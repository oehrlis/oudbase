#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: tns_test.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.15
# Version....: v4.0.0
# Purpose....: Test LDAP entries using tnsping and sqlplus
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
set -o nounset # exit if script try to use an uninitialised variable
# set -o errexit                      # exit script if any statement returns a non-true return value
# set -o pipefail                     # pipefail exit after 1st piped commands failed
set -o noglob # Disable filename expansion (globbing).
# - Environment Variables ------------------------------------------------------
# define generic environment variables
VERSION=v4.0.0
TVDLDAP_VERBOSE=${TVDLDAP_VERBOSE:-"FALSE"} # enable verbose mode
TVDLDAP_DEBUG=${TVDLDAP_DEBUG:-"FALSE"}     # enable debug mode
TVDLDAP_QUIET=${TVDLDAP_QUIET:-"FALSE"}     # enable quiet mode
TVDLDAP_SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
TVDLDAP_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TVDLDAP_LOG_DIR="$(dirname ${TVDLDAP_BIN_DIR})/log"
padding='.................................................'
entries_processed=0 # Counter for processed entries
entries_ok=0        # Counter for successful entries
entries_nok=0       # Counter for failed entries

# define logfile and logging
LOG_BASE=${LOG_BASE:-"${TVDLDAP_LOG_DIR}"} # Use script log directory as default logbase
TIMESTAMP=$(date "+%Y.%m.%d_%H%M%S")
readonly LOGFILE="$LOG_BASE/$(basename $TVDLDAP_SCRIPT_NAME .sh)_$TIMESTAMP.log"

# define tempfile for ldapsearch
TEMPFILE="$LOG_BASE/$(basename $TVDLDAP_SCRIPT_NAME .sh)_$$.ldif"
TNSPING_TEMPFILE="$LOG_BASE/$(basename $TVDLDAP_SCRIPT_NAME .sh)_tnsping_$$.log"
# - EOF Environment Variables --------------------------------------------------

# - Functions ------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function...: Usage
# Purpose....: Display Usage and exit script
# ------------------------------------------------------------------------------
function Usage() {

	# define default values for function arguments
	error=${1:-"0"}      # default error number
	error_value=${2:-""} # default error message
	cat <<EOI

  Usage: ${TVDLDAP_SCRIPT_NAME} [options] [test options] [bind options] [search options] [services]

  where:
    services	        Comma separated list of Oracle Net Service Names to test

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
    -s                  Use LDAPS (SSL/TLS) with trustall option (OUD only). Can be
                        specified by setting TVDLDAP_LDAPS.
    -t <DURATION>       Specific a timeout for the test commands using core utility
                        timeout. DURATION is a number with an optional suffix: 's'
                        for seconds (the default), 'm' for minutes, 'h' for
                        hours or 'd' for days. A duration of 0 disables the
                        associated timeout.     
  
  Test Options:
    -U <USERNAME>       Username for SQLPlus test. If no username is specified,
                        the SQLPlus test will be omitted. Can be specified by
                        setting TVDLDAP_SQL_USER.
    -c <PASSWORD>       SQLPlus password. Can be specified by setting TVDLDAP_SQL_PWD.
    -C                  prompt for SQLPlus password. Can be specified by setting
                        TVDLDAP_SQL_PWDASK.
    -Z <PASSWORD FILE>  Read password from file. Can be specified by setting
                        TVDLDAP_SQL_PWDFILE.
  
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

  Configuration file:
    The script does load configuration files to define default values as an
    alternative for command line parameter. e.g. to set a bind DN TVDLDAP_BINDDN
    LDAP hostname TVDLDAP_LDAPHOST, etc. The configuration files are loaded in
    the following order:

$(get_list_of_config && echo "Command line parameter" | cat -b)

  Logfile : ${LOGFILE}

EOI
	dump_runtime_config # dump current tool specific environment in debug mode
	clean_quit ${error} ${error_value}
}
# - EOF Functions --------------------------------------------------------------

# - Initialization -------------------------------------------------------------
touch $LOGFILE 2>/dev/null   # initialize logfile
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

# define signal handling
trap on_term TERM SEGV # handle TERM SEGV using function on_term
trap on_int INT        # handle INT using function on_int
source_env             # source oudbase or base environment if it does exists
load_config            # load configur26ation files. File list in TVDLDAP_CONFIG_FILES

# initialize tempfile for the script
touch $TEMPFILE 2>/dev/null || clean_quit 25 $TEMPFILE
touch $TNSPING_TEMPFILE 2>/dev/null || clean_quit 25 $TNSPING_TEMPFILE

