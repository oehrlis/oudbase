#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: tns_dump.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.02
# Version....: v2.12.4
# Purpose....: Dump entries as tnsnames.ora
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------
# - just add/update any kind of customized environment variable here
DEFAULT_OUTPUT_DIR=${TNS_ADMIN}
DEFAULT_FILE_PREFIX="ldap_dump"
# - End of Customization -------------------------------------------------------

# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# https://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -o nounset                      # exit if script try to use an uninitialised variable
# set -o errexit                      # exit script if any statement returns a non-true return value
# set -o pipefail                     # pipefail exit after 1st piped commands failed
set -f
# - Environment Variables ------------------------------------------------------
# define generic environment variables
VERSION=v2.12.4
TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE:-"FALSE"}                     # enable verbose mode
TVDLDAP_DEBUG=${TVDLDAP_DEBUG:-"FALSE"}                         # enable debug mode
TVDLDAP_QUIET=${TVDLDAP_QUIET:-"FALSE"}                         # enable quiet mode
TVDLDAP_SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
TVDLDAP_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TVDLDAP_LOG_DIR="$(dirname ${TVDLDAP_BIN_DIR})/log"
DEFAULT_OUTPUT_DIR=${DEFAULT_OUTPUT_DIR:-$TVDLDAP_LOG_DIR}
DEFAULT_OUTPUT_DIR=${DEFAULT_OUTPUT_DIR:-$(pwd)}
files_processed=0                           # Counter for processed files 
entries_processed=0                         # Counter for processed entries 

# define logfile and logging
LOG_BASE=${LOG_BASE:-"${TVDLDAP_LOG_DIR}"} # Use script log directory as default logbase
TIMESTAMP=$(date "+%Y.%m.%d_%H%M%S")
readonly LOGFILE="$LOG_BASE/$(basename $TVDLDAP_SCRIPT_NAME .sh)_$TIMESTAMP.log"
# define tempfile for the script
TEMPFILE="$LOG_BASE/$(basename $TVDLDAP_SCRIPT_NAME .sh)_$$.ldif"
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

  Usage: ${TVDLDAP_SCRIPT_NAME} [options] [bind options] [dump options] [search options] [services]

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
  
  Search options:
    -S <NETSERVICE>     Oracle Net Service Names to search for
                        (default \$ORACLE_SID)

  Dump options:
    -T <OUTPUT DIR>     Output Directory to dump the tnsnames information
                        (default $DEFAULT_OUTPUT_DIR)
    -o <OUTPUT FILE>    Output file with tnsnames dump from specified Base
                        DN (default ${DEFAULT_FILE_PREFIX}_<BASEDN>_<DATE>.ora)
    -f <FORMAT>         Format the net service names either as single line or more
                        readable as multiline connect string. Possible values are
                        SINGLE, INDENTED (default $TVDLDAP_DEFAULT_DUMP_FORMAT)
    -n                  Show what would be done but do not actually do it
    -F                  Force mode to overwrite existing tnsnames dump files

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
touch $LOGFILE 2>/dev/null          # initialize logfile
exec &> >(tee -a "$LOGFILE")        # Open standard out at `$LOG_FILE` for write.  
exec 2>&1  
echo "INFO : Start ${TVDLDAP_SCRIPT_NAME} on host $(hostname) at $(date)"

# source common variables and functions from tns_functions.sh
if [ -f ${TVDLDAP_BIN_DIR}/tns_functions.sh ]; then
    . ${TVDLDAP_BIN_DIR}/tns_functions.sh
else
    echo "ERROR: Can not find common functions ${TVDLDAP_BIN_DIR}/tns_functions.sh"
    exit 5
fi

load_config                 # load configur26ation files. File list in TVDLDAP_CONFIG_FILES

# initialize tempfile for the script
touch $TEMPFILE 2>/dev/null || clean_quit 25 $TEMPFILE

# get options
while getopts mvdb:h:p:D:w:Wy:o:T:FnE:f:S: CurOpt; do
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
        T) OUTPUT_DIR="${OPTARG}";;
        o) OUTPUT_FILE="${OPTARG}";;
        f) TVDLDAP_DUMP_FORMAT="${OPTARG}";;
        F) TVDLDAP_FORCE="TRUE";;
        n) TVDLDAP_DRYRUN="TRUE";; 
        S) NETSERVICE=${OPTARG};; 
        E) clean_quit "${OPTARG}";;
        *) Usage 2 $*;;
    esac
done

check_tools             # check if we do have the required LDAP tools available
check_ldap_tools        # check what kind of LDAP tools we do have e.g. 
                        # OpenLDAP, Oracle DB or Oracle Unified Directory
dump_runtime_config     # dump current tool specific environment in debug mode

# get the ldapsearch options based on available tools
ldapsearch_options=$(ldapsearch_options)

# Default value for OUTPUT_FILE is null
OUTPUT_FILE=${OUTPUT_FILE:-""}

