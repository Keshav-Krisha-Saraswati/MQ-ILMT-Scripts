#!/bin/sh
#
#----------------------------------------------------------
# Description: Start ILMT server or individual components
# Author: Keshav Krishna saraswati
# Date: 16/05/2019
#----------------------------------------------------------
# Amendments:
#----------------------------------------------------------
#
#
# Amend the following for new customers
# ---------------------------------------
# May need to change DB2 admin user from default of "db2inst1"
# ---------------------------------------
#
set -x
#
#----------------------------------------------------------
# Usage
#----------------------------------------------------------
#
if [ $# -ne 1 ]; then
	echo "ILMTstart.sh all|db2|bes|lmt"
	exit 99
fi
#
#----------------------------------------------------------
# Start DB2
#----------------------------------------------------------
#
db2 ()
{
echo "Starting DB2"
su - db2inst1 -c "db2start"
if [ $? -ne 0 ]; then
	echo "Start of DB2 failed"
	exit 99
else
	echo "Start of DB2 successful"
fi
}
#
#----------------------------------------------------------
# Start BigFix
#----------------------------------------------------------
#
bes ()
{
echo "Starting BES processes"
for P in server filldb gatherdb webreports client
do
	echo "Starting BES$P"
	sleep 5
	/sbin/service bes$P start
	PROC=`ps -ef | grep -i $P | grep BES |grep -Ev "grep|VMMAN" | wc -l`
	if [ $PROC -gt 0 ]; then
		echo "Start of BES$P successful"
	else
		echo "Start of BES$P failed"
		exit 99
	fi
done
/sbin/service vmmansvc start
}
#
#----------------------------------------------------------
# Start LMT
#----------------------------------------------------------
#
lmt ()
{
echo "Start ILMT"
/etc/init.d/LMTserver start
if [ $? -ne 0 ]; then
	echo "Start of LMT server failed"
	exit 99
else
	echo "Start of LMT server successful"
fi
}
#
#----------------------------------------------------------
# Main script starts here
#----------------------------------------------------------
#
case $1 in
all)
db2
bes
lmt
;;
db2)
db2
;;
bes)
bes
;;
lmt)
lmt
;;
*)
echo "Invalid parameter"
exit 99
;;
esac
#
# End of script
