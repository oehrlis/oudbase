#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: oud_start_stop.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: Bash Script to start/stop OUD Instances 
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------
# - Customization -------------------------------------------------------
 
# - End of Customization ------------------------------------------------
 
# - Default Values ------------------------------------------------------
VERSION=v1.5.7
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="FALSE"                                 # enable verbose mode
SCRIPT_NAME=$(basename $0)
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
HOST=$(hostname 2>/dev/null ||cat /etc/hostname ||echo $HOSTNAME)  # Hostname
# - End of Default Values -----------------------------------------------
 
# - Functions -----------------------------------------------------------
# -----------------------------------------------------------------------
# Purpose....: Display Usage
# -----------------------------------------------------------------------
function Usage() {
    VERBOSE="TRUE"
    DoMsg "INFO : Usage, ${SCRIPT_NAME} [-hv -a <START|STOP> -i <OUD_INSTANCES>] [<START|STOP> <OUD_INSTANCES>]"
    DoMsg "INFO :   -h                 Usage (this message"
    DoMsg "INFO :   -v                 enable verbose mode"
    DoMsg "INFO :   -a <start|stop>    Activity either start or stop"
    DoMsg "INFO :   -i <OUD_INSTANCES> List of OUD instances (default all market with Y in oudtab)"
    DoMsg "INFO : Logfile : ${LOGFILE}"
    if [ ${1} -gt 0 ]; then
        CleanAndQuit ${1} ${2}
    else
        VERBOSE="FALSE"
        CleanAndQuit 0
    fi
}
 
# -----------------------------------------------------------------------
# Purpose....: Display Message with time stamp
# -----------------------------------------------------------------------
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
 
# -----------------------------------------------------------------------
# Purpose....: Clean up before exit
# -----------------------------------------------------------------------
function CleanAndQuit() {
    STATUS="INFO"
    if [ ${1} -gt 0 ]; then
      VERBOSE="TRUE"
      STATUS="ERROR"
    fi

    case ${1} in
        0)  DoMsg "END  : of ${SCRIPT_NAME}";;
        1)  DoMsg "ERR  : Exit Code ${1}. Wrong amount of arguments. See usage for correct one.";;
        2)  DoMsg "ERR  : Exit Code ${1}. Wrong arguments (${2}). See usage for correct one.";;
        10) DoMsg "ERR  : Exit Code ${1}. OUD_BASE not set or $OUD_BASE not available.";;
        11) DoMsg "ERR  : Exit Code ${1}. Could not touch file ${2}";;
        21) DoMsg "ERR  : Exit Code ${1}. Could not load \${HOME}/.OUD_BASE";;
        30) DoMsg "ERR  : Exit Code ${1}. Some backups failed";;
        31) DoMsg "ERR  : Exit Code ${1}. Some exports failed";;
        43) DoMsg "ERR  : Exit Code ${1}. Missing bind password file";;
        44) DoMsg "ERR  : Exit Code ${1}. Can not create directory ${2}";;
        45) DoMsg "ERR  : Exit Code ${1}. Directory ${2} is not writeable";;
        50) DoMsg "ERR  : Exit Code ${1}. Error while performing exports";;
        51) DoMsg "ERR  : Exit Code ${1}. Error while performing backups";;
        52) DoMsg "ERR  : Exit Code ${1}. Error unknown activity ${2}";;
        99) DoMsg "INFO : Just wanna say hallo.";;
        ?)  DoMsg "ERR  : Exit Code ${1}. Unknown Error.";;
    esac
    exit ${1}
}
# - EOF Functions -------------------------------------------------------
 
# - Initialization ------------------------------------------------------
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
 
# - EOF Initialization --------------------------------------------------
 
# - Main ----------------------------------------------------------------
DoMsg "${START_HEADER}"
 
# get pointer / linenumber from logfile with the latest header line
LOG_START=$(($(grep -ni "${START_HEADER}" "${LOGFILE}"|cut -d: -f1 |tail -1)-1))
 
if [ $# -eq 0 ]; then
   Usage 2
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hva:i:E: arg; do
    case $arg in
        h) Usage 0;;
        v) VERBOSE="TRUE";;
        a) MyActivity="${OPTARG}";;
        i) MyOUD_INSTANCES=$(echo "${OPTARG}"|sed s/\,/\ /g);;
        E) CleanAndQuit "${OPTARG}";;
        ?) Usage 2 $*;;
    esac
