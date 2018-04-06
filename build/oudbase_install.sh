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
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - Customization -------------------------------------------------------
export LOG_BASE=${LOG_BASE-"/tmp"}
# - End of Customization ------------------------------------------------

# - Default Values ------------------------------------------------------
VERSION="v1.3.6"
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="TRUE"                                  # enable verbose mode
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"     # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"       # Full qualified script name

START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
OUD_CORE_CONFIG="oudenv_core.conf"
CONFIG_FILES="oudtab oud._DEFAULT_.conf"

# a few core default values.
DEFAULT_ORACLE_BASE="/u00/app/oracle"
SYSTEM_JAVA_PATH=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_OUD_DATA="/u01"
DEFAULT_OUD_BASE_NAME="oudbase"
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_PRODUCT_BASE_NAME="product"
DEFAULT_ORACLE_HOME_NAME="oud12.2.1.3.0"
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.3.0"
# - End of Default Values -----------------------------------------------

# - Functions -----------------------------------------------------------

# -----------------------------------------------------------------------
# Purpose....: Display Usage
# -----------------------------------------------------------------------
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
# - EOF Functions -------------------------------------------------------

# - Initialization ------------------------------------------------------
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

# - Main ----------------------------------------------------------------
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
DEFAULT_OUD_BASE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/${DEFAULT_OUD_BASE_NAME}"
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
export ETC_CORE="${OUD_BASE}/etc" 

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE="${OUD_BASE}/log"
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
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${OUD_BASE}

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
    echo "alias oud='. \${OUD_BASE}/bin/oudenv.sh'"                     >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# source oud environment"                                     >>"${PROFILE}"
    echo ". \${OUD_BASE}/bin/oudenv.sh"                                 >>"${PROFILE}"
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
    DoMsg "alias oud='. \${OUD_BASE}/bin/oudenv.sh'"
    DoMsg ""
    DoMsg "# source oud environment"
    DoMsg ". ${OUD_BASE}/bin/oudenv.sh"
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
__TARFILE_FOLLOWS__
� 'O�Z ��ZY�(Zo<�.�l#��SNg�r�*�F8���@
A��u��l�wܗ�'�k�SDH���6]�i�k����i������֞?}���g�����W~��㍧���Ϟ��u������/�0����0���i��4|/�0����������	lo:�[���c��o<{����:����1���Ǐ��־�ZJ?������ۈ�a~<P����ю��"Ĺ�|�P�fy�Dy����h�N�Q2U��z��$ͦj��v�}zateQ�O�0�#��ǆ������(�NO���YC�.��_�l&�{_�~8�Z�����_vf��4�/{�h&� :�F�ZM���r����g�> ���zw�7|�N�k�h�=n���9�.�<N���x8�&iq�Wpt�����TMSu�?瑊Xxҏ�_��ʢ�,Q�t�>�i������r~�q2�R�<�a��(���4�#П���:�a�	S�W��!̆��O��|��>���S�{��#�L��w�~��-|��|�Z���;Li/��8��gE
V@`h*�2��m���g��q�!���q8Ŗ��y��E��.���������<�]G�>�:x�}rtpp|���r���f��2=���J���5M�M*~�jPy6����,�︑���Qo�`�e�b�����lt���/k�Go�5��� jx:��$c�%�L"�0�^�e�ug�w��.��.�ܙ�������~g��re�8Z�V���������Qw���觗��t<�ч�wvaڕ�^��߽��Rzǝ��7��v��e��B"���)�|tf�V�?D!��G��u�y�Q-����v������K�q��f!\�V�<��\��a�����ڃ袝�F#��S�?O�
�����7�6p�����z=K��{w���.�P֣���Y�ZW�w;�'������h������v���������ɓ6��s��"S�X}�g�g���jn�o������_��C �i6x7�;�K�$J5ϫ.M�y�r�cN��jN���{�<�'
�E�Q�'�5g g��Gc�b��'/��,���M6g�JȽ�O�D>"z3�w�T�>Q;£���gD�6�w�GBr����>\�Vͳ�ZS��@��z�[�(L:��?f�Ԩ��Ǎk�:���
T�����χqp�+���Q{�TLʦ񘤗��K�n��j=�H���?|���7������~@��G
��
.Ar�N#�g�0�IP�P� @T� Hr�
U��GBl��ϜE�P5 ��;{����C���U�_����͸����7���m~ӫ�_�p���,�Lz�aރ?׈g8]k5��#��kЪ�ѝ�<�[̯�C̽���Jd��%�M���-́<�Y�^���4ѱ:�������aL3�J���<N�_��x�i�8��a���A�Mq۝�e>\���.�k�촼�A�De�t����wU{�;�~�"o���ˆ<�L e U$��@�&@��0E��=�B�]��$PR��d�4_��T8kI�v�Ժ�()4���H-4tK�:�
��,!!=��f�#�-ՃK5#V�d��f(g�"��)6n:�X�"+��t��K�w� �@�O�)h�l����ΫkS�G��ݮ�fN^uz����J�h�<���އ�E�PZ�����l�t6��t�?g-���Ì�p�ޭ||s ��n�E��=^��^
\��j�6��O���f@�3 ���t7ܝN7�%	�-b��q���m�a�A��Ψ8��ɲ�g��$�L����ӫ	�_�tB `5�7�-�����<'��,����&�[�4�.��7�-I"��o d�H �$�i�R����y���Gw��9&���xS����Ѣee	h���6��+�j�������v%y*�Z�ɐw�?��^Щ�4˧�2L�P�m���Q��[J0�
�Ҋ�H�Ml��?�%���(��D�0�2]�8���!{�i� ��Jg}��Y��a�Ci��W�3wt4Y�y��=�𤫦q�:�Q�A�1��_ �ǃןo�a��NO�p�y6T�Q�� ��L��@ႢZ�]Z���X��?ƀ!6+�&��Z��bO!�X7�0�j���\��|�{��v�ͺ���\���O h)g����A+?/��?ơDCG R0ZK�WMSC�o��s��9��=,d���N�7J��_���R������90'��cݝ����$�0� cl�l4�����~ۧY8Q5oCO�jh}�N m� ��	���}�쓑��@M�%a�P5�K�x�΢i:4��O���i�#F�I�L�Bǚ��V����毛���d���
 ��*�y]L�kѿ�4	绸���\F�<8�|��ml��9-~�-\#✶Y]uww�:��)��[���z�ӛ�P+�\FEڣ����F�hZ�+-�r�+N,�
��B�w��!6���� ��b��`�s��T���,+S��i_�3z0{�J[�6�MQ���b9��rL��a�ȍ]�|z#`0�����)lծ���0��ë��]����r.#8�\I�s�R ����f���~�t����~��|<�q[�vmY�����\��O�QBX-���A�-hM/���kE��u�ɾ��0�#��+�$I�@�Ɠ)�~���(��Q�+��vvc�����ݣ��84�f �v�Z}�5�1\�w��+.���h^�2�׽.Z��I���(��ۡ?�����သ]*(H�X=��Yi7�ݫ"�M�o�
���f��x6��tc`�7T���d�Φч)*0+��/������/��\�i�������?��*�y�G#�?ꁨ̽(� ���W<��3��ae}���L����[G]ӿ�Y�:ୣ���ⵢ�X@���6}�.������d.���۝C�O�3���c:V1����Q�:?��� D���{��U�����G���wI�貯��ڋ����^�{���uėO�����j��3dpNmd+�ѻo�L�}�Va��+���.o	>��8k/�5��>�6E�����f��u�V�V8���v�c�(�	rEs;Kf@��f��e����z��StL�Fp�2�����yV�.���v������RFJFؕ��m:�{;�.o��f��8Nn�g���ܳ��c��-:�Jv�'�d�̜,���5*L�ɹVx�6k/�U�I��������{��f�^}O�nT^��]��J�(�Q���O4Z,T��	������a �f�������&!+�N��])����U4�2���l�8��e֙g\��7�^��ʉ�9�������dFy��(��,R�}�sy,k��Q� =yR�()D~0���|�����۾���A�����kϟ?+��?���[�|��������s#�1��%
<*���� ���'
�W������c������t����_Ƚ�������+B�W>#����N5��[ࣛ�س�f�N�7�/�y(���c���]ڞ��#%摹ݷշ�v����|
���0��2?[0�W���������J�����Y2ӻ�Y�7�P}��OT�;�oh
�42��ș �f -������y�^2 ��u������M����5@}� ������	���p@���<~B4rě��
I�C:A���M��'��"'�~�A�Q%j��<rܧ-�'YJ��	��U��?�0��I��0�|r$���9��Q�*Q��56�)(�:�:����~�w�T>���X���ׄ���KSN����$��}x�t=4���+�'�)�yr�?�"��?��'O�����A�Y<��A�˳86���$�І����.a�Xr~��z��r���ΐk*���e<1�q�Pk��bZ-q|7����}�^�1^5��q�z
3�ЌV���˾j�Էn�q�kv��jeuuE�4���%���)�=��p�O�����V���Q�kq���KֿL�����AKr�o��0��������e8M�D��������$�_���W�ů�1�^�>΁U�&i�L�L��>%��)�A!&#�,���<R#�h@�ϣp m�y`�#�L��|�)|�8�l�=ZŒ��z�W�e���x3��R�p����	�CC�쿲��R������F��j�տX���r��a8=���>2�@{RmL,�Ɣ��^KD_�P�w�&N�r��\�9̖��^��dY��\
[5NTC�x*��ܑc�7n[��0O+mą���Ӻ�[B�y�J��e�Џ�C�>
�9g�:�aA�;�zY���!A�dw��aLY.�ÿ<x�L�9 "@L�e�ꫵ�O0!ؽ����q^�̊�.��;f�۝��u�&��^�D�]�F�������di��U醰��C_�7�ښ���h�Ƿ�k�[�����*Z�V�����NP�cW2/gx�����q�<Z��҃�My�����,3���P���5����$�$�'�������4�DF.������N�6w�43��4������쏑&��Zpz$�#��W�`�b��	U�|*e��S ���ȪhG��g3�/F��Y֏��!U�MQmO\8�G3��]� ��U��_���&�8�l�[B�������7�}����Fm��=���)|/�u��SYi'�.�OQe��?C9��34a�W�� �F@�E#�9wJ�sK��@��\ɪ��a�^�wH�
�k>M���m]�m��/��Ƿ�s�b)~ĺY�l�H�W}�r/&!�ߩ'��=p�!W�*8�����t�v@:m��=s�N!%.ڶ|˵�x��U����a՜�R�"QB���[��X��Z.o���F7xǐh���;9:��P���[��pP��.\�n�F|�RRҎ��ߡs��=�����)'�q1�]�٫�ʓf�C�@*fȨV��7u�O�<��>;Jө�66���<�����Q����嗇�� $�Y��O{�Y�z�I4D�28 �w@��>Q7q�����w�ƻZ�4D��mц�꾟s>�s� s�%���m���[D�"^�t����:h����u��j�p��M�&�7ʘ�Qj�v1��4�Å�@�k�Ku�ǉ�d;�� ������a��#���$x *�aP3R�wI�����^:?��l!��LpY�	��q0�)���,�i�m����J�-$��,��DT�&9�W�^ݛ^q�+��T6��xx�7�3�q�w'
e�A�}P�V^��F�]�O�i�����O�a:� ��F�[���-���H��SE2(7ǂ|�G����+XS���`nJu�ɭ%�Az�4@$����N��gf�0��ʴ�)ȹ�:���5���1�I����7���x���������������k��,���cn�?F���!���|����X_��x��#a�oww�/������c�u���=|��F�(����]�E�s$�h�-������l�����W��z=
Ͼ�&��4�Qj�T}�h�O��d�jTgww^��ٶ�q���+�vם����^w���kG�/��^}�c����޵K���t40Q�f�'��������Ug��oo��T\��N�!�f'�]�Or�|��9H_s����`�� ���$��_s��� }�A����5�k����9H_s��� }�A�������4�|�o�7���/��4�+vT�輯+r	T�[�/Q��S���P�H��?�L�0y޺��Z�_����0����5����:_3u�f���f�8�7�ԑxo�E�%Z�"�H7QAxK 3PT	G�Su�t��ר�!�O�8����R�T����`���	���k�[��v���+m��PA`���8wz]@>��&�N�륾A�uĈ>�>�bQg�����!m����D����z�`l{��IH��쮐F������*]wL��A�ּt���l	$�)��J��k2Ҽd$�:�d$+�d$�B?��b��R�ܱn��䴿y*���1t�R����:�j���H��:Rʴ��>rf�}�QY�w�P��k%����V���v����D���5/K�qH��,�׏%F4��!w�¡,L̑�V%��0���V�-���k�7 �MV���_���q3_���	i~K����?��A<	�A��&����4,=�~���&h��  1T�����M �v�x����L!��_��3eeQ�n��ͫA�_d�x9�]�*���?��p�c���&��a�o�ŉV U8�}~���<+��$�J�-dY�<�j�������*���n�@�[$O�,qJ�w�ĩ�'M��W ��P��Eβ3�����)K�}sZ�P@��%��4V�d5*�Uw8�#y�~�J7�K+̞�W>�l��Y5�*��u�e.�~�na�� eW�HY^wyхDL�{l���6�l���Od[��پ����{��ͱ0�o}m�ٳ�B���'_���m~���ɂ��|#��s�ئG�0�_�s
6��Y�_Y�:w�B��0�1���)S/�j��8w�X�#��5tE)]M
F�>L�,	A\l��I'}|���X��tV���⁨���C0y�[�\�x�ɉ��4"�3%���4�d��$����4�*�^�E-T�[�$CЛt��~3��P�_�R��p�Ш�f ʊ��Vs!E8���l���.�$ظ"�5������UhD���6�{s�;x{���y��Z��^��� ��z�.��4��Î����u����ct��;��h�Am��0냶�������O;��ݣ����s��k���֚<i��hs�g���|r}��v�>1�ig��v�ۭ�<��q�F������O����͵	|��7})u�_>S�9��~煟=���̇O��AK��?t^7_=�t� �ҀR9�n����N1	��ݞz�u�T����Ԑu-Č<�����G�9B��UkBCk��T��mE�R+�A�ӈ�}�����vN��Ӵ�w�} *�7� E��7Mz����}��i�
�����nM�s[���<��긻w��'m��xB�H������ۭcw@������0O�Ǘ������R��{?.h�vã.w����h ]p�N2$���'		Tqnl�R���7��.8����s��8��뀝ܥ���59.�����t&���N��ݞ��yc,X��MּY��LC��v�f��6�i<r�e���tx�̮[:{\0��+2K�dFY�����A!	纖���,X�ZK��k�ƍ�t�h��P�4t��</m`O	�?n�}^�՜�,��A��'�D>(䵀a}����[$Ʌ�=Z��70.�L���}�����-���NC��s�~�:K-�ǿ]���U���~}�k'ԟ|�-w&�S燎���~��~/B�R"(tG?x�%N�U�+FZ�z����h��gk+�=�v�������G'�������kJ��'i2@�� z)�J���4�˅��e��d/(�>�#��\l�.��1V��i��d�r��pH7eA"�(����x�g|8L4��0�$��M�� >Lz��kf:���Y�>�f���%"+]�p�\��]��Dn>��V�[�p��|��� x�i��/�����E�Fb�$���cu���梮�,�LEZ�p�hT�x:�"fp�S���#ʢ�T����h������֘��e��0�q����	|44,��� X՗��H��'�Z*A ���R�s̿YB�Nqbrs�m�tW�N�T�m\Ɨ�Y,.ޘ�iѭF���|8����L!� kK��٣A����m��m��\�#M:�v������Za��������517&J���b�Is�Q�f-�'�\o(��f:��v�����tG�C�f:g֨.U�e��H��^JO��/֭�v�_8q����3�c��������q�˝��ڬ?����0�?�_�����% }ԿB�?�ь[A�z{�-�w���L�P�b��=n���g�	�S��*A^{���^�A�ި��[�UÒ�47�e��u+X҄_�/3烋��֧��Ҽ�4��vIt��� ����8�*'�`�r�( ����	+��ߚ�T��ΓR��u�Q�G�Q�t�_�|���_T��9��O��uK�m�J���J�N���> L����;�`��	g�e`��L@�gr5m�%�,�]�$�B$�W��5�r�,#�y�vW�EӇ�>�6nSw2-&[i��U+~��;�'%��e���:�X��`� Pd���g�`*A�2R�:K���K�S�je]�ݻ�G�t�6���t.惡��+�q�\͗�0���~&p�" ��< T��w��w�Um�*L�x	mq����� Ob�jf�3j#�"�F�+TO�W-����qX���*RP=��W�d�����|a�1�����Z��$>iy�M=B�e�{&���uM�Ot����Z��+�R�������I����������[�`�=����"s��W����� ��6�%[�4��ۢ��O��?�n�#2��}�nd&!��ZUh�z�]&crb,w��w�j�H%[���f���;��M���ө�z���8`�� ʙ�:�L�cz$}xf��mm�s��3x�C��; 1��TT�ND���u��XwЉ�<�b��I��$OG�R�0�|�ݖ��Wb�y>.-������
;��;v�>�V�oYe���&e��a��P�h�z�=�o=/@A��1?�	R�Z���T��Y�Ϫmka��y����=P�$>o��Tu)J�ڔ$dĵjõѹ>�J׵�ui�����Z}��k�\w*�=)��g�js�������xOﾧ�͟�vR��-ph�:��1˲��ZYk[ܞ4�wc�G=^��VP��%�0cd:T�i>��7����3��	�7�b]U�s|m8��z�-����k''�W�-���!��������mA����O��V�8��{E!2���5'�Tw��U�H(�-2qi;)�IK��ې��j�C��,�G��R��k�l�Vy�� C�La�����	
qu�iJ�Y�ՄiA�u#��Z)>'���(����ԛ����G�=��,g���l��] �o9|2��wHH��/^X�7�Q8���D'�L}9��׏��
��ji���n��N�0T�Q�L�4Vܹ�<Z,��rN�O��O�U���IS�k\�Y�� w�՜��dw���x<��Ysn��<��zA�;FF,��y�N�J>��<GU@���)��vA�v��_�I&'�����DlM#�b��+�%g�s���kׁ\�1>���2J|�w�2�>��`~�wJJ�<�LX ,|�������OJ�.�x�Y��,K$�k�?=�fQA�@��,�R��|(p�=rI̤tW���br_�:��6����c>�E,tg7�I�`�����(p�HHW��,�f~i#�Ճ�ԉ�I ik+9!�aA�<�?�?�TU�~Y�RS�ӈS 6�W�D�/��G�
�3�S�V��7�U(�{�]�������wOv/�������f�P�0�y	��^�x���^�Q�v�;����Vt��+�x:������������}�s�m��+����n��^�Y�H>"�_�H�$]�����j������og/'��n��K�,�=Yv�%~U�9[E]~^��nsV���Kq��Q��j��9�����Vv)ت+	�����0�I�W$�uM�>�q� ��J�v8D��� ߭8��-����$z]�n��+l�UWL��I�W���GĬO������6�LTi��ݨ;|3sG�'r=35E �2c�#�9�X�J�1G�-b8/�dg���0��D��X�z��q!o�W-�T&��yaY!�KoKPQJ���C����Gt�a���&��R�cw��q ��+1�!��#t��IA��$
=�����阗N��� K���֣��Շ5��O�z�=����(��ɼqV�8+�Vy�:U_i��h?�3�G�m�If���XYO��E쪵��V>��U���)�_�/����q�YL�,��^�G:�Ez*���R�+�ڗV=�1�$w�	�Pa��v��h'�+e5V;�����~K���H�^|�=g@��$4ת�i|a�����
�m�o`IC2g��ڴtf�b��I,���^�%a�b�� ��2�c΋ �h$��/O�/����ro��B��Y���49:�r��0����E93/a������}=X�������/��jN��5��$g[KXZLA�}��<� ��>�FB3�j5����ْX
N.g�N���[a6��he��#�l�̍��m.��V�5��V���o/ �hy���2X�dKeV;��):�v����} $�2x�Y
P^��1�[���*�6�A�u�3 x�U�c �SJp0<B��!}���L�@�4i:M���4�����b�3���5����h<@�:�˅�#J�#��4�̙��$��n`�F��{Y��t�g��Qy��� ��Uq&5���{|"s:�*��L���*�b���o��|�O/,˓����QFkhK!#ӓJ��˦���������䓓�ⅇ����w;�|��[��y'�ݜ��y}�_��" �Rt�,�|Y�#=���,��V���,Ji˛���k[X�3R���7X+mg��A�i�e��`���S���`��B>�S]��Cw�R�`> �s�<���x�ʕ��Ĵ�)>�O�N�y$���������2�x�i�V�@�����uT�ɢ�[wK���C����#�d�̇��'lD��1��f��tU�kw=�mK��c���	 �]U���^2�]�yDOR(��[i��f˘]���ݏ�(�@}�hmT��O|m����NytGX��~CP�
�.�|'�,��։��;-���X3�n�f*���K-���D�s�b�79��7��i��+���_�����%DЭ��� �y{Kχ��P������5U��gu�W��@�ʂ�8]�P���U-y��R.�qJ�x�,�4"S�5�r}�+�V&�q�F�/Ɍ�W��0�Qz���~��"����+�i]���<��?�iA{�)W�M�&�V��m����;i�#sk��$y��kE�M�u���M�KL�n�r}[�^��|��Ёx�QNh"�ȞV�wa%���)H:�B��rO�JѺ�c����� ���T�x$#?b�7m�Qy�o�i<�m^W~)+Zp2� |9�OhP�i�&�럪����K�u5G�W��Gy�ꀁ�r_��:��I����r�H@�s�h@l�V��8�Ϻ�]$
ƣ�$�_p�\`�:m/�|ڰ��x���p�x�"��dp���i����t;�ѭ�,R��Z��fӼ���
(\�il�rа������,�w�J��^M��BU����C���?����M�Ͱv89C�4�̹+���&(|��4�[��������W�f����`,6��yD�vc��J �B���׾>ۤȖ�=$Hw�G:C�c��R��VQ��Xca���j`���b6 (�s�u����I����PނtVT݌l�K�Gw�k'}J:IBْ���d�-���頓�ty�t�JeK:<5����%�$o�	6�!�>s!�>��ˎ���%��ĉ���y9h.y	h�c�i���w��x���Z��<����4N��' �$�,�<O��K�x-M�|V�>E�!*�S����*�T����Z8��[<����8��xr�V'����R׫��Z=b�yߨD����,�ю�
Vl������$����'��ڠ�_Q��(qV���@��%z.feU�XۼxO*��Vw�BY��r�3Y�S���g����w��|�е�z[Y��{^T=�Q>��E��Z�zp�;�ZN�Sy.�ݡ�Wcѯ�R��u�8=w�I����s7m0.�^�d� �H-e�v�URΥ�W�@����4>ދ�v6-��\_�kbVc����<m>�7��#���@�Hf�Hޤ�/��������E-�%gW�w�.r9�[4܊�ٚ;5��G��k��"�:�Tv�t"�}*۳!�y�)AN�K�OM�.y��q�4�!��ΆC/"��r�a��=�W�Yv4�
��yN�2e�Q��ƿ6����*nؿͫ�ݹ?>��9���m���D�[���\jpna��}E:b5����4�_z�\�T��3�B�UuP�cp�*���t}g��	��|U�Y`����'�ps���>�Z(p�6�^)�d�gܼ�Yq��-}��jӍ�Amg����NŹߵ���Z�e��{����x���QA%��9@�^��}+�	0`�T��"�#�z%�8�����H�t۱��.��9�)��lM��6�l!4)\c>4����G�� *'�̍�X�r�9~(K�ۿUf��h?z�V�1@�#)�ā�r��j��i�%�q����nI�[>\�X�e��˝a���a��ܪ����b0�s!��C���]��0|ns���[���x�%���Tv�%	����k�����zA	�J���Zm��E%���;v/%�qE2?O�a���Ώ�4~w�?��߾��?kkkϟ>U��3�wm�	�+?j��Ƴ�gO�?y�\���?}��;��K/fH�a)y-l͆���>̿� ?x��;[��^����x��ɜ�__{�t�q��7��=��Z�b+r~�������~������=��÷� =��H)M~~������G��Y�8lP���U��O��V�>T��(R�t8�ĸ_2��#����R�J�a>l��Y��@u/��
��q�&�?�bJ&*M�HL��N�)�A�S��#89cz��~��>�ϐ�7��jrəD�p4J/�A+��]�9̢p��:A��F��#u8;��Ԯ̈�-	��A+E���g	r�
���q2�\qt��-=��b��8��^��B�)ܙ«Q�a�>0����2��G�paR1(?�#q^9Ix��^]��3��|��Kw'�(�9���,����AiFLגw��5 ϲp�lNS��
ǕE���p�$����#s���<�,ؓy�1癁�\K8����K�ܰ�0���@�agD1a"���VΦ�)��t���4�G^-�[HS1�2���=.!`����pY4�2��aC�=E7�b�?�`����X�<Г��P�4��Zrn"_���Ԫwv��#�Q��!�e���f
�r�05Y��,�(
C�J��2Ă
S�+�q��L��am}^���$�uZxs��=��qT|�p�3���b�)��ҹ���4��a8�0`ʘ!�����p<&w�u��{��n'��� íZD�S<xl����lR�0VK���xO�0̕��B�A�C�@@�A<D��,����p�."��=d^c���x2�q� ����Нs����G�ۭ��lv��PEUs�J(W?��i�;EYW^B���<��☛B���[�1�V�8@���Ѕ0[�=����L�[�ф഍Y��Q��_!#�t�[�^��<��F�|3X]�� ݛ�aދ��1{u�0����I.p_h�Eg@������6����DQ̩s����C6i0�{��C���	[��̀�aMD$�>�,b��3C^r%O)ŹO]Z<�)���40��p�v:�F'��cH�a@� E��������S�e�D�A�Q ۑ�p*���,��Y�B��+AtGr�f>�[�^�o�T��K�}*�K	�T��G6K��6
�;��-�d���ͱ	:!� >�%��tyJTyz�!�O�Q	a7\N��0*� a� ���$'���
�̴L�W�ʔ���poKN�J���,#o!Mr3����HO��c�9�jH���H!���xšY��g	Bu2E�OZ/#fw�0 �� Q��|z$Rd,�E��)\/�T�aGvf�(�0�4���i�$	�"Kp6� �P�D+L$�Yv��JS�8�p��k�#�ko`,*�*ͭ��;Ut����� ��J�m����v'�i+#�y
N�k�{�pGD�����o�@8ܦ�T�2���	�V���(�4'\�DW�r�	i�\(� %��B]͋4�R�6� �4��zA,��X�7�,䀸�������ʈ@2W��UK$��,9�=��(���-�2�yZG
�Sc�\��Ʌ�Hl� � CJ������q�)%�C�x�u����^Ou���1��㝃�6^kau4L]6��v����t��=6�h�����7�1��9��c����u�a"_�
H�ii��1i�N���{���=��l��͜d�&Y_t4�N9�8���bsi�` G�s xXnZդC���HjV���ʮ\�]9L$���5f�0�Mj����q� P�	];��J��9`� #�a��s1!d�Hҭta���@�
�2;!��$ ��R�P���V`Z\�sE|�Vdb5YS��A��*�鷚�8�hb���j�Ƃ6�YM@Ų`�]��S��FD�����v�gMQ��Є����)אIgp��]$�22:�F�x!jw�?G�cA�)N�xT�J��S�Z�3�� d��6]�mx�M$���[����Cgv(�DD �?�34t$���*m��m*����'�aÐXx&t�Y@ģ�h�B�T�]�O/X��+s�F�$ FQ���)�l�hC������E��S@�J4P�R 
{$3$ ��kWqm:�Jފ	B�x��Nq1��/�-%�����"L�G�~̃'�M�<O@���*�@4:�/xT�$��(r�@t"��Xݕ�y�$���ĮQ�@�X�Q�P�03����m�-����L�X(-ꅒ�
�
n������$�آM���D,�4�k	�f+�RRـa!�1Z�38�^���u�``�5i�X�($N'=!�lyM���5X�e�����I��E�s������A���R��B�S������DUv��h�Z�X�ҥ�d��k�^V�0�ȔN������n��!y���Gx{(���@�h��� �>2A��;POc��X��tv��!�:���r� T�tp�֋�%ՙ no&ʝ�+]��lk��0�o��1$��h�D]�0�S��a�vܶ$x0"���z�� B�f!�sG��V��;j؇����Vj��jL:���W�:[_��@!��� �t��><c"��
@�r�&�,n�%�JV$�	�y�4�;~ZW�bX�b�*"�]�(� �Ҽx���L��*#/$
�VxR^b(�
�kBD8��&�VQ��+�¤��@]����F�Qx���-5!�OXy�ΘA�)p<��3���KHL��8�u92o�	������Kp�xeZ-����"{m����~8����ny��0���I�IH%@���a�Q(��m���:�^�L�ia8�;�dSmj�[e�'x������"��g�8�7�%j�S�]�9=��<(^WjQɜ�)��� ����Fe���hs��	P�@`�ɾ�d�����_K^m�`i�:���~G�0zF54�#G�u���/�b/`����Ş��1{鮒p̵�,q�t{vj@c���ڀ�,P�
&f�F��)zS�R���P8��1�%Z�%u�Qa���S�0	��1�/Z(��x���+��]2b�6�f9ԲȾ��V'm�<�7]��-^�U�t��3@��2nw���j�@��B�jd�B16��oP!@R꯵���6%C��6�=�@��E�J�����:4�����$��w�	Aj@���g�(�8�o�ִ����r
J��|*�8!f�:$)�����R`�Gj���rA�9�%byd������v����a'�%(�g�,�n�!(�1��P�$��q��?���W�NHL���dG��&�J��,ǃ�-�Y�6��kf�7B�(���>o���%J��'�W#B{a������X��h�</���&ΗeA��r6���.��!v%"�ʨ}\C��'�,����T�s��ve!�7 /*T�L+zdvA���,�	�`��2'G��F�Ynl,�"��V�5E&}p%�N��p4l������Ć�Ki�E���i�1x���h�md��c��F4���.	�QEj8��x�,z�n�������q֟�u�/Rq%v�0p,������S���pJ$�{� /�C�d}���9� r�6D|�B:��o���J�_���p��-��8�\���;<d��"T�d݁a�(1i3F�<IG�2�-CrcZ9F!��j87��))l�Ln��Ge���u͂~�9<p���0� �Z���XS� �պ��?>�;�@xQ�"C�F��b�'K����=�6�/Q�V�/�2���ە�Y¡�F�)N��L���o2!	��: �	*��Y?&��\�	���<�W�Y�8��#���N(�f*,��VH��M���Ez!��X;7A�JJ$�t�]�d�_w��f�epk
0eg��C��I������t|��\$�[����0�Df.�6�aZ�xpY�ٸ�L'�~vʒؚ��]�T ?G̦WG%�l���E@	�pbh��L>\$1F�&�� -(Z<�0>����a�ꐳ(.$�uj0*,@����ڏ�v\��Z�]Pߜ��j�J�5�h7��=8�)*'/���\it�PP��E�q8>A^�$s�6��BKx�"۞��D2��u��ε��U�6��1�s�S���$�ms�V��(0"�>�'U+n�H�4t����6�C�Ixe�2�> ��12V"�����X�:R ��Xa1,���i.�K^��U�|3\N����
�h��ZTv�Իa���*D�x�8Bm�ũ�F�u#�eXb@�2�	;�8������g��Dh��"��p/�<�rIZYa �0��&�>X���%�gB����j�}�b&Q���6����l0¸��9����I��<�	�Q����\Xjm�	���go-4��	�6�L�N�A%��"5��j=��^�̥Ԡ�_���,�|W@����y��F��xy����Ǽ�3Ɇ�eZ�����3w��4��� H�!Y��w��C#+�2�C^CN�p\휢��f(R}QjO�MD��w�	:D��`a�d��Rm�aqc���'�:�@��]tM_���9Rew@B*j�#�(ธ����!B����B� ���㥶,_Vh*�f�d9*�	Nii����F@$�.������"����T���#/=�O���4�!�:W�+=Xߧ��@�;�\�����p8sx�o(�0��(�0ʌ�:�:�1\L��&Bͫ��&+�4�OId+��n��
�t@�nC�9�ίr��%̋Y��i�E��$�'ak�S�jS_����Pf����< s0J-���Y���p@�
�Y��7�s�D-C�=a)���곴7Ţ���`��Ufl�u�0�t�OZ��0��8Ě!��lXb���
���A�(����IÅ�x2) ��Ӌ�����1 +9j��Q�����=�$�� V#�zy�H�	;����K�>�g��ˈńU�l�ZE=X��(r�:=��I**������k���ID�s`e|���ZU.Е�����Ckq��Jl(N��0'Ɍ�Qt�ӋzY?�K�QqmWvCث��<�\�G�N�ũ��Z�h��?m��3����=3d�',�Si����Qgђ!h��Ω/<pѨ�sAOf&t�>��	� �,c� c3*#'�b���
�&�%�3�D4=�OJ��6�_<����m��	گ�e���;���\q8"B�r�$�˱|;��rT�bֺ(P�Z�1n����.�F�Pk�_�.ù�m��W��A��l�<�9�cn����W-�MҀ6�0&��:�Zb�eX�u�������^nM4����.8���9M��/���?aW'l/`G`DA%�
O���!C=[ t>����a�1��Z�H�[#�ѵ21U�5�.�F���Y �	�p��x`p��^R}��rx�w����G�����H����x�Ð��h)����|6f%��hE�D:S��]ñ�"��Yw���H�����K�1p�����=����-Ԟc��&�<HjPq�zȶ����a��$�����&C#=���m����t8�� s�u��IG�ax�R�"I�ζq#�tv�eO��X���P5P^\u0�����r��	#�W"Ga�;)��YB��g&��0��M�	)������W�G}@#~�_<���NQ�	G���0�Ȉ��`/�\�3�t�����3��T���L�˝%44��	�'�� iq���l6�$�QCH�"�w8n���T��r��!8�m�����я�hH���>�b�2��ؚ��T'2"p�PT��U�n�x<o�H���ԟsB��]�-�BA>�PŨ�f��8��y�Q_kP�+ND+�TRS]�T&l*�}qh�6O#R�}��5?%Htg�9ђ�tM���Ƈӱ[ύ�J6-��.tml�#�s��fƉ��0�S97Q"F��u�&����&��Hd���h'�U�h:��WF.X��P��J��#���_%�8
*Y�۷ok��)�4r�ހu}5�a
�LH�E�XzȦP!Kflx�I�`GĂ���N!��ܻU�II�f�ۃ8�p3ט�ɀ�;���&l�]��G��z9B/
C�[��Uz�)]{���a����Y{m2g+rJ��JA	<��e�"�0
Ph�@��ADf���()9��PE��	����Ҳ����[���c�>z"X�E��(�67��c�Ù�1�q(��FՅ�,�sw 	�Xp�*�=g-�A��{V^�L���&²,�]� G�?�
1����b���4���H�\AS	 ܌pb��[��cS�Z�[X�X�e�#mP�9�Z��e�z�8.��%�N;C��xΨ�$@�7L"N��"���˭T/�g�%�&6�>1�� 1�ǌp��M7���i�`uא��b�\pv8�����Qm���ʵl��Q�n���J�g6�7�Dy�O
4AG����UPЕJ�P$����s̀���w07 ��UU�1��P�p*J O(�ð��E?����d�>��g��X��%<m5�q��/J/e��8�Y��ǥ�`!һU��2�s��tB�bC|�b!���I�qw�>ԥ��[�ag���)#e���7]�G�c�\TF�a�EU^�9E���2#��sz*�����]_H(�0%��:?�% ��I~��-�yQ�L��c�����PSr���S"��ϊkx�2�vB�tSR[�þl
�c~f��	{a�(��Td�ٵ:`�3m[,y[i�j�,���s(y��l�S��~���yL1��ǃ�$���(�ge�6�vN�
]����[��KJ���1��BBS~�neP�Ñ�Ɩ3��Ĭ^�0p1�F���}�uង�����DQ�GLt� ���2Pfp{�(���Uj��h��\�$H���C���=N��:����>2��j�_�1H�so�jUg��Q"o�|��Y�.�X�6-Ǒ���P�:�r�	�䐡�qM�1H)E�������`*Wb+F��F��wH�jb�L((�7�w��h?�>"yk욹���]�Gs��C�Y�	�@T�%9Z͋yYY�g�*6b	�~�� ��3�MJ����3�r$ɂP��1ʜ���D�������EJ�S�ͧuj���y�Q�j��(�=��Ż���y�wm�\sK�^��~.�ҁ	�3ln2S�BF tbT(!�_C�/�t'�Q�	=�}¨����e#�wJY��I�7��*	YǰM�u���52�LwsG	x� Q��k�vŎ L����)(q��7���Lƈ�U89I�5 3�A�6�T��Z(�N�ai'o��|3[`*O��*.��Q���e5�D^-���x7z�H	�����T��-,h�
�ɹG������	
#�����~W��S����Ԍd��c�.
��lDd_`�!��b&�(+�J9�˪J���X ��=6�6�2[%�2�4o��x����T3h�2ٕ��!'?[S�j�S9	��0(��mJP���n�����Җt�I��^��{i���,'���x�z~��	����b�Χe��n����\�tП��юj��؅o ���Q�yQlܳ��-�1ߐc�z�V"��%C�T�@i��2
�a&���nʷ����iLc�E��=�Ћ�{�4��7�� ?�^��
!�ֆW�UG%��z��(� ���"��D^~�����Gy�m�t	;�:G�v��(9�p�P ����E$���N��r(���R9$k>�����֤3�8�gY�,�DD�`�6�JN7��-�J��H��F���U�c�i��db���w���+Zr�^�!����gj�p�!��`ڐ� �+�aY��=��p_��;��I���K�h,_��_��2�gN���U񸫦S�#���K�L4$�a��8˩p��3��+��/��]��#�l��e��&��!�bdH��X'Q5���d�?5��]���9�<����ܒ\,�ye���c�N���Q��5<�c���1ǭ�E�m�u�1�1먭D�w'a��$�r����+a�]���&�k`�^QK�u��Z��~��*2(���0��-����G�8+n��F��y4�uI�b1�b���݂A�9kBq&(~OA��BabI�3�>1�$6�����B�ʵ�M��ﳐ��,����	�^iQ
w~{c��n�^�#�Ngoٵ�1��ҕ�cz |�f���^�09�����O��79}0�t��t��i%>puil	��zA̕��p�L�F6R9�p$����$V/�(�c�$�d}��uYK]r.a�c��t�MAd�;e,��P����S�Ϋsh+pR3�@��,��	m"�Q�e�mtWm����-��]�TH߼�`<������S��6hi��Mþ9p:�HY�ן64���y�tN�n�wMJxP���̅�#-n�"PZeD Ԟi���%��
�%}��Rz+����Wڐ-�Ґ�LG5[��Vh��E�c�4�1��rjb^=S�
ܳ��vՎ�]Ô����h�U��ir�O�vH���sp���KZP\��\t�v�[�Wܖ}�D�]6>1ؐ��?1қ���슬O5�L$�+m	�i$�)v��S��I~���4X�JE�H�%��);��K��T)�}x��(	9��k��ݟ[��'�\ֶF�\3������.L�L��α�sv[ڗF7��ƭ�r*��XFVMY�#����R9Kmnp�+0�"~1� S+��cܤ΋,MIR:�=tL�3I!��0i�2��N[C05U4�:��:Al�^ahs���2�TEg�+�
e�RD�Q��VaJ�;VS�l�����R���F`�c�����U��FdS��់ȢˌxRLq��]�1h@��TAqB���y�e���/ms�q�`Une��d�cV7�#�tN`3�-���)� ��܉�%YF�Q]D6Cn]݀�,�,�a�I�IE�:�ꀏ�A3ms��
2�nA:Ӻ�M�QR�)}���Ut��7:8�Ey�*�c4SZHG���i���UW�s5��6�T`	=��ˏ�	�QYL>X��f��S��G�p�T��"�v����jX$�����UM��,౟������!�o��/yQ}a�:�E�l����SO2ҋA��Q�k!-_�*2�XrHx�j02&���	�T�/0_�)J�Dj��N���ڐb���jLqN�u(�^U
)M��R$���j����f٬�K�Rm�LI���t;��AiI.�	>U'-S?�#i&�V�wV9~.�Ҿc^�R��q��:!`���!�ɠjjsE��,z�4�\�D��V\`q���"���� �%k�I,�ar�a��P{a��o�����X��u�~&S���e3��u�	�! 1��TcӲ��L�����mFD��e7rҘ�]O�ި�Z�haq��y��� G���\�t��B�?6Q�N�Z��!���Qevg8�]l]I>�	��ST�ܮt}; $�[��؆��mY�mЄ�g�y*�tjY�g�i�߉�H�Re.�$�K��L1�T��m7a/%��k���fT��h*�4AK<���u�vʺ��c	�ǑdR0����Y�f����)Y*�\����<t�Aɨ��hfx�9:SǨ��cn5���-��R&�K�A2]�<ŝ�@Y,�����%2J�	͍��'$>��Y���W�N�2Z`�r�Z�n���S�L�x7H߫@A�:&��DdW�c����v����1�������b�F�2*8��H�8gW1�<i��N��C侽T0� ��Eȑ�R�,���-�0�cz��^,�{��\8�K��8�?������B�$�b��+Q���E������ 3JF�?gBS�G�X&Fp;~&�� ��J�b����[$3,,h"�\.1�Z4!�����*�*(��&f]L��VO�#���������d�sl<s���[T�f��Dq���Û��M90���'�v}�jQo>
���y��z�?��U�s�Z�vw����p�/,�7�fM�'�����l������q臹S��/ߩj��|86z��$4��u~���ҁjq�l�z&67Z2�ltn���;�CI��p����Y� �VD��d�Tܨ�-	�e���CJ&vO[&4�Q�G	g��{�U;=��~�u��R���uxt��Qg������w���a�ho�����^�tww�:�v�j��#����[��c���:����uU︃v�ՏG;�;��Ӏ[�?�|��8xs���=���0;uT����n����v�]��uz���q�����c����5�����vCuwh��u{=X ���+�;�[�o�a-�
F�?8V�;�3hv|�p6i�G����{ݣ�7�g�������z�s�S�:�򭷻�������A��RB ~�����`��m�Ѕ1���z���s Ǆ�U?�E������������������izo����1tvw�~w��9�I��G?�l�����#������r��h������ᱫ���b�#u@�x����8���[�+b����|�%@;8����3��1������؁�;��y��"��u��C��^�B�lQ��� �
�C� ��ܶ;{��=3p�@�n��awk��vT�=�+-| ���1���������������Ůڹ�H�vz���v縣h���.�>����u����}��V�{7pg�O�KW|�h;З���ugg��Q�p� !I������ySm��cS�U�I���xՅf��v�:�<���	�F82�=o��"�$���^)I�e^�虌l8�نߛ"ik_�c�g�b�N^����,TxJ�R"�H]�t�%\X�gUF
/Eg�rL�Qʙ�����H��i�����p2�(����Y{��đ�l ��d|@�tg�����=ZܾXֵ���y�������!q8ױ-�	Y�>����� ɻ>�\�W�u8�<9-���9���S���BniC<#��ka��9Y�M����i�?���=���Q~O��W��j�KZ7֏�Q�X��C1Z�U�N�_��:��5\��=֍A��l
"r������{3 �K��NUC�(1�DC��${��o��ԌLSCeY�"j��R��]=g83�]�)[�M��EpR]����Ü҉d��,���A	Mq"1�����DZ�Zݪ�o�:�w0�����x�cy�U�mxǽi��9�j}P\�7T�Q\(%���_H��|��՘�i��Qp�Ѫ�nZ/k6�j �}����ѽ��tHg����Ң>��5� Zd{a�j�������Xq�UQ������zk�8�"=\�0XM�U���ⵉl�#��,u�Zd���c�C��=�N'�����e�,���쬭�=����:��I7ni,"´�����8ռG;_�&X5
�
	'�{s���C%�z�[����VB�G6��3��)��°S����N݂�X�FRV��y���M,�!�f&�v^�v�wwr5�t�r�jz�_����Ö�x�-� Z�p6LzכF��l���%�;]��� >Z�ί&hn$w�2����Lo�?�Z������c�T�`H��ql[����tX�B�/���v�V?�ghA3�5�L��釚���%S�)�ZҬ���
#�^m_A�/�EY�b�P���ϭ��+ q0�.VƫY7�)�V̛��Oݿ8����$Kh��h��r���pI����-�(�1�p��[,��{>\9lbߥ�_�N��C�C�R�cF�ו$�q�_���;J�`�L�E�4ds��Q\ES1Cʛ92��g�=�Ա�^�Ow��.��e�{%��
o�ԡ���t,��<��y�t:9�j_�_5����d�:��Gp:��G����Q����m�_h����gO�(���������?O6�>{��o<[����'�����g��־�z���XJ�F�A��p���e���y��n��oQp��=PC"�������&|�M.�������G9�J/\�Pe^[ �c0�T�(��AL`?�`�#~��4�NLKt<��F�
�F��-��j���9��a]�	����l{�!%,� &B�(8�t�]��7\�z�@ Ǥh�Aч�0l��<=�<��v����_-�i��Ew��]�C��B�Ы)�
��mF�,���ꨳՠF�ϰ�U/B�Ogá��ŉ)꥔Q`$�n�l��#�4�$�\�o~�I0�G�l �j��	X�5�d�ͤ�<8Ɋ�,音"�0-�v\� v��}zb@�d\z��aN}�fAV|\�r�>W�+b���9x�i���|}�.QP��!��n��>�������ªp��i�={�Q��8�(�'���rcS>7�4��O�ЮڽiM��4�+�`�^꾖A�q� N��PP��I�l��GǠϐ�MFlt�˒Y�)<Mǉ|����D�Y�-�ft���O X4�,����p�AJ��wn������I�G���lm��O��˓��y��������\|��ds��O���7pt����a����i�Zk]
o�mg���ڤ D�嬲1;�c�Յ�����ty!?7�/~����o���vO^uz��~Q�S�#6=v�a��[���ͱ�������+���6���緇�����y^i��ڳZ%�k�R�YT_6�����]i|#�o��-� Sw4�s��)MK�!�#�fgT��*݂���XB&T��m�\��T�\a#�=����A4ѻ������M1�)�P5���������9�	��π����* E�I���py�*�c3��ZR=(P�| :��w�Gj�l�x2J�1L��զ/�e3V��%3�����I^5'�|Ҙ'����I�n�;�Ӛ/���*�d��쫑�=��Q���t�/�S�����jOǓ��g�$��+�)!zN�V��x���1���E��o\�ق~��G��0q�{�ai�24��az�{?B��H�jq�cSe=�pS?�u,a�h��@�[W��7*�;�Z�J����MX�Z��6,��D,?VJ�E
c 1.}4�����\�h�?;Y_�|�ds������ZkMK$�2�-䗹��1��^��p�fQ����\�EY/��a�*�J�GrY��yY���!4�tn7����s�Xo�5]Է{�u�up�d�69qۀ�K���e}/�]��cΜ��/��S��#op~�b{�������nυ������o-:J�=_�o�6Z�ǭ���z�Gg���O�:����y��t������?��N֟m,��u�sx|��?�˘7��.R�dX]��.�E�vk�Ќ)�f�b����a��{��]�k�U��U�w�x�m��w�{T��f`�~or�^�A �xa�X�IG��ixJY��[+����uD��'�����u��}�y�{|�T�t���Tȓ2*Px$�N5���ܦ����o���ԟD�V�~�X�|�Ƽ�!��/�e
������?ƕ ޷�?���B������	?K�}��- (ŧ� ne;��#^��u4���ߴ"�gLk�~�B�������e)���������?'@�z{��՜�`C����/G�	|��[R���&�Y>)|�d��~�8`}[+�%�a�I|��$Z��BL<�XH��K�T���7��;N�g���Y�2_H*#آ��Rf���U$e��AB�ja�w�vo7�!{1A��
��ɓ7��oJ.JCPt�����U���XB�@m�G��$����s����j+u��H������JQ����r�n�n+�ZU-��h$A2Q�<U������ 2�����T�s�?�ɀ5|+�����?zYk)g핏�H�g�[�]��d���xԴ���C�|�}����읟?�0'�w�<G�����+e<��-��5�f�m��0�F�ԋ��q����i4���� }o-����;�V-�+��Z�O�V��ܢ܌��~�aj��yU����5P|�5	��o�ÚƋ��}m�tun{yV�H��jrx�F���[��;�΃�B�c2BXw��y<�ȧ���]�vi����6���*�\�a�xTg9?7�
�b�r�hx^x�"���sS�B?�.�H[�)2��րs9s������5lė�fI�Y���[ٌߘ3U@ܱp���+dc^���F�c���M�x�7��=���&D�Tw��=-g���-	ZC[p��]zN,@����/��=�5	4��{fK�.������
?��vĤ��аY�Q���`CK��u�qዒ@ˤg*���v�9A�SoǶM�[믩�gne�6$jWa��ii�r��м흩Th��Ҝ�<��nw�ㆸd��^oW�z_Yd�NH���B=���R�p�TWO�9����^�����qgf���5�������Џ7�R�\,���-����q�m@�c�D����U��`�@b��Z�`�k�W\�=t�����ߞ�q��t���}m��wM�ql΢��u1��W`��1��:*n��h�V��r76Y��cZ|N���� �h��@�&b%�J{+�]yj-kg�Vw_����X�� �`]��Nс+����¶co��2@�̼,�Z~`�fc9ZQXKO��%	����f�pp���~L�g�s�TY	Gz=�>P"�+��iT/艘Sw���f�B�!2��Q�lmn�jvW��Ԃ��k�aj׉�P+�Azjv���]n���� S!�b��<u�O��Iڡ���L�:ϱ��O�bhH���s��h��\E� ��X�ȅ�C�M�S-I�X�	�ϴ�ʻȲ|�TDt
П�U#y��n��`�2���R$9�
�F�+����,{񁫏�@�4y¸�Y��s�>��tf��xe�4w��Ckh�xk��ͧ�>=��tB����ʽ��̈띿k�V��]����W�(��10���+o��
Y�W�	�� 08�p�y�uOi�ziR�d�I���o��p'�VO�m����T�M�c�T������iRAݪ>�t+|�R��n�&��@�Y����/�}y�C�&�s��,*D�� �<��T�ƃ`��6a�����A�g}:l��*]ĕ���?yR��'�����2t�"��Ƨ����(1e���(�{ߺ�6�$z�}_ށ�d�Iƒx����c;iO;��r���W�(+�E�H�q&9ϲ?�c�_�/v� �/�|����ݴ�[�P�%#�g�ڜ���uew��p�Q�u�X�z*��l����/��+w���O�c68��)�	�UU�ak�1�"
$?<a(p"�/A�V��1�ٍ��!s�A��[�hhޡ��T���d���~h��d���c�5>Z�8Pr����2ZަJ��;��x��1��Dy�3+uYAe�r���`9|��xvabr�ٷSﾱ�P��' �{���,��!��ʮ�}
�<���Ǜ/��w����{e<�a<U���@��+�3���+>���GzY ��Y�Gǅ�Y����՗0~�F�� b�YWJ���;�9\ԯ�M�b�x�� hr�w0��e3�ˊo����E���d�;�������>�k������:�a�[,r67�gy*�0+-�҇�GỾǪ�]��a!%��Mz�$#��Z��(�m��c`���N��xƔ`��&�<�T���3+9�g�ߨ�KB�R��=��6�t+���M?��Bݠ��'EV�Ϩ���BrO&�5��g;�~K�{B!���ZW�$��)��r�v����]x�PW�?�V��4.D��k�\(�N��qs
H���`r[G�>���]���B�O���i�fG� ���ln4�nJ�P�I��)�ٜA�3K�c��ef5�px�&� B<s!�`BƜ���\
�9��-�ͻ$X��v������M�U���/gc�؋>��?
����|��.�.���4���$f������������~�J��F�!�#�I&E��Fl� w�D�ŗZa�4~���&n�
d
��EE�51"�At��N�r���"`���h�������?2�mC�"���R�lz�>�Q��WKa����I����{�Z��6��">7��;b��1���Ի
2?m
�c�/��3���*&�������';�7�@p���>�
Ϸ��?�W����T���~��ĊԳ=�t�b��)}J*�x���73w����$ܚ-���^����'~%A�B�5}H����p
�/e�N�cq)N9*�+Z;}&c��W�aF6`NL��_D�
7��{��;u���!�U\�	2.J<��*�ӜG�k8z�$8�N���_��f�|��%hۜi~6iQ7	)>��M��9:Ma���ۻG���?jL�D�� S�`0�) bk����H���%�	b#o��v�=-�a��l�6�M��vH��בK�ZP�@�t&UH�a�V\����Tcϙ��@h��x� (��-	1�������%^1�R<����+���Y�gq���h������ds@��:kQF��u�Ԡ��ֳ�Z���N��ϲS(���L�؎EZ��3����>i�균�3:q�����
1SyWxT:ךr3	8T]+�-�17k�<N������%I����l�}�q��Y�5�����Q����JR-p��1���`J��s�j׻�(Oy�ƶ�ڿT�!{�:����Y?��ܥBw��J|�D�?��fxb�G����Z���e)��_ER��M��iW�ۺ�)J�l�ۆ�V]�%���]�ߛ����<���j�tl��mHXO�N���2�\ٳ�ک�����J(iC� �6�c@�eC��n���S�4�'��Z�Ꙧ��5Ͱ���e]sb���ZmO����&��Q\�7eK�_3;���Z�/����k��P�mh�a���͎�*
�رU�p��阎'g�Ė]@������t\��}����w�
XZ�q�2�Wm�����i�aʺ��n���hF��a	 Њ��K�-�uO7��������i��꩎
�(�:oq�vEQ�6��E3۶%��ב5����DS�j��E�d��8����c��ELK��]��t�T�,�r�8CUM�n���mC�}"�m�vն3d�2|�ڞU�UX[Y�]W�Wu=M����-�r�ElE�|�Ҋ�DK<�mE5l��PM�td p-��l���������A:�^��Æ�:M��p�z������: m	���p��ZD���ھ㸚m͵U�혊k����'疸W vS,, ��sl���`�4�82,8�,��m6��k���+V4���lـ��-�D��nǓ}C�]��m��o���	��j[��wղ F�W�������?+7;Y�S��6T]�T�z������#wLՒm�q;�ǲ���Y͆��K'��i;N�m*��D�er,lAV}��J85j).�)h�FueK�!�U�Rkؖn�y��AA�fz��K�;��XHe5�O �m� �h���\jR++}nU�.�	�#Ks	a}G�`�2�6_3G����--锃�c�� ��h�Sǀ�BDt��3[uۚnȦ��,�r4�U�r�2%q}�����NNZ��*��9�ٱ�v�P:��:��8�ߑ=���O��d�O�)w�\ʪ��G�Sǆ��-��8��@�3����u|�tL�35��(p�i�m;�n�.��p�ΙW��.����|�°�:�<6��Lw5$#�a*��!1m�C6J��J�������8�j�����
�m�c�młNb�D���u��r�j�J9[�ذ�b::�9 2�O�P;�ݑm�k˖|���y%nۇ�Z�M߀s�m�p����o(�i鮫!q.�h}���F7�[* &�_�����V˃]�/X-ټ�F@K�ds��<y)�-wlݳ�HU<��#�+C6�Z~fi?M�l���e+� �&�8�8�;�U
�w����˚��	@��v���5�<���Xh�6aK������&] '�@<8�u��L�k챣��;�S����<��*�G�e�m�5, -2q}خ<	� 3`���(�~�5�'�|��1dJG,q_�Վն;�i�����U)	`������.7�_�]OQ<x�[d�l�n˔�������۩i��lG���߁��xpz�!f �{��KF�*�����g��6@���J:��*�|\3����
�KJ��w(����?�����貪���7�I�}w�\�/����Ƃ�]�\�t�KX�Ҵ��g��5�ߟ>������C�6�E��,����۽gP�g�z����DR;�����
N�ș��u�w1�>�):��-�è&�di�`,�7i|������4 �3t@yMv/�����ʡ��7��k��m���FS֚J�� ��3������y���R�[9���8� ���`����%�����F�'����}��[�I�?Ԓg8֧W�{�)�e���c`��-���Q�"9�C�j16'h{o���F��.���6�^��E�{�S?�!%��2+�ة?5��6N�q��<a�F�ES��<�ҕ?���:�>��8D�%7������F��y�y����s>_x�m��$��i�
��;�L�qo����w|�z��Ma�1+u��Zg�,:�>L��<���X]�gl��n)̂�� u4�(t(�����P��yʍ�����0��u�)t-��Zڿ�q�0`��F��j���U�fn 0;���h��o�V��.�W����թ�E��dEG'[�\�Y_��=��ssF*W�Eϕ�)����9l�/#��!q�,m	Y���R��_K7����w��{r��6���E3���bAR����V��*�Ҷ�7(̓2��ub��;r���QSj�)Xv�9�,��
'xQ��LFp���X�2�!'���݊��Jf�E���v[pęZmޤ�^���������Q�-z�Z�d2u鰧t������d��EK���+�Y�/�IkqI�;��הm��~���z��K(�t?�i��gSc�/�ii��ʁ����aj�+�=)-+����i��I��둝��]|�p�w��8�Cv�j&�tw��w�I!c�����ם���7dAV��=J�7�p9 l�PJ���
���� �Nʸ�b�|B�u4����>L<T:��F妟��T������O�5��A	<�'㵥�A�[�Q��e��͠U�R��/5n��?��f��{��cR�@����5ד�}�ݿ���ggRÕ򊊒�}�#��l4�<@�ƹTߐ~�Ƴ��6����{;�OZ�$�	�b��W;ۭ�w�ڔ4��/�*���RC���Z]z�LjL��q$�hO��rһ	��ˏ�~���]8޿K_�����:��s��֘A?��?U�^��j\S�ɗJ�;�7�=�E�OR���;���j�&Z�L�X��׃]���UjH����DꝮ`������X�iѓ��@�ӯ�R@9@�K
�	�P�dny���j�H���ԋ�P�팺X�w�df
!1/�L��X��#�k�d�47]�f>qL������v�ۣJ�&��LJME��F#�����'̇��/��q7�U�Z�N��{�L�����wډi��(��n4�Q�f7���3� ��+��=u� �������HX��\Nc ����o���[I&��/��d�`Ŗcq֨�]���:��`ڵgQ���o���������r�I��RN�=E��`L�8��.��i������#^g�9�|F+�1HH	"�l�la��M؇�$���D6���2��՛�Ŭ����fթ]�Pp�f TN��7��� N�k+�ei㳳���}8���q�
��UM���;XI�E�NzH,K��O���0���o�ާ.����a�];f�%����wg~�c1��y/����e���i�����ru���T������5��$��^��6�ۼ����׸>����e�������M���a-�E5Z�SF�Sˬ�;c��k����BAYQ-���\IzLɽ��e#�R�H�WY>���L0OK�zI��27�]K�i��#�z&�dn��`�dPz]:���{;;�皛�د=�7�V.��E��.�������)���_E����?o^�0y�9��z�^��7���)�_��[O>��۸����Z�fj&����V���"�6������_�U�Z�U����{i��oif���HY�8���-�߰*���Tpctm�|�u�:�W��x�Zj�Y�r�o���������8k���R�>	E;�$?��0��_�a��0����o�a�q�7�̚?DPoB�Z�R�j�q���c`lh{0���Z�p�����w�	u�d���p�3�Qls ��	qOS+[�����f�oQo�.u�z=�$�#���>�$a��R��,+_�($� ӻ�9::8��Ě���&L��؎'�a�� Ur˫W'��*Y�N̦,�8鵅�+ݘ?Z*�ٷ�6�{�늡X���_U+�%���ڸ���2���z��i%�z�6����x>-^�V'ɪ�j�������F9 ��-����m^��9p�}�<��Gw{|t���ς����,���iv&�)�a4"c���2ǧG�WB��z���-y=ė�G�z�[j)0.n$�9�F�P�x����H~6Ǜp=n��o&�rL^�@3�r����F=�RPj�6JUݒ
�@�X!�M��vV�r�+�*��� 7[&+6.���r���I9f�����=z���o�妥P��.�b�_��e�q_��7B���G 6.�3^�CdU��NX����X��� &�]�k��.�C\2g��%�y�䐚�	�C����#���
�c��%�bs�C���LX
�C-��q;���Y{d����1��4��Df^��@�ƨ������O���I�q�����Ac2�&B��4�`s$�9���R��F��[�;�����4-���j����eU�+I˗a�� �C��~��6�>��.F<�n�5�T�g��7$s�m;���w_�4��`��A�"˽�K���a�̇��dܔ^�!��gO}���)8ڄ=�g�x��f ���!R�L=�E*��}\�h牷��ǜ$tO`�:3������X"��A�Hr�u�l̄�e�� � nH�j��W����א�	�xD�m74?� �Ш�tb�a�7v��(a�賀��sj�8N }u<%W:Wki��7$w܍gy~�n���7S�|T��?m��Vn *��`:8q/�M�2�`����(O������t`��oG{�5��_�����~9>|{���l�o��&�:�����u.^y?���urzq��������;'�oO������oG�t�էO?��cC7��ƓW/Z���d6�{���7T3���n/	��n�f�� y"�6��ݐ��� Ȃ#��B@\�� 8�N��lpҀ��ц��	���H��`xN��.z�U�t!�Щ�,����[��=�s�g���G�fZ�R�I4�Qg.x�-��I�,^�o�F��Ӈݖr�����_~|���b��G��������'뗱�����99>��a�ӻ�o���qx��/W�d��׾xux��:���o�2�l�n�~0��y��~����h�,E�0��T"[n�_H
�&0OwP���D����[�0cޕ.��'�K��-cd��.3%ȼ�t��g�;����/]^�R7�˱;����%^���P^���G�Aҿ��}����+�y��2�� �[��!�x9w�b�=8�d�4������]5{^gx��da,��B�'`��@byf�O��oC��ۓo?]3�ݝ�Xp�c(fb���*}�ӭ���JR��'�9{T���U�*_�*���*�"���/�b���}s6 ��7��1�����p��`��0���� #���k"{�'O�H��d�ҫ�O�j ���б���'sCU� ݩ�(b���;�R��#��%�g��đ�i0���H�{0%C� <�E���4`MxJc��[���nH�'�('���aHQ
���(�����
~M���]`�h]
�mZ�T<c8�������\�ĮQRϛ�z+�D<TL�P������g���!�+jSm*M�o���2�W�W��=��z��;J���{I ��>u�)�3~l,��M�Qr�@��S��<vuH�]Ekwre{���bjf.�h����Ҝ��;�ݺKȧ�m����ͣ�����aD��y��B�>Ʀ����_Z�������2�����R�o�3��s�;q����{�jLJ��`).:�L�"���"������c�*����Ͻャ��܇Ӱ ���h>��D����֏����W:\�Z��1��Q�8>�w�<M�W����T��I�5���� ���P�T�B�grU��fs5���E9v��p��R�v��;��@�ӍT��t��oV��+I��'�9+���	Y�Ke���?�
�9����eQ|aGn�c����x�7,��͌l�E�+?�5S>kx_ZlnF-�`�T&��?�l ��((��[u�Q�Gu�\tQ	�)�n��@�@p�DFX�N�*I��}�J����ك
� ��_�Qt�3x,�.��4&)�0���������ۍ��.����n�����D�����ܴ\��b�4��ﲲ��Ǚa��G_E�T�w���*ɲ�Ej�����}Q����T��+�b�y�+s���,�e�1���`^	���,(랓��d�g9 Q:�#������>M]������_Ut#����լ��W�*�_��5������ i��H!�W�NE6�Ɗ�sĢJ5�aǹ�S���A��cK�|�=��J�T<��>�t}���sӨ;] .�������P�CQ���o%�:��>��������^K#��� �6S~�s(pTM&Q�u����?�B��38��'�1ɘ���9��g�7s �qBp~ru�L0GU�qw�cuw��q|K �`����w7wݻ��f�\���=^t�����)D��dNAXB$��;�y���D�h➧�8T�}w�j�Sˈ�0}�ǗEew\=�,w2@�c���
����y���'JF�=��jVj��X���Ze���$��;dn��݂�[j�3�����л}���NP�t�bP��O�}��.�R4��)L�ݻ9'5��Z�j�h���]T����g�T	�E:�82�_{tm�Ǩ�ja&>�-�ϝ�2Xb(�9L�My�k>^�5P(�Hy���fʨ�eԴGW<*^�MQ,x�sX���I��_��t�x����,���\E6]�48c�����8����{��1_����	��o�6s�b�au2r�K��O��z�Z�	����N��zޫe�~��|Ew<��L�'/5N≀�&�h�%^v�W����y�O])��h���+�o���x�+����h��W���S�OY&��܂�S���������El�G��L� U��*Ra������ ,�� ������W��JR���g���������w��O�5�붳B��+���#߆��-�~�d�'Kh�e�߉,A���#�A���V���ۈ�%+?(9ΙYs(��l@�;��o��.��Z
Z��ZZ̡�c\(t�ΦD�=JY��:j��S*G$����Ĉ[Ȕ�C�)�J���e�*};�Z����ǒ�4���Q��Y��+I������ �-��l�i���.�DŸ�C�2xP�p�P꽡 �ԝC�A~�>V�9�8�d��X8�O��R^����;8���~Tcm 5	�A���l�=��,S�}��L���Mqw�I�����\�����n|��:d��ȓ�"�'֭1��g)0�����!�'"��?��%�Kݮ��W ���l �gAc�%��^��,̆�Ȥ���k5�+��Ж��K /[�Zq�fa��+`{6�.�_�]���ń��!��c� |��Ra���Qz3��\���Q7�@�|H�X�c��Q(��/�g6�|��9�"ͩ�������r�%]I@��.�V`+�(����O��i0;�n����w�q�y�5�$�pk�My�y��l��f��\`�1���-7qiS���e�������������OӍ�Y��J�wE�z����һ~��[�����쫷���A���y ��Ysr�c��f����,Ɋ��Z���"-��̳|�c�8�{7���ãl�<�_���3{�.�^Ư�����ڔ��7����Y�vV����7��=hM�3y��I�G����;���<:�}���ԅZM^�9 �ӵ�כ��4��ںT�����՟� &xas5 <�@k&+-V-l�)�K��^<���OC���y���N4jɲRW�Q\��ʽޞP_M���y�Iﺱ�q`i�n=�8F���ֳ� ��&S��Cv�u9�����r��]��a<ͅ� iqv�~��aZ<��|i��d5��t�ޤ�S
�/-�<e�)�3�U99x�׋�ˡ��<e��8��L�0��4��uJ�UK��Z�)"Bf�媊8S���J�gQ�tֺ�yZW��O�姢�����۶q�ES��O��s%��������U�?�����]��ۗ����n���������)Q�)/:�6�Z�����'�m9����ji�dA���U��+I���;����l�o@�bl{���8���A�oH��򦕐��JQ�iR�g���PA/��;Iz1�D��hBgĽT�F�g*򕷠.h!/����u���wu���'��Ȱ��b<���, � g>����@ 0�7&%�����"[:Cj�;�����D�k���U�x̅��,�U��[���T��/2�G��F��:�H�?�^S��d<�y��lC���)gVTt ��h@�S.����J�3�3��	�n#ѧ�Y4�Êf�5��j�	3+�q���1���IF����BE�@��q7��djkS���~��6~B��90`���(p�Q�g��dn��@D��#҈�� B�|���81�����`�a�.�D��;�q�nH����2=�1�)��3�	6'B�](��J��A=r$8�ߛ9�f�A��GF� ڣ_���ץ���7�@�$T��K�[{k!�8�'PZj�K7�R������	�M�QV��i���y��;ܨ?��v@"^����4�f[������T�z�-��ϰ�Sn�!�~'�.0��m!G���x�L<N�1N�4ފ�z���2���S������C/���N6l~�r��!�f��<�/R���T��5�'��� Pm1= ��"�_��N�B�_�����QTˬ��U���υ|���Y�'_C8�)�\�E���|�\���\�m����_=���������뱫>��|Ƒ\��ɢ�E����6F�k��򔵰9�0lFn�.%}�ی�8�HzK�0Qh���Mڼ�`_&����ͻt�Ɔ�s{4�6�5�{9����dƼ͜�H���C��x�a����i�g1�-9(�R;Iy1 A���x	�p���ν�xh!��%.��w�`��X���[�˺wĠ%�{O:��k�yj�p���F8!��m4�z.�')ζ=�����xv8�nh�qMu����A���;&�d���:��ɯO��"��=b��U�@�Ȅӳ�Gƃ��]�O*����%J�'h�1�<���P: $6@� F�3�Q�ᓸ'�~�l(�N��=fQ��{aC�>�@!�)�}3GZ�gqő�Q<˞�J�5 �e��/^�&�8�:�tn��:��S���g [ͦp\�3út�}4�"A��5B��n�Q�¨�G���`���,q�I<G���|���C�;����G�����ρ{�#g���Qf`X��A���+;��|#���,xt9�;�w�\Ӽ��́��ؤ f�cb�&����_����p/�aH�/,0����H���c��Q�R��׭�x�O�M������V�a\.T�������i�굨����Xp��ZV���`��SS���g����/7 ��z�^�3���ƼR��nPwR�����U)vް�Ԉ�/8ch1�?l���,�f�b/M�}�ZBF�ڃqFC�PnZUtMA����c�I�Azut�����x��X�3ΐ�
��rBNG����0ě�����жk�O�����!��}��v�\`qN9b�t�ۯ{;�A�A'����F��n<�ԗt�;�H�\r%���`��p�μ��n�W,[� ���=��x�,8�KQ��ߴ,8��0��iiԒ�̊�������^�Qa�����lBIs&�|D|.�3e�B>�/ �!PsY>z~��?����/��,�����
��3� ���*R%�U������}S~�D�/@�e��4-����R����h�n���nɕ����o�jKt{vԇ��^Vt�^��2!��,ɟ�F#�R�S��l�σ�V� ˒ґ���а�	h�H�P��DjD��7{{R���o��Th�'��4���~�g��ԙ��!L�p�N黥���IgG^W׵u}�X7�7O��[G;�w��7��t1�`%S��t��ϝΩ��,���}*UiU)��0���(��C�})m,���D��u�����bU�+I�&�?�  �W����ܐ
h%C���%%;�r�d�ɿ�i�VS��JS�3�o��?��}�5�ԍʬ!Lb8��~���(vс�`Q�ad�+��47'���RL��ؼQO�-�Nféf�b�r�z�)�鳦��}�=H5�֥�4 �;�K�P��񑱤i�aԬ=Δ��p�a�_�y#�=�y��N��.�f�5:->L��V��{��g5K(]���*��p���p*�~+����лH�*���=�xH+-Ln9(Y	
��n��گH?~�m���P�0:����;{��1�.��i��T�6��L�R�WN��_NH7Q 5T�E[��+ܱ��;�2�����vm�#q)���(��#���G_k�p0))�,-"�X�xxF�Y�#nW��43��w0�&��+�7�t?��3���G3'!�љ"ދ���l�Nn<5���Y��]P�]�ջ:}�"�/�e������i���JR��#�#fp��^*�"�M��A�=��z���_���ѥT+L#��1�&��?�|l�;O�('pkF�Ė|)�0�.��l��>���.��`lեDm�3�����&�����07pC&� �
-<	f#O��Ҙ���=����Z���jh���@l����N���D"�&̲�D����4@l�6�OH��"q���o�t�Z����pDZF�����u���o�����e�x�`�V�0á#�萙Z��hsko�^��r���p!���#��Vq�Z3Ynٓ	�	d0�-� ˤ0a�W:� ��<�, C@����t�ד�����q�@K<��>
]K\���_ܙV�:�x��7�����x1LVP\�b�0�� f'�u6�����D������@S���}��������	�XZ4~N��ɦ��zN(ɚ�f|�K�Pk�1��[W�Cގ��֐�J#���
�%F8�,m	8^K��-���W��wOY����4�,�����h��W-]35����������������jG$���@�k�[�8��4e��گ�v�w�v�~��v�����s�z������3#��7��o��ۣ��V��R���Dџ���2�$��n�2���\��U�J����Y���hR:�g1����ہ|��s<���\�f;�K/����jt�O5�/���v0��������t��|d�{ o�b��d�n6����&���Q��=��%v����������ޟl��hI��"G�&��%]�_S��K���漴3g�i�@9E��콃�ͽ/�ii��ʁ����x&G	eOJ�
F�	aZ2p�.�zd�?���ɸ ��=�z �cY3ɦ���?�[N
Kl쿼�xu�!�ۻG��&�_�E@�ʡ�`�'��m V� v��\�T
'��7�g1|&p�a���ҹL6�&Rޛm�+7*��/?u�����p��זJy�p{�[��vO�mR|�S��!^������I���MV2�֛��C�UW?㷃O����I�U�]��z��1l�%�N�B�vN���׺H���&��X��)�[�X
r3�pGKA.�J�O����p4�P�O���ե�&L�)�L]����̝�|�ai�L!a����`�]��F�O4NX.�*��X�����	M�,���- C{{ pv���6{$}�grR��]���|��F��kϢ )P�I�O�Q4M�B�U-��@'�<��D�]�1�.)�bKB8���l�}V��j�|52p'iur��ߺ��S2� !JJ
%�fG�N1q>�k��� ��l'�*�s6ah1K�b�πΜv�Ψ�Q���C׌��R⨑G��b���BsC��NBŞ�����tr5;;���q������̍NC�EY̝4���]N�I�%�Ʌ������HL���U�Y[�
�7{�����(�)�.��E���[��U���gi8Fo%�������&�^��,a�Խ�C���}������`��k��_����'��kZ��W���߼�W����50�~u|]�n��~|��ůq{&I���������7�{��؟Ɇ\��^u��?���>c�����0������_EzLI>;R�Y�g���9�9��*����<�0
2�ii^/��Y&u��d,S��|27C1�x�H���t���l�vv�����k���M����o��|�w�_�����aQ�_@����T��������ϱ )g�oa����!T��ǘ�>�4�+��4���\�,8�5+��	� ��[��U��*R���������[� ��� ��$�D<�k�p���l����}��ݿӏ���_���U���h��?���@�®��w���x�s?�?�{p�����'��:�`h����*M�u�����Y� �[����yixȊ�s6�n��A��	&�*G ��޵*M	�����<0�"��w@j� N�}�˛��c���b���,E����$=���zғ�����려��K��~X�Г=���� D��B�q�V$�>�E��X���*��ޜ2xc	(At����s��A1_�o�/�n̓E��.,P4@L_�?���R�YB|.N�8�W����莻�D��`�P�}.Vϵ䎶�q�&�I g�\��� m�W�*U�JU�R��T�*U�JU�R��T�*U�JU�R��T�*U�JU�R��T�*U�JU�R��T�*}c��N}H� � 