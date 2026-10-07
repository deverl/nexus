#!/usr/bin/env bash

# Restores databases from the ~/opt/db_bkup directory.
#
# Each argument is treated as either an exact database name or a pattern that is
# matched against the names of the backed-up databases. Every matching database
# is restored. Multiple names/patterns may be given.
#
# If "all" is given as an argument, every backed-up database is restored.
#
# After each restore, adopt_snapshot.sql is applied so the database is safe to
# use locally. Pass -n / --no-adopt to skip that cleanup.
#
# Options:
#   -d, --dry_run   Show which databases would be restored without doing anything.
#   -e, --exact     Only restore databases whose name exactly matches an argument.
#   -n, --no-adopt  Restore only; do not run adopt_snapshot.sql.
#
# Examples:
#   restoredb.sh smokeautomotive          # restore one database by name
#   restoredb.sh smoke                     # restore all databases matching "smoke"
#   restoredb.sh smokeautomotive widget    # restore everything matching either term
#   restoredb.sh all                       # restore every backed-up database
#   restoredb.sh -d smoke                  # show what "smoke" would restore, but do nothing
#   restoredb.sh -e nrac                   # restore only "nrac", not "nractraining"
#   restoredb.sh -n smokeautomotive        # restore without running adopt_snapshot.sql

usage() {
    cat <<'EOF'
Usage: rdb.sh [OPTIONS] NAME|PATTERN [NAME|PATTERN ...]
       rdb.sh [OPTIONS] all

Restores databases from the ~/opt/db_bkup directory.

Each argument is treated as either an exact database name or a pattern that is
matched against the names of the backed-up databases. Every matching database
is restored. Multiple names/patterns may be given. If "all" is given, every
backed-up database is restored.

After each successful restore, adopt_snapshot.sql is applied so the database is
safe to use locally. Pass -n / --no-adopt to skip that cleanup.

Options:
  -d, --dry_run   Show which databases would be restored without doing anything.
  -e, --exact     Only restore databases whose name exactly matches an argument.
  -n, --no-adopt  Restore only; do not run adopt_snapshot.sql.
  -h, --help      Show this help message and exit.

Examples:
  rdb.sh smokeautomotive          # restore one database by name
  rdb.sh smoke                    # restore all databases matching "smoke"
  rdb.sh smokeautomotive widget   # restore everything matching either term
  rdb.sh all                      # restore every backed-up database
  rdb.sh -d smoke                 # show what "smoke" would restore, but do nothing
  rdb.sh -e nrac                  # restore only "nrac", not "nractraining"
  rdb.sh -n smokeautomotive       # restore without running adopt_snapshot.sql
EOF
}

DRY_RUN=0
EXACT=0
NO_ADOPT=0
WARHUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -a ARGS=()
for arg in "$@"
do
    case "$arg" in
        -h|--help)
            usage
            exit 0
            ;;
        -d|--dry_run)
            DRY_RUN=1
            ;;
        -e|--exact)
            EXACT=1
            ;;
        -n|--no-adopt)
            NO_ADOPT=1
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done
set -- "${ARGS[@]}"

if [ $# -eq 0 ]
then
    echo "ERROR: You must provide at least 1 db name, pattern, or \"all\""
    echo "Run 'rdb.sh --help' for usage."
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
            if [ "$EXACT" -eq 1 ]
            then
                if [ "$DB_NAME" = "$arg" ]
                then
                    add_db "$DB_NAME"
                    matched=1
                fi
            elif grep -q "$arg" <<< "$DB_NAME"
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

if [ "$DRY_RUN" -eq 1 ]
then
    echo "DRY RUN: The following ${#DBS[@]} database(s) would be restored:"
    for DB in "${DBS[@]}"
    do
        echo "  $DB"
    done
    if [ "$NO_ADOPT" -eq 1 ]
    then
        echo "DRY RUN: adopt_snapshot.sql would be skipped (--no-adopt)."
    else
        echo "DRY RUN: adopt_snapshot.sql would be applied to each restored database."
    fi
    exit 0
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

    # if ! restore_sql.sh "${DB}" core localhost 5432 "$XZ_FILE_NAME" delete
    # then
    #     echo "ERROR: restore failed for $DB" >&2
    #     echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Failed restoring $DB\"" >> "$LOGFILE"
    #     rm -f "$XZ_FILE_NAME"
    #     exit 1
    # fi

    echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Done restoring $DB\"" >> "$LOGFILE"

    printf "Done restoring $DB\n"

    if [ "$NO_ADOPT" -eq 0 ]
    then
        printf "Adopting snapshot $DB\n"
        echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Adopting snapshot $DB\"" >> "$LOGFILE"
        if ! psql -h localhost -U core -p 5432 -d "$DB" -v ON_ERROR_STOP=1 -f "$WARHUB_DIR/adopt_snapshot.sql"
        then
            echo "ERROR: adopt_snapshot.sql failed for $DB" >&2
            echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Failed adopting snapshot $DB\"" >> "$LOGFILE"
            rm -f "$XZ_FILE_NAME"
            exit 1
        fi
        echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Done adopting snapshot $DB\"" >> "$LOGFILE"
    fi

    rm -f "$XZ_FILE_NAME"
done

echo "date=$(date "+%Y-%m-%d") time=$(date "+%H:%M:%S") msg=\"Done restoring\" count=${#DBS[@]}" >> "$LOGFILE"
