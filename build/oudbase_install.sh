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
VERSION=1.0.0
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
� ��Z ��zɑ(迮�HCl�Ԁ ��$�%DBmކ���m��P �TaP )Z���Ǿ��;�>�y��$��U@J��m�0�QȊ̌��{F������YYYy�����M�weu����j��n4�n�7��Fc�������~��$�P�4����zs~�y��I>mX�t�=��M�Y-��>��������jccssm�}mu�wj�+��������PGh�Y?������v�[j�����㋰g�����O�8��L�D� �d���N��Q:����;'K��I�G�(�&�0�"����56V��A8������:��'�ƃ0�����aT�ϖ�6�؜N��X~<�D�0Q�Q<��beK*�g�����DP�Cx�Ս'�텽0�l���<�>�b��۷� �&��E��iRh��fG��(�"��hF�t��h�&�:���~����t"�3Ta���d��Nڍ�$��hN���À��a���4�����U�\��4�E���Ӊ:}��]�O4�,+�����(۪�ϡ崍ة3�2dq@���^܉=��G{�k������O�q/���|͢H�� �Mӆ5��I�/���f<LǈB�sN�%��CK�է�.,Xv�]V���a�w��K�Eh���9;><<=�9x������\
���.�����5��tUڻ�qn��t0Qo��4ʾ`B���������Fm%�9l�v�VN�_�*ꖟ{@�a{���G8E�c ��Ó��ʋ���g����m؍@3��N��w�N������H�	�����������O�xZ�O��
=|���/|�\���k���y|z����i?��7�T!,5,��G��k��&�/|�]/1�/<���ݽ���q���)l�O�!��Z�������.E|�J2�Ӥ�D�%����v��d\�u�G�K�c�����h^q�;���P!5=�I��sU�=xq����j~�\�_��r���ݽ{ 4q��z��w���Qtw����#�������������e�N���	ʉ!�y�6�����Kvʌ��e�w�Q�=��q4��K3 8�M�H�[��<݉�Q�x�~��l�3����9<Q#yD�d�ۅe�<Q�"����Kω=����w���5��{�GxظV����~z��>	�4�Q�4��LA�Q������s4 ����8^��+�����:�sYW������GM�!�.������ť�#�s����)��w[�ˈ�>����#J��
6Cr����e�v�_�	�5���AWV�J@r�I̷�@��5��UYR�tw�ut��5U���~X�n��]��W[��o}wRYz��y��x���/�t��?��ÿ`�^�������5��|�KQv���@C
����JԀ�f�M��0�-����ގ	� 7QE�2�q9t��y��W���f����Y?�M̷�>�{5v�/���z]|���ro�]���:3-ζ�&Q�7��={V6�0������ٰHW �R�����`M��C<�
��M��Dy�	Kn ;6�W���E�
���=���4�
�[0M�Z����`��p�N������嬦N`sMI�!{�c�;���jn���BV�(ڗn�F��VBj�h�I:�E�P��	y�|~��+�r���k���y�$�8@��k�OM��0��j��|�� o��A� L�i����C�'��aW�[���ȣ^Ӄt���8ߓ�}���L,����~k<�p��E���8~�Vw<M�_�=�I��0���~�n��P�n��giVE-ۥ���V��o2P�-� I"f��`>�Hf�!�R�"fKxĶqK|�F;vp��:7��G.���1c�s���[�g�~/w��/�,�?O����$T���p0H�m������}�^&<���26֎�����t�P�#T�yϛW�r2z W�ջ�E=���=�(�J�]�K,��4Bo+�tv�����;��\�7�pIʺq�:KX��5dȄ�@�v�/�Ƴ�N��$������� �i�pt�<�HaaaG��7�
�J���J�SL	=l�������*������0�n/V*0c����I������j������kczþ�)��_{PSؤ�pP�H!4�e�</P'@��P�Lq&�a���Ԭ��0�n%���X	XzZգI���;��P+S�#.ҥ�8�o�9�m`���J��б�;�n���hcڿ�ep�a�E�w��'�p�*���W*h���,�������� >�r��Hu���%��7ў���5B�m��$����)n>�"���Q8b��7��!y[�/⭝���Z[c�A�Q��5<q�����WQp���ҝ��%��2�����'Aw�{�f��Y�pv3ڎ��q�how�y���¨ZK>U�C����Zx��/��������r(�mmYXԑ]m�6<�,<B=SfÞ�c#�F��_���'EGE(�A9�C�0�H?��eV���U@ ��)i�R.��0+���S�>C��|�h�q# .#@����^`Q�n-WJ=��A	���܇ `������5��"���I������)V�D�A�csi��i���Q���8�����I�.��&���8E�Ie8Rx�8��9���cwN�t��p2��	D��'�<��4���:��7��B%a�gԓ-�3��a�DN�{Eb�}9V���_����.%�[?� ������V�|8L��51À��^
��$�0A�~����IV��U�������s�UZm9 K?�^ru�B��nL�'!��h|��މ�&��*�h:�~��D�����f!�ځ���]t��\l%�n�w4�X3�/fb�N164�b4��v�G��#H}�0c)��1+���/g��X/߫��[/w>�<��K�߁�����<�}ypx�����ͬ�j��V��6��1�A9��*>z��}����gu�&���Ə[<x�$pV��kV|$����+��h�޾3ʼ��`u6M��%*.S����y_;��6~Z9�e��:w�:���]]�����|v�cg%+����<�^R!��wo�T��[8:����{�
��r,�����(�J�j��4kYK�韱�뫾���e�<������5p?lU��^����t�i������{j�[@���j)�����o�z��������q��NI���?:����~���5�|l��*�7���*�o�߿Q���p�*�ߒ���cr��}K��O���N��,�ON��U���_����%��H
_�~]H�=y����{g����ӭ�$������1�GDbs�Iٌ��3o��@�ߢ��o�Ϳj~�����-�Y}�o����-�YX䯟�<'���|�����|�oyƟ�g|G9��EF�����Gh�:x�Wi�n�e��M���$I��@o� ��j�8 ~z�#[����[�V���LƓɇCh�x�������ج��Z���K_-�N���S���ֶ�U�8��z7I���]�ɽ�s�8R�u�-���1(�b�Tg�5�觉�=:�⌆���r�|���QICB����	��9/�B�������/��F� ᰵT�E�����̮�5!<!����d�3� ݣQNR|G��<m^�����4��Z;kK錭Y�iV���%��0���Q[�c��ڃw�w��ߥw8�ڃ���F�����kD��M� �g��V���Y4���J��.���@����
�oIؾ�I�Kb�q�[�R�6;�_�w� ���siB֧�̞+@��1�t�RL8�j�:��usR�yyF�ߏ���,]��2s\�1G��F=����v��_�; T�����bp$�e�%Y*�n˩���r��w�7CU~����ϲ2��������:[͒�ïJ�;�������W�z]#S��}��H���'�n���~	oX�g���ڜ��g��o��{^k���ól2F%ig�ٲn-���鄹iw9ju�t��?��������~��T�H����k��J:����ae�O1��{�nq�u���w��J� �~�ܶ�÷%�����vV���|��l�^��33�kV�]г�7����,�	��;�_PHk�p����D��u��<��f^^�ل&A7�ۭ�
o�_6L�`sq��p((�-d�3�y�^�����}7��@�-~A�{H�a��3&Dz��Y�����B��݆:Y���s&�����b *7=�8��nK8��P$�mfb��'gQ���e@>�匼*��[-���<7\A±&H�
�����ǿ5�|�P�>����K6�e�3�
�$��Q7�~��yۿ@bu�ˤ
꧞�e��e4Ɣ��[�g��[�0�\|���F�LAR9B�k���������/,.]2~r~�ܚ
��\���B���[���}t�'R�t����m�;���T�wu}�[������������������-��:�s����-���f���p�3z��w�	���=g�pz5����ZGO�?� ;�����6��g�h�G�(�>�L����e��-��u�+�� <����Ϝ�:Q�#��맾������nTL.�=�>n�N�{�Rh?�j��Rh����BK}|K���B�-�v�)��V��rh���~^��v��o��s�}�}����O��z��?��^'[��p��5�^'`���4w��ȉ��Z�ߒ<��%y~K��'N��-�<�j���Z�#�c��:�|�%�@��+�|u$��Hm��E�3�cN�������*!W|p�z{��������sy]Y
�v�`؆��1p��D�?on�����I(�;=�N�%彥�CS�^�� =�b��v%/�K�S�3.M�D�������0 
Rq:>�x�@vGH��)}K�U_�v��Z��&��+$�z��;�XM��җU]��b�$ʡ,P�-��ɧײ��oo���E:*K=x��ӑ7����m�[��6+�����R�[fw����l��\�z��iҋ��2�bĂ�N�M;nX�|��N�68��i��69�;�yۇ/ԳY��aj���g�0���w19�>����Snh�0�z��:��;�@u�N����_���Xn�V�P8&�䟍��,<�aY�[���'�N~^��?!�V����g��ޜ�[���&��)�"�7�n7��Sr:!�A"]��~��A��VO��Ab�$�{s�	��ҽK�(��0\��6}i���I�Y��Z���ě#3��q��S�S����ZQA*��������2�ex�2�?��['�~���x7�|�>��o�?�X�����Jcm}��-����|���m�y����~��LG�@j�ۣ�ͅ;$�e���e�K��E��pc0���_�ID��R&�g��W��t���t��"s�lM��ŪxuH�\}�u�˵�x.��͓Wg'����[?��*f^�e�Xڧty�б�
Z2�`lvlzjY)�� �'jt�������t�15� �}�T}�v�����|�x��M�ѥ�s8(q�W�3�܈d�`�,�i�h��Û5v��0�*�d_W�6��;�X��[y�i����'�g;���z�vSd~C0R��{n+:�<��s )���i��!nM:3[�}��<��괵��<m�H[��k�ܾqt|��z�ԝ�h�v����cG�~ Mz���jm�֨o+4|��vNc���Q���i���9uљT	� qpO]��(r�J\��Y/���K�N?�
����?��ֲ�q}��%Ss�XO-X�bV[��S73��T�M��M��p%P��w��H�q-jw�4���9}i"&$����{({x�UG�����\x;�7:;Ԓ˻����@��X��(�ih=�_�bc�Om���2��Q�v���p5c`h4���}��M��Gm�b����s��7�;s�=�����f�E���-����_¦���{���ne�a��ݥ����N�v�*�'�����v��|i��u:�s�MSwi����~/BF-r=���~�rk�����3N��$D�7��{@�)��3�ޢ;� �:p2�R�r�͎NO�2{��=��(x�"%�&��Y�!�Liua��ER�v�K-���<�%�k�ˆ���W�P��T���nF�/�oM��D5������f����+�yD���8��쵑�M���P�����Cs/RG��Wh���q6qh+Ż/cM���}	��ֵZD��=�W7ߴv�8�1�s�d|�;�l�b�A`	��%W=A�)�`_�^.0 S9���W>#�8B�R6A�:zK�F+��.������c�`�$�'��v(:yI��R*��nJ���\���q�JT|hr����krK����ږ�����&F�!�ߔ�	K|E7m�$j��;h��3��9�6BH)u��'a��+�i3���⭓:w�&��͵۬��"ԏ�D�A��p��vio�In�%�͵4Qw���ج�����篶���1�1"{�9)�Nގ(M3�1�������1KK�7�̜u(�����OO}��lV���I�����PBE����A��jX�3��	*���*^֦�Tj~�~N�(���I�0��ahVE�.q����2�'��$Ӷ}S�mnԗf�:�!T�p�
21xܱ�����N�R4Ws6J	�5�s���Y�+��)gVfb6�P��+�����'��,z�tZ�\:�k#��j)Ү�f%Ϩ�9�,��G`�T^�m	�{Md9u{��G<� ?�[����D.��kJ�5�Z�� T�Q�a�<<1�h&e�/̜�y� [��Q��o>k�ebم� }�#T��W��aL'��?�é?�	ή��p-�t`�L@E���,��k<�tMdp̖wv����J�ޫ�� E!G���`�'�Sد ��l�?\�� Y����'+��3.d��1V��7Ɲ�V�6��vaq~�����'�0�� ]�)7p�*��q��.��d)�F���1����8��3����6���5
�,����]Ao92�f�
���/���..X,/��R���<Yz[9Z���N�kH{����{2��1轝�:B����`��NMO������d�мI֥��Qx��I����ǭ�O�׿�Lo����Y�6�t)�SV��u')a��D�5�����H��Y���'�M�tt~��;/����(6]�)�U21\��kN�.=W�=O(�ݩ��M��<νѩ���ײO�7>f���=�.H��sB��ic��l_��!��E����/7���K����B
�|`kK���B_�rs6�O��i(%�un��5#�����я�^�b������ �M\���?�ɤ����������M�s����X���"E���TN��}�����Z�E"1!cW���X!혾v_~Mn��G�gi�b!k��ͺ�� ��+05�p�B���N�1��u�J���̃��݃������)GMg���O?�s�v��_"!Nc�?�§H�;��'�x�K�;�J�-g�p����w9��y_��n����
����]C��Ę����QʁS�*�����W�����OȚ{������x���v�҉�Bw�����9r�W3O�y�F&S��w�h7��4� ���a"~|�$�O5u4���}@*��Ƚ�T<̗+��|-��g�kΤx��FP��I�vs)����tg _�ҡ�B��rK����?��iƟ�0,��R��EU�W�?�Ń��Dݯ���tz�+A�IB*G�Z��B}t_��
�l��;_�hS���Zb-`0ĳgtυ>������Ă�z<��]��
�t�?w�կ��b�=?�J�cޚ���{�����?�̻ʊgl�0%��R�;�$�F`���Ǳ?����4�=.o��d�.l���9�-��G�'�}�؃��|��8Z�L���3|Ĺ��nǂ�.���;��W��y����F��Zp�~,����ĝ�;� �gڞ����@+�% ��e��GEF6�Q%�O|������l���C�9V�z��z�ݻ�#�Qo:�r(p���ւ���;���i&ư����f ���ш�=�5�"���J`r6��6���$s�i�����x~�%�>��+�����SC�x ���*�B���1�7L�t�_�LYǣ��jÃ,���%��
g��-�{��z�{@4u��YʦN��eH'�i乾3PA��
��A����E�e�Ui.�_���W�c}3<���e�~Q��MT������eX<r���@�ɭ?������#����ԓ�|Bl�~�>O������~4(��x��D��r�����^-�ry���h��:x�e��-X�x^����� L�U{
D�?_N��}��K�%�y�%���|�:i�_ޜr�K���\s/F�4����;���?,�<�^g�秡�皻gQ�����7������}x�~�=o*O}GD�'G�yo8ϋ������|NW����N��/{�dj(�U��T�;%M���BS~^�H�2����9�������"�n�� ������>��]�`��y��.$.-�HaQ9��n�!غ��װI׸�ٽ��]�EW/Yr@��%[/�Ȕ������k�a.�H ��|��t�M�[yd@�+�7@j	����z�X��G��g,�}Dfx|6g!��_�-~eC���N��֙%D60��ы�����pH�|��/Bd��|r�c*�L��=�m�I�R����4B��	��F���^�ڒ�r*Tso�i��S{ʋ�QHjt�X{��t�~���R�%G+��a�P:,:��=����"CY0K�w���%P>�_[�>�����J���+%1���4�|T?��K�A͐�*s���U�F����?�/*��ܣ��ao����ohT��eFO��� �|�ɏ�s`��L�>4'�_������W�rR׮��p#r�:� X��}i����z��LҸ�g�7)����9��е7��po7��Kw4��t8L�#`fO�)�#�(I/��q��r�Rq�;�ǲy�[��e�es��\�W���>���j�I�F{$HL���m���M����Bf2��kjqu��e��Y$8Ő��;���(��P͠�]F��RWY"�ۤ�\8�}��W��r[Z��V���d�X���g!m�Μh=�b���A\���j�S@�"��Aߤoѧ�!����=Ԁ& @p�����p|�,JU��B�Xe
N�d�iB-^���pܕ5�Oyz�p8�lw��U�#����n��I����w~�t[D\nc7!��0�2�*`%;:���|t�l5|A*B��W���.ror��[{Z�%X"��4ʰ�w�)� jv&ǒ���;wV��$����Y����g'�ǷI��Ơ�<�<p�#��N���І��z��I�7���{Iǯox-��+��^ژ�8{ëw� ��$L/���D�"�~�S#7y�� ;+D�9	s�:.����x���ϞJI�M��:
}�ש�w�*G.�΋��?Hlͼ5砑>����
�-,j%���'��U���p��
����
�����HA����5����=��C��gI��PV����wA4���cUR3j�J��)��� J��&Pfr������%�oY�%��g�x/�H�rT5o�����`=[��4�3#��G��}�;@�Dk�k�����#@ێ���S^�e.���2����'�M���'+?���������;dο	��]������<5�Jc��T�0z_wc��.
T�H���1��;�u��)5T���-^��>�]���Y/b!��
ƭqZ,iT�х����Lqw��ЕD7���V'����@?��Bϋ�/�n�]����,���H��l����~SV��-����xǺ���X`���7�k3���f����d˟Ӗ[R~��?�r����`���~s��b�Ԣv��Q�Z���U��=�2��%H��HsKS��h0�X���d49X7*��E�&޹���&�^�V�*���)wu��ƀzP�1ޙ��n@i��S��<�u��>1I4=vk��^�2ɟWw1�6�0)�ow�N�OW(�䀲S֍q�sp?;Z_�~XWW�M�qO̙�c��l�Wӎ�{i�n=�
�����dQ���C_��y�Qָ�Ui1."��|�`�ϼ���t�N֝� A��OݴS��wLͿ�������6W6�7�J���������������p��v�['���]�>c�+������n<\�v�ۯ�Q%������A븹��^?�PB"�$#������Z}��<M"�
� �GW���?Q��K�P�G�:I{�K, �����IU`����^J"��^-�ן�u��0� ����a<A���+�X�x63nc<ڶjh#,��y���/�R@�S��U�9e3c���eԭ��K��qA��V����(Qr���m�M_5�pC�΢�J#DT�!d8*���I�2A�y��t'�V&W��u��wGx�����Tg�e�9ֿ��d�Fx^�D�@���!q&!i[<��_�K/ЛT�ɍ3��I�ty�Χ�8��Q�Ǡ�#&HJ#�?ĺ'��p��<I�AE��ѭO��.M �z�f 	����DsHo�EɃ9s2(O����`�	�%�1��X�慅�y5}�G�vJ���o_�C����C:����!�?�)�)Q�[�_F�E��� �x���o�w�Q�.V�e��=��`4��:����Fy���Z@�&�W������0>�(ˍ)#��!�{ R]�Y�j��4���DY�݈�^�X<mZz1�1}v⼊m26����0���$�h�ߜ%,��cb��ۥT�,���3�W'��D�Fl/��H"��h]P�2R���AE��5�I0L~�f��'ڝ����u��X���h<	)�dq;ē�/��F���b����=�@ �n�C��*a�3��K�Eh���x�߇p8 �y#Ȧ����>���{��nՋd�C<m�� �}rO�L �I�3��d\Y�����P����tU�:pH��e��4�\̠�>�Q�
ȭLe4ī��	��5���S$�0%f�G{e���p���	e[�bcI���	����oq��W� ��"���1����Mw���I݌d��ݪ�� �N�QŬ:Wiֳ���fy��t���4a���c�xv�{�Wb�x�9FYrE�@���K�;n�1��N�ikl��p^<��C���
�vD1~Ořɮ��*�b�Ϡ3�\��	'��.ŗ�(�f�+�<$wd1�`�#��ЍX�K��#��y���ǇR	��x��i�67�w��`���W��OM�a2�� �`��R�2(��(3Q}��m ���D��" 	c� �^_�$Y	GN�pf�e*�R��s��&����["�t�c��Qg��12�^DV�@{�NA#��-d&q�2yG�!���t�WϢh�&����I>k��X���@����`$)b�iX�8�X��^S�^z�5:�@33D���l�F/�&,�.!�\�h��.������T�xT L��%����˺��Mquqv�U,A��JK+f79��J��8��UU�
�fۈ�I��f�'�i*�y	��g�{X�6�8�H��n vSg�Y	yWp�D=���9iTg�G�L��\���D4i&���xF����Es�����"�����z�!�����B���:���v0u@��+S�&�k�^��jn��`
S�k�	F�]c/��X
B�"wH���@��ڣ۫F�w8|\N	�07/�j̶�N[��'�y���|vvOwN��Jϻ�	�H�WNSa���W�5��fj��X�V�9��Ȼ�A�/���*5t��VY6Ua-@��0F$Mѝ�0{o���G�v��:��<Ф닍�)�g��R�:�&lv�������ȭ@���eZ��Uj*0�+����x�V��o�
�d �c�t��9�n8�m�_(�_��	���Y�ϫ��D�n��T�t���	)�h�%���J�ӏ)u���U &d���Ș�bmW�6HU���B��MU� �ೊ�"�e���ӧ,����G��ɸ��s�\��KdBV�G�
ᤪ�3\�]$�:2���taY��	��8ށ�S��p5�p����k����m��9�y��4�TF��_Q�/�@�ّ�	$�`
�����#�4Y �omw�
xB�&?Qރ�vVP���R,��qL&-��6?`�\F��Y	��E�'wܧ��EK0S �%�"���5�
�Q��V
`a�t���.>�Hr�RAh�	���3�	�Y���E�6�lp�x!�lb����z Z��, �h�X��R푾~��ʑU��H;`�csW/��XKT ����F\=��(B�����
ӷ%���7vF0�EbsL�4_�N�(+��NB^�EE&���:�6#f�X%�2f-Vx�d��8F^�<�|�p��^�^�H���^�&�jB�4��#b�Vք��i��]�8,�A9݊�h���q��F��$޴����������#V�)������ɿ���ݬlaLP(����#x��P���Q5��c�'������H��;����9���<�Qce!�K�@���9�<��J�ɖv��{Qը�3V �MG�s�#��}g:��m�h��7���������X�)��h�v�6qVa/�]�2o�����Z���pe�F�5�Cdk`d+�BR3&��;��{_��FB|A��\�}x�L~?����*M�[�Kȕ�J P��iN{����/:bX�b�**�����B������M��*-4
�VdRV(�
��BD<��&��FQ��-�B�&��d����F�qxz)X|Vj4@�t���1��S�x�g��($���07� 2��Jd� 3n�*��Ϫ��`�� k�@�J��v�����L`b�C��gC��eF㱓؇ID%H��c�1(u����X��x�v�Ħ�h`��|��v5٩2�>�W��p(^���z,�����*�C�����{?�ە��72'i�J�� ;�"�'�SY��X�9G��M 2�e�2�����oKm-�i-[���~G�0v��@34�D��v����c/h�B��ő$�oS��Q��$��^r�|{�6�1�ô5�7!����ۮhq��ؔC��6���NmĒ�ˤ�C�BT2�{��1��(Z(�Fz�)�+��]2j�v�3r��#[�̽(Z��b�^ww7,�V��=�� Fϸ��jO�g:2	��M���|NQ�n�ED��J�P��G��O�`�a)-Z�c�B�P7p|tkp4�.IݿSl5���&�&�x#߇�yK������yU�qB�2pmH2X�{��GIA93���x��%y��'Ӊ��x~~ ������g�0Q��cZ�i���,�3����o�S���!��1b	�Q�ˉ��i��DV��=뺙2���&k�c��m��D�$�hDi�u��ؙ�]�$|]����70m2�|],��4c���qGq(ypF��_=�lYG��#�d�+�@�,oD(� ̆�]�o�c��DB0�1
�u��#�`'�43>w��Ed��"���	��@�zU���}��@|�8�*md��F�����6��G��=�g�iD];q����=����#A�&����8;L���;ӡ.��e� ��Ǝo�K��``���T��EX%R�|�'�!q�X!'o���kV�N��]�Z���{���Ǽa_ z� ���i��F�{�Ro�P���QN���5b5&�b�����t���0�2�0�ő��m�z�H��L�\v��Gc��FC����G�㘠s`v������h�����Ǜ���/�T��$�IU\��I�� �=��f<�#���J�_�����,a�Ȣ �o� C��x8S�?�LH��^E����q'&��\"��M�<�[�E��;���L(�f""��6H��]���Ev!���8J���	,�oW�%ݤ�۝c�c�2ص��23��¢�ؤ�[�9������f��+�dus)\zb"��g�J��%�n:LA�5 6K<���$���AY�[7�k�d}�����g6���$�ヰb��9L1\d1F��&�=@�VO.L̦+�{ءR8��zh�LJ�9��m�\;�+�s{B�8��曓>Q��V��f��f!9���\#E��oF�"荀p8?!��(i��v���BC�p�m_�v��q�9�s=�EU���c��ܱh��K�{�N1�j5���"�]/�X	sE���\A���p��W����� ®'c)Q�,}e@,~I	)��S��@�D۟�E��}�WfN��p%5�n+�"0��,V!��d6��t@�H#!Tfl��L��ds��K"���X'Ή���zR3D_"�C]��p�i�E��$m�,�2L&:)�Y@�ݏ9Qo��F�Q	왈�����b�I%Y�UY��p�`�	�ڜ�t�.xr)RB�g� cA=���m0��Zu'�+��[g�W*��	T��(S#��6u��:�K����.�b��1��>;��"~5tj[����'��/y�+ߓL�x�%-���R�3{a�M h�A��✾�~xv]�ס�~�s��Fx��9����Pd��֞p��'/��St���``m����v밺1��
�㝯����.��/���+ʆ�i�1!��#�*�������#Ac�6�#�(��O2'JmE��<�.TV�H�rV�S�������#`	��P�1�q}1zِ��SB&[��Q���gd}�����-�|��l���
�Φ+S@Yq�g�,�%%c#�Vf���3�����Y�D(�y��\gy���)��`���m�_ΙN��= mHW��^�*#XҼȢ�O;-Jht�J��p&��+1�(w��X[	Uw:f���� Y��@� �%�M�pB���Cfjc������>k{ �Au����WWQ8f׭ӄ%����䈥՘S�3��Ɏ%vj���:���a������n�4\LI$�ry�2=�o��]C2"ѣf:����!�ߞ�:BJ��H�a�� �5�����$�p \�����}�z��ZLT�)�6�Ũyԏ*w�3,8Iԑ�b�XN��ᮾu�.�dt8V�Gɐ��U� ].`*+��3�TbGq��ifl�bH#�X�K�Q��+�)���gj6��#y&ܢ��ͶՋfl��Xc��y���!?=Q� �J���}^�%V-��K�����#t��ؤ.�C�(���L��dj`Ae�$1�#����젩f���H��� }V�h�:��x�q�o�qȕ����3������zs���1av�����x���9�H1[]��o�Ø7�ab
g�YHP9���C�3�[�����A��L��f|�c��U�8Z��d%x�Ic�V��%�aD��[gH�m�<k2�]��5S���h�<I��_N�2)�G'�/�@`DI%���H�DB��/^nG�m{$0d�$Z�s$�������)�I #����R�n�X"08a�/)�b�9��;pA�q�&����)V�!�3�0���#�)w0��Ƞ&��1�N�ϊҬaYȐF�,���&�`��+Wuc���$n��S���LI�*�PG�Mț��+G���C�E'����,HLD#��S)��&�!��?o�ՠ�NۓޔkRg6� K�.Ͻ�"��E�<�s}��͠ҧ�x�\-'�
͞��x����ՈtŔ���?�F���a�9G>�9���O�ن\�'A$��6�&�4��0z��D�t�d#rq$ N�L8ˎ�FF�,E{n�z��0p��V/@�ޝ�6ͨ�*��w�h��	�'�� mi����6�$�QcHυ2�w9o��]�T��Nr���!8�i�ݬ��щ���90�XW�+F/3������u"'�E%Ƕ�����9P��3��l�.�^� �b�b�3l�������:�q��
4���)�.�Qf�*�yqj�6���~<)��i.�P�Dw{^-)�J����X|���ܬ����e3�Ů�r�}>���	b�8uW�N�������~H�V�Z$�ڑqF����Q4�Ɠ+��lAS��b�{�af�,��SJ8��R�������JlG�����f�1<�?� ���6���`�D�u�r ���
:�A!T��ܽ��I9t͚��qJ�3�f�35 ��,;���Lڒ;~ǎ�5�b�^�@�]��&=ꎔ���GD�|7,�FH����6cg*�J���BJA=��㛀��0Ph�@��nDn��~��PȨ�A�$R�pfyY��P$�����1s���"Nt�&7�R`t�3�`vcO��ͪ;�4�\@��1g/0W���Z&���,�<|2�^6>�ea�2�9*8 �����0���v�޵�LZ�4U� Q ͈&�	�E(��JI~K�����Ŗu\�4�Պ��8�8�8rSo��%_�����ΐf%�OT�!@�7L">�3��س!�ZP>�9��Ět���t���H��3��qcP��0����:��\s�N��+�y¬6�ta���|�,u7���m��x�w ��6�h�����U%XЕJ�Q%��A!=��X �i��`fB;��Rcp���(]y���nt<;��%ds����>�-����*�i���ەxQz)À�Ј��l\�	�2�kK6�@.�`��OS�J�X�"d1�1)?����{K�>lo��5�e��(:�M����q.*���0��.Ь"���
#;&�(#�.��E�^��(�4%��?v$!��I�~��-�y�1�X+�'�ә��&�䐩�1��f~OP��A�csܔ̖�_���~搛I{��(��Td�޵9`��ڷX�����,���s�y�ll�;��n���bl/O�J�ǉ1n-�����5*tq3[�B|u�.��^�x����Kv*�%XYll9�jH,*q��W{�ާZ�J]�v-aထ��$�\V����1��Aa�����QTms6.E$�d�ߞKi�&^Z���S�D/�xf5���Ι7]��O��Q2o��gXk��T`(b���h�9e��q�\��Drr�P)\s���2��]�_J`N0��%��MHf�{�;�kq�&�����D���ɼ�v-\��.�.�ѣ�{̩�l��� �Ғ�f弅l,j�3T%�[�,/@D��P7)T�3�@� $͂���9�|��ˉvU?G��	K��̝��{�֩��G��Q��F9��6ޅ$���룠Ლ[�ۀ�pY(�L�I`s3U)eP@+ N���5$xC��d:
9ad�C���lt�f!!��?i~GU�B%)��Gn��'�sLDx�_3�x� Iԍk�tŏ B����FJ��?�����h�Ĉ��[99�Mc@a��2m(��HE�Pu���ι6�Mo��<�;����F�r�)��L �h�Ύw���P:�)��?
��[!�6�{l����WNR)�t��<$�TE��&<L�H��:����GD�6����r@Y<��PceP�Gz���n��?���{�6�2U�[%��˛�7n���,��E�F�C~e�a��7WT����DV��c��6%�{��n���A�3��4�8ʜ�7ϥ�+��Ћǘ�#[��7�5 z&��󴬟.Y;.��:�L%�h�����$��32�3��{�?௅=�;r�[��JĘ�d�����M�]fP��7L4Q�Mq7״\1�	y�L�]I���K�P@�9����'�KSS!/��
�ꬄ�HY/{����y�Fr�
 ?���O��K��I78µ�|b�D�.���äS~^F�=��L:�7CN�6�R�)���'�Y��q�%Yr��� x�Kƃś����n��`�9���EK��Cn2rjޑ~�q����1�HNb���w���+Z�i��E�+ɡ3���ᣇ���Ӫ$�^!�⠰�ܐ�����ԒO��2��^Ec�b 4��B/Qq*�yf���*�t�|*sܢ}i���ĭm�=β*\��̦� ��C���:��"{��e�|�!�btH��X3Q���d�?��݈��9q?|T�^�%�X������R��u&�nCj�xa��9S�[��۬�Hb�c�Y[�*�N��9H4�"��;Wd����3M09�4��ܢ����k�`��}��إS�송 'X���l `]=��Yu��4�σ)�KN)��U�ԹS0�:cL����)��+L,G����z=L�*��bo#�)1�2y�c�&��;��"�ν�R���bn�v�bu�qz$R�:)t|zˎ%?�Y����c�	��f��x��XZ�c�����J�)�GJ��*��ٹ6�GQ�Ɩawm��R	�
