#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: 11_setup_oud_patch.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2020.03.11
# Revision...: 
# Purpose....: Script to patch Oracle Unified Directory binaries
# Notes......: - Script would like to be executed as oracle :-)
#              - If the required software is not in /opt/stage, an attempt is
#                made to download the software package with curl from 
#                ${SOFTWARE_REPO} In this case, the environment variable must 
#                point to a corresponding URL.
# Reference..: --
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at http://oss.oracle.com/licenses/upl.
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ---------------------------------------------------------------------------
# - Environment Variables ---------------------------------------------------
VERSION=v1.9.5
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0

DOAPPEND="TRUE"                                 # enable log file append
export VERBOSE=${VERBOSE:-"FALSE"}              # enable debug mode
export CLEANUP=${CLEANUP:-"true"}               # Flag to set yum clean up
export SLIM=${SLIM:-"false"}                    # flag to enable SLIM setup
export DEBUG=${DEBUG:-"FALSE"}                  # enable debug mode
DEFAULT_OUD_TYPE=${OUD_TYPE:-"OUD12"}
# define oradba specific variables
export SETUP_OUD_PATCH="setup_oud_patch.sh"     # OUD patch script
export OUD_FUNCTIONS="oud_functions.sh"         # OUD oud_functions script
# source common functions from oud_functions.sh
. ${SCRIPT_DIR}/${OUD_FUNCTIONS}
TMP_DIR=$(mktemp -p ${SOFTWARE} -d)             # create a temp directory
# define default software packages
DEFAULT_FMW_BASE_PKG="fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip"
DEFAULT_OUD_BASE_PKG="p30188352_122140_Generic.zip"
DEFAULT_OUD_PATCH_PKG="p32730494_122140_Generic.zip"
DEFAULT_FMW_PATCH_PKG="p32698246_122140_Generic.zip"
DEFAULT_OUD_OPATCH_PKG="p28186730_139425_Generic.zip"
DEFAULT_OUI_PATCH_PKG=""
DEFAULT_COHERENCE_PATCH_PKG="p32581859_122140_Generic.zip"
DEFAULT_OUD_ONEOFF_PKGS=""

# define the software packages
export OUD_PATCH_PKG=${OUD_PATCH_PKG:-""}
export FMW_PATCH_PKG=${FMW_PATCH_PKG:-""}
export OUD_OPATCH_PKG=${OUD_OPATCH_PKG:-""}
export OUI_PATCH_PKG=${OUI_PATCH_PKG:-""}
export COHERENCE_PATCH_PKG=${COHERENCE_PATCH_PKG:-""}
export OPATCH_NO_FUSER=true

# define oradba specific variables
export SETUP_OUD_PATCH="setup_oud_patch.sh"     # OUD patch script
export OUD_FUNCTIONS="oud_functions.sh"         # OUD oud_functions script
# define Oracle specific variables
export ORACLE_ROOT=${ORACLE_ROOT:-"/u00"}
export ORACLE_BASE=${ORACLE_BASE:-"${ORACLE_ROOT}/app/oracle"}
export ORACLE_INVENTORY=${ORACLE_INVENTORY:-"${ORACLE_ROOT}/app/oraInventory"}
export ORACLE_HOME_NAME=${ORACLE_HOME_NAME:-"oud12.2.1.4.0"}
export ORACLE_HOME="${ORACLE_HOME:-${ORACLE_BASE}/product/${ORACLE_HOME_NAME}}"

# define generic variables for software, download etc
export JAVA_HOME=${JAVA_HOME:-$(dirname $(dirname $(find ${ORACLE_BASE} /usr/java -name javac 2>/dev/null|sort -r|head -1) 2>/dev/null) 2>/dev/null)}
CURRENT_DIR=$(pwd)
# - EOF Environment Variables -----------------------------------------------

