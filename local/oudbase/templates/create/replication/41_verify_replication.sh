#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 41_verify_replication.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.31
# Version....: v3.4.3
# Usage......: 41_verify_replication.sh
# Purpose....: simple script to verify replication status
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
echo "Verify replication status ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "REPMAN            : ${REPMAN}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${HOST}" ]          && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PWD_FILE}" ]      && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]      && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${PORT_ADMIN}" ]    && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${REPMAN}" ]        && echo "- skip $(basename $0), variable REPMAN not set"            && exit

# - check status of replication ------------------------------------------------
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication verify --hostname "${HOST}" \
--port "${PORT_ADMIN}" --trustAll --no-prompt \
--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
--advanced --noPropertiesFile --no-prompt
# - EOF ------------------------------------------------------------------------