#!/usr/bin/env bash

set -e

# Ensure PGPASSWORD environment variable is set.
if [[ -z "$PGPASSWORD" ]]; then
  echo "You must set the PostgreSQL password in the environment, such as: PGPASSWORD=password ${0} ..."
  exit 1
fi

# Check if the necessary arguments are provided.
if [[ -z "$6" ]]; then
  echo "usage: ${0} <DB> <USER> <HOST> <PORT> <FILE> <DELETE>"
  exit 1
fi

# Assign variables based on input arguments.
DB=$1
USER=$2
HOST=$3
PORT=$4
FILE=$5
DELETE=$6

# Number of jobs for pg_restore.
JOBS=8  # You can adjust this number based on the number of CPU cores available.

# Create a temporary directory for extraction.
TMP_DIR=$(mktemp -d)

# Using pxz for multi-threaded extraction.
#tar --use-compress-program=pxz -xvf "$FILE" -C "$TMP_DIR"
tar -xvf "$FILE" -C "$TMP_DIR"

# Drop and recreate the database if DELETE is specified.
if [[ "$DELETE" == "delete" ]]; then
  psql -U "$USER" -h "$HOST" -p "$PORT" -d postgres -c "drop database ${DB}" || true
  psql -U "$USER" -h "$HOST" -p "$PORT" -d postgres -c "create database ${DB}"
fi

# Navigate to the temporary directory and restore the database using pg_restore with multiple jobs.
pushd "$TMP_DIR"
pg_restore -v -U "$USER" -h "$HOST" -p "$PORT" -c --if-exists --disable-triggers -d "$DB" -F d .
#pg_restore -v -U "$USER" -h "$HOST" -p "$PORT" -c --if-exists --disable-triggers -d "$DB" -F d -j "$JOBS" .
popd

# Clean up the temporary directory.
rm -rf "$TMP_DIR"

