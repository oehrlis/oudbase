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
VERSION="v1.2.2"
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
� 0��Z ��ZY�0X�O�K&�ȭ`��iW� ���Ԁ��:��DZ�PGH`ʦ��������Q�Q�'�uڧ��geu[]�F�k��^��i����?+++�>y��ߧ����:�+��x�ɷ��ߪ�U����ԓ/=0�L�I��P�4���s~�y��I>����ӛL�V~�����kO��������?^�v�����ߩ�/0�����?�}Q�4�σ�y�v��a?�U���z9��$�s�]D�t<�����:���i6Q�/�����Q�EY�,��H�������dM}?'��lzv�PG����Q6���z/E-�l(�d�����<��ǣI4��g�X-�Q^W9=k���_'� �^:����xR�6��Nl�k+�l�<n��~9�.�<N���x0��iqۗ�uꨗ�㉚��,��#'0�)�
s�E�i�zi?�y��(����.���q2�R�<�A��(���4�-��?O�u�v�	]�O4�l���'�q��n�A��)ν��#�L��w�^��)|��|�Z����L�����A����G���"�j*�2��M�~�g4�Q������p�-���09��{`Sm�IG�߹��B�>�	��ur��|���|��m�Yl���yj��Y�:�&}�>s��T�'�m8�F�'��m��=�]���Zk�`k�sp���z^;>|ӭ�E�����0❌�p<��F ��G��W���� ���S8h�pf�6��O�:���Kˈ�	�
��R�wN�������?>��'�q���ށn�>z���뭥�Zpt�9<>y��lu����vvi����Z~e��Keծ��K�j�ng{���u�=:z'�_�,�c��������+����c��9�b�E�]���p�>}�z�Z�6�[�W䵴\����gP��Iq�xà��`d<�M�E�u��Hq��|<���=��mP�P�m�����m��W�i��?5�/2Ռ�wx�� �6�/TsK}������ !�L��+8!/��U�(�<�:�9�����ˌ�/�ޮ8T3^Ϫ^�G��D��h<�{D�f p�m?[/[7T/y�gQ���n��l��*W�%<QcyD�f�ۥ]�<Q�£���Iψ�m�V��������<\�Vͳ�ZQ??C��z���(L:I�ߦ�Ԩ��ǵk�9���
T���E�qp�+��<Q��TL�&񈤗��K�nZ��z�淽w�(���o6]W!}@��G
��
Ar�N#���k��KM��A��� Hr�
U�3GBl����E��������	�����>Ȋ��/����f������ov7�9�՟=s^=<��j��eb@�����k�x��j��6xĿ{Z�R��=��5�y���5�\�lP<���!浥>��!�6c4��SS�& :6C��7��4�iGI���ǃ��vy��F����Kc�^���V����U�p>8��3��l�i�i�=nۋUs���~� o�x�M�yt� �@�H������Pa�>ē{��1�
YIVMH�*�a�|�nx,RU�%��%S�Ns��мST� ���t�3��iBBz��MQG�[�ՔX��^����d�r�X�i�ZFV^�)�'�R�	�Z �'�64G6F��q�嵂���ags�k���������B/�^�~�hB����EQZ�泺��f:�	�$���Y�yy�~0�4�wK_�z�[z�.���{��ﲚ>��E}�����w�V��'��}�l�u��l�$(��Q���Fa�[��~��Th!�/�<M�'�e��F,�\�y�p�ZVx��/��9	me��=47A�¡�q�Zx�n�hI1�}K6�dac9��1�U*�М:���p��,:ۄ��0�-���hY�Aڅ�����J��7��;���G��]I�ʩ��dȅ�O�t��L��$T9h��p�z��	�AQ�	������Ķ�1F���U �V�U+Ne#�c�1M�F�t����B�O#��J��^N�\�h�B�l��|����m�`F�����bz���f�m'�$��gCH���Yd�
���*�n�/�1�Y�g�0�Uժ,{
�ڪ��1PW3v���x���O���߫f��;@�������EA�����r����ö8�Y+?/�uh�w� EsG �0�L�OMYs�o��uļZ���
�.�$�g8���r���p�.Uͱ�x�/�������:�}��c�y��?Y�n��[���$Ǫ�Mh}��6� �혥��B� �0{�
V�H�� �&�0ި��ˮx�΢I:d��g):��"Mqe�aH0A;�k�:��7�6~��nd(-��x�*�u1d�8���^�'���ڽr�s� ��{�oa;�;�h�n�g����{����9&�HqTݺ���P��'�����tHC#��!�(Q����l,J�Pq��ڠ^(�X{�� �c����9�K*BF2F���$�h�W���=Q��64%MW����b���srL�g0�9Dǎf6Ցe0n�����X�����i�p��Rxs*��\F�)8�"�������?7��J+���wR���C �����-Y�kˆ/����u����q%��"�-o��4�BP��X]<\���n6���dq}O��	p4���Y:��I�8rx�kg'������U�ġ�$9��ꅏ�p�p`�9�=�8l8G��k��{��˼꽢�4����=�9�����0�h��Ң��Ԍ�ü���v���=*��/)pϗa�=������0�'�]���j����$�0Aef��q�Y�~��U����>���>-��o�r�\�)�V���9=a}SD}>���5k��{�|r=������K:�{�k�W�kP�qT[;}R�R�H��ԦgU�sQ�C�C���o�ҋj��V��s�t��c:Vv�c�b��z��΢���z�������ã�wI�赯��ڳ�����^�{������O����K�����3ا6���5|����w/��#Lpy�1?���y]�<S��'�H�=�1C��x��V�V��'��6�mcy+Wi劦w�;� ��9R�\����a���u�A��̉�.� �!d>'�1�, @]|��)!U��)d��A��l�nﹼq&���8���f�3�r&���6o�+��g���Z�9X��9�cT��s��,mԞ	�_���v��ɷ����dM�C<>��<Y�<(w;k�K��Z%��?�p�P}�;Oؿ�d��p�y�)7�m4_o���UQ#��q]RE�)���N�i�Hr|�Ys�fp򣁼E(��81͐گ��hx���$!���B]�"�m��ߗ�2�U
��zyEI!�[�U�s-)�t��|t�?��#���|��S������Ǐ�����/��O�_�oN�?GܿD��@��W���!���B��=F�!������k�;�;1��r�~�1��R�}Eh?��g�ܗ���^��H}� <�y�=�j��a����w�2��`|u���K�3o��P�Id��[껗�{[Nh>҃�m�Yt��-�߫�����~�BETwr���,��ݒ�&̂?P�u�U����k���`CFV9�^�����緒���k&�t3 �k�� �5�k�?o�$�_8�f�M�����o��*$9 �t�K��&��f�U�T��Y��`�A�Q%j��<t\�'�;YH��	��U��_8�I�� `69(?t��%��8Ɔ:�^�V經��K�Ɏ����Q����p�5�aa��i�{?����� h	�"y➢�''l���,B!��p�k��d�-�]�~�œ�ľ8�c�y��mX8]Y�ۥ#̀%�����af@�)�鰦RQ��\��!ӱ���Bͧ��w�]����Q��w\@�'гyC��
��|�S͡��<�{͎�Q--//�;M����m��U�c��k7����j�0�r�ً֨��@���%�_&p_�O���KKrƯ��0v����j�T�2�&Y"M,n}v�?w@�;��W�3���=��{����}`�q'�(Sm�O�tt
_(�d(�%6��Gj��y��6�!b$1�I\��ۅO='��8G��X�Z����4���m�]
�l���G3��G��1�/-k�T���f�����~��g�/�50���kzN�g������#�6&�Mc�Xe�%����V(����D�|���QA��fKKW�gr�(X|&���'�!d��?�Gh�б���Il����6���ӺǛB�Z�\òm��ݡy���3Q�����ˏw^>/�SѐV�dg��aLY.�ÿ=x�L�9 "@L�e�ꫵ�OkBk��b�3��e]D�w�`�:ǝ��#Lf�oMIs���O��J�%X%�����}�ikB��b�=�z���n�[��h=Zj�[m?�;���]ɬx9��T���lk>ͣyX-o0�)�����"�e�6*����ђ��D��4⤰C��m�9=�&���\��#�?1#�@m�\	3�4����|#M�}Sh�y� ����%N'Qr��!
(N�*��GVE�?�P?�?8O�Y/�BDT@7E��}<v׉<��W��./����8�4����`��"�~ ��t��I�S��w'j#������L!�xxx������J3�t�|�*+l�
ȹ0T��	ۼ�L6��'�x�|)�-Y���_ �JF�@�h�M�U\�1�h"u\m�o����d>�9��/C���p�cD���͕s1Q�N=y����U�il ��i�-@�m���s�L!%.ڶ|˵�x��*�ף� E5ǪԾH�P�-�^r,�z,�7�����xe�Z#4�N�Ά'�x`��9�$(��[������c�:���>�FOTO9ፋq��j�\�V�4#� e��!�ZF��ԭ?I����0M'��XC�
���6N�a�~���K� �|���څY�ތ��pڏ^f�A��b�=Q7��������Z�]�]�~xf[��[��s�^��"�FhɃg{����`�hX����G�osw��f�m�]�Ts؇s�l��4�8�Q�̍�N���y�Bc;� *�{<N,����J��7Ӈ�B�邂��-Qa'�����K�-Ջ�s�|JoT��g�2�e�$0���
�(�љ;~�~��$��9J�)$���*DT�#9�W�^ݛq�+��T6��xx�7���q�w'
e�A�}P�r+/��M#Ϯէ�4W9N_�S���?@���Q�gV�t��Bx�I?�Q$���X�O{h2�4qcJ��<�όB��9��d�O/����<�����̌�zS��39V�X�a�&{�=f.��Vc�!�?k�W�5�?k���������?���k�����cN�?G���!���|������?_<�͑0�7;;���SЛ���1�:���<_� ��Ǟ_��Q�>Gb�>����1ʻ�kͦ�{���~e۪W���kj��t�+�&M�w������LV�������1�6�H)<�hw���<��v��;;*�8�{����_�,\{�.ݳ��a�DA���~f��@}�����77�N*Kg'1���I���I�5�k�o+�k�� ����5�k����9H_s��� }�A����5�k����f�d��F�1�lt�DҤ��uP����%P�믑�DGlO��2�B"A<
�|�3�ø��VUtւ���U_���]E[����5S�k���L';�&�:�-oQn���07��MT��U�!�T�������#Ά9:Ǧ�T=��$��3���p�~��}��d���-����G��)T� >��Q��;=�N�%彥�A���}�}�ż��*^�7i�4g�&��?�0������0&��4;���쎐 �S���l
�;&�_!ekV:��R�d%�[$m����d�Y�H�uL�HV64�H�����Ŕۥ"��n��䴿y*��c�.�"-Ku*R�H��:Rʴ��>rz�}�QY�g�P���%Qߡ�V�����]�ӎ���1/J�qH�=,��#�u���)ssd�UI9�<�:�J�e��p�G�Kq�Q/}���zs�̗b�rB���Rzca拟�� �� 	�L�A|VAnK��&h�v# 1T��ｋ�M���#q���ߙBn�ｚ��N��9Dťt��n^�d�.V����b�Z����hxK8/�c���&��A�����@�p��\��yVΎI���-dY�<�j�������*���n�@�k$O�,qJ��ΉS7O���E�X��M��U���t�b�{/�f�,	�=�1h1B6��k�X���l��V�as�>��+Uܨ/�0{�^yϳ�jf�� �{���l{�;�A:�]F#ey��A1����ƶ�$����?�m�WJd����ǻ���1?��ە�O��������O��������+_��~����?p1��O�o:��mzT+#��=�`������Թ{ve߆Y�1W�O�BHG\��r�yUܺ�A��T��VJ���mo�r����Q�B��2��������'G�o7�?��|]���35��*
��=���t�}�BFv7R\5�i�����s|�=�{��o?�Ϳw��k�����Ϗ6�����������7[���O�[�������Àᐲ�����~��|���T�0<Q�����7�5~Nw��r���ّy��;xA�y��:7g���n8Q��i�T
�j���Q�*G��Ǔ@O��}\��6%��k���V�U��^,�B��YR�~��4n+���V�A�ӈ�]�����v���iz�{��*��o?E��7Mr����=��h�@� �spZ���[E���V���>�f�:���t��G�v���c�88��z�y��b���io�@e�9�I���rH@k�������s���KƳ��i灜��>����jl"�f��������u��?T���������ߚ��#t�m4���c��`���O��8��:˚��&��߷�G��j!q�P{�`�c���uSg�s:��/ݱDNdތ(��3�c�3�Z��]����O����{�K����'����������v���y��%��V:�,)����q����Z��x>�%��n�Go��F��������h�?����vC��s���K��o�V��z�*�Xw�>U��'�۩G�����y��]��o��/�E�P�B��~�xN�z�ߊ�4�j88m��l�<�M�/0�mv�,���PmJ)��i���Wt�q��+�ާ*��G
0���gOg�ki�׈{���M�@�L&ϗ;�370af�i�~!$�06�k��O�ᢃծ�f>p1����"��?����#[ho$�E^8vP�J�RC�Q�q��q����D���ē��+�[��<�&�,Q�E+:+�Y��dyq�#)h^t���	Z�I��z�&�/�^q6i�$D�ڍ�ߖ��j�W��K����ଉ��QBu6%v������k�?� �zM�������h������{`�˙�X��tR��l�0�_�X�*�y�RB6 �F
������0�u�8�KN{i	mV��O�mx�?�?����Og�����������V�����y���:jͷ\(E�A|�h�[Ʈ!�7���̶GNci�X�ޚB�����o�$�X������ƙ7�]�V�|Y���*Q�����j�O����Z�ψ̵���_q����Ξ�[��;_����E��қ��������[�{/gad����O8��,���$�`:�?��m��܊�mP��ϰݼ"���]��[��W?)$.{ő�){s��+.O%�Cv�8C�@����ZYv~���h��z���Hl��X������ҷL/��Ks����fR�c/^Tͣ*����(-�w�|E	R��e4e�ٌF��UKm�ԭ$����"р���Fv����hڗ iJ$�%z��c�K�47)��I��ݫkUU�Y�5a;��v��g���l〤yJZ6���T�U1]��<}��&���E�Y�}��js�]�L�f�a4�Y�LJnͪr:��l"@L.�	|���atB��w"��]6-�N�9�ȏm��?�g�x�fJ��^�p�����Ko�*��}�,�����{FGLt�=wy}�c])h�]usYW�N�U��x���{�����.j���L�<FJ�#�@��v[��aF�!D��4������̚	6=�ljg��{9V_H�@�;����h�#�|�۾��|����
��3����J��"��i�'�V\lod�Y~V�Z���t���St��@K��y�$�#�6�䣯�\{:��e.}���'�i���Na���i�~�Vr����_=%�zx:�����4�ʜ[���s{��b1�>k����R<G�P��%=?�,N&���\}�\]��>�?��9�D�R��k�'�;o8���_�899�Rmņ�ke���o:�u�9}��C��T�L1�l�lg���L�ui���L�`�����T�,n�S �d�� �F.��c�(�h�fg��F�[y�]DY�£L@�?|�� {������3�R��y!�d�5�I���X�7�a8��s�tt}9��֏���0Z'�Ы�H+�����Ȼ��.�;	���U�.Wx����*D�T��)wa��)8�p��=b� 
�C*Y�U<BR��|���!�1e���g�9�W嬼�&��X� �5{��pf��s枬Y�Ks���������V+�N�_�+q%'�(m�J�����ߠz�cى���9����o6ȧY���µ�CzAWx���t��:&m��\W�c�\n�����#91�j���\�o�M#O��%��2�Y���>)��j���
�_i��1�����|R,'j՗Iq�r�09���������O ��G�#�����yN���G�S Y��G��Thϣa�J������uk*�ߐ�*Z(�v'h�@K�lw����}|�Jm�9:���M*�@��-��&�+��%�'ۗ�煗tY>M�%���S�xEs|^h�INs��=�cZ�2��u���4��Bs7k�m�</��+�:�ϫ;б�����Cx�a�=o��}�T10���L?/��+������
���̒�U�^��P�U��sQ�+��٥������Al|^�������k�����a~7�cG!�8/���G��s��\bt��ߏ��=��-9�ݖt(��˾���3E��
-uD��W�=]o`�)08m��[�� � ��,|�Nݷ��.��JJ�8��В�\m��$����O8�DĹ"7.���$����j��kP���^�Y��K�m)��2u8���-���������7Rǚ\_����6�,U#��`3b���@72J.�i��ZԖ$������1%��=�y�QH��|����|�a��S��zD�^��m�,��ҧe�R0�������
(寍&�2��Tl���߀.��Z�X����4��?5������\,�̇_N���Β���A�Y����}
9n���^�=�K��ia�Q�ٗ�s���3MR� ��6Y��UV�᯵{^�"�\�m?�a�q��&%L�v�Z:)&�dBz!L\�S�3��|���S����Sx�~F���Fir ����?��4%�%�;�r���j�s�@�T5�K�̱j�?�\�%)h��yC��0�Y��ǈ)��G@�����*�90�R��������,�O{�������	pF��Sz@�zC��F�w� 7D��@߲���lh���3�o�]-�V��z��H����6j���G�/َ�Iц�k�<��g 7�v���RX�e��~�s�~z 2�v�N�<FW
,��~���O(�Z��f[���d�L��ӄZ�J��0�ˮ��=3�;C>��b�pH���Ux�\�lQ�l�3����V�m�=� �O�P�C��B���a�������x��y�=ރ3�\˷����������s��5@��k�skn�!�MimI�6oR���hY��}��o���9�X��`��t9�����xc2�����͸��g8P�
!k0b.�e�P͏�<��gX=�|�����	m��I����
d��3��|�W�4�2�Q�A��D����Vbŝ�����9�Ƽ,��ک��p�Ve/��a~c�^Q�S��M
� �`5���1_=AI�Mܢ�FJ|�U�P��nV�A��vAh!��e�2V���-�� ����B�^��?7ݿedk)\�e%�G~��c�v��6L�)�_ۋp��S�� T�1��b���W�טY��tf𠇵N�z��ʪ�������
腋kp�e���a�_��&{Ֆ�3}��r�K[�y�����`���{��uK�h0�
}�܇�V�*6T~���<p}�9��]�<�T,x2�.��7O�ג--��3���2�DؙbO�s4�w� U&q$�/�-���ϸp~֍=t�M�$�	��i�OE���>�YV�sK�s�]�/��r�Y7%��#�f�REf�~��$�Y��-=uSc�R\�v7���Cn�!���  ��ԖJCi;30��P ?b�(�Q�7ߴ���+�+Z<��"A<<W��~�!,�{)(�2���q.���(�xk�����6���1�J)�$g���R�9�g��{�aZ�{�c��]�ϩ!Zީb�k�~���Gr�{�(���Y������=���3��� �˗7k�kL|����e"�9��U�7��~8@ODN�W����	�VW�u��W���^W���MG{����r�R�@���x��l^�gj�G;�� ���%�n�Xfn"5K�Z5���̙�
`�������}4�*�ҋG�vK��}��xݭr�&��s�g1K}n6�����d�x�:�������Μ�!5��NҨ�v��ku������,h�fK�ʂ;/�ܜ��;�pɡ/<1��~�˂מV�v�gߑ�x�Iv�g]�w���R����
��_$�Nx5���$.��*���}@�#e~��ҫ�� �s���Y]��L�u�ʟ�eګP��L`vՏ�V��U�$�Y�wL�>+D��Y�~k�Gń���/�>��\����iC�;ң�3�~�)P��??�e�?�M��im��P�Wt���x<46�����t�s0� ��Fa2ќ>��UcX�k����V��fafU��
��\�Uc���v�U"�����`�
0���EK�[�s7�\�/pÆ+��E>���	r�����8�FG���;K�0
U���P{E��:�-R��yq�g`����(��,�==��}�u���>>|ӭ���)��𩦽sDJW��(n-���U��;�ƻ0Tѣ{���<��������"V�/�h|87^ԲټU@�x�5f���)��u���������s��Uz�$|.t[)���ȝV�&UHԝW���*���n���Fm��m���{�7�ܺ�Q��t]�?�7� ��룿��~�c�c����˻��XEٺ�x5n����RP9�(|�*�0�x↵/jp ͽ��m�$;��s�sS��hL��6<����.e>��M��٫)�}U_��P���3]����n��҆4�Pg�_�&���o�k��c���x�!iM>L���[|1�����(;gݘ�;g�g�>Tn�#���fcx<`7�l��l^>���e{q�q̐�揦�%gї>b��5RWQ�mЕ�rBk�T�x�^�
ϼ�������5���׾��g���|_����d��ZY]}����ԓ/=0�����g{��w��b}�z<]_����+�OV����o����k|T����7���^����޼�P�"AUs���\����'��i�5��  �`|��g���Y���UE�(L.1�L���k M��wR�o�Ziv�~��E�]�C4��f�Q<�`��0��H����)f@�S�����8��ͣ
P~�����=�.b$@lrP��0�ě1gM�>Y�@d�V� �ЪQ��PLO�7}�)�[��4�aD���p� ׋�S��d�>N���	2����;��r���y/�;���/S�g?��3���ٰ�Fx^�=)80,Z�2幆��$���zy��B��w�&g'�(��>�M�,��Q�Ǡ�#frHj)�?Ī]gY8j6'��	��FW�r���5ĕA h� 	�����ޔCd�9s2K�b(lfV��%��hb��R�W�\�n��a~WD�-a".���0�ۅq�?�SL�"H�B�Ւ��0�4%L�R/#��pp�x��/��y)[�9x���I0�b�}��|�l}�Q��S�-� N\W�����4>�,۝�1��
� R]��y�a����3E����RB��E��^.CLc�8�b�M��:�6��ǣC 	3�]o��p�1�H��S.0�ְ�����}#���n$��8�.(1C�� �_��$&�������N�n��΍n�"� ;���cCܔ�e���
��X���x��بr��UjP|� 1��%7��`X�'�"�#��+���C8���޹=�t��u�W*ъ��V�H&;�1�J��(wM�� 0��<#�FWƕ��/'� PC���5t��A=^-�� ��b���f� ��UNC�
��X�	��\���A�Ą�`�
�8Kqr��5��|#X^�+�==��aދ��m.b��Z�H�&9��Y|��n�q �����pw���:
��]�,=��l�`��PO��/M��:���z\H��Y���g���P�F�Q�w|
���:L�9��.��sg���Hn��4���S�U U��<���3�#�
`;��Ndm��J�t�ô�3�Hݑ�����툮��_zT��K�=*f	�t��l��i7��	����C���윚��w ��,J��De���b#�D�	�� &w��D��" 	c� ��_�$�	�OTPf�e*�T�|�  ùI,i8�#��zӌ�s��a��t)1�F =
����q��-$&q�2��H!���xE���i��:��-�'���;�� ��,0����H��X�_S8^z�-�<A33Hf���OOѼ��o��"K�%�4��O�,�0�4JdT L�'����˲�Lqwrv�/D^����ag��Nx���*B]�m\��9y�p�@f��I�1(8Ɵ��a��
�hK"�ߺ�p8M��&%d���6�����P�i����N>�r�	i�\(|?%��B͋4�,f�6�G$͸��z�B,՛�S�b@\��@[{XNaHK2W��UK$�p�,9�=��(���)�2͹[G
�]c^5��h
���w$¹s����)�(w8t\���0��n�օ����G����WGnmo��a����ޯ;<���)�>E��9�)�3 �U�X�����5��{� ���"5t��Vi6!-���(�E��3 (a�ތ;u��6���O�^��/:`��R�z�JuC�L��f��Ö��[�[�V5y!�k�%5+��`dW�.���&&k��d �c�2�9s�*T�pL��P5�|'�z(j��\C&�t+]X�!+Lu��� �z\��c�D(}F��؀�\�VB�0���)@� �zI��WM{jԱۊ��j�`A|V���b0����)��'��Q�Yd<��E<׹OhBZ�G�
��K�S8���]$�22:� uay��	���W��S�p7�P� ѧ��{����m:�mx�M$���W��.�A{v �DD �?�34t$���2M��4�KT@��0��"�c:�,��Q�&	� 6�.��~�����C��FQ���)�L�hC��ӌ@�����.�D%(k)�
�$3$�\!���RQ���,��� C��`�BL>I�<E�6�Op���K8��~."���麘@4:c�/�U;$��(r�@t"��Xݕ���$� aR=�k�!��5 Vn�"�/L�l�0}[tK��g�$V�d���BI�a7�I����$�آM���D,yU	���Y�)�l��0ڌ7�-����a�H00�n4I,s���Y��&��N����Ơ�IAE)�H3�5��-%��MT=5ϯ9�hMTe��X�F!�҆�\:O�->��aec�Li����(8��ge)֡���=BQ5��j[/�}�YH>�L�c����0v��ZQ2��=g��0�I�ʖ���z��KI����MG��OËDǾ7���6�e��7���������XG)�z;N�(������7�P�Y�D���Q��#��!�50��Z!*��u�����Wz��!��� �t��><c"����	�*M�Y�(KH��H P��iNg�����>bX�b�*"��(����~������%|UF�0H����P3�%ք����VEM��\
�~���U!l��)fD��`�=h��I|�ǢD�Ǽ4 ��3*8c^O!��Ą�q��^ב#��p�X�}�`����Q��Q+�ў��)�ǖO��}aj�a�w3���>LB*Y��0(��R��nh�� π�i�Jd�NChngd�M���N���h�ǀ��PT>+7�ֿN/Qkm�j����i��x\iQ�J�$MY��XD$��6*k��D�s�NXU�	\L2����2�/�ǒG�*XZ��10��$��ƥ;QM{���|\e7�G��˲KA���bORؘ,{鮒p�ez���t{zj��Ty�ڀ>,���L�v�@�S����QE�pB�c4M�K�.�� m� �a^%�c�18^�P������j]������)7�ɠ�E�¼[�H��r�^ww7,�Q-�=�� F˸��Z%e:0
	�����|F^�~� EH��B��۔���O�`�a)+-Z�c�B�P?plT�&�h���߹�!��d&�&�x#߆�iKY�����yW�qB�2puHRX��长�����Pg �#�͉.�#�X<�ND����������E<�@�������BI���E8d���%=��uB�`���<"�8.�h��z�r<(�ڢ/��k�Ϻf&`}C��B���v�o�Ym�4�ԣ���yj|g�ct{��a4e��|�h�
�˲�Q�9���(�����e�>���K��p�`��9OF�2@�	ȋJ�dҊ�]�ne1�g�!x�Q
�t��#�`#�476w��Md��"���p$h�N��p8h���Gl���Ć�Ci�A���i�1x���h�md��c��FԷ��.	�Q!Zد�x�,�$\�4�&��g��Yo:҅��H������(�9Z9�:"qv��x/��`������7G��\��>n!�~�7��`����+\�p��&��uG��^�m�R@*y�n߰}����6�w�����	�!�1�9F!8�j07�
)L�LN��Ge���U͂~�>�w��� �j-G뮭�-X*���?=�3�@xQ�"C�F��b�'K�����s�m�0�
>�d_�eS��+�M#���4R��[3��S�Ʉ$�U�yᙠ�ؚ�bB!�쑐�x�ӠxD��c�7D΄�h&²��iŁ��T�Y��L�e5���DIG��qI6i�qg�j�X���,��̬fiӂ�դ�[o9������d��ˁdw!\zb�H��%�f:A�5,�x:�&�I>������f,t� ���#��K��\c׳�Ra����+�|�Hb� �M(�$WZP�xra|6}����(fQ\Hз֩��ԟ3 Y��4�^Ĵ���ܞ�0������OT���U���Ek��H���n(�HQ�i���]VwSP��A@8��O�p��Q
m���	�!<q�mW�v"�u��s-�%AU���a��ܱH��Kb{�F1k5��#"�]��XqsE⦡�]F����N�+[����`��#c%R�(X*� !v		)��C����xO��y�%V���	>.����me�̷ZT��lG26z�?�B�7!�f��L�W�1BZ�%�/3��c�s<����і�PVd5�E��Q�#	B�#+ ���J`�p�c��j�����LH��ԃF�Q�$���цl�Y���w��61q]Q6)R@��� aA9���u0w-���N�W⳷F�T� ϱ��Q�Fa�$��:�K��������1VZ��j��"z5r�##(3/�pmľ�1�bO2!c�����%W���y6��Y)>$�s����`hd_�b���+'^8..�vN�{|3��(�'�&"�ɋ;���>�)Y���T�uX��g����7PaDe]��p�7��T���ܑZp\�IP����o��%�R��㥶,_Fh*�f�d9*�	Ni	�C	ON# 	�$��������"����T���#/=�O���4{!�:G�+=Xߧ�4 �.O�aE��+؜��7�T�dbX�e��2�:�L��&Bͫ��:+�4�OId+��n��
�t@�nC�9�ίr��%̋�,[��ӢG���F�0��]��D��/���J��ӌ�g:dFك=@8K6Z��y���C�2Q�POX
l(��,�M�4$i1u��n�&�9��&�̭2��q�L6,�Q�L�	t�C�L�Ņu��ᮔx2) �7��������1 #9j��Q�<Z��CC{HIr.>J9@�Fp��4��v��>Q�r}"�X��	�0$ن��z0�Q�u�{ 	;�TT+�	>;���.ݭ��g���(�b���+ÅCe����\��P��zaN����RG8�uT����n{�𙇚�c�H�	�8���S+�8�����q�=��g���	K��TZ.���~�Y���Vjg��n�hT�q��	]���9a AL3�260�2r�(^��M�;��2���HD�� }R��p�1���q��א��/�e���;\vk͹�JgD<����H �c�v�/+�"ŬuQ���c����(�Y�!A�Pk�+�.Ù���Kq\5�$#��9�|��98Zm�d!h�	c�Z��%�aX��[���m�=m2�S�<5S���(kN�&���_&�O�0����	��QP	�]�'��"�P�/�FLm�0d��[�c$������*�q@#����tR�f�X<08ac/�>bx8<�;PAspO�#��{SJ��	CBc<�a�Ck4�CS�`>��AM��c"��	�Ҭa[H�F�,����`���Wuc��8nӈ�S��/�Un9���71�a_R��ê�l�N(��Q�6�J��G�M24�C,a�dA?��NS�*,�^ؚtx��</R
[$�#<��6n��n��b��+T{��-�WL��$+�E�e��a��N�G�`��~��m(t�xt@BJ��7�����Q�EЈ����)J3�(;F1�r�#כ�� ���X� �z��4/߭&�p�	�&Y �@�H�&�Ȩ�f�H�
�P$�6���M�����A�s"G0���77zQ�Ӆ��GW��L�b[ܾ��DF��*Ҷ����)P����|�Dy�C�P�O1T1*�q6N�d��@nk�����
4�ĄԔC%U�� ��x^�C��ӈ�|�dʇ�B	�xN��D*]S�&���aw��s�r�M�j���66ȑ�9st3��dvꮜ�(#�:j�~H�v�Z$���qF����q4�Ɠ+#��AS��r�y�aN���$�w	8��J�����zQɔx�zo����u�0*$עm,=d�	��;fl��I�`G����N!��ܳU�II�f��[q
�3�f�15 ���;�w�&l���G͚z9B/
 �)s�i�eG
