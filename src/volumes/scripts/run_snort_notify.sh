#!/bin/bash

SNORT_SCRIPT=/home/snorty/scripts/run_snort.sh

# Resolve the active rules file: explicit override > selected IDS mode > legacy fallback.
# Base images set RULES_FILE=local.rules, which must not override IDS_MODE from Compose.
if [ -n "${IDS_RULES_FILE:-}" ]; then
    _rules_file="$IDS_RULES_FILE"
elif [ -n "${IDS_MODE:-}" ] && [ "${IDS_MODE:-}" != "custom" ]; then
    _rules_file="/home/snorty/custom/${IDS_MODE}.rules"
elif [ -n "${RULES_FILE:-}" ]; then
    _rules_file="$RULES_FILE"
else
    echo "[WARN] IDS_RULES_FILE not set and IDS_MODE is empty/custom — hot-reload disabled"
    exec bash "$SNORT_SCRIPT"
fi
RULES_DIR="$(dirname -- "$_rules_file")"
RULES_BASE="$(basename -- "$_rules_file")"


start_snort_script() {
    echo "[INFO] Starting $SNORT_SCRIPT..."
    bash "$SNORT_SCRIPT" &
}

stop_snort_script() {
    PGID=$(pgrep -f "bash $SNORT_SCRIPT" | head -n 1)
    if kill -0 "$PGID" 2>/dev/null; then
        echo "[INFO] Stopping $SNORT_SCRIPT and children (PGID $PGID)..."
        pkill -TERM -P "$PGID"
        while kill -0 "$PGID" 2>/dev/null; do sleep 0.1; done
    fi
}

restart_snort_script() { stop_snort_script; start_snort_script; }

start_snort_script

echo "[INFO] Monitoring $RULES_DIR for changes to $RULES_BASE..."
inotifywait -m -e close_write --format "%e %f" --include "(^|/)${RULES_BASE}$" -r "$RULES_DIR" | \
while read action file; do
    echo "[INFO] $file $action — restarting snort"
    restart_snort_script
done
