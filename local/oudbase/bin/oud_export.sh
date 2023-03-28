#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oud_export.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.28
# Version....: v3.0.1
# Purpose....: Bash Script to export all running OUD Instances
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------

# - End of Customization -------------------------------------------------------
 
# - Default Values ------------------------------------------------------
VERSION=v3.0.1
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="FALSE"                                 # enable verbose mode
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
MAILADDRESS=""
SEND_MAIL="FALSE"                               # don't send mails by default
ERROR=0
KEEP=7                                          # Number of Days to keep
COMPRESS=""                                     # set default value for compression
SUFFIX="ldif"                                   # default suffix
DATE_STRING=$(date '+%Y%m%d-%H%M%S')            # String used for the export files
HOST=$(hostname 2>/dev/null ||cat /etc/hostname ||echo $HOSTNAME)  # Hostname

# Define a bunch of bash option see
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o nounset                      # exit if script try to use an uninitialised variable
set -o errexit                      # exit script if any statement returns a non-true return value
set -o pipefail                     # pipefail exit after 1st piped commands failed
# - End of Default Values ------------------------------------------------------

# - Functions ------------------------------------------------------------------
# source common functions from oud_functions.sh
. ${SCRIPT_DIR}/oud_functions.sh

# define signal handling
trap on_term TERM SEGV      # handle TERM SEGV using function on_term
trap on_int INT             # handle INT using function on_int
# ------------------------------------------------------------------------------
# Purpose....: Display Usage
# ------------------------------------------------------------------------------
function Usage() {
    VERBOSE="TRUE"
    DoMsg "Usage, ${SCRIPT_NAME} [-hv -i <OUD_INSTANCES> -b <BACKENDS> -m <MAILADDRESSES>]"
    DoMsg "    -h                 Usage (this message"
    DoMsg "    -v                 enable verbose mode"
    DoMsg "    -i <OUD_INSTANCES> List of OUD instances (comma separated)"
    DoMsg "    -b <BACKENDS>      List of OUD instances default all (semi-comma seperated)"
    DoMsg "    -m <MAILADDRESSES> List of Mail Addresses (comma separated)"
    DoMsg "    -o                 force to send mails. Requires -m <MAILADDRESSES>"
    DoMsg "    -c                 Compress LDIF file (default no compression)"
    DoMsg "    -k <DAYS>          Number of days to keep old exports (default 7)"
    DoMsg "    -D <BINDDN>        Bind DN used for the export (default: cn=Directory Manager)"
    DoMsg "    -j <PWDFILE>       Password file used for the export (default: \$PWD_FILE)"
    DoMsg "    -f <EXPORTPATH>    Directory used to store the exports (default: \$OUD_EXPORT_DIR)"
    DoMsg "Logfile : ${LOGFILE}"
    if [ ${1} -gt 0 ]; then
        CleanAndQuit ${1} ${2}
    else
        VERBOSE="FALSE"
        CleanAndQuit 0
    fi
}
# - EOF Functions --------------------------------------------------------------
 
# - Initialization -------------------------------------------------------------
# Check OUD_BASE and load if necessary
if [ "${OUD_BASE}" = "" ]; then
    if [ -f "${HOME}/.OUD_BASE" ]; then
        . "${HOME}/.OUD_BASE"
    else
        CleanAndQuit 21
    fi
fi
 
# Check if OUD_BASE exits
if [ "${OUD_BASE}" = "" ] || [ ! -d "${OUD_BASE}" ]; then
    CleanAndQuit 10
fi
 
OUDENV=$(find $OUD_BASE -name oudenv.sh)
# Load OUD environment
. "${OUDENV}" SILENT
 
# Define Logfile
LOGFILE="${LOG_BASE}/$(basename ${SCRIPT_NAME} .sh).log"
touch ${LOGFILE} 2>/dev/null
if [ $? -eq 0 ] && [ -w "${LOGFILE}" ]; then
    DOAPPEND="TRUE"
else
    CleanAndQuit 11 ${LOGFILE} # Define a clean exit
fi
 
# - EOF Initialization ---------------------------------------------------------
 
# - Main -----------------------------------------------------------------------
DoMsg "${START_HEADER}"
# get pointer / linenumber from logfile with the latest header line
LOG_START=$(($(grep -ni "${START_HEADER}" "${LOGFILE}"|cut -d: -f1 |tail -1)-1))
 
# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvdcb:m:oi:k:E:D:j:f: arg; do
    case $arg in
        h) Usage 0;;
        v) VERBOSE="TRUE";;
        d) DEBUG="TRUE";;
        c) COMPRESS="--compress";;
        b) BACKENDS=${OPTARG};;
        i) MyOUD_INSTANCES="${OPTARG}";;
        k) KEEP="${OPTARG}";;
        m) MAILADDRESS=$(echo "${OPTARG}"|sed s/\,/\ /g);;
        o) SEND_MAIL="TRUE";;
        D) MybindDN="${OPTARG}";;
        j) MybindPasswordFile="${OPTARG}";;
        f) MyExportPath="${OPTARG}";;
        E) CleanAndQuit "${OPTARG}";;
        ?) Usage 2 $*;;
    esac
