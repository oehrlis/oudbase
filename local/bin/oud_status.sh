#!/bin/bash
# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: oud_status.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Bash Script to get the instance status as retun code
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# ---------------------------------------------------------------------------
# Rev History:
# 01.09.2016   soe  Initial version
# 12.11.2017   soe  Adjust to latest verson of oudenv.sh
# ---------------------------------------------------------------------------
# - Customization -----------------------------------------------------------
export OUD_ROOT_DN=${OUD_ROOT_DN:-"postgasse.org"}
# - End of Customization ----------------------------------------------------

# - Default Values ----------------------------------------------------------
VERSION=1.0
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="FALSE"                                        # enable verbose mode
SCRIPT_NAME=$(basename $0)
TMP_DIRECTORY="/tmp"
TMP_FILE="${TMP_DIRECTORY}/$(basename $0).$$"
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
MAILADDRESS=oud@oradba.ch
ERROR=0

# - End of Default Values ---------------------------------------------------

# - Functions ---------------------------------------------------------------
# ---------------------------------------------------------------------------
function Usage() {
# Purpose....: Display Usage
# ---------------------------------------------------------------------------
    VERBOSE="TRUE"
    DoMsg "INFO : Usage, ${SCRIPT_NAME} [-hvr -i <OUD_INSTANCE> -D <bindDN> -j <bindPasswordFile> ]"
    DoMsg "INFO :   -h                    Usage (this message"
    DoMsg "INFO :   -v                    enable verbose mode"
    DoMsg "INFO :   -r                    check for replication"
    DoMsg "INFO :   -D <bindDN>           Default value: cn=Directory Manager"
    DoMsg "INFO :   -j <bindPasswordFile> Bind password file"
    DoMsg "INFO :   -i <OUD_INSTANCE>     OUD Instance"
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
function CleanAndQuit() { 
# Purpose....: Clean up before exit
# ---------------------------------------------------------------------------
    if [ ${1} -gt 0 ]; then
        VERBOSE="TRUE"
    fi
    case ${1} in
        0)  DoMsg "END  : of ${SCRIPT_NAME}";;
        1)  DoMsg "ERR  : Exit Code ${1}. Wrong amount of arguments. See usage for correct one.";;
        2)  DoMsg "ERR  : Exit Code ${1}. Wrong arguments (${2}). See usage for correct one.";;
        5)  DoMsg "ERR  : Exit Code ${1}. OUD Instance ${2} does not exits in ${OUDTAB} or ${ORACLE_INSTANCE_BASE}";;
        10) DoMsg "ERR  : Exit Code ${1}. OUD_BASE not set or $OUD_BASE not available.";;
        11) DoMsg "ERR  : Exit Code ${1}. Could not touch file ${2}";;
        21) DoMsg "ERR  : Exit Code ${1}. Could not load \${HOME}/.OUD_BASE";;
        30) DoMsg "ERR  : Exit Code ${1}. Some Export failed";;
        40) DoMsg "ERR  : Exit Code ${1}. Error not defined";;
        41) DoMsg "ERR  : Exit Code ${1}. Error ${2} running status command";;
        42) DoMsg "ERR  : Exit Code ${1}. Error ${2} running dsreplication command";;
        43) DoMsg "ERR  : Exit Code ${1}. Missing bind password file";;
        50) DoMsg "ERR  : Exit Code ${1}. OUD Instance ${2} not running";;
        51) DoMsg "ERR  : Exit Code ${1}. Connection Handler ${2} is not enabled on ${OUD_INSTANCE}";;
        52) DoMsg "ERR  : Exit Code ${1}. Error in Replication for OUD Instance ${OUD_INSTANCE}. Check replication log ${ORACLE_INSTANCE_BASE}/${OUD_INSTANCE}/OUD/logs for more information";;
        99) DoMsg "INFO : Just wanna say hallo.";;
        ?)  DoMsg "ERR  : Exit Code ${1}. Unknown Error.";;
    esac
    if [ -e ${TMP_FILE} ]; then
        DoMsg "INFO : Remove temp file ${TMP_FILE}"
        rm ${TMP_FILE} 2>/dev/null
    fi
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

# Load OUD environment
. $(find $OUD_BASE -name oudenv.sh) ${OUD_INSTANCE} SILENT

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
#trap "CleanAndQuit 40" ERR

DoMsg "${START_HEADER}"
if [ $# -lt 1 ]; then
    DoMsg "INFO : Use current OUD instance"
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvi:D:j:E:r arg; do
    case $arg in
        h) Usage 0;;
        v) VERBOSE="TRUE";;
        i) MyOUD_INSTANCE="${OPTARG}";;
        D) MybindDN="${OPTARG}";;
        j) MybindPasswordFile="${OPTARG}";;
        r) REPLICATION="TRUE";;
        E) CleanAndQuit "${OPTARG}";;
        ?) Usage 2 $*;;
    esac
