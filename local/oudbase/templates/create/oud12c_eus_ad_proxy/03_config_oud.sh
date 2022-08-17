#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 03_config_oud.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.08.17
# Revision...: --
# Purpose....: Script to configure the OUD proxy instance.
# Notes......: The config file 03_config_oud_proxy.conf is executed using
#              dsconfig in batch mode. If required, each command can 
#              also be executed individually.
#
#              dsconfig -h ${HOSTNAME} -p $PORT_ADMIN \
#                  -D "cn=Directory Manager"-j $PWD_FILE -X -n \
#                  <COMMAND>
#
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf"      # config file based on script name
# - configure instance ---------------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "  HOSTNAME          : ${HOST}"
echo "  PORT_ADMIN        : ${PORT_ADMIN}"
echo "  DIRMAN            : ${DIRMAN}"
echo "  PWD_FILE          : ${PWD_FILE}"
echo "  BASEDN            : ${BASEDN}"
echo "  BASEDN_STRING     : ${BASEDN_STRING}"
echo "  CONFIGFILE        : ${CONFIGFILE}"
echo ""

echo "  Config OUD Proxy Instance"
${OUD_INSTANCE_HOME}/OUD/bin/dsconfig \
  --hostname ${HOST} \
  --port ${PORT_ADMIN} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --no-prompt \
  --verbose \
  --trustAll \
  --batchFilePath "${CONFIGFILE}"
# - EOF ------------------------------------------------------------------------
