#!/usr/bin/env bash

mr=${1:-}
ticket=${2:-}
db=${3:-}

[[ -z $mr ]] && read -rp "MR: " mr
[[ -z $ticket ]] && read -rp "Ticket (#### or PREFIX-####): " ticket
[[ -z $db ]] && read -rp "Database: " db

# Digits alone default to WARH-; any prefix already in the argument is kept.
if [[ $ticket =~ ^[0-9]+$ ]]; then
  ticket="WARH-${ticket}"
fi

template=$(cat <<'EOF'
Please do a detailed worktree MR review of MR !<MR>.  The associated ticket is <TICKET>.

Treat <TICKET> as the ticket for this review, even if the branch name has a different key or none.

You can use the glab command line tool to read the merge request, and you can use the linear-cli command line tool to read the ticket. The linear MCP is also available as a service in Claude.

Please use all claude configuration and guidance you can find.

Read the MR discussion, including unresolved threads. If .claude/tmp/mr-review-<MR>.md already exists, read it too. Say which earlier findings are fixed, still open, or new.

Do not post, push, commit, or edit the merge request.

After the written review, run the test plan in the MR description, plus the unit tests that cover the production files in the diff. Report each as passed, failed, or skipped, and include the failure output. Skip that run when CI is already green and the diff has no production code.

Then bring up the stack on the <DB> database. If that database already exists in local Postgres, point this worktree at it with ./stack set-db <DB> and leave the data in place. If it does not, restore the exact backup $HOME/opt/db_bkup/<DB>.tar.xz.age by running rdb.sh -e <DB>, then ./stack set-db <DB>. Use that local file as the only source. Do not run ./stack load-db and do not fetch a snapshot from depot. If that backup file is missing, or rdb.sh stops to wait for a 1Password sign-in, stop and say so. If the MR adds migrations, say whether they apply on that database before treating the stack as up. Skip the "what next?" question and do this after the tests.

After the stack is up, list the WTBD items that still need a person in the browser. For each one, give a concrete step and the result you expect. Stop there.
EOF
)

output="${template//<MR>/$mr}"
output="${output//<TICKET>/$ticket}"
output="${output//<DB>/$db}"

printf '%s\n' "$output" | pbcopy

echo "Copied to clipboard."
