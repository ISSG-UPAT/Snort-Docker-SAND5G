#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ── IDS_* contract (backward-compatible fallbacks for old var names) ──────────
IDS_MODE="${IDS_MODE:-}"
IDS_QUEUE="${IDS_QUEUE:-${QUEUE:-0}}"
# Rules file: explicit override > selected IDS mode > old RULES_FILE fallback.
# Base images set RULES_FILE=local.rules, which must not override IDS_MODE from Compose.
if [ -n "${IDS_RULES_FILE:-}" ]; then
    : # already set
elif [ -n "$IDS_MODE" ] && [ "$IDS_MODE" != "custom" ]; then
    IDS_RULES_FILE="/home/snorty/custom/${IDS_MODE}.rules"
elif [ -n "${RULES_FILE:-}" ]; then
    IDS_RULES_FILE="$RULES_FILE"
else
    IDS_RULES_FILE=""
fi
IDS_CONF_FILE="${IDS_CONF_FILE:-${SNORT_CONF_FILE:-/home/snorty/custom/custom_snort.lua}}"
IDS_VERBOSE="${IDS_VERBOSE:-${VERBOSE:-0}}"
IDS_DAQ_MODE="${IDS_DAQ_MODE:-${SNORT_DAQ_MODE:-nfq}}"
IDS_ALERT_MODE="${IDS_ALERT_MODE:-${SNORT_ALERT_MODE:-alert_json}}"
IDS_DAQ_DEBUG="${IDS_DAQ_DEBUG:-${SNORT_DAQ_DEBUG:-0}}"

SNORT_BIN="${SNORT_BIN:-/home/snorty/snort3}"

cd "${SNORT_ALERTS:-/home/snorty/alerts}"
echo "[INFO] Working directory: $(pwd)"
echo "[INFO] IDS_MODE=$IDS_MODE  rules=$IDS_RULES_FILE  daq=$IDS_DAQ_MODE  queue=$IDS_QUEUE"

SNORT_CMD="${SNORT_BIN}/bin/snort"

[ "$IDS_VERBOSE" -eq 0 ] && SNORT_CMD="$SNORT_CMD -q"

[ -n "$IDS_RULES_FILE" ] && SNORT_CMD="$SNORT_CMD -R $IDS_RULES_FILE"
[ -n "$IDS_CONF_FILE"  ] && SNORT_CMD="$SNORT_CMD -c $IDS_CONF_FILE"
[ -n "$IDS_ALERT_MODE" ] && SNORT_CMD="$SNORT_CMD -A $IDS_ALERT_MODE"

case "$IDS_DAQ_MODE" in
nfq)
    SNORT_CMD="$SNORT_CMD --daq-dir /usr/local/lib/daq --daq nfq"
    SNORT_CMD="$SNORT_CMD --daq-var queue=$IDS_QUEUE --daq-var bufsz=65535"
    [ "$IDS_DAQ_DEBUG" -eq 1 ] && SNORT_CMD="$SNORT_CMD --daq-var debug"
    SNORT_CMD="$SNORT_CMD -Q"
    ;;
afpacket)
    INTERFACE="${INTERFACE:-$(ip -o link show | awk -F': ' 'NR==1{print $2}')}"
    SNORT_CMD="$SNORT_CMD --daq-dir /usr/local/lib/daq --daq afpacket -i $INTERFACE -Q"
    ;;
*)
    INTERFACE="${INTERFACE:-$(ip -o link show | awk -F': ' 'NR==1{print $2}')}"
    echo "[INFO] Passive mode on interface $INTERFACE"
    SNORT_CMD="$SNORT_CMD -i $INTERFACE"
    ;;
esac

echo "[INFO] Running: $SNORT_CMD"
$SNORT_CMD