done

# explisitly define a couple of default variable
MybindPasswordFile=${MybindPasswordFile:-""}
MyExportPath=${MyExportPath:-""}
MyOUD_INSTANCES=${MyOUD_INSTANCES:-""}
BACKENDS=${BACKENDS:-""}

# Set the default Bind DN to cn=Directory Manager if not specified
MybindDN=${MybindDN:-"cn=Directory Manager"}

# change suffix 
if [ "${COMPRESS}" == "--compress" ]; then
    SUFFIX="ldif.gz"
fi

# Check if the provided password file does exits
if [[ -n "${MybindPasswordFile}" ]] && [[ ! -f "${MybindPasswordFile}" ]]; then
    CleanAndQuit 43 ${MyOUD_INSTANCE}
fi

# Set a minimal value for KEEP to 1 eg. 2 days
if [ ${KEEP} -lt 2 ]; then
KEEP=2
fi

if [ "$MyOUD_INSTANCES" = "" ]; then
    # Load list of OUD Instances from oudtab
    DoMsg "INFO : Load list of OUD instances"
    if [ -f "${ETC_BASE}/oudtab" ]; then
        # create a OUD Instance Liste based on oudtab
        export OUDTAB=${ETC_BASE}/oudtab
        export OUD_INST_LIST=$(grep -v '^#' ${OUDTAB}|cut -f1 -d:)
    else
        DoMsg "WARN : Could not load OUD list from \${ETC_BASE}/oudtab"
        DoMsg "WARN : Fallback to \${OUD_DATA}/*/OUD"
        unset OUD_INST_LIST
        for i in ${ORACLE_INSTANCE_BASE}/*/OUD; do
            # create a OUD Instance Liste based on OUD Instance Base
            OUD_INST_LIST="$(echo $i|sed 's/^.*\/\(.*\)\/OUD.*$/\1/')"
        done
    fi
else
    DoMsg "INFO : Use instance list from commandline"
    # use list of OUD Instances from command line
    OUD_INST_LIST=$(echo "${MyOUD_INSTANCES}" |tr ',' ' ')
fi
 
# remove newline in OUD_INST_LIST
OUD_INST_LIST=$(echo ${OUD_INST_LIST}|tr '\n' ' ')
DoMsg "INFO : Initiate export for OUD instances ${OUD_INST_LIST}"
 
# Loop over OUD Instances
for oud_inst in ${OUD_INST_LIST}; do
    # Load OUD environment
    . "${OUDENV}" $oud_inst SILENT >/dev/null 2>&1
     if [ $? -ne 0 ]; then
        DoMsg "ERROR: [$oud_inst] Can not source environment for ${oud_inst}. Skip export for this instance"
        ERROR=$((ERROR+1))
        continue
    fi
    # check directory type
    if [ ! ${DIRECTORY_TYPE} == "OUD" ]; then
        DoMsg "WARN : [$oud_inst] Instance $oud_inst is not of type OUD. Skip backup for this instance."
        continue
    fi
 
    # if we still in game set the password file if not yet defined to ${PWD_FILE}
    MybindPasswordFile=${MybindPasswordFile:-"${PWD_FILE}"}
 
    # Check if the provided password file does exits
    if [ ! -f "${MybindPasswordFile}" ]; then
        CleanAndQuit 43 ${MyOUD_INSTANCE}
    fi
 
    DoMsg "INFO : [$oud_inst] Check if $oud_inst is running"
    STATUS=$(get_status $oud_inst)
    if [ "${STATUS^^}" == "UP" ]; then
        DoMsg "INFO : [$oud_inst] OUD Instance $oud_inst up."
 
        # set the export path to MyExportPath or fallback to the default $OUD_EXPORT_DIR
        OUD_EXPORT_DIR=${MyExportPath:-"${OUD_EXPORT_DIR}"}
 
        # check and create directory
        if [ ! -d "${OUD_EXPORT_DIR}" ]; then
            mkdir -p ${OUD_EXPORT_DIR} >/dev/null 2>&1 || CleanAndQuit 12 ${OUD_EXPORT_DIR}
        elif [ ! -w "${OUD_EXPORT_DIR}" ]; then
            CleanAndQuit 13 ${OUD_EXPORT_DIR}
        fi
 
        # define a instance export log file and clear it
        INST_LOG_FILE="${OUD_EXPORT_DIR}/$(basename ${SCRIPT_NAME} .sh)_${oud_inst}_${DATE_STRING}.log" >${INST_LOG_FILE}

        OLDIFS=$IFS                     # save and change IFS
        if [ -n "${BACKENDS}" ]; then
            IFS=';'
            DoMsg "INFO : [$oud_inst] using backends ${BACKENDS}"
            backends=(${BACKENDS})
        else
            DoMsg "INFO : [$oud_inst] get backends for $oud_inst"
            IFS=$'\n'
            # read all backends into an array
            EXCLUDED_BACKENDS="adminRoot|ads-truststore|monitor|backup|tasks|virtualAcis"
            DoMsg "INFO : [$oud_inst] exclude backends $(echo $EXCLUDED_BACKENDS|sed 's/|/\, /g')"
            backends=($(list-backends|egrep -v "[.:]\s*$|${EXCLUDED_BACKENDS}"|tail -n +3|sed 's/"//g'))
        fi
        IFS=$OLDIFS                     # restore IFS
        tLen=${#backends[@]}            # get length of an array
        # use for loop read all filenames
        for (( i=0; i<${tLen}; i++ ));do
            backend_id=$(echo ${backends[$i]}|cut -d: -f1|sed 's/^[ \t]*//;s/[ \t]*$//')
            backend_basedn=$(echo ${backends[$i]}|cut -d: -f2|sed 's/^[ \t]*//;s/[ \t]*$//'|sed 's/ /\\ /')
            includeBranch=" --includeBranch $(echo ${backend_basedn}|cut -d: -f2|sed s'/\",\"/ --includeBranch /'g|sed s'/\"//'g)"
            DoMsg "INFO : [$oud_inst] start export backendID ${backend_id} with base DN ${backend_basedn}"
            DoMsg "INFO : [$oud_inst] export log file ${INST_LOG_FILE}"

            EXPORT_COMMAND="${OUD_BIN}/export-ldif --hostname ${HOST} --port $PORT_ADMIN --bindDN "${MybindDN}" ${COMPRESS} --trustAll --bindPasswordFile ${MybindPasswordFile} --backendID \"${backend_id}\" --ldifFile \"${OUD_EXPORT_DIR}/export_${oud_inst}_${backend_id}_${DATE_STRING}.${SUFFIX}\""
            echo -e "\n${EXPORT_COMMAND}" >>${INST_LOG_FILE}
            
            ${OUD_BIN}/export-ldif --hostname ${HOST} --port $PORT_ADMIN --bindDN "${MybindDN}" ${COMPRESS} --trustAll --bindPasswordFile ${MybindPasswordFile} --backendID "${backend_id}" --ldifFile "${OUD_EXPORT_DIR}/export_${oud_inst}_${backend_id}_${DATE_STRING}.${SUFFIX}">>${INST_LOG_FILE} 2>&1
            OUD_ERROR=$?
            DoMsg "INFO : [$oud_inst] cat lines from export log ${INST_LOG_FILE}"
            DoMsg "$(sed -n "/${backend_id}/,\$p" ${INST_LOG_FILE})"
            # handle export errors
            if [ $OUD_ERROR -gt 0 ]; then
                DoMsg "WARN : [$oud_inst] Export for $oud_inst backendID ${backend_id} failed with error ${OUD_ERROR}"
                # in case we do have an e-mail address we send a mail
                if [ -n "${MAILADDRESS}" ]; then
                    DoMsg "INFO : [$oud_inst] Send instance logfile ${INST_LOG_FILE} to ${MAILADDRESS}"
                    cat ${INST_LOG_FILE}|mailx -s "ERROR: Export OUD Instance ${OUD_INSTANCE} failed" ${MAILADDRESS}
                fi
            ERROR=$((ERROR+1))
            else
                DoMsg "INFO : [$oud_inst] Export for $oud_inst backendID ${backend_id} successfully finished"
            fi
        done

        # purge old export files
        if [ $(find ${OUD_EXPORT_DIR} -type f -mtime +${KEEP} -ls|wc -l) -lt 0 ]; then
            DoMsg "INFO : [$oud_inst] Purge exports older than ${KEEP} days"
            find ${OUD_EXPORT_DIR} -type f -mtime +${KEEP} -exec rm -v {} \;
        else
            DoMsg "INFO : [$oud_inst] No old export files found to purge (keep is set to ${KEEP} days)"
        fi
    else
        DoMsg "WARN : [$oud_inst] OUD Instance $oud_inst down, no export will be performed."
        # in case we do have an e-mail address and force mails is true we send a mail
        if [ "${SEND_MAIL}" = "TRUE" ] && [ -n "${MAILADDRESS}" ]; then
            echo "Warning OUD instance $oud_inst is down, no export will be performed." |mailx -s "WARNING : Export OUD Instance ${OUD_INSTANCE} failed" ${MAILADDRESS}
        fi
    fi
done

if [ "${ERROR}" -gt 0 ]; then
    CleanAndQuit 32
else
    CleanAndQuit 0
fi
# - EOF ------------------------------------------------------------------------
