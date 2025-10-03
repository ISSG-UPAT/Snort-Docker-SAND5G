#!/bin/bash

# Path to the local.rules file
RULES_FILE="/home/snorty/custom/local.rules"

# Path to the script to run
SNORT_SCRIPT="/home/snorty/scripts/run_snort.sh"

# Run once at startup
echo "Initial run of $SNORT_SCRIPT..."
bash "$SNORT_SCRIPT" &

# Monitor the local.rules file for close_write (file save) events
echo "Monitoring $RULES_FILE for changes..."
inotifywait -m -e close_write --quiet "$RULES_FILE" | while read -r path action file; do
    echo "Change detected in $RULES_FILE. Running $SNORT_SCRIPT..."
    
    # Kill any existing instance of the SNORT_SCRIPT
    pkill -f "$SNORT_SCRIPT"
    
    # Run the SNORT_SCRIPT in the background
    bash "$SNORT_SCRIPT" &
done
