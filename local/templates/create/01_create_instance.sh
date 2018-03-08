# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 01_create_instance.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Script zum erstellen der OUD Instanz
# Notes......:
# Reference..:
# ---------------------------------------------------------------------------
# Rev History:
# 08.03.2018   soe  Initial version
# ---------------------------------------------------------------------------

# - load instance environment -----------------------------------------------
. "$(dirname $0)/00_init_environment.sh"

# - create instance ---------------------------------------------------------
echo "Create OUD instance ${OUD_INSTANCE} using:"
echo "OUD_INSTANCE_HOME : ${OUD_INSTANCE_HOME}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "HOSTNAME          : $(hostname)"
echo "PORT              : ${PORT}"
echo "PORT_SSL          : ${PORT_SSL}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "BASEDN            : ${BASEDN}"

${ORACLE_HOME}/oud/oud-setup \
  --cli \
  --instancePath "${OUD_INSTANCE_HOME}/OUD" \
  --rootUserDN "${DIRMAN}" \
  --rootUserPasswordFile "${PWD_FILE}" \
  --hostname $(hostname) \
  --ldapPort ${PORT} \
  --ldapsPort ${PORT_SSL} \
  --adminConnectorPort ${PORT_ADMIN} \
  --baseDN  ${BASEDN} \
  --addBaseEntry \
  --generateSelfSignedCertificate \
  --serverTuning jvm-default \
  --offlineToolsTuning jvm-default \
  --no-prompt \
  --noPropertiesFile

# - EOF ---------------------------------------------------------------------
