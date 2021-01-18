#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: oudbase_install.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: This script is used as base install script for the OUD 
#              Environment
# Notes......: --
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...::175
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - Customization -------------------------------------------------------
export LOG_BASE=${LOG_BASE-"/tmp"}
# - End of Customization ------------------------------------------------

# - Default Values ------------------------------------------------------
VERSION=v1.9.4
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="TRUE"                                  # enable verbose mode
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"     # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"       # Full qualified script name
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
BASE64_BIN=$(find /usr/bin -name base64 -print) # executable for base64
BASE64_BIN=${BASE64_BIN:-"$(command -v -p base64)"} # executable for base64
TAR_BIN=$(command -v -p tar)                    # executable for tar
GZIP_BIN=$(command -v -p gzip)                    # executable for tar
OUD_CORE_CONFIG="oudenv_core.conf"
CONFIG_FILES="oudtab oud._DEFAULT_.conf oudenv.conf oudenv_custom.conf"
PAYLOAD_BINARY=0                                # default disable binary payload 
PAYLOAD_BASE64=1                                # default enable base64 payload 

# a few core default values.
DEFAULT_ORACLE_BASE="/u00/app/oracle"
SYSTEM_JAVA_PATH=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_OUD_DATA="/u01"
DEFAULT_ORACLE_DATA=${DEFAULT_OUD_DATA}
# Default values for file and folder names
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.4.0"
DEFAULT_ORACLE_HOME_NAME="fmw12.2.1.4.0"
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_BASE_NAME="oudbase"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUD_LOCAL_BASE_BIN_NAME="bin"
DEFAULT_OUD_LOCAL_BASE_ETC_NAME="etc"
DEFAULT_OUD_LOCAL_BASE_LOG_NAME="log"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_OUD_LOCAL_BASE_TEMPLATES_NAME="templates"
DEFAULT_OUDSM_DOMAIN_BASE_NAME="domains"
DEFAULT_PRODUCT_BASE_NAME="product"
OUD_CORE_CONFIG="oudenv_core.conf"

# - End of Default Values -----------------------------------------------

# - Functions -----------------------------------------------------------

# -----------------------------------------------------------------------
# Purpose....: Display Usage
# -----------------------------------------------------------------------
function Usage()
{
    VERBOSE="TRUE"
    DoMsg "Usage, ${SCRIPT_NAME} [-hav] [-b <ORACLE_BASE>] "
    DoMsg "    [-i <OUD_INSTANCE_BASE>] [-B <OUD_BACKUP_BASE>]"
    DoMsg "    [-m <ORACLE_HOME>] [-f <ORACLE_FMW_HOME>] [-j <JAVA_HOME>]"
    DoMsg "    [-e <ETC_BASE>] [-l <LOG_BASE>]"
    DoMsg ""
    DoMsg "    -h                          Usage (this message)"
    DoMsg "    -v                          enable verbose mode"
    DoMsg "    -a                          append to  profile eg. .bash_profile or .profile"
    DoMsg "    -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This "
    DoMsg "                                directory is use as OUD_BASE directory"
    DoMsg "    -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE/$DEFAULT_OUD_LOCAL_BASE_NAME/$DEFAULT_OUD_BASE_NAME)."
    DoMsg "    -d <OUD_DATA>               OUD_DATA Directory. (default /u01 if available otherwise \$ORACLE_BASE). "
    DoMsg "                                This directory has to be specified to distinct persistant data from software "
    DoMsg "                                eg. in a docker containers"
    DoMsg "    -A <OUD_ADMIN_BASE>         Base directory for OUD admin (default \$OUD_DATA/admin)"
    DoMsg "    -B <OUD_BACKUP_BASE>        Base directory for OUD backups (default \$OUD_DATA/backup)"
    DoMsg "    -i <OUD_INSTANCE_BASE>      Base directory for OUD instances (default \$OUD_DATA/instances)"
    DoMsg "    -m <ORACLE_HOME>            Oracle home directory for OUD binaries (default \$ORACLE_BASE/products)"
    DoMsg "    -f <ORACLE_FMW_HOME>        Oracle Fusion Middleware home directory. (default \$ORACLE_BASE/products)"
    DoMsg "    -j <JAVA_HOME>              JAVA_HOME directory. (default search for java in \$ORACLE_BASE/products)"
    DoMsg "    -e <ETC_BASE>               ETC_BASE directory for configuration files. (default \$OUD_BASE/etc respectively \$OUD_DATA/etc)"
    DoMsg "    -l <LOG_BASE>               LOG_BASE directory for log files. (default \$OUD_BASE/log respectively \$OUD_DATA/log)"
    DoMsg ""
    DoMsg "    Logfile : ${LOGFILE}"

    if [ ${1} -gt 0 ]; then
        CleanAndQuit ${1} ${2}
    else
        VERBOSE="FALSE"
        CleanAndQuit 0
    fi
}

