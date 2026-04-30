#!/usr/bin/env bash

if [ -z "$INFRA" ]
then
    INFRA=~/develop/infrastructure
fi

scp bb:/usr/local/bin/build_and_deploy.py             $INFRA/build-box/usr/local/bin/

scp bb:/usr/local/etc/build_and_deploy_vanguard.json  $INFRA/build-box/usr/local/etc/

