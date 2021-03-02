#!/bin/bash
   if [ `id -u` -ne 0 ]; then
      echo "This script can be executed only as root, Exiting.."
      exit 1
   fi

case "$1" in
   install|update)

	CRON_FILE="/var/spool/cron/modehero"

	if [ ! -f $CRON_FILE ]; then
	   echo "cron file for root doesnot exist, creating.."
	   touch $CRON_FILE
	   /usr/bin/crontab $CRON_FILE
	fi

	# Method 1
	grep -qi "cleanup_script" $CRON_FILE
	if [ $? != 0 ]; then
	   echo "Updating cron job for cleaning temporary files"
           /bin/echo "0 0 1 * * sudo certbot renew --nginx && sudo service nginx restart" >> $CRON_FILE
	fi

	# Method 2
	grep -qi "cleanup_script" $CRON_FILE
	if [ $? != 0 ]; then
	   echo "Updating cron job for cleaning temporary files"
	   crontab -u modehero -l >/tmp/crontab
           /bin/echo "0 0 1 * * sudo certbot renew --nginx && sudo service nginx restart " >> /tmp/crontab
	   crontab -u modehero /tmp/crontab
	fi

	;;
	
	*)
	
	echo "Usage: $0 {install|update}"
	exit 1
    ;;

esac
