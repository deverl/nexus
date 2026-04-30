#!/usr/bin/env bash

if [ -z "$INFRA" ]
then
    INFRA=~/develop/infrastructure
fi

scp $INFRA/build-box/usr/local/bin/build_and_deploy.py bb:/usr/local/bin

scp $INFRA/build-box/usr/local/etc/build_and_deploy_vanguard.json bb:/usr/local/etc

ssh bb 'bin/sign_json.sh'

