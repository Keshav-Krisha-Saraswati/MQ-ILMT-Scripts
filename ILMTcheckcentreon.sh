#!/bin/sh
#
#------------------------------------------------------------------
# Description: Check ILMT filesystems and processes.
# Author: Keshav Krishna Saraswati
# Date: 21/10/2020
#------------------------------------------------------------------
#set -x

DAT=`date +"%d%b%y"`
OKLOG=/tmp/oklog.$DAT
ERRLOG=/tmp/errlog.$DAT
touch $OKLOG
touch $ERRLOG
chmod 777 $OKLOG
chmod 777 $ERRLOG
RED=0
DB2=0
#------------------------------------------------------------------
# Check ILMT processes
#------------------------------------------------------------------
#
#echo "Checking DB2 processes"
DB2=`ps -ef | grep [d]b2sysc | wc -l`
if [ $DB2 -ne 1 ]; then
	echo "RED - Check DB2 is not running ~ "  >> $ERRLOG
	export RED=`expr $RED + 1`
else
	echo "DB2 is running ~ " >> $OKLOG
fi

#echo "Checking ILMT server process"
LMT=`/etc/init.d/LMTserver status | grep [S]erver | awk '{print $4}'`
if [ "$LMT" != "running" ]; then
	echo "RED - Check LMT server is not  running ~ " >> $ERRLOG
	export RED=`expr $RED + 1`
else
	echo "LMT server is running ~ " >> $OKLOG
fi

#echo "Checking BES processes"
for S in besclient besfilldb besgatherdb besserver beswebreports 
do
	STATUS=`service $S status | awk '{print $5}' | sed "s/\.//g"`
	if [ "$STATUS" != "running" ]; then
		echo "RED - Service $S has failed it's status check ~ " >> $ERRLOG
		export RED=`expr $RED + 1`
	else
		echo "Service $S is running ~ "  >> $OKLOG
	fi
done

#echo "Checking Final status "

if [ $RED -ne 0 ]; then

        ERRCOM=`echo $(cat $ERRLOG)`
	EXITCODE=2
        echo "[ Error Found: $ERRCOM ]"

else
        OKCMP=`echo $(cat $OKLOG)`
	EXITCODE=0
        echo "[ All OK: $OKCMP ]"

fi
rm $OKLOG
rm $ERRLOG
exit $EXITCODE
#
#End of script
	
