#!/bin/sh
#
#---------------------------------------------------------------------------------------------------
# Description: DB2 offline backup
# Author: KeshavKrishna Saraswati
# Date: 30/04/2020
#---------------------------------------------------------------------------------------------------
# Amendments:
#---------------------------------------------------------------------------------------------------
#
set -x
DAY=`date +"%d%b%y"`
TIME=`date +"%H:%M"`
LOG=/tmp/ILMTlogs/DB2offline.$DAY
touch $LOG
chmod 444 $LOG
echo "$LOG" > /tmp/DB2log
#
#---------------------------------------------------------------------------------------------------
# Stop ILMT
#---------------------------------------------------------------------------------------------------
/root/scripts/ILMTstop.sh lmt
if [ $? -ne 0 ]; then
	echo "RED - ILMT stop failed" >> $LOG
	exit 99
else
	echo "GREEN - ILMT stop successful" >> $LOG
fi
#---------------------------------------------------------------------------------------------------
# Stop BES
#---------------------------------------------------------------------------------------------------
/root/scripts/ILMTstop.sh bes
if [ $? -ne 0 ]; then
	echo "RED - BigFix stop failed" >> $LOG
	exit 99
else
	echo "GREEN - BigFix stop successful" >> $LOG
fi
#
echo "**********************************************************************************************"
echo "* dB2 offline backup taken on $DAY at $TIME"
echo "**********************************************************************************************"
#
for DB in TEMADB BFENT BESREPOR
do
#
#---------------------------------------------------------------------------------------------------
# Terminate DB2 connections and deactivate DB 
#---------------------------------------------------------------------------------------------------
#
	echo "Deactivating DB2 DB $DB"
	su - db2inst1 -c "db2 terminate"
	su - db2inst1 -c "db2 force application all"
	su - db2inst1 -c "db2 deactivate db $DB"
	if [ $? -ne 0 ]; then
		echo "RED - Deactivate of DB2 database $DB failed" >> $LOG
		exit 99
	else
		echo "GREEN - Deactivate of DB2 database $DB successful" >> $LOG
	fi
#
#---------------------------------------------------------------------------------------------------
# DB2 offline backup
#---------------------------------------------------------------------------------------------------
#
	echo "Starting DB2 offline backup for $DB"
	su - db2inst1 -c "db2 backup db $DB to /opt/db2backups" > /tmp/DB2offline.$DB
	if [ $? -ne 0 ]; then
		echo "RED - Offline backup of DB2 database $DB failed" >> $LOG
		exit 99
	else
		echo "GREEN - Offline backup of DB2 database $DB successful" >> $LOG
	fi
#
#---------------------------------------------------------------------------------------------------
# Verify DB2 backup
#---------------------------------------------------------------------------------------------------
#
	DB2FIL=`cat /tmp/DB2offline.$DB | awk '{print $11}'`
	DB2BKFIL=`ls /opt/db2backups | grep $DB2FIL`
	su - db2inst1 -c "db2ckbkp /opt/db2backups/$DB2BKFIL"
	if [ $? -ne 0 ]; then
		echo "RED - DB2 offline backup image of $DB is invalid" >> $LOG
		exit 99
	else
		echo "GREEN - DB2 offline backup image of $DB is valid" >> $LOG
	fi
#	
#---------------------------------------------------------------------------------------------------
# Activate DB2 database
#---------------------------------------------------------------------------------------------------
#
	su - db2inst1 -c "db2 activate db $DB"
	if [ $? -ne 0 ]; then
		echo "RED - DB2 activation of $DB failed" >> $LOG
		exit 99
	else
		echo "GREEN - DB2 activation of $DB successful" >> $LOG
	fi
done
#	
#---------------------------------------------------------------------------------------------------
# Start BES
#---------------------------------------------------------------------------------------------------
/root/scripts/ILMTstart.sh bes
if [ $? -ne 0 ]; then
	echo "RED - BigFix start failed" >> $LOG
	exit 99
else
	echo "GREEN - BigFix start successful" >> $LOG
fi
#---------------------------------------------------------------------------------------------------
# Restart ILMT
#---------------------------------------------------------------------------------------------------
#
/etc/init.d/LMTserver start
if [ $? -ne 0 ]; then
	echo "RED - ILMT start failed" >> $LOG
	exit 99
else
	echo "GREEN - ILMT start successful" >> $LOG
fi
#
#---------------------------------------------------------------------------------------------------
# Remove old backups
#---------------------------------------------------------------------------------------------------
#
cd /opt/db2backups
find /opt/db2backups -name \*db2inst1\* -a -mtime +15 | xargs -i rm {}
#
# End of script
