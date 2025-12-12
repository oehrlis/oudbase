#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 40_status_replication.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.12
# Version....: v4.0.0
# Usage......: 40_status_replication.sh
# Purpose....: simple script to display replication status
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
echo "Check replication status ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "REPMAN            : ${REPMAN}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[ -z "${HOST}" ] && echo "- skip $(basename $0), variable HOST not set" && exit
[ -z "${PWD_FILE}" ] && echo "- skip $(basename $0), variable PWD_FILE not set" && exit
[ ! -f "${PWD_FILE}" ] && echo "- skip $(basename $0), missing password file ${PWD_FILE}" && exit
[ -z "${PORT_ADMIN}" ] && echo "- skip $(basename $0), variable PORT_ADMIN not set" && exit
[ -z "${REPMAN}" ] && echo "- skip $(basename $0), variable REPMAN not set" && exit

# - check status of replication ------------------------------------------------
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h "${HOST}" -p "${PORT_ADMIN}" \
	--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
	--advanced --trustAll --no-prompt --noPropertiesFile
# - EOF ------------------------------------------------------------------------
