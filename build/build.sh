#!/bin/bash
# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: build.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Simple build script for the OUD Base Package
# Notes......: This script is used as base install script for the OUD Environment
# Reference..: --
# ---------------------------------------------------------------------------
# Rev History:
# 11.10.2016   soe  Initial version
# ---------------------------------------------------------------------------
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"                  # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"                    # Full qualified script name

echo "SCRIPT_FQN=$SCRIPT_FQN"
echo "SCRIPT_DIR=$SCRIPT_DIR"

cd ${SCRIPT_DIR}/../local
cp ${SCRIPT_DIR}/../README.md ${SCRIPT_DIR}/../local/doc
find . -type f \( ! -iname ".DS_Store" ! -iname ".oudbase.sha" \) -print0 | xargs -0 shasum -p >${SCRIPT_DIR}/../local/doc/.oudbase.sha
tar -zcvf ${SCRIPT_DIR}/oudbase_install.tgz \
    --exclude=bin/oudbase_install.sh \
    --exclude=log/*.log \
    bin/ doc/ etc/ log/ templates/
cat bin/oudbase_install.sh ${SCRIPT_DIR}/oudbase_install.tgz >${SCRIPT_DIR}/oudbase_install.sh
rm ${SCRIPT_DIR}/../local/doc/README.md
chmod 755 ${SCRIPT_DIR}/oudbase_install.sh
# - EOF ---------------------------------------------------------------------