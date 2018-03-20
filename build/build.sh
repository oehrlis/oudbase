#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: build.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Simple build script for the OUD Base Package
# Notes......: This script is used as base install script for the OUD 
#              Environment
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"                  # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"                    # Full qualified script name
export COPYFILE_DISABLE=true
echo "SCRIPT_FQN=$SCRIPT_FQN"
echo "SCRIPT_DIR=$SCRIPT_DIR"

# Remove .DS_Store files
echo "Remove .DS_Store files"
find ${SCRIPT_DIR}/.. -name .DS_Store -exec rm {} \;

# change workding directory
cd ${SCRIPT_DIR}/../local
cp ${SCRIPT_DIR}/../README.md ${SCRIPT_DIR}/../local/doc
cp ${SCRIPT_DIR}/../LICENSE ${SCRIPT_DIR}/../local/doc

# create sha hash's
echo "Create sha hashs for all files"
find . -type f \( ! -iname ".DS_Store" ! -iname ".oudbase.sha" ! -iname "*.log" ! -iname "oudbase_install.sh" \) \
  -print0 | xargs -0 shasum -p >${SCRIPT_DIR}/../local/doc/.oudbase.sha

# Tar all together
echo "Put all together in a tar"
tar -zcvf ${SCRIPT_DIR}/oudbase_install.tgz \
    --exclude=bin/oudbase_install.sh \
    --exclude=log/*.log \
    --exclude='.DS_Store' \
    --exclude='._*'  \
    bin/ doc/ etc/ log/ templates/

# build this nice executable shell script with an embeded TAR
echo "Create this fancy shell with embedded tar"
cat bin/oudbase_install.sh ${SCRIPT_DIR}/oudbase_install.tgz >${SCRIPT_DIR}/oudbase_install.sh

# clean up
echo "Clean up...."
rm ${SCRIPT_DIR}/../local/doc/README.md
rm ${SCRIPT_DIR}/../local/doc/LICENSE
chmod 755 ${SCRIPT_DIR}/oudbase_install.sh
# - EOF ---------------------------------------------------------------------