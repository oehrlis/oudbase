#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 14_add_local_user.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.05.28
# Usage......: 14_add_local_user.sh
# Purpose....: Script to add local users
# Notes......: Script does load the LDIF file 14_add_local_user.ldif. 
# Reference..: 
# License...: Licensed under the Universal Permissive License v 1.0 as 
#             shown at http://oss.oracle.com/licenses/upl.
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -----------------------------------------------
. "$(dirname $0)/00_init_environment"
LDIFFILE="$(dirname $0)/$(basename $0 .sh).ldif"      # LDIF file based on script name
LDIFFILE_CUSTOM="$(dirname $0)/$(basename $0 .sh).ldif_${BASEDN_STRING}"
export BASE64=${BASE64:-"/usr/bin/base64"}

# - configure instance ------------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "PORT_SSL          : ${PORT_SSL}"
echo "DIRMAN            : ${DIRMAN}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "LDIFFILE          : ${LDIFFILE}"
echo "LDIFFILE_CUSTOM   : ${LDIFFILE_CUSTOM}"
echo "BASEDN            : ${BASEDN}"
echo "LOCAL_OU          : ${LOCAL_OU}"

# - configure instance --------------------------------------------------
# Update baseDN in LDIF file if required
if [ -f ${LDIFFILE} ]; then
  cp -v ${LDIFFILE} ${LDIFFILE_CUSTOM}
else
  echo "- skip $(basename $0), missing ${LDIFFILE}"
  exit
fi

echo "- Update LDIF file to match ${BASEDN} and other variables"
sed -i "s/BASEDN/${BASEDN}/g" ${LDIFFILE_CUSTOM}
sed -i "s/LOCAL_OU/${LOCAL_OU}/g" ${LDIFFILE_CUSTOM}

# encode values with umlaut
echo "- encode umlaut in LDIF"
touch ${LDIFFILE_CUSTOM}.base64
while read line ; do
  attribute="$(echo -n $line|sed 's/:\s*.*//'):"
  value="$(echo -n $line|sed -E -e 's/^.*:\s*//'|sed 's/\s*//')"
  umlaut="$(echo -n $value|sed -E '/(ü|ä|ö|ß)/Id')"
  if [ ! -n "$umlaut" ] && [ -n "${value}" ]; then
    echo "${attribute}: $(echo -n $value|${BASE64} -w 0)" >> ${LDIFFILE_CUSTOM}.base64
  else
    echo $line >> ${LDIFFILE_CUSTOM}.base64
  fi
done < ${LDIFFILE_CUSTOM}
mv -v ${LDIFFILE_CUSTOM}.base64 ${LDIFFILE_CUSTOM}

# - configure instance ------------------------------------------------------
echo "Add local Users ${OUD_INSTANCE}"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname "${HOST}" \
  --port "${PORT_SSL}" \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --useSSL \
  --trustAll \
  --defaultAdd \
  --filename "${LDIFFILE_CUSTOM}"
# - EOF ---------------------------------------------------------------------
