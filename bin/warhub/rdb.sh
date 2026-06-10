#!/usr/bin/env bash

if [ $# -eq 0 ]
then
    echo "ERROR: You must provide at least 1 db name"
    exit 1
fi

export TARGET_BKUP_DIR=~/opt/db_bkup

if [ -z "$LOGFILE" ]
then
    export LOGFILE=/tmp/db_bkup.log
fi

if [ ! -d $TARGET_BKUP_DIR ]
then
    echo "ERROR: No backup directory!"
    exit 1
fi

export PGPASSWORD=$(initool --get ~/.warrantyhub.ini passwords postgresql)

cd $TARGET_BKUP_DIR

eval $(op signin)

while [ $# -gt 0 ]
do
    DB="$1"
    XZ_FILE_NAME=${DB}.tar.xz
    AGE_FILE_NAME=${XZ_FILE_NAME}.age
    echo $DB
    op read "op://Development/Development DB Backups AGE Key/Private Key" | age -d -i - -o $XZ_FILE_NAME $AGE_FILE_NAME

    echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Restoring $DB\"" >> $LOGFILE
    
    restore_sql.sh ${DB} core localhost 5432 $XZ_FILE_NAME delete

    echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Done restoring $DB\"" >> $LOGFILE
    
    rm -f $XZ_FILE_NAME

    shift
done

