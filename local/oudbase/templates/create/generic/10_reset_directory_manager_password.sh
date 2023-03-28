#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 10_reset_directory_manager_password.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.28
# Version....: v3.1.0
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

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${PWD_FILE}" ]    && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]    && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${HOST}" ]        && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PORT_ADMIN}" ]  && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${DIRMAN}" ]      && echo "- skip $(basename $0), variable DIRMAN not set"            && exit
[   -z "${BASEDN}" ]      && echo "- skip $(basename $0), variable BASEDN not set"            && exit

# generate a temporary password
if [ $(command -v pwgen) ]; then 
  s=$(pwgen -s -1 15)
else 
  while true; do
    # use urandom to generate a random string
    s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 15 | head -n 1)
    # check if the password meet the requirements
    if [[ ${#s} -ge 10 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]; then
      echo "$s"
      break
    fi
  done
fi

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
