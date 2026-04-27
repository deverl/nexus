#!/usr/bin/env bash

set -e

LOG=false
DRY_RUN=false

# Parse options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -l|--log)
            LOG=true
            shift
            ;;
        -d|--dry_run)
            DRY_RUN=true
            shift
            ;;
        -*)
            echo "ERROR: Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Check for required argument
if [ -z "$1" ]; then
    echo "ERROR: You must provide the name of the environment to run!"
    exit 1
fi

DB="$1"

cd ~/develop/vanguard/jaguar || {
    echo "ERROR: Failed to change directory"
    exit 1
}

# Show the starting db name
echo "Starting DB_NAME:"
grep "^DB_NAME=" dev_env

# Edit the dev_env file
sed -i '' "s/^DB_NAME=.*/DB_NAME=$DB/" dev_env

# Show updated value
echo "Updated DB_NAME:"
grep "^DB_NAME=" dev_env

# Restart services (unless dry run)
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Skipping: docker compose down"
    echo "[DRY RUN] Skipping: docker compose up -d debug celery"
else
    echo "[INFO] Running dco down"
    docker compose down
    echo "[INFO] Running dco up debug celery"
    docker compose up -d debug celery
fi

# Restore DB_NAME to rc
sed -i '' 's/^DB_NAME=.*/DB_NAME=rc/' dev_env

# Show final value
echo "Restored DB_NAME:"
grep "^DB_NAME=" dev_env

# Tail logs only if requested
if [ "$LOG" = true ]; then
    tail -f data/jaguar/logs/bbp.log | hl -F -P
fi