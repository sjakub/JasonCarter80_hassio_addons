#!/bin/bash
set -e
CONFIG_PATH=/data/options.json

SERIAL=$(jq --raw-output ".serial" $CONFIG_PATH)
DEBUG=$(jq --raw-output ".debug" $CONFIG_PATH)




echo "SERIAL: $SERIAL"
echo "DEBUG: $DEBUG"


COMMAND = "/usr/bin/concord232_server"
SERIAL_CMD = "--serial $SERIAL" 
DEBUG_CMD = ""

if $DEBUG ; then
    DEBUG_CMD = "--debug"
fi 




{ # try
	echo "STARTING"
    eval ${COMMAND} ${SERIAL_CMD} ${DEBUG_CMD} 

} || { # catch
	echo "$SERIAL does not appear to be valid"
	echo "Here are all your USB devices mapped to this container:"
    ls /dev/ttyUSB*
}
