#!/bin/bash

# Path to the local.rules file
# It is declared
# RULES_FILE=/home/snorty/custom/local.rules

# Path to the script to run
SNORT_SCRIPT=/home/snorty/scripts/run_snort.sh

# Run once at startup
echo "Initial run of $SNORT_SCRIPT..."
bash "$SNORT_SCRIPT" &

# Monitor the local.rules file for changes
echo "Monitoring $RULES_FILE for changes..."
while inotifywait -e modify "$RULES_FILE"; do
    echo "Change detected in $RULES_FILE. Running $SNORT_SCRIPT..."
    
    # Kill any existing instance of the SNORT_SCRIPT
    pkill -f "$SNORT_SCRIPT"
    
    # Run the SNORT_SCRIPT in the background
    bash "$SNORT_SCRIPT" &
done