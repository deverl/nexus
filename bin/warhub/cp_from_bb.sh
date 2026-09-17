#!/usr/bin/env bash

if [ -z "$INFRA_DIRECTORY" ]
then
    INFRA_DIRECTORY=~/develop/infrastructure
fi

if [ ! -d "${INFRA_DIRECTORY}" ]
then
    printf "ERROR: '$INFRA_DIRECTORY not found\n"
    exit 1
fi

scp bb:/usr/local/bin/build_and_deploy.py             $INFRA_DIRECTORY/build-box/usr/local/bin/

scp bb:/usr/local/etc/build_and_deploy_vanguard.json  $INFRA_DIRECTORY/build-box/usr/local/etc/

