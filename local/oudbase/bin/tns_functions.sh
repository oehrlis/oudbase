#!/bin/bash
# ----------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------------
# Name.......: tns_functions.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.12.14
# Revision...: 
# Purpose....: Common functions used by the TNS bash scripts.
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ----------------------------------------------------------------------------

# - Customization ------------------------------------------------------------
# - just add/update any kind of customized environment variable here
TVDLDAP_DEFAULT_LDAPHOST="localhost"
TVDLDAP_DEFAULT_LDAPPORT=389
TVDLDAP_DEFAULT_KEEP_LOG_DAYS=5
TVDLDAP_DEFAULT_BINDDN=""
TVDLDAP_DEFAULT_BINDDN_PWDASK="FALSE"
TVDLDAP_DEFAULT_BINDDN_PWD=""
TVDLDAP_DEFAULT_BINDDN_PWDFILE=""
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
DEFAULT_TOOLS=${DEFAULT_TOOLS:-"ldapsearch ldapadd ldapmodify ldapdelete"} # List of default tools
LOCAL_SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
export TVDLDAP_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TVDLDAP_LOG_DIR="$(dirname ${TVDLDAP_BIN_DIR})/log"
export TVDLDAP_ETC_DIR="$(dirname ${TVDLDAP_BIN_DIR})/etc"
export TVDLDAP_BASE=$(dirname ${TVDLDAP_BIN_DIR})
export TOOL_BASE_NAME=$(basename ${TVDLDAP_BASE})
export TVDLDAP_CONFIG_FILES=""
export TVDLDAP_KEEP_LOG_DAYS=${TVDLDAP_KEEP_LOG_DAYS:-$TVDLDAP_DEFAULT_KEEP_LOG_DAYS}

# define bind DN environment variables
export TVDLDAP_BINDDN=${TVDLDAP_BINDDN:-$TVDLDAP_DEFAULT_BINDDN}
export TVDLDAP_BINDDN_PWDASK=${TVDLDAP_BINDDN_PWDASK:-$TVDLDAP_DEFAULT_BINDDN_PWDASK}
export TVDLDAP_BINDDN_PWD=${TVDLDAP_BINDDN_PWD:-$TVDLDAP_DEFAULT_BINDDN_PWD}
export TVDLDAP_BINDDN_PWDFILE=${TVDLDAP_BINDDN_PWDFILE:-$TVDLDAP_DEFAULT_BINDDN_PWDFILE}

# initialize common variables
export TVDLDAP_BASEDN=${TVDLDAP_BASEDN:-""}
export TVDLDAP_DRYRUN=${TVDLDAP_DRYRUN:-"FALSE"}
export TVDLDAP_FORCE=${TVDLDAP_FORCE:-"FALSE"}
# - EOF Environment Variables -----------------------------------------------

