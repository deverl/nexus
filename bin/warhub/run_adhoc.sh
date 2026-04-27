#!/usr/bin/env bash

usage() {
    echo ""
    echo "Usage: $0 [-l LIMIT|--limit LIMIT] [-f INPUT_FILE|--file INPUT_FILE] [-h|--help] MODULE_TO_RUN"
    echo ""
    echo "Options:"
    echo "  -l, --limit LIMIT      Number of records to process (default: 25)"
    echo "  -f, --file INPUT_FILE  Path to csv input file"
    echo "  -h, --help             Show this help message and exit"
    echo ""
    echo "Examples:"
    echo "  $0 -l 1000 WARH_2991_nrac_custom_fields"
    echo "  $0 --file /tmp/data.txt WARH_2991_nrac_custom_fields"
    echo ""
}

LIMIT=25
INPUT_FILE=""

# ---- Translate long options to short options before getopts ----
for arg in "$@"; do
    shift
    case "$arg" in
        --help)  set -- "$@" "-h" ;;
        --limit) set -- "$@" "-l" ;;
        --file)  set -- "$@" "-f" ;;
        *)       set -- "$@" "$arg" ;;
    esac
done

# ---- Parse options with getopts ----
while getopts ":l:f:h" opt; do
    case $opt in
        l)
            LIMIT="$OPTARG"
            ;;
        f)
            INPUT_FILE="$OPTARG"
            ;;
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Unknown option: -$OPTARG"
            usage
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            usage
            exit 1
            ;;
    esac
done

# ---- Remove parsed options ----
shift $((OPTIND - 1))

# ---- Expect exactly one positional argument ----
if [ $# -ne 1 ]; then
    echo "Error: You must supply exactly one MODULE_TO_RUN argument."
    usage
    exit 1
fi

MODULE_TO_RUN="$1"

# ---- Validate LIMIT is numeric ----
if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
    echo "Error: LIMIT must be a positive integer. Got: $LIMIT"
    exit 1
fi

# ---- Validate INPUT_FILE exists (if provided) ----
if [ -n "$INPUT_FILE" ]; then
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: INPUT_FILE does not exist or is not a file: $INPUT_FILE"
        exit 1
    fi
fi

echo "LIMIT = $LIMIT"
if [ -n "$INPUT_FILE" ]; then
    echo "INPUT_FILE = $INPUT_FILE"
fi

set -x

# ---- Build command ----
CMD=( ./manage.py adhoc_task_handler
      --module "$MODULE_TO_RUN"
      --limit "$LIMIT"
      --print_success
      --commit True )

# Add file if provided
if [ -n "$INPUT_FILE" ]; then
    CMD+=( --file "$INPUT_FILE" )
fi

# ---- Execute command ----
"${CMD[@]}" 2>> /tmp/run_adhoc.log
