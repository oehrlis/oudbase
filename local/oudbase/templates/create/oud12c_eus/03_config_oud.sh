#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: 03_config_oud.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.28
# Version....: v3.0.3
# Purpose....: Script to configure the OUD proxy instance.
# Notes......: The config file 03_config_oud_proxy.conf is executed using
#              dsconfig in batch mode. If required, each command can 
#              also be executed individually.
#
#              dsconfig -h ${HOSTNAME} -p $PORT_ADMIN \
#                  -D "cn=Directory Manager"-j $PWD_FILE -X -n \
#                  <COMMAND>
#
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - load instance environment --------------------------------------------------
. "$(dirname $0)/00_init_environment"
CONFIGFILE="$(dirname $0)/$(basename $0 .sh).conf"      # config file based on script name
# - configure instance ---------------------------------------------------------
echo "Configure OUD instance ${OUD_INSTANCE} using:"
echo "  HOSTNAME          : ${HOST}"
echo "  PORT_ADMIN        : ${PORT_ADMIN}"
echo "  DIRMAN            : ${DIRMAN}"
echo "  PWD_FILE          : ${PWD_FILE}"
echo "  BASEDN            : ${BASEDN}"
echo "  BASEDN_STRING     : ${BASEDN_STRING}"
echo "  CONFIGFILE        : ${CONFIGFILE}"
echo ""

# - check prerequisites --------------------------------------------------------
# check mandatory variables
[ -z ${PWD_FILE} ]          && echo "- skip $(basename $0), variable PWD_FILE not set"          && exit
[ ! -f ${PWD_FILE} ]          && echo "- skip $(basename $0), missing password file ${PWD_FILE}"  && exit
[ -z ${HOST} ]              && echo "- skip $(basename $0), variable HOST not set"              && exit
[ -z ${PORT_ADMIN} ]        && echo "- skip $(basename $0), variable PORT_ADMIN not set"        && exit
[ -z ${DIRMAN} ]            && echo "- skip $(basename $0), variable DIRMAN not set"            && exit
[ -z ${BASEDN} ]            && echo "- skip $(basename $0), variable BASEDN not set"            && exit

echo "  Config OUD Proxy Instance"
${OUD_INSTANCE_HOME}/OUD/bin/dsconfig \
  --hostname ${HOST} \
  --port ${PORT_ADMIN} \
  --bindDN "${DIRMAN}" \
  --bindPasswordFile "${PWD_FILE}" \
  --no-prompt \
  --verbose \
  --trustAll \
  --batchFilePath "${CONFIGFILE}"
# - EOF ------------------------------------------------------------------------
