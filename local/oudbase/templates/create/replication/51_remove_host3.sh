#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 51_remove_hostX.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.05.04
# Version....: v3.4.8
# Usage......: 51_remove_hostX.sh
# Purpose....: Simple script to remove replication on a host, where the value of
#              the host is derived from the script name. e.g. 51_remove_host3.sh
#              is for HOST3.
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

# derived the host variable from the script name
HOSTVAR=$(echo ${SCRIPTFILE}| sed -n 's/.*\(host[0-9]\).*/\1/p' | tr '[:lower:]' '[:upper:]')

# check if HOST variable is defined
if [ -n "${!HOSTVAR}" ]; then
    # check if current host does match HOSTVAR
    if [ "${HOST}" != "${!HOSTVAR}" ]; then 
        echo "skip for host ${HOST}, does only run on host ${!HOSTVAR}"
        exit
    else
        echo "ok to run script on host ${HOST}"
        HOST=${!HOSTVAR}
    fi
else
    echo "Host variable ${HOSTVAR} not defined"
    exit
fi

# - configure instance ---------------------------------------------------------
echo "Disable replication for ${OUD_INSTANCE} on ${HOST} using:"
echo "HOSTNAME          : ${HOST}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${HOST}" ]          && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PWD_FILE}" ]      && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]      && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${PORT_ADMIN}" ]    && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${DIRMAN}" ]        && echo "- skip $(basename $0), variable DIRMAN not set"            && exit

# - loop through list of suffix ------------------------------------------------
# - initialize replication -----------------------------------------------------
echo "disable replication on $HOST"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication disable \
--hostname "${HOST}" --port "${PORT_ADMIN}" \
--bindDN "${DIRMAN}" --adminPasswordFile "${PWD_FILE}" \
--disableAll --trustAll --no-prompt --noPropertiesFile
# - EOF ------------------------------------------------------------------------