#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 21_replication_add_host2.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.09.04
# Usage......: 21_replication_add_host2.sh
# Purpose....: simple script to add and initialize replication
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

# limit Script to run on HOST1
RUN_ON_HOST="HOST1"         # define the HOST Variable from the 00_init_environment file
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

# check if HOST3 is defined
if [ -z "${HOST3}" ]; then
    echo "HOST3 not defined"
    exit
fi

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

# - loop through list of suffix ---------------------------------------------
# - add suffix --------------------------------------------------------------
echo "enable replication for suffix (${BASEDN}) from $HOST1 to $HOST3"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication enable \
--host1 "${HOST1}" --port1 "${PORT_ADMIN}" --bindDN1 "${DIRMAN}" --bindPasswordFile1 "${PWD_FILE}" \
--host2 "${HOST3}" --port2 "${PORT_ADMIN}" --bindDN2 "${DIRMAN}" --bindPasswordFile2 "${PWD_FILE}" \
--replicationPort1 "${PORT_REP}" --secureReplication1 \
--replicationPort2 "${PORT_REP}" --secureReplication2 \
--baseDN "${BASEDN}" --adminUID "${REPMAN}" \
--adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

# - initialize replication --------------------------------------------------
echo "initialize replication for suffix ${BASEDN} on $HOST3 from $HOST1"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize \
--hostSource "${HOST1}" --portSource "${PORT_ADMIN}" \
--hostDestination "${HOST3}" --portDestination "${PORT_ADMIN}" \
--baseDN "${BASEDN}" --adminUID "${REPMAN}" \
--adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

# - check status of replication ---------------------------------------------
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h "${HOST1}" -p "${PORT_ADMIN}" \
--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile
# - EOF ---------------------------------------------------------------------