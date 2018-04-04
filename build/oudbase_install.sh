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
� X��Z ��z�X�0X���8E+ˢ��$/Y%�]MKtZU�Z���:K���4	�R��Vs1/1w�̣ͣ�O2�� Iɖ���ͮN��A�-N��4Nڿ����o?V���wm��+��p����'ߪ�u������/=0���i��P�4Z���~�y��I>����lpӛ��V~��X��O}K������a�=�x�;���R����{�o#
���ypO5��Ў��"Ĺ�|�P/fy�Dy����h�N�Q2UP��d�fS��b�W�wzateQ�O�0�#��������(�NO���YC�.��ߣl&�;�~8�Z��T�ɀ;��y�ɏ�i4u�g�X��Q^W9=k���_�� �~:����xZ�6��Nm�k�l�=l��~9�.�<N���x8�&iq��u�����TMSu�?瑊xҏ�_��ʢ�,Q�t�<�i�����a�r���8]�Y�0�T�\�Y�Ж�ҟ���:~�݄��'�6zC`���$�l�Ϡ������ȑ� �a��q?J��?�m>l����m&@�K�0��|ͣH��`x5Lv�&D���3��8�p���q8Ŗ��y��E������������ͧB���	:x�}rtpp|���l��m�Yl���yj��Y�:�&�?s��T����M8�E�'N$x�=���?�]��6Z�`��sx���~V;>zݭ�e�{����(❌�p2��F ������n�6�.������������~g��le�8Z�V���������Qw�����g��t<��×;������u����Rzǝ��W��v��Y��!�aga�V>8�_��7QFH��AV�Έ���uvv;��G�^���M��]�t������z�0�s@���� �h'��H}���S��m��:��+i���yϠ^Β>�ާ�����9���yx��Շ"�ݎ��(��w�3.�AUByz����g�����@mr��"B��<��T3V���������>W�m�����>���}��2�/�<W?Wu�T��`P��^�G /�/s޾�z��P�y=�z����΢�(�Ś����hl�@l�T���v�E}�{a��怫\��DM�ћ9o�v?�D���zo7=#�	[�{�=�kn�O�p�Z5ϦjM��~�in��0�$��S�v+6���h�W�+P����=��up�ܯ�D�1R1)��c�^Ɠ/q�i�W�������k��ֿ�|p]�|��6|)`�+8ə:����iH:,5��� !��*T	H@�	��>7p<�5��j@��w��'�?{�@� +�ڿ|�c�q���7�6�����W�?}�zt4��d��Ā��O���5�Ϋ������5hU|�KQ�-�׈�!�^��3%�A��Z�XԖ�@���ڌ	� OM}�����sh����b0�%�g~����9�w5v�{/�u�z]�vfvX��KgW9��༦�L˳�IT�Iw�mϟW��7��Ճ����5]6��e(�"ɦj68D�)zO�XZ��*d%Y5!��H�M��HU���k�L�;́�B�.LQm��B�[�Љ�T8Ng		�av6C9o���2$��4C9ɨ�v�q�.4`����~S����w� �@�O�)mh�l����΋k]�����n�H3'/:����B/�^�~�hJ����E�PZ�泾��V:�4���Y�yy�~0�4��+^ z�[z�.��K��K��wYM�Ģ������w�V�3 ��}�l�u��l�$(��Q����a���p�����B~��,y�����|z5��k��Nh	X�	x��^��$��w���}��%kၺ�%I��,�(������4P��Bs�<|~|�-��|�lR��T�.`t���֢ee	h^o÷6��+�j����� �� ��<�S��ɐ��T/�T��Su&I�r�6���(�̟��ׂ�4�9jk��u�m�c:���(� L�̫V���H�^c�܃�"P�l�Ϸ�:�Eh�3�fa������d���&����;]Ս������#+����x����>l=�I�i�>φ
����Ȥ6(���U��?݌�?_�cb�"�(aB��UY(��u��c��f�б>����U?�/�W�A�gw�^��k������T��	-�@i�K���"QQ=@��c%��:���Z
j��J}���#����V����e�?Ù�O� ����s�j�Uśv������c������$�0�����hʠ������O�p�jބ����B�`��4P"^H�f�X�>���ф\�U��`���Y4M'�����,��|Z���$� 	�h�cMM�V�����/����d���
 O\�.&�5��_����[\W{W.#z��|��ml��9-~�-\#✶Y]uww�:��)��[���ʟ�d7���Q��h��??�%�VX���E9�'S�P�\Y?���?�؈�+�>�IFR2_�+�t����ӾJg���*M��d4E�f�H���N�1A����;���F����N�<�pKa�vT��?�X�i<�*K�H̝�s��\�H��-�#����l�*-����ѯ��ʇ��eٮ-���0��;�e���e�V�|���G�DZ@��t�X��Һ�d_{s��`�<I�&���dJf�$ʦq���������>L��sT����d���>Z�Áy�L����y��f�+/���f��p�
��t���0��?p��#гK�

R3V����V���}���ۿ��7_��w����f��x6��tc`��}@B2hg���������y�m�V��� ������I�Mp��["2��h��G���e�_"���{�z�<����:x�k�W�kP�qT[8}R�V�H��Ԧo��sQ�C�=���o������v������1� ��!vԯ�=9@�jx�N���~g��Q�Y�m�|��K���t�������?e��ct����R�u����,ce���>�t���� \]yȏ�<%x^8kO�5��>�6E�|�Pu3^�8��v��z���f�X��uZ����%3�b�|�Ѝ�vTt�~���.:�s"�K8�t�O��s��<�P�hx;FJHU��RFJFؕ��m:�{;�.o��f��8Nn�g���ܽ��c��-��Jv�;�h�̜,���1*t��9Vx�6kO�U�I����[����s��f�}NoT�O;�K��F%��?�h�P��[$��R�~}�������6��z�כ���;��vU�ȖcG7T�L
0���l�8��e֙g��7�����rB�����Ɍ$$ � _QxkY������P�b��JAz�������,��6��?:n��>:���H���׾��	�<Z��!����~���5>_$���.��*�ߜ�����Jk��+H�_C�����;��W_C�1�����j�t����]Ƚ�M���J����+�s_
��=Wͱ��Axt�{vج~R������c��(�����s�.Mϼ��#%摹�o��^��o;��HZ�a>d�e~�:`|�ׯϏ�?�a�R�ɡ��+ڳ0�P}��wT�;ǯ�;4�YM�t�{=�D 0/����J�ּ��x��Y��d �� _3 ���� �� _�0�8��	49���� D#G�	뫐� l�	J,����s�= N�?P!D*Nd�2�5�D��	���q�b���d)Ij&�^�TE\~|a�����E�|r$P~��#=JT�q�u
����m'-����E9�O�>+�%"�5��k���ԇӰ�n6�+r.�tE��E�/ON���Y�B�������e���wu�eO�b��l��g�5�2�a�te�n��0���?4�^�2��%��3�ÚJE9�r�FL�rD"��#��VK���v���j�G��{�q��B��hF+���e_5G�;7���5;FF����"�4���%BWM���7��p�8�����T���Z�f/��	.0����}�?5r_/-��bܾ�8�����!RA�p�d�4q�����! ��$�_���Wwů�0�^�>��U�&i�L�L��>%��)|���X���r�p4���Q8�6�<0T����&q�?o>�A�l6���bITj���Ӱ�>��ov)`��k����쏡�c�_Y�z�n�͂y�m��V���_,w`�m9��0���iu��=�6&�Mc�Xe�%����V(����D�|��QA��fKKW�	gr�,p|.���'�!d��?�Gh�ȱ���Ir����6���Ӻ�[B�Z�\òm���y���3Q�����ˏw^<+�SѐV�dw��aLY.���ݻ�L�9 "@L�e�ꫵ�OkBk��b�s��e]D߷�`�;ǝ��Lf�o�Iv���O��K�%X%�����}�ikB�Vb�=�z��v�[��h=Xi�]o߯;A��]ɬx9��T���lw>ˣEX-o0�)�����"�e��7�+����ђ��D��4⤰C��m�9=�&�o�\��#�?5#�@m�\	3��4������|#M�}Sh�y� ����N'T�!
(N�*��GVE;8�T?�?8OgY?�BD�T@7E��]<q׉<��W��������8�4����`��"�~0��t��I�S��w'j�������L�xxx������J3�t�|�*+l�
ȹ0T��	ۼ�L6�(��ɹS2�[�Vgտ@ʕ��?�6��z���0��c�1�T���u�&@M��7�|}8_*��G����&�{՛+�b���z���r����� �Ӟ[���~���BJ\�m��kW�t�U���� �jNT�}�(�V[�-��X��X.o<�������Fh��l�O�U����s�I8(PZ.t�D#>q))i��st.;��}�����r��0�՜���<iF��P1CF��\��[��1���Q�N]-���,��O?m�������?߯� f������'��l��`�@���{�n q�������Z��}�̶h÷��眿�9E�9�В�ζ��M�Ѱ�.��� ����^�"b=�ٿn3��h ��4�i�}p���e�VMs.܅�v8T<6<T�x�XX'��(���of��-�t�%�[��N5#U{��[������ިx���Oe���I`>��HQ��x�����J���SHB�4Չ�NMr:����7=*�b#V$5�lrI��4|o.g�'��5�N�Ѓ����V^��F�]�O�i�����j3�H�]��ϭ�T�p?����<~*�H�/�ͱ ���d8i�
Ɣ��y4��Rsrk�n�^&��y �ө�G9�,�2-g
r.�N�>�fM��;�b��?���C�6�}k�6��/�6}���U>_�d���s"�9���5��k�ϧ��������	����|�<�)/�l������G7 P�����!���H,�E�$�S:Ay�Y���/ۯl[�r�}MM��n~�Ԥ����Q��ɪQ���y�:f���)�G�;�[Gݽ��qg�B��}������k�µg��=k*L��h��̰��^t�����F�I�a��$�5;�7}?ɧ�#}�A�����ʂ���ğ�9HD�� }�A����5�k����9H_s��� }�A����5鷙�4�|�o�7���/��4�+vT�輫+r	T��k�/Q��S���P�H��_�L�0.�u���h��a�oׅ�kh�ֿf�|�������7S��θI���{�[�[�!.ҍ$�q��0E�p�>U����F5�"~ǈ�a�α�(U��;I1���?���i������`w������6�n
&�OŹ���q�'�)�����7h|�1���X��B���&m���D����v|��� ۞eg�"��dJ����B�u���+�l�Kg���-Y��I[%��5i^2�uS2��M2�m�/�r1�v�H.���"9�o�����K�HK�R��T}i*� ���2m+���n�}T�;�Y�3��x[I4p(��-��D�?iG�`옗��8����C�ͻ~�Zؔ��92ު�CQo%�2Zz��#p���ɨW>�cq�9n�K�U9!��c)��4���zqOv�m��0>� K��_x�N4Q���y�����&�v󑸇����L!��_�YL�����R���7�^2}#���y�2U�Y�ջ_4�%��̱��T������Y�ŉV U8�}~���<+g�$�J���n�a5_HzQI�n�H��IT�N��5��n�8%��ɉS7O���E�X��M��U���l�b�{?�f�,	���1h1B6��k�X���l��V}���}�#W��Q_Za����gc�̪�U���-s��Sw
�t(��F��˃.$b:���c�m�Id���}"�گ�����I�Z�/�����oמ<������?z��ɺZ[�������_��5�O\������c��J��~m�)���f��� u�]�7ac���S�R��B�Q�3��[wa:(�j���J�b[���W��Wb�B["�Ph�[����о�{u�;x}���i���Z������ TQ�N�i��fӈ� 2�븑⪱O388��?'����������)l����_k�?�4~������?<�>X}���\����q����W����*����;�R�x��Z����}��Km�s�����=��z��#~��ˊ����йE���dӉ$M�Rh�P;����U���O=ݺ�q�۔P������ݗ�׻x�0Gq�fMhH���*Ҹ���ZI�N#�v�V��W�9>z�io�d� T<��A���o��Vg�m5J���������B9������P��}��mu��;��w{�v�'�c�8<:�~�u��b���Y�@e�9�I���rH@k����������KƳ��i灜��>����jl"�f�������u��?T���������ߚ��#t�m6���c��`���O��8�?u�5�zM���oۏT��B�(n���*�}�j+���$t��_�c�,�ȼQT_g��tz!�;����4+؟ZK�|�8=��bh)lNCw�1b�^)-y�څ?��>�K�t�YR(@��w� u$���|�J��-��`��>�hˁ���ާ���|�/�>���]�!�"�C������U���|}�j;�O>�S�^;��󦣻4߲�_С�(�� ����(
��	h<�pp*���y�_`��0�3X>��3�ڔR�O�d�ѯ���q��+�ޥ*��G
0���gOg�ki�7�{���M{ T&�g+�ș��0�ȴC�X����'�p��j׿H3��{p�~�A.`�HΑ-�7�"	/;�D%`i��֨�8�˸�R��Y"PPo��芈����-�~�E�Y�������,
J��8�4/������$�D�o�rF�Y�8�4M"e�F�o+��}�«k��fx����(�:���A���F��ԟt�}�"��]�t���{�}��&�ؼ�Y�UJ�J'EH�
C�����5|����-%d�o�0̰���`� Sy'x�i/-����?������'�}��ɜ��@�����b�>٪8`s��?�tWTG�����4���z��5��&ך�۶�4������)�oO[X�F�N�߀e�jW�h�y��Uo�*��b}�V��o���+"�Ɵ7�Fd��n0_4?���}Ƨu����z����6���-��������p��`��P��j�y9#��&�¹-e9�&	�q��m�_�Vo���8�}����@L'DF��B��Q� q�/��Nٛ�\q�x*q�C��D ��d�X�ʲ�۷�G��ԛ��l:Gb� �抿�5w�,}�����4�i:on&E�.f��y�<��\<}A�Ҫy��W� ���SFS���h<�^�ԖN�J�K���*H�n0��jdw��_x1��}	���D��P�g�`9���Ns�P������ٝ�VUe�E]�]o���*��7H����es��\�_�5���w7~n���Z䮛u>�ͮ6'|ʜI��լߏG7�IɭYUNG\��M��E3�O��?�N�<|�N<�˦e�	�"G���MWw'���\	���+��]�z�M�@������ӡ�v���DG�s��7<֕�vI�U7�u���]u[��y����<}��~��*��$OG�R�H0�h�ݖ+h��aQ>.�����?�f�M{�M�L��q'��)�qg�2�u�p��r;pS����R�vs��sZ[���^�1M�d׊��L5��J_�>��Nzu�.~�i	2=O�dy���&_��|�U�kOѶ̕���5MTs�)L�dڽ�Նܻ�����WOI������v>=�2�:��ܞp�X̾�Z�w���/PǪ ��-qI��$���P����8W�4�7�O��G��k"T�����7����/i���^��bC��i�7��:�>S��r�t��	t�s�3Sts�ۺ��P�;&�Z0A�i�}E�T��)D2J]�b#W��1��A4N��V�W#�<�.��E�Q&����F9��^��p6����T�c^<�~Me*����|Nw�5�%]_�����='��I;��"�{��
�7t�;��?����p���O�+��V�v�j*Mʔ�����C��1o �!�,�*�)�]�h�r�瘲_]Y����rV^x����_,\ W���?�[83���Oּ 祅	x�����ZT|��^��/�8��S���^%Q�FSӈoP�ñ�F��������s�7�,j`j�Z���+���[:W�&m��\W�c�\��������dت���sտi6�<"��~�h�ea2 ����۾�u��+l�}���<�(w,b��Q���u_&�A�˱�x�4�� �rB�?������#JTP��u�s�O�d�+bIv_P�=�F*�g@�&:�֭�twC2�h��'A�Z
�`��o>=����������hR��<l�7A\��/�<پ�?/����h�/��ߜ��+���BsOMr�{����Z�y^h��������Yns�y�]1�Ё~^݁��-v��7��k���y3�s���y�g`�y�_a����tUx�d�f����*��j�*|��:\�Tn�.5��U/u�`��栍W6��^s���<��(�O#;vR���"�zT�;G��%FGi���kݣ1�튃�mI�ҰI���}?W�P���Rw@��}e���֟�ӆ�I�����*`��W���}�.��l����-I.���j�Ab�(}�T��1Kt@�� r�"�AX�p�Hb߿����鿦k+�un�Պ�TٖR�(S���<a�b/_o�yȋY~#u����I�����0�R5R*&1c!v�Xt#�䂘F/��EmI�*z`;�;SR��S�W�Tz�W[��V����>��T�UY���΃�za�|\e(u S_i��h߯��A��l�-��KŶ����bM����Y�@�*��S3�=�
J���.��|��tm�,���T�e��шJ�ݵ����v^b)���S�T��Ԟ~�9g@-�{<�$�i|a��A(\g��ڸ�u@*b̕��sf0��kRo��%��b�^A&���9e?��(��W/_�� 0U����l<���fD[�x�&�@�����GJS�^R��(Y�Y��>w�OU�b��������Z��?�7�8
����>p�����K�Z�r���,ś��x��z�Z͢����8�
N� g�N=�{ĺ�7+hdxwrC�q��-Km�͆V�>�����
�i����ۋ4+�l�� +�����ؙmH�V�=�xrCn��,�U^��1�7=��"�h��$�ct��B�p�H����Ŭm��!�`K,�@��4i:M���4�����b�3���1��+ƎFo\������%�Qp?s�-/]a%��n�� a��4U>ª-T�<���� �\���G0�q����=8��U�|k09>�Ky���K\?�_D�F-1��F����Ж�n�&����V���7z��o�ᝓꁅ��O��/x;�7&ٹ����x|��� �R^���X�#=���q��7�w�>����0]��|���@�:>�8˧z�H#.��O��X�m�Q!V�I/��nc��+�˂��
��kU����7�h�U�:E��ѴP�
V]������n��-*��iԠ��Z����f5t��k��o[��,c�P�j�r(K@ء��*���Xn�s��QF��µ_V�}��y8v�k�ZhÔ����G/:��	B���.�
[|z��^HgzX�D��a����h�����^���Z�����6�Uin�Wm	o1#�G�,���e��|-_���̿�H^�d�����}l5�bC���ק�������k@ł'��Zz#P�4z-y��R��;���+K��)�O9G�~�ReG�����̟������C�.K����&�X$�^<᳛e%9�$�7��%�y-7�i�wS�-�;rn&�)U�`�W�Hb�׺��S75�ĕnws��(
9��2�A~ y|�^m�4��c0� �������P��M��M��Gy���=�)���s���g�R����*�1����"��������x,�hc�c���Jrf�?_
9'����;L�{�{̔|���95D�;U�}-����ѯ�W�H�x�`x�>���w�S^��G�W<xF1����y��f�A�`���sx�[�L�2'����f������	�
r���<�1����N������4��b��h�v��WN�QJ<� oւ���K�LAw�h��rPu���-���M�f)֫�_1���@,6�|2D� F�J���Q������^w�ܻ����\�Y�R_�q�<u>(޹ફ>^�3'��OH��F��4���(�ZF�ߵ{�.�$�-Ko�ƒ��䅇�:7g�+��W��В��a?�e�kO�_�u
���Hu��$���ջE�u)�f��j~>(�e'��VG�c��R�> Ǒ���;���q�����y]��L�u�ʟ�eګP��L`vՏ�V��U�$�Y֟�}V�������	��j_�5|�ٹr{ku҆�w�G�g4��S�*�3~���	8�m�ڨ���/钙1�ddl,r姿n�5�`�a�^��d�9}��ư�rT�����g#��̪2�����
�,���*�Dx+�����O(`��++-En���tr7�\�M���^�&�U^�Β�(���{h�,=�l(TI�+C��]ٻꤶH��k��]��m��'�trě�D0���
�,�Q�s����u�F�Oç���)]�꣸���ϺV����<PE��^j�>�],W�I/b5�ҋƇs�E-��[D��7^cF�;���_w�|�^�7*���?�1^%a�I��B��B�ˋ|��ܤ
����������8�-8�QE�up����^�4�.lVl7]����gӍ6@�}���o'���X�X�b���.w=VQ�n<^�|%��/eǟT�"
_�J+L2��a-ŋHohp۱�������`-S��O�`1���G�Ogá�D��y�j�}_՗<�8r��\W�%-��㧴!M2Թ�h�I����[��,�����EsHZ�������6_�~kp%����Y7��.X�������������M<n��s���{�;wٞ�xs��ţ�|�Y��yxM��5GTct����Z.�+^�W��s��%`6��7~�� ����Y|�'ߗ��>~���Z�??��z�����������lu�{�/��ǓG�����ڣ������ɣ����U��~������=����/ =��HP�>o$�aCm�I�e�Dj6;@>�\e���T�n��z�E����%�#���|{�����N���a+����ս��+t��9�L=��S�6����;�v#>�,h{
�P��``�#�yT�ϐ�7���E��MJ8��x3����0��1�,��Z5JX���)���:�z+C�v�F<�(���z1p*����ɀ24AFz��t'�V.���=��w'X����e��Dy|���x!�/�+�'�E+P�<א8��$5�R/��^�w�N�t��d%ާ�Y���=*��z�LI-���X��,���4�5A��JW.8���2Mx� ���"�ԛq�l�`Nf�S����?ű���M�_
�
�+�\>��H�%Lĥ?���t�0���t��Q	C(�Z2�����	?`B�e�a�;��O��ex9/eKc8�9^�>&Y��o������5�[zʕ�����ꠐs� �ƧVe��3F�0FA@��8?�7L|aF����tQ*@H����ҋ�e�i�S�Ul㠱�^�݆��yt$AcF@������fi��&���|>S|u��b�oD�rڍ$�5�d��#f���+�#���q�a�N~��I��չѭZD`�S�xl����lR^!V���xOc� UJ�/"��!��f��]D�#Bs��y���Ǔ�]4�|�?�'��s���J%Z:�j�d�X UIT�I@� &Ӝg���ʸ�b����c�<��n8�ǫe��t ]̠�s@�lA�[��i�W!�k4�u���5h B����V�g)N/S��|�o��u���gS�5�{qq��E�^ݨÚ�`�B�$�?8�/4ލ�3 �us���v��6QGA����gu�ML������i��@'3�X��{�w"��=�̐�\*Ш=���O���S���4�=��e���,������F��;
�
��A�w��}1`�[lGғ©�̀|TI��r�r	�;��~0�Ѻ��JI��_A��Z�Tاb��PJ����fIP�F�p��pY8��Ω	�}� >�!��tyJTy:,6�L�0�
 ar'N��0*�0F
��L��p�DefZ��+@e��
 2��Ē�S<i�?��?G��ƋI��h���`���Bb�)�z�"�`���W$�k�%���)ڢ|�z1������`�#J�OρD�����H�5�㥇ڢ�43�Da�Ii����F�,��\2M���T��
sL�DF��{"�)	�,+��w� G`����B�U�[1�)v���	���"�5��Ŝ����	dF�ʈd�����q����$������ԟjRBf�=a���~\�ř����,gq��&ͅ�Rb�(t�ѼHc�b�i�DҌ���G+�R��8%(�EЌ����F�4 sE�j^�DR`I �˒# �3M���B!*���u� �5�U�X�� H.|G"�1')�r�r�Cǥ���sy1��|]�{��S��m�:r{�x�`����ZXw(N�Gz�v�������=4�h�΀�VYc���~���0��R�:��Б�[��4�� 
F�i�� ���;3��=Zhw�(�>�zM���h���Kq��+��3i�` [�sloXnZ��(�іԬPS��]!6�4��r�H��Hk̒�M�0��̡� P�	;�B�d� 롨a��sd�Hҭta����0�advB,�qI "`�����c\�s�X	���j2� �X�U$�_5�9�Q�n+Z����S�m�YM�"�e�p�ӧl���"G��f��t�g�P\��	i	��+�S./����;�wI4����ԅq��&p�:b_	�Nq2�ݠB5�pD����� ��,h�y��4�TF��_Q�/�P�١�8�h��Б��#�4Y '�T.QOä���L贳�
�G��T$�����^��G�2��N�]DEt�s�g^�3�Q�N3 �ZC���h����*�̐�r�\W�KE_DƇ�T�u��i�k1�$ɇ\� aڔ?��cz.�lb����z Z��b��L���V풼���ȑ�щH:`�cuW6/��XsT �I�ĮQ�@�X�Q�P�0=����m�-����La�X�UZ,�%]��p'!/�""��b�6h���U%�f�Vx���;�h3�c<�|gp4�އ	V ����$��IH�vzBd��0�;k���+�v&1iE��"a���`b���8��P��<���5Q�]r�b��J�s�<ٷ�X���5�)2���_"��ޞ-�=�X�z����j�Ԏ^4����|� ����1�a,�"���dH�{΀�a�4 �-\�������߁ۛ�r'����}6
��m��0�o��1$��h�D]�0�S,`�v�6QV!/�ݣ�7�P�Y�D���Q��#��!�50��Z!*���t��հ��Wz{�!��� �t��.<c"�����*M�Y�(KH��H P��iNg�����>bX�b�*"��(����~������%|UF�0H����P3�%ք����VEM��\
�����U!l��)fD��`�h��I|2��D�Ǽ4 ��3*8c^_!��Ą�q��^ב#��p�X�}�`���GQ��Q+�ў��)�ǖO��}aj�a�w3���>LB*Y��((��R��nh�� ϐ�i�Jd�NChngd�M���N���h�ǀ��HT>+7�ֿJ/Qkm�j����i���x\iQ�J�4MY��XD$��6*k��D�s�NXU�	\L2����2�/�ǒG�*XZ��10��$��ƥ;QM���|\e7�G��˲KA���bO� ؘ,{鮒p�ez���t{vj��Ty�ڀ>,���L�v�@�S����SE�pJ�c<K�K�.��m� �a^%�c�18^�P������j]������)7�ɠ�E�¼[�H��r�^ww�x,�Q-�=�� F˸��F%e:4
	�����|F^�A� EH��B��۔ч��O�`�a)+-Z�c�B�� plT�&�j���߹�!��d&�%�x#߆�iKY�����yW�qB�2puHRX��长�����Pg �#�͉.�#�X<�ME����������E<�@��������BI���E8b���%=��uB�`���<&�8.�h��z�r<(�ڢ/��k�Ϻf&`}#��B���v�o�Ym�4�ԣ���yj|g�ct{��a4e��|�h�
�˲�Q�f9���(�����e�>�!��K��p�`��9OF�2@�	ȋJ�dҊ�]�ne1�g�!x�Q
�t��#�`#�,76w��Md��"���p$h�N��p4l���Gl���Ć�Ci�A���i�1x���h�md��c��F4���.	�Q!Zد�x�,�$\�2�&��g��Y6օ��H������(�9Z9�ꑸ�DB��m0�N���ț�� K�k� ���h��k�{�R~��%.O�Us���v`��+�q?�6Y)���Yw`�>JL����?O�Qz��tːܘv��{5����S�&|&�Cڣ2B���fA?�8�c��}�9 ���u7��6,�q\�ӟ���
r ��R�!V��FU1�%�[���9�6�Q�V�/�2���ԕ�Y¦�F�)v㭙��)�dB��*ꀼ�LPAl��1!���
�HHl<�iP<��
�1��gBA4SaY�ȴ�@R�o�w�,�Y&ǲ�	RWR"����트$�4���O5c,�S{_SffV��iA�j��=j9������b��ˁdw!\zb��H��%�f:A�5,�x6�&�I>������f,t� ���#��K��Bc�ӀRa����+�|�Hb� �M(�$WZP�xra|6���>�(fQ\Hз֩��4X0 Y��4�~Ĵ���ܞ�0������OT���U���Ek��H���n(�HQ�i���]VwSP��A@8���&p��Q
m���	�!<v�mO�v"�q��s-�%AU���a��ܱH��Kb{�F1k5��#"�}T�����MC���l�=ta��W��!��Â]9F�J�4Q>�T\AB�:R ��XaI#��~R_�m�LX	��R'�d�������"0�jQY�B��l�����
�^h�@�P�spj2�~��i�X��h%�����zR�3D["�CY��p8i�G��$��� �"L�:(�I@�=�Vo��ƀ��3!]CS��>D1�(J�F�ega6a�	����uE٤HU�₄�(z���ܵ�ڪ8^���Zh9Pm��<�NX�\F�y������`/m�RjPח~P�Xii��V���ع����u�<ŵ��Ǽ�=Ʉ�eZ��B�\�2����fal���,��;l�g���|��W^��xḸ0�9E���P���Ԟ���'/��t���``�d��Rm�aqc���'�:�@��]tM_����R�g@B��sGjQ�q1'A-<;C�F�m�Gj��K�掗ڲ|y�M�,���,�'8�%��%<98��$����Ώ���ˊ��R٪�����?=#k��F�I�C��`}�VVЀw��<u�a�/as��R�PRa06��Q`9`���\F�8��p0w�E4��"V�(�0>%�e�@|��e�+�I0 ���j��;��I�0/�j��N�
�7H�O�$�v%�զ��=K+��2��i��9er� �,�hm8 �
�Y���s�D-C�=a)���곴7�Ґ��`��Ufl�u�0�t�OZ��0��8ĚW�2ٰ�F3'н�>Q25�-���R�ɤ�\�#L/��2�w7�`��H䨹��F5>�Dh�o��!%�]��8�h �����DN���D]��i�<c�_F,&�d�*��"�G�;��$�HRQA�'��PW_�t�N":�+�DH^�ժr���0���W�smTbCq��9If���K=hX�K�Q��+�!���gj��#y&��T�ON�\4����6FǙ�H��=3d�',�Si����QgђW�Z��]_��Q��"�Af&t�r�e8��:������I�x)7����,S�\&�#C��Ii^���\T�Ǒ|�c\C�vDh�ʖ!�D�p٭5�+��b��[ �\���Ῥ�����E���:�q��F�pf���C���,��n/�q���d��@`�7�l�h�q��4��&��j����؆a�o�#&��9���\NM4����.8���9M��/���?��G'l/`G`DA%�v�p�7� C=[ �|1�Ðmo�����F�7�k;db �k�] ��3@��I�=b�������������@��=5���M)�B'	��!��PM���l�J5ъ��t
��+J��m!E5�Ζ0��6._Ս���c�L#:O��s�\�W���sl\�ĜGIm *��-:�0�FAb� *	�n9w4��H���y�m�tv:�����z`k����0�H)l�$��Lg۸T:���'��rB�P�i���P^\u0�����r��	#��Fa�;)��YB��g&��й�I�	)������G�[�G#~�/`�o|�(̈́��h`ad���e/�\o��N:H`�d�JӼT|��t�Ý%�d|�I�"y H�@#�&��"	`�+��B��;��
�Q*�[��G̉ô�A�@��Gt4$Lv~]��2�-lMpN�8^(�H�*[7t<�7@�@AXz�sB��]��BA>�PŨ�f��8����M_kP�#ND+�TRS]�T&l*�yqh�6O#R�}�)>%Htg�9ђ�tM���Ƈݱ[ύ�J6-������ G���-�͌��a��rN�D�]�M�!��Mk��j���N�&�tO��\�M�*���M�91G����%�8
*Y�۷o�E%S�i����j����8�\�����M'�[�^');�9KPR2;�Pػr�V'%�%oo�)pτ���Ԁ�N 2�8:ث��%w��5o���0(�Ч��Uz�)]{���z����Y{l�:d�Td�^5����l��EFa�0�:������"��QRrB!��FCH�ݙ�eC�"ro]�L}tG0��8Q"Mn&u�(�3�ct�P�����Y��. 	�Xp�*��g-�A��{V�L���M�eY8�����*����s��R�Zs"�sME3X(�f���"�x��.�zG��m��j��q��5�up`:X��7��/]2o�3�Y���
N�x�$⤟,�lϺ�ZA� ��P<P�k�a���#�p�'��tc�9��VwY^,��g���J9O�F�.�{��o�������{fS}I����@tTo�쮪X]��EN_J�!<�HO�zsb�XU���n ��r9�7Y��p*)JH����N}^����s�DO[�lܮ���K��J�Ԭ`��RO��ݪ[g�X�9�G:!D�!�c���������;r�Rdבֿ���I����2Qt�.ȣ�~.*���0�o*��"e	��l��j�U�Ӣa�
?L�~�Ώm	H"mR�_�}^�&k!�ؤt8�6��r�������������G&ݔԖ�°/��㘟��f�^�5��e*2P�Z�񇙶-���D<��'�K��9�<BV��}����ļ�������gqb�[��2|�q;�F�.�`�b�V���Y�KJ���1��@BS~�NeP�͑�Ɩ3��Ĭ7^�0p0x�:���}�u������mGQ�G���lAd+D�e����8�Q�r#�װ��a��r)� �On�����q��ٙ8L���eV/����9���Vu�ma%�o��Z[d}�� ca�4Gj/�C��ɕ�N8'�U�5��  ��.�b�R� &;��\!��mB<� �!]��i>0��$����$��@��L�5�k�� (vI���c�g�'Q��0h5/�-deQ�����%���9ڀ���P6)U�3�@� $ɂP��1ʜ���D�������EJ�S�ͧuj���y|�jԨ�Q{>��w!;����(h�,��@7��\
��g��d������Q���~	>�:���N�Y�F%g�'(�S
�r�OZ<Q-PIȺ8�mʭ�e���g��0w���� E]��LW��4h�l��'l�p�>(�d��ZP����n2��i�I�0@*�����u�FX�7����H��ª���YVS�@�U�ҩΉw���P8�)�XL�����~��{dk�M���0��~*yH�w��8I8L�H��:�� ��FD�V��B١,�a2���2��#���d���]D?���#ֆ\F�ac�x ���y���4�%���A5�Ƒ+Ð]kr��55 �f8���|��{�ۦ��^ҍ1pљSiJ��I��\��si���,'�ś�x�z~��	��s1F�Ӳ|Z�z\P�M:����h���}�o 0��Q�yPlܳ�-�1ߐc�z�T⊙C��_�ȁ��ef)t���&��)���+�1�"���{ �Sw�h8io�?A~"�45B�:�@��J����Q��5�S�����i�By�m�t	;�:G�v��(9�p=P ����E$���N��r(���R9$k>�����Ƥ3�8�gX2,�DD�`�6�f��n/�[�r��R��Ï�8ǜ�0#��f͑�8g_W��l��M�+ɡ1�����C^�R�iCH��eנt�ܐ�����ќO��0��^Fc�b@4�B/Qq*Cy��Z�^��j:�;nY�4�DCqFZ`���
z�>��"H���?R�tDb�M{�̘�os}!DY����$��V<T�������2>'�S5���[��E0���},��Q��2�6�ƂG�8��s�z_D���@jc���JTyv��N�)�ܹ"v��%i���������\������W��"〲(�CNN�"�HXA��zd���)�i$.�G3�d)�*�:��)t�3&g����?-&��?���C�Jb���Hy*T�\{�$���>)���)�}� 핆�0p��'��f�U8OY��q��Kq�j+]�3�;��hV�J�i��c��i����J���)�34����L+�#�KcK���`�d��f6��ʱ�#�<��&�z�E��$Y%��-u��Z�s	[Ӭ�o
"#�)cѥ��
5�����t^��C[���ؘ�r�f��Mh!t��N�;jS~��x-m1w��K���{ �N5ǟ� nؠ��7�"��� #eQ_?mhN����-��8	� �%(�2=,"�9GZ�b�Eih��P{�y�s�D�'* V��ٯJ��Ot�^iB��KC62�l�7X�ͫRg����t�x��d�S��
��P��]Nﴣv������ V=�F��e�N�k�x*�C�}$���(\\҂�p/�s�;�r>��W�X �p�2�y���,�����LD�X�fWd}���d"�\i�H M#�N��=���M��08 ����T*rOD�-9NWMٹDC.��R�X���]DIȉ�tY�L���­=Y粶5��)��� 7�ta
dJ�u�U�3�Ҽ4j����*ʩ �b5e�XOJC�,��������D�a��L�t*�q�:/z�4%I���0�1N'��ä)� [R8IlM��8T�8ꄾ��9s�9���#K�6P��g�xDX+�u
H�%:� HƶZ@S�ݱ�e�M�"7�H�0S[��F��d4"�
��ZD]��Xfēb��(�A� 
���
�����,�d,i���r+�M�>FauC=bL�6�!�RhZ��� P&�N�.(�2:���"�Ar���g!d���L"�L*2בT|L6�i�S�U�Iw�ҙֵ��h��L���?��C$���Q.�kU#���B:�׌M3��84p��ڟ�)���K��~�L،�b���\6{��?2���ڔ6��S\誆�G��XJ�]��N�R ����Ή����������s[���[`��*:��$#��$?u���"s�K	�VF�d��8��J��k:E	R�Hm�#���<@rBlp^�)�)����J!�i�}U�^q`���B�>��"l�����!���ʔD��J�C^���O��Su�2U�3�<�f�h%xg���b*�;0�%.�����<�	�G�LU]�#j�`�C�i�&�w�� �#���`�5A-YLb��&��ў���G�f�[xg��/:�uiY��g25��\63>>Q��PR�1 #L56-;��`�4^]q	L�fDd]v#'����t�Ja�����k�`�b~�n��c-�����b u�Ԫ���݌*ð;Ñ�`�J��0�a�MX����v����B"��~�mh��-+~����,>O���N-���l4�=1�W���t��)��
��}M�K�.�d�x�?)��4Mĥ%�����:��
e]�豄���H2)�F�q�,�f����)Y*r]�Ͳ�5?�\t᭒Q���0��st��Q���jF�[�m�L����d��z�O
4e�DJ�N(��(�'47�n�����k5_I:�h���ak���
8HnLu2��� }����t\���.��7�]#0���ԏ2�s���˨XD��V�E��9����QKE��0�7�{�R�<��4�.B�l�d�@�������iϻ����sp��/8�5����0B[���
I�8�M6�D-�)78J"��Q2�;t�:��\j�21.��g��	kÕQIx@l���q_t�d��M�W`��%TK�&��_�3�
k֪&f]L��VOs�#���������d�sl<s���[T�f�|Dq���Û��M90���N(��+�E��(d�����Rh d2�����f��K���oX�_P� ��WV����G������\�)~ؗ�T���|86z��xI�~C��.٥�▙���L�h�4�ѹ����%���#(�%�Z� �"$��F��iI .#6H/R2�{�2��J?Hp8��Wݣ�����C�訳��zyp�?�ã��:{u|@߻�~��?V�ݣ�����z�c�9<��������xsҿou������ ������q_��W?���O �<����q��`w�{D7T��wzQv��w�=Ǜ��;&U��`�5������f���K �����vCuwP����� `������������mKC� ��jwf͎�&m5t���m����;�;�^x��˝�}�֮�#�z��9
_��-�K@`��vzU0Y�{�1�`u��R�}9s`�p��ǃ��"`޻�ޢ�Bu�v�ew�x�M��-���뽮�w����]��݂�v�~T��ћ�-Z���ag�Wi�����3=iqp�qx��e���A�7���wq%�����X�|,A����N?���p�b(F��?X��P�@�l��m��:�������lQ��� �d��#�U�}���u�����>�d��z�ݭ�~|�����\qk� Q�c�������������g�`Wm�e�T�=��`�s�Q4b��E[u�a��u��^�y�����N��>�Η����v��������"�a������	nѫ7�|����z%ۦ����z[��:�ov�8J?0�Y�A�ud����w���{�$�y<�g2b���Cd~o�|p���я�Q��8y�+K|�P�)�Kq�p�"at���pa��T�^�Ύ����3A1��=ݑ�h�:����S�d?PF�/�3�
��#��@R/7�&�aӝ�Z
?Sti1p�bY׊�%������ԡ%�p�cZ�#��}Ve ��A�{}H����p�rZ<$2�3�śs�����҆xF�)�0���s���0P�����:��!�nM�|����Y����n�/I��U�b��N�2���	�!;tqj8b��X7���-(��	���Zr�F̀�/�f:U����@���${��o��ԌLSCeY�"j��R��]=g83�]�*[�M�����u�7g��sJ'ЧYу��Db o=��DZ�Zݪ��:�s�@�:}�9�{,���o�7�}��&�S��ˁ�=���0��I��/�7�S2-�8
N?Z��M�eͦU� v���st/�$��Y���䪴��jq9�ٞ��Z��A����+N�*J^���/e�^Ě BX��k�ɺj�#\�6��~d�|�RWΩEfג�A@v�|��w���d�ݾ��l�%�V���u�G�9���{�t�6�""L;���W�S�{��ei�U��p��+07�QN\=T��G�������l%��Ȧ��Q�ƕ&E��XvJu�ة[��H��w�����rifZ�΋������&��T�SM� A��n|��߲���ٲ����aäw�	�f�m,	O����݁��e��j��Fr*s����-��o�w3����s�JI1�mK3u���� +Yh���p��_����r�hF�U�	��4}_3q�2d�5�PK�5�s�^aD�ث�-�F�(�SL�@8��5�za$� ����x5��7eݱ������ovv��d	�Vm7޼�4XzH�r����G���H��Õ�&�^j�C��J8t9� �,E?f$�z]I�����N<��L�)��G��l��=��h*fH�3G�k{��K�p)�xu��[���0�l�u���pP���:�q��Ô��!4�[19�A�N'�W���&,sst6�Χ�����?���>�v�������������#��~��1�������h��o��Í'��>~�����=^��Z�B��>3d)0�<���f���y2���O�^o��oQp��=PC"������v~�&�����Zʥ�d
�.I�2�-��1I�I�\� &��	�0���wj'�%:�m�|�RP�����D���E`� uȰ�����Nv��ѐ�q�{�x:ӮS��t�X �cR�qƠ��#s���'�'s�΀�������4�P���n}O�O��N94))T	ݚ·0{˸���[g�[z{u��jP��gXV��!uΧ������Ĕ�R�(0�v7r&|�F�j.�7��$���t6�A���dY�6�d�ͤ�\8Ɋ�,音"�0-�v\� v��}�b@�dz��bN���y)��
���H-��}�^W�"�rs��X�U���9�DA%���+�q2{���������Q����;���0q0�Q�ON#�1�0Ʀ�o�4��/�ЮڽiM��Կ+�`�^�ޖA�q� v��=PP��Ia�l��GǠϐ�MFlt�˒٥S���'�nkkard�,2��K��Y��bQ?�_0�������)�߿���j���ߓ� �~V���z��m�;S��`cm����zs�����͍?n>��B����&�"̆��WW�O��Z�Rxc����j�1�����L�8�{�uW��:�����y~�3��T}w �v�{���>�Y-����ؼ��3��2�����^�9�_�����}믯�����y^i���Y���5F��,�/w1��+�w����e�
k�Bs��mMiZjY�0;��-V�t��c	�P8o�	з�q�\R�s���\40g"��h�woE�Zo-�b�]���rTwa�.�e'}�O�~�ڪO�P�@����B�{06���!ՃΗ-D����#5u&G<%����׫M?�k�z�8�Kz<��f���O�iy�1w�S���ݢ{6+�5?.=�U�i�l��W#]{�w}i�_b�?���g�'7U{:��x�(=C&^�L	�sJ����#V����q�g�k�>x ��k�K�Ks�"C3�6,#�ۃ� �~�V�8Ʊ�2����Ohܴ� �$�!(�����*:�J�����&��l���͏E���h���J	��H�ң����csm����d}m��͵Ƿ�G�[k�5-��I﷐_澼�مtc<���p4��o��uX��2]�6�R����˪��Yq���������s@���.z�{�u�up���69qۀ�K��Ȳw/���=�M8}�������G�`����f|:<:�~�u<w�u���B��h+T{8�\�hm��[[k7�r��] �K�M�0^�g�_@'l�2x���ck�d���BH�����㓗��_Ƽ�4t!H�kH�au���-r�[��fL1�0;��mθ�52��Nw�[ˎb�[ej�	/?M����U�x3�t�79}/h�  q��H,��E��ixJY��W+������V-�O��_o�u��}�y�{|�B*<]���
yRF
��ѩF����z�n<��I�m����	�^�v�~I.S�m����1�� �M��wO� �Ѽ����'|-��vG�YX�`��8�� ��x(��� ��iD�kLk�>i��x����Jϲ�U��}��'��	��^kr5L�<�!��r����|ܒڵ��5���I�@ $��<����Z��L��%��1�(b!�/Sa��Ȟ~q�o���~�E.��BR�u���Л�w,�")�*JVC�4h��{;������*��&O�\�)�(AaСZ��6�wV!��e	�=�u���%��H��u���'U[���]�@�����O)m-P�Z4��%��vK�u[)ժj�D#	���穪u�����=4��7�q ���X���r��9��ѳZK9Sh�|�D
��luv闓�v�Q�v �]�}��P�_3w��D0�����t�f~[W�xp�[��k
�T�8ː0� U��l�8�ɀ���4�H���
�����c�R�h�����-�l+�hnQnFF��>�0�Ƽ*�iWy�(>��ʞ��'E�aM�EG�N�>6�ttn{xV�H�Y@���,���%�d��:������׺����iD>� xqe��K�]��i�X��5P��Jcƣ:��Ҹ�T �kE�����ܞ�*�"v�pG��M�q6��˙�T���-�a{ �7K���0��f|ǜ����9�wX���y-N����Վ�6�B�-��g,Bt-n�1Rݹ:��l��^o�H�ڂ�P,��Exqba%��2⁽g�G�$��X|�l)��%\VXڞV|$�����#&-�@�f��>�`CK�]�:Ѹ�EI�a�5��*v-���
s���ތ�+�	��_S�Ϝ�MHԮ���ii�r��м��Th��Ҝ�<� �nw�qC\2�w���L��,�a'��Ȁx��HY��R���TWO�9����^�����qgfr��5�������Џ7�R�\,���-����q�i@�c�D����U��`�ĢEKxjq%� ��>��C<�f���<�+蕥=���j,��c��ms�Ϭ��<��D�Qq;�F�z^�����b`��h�9���βhE�^�9�$�X�Z��aW�Z�ڙ�է@B��x,CE�j��[������La۱7R} C�_�W-?0T���(,�������MM�[j3j88{�Y�	��3�9x	���#�E�)�w��z"�����hf\ ��!��0�.���fksV��J��4�]#n]�N�Z��S3�~-��*g]�A�B&��qbs�U>)��C���t�:ϱ��O�bhH���s��2�+����zc� E7MN�$Ab�'�6<Ӓ+�"��eR�)@G�����z�1�ĺ�J�X�+�q�zBв0��_\��feI�'��+�}-0��/Kg���WƬ����?4�`�7n�<-�ӓL'�)Q��+}��vݝq��g��
5c���e�xkm��"f���#}�-;^!�(>�*6h�h9�p�y�uwi�x�S�d�N�] �;��N��՝b���������x,�J�U5�O�TP��]:>U�T�w�w^�c �,�`��>}x�C�&�s��,*D�- �w�<U:�q#���NX���6�}P�Y_�6Zy�.��yWy�=*�������2t�"��Ƨ4���(1e���(����B���}e�A%.,b�+��ԓ~J#�>����W����Ɨ����>j1X��G˄d��zbm1TPC/������Q�܁_�mo�����~^yF�N���yL���j�mx����>4?V��y%��G�;J����z&��UP��a����`mM��G�Y�d��z��n�������F���:c�D���ݝޱ`7f��v���@�'30�|�y���>y��[%��K��������|�r�u�����5}O���~�����������LB,o44�ó�6��������U��-���%@��o0�Ū������S�D�U�Uw<)��\���f'bk�G#�8N��>6ܺ�7gKU����p����#�(������1�9"���x��0�i>E�U��Q�m��1جz�	��g��M.?�^���%GuVĢFFB�R��Sh��n%2
s,�/�Z���<	Y�	:�(�������w�R<��uK�wC!��GU�*�����Z\"��0�Z"��� *��j�>�{	Ha��f�h�eX�������L�u��0 �\����@�h��݂A��>;�!<���X��� �����&�9+��g�ܱ �rZ^q^b�;�"ċ8�K'Q"�Ct�RЏ&��
�����yRw�\	}sh�6 �~9K�����K������|	��)�.y��DH��D��v��?~�\�O�]��R�1I����u�mYp���/d�Iƒx����vҞvb�Nz�ӟ�PV"��rbOg�e�c�=/�U H�e�"+N7ѝ��­P����d8�b�*,܈���c����R+J|�&o���t<��@����]T�0xC:�ǧY�Ѡp��,F^J��f������37�6d��)��5��������j)�������4��M�{�Z��6��2>7��;�,���)b���3�wdq��@N���0�HΧ��X���^.!
Ov<Bor��`�<�
Ϸ�߽yήv?���	�Sن��U+2���������)��i�S����������M���$�<�+	����C�`T�~�S�)h�qZzKJ	*(P]�:�3����r�wb2�^��"�V���;g�ؙc�tYG��RB�qQ�i��PaT��"��X#@�$�)~��&��z�5��KoD�,A��\��q��I�����j���,�iӀoL��=T�g�h	I�A� \i���ȧ ����'#S�;)QM�9��r�m,�t�{�
we{�I6���J$vBG.�jI�5ҹTAv�-��R';C�ƞ;�#���9�A0\C[a.���N���^1�R"����;u��Y�|�b9�=E78�F��(��B���Z�Q�s��45X���l�V{N~�I��yvE��	ۉ�H�}�գ�����"˽A�Tz�&.q���O:)b�/�
�J�zSi��cB��k�����b�f-���)s��ݾ�	�������6����(��e�T��h�V��YE���!�4�_tr�=��v�K��TT��l{���t�O��X��(�]:!u�k���Il��oF��}��`�[����f��W���<�tM����v�{�?uMM�N����琢M��ٚ��]ڡj�j��f�m�������0��X����"��l���e8�n��a8v�P���V��k;���Z�7T*����T%h;�c�Uӱڮ��=K7���n*���x�T[�GP�*ZG�4잦��nu\ߥ0߳�@�t�훬f��QС��8mC<Oo������@uۮ��Ѷ� �qu����m+�8�C���m ��y��J5UՋ�˖q��XA������gZ����c��骺���4`I Њ��][ul��\�0����:���-G�4_s5Ƕ�Z����9m �*,�c+m�w��t:�U���ky�=���.��l�^'���t��	ak.L��8�aY���Ungj�e:��z��M��b�u���
̐e)��o��,���UtXR%p=��aEM
�l;�a[���mꨊx�>J�ģ�	Xa:>L��Y�( �ږoh�c��8�;�C�/&������NGW�`[U��1;�b Җ@�l�L�4;�M�	����;�=GSڮ�z���6rn�{3�n��3 ������,��QW���m;���f�`Gz�R`�&�mC�W��Ul�a��H�S5<���hz�xžI��Z[S�� �L�v\ FM��P̶���Q��.�N���4vL�Pt��T�yA ��2`Q��lŁw
{,oY��X[C��:���vږ
O5X&��-�5��SS����R�@��h�b�0����
��6l��<(�\�,@�p�yj�N��T���)��R@]q���Lj�DX�f�v
���=@BX�Ul��- !��`��m�BK;� ��$�4�����G"j����:�,�'׷5��=OSˡ*�ĝȞ���f�q�������V�v�S�ǅ�jAN�r��I�?'7~J-��R�4��鸪�+�M=�`P8�<˦7��f@u:A[��X�o���Vw����ھ�Psμ�'�"�"O� ��0v�<�c�@�OG2����ypR�Q5��Y
VSO�Y�pp�w�Q�2[GO1-`<��h`Tp��8@T�j���SS+�����v�I-�@2D�h�j��;��m�kn4|6��k0^�s��pN�m��v��!l�$Υ�U�Dz8:���Xg�h� &�_q��S���Lۇ]kX�%4ź�F@K�ds=�}yC��t�w�HU�'ԁ�ST��Ջ3�����xHt߰lG��,_�������ݱ�R�����_Ԝ�2m�!��C����նt�	�9���j�����)N|�C&R`k��Y�;�[��T�{(��#T���Tږg�@Z��];x�f�4]Q��k�N@�H�c*���Fv���w�����R ��#V�$�sz�f����tJE�|U�M�}�oQ�m���0��2����Λ�NM�aH��88� 0`m��ԇ�1��Wݤ^�0qIf�|<O��[���M�j�t�Lj&�VP�}I	y��n�~Ӝ���2��E�u��a�������1Lp��LZv�]Qq�An0�/a�[׫��U���T$[|����71�!z���mD�=N������۽gP���>z���E�h�u,�F^�I��i��Nz��%��S��2;�j�M�6f�e��&�#��b�� �'OC=C���������j�����6|�F�(i�a4���� �<~a�<�N0�'/�,��������	�lO`J�ٜ^�hfAYnt�pr��ڰ �7��ha�A-}��}zu��Л�_����1ր��:��U/摓q@0�1~acs�����h�l$��
n~n���1IL^Թg>�3R����rK��33�|��p(/bf1m�.z��P������Q�<�x��!.�aM\.�.6��ͣ��;A8a_��"�n���$!����0x,ܙ��z�{{'[ǽ��׻?o���y��$_�*87'�ଓQ�Ä���͜��z�Ư�f�����`���U �������� pO�	__����=����YK�7k�!X����
���0�#BiU$�� �O��#Z-�ۼh�����PI��b��԰���deG'9[�B�y_���z���!���T���+3��!�Bs�]�,<�K�(Vy��X�ͥRѿ�n��+��n���p/m\����f&ￆ�jL��֍��_EZ��%�y2�Cf��N�^
G���5�`�,>%ˎ"G�g���]��$��\��(Q�,z�I��
�"�n�?v���ݖqfV�7i���(v>�|�y�}����8�\���������ޟn���"�pw�	k��W������.|�ئ/������nW�eE63��r��n��ȁW,�]f��R��ҲR��|`hɛ�ݬ˅9�O�ŷ( 'yWRKN�<d'�f��&q���n�d,�����u'��ī�Y��w��M��/B�Z����Ĭ� ��3 �'c\Q1zL/��d-�s~�&^*��t�
���o��F����ew���`Γ��R�'�?g�Q�Ld���`U�2��/5nB��?�����{��#Z@��5�'�>���$:u��ix���H��[>=o����o}4�k��������M���A^n���l?i�Ҽ'����_�l����;�I,�r@�?%�AfR�[����Hc<�b��Τk������|�v�7�Ć���hr76��y'��!�5��8�?�모�*3.�)�H	r'�&�'��IG���	ϭ��|^�6���Z��B���:�V�A��_���;[��
�sK�V���II��g_��
 ���*.�����R���@��e��%V�^�u���B��+��|�dʅ�|I_C7?��钧4�ɏ�w�]v���vU��A&#��}v�O��n��#��~C�ި�9�y�LY'u�=����Բ;��$�^��q7�,<�MB���<��pD�	�<�<(H�Awƽ#�R���$=�-=x��L���ۘbS���<�Kf�|X�iX�5lv׆}j>��y�0�t�i��k{��joo�h��E��3$�166-T^�M�g8��|��ޅa<I�"�U֟h(���>g��h&=()F|�|a�2_��1�0g�Ŝ���^XS�z���9zV�ެ:3<��N������f02Ku	���Z�L�+mY�����v>BΜ�Eҭ��$E��,��M�#\�d��>�k�ھ�5~1����Lku�{�\�{�m,���l�H�?,�?L�P���U����LD2x���e'	�m�bxз���u����!���\?�gc�����=�Z��,f�4���g�Y�w�,���+�������V�������{)���Fޥ*�����|\�`�����L�gn���$�䙇��M��ڐ3�5Ƞ�:��ſ�{;;�皛�د=�7�V.��E��!��������X��_E���%޿h^�0y�9��z�^��7���)�_��[O>��۸����نn���Z�^���"e6������_W4�Z�U����{i��o�V���Hy�8���-�ߴ+���4���ڸ��Zu��&��B��6����j��4��Cu�s��q�H���}�v� ��0�/���8�L<��wX|T���,��q�U�=�Z-?"P�y�m�'�YT�l��}�o<a������D{7Jl�S�>����ʖ�/p���Ԧ��[֛��.��������j��@��U�K�,+_�0�� ׻�9<�?ė��Ě���&L��Ď'�a�� Ӂ+�W���)Y�NN'<�<鵅�+�?Z*�ٷ�6�{����*��E�����4��ڸ��
���?�����t=O�wkc�<���?z�#��h�]��H���q ȵ=Zޥ��ۼ>��s����{,�	���(���W�G�;>*>����rzF��0��E�@��q���J����Y�Ѽw�%�����hYO{K�#&č4�$��JO���#)��x�'�
�ʹ�[���+"h.�X�b��zڨ'Uf���F��[Za6P.VHr�r�V��J�f��2X��/������B�\�۴�_LKn���|Sl��f�P�ڞ)�s����[5��?���@�����E�������S'�'��I,��h/����5g-S��!)Y�����}g|��u�������r��m����K�9N�!���K',���(�/򒈬=:z����[t�u"�(�-���#�u�p~�H�'�w��(���R��1��gc)�`��9�&�r)�͏V#�_�-��X��ٺ����t�B�϶+������˱|s��!s}?O#�ƗÁ���h�1!���t.��Ddo{�%�N���Y��<*j�9� �o�Q�����;��|tF#�5�L��3�b���_� )�D'>@�"Wz�>.y����dv�c�y��i�)��ds4�=<"7<�B��x�����]������{5�I�����	<a)���'�� 4*���b8��ݑO?�}�>vtN���	��a��&�Jj-m����F�d����C���o"��+m>�������@+7 �h�?����
��e�q8.��Q���'l����B�p�wF·�3LښJ��w��æ�j_��~�K�|:��Gv'
������]��+��}�=��:��������wNw�~<�s�k�s�*��W���~lF�a��Ư^�~�q�t���Q�mH��~�I�^Rf�(�,+6�<@�m �A����Ȃ#��B@\��0��N�i������	���4��?8��7.z�՚l!���
q���ԭ���9����k���i����w�0G��o�_>��&�҈���R�_���ˏ�~��~�����}�����?�K����"��9=:��a�ӻ�o���Q���_���hg���������E�ś������V���_�?�i�K;T8��fh���J�����i�D�s �tE���K4`/�K�Um 3�_Y���Dy	t�Ea�����e&��y�.�/M��s���}���ˠ[�Ft1��|��!�$�ʋ}8�8H��ϟ2�z�|!���ZW�|ky�3�/�NT��g���ep����`����(�Nc��^Z����å7�X�9��,E�ې�o����O�`w�6�����������������T���}�_�s�)׹
ª����e,^��P����g}�<}s�:��d:�S������A8�cD�QrM�L��q�0����0� A>�,tl��!����PU7@w�#�X���Nv�%قE�8f����#qc�:�N&�cL���L� / O���P��o�*X}d�eح_��0��cʉ�xw1��B�,�;$���-��0&�_�BD�n��Z�N"���Ca�Lǈι��y�{��]��5J�y�[o��X�����w�n�����ň��Ԛj�[�+�╇��n������ (�^� �yՔ��<6�{�f�(�n�oL��)�H�������;����^W�t��}�s�mwXi�͆�wO��n�%�SL���������Nq٢0�1�M�<É�L��MU�߿�0MI�����g�JJ��Ε���V2��u�nF�R�=�[��1-�����,2��pW<���қ/�WO䫴�;������>|�f@��5��9�z�fw�G��z�S6\�Z���1�Fq�8>�w�<M�%O��ߘ���Dk���� ,���v�r�Z��j<W���<W��r쌻�t%�=�t�`�whc��g�����ߪ�?W�*�O�s^����2��ʂ����fs�ϧ�eY��{%��?�"�MߠTo@43t�g����L���}�lsSfY�f2!I����,n��0[m~�r��#1:���ːI���"&�fZLO�K:��l�PI����WҐE�d�T�5|}�б�Qౄ�X�'YLR�=a��Wsa!��9$9o9,���`�]TwS����Ouw�*�	>�K%�Y�l��rY.W��e7}_0��'b���ԙv�\��-T���C��l�%*���Y����*�B��.r]�w��|�,���h�)%�� �J�w挲�9��pL&���R�c82\�a]\�����5��;i /��5�03��D�_լ��%����>_������";BE
��*0�(��7V�#U���;.��:]� �-Y�q���*�������Mw�zZ'�4�N��%;�u��PU���[I������|'<��_� D�A��d��B${r�fʏ���8αҕ>�'�U���}��4&93�$�#8|�x3�8�!5�	�O�.�K}��H��>�.}�����>n_l	$|������{���,�������ǋ��p4�(����	'�@�d#5���S���@��M�������n3mf���䲨쎫���Cb���]����'"\��c�F�z������������^��&I�����p�`�����j'Rd����NКl�bP��O�}��.�R,��G6��wsNj#��Հђ8��]Ԡ���g�T�"d�w��/�=�6w$bT�P�0���G9,9R���<�5���(QI�)a��2Zi-�����~S�����ܴ��/��b�j�Tv��Y���"��`�����8������q_��x�K�	K�o�6	���ur
�KɣOM�:f����z�'AW=��rA��g�Yw<��L7O��D@C�B0�/��+��=��iE�O[)����3*�o���D�+����X��W����$�O]&��ނ��~����������El����\� U��*����z)��AX��A13�?�;Xݨ����������7�����h3�?sր���fb<�]��	}�m�	�B��J�xp��^ZF���tv��r�$=�X����ˢ�D*P��Z���5�
(�T/��PK�fv�"�'@k���+Ak%���H=ƅB���tB�ݣ��Ѯ����>�rD*]!H�@���L�?$�R�d�oX��ҷ����~�l���i:��`X����T��}^��R��G�dN�o��aNT��:t(�7��J�7� *u�Pi�ߡ��yA�<	BE��'}	*��N6{�w���_�`ҏj��&a9����f�~G���a��O��I���w��
����f�g�q�4:u�¡O����/�֭1"�������>%m��?úDu��� �_�� x1�,�knx�.�0P ��5��j�CWܓ�C���������ea��+`�6ܞ���(	6�a�Im���D��K]��?�3w��xĶ�d��cn��RI��m�8��v�-dc� ����Gh�H1�s��̩����բ�r�%[I@��.�V`+�(����Ϛ
X0;�n���w�q�y�5�$�pk�My�y��l��f��\`�1���-7qiS���e����iV�W/����韥�������R��/:\��>�w�J��z��C��Wo��[���7�@죳��b<�"��0����t�(��+z���"-��,�|�� �8�{/����gl�<D_��+2{�.�^Ư������T��7���C�Y�:K��3g��ptZS��MH!	�)sV#s}�I��������t,u�VS�m�i�tm{�����hm��)=���� c��� �W�5U�����ɟ�ԋg5v��$��i��`��ڊ�֟%��h�Կ�r��'�ײ��Bv�p��n��������v#}%u��g ��j�	vh�#;ۺ����Oѯk����P� ��� Yq~�~��aV<��bi���5���tf���)��N�����Ҁ�����%Ā�0��s����I�Z����{O�:es«e�qU-�!s�rUE��7����gQ�lֺ3�$��k���O��?�>n��M�T]��?��ϕ���Ot��s�W��<���K|�w��o_������O�f������ʧDu���<���j���f�?��v��������PA���zu���T���y�o�&����Vp�1�qh���QA����A*!�J!oR	y@!�d�埦%�	�^�������@Le��&tN��Ԡo$��~f"_yڂ�r��/[���~W��	r����o�����q�[�} #8�pc\�hE��(�e��0�������oNt���?ZE܁�\��+R�WMe��]��+I���"�D��l�ϭ�� �����5��AGS�G�6c(�Z?̊f�@A8��Ɣ�5��8�dp&z�;��m4������R`X٬�g���ˬ1�wn�?*1�3��|#3�)�|8S��so���5�������p����~zg�?]g���A2?��001A�zH��@��'���S�|N6ϣ��`p�>.y����M`���9/(H�@��)�L�91"�B���`���ȑ�8�o�����+>R�
 h�~5�;�O^'gS�6n���i�5"�[{k�8�'PZf��6�R������	�O�aV��I����D��lԟ�aۧ���}_W�Z�m(MU�M�j�M��V���gX���� ����&���!��;1 �҉ǩ;©�&Z!�����!�~z
�g��#�ڸ��i��O����,������<�/2���T��5�'��� P
m1= ��Y��4���$����-��m���j�U���H�_�<���N��$p>p2y��G��!��s��ks��a�+��<�kg0$?�����W}����#�r�E;����
���3��S���ẖ��}���n3r�Nc�N`��6����y3D���C�/�#�t���sg8���5�{1������Ƽ͝������o<�0��]˵+��ۖ_@�˝d����@k�|����x��>ZHi��#��)�:��������rhi�^%��"�t�8^�-����7p���?=�Ǔ�[a��O�c}4=��6�����>�M��A��SZ�;~$��#��u�#a5R\�ҥ9@#g���(�Ɛ	�gc����i���{�V~O�&%J�h�1��<���P6 $6@� F�3�Q�ᓸOz?l6�\'a�~�q�{aC��>@!�)�}3��,b��#cx(�=�=��O7l۶�_��M�y<u0,��ܰ
u
-7&�_S8�@��N��f�w���h>J� <�0uk�:b��
�n�Q��,|������ �y�>��x�"}g�X7�vw�.�g� ���߅���`���Qf�X������+?��|#��,x|1�;�w�\Ӽ��ԅ��ش f�cbख़���_����pO�0��L�$?:�.D��8�w�~��p�����<�e�Eo����$�A��x�Uz�)��~|�(��-f���6��h���7��/��U���YE�t>�����޹��L��ڸWj���N�!X���*��v�џH�Z\�Z���;F���A~�I-)����(��w(7�*��`u���1O	zk ���X��/�y��"�Y���(������x6��"��~�h۵�'�s|Q�T^׾�n;O�8b�t�ۯ{;�A�@�����HF��n<�̗t�?��H�<z%���p���p��d�n�W,_� ���=��x�,8�U[���߲m8�M�4��ii�R�̊��������_���2�ɉ�x�cF�s��3��l>W&�ɧ���}57%j�(���n�ϥ���K�1�bd���,8 *���T��(yߔ�'Y�p٬?K迮h������eXx�g�J��k%�[����ނ�!t�ˊN�+�^&$~�E��pH8�'a�$'�>&Z�K 4��C��h�̎�Wd�Z(JPtJ1yy��Gg��'�B�;%߳`�#������Rg�w01��7a����'�e][�׍usݺ�<��:�y���h��L�V2E�Ʀ��܉�
N̢��ڧR�V�2���}F����/��E������aY��W���w%����  ��<Y��d�d(��$qbR`'g��+��b7I�gT�J�i<�$K����S7*�F0�	���q����E�G1Ȇ�c0�`�t����І�;�h�'���|8���تB��<e=}�$��؃Lj��'!p��y(~
���wi��%sHCq��8W��C�Q��y����h���.;iM�Ik8p[b���V��{���5K(]���*b�p�>u�p*�~+�����лX�JΜ��^	<b���7���\�B7�`���ֶ)G|h���8��g�3���Ɵ���&���m1�3I�A��]�i7 Q�5T�E[��+ܱ�wP6d��3۵���c�7���P�u�П?�Z��qIYdiq��G�3N�����Ԡ���L��i<��]@8X��x�(
���ם�$�?	����_\tϦ�x�tr���]D������\���)-����f����Y�Y��$U�?�=b��"�!
���ٳ"���8�E��^�ZQ����$��ű`/�y�G9�[Sf%��Kɔ��Ȅg����h��^�6�D.�)�U���g4M��M��7�aa��L0�A�ZtN�>�1��dDQљ\@�x-��DM5����q 6�|]�V�g���VtJh�	�L��R�d<	��ͣS�G6Τ�>'�,��tι3����8���.�N�0�n{{'[ǽ��׻?o�����:�h È:���?����a�f���#�a;B��~f��z�#���TQZ�x,t9Lq'�2L�� ����7�6g�!�LF��:;��M�z��8J���X����L��/�L+w�)����A2n	��1^��W�����E ��:���~r&T������@3���}��������v,+��	gK��d�D=��d�k3��evE���ѣ�+�!o'�끅
Lk���N(A6� �g�ˈ�+O[" ���R)�_K7���5��S���9��Klc���:��5��-�b��V���$�����_k�4��@�k�[�8��6�_�W;ovw�~��v��w��qr| �z�w�vw���?81����n���?X��Ke��E���T���m)l�J��W�*�?/�?d�+����4pn��t�'bor��Z��P^br��vz/�^"!~�W��>��������4&Go��3�����`�7��t�@ޖ���t�n6����'���a��3��%vV���������ޟn���"�"G�J֒��څ����%��t^ڹ����+
��"eE�����ޗ�4p�M@�b��c<������e����Є0+�Y�=r��Z��dR o���i= ى��f�I�}3�[nKl�yy�	�+��zC�.�w��Mo�����U@)��O��� ��, �[Lr���%�/�g	|.p��ċAes�n�M��7ۚWnTN�?_\v�؏F��@�-�����H��(�㝲ۤ�R������&�do�w��F���MV2�֛Dڡ�*A�����'�z�G��+�_��b�����B�I!i;g_��k]�u�kz0[��+�[h���J᎚-�P*-68-T�׃��B�>�J{W��0+�$7elE�ώ;wڋE�Es���KIP:k�qw�Oc1>P?<�����Œo��O�p�d�T�m�����E��ۜ!����i�fw?������Iי�aZ���~�p �x�fE<�Z4ŁN<y��ѻ`c<]Z&Ö�p�;���N��L�jdN���f�)�uK�'t|3 R��Jt3܎�	�b�|v��9�A�;n:U��t��b�"Ŵ����];c
F�]32K��FU��S���0f(s*�$��}�Π���ٙ3�H��G�O�0_en�ha/�b�dAu�?�p:O,i�?���������^5���p|�Wх����� �r��Xt��3���Q���"F�6�	�y�����A�!Kx���^��k��JwM��_L0Z�5����I�����u���+I��oQ�+��o��w���.
T��K�����׸=#�1�)�~x�@�8�����3���H6*d��c>s��ؽ�3f�����ԙ�[���U�ǌ��#��%xF��������������Q�1O��zi��3���4��R�����!�1�ۨE
����.�����!�=��w�מ凛f��d{������������M���ZP��U�������?P��H9�~����������?���a�y_i����.�Ȃ�_�����
���m�zu��"U�?��?��W�wpr 7t��=��'xm�?ҙ-q����cO���w�Q�������j����-���ǵ����\��y��� ��s������v�v�l�NRs�n�m0��l}�?�M�uNTKk��A��]1�����t ݒ=�̭��UAu�kU�P��I��9y`�E$��ԌN�/ob�Rx�E�?�]���U�������<��7ȓ�����렴��K��~X�Г=���� D��B�q��^$�>�E��X��L*K��Rޜ1x#� ��]��Ǉ�X�۷�Dt���"�^(�#���/�_��f֤߀���3J�U����!z�.;���2����g�Z�[�(��NR�4��.d��F��6�R��T�*U�JU�R��T�*U�JU�R�~���e��� � 