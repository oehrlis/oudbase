#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 20_wait_for_host2.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.28
# Version....: v3.0.2
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

# extract the host* from the script name and convert it to upper case
HOSTVAR=$(echo ${SCRIPTFILE}| sed -n 's/.*\(host[0-9]\).*/\1/p' | tr '[:lower:]' '[:upper:]')
RUN_ON_HOST=${!HOSTVAR}

echo "Run host identified as $HOSTVAR=${RUN_ON_HOST}"

# check if current host does match RUN_NOT_ON_HOST
if [ "${HOST}" == "${RUN_ON_HOST}" ]; then 
    echo "Run stuff on host ${RUN_ON_HOST}"
else
    echo "Skip script $(basename $SCRIPTFILE) on host ${HOST}"
fi

# - EOF ------------------------------------------------------------------------
