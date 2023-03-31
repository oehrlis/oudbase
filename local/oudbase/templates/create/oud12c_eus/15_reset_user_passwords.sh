#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 15_reset_user_passwords.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.31
# Version....: v3.4.2
# Usage......: 15_reset_user_passwords.sh
# Purpose....: Script to reset admin user passwords
# Notes......: 
# Reference..: 
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"

# Get the root users
echo "- get user from directory -----------------------------------------------"
mapfile -t COMMON_USERS < <(${OUD_INSTANCE_HOME}/OUD/bin/ldapsearch --hostname ${HOST} --port $PORT_SSL --trustAll --useSSL -D "${DIRMAN}"  -j ${PWD_FILE} -b "${BASEDN}" "(objectClass=person)" dn|sed 's/^dn: //'|grep -i 'cn')
DEFAULT_USERS_PWD_FILE=${DEFAULT_USERS_PWD_FILE:-"${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_default_user_pwd.txt"}

# - configure instance ---------------------------------------------------------
echo "- reset admin user password for OUD instance ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "DEFAULT_PASSWORD  : ${DEFAULT_PASSWORD}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${PWD_FILE}" ]    && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]    && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${HOST}" ]        && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PORT_ADMIN}" ]  && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${DIRMAN}" ]      && echo "- skip $(basename $0), variable DIRMAN not set"            && exit

# generate a password
if [ -z "${DEFAULT_PASSWORD}" ]; then
  if [ -f "${DEFAULT_USERS_PWD_FILE}" ]; then
    echo "- user password from default user password file (${DEFAULT_USERS_PWD_FILE})..."
    DEFAULT_PASSWORD=$(cat ${DEFAULT_USERS_PWD_FILE})
  else
    # Auto generate a password
    echo "- auto generate new password..."
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
    echo "- use auto generated password (${DEFAULT_PASSWORD}) for users"
    DEFAULT_PASSWORD=$s
    echo "- save generated password for users to ${DEFAULT_USERS_PWD_FILE}"
    echo ${DEFAULT_PASSWORD}>$DEFAULT_USERS_PWD_FILE
  fi
else
  echo "- use predefined password (\${DEFAULT_PASSWORD}=${DEFAULT_PASSWORD}) for users"
  echo ${DEFAULT_PASSWORD}>$DEFAULT_USERS_PWD_FILE
fi

for user in "${COMMON_USERS[@]}"; do
  echo -n "- reset Password for ${user} "
  ${OUD_INSTANCE_HOME}/OUD/bin/ldappasswordmodify \
    --hostname ${HOST} \
    --port $PORT_ADMIN --trustAll --useSSL \
    -D "${DIRMAN}" -j $PWD_FILE \
    --authzID "${user}" --newPassword ${DEFAULT_PASSWORD} 2>&1 >/dev/null
  if [ $? -eq 0 ]; then
    echo "OK"
  else
    echo "NOK"
  fi
done
# - EOF ------------------------------------------------------------------------
