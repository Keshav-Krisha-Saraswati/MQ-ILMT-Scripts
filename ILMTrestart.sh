#!/bin/sh
#
#---------------------------------------------------------------------------------
# Description: Stop/starts ILMT if server has been rebooted in the last 24 hours
# Author: Keshav Krishna Saraswati
# Date: 29/04/2020
#---------------------------------------------------------------------------------
# Amendments: Will include the team DL later once testing is done
#---------------------------------------------------------------------------------
#
#
LOG=/root/logs/ILMTrestart.log
#set -x
#
RESTART=`/usr/bin/uptime | grep day | wc -l`
if [ $RESTART -ne 1 ]; then
	echo "============================================================================" >> $LOG
	echo "Restarting after a reboot - `date`" >> $LOG
	echo "----------------------------" >> $LOG
	uptime >> $LOG
	echo "Check ILMT is OK after the reboot" | mail -s "MarkIT ILMT server has been rebooted" keshav.saraswati@ihsmarkit.com
	/root/scripts/stopILMT.sh
	sleep 30
	/root/scripts/startILMT.sh
	sleep 10
	/root/scripts/ILMTcheck.sh
fi
#
# End of script
