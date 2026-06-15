#!/usr/bin/env bash

# Restores all, or some of, the databases in the ~/opt/db_bkup directory.
#
# If run without arguments, it will restore every database that is backed up in ~/opt/db_bkup.
#
# The script will accept a single argument. If one is given, it is used as a pattern to match
# databases in the ~/opt_db_bkup directory. e.g. if you ran `rdball.sh smoke`, the script would
# restore smokeautomotive, smokeboat, smokebuilder, etc.

TARGET_BKUP_DIR=~/opt/db_bkup
PATTERN="$1"

if [ ! -d "$TARGET_BKUP_DIR" ]
then
    echo "ERROR: No backup directory"
    exit 1
fi

export LOGFILE=/tmp/db_bkup.log

cd "$TARGET_BKUP_DIR" || exit 1

echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Starting restore\" pattern=\"${PATTERN:-*}\"" >> "$LOGFILE"

for F in *.age
do
    if [ -n "$PATTERN" ] && ! grep -q "$PATTERN" <<< "$F"
    then
        continue
    fi
    DB_NAME=$(basename "$F" .tar.xz.age)
    rdb.sh "$DB_NAME"
done

echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Done restoring\" pattern=\"${PATTERN:-*}\"" >> "$LOGFILE"