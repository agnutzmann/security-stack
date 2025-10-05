#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: update-templates.sh (Version 1.0.0)
# Function: Updates the local Nuclei templates repository.
#           Should be run periodically (e.g., via cron).
# Author: Alexandre Gnutzmann (gnu-it.com)
# -----------------------------------------------------------------------------

set -euo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${BASE_DIR}/nuclei-templates"
echo "[*] Verifying local repository at '$TEMPLATE_DIR'..."
if [[ ! -d "$TEMPLATE_DIR/.git" ]]; then
  echo "❌ Error: Directory is not a git repository. Please clone it first:" >&2
  echo "git clone https://github.com/projectdiscovery/nuclei-templates.git $TEMPLATE_DIR" >&2
  exit 1
fi
cd "$TEMPLATE_DIR"
echo "[*] Ensuring the clone is not shallow..."
git fetch --unshallow || true
echo "[*] Fetching latest remote information..."
git fetch --all --prune --tags --quiet
echo "[*] Switching to the main branch and ensuring it tracks the remote..."
git checkout main
git branch --set-upstream-to=origin/main main
echo "[*] Resetting local repository to match the remote 'main' branch. All local changes will be lost!"
git reset --hard origin/main
git clean -fd
echo "✅ Nuclei templates are now 100% in sync with the official repository."
exit 0