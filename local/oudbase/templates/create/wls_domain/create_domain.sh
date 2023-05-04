#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: create_domain.sh
# Author.....: Patrick Joss (jpa) patrick.joss@trivadis.com
# Editor.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Date.......: 2023.05.04
# Version....: v3.4.8
# Purpose....: Script to create an empty weblogic domain 
#              with template Basic WebLogic Server Domain  
# Notes......: 
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

ORACLE_BASE=${ORACLE_BASE:-"/u00/app/oracle"}
DOMAIN_NAME=${DOMAIN_NAME:-"BaseDomain"}
DOMAIN_HOME=${DOMAIN_HOME:-"${ORACLE_BASE}/user_projects/domains/BaseDomain"}
WLS_HOME=${WLS_HOME:-"${ORACLE_BASE}/product/middleware/wls12214"}
JAVA_HOME=${JAVA_HOME:-"${ORACLE_BASE}/product/jdk1.8.0_271"}
WLS_ADMIN=${WLS_ADMIN:-"weblogic"}
PWD_FILE=${PWD_FILE:-"./pwd.txt"}
MACHINE_NAME=${MACHINE_NAME:-"localhost"}
LISTEN_PORT=${LISTEN_PORT:-7001}
NM_PORT=${NM_PORT:-5556}

# - create weblogic domwin -----------------------------------------------------
echo "Create weblogic domain ${DOMAIN_NAME} using:"
echo "DOMAIN_HOME       : ${DOMAIN_HOME}"
echo "WLS_HOME          : ${WLS_HOME}"
echo "JAVA_HOME         : ${JAVA_HOME}"
echo "WLS_ADMIN         : ${WLS_ADMIN}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "MACHINE_NAME      : ${MACHINE_NAME}"
echo "LISTEN_PORT       : ${LISTEN_PORT}"
echo "NM_PORT           : ${NM_PORT}"


WLS_PASSWORD=$(cat ${PWD_FILE})
CREATE_SCRIPT_PY=/tmp/create_domain_$$.py


sed -e '
s@###DOMAIN_NAME###@${DOMAIN_NAME}@g
s@###DOMAIN_HOME###@${DOMAIN_HOME}@g
s@###WLS_HOME###@${WLS_HOME}@g
s@###JAVA_HOME###@${JAVA_HOME}@g
s@###WLS_ADMIN###@${WLS_ADMIN}@g
s@###WLS_PASSWORD###@${WLS_PASSWORD}@g
s@###NM_PORT###@${NM_PORT}@g
s@###MACHINE_NAME###@${MACHINE_NAME}@g
s@###LISTEN_PORT###@${LISTEN_PORT}@g
' create_domain.py.template > ${CREATE_SCRIPT_PY}

${WLS_HOME}/oracle_common/common/bin/wlst.sh ${CREATE_SCRIPT_PY}

rm -f ${CREATE_SCRIPT_PY}
