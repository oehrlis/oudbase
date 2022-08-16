#!/bin/bash
# ----------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------------
# Name.......: tns_dump.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.12.14
# Revision...: 
# Purpose....: Dump entries as tnsnames.ora
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ----------------------------------------------------------------------------
# - Customization ------------------------------------------------------------
# - just add/update any kind of customized environment variable here
DEFAULT_OUTPUT_DIR=$TNS_ADMIN
DEFAULT_FILE_PREFIX="ldap_dump"
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

  Usage: ${TVDLDAP_SCRIPT_NAME} [options] [bind options] [dump options]

  Common Options:
    -m                      Usage this message
    -v                      Enable verbose mode (default \$TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE})
    -d                      Enable debug mode (default \$TVDLDAP_DEBUG=${TVDLDAP_DEBUG})
    -b <BASEDN>             Specify Base DN to dump Net Service Name. Either
                            specific base DN or ALL to modify Net Service
                            Name in all available namingContexts. By the
                            default the Base DN is taken from ldap.ora
    -h <HOST>               LDAP server (default take from ldap.ora)
    -p <PORT>               port on LDAP server (default take from ldap.ora)

  Bind Options:
    -D <BINDDN>             Bind DN (default ANONYMOUS)
    -w <PASSWORD>           Bind password
    -W                      prompt for bind password
    -y <PASSWORD FILE>      Read password from file

  Dump options:
    -T <OUTPUT DIRECTORY>   Output Directory to dump the tnsnames information
                            (default $DEFAULT_OUTPUT_DIR)
    -o <OUTPUT FILE>        Output file with tnsnames dump from specified Base
                            DN (default ${DEFAULT_FILE_PREFIX}_<BASEDN>_<DATE>.ora)
    -n                      Show what would be done but do not actually do it
    -F                      Force mode to overwrite existing tnsnames dump files

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
while getopts mvdb:h:p:D:w:Wy:o:T:FE: CurOpt; do
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
        F) TVDLDAP_FORCE="TRUE";; 
        E) clean_quit "${OPTARG}";;
        *) Usage 2 $*;;
    esac
done

check_openldap_tools    # check tools required by tvdldap
dump_runtime_config     # dump current tool specific environment in debug mode

# Default values
OUTPUT_DIR=${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}
OUTPUT_FILE=${OUTPUT_FILE:-""}

# get default values for LDAP Server
TVDLDAP_LDAPHOST=${TVDLDAP_LDAPHOST:-$(get_ldaphost)}
TVDLDAP_LDAPPORT=${TVDLDAP_LDAPPORT:-$(get_ldapport)}

# get bind parameter
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
# - EOF Initialization -------------------------------------------------------
 
# - Main ---------------------------------------------------------------------
echo_debug "DEBUG: ldapsearch using:"
echo_debug "DEBUG: LDAP Host        = $TVDLDAP_LDAPHOST"
echo_debug "DEBUG: LDAP Port        = $TVDLDAP_LDAPPORT"
echo_debug "DEBUG: Bind DN          = $TVDLDAP_BINDDN"
echo_debug "DEBUG: Bind PWD         = $TVDLDAP_BINDDN_PWD"
echo_debug "DEBUG: Bind PWD File    = $TVDLDAP_BINDDN_PWDFILE"
echo_debug "DEBUG: Bind parameter   = $current_binddn $current_bindpwd"
echo_debug "DEBUG: Base DN          = $BASEDN_LIST"
echo_debug "DEBUG: Output directory = $OUTPUT_DIR"
echo_debug "DEBUG: Output file      = $OUTPUT_FILE"

echo
# loop over base DN
for basedn in ${BASEDN_LIST}; do 
    echo "INFO : Process base dn $basedn"
    domain=$(echo $basedn|sed -e 's/,dc=/\./g' -e 's/dc=//g')
    if [ -z "$OUTPUT_FILE" ]; then
        dump_file="${DEFAULT_FILE_PREFIX}_${domain}_${TIMESTAMP}.ora"
    else
        dump_file=$OUTPUT_FILE
    fi
    i=0                     # init counter to test for results
    # loop over ldapsearch results
    if [ -n "$current_binddn" ]; then           # check if bind dn is defined
        while IFS= read -r result ; do
            i=$((i+1))                          # inc counter to count results
            cn=$(echo ${result}| cut -d ';' -f 1 | cut -d " " -f 2)
            NetDescString=$(echo ${result}| cut -d ';' -f 2 | cut -d " " -f2-)
            if [ $i -eq 1 ]; then
                echo "# LDAP Net Service Description dump for base DN ${basedn}" >>${OUTPUT_DIR}/${dump_file}
                echo "# Dump Date : $(date)" >>${OUTPUT_DIR}/${dump_file}
                echo >>${OUTPUT_DIR}/${dump_file}
            fi
            echo "${cn}.${domain}=${NetDescString}" >>${OUTPUT_DIR}/${dump_file}
        done < <(ldapsearch -p ${TVDLDAP_LDAPPORT} -h ${TVDLDAP_LDAPHOST} "$current_binddn" $current_bindpwd -x -b $basedn -LLL -o "ldif-wrap=no" -s sub "(&(objectclass=orclNetService)(cn=*))" cn orclNetDescString|grep -iv '^dn: '| sed 's/$/;/g' | sed 's/^;$/DELIM/g'| tr -d '\n'| sed 's/DELIM/\n/g')
    else
        while IFS= read -r result ; do
            i=$((i+1))          # inc counter to count results
            cn=$(echo ${result}| cut -d ';' -f 1 | cut -d " " -f 2)
            NetDescString=$(echo ${result}| cut -d ';' -f 2 | cut -d " " -f2-)
            if [ $i -eq 1 ]; then
                echo "# LDAP Net Service Description dump for base DN ${basedn}" >>${OUTPUT_DIR}/${dump_file}
                echo "# Dump Date : $(date)" >>${OUTPUT_DIR}/${dump_file}
                echo >>${OUTPUT_DIR}/${dump_file}
            fi
            echo "${cn}.${domain}=${NetDescString}" >>${OUTPUT_DIR}/${dump_file}
        done < <(ldapsearch -p ${TVDLDAP_LDAPPORT} -h ${TVDLDAP_LDAPHOST} -x -b $basedn -LLL -o "ldif-wrap=no" -s sub "(&(objectclass=orclNetService)(cn=*))" cn orclNetDescString|grep -iv '^dn: '| sed 's/$/;/g' | sed 's/^;$/DELIM/g'| tr -d '\n'| sed 's/DELIM/\n/g')
    fi
    # Inform when no results found
    if [ $i -eq 0 ]; then
        echo "WARN : No service found in ${basedn}"
    else
        echo "INFO : Dump TNS Names into ${OUTPUT_DIR}/${dump_file}"
    fi
done
echo 

# purge log files
rotate_logfiles
clean_quit
# --- EOF --------------------------------------------------------------------