# - Functions -----------------------------------------------------------
# -----------------------------------------------------------------------
function Usage() {
# Purpose....: Display Usage
# -----------------------------------------------------------------------
    VERBOSE="TRUE"
    DoMsg "Usage, ${SCRIPT_NAME} [-hvA] [-b <ORACLE_BASE>] "
    DoMsg "    [-j <JAVA_HOME>] [-l <LOCK FILE>] [-m <ORACLE_HOME>]"
    DoMsg "    [-n <ORACLE_HOME_NAME>] [-r <RESPONSE FILE>] [-t <INSTALL TYPE>]"
    DoMsg "    [-C <COHERENCE_PATCH_PKG>] [-O <OUD_BASE_PKG FILE>] [-P <OUD_ONEOFF_PKGS>]"
    DoMsg "    [-T <OUD_PATCH_PKG>] [-U <FMW_PATCH_PKG>] [-V <OUD_OPATCH_PKG>]"
    DoMsg "    [-W <FMW_BASE_PKG>] [-I <OUI_PATCH_PKG>]"
    DoMsg ""
    DoMsg "    -b <ORACLE_BASE>         ORACLE_BASE Directory. (default \$ORACLE_BASE=${ORACLE_BASE})"
    DoMsg "    -h                       Usage this message"
    DoMsg "    -j <JAVA_HOME>           JAVA_HOME directory. If not set we will search for java in \$ORACLE_BASE/products)"
    DoMsg "    -m <ORACLE_HOME>         Oracle home directory for OUD binaries "
    DoMsg "                             (default \$ORACLE_HOME=$ORACLE_BASE/products/$ORACLE_HOME_NAME)"
    DoMsg "    -n <ORACLE_HOME_NAME>    Name for the Oracle home folder. Can be used to overwrite \$ORACLE_HOME"
    DoMsg "                             (default \$ORACLE_HOME_NAME=${ORACLE_HOME_NAME})"
    DoMsg "    -t <INSTALL TYPE>        OUD install type OUD12,OUDSM12 or OUD11 (default ${DEFAULT_OUD_TYPE})"
    DoMsg "    -v                       enable verbose mode"
    DoMsg "    -A                       Install latest default patches"
    DoMsg "                             \$OUD_PATCH_PKG=${DEFAULT_OUD_PATCH_PKG}"
    DoMsg "                             \$FMW_PATCH_PKG=${DEFAULT_FMW_PATCH_PKG}"
    DoMsg "                             \$OUD_OPATCH_PKG=${DEFAULT_OUD_OPATCH_PKG}"
    DoMsg "    -C <COHERENCE_PATCH_PKG> Coherence patch package (default none)"
    DoMsg "    -O <OUD_BASE_PKG>        Unified Directory binary package (default \$OUD_BASE_PKG=$OUD_BASE_PKG)"
    DoMsg "    -P <OUD_ONEOFF_PKGS>     List of patch (default none)"
    DoMsg "    -T <OUD_PATCH_PKG>       OUD patch package (default none)"
    DoMsg "    -U <FMW_PATCH_PKG>       WLS patch package (default none)"
    DoMsg "    -V <OUD_OPATCH_PKG>      OPatch binary package (default none)"
    DoMsg "    -W <FMW_BASE_PKG>        Fusion Middleware binary package (default none)"
    DoMsg "    -I <OUI_PATCH_PKG>       OUI patch package (default none)"
    DoMsg "    Logfile : ${LOGFILE}"
    if [ ${1} -gt 0 ]; then
        CleanAndQuit ${1} ${2}
    else
        VERBOSE="FALSE"
        CleanAndQuit 0 
    fi
}

