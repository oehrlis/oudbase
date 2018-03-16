#!/bin/bash
# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: oudbase_install.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: This script is used as base install script for the OUD Environment
# Notes......: --
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes/updates
# ---------------------------------------------------------------------------

# - Customization -----------------------------------------------------------
export LOG_BASE=${LOG_BASE-"/tmp"}
# - End of Customization ----------------------------------------------------

# - Default Values ----------------------------------------------------------
VERSION="v1.2.2"
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="TRUE"                                         # enable verbose mode
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"                  # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"                    # Full qualified script name

START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
OUD_CORE_CONFIG="oudenv_core.conf"
CONFIG_FILES="oudtab oud._DEFAULT_.conf"

# a few core default values.
DEFAULT_ORACLE_BASE="/u00/app/oracle"
SYSTEM_JAVA_PATH=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_OUD_DATA="/u01"
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_PRODUCT_BASE_NAME="product"
DEFAULT_ORACLE_HOME_NAME="oud12.2.1.3.0"
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.3.0"
# - End of Default Values ---------------------------------------------------

# - Functions ---------------------------------------------------------------

# ---------------------------------------------------------------------------
# Purpose....: Display Usage
# ---------------------------------------------------------------------------
function Usage()
{
    VERBOSE="TRUE"
    DoMsg "INFO : Usage, ${SCRIPT_NAME} [-hav] [-b <ORACLE_BASE>] "
    DoMsg "INFO :   [-i <OUD_INSTANCE_BASE>] [-B <OUD_BACKUP_BASE>]"
    DoMsg "INFO :   [-m <ORACLE_HOME>] [-f <ORACLE_FMW_HOME>] [-j <JAVA_HOME>]"
    DoMsg "INFO : "
    DoMsg "INFO :   -h                          Usage (this message)"
    DoMsg "INFO :   -v                          enable verbose mode"
    DoMsg "INFO :   -a                          append to  profile eg. .bash_profile or .profile"
    DoMsg "INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This "
    DoMsg "INFO :                               directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default /u01 if available otherwise \$ORACLE_BASE). "
    DoMsg "INFO :                               This directory has to be specified to distinct persistant data from software "
    DoMsg "INFO :                               eg. in a docker containers"
    DoMsg "INFO :   -A <OUD_ADMIN_BASE>         Base directory for OUD admin (default \$OUD_DATA/admin)"
    DoMsg "INFO :   -B <OUD_BACKUP_BASE>        Base directory for OUD backups (default \$OUD_DATA/backup)"
    DoMsg "INFO :   -i <OUD_INSTANCE_BASE>      Base directory for OUD instances (default \$OUD_DATA/instances)"
    DoMsg "INFO :   -m <ORACLE_HOME>            Oracle home directory for OUD binaries (default \$ORACLE_BASE/products)"
    DoMsg "INFO :   -f <ORACLE_FMW_HOME>        Oracle Fusion Middleware home directory. (default \$ORACLE_BASE/products)"
    DoMsg "INFO :   -j <JAVA_HOME>              JAVA_HOME directory. (default search for java in \$ORACLE_BASE/products)"
    DoMsg "INFO : "
    DoMsg "INFO : Logfile : ${LOGFILE}"

    if [ ${1} -gt 0 ]; then
        CleanAndQuit ${1} ${2}
    else
        VERBOSE="FALSE"
        CleanAndQuit 0
    fi
}

# ---------------------------------------------------------------------------
# Purpose....: Display Message with time stamp
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Purpose....: Clean up before exit
# ---------------------------------------------------------------------------
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
        40) DoMsg "ERR  : Exit Code ${1}. This is not an Install package. Missing TAR section.";;
        41) DoMsg "ERR  : Exit Code ${1}. Error creating directory ${2}.";;
        42) DoMsg "ERR  : Exit Code ${1}. ORACEL_BASE directory not available";;
        43) DoMsg "ERR  : Exit Code ${1}. OUD_BASE directory not available";;
        44) DoMsg "ERR  : Exit Code ${1}. OUD_DATA directory not available";;
        11) DoMsg "ERR  : Exit Code ${1}. Could not touch file ${2}";;
        99) DoMsg "INFO : Just wanna say hallo.";;
        ?)  DoMsg "ERR  : Exit Code ${1}. Unknown Error.";;
    esac
    exit ${1}
}
# - EOF Functions -----------------------------------------------------------

# - Initialization ----------------------------------------------------------
tty >/dev/null 2>&1
pTTY=$?

# Define Logfile but first reset LOG_BASE if directory does not exists
if [ ! -d ${LOG_BASE} ]; then
    export LOG_BASE="/tmp"
fi

LOGFILE="${LOG_BASE}/$(basename ${SCRIPT_NAME} .sh).log"
touch ${LOGFILE} 2>/dev/null
if [ $? -eq 0 ] && [ -w "${LOGFILE}" ]; then
    DOAPPEND="TRUE"
else
    CleanAndQuit 11 ${LOGFILE} # Define a clean exit
fi

# searches for the line number where finish the script and start the tar.gz
SKIP=$(awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0)

# count the lines of our file name
LINES=$(wc -l <$SCRIPT_FQN)

# - Main --------------------------------------------------------------------
DoMsg "${START_HEADER}"
if [ $# -lt 1 ]; then
    Usage 1
fi

# Exit if there are less lines than the skip line marker (__TARFILE_FOLLOWS__)
if [ ${LINES} -lt $SKIP ]; then
    CleanAndQuit 40
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvab:o:d:i:m:A:B:E:f:j: arg; do
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

DoMsg "INFO : Define default values"
# define default values for a couple of directories and set the real 
# directories based on the cli or default values

# define ORACLE_BASE basically this should not be used since -b is a mandatory parameter
export ORACLE_BASE=${INSTALL_ORACLE_BASE:-"${DEFAULT_ORACLE_BASE}"}

# define OUD_BASE
DEFAULT_OUD_BASE="${ORACLE_BASE}"
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

# define OUD_DATA
DEFAULT_OUD_DATA=$(if [ -d "${DEFAULT_OUD_DATA}" ]; then echo ${DEFAULT_OUD_DATA}; else echo "${ORACLE_BASE}"; fi)
export OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}

# define OUD_INSTANCE_BASE
DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/${DEFAULT_OUD_INSTANCE_BASE_NAME}"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

# define OUD_BACKUP_BASE
DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/${DEFAULT_OUD_BACKUP_BASE_NAME}"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

# define ORACLE_HOME
DEFAULT_ORACLE_HOME=$(find ${ORACLE_BASE} ! -readable -prune -o -name oud-setup -print |sed 's/\/oud\/oud-setup$//'|head -n 1)
DEFAULT_ORACLE_HOME=${DEFAULT_ORACLE_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_HOME_NAME}"}
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

# define ORACLE_FMW_HOME
DEFAULT_ORACLE_FMW_HOME=$(find ${ORACLE_BASE} ! -readable -prune -o -name oudsm-wlst.jar -print|sed -r 's/(\/[^\/]+){3}\/oudsm-wlst.jar//g'|head -n 1)
DEFAULT_ORACLE_FMW_HOME=${DEFAULT_ORACLE_FMW_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_FMW_HOME_NAME}"}
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

# define JAVA_HOME
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA_PATH} ! -readable -prune -o -type f -name java -print |head -1) 2>/dev/null| sed "s:/bin/java::")
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

# define OUD_BACKUP_BASE
DEFAULT_OUD_ADMIN_BASE="${OUD_DATA}/${DEFAULT_OUD_ADMIN_BASE_NAME}"
export OUD_ADMIN_BASE=${INSTALL_OUD_ADMIN_BASE:-"${DEFAULT_OUD_ADMIN_BASE}"}

# define ORACLE_PRODUCT
if [ "${INSTALL_ORACLE_HOME}" == "" ]; then
    ORACLE_PRODUCT=$(dirname ${ORACLE_HOME})
else
    ORACLE_PRODUCT
fi

# set the core etc directory
export ETC_CORE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/etc" 

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/log"
    export ETC_BASE="${ETC_CORE}"
else
    export LOG_BASE="${OUD_DATA}/log"
    export ETC_BASE="${OUD_DATA}/etc"
fi

# Print some information on the defined variables
DoMsg "INFO : Using the following variable for installation"
DoMsg "INFO : ORACLE_BASE          = $ORACLE_BASE"
DoMsg "INFO : OUD_BASE             = $OUD_BASE"
DoMsg "INFO : LOG_BASE             = $LOG_BASE"
DoMsg "INFO : ETC_CORE             = $ETC_CORE"
DoMsg "INFO : ETC_BASE             = $ETC_BASE"
DoMsg "INFO : OUD_DATA             = $OUD_DATA"
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
            ${ORACLE_PRODUCT}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

# backup config files if the exits. Just check if ${OUD_BASE}/local/etc
# does exist
if [ -d ${ETC_BASE} ]; then
    DoMsg "INFO : Backup existing config files"
    SAVE_CONFIG="TRUE"
    for i in ${CONFIG_FILES}; do
        if [ -f ${ETC_BASE}/$i ]; then
            DoMsg "INFO : Backup $i to $i.save"
            cp ${ETC_BASE}/$i ${ETC_BASE}/$i.save
        fi
    done
fi

DoMsg "INFO : Extracting file into ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}

# restore customized config files
if [ "${SAVE_CONFIG}" = "TRUE" ]; then
    DoMsg "INFO : Restore cusomized config files"
    for i in ${CONFIG_FILES}; do
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
fi

# Store install customization
DoMsg "INFO : Store customization in core config file ${ETC_CORE}/${OUD_CORE_CONFIG}"
for i in    OUD_ADMIN_BASE \
            OUD_BACKUP_BASE \
            OUD_INSTANCE_BASE \
            OUD_DATA \
            OUD_BASE \
            ORACLE_BASE \
            ORACLE_HOME \
            ORACLE_FMW_HOME \
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

