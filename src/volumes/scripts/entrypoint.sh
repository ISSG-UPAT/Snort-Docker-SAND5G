#!/bin/sh
#
# This script serves as the entrypoint for the Snort container.
#
# Functionality:
# - Logs the startup of the Snort container.
# - Inserts NFQUEUE iptables rules on start.
# - Removes them on exit.
# - Executes /home/snorty/scripts/run_snort_notify.sh if present.
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
set -eu

# Log the startup of the Snort container
echo "[INFO] Snort container starting..."

# --- Configuration ---
QUEUE="${QUEUE:-0}"
IN_IF="${IN_IF:-ogstun}"
OUT_IF="${OUT_IF:-ens3}"
TABLE_IN="${TABLE_IN:-FORWARD}"
TABLE_OUT="${TABLE_OUT:-FORWARD}"

# RULE_IN="-i $IN_IF -j NFQUEUE --queue-num $QUEUE --queue-bypass"
# RULE_OUT="-o $OUT_IF -j NFQUEUE --queue-num $QUEUE --queue-bypass"

RULE_IN="-i $IN_IF -o $OUT_IF -j NFQUEUE --queue-num $QUEUE --queue-bypass"
RULE_OUT="-i $OUT_IF -o $IN_IF -j NFQUEUE --queue-num $QUEUE --queue-bypass"


log() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*"; }


# Remove ALL matching instances of a rule (handles duplicates / restart cases)
del_rule_all() {
    table="$1"; shift
    chain="$1"; shift
    rule="$*"
    
    # keep deleting as long as the rule exists
    while sudo iptables -t "$table" -C "$chain" $rule 2>/dev/null; do
        sudo iptables -t "$table" -D "$chain" $rule 2>/dev/null || true
    done
}

add_rule_once() {
    table="$1"; shift
    chain="$1"; shift
    rule="$*"
    echo "Adding rule to iptables table='$table' chain='$chain': $rule"
    if sudo iptables -t "$table" -C "$chain" $rule 2>/dev/null; then
        log "Rule already present: $chain $rule"
    else
        # log "sudo iptables -t \"$table\" -I \"$chain\" 1 $rule"
        sudo iptables -t "$table" -I "$chain" 1 $rule
        log "Inserted rule: $chain $rule"
    fi
}


cleanup() {
    log "Removing NFQUEUE rules (queue=$QUEUE, iface=$IN_IF)..."
    # IMPORTANT: -C/-D need the exact same rule spec as inserted.
    del_rule_all filter "$TABLE_IN"  $RULE_IN
    del_rule_all filter "$TABLE_OUT" $RULE_OUT
    log "Cleanup done."
}


# Handle stop signals from docker/compose
on_term() {
    warn "Got SIGTERM/INT/HUP -> cleanup + stop child"
    cleanup
    if [ -n "${CHILD_PID:-}" ]; then
        kill -TERM "$CHILD_PID" 2>/dev/null || true
        wait "$CHILD_PID" 2>/dev/null || true
    fi
    exit 0
}


trap on_term TERM INT HUP
trap cleanup EXIT

# --- Startup ---
log "Snort container starting..."


# --- Main process ---

# Optional: wait for Docker to mount volumes (adjust the sleep duration or remove if unnecessary)
sleep 1

# # Ingress to Open5GS via ogstun
# sudo iptables -I $TABLE_IN  -i $IN_IF -j NFQUEUE --queue-num $QUEUE --queue-bypass

# # Egress from Open5GS via ogstun
# sudo iptables -I $TABLE_OUT -o $IN_IF -j NFQUEUE --queue-num $QUEUE --queue-bypass

# sudo iptables -I FORWARD -i "$IN_IF" -o "$OUT_IF" -j NFQUEUE --queue-num $QUEUE
# sudo iptables -I FORWARD -i "$OUT_IF"   -o "$IN_IF" -j NFQUEUE --queue-num $QUEUE

add_rule_once filter "$TABLE_IN"  $RULE_IN
add_rule_once filter "$TABLE_OUT" $RULE_OUT

# Check if the custom script /home/snorty/scripts/run_snort.sh exists and is executable
if [ ! -x /home/snorty/scripts/run_snort_notify.sh ]; then
    # Log a warning if the custom script is not found or not executable
    warn "Script /home/snorty/scripts/run_snort_notify.sh not found or not executable!"
fi

# Log that the custom script is being executed
log "Executing custom run_snort_notify script"
# Execute the custom script
/home/snorty/scripts/run_snort_notify.sh &
CHILD_PID="$!"

wait "$CHILD_PID"


# Optional: keep the container running or start your real process here
# Uncomment the following line to keep the container running indefinitely
# exec tail -f /dev/null
