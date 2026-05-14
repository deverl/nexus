#!/usr/bin/env bash

cd ~/Parallels

F=$(ls -1 alpine*.tar.xz | sort -r | head -n 1)

if [ -z "$F" ]
then
    echo "ERROR: No archived files found!"
    exit 1
fi

# echo "F = $F"

echo -n "Decompressing..."

xz -d -k $F

echo "done."

TAR_FILE=$(basename $F .xz)

# echo "TAR_FILE = $TAR_FILE"

if [ ! -f $TAR_FILE ]
then
    echo "ERROR: Tar file not found"
    exit 1
fi

echo -n "Untarring..."

gtar xf $TAR_FILE

echo "done."

rm -rf $TAR_FILE

ls -lh

