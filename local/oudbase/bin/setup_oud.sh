#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: setup_oud.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.03.06
# Version....: v2.12.7
# Purpose....: generic script to install Oracle Unified Directory binaries.
# Notes......: Script would like to be executed as oracle :-).
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------
# define default software packages
DEFAULT_FMW_BASE_PKG="fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip"
DEFAULT_OUD_BASE_PKG="p30188352_122140_Generic.zip"
DEFAULT_OUD_PATCH_PKG="p34682234_122140_Generic.zip"
DEFAULT_FMW_PATCH_PKG="p34883826_122140_Generic.zip"
DEFAULT_OUD_OPATCH_PKG="p28186730_1394211_Generic.zip"
DEFAULT_OUI_PATCH_PKG=""
DEFAULT_COHERENCE_PATCH_PKG="p34845927_122140_Generic.zip"
DEFAULT_OUD_ONEOFF_PKGS=""

# ORACLE_HOME_NAME="oud12.2.1.4.0"                    # Name of the Oracle Home directory
# ORACLE_HOME="${ORACLE_BASE}/product/${ORACLE_HOME_NAME}"
# - End of Customization -------------------------------------------------------

# - Default Values ------------------------------------------------------
VERSION=v2.12.7
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0

DOAPPEND="TRUE"                                 # enable log file append
export VERBOSE=${VERBOSE:-"FALSE"}              # enable debug mode
export CLEANUP=${CLEANUP:-"true"}               # Flag to set yum clean up
export SLIM=${SLIM:-"false"}                    # flag to enable SLIM setup
export DEBUG=${DEBUG:-"FALSE"}                  # enable debug mode
export PATCH_LATER=${PATCH_LATER:-"FALSE"}      # Flag to postpone patch and clear stuff
# define oradba specific variables
export SETUP_OUD_PATCH="setup_oud_patch.sh"     # OUD patch script
export OUD_FUNCTIONS="oud_functions.sh"         # OUD oud_functions script
# source common functions from oud_functions.sh
. ${SCRIPT_DIR}/${OUD_FUNCTIONS}
DEFAULT_TMP_DIR=$(mktemp -d)                            # create a temp directory
DEFAULT_RSP_FILE=${DEFAULT_TMP_DIR}/oud_install.rsp     # default response file
DEFAULT_LOCK_FILE=${DEFAULT_TMP_DIR}/oraInst.loc        # default lock file
DEFAULT_OUD_TYPE=${OUD_TYPE:-"OUD12"}

# define the software packages default is just the OUD 12.2.1.4 base package
export OUD_BASE_PKG=${OUD_BASE_PKG:-"${DEFAULT_OUD_BASE_PKG}"} # OUD 12.2.1.4.0
export FMW_BASE_PKG=${FMW_BASE_PKG:-"${DEFAULT_FMW_BASE_PKG}"}                             
export OUD_PATCH_PKG=${OUD_PATCH_PKG:-""}
export FMW_PATCH_PKG=${FMW_PATCH_PKG:-""}
export OUD_OPATCH_PKG=${OUD_OPATCH_PKG:-""}
export OUI_PATCH_PKG=${OUI_PATCH_PKG:-""}
export COHERENCE_PATCH_PKG=${COHERENCE_PATCH_PKG:-""}
export OPATCH_NO_FUSER=true
export OUD_ONEOFF_PKGS=${OUD_ONEOFF_PKGS:-""}
export OUD_INSTALL_TYPE=${OUD_INSTALL_TYPE:-'Standalone Oracle Unified Directory Server (Managed independently of WebLogic server)'}

# define Oracle specific variables
export ORACLE_ROOT=${ORACLE_ROOT:-"/u00"}
export ORACLE_BASE=${ORACLE_BASE:-"${ORACLE_ROOT}/app/oracle"}
export SOFTWARE=${SOFTWARE:-"${ORACLE_BASE}/software"}
export ORACLE_INVENTORY=${ORACLE_INVENTORY:-"${ORACLE_ROOT}/app/oraInventory"}
export ORACLE_HOME_NAME=${ORACLE_HOME_NAME:-"oud12.2.1.4.0"}
export ORACLE_HOME="${ORACLE_HOME:-${ORACLE_BASE}/product/${ORACLE_HOME_NAME}}"