# get options
while getopts mvdb:h:p:sD:w:Wy:E:t:U:c:CZ:S: CurOpt; do
	case ${CurOpt} in
	m) Usage 0 ;;
	v) TVDLDAP_VERBOSE="TRUE" ;;
	d) TVDLDAP_DEBUG="TRUE" ;;
	b) TVDLDAP_BASEDN="${OPTARG}" ;;
	h) TVDLDAP_LDAPHOST=${OPTARG} ;;
	p) TVDLDAP_LDAPPORT=${OPTARG} ;;
	s) TVDLDAP_LDAPS="TRUE" ;;
	D) TVDLDAP_BINDDN="${OPTARG}" ;;
	w) TVDLDAP_BINDDN_PWD="${OPTARG}" ;;
	W) TVDLDAP_BINDDN_PWDASK="TRUE" ;;
	y) TVDLDAP_BINDDN_PWDFILE="${OPTARG}" ;;
	t) TVDLDAP_TIMEMOUT="${OPTARG}" ;;
	U) TVDLDAP_SQL_USER="${OPTARG}" ;;
	c) TVDLDAP_SQL_PWD="${OPTARG}" ;;
	C) TVDLDAP_SQL_PWDASK="TRUE" ;;
	Z) TVDLDAP_SQL_PWDFILE="${OPTARG}" ;;
	S) NETSERVICE=${OPTARG} ;;
	E) clean_quit "${OPTARG}" ;;
	*) Usage 2 $* ;;
	esac
done

check_tools      # check if we do have the required LDAP tools available
check_ldap_tools # check what kind of LDAP tools we do have e.g.
# OpenLDAP, Oracle DB or Oracle Unified Directory
dump_runtime_config # dump current tool specific environment in debug mode

# get the ldapsearch options based on available tools
ldapsearch_options=$(ldapsearch_options)
ldaps_options=$(ldaps_options)

# check if we do have a tnsping
if ! command_exists tnsping; then
	clean_quit 10 tnsping
fi

# check if we do hav a sqlplus
if ! command_exists sqlplus; then
	clean_quit 10 sqlplus
fi

# Default values
export NETSERVICE=${NETSERVICE:-""}

