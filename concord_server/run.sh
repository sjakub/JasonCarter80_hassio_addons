#!/bin/bash
set -e

PORT=$(jq --raw-output ".port" $CONFIG_PATH)
/usr/bin/concord232_server --serial $PORT