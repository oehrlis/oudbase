#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 18_migrate_keystore.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.10.24
# Version....: v2.8.0
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

echo "- migrate keystore to PKCS12"
$JAVA_HOME/bin/keytool -importkeystore \
    -srckeystore ${KEYSTOREFILE} \
    -srcstorepass $(cat ${KEYSTOREPIN}) \
    -destkeystore ${KEYSTOREFILE} \
    -deststorepass $(cat ${KEYSTOREPIN}) \
    -deststoretype pkcs12

# - EOF ------------------------------------------------------------------------
