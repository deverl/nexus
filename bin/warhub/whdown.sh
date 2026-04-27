#!/usr/bin/env bash

function show_usage() {
    echo "whdown.sh [opts]"
    echo ""
    echo "Shuts down the jaguar containers"
    echo "  opts:"
    echo "      -h, --help     show this screen and exit"
    echo "      -p, --prune    run docker.prune after the shutdown"
}

PRUNE=false

# Parse options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_usage
            shift
            ;;
        -p|--prune)
            PRUNE=true
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

cd ~/develop/vanguard/jaguar || {
    echo "ERROR: Failed to change directory"
    exit 1
}

echo "[INFO] Running dco down"
docker compose down

if [ "$PRUNE" = true ]
then
    echo "[INFO] Running docker.prune"
    docker.prune
fi
