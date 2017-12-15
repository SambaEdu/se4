#
# Regular cron jobs for the sambaedu-master package
#
0 4	* * *	root	[ -x /usr/bin/sambaedu-master_maintenance ] && /usr/bin/sambaedu-master_maintenance
