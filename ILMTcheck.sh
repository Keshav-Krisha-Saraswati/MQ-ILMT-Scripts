#!/bin/sh
#
#------------------------------------------------------------------
# Description: Check ILMT filesystems and processes
# Author: Keshav Krishna Saraswati
# Date: 16/05/2020
#------------------------------------------------------------------
# Amendments:
#------------------------------------------------------------------
#
#
# ---------------------------------------
# If required make change in mail subject
#If Required may need to change filesystems in check filesystems check step
# ---------------------------------------
#
set -x

DAT=`date +"%d%b%y"`
LOG=/tmp/ILMTlogs/ILMTcheck.$DAT
touch $LOG
chmod 444 $LOG
RED=0
echo "*************************************************"
echo " ILMT server check - `date`"
echo "*************************************************"
#
#------------------------------------------------------------------
# Check free memory
#------------------------------------------------------------------
#
echo "Checking memory"
MEM=`vmstat -SM | grep -Ev "proc|buff" | awk '{print $4}'`
if [ $MEM -lt 50 ]; then
	echo "RED - Free memory is less than 50MB" | tee -a $LOG
	export RED=`expr + 1`
else
	echo "Free memory is $MEM MB" | tee -a $LOG
fi
#
#------------------------------------------------------------------
# Check CPU usage
#------------------------------------------------------------------
#
echo "Checking CPU utilisation"
IDLE=`vmstat | grep -Ev "proc|buff" | awk '{print $15}'`
if [ $IDLE -lt 20 ]; then
	sleep 300
	IDLE=`vmstat | grep -Ev "proc|buff" | awk '{print $15}'`
	if [ $IDLE -lt 20 ]; then
		echo "RED - CPU over 80% utilised over the last 5 minutes" | tee -a $LOG
		export RED=`expr $RED + 1`
	fi
else
	echo "CPU utilisation is under 80%" | tee -a $LOG
fi
#
#------------------------------------------------------------------
# Check filesystems
#------------------------------------------------------------------
#
echo "Checking Filesystem usage"
for F in / /home /opt /var /tmp
do
	FS=`df -h $F | grep -v File | sed "s/%//g" | awk '{print $5}'`
	if [$FS -gt 80 ]; then
		echo "RED - Filesystem $F is $FS percent full" | tee -a $LOG
		export RED=`expr $RED + 1`
	else
		echo "Filesystem "$F" is "$FS" percent full" | tee -a $LOG
	fi
done
#
#------------------------------------------------------------------
# Check processes
#------------------------------------------------------------------
#
echo "Checking DB2 processes"
DB2=`ps -ef | grep [d]b2sysc | wc -l`
if [ $DB2 -ne 1 ]; then
	echo "RED - Check DB2 is running" | tee -a $LOG
	export RED=`expr $RED + 1`
else
	echo "DB2 is running" | tee -a $LOG
fi

echo "Checking ILMT server process"
LMT=`/etc/init.d/LMTserver status | grep [S]erver | awk '{print $4}'`
if [ $LMT != running ]; then
	echo "RED - Check LMT server is running" | tee -a $LOG
	export RED=`expr $RED + 1`
else
	echo "LMT server is running" | tee -a $LOG
fi

echo "Checking BES processes"
for S in besclient besfilldb besgatherdb besserver beswebreports 
do
	STATUS=`service $S status | awk '{print $5}' | sed "s/\.//g"`
	if [ $STATUS != running ]; then
		echo "RED - Service $S has failed it's status check" | tee -a $LOG
		export RED=`expr $RED + 1`
	else
		echo "Service $S is running" | tee -a $LOG
	fi
done

echo "Checking for a reboot"

if [ $RED -ne 0 ]; then
	cat $LOG | mail -s "MarkIT ILMTcheck - RED"  keshav.saraswati@ihsmarkit.com
else
	cat $LOG | mail -s "MarkIT ILMTcheck - GREEN" keshav.saraswati@ihsmarkit.com
fi
#
#End of script
	
