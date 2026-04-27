#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    printf "\nERROR: You must provide the namespace and the base file name of your command.\n\n"
    printf "       e.g. cp_cmd_to_core.sh nrac WARH_3197_fix_nrac_parts_labor_compressor_expiry\n\n"
    exit 1
fi

NAMESPACE=$1
CMD=$2

LOCAL_PATH="$HOME/develop/vanguard/jaguar/bbp/management/commands/adhoc_tasks/$CMD/$CMD.py"


if [ ! -f "$LOCAL_PATH" ]
then
    printf "\nERROR: %s not found!\n\n" "$LOCAL_PATH"
    exit 1
fi

# Find the first running pod matching "core-"
pod=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running \
      -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
      | grep '^core-' | head -n 1)

if [ -z "$pod" ]; then
    printf "ERROR: No running pod found matching 'core-' in namespace $NAMESPACE\n"
    exit 1
fi

printf "Using pod: %s\n", $pod

REMOTE_PATH="$NAMESPACE/$pod:/jaguar/bbp/management/commands/adhoc_tasks/$CMD/$CMD.py"

# Create the target directory inside the pod
kubectl exec -n $NAMESPACE "$pod" -- mkdir -p "/jaguar/bbp/management/commands/adhoc_tasks/$CMD"

kubectl cp "$LOCAL_PATH" "$REMOTE_PATH"

printf "File copied successfully to %s\n", $pod


