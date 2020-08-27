#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 40_status_replication.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.09.04
# Usage......: 40_status_replication.sh
# Purpose....: simple script to display replication status
# Notes......:  
# Reference..: 
# License...: Licensed under the Universal Permissive License v 1.0 as 
#             shown at http://oss.oracle.com/licenses/upl.
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------
# - load instance environment -----------------------------------------------
. "$(dirname $0)/00_init_environment"

# - configure instance ------------------------------------------------------
echo "Enable replication ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "HOST1             : ${HOST1}"
echo "HOST2             : ${HOST2}"
echo "HOST3             : ${HOST3}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "PORT_REP          : ${PORT_REP}"
echo "DIRMAN            : ${DIRMAN}"
echo "REPMAN            : ${REPMAN}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "BASEDN            : ${BASEDN}"

# - check status of replication ---------------------------------------------
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h "${HOST1}" -p "${PORT_ADMIN}" \
--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile
# - EOF ---------------------------------------------------------------------