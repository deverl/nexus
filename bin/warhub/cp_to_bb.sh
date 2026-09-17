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

scp $INFRA_DIRECTORY/build-box/usr/local/bin/build_and_deploy.py bb:/usr/local/bin

scp $INFRA_DIRECTORY/build-box/usr/local/etc/build_and_deploy_vanguard.json bb:/usr/local/etc

ssh bbn 'bin/sign_json.sh'