# -----------------------------------------------------------------------
# Purpose....: Display Message with time stamp
# -----------------------------------------------------------------------
function DoMsg()
{
    INPUT=${1}
    PREFIX=${INPUT%:*}                 # Take everything before :
    case ${PREFIX} in                  # Define a nice time stamp for ERR, END
        "END  ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "ERR  ")        TIME_STAMP=$(date "+%n%Y-%m-%d_%H:%M:%S  ");;
        "START")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "OK   ")        TIME_STAMP="";;
        "INFO ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        *)              TIME_STAMP="";;
    esac
    if [ "${VERBOSE}" = "TRUE" ]; then
        if [ "${DOAPPEND}" = "TRUE" ]; then
            echo "${TIME_STAMP}${1}" |tee -a ${LOGFILE}
        else
            echo "${TIME_STAMP}${1}"
        fi
        shift
        while [ "${1}" != "" ]; do
            if [ "${DOAPPEND}" = "TRUE" ]; then
                echo "               ${1}" |tee -a ${LOGFILE}
            else
                echo "               ${1}"
            fi
            shift
        done
    else
        if [ "${DOAPPEND}" = "TRUE" ]; then
            echo "${TIME_STAMP}  ${1}" >> ${LOGFILE}
        fi
        shift
        while [ "${1}" != "" ]; do
            if [ "${DOAPPEND}" = "TRUE" ]; then
                echo "               ${1}" >> ${LOGFILE}
            fi
            shift
        done
    fi
}

# -----------------------------------------------------------------------
# Purpose....: Clean up before exit
# -----------------------------------------------------------------------
function CleanAndQuit()
{
    if [ ${1} -gt 0 ]; then
        VERBOSE="TRUE"
    fi
    case ${1} in
        0)  DoMsg "END  : of ${SCRIPT_NAME}";;
        1)  DoMsg "ERR  : Exit Code ${1}. Wrong amount of arguments. See usage for correct one.";;
        2)  DoMsg "ERR  : Exit Code ${1}. Wrong arguments (${2}). See usage for correct one.";;
        3)  DoMsg "ERR  : Exit Code ${1}. Missing mandatory argument ${2}. See usage for correct one.";;
        10) DoMsg "ERR  : Exit Code ${1}. OUD_BASE not set or $OUD_BASE not available.";;
        20) DoMsg "ERR  : Exit Code ${1}. Can not append to profile.";;
        30) DoMsg "ERR  : Exit Code ${1}. Missing ${2} can not proceed";;
        40) DoMsg "ERR  : Exit Code ${1}. This is not an Install package. Missing TAR payload or TAR file.";;
        41) DoMsg "ERR  : Exit Code ${1}. Error creating directory ${2}.";;
        42) DoMsg "ERR  : Exit Code ${1}. ORACEL_BASE directory not available ${2}";;
        43) DoMsg "ERR  : Exit Code ${1}. OUD_BASE directory not available";;
        44) DoMsg "ERR  : Exit Code ${1}. OUD_DATA directory not available";;
        11) DoMsg "ERR  : Exit Code ${1}. Could not touch file ${2}";;
        99) DoMsg "INFO : Just wanna say hallo.";;
        ?)  DoMsg "ERR  : Exit Code ${1}. Unknown Error.";;
    esac
    exit ${1}
}

