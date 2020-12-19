#!/bin/sh
#
#------------------------------------------------------------------
# Description: Check ILMT computers
# Author: Keshav Krishna Saraswati
# Date: 15/04/2020
#------------------------------------------------------------------
# Amendments:
#------------------------------------------------------------------
#
set -x

CHK=/root/logs/ILMTcomputers.out
CURR=/root/logs/ILMTcomputers.current
OLD=/root/logs/ILMTcomputers.old
#
# Amend the following if you make any changes in following
# ---------------------------------------
#  bigfixhost, username, password and logs path
# ---------------------------------------
#
cp $CURR $OLD
curl -k -u IEMAdmin:iL0bf135 -X POST  https://nj4gtspdilm001.markit.partners:52311/api/query -d "relevance=(names of bes computers)" |grep Answer > $CHK
cat $CHK | sed "s/>/ /g" | sed "s/</ /g" | awk '{print $3}' | sort -u > $CURR
COUNT1=`cat $OLD | wc -l`
COUNT2=`cat $CURR |wc -l`
if [ $COUNT1 -ne $COUNT2 ];then
        echo "ILMT Computers now = $COUNT2, when last checked = $COUNT1" | mail -s "Markit - ILMT computer check" keshav.saraswati@ihsmarkit.com
else
#Temporary to check script is working OK
        echo "Number of ILMT computers has not changed" | mail -s "Markit - ILMT computer check" keshav.saraswati@ihsmarkit.com
fi
#
#End of script

