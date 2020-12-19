#!/bin/sh
#
#------------------------------------------------------------------
# Description: Check ILMT import status
# Author: Keshav Krishna Saraswati
# Date: 24/05/2020
#------------------------------------------------------------------
# Amendments:
#------------------------------------------------------------------
#
set -x

#DAT=`date +"%d%b%y"`
#LOG=/root/logs/ILMTimport_check.$DAT
CHK=/root/logs/import.chk
#
# Amend the following if required
# ---------------------------------------
# Verify ILMT server hostname 
# Change token 
# (To get token: Log in to ILMT, click on user icon, select profile, select show token)
# May need to change backup directory from "/opt/db2backups" in backup, verify and remove steps
# ---------------------------------------
#
curl -k https://nj4gtspdilm001.markit.partners:9081/api/import_status.xml?token=39dc1774e477d7e61482c533606a384fa2aed034 > $CHK
MODE=`cat $CHK | grep mode | sed "s/</ /g" | sed "s/>/ /g" | awk '{print $3}'`
STATUS=`cat $CHK | grep last-status | sed "s/</ /g" | sed "s/>/ /g" | awk '{print $3}'`
TIME=`cat $CHK | grep last-success-time | sed "s/</ /g" | sed "s/>/ /g" | awk '{print $3}'|sed "s/Z//g"|sed "s/T/ /g"`

if [ $MODE = running ]; then
	sleep 600
	curl -k https://nj4gtspdilm001.markit.partners:9081/api/import_status.xml?token=39dc1774e477d7e61482c533606a384fa2aed034 > $CHK
	MODE=`cat $CHK | grep mode | sed "s/</ /g" | sed "s/>/ /g" | awk '{print $3}'`
	STATUS=`cat $CHK | grep last-status | sed "s/</ /g" | sed "s/>/ /g" | awk '{print $3}'`
	TIME=`cat $CHK | grep last-success-time | sed "s/</ /g" | sed "s/>/ /g" | awk '{print $3}'`
	if [ $MODE = running ]; then
		echo "Import still running after 10 minutes" | mail -s "MarkIT - Long running import" keshav.saraswati@ihsmarkit.com
		exit
	fi
fi

if [ $MODE != running ]; then
	if [ $STATUS != successful ]; then
		echo "Mode=$MODE, Status=$STATUS, Time=$TIME" | mail -s "MarkIT - ILMT import check" keshav.saraswati@ihsmarkit.com
	else
#Temporary to check script is working OK
		echo "Mode=$MODE, Status=$STATUS, Time=$TIME" | mail -s "MarkIT - ILMT import check" keshav.saraswati@ihsmarkit.com
	fi
fi
#
#End of script
	
