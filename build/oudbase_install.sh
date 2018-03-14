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
� �)�Z ��zǕ(��駨@tDh@��HI�,g ���6$%���0M�A�tc�R���Ώ����Σ�G�Or֭n���(;����F���U�ֽV��I�w������xcCѿ���յu�W>��pm���xc��X����W�6>���3˧aC��ha;h6,�]�a��'�������)Lo:˛��3��x��=~���mm��h}���ڣߩ��0�������CI�,̇�=�rw�����TKw�$�/�~���ˆz>��$�s�]D�t2�����:�M&i6U�Ϸ����q�GY��,��H�}�PO�k��(�Nϲ��yC_�ӿG�(L�w>��p5����?vf�a�ɏ��h&� f�X-�Q^W9=k���ߧ��f/���~<5o/��tk&�Q���;�ھ��79�.�<N�R�7;�e�4��s�u����TMSu�?�H�	L-�E�g��\e�t��^ڏ�4��hN���9À��a����,��j�f*J.�,MhQaq��l�N�l�@���{ �
�!��t:�7[�sh9;C�c9�8 q�~7�E�����ݕ�������K�� ���|ͣH�� �Mӆ5��I�/���f<N3D!�9���ף��[�I,�����-���8�;w�)Тw��^o���n�?[z�|�\�M�q6��vM�&}��`�ۆ�2M՛p4��O�P�{t�s����\�:�����g����ݚ����qx6�x�c�#�L"�1 ���q�Y�Eg��#�]D��F��X�[G;�'����e$�X�ZZ�'{���;Gݭ�����Z��F_��B�K��-����R-8>�����v��G�j�9UK˶����Z-��2������:S�҃Z�����lou�������4ao6{à{ttp�l5p)��W����%=$�O!w��o �R���<Z���E6��Qx��w$'C�D��h;���Umg�Ł���E�aex���X}��{ghb���Z�V߀F��އ��a�_�Y���ꧪN�ZV;u���('� ��ۜ�/�^��)s^Ϫ^���[��Y4�=�Ks 8�M�H����<ێ��G�/L`6�p��{O�D/��viY�OԎH��v�sbO ����D�p���������T������O=ͭQ&���3e�n���5��@��v�W�����8��\�Un�=&,�Q�xL��x�:a}���y���>!��j��u����m�@�ͮ`3$��,�����k@9����#��*T	�@�<����67�&5��ju�Nv���@G{� XPQ�������+_�O�z�����Wǵ�ӧΫGG�_Mnx������{������w�A��_��gw@�R�uM=S�7�n�ՅEm���0��vL@��j�)(�+��͛޾Z�4�-��̇�`j�]q�Ө��?�xi�����Cgf�Uxx��*g���ԙiy��4�ʼ����o������A�y��?�
T�T�uS5� ������A9�I�U(O�=a�mdǦ�j��\� iKڳˮ�Ns�м�T[������s��YB�x����ZΛ�6׌���^����d�t�X�m�ZF�^�-���Z	�@b��'�5GqF&�I�������Qgk�k������ �7�J�Q?y4%����"�G�=z�i�o����F}�0Mg�![|8/� f��}����W@������=NA�w�8�Ģ������w�0����~�l�uZ�l�$���{����a�[�p��Q���B^�	�,y�����5}z5��k��Nl���?�	�^�礼�yw�܆|��%��@݂В$b��
P6����A���*�]hv�G��\2��G�2!�(L��FG�v��(sX@��z���}^�Z��������PW����5��p�~�u�`c�y�O�e�$������Q�1�?��0_�҈�h�+�X�x�Kb��Q4N/� ��`ne^�jU6�@�}��G�d6�&�`�T:���m��g��a�Y؃�g�.t�K��v��|�ĕ���m�PF�"�Q��q8�����v�x��O��4&y#�`O�������jvheP7ce�W�ج(;JѬjUV�=C}�m,�A\֌:6�'>��_��?��~�gw�^��U���E� �p�AS9P`���QKb�Ь��,F9� @����n�R�Ss�7�;� v)��ܷʵG��Q�	v��>���G\�KUs|.��^�������ۡc��HQ&���ƴ'������b�O�p�j���Wk��Y�u���
|�ܘ���@KM(<a�T5�벸�Σi:��ߟd)n>�ޢ]�Ó0b����8y[/���͟7��j�Ɯc� �����.��UG\����[\W{W.!#�j^z�y۱_rN��u��8�mVWG��ݝ��	EJ���}����'=�5���_d[^��9F��PP�ڲ��ݻJ�mx�Xx��V�}{��� q�b�O�Ӑ�'�`�#KǊa
��7��Is�� lCS���Z/`0V�/�''}�2�������>�k:=��^�����Q����p��ZyK,G]F�(8�"����@d�+�J/���S���C ����mA۵��\~�,�}F��L"~Q���h�h%8|A�.n.z_Z��pD~e��P�<I�`��ɔ�>��I�M�(Ǒ�#Ɲ���>L��sT������l�o}��=�����q�f�9�\���MWFs�{E+8�i��x�;�sa��a�y�%�����y�K���}w���?� A���������8�x6��c���u@
4Xn����������y�Ǥ�ZO�������*-7���Ro�xȒ��6vuO���(� �����������z�~��ġ��7�����S�G��gūE��@=�mz֔�)�o�Mh~�`4�w�;���c���c��Xإ��c�u�������˷����˝��G��j?&+?������=�y� ��޳�S��m`����[�����3X����5|��7����?~�R�a��K�q����g������{���O�n��mg��b��
n�+}۷[��R�	sE�<�f��-ga��Y������*:n�#�K؀�	YN��s\�<�pߡ�a������)9h����l��컲q����8�����s�r�����h�+��'���ZY8X��9�mT��g[�^ڬ=��V-/I�Z�����d]�#�>z�l�Un���k�(�I~����h�X�>�[���f��h�Y�,7[���a�O�R�$�E�)��2K��9���nT�+=�H�f����~f�y��Fȏ������B9�5������dFZ0zб(U��V~	�k�P�b���HZ_/c��"?��xh�£�rc�������$�~����F{�������5>_�������U��%�;�c����I��O���N��,�N��U�����������H
��~_J�>�V���7�
ãۧ�J�����c��(V����s�.Mϼ��#%Ώ�׿������K~���v�%��K~���va��~���z���Kv���`��%H�y�_2H��2H�iw��^�5�)W��6�`����� �޾��~��q") ��lQ�~�곥��7��.������sR8���� --k=O��=�y��F�G�:��\�;��]����}l�߇��ݜ��Q�^am+X�0���K1�w��:�*�"�NG
tO���143/�"�К�T	��D
�&rF��U׍9�<V!��tw�c�� v�����}{\��l
#o�pج�e�����>�}MOH!��X1�9p^��qQNS|G��9�\��y$��,��d;kK�4�y'�VɄ�%��0���Q[�c�4��[?.��?�(��Z?�[��N�cD����M�(�g�����Y-"ky�����-�+�!2�3u�q_��Յ���$�$v'��n���5��1������H�>g�\	Z����b�T��1�������ˆD�(1����,p��^Ȱp�FP? Gew�ճ�6��OjKNP��,�E^�o@':uS4%��`�F����ұW�?�4���,2��L�s���;�?�&�z��`v�< +e��Y<�fy.��]�w<�j��@�����O^��]D����u���M��W9m�����-�dY���x���SwYI�- �bZ~����l�*���V�y��D���'������ ������vg��͇I�o��{^k���CX�Gܯ���Vt�_$��^v��S�`�M�b�5d,`����ͳQ��������`�;��^�0�ޛq����<��aj��D����[?�?�Z%���E��}�槑שZ��/oN�T�#[�p;�v�_������^�+1Bw��[qeԇ������9�o�J�����abʠ�{l�C@�m!�������J�����}�Q�m�ʓ��K?c��G��W�i��L��m��WyY9���q^2�(��Wu�W!��%q�q .�"6۰V�SX}T�2 ��J�%lר�s�אp��W恂$���2��o��*C���x�g=���_\��K�|��!��^��6�{�8駗Iĵ��e����(�4��߬��9��4�\|��8O�B�i9��k������U��RZ\�dY|�5%#��R�ms7N���K�|��?:����ߦ�w�Q[���?~L��k�/�����K��o��k6ܿJ����_�����#���6������,`���^���zB<)�fϙ!����/�����#��g�(��}Eosd4o�h��`���ʊ����j ��b�Ix�gNx��o�T��R��r_����[��L�|���p�b�����Qw���ٵP��y`ߪo��v�rl��x��@���"��σ�%o{�V�����R��K�6��%o�K��������[�mI�����q�ۢB���$\/ �%��K��?U��]���L��n�݌7Ǜ�ϑl=#��c�)�o��]տ���w�Z}R/T�8��ሯ0#���C7@[E�M�/�tiW����=ᣍ���/�_2��d4�Kf4;	���h�{d�K���U�8���_����p�! �#i�F�λ�/l���v6JՆvs�����~��S��8��׵zp��m ��6�^.X����;[y}xz���NO�SxIyo��Є�1�
H�X��B���m�挋D����v|}30���4�e����	�?�/����3ۿ$�;I����a�c�ը�lA�5�i��(����o1bN�v�׎�}W� v"�QUZ��#���J�����h^�b�A��{,�K��n�y�f���O
��J�A|n��#�
o�qò��ÿ���Q�M�f�������:����7����S�	��)Wͭ��]L�������4Q�Z+�q!z�';_g}t9�R�x,���y�Su�&&+�M��<<WaY��[����'��g��+7���*7]z�������K���W9�[��,��l�b�V/�7H�e��cT<B)� ��3/�K�0��~t�Q��)�]n68O
�m�Қ����O$dc��U��ě�f󧱟�S�30����Pwy���17}\թ��-rөޗS�����|��w��g�cq�������t��j{��V���ֿ����/���M�?o���vu�qR�R�	�]_N�c���g��7ac^�ǥ?#4���Τ.������T]E�n��)���<����k�+Fz�^k�|>5��:=>x}���a���Z�����e�S���Y��fSD�*�̈́,^�����@��MF�����׻xe�6 �p����>�ymD�u���b+�Ή�9M��N�@!�����`�muv�Vt�}n�� RX���
CP�*���B�R�y>��Iw�p�s�=��xK�7�}���`��։;�I��g����S�Y!M���Zs��n�(5|��݂��c9꒣e��3����&:cjA ��ځ8��j�J\��Y/���K�N?�4����?��抓�q}��Ss�X�,X�b^[��37�������(���p%PV�w���H�q�iw�4���}i"&$K ��c��y�UO����ҬB;���;�RH)i��܏q��X�(Tjh��$t1�a�g6�KE���];��q�c��104��g�>`�&�죶��W�b|�!n�[���,\&|3�2�����������`��b�=�<����\��R�VZc����FU���t}�h;�O>�S��:��󦣻4`g?�!�9G!̦��#l�(��Q�����T���ho˝hdw��8�^�����zrr�=_��sl����{���CDѻ�7�a��U�I��F/��I~���J���[!�f���=��SU"�s2�y|Y4�e�j�01c4
-5Q��H͏�������qF�3�;C~6��1v�B�o]i��S�;'��B�Y>uh+ŋ?/cMY���NP���������Λ��):����sG�mU��,�7�D�'h "e���+�3��GNu"aiĕ�H&��UMPg��R�����C��}��d�X=�*���c���Ώ�8�XJ�����Z��kUR=�U�ʀM��r2�M�����mY[���T�H0��0���VX�+��V&�l6��Am�jl�͡�BJ����=���Ҷ6i��/.߰�sn�	�\�͊Q�.B�(���)<G���G�VR�\@C�u'(�����P��{\�f���������p�vDe&k���IG-nL�%�YZ�er�3@Ia-d�~xv�'&�J���gMb�6��*O�W^BQ!���gpSTSQU��P/o���s���QJ�Car��Ь�]�N�ykU<O }J2��M9��EP����P�8$E�a+@���p�:�C;%J�\�Ix�$�/�b�r��Ҧ�\����wB�s��"��@wLs����i�c��i���ea��c�O��<�P�X����)Ry�%��vp�������p���n|>!��ڮ)m�k��`6�P�'Q�B/�rlNL���_1���@,�x?���|�@�Ĳ�M����Qؘ�ј�#y���ɟ�pj_�h���H:�i��"�uר")�����ѩ�XK�z�K��j��?X����+��[��-gy;���OV��g:��\c��ѱh�����mF)#������C��O�n<���jRn�\�Vr0�]9e�R��)�c���,썢S��V��6���FM
R�,�?��]Ao92�:�6K���/���./Y,�Ko�Z)���,����[zN��5�=wy}�=Y����v�P"{V�P��uQ���~[izz|�[jޡ����(�p�%�k�������_e�������S:��r��) ����ߤ.�v�ǥ1�:99T�g�t��qeS;�_z'{�Ϋ�x�s6)�MWb�h��>쑰��>��d����Y��bޝ
�� �4�]^+���Z)?+}���|�c��3����t�8�@��6v���U���[��Y�J۹\a���x@k> ������JJ/��� ��a�4��tn��5#�����я�^��b���� M\���>��d:P��Z���W+�5��#�s����X���"E���Ԗ�N����J��ǵ��Db�&B���P��c��}�9�����U������ �7[���p���Դ
�j:}ƨC��'(K����L�h�~Q��l��w�}��_c��Oiv�L1��7�e%�[���/s�^���g�תn�Q�_"!Nc�?��ʧ0�;���'����
�`%�W�Q8���ͻ��ټ/G�o�ޥ�z�
�N����!TRb̎��_�$���cX�HO�3�����d�=[j��h%[`���]�t"�Н�7��q��9����i^��ɧ�_�Ž2��6��2�����r"_g,���:E���ޡOGW�^u^*�+T$t��f��5gR> G#(���y��T���v�3��Q��c!�n�%�`�㟃m�4�q�x�C�\Ѳ���������J��ȃ@n:��E.�$!���h�u�5��G`�~����`�)J��4�0��3��R��	���W�eobAy=�.����I�����g1ޞ�]����f�6���h���{���:�C	j:�T�.�;����q�O����6�O��n��d�.l���9m���?�퓯=�Ϸ?��ժ$A�M<�G\x��v,9�
m]�c�{�i_t���:o}�%����!��٩��J����8�� ��\"YV�xTfdsUb�ė�"�֩h���ḇ��
/�z?�Xx�>�MC��n��\��Rs�v�>����ř`��@��;���s�kf%09��%�Uz`e�Ab�]�w<���F��t����u�������T�gY��R""��8F�ɝ��#�xTTmx�����=pQ�u�(������r���TM�V�+�N�Y乾sPA�
�e IA|���➪uV��p��+_��!|Ě�vL�(��&��{bq��r�o9���G Ĝ�փ �O�G�U�t��OJ��>!��~��H������a4���x��D��r����qY-�
y��h����i��-X�x^���� L�U{D�?_IZ�}��K�%�y�%���|�9i��ޜr�+���Bs/F�4����;���?,��^g������gQ�����7������}x�~�=o*�|GD�'G�yo8�˯�����|AW��N�N�ȯz�bj(�U��L�;M�n�RS~^�H�*����9�������"����(�����TW�R}�`��s��.$.-Z�Ha�
9���C�-9�a��q�7�{9W�Pˮ^Rw@���e/�Ȕ������k��D��*`���W���}�n��2Ȁ�#W&o��Uc5� ������ �X�9 �>��$�� l�B1�g߿�[���UEL�Ry�sK�l`䥣��5U�z���O#^��z��V2�M��=�m�I�R�����4B��	��F���^�ڒ�
*Tgw�c
�S{ʋ�QHjt��|P�|���K��|@���jzXu��΅�|a,���P� ����q�u��{�ks��G�"�rX��@ɖ�x�"f���&U���f�_{�>�r\e!x���j���}9�g�E�Y������{sM��x�A����iz�����3N>΁y�s=�� ���fh|mv:�_k��ULH]��O�F�<^sr����\O��U�^A��q��0����(��Ws�סko8���n@���hH[�x�&��̞-�S�G�Q�^R��(��Y��<w�U�d������O��$�}�6�8
����H���e=��Lm��ʁq��b�LFX�L-gQ��^vX�E�S���s���2���e�K��s�%��(�Ņg�ѡ�gy��w��(���5����N�QK����|���֣̉U+����u�0,�v���a]��C�>=D�0�@���4� B�[��Ч|���fQ���ZP�s�&+Nj�"�.ì/k����8p�p�4��'$ħ)�;��"�8�CI���鶌���nB�- ate��*ae8:�����w�l�}A*B��g�����<r/���[{���H���E9�s�6E�@���X�>�z��j>C�D���=�N���\0�����6ɝ�t�g�W:�������	m�9�7�P��z�K/����2s%6{�Kgox��d����1[���x��#7EX� ;/D�1	s�:.����x��䏞JE�M��:
}�ש(v�*G!�΋��?Hlͼ�ࠑ>����
�--k%���'U���Ex�������΋�}Jr��Ssg�*���W����3����z��QV^� ���ʧ�a�kxהU
�Z ��
(39�}�It���7���.�Q��A�_5�:7D]ՄS\�>,�b��M����C
��V�6��r��еS	~���mGl�P�)�z�2�?��U[DPE���%E�N���ڐ9���go��[���oB���P�2��휘K�1rE�LM�/��\�*�(�s@~�̻?����X��/�x�.������o�E]'��8-=jE��o�b&�;u��ҟ���������S���5nzQ�}*t{0��4�Ga�6���Gc�]��*���n	�/-��=V>�F+U0����)6�97��,N6�9m��#�w]q��l�;���|b�7�� VN�j����%�?���5�a���-RZ�a�@ZX��mG�q�R,W�)�)��iP���(�=�d>��� ���M����T�B��-�wJ�휺A��d�s��9�IS���[�����{VI�������i���n����`p��I(;e�g� �����K�~u����ľ�;�����z5��q���1G�Z<�ʗ,ʗ�c�k�P�:�W��,�E$}<��"�{� �	%n%�;����v��?�����},����������?^S���ƣ�ߩ��=0�����wg����l}�%o�sֿ����~XX��������k|T����k����=����ρ<��H))J>o$g�aC�}��<K"���pL���|8U�[uz�^dQ�����V���=�(Uu����N�|�L��ַ��^D�fF�9^�9����bprE�Sϒ�g��g ��	���Mxs�) �J�����⇙����G��2�7�yӥ�a�cP���	�H�5J�������C�!�QԠ�"*JͿ��
r��
��Wo�O���u�͛�y+�������<����e�ޏ������7x�$���%m��:Ԑ8�t?�Rϯ��,̧�`z��d%}^��Y���=*��z�$I����X��<�++���Qt��RE�,�t ���Y�`���A�h�͸�z�`N�)V����X��d�2���a^X��WчyO��D����+aH����Og�2D��7�Bؒ��0�4%J�C��f��oq8�3������n<�*�jŌs��vL��ժ _=[�j��z�!����xuH�ى�K�S˲�xq2�?@��	 �e����-E��'�k/�GtUDH��i�ҋ�e��S�Ul㐱�^�Ն��xt$A'I@���f�q4�>���`)Qޟ)�:�,*Z7b{9�F1'YtAy�H���
�'�0�Eg����hw���֭��`�S\xl����lR�1��xOc�lU����v����� Ir����p�.!��9f^�����dp� ���v�ꆜ�t�u#��� �Ɏ�t�h�ʽ^@21 L�9�(G��+/V_v*�8^�@���[�1�U���T>r!�B�����x1�_�&�a��A�Č�p���8{oz��=��|3Xn�^q�MIְ�E�x�����V��`�B�$�?8�/4ݍ�s`$us��"v�
�qG!��\UZ��>�:�����!�Kӄ)��Of���?2�@�D�x晡,�"R�Q{ܥ���1��N�ikl��hc�E��\�i�YD���bҁ�h�*�b�Ϡ�s�\��	���>���(��+�<$wd1�`�#��^�K��#��y���ǇR��G6K��4
�_��D[���ޫz>�&�0�@}�M�����t@6�LT��2 �i��9�Ĥ@�9@��(IV��y�ʯ��龟  þI,k8�-��z���~��a�L�ǑU#О���3ǈsx�Iܣ��	r�<��_2]�ճ(�g	bu2E��Z/#wv1!��� I��|:)�3��"����j�Nh����Z����g�ż	ˢKȽ�4��O�>����- �kf�%������3\]C�{K����Ҋ�M���RE;<Np|����6"s:� �	tF�ʈtC���V����vM�������ԛjVB��=Q���~|�ՙ�	'���,gu��&ͅ��SϨt�ּHc�����}$Ҍ���Gb��L�.�
H��[xk��5�sE`j^5ES`M �˲#`�3͍��Ba*t-2��h�k�8ƱKA�\�i\X͈�ht�����˩'��H\����I�h�Xu�����������16^m���8���ډ#cj�����]��죹Z82Ve�nκ7�ne��K.���J��U@�MCX�`4�I3. '�ߚqG`���a��o�$8��b�u�*�y�G�T7�Τ	[��>,y���@�֠UM^��-I�*55�R���`�`+��T�7
i�E2 �����9a�~8�m�_蔂����!5�!��A��,�jV9h���R`юKP{����(����� &d���ɘ�bmW�6H�t,�F��U� �೚�"�e���ӧ,����G��ɸ��sʣ(�OdBV�G�
ᴡ�3\�]$�:2��tay��	���8���S�p5�0����k���;�m��<�y��4�TF��_Q�/� �١�	$�h�����#�4Y �omw�
xB��AQރ	�vVP���/�B2#�����e.��Ȭ��"*�;�S��%�)o���� �_�ZԨ�e+��G:C�
���$���u� 4��������|��a��L�cA8~���h6��\D�= -�E!�it&,_p�vI_�OQ��k��D�0屹+�r�I�%* �KI\����rc�}azfw��ے[B�;#��"�9&XZ��']��p'!/Ģ"��j�vh��d��k�+<R2�@a
&/�qZ�389^����$��\�F��@!IX�	�e+k� v���.c� ���E{4�ȈEƘ��� �h7�D�����2��أ51�]v�j:��43�v�<��x[���-�)
����#����-�=�*W4��1��a�W;i�u���!����1�a��"})��!�i;���tI0���z/�t&���(w�b$Ѷ��F��#��f�9:C^��; ��+c�8�#�ݎ�&�*�E��ktL��Y"S��t�l�٣F|�l�l�VHJ`Ƥ#]*h9������k$$�0�d}���ކ����	[���ĸō��\ɪ�5����ꊪ�#�u-f�������,��[H�D��2�Ђ��@�0mE&�%��X��,�.D�zl�Za5!�r)t�n��t��9�)�jd������`�F#d�I���3j@=�gLp���Br	Is� 8�Z�Q"��q�T�}�`���GQ��1+�Ӟ��.�ۖw0��}aj�Q�W����Nb&� i4

�1Ǡԥ��c!�3�qڹ�������dS�j�Se�'|����P�"��g�X�W�%Z��&�X�9�~�+!�hdNӔ�p�v�%D
Oh����L�9G��M 2�e_2�����oKm��i�Z���~G�0v��@34�D��v����c/h����ő$�T��Q��$�5�^ʊ|{vfPcJ�ik@oB���]#���)�)�tgn8��1�%ڈ%s�Ia���3P��8vǸcp�h�G1���
���wiȨ�ڕ���P�"[aͽ�Z��r�^ww�x,�V-�=�� Fϸ��Z+ g:4	�����|NQ�~�ED��J�Pڔч��O�`�a)-Z�c�B�P?p|t�q4�.IݿS6���&�%�x#߇�yK������yU�qB�2pmH2X��ٕ���r��!5�9(��is�K$��9OgS��-���@`'�%���,�a��1ǴP�$��q�X>��gW�MHL�P���GĈ%�F�7,'��-�Y�6���f���QD����y����[}@4�ԣ���yjbgBct��ate��t��Ʉ�uY�(F���r�E]0ġD�y�u�k�~�Ĳeq9��c� �ѯ�����1z�vA��Ŭ���`b�2+G��N�Yn|,� ��T94E.}�%h�΢a84d�#�A ��!�P��in�u�c�2��g��8�m���ārtHcbT��kOX��D�[o��0q�^��fc]���AA��9�F�����˩�1���J��{� O�C⤽JN�u����=�8��M�#:���l��}��逴Z٢!����v�O��CQ
$r�rtݾ��1i3,Fo�����	ؖ!�1-��l{5��@���n`��;�=C����Z}�sx�0�):�f�Z��][Uۀ�������G���/�T��$�IU\��I�� �=��f<�#���J�_�����,a�Ȣ �?�A���p�t�w���Ὂ6 #�*��Y/&��\!��M�<�[�E��{#���L(�f*"��6H��]���Ev!���8J���	,�oW�%ݤ�۝c�S����L���fiтjl��7�}�F�gm�C͕@���.=1���sO�a�h7������%����t�O���,Ň��5��!Rv��z�3[��z��FX1�r�
�.���J_��E�'&f��=�Q�VŅ=�A&�����3�\{�+�s{J�8��曓>Q��V��f��f!9���\#E��oF�"荀p8?!�M(���v���BC�p�mO�v��q��s=�%EU���c��ܱh��K�{�N1�j5���"�]��X	sE���]A����N�+{�P�� aW����(M���� ��$����v�)VX�J��g�E��}�WeN��p%5�n+�"0���,V!��d6��t@�H#!��l��L�W�9BZ�%�/3���s"����ї�PWd3�E��Q�3	B#+ ���NJ`�p�cA�n���gT{&�kh�A�vŇf�EI�hC��<��#�;A]�����O.EJ��d,�G�����R[�N�dx%1{�a�L����j�;a�Jrej���N�\'{i7�R��.�I����C-�)�Wc�7A�xy����'��=Ʉ�gZ��z)M:����fa|d��.��;�g���|��1�1'Q�~�w��S��E�/j�	��Hq��<E���vF^}!�nV7�YAyb��4�����E:�q�8M��o^8R�N�9	j��94�mc=R�"��4w��V����BeՌ�,ge� <�)-��/���Y,Q�K:�/F/2zJ�d�Z>�����O�r��%��ڃ�}Z]A"�y���}PVD���ř#K}GI���H@fF���9pfD��\A��ư1�vV0�x^�G��YQ�azJ"+X��8"u��Wp��b fH��(�7��I�4/�l��N�
�7H�O�$�~%�ծ��k+���2��i��%H���Y���t@�
'�Y����9d�������P��Y�9��̿��]�N����I+��V�X3f%�K��0Su�;�#SKqݢi���H&%��"ez�ߖ%��8�dD�G�u>6��'B�==4t��4w��㔳�k[/OI8� ��m)7�!���~���
S�mZ����U�PgXp��#I���г�]}��]:��p�L��!y!^���:\8�TV�=�کĎ��s���Ő:F0б��h�"�WvSث��2�lcG�L�řV�Y�h��?k��3����#3�'*aPi�����QgՒ1h��Ϊ/\p��8rA7�g&u�r�D\�g��w����ѓ�0��܆�
����)��#C��Yi^���\R�Ǚ��c�!R"�_f���w�v�͹��L�<����H"���v�/�h"�luQ���c��Q(�Y�!A�TkT�b��n�źfiF2�a�󹎹�7do�h�s��4��&��Z�N��Ć6n�#%s�9���\vM4w���/8��le��࿜�eR�4�	�<N�_�����Jw�p?6� �B=_ �|1����e�h�Α��F�7bk;l�/�[$]���3@�0H�=b�������z���������=3��M)�B'	��h����P	M���l�F5ц��t
�xV�f�B�4Zf�-7a3m\���,� qx�h���C�K�W���:rlB�$�G}9� \��/:�4�>fAb� 	�^M�w4��h���y�m�tv6̸�vn��4���</RJ[$�#<קm�*}���'��rR���i���(/�:�^MHWL9��%�iDXX}�s�QpK��̜m(t�x�AB:^an
M<�G�K�C'>I6"�	G`�t̄��h`�ad��J�F�ˁA�8H`���jӌ*�:.�pg	�&] �@��H�&��ȩ�n�H5��\(~��v�@�!NE�� w�9�c�V��H���������u�6�b�2�-l�p��Q'r"p�PTql�����x� �a�}>����"ox�
��*FE1#��i�̐H!sQ|�C�81�@sI<��r�a6��"���Ph�,"3ߏ!�a��8�$ѝ�DKJ��u�j�/v�a=7+g �i�t�ks�m�On�mf��,Cݕ�%cd�zG����Ĵɬvd�Q�$�jMg����[Д��\���G��+1����R��}��F*��"����W����I ��hO�t��N"��:I9 ��Xޒ�qP��+wohR]���a��L���L�� ˎ����I[r���Q�^�����\pڤGݑ��u�������О����!s�"�d�!���c�9�	(

c ���	D��G��FI)��*L"�g���E�EҊؽ3���X.�tD�hr3)LFg8�f7D۬����y���{����u��09�ܸg���I���.�@�� �Q����B����᠘8'�+��-G`�������iF41K0,B�wtPJ�XZ���M,��2'�v�֜�6������M�A�|�{S;C��|>Q�� )�0���Oi�gCn͠z�s((�5�	���p���8g����Ơ6�a7Y�udy��,8���W:�Ym$��ʱ���Y�n����q�l�w ��6�h�����UXЕJ�Q%��A)=��X �iW�`nB;��Rcp���(]����nt<;��%ds����>�-����*�i���ەxQz)À�Ј��l\�	2��ul K0g��'�)6$v,~������wG�C]����y�7�ۚ�2�I�������Ÿ��Ip�ǂ�s�hV�N	��l��Z�U�ݢa�2
?M�~���mIH"kR�_`|c^tL&�J��I�tf�)&9䪽A̴��8���c� đ9nJfKvaė=�㸟9�f�^84��2�wm���L�K�V"W�e�sx5����xjG߫��79o@)���d0��y���Ҭߞ��S�BG0s�E+�W�`蒎���иax �)�d�ү���bc˙TCbQ��}8������>պpW���z�����i�#F&[��
Yu38=�c��c�5l��h��l\�&H��m���0�=N��:;���^2��j�_�9ȝso�jY��-,�d����lXk��T`,b���h�et�q�\��Drr�P%\s���2��]�_*`N0�+$��MHf�{�;�k5q�&�����D���ɼ�v-\��>�.�ѣ�{̩�l��� �Ғ��弅l,j�3T�[�,/@D��P7)U�3�@� $͂���9�|��ˉvU?G�W	K��̝��{�֩��G��Q��F9��6ޅ$���룠Ლ[�ۀ�pY(�L�I`s35(eP@+ N���5$xC��d:
9ad�G����lt�N)!��?iqG5�B%)��Gn��'�s�LD8ӯ��c<��$��5d��G �A�}�$%N���}�y4sb�ւ*���1�0�A�6�TN��Z��N�P������T���U\�T�|9���T&yU��� gǻ��J(�`,���Â��~�=��f��+')��w��J��]�"NE�S3�㮎��� *����z`�P(�g�j`��*�H�TU�\��"�?�c�#Ն\F�as�x �`y���4��%��蠚A���aȯ�5���U�'�f0�����D���M	��!�[!1p��̩4%��$�rg.��si��Ǭ'�3[�qd���&�@ϥ}���Ӻ���p��L����C��d|�p&�p�A�s������|G�q��]�3���R��)��*t���&��)�榖+�1�"���/�Sw�
h8�����Dvij*��5^�V��)�e/�6�8��I޿�\���t����m��:w��p�2�(Q���*z��0锟��dO?v��͐S�M��r�!y�Ie�(D�C\x���4�! 8Ò�`�&b�:�� 4Xrp�zA�R��������w��~\%A8�p3���l9r�g�늖|Z�b�Jr�35v��!#�t��!	�W���8(�{.7$龨)w��&�Lo��@�X�M'��KT��p�9g����']5���l_c�!qF[`���
z�>��"H�����N:"��{�s�1_T��B��ҭ1�IT�xh<��O�5~7"dbN���WnI.V���~(��T'g݂ɨ�P�+e�(;g�q�}��]�A�y�:k+Q��I�;��\�2p�L�Yb�}p�	&����[��s}ހc-l��O�t���0�+�t���G�8�n��F��y4�q�)�⹊��:w
�\�	ՙ��;%�O���ȟ��`�)W%�Y�m�<&T�#or���>G�Q�ӹ�y��WB������X����W�H"e��Bǧ��X��W[�ʝ1V���ifL���,L��>��O����>x�t����k#>puilv�FA,���p�L�f6R9�p$��ǔ�$^/�(�c��TI��T����.9���1�j:�2�2]:Pa���S�Ϋsh+p�16<��Ynkڃ:EA�	���)�gΐx-m1���������T�p���MZq}Ӱ'J�
RV��ӆ�X<�Ί���\��9�S�E� w!����X)� �2���4Ou�(�D�
����UGz+����W��-�Ґ�LG5[��&Vh���E�c�4�1F��rjb^=W�
ҳ��;�%,$��)?�U�Q�j���5s<��a�>ΡAT..iAyY����9۝v9oq[���R,PI�w��<�`G�>�����D�X�W�}���d&�\i�H M#�Nq�=���MΗar@*�K�M�T����[
�.��s��\҅�J�~������r�e3��s��d����h�k��������څ)�)5�9W}�lK�Ҥ�f'�UYN�˨���T��u�4T>�679�Ut�?��B ���Ne�1oR����x$I���0�9N'�#FHS���t�غ��	��s�I}�����>G��,��DU���a�P�Q(!EPt%���o�@����1�˖�.G
n���i�>�.=�\��XD�( V<�K�Xt�B㙑H�)Σ��+
�(���*(N�rPro�Γ���}.<0>8Xu�2��d�cV7�#�� f8�[
MKP4 ʜ��j�L�8��l����Y�	Y�6�4��+���u�'Ձ��f��Tpd��0�t�m-h!�p�d:��u�V�!R���(㵪��Q�Li!��kƦF`8W]�ϵ�J�tRA%t�?�.l&eq�`q.{z��?r�S�ڔ6��SDtU��#YL"%ͮjr�f)��t\�f�dqfx�T|ɋ��ֹ-�e�-�f`�Bz��^l
���:�
i�FWQ80�ēCʫ5�Q0Y�4A@'�Rb��Ě�P��$R{ܑ�d��M9!18	�Ɣ�ڀ���U���4ڿ*E�81_�J�F��_6�f]�ܰj�xeN��t�ݡ�:��O��Su�2W�O�y,�$�J��2���Tڷo�K\��Yx`�AG9�3�Wum���?�U}L;�<���X)8��|}�� j�Z`��8���ܰ^��'j/�`���4�_4�uiY��gNjP1�lfb|bN;�:d c$f�jlZw ���i��⒘�ͨȘ��fN������V�&�:6��z ��>���O�Z+��cE_ꔩemR9�U��p��?��֕d�a�C?|�EU��J׷D���~�oh��M�~����">O���>Z����h�{b8S�T��s	�)��z*h��5/%������fT���*�<QK<ק���*�u���*ڎ#��4��g�-`0cG��TL9�"�ձ/Р���H�K��@� �M�ٙ:G�?<�V3j?lbF��2�^�Z���)>*�(��)�[�HX"����ȻyB�S+��X8|%��XGl][��-�P��A��T� S(�M��*PP��9BWb��Ϋչ�eu��k&����zQ�i{N1cu����
^$�OW1��7�Q+�~�w/�#��ywrf� ��\��F7aLO{ލ���0�����!�؃���m]�+$M�,6�y%k�x�ȸ�Qr!���%#�C��3�.̥F�#��8�&O�WF%��iS�u�-�4�_�I.�P��b~�?�U�UP�UMܺx�z=ͽ�T��RgR�����̹rGn�P�G��u�hJ��R�nK7��8��3�P��1�U��$d��z�TG)4�?��U�s�Z�vw���yw�7,�/hfO�+���ȿ�l�#I�����~.�?���Z4�)��^�;F	A�oh��#���Z�2�@�����͖L3���y�N�P�zo8�BA]�S˒ �Vd��f�\ܘ4-I�e���#JfvM�Τ��$�3�{�=ꪝc����u�O�W/��uxt���P'����'��u�=��99�n������ݝ���ݮ��|�7'��V��D}�����w;�]u|��v��wG;';�/	�����G;/_��v��GtCUz��a��d�{��x���uǤj�cvM}�s�����|p��|������P����ã��1 `������������mKC=�'jwf�N�&m5t���m�����;�;�/�V����>tA���ȷ^�v����G��ݦb@����_�@��;``�u���ؗ3� �	���?x�"潻�!�U��ݭ��7���n�_�u��' 4�������s��:����"<u;;G�����#�r��d�����&౫���c�#u� }���ELu��5��D�T��;/���h�&��v``�z�0F�^�,a|$v���w^��l��~�X<[��<?@�<����x`�%\���^�e�ء�3�K���������@�@ ����c�+.-< �k��8y�װ� �5�@�����L�j��)0��t��}���G�}@�����#�o�߀�����ϫ��-�s��MFt�������Hx���A:+�-�� _���^ɲ)o+�^�R<�B����ڎ�rGp�#�G���M�[��0x\:��
����̉l8�٦ߛ"�iko�c�g�b�>��%�Y��Kq�p�*at���pa��T�^�͎�z��O����wtGB�O�,OGx~�
'���:z|���W�L�&�zg�����3G@K�g�.-i_,�Z���u�s����{�:�"N�:ѩ�ߣ��eU�;$�ׇl�K{+�Ng�+�%B"�8�s�9H�T�/��p��!��|�5�0qoHu�*q�x�Wg�:D�m�k���/��7�������%i�#����P��V}�G���sw�����ؼ=֍A����D���}-�w#f@��x3���~Qb�D �zPҽu�72jF����,n5Iɨc����3��ڮt�-�B\� :�}]�͙����	�,�A	Mq"q�7���DZ�Zު�o�:ݷ��H��o����U�mx˽i��9�j{PB|n�:��PKsϾ�?�u��6cJ��G�Ǐ�����eӬF�����j��}H��q��a9�*-ڣZ]C	�U���\-V� X��i��*j^��y�����qĖ BXd���ɺj�#\�6��~f�|�RWΩEfq�� ;f>D��t:�l�.//��ɬ�f�-�������=<t�6�""�;���W�S�{��ei�U��p��+07WPN\;T��G�������l%D|d�@�(]�J����XvJu�ة[��ȑ�o��oo�Ktȥ�	������O��߻��SZSYN5����~y�i����ˣ�ÎIo{���P��$<u���w�G���j��F
*s����-��o�wO:�a��;�:�"bۖgꮃ1-V��v�S��/_����r�hF�U�	��,}W3y�2d�5�TK�5�}�^aF����-�F�(�SNڷ�8��5�za$� ����x5�7eݱ��ㅉ���ovv��d�Um67޼�4�q���p�1.�ts���pׇ+�M�����9+���Ĳ㘑\�u%���/���=J�`�L�E<td�9nۣ���↔;s��g�>�Թ��^�Ww�D�.��e�{�%���h�ԡ7�=LǱ0��r)&�T�t2�j]�V �+��ɨ9��G�:��g���^�����6���������u��>~�A����w���m<z���6����?^S�퇫��V?�x��E
%O����`��w��2���|��x�[��e�}T���h/�:y���w�������-�RNr����T������I�\Ġ&p�����w� �e:�m�r�Zp������j���>��a]�	����l{�!#,�$&L��8�t�C�l7\�z�� �dh��ЇG�6�5WO�L�c;}�f��i��p�;��w:C��A�Э)|���m�FϬ��5�Qg�A�^ΰ�U/B�Og����ŉ)�)��HZ�șȡ�hH�����<�d��Y�̇Z�6�d�Ϥ�\8Ɇ�,��c�&I;�K�����]1�E2#q|1�ƾD^J��+1.2��>W�+R��N�9x�i���U���C�`KC^��8��So������¨p��i�-G�Q��8�(�'gޘrcS^7z���ghW��iM{C��U|��^�ޖA�q� V��=0P��Ia�l��G'`ϐ�MNl4�e�,��&��T~�emb"<Y�+���Rg��'�,����������p���R?����~��Z��v��m�;S+�`m��x��^i?<m�o�=��x�06pt����c���e�Ӫ�f[
õ����@mR"���13;N�c�Յ/���:��@~X^��=S�����>�w��I-����ؼ��3��2���26��:�s�?�篷���_^���0��a���>4g�Lz����~�����^i�#�oh����S��\mkN�T{(���9U�h�I����>��	ׁ�Ƌ }�o�K�W�0���Ld�B��-�_�͛��s��B�]Xd�_v�CNx+�ph�>�	@�=2v0!\��
9���L��&�T�\8�	Fh�;��#7u&G25�����j���M=V��z<{og���O���Nc���;%�E�lVtk~�q�Wq�f+¾��Z��E��7��90��t7='9��Z��$�F�9
� �
gJ��S��.)��L���H����?����ك��䌰6� �Yܰ�o���~����Z����x��:>�q.i�NP {��+LU����(JMU�MD��&d��G��z�#�
돕�J�dƥG}����deum��贽�������a�H���\�ɝ����ܗ��t!�O;�"͢|��s�e�L���Q)W�\���󬈃� ��t?b����n�E�vO�N��n�EA�P����w�/�{�{��p�4l�FV���&y��3�{�y�m(���`����\���� �rk�R
��`|�^k�5�͇��� ~����. ���S/γ��`�~�m7�4WOۏ�B:�:�9<9}��eʛ�C����V�ڱ_ۢ`�uXh��f�c<��=.`��{��]��M[��27���o�M���bU�x;p�|o����A�|a�X�͋@����N)�_�3�o�"z��?y[�������ݓSR��� �塚'��@�":��zs���Jߍ�[R?�ޡ��}�T�<ag^��n��2Q��Z��J��[�~��J��yX�~���y�au�������lXp�C������N#�_{�`�}�I��S�?Ħ(=�RLW����+��?��Ȏ����9�`B���qė�����Ԯ-��l�O
�  [�W�X��
��8l3�O��D,�ģ��tX�tL��o�#���S|3�׀��,r��W����;�T��ľc�hYY�cA�R�\��As��x�QLP��o�|�����!:U��|���U��xYBpOm��[�ʍ����9F�P�����u��ZM�����JQ��6B����m�VJ5�Z�/�H�d��0U������ r�c���T�� �0�>[<xW�'�/>zVk*g
����I�݃��.�r���N<nZ����u�u��5s��O�2�J�^��Ho4��B�Rƃ��R�^Sh���Y��� ��.f�ǉ>(ĝO�������G;h86.�j�?Yq}�Tƶ�(|�-���ȉ��g�����W�1͑*\ŧn�@��p�H2�i�h��n��棶·n�e*�l�V8=K�s��]r��L:������q��z�xQL1�_���BgF��1w�g�:��s%�1Q��|i�T*������a�y�΋Xnn�M�
}�x�#��̸
X���	�z��&&԰?o��%�nq&oe3�c�Tqa�9:�G�μ&���C�kGi�N!���3!�7w]����\�{Vv�Vc�.2����6�t^�X�$oCA#n�{�z�RhN$�̞b/]����i�/B>���Y���p��Q��`C˾]�:ф��H�a�5���K�q��$�7c�
u�����3��I��0syZ�l&= to{k*�2��4�8����۝Czܐ��}|��L��,�i'd�Ȁx��JY�U)PXa��'ʜ=��c^�����	g�gr��u��������7�R�\,����M����q�i@�%�D����UQ~�b�`bƒ�Z�`�c�[\�=t����џ�Gq������]M��wL��lΠ��u������c/1t4܆�h���u[���SL�c<��S��Y�V�Ph��A� �[��aW�Z������@R��|,�E�k��[�������¶�o��2��L���Zy`�f�f���4֞���KR45n�=<Q���c>���}�:/���t���Dr՝:A���H8u�ߨ7Zu�h�|=��>���܆��R�M?�7��� rC-��陙���Cn���� S!~���몘�IZ���S�v��X�D��\14��� �]D4��J��y�i7r��Pu��Tk�VyJl�s-��.�,_'��g��H�!�۩7�N�;�T�EϱʩQ���'4 ��\|��6�%K�(n�c��Z��_��,���������?4�&P�7n�<-�s,�N�S��YW�@���;=�x����j�``;�˺��Z
=E
̢s&G�ʛv���Q��Xl��N:ȼẫ4o�ԩ2C�H�. �Ν�n�~��N�����O�zPW�=n�J�U5���TH��]�>W�4�w�w^�c"�,�d��W>~xN@�6�s��"*����;uR�*���~_'l_�x��>������Z�!�2D\9直��z�?���Tu
��{^M7>��ƮD��)+�l�D�LO��nXW�T��"Q+�b|M=٧4�탽��~��6�<�NF0��V���[|�NH�����S5�2	���LC~	��qj����y�95h;Uc���	離���ǐ~��������+�8w>��s��*��ޮg2Z�X�h�gߓ[����5�2+�� ۠�.�܍��a:����h�C[�W�*�y�tw�����q�'�N÷`̓_>�<g@��m���٭�i����T�Գ@��k=����ߜ�#g��H?���NJ}s�^O��r&!�7���Y�Y�������7��艻(:�n j|}���*VaNں1��JI�W6�q�x�rSX�������8Gu����-�9[P%��A���rN��?
��}~� vqL�|�
��7F��f��St^5<E�f7�ͪ�N`]:�$�nr������SrTgE<j�$�*%�9����V2 �0�2�R��ʠ�����`��Nx�=?��Fs�o��c�R��pH��Qպ�.��c���4�PD��o��}�B� W�Z��9�^2Dh�C�F�e960琀��nS�:b�h.`��v�]2t�v���ژ]��G+�X��A-��M�gs0��g�±�����$<w�D�q:"��N�D�	���堿��U �eHΩ_}�A�na�+�o����/f	��0�|)u����e�7���2�RԮ̤���N����nw��ɫoe���e�zi�2��pHr�l�<f�^��F��8�D��N�\� �1P�w6���T`S��"G���]���|:�w'H�RpS/޼d��ZZ�������M�	<�KS�۝�虞�G񔢖����u���/#]����p�������4p�L~�C��Q&/�,ҦY}����i��j��bQ*���ځz.`�>|�/<�>�n��vN��֩j��qU����=��])Z�R(�����7������\�:1�B�m��<:J�g
�WH��������	�3M;�1�J���2��m��߲Q�س��Ib#l��܋�A��=�m��@(qI3d\��y��E4��P�� bh��H!oB���^Sw_�AY�g���g��I��\�LC�BN�cL�l�����4K\H��� '��� �!,���wZ���v��p��l�,��Ƹ�ګM��$�CB%2;ɑ3�v�,0#��
���x�J�:I�R���������!� ZóQ�O�_�	�o73U1t+��E������ǰ8���x0n��䛭�d����HQ9ۢM+�Vުo��CW���c��F�Ķ>(��u|=��a� ��HO?���T'��i���tb�D[/oAE����զ�:&=�t-�@���7�2k��N�X�o]��|0i�)j���cq������������x����׾���5>�1p�"�1h�[�zp;'D����j�������L�c�s'p�O�3��z%~���x3���������R��ǏW���_���{��h���ڽv{}cu�W�V���:X��Sj����o<z|�>y��q{��v�8��կ��������~=v߶g�֣p����d��è������Շ�����Itv����`�}۞K�������W��a��ٓ�k���G�kO�`:_�����󶜏x����I�{�q~�p��6���^�����^���^{���:�Yy�h�>[];��z����ٓv�0l?z8X{m|}�~��㰿�� ��h}������GO� ������kg���v}�h��j�a�D,t������q����:'�Q2�ǒxѽG��c;iO;�?�N��^ ��DjDʎ=�}�}�����V 	R�%۲w3���B�V �����J�^mh&T���jUmٍV]m�`ܨfA��Ѥ
��SZ��7���Y�fڭV-���`~�f��z�U�5�R���]�CՌf[S�z�h(Ѝ_�ժR]���Z���"{2Ӫ�v�YiVͺ���a�JM�j�b(-˨�MNy�L�n3�3�pɹU��e)}��,[��4�H�@�@��P�o5�YT�%��Mݶk�b5-ņ��*�WfF�7j�:��L+5ڲ��6�v��+0�5�C_k�j�KN�ښ��E����e�io�m�pA��Z��Mˬ�ku �!葩�k��jU�ԩ]�j&�YH �YմV�ڲL6��k���6H-���+���{�t���+� 7�oj��V�Z�a�>��6R�#iw
���c��Tu� <@T����ַ�z�Ę�e�?*�vKگj-SQ��RPj��X&�5]mA��2�a[u�%l�ٴUX�-]�5�*�'��Ӻ]�Q3=�̤VQ{ª6�����שр1n)M��8,LXx�b����z�^S����(�!ʉ�=4���f��5U *�Cjfժ[��M[0���m4���ڨfcU�ד=�AKu�fԍ�U�u8ck�U��[}���j@o����qj��N��0lV�*���@��f�a+����&1�u���[`e#Pk�^\��V�l��~&�o�T�V5C��3j漩�{�"��
�=��ǻ0l�m�-C��l�Tl`�`q�9]�+��(F�^@i�-k/��uM��� �����N���_�����h��]�Y������H=|Nѱ�5F���ͭ��ת-8�C������V}iC�&��}�h����hf8-89k�a�lx�*Pr�(�M�)�Q@�����TkvC�a0@��m�v���͆ig�\����٬Ԭ�f�j�,�i�}hgSoY�^kT[��@و���'�g<[�K�Sܳ�m�Tћ�Um�Z*�#p4�Vvs�Ɠ�p\[5�O����nm՚u�jXp�Y� �6��m��v�Zմl����ŲUՆ3��0�u8n�Qa'�Q�{ۻ�݂�cn@6��iMKk�[:�%�|�
�Am���N�V�t��V�6M�}��l�	LUK��jB>�䛛��x�P��L(��j��P^B�O�6��l�����H���O.�e����c��_�i5.�� Nj(�#!���:��0�������&�_�='/��6y�r����-�FZ�ᡚ���HW<s�|��}e���b?��O���$��i�-��9���{��t���W�hTH,�Ԟ1˄�[,�����u�!�m%/=�BW�W�7����,�޵� *�b���m~o�������� ��AX�Z<�� �v4�`lI��Y��[YO;���(	3�`|�� ���6�j�9=6����0.��.DO@�o��KzY��ʧ��`r������Q��;}��q��X�4��w��*鯼����Z���]����$��:���{l�H� �p����<3;K6�a�El�8�
�C����m�bT<�^�:�}y�#���/t��˼Γ�6$:a���A"�@۶�h/���0|,��1�zw�������ỽ_�x����(��RM�	�uz)|j��baO���L؜���1�3�N��	�ԠY�>P CDI�t�5�S>\�[���Դ�zef�f���vVa��p�'͊d�q��A�|˨%��wB�e�Y�	Z�0:��Tv���Kՙ���߬�Rr�V�h�F��I�9C��=Bh��U��4����[D����w�d.���Sb���A긙�Wժ���������������Lx�2�<)�i I�Zo�[���Swd����r �D
����{V��17��K�k	C
�)"V�\vw���E�V����_� ��:�G�H+o8W= G]���q�Ϗg폗�w���_?��Ҳ�:�5f���_�N��I� ̎�/��lf��u��3]U
�c��[��JU�=˄� ���i�q�S-2ҟ�;j \GGR��=d�lh��q�`~��3Bl�Yv@�L�]�˒��wMo$X|2�_I���`�gf�6�0՞A��"S�J�cz��$K^���=xѩx,�E+�ﻴR��o�_��;�g�p*�p�Z�jq�
��P�+0�f&3��Z !�����'�ŕK	�!�*lϥ�2iV�ٰl"����C�3ß�H�"i5;��P��Eŝ���t�tA�mr�S�w<̊~�M�l���T����a����T�����LJ, p�||I�BJ3c(ʵ��W�4�8n���Ř`���ucр7_.���݂3�d�)�5�[;;�_���JShG����MU����*3��!��roYB?h����N�R�~G����h���uF�����"�f�D������y<��=]2�B�ZcгR���N&�
��3��[�6^ތ7��� b�2q��(�P���BAn
7�Y(ȕ�f!�����Ĉ�>4"�.�B�H3��l����K�`[��p?�_��)Zn'v��\N��{h������8n���Vd�J�<����$��XD|@gv�Rg^����;a������hHMʺ.�6�ؑercD��Wh�f˝�������A�,o�M:�4�"���>�h���:��l6��w��F@�Pf�=���̋�8��&�I�����C�#�3�Ec^�hJ����|b7b���1�0Ǚ����&4�5���X�F�qqz���<Z*4u;)�X����%睍�1�#-YV�t�����І�1�
�5C8B�c�Հ�!�>�����|�;�/��q�$vA��
�c��=V�V�]m�?tU���_�?j����%����{��P��C^�&�7����eWY�up~�p��K]/>��!Ϲ�	�_�b�q?�ۇ�$�Nx/��'[��I�e��ձ��_�S��Z��s����sv�J�m��Qy���u*�.�AX��f����ٍr�"w��u��5�{,ݏ���b:��dIYD�Mr����tww#6����H���~�U��j�u�ޮBj7[�'��s��ن���c���j5��\�պZ���:R���(��iC�*�ͱ ��r�ǖ�V,��GR+�X��vD/ޱ��7�Az���g��LI�;��5��\G����e��Rt��V�Z>��H)/=R��׿�Ы���#%��<Lw��Z#��גf�=@��������Is�P����?��6R�_����ߵ��I�h�HBO�Q(Z�&�(r��'�����3�ȧ��-��r�Y�;������SW��c)�<Ɔ�c�
G['?v^��,�U9R��-.�� 8�F��ت��/0���Ȇ���(�xI��Q�		{@��+
�.CR΂�/t�S�5�w����m<4igm�,	���+��
}��9���PS/"ߛNx�/y�������%�}��cy�O��U����i���q����kI�yڼ_���R��?JU%��hz��������gѫ߳�^�?�˻߳;<�=@�O��������-|�{���%_ ��� y�wr=:�V��%��W��G�������5�ټ��2�A�٪_�V�^�PH<QDDIԺ5Bp^�΄[�)��85.�Ukܨ�{�N"(i"�Y� ���j�"3z�������ً��������ֻ$\l�㛉���A��L2tm��)�D���F�;{��ҵ��
彝(���Mc�L����S��?>�T�`/?�Y9¸Z�yZ�����U FŭKM�E�!3M ŷ�m���it9ߗ>��?2��m�u�ƙ��9��0����	�n �����v��u.���$�$j���N�.�<|��B-
�]��>�?��J�7KGo��Q�1\�+{c~�_����n��Q���QW"�� 1�L����������笮�-�:�\�nB��kB�S��v�<) ����7�GO���uFl�"Ev bL�0��>u���Vc�����I���˰��)��C�@��Nl�(�IV���Z}�c�0�5��3X��$��a����� �hL�.�tR:Me"P3_&P�b���Q�c%p� u0Cl�V����c��]��K�@_Ye�L�b��Ҟk�/���<:���)��ag���Ʉb��T�����r;�po��c\�;>��j��
��X��!l�m�1NGt�{n��8+3�Ʃ�/Y�	J�[�%���&��]�aX�T���?��[5U�zr����݋�c[��>�-��:�G��˷�/��9>���_^��fpeo����������}㿇����2�~{}}�S��qk����;~����A����g�mK4�'��	��R����Y6���A�-�L�&��aP���N�<����΃��7���o'h���w�i������Ë���2��S6�B:p���)=����k?{�K���t��_Áf�� ��������5��L=�m㧟?�U�÷�����Ӈ���ӟ�Ps���/��\7~u���;�g'���?�����v���������~��������U��A���V�]��c}�����֎�mLcz��޸q$����ۅ�)�&��"�`�|G� �4��j	X5�F��	��l��G��ܧ��0���<DW蒪dX�9M�%?,����0觾�_�֜�z�+#��#���K���5���!ï7��%�s �s�F�O^��б�6��"���d6��b�f�k���Ϧ��]fb��8��s�%�0GF���H��'��Jm� ���c��OM���W���j~���$�?Qk���2(���eP�R{�WAX�a��pl\�)X\ ���97{:Pd����d���>��q:x-��7` 7�%2��蹙9�����)� < Ǜ
͚�a'n��W��bq[��ս�O	�I��!p���u��1"�so2��PF�0D�	�1ɎQM�), >cꟳ�R�b�L>8Llb�����&�&����\��\Ta���5�Ƹ�}8^b�`���A1I��h�<pֵ���R*�~RBH�3�N��.�8����bʷ;���
p�ZY+�e y���<�������fz�O;D�� �yQ0�������8g{�gR�f�'\��+�^�;�V$���>GR���~�����w�:�$f`��
PȽn�7�[�P��{������nz�|�`t��EL��R=�SEÿ�V06Uܛw`��e����TpaW®G.m��0���:��[#(��R����mi�H��ܖ"���?���=9<޽%�}>�gP��1���<�Z�����N1�w�៨O?z~W�*2j�iʨ�D��s�d��s��,�uߟ&s�ۦ���ߣ�E���z=~�����=��֑r�o�"ߜ����>!������畭���&����k# ���D�O�6�L� �uhP;����a�;O2哘H�)Y��E��	x}�p�G���"����+P�,�!�!���l3�B`z u\�!B�a�|.Z����� �$��6(��$J����c1&��#�M�h�X�YW��ɱc�#ng���!a�WC;Rώ�15�W�y�G*̍�♗��\���a�l[���	g�=u��\�ԃ�o>�hS�34�����3A-2����26_� ���1IZ�~Q7���v�L�{߳�3z�tb�q�����4At�B}z���iI��^��M�c�_EG�_U���?kI9����O_��AdW�>!���%�2�k]�9�S��$t��je�
ѿw�p����2p�4{��=� z��vh�� \h�_S��?�U����:R~�����^]O���. �U��� �Ӱ���_`��k<�Ô� c�x����S���;���Arf�L�\8~�xY�8�!Uq	�)�s��i�_ѭ����z���
�]�{�GMy��e��;#�p]�nl� �GJ�c�A�Ƅ��PȻH���Nm�zMbW5a�������4���C���wFY�]]�y��e� ����Q��åe���\ .��g��ijU���גf�_�{R��a�=�8��!.�����7Uc�^�念�<�Ӛ�>ݰ��'�-��������}��������wΥ��G��Q�.���iJ
���5O�Z�\>�O+����D0#u�����M�㕖�<��˒�K*H`ꌮ�M��3a��U7�,,�� ������fņ���������K"��֟x#�V��_:_��/#u|,�~5Dǟ��Oi|}H�w��񤯦��5�+�>�Z�D�݈Z�@-u�Hj1N����*�&5��vs��>�����NAR-���E,�%IAVu��>ҁ���\�D����JTQ�)HՄ����4�I���P?p\��ȓ���*83��&�v��b�����@0�I�,�h�"ߌ���+���/$V���������!�����{�)�{t��ǿ��I�l�:�s\%�U�?݃����+lo�~x��a�p��m)�ful)��zG[���㝯a,�g^l<^6
�~y�u�G�'���0��/��$�^T�\g#�; ��m��V�W�t��ZE��{C��.���g���U������Rɀ�&���`~�"�t�w��O�%� y:*�,�)ѽ0		�w�	�Q�;��1ҙ���&�A:?��,j®qga��p�7���ſ	�+t�XzR]}���=WT��s�e\��Y��S�-I1�˜0�.&�C��f�p?J!��� �����hGy��=�J��Jb�b~q���$sz��3��@���9:���3���\�?�/����@�h�{8�yzr&P߮y���/�ش�#x�1乍�Sn�tϔ+��?���!	���<�ZE�t�Q���*QԆR���גV%��/h�����a�<}��q8 ����<���IQ�j_��ӷ0PzY��J5u�2��+
��}Gv����#�J�\��x��Y�k�nl6�=v.�ԁRe[������-഑9��$Eq��劯Bc<-oF��"�L����s�W"��U��=ց��/�X��"m(�Z|��aX����I嵸<��u'<��%5a��5=�e�I��X(�l�'|��7��_�O���>~�8N@�%��hc�xt����ih1�q��x|2�����ѽ�h1�R[Ç�n�1��W𜗼���x��Z����O�<�c��qS)�� �rSA�iq�㳨T<j��q��;���c���B����2�Դu��j���Ɣ��K�s����?s�u����?�����	����?�oQ��mբ}����jߒ�g8ٹ�g����L����[�̮>���ڐ�?k<��^��u�\�[��7g]�!�?]�`�B��j	�0lO(�N�B�T��[�˅��+�eL.���+�؋�a_4���B��̗ЅI�}�"̭?��X�ˮA[PCZ��# ��t��R	!Pv[�`���y���,�G޿��WBЃ3�6�����Ң[<߆�6�3s۝�py�)-e������c��'�U����\�[G�����W�Ӷ ��r<�j��;�'6|M�)�6z霱����S�ĳ��������o�ƛ8#�2��h���^�3<�3k>�ȏ�5Lf���V~s�p���N_��1�cU��(K��d(��~F��Zi0�LcX�����|���� ���jiBY��ͱpJ&=3.o�6,���ܜq��}�(� �0�"(�s�i�2u04-Zۢ[\\��3<A��%f�Q9�V���F��4��2+[����7�hJ�j����b4� ���%[��>�8�g�W�F�G�j�&ްg�$�{�m"��a9��K8�4:�jY+7�JYU�Z�^V��rS�},2���t����{bX VwЁ(S�c�
�U4�8r'8r|܈���V~,~���w�� ����v�h����B�l~3��;>��+��*> 	a�rz�~%Da[LE�EΟ7-��^�B�/z���T��O�����:R.�}񟞾���z�$x�����yw\MOO�{g8C�#������������qB�Ic��"�C�2�Hr��-w��9�C6��~+��=���];,0�m��`[��W�M�Ee�{a�d�VC�Wn`|ɮ'��nuO"�.G���ЭD�7-Q�����),��R��o@AK�<`��#�~���Ɲ2r"�+N��B���&��E���Ź�y�[Ժ�����(�DH��'��u��1�c�.����ܟ�/��1���;�Xm}3,�m�~9��tJ�c�π1�?u����=�i��ɜ�#��C.d�4A6FL8<�}����k���1*���!2�Gd؞��d���w 7��K,�m��c��[%5�HX���4(�b-�?�sv�`�Lݠ���!��$�8nf�e����[�n4u�Qo��~;b�:.Pg��*���4����9��t�G<2�I�_G�I*��H�w&�V��)�N�����8J��&���<��I��,�&�sM��A$�-�&4ئ_�T*�!EQ�S���y|L|������W�y��E���OM8Zግ 0��e��E�@m�x���u��F���pL����Ddv����̷����M�5_�_�����ox�w�A���&�	�������hW����ձ������@2���������kI+x����e���z��=��^A2wTF܍U�g�u����+k1s�ѓ��T�]�_a�Lܳ$��~�?#�����I%�1���u4�.+{����RZ��
�F�2挐��[JχW�����^�>]9w���>�SS�=+|E��#dWt.h����y�ݽ�es<��ۗd�X�����Ǽ���_ƝТ7�yn�6+�?�s� }\r.n>���?���'Hs��ֱ���0����uE����s�ϵ������������������UCPO��TN|�_pid|�6&��{�:��5�(W�sv�?�>���4�����:nq���?�<��zR~���~���W~�����!����	�Z�gi��O�&�mhp�Wj��u-i�Q�a< =Q@�^�`u���_x�/q�/y��m� >{&y3琟=�o��;�W;/���ڇ5w�����O�C¹���ۍ��E��P7}��Y�E������(A*SE��x��0��
Cbg�3R
ț��}R�J�'@Ք�3�����2�7�������m80z�kM�>��x��lj��fu��Y��p�l��=8��VF��kIMc#�ݲ�'�h���c���)��0�����Gֲ�����������?U�I����Z�ʖS�A��@a[��)q֬Mf��Fm3ɞ# )m6ȓ�*+�2Is^jYIsY�.0�=J���΂�>b�ؿ�v��`zD�n�(Vq7��U�N��!�_��{C�CTjQod2�i�LpSa�D^���*�-�3�A���INQ��$;��B%���\�H��\x��f�hpv`�],����Om�X��i��ߟT��Y��_IU \�1��dF�ӓ���P�{oS�
����k�E�E�ta�d�dd�Scx#r�Z�����1q.;ܻ���p?�Tء|!@����=�U>n�w\\z��2wnP��t��$�����pr5�߁M�ЌW��
f�>@1X��Й�*�~����oFr���1��Q.���Ț!!��'Έ�եVGW�T����>��i��Y��幾���N&�$��,��Ol�P���a�bh�$�[J��Ʒg���雔�՚���2�����?�'=�[<���*w������%`b�=�A� 6k�!���i�����p�
b>�~�8��$�Cq<�����lϹ�4�1�l|�ȹ���n��5,�Kr�M�ջ"�f��8D*��}XP���42�@�0l��7���`�KQOݘ\A�`ÇE�d�a��h�yͰ��T�Љ�K���AF���0�z㉇�X�u���$�qF�2�o0}�ZX�3dJ5��$ǇM
�a�}��{ۧݓ�w{�n����¡�<�wd>#�Ę0�����]��B<"-�#/lg,"m�K��QJ]eq��;2�$N����E�v�N�f�!�Xn��I��U�fRw���EN�Y��E���/lL%q_(:����Q�o	���]��ʳ�<�ό�"��A����KcBe�o�}��	5c�߿��o�M���L�`�2���?�J47����e�ּ:A��R�d�vO�o����84�C�XX";�#�f	��l(pv�l3�~%���ɶ�������o��73%��ٕ'�x�u,��U��U`������ד~�=x�w���pL�1�?��;jY��)��v�`�xo�S���}z�w�K�����n���V��/|�����N��L4O������,-X��zC������_������\(��� O�`;���N���i�g�r$���SH9�cB��Nt1�g�$	~���
ߎl&a������'�w���"�DXMs��[R�"�y�K������[ǝ��pJW�p�Zr�U;���x��xY!��b�}"!�e�u�k,R}���T�'0 �0R�Pd�no�]�&�LW�B�Xi�8��$سLX	`8�ǐ�79�"#���|Q� �k��P>��z���(�����f�1f��><x���x�\��{����hz��������HJF��3s:�E ka�	�tB�1����\��ˡ=xѩx,�E����]�ij1%-��\]w6��;�Tr7� �N��l���߰�إSx�S�\�������uO�������/�N�L�՚����/�b��\Z��pذ�t�A�lD@g!����C��(�E�kZ0��J@�r������Y(���9��T���p.P�f$h�fh� cx�VC�f$�l�s�=�d�&������h���ƀ=�$�L����^���������8̂��߆-id��6��3��wvrG@��~�I�;X,�7�&cx@63�>���$��yV6(�a�x�4&@'�%�hJSK��D@��L�Ք��A��������,/����H��b,��pp�*����p��ƅ� �0Ì�
���9YL#���3�1睍Ӎ*�8q�Si���'S�ۥ�}<�<�ӳ)c��rK���q�����1�
�e��N%��26�?�Y����<�GV��!�TƗ6Ɓ._�3	G�7ugcUw̩�����֊�cZt��3�������#9.:���Ѓ9��=��U�W����<�7e�1Ice�����U)�KU�������_֒���ǽ������wp�mp�*���:8�~��८�����$� '����Y�@�O���a)�''E��d��2i��s�u,�������������H���pvrsU��v��e�~�ć���#r�'f�Rf7ʭ�\�8ʭ��c�%�V'm�b�Eà��$�{��Nww��v�����H��l�:����7[m����UH�f��OI{��if��{;�o�N�Oz����Z��?���ԕ���ZRn��(�?�U�d%�9@قZn���ڊe��Hj�_ߎ��;���Yw��g��8*��\�,���K��5��ߨk����������x$���|�����td�� #���u8~�F6���f�����K�\?�ߗl�*<��%j���������\�9�w��f����v����`v�vv����Sd�O+��s��,+=��U�I�0ɛ��.�{�)���{�@�d�0s�x�t�c�{�B��@X|u�eٻ���1�c���o3VRǢ����+h��Py�ϵ���>���UMb=<ً�qI#��xs��v��*q��s�Ϋjn��I��LP0@J߄?�ɠ`[me<�3̖5�?�'�}�$��1�1Zn����fn ���⩚��� q�I���zp����?�
�co~y�S��<�)Oy�S��<�)O����)�D p 