#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 10_reset_directory_manager_password.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.08.17
# Version....: v2.1.2
# Purpose....: Adjust cn=Directory Manager to use new password storage scheme
# Notes......: --
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"

# - configure instance ---------------------------------------------------------
echo "- reset admin user password for OUD instance ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "PWD_FILE          : ${PWD_FILE}"

# generate a temporary password
while true; do
    s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 10 | head -n 1)
    if [[ ${#s} -ge 8 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]; then
        break
    fi
done

# Temporary admin password
ADMIN_PASSWORD=$s

echo "- set temporary password for ${DIRMAN}"
# set the Directory Manager password to the temporary password ADMIN_PASSWORD
${OUD_INSTANCE_HOME}/OUD/bin/ldappasswordmodify \
  --hostname ${HOST} \
  --port $PORT_ADMIN --trustAll --useSSL \
  --authzID "${DIRMAN}" \
 --currentPasswordFile $PWD_FILE --newPassword ${ADMIN_PASSWORD}

echo "- reset password for ${DIRMAN}"
# set the Directory Manager password back to the original password
${OUD_INSTANCE_HOME}/OUD/bin/ldappasswordmodify \
  --hostname ${HOST} \
  --port $PORT_ADMIN --trustAll --useSSL \
  --authzID "${DIRMAN}" \
 --currentPassword ${ADMIN_PASSWORD} --newPasswordFile $PWD_FILE 

echo "- review Directory Manager"
${OUD_INSTANCE_HOME}/OUD/bin/ldapsearch \
  --hostname ${HOST} \
  --port $PORT_ADMIN --trustAll --useSSL \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --baseDN "cn=config" "${DIRMAN}" uid userpassword
# - EOF ------------------------------------------------------------------------
