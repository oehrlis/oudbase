#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oudenv.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.12
# Version....: v4.0.0
# Purpose....: Bash Source File to set the environment for OUD Instances
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - Environment Variables ------------------------------------------------------
# Definition of default values for environment variables, if not defined
# externally. In principle, these variables should not be changed at this
# point. The customization should be done externally in .bash_profile or
# in oudenv_core.conf.
VERSION=v4.0.0

# define some binaries for later user
PGREP_BIN=$(command -v pgrep)                                 # get the binary for pgrep
SHA1SUM_BIN=$(command -v sha1sum)                             # get the binary for sha1sum
HOSTNAME_BIN=$(command -v hostname)                           # get the binary for hostname
HOSTNAME_BIN=${HOSTNAME_BIN:-"cat /proc/sys/kernel/hostname"} # fallback to /proc/sys/kernel/hostname
SOURCED=${SOURCED:-0}                                         # define default value for source
export HOST=$("${HOSTNAME_BIN}")

# Absolute path of script directory
OUDENV_SCRIPT_DIR="$(
	cd "$(dirname "${BASH_SOURCE[0]}")"
	pwd -P
)"
# Recreate admin directory and *.conf files
RECREATE="TRUE"

# OUDTAB string pattern used to search entries
ORATAB_PATTERN='^[a-zA-Z0-9_-]*:([0-9]*:){4}O(UD|UDSM|ID|DSEE)(:(N|Y|D))?$'
ORATAB_PATTERN_OUD='^[a-zA-Z0-9_-]*:([0-9]*:){4}OUD(:(N|Y|D))?$'
# OUDTAB header
OUDTAB_COMMENT=$(
	cat <<COMMENT
# OUD Config File
#  1: OUD Instance Name
#  2: OUD LDAP Port
#  3: OUD LDAPS Port
#  4: OUD Admin Port
#  5: OUD Replication Port
#  6: Directory type eg. OUD, OID, ODSEE or OUDSM
#  7: Flag for start/stop eg. (N)o, (Y)es or (D)ummy
# ------------------------------------------------------------------------------
COMMENT
)

# Default values for file and folder names
DEFAULT_OUD_BASE_NAME="oudbase"
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUDSM_DOMAIN_BASE_NAME="domains"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_OUD_LOCAL_BASE_BIN_NAME="bin"
DEFAULT_OUD_LOCAL_BASE_ETC_NAME="etc"
DEFAULT_OUD_LOCAL_BASE_LOG_NAME="log"
DEFAULT_OUD_LOCAL_BASE_TEMPLATES_NAME="templates"
DEFAULT_PRODUCT_BASE_NAME="product"
DEFAULT_ORACLE_HOME_NAME="fmw12.2.1.4.0"
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.4.0"
OUD_CORE_CONFIG="oudenv_core.conf"
# default Ports
DEFAULT_PORT=1389
DEFAULT_PORT_SSL=1636
DEFAULT_PORT_ADMIN=4444
DEFAULT_PORT_REP=8989

# Default ORACLE_BASE based on script path
DEFAULT_ORACLE_BASE=${OUDENV_SCRIPT_DIR%%/${DEFAULT_OUD_LOCAL_BASE_NAME}/${DEFAULT_OUD_BASE_NAME}/${DEFAULT_OUD_LOCAL_BASE_BIN_NAME}}

# default ORACLE_BASE or OUD_BASE
export ORACLE_BASE=${ORACLE_BASE:-${DEFAULT_ORACLE_BASE}}
export OUD_BASE=${OUD_BASE:-"${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/${DEFAULT_OUD_BASE_NAME}"}
export OUD_LOCAL=${OUD_LOCAL:-"$(dirname "${OUD_BASE}")"}

# set the ETC_CORE to the oud base directory
export ETC_CORE=${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}

# source the core oudenv customization (after functions are defined below)
# Note: safe_source function is defined in the functions section
# This is deferred until after function definitions

# define location for OUD data
export OUD_DATA=${OUD_DATA:-"${ORACLE_BASE}"}
export ORACLE_DATA=${ORACLE_DATA:-"${OUD_DATA}"}

# define misc base directories
export OUD_ADMIN_BASE=${OUD_ADMIN_BASE:-"${OUD_DATA}/${DEFAULT_OUD_ADMIN_BASE_NAME}"}
export OUD_BACKUP_BASE=${OUD_BACKUP_BASE:-"${OUD_DATA}/${DEFAULT_OUD_BACKUP_BASE_NAME}"}
export OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-"${OUD_DATA}/${DEFAULT_OUD_INSTANCE_BASE_NAME}"}
export OUDSM_DOMAIN_BASE=${OUDSM_DOMAIN_BASE:-"${OUD_DATA}/${DEFAULT_OUDSM_DOMAIN_BASE_NAME}"}

# define default home directories
export ORACLE_HOME=${ORACLE_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_HOME_NAME}"}
export ORACLE_FMW_HOME=${ORACLE_FMW_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_FMW_HOME_NAME}"}
export JAVA_HOME=${JAVA_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/java"}

# set directory type
DEFAULT_DIRECTORY_TYPE="OUD"
export DIRECTORY_TYPE=${DIRECTORY_TYPE:-"${DEFAULT_DIRECTORY_TYPE}"}
# - EOF Environment Variables --------------------------------------------------

# - Functions ------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Logging and Error Handling Functions
# ------------------------------------------------------------------------------

# Log file location (optional - if set, logs to file; otherwise stderr only)
LOG_FILE=${LOG_FILE:-""}
LOG_LEVEL=${LOG_LEVEL:-"INFO"} # DEBUG, INFO, WARN, ERROR

function log_message() {
	# Purpose: Centralized logging function with level support
	# Usage: log_message LEVEL "message" [sanitize_flag]
	local level="${1:-INFO}"
	local message="${2:-}"
	local sanitize="${3:-false}"
	local timestamp
	timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	# Sanitize sensitive information if requested
	if [[ "${sanitize}" == "true" ]]; then
		# Remove common password patterns
		message=$(echo "${message}" | sed -E 's/(password|passwd|pwd|secret|token)=[^[:space:]]*/\1=***REDACTED***/gi')
		message=$(echo "${message}" | sed -E 's/(bindpw|bind_pw|admin_pw)[[:space:]]*=[[:space:]]*[^[:space:]]*/\1=***REDACTED***/gi')
	fi

	# Format log message
	local log_entry="[${timestamp}] [${level}] ${message}"

	# Output based on level
	case "${level}" in
	ERROR)
		echo "${log_entry}" >&2
		[[ -n "${LOG_FILE}" ]] && echo "${log_entry}" >>"${LOG_FILE}"
		;;
	WARN)
		echo "${log_entry}" >&2
		[[ -n "${LOG_FILE}" ]] && echo "${log_entry}" >>"${LOG_FILE}"
		;;
	INFO)
		[[ "${LOG_LEVEL}" =~ ^(DEBUG|INFO)$ ]] && echo "${log_entry}"
		[[ -n "${LOG_FILE}" ]] && echo "${log_entry}" >>"${LOG_FILE}"
		;;
	DEBUG)
		[[ "${LOG_LEVEL}" == "DEBUG" ]] && echo "${log_entry}"
		[[ -n "${LOG_FILE}" ]] && echo "${log_entry}" >>"${LOG_FILE}"
		;;
	esac
}

function log_error() {
	# Purpose: Log error message
	# Usage: log_error "error message" [sanitize_flag]
	log_message "ERROR" "$1" "${2:-false}"
}

function log_warn() {
	# Purpose: Log warning message
	# Usage: log_warn "warning message" [sanitize_flag]
	log_message "WARN" "$1" "${2:-false}"
}

function log_info() {
	# Purpose: Log info message
	# Usage: log_info "info message" [sanitize_flag]
	log_message "INFO" "$1" "${2:-false}"
}

function log_debug() {
	# Purpose: Log debug message
	# Usage: log_debug "debug message"
	log_message "DEBUG" "$1" false
}

function log_security() {
	# Purpose: Log security-relevant operations
	# Usage: log_security "security event description"
	local message="[SECURITY] $1"
	log_message "INFO" "${message}" false

	# Optionally write to separate security log
	if [[ -n "${SECURITY_LOG_FILE:-}" ]]; then
		local timestamp
		timestamp=$(date '+%Y-%m-%d %H:%M:%S')
		echo "[${timestamp}] ${message}" >>"${SECURITY_LOG_FILE}"
	fi
}

function handle_error() {
	# Purpose: Centralized error handling with exit option
	# Usage: handle_error exit_code "error message" [exit_flag]
	local exit_code="${1:-1}"
	local message="${2:-Unknown error}"
	local should_exit="${3:-false}"

	log_error "${message}"

	if [[ "${should_exit}" == "true" ]]; then
		exit "${exit_code}"
	fi

	return "${exit_code}"
}

