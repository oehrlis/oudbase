# oudenv.sh Security and Stability Improvements - Implementation Guide

## Overview

This document tracks the implementation of security and stability improvements for oudenv.sh, following the improvement plan with parallel BATS unit testing.

## Phase 1: Security Improvements (Weeks 1-3)

### 1.1 Variable Quoting (Priority: CRITICAL)

**Problem**: Unquoted variables can cause word splitting and glob expansion, leading to security vulnerabilities and unexpected behavior.

**Implementation Steps**:
1. Scan oudenv.sh for all variable references
2. Quote all variable expansions: `"${var}"` instead of `${var}` or `$var`
3. Pay special attention to:
   - Command substitutions: `"$(command)"`
   - Array expansions: `"${array[@]}"`
   - Path variables: `"${OUD_BASE}"`, `"${ORACLE_INSTANCE_BASE}"`
   - User input: instance names, parameters

**Test Coverage**: [test_oudenv_security.bats](tests/test_oudenv_security.bats) lines 34-64

**Status**: ⏳ Not started

---

### 1.2 Input Validation (Priority: CRITICAL)

**Problem**: No validation of instance names and other inputs allows command injection and path traversal attacks.

**Implementation Steps**:
1. Add `validate_instance_name()` function:
   ```bash
   validate_instance_name() {
       local name="$1"
       # Allow only alphanumeric, underscore, hyphen
       if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
           echo "ERROR: Invalid instance name: $name"
           return 1
       fi
       # Check length (max 255 chars)
       if [[ ${#name} -gt 255 ]]; then
           echo "ERROR: Instance name too long: $name"
           return 1
       fi
       return 0
   }
   ```

2. Add `validate_port()` function:
   ```bash
   validate_port() {
       local port="$1"
       # Check if numeric
       if [[ ! "$port" =~ ^[0-9]+$ ]]; then
           echo "ERROR: Port must be numeric: $port"
           return 1
       fi
       # Check range (1-65535)
       if (( port < 1 || port > 65535 )); then
           echo "ERROR: Port out of range: $port"
           return 1
       fi
       return 0
   }
   ```

3. Call validation functions before using inputs

**Test Coverage**: [test_oudenv_security.bats](tests/test_oudenv_security.bats) lines 69-127

**Status**: ⏳ Not started

---

### 1.3 Secure File Operations (Priority: HIGH)

**Problem**: Unsafe temp file creation and file operations create race conditions and security vulnerabilities.

**Implementation Steps**:
1. Replace predictable temp file names with `mktemp`:
   ```bash
   # BAD
   temp_file="/tmp/oudenv_$$"
   
   # GOOD
   temp_file="$(mktemp -t oudenv.XXXXXX)" || { echo "ERROR: Cannot create temp file"; return 1; }
   trap 'rm -f "$temp_file"' EXIT
   ```

2. Set restrictive permissions:
   ```bash
   mktemp -t oudenv.XXXXXX
   chmod 600 "$temp_file"
   ```

3. Add file existence checks before sourcing:
   ```bash
   if [[ -f "$config_file" ]] && [[ -r "$config_file" ]]; then
       source "$config_file"
   else
       echo "ERROR: Config file not found or not readable: $config_file"
       return 1
   fi
   ```

4. Prevent symlink attacks:
   ```bash
   # Check if file is a regular file (not symlink)
   if [[ ! -f "$file" ]] || [[ -L "$file" ]]; then
       echo "ERROR: File is not a regular file: $file"
       return 1
   fi
   ```

**Test Coverage**: [test_oudenv_security.bats](tests/test_oudenv_security.bats) lines 132-167

**Status**: ⏳ Not started

---

## Phase 2: Stability Improvements (Weeks 4-6)

### 2.1 Error Handling (Priority: HIGH)

**Problem**: Insufficient error handling causes silent failures and difficult-to-debug issues.

**Implementation Steps**:
1. Add comprehensive error checking:
   ```bash
   # Check critical variables
   if [[ -z "${OUD_BASE}" ]]; then
       echo "ERROR: OUD_BASE not set" >&2
       return 10
   fi
   
   if [[ ! -d "${OUD_BASE}" ]]; then
       echo "ERROR: OUD_BASE directory does not exist: ${OUD_BASE}" >&2
       return 11
   fi
   ```

2. Implement cleanup on error:
   ```bash
   cleanup() {
       local exit_code=$?
       # Remove temp files
       [[ -n "${temp_file}" ]] && rm -f "${temp_file}"
       # Reset environment on error
       if (( exit_code != 0 )); then
           unset OUD_INSTANCE
       fi
       return $exit_code
   }
   trap cleanup EXIT
   ```

3. Provide informative error messages with error codes

**Test Coverage**: [test_oudenv_stability.bats](tests/test_oudenv_stability.bats) lines 34-92

