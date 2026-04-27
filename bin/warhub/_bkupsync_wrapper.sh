#!/usr/bin/env bash
set -euo pipefail   # ← fail fast on errors/unset vars

echo "========================================"
echo "Starting at: $(date)"
echo "Running as: $(whoami)"
echo "Current dir: $(pwd)"
echo "PATH is: $PATH"
echo "HOME is: $HOME"

# Uncomment and customize if needed
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/bin:$HOME/.local/bin"
export HOME="/Users/dstokes"

echo "Trying to run bkup.sync.sh..."
target="/Users/dstokes/nexus/bin/warhub/bkup.sync.sh"

if [[ ! -x "$target" ]]; then
    echo "ERROR: $target is not executable or missing!"
    ls -la "$(dirname "$target")" || true
    exit 1
fi

"$target" || {
    echo "bkup.sync.sh FAILED with exit code $?"
    exit 1
}

echo "Finished at: $(date)"
echo "========================================"

