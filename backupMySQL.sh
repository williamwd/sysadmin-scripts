#!/bin/bash

# I found the base script here (http://andycroll.com/development/backing-up-mysql-databases-remotely-using-cron-and-ssh/) and adapted some parts for my best usage. All credits to the author. 
# Changed gzip for pbzip which is a multithread compressor (runs much faster than traditional implementation.

### System Setup ###
NOW=$(date +%Y-%m-%d)
KEEPDAYS=20
localPath=/path/local/mysql

### SSH Info ###
SHOST="remote.host.mysql.access"
SUSER="remoteUser"
SDIR="/path/backup/mysql"

### MySQL Setup ###
MUSER="mysqlUser"
MPASS="mysqlPassword"
MHOST="mysqlHost"
DBS="EACH SCHEMA SEPARED BY SPACE WILL GENERATE ONE FILE"

### Start MySQL Backup ###
attempts=0
for db in $DBS	# for each listed database
do
	echo "Starting $db"
	attempts=$(expr $attempts + 1)	# count the backup attempts
	ssh -C $SUSER@$SHOST mkdir $SDIR/$NOW			#create the backup dir
	FILE=$SDIR/$NOW/$db.sql.gz        # Set the backup filename
                                            # Dump the MySQL and gzip it up
	ssh -C $SUSER@$SHOST "mysqldump -q -u $MUSER -h $MHOST -p$MPASS $db | pbzip -9 > $FILE"
	echo "Finished $db"
done
mkdir "$localPath"/"$NOW"
scp -C $SUSER@$SHOST:/$SDIR/$NOW/* "$localPath"/$NOW	# copy all the files to backup server
ssh -C $SUSER@$SHOST rm -rf $SDIR/$NOW	# delete files on db server

################### Save last month's last backup #########################
today=$(date +%d)
permanents="$localPath/permanents/"
if [ "$today" = "01" ]; then
	cp -rl "$localPath"/$NOW $permanents
fi

# Deletes backups older than $KEEPDAYS, unless they are permanent
find "$localPath" -type d -path "$permanents" -prune -o -daystart -mtime +$KEEPDAYS -exec rm -rf {} \;

#END
