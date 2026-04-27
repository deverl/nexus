#!/usr/bin/env bash

cd ~/develop/vanguard

set -euo pipefail

usage() {
  echo "Usage: $0 [-f|--full]"
  echo ""
  echo "  -f, --full    Run tests in Docker (headless, 2 workers). This is the default"
  echo "  -l, --light   Run reduced (light) tests"
  echo "  -h, --help    Show this help message"
  exit 0
}

FULL=true

PARSED=$(getopt -o flh --long full,light,help -n "$0" -- "$@")
if [[ $? -ne 0 ]]; then
  usage
fi

eval set -- "$PARSED"

while true; do
  case "$1" in
    -f|--full)
      FULL=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    -l|--light)
      FULL=false
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unexpected option: $1"
      usage
      ;;
  esac
done

if [[ "$FULL" == true ]]; then
  docker run \
    --name playwright-headless \
    -v ~/develop/vanguard:/opt/vanguard \
    -it --rm \
    -w /opt/vanguard/e2e/ \
    mcr.microsoft.com/playwright:v1.56.1-noble \
    npx playwright test --config=playwright.all.config.ts -j 2
else
  cd ~/develop/vanguard/e2e
  npm i
  npx playwright install
  sudo npx playwright install-deps
  ENV=rc npx playwright test --headed --config playwright.all.config.ts
fi