function install_patch {
# ---------------------------------------------------------------------------
# Purpose....: function to install a DB patch using opatch apply 
# ---------------------------------------------------------------------------
    PATCH_PKG=${1:-""}
    if [ -n "${PATCH_PKG}" ]; then
        if get_software "${PATCH_PKG}"; then        # Check and get binaries
            PATCH_ID=$(echo ${PATCH_PKG}| sed -E 's/p([[:digit:]]+).*/\1/')
            DoMsg "INFO : unzip ${SOFTWARE}/${PATCH_PKG} to ${TMP_DIR}"
            unzip -q -o ${SOFTWARE}/${PATCH_PKG} \
                -d ${TMP_DIR}/                         # unpack OPatch binary package
            cd ${TMP_DIR}/${PATCH_ID}
            ${ORACLE_HOME}/OPatch/opatch apply -silent -jre $JAVA_HOME
            OPATCH_ERR=$?
            if [ ${OPATCH_ERR} -ne 0 ]; then
                DoMsg "WARN : opatch apply failed with error ${OPATCH_ERR}"
                return 1
            fi
            cd -
            # remove binary packages on docker builds
            running_in_docker && rm -rf ${SOFTWARE}/${PATCH_PKG}
            rm -rf ${TMP_DIR}/${PATCH_ID}          # remove the binary packages
            rm -rf ${TMP_DIR}/PatchSearch.xml          # remove the binary packages
            DoMsg "INFO : Successfully install patch package ${PATCH_PKG}"
        else
            DoMsg "WARN : Could not find local or remote patch package ${PATCH_PKG}. Skip patch installation for ${PATCH_PKG}"
            DoMsg "WARN : Skip patch installation."
        fi
    else
        DoMsg "INFO : No package specified. Skip patch installation."
    fi
}
# - EOF Functions -------------------------------------------------------
# - Initialization ----------------------------------------------------------
# Make sure root does not run our script
if [ ! $EUID -ne 0 ]; then
   CleanAndQuit 3 "root"
fi

# Define Logfile
LOGFILE="${LOG_BASE}/$(basename ${SCRIPT_NAME} .sh).log"
touch ${LOGFILE} 2>/dev/null
if [ $? -eq 0 ] && [ -w "${LOGFILE}" ]; then
    DOAPPEND="TRUE"
else
    CleanAndQuit 11 ${LOGFILE} # Define a clean exit
fi

# fuser issue see MOS Note 2429708.1 OPatch Fails with Error "fuser could not be located"
running_in_docker && export OPATCH_NO_FUSER=true

# usage and getopts
while getopts b:hj:m:n:t:vAC:O:P:T:U:V:W:I:E: arg; do
    case $arg in
        h) Usage 0;;
        b) export ORACLE_BASE="${OPTARG}";;
        j) export JAVA_HOME="${OPTARG}";;
        m) export ORACLE_HOME="${OPTARG}";;
        n) export ORACLE_HOME_NAME="${OPTARG}";;
        t) export OUD_TYPE="${OPTARG}";;
        v) VERBOSE="TRUE";;
        A) LATEST="TRUE";;
        C) export COHERENCE_PATCH_PKG="${OPTARG}";;
        O) export OUD_BASE_PKG="${OPTARG}";;
        P) export OUD_ONEOFF_PKGS="${OPTARG}";;
        T) export OUD_PATCH_PKG="${OPTARG}";;
        U) export FMW_PATCH_PKG="${OPTARG}";;
        V) export OUD_OPATCH_PKG="${OPTARG}";;
        W) export FMW_BASE_PKG="${OPTARG}";;
        I) export OUI_PATCH_PKG="${OPTARG}";;
        E) CleanAndQuit "${OPTARG}";;
        ?) Usage 2 $*;;
    esac
done

# set default values
OUD_TYPE=${OUD_TYPE:-${DEFAULT_OUD_TYPE}}

if [ "${LATEST^^}" == "TRUE" ]; then
    DoMsg "INFO : Define the latest patches"
    export OUD_PATCH_PKG=${DEFAULT_OUD_PATCH_PKG}
    export FMW_PATCH_PKG=${DEFAULT_FMW_PATCH_PKG}
    export COHERENCE_PATCH_PKG=${DEFAULT_COHERENCE_PATCH_PKG}
    export OUI_PATCH_PKG=${DEFAULT_OUI_PATCH_PKG}
    export OUD_OPATCH_PKG=${DEFAULT_OUD_OPATCH_PKG}
    export OUD_ONEOFF_PKGS=${DEFAULT_OUD_ONEOFF_PKGS}
fi

if [ -n "${ORACLE_HOME_NAME}" ]; then 
    export ORACLE_HOME="${ORACLE_BASE}/product/${ORACLE_HOME_NAME}"
fi

