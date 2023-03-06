#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: tns_modify.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.06
# Version....: v2.12.7
# Purpose....: Modify a tns entry
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
set -o errexit                      # exit script if any statement returns a non-true return value
set -o pipefail                     # pipefail exit after 1st piped commands failed

# - Environment Variables ------------------------------------------------------
# define generic environment variables
VERSION=v2.12.7
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
# - EOF Environment Variables --------------------------------------------------

# - Functions ------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function...: Usage
# Purpose....: Display Usage and exit script
# ------------------------------------------------------------------------------
function Usage() {
    
    # define default values for function arguments
    error=${1:-"0"}                 # default error number
    error_value=${2:-""}            # default error message
    cat << EOI

  Usage: ${TVDLDAP_SCRIPT_NAME} [options] [bind options] [modify options]

  Common Options:
    -m                  Usage this message
    -v                  Enable verbose mode (default \$TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE})
    -d                  Enable debug mode (default \$TVDLDAP_DEBUG=${TVDLDAP_DEBUG})
    -b <BASEDN>         Specify Base DN to search Net Service Name. Either
                        specific base DN or ALL to search Net Service Name in
                        all available namingContexts. By the default the Base
                        DN is derived from a fully qualified Net Service Name.
                        Otherwise the default Base DN is taken from ldap.ora. Can
                        also be specified by setting TVDLDAP_BASEDN.
    -h <HOST>           LDAP server (default take from ldap.ora). Can be specified
                        by setting TVDLDAP_LDAPHOST.
    -p <PORT>           port on LDAP server (default take from ldap.ora). Can be
                        specified by setting TVDLDAP_LDAPPORT.
                        
  Bind Options:
    -D <BINDDN>         Bind DN (default ANONYMOUS). Can be specified by setting
                        TVDLDAP_BINDDN.
    -w <PASSWORD>       Bind password. Can be specified by setting TVDLDAP_BINDDN_PWD.
    -W                  prompt for bind password. Can be specified by setting
                        TVDLDAP_BINDDN_PWDASK.
    -y <PASSWORD FILE>  Read password from file. Can be specified by setting
                        TVDLDAP_BINDDN_PWDFILE.

  Modify options:
    -S <NETSERVICE>     Oracle Net Service Name to modify (mandatory)
    -N <NETDESCSTRING>  Oracle Net Service description string (mandatory)
    -A                  Modify an Oracle Net Service alias rather a full description
                        string. If this option is specified -N must just be a target
                        Oracle Net Service Name for the alias
    -n                  Show what would be done but do not actually do it
    -F                  Force mode to add entry it it does not exists
    
  Configuration file:
    The script does load configuration files to define default values as an
    alternative for command line parameter. e.g. to set a bind DN TVDLDAP_BINDDN
    LDAP hostname TVDLDAP_LDAPHOST, etc. The configuration files are loaded in
    the following order:

$((get_list_of_config && echo "Command line parameter")|cat -b)

  Logfile : ${LOGFILE}

EOI
    dump_runtime_config     # dump current tool specific environment in debug mode
    clean_quit ${error} ${error_value}
}
# - EOF Functions --------------------------------------------------------------

# - Initialization -------------------------------------------------------------
# initialize logfile
touch $LOGFILE 2>/dev/null
exec &> >(tee -a "$LOGFILE") # Open standard out at `$LOG_FILE` for write.  
exec 2>&1  
echo "INFO : Start ${TVDLDAP_SCRIPT_NAME} on host $(hostname) at $(date)"

# source common variables and functions from tns_functions.sh
if [ -f ${TVDLDAP_BIN_DIR}/tns_functions.sh ]; then
    . ${TVDLDAP_BIN_DIR}/tns_functions.sh
else
    echo "ERROR: Can not find common functions ${TVDLDAP_BIN_DIR}/tns_functions.sh"
    exit 5
fi

load_config                 # load configuration files. File list in TVDLDAP_CONFIG_FILES

# get options
while getopts mvdb:h:p:D:w:Wy:S:N:nFAE: CurOpt; do
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
        A) TVDLDAP_NETALIAS="TRUE";; 
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

check_tools             # check if we do have the required LDAP tools available
check_ldap_tools        # check what kind of LDAP tools we do have e.g. 
                        # OpenLDAP, Oracle DB or Oracle Unified Directory
dump_runtime_config     # dump current tool specific environment in debug mode

# get the ldapmodify and ldapadd options based on available tools
ldapmodify_options=$(ldapmodify_options)
ldapadd_command=$(ldapadd_command)
ldapadd_options=$(ldapadd_options)

# Default values
export NETSERVICE=${NETSERVICE:-""}
export NETDESCSTRING=${NETDESCSTRING:-""}

# check for mandatory parameters
if [ -z "${NETSERVICE}" ]; then clean_quit 3 "-S"; fi
if [ -z "${NETDESCSTRING}" ]; then clean_quit 3 "-N"; fi

# get default values for LDAP Server
TVDLDAP_LDAPHOST=${TVDLDAP_LDAPHOST:-$(get_ldaphost)}
TVDLDAP_LDAPPORT=${TVDLDAP_LDAPPORT:-$(get_ldapport)}

# get bind parameter
ask_bindpwd                         # ask for the bind password if TVDLDAP_BINDDN_PWDASK
                                    # is TRUE and LDAP tools are not OpenLDAP
