#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 12_replication_add_host2.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: Script zum initializieren der Replikation
# Notes......:
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Rev History:
# 23.01.2018   soe  Initial version
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment.sh"

# - Enable Replication --------------------------------------------------
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

echo "initialize replication for ${BASEDN} on $HOST1 from $HOST2"
${OUD_INSTANCE_HOME}/OUD/bin/dsreplication initialize \
--hostSource $HOST2 --portSource $PORT_ADMIN \
--hostDestination $HOST1 --portDestination $PORT_ADMIN \
--baseDN ${BASEDN} \
--adminUID "$REPMAN" --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile

${OUD_INSTANCE_HOME}/OUD/bin/dsreplication status -h $HOST2 \
-p $PORT_ADMIN --adminUID "$REPMAN"  --adminPasswordFile "${PWD_FILE}" \
--trustAll --no-prompt --noPropertiesFile

# - EOF -----------------------------------------------------------------
