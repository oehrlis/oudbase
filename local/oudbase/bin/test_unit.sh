#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_unit.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.06.30
# Version....: v3.6.1
# Purpose....: Script to test / verify all TNS utilities
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------
# - just add/update any kind of customized environment variable here

# - End of Customization -------------------------------------------------------

# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o nounset                      # exit if script try to use an uninitialised variable
# set -o errexit                      # exit script if any statement returns a non-true return value
# set -o pipefail                     # pipefail exit after 1st piped commands failed
set -o noglob                       # Disable filename expansion (globbing).
# - Environment Variables ------------------------------------------------------
# define generic environment variables
VERSION=v3.6.1
TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE:-"FALSE"}                     # enable verbose mode
TVDLDAP_DEBUG=${TVDLDAP_DEBUG:-"FALSE"}                         # enable debug mode
TVDLDAP_QUIET=${TVDLDAP_QUIET:-"FALSE"}                         # enable quiet mode
TVDLDAP_SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
TVDLDAP_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TVDLDAP_LOG_DIR="$(dirname ${TVDLDAP_BIN_DIR})/log"

# define logfile and logging
LOG_BASE=${LOG_BASE:-"${TVDLDAP_LOG_DIR}"} # Use script log directory as default logbase
TIMESTAMP=$(date "+%Y.%m.%d_%H%M%S")
readonly LOGFILE="$LOG_BASE/$(basename $TVDLDAP_SCRIPT_NAME .sh)_$TIMESTAMP.log"

# define tempfile for ldapsearch
TEMPFILE="$LOG_BASE/$(basename $TVDLDAP_SCRIPT_NAME .sh)_$$.ldif"
# Define the color for the output 
export INFO="\e[98m%b\e[0m" 
export SUCCESS="\e[92m%b\e[0m" 
export WARNING="\e[93m%b\e[0m" 
export ERROR="\e[91m%b\e[0m"

export TNS_RED="\e[91m%b\e[0m"
export TNS_GREED="\e[92m%b\e[0m"
export TNS_YELLOW="\e[93m%b\e[0m"
export TNS_PURPLE="\e[94m%b\e[0m"
export TNS_MAGENTA="\e[95m%b\e[0m" 
export TNS_CYAN="\e[96m%b\e[0m" 
export TNS_WHITE="\e[97m%b\e[0m" 
export TNS_BLACK="\e[98m%b\e[0m" 
export TNS_OTHER_BLACK="\e[99m%b\e[0m" 

# - EOF Environment Variables --------------------------------------------------

# - Functions ------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function...: Usage
# Purpose....: Display Usage and exit script
# ------------------------------------------------------------------------------
Usage() {
    
    # define default values for arguments
    error=${1:-"0"}                 # default error number
    error_value=${2:-""}            # default error message
    cat << EOI

  Usage: ${TVDLDAP_SCRIPT_NAME} [options]

  where:
    services	        Comma separated list of Oracle Net Service Names to test

  Common Options:
    -m                  Usage this message
    -v                  Enable verbose mode (default \$TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE})
    -d                  Enable debug mode (default \$TVDLDAP_DEBUG=${TVDLDAP_DEBUG})

$((get_list_of_config && echo "Command line parameter")|cat -b)

  Logfile : ${LOGFILE}

EOI
    exit $error
}

# ------------------------------------------------------------------------------
# Function...: ok
# Purpose....: echo OK
# ------------------------------------------------------------------------------
ok() { printf ${INFO:-"\e[98m%b\e[0m"}'\n' "OK" ; }

# ------------------------------------------------------------------------------
# Function...: nok
# Purpose....: echo Not OK
# ------------------------------------------------------------------------------
nok() { printf ${ERROR:-"\e[92m%b\e[0m"}'\n' "Not OK" ; }