# show what we will create later on...
DoMsg "INFO : Prepare Oracle OUD patch installation ---------------------------"
DoMsg "INFO : ORACLE_ROOT           = ${ORACLE_ROOT:-n/a}"
DoMsg "INFO : ORACLE_DATA           = ${ORACLE_DATA:-n/a}"
DoMsg "INFO : ORACLE_BASE           = ${ORACLE_BASE:-n/a}"
DoMsg "INFO : ORACLE_HOME           = ${ORACLE_HOME:-n/a}"
DoMsg "INFO : ORACLE_INVENTORY      = ${ORACLE_INVENTORY:-n/a}"
DoMsg "INFO : OUD_TYPE              = ${OUD_TYPE:-n/a}"
DoMsg "INFO : SOFTWARE              = ${SOFTWARE:-n/a}"
DoMsg "INFO : SOFTWARE_REPO         = ${SOFTWARE_REPO:-n/a}"
DoMsg "INFO : TMP_DIR               = ${TMP_DIR:-n/a}"
DoMsg "INFO : OUD_BASE_PKG          = ${OUD_BASE_PKG:-n/a}"
DoMsg "INFO : FMW_BASE_PKG          = ${FMW_BASE_PKG:-n/a}"
DoMsg "INFO : OUD_PATCH_PKG         = ${OUD_PATCH_PKG:-n/a}"
DoMsg "INFO : FMW_PATCH_PKG         = ${FMW_PATCH_PKG:-n/a}"
DoMsg "INFO : OUD_OPATCH_PKG        = ${OUD_OPATCH_PKG:-n/a}"
DoMsg "INFO : OUI_PATCH_PKG         = ${OUI_PATCH_PKG:-n/a}"
DoMsg "INFO : COHERENCE_PATCH_PKG   = ${COHERENCE_PATCH_PKG:-n/a}"
DoMsg "INFO : OUD_ONEOFF_PKGS       = ${OUD_ONEOFF_PKGS:-n/a}"
# - EOF Initialization ------------------------------------------------------

# - Main --------------------------------------------------------------------
# - Install OPatch ----------------------------------------------------------
DoMsg "INFO : Step 1 Install OPatch (${OUD_OPATCH_PKG}) ---------------------"
if [ -n "${OUD_OPATCH_PKG}" ]; then
    if get_software "${OUD_OPATCH_PKG}"; then       # Check and get binaries
        DoMsg "INFO : unzip ${SOFTWARE}/${OUD_OPATCH_PKG} to ${TMP_DIR}"
        unzip -q -o ${SOFTWARE}/${OUD_OPATCH_PKG} \
            -d ${TMP_DIR}/                         # unpack OPatch binary package
        # install the OPatch using java
        $JAVA_HOME/bin/java -jar ${TMP_DIR}/6880880/opatch_generic.jar \
            -ignoreSysPrereqs -force \
            -silent oracle_home=${ORACLE_HOME}
        rm -rf ${TMP_DIR}/6880880
        running_in_docker && rm -rf ${SOFTWARE}/${OUD_OPATCH_PKG}
    else
        DoMsg "WARN : Could not find local or remote patch package ${OUD_OPATCH_PKG}. Skip patch installation for ${OUD_OPATCH_PKG}"
        DoMsg "WARN : Skip patch installation."
    fi
else
    DoMsg "INFO : No OPatch package specified. Skip OPatch update."
fi

# - Install OUI patch -------------------------------------------------------
DoMsg "INFO : Step 2 Install OUI patch (${OUI_PATCH_PKG}) -------------------"
install_patch ${OUI_PATCH_PKG}

DoMsg "INFO : Step 3 Install FMW patch (${FMW_PATCH_PKG}) -------------------"
if [ "${OUD_TYPE}" == "OUDSM12" ]; then
    install_patch ${FMW_PATCH_PKG}
else
    DoMsg "INFO : OUD_TYPE=${OUD_TYPE} Skip FMW patch -----------------------"
fi

