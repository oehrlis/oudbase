#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 02_config_eus_context.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
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
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment"
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf"      # config file based on script name

# - configure instance --------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "  BASEDN            : ${BASEDN}"
echo "  CONFIGFILE        : ${CONFIGFILE}"
echo "  AD_PDC_HOST       : ${AD_PDC_HOST}"
echo "  AD_PDC_PORT       : ${AD_PDC_PORT}"
echo "  AD_PDC_USER       : ${AD_PDC_USER}"
echo "  AD_PDC_PASSWORD   : **********"

# Update baseDN in config file if required
if [[ "$BASEDN" != "dc=example,dc=com" ]]; then
  echo "  Different base DN than default dc=example,dc=com."
  echo "  Update config and LDIF files to match $BASEDN" 
  sed -i "s/dc=example,dc=com/$BASEDN/" ${CONFIGFILE}
fi

# Update AD PDC Information in config file
sed -i "s/AD_PDC_HOST/${AD_PDC_HOST}/" ${CONFIGFILE}
sed -i "s/AD_PDC_PORT/${AD_PDC_PORT}/" ${CONFIGFILE}
sed -i "s/AD_PDC_USER/\"${AD_PDC_USER}\"/" ${CONFIGFILE}
sed -i "s/AD_PDC_PASSWORD/${AD_PDC_PASSWORD}/" ${CONFIGFILE}

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
  --batchFilePath "${CONFIGFILE}"

# - EOF -----------------------------------------------------------------