G��#Bh���c#��Cg���3�%�WA���<��E@�Q(�N �~?"���y���PH����RhwfiY��Pĭ��[�1S���"N���G��J1��L{�8fl���^��HB4��
3�YK�d�s�����3��ecaY΁.�+G�?�
1ó��b���Ի��H�\AS�
���4A�9�3��Ħ��j}��:��/si�j�yj��En���K�̛:�qV�q8��� )�0�8�'�4۳.�VP=�9���t��Ĵ���H�3�In6��fN�q��]C��ar���Ķ�R�F��+���[G��1��o+��D�@�?)��6��*VAW*9C����Rx�1�Ӯ��̀6VU���4B���(�\�C��M�,�H��92��S��- ���,���V3�+���R��'5+X���,Dz����@&�`��NQl��X�"�1�>)?�܇���{+�>lo�5�m�L����|�߁��� 8�c���4�HY"8[fdǄeD���h�����S����cK�H�����B����Z�06)ά5� �\�>!b���8�g(cj'ġI7%�%�0�˦�8�gv���v��r��ԻVl�a�m�%o+�����ҳ{%����xbG߫��71o�)F��x0��Y�����f�ΨQ��#��آb�sV���r�zh�0<�Д_�S��asd���T�!1�č�6^�N�{�j]�;att=`�QT�0�!/&:[�
Qu(38=�c���#�5l��h��\�$H��~.���{�xauv&N�eb�Ջ��x uν�e�e[�F������Y�.�H�6Ǒ���@�ur���!C�pM�1H)E����T.��`*Wb+F��F��wH�jb�L((�78w9�h?�>"yk욹��}�]�Gs��C�Y�	�@T�%9Z͊yYY�g�*&b	��p�6 ��3�MJ����P9 I��@ ��l�2��x1Ѯ����*�b�ҟ��w�i��y�gߨ5�mÞO��]H�ά�6
.���A��h���B��� 67��A!#��bT(!�_C���N���z{�QA���	�F�����OTCT�.�a�r�<i�kh<~-�%�Y�6 DQׯ!�;0�[���	�#ܸ�G3#�Ta�$��ƀ�0a�`R9��j��:�{n��V�Mo��<�'����F�r~��D&yU�tj�s���"%n
0S�"���a+�����Ze��k'(��w�߄J��])"ND�S3������( *��}��z`�Pv(�e�j��+�H/�*�.�c�O챹���!�h��*�h�t�� �g�m�rP͠Q��0dW���0�tE�I�Ld'(à�.�)����t�E�Et�T��~�fG�3�`�\��1�	|��$E���anBk �L����,�֭�k�zSq0Z�f}��H�glg�,}�_Kg�7���=��b搡�W*r�4Ez�Y
�a:���lʧ����iL��"g��K����jNڛ�O��H/MM���+Ъ��e��e�fp���"��X�f����P^sF[!]B�N���]�#J�9\E&e�yI6����n��m���CɚO"�x!B��1�L������7�7ء��Y%'���z��� d��|"���*�1�4�H2�Ys�;���-9[�b�Jrh�35v8����`ڐ� �+�a�5(�{.7$�()w4�&"Lo����X�M��KT��P��V�W�㮚N厀[�/�2ѐD܆���,�^��|ʮ�����ςT'�XdӞ8/3���\_Q#C�5�:����'������z��ω��TM.x��b�+�|Kur�-���E���Q�1��3���ѷY�5��Ǭ��U������h�E.w�H��-v�G�`p�i�q;xD-=���kag��C��ا,J6Ð�� �}V��Y⬸e�g�����%Y�ż���:w
]g�	ř��;�O
��%�ϰ�h0�����,�6R�
*מ7I34��BJ>�|�{�%H{�!D)�����Yz�S�:!t��e�RǬ�JW��N�	�&�{x���Xjr$�?E��wr�`J�M%�>;�J|�������4�+Yᨙ��l�r��P��(�I�^nQ8��>IV��jK貖��\�V�4�����Ȉg�Xt)'�B�/0i�0�W-��V�46f<���ink�D� Ä��ڔ�39$^K[�]v�R!}��x��S���:�6hi��MÞ9�;�HY��O�S`�<r:;N7s	��&%<(�L��A�BΑ�XqQZeD Ԟi���!��
�%}��Rz+����W��-�Ґ�L�5[��Vh��E�c�4�1^46�����z�r5�g��;�!,$��)?�U�a�j���9���~	g� 
����,�K9��N����-��U)�$ܻL|b�!Kgb�7*��Y�j�$�H$W�<@�H�S�~�'l��2HE}i�*����vK��eSv.ѐK��T)��pQr"']�0�?�pkOֹ�m���f
��;H�,]��Rs�c�g̶4/�n2;���r*��XFFMY�C����P9Kmfp�+0�"~1� S+��cܤ΋�/LIR:�=tL��I!��0i�2��N[C01U4�:��:Al�\ahs���ҹTEg�+�
e�Rd�N����pw�0�r��c�CåH�(R9����֥����6�Ȧ`�ÿ�E.4���<���"c�&�j)���,%�6�<�_�������������QX�P��9��p���h  �ɹ�J���8��l�����i�Y,6�4��+���u����f��Tpd��0�t�u-h!�p��:S�:����ntp���ZU@�h�����5c�#0�����jJ%m:���x���6���|�8��^�`����6�D`���a��,&��fW5����~:.��s��82�a*��E��e�����X2��N!<�H/6�G����|���x�ĒC«U��1Y�4N@'�R|����NQ�� R��Hv2}І��W#�sJ�CAz�RHim_�"�W�/d�P����e��.inH�5�2%�v���І��%��S$�T��L�L<��� Z	�Y����J���y�K���:3tB�8(őC<�~U�戚�#X��iڹ��䝭8��H��Ed#�sMAPK��X��eh�熵���Q��ޙ���c]Z�1��L*&�M��O�i'T�d���S�M��:3�WW\S��C���Icvw=�z�R�ju��ŭ��5F���1H7s�ӑ��
���Dї:ejY�T�nJ�a؝�ȏv�u%Ql�Џ{&,_wQ�r����`!��b��64�ݖ?��Mh|��R�@����h:������+U��L�D��CKMݾ&�d�w�?2@�Ì��ME�&�Ғ���uv�]��.h�XBE�q$�L#�8g�3rX~PŔ,���m�f���d.��Vɨ��hdx�9:SǨ��cn5���-��R&�K�A2�w=ŝ�@Y,�����%2J�	͍��'$>��Z���W�N�2Z`�r�Z�n���S�L�x7H߫@A�:&��DdW�c����f����1�������b�F�2*8��u��qήb|Yo��v��6r�^*�Gp�f�Eȑ�R�,hr�z݀1=�Y7�9Cw������Fh�r}X!ig��敨Ec�"�G�A��B3J�t�_gB]�K�X&��v�L=am�2*	�MS�:�n�L�����
Lp�ĀjiЄ�~FWa���Z�Ĭ�I��i�u�����08��lw��gƕ;�p�*=������(�@c�5�zxX�)����	�]E��7�l�X�<�^
��Of|A���֬�aic>\����D�ʪ�"��3���B�u<?�~��1���v�ܐ�F��/	A�oh��e#;��Z�2��U=��-�f6:7p�����$��p����Y� �VD��d�Tܨ4-	�e���CJ&vOZ&4�Q�	g��{�U�Gjo_��9<����^����p����nC����w���A�pw�����^�tv�7;/w�j��ޜ��݃c�����G�?lu��q_��S?no�}O 7�~<����q�zg�{H7T��wzQt���G8���[]wL��9�a���ǯ������ ȏ��{[��&@�?8��  ��.��?n�m�ق�4�K����v�af��x�`o�VC�� �����k��y�����j��>ރ.h�:<��7;��������Q��x	,����_�@���t X]�����c_Μ�&���q����Ζ�(�P]��}��<�~�m`K����nW��������݄�vTG�÷ۛ��݃��!�����!B��c4z���r����Q�L1���o?����Jv����D�X��;�vi��~؆����P�z~���#�ؾ����~��"��������Q�
��E���}\��0�m� W	�m�����{�`��%�ut����?�w�G@�^��#�+n-< �{�9y�7p�4�@������jg�10��w��}��և�=X(:c���7�pް��9z'p{�w�KG|�p+Ї���Ug{��a��}XBI���8�7�|��
��|-ۦ����z[��:[o��8J?0�mY�A�ud����w����JI*.��{D�d�`á��6����H[{�>��p�
W��f��J��� E���S,���?�)���1��)g�bb��#!Цu��C̟���,~��_�Cg�6G���^n�M,�¦;��~���b��Ų��K��7��k�שCK��\�:��Gdy{ �� rǃ$���.pio%��r�xHdg���N��2������a��{�dQ7a���'�u6�Ct�&�F�>	�"^}���/i�X_�F1b��h�W�:e$�Mv�<��p���ng[P�f����ލ��_b�t��E�	���AI����H�����ʲ�E�8%����z�`jj��U�(�
r}��I��o���N$�O�8�%4ŉ�@�z!U�����YW�au���Hu����X�k�a�vo��ƽM�'Z��U{�J�a����3[�oh5�dZ�q�~�짛�˚M�z�<��U��^�I:���d��UiQ��r-�=3y�XA�`i�%V�vU��`qg	^�
^Gk�a��]�&�Q�p��D6��u�K]9��]KV�1�!RߝO&�v���u�L[iv����0���aҍ[���0�$�7_=N5��Η�	V�»B�1F���\F9v�P���Ɩ��r����#�rF�W�eca�	�m�b�n�^,\#)��I�/n|Kxȥ�iM;/��w�ww~t5�g����jr�t���ÖW<ϖu-���&��M�4��hcIx�v�{�-K�Wc47��P�[��h�m�?}[������a�Tj@��ql[���F�X�B�τ��f�V?�kh@S�5�L��釚���!S�)�ZR����
#�^moA�7�EY�b�P���׭��+ q0�.VƫY7�)�V̝��O�?8|��s�$Kh�@�js���m8���Cʖ�9�Ƙ|8��-D���6��R�r'W¡�!�e)�1#���J���/�u���`�L�E<4ds��Q\E1Cʝ9\۳�]�X�K	/���u�
.���e��{%��
o�ԡ���t,��܊�y�t:>�j_�_5a��ó�u>aw~���駽�a����m��_��������
�����we���g}���o��㵧���O֟�����+O�N�|��x�)�J�Fs�A��`��<e��'�<P�o���(8�˞�(�!�Vnu�v�	�w������D-�RN2���$T��@��%�$J.b�O��t����;�Ӓ�6D����Qgh�`�Z��"��:dX�~��a'��[�hH	�8�	���=
N<�j�)�W�^,�)�8cP�����@�Փ̓9m�OC�y�l��b�f(�Qt�~ ��z�����nM�[��e����3�-G�u��lP��XV��!u�'������Ĕ�R�(0�v7r&|�F�Gj.�7�L%�ѣtڇA���G�dY�6�d�M��\8Ɋ�4靳"�0-�v\� v��=�b@�dz��bN���y)��
���H-��}�^W�"�r����X�U���9�DA%���+;q2����������Q����{���0q0�a��O#�1� Ʀ�o�4��/�Ю�G�,��ΩW����Խ-����҃��L���vٸ��A�!��6��\�%�K�p7q9N�'��� ����_Yd0е�:��>�Ţ~x�`������RZ�p��V?��'�~���ӕ�6_)�.w�����������������?n<��B�����"̆��W��O�VZ�Rxc��W�j�1����FL�8�{�uW��&�����y~�3��T}��v�{�s�}�O��yc{f��i^��92����u����o����_���-E��BG��Z&�k�R�YT_�b68�W�C�*~���ԅ�<W[�Ҵ�.�8":avF/Z����j��2�:p�x�o�㢹�z�
��h`�D��� D�ޒ���Z�E��@@U����.f]��N���@��5�U�P�h�);.�S��`l��Y�C��*�/Z�/H��{�Gj�L�x2J�t�/:�W�~���Xq.�x��O�yU����Nc�ԧs;%�E�lVtk~\xʫ�ӂ�
��F��(�����¾��Jߝ��g�'7T{2�x�0=C&^�L	�sJ����#V����q�g�k�>z$��k�K�Ks�"C3�6,#����!�~���8Ʊ�2����Ohܴ� �$�(�����*:�J�����&��l���͏E���h���J	��H�ң>����cse����due����ʓ��#���֊�H��[�/3_���B�1�N�E8�F��7��:,�z�.��T)Wڜ�e����Ah�~nbg�� V�xL��=�<��?\�}���m���fdѻ����]���&�>�_��S��#o��b{o3�	�o��<����b�@!ߚ���=]����Z��ǭ�� ~����> ���S/γ�/���_m���r��tm.������W��WƼ�4t.H�kH�au�;��Mr�[��fL1�0;��mθ�52��Nw�[��b�[ejp������np��_�X8ߛ���4F�8^X�n�"`�$<�,E���c���^D��'o믷�:����9>q!�.��@�<)��G��T���m�
=|7
I�$���R�	c��y�t;@�$�)��6�Z��WB xߦ��'=�h^�������{���,,P0�O���v���<����4"����w��Pl<���t�gY��*~�ar�����nk|5L�<�!��r����|Ԓڵ��5���q�@ $��<����Z�ی��%��s1�0b!�/Qa���#����5 �4�\ ���2���U�7��X ZFRV�+J�C�4Gؽ��b�`O~�d�'o��ߔ\���0�P-js�;������<�z��Pl$v������-}�ͮk E�j��g��(E-�l���u��ۺ��jU��_���D��Tպ������Ȍ��S囃8���L����]9�g����y���)��>j"��v�7;;���^;�i;�Շ���>�;����̝�?�0;�g�<E�����2\��j��B3�6�2$�H�z1[?�u2� w>��R�3�����X��ڪ��d��QK��ʦp"�[���#¿O9L�1�
a��U���=&��'`�I�`X�xޑ�Ӣ�͝��m�2I6����ѹ���,z�Q�����1�Zw��y<�ȧ/��]�vi����6���*�\�a�xT�9_7�
�b�r�hx^��"���sS�B_�.�H[�)2��ր}9s������5lě�I�Y���[ٔ�3U@\X8G���1��	�\��ܱ�QئS����E����]"F�;W瞖��ի�	ZC[p��]�/N,�$CYF<���W$���-�^���
K��
�OB>��VĤ��h�,ԧ�lhɷQ� �(	4L�WŮ%���BaN�ě�}�:a���k���S٢	��U��<-�T����=�
M�A���G����=n�K��>:�Q��WٰRd@<PO��XU)P�a��'M����YYt�p긳�S�{�Cu�RZ}�W�ǛP)e.�EA����Im��4���1B"W����ȿ@�vVb�"�$<��\�ՎUq���!�3Gz�����O�5F�1}ƶ9��g�������^"訸�GñZ>�����d10��h4��O�gY���B/ڌe�E�\��܊�+w�e������Pc?�P����):p�0?1S�r�T_Ȑ��U��l,F+
Kc驯/�$AS����Ō�q�o�i�Lu�_�*+�H���JDrŝ:A����9u�ު��u�p�|='s�>���̆�쮒�9Mo׈B׮���z�������_�.��YWx���	�b���u�O��$����9]��s,j��S�Rah���B���J��Y+�ژ?ȹ�C�M�S-I�X�	�ϴ�ʻȲ|�TDt
П�Q#y��n��`�2��R$9�
�F�+��� �,s�Wo�YY��	���z_̹z��ҙ���1k������㍁��6OK�I��(֕>P~���N�8�ٳvl��1���n�����xO��Q�������p�L��N8Ȭẻ4k�ԩv2C���. �Ν�n�~��N�����O�~PWp<v�o���ߝ:ԭzg�N�OU*�㝭�W���6�1�6�Ł��q��dxns��A�¹�|�N���JG0n��7	���f�J>����Z�1��E\9�*���z᝿��LTu��{^M7>���.G��)+�lG�T����+�*qa��X1����S���ng{�b��6�<�^F0��I����>Z&$S��k���z�����
h{��Dg[���3j�8��� �b*�OU�m�� }���ٱ���+�8w>\�9PrG�Io�3)-o��b$������kkb�<��J%+H7��x�#��Nfw�0���V��C%2o ��l� vbV��`�I��y2��ǝ������W�;U2́�ܨ���z��G-g\��_�[�d,p������q�o���L_�$��FC3�8<k> kS[�{�h\EK�b�h�[ �����]�Z9i����;%M�\uXuǓ�i����IaVp"�&4����cí�|s�$P%��A�gi9�>b�B�~�_)�]S?�!B*���^	s��4^5<E�f�ͪם��x�A0�����%���YrTgE,jd$�*%�9����VR �0�2�R��ʠ�̓������2����L}�)��X�7�lT���K����%r9	ê%���7��>B�R�́�V�S���Zi����FY�E��(������\G�>`�������Π���{볣k³���%i��x��xn?��"~�`�r.����%�m� B��ә�t%"O8Dw&�d2z� nɐ��_�� u��Ε�7�Vi�P�Wӄ{�N������K����׮L���������Nw����/d���e��� ������m�Ȃ�Wߗw�Q2�$cI�Sr���c;iO;�ײ���?^@Y�,jDʉ=�}���������V 	R�勬8�D�86n�BP��0:�9N3�ب
7�x���'b?�Ԋ��(�;��m*�)��b)�Đ���i;A4(n&����R��.�����Wn�m�ASH;k.ͧ'>�7�'��RZ������i��+�x���6dmmF[e|n��w�Y��S�(��gR�*�ⴙ��}`a���OW1����&\B��x����/�>?>x��o�{�]�~�X�����&Vd���3+%9H�SR	����d3g?��)Hí9қH�-H�y�W�)d1\�������� �R&О��:��TP�2��u�g2^+{5�d��d����E���w�,�3�����0ť� �$�<�¨8�E�I�F�`H�S�)�M����k&͗ވ�Y��͹��s���s�!?�TI1Y���ߘ���{�~����x%�&H ����O_#��OF�wR�� 7r̕��X����,���j�lr%�6�H섎\:Ւ�j�s���FZX	�Nv�2�=w�G>��s�)�`���4�\�/�	�D7K�b$�D��+�w��8F�B�r4�{�np��VQ��g�`G����l�9hj�ZQ��F����������� ��8�C�/��GS=��E�{��-��M\�"-)'�tR��_������LCǄ.S��;hK�����Z4υS�,�k�}I*�7[u_m\��GQUK���m��Ͱ+�?�H�T�=��Ɯ��F���ծw	Q����mϴ�NC��)s+���~ŹK'��|��:��1���Թ�6�KW���/�4�����V�c��=�ѩ��,���v}E�x�������N��ٚ��]ڡj�j��f�mS5u��V[���:v`)�b��\;�53t/���8�i����mC��N[5ڮ�X��k�P�\;�KS���h�ih�VM�j�^[�,�Զh:���t<C�-�#�C��zvO��@�:��R���n�x���MV���(�Ўow������U���_C��Z��m���4�V�0N����w|�m�q(�R�� �5��V���z�q�2.�+T?p_�LK1<�t�2]U7۞��!	Zљ�k��mz��f�6�w]�u���h��k��ؖ"U+Zܵ=UU5��S��vl�M�����NǠ�jt4�`-/�'sUՅޘm�����4!lͅi�G7,K5��M�LM�L��z��M��b�u���
̐e)��o��,���UtXR%p=��aEM
�l;�a[���mꨊ�Ƙ%[����0���,�v pm�74űTM˝�!��FbF[~��+PHׄ���1;�b Җ@�l�L�4a+Scj���Eu�є�k��m��͟�[����b��">�0Ǧs K�{�U`��o�Nะ�4ؑ�;�ج	d�P���`fh`����T���8�8^�o����S�-�L�v\ FM�i(f��a�(��.�N���4vL�PtM�T�yA �N��:J��lŁw
{,oY��X[C��:���vږ
O5X&��-�5��SS����R�@��h�b�0����
��6l��<(�\�,@�p�yj�N��T���)��R@]q���Lj�DX�f�v
���=@BX�Ul��-�M��`��m�BK;� ��$�4����c��!��h������b�y��p}[�]��4���H܉�zjv�MmS�x�a��aul��1Վj���Z�Q|��v���ɍ�RK� �T4̓%q:�
�cS�-��8ϲ���P�N��;�E;��[�t���]�qu�񼶯:Ԝ3��	��;A�ȓ0�.��� �ؤ�3�ӑ�h&�}���rT��b����nV2\�p����SLj8Z� Ն\��ڊ�)p�ajE�����5��H�ȸ:@��vGq�|͍���z� �k{uΩ�m���n�<�m �Ĺ���HG'����l#m_���+�u��ۚi��k˵����X��h�o��l��o��ݶ�J�1|�T���� 9R�b�gV/�,맪��!�}ò���|͢���vǲKa�N�|Qs˴��h>�ͣcWնt�	�9���j�����)N|�C&R`k��Y�;�[��T�{(��#T���Tږg�@Z��];x�f�4]Q��k�N@�H�c*���Fv���w�����R ��#V�$�sz�f����tJE�|L�}�oQ�m���0��2����Λ�NM�aH��88� 0`m��ԇ�1��Wݤ��0(05�"�Kzm������Ȁ㝂��Nj&�VR�}I	y��n�~Ӝ����M�A����y���'���d�e��������� ��߰����J��k*�-�?}LR�����C�6����Jz�����3��sh�HG�ĉ"J��:Q#�ऊ�ɴ�_'�O���N�)|m�F5�&O3Ʋ�}�Ň�{1�Z�݁��!���
�k�{��b�xW�w�A\^>n�p�4��0���T���F���nL'ϓ�e�R��Y�M��p�'0%�lΈ/�]4��,7:F8��UmX� ��L������>��>�:�k�M�oK]��k@}lEP�����8 ���
�0��9A[�{C��6�v7?���b��$&/��3���)��L�[�%N���_�qM8����6d=@L(�_��KW�~��<���ް&.�sM��Q�� �0�/�|Q�}_R��Zf�s<���s=ǽ���������_6y��Ǽ�A�/o��Vp�ɨ�a����f��b=g�Wt3�`�XxJ0QG�*�R�R`y{L�m ��܄�/�̍Rhy��R�rꬥ��5ΐ,��HP�A�b����*��� �'Q�-���m�
4�e�fm�$xh1�tjX�YW������^�ͼ�tL��f=�����
F*W�Eϕ�����9�.b�ݥI�<m�x���R���K7����w�Txr��6���UU3��_U����nT��*�Ҷ�7(̓2��wb�R8rL��1Sf�)Yv9�<���J'�� !�4���F��e�CNmU��O��p���3���3�ڼI+��.F��������[�<�����䠧v��O���t������+LX�/������v�k�6}ɾ8�|=n�%p���,{(���Ǘ�4p�M@�b��0���ʞ���
�CKެd�f].��)~.�E8ɻ�Zr��!;a5�l6��o�w�� c���7/�;!|%^]oȒ���{�.o*<|r@�*��`�'f8�0��8㊊�cz��$�h��'0�bP�\�U�~�~S6*'�/.�k��#�p��֖J=a�9c͈�d"�՘m3�J'��L��p� �X�ɠ�7�x��5?њ� �7L�y>���w�&ѩM�H�#EEE�}���yk4��]��7������l�G��rswog�I���=�\��jg�U��0ߡM�`!���)��0C���Z��F��`+�v&}Xk%��Xt����`���{p$6��$�@������;����1�~���Q]WE�+P�q!L�e@J�;�7I<���K�8��Nxnn�󚴩�/׺���`��w�J�M��XL���
(�Tȝ[���=MJJ<�:(T T��P�pI�O疗
���-+ͼ(�
��Ψ˅�|���\!$�3� S.$��H���9-L�<��O~�K��������2����xvs8�_a���R�F���kf�:���צ��Y'&��Č��`g��n�Md�&�#zO��y�AA�3�1��W'鑴h����v?d*�-����;��Ln�_2���#�JLÒ�a��6�0�S�9t����L�0-�]�C�W{{�G;�-���!����i��Rn�=ù��K�8��.�I���DCQg�93mF3��@I�0�����������8�,��Р�����ջ���ѳ��fՙ�Tp�f $TΠD7��Y�K >v�rf�_i˲Ƨg_�3��p�L.�n� ��%)���`i��l����$���A�];䈠��������wgZ����H�j��mc���f�F��a���a�R���"U��e: ���7x,;I�n������6���u��5��y�]v��1?K�݄�֒\d1���qPe�?�̺�3f���nX��/TTͶ*�ϕ�ǌ�K�m�|P7�.U��|���*����,��f<s�]�$�&�<�no�Oֆ䠘�=�A����.����줞kn�c��,?�TnX��6�����+���bU�����x��y�����h����xſߨ�8��~��o=a���n���f�����j)ze������_7_]єj�W�
^z[���[���"���O�XӮ��JҌ�{h���oh����4��R�Xp��*�]XӨ�?�&=�颴�x�OCю|���6�G��G~���j���eւ�:��j��T���A�3�������9�j��ͣ�O�����M��Hd�w��� �1%�S�}̬ly��yXOm�y�e��:�z=�=!����4iXu�!Ͳ��#�
p�۝���C|�ML�Y�Jk�d��J�x�|2��zu:;��u�D�t��~ɓ^[X�ұ���r�}�m�翡�����_��Y���H3>�믿����3*�O+I��y�6��������:�h��W��W��� �k{��K�G�y|t���%�9� X���Q�ѕ����?>�}|T|�������	�a8�#�ȁ\���Q�ù�ޣy�zK^�e�Ѳ����GL�i8BIι0�,���	7FR���&\O��i÷�WD$�\����,���QO��(���RU���l�\���f�3�|9̕`��e� 7_&+6)���r���i9n�����=|����*��J���=S��~a˗�j�}��oD���@(l4< (��dE0�U}�:a=)�NbQ�F{��wů9k���Iɂeܗ$�;�f��'\Ώ�l���� o+����\��qR	N^:a �vF1�x��Dd��a��G�ߢ���E!n!u4��Ç�F�>!�'�Ga8�����$<K�p����0ٖKyl~�Y��n���������������]��$U,_�囃����e94�<�x�Fk�		���й�߶���ݗ�;M�"�wJ|�\d�Wx��LX�i@GM����3	�Gg4b�X���9�)��������Ot�$(Rq�w���@�P�MfG8漠�w
�֝?H6GC��#BqÃ��!�H耧ؘ��1��A� �jʱW���`�������nh~�b@��:Љ) �h����3���g!�cG���q� ��hB1�t��Ҧ�mo�Mfy~?�ݼ�&�߹��Z�~ �ik�rP������{��m\���B�5���x?j�>/�'}g$|;:ä���@n��z?l��������Χ�;��qdw��H�u>����������O翼�_��?���s������?�;��ۡ2�zuy�����`d���h��E��N{oռц��Q�/1���%eF��̲bc �����>@
�,8�+��1Ï��$��O�� � :��Y�hpI�_��s:z��[���M�`G~nO�
��i�c?�����(���Y�pHy��s�@�\�_�哈i�@�(����-u���������鏟�۷����?Ǘ�/#��E��szt����w��|�?Gѧ��:������W?ۇ�oZ��7[�[�������/�P�4b��q���J*�/7g�/�8�,�)?/�p��,/�W�̘e�O��%���1r�[W��Pd^��@�4���
n�aC��./�n���ț�y�n�� /@@h(/���3� �_��>����<�k\Q���ΐG��;Q�w�m:D��Y��R�n���3�3�Lt:�1{i��p��@by�O��oC��ۓo?]3�ݝ�Xp�c�Vj��*{�3l���YE����>�/�Jw�׹
Ҕ�\a�{��C�2��(qq����>E��9{�j2�)g��x�x� �1"�(�&r�A��8�y��Zz�W� �w:6�Ð_��n���;�E,�~q'�C��l��p3qqƑ�1L�~'�1&}�p�d���L�c(��7{���>��2�֯I���ı��u�;��A�h���`T�TCɯ�!�[�OX-^'zUˡ0�J�c��\��<�=��H�%�٭��q,B��g��^�^���?�b�xUkjM�	�-ו^����˿�G�R��EG�s �v/S r¼jJ�L�=~3k�B7�7&z�`���]R�CW�۝B�^o��Z�U�>�9�;���f����'�f���)&z��y�n�p��lQ�Ѧu��Dk��	Ʀ����_Z�������rł�O%���n�J��~+v�:d7#u)��-�䘖�E�RBt��E�+�SE�͗�'�UZ�ǝ�{G��;7D���~��Ch��޿����A�������G:��(����郼�i���;�:x�hM<ó�1�es0�.S�P�\��j�\���uY΃�q7��D����l�m,��3��������J�s%����>��9;�!+�,����_a6��~:AnY�_8�W��c.B ��J�D3C��q���|͔�ޗ�67e�e0n&�Կ�� ��

���-���0���M!���9)bn����@p��C�ΦN��$z�>~%Y�H��A\Q���g�K���|��$�����}5�]�C����z�	��Eu7��M���Tw�����C�T����V[.��r�]^v��3�}"�ثH�i��u{�B%Y�<�H�v\�b����U�q�_��+�Z��"ѕ{���G�r����R����|�a�(�Ӊ�d�gX U:�#�%����>M]������_S3��M��Uͪ��W�*�_��5������ �#T���/���2�c��9bQ�����B�)Q�������ْ%w���R.͞��	�t'��u"L��t����P��_G�UU���������\<��w��>��@t�{M��/�A�'7l���P���� ]��>Q�,�gp��OLc�3M�9��g�7s �sR�������*�4�������>�~���Ŗ@���9��+��n�w[���y���+{���	GÏ2�0)�p���L6R#xo8��	t���$=�.q�
��6��g��a� H.���zHY�8d� ������z"�.1fm�����ۙ��jk
�����j���-�w�o�α~�v"E�=q|����f�!�|���W��/�b.}d�)�{7��1RK]-��sJ�EP�8pf�N%�,�A&�{����أksG"F�Us�n�}�|�Ò#��a:n�s\�9���R����+���Ѳ]�x�7E�����,,�M�]��x-��&Jegnnѐu����*��
&��]�/z���Iͼ��w��ˁ�7�$O����6Ha��@)�^'��PQ���<�Ԅ?�c`��O��g=qt��^-<{�u�S����p�q�L44.#/��{��hٳ��V��������?���V�*�Ot���*��5^�����?M���e��-�?����Z�o���]���_���0 P���"ͬ����>���E�3��ù��׍��_I����<�?<|�?�6��3g��l&�sޕۛЧ߆��-�~�d�'K�e�?�,Ag,/GH����^��,�H�5/?�Ι[s���|@�;��of�.��V
Z��VZ́�c\(t�M'T�=jY��:Z��S*G�����Ĉ[Ȕ�C�)�J���e�*};�Z�����V�,���3��U��+I������ �-��|�I���.�DŸ�C�2x3���Ρ�{��Rw���Xi�4ȓ Tđ��pҗ��2^��`��{���%	&���� j����N�m`��w�y����)𙄹�Npw��ߡ i��o6~q�J�S�� ���
�qJa�#�>ˀa_��>�@>�S�&�+�KT'�.y�+ ��y>���1�"�冗�B.�u 2I^�}���=t�=8��=x��.Њ�Y�پ��ac��Y�밋��a�Q���V0���H4��q��eX��>s�H�Gl�K�8=�(������=m'�B6f
`��K�y���#�{;�_Ȝj�y�X-�/wZ��d.�jV���H��+����������x}w'��`Z�NK�W�FߔǛ���f��j�����x���r�6�ۚ[�ʊ��f�����]��Y���/��^���(U���Õ��Czׯ��7�?՛}�V[��>�_q3�>:k�/��c,���J�?KW��ں�W��*Ҳ��"˷;
����b����=|v��C�5��"�'0�B�5`�j<��jM�(0xs��8�%��d;<s�G��55k�䁄�`�2g52�w����l�OK�Rj5E�f��O׶�_o�a���I���^��,0����y� ZSEm�jQ�/Q���H�xVc'�	@q0����v8���(j�YR9��I��*�z{R}-��.d�'��Ɗ��K;��i�1�WR�� ��6�`��8���+��_���V���
��i�)�����fų�-��+I^�XZLgV�8��R�8Y��)kNi�1(�*����^Bx�<�)�^(8�t��yXϽ��S6'�Z6W�BL�27/WUęz#m�l~��f�;3OK⪾�i��4k�3���m���G�Un�S��\I���D��8�����*��ćz����%p+����$n*������|JTwʋ΃�ͬVi�iV�SN8m�9����j�Y�dA���W��+I��':����l�o@�`lg���8���A�oH���&���'�JQ�iZ�`���0A/��;Iz	�T��iB�ĽL�F��g&򕷠-h�(����u���wu���'��ȱ���<���, : g>����@ 0�S	7�%�V�؊"[6Cj�;�����D�k���U�x̅��"��T������T��/2�G��F��:�H�?�^3��t4�y��l3���S��h�] 4��>aL�\S�7��Jg�g��S��F�˸9k�/����}f�����V��3�9cH�72������3Yj 1�F��^���M����	��	����q6���u�O�$��䯇��h���� =�pb.=u��d��<:�+w��� ���f����D͝���!�.��Y	(k0�)����n<�k����!E� ���W�c��ur6�l��fH��ƀj0Q#������sp�e�lS.u؈舊�����$6`��!����ܐO�np��F�)�}�
��u��5ۆ�TU�4���4�m�|_���
�H�q<`2��B��_��(�x��#�:1i��{���2�᧧@�}�?�^��+l�l��:��"�m���w��ȳ�2�'C�L�?_ҙ_
��c��̝��Kû�IX����2����/�f[���T�����s��!K I��kH�'�gx�{d�2�?��6�����W��vC�C	y=~�G��9�+W1]��x�����a�9C�<�-l����[�gK���6c �4&o�&
m��ۺI�7C��8>�8�K7hl0:w���^C����\�Nn���I]}�^��C޵\�"��m)@����IƋڀ� ��O�G�/�w�x죅�p���8ޝ�I�ci~�oY.��!����U�=� 2�)P@�����B[јzg��8��sy<iq�6�����0�G�3�oC_Ojj��D�:�Ź�G�8␎� �\=V#��)]��0r�\�j�Rh�pz6���6^�+��i���mR��~��S��C**\ e@b4�b=��>�����fC�u���p7|�6���s ��7�Q����!��!�80��r�3�Cٰ�töm��+ۤ���Q#�"���P��rcB�5��d����lfx�n���T�#S�F�#V߫0�Vu����L:�"�'�<���(�w��u�~hwG���~�I���]�O?v�� e�%8L�N��c
�7�1݀����zG�5��M]8Z�M`6?&^��k��9��� �`���l�@�0�dN��B���{��7����n]�3_6_4�6��Ort�NZ��q�P������'a�R��b&�Kkc���fۉ�w���R-]ժ��U�J�3�� ���{��$9��{�Fݠ�d��k�Q�R�a���䌡�e������`��Q��4���Ԓ2����(xw�rӪ�k
V���󔠷��p����x��x��X(2ΐ����rJ?/دg�o*�/��]�r>G�uM�u�K�����Q �M�����s��q
�
(�daԠ���S�|I7����4̣W��i;G-�m'��@��v�q�"�`������ĝ�_�U-=�-ۆ�ߴM�:�W��F-ͬ������?p.`o��	*,㜜���q:f�9�O?#>��se�|::_@�QsS��������\��˿$���+F&����ς����H��WQ���w��M�y��� �����������Z��[�����T��V��5��-��-�QB��������eB�WY$����|�@r2��`���@�
Q;�9�����H@{Evh���t E�����{{�q����p� *4�S�=8¾k��U�-uf|g 3y�n�n~��Qֵu}�X7׭���Ý�;o�6��tq�`%S�il��ϝ����,���}*UiU)��0�ߧa$<�G�Q�R�X��Y��o�e��ծ�W��M�� ��ȓ58�Af��J�r=�K'&vr�ɿ�i*v�yF������O�d�{-<u�2k�� �.�g^<L\t�0x�l9�
f1KG����Cڐu���D��;����6[U�֓���Ϛd�� {�i@���$�;�O�0��.��di� n��J3{8�0�/�ռ��M��x��e'�i4inKS��*4 |�0��fI��S���TE��ާ�N��o��5�z�Pə3�:�+�G��b����Ò�`�+Q��������6�u18 �#���sFq���S8���6��� ��b&��*H�o���1�F 
����h+[{�;������Lw|w�a���z�f��������G_k�p8.)�,-"�\�hpF�iܣ^WW�43򝉿?��Ӹ+�7/E!t?��3����G� !���������t�Nn25��y��_P�x��wu�"�E�_4���?�?�6+�ϕ���G�G����T�;Da� ��8{V��Ǿ?]�T+�"��1���á8�l�?O�,'pkʬĖ|)�2���lpy[���F��E8��0����f���	���&4,ܐ	<�w�A�N���'�0v��(�/:���E0����v�>:�Ɛ�K��q��xڊN	�7a�I]ʞ�'!�`��ytJ��ƙ"��D|���hA�;�!kPj�c8<�R��	�붷w�u�;���������
x��0�2���CnNX���ͭ�vi��<�#��g&��'[1�YjM���B'���p�,���q_	P�P
l{�hs�d$�����4��_��Z���Q�Z��tn��δrיb�[?$㖠���0yAyU��љ\0?������'gBe�/_�K��
4cm�?7�n���� �LNaǲ�ɛp��hN6AM�s�Hּ6�k]fW�Z;�=ں�vⰸX��D�����d� (pf����%�xx-����t�_]S�=��A���h��6����s�_���-��kU��Jү;o^����vH�1���V�厓�jS���~}��f�pw�Zog��p������;�����'��İw|��6��3\��`��/���K�YZ��mSM�?����o(��_E�������E����'����	������j�Cy��5���pTz� �4�_���T��rK(n�Ә��f�F����e��#��y[R#o�e��X{�k�̷��ݷ�pJ��Y��r�S�k��x���S��Z��YKJz�i�frӗ��-xi��ֳ�(�r��=�{�[�{_����-6U 9��2��\��ʞ���
�C¬d�f].��)~j1�I8��{"�� <d'�f��&q���n�d,�����u'��ī�Y�,��=L�7�=�".�V�d ;?1os ��� `l1ɕNH4��@�l�%��y/��e�Q7���lk^�Q9%�|q�]c�6��e��TB(b�;#�"��w�n��K���B/������ї!~X�7X�ɠ[oi����~&n��5?����~��c��_K�&���}��u�
ԥ�M��l	�W�n��R��+�;j��B����lP�^�s��D*�]]�o¬<��ܔ��>;��i/����.%A���ݵ>�Y��t@������K��TW<��q�S��dho���ns��wv&����5����s�&^8']g�i�r0n�}��I��2h�P:��9t&F�ti�[RNL� ��:V3���A8ȪӛU���-U���� HQR2(��`p;�&p�	��A�];�	F��T���1G�i��bt�cw�)5�\8t��\,��ET�B N)&.47�L���I�ܓhz�u;�N��gg��"��>��<|���I��(����������<I��5��c|�f�9����z�p֖����^E�&ʂp�yKlc��/�����Fu���4����'����&�Q��,�I��{������*�5��1�hi����&��E�O����j��$U��E�����k`���6��(P�/�6�Z��_�����$� ,����Y���&�cϰ��#�@��ݫ����b��ϘE��nd�LSg�l�:�W�3�Ϗv���n�vNb�����7FA�<=�륙�d��L�gJA��Oֆd(�o�)�^'���c���C{���گ=�7���������㽣���������6�������H�/�������rv� E)�Oi�g���x���N������=\���ng�?��������_E����<����>@n�$�;2)z �O��*�3[��c=�Ǟnk����l����G9v�����5Z����kA�����+~��,�"_�܏���������:�`h���T� 뜨�֪�=��oI��b���#+��� �%{�['����ת4����s.����H���8� _�Č����T�h�g�J��}%�1y��o�'ˣ?<}s�Ai���B����+�'{�!o� � _��(��H�}��$x�K�T�����9c�F(A|���/r��A�X�o�/��n͇E�.,P�GL_�?�I��{$ͬI!�'}g����}�c�C�F]v"G�e�=(�?�V/����Q���hg�\��� m�W�*U�JU�R��T�*U�JU�R��T�*������X � 