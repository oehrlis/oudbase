# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 90_post_migration.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Script zum Abschliessen der Migration
# Notes......:
# Reference..: https://github.com/oehrlis/oudbase
# ---------------------------------------------------------------------------
# Rev History:
# 23.01.2018   soe  Initial version
# ---------------------------------------------------------------------------

# - load instance environment -----------------------------------------------
. "$(dirname $0)/00_init_environment"

# - Finish Migration -------------------------------------------------------
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

echo "Enable replication for (${BASEDN}) from ${HOST1} to ${HOST2}"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication enable \
--host1 ${HOST1} --port1 ${PORT_ADMIN}  --bindDN1 "${DIRMAN}" --bindPasswordFile1 "${PWD_FILE}" \
--host2 ${HOST2} --port2 ${PORT_ADMIN}  --bindDN2 "${DIRMAN}" --bindPasswordFile2 "${PWD_FILE}"  \
--replicationPort1 ${PORT_REP} --secureReplication1 \
--replicationPort2 ${PORT_REP} --secureReplication2 \
--baseDN "${BASEDN}" --adminUID "${REPMAN}" \
--adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

echo "enable replication for ${BASEDN} from $HOST1 to $HOST3"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication enable \
--host1 $HOST1 --port1 $PORT_ADMIN --bindDN1 "$DIRMAN" --bindPasswordFile1 "${PWD_FILE}" \
--host2 $HOST3 --port2 $PORT_ADMIN --bindDN2 "$DIRMAN" --bindPasswordFile2 "${PWD_FILE}" \
--replicationPort1 $PORT_REP --secureReplication1 \
--replicationPort2 $PORT_REP --secureReplication2 \
--baseDN ${BASEDN} --adminUID "$REPMAN" \
--adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

echo "initialize replication for ${BASEDN} on all hosts"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize-all \
-h ${HOST1} -p ${PORT_ADMIN}  --baseDN ${BASEDN}  \
--adminUID "${REPMAN}"  --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile

${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h $HOST1 \
-p $PORT_ADMIN --adminUID "$REPMAN"  --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile

# - EOF ---------------------------------------------------------------------
