#!/usr/bin/env bash

mr=${1:-}
ticket=${2:-}
db=${3:-}

[[ -z $mr ]] && read -rp "MR: " mr
[[ -z $ticket ]] && read -rp "Ticket (WARH-): " ticket
[[ -z $db ]] && read -rp "Database: " db

template=$(cat <<'EOF'
Please do a detailed worktree MR review of MR <MR>.  The associated ticket is WARH-<TICKET>.

You can use the glab command line tool to read the merge request, and you can use the linear-cli command line tool to read the ticket.

Please use all claude configuration and guidance you can find.

After the review, please run all of the tests mentioned in the MR.

Then, please bring up the stack using the <DB> database.
EOF
)

output="${template//<MR>/$mr}"
output="${output//<TICKET>/$ticket}"
output="${output//<DB>/$db}"

printf '%s\n' "$output" | pbcopy

echo "Copied to clipboard."