# append to the profile....
if [ "${APPEND_PROFILE}" = "TRUE" ]; then
    if [ -f "${HOME}/.bash_profile" ]; then
        PROFILE="${HOME}/.bash_profile"
    else
        CleanAndQuit 20
    fi
    DoMsg "Append to profile ${PROFILE}"
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
    echo "alias oud='. \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'"  >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# source oud environment"                                     >>"${PROFILE}"
    echo ". \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"  >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg "# Check OUD_BASE and load if necessary"
    DoMsg "if [ \"\${OUD_BASE}\" = \"\" ]; then"
    DoMsg "  if [ -f \"\${HOME}/.OUD_BASE\" ]; then"
    DoMsg "    . \"\${HOME}/.OUD_BASE\""
    DoMsg "  else'"
    DoMsg "    echo \"ERROR: Could not load \${HOME}/.OUD_BASE\""
    DoMsg "  fi"
    DoMsg "fi"
    DoMsg ""
    DoMsg "# define an oudenv alias"
    DoMsg "alias oud='. \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'"
    DoMsg ""
    DoMsg "# source oud environment"
    DoMsg ". ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"
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
# - EOF Script --------------------------------------------------------------
__TARFILE_FOLLOWS__
� �ȫZ ��zǕ(��駨@tDhp!)�v(K��$&�II�c9Lhmݘn�#s��������(�Q���u�[w�$�v2�d,�Zu[��k�Y������־y�Pѿ_�k�_�Q��7n|������Vk������z��'�?�|f0�<���f����e����38�t�?��Mgy+~�1�����<xP8����N�}���~�����?���|�Q���h+;�M�r�`O��"�ǹ�<o���<N�<W��E4J'�(��?���d�fS��t��}���<ʢ8�fa�Gj�O�����|N�g������/��?�l&�[��~8�Z����_vf�a�ɗ��h&� f�X��Q^W9}�J����z�zw����^����0LΣ��+���pj�v���(���8MJM���p�M�<bHOg�q/�'S5M�y�#'���)^�
s�E�Y�zi?H�Q�gs2�s��6�dt�fy�W�4SQrgiB�
�3LgSu�j�	C�W4�+������$�l�ϡ��w��;�#���w�^��%<?�m�o��ۭ�^ڏq��Q��<��
6�wS���̮hQ��(=����~�Sl	���Q��٤���d�j�`:���C~
��ݻ��ۧG'����W�;m6k�A�s���4;�]��I_��[�G@���FS�*͢�����?�]��6Z�`��sx���~\;9z٭���\�Ft���I�xzp�}\{��=�xQvWn��������~g��xe1>��V���������Qw�����ǵ�t<�ч�vva���^��߽��R�O:G'�/���������*��[y�~�V_E���{���:��ʽZ�����lou������4Ⴖzà{ttp�x-p��ӏ��=�%=ĬO�w�Wp �R/��<Z���EZ��Qx�nytD'������v����������7���Csx��f���+��8���}����;+�����O��!\��4�?��~�D��
�ip�:Ef1f��~Qս���Uu���["�Y4�="Ns 8�?}/}7U/y�gQ��^��j�9�*��)|�&�ђ9�Kǂ?���]�o7='�����s���.����k�<��5��#��I���5�¤���c��ڭ�߸����^ݮ@���)�|���3�ʫ�ǈ�4j�I�O>�U�]_��i�;��/O�S��y�
	�d��m�@�ͮ�2$��,����=�װ��d�j�� 0�P% 9�$��P��̙��U�+u���=<�;Ƃb����W�7�7��~�b�ͯ�k�G���GG�&K:w��1��_qTo�Z�mp����*~t�({�Ԉ�!_��c%b@�2�Z\XԖ��Slo�h����~������hzz�j1����5ƃ���r���f����Ks���2;�KWW���༦�J˫�IT�M�xlO�T��7��Փ���}�lH��P(RE�M�ldp�zS�.�~�h��d��$�#96����"uN[��]r��4�
ͻ�L�R�n�נ"��p������|�*s�R�p�f�֐�����)��;��M�Ѐ�*���M�?\
ߕJHl I?I�t�9�3�#O:O�u�v�F�9}�9.ll��Q���GS�}^���Go=��� o��Q� L�Yo����� 3Jþz�����G��'邻�t��)p�.k�XX�w�?Xڿ�e�C8�>I~�����t��,IP~Q/��������#�;P���`�Y�6I/�7b��j��׀;���Z��&~��8�Ix+�	�.�K��uDK����زQ$�$��R����y����Gw��9&���xC��h�ݣE+��.to�_mh�W�׼�/=9�? <��J�Tn��'C.\��S��c�e�O�e�$��A���Q��?/%�/EiFs$�&6�&�����t��P"T�Z��V���ȍ'�~t�Nf��ir�@�����j���P��=����܅�v)��6���t�0n[3�;;FVB�������؄ؼ����8}��1�^w�Y ,\TTU��@���� Ș0�fE�QVU����)��FS�@e��a`3}���~����j�_��F]_��p�]���� h)
��^8j�����a�Ĩc@��(���A���@
�j
��F}���#���V��p�%�?��/�'����t�j���[|�����we����{$(�x��Ƹ+�������O�p�j�����6B�`�[4�'�P��v�߹�3R�H�	�(���&�²,޶�h�N i���,�ˇ�[����$� �h�c=Nz��E�����fw3C�٨s��'�b0���s�a��~�|��ޕ�Ȉ���5�=Ƽ���.9��O��kj��6�������V�<#�Yu�>VVC��^�Z��/�-��ׇ�D�
[P��r�(ݻB�Mh�Xh�z��=�;��� ��b��0Ґ�'!c�#KǊa
��7��Io���`Z��/��x��\}�=9!�s�����f>��m0��ӓ��,,������v`���,� 1�r��e�r�3)b���\�l�u�Y���_;�����������eۮ-;��0�r��2S�	��2J�E�[>ȣY��0��1�x����n6�-�dq}�$i�x2���te�8�q���]��>,�?vר*����VO|��;��q�e�5�\���KW��u��pdа�
��v�ρm�}���!C���6��f��������U��?��A�����G�l�b<M�	��1���> 4�i�n���J������&i����c �sZ:�ߤ���4Z"2��h��]�u�8�.@�D�=.���9��0���[j&~��ͣ��_�AU��Qm�I�ZQf, EOS��U���J�h�d�{��j��v��s�z��c:Vv�}�f��==@'�jx�V�}�}������q�M�|z�3���h����K`{������!:������:�~��F�������.�t�͓�z\]��wyI�y]�=R��?zO�}�c����z�YXq[��Wڶov��\��+��Y�0� *�H9]=�kGE��S��N�1C�	C��K�|n�c2��YD����c��TU��2R2Ю�������wy�\6��qr>[�\��\�-m��W��O8�e�,`iw�D�Qa���k�wi��H��Z��H�k}O�Q�o�'�h2������F�E��˱Q�E>�oT�<����{�����_�>�a��f���:L�)ZBꛄ��?��vUdɖc0G7Uь
pea��,q�9�Ϭ=�2���@z+��(͔:��h��Nf$%���e�b几�6�e.�H���ʻJJ��b,4�aQi.�������k���_ߨ���x�%�������+������/��!�_�u���K���x迺�H~�[��8���L���	��ݨ{����c�+"�>!��}�D5��;�\ᣛ��J�����s�r(ڀ���sz��gz��H��cn�m��ӝ�m'8�B�A�6\�l���V�����������Q�ԃ�>KFz������w��DE�s򂆰S#�����D� �7�5�}*���� h]�	�-���T����%@}����ϛ�	�/�?7�	�z�$e�7a�� ��:E	���&����
��y��`�A��%j��<r���YJ��	9�DU}�?�pp����F�|�$P^w����%��8ǆ:_W�v���Oѭ����'Q���1��r�%�ai��Y�{;�����· h��"}�����'l��,Ba�zm�{���2P�^_�~��Өƾ<��㙉M�Y�\ٲKH�K��W��́e@�)�鰦RQ��\ƣӱ���9-���w꬝���R��Q�;/��S��� f4y��^�Ts��sC��^�dT+��+ҧI��P^�-�jrt4��vC��U�S���\�5}1Hp���d����ɱ�z�I��#�F�v�_~�Z��$c��­Ϗ��'���F ���~s	n-� ΋�Ǒ�T�$��i��6Ѭd6>�?(�d$�'6�#5B��T��m�y`((�L��xމ����߄;�J'Q��:��NӺ����f�٥���/�<'d{�ʪ�Yu۟�t���4�oT����rؖ3P��pN��� �=��db�4�^`�U6]"�(k%#���p��Ⰰ/q?*�z��l������LZ���ϥ����DA���		�9vz��5���Ҏ\�X0�;��{�%���U�:,�~�� P��9?ՙ���I����8i7Nww���0e�Pw�v�2�LH�� 1��������<�	�ݛ��ρ��X�}�0���t���0����%��bb<��<K�J���:�= ��ք��D{02�u�M��*���gѺ��~�޾[w�)����r��)Ah��!�:�|�G��Zz0�)�����"{f��6�*����ג�D��4�pB��m�9}|M��$��G���x�tZ��s%ȟw�t�R���5�?�`S~��m�d���_�Bڊ�S�
�T��`��&��m���V����y�#����*�6���D^�ث�E|��WW�[wԞ^�L�df�Qn	�?��R�?�$����q��xXoD��M�<�F֗�kt�g��x�m>E5����\��Єm^E�.M�A��)���Vg�?C���ʿ�6��z��k3�&e�1�T����u�N@M��7�|y8_*��Ǫ���&�{Շ+�b���z��r���c� �?�3� �����;���h��ٮ�B�4i��՜�R�"QB��[��X��\.o<��������vh����M�]�����I8(PZ/.�D;>u))i��t<;��s�����q���0�՜���<iF>���b��j�zS��Y�Ɛ�gGi:u����T@��?��y6
���?�x�^�������.̺�3Nz�Y?z��������������oj����sۢ�}����)t�a��<�tv��Ԯo
���E�p���m��u�D"�����6�j��p��M�l�(_��Q�̍�O����Vc;�� *^��{AN-����J����W���B�閂��mR�,�����I�-Փ�����zTt�3��2�e�"0���
�(��<~���$%�ιJ�=$��L�*ET�%9�WH_ݛ^q�+�ZU6��xx�����q�'(�e�WɩP��A���F�^�Q�q��\��O�a:^��F�[��Y������Sc2Sn����F��W0�$·Qn�JuD��v��2i�P����Ό'͸�ad1�iIS�sie��9l���j�����/?����XQ�U�6��xX���x�����_��K�ׯ��e.ܿJ������}�����R���\>ڦa/wwo�
^�>��LN����n����#��9( ��:���Hd�F�$��=AE�q��Կ�`�l�]ԳQx�%��:�m��C\�J}3�Z���;/�,��8N�EK����Qw���ٵP��y`ߪ�^w�=�p��t��JG}Kk@?����껧����<�Q�[qZ:�A|�y�m�}y��K���%��K�ۗ�7��_r޾�}�y����%��K�ۗ��/9o_r޾�}�y�<9o����%��ݦ�o7����`��9�ݦuŞ��|��uE���o�\9�ncK�/��*�q8���I<�M@�����-������Jm�����/Ya_���u�L��d�In���<&-q)x$	��� �%�(��#t�::R�ר�w�q6�ѭ6��vD)��~��)z��+�K��v���+�m��PA`��������|<�)
���K}��ꈱ��}8Ģ�v
��C�.����O"��;��r`�l{��Kl�@vgH��%��������	�H��:�q遲�	�%��%�m^�u:S⛕M�m���s1����\X7I{s��<�����KioK�R��V}iڛ ���2m+3ݜ><ӭ,wڻ�w(����M���P`�[���v��ԉ���9/KsH��,���#��ȕ�p(��d�U	`�<�:rK��p�W�[q�Y�����zw��b�r�1U�4��ϯrOB}�m�� >� K��W�i�	��=@�<�G�bp�n��o<Bkz���[���l�3de�Zq+���Wo�~�W��׿������7ߩ�-sl��0�$�=��:;�8��
����[��眘��	�B>��s��IO+����}z�����iz7Kѓ���������WlB����+�eg6M1�B3R��������K�5
��8�j6TP�>�p��L`�.If��XZa����gc�̪�U����&�Sw	�t(��F��˓.��:���e�m�2)����ɵ_,e��'�?S������|�`���w���_��~��/��N�_���?6�Q1��f��i�K�o;PR��F�
�#�>.
�s)02�]p6U�4/� ��a�ێ�-������yU��:��u���emtd��P�?~qz|��h���ڏ׵zM=R��>�{�+\�<ͦ�A�b�دQ�S�i��%����g����|�6׳!'����F�&�K0~+ϡ'�����x�t� �vo�~�7�o��Vg�mEUy�y
 e��58���ɭ�ion+TL���s[�t�w;'�ci;��
��=��_n����di֛:P�'��F�d0�\<j���x�>�{��1�B��d�y�������F�ZP��{l���_�\��$������EJg��~��ğ���f�	���Q�9=�c���ז�؍�Z�1� ��~D5<	mЇ���R�AM�Mebv�X�i���D�'$�|ު�3�cz@����]˃��L����qic3��1S��~�50���a�%xl�
�m�G��?����As�Yz&0��!����� ��a����=v)�"�, ���cߺ�x����}B������ ��a�=�Hܪ�T��R��t���%r�ͪ@'������?��A=����Ϋ�������^���H9
�[����>&���DỢ���SW�M�"���;�^���NNN�G�������))F�Q�Hb��wQoF�h�4I�¸�U��삿�hc +i!�kN
FVʮ춣��9U%������ˢ�,KԺ03Gs�Pu����|)����y΃�̪gv���4�Ck�]i���"�*� ��[)��]������S)��Q��I�����}����k'���x��F^�% ��ND�#��F��r��T�`/���r|1�#.F4q�H�j�:H��ҍ��]:^�%$��Փ��8�% �Tx�a�ٵ?��%�y����`r�J�ǵ��C۩� }/�	��ll�K'��������b㑂#�Raf�Y8f� ��N�n�Ρ�BB����}��)z��m�*N�L7{:�aN���MN�Ft7�3�6@u�������)o��xNW�P����-����P��{\��&`�α��������Kc���k�s��|on�LP�ͼL���tb���J��V%v��i�xȡ��dz兩"h�r�0E�1QŋF�������*���V ��0��ahRE]�VC�kU4O }J�ٲ���!�O�$w0C,��q�ܱn�}��c�������h��8�+�U�]L(�7���
.+1�V0p�Ud1��qn�}8�},��6�~i)��#�]�1̧�I�>�P�X���⪡TQ[���N��=�� �x��{�*�<�V�3��
;:sP����	�n���N�W-�b2��X��~4D�;����V�e���Np;����v��	�rH4�����'L��K�+7Q.�D�����U��3Y��9:�5Pҷ^u�� �r�+=ٛ�v��͚���o�c����g���g��T���бh�����Mf)3������C��LO6��xt{t�
���Qk��%ӚfVЫ���2RDRG�3��,썢S��V�l6���F-rR�̞?�]Fo)2�>�6K!��^�tWW�.�K=������K��3�5K����!�ox'�2�����C$�ʙ
��epjz췕���ǻ��� W7'cD��Q4���n��Q����/��]aW[t�osJG�R�T0&d��v���4$���4�''�����lz\��.G�&���"����~|�9��٦�1���m��9���q���s�y�b)����l�i���V�sov�Y���g�O�W>��;��m.H���y�tش�wv��B�]E֢��"�j�;e�=ph�������]N鹾>���A~�7MC�LB���87&D�Y�cP�2�����J��f\����p�'Y�L��W͇���������~}���QU,�HL����o:��՟�89=�Rmh��q-�"���	���T��gҎ�k���fΉ�WE�v.�V ��l�z'B�>Q�
D����#��,Ǽy�xe���N@E��g����-���g�?�U���Rt-�<�.��EQI�b�1}�����8k�Vu_�DL��~w6����������� ���r����|N���uWS�[[��(��λ�QOڡ����x��U�JB���X62���8u����|����w�����+�>?jfTW���N��K���<0N���\�Ml�B�L<���ϱ�� �5�a��X-% t$�bh��Q����*P�ttE�U�S9������YZ���\I9��fP��Q�fk��ի�tg|�?�����>�9Ȇ3��a��0��-۫��*��i<�1i&�n�,d֠��G�&	��F�o+��]=�(��fop�DoS����-�3��g�ȥ1e����h�Ay#�!���F�2 2k���re�4�R7G�_�:#ޜ^���/s�&�����=�b�X0R+/��P~��i/T�����Q�@�} ?��괗��f����n�h5l�����%�y�����Ƀ����h`�+�e���r�W�PY2�ں��J��Ӿh��c�uz��%�����_��r�ک�J�����;�>˴�_\(�W�T&dsM[��^��xZ�Z��e���!��Z�б�{��[�7�n:�ipks�ߖ����8#c��W�u%*�~�4�'O�͹L�?�ؘ�����cesb�|��-����Qr>�Ai}�:�}��;j�/&�,j`�
aYz#�a���������6�>ȃ��]��p�s~�G~�6���*UK���r��ly���1���4�Y�����ē��u��W���Z�O5�S%�ʘ��ϊ�ŉZ�m�8�;9>U9���G@Ĝ�ֽ ����`��G04|�~\�N�#�H�o��H����F�
/��@Mt��[��v�e�V!����m4�`���>-Qق������Q�%�yH��L�����%��������:?����OoN�����Bsϫ�4�>��>6�ß����^����?/4w�W�����=t�X����y��-����7]Gr8�������w�.���*�;]t:%M��_�ҐC���cqU4e�^nʟWu �_?�j"Des��k�R��kg����;� ���J�l�X�35�y.-� HE}���f�Aض��k�$k\���ϕ.Ԫ+������sJ���A09��Lh[�� �� ��v�Ognoz�Ӌ! ��L��%Ȫ�j�Ab6'?��;c>�� r�ヰQE��!/*WM��T��tֹEDV0�R�F!�*u����4�E�,����N�|v��a�� e�*6�u\:��Q�@��N BQ[��TA����t�Ԟ"�aL������ޭ���\���Q8���V1��ҹ0V� ���WJ��W�o6�w+����6��p����B�x�k^������j����!{bb��>����������oT�e��ш�~G9Wa�y�ot���+����}>���πr`d�\_ 4����:᷍ϰHU�^�O�f�|��D`���\K�gU�� O�{���ܲ��he�O�#��7��to6�B�[��V:��!��+���j�����(�A8x\�9�;�u�Y��e�Uk���B�X���>�j�I�J{8HL���S�]�At`���\(�VCS�Yԟ���ɳ��9rf��E�!V���A3��ސ;���`���els�V4t�����P+��պ���VkAx�m�`%�&gO�q�5�y�k��ﰁ����ig)l�*��پ��n���L�mz �b�P�6�pe���Qأh�!}��5V�¯�4i:M�ų4�����b������)���ɏF_r��C�-r>�s>&ϟ9Ö7��nc7���л2�B�����G���8� ��>#��⶟ͻ�'��g޴�􆉲�}�x �fQ�E�T���ٹ$2�d�[7Vs�Y]z�����������M�A�9��к������}�.��CuX�N����{I�B,�xs�tz� �vI�[�-`"��lq����7��`a��<�Ǆ�-��;�9����`�"ȅ����lQ0p�}�y��/ķfz-HM���4����ʪk+~�Pu4��ȫ����4��:/~�c���*=�ϴ]��w��e{�!�5��CUU�����|��Bͬy�<��Ƭ����L�+,������M'4~��ߴ�K��HF��~�[�Y�uUq������i�=��[0�Y�
�F�}�Br`CۊQs�����>B���z�<���WmB1s��u:Y�KC&����o�n��W�������QQ3����m�
DS*SI�J�:��ʗ��&���xO�;�jJK�U,�w�Nm^��������:��7��r��VQ����[�(x�&@~�g�4��o�}͟
�|��@/2�O�nS���?jgn�&�>zg~�s_V�WvC�~1BT�Va�!:Z����p�<����8��״����u����n}·7�r�ۯ���X9���Zy�ҖT�,�
�V�U�S��i��ia�k�MƝK���̦ k٤��M�R4{�C<�|:lB�<87偍�'P0
�<� ��--�s*U�������S�@��s�J����Y����/FF�������6�����J��Pvɺ1�v�����W����Ձ�w<�f�n��s��Ӵ3��ݴ'7��k�d*;�-_y�5���B��k\3������Ǡ�$x�w����S^�g~����ڟy�%��{Y��׃�6����ï7~�~���������ww������6=��`����=x�~�p�������_�GU�<���w��G�]u��)��)E4��+	x��PR�%�ڀ��&WY|>��խ:}��eQ������S?�W )�T��R�IŦA>h��y�I��Qv�aq��1��)��號\�����������ࡰ7���t	=G����!�o(h��y6���p4J/�~+��\�9̢p�:��v��2G�pv���n�^5hƣ�jP�w�o�\o.�*ի�qҧ0D���-=����0|ݴ�w��X�;S�~���X�ߺ�Ԑ�2���G�f\��9Ԑ8l�7��RO��܇�M�t��d%}>��Y���wT1(��
?I��,�y���ij�Z=�F�R8���; A��,H0�ה-@��L��ly�Š3��p.�d2�Q�J�.��̧�ۇAK	�����gW4Ð���9~��0އ �w�vK֟�Ҕ0�5���Y�I������4�+\_�o�QH0'�=�'N��$�1)V ����X����  �Z@a-��
97�/`i~jU���E�c�����a�a����C�D����^�)k�.-u.C�՝:]����fx莧s���H����i��C��[���p��J8��C�~��u�!PtnD�r:�$�=�d�I#f���+<#\��8�0+_��$�7�D�[��.�I�x��%�E�4�`9�Y��g�(����6�<%w�8|<@���D��2<�~��v���v����.OF w��Yoho<lݐc�α, ��n5�d�cLmB�5Hy�P&��4���(�y�%����#@�7��5t��A=�-�� ��b&�]�Q�o�*�)^�L�[�ф�I�0EԠ	QbB{�[�^z7�L��I����>q�M��0����1{u�{$��	�\��<��x7�΁8�͉��m�'��DQ̩si���l�`�wW/��/-��:���D}$�>�,b��3C^rE�@���K�>�c�O�f������8�d���h�e@g E��jG���S�i�D�A��d��VNeo��J�t����3�Lݑ�������ozT��K���9~(�z�~d�$(/�p��C�'܂K��]��!5��l �\�,J��De���f#�D�	��@��M9�� $���|��$>QA�����
P���	 2ܛĒ�3�i�7��gG��ƛI�6�h��p��z!1�{6<A
�G0�K�+~zY�,�]�L�4��ˈٝ=���!�(Ed>��Kc��k
�KO�E��2�Da���348`�n�e�%�N�~ߧ�*��Cq�g��Y"�)	�,+��O� G`���
�ȫ4�brS �,T���_CE(�k���9��	dFZʈd����ߍ(�G�I�����m�M5)!C���a`e?N�Fq�9��}S��,�Ҥ�P�~J����i���:��H�qc=!�h�X�7����"hS���<�m�\��W-�X����LS�@��P�
=�L�a� =4��\�� H.|�$.,^�A�z\k�r�C�%eI�yOc�.t�=�;V��m,4��s�s����Z�\'<"���8<���)���E��=�+�3 �U�X��y��-��p)t�Ej�׭�lBZ �q��4C� P����w�m�;m��͘d�&Y_t4�N9�8���0�4aͰ߇#��y�����I�(�ёԬPS��]!6�4��r�H�#�֘%�������� P��	];��R��O�	?j�CN�A��$�JV8h�S%f'$��� �X*J�Q�66���9gp�N��&V�9(�Z�"i�~�iGB�v[�ftT��,h���d+�X&�+1c�a;�	z r�|m6owxNA�}��������B8m���w�.�a�T��0�<B�� ��u��S��4(K��S�Z�3�� d��6�*�<���H*#��(���}Bgv(�DD �?�34t$���*-��W�]�
� �yhP��`B��T@<z��^��HE��B~z��\��h42'{t��)�y���6D	��t��/j�JT������G2C�r��C_DƇ�T�u��i�ZPj
�k>��/C�MN��k#�M�8@���@4:�/xT�$��(r�@t"��Xݕ�y�$� ��ĮQ�@� X�Q�P�0#��m�-��L�X�]Z,�%]��p!b�I��E�4�͉X��k	�f+<SRـa�$�1Z�38�]��_�$���~F��읐8��Ȳ�5a 7v�`e�w� ��Ң>E��"a���`b������P��<���5Q�]r�b�0��]:O�-���eec�L��질(8��wey�U=�{��j��Վ�4���H��L�c����0v�~�Dɐ�΁��\� T���֋��JJ�noʝ'�x����f��X�Ƹ#��f�9C�^��;@��c�8�"�ގ�&�*�E��gtL� �Y"Q�1w�l����}oo�V�J�Ƥ#]�g5����z��&$p0@�|���ކ�L��`��\��1�e	��	` j8�鎟�FC�ZLXED�%��4.^}@54���ʈCƓ�´����b�¼Ěq�b�
��	���Ka�wS������(��bF�:�oAK�FH�>&���րx
Ϩ��y=�����k���#G�2�������r	��L��VZ�=��[d�-�6 S�aj�a�W�	�GNb&!�l�hc�B��B5��B�g��k%2]��!4w0�ɦ��d��O�	�rB�c@��t$*����_����6��``}�4ػyP����E%s��,��p,"�{B�5�f��9B'�*�n&��S�[�����ٶ
�֪s�w	��q}
TC�r�>_W9M�R,���R��x�ؓ�ρʶ���*	��js�o�"ݞ���1uʴ6�/m�k�]#���)p)��Dn8��1�%Z�%u�Qa���3��i86Ǹsp�h�T61۫/Hվ����!#�kSn��A-�ly4�k���c{�<���W�H��>-�ve-L��thV#;������x�
��R��8�= �)������(�*.RVZ�,�x�֡~��.�Q�h�M�z|��kR=�L>KF�8F�[Ӗ��'�)(- ��@ㄘe�ꐤ���gW�v�|��P� �#�͉.�#�X<�ME����������G��@�������BI���E8b���-=��uB:`���<&�8n�h��z�r<(�ڢ/��k�Ϻf�_�m���>o�1v2K����|�z6"�O��Lp�^|:���ax���6�p�,�h��QA������+iPF���]=�dYG�j�#�d�+�@߀��D(.W̊�]�ne1�g�!x�Q
�t��#�`#�,76w��Cd��"���p%�΢a84�~�Gl���Ć�Si�E���i�1x���h�md��c�YFԷ��.	�Q�8�a<a=	W�̾�����{q֛�u5)/Rq%v���X%+G+�R�$.�)��Ń<B���52��(;̰�7Ȅh��	�o!�~����`���/�3ܞp��M��uW��~��R@�3�� ���G�I���0z�$���L@�ɍi��1
��W������|.�Cڣ2B���fA�w�1E�>��Z���kj�a|�������N9^T���QD����ɒ�m��z�r�����O+�|�F�b�g	�F �Y<�8��gJ��|�	I^W�y㙠�ؚ�bB!�쑐�x�ӠxE��c�7B���h�²��iŁ��T�Y��LG	RWR"����트$�4���O5c,�[{W6SVfv�thA�n��=h9������b��ˁ�t!\za��H��%�f:A�5l\�x6�&�I>������f,t� ȇ����%�l���Q@��pbh��L>\$1F�&~�=@�O.�Ϧ/�{أ�;,�	��:5��& ����ڋ�v\��#��9]Pߜ��j�J�5�h7��=8�)��$�#3���

�����ل��9jC��1!4��.��i�N$�W����u���$���Q4��;I��$�ms�V��(0"�>�U+n�H�4t����6�C�Ixe�2�lؕcd�DJ��'�Ů#� !�]`�V�o��G�E�v�o���	�.����me��7ZT��lG�6z�_�B�7!��\��,�W�1BZ�%�/3��c�s<�_/�}�hK�v(+��"��(ב��� P��T%0	h������`���Vy&�kh�A�vه(fEI�hC��<��#�;AY�����O&E
��$,(GQ_s�Rk�N�dx%>{k�a�L@��h;a�JpEj�>�N�\{i3�R���lI�c��]-�SD��N!m�2����F�K�*�$2�i	K�M����Q�gZ��A��C�8����FV�e(��y�s��G�$ �9E���P���Ԟ���'/��t���`bgd��Rm�aqc���'�:�@��]tM_�����Ҥ !~�#�(ธ����#B��6�3�[D��掗ڲ|�y�M�,���,��'8�%�w%<98��$����f����ˊ��R٪�����?�"k��F�\I�C��`}�VVЀw�vy�>+�N����᥾���`l8 ��r�(3n�ù��q��b�41�h^�E�0XQ�a|J"�X��8,uˌW0��` jp��ȡ7��I�0/�j��N�
�7H�O�$�v%�զ��K+���2��i��9er� �,�hm8 �
�Y����9d�������PD�Y�>������M�N朎�I��V�X��8B&�بa���wЇ!J���ºE�pwJ<��ˇ`��Ev[������5��ب�^m���=�$�� V#�zy�H�	;����K�>�g��ˈńU�l�ZE=X��(r�:=��I**������k���ID�s`e|���ZUNЕ����r��8�F%6��^��d��(��у����D�h���^=}���=�W�-δ�������\�3���:����g���#t*�c��<�,Z�Z+�s�\4*�\����	]�yp� ��3��:������I�x)7����lS�TL癈��A��4/�nc.*����?��1�!WA"�_e���w��֚s�u��x���#�@.����_V�QE�Y�@}kƸ�wS#P8��C�ʡ�(���2���-,��$�"�i�ys�7�n�l�q��4��&��j����؆a�o�#&��9���\nM4����.8���9M��/���?��g'l/`G`DA%�w�p�7� C=[ t>����a�1��Z�H�[#�ѵ2�U�5�.�F��љ �	�p��x`p��^R}��rx�w����Gv����H����x�Ð��h*����|6f%��hE�D:S��Uñ�"��Yw���H�����K�1p��S�~��Y��*�P{��˛��/�@�a�C�E'���(HD%�<�)���!��?o�����Φ��έ��&]�>��I��u��A��,{�X-'�
՞��y��Uӫ	Ɋ)G�ᣂ:�����<wR>����LnCapŋ�Rz��)40Fϒ�(z�F|�l�����)̈́��hbad���m/�\��N:H`�d��JӼU\2\���M� ~�I�"y H�@#�&��"	`�;��B��;��
�Q*�]��W̉ò�~�@��E}t4$L"���芷�	_lak��wR�Ȉ��BQE�Vٺ���	"
�R�	��Kt�7=�
�C�"�g�4NfH�
��֠�W��V��$&���(�"L�T����rm�E���� Ĝ3s�$�3�hI�T��XM�E���ح�F�$���@wwml�#�s��fƉ��0�C97Q"F�u�&����&��Hd���h'�U�h:��WF.X��P��J�?�ܾ����p�,���۷���)�,r�ހu}5�a
�LH�E�XzȦ�qalx�I�`G�ڔ��N!��ܻU�II�f���q
�3�f�15 ���;���&lɝ��G�[z9B/
 �-s�i�eG
G��#Bh~��c#��Cw�^���9%�WA���=��e@�Q(�N �~?"���0JJN($T�h`)�;���,�`(�VD�똩��r�#Jģ�ͤ��p�=�n3�Qua/K��$!�S��笥a2ȹ~���ÙI���DX��{��|��Q��B�����8'�+��5G �:W�8��nF81K�-B�w4PJ��hZ�[ߴ����˜DڠZs>�L�"7�q\�K�M�v�8+�8�Q�I�o�D���E��Y�[+����J|M:l�}b��Ab$P��$7�nb3'Ӹ��!ˋ�0���pb[_)�	�ڈӅ�s����Z㷕t�l�o ��֟h�����U��+���H��A)<���eW�`n@��Bcp���T���Wa}�0ڟN%E	�|Щ���[bu���i����Qz)Ӏ~��I�
�?.��ޭ�u6��%�3}�B�;�iL�Oʏ�#��.�@��ʸ;��mM�)E���<:��w�2:�X�q���)R��Ζ�9�FQu�-v}!��Ô�+��ؖ�$�&u�����Ei2�"�MJ�3kCM1�!W����]��#�1��Ȥ��ڒ]�eSx�3��L��Fy�LE]�6�0ӶŒ�����U�dy��=��G��v<��������7��{y<N�<N�rkqV�o3n�Ԩ���Zl�
��9;tIi{�c=4f�Hh�/٥��p8r��r&Ր�U��kN��_ؽO�.ܓ0:���(�c�7�-�l����\�1��An�����Y4lsV.E�������=N��:����>2���Ϳ�c<�:��rժβ-�D���sjXk��T`,l���H�at��:�r�	�䐡J�&���"��\�Tn��`*Wb+F��F��wH�jb�L((�7�v��h?�>"yk욹��}�]�Gs��C�Y�	�@T�%9Z͋yYY�g�*b	��Y>����P6)U�3�@� $ɂP��1ʜ���D�������EJ�S�ͧuj���y�Q5k��(�=��Ż���y�wm4]sK�^��z.�ҁ	�3ln2S�BF`�ĨPB\��_�N���z{�QA���	�F������oTCT�.�a�r�<i�kd<���(` ���א�����)(q��7���Lƈ�U89I�9 3�A�6�T��Z(�N�O'o��|3Z`*O��*.��Q���e5�D^-���x7z�H	�����T��-,h�
���#[�l�x����N/�P�CR�+EĩH�Y`jF���1U@E6"�/�\��e��A��Q��eU%�`��&��=6�6�2[%�> ͛�7^���,����4�\���XÐ��^S}�jS9	��0(��mJ��%!�hg�5���{�J�(w�,_K�O<f9ag��#[��07�5 z.��|Z�O�V��ӵI��8-T�����$��31�3O��{�>෥;�r�Y��J�1s���+9P�"��l��0�Bq5����|�4&Xd�3c�%�b���'�M��O����B���h�Q	��^�2J3�gj��o"� �#��@(/8���.�c']��.�%���'
�����$���Iz@7C�6�R�!�d�'�Y��vq�\�i��8Ӓ�`�&"�;�� 4��$p�xA�R�������o�~\�A8漐�I&6k�\pǹ���%g�U�_I�q����&�L@r�0,��{��$�%��|�D����0�����Dũ噓k�{U<��T��e��(I�mi�-�r*\���g� ���X�.Hu��E6��2c~e���e12�[c���Z�Py���K��G���xN��WnI.���~���T'G݂ʨ�P�e�(;g�q�}}�w]�A�q�:j+Q��I�;;��\�2p׊D�9b�|p�	���W��s�o��v�_ݥ��}ʢd399A� "�g��%Ί[�x���@|�p^��X̫��s�`�uΜP�	��SP��P�XR����*�͢o#�P�r�y�4C��,��#˧��y��WB�����X����W�H<e�B��[v.�y̫�t��M��03���&�R�� ��)"��&�����T��s����.�-��[/H�����i��F*����񘢛�����ql��d����ԡ.k�K�%luL���)��x��E�r*���v
�y�bmNJcc��}��6�M��!
2M���M�=�C⵴�p�m/?6�| ��N5ǟ� nؠ��7{"��� #eQ_�М��[�9q�A�KP�5)�A9dzPD2r���Ŋ���*#��L�R�N�OT � (�_��[16���5�҂l1��d:�قo6�B�W��(�C����.�&&��3����=���ig�a!�5L��z���XU�P�&���Tn���H8Q����e�Y�E�hw��|�m��J�@$��e���Y:�#���P�Xͮ��T��D"��� �Fb�b�{<e���ap@*�K�U�T䞈�[r����s��\���J����]DIȉ��X�L���­=Y粶5:�)�� 7�ta
dJ�u�U���Һ4j����*ʩ �b�5e�XOJS�,��������D�a��L�t*�q�:/��4%I���0�1� ��ä)� [R8IlM��8T�8ꄾ��9k�5���#��6P���xDX+�u
H�-:� HƶZ@S�ݱ�e����"7�H�0S[��F��d4"�
��ZD]��Xfēb��(�A� 
���
�����,�d,i�O��r+�'s����1�s��n)4-N�@ (�s'v�dFqt� �ut泐�Xl�e&�W&����>&ʹͩ�*Ȥ�a�L�Z�B4�FIu��u�V�!���(嵪���Li!�k�F`�V]��ՔJ�tR�%��O?�&lFe1�`q.�������SmJ���)nU��#YL,%ͮj�@f) ��t\�V�Dqdx�T|ɋ��ֹ-�e�-�d`�Bx��^l��:_i�JW�9�V�%��W�#c��i��N@���5��)A�6ݑ�d���9!68	���Z����U���4ھ*E�80_�J�F�;^6�f]�ܐjkxeJ��t�ۡ�JKrѧH�:i�*��xI3A�����s1������Ǐ��<�	�G�L�UC�+jޏ`�C�i�&�w���#�����5A-YLb��'��ў����38-|3M�c]Z�1��L*&�͌�O�i'T�d���S�M��:3�WW\S��C���Icvw=�z�R�j}��ŭ��3Fp�1�K/s�ӱ��
���Dї:ejU�T�nF�a؝�ȏv�u%Ql�Џ{&,_Q�r����`#����64�oˊ��l�&4>��S)o�S��x<MC�NG�*sy&]"Eg�����n�	{)��]�L�0��'ES�����d��>q�]�oW��=�P�z�@&�H<Ν�^@`��
����"�ձ-�l=�#��C�.��/1Gg�5?y̭f�~���V��w):�A������@@#PK�$o�"a���Bs#��	�O�|Vc�������غ�֫[|������T� �+���*PP��I�+�@���X벸��5�x�O�@�(�=���Ѻ���A�le_$~���_��Q'�~�o/�#�M��"��V)@�	4y`=�n��^��鞡;'�R�C�c�#�u�>��4���d�JԢ�z�r��� B��ǌ����ϙ��Q#��q�?�FO���J�b����[$3,,h"�\.1�Z4!�����*�UPث��u1	�Z=ͻ�T��R�GR��α��yrGnP�g��s�hL��Ro�7��8#��>�����棐�S��@��d�T���k����0����ߠ�A4���
."�=��� $p_��#軹S��/ߩj���pl����t�C��.٥��Y���L�h�4�ѹ����%���
�f-K tZ�B�Sq�Nв$ ��)��=l��pF���$�E���v����z�9:��|��������Qg��N����t�O�a�ho�䤻��~tww�:Ow�j��_N�ϭ��z�������:>�`��}��h�dg�9�:8��h��������v��^�j���Qv�Nv��8�W;�]wN��9�i��띓/O�䃃g �{�ם������u��a {gf܅/w��v_n�\�)@�?8Q�;�2hvr�p4i���d �^�h���y������j=�9ه!h�:<󭗻��������q��xl����_�@6�?^v �]������XΚ8&\����%�X�)�Q]��}��:�y�m`K���^W������]��݂�v��W�ݣW;[�G���������B9�g4������ᱫ���b�#u_!~���ŝ8���KX+b���w�ui��^�����b(F�u�/,b|(v���w���l��~���lQ��� 7�)Ld��3�]�s���u�w���1yd����[;�|���[�kţ����#DN>��%\D�}�806~�NvՎ]FJ�{p�lwN:�f�>�b��>lݱ����#�o�{�l�_���������9��%#�}���}yTD<� �A:'�-�� _�<���^ȱ)�*�^�Q<�B������2LrG�VGd��i��"�$����R��˼��31�p�!��7E>8�־�ǂ�(�b���%�Y��ҥ8D8@�0�d�K�����@
/Eg�rL�Qʙ�����H��i�����p2�(���ș{��đ�l ��d������-��)z��}��k��%����~שC[��\':��{dy� ��rǃ$���.pi_%����xHd���N��2�����S�a��{C���0P����:��!znM������~Y����n�I��U�b��N�2���	�!;tpi8c�{��D��D���{-��"f@�X3���~Qb�D �yP��u�7RjF����,f5II�c����3��ڮ��-ʦ�\��vR]��Y�ݜ҉�YG����8��[O�*���V���;�N�F �N�{���{�:l�;�M�޸w��T��r༡j��B)9�=�B~����ƔL6��ӏV�t�zY�iUo�]�y�j����C�8K�p�\��Q-�!�"�#�W�4�6~Zb�iWE�6w�६�u�&���څ�j�����Md�Y7�ԕsj�ٽdu�#"��p:�l�ۗ����d�J���h?�	u0t�n��&XD�i'ٿ��q�y�v�,M�j�N0r��2ʉ��J���5�44�ӏ����4�;JϸҢ(�N�n#;u�b�IY�N�}r�X�C.�L{�yz|�������<�3��T�+@пӋ�w[\�>[�A�<�8l���7A��l���%�;\�;�|�,�&hn$w�2����Lo�?�Z������c�T�`@��ql[����tX�B뵏��?�c��34��T&����]��Mʔ)�C-i��uz�b��� ����N1]�����������F+�լߔu�
+�͏gƧ�_~��yV�%4�@�js���m����Kʖ��Ƙ|8��-D�=�6��R�/r'W¡�!�e)�1#y��J���/�u���`�L�E<4ds�Q\ES1Cʛ9\۳�]�X�K	/���u�
n�.��e�{%��
o�ԡ���t,��<��0Q:��ڗë&lsst>����N�w��?���>�v����q�3�������
��������?6~��Z���p��?�Pk���~�;������̐��T�4Z�����(��?��u�r~��|칏"m�V'����}7��?���G�R�$S(�pIB�ymԏ�HRM��"1��4HH�a�����P;1-��l#�=�*�uF�`&�e�/��'�C�u�'\r���͆�����0�#���әv���p������+E>°1�yz�y2���i
�.X�?[L��;���w�]�C��B�Ы)�
����z�}f��x���:[j�|�ee�zR�|:��-NL)P/��#�t#g���i��'��~��L�1��Kg}�T+޻'��Яy'��|&����IV�fIo�f�k����q]��7��͒q��9���4
*���"�����z]��t����NK`�W��!�DA%��|*�q2{�^�������Y����[���0q0�Q�O�"|1�0Ʀ|n�i��_��]���Y4�i|W�����}-����ҝ;��Lg��qٸ�N@�!��6�h�˒٭Sx����kkard�,2��K��]��f�8|^0ѿ���8� ���w ���m��{���я�=[[o���`�96�ֿi��7�?���v��
}G'���0&*����V��֥��<h;���& bh-g����qX��.��2�����9���{��;�k��=}�9�>�Q-���Glz��Ê��L��c�݋�=�����m�{�/��-�EsXi��Z�Z%�k�R�yT_�b>8yW�C�*~ˠ�ԅ�|��5�i�=dqDt��*^�X�[0ԲKȄ��}�C��͗�֒�+,ע�9Y�G��{+��zk�}] UC�k�z��u�/��!<��	{h�>�
@�=Rv0 \��
9���L���T�T8_����w�;���Y�d�4�c��tܯ6}Q�-��^.�,콝M�1����<�O=Jt��٬�|���WQ�%�f_�t�q��"<��c���x
�����T��xR�q���dx�3%D�)�
r�X�=Fz������K?[Яyv�&�y/1#,�9���ް���ս�!羧V�8Ʊ�2~����мi/I�P }��+�Ut���J-U%MD��&Ld��G�?�g��+%��"H�K�	��͵���ק�k�l�=�0yd���Z�ɭ������ۘ]H/���G�(_��e�â����I�r�ͅ�\Vm~�`1�!ݟ�{�|��6^�E}�'[�[GK�o��ؼؼ�,�k�x���~�p�4d)�O�Y�������f|:<:�~�u2w�u���B���(T{0�\�hm��[�[k7�l��6 ���S�/γ�O���]o}�Z;]�zc!�㭣�Ó�g��_Ƽ�4t!H�kH�au����9ۭ�B3��s����C52��nwu�eW��W�|���oSu�ܣ�7# K�{�������4�b�M:vN�3�R��Z9F�߬#Z�p<���������ݓSR��� �塚'eT��H�j���M�A���F�+�?�ޡ���������y�t;@�$�)��6�Z��WB xߦ�p��q�.���ߧ�,��1�����A�(>kp+���T쯣~<p���?{@`Z}��������.��<K1\�o�#L����9Bv�ך\́*���g|9�O��|ܒڵ��5���I�@ $��<�����Z�6�L�S�%��b�Q�B:�_:���7��Ǻ�{���^�E.��BR����0��w,�")�,JVS�8h���a ً	�=U��M���~SrQ� C��͇p�Y�h��%w��0꽵[B��8��:G����^7���Q��Q�Z��h�J.��n�R�U���F$����u�����=4�ʞ�8���J����[9�g�����ZK9Kh���D
?�=����7��ģ�5@v>t����C]�~�����sR|׆�8��|����ષT�����q�!a8'@�ԋ��q����i4���� }oM����;�V-�+��Z�/�V��ܢ܌��~�aj��yU��r�5P|�5	��o�ÚƋ��}m>��|��Y�"�fU�ó4:חܒe�u�����u'��iD>� xze���K�]��i�X��5P��Jcƣ:��Ѹ�T �kE�����ܞ�*�!v�pG��M�q6��˹�T���-�a{ �7K���0��f�Ɯ����5�wXϐ�y-N���C�jGa�N!�o�3!z7wM���<�{V6�V�7]$hm�m(�w�!|8���|e���1أ��@s"�g�{�.+,O+~&���ڎ��`[� 6�?���'�Вo�A4.|Qh��"��K�q�� ꩷bۅa���k���[٢��UX�|Z��\&=!4o{g*�2~�4'?����۝C��!.���xW�z_Yd�NH��	�D=��bW�@ᄩ��s6e3G/�fd�eé������	k�1Hi��_�oB���X��[j7���Jˀ�+��\M��"���ىE�0����NpV;W}�%�C�x����yW�+KgH_��Xq��	��L�_Y�?x&#x����6�F�:�����d10��i6�9���βiE�޴9�$�X�[��aW�Z�ڙ���O@B��x,CE�j��[��������¶co��2@�̸,�Z~`�fc9ZQXKO}��%	����f�pp���~L�g�s�TY	Gz6��Q"�+��	��D̩��J��̸@�;�C���p� ꣚��mX��*��Z���qC�u"7�J����8��E�[�+<�TȄ�'6]�b0I;t����]�95��)W�04pnw#Zfz%WѼ�Yo,�����ɩ�$H��؆gZr�]dY�L*":��ઑ<Cr�So0f�XZ)��c�S#�COhZ��������,i�q#g�?̹���ҙ���1{�����C0ƛM�m>-�9�L'�)Q��+}�ܻ��Έ8���vl��1�	��n|����xO��Q���򖝯�?�.6h�h;�p�y�uOi�|iP�d�A�] �7�_�����6�P��σ���t(�RT��>jPAݪ>�t+|�R��n�<#��@�Y����/|����M��6wYT� - ��	y�t�A0�}��~a�m���䳾6Z�y
�.��uWy�<(��|�DU�P���r�3Zh�r�������pO��Xm!|`ɹ�͠�Z��g�I?�l�uv�+�x�m��coe�~�b���?Z&$S��k���z��CF�����<5������4���9�@��U�t���G�~��������+�8>Z>8PrG�Mo62)-���b$������kkb�<��J%+H7��x�#����lLa6����3�Jd� 8��9>��Ƭ\�����-(�d��'������鳝�*��P?
nTU}A=t彖3����O.���;2����<���Iil��L_�"��FS3�8<k1 kS[�{�l^EK�r�h�[����S��9i����'%M�^uXuǛ�i����MaVp*�&6����kí��r�$P%��A�gi9�>b�B�~���.Ω��!}Ǜn�����WG�����`��}'�.�q�67�����[�9K�꬈E���X���=��6�J
d�X�_j�P�y�r1t�Q��;�����4�x�O����B�폪�UIu?��D.�aX�E4~G�G(T
�9�ժ}�A��"�@+�4�!�(˰ȱ�9w3����,`@���񻛁v�Й���~k}v�Bx5�cI�׃(j8&��������!Xrǂ��i5��y�y�>�/�t.D�.�D��ѝKA6�U �eJN֯�s��[X�J�C��A(��Y��'�������%���D��+i -�-,|���~��,�����o�R�1IΙ��ج��s#a� oU"�k�V�k�j(�;�L$7�ڿ�Pa`��(9���	2��ԇ�//���������{��>�GSԷv8��gz��S�Z:g���y:Կ>�tuo7jÍ�&���s��~�2��ObT�G�t��p�d��Y������"!����=��T��z��\��{yx;��>x��L�?�qr
�Tu��*`bG�lOu���V�f��J��84���,�~��40ϭ��O��ih?���`N!��j�qR�?�-�=e���ӎwL�*(���hC�&�^�k{�1I��M�G���;�Ll[X��!M��4A�C��<�Ҽ��E�1X# ���b.R��������WZD��`n�7�lҦ2	���|�b0Y�)�m@�w�;G�O�M"�Fz �A#_>@|F�9#���V�&����`9�66[-�Q��jKu8퐶���ș�v�,0"��
���a%A��C)b�lv�rBCw�A�a.D���/�֯�����<�~x����[_���rL�[�28�f��(�:�Fp��m�϶�@S�z��{ߺ�F�5z���w�8�!��v]\.�=�o�4�$�aH��^^uQS�q�!0��4�1ο����R]Tc�4ݥ����%mmI{K��xխT�!��Fz�<;�" ������P��������D�A�s��.Q��^1�E.Ңr��H����˻��҅Z��q��d�Zim�7���Y��pJ�=�ۗ8��~=d������HRSV"�?jKm��������T��#���|P�-�ܫ��.!�SV=����/�iH�B�d�c�`缟��ܧBw{&'��b���Ƃ���R����K��_GҔ&mYF�2,��4-Kw4����ݑ�f��N�1�_�F�~����ܔ:ZSW;zK��n9���F�l�f�TGnv�ډ��Fۖ��ԲۊD۪ft��JSBQ[T�M����N��Z��)rǲ�VG�tL�V,�ieA���n�MŐM]��G�4EmV[3�����4I5%��Țj�R[�d�#5�f���#��bZ�bIJ��Ͷl���R�E������i��-��m�R�ݦ��(�����YJS6h��蒥��d,�:m��j�	Mˈ_�c띖�C� 9F�
 ЊNꨆ�nw`f��C��%k�F�nH�-��uZZ��e-�ږ,ˊ�֠����چ.�0:��N�Ӥ*̵�� ٓ�VK�[N��h�fː;�l���)��H���t 1iX�&q��h�.=���X�䘖b�jSՐۆ��[�)�ujȒ�X��%Z�і�Vm[�$�mI6԰as�a�Z03rK��)��`p"�h�cS	�En��NG�`�5S�kmYnu��,5m�.�"��-Cq�ȹ#��-K�9 Yz�5��L�������#2UG�5K7���R�I�B`yH aÂ3Ȳ�vG֛�
h�:L�$kv�:R�p��'�n*��i���if��qR�mJZ[���C�zf}��Navpr,���8(��0�Vv6K��1��e�^����T:�$�[�
�6dG�,��L�;�D�F8����EE�m���m��6۶˵�ʚޒa=���얖G.3���AhU�L�iE�3����mRNǄ�'I�S����&ٔ�b�����D��	v3�(m�
��lZ-Koٴ�;�޴�6�� uC��7=�AOUK3Zp�j��2�	��,9���誦5;�g�SS��sR��Y*�^�i��f�`+����6����L��P�6��MEՕ������8�&��	�*L����J���*D<���0�m�C��lӔl`�`qP������H�c�%]�,����ܨ��[@B�%��i�p8 &�GFG6�ZXV� $�>���C���"YtW�#�Q�8�uݐq0�d�j�Ӻ5��&L8U���_U��x	NN�2LͶuر�����5-�vKZ���m��ٺh0t�{�6U�'���v�ȕ+l��m͠��u��f�m�Dު�v,K��f�TQXp/}"|�j8�X
l��g#�@����;�8�m���E�d� ז&;Tj+���XZ���O�;� ն�-�8��^Ҳ
djP��%˖e[���1 ��&��N�����w��w+* pn@6��)mKѝ�
l�m �"�0�Ԗͨ^�4H���l��>͎D5�i�l�!y�m�e�-F77w^�,\�8Q�P�Ӵ��?(/��`�����c����_��6��MM�2��vy�����/L8>c�諹I��i�ɋ=�K^�l�|��E��wx�&��7��9^��鿂:}��W�LߧD�l`��΂��Ά�Mҿ�t���W�iTH���͙e��-�$����u��m%/=�BW�W�7��B�,�޵GA\�ž��������d���/����1�-}��gS�-�!1����Vԓ�{p�F-
F��2��4H���`C5�;�B���_NW�' އ���5�.�}�S�c0�������Q��cO�q��X�4��w��*鯼����Z���]����$��:���{b�H� 8�VW��yfv�� �:8c�%1V�z$�R��n�.F�GދD���G0�=��o�"�)A���<��`#�ʹ3>H�(ж-<�-�x.�e�����`��|�n��-��9/u�K[��p�
�^�>5�[qhO���Lٜe��1�9�C&��P�P,mC@i�t�5�3>\�Z���е�zea���E�jh�f�O���c	�i$
>�EЂ��;�ƺ^ަG��<Lǃͻ6o�l�2m�}��D���P*�C���M�=)>g�w<�G����{�p�&��*���0�{}��?
�wO�)1s�� m����rS���ޔK����� ��0O
x�@ڥ֛Э`����;2��yn9 ^*E
p{��$BÉ#7��˺k�B�>.�S)D������-8�L�
�o�_8�?l�>���w���þ���4��������֋�ί�����e���k�R}M��t=n�$0{�Ͼ${f3Ä��iidf�ʀY��-_b�*�=-,+��V�II�L��鑑��� ��Th�l �g3$�-3��%�޿�-B�L��ݐ9bg�(��X���~#CR"���� ��v :�dL-*�N�5�,yC�� ��A%��mh�xߥ�Y�|��ru��`?k��S��x���
�sVx(tF�_��0C�����k� /���_��^\�đR�RՊ���L�U�6,��+������g�f���Q�k�������߆h:V� �.9���fU��%o���ww^4q���0�oww�o	�|Y'5�!�^���ڈ�1T�֪��+R�LGn ��Řa���w��o�\8���f�Z����E��������|$����%�3yS��_��L� �) ��%��I�(����h�4=��r�Q`9>�v�|�T#	�7����<��̞.2��&EO���|ʀ�}��Pv+ʟ�-/�7��4��*TE�ƥQK᎞/��R���KA�X*_B��i��0f�Љ�z�V��"	[��d��R�"�Ղ)l�[�1��q�;�I�r{�˔w��rZ�G6��ߍ폓NL}�E��q��N���(PX���h����_̋���W7'�07��t��d���o��Iq&7F�/�_�`ELQָ������t���޴g�/.���GM��[ǻ�m���1���q��Rf�=���̋�8��.��i������8b�f��Ƽ.Q�������H<�&��l�dfs���@�j�ͫ������t���<Z�4� ��(�r0{j�Yo#e��HK�5>;���G�ù1����#�P�#�j��Q�[��e>��#��q1J킡R*l�}�X�X�w�m,��Pe5k����V���#����{��R��C^�&�7�g��EWY�upy�p����^|��3B�s'8��3��q?�����Nx/��'[�n�ˬ�kc����f�?E�K�o-�9;`��6\C��<�n�:y���X��f����ُs�a���r�0�H����0�t,63ɒ�����`������l*ϗ��Hŋ�~we����@p�&�n��?�(XlX��6�E��Y���R���%�������5d~����bA�� xlimŲ�z$�ʊ��ߏ���{�f5@��c��U�)�t�ϖ�����H�=�õ�������?|�x�y�6�0���*�)��aڸ��kz���%��=@��S)����9^�V�Ƃ�Y����S+�ג����Q"�<�ǡh]�8q䄑C~����	fj�_���n�ד̊3BP'>WW������@��N�s�R9�:�����`���"v����";(��O�u�X5���ې�~W�*�j5�=!�Ƞ�ê�����/t�SV�k.���xd���TX���YNE>��$څ�PS�"ߛMy�/镅��\w�eJ���Ͼն����)M�<�בr���������[K���������kJ����")Z��������g�߳�^�?�˻߳;<�=@�SO��������-|�{v��g�||�}�1�����)�r<�.��x�\}��Y�=���y��=�=���z�V�����2���GDD������M����j�S�j�th�7~��p�)J�
v�1��n��ըJNO�t��
���X!�M�}�?~��.].��K��b�2x��5U&�6*���r�0�q9n����;z��>�*�MJ����+�s��iL������|����g ��j�E��hV1�Vu��h5*��z�* ���e��̢��\D%M �ocۘ2�,�t1�>0LG����L�L,����#-`�r®�n�EAb�t��GC���t�uX����\Ty�|q^��(���c���K�^m2��'B��ԛ`s�G<FKteo���+�?T��[�{�����[R���"C���_G*�����sV��~����#�n���kJ��c��<) :����7�GO���uJl�E�� 
Ę90�3���gY���t����C��e�X�`��C�@#8&�%��P)������Z}�c�0�5��SX��$��a����� �hB�.�tZ;Ie*P3_&P�b���Q(�j � t�#6`�����#��]��K:
����\2�1��k{�M��^~��!�vN�}�/`���#�gj��6,t��E�ބ�G��w������>�x�g`��ǰ�v��hp0ҩ﹙o�����drl�f9C&�l��K>S7��j���f���%������d����˿�/f#�:����w|�X��?v.��?���qzvy��ᕽ�����{Ύ����^��t������Ñ�5[������ϻ���?<�XnW�I?�W8���-e�j̲b��GH�5�i�~ ��	+;�ym�yg��ԛOk��(�����?���/��u�3��Z���<a���N-�{��.}�q����~��\φ��k8Ь�`4D1�����av�Y4SOt�����{���ɻ���������/����駟�k�gW�|�����}?��㿶>���_~���d�w�ۗoϾ�GW���?O����[��>��}��ʑķ�YB�~��7�t�9k~�v!l
')�٭/� �Q3�=-.�g���}c��)����K���O���L)2:� ]�K��a��t����?/.�~�k��k��<Bcxe�Wb x�|���z�ȹ��}>����B����`n(������O^�ET���M�H28;Y\��t�Y3�u&,��ۻ,&��C1�s�5�0ύ����O�?ȕ�-ޫ��?��H��_M*��֒B�O��{ ƭ���;}T�Ԟ�U���`86���)8� �<sn��|H�}���әk�<{����c�o<�@ntKd̜���9���s ��]�n��o��W��bq[�׫{�2f��{c�����:��;Ęμ锞dH5�Fx'x�$;F5}��������K���:�8bb�l7�6�gD��	�UH�1���@FL�Z3 ч�%�
6���4a�偳�G�X-���'%r��8��U�$�EUsE�q�W��v��Y.Y�+u�$/�����ö���W�B��Y��s v/�2�w��B?��b���B*���y��q݊�?���H�l���C/$�����$IX�Y�������K ����9��u���>�s�nոHh���5�8UP5��kcS�{��c��s~YP���N�Tpa7���.m��0���z��[�R09X*���L���-b����RD�U\�ݟ��G�K���3?�0��l>��D�����p=��ѯd��
��c���qT��{LSF��r���sU��VE����4Yj',�nl�m,���[�����R)�W䛳����Jb���?���5����ybQ�{m����
���ƨP3 �:6�$�̉P1�Γ��$��3��kqt��ׇ	�|d�� ��+2�����CAd�dH��!�L���H�t��ZBN�-W��GT�F�dlT�I
k����c5!��cY�$ц�޳
��{;�c5�&F�.��gG�}_�X=;����^��uD�RQnR.�y�\�˵�y�-�YeϞ:�L�{���A�7��hSO
4���y�\P�B��Pw�� ��i��	-�Z�h����� ����jN/��NM8.�?�!�~9�&.R�����=8ݒ�����_Q՜�/�,��u������O_��Ad7�}B�?��K�D�i]�9�S��$�Pw)�����.�L�r�e�-R��W|APjڡ��p���&g�Yi���:Ry����/^]O��. �Uv��<�a[����$H�3悌]��~>�o���p��OL�3u����3��:�ƹ��K8M��C��H��n��-���{Ew��e8�5���n{յ�/ׇm��/�
�}�f�	D@J��?,!�"��k<���)t�]�D=O�r������g��+���]w�q��B8�?��r�.ݖ�����?��MA�%�����Y��m��\���H�_ѳ��dU���_G*�>�)����~��B����-�9bw��o~���b��q����.�<c��޳iF
\^�'p�|.�Z����Z����`F.�"��;�s8�7mWXB��e�[j�R�@(&�tXn
�ZXFMzu��­UĂG��yX��Y��VB\%,E�K"��L�s�#+��/�/x��m|��~9ǟ��O?�þ$�T-xҗ�o� ���_Z)��Z) -�P�1N���fS*�&���rs��	}�%��ߝ��Z}�5�y�X�J������>�A�ot}-�������)�D����S4�	�ߡ~0r��E��ԇL�bc�Q��X�֨]1p
3��N#D@C��tx�=^�Dy!��t+�k��+zV�_�J��������������^�����%u��J������/�W����������41�R���R������G;_�XV�*��x�b�����~Kl��a�{/^wI6�h̦����oP��l�T�j?�k�֩B��mR�$��R�ÚK�W	0��/���>H%CJ��o����#���~�&���Y�d�_SËR(��>;*yǖ8F:����td��w५��k�%Y���6�����7auE��G���Ж3�m����v�",�u�,�ɉ˖����gN�`�!Yn98܏RD-��+��'��b�1E��w���9ն�б�_]-Z��bή�r�0H�1GgISs\����]���6�H��W�0OO���k��0�K+6�y�sy��q*��J������O($���'W�hc������L�?]�J�ﵤU�i��=י>�V��/��c3\�1��w2�_�k|�v�FJ��J]jf�^�\� �aš���Ȏwn���}�����F<_��,�5\D�*6�����,��V=,[�������-഑9��$U��>����" <-o��h�$������s�W"��U��6���^f���pT�$��*�����M���+I}��N"x`�Kj���j�q��խ�e�j�R�L�C���2��_�����AƷ���s�q��\�9�q�O��-�<!��-�3�p��<�/)�+�)���@����q�m<��<�%�>ƨ𰙺��)��'�Z���j!�����MS�ŕ�gQ�k��v���X:~�������J����f�ϖ^��H����?篫R��d]W��R����*�e�?����{��d[uؿR��A�?�ߓ�g4٥�g����Ly�O�-UdW���&�Y�o��,��גJ�o]�ߜu���F�Z���UKtGa{"������B���B_)�=]a�`�p)��K�
�3L��1p/�/��|)]��ؗ(�,%���LD���-d�9`2Oˈ�7�J	��ۚ����}dA� ��y���_�NژLZVrˊn	:~������w)�t+�?TE�G�|�W]/��֒J��G������- ������N��IL_Sw��F/�9˻X�9�J��LE�L5s7�dt��8笣W�O�̚O4��Ab�d�F~n��ߜ!��t���pL�DU�4��g�	,��x*W�V�=��,x�O
@`����"-M�뙟�;��f�S�b�M��e�IP�3�����p��R>��- ���Ek[t���P|�'蟲��sc*���33�kPaL�(>.�����L���([-��_S�� ��\�����Ê3p}�~�W>j�z�N�V��`�k0q��Nc�G��&��0�Q����!�
�OU����M�.˪���r�YoKڧ*��xyA��~�n�%�bEu�2�?v� Y�xG�#�8�H�
��T�E��%�6��'��B/оVS6��&�f�Cw�����l ���$�=*i�h(F�J�(����J��?o�e��{I����y�O�����T����OO_LGx�Q���W�yw\MOO�{g���{��!��o�i�9�y�ƓxL�:��=�#����	�g���Բg�� vs�t
H���l˴��`_&�W���Dc#�����ڽr�Kq;�1�p�{�w9d���Gn%j�k�v�,n���b�P�b'� h��6v�޹FN$���]zx�L���Tߒ\޽#-����{�A�Rb�@�S�
@������Z#cܭ���8��8_]c<95��Mwv4cu�ͨ������A��3��?& �x���bt��,�N��O��"�s!�	��1bB�t��;Nk��ҧ��'�!*QX?&��L�'������{{�E���j5bl��~�&�:	��̛5;\]�/���|���t�<b�j��f��P,{k(֐vu]o�zc���d.ԑT��2u2-צ��38�@��M��H0û��:�OR�NAr�3A��VIQw���'>��Q��0��ӛ�Ok�A��;�Ǻi/�{�=��_�CH$���&tئ_BΩV�c���1~��䘂�5�F \����#5�?3�h�36.����Yq&��z��F��pO�0��k�p��'�px�Gf�Es<6�:49�|]]Ǜ��������Ga6ʛ�'������^���`n
V��"�/J6���R���-i��� =�;��[ X^O��g?�+HJ��J�H����p�^�#��gXY������,���
�{d�%q�������&d��1t=?Y��t]�{�����&W�6���(��/?�bK�����>�x��>]9�����>��I�U�"gtGY���4��8w��w/`��Oa���% �(~[y��h�>��Z�f8��s�m�f�gs�������ϑ����?A��������"k�OYӵ2��ZR����_�������ohł�`�ل�ʩ�.����$�����}�Q��G�$�������2���?.������jIZy��#��y���~���<��I���M`բ?K���j��SW���_GZ�FTy@O�P�������[��<����6l�=���s������y'�j��\���!�l<&�[ ���nLg.j�D���z��]�`  �������>s~!00�)�����>������75�N��)��Etq �w�+�$��F�5eZ3��J�T6��榶ٺ%���o��}��������(_���R�#�����u����hz�c�Y�>Գ�6���d�?�z������%�e�~�������8k�%9���G�L�g�H�C�y�:uI��,�%ץ,�u��!ޣ�߅�Yа�$F��+�ǹ�#�h8�*F�#���J�1�>�k�hoH�c���$l�w2�4-�4�"/YO_�ɖ�� �F�$é�+Lv�Ca��L� �| �QP�<O�f�h��c�],�����l�X�����̟6�#�3��F������k4P8=*ˠ�g�p�65� h*�}+vX}Q3}��*97ܙ1���*-�M����\���l��O~��P�������^ȉU>n��\\zӳ:wnP�r:�f��/��k��jB{�6	ZA3
t\Qy�+����`��;@/�=T��B-F��oFr���1��Q./�M
�"s��$?�So���S%�͸�1�f�d� aV�ny��A����ө7�~�1�[ʯS(i��g�`��%B�<�I~��������:���7!-��������[R���#=�[<g��*w������%`j�=�A� m�@�*f�N�R�/������O³�3�Ɨ�qx<:��k~����
:[��c6>�|t}gw��kXt��ʛ�wE�͸wN��x��aA��1zHw�A�O���&� �O\�z���
�>`u�������1�5��RR�_����iR�8L��b��y|J�D�%�� ������qa�ƬA�e4���K�1$̵���`��|�n��㽃� ��R���D>#�NX������]��B<"-�
^��DDڌ���Xj�$�aL&��7�y�#LÄq�P�Plg�x+%r�H�،��6Ӻ~-v���(t-�l?�Qg�;�p��?�F���w��a��0O�9.�Fb�|d�cziL��ͻ��;�f�5���և-��)x����)�XV4z�O�͍�hupAٶ5�͐���5������!���XX#;�#�f	��l(pv�l3�q����ɶ��������tq����ͮ>�'+lc�/�9�OMo��֒~�}�v��#�O`��y��Xؓ��O嗷��w�����w�O����¾��|�����o<��C�~�s����G��p�H�_���҂���t9o�S���%=��_�t���i_ l����|[�`���1UJ�d��1��d'���oB	~���
ߎl&a�����r�a�y�q/�K��t���}��/�!�׻���\�q$�:�}0�3���(�}���i��O��O��K&�دd#*i٧=���T_�/F/Ç��I
�aa��q���R�ަ���m*rde$񄸈%�=-,+����II�L��鑑��`����k��H>��xȎ��8�!q���n�	d,�}���m�g���,�#����_,|��F��D �?2��s ��y ���PK�ğ�k�-�d�E�: ć�Jp/�-ܖ�L3�)�h�f��꺷�~��! ���� )w�gK�.���]:Ew?��_����^��k�۫�	��bԫ։�Z��Pg,�D|1�Vlϥ^	w������F\�4*$,���}��;BU�Z��K`�R�p9�KAn���|)ȅRq��iѠ2����׌Pں�4_�Iy�VR(c3�|6̹h�MPoG1ֆ��Ɛ�$�L����^�E������$�T�oÖ���ro��a�c�;��B��~�I�X,�7��=cxq�b0f�}���i���"h�8,{Ƌo�3:���D��2	�ěH��� ��u��I7C�s&�N��N�Y^�>��� ��(�r0�g�:�����۸��7��0cT���	'�YL�lt欷q�t�j�N\�T���~������B�>�r���|@����v���A_���sczu��a�
n�7�?��E����<�GQ���4&�6Ɓ�_q0)G�7gcUw̙�����֊�cZt���������4r�	���y/�Z��!,PA�j0��]�C�c��L�M��_L�X�5�"�9�E�UU-��:Ry������Z�c^�.��^��^^���|���ǻ>#�9	(�	8�x�@V���	��?����[�c�le�M���a���E�_SQs�?���[Kz�X~����k��tSG/�]��~���:$��b�*d���f��\ǹZ�{$\�D�Z�+X�ht��7�������%�]d���;�൛�Ygtڕ�v�+�u�����	p�����Sn��;�o�N����]���i��R�o-���y���*{����bA�� zlimŲ�z$�ʊ��ߏ�����Yw��s��xe.`���r���Z���%��_���#���{�����%]�xiG6Y0�)ZY����^6cx�����N_���a��SW�\�ܢ�{x��;:��������"0����x�������� 6E�UقC���g�L����@n)�j�#L��9���aj6������[�g��u�I��H��}�JS��@T}u�eٻ���1��� ��:f���E�?������2��zR�H��v��&���E�NxI#��ys��v��*u��K�Ϋ�nņI��LP0DJ߄?��b[]gV<�3̖5�?��CÍ|����1�!Zn����flJ���Ꙗ��� q�i��zp�υ�?/��7�2��Le*S��T�2��Le*S��T�2��Le*S��T�2��Le*S��T�2��Le*S��h��y/� � 