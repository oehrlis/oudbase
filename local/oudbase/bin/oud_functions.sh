#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oud_functions.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.05.28
# Version....: v3.6.0
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
VERSION=v3.6.0
DOAPPEND=${DOAPPEND:-"TRUE"}                    # enable log file append
VERBOSE=${VERBOSE:-"FALSE"}                     # enable verbose mode
DEBUG=${DEBUG:-"FALSE"}                         # enable debug mode
SEND_MAIL=${SEND_MAIL:-"UNDEF"} 
ORACLE_BASE=${ORACLE_BASE:-""}
SOFTWARE=${SOFTWARE:-"${ORACLE_BASE}/software"} # local software stage folder
SOFTWARE_REPO=${SOFTWARE_REPO:-""}              # URL to software for curl fallback

# Define the color for the output 
export TNS_INFO="\e[96m%b\e[0m" 
export TNS_SUCCESS="\e[92m%b\e[0m" 
export TNS_WARNING="\e[93m%b\e[0m" 
export TNS_ERROR="\e[91m%b\e[0m" 

# explisitly define a couple of default variable
TMP_DIR=${TMP_DIR:-""}
DEFAULT_TMP_DIR=${DEFAULT_TMP_DIR:-""}
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
function DoMsg() {
    set +o nounset                      # exit if script try to use an uninitialised variable
    INPUT=${1:-""}
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
    error=${1:-"0"}                 # default error number
    error_value=${2:-""}            # default error message
    STATUS="INFO"
    if [ ${error} -gt 0 ]; then
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
    case ${error} in
        0)  DoMsg "END  : Successfully finish ${SCRIPT_NAME}";;
        1)  DoMsg "ERR  : Exit Code ${error}. Wrong amount of arguments. See usage for correct one.";;
        2)  DoMsg "ERR  : Exit Code ${error}. Wrong arguments (${error_value}). See usage for correct one.";;
        3)  DoMsg "ERR  : Exit Code ${error}. This script must not be run as root ${error_value}";;
        5)  DoMsg "ERR  : Exit Code ${error}. OUD Instance ${error_value} does not exits in ${OUDTAB} or ${ORACLE_INSTANCE_BASE}";;
        10) DoMsg "ERR  : Exit Code ${error}. OUD_BASE not set or $OUD_BASE not available.";;
        11) DoMsg "ERR  : Exit Code ${error}. Could not touch file ${error_value}";;
        12) DoMsg "ERR  : Exit Code ${error}. Can not create directory ${error_value}";;
        13) DoMsg "ERR  : Exit Code ${error}. Directory ${error_value} is not read / writeable";;
        14) DoMsg "ERR  : Exit Code ${error}. Directory ${error_value} already exists";;
        15) DoMsg "ERR  : Exit Code ${error}. Cloud not access file ${error_value}";;
        21) DoMsg "ERR  : Exit Code ${error}. Could not load \${HOME}/.OUD_BASE";;
        30) DoMsg "ERR  : Exit Code ${error}. Some backups failed";;
        31) DoMsg "ERR  : Exit Code ${error}. Some exports failed";;
        32) DoMsg "ERR  : Exit Code ${error}. Error while performing exports";;
        33) DoMsg "ERR  : Exit Code ${error}. Error while performing backups";;
        40) DoMsg "ERR  : Exit Code ${error}. Error not defined";;
        41) DoMsg "ERR  : Exit Code ${error}. Error ${error_value} running status command";;
        42) DoMsg "ERR  : Exit Code ${error}. Error ${error_value} running dsreplication command";; 
        43) DoMsg "ERR  : Exit Code ${error}. Missing bind password file";;
        44) DoMsg "ERR  : Exit Code ${error}. unknown directory type ${error_value}, can not check status";;
        50) DoMsg "ERR  : Exit Code ${error}. OUD Instance ${error_value} not running";;
        51) DoMsg "ERR  : Exit Code ${error}. Connection Handler ${error_value} is not enabled on ${OUD_INSTANCE}";;
        52) DoMsg "ERR  : Exit Code ${error}. Error in Replication for OUD Instance ${OUD_INSTANCE}. Check replication log ${ORACLE_INSTANCE_BASE}/${OUD_INSTANCE}/OUD/logs for more information";;
        53) DoMsg "ERR  : Exit Code ${error}. Error OUDSM console ${error_value} is not available";;
        54) DoMsg "ERR  : Exit Code ${error}. Can not proceed, no OUD instance defined/found";;
        60) DoMsg "ERR  : Exit Code ${error}. Force mail enabled but no e-Mail adress specified";;
        70) DoMsg "ERR  : Exit Code ${error}. Error starting instances ${error_value}";;
        71) DoMsg "ERR  : Exit Code ${error}. Error unknown activity ${error_value}";;
        80) DoMsg "ERR  : Exit Code ${error}. No base software package specified. Abort installation.";;
        90) DoMsg "ERR  : Exit Code ${error}. Received signal SIGINT / Interrupt / CTRL-C ..." >&2;;
        91) DoMsg "ERR  : Exit Code ${error}. Received signal TERM to terminate the script ..." >&2;;
        92) DoMsg "ERR  : Exit Code ${error}. Recived signal is SIGINT / Interrupt / CTRL-C} ..." >&2;;
        99) DoMsg "INFO : Just wanna say hallo.";;
        ?)  DoMsg "ERR  : Exit Code ${error}. Unknown Error.";;
    esac
 
    # clean up potential Temp directories
    if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then rm -rf "${TMP_DIR}"; fi
    if [ -n "$DEFAULT_TMP_DIR" ] && [ -d "$DEFAULT_TMP_DIR" ]; then rm -rf "${DEFAULT_TMP_DIR}"; fi
    
    # if we do have mail addresses we will send some mails...
    if [ "${SEND_MAIL}" = "TRUE" ] && [ -n "${MAILADDRESS}" ]; then
        # check how much lines we do have to tail
        LOG_END=$(wc -l <"${LOGFILE}")
        LOG_TAIL=$(($LOG_END-$LOG_START))
        tail -${LOG_TAIL} ${LOGFILE} |mailx -s "$STATUS : OUD Script ${SCRIPT_NAME}" ${MAILADDRESS}
    fi
    exit ${error}
}

# ------------------------------------------------------------------------------
# Function...: on_int
# Purpose....: function to handle interupt by CTRL-C
# ------------------------------------------------------------------------------
on_int() {
    echo
    printf $TNS_INFO'\n' "You hit CTRL-C, are you sure ? (y/n)"
    read answer
    if [[ ${answer} = "y" ]]; then
        printf $TNS_ERROR'\n' "OK, lets quit then"
        CleanAndQuit 90
    else
        printf $TNS_INFO'\n' "OK, lets continue then"
    fi
}

# ------------------------------------------------------------------------------
# Function...: on_term
# Purpose....: function to handle TERM signal
# ------------------------------------------------------------------------------
on_term() {
  printf $TNS_ERROR'\n' "I have recived a terminal signal. Terminating script..."
  CleanAndQuit 91
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
    SOFTWARE_PKG=$(find ${SOFTWARE} -name ${PKG} 2>/dev/null| head -1)
    if [ -z "${SOFTWARE_PKG}" ] || [ ! -s "${SOFTWARE_PKG}" ]; then 
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
        echo " - Found package ${PKG} for installation in $(dirname ${SOFTWARE_PKG})."
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