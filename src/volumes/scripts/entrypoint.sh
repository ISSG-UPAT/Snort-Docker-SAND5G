#!/bin/sh
#
# Snort container entrypoint.
#
# Reads IDS_MODE to determine which NFQ iptables rules to insert, then
# delegates to run_snort_notify.sh. Cleans up iptables on exit.
#
# IDS_MODE values:
#   n2     — NGAP/SCTP port 38412  (AMF ↔ gNB)
#   n3     — GTP-U/UDP port 2152   (gNB ↔ UPF) + ogstun FORWARD chain
#   n4     — PFCP/UDP  port 8805   (SMF ↔ UPF)
#   sbi    — HTTP-2/TCP port 7777  (Open5GS inter-NF SBI)
#   n6     — all user-plane traffic on ogstun FORWARD (UPF ↔ Data Network)
#   custom — arbitrary rule strings via RULE_IN / RULE_OUT
#   (empty)— same as custom
#
# Custom mode variables:
#   RULE_IN   — full iptables rule args for inbound  (e.g. "-i ens3 -p tcp --dport 9999 -j NFQUEUE --queue-num 0 --queue-bypass")
#   RULE_OUT  — full iptables rule args for outbound (optional)
#   CHAIN_IN  — iptables chain for RULE_IN  (default: INPUT)
#   CHAIN_OUT — iptables chain for RULE_OUT (default: OUTPUT)

set -eu

log()  { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*"; }

# ── Configuration ─────────────────────────────────────────────────────────────
IDS_MODE="${IDS_MODE:-}"
IDS_QUEUE="${IDS_QUEUE:-0}"

N2_IF="${N2_IF:-lo}"
N2_PORT="${N2_PORT:-38412}"
N3_IF="${N3_IF:-ens3}"
N3_PORT="${N3_PORT:-2152}"
TUN_IF="${TUN_IF:-ogstun}"
N4_IF="${N4_IF:-lo}"
N4_PORT="${N4_PORT:-8805}"
SBI_IF="${SBI_IF:-lo}"
SBI_PORT="${SBI_PORT:-7777}"
N6_IF="${N6_IF:-ogstun}"

# ── iptables helpers ──────────────────────────────────────────────────────────

del_rule_all() {
    table="$1"; shift; chain="$1"; shift; rule="$*"
    while sudo iptables -t "$table" -C "$chain" $rule 2>/dev/null; do
        sudo iptables -t "$table" -D "$chain" $rule 2>/dev/null || true
    done
}

add_rule_once() {
    table="$1"; shift; chain="$1"; shift; rule="$*"
    log "Adding rule: table=$table chain=$chain $rule"
    if sudo iptables -t "$table" -C "$chain" $rule 2>/dev/null; then
        log "Rule already present"
    else
        sudo iptables -t "$table" -I "$chain" 1 $rule
    fi
}

# For loopback use INPUT/OUTPUT; physical/bridge interfaces use FORWARD.
_iface_chains() {
    if [ "$1" = "lo" ]; then
        CHAIN_IN="INPUT"; CHAIN_OUT="OUTPUT"
    else
        CHAIN_IN="FORWARD"; CHAIN_OUT="FORWARD"
    fi
}

# ── Interface-specific iptables setup ────────────────────────────────────────

setup_rules() {
    log "IDS_MODE=$IDS_MODE — inserting NFQ rules (queue=$IDS_QUEUE)..."
    modprobe xt_sctp 2>/dev/null || log "xt_sctp not loaded; falling back to ip_proto:132"

    case "$IDS_MODE" in
    n2)
        _iface_chains "$N2_IF"
        if iptables -p sctp --help 2>&1 | grep -q 'destination port'; then
            add_rule_once filter "$CHAIN_IN"  "-i $N2_IF -p sctp --dport $N2_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
            add_rule_once filter "$CHAIN_OUT" "-o $N2_IF -p sctp --sport $N2_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        else
            add_rule_once filter "$CHAIN_IN"  "-i $N2_IF -p 132 -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
            add_rule_once filter "$CHAIN_OUT" "-o $N2_IF -p 132 -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        fi
        ;;
    n3)
        # ogstun FORWARD chain (inner IP after GTP-U decapsulation)
        add_rule_once filter FORWARD "-j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        # Outer GTP-U packets (no interface restriction — ClusterIP DNAT may route via any interface)
        add_rule_once filter INPUT  "-p udp --dport $N3_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        add_rule_once filter OUTPUT "-p udp --sport $N3_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        ;;
    n4)
        _iface_chains "$N4_IF"
        add_rule_once filter "$CHAIN_IN"  "-i $N4_IF -p udp --dport $N4_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        add_rule_once filter "$CHAIN_OUT" "-o $N4_IF -p udp --sport $N4_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        ;;
    sbi)
        _iface_chains "$SBI_IF"
        add_rule_once filter "$CHAIN_IN"  "-i $SBI_IF -p tcp --dport $SBI_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        add_rule_once filter "$CHAIN_OUT" "-o $SBI_IF -p tcp --sport $SBI_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        ;;
    n6)
        # N6: UPF ↔ Data Network — decapsulated user-plane traffic on ogstun
        add_rule_once filter FORWARD "-i $N6_IF -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        add_rule_once filter FORWARD "-o $N6_IF -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        ;;
    ""|custom)
        # Custom rule strings — set RULE_IN / RULE_OUT to arbitrary iptables args.
        # CHAIN_IN / CHAIN_OUT default to INPUT / OUTPUT.
        CHAIN_IN="${CHAIN_IN:-INPUT}"
        CHAIN_OUT="${CHAIN_OUT:-OUTPUT}"
        if [ -n "${RULE_IN:-}" ]; then
            add_rule_once filter "$CHAIN_IN" $RULE_IN
        fi
        if [ -n "${RULE_OUT:-}" ]; then
            add_rule_once filter "$CHAIN_OUT" $RULE_OUT
        fi
        if [ -z "${RULE_IN:-}" ] && [ -z "${RULE_OUT:-}" ]; then
            warn "IDS_MODE is empty/custom but RULE_IN and RULE_OUT are both unset — no iptables rules inserted"
        fi
        ;;
    *)
        warn "Unknown IDS_MODE='$IDS_MODE' — no iptables rules inserted"
        ;;
    esac
}

