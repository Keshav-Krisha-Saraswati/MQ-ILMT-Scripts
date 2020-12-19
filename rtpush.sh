#!/bin/bash

# All Rights Reserved

# NOTICE: All information contained herein is, and remains
# the property of IHS Markit and its suppliers,
# if any. The intellectual and technical concepts contained
# herein are proprietary to IHS Markit and its suppliers
# and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material
# is strictly forbidden unless prior written permission is obtained
# from IHS Markit.

usage() {
    cat << EOF
usage: ./rtpush.sh [Flags]

Flags:
  -r, --rpm, --rpmname FILENAME
        Rpm file name. Needs to be the absolute or relative path to the file.
  -d, --dir DIRECTORY
        process packages from this directory. 
  -c, --channel CHANNEL
        process data for this specific channel (specified by label) only. NOTE: This needs to be the folder name inside
        the repository. E.g. qa-rhel-x86_64-7-devtools.
  --repository REPOSITORY
        process data for this specific repository only. This is the name of the virtual repository, e.g. qa-rhel-x86_64-7
  --server SERVER_URL
        push to this server. The format is <hostname>, e.g. repo.ihsmarkit.com/artifactory
  -p, --password API_KEY
        api key for the user with permissions to upload to Artifactory.
  --dry-run                     
        (optional) Execute the script in dry run mode. This will simply output the steps it would execute without 
        actually running them.
  -v, --verbose                  
        (optional) Increase verbosity
  -h                            
        (optional) This help message

Environment Variables:
Prior to running the script set the following environment variables:

  ARTIFACTORY_PASS    API Key for the user with permissions to upload to Artifactory
  ARTIFACTORY_HOST    Artifactory host name. Default repo.ihsmarkit.com/artifactory
  VERBOSE             Enable verbose mode for this script to get more logging. Default is not verbose (0).

EOF
exit 0
}

initialize() {
    VERBOSE=${VERBOSE:-0}
    ARTIFACTORY_HOST=${ARTIFACTORY_HOST:-repo.ihsmarkit.com/artifactory}
    ARTIFACTORY_PASS=${ARTIFACTORY_PASS:-}
    DRYRUN=${DRYRUN:-0}
}

prepare() {
    # check if required input has been provided
    [ -n "${ARTIFACTORY_HOST}" ] || die "No Artifactory host name provided."
    [ -n "${ARTIFACTORY_PASS}" ] || die "No Artifactory API key (password) provided."
    
    # tools check
    [ -x "`which md5sum`" ] || die "Tool not Found: md5sum"
    [ -x "`which sha1sum`" ] || die "Tool not Found: sha1sum"
    [ -x "`which sha256sum`" ] || die "Tool not Found: sha256sum"

    # determine the repository name. if needed derive from channel name.
    ARTIFACTORY_REPOSITORY=${ARTIFACTORY_REPOSITORY:-$(echo $ARTIFACTORY_CHANNEL | cut -d'-' -f-4)}
}

main() {
    # we either upload a single rpm or rpms from a given repository
    if [ -n "${RPM_FILE}" ]; then
        upload_rpm
    elif [ -n "${RPM_DIRECTORY}" ]; then
        for RPM_FILE in $(find ${RPM_DIRECTORY}/ -type f -name *.rpm); do
            upload_rpm
        done
    else
        die "No rpm or directory provided."
    fi
}

