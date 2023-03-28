#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 01_create_instance.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.28
# Version....: v3.0.4
# Purpose....: Script to create the OUD instance with EUS context 
#              using oud-setup.
# Notes......: Will skip oud-proxy-setup if config.ldif already exists
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"

# - create instance ------------------------------------------------------------
echo "Create OUD instance ${OUD_INSTANCE} using:"
echo "OUD_INSTANCE_HOME : ${OUD_INSTANCE_HOME}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "HOSTNAME          : ${HOST}"
echo "PORT              : ${PORT}"
echo "PORT_SSL          : ${PORT_SSL}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "PORT_REST_ADMIN   : ${PORT_REST_ADMIN}"
echo "PORT_REST_HTTP    : ${PORT_REST_HTTP}"
echo "PORT_REST_HTTPS   : ${PORT_REST_HTTPS}"
echo "DIRMAN            : ${DIRMAN}"
echo "BASEDN            : ${BASEDN}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[   -z "${OUD_INSTANCE_HOME}" ] && echo "- skip $(basename $0), variable OUD_INSTANCE_HOME not set" && exit
[   -z "${PWD_FILE}" ]          && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f "${PWD_FILE}" ]          && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[   -z "${HOST}" ]              && echo "- skip $(basename $0), variable HOST not set"              && exit
[   -z "${PORT}" ]              && echo "- skip $(basename $0), variable PORT not set"              && exit
[   -z "${PORT_SSL}" ]          && echo "- skip $(basename $0), variable PORT_SSL not set"          && exit
[   -z "${PORT_ADMIN}" ]        && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[   -z "${PORT_REST_ADMIN}" ]   && echo "- skip $(basename $0), variable PORT_REST_ADMIN not set"   && exit
[   -z "${PORT_REST_HTTP}" ]    && echo "- skip $(basename $0), variable PORT_REST_HTTP not set"    && exit
[   -z "${PORT_REST_HTTPS}" ]   && echo "- skip $(basename $0), variable PORT_REST_HTTPS not set"   && exit
[   -z "${DIRMAN}" ]            && echo "- skip $(basename $0), variable DIRMAN not set"            && exit
[   -z "${BASEDN}" ]            && echo "- skip $(basename $0), variable BASEDN not set"            && exit

# check if we do have a password file
if [ ! -f "${PWD_FILE}" ]; then
    # check if we do have a default admin password
    if [ -z "${DEFAULT_ADMIN_PASSWORD}" ]; then
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
        echo "- use auto generated password for ${DIRMAN}"
        echo "- save password for ${DIRMAN} in ${PWD_FILE}"
        echo $s>${PWD_FILE}
    else
        echo ${DEFAULT_ADMIN_PASSWORD}>${PWD_FILE}
        echo "- use predefined admin password for user from variable \${DEFAULT_ADMIN_PASSWORD}"
    fi
else
    echo "- use predefined password for user from file ${PWD_FILE}"
fi

# check if OUD instance config does not yet exists
if [ ! -f "${OUD_INSTANCE_HOME}/OUD/config/config.ldif" ]; then
    echo "INFO: Create OUD instance ${OUD_INSTANCE}"
    ${ORACLE_HOME}/oud/oud-setup \
        --cli \
        --instancePath "${OUD_INSTANCE_HOME}/OUD" \
        --rootUserDN "${DIRMAN}" \
        --rootUserPasswordFile "${PWD_FILE}" \
        --adminConnectorPort ${PORT_ADMIN} \
        --httpAdminConnectorPort ${PORT_REST_ADMIN} \
        --hostname ${HOST} \
        --ldapPort ${PORT} \
        --ldapsPort ${PORT_SSL} \
        --httpPort ${PORT_REST_HTTP} \
        --httpsPort ${PORT_REST_HTTPS} \
        --generateSelfSignedCertificate \
        --enableStartTLS \
        --baseDN "${BASEDN}" \
        --integration generic \
        --serverTuning jvm-default \
        --offlineToolsTuning autotune \
        --no-prompt
else
    echo "WARN: did found an instance configuration file"
    echo "      ${OUD_INSTANCE_HOME}/OUD/config/config.ldif"
    echo "      skip create instance ${OUD_INSTANCE}"
fi

# - EOF ------------------------------------------------------------------------