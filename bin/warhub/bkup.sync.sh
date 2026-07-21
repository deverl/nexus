#!/usr/bin/env bash

TARGET_BKUP_DIR=~/opt/db_bkup

REMOTE_BASE_DIR='depot:/mnt/sfo3_dbdump_storage'

EXCLUDES='--exclude _backup.log.xz --exclude defaultdb.tar.xz.age'

mkdir -p $TARGET_BKUP_DIR

rsync -av $EXCLUDES $REMOTE_BASE_DIR/backups/current/      $TARGET_BKUP_DIR

rsync -av $EXCLUDES $REMOTE_BASE_DIR/backups-s002/current/ $TARGET_BKUP_DIR

rsync -av $EXCLUDES $REMOTE_BASE_DIR/backupsdev/current/   $TARGET_BKUP_DIR

#
# eval $(op signin)
#
# for F in *.age
# do
#     echo $(basename $F .tar.xz.age)
#     BN=$(basename $F .age)
#     op read "op://Development/Development DB Backups AGE Key/Private Key" | age -d -i - -o $BN $F
# done
#
