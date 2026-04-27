#!/usr/bin/env bash

cd ~/develop/vanguard

dpy() {
    docker exec -it jaguar-debug python manage.py "$@"
}

# Reverse the migration
dpy migrate bbp 0167

# Go back to the commit hash for just db-prep
git co 9cfb6e269949ae36e8db79248d6e14ddfd26545b

# Run the prep in reverse direction
dpy adhoc_task_handler --module WARH_2920_tenant_id_db_migrations --no_transaction True --extra_options '{"direction":"reverse"}'


