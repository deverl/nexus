#!/usr/bin/env bash

cd ~

for F in $(find ~/ -maxdepth 1 -type d -name ".*" | sed 's|^.*/||' | sort)
do
    du -hs $F
done