upload_rpm() {
    local __md5sum=$(md5sum ${RPM_FILE} | awk '{print $1}')
    local __sha1sum=$(sha1sum ${RPM_FILE} | awk '{print $1}')
    local __sha256sum=$(sha256sum ${RPM_FILE} | awk '{print $1}')
    local __rpm_file_name=$(basename $RPM_FILE)

    # Try checksum upload first
    print_msg "INFO : Uploading $(basename ${RPM_FILE}) (sha265: ${__sha256sum})..."
    CHECKSUM_UPLOAD="curl -u :${ARTIFACTORY_PASS} -X PUT -H \"X-Checksum-Deploy:true\" -H \"X-Checksum-Sha256: ${__sha256sum}\" --write-out %{http_code} --silent --output /dev/null \"https://${ARTIFACTORY_HOST}/${ARTIFACTORY_REPOSITORY}/${ARTIFACTORY_CHANNEL}/${__rpm_file_name}\""
    BINARY_UPLOAD="curl -u :${ARTIFACTORY_PASS} -X PUT -H \"X-Checksum-Md5: ${__md5sum}\" -H \"X-Checksum-Sha1: ${__sha1sum}\" -H \"X-Checksum-Sha256: ${__sha256sum}\" -T ${RPM_FILE} --write-out %{http_code} --output /dev/null \"https://${ARTIFACTORY_HOST}/${ARTIFACTORY_REPOSITORY}/${ARTIFACTORY_CHANNEL}/\""

    if [ $DRYRUN -eq 1 ]; then
        print_msg "DEBUG: dryrun - ${CHECKSUM_UPLOAD}"
        print_msg "DEBUG: dryrun - ${BINARY_UPLOAD}"
    else
        print_msg "DEBUG: Checksum upload: ${__rpm_file_name} (sha265: ${__sha256sum})..."
        status=$(eval "${CHECKSUM_UPLOAD}")
        print_msg "DEBUG: http return code: $status. Try binary upload..."
        case $status in
            404)
                print_msg "DEBUG: Binary upload: ${__rpm_file_name} (sha265: ${__sha256sum})..."
                status=$(eval "${BINARY_UPLOAD}")
                print_msg "DEBUG: http return code: $status"
                case $status in
                    200|201)
                        print_msg "INFO : $status - Successfully uploaded ${__rpm_file_name}"
                        print_msg "INFO : RPM has been uploaded to: https://${ARTIFACTORY_HOST}/${ARTIFACTORY_REPOSITORY}/${ARTIFACTORY_CHANNEL}/"
                        print_msg "DEBUG: Direct download link: https://${ARTIFACTORY_HOST}/${ARTIFACTORY_REPOSITORY}/${ARTIFACTORY_CHANNEL}/${__rpm_file_name}"
                        exit 0
                        ;;
                    409)
                        print_msg "ERROR: $status - Failed to upload file $RPM_FILE to https://${ARTIFACTORY_HOST}/${ARTIFACTORY_REPOSITORY}/${ARTIFACTORY_CHANNEL}/"
                        exit $status
                        ;;
                    *)
                        print_msg "WARN : Unexpected result: $status"
                        exit $status
                        ;;
                esac
                ;;
            409)
                print_msg "WARN : $status - File already exists. Skip binary upload"
                exit 0
                ;;
            200|201)
                print_msg "INFO : $status - Successfully uploaded ${__rpm_file_name}"
                print_msg "INFO : RPM has been uploaded to: https://${ARTIFACTORY_HOST}/${ARTIFACTORY_REPOSITORY}/${ARTIFACTORY_CHANNEL}/"
                print_msg "DEBUG: Direct download link: https://${ARTIFACTORY_HOST}/${ARTIFACTORY_REPOSITORY}/${ARTIFACTORY_CHANNEL}/${__rpm_file_name}"
                exit 0
                ;;
        esac
    fi
}

die() {
    local MSG="$1"

    print_msg "ERROR: $MSG"
    print_msg
    print_msg "Run './rtpush.sh -h' for more information about all required flags."
    exit 1
}

print_msg() {
    local MSG="$1"
    echo "$MSG"
}

check_access() {
    # basic check to see if we can run commands to the rest api
    CMD="curl -s -u :${ARTIFACTORY_PASS} -XGET -o /dev/null -w \"%{http_code}\" \"https://${ARTIFACTORY_HOST}/api/system/ping\""
    local status_code=$(eval $CMD)
    [ $status_code == 200 ] ||  {
        die "Failed to connect to Artifactory (https://${ARTIFACTORY_HOST}). If there is connectivity, make sure to provide a valid API key"
    }
}

initialize

# continue testing for arguments
[ $# -eq 0 ] && usage
while [[ $# > 0 ]]; do
    case $1 in
        -r|--rpm|--rpmname)
            RPM_FILE=$2
            shift
            ;;
        -d|--dir)
            RPM_DIRECTORY=$2
            shift
            ;;
        -c|--channel)
            ARTIFACTORY_CHANNEL=$2
            shift
            ;;
        --repository)
            ARTIFACTORY_REPOSITORY=$2
            shift
            ;;
        --server)
            ARTIFACTORY_HOST=$2
            shift
            ;;
        -u|--username)
            ARTIFACTORY_USER=$2
            shift
            ;;
        -p|--password)
            ARTIFACTORY_PASS=$2
            shift
            ;;
        --dry-run)
            DRYRUN=1
            ;;
        -v|--verbose)
            VERBOSE=1
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "UNKNOWN ARGUMENT $1"
            usage
            exit 1
            ;;
    esac
    shift
done

if [ ! -z "$VERBOSE" ] && [ $VERBOSE -eq 1 ]; then
    set -eox pipefail
else
    set -eo pipefail
fi

prepare

check_access

main