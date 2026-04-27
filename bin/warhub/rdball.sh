#!/usr/bin/env bash

TARGET_BKUP_DIR=~/opt/db_bkup

if [ ! -d $TARGET_BKUP_DIR ]
then
    echo "ERROR: No backup directory"
    exit 1
fi

export LOGFILE=/tmp/db_bkup.log

cd $TARGET_BKUP_DIR

echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Starting restore all\"" >> $LOGFILE

for F in *.age
do
    DB_NAME=$(basename $F .tar.xz.age)
    rdb.sh $DB_NAME
done

echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Done restoring all\"" >> $LOGFILE
