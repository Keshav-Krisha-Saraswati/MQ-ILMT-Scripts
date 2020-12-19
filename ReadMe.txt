
1. Create scripts and logs directories under /root
2. Create directory for DB2 backups (ie. /opt/db2backups)
3. Place scripts into /root/scripts
4. Test email from server
5. Scripts should properly reflect our  environment
	(ie. DB2 backup location, Details in mail subject, directories in housekeep script,
	import check script etc.)
6. Test scripts
7. Create root crontab entries (example below)
	format = min hour DoM month DoW (Sun = 0)
	# L-Markit scripts for ILMT
	5 0 * * * /root/scripts/vmstat.sh
	30 10 * * * /root/scripts/ILMTcheck.sh
	25 7 * * 3 /root/scripts/db2offlinebackup.sh
	45 8 * * 3 /root/scripts/db2offbckchk.sh
	55 8 * * 3 /root/scripts/housekeep.sh
	0 12 * * * /root/scripts/ILMTrestart.sh
	0 14 * * * /root/scripts/ILMTimportchk.sh
	0 6 * * 1 /root/scripts/ILMTvmmanagerchk.sh