# -----------------------------------------------------------------------
# Purpose....: get the payload from script
# -----------------------------------------------------------------------
function UntarPayload()
{
    # default values for payload
    PAYLOAD_BINARY=${PAYLOAD_BINARY:-0}
    PAYLOAD_BASE64=${PAYLOAD_BASE64:-1}
    
    
    DoMsg "INFO : Start processing the payload"
    MATCH=$(grep -n '^__TAR_PAYLOAD__$' $0 | cut -d ':' -f 1)
    PAYLOAD_START=$((MATCH + 1))

    # adjust os specific tar commands
    case "$OSTYPE" in
        aix*)       LOCAL_TAR="${GZIP_BIN} -c - | ${TAR_BIN} -xf -" ;;
        linux*)     LOCAL_TAR="${TAR_BIN} -xzv --exclude=\"._*\"" ;;
        *)          LOCAL_TAR="${TAR_BIN} -xzv --exclude=\"._*\"" ;;
    esac
    echo "LOCAL_TAR =>$LOCAL_TAR"
    # check if we do have a payload
    if [[ ${PAYLOAD_START} -gt 1 ]]; then
        DoMsg "INFO : Payload is available as of line ${PAYLOAD_START}."
        DoMsg "INFO : Extracting payload into ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}"
        if [[ ${PAYLOAD_BINARY} -ne 0 ]]; then
            DoMsg "INFO : Payload is set to binary, just use untar."
            tail -n +${PAYLOAD_START} ${SCRIPT_FQN} | ${TAR_BIN} -xzv --exclude="._*" -C ${OUD_BASE}
        elif [[ ${PAYLOAD_BASE64} -ne 0 ]]; then
            DoMsg "INFO : Payload is set to base64. Using base64 decode before untar."
            tail -n +${PAYLOAD_START} ${SCRIPT_FQN} | ${BASE64_BIN} --decode - | ${TAR_BIN} -xzv --exclude="._*" -C ${OUD_BASE}
        fi
    # fall back to local tar file
    else
        DoMsg "WARN : Could not find any payload try to use local tar file."
        TARFILE="$(dirname ${SCRIPT_FQN})/$(basename ${SCRIPT_FQN} .sh).tgz"      # LDIF file based on script name
        if [[ -f ${TARFILE} ]]; then
            DoMsg "INFO : Extracting local tar into ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}"
            ${TAR_BIN} -xzv --exclude="._*" -f ${TARFILE} -C ${OUD_BASE}
        else
            CleanAndQuit 40
        fi
    fi
}

# - EOF Functions -------------------------------------------------------

# - Initialization ------------------------------------------------------
tty >/dev/null 2>&1
pTTY=$?

# Define Logfile but first reset LOG_BASE if directory does not exists
if [ ! -d ${LOG_BASE} ] || [ ! -w ${LOG_BASE} ] ; then
    echo "INFO : set LOG_BASE to /tmp"
    export LOG_BASE="/tmp"
fi

LOGFILE="${LOG_BASE}/$(basename ${SCRIPT_NAME} .sh).log"
touch ${LOGFILE} 2>/dev/null
if [ $? -eq 0 ] && [ -w "${LOGFILE}" ]; then
    DOAPPEND="TRUE"
else
    CleanAndQuit 11 ${LOGFILE} # Define a clean exit
fi

# - Main ----------------------------------------------------------------
DoMsg "${START_HEADER}"
if [ $# -lt 1 ]; then
    Usage 1
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvab:o:d:i:m:A:B:E:f:j:e:l: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
      A) INSTALL_OUD_ADMIN_BASE="${OPTARG}";;
      B) INSTALL_OUD_BACKUP_BASE="${OPTARG}";;
      j) INSTALL_JAVA_HOME="${OPTARG}";;
      m) INSTALL_ORACLE_HOME="${OPTARG}";;
      f) INSTALL_ORACLE_FMW_HOME="${OPTARG}";;
      e) INSTALL_ETC_BASE="${OPTARG}";;
      l) INSTALL_LOG_BASE="${OPTARG}";;
      E) CleanAndQuit "${OPTARG}";;
      ?) Usage 2 $*;;
    esac
done

# Check if INSTALL_ORACLE_BASE is defined
if [ "${INSTALL_ORACLE_BASE}" = "" ]; then
    Usage 3 "-b"
fi

# Check if INSTALL_ORACLE_BASE exits
if [ ! -d "${INSTALL_ORACLE_BASE}" ]; then
    CleanAndQuit 42 ${INSTALL_ORACLE_BASE}
fi

# Check if INSTALL_ORACLE_BASE exits
if [ ! "${INSTALL_OUD_BASE}" = "" ] && [ ! -d "${INSTALL_OUD_BASE}" ]; then
    CleanAndQuit 43 ${INSTALL_OUD_BASE}