# ------------------------------------------------------------------------------
# Function...: nok
# Purpose....: echo Not OK
# ------------------------------------------------------------------------------
display(){
    status=${1:-""}
    message=${2:-""}
    value=${3:-""}
    padding='...............................................................................................'
    if [ -z $value ]; then
        printf "%s : %s %s %s" "${status^^}"  "${message}" "${padding:${#message}}" "${value}"
    else
        value=${value//\\n/}
        printf "%s : %s %s\n" "${status^^}"  "${message}" "${value}"
    fi
} 

function try()
{
    [[ $- = *e* ]]; SAVED_OPT_E=$?
    set +e
}

function throw()
{
    exit $1
}

function catch()
{
    export exception_code=$?
    (( $SAVED_OPT_E )) && set +e
    return $exception_code
}
# - EOF Functions --------------------------------------------------------------

# - Initialization -------------------------------------------------------------
touch $LOGFILE 2>/dev/null          # initialize logfile
exec &> >(tee -a "$LOGFILE")        # Open standard out at `$LOG_FILE` for write.  
exec 2>&1  
printf $TNS_INFO'\n'  "INFO : Start ${TVDLDAP_SCRIPT_NAME} on host $(hostname) at $(date)"

# initialize tempfile for the script
touch $TEMPFILE 2>/dev/null || exit 25
printf $INFO'\n'  "INFO : touch logfile $LOGFILE"
printf $INFO'\n'  "INFO : touch tempfile $TEMPFILE"


# get options
while getopts mvdE: CurOpt; do
    case ${CurOpt} in
        m) Usage 0;;
        v) TVDLDAP_VERBOSE="TRUE" ;;
        d) TVDLDAP_DEBUG="TRUE" ;;
        E) clean_quit "${OPTARG}";;
        *) Usage 2 $*;;
    esac
done

display "INFO" "load file ${TVDLDAP_BIN_DIR}/tns_functions.sh"
if [ -f ${TVDLDAP_BIN_DIR}/tns_functions.sh ]; then . ${TVDLDAP_BIN_DIR}/tns_functions.sh; ok; else nok; fi

display "INFO" "check functions" "..."
display "INFO" "source_env"
if ! source_env 2>$LOGFILE ; then nok ; else ok ; fi

display "INFO" "load_config"
if ! load_config 2>$LOGFILE ; then nok ; else ok ; fi

display "INFO" "check_tools"
if ! check_tools 2>$LOGFILE ; then nok ; else ok ; fi

display "INFO" "check_ldap_tools"
if ! check_ldap_tools 2>$LOGFILE ; then nok ; else ok ; fi

display "INFO" "clean_quit"
try
(
    clean_quit 99 >$LOGFILE 2>&1
) 
catch || {
    case $exception_code in
        99) ok;;
        *) nok;;
    esac
}

display "INFO" "check_ldap_tools"
if ! check_ldap_tools 2>$LOGFILE ; then nok ; else ok ; fi

display "INFO" "get_basedn"
if ! get_local_basedn >$LOGFILE 2>&1 ; then nok ; else ok ; fi


display "INFO" "get_local_basedn"
if ! get_local_basedn >$LOGFILE 2>&1 ; then nok ; else ok ; fi

display "INFO" "get_all_basedn"
if ! get_all_basedn >$LOGFILE 2>&1 ; then nok ; else ok ; fi

display "INFO" "get_ldaphost"
if ! get_ldaphost >$LOGFILE 2>&1 ; then nok ; else ok ; fi

display "INFO" "get_ldapport"
if ! get_ldapport >$LOGFILE 2>&1 ; then nok ; else ok ; fi

display "INFO" "rotate_logfiles"
if ! rotate_logfiles 2>$LOGFILE ; then nok ; else ok ; fi

# alias_enabled
# ask_bindpwd
# basedn_exists
# bulk_enabled
# check_bind_parameter
# check_openldap_tools
# clean_quit
# command_exists
# dryrun_enabled
# dump_runtime_config
# echo_debug
# echo_secret
# echo_stderr
# force_enabled
# get_binddn_param
# get_bindpwd_param
# join_dotora
# ldapadd_command
# ldapadd_options
# ldapmodify_options
# ldapsearch_options
# net_service_exists
# on_int
# on_term
# split_net_service_basedn
# split_net_service_cn
# tidy_dotora

display "INFO" "check scripts" "..."
display "INFO" "tns_add.sh"
try
(
    tns_add.sh -S DUMMY.epu.corpintra.net \
    -N "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.1.1.12)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=TDB02.trivadislabs.com))(UR=A))" || throw 1
) 
catch || {
    case $exception_code in
        1) nok;;
        *) ok;;
    esac
}

if ! tns_add.sh >$LOGFILE 2>&1  ; then nok ; else ok ; fi

rotate_logfiles                     # purge log files based on TVDLDAP_KEEP_LOG_DAYS
clean_quit                          # clean exit with return code 0
# --- EOF ----------------------------------------------------------------------