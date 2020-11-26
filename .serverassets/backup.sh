#!/bin/sh
. ./shvars

ssh ${username}@${ipv4_address} '/mcdata/manage.sh --backup'
rsync -avz ${username}@${ipv4_address}:/mcdata/backups/last_backup $last_backup_path
last_backup=$(cat $last_backup_path)

rsync -avz ${username}@${ipv4_address}:/mcdata/backups/$last_backup $backupdir