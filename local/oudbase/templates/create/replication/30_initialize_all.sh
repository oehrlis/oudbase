#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 31_initialize_host1.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.05.04
# Version....: v3.4.8
# Usage......: 31_initialize_host1.sh
# Purpose....: simple script to initialize replication on HOST1 from HOST2
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

# - configure instance ---------------------------------------------------------
echo "Enable replication ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "HOST1             : ${HOST1}"
echo "HOST2             : ${HOST2}"
echo "HOST2             : ${HOST2}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "PORT_REP          : ${PORT_REP}"
echo "REPMAN            : ${REPMAN}"
echo "BASEDN            : ${BASEDN}"
echo "All suffix        : ${ALL_SUFFIX}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${HOST}" ]              && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PWD_FILE}" ]          && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]          && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${PORT_REP}" ]          && echo "- skip $(basename $0), variable PORT_REP not set"          && exit
[   -z "${PORT_ADMIN}" ]        && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${REPMAN}" ]            && echo "- skip $(basename $0), variable REPMAN not set"            && exit
[   -z "${BASEDN}" ]            && echo "- skip $(basename $0), variable BASEDN not set"            && exit

# - loop through list of suffix ------------------------------------------------
# - initialize replication -----------------------------------------------------
echo "initialize replication for suffix ${BASEDN} on ALL from $HOST"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize-all \
    --hostname "${HOST}" --port "${PORT_ADMIN}" \
    --baseDN "${BASEDN}" --adminUID "${REPMAN}" \
    --adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

# check if we have other suffix defined
if [ -n "${ALL_SUFFIX}" ]; then
    # - loop through list of suffix ------------------------------------------------
    for suffix in ${ALL_SUFFIX}; do
        echo "initialize replication for suffix ${suffix} on ALL from $HOST"
        ${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize-all \
            --hostname "${HOST}" --port "${PORT_ADMIN}" \
            --baseDN "${suffix}" --adminUID "${REPMAN}" \
            --adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile
    done
else
    echo "NO additional NET suffix defined. No suffix specific replication configuration required..."
fi

# - check status of replication ------------------------------------------------
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h "${HOST}" -p "${PORT_ADMIN}" \
--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
--advanced --trustAll --no-prompt --noPropertiesFile
# - EOF ------------------------------------------------------------------------