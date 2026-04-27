#!/usr/bin/env bash

ssh mbp 'backup_home.sh -2'

FNAME=$(ssh mbp 'ls -1 Backups | sort -r | head -1') 2> /dev/null

scp mbp:Backups/$FNAME .

gpg -c -o /mnt/chromeos/MyFiles/${FNAME}.gpg $FNAME

rm -f $FNAME
