#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 05_config_eus_realm.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.28
# Version....: v3.0.3
# Purpose....: Script to configure EUS realm to the OUD proxy instance.
# Notes......: BaseDN in 05_config_eus_realm.ldif will be updated before
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
# - configure instance ---------------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "  HOSTNAME          : ${HOST}"
echo "  PORT              : ${PORT}"
echo "  PORT_SSL          : ${PORT_SSL}"
echo "  DIRMAN            : ${DIRMAN}"
echo "  PWD_FILE          : ${PWD_FILE}"
echo "  BASEDN            : ${BASEDN}"
echo "  BASEDN_STRING     : ${BASEDN_STRING}"
echo "  GROUP_OU          : ${GROUP_OU}"
echo "  USER_OU           : ${USER_OU}"
echo "  LDIFFILE          : ${LDIFFILE}"
echo "  LDIFFILE_CUSTOM   : ${LDIFFILE_CUSTOM}"
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

echo "- Update EUS Realm configuration"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname ${HOST} \
  --port ${PORT_SSL} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --useSSL \
  --trustAll \
  --defaultAdd \
  --filename "${LDIFFILE_CUSTOM}"
# - EOF ------------------------------------------------------------------------
