#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: oud_functions.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.03.05
# Revision...: 
# Purpose....: Common OUD Base functions.
# Notes......: Has to be source in the vagrant provisioning bash scripts to load
#              environment and default values based on vagrant.yml 
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
# - Customization -----------------------------------------------------------

# - End of Customization ----------------------------------------------------

# - Environment Variables ---------------------------------------------------
# define default values 
VERSION=v1.8.3
DOAPPEND=${DOAPPEND:-"TRUE"}                    # enable log file append
VERBOSE=${VERBOSE:-"FALSE"}                     # enable verbose mode
DEBUG=${DEBUG:-"FALSE"}                         # enable debug mode
SEND_MAIL=${SEND_MAIL:-"UNDEF"} 
# - EOF Environment Variables -----------------------------------------------

# - Functions ---------------------------------------------------------------
# -----------------------------------------------------------------------
# Purpose....: Display Usage
# -----------------------------------------------------------------------
function oud_test() {
    echo "hello world"
}

# -----------------------------------------------------------------------
# Purpose....: Display Message with time stamp
# -----------------------------------------------------------------------
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

# -----------------------------------------------------------------------
# Purpose....: Clean up before exit
# -----------------------------------------------------------------------
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
        60) DoMsg "ERR  : Exit Code ${1}. Force mail enabled but no e-Mail adress specified";;
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
# - EOF Functions -----------------------------------------------------------

# check if script is sourced and return/exit
if [ "${DEBUG^^}" == "TRUE" ]; then
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        echo "INFO : Script ${BASH_SOURCE[0]} is sourced from ${0}"
    else
        echo "INFO : Script ${BASH_SOURCE[0]} is executed. No action is performed"
    fi
fi
# --- EOF --------------------------------------------------------------------