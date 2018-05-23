# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 90_pre_migration.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Script zum vorbereiten der Migration
# Notes......:
# Reference..: https://github.com/oehrlis/oudbase
# ---------------------------------------------------------------------------
# Rev History:
# 23.01.2018   soe  Initial version
# ---------------------------------------------------------------------------

# - load instance environment -----------------------------------------------
. "$(dirname $0)/00_init_environment.sh"

# - Prepare Migration -------------------------------------------------------
echo "Prepare replication ${OUD_INSTANCE} using:"
echo "OUD_INSTANCE_HOME : ${OUD_INSTANCE_HOME}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "HOSTNAME          : $(hostname)"
echo "HOST1             : ${HOST1}"
echo "HOST2             : ${HOST2}"
echo "HOST3             : ${HOST3}"
echo "PORT              : ${PORT}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "PORT_REP          : ${PORT_REP}"
echo "DIRMAN            : ${DIRMAN}"
echo "BASEDN            : ${BASEDN}"

${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h $HOST1 \
-p $PORT_ADMIN --adminUID "$REPMAN"  --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile

echo "disable replication for ${BASEDN} on $HOST1"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication disable \
          --hostname ${HOST1} \
          --port ${PORT_ADMIN} \
          --disableReplicationServer \
          --baseDN ${BASEDN} --adminUID "$REPMAN" \
          --adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

echo "disable replication for ${BASEDN} on $HOST2"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication disable \
          --hostname ${HOST2} \
          --port ${PORT_ADMIN} \
          --disableReplicationServer \
          --baseDN ${BASEDN} --adminUID "$REPMAN" \
          --adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

echo "disable replication for ${BASEDN} on $HOST3"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication disable \
          --hostname ${HOST3} \
          --port ${PORT_ADMIN} \
          --disableReplicationServer \
          --baseDN ${BASEDN} --adminUID "$REPMAN" \
          --adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h $HOST1 \
-p $PORT_ADMIN --adminUID "$REPMAN"  --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile

# - EOF ---------------------------------------------------------------------
