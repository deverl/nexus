#!/usr/bin/env bash

if [ $# == 0 ]; then
	echo  "Commands: start, stop, allow <username>, deny <username>"
	exit
fi

case "$1" in
	start)
		echo 'Starting Remote Access'
		# Activate Apple Remote Access with current settings
		sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate
		;;
	stop)
		echo 'Stopping Remote Access'
		# Deactivate Apple Remote Access
		sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop
		;;
	allow)
		if [ -z "$2" ]; then
			echo  "ERROR: Provide a valid user"
			exit
		fi
		sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -specifiedUsers
		sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -access -on -privs -all -users ${2}
		;;
	deny)
		if [ -z "$2" ]; then
			echo  "ERROR: Provide a valid user"
			exit
		fi
		sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -specifiedUsers
		sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -access -off -privs -none -users ${2}
		;;
esac