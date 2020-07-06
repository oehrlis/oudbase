#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 07_create_eusadmin_users.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.07.01
# Revision...: --
# Purpose....: Script to create EUS Context Admin according to MOS Note 1996363.1.
# Notes......: --
# Reference..: https://github.com/oehrlis/oudbase
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at https://oss.oracle.com/licenses/upl.
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - load instance environment -------------------------------------------
. "$(dirname $0)/00_init_environment"
export EUSADMIN_USERS_PWD_FILE=${EUSADMIN_USERS_PWD_FILE:-"${INSTANCE_INIT}/etc/${OUD_INSTANCE}_${EUS_USER_NAME}_pwd.txt"}
export EUSADMIN_USERS_DN_FILE=${EUSADMIN_USERS_DN_FILE:-"${INSTANCE_INIT}/etc/${OUD_INSTANCE}_${EUS_USER_NAME}_dn.txt"}

# - configure instance --------------------------------------------------
echo "Create EUS Admin user for OUD instance ${OUD_INSTANCE} using:"
echo "  BASEDN                  : ${BASEDN}"
echo "  EUS_USER_NAME           : ${EUS_USER_NAME}"
echo "  EUS_USER_DN             : ${EUS_USER_DN}"
echo "  EUSADMIN_USERS_PWD_FILE : ${EUSADMIN_USERS_PWD_FILE}"
echo "  EUSADMIN_USERS_DN_FILE  : ${EUSADMIN_USERS_DN_FILE}"

# reuse existing password file
echo ${EUS_USER_DN} >${EUSADMIN_USERS_DN_FILE}
if [ -f "$EUSADMIN_USERS_PWD_FILE" ]; then
    echo "    found password file $EUSADMIN_USERS_PWD_FILE"
    export ADMIN_PASSWORD=$(cat $EUSADMIN_USERS_PWD_FILE)
fi

# generate a password
if [ -z ${ADMIN_PASSWORD} ]; then
# Auto generate a password
    echo "- auto generate new password..."
    while true; do
        s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 10 | head -n 1)
        if [[ ${#s} -ge 8 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]*  ]]; then
            echo "- passwort does Match the criteria"
            break
        else
            echo "- password does not Match the criteria, re-generating..."
        fi
    done
    echo "- use auto generated password for user ${EUS_USER_NAME}"
    ADMIN_PASSWORD=$s
    echo "- save password for ${EUS_USER_NAME} in ${EUSADMIN_USERS_PWD_FILE}"
    echo ${ADMIN_PASSWORD}>$EUSADMIN_USERS_PWD_FILE
else
    echo "- use predefined password for user ${EUS_USER_NAME} from ${EUSADMIN_USERS_PWD_FILE}"
fi

# create EUS Admin User
echo "- create EUS admin user ${EUS_USER_DN}"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
  --hostname ${HOST} \
  --port $PORT \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" <<LDIF
dn: ${EUS_USER_DN}
changetype: add
objectclass: inetorgperson
cn: ${EUS_USER_NAME}
sn: ${EUS_USER_NAME}
uid: ${EUS_USER_NAME}
userpassword: $s
ds-privilege-name: password-reset
ds-pwp-password-policy-dn: cn=EUS Password Policy,cn=Password Policies,cn=config

dn: ou=role_eus_admins,ou=groups,ou=local,${BASEDN}
changetype: modify
add: uniquemember
uniquemember: ${EUS_USER_DN}
LDIF

# Reset EUS Admin User password to make sure it has a AES passwort entry
echo "- Reset Password for cn=eusadmin to generate AES password entry"
${OUD_INSTANCE_HOME}/OUD/bin/ldappasswordmodify \
    --hostname ${HOST} \
    -D "${DIRMAN}" -j $PWD_FILE \
    --port $PORT_ADMIN --trustAll --useSSL \
    --authzID "${EUS_USER_DN}" \
    --currentPasswordFile $EUSADMIN_USERS_PWD_FILE --newPasswordFile $EUSADMIN_USERS_PWD_FILE 

echo "- Config EUS users"
${OUD_INSTANCE_HOME}/OUD/bin/dsconfig set-access-control-handler-prop \
    --add global-aci:\(targetattr=\"*\"\)\ \(version\ 3.0\;\ acl\ \"Allow\ OracleContextAdmins\"\;\ allow\ \(all\)\ groupdn=\"ldap:///cn=OracleContextAdmins,cn=Groups,cn=OracleContext,dc=trivadislabs,dc=com\"\;\) \
    --hostname ${HOST} \
    --port ${PORT_ADMIN} \
    --bindDN "${DIRMAN}" \
    --bindPasswordFile "${PWD_FILE}" \
    --no-prompt \
    --verbose \
    --trustAll

${OUD_INSTANCE_HOME}/OUD/bin/dsconfig set-access-control-handler-prop \
    --add global-aci:\(targetcontrol=\"1.2.840.113556.1.4.805\"\)\ \(version\ 3.0\;\ acl\ \"EUS\ Administrator\ SubTree\ delete\ control\ access\"\;\ allow\(read\)\ groupdn=\"ldap:///cn=OracleContextAdmins,cn=Groups,cn=OracleContext,dc=trivadislabs,dc=com\"\;\) \
    --hostname ${HOST} \
    --port ${PORT_ADMIN} \
    --bindDN "${DIRMAN}" \
    --bindPasswordFile "${PWD_FILE}" \
    --no-prompt \
    --verbose \
    --trustAll
# - EOF -----------------------------------------------------------------
