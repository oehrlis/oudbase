# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 04_create_root_user.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Script für das erstellen der root User
# Notes......: Das Script laedt das LDIF file 04_create_root_user.ldif und
#              fuehrt die dsconfig Kommandos aus 04_create_root_user.config
#              als Batch aus. Diese lassen sich bei Bedarf auch einzel ausführen.
#
# Reference..: https://github.com/oehrlis/oudbase
# ---------------------------------------------------------------------------
# Rev History:
# 07.03.2018   soe  Initial version
# ---------------------------------------------------------------------------

# - load instance environment -----------------------------------------------
. "$(dirname $0)/00_init_environment.sh"
LDIFFILE="$(basename $0 .sh).ldif"          # LDIF file based on script name
CONFIGFILE="$(basename $0 .sh).conf"        # config file based on script name

# - configure instance ------------------------------------------------------
echo "Add root user to OUD instance ${OUD_INSTANCE} using:"
echo "OUD_INSTANCE_HOME : ${OUD_INSTANCE_HOME}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "HOSTNAME          : $(hostname)"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "LDIFFILE          : ${LDIFFILE}"
echo "CONFIGFILE        : ${CONFIGFILE}"

${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname $(hostname) \
  --port ${PORT_ADMIN} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --useSSL \
  --trustAll \
  --defaultAdd \
  --filename "${LDIFFILE}"

${OUD_INSTANCE_HOME}/OUD/bin/dsconfig \
  --hostname $(hostname) \
  --port ${PORT_ADMIN} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --no-prompt \
  --verbose \
  --trustAll \
  --batchFilePath "${CONFIGFILE}"

# - EOF ---------------------------------------------------------------------
