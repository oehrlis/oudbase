#!/bin/bash
# ----------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------------
# Name.......: tns_modify.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.12.14
# Revision...: 
# Purpose....: Modify a tns entry
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

  Usage: ${TVDLDAP_SCRIPT_NAME} [options] [bind options] [modify options]

  Common Options:
    -m                  Usage this message
    -v                  Enable verbose mode (default \$TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE})
    -d                  Enable debug mode (default \$TVDLDAP_DEBUG=${TVDLDAP_DEBUG})
    -b <BASEDN>         Specify Base DN to modify Net Service Name. Either
                        specific base DN or ALL to modify Net Service Name in
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

  Modify options:
    -S <NETSERVICE>     Oracle Net Service Name to modify (mandatory)
    -N <NETDESCSTRING>  Oracle Net Service description string (mandatory)
    -n                  Show what would be done but do not actually do it
    -F                  Force mode to add entry it it does not exists

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

# source common functions from tns_functions.sh
if [ -f ${TVDLDAP_BIN_DIR}/tns_functions.sh ]; then
    . ${TVDLDAP_BIN_DIR}/tns_functions.sh
else
    echo "ERROR: Can not find common functions ${TVDLDAP_BIN_DIR}/tns_functions.sh"
    exit 5
fi

# load configuration files
load_config

# get options
while getopts mvdb:h:p:D:w:Wy:S:N:nFE: CurOpt; do
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
        F) TVDLDAP_FORCE="TRUE";; 
        n) TVDLDAP_DRYRUN="TRUE";; 
        S) NETSERVICE=${OPTARG};;
        N) NETDESCSTRING="${OPTARG}";;
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
NETSERVICE=${NETSERVICE:-""}
NETDESCSTRING=${NETDESCSTRING:-""}

# check for mandatory parameters
if [ -z "${NETSERVICE}" ]; then clean_quit 3 "-S"; fi
if [ -z "${NETDESCSTRING}" ]; then clean_quit 3 "-N"; fi

# get default values for LDAP Server
TVDLDAP_LDAPHOST=${TVDLDAP_LDAPHOST:-$(get_ldaphost)}
TVDLDAP_LDAPPORT=${TVDLDAP_LDAPPORT:-$(get_ldapport)}

# get bind parameter
current_binddn=$(get_binddn_param "$TVDLDAP_BINDDN" )
current_bindpwd=$(get_bindpwd_param "$TVDLDAP_BINDDN_PWD" ${TVDLDAP_BINDDN_PWDASK} "$TVDLDAP_BINDDN_PWDFILE")
if [ -z "$current_binddn" ] && [ -z "${current_bindpwd}" ]; then clean_quit 4; fi

# get base DN information
BASEDN_LIST=$(get_basedn "$TVDLDAP_BASEDN")

# Split Net Service Name if full qualified e.g. with a dot
current_basedn=$(split_net_service_basedn ${NETSERVICE})
current_cn=$(split_net_service_cn ${NETSERVICE})
# - EOF Initialization -------------------------------------------------------
 
# - Main ---------------------------------------------------------------------
echo_debug "DEBUG: ldapsearch using:"
echo_debug "DEBUG: LDAP Host                = $TVDLDAP_LDAPHOST"
echo_debug "DEBUG: LDAP Port                = $TVDLDAP_LDAPPORT"
echo_debug "DEBUG: Bind DN                  = $TVDLDAP_BINDDN"
echo_debug "DEBUG: Bind PWD                 = $TVDLDAP_BINDDN_PWD"
echo_debug "DEBUG: Bind PWD File            = $TVDLDAP_BINDDN_PWDFILE"
echo_debug "DEBUG: Bind parameter           = $current_binddn $current_bindpwd"
echo_debug "DEBUG: Base DN                  = $BASEDN_LIST"
echo_debug "DEBUG: Net Service Name         = $NETSERVICE"
echo_debug "DEBUG: Net Service Name CN      = $current_cn"
echo_debug "DEBUG: Net Service Name Base DN = $current_basedn"
echo_debug "DEBUG: Net Service Description  = $NETDESCSTRING"

# Set BASEDN_LIST to current Base DN from Net Service Name
if [ -n "${current_basedn}" ]; then BASEDN_LIST=${current_basedn}; fi

# loop over base DN
for basedn in ${BASEDN_LIST}; do 
    echo_debug "DEBUG: Process base dn $basedn"
    if net_service_exists "$current_cn" "${basedn}" ; then
        echo "INFO : Modify Net Service Name $current_cn in $current_basedn"
        if ! dryrun_enabled; then
            ldapmodify -p ${TVDLDAP_LDAPPORT} -h ${TVDLDAP_LDAPHOST} "$current_binddn" $current_bindpwd <<-EOI
dn: cn=$current_cn,cn=OracleContext,$current_basedn
changetype: modify
replace: orclNetDescString
orclNetDescString: $NETDESCSTRING

EOI
        else
            echo "INFO : Dry run enabled, skip modify Net Service Name $current_cn in $basedn"
        fi
    else
        if force_enabled; then
            echo "INFO : Add Net Service Name $current_cn in $basedn" 
            if ! dryrun_enabled; then
                ldapadd -p ${TVDLDAP_LDAPPORT} -h ${TVDLDAP_LDAPHOST} "$current_binddn" $current_bindpwd <<-EOI
dn: cn=$current_cn,cn=OracleContext,$basedn
objectclass: top
objectclass: orclNetService
cn: $current_cn
orclNetDescString: $NETDESCSTRING

EOI
            else
                echo "INFO : Dry run enabled, skip add Net Service Name $current_cn in $basedn"
            fi
        fi
    fi
done

# purge log files
rotate_logfiles
clean_quit
# --- EOF --------------------------------------------------------------------