# ------------------------------------------------------------------------------
# Input Validation and Sanitization Functions
# ------------------------------------------------------------------------------

function validate_instance_name() {
	# Purpose....: Validate OUD instance name to prevent security issues
	# Parameters.: $1 - Instance name to validate
	# Returns....: 0 on success, 1 on failure
	# ------------------------------------------------------------------------------
	local name="$1"

	# Check if empty
	if [[ -z "${name}" ]]; then
		log_error "Instance name cannot be empty"
		return 1
	fi

	# Allow only alphanumeric, underscore, hyphen
	if [[ ! "${name}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
		log_error "Invalid instance name '${name}'"
		log_error "Only alphanumeric characters, underscore, and hyphen are allowed"
		return 1
	fi

	# Check length (max 255 chars for filesystem compatibility)
	if [[ ${#name} -gt 255 ]]; then
		log_error "Instance name too long: ${#name} characters (max 255)"
		return 1
	fi

	# Prevent path traversal patterns
	if [[ "${name}" == *".."* ]] || [[ "${name}" == *"/"* ]]; then
		log_error "Instance name contains invalid path characters"
		return 1
	fi

	# Prevent reserved names
	case "${name}" in
	"." | ".." | "~" | "SILENT" | "silent")
		log_error "Instance name '${name}' is reserved"
		return 1
		;;
	esac

	return 0
}

function validate_port() {
	# Purpose....: Validate and normalize port numbers
	# Parameters.: $1 - Port number to validate
	#              $2 - Port name/description (optional)
	# Returns....: Normalized port number on success, empty on failure
	# ------------------------------------------------------------------------------
	local port="$1"
	local port_name="${2:-Port}"

	# Check if empty (some ports are optional)
	if [[ -z "${port}" ]]; then
		echo ""
		return 0 # Empty is OK for optional ports
	fi

	# Check if numeric (no letters, special chars)
	if [[ ! "${port}" =~ ^[0-9]+$ ]]; then
		log_error "${port_name} must be numeric: '${port}'"
		return 1
	fi

	# Remove leading zeros to prevent octal interpretation and normalize
	port=$((10#${port}))

	# Check range (1-65535 for TCP/UDP ports)
	if ((port < 1 || port > 65535)); then
		log_error "${port_name} out of valid range (1-65535): ${port}"
		return 1
	fi

	# Return normalized port (without leading zeros)
	echo "${port}"
	return 0
}

function sanitize_path() {
	# Purpose....: Sanitize and validate file system paths
	# Parameters.: $1 - Path to sanitize
	#              $2 - Path name/description (optional)
	#              $3 - Must exist flag: "true" or "false" (optional, default: false)
	# Returns....: Sanitized absolute path on success
	# ------------------------------------------------------------------------------
	local path="$1"
	local path_name="${2:-Path}"
	local must_exist="${3:-false}"

	# Check if empty
	if [[ -z "${path}" ]]; then
		log_error "${path_name} cannot be empty"
		return 1
	fi

	# Check for dangerous patterns
	if [[ "${path}" == *".."* ]]; then
		log_error "${path_name} contains path traversal sequence '..'"
		return 1
	fi

	# Check for null bytes (path injection)
	if [[ "${path}" == *$'\0'* ]]; then
		log_error "${path_name} contains null bytes"
		return 1
	fi

	# Check existence if required
	if [[ "${must_exist}" == "true" ]] && [[ ! -e "${path}" ]]; then
		log_error "${path_name} does not exist: ${path}"
		return 1
	fi

	# Normalize path (remove trailing slashes)
	path="${path%/}"

	echo "${path}"
	return 0
}

function validate_directory_type() {
	# Purpose....: Validate directory type value
	# Parameters.: $1 - Directory type to validate
	# Returns....: Validated directory type on success
	# ------------------------------------------------------------------------------
	local dir_type="$1"

	# Check if empty
	if [[ -z "${dir_type}" ]]; then
		log_error "Directory type cannot be empty"
		return 1
	fi

	# Validate against allowed types
	case "${dir_type}" in
	"OUD" | "OUDSM" | "ODSEE")
		echo "${dir_type}"
		return 0
		;;
	*)
		log_error "Invalid directory type '${dir_type}'"
		log_error "Allowed types: OUD, OUDSM, ODSEE"
		return 1
		;;
	esac
}

function sanitize_env_var() {
	# Purpose....: Sanitize environment variable values
	# Parameters.: $1 - Variable value to sanitize
	#              $2 - Variable name/description (optional)
	# Returns....: Sanitized value on success
	# ------------------------------------------------------------------------------
	local var_value="$1"
	local var_name="${2:-Variable}"

	# Allow empty values
	if [[ -z "${var_value}" ]]; then
		echo ""
		return 0
	fi

	# Check for shell metacharacters
	if [[ "${var_value}" =~ [\$\`\;\&\|\<\>] ]]; then
		log_error "${var_name} contains dangerous shell metacharacters"
		return 1
	fi

	# Check for command substitution attempts
	if [[ "${var_value}" == *'$('* ]] || [[ "${var_value}" == *'`'* ]]; then
		log_error "${var_name} contains command substitution"
		return 1
	fi

	# Check for newlines (can break parsing)
	if [[ "${var_value}" == *$'\n'* ]]; then
		log_error "${var_name} contains newline characters"
		return 1
	fi

	echo "${var_value}"
	return 0
}

# - EOF Input Validation Functions ---------------------------------------------

# ------------------------------------------------------------------------------
# Secure File Operations Functions
# ------------------------------------------------------------------------------

function safe_source() {
	# Purpose....: Safely source configuration files with security checks
	# Parameters.: $1 - File path to source
	#              $2 - File description (optional)
	#              $3 - Required flag: "true" or "false" (optional, default: false)
	# Returns....: 0 on success, 1 on failure
	# ------------------------------------------------------------------------------
	local file="$1"
	local file_desc="${2:-Configuration file}"
	local required="${3:-false}"

	# Check if file exists
	if [[ ! -e "${file}" ]]; then
		if [[ "${required}" == "true" ]]; then
			log_error "Required ${file_desc} does not exist: ${file}"
			return 1
		else
			return 0 # Optional file missing is OK
		fi
	fi

	# Check if it's a regular file (not symlink, device, etc.)
	if [[ ! -f "${file}" ]]; then
		log_error "${file_desc} is not a regular file: ${file}"
		return 1
	fi

	# Check if it's a symlink (security risk)
	if [[ -L "${file}" ]]; then
		log_error "${file_desc} is a symbolic link: ${file}"
		log_error "Sourcing symlinks is not allowed for security reasons"
		return 1
	fi

	# Check if readable
	if [[ ! -r "${file}" ]]; then
		log_error "${file_desc} is not readable: ${file}"
		return 1
	fi

	# Check file size (prevent sourcing huge files - 1MB limit)
	local file_size
	if [[ "$(uname)" == "Darwin" ]]; then
		file_size=$(stat -f%z "${file}" 2>/dev/null || echo 0)
	else
		file_size=$(stat -c%s "${file}" 2>/dev/null || echo 0)
	fi
	if ((file_size > 1048576)); then
		log_error "${file_desc} is too large (>1MB): ${file}"
		return 1
	fi

	# Check for world-writable (security risk)
	local perms
	if [[ "$(uname)" == "Darwin" ]]; then
		perms=$(stat -f%p "${file}" 2>/dev/null)
	else
		perms=$(stat -c%a "${file}" 2>/dev/null)
	fi
	if [[ "${perms: -1}" == "2" ]] || [[ "${perms: -1}" == "6" ]]; then
		log_error "${file_desc} is world-writable: ${file}"
		return 1
	fi

	# All checks passed - log and source the file
	log_security "Sourcing ${file_desc}: ${file}"
	# shellcheck disable=SC1090
	. "${file}"
}

function create_secure_dir() {
	# Purpose....: Create directory with secure permissions
	# Parameters.: $1 - Directory path
	#              $2 - Permissions (optional, default: 0755)
	#              $3 - Directory description (optional)
	# Returns....: 0 on success, 1 on failure
	# ------------------------------------------------------------------------------
	local dir="$1"
	local perms="${2:-0755}"
	local dir_desc="${3:-Directory}"

	# Check if already exists
	if [[ -e "${dir}" ]]; then
		# Exists - verify it's actually a directory
		if [[ ! -d "${dir}" ]]; then
			log_error "${dir_desc} exists but is not a directory: ${dir}"
			return 1
		fi

		# Check if it's a symlink
		if [[ -L "${dir}" ]]; then
			log_error "${dir_desc} is a symbolic link: ${dir}"
			return 1
		fi

		return 0 # Already exists and is valid
	fi

	# Create directory with safe permissions
	mkdir -p "${dir}" || {
		log_error "Cannot create ${dir_desc}: ${dir}"
		return 1
	}

	# Set explicit permissions
	chmod "${perms}" "${dir}" || {
		echo "WARN: Cannot set permissions ${perms} on ${dir_desc}: ${dir}" >&2
	}

	return 0
}

function create_secure_temp() {
	# Purpose....: Create secure temporary file with random name
	# Parameters.: $1 - Prefix for temp file (optional, default: oudenv)
	# Returns....: Path to temp file on success
	# ------------------------------------------------------------------------------
	local prefix="${1:-oudenv}"
	local temp_file

	# Create temp file with random name
	temp_file=$(mktemp -t "${prefix}.XXXXXXXXXX") || {
		log_error "Cannot create temporary file"
		return 1
	}

	# Set restrictive permissions (owner read/write only)
	chmod 600 "${temp_file}" || {
		rm -f "${temp_file}"
		log_error "Cannot set permissions on temp file"
		return 1
	}

	# Register cleanup trap
	trap "rm -f '${temp_file}'" EXIT INT TERM

	echo "${temp_file}"
}

# - EOF Secure File Operations Functions ---------------------------------------

# ------------------------------------------------------------------------------
function get_instance_real_home {
	# Purpose....: get the corresponding PORTS from OUD Instance
	# ------------------------------------------------------------------------------
	# define the function parameter
	OUD_INSTANCE=${1:-${OUD_INSTANCE}}
	DIRECTORY_TYPE=${2:-${DIRECTORY_TYPE}}
	Silent=${3:-""}
	# get config for OUD instance
	if [ ${DIRECTORY_TYPE} == "OUD" ]; then
		# check if instance home does use a /OUD directory or not
		if [ -r "${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/OUD/config/config.ldif" ]; then
			OUD_INSTANCE_REAL_HOME="${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/OUD"
		elif [ -r "${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/config/config.ldif" ]; then
			OUD_INSTANCE_REAL_HOME="${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"
		elif [ -r "${ORACLE_FMW_HOME}/${OUD_INSTANCE}/OUD/config/config.ldif" ]; then
			OUD_INSTANCE_REAL_HOME="${ORACLE_FMW_HOME}/${OUD_INSTANCE}/OUD"
		elif [ -r "${ORACLE_FMW_HOME}/${OUD_INSTANCE}/config/config.ldif" ]; then
			OUD_INSTANCE_REAL_HOME="${ORACLE_FMW_HOME}/${OUD_INSTANCE}"
		else
			[ "${Silent}" == "" ] && log_warn "Can not determin config.ldif from OUD Instance. Please explicitly set OUD_INSTANCE_REAL_HOME."
			return 1
		fi
	elif [ "${DIRECTORY_TYPE}" == "OUDSM" ]; then
		if [ -r "${OUDSM_DOMAIN_BASE}/${OUD_INSTANCE}/config/config.xml" ]; then
			OUD_INSTANCE_REAL_HOME="${OUDSM_DOMAIN_BASE}/${OUD_INSTANCE}"
		else
			[ "${Silent}" == "" ] && log_warn "Can not determin config.ldif from OUD Instance. Please explicitly set OUD_INSTANCE_REAL_HOME."
			return 1
		fi
	elif [ "${DIRECTORY_TYPE}" == "ODSEE" ]; then
		if [ -r "${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/config/dse.ldif" ]; then
			OUD_INSTANCE_REAL_HOME="${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"
		else
			[ "${Silent}" == "" ] && log_warn "Can not determin config.ldif from OUD Instance. Please explicitly set OUD_INSTANCE_REAL_HOME."
			return 1
		fi
	fi
	echo "${OUD_INSTANCE_REAL_HOME}"
}

# ------------------------------------------------------------------------------
# Function...: update_path
# Purpose....: multipurpose function to manipulate PATH variable
# Usage......:
#   update_path /new/directory              Prepend the directory to the beginning of PATH variable
#   update_path /new/directory after        Append the directory to the end of PATH variable
#   update_path /new/directory remove       Removes the directory from PATH variable
#   update_path                             Removes any dublicates from PATH variable
# ------------------------------------------------------------------------------
function update_path() {
	directory=${1:-""}
	task=${2:-""}
	case ":${PATH}:" in
	*:"${directory}":*)
		if [ "${task}" = "remove" ]; then
			# remove directory from PATH
			PATH=:${PATH}:
			PATH=${PATH//:${directory}:/:}
			PATH=${PATH#:}
			PATH=${PATH%:}
		fi
		;;
	*)
		if [ -d "${directory}" ]; then
			if [ "${task}" = "after" ]; then
				# append directory to PATH
				PATH=${PATH}:${directory}
			else
				# prepend directory to PATH
				PATH=${directory}:${PATH}
			fi
		fi
		;;
	esac
	# make sure PATH values are in any case unique
	PATH=$(echo -n $PATH | awk -v RS=: '!($0 in a) {a[$0]; printf("%s%s", length(a) > 1 ? ":" : "", $0)}')
	# remove any leading / trailing :
	PATH=${PATH#:}
	PATH=${PATH%:}
}

# ------------------------------------------------------------------------------
function get_ports {
	# Purpose....: get the corresponding PORTS from OUD Instance
	# ------------------------------------------------------------------------------
	# define the function parameter
	OUD_INSTANCE=${1:-${OUD_INSTANCE}}
	DIRECTORY_TYPE=${2:-${DIRECTORY_TYPE}}
	Silent=${3:-""}
	# get default ports from oudtab
	OUDTAB_PORT=$(grep -E ${ORATAB_PATTERN} "${OUDTAB}" | grep -i ${OUD_INSTANCE} | head -1 | cut -d: -f2)
	OUDTAB_PORT_SSL=$(grep -E ${ORATAB_PATTERN} "${OUDTAB}" | grep -i ${OUD_INSTANCE} | head -1 | cut -d: -f3)
	OUDTAB_PORT_ADMIN=$(grep -E ${ORATAB_PATTERN} "${OUDTAB}" | grep -i ${OUD_INSTANCE} | head -1 | cut -d: -f4)
	OUDTAB_PORT_REP=$(grep -E ${ORATAB_PATTERN} "${OUDTAB}" | grep -i ${OUD_INSTANCE} | head -1 | cut -d: -f5)

	# Validate and normalize ports from oudtab
	if [[ -n "${OUDTAB_PORT}" ]]; then
		OUDTAB_PORT=$(validate_port "${OUDTAB_PORT}" "LDAP port") || {
			[ "${Silent}" == "" ] && log_warn "Invalid LDAP port in oudtab, using default" >&2
			OUDTAB_PORT="${DEFAULT_PORT}"
		}
	fi
	if [[ -n "${OUDTAB_PORT_SSL}" ]]; then
		OUDTAB_PORT_SSL=$(validate_port "${OUDTAB_PORT_SSL}" "LDAPS port") || {
			[ "${Silent}" == "" ] && log_warn "Invalid LDAPS port in oudtab, using default" >&2
			OUDTAB_PORT_SSL="${DEFAULT_PORT_SSL}"
		}
	fi
	if [[ -n "${OUDTAB_PORT_ADMIN}" ]]; then
		OUDTAB_PORT_ADMIN=$(validate_port "${OUDTAB_PORT_ADMIN}" "Admin port") || {
			[ "${Silent}" == "" ] && log_warn "Invalid Admin port in oudtab, using default" >&2
			OUDTAB_PORT_ADMIN="${DEFAULT_PORT_ADMIN}"
		}
	fi
	if [[ -n "${OUDTAB_PORT_REP}" ]]; then
		OUDTAB_PORT_REP=$(validate_port "${OUDTAB_PORT_REP}" "Replication port") || {
			[ "${Silent}" == "" ] && log_warn "Invalid Replication port in oudtab, using default" >&2
			OUDTAB_PORT_REP="${DEFAULT_PORT_REP}"
		}
	fi

	DEFAULT_PORT=${OUDTAB_PORT:-${DEFAULT_PORT}}
	DEFAULT_PORT_SSL=${OUDTAB_PORT_SSL:-${DEFAULT_PORT_SSL}}
	DEFAULT_PORT_ADMIN=${OUDTAB_PORT_ADMIN:-${DEFAULT_PORT_ADMIN}}
	DEFAULT_PORT_REP=${OUDTAB_PORT_REP:-${DEFAULT_PORT_REP}}
	DEFAULT_PORT_REST_ADMIN=""
	DEFAULT_PORT_REST_HTTP=""
	DEFAULT_PORT_REST_HTTPS=""
	# get ports for OUD instance
	if [ ${DIRECTORY_TYPE} == "OUD" ]; then
		OUD_INSTANCE_REAL_HOME=$(get_instance_real_home ${OUD_INSTANCE} ${DIRECTORY_TYPE} ${Silent})
		# check if instance home does use a /OUD directory or not
		if [ -r "${OUD_INSTANCE_REAL_HOME}/config/config.ldif" ]; then
			CONFIG="${OUD_INSTANCE_REAL_HOME}/config/config.ldif"
		else
			[ "${Silent}" == "" ] && log_warn "Can not determin config.ldif from OUD Instance. Please explicitly set your PORTS."
			return 1
		fi

		# read ports from config file
		PORT_ADMIN=$(sed -n '/ds-cfg-ldap-administration-connector/,/^$/p' "${CONFIG}" | grep -i ds-cfg-listen-port | cut -d' ' -f2)
		PORT_REST_ADMIN=$(sed -n '/ds-cfg-http-administration-connector/,/^$/p' "${CONFIG}" | grep -i ds-cfg-listen-port | cut -d' ' -f2 | head -1)
		PORT=$(sed -n '/ds-cfg-ldap-connection-handler/,/^$/p' "${CONFIG}" | sed -n '/ds-cfg-use-ssl: false/,/^$/p' | grep -i ds-cfg-listen-port | cut -d' ' -f2)
		PORT_SSL=$(sed -n '/ds-cfg-ldap-connection-handler/,/^$/p' "${CONFIG}" | sed -n '/ds-cfg-use-ssl: true/,/^$/p' | grep -i ds-cfg-listen-port | cut -d' ' -f2)
		PORT_REP=$(grep -i ds-cfg-replication-port "${CONFIG}" | cut -d' ' -f2)
		PORT_REST_HTTP=$(sed -n '/ds-cfg-http-connection-handler/,/^$/p' "${CONFIG}" | sed -n '/ds-cfg-use-ssl: true/,/^$/!p' | grep -i ds-cfg-listen-port | cut -d' ' -f2)
		PORT_REST_HTTPS=$(sed -n '/ds-cfg-http-connection-handler/,/^$/p' "${CONFIG}" | sed -n '/ds-cfg-use-ssl: true/,/^$/p' | grep -i ds-cfg-listen-port | cut -d' ' -f2)

		# Validate and normalize ports read from config
		PORT=$(validate_port "${PORT}" "LDAP port") || PORT="$DEFAULT_PORT"
		PORT_SSL=$(validate_port "${PORT_SSL}" "LDAPS port") || PORT_SSL="$DEFAULT_PORT_SSL"
		PORT_ADMIN=$(validate_port "${PORT_ADMIN}" "Admin port") || PORT_ADMIN="$DEFAULT_PORT_ADMIN"
		PORT_REP=$(validate_port "${PORT_REP}" "Replication port") || PORT_REP="$DEFAULT_PORT_REP"
		PORT_REST_ADMIN=$(validate_port "${PORT_REST_ADMIN}" "REST Admin port") || PORT_REST_ADMIN="$DEFAULT_PORT_REST_ADMIN"
		PORT_REST_HTTP=$(validate_port "${PORT_REST_HTTP}" "REST HTTP port") || PORT_REST_HTTP="$DEFAULT_PORT_REST_HTTP"
		PORT_REST_HTTPS=$(validate_port "${PORT_REST_HTTPS}" "REST HTTPS port") || PORT_REST_HTTPS="$DEFAULT_PORT_REST_HTTPS"

		# export the port variables and set default values with not specified
		export PORT=${PORT:-$DEFAULT_PORT}
		export PORT_SSL=${PORT_SSL:-$DEFAULT_PORT_SSL}
		export PORT_ADMIN=${PORT_ADMIN:-$DEFAULT_PORT_ADMIN}
		export PORT_REP=${PORT_REP:-$DEFAULT_PORT_REP}
		export PORT_REST_ADMIN=${PORT_REST_ADMIN:-$DEFAULT_PORT_REST_ADMIN}
		export PORT_REST_HTTP=${PORT_REST_HTTP:-$DEFAULT_PORT_REST_HTTP}
		export PORT_REST_HTTPS=${PORT_REST_HTTPS:-$DEFAULT_PORT_REST_HTTPS}
	# get ports for OUDSM domain
	elif [ "${DIRECTORY_TYPE}" == "OUDSM" ]; then
		# currently just use the default values for OUDSM
		# export the port variables and set default values with not specified
		export PORT=$DEFAULT_PORT
		export PORT_SSL=$DEFAULT_PORT_SSL
		export PORT_ADMIN=""
		export PORT_REP=""
	# get ports for ODSEE domain
	elif [ "${DIRECTORY_TYPE}" == "ODSEE" ]; then
		# currently just use the default values for ODSEE
		# export the port variables and set default values with not specified
		export PORT=${DEFAULT_PORT:-"7001"}
		export PORT_SSL=${DEFAULT_PORT_SSL:-"7002"}
		export PORT_ADMIN=""
		export PORT_REP=""
	fi
	# display new settings if not set to silent
	if [ "${Silent}" == "" ]; then
		echo "--------------------------------------------------------------"
		echo " Instance Name   : ${OUD_INSTANCE}"
		echo " Directory Type  : ${DIRECTORY_TYPE}"
		echo " LDAP Port       : ${PORT}"
		echo " LDAPS Port      : ${PORT_SSL}"
		echo " Admin Port      : ${PORT_ADMIN}"
		echo " Replication Port: ${PORT_REP}"
		echo " REST Admin Port : ${PORT_REST_ADMIN}"
		echo " REST http Port  : ${PORT_REST_HTTP}"
		echo " REST https Port : ${PORT_REST_HTTPS}"
		echo "--------------------------------------------------------------"
	fi
}

# ------------------------------------------------------------------------------
function update_oudtab {
	# Purpose....: update OUD tab
	# ------------------------------------------------------------------------------
	# define the function parameter
	OUD_INSTANCE=${1:-${OUD_INSTANCE}}
	DIRECTORY_TYPE=${2:-${DIRECTORY_TYPE}}
	START_STOP="N"
	Silent=${3:-""}
	# get the ports for the instance
	get_ports ${OUD_INSTANCE} ${DIRECTORY_TYPE} ${Silent}
	# get the status of the oud instance and set START_STOP if running assume up=Y, down=N, n/a=N
	START_STOP=$(get_status ${OUD_INSTANCE} | sed 's/up/Y/' | sed 's/down/N/' | sed 's/n\/a/N/')
	# Use atomic file update with temporary file to prevent TOCTOU races
	local temp_file
	temp_file=$(create_secure_temp "oudtab") || return 1

	if [ -f "${OUDTAB}" ]; then
		# Verify OUDTAB is not a symlink
		if [ -L "${OUDTAB}" ]; then
			echo "ERROR: ${OUDTAB} is a symlink, refusing to update"
			rm -f "${temp_file}"
			return 1
		fi

		# OUDTAB does exists so let's update / add an entry
		if [ $(grep -E $ORATAB_PATTERN "${OUDTAB}" | grep -iwc ${OUD_INSTANCE}) -eq 1 ]; then
			# get start/stop flag from existing oudtab assume up=Y, down=N, n/a=N
			START_STOP=$(grep -E ${ORATAB_PATTERN} "${OUDTAB}" | grep -i ${OUD_INSTANCE} | head -1 | cut -d: -f7)
			# if not define set it based on up/down
			START_STOP=${START_STOP:-"$(get_status "${OUD_INSTANCE}" | sed 's/up/Y/' | sed 's/down/N/' | sed 's/n\/a/N/')"}
			# update the OUDTAB entry
			[ "${Silent}" == "" ] && log_info "update ${OUD_INSTANCE} in ${OUDTAB} adjust flag Y/N"
			sed "/${OUD_INSTANCE}/c\\${OUD_INSTANCE}:${PORT}:${PORT_SSL}:${PORT_ADMIN}:${PORT_REP}:${DIRECTORY_TYPE}:${START_STOP}" "${OUDTAB}" >"${temp_file}"
		else
			# add a new OUDTAB entry
			[ "${Silent}" == "" ] && log_info "add ${OUD_INSTANCE} to ${OUDTAB} adjust flag Y/N"
			cat "${OUDTAB}" >"${temp_file}"
			echo "${OUD_INSTANCE}:${PORT}:${PORT_SSL}:${PORT_ADMIN}:${PORT_REP}:${DIRECTORY_TYPE}:${START_STOP}" >>"${temp_file}"
		fi
		# Atomically replace the original file
		mv -f "${temp_file}" "${OUDTAB}"
	else
		# recreate the OUDTAB and add a new entry
		log_warn "oudtab (${OUDTAB}) does not exist or is empty. Create a new one.."
		echo "${OUDTAB_COMMENT}" >"${temp_file}"
		[ "${Silent}" == "" ] && log_info "add ${OUD_INSTANCE} to ${OUDTAB} adjust flag Y/N"
		echo "${OUD_INSTANCE}:${PORT}:${PORT_SSL}:${PORT_ADMIN}:${PORT_REP}:${DIRECTORY_TYPE}:${START_STOP}" >>"${temp_file}"
		# Atomically create the file
		mv -f "${temp_file}" "${OUDTAB}"
	fi
}

# ------------------------------------------------------------------------------
function oud_status {
	# Purpose....: just display the current OUD settings
	# ------------------------------------------------------------------------------
	STATUS=$(get_status)
	DIR_STATUS="??"
	Silent=""
	OUD_INSTANCE_REAL_HOME=$(get_instance_real_home "${OUD_INSTANCE}" "${DIRECTORY_TYPE}" "${Silent}")
	if [ "${DIRECTORY_TYPE}" == "OUD" ] && [ -f "${OUD_INSTANCE_REAL_HOME}/config/config.ldif" ]; then
		DIR_STATUS="ok"
	elif [ "${DIRECTORY_TYPE}" == "ODSEE" ] && [ -f "${OUD_INSTANCE_REAL_HOME}/config/dse.ldif" ]; then
		DIR_STATUS="ok"
	elif [ "${DIRECTORY_TYPE}" == "OUDSM" ] && [ -f "${OUD_INSTANCE_REAL_HOME}/config/config.xml" ]; then
		DIR_STATUS="ok"
	fi

	get_ports "${OUD_INSTANCE}" "${DIRECTORY_TYPE}" silent       # read ports from OUD config file
	get_oracle_home "${OUD_INSTANCE}" "${DIRECTORY_TYPE}" silent # read oracle home from OUD install.path file
	# display the instance status
	echo "--------------------------------------------------------------"
	echo " Instance Name      : ${OUD_INSTANCE:-n/a}"
	echo " Instance Home ($DIR_STATUS) : ${OUD_INSTANCE_HOME:-n/a}"
	echo " Oracle Home        : ${ORACLE_HOME:-n/a}"
	echo " Instance Status    : ${STATUS:-n/a}"
	if [ "${DIRECTORY_TYPE}" == "OUD" ]; then
		echo " LDAP Port          : ${PORT:-n/a}"
		echo " LDAPS Port         : ${PORT_SSL:-n/a}"
		echo " Admin Port         : ${PORT_ADMIN:-n/a}"
		echo " Replication Port   : ${PORT_REP:-n/a}"
		echo " REST Admin Port    : ${PORT_REST_ADMIN:-n/a}"
		echo " REST http Port     : ${PORT_REST_HTTP:-n/a}"
		echo " REST https Port    : ${PORT_REST_HTTPS:-n/a}"
	elif [ "${DIRECTORY_TYPE}" == "ODSEE" ]; then
		echo " LDAP Port          : ${PORT:-n/a}"
		echo " LDAPS Port         : ${PORT_SSL:-n/a}"
	elif [ "${DIRECTORY_TYPE}" == "OUDSM" ]; then
		echo " Console            : http://${HOST}:${PORT}/oudsm"
		echo " HTTP               : ${PORT:-n/a}"
		echo " HTTPS              : ${PORT_SSL:-n/a}"
	fi
	echo "--------------------------------------------------------------"
}

# ------------------------------------------------------------------------------
function oud_up {
	# Purpose....: display the status of the OUD instances
	# ------------------------------------------------------------------------------
	echo "TYPE  INSTANCE     STATUS PORTS          INSTANCE HOME"
	echo "----- ------------ ------ -------------- ----------------------------------"
	# loop through OUD instance list
	for i in ${OUD_INST_LIST}; do
		# get the values from OUDTAB
		PORT_ADMIN=$(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -i "${i}" | head -1 | cut -d: -f4)
		PORT=$(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -i "${i}" | head -1 | cut -d: -f2)
		PORT_SSL=$(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -i "${i}" | head -1 | cut -d: -f3)
		DIRECTORY_TYPE=$(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -i "${i}" | head -1 | cut -d: -f6)
		DIRECTORY_TYPE=${DIRECTORY_TYPE:-"${DEFAULT_DIRECTORY_TYPE}"}
		# get the instance status (up/down/n/a)
		STATUS=$(get_status "${i}")
		if [ "${DIRECTORY_TYPE}" == "OUDSM" ]; then
			INSTANCE_HOME="${OUDSM_DOMAIN_BASE}/${i}"
		else
			INSTANCE_HOME="${OUD_INSTANCE_BASE}/${i}"
		fi
		printf '%-5s %-12s %-6s %-14s %-s\n' "${DIRECTORY_TYPE}" "${i}" "${STATUS}" \
			"$(join_by / "${PORT}" "${PORT_SSL}" "${PORT_ADMIN}")" "${INSTANCE_HOME}"
	done
	echo ""
}

# ------------------------------------------------------------------------------
function proc_grep {
	# Purpose....: simulate pgrep to get the OUD / OUDSM process status
	# ------------------------------------------------------------------------------
	GrepString=${1}
	if [ -n "${GrepString}" ]; then
		GrepString=$(echo "${GrepString}" | sed 's/\(.\)/[\1]/1')
		find /proc -maxdepth 2 -type f -regex ".*/[0-9]*/cmdline" -exec grep -iH -o -a -e "${GrepString}" {} \; | tr "\0" " "
	else
		echo 0
	fi
}

# ------------------------------------------------------------------------------
function oud_pgrep {
	# Purpose....: simulate pgrep to get the OUD / OUDSM process status
	# ------------------------------------------------------------------------------
	GrepString=${1}
	if [ -n "${GrepString}" ]; then
		GrepString=$(echo "${GrepString}" | sed 's/\(.\)/[\1]/1')
		for i in $(find /proc -maxdepth 2 -type f -regex ".*/[0-9]*/cmdline" -exec grep -il -o -a -e "${GrepString}" {} \;); do
			pid=$(echo "${i//[^0-9]/}")
			ppid=$(grep -i ppid "/proc/${pid}/status" | cut -d: -f2 | xargs)
			user=$(grep "$(cat "/proc/${pid}/loginuid")" /etc/passwd | cut -f1 -d:)
			user=${user:-"undef"}
			cmdline=$(cat "${i}")
			printf '%-5s %-12s %-10s %-s\n' "${user}" "${pid}" "${ppid}" "${cmdline}"
		done
	else
		echo 0
	fi
}

# -----------------------------------------------------------------------
function get_status {
	# Purpose....: get the current instance / process status
	# -----------------------------------------------------------------------
	InstanceName=${1:-${OUD_INSTANCE}}
	[ "${InstanceName}" == 'n/a' ] && DirectoryType="${InstanceName}"
	# check if the instance is in the oud tab
	if [ $(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -iwc "${InstanceName}") -eq 1 ]; then
		# get the directory type from OUDTAB
		DirectoryType=$(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -i "${InstanceName}" | head -1 | cut -d: -f6)
		PGREP=${PGREP_BIN:-"proc_grep"}    # define the pgrep command, fall back to proc_grep
		PGREP_PARAMETER=${PGREP_BIN:+"-f"} # set pgrep parameter -f if using pgrep
		case "${DirectoryType}" in
		# check the process for each directory type
		"OUD") echo $(if [ $("${PGREP}" ${PGREP_PARAMETER} "org.opends.server.core.DirectoryServer.*${InstanceName}" | wc -l) -gt 0 ]; then echo 'up'; else echo 'down'; fi) ;;
		"ODSEE") echo $(if [ $("${PGREP}" ${PGREP_PARAMETER} "ns-slapd.*${InstanceName}" | wc -l) -gt 0 ]; then echo 'up'; else echo 'down'; fi) ;;
		"OUDSM") echo $(if [ $("${PGREP}" ${PGREP_PARAMETER} "wlserver.*${InstanceName}" | wc -l) -gt 0 ]; then echo 'up'; else echo 'down'; fi) ;;
		*) echo "n/a" ;;
		esac
	else
		echo "n/a"
	fi
}

function get_oracle_home {
	# Purpose....: get the corresponding ORACLE_HOME from OUD Instance
	# -----------------------------------------------------------------------
	# define the function parameter
	OUD_INSTANCE=${1:-${OUD_INSTANCE}}
	DIRECTORY_TYPE=${2:-${DIRECTORY_TYPE}}
	Silent=${3:-""}
	# get the ORACLE_HOME from the install.path currently just supported
	# for directory type OUD
	if [ "${DIRECTORY_TYPE}" == "OUD" ]; then
		OUD_INSTANCE_REAL_HOME=$(get_instance_real_home "${OUD_INSTANCE}" "${DIRECTORY_TYPE}" "${OUD_INSTANCE}")
		if [ -r "${OUD_INSTANCE_REAL_HOME}/install.path" ]; then
			ORACLE_HOME=$(cat "${OUD_INSTANCE_REAL_HOME}/install.path")
			# check if our install path contains an oud at the end
			if [ "$(basename "${ORACLE_HOME}")" == "oud" ]; then
				# seems we have an OUD 12 home
				export ORACLE_HOME=$(dirname "${ORACLE_HOME}")
			else
				# seems we have an OUD 11 home
				export ORACLE_HOME=${ORACLE_HOME}
			fi
		else
			if [ "${Silent}" == "" ]; then
				log_warn "Can not determin ORACLE_HOME from OUD Instance. Please explicitly set ORACLE_HOME"
			fi
		fi
		# Display the ORACLE_HOME
		if [ "${Silent}" == "" ]; then
			echo " Oracle Home    : ${ORACLE_HOME}"
		fi
	fi
}

# ------------------------------------------------------------------------------
function gen_password {
	# Purpose....: generate a password string
	# ------------------------------------------------------------------------------
	Length=${1:-12}

	# make sure, that the password length is not shorter than 4 characters
	if [ ${Length} -lt 4 ]; then
		Length=4
	fi

	# Auto generate a password
	if [ $(command -v pwgen) ]; then
		s=$(pwgen -s -1 $Length)
		echo "$s"
	else
		while true; do
			# use urandom to generate a random string
			s=$(cat /dev/urandom | tr -dc "A-Za-z0-9" | fold -w 15 | head -n 1)
			# check if the password meet the requirements
			if [[ ${#s} -ge 10 && "$s" == *[A-Z]* && "$s" == *[a-z]* && "$s" == *[0-9]* ]]; then
				echo "$s"
				break
			fi
		done
	fi
}

# ------------------------------------------------------------------------------
function oud_help {
	# Purpose....: just display help for OUD environment
	# ------------------------------------------------------------------------------
	echo "--- OUD Instances -----------------------------------------------------"
	echo ""
	echo "--- ENV Variables -----------------------------------------------------"
	echo "  ORACLE_BASE         = ${ORACLE_BASE:-n/a}"
	echo "  OUD_BASE            = ${OUD_BASE:-n/a}"
	echo "  LOG_BASE            = ${LOG_BASE:-n/a}"
	echo "  ETC_BASE            = ${ETC_BASE:-n/a}"
	echo "  ETC_CORE            = ${ETC_CORE:-n/a}"
	echo "  JAVA_HOME           = ${JAVA_HOME:-n/a}"
	echo "  ORACLE_HOME         = ${ORACLE_HOME:-n/a}"

	echo "  DIRECTORY_TYPE      = ${DIRECTORY_TYPE:-n/a}"
	if [ ${DIRECTORY_TYPE} == "OUD" ]; then
		echo "  OUD_INSTANCE        = ${OUD_INSTANCE:-n/a}"
		echo "  OUD_INSTANCE_BASE   = ${OUD_INSTANCE_BASE:-n/a}"
		echo "  OUD_INSTANCE_HOME   = ${OUD_INSTANCE_HOME:-n/a}"
		echo "  OUD_INSTANCE_ADMIN  = ${OUD_INSTANCE_ADMIN:-n/a}"
		echo "  PORT                = ${PORT:-n/a}"
		echo "  PORT_ADMIN          = ${PORT_ADMIN:-n/a}"
		echo "  PORT_REP            = ${PORT_REP:-n/a}"
		echo "  PORT_SSL            = ${PORT_SSL:-n/a}"
		echo "  PORT_REST_HTTP      = ${PORT_REST_HTTP:-n/a}"
		echo "  PORT_REST_HTTP      = ${PORT_REST_HTTP:-n/a}"
	elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
		echo "  OUD_INSTANCE        = ${OUD_INSTANCE:-n/a}"
		echo "  ORACLE_FMW_HOME     = ${ORACLE_FMW_HOME:-'n/a'}"
		echo "  OUDSM_DOMAIN_BASE   = ${OUDSM_DOMAIN_BASE:-n/a}"
		echo "  PORT                = ${PORT:-n/a}"
		echo "  PORT_SSL            = ${PORT_SSL:-n/a}"
	fi
	echo ""
	# get default aliases from oudenv.conf
	if [ -s "${ETC_BASE}/oudenv.conf" ]; then
		echo "--- Default Aliases from \${ETC_BASE}/oudenv.conf ---------------------"
		OLDIFS=$IFS # save and change IFS
		IFS=$'\n'
		for line in $(sed -n '/DEF_ALIASES/,/EOF DEF_ALIASES/p;/EOF DEF_ALIASES/q' ${ETC_BASE}/oudenv.conf); do
			# If the line starts with alias then echo the line
			if [[ ${line} == alias* ]]; then
				ALIAS=$(echo "${line}" | sed -r 's/^.*\s(.*)=('"'"'|"  ).*/\1/')
				COMMENT=$(echo "${line}" | sed -r 's/^.*(#(.*)$|(('"'"')|  ))$/\2/')
				COMMENT=${COMMENT:-"n/a"}
				printf "  %-10s %-s\n" \
					"${ALIAS}" \
					"${COMMENT}"
			fi
		done
		IFS=$OLDIFS # restore IFS
	fi
	echo ""
	# get custom aliases from oudenv_custom.conf
	if [ -s "${ETC_BASE}/oudenv_custom.conf" ]; then
		echo "--- Custom Aliases from \${ETC_BASE}/oudenv_custom.conf --------------"
		while read -r line; do
			# If the line starts with alias then echo the line
			if [[ ${line} == alias* ]]; then
				ALIAS=$(echo "${line}" | sed -r 's/^.*\s(.*)=('"'"'|"  ).*/\1/')
				COMMENT=$(echo "${line}" | sed -r 's/^.*(#(.*)$|(('"'"')|  ))$/\2/')
				COMMENT=${COMMENT:-"n/a"}
				printf "  %-10s %-s\n" \
					"${ALIAS}" \
					"${COMMENT}"
			fi
			# read the custom config file to parse/display the comments
		done <"${ETC_BASE}/oudenv_custom.conf"
		echo ""
	fi
}

# ------------------------------------------------------------------------------
function join_by {
	# Purpose....: Join array elements
	# ------------------------------------------------------------------------------
	local IFS="$1"
	shift
	echo "$*"
}

# ------------------------------------------------------------------------------
function relpath {
	# Purpose....: get the relative path of DIR1 from DIR2
	# ------------------------------------------------------------------------------
	# define the function parameter
	BaseDirectory=$1
	TargetDirectory=$2

	if [ "${BaseDirectory}" == "" ]; then
		log_warn "BaseDirectory in relpath is empty."
		caller
		return 1
	fi

	if [ "${TargetDirectory}" == "" ]; then
		log_warn "TargetDirectory in relpath is empty."
		caller
		return 1
	fi

	CommonPart=$BaseDirectory # for now
	Result=""                 # for now

	while [[ "${TargetDirectory#${CommonPart}}" == "${TargetDirectory}" ]]; do
		# no match, means that candidate common part is not correct
		# go up one level (reduce common part)
		CommonPart="$(dirname "${CommonPart}")"
		# and record that we went back, with correct / handling
		if [[ -z "${Result}" ]]; then
			Result=".."
		else
			Result="../${Result}"
		fi
	done

	if [[ "${CommonPart}" == "/" ]]; then
		# special case for root (no common path)
		Result="${Result}/"
	fi

	# since we now have identified the common part,
	# compute the non-common part
	ForwardPart="${TargetDirectory#${CommonPart}}"

	# and now stick all parts together
	if [[ -n "${Result}" ]] && [[ -n "${ForwardPart}" ]]; then
		Result="${Result}${ForwardPart}"
	elif [[ -n "${ForwardPart}" ]]; then
		# extra slash removal
		Result="${ForwardPart:1}"
	fi
	echo "${Result}"
}
# - EOF Functions --------------------------------------------------------------

# - Initialization -------------------------------------------------------------

# Now source the core oudenv customization (after functions are defined)
if [ -f "${ETC_CORE}/${OUD_CORE_CONFIG}" ]; then
	safe_source "${ETC_CORE}/${OUD_CORE_CONFIG}" "core oudenv configuration" false
fi

tty >/dev/null 2>&1
pTTY=$?

# Validate and set OUD_INSTANCE parameter
if [ -n "$1" ] && [ "$1" != "SILENT" ] && [ "$1" != "silent" ]; then
	# Validate instance name before setting
	validate_instance_name "$1" || return 1
	log_security "Setting OUD instance to: $1"
	export OUD_INSTANCE="$1"
else
	export OUD_INSTANCE=${1:-""}
fi
export SILENT=${2:-""}

# count number of execution / source
export SOURCED=$((SOURCED + 1))

# Check OUD_BASE and load if necessary
if [ "${OUD_BASE}" = "" ]; then
	if [ -f "${HOME}/.OUD_BASE" ]; then
		. "${HOME}/.OUD_BASE"
	else
		echo "ERROR: Could not load ${HOME}/.OUD_BASE"
	fi
fi

# Check if OUD_BASE exits
if [ "${OUD_BASE}" = "" ] || [ ! -d "${OUD_BASE}" ]; then
	echo "ERROR: OUD_BASE not set or \$OUD_BASE not available"
	return 1
fi

# Check if JAVA_HOME is defined
if [ "${JAVA_HOME}" == "" ]; then
	log_warn "JAVA_HOME is not set or could not be determined automatically"
fi

# store PATH on first execution otherwise reset it
if [ "${SOURCED}" -le 1 ]; then
	export OUDSAVED_PATH="${PATH}"
else
	if [ "${OUDSAVED_PATH}" ]; then
		# reset PATH to inital PATH
		export PATH="${OUDSAVED_PATH}"
	fi
fi

# set the log and etc base directory depending on OUD_DATA
if [ "${ORACLE_BASE}" == "${OUD_DATA}" ]; then
	# set LOG_BASE and ETC_BASE to OUD_BASE
	export LOG_BASE=${LOG_BASE:-${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_LOG_NAME}}
	export ETC_BASE=${ETC_BASE:-${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}}
	# set the OUDTAB to ETC_CORE since OUD_DATA is ORACLE_BASE
	export OUDTAB=${ETC_BASE}/oudtab
else
	# set LOG_BASE and ETC_BASE to OUD_DATA
	export LOG_BASE=${LOG_BASE:-${OUD_DATA}/${DEFAULT_OUD_LOCAL_BASE_LOG_NAME}}
	export ETC_BASE=${ETC_BASE:-${OUD_DATA}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}}
	# set the OUDTAB to ETC_BASE
	export OUDTAB=${ETC_BASE}/oudtab
fi

# recreate missing directories
for i in ${OUD_ADMIN_BASE} ${OUD_BACKUP_BASE} ${OUD_INSTANCE_BASE} ${ETC_BASE} ${LOG_BASE}; do
	create_secure_dir "${i}" "0755" "base directory"
done

# adjust config files in ETC_BASE if different than ETC_CORE
if [ "${ETC_BASE}" != "${ETC_CORE}" ]; then
	for i in oud._DEFAULT_.conf oudenv_custom.conf oudenv.conf oudtab; do
		if [ ! -f "${ETC_BASE}/${i}" ]; then
			if [ -f "${ETC_CORE}/${i}" ] && [ ! -L "${ETC_CORE}/${i}" ]; then
				# take the file from the $ETC_CORE folder
				log_info "move config file ${i} from \$ETC_CORE"
				# Check destination is not a symlink before moving
				if [ -e "${ETC_BASE}/${i}" ] && [ -L "${ETC_BASE}/${i}" ]; then
					echo "ERROR: Destination ${ETC_BASE}/${i} is a symlink, refusing to overwrite"
					return 1
				fi
				mv "${ETC_CORE}/${i}" "${ETC_BASE}"
			elif [ ! -f "${ETC_CORE}/${i}" ]; then
				log_info "copy config file ${i} from template folder ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_TEMPLATES_NAME}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}"
				# Validate source template is not a symlink
				template_file="${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_TEMPLATES_NAME}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}/${i}"
				if [ -L "${template_file}" ]; then
					echo "ERROR: Template file ${template_file} is a symlink, refusing to copy"
					return 1
				fi
				# Check destination is not a symlink before copying
				if [ -e "${ETC_BASE}/${i}" ] && [ -L "${ETC_BASE}/${i}" ]; then
					echo "ERROR: Destination ${ETC_BASE}/${i} is a symlink, refusing to overwrite"
					return 1
				fi
				cp "${template_file}" "${ETC_BASE}"
			fi
			# recreate softlinks for some config files
			if [ "${i}" == "oudenv.conf" ] || [ "${i}" == "oudtab" ]; then
				log_info "re-create softlink for ${i} "
				# Verify source exists and is not a symlink before creating symlink
				if [ ! -f "${ETC_BASE}/${i}" ] || [ -L "${ETC_BASE}/${i}" ]; then
					echo "ERROR: Source ${ETC_BASE}/${i} does not exist or is a symlink"
					return 1
				fi
				# Remove existing symlink if present
				[ -L "${ETC_CORE}/${i}" ] && rm -f "${ETC_CORE}/${i}"
				ln -s -v "${ETC_BASE}/${i}" "${ETC_CORE}/${i}"
			fi
		fi
	done
fi

# check if we have an oudtab file and it does have entries
if [ -f "${OUDTAB}" ] && [ $(grep -c -E $ORATAB_PATTERN "${OUDTAB}") -gt 0 ]; then
	# create a OUD Instance list based on oudtab and remove newlines|
	export OUD_INST_LIST=$(grep -E $ORATAB_PATTERN "${OUDTAB}" | cut -f1 -d: | tr '\n' ' ')
	export REAL_OUD_INST_LIST=$(grep -E $ORATAB_PATTERN_OUD "${OUDTAB}" | cut -f1 -d: | tr '\n' ' ')
else
	log_warn "oudtab (${OUDTAB}) does not exist or is empty. Create a new one."
	echo "${OUDTAB_COMMENT}" >"${OUDTAB}"
	unset OUD_INST_LIST
	# create a OUD Instance Liste based on OUD instance base
	for i in ${OUD_INSTANCE_BASE}/*/OUD/config/config.ldif \
		${OUD_INSTANCE_BASE}/*/config/config.ldif \
		${ORACLE_FMW_HOME}/*/OUD/config/config.ldif \
		${ORACLE_FMW_HOME}/*/config/config.ldif; do
		# if the config.ldif file exists use it to get instance name
		if [ -f "${i}" ] && [ ! "${i}" == "${ORACLE_FMW_HOME}/oud/config/config.ldif" ]; then
			# remove leading OUD instance path
			i=${i##"${OUD_INSTANCE_BASE}/"}
			# remove trailing OUD* and config*
			i=${i%%/O*.ldif}
			i=${i%%/config*.ldif}
			# add oudtab entry
			update_oudtab "${i}" OUD silent
			export OUD_INST_LIST+="$(echo "${i}") "
		fi
	done
	# create a list of ODSEE instance on OUD instance base
	for i in ${OUD_INSTANCE_BASE}/*/config/dse.ldif; do
		# if the dse.ldif file exists use it to get instance name
		if [ -f "${i}" ]; then
			# remove leading OUD instance path
			i=${i##"${OUD_INSTANCE_BASE}/"}
			# remove trailing OUD* and config*
			i=${i%%/config*.ldif}
			# add oudtab entry
			update_oudtab "${i}" ODSEE silent
			export OUD_INST_LIST+="$(echo "${i}") "
		fi
	done
	# check for OUDSM Instances
	for i in ${OUDSM_DOMAIN_BASE}/*/config/config.xml; do
		# if the config.xml file exists use it to get domain name
		if [ -f "${i}" ]; then
			# remove leading OUD instance path
			i=${i##"${OUDSM_DOMAIN_BASE}/"}
			# remove trailing OUD* and config*
			i=${i%%/config*.xml}
			#add oudtab entry
			update_oudtab "${i}" OUDSM silent
			export OUD_INST_LIST+="$(echo "${i}") "
		fi
	done
fi

# if not defined set default instance to first of OUD_INST_LIST
if [ -n "$(echo "${OUD_INST_LIST}" | cut -f1 -d' ')" ]; then
	OUD_DEFAULT_INSTANCE=$(echo "${OUD_INST_LIST}" | cut -f1 -d' ')
else
	OUD_DEFAULT_INSTANCE="n/a"
fi

# set the last OUD instance to ...
if [ "${OUD_INSTANCE}" = "" ]; then
	# the default instance
	export OUD_INSTANCE_LAST=${OUD_DEFAULT_INSTANCE}
else
	# the real last instance
	export OUD_INSTANCE_LAST=${OUD_INSTANCE}
fi

# use default OUD Instance if none has been specified as parameter
if [ "${OUD_INSTANCE}" = "" ]; then
	export OUD_INSTANCE=${OUD_DEFAULT_INSTANCE}
elif [ "${OUD_INSTANCE}" == "SILENT" ]; then
	export OUD_INSTANCE=${OUD_DEFAULT_INSTANCE}
	export SILENT="SILENT"
elif [[ "${OUD_INSTANCE}" =~ [^a-zA-Z0-9_-] ]]; then
	export OUD_INSTANCE=${OUD_DEFAULT_INSTANCE}
else
	export OUD_INSTANCE=${OUD_INSTANCE}
fi
# - EOF Initialization ---------------------------------------------------------

# - Main -----------------------------------------------------------------------

# Load OUD config from oudtab
if [ $(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -iwc "${OUD_INSTANCE}") -eq 1 ]; then
	# set new environment based on oudtab values
	OUD_CONF_STR=$(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -i "${OUD_INSTANCE}" | head -1)
	OUD_INSTANCE=$(echo "${OUD_CONF_STR}" | cut -d: -f1)
	PORT=$(echo "${OUD_CONF_STR}" | cut -d: -f2)
	PORT_SSL=$(echo "${OUD_CONF_STR}" | cut -d: -f3)
	PORT_ADMIN=$(echo "${OUD_CONF_STR}" | cut -d: -f4)
	PORT_REP=$(echo "${OUD_CONF_STR}" | cut -d: -f5)
	DIRECTORY_TYPE=$(echo "${OUD_CONF_STR}" | cut -d: -f6)
	# make sure that we define a directory type even if it is missing in OUDTAB
	DIRECTORY_TYPE=${DIRECTORY_TYPE:-"${DEFAULT_DIRECTORY_TYPE}"}

	# Validate directory type
	DIRECTORY_TYPE=$(validate_directory_type "${DIRECTORY_TYPE}") || {
		log_error "Invalid directory type in oudtab for instance ${OUD_INSTANCE}"
		return 1
	}

	# set the instance home based on directory type
	if [ "${DIRECTORY_TYPE}" == "OUD" ]; then
		OUD_INSTANCE_HOME="${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"
		# check which bin folder is availabe eg. workaround OUD folder issue
		if [ -d "${OUD_INSTANCE_HOME}/OUD/bin" ]; then
			OUD_INSTANCE_HOME_BIN="${OUD_INSTANCE_HOME}/OUD/bin"
		elif [ -d "${OUD_INSTANCE_HOME}/bin" ]; then
			OUD_INSTANCE_HOME_BIN="${OUD_INSTANCE_HOME}/bin"
		else
			OUD_INSTANCE_HOME_BIN="${OUD_INSTANCE_HOME}"
		fi
	elif [ "${DIRECTORY_TYPE}" == "OUDSM" ]; then
		# if directory type is OUDSM use a different base
		OUD_INSTANCE_HOME="${OUDSM_DOMAIN_BASE}/${OUD_INSTANCE}"
	else
		OUD_INSTANCE_HOME="${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"
	fi
	export OUD_INSTANCE_HOME
	export OUD_INSTANCE_ADMIN=${OUD_ADMIN_BASE}/${OUD_INSTANCE}

	# get the Oracle home based on OUD instance home
	get_oracle_home "${OUD_INSTANCE}" "${DIRECTORY_TYPE}" silent # get oracle home from OUD instance
	export INSTANCE_NAME=$(relpath "${ORACLE_HOME}" "${OUD_INSTANCE_HOME}")
	export PORT
	export PORT_SSL
	export PORT_ADMIN
	export PORT_REP
	export DIRECTORY_TYPE
elif [ -d "${OUD_INSTANCE_BASE}/${OUD_INSTANCE}" ]; then
	# fallback to OUD_INSTANCE_BASE Instance directory
	export OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}
	export OUD_INSTANCE_ADMIN=${OUD_ADMIN_BASE}/${OUD_INSTANCE}
	log_warn "Set Instance based on ${OUD_INSTANCE_HOME}"
	get_oracle_home "${OUD_INSTANCE}" "${DIRECTORY_TYPE}" silent # get oracle home from OUD instance
	get_ports "${OUD_INSTANCE}" "${DIRECTORY_TYPE}" silent       # get ports from OUD config
	echo "${OUD_INSTANCE}:${PORT}:${PORT_SSL}:${PORT_ADMIN}:${PORT_REP}:${DIRECTORY_TYPE}" >>${OUDTAB}
	log_warn "Add ${OUD_INSTANCE} to ${OUDTAB} please review ports"
elif [ $(grep -E "${ORATAB_PATTERN}" "${OUDTAB}" | grep -iwc "${OUD_INSTANCE}") -gt 1 ]; then
	echo "ERROR: Found multiple entries for ${OUD_INSTANCE} in ${OUDTAB} please fix manualy"
	RECREATE="FALSE"
elif [ "${OUD_INSTANCE}" == "n/a" ]; then
	log_warn "No OUD Instance yet available or defined."
	RECREATE="FALSE"
else # print error and keep current setting
	echo "ERROR: OUD Instance ${OUD_INSTANCE} does not exits in ${OUDTAB} or ${OUD_INSTANCE_BASE}"
	echo "ERROR: Set environment to ${OUD_DEFAULT_INSTANCE}."
	export OUD_INSTANCE=${OUD_DEFAULT_INSTANCE}
	export OUD_INSTANCE_HOME_BIN=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/OUD/bin
	RECREATE="FALSE"
	exit 1
fi

# re-create a few stuff if necessary
if [ "${RECREATE}" = "TRUE" ]; then
	# re-create instance admin directory
	if [ ! -d "${OUD_INSTANCE_ADMIN}" ]; then
		create_secure_dir "${OUD_INSTANCE_ADMIN}" "0755" "instance admin directory"
		create_secure_dir "${OUD_INSTANCE_ADMIN}/create" "0755" "instance admin create directory"
		create_secure_dir "${OUD_INSTANCE_ADMIN}/log" "0755" "instance admin log directory"
		create_secure_dir "${OUD_INSTANCE_ADMIN}/etc" "0750" "instance admin etc directory"
	fi

	# re-create instance admin directory
	if [ ! -f "${ETC_BASE}/oud.${OUD_INSTANCE}.conf" ]; then
		echo "# ----------------------------------------------------------------------" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
		echo "# Instance Name : ${OUD_INSTANCE}" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
		echo "# Instance Type : ${DIRECTORY_TYPE}" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
		echo "# Instance Home : ${OUD_INSTANCE_HOME}" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
		echo "# Oracle Home   : ${ORACLE_HOME}" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
		echo "# ----------------------------------------------------------------------" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
		echo "export ORACLE_HOME=${ORACLE_HOME}" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
	fi
fi

# set a few default values for undefined variables
OUD_INSTANCE_HOME=${OUD_INSTANCE_HOME:-${OUD_INSTANCE_BASE}/${OUD_INSTANCE}}
OUD_INSTANCE_HOME_BIN=${OUD_INSTANCE_HOME_BIN:-"${OUD_INSTANCE_HOME}/OUD/bin"}
OUD_INST_LIST=${OUD_INST_LIST:-""}
REAL_OUD_INST_LIST=${REAL_OUD_INST_LIST:-""}
OUD_INSTANCE_ADMIN=${OUD_INSTANCE_ADMIN:-${OUD_ADMIN_BASE}/${OUD_INSTANCE}}
# set the new PATH
update_path "${JAVA_HOME}/bin"
update_path "${ORACLE_HOME}"
update_path "${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_BIN_NAME}"
if [ "${DIRECTORY_TYPE}" == "OUD" ]; then
	update_path "${OUD_INSTANCE_HOME_BIN:-${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/OUD/bin}"
elif [ "${DIRECTORY_TYPE}" == "OUDSM" ]; then
	update_path "${OUD_INSTANCE_HOME}/bin"
elif [ "${DIRECTORY_TYPE}" == "ODSEE" ]; then
	update_path "${OUD_INSTANCE_HOME}/OUD/bin"
fi
# start to source stuff from ETC_CORE
# source oudenv.conf file from core etc directory if it exits
if [ -f "${ETC_CORE}/oudenv.conf" ]; then
	safe_source "${ETC_CORE}/oudenv.conf" "core oudenv configuration" false
fi
# source oud._DEFAULT_.conf from core etc directory if it exits
if [ -f "${ETC_CORE}/oud._DEFAULT_.conf" ]; then
	safe_source "${ETC_CORE}/oud._DEFAULT_.conf" "default OUD configuration" false
fi

# start to source stuff from ETC_BASE
# source oudenv.conf file to set environment variables and aliases
safe_source "${ETC_BASE}/oudenv.conf" "base oudenv configuration" true

# set the password file variable based on ETC_BASE
if [ -f "${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt" ]; then
	export PWD_FILE=${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt
else
	export PWD_FILE=${ETC_BASE}/pwd.txt
fi

# source custom config file
if [ -f "${ETC_BASE}/oudenv_custom.conf" ]; then
	safe_source "${ETC_BASE}/oudenv_custom.conf" "custom oudenv configuration" false
fi

# source oud._DEFAULT_.conf if exists
if [ -f "${ETC_BASE}/oud._DEFAULT_.conf" ]; then
	safe_source "${ETC_BASE}/oud._DEFAULT_.conf" "default OUD instance configuration" false
fi

# source oud.<OUD_INSTANCE>.conf if exists
if [ -f "${ETC_BASE}/oud.${OUD_INSTANCE}.conf" ]; then
	safe_source "${ETC_BASE}/oud.${OUD_INSTANCE}.conf" "instance configuration for ${OUD_INSTANCE}" false
fi

if [ "${pTTY}" -eq 0 ] && [ "${SILENT}" = "" ] && [ ! "${OUD_INSTANCE}" == 'n/a' ]; then
	echo "Source environment for ${DIRECTORY_TYPE} Instance ${OUD_INSTANCE}"
	oud_status
fi
# - EOF ------------------------------------------------------------------------
