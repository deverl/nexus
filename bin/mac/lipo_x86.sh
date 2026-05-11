#!/usr/bin/env bash

for app in /Applications/*.app; do
    macos_dir="$app/Contents/MacOS"
    if [ -d "$macos_dir" ]; then
        for binary in "$macos_dir"/*; do
            if [ -f "$binary" ]; then
                archs=$(lipo -archs "$binary" 2>/dev/null)
                if [ "$archs" = "x86_64" ]; then
                    echo "x86-only: $binary"
                fi
            fi
        done
    fi
done
