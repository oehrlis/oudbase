#!/bin/bash
# ----------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------------
# Name.......: tns_search.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.12.14
# Revision...: 
# Purpose....: Search a tns entry
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ----------------------------------------------------------------------------
# - Customization ------------------------------------------------------------
# - just add/update any kind of customized environment variable here

# - End of Customization ----------------------------------------------------

# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o nounset          # exit if script try to use an uninitialised variable
set -o errexit          # exit script if any statement returns a non-true return value
set -o pipefail         # pipefail exit after 1st piped commands failed

# - Environment Variables ---------------------------------------------------
# define generic environment variables
VERSION=v2.0.0
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
# - EOF Environment Variables -----------------------------------------------

# - Functions ---------------------------------------------------------------
# ---------------------------------------------------------------------------
# Function...: Usage
# Purpose....: Display Usage and exit script
# ---------------------------------------------------------------------------
function Usage() {
    
    # define default values for function arguments
    error=${1:-"0"}
    error_value=${2:-""}
    cat << EOI

  Usage: ${TVDLDAP_SCRIPT_NAME} [options] [bind options] [search options] [services]

  where:
    services	        Comma separated list of Oracle Net Service Names to search
        
  Common Options:
    -m                  Usage this message
    -v                  Enable verbose mode (default \$TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE})
    -d                  Enable debug mode (default \$TVDLDAP_DEBUG=${TVDLDAP_DEBUG})
    -b <BASEDN>         Specify Base DN to search Net Service Name. Either
                        specific base DN or ALL to search Net Service Name in
                        all available namingContexts. By the default the Base
                        DN is derived from a fully qualified Net Service Name.
                        Otherwise the default Base DN is taken from ldap.ora
    -h <HOST>           LDAP server (default take from ldap.ora)
    -p <PORT>           port on LDAP server (default take from ldap.ora)

  Bind Options:
    -D <BINDDN>         Bind DN (default ANONYMOUS)
    -w <PASSWORD>       Bind password
    -W                  prompt for bind password
    -y <PASSWORD FILE>  Read password from file

  Search options:
    -S <NETSERVICE>     Oracle Net Service Names to search for
                        (default \$ORACLE_SID)
    
  Logfile : ${LOGFILE}

EOI
    dump_runtime_config     # dump current tool specific environment in debug mode
    clean_quit ${error} ${error_value}
}
# - EOF Functions -----------------------------------------------------------

# - Initialization ----------------------------------------------------------
# initialize logfile
touch $LOGFILE 2>/dev/null
exec &> >(tee -a "$LOGFILE")    # Open standard out at `$LOG_FILE` for write.  
exec 2>&1  
echo "INFO : Start ${TVDLDAP_SCRIPT_NAME} on host $(hostname) at $(date)"

# source common variables and functions from tns_functions.sh
if [ -f ${TVDLDAP_BIN_DIR}/tns_functions.sh ]; then
    . ${TVDLDAP_BIN_DIR}/tns_functions.sh
else
    echo "ERROR: Can not find common functions ${TVDLDAP_BIN_DIR}/tns_functions.sh"
    exit 5
fi

# load configuration files
load_config

# get options
while getopts mvdb:h:p:D:w:Wy:S:E: CurOpt; do
    case ${CurOpt} in
        m) Usage 0;;
        v) TVDLDAP_VERBOSE="TRUE" ;;
        d) TVDLDAP_DEBUG="TRUE" ;;
        b) TVDLDAP_BASEDN="${OPTARG}";;
        h) TVDLDAP_LDAPHOST=${OPTARG};;
        p) TVDLDAP_LDAPPORT=${OPTARG};;
        D) TVDLDAP_BINDDN="${OPTARG}";; 
        w) TVDLDAP_BINDDN_PWD="${OPTARG}";; 
        W) TVDLDAP_BINDDN_PWDASK="TRUE";; 
        y) TVDLDAP_BINDDN_PWDFILE="${OPTARG}";; 
        S) NETSERVICE=${OPTARG};;
        E) clean_quit "${OPTARG}";;
        *) Usage 2 $*;;
    esac
done

