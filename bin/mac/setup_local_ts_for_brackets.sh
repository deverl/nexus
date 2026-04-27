#!/usr/bin/env bash

for D in css images include winc
do
    echo "Working on $D..."

    if [ -L $D ]
    then
        unlink $D
    fi

    rsync -av --exclude='.svn' --delete-excluded ~/develop/shazdev2/$D/ $D/
done


if [ ! -d css.local ]
then
    mkdir css.local
fi

cd css.local

curl -s https://staff.tsheets.com/css.php -o css.php.css

cd ..



