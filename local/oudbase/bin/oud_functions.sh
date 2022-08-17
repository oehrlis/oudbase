#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oud_functions.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.08.17
# Version....: v2.1.1
# Purpose....: Common OUD Base functions.
# Notes......: Has to be source in the vagrant provisioning bash scripts to load
#              environment and default values based on vagrant.yml 
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------

# - End of Customization -------------------------------------------------------

# - Environment Variables ------------------------------------------------------
# define default values 
VERSION=v2.1.1
DOAPPEND=${DOAPPEND:-"TRUE"}                    # enable log file append
VERBOSE=${VERBOSE:-"FALSE"}                     # enable verbose mode
DEBUG=${DEBUG:-"FALSE"}                         # enable debug mode
SEND_MAIL=${SEND_MAIL:-"UNDEF"} 
SOFTWARE=${SOFTWARE:-"${ORACLE_BASE}/software"} # local software stage folder
SOFTWARE_REPO=${SOFTWARE_REPO:-""}              # URL to software for curl fallback
# - EOF Environment Variables --------------------------------------------------

# - Functions ------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Purpose....: Display Usage
# ------------------------------------------------------------------------------
function oud_test() {
    echo "hello world"
}

# ------------------------------------------------------------------------------
# Purpose....: Display Message with time stamp
# ------------------------------------------------------------------------------
function DoMsg()
{
    INPUT=${1}
    PREFIX=${INPUT%: *}                # Take everything before :
    case ${PREFIX} in                  # Define a nice time stamp for ERR, END
        "END  ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "ERR  ")        TIME_STAMP=$(date "+%n%Y-%m-%d_%H:%M:%S  ");;
        "START")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "OK   ")        TIME_STAMP="";;
        "INFO ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "WARN ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "DEBUG")        if [ "${DEBUG^^}" == "TRUE" ]; then TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  "); else return; fi ;;
        *)              TIME_STAMP="";;
    esac
    if [ "${VERBOSE^^}" == "TRUE" ]; then
        if [ "${DOAPPEND^^}" == "TRUE" ]; then
            echo "${TIME_STAMP}${1}" |tee -a ${LOGFILE}
        else
            echo "${TIME_STAMP}${1}"
        fi
        shift
        while [ "${1}" != "" ]; do
            if [ "${DOAPPEND^^}" == "TRUE" ]; then
                echo "               ${1}" |tee -a ${LOGFILE}
            else
                echo "               ${1}"
            fi
            shift
        done
    else
        if [ "${DOAPPEND^^}" == "TRUE" ]; then
            echo "${TIME_STAMP}  ${1}" >> ${LOGFILE}
        fi
        shift
        while [ "${1}" != "" ]; do
            if [ "${DOAPPEND^^}" == "TRUE" ]; then
                echo "               ${1}" >> ${LOGFILE}
            fi
            shift
        done
    fi
}

