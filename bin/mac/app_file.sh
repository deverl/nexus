#!/usr/bin/env bash

for app in /Applications/*.app; do
    macos_dir="$app/Contents/MacOS"
    if [ -d "$macos_dir" ]; then
        find "$macos_dir" -type f -exec file {} \;
    fi
done
