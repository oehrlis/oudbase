#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 02_config_eus_context.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.07.09
# Version....: v2.4.0
# Purpose....: Script to configure the EUS context in the OUD proxy instance.
# Notes......: The config file 02_config_eus_context.conf is executed using
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
CONFIGFILE_CUSTOM="$(dirname $0)/$(basename $0 .sh)_${BASEDN_STRING}"
# - configure instance ---------------------------------------------------------
echo "Configure OUD proxy instance ${OUD_INSTANCE} using:"
echo "  BASEDN            : ${BASEDN}"
echo "  BASEDN_STRING     : ${BASEDN_STRING}"
echo "  CONFIGFILE        : ${CONFIGFILE}"
echo "  CONFIGFILE_CUSTOM : ${CONFIGFILE_CUSTOM}"
echo "  AD_PDC_HOST       : ${AD_PDC_HOST}"
echo "  AD_PDC_PORT       : ${AD_PDC_PORT}"
echo "  AD_PDC_USER       : ${AD_PDC_USER}"
echo "  AD_PDC_PASSWORD   : ${AD_PDC_PASSWORD}"

LOCAL_AD_PDC_PASSWORD=""
# check if we do have a password file
if [ -f "${AD_PDC_PASSWORD_FILE}" ]; then
  # set the local password variable pased on password file
  LOCAL_AD_PDC_PASSWORD=$(cat ${AD_PDC_PASSWORD_FILE})
else
  # set the local password variable pased on password variable 
  # or to defalt if variable is empty
  LOCAL_AD_PDC_PASSWORD=${AD_PDC_PASSWORD:-"default"}
fi

# Update baseDN in LDIF file if required
if [ -f ${CONFIGFILE} ]; then
  cp ${CONFIGFILE} ${CONFIGFILE_CUSTOM}
else
  echo "- skip $(basename $0), missing ${CONFIGFILE}"
  exit
fi

echo "- Update batch file to match ${BASEDN} and other variables"
echo "Update conf files to match AD" 
sed -i "s/AD_PDC_HOST/${AD_PDC_HOST}/g" ${CONFIGFILE_CUSTOM}
sed -i "s/AD_PDC_PORT/${AD_PDC_PORT}/g" ${CONFIGFILE_CUSTOM}
sed -i "s/AD_PDC_USER/${AD_PDC_USER}/g" ${CONFIGFILE_CUSTOM}
sed -i "s/AD_PDC_PASSWORD/${LOCAL_AD_PDC_PASSWORD}/g" ${CONFIGFILE_CUSTOM}
sed -i "s/BASEDN/${BASEDN}/g" ${CONFIGFILE_CUSTOM}

echo "  Configure EUS context in OUD Proxy Instance"
${OUD_INSTANCE_HOME}/OUD/bin/dsconfig \
  --hostname ${HOST} \
  --port ${PORT_ADMIN} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --no-prompt \
  --verbose \
  --verbose \
  --trustAll \
  --batchFilePath "${CONFIGFILE_CUSTOM}"

# - EOF ------------------------------------------------------------------------