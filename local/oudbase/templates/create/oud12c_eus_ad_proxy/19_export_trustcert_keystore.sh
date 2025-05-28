#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 10_export_trustcert_keystore.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.05.28
# Version....: v3.6.0
# Purpose....: Script to export the java keystore to PKCS12
# Notes......: --
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"

# set default values for keystore if not specified
export KEYSTOREFILE=${KEYSTOREFILE:-"${OUD_INSTANCE_HOME}/OUD/config/keystore"} 
export KEYSTOREPIN=${KEYSTOREPIN:-"${OUD_INSTANCE_HOME}/OUD/config/keystore.pin"}
export KEYSTORE_ALIAS=${KEYSTORE_ALIAS:-"server-cert"}
export TRUSTED_CERT_FILE=${TRUSTED_CERT_FILE:-"${OUD_INSTANCE_ADMIN}/etc/oud_trusted_cert.txt"}

# - configure instance ---------------------------------------------------------
echo "Export the trusted certificate from OUD instance ${OUD_INSTANCE} keystore using:"
echo "  KEYSTOREFILE        : ${KEYSTOREFILE}"
echo "  KEYSTOREPIN         : ${KEYSTOREPIN}"
echo "  KEYSTORE_ALIAS      : ${KEYSTORE_ALIAS}"
echo "  TRUSTED_CERT_FILE   : ${TRUSTED_CERT_FILE}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${KEYSTOREFILE}" ]      && echo "- skip $(basename $0), variable KEYSTOREFILE not set"      && exit
[ ! -f "${KEYSTOREFILE}" ]      && echo "- skip $(basename $0), missing file ${KEYSTOREFILE}"       && exit
[   -z "${KEYSTOREPIN}" ]       && echo "- skip $(basename $0), variable KEYSTOREPIN not set"       && exit
[ ! -f "${KEYSTOREPIN}" ]       && echo "- skip $(basename $0), missing file ${KEYSTOREPIN}"        && exit
[   -z "${KEYSTORE_ALIAS}" ]    && echo "- skip $(basename $0), variable KEYSTORE_ALIAS not set"    && exit
[   -z "${TRUSTED_CERT_FILE}" ] && echo "- skip $(basename $0), variable TRUSTED_CERT_FILE not set" && exit
[ ! -f "${TRUSTED_CERT_FILE}" ] && echo "- skip $(basename $0), missing file ${TRUSTED_CERT_FILE}"  && exit

echo "- export trusted certificate"
$JAVA_HOME/bin/keytool -export -noprompt -rfc \
    -alias ${KEYSTORE_ALIAS} \
    -keystore ${KEYSTOREFILE} \
    -storepass $(cat ${KEYSTOREPIN}) \
    -file ${TRUSTED_CERT_FILE}
# - EOF ------------------------------------------------------------------------
