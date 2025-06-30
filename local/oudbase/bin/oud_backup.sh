#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oud_backup.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.06.30
# Version....: v3.6.1
# Purpose....: Bash Script to backup all running OUD Instances
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
VERSION=v3.6.1
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="FALSE"                                 # enable verbose mode
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
MAILADDRESS=""
SEND_MAIL="FALSE"                               # don't send mails by default
ERROR=0
TYPE="FULL"                                     # Default Backup Type
KEEP=4                                          # Default number of Weeks to keep
compress="--compress"                           # set --compress Flag
OUD_ERROR=0                                     # default value for error
export OUD_BASE=${OUD_BASE:-""}
export HOME=${HOME:-~}
# Define a bunch of bash option see
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o nounset                      # exit if script try to use an uninitialised variable
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
    DoMsg "Usage, ${SCRIPT_NAME} [-hv -i <OUD_INSTANCES> -t <TYPE> -m <MAILADDRESSES>]"
    DoMsg "    -h                 Usage (this message"
    DoMsg "    -v                 enable verbose mode"
    DoMsg "    -i <OUD_INSTANCES> List of OUD instances (default ALL)"
    DoMsg "    -t <TYPE>          Backup Type FULL, INCREMENTAL or just CONFIG (default FULL)"
    DoMsg "    -k <WEEKS>         Number of weeks to keep old backups (default 4)"
    DoMsg "    -o                 force to send mails. Requires -m <MAILADDRESSES>"
    DoMsg "    -L                 Backup current instance log files (default: no logfile backup)"
    DoMsg "    -m <MAILADDRESSES> List of Mail Addresses"
    DoMsg "    -f <BACKUPPATH>    Directory used to store the backups (default: \$OUD_BACKUP_DIR)"
    DoMsg "    Logfile : ${LOGFILE}"
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
while getopts hvt:k:oLi:m:f:E: arg; do
    case $arg in
        h) Usage 0;;
        v) VERBOSE="TRUE";;
        t) TYPE="${OPTARG}";;
        k) KEEP="${OPTARG}";;
        o) SEND_MAIL="TRUE";;
        L) BACKUP_LOGS="TRUE";;
        i) MyOUD_INSTANCES="${OPTARG}";;
        m) MAILADDRESS=$(echo "${OPTARG}"|sed s/\,/\ /g);;
        f) MyBackupPath="${OPTARG}";;
        E) CleanAndQuit "${OPTARG}";;
        ?) Usage 2 $*;;
    esac
done

# explisitly define a couple of default variable
MyBackupPath=${MyBackupPath:-""}
MyOUD_INSTANCES=${MyOUD_INSTANCES:-""}
BACKUP_LOGS=${MyOUD_INSTANCES:-"FALSE"}
# log info in case we do send e-mails
if [ "${SEND_MAIL}" = "TRUE" ] && [ -z "${MAILADDRESS}" ]; then
    DoMsg "WARN : SEND_MAIL is TRUE, but can not send e-Mail. No address specified."
fi
 
# Set a minimal value for KEEP to 1 eg. 1 week
if [ ${KEEP} -lt 1 ]; then
    KEEP=1
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

# check if we do have a list of OUD instances to backup
if [ -z "${OUD_INST_LIST// /}" ]; then
    DoMsg "WARN : No OUD instance defined/found"
    CleanAndQuit 54
else
    DoMsg "INFO : Initiate backup for OUD instances ${OUD_INST_LIST}"
fi
 
# define backup type incremental
if [ "${TYPE^^}" = "INCREMENTAL" ]; then
    incremental="--incremental"
else
    incremental=""
fi
 
# set the default value for keep if not defined
KEEP=${KEEP:-4}
# define backup set as modulo 5 of week number
NEW_WEEKNO=$(date "+%U"|sed "s/^0*//g")
OLD_WEEKNO=$((${NEW_WEEKNO}-${KEEP}))
NEW_BACKUP_SET="backup_set$(( ${NEW_WEEKNO} % (${KEEP}+1)))"
OLD_BACKUP_SET="backup_set$(( ${OLD_WEEKNO} % (${KEEP}+1)))"
# set default value for NEW_BACKUP_SET
NEW_BACKUP_SET=${NEW_BACKUP_SET:-"backup_set0"}