fi

# Check if INSTALL_ORACLE_BASE exits
if [ ! "${INSTALL_OUD_DATA}" = "" ] && [ ! -d "${INSTALL_OUD_DATA}" ]; then
    CleanAndQuit 44 ${INSTALL_OUD_DATA}
fi

# check if we do have an existing 
if [ -f  ${ETC_CORE}/${OUD_CORE_CONFIG} ]; then
    DoMsg "INFO : oudenv_core.conf does exists, assume upgrade..."
    for i in $(grep -v '^#' ${ETC_CORE}/${OUD_CORE_CONFIG}); do
        variable="UPGRADE_$(echo $i|cut -d= -f1)"
        export $variable=$(echo $i|cut -d= -f2)
    done
fi

# check if we do have a base64 tool
if [ -z "${BASE64_BIN}" ] && [ ${PAYLOAD_BASE64} -eq 1 ]; then 
    CleanAndQuit 30 "base64"
fi

# get the right TAR file
case "$OSTYPE" in
    aix*)     TAR_BIN=$(command -v gtar) ;; 
    linux*)   TAR_BIN=$(command -v -p tar);;
    *)        TAR_BIN=$(command -v -p tar);;
esac
# check if we do have a base64 tool
if [ -z "${TAR_BIN}" ]; then 
    CleanAndQuit 30 "tar"
fi

DoMsg "INFO : Define default values"
# define default values for a couple of directories and set the real 
# directories based on the cli or default values

# define ORACLE_BASE basically this should not be used since -b is a mandatory parameter
export ORACLE_BASE=${INSTALL_ORACLE_BASE:-"${DEFAULT_ORACLE_BASE}"}

# define OUD_BASE
DEFAULT_OUD_BASE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/${DEFAULT_OUD_BASE_NAME}"
INSTALL_OUD_BASE=${INSTALL_OUD_BASE:-${UPGRADE_OUD_BASE}}
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

# define OUD_DATA
DEFAULT_OUD_DATA=$(if [ -d "${DEFAULT_OUD_DATA}" ]; then echo ${DEFAULT_OUD_DATA}; else echo "${ORACLE_BASE}"; fi)
INSTALL_OUD_DATA=${INSTALL_OUD_DATA:-${UPGRADE_OUD_DATA}}
export OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}
export ORACLE_DATA=${ORACLE_DATA:-"${OUD_DATA}"}

# define OUD_INSTANCE_BASE
DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/${DEFAULT_OUD_INSTANCE_BASE_NAME}"
INSTALL_OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-${UPGRADE_OUD_INSTANCE_BASE}}
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

# define OUD_BACKUP_BASE
DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/${DEFAULT_OUD_BACKUP_BASE_NAME}"
INSTALL_OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-${UPGRADE_OUD_BACKUP_BASE}}
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

# define ORACLE_HOME
DEFAULT_ORACLE_HOME=$(find ${ORACLE_BASE} ! -readable -prune -o -name oud-setup -print |sed 's/\/oud\/oud-setup$//'|head -n 1)
DEFAULT_ORACLE_HOME=${DEFAULT_ORACLE_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_HOME_NAME}"}
INSTALL_ORACLE_HOME=${INSTALL_ORACLE_HOME:-${UPGRADE_ORACLE_HOME}}
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

# define ORACLE_FMW_HOME
DEFAULT_ORACLE_FMW_HOME=$(find ${ORACLE_BASE} ! -readable -prune -o -name oudsm-wlst.jar -print|sed -r 's/(\/[^\/]+){3}\/oudsm-wlst.jar//g'|head -n 1)
DEFAULT_ORACLE_FMW_HOME=${DEFAULT_ORACLE_FMW_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_FMW_HOME_NAME}"}
INSTALL_ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-${UPGRADE_ORACLE_FMW_HOME}}
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

# define JAVA_HOME
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA_PATH} ! -readable -prune -o -type f -name java -print |head -1) 2>/dev/null| sed "s:/bin/java::")
INSTALL_JAVA_HOME=${INSTALL_JAVA_HOME:-${UPGRADE_JAVA_HOME}}
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

