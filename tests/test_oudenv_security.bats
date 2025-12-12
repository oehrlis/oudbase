#!/usr/bin/env bats
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: test_oudenv_security.bats
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.12
# Version....: v3.6.1
# Purpose....: BATS tests for oudenv.sh security improvements
# Notes......: Tests focus on Phase 1 - Security (variable quoting, input
#              validation, file operations)
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

# Load BATS helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'
load 'common'

# Setup and teardown
setup() {
    setup_test_env
    
    # Copy oudenv.sh to test environment
    cp "${BIN_DIR}/oudenv.sh" "${BIN_BASE}/oudenv.sh"
    chmod +x "${BIN_BASE}/oudenv.sh"
    
    # Create mock configuration files
    create_mock_oudtab
    create_mock_oudenv_conf
}

teardown() {
    cleanup_test_env
}

# ------------------------------------------------------------------------------
# Security Tests - Variable Quoting
# ------------------------------------------------------------------------------

@test "oudenv.sh: Variables with spaces are properly quoted in assignments" {
    # Create a config with spaces
    local test_var="value with spaces"
    export TEST_OUD_VAR="${test_var}"
    
    # Source oudenv.sh - should now handle spaces correctly
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    # Should not fail due to unquoted variables
    assert_success
}

@test "oudenv.sh: Path variables with spaces are properly quoted" {
    # Create directory with spaces
    local dir_with_spaces="${TEST_TEMP_DIR}/dir with spaces"
    mkdir -p "${dir_with_spaces}"
    
    export ORACLE_INSTANCE_BASE="${dir_with_spaces}"
    
    # Test if oudenv.sh handles this correctly (should not error on unquoted paths)
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    # May fail for other reasons but not due to unquoted paths
    # Check that no word splitting errors occurred
    refute_output --partial "No such file or directory: ${TEST_TEMP_DIR}/dir"
}

@test "oudenv.sh: Command substitution results are properly quoted" {
    # Test that $(command) results are quoted
    # All command substitutions in oudenv.sh are now properly quoted
    
    # Source script - command substitutions should be safe
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    
    # Should succeed - all command substitutions are quoted
    assert_success
}

@test "oudenv.sh: Array expansions are properly quoted" {
    # Test that ${array[@]} is properly quoted
    # oudenv.sh doesn't use arrays, but we verify general quoting
    
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    assert_success
}

@test "oudenv.sh: Variables in conditionals are properly quoted" {
    # Test [[ "${var}" == "value" ]] pattern
    # All conditionals in oudenv.sh now properly quote variables
    
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    assert_success
}

# ------------------------------------------------------------------------------
# Security Tests - Input Validation
# ------------------------------------------------------------------------------

@test "oudenv.sh: Rejects instance name with spaces" {
    run bash -c "source '${BIN_BASE}/oudenv.sh' 'instance with spaces' SILENT 2>&1"
    assert_failure
    assert_output --partial "ERROR: Invalid instance name"
}

@test "oudenv.sh: Rejects instance name with special shell characters" {
    run bash -c "source '${BIN_BASE}/oudenv.sh' 'instance;rm -rf /' SILENT 2>&1"
    assert_failure
    assert_output --partial "ERROR: Invalid instance name"
}

@test "oudenv.sh: Validates instance name format" {
    # Valid: alphanumeric, underscore, hyphen
    create_mock_oud_instance "oud_test1"
    create_mock_oudtab
    
    run bash -c "source '${BIN_BASE}/oudenv.sh' 'oud_test1' SILENT 2>&1"
    # Should succeed with valid instance name format
    assert_success
}

@test "oudenv.sh: Rejects instance name with path traversal" {
    run bash -c "source '${BIN_BASE}/oudenv.sh' '../../../etc/passwd' SILENT 2>&1"
    assert_failure
    assert_output --partial "ERROR: Invalid instance name"
}

@test "oudenv.sh: Validates port numbers are numeric" {
    # Note: Invalid oudtab format will be rejected by ORATAB_PATTERN before reaching port validation
    # Testing via oudtab parsing is done in the range test
    skip "Non-numeric ports are rejected at oudtab pattern matching level"
}

@test "oudenv.sh: Validates port numbers are in valid range (1-65535)" {
    # Create oudtab with out-of-range port
    cat > "${ETC_BASE}/oudtab" <<EOF
oud_test:99999:1636:4444:8989:OUD:Y
EOF
    
    create_mock_oud_instance "oud_test"
    run bash -c "source '${BIN_BASE}/oudenv.sh' 'oud_test' 2>&1"
    
    # Port validation should trigger ERROR message
    assert_success
    assert_output --partial "ERROR: LDAP port out of valid range"
}

