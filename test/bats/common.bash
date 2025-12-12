#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: common.bash
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.12
# Version....: v3.6.1
# Purpose....: Common setup and helper functions for BATS tests
# Notes......: Source this file in BATS test files using: load 'common'
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Get the directory where this script is located
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${TEST_DIR}/../.." && pwd)"
BIN_DIR="${PROJECT_ROOT}/src/bin"
ETC_DIR="${PROJECT_ROOT}/src/etc"
FIXTURES_DIR="${PROJECT_ROOT}/test/fixtures"

# Temporary directory for test data
TEST_TEMP_DIR=""

# ------------------------------------------------------------------------------
# Setup test environment
# ------------------------------------------------------------------------------
setup_test_env() {
	# Create temporary directory for this test
	TEST_TEMP_DIR="$(mktemp -d -t oudbase-test.XXXXXX)"

	# Export common environment variables
	export OUD_BASE="${TEST_TEMP_DIR}/oudbase"
	export ORACLE_BASE="${TEST_TEMP_DIR}/oracle"
	export ORACLE_INSTANCE_BASE="${TEST_TEMP_DIR}/instances"
	export OUD_DATA="${ORACLE_INSTANCE_BASE}"
	export ETC_BASE="${OUD_BASE}/etc"
	export BIN_BASE="${OUD_BASE}/bin"
	export LOG_BASE="${OUD_BASE}/log"
	export HOME="${TEST_TEMP_DIR}/home"

	# Create necessary directories
	mkdir -p "${OUD_BASE}"/{bin,etc,log,templates}
	mkdir -p "${ORACLE_INSTANCE_BASE}"
	mkdir -p "${HOME}"

	# Set up default paths
	export PATH="${BIN_BASE}:${PATH}"
}

# ------------------------------------------------------------------------------
# Cleanup test environment
# ------------------------------------------------------------------------------
cleanup_test_env() {
	# Remove temporary directory
	if [[ -n "${TEST_TEMP_DIR}" ]] && [[ -d "${TEST_TEMP_DIR}" ]]; then
		rm -rf "${TEST_TEMP_DIR}"
	fi
}

# ------------------------------------------------------------------------------
# Create mock OUD instance directory structure
# ------------------------------------------------------------------------------
create_mock_oud_instance() {
	local instance_name="${1:-oud_test}"
	local instance_dir="${ORACLE_INSTANCE_BASE}/${instance_name}"

	mkdir -p "${instance_dir}"/{OUD,admin}
	mkdir -p "${instance_dir}/OUD"/{config,logs,db,ldif}
	mkdir -p "${instance_dir}/admin"

	# Create minimal config files
	cat >"${instance_dir}/OUD/config/config.ldif" <<EOF
dn: cn=config
objectClass: top
cn: config
EOF

	echo "${instance_name}" >"${instance_dir}/.oud_instance"
	echo "OUD" >"${instance_dir}/.directory_type"

	echo "${instance_dir}"
}

# ------------------------------------------------------------------------------
# Create mock oudtab file
# ------------------------------------------------------------------------------
create_mock_oudtab() {
	local oudtab_file="${ETC_BASE}/oudtab"

	cat >"${oudtab_file}" <<EOF
# OUD Instance Configuration
# Format: INSTANCE:PORT:PORT_SSL:PORT_ADMIN:PORT_REP:TYPE:STATUS
oud_test1:1389:1636:4444:8989:OUD:Y
oud_test2:2389:2636:5444:9989:OUD:N
# Comment line
oud_test3:3389:3636:6444:10989:OUD:Y
EOF

	echo "${oudtab_file}"
}

# ------------------------------------------------------------------------------
# Create mock oudenv.conf file
# ------------------------------------------------------------------------------
create_mock_oudenv_conf() {
	local conf_file="${ETC_BASE}/oudenv.conf"

	cat >"${conf_file}" <<EOF
# OUD Environment Configuration
export OUD_BASE="${OUD_BASE}"
export ORACLE_BASE="${ORACLE_BASE}"
export ORACLE_INSTANCE_BASE="${ORACLE_INSTANCE_BASE}"
export ETC_BASE="${ETC_BASE}"
export LOG_BASE="${LOG_BASE}"
EOF

	echo "${conf_file}"
}

# ------------------------------------------------------------------------------
# Mock the 'ps' command for testing
# ------------------------------------------------------------------------------
mock_ps_command() {
	local instance_name="${1:-oud_test}"
	local pid="${2:-12345}"

	# Create a mock ps function that will be used instead of the real ps
	eval "ps() { echo '${pid} ${ORACLE_INSTANCE_BASE}/${instance_name}/OUD/bin/start-ds'; }"
	export -f ps
}

# ------------------------------------------------------------------------------
# Unmock the 'ps' command
# ------------------------------------------------------------------------------
unmock_ps_command() {
	unset -f ps
}

# ------------------------------------------------------------------------------
# Assert that a variable is properly quoted in output
# ------------------------------------------------------------------------------
assert_variable_quoted() {
	local var_name="$1"
	local output="$2"

	# Check if variable appears unquoted in command context
	if echo "${output}" | grep -E "\\$\{?${var_name}\}?[^\"']" >/dev/null; then
		echo "ERROR: Variable ${var_name} appears unquoted in output"
		return 1
	fi
	return 0
}

# ------------------------------------------------------------------------------
# Create a file with spaces in name for testing
# ------------------------------------------------------------------------------
create_file_with_spaces() {
	local dir="${1:-${TEST_TEMP_DIR}}"
	local filename="file with spaces.txt"
	local filepath="${dir}/${filename}"

	echo "test content" >"${filepath}"
	echo "${filepath}"
}

# ------------------------------------------------------------------------------
# Simulate a running OUD process
# ------------------------------------------------------------------------------
simulate_oud_process() {
	local instance_name="${1:-oud_test}"
	local port="${2:-1389}"

	# Create a mock process by writing PID file
	local pid_file="${ORACLE_INSTANCE_BASE}/${instance_name}/OUD/locks/server.pid"
	mkdir -p "$(dirname "${pid_file}")"
	echo "$$" >"${pid_file}"

	# Mock netstat to show listening port
	eval "netstat() { echo 'tcp 0 0 0.0.0.0:${port} 0.0.0.0:* LISTEN'; }"
	export -f netstat
}

# ------------------------------------------------------------------------------
# Stop simulating OUD process
# ------------------------------------------------------------------------------
stop_simulate_oud_process() {
	unset -f netstat
}

# ------------------------------------------------------------------------------
# Assert that a function validates its input
# ------------------------------------------------------------------------------
assert_validates_input() {
	local function_name="$1"
	local invalid_input="$2"

	run "${function_name}" "${invalid_input}"
	assert_failure
}

# ------------------------------------------------------------------------------
# Create a symlink for testing
# ------------------------------------------------------------------------------
create_test_symlink() {
	local target="${1}"
	local link_name="${2}"

	ln -s "${target}" "${link_name}"
	echo "${link_name}"
}

# ------------------------------------------------------------------------------
# Check if running as root (some tests may need to skip)
# ------------------------------------------------------------------------------
is_root() {
	[[ $EUID -eq 0 ]]
}

# ------------------------------------------------------------------------------
# Skip test if not root
# ------------------------------------------------------------------------------
skip_if_not_root() {
	if ! is_root; then
		skip "This test requires root privileges"
	fi
}

# ------------------------------------------------------------------------------
# Generate random port number for testing
# ------------------------------------------------------------------------------
generate_test_port() {
	local min=${1:-10000}
	local max=${2:-20000}
	echo $((min + RANDOM % (max - min)))
}
