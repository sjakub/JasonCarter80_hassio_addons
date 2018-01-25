#!/bin/bash
set -e
CONFIG_PATH=/data/options.json

SERIAL=$(jq --raw-output ".serial" $CONFIG_PATH)
DEBUG=$(jq --raw-output ".debug" $CONFIG_PATH)

echo "Using $SERIAL"
echo "DEBUG: $DEBUG"


{ # try
	echo "Trying SERIAL PORT: $SERIAL"
    /usr/bin/concord232_server --serial $SERIAL --debug:$DEBUG 

} || { # catch
	echo "$SERIAL does not appear to be valid"
	echo "Here are all your USB devices mapped to this container:"
    ls /dev/ttyUSB*
}
