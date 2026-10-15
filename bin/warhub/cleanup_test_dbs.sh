#!/usr/bin/env bash
# Drop PostgreSQL databases on localhost whose names start with test_,
# plus any additional database names passed as arguments.
#
# Usage:
#   ./cleanup_test_dbs.sh
#   ./cleanup_test_dbs.sh wt-new-warh-4449-cpm-basic-comms smokeautomotive
#   ./cleanup_test_dbs.sh -d
#   ./cleanup_test_dbs.sh --dry-run smokeautomotive
#
# Connects with: psql -h localhost -p 5432 -U core -d rc
# Password prompts still work: psql reads them from the terminal, not stdin.
# ~/.pgpass and PGPASSWORD are used when they are set.
# postgres, template0, and template1 are never dropped.

set -euo pipefail

pg_host=localhost
pg_port=5432
pg_user=core
pg_database=rc

psql=(psql -X -h "$pg_host" -p "$pg_port" -U "$pg_user" -d "$pg_database")

# Names to drop. Arguments are recorded first; test_* names from \l follow.
databases=()

trim() {
  local value=$1
  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}
  printf '%s' "$value"
}

# Quote a database name as a PostgreSQL identifier.
sql_ident() {
  local name=$1
  name=${name//\"/\"\"}
  printf '"%s"' "$name"
}

add_db() {
  local name existing
  name=$(trim "$1")
  if [[ -z $name ]]; then
    return 0
  fi
  case $name in
    postgres|template0|template1|core|rc)
      printf 'Skipping system database: %s\n' "$name" >&2
      return 0
      ;;
  esac
  if [[ $name == "$pg_database" ]]; then
    printf 'Skipping the database this script is connected to: %s\n' "$name" >&2
    return 0
  fi
  if ((${#databases[@]} > 0)); then
    for existing in "${databases[@]}"; do
      if [[ $existing == "$name" ]]; then
        return 0
      fi
    done
  fi
  databases+=("$name")
}

# Print one database name per line from psql's aligned \l output.
# Continuation rows (blank name column) and the header are ignored.
names_from_list() {
  local line name
  while IFS= read -r line || [[ -n $line ]]; do
    [[ $line == *"|"* ]] || continue
    name=${line%%|*}
    name=$(trim "$name")
    [[ -z $name ]] && continue
    [[ $name == "Name" ]] && continue
    [[ $name == -* ]] && continue
    printf '%s\n' "$name"
  done
}

main() {
  local arg name list_output parsed ident sql dry_run
  local -a db_args=()
  dry_run=0

  if ! command -v psql >/dev/null 2>&1; then
    printf 'psql not found in PATH\n' >&2
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case $1 in
      -d|--dry-run)
        dry_run=1
        shift
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          db_args+=("$1")
          shift
        done
        ;;
      -*)
        printf 'Unknown option: %s\n' "$1" >&2
        printf 'Usage: %s [-d|--dry-run] [database ...]\n' "$0" >&2
        exit 1
        ;;
      *)
        db_args+=("$1")
        shift
        ;;
    esac
  done

  if ((${#db_args[@]} > 0)); then
    for arg in "${db_args[@]}"; do
      add_db "$arg"
    done
  fi


  # -X ignores ~/.psqlrc. Border 1 is the aligned layout this parser expects.
  list_output=$(COLUMNS=4096 "${psql[@]}" \
    -P pager=off -P format=aligned -P border=1 -v ON_ERROR_STOP=1 <<'EOF'
\l
EOF
)

  parsed=0
  while IFS= read -r name; do
    [[ -z $name ]] && continue
    parsed=$((parsed + 1))
    if [[ $name == test_* ]]; then
      add_db "$name"
    fi
  done < <(printf '%s\n' "$list_output" | names_from_list)

  if ((parsed == 0)); then
    printf 'Failed to parse any database names from psql \\l output.\n' >&2
    exit 1
  fi

  if ((${#databases[@]} == 0)); then
    printf 'No databases to drop.\n'
    return 0
  fi

  if ((dry_run)); then
    printf 'Would drop %d database(s):\n' "${#databases[@]}"
  else
    printf 'Dropping %d database(s):\n' "${#databases[@]}"
  fi
  for name in "${databases[@]}"; do
    printf '  %s\n' "$name"
  done

  if ((dry_run)); then
    return 0
  fi

  sql=""
  for name in "${databases[@]}"; do
    ident=$(sql_ident "$name")
    sql+="DROP DATABASE IF EXISTS ${ident} WITH (FORCE);"$'\n'
  done

  "${psql[@]}" -v ON_ERROR_STOP=1 <<EOF
$sql
EOF
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
