#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 02_import_data_offline.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: Script für das offline laden der Directory Daten
# Notes......: Das Script stoppt die Instanz und fuehrt ein offline import
#              mit import-ldif durch. Anschliesend wird die Instanz wieder 
#              gestartet.
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment"
LDIFFILE="$(basename $0 .sh).ldif"      # LDIF file based on script name
CONFIGFILE="$(basename $0 .sh).conf"    # config file based on script name

# - configure instance --------------------------------------------------
echo "Offline data load for OUD instance ${OUD_INSTANCE} using:"
echo "OUD_INSTANCE_HOME : ${OUD_INSTANCE_HOME}"
echo "LDIFFILE          : ${LDIFFILE}"
echo "BASEDN            : ${BASEDN}"

echo "Stop OUD instance ${OUD_INSTANCE}"
${OUD_INSTANCE_HOME}/OUD/bin/stop-ds

echo "Offine data import"
${OUD_INSTANCE_HOME}/OUD/bin/import-ldif \
  --includeBranch "${BASEDN}" \
  --backendID userRoot \
  --ldifFile "${LDIFFILE}"

echo "Start OUD instance ${OUD_INSTANCE}"
${OUD_INSTANCE_HOME}/OUD/bin/start-ds

# - EOF -----------------------------------------------------------------
