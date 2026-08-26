#!/usr/bin/env bash

set -euo pipefail

WARHUB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd ~/develop/infrastructure

python3 "$WARHUB_DIR/test_build_and_deploy.py" "$@"
