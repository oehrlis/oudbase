# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Makefile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.12.12
# Version....: v4.0.0
# Purpose....: Common developer & CI targets for oudbase
# Notes......: Provides targets for linting, testing, building, and releasing
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------
# Usage:
#   make            -> show help
#   make lint       -> run shfmt (check) and shellcheck
#   make fmt        -> run shfmt to rewrite files
#   make test       -> run unit tests
#   make test-integration PREFIX=/tmp/u00 -> run integration tests
#   make build      -> build tarball into dist/
#   make package    -> same as build
#   make install-local PREFIX=/tmp/u00 -> install built artifact for testing
#   make release    -> build + checksums (+ sign if GPG env provided)
#   make ci         -> lint, test, build (for CI pipelines)
#
# Variables (adjust via env):
#   PREFIX=/tmp/u00      Installation prefix for testing
#   DISTDIR=dist         Distribution directory for build artifacts
#   VERSION=$(git...)    Version string (auto-detected from git)
# ------------------------------------------------------------------------------

SHELL := /bin/bash
.PHONY: help fmt lint test test-unit test-integration build package install-local clean ci release install-bats

# Configurable vars
DISTDIR ?= dist
PREFIX ?= /tmp/u00
VERSION ?= $(shell git describe --tags --always --dirty)
BATS_VERSION ?= v1.11.0

# Discover shell files under the repository
SH_GLOBS := $(shell git ls-files '*.sh' 'src/bin/*' 'scripts/*.sh' 'test/bats/*.bash' 2> /dev/null || true)

help:
	@echo "Makefile targets:"
	@echo "  make lint                # run shfmt (check) and shellcheck"
	@echo "  make fmt                 # run shfmt to fix formatting"
	@echo "  make test                # run unit tests (test/bats)"
	@echo "  make test-integration    # run integration tests (test/integration) (PREFIX can be set)"
	@echo "  make build               # assemble artifact into $(DISTDIR)/oudbase-$(VERSION).tar.gz"
	@echo "  make package             # alias for build"
	@echo "  make install-local       # install built artifact into PREFIX (for local testing)"
	@echo "  make release             # build + checksums (+optional signing if GPG env provided)"
	@echo "  make ci                  # run lint, tests, build (used by CI)"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX=$(PREFIX)"
	@echo "  DISTDIR=$(DISTDIR)"
	@echo "  VERSION=$(VERSION)"

# Formatting
fmt:
ifeq ($(SH_GLOBS),)
	@echo "No shell files found to format."
else
	@echo "Running shfmt -w on repository shell files..."
	@command -v shfmt >/dev/null 2>&1 || (echo "shfmt not found; please install shfmt" && exit 1)
	@echo "$(SH_GLOBS)" | xargs -r shfmt -w
endif

lint: shfmt-check shellcheck
	@echo "Lint checks passed."

shfmt-check:
ifeq ($(SH_GLOBS),)
	@echo "No shell files found to check."
else
	@command -v shfmt >/dev/null 2>&1 || (echo "shfmt not found; please install shfmt" && exit 1)
	@echo "Checking formatting with shfmt..."
	@echo "$(SH_GLOBS)" | xargs -r shfmt -d || (echo "Run 'make fmt' to fix formatting" && exit 1)
endif

shellcheck:
ifeq ($(SH_GLOBS),)
	@echo "No shell files found to lint."
else
	@command -v shellcheck >/dev/null 2>&1 || (echo "shellcheck not found; please install shellcheck" && exit 1)
	@echo "Running shellcheck on shell files..."
	@echo "$(SH_GLOBS)" | xargs -r -n1 shellcheck -x || (echo "shellcheck found issues" && exit 1)
endif

# Tests
test: test-unit

# Ensure bats is available; install locally if missing
install-bats:
	@if command -v bats >/dev/null 2>&1; then \
	  echo "bats already installed: $$(command -v bats)"; \
	else \
	  echo "Installing bats-core ($(BATS_VERSION)) into $(HOME)/.local..."; \
	  git clone --depth 1 --branch $(BATS_VERSION) https://github.com/bats-core/bats-core.git /tmp/bats-core-$$$$; \
	  cd /tmp/bats-core-$$$$ && ./install.sh $(HOME)/.local; \
	  echo 'export PATH="$(HOME)/.local/bin:$$PATH"' >> $(HOME)/.profile || true; \
	  echo "bats installed at $(HOME)/.local/bin/bats"; \
	fi

test-unit: install-bats
	@if [ -d test/bats ]; then \
	  echo "Running unit tests (test/bats)"; \
	  PATH="$(HOME)/.local/bin:$$PATH" bats -T test/bats || (echo "Unit tests failed" && exit 1); \
	else \
	  echo "No unit tests found (test/bats)"; \
	fi

test-integration: install-bats
	@if [ -d test/integration ]; then \
	  echo "Running integration tests (test/integration) using PREFIX=$(PREFIX)"; \
	  PATH="$(HOME)/.local/bin:$$PATH" PREFIX="$(PREFIX)" bats -T test/integration || (echo "Integration tests failed" && exit 1); \
	else \
	  echo "No integration tests found (test/integration)"; \
	fi

# Build / Package
build: $(DISTDIR)/oudbase-$(VERSION).tar.gz

$(DISTDIR)/oudbase-$(VERSION).tar.gz:
	@echo "Building artifact for version $(VERSION)..."
	@mkdir -p $(DISTDIR)
	@if [ -x scripts/build.sh ]; then \
	  cd scripts && ./build.sh && cp *.tgz ../$(DISTDIR)/oudbase-$(VERSION).tar.gz; \
	else \
	  echo "scripts/build.sh not found or not executable. Please add a build script."; \
	  exit 1; \
	fi

package: build

# Local install for testing
install-local: build
	@echo "Installing built artifact into prefix: $(PREFIX)"
	@if [ -x scripts/oudbase_install.sh ]; then \
	  ./scripts/oudbase_install.sh -b "$(PREFIX)" -o "$(PREFIX)"; \
	else \
	  echo "scripts/oudbase_install.sh not found. Run 'make build' first."; \
	  exit 1; \
	fi

# Release helpers
release: build checksums maybe-sign
	@echo "Release artifacts prepared in $(DISTDIR)."

checksums:
	@echo "Generating checksums in $(DISTDIR)/checksums.txt..."
	@cd $(DISTDIR) && sha256sum * > checksums.txt

maybe-sign:
ifeq (, $(GPG_PRIVATE_KEY))
	@echo "No GPG_PRIVATE_KEY provided; skipping signing step."
else
	@echo "Importing GPG key and signing artifacts (GPG_PRIVATE_KEY provided)."
	@echo "$$GPG_PRIVATE_KEY" | gpg --batch --import
	@for f in $(DISTDIR)/*; do \
	  gpg --batch --yes --pinentry-mode loopback --output "$$f.sig" --detach-sign "$$f"; \
	done
endif

ci: lint test build

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(DISTDIR)
