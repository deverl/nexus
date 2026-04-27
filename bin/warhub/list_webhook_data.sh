#!/usr/bin/env bash

for file in $(stat -f "%SB %N" -t "%Y%m%d%H%M%S" webhook*.json | sort | cut -d' ' -f2-); do
    echo "===== $file ====="
    cat "$file"
    echo
done



