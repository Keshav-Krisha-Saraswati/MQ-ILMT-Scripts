#!/bin/sh
#
#--------------------------------------------------------------------------
# Description: Stop ILMT server or individual components
# Author: Keshav Krishna saraswati
# Date: 16/05/2019
#--------------------------------------------------------------------------
# Amendments:
#--------------------------------------------------------------------------
#
#
# Amend the following for new customers
# ---------------------------------------
# May need to change DB2 admin user from default of "db2inst1"
# ---------------------------------------
#
set -x
#
#--------------------------------------------------------------------------
# Usage
#--------------------------------------------------------------------------
#
if [ $# -ne 1 ]; then
	echo "ILMTstop.sh all|db2|bes|lmt"
	exit 99
fi
#
#--------------------------------------------------------------------------
# Stop DB2
#--------------------------------------------------------------------------
#
db2 ()
{
echo "Stopping DB2"
su - db2inst1 -c "db2 force application all"
sleep 30
su - db2inst1 -c "db2stop"
if [ $? -ne 0 ]; then
	echo "Stop of DB2 failed"
	exit 99
else
	echo "Stop of DB2 successful"
fi
}
#
#--------------------------------------------------------------------------
# Stop BigFix
#--------------------------------------------------------------------------
#
bes ()
{
echo "Stopping BES processes"
for P in client webreports gatherdb filldb server
do
	echo "Stopping BES$P"
	/sbin/service bes$P stop
	PROC=`ps -ef | grep -i $P | grep BES | grep -Ev "grep|VMMAN" | wc -l`
	if [ $PROC -gt 0 ]; then
		echo "Stop of BES$P failed"
		exit 99
	else
		echo "Stop of BES$P successful"
	fi
done
/sbin/service vmmansvc stop
}
#
#--------------------------------------------------------------------------
# Stop ILMT
#--------------------------------------------------------------------------
#
lmt ()
{
echo "Stop ILMT"
/etc/init.d/LMTserver stop
if [ $? -ne 0 ]; then
	echo "Stop of LMT server failed"
	exit 99
else
	echo "Stop of LMT server successful"
fi
}
#
#--------------------------------------------------------------------------
# Main script starts here
#--------------------------------------------------------------------------
#
case $1 in
all)
lmt
bes
db2
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
