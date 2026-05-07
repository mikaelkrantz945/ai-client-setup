#!/bin/bash
# build-all-templates.sh — Rebuild all Proxmox cloud-init templates
# Run manually or via cron to keep images updated
#
# Cron example (weekly Sunday 03:00):
#   0 3 * * 0 /opt/ai-client-setup/build-all-templates.sh >> /var/log/ai-templates-build.log 2>&1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_PREFIX="[ai-templates]"
LOCK_FILE="/tmp/ai-templates-build.lock"

# Prevent concurrent runs
if [ -f "$LOCK_FILE" ]; then
    pid=$(cat "$LOCK_FILE" 2>/dev/null)
    if kill -0 "$pid" 2>/dev/null; then
        echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') Already running (PID $pid). Exiting."
        exit 0
    fi
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') Starting template build"

# Pull latest scripts
if [ -d "$SCRIPT_DIR/.git" ]; then
    echo "$LOG_PREFIX Pulling latest from git..."
    cd "$SCRIPT_DIR"
    git pull --quiet origin main 2>/dev/null || true
fi

FAILED=0
BUILT=0

for script in "$SCRIPT_DIR"/cloud-init/*.sh; do
    name=$(basename "$script" .sh)
    echo "$LOG_PREFIX Building: $name"
    if bash "$script"; then
        echo "$LOG_PREFIX $name — OK"
        BUILT=$((BUILT + 1))
    else
        echo "$LOG_PREFIX $name — FAILED"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') Done. Built: $BUILT, Failed: $FAILED"
