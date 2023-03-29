#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 99_completion_status.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.29
# Version....: v3.3.2
# Usage......: 99_completion_status.sh
# Purpose....: simple touch completion status
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

COMMON_DIR="$(dirname ${INSTANCE_INIT})/common"
STATUS_FILE="${OUD_INSTANCE}_${HOST}"

# - configure instance ---------------------------------------------------------
echo "Completion Status for ${OUD_INSTANCE} on ${HOST}:"
echo "COMMON_DIR        : ${COMMON_DIR}"
echo "STATUS_FILE       : ${STATUS_FILE}"

mkdir -p ${COMMON_DIR}
# check if HOST variable is defined
if [ -d "${COMMON_DIR}" ]; then
    echo "INFO: create status file ${COMMON_DIR}/${STATUS_FILE}"
    touch ${COMMON_DIR}/${STATUS_FILE}
fi
# - touch file when setup finished ---------------------------------------------

# - EOF ------------------------------------------------------------------------