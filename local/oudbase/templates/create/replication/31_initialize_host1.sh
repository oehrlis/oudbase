#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 31_initialize_host1.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.08.17
# Version....: v2.1.1
# Usage......: 31_initialize_host1.sh
# Purpose....: simple script to initialize replication
# Notes......:  
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------
# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"

# limit Script to run on HOST2
RUN_ON_HOST="HOST2"         # define the HOST Variable from the 00_init_environment file
# check if HOST variable is defined
if [ -n "${!RUN_ON_HOST}" ]; then
    # check if current host does match RUN_ON_HOST
    if [ "${HOST}" != "${!RUN_ON_HOST}" ]; then 
        echo "skip for host ${HOST}, does only run on host ${!RUN_ON_HOST}"
        exit
    else
        echo "ok to run script on host ${HOST}"
    fi
else
    echo "Host variable ${RUN_ON_HOST} not defined"
    exit
fi

# - configure instance ---------------------------------------------------------
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

# - loop through list of suffix ------------------------------------------------
# - initialize replication -----------------------------------------------------
echo "initialize replication for suffix ${BASEDN} on $HOST1 from $HOST2"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize \
--hostSource "${HOST2}" --portSource "${PORT_ADMIN}" \
--hostDestination "${HOST1}" --portDestination "${PORT_ADMIN}" \
--baseDN "${BASEDN}" --adminUID "${REPMAN}" \
--adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

# - check status of replication ------------------------------------------------
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h "${HOST2}" -p "${PORT_ADMIN}" \
--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile
# - EOF ------------------------------------------------------------------------