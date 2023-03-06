#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oud_start_stop.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.06
# Version....: v2.12.7
# Purpose....: Bash Script to start/stop OUD Instances 
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:-------
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------

# - End of Customization -------------------------------------------------------
 
# - Default Values ------------------------------------------------------
VERSION=v2.12.7
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="FALSE"                                 # enable verbose mode
FORCE="FALSE"                                   # enable force restart
TIMEOUT=60                                      # default timeout in seconds
WAIT_ITER=60                                    # default wait iternation
WAIT="FALSE"                                    # default wait mode
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
HOST=$(hostname 2>/dev/null ||cat /etc/hostname ||echo $HOSTNAME)  # Hostname
# - End of Default Values ------------------------------------------------------
 
# - Functions ------------------------------------------------------------------
# source common functions from oud_functions.sh
. ${SCRIPT_DIR}/oud_functions.sh
# ------------------------------------------------------------------------------
# Purpose....: Display Usage
# ------------------------------------------------------------------------------
function Usage() {
    VERBOSE="TRUE"
    DoMsg " Usage, ${SCRIPT_NAME} [-fhvw -t <TIMEOUT> -a <START|STOP|RESTART> -i <OUD_INSTANCES>]"
    DoMsg "    -h                      Usage (this message"
    DoMsg "    -v                      enable verbose mode"
    DoMsg "    -f                      force startup will cause a restart if instance is running"
    DoMsg "    -w                      wait for OUDSM to start (default nowait)"
    DoMsg "    -t <TIMEOUT>            timeout when waiting for OUDSM (default ${TIMEOUT} seconds)"
    DoMsg "    -a <start|stop|restart> Activity either start, stop or restart (default start)"
    DoMsg "    -i <OUD_INSTANCES>      List of OUD instances (default all market with Y in oudtab)"
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

# Load OUD environment
OUDENV=$(find $OUD_BASE -name oudenv.sh)
. "${OUDENV}" SILENT >/dev/null 2>&1
# get oud_status.sh script
OUDSTATUS=$(find $OUD_BASE -name oud_status.sh)
 
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
 
if [ $# -eq 0 ]; then
   Usage 2
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvwft:a:i:E: arg; do
    case $arg in
        h) Usage 0;;
        v) VERBOSE="TRUE";;
        f) FORCE="TRUE";;
        w) WAIT="TRUE";;
        a) MyActivity="${OPTARG}";;
        t) TIMEOUT="${OPTARG}";;
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
MyActivity=$(echo $MyActivity|sed "s/^restart$/RESTART/gi")

