#!/usr/bin/env bash

for app in /Applications/*.app; do
    macos_dir="$app/Contents/MacOS"
    if [ -d "$macos_dir" ]; then
        for binary in "$macos_dir"/*; do
            if [ -f "$binary" ]; then
                file_output=$(file "$binary")
                # Match Mach-O x86_64 binaries that are NOT universal/fat
                # and do NOT contain arm64
                if echo "$file_output" | grep -q "Mach-O.*x86_64" && \
                   ! echo "$file_output" | grep -q "arm64" && \
                   ! echo "$file_output" | grep -q "universal"; then
                    echo "x86-only: $binary"
                fi
            fi
        done
    fi
done
