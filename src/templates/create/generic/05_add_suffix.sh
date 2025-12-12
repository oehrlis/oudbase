#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 05_add_suffix.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.12
# Version....: v4.0.0
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
LDIFFILE="$(dirname $0)/$(basename $0 .sh).ldif"   # LDIF file based on script name
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf" # config file based on script name

# - create instance ------------------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "HOSTNAME          : ${HOST}"
echo "PORT_SSL          : ${PORT_SSL}"
echo "PORT_ADMIN        : ${PORT_ADMIN}"
echo "DIRMAN            : ${DIRMAN}"
echo "PWD_FILE          : ${PWD_FILE}"
echo "ALL_SUFFIX        : ${ALL_SUFFIX}"
echo "LDIFFILE          : ${LDIFFILE}"

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[ -z "${PWD_FILE}" ] && echo "- skip $(basename $0), variable PWD_FILE not set" && exit
[ ! -f "${PWD_FILE}" ] && echo "- skip $(basename $0), missing password file ${PWD_FILE}" && exit
[ -z "${HOST}" ] && echo "- skip $(basename $0), variable HOST not set" && exit
[ -z "${PORT_SSL}" ] && echo "- skip $(basename $0), variable PORT_SSL not set" && exit
[ -z "${PORT_ADMIN}" ] && echo "- skip $(basename $0), variable PORT_ADMIN not set" && exit
[ -z "${DIRMAN}" ] && echo "- skip $(basename $0), variable DIRMAN not set" && exit
[ -z "${LDIFFILE}" ] && echo "- skip $(basename $0), variable LDIFFILE not set" && exit
[ ! -f "${LDIFFILE}" ] && echo "- skip $(basename $0), missing file ${LDIFFILE}" && exit
[ -z "${BASEDN}" ] && echo "- skip $(basename $0), variable BASEDN not set" && exit
[ -z "${USER_OU}" ] && echo "- skip $(basename $0), variable USER_OU not set" && exit
[ -z "${GROUP_OU}" ] && echo "- skip $(basename $0), variable GROUP_OU not set" && exit
[ -z "${LOCAL_OU}" ] && echo "- skip $(basename $0), variable LOCAL_OU not set" && exit

# check if we have other NET suffix defined
if [ ! -n "${ALL_SUFFIX}" ]; then
	echo "NO additional NET suffix defined. Skip this script..."
	exit
fi

# - add suffix -----------------------------------------------------------------
for suffix in ${ALL_SUFFIX}; do
	environment=$(echo $suffix | cut -d, -f1 | sed 's/dc=//i')
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