# set the timeout just in case
TIMEOUT=${TIMEOUT:-10}

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
    DoMsg "INFO : Initiate $MyActivity for ${DIRECTORY_TYPE} instance ${oud_inst}"
    DoMsg "INFO : [$oud_inst] check the progress in instance logfile ${INSTANCE_LOGFILE}"
    if [ "$MyActivity" == "START" ]; then
        # check if instance is running
        ${OUDSTATUS} -i $oud_inst 2>&1 >/dev/null
        OUDSTATUS_ERROR=$?
        if [ ${OUDSTATUS_ERROR} -eq 0 ] && [ ${FORCE} == "TRUE" ]; then
            if [ ${DIRECTORY_TYPE} == "OUD" ]; then
                DoMsg "INFO : [$oud_inst] Instance $oud_inst forced to restart."
                $OUD_INSTANCE_HOME/OUD/bin/stop-ds >> ${INSTANCE_LOGFILE} 2>&1 
                $OUD_INSTANCE_HOME/OUD/bin/start-ds >> ${INSTANCE_LOGFILE} 2>&1 
            elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
                DoMsg "WARN : [$oud_inst] force not supported for OUDSM. Skip $MyActivity force for this instance."
            else
                DoMsg "WARN : [$oud_inst] Instance $oud_inst is not of type OUD/OUDSM. Skip $MyActivity for this instance."
            fi 
        elif [ ${OUDSTATUS_ERROR} -eq 0 ] && [ ${FORCE} == "FALSE" ]; then
            DoMsg "WARN : Instance $oud_inst already running"
            ERROR=$((ERROR+1))
        else
            # check directory type
            if [ ${DIRECTORY_TYPE} == "OUD" ]; then
                $OUD_INSTANCE_HOME/OUD/bin/start-ds >> ${INSTANCE_LOGFILE} 2>&1 
            elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
                # clean up old WLS lok, DAT files
                find $OUD_INSTANCE_HOME/servers -name "*.lok" -exec rm -f {} \; 2>/dev/null
                find $OUD_INSTANCE_HOME/servers -name "*.DAT" -exec rm -f {} \; 2>/dev/null
                nohup $OUD_INSTANCE_HOME/startWebLogic.sh >> ${INSTANCE_LOGFILE} 2>&1 &
                if [ ${WAIT} == "TRUE" ]; then
                    DoMsg "INFO : [$oud_inst] Start OUDSM domain $oud_inst and wait for ${TIMEOUT} seconds."
                    # OUDSM URL to check
                    URL="http://${HOST}:$PORT/oudsm/"
                    # check URL using curl
                    curl -sf ${URL} --output /dev/null 2>&1 >/dev/null
                    STARTING=$?                 # get return value
                    # calculate sleeptime 
                    WAIT_TIME=$(($TIMEOUT / $WAIT_ITER))
                    NEXT_WAIT=1
                    START_EPOCH=$(date "+%s")
                    # start the until loop
                    until [ $STARTING -eq 0 ] || [ $(($NEXT_WAIT*$WAIT_TIME)) -ge $TIMEOUT ]; do
                        [[ ${VERBOSE} == "TRUE" ]] && echo -n "."
                        sleep $WAIT_TIME        # Wait for the wait time
                        # check oudsm url
                        curl -sf ${URL} --output /dev/null 2>&1 >/dev/null
                        STARTING=$?             # get return value
                        let NEXT_WAIT++         # increment wait counter
                    done
                    END_EPOCH=$(date "+%s")
                    # print a status if in verbose mode
                    if [ $STARTING -eq 0 ]; then
                        [[ ${VERBOSE} == "TRUE" ]] && echo " OK (after $(($END_EPOCH-$START_EPOCH)) seconds)"     # status is OK
                    else
                        [[ ${VERBOSE} == "TRUE" ]] && echo " timeout ( $TIMEOUT seconds)" # run into a timeout
                    fi
                else
                    DoMsg "INFO : [$oud_inst] Start OUDSM domain $oud_inst in background."
                fi
            else
                DoMsg "WARN : [$oud_inst] Instance $oud_inst is not of type OUD/OUDSM. Skip $MyActivity for this instance."
            fi 
        fi
    elif  [ "$MyActivity" == "STOP" ]; then 
        if [ ${DIRECTORY_TYPE} == "OUD" ]; then
            $OUD_INSTANCE_HOME/OUD/bin/stop-ds >> ${INSTANCE_LOGFILE} 2>&1 
        elif [ "${DIRECTORY_TYPE}" == "OUDSM" ]; then
            nohup $OUD_INSTANCE_HOME/bin/stopWebLogic.sh >> ${INSTANCE_LOGFILE} 2>&1 &
            if [ "${WAIT}" == "TRUE" ]; then
                DoMsg "INFO : [$oud_inst] Stop OUDSM domain $oud_inst and wait for ${TIMEOUT} seconds."
                # OUDSM URL to check
                URL="http://${HOST}:$PORT/oudsm/"
                # check URL using curl
                curl -sf ${URL} --output /dev/null 2>&1 >/dev/null
                STARTING=$?                 # get return value
                # calculate sleeptime 
                WAIT_TIME=$(($TIMEOUT / $WAIT_ITER))
                NEXT_WAIT=1
                START_EPOCH=$(date "+%s")
                # start the until loop
                until [ $STARTING -ne 0 ] || [ $(($NEXT_WAIT*$WAIT_TIME)) -ge $TIMEOUT ]; do
                    [[ ${VERBOSE} == "TRUE" ]] && echo -n "."
                    sleep $WAIT_TIME        # Wait for the wait time
                    # check oudsm url
                    curl -sf ${URL} --output /dev/null 2>&1 >/dev/null
                    STARTING=$?             # get return value
                    let NEXT_WAIT++         # increment wait counter
                done
                END_EPOCH=$(date "+%s")
                # print a status if in verbose mode
                if [ $STARTING -ne 0 ]; then
                    # status is OK
                    [[ ${VERBOSE} == "TRUE" ]] && echo " OK (after $(($END_EPOCH-$START_EPOCH)) seconds)"
                else
                    # run into a timeout
                    [[ ${VERBOSE} == "TRUE" ]] && echo " timeout ( $TIMEOUT seconds)"
                fi
            else
                DoMsg "INFO : [$oud_inst] Stop OUDSM domain $oud_inst in background."
            fi
            # clean up old WLS lok, DAT files
            find $OUD_INSTANCE_HOME/servers -name "*.lok" -exec rm -f {} \;
            find $OUD_INSTANCE_HOME/servers -name "*.DAT" -exec rm -f {} \;
        else
            DoMsg "WARN : [$oud_inst] Instance $oud_inst is not of type OUD/OUDSM. Skip $MyActivity for this instance."
        fi
    elif  [ "$MyActivity" == "RESTART" ]; then 
        if [ ${DIRECTORY_TYPE} == "OUD" ]; then
            $OUD_INSTANCE_HOME/OUD/bin/stop-ds >> ${INSTANCE_LOGFILE} 2>&1 
            $OUD_INSTANCE_HOME/OUD/bin/start-ds >> ${INSTANCE_LOGFILE} 2>&1 
        elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
            DoMsg "WARN : [$oud_inst] $MyActivity not supported for OUDSM. Skip $MyActivity for this instance."
        else
            DoMsg "WARN : [$oud_inst] Instance $oud_inst is not of type OUD/OUDSM. Skip $MyActivity for this instance."
        fi
   else
    CleanAndQuit 71 $MyActivity
   fi
done
 
if [ "${ERROR}" -gt 0 ]; then
    CleanAndQuit 70 ${OUD_INST_LIST}
else
    CleanAndQuit 0
fi
# - EOF ------------------------------------------------------------------------
