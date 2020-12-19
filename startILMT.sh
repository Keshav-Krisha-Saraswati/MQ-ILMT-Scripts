#!/bin/ksh
#
# ---------------------------------------
# Author: Keshav Krishna Saraswati
# Date: 08/04/2019
# Must use  DB2 admin user from default of "db2inst1"
# ---------------------------------------
#
#-----------------------------------------------------------------------------------
# Start DB2
#-----------------------------------------------------------------------------------
su - db2inst1 -c db2start
#-----------------------------------------------------------------------------------
# Start BigFix server
#-----------------------------------------------------------------------------------
/etc/init.d/vmmansvc start
/etc/init.d/besgatherdb start
/etc/init.d/besfilldb start
/etc/init.d/besserver start
/etc/init.d/beswebreports start
#-----------------------------------------------------------------------------------
# Start ILMT
#-----------------------------------------------------------------------------------
/opt/ibm/LMT/cli/srvstart.sh
#-----------------------------------------------------------------------------------
# Start client
#-----------------------------------------------------------------------------------
/etc/init.d/besclient start
#-----------------------------------------------------------------------------------
# End of script