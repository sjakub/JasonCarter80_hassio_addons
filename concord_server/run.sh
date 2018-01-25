#!/bin/bash
set -e
CONFIG_PATH=/data/options.json

PORT=$(jq --raw-output ".port" $CONFIG_PATH)
DEBUG=$(jq --raw-output ".debug" $CONFIG_PATH)

echo "Using $PORT"
echo "DEBUG: $DEBUG"

/usr/bin/concord232_server --serial $PORT