# define generic variables for software, download etc
export JAVA_HOME=${JAVA_HOME:-$(dirname $(dirname $(find ${ORACLE_BASE} /usr/java -name javac 2>/dev/null|sort -r|head -1) 2>/dev/null) 2>/dev/null)}
CURRENT_DIR=$(pwd)
# - EOF Environment Variables --------------------------------------------------

# - Functions ------------------------------------------------------------------
# ------------------------------------------------------------------------------
function Usage() {
# Purpose....: Display Usage
# ------------------------------------------------------------------------------
    VERBOSE="TRUE"
    DoMsg "Usage, ${SCRIPT_NAME} [-hvAL] [-b <ORACLE_BASE>] [-i <ORACLE_INVENTORY>]"
    DoMsg "    [-S <SOFTWARE>] [-R <SOFTWARE_REPO>] [-j <JAVA_HOME>] [-l <LOCK FILE>]"
    DoMsg "    [-m <ORACLE_HOME>] [-n <ORACLE_HOME_NAME>] [-r <RESPONSE FILE>]"
    DoMsg "    [-t <INSTALL TYPE>] [-C <COHERENCE_PATCH_PKG>] [-O <OUD_BASE_PKG FILE>]"
    DoMsg "    [-P <OUD_ONEOFF_PKGS>] [-T <OUD_PATCH_PKG>] [-U <FMW_PATCH_PKG>]"
    DoMsg "    [-V <OUD_OPATCH_PKG>] [-W <FMW_BASE_PKG>] [-I <OUI_PATCH_PKG>]"
    DoMsg ""
    DoMsg "    -b <ORACLE_BASE>         ORACLE_BASE Directory. (default \$ORACLE_BASE=${ORACLE_BASE})"
    DoMsg "    -i <ORACLE_INVENTORY>    ORACLE_INVENTORY Directory. (default \$ORACLE_INVENTORY=${ORACLE_INVENTORY})"
    DoMsg "    -S <SOFTWARE>            Directory containing the installation packages and software. (default \$SOFTWARE=${ORACLE_BASE}/software)"
    DoMsg "    -R <SOFTWARE_REPO>       URL of a software repository to to download the packages/software alternatively. (default \$SOFTWARE_REPO=${SOFTWARE_REPO})"
    DoMsg "    -h                       Usage this message"
    DoMsg "    -j <JAVA_HOME>           JAVA_HOME directory. If not set we will search for java in \$ORACLE_BASE/products)"
    DoMsg "    -l <LOCK FILE>           Specify a dedicated lock file (default ${DEFAULT_LOCK_FILE})"
    DoMsg "    -m <ORACLE_HOME>         Oracle home directory for OUD binaries "
    DoMsg "                             (default \$ORACLE_HOME=$ORACLE_BASE/products/$ORACLE_HOME_NAME)"
    DoMsg "    -n <ORACLE_HOME_NAME>    Name for the Oracle home folder. Can be used to overwrite \$ORACLE_HOME"
    DoMsg "                             (default \$ORACLE_HOME_NAME=${ORACLE_HOME_NAME})"
    DoMsg "    -r <RESPONSE FILE>       Specify a dedicated response file (default ${DEFAULT_RSP_FILE})"
    DoMsg "    -t <INSTALL TYPE>        OUD install type OUD12,OUDSM12 or OUD11 (default ${DEFAULT_OUD_TYPE})"
    DoMsg "    -v                       enable verbose mode"
    DoMsg "    -A                       Install latest default patches"
    DoMsg "                             \$OUD_PATCH_PKG=${DEFAULT_OUD_PATCH_PKG}"
    DoMsg "                             \$FMW_PATCH_PKG=${DEFAULT_FMW_PATCH_PKG}"
    DoMsg "                             \$OUD_OPATCH_PKG=${DEFAULT_OUD_OPATCH_PKG}"
    DoMsg "    -L                       Do not install any patches"
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
# - EOF Functions --------------------------------------------------------------
# - Initialization -------------------------------------------------------------
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
while getopts b:i:S:R:hj:l:m:n:r:t:vALC:O:P:T:U:V:W:I:E: arg; do
    case $arg in
        h) Usage 0;;
        l) LOCK_FILE="${OPTARG}";;
        r) RSP_FILE="${OPTARG}";;
        L) PATCH_LATER="TRUE";;     
        b) export ORACLE_BASE="${OPTARG}";;
        i) export ORACLE_INVENTORY="${OPTARG}";;
        S) export SOFTWARE="${OPTARG}";;
        R) export SOFTWARE_REPO="${OPTARG}";;
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
        ?) Usage 2 $*;;
    esac
