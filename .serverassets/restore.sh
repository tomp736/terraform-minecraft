#!/bin/sh
. ./shvars

if [ -f "$last_backup_path" ]; then
    scp $last_backup_path ${username}@${ipv4_address}:/mcdata/backups/last_backup 
    rsync -avz $backupdir/$last_backup ${username}@${ipv4_address}:/mcdata/backups --delete
    ssh ${username}@${ipv4_address} '/mcdata/manage.sh --restore'
fi