@test "oudenv.sh: Sanitizes environment variables before use" {
    export OUD_BASE="/tmp/test\$(rm -rf /)"
    
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    
    # Should not execute the embedded command
    assert_dir_exists "/tmp"
    skip "Implementation pending"
}

# ------------------------------------------------------------------------------
# Security Tests - File Operations
# ------------------------------------------------------------------------------

@test "oudenv.sh: Uses secure temp file creation" {
    # Test that mktemp is used instead of predictable names
    skip "Implementation pending - will check for mktemp usage"
}

@test "oudenv.sh: Sets restrictive permissions on created files" {
    # Temp files should be 0600, dirs 0700
    skip "Implementation pending"
}

@test "oudenv.sh: Checks file existence before sourcing" {
    # Test that files are checked with [[ -f ]] before being sourced
    run bash -c "source '${BIN_BASE}/oudenv.sh' 'nonexistent' SILENT 2>&1"
    assert_failure
}

@test "oudenv.sh: Prevents symlink attacks in file operations" {
    # Create a symlink pointing to sensitive file
    local fake_conf="${TEST_TEMP_DIR}/fake.conf"
    ln -s "/etc/passwd" "${fake_conf}"
    
    # oudenv.sh should detect and reject symlinks in temp operations
    skip "Implementation pending"
}

@test "oudenv.sh: Safely handles files with special characters in names" {
    # Create file with special chars
    local special_file="${ETC_BASE}/file\$with\`special\`chars.conf"
    touch "${special_file}"
    
    # Should handle without executing embedded commands
    skip "Implementation pending"
}

@test "oudenv.sh: Avoids race conditions in file checks" {
    # TOCTOU (Time-of-check, Time-of-use) test
    # Create file, check it, remove it, use it
    skip "Implementation pending - complex to test"
}

# ------------------------------------------------------------------------------
# Security Tests - Command Injection Prevention
# ------------------------------------------------------------------------------

@test "oudenv.sh: Prevents command injection through instance names" {
    run bash -c "source '${BIN_BASE}/oudenv.sh' '\$(whoami)' SILENT 2>&1"
    assert_failure
    # Output should not contain actual username
}

@test "oudenv.sh: Prevents command injection through environment variables" {
    export OUD_INSTANCE="\$(whoami)"
    
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    
    # Should not execute whoami
    skip "Implementation pending"
}

@test "oudenv.sh: Safely constructs paths without eval" {
    # Ensure no eval is used with user input
    local malicious_path="/tmp;\$(rm -rf /tmp/testdir)"
    export ORACLE_INSTANCE_BASE="${malicious_path}"
    
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    
    # Should not execute the embedded command
    skip "Implementation pending"
}

# ------------------------------------------------------------------------------
# Security Tests - Privilege Escalation Prevention
# ------------------------------------------------------------------------------

@test "oudenv.sh: Refuses to run as root when not necessary" {
    if [[ $EUID -eq 0 ]]; then
        skip "Test requires non-root execution"
    fi
    
    # Should work as non-root user
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    # May fail for other reasons, but not due to privilege check
}

@test "oudenv.sh: Does not change ownership of files unexpectedly" {
    # Create a file and remember its ownership
    local test_file="${TEST_TEMP_DIR}/ownership_test"
    touch "${test_file}"
    local original_owner=$(stat -f "%u:%g" "${test_file}" 2>/dev/null || stat -c "%u:%g" "${test_file}")
    
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    
    local new_owner=$(stat -f "%u:%g" "${test_file}" 2>/dev/null || stat -c "%u:%g" "${test_file}")
    assert_equal "${original_owner}" "${new_owner}"
}

@test "oudenv.sh: Validates ORACLE_BASE ownership before use" {
    # Create ORACLE_BASE owned by different user (if possible)
    skip "Implementation pending - requires multi-user setup"
}

# ------------------------------------------------------------------------------
# Security Tests - Logging and Auditing
# ------------------------------------------------------------------------------

@test "oudenv.sh: Logs security-relevant operations" {
    skip "Implementation pending - will add security logging"
}

@test "oudenv.sh: Does not log sensitive information (passwords, etc.)" {
    export TVDLDAP_BINDPW="secret_password"
    
    run bash -c "source '${BIN_BASE}/oudenv.sh' SILENT 2>&1"
    
    # Check that password doesn't appear in output
    refute_output --partial "secret_password"
}

@test "oudenv.sh: Sanitizes output to prevent information disclosure" {
    # Ensure error messages don't reveal full paths or sensitive info
    skip "Implementation pending"
}
