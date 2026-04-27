#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status and print all commands executed.
set -e

# Ensure PGPASSWORD environment variable is set.
if [[ -z "$PGPASSWORD" ]]; then
  echo "You must set the PostgreSQL password in the environment, such as: PGPASSWORD=password ./restore_remote.sh <DB> [REMOTE FILE]"
  exit 1
fi

# Check if the first argument (DB name) is provided. If not, exit with a usage message.
if [[ -z "$1" ]]; then
  echo "usage: ${0} <DB> [REMOTE FILE : optional]"
  exit 1
fi

# Assign DB name and optional remote file name variables.
DB=$1
REMOTE_FILE=$2


# Define remote server configurations.
REMOTE_DIR=/mnt/sfo3_dbdump_storage/backups/current/
REMOTE_HOST=146.190.164.209

# If REMOTE_FILE is not provided as an argument, set it to a default name based on DB.
if [[ -z $REMOTE_FILE ]]; then
  REMOTE_FILE=${DB}.tar.xz
fi

echo $DB >> $LOGFILE

# Download the backup file from the remote server.
if [[ -z $SKIP_DOWNLOAD ]]; then
    echo "    Starting download at $(date "+%Y-%m-%dT%H:%M:%S")" >> $LOGFILE
    sftp $(whoami)@${REMOTE_HOST}:${REMOTE_DIR}${REMOTE_FILE} .
fi

if [[ -z $SKIP_RESTORE ]]; then
    # Restore the database using `restore_sql.sh` script with provided parameters.
    echo "    Restoring at $(date "+%Y-%m-%dT%H:%M:%S")" >> $LOGFILE
    restore_sql.sh ${DB} core localhost 5432 ${REMOTE_FILE} delete
fi
