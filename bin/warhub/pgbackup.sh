#!/usr/bin/env bash

if [ -z "$1" ]
then
    echo "ERROR: You must provide the database name"
    exit 1
fi

echo -n "Backing up..."

PGPASSWORD=$(initool --get ~/.warrantyhub.ini passwords postgresql)

export PGPASSWORD

pg_dump -h localhost -p 5432 -U core -c -Ft "$1" > "${1}.tar"

echo "done."

echo -n "Compressing..."

xz -9 "${1}.tar"

echo "done."

ls -lh "${1}.tar.xz"
