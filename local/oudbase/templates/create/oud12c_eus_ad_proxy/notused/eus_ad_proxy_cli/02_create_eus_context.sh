#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 02_create_eus_context.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.06.26
# Revision...: --
# Purpose....: Script to add an EUS context to the OUD proxy instance.
# Notes......: BaseDN in 02_create_eus_context.conf will be updated before
#              it is executed with dsconfig as batch.
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment"
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf"      # config file based on script name
LDIFFILE="$(dirname $0)/$(basename $0 .sh).ldif"      # LDIF file based on script name

# Update baseDN in config file if required
if [[ "$BASEDN" != "dc=example,dc=com" ]]; then
  echo "Different base DN than default dc=example,dc=com."
  echo "Update config and LDIF files to match $BASEDN" 
  sed -i "s/dc=example,dc=com/$BASEDN/" ${CONFIGFILE}
  sed -i "s/dc=example,dc=com/$BASEDN/" ${LDIFFILE}
fi

# Update AD PDC Information in config file
sed -i "s/AD_PDC_HOST/$AD_PDC_HOST/" ${CONFIGFILE}
sed -i "s/AD_PDC_PORT/$AD_PDC_PORT/" ${CONFIGFILE}
sed -i "s/AD_PDC_USER/$AD_PDC_USER/" ${CONFIGFILE}
sed -i "s/AD_PDC_PASSWORD/$AD_PDC_PASSWORD/" ${CONFIGFILE}

# - add EUS context to proxy instance -----------------------------------
echo "INFO: Add EUS OracleContext workflows to OUD proxy instance ${OUD_INSTANCE}"
${OUD_INSTANCE_HOME}/OUD/bin/dsconfig \
  --hostname ${HOST} \
  --port ${PORT_ADMIN} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --no-prompt \
  --verbose \
  --verbose \
  --trustAll \
  --batchFilePath "${CONFIGFILE}"

echo "INFO: Add EUS OracleContext to OUD proxy instance ${OUD_INSTANCE}"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname ${HOST} \
  --port ${PORT} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --defaultAdd \
  --filename "${ORACLE_HOME}/oud/config/EUS/oracleContext.ldif"

echo "INFO: Update EUS Realm configuration"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname ${HOST} \
  --port ${PORT} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --defaultAdd \
  --filename "${LDIFFILE}"

# - EOF -----------------------------------------------------------------
