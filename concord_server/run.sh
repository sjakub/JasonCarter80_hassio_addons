#!/bin/bash
CONFIG_PATH=/data/options.json
SERIAL=$(jq --raw-output ".serial" $CONFIG_PATH)
DEBUG=$(jq --raw-output ".debug" $CONFIG_PATH)
COMMAND="/usr/bin/concord232_server"
SERIAL_CMD="--serial $SERIAL" 
DEBUG_CMD=""

if $DEBUG ; then
    DEBUG_CMD="--debug"
fi 

{ # try
	echo "STARTING"
    eval ${COMMAND} ${SERIAL_CMD} ${DEBUG_CMD} 

} || { # catch
	echo "$SERIAL does not appear to be valid"
	echo "Here are all your USB devices mapped to this container:"
    ls /dev/ttyUSB*
}

while true; do echo 'Hit CTRL+C'; sleep 1; done