done

# get none getopt parameters
shift $((OPTIND-1))
Arguments=$@

if [ $# -ne 0 ]; then
#if [ ! -z "$@" ]; then
    DoMsg "INFO : Fallback to legacy parameter"
    MyActivity=$(echo $@|cut -d' ' -f1)
    shift  
    MyOUD_INSTANCES=$@
fi

# Normalize activity
MyActivity=${MyActivity:-"START"}
MyActivity=$(echo $MyActivity|sed "s/^start$/START/gi")
MyActivity=$(echo $MyActivity|sed "s/^stop$/STOP/gi")

if [ "$MyOUD_INSTANCES" = "" ]; then
    # Load list of OUD Instances from oudtab
    DoMsg "INFO : Load list of OUD instances"
    if [ -f "${ETC_BASE}/oudtab" ]; then
        # create a OUD Instance Liste based on oudtab
        export OUDTAB=${ETC_BASE}/oudtab
        if [ "$MyActivity" == "START" ]; then
            export OUD_INST_LIST=$(grep -v '^#' ${OUDTAB}|grep -iEv ':(N|D)$'|cut -f1 -d:)
        else
            export OUD_INST_LIST=$(grep -v '^#' ${OUDTAB}|cut -f1 -d:)
        fi
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
DoMsg "INFO : Initiate $MyActivity for instances ${OUD_INST_LIST}"
 
# Loop over OUD Instances
for oud_inst in ${OUD_INST_LIST}; do
    # Load OUD environment
    . "${OUDENV}" $oud_inst SILENT >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        DoMsg "ERROR: [$oud_inst] Can not source environment for ${oud_inst}. Skip export for this instance"
        ERROR=$((ERROR+1))
        continue
    fi
    if [ ! -d "$OUD_INSTANCE_HOME" ]; then
        DoMsg "ERROR: Instance home for ${oud_inst} does not exists. Skip start/stop for this instance"
        continue
    fi
    INSTANCE_LOGFILE="${LOG_BASE}/$(basename ${SCRIPT_NAME} .sh)_${oud_inst}.log"
    if [ "$MyActivity" == "START" ]; then
        # check directory type
        if [ ${DIRECTORY_TYPE} == "OUD" ]; then
            DoMsg "INFO : Initiate $MyActivity for ${DIRECTORY_TYPE} instance ${oud_inst}"
            $OUD_INSTANCE_HOME/OUD/bin/start-ds >> ${INSTANCE_LOGFILE} 2>&1 
        elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
            DoMsg "INFO : Initiate $MyActivity for ${DIRECTORY_TYPE} instance ${oud_inst}"
            $OUD_INSTANCE_HOME/startWebLogic.sh >> ${INSTANCE_LOGFILE} 2>&1 &
        else
            DoMsg "WARN : [$oud_inst] Instance $oud_inst is not of type OUD/OUDSM. Skip $MyActivity for this instance."
        fi 
   elif  [ "$MyActivity" == "STOP" ]; then 
          if [ ${DIRECTORY_TYPE} == "OUD" ]; then
            DoMsg "INFO : Initiate $MyActivity for ${DIRECTORY_TYPE} instance ${oud_inst}"
            $OUD_INSTANCE_HOME/OUD/bin/stop-ds >> ${INSTANCE_LOGFILE} 2>&1 
        elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
            DoMsg "INFO : Initiate $MyActivity for ${DIRECTORY_TYPE} instance ${oud_inst}"
            $OUD_INSTANCE_HOME/bin/stopWebLogic.sh >> ${INSTANCE_LOGFILE} 2>&1 &
        else
            DoMsg "WARN : [$oud_inst] Instance $oud_inst is not of type OUD/OUDSM. Skip $MyActivity for this instance."
        fi
   else
    CleanAndQuit 52 $MyActivity
   fi
done
 
if [ "${ERROR}" -gt 0 ]; then
    CleanAndQuit 51
else
    CleanAndQuit 0
fi
# - EOF -----------------------------------------------------------------
