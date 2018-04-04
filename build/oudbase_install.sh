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
� C��Z ��z�X�0X���8E+ۢ��$/Y%��MKtZU�Z���?���HPB�� )Ye���������Q�Q�'�����d�YU�fW�E� �'��s'��}�������+��	�������Z����u�ߓ���:���w���~f�4�`(y-l͆���<̿� �S��t68��Mgy+?�
},���'����?Z�����`�=�x�;���R����{�o#
���ypO5��Ў��"Ĺ���P/fy�Dy����h�N�Q2U��z��$ͦj��v�����,ʢ8�fa�Gj�������Q8��f�����]�ӿF�(Lw>��p������?vf��4�{�h&� :�F�ZM���rz�J�ٿNeZ�tow��m�q;��~7����Z{�Z��r]�y�&���p�M�<�/`�T��œ����,��#'0�)�
s�E�Y��� �y��(����.���q2�R�<�a��(���4�-��?OgSu�f�	]�O4�!l��Χ�I��n�A��)ν��#�L��w�~��)�x��|�Z���L����a���G���"�j*�2��M�~�g4�q������p�-���09��;`Sm�I��_��υ}�t�z������d{���G��f��2=���J���5u�M*~���<M՛p4��ϜH�{��9�V�Xom�6j��A�𰻿��v|��[S�>� Q��Q�;��d� �/z�g�����m ]D�)4@	83��������^���*�q�B��Ճ�Ó흣�����O�j��xR��/wv�ە�^���zke��;G�'�����ѳ}C"���.�|tz�V�o���x壬�u�y�A-����v������38q��f!�V�<�=[^�a�4����At�Nf����)꟧j�`ou^�W�6p���6�A��%}Ľ��uws(�Q���,Z���E���Qx��g\h�����h;���Tmg����NE���y~��f�~��������}�������}��W���e�^�	y�~��D��y���΁� � ^_�}Q�vš��zV�z�<�'
�E�Q�'�5�3m���z�غ��ɳ�8�����f��W�r/����#�7s�.�
~���]��nzF$l�z��G$$��.������j�M՚��)2�$���Ea�I�6�F�V>n\�����nW����)z>����N�_��c�bR6��$��'_�t�j�փ�4�����@?����
��"m�>R �fWp�3u�?^�>�tXjuD5@B��U����9b}n(�xf/j�EՀ��uO ��n@VT����w��w���^m~���]�V��y��h��ɒ���۟����k�3�Wk5����kЪ�藢<�[̯�C̽��gJd��!�M���-��<�����4ѱ:�м靧�`L38J���<Nͷ�s<�4j���0^� ������
�ήr���yM���g;H��L��p۞?������W��w�tِG�	���$���H���C<�cYh����dՄ�#6����"U�Z�]2��4J
ͻ0E�R�n�����p�����l�:r�R=8T3beH��i�r(�Q��b�]h�jYy���/��J!$& j� ��S���)�ǝ�
��/G��ݮ�fN^tz����^�+�F��є {Ë0����g}}�t6�i:럳����`Fi8P�V>�: �h�� ]p�η��ﲚ>��E��GK��f�g@҃�����봻�,IPn�P?�������#�;P���h�Y�>I/50b��j��׀3������p��8�Ih+�	��K��uDK��)�+X�Q$�$�i�R9���y����[g���&���x]��h�ݭE���.�ކomh�Wռ�/�9? ��v%y*�Z��!.�?��^Щ�4˧�2L�P�m���Q��YJ0_�҈�H�Ml��?�%���(��D�0�2�Zq*{ {�ir6�@���>��`�u�P��}x�bv�BG��g����tU7n[3�_v����/����/7���h'��q8�2*@bT7<�"�~�P8���fW��t3�|��1`�͊<��	��Ve��S�7֍F>�����C�f�Ļ�W}���^5���z���Ao��..
R�'���|?�ű�Z�y������1}X����h3�?5eq̥��`��j�{+L{�Ȓ����O�#�?�nҥ�9�o��s`��_�u�CG��pL"1/��#+�����88?��yz�VCD���v��@�x!a#���b+e��3�JrLoTMփeW<eg�4� ���O�rk�&F���0$�����5y[�_ěۛ�nv73����Ɗ <q��2��Q/��oq]�]���ypK�ǈ�����U�pM�s�fuu�=�����[�8�n���j(��'��V��tHC#��!�(Q����l,J�Pq��ڠ�+��x�O�6b�ʿ@O�$/�1�Y:VS���i_�?z+�X� �Д4]�f������1A���;��TG����N�:�pca�vT��?�X�i<�*K�H̩�s��\�H�.�#G���l�*�����Iѯ����÷۲lז�^q���23�	��2J�E�[�ȣY��.����x��}i�l�߽9��0�
�$i�x2���te�8�q�����Nl{�Ï�9�ʉC�irp��s�����s&{\q�p�<�X��Е�y�{E6�i8�v{:�s`� �xa����Ee���y�/+�f��{T��_S��/��{xG�l��a<M�	��1H��> �4�i�a���J���Ӽ�.i����} �}Z��_����S��sz4�����܋��5k{�=\=�F�W�K��%�q�5�+�5��8���>)^+ʊ��kjӷ���!�!Ye�P�E�ww�sH��y]嘎U�]�;�X��O�Y�^�W�_t���x�{V{�4߁^����=��q� �%��g�OY_|��q��T�/�� �}j#�X��G�~��=����>�WW��.O	����Su�~���Y�33T݌�;��a�i�|�^iþ�6��r�V�hzg����#�,t�<���v�o������H� B�p�A>���7 ގ�RU�����Av�� 4����ξ���p0����j�:w/��Xoj�����~��?�(3g� K�;�r�
�|r�����SA�k���Ӯ�9�^�����죉p��G�������F��(�Q���O4Z,T��	����_�>�a0�f��f����&!+�N��]5����%U4�L�.�4�%�$�g�5�Y� ��-Ba�ĉi���~�E��t2#		�<�W�Z)o����<����R�=*�()D~`���|�%����������� ҿE��õ�b�������������U����b����͉�ǈ��(�(��ʺ�S�-���Qȿ��~�-�C��R�}���A�N��݅ܫ�˘��(��"�q�b�K�ݽ�9V?8( �ncϮ��ϊ��yx}y̻@E_0��|�ۥ陷��x��$2��m�Ë��m'4��A�6̇,���V����������o�Q՝��>Kzz���	����GU�s����C#�����DN��i>�*��{� ���5�;:�7 �[�� �-�[�?n�W$�_9�n�M���5��o��*$9 �t�K��&��f�U�T��Y��`�A�Q%j��<r\�'�;YJ��	��U��_�q�$a�pQ 0�	����}��G�*?���NA�סչ��St��(��I�gźDľ%\|K}X��p���&yE��å�! Z��H�������	[:� �P�>��?z�Զ��b���iTb_�����̼&Q�6,��,����������]�03��i�tXS�(�_.�ш�X��C�Z{��j�ݻu�.���R��QL�;.��S�ټ���h[Y���H��׽f�ȨVVWW�&�A�xݶD��1��Ƶ��	g�A5s�
s9Xk���Z\ �f�������F��%9�7��W;��x5D*hN�,�&�>?; НD���������ϋ��>�
�$��i��6ѧd6>�/V2�Y�#5���<
����1���$.���§>����&��uP,�J���u�݇��7��.��7���ޜ`�14t��+�Z/�m?�Y0o�k�ߩ�Y��e�-����9��"w 7�'��ĲiL�� ��D�Q��
Ep��p�hb��/� *�u��li���a�LN��ϥ����D5�����96x�5����F\x�`�wxZ�xK�1C��kX���;4��s&�3�t���΋g�~*�j���?�)˅���{���5gBD�I��X}������iMh��UL}�� ��������v�s�~�ɬ��Y"i.v"����yi��dU���{��/��/mM��JL�c�[޵߭���p�+�w���u'�ұ+�/�v��v���c�gy����7��[Z8Bd�����}�W�<Z�_�蒘F�v��6����]"��{����c��͙+Acf����b ����c�	�o
-8o$�#��O�`�b��$�B�2D�)X���ȪhG��g����,�G^�Ȑ*覨���'�:�G3��]���U�����&�8�l�SB�������7�w�>��Dmı����)dϑu��SYi&�.�OQe��?C9��34a�W�� �F@��D?;_J�sK���WH��Q�'��F=Zo�t�|<&�JWۺ����_�"�����K�P�(u3����a�zs�\LB�SO^C{��aC�pUp��c�s�v�oa��=SH���-�r�*�.�J���=@Q͉*�/%�j���������C� ��;^��������I�j ��u�0	J��h�'.%%�X~��e�������SNx�b淚3W��'��C8@*fȨV��7u�O�0��>;Jө�66���������Q�������� $�,_���vaֽ7�?��l�;�X{O� n�vv����xWk�@���m�V�����>�2�Z� ��ٶC��)�"�¥;���:���YD�G;��m��\5�&:M2n�%s��Ӫ�b�����"��ǆ����d;�� ������~���n���$xKT�	 f�j�rK���\:��/�B��LjY<	��q0�)�`t�ߴ��69��s��
I�4��
��HN��W��GE�AlĊ�&�M()� �����l�D��݉BzBr���ʋ�|�ȳk�)1͕�c����Tm����kT�՟*����@��Oe��E�9�>�� M\���8?�s�P�cNn-��ˤ"�>�u:5>3�(���T��LAΥ)��جɞ��K:��՘�I���õ�M���C����ƣo�?���[�����cN�?F���!���|���X���z��#a��ww����7���c�u���=|��F �>{~ao��}���}M8��w�՚M������ʶU/G�ٷԤ���7JM���%)����ݝ��c�m>ΑRx$��u����wv-T�q��ꇷ��{�=k��YS�h`� �G��~a��P����ׇ7�N*Kg'1�o�I���|^>ҷ�o9H_Y0�r���-����o9H�r��� }�A����-�[ҷ�o9H�r��� �}� M7�oƛ���f�k� M�]�9:��\տ��K�q����(�(T ��p�W9�8���<o]Eg-�/�_���u��Z��o�:�2u�e�����q�3n��#����hA�s#Ip�D�-�@Q%�O���p�QM���1�l��sl6J�c�NR�?�����;�8��� ��n�VW>چ�M����8wz]@>��:��������"F��a�^�C�x�ߤ�Ҝq�h�� �\؎��Ø`۳�LBZ�;B��O�o��U(�����y�L���%+��"i�D]�%#�KF��cJF���IF�-�].��.Ʌu�T$���S���Cw)i�X�S���/ME$֑R�me������r�=�x�B� o(������o���g�H�����Â�ޖѼ+�\��MY��#�J�0���V�-���k<7X���z�?כ�f�[���<��K3_���$`I�V��
Ұt[��7�4A������_o��m7�{hM���r�`���t���!*.��~~��%�w�j��wS՚_��E�[�y�� LL5�o��\�hR�s���Z-ͳrvL��n!���V����V�T_�Du���"y�f�S�~��8u�y^�E���yyQ���̦)Ƽ�ChFʒ`���#�asɺF!�;Y͆
j�gl��g?r����fO�+�y6Vͬ�\ z��2�m?u�0Lg���h�,��<�B"��?�=6��v�D6��'���F�l�>�����J},���~������d}���ړu�����Ío����[������'��:��mzT+#��=�`�������s��ʾ	�c�n�2��z\��r�yUܺ�A��T��VJ���mo�r����Q�B��*������ޫ���룭��k�\��5�TM.��pzO�t4�Fl����]ǍW�}���Q�99�w�������a���Zk���˃�՟�/����������Ox�꧝�O۽n��r?`8�lv����?� ߡo<�b��O���/����_j���懰���}�3��^Pl>�����'�N i�(�B�:����l�Jo��x��ֵ���ܦ�Ґu��<����ŋ�9B��5kBCj��T��mE�3�
0H�v��������;M{{'���y�R$�~C�$�:�n�Q�Go��6/ ��8��ȹU4��m�J���ln�����n�ۓ��h<�@�������cw�,��S*��1M�Ǘ�@Z�-�牢/��.h�v��.�v~��rv���B���8�gƚ���@�[�ׅ���P�?��B;C��Bk������tz�����_�?ك�4��Yּ^�5���m?R�W!�����k;����t��:�\ЙF~�E �p"�fDQ}�ӝ����Z� wЬ`j-m^����XjR�}���A8�Eǈ�g6x���k�8��X/a��gI� ��ߍ�d��-��f8��g(Y
�Hv�=z��7�-^��>x�F3x��"�����c�wՆX�h=~[t�J��V�ƺ�����P?��N=z�t��Λ����}��~/B�z��~��3
У(�V�&��T���h�K���e��܆a���N�	զ��|�&�~E�~��\��.U!�<R�	��={:�^K{�A���Mn��2�>[y�D��<���E�������04��.?���V��E����؃��r� Fr�l����Ix��A *K�F=�^�Ŗ:E���zOGWDD�@.`�m���,�βD���tfQ8P���a���y��&huh'i&�~��3R��z�٤i�)k7�YiO�^]S/u�7�ó&^F	�ٔ�ujl7�^������9盛�^o��[�+vw�=4�����j�R�T:)Br6Pկ�?���̼l)!�#�A`����G���#�8�KN{i	m����mx�?�?�퓇O津������#���V�����e���:jͷ\(E�A|�h�[Ʈ!�7���ܶ=�����loM!~{���7�v�,{U��ZE��[̮z{U� _�k�J�}���^�a6��Q�3"s�v�����7��3>��D��+��W�����nQ������6��v�6���V���Y|6�p��m)���3I8���%h[�� ��xԷǁ�3l7�b:!2BW��z��OJ��~q$u��\��K�S��*�P'� <�$CŪV��߽+<�$��4�f�9��7W�Ŭ�s�l�[���M�ys3)�w1��ϫ�Q���r�Vͻu���}�2�2�lF������t�V]R�V��h@�w���U#���ʋI4�k�4%�l�=��1�v�����4N��Ե�*�,ꚰ��z;��/^%���I���lλ����b���y��&��M��J]��u������ϙ3	�������f]3)�5���ܲ� 1�h&@�i�G�	��o܉��wٴl:!W�h�"?���9⡚+!_x��]]�K_/�����x���r:���9����H{����ǺR�.	��沮����n+�:/��s���3��Q[�V���(R�	m��r3:!�ǥ�:>>T�g�L�i������7��X}%%9�lR�.����]nn���[^*�n�<�sNk+U؋`>�	��Zq����f�Y�k�G��I�N���=-A�牓,�����k4���
r�� ږ��1�V����j�;�I�L�w�ڐ{7��]��)�w�Ó�=�Χ��T��B綟�.���Y��._�W��X���%.�A��dq2���5������	����cM�*�;��|R��S[Y�5����+�Vlh�V�8m��Cp]'��g�<T[N���W#��v�wf��a�t[���xǄP&(8-��H����8�HF��Pl�X?&|��>��iv�J�j���G�E��(<������(g`� ������&����w��'�د�LBE}������������ø���Q~��~P���:i�^]@Dr5]����vG���v�� ��_��r�w��ݮBTM�I�r����s���� ���9���X�#t!���]��S��++p6��}U��o2������JqQ��xg&��0�`�ɚ@༴0�_���_��o���t���gQrb��VЫ$��hj��w8��(9��31Z_�y��f�|�E�A-\�=�t���pK�>¤X\x��
p�k�=2�"�>ґ��[5_Z��7�f��@��O�,L�b��y�W�N��Ϳ�5�X����B�x>)����ˤ8�{9V�����O�c9!׃��/�G�U�%*(�˂�����@����$���ОG�
��3 SK��T��!U�P��-[���7����Uj�u��`c4�X}���ϛ �\ۗ|�l_�^�e�\4����/oN����y���&9ͽ�w��	h-�</���f�����ݬ�����[|C?oއ������g7Ş��{�y^~�׀�+��]�;Y�;%	�꽊���
�g��V4�+�KM�y�G��*����9�ו���ܥ":q�3������T��Dǁ�.���'h�QZ��� ���h]{�� l[�4l�,.fv?Ε%Ԫ+���ُt_�u��ദ�I&�^�0Q% ��Y�*<��o�-\�1�"�`q2cr%Q��X�<H���/�*�2�q�sDn|>k�-Z=��rea�0��4��k���-"����J�R���p��'�Z���*�y"d�_5�`4	f��FY*/Ju�$,�N�nd�V���%���-�NE�jgw�cj$S{��
��ҭ�j�A�����ߧZ�����*+����y0V�!��O��`�+�w��P>�_�M2NX�a���Z̃���?+iRE� ~j���$A���مX������%�O��
�P=Q���qb��K���^{ʷ$=�����ӯ5�����ژ�A8�/l�3Hy��_w�HE��Qs��F�<�pmD���$Rt|�dBz!L��S�3���|� �� S�����Sx�nF����ir��ي?�{�%�%�;�r���j�s�@�\5�{+�̱j��Rp�%)����yC��0�Y1�ǈ).�O@�V�)�*�90�R����ˁ��,��������$�;�w
$�#���XA#��X����`��Mjs�54c����7��VxM��f��^�Xтe�Xɞ#��l�ΤhCڵ� �q3��#�~g)��*l�Y��]?=E�t�X�o
��k��@§%-vj�-y+RbM�-�I�iB-^��e�d����!��Xv4"xx�*�|.F�(q�������oy�
+�6v�n 	#ЧY���a�b����G���uE��A�����/��N���X����OX�S�\���� j�h��7��g4��dk�7�h�G�*�������:�9)X��`��tێ����xc2�����͹ލ�g8P�N kb.�b�P͏�<��gX}�|��1��	mQ�ѕɳ�+��Nc,�3��|�W�4�2�Q�A��T�~������|�Λ�6F-��D+���)��p�Ve��N�`~c�^�,<��M��W���EŘ,u�&n� �L�e�תf�mP7+��k�\� ���:f��R��ˡ,a�b���*�c�����/����~�H����:��;r�a���f1���%'��cl���*l��5fxÜ<�a������j�˜��fp��y�&j�f�mM�������^�%^Ō@!�\��Q��={y:��2�^Bs�$��B_6���|���_5$.\�~�rGW���+�̿h�?����AKK9,Ƒ"�.�+!s�zS<���G:H�Y=ڭ���KRy�sn��w�`S��Ht��S�h{��n�f�\{�_Ec��+$��<Ie��G���ȹj@�TTY�0�"+a^�rKO���W���=B�(�wȨ�A���{���Pڎ��B~<��.JC}P��w�4����Ŋ�(IH�ϕ���2KA�^�2���p�������j�JC8>�>�q�^�.`��#�JÙ��l|)$��#o��0-��1S���-�T1��xV?�G��^�#�㽂i���,�B��Ny	��^���H�z���%��5i�5&����	nA2ʜ���ǛMs�? �'"'�K�ǄB���:U�+._t��P��妣��AV^9G)�'v�p��XN6o�3Eݍ�JP��AՍ[� � 3W���X���h����P�����}4�*��0�vk���wx�r/��s�g1�|az����d�x�:����<x��Ȝ�>#���κ��v��{u��m���$�,i�aKʒ:/�d�%�<r^�BK^xlR����%�=�~��9)ξ#����ϻ'��ԥ �������H��xi�P[\l�eSK���G���W��a�7�s��-t)�2�ֵ+іi�B�2��U?�VKW����Mf^�Y!j�Ok.�[3<����}���)f����]XH�ߑ����KO������i.{'��lZ�Mk�>Ɔ��[c� Xē������.��HԄ�ۇ�5�Y����g��
\�5P�޶"��^03��V�ߗ��*c�f�����Ħ��?�"��,EP��E8�o�I�����6m�"�]�cxk� WyY;K��htī@����P%����Qd/��b!�ޮ�7qy�i��o�����+�g�\G��1�������b?1���;G�t�����r
?�XE�N�j��@=�7x����w���g����K/΍�l6oE�+�x��,z
?|��az�ߨZ?���x7��^$	_
ݖ����Y+s��"�W�o���J���n���Fm��m���{�7�\��Y��t��?�M7� ��M룿��~�c�c�������XEٺ�x5n����R!9�(|�*�0�xꆵo^p -�r�m�$;��s�KS��lL��6<���".e>���M����)xU�ڄ�P���s]�K���n��҆4�P�_�&���o�k��c���x�!iM?L����m�����JvK���nL�]���S*7�����a�1<��x>���6/����=��8�HW�GS����+1���k���6�J{9��ܒW��L����K�l���{Ki����X|�'ߗ���\_{����?z�;��k?�������������_�X�'������G������'���->�����k�cw�{��U��_ z(A���9|�H��Æ�����,��lv�81����Zݪ�C�2�"�K��K�^$�&�@��-��T���V�����{eW�?�s��zO����)�+��x�F|�I	���88�84N_�7G|���!h(hϙ�8���p4J/�f�yӥ�a�c�p��1�?�j��:R��S�M�u��V�0��xQ�"��(��b�T(�Y���%t�H�>o�N�\�+�{���N��O��$:���÷�B6,�^�W|O
�V�z�!q(	v<�^\�y��6�����4J�Og�0�{T�1(�����J��j�Y���ijk�(�ѕ�\$pvqeZ�f9@����"�ԛqDm�`Nf�S�����?ű���-��
�
�+�\>L�H&Lĥ?���t�0��t��T	C(�Z2�����	o1�2�(��=W����?��2�����1���/{��,��7� �W����-=�V�����uuP�9�| K�S�����?@�\	 �e�����Վ0�Q��~:�(s �J[th���2Ĭ��*�q��t��n���<:���#�q����n���4���`k>�)�:��2�7"{9�F�N����3�l���N�a�8�0/?��$c�����V-���)n<6�M	�Q6)+���i<��1_ ��*w�]�����Qr����p�."��9�ʼ���?����.A>��KwΩ_gx���n5�d�c,��'j�r�$�L �i�3�kte\y	�r�P�1]C����2X	p:�.fP�9�a� 
�\�4ī��	��5��:���4 !JLhw�Ћ���)^C>�7������ӳ)�潸8��"f�n�áD0~!a�����F��9�xa�w\��� ��u��ҳ�ϖ&y��t���4a�}���?�ǅ�=�;�E̞�xf�K�h�uiqǧ�~L����t�����?gq�z���pˀN#@��=�iR����Ê�>�0ƭ �#�L�T�f@.�$Jg9L9���A?��h�zt�$�ү��H-x^*�S1Kx(���|d�$(O�p��x@��,���g����C�d�P�<%*�<y&�O���0'�zH#��&�N8|��23-S��2� �MbI�)��ߟe�Σ�@�ŤK�Y4�	Px0v�ko!1����=A
�G0�K�+�����\��MW>i��������53d���̧�@"�.��X$�����CmQ�
��A�0��|v����UYB.�����*�h�)�Q"�`r�=�Ĕ�^�� �p��k�#�co`4"�*ͭ��;Ut����P
�l�bN��9��2#MeD2�A�	��t�GT7EI�����i�O5)!+Ξ�ahe?.f��Ls��t�r���OH��B�)�g:�h^�1'=�,�"iƍ��Xԣb��L���"hu����#Z��"P5�Z")�$��e�F��N��Y��:R��Ӱq,FS$�#у�s���|9A�á�R�E臹�wc�.t�=����6^��s�s����k-,S'�#�_;vxL��S�_}��s4W
g@F�������k���p|)t�Ej��׭�lBZ �q��4C�P���w�-�;l��M�d�&Y_t4�N٥8���Й4a�p0�-�9�,��j�B��hKjV���Ȯ\�]9L$���5f� ��&UDs�HW�ᄎ~����N��S�0�Ϲ�2L$�V���ACV��02;!��$ ��R�P���߱.ι6���ab5S��A��*�鯚v4Ԩc�-FG��)��6��&K�2`8]��S6�O����g��x��3
�(��Є����)W�Hgp̝ջ$H�ed�c��8�Q�|�ku�8�nP]A8�O}ja�����t�4�<���H*#��(��\׃��P扈 �4fh�H�ёU�,��i*����'�a2�Ex&t�Y@ģ�N�)@�n�]�O/X��#s�Ff'`�.�"��9�3/R��ц(a��E��]@�J4P�R`�HfH`�B.�Õ��/"�CY*��:��4�5�����C���0m����1��p6��\D�= 	-�u1�ht&�_p�vI^�OQ��k��D$0決+�r�I�9* �|b�(C��k��(E�_���\a���P�F���I���*-ꅒ�
�
n���b�I��E�4�͉X��k	�f+<RRـapo�1Z�38x[���``��h�X%$N;=!�lyM���5X����A;��4�"Rb�0f�k01�[J�Z[�zj�_s�њ��.9b� �BX��˹t��[|,��������Qpo��R�C=��CQ5�jG/�}�YH>�L�c����0v�NrQ2�R?g��0�I�ʖ��z��KI����MG��~ËDǾ?���6�e��7����������X�)��z;N�(����Q��@��,D�Vc�(TيrF���J��@�IG�J�jXg�+�=Ћ��� ]��:��1���E�r�&�,n�%�JV$��y�4�3~ZWT{1,k1a�X�DX�R�x���L��*#m$
�VxR^b(�
�kB�u@�MP+��&h�G.�N?Lu��6EY�3���R����h�$>`#�c^O���1��]Bb��8�`��ȑy�L�}� �>o�\��ǣ(�j����h����c˧��Ծ�0�͆0t˻��	�GNb&!�,�hc�B�Kk7��B�g��s%2]��!4�3�ɦ��d��O�	�rB�c@��t$*��`�_����6L�Dt}�4��yP<���E%s��,��p,"�{B�5�f��9B'�*�.&��C�Sؗ�cɣm,�U���FO�J����}��>�����X�e٥�i�p�'i lL���tWI8�>�@�=;5Kc��km@ZP�
&f�F��)zS�P���J8��1�%Z�%u�Qa���S�0��1�/Z(5b���R��l�wqȈ�ڔ��dP�"[aޭs$�X�o����[<����g� �e��l��u�2�����bl>#/ޠB�"��?k!m�mJ��Cm�'{0J�0����-�1^�uh8�*yM�IR��\��ԀF2�ϒQ<��o�ִ����r
J��+�8!f�:$)�����_�r�Cj�3���D���q,�Φ"�[����N�KP��"�Y��DCP�c�i��I���"1�풞^�:!m0�?@L�iF4Vj�a9Pmї�µ�g]3���G���y����,�6@�I�ш�^�<5�3�1�=P�0�2��>t@�I��eY�(F���r�E]V�]�H�2jא��%�b8r0U��'�] ��E%�J8iE��.H����3��(�D���n�s��;�¦2UvM�I�[	8�A��y86�|�#�A��bCġ4� ���4���|d���62��?�L#؉�h��Ĩn-��y<ao�n�uc����?��^��J��F��cq����J�H\�]"!ދy�6b'�kd��Qv�%�%	i�[HG���5�=X)?����ܪ�ECF;0Bݕ㸟z���P�*䁬;0l%&mb���'�(=Cf�eHnL�F�Q���F�ͩ`F
>��!�Q!l}]���;�ᘢq`@���ލ5��@U����'x��/�Td��(�QUL�dI��A|=z��x�FT�����c*Ou�}��i�Q ���C��xk�t�7���Ὂ: /<T[�~L#$��=Oy�(�Bq��G�AÙP�TX12�8�T��]5��B�ɱ
g�ԕ�H �(|�".�&>��S����ޗŔ���,mZP���{�Zι}�㳶ؠ�r ��B�������'�0s	��C@�b��%����t�O@�g�,����5H�s����g����4��E�1�r��
&.�#�B�?�U�-�\��@���O�Y��uj0*@�/<͵1�26��4�3:<��9��60h�jkv�n6��{��5RT�Z�Ffd���$}�'�	��#sԆB<`cBh�]d�Ӳ�H�o\G{�\KIPi�h3:w,�����^�Q��ZM"���zkUa���"q�І�.#�d]X'ᕭ~����`W���)M�,������v�!VXI�����y�%qV���	>.����me���ZT��lG26z�?�B�7!����L�_�1BZ�%�/3��c�s<����і�PVd5�E��Q�#	B�#+ ���J`�p�c��j��1��LH��ԃF�Q�$���цl�Y�Fw��61qR6)R@��� aA9���u0w-���N�W⳷F�T.8ϱ��Q�Faa%��:�K�����!�1f��j��"z5v�##(s/Oqmľ�1�bO2!c���.�%7���y6��Y)>$�s����`hd_�b���+'^8�E�vN�{|3��(�'�&"�ɋ;���>�)Y���T�uX��g����7PaDe]��h��T#��ܑZp\�IP����o��%�ʦ�㥶,_Fh*�f�d9*�	Ni	�}	ON# 	�$�.������"����T���#/=�O���4�!�:G�+=Xߧ�4 '.O�aE��K؜9��7�T�dbX�e��<�:�1L��&Bͫ��:+�4�OId+��n��
�t@�nC�9�ίr��%̋��Z��ӢG���Ɠ0��]��D��/���J����g:dFɆ=@8K6Z��y���M�2Q�POX
l(��,�M��$i1u��n�&�9��&'̭2��q�L6,�Q�L�	t�C�L�Ņu��ᮔx2) �7�Ӌ�����1 #9j��Q�<Z��CC{HIr.>N9@�Fp��4��v��>Q�r}"�X��	�0$ن��z��Q�u�{ 	;�TT+�	>;���.ݭ��g���(�b���+Å#e���\��P���aN����RG8�uT����n{�𙇚�c�H�	�8��S+�9�����q�=��g���	KG�TZ-���~�Y���Vjg�n�hT�q��	]���9a A�2�260�2r�(^��M�;��2w��HD�� }R��p�1���q��א�#گ�e���;\vk͹��hD<����H �c�v�/+�"ŬuQ���c����(�Y�!A�Pk*C�.ù���;t\5�$#��9�|��98Zm�d!h�	c�Z��%�aX��[���m�=m2�S�=53�N�(kN�&���_&�O�0����	��QP	�]�'��"�P�/�FLm��0d��[�c$������*�q@#����tR�f�X<08ac/�>bx8<�;PAspO�#{�{SJ��	CBc<�a�Ck4�CS�`>��AM��c"��)�Ҭa[H�F�,����`���Wuc��8nӈ�S��/�Un9���71��@R��ê�l�N(}�Q�6�J��JG�M24�C,a�d� ��N�3�Y,�^ؚtt��</R
[$�#<��6n��n��b��+T{��-�WL�&$+�E�e�Q��N�G�`��~��m(t�xt@BJ��7�����Q�EЈ�����)J3�(;F1�r�#כ�� ���X� ��`��4/_�&�pg	�&Y �@�H�&�Ȩ�f�H�
�P$����C�����A�s"�0�t�77�� ��u��GW��L�b[܁��DF��*Ҷ����)P����|�Dy�C�P��0T1*�q6N�d��@.w�����
4�ĄԔC%U�� ��x^�C��ӈ�|�d���C	�zN��D*]S�&���aw��s�r��M�j���66ȑ�9st3��dvꮜ�(#C�:j�~H�v�Z$���qF����I4���+#��AS��j�y�aN���$�W	8��J�����zQɔx�zo����w�0&$עm,=d�	�<fl��I�`GĊ���N!��ܳU�II�f��[q
�3�f�15 ���;���&l���G͛z9B/
 �)s�i�eG
G��#Bh�́c#��Cg���3�%�WA���<��e@�Q(�N �� "���y���PH����Rhw� iY��Pĭ��[�1S���"NG��G��I�1��L��8fl���~��HB4��
s�YK�d�s�����3��ecaY΁.�+G�?�
1����b���Ի��H�\AS 
���,A�9�3��Ħ��j}�²��/si�j�yj��En���K�̛:�qV�q8��� )�0�8�'�4۳.�VP=�9���t��Ĵ���H�3�In6��fN�q��]C��ar���Ķ�R�F��+���[G��1��o+��T�@�?)��6��*VAW*9C����Rx�1�Ӯ��܀6VU���4B���(�ܛC��M�,�J��92��S��- ���,���V3�+���R��'5+X���,Dz����@&�`��NQl��X�"�1�>)?�܇���{+�>lo�5�m�L����|�߁��� 8�c���4�HY"8[fdǄeD���h�����S����c[�H�����B����Z�06)ά5� �\�?&b���8��(cj'đI7%�%�0�˦�8�gv���v��r��ԻVl�a�m�%o+�����ҳ{%����xjG߯��71o�)F��x0��Y�����f�ΩQ��#��آb�sV���r�zh�0<�Д_�S�asd���L�!1�č�6��N�{�j]�;att=`�QT�0�/&:[�
Qu(38=�c���c�5l��h��\�$H��~�.���{�xauv&N�eb�Ջ��x uν�U�e[�F������Y�.�X�6Ǒ���P�ur���!C�pM�1H)E����T.��`*Wb+F��F��wH�jb�L((�78w9�h?�>"yk욹���]�Gs��C�Y�	�@T�%9Z͋yYY�g�*&b	����6 ��3�MJ����P9 I��@ ��l�2��x1Ѯ����*�b�ҟ��w�i��y�gߨ5�mÞ���]H�μ�6
.���A/�h���B��� 67��A!#��bT(!�_C���N���z��QA���	�F�����OTCT�.�a�r�<i�kd<~-�%�i�6 DQׯ!�;0�Z���	�#ܸ�G3#�Ta�$��ƀ�0a�`R9��j��:�kq��V�Mo��<�'����F�r~��T&yU�tj�s���"%n
0S�"���a+��&��Zg��+'(��w��J��])"NE�S3������( *��}��z`�Pv(�e�j���*�H/�*C.�c�O챹���!�h��*�!h�t�� �g�m�rP͠q��0dW���0�dMH�Ne'(à��)����t�E�Et�T��~�fG�3�`�\��1�	|O�4G���anBk �\����,�֭�k��3q0Z�f}��H�gbg�,}�_Kg�7���=��b搡�W*r�4Ez�Y
�a:���lʧ����iL��"g�H����jNڛ�O��H/MM��=�+Ъ��e��e�fp���"��D�r�G��P^qF[!]B�N���]�#J8\E&e�yI6����n��m���CɚO"�x!B��1�L�%�����7�7ء��Y%'���z��� d��|"���*�1�4�H2�Ys�;���-9[�b�Jrh�35v8����`ڐ� �+�a�5(�{.7$�()w4�&"Lo����X�M��KT��P�9�V�W�㮚N厀[�/�2ѐD܆���,�^��|Ʈ�����ςT'�XdӞ8/3���\_Q#C�5�:����'������z��ω��TM.x��b�+�|Kur�-���E���Q�1��3���ѷy�5��Ǭ��U������h�E.w�H��-v�G�`p�i�q;xD-=���kag��}��8�,J6Ð�� �V��Y⬸e�g�����%Y�ż���:w
]�	ř��;�O��%�ϰ�h8Đ���,�6R�
*מ7I34��BJ>�|�{�'H{�!D)�����Yz��S�:!t��e�RǼ�JW��
�)���{x���Xjr$�?E��wr�`J�M%�>;�J|�������4�+Yᨙ��l�r��H��)�I�^nQ8��>IV��zK겖��\�V�4�����Ȉg�Xt)'�B�/0i�0�W-��V�46f<���Ynk�D� Ä��ڔ�39$^K[�]v�R!}��x��S���:�6hi��Mþ9�;�HY��O�S`�<r:;N7s	��&%<(�L��A�BΑ�XqQZeD Ԟi���!��
�%}��Rz+����W��-�Ґ�LG5[��Vh��E�c�4�1^46�����z�r5�g��;�!,$��)?�U�� �j���9���~	�� 
����,�K9��N����-��U)�$ܻL|b�!Kgb�7*��Y�j�$�H$W�<@�H�S�~��l��2HE}i�*����vK��USv.ѐK��T)��pQr"']�0�?�pkOֹ�m���f
��;H�,]��Rs�c��̶4/�n2;���r*��XFFMY�#����P9Kmnp�+0�"~1� S+��cܤ΋,MIR:�=tL��I!��0i�2��N[C05U4�:��:Al�\ahs���ҹTEg�+�
e�Rd�N����pw�0�r��C�CåH�(R9����֥����6�Ȧ`��?�E.4���<���"c�&�j)���,%�6�<�_�������������QX�P��9��p���h  �ɹ�J���8��l�����Y�Y,6�4��+���u����f��Tpd��0�t�u-h!�p��:S�:����ntp���ZU@�h�����5c�#0�����jJ%m:���x���6���|�8��^�`����6�D`���a��,&��fW5�B���~:.��s��82�a*��E��e�����X2��N!<�H/6�G����|���x�ĒC«U��1Y�4N@'�R|����NQ�� R��Hv2}І���Wc�sJ�CAz�RHim_�"�W�/d�P����e��.inH�5�2%�v���І��%��S$�T��L�L<��� Z	�Y����J��y�K���:3tB�8(őC<�AU�戚�#X��iڹ��䝭8��H��Ed#pMAPK��X��eh�熵�o�A��ޙ���c]Z�1��L*&�͌�O�i'T�d���S�M��:3�WW\S��C���Icvw=�z�R�j}��ŭz�#����ߧ���X�o�zl�H�2���C*g7��0��p�G;غ�(6|�}����r�]��v���n�_c��nˊ�|m�&4>��S)o�S��x<MC}OG�*sy&]"Eg�����n_�R�˻� �aF�O��"Mqiɀg}�:���BY4z,���8�L
��x�3o�;,?(�bJ��\WǶ@�lt͏@2]x�dTpr43<���c���1�����Ft[)���.����@Y,�����%2J�	͍��'$>��Z���W�N�2Z`�r�Z�n���S�L�x7H߫@A�:&��DdW�c����f����!�������b�F�2*8��u��qήb|y�RG�0��M�޽T0��2ͻ��#[� Y&��-�0�cz��n,�s��8�Ka�=88?������B�$�b��+Q���E�����f����΄�0��L�����4z��peT�f0u��"�aaA���r��Ҡ	!�����Z����Y� �����H5��)�ap$5��Ϝ+wD��Uz��!_Q��k(��&�xS�32;�J���jQo>
���y��ٟ�����9x�Y�;���|���T3�&�U�E��g� ����x~}?c���;U�2�!��^�;^����:��FviC��e&��z&67Z2�ltn���;�CI��
q	��% :��p!ɀ��Q'hZ�ˈҋ��L��Lh8��[	g��{�U;=���v��:��?��G��:<:���P��������cu�=��9>�n�?���ݝ�΋ݮ��ś��}�{x�޾���v��U�����������H �:����q��`w�{D7T��wzQv��w�=Ǜ��;&U��`�5�v�����c3���% �I�yg���;���G�^ �w�`�]�qgk��6���^ ���c��3�f�� {��:��u��^��΋��X/�V����>tAk��o������zݖ�% ��G;�?+��,쿽�@�� c/�Ǿ�9�M8]���kd0��moQp��j����u������M��^Wֻw@�����n�x;G?�^������Q���s���upt�P����8��8<vu�2S�}Ġ�ď����G�{sE,Q>� �ΏG]Zh'��;00�=���A��1~;P{�;/q[q���t���:[��8��y١��p�p߶;{��=3��@.�n��awk���vy��{0W�Zx @T�! r�>��  �kā��;�U�w)��A10��w��}���G�}X(:c����Gpް��齆��ϻ��#�s��CFx��������x��,!�$tv�[�� 7_���^ɶ)�(��^�V��B����:��rG�fGd��o��"x%���^)I�e^�虌l8�نߛ"iko�c�g�b�N^����,TxJ�R"�H]�t�%\X�gU ����c9��(�LPLl�@w$�ڴN�t���T8�����x䌽�f��`6������B�tg�����]ZܾXֵ�xI�<�B�y��:uh�8��X����,o�U@�x��^�.��:�A������s�ܩ�_fy!��!��|�5�0p�,�&T�b�4��fq���D�(�'�_īoV5�%��K�(F��Aա���S���cw���C��ؼ=֍A��l
"r�����ܻ3 �K��NUC�(1A"r=(�޺��?5#��PY�����Ա}AW��LmW��eSA�p9�}]�͙���҉�iGC����8��[ϥ*���V����N�z �N�{���}�:l���Ms߸���T��r༡j��B)9�=�B~����ƔL6��ӏV�t�zY�iU/�������:I��q��a;�*-�Z\C�E��&�+h,m��ĊӮ��,�<�KY���&���څ�j�����Md�Y7�ԕsj�ٵdu�#"���t:�l�///[gɬ�fgm��~�`�&ݸ�M���N����T��|Y�`�(�+$�`�
��e�W�(�klih*�/[	q=�i g��q�IQ60��R�F.v����5��������'���\��ִ�w���������<�=��T�+@����/�,��y���hy4�~�0�o����$EK�S���}w ��hY:�����܅��B��Gc0o�����Lg� �{�RCD�c��L�u0�-�JZ�}*����;���\�@���A�@`�8M?�Lܤ�bM1Ԓz��\�W� �j{���/��Ӆ�-�n��^X�+�it�2^ͺ�MYw��b��xi|���ᛝ�k%YB��U�Í7o�!�R�.�4��Ñnn�0 ��p尉��Z��;�]1@,Kяɵ^W�l�e)��(-�g�,①!��m��*��R���ڞ���R�"\Jx^ݭ�VpAv1,�g��(�(Txk��e�`�0�caM�VL�c����U����	���MF���x���� ����nk<�J}���=y�H��?yL��m�w�<�x��{��p���������jm�!<��Z�J��>3d)0�<���f���y2����^o��oQp��=PC"������v~�&�����Zʥ�d
�.I�2�-��1I�I�\� &��	�0���wj'�%:�m�|�RP�����D���E`� uȰ�����Nv��ѐ�q�{�x:ӮS��t�X �cR�qƠ��#s���'�'s�΀�������4�P���n�@�O��N94))T	ݚ·0{˸���[g�[z{u��jP�gXV��!uΧ������Ĕ�R�(0�v7r&|�F�j.�7��$���t6�A���dY�6�d�ͤ�\8Ɋ�,音"�0-�v\� v��}�b@�dz��bN���y)��
���H-��}�^W�"�rs��X�U���9�DA%���+�q2����������Q����{���0q0�Q�ON#�1�0Ʀ�o�4��O�ЮڽiM��Կ+�`�^�ޖA�q� v��=PP��Ia�l��GǠϐ�MFlt�˒٥S���'�nkkard�,2��K��Y��bQ?�_0�������)�߿���j���ߓ� �~Q���z��m�;S��`cm����zs�����͍?l>��B����&�"̆��WW�O��Z�Rxc����j�1�����L�8�{�uW��:�����y~���T�p �v�{���>�E-����ؼ��3��2�����^�9�_�����}�ϯ�����y^i���Y���5F��,�/w1��+�w����e�
k�Bs��mMiZjY�0;��-V�t��c	�P8o�	з�q�\R�s���\40g"��h�woE�Zo-�b�]���rTwa�.�e'}�O�~�ڪO�P�@����B�{06���!ՃΗ-D����#5u&G<%����׫M?�k�z�8�Kz<��g���O�iy�1w�S���ݢ{6+�5?.=�U�i�l��W#]{�w}i�_c�?���g�'7U{:��x�(=C&^�L	�sJ����#V����q�g�k�>x ��k�K�Ks�"C3�6,#�ۃ� �~�V�8Ʊ�2����Ohܴ� �$�!(�����*:�J�����&��l���͏E���h���J	��H�ң����Csm����d}m��͵Ƿ�G�[k�5-��I﷐_澼�مtc<���p4��o��uX��2]�6�R����˪��Yq���������s@���.z�{�u�up���69qۀ�K��Ȳw/���=�M8}�������G�`����f|:<:�~�u<w�u���B��h+T{8�\�hm��[[k7�r��. ���S/γ�����_o���v��dc!����������/c�|���5$Ȱ�V�]��9ۭ�B3��s����6g\��f����eG��25��������np��_�X:ߛ��4F�8^X�n�"`�4<�,E���c���^D��'o믷�:����=>q!�.��@�<)��G��T���m�
=|7
I�$���R�	c��y�t;@�$�)��6�Z��WB xߦ��'}�h^�������{���,,P0�O���v��G<��h��4"���5p��Pl<���t�gY��*~�>ar���Yo�5��	&T��G|9�O�i>nI�����f���  �UP��_`��i� K�m&�	֒hჅ�x������0��OdO�8�7C}H?�"�|!��`���CU�M�;�V���?	%���~4Gؽ�C�b�`O~d�'o��ߔ\���0�P-js�;������:����Pl$v�������|�ͮk E�jꗧ��(E-�Cl���u��ۺ��jU��_���D��TպGGG��Ȍ��S��8���L���]9�g����Y���)�W>j"��v�:����~;�i;�Շ���>�|��ٯ�;_"�av���y:��A3�-�+e<��-��5�f�m�eH�	�*�b�~�d@A�|M��glH��Añ~)��UK�ɂ냖���M�D4�(7##F��r��c^�4��<p_zLeO�"����#C�E��::�=<�T$�,�jrx�F���S��uF�{���F�d�k�����4"�b��2v�ڥ��.��4w�g���r%�1�Q��|i�T*���˵�a�y�΋Xnn�M�
}�X�#m�ȸ
X���q�z��԰=o��%�fqoe3�c�Tqa��;�G�Ƽ'ts��s�jGa�N!�o�3!�7wM���\�{Z6�V��7\$hm�m(�w�"�8���|e���3أ^�@s,�g�{�.+,mO+>U�|R��l��a��Q��O��%�.D�h\��$�0�D\����v�9A�So���[믩�gNe�&$jWa��4R9Lz@h���T*4e|iN~}�w�;���!.����U��WٰRd@<PO��XU)P�a��'M����YYt�p긳3�{�Cu�RZ}�W�ǛP)e.�EA����Mm��4���1B"W����ȿ@�vVb�"�%<��\�ՎUq���!w3Gz�����Ow5F�1}��9��g�������^"訸�G��Z=�����d10��i4��O�gY���B/ڜe�E�\��܊�+w�e����� ��~<��"H5X�-�St��a~b�������!�/˫���X�V����@_zI����-��5�=�������UV^�����;u��=s��Qo43.���zND}T�����]%�S�ޮ7��]'rC��驙���]n���� S!~�8���*��Iڡ��K�v��X�D��\14�����݅h��\E�Vf��x�����&�Z� ��b�iɕw�e�2����?��F���N���eb�i�H,r�N��W=�hY��/��j����ƍ�����s�Ɨ�3K��+c�Ns��C0��m����I��(֕>P~���N�8���vl��1���n�����xO��Q�������p�L��N8ȼẻ4o�ԩv2C���. �Ν�n�~��N�����O�~PWp<�v�o����gu*�[��.�
��T*ǻ�;/	�1mc0m��?<�!r���]�"���;uB�*��L~_'�_X��>(������<�Jq弫�Ə����DU�P���t�S�h�r�������pO��Xm!|`ɾ�͠�Z��k�I?�l�uv�+�x�i��c�d�?������eB2UM=��*���Q�`||�(p���@��7NMtvt?�<��c�j��<���T5�6<��'m�+Y켒�s��%wD���f=����*(F�?�0}On	O��&�ȣʬT��t�j��Gp7r��dvga
��mu_�1T"����N����r��N���̓_>�`@�o�O^��V�4��Rp����i�+��q��w|r9hM?���m�s�Gǥ���'2}9��� ��ŀ�Mm9����q-qˁ�!o	Pc�[Lv�j夭�.�4�s�a�O��)���'�Y��ؚ��H8������n��ْ@���i#���d��=
��~��vqL�|���7^t{%�y�O�x��py�=|6�^w���hs��O��|+?g�Q�������x���f�[I�����K�*��2OBV.F��3��r{0v2������c�R��PH��Qպ�.����4���:��h��JA6��Z�O9�^RDh�C�F7e960砀��nSr���40�v3�.:�~�`��ώ�AϢ&>��A{<�⡆c�	�lΊ ��%w,ȹ�V�W������"N�B���I��<�ݹ�����-Cr�~u�����:WB�Z�B�_�.�En8�R����,_B�oJ�K^�2��r2�������_=���o���GC��i��C�3&��!������o]oGܿ���;�(�q��$�)�G}Ʊ�����ǲ��������ȢF�����g���kϋm � EY�Ȋ�M�c�@�V(Tua�F� w�D�'�ZQ�4y��㱰M2��_�"����Q?>�b'����d0�R�u4�E\�����!CM!�4�����(��WKi���ɯ�h��[�ڐ��m��6��gѯ?N�>�I�� ��fr"�e��yFr>]��r6���p	Qx��z�Ծ ����9Vx�����sv��!�N`��6\֯�X�y�g~��x��� eOI%O�ߒ�,���ǧ ��Ho"��� y�I^IЦ��p�R���3���K�@{����XRJPA����ɞ�x���l����Q��&��"�n��9����s�:������L�<�
��4�'�� )N�S��7!��c��4_z#�g	�6皟�[�MB��Ň�TS%�d�N�|c�����=�GKH�� = �J#F>@|�?��I�j���1W��nc���gسT�+۫M�ɕ��T"�:r�TKJ��Υ
�Eha%�:��4��i���ω����B�sٿ�'p�,����a\�/��ߩ�������0�)���6Z-D�f��u�b�"��-栩�jE�g��s��N��ϳ3(���N��NEZ��3�M]��>Y�균�36q�����x�H13yWxT:כJ3�L]+�-��s7k�<N������%M���l�}�q��E1T-��������[���U�Z*�RNc��A%��s�j׻�(OE�ζgڿL�!�9���y?��ܥRw��J|������ft��G���+z���m��_Ej+�1ayڞ��T�}PUo���w<[�}SU}_'��l�ڏ�.�P�c�}_3ݶ��:�u����ah;�[1]E��ٚ�P�p�4]�p춡Zm��m�v,�յ�o�T��٥ulæ��(Ѐn�Z�mZ�sC3��j��\�#��ԡ��Q=���j�[�w)��l7P<]m���5K�:��U�v�4MU����LϷU݃��V[�t� @'QG� �;�߶���8���4����ּN[������e˸@s� P��U|�3-ŀfôLW�Ͷ�x�{H�Vt��ڪc�0+�am30|�u\Gk[��i��j�m)R���]�SUUs� �1UXh�V���(���t��FG3��"{2WU]����Nб��@M��ܶx�����yX�&q��Y��|=�ڦbT1ں�imfȲ��}{���*z�yJ�z���nR�f�Q۲]�mSGU� 6�,(��f[�LǇ)65ˠ�\���q,U��r�u��ŤFbj��;]	T�tM�z��Z��* m	����L�2U`0&�vພ�XT�Mi����f���ɹ%�� �)� (�sl0�D�G]��6�Lǅͤ��i��J�͚@��\fV���V{_	L��l �����&�njmM1u8����0j�OC1۶G�vav�v�.��c&�Rz���U���t,�V�q�����Ý�5T۠��i�n�m���T�ermlA��Q�J85j��)���)�
Cjk����p�;E�)@A�fz���S[w:���Heu�O����[�\fR��'ª6[�S G������b�@�m�n��{Em�Z�)i$ 'a��A'L&5�DTT�k���׷5��=OSˡ*�ĝȞ���f�q��6�����V�v�8+TO^�Ղ��{�0���Nn��ZJȥ�i,��qU8��z�o��p�y�Mo �̀�t���	,ڱ<�� NT��]�q�󼶯:Ԝ3��	��;A�ȓ0�.��� �ؤ�3�ӑ�h&�}���rT��b����nV2\�p����SLj8Zǁs׆\��ڊ�)p�ajE�����5��H�ȸ:@��vGq�|͍���z� �k{uΩ�m���n��j�mx��Ĺ���HG'����l#m_���+�u
�f�>�Z�r-�(A�)ֵ7Z�[�� ���[�f���q._�=�"@�T��Ջ3�����xHt� �M��,_�������ݱ�R�����_Ԝ�2m�!��C���U�m� Xhñ`K������&[ �8@<L8���L`k��Y�;�[��T�{(��3~�c ���-ϴ��(�`�v�$�̄i��:Ƶ׈��:�^�T��6�09��сO� �G�G�JI ��,�p=v��:���� ��� ߢ {m���0��2����Λ�NM�aH��88� 0`m��ԇ�1��Wݤ^�06.0~���T �̻�������x���yK���*�/)!/t�m��o����P^��(��~3�1�c�������6��������` _����W�?�H���H����1I�ob�C����<�{��3���/�{ϠNϡ}�"�'�(�:�XD����*v'�~��>�K:A��ev�D�<m����MF|��4@kvN��4z�( ��������]9���qym����Q�4��h*zSm�@y�ºy0�`<O^�YJ	+gY7��ٞ���9#6��w�̂�����W�a�o,|0	����Z�����`��7��,u_c���tA1�^�#'�`2c(��,��m���R;�H��������c����s�|�g6��32�n�8�gf~��4�P^�"�bڐ]� 1�\�.]ţ�y�3�H/�C\zÚ�\�]l4y�Gɛw�p�,���ED��}IIBj���a�X�3�����N��{G��w��F�RI0��UpnNX�Y'�	{���9�����_�� �9c�)�Dͫ JJ���10����r���37J��zJ]˩���o�8C�lg#A5�a
G�ҪHf37 ��D�G�Z�y+�X��������өaEg]�ʎNr�z�6��1%�+�CN�+�\	=W>f��CF#��3��Yxv�&Q��%�B�K��-���W���R���^ڸ��WA�W��������_���XIZ��%�y2�Cf��N�^
G���5�`�,>%ˎ"G�g���]��$��\��(Q�,z�I��
�"�n�?v���ݖqfV�7i���(v>�|�y�}����8�\���������ޟn���"�pw�	k��W������.|�ئ/������nW�eE63��r��n��ȁW,�]f��R��ҲR��|`hɛ�ݬ˅9�O�ŷ( 'yWRKN�<d'�f��&q���n�d,�����u'��ī�Y��w��M��/B�Z����Ĭ� ��3 �'c\Q1zL/��d-�s~�&^*��t�
���o��F����ew���`Γ��R�'�?g�Q�Ld���`U�2��/5nB��?��rI"�~��5?њ��7O�y>�w�w�&ѩM�H�#EuE�}���yk4�	^��7��������G��rswog�I���=�\��jg�U��0�M�`����)��0s���Z��F��`+�}v&}Xq%��Xt����`���yp06��$�@������;��ѭ1�~���Q]WE�+P��!L�e@JP<�=I����K�8��N�o�������/׽F���`��w�J�M��XL���
�Tȝ[���=MJJt<�:(T ���P�|I�O疗
��D.+�|)�
u�qk��RH�gKAn���R�+��-!}����f̏��v�������/�d�Q��n4�	����~�q��oH�u3�3����.�'���qg��D؋��F��|ǻI�5�����+㙿i0輸w�h_=��G�ڤ�l:����`��~�O�J3�Q'~Ɍ!�� +1K�����0�O���9/���3�ô@wm]]��m�t�v��7ƴ���K�����s.�p»0�'iVĳ��Eq���̐��G �$e�/�Z�z:���,��;@kCk k*W��7>ϪӛUgf�Ru����P9��Ff�.���]���-���}���G�Ù3�H�5�8BsD��Ͽ��!�j�w��{�;��aw�|�#�B���Ư��_ޝE��uW��ռ�����6�T��b���n(���*Ru�[�"<|�������6x1
<���o�:�Z׋_������e�����M,��a-�E3ZOUF�3ˬ�;c��놕��BAE�l���\Iz�Ƚ��u#�R�H��x>���L0O��zi��37��L�i��C�>'�dmH��$�dPz�������N���;�k���M冕�mc�oH��b���a)���JR��-��E������ /g�+���QgwL�����z������5��L�6tK����R���o)�	��6n����)���"���K�X��U��)��~ڸ���vE�W�f��C7_C���դ9^���Ƃ�UQ��������?=�颴�x�OCю|���6�G��G~���j���eւ�:��j��T���A�3�������9�j��ͣ�O���ꪙ*��n��@9��}J����-�_�0�M3�w]����.�����������@��U�K�,+_�0�� ׸�9<�?ė��Ě���&L��Ď'�a�� ӊ��zu�D�t��~ɓ^[X�Һ���r�}�m�翡���*H�5���W�f|��C�_C���gT��V���i�nm,����ӓ�GouD�M�+�o��0 ��G˻tt���G�x\r�s��;���]�*�h����w�GŇA}�\N��@�C:"��ȕ9._	9�>�=�������_�-�io�}d�����#��C��?�p�$��o���Ya��6|�1pyED�E+X�r_O��ʌR�(UuK+���
InV.1�ʗ�\	�L�[r�e�b�2�[(��{��㖋i����כo���ܬ
X�3�x��|y{F�W��FDQ ~���F��"~MV� Y��֓��$eo���zW������됔,��}I�3>`�;|���H��f9��L���ш�yɥ�'������QagÎyID��AD�-:���Y�6SG��:|8?k$��p�|��h~�Q�O³��q0	���p�m����G��ů��m,��l]O�j�i!�gە��JR���X�9��������C����È��m�Ƙ�`
?����m;���}	�ӄ)�y�ć<�E�{�'���a�4��t�$/� ��;��|tF#�5�L��3�b���_� )�D'>@�"Wz�>.y����dv�c�y��i�)��ds4�=<"7<�B��x�����]������{5�I�����	<a)���'�� 4*���b8��ݑO?�}�>vtN���	��a��&�Jj-m����F�d����C���o"��+m>�������@+7 �h�?����
��e�q8.��Q���'l����B�p�wF·�3LښJ��w��æ�j_��~�K�|:��Gv'
������]��+��}�=��:��������wNw�~<�s�k�s�*��W���~lF�a��Ư^�~�q�t���Q�mH����I�^Rf&�(�,+6�<@�m �A����Ȃ#��B@\��0��N�i�����	���4��?8��7.z�՚l!���
q���ԭ���9����k���i����w�0G��o�_>��&�҈���R�_���ˏ�~��~�����}�����?�K����"��9=:��a�ӻ�o���Q���_���hg���������E�ś������V���_�?�i�K;T8��fh����J�����i�D�s �tE���K4`/�K�Um 3�_Y���Dy	t�Ea�����e&��y�.�SM��s���}���ˠ[�Ft1��|��!�$�ʋ}8�8H��ϟ2�z�|!���ZW�|ky�3�/�NT��g���ep����`����(�Nc��^Z����å7�X�9��,E�ې�o����O�`w�6������������[��V���?���ˠҝ�u��4�:WAXu����P���럸 J\�r>���O��o�^Ǽ�LG~��c����0<�}�2J���i�>1�@b�%��^��U �睅�M�0�>����N}D��_��$[�(�L\ܟq$nS��Ʉ~�I�2܃)��)������^�k��,���k�w&?q�@9q�#�rP(���xǀ$����D�h:B����V��I�~�r(������9�|>OvOs�+��F�nv�p�P1��"��׭|>���O�1^՚ZSm~�u��A�����o�ѭԣt�Q� ��K���0?�R?���r��������><%��a׀���U�v�P���몖n�w��+-��0���I�٭��|ʀ����_��<�).[1F�i�g8њ�u��i�j���ƣ))����\���SI���۹R��J�����H]
��Gw�};��`Q���E&��TBz����|�V�q����Ý�܇����Y�F�!4�R���n����[O~ˆ�P��#�ag���{����A^�=I~��i<I�&�������9j�)W��\��s�|��s��,��θNW��CJ�6~�6������`��V����T�r���ߜ���T����0��~?� �,˂/��+y��1!o��z���C�8{�g�f�g�Kg��2�27�	I�q�G�`q���j�ÖC]g��Aݦ]�L�17�Z`z
 �\�!VgS'�J�e���,b$c��.��A��3��u��%��r>�b�r�	C�쾚��!��x�a	��{����~��KT�M�!_*���e�-��r��./�����>{�U�δ{�=m��,Z�f;.Q�M�Ϫ�θ�/U�J��u��������#�`��ECL)��XT��0g�u��ąc2�35�*Ñ�����N������Ix�������&���fU��+I�/����CW�g�*R��U��G�Ϳ�b���R�F�q�蔨p�F����lɒ���u�U)�f���o���:�Qw� \h�m(�����������JRu��}.���;�a�� :�&C�� ٓ6S~�(pT��q�u�����?��B��38��'�1ə�&���3ě9�ƹ��Op~
u�\�sGW�qw�cuw��q�bK ������w7wݻ��f�\���=^t�����GD��tN8AXB&��7�������h��g�8L�}w�i�3ˈ�0}$�Eew\=�,w2@c���f�?M=���6��{������[�5����{5I���w�܆�����X?U;�b��8��v��d����H���+�v��b1�>��ؽ�sR��������9%��M�8�`�`� �P�Kl|y�ѵ�#�b�����X��p>�aɱ��07�9��x��@��J�L	�͕�J�hY��xT����\�p�`�Ů~y��U��37�h�:f~pp�t������=���f����\�����ě\�'MXR|���H�����P�(\�H}j��10k�'\׳�8	��y���=�ͺ��dbx z�8M&�tx�=^y��Y�O+��J�?U���Q��H�':\��������{���&��2�?����{���?,�7���.
`�?�/��h ���V�f�_�KY�B�"����������F���$U���p����	>��xG�a���t�v6�9���M��oCN�B?W�ă�%��2��D�����#$���p\�߈_m$R�����̭9T@a>�z��Z�7�K�?Z+�]	Z+-�@�1.:���*����vu�\�)�#Ry�
A�b�-dJ�!ɔz%S~�2e���t�����c+f�Kә�ê����J�[���`ߖ�w>
�$sB~C�s�b�֡C�P�p�P�aP�;�J��}�4��I*�H��x8�K`P�wr����?����~T�m 5	�A��O��60{�;�<S�}��L�܀M'����oP�4|��7?;�K�ѩCf}��DT�8��n�Q�e����@OG ��)i�?��%��n�<����<���Y�d�_s�Kw!���Ѐ: �$�پ�P������ �|Uh��,�l_��1��,�u�EIȰ��[Lj+���p$���_�2,�m��{$�#��%{�s��Jl���ាl!3���%�<B�F��ǽ��/dN��<t�՗;-�J2wI�+XDy$`�~�T����Fp{_������{0�A�%Y�+X�o�����f�|w5K���Q<��n��K��m�-Se���L���zQ��.O�,�H�����W�����J��!��W��՛��;z���j�����b�5���1��i����+DQm]�+�oiY�f������{1^���>�`�!���^��t��0~���T��b�9�]���Y��9�o��{К�5n�@�I�O����;O��|6�'��c����l�O�k���7w߰�Gk��H�	�W� ��� �B ����x�����N�D�^<��� �8�O�P�;�h�V��,�Eä�U�{�=����g���uc�Oԅ�x����+�[�? TO�Ck���\�/�~]+L�w���4��Ȋ����t����K�$�Q,-�3�p��O)x���t��5�4��T���^/!<����w/�N:��<����xJ�)�^-���j!������*�L��6W6?�je�֝��%qU_��^~�����q�6nb���*�����$U��ÿ������p��]�C�K�}��������7������T>%�;�E���fV���4+�)'��������,��
� �ի����J���s6�7 �0��3�A�Ck��p�
� �7�R	yW
y�J��
y%�(�4-�L0�bf������$�b*��4�s�^�}#�O�3��[��P���~�:�D���VN��CU�X�s���W ��3�R�k  ����E+JlE�-���!����~s�۵���*�<�B�_��j*����_I�L���#�?d�n� Y�������:��<b`�C����`V4�. �a��0�\�)���i%�3�3��)�n��eܜ5ϗ��f�>3�w\f�	s+�Q���1$��IN���Ù�,5��{�nf����&@�?@���m����s`�8�a�:Æ'����܆���	��C�H�� B�~��x81��:�p��xǕ�;�q�n���m���yAA
��NAd�͉�q���5�G���{S7���5�^�鐢W @{���1|�:9�R�Yp�� $�Nc@5�����[�`�9�?��2_�)�:lDtDE@M@�x�R��NRTGn�'b78�`���>�E�����ԚmCi��n�VSmͶb��?��O�u$��80��m!���؉x�N<N�N��4�
�|_����S��>����A/���N6l~g��D�;�� �Y}����v���?��/�Rh�1�X��������$,��eh�oc�U����_E���B��9���%�$p�5$����3��=2�����_���_�����_;�!�!��������ɕ��.�Y<�_�W��0��!^��6Gc��ȭ�d�p�1�w��t����mݤ͛!
�e�xAѥ46�;Á�pD��݋Q�|.o'7�m���X/x㉇��Z�]��ݶ��J]�$�� m�v Z�����;w<��BB8HK]	�N�б4?׷,�w�CK{�*��v�(����b�l���hL��3�h���<��8�
�p|�l�������'5���o"�������#aqHG\�H��	�����.�B9C.x\�@)4�L8={tԏO/Е����{�6)QZ?EÍ�l�!.�� �� 1��эz��}��a���:	��c8���JT�9 
L��(��g�{֐W	�C���lX}�a۶��m���ب�`L�U�Sh�1����y��t�E63�K7�G�Q*���[#���Uu+��d��&�������s�;�Ǻy?��#pI?��$�m�.tا���h��2��&L'_�1��Řn�`��y��#��}��.�pƦ0�/��5X�����|�{0xA�_ X`2'���t!J����c�t��F_�.�/�/�x���'�:x'��ø\�҃O����0F)�o1�奵���G����������j���*R��\n �?P�νdg���ƽR��nPw2�ⵍ�U)vް�̈�Dr���2�b��Y0�ͨ�_���MjI��Ga�;@�iU�5��o�yJ�[yu�|�r�p|���,g�RE�G9���׳A�7�G�Gۮ�?9�#�������v�y���(���~��9�r�8�]�G�0jP�v�)d����Y�D��+�������ﶀv� �v���b�
�`�����3f���ڪ����m��oڦY���HK���fV\@��p�8�����qNN\��83Ҝ˧��g�2�L>�/ �)QsE���v�.���_�YH�#��T��g�P��U�J��(E��;����<��_���f�YZ@�uEc�_-U�-���?�V*�_+I��������K^Vt�^��2!�,L�C�I>	f 9���y0�
\� �a����C�fv$��";4�BQ:��S҈���=�8C��[8q ��)��aߵ���֖:3�3����	{�tV7?��(�ں�n������i������7G�_g�8w��)�46E��N��Tpb���>���������0��#�})m,���T�7�2���jW�+I�&�?�  �W����� 3h%C���%��;9��_�4�I�<��T�L���'Y����Q�5�IL GЏ3/&.:p<�A6��y���#����!	mȺ�F}"Z��̇S�A���*t��S��gM���=�4��IG����P��|��X2�4d7k�s��=e���j��}��~H��첓�4����%�)�m�W|^�����)`Ya�"VG�Sǋ����ꋚ���e���M���#Vi1�p|s�a�J0��(t��~A��km�rć���ӑ]�x��9�8�h�)�|lr���f�I1��~$����Řv�ZCU]������~{�`C�;�;�]��L=���Z��Qw����5^8��E�G.~48��4�Q��+J����ߟ��i����������|ݙL�I�#�Y��_�LQ��E�l:�L'7���ET�<��/(O<�ջ:}��"�/�mf�����e����JR��#�#�p��^*���M�A�=+�z��c_�����eف˘N����PK6񂟧��5eVbK��LQ�Lx6����F�l�O�"�[uA�M`xF��Txل��qn��;��E��t�Q;MF���ԍ�"�M�TC;_bc��%m�8pN<mE����0ˤ�.eOƓq���<:�yd�L
�s"������sΝ��5(���1v)v���u��;�:����y�hw�H��AEF��!7'��������4K�	�B�3G֓��,����r�c��a�[8I��`¸�(u(��y�9e2���YOo��/�Q
-����(u-ue:�IgZ��L1���qKPō�b����*����.����������3�2藯�%�o�����o7���} d&��cY��M8[J4'��&�9e$k^�ɵ.�+B�Έm]y;qX\,T`"X�l��FpB	��83\F�p\y�p<��JI�Z���������� ��I4^b�E�9��نn����*�%闝7�v���Z;��N�_��r�I]����j���y�s���k���u|�{����;�����'����a�� �mtg�4��*�_*���(���`�ۦ��0lKa��P����T��y��!��[9�OF��s,�38{;���
���"�k���{��Ai��B/��g��P��19z�͜1���@�˼�G���(Fަ�v�����>�o7�o��.��B�堧v��O���t�����9�W������.|��/��[��Ν�g\Q �){(����6��\���[l� r�d�%�=--+��&�Y��ͺ\�S��b>&�px��DL�x�Nd�4�M����r3�Xbk����N_�W��tY��{�.oz{�E\D�J� v~b�� �g�.�b�+��hL/�&x�>K�s��&^*��t�n"��ּr�rJ��ⲻ�~m0
�hm��P�wF�EF���&%�:5���^6�'{���/5B���o���A��$�W	B�L�>�k~8�5^	w���#�𝿖:M
I�9�:d_�2�K_�Ѓ�د\)�B�� 7W
w�l)ȅRi��i٠
��J��Tڻ�4߄Yy %�)c+�}vܹ�^,:(-�+$M]J��Y돻k}������)��W�'x/�|�/��xJ��$�jo�����-2����o�LN5�k��'��M�pN��4��`����Ɠ4+�YeТ�(t��s�L��#���2���#�����u�f*W#�p2�U�7�N�[�>�����dP����v�M�烰�v>�!��qө�?�c��)�������S0j��p蚑�XJ5��B�@�RL\hn(��0C��P�'����v�\M�Μ�E�-?�}*�y�*s�G�{Qs'���q���y�`Ik����|��s,&�����-O�㛽�.��L����Ƣ�_ȝ��U���gi0Bo%��O`ͻ�L��@Y>W�_��U�k*��b��Ү��M�����������_I����_�������m�uQ��^�m�n���!�ILAX��������M�Ǟa-�'G��P!�W����e�1�����?����?�ju��"=f$�)�,�3B����|���mo���yz��K3�ɜ%��&ϔ�$����P�9�F-R(�N�w��vog�$�p7ߵ_{�n���͓흗��{G'+��3��5m��hA��W�*�_����@��9 ���-,@�R��"������߇��}���?{�4 ����+����������T���G��_y����-|���H�wdR� "��U8�Hg����z
�=�����G�Z߯ߏr�݃�k�t�ׂ~K saW��;X�D�ι�s��?�y��;I�!�u��������6A�9Q-�U�{�ߒ&w��3H�GV�_�tK�2�N8.V99��UiB9�'՗�\�y���R3p<8A���K�1���v���V����J�c�d�� O�Gx�殃�n/�r�a�WBO��C�b �
9�Q.�x��(I>�b9�2	�,�cKys���P��"w�_���b�n߆_�ݚ��{]X�������~��6H�Y�B|.N��(�W����荺�D���`{P���^h�n��$:I!�������A��įJU�R��T�*U�JU�R��T�*U�JU����a�jX � 