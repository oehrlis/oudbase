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
# - EOF Script ----------------------------------------------------------
__TARFILE_FOLLOWS__
� �ϰZ ��z�V�(�O��Vڒ��$Iɱ�i��U��E���8��HPDLl�������q_��;�}��(�I����l�I����X7֞�^�Z�,NZ��?����>|���G�����W>j�����o�t��Z��x���?��_z`����0���i��4�.�0���|�`��Y��7���|��X�����?�������o��?������K��?|�����(p����j����d�E؏s�������8��\�D�(���d��Yug�I�M�곝�����(��|��y��?��w7��p:=�f��uս����Q��o}��8j�gKy'~lϦ�4���h&�0f�X��Q��rz�L�ٿMe��tow���m�q'��~7�7�k��on|�Gq�	�Bc<�e�4���3�:��e�d���:���a����"��Wa��h:KT/�G8�t庿�!�R�0�q'�+5ˣ������8K�2X�a:���W;�~�!`Ӡ76�N'�V�u-gg8��G��0�ߋ{Q�����^�~s�_no3�~ڏq���kE
F����`ʰW4!�e���l�i����)�����ar�:���Ⓨ�s7�
)zG'���������������η�F�ez�穙f�k꼓�U:��1jPy6��W�h�8��U縻{x�v���lnւ����Q�`�I���e���}� ��g��w2�?��$��v;Oj��{ݏtegp� %��t��w�NN���'+���	�
��������w�O�|RkMǓ=|��ݮ��\��כ++��{�>>9}�i�t�����vvi����Z}e��+�eծ��W�Ղ���^{g���>��oi±k��A������z��{sZ� 6����E+��F�Ç�7L�
����xE^H��E���x�|���>o��́�G����huM�/Rܝ8���+np�=�BT%��G;�~~�j���wZ/"�O��E��������v�j��w��_��# �i�'�����ê�A�{A���y����C5������0�%
�E�Q�#�5�3m���z�غ�zɓ�8�z���f��W�r�����#�7s�.�
~���]��^zN$l�z��$$��.����Ƶj�Oպ��12�$���Ea�N��>�F�V�o^�����nW����+z>����V�_��g�bR6��$��'_�t�j���i~�G/�"���f��u��D��m�@�ͮ�$��,����= ����j�� �P% 9s$��\W���^����	>�������j��͏�oƍo��߼��f�nm��c������&K^&oB����p^�����w�A��_��g1�F<1����(���@7�2Ģ���<d�fL�xxj��D�F�C�w��1��(�?�a<��o�C<�4j���0^k?���ؙ�a.�]���:3-϶�&Q�&��=}Z5����W��w�tِG�	���$���H� ��]<�eYh����dՄo 6����E�
��$X�dj�i��w`�j��T�A'>W�8�%$����u伩�p�f�ʐ����P$�����M�Ѐ�*�����+��� ��|�NiCsdc�L���]+�
����:F�9}��zi����GS�=/�x�Ң7���e���٨O��7d-��-�G��a_�Yy��У�ԃt��_:�n
\��j� &���,}��e�B8�>I��Kgï��f�$A�E�B�t<��'���H�@E��e�g��$�LT߈�ӫ	�_�tBK�j O���e���<'��,����&�[848.Y�-I"��/`�F�,l,g�4��J��S����n��cg��r��u���v�-+sH@��z���}^iT�ƿt�x� ��ؕ䩜j�N�\�`�����N��Y>U�a��*mc�F�G`�u)�|)(J#�#�6����\�ؖ?��h�^�"�
��ʼjũl�t�5���(����|[��Y��a8Ci����ٹMVh�m�����Uݸm̨~A�1�Z�@L���?���֣�$�����l� �Q�� 8�L�aCဢZ�]Z���X��?ƀ6+�&4�Z��bO!��0� �j����?\����G��~v�����a_{�(H5�@�T8�p��"4k��"iQ]@�(���;���f
j��K}��^C̫��0��"K��
'�?Q�T��ϸI����V��Lρ�U6�ݾG�1�ļl�󟍬j?�?�[���4'��M��zmA 4
V�1K=⅄A�`��������@*M�1a�Q5Y�]�G�t��?�R<tȭE���N��`�v:���m5���v�~��le(-��x�*�51d�;��b��O8��kj��E`D��#X�<F�����8��/��kJ��6[Sǝ�����	�E�����X�_�d7��=�]�ih�??�%�VX���Ei�*nB|�B�Se}�O�y#�F��X�W�iH򒊐����c�0Iߛ�U���rUi�MIӕj滀�X.�����9�ѱ��Oud������#x7�jG�H����xpU����S9��2�M���1\�G�.6��ըUZᯝ���_u���G�wdٮ-��0��;�ef���e���<���ǳD]@�bu�p��Һ�`�{c��`�<I���dJe�$ʦq���������L��sT������6��>Z�Áy�L����y��f�+/���l�Ӱ�
��t���6�>�?����K�
�R#Vw��_WZ��]���ۿ��=��������a_�x6��tc���uH3hj����������y�M�R���� ������J�-p��["1��h��M���e�k"�v�{�zr=����K:�{�X����נx㨶v��x�(+����MϪ�CQ�C�C���o�ҋj��N��������1� ��>vT��뿜��h5�|��>���{������&i���9�Y{����!�K`{O6����!:�6���_��~��B������|{���iK��	������<_8��5��ޓfE�|�Pkf��q�+N+��ÍJ�Ͷ����rE�;�f@�)g�K�I��������.:fs"�K8�t�O��sL�<P߀�q����������+G���w�w\�8�͆�q�܀�V3׹{9��zS[�����3v��f�9X��>�cT��s��,m��_���v��ɷ���� M�#<>��<ܬ<(�v86+��G��J����b����H��H����ޓSn�Zh&�\o��[UQ#ێq]RE�)���N�Y�Hr|�Ys�ep��@�"VN��f�	�W�w4<N'3���ȃ|E��e��c��ߗ�2�U
҃�%��l1V�ϵ�4~������"�-�����#���G������_��E����b����͉�ǈ��(�(��ʺ�S�5���Qȿ��~�5�C��P�}���A�N���ܫ�e���`_ڏ��1�����S����G7��gW��'E��<��<�=���/_]>�������a<Rb�����������O���i�C]�g�}���p�����G�wP՝��>Kzz���	������@U�}򂺰C#�����DN��i>�*���d hm뚉�-���M����5@}� ������	���p@���<y	B4rě��
I��&���Rx,�I<��b�D�B��D�/#XsP)AT��-��)�I�N���FB.+AU�"����1IX \ �'G�u�� ��Q�ʏc��3P�uhun;i����(ʩ|�X�.��	_S��>�����I^��p�x���+�'n)�yr¶�?�"�����.�㽫��/�x�ؗg#pl<3�I���+K�q�s`������B�9�(1E�!�T*���x4b:�#���^�ŴZb�n@���{�^�15��q�z
=�70��`+��=������5��	2����y�A�0�f["t��i|��D���~�9L���5j�b-.��3q���	�W�S#��Ғ��+��+����� ��A�H��6?; НD��������-�ϋ��>�
�$��i��ѧd6>�/V2�Y��G�=��>��恡:D�$&0���y���d���hK�Rk�5���������~����`�14t��+�Z/�m?�Y0o���ި����`[�5=
��9�n#w 7�+��ĲiL�� ��D�Q��
E�qA�.��n_.�~T��8���R��+����,�Ka+#ŉj/�O��;rl��mk��Y����b�x���ɶ�c�V)װl�qwh�G!>�LTg0,#��c'�gO��T4��8��%S�u��w�*�k΄���2c��ڂ΂��5��{S1�9p��̊�.��f�;��u�&�ڷf���؉��c�����U�k����x���5!B+1���o�{�z�
�]{��h�[i��h�]s)��Y�rn��.h��!�:�|�G��Z�`~S����#D6�Lݭ�U�k�GK�k]ӈ��UB������ �Ir!~����x�t�9s%ȟ��t�R��#2�}�4��M��m�$s�2���V8�DUȡR�(�8�TvY��xK�d@�l4�<�e��PE ������]'�h�^�+�C��J�ˆ����d'3��rJ��������&�N�gߝ��8���:: 2�l���9�n\��c*+���e�)�����( ��P}�&l�*2 �h���'�K�x>��:��ҬdT�	��Q���$]��5���R�ն^�m�����ǗGs�b(~���l�H�W��r.&!�ߩ'��=p�!W�*8�`�1�H��{�)��Eۖo�vOZ��z����D���j�� ��K��[����c�?\ ���L_k�������$\5 L�:g����u�BwK4�S���v�?E��������'�q1�[͙��ʓf�!�3dT�����IC~�������Rq������(L�n���ݵ� $�,_���va�yo�Io4�G�2� �w@����@�d��n�M����*�h�=�-Z�m��s�_��"�FhɃgw����`�hX����G�o�p��f��\�Tcԇs�h��4�8�Q�̍�N���y�Bc;� *�{<N-�ӝ�J���7��kM�t�%�[��N5"U{��[������ިx���OeR��I`��HQ�3w�����I�s��SHB�4U��NGr:���:7=*�b#V$5�lBI��4|o.g�'��5�N�Ѓ���壼��7�<�V��\	?8}�O�f:� ��;F�[���-�~
�	$y�TF��_��cA>��p ���)��aԟ�Rs�ђ]?�L� ���@^�3�33�r�YLeZ��\Z�bc�͚�������X��M�6�k�6���?�����*���?2�R��9��?b�����5��S`}�����?h�����[>|��ޔg|�O����N��Ƀ(���Y����9��Q4	��NP�}Rk4�ߋF��+�V=��_S�n��_)5i��G4�o��d�jT{oo^�����8GJ�D�����qg�sp�޳P��y`ߪ�_w:�Z���]�gM�����4�̃��V�����_^�(;�8,��� �f'���'��|��9H_s�~_Y0_s���5������9H_s��� }�A����5�k����9H_s��� �>s��[o����`��%r��k�]�9:o����5�(��R�Q�@$��ሯr&qyކ�Λ�_���+0��5�h_3u�f�|����dg�$SG��-�-т�F�ฉ
�[���J8B������^��^�c��0G��l���ڝ���ק�w:8t��/A�?�۱?�����B�	�Sq�t;�|��)t
/)�-��E����.�l�P�I;�9�6�D�A��<�_/�11��gٹ��dw�ٟ�o��U(�����y�L���%+��"i�D]�&#�KF��cJF���IF�-�].�|\*��&�HN���"9/9��R*�ұT�"UA_��$H�#�L���#����>*˝�,�
at}��$�;��s׿U�럴#e0v��RsR`~{]bD�r�6eab���*)G��GT�[I������`)n2���X\o���RlUNH��XJo,�|�^ē�$A�i2��+H��m�޴�M�n �j��w1����|$�9=�;S��Ã�s��2����n��ͫ�L�Ū�r�]LUkV|��o	�%sl�01� �=X�mVpq�H�a��k�4���1ɲ��,��gX���UR��J���$��N��5��n�8%��ɉS7O���E�X��M��U���l�b�{/�f�,	���1h1B6��k�X���l��V}���}�#W��Q_Za����gc�Ȫ�U���G����Pv���q�]H�t�G����>&�MFw��l�R"���'}����P���=�xh������u���o�������2�b����u����VF�k{N���5���(Sva_�Y�!W�1���\�lr�xUܹ�A��T�6�vK�b[�؛�ܫ��>��Dԡ��
�;���}���{��x�����׵��z�&�}PE�O8�gy:�M#�o�\���ϥ�j��πe_�%v:��/�����B�A�"��u�5��HtN#���V��Q�9>a�iw�t�T
��~���o��v{�m5J{�}�������B�,������Pi�}��mu��?�k�t��v�'�a�8:>�y�}��b���Yo�@e-?I���rP���zRj�|����l�9f��'5&��=�M4�Ԃ"@�c<��t�;q=�g�	��.R:�(&���>Q�0�o['(��F�+��)��X��ż�4�'ndؒ����E ��Nhgl�"v�}ҙn*#���HL�,�02�!���V=�H�Uۅ���Z��v��`�h.mNW{>Ύỳb�ͻ��4tW��ؐv�8�Q�v����p��@�h��	L��8k8��_��^=�1���]/�[����|�[^�/�\�Oh��l�
2�o�>�C�
��K��)�o�=v:.�KoT:�Nק��C��s;�h���ۯںK��Gv�Kx��"�(8��{�O�	��� 
��4�j88m��l).��(����T�urr�#:Rd�`���m���$&e9z�f4���H�"	X;�*���w��AIb�-D��y����3���hoLU�8o�d����h:��!LČ�$��D�7#5?J<AՈ�d��qF�3�w�tlaR(��5��4k��rL>Gjg����z�.c`IY������H�ȉԤAZ�~��9E����ϵ[�p�Veó�~c':�KPAD���g�W�X���9����/#�8̣V5A�~C�F��.C�ђ�Y���Tqԏ�v(����n0��)�i�ᛞ@r�J"ǵ��7UN����r�k6�㡓���S�:͉����_�03��L 3v�<��z5H�PZ� a�}d���gf�^f=�.�͞�X���v��������)�E��`��o%�ԕ�5o�ne	F�_�*6T�����I=�c,Ii8E�a~D�Ҹ����Z�%���;�Xn3.���a�9.�R��U�]`���r�h<�^y�s��޲��=LQXLET�"�� n'�*��E�x��0(�!L�|�T�BW��հ�Z�H��~�,���	�s����.��;�O�ΰv,s0�;�S�M��}%¸�w���u�6���L�A���}���h���o�k��g��c�_Zʸ�lWv󩿓��()�<����j(UԖV~�����n��(��#�ǀ��9
8wġ�vO���`*��ޛ�:�Uӯ̂�y� k��Q莯>k�Ulم�q�8|~���<����!%��������RC�GDt��2��6]l�'��L�wv�Ouݕ��W�e~����JK�d��X���|9n���_���;�L��J�S6�q����d�2�>l̯9<��~��dߍG�7@W�@��Z�Fj[2�i�o����@Ɖ�(x��4{��,��@��z("��Q��� ����y��[
�A<��R�b�/p��+v��Jo�^)��C�,�����yN]�Ҟ����,�hzo�}���+g(��R���i�o+MO�ݽR�6zz������q4��͑��ǝ��8׿�Lot�]�Ё�)EJ�C�p��VK.٢�PO�ǥ�899R�g�T�i��������sE���b>>��Mʬ���NӁ�<���[f��R�ݜ>�眖VJ���:�n��ɮ���j����V}j��17�?w�I &N�3�^�ƞ���}�Y�>`%
��p�I<X��}:�Mb����rGϭ�� ��q�2�2�:��ܘ�x��)�Z��a�[+��tU �j��	��dq2���4����&���� ���:X����ש7�pj+���qrzv�Z���Z�E$1"_�Q��1;�=�_��9��^Iٹh�Z�7粥k���eb��~P�!1F�X�q����*��:,�*2������{��)�Λ)���feQ֤H#S��K?�y���<g��j�F�_"�Mc�;��}LG@�c�?<�k�+��ª$y#����n������}9���.y˓Vhd(8'�Iw����bN;���');E�jAz2�|�?�<wIk{����F�@�w�j�Dʟ;��o
��dV9J��$*/t����/��B.S����2\����RnBG,���:Eh֎ޡ�OGWd6u^*�l2蜯�}�l~͙��h�805o6�j��Zw��		lR�!�`m��O.t���K�f��T�d�U�E鏧ݠ����-��قrj��u�$$f�ꭿ��&w��R����y�GQB��f��Ow�=���N����|���������]w��6e d־#��JGs�}Y�`��	�U:���5oB��hE7��6���r2
e�P$�v�ɝ���v���8J��^ZB��������ѝ����津~������Ƀ����HU�5�e���n᭢��da+�u��vQ�}�6:�0�Q4��,�_f�4��M� ۩أJ����!3�-G��Y<�TT&`s�L��ė�"~�Qݍ�=Y��Ǫ�*���ySxĆ�-��[�m��Z���m�`�H��řpi�J@��[�ӧ��\��_P�KNM�
�.�2�0����[����|:d����u���w�/B�gYTǒ¢�F�	j���0�dex��3�=p�����{~����UӦ]�J��ly���	W��h�Y���hRCO�ڍ�+l�}��<�LD,0f��A��6Q��~'�[I"��?�3 `N|��O ��{�#����G��w��>�������d��r�a4�p�x��D'R�eooH�=-?	Z-��Z�s���S�}������c��W��@�y#i���%�ٗ�煗Lx��y���~~s
�h���=����{~���	X�y��9/NC?/4w�B�����7t.V���q^�[~ϛ�߂P���p����+��ƾ�?_�U��E�S�ҫޫ�rdU�<OLESf�������U��yUs*��s��KE�ݬ�Q�FG�(��/�F�+�bA8N����h���M�ěa[���a�|q�7��a�D�V]Yd���w��@9L6�}R�`lK� U����W���}�.��\��(c�q�8�lj�f$fq��wPX�8�����.(����r�q���i@[K{�[Dd�"/�B2]�2�{����C^����|��ew�]FY��Ҡb��Sǫ���.z	D'jK��*�N�ݶ�V��S�2�Bb���潵'�wk�jk�{������){s.��;c��*CY0k+�7���P��_[��XK���a���Zٵ
G��{�Tх����E�D���X�y���&��e����f�z4�r�������:���c�X�����/4���5�C�p_؂) �m�A�ڼ�u@*b��ڶ~f0���ǚ/�Ks-p���{y�^�D�V�G�(3_Mʭ���p
ýـ
/�Ґ���8M��x=Y�|�Ԡ$��v�Q���Z�y�ȟ��ug�B�9V����YI
���7��q&9+�=�1��z�L�v��Ёq���H<FXAL�fQ��^vH�]�V�3z'���.��
�߆�e�:s }�b�볢1C�����w��KZ�3��n6D"�F-V�Zr2��י�G�V��ށ�P6*�v��"�¾�����q� Z��.F�3, ���O9���yfS�����"L�s�&�	�x�f�a֗=[�yz�q8�|c��ш�����PN��O��E��3������m�F�� zM�Y���m�t�pT��dk�g��4^��Mx�x�{s��T�0�T����s�XO��(�ށ8�K>��9�u#4'o%ѥ'gϻU�P�|�vO�oq�A�^�y�J����N���J�K^��<]����K�Ѽ�B��8Q���pA4�Wo=j����^p�ŉ��M,j��#SD��Q��\~�Ͷ��R<����$�T*bc� 6�^�C�@D���5
�n����A|f�?:���"U�[Y��_mŏҩs�ku�������\���>&9��)v�xO[��~ǫ�P���_�z?����7�6���p�z,�iFm�C��6f�ܹ@eF[a%'%G�o9��[^����R��E2��+��^��o��p�
n^�WI���;l��P|E��
I+-tm/ͭ�Rv�z�{��6(s7��_�EU�HL��KR��dn-�l�[8�������[�ֿ	�~9DE�N�q�}�/��b
)�`$%���P��^>v\�La�Yw�ݒ�`���4T�"�^j�>�],~�I/bm�ҋ�@ō״\m�Y@mg��3
ޚ�?|W��az��(�����q�@/2�υn3��Ӫ?ien�}�>ye~�}_VgvC�~M?T��_�1:Z�t��Jj�����(�8�����l��u�Ï��n}��7�r:�o���X9�ݒs亖�,�B�V�Y�S�:h�h�ia�h��K�N�猦 k٠��M�O4w��<�|:l1?*�75�ʊ�
P0
��;��ޒ%-�s
�TWΒ��}ߧ &����n�>��ݳ���_��hN�M���������*9��uc�킵�﷯�������G�x ���1���6׻iG�hOo<�9���T�d�|�=�n�&��#�q��:Y���y�<I�������[��������⧟�Z_�����}Y���G7�����G�I=��������p��v�;���.y{0g�7�<ܸ_��͇�>�z�ۯ�Q�^�:����:z��C	�����J� ����ԟgI�6a�� ���U��ju{���Y�n:�^bU��x&��Ձ)���{�5��4;o=T�"ʮ0�#��f�q<E[�&W$+�1�5>�h{�P6�`�p�E�7G|���!g�+h�a�M���p4J/�~3�7]�eQ8�[��8H�F��#u4;���]g7�8��4�QD���7`�A��B����8�St&H�o��D���2�����Y�$?�L���Q�� x�fʄ�����0��ќ$���zv��Q��oZ�Kg'�(��>���,��Q�Ǡ�#rHX)�?�b1�Y8n4��M�Qt�]�E��҅� ��� ��_SRP� �f\�=X0'��)�����?Ʊ���(F��ü��3�.�vE�&�ҟ]�C�]��c:ð(���!Z-�SHS���,O��-W����?��2���"��$2�9^�:&Y�9���W����-=�I�����uuP�9�| K�S���x�0�?@�� �e���͊0Q��^ڏ�>���
С���C��Ϋ��Ac�=���c���H����iכ#��[6�p�L8��K�|���#�h߈��I�k8ɢ�G��(GW�G8	��/�8����D���|'�n�$� ;���cCܔ�eӐb
��B�ţx��بr��U�c�� 1��%���`X�'�"�#��s���]8�� ���ОxX�!�r�c�Z:�j�dǘ텊8*�ri�L �i�3�[e\y	��r�P���:tu�:pP�W�`%�i��A�C@�lA�[��i�W!�k4�u��Q5h B����U�G(N/S��t�o�k
oOͦ�k����x������k$��	���<��x7�΁8�͉�ۭ�;�ZDQ̮s�j=��l�a�wWO��/M��:���:H��Y���g���P�F�Q�&w|���:L�9��=�q�z���Pˀ�"@��-U�$áλ�Ê�>�0���l�#'�����՗D�,]g�� �#9����[���_zT��K�t�;>�2Bx>�Y��Q8��B�'܂C��b��!5��l ��,J��De���b#�D�	o�@�	�-_�� $��z�d'>QA�����
P�.
 2��Ē�3<i�7���I��ƋI�D�h��p���Bb�(�z�"�`���W|�-��Y��:��%�'���;�� :FQ��|:)fB��"����j��Nhf���F�ggh�����"Kȥ�4��O�,t�@��- ��n�$�$����3�]��{�#��܊�M���PE'<Np|u����6.�tHK\'�i*#�y
N�g�{X8�$(m�%�[7��7դ��Z8{���8?řƄ�t�q���OH��B��)�g:�h^�1�0��>"iƍ��Xԣb��L�n�
���	hkS)F�4 sE�j^5ER`I �˒# �3M���B!*t/3���t�U�c1�� �������
�J�	��L.��J܍���I�x���;Xig�d�𠋍כ�s'�#�_;qxL��S�_}��s4W
g@F����͙��5F�[�y�R�:��Б�[��ԅ� 
F�i�����[3��=Zhw�(�>��O���h���Kq��+�	�3ia�[��5`�5hU���F[R�BMFv����8/��a"����,���$C4g���N����Đ}�w̅R�0r�2L$�V���A]V�
+0;!��$ ��R�P���ٱ.�9�VB�0���)@� �zI��WM�]jԱۊ��j�`A|V���b0����)��'��Q�Yd<��9Ō׹OhBZ�G�
ᴮ�S�ջ$H�edt���8�Q�|��	u�8�nP�� ѧ��{���;�m�.>�y��4�TF��_Q�/8I���H扈 �4fh�H�ёU�,���ƻD<As�����N;��xtS�S���@�����82��hdv��"*�;�S<�"%�)m��8� �_����De-Va�d��+�:N%���e� 4��Sץ����|�wn�"L��'?�G8��~."����"@4��/�U{$��(r�@t"��Xݕ���$� �͎ĮQ�@� X�Q�P�0=����m�-����La�X�UZ,�%]��p'!/�""��b�6h���U%�f�Vx���;�pS�c<�|wp"�އ	�cI���s�&�IN!q��	�e�k� N���.�8l�A�0F}4�H�E��� ��h*��m��y~��Gk�*���4
a�6&��t��[|,��������/Qpo��r_�z����j��ծ^4����|� ����1�a,�"}���!���Û���li�
�u������t�;�"ѱ��F����qF ���s4�$<� �w�h�+��q��RZ��M�Uȋa��K� �Y"Q�1w�l�9��}oo�V�J�Ƥ#]�h5\c�+��׋��� ]��:�{�3���E�r�&�,n�%�JV$��y�4�3~����1bX�b�*"��(����~������%|UF�0H����P3�%ք����VEM��\
�����6EY�3���R����h�$>�cN"�1/����
Θ�S�.!1an`%i��5��<A&�>V�~��Y.���Q�i�@�Jk��vp����D`j�C��fC��UceB㑓؇IH%�4Ø�P�2Yum���8�\�L������dSmj�Se���Z9!�1 E:�����/�K�Z��M�>s��<(WZԢ�9MS��8�=���w3���Vp�L��!�������6�֪}�w	��q�TC�r�>W�M�Q,���R̤x�ؓ���ʲ���*	�|Wt�7�"ݞ���1e۴6�-�k�]=���)p(�t1o8��1�%Z�%u�Qa���3��B:6Ǹcp�h�|1˫Hպ����!#�kSn��A-�l�8��l���}{�����G�H��>-�vf�M�� ���($�F�A/c�9y��!��Yqh{@nS2Di?كQ
�Y\���hY��
�C���]�U��T�$u�Na��4z��|���q�0|��-e�O�SPZ@~�]��	1���!Ia��gW�r���TW� �#�͉.�#�X<�ME����������G<�@�������BI���E8b���%=��uB�`���<&�8.�h��z�r<(�ڢ/��k�Ϻf��7�e���>o�
x2K����|�z4"�:O��Lp��:���ax���6�p�,�h��QA�����
�+iPF���]=�dYG�j�#�d�+�@����D(��̊�]�ne1�g�!x�Q
�t��#�`#�,76w��Md��"���p$h�΢a8��|�#�A��bCġ�� ���4���|d���62��?�L#�ۉ�h��Ĩ��0�0�7	W�ͺ�����{q֛�u�-/Rq%v|#�ű8Jf�VN��$.�.��Ń<F���u2��(;̰�8Ȅh���o"�~����`����s\�6p��6��uO��A�m�R@�3�� ���G�I��a3z�$���L@�ɍi��1
��W������&|.�Cڣ2B�ƆfA�w��1E�>��Z˱Λ�j�a|�o��O��L9^T���QD����ɒ�-��z�r�����O+�|�B�d�g	�F �Y<�؍�fJ��|�	Iޫ���3A�5�ń0B�+�#!��A�2+�xo�4�	�L�e#ӊI5���U�H/d�G	RWR"����트$�����O5c,�S{WSffV��iA�j��=h:������f��ˁdw!\zb��H��%�f:A�5,�x6�&�I>������f,t� ȇ����%�l���q@���ch��L>\$1F�&�'>@�O.�Ϧ/�{أ�D,�	��:5�� ����ڋ�v\��c�9Pߜ��j�J�5�h7��=��)*2%#3���n

�>���ل��9jC��1!4��.��k�N$�W����u���$���Q4��;I�{Il/�(�b�&Q`D���0V�\��ihCs��m��.\#ᕭ~��{�`W���)M����!�����v�!VX�K��g��y��}W�N��p95�n+kE`�բ�h�d;�ٰ���"�и��6���d��5#�eXb@�2�	;�8����I��m��eEV��\�y�:� �>� �0��&u�<X���}^J τtuM=h�.��L�(I�˖��Y�q'(ks���ɤHU�₄�(z���ܵ�ڪ8^���Zh9Pm�z�NX�\F�y�W�=��^�̥TM�������X)�Wc��8A��xy�k#�%�y{�	˴�%��.Rnun/̳	��� H�!Y��w��C#+�2���^9���#��휢��f(R}QjO�MD��w�	:D�}0�3��k�6밸1F�
�c����.��/�ь���@i���ܑZp\�IP����o��%��Os�KmY��<�&T͈�rT�������E@pIB]bJ��E�eE]O	�lU�G^z�����i�B#t�$�!Wz��O++h@�;�\�z ���9sx�o(�0��(�0ʌ��p.#tzc8��;�"�Wi+tVi���2V >K�6���$��܆d5r��r��%̋��Z��ӢG��$�'ak�S�jS_����P�g��4t���/9z�p�l�6V��,k�M�2Q�POX
�+��,����_]EaƦ[�	sN�����	s��C�ye!�Kl�0Sq�;��%Ssqa�"i�+%�L
��M0��"�-sxwsȈD��k|�W�O����P�R�܅��S���<M$���Oԥ\���3��e�b�*I�a��,�~�Ca�H$�Jp��u��Kw�$��ٰ2>J��X�*��p�CY��r�k���^/�I2cu]���@�GX���P�]�a�>�Psx��3�gZ@|tf�9�L�1:μG���!;=a��J�Ř}ޏ5-y������.{.BdfB��!wN���f[�Q9I/e�&xWЀ�ej�B�<�04H���%ܭ�E%>x���;�5�Q���lbz@���Zs��!v����X���
9�H1k]�o��7�nj
g�yHP9���]�sW��5q]5�$#��0�9�c��u98Zm�d!h�	c�Z��%�aX��[���m�=m2�S�=53�N�(kL����_&�O�0����	��QP	�]�'��"�P�/�ELm�0d��[�c$������*�q@#����tR�f�X<08ac/�>bx8<�;PAspό#��{SJ��	CBc<�a�Ck4�CS�`>��AM��c"��)�Ҭa[H�F�,����`���Wuc��8nӈ�)�>�˽�y�[�=���M�yԗ����!ۢ
C�c$���`��sG���K؟7�z�Ogg������� [��.x��EJa�$y��:�ƍ����=Q��b�jO]ռ��⪃�ՄdŔ���^EF���Ga�;)��YB��g&��й�I�	)������G�[�C#>q6B�	{`��f�Qv40�02bd�F�7ˁA'$�r2���i^*��.�pg	�&Y �@�H�&�Ȩ�f�H�
�P$�.���K�����A�s"�0����7zQu���u�6���e�[ؚ���T'2"p�PT��U�n�x<o�H����>���%��Z��|���Q�͈�q'3$R�]_kP�#ND+�TRS]�T&l*�yqh�6�"R�}b����C	�xN��D*]S�&���aw��s�r�M�j���66ȑ�9st3��dvꮜ�(#�:j�~H�v�Z$���qF����I4���+#��AS��j�y�an����S
8��J�����zQɔx�zo����w�0&$עm,=d���A�06��$e�#b)OJc�
{W��*�$]���8�p3ט�	@�Ǉ�k&l���G͛z9B/
 �)s�i�eG
G��#Bh���c#��Cg���3�%�WuA���<��e@�Q(�N �~?"���0JJN($T�h`)�;���,�`(�VD�똩���r�#Jģ�ͤ�p�=�n3�Qua/K��$!�S�����a2ȹ~���ÙI�����,�@�������Q�����A1pNtW�]k�@�u���܌pb��[��h���Ѵh��mb!l�9��A��<�L�"7�q\�K�M�v�8+�8�Q�I�o�D���E��Y�[3���J|M:l�}b��Ab$P��$7�nb3'Ӹ��!ˋ�0���pb[_)�	�ڈӅ�c����Z㷕t�l�O ��֟h�����U��+���H��A)<���iW�`n@��Bcp���T����a}u7ڟN%E	�|Щ���[bu���i����Qz)À�P����\�	"��k��@&�`��NQ���X�"�1�>)?�܇���{+�>lo�5�m�L����|�߁��� 8�c�;��4�HY"8[fdǄeD���h�k	��D?Y�ǎ$�6��/п�>/J���alR:�Yj�A��xH�t�Qq�Q��N�c�nJjKvaؗM�q���r3a/���2�w����L�K�V"W��g�J!+��Ԏ�����ļ��������qb�[��2|�q;�F�.�`�b�V���Y�KJ���1��@BS~�N���#��-gR�Y%n��a�`�5����T���	���ێ�5#�b����U��2���8FQ?ȍ0\�<��m�ʥH��>��w�b:�ǉVgg�0�[&�Y��W~�R�ܛ�Z�Y��m�ț5}���"��ۦ�8R{A�N��v�99d��I6)�v1��0�L�
Al�h��h� ��ZML�	%��.'��Gd"o��]3W? �O�K��h�s�=k=����$�A�y1o!+�Z�U�D,�>�Q��&�jtf|���$Yp  j6F�S[��hW�s�c�H���qʻ��N�<�3�oT��6�a�gp�.$`g��]���Ҡ�4߀�B�t`��L ���T��X�1*�ׯ!�B^'�Q�	=�=¨����e#�KY��I�'��*	YǰM�u���52�L���8` ���א�����&)(q��7���Lƈ�U�9I�1 3�A�6�T��Z(�N�FT'o��|�[`*O��*.��Q���e5�	D^-���x7z�H	�����T��-,h�
���#[l�x����NQ�CR�+EĩH�Y`jF���1U@E6"�/��!��b&�(+�J9�˪J�����E�{l.0bm�e�6�J�| �7o<@�Yr[�T3h�2ٕ��!'?ZW}�jS�	��0(��mJ��%!�hg�9���ߠ��Q��%X>�:�x�r� �0�%G���anBk �\����,��Y=.(�&�f�`�P���w�7����(�<(6�Y����Θo�1f={*q��!C�T�@i��2�:|�t@�ٔOsS�Ә`�E��ݗЋ���ԝ�7�� ?�^��
!x��W�UG%��z��(�����Iֿ�\o���������B����t�#\��G
��s��(L���"�l�c;��9��TK)��5�Df�B��Ņ��I��x�Kƃś����f�Ь�����yK��Cn 2Rj>�~�q��Bf$�ج9r���늖��W�	~%94ƙ;�zȋ\J0�K@ �°���=��p_��ۚ�I�w�K�h,_��_�%*Ne(Ϝ\+߫�qWM�rG�-�F��K"n�Hlq�]�B/�g>cW�_���gA���H,�iO��󥌮/�(��!�c�D�Њ�ʓ���X�w=B����p�&�rKr���C���:9�TF݆"�X�(�G�9c�[��ۼ�Hb�c�Q[�*�N���I4�"��;W$����#M08�4��<����|������.Ud�S%�a��	Z�>+XW�,qV�2�3����h��,�b^�\G�;��sƄ�LP�������Ē�gX}4`�UIl})O�
�kϛ��g!%Y>������n���bu�,�
G�)K�:�޲c)�c^m�+w�XmO8��1�^�09����O����>�R:CS	��ε8��4��o� u�J@V8j�n#�{8���c�n��[���O�U���TG���.9���1�j:� 2�2]�	�P�L�)L�U�9�8)��O �m��ڄ6B�(�0�4��6��L����q�]�TH߼�0���T�p���Zq}Ӱ'B�2R��Ӻ�X<�܂Ύ���\��I	�!Ӄ"r���s��-V\�z�V�g��:wH�x�`AI����ފ��D��&d���e#�Q�|��ڼ*uF��:Mg��Mv951����\����N;jGɮa�`��l�ǪZ��4�f��r;��G�98��E�%-(.�R:G��)�#n˾pU�"	�.��l��ٟ��D���jvE֧�?I&ɕ6��4����)��$��RQ_�J�"�D�ݒ�tՔ�K4�,,U��;��E����I�5����-�ړk\ֶF�\3������.L�L��α�sf[��F7���VE9�W,�������Ii���678�t�?��\ ���Ne�1nR�E���$)�:��餐�`�4E`K
'���!��*G��W� 6g�0�9bud����3��k���B)�DgQ��VaJ�;VS�l����R���F`�c�����U��FdS���_�ȢˌxRLq��]�1h@��TAqB���y�e���/ms�q�`Une����(�n�G���f8�[
M�S4 ��܉�%YF�Q]D6CN]݀�,�,�a�I�IE�:�ꀏ�F3ms��
2�nA:Ӻ�M�^R�)}���Ut��7:8�Ey�*�c4SZHG���i���UW�s5��6�T`	]��Ï�	�QYL>X��f��]��G�p�T��"���]հ�HKI����'Z
�c?���9�C^7_��²un�z�z,XE��d��䇣��B���Ud�Tb�!�ժ�Ș,z'�P)��@|Mg(AJ�Mw$;����hCN�N«1�9�֡ =xU)�4���J��+��R����W�ͲY]�47��^��h;]�th�k�Ғ\�)|�NZ�
~&�G�L��r�\L�}�Ƽĥ���3tB�8(őC<�~U�戚�#X��iڹ��䝭8��H��Ed#�sMAPK��X��eh�纵�o~���v�L��E�X��u�~&S���e3��u�	�! 1��TcӲ��L�����mFD��e7rҘ�]O������lbq������!�w�f�~:��[���(�R�L�j����ͨ2�3��vMI>��	��]T�ܮt};XHd�د���i�O��A��穔7Щey<�����'�#�J��<��.��3��RAS��	{)��]��0��'ES�����d��>q�]�wW��=�P�z�@&�H<Ι������B1%KE��c[�Y6��G ��.�U2*89b���1j~�[�h�~#�����R�Q�L]O�I��F�,�HI�
E�%���F���Zy����+I'c-�u9l�W��B�ɍ�A&W���U��@�BW"����ձ�eq�����v��zQ�a{N1�u����ʺH�8gW1�<h��v��*r�^*�Gp���Eȑ�R�,hr�z݀1=�y7�9Cw������Fh�r}X!ig��敨Ec�"�G�A��B3JFt�_gB]�K�X&��v�L=am�2*	�M3�:�n�̰����
Lp�ĀjiЄ�~FWa���Z�Ĭ�I��i�u�����08��lw��gΕ;�p�*=������(�@c�5�zxX�)����	�]E��7�l�Xo�j/�B�'3��j|^k����1���E���	|eUp���-@}!��:�A��Ř�}�NU�Lnȇc��쎗���7��ﲑ=�P-n�Iઞ��č�L3��q�N�P�zo8�BA\¬e	�N+"\H2`*n�	���2b���!%��MΨ�Z�ÙĽ�w�nW�������ɏ���1����8n����!}���I��Du��wON:;�ُA��how��l���گ��������/:�����vT���/���ǻ'�?��ã�wxq�8����U-�^TG���N��jw��I��]vM��=yq���>8|@~T�=ة��.����q�ۅ ��}q~�=��{�c��g ���D���̠��a=�ޤ�����������lwo���z�{r ]�ڵy��/��������n��x	,��n�/
f ��/��.��olw�/g�lNW�x�Y�{o�[\����<�l���Ա%t�}�ߑ�� Р���:�0����9~��M�p�9j��*m#��F�GM.7�=��� 1��
������q��_�\K��%���q������.w� �bĨ�+��E�������s�A��ÃW����*��e��qa��@vi<0\%ܷ��~��N���3�K��{����?�w�G@�=^��.��Ն=F�����K8��q�o|�v��]FJ�w�Ev�'mE#��u��q� ��X{{��1�7l�o�h�/���n�|������>o��<."�|K� 	���ݵz���v�CW�/d۔w�T/`+�u�Y{��.G��+k�#���}�6�n��``����2��G�LF6y�l��M����7���3J��'�pea�o*<�t)P$�.� :�.����*��K�ٱSo�r&(&���;� mZgy:��y*������E<r�^a3qd0H����!l�3{@K�g�.-n_,�Z���}�s����{�ڴD�u�C�D�w ª w<Hr����Vb� WN��D�qNy�9p�T�/���[Z�H>�F�7$��	�X<���Y��6�4��I���U�I����4��cPu(�@+���)#���]�C�� ��#6o�uc��8ۂ���0{��%�n�H�k�S��/JL��\J����F�O��45T��,�&))ul_��s3Sە��E�T��{\Nz_�xs�7�t"}��� =(�)N$��S�J�����5�=V�{
=�T��=�~O�V��m���o���x��Aq9p�P�Gq���~!	?�e��VcJ�G��G�~��ZY�iV/�����j����C�8K���\��Q-�!�"�c�W�4�6~Zb�iWE�w�६�ՍXD��p��`5YW�B���&�ُ��X��9���Z�:Ȏ���~8�N�Z�����y2k��yK�{�����I7ni,"´���|�8ռG;_�&X5
�
	'�ss���C%�z�[����VB\�l��k\iR���a�T�����{�p���~/�>��I,�!�f�5m?��<����j2�iOe;��
�ot���ݦW<ϖu-�F�&��M�4��hcIx�v׻�-Kë	��]��-�z|4�������t��αw*u8 A�8�-��]c��d������x�k��54��T&����]��Mʐ)�C-���uz�b��� ���l�b�P���׭��+ q0�.VƫY7�)�V̝ύO�?8|��s�$Kh�@�js���m8���Cʖ��Ƙ|8��-D���6��R�r'W¡�!�e)�1#���J���/�u���`�L�E<4ds��Q\ES1Cʝ9\۳�]�X�K	/���u�
.���e�{%��
o�ԡ���t,��܊�0Q:��Z�ë,sct>5���v��?���:�w�;�q����������~��!�������`��o���͇6��j}�����R�_h<�g�,�����v�l0X�;OF��A>w�����-
N��>�`HD��[���i������?�QK���L�t�%	U�P?�#I5������ !=�=�;��B�Ĵd@ǳ��o�@� j�ق1���9����ֵ�pz����7R�2b�` t���Og�u�zÕ�pL�6�}x�ac.Ps�$�dN���x^0����wݭ����)�&%�*�[S�fow�2z��rKw�����uj����P�"���t6X[��R�^JF��F�$���HsOB�%�旙c޻���0�f>�wO���o�N��L
QɅ��X͒ސ�1րi��)�n���%�0��s���K�T`��Ej!��s��"�.萛���(�:�^�����X�����z�����F�c�I{o���\��(�a>9��Ɣ�����D�?C�ju�Y4��W����Խ-����ҝ;��Lg��vٸ�N@�!��6�h�˒٥S�����nkkard�,2��K��Y��bQ?�_0п��o8� ���7 ��_-��{����Ϫ5[�h񕢭rg�16�7�mll46�n<���n��w
}�'[x�0&*^]?�ZonH�y�v��-
@��Z�*3���1�]]��˜��.����g������^��Y��y��ZO��yc� f|�m^��16��8�w�?��/w���_^��-EcXi���Y���5F��<Z[�b>8�W�C�*~ˠ�ԅ�<W;��4�>�8":avN/���-�j��2�:p�x�o�㲹�z�
��h`�DV�� D�ފ�u����>w�.��.�5P݅]�5Y/;�!<��kh�>�
@�=Rv0 \��
9���L��&�T�T8_�m^��w
+��ԙ�d�4�c��_t\���V[�cŹ\��Y�{;��U}�O�;��S�z,��ݳYѭ�q�)��NKf+̾�Z��E��K��+��t/='>��Z����F�92� �
gJ��S��.)��{��������K?��^���=!L\�^bFX�s�ٵa��W�}9�=���1�M����Mk���Mk	pH�p��l]a��^���@Pj�*i"Jη` �-�>Z�X��0X~��0.��` 1.=�,���뛍�G��[l�?�8yd���\�ɭ����ܗw0��n��p�fQ�������^�8�&Uʕ6BrY��<)��b�C����w��-<����l�n/�EN�`�R`���]����.}�cN���/�`��?j�7�?C��������w^n��]]����o-�J��/76��͍����M ?�� ��n�j�ˀ��脭_�o7��5�O7m.���>�=:9}��e̛OC����V��_�&g�5Xh�s�C1�|��Fƽ��~k�Q�z�L>��姩�����oF ���&��� �i�ŀ���9�(K��j�y�Ѫ������ǀh��t��_��
O�켣B��Q��#yt���������~�C[�����y�Ƽ�W��_��Dyk���+! �o����q4/�a��)_K�=���(�g� Ne+��#��sԏ�w�����O�(6���j����,�p�y�0��	�s
���ߜ\́*���#���47�vm�wM`�|R� �*(��/����V����6��kI4��BL<�XH��K�T���'��_�⛡���f�d��TF�E��*�&�D�H��>	%���~4G��8�G����*���&O�\�)�(AaСZ��c��B����;j{���%��H��u���'U[y��]�@����Ϗ)m-P�Z4�%��VS�u[)լj�D#	��z�T�:�Ǉ���Ȍ��S囃8���L����]9�g����I���)�V�k"�����{���A;�i;�Շ���>�t��ٯ�;_"�av���0G����2\��j��B3�6�2$�H�z1[?Nt2� w>�&R�3�����X��Z���d��^S��ʦp"�[���#¿�8L�1�
a��U���=&��'`�I�`X�xё�Ӣ��'��=<�T$�,�jpx�F�%�d��:w�����׺����4"�b<�2v�{ڥ��.��4w�g���r%�1�Q��|i�T*���˵�a�y�΋Xnn�M�
}�X�#m�ȸ
X���q�z��&԰=o��%�fqoe3�c�Tqa��;�G�Ƽ&'ts��c���M�x�7��]���&D�Tw��=+g�W�.�����˻t^�XXI>���x`��Q�I�9�3[��p	�����*|>���I��аQ���'�Вo�A4.|Qh�t"��]K�q�� �7c�
u�����3��I��0syZ�&= 4o{{*�2��4'?�>�{;�#z\�����)S�+�l�	�?2 �'RV���(�0��aΦl��׬�,�l8u�Y���=a��:� )���+��M��2ˢ��~S�t\i�~�!���p|U�_ X;+�h��Z\	.�jǪ��D{��ۙ�?=�
zei�ۚ #�>cۜA�3�`�����c/tT܆�h�V�k�r76Y��c<��S��Y�h�Ћ6g�d+W�4�"��]kZ;3���H���e�R�u���b��)�8�F�/d������j֗������ח^���ipS�cFg�9�7��}�:��A��p���%"���A����9u^�W�u�p�|=
��>���܆�쮒�M?�7��]'r]���陙���]n���� S!~�8���*��IZ���s�v��X�D��\14�����݅h��\E�Vf��x�����&�Z� ��b�iɕw�e�2����?��F���N���eb�i�H,r�N��W=�hY��/��j����ƍ�����s�Ɨ�3K��+c�Ns��C0��e����J��(֕>P~���N�8���vl��1���n�����xO��Q������p�L��N8ȼẻ4o�ԩv2C���. �Ν�n�~��N�����O�~PWp<�v�o����'u*�[���
��T*�{;��	�1mc0m��><�!r���]�"C��:!O��`�&�/�/���p�|66����}B���r�U^�
��~g��C���h��M4v9JELYyds8���{��>�d_�fP��X�Ċ�5����v�ۻk���屷2���Z�_o��2!����X[���(`0>2
�(��Ʃ�ή��gԠq�V�:��T����ۂ'A���C�c%��W�q�|��s��(��ެgRZ^Y�H�g���-�	���yT��JV�nP��nG��8��Y��hB[�Wg�ȼp���=��Ŭ\�����-(�dƗO�������{U2͑�ܨ���z��{-g\���\���wd,p������I�o���L_�$��FC3�8<k1 kS[�s�l\EK�r�h�[����]�Z9i����;%M�\�YuǓ�i����IaVp*�&4����cí[|s�$P%��A�gi9�>b�B�~�_)�]S?�#B*���^	3L�)���"o����f��N`]<� mnr����o��,9��"52b���B�lt+)�Q�c�~��BeP\�I���H�yF^n�N��ה�?p�[��
I�?�ZW�%��t�����a�Qg�m|�P)��@W��)�K@��4c��@�,�"��P���`J�#V������n�ECg�o�����5�y��ǒ4h�Q<�pL<7���Y?C��9��j�����5|!^��\��[:��'�;��~0�U wdHN֯�s��[X�J�C��A(��Y��'_J����e	�r}S"]�ڕ�4��Ӊ����p��L�~���_?�Lc,��36��l��u#a� OU"�k�V�k�j(�;�L$7�ڿ�Pa`p�(9���	ҡ�ԛ�7/���q�����y��ȥ)�;۝��3=e��)y-�=����<�?�tuo7jÍ�&���s�t�~�2��ObT�G��]Y�M	�V�,`I���i��b~w_��(����^m@=��^�����>�G��_�89�}�:pv\0�E�lOu��|W�f��J��84��,�~��40׭��O��ih?���`N!��j�qR�?�%�=e���ӎwL�*(���hC�&㷬�,�t.b�X�l"�"I7hw��ض��YC.i�����yB�yq���c�F@18�\�7!��i������ /��f��٤Ee,>�&R�`��Sˀ>��wv�7��?��$.DP�� ��F�|
�x�sF
�;�Mp;y��r8ll�Z�akF��:�M�� �#ZJ$v#g��	���t�*�n�c��u�����9�݉CA���Q�O�_�	�o73U1t+��E���;;��nq����o�[��ƑD�ߣ��;`��8�$�)�G���N��N최�/��/��X5"�Ğ�y�}���/v� �)��EV�4�;Y
�B�
�*��a�St�u[-D��1+;��E8g[�AS�ՊZϺ��w��D/�ggP$ !=������x�gX=���1}.���oA�gl�iI9�3�b f���t�7�f:&t��V�A[�M/�n֢y.�2gA_��K�Pi�)ت�j�j�?�b�Z����U���F��g��
��Әs|0�5�ܳ��.!�SQ=����/�i��B<e�cE�s�O�8w�ԝ/�_&��/f��8��Ƃ�o�^��e[��_Ij+�1ayڞ��T�}PUo���w<[�}SU}_'��l�ڏ�.�P�c�}_3ݶ��:�u����ah;�[1]E��ٚ�P�p�4]�p춡Zm��m�v,�յ�o�T��٥Y�a+��Y�ij��YF@}JU�Qעm�:~G�5�����U���i�=MW�긾Ka�g����j�7�Yj`�Z��k�g�ֱ`������9�0ږ��UŦ
��9 �8�:�H����tǡ����F��ն�u�*�TU/6.Y�u�J�2l�lW�P;�ݱ�vG��y��(�Ӧ��3}�V��<�����]�q�m9�����9��HՊwmOUU�i�VuLڱ�6�;��v:��с}l#�E�d������{��cSӁ�& �����e�fV�I��i��_��� &(F[w<��(����aY�YX3k���)��i���I��mpͲ]�mSGU� 6�,(��f[�LǇ)65ˠ�\��Mq,U��r�u��ŤFb*`U��+�րl0� ]�:fGU@�(���&le��`L@��u=ݱ��9��v-ճ��5���sKܛvS,�P�G��4``�t��
,8�m�	6�f辧�+6k��N �~[*b��g�:Є����66O1ia�%�M��)�'Z�����Q�5�m��؍^�üݩh옚��N��؁J�Vᯎұ4[q|�q
{,oY��X[C��:���B�UXx�����؂�ԣƕpj
�R=�S�(8�[�!�5�U`8�a;E�)@A�f�@�����tO���� �9.u<�;�8�̤VQ��Um�h'@�l݃ER�u��ntSu5�+j�����N9H#9	��"8a�0�@��'���h^[7���`���ـ���CU�;�=�AO͎㶩mj��5���;��Q-<y]W:���ԎR�9��Sj)؋��y�$N�U��vl
�!L�J��,�� *���m�X�cy�\AG5Kw������s�9g^�#~�w�
�Ga�];��I�g��� ��RUNCj9��
(f)XM=�f%��%�G��laCZ�xP��:��Vm8��N� Q��x�cN9L�SC���w��&�\Å��РcZ
:�	�6�57>�W����\�Q������Y��y:�R��~$=��z���`�}ǯ8Tש�nk��î5,���b]{#���x
����jv�n+��8RU�*�H���Ջ3�����xHt߰lG��,_�������ݱ�R�����_Ԝ�2m�!��C���U�m� Xhñ`K������&[ �8@<��S��L`k��Y�;�[��T�{(��#T��ۄ��3m -
�خ<	� 3a�����q�5b'�|��1FGl�;LAλ�t�0�CH�G�G�JI ��,�p=v��:���� ��� ߢV�VGate�ݝ������Ð\�qpt0`���р��M@~_u�z���C��;����x�n[����i��X8�&5�[�?�ྤ���}��r�iο�Cy��tK�@�WM��?ļ�a����e2в�Xp�c芚�� _����W�?�H���H����1I�o`�C���[<�{��+���Ϸ�ϠNߡ��E:�'NQ�u�	��y	'U�N�����q_�	:��-�è&��;c,�7X|�� ��8y��:���&��G,Əw�P{�����
GI�����M�_X a�����t��<yYf)%��e�DNg{S2�����E3�r�c��K\Ն����-�$@�j�3����݆�T���E|�1����QŨz1����yȌ�������7DK�`#�nWp�sH�)�Ib��=�ِ�O�t��[�ԟ���gЄCy�0�iCv�Ąr�_�t����x�#� 1p�k�r9w���m&o�	�	����u��%%	�e?��c�Μc�縻{�����j��a�1/����[���u2*|���ya����X����2�3�L�Ѽ
�ԡX�S C@y �)7��>s�Zޡ�Ե�:ki�f�3��v6TaP��pD(��d6s��I�|Dˠ%���u�Y*	ZL1�Vt֕���$g�Wh3�S"�Y��2<�����ʕ`�s�cx+d4Bh;����gwi�*O["+��T*����C%��-���U��T��05����f���"-m�~��<�!��y'f/�#���S0e��eG��ϳ@���t��
�I�.�`��Z=�$�V�[�T���;s��nK�83�͛����b;��\��8�E�SK�L��A��jo����O��?��o�]a�Z~���%%=��_3��s�����q;/��ۓ� f�C�͌=>_���[l� r�pW���T����T`8Z�f%C7�r�GN�p�-
�IޓԒ�l �	��f�I�y=�[nKl�~q�	�+��zC�d����tyS�᳐�V�d �?3��9 ��� t��WT��K�� YG���<�����2ݨ�������Q9!�tq�[c?���y2Z[*���5#
��LWc�̠*�@f2���M(�Pc�'��7\.I�ԯ�T��#Z~@�橽5�'�n���$:q��ix���H�Z>=o�����h��8'�.�����P���%/6vv����Zi���p�/��Z��	� �$X9 � �3�˭���g�1�F���'gr+������t�v�Ɔ���hr76��x'>�!�5��8�O�uUԁ����\�œۓğ\||I��������|^�6��康�H���:�V�A��_��4<[��
�sK�V��'II��g_��
 ���*�/�����R���@��e��/%V�.#7n��\
��l)�͕B�>[
r�R�%������܌�t"��n4�R¶3���8��؍F<r�1�O����ԽQ/s=��N��{��q��w։I��(1�n4���f'	�&2� ��}%�c<� ������HZ���M��8�)X)����;��Lnԉ_2c��#�J���a��6�0�S�;��Iϙ�aZ������vw7�{�;C�cZ�B���{�Y�9��q8�]Ɠ4+�Ye����8��w̐��G �$e�/�Z�z:���,��;@kCk k*W��7>ϪӛUgf�Ru����P9��Ff�.�8��¿Жe�OϾlg�#��̙\$ݚA�92�j��Y��{��e>��烰�v>�QA��[_���{/�ΣV�+I�j��mc���f�Fz�k���a�R���"U��e: ���Wx,;I�n������:���u��%��y�]v��1?K����֒\d1����Te�?�̺�3f�����5ۮ�W�3r/��SD��v3שxN�M|`VЛ	f�Rf?�5D���IrM�{ ��$�,1��{L"�,"�:������۩���� RӠ�]Uow�* \׀�mw�O���<�+���"�ߐ���Q��R�j��"U���_4/~����rV�� ���u��c�����Ͼ�6na�g)ze������_7_]єj�W�
^z[���[���"���O�XӮ��JҌ�{h���oh����4��R�Xp��*�]X�0��ߕ��y#]��O�i(ڑO�4r�  ������3����c�Q��6��Z0@Po"�Z�1�j�q���c`lh�x�E����ᏽ'�o�	u�L�E{7Jl�S�>��ife��8��zj���]�t��G�����$#��b >Фa��R�4�J�:�(+�5n���61�f}*�	���+��I|��5ȴ⮡^]G8Q8��_��V�s�}W)��K>������S3���_E��	vm\w��P�?��������yڼ[�?���o�VGM�t���V��� �k{��K�G�y|t���%�9� X���Q�ѕ����?>�}|T|�������	�a8�#�ȁ\���Q�ù�ޣy�zK^�e�Ѳ����GL�i8BIι0�,���	7OR���&\O��i÷�WD$�\����,��ԭ'Uf��H�T�-�0(+$�Y��0+_s%X3Ao,�͗�ǊM�`n�\.�mZ�[.�%�v^m�.��s�R(`m͔⹟����q_��E���#
�����>���S'�'��I,��hA����5g?S��!)Y�����}g���w�������r��m��S�K�9N�!���K',���(�/򒈬}:����7�$��DfQ��LNG��������O���I�a���Fac<	��R��$cs4�9L��R��F��[�;�����u=���馅��mW�+I˗c�� �C��~�F�/�#B��cB�)���\�oˉ������&L�;!>�	.��+<yT�s�,�4��&yN�?ߙ���8ք3�g�h��fg@p� ��#�� 	�T\����7�Po���9�i���u��������P�� d9��)6���r�wk�]B9�j��P�l��5x� P~��O>�AhTV:1�p �;#�~"3�,����95vC'�>��:�P�+]���i�G]�z�,�����[�#�͕6�B��O�C��]@%�M��A�G�o��8r���ǌ'l����B�pr쌄oGg��5��.�w��ㆩj���~�[�|:�7�zٝ(8To���:_������i������/�/�����>�y{z����p��y;T&�///?����L�z��_>o�����`��7�J����I�^Rf&�(�,+6�<@�m �%��RPd�GX! .g�a��'�pz|Ҁ�q��p�g��%�9���k=�jM��o��
q���ԭ���9����k����1+�)�$�1g��|�$b�,�WJ#~���NK�{�j��o?���G�q��'�����_�K�ב��"��>9<��q��n���Q����������n�����O��E���֯�֫V�G��_?�n�K;P8��fh����J�����i�D�� ������h8�^���� f̿���	���b�������L(2/� ]������t���!�K��A�ԍ�b���<@�CxI�  4��p�	p��/��?e����B�����(����g�#^̝����6�"��,by)~��V͙�Q&:�����P�	8��Ko �<s��Y��!y_���ן���Nm,��1U+��S����V���"U�r��A�;��\i�u���ꀽ���r��?q��8�|c�<}s�:��d:�S������A8<ƈ ��ș��$�[2k��q��j ���б)���'wCU� ݩ�(b���;�2�d�C�����3�ča�B�4�L�iL�)�=��^ �0	�����U�&:e�eح_��0��cʉ�xw1��B�,�;$���-��0&�G�BDGo�Z�N"t��Ca�Lǈι��y�{��]��5J�p�Wo��X�����w�^�����ň��Ԛj�[�+�╇��n������ (�^� ��ٔ��<6�{�f�(�n��L��)�H{��!����
e���z|(dl����C�͆�wO��n�%�SL���������vq٢0�1�M�<É�L�#�MU��?�0MI����gKJ��ʕ���V2��m�NF�R�=�W��1-�����,2��pO<���қ/�WO䫴�Oۿ���o�rN���~��Ch��޿���	�A���ʆ�P��O:��(����ޓ�郼�z����:x�hM<ó�1�es0�S�P�\��j�\���uY΃�q7��D����l�m,��3������[���JR%��}��sv�CVRY���_a6��>� �,˂ϝ�+y��)!o��z���C�8{�g�f�g�Kg��2�27�	I�q�'�`q���j�ÖC]g��Aݦ]�L�17�Z`z
 �\�!VgS'�J�e���,b$c��.��A��3��u��%��r>�b�r�	C�켜��!��x�a	��{�����=��%��&��/��f�Ֆ�e�\}����}�sw�}�*Rgڽsݞ�PI�?-R����&��g�zg\◪�
�V��At�����G�܃��!����,*�q�3ʺ�t��1����H����@p��uqſѧ�k��w� ^��k�af������Y���JR���}����Ձ�D���2�EU`r*��7V�#U��_	;.���Z�Ζ,��{X^�ri��׏��;B=�#au����߆���:���Z���$U�����_���/] �� �k2t|��=�a3�ǿ�G�x�X�����*d��>��b���h��>C��h�ː���Pȥc��H��>�.}�����>nOl	$|������{���,���þ��ǋ��p4�(����	'�@�d#5���S�>�@��M�������l1mf���䲨쎫���Cb�_�]����G"\����F�z������������^��&I�����p�`�����jGR��#���NКl�bP��O�}��.�R,��)L�ݻ9'5��Z�j�hɏ�S�.jЀ����3v*f�2	��Ɨ�]�;1*F�Z���u����;}�qS��ρ�x����Ȕ��\������G�k�)���gaanZ���k1]5Q*;ss���c�W�OW0	��o���)N�'5������W,&��<i�[ �F�xgx�܇BE��G��S��� �V�u=뉓����j�0��3߬;��M&��'��d"��q!<yI���㕇Ϟ���"�����Su�����T����W���������i��.��So��i�"���i��9�wQ [��1~)��_� @���4���^���w�P�L���_7*�%���E�����M�����;��Ϝ5�붳��yWn�C�~r�����%�,���ѿY��.X^����q�~#~Y��Hj^~P�3��P����%vj	��.]D�h��v%h��4�}�ǸP�0ޛN��{Բ:��u�rѧT�H�+����)��$S�L�˔U�zҵ�?������Y�/Mg����W�*�o���A|]���(`��	�]:̉�q[�e�f@]ÝC���@��*�;��� /h�'A��#9��/�Ae����F��n�`�sL�Q���$,��?�`������<LQ��S�3	s6���:#@A��=R�h��4.�F��A8�I�#Q��º5FD}�þ�=}�|rLI�����.Q��z�� ���� x1�,�{nx�.�0P ����j�CWܓ�Cz?�����8Ͳ0���}n��_�]����a�Im��G�����.��_{��#y3b�\���37�@�$|ȶ��i;�ҝ)��� ���)F��o|&s�m�c����i�V���K�X�
 �#c��̎7�������u�tރi:-�"\�}Uo�7�廫Y�7Xo��9�w�M\�Tnkn�*+�o2����E�߻<��t#�_����]Q���E�+�߇��_��Vo��7�ꭶz�}���f�}t�_,��X�������E�uE���U�e��E�og x��x�ã{�����Kr{EfO`<Ѕ�+���2xvS՚�Q`��pwq(:KXg�Vx����Akjָ�	#$�>e�jd��<	�S�ٜ1����j���c?]��{���E<Z['uFJ�x����/l���hM�ūE��Du�"��Y��@Gl 	��(~Z�*.��DC�����gI�(&������J���>���7��+~�.,�����H_I�z� ���x�Z��ζ��~�K��Za2�/�O�y�8.@V�_��s��f�X�$y�bi1�Y�7�������J�OYsJ�Ai@UA���b�s}�9O�xwC��S-��z�=��d��9�ղ���b����y��"��kise�V6k��yZW��O��Y���W�m�&�?��r�����JRu�':����U�?�����]��K�V�?���I�T�?�c�S�����_�Y���Ӭ��q�.s����6��*Ȃ�U���W�*�Ot8/���_��7��
�01�q��9*(�x_�2H%�])�M*!�O(�,��Ӵ�3�Ћ�a�^:w������ӄΉ{��>��L�+oA[�BQ�#�e�t���Z9�OU�c���y��_X t "�|tK��� `'n�K�(�E�l:��6w0s��Չnײ�G��;��E�������+�%�2�_d�������u<d�^�#�f����h���f�S맂YѬ� h ��t�1�rM��<N+����N1v�/��y�V6������2kL��[�J���!!��Lr
.��Td����2{M��6���'l�g�����8��3lx�� ��m�� =��Dk ��艇�p�s>']���8�<ܡ�Kp�llm�ev�c�s
R85w
"lN���P~g%���<r�8�ߟ��f����O�� ڣ_�����ٔ�͂��9 �w��D�����Z;���	����M��a#�#*j�Ǔp؀��t��:rC>�����S8l�i,*���զ�lJSUuӴ�j�h��}��*�; ����ɬoa9��N��t�q�q�Ĥ�V����������|���z�6��uZ��`��E��z�o��ȳ�2�'C�L�?_ҙ_
��c��̝��Kû�IX����2����/�f[���T�����s��!K I��kH�'�gx�{d�2�?��6�����W��rC�c	y}~�G��9�+W1]��x?�WPwz�/Oy�1�f����R�w��ȁ;��[:��B�l�n����2�O� ����Ν��o8�����(v>����w�BRW_������P�w-׮��n[
P|�.w��b �6`; ��S�Q���ν�h!!��.��w�pR�X���[�˻w����{�|O;��k
�y�x1p��V7So�����|'�'-ηB��O���>���x]}=����~9|Я��	c��C:�Dr�HX�קti���r��J�1d������q|�x���ާ�ߓ�I���)v����TT� ���hx�(zF��>>�����FC�u��i8���]%*� � � ��tw�Y<Ğ5�G��P.{{(�1�ڶm�xe���x 6�`X�ٵ
u
-7&�_S8�@��N��f�w���h>J� <�0uk�:d��
�n�Q��,|�����cA���}�'5�E���n����\�O�A 	;B���'�.5 �����'�	��W~LA�F|1�],x|1�;�w�\Ӽ��ԅ��ش f�cbख़���ߑ���pO�0��sL�$?:�.D��8�w�~��p�����<�e�yo�����۠�w�j<�˅*=���� ?>	c�B�3Y^Z��?(������K�+������G����=��%9񍻧FY��ng��38fu�p�>2��#�;C�_D-����#!�Z�ɠ	�oTM�h��xF����ו�U���N��}8��{o�y��/�Ey��I��Z�p^N�����>Dx�
W��{���|��g�ʫG����r�<��N��x�[����oAZ��ـ.IH��n>���t�?��H�<z5���p�������1Ho�<W.	_�d9��9U��Is��%����Sm#���aAE5m�z�[IZ�阜�Xq�wY�����<Bv��#��N�c~�>�O��%�~��::_|�/>�M��V�Sv~���s�?���h�b�������߲����$U�E�+��>~S��'Y�o٬?K����nZ@�����I_�����> ��H��{>����Er�	;�C�s��,u�9q�G��7�o��LH�ƒ��p
O�N�#|N�B�8 h���C�vF��^uwosc���JNtB1y�fw�4���N���wB~`� G�y퇿���N��`f#o����MP6=ʺ�����u͉�y�y��j���Ɨ�/��d�4���w�gF�&83���KLUZI��?��q��wԿ�6��b���e��o��V��H�������"O��|d�̠���z��$NL
��l���T�&)�jS)2�oF�?�}���Ԏ��Lb8��~�y�0qт��Q,�a��+��,7G���І�;�h�'���|8���غ¶�<e=}�$�؃Ln�OB`(`��P�
��� K搈�f�q�4���s#?�X����h���.;iM�Ik8p[b����
�;>�Y�@����0U+�����ŀS��[�E�E����2Tr挦��J���t8�9�d%�J�qk�!����E9�CC=��Ȏ`;k�Q�F4�NN�ܦ���tR�$�����vx1��h D��PUm�k/qǲ_�l�t��f�j۟���o�[���;��b<����㒲��"���g4��}��tE�A3#ߙ�{�x<�{�p���QB���ۓI8)~�1�;�)�?��M���d'S�MD����2��\���)-����f�����z�_Q�|~J��9����x�(lS�+gϊ�c���mxA�jE��pj�t��F��X
����<�����)�\�dʈz@d³��m}trh�a}$�ت�lB�3��&ë&����а0pD&� �-:	�C����i2����L.�n��l�"�y��8C�.i+ǁ3p�+:!��	�L��R�h<	�����G6Τ�>G�,���ι3����8���.��1a~�vw�6���^���q����^j?���#b萛Vp�`csw�=�%r���!���#��V�p�ZSEi9�P��0�l� �0a�W�:���8ܘ��2	G�쬧�����(��zDd}������ۿ�3��e���Oo��qKPŅ�b����*����.����������3�2���%�o����o7���} d&'�cY���7[J4'����9e$k^��Z̮�v8#z�y<���aq=�P��`�2�	%Ȧ@P��p1�q�iK���Z*%�{������{���� 7'�x�m,��U���f��[L�ת����߶_��y��{�Fc8(�~�g�Ԧ�����r���������曃��_���������8z�'��7��o�8å�V��R���Dџ���6�T�Ӱ-��C���*R%�����,�o�>��M���p�D��@>Q+8�ʋ@L�y���G��BH�_�
5����՗[Bq;�����s�1:��,���>�ے�y�.����g^��d��8�u�S���
����[{?�������-�[!r��d-)��'=���M��/N�य़;��
�� �)R�Pd3U���ii��*�x�Y� .GIeOJ�J�󁡅hV2t�.z�?���Ѥ ��=�z �Y3�f���z~��2���{���W����,]l��˛�|Q��R2�ퟙ��9 x�Y �6��J'$�K�	^���\�<�����2ݨHyo�5�ܨ����쭱�F��@�-�����H��(�㝰ۤ�R������&�hw���F���MV2�՛Dڡ�*A螉��'�z�G��+�_��b� ����B'I!i;g_��k]�u�kz0[��+�[h���J᎚-�P*-68)T�׃��B�>�J{W��0+�$7elE�ώ;wڋE�Es���KIP:k����1���6L3��˯J��^,�_PW��IL��&���]8{�d���?ؙ�j����O���6��a8�9�8L��q��`OҬ�g�A���8Љ'�Agb�.�O��ɰ%%����>�`5S��O��:�Yu�o�R�	��%'��w��N1q>{k�� ��7�*�s:�h1M�bZ̀Μ��Θ�Q���Cל��V�SD�*b�b���RsCĀ�ʜ��=��g_�3��lzv�L.�n��S)���?�D؋��KYP%,�ғKZ�>�glƟby09��Wgmy*_�Ut��g�,����6��B����jT�?�H�:��M|k�+�`r|j�su/�P�{_���r�/&-�x��פ�φ�ب�����_I����_�������m�uQ��^�m�n���!�ILAX��������M�Ǟa-�'G��P!�W����e�1��C���Q�]Qz�H>?R�Yµ&�J��À���Av�6�	���L]�짹��e.1�\S�J���o�Jc�;=���do���oo��.�����������S:�z��U��n�ܯV��U���ͣ��ov�V��ff�k��������_E����/�����X���뷰 )J	J��?+��1�߆��}���?{�4 ����+���m����T���G��_y����-|���H�wdR� "��U8�Hg����z
�=�����G�Z߯ߏr�݃�k�t�ׂ~K saW��;X�D�ʹ�s����~��?J�!{u������?U� ���֪�=��oI��b���#+��� �%{�['����ת4����s.����H���8!_�Č����T�h�g��Y��H�ɓ�K�,�����]��.^
���r�������  |r��\ ?�"9�Q.�|��r,eP[�ǖ�����E�ҿ�=>L�bݾ� ��5��z�@�1b�:�N�k��%ifM
��89vF����8�8Do�c'r�^ۃ��l�BK�p3� q�I
y��p�υ�?��&~U�R��T�*U�JU�R��T�*U�JU�R��T�*U�J�`�����[ � 