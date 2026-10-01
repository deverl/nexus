#!/usr/bin/env bash

# Show the most recent migrations in the bbp app and warn about any
# duplicate migration numbers.
# Usage: migrate.check.sh [-n COUNT] [-v]

MIGRATIONS_DIR=${JAGUAR_DIRECTORY}/bbp/migrations
COUNT=10
VERBOSE=0

# Permanent duplicate prefixes. Omitted from the warning unless -v/--verbose.
IGNORE_DUPES=(0325)

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n)
            if [[ -z "$2" || ! "$2" =~ ^[0-9]+$ ]]; then
                echo "Error: -n requires a numeric argument" >&2
                exit 1
            fi
            COUNT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            echo "Usage: migrate.check.sh [-n COUNT] [-v]"
            echo "  -n COUNT       number of migrations to show (default: $COUNT)"
            echo "  -v, --verbose  also report ignored duplicate prefixes (${IGNORE_DUPES[*]})"
            exit 0
            ;;
        *)
            echo "Usage: migrate.check.sh [-n COUNT] [-v]" >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "$MIGRATIONS_DIR" ]]; then
    echo "Error: migrations directory not found: $MIGRATIONS_DIR" >&2
    exit 1
fi

cd "$MIGRATIONS_DIR" || exit 1

ls -1 | tail -n "$COUNT"

# Check the whole directory, not just the tail, so nothing slips past.
dupes=$(ls -1 | grep -E '^[0-9]{4}_' | cut -c1-4 | sort | uniq -d)
if [[ "$VERBOSE" -eq 0 ]]; then
    filtered=()
    for num in $dupes; do
        ignore=0
        for skip in "${IGNORE_DUPES[@]}"; do
            if [[ "$num" == "$skip" ]]; then
                ignore=1
                break
            fi
        done
        if [[ $ignore -eq 0 ]]; then
            filtered+=("$num")
        fi
    done
    dupes="${filtered[*]}"
fi
if [[ -n "$dupes" ]]; then
    # Only emit color codes when stderr is a terminal (not piped/redirected).
    if [[ -t 2 ]]; then
        RED=$'\033[31m'
        BOLD=$'\033[1m'
        RESET=$'\033[0m'
    else
        RED='' BOLD='' RESET=''
    fi
    echo >&2
    echo "${BOLD}${RED}WARNING: duplicate migration numbers found:${RESET}" >&2
    for num in $dupes; do
        ls -1 | grep -E "^${num}_" | sed "s/^/    ${RED}/; s/\$/${RESET}/" >&2
    done
    exit 2
fi
