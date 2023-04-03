#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_scripts.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.04.03
# Version....: v3.4.4
# Purpose....: Script to test / verify all TNS utilities
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------
# - just add/update any kind of customized environment variable here

# - End of Customization -------------------------------------------------------

# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o nounset                      # exit if script try to use an uninitialised variable
# set -o errexit                      # exit script if any statement returns a non-true return value
# set -o pipefail                     # pipefail exit after 1st piped commands failed
set -o noglob                       # Disable filename expansion (globbing).
# - Environment Variables ------------------------------------------------------
# define generic environment variables
VERSION=v3.4.4
ORACLE_BASE=${ORACLE_BASE:-"/u01/app/oracle"}
TVDLDAP_BIN_DIR=$(dirname $(find ${ORACLE_BASE} -name tns_add.sh 2>/dev/null|head -1))
# - EOF Environment Variables --------------------------------------------------

# - Functions ------------------------------------------------------------------
# - EOF Functions --------------------------------------------------------------

# - Initialization -------------------------------------------------------------
. ${TVDLDAP_BIN_DIR}/tns_functions.sh
source_env
SUFFIXES=${SUFFIXES:-$(get_all_basedn)}
SUFFIX=${SUFFIX:-$(get_local_basedn|cut -d' ' -f1|sed -e 's/,dc=/\./g' -e 's/^dc=//')}
# - EOF Initialization ---------------------------------------------------------
 
# - Main -----------------------------------------------------------------------
echo "SUFFIX            : ${SUFFIX}"
echo "SUFFIXES          : ${SUFFIXES}"
echo "ORACLE_BASE       : ${ORACLE_BASE}"
echo "TVDLDAP_BIN_DIR   : ${TVDLDAP_BIN_DIR}"
for i in $SUFFIXES; do
    echo "add $i"
    echo "${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY0 -b $i -N <Net String>"
    ${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY0 -b "$i" -N "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.1.1.12)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=TDB02.trivadislabs.com)))"
done
echo "${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY.${SUFFIX} -N <Net String>"
${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY.${SUFFIX} -N "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.1.1.12)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=TDB02.trivadislabs.com)))"

echo "${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY.${SUFFIX} -N <Net String>"
${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY.${SUFFIX} -N "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.1.1.12)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=TDB02.trivadislabs.com)))"

echo "${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY.${SUFFIX} -N <Net String> -F"
${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY.${SUFFIX} -N "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.1.1.12)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=TDB02.trivadislabs.com)))" -F

echo "${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY2 -b ALL -N <Net String> -F"
${TVDLDAP_BIN_DIR}/tns_add.sh -S DUMMY2 -b ALL -N "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.1.1.12)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=TDB02.trivadislabs.com)))" -F

echo "${TVDLDAP_BIN_DIR}/tns_modify.sh -S DUMMY1.${SUFFIX} -N <Net String>"
${TVDLDAP_BIN_DIR}/tns_modify.sh -S DUMMY1.${SUFFIX} -N "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.1.1.12)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=TDB02.trivadislabs.com)))"

echo "${TVDLDAP_BIN_DIR}/tns_modify.sh -S DUMMY1.${SUFFIX} -N <Net String> -F"
${TVDLDAP_BIN_DIR}/tns_modify.sh -S DUMMY1.${SUFFIX} -N "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.1.1.12)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=TDB02.trivadislabs.com)))" -F

echo "${TVDLDAP_BIN_DIR}/tns_search.sh -S DUMMY* -b ${SUFFIX}"
${TVDLDAP_BIN_DIR}/tns_search.sh -S DUMMY* -b ${SUFFIX}

echo "${TVDLDAP_BIN_DIR}/tns_dump.sh -S DUMMY* -b all -o /tmp/tns_delete_dump.${SUFFIX}.ora -F"
${TVDLDAP_BIN_DIR}/tns_dump.sh -S DUMMY* -b all -o /tmp/tns_delete_dump.${SUFFIX}.ora -F

echo "${TVDLDAP_BIN_DIR}/tns_delete.sh -S DUMMY* -b ${SUFFIX} -B"
${TVDLDAP_BIN_DIR}/tns_delete.sh -S DUMMY* -b ${SUFFIX} -B

echo "${TVDLDAP_BIN_DIR}/tns_load.sh -t /tmp/tns_delete_dump.${SUFFIX}.ora -F"
${TVDLDAP_BIN_DIR}/tns_load.sh -t /tmp/tns_delete_dump.${SUFFIX}.ora -F

echo "${TVDLDAP_BIN_DIR}/tns_test.sh -S DUMMY* -b all"
${TVDLDAP_BIN_DIR}/tns_test.sh -S DUMMY* -b all

echo "${TVDLDAP_BIN_DIR}/tns_delete.sh -S DUMMY* -b all -B"
${TVDLDAP_BIN_DIR}/tns_delete.sh -S DUMMY* -b all -B
rm /tmp/tns_delete_dump.${SUFFIX}.ora
# --- EOF ----------------------------------------------------------------------