# - Functions ---------------------------------------------------------------
# ---------------------------------------------------------------------------
# Function...: force_enabled
# Purpose....: Check if FORCE mode is enabled
# ---------------------------------------------------------------------------
function force_enabled () {
    if [ "${TVDLDAP_FORCE^^}" == "TRUE" ]; then
        return 0
    else
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Function...: dryrun_enabled
# Purpose....: Check if DRYRUN mode is enabled
# ---------------------------------------------------------------------------
function dryrun_enabled () {
    if [ "${TVDLDAP_DRYRUN^^}" == "TRUE" ]; then
        return 0
    else
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Function...: command_exists
# Purpose....: Check if a command does exists
# ---------------------------------------------------------------------------
function command_exists () {
    command -v $1 >/dev/null 2>&1;
}

# ---------------------------------------------------------------------------
# Function...: check_tools
# Purpose....: Check if the required tools are installed
# ---------------------------------------------------------------------------
function check_tools() {
    TOOLS="$DEFAULT_TOOLS ${1:-""}"
    echo_debug "DEBUG: List of tools to check: ${TOOLS}"
    for i in ${TOOLS}; do
        if ! command_exists ${i}; then
            clean_quit 10 ${i} 
            exit 1
        fi
    done
    if [ $(ldapsearch -VV 2>&1 |grep -c OpenLDAP) -eq 0]; then
        clean_quit 11 ${i} 
    fi
}

# ---------------------------------------------------------------------------
# Function...: check_openldap_tools
# Purpose....: Check if the required tools are OpenLDAP
# ---------------------------------------------------------------------------
function check_openldap_tools() {
    TOOLS="ldapsearch ldapmodify ldapadd ldapdelete"
    echo_debug "DEBUG: List of tools to check: ${TOOLS}"
    for i in ${TOOLS}; do
        if command_exists ${i}; then
            if [ "$($i -VV 2>&1 |grep -c OpenLDAP)" -eq 0 ]; then
                clean_quit 11 ${i} 
            fi
        fi
    done
}

# ---------------------------------------------------------------------------
# Function...: echo_debug
# Purpose....: Echo only if TVDLDAP_DEBUG variable is true
# ---------------------------------------------------------------------------
function echo_debug () {
    if [ "${TVDLDAP_DEBUG^^}" == "TRUE" ]; then
        echo $1
    fi
}

# ---------------------------------------------------------------------------
# Function...: clean_quit
# Purpose....: Clean exit for all scripts
# ---------------------------------------------------------------------------
function clean_quit() {

    # define default values for function arguments
    error=${1:-"0"}
    error_value=${2:-""}
    TVDLDAP_SCRIPT_NAME=${TVDLDAP_SCRIPT_NAME:-${LOCAL_SCRIPT_NAME}}

    case ${error} in
        0)  echo "INFO : Successfully finish ${TVDLDAP_SCRIPT_NAME}";;
        1)  echo "ERROR: Exit Code ${error}. Wrong amount of arguments. See usage for correct one." ;;
        2)  echo "ERROR: Exit Code ${error}. Wrong arguments (${error_value}). See usage for correct one." >&2;;
        3)  echo "ERROR: Exit Code ${error}. Missing mandatory argument (${error_value}). See usage ..." >&2;;
        4)  echo "ERROR: Exit Code ${error}. Missing mandatory Bind arguments -D with -w, -W or -y. See usage ..." >&2;;
        5)  echo "ERROR: Exit Code ${error}. Missing common function file (${error_value}) to source." >&2;;
        10) echo "ERROR: Exit Code ${error}. Command ${error_value} isn't installed/available on this system..." >&2;;
        11) echo "ERROR: Exit Code ${error}. LDAP tool ${error_value} in PATH is not OpenLDAP compatible..." >&2;;
        20) echo "ERROR: Exit Code ${error}. File ${error_value} already exists..." >&2;;
        21) echo "ERROR: Exit Code ${error}. Directory ${error_value} is not writeable..." >&2;;
        22) echo "ERROR: Exit Code ${error}. Can not read file ${error_value} ..." >&2;;
        23) echo "ERROR: Exit Code ${error}. Can not write file ${error_value} ..." >&2;;
        24) echo "ERROR: Exit Code ${error}. Can not create skip/reject files in ${error_value} ..." >&2;;
        25) echo "ERROR: Exit Code ${error}. Can not read file password file ${error_value} ..." >&2;;
        30) echo "ERROR: Exit Code ${error}. Bind DN ${error_value} defined but no password parameter provided..." >&2;;
        31) echo "ERROR: Exit Code ${error}. Base DN ${error_value} does not exists..." >&2;;
        32) echo "ERROR: Exit Code ${error}. Base DN ALL not supported for ${error_value} ..." >&2;;
        *)  echo "ERROR: Exit Code ${error}. But do not no realy why..." >&2;;
    esac
    exit ${error}
}

