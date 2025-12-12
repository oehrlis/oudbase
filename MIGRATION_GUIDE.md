# Repository Migration Guide

## Overview

This document describes the repository reorganization completed in December 2025 (issue #140). The changes improve CI/CD integration, standardize directory structure, and separate source code from build artifacts.

## Directory Structure Changes

### Before (Old Structure)

```text
oudbase/
├── build/                    # Build scripts and artifacts
├── local/oudbase/            # Source code location
│   ├── bin/                  # Scripts
│   ├── etc/                  # Configs
│   ├── templates/            # Templates
│   └── doc/                  # Documentation
├── tests/                    # Test files
├── admin/                    # Empty directory
├── backup/                   # Empty directory
├── instances/                # Empty directory
└── images/                   # Empty directory
```

### After (New Structure)

```text
oudbase/
├── src/                      # NEW: All source code
│   ├── bin/                  # Scripts (from local/oudbase/bin/)
│   ├── etc/                  # Configs (from local/oudbase/etc/)
│   ├── templates/            # Templates (from local/oudbase/templates/)
│   └── doc/                  # Documentation (from local/oudbase/doc/)
├── scripts/                  # NEW: Build & utility scripts
│   ├── build.sh              # Main build script (from build/)
│   └── install/              # Installation helpers
├── test/                     # RENAMED: tests/ → test/
│   ├── bats/                 # BATS test files
│   ├── fixtures/             # Test fixtures
│   ├── helpers/              # Test helpers (bats-assert, bats-support, bats-file)
│   └── work/                 # NEW: Temp/work directory for test artifacts
├── ci/                       # NEW: CI/CD specific files (reserved for future)
├── docs/                     # Documentation
│   ├── issues/               # Issue documentation
│   └── images/               # NEW: Images (from root images/)
└── examples/                 # NEW: Example configurations
```

## Breaking Changes

### 1. Source Code Location

- **Old**: `local/oudbase/bin/oudenv.sh`
- **New**: `src/bin/oudenv.sh`

### 2. Build Script Location

- **Old**: `build/build.sh`
- **New**: `scripts/build.sh`

### 3. Test Files Location

- **Old**: `tests/test_oudenv_security.bats`
- **New**: `test/bats/test_oudenv_security.bats`

### 4. Test Helper Path

- **Old**: `tests/test_helper/bats-assert`
- **New**: `test/helpers/test_helper/bats-assert`

### 5. Build Artifacts

- **Old**: `build/oudbase_install.sh`, `build/oudbase_install.tgz`
- **New**: `scripts/oudbase_install.sh`, `scripts/oudbase_install.tgz`

## Migration Steps for Users

### If you have scripts referencing old paths

```bash
# Update source references
sed -i 's|local/oudbase/bin/|src/bin/|g' your-script.sh
sed -i 's|local/oudbase/etc/|src/etc/|g' your-script.sh

# Update test references
sed -i 's|tests/|test/bats/|g' your-script.sh
sed -i 's|tests/test_helper|test/helpers/test_helper|g' your-script.sh

# Update build references
sed -i 's|build/build.sh|scripts/build.sh|g' your-script.sh
```

### Running Tests

**Old command:**

```bash
bats tests/test_oudenv_security.bats
```

**New command:**

```bash
bats test/bats/test_oudenv_security.bats
```

### Building the Package

**Old command:**

```bash
cd build && ./build.sh
```

**New command:**

```bash
cd scripts && ./build.sh
```

## Rationale

### Why These Changes?

1. **Clearer Source Organization**: All source code now in `src/` directory
2. **Standard Test Structure**: Using `test/` (singular) follows common conventions
3. **Separation of Concerns**: Build scripts in `scripts/`, source in `src/`
4. **CI/CD Ready**: Structure supports future GitHub Actions workflows in `ci/`
5. **Reduced Clutter**: Empty directories (admin, backup, instances) now ignored
6. **Test Isolation**: Work directory (`test/work/`) for temporary test artifacts

### Benefits

- ✅ Easier to understand repository structure
- ✅ Clear separation between source and build artifacts
- ✅ Standard naming conventions (test/ instead of tests/)
- ✅ Ready for CI/CD pipeline integration
- ✅ Reduced repository size (empty dirs ignored)
- ✅ Better for automation and Docker builds

## Backward Compatibility

### Deprecated Directories

The following directories are now **deprecated** and ignored by git:

- `local/` - Use `src/` instead
- `build/` - Use `scripts/` for build scripts
- `tests/` - Use `test/` instead
- `admin/`, `backup/`, `instances/`, `images/` - Created on demand in runtime

### Git Ignore Rules

The following are now ignored by `.gitignore`:

```text
# Deprecated directories
build/
local/
tests/
admin/
backup/
instances/
images/

# Build artifacts
scripts/oudbase_install.sh
scripts/oudbase_install.tgz
scripts/passwords.txt

# Test work directory
test/work/
```

## Installation Script Changes

The installation script (`oudbase_install.sh`) still works as before, but it now:

- Reads from `src/` directory during build
- Generates artifacts in `scripts/` directory
- Creates runtime directories (admin, backup, instances) on target system

## Questions or Issues?

If you encounter problems with the migration:

1. Check this guide for path updates
2. Review issue #140 for background
3. Open a new issue if you find migration problems

## Timeline

- **Planning**: Issue #140 opened
- **Implementation**: December 2025
- **Deprecation Period**: Old directories remain until next major version
- **Removal**: Old structure will be fully removed in v5.0.0

---
Last Updated: December 2025
