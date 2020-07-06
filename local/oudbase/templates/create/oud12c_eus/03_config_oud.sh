#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 03_config_oud.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.06.30
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
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at https://oss.oracle.com/licenses/upl.
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment"
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf"      # config file based on script name
CONFIGFILE_CUSTOM="$(dirname $0)/$(basename $0 .sh)_${BASEDN_STRING}"
# - configure instance --------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "  BASEDN            : ${BASEDN}"
echo "  BASEDN_STRING     : ${BASEDN_STRING}"
echo "  CONFIGFILE        : ${CONFIGFILE}"
echo "  CONFIGFILE_CUSTOM : ${CONFIGFILE_CUSTOM}"
echo ""

# Update baseDN in LDIF file if required
if [ -f ${CONFIGFILE} ]; then
  cp -v ${CONFIGFILE} ${CONFIGFILE_CUSTOM}
else
  echo "- skip $(basename $0), missing ${CONFIGFILE}"
  exit
fi

echo "- Update batch file to match ${BASEDN} and other variables"
sed -i "s/BASEDN/${BASEDN}/g" ${CONFIGFILE_CUSTOM}

echo "  Config OUD Proxy Instance"
${OUD_INSTANCE_HOME}/OUD/bin/dsconfig \
  --hostname ${HOST} \
  --port ${PORT_ADMIN} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --no-prompt \
  --verbose \
  --trustAll \
  --batchFilePath "${CONFIGFILE_CUSTOM}"
# - EOF -----------------------------------------------------------------