# set the default value for OUTPUT_DIR
if [ -z "$OUTPUT_FILE" ]; then
    # use DEFAULT_OUTPUT_DIR when OUTPUT_FILE and OUTPUT_DIR not defined
    OUTPUT_DIR=${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}
else
    # use PATH of OUTPUT_FILE when OUTPUT_FILE defined and OUTPUT_DIR not defined
    OUTPUT_DIR=${OUTPUT_DIR:-$(dirname $OUTPUT_FILE)}
fi

export NETSERVICE=${NETSERVICE:-""}

# check for Service and Arguments
if [ -z "$NETSERVICE" ] && [ $# -ne 0 ]; then
    echo_debug "DEBUG: Process default NETSERVICE"
    if [[ "$1" =~ ^-.*  ]]; then
        echo_debug "DEBUG: Set NETSERVICE to ALL"
        NETSERVICE="ALL"          # default service to * if Argument starting with dash 
    else
        echo_debug "DEBUG: Set NETSERVICE to $1"
        NETSERVICE=$1             # default service to Argument if not starting with dash
    fi
else
    echo_debug "DEBUG: Set NETSERVICE to ALL"
    NETSERVICE=${NETSERVICE:-"ALL"}
fi

# get default values for LDAP Server
TVDLDAP_LDAPHOST=${TVDLDAP_LDAPHOST:-$(get_ldaphost)}
TVDLDAP_LDAPPORT=${TVDLDAP_LDAPPORT:-$(get_ldapport)}
# get default values for dump format
TVDLDAP_DUMP_FORMAT=${TVDLDAP_DUMP_FORMAT:-$TVDLDAP_DEFAULT_DUMP_FORMAT}
# get bind parameter
ask_bindpwd                         # ask for the bind password if TVDLDAP_BINDDN_PWDASK
                                    # is TRUE and LDAP tools are not OpenLDAP
current_binddn=$(get_binddn_param "$TVDLDAP_BINDDN" )
current_bindpwd=$(get_bindpwd_param "$TVDLDAP_BINDDN_PWD" ${TVDLDAP_BINDDN_PWDASK} "$TVDLDAP_BINDDN_PWDFILE")
if [ -n "$current_binddn" ] && [ -z "${current_bindpwd}" ]; then clean_quit 4; fi

# get base DN information
BASEDN_LIST=$(get_basedn "$TVDLDAP_BASEDN")

# check if we can write output
if [ ! -w "${OUTPUT_DIR}" ]; then
    clean_quit 21 "${OUTPUT_DIR}"
fi

# Check if output already does exists
if [ -n "$OUTPUT_FILE" ]; then
    OUTPUT_FILE=$(basename "$OUTPUT_FILE")
    if [ -f "${OUTPUT_DIR}/${OUTPUT_FILE}" ] && ! force_enabled; then
        clean_quit 20 "${OUTPUT_DIR}/${OUTPUT_FILE}"
    elif [ -f "${OUTPUT_DIR}/${OUTPUT_FILE}" ] && force_enabled; then
        rm ${OUTPUT_DIR}/${OUTPUT_FILE}
    fi
fi
# - EOF Initialization ----------------------------------------------------------
 
# - Main ------------------------------------------------------------------------
echo_debug "DEBUG: Configuration / Variables:"
echo_debug "---------------------------------------------------------------------------------"
echo_debug "DEBUG: LDAP Host............... = $TVDLDAP_LDAPHOST"
echo_debug "DEBUG: LDAP Port............... = $TVDLDAP_LDAPPORT"
echo_debug "DEBUG: Bind DN................. = $TVDLDAP_BINDDN"
echo_debug "DEBUG: Bind PWD................ = $TVDLDAP_BINDDN_PWD"
echo_debug "DEBUG: Bind PWD File........... = $TVDLDAP_BINDDN_PWDFILE"
echo_debug "DEBUG: Bind parameter.......... = $current_binddn $current_bindpwd"
echo_debug "DEBUG: Base DN................. = $BASEDN_LIST"
echo_debug "DEBUG: Net Service Names....... = $NETSERVICE"
echo_debug "DEBUG: Output directory........ = $OUTPUT_DIR"
echo_debug "DEBUG: Output file............. = $OUTPUT_FILE"
echo_debug "DEBUG: ldapsearch options...... = $ldapsearch_options"
echo_debug "DEBUG: "

for service in $(echo $NETSERVICE | tr "," "\n"); do  # loop over service
    echo_debug "DEBUG: process service $service"
    # set current_cn to * for all 
    if [ "${NETSERVICE^^}" == "ALL" ]; then
        current_basedn=""
        current_cn="*"
        echo_debug "DEBUG: current Net Service Names    = $NETSERVICE"
    else
        current_basedn=$(split_net_service_basedn ${service})
        current_cn=$(split_net_service_cn ${service})
        echo_debug "DEBUG: current Net Service Names    = $current_cn"
    fi
    
    # Set BASEDN_LIST to current Base DN taken from Net Service Name
    if [ -n "${current_basedn}" ]; then
        BASEDN_LIST=${current_basedn}
    else 
        BASEDN_LIST=$(get_basedn "$TVDLDAP_BASEDN")
    fi

    echo_debug "DEBUG: current Base DN list........ = $BASEDN_LIST"
    for basedn in ${BASEDN_LIST}; do                # loop over base DN
        if basedn_exists ${basedn}; then
            echo "INFO : Process base dn $basedn"
            domain=$(echo $basedn|sed -e 's/,dc=/\./g' -e 's/dc=//g')
            if [ -z "$OUTPUT_FILE" ]; then
                dump_file="${DEFAULT_FILE_PREFIX}_${domain}_${TIMESTAMP}.ora"
                files_processed=$((files_processed+1))  # Count processed files
            else
                dump_file=$OUTPUT_FILE
                files_processed=1
            fi

            if ! dryrun_enabled; then
                echo "INFO : Dump Net Service Names from $basedn to ${OUTPUT_DIR}/${dump_file}"
                echo "# LDAP Net Service Description dump for base DN ${basedn}" >>${OUTPUT_DIR}/${dump_file}
                echo "# Dump Date : $(date)" >>${OUTPUT_DIR}/${dump_file}
                if ! alias_enabled; then
                    # run ldapsearch an write output to tempfile
                    ldapsearch -h ${TVDLDAP_LDAPHOST} -p ${TVDLDAP_LDAPPORT} \
                        ${current_binddn:+"$current_binddn"} ${current_bindpwd} \
                        ${ldapsearch_options} -b "$basedn" -s sub \
                        "(&(cn=${current_cn})(|(objectClass=orclNetService)(objectClass=orclService)(objectClass=orclNetServiceAlias)))" \
                        cn orclNetDescString aliasedObjectName>$TEMPFILE
                    # check if last command did run successfully
                    if [ $? -ne 0 ]; then clean_quit 33 "ldapsearch"; fi
                fi
                # check if tempfile does exist and has some values
                if [ -s "$TEMPFILE" ] ; then
                    echo "" >> $TEMPFILE    # add a new line to the tempfile
                    # loop over ldapsearch results
                    for result in $(grep -iv '^dn: ' $TEMPFILE | sed -n '1 {h; $ !d}; $ {x; s/\n //g; p}; /^ / {H; d}; /^ /! {x; s/\n //g; p}'| sed 's/$/;/g' | sed 's/^;$/DELIM/g' | tr -d '\n'| sed 's/DELIM/\n/g'|tr -d ' '); do
                        echo_debug "DEBUG: ${result}"
                        cn=$(echo ${result}|sed 's/;*$//g'|sed 's/.*cn:\(.*\)\(;.*\|$\)/\1/')
                        # check for aliasedObjectName or orclNetDescString
                        if [[ "$result" == *orclNetDescString* ]]; then
                            NetDescString=$(echo ${result}|sed 's/;*$//g'|sed 's/.*orclNetDescString:\(.*\)\(;.*\|$\)/\1/')
                            if [ "${TVDLDAP_DUMP_FORMAT^^}" == "INDENTED" ] ; then
                                echo "${cn}.${domain}=${NetDescString}" | tidy_dotora >>${OUTPUT_DIR}/${dump_file}
                            else
                                echo "${cn}.${domain}=${NetDescString}" | join_dotora >>${OUTPUT_DIR}/${dump_file}
                            fi
                        elif [[ "$result" == *aliasedObjectName* ]]; then
                            aliasedObjectName=$(echo ${result}|sed 's/;*$//g'|sed 's/.*aliasedObjectName:\(.*\)\(;.*\|$\)/\1/')
                            echo "# ${cn}.${domain} alias to ${aliasedObjectName}" >>${OUTPUT_DIR}/${dump_file}
                        fi
                    done
                else
                    echo "WARN : No Net Service Name / Alias found in ${basedn}"
                    echo "# No Net Service Name / Alias found in ${basedn}" >>${OUTPUT_DIR}/${dump_file}   
                fi
                echo >>${OUTPUT_DIR}/${dump_file}
                entries_processed=$((entries_processed+1))  # Count processed entries
            else
                echo "INFO : Dry run enabled, skip dump Net Service Names from $basedn to ${OUTPUT_DIR}/${dump_file}"
            fi
        else
            echo "WARN : Base DN ${basedn} not found"
        fi
    done
done

echo "INFO : Status information about the dumping process"
echo "INFO : Processed BaseDN...... = $BASEDN_LIST"
echo "INFO : Processed files....... = $files_processed"
echo "INFO : Dumped TNS entries.... = $entries_processed"

rotate_logfiles                     # purge log files based on TVDLDAP_KEEP_LOG_DAYS
clean_quit                          # clean exit with return code 0
# --- EOF ----------------------------------------------------------------------
