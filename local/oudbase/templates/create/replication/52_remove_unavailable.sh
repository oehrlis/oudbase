#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 52_remove_unavailable.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.29
# Version....: v3.3.0
# Usage......: 52_remove_unavailable.sh
# Purpose....: Script to remove unavailable replication hosts
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

# get the name of the script to derived the host name
SCRIPTFILE="$(dirname $0)/$(basename $0)"

# - configure instance ---------------------------------------------------------
echo "Disable replication for Unavailable replication hosts using:"
echo "HOSTNAME          : ${HOST}"
echo "HOST1             : ${HOST1}"
echo "HOST2             : ${HOST2}"
echo "HOST3             : ${HOST3}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "REPMAN            : ${REPMAN}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${HOST}" ]          && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PWD_FILE}" ]      && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]      && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${PORT_ADMIN}" ]    && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${DIRMAN}" ]        && echo "- skip $(basename $0), variable DIRMAN not set"            && exit

# get the list of unavailable hosts
UNAVAILABLE_HOSTS=$(${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status \
--hostname "${HOST}" --port "${PORT_ADMIN}" \
--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
--advanced --trustAll --no-prompt --noPropertiesFile \
--script-friendly 2>/dev/null|sed -n "s/^Server:\s*\(.*\):<Unknown.*/\1/p" |sort -u)

# process list of unavailable hosts
if [ -n "$UNAVAILABLE_HOSTS" ]; then
    echo "INFO: Unavailable replication hosts found..."
    for i in $UNAVAILABLE_HOSTS; do
        # start to remove unavailable hosts
        echo "INFO: Disable replication for host $i"
        ${OUD_INSTANCE_HOME}/OUD/bin/dsreplication disable \
            --hostname "${HOST}" --port "${PORT_ADMIN}" \
            --bindDN "${DIRMAN}" --adminPasswordFile "${PWD_FILE}" \
            --unreachableServer "$i:${PORT_ADMIN}" --trustAll \
            --no-prompt --noPropertiesFile
    done
else
    echo "INFO: All replication hosts seem to be available..."
fi
# - EOF ------------------------------------------------------------------------