#!/bin/sh
#
#-----------------------------------------------------------------------------------------------------
# Description: Manage log files
# Author: Keshav Krishna saraswati
# Date: 05/01/2020
#-----------------------------------------------------------------------------------------------------
#
#
# ---------------------------------------
#  change DB2 admin user from default of "db2inst1"
#  backup directory from "/opt/db2backups" in delete backup step
#  if required change location of db2dump directory in archive step
# ---------------------------------------
#
#set -x
#
DAY=`date +"%a %d%b%y"`
TIME=`date +"%H:%M"`
HOST=`hostname`
#-----------------------------------------------------------------------------------------------------
# Archive DB2 diag log
#-----------------------------------------------------------------------------------------------------
echo "Archiving DB2 diag log"
su - db2inst1 -c "db2diag -A"
if [ $? -ne 0 ]; then
        echo "Archive of DB2 diag log failed"
        echo "$DAY, $TIME - Archive of DB2 diag log failed" |  mail -s "MarkIT $HOST - $0 Failed" keshav.saraswati@ihsmarkit.com
        exit 99
else
        echo "Archive of DB2 diag log  successful"
        echo "$DAY, $TIME - Archive of DB2 diag log  successful" | mail -s "MarkIT $HOST - $0 OK" keshav.saraswati@ihsmarkit.com
fi
#-----------------------------------------------------------------------------------------------------
# Delete DB2 archived diag logs over 30 days old
#-----------------------------------------------------------------------------------------------------
echo "Deleting old DB2 diag logs"
find /home/db2inst1/sqllib/db2dump -name db2diag\* -a -mtime +30 | xargs -i rm {}
#-----------------------------------------------------------------------------------------------------
# Delete DB2 backups over 14 days old
#-----------------------------------------------------------------------------------------------------
echo "Deleting old DB2 backups"
find /opt/db2backups -name \*db2inst1\* -a -mtime +14 | xargs -i rm {}
#-----------------------------------------------------------------------------------------------------
# Delete logs over 30 days old from /root/logs
#-----------------------------------------------------------------------------------------------------
echo "Deleting old logs"
find /root/logs -mtime +30 |grep -v [v]mstat |xargs -i rm {}
find /root/logs -name vmstat\* -a -mtime +180 |xargs -i rm {}
#-------------------------------------------------------------------------------------------------------
#
#
# End of script