cleanup_rules() {
    log "Removing NFQ rules (mode=${IDS_MODE:-custom}, queue=$IDS_QUEUE)..."
    case "$IDS_MODE" in
    n2)
        _iface_chains "$N2_IF"
        if iptables -p sctp --help 2>&1 | grep -q 'destination port'; then
            del_rule_all filter "$CHAIN_IN"  "-i $N2_IF -p sctp --dport $N2_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
            del_rule_all filter "$CHAIN_OUT" "-o $N2_IF -p sctp --sport $N2_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        else
            del_rule_all filter "$CHAIN_IN"  "-i $N2_IF -p 132 -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
            del_rule_all filter "$CHAIN_OUT" "-o $N2_IF -p 132 -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        fi
        ;;
    n3)
        del_rule_all filter FORWARD "-j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        del_rule_all filter INPUT  "-p udp --dport $N3_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        del_rule_all filter OUTPUT "-p udp --sport $N3_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        ;;
    n4)
        _iface_chains "$N4_IF"
        del_rule_all filter "$CHAIN_IN"  "-i $N4_IF -p udp --dport $N4_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        del_rule_all filter "$CHAIN_OUT" "-o $N4_IF -p udp --sport $N4_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        ;;
    sbi)
        _iface_chains "$SBI_IF"
        del_rule_all filter "$CHAIN_IN"  "-i $SBI_IF -p tcp --dport $SBI_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        del_rule_all filter "$CHAIN_OUT" "-o $SBI_IF -p tcp --sport $SBI_PORT -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        ;;
    n6)
        del_rule_all filter FORWARD "-i $N6_IF -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        del_rule_all filter FORWARD "-o $N6_IF -j NFQUEUE --queue-num $IDS_QUEUE --queue-bypass"
        ;;
    ""|custom)
        CHAIN_IN="${CHAIN_IN:-INPUT}"
        CHAIN_OUT="${CHAIN_OUT:-OUTPUT}"
        [ -n "${RULE_IN:-}"  ] && del_rule_all filter "$CHAIN_IN"  $RULE_IN
        [ -n "${RULE_OUT:-}" ] && del_rule_all filter "$CHAIN_OUT" $RULE_OUT
        ;;
    esac
    log "Cleanup done."
}

# ── Signal handling ───────────────────────────────────────────────────────────

on_term() {
    warn "Got SIGTERM/INT/HUP → cleanup + stop child"
    cleanup_rules
    if [ -n "${CHILD_PID:-}" ]; then
        kill -TERM "$CHILD_PID" 2>/dev/null || true
        wait "$CHILD_PID" 2>/dev/null || true
    fi
    exit 0
}

trap on_term TERM INT HUP
trap cleanup_rules EXIT

# ── Startup ───────────────────────────────────────────────────────────────────

log "Snort container starting (IDS_MODE=${IDS_MODE:-custom}, queue=$IDS_QUEUE)..."
sleep 1
setup_rules

if [ ! -x /home/snorty/scripts/run_snort_notify.sh ]; then
    warn "Script /home/snorty/scripts/run_snort_notify.sh not found or not executable!"
fi

log "Executing run_snort_notify script..."
/home/snorty/scripts/run_snort_notify.sh &
CHILD_PID="$!"
wait "$CHILD_PID"
