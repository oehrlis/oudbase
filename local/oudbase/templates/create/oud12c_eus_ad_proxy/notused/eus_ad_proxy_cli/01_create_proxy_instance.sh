#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 01_create_instance.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: Script to create the OUD proxy instance using oud-proxy-setup.
# Notes......: Will skip oud-proxy-setup if config.ldif already exists
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment"

# - create instance -----------------------------------------------------
echo "Create OUD instance ${OUD_INSTANCE} using:"
echo "OUD_INSTANCE_HOME : ${OUD_INSTANCE_HOME}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "HOSTNAME          : ${HOST}"
echo "PORT              : ${PORT}"
echo "PORT_SSL          : ${PORT_SSL}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "BASEDN            : ${BASEDN}"

# check if OUD instance config does not yet exists
if [ ! -f "${OUD_INSTANCE_HOME}/OUD/config/config.ldif" ]; then
    echo "INFO: Create OUD proxy instance ${OUD_INSTANCE}"
    ${ORACLE_HOME}/oud/oud-proxy-setup \
        --cli \
        --instancePath "${OUD_INSTANCE_HOME}/OUD" \
        --rootUserDN "${DIRMAN}" \
        --rootUserPasswordFile "${PWD_FILE}" \
        --hostname ${HOST} \
        --ldapPort ${PORT} \
        --ldapsPort ${PORT_SSL} \
        --adminConnectorPort ${PORT_ADMIN} \
        --enableStartTLS \
        --generateSelfSignedCertificate \
        --no-prompt \
        --noPropertiesFile
else
    echo "WARN: did found an instance configuration file"
    echo "      ${OUD_INSTANCE_HOME}/OUD/config/config.ldif"
    echo "      skip create instance ${OUD_INSTANCE}"
fi

# - EOF -----------------------------------------------------------------