**Status**: ⏳ Not started

---

### 2.2 Port Parsing Improvements (Priority: MEDIUM)

**Problem**: Brittle port parsing fails with non-standard formats and doesn't validate values.

**Implementation Steps**:
1. Robust port extraction from oudtab:
   ```bash
   parse_oudtab_entry() {
       local instance="$1"
       local oudtab_line
       
       oudtab_line=$(grep "^${instance}:" "${OUDTAB}" | head -1)
       
       if [[ -z "$oudtab_line" ]]; then
           echo "ERROR: Instance not found in oudtab: $instance" >&2
           return 1
       fi
       
       IFS=':' read -r inst version port port_ssl port_admin port_rep status <<< "$oudtab_line"
       
       # Validate and export ports
       if [[ -n "$port" ]]; then
           validate_port "$port" || return 1
           export OUD_PORT="$port"
       fi
       
       # ... repeat for other ports
   }
   ```

2. Fallback to process detection if oudtab missing
3. Handle missing or invalid ports gracefully

**Test Coverage**: [test_oudenv_stability.bats](tests/test_oudenv_stability.bats) lines 97-147

**Status**: ⏳ Not started

---

### 2.3 Path Resolution (Priority: MEDIUM)

**Problem**: Paths with symlinks, relative references, or special characters cause issues.

**Implementation Steps**:
1. Normalize all paths:
   ```bash
   normalize_path() {
       local path="$1"
       # Resolve to absolute path
       path=$(cd "$path" 2>/dev/null && pwd -P) || return 1
       # Remove trailing slashes
       path="${path%/}"
       echo "$path"
   }
   ```

2. Use normalized paths consistently
3. Add symlink resolution

**Test Coverage**: [test_oudenv_stability.bats](tests/test_oudenv_stability.bats) lines 185-218

**Status**: ⏳ Not started

---

## Testing Strategy

### Test Structure

```
tests/
├── README.md                         # Testing documentation
├── common.bash                       # Shared test utilities
├── fixtures/                         # Test data
│   ├── oudtab.sample
│   └── oudenv.conf.sample
├── test_helper/                      # BATS libraries
│   ├── bats-support/
│   ├── bats-assert/
│   └── bats-file/
├── test_oudenv_security.bats         # Security tests (30+ tests)
└── test_oudenv_stability.bats        # Stability tests (35+ tests)
```

### Running Tests

```bash
# Setup BATS (one-time)
./setup_bats.sh

# Run all tests
bats tests/*.bats

# Run specific test suite
bats tests/test_oudenv_security.bats
bats tests/test_oudenv_stability.bats

# Run specific test
bats tests/test_oudenv_security.bats -f "quote"
```

### Test-Driven Development Workflow

1. **Write test** for the feature/fix (initially marked as `skip`)
2. **Implement** the fix in oudenv.sh
3. **Remove `skip`** from the test
4. **Run test** to verify fix: `bats tests/test_*.bats`
5. **Iterate** until test passes
6. **Commit** with test and implementation together

### Current Test Status

- **Total tests created**: 65+
- **Security tests**: 30 (all marked `skip` until implementation)
- **Stability tests**: 35 (all marked `skip` until implementation)
- **Tests passing**: 0 (implementation not started)

---

## Implementation Priority

### Week 1-2: Critical Security Fixes
1. ✅ Setup BATS infrastructure
2. ⏳ Variable quoting (all instances)
3. ⏳ Input validation functions
4. ⏳ Activate and verify security tests

### Week 3-4: File Operations & Error Handling
5. ⏳ Secure file operations
6. ⏳ Comprehensive error handling
7. ⏳ Cleanup on error
8. ⏳ Activate and verify error handling tests

### Week 5-6: Stability & Edge Cases
9. ⏳ Port parsing improvements
10. ⏳ Path resolution
11. ⏳ Process detection improvements
12. ⏳ Activate and verify stability tests

---

## Checklist for Each Fix

Before considering a fix complete:

- [ ] Implementation in oudenv.sh
- [ ] Remove `skip` from relevant BATS tests
- [ ] All tests pass: `bats tests/*.bats`
- [ ] Manual testing with real OUD instances
- [ ] No regressions in existing functionality
- [ ] Update this document with status
- [ ] Commit changes with descriptive message

---

## Notes

- All tests are initially marked as `skip` to prevent failures before implementation
- As you implement each fix, update the corresponding test by removing the `skip` statement
- Run tests frequently during development to catch regressions early
- Tests use mock data and temporary directories to avoid affecting real OUD instances

---

## Resources

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)
- [ShellCheck](https://www.shellcheck.net/) - Static analysis for bash scripts
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

**Last Updated**: 2025-12-12
**Status**: Phase 1 & 2 - Infrastructure Complete, Implementation Not Started
