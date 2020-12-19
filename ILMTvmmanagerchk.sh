#!/bin/sh
#
#-------------------------------------------------------------------------------------
# Description: Check ILMT VM manager status
# Author: Keshav Krishna Saraswati
# Date: 28/04/2020
#-------------------------------------------------------------------------------------
#
#set -x

DAT=`date +"%d%b%y"`
CHK=/root/logs/vmmanager.chk
OUT=/root/logs/vmmanager.out
FILE=/root/scripts/ILMTvmmanagerchk.txt
LOG=/tmp/ILMTlogs/ILMTvmmanagerchk.$DAT
touch $LOG
chmod 444 $LOG
#
#--------------------------------------------------------------------------------------
# Change ILMT hostname, token and mail message
#--------------------------------------------------------------------------------------
#
curl -k https://nj4gtspdilm001.markit.partners:9081/api/sam/vmmanagers?token=39dc1774e477d7e61482c533606a384fa2aed034 > $CHK
cat $CHK | sed "s/\[//g" | sed "s/\]//g" | sed "s/[\\\"}]//g" | sed "s/,/ /g" | tr "{" "\n" | grep deleted:false | awk '{print $11, $1, $10}' > $OUT
cat $OUT | grep status | while read STATUS ID MANAGER
do
        if [ $STATUS != status:1 ]; then
                ERR=`echo "$STATUS" | sed "s/:/ /g" | awk '{print $2}'`
                cat $FILE | while read RC MSG
                do
                        if [ $RC -eq $ERR ]; then
                                echo "RED - Status $RC $MSG found for VM manager $MANAGER" > $LOG
                                echo "RED - Status $RC $MSG found for VM manager $MANAGER" | mail -s "MarkIT - ILMT VM manager check" keshav.saraswati@ihsmarkit.com
                        fi
                done
        else
                echo "GREEN - Status is OK for VM manager $MANAGER" > $LOG
                cat $LOG | mail -s "MarkIT - ILMT VM manager check" keshav.saraswati@ihsmarkit.com
        fi
done
#
# End of script
