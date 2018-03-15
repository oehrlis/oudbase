#!/bin/bash
# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: oud_export.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Bash Script to export all running OUD Instances
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
VERSION=1.0
DOAPPEND="TRUE"                                     # enable log file append
VERBOSE="FALSE"                                     # enable verbose mode
SCRIPT_NAME=$(basename $0)
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
MAILADDRESS=oud@oradba.ch
ERROR=0
# - End of Default Values ---------------------------------------------------
 
# - Functions ---------------------------------------------------------------
# ---------------------------------------------------------------------------
# Purpose....: Display Usage
# ---------------------------------------------------------------------------
function Usage() {
    VERBOSE="TRUE"
    DoMsg "INFO : Usage, ${SCRIPT_NAME} [-hv -i <OUD_INSTANCES> -m <MAILADDRESSES>]"
    DoMsg "INFO :   -h                 Usage (this message"
    DoMsg "INFO :   -v                 enable verbose mode"
    DoMsg "INFO :   -i <OUD_INSTANCES> List of OUD instances"
    DoMsg "INFO :   -m <MAILADDRESSES> List of Mail Addresses"
    DoMsg "INFO :   -D <BINDDN>        Bind DN used for the export (default: cn=Directory Manager)"
    DoMsg "INFO :   -j <PWDFILE>       Password file used for the export (default: \$PWD_FILE)"
    DoMsg "INFO :   -f <EXPORTPATH>    Directory used to store the exports (default: \$OUD_EXPORT_DIR)"
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
function DoMsg() {
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
function CleanAndQuit() {
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
        30) DoMsg "ERR  : Exit Code ${1}. Some Export failed";;
        43) DoMsg "ERR  : Exit Code ${1}. Missing bind password file";;
        44) DoMsg "ERR  : Exit Code ${1}. Can not create directory ${2}";;
        45) DoMsg "ERR  : Exit Code ${1}. Directory ${2} is not writeable";;
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
 
# - EOF Initialization --------------------------------------------------------
 
# - Main ----------------------------------------------------------------------
DoMsg "${START_HEADER}"
 
# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvm:i:E:D:j:f: arg; do
    case $arg in
        h) Usage 0;;
        v) VERBOSE="TRUE";;
        i) MyOUD_INSTANCES="${OPTARG}";;
        m) MAILADDRESS=$(echo "${OPTARG}"|sed s/\,/\ /g);;
        D) MybindDN="${OPTARG}";;
        j) MybindPasswordFile="${OPTARG}";;
        f) MyExportPath="${OPTARG}";;
        E) CleanAndQuit "${OPTARG}";;
        ?) Usage 2 $*;;
    esac
done
 
# Set the default Bind DN to cn=Directory Manager if not specified
MybindDN=${MybindDN:-"cn=Directory Manager"}
 
# Check if the provided password file does exits
if [[ -n "${MybindPasswordFile}" ]] && [[ ! -f "${MybindPasswordFile}" ]]; then
    CleanAndQuit 43 ${MyOUD_INSTANCE}
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
        DoMsg "ERROR: [$oud_inst] Can not source environment for ${oud_inst}. Skip backup for this instance"
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
            mkdir -p ${OUD_EXPORT_DIR} >/dev/null 2>&1 || CleanAndQuit 44 ${OUD_EXPORT_DIR}
        elif [ ! -w "${OUD_EXPORT_DIR}" ]; then
            CleanAndQuit 45 ${OUD_EXPORT_DIR}
        fi
 
        # define a instance export log file and clear it
        INST_LOG_FILE="${OUD_EXPORT_DIR}/$(basename ${SCRIPT_NAME} .sh)_${oud_inst}.log"
        >${INST_LOG_FILE}
 
        DoMsg "INFO : [$oud_inst] get backends for $oud_inst"
        # get backends
        for backend_string in $(list-backends|grep -i userRoot|cut -d: -f1,2|tr -d '[[:blank:]]'); do
            backend=$(echo ${backend_string}|cut -d: -f1)
            includeBranch=" --includeBranch $(echo ${backend_string}|cut -d: -f2|sed s'/\",\"/ --includeBranch /'g|sed s'/\"//'g)"
            DoMsg "INFO : [$oud_inst] start export for $oud_inst backendID ${backend}"
            DoMsg "INFO : [$oud_inst] export log file ${INST_LOG_FILE}"
 
            EXPORT_COMMAND="${OUD_BIN}/export-ldif --hostname localhost --port $PORT_ADMIN --trustAll --bindPasswordFile ${MybindPasswordFile} --backendID ${backend} ${includeBranch} --ldifFile ${OUD_EXPORT_DIR}/export_${oud_inst}_${backend}_Day$(date '+%u').ldif"
            DoMsg "INFO : [$oud_inst] ${EXPORT_COMMAND}"
            echo -e "\n${EXPORT_COMMAND}" >>${INST_LOG_FILE}
            ${EXPORT_COMMAND} >>${INST_LOG_FILE} 2>&1
            OUD_ERROR=$?
            DoMsg "INFO : [$oud_inst] cat export log ${INST_LOG_FILE}"
            DoMsg "$(cat ${INST_LOG_FILE})"
            # handle export errors
            if [ $OUD_ERROR -lt 0 ]; then
                DoMsg "WARN : [$oud_inst] Export for $oud_inst backendID ${backend} failed with error ${OUD_ERROR}"
                cat ${INST_LOG_FILE}|mailx -s "ERROR:Export OUD Instance ${OUD_INSTANCE}" ${MAILADDRESS}
                export ERROR=$((ERROR+1))
            else
                DoMsg "INFO : [$oud_inst] Export for $oud_inst backendID ${backend} successfully finished"
            fi
        done
    else
        DoMsg "INFO : [$oud_inst] OUD Instance $oud_inst down, no export will be performed."
    fi
done
 
if [ $ERROR -lt 0 ]; then
    DoMsg "WARN : send e-Mail due to error "
    tail -400 ${LOGFILE} |mailx -s "ERROR: OUD Script ${SCRIPT_NAME}" ${MAILADDRESS}
else
    CleanAndQuit 0
fi
 
# - EOF -----------------------------------------------------------------------