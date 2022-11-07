#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 05_add_suffix.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.10.24
# Version....: v2.8.0
# Usage......: 05_add_suffix.sh
# Purpose....: Simple script to add the different NET suffixes
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
LDIFFILE="$(dirname $0)/$(basename $0 .sh).ldif"      # LDIF file based on script name
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf"    # config file based on script name

# - create instance ------------------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "PORT_SSL          : ${PORT_SSL}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "ALL_SUFFIX        : ${ALL_SUFFIX}"
echo "LDIFFILE          : ${LDIFFILE}"

# check if we have other NET suffix defined
if [ ! -n "${ALL_SUFFIX}" ]; then
  echo "NO additional NET suffix defined. Skip this script..."
  exit
fi

# - add suffix -----------------------------------------------------------------
for suffix in ${ALL_SUFFIX}; do
  environment=$(echo $suffix|cut -d, -f1|sed 's/dc=//i')
  workflow_element="local_net_${environment}_DB"
  NET_LDIFFILE="$(dirname ${LDIFFILE})/$(basename ${LDIFFILE} .ldif)_${environment}.ldif"
  echo "suffix      : $suffix"
  echo "environment : $environment"
  echo "workflow    : $workflow_element"
  echo "LDIF        : ${NET_LDIFFILE}"

  # prepare LDIF file for OU
  cp -v ${LDIFFILE} ${NET_LDIFFILE}
  echo "Update ldif file ${NET_LDIFFILE} to match $suffix" 
  sed -i "s/BASEDN/${suffix}/g" ${NET_LDIFFILE}
  sed -i "s/ROOTDN/${BASEDN}/g" ${NET_LDIFFILE}
  sed -i "s/USER_OU/${USER_OU}/g" ${NET_LDIFFILE}
  sed -i "s/GROUP_OU/${GROUP_OU}/g" ${NET_LDIFFILE}
  sed -i "s/LOCAL_OU/${LOCAL_OU}/g" ${NET_LDIFFILE}
  
  echo "add NET suffix (${suffix}) to OUD instance ${OUD_INSTANCE_NAME}"
  ${OUD_INSTANCE_HOME}/OUD/bin/manage-suffix create \
    --baseDN ${suffix} \
    --verbose \
    --integration generic \
    --hostname ${HOST} \
    --networkGroup network-group \
    --workflowElement ${workflow_element} \
    --port ${PORT_ADMIN} \
    --bindDN "${DIRMAN}" \
    --bindPasswordFile "${PWD_FILE}" \
    --trustAll \
    --no-prompt

  echo "Configure NET suffix ${suffix}"
  ${OUD_INSTANCE_HOME}/OUD/bin/ldapmodify \
    --hostname "${HOST}" \
    --port "${PORT_SSL}" \
    --bindDN "${DIRMAN}" \
    --bindPasswordFile "${PWD_FILE}" \
    --useSSL \
    --trustAll \
    --defaultAdd \
    --filename "${NET_LDIFFILE}"
done
# - EOF ------------------------------------------------------------------------
