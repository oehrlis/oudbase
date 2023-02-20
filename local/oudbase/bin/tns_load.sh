#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: tns_load.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2023.02.20
# Version....: v2.9.2
# Purpose....: Load a tnsnames.ora
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------
# - just add/update any kind of customized environment variable here
DEFAULT_OUTPUT_DIR=${TNS_ADMIN:-$(pwd)}
DEFAULT_FILE_PREFIX="ldap_dump"
# - End of Customization -------------------------------------------------------

# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o nounset                      # exit if script try to use an uninitialised variable
set -o errexit                      # exit script if any statement returns a non-true return value
set -o pipefail                     # pipefail exit after 1st piped commands failed

# - Environment Variables ------------------------------------------------------
# define generic environment variables
VERSION=v2.9.2
TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE:-"FALSE"}                     # enable verbose mode
TVDLDAP_DEBUG=${TVDLDAP_DEBUG:-"FALSE"}                         # enable debug mode
TVDLDAP_QUIET=${TVDLDAP_QUIET:-"FALSE"}                         # enable quiet mode
TVDLDAP_SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
TVDLDAP_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TVDLDAP_LOG_DIR="$(dirname ${TVDLDAP_BIN_DIR})/log"
files_processed=0                           # Counter for processed files 
entries_processed=0                         # Counter for processed entries 
entries_loaded=0                            # Counter for loaded entries 
entries_skipped=0                           # Counter for skipped entries 
entries_rejected=0                          # Counter for rejected entries 
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

  Usage: ${TVDLDAP_SCRIPT_NAME} [options] [bind options] [load options]

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

  Load options:
    -t <TNSNAMES FILE>  tnsnames.ora file to read and load (mandatory)
    -n                  Show what would be done but do not actually do it
    -F                  Force mode to add entry it it does not exists

  Configuration file:
    The script does load configuration files to define default values as an
    alternative for command line parameter. e.g. to set a bind DN TVDLDAP_BINDDN
    LDAP hostname TVDLDAP_LDAPHOST, etc. The configuration files are loaded in
    the following order:

    1.  ${TVDLDAP_ETC_DIR}/${TOOL_OUD_BASE_NAME}.conf
    2.  ${TVDLDAP_ETC_DIR}/${TOOL_OUD_BASE_NAME}_custom.conf
    3.  ${ETC_BASE}/${TOOL_OUD_BASE_NAME}.conf
    4.  ${ETC_BASE}/${TOOL_OUD_BASE_NAME}_custom.conf
    5.  Command line parameter

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
while getopts mvdb:h:p:D:w:Wy:t:FnE: CurOpt; do
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
        t) TNSNAMES_FILES="${OPTARG}";;
        F) TVDLDAP_FORCE="TRUE";; 
        n) TVDLDAP_DRYRUN="TRUE";; 
        E) clean_quit "${OPTARG}";;
        *) Usage 2 $*;;
    esac
done

check_tools             # check if we do have the required LDAP tools available
check_ldap_tools        # check what kind of LDAP tools we do have e.g. 
                        # OpenLDAP, Oracle DB or Oracle Unified Directory
dump_runtime_config     # dump current tool specific environment in debug mode

# get the ldapmodify and ldapadd options based on available tools
ldapmodify_options=$(ldapmodify_options)

# check if the current LDAP utilites does provide an 
if ! command_exists ldapadd; then
    ldapadd_command="ldapmodify"
    ldapadd_options=$(ldapmodify_options)
else
    ldapadd_command="ldapadd"
    ldapadd_options=$(ldapadd_options)
fi

# Default values
TNSNAMES_FILES=${TNSNAMES_FILES:-""}
if [ -z "${TNSNAMES_FILES}" ]; then clean_quit 3 "-t"; fi

# get default values for LDAP Server
TVDLDAP_LDAPHOST=${TVDLDAP_LDAPHOST:-$(get_ldaphost)}
TVDLDAP_LDAPPORT=${TVDLDAP_LDAPPORT:-$(get_ldapport)}

# get bind parameter
ask_bindpwd                         # ask for the bind password if TVDLDAP_BINDDN_PWDASK
                                    # is TRUE and LDAP tools are not OpenLDAP
current_binddn=$(get_binddn_param "$TVDLDAP_BINDDN" )
current_bindpwd=$(get_bindpwd_param "$TVDLDAP_BINDDN_PWD" ${TVDLDAP_BINDDN_PWDASK} "$TVDLDAP_BINDDN_PWDFILE")
if [ -z "$current_binddn" ] && [ -z "${current_bindpwd}" ]; then clean_quit 4; fi

# get base DN information if not ALL specified
if [ "${TVDLDAP_BASEDN^^}" == "ALL" ]; then clean_quit 32 ${TVDLDAP_SCRIPT_NAME} ;fi
common_basedn=$(get_basedn "$TVDLDAP_BASEDN")

# - EOF Initialization ----------------------------------------------------------
 
# - Main ------------------------------------------------------------------------
echo_debug "DEBUG: Configuration / Variables:"
echo_debug "DEBUG: LDAP Host............... = $TVDLDAP_LDAPHOST"
echo_debug "DEBUG: LDAP Port............... = $TVDLDAP_LDAPPORT"
echo_debug "DEBUG: Bind DN................. = $TVDLDAP_BINDDN"
echo_debug "DEBUG: Bind PWD................ = $TVDLDAP_BINDDN_PWD"
echo_debug "DEBUG: Bind PWD File........... = $TVDLDAP_BINDDN_PWDFILE"
echo_debug "DEBUG: Bind parameter.......... = $current_binddn $current_bindpwd"
echo_debug "DEBUG: Common Base DN.......... = $common_basedn"
echo_debug "DEBUG: tnsnames file........... = $TNSNAMES_FILES"
echo_debug "DEBUG: ldapmodify options...... = $ldapmodify_options"
echo_debug "DEBUG: ldapadd options......... = $ldapadd_options"

