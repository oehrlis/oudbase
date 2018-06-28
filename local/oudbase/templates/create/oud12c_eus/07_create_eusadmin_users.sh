#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 07_create_eusadmin_users.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.06.27
# Revision...: --
# Purpose....: Script to update uniqueMember of EUS Context Admins.
# Notes......: --
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment"

# - configure instance --------------------------------------------------
echo "Create root user for OUD proxy instance ${OUD_INSTANCE} using:"
echo "  BASEDN            : ${BASEDN}"

echo "  update uniqueMember of cn=OracleContextAdmins,cn=groups,cn=OracleContext,${BASEDN}"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname ${HOST} \
  --port $PORT \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" <<LDIF
dn: cn=OracleContextAdmins,cn=groups,cn=OracleContext,${BASEDN}
changetype: modify
add: uniquemember
uniquemember: cn=eusadmin,cn=Root DNs,cn=config
uniquemember: cn=oudadmin,cn=Root DNs,cn=config
LDIF

# - EOF -----------------------------------------------------------------
