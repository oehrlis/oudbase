#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 20_wait_for_host2.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.08.30
# Version....: v2.7.0
# Usage......: 20_wait_for_host2.sh
# Purpose....: Script to wait for other host to be ready
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

SCRIPTFILE="$(dirname $0)/$(basename $0)"
SCRIPT_BASE="$(dirname $SCRIPTFILE)"
INSTANCE_INIT=${INSTANCE_INIT:-$(dirname $SCRIPT_BASE)}

# extract the host* from the script name and convert it to upper case
HOSTVAR=$(echo ${SCRIPTFILE}| sed -n 's/.*\(host[0-9]\).*/\1/p' | tr '[:lower:]' '[:upper:]')
WAIT_HOST=${!HOSTVAR}
WAIT_TIME=${WAIT_TIME:-"5"}
COMMON_DIR="$(dirname ${INSTANCE_INIT})/common"
STATUS_FILE="${OUD_INSTANCE}_${WAIT_HOST}"

echo "Wait host identified as $HOSTVAR=${WAIT_HOST}"

# check if current host does match RUN_NOT_ON_HOST
if [ "${HOST}" == "${WAIT_HOST}" ]; then 
    echo "skip wait for host ${HOST}, no need to wait on ${WAIT_HOST}"
    exit
else
    echo "ok to run wait script on host ${HOST}"
fi

# check lock file from host 1
echo "check for lock file  ${COMMON_DIR}/${STATUS_FILE}"
while [ ! -f ${COMMON_DIR}/${STATUS_FILE} ]; do
    echo "wait for ${WAIT_HOST} and lock file ${COMMON_DIR}/${STATUS_FILE}"
    sleep ${WAIT_TIME}
done

echo "initial wait for ${WAIT_HOST} (${WAIT_TIME}s)"
sleep ${WAIT_TIME}
# check host via LDAPSEARCH
${OUD_INSTANCE_HOME}/OUD/bin/ldapsearch \
    --hostname ${WAIT_HOST} \
    --port $PORT \
    --baseDN '' \
    --searchScope base "(objectclass=*)" vendorname >/dev/null 2>&1

# start while loop until host is available
while [ $? -ne 0 ]; do 
    echo "wait for ${WAIT_HOST}"
    sleep ${WAIT_TIME}
    ${OUD_INSTANCE_HOME}/OUD/bin/ldapsearch \
    --hostname ${WAIT_HOST} \
    --port $PORT \
    --baseDN '' \
    --searchScope base "(objectclass=*)" vendorname >/dev/null 2>&1
done
# - EOF ------------------------------------------------------------------------
