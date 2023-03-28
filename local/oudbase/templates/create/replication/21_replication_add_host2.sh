#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 21_replication_add_host2.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.28
# Version....: v3.1.0
# Usage......: 21_replication_add_host2.sh
# Purpose....: simple script to add and initialize replication
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

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${HOST}" ]              && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${HOST1}" ]             && echo "- skip $(basename $0), variable HOST1 not set"             && exit
[   -z "${HOST2}" ]             && echo "- skip $(basename $0), variable HOST2 not set"             && exit
[   -z "${PWD_FILE}" ]          && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]          && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${HOST}" ]              && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PORT_REP}" ]          && echo "- skip $(basename $0), variable PORT_REP not set"          && exit
[   -z "${PORT_ADMIN}" ]        && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${PORT_REST_ADMIN}" ]   && echo "- skip $(basename $0), variable PORT_REST_ADMIN not set"   && exit
[   -z "${PORT_REST_HTTP}" ]    && echo "- skip $(basename $0), variable PORT_REST_HTTP not set"    && exit
[   -z "${PORT_REST_HTTPS}" ]   && echo "- skip $(basename $0), variable PORT_REST_HTTPS not set"   && exit
[   -z "${DIRMAN}" ]            && echo "- skip $(basename $0), variable DIRMAN not set"            && exit
[   -z "${REPMAN}" ]            && echo "- skip $(basename $0), variable REPMAN not set"            && exit
[   -z "${BASEDN}" ]            && echo "- skip $(basename $0), variable BASEDN not set"            && exit
# - loop through list of suffix ------------------------------------------------
# - add suffix -----------------------------------------------------------------
echo "enable replication for suffix (${BASEDN}) from $HOST1 to $HOST2"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication enable \
--host1 "${HOST1}" --port1 "${PORT_ADMIN}" --bindDN1 "${DIRMAN}" --bindPasswordFile1 "${PWD_FILE}" \
--host2 "${HOST2}" --port2 "${PORT_ADMIN}" --bindDN2 "${DIRMAN}" --bindPasswordFile2 "${PWD_FILE}" \
--replicationPort1 "${PORT_REP}" --secureReplication1 \
--replicationPort2 "${PORT_REP}" --secureReplication2 \
--baseDN "${BASEDN}" --adminUID "${REPMAN}" \
--adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

# - initialize replication -----------------------------------------------------
echo "initialize replication for suffix ${BASEDN} on $HOST2 from $HOST1"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize \
--hostSource "${HOST1}" --portSource "${PORT_ADMIN}" \
--hostDestination "${HOST2}" --portDestination "${PORT_ADMIN}" \
--baseDN "${BASEDN}" --adminUID "${REPMAN}" \
--adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

# check if we have other suffix defined
if [ -n "${ALL_SUFFIX}" ]; then
    # - loop through list of suffix ------------------------------------------------
    for suffix in ${ALL_SUFFIX}; do
        echo "enable replication for suffix (${suffix}) from $HOST1 to $HOST2"
        ${OUD_INSTANCE_HOME}/OUD/bin/dsreplication enable \
        --host1 "${HOST1}" --port1 "${PORT_ADMIN}" --bindDN1 "${DIRMAN}" --bindPasswordFile1 "${PWD_FILE}" \
        --host2 "${HOST2}" --port2 "${PORT_ADMIN}" --bindDN2 "${DIRMAN}" --bindPasswordFile2 "${PWD_FILE}" \
        --replicationPort1 "${PORT_REP}" --secureReplication1 \
        --replicationPort2 "${PORT_REP}" --secureReplication2 \
        --baseDN "${suffix}" --adminUID "${REPMAN}" \
        --adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

        # - initialize replication -----------------------------------------------------
        echo "initialize replication for suffix ${suffix} on $HOST2 from $HOST1"
        ${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize \
        --hostSource "${HOST1}" --portSource "${PORT_ADMIN}" \
        --hostDestination "${HOST2}" --portDestination "${PORT_ADMIN}" \
        --baseDN "${suffix}" --adminUID "${REPMAN}" \
        --adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile
    done
else
    echo "NO additional NET suffix defined. No suffix specific replication configuration required..."
fi

# - check status of replication ------------------------------------------------
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h "${HOST1}" -p "${PORT_ADMIN}" \
--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile
# - EOF ------------------------------------------------------------------------