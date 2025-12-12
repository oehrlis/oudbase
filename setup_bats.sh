#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: setup_bats.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.12
# Version....: v3.6.1
# Purpose....: Setup BATS testing framework and helper libraries
# Notes......: Run this script to install BATS and required helpers
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/tests"
HELPER_DIR="${TEST_DIR}/test_helper"

echo "==> Setting up BATS testing framework..."

# Check if BATS is installed
if ! command -v bats &> /dev/null; then
    echo "==> BATS not found. Installing..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo "==> Installing BATS via Homebrew..."
            brew install bats-core
        else
            echo "ERROR: Homebrew not found. Please install Homebrew first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        echo "==> Installing BATS from source..."
        TMP_DIR=$(mktemp -d)
        cd "${TMP_DIR}"
        git clone https://github.com/bats-core/bats-core.git
        cd bats-core
        sudo ./install.sh /usr/local
        cd "${SCRIPT_DIR}"
        rm -rf "${TMP_DIR}"
    else
        echo "ERROR: Unsupported operating system: $OSTYPE"
        exit 1
    fi
else
    echo "==> BATS already installed: $(bats --version)"
fi

# Create test helper directory
mkdir -p "${HELPER_DIR}"

# Install bats-support
if [[ ! -d "${HELPER_DIR}/bats-support" ]]; then
    echo "==> Installing bats-support..."
    git clone https://github.com/bats-core/bats-support.git "${HELPER_DIR}/bats-support"
else
    echo "==> bats-support already installed"
fi

# Install bats-assert
if [[ ! -d "${HELPER_DIR}/bats-assert" ]]; then
    echo "==> Installing bats-assert..."
    git clone https://github.com/bats-core/bats-assert.git "${HELPER_DIR}/bats-assert"
else
    echo "==> bats-assert already installed"
fi

# Install bats-file
if [[ ! -d "${HELPER_DIR}/bats-file" ]]; then
    echo "==> Installing bats-file..."
    git clone https://github.com/bats-core/bats-file.git "${HELPER_DIR}/bats-file"
else
    echo "==> bats-file already installed"
fi

echo ""
echo "==> BATS setup complete!"
echo ""
echo "To run tests:"
echo "  bats tests/*.bats                    # Run all tests"
echo "  bats tests/test_oudenv_security.bats # Run security tests"
echo "  bats tests/test_oudenv_stability.bats # Run stability tests"
echo ""
echo "Note: Most tests are marked as 'skip' until implementation is complete."
echo "      As you implement fixes, update the tests to remove the 'skip' statements."
echo ""