# check for Service and Arguments
if [ -z "$NETSERVICE" ] && [ $# -ne 0 ]; then
	echo_debug "DEBUG: Process default NETSERVICE"
	if [[ "$1" =~ ^-.* ]]; then
		echo_debug "DEBUG: Set NETSERVICE to ALL"
		NETSERVICE="ALL" # default service to * if Argument starting with dash
	else
		echo_debug "DEBUG: Set NETSERVICE to $1"
		NETSERVICE=$1 # default service to Argument if not starting with dash
	fi
else
	echo_debug "DEBUG: Set NETSERVICE to ALL"
	NETSERVICE=${NETSERVICE:-"ALL"}
fi

# get default values for LDAP Server
TVDLDAP_LDAPHOST=${TVDLDAP_LDAPHOST:-$(get_ldaphost)}
TVDLDAP_LDAPPORT=${TVDLDAP_LDAPPORT:-$(get_ldapport)}

# default time out setting
TVDLDAP_TIMEMOUT=${TVDLDAP_TIMEMOUT:-0}

# Check if timeout is defined and verify timeout command
if [ -n "$TVDLDAP_TIMEMOUT" ] && [ $TVDLDAP_TIMEMOUT -ne 0 ]; then
	if ! command_exists timeout; then
		clean_quit 10 timeout
	fi
	timeout_command="timeout $TVDLDAP_TIMEMOUT"
else
	echo "INFO : Skip test timeout as duration is set to $TVDLDAP_TIMEMOUT."
	timeout_command=""
fi

# get bind parameter
ask_bindpwd # ask for the bind password if TVDLDAP_BINDDN_PWDASK
# is TRUE and LDAP tools are not OpenLDAP
current_binddn=$(get_binddn_param "$TVDLDAP_BINDDN")
current_bindpwd=$(get_bindpwd_param "$TVDLDAP_BINDDN_PWD" ${TVDLDAP_BINDDN_PWDASK} "$TVDLDAP_BINDDN_PWDFILE")
if [ -z "$current_binddn" ] && [ -z "${current_bindpwd}" ]; then clean_quit 4; fi

# get the SQL test password if user name is defined
if [ -n "$TVDLDAP_SQL_USER" ]; then
	if [ -z "$TVDLDAP_SQL_PWD" ]; then
		# try to get the password from file if TVDLDAP_SQL_PWD is empty
		if [ -f "$TVDLDAP_SQL_PWDFILE" ]; then
			TVDLDAP_SQL_PWD=$(cat $TVDLDAP_SQL_PWDFILE)
		elif [ "${TVDLDAP_SQL_PWDASK^^}" == "TRUE" ]; then
			read -p "SQLPlus Password:" TVDLDAP_SQL_PWD
		else
			printf $TNS_INFO'\n' "WARN : No password defined. Using dummy password to run SQLPlus tests."
			TVDLDAP_SQL_PWD="tiger"
		fi
	fi
else
	printf $TNS_INFO'\n' "WARN : Skip SQLPlus test. No user name defined."
fi

# get base DN information
BASEDN_LIST=$(get_basedn "$TVDLDAP_BASEDN")
# - EOF Initialization ----------------------------------------------------------

# - Main ------------------------------------------------------------------------
echo_debug "DEBUG: Configuration / Variables:"
echo_debug "---------------------------------------------------------------------------------"
echo_debug "DEBUG: LDAP Host............... = $TVDLDAP_LDAPHOST"
echo_debug "DEBUG: LDAP Port............... = $TVDLDAP_LDAPPORT"
echo_debug "DEBUG: LDAPS / SSL............. = $TVDLDAP_LDAPS"
echo_debug "DEBUG: Bind DN................. = $TVDLDAP_BINDDN"
echo_debug "DEBUG: Bind PWD................ = $(echo_secret $TVDLDAP_BINDDN_PWD)"
echo_debug "DEBUG: Bind PWD File........... = $TVDLDAP_BINDDN_PWDFILE"
echo_debug "DEBUG: Bind parameter.......... = $current_binddn $(echo_secret $current_bindpwd)"
echo_debug "DEBUG: Base DN................. = $BASEDN_LIST"
echo_debug "DEBUG: Net Service Names....... = $NETSERVICE"
echo_debug "DEBUG: ldapsearch options...... = $ldapsearch_options"
echo_debug "DEBUG: ldaps options........... = $ldaps_options"
echo_debug "DEBUG: Command Timeout......... = $TVDLDAP_TIMEMOUT"
echo_debug "DEBUG: SQL Test User........... = $TVDLDAP_SQL_USER"
echo_debug "DEBUG: SQL Test PWD............ = $TVDLDAP_SQL_PWD"
echo_debug "DEBUG: SQL Test PWD File....... = $TVDLDAP_SQL_PWDFILE"
echo_debug "DEBUG: "

for service in $( # loop over service
	echo $NETSERVICE | tr "," "\n"
); do
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
	echo_debug "DEBUG: current Net Service Names... = $current_cn"
	for basedn in ${BASEDN_LIST}; do # loop over base DN
		if basedn_exists ${basedn}; then
			echo "INFO : Process base dn $basedn"
			domain=$(echo $basedn | sed -e 's/,dc=/\./g' -e 's/dc=//g')
			if ! alias_enabled; then
				# run ldapsearch an write output to tempfile
				ldapsearch -h ${TVDLDAP_LDAPHOST} -p ${TVDLDAP_LDAPPORT} \
					${ldaps_options} \
					${current_binddn:+"$current_binddn"} ${current_bindpwd} \
					${ldapsearch_options} -b "$basedn" -s sub \
					"(&(cn=${current_cn})(|(objectClass=orclNetService)(objectClass=orclService)(objectClass=orclNetServiceAlias)))" \
					cn orclNetDescString aliasedObjectName >$TEMPFILE
				# check if last command did run successfully
				if [ $? -ne 0 ]; then clean_quit 33 "ldapsearch"; fi
			fi
			# check if tempfile does exist and has some values
			if [ -s "$TEMPFILE" ]; then
				echo "" >>$TEMPFILE # add a new line to the tempfile
				# loop over ldapsearch results
				for result in $(grep -iv '^dn: ' $TEMPFILE | sed -n '1 {h; $ !d}; $ {x; s/\n //g; p}; /^ / {H; d}; /^ /! {x; s/\n //g; p}' | sed 's/$/;/g' | sed 's/^;$/DELIM/g' | tr -d '\n' | sed 's/DELIM/\n/g' | tr -d ' '); do
					echo_debug "DEBUG: ${result}"
					cn=$(echo ${result} | sed 's/;*$//g' | sed 's/.*cn:\(.*\)\(;.*\|$\)/\1/')
					# check for aliasedObjectName or orclNetDescString
					if [[ "$result" == *orclNetDescString* ]]; then
						NetDescString=$(echo ${result} | sed 's/;*$//g' | sed 's/.*orclNetDescString:\(.*\)\(;.*\|$\)/\1/')
					elif [[ "$result" == *aliasedObjectName* ]]; then
						NetDescString=$(echo ${result} | cut -d ';' -f 2 | cut -d " " -f2- | sed 's/aliasedObjectName://gi')
						NetDescString="$(split_net_service_cn ${NetDescString}).${domain}"
					fi
					current_netservice="${cn}.${domain}"

					# add a few debug messages
					echo_debug "DEBUG: Query result.... : ${result}"
					echo_debug "DEBUG: cn.............. : $cn"
					echo_debug "DEBUG: NetDescString... : $NetDescString"

					# run tnsping checks for the Net Service Connect String
					printf "INFO : Test Net Service Connect String for %s %s" "${current_netservice}" "${padding:${#current_netservice}}"
					tnsping_error=0
					$timeout_command tnsping "${NetDescString}" >$TNSPING_TEMPFILE 2>&1 || tnsping_error=$?
					TNSPING_STATUS=$(cat $TNSPING_TEMPFILE)
					if [[ $tnsping_error -ne 0 ]] || [[ $TNSPING_STATUS == *"TNS-"* ]]; then
						# Handle error if tnsping return something with TNS-
						TNSERR=$(echo "$TNSPING_STATUS" | sed -n 's/.*\(TNS\-[0-9]*\).*/\1/p')
						TNSERR=${TNSERR:-"timed out ${TVDLDAP_TIMEMOUT}s"}
						echo "NOK ($TNSERR)"
						entries_nok=$((entries_nok + 1)) # Count processed entries
						echo "# tnsping error/timeout $TNSERR" >>"$(dirname $LOGFILE)/$(basename $LOGFILE .log).errors.log"
						echo "${cn}.${domain}=${NetDescString}" >>"$(dirname $LOGFILE)/$(basename $LOGFILE .log).errors.log"
					else
						# Prozess sqlplus check if a login user is defined and tnsping does not create an error
						if [ -n "$TVDLDAP_SQL_USER" ] && [ -n "$TVDLDAP_SQL_PWD" ]; then
							SQLPLUS_STATUS=$(
								sqlplus -S -L /nolog <<EOFSQL
connect $TVDLDAP_SQL_USER/$TVDLDAP_SQL_PWD@${NetDescString}
EOFSQL
							)
							# Check return code for 0 / successfull
							if [[ ($? -eq 0) && ($SQLPLUS_STATUS == *"ORA-01017"* || $SQLPLUS_STATUS == *"ORA-28000"* || -z "$SQLPLUS_STATUS") ]]; then
								echo "OK  (tnsping, sqlplus)"
								entries_ok=$((entries_ok + 1)) # Count processed entries
							else
								# all other case should report not OK
								ORAERR=$(echo "$SQLPLUS_STATUS" | sed -n 's/.*\(ORA\-[0-9]*\).*/\1/p')
								echo "NOK ($ORAERR)"
								entries_nok=$((entries_nok + 1))
								echo "# SQLPlus login error $ORAERR" >>"$(dirname $LOGFILE)/$(basename $LOGFILE .log).errors.log"
								echo "${cn}.${domain}=${NetDescString}" >>"$(dirname $LOGFILE)/$(basename $LOGFILE .log).errors.log"
							fi
						else
							echo "OK  (tnsping)"
							entries_ok=$((entries_ok + 1)) # Count processed entries
						fi
					fi
					entries_processed=$((entries_processed + 1)) # Count processed entries
				done
			else
				printf $TNS_INFO'\n' "WARN : No service found in ${basedn}"
			fi
		else
			printf $TNS_INFO'\n' "WARN : Base DN ${basedn} not found"
		fi
	done
done

echo "INFO :"
echo "INFO : Status information about the tns test process"
echo "INFO : Processed BaseDN...... = $BASEDN_LIST"
echo "INFO : Tested TNS entries.... = $entries_processed"
echo "INFO : Successful tests...... = $entries_ok"
echo "INFO : failed tests.......... = $entries_nok"

rotate_logfiles # purge log files based on TVDLDAP_KEEP_LOG_DAYS
clean_quit      # clean exit with return code 0
# --- EOF ----------------------------------------------------------------------
