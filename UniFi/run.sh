#!/bin/bash
CONFIG_PATH=/data/options.json

CERTFILE=$(jq --raw-output ".certfile" $CONFIG_PATH)
KEYFILE=$(jq --raw-output ".keyfile" $CONFIG_PATH)


TEMPFILE=$(mktemp)
CERTTEMPFILE=$(mktemp)
CERTDIR="/data"


log() {
    echo "$(date +"[%Y-%m-%d %T,%3N]") <docker-entrypoint> $*" 
}

# SSL certificate setup
# Ref:  https://github.com/goofball222/unifi/blob/master/stable/root/usr/local/bin/docker-entrypoint.sh
if [ -e /ssl/${KEYFILE} ] && [ -e ${CERTDIR}/fullchain.pem ]; then
    if `/usr/bin/sha256sum -c ${CERTDIR}/unificert.sha256 &> /dev/null`; then
        log "INFO - SSL: certificate files unchanged, continuing with UniFi startup"
        log "INFO - SSL: To force rerun import process: delete '${CERTDIR}/unificert.sha256' and restart the container"
    else
        if [ ! -e ${DATADIR}/keystore ]; then
            log "WARN - SSL: keystore does not exist, generating it with Java keytool"
            keytool -genkey -keyalg RSA -alias unifi -keystore ${DATADIR}/keystore \
            -storepass aircontrolenterprise -keypass aircontrolenterprise -validity 1825 \
            -keysize 4096 -dname "cn=UniFi"
        else
            log "INFO - SSL: backup existing '${DATADIR}/keystore' to '${DATADIR}/keystore-$(date +%s)'"
            cp ${DATADIR}/keystore ${DATADIR}/keystore-$(date +%s)
        fi
        log "INFO - SSL: custom certificate keystore update"
        log "INFO - SSL: openssl combine custom private key and certificate chain into temporary PKCS12 file"
        openssl pkcs12 -export \
            -inkey /ssl/${KEYFILE} \
            -in /ssl/{$CERTFILE} \
            -out ${TEMPFILE} \
            -name ubnt -password pass:temppass

        log "INFO - SSL: Java keytool import PKCS12 '${TEMPFILE}' file into '${DATADIR}/keystore'"
        keytool -importkeystore -deststorepass aircontrolenterprise \
         -destkeypass aircontrolenterprise -destkeystore ${DATADIR}/keystore \
         -srckeystore ${TEMPFILE} -srcstoretype PKCS12 \
         -srcstorepass temppass -alias ubnt -noprompt

        log "INFO - SSL: Removing temporary PKCS12 file"
        rm ${TEMPFILE}

        log "INFO - SSL: Store SHA256 hash of private key and certificate file"
        /usr/bin/sha256sum /ssl/${KEYFILE} > ${CERTDIR}/unificert.sha256
        /usr/bin/sha256sum /ssl/${CERTFILE} >> ${CERTDIR}/unificert.sha256

        log "INFO - SSL: completed update of custom certificate in '${DATADIR}/keystore'"
        log "INFO - SSL: Check above ***here*** for errors if your custom certificate import isn't working"
        log "INFO - SSL: To force rerun import process: delete '${CERTDIR}/unificert.sha256' and restart the container"
    fi
else
    [ -f /ssl/${KEYFILE} ] || log "WARN - SSL: missing '/ssl/${KEYFILE}', cannot update certificate in '${DATADIR}/keystore'"
    [ -f /ssl/${CERTFILE} ] || log "WARN - SSL: missing '/ssl/${CERTFILE}', cannot update certificate in '${DATADIR}/keystore'"
    log "WARN - SSL: certificate import was NOT performed"
fi
# End SSL certificate setup    

### This is a simple watcher that checks that the Java process
### is running, if not, it will kill this script which is 
### streaming the server log to HASSIO console  
/run/watch $$ &


### Start the Java Process in the Background
/usr/bin/java -Xmx256M -jar /usr/lib/unifi/lib/ace.jar  start &


### Output the Logs to the Console
tail -f /data/logs/server.log
