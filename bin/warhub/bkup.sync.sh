#!/usr/bin/env bash

TARGET_BKUP_DIR=~/opt/db_bkup

mkdir -p $TARGET_BKUP_DIR

rsync -av --delete depot:/mnt/sfo3_dbdump_storage/backups/current/ $TARGET_BKUP_DIR

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
