#!/bin/bash


# Get all the interfaces

# ip -o link show | awk -F': ' '{print $2}'

# Set the interface to the second one

# This is for ease of testing
# 1: lo
# 2: enp0s31f6
# 3: wlp0s20f3
# 4: virbr0
# 6: br-4d4298b37011
# 7: br-84e1d9e885e1
# 8: docker0

AUTOMATED_INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | awk 'NR==1')
INTERFACE=${INTERFACE:- ${AUTOMATED_INTERFACE}}
echo "Interface: $INTERFACE"

# Get the interface from the environmental variable or from the automated interface

# Set the path to the Snort binary
SNORT_BIN=${SNORT_BIN:-"/home/snorty/snort3"}


# Go inside the snort alerts directory in order to save the alerts with ease
cd $SNORT_ALERTS
# for logging print the current working directory
echo "Current working directory: $(pwd)"

# Start Snort with the specified configuration and rules


SNORT_CMD="$SNORT_BIN/bin/snort"


if [ "$VERBOSE" -eq 0 ]; then
    SNORT_CMD+=" -q "
fi

if [ -n "$RULES_FILE" ]; then
    SNORT_CMD+=" -R $RULES_FILE "
else
    echo "No rules file specified, using default rules."
fi

# Set the Snort configuration file
if [ -n "$SNORT_CONF_FILE" ]; then
    SNORT_CMD+=" -c $SNORT_CONF_FILE "
else
    echo "No configuration file specified, using default configuration."
    SNORT_CONF_FILE="/home/snorty/custom/custom_snort.lua"
fi


# Set the alert mode

if [ -n "$SNORT_ALERT_MODE" ]; then
    SNORT_CMD+=" -A $SNORT_ALERT_MODE "
else
    echo "No alert mode specified, using default alert mode."
    SNORT_ALERT_MODE="console"
fi

# --daq-dir /usr/local/lib/daq --daq afpacket --daq-var debug
if [ "$SNORT_DAQ_MODE" = "nfq" ] || [ "$SNORT_DAQ_MODE" = "afpacket" ]; then
    SNORT_CMD+=" --daq-dir /usr/local/lib/daq"
    
    
    if [ "$SNORT_DAQ_MODE" = "nfq" ]; then
        SNORT_CMD+=" --daq nfq "
        SNORT_CMD+=" --daq-var queue=0 --daq-var bufsz=65535"
        elif [ "$SNORT_DAQ_MODE" = "afpacket" ]; then
        SNORT_CMD+=" --daq afpacket "
        SNORT_CMD+=" -i $INTERFACE"
    fi
    
    if [ "$SNORT_DAQ_DEBUG" -eq 1 ]; then
        SNORT_CMD+=" --daq-var debug "
    fi
    
    SNORT_CMD+=" -Q"
else
    echo "Snort running in passive mode"
    # Set the interface to listen on
    SNORT_CMD+=" -i $INTERFACE "
fi



echo "Running Snort with command: $SNORT_CMD"
$SNORT_CMD
