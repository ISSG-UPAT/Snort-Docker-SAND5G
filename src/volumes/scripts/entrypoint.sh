#!/bin/sh
#
# This script serves as the entrypoint for the Snort container.
#
# Functionality:
# - Logs the startup of the Snort container.
# - Optionally waits for Docker to mount volumes (adjustable or removable).
# - Checks for the existence and executability of a custom script located at
#   /home/snorty/scripts/run_snort.sh.
# - Executes the custom script if found and executable.
# - Logs a warning if the custom script is not found or is not executable.
# - Optionally keeps the container running or starts a real process (commented out by default).
#
# Usage:
# - Place this script in the container's designated entrypoint path.
# - Ensure the custom script (/home/snorty/scripts/run_snort.sh) exists and has executable permissions.
#
# Notes:
# - Modify the sleep duration or remove the sleep command if volume mounting delay is not an issue.
# - Uncomment and replace the `exec` command at the end to start a real process if needed.

# Exit immediately if a command exits with a non-zero status
set -e


# --- Startup ---
echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') Snort container starting..."


# Optional: wait for Docker to mount volumes (adjust the sleep duration or remove if unnecessary)
sleep 1

# Check if the custom script /home/snorty/scripts/run_snort.sh exists and is executable
if [ -x /home/snorty/scripts/entrypoint.sh ]; then
    # Log that the custom entrypoint script is being executed
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') Executing custom entrypoint script"
    # Execute the custom script
    /home/snorty/scripts/run_snort_notify.sh
else
    # Log a warning if the custom script is not found or not executable
    echo "[WARN] Script /home/snorty/scripts/run_snort.sh not found or not executable!"
fi

# Optional: keep the container running or start your real process here
# Uncomment the following line to keep the container running indefinitely
# exec tail -f /dev/null
