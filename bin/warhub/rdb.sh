#!/usr/bin/env bash

# Restores databases from the ~/opt/db_bkup directory.
#
# Each argument is treated as either an exact database name or a pattern that is
# matched against the names of the backed-up databases. Every matching database
# is restored. Multiple names/patterns may be given.
#
# If "all" is given as an argument, every backed-up database is restored.
#
# Examples:
#   restoredb.sh smokeautomotive          # restore one database by name
#   restoredb.sh smoke                     # restore all databases matching "smoke"
#   restoredb.sh smokeautomotive widget    # restore everything matching either term
#   restoredb.sh all                       # restore every backed-up database

if [ $# -eq 0 ]
then
    echo "ERROR: You must provide at least 1 db name, pattern, or \"all\""
    exit 1
fi

export TARGET_BKUP_DIR=~/opt/db_bkup

if [ -z "$LOGFILE" ]
then
    export LOGFILE=/tmp/db_bkup.log
fi

if [ ! -d "$TARGET_BKUP_DIR" ]
then
    echo "ERROR: No backup directory!"
    exit 1
fi

export PGPASSWORD=$(initool --get ~/.warrantyhub.ini passwords postgresql)

cd "$TARGET_BKUP_DIR" || exit 1

# Collect the available backups.
shopt -s nullglob
ALL_FILES=( *.tar.xz.age )
shopt -u nullglob

if [ ${#ALL_FILES[@]} -eq 0 ]
then
    echo "ERROR: No backups found in $TARGET_BKUP_DIR"
    exit 1
fi

# Resolve the list of databases to restore, de-duplicating as we go.
declare -a DBS=()

add_db() {
    local db="$1"
    local existing
    for existing in "${DBS[@]}"
    do
        [ "$existing" = "$db" ] && return
    done
    DBS+=("$db")
}

RESTORE_ALL=0
for arg in "$@"
do
    if [ "$arg" = "all" ]
    then
        RESTORE_ALL=1
    fi
done

if [ "$RESTORE_ALL" -eq 1 ]
then
    for F in "${ALL_FILES[@]}"
    do
        add_db "$(basename "$F" .tar.xz.age)"
    done
else
    for arg in "$@"
    do
        matched=0
        for F in "${ALL_FILES[@]}"
        do
            DB_NAME=$(basename "$F" .tar.xz.age)
            if grep -q "$arg" <<< "$DB_NAME"
            then
                add_db "$DB_NAME"
                matched=1
            fi
        done
        if [ "$matched" -eq 0 ]
        then
            echo "WARNING: No backups matched \"$arg\""
        fi
    done
fi

if [ ${#DBS[@]} -eq 0 ]
then
    echo "ERROR: No databases matched the given name(s)/pattern(s)"
    exit 1
fi

eval $(op signin)

echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Starting restore\" count=${#DBS[@]}" >> "$LOGFILE"

for DB in "${DBS[@]}"
do
    XZ_FILE_NAME=${DB}.tar.xz
    AGE_FILE_NAME=${XZ_FILE_NAME}.age
    echo "$DB"
    op read "op://Development/Development DB Backups AGE Key/Private Key" | age -d -i - -o "$XZ_FILE_NAME" "$AGE_FILE_NAME"

    echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Restoring $DB\"" >> "$LOGFILE"

    restore_sql.sh "${DB}" core localhost 5432 "$XZ_FILE_NAME" delete

    echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Done restoring $DB\"" >> "$LOGFILE"

    rm -f "$XZ_FILE_NAME"
done

echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Done restoring\" count=${#DBS[@]}" >> "$LOGFILE"
