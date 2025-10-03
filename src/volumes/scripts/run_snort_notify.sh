#!/bin/bash

# Path to the local.rules file
# It is declared
# RULES_FILE=/home/snorty/custom/local.rules

# Path to the script to run
SNORT_SCRIPT=/home/snorty/scripts/run_snort.sh
RULES_DIR="$(dirname -- "$RULES_FILE")"
RULES_BASE="$(basename -- "$RULES_FILE")"


# Functions to start/stop the SNORT_SCRIPT and all its children
start_snort_script() {
    echo "Starting $SNORT_SCRIPT..."
    bash "$SNORT_SCRIPT" &
}



stop_snort_script() {
    PGID=$(pgrep -f "bash $SNORT_SCRIPT" | head -n 1)
    if kill -0 "$PGID" 2>/dev/null; then
        echo "Stopping $SNORT_SCRIPT and all child processes (PGID $PGID)..."
        pkill -TERM -P "$PGID"
        # Wait for the process group to exit
        while kill -0 "$PGID" 2>/dev/null; do
            sleep 0.1
        done
    fi
}

restart_snort_script() {
    stop_snort_script
    start_snort_script
}

# Initial start
start_snort_script



# Monitor the custom directory for changes to custom_alert_drop_block.rules
echo "Monitoring custom directory for changes to $RULES_BASE..."
inotifywait -m -e close_write --format "%e %f" --include "(^|/)${RULES_BASE}$" -r $RULES_DIR | \
while read action file; do
    echo "$file  $action"
    restart_snort_script
done