# ------------------------------------------------------------------------------
# Purpose....: Clean up before exit
# ------------------------------------------------------------------------------
function CleanAndQuit() {
    STATUS="INFO"
    if [ ${1} -gt 0 ]; then
        VERBOSE="TRUE"
        if [ "${SEND_MAIL}" != "UNDEF" ]; then
            DoMsg "DEBUG: CleanAndQuit called with error != 0 force send e-Mail"
            SEND_MAIL="TRUE"
        else
            DoMsg "DEBUG: Send e-Mail ${SEND_MAIL}"
        fi
      STATUS="ERROR"
    fi

    # log info in case we do send e-mails
    if [ "${SEND_MAIL}" = "TRUE" ]; then
        if [ -n "${MAILADDRESS}" ]; then
            DoMsg "INFO : Send e-Mail to ${MAILADDRESS}"
        else
            DoMsg "WARN : SEND_MAIL is TRUE, but can not send e-Mail. No address specified."
        fi
    fi
    case ${1} in
        0)  DoMsg "END  : of ${SCRIPT_NAME}";;
        1)  DoMsg "ERR  : Exit Code ${1}. Wrong amount of arguments. See usage for correct one.";;
        2)  DoMsg "ERR  : Exit Code ${1}. Wrong arguments (${2}). See usage for correct one.";;
        3)  DoMsg "ERR  : Exit Code ${1}. This script must not be run as root ${2}";;
        5)  DoMsg "ERR  : Exit Code ${1}. OUD Instance ${2} does not exits in ${OUDTAB} or ${ORACLE_INSTANCE_BASE}";;
        10) DoMsg "ERR  : Exit Code ${1}. OUD_BASE not set or $OUD_BASE not available.";;
        11) DoMsg "ERR  : Exit Code ${1}. Could not touch file ${2}";;
        12) DoMsg "ERR  : Exit Code ${1}. Can not create directory ${2}";;
        13) DoMsg "ERR  : Exit Code ${1}. Directory ${2} is not read / writeable";;
        14) DoMsg "ERR  : Exit Code ${1}. Directory ${2} already exists";;
        15) DoMsg "ERR  : Exit Code ${1}. Cloud not access file ${2}";;
        21) DoMsg "ERR  : Exit Code ${1}. Could not load \${HOME}/.OUD_BASE";;
        30) DoMsg "ERR  : Exit Code ${1}. Some backups failed";;
        31) DoMsg "ERR  : Exit Code ${1}. Some exports failed";;
        32) DoMsg "ERR  : Exit Code ${1}. Error while performing exports";;
        33) DoMsg "ERR  : Exit Code ${1}. Error while performing backups";;
        40) DoMsg "ERR  : Exit Code ${1}. Error not defined";;
        41) DoMsg "ERR  : Exit Code ${1}. Error ${2} running status command";;
        42) DoMsg "ERR  : Exit Code ${1}. Error ${2} running dsreplication command";; 
        43) DoMsg "ERR  : Exit Code ${1}. Missing bind password file";;
        44) DoMsg "ERR  : Exit Code ${1}. unknown directory type ${2}, can not check status";;
        50) DoMsg "ERR  : Exit Code ${1}. OUD Instance ${2} not running";;
        51) DoMsg "ERR  : Exit Code ${1}. Connection Handler ${2} is not enabled on ${OUD_INSTANCE}";;
        52) DoMsg "ERR  : Exit Code ${1}. Error in Replication for OUD Instance ${OUD_INSTANCE}. Check replication log ${ORACLE_INSTANCE_BASE}/${OUD_INSTANCE}/OUD/logs for more information";;
        53) DoMsg "ERR  : Exit Code ${1}. Error OUDSM console ${2} is not available";;
        60) DoMsg "ERR  : Exit Code ${1}. Force mail enabled but no e-Mail adress specified";;
        70) DoMsg "ERR  : Exit Code ${1}. Error starting instances ${2}";;
        71) DoMsg "ERR  : Exit Code ${1}. Error unknown activity ${2}";;
        80) DoMsg "ERR  : Exit Code ${1}. No base software package specified. Abort installation.";;
        99) DoMsg "INFO : Just wanna say hallo.";;
        ?)  DoMsg "ERR  : Exit Code ${1}. Unknown Error.";;
    esac
 
    # if we do have mail addresses we will send some mails...
    if [ "${SEND_MAIL}" = "TRUE" ] && [ -n "${MAILADDRESS}" ]; then
        # check how much lines we do have to tail
        LOG_END=$(wc -l <"${LOGFILE}")
        LOG_TAIL=$(($LOG_END-$LOG_START))
        tail -${LOG_TAIL} ${LOGFILE} |mailx -s "$STATUS : OUD Script ${SCRIPT_NAME}" ${MAILADDRESS}
    fi
    exit ${1}
}

function running_in_docker() {
# ------------------------------------------------------------------------------
# Purpose....:  Function for checking whether the process is running in a 
#               container. It return 0 if YES or 1 if NOT.
# ------------------------------------------------------------------------------
    if [ -e /proc/self/cgroup ]; then
        awk -F/ '$2 == "docker"' /proc/self/cgroup | read
    else
        return 1
    fi
}

function get_software {
# ------------------------------------------------------------------------------
# Purpose....: Verify if the software package is available if not try to 
#              download it from $SOFTWARE_REPO
# ------------------------------------------------------------------------------
    PKG=$1
    if [ ! -s "${SOFTWARE}/${PKG}" ]; then
        if [ ! -z "${SOFTWARE_REPO}" ]; then
            echo " - Try to download ${PKG} from ${SOFTWARE_REPO}"
            curl -f ${SOFTWARE_REPO}/${PKG} -o ${SOFTWARE}/${PKG} 2>&1
            CURL_ERR=$?
            if [ ${CURL_ERR} -ne 0 ]; then
                echo " - WARNING: Unable to access software repository or ${PKG} (curl error ${CURL_ERR})"
                return 1
            fi
        else
            echo " - WARNING: No software repository specified"
            return 1
        fi
    else
        echo " - Found package ${PKG} for installation."
        return 0
    fi
}
# - EOF Functions --------------------------------------------------------------
# check if script is sourced and return/exit
if [ "${DEBUG^^}" == "TRUE" ]; then
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        echo "INFO : Script ${BASH_SOURCE[0]} is sourced from ${0}"
    else
        echo "INFO : Script ${BASH_SOURCE[0]} is executed. No action is performed"
    fi
fi
# --- EOF ----------------------------------------------------------------------