done

if [ "${MyOUD_INSTANCE}" == "" ]; then
    MyOUD_INSTANCE=${OUD_INSTANCE}
fi

# set OUD Instance
. "${OUD_BASE}/local/bin/oudenv.sh" $MyOUD_INSTANCE SILENT > /dev/null 2>&1
OUD_ERROR=$?
# handle errors from oudenv
if [ ${OUD_ERROR} -gt 0 ]; then
    CleanAndQuit 5 ${MyOUD_INSTANCE}    
fi

touch ${TMP_FILE} 2>/dev/null
if [ $? -eq 0 ] && [ -w "${TMP_FILE}" ]; then
    DoMsg "INFO : Touch temp file ${TMP_FILE}"
else
    CleanAndQuit 11 ${TMP_FILE} # Define a clean exit
fi

# Check if we have a bindPasswordFile
MybindDN=${MybindDN:-"cn=Directory Manager"}
MybindPasswordFile=${MybindPasswordFile:-"${PWD_FILE}"}
if [ ! -f "${MybindPasswordFile}" ]; then
    CleanAndQuit 43 ${MyOUD_INSTANCE}
fi  

DoMsg "INFO : Run status on OUD Instance ${MyOUD_INSTANCE}"
status --script-friendly --no-prompt --noPropertiesFile --bindDN "${MybindDN}" --bindPasswordFile ${MybindPasswordFile} --trustAll >${TMP_FILE} 2>&1
OUD_ERROR=$?
# handle errors from OUD status
if [ ${OUD_ERROR} -gt 0 ]; then
    CleanAndQuit 41 ${OUD_ERROR}
fi

# adjust temp file 
# and add a - at the end
sed -i 's/^$/-/' ${TMP_FILE}
# join Backend ID with multiple lines
sed -i '/OracleContext for$/{N;s/\n/ /;}' ${TMP_FILE}
# join Base DN with multiple lines
sed -i '/^Base DN:$/{N;s/\n/                      /;}' ${TMP_FILE}

DoMsg "INFO : Process ${TMP_FILE} file"
# check Server Run Status
if [ $(grep -ic 'Server Run Status: Started' ${TMP_FILE}) -eq 0 ]; then
    cat ${TMP_FILE} >> ${LOGFILE}
    CleanAndQuit 50 ${OUD_INSTANCE}
fi

# check if connection handler are enabled
for i in LDAP LDAPS; do
    DoMsg "INFO : Check connection handler ${i}"
    AWK_OUT=$(awk 'BEGIN{RS="\n-\n";FS="\n";IGNORECASE=1; Error=51} $1 ~ /^Address/ && $2 ~ /\<'${i}'\>/ {if ($3 ~ /\<Enabled\>/) Error=0; } END{exit Error}' ${TMP_FILE} )
    OUD_ERROR=$?
    if [ ${OUD_ERROR} -eq 51 ]; then
        cat ${TMP_FILE} >> ${LOGFILE}
        CleanAndQuit 51 ${i}
    fi
done

if [ "${REPLICATION}" = "TRUE" ]; then
    i="Replication"
    DoMsg "INFO : Check connection handler ${i}"
    AWK_OUT=$(awk 'BEGIN{RS="\n-\n";FS="\n";IGNORECASE=1; Error=51} $1 ~ /^Address/ && $2 ~ /\<'${i}'\>/ {if ($3 ~ /\<Enabled\>/) Error=0; } END{exit Error}' ${TMP_FILE} )
    OUD_ERROR=$?
    if [ ${OUD_ERROR} -eq 51 ]; then
        cat ${TMP_FILE} >> ${LOGFILE}
        CleanAndQuit 51 ${i}
    fi
    
    # check if there are errors in replications
    DoMsg "INFO : Run dsreplication status on OUD Instance ${MyOUD_INSTANCE}"
    dsreplication status --no-prompt --noPropertiesFile --port $PORT_ADMIN --trustAll --bindDN "${MybindDN}" --adminPasswordFile ${MybindPasswordFile} >${TMP_FILE} 2>&1
    OUD_ERROR=$?
    # handle errors from OUD dsreplication
    if [ ${OUD_ERROR} -gt 0 ]; then
        cat ${TMP_FILE} >> ${LOGFILE}
        CleanAndQuit 42 ${OUD_ERROR}
    fi

    CAT_OUT=$(cat ${TMP_FILE}|awk 'BEGIN{FS=":";Error=0} /${OUD_ROOT_DN}/ {if ($7 !~/\<Normal\>/ ) Error=52; } END{exit Error}' )
    OUD_ERROR=$?
    if [ ${OUD_ERROR} -eq 52 ]; then
        CleanAndQuit 52 ${i}
    fi
fi

CleanAndQuit 0
# - EOF ---------------------------------------------------------------------