for file in $TNSNAMES_FILES; do
    files_processed=$((files_processed+1))      # Count processed files
    echo_debug "DEBUG: Start to process file $file"
    # check if we can access the file
    if [ ! -f "${file}" ]; then clean_quit 22 "${file}"; fi

    # check if we can write to the folder to create the skip / reject files
    if [ ! -w "$(dirname ${file})" ]; then clean_quit 24 "$(dirname ${file})"; fi

    # start to read the file
    while IFS= read -r line ; do
        entries_processed=$((entries_processed+1))  # Count processed entries
        net_service=$(echo $line| cut -d'=' -f1)
        current_cn=$(split_net_service_cn ${net_service})         # get pure Net Service Name
        current_basedn=$(split_net_service_basedn ${net_service}) 
        current_basedn=${current_basedn:-"${common_basedn}"}    
        NetDescString=$(echo $line| cut -d'=' -f2-)
        # check for , in service name => reject
        if [[ "${net_service}" == *","* ]]; then
            echo "WARN : Can not handle comma in Net Service Name, reject Net Service Name ${net_service}"
            echo "# Can not handle comma in Net Service Name ${net_service}" >>"${file}_reject" || clean_quit 23 ${file}_reject
            echo "${net_service}=${NetDescString}" >>"${file}_reject"
            entries_rejected=$((entries_rejected+1))      # Count rejeced entries
            continue
        fi

        # check if base DN exists => reject
        if ! basedn_exists ${current_basedn}; then
            echo "WARN : Base DN ${current_basedn} does not exists, reject Net Service Name ${net_service}"
            echo "# Base DN ${current_basedn} does not exists, reject Net Service Name ${net_service}" >>"${file}_reject"
            echo "${net_service}=${NetDescString}" >>"${file}_reject"
            entries_rejected=$((entries_rejected+1))      # Count rejeced entries
            continue
        fi
        echo_debug "DEBUG: Net Service Name => $net_service"
        echo_debug "DEBUG: cn               => $current_cn"
        echo_debug "DEBUG: basedn           => $current_basedn"
        echo_debug "DEBUG: NetDescString    => $NetDescString"
        # check if net service entry exists => skip if force = FALSE
        if ! net_service_exists "$current_cn" "${current_basedn}" ; then
            echo "INFO : Add Net Service Name $net_service in $current_basedn" 
            if ! dryrun_enabled; then
                $ldapadd_command -h ${TVDLDAP_LDAPHOST} -p ${TVDLDAP_LDAPPORT} \
                    ${current_binddn:+"$current_binddn"} \
                    ${current_bindpwd} ${ldapadd_options} <<-EOI
dn: cn=$current_cn,cn=OracleContext,$current_basedn
objectclass: top
objectclass: orclNetService
cn: $current_cn
orclNetDescString: $NetDescString

EOI
                # check if last command did run successfully
                if [ $? -ne 0 ]; then clean_quit 33 "$ldapadd_command"; fi
                entries_loaded=$((entries_loaded+1))  # Count loaded entries
            else
                echo "INFO : Dry run enabled, skip add Net Service Name $current_cn in $current_basedn"
            fi
        else
            if force_enabled; then
                echo "INFO : Modify Net Service Name $net_service in $current_basedn"
                if ! dryrun_enabled; then
                    ldapmodify -h ${TVDLDAP_LDAPHOST} -p ${TVDLDAP_LDAPPORT} \
                        ${current_binddn:+"$current_binddn"} \
                        ${current_bindpwd} ${ldapmodify_options} <<-EOI
dn: cn=$current_cn,cn=OracleContext,$current_basedn
changetype: modify
replace: orclNetDescString
orclNetDescString: $NetDescString

EOI
                    # check if last command did run successfully
                    if [ $? -ne 0 ]; then clean_quit 33 "ldapmodify"; fi
                    entries_loaded=$((entries_loaded+1))  # Count loaded entries
                else
                    echo "INFO : Dry run enabled, skip modify Net Service Name $current_cn in $current_basedn"
                fi
            else
                echo "WARN : Net Service Name does exists in $current_basedn, skip ${net_service}"
                echo "# Net Service Name does exists in $current_basedn, skip ${net_service}" >>"${file}_skip"
                echo "${net_service}=${NetDescString}" >>"${file}_skip"
                entries_skipped=$((entries_skipped+1))      # Count skipped entries
            fi
        fi
    done < <(cat ${file}|sed -e 's/^#\s*$/DELIM/g' -e 's/^\s*$/DELIM/g'|grep -v '^#'| sed -e 's/\s*//g' -e '/^[a-zA-Z0-9.]*=/s/^/DELIM\n/'|tr -d '\n'| sed -e 's/DELIM/\n/g' -e 's/$/\n/' |sed '/^$/d')
done
echo "INFO : Status information about the loading process"
echo "INFO : Processed files        = $files_processed"
echo "INFO : Processed TNS entries  = $entries_processed"
echo "INFO : Loaded TNS entries     = $entries_loaded"
echo "INFO : Skipped TNS entries    = $entries_skipped"
echo "INFO : Rejected TNS entries   = $entries_rejected"

rotate_logfiles                     # purge log files based on TVDLDAP_KEEP_LOG_DAYS
clean_quit                          # clean exit with return code 0
# --- EOF ----------------------------------------------------------------------