# ---------------------------------------------------------------------------
# Function...: load_config
# Purpose....: Load package specific configuration files
# ---------------------------------------------------------------------------
function load_config() {
    echo_debug "DEBUG: Start to source configuration files"
    for config in   ${TVDLDAP_ETC_DIR}/${TOOL_BASE_NAME}.conf \
                    ${TVDLDAP_ETC_DIR}/${TOOL_BASE_NAME}_custom.conf \
                    ${ETC_BASE}/${TOOL_BASE_NAME}.conf \
                    ${ETC_BASE}/${TOOL_BASE_NAME}_custom.conf; do
        if [ -f "${config}" ]; then
            echo_debug "DEBUG: source configuration file ${config}"
            . ${config}
            export TVDLDAP_CONFIG_FILES="$TVDLDAP_CONFIG_FILES${config} "
        fi
    done
}

# ---------------------------------------------------------------------------
# Function...: dump_runtime_config
# Purpose....: Dump / display runtime configuration and variables
# ---------------------------------------------------------------------------
function dump_runtime_config() {
    echo_debug "DEBUG: Dump current ${TOOL_BASE_NAME} specific environment variables"
    if [ "${TVDLDAP_DEBUG^^}" == "TRUE" ]; then 
        env|grep -i "${TOOL_BASE_NAME}_"|sort
    fi
}

# ---------------------------------------------------------------------------
# Function...: rotate_logfiles
# Purpose....: Rotate and purge log files
# ---------------------------------------------------------------------------
function rotate_logfiles() {
    TVDLDAP_KEEP_LOG_DAYS=${1:-$TVDLDAP_KEEP_LOG_DAYS}
    echo_debug "DEBUG: purge files older for ${TVDLDAP_SCRIPT_NAME} than $TVDLDAP_KEEP_LOG_DAYS"
    find $LOG_BASE -name "$(basename ${TVDLDAP_SCRIPT_NAME} .sh)*.log" \
        -mtime +${TVDLDAP_KEEP_LOG_DAYS} -exec rm {} \; 
}

# ---------------------------------------------------------------------------
# Function...: get_all_basedn
# Purpose....: get base dn from LDAP server namingContexts
# ---------------------------------------------------------------------------
function get_all_basedn() {
    TVDLDAP_LDAPHOST=${1:-$(get_ldaphost)}
    TVDLDAP_LDAPPORT=${2:-$(get_ldapport)}
    /usr/bin/ldapsearch -p ${TVDLDAP_LDAPPORT} -h ${TVDLDAP_LDAPHOST} -x -b "" -LLL \
        -s base "(objectClass=*)" namingContexts|grep -i namingContexts|cut -d: -f2| xargs
}

# ---------------------------------------------------------------------------
# Function...: get_local_basedn
# Purpose....: get base dn from ldap.ora DEFAULT_ADMIN_CONTEXT
# ---------------------------------------------------------------------------
function get_local_basedn() {
    if [ -f "$TNS_ADMIN/ldap.ora" ]; then
        grep -i DEFAULT_ADMIN_CONTEXT $TNS_ADMIN/ldap.ora|sed 's/.*"\(.*\)".*/\1/'
    else
        echo $TVDLDAP_DEFAULT_BASEDN
    fi
}

# ---------------------------------------------------------------------------
# Function...: get_basedn
# Purpose....: get base correct base DN. Either default, ldap.ora or all, check
#              if user provided base DN are valid
# ---------------------------------------------------------------------------
function get_basedn() {
    TVDLDAP_BASEDN="${1}"
    LOCAL_BASEDN=""
    # get base DN information
    if [ -z "$TVDLDAP_BASEDN" ]; then
        LOCAL_BASEDN=$(get_local_basedn)
    elif [ "${TVDLDAP_BASEDN^^}" == "ALL" ]; then
        LOCAL_BASEDN=$(get_all_basedn)
    else
        if [[ "$TVDLDAP_BASEDN" =~ ^dc=.* ]]; then
            LOCAL_BASEDN=$TVDLDAP_BASEDN
        else
            LOCAL_BASEDN=$(echo $TVDLDAP_BASEDN|sed -e 's/\./,dc=/g' -e 's/^/dc=/')
        fi
        if [[ "$(get_all_basedn)" != *"${LOCAL_BASEDN}"* ]]; then
            clean_quit 31 ${LOCAL_BASEDN}
        fi
    fi
    echo $LOCAL_BASEDN
}

