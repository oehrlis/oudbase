#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 02_config_basedn.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.08.17
# Version....: v2.5.0
# Purpose....: Script to configure base DN and add ou's for users and groups.
# Notes......: BaseDN in 02_config_basedn.ldif will be updated before
#              it is loaded using ldapmodify.
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"
LDIFFILE="$(dirname $0)/$(basename $0 .sh).ldif"      # LDIF file based on script name
LDIFFILE_CUSTOM="$(dirname $0)/$(basename $0 .sh).ldif_${BASEDN_STRING}"
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf"      # config file based on script name
CONFIGFILE_CUSTOM="$(dirname $0)/$(basename $0 .sh).conf_${BASEDN_STRING}"
# - configure instance ---------------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "  HOSTNAME          : ${HOST}"
echo "  PORT              : ${PORT}"
echo "  PORT_SSL          : ${PORT_SSL}"
echo "  PORT_ADMIN        : ${PORT_ADMIN}"
echo "  DIRMAN            : ${DIRMAN}"
echo "  PWD_FILE          : ${PWD_FILE}"
echo "  BASEDN            : ${BASEDN}"
echo "  BASEDN_STRING     : ${BASEDN_STRING}"
echo "  GROUP_OU          : ${GROUP_OU}"
echo "  USER_OU           : ${USER_OU}"
echo "  LDIFFILE          : ${LDIFFILE}"
echo "  LDIFFILE_CUSTOM   : ${LDIFFILE_CUSTOM}"
echo "  CONFIGFILE        : ${CONFIGFILE}"
echo "  CONFIGFILE_CUSTOM : ${CONFIGFILE_CUSTOM}"
echo ""

# - configure instance ---------------------------------------------------------
# Update baseDN in LDIF file if required
if [ -f ${LDIFFILE} ]; then
  cp ${LDIFFILE} ${LDIFFILE_CUSTOM}
else
  echo "- skip $(basename $0), missing ${LDIFFILE}"
  exit
fi

echo "- Update LDIF file to match ${BASEDN} and other variables"
sed -i "s/BASEDN/${BASEDN}/g" ${LDIFFILE_CUSTOM}
sed -i "s/USER_OU/${USER_OU}/g" ${LDIFFILE_CUSTOM}
sed -i "s/GROUP_OU/${GROUP_OU}/g" ${LDIFFILE_CUSTOM}
sed -i "s/LOCAL_OU/${LOCAL_OU}/g" ${LDIFFILE_CUSTOM}

echo "- Configure base DN for groups, people and entries"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname ${HOST} \
  --port ${PORT_SSL} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --useSSL \
  --trustAll \
  --defaultAdd \
  --filename "${LDIFFILE_CUSTOM}"

# Update baseDN in LDIF file if required
if [ -f ${CONFIGFILE} ]; then
  cp ${CONFIGFILE} ${CONFIGFILE_CUSTOM}
else
  echo "- skip $(basename $0), missing ${CONFIGFILE}"
  exit
fi

echo "- Update batch file to match ${BASEDN} and other variables"
sed -i "s/BASEDN/${BASEDN}/g" ${CONFIGFILE_CUSTOM}
sed -i "s/LOCAL_OU/${LOCAL_OU}/g" ${CONFIGFILE_CUSTOM}

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
# - EOF ------------------------------------------------------------------------