# define OUD_BACKUP_BASE
DEFAULT_OUD_ADMIN_BASE="${OUD_DATA}/${DEFAULT_OUD_ADMIN_BASE_NAME}"
INSTALL_OUD_ADMIN_BASE=${INSTALL_OUD_ADMIN_BASE:-${UPGRADE_OUD_ADMIN_BASE}}
export OUD_ADMIN_BASE=${INSTALL_OUD_ADMIN_BASE:-"${DEFAULT_OUD_ADMIN_BASE}"}

# define ORACLE_PRODUCT
if [ "${INSTALL_ORACLE_HOME}" == "" ]; then
    ORACLE_PRODUCT=$(dirname ${ORACLE_HOME})
fi

# set the core etc directory
export ETC_CORE="${OUD_BASE}/etc" 

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
INSTALL_LOG_BASE=${INSTALL_LOG_BASE:-${UPGRADE_LOG_BASE}}
INSTALL_ETC_BASE=${INSTALL_ETC_BASE:-${UPGRADE_ETC_BASE}}
if [ "${ORACLE_BASE}" == "${OUD_DATA}" ]; then
    export LOG_BASE=${INSTALL_LOG_BASE:-"${OUD_BASE}/log"}
    export ETC_BASE=${INSTALL_ETC_BASE:-"${ETC_CORE}"}
else
    export LOG_BASE=${INSTALL_LOG_BASE:-"${OUD_DATA}/log"}
    export ETC_BASE=${INSTALL_ETC_BASE:-"${OUD_DATA}/etc"}
fi

# Print some information on the defined variables
DoMsg "INFO : Using the following variable for installation"
DoMsg "INFO : ORACLE_BASE          = $ORACLE_BASE"
DoMsg "INFO : OUD_BASE             = $OUD_BASE"
DoMsg "INFO : LOG_BASE             = $LOG_BASE"
DoMsg "INFO : ETC_CORE             = $ETC_CORE"
DoMsg "INFO : ETC_BASE             = $ETC_BASE"
DoMsg "INFO : OUD_DATA             = $OUD_DATA"
DoMsg "INFO : ORACLE_DATA          = $ORACLE_DATA"
DoMsg "INFO : OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "INFO : OUD_ADMIN_BASE       = $OUD_ADMIN_BASE"
DoMsg "INFO : OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "INFO : ORACLE_PRODUCT       = $ORACLE_PRODUCT"
DoMsg "INFO : ORACLE_HOME          = $ORACLE_HOME"
DoMsg "INFO : ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "INFO : JAVA_HOME            = $JAVA_HOME"
DoMsg "INFO : SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "INFO : Installing OUD Environment"
DoMsg "INFO : Create required directories in ORACLE_BASE=${ORACLE_BASE}"

for i in    ${LOG_BASE} \
            ${ETC_BASE} \
            ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME} \
            ${OUD_ADMIN_BASE} \
            ${OUD_BACKUP_BASE} \
            ${OUD_INSTANCE_BASE} \
            ${ORACLE_PRODUCT} \
            ${OUD_BASE}; do
    mkdir -p ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

# backup config files if the exits. Just check if ${OUD_BASE}/local/etc
# does exist
if [ -d ${ETC_BASE} ]; then
    DoMsg "INFO : Backup existing config files"
    SAVE_CONFIG="TRUE"
    for i in ${CONFIG_FILES} ${OUD_CORE_CONFIG}; do
        if [ -f ${ETC_BASE}/$i ]; then
            DoMsg "INFO : Backup $i to $i.save"
            cp ${ETC_BASE}/$i ${ETC_BASE}/$i.save
        fi
    done
    # backup core config files
    if [ "${ETC_BASE}" != "${ETC_CORE}" ]; then
        echo "INFO : Backup existing core config file"
        if [ -f ${ETC_CORE}/${OUD_CORE_CONFIG} ]; then
            DoMsg "INFO : Backup ${OUD_CORE_CONFIG} to ${OUD_CORE_CONFIG}"
            cp ${ETC_CORE}/${OUD_CORE_CONFIG} ${ETC_CORE}/${OUD_CORE_CONFIG}.save
        fi
    fi
fi

# start to process payload
UntarPayload

