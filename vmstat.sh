#!/bin/sh
#
#-----------------------------------------------------------------------------------------------------
# Description: Gather daily stats at 5 minute intervals
# Author: Keshav Krishna Saraswati 
# Date: 08/04/2019
#-----------------------------------------------------------------------------------------------------
#
#set -x
#
DAY=`date +"%d%b%y"`
#-----------------------------------------------------------------------------------------------------
# Use vmstat to get free memory and CPU utilisation
#-----------------------------------------------------------------------------------------------------
echo "Time Free_mem User System WIO" >>/root/logs/vmstat.$DAY
vmstat -ntS M 300 288|grep -Ev "procs|buff"|awk '{print $19, $4, $13, $14, $16}' >>/root/logs/vmstat.$DAY
#
# End of script

