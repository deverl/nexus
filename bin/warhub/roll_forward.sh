#!/usr/bin/env bash

cd ~/develop/vanguard

dpy() {
    docker exec -it jaguar-debug python manage.py "$@"
}

# Checkout main, and go to this hash on the branch
# This will put you in detached HEAD mode
git checkout 9cfb6e269949ae36e8db79248d6e14ddfd26545b

# Run this command to add tenant_id to all tables and set it up with correct default value
dpy adhoc_task_handler --module WARH_2920_tenant_id_db_migrations --no_transaction True --extra_options '{"direction":"forward"}'

# Checkout latest main
git checkout main

# Run migrations
dpy migrate

