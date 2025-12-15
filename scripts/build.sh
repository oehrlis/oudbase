#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: build.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2022.08.17
# Version....: 2.0.0
# Purpose....: Simple build script for the OUD Base Package
# Notes......: This script is used as base install script for the OUD
#              Environment
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")" # Basename of the script
SCRIPT_DIR="$(
	cd "$(dirname "${BASH_SOURCE[0]}")" || exit
	pwd -P
)"                                        # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}" # Full qualified script name
PACKAG_BASE=$(dirname "${SCRIPT_DIR}")    # basename of package
export COPYFILE_DISABLE=true
echo "SCRIPT_FQN=$SCRIPT_FQN"
echo "SCRIPT_DIR=$SCRIPT_DIR"
PAYLOAD_BINARY=0 # default disable binary payload
PAYLOAD_BASE64=1 # default enable base64 payload

# Check for payload format option (default is base64).
if [[ "$1" == '--binary' ]]; then
	PAYLOAD_BINARY=1
	PAYLOAD_BASE64=0
	shift
fi
if [[ "$1" == '--base64' ]]; then
	PAYLOAD_BINARY=0
	PAYLOAD_BASE64=1
	shift
fi

# Remove .DS_Store files
echo "Remove .DS_Store files"
find "${SCRIPT_DIR}"/.. -name .DS_Store -exec rm {} \;

# change workding directory
cd "${SCRIPT_DIR}"/../src || exit
cp "${SCRIPT_DIR}"/../README.md "${SCRIPT_DIR}"/../src/doc
cp "${SCRIPT_DIR}"/../LICENSE "${SCRIPT_DIR}"/../src/doc

# update version in *.sh files
VERSION=$(head -1 "${PACKAG_BASE}"/VERSION | sed -E 's/.*(v[0-9]+.[0-9]+.[0-9]+).*/\1/')
DATE=$(date "+%Y.%m.%d")

while IFS= read -r -d '' i; do
	echo "update version to ${VERSION} and date to ${DATE} in file $i"
	sed -i -E "s/^VERSION=.*/VERSION=${VERSION}/" "$i"
	sed -i -E "s/^# Date\\.\\.\\.\\.\\.\\.\\.:.*/# Date.......: ${DATE}/" "$i"
	sed -i -E "s/^# Version\\.\\.\\.\\.\\.:.*/# Version....: ${VERSION}/" "$i"
done < <(find ./bin ./etc ./templates -type f -print0)

#update version file
while IFS= read -r vfile; do
	sed -i "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/${VERSION}/" "$vfile"
done < <(find . -name .version)

# create sha hash's
echo "Create sha hash values for all files"
find . -type f \( ! -iname ".DS_Store" ! -iname ".oudbase.sha" ! -iname "*.log" ! -iname "oudbase_install.sh" ! -iname "oudbase_install.tgz" \) \
	-print0 | xargs -0 shasum >"${SCRIPT_DIR}"/../src/doc/.oudbase.sha

cp "${SCRIPT_DIR}"/../src/doc/.oudbase.sha "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
# clean up .oudbase.sha
sed -i "\|./doc/.tvdldap.sha|d" "${SCRIPT_DIR}"/../src/doc/.oudbase.sha

# clean up .tvdldap.sha
sed -i "\|./templates/etc/o|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./templates/create|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./bin/oud|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./bin/setup|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./etc/oud|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./templates/logrotate.d|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./templates/cron.d|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./templates/etc/i|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./templates/etc/w|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha
sed -i "\|./templates/etc/h|d" "${SCRIPT_DIR}"/../src/doc/.tvdldap.sha

# Create output directory
mkdir -p "${SCRIPT_DIR}"/../dist

# Tar all together
echo "Put all together in a tar"
tar --verbose -zcvf "${SCRIPT_DIR}"/../dist/oudbase_install.tgz \
	--exclude=bin/oudbase_install.sh \
	--exclude=log/*.log \
	--exclude=doc/.tvdldap.sha \
	--exclude='.DS_Store' \
	--exclude='._*' \
	bin/ doc/ etc/ templates/

# create tns utility tar file
echo "Put all tns utilities together in a tar"
tar --verbose -zcvf "${SCRIPT_DIR}"/../dist/tvdldap_install.tgz \
	--exclude=bin/*oud* \
	--exclude=etc/*oud* \
	--exclude=log/*.log \
	--exclude=doc/.oudbase.sha \
	--exclude='.DS_Store' \
	--exclude=templates/create \
	--exclude=templates/cron.d \
	--exclude=templates/logrotate.d \
	--exclude=templates/etc/*oud* \
	--exclude=templates/etc/housekeeping.conf \
	--exclude=templates/etc/install.rsp \
	--exclude=templates/etc/oraInst.loc \
	--exclude='._*' \
	bin/ doc/ etc/ templates/
# build this nice executable shell script with a TAR payload
echo "Create this fancy shell with a tar payload"

cat bin/oudbase_install.sh >"${SCRIPT_DIR}"/../dist/oudbase_install.sh

# Append the payload
if [[ ${PAYLOAD_BINARY} -ne 0 ]]; then
	echo "Add binary payload"
	# first get the install script
	sed \
		-e 's/^PAYLOAD_BASE64=./PAYLOAD_BASE64=0/' \
		-e 's/^PAYLOAD_BINARY=./PAYLOAD_BINARY=1/' \
		bin/oudbase_install.sh >"${SCRIPT_DIR}"/../dist/oudbase_install.sh
	# set the payload pointer
	echo "__TAR_PAYLOAD__" >>"${SCRIPT_DIR}"/../dist/oudbase_install.sh
	cat "${SCRIPT_DIR}"/../dist/oudbase_install.tgz >>"${SCRIPT_DIR}"/../dist/oudbase_install.sh
elif [[ ${PAYLOAD_BASE64} -ne 0 ]]; then
	echo "Add base64 payload"
	# first get the install script
	sed \
		-e 's/^PAYLOAD_BASE64=./PAYLOAD_BASE64=1/' \
		-e 's/^PAYLOAD_BINARY=./PAYLOAD_BINARY=0/' \
		bin/oudbase_install.sh >"${SCRIPT_DIR}"/../dist/oudbase_install.sh
	# set the payload pointer
	echo "__TAR_PAYLOAD__" >>"${SCRIPT_DIR}"/../dist/oudbase_install.sh
	openssl base64 <"${SCRIPT_DIR}"/../dist/oudbase_install.tgz >>"${SCRIPT_DIR}"/../dist/oudbase_install.sh
fi

# clean up
echo "Clean up...."
rm "${SCRIPT_DIR}"/../src/doc/README.md
rm "${SCRIPT_DIR}"/../src/doc/LICENSE
chmod 755 "${SCRIPT_DIR}"/../dist/oudbase_install.sh
# - EOF ------------------------------------------------------------------------