DoMsg "INFO : Define backup set for week ${NEW_WEEKNO} as ${NEW_BACKUP_SET}"
DoMsg "INFO : Define backup set to be purged for week ${OLD_WEEKNO} as ${OLD_BACKUP_SET}"
 
# Loop over OUD Instances
for oud_inst in ${OUD_INST_LIST}; do
    # Load OUD environment
    . "${OUDENV}" $oud_inst SILENT 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
        DoMsg "ERROR: [$oud_inst] Can not source environment for ${oud_inst}. Skip backup for this instance"
        ERROR=$((ERROR+1))
        continue
    fi
 
    # check directory type
    if [ ! ${DIRECTORY_TYPE} == "OUD" ]; then
        DoMsg "WARN : [$oud_inst] Instance $oud_inst is not of type OUD. Skip backup for this instance."
        continue
    fi

    DoMsg "INFO : [$oud_inst] Check if $oud_inst is running"
    STATUS=$(get_status $oud_inst)
    if [ "${STATUS^^}" == "UP" ]; then
        DoMsg "INFO : [$oud_inst] OUD Instance $oud_inst up."
 
        # set the export path to MyExportPath or fallback to the default $OUD_EXPORT_DIR
        OUD_BACKUP_DIR=${MyBackupPath:-"${OUD_BACKUP_DIR}"}
        # check and create directory
        if [ ! -d "${OUD_BACKUP_DIR}" ]; then
            mkdir -p ${OUD_BACKUP_DIR} >/dev/null 2>&1 || CleanAndQuit 12 ${OUD_BACKUP_DIR}
        elif [ ! -w "${OUD_BACKUP_DIR}" ]; then
            CleanAndQuit 13 ${OUD_BACKUP_DIR}
        fi
 
        # define a instance backup log file
        INST_LOG_FILE="${OUD_BACKUP_DIR}/$(basename ${SCRIPT_NAME} .sh)_${oud_inst}.log"
 
        # create directory for a dedicated backup set
        if [ ! -d ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET} ]; then
            mkdir -p ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET} >/dev/null 2>&1 || CleanAndQuit 12 ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}
            echo "CREATED:$(date "+%Y.%m.%d-%H%M%S");TYPE:${TYPE^^};STATUS:unknown" >${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}/.backup_set.log
        else 
            echo "MODIFIED:$(date "+%Y.%m.%d-%H%M%S");TYPE:${TYPE^^};STATUS:unknown" >>${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}/.backup_set.log
        fi  

        DoMsg "INFO : [$oud_inst] start backup for $oud_inst for Week ${NEW_WEEKNO}"
        DoMsg "INFO : [$oud_inst] backup log file ${INST_LOG_FILE}"
 
        # check if backup type is not config only e.g. CONFIG
        # do a regular backup only if TYPE is not CONFIG
        if [ "${TYPE^^}" != "CONFIG" ]; then
            BACKUP_COMMAND="${OUD_BIN}/backup -a ${compress} ${incremental} -d ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}"
            DoMsg "INFO : [$oud_inst] ${BACKUP_COMMAND}"
            echo -e "\n${BACKUP_COMMAND}" >${INST_LOG_FILE} 2>&1
            ${BACKUP_COMMAND} >>${INST_LOG_FILE} 2>&1
            OUD_ERROR=$?
        else
            DoMsg "INFO : [$oud_inst] Backup type set to ${TYPE^^}, skip regular OUD backups    "
        fi

        # Backup the Config directory in any case
        DoMsg "INFO : [$oud_inst] backup config directory"
        TAR_COMMAND="tar -Pzcvf ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}/${oud_inst}_config.tgz $OUD_CONF"
        echo -e "\n${TAR_COMMAND}" >>${INST_LOG_FILE} 2>&1
        ${TAR_COMMAND} >>${INST_LOG_FILE} 2>&1

        # Backup the current log files only if LOGFILE Flag is set
        if [ "${BACKUP_LOGS}" = "TRUE" ]; then
            DoMsg "INFO : [$oud_inst] backup current log files"
            TAR_COMMAND="tar -Pzcvf ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}/${oud_inst}_logs.tgz $(find $OUD_LOG -type f ! -iname '*Z')"
            echo -e "\n${TAR_COMMAND}" >>${INST_LOG_FILE} 2>&1
            ${TAR_COMMAND} >>${INST_LOG_FILE} 2>&1
        fi
        DoMsg "INFO : [$oud_inst] cat of backup log ${INST_LOG_FILE}"
        DoMsg "$(cat ${INST_LOG_FILE})"
 
        # handle backup errors
        if [ $OUD_ERROR -lt 0 ]; then
            DoMsg "WARN : [$oud_inst] Backup for $oud_inst failed with error ${OUD_ERROR}"
            # add NOK to the backup .backup_set.log
            sed -i "s/unknown/NOK/" ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}/.backup_set.log
            # in case we do have an e-mail address we send a mail
            if [ -n "${MAILADDRESS}" ]; then
                DoMsg "INFO : [$oud_inst] Send instance logfile ${INST_LOG_FILE} to ${MAILADDRESS}"
                cat ${INST_LOG_FILE}|mailx -s "ERROR: Backup OUD Instance ${OUD_INSTANCE} failed" ${MAILADDRESS}
            fi
            ERROR=$((ERROR+1))
        else
            DoMsg "INFO : [$oud_inst] Backup for $oud_inst successfully finished"
            # in case we do have an e-mail address and force mails is true we send a mail
            if  [ "${SEND_MAIL}" = "TRUE" ] && [ -n "${MAILADDRESS}" ]; then
                DoMsg "INFO : [$oud_inst] Send instance logfile ${INST_LOG_FILE} to ${MAILADDRESS}"
                cat ${INST_LOG_FILE}|mailx -s "INFO : Backup OUD Instance ${OUD_INSTANCE} successfully finished" ${MAILADDRESS}
            fi
            # add OK to the backup .backup_set.log
            sed -i "s/unknown/OK/" ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}/.backup_set.log
            # check if we do have a an old backup set defined
            if [ -z "$OLD_BACKUP_SET" ]; then
                DoMsg "WARN : [$oud_inst] old backup set not defined. Do not purge any backup."
            else
                # Automaticaly purge backup's older than KEEP weeks
                if [ -d ${OUD_BACKUP_DIR}/${OLD_BACKUP_SET} ]; then
                    DoMsg "INFO : [$oud_inst] Remove old backup set ${OUD_BACKUP_DIR}/${OLD_BACKUP_SET} of week ${OLD_WEEKNO}"
                    rm -rf ${OUD_BACKUP_DIR}/${OLD_BACKUP_SET}
                else
                    DoMsg "INFO : [$oud_inst] No old backup found (eg. ${OLD_BACKUP_SET} week ${OLD_WEEKNO})"
                fi
            fi
        fi
    else
        DoMsg "WARN : [$oud_inst] OUD Instance $oud_inst down, no backup will be performed."
        # in case we do have an e-mail address and force mails is true we send a mail
        if [ "${SEND_MAIL}" = "TRUE" ] && [ -n "${MAILADDRESS}" ]; then
            echo "Warning OUD instance $oud_inst is down, no backup will be performed." |mailx -s "WARNING : Backup OUD Instance ${OUD_INSTANCE} failed" ${MAILADDRESS}
        fi
    fi
done
 
if [ "${ERROR}" -gt 0 ]; then
    CleanAndQuit 33
else
    CleanAndQuit 0
fi
# - EOF ------------------------------------------------------------------------