done

# set default values
RSP_FILE=${RSP_FILE:-${DEFAULT_RSP_FILE}}
LOCK_FILE=${LOCK_FILE:-${DEFAULT_LOCK_FILE}}
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

# Create a list of software based on environment variables ending with _PKG or _PKGS
SOFTWARE_LIST=""                        # initial values of SOFTWARE_LIST
SOFTWARE_VARIABLES=""                   # initial list SOFTWARE VARIABLES
if [ "${OUD_TYPE}" == "OUDSM12" ]; then
    # create list of software for OUD and collocated installations
    SOFTWARE_VARIABLES=$(env|cut -d= -f1|grep '_PKG$\|_PKGS$'|grep -v '^DEFAULT')
else
    # create list of software for OUD and standalone installations
    SOFTWARE_VARIABLES=$(env|cut -d= -f1|grep '_PKG$\|_PKGS$'|grep -v '^DEFAULT\|^FMW\|^COHERENCE')
fi

for i in ${SOFTWARE_VARIABLES}; do
    # check if environment variable is not empty and value not yet part of SOFTWARE_LIST
    if [ -n "${!i}" ] && [[ $SOFTWARE_LIST != *"${!i}"* ]]; then
        SOFTWARE_LIST+="${!i};"
    fi
done
export SOFTWARE_LIST=$(echo $SOFTWARE_LIST|sed 's/.$//')