# - Install Coherence patch -------------------------------------------------------
DoMsg "INFO : Step 4 Install Coherence patch (${COHERENCE_PATCH_PKG}) ------------"
if [ "${OUD_TYPE}" == "OUDSM12" ]; then
    if [ -n "${COHERENCE_PATCH_PKG}" ]; then
        if get_software "${COHERENCE_PATCH_PKG}"; then        # Check and get binaries
            COHERENCE_PATCH_ID=$(unzip -qql ${SOFTWARE}/${COHERENCE_PATCH_PKG}| sed -r '1 {s/([ ]+[^ ]+){3}\s+//;q}')
            DoMsg "INFO : unzip ${SOFTWARE}/${COHERENCE_PATCH_PKG} to ${TMP_DIR}"
            unzip -q -o ${SOFTWARE}/${COHERENCE_PATCH_PKG} \
                -d ${TMP_DIR}/                         # unpack OPatch binary package
            cd ${TMP_DIR}/${COHERENCE_PATCH_ID}
            ${ORACLE_HOME}/OPatch/opatch apply -silent
            OPATCH_ERR=$?
            if [ ${OPATCH_ERR} -ne 0 ]; then
                DoMsg "WARN : opatch apply failed with error ${OPATCH_ERR}"
                return 1
            fi
            cd -
            # remove binary packages on docker builds
            running_in_docker && rm -rf ${SOFTWARE}/${COHERENCE_PATCH_PKG}
            rm -rf ${TMP_DIR}/${COHERENCE_PATCH_ID}          # remove the binary packages
            rm -rf ${TMP_DIR}/PatchSearch.xml          # remove the binary packages
            DoMsg "INFO : Successfully install patch package ${PATCH_PKG}"
        else
            DoMsg "WARN : Could not find local or remote patch package ${COHERENCE_PATCH_PKG}. Skip patch installation for ${COHERENCE_PATCH_PKG}"
            DoMsg "WARN : Skip patch installation."
        fi
    else
        DoMsg "INFO : No OPatch package specified. Skip OPatch update."
    fi
else
    DoMsg "INFO : OUD_TYPE=${OUD_TYPE} Skip Coherence patch -----------------------"
fi

# - Install OUD patch -------------------------------------------------------
DoMsg "INFO : Step 5 Install OUD patch (${OUD_PATCH_PKG}) -------------------"
install_patch ${OUD_PATCH_PKG}

echo " - Step 6: Install One-off patches ------------------------------------"
if [ -n "${OUD_ONEOFF_PKGS}" ]; then
    for oneoff_patch in $(echo "${OUD_ONEOFF_PKGS}"|sed s/\;/\ /g); do
        DoMsg "INFO : Step 6.x: Install One-off patch ${oneoff_patch} ------------"
        install_patch ${oneoff_patch}
    done
else
    DoMsg "INFO : No one-off packages specified. Skip one-off installation."
fi

DoMsg "INFO : List opatch inventory ----------------------------------------------"
cd ${CURRENT_DIR}
${ORACLE_HOME}/OPatch/opatch lsinventory

DoMsg "INFO : CleanUp OUD patch installation -------------------------------------"
# Remove not needed components
if running_in_docker; then
    DoMsg "INFO : remove Docker specific stuff"
    rm -rf ${ORACLE_HOME}/inventory/backup/*    # OUI backup
    rm -rf ${ORACLE_HOME}/.patch_storage        # remove patch storage
fi

if [ "${DEBUG^^}" == "TRUE" ]; then
    DoMsg "INFO : \$DEBUG set to TRUE, keep temp and log files"
else
    DoMsg "INFO : \$DEBUG not set, remove temp and log files"
    # Temp locations
    DoMsg "INFO : remove temp files"
    rm -rf ${TMP_DIR}
    rm -rf /tmp/InstallActions*
    rm -rf /tmp/CVU*oracle
    rm -rf /tmp/OraInstall*
    # remove all the logs....
    DoMsg "INFO : remove log files in \${ORACLE_INVENTORY} and \${ORACLE_BASE}/product"
    find ${ORACLE_INVENTORY} -type f -name '*.log' -exec rm {} \;
    find ${ORACLE_BASE}/product -type f -name '*.log' -exec rm {} \;
fi

if [ "${SLIM^^}" == "TRUE" ]; then
    DoMsg "INFO : \$SLIM set to TRUE, remove other stuff..."
    rm -rf ${ORACLE_HOME}/inventory                 # remove inventory
    rm -rf ${ORACLE_HOME}/oui                       # remove oui
    rm -rf ${ORACLE_HOME}/OPatch                    # remove OPatch
    rm -rf ${TMP_DIR}
    rm -rf /tmp/OraInstall*
    rm -rf ${ORACLE_HOME}/.patch_storage            # remove patch storage
fi
# --- EOF --------------------------------------------------------------------