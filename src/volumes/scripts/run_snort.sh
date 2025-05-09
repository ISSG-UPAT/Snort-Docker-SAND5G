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



# Go inside the snort alerts directory in order to save the alerts with ease
cd $SNORT_ALERTS
# for logging print the current working directory
echo "Current working directory: $(pwd)"

# Start Snort with the specified configuration and rules

# Explaining the paramters
# -q : quiet operatoin, don'w displa
# -c config-file

/home/snorty/snort3/bin/snort -q -c $SNORT_CONF_FILE -i $INTERFACE -A alert_json
