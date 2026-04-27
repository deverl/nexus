#!/usr/bin/env bash

if [ $# -eq 0 ]
then
    echo "ERROR: You must provide at least one .age file to decrypt."
    exit 1
fi

eval $(op signin)

while [ $# -gt 0 ]
do
    AGE_FILE="$1"
    DECRYPTED_FILE=$(basename $AGE_FILE .age)

    echo -n "Decrypting $AGE_FILE to $DECRYPTED_FILE..."

    op read "op://Development/Development DB Backups AGE Key/Private Key" | age -d -i - -o $DECRYPTED_FILE $AGE_FILE

    echo "done."

    shift
done
