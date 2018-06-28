#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 10_enable_replication.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: Script zum einschalten und initialisieren der Replication
# Notes......:
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment.sh"

# - Enable replication --------------------------------------------------
echo "Enable replication ${OUD_INSTANCE} using:"
echo "OUD_INSTANCE_HOME : ${OUD_INSTANCE_HOME}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "HOSTNAME          : ${HOST}"
echo "HOST1             : ${HOST1}"
echo "HOST2             : ${HOST2}"
echo "PORT              : ${PORT}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "PORT_REP          : ${PORT_REP}"
echo "DIRMAN            : ${DIRMAN}"
echo "BASEDN            : ${BASEDN}"

echo "Enable replication for (${BASEDN}) from ${HOST1} to ${HOST2}"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication enable \
--host1 ${HOST1} --port1 ${PORT_ADMIN}  --bindDN1 "${DIRMAN}" --bindPasswordFile1 "${PWD_FILE}" \
--host2 ${HOST2} --port2 ${PORT_ADMIN}  --bindDN2 "${DIRMAN}" --bindPasswordFile2 "${PWD_FILE}"  \
--replicationPort1 ${PORT_REP} --secureReplication1 \
--replicationPort2 ${PORT_REP} --secureReplication2 \
--baseDN "${BASEDN}" --adminUID "${REPMAN}" \
--adminPasswordFile "${PWD_FILE}" --trustAll --no-prompt --noPropertiesFile

echo "initialize replication for ${BASEDN} on all hosts"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize-all \
-h ${HOST1} -p ${PORT_ADMIN}  --baseDN ${BASEDN}  \
--adminUID "${REPMAN}"  --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile

${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h ${HOST1} -p ${PORT_ADMIN} \
--adminUID "${REPMAN}" --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile

# - EOF -----------------------------------------------------------------