current_binddn=$(get_binddn_param "$TVDLDAP_BINDDN" )
current_bindpwd=$(get_bindpwd_param "$TVDLDAP_BINDDN_PWD" ${TVDLDAP_BINDDN_PWDASK} "$TVDLDAP_BINDDN_PWDFILE")
if [ -z "$current_binddn" ] && [ -z "${current_bindpwd}" ]; then clean_quit 4; fi

# get base DN information
BASEDN_LIST=$(get_basedn "$TVDLDAP_BASEDN")

# Split Net Service Name if full qualified e.g. with a dot
current_basedn=$(split_net_service_basedn ${NETSERVICE})
current_cn=$(split_net_service_cn ${NETSERVICE})
# - EOF Initialization ----------------------------------------------------------
 
# - Main ------------------------------------------------------------------------
echo_debug "DEBUG: Configuration / Variables:"
echo_debug "---------------------------------------------------------------------------------"
echo_debug "DEBUG: LDAP Host............... = $TVDLDAP_LDAPHOST"
echo_debug "DEBUG: LDAP Port............... = $TVDLDAP_LDAPPORT"
echo_debug "DEBUG: Bind DN................. = $TVDLDAP_BINDDN"
echo_debug "DEBUG: Bind PWD................ = $(echo_secret $TVDLDAP_BINDDN_PWD)"
echo_debug "DEBUG: Bind PWD File........... = $TVDLDAP_BINDDN_PWDFILE"
echo_debug "DEBUG: Bind parameter.......... = $current_binddn $(echo_secret $current_bindpwd)"
echo_debug "DEBUG: Base DN................. = $BASEDN_LIST"
echo_debug "DEBUG: Net Service Names....... = $NETSERVICE"
echo_debug "DEBUG: Net Service Name CN..... = $current_cn"
echo_debug "DEBUG: Net Service Name Base DN = $current_basedn"
echo_debug "DEBUG: Net Service Description. = $NETDESCSTRING"
echo_debug "DEBUG: Net Service Alias....... = $TVDLDAP_NETALIAS"
echo_debug "DEBUG: ldapmodify options...... = $ldapmodify_options"
echo_debug "DEBUG: ldapadd options......... = $ldapadd_options"
echo_debug "DEBUG: "

# Set BASEDN_LIST to current Base DN from Net Service Name
if [ -n "${current_basedn}" ]; then BASEDN_LIST=${current_basedn}; fi

# loop over base DN
for basedn in ${BASEDN_LIST}; do 
    echo_debug "DEBUG: Process base dn $basedn"
    if ! net_service_exists "$current_cn" "${basedn}" ; then
        if force_enabled; then
            echo "INFO : Add Net Service Name $current_cn in $basedn" 
            if ! dryrun_enabled; then
                if ! alias_enabled; then
                    $ldapadd_command -h ${TVDLDAP_LDAPHOST} -p ${TVDLDAP_LDAPPORT} \
                        ${current_binddn:+"$current_binddn"} \
                        ${current_bindpwd} ${ldapadd_options} <<-EOI
dn: cn=$current_cn,cn=OracleContext,$basedn
objectclass: top
objectclass: orclNetService
cn: $current_cn
orclNetDescString: $NETDESCSTRING

EOI
                else
                    aliasedObjectName=$(split_net_service_cn ${NETDESCSTRING})
                    $ldapadd_command -h ${TVDLDAP_LDAPHOST} -p ${TVDLDAP_LDAPPORT} \
                        ${current_binddn:+"$current_binddn"} \
                        ${current_bindpwd} ${ldapadd_options} <<-EOI
dn: cn=$current_cn,cn=OracleContext,$basedn
aliasedObjectName: cn=$aliasedObjectName,cn=OracleContext,$basedn
objectClass: alias
objectClass: top
objectClass: orclNetServiceAlias
cn: $current_cn

EOI
                fi
                
                # check if last command did run successfully
                if [ $? -ne 0 ]; then clean_quit 33 "$ldapadd_command"; fi
            else
                echo "INFO : Dry run enabled, skip add Net Service Name $current_cn in $basedn"
            fi
        else
            echo "WARN : Net Service Name $current_cn does not exists in $current_basedn. Enable force mode to add it."
        fi
    else
        echo "INFO : Modify Net Service Name $current_cn in $current_basedn"
        if ! dryrun_enabled; then
            if ! alias_enabled; then
                ldapmodify -h ${TVDLDAP_LDAPHOST} -p ${TVDLDAP_LDAPPORT} \
                    ${current_binddn:+"$current_binddn"} \
                    ${current_bindpwd} ${ldapmodify_options} <<-EOI
dn: cn=$current_cn,cn=OracleContext,$current_basedn
changetype: modify
replace: orclNetDescString
orclNetDescString: $NETDESCSTRING

EOI
            else
                aliasedObjectName=$(split_net_service_cn ${NETDESCSTRING})
                ldapmodify -h ${TVDLDAP_LDAPHOST} -p ${TVDLDAP_LDAPPORT} \
                    ${current_binddn:+"$current_binddn"} \
                    ${current_bindpwd} ${ldapmodify_options} <<-EOI
dn: cn=$current_cn,cn=OracleContext,$current_basedn
changetype: modify
replace: aliasedObjectName
aliasedObjectName: cn=$aliasedObjectName,cn=OracleContext,$basedn

EOI
            fi
            # check if last command did run successfully
            if [ $? -ne 0 ]; then clean_quit 33 "ldapmodify"; fi
        fi
    fi
done

rotate_logfiles                     # purge log files based on TVDLDAP_KEEP_LOG_DAYS
clean_quit                          # clean exit with return code 0
# --- EOF ----------------------------------------------------------------------