g�Tmf#�cR�xH�M��r��a?6�IN�45u��Z�s	{�qE'��TF�SƣKgJ����v
�y�b�lN:�Ƃ'��6�lmB{B�(�0a7��6�����-��]�T|���8 �u�jN<�\�IK�ovDɁ�AAʪ�~ZՒ��QX�YqR�A�KP�5Gb�t/O�.�3��#��WFB����� XNQ�{��HoI߼���J��\����b���
�^�:�(w��=�Hc�]FML«�*�PCNz��x�������0����x�ŪZ��,s���vX�O�3h���KZP^��lt�v�]�[ܖ}�sT�]&>�0ؑ�Ob�73*��y�*�$�I$W�=@�H�S~�'���e����ReS*�'"�����\�!ta�R����.�$䃜tY�T���­=��em+��S��_AJn`��Ȕ�뜫>c��yi�p�ܲ,����eT`�t*p�:xR*�R����*�H��FL!���J�2��7��Ewo<��tn{���ܑ#�)� [R:Il]��T�9ꤾ�b3�
s@�#VG��m�*�����V(�(��"(jG	0$�[��)��xaL��5�C��H�-8R1����֥���k6�������.\h<3I1�yWwE��] 9�RR�IY
�m�yƬi������7Y���M���8'�N�B��2g��,�� �."��!���a�lrB��0�$�ʤ�p�Iu �d���9� \�l7� �j[Z�%\-��t|��e|��7;8��x-+�c4SZHg���i����UW�s-��5��P	]��Ï���IY\>X�˞^�`ŏ��6�Dam�]U���8&����*r�e!��t\�f�dqfx�T|����֙-�e�-�f`�\z��^l
���:�
��FW^80�ēCʫ5�Q0Y�4A@'�Rb��ĚڨAJ�=�H~2}Ц���WC�sJm@Az�RHi�_�"�W��/l%W���/�u��.inX�u�2'�~���Ў�*Kr�'��:i�+�'�<�f�h%yg���b*��5�%.����Xx`�AG9�3�um���?�U}L;�<���%X)8��|]�� j�Z`��8���\�^��Gj?�j�i:���Ҳ��ϜԠbr㩉�9�ꐁ�	��y`��i�L���Kb
�6�"c겛9i��n�SOT
[5VkX���\c�}���t3W7j�-W�]]�S��}H��T����h��$��qǤ��.�BnW�� �-�k|C�߭Y���mЌ��Y*��Ѳ,N�P�Ùz��\�K@�H�'��SAS���x)��]���0��'yW�扈Zr�٘�>]�wW��=�P�v�@���x�=o�:"?ȥb�)���}�mt͏@2]xX2&8zc�Ĝ��s���cn5��Z3�����R4тL�]O�Y��F�̗HI�G�����F����Zz����+9N�:Z`�r�Z�n��r6�<�B�n��W��u���t^�ε.����]50��5��DcN�s���˘X�D��V�"��|���e���#Xa��Ƚ{)�A4ͺ��3[� �X��[at���g�XH��98p��
�=88?������B�(��4�d-�78JN"��x�d@w��u&ԅ�ԈubD�g��	��ʨ�< 5Ma�.�E2�&�+0����A�B�/�'�r�
r���[AX���בj��]J��Lj��9>�W�����3B�"?M	�Q��M`馘gtv�j�>F��7��l�X���(�B�'3��l|]k���@1���E���	|eUp����!}!��:�A��ę�}�AU�&7����kq�(!��m�bd�T�[f��s�ْ��f�n޿�?������S��Բ$@�%.�07�MKp��A{񈒙�Fͤ�3)���pfq�Z�-�{�����q������PGǇ/���UuzH�[�y�:8UG������֎z�C�<:���n>�k���[�9�?�[G���ց:D�owOZ�䴉/���ǻ��/	����ǻ/_���vZ�tCUz��Q��t�u��x���rǤ*�vE��=}u���>8|@~P�=ة��.j���q�� �w�a�-�q�`{���������S��3�f��� {��:�﷎�_����ݽ]�^��b�� � �5y�ۯ�������ÓVM1
 �x��/
f ����M�0��y�˙s ˄�U?�F���񐂈j��֋����V[B7'��[��S 4���Ak��<�A�����n�[G��c�����1B9<`2ڬqr�	x��e�HA�7H��ǭ�xsE*Q>� ����!ڡ���.W��b¨�+��%��������\!��Ã7�N+�gK��燈��0�]� �����o�l�8��}r�vU���w���`�Qupsť�D5a�'�c�6��&����]�}�R�� ;�Ӧ�ÿ�[���u ��=���~}�[�0��װwx5p���w�w�Ɉn_4w�^�	{>"H"@g%���R5��W�/���W�l���?�W��[Ь��f��������������a���+1���«�1=s"<B�����g���X��X��pea�o.<��R�"�J]�t�%\��gU ��b�c9�� 哠x��ݑ���jg� ��S�dV?PG�/�3������DR�l�=X�#�w�h!�Lѥ� ��e]K>@���3n ��W|�S�P��\�:��y��� 2'�$���-pio%��r�DHd�t�1ɝJ�e��ΖV%2�M��&��ɣn�@%.O��lV��Mt��}�E��fU_Ҷ��$�rĪ�T�3Ъ�����uN�.�����S�����1hT|ڂ���4{��%�n�H�o�S��/JL��\J����F�O��44��-�F)u�_��szSSە��E�T��{D'��k�9��q"��Q#(�)N$��3�J�����%�=V�{=�T�{����}�:m�[�-s߸���Dۃr�sC�ŹZr�y������W�Sp-�<
>~��7]*Z6�r�y����^Їt�g����Ң=��5� Ze{b��b�����Y񱫼�ȝ�x)�x�Dl	"�yv�a����Fa<¥k���g��,u�Zd�l�c�C���O&��z���v�Lk�����=��`@ML��C7ni,"¼���|�8ռG?�8M�j��0s��
ʑk�J���u�T5�ӗ�����$�=J׸Ҥ�40��P�F.v����5rd�{��٭wb��43����p��ik�גyBk*˩&W@���/��,��~���xy4�~�1�mo�����6��'nw���@ ��Y�_���H�Ben!��1�����m��Ig� ��R�=RDL`��L�u0�%�Jڮ}"����][�X�q�M�נ*�0]���7)C�\SL��^#���f4���ނ�o��K�Ӆ�-0�n��^X�+�ir�:^ņ�MYw��b��xab���ᛝ�k%YC�bU�͍7o�&nܤ�9��i�ˇ3��ba�$����a#{/��!s�J8|9��q�q�H�����v\���u�%d0{��"	:����QBEqCʝ9\��x]�\�KI/���u�
"d��Ƴ�{�%�ݒh�ԡ7�=LǱ0��t)F�T�tԿ�_����˃�Ѡ֟�:��g�t�N�����oՆݯ���������nnп+��>��Ucmuc��	7�Jcmec�wj�+���LQ��P�4����zs~��(��?��:|���E�)^��E���r��7;��{+��?���G�R.�$W(�pIJ��m̏�@��D�Ej�i�����}�P1-��l��*�5�`T;����Nֵ�pz����72�ƜĄ�@'�Lu��+]/��m�1����\���I��|l�KC�y�l���1�P��n�@��z�34)T	ݚ·0{h��h���z��~U7�������P�"���d���x[��R�ޑ2J��Ս�I�z��恤�K���SI�|� �vaP��������o�Nz��T
QɅ�lXM�N��1ր����)�Ln��Z$�00�sj�K����"����s��<�*蔛�͚��\5� ?�9$
&�4�Uً���f�����/�
Ǹ�v�s����Q��lԎ�Ɣ�����T�?�@���L�Ѥӧ�]����m4�`���e2���m�zt
����F}]�̢N�j":��'\�� �Ñ����`��(����E��z�@����������� n���G����͢�T}�Ҩ��bgj���4.7ˍ�����꣭�G
cǧ[x�0;&J^]�8�Z�5���,h�/�% bj-�*2���!�]���댯�.�����O�߶����^��y���'5��7b�����`ۼ�������p�y���ށ��y}$��vt�(���:�М�"�]CԚϣ���]�'�J�a}C��&h9��М�jGs���GGL'�Sŋ�ts���c�p�o�з�񦹤z�r��h`�D�Q/��ނ�u�vS]�C e]Ph����%���t���
�ڪOhP�@��L��B�{0>���)���nBD����A��M�ɑLFM�;��|�#����R�K��=�����(+���Ә;����N�o�=�%ݚo��e��ي�/'��0�v���}L>�K�INn��d8*ȸAz�B2����n��G
��=~�>�������~�@׼����$C3�֑��n��Pr?P�Z��T_ܴ�Oh܄K�Cm���`�
S��j�~�RM�iQr�Y���Q�Ǣ^�H����c��q�R$�q�Q�`�b?Z^Y]nl�5V�6ַV6>Mi�Vj+Z#���?A����.��i\��i��}�u�Ӣl����9*�j�s!���|��q0������@����Q�m:�����������)�[j�ج������wo|�N������S�$#o�~�c{o3���>��]���Pn�[JU�/���Z��V[���o�w���7��xp6��6a����F�Qm嬱�:�������ً�8(R�l:��5d(�Z֎���6ۭ�B���0;���qkt�����nڊeo��gt|�n*������1��{�����
��6�j�m^꜄m:�H�2̼�݋�����m��S@��vZ/���N�\H��7l}�B�t��G�蔓��u�*=|7
nI�$���R�	S��yc�`\��DYk��L(! ����ݳ(q4/�a��_K�=�����v=�]Y�<���b�t���Fd�v��Ժ���g@�MPz>N1]�o�!J.y���#;ٯ��f@�	G�?�_�3x�kR�6��f��l�� �*��/��z���%�a�Q|��$j�`.%G�����C*L}�y�_��������#�l%�H`��M��M�;V���-}.RJsC�<h���i �8�	�=U��O���}��4�A�jQ�O����/K��~�yoQB��ؙ:������Q7���Q����б�@)j���F��\�k���J�ZY�%H�L�駪�:>><Dnt�tИJ����f�e���!:��D@��GO+5�L���Q3)|�w��ܣ_��؉�M+؁`�������f�|��P�Y)�k�t�f~�W�xp�[��k
͔�8��0� �����8Շ���I4����U �h�ƥ�=PW5�'+�j���V���E1�91"���ij�{U����uP|�6	��sw�$Ú����m>k�|��Y�"��j�ӳ49/ݰKnz�I��=���q!���N?�DS��WƯ�@���م�p{���*�\�c�DT�_7�
���r�h�x���"���3S�B_�.�H{�)3��V�u9w������	5�ě�I�[���[�)�1g����p��#dg^�ts��㵣�M�x�w��]���.D�Tw��m�������=�U��.]��'�0��PЈ������S�=���K�pEaayjA��P��/j'bւm�4\.~�/�'�вo�NA4!|1h�t"b��c�n�0'�z��ؾB�0`��5��̮�ф����\�F*�I��ޚJ��1�A�Q�Goཝ�=�JH��>9�S���8�i'd�Ȁx��JY�U)�[a��'ʜ=��a^�����	gu�r��u��������7�R�\,����5����q�i@��D����U^~�b�`b�����`�c�[\�=t����џ�Gq9������]M��wL_�lΠ���������c/1t4���`��K�r76��z�4xN�'x�� -��H��&Ab)�
s��.]���3s������X�� �`[�8N��K�����H�e��~Y_���p���dEii�=u����hj\S�x�����|�7�c��u_�)+�H/�:��;K�Kz"��:x��ha�c�M�!��(����(k3���R���4��F��v��U���m3�~͇�Jg]A�B&��	bs�e1)��C��t�ϱ��VO�bhH��Ar�����BE�0Ө�����٩�$H��ت�Zr�]Y�N**:%�Oa��>Cz�So0f�XwZ���c�S���SOh Z�����Km0K�<Q��Ǭ�5'�����Y�/Q�;-�gh5�o4ܺyZx�D20�T�D��.����9rwz��Ξ��+Ԃ��v��u��&z�8�Ι�+���
[�G�b�Jh"t:� ���Ҭ�R�:��"}� �;w�?����;�6~W�?��A]����+}ST��>�S!ݲw�hW�\��8���}Aď�h��i_���9���m� t�C�[ ���Iy*�B0�}��}a�mF����h���5Bi��t�eQ����;�ߙ��*���$�nܦ�ƮD)�)+�l�D�LO���nXW����<Q+�b|M=٧4������A	���6�<�NF0��V���[|�NH������S5�"	���L}~		Խqj����y�95h�ec��f	鱗���ǐ~���ٹ���K�8w>��s��*��ޮg2Z�X�h�����-�	���yT��JV�mPn��F��4��ALn4���Oؼp��{r�؋ٸ�]'�{0���/�6�3���;g/v��t�#})�1U��,Ѕ�Zϸ��+>���&�Y�6ҏ�����B�ܿ����I�獆f qz�|@֧v3����M��{�n����_�<`��e���n:�R�D�U�Mw�)�������g�k�G#�8�Q�m�u�oΖT��{�5§���>�¸~�_ɉ]S7��B*���n�����WU�FQ����`��x'�.�q�v7���{����)9��"5rb����B��t+�Q�a�~��BeP\�I���H0xF'����L}�9�3�X�7�|T���K����v9	�2Qg�-|�P)�垮V�s���Z����-�F�1960g����nS�:b�h&`��v�]2t�~Π�ۘ]��G��X��A-��M�30���±����� <w�D�q:"����D�	���䠿��e wdHΩ_}�A�na�+�o����/�	��0�|)t����e�7���2�BԮȤ��������^����g2}���4H��X8$9g6l�i��u#a� wU"�j�V�k��(�;��l*�)������.Qr>�ۻ�C)��o^2UG--����o�&�ȥ)��΂f�L�أxFQKg���:O��ϗ����fm����[]z��8�X$��!�r�(�N�AiS���>X�gh�4O�e5�d_��(����^�@=�^=���=x@�ݟ�89�u*�pv\%0�E�lOu��|W��J*��7��,�~8��3׭�NL$i��8�����B���R�,~�(�#eB�L�NtL�.(���hC&�l�,�l.b���,"�"�n��lOb����4J\�E�yA�Y�y�1T# H��b)�˛����S�ݗzDP���f���Ne,=��&S�P���Ѐ1��wv���U���&z �I#o>@�F�%#�����&����d966[,ʰ%cܕ�՚jr������T;I���V���2<a%I�$C)c�==G=�a8�� ���,D��S��k���LU�J�qQ?������[�0��-b�l�^G���S#�Q�:)� g�T�i����K[A�@���y���Bq �Qb[�s�%|=���b�\����~^Z"��i���tb�D[/oNE����J�\��)]�/�f��M��Z6���-�[�}1Lگ�Z����_�gee��*�6�WV6��������?��'0�q�<�C+�{n)�����O�`��f�RN��X��r�9�8Η��o��͇��`���ï���c��=|��m����퍇���G��hce��h5�t�7+���Ç����Շa���T�ϏmF�0z��<�����n�녽�ݍ�� ��퍕���}۞5klln����z/��Gף�õ(z���h<�6���7W�o�si�a��h�V����{��{�W����|c�Q��X�=�:��r>bscu�Q�y���m�;Qgce����<nl�u�+��:���u|��Q��^Ymwz����G���G�p-ll��V!�����C@�# ������~���p�������7:����Շ+��0����9���ʣ����m���5`�݇�[�׺�h�SX酏"��[y��=z��¸��Fc#��+���f���ƣ��Z���#��j�h��X�|>\�i<�=~�x=Zk�?^�X� n:O���h����ǏQ�q���x�y�����Z��Z��`q|X�G�>eEG���]Y�u:+��j�����5�G����͇�G�����u�A�'�͵G0���J�Qg�o���}�v�8���]��w�(�q�cJ$u�գ�F���'��ϲ��$G�"!��DjHʎ=�}�}�����V 	R��$�ibf2X(�
@P�Q�j0_u���P)�''ά��`iQ�E۬[[[�֫���65��U��Ԫ�[X$ۿ�P\��ܓ���ݕ
���^��i�R�V{FϪ��R�zU������0`F-ٴ	$s�W���~u���VkzK��U�6�*�F_լ��K������**�f��^��*�[Uk������H����)l\�z]�W��fm�4�ЀC��ꍊ�kЭ^_335�i��J�2�&��iT{���c���u�W۪кU��^�+̀Uպ5���^�S�=�R7{�olU�= sU�4�t�ޯ�T�R�����\7���`�}}S����Sk��Y7u�n�P7��'�VF ��6����ZZ1kFݨ���V�Ѫ5z�
5��Q��`v���g�Ի���D�a��-��η�Y�z�^�W��ǪB�7a�i��Q-Ml7be# '_C3�z��WM�^��01}���(rL�Q�͚�J�_�uQ�����x�͵�
�Z���Z�`)��V���rU����6ԭ��e��J]�`ka��*l �
l��l�=X�ƖfXթU�k���������lq͂4t��Cs�'1�zu��F�а3�jT*խ��	�q	�PT��р+*l|����9U3�=����@�٣�6䦰# ��-�;-�Z�*�� �7�^Ūm��f�ge�\����js�f�^��m�[5�ڴz}h�fe�4+�Fu�V�����4��}�����WaG���gBWq�Q��	�]ckK�]v����Nr�x�=G������k�7���:�?5L8]L8z�T7��]��-�z�gZ25(�ii�;��7`��`KUvL�Բ���{��-T`�`�aK�Édꛦ��oU�	��
�
�4��^X.vQ ���F�Q�B���n�5:��p���x�%�{��ITĳp�u��W�;�Ay	�?�� Ʋ�lٕ�Ej�n�?����/��9�����?�8�󏄐���H���sf����4~���<߳�����Fn��^/����C5�'����x�x�j���t:@_�~��O���A����8���76H��������hTH,�Ԝ2˄�m�D|��];�ݶ�.�_���+��b�VJ�Zv�~�o��6�7}u�g`�R ~� ,n-2i��;�x[�cbV;��V֓��p�5JF��2��4����`��sN�d�C�] ��/��oÛ�}�RR���}�1�lja-言bT��G��N@�cc��,�f���~��J�o�zZK���/�W��1bQ��x�m�dImnu:�gfg�0l������X!{����=�.F�#�E����G0�=��n�B�	A���<	�`C�f�)$"
�eI��R�,����o�w����>������#^>�PGap���jbL��K�S��{�F��,���ᜲ8�p���M�EȒ��"J�sϭ!ן���Gؒ&��%�+3�7m, uX����
��8�c<iV$3�; L��XF-��j,��M��H�Ђ��x0�iצ�㍄�X�Τ� t����=�����4SF7�EO�����B��p�.�GèJɽED}/-|7�G�"��)ɇ�+��q3��iUM���j���U���_EZ��4	��� ����- $]j�nC�_Lݑ��r��)T�ۓ��iIBphNİ�P�/�%�)|\��\�XLs���[r[޽2\�WN`|���}�z����p�z@�:Zk���Ϛ/��w�Z/d;�~"�!�i���k�R}���d9n�$�Z�Ͼ8{(��a����d��U�P�f��勭T%سLX	`8Z�Ɛn/nr�EF��pG- ��hI*�a6������ ��nV/ƌۇ�o; |&�ܮ˒��wMo$X|2�_N���`�f�6�0՞B��"S�J�cz��$K^���]xѩx,�E+���R��o�_��[��O�p*9�K8HMa�8e��Bg(��M3����~-����X������%���@��Ђ�_�4�l���W���!���OFD1IZ͎�?�-zQv&��4S.H�I���ì藛�u{ow�y��=�\S�fw�\��0ϗ%����}���Qlf�P�k+��/�2�l'P��bx�}5j�X4�����tC�0�U��"J_������������L�M��k�(��3��!��roYB?h���('@�?
���izR4�Y�:��r|��"�fI!�ோ���<��Ԟ.�fB�ZcгR���v&�
��3��[�6^ތ7��� b�2q��(�P��OCAn
7�i(ȕ��!��n/9���|hDd=�(�Y$a�A&�(e+bE	<�Z��!�	��vH�tZ�˔w���+��M?�w#������06Vv
��DFax,��?>�3;�3�_����;a������hH.Mʺ.�6�ؑercD��Wh�fK������J?@�Lw�z-c�@k}]4��Ov[���!���P6T/�SVt�E}z�	����|���(�qd`�h��]a\�w�O�z��x2�&�83��ׄ��޼��h:.N�V��GKŁ��@"��7�=��⼵�0f~�%�*���1��02���YS�#�O�Y�"k��H���Ǭ��v[�vbJ��Q<�=�c�l5���1G���U�������J%��XI����7�\�]^�&�7����eWY�up~����[]/>��!ϸ�	�_�b��0�ۇ�$�Nx/��'[�n�bˬ��1��_�����������3v�J�m���x���u*�.�AX��f��)��VEn��u��5�{,ݏ���b:��dIYD�r����tvw#6�gw��H���~7���VS�W��*�����.Q0۰r�u�Y�zC����Z�j��_E���E�?m��T%� قZn���ڂe��Hj�_ߎ��;�{�z1H��c��E�)�t�Ϻ�����H�������WT����*R�K�R���7��_>��OI�8˩��_k���JҔ�%�q��������4��B�s���0����Uk���Jҳ�Q4J$�'�(�c�~9������p��L��Gw
��g�6�:���������XD�#�����g��B�}�s�9��|�B]�"El����B;�c��g�<���y��yX�l�y����w��H�����g �����2!�,�B�>e \sy������C�v֦̒0X|�B˩Ї=��X��j�E�������0����;O	�_� ��:�~��������HSږP�}��z���$��������U�z���P�QuU���+I��^�^��{Q�v�w��{<�-�݉���յ��翵��k�x \���Z�	��|'ד��r8��D�B�>r��z\��k�ڬ�%L����������!OQ�����qk3��7�Űja�U���p�I%M;KDs7_�bXdJO�43���1{�@���|�99h�K��x1����~M�$C׆0���K���Aj��w��}�����P(��LA�ܯl�f�����OQ>��2�����?�Y9¸Z�YZ��=�U FŭKM�E�!3M ŷ�e���it9ߗ>��?2��m�q�ƙ��9��0����	�N �����v�߱����� ��p'U>_��P�B|�O\w�φr\e칣��q�c���8��]��Z~E�]�[;�@s��F]���64 �?��]Q������3V��~������A7�ch�����l:K
��dg�5����3ψyB���@�I�tҧNi-m5����?�����p���`L ��p&ꘇ���$�Գ8�\&Y`{�0 
Z}�c�0���3Xܽ	H��a�;��� �hL���SND��̗G�I�I��(��8R�:�"6`�|A@�1��.����WV�!��]�s,��`��K��%�]�,����;�(F8O�Z�x[��M���}�{��ǿ���Z��}�y{�kh�����z�뤾��2w�ʱ|���H�X��K>�z��]�aX�D���?���횦=9z����Ķ�����-��٧G�[�o�_����|v~y����������ݳ������w/��C��~s}}��|d;�j�}��yU�mנ{��Z�t�M��_�3��[ʜ?(��e`c��m$_e�&A����t`�)C�=�<w28S�4I�����i������Ë�����S6�B:p���z )-q�c�󵟽�ӥ��z2`��@3�{ �P�ο��9��$��'�m����^Y;|�n���o?��3����B{�ƿ~�������|���=;��<��ÿ�����/?��_�C����o�ο4���^����ʝ���=���~��mcӳ��y�Ƒ�����nҦp�@�ފ������i6�UX5�F�K�E6�ң�G�S�f�"�3���Rs8�)�䇊���~���1g|���^��`�G_�����ﳇ��0^(3(\� ��f�����9P�c/m:E����l(~��f͘��M˽�&��Cq
�h�0GF���H��'�wr�vː��c��O��������?���g5I������2(���eP�R{�WAX�f��pl\�)X\ ���97{:Pd�K�7q��g��g�8m��a�v�0���~��̜�Jx}䔧��M�fM��I�+��n�X��z�`�SF�l}w\2��|q��¹�y�< ʨ���;�3&�1��0��gL�s_�]����MLԲP<���D�! �c���#����"��>�f���K,l=(&i:�κ�Q�"\J��OJ�)v��*��q �E�@�q�UL�v���.M/�%�$/������ò���W�L��i��3d6/
�B��w��R;��l���B*���y%��q݊$?���H
���o��T���Q]����_�
��퇆��Vw_�|h獵�w�F�*_ĴQ�*��8UP4������2�^��� �.3�N��$���v=ri��������A�� ���E&Wh	m�H;Fz���h|��k���x�����ܟBq4��l6��Xj����[\�b�W�]�Z��>���A\9��h-�)��:�Փ��[)��P��i2�N�k�e��I����z��_����z.��"�"�jE���i}B������+��y����+# ��m"�'Jv�f��:4���̉P�0�'��IL���,`M��C�^&����0|�H�3���
-	Ad�dH��!�k!0��:���ٰN>-��GT�F�dl�I%|}����3���"q�a,�V��U{of�Cr,�������zvH��ЎԳ#�ߧ��5�C�HB��1\<�2\�˵�9l۲�̝pv�SG�)q�t`\F=h��sm�q�&u�bZ�{*�E����]��$]0"9&IBK����f��߭�i}�vuJ/��z=8.ßQ��H�ND*ԧg~iN����<���+�X�W�������������������� �+t���Ok��s�￳.��)�~��]
�2x��߻I8S��C.��E�>�+]� ���vh� �k�_Ӥ�?�M����*R~�����^]O���. �U��� �Ӱ���_`��k<�Ä� c�x����S���;���Arf�D�?C��l�ː�����9�j�4ȯ�����n�Wt�b��.Ç�ϣ�,��W]�p�l7�x�U�#���aP�1���<�.�>0����I�&ly|�����v�F?�~�\����(뺫�;��D���<-/ݖ��������U���%ij��JW
��5,���H�����F��Mә�W����JR�iEA�nXW��J~��n)�����7~�˥=��K���v���]�kєxw�k����|j1�&j�Z����ENw|`w�7m�WZB����/��6�����M����J&L%n�:�VY��w��qanv�bí�����ӓ�K"�����y�+p�_(>�_F(��X�o�Z��?��Oi|}H�w��񤯥��5�+�>�Z�D�߈Z�@-u�Hj1N��3'�V��UF�����v���w� ��s�v�"�}����� �:L{��@����o�\�||%�(ޅ�jBr�pG�	����w�؎�^��N|H��h�C;`�େ��@0�rT4N�oF����H�I����\��ސ��+���{�)�{t����_��;�����W�����@�T����p����ox?NC�-�Ѭ��-e^����|8<��ƲZ+�:`�q�Q���3�X<�#�\���o=�%)[��<�p��� H�$Ŷ�\��V2���"�%�T�qFa�h/cd��ߡ��|�J�l�����/�V���; ��C2����2�"�����y�`����cK#���hɳ��� �d���qF����qc��i���B��3��'�շ�ߖ�
8������:d����a�_R��0'L��I�/�)<܏RH-�9���$�o�͈"O;��_Ɍb�$v,�;,�L1�WI>+�$y�������>s\�+���S���6���X��+��c��'g��7-�~i��=0��c�!�]l�r;��\)��i��GI@��w���"�s�S�4����V%��P����JҢ��͞���3�ӗ{б�������;��/�5>Q:}���4��VSw/3�X��0��X�wd���?�/����߈�K�廆���V�b��e�2K-(U��^���k�����)��./W|"�iy3�Ay�je^�/����/L&��m'x��*��iCU��˰����7.H*���g<�;���/i��6�Q���^X���Ɋ�Ba�a��9�e,�����ZOƏ)�p���qbp.�Ec�ǣ��F���HC����㓉�/���f@�4���>�w�簽�����w��`4��8l$.7x
�)^,��J!�����
�HH�+�y��QkM����Y`�N���Ҵ�������J������+L����?g��\�3g]��\�����0��Y�S��?�V-ڗ�.U�S���?����?s���2M�j�o�2��T��5�!��y��J-��V�r�oU�ߌu�]6�V�p�s��a؞P"�΅��T��,������2&��`���0�/�I|!�H�K��$ľX�N��hg,�eנϩ!-�� �y��xs��(��I������G��#��S�S��L��qƤ�%���Ƿ!�����v�"\�nJ���CU��1W���jj���F.��"���n����i[ rc9O5r�������G�tNY�EZ�)U�i��D��DU��&�H��8�,�W�O�̚O6��Ab�3Ȉ���+�]8K�j�/\�Ό1���I��g(
,�/h<5]SC�gS<��(�?0��`H�PKʺ����A��3��v��a�t��l�@a�a�EP�g@Ӿ	djchZ��E����gx��)f�Q9�V��FP�C��q��-|Fg�d4�l��bE1n t������+�����_x���:�Z���*0q֐z�#�k�4�n_�y?��(��X�Jzi���4�R��KZ�Z�Tk�̾���� ��HĊ�:ej�\���G�G����ʏ�Q�q/_�`1�xX��[`5�aS�m����΁��H^�HBآ������_E��SQn���M���� 	p���J���V��O�����*R.�}񟞾���z�$xa����y�\MOO�{g�C�3������T�|�~�8��$��1��"�C�4�Hr���3���!�Z��`��M�z0h�6�v�:�F8ؖ�2�1D��P��\C�R�j���	�/��$��í�I��刵�W��Px���,n���b	,E����T��������$�7^q"�¥���'����slQ�ބߣ��!��3 1�j�cj�ư�t���ܟ�/��1���3͘��FXRߘ�&rx�脦ǎ�c\�pa1��[�i��ɜ�#��C.d�4A6FL8<�}��3��O��Hއ��#2lNd{2	T�z�;���
�rG��j�X��s[����{�N�k���Y���C � �f���4b�y�q3ct(Î`���f�Ѩ�zc�����v��`8��T�T͊G�=�s��G<2�Iw_G�I*��H��&�V��)�^�|b��%�b�On�6������w��e�^�˾�_�� v�*Vl�/�sR:�(Jp*���<��)�WX�J�Lxp5�;���\Ԭ���G+�� f�c�6�L^��������>t��n��W�:�I�w4����qt������a�s�ץW%�������}�f#�Iz�)��>�s-d�Xǜ������Vk��~����P�gi�OT|Z֓U��7��w�0��n����a���z/��剪����2O�ev������ ��q	~����- �"�s�3�̍�~�l/
�s���H��kOҪ��y�k~��I~���`�G?K���դ�_k�p�Wy��դ�����[��۰A|v{�u~ޯ��_<�KJχx�6�/���.���7����;�m�� �A�)�n�l�M!$��?#J@^���e�+� TS2��O?�r0���$ �O�
K>˰a�l���}��x��n����Fm�~���;�>�}�{p��VF�s�+I]g#��m�O��8~w��>�S���7�ˡ�e.*K>wԺ�:���j#��*����?9������fоa��VdbΚ5���ȣm$�3b$šM;�U�Jj�DҜ�VR�\֩�F|��n~����c����#3����N$��x�8� �C�	w��1���"���d4����B���`NI_�H��+��El����
S��bEX����#�,���
��L	N��C�4����s<=���^yh�ʢ���˩
��3��KfT�=;IK����5� (*�}-�(>���v����gboD�B�Q��cv3f�!�%�7��;�&�
;�/����ٮ�'X���	��C�K�;/q��B�P/�I
����S��jL[�{-�:Z-��f}�b�>����p�wǞ��D~��[&�cv�P����˖�~��}t�^V82w|\=����N�ήC�VEU�L�2<�p�'A�&����.O�u��\/��T�X��L��M������/��O�0sԹ�@�5�����Z�c�O�*��7r���I������9"Z�ޓ�����L��'{#��Bg)�0�y2��}.:@̇M͏�s�3�"A8d�x�O��X@c��=6a�sG����51l�`�]�+w��a:���!2�6���T,`�5zH6�a�����b�{�8���
��>�(L�-,���!�֕�:���J0Ҥ�q��=�b��yrF�D'�k
2�o0}�j��=dJ5��ǇM
�a�]���ۧ���w{��O�@V�PG���2��DbL��q{{��jBi�G$�z��팅��pI�8J)v��<ݑ&qB�oD(5(B��>iO!CD�䆽�66������a���6JM�<��l_ؘr�Ptx���Q�o	������ʳ�<�M��<��A,�l��Kã2���>����2|�j�o�M���L�`�2���7)�@uS��^P�mͪST�6��O�o����84n�
0�P!;.�#�f	�l(pv��f��&���ɶ�������o��73%��ٕ<��:����V���V�_�����_I�}�������1�ǰS����[������S����������Bgw��x�����싻����v�ݯ|����[�o�ż�i�)K�_����<��zC���:[��z��W��%��@�θx� �	E`vr �&Lch>{�Ȍ��"A!eT̈́�ӝ�n�ϼI�����+|=���!W��6>����a�Z�E~����2�ⷤ�E�G�z��w��/�����{c8�o�P-9�h����~<k~�,��S��?��Ҵ�Z�5���_�VfT��' P����"{�p����65ٽtU)������rK�=˄� �����1�ۋ��j���Tf��B �5�{(F� =d�bh��q�`v�z1f����>on�e�ag�8���b᫸#��)������C�@���Z�fB-��?�װ[���s9�/:�e�h۸-�g��Sr������uk����C N%g}	�uj8�^����t
�~
�k�_<�������!�[�X���*���Z�_��],X�C�� 릕�3�w���,��v�uȾ��(}-A�!�]	(\N�P�����5� ��gY�J����֌m��d�Jb�،ğ���aO�ڙ�	 i��(����>�puh���\~�����|Aտ3:�Y0T�۰%���&CXyƐ��N���Z�)� ��t���2&�d��E�=�`xQ�ϳ���C{���1:)Q��LL-�&L` ��2},VSo&�2w]�w+N��\*����H��c,��pp�+���������� �0����9YL"���3�1��ӎR�N\�T�D�^D��T�.�{;C0���t@����2z�Ơ��d42���Y��Tr�(cc����������>��?��<��0P)�ȝI8���;닺cN��x�^pT�i��/�N��jz~���d; ��J�O)G1z 䫺��%
��yzh���b��®����k���j�����J��s%)��}��_y�}�����so��W�(�����u��ou��x�g�<#9�o���aB=�K�ax�-O�IS�_`�]�<���WR�_����&=c,?����5T�F�����.�A�w�G#ObfE��D�U���\D�5�+Ŧ���IS�d�� �7�������%��D�]��]w:R�k7�5ϩ��*�[M�^�7����[��>%����_���n��tW%��������y�������Q�R���J~3,����豥��j���
���k����O��qT�����w�[oH�+5���Wr��+I��~ O���G�\�<��-���K4��^6"|����|�/Ys�\�/��UX��[�� �/��~O03q�<߃��F��Y���l��t��)j��Z��?[�Zi��v�j�\L:}�b;^ƚ��O�y��E����Ć��.^�t��� =��z�����<¬�%���uxlw��-a�B�w��5b�/u�j#��V��G�t��W5���d/j��v�G��7g�C`'���i�1�輨�,�$�l�����z��e6I�Y��--z�	}�$����1�N����Fn ���⩚��� qP/�|D]8�gb����7�<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��'��?jz.� p 