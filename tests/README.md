# BATS Testing Infrastructure

This directory contains unit tests for the oudbase scripts using [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

## Setup

### Install BATS

**macOS:**
```bash
brew install bats-core
```

**Linux:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### Install BATS Helper Libraries

```bash
# bats-support: Improved output and error handling
git clone https://github.com/bats-core/bats-support tests/test_helper/bats-support

# bats-assert: Assertion library
git clone https://github.com/bats-core/bats-assert tests/test_helper/bats-assert

# bats-file: File system assertions
git clone https://github.com/bats-core/bats-file tests/test_helper/bats-file
```

## Running Tests

### Run all tests:
```bash
bats tests/*.bats
```

### Run specific test file:
```bash
bats tests/test_oudenv.bats
```

### Run with verbose output:
```bash
bats --tap tests/*.bats
```

### Run specific test:
```bash
bats tests/test_oudenv.bats -f "test name pattern"
```

## Test Structure

```
tests/
├── README.md                  # This file
├── fixtures/                  # Test data and mock files
│   ├── oudtab.sample
│   ├── oudenv.conf.sample
│   └── mock_oud_instance/
├── test_helper/              # BATS helper libraries
│   ├── bats-support/
│   ├── bats-assert/
│   └── bats-file/
├── common.bash               # Common test setup functions
├── test_oudenv.bats          # Tests for oudenv.sh
├── test_oud_functions.bats   # Tests for oud_functions.sh
└── test_tns_functions.bats   # Tests for tns_functions.sh
```

## Writing Tests

Example test structure:

```bash
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'
load 'common'

setup() {
    # Setup test environment
    setup_test_env
}

teardown() {
    # Cleanup after test
    cleanup_test_env
}

@test "function handles quoted variables correctly" {
    run my_function "value with spaces"
    assert_success
    assert_output "expected output"
}
```

## Coverage

Tests are organized by phase:
- **Security tests**: Variable quoting, input validation, file operations
- **Stability tests**: Error handling, race conditions, port parsing
- **Refactoring tests**: Function modularity, code organization
- **Best practices tests**: Documentation, style compliance

## Continuous Integration

Tests can be integrated into CI/CD pipelines using GitHub Actions or similar.
