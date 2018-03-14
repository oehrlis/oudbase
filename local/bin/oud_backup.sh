#!/bin/bash
# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: oud_backup.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Bash Script to backup all running OUD Instances
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes/updates
# ---------------------------------------------------------------------------
# - Customization -----------------------------------------------------------

# - End of Customization ----------------------------------------------------

# - Default Values ----------------------------------------------------------
VERSION=0.1
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="FALSE"                                        # enable verbose mode
SCRIPT_NAME=$(basename $0)
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
MAILADDRESS=oud@oradba.ch
ERROR=0
TYPE="FULL"                                            # Default Backup Type
KEEP=4                                                 # Number of Weeks to keep
compress="--compress"                                  # set --compress Flag
# - End of Default Values ---------------------------------------------------

# - Functions ---------------------------------------------------------------
# ---------------------------------------------------------------------------
# Purpose....: Display Usage
# ---------------------------------------------------------------------------
function Usage() {
    VERBOSE="TRUE"
    DoMsg "INFO : Usage, ${SCRIPT_NAME} [-hv -i <OUD_INSTANCES> -t <TYPE> -m <MAILADDRESSES>]"
    DoMsg "INFO :   -h                 Usage (this message"
    DoMsg "INFO :   -v                 enable verbose mode"
    DoMsg "INFO :   -i <OUD_INSTANCES> List of OUD instances (default ALL)"
    DoMsg "INFO :   -t <TYPE>          Backup Type FULL or INCREMENTAL (default FULL)"
    DoMsg "INFO :   -k <WEEKS>         Number of weeks to keep old backups (default 4)"
    DoMsg "INFO :   -m <MAILADDRESSES> List of Mail Addresses"
    DoMsg "INFO : Logfile : ${LOGFILE}"
    if [ ${1} -gt 0 ]; then
        CleanAndQuit ${1} ${2}
    else
        VERBOSE="FALSE"
        CleanAndQuit 0 
    fi
}

# ---------------------------------------------------------------------------
# Purpose....: Display Message with time stamp
# ---------------------------------------------------------------------------
function DoMsg()
{
    INPUT=${1%:*}                         # Take everything behinde
    case ${INPUT} in                    # Define a nice time stamp for ERR, END
        "END ")  TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S");;
        "ERR ")  TIME_STAMP=$(date "+%n%Y-%m-%d_%H:%M:%S");;
        "START") TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S");;
        "OK")    TIME_STAMP="";;
        "*")     TIME_STAMP="....................";;
    esac
    if [ "${VERBOSE}" = "TRUE" ]; then
        if [ "${DOAPPEND}" = "TRUE" ]; then
            echo "${TIME_STAMP}  ${1}" |tee -a ${LOGFILE}
        else
            echo "${TIME_STAMP}  ${1}"
        fi
        shift
        while [ "${1}" != "" ]; do
            if [ "${DOAPPEND}" = "TRUE" ]; then
                echo "               ${1}" |tee -a ${LOGFILE}
            else
                echo "               ${1}"
            fi
            shift
        done
    else
        if [ "${DOAPPEND}" = "TRUE" ]; then
            echo "${TIME_STAMP}  ${1}" >> ${LOGFILE}
        fi
        shift
        while [ "${1}" != "" ]; do
            if [ "${DOAPPEND}" = "TRUE" ]; then
                echo "               ${1}" >> ${LOGFILE}
            fi
            shift
        done
    fi
}

# ---------------------------------------------------------------------------
# Purpose....: Clean up before exit
# ---------------------------------------------------------------------------
function CleanAndQuit(){ 
    if [ ${1} -gt 0 ]; then
        VERBOSE="TRUE"
    fi
    case ${1} in
        0)  DoMsg "END  : of ${SCRIPT_NAME}";;
        1)  DoMsg "ERR  : Exit Code ${1}. Wrong amount of arguments. See usage for correct one.";;
        2)  DoMsg "ERR  : Exit Code ${1}. Wrong arguments (${2}). See usage for correct one.";;
        10) DoMsg "ERR  : Exit Code ${1}. OUD_BASE not set or $OUD_BASE not available.";;
        11) DoMsg "ERR  : Exit Code ${1}. Could not touch file ${2}";;
        21) DoMsg "ERR  : Exit Code ${1}. Could not load \${HOME}/.OUD_BASE";;
        30) DoMsg "ERR  : Exit Code ${1}. Some Backup failed";;
        99) DoMsg "INFO : Just wanna say hallo.";;
        ?)  DoMsg "ERR  : Exit Code ${1}. Unknown Error.";;
    esac
    exit ${1}
}
# - EOF Functions -----------------------------------------------------------

# - Initialization ----------------------------------------------------------
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

# - EOF Initialization ------------------------------------------------------

