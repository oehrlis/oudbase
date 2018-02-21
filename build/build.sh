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

function myreadlink() {
  (
  cd $(dirname $1)         # or  cd ${1%/*}
  echo $PWD/$(basename $1) # or  echo $PWD/${1##*/}
  )
}

ABS_NAME=$(myreadlink $0)
BUILD_DIR=$(dirname ${ABS_NAME})

echo "ABS_NAME=$ABS_NAME"
echo "BUILD_DIR=$BUILD_DIR"

cd ${BUILD_DIR}/../local
cp ${BUILD_DIR}/../README.md ${BUILD_DIR}/../local/doc
tar -zcvf ${BUILD_DIR}/oudbase_install.tgz \
    --exclude=bin/oudbase_install.sh \
    --exclude=log/*.log \
    bin/ doc/ etc/ log/ templates/
cat bin/oudbase_install.sh ${BUILD_DIR}/oudbase_install.tgz >${BUILD_DIR}/oudbase_install.sh
rm ${BUILD_DIR}/../local/doc/README.md
chmod 755 ${BUILD_DIR}/oudbase_install.sh
# - EOF ---------------------------------------------------------------------