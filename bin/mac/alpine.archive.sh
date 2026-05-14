#!/usr/bin/env bash

cd ~/Parallels

if [ ! -d 'Alpine Linux Xfce.pvm' ]
then
    echo "ERROR: Alpine Linux Xfce.pvm is not present!"
    exit 1
fi

TS=$(date "+%Y%m%dT%H%M%S")

TAR_FILE=alpine_xfce_${TS}.tar

echo -n "Tarring..."

gtar cf $TAR_FILE 'Alpine Linux Xfce.pvm'

echo "done."

echo -n "Compressing..."

xz -2 $TAR_FILE

echo "done."

rm -rf 'Alpine Linux Xfce.pvm'

du -hs $TAR_FILE.xz