# - Main --------------------------------------------------------------------
DoMsg "${START_HEADER}"
if [ $# -lt 1 ]; then
    Usage 1 
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvt:k:i:m:E: arg; do
    case $arg in
        h) Usage 0;;
        v) VERBOSE="TRUE";;
        t) TYPE="${OPTARG}";;
        k) KEEP="${OPTARG}";;
        i) MyOUD_INSTANCES="${OPTARG}";;
        m) MAILADDRESS=$(echo "${OPTARG}"|sed s/\,/\ /g);;
        E) CleanAndQuit "${OPTARG}";;
        ?) Usage 2 $*;;
    esac
done

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
DoMsg "INFO : Initiate backup for OUD instances ${OUD_INST_LIST}"

# define backup type
if [ "${TYPE}" = "INCREMENTAL" ]; then
    incremental="--incremental"
else
    incremental=""
fi

# define backup set as modulo 5 of week number
NEW_WEEKNO=$(date "+%U")
OLD_WEEKNO=$((${NEW_WEEKNO}-${KEEP}))
NEW_BACKUP_SET="backup_set$(( ${NEW_WEEKNO} % (${KEEP}+1)))"
OLD_BACKUP_SET="backup_set$(( ${OLD_WEEKNO} % (${KEEP}+1)))"
DoMsg "INFO : Define backup set for week ${NEW_WEEKNO} as ${NEW_BACKUP_SET}"
DoMsg "INFO : Define backup set to be purged for week ${OLD_WEEKNO} as ${OLD_BACKUP_SET}"

# Loop over OUD Instances
for oud_inst in ${OUD_INST_LIST}; do
    # Load OUD environment
    . "${OUDENV}" $oud_inst SILENT 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
        DoMsg "ERROR: [$oud_inst] Can not source environment for ${oud_inst}. Skip backup for this instance"
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
        INST_LOG_FILE="/tmp/$(basename ${SCRIPT_NAME} .sh)_${oud_inst}.log"
        DoMsg "INFO : [$oud_inst] OUD Instance $oud_inst up."
        
        # create directory for a dedicated backup set
        mkdir -p ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}
        DoMsg "INFO : [$oud_inst] start backup for $oud_inst for Week ${NEW_WEEKNO}"
        BACKUP_COMMAND="${OUD_BIN}/backup -a ${compress} ${incremental} -d ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}"
        DoMsg "INFO : [$oud_inst] ${BACKUP_COMMAND}"
        ${BACKUP_COMMAND} >${INST_LOG_FILE} 2>&1       
        OUD_ERROR=$? 
        
        # Backup the Config directory
        DoMsg "INFO : [$oud_inst] backup config directory"
        tar -Pzcf ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}/${oud_inst}_config.tgz $OUD_CONF >>${INST_LOG_FILE} 2>&1  
        
        # Backup the current log files
        DoMsg "INFO : [$oud_inst] backup current log files"
        tar -Pzcf ${OUD_BACKUP_DIR}/${NEW_BACKUP_SET}/${oud_inst}_logs.tgz \
            $OUD_LOG/access $OUD_LOG/admin $OUD_LOG/audit $OUD_LOG/errors \
            $OUD_LOG/replication $OUD_LOG/server.out $OUD_LOG/server.pid >>${INST_LOG_FILE} 2>&1
        
        # handle backup errors
        if [ $OUD_ERROR -lt 0 ]; then
            DoMsg "WARN : [$oud_inst] Backup for $oud_inst failed with error ${OUD_ERROR}"
            cat ${INST_LOG_FILE}|mailx -s "ERROR:Backup OUD Instance ${OUD_INSTANCE}" ${MAILADDRESS}
            export ERROR=$((ERROR+1))
        else
            DoMsg "INFO : [$oud_inst] Backup for $oud_inst successfully finished"
            
            # Automaticaly purge backup's older than KEEP weeks
            if [ -d ${OUD_BACKUP_DIR}/${OLD_BACKUP_SET} ]; then
                DoMsg "INFO : [$oud_inst] Remove old backup set ${OUD_BACKUP_DIR}/${OLD_BACKUP_SET} of week ${OLD_WEEKNO}"
                rm -rf ${OUD_BACKUP_DIR}/${OLD_BACKUP_SET}
            else
                DoMsg "INFO : [$oud_inst] No old backup found (eg. ${OLD_BACKUP_SET} week ${OLD_WEEKNO})"
            fi
        fi
    else 
        DoMsg "WARN : [$oud_inst] OUD Instance $oud_inst down, no backup will be performed." 
    fi
done

if [ $ERROR -lt 0 ]; then
    DoMsg "WARN : send e-Mail due to error "
    tail -400 ${LOGFILE} |mailx -s "ERROR: OUD Script ${SCRIPT_NAME}" ${MAILADDRESS}     
else 
    CleanAndQuit 0
fi

# - EOF ---------------------------------------------------------------------