#!/usr/bin/env bash

launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.dstokes.db_rsync.plist

launchctl enable    gui/$(id -u)/com.dstokes.db_rsync

