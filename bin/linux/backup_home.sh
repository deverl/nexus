#!/usr/bin/env bash

cd ~

HOMEDIR=$(basename $(pwd))

USER=$HOMEDIR

COMPRESSION=0
ENCRYPT=0
LISTING=0

function show_help() {
    echo ""
    echo "backup_home.sh"
    echo ""
    echo "usage: backup_home.sh [opts]"
    echo "  opts:"
    echo "      -0, --no-compression    Do not compress the resulting archive file (default)"
    echo "      -1, --use-gzip          Compress using gzip (.tgz)"
    echo "      -2, --use-bzip2         Compress using bzip2 (.tbz)"
    echo "      -e, --encrypt           Encrypt the resulting archive file. Will encrypt and add .gpg"
    echo "      -h, --help              Show this help screen then exit"
    echo "      -l, --listing           Create a listing file"
    echo ""
}

while [ $# -gt 0 ]
do
    if [ "$1" = "-2" -o "$1" = "--use-bzip2" ]
    then
        COMPRESSION=2
    elif [ "$1" = "-1" -o "$1" = "--use-gzip" ]
    then
        COMPRESSION=1
    elif [ "$1" = "-0" -o "$1" = "--no-compressoin" ]
    then
        COMPRESSION=0
    elif [ "$1" = "-e" -o "$1" = "--encrypt" ]
    then
        ENCRYPT=1
    elif [ "$1" = "-h" -o "$1" = "--help" ]
    then
        show_help
        exit 1
    elif [ "$1" = "-l" -o "$1" = "--listing" ]
    then
        LISTING=1
    else
        echo "ERROR: Invalid option: '$1'"
        exit 1
    fi
    shift
done

cd ~

rm -f ${USER}*.tar* ${USER}*.tbz* ${USER}*.tgz*

cd ..

CMDLINE="cf"
EXTENSION=tar

if [ $COMPRESSION -eq 1 ]
then
    CMDLINE="czf"
    EXTENSION=tgz
elif [ $COMPRESSION -eq 2 ]
then
    CMDLINE="cjf"
    EXTENSION=tbz
fi

TARGET=$USER.$EXTENSION

tar $CMDLINE /tmp/$TARGET \
    --exclude "dstokes/.atom" \
    --exclude "dstokes/.cache" \
    --exclude "dstokes/.cargo" \
    --exclude "dstokes/.config" \
    --exclude "dstokes/go" \
    --exclude "dstokes/.local" \
    --exclude "dstokes/.npm" \
    --exclude "dstokes/.nvm" \
    --exclude "dstokes/octave" \
    --exclude "dstokes/.octave_packages" \
    --exclude "dstokes/.rustup" \
    --exclude "dstokes/.vscode" \
    --exclude "dtokes/.downloads" \
    --exclude ".git" \
    --exclude "Gravity.mp4" \
    --exclude "nexus/bin/cygwin" \
    --exclude "nexus/bin/mac" \
    --exclude "nexus/bin/mugs" \
    --exclude "nexus/bin/rightscale" \
    --exclude "nexus/bin/tsheets" \
    --exclude "nexus/bin/unity" \
    --exclude "nexus/bin/win" \
    --exclude "nexus/Config/win" \
    --exclude "node_modules" \
    --exclude "__pycache__" \
    --exclude "*/target/debug" \
    --exclude "*/target/doc" \
    --exclude "*/target/release" \
    -v \
    $HOMEDIR


TS=$(date "+%Y%m%dT%H%M")

FNAME=${USER}-$TS.$EXTENSION

mv /tmp/${USER}.$EXTENSION ~/$FNAME

cd ~


if [ $LISTING -gt 0 ]
then
    echo ""
    echo "Creating listing file..."
    tar tf $FNAME > $FNAME.txt
fi

if [ $ENCRYPT -eq 1 ]
then
    echo "Encrypting..."
    time gpg -c -o $FNAME.gpg $FNAME
fi

ls -lh $FNAME*

mv $FNAME* /mnt/chromeos/MyFiles/

echo ""
echo "done."

