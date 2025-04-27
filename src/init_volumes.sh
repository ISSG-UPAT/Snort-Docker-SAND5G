#!/bin/bash


# Folders necessary
mkdir -p volumes/alerts volumes/defaults volumes/examples volumes/logs volumes/rules volumes/scripts volumes/custom;


# Files necessary

# Check if entrypoint file exists

if [ ! -f volumes/scripts/entrypoint.sh ]; then
    echo "Entrypoint file not found. Creating entrypoint file...";
    touch volumes/scripts/entrypoint.sh;
    chmod +x volumes/scripts/entrypoint.sh;
else
    echo "Entrypoint file found.";
    chmod +x volumes/scripts/entrypoint.sh;
fi


# Check if alert.log exists in volumes/alerts

if [ ! -f volumes/alerts/alert.log ]; then
    echo "Alert log file not found. Creating alert log file...";
    touch volumes/alerts/alert.log;
else
    echo "Alert log file found.";
fi


# Prerequisites to have the entrypoint.sh
# touch volumes/scripts/entrypoint.sh ;
# chmod +x volumes/scripts/entrypoint.sh ;