# display usage and exit if parameter is null
if [ $# -eq 0 ]; then
   Usage 1
fi

check_openldap_tools    # check tools required by tvdldap
dump_runtime_config     # dump current tool specific environment in debug mode

# Default values
export NETSERVICE=${NETSERVICE:-""}

# check for Service and Arguments
if [ -z "$NETSERVICE" ] && [ $# -ne 0 ]; then
    if [[ "$1" =~ ^-.*  ]]; then
        NETSERVICE=$ORACLE_SID    # default service to ORACLE_SID if Argument starting with dash 
    else
        NETSERVICE=$1             # default service to Argument if not starting with dash
    fi
fi

# check for mandatory parameters
if [ -z "${NETSERVICE}" ]; then clean_quit 3 "-S"; fi

# get default values for LDAP Server
TVDLDAP_LDAPHOST=${TVDLDAP_LDAPHOST:-$(get_ldaphost)}
TVDLDAP_LDAPPORT=${TVDLDAP_LDAPPORT:-$(get_ldapport)}

# get bind parameter
current_binddn=$(get_binddn_param "$TVDLDAP_BINDDN" )
current_bindpwd=$(get_bindpwd_param "$TVDLDAP_BINDDN_PWD" ${TVDLDAP_BINDDN_PWDASK} "$TVDLDAP_BINDDN_PWDFILE")
if [ -n "$current_binddn" ] && [ -z "${current_bindpwd}" ]; then clean_quit 4; fi

# get base DN information
BASEDN_LIST=$(get_basedn "$TVDLDAP_BASEDN")
# - EOF Initialization -------------------------------------------------------
 
# - Main ---------------------------------------------------------------------
echo_debug "DEBUG: ldapsearch using:"
echo_debug "DEBUG: LDAP Host            = $TVDLDAP_LDAPHOST"
echo_debug "DEBUG: LDAP Port            = $TVDLDAP_LDAPPORT"
echo_debug "DEBUG: Bind DN              = $TVDLDAP_BINDDN"
echo_debug "DEBUG: Bind PWD             = $TVDLDAP_BINDDN_PWD"
echo_debug "DEBUG: Bind PWD File        = $TVDLDAP_BINDDN_PWDFILE"
echo_debug "DEBUG: Bind parameter       = $current_binddn $current_bindpwd"
echo_debug "DEBUG: Base DN              = $BASEDN_LIST"
echo_debug "DEBUG: Net Service Names    = $NETSERVICE"

echo
for service in $(echo $NETSERVICE | tr "," "\n"); do  # loop over service
    echo_debug "DEBUG: process service $service"
    current_basedn=$(split_net_service_basedn ${service})
    current_cn=$(split_net_service_cn ${service})

    # Set BASEDN_LIST to current Base DN from Net Service Name
    if [ -n "${current_basedn}" ]; then
        BASEDN_LIST=${current_basedn}
    else 
        BASEDN_LIST=$(get_basedn "$TVDLDAP_BASEDN")
    fi
    echo_debug "DEBUG: current Base DN list         = $BASEDN_LIST"
    echo_debug "DEBUG: current Net Service Names    = $current_cn"
    for basedn in ${BASEDN_LIST}; do                # loop over base DN
        if basedn_exists ${basedn}; then
            echo "INFO : Process base dn $basedn"
            domain=$(echo $basedn|sed -e 's/,dc=/\./g' -e 's/dc=//g')
            i=0                                         # init counter to test for results
            if [ -n "$current_binddn" ]; then           # check if bind dn is defined
                while IFS= read -r result ; do          # loop over ldapsearch results 
                    i=$((i+1))                          # inc counter to count results
                    cn=$(echo ${result}| cut -d ';' -f 1 | cut -d " " -f 2)
                    NetDescString=$(echo ${result}| cut -d ';' -f 2 | cut -d " " -f2-)
                    echo "${cn}.${domain}=${NetDescString}"
                done < <(ldapsearch -p ${TVDLDAP_LDAPPORT} -h ${TVDLDAP_LDAPHOST} "$current_binddn" $current_bindpwd -x -b "$basedn" -LLL -o "ldif-wrap=no" -s sub "(&(objectclass=orclNetService)(cn=${current_cn}))" cn orclNetDescString|grep -iv '^dn: '| sed 's/$/;/g' | sed 's/^;$/DELIM/g'| tr -d '\n'| sed 's/DELIM/\n/g')
            else
                while IFS= read -r result ; do          # loop over ldapsearch results 
                    i=$((i+1))                          # inc counter to count results
                    cn=$(echo ${result}| cut -d ';' -f 1 | cut -d " " -f 2)
                    NetDescString=$(echo ${result}| cut -d ';' -f 2 | cut -d " " -f2-)
                    echo "${cn}.${domain}=${NetDescString}"
                done < <(ldapsearch -p ${TVDLDAP_LDAPPORT} -h ${TVDLDAP_LDAPHOST} -x -b "$basedn" -LLL -o "ldif-wrap=no" -s sub "(&(objectclass=orclNetService)(cn=${current_cn}))" cn orclNetDescString|grep -iv '^dn: '| sed 's/$/;/g' | sed 's/^;$/DELIM/g'| tr -d '\n'| sed 's/DELIM/\n/g')
            fi
            if [ $i -eq 0 ]; then               # Inform when no results found
                echo "WARN : Net Service Name ${current_cn} not found in ${basedn}"
            fi
        fi
    done
    echo 
done

# purge log files
rotate_logfiles
clean_quit
# --- EOF --------------------------------------------------------------------
