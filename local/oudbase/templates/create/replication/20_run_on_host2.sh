#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 20_wait_for_host2.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.09.26
# Usage......: 20_wait_for_host2.sh
# Purpose....: Script to wait for other host to be ready
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

# - EOF ---------------------------------------------------------------------
