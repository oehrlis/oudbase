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
� -ʰZ ��zY�(:;�b�p6��m����[��}���)��i)ee!ej2%7x��������(�Q�����[fJ2`��g��Vje�[��G��8i�����������7��Q�7n~������U����'��K?�|f0�<���f����e�����:��������@���ۇ�h�l<������o~�Oj�������w��B8�apG5n��N��"�ǹj?����<N�<W;�E4J'�(��V��d�fS��t���t��<ʢ8�fa�Gj�Ou����M�|N�g����������Q6
���� GM�l)�d����t�f�cw�DF�l��4��TNϚ)=���,@�����N?�V�?�S���������͍����"��4�_h�G�l���}
[���,�L�4U��3�T����^�x�*�UMg����N�\�w2�]��5�dt�fy�W�4SQrgiB[K?LgSu�j�]�O4�l�����$�j�Ρ������ȑ� �a�{q/J���5�7����6 ��xG}���Q�`D���
��qE�_F�9�v�f�|��8�bK�_o&�Q~�l�m >�8�;w󩐢wt�_����<^y�|�j� [��x��iv^���;I_���C@�v �g��z�fQ��	^u�����k���f-�9luv�N�_vjj�� jx6�x'c�#�L"� ��a�������@QvP�Lw�x�������y���x� �P+�k�������qg�����ǵ�t<���g�{���{��u����R�'�����N��q��!�aga�V�;�_��WQFH��^V�z�y�^-�o��wv�;��c8q��f!�fot����/�'0�!�b�I�]���h�>|�z�T�`�m�W䅴\����gP�fIq�S�A����x��<<�V���"�݉��(����3.�AUByz����窶{��Pmq��"B��^d����� �lw��Ǝ��{� ����>Bp�f�gpB����:Q�1�:�9�����˜�/�ޮ8Ts^Ϫ^���[��Y4�=�Xs 8Ӷ����[��<މ��G\`?L`6�p�+����<"z3��Ү���]��U���D¶`���#!��v�@�7�U�|���Ϗ��'����(
�v���05j��~�~�F�|u�U�~]��A\���*O�>#��i<&�e<���V{u-xO��=8z	���7[�����> ҆o#lv� 9Wg���5�I��&P� @TC $9X�*	ș#!6���g��_TH���~��g��vdEU��o~l|3n|�?����7�[�tkk�9��5Y�21 x��=�K�x��j��6�ǿ{��R��=��5�y���5�X�lP<���!��>��!�6c4��SS� :6B��7���iGI�����|��y�Qc����X���������p��*g���ԙiy��4��4���ɓ�9��V�z�7_�ۦˆ<�L e U$��@�&@�0E���-�B�]��$�&�xɰi��fx,RU�%��%SNs��мST� ��z:�
��,!!=��g�#�MՅC5#V�d��f(g�"5�.6oڅ�V�����å�])��@-�tJ�##e���ZAW�帽��1����v��p��K{�ר�<�`�ax�#���ll,����F}�0Mg�!k�8/o�?�(��������������vS��V�0����`���,����Iz�__:~�v7�%	�-b��q���6?\?wDr*��,�<K�&�e��F,�^Mx��p�ZVx���/��9	me��=47A�¡�q�Zx�n�hI1�}K6�dac9��1�U*�М:��p��,;ۄ��0�-���hY�CZ��[���J��7��;����}��$O�T�u2����?�t�?���$T9h�p4J=�K	�KAQ�	������Ķ�1G���U �V�U+Nec�c�1M��F�t����B��"��J�����]�h�B�l�߼�ĝ���m�`F�����bz<|��f��&�4G�gCH���Yd�
���*�n�/�1�Y�g�0�Yժ,{
����1PW3v���x�����?�F��;@�׍u����EA�����r����8�Y3I��� @ч���,�6S�SS�\�۽ �b^-`~o�iY��W8���r����M�T5Ƕ�M�`z�~����v���=�I$�ec��ldeP�a����Y8Q5oB�kh��Q�ڎY�/$b��W�`��ToRiB�	㍪�z�슧�<��@V��I��Cn-��Wvf�S�ӱ�&o��E�����Vg+Ci٨m��W��!s�!�k}��-^S�W.#z��<���c�����)qN�lMw��v��'�)����cc5�Փ�T+�\vE:�����R�([a	
GZ6�yW��	m�mPO��Il>�� �c�_��!�K*BF2F���$}o�W���=T��64%MW����b���srB��0�Dǎf>Ցe0n�ӓ���X����!��N��UY
/@bN尟�6�GR�p�9����V�Vi��v^�N�~�}@V��ޑe��l����\���O�QB�.���F�-te/����E�K�F���AG��W�$I@ Ǔ)�}���(��Q�#�G�vvb;0~��QUNN3���p���hg�3��Æs�9�ƚ������+Z��N��/(��ӡ������C�v@//-*(K�X��[]i5Zwݣ"o���|���;jw�}��hO�u�A*��!	̠�M�wSTfVZ��7IK�]/�x����*-����Ro�xĜӣ�7uG��n�]���X�-���9��0���[j&.��cMӿ�^�j����������X@���6=�:Eu��*3��J/��{;�#�O�3��+�t�����Q�گ�rz�΢������|���q�q�M�xz�3���h���!�K`{�7����!:�6���_��~��B�������p{���IK��	������<_8��5��ޓfE�|�Pkf��q�+N+��ÍJ�Ͷ����rE�;�f@�)g�K�q��������.:fs"�K8�t�O��sL�<P߀�q����������+G���w�w\�8�͆�q�܀�V3׹{9��zS[�����3v��f�9X��>�cT��s��,m�	�_���v���w���� M�#<>��<ܬ<(�v86+��G��J����b����H��H������Sn�Zh&�\o��[UQ#ێq]RE�)���N�Y�Hr|�Ys�ep��@�"VN��f�	�W�w4<N'3���ȃ|E��e��c��ߗ�2�U
҃�%��l1V�ϵ�4~������"�-����ݷ&���w�R����_�������������7'�#�_��C���+�
O�א��F!��#���~��B����'�;1��r�~�1��R�}Eh?��g�ܗ���OTc�~pP �<ƞ]5��a������2��`|u���K�3o��H�Id��;ꇧ�;Nh>҃�m�Yt����߫��������AETwr��,��͊�&̃?P?t�U�������`CFV9�^�����������k&�t7 �k�� �5�k�?n�$�_8�n�M���%��o��*$9 �t�K��&��f�U�T��Y��`�A�Q%j��<r\�'�;YJ�	��U��_�r�$a�pQ 0�	������G�*?����@�סչ�Rt��(��I�cźDľ&\|M}X��p���&yE�����! Z��H�������	�:� �P�>��?x�Ԏ��b���iTb_�����̼&Q�6,��,�ǥ#́%����]�03��i�tXS�(�_.�ш�X��C�Z{��j�ݻu�.�az��x�(��P�)�l��Pf����^�Tc�~p�׼f'ȨVVWW��A���m��U�c��k7����j�0�r�ً֨��@���%�_&p_�O���KKrƯ��0v�s�
�j�T�2�Y"M,�����@w���g��[��W��?/F��*P�4N�Q�ZD�����PX�H,KldFj��0
�����1���$.���������P,�Jm����hX��?ފ�:�?��5"��s�����1���j�T���f�����z�Z�k_,k`�m9��(�紺���ЮT˦1����QF�W+����D�|���QA��fKKW�gr�,X|.���'�!d��?�Gh�ȱ���Il��g�6����:'�B�Z�\òm��ݡy���3Q�����ˏ���>.�SѐV�to��aLY.�ݿ޹�L�9 "@L�ʌ�Wk:�ք��M����y2+ʺ��o���O�׭{��jߚ%��b'bϟ�9��&K�JV������= ��ք��D{0&�y�M��*�w���yo��f�uw�	�t�Jf�˹]���]g�`�X�Y-�jy��My�����,3u�~W���i-�ItIL#N
;T	����k�&ȅ�=b�S�1�	��̕�13�KӉJ1�ޏ���1��7�������'_0[1�tU!�J����R�ydU���-����р�t��"/Dd@tST���w�ȣ{���qP��*��/���K�i��6�)!��PZJ�Ǜ�;U�}w�6��n��������Ⱥqy����4O�ͧ��������C���ͫ�T�`#��z"���/%��H���H��Q�'��F=Zo�t�|<&�JW�zͷ	Pӿ�U2_�ŗ���Q�f8�	"��^��ʹ��(~�������Æ\��46��Ǵ� ����{��m[���U<]h����[��Uj_$J�Ֆx/9n=���Ň�pt�w�2}�~'[gÓp� <0}�a
�օ�-шO]JJڱ���lw�'*�g����8�o5g�n+O���p�2T̐Q�"Wo��$a�}v��SW�o"KĹ��O[g�0y����w�J� �|���څ��'�Ѭ=�`�@���{�n q�����7���Z��u�ܶh��5��9�s� s�%2��;�뛂-�a/\��A�����6�E�z�{p�bP�Q�U�a��$��FY27�:��.�Y���p �xlx���8��Nw�+	P��/���5�M�o�
;AԈT�MRn��T�K�Sz��?C?�I-�'�98fT E������&'1t�Q�O!	�f�T!�:��B������3��X�Ԥ�	%���𽹜���C׸;Q(CBH�����.�4��Z}JLs%�X��u?U���D��U|n��J���)�',���SE2Qn����&�HW0�$·QnJu��GKv��2��H��y�Ό��8ʡg1�i9S�siE��96k���b���a5�7��ټ�����ټ���l>����|���ȀK�?�D�c����k�����O��5�����9��roo��y
zS���>A[�_:���n@���f�:���H,�F�$�S:Ay�q���/ۯl[�l�MM��n~�Ԥ����Q��ɪQ�y�:f���)�G��ǝ���I{�B��}�~x����k�ڳv�5���&
Ҁ~0�gfX�O��yyt���tv������������ }�A�}e�|�A���$��_s��� }�A����5�k����9H_s��� }�A������A�n�݊��[��Η�A��)vT��]S������_��#���JG�� �#�ʙ�a\�y*:o�������߮w�Тm|������5S�o����q�L����(�DB\�I��&*o	`�*�}��W��{�jzE��g��c�Q�jw�b�t^�����б���po������6�n&�OŹ�� �q���)�����7h|�1���X��B���&���D����v|��� ۞e��"��dJ�}�V�кcr�R��3}Zʖ�����u���4/ɺ�)�ʆ&ɶ�v���q�H.���"9�o�����K�HK�R��T}i*� ���2m+���>>��,wڳ�g(���񆒨�P`�[�]�V��Ҏ���1/K�qH�=,��u�ͻr�Zؔ��92ު�CQo%�2Zz��#p���ɨW��cq�9n�K�U9!��c)��4���zqOv�m�� >� K��Wx�N4Q���q�����&�r󑸇����L!���YL�����R���7�^2}���yw1U�Y���_4�%��̱��T���`�Y�ŉV U8�}~���<+g�$�J���n�a5_HzZI�>*���>:���H��Y┬�''N�<ij��b*7u^^Ta/۳i�1����$�w7Ǡ�d�\��QHc�NV���Z�	�{,�ُ\��F}i�����{��U#�&W�ޫ��v��S�3@�U4R��]t!����ol��D6��'���J�l_?�����B},�������������������_��5�O\������c��J��~m�)���f��� %c�.�0�1���3�R�kB�M���;wa:(בj�f�n)�Ol�{�{��اЖ�:Z�VA'85�/t_�v_ow~Z����VS����(�	��,OG�i��M����W͔��싽��N�Y��^t��P�?�Y�5�����i�ҕ��s6J;�'�4����J���O��As�n﹭Fi�Os�<�2���V��VѴ7�*M���N:�G{�NW�N��?�GǇ;/�O�YL��?�M����'i2_n �57�@OJ��^И�4�2��>\c��z�D�N-(��=6�S@�o@gX���֛p}�"�ӏb"N������p���oԼbjΛ�K]�kK{�F�-Y�ZX_��v6�F(Ba��'��20��/�Ĵ��#��|�o�Ӊ�1]�]���ή��j[
f����t������(v�>м�NCw�1��y`����k�8�{W/`́f������#+��-�A���C{��R�E�Y ��Ǿ�e9�2����������� ��f�=Ĩ���T͞R�V�c����FU���t}�h;�O>�S��:������4dg��!/-R��cY�����?Y��[�Mé��3�f�ϖ�[�B�N�J�^'''?�#Ef��)�z�QKbR��wQoFCh	�4/������'�*���$��B�ٜ�)0Z);�ێ���T���fN&�/���,Q�D��AB-ND{3R��T�HL�gT=�zgHǦ&e��Z���J�6�-��sԠq�O�J���2��E=��0MA-�Ԍ�HM����W��Sx��\;�U�kU6<,�7v���D�l�}fzk��I0X�c��1Xq�2���<jU��7�j��}���1�-�u�LG�ȱ,a������cɟr����	$ת$r\�
Q�xS�$�.'p!�f8:	�n.>e�Ӝ�/l�
33	�2cɳy�W�t��F�G��ixf��`�ѳ8�2����e8�i7�1��]P�mؠ�Q�rZT��P�VbL]�_C��V�`�5�bC��qi��pг;�b���S��Gt/��.L�%�YZ�a��3@��6�2�{f�����+ſZU�����!��Ɠ�:W��-�����TD/B��vb��X4�wZ	����ʇ�I-t5�[k�U�<��9Q�g˂���>7���1`�"��c�4�k�2#��;%L�T�q�W"��~^1��^WjSx����[��9�W�YQ���ƹy�����xv�8F����[�Fpe�0��;	�2@�b�ÿ;^ح�REmi���8�j���o�x8�~X�sGZm��+��0�Am �bj8`�I�3+�Q5���,��
`��������ZŖ]��n����m�.���)R"Q����_0-�/5��pDD8(S�o�ņ{Rn�dxg��T�]I�z]�g!p����dO��Q�5���ϗ������_-��ϴ{��$�0�ac�w���MF)#������C��GO��xt{t����Qk䠶%ӚfN�V_I�d�����g^O��7�Nɒ[�[��׀"2;5�i 2;�<�w�������*�)V�����bWy��&���?������К����e�!����ɢ�Ơ�v�G�ɱr��i*E���v�������+5o����9J/G�Q,�yM�p�9��s����FG�������Q��;�j��"�-���|\ߋ��#��M�v+�ک���[9Wd*�< ���٤�*].)�4h˃�_�ef�+����Cx�ii�t.���	��Zq����F�Y�kէ�+s�,�sG��a�d<#�5m�9�o����E�V�P���ă5ܧ��!�~:��k.w��Z�
��� ?�S��T&?B綟���1%Q}?�uk%^P��
@Q�u8ؓ,N�u����\}�����~K>����g$�F�u�7����/i���]�4B世I�߄��kT��g̎zk�嗢b�n�WERv.��͹l�+B�n��i��T�tH�}`-�c�<�����N@�ꃊ�!�G|���/���~J��f�n���G�E�5)��Td���s�n�0Oř�Z�Q�嗈a����&w����O���
#��*I��G����w5���y_���n�K��
Ήw�]��$��ӎe)�I�NQG�Z���-���=�]���l�<��-P�]��#���N������8�U�57��2���7��� ���(~|#���������F���w�(����M���9[�:�kiF9�_s&�<.A)�G͛ͥZ'��ǝ���BB�TnH4X����.�1��Ya(�;Y�GmQ��i7�i$�n�,d����q�&	��z�+��]=���Fop�@�Q��ퟢ�s��]tϥ>����4�fo�-y=v�p�ǝ#�M ����%��Q�n)��#ӯD��oN���Y��y�wG�>�z��I+y���\(}�BԴW�HG�C�M��>����:�%�ٸ�����0��~{��9m	s��?�����~:��<Xq�m�p<�j\x�h�,��
m]Kd���i_4�α�:o��%��Y�/�Eg��v*��'��hb,�o�*-��H��U��	�\�&���"~�Q}ލ��Z�kĪ�*���ySx��-��[�m��Z���m���H��řp͊J@��[�'��\��_PLLNMi�
I1�2�1���[����|:d����u���w�oX�gYT�Z¢�F􆉖��0y�px��3�=p1����{~�����UӦ]���ly���1���4�Y���h�HO�ڍ�+l�}��<�G�\f��A�%8Q�]~'��N"��?�3 `N|��O ��{�#����G�����>������d��r~�a4���xA�Dgh��ooH�="8?	Z-І`�s���s�}�����c�n��c@�y#i���%�ٗ�煗Lܭ�y��~~s�B�h���=O���{~�ؼX�y���e/NC?/4w�M�����7t�W���q^�[~ϛ�c�4Q���p����+�Ⱦ�?_�U��E�S�تޫ�rdU�<OESf�������U��yUs*��s��KE����Q�FG�(��0]�+�jb�9ΰg��h���M�śa[���a�|q�7�{>W�P��,��H��P�Sr����igf.�ڹ�D� ����Ux:sߦA�� R�1��D�8�lj�f$fq�ї[X�8�������Z(:���r}r����i@�`K{�[Dd�"/%YRh�R�{����C^���Y�|y�ew�]FY
.���b��S�]���.z	D'jK��*�N�ݶ����S4�B����潵ǫwk�jk�{����)-t.��;c��*CY0k+�7���P��_[r&YK���a���Z<�
��{�T�7������DȞ��X�Ŀ�&�=�e����f�z4�:�����j	��𞏍�#�������/4��F5ε�C�p_�J, �m�A�ڼ�u@*b��hf0��	��dܗ�Z�<k��
� �:;�-)�FQf��\^����{�^��!m��q��z��O��AIzI펣��ǵ���!�?U��Ί�.s����?b��T�ioXW�(LrV�{�1b2��(��B�re��<�kE�x��4�Z͢����8�N"g�N��b]��42��!�8u� �
�~Ec�~����j���Zg���l.q��Z�d��,Gۯ3'ڏV���6���4W��,�E^�}1�7����A�\��gX&@�*�r�{	ͦ�����՝��$MNj�,�.ì/{���8p�p�4�Z���û��ݡ�ٟ��
o�gN��+����G�$��L�P�#�GyL���{�ֆ�8�1h���+�n�1�J8��a"��S ��Y�c�z/U)z�t.��:��֍М�D���=ﺦC)~�=9�I(�7Թ�+%-�w;�voN+��.y�:�u�K�/i���
q��]���a�K^��p�F bzQ�'*.M��ys�L���s�}J�ܢ�K���;��q��S��)�\�@{����g��t����A|f��D:c��"��[Y��_m����Js.�u�������\���>&9�ϩ��xO[��~�+�P���_��?����7�6���p�z��iFm�C��6f�ܹ@e�\a%'%��o9a�[^X���R��E2�7��^��o��p�
V�^�wT���;l���P|E��W-tm+:ͽ ���*$�ՃP���j������m������>Z2i��p,?g�7?�H���r��!���N�D߆KUR9�HJTzסज़�|�6)�����~��VS�i�b�����	|ڻXU��^Ģ��u��i��Q��(��~�%f�5�~�������Q�4?��'x���^dj�ݦ^W�k���$�[}��������*��@�b���c-��ct�RM¥%�L�譹�gq���i�-)��������oo��<��|u�r�N����u-��YD&�����n��b5j��2�n;�;�b��MֲA���h��;-x��t6�*�Tp�j�]�7 �`��wn��%KZn�T�.�%C���OAL8MG��*}f|�g�/ʿќ��V���;|g�G�+�Br@�)��8�k?�o_���WW��@���c��m�wӎ�wў�xs�Ń�|�.��{�	}M�uGX�V�����.�.����08r����5J���~�k}�>����e��_ס�����o��I=��������p��v�;���.y{0g�7�<ܸ_��͇�m|����������y�s��SG/�z(A�R<�|^I���������,��&lv�4�����T�n��C�,�"�M�K����äl�:��^S� u����f�'��\D�i�9�L9��h��b���D�>&��g
 m� ����!���oS��3d`u�9��>c&�F�e�o�K��,
� �a���h�(�t��fgЛ��� �FQ�F<���5�\4��b�T�>�z'}
�A�m�ԝ�[��W����ߝ`�	��痩�x?��s� o�����2��,M扠�<Ԑ8��Q�RO�Ј�w�M��t��d%}ާ�Y���=*��z�x�����X,�<Ǎ�4��8�nt�+��]C�����r�$�k�݉�ތ+��d�<�ԙY�G8�p2Ũ_`}s�V��������w�D\��+aH��Lg�D��7�B�%��a
iJ���
���I����
����'�_���Q@3�D�5��^��$�1uW����X����p&Z@A:��
9'�`i|jU�/F�c�������Z�t�T�4�K��GR]:��bpb���y�8hl���q�al=I�n�8�zs@��{�1An��u	g�v)��_�b@����v#�x'YtA!ވ� �
�'�0�Eg�����t�-��d֭�D`�S�xl����lR�VU��xOc�UJu�> �����V��]D�#Bs��y��Ǔ�]4�|��K7䈫s,^@+B�["����P_F�X.��`2�yFx���+/!V_N*�8��@���[��j�8m@3�|�B�-�|+W9�* d��b�&�Nr=*�@�ڣ�*��@��e�אN�`ucM��ٔx�^\os�W7�`́D0~!a�����F�9�9�xa�uw\��� ��u.]�gu��/L������i�{@'3�XN �{�w"��=�̐�\*Ш=���� ���S���4�=�ݡ4�"Y��j�YH����Ձ$"�yyX1�g�9_�-w�SY�>y�(��+�<Dw$1�`��u���`�K��
#��y��.xǇRF�G6K��4
�_���[p��^�z>�&�0�@|�C�B���tXl�(>�? #0�p���Q��1R�@�/`���'*(3�2�_*ӥB@�s�X�p�G"��fy"�3��x1�H�@z�π��[HL�AO�B�����E�>KpU'S4����2bvg7D��#J�O�@"Ś��X$�����CmRr�� Q���H���(X1�VYd	���F���)�.�ޡ�ţ`r�-�Ĕ�^�� �`��k�#�c�c]v�U�[1�)v���	���"�5��Ŝɯ��2#MeD2�A�	��tK G�����$��a�4������	gO�0�����8Әp���r�	i�\(|?%��B͋4�Pc��G$͸��z�B,՛��-Yq��m�a�È�d�Tͫ�H
,	�~Yr�{��Q���S(D��e��0R����q,FS$�C�W��]�5A�á�p%��\C��1_:��wU�`�!���t��zS�{��k'���xJ��O�}s��J��h�5�9���(~�7/\
]g�:�u��4���@�h�"����0k���G�e|�'��I��Sv)�=z�:!t&MX3��a�s��,��j�B��hKjV���Ȯ\�]9L�z#�֘%�dJ���1� P��	;�B	��N�)Kj�CN�A��$�JV8��
S�f'$��� �X*J�Q�96���9��J��&V�1(�Z�"i���i�H�:v[�b�U��,h��j�Q,�ӕ�>e��=9J~6���;<�Ў�:�	MHK`�H\!���}ꁻz�D������7@]G!jw��#v��'��%�#�ԣv��0 �~��M���6<�&��q�+
����О�<��f�	<:�J�p��x����'�a�7�=��ig�n
�{*3Rh���^��G�2��N�]DEt�s�g^�3�QA �ZC���h����*�̐�r����ٜ���,��� C��`�b��������P�i�����[�g��E����"]��F{���j����E���ND�c���y!��Ě� �ّ�5�h� +7J��g6W��-�%Կ�3�)l�c�J��z�������$�XDd�x@lѦM`s"�����Z¬�
��T6`G�c���������0�{,I00w��$1)$N;=!�lyM����Y����A;H"����F)�H3�5�M%�mT=5ϯ9�hMTe��X�F!L�Ɯn�Γ}���{XYØ"S:<�%"
����B�C��@C��vQT���Ջf_w��#�~�4F9��]��o�Q2���s�yx�4 �-�_�������Ӏۛ�r�""^$:���(4ֶ1.���Yx�Ɛ����mt��X8N�ZJ��㴉�
y� �uI��:�B$j5�B��!g԰ᭁ��
Q	Ԙt����kl}���z���?@�zo�s&���/��@��Ęō��TɊ�5��t����1FC�ZLXED�%���/}@54���ʈCƃ�´����b�¼Ěq�b�
��	���K��wS�^����(��bF�^
V߂����'}L�=��8�Q��z
�%$&̍�${���'Ȅ��
���:�%�}<�2��Zi���N�=�|ڀL�{S�lC��j�Lh<r�0	�d�F��`sJ]ͪ�-�<��+��5Bs;#�l�MMv���@+'�8�HG��Y���Ez�Zk١	q�gN�����J�ZT2�i�B�� '�""�'�QY�n&ڜ#tªN�b�ɾ0d<��}�?�<�f��Z���a�� a�4���jh�C����*��?��^�]j�{��RY6��]%����W�۳3�4�����a�u�`b�����7�.��t8ƳD+���2*жp"^H��w�-��,fy��ZW6�8d�~m��r2�e�-��ޞ-�X�o����[<����g� �e��l����2����6�bl>'/^�B�"��?k!m�mJ��#m�'{0J�0����-�1^�u�8��J9�j���ߩ?�ԀF2�ϒQ<��o�ִ����r
J��+�8!f�:$)�����_ₒeÐ���x��9�%byd������xq~�������gh7� ��}Z(i���G̟s��gW�NHL���dǅM��ZoX�T[�%�pm�Y�̔����l����^OfI�1 ҐOR�F��B��	�ѽSB�є9/���&ΗeA��r6�!QtY!v%"�ʨ}\��'�,����T�s��ve�����E�Y�#�ҭ,f�L8�p J!�.�s�lĜ������i�L�]Sd��V�m�Y4G���oz�6X�@l�8�:d��F�����V��F��=�g�iD};q��@�Պ���fA�&��Y71v?{/�z�����E� ��Ďo�8G�����ʩT��E�%�x�Gh�!v��NF�e���-�8��M�#�������}���n�ئ!����q<H��CV
(r�|dݾa�(1i3lFo�����	�!�1�9F!8�j07�����tH{T�@���,���ѡC8�h��}Pk9$ys]��2�����?��[<SA�U*2�jѨ*&}�$z� �=��F<�#���J�_��8Y�Y¦�F�)v㭙��)�dB��*ꀼ�LPAl�z1!���
�HHl<�iP<��
�1��gBA4SaY�ȴ�@R�o�w�,�Y&��Q�ԕ�H �(|�".�&u>��S����ޕŔ���,mZP���{�ι}�㳶٠�r ��B����绹'�0s	��C@�b��%����t�O@�g�,����5H�!bv��z�3[h�zP�%�Z�Cv�I�}���Ђ�œ��������B���NF������g���"�W�����qN��7'|���Rm�.Z��FrtvC�F�jA��Ȍ첺���D�����|6��d��Ph�lLᡋl�Z�����h/`�k�/	�"mcF�ER�^ۋ6��X�IDAo�*�7W$n���ed[��Hxe�2�,ؕcd�DJ�oQ�Ů#� !�]`���o��'�E�vz��U�|2\N����Z�ﴨ,Z!َd6l�t@�H/4n B��985�ho��i�X��h%�����zR�3D["�CY��p8i�G��$��� �"L�:(�I@�=�Vo��F���3!]]S��>D1�(J�F�e�a�a�	���t�&x2)R@��� aA9���u0w-���N�W⳷F�T.�Ʊ��Q�F��D�u��6s)�_�u9�c��~��V����)NP�:^�ڈ}�c^ŞdB�2-a	|�TE���lA�06R|H���ó���
����+�WN�p�/+D;��=��T_��v����y��w쌬��C��:,n�ѳ���X��0�����t4��!P�4$��<w�s���sDh���z�v�h����R[�/#�	�E3b��������'g�\�PW��~}QzY�A�SB*[������gdm�����#�tȕ����
�η.O= aE��3؜9��7�T�dbX�e��8�:�1L��Bͫ��:+�4�OId+��n��
�t@�nC�9�W9���E@V�}�iQ��ku��Ɠ0��]��D��/~��J�����g:dF9�=@8K6Z��y����s��e��',�Q}������㯮�0cӭӄ9�c��䄹U�!ּ2��Ɇ%6j���8���a������n�4ܕO&��&az�ݖ9��9dD"G�5>֫�'B~s|�k)I����)G���^�&p�p�'�R�OC�k�2b1a�$۰VQa?�ܡ��`$aG��
b%8�g���ڥ�u��lX%B�B�V�te�p���\9εQ��i��$��:�.u�`�a�#,QGE(ڮ솰W�y�9<F��p�3- ~{f�9�L�1:μG���!;=a��J�Ř}ޏ5-y������.{.BdfB��!wN���f[�Q9I/e�&xWЀ�ej�z�<�04H���%ܭ�E%>x���;�5��N���lbz@���Zs��Z!v����X���
9�H1k]�o��7�nj
g�yHP9���]�sW���k]5�$#��0�9�c��u98Zm�d!h�	c�Z��%�aX��[���m�=m2�S�=53�N�(kL����_&�O�0����	��QP	�]�'��"�P�/�ELm�0d��[�c$������*�q@#����tR�f�X<08ac/�>bx8<�;PAspό#��{SJ��	CBc<�a�Ck4�CS�`>��AM��c"��)�Ҭa[H�F�,����`���Wuc��8nӈ�)�>�;��y�[�=���M�yԗ����!ۢ
C�c$���`��sG���K؟7�z�Ogg����y��� [��.x��EJa�$y��:�ƍ����=Q��b�jO]ռ��⪃�ՄdŔ����CF�5�Ga�;)��YB��g&��й�I�	)������G�[�C#>q6B�	{`��f�Qv40�02bd�F�7ˁA'$�r2���i^*.�.�pg	�&Y �@�H�&�Ȩ�f�H�
�P$�.���K�����A�s"�0����7zQu���u�6���e�[ؚ���T'2"p�PT��U�n�x<o�H����>���%��Z��|���Q�͈�q'3$RS]_kP�#ND+�TRS]�T&l*�yqh�6�"R�}b����C	�xN��D*]S�&���aw��s�r�M�j���66ȑ�9st3��dvꮜ�(#�:j�~H�v�Z$���qF����I4���+#��AS��j�y�anou��S
8��J�����zQɔx�zo����w�0&$עm,=d��2?�06��$e�#b�MJc�
{W��*�$]���8�p3ט�	@�Ǉ�k&l���G͛z9B/
 �)s�i�eG
