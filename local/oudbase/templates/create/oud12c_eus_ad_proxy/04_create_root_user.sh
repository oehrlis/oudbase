#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 04_create_root_user.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2023.02.21
# Version....: v2.10.0
# Usage......: 04_create_root_user.sh
# Purpose....: Script für das erstellen der root User
# Notes......: Das Script für die dsconfig Kommandos aus 04_create_root_user.conf
#              als Batch aus sowie die LDIF aus 04_create_root_user.ldif. 
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"
LDIFFILE="$(dirname $0)/$(basename $0 .sh).ldif"      # LDIF file based on script name
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf"    # config file based on script name

# - configure instance ---------------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "  HOSTNAME          : ${HOST}"
echo "  PORT_ADMIN        : ${PORT_ADMIN}"
echo "  DIRMAN            : ${DIRMAN}"
echo "  PWD_FILE          : ${PWD_FILE}"
echo "  KEYSTOREPIN       : ${KEYSTOREPIN}"
echo "  CONFIGFILE        : ${CONFIGFILE}"
echo "  LDIFFILE          : ${LDIFFILE}"

# - configure instance ---------------------------------------------------------
echo "- Add root user to OUD instance ${OUD_INSTANCE}"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname "${HOST}" \
  --port "${PORT_ADMIN}" \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --useSSL \
  --trustAll \
  --defaultAdd \
  --filename "${LDIFFILE}"

echo "- Configure ACI for root user"
${OUD_INSTANCE_HOME}/OUD/bin/dsconfig \
  --hostname "${HOST}" \
  --port "${PORT_ADMIN}" \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --no-prompt \
  --verbose \
  --trustAll \
  --batchFilePath "${CONFIGFILE}"
# - EOF ------------------------------------------------------------------------
