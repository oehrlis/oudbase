#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 07_create_eusadmin_users.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.06.30
# Version....: v3.6.1
# Purpose....: Script to create EUS Context Admin according to MOS Note 1996363.1.
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
export EUSADMIN_USERS_PWD_FILE=${EUSADMIN_USERS_PWD_FILE:-"${OUD_INSTANCE_ADMIN}/etc/${EUS_USER_NAME}_pwd.txt"}
export EUS_USER_NAME=${EUS_USER_NAME:-"eusadmin"}
export EUS_USER_DN=${EUS_USER_DN:-"cn=${EUS_USER_NAME},cn=oraclecontext"}

# - configure instance ---------------------------------------------------------
echo "Create EUS Admin user for OUD instance ${OUD_INSTANCE} using:"
echo "  HOSTNAME                : ${HOST}"
echo "  PORT_SSL                : ${PORT_SSL}"
echo "  PORT_ADMIN              : ${PORT_ADMIN}"
echo "  DIRMAN                  : ${DIRMAN}"
echo "  PWD_FILE                : ${PWD_FILE}"
echo "  BASEDN                  : ${BASEDN}"
echo "  EUS_USER_NAME           : ${EUS_USER_NAME}"
echo "  EUS_USER_DN             : ${EUS_USER_DN}"
echo "  EUSADMIN_USERS_PWD_FILE : ${EUSADMIN_USERS_PWD_FILE}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${PWD_FILE}" ]      && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]      && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${HOST}" ]          && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PORT}" ]          && echo "- skip $(basename $0), variable PORT not set"              && exit
[   -z "${PORT_ADMIN}" ]    && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${DIRMAN}" ]        && echo "- skip $(basename $0), variable DIRMAN not set"            && exit
[   -z "${EUS_USER_DN}" ]   && echo "- skip $(basename $0), variable EUS_USER_DN not set"       && exit
[   -z "${EUS_USER_NAME}" ] && echo "- skip $(basename $0), variable EUS_USER_NAME not set"     && exit
[   -z "${BASEDN}" ]        && echo "- skip $(basename $0), variable BASEDN not set"            && exit

# reuse existing password file
if [ -f "$EUSADMIN_USERS_PWD_FILE" ]; then
    echo "- found eus admin password file ${EUSADMIN_USERS_PWD_FILE}"
    export ADMIN_PASSWORD=$(cat ${EUSADMIN_USERS_PWD_FILE})
# use default password from variable
elif [ -n "${DEFAULT_PASSWORD}" ]; then
    echo "- use default user password from \${DEFAULT_PASSWORD} for user ${EUS_USER_NAME}"
    echo ${DEFAULT_PASSWORD}> ${EUSADMIN_USERS_PWD_FILE}
    export ADMIN_PASSWORD=$(cat $EUSADMIN_USERS_PWD_FILE)
# still here, then lets create a password
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
    echo "- use auto generated password for user ${EUS_USER_NAME}"
    ADMIN_PASSWORD=$s
    echo "- save password for ${EUS_USER_NAME} in ${EUSADMIN_USERS_PWD_FILE}"
    echo ${ADMIN_PASSWORD}>$EUSADMIN_USERS_PWD_FILE
fi

# create EUS Admin User
echo "- create EUS admin user ${EUS_USER_DN}"
${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
    --hostname ${HOST} \
    --port ${PORT_SSL} \
    --useSSL \
    --trustAll \
    --bindDN "${DIRMAN}" \
    --bindPasswordFile "${PWD_FILE}" <<LDIF
dn: ${EUS_USER_DN}
changetype: add
objectclass: inetorgperson
cn: ${EUS_USER_NAME}
sn: ${EUS_USER_NAME}
uid: ${EUS_USER_NAME}
ds-privilege-name: password-reset
ds-pwp-password-policy-dn: cn=EUS Password Policy,cn=Password Policies,cn=config
userpassword: ${ADMIN_PASSWORD}

DN: cn=OracleDBSecurityAdmins,cn=OracleContext
changetype: modify
add: uniquemember
uniquemember: ${EUS_USER_DN}

dn: cn=OracleContextAdmins,cn=groups,cn=OracleContext,${BASEDN}
changetype: modify
add: uniquemember
uniquemember: ${EUS_USER_DN}
LDIF

# check if we do have role_eus_admins
ROLE_DN=$(ldapsearch -h ${HOST} -p ${PORT_SSL} --useSSL --trustAll -D "${DIRMAN}" -j ${PWD_FILE} -b ${BASEDN} -s sub "(ou=role_eus_admins)" dn 2>/dev/null)
if [ -n "$ROLE_DN" ]; then 
    echo "- add EUS admin user ${EUS_USER_DN} to ${ROLE_DN}"
    ${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
        --hostname ${HOST} \
        --port ${PORT_SSL} \
        --useSSL \
        --trustAll \
        --bindDN "${DIRMAN}" \
        --bindPasswordFile "${PWD_FILE}" <<LDIF
dn: ou=role_eus_admins,ou=groups,ou=local,${BASEDN}
changetype: modify
add: uniquemember
uniquemember: ${EUS_USER_DN}
LDIF
fi

# Reset EUS Admin User password to make sure it has a AES passwort entry
echo "- Reset Password for ${EUS_USER_DN} to generate AES password entry"
${OUD_INSTANCE_HOME}/OUD/bin/ldappasswordmodify \
    --hostname ${HOST} \
    -D "${DIRMAN}" -j $PWD_FILE \
    --port $PORT_ADMIN --trustAll --useSSL \
    --authzID "${EUS_USER_DN}" \
    --newPasswordFile $EUSADMIN_USERS_PWD_FILE 

# check if we do have an AES hash
echo "- review password attribute for ${EUS_USER_DN}"
${OUD_INSTANCE_HOME}/OUD/bin/ldapsearch \
    --hostname ${HOST} \
    --port ${PORT_SSL} \
    --useSSL \
    --trustAll \
    --bindDN "${DIRMAN}" \
    --bindPasswordFile "${PWD_FILE}" \
    --baseDN "cn=OracleContext" "(cn=${EUS_USER_NAME})" uid userpassword

echo "- Config ACI for Context Admin"
${OUD_INSTANCE_HOME}/OUD/bin/dsconfig set-access-control-handler-prop \
    --add global-aci:\(targetattr=\"*\"\)\ \(version\ 3.0\;\ acl\ \"Allow\ OracleContextAdmins\"\;\ allow\ \(all\)\ groupdn=\"ldap:///cn=OracleContextAdmins,cn=Groups,cn=OracleContext,${BASEDN}\"\;\) \
    --hostname ${HOST} \
    --port ${PORT_ADMIN} \
    --bindDN "${DIRMAN}" \
    --bindPasswordFile "${PWD_FILE}" \
    --no-prompt \
    --verbose \
    --trustAll

${OUD_INSTANCE_HOME}/OUD/bin/dsconfig set-access-control-handler-prop \
    --add global-aci:\(targetcontrol=\"1.2.840.113556.1.4.805\"\)\ \(version\ 3.0\;\ acl\ \"EUS\ Administrator\ SubTree\ delete\ control\ access\"\;\ allow\(read\)\ groupdn=\"ldap:///cn=OracleContextAdmins,cn=Groups,cn=OracleContext,${BASEDN}\"\;\) \
    --hostname ${HOST} \
    --port ${PORT_ADMIN} \
    --bindDN "${DIRMAN}" \
    --bindPasswordFile "${PWD_FILE}" \
    --no-prompt \
    --verbose \
    --trustAll
# - EOF ------------------------------------------------------------------------