G��#Bh�2�c#��Cg���3�%�WuA���<��e@�Q(�N �~?"���0JJN($T�h`)�;���,�`(�VD�똩���r�#Jģ�ͤV�p�=�n3�Qua/K��$!�S�����a2ȹ~���ÙI�����,�@�������Q�����A1pNtW�]k�@�u��)�܌pb��[��h���Ѵh��kb�j�9��A��<�L�"7�q\�K�M�v�8+�8�Q�I�o�D���E��Y�[3���J|M:l�}b��Ab$P��$7�nb3'Ӹ��!ˋ�0���pb[_)�	�ڈӅ�c����Z㷕t�l�O ��֟h�����U��+���H��A)<���iW�`n@��Bcp���T��n�a}u7ڟN%E	�|Щ���[bu���i����Qz)À�P����\�	"��k��@&�`��NQ���X�"�1�>)?�܇���{+�>lo�5�m�L����|�߁��� 8�c����4�HY"8[fdǄeD���h�k	��D?Y�ǎ$�6��/п�>/J���alR:�Yj�A��xH�t��������&ݔԖ�°/��㘟��f�^�5��e*2P�Z�񇙶-���D<��'�K��9�<BV��}o���yL1��ǃa'���(�ge�6�vN�
]����[��B����;�Cc�၄����J6G6[Τ�J�xm����h����օ�FG��EkF8��Dg"[!�.e��q��~�a,��-xuۜ�K�i}r����4tx�/����)`��L,�z���ι7]���l�(�7k�r8��E��0�M�q���0:�k�\��sr�P%\�lRJ�b.�/�`����؊�&ĳ�<�ҵ���
J��]N"����D�Z�f�~ `�b�D���=�P{�zB!UaI�V�b�BV�����X�-|�7 ��3�MJ����P9 I��@ ��l�2��x1Ѯ����*�b�ҟ��w�i��y�gߨ5�mÞ���]H�μ�6
.���A/�h���B��� 67��N!#��bT(!�_C���N���z{�QA���	�F�o����OT]T�.�a�r�<i�kd<~-�%�Q�6 DQׯ!�;0��MRP��n�壙�[��s��Mc@f��0m0�HE�Pt��ťN�+����T���U\XU�x9?�j*��*Z:5�9�n��
7��P[Xа�o��G�6����	
#��!����~W��S����Ԍd��c�.
��lDd_`x-0B(;��2L5PVF�r��U������'��\`�ڐ��ml� � 4o:�x���v9�f�8re�+cCN�v]�I�Le'(à�>�)����t�E�Et�T��~�fG�3�`�\��1�	�8�Ȗx�z~��	��s1F�Ӳ|�f���8\�tЛ���B5�{�]�@">`8�8�ظg��Z:c�!ǘ���3���R��)���R���MgS>�M�WLc�E9�w_B/��V;Pw�����Dzij*���^�V�.�E/�4�k��&Y�&r ?���3�
�:v�u�p�2(P���*z�@0)�ϋH�ُ�t3�PnS-�rH�|��j^+&�K��3,o""o�C�B�JN7��-�J��H��D���U�c�i��db���w���+Zr�^�&����gj�p�!/r)��.$WòkP:�\nH�}QRnk�'MD��I/��|1 �|���8��<sr�|���]5����_e�.��u#-��Yv��P���]$y��N:"�Ȧ=q^f�w'���,F�tk��UC+*O��Sc�����é�\��-��"�W��>���[Pu�Pc��ce�9n�/�o�k 5�1�YGm%�<;	sg'є�\�\�;[��4��\� �v��Zz���������T��OY�l�!''h@��� `]=��Yq��4�ϣ�K��ysu����3A�w
�
Kʟa��`�!W%�Y�m�<*T�=o�fh|���|d���>O��JC�R�����u��*��,uB�8{ˎ�8�y����c�	<�f��x���Xjp$�?E��wr�`J�M%�>;�J|�������ԙ+Yᨙ��l�r��H��)�I�^nQ8��>IV��FS鲖��\�V�4�����Ȉg�Xt)'�B�/0i�0�W-��V�46f<���Ynk�D� Ä��ڔ�39$^K[�]v�R!}��x��S���:��6hi��MÞ9�;�HY��O�S`�<r:;N7s	��&%<(�L��A�BΑ�XqQ�ZeD Ԟi���!��
�%}��Rz+����W��-�R��LG5[��Vh��E�c�4�1^46�����z�r5�g��;�!,$��)?�U�Q�j����9���~	�� 
����,�K9��N����-��U)�$ܻL|b�!Kgb�7*��Y�j�$�H$W�<@�H�S�~��l��2HE}��*����vK��USv.ѐK��T)��pQr"']�0�?�pkO�qY��s�r�w��X�02��:Ǫϙmi^5�dv�[�T_��
���G,�'��r����TW`�E"�0br�V:�	ƸI��_���tl{���Bʃa�e�-)�$�&�`j�huB_u�؜����Ց�s����sV<"��:
���E	$c[- �)��XaL������K��P�r����KO#Wm2�M���)"�.\h,3�I1�yWwEƠM �RR�	YJ�m�y2���ͅƉ�U����&s����1�s��n)4-N�@ (�s'v�dFqt� 9uut泐�Xl�i&�W&����>&ʹͩ�*Ȥ�a�L�Z�B4�zIu��u�V�!���(嵪���Li!�kƦF`8W]��ՔJ�tR�%t�?�&lFe1�`q.���w����SmJ���..tU��#YL,%ͮjr�g) ��t\�f�Dqdx�T|ɋ��ֹ-�e�-�d`�Bx��^l��:_i�JW�9�R�%��W�#c��i��N@���5��)A�6ݑ�d��9!68	���Z����U���4ھ*E�80_�J�F��_6�fu]�ܐjkxeJ��t�ӡ�uJKrѧH�:i�*��xI3A�����s1��������k�<�	�G�L�U]�#j�`�C�i�&�w�� �#�����5A-YLb��&��ў������3�-�3M�c]Z�1��L*&�͌�O�i'T�d���S�M��:3�WW\S��C���Icvw=�z�R�jc��ŭ��#��C��ߥ����X�o�zl��K�2���C*g7��0��p�G;�5%Ql�Џ{&,_wQ�r����`!��b��64�ݦ?��Mh|��R�@����x6������+U��L�D��CKMݾ&�d�w�?2@�Ì��ME�&�Ғ���uv�]��.h�XBE�q$�L#�8g�3vX~PŔ,���m�f���d.��Vɨ��hdx�9:SǨ��cn5���M��R&�K�F2]t=�'��X"%y+	Kd���y7OH|j���$��e���尵^���$7�:�\�n��W��uL
]��:�V�Z���̮��}��E��9����eT,"pF+�"��]��򠩎#�a��Ƚ{�`�e�w!G�J�L��[�at�����XH��98p��
�{pp~����a��I��&�W��Ջ�%�}�(�:|�	ua.5b����3i��ʨ$< 6�`�/�E2�&�+0����AB�/�]��

kU�.&AX���בj��SJ��Hj��96�9W�­��3B��8�	�P��M`�gdv^'�v�բ�|��c�a��ٟ�����9x�Y�;��Ƽ���T3�&�U�E��g� ����x~}7c���;U�2�!��^�;^����:��F�hC��e&��z.67Z2�ltn���;�CI��
q	��% :��p!ɀ��Q'hZ�ˈҋ��L�6Mh8��k	g��s�Q�]up�^����'?�g����::>|~�ޯ��C��������:��tv��������v��^G�_��I���9:Q�_t�!�����I_�=P��wOv���ã�w��8	^��t�醪�N/�����n���x���qǤj�.��^8|yb> ?�����Ug� u������  ��>��?�l�܁���S�ppx��vaf���`o�VC�� �������~�����j=�=9�.h��<��{�������a��T�� �x��3�����mV`��;ؗ3� �	��~<|�,潷�-
.TG�t�u�Ov_u�������zwO h���S�mo��G����ݦu8��w�q�������ѷM.7�=��� 1��
������q��_�\K��%����C��D�z��gC1b����"Ə�b�j�pg�n� �����Ώ��]Xg����0Oa �4���N{����u0����u�w���`���sŭ�D�a�"'�c�"��F����]�}��R�v���I[ш�ߧl}�9���3���~y�[�0��K8���8_:��;�>d���ڻ{/����=�"HB@g'�Ew����g����6���؊�h��y�K�Q��A�ʚ����#c�wM�[��0�-%��̫�=��G"��{S�#m�~,��R,v��+\YX⛅
O)]�C�	�K6�ΰ���,�
��Rtv,����	��-�莄<@��Y��0�
'���2z|���W�L��z�A6��_����R���K���˺V| /i���@h?/�^�6-�s��������*����C�����X�3ȕ��!�y�S�c�;��,/���3�O���ɢn�@�/O��l��M4��}�E��fU�_Һ��$�b��T�1Њ�:u�H�:&p���y8�����c�$*ζ� "'̞�kɽ1��Ě�T5�$!׃�쭫���S32M�e1��IJJ�t�����v��lQ6������5ޜ���)�H@�eq4@Jh�����D�i)ku{M����@"��{O����U�mx۽e��69�j}P\�7T�Q\(%���_H��|��՘�i��Qp�Ѫ�n�V�l��`�i��{A'�6Β=l'W�E}T�k�A������b�����Xq�UQ�ŝ'x)+xu#��"=\�0XM�U���ⵉl�#����rN-2����c�C�~N���V���y�̚iv����'0�6��aҍ[���0�$�7_=N5��Η�	V�»B�	F���\F9q�P���Ɩ��r����#�rF�W�eca�)�m�b�n�^,\#)�?H�On|Kxȥ�iM�O��{/O:{?���#�S�N5����~y�i�ϳeDˣ�ÆI�x>�&)�X������G���j��Fr*s����-��o�w3����s�JH1�mK3u���� +Yh���p��/wm�c�Ɓ4#[����xq�����I2Śb�%���N�0�A���}�_��QL�@8��5�za$� ����x5��7eݱ������ovv��d	�Vm7޼�4XzH�r����G���H��Õ�&�^j�C��J8t9� �,E?f$�z]I�����N<��L�)��G��l��=��h*fH�3G�k{��K�p)�xu��[���0�l�u����_���:�q��Ô��!4�[1� J���U�rxՀen��'��p:����?⧟�Zǝ��~�9��>��׿}�@��}���]����y��������͇6<\�P�o܇�I���x��J�F�A��`��<e����Q�/w��(8�˞�(�!�Vnu�j��w������D-�RN2���$T��@��$�$J.b�O�������;�Ӓ�6B����Q{d�`�Z��"��:dX�~��a'��;�hH	�8�	���=
N<�i�)�W�^,�1)�8cP�����@�Փ̓9m�OC�y�l��b�f(�Qt��#�g�z�����nM�[��e����3�-���:noש������EH���l0���81�@��2
��ݍ�I ���构�K��/3	Ƽw/��aP�|x�,K]������'Y��%�!�!b��$n�u	R`�У+4K�a�'�/�ԫ/��R/������B����uE,�]�!7���MQ�u^5� ?�%
*�4�]ً��;�j�����/�
Ǹ��޲����Q��|r�)G16�}��1�>�v��N�h�R�����{�{[�Aإ;w@A��&��q ��>C
6m��P�%�K�p7q9N�'��&� ����_Yd0е�:��>�Ţ~x�`����p�AJ��o n�Z�'����ϣ�Uk����+E[��Tcl�o|���hl�?�x���������O��a6LT��*~Z��ܐ���<;T[�����U6fb�a�c�����9_']�O������3��!۽���v���g���7b�����`ۼ�Scl~{q��<
�_����<��;Z2�ư�BG��Z%�k�R�y����|pr�4���7T��A+���y�v4�i�}dqDt��*^4Y�[�ղ�%dBu��&@���esI��&�s�������A�޽��ZsY}�] U]�k����k�^v�Cx-�3��V}B��z��`@�\Or܃��F�M���p�l!ڼ �V��39��(i��Е��^-�a���Ǌs��ǳ��v6ɫ�䟖ws�>�X�)�-�g��[���S^E���V�}5ҵ�q�?�pח��%V��)�^zN|rK���I�Ǎ�sd�A�Δ=�t+�]<R`����{���~6��ٽ{B���Č�4�,24�k�22�ݯ~�r�{jU�c�*�ዛ��	�����D;� �7غ�XE'�^)߁��TU�D��o�@�[ }����<-`��X)a\ )�@b\z�'X���7�7ߞn�o=|�����䑍�zs]K$���G�/s_���B�1�N�E8�E��7^�:,�z�.��T)W�\�e����Ah�~>����9 6ZxL��9�>�><^�}���-����dٻ����]���&�>�_
��S��#o��b{o3�	��>����b�@!�Z���5_nl67������ ~���~���~�.���Y��	[���n4�o��n|��Rw�x����ٿ�1o>]R�dX��.|m����`�S�9��x�1g\��f����eG��25��������np��_�X:ߛ���4F�8^X�n�"`�4<�,E���c���^D��'o��y��y�~�wr�B*<]��
yRF
��ѩF��[�z�n<��I�m����	�^�V�~I.S�-����1�� �E��wO{ �Ѽ����|-��vG�YX�`��8�� ��x(��Q?��iD�kL��>i��x
����Jϳ�U��=��'��)��~sr5L�<�!��r����|ܔڵ��5���I�@ $��<����Z��L�S�%��1�8b!�/Sa��Ȯ~q�o���^�E.��BR�u���Л�w,�")[�T$����i�a�� �{���'�<ys=���4�A�jQ��ᾳ
�/K��a�{k��b#�3�u���Tm�nv])�VS??���@)j�`#�\�[M��m�T����$H&�SU�"3:z:hL�o� �3�ƃw���s"���ǵ�r��Zy��>�;�n��/�m�ģ�5�@V����ӡ.f�f�|��`��)>k�t�f~[W�xp�[��k
�T�8ː0� U��l�8�ɀ���4�H���
�����c�R�h�����{M�gl+�hnQnFF��>�0�{Ƽ*�iW��(>��ʞ��'E�aM�EG�N�>6�tt>��R�d�����Y�ז��e�3�ܹ�74:&#\�v��ӈ|�A����5�i���n�ܱ��k�b˕ƌGu��qS� *6.׊���;/b��=7U*�E�bᎴ��"�*l`uؗsǩ�k�P��@�	n�T��a�����9Są�sd�!���5���Վ�6�B�M��g,Bt-n�1Rݹ:��l��^o�H��ڂ[W,��Exqba%��2⁽c�G=#��D|�l)��%\VXڞf| ����v"&-�@�F��>�`CK�]�:Ѹ�EI�a�5��*v-���
s���ތ�+�	��_S�Ϝ�&MHԮ���ii�r��м��Th��Ҝ�<� ���q]\2�w���L��,�a'��Ȁx��HY��R���TWO�9����^�����qg�gr��5�������Џ7�R�\,����M����q�i@�c�D����U��`�ĢEKxjq%� ��>��C<ng���<�+蕥=��nk,��c��ms�Ϭ��<��D�QqF��Z�����d10��i4��O�gY���B/ڜe�E�\��܊�+w�i����� ��~<��"H5X�-�St��a~`�������!�/˫��Y_�V���S__zI����M��5�=������>UV���w���;k�z"��9x�^if\ �m�!��(�.���fksV��J��4��F��v��u���gf��Zt�UκL�L���殫|R&i������u�cQ-�r�А
C�v�i�Wr�[����A.�n��jI��*O��{�%W�E��ˤ"�S����3$w;�c��u��"��9V85�^1��ea����z��ʒ&O7�W��Z`��_��,���Y;���hM�o4ܖyZz�+�N�S��YW�@���;=�x��ڱj�``;�˺���
�=E̢sFG�ʛv�B�Q|�U��2�r:� ���Ҽ�R����"~� �;w�?����;�6~W�?��A]��Xڕ�)�j~�ԩ�n�;{t*|�R����>#��@�Y����/|����M��6wYT� - �w�<U:�q#���LX���6�}P��؀6��y�.��yWy�<(��g�����2t�"���g4���(1e���(����B���}e�A%.,b�+��ԓ~J#�9�o�T����Ɨ����>h1X��G˄d��zbm1TPC/����x�(0t�W�@��&:����Q�Ʊ[5�hS�~�n�x郶͏�,v^�ƹ���΁�;��^z��Iiye#�E��'��'X[k�QeV*YA�A�^�#�9��dvga
�9mu_�1T"����n����r��N÷�̓_>i?e@G�wN���U�4G�Rp����i�+ﵜq��w|r�oNߑ��m�s���'����'2}9��� ��ŀ�Mm9���Ѳq-qˁ�!o	Pc�[Lv�j夭�.�4�s�f�O��)���'�Y��ؚ��H8������n��ْ@���i#���d��=
��}~��vqL�|���7^t{%�0ͧh��{8���>�U�;�u�`����'�K�����ΊX��H�UJ<�s
m�ѭ�@Fa�e��V�Aq�'!+#A�ex�=;��AS�'���n)�n($���j]e�T��Q�K�r�UKD��o��}�B� ]�ڧt/)"�Ҍ!@�����sP@�o7�)��X}���h�A�]0��gG� ��QKҠ=D�P�1��~6gE���;�\N��+�K�s��A�x�s!�o�$JD�p��\
��d�Vܑ!9Y�:�A�na�+�o�����f	�"7�|)u����%�K��M�t�kW&�@ZN'ZX�a�s�����>�vه���Lc,��36��l��u#a� OU"�k�V�k�j(�;�L$7�ڿ�Pa`p�(9���	ҡ�ԛ�7/���q�����y��ȥ)�{۝��3=e��)y-�=����<�?�G�����Fkmu�i:`?b��'1��#O�.�,ܦY+}��gh��H�e1���XC�Jv|C�6���{/����v_�#��/i���>U8;�
��"U��:@c�+E3Rr%U@���a�b?�|���B�'R���G{I0���p���8�����2A{�i�;�[	T�R��u��[�k{�1I��M6�{���;�Ll[X߬!��4A�M��<�Ҽ��E�1X# ���b.R��������WZD��`n���lҢ2	���|�b0Y�)�e@�;��O�MM"�Fz �A#o>@�G�9#���V�&����`966[-�5��U�զjs�-%;��3K�Y`D:kj7�1�J�:��R���������!� \�\�(ǧ�/�ַ�����\�~z����[o���rL��������q$������X%3Nz,�wJ�Q�8����{-'�K���h+�E�H9��s�fc�틝* $A��|�'M�NV�­P�����D�VQ�y�
��:k1F��s��`��ֳn���m;����	@HO&pl'�"-^�V��.zB��,��[P����EZRN<������+<*��M����	]���wЖzӋ���h���YЗv��&T�o
��ڸ���������5�@�?��W�V�j��{@9�9��\c�=�]��<�#8۞i�2���-�S�<V;���s�NH���+�e��bƛщsm,�����E�_�iW���PǄ�i{��S�Y@U������l��MU�}��g�5k?f��CՎ��}�tۦj��׭����u��Rl�t�vfkf�^@-�qt�tñۆj���j�]۱W�:��R�vf��	�i���k��j�����9Զ4_�T�cvtܕ��ԡ��Q=���j�[�w)��l7P<]m���5K�T�W}����:д]�p<�F��۾��T>1@'QG� �;�߶���8���4����ּN[������%˸N[i[�����A�jǷ;����~@5��%p�T�Vt��ڪc�����2�w]�u���h��k��ؖ"U+Zܵ=UU5�[�1UXh�V���(���t��F��� ٓ���Bo̶�u��MMj��0��x�����yX�&q��Y��|=�ڦbT1ں�imE|���b�Y[E<O	\O�|��M
�l;�a[���mꨊ�Ƙ%[���l����0�&�4�� X�k[��)��jZ�X�񾘴��H�@��tt����3W���d�gz�	[6�IM@��u=ݱ��9��v-ճ��5���sKܛvS,�P�G��4``�t��
,8�m�	6p����+6k��N �~[3�ru��u�	�a��m l�b���K��Z[SLN��35�qW�&�k(f������y�S��15�N��؁J�Vᯎұ4[q|�q
{,oY��X[C��:���B�UXx�����؂�ԣƕpj@H]�:������UR[S]��c�SD�d.j�
d�p�yj�N��T���)���Rǃ�s���Lj�HX�f�v���=X$��\W�a�
�@7UW����m-픃4��0��� ���	��p�*���u`M,��ۚ��ij9T���#����8n�ڦ��T��]���N�c���u����^9L�(���?��ҁ��h�K�t\�mǦ�[�(�q�e�@e3�:���w�v,Ϸ�+訦c��:�s�p5�̫~�/�P!�(�c�=�<6����t �6X���iH-G�<@�,��Gܬd8��;�(V��#lHj8ZǱڪ��i *@��t��)��aj�w�0CԤ�k�p� �qtLKB�8����F�g�J�v 㵁QpΩ�m8�� ��j�mx��Ĺ��IGG����l#m_���+�u��ۚi��k˵����X��h�o��l��o��ݶ�J�1|�T���� 9R}�|f��̲~��n;��7,�Q)l��,��p�A;pjw,���$?��5'�Lh����<j1vUmA' ��p,���j�����)���s�=S�ڷ��i�ߎ�o+U9�
e��_� �h���6��zl���p��0�@WTǸ��P>��
�#�ц� ��v:p��!���#V�$�sz�f����tJE�|L�}�oQ�m���0��2�������vM�aH��88� 0`m����h���& ���I��a`D;�y��e�$�8��[Fu-8{ښ�(���Ln�������B�����9���e��A�-��_5m���;��O.���@�nc����+jr�c�|	�o�zu�������d��O�ԁ�>D� ���Ńh�ǩ���x�z�|����z�^��x�D%Zg� ����pR��dz|�N��%��S��2;�j�M��3Ʋ�}�Ň��1�Z�݁��!���
�k�{��b�xW���A\^>n�p�4��0���T���F���n�O'ϓ�e�R��Y�M��p�'0%�lΈ/�]4��,7:F8��UmX� ��L������>��>���m�M�oK]�Wk@}lEP�����8 ���
�0��9A[�{C��6�v7?����b��$&/��3���)��L�[�%N���_�qM8����6d=@L(�_��KW�~��<���ް&.�sM��a�� �0�/�|Q�}_R��Zf�s<��9�z���G�o��{�v~��F�R�I0��UpnNX�Y'�	{���9�����_�� �9c�)�Dͫ JJ���10����r���37J��zJ]˩���o�8C�lg#A5�a
G�ҪHf37 ��D�G�Z�y+�X��������өaEg]�ʎNr�z�6��1%�+�CN�+�\	=W>f��BF#��3��Yxv�&Q��%�B�K��/��?T���R���^ڸ��WUMO�?S��z�i%ii[�+� �� ���;1{!9&~֘�)���,;�}�Jtw�|V�LFpq�Dղ�!'��*܊��Jf�E�ؙ�v[ręYmޤ�^��������A�-z�Z�dru��W{k��x�}��E~��
����d-)��'=���M��/N/_��yIܞ�1��lf���:-�bS��X��:�,��'�e����В7+�Y�=r����oQ N򞤖�dx�NX�4�M�����r3�Xbs����N_����$+l��˛
���
(%���Y� ��g �NƸ�b��^�?�:Z����L�T6��F����T���	�������`Γ��R�'�?g�Q�Ld���`U�2���5nB��?��rI"�~��5?њ��7O�y>�w���&щM�H�#EuE�����yk4�8F��9�w��O�?���G�.y��������J�@.��~��ժO��&i���y���i�9H]n�N�?#��d0��?>9�cXq%��Xt�ŧ�`��xp06��$�@������;���ѭ1�~������������2 %(�ܞ$����K�8��^�o�������/׽F���`����J�M��XL���
�Tȝ[���=IJJt<�:(T ���P�|I�O斗
��D.+�|)�
u�qk��RH�gKAn���R�+��-!}����f̏��v�������/�d�Q��n4�	�Ӎ�~¸��פ�z��W�puR����M�NL"�E��v��N�7;I�5�����+㙿i0輸�h_=��G�ڤ�l:��! M�J1�6��1�fr�N��C&Vb�d���a�!���A�pNz�4���]tu���q���$X��?Ӛ*/��3�JϹt��	��0��Y�*�O4�qf�c��h=�')F|�|a�2���1�0g�Ŝ�Z�ZXS�z7���yV�ެ:33��N������f02�t	�io-g���,k|z�e;�g��"���͑YVֆȺ%ߓ?/�1�?����A�

������{qw���]I*W�^n�?4�4��_�D�S7���w���-����k`�IBu��m��y|���/q}F�c�׏��X���&�`ϰ��"�-��*���e���1��5�����v�������{)�ט"*����N�s?h�����L0S�2�i�!r7�M�k���^'�fa��T�cea��������N=���t�Z���z��U��n��?��QnX��6�����+���ߖbU�����x��y�����h����xſߨ��S~���מ0|�}�q�?K�+��U��&��ڸ��늦T뿊T��s/m�b�mݪ�)��~ڸ���vE�W�f��C7_C���դ9^���Ƃ�UQ�����Y���$=�颴�x�OCю|���6�G��G~���j���eւ�zq�j��Vˏ�gcC���,���7�=��OX��f�@,2ػQbs ��	�N3+[��a�S�f�ﺤ�\'=R���'$Y�&�.�"�YV��aDY�q�}p�w�/���5�SiM�,>_�O�Þ�A�w��:�����'������J9�_�ٷ�6n~����U��*ҌO�{h��o���1�Ϩ�?�$]�����X����O���:�h��W��W��� �k{��K�G�y|t���%�9� X���Q�ѕ����?>�}|T|�������	�a8�#�ȁ\���Q�ù�ޣy�zK^�e�Ѳ����GL�i8BIι0�,���	7OR���&\O��i÷�WD$�\����,��ԭ'Uf��H�T�-�0(+$�Y��0+_s%X3Ao,�͗�ǊM�`n�\.�mZ�[.�%�v^m�.��s�R(`m͔⹟����q_��E���#
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
y��p�υ�?��&~U�R��T�*U�JU�R��T�*U�JU�R��T�*U�J�`��P)� � 