# ---------------------------------------------------------------------------
# Function...: basedn_exists
# Purpose....: check if base does exists in ldap.ora namingContexts
# ---------------------------------------------------------------------------
function basedn_exists() {
    my_basedn=${1:-""}
    ALL_BASEDN=$(get_all_basedn)        # get list of all base DN
    
    if [[ "$my_basedn" =~ ^dc=.* ]]; then
        my_basedn=$my_basedn            # keep base DN as it is
    else
        # convert regular domain name into a base DN
        my_basedn=$(echo $my_basedn|sed -e 's/\./,dc=/g' -e 's/^/dc=/')
    fi
    # check if my_basedn is in the list of all base DN
    if [[ "${ALL_BASEDN}" == *"${my_basedn}"* ]]; then
        return 0 
    else
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Function...: split_net_service_basedn
# Purpose....: split base DN from full qualified Net Service Name
# ---------------------------------------------------------------------------
function split_net_service_basedn() {
    my_netservice=${1:-""}
    if [ -n "${my_netservice}" ]; then
        if [[ "${my_netservice}" == *"."* ]]; then
            echo $my_netservice| cut -d. -f2-| tr '[:upper:]' '[:lower:]'|sed -e 's/\./,dc=/g' -e 's/^/dc=/'
        else 
            echo ""
        fi
    else
        echo ""
    fi
}

# ---------------------------------------------------------------------------
# Function...: split_net_service_cn
# Purpose....: split Net Service Name from full qualified Net Service Name
# ---------------------------------------------------------------------------
function split_net_service_cn() {
    my_netservice=${1:-""}
    if [ -n "${my_netservice}" ]; then
        if [[ "${my_netservice}" == *"."* ]]; then
            echo $my_netservice| cut -d. -f1
        else 
            echo $my_netservice
        fi
    else
        echo ""
    fi
}

# ---------------------------------------------------------------------------
# Function...: net_service_exists
# Purpose....: check if Net Service Name does exists
# ---------------------------------------------------------------------------
function net_service_exists() {
    my_netservice=${1:-""}
    my_basedn=${2:-"$(get_local_basedn)"}           # get the default Base DN from ldap.ora
    my_ldaphost=$(get_ldaphost)                     # get ldap host from ldap.ora
    my_ldapport=$(get_ldapport)                     # get ldap port from ldap.ora
    current_cn=$(split_net_service_cn ${my_netservice})         # get pure Net Service Name
    current_basedn=$(split_net_service_basedn ${my_netservice}) # get Base DN from Net Service Name
    current_basedn=${current_basedn:-$my_basedn}    # set the Base DN if not defined in Net Service Name
    
    if [ -n "${current_cn}" ]; then
        result=$(ldapsearch -h ${my_ldaphost} -p ${my_ldapport} -x -b $current_basedn -LLL -o "ldif-wrap=no" -s sub "(&(objectclass=orclNetService)(cn=$current_cn))" dn)
        if [ -z "$result" ]; then
            return 1
        else
            return 0
        fi
    fi
}

# ---------------------------------------------------------------------------
# Function...: check_bind_parameter
# Purpose....: check the correct bind parameter and combination
# ---------------------------------------------------------------------------
function check_bind_parameter() {
    TVDLDAP_BINDDN="${1}"
    TVDLDAP_BINDDN_PWD="${2}"
    TVDLDAP_BINDDN_PWDFILE="${3}"
    TVDLDAP_BINDDN_PWDASK="${4}"
    if [ -n "$TVDLDAP_BINDDN" ] && [ -n "$TVDLDAP_BINDDN_PWDFILE" ] ; then
        if [ ! -f "$TVDLDAP_BINDDN_PWDFILE" ]; then
           clean_quit 22 $TVDLDAP_BINDDN_PWDFILE
        fi
    elif [ -n "$TVDLDAP_BINDDN" ] && [ "${TVDLDAP_BINDDN_PWDASK^^}" == "TRUE" ] ; then
        BIND_PARA=("-D '$TVDLDAP_BINDDN'" "-W")
    elif [ -n "$TVDLDAP_BINDDN" ] && [ -n "$TVDLDAP_BINDDN_PWD" ] ; then
        BIND_PARA=("-D '$TVDLDAP_BINDDN'" "-w $TVDLDAP_BINDDN_PWD")
    elif [ -n "$TVDLDAP_BINDDN" ] ; then
        clean_quit 30 "$TVDLDAP_BINDDN"
    else
        BIND_PARA=()
    fi
    echo "${BIND_PARA[@]}"
}

# ---------------------------------------------------------------------------
# Function...: get_binddn_param
# Purpose....: create Bind DN Parameter
# ---------------------------------------------------------------------------
function get_binddn_param() {
    my_binddn=${1:-$TVDLDAP_BINDDN}
    if [ -n "$my_binddn" ]; then 
        echo "-D $my_binddn"
    else
        echo ""
    fi
}

# ---------------------------------------------------------------------------
# Function...: get_bindpwd_param
# Purpose....: create Bind password parameter
# ---------------------------------------------------------------------------
function get_bindpwd_param() {
    my_bindpwd=${1:-$TVDLDAP_BINDDN_PWD}
    my_bindpwd_ask=${2:-$TVDLDAP_BINDDN_PWDASK}
    my_bindpwd_file=${3:-$TVDLDAP_BINDDN_PWDFILE}
    if [ -n "$my_bindpwd" ]; then 
        echo "-w $my_bindpwd"
    elif [ "${my_bindpwd_ask^^}" == "TRUE" ]; then 
        echo "-W"
    elif [ -n "$my_bindpwd_file" ]; then
        if [ -f "$my_bindpwd_file" ]; then
            echo "-y $my_bindpwd_file"
        else
            clean_quit 25 $my_bindpwd_file
        fi
    else
        echo ""
    fi
}

# ---------------------------------------------------------------------------
# Function...: get_ldaphost
# Purpose....: get ldap host from ldap.ora
# ---------------------------------------------------------------------------
function get_ldaphost() {
    if [ -f "$TNS_ADMIN/ldap.ora" ]; then
        grep -i DIRECTORY_SERVERS $TNS_ADMIN/ldap.ora|sed 's/.*(\(.*\),.*/\1/'| cut -d: -f1
    else
        echo $TVDLDAP_DEFAULT_LDAPHOST
    fi
}

# ---------------------------------------------------------------------------
# Function...: get_ldapport
# Purpose....: get ldap port from ldap.ora
# ---------------------------------------------------------------------------
function get_ldapport() {
    if [ -f "$TNS_ADMIN/ldap.ora" ]; then
        grep -i DIRECTORY_SERVERS $TNS_ADMIN/ldap.ora|sed 's/.*(\(.*\),.*/\1/'| cut -d: -f2
    else
        echo $TVDLDAP_DEFAULT_LDAPPORT
    fi
}

# - EOF Functions -----------------------------------------------------------

# - Initialization ----------------------------------------------------------

# - EOF Initialization -------------------------------------------------------
 
# - Main ---------------------------------------------------------------------
# check if script is sourced and return/exit
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    echo_debug "DEBUG: Script ${BASH_SOURCE[0]} is sourced from ${0}"
else
    echo "INFO : Script ${BASH_SOURCE[0]} is executed directly. No action is performed."
    clean_quit
fi
# --- EOF --------------------------------------------------------------------