# restore customized config files
if [ "${SAVE_CONFIG}" = "TRUE" ]; then
    DoMsg "INFO : Restore cusomized config files"
    for i in ${CONFIG_FILES} ${OUD_CORE_CONFIG}; do
        if [ -f ${ETC_BASE}/$i.save ]; then
            if ! cmp ${ETC_BASE}/$i.save ${ETC_BASE}/$i >/dev/null 2>&1 ; then
                DoMsg "INFO : Restore $i.save to $i"
                cp ${ETC_BASE}/$i ${ETC_BASE}/$i.new
                cp ${ETC_BASE}/$i.save ${ETC_BASE}/$i
                rm ${ETC_BASE}/$i.save
            else
                rm ${ETC_BASE}/$i.save
            fi
        fi
    done
    # restore core config file
    if [ "${ETC_BASE}" != "${ETC_CORE}" ]; then
        echo "INFO : Restore core config file"
        if [ -f ${ETC_CORE}/${OUD_CORE_CONFIG}.save ]; then
            if ! cmp ${ETC_CORE}/${OUD_CORE_CONFIG}.save ${ETC_CORE}/${OUD_CORE_CONFIG} >/dev/null 2>&1 ; then
                DoMsg "INFO : Restore ${OUD_CORE_CONFIG}.save to ${OUD_CORE_CONFIG}"
                cp ${ETC_CORE}/${OUD_CORE_CONFIG}.save ${ETC_CORE}/${OUD_CORE_CONFIG}
            else
                rm ${ETC_CORE}/${OUD_CORE_CONFIG}.save
            fi
        fi
    fi
fi

# remove new / empty core file
if [ -f "${ETC_CORE}/${OUD_CORE_CONFIG}.new" ]; then
    if [ $(grep -v '^#' -c ${ETC_CORE}/${OUD_CORE_CONFIG}.new ) -eq 0 ]; then
        rm "${ETC_CORE}/${OUD_CORE_CONFIG}.new"
    fi
fi

# remove new / empty oudtab file
if [ -f "${ETC_BASE}/oudtab.new" ]; then
    if [ $(grep -v '^#' -c ${ETC_BASE}/oudtab.new ) -eq 0 ]; then
        rm "${ETC_BASE}/oudtab.new"
    fi
fi

# move config files
if [ "${ETC_BASE}" != "${ETC_CORE}" ]; then
    for i in ${CONFIG_FILES}; do
        if [ ! -f "${ETC_BASE}/${i}" ]; then
            if [ -f "${ETC_CORE}/${i}" ] && [ ! -L "${ETC_CORE}/${i}" ]; then
                # take the file from the $ETC_CORE folder
                echo "INFO : move config file ${i} from \$ETC_CORE=${ETC_CORE} to \${ETC_BASE}=${ETC_BASE}"
                mv ${ETC_CORE}/${i} ${ETC_BASE}
            elif [ ! -f "${ETC_CORE}/${i}" ]; then
                echo "INFO : copy config file ${i} from template folder ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_TEMPLATES_NAME}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}"
                cp ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_TEMPLATES_NAME}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}/${i} ${ETC_BASE}
            fi
        fi
        # recreate softlinks for some config files
        if [ "${i}" == "oudenv.conf" ] || [ "${i}" == "oudtab" ]; then
            echo "INFO : re-create softlink for ${i} "
            ln -s -f ${ETC_BASE}/${i} ${ETC_CORE}/${i}
        fi
    done
fi
# Store install customization
DoMsg "INFO : Store customization in core config file ${ETC_CORE}/${OUD_CORE_CONFIG}"
for i in    OUD_ADMIN_BASE \
            OUD_BACKUP_BASE \
            OUD_INSTANCE_BASE \
            OUD_DATA \
            ORACLE_DATA \
            OUD_BASE \
            ORACLE_BASE \
            ORACLE_HOME \
            ORACLE_FMW_HOME \
            LOG_BASE \
            ETC_BASE \
            JAVA_HOME; do
    variable="INSTALL_${i}"
    if [ ! "${!variable}" == "" ]; then
        if [ $(grep -c "^$i" ${ETC_CORE}/${OUD_CORE_CONFIG}) -gt 0 ]; then
            DoMsg "INFO : update customization for $i (${!variable})"
            sed -i "s|^$i.*|$i=${!variable}|" ${ETC_CORE}/${OUD_CORE_CONFIG}
        else
            DoMsg "INFO : save customization for $i (${!variable})"
            echo "$i=${!variable}" >> ${ETC_CORE}/${OUD_CORE_CONFIG}
        fi
    fi
done

