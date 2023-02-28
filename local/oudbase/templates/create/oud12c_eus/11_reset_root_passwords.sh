#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 11_reset_root_passwords.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.02.28
# Version....: v2.12.0
# Usage......: 11_reset_root_passwords.sh
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
echo "- get root user from directory ------------------------------------------------------"
ROOT_USERS=($(${OUD_INSTANCE_HOME}/OUD/bin/ldapsearch --hostname ${HOST} --port $PORT_ADMIN --trustAll --useSSL -D "${DIRMAN}" -j $PWD_FILE -b "cn=config" "(&(objectClass=ds-cfg-root-dn-user)("'!'"(${DIRMAN})))" cn|grep -i 'cn:'|sed 's/cn: //i'))

# - configure instance ---------------------------------------------------------
echo "- reset admin user password for OUD instance ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "ROOT_USER         : ${ROOT_USERS[@]}"

for user in "${ROOT_USERS[@]}"; do
  echo "- Start to process root user $user --------------------------------------------------"
  # reuse existing password file
  ROOT_USER_NAME=${user// /_}  # define the workflow name without spaces
  ROOT_USER_NAME=${ROOT_USER_NAME,,}
  ROOT_USERS_PWD_FILE=${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_${ROOT_USER_NAME}_pwd.txt
  if [ -f "$ROOT_USERS_PWD_FILE" ]; then
    echo "- found password file $ROOT_USERS_PWD_FILE"
    export ADMIN_PASSWORD=$(cat $ROOT_USERS_PWD_FILE)
  fi

  # generate a password
  if [ -z ${ADMIN_PASSWORD} ]; then
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
    echo "- use auto generated password for user ${user}"
    ADMIN_PASSWORD=$s
    echo "- save password for ${user} in ${ROOT_USERS_PWD_FILE}"
    echo ${ADMIN_PASSWORD}>$ROOT_USERS_PWD_FILE
  else
    echo "- use predefined password for user ${user} from ${ROOT_USERS_PWD_FILE}"
  fi

  echo -n "- reset Password for cn=${user},cn=Root DNs,cn=config "
  ${OUD_INSTANCE_HOME}/OUD/bin/ldappasswordmodify \
    --hostname ${HOST} \
    --port $PORT_ADMIN --trustAll --useSSL \
    -D "${DIRMAN}" -j $PWD_FILE \
    --authzID "cn=${user},cn=Root DNs,cn=config" --newPassword ${ADMIN_PASSWORD} 2>&1 >/dev/null
  if [ $? -eq 0 ]; then
    echo "OK"
  else
    echo "NOK"
  fi
  unset ADMIN_PASSWORD
done
# - EOF ------------------------------------------------------------------------
