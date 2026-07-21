#!/usr/bin/env bash

TARGET_BKUP_DIR=~/opt/db_bkup

REMOTE_BASE_DIR='depot:/mnt/sfo3_dbdump_storage'

EXCLUDES=(--exclude _backup.log.xz \
          --exclude defaultdb.tar.xz.age \
          --exclude unzip --exclude 'delme*')

mkdir -p $TARGET_BKUP_DIR

rsync -av "${EXCLUDES[@]}" $REMOTE_BASE_DIR/backups/current/      $TARGET_BKUP_DIR

rsync -av "${EXCLUDES[@]}" $REMOTE_BASE_DIR/backups-s002/current/ $TARGET_BKUP_DIR

rsync -av "${EXCLUDES[@]}" $REMOTE_BASE_DIR/backupsdev/current/   $TARGET_BKUP_DIR
