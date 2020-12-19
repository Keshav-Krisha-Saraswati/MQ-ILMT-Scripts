#!/bin/sh
#
#--------------------------------------------------------------------------------------------------------
# Description: Check DB2 offline backup log
# Author: Keshav Krishna Saraswati
# Date: 30/04/2020
#--------------------------------------------------------------------------------------------------------
#
set -x
#
LOG=`cat /tmp/DB2log`
grep RED $LOG
if [ $? -ne 0 ]; then
	cat $LOG | mail -s "MarkIT DB2 offline OK" keshav.saraswati@ihsmarkit.com
else	
	cat $LOG | mail -s "MarkIT DB2 offline failed" keshav.saraswati@ihsmarkit.com
fi