# check Software folder
if [ -d "${SOFTWARE}" ] || [ -w "${SOFTWARE}" ]; then
    TMP_DIR=$(mktemp -p ${SOFTWARE} -d)             # create a temp directory
    for i in ${SOFTWARE_LIST//;/ }; do
        if [ $(find ${SOFTWARE} -name $i | wc -l) -eq 0 ]; then
            CleanAndQuit 15 ${i}             # Define a clean exit
        fi
    done
else
    DoMsg "INFO : Sofware repository is ready"
fi

if [ -n "${ORACLE_HOME_NAME}" ]; then 
    export ORACLE_HOME="${ORACLE_BASE}/product/${ORACLE_HOME_NAME}"
fi

# show what we will create later on...
DoMsg "INFO : Prepare Oracle OUD binaries installation ---------------------------"
DoMsg "INFO : ORACLE_ROOT           = ${ORACLE_ROOT:-n/a}"
DoMsg "INFO : ORACLE_DATA           = ${ORACLE_DATA:-n/a}"
DoMsg "INFO : ORACLE_BASE           = ${ORACLE_BASE:-n/a}"
DoMsg "INFO : ORACLE_HOME           = ${ORACLE_HOME:-n/a}"
DoMsg "INFO : ORACLE_INVENTORY      = ${ORACLE_INVENTORY:-n/a}"
DoMsg "INFO : OUD_TYPE              = ${OUD_TYPE:-n/a}"
DoMsg "INFO : SOFTWARE              = ${SOFTWARE:-n/a}"
DoMsg "INFO : SOFTWARE_REPO         = ${SOFTWARE_REPO:-n/a}"
DoMsg "INFO : DEFAULT_TMP_DIR       = ${DEFAULT_TMP_DIR:-n/a}"
DoMsg "INFO : TMP_DIR               = ${TMP_DIR:-n/a}"
DoMsg "INFO : RSP_FILE              = ${RSP_FILE:-n/a}"
DoMsg "INFO : LOCK_FILE             = ${LOCK_FILE:-n/a}"
DoMsg "INFO : OUD_BASE_PKG          = ${OUD_BASE_PKG:-n/a}"
DoMsg "INFO : FMW_BASE_PKG          = ${FMW_BASE_PKG:-n/a}"
DoMsg "INFO : OUD_PATCH_PKG         = ${OUD_PATCH_PKG:-n/a}"
DoMsg "INFO : FMW_PATCH_PKG         = ${FMW_PATCH_PKG:-n/a}"
DoMsg "INFO : OUD_OPATCH_PKG        = ${OUD_OPATCH_PKG:-n/a}"
DoMsg "INFO : OUI_PATCH_PKG         = ${OUI_PATCH_PKG:-n/a}"
DoMsg "INFO : COHERENCE_PATCH_PKG   = ${COHERENCE_PATCH_PKG:-n/a}"
DoMsg "INFO : OUD_ONEOFF_PKGS       = ${OUD_ONEOFF_PKGS:-n/a}"

# Replace place holders in responce file
DoMsg "INFO : Prepare response files ---------------------------------------------"
if [ ! -f ${RSP_FILE} ]; then
    DoMsg "INFO : Response file does not yet exists. Create new response file"
    cat << EOF > ${RSP_FILE}
[ENGINE]
Response File Version=1.0.0.0.0
[GENERIC]
DECLINE_SECURITY_UPDATES=true
SECURITY_UPDATES_VIA_MYORACLESUPPORT=false
SPECIFY_DOWNLOAD_LOCATION=false
SKIP_SOFTWARE_UPDATES=true
SOFTWARE_UPDATES_DOWNLOAD_LOCATION=
CONFIG_WIZARD_RESPONSE_FILE_LOCATION=0
EOF
else
    DoMsg "INFO : User existing response file ${RSP_FILE}"
fi

if [ ! -f ${LOCK_FILE} ]; then    
    DoMsg "INFO : Lock file does not yet exists. Create new lock file"
    cat << EOF > ${LOCK_FILE}
inventory_loc=${ORACLE_INVENTORY}
inst_group=oinstall
EOF
else
    DoMsg "INFO : User existing lock file ${LOCK_FILE}"
fi

# create product directory 
mkdir -p $(dirname ${ORACLE_HOME})
# check if oracle home does exists
if [ -d "${ORACLE_HOME}" ]; then
    CleanAndQuit 14 ${ORACLE_HOME}
fi
# - EOF Initialization ---------------------------------------------------------

# - Main -----------------------------------------------------------------------

# - Install FWM Binaries -------------------------------------------------------
# - just required if you setup OUDSM
if [ "${OUD_TYPE}" == "OUDSM12" ]; then
    DoMsg "INFO : Install Oracle FMW binaries ----------------------------------------"
    export OUD_INSTALL_TYPE='Collocated Oracle Unified Directory Server (Managed through WebLogic server)'
    if [ -n "${FMW_BASE_PKG}" ]; then
        if get_software "${FMW_BASE_PKG}"; then          # Check and get binaries
            SOFTWARE_PKG=$(find ${SOFTWARE} -name ${FMW_BASE_PKG} 2>/dev/null| head -1)
            cd ${TMP_DIR}
            # unpack OUD binary package
            FMW_BASE_LOG=$(basename ${FMW_BASE_PKG} .zip).log
            ${JAVA_HOME}/bin/jar xvf ${SOFTWARE_PKG} >${FMW_BASE_LOG}

            # get the jar file name from the logfile
            FMW_BASE_JAR=$(grep -i jar ${FMW_BASE_LOG} |cut -d' ' -f3| tr -d " ")

            # Install OUD binaries
            ${JAVA_HOME}/bin/java -jar ${TMP_DIR}/$FMW_BASE_JAR -silent \
            -responseFile ${RSP_FILE} \
            -invPtrLoc ${LOCK_FILE} \
            -ignoreSysPrereqs -force \
            -novalidation ORACLE_HOME=${ORACLE_HOME} \
            INSTALL_TYPE="WebLogic Server"

            # remove files on docker builds
            rm -rf ${TMP_DIR}/$FMW_BASE_JAR
            running_in_docker && rm -rf ${SOFTWARE}/${FMW_BASE_PKG}
        else
            CleanAndQuit 80 ${OUD_BASE_PKG}
        fi
    fi
fi

# - Install OUD binaries -------------------------------------------------------
DoMsg "INFO : Install Oracle OUD binaries ----------------------------------------"
if [ -n "${OUD_BASE_PKG}" ]; then
    if get_software "${OUD_BASE_PKG}"; then          # Check and get binaries
        SOFTWARE_PKG=$(find ${SOFTWARE} -name ${OUD_BASE_PKG} 2>/dev/null| head -1)
        cd ${TMP_DIR}
        # unpack OUD binary package
        OUD_BASE_LOG=$(basename ${OUD_BASE_PKG} .zip).log
        ${JAVA_HOME}/bin/jar xvf ${SOFTWARE_PKG} >${OUD_BASE_LOG}
        # identify OUD major release based on OUD_TYPE
        if [ "${OUD_TYPE}" == "OUD12" ] || [ "${OUD_TYPE}" == "OUDSM12" ]; then
            DoMsg "INFO : Start to install OUD 12c (${OUD_TYPE})"
            # get the jar file name from the logfile
            OUD_BASE_JAR=$(grep -i jar ${OUD_BASE_LOG} |cut -d' ' -f3| tr -d " ")

            # Install OUD binaries
            ${JAVA_HOME}/bin/java -jar ${TMP_DIR}/$OUD_BASE_JAR -silent \
                -responseFile ${RSP_FILE} \
                -invPtrLoc ${LOCK_FILE} \
                -ignoreSysPrereqs -force \
                -novalidation ORACLE_HOME=${ORACLE_HOME} \
                INSTALL_TYPE="${OUD_INSTALL_TYPE}"

            # remove files on docker builds
            rm -rf ${TMP_DIR}/$OUD_BASE_JAR
            running_in_docker && rm -rf ${SOFTWARE_PKG}
        else
            DoMsg "INFO : Start to install OUD 11g"
            chmod -R u+x ${TMP_DIR}/Disk1
            # Install OUD binaries
            ${TMP_DIR}/Disk1/runInstaller -silent \
                -jreLoc ${JAVA_HOME} \
                -waitforcompletion \
                -ignoreSysPrereqs -force \
                -responseFile ${RSP_FILE} \
                -invPtrLoc ${LOCK_FILE} \
                ORACLE_HOME=${ORACLE_HOME}
        
            # remove files on docker builds
            rm -rf ${TMP_DIR}/Disk1
            running_in_docker && rm -rf ${SOFTWARE_PKG}
        fi
    else
        CleanAndQuit 80 ${OUD_BASE_PKG}
    fi
fi

# install patch any of the patch variable is if defined
if [ ! -z "${OUD_PATCH_PKG}" ] || [ ! -z "${FMW_PATCH_PKG}" ] || [ ! -z "${OUD_OPATCH_PKG}" ] || [ ! -z "${OUI_PATCH_PKG}" ] || [ ! -z "${COHERENCE_PATCH_PKG}" ] || [ ! -z "${OUD_ONEOFF_PKGS}" ] && [ "${PATCH_LATER^^}" == "FALSE" ]; then  
    ${SCRIPT_DIR}/${SETUP_OUD_PATCH} "$@"

elif [ "${PATCH_LATER^^}" == "TRUE" ]; then
    DoMsg "INFO : Patch later. PATCH_LATER=$PATCH_LATER"
else
    DoMsg "INFO : Skip patch installation. No patch packages specified."
fi

DoMsg "INFO : CleanUp OUD installation -------------------------------------------"
# Remove not needed components
if running_in_docker && [ "${PATCH_LATER^^}" == "FALSE" ]; then
    DoMsg "INFO : remove Docker specific stuff"
    rm -rf ${ORACLE_HOME}/inventory/backup/*            # OUI backup
fi

if [ "${DEBUG^^}" == "TRUE" ]; then
    DoMsg "INFO : \$DEBUG set to TRUE, keep temp and log files"
else
    DoMsg "INFO : \$DEBUG not set, remove temp and log files"
    # Temp locations
    DoMsg "INFO : remove temp files"
    rm -rf ${TMP_DIR}
fi

if [ "${SLIM^^}" == "TRUE" ] && [ "${PATCH_LATER^^}" == "FALSE" ]; then
    DoMsg "INFO : \$SLIM set to TRUE, remove other stuff..."
    rm -rf ${ORACLE_HOME}/inventory                 # remove inventory
    rm -rf ${ORACLE_HOME}/oui                       # remove oui
    rm -rf ${ORACLE_HOME}/OPatch                    # remove OPatch
    rm -rf ${TMP_DIR}
    rm -rf ${ORACLE_HOME}/.patch_storage            # remove patch storage
    rm -rf /tmp/InstallActions*
    rm -rf /tmp/CVU*oracle
    rm -rf /tmp/OraInstall*
    # remove all the logs....
    DoMsg "INFO : remove log files in \${ORACLE_INVENTORY} and \${ORACLE_BASE}/product"
    find ${ORACLE_INVENTORY} -type f -name '*.log' -exec rm {} \;
    find ${ORACLE_BASE}/product -type f -name '*.log' -exec rm {} \;
fi
# --- EOF ----------------------------------------------------------------------