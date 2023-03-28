#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 18_migrate_keystore.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.28
# Version....: v3.0.0
# Purpose....: Script to migrate the java keystore to PKCS12
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

# - configure instance ---------------------------------------------------------
echo "Migrate java keystore for OUD instance ${OUD_INSTANCE} using:"
echo "  KEYSTOREFILE      : ${KEYSTOREFILE}"
echo "  KEYSTOREPIN       : ${KEYSTOREPIN}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[ -z ${KEYSTOREFILE} ]    && echo "- skip $(basename $0), variable KEYSTOREFILE not set"          && exit
[ -f ${KEYSTOREFILE} ]    && echo "- skip $(basename $0), missing password file ${KEYSTOREFILE}"  && exit
[ -z ${KEYSTOREPIN} ]     && echo "- skip $(basename $0), variable KEYSTOREPIN not set"          && exit
[ -f ${KEYSTOREPIN} ]     && echo "- skip $(basename $0), missing password file ${KEYSTOREPIN}"  && exit

echo "- migrate keystore to PKCS12"
$JAVA_HOME/bin/keytool -importkeystore \
    -srckeystore ${KEYSTOREFILE} \
    -srcstorepass $(cat ${KEYSTOREPIN}) \
    -destkeystore ${KEYSTOREFILE} \
    -deststorepass $(cat ${KEYSTOREPIN}) \
    -deststoretype pkcs12

# - EOF ------------------------------------------------------------------------