# change prompt if basenv is installed
if [ -n "${BE_HOME}" ]; then
    DoMsg "INFO : \${BE_HOME} is set, assume that oudbase and TVD-BasEnv are used together."
    if [ -f "$ETC_CORE/oudenv.conf" ]; then
        DoMsg "INFO : Update the \$PS1 variable in \$ETC_CORE/oudenv.conf"
        sed -i "s|^export PS1=.*|export PS1=\${BASENV_PS1}|" $ETC_CORE/oudenv.conf
    fi
    if [ -f "$ETC_BASE/oudenv.conf" ]; then
        DoMsg "INFO : Update the \$PS1 variable in \$ETC_BASE/oudenv.conf"
        sed -i "s|^export PS1=.*|export PS1=\${BASENV_PS1}|" $ETC_BASE/oudenv.conf
    fi
fi

# append to the profile....
if [ "${APPEND_PROFILE}" = "TRUE" ]; then
    if [ -f "$HOME/.bash_profile" ]; then
        PROFILE="$HOME/.bash_profile"
    elif [ -f "$HOME/.profile" ]; then
        PROFILE="$HOME/.profile"
    else
        CleanAndQuit 20 
    fi
    DoMsg "Append to profile ${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# Check OUD_BASE and load if necessary"                       >>"${PROFILE}"
    echo "if [ \"\${OUD_BASE}\" = \"\" ]; then"                         >>"${PROFILE}"
    echo "  if [ -f \"\${HOME}/.OUD_BASE\" ]; then"                     >>"${PROFILE}"
    echo "    . \"\${HOME}/.OUD_BASE\""                                 >>"${PROFILE}"
    echo "  else"                                                       >>"${PROFILE}"
    echo "    echo \"ERROR: Could not load \${HOME}/.OUD_BASE\""        >>"${PROFILE}"
    echo "  fi"                                                         >>"${PROFILE}"
    echo "fi"                                                           >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# define an oudenv alias"                                     >>"${PROFILE}"
    echo "alias oudenv='. \${OUD_BASE}/bin/oudenv.sh'"                  >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# source oud environment"                                     >>"${PROFILE}"
    echo "if [ -z \"\$PS1\" ]; then"                                    >>"${PROFILE}"
    echo "    . \${OUD_BASE}/bin/oudenv.sh SILENT"                      >>"${PROFILE}"
    echo "else"                                                         >>"${PROFILE}"
    echo "    . \${OUD_BASE}/bin/oudenv.sh"                             >>"${PROFILE}"
    echo "fi"                                                           >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg "# Check OUD_BASE and load if necessary"
    DoMsg "if [ \"\${OUD_BASE}\" = \"\" ]; then"
    DoMsg "  if [ -f \"\${HOME}/.OUD_BASE\" ]; then"
    DoMsg "    . \"\${HOME}/.OUD_BASE\""
    DoMsg "  else"
    DoMsg "    echo \"ERROR: Could not load \${HOME}/.OUD_BASE\""
    DoMsg "  fi"
    DoMsg "fi"
    DoMsg ""
    DoMsg "# define an oudenv alias"
    DoMsg "alias oudenv='. \${OUD_BASE}/bin/oudenv.sh'"
    DoMsg ""
    DoMsg "# source oud environment"
    DoMsg "if [ -z \"\$PS1\" ]; then"
    DoMsg "    . \${OUD_BASE}/bin/oudenv.sh SILENT"
    DoMsg "else"
    DoMsg "    . \${OUD_BASE}/bin/oudenv.sh"
    DoMsg "fi"
fi

touch $HOME/.OUD_BASE 2>/dev/null
if [ -w $HOME/.OUD_BASE ]; then
    DoMsg "INFO : update your .OUD_BASE file $HOME/.OUD_BASE"
    # Any script here will happen after the tar file extract.
    echo "# OUD Base Directory" >$HOME/.OUD_BASE
    echo "# from here the directories local," >>$HOME/.OUD_BASE
    echo "# instance and others are derived" >>$HOME/.OUD_BASE
    echo "OUD_BASE=${OUD_BASE}" >>$HOME/.OUD_BASE
else
    DoMsg "INFO : Could not update your .OUD_BASE file $HOME/.OUD_BASE"
    DoMsg "INFO : make sure to add the right OUD_BASE directory"
fi

CleanAndQuit 0

# NOTE: Don't place any newline characters after the last line below.
# - EOF Script ----------------------------------------------------------
