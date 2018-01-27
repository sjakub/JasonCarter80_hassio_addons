#!/bin/bash
CONFIG_PATH=/data/options.json

CERTFILE=$(jq --raw-output ".certfile" $CONFIG_PATH)
KEYFILE=$(jq --raw-output ".keyfile" $CONFIG_PATH)



### Update the Certs incase they've changed
### Ref:  https://gist.github.com/bsodmike/bc56730fcc71e69bf10875898a92de02
TEMPFILE=$(mktemp)
CERTTEMPFILE=$(mktemp)

	# Identrust cross-signed CA cert needed by the java keystore for import.
	# Can get original here: https://www.identrust.com/certificates/trustid/root-download-x3.html
	cat > ${CERTTEMPFILE} <<'_EOF'
-----BEGIN CERTIFICATE-----
MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
-----END CERTIFICATE-----
_EOF

echo "Using openssl to prepare certificate..."
openssl pkcs12 -export  -passout pass:aircontrolenterprise \
	-in //ssl/${CERTFILE} \
	-inkey /ssl/${KEYFILE} \
	-out ${TEMPFILE} -name unifi \
	-CAfile /ssl/${CERTFILE} -caname root

echo "Removing existing certificate from Unifi protected keystore..."
keytool -delete -alias unifi -keystore /data/keystore \
	-deststorepass aircontrolenterprise
echo "Inserting certificate into Unifi keystore..."
keytool -trustcacerts -importkeystore \
	-deststorepass aircontrolenterprise \
	-destkeypass aircontrolenterprise \
	-destkeystore /data/keystore \
	-srckeystore ${TEMPFILE} -srcstoretype PKCS12 \
	-srcstorepass aircontrolenterprise \
	-alias unifi
rm -f ${TEMPFILE}
echo "Importing cert into Unifi database..."
java -jar /usr/lib/unifi/lib/ace.jar import_cert \
	/ssl/${CERTFILE} \
	${CERTTEMPFILE}
    
 rm -f ${CERTTEMPFILE}


### This is a simple watcher that checks that the Java process
### is running, if not, it will kill this script which is 
### streaming the server log to HASSIO console  
./watch $$ &


### Start the Java Process in the Background
/usr/bin/java -Xmx256M -jar /usr/lib/unifi/lib/ace.jar  start &


### Output the Logs to the Console
tail -f /data/logs/server.log
