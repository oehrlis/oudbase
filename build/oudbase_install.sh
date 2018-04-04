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
� ]��Z ��z�X�0X���8E+ˢ��$/Y%�]MKtZU�Z���:K���4	�R��Vs1/1w�̣ͣ�O2�� Iɖ���ͮN��A�-N��4Nڿ����o?V���wm��+��p����'ߪ�u������/=0���i��P�4Z���~�y��I>����lpӛ��V~��X��O�=������o��?z���wj��������~�F8����j���g�E8�s����^��8��\mG�(���d���z��$ͦj��v�����,ʢ8�fa�Gj�O������Q8��f�����]�ӿG�(Lw>��p������?vf��4�{�h&� :�F�ZM���rz�J�ٿNeZ�tow��m�q;��~7����Z{�Z�#�r]�y�&���p�M�<�/`�T��œ����,��#'0�)�
s�E�Y��� �y��(����.���q2�R�<�a��(���4�-��?OgSu�f�	]�O4�!l��Χ�I��n�A��)ν��#�L��w�~��)|��|�Z����L����a���G���"�j*�2��M�~�g4�q������p�-���09��;`Sm�I��߹�O���t�z������d{�����f��2=���J���5u�M*~���<M՛p4��O�H�{��9�V�Xom�6j��A�𰻿��v|��[S�>� Q��Q�;��d� �/z�g�����m ]D�)4@	83��������^���*�q�B��Ճ�Ó흣����я�j��xR��/wv�ە^���zke��;G�'�����ѳ}C"���.�|pz�V�o���x僬�u�y�A-����v������38q��f!�V�<�=[^�a�4����At�Nf����1꟧j�`ou^�W�6p���6�A��%}ĽO�uws(�Q���,Z��E���Qx��g\h�����h;���Tmg����NE���y~��f��Ã������}����;���}�����e�^�	y�~��D��y���΁� � ^_�}Q�vš��zV�z�<�#
�E�Q�'�5�3m���z�غ��ɳ�8�����f��W�r/����#�7s�.�
~���]��nzF$l�z��{$$��.������j�M՚��)2�$���Ea�I�6�F�V>l\�����nW����)z>����N�_��c�bR6��$��'_�t�j�փ4�����@?����
��"m�.R �fWp�3u�?^�>�tXjuD5@B��U����9b}n(�xf/j�EՀ��uO ��n@VT�����7��7��o^m~���M�V��y��h��ɒ���۟���_k�3�Wk5����kЪ�藢<�[̯�C̽��gJd��!�M���-��<�����8ѱ:�м靧�`L38J���<Nͷ�s<�4j���0^� ������
�ήr���yM���g;H��L��p۞?���ol��y�Żk�lȣ�PRE�M�l$p�
S�>�ޱ,���U�J�jB�ב��ku�c��g-	�.�Zw�%��]�����@�����p�����l�:r�R=8T3beH��i�r(�Q��b�]h�jYy���/��J!$& j� ��S���)�ǝ�
��/G��ݮ�fN^tz����^�+�F��є {Ë0����g}}�t6�i:럳����`Fi8PoW>�: �h�� ]p�η��ﲚ>��E��GK��f�g@҃�����봻�,IPn�P?�����	��#�;P���h�Y�.I/50b��j��׀3������p��8�Ih+�	��K��uDK��)�+X�Q$�$�i�R9���y����[g���&���x]��h�ݭE���.�ކomh�Wռ�/�9? ��v%y*�Z��!.�?��^Щ�2˧�2L�P�m���Q��?/%��EiDs$�&6�֟����t��P"T�Z�W�8��=����4�E���@�ou0��:g(��><x1;s���
ͳM~�Aw������/;FVB�������}�z����8}� 1�g�I?l(PTK��@����0�fE�QVU��P�)��F#�@]�ءc3|���>~�_~������ �^�נ7�k���Zʁg����X�f���HZT�x��>,�@da����8�R����y�����=\dI��p2��H��?�&]��c[�&_0=f?�UYw;tt�>	�$�1�6�2��0�do����,���7�Gk5�A��(Xm�,�1���+V�RF�?�4!Ǆ�F�d=Xv�SvM�	 ���$K��!�ib�+;	3@�)��X_����E�����fw3Ci٨m��W8��!s�!���>����ޕ������4�{�x۱�qN�_tה8�mVWG��ݝ��1�E����}l���g=����eW�C��)E����p�ecQ�w�������\Y����?�؈+���I^R2b�1�t�� �ӾJ�V�*- ��)i�R�|����c�>��/ :v4�,�q;��x/���T��H;���xxU����S9��2�M���1\�G�.6��٬UZᯝ���_u���?l˲][6�{a��w����'��(!lyny#�f����������u��~��0�#��+x��M ��ɔ�>��I�M�(Ǒ�#^;;��}�?v�*'���8V�}��3��Ι�q�a�9�\c��CW^�u�-�H�������ρm����!G;�����f���������Q��I�{������;��l4�'�:� T��f�Ԧ��)*3+��O��ۤ��O����ii�����O��
D<d���뛺'�s/�.@�D���p��zY_�/5�t4��Q����נx㨶v��x�(+����Mߪ��:�h�d���B������!���t��c:Vv�C�b��zr�΢�����������޳�ۤ��ڗ�g�����@/��=[�����[W�����SY��>z��}�����m�&���wyJ�.p֞�k�} ͊�����f��q�+N+����J�Ͷ����rE�;�f@�)g�K�Y��������]t��DB�p �2�����y�.��v����������+���t��v�]�8�͆�q�܀�V3׹{9��zS[�����3v��F�9X��9�cT��s��,m֞
�_���v��ɷ����dM�#<>��<ި<(�v86*��G��J����b����Hؿ�d��h�Y�)7�m4���7	YQw����-�8�.���`
ta��,q$9>ˬ9�28yo(o
+'NL3��+�;��IH@�A��PײHy���塌�nG����QyEI!�[�U�s-)�t��|t�?��#���}��������������/��O�_�oN�?GܿD��@��W���!���B��F�!������k�O�wb��.�^�&c�� ���~ĕψ�/w����X}� <�y�=�jV?)������1�e}����9o��g������׷�w/v����|
�M�0��2?[0�W���������������Y����M�����;�b���Wԅ����&r:ȽH�!�T��o%@k[�L<��,�f2 ���� �k�����/H��p��܄����k��#ބ�UHr 6�%��c�M���&��"'�~���J	�J�my�L1NJw��$5r)X	�"?�0��I�� `>9(?t���%��8Ɔ:�^�V經��O�Ɏ���'Q����p�5�ai��i�7������ h	�"y⎢��''l���,B!��p�k���2P�޻:��2��Q1�}y6��3�Dڰp��d�KG�K��\/t��̀S��aM����G#�c9"j�ZL�%v��Y����K5ƣF1=BO�g��2�le����#��x\��#�ZY]]�w��	�u���&�H��n �G��{��a*��`�Q�kq���KֿL��������_1n_a�lw�����e8M�D�X�����@w���g��;��Ww�?/F��*P�4N�Q��D�����PX�H,Kld9��8P��(@l�C�Hb��ܟ�� N6�p��A�$*�^���iXw�?ތ7��?��5"�{s�����1���j�T���f�����~��g�/�50Ķ�kzN�紺���ОT˦1����QF�W+���]����\ă� �q�����W��39Y,>��VF��2^��
�#4w������$6L��Jq�ł���i��-���R�a�6���м�B|Ι��`XF��ǎ;/����hH�q��C�0�,�����W&ל		 &�2c��ڂ΂��5��{[1�9p^�̊�.��[f�۝��u�&�ڷf���؉��c�����U�k����x���5!B+1���o=x�~�
����Q���߮��ם@JǮdV���e��uv��5���"��7�ߔ�oih���2S���_]�hIM�KbqRءJ�6؜_෉@.������N�6g����n�NT���~D���&��)��m�d�P�?��ي���
9T��`���#��m��ȟ�����y!"C������.���D�ثwE|��WW�YwT�~�L�df�QN	�?��R���$ߩ����v{XGD��M<<<G֍�stLe��x�l>E����\��Єm^E�M�A��|)�-Y���_ �JF�@�h�M�U\�1�h*u\m�o����d>�>��/C���pfD���͕s1	Q�N=y�C���U�il ��i�-@�m���s�L!%.ڶ|˵�x��*���w E5'�ԾH�P�-�^r,�z,�7�����xeZ#4�N�Ά'�x`��9�$(��[������c�9:���>�GOTO9ፋq��j�\�V�4#� e��!�ZE��ԭ?J����(M����@�
�s���6OGa�n����K� �|���څY�ތ��h6�^d�A��b�=Q7��������Z�m�]Ѿf[��[��s�_��"�FhɃgg����`�hX����G�o�`o��f���_�Ts4�s�l��4�8�Q�̍�N���y�Bc;� *�{<N,����J���7���B�邂��-Qa'�����M�-��s�|JoT��g�2�e�$0���
�(�љ;~�~��$��9J�)$���*DT�#9�W�^ݛq�+��T6��xx�7���q�w'
e�A�}P�r+/��M#Ϯէ�4WN_�S���?@���Q��V�t��Bx�I?�Q$���X���h2�4qcJ��<̍B��9��d7H/����<�����̌�zS��39�V�X�c�&{�f.��Vc�!�?׾5�?���G�����*���?2�R��9��?b�����5��S`}�����?h�����]>|��ޔ|������n��٣(����Y�E�r$�h�)������l����W��z9
Ͼ�&�M7�Rj�T}�h��(I�dը���|3m�q���#�vם����^w���k�����S������g�ڳv�5��&
Ҁ~4�gfX�w/:[}}x���tv������������ }�A�me�|�A���$��_s��� }�A����5�k����9H_s��� }�A������A�n�ی7Ǜ����A���*st�����5�(��R�Q�@$��ሯr&qy޺��Z�_���+0��5�h�_3u�f�|����dg�$SG��-�-т�F�ฉ
�[���J8B������^��^�c��0G��l���ڝ����N���X�_���mX]�`^7�
ħ���u����^R�[�4>Ћ�؇],z���e��Ks�m����sy`;�^cb�mϲ3	i��	�?�|�V�кcr�R��3}Zʖ�����u���4/ɺ�)�ʆ&ɶ�v��r�T$�MR���7OEr^rݥT��c�NE���4I�XGJ����GN��>*˝�,�
at��$8��s׿]�럴#e0v��RsR`~��Ĉ�]9�-l���oUR��!�����l-=\���R�d�+����7�ت���籔�X���g�8�';H���d�U�����/�i�	���@�<�{�bx�n��H�Ckz�w��[�/�,��eeQq)���W/���U�弻��֬���/��K��ab�I|{X�Ǭ��D+�*��>?�ji���c�e%pYV7ϰ�/$���v�J���$�['P��S7K�����ĩ�'M��W,B��ˋ*�eg6M1�B3R��������K�5
i���j6TP�>as��>��+Uܨ/�0{�^yϳ�jf�� �{���l��;�a:�]E#ey��A1����ƶ�$����>�m�WJd�����w��cq�߷kO��_O��=z�d]��?|�h�k�߯����'.����M���M�j%`D���l|_� [Y�:wϮ�0�1���)S��E��(w��Wŭ�0�I��pj��?�-���+��+�O�-u(�����Npjh_�:��>������u�^SO��r �(�	��4OG�i��M��u�Hq�اu������q�h�����6��i����N�??�\�	���]�����׬~������v�+��C�fw__���w���S)v<��D�o�R�>���6�9�a~ˉ��g=��?�����c~�ܜm~z��D���R)�n����F���n�'��n]����mJ(Y��]̓�����]�X�#�8_�&4���Ni�Vt=s� �$l�K�~+��+��Ӵ�w�} *��� E��7Mr����}��i�@� �spZ���[E���V���>��:���v��=i;��
ıol��:vg1����?u����Ѥ�p|�$����^j�r���nv�%������@�N�@�[h`C5� G��X��Z|�hq�����*����ChgrZ�oM��:�6�NO�1@w0�k�'{P�Ɵ:˚��&��߷�G��j!q�P{�`�c���uSg�:��/ݱDNdތ(��3�c�3�Z��]����O����{�KC���6�����������v���y��%��V:�,)����q����Z��x>�%K��n�Go��F��������h�?[���vC��s���K��o�V��z�*�Xw�>U��'�۩G�����y��]��o��/�E�P�B��~�xF�z�ߊ�4�j88m��l�<�M�/0�mv�,���PmJ)�'i2��Wt��8�˕K�RR�#���Lѳ�����=���=*�鳕�N���L�Ydڡ_	,�C������`��_���\�=��@�� �`$����k������4�Pk�c�e\l��Q�,(�7�ttED�
��ߖo?Ϣ�,K�zъ�Jg�%Y^�H
�]a�`�V�v�f��I9#ŋ�W�M�&	��v������Z��5�Ry�?<kb�e�P�M�]Ǡ��p���Z�O:��^���z:��v����`wG�C^l^ά�*%H��"$g�!P�j��>P��˖��7RfX�~�_��<���䴗��f���T݆�����>y�dN[Z��Oh��?1\�lU����G�+���|˅RT�w�V�e��x�k��m�sK[\����ⷧ-�|�h'�o��W���U4μ�쪷W��e��V�D�ڷkk�?f���?#2�j7�/��~��>��:Jt@o�R�|e�oxX��nHoz@os8ow0os(�n����g�?�ܖ��?����8�\���/
p+��A}{�>�v�P �"#tՊo�w_��D���GR����J��D<��١�u" �K2T�je����£MB�Msh6�#�i~s�_̚;�O��ez�`P��4�77�"x�x��jUA.�� Giռ[�+J��G�)�)C�f4�L�ZjK�n%�%U�h	��}7XX5��^�/��DӾI�P"�f(ѳ_��@j��a�H�OO���N]��2͢�	ۉ����?{�|�$�{XҲ9�~�����N�黛?7��u-r��:�fW�>e�$��j��ǣ�uͤ�֬*�#.p�&�䢙 ��Y�E'd�q'��eӲ�\��Q��ئ��z戇j��X|�wu�.}��&o���?�������Z����c�#����JA�$誛˺�v⮺���`��OQ���L?Em�[i���H)w$H��n�4��0�(������P��y3���ʦv&Z޸�c���丳I�ۺ�V8r�w����w�oy�p�9��9��T�a/���&x�k���F���g��U�J'��:E?����'N�<��j���@>�*ȵ��h[�ʇ�Z}Ě&���&yT2���jC���~Xw���$�QO��p;���R�s��~nO�\,f�g�»|�^��cU Jޖ���g���t���|��o����'��#�o�5�T����I��Nme��4NNN�T[���ZY����u�tN���Pm9U:�_�:�9ߙ)��9�m]�G��B-�����"U*���"�.�C���b���
� ��Y+ū�VeQ֢�(���`���]`/c�{�?��JX*�1/�c��2	��K�f>
'�;�㒮/G����AݞF�zu�=�t��:�y�����I�~ݧ��m�w�
Q5�&e�]��n
�!܋r���7�琊F`�Ѕ�._4v�C�sLٯ����|��U9+/���c�/.�+�E͟�-����� ��'k^ ����<�n�-*��J����J�Eɉ)J[A��(c��i�7���Xv��lz��h}��9ƛ�Y50�p-��^�^�s�-����6`q�A�+�1|������HGrb2l�|i����4�E��Kp?e4̲0 �}Tt�m_�:��6����Sb�;����X
NԺ/����Xa<r����c9!׃� ���G�U�%*(������@����$�/�ОG�
��3 SK��T��!U�P퓠�-[���7����Uj�u��`c4�X}���ϛ �\ۗ|�l_�^�e�\4�����oN����y���&9ͽ�w��	h-�</���f�����ݬ�������[�@?��@��;�ϛ�������?�S��<ۏ30�����0�W���*�w�h3KW�{SC�W>�D�h*7d�������U��yUs��+��s��Ktt�[g����;
)��y�e=�ǝ#�����h��Aĵ���v��ﶤCi�$�\�쾟+z�UWh�; R�����z�O��i� ���v�D� ��g��t�M�vy�W
P��Ɍ��$�jc5� 1G�������%: �}�q�� �u�h$��_��UC��_Ӏ����:���jE^�lK)]���I]��l�����<�E�,��:����$����ve�)����;u,��QrAL��@Ԣ�$i=��ݝ�)�L��+�B*�櫭�g��k�k������Dh�H��X��0V>�2�:�����n��W@� m6ɖa�b[����p�&�
�B��|�I����מO%HV~b�g>�r:�6w�Dο�*�2@�hD����P�yp;/��z�)_��T�jO�Ԝ3��=�k���4���� ���m��: 1�Jm�93��x�5)a·�֒�I1	x� �aₜ���he櫗/�D����po6��Kw3��t<N�C�]�V�	�#�)I/��Q��,�Vs�;�y�[��e�Us���o-IA����j�I�z|8FLat}���M�V��ȁq���_H<FX=D�f�`��^vH�]�N�3z���=b]��42���!�8� ���6�fC��~����j�״Z����E�^�Q[���?R~�v�L�6�]+�G<�!��w��*��Ƙ�������Q�Kw��1�R`� o��[$|JA�b�6�Ґw��%�` Sd�4�&��e�]��@vm1����i�cG#��7����r`d�g�(���9�����nc7���0`}��*a��}���|p�l�_W�#Ըˋp������X�5����<���%����^���[s��QFchKr�y�j|��E����=~˷���I����sާ�y�������\�v�mp<>Á�WY�	s)/c�j~����8���;��}�Nhk��LZ>�p�W c�a��S�R��q�B����T,؅��+w�t�1���e�?�N���*{Qt���[4��*`�"D�hZ(p���`T���	Jj�h�P�4jP�{�j��du����ȵB��-�`��z(U� n9�% �P�mR�z,������(#[K��/+�>��<��c-�aJN����^�#������p�	Vk�-����/�3�=�u�׃�0UV�tU4��NW@/\\�C-���D���47٫�����#d�K_�2�S��/O�ST��I$�[�D��V���>��U��������QT����5�b���w	-��x��<hi)����ADԕ�%��{����A���H�2	�#�uxYI�O}΅��n�o
�%�N��O�,m/���Ͳ��[���k������̻)��97Ȕ*b0��+U$1�k]n驛�V�J���vh�r�� ?�<�w��RJ�1�y�AȏG��Ei�ʀ���}���p]���X���	z���~�3a)��KA	���~��sU]��@i��<��W����1WJQ%9�؟�/�������Ž�=fJ>������*ƾ�����W�+$w�W0��[�EX�;�)/��#�+<�IPQм|y�� M�����9<��_&B�KX�x�i����D�~�QXp��Phuu_��~�]��uEJP��t�w;��+'�(%��N�x��k��F�{����q�C	
P9��Qb���e�&R��U�͂�y� j>�r_���Y%Tz��ni�Ͽ����U���Z�r��,f�/̆�]�:��\p�U���ڙ����'�fx#�Iu�n�{-���ڽ|�_���%�7lcIZY��C�����G�+\rh��M氟��'կ�:���w�:^r���y���"��s��_�?ɲ^�m�#����j���HY�����8���|J�㼅.�U&ܺv���2�U��W&0��G]�`�*v�,�OL�>+D��Y�~k�GńWV�/�>��\����iC�;ң�3�~�)P��??�e�?�M��im��P�t���x226�����t��p0�0~��a2ќ>��UcX�k����V���afU��
��\�Uc���q�U"�����`�'0`Е���"���n:���^.�WĿ�|/Y�*/kgIq��xs�=4v�a6�$ו���.��]uR[���5��.��6���Q:9�MY"{z�u�����9�}|��[#wCS�'��SM{爔�@�Q�ZN�g��ԉwB�wa��G�/�y��.�����~�E�ù�����p��1���EOᇯ;\>L��������0Ћ$�s��J!��E>ienR�D}���c�}YEr���Ҩ���:���Qr|/��[6+��������F���i}�����v�z,w1�ry���([7�������O
*g�/X�&Oݰ��E��74��؀d�Rtn�`
�����܆�`���ţ̧���z���<5徯�K�P
9\~�+xɒ����Sڐ&�����$t�|��tm�wWq�� �9$���i���a�/F�5����e��t���ԇ�M�c�u|�|���&��7��������l�o<�9����T��,���<�&C�#����^Nh-��/�+S���0�}���t���w��,����˔�?�?|����?~�;��K?�������������_�X�'�����5����o<~�������GU|������w�:����@%(T5���|�PR�%�ڀ��&WY|v>U�[uz�^fQ�z�pz��d�$�^hj������|�J����@u/��
�q�7S����0�arE�� �݈O1� ڞ<��&X�����oU��3$��9u#b���F�%ތ9o��9̢p"�:��V�VG�pv
��N����ݠ�"�<�߀��^�
E&�wq2�M����-݉���}�x�{��	��hh~��>Q�a<6^Ȇ�5�����I��a�
�)�5$��$I�G�ԋ+��ݼ�F0]:�8�Fɀ��lf!|��=�1�CRKi�!V�:��q�9MmME7�ҕ�ή!�A�,H0���H� �f",��Y�Ca3��Oq,�d2B;ŗ¼��Jv��"�l	q�O�h�!�.�c�1�ajA��
���?�)�)a���zaX@���+`����p~^�K����k���O�Ic�u �g�c��r�`hp�:(�D>���U���� �QP��2����_G��(bf?D�
R�-:��bpb��y�8hl���q�al}IИ�8�zs���{��F�r�	g��5��_�b�����v#�x'YtA��b���
�'�0�Eg�����t�u{@unt����7��(���W����4�Ә/ �F���R��K�����x�(�Y���g8i���ie^�}����dp� ���퉇�;�\�3�R�V�N�F2�1�AUUF�kP&��4��5�2���X9y���2O���[��j�8@3��Ѕ0[�V�r�U@��Mh��ztD�%&���U��Y����!����z]���ٔx�^\os�W7��@"��0�����w���qݜx��݆�� �M�Q��:�`�Y�g����z:Di�0�>�����B���"f�@<3�%W�
4j�����S@?&��i`:�a�mwY���8�d��rs�e@� E����r��]�a�D�A�V ۑ��p*k3 U������G��� �L�n=�R~�WPa�</���%<��qx>�Y��Q8��B< ܂C��b��sj�n�!�p�@(]��A���<�'L�@��	�m7�� $��z�d'>QA�����
P����&����D���2��Qg ��bҥ�,��(<�;�5�����}ʰ� ��#�%�I~��g	��d��(��^F���f���"���RD��s �b�bi,|M�x顶���� Q�aRZ>;E�F��*�,!�L�h��ճ@���(�Q0��HbJB/�J j8��5�ر70�y��VLn
���*:�q��k�tM�q1���m�u���2"�Ǡ�F��u�#*��-�$��a�4�����YgO�0���Cq�9�:�8�Y�'�Is�����3
t4/Ҙ��u�� �4��z@,��
�To&N	�q4#m�c9�-�\��W-�X�����LS�@��P��,�n)@w�y�8�)�ߑ�A���Cʦ�����q��"��\^��1_:���Tg����9�9��a����ޯ;<���)�>E�9�+�3 �U�X�����5G�;� ���"5t��Vi6!-���8�E��3 (a�Ό;u��6���O�^��/:`��R�z�JuC�L��f8����[�[�V5y!�k�%5+��`dW�.���&&k��d �c�2�9s�*T�pB��P5�|'�z(j��\C&�t+]X�!+Lu��� �z\��g�D(}F��؀�\�VB�0���)@� �zI��WM{jԱۊ��j�`A|V���b0����)��'��Q�Yd<��E<�y@hBZ�G�
��K�38���]$�22:� uay��	����W��S�q7�P� ѧ>��{���{�m:�mx�M$���W��.�A{v(�DD �?�34t$���*M��4�KT@��0��"�:�,��Q�&	� 6�.��~����F#��FQ���)�L�hC��ӌ@�����.�D%(k)�
{$3$�\!���RQ���,��� C��`�BL>I�!<E�6�Op���K8��~."���麘@4:�/�U�$��(r�@t"��Xݕ���$� aR=�k�!��5Vn�"�/L�l�0}[tK��gS�$V�d��BIWa7�I����$�آM���D,yU	���Y�)�l��0ڌ7�-����a�H00�n4I,s����Y��&�������Ơ�IAG)�H3�5��-%��-T=5ϯ9�hMTe��X�F!�҆�\:O�->��aec�L�����(8��ge)֡����f��;�,$�G&�1��i�r�Ag-�(R�3�y��$@eKWh�h襤�w�����ɧ�E�cߟ�Bcm�2�@���ghIxxZ� �FW,���X��M�Uȋa��G� �i"Q�1w�l�9��}oo�V�J�Ƥ#]%y5������EH`c�.�� ��Ϙ��"l�Jc7�R%+@�<p��?�+����������n,J",e�_<��jh&b	_��6��i+<)/1��y�5!�:��&�FQ��#�B�狀vU����F�Qxz)X}Zj4B��(�1/����
Θ�W�.!1an����u��<A&�>V�~�7X.���Q�i�@�Jk��vp����D`j�C��fC���L���#'���Ji4

�1G�ԥ��b!�3�qڹ�������dSmj�Se���Z9!�1 E:�������K�Z�"�>s��<(WZԢ�9MS��8�=���w3���Vp�L��!������Ѷ
�֪}�w	��q�NTC�>r�W�M�Q,���Rдx�ؓ4 6&��^��$s�� +o ݞ���1U޵6�-�k�]#���)p(�T%�����Ē�˨0D��)�d�W��w�-���fy��ZW6�8d�~m��r2�e��0�.m�ܷ�]��-�T�t��3@��2ng���B�@��B�jd�B16��oP!@RꟵ���6%C��6�=�@��E�J�����:4�հ���$��w.pAj@���g�(�÷ak�R��D9��w�h��\�V�~z�/qA�~�!5��His�K���8OgS��-����a'�%(�g�,�n�!(�1��P�$��q��?�vIO�|��6�� &��4�#� +�ް
���Kd��賮�	X��P�B����[d�D �$�hDh/t�ߙ��(tM���: ڤ���,h�Y�F9�"�.+ĮD�y@��k�v�Ēe19��}���Ѯ}�A5���Gf�[Y��p^�@�B"]f�7؈9ˍ��da��*��Ȥ�	ڠ��<r��� `��!�Pt�inlu�c>2Z�g��؟m���s�K}bT���<�0�7	W�̺������q֟�u�m/Rq%v|#�ű8Jf�VN�z$.�.��Ń<E���52��(;����4��-�#�������}���n�ܢ!����q�O��CV
(B%�@����61�f�ϓt��!3�2$7�]#�(�^g#��T#�	���������Y�;�ᘢq`@��hݍ5��@e����'x��/�Td��(�QUL�dI��A|=z��x�FT�����c�7u�}��i�Q ���C��xk�t�7���Ὂ: /<T[�~L#$��=Oy�(�Bq��G�AÙP�TX12�8�T��]5��B�ɱ�f�ԕ�H �(|�".�&>��S����ޗŔ���,mZP���{�Zι}�㳶ؠ�r ��B�������'�0s	��C@�b��%����t�O@�g�,����5H�s����g����4�D�1�r��
&.�#�B�?�U�-�\��@���O%�Y��uj0*@�/<͵1�26��4�3:<��9��60h�jkv�n6��{��5RTiZ�Ffd���$}�'�	�#sԆB<`cBh�]d�Ӳ�H�o\G{�\KIPi�h3:w,�����^�Q��ZM"���zkUa���"q�І�.#�d]X'ᕭ~����`W���)M�,W������v�!VX�H�����y�%V���	>.����me�̷ZT��lG26z�?�B�7!����L�_�1BZ�%�/3��c�s<����і�PVd5�E��Q�#	B�#+ ���J`�p�c��j��1��LH��ԃF�Q�$���цl�Y�Fw��61q]Q6)R@��� aA9���u0w-���N�W⳷F�T� ϱ��Q�Fa�$��:�K�������1VZ��j��"z5v�##(s/Oqmľ�1�bO2!c�����%W���y6��Y)>$�s����`hd_�b���+'^8..�vN�{|3��(�'�&"�ɋ;���>�)Y���T�uX��g����7PaDe]��h�7��T���ܑZp\�IP����o��%�R��㥶,_Fh*�f�d9*�	Ni	�}	ON# 	�$��������"����T���#/=�O���4�!�:G�+=Xߧ�4 '.O�aE��K؜9��7�T�dbX�e��<�:�1L��&Bͫ��:+�4�OId+��n��
�t@�nC�9�ίr��%̋��Z��ӢG���Ɠ0��]��D��/~��J����g:dFك=@8K6Z��y���C�2Q�POX
l(��,�M�4$i1u��n�&�9��&'̭2��q�L6,�Q�L�	t�C�L�Ņu��ᮔx2) �7�Ӌ�����1 #9j��Q�<Z��CC{HIr.>N9@�Fp��4��v��>Q�r}"�X��	�0$ن��z��Q�u�{ 	;�TT+�	>;���.ݭ��g���(�b���+Å#e����\��P���aN����RG8�uT����n{�𙇚�c�H�	�8��S+�9�����q�=��g���	KG�TZ-���~�Y���Vjg�n�hT�q��	]���9a A�2�260�2r�(^��M�;��2���HD�� }R��p�1���q��א�گ�e���;\vk͹�JgD<����H �c�v�/+�"ŬuQ���c����(�Y�!A�Pk�+�.ù���Kq\5�$#��9�|��98Zm�d!h�	c�Z��%�aX��[���m�=m2�S�=53�N�(kN�&���_&�O�0����	��QP	�]�'��"�P�/�FLm��0d��[�c$������*�q@#����tR�f�X<08ac/�>bx8<�;PAspO�#{�{SJ��	CBc<�a�Ck4�CS�`>��AM��c"��)�Ҭa[H�F�,����`���Wuc��8nӈ�S��/�Un9���71��@R��ê�l�N(}�Q�6�J��G�M24�C,a�d� ��N�3�*,�^ؚtt��</R
[$�#<��6n��n��b��+T{��-�WL�&$+�E�e��Q��N�G�`��~��m(t�xt@BJ��7�����Q�E�ш����)J3�(;F1�r�#כ�� ���X� ��`��4/߭&�pg	�&Y �@�H�&�Ȩ�f�H�
�P$����C�����A�s"�0�t�77�� �Ӆ��EW��L�b[܁��DF��*Ҷ����)P����|�Dy�C�P��0T1*�q6N�d��@nk�����
4�ĄԔC%U�� ��x^�C��ӈ�|�dʇ�C	�zN��D*]S�&���aw��s�r��M�j���66ȑ�9st3��dvꮜ�(#C�:j�~H�v�Z$���qF����I4���+#��AS��j�y�aN���$�w	8��J�����zQɔx�zo����w�0&$עm,=d�	��;fl��I�`G����N!��ܳU�II�f��[q
�3�f�15 ���;���&l���G͛z9B/
 �)s�i�eG
G��#Bh���c#��Cg���3�%�WA���<��e@�Q(�N �� "���y���PH����Rhw� iY��Pĭ��[�1S���"NG��G��I1��L��8fl���~��HB4��
s�YK�d�s�����3��ecaY΁.�+G�?�
1����b���Ի��H�\AS�
���,A�9�3��Ħ��j}��:��/si�j�yj��En���K�̛:�qV�q8��� )�0�8�'�4۳.�VP=�9���t��Ĵ���H�3�In6��fN�q��]C��ar���Ķ�R�F��+���[G��1��o+��T�@�?)��6��*VAW*9C����Rx�1�Ӯ��܀6VU���4B���(�\�C��M�,�J��92��S��- ���,���V3�+���R��'5+X���,Dz����@&�`��NQl��X�"�1�>)?�܇���{+�>lo�5�m�L����|�߁��� 8�c���4�HY"8[fdǄeD���h�����S����c[�H�����B����Z�06)ά5� �\�?&b���8��(cj'đI7%�%�0�˦�8�gv���v��r��ԻVl�a�m�%o+�����ҳ{%����xjG߯��71o�)F��x0��Y�����f�ΩQ��#��آb�sV���r�zh�0<�Д_�S�asd���L�!1�č�6^�N�{�j]�;att=`�QT�0�/&:[�
Qu(38=�c���c�5l��h��\�$H��~�.���{�xauv&N�eb�Ջ��x uν�U�e[�F������Y�.�X�6Ǒ���P�ur���!C�pM�1H)E����T.��`*Wb+F��F��wH�jb�L((�78w9�h?�>"yk욹���]�Gs��C�Y�	�@T�%9Z͋yYY�g�*&b	��p�6 ��3�MJ����P9 I��@ ��l�2��x1Ѯ����*�b�ҟ��w�i��y�gߨ5�mÞ���]H�μ�6
.���A/�h���B��� 67��A!#��bT(!�_C���N���z��QA���	�F�����OTCT�.�a�r�<i�kd<~-�%�i�6 DQׯ!�;0�[���	�#ܸ�G3#�Ta�$��ƀ�0a�`R9��j��:�{n��V�Mo��<�'����F�r~��T&yU�tj�s���"%n
0S�"���a+��&��Zg��+'(��w�߄J��])"NE�S3������( *��}��z`�Pv(�e�j���*�H/�*C.�c�O챹���!�h��*�!h�t�� �g�m�rP͠q��0dW���0�dMH�Ne'(à��)����t�E�Et�T��~�fG�3�`�\��1�	|��4G���anBk �\����,�֭�k��3q0Z�f}��H�gbg�,}�_Kg�7���=��b搡�W*r�4Ez�Y
�a:���lʧ����iL��"g�H����jNڛ�O��H/MM���+Ъ��e��e�fp���"��D�f�G��P^qF[!]B�N���]�#J8\E&e�yI6����n��m���CɚO"�x!B��1�L�%�����7�7ء��Y%'���z��� d��|"���*�1�4�H2�Ys�;���-9[�b�Jrh�35v8����`ڐ� �+�a�5(�{.7$�()w4�&"Lo����X�M��KT��P�9�V�W�㮚N厀[�/�2ѐD܆���,�^��|Ʈ�����ςT'�XdӞ8/3���\_Q#C�5�:����'������z��ω��TM.x��b�+�|Kur�-���E���Q�1��3���ѷy�5��Ǭ��U������h�E.w�H��-v�G�`p�i�q;xD-=���kag��}��8�,J6Ð�� �V��Y⬸e�g�����%Y�ż���:w
]�	ř��;�O��%�ϰ�h8Đ���,�6R�
*מ7I34��BJ>�|�{�'H{�!D)�����Yz��S�:!t��e�RǼ�JW��N�)���{x���Xjr$�?E��wr�`J�M%�>;�J|�������4�+Yᨙ��l�r��H��)�I�^nQ8��>IV��zK겖��\�V�4�����Ȉg�Xt)'�B�/0i�0�W-��V�46f<���Ynk�D� Ä��ڔ�39$^K[�]v�R!}��x��S���:�6hi��Mþ9�;�HY��O�S`�<r:;N7s	��&%<(�L��A�BΑ�XqQZeD Ԟi���!��
�%}��Rz+����W��-�Ґ�LG5[��Vh��E�c�4�1^46�����z�r5�g��;�!,$��)?�U�� �j���9���~	�� 
����,�K9��N����-��U)�$ܻL|b�!Kgb�7*��Y�j�$�H$W�<@�H�S�~��l��2HE}i�*����vK��USv.ѐK��T)��pQr"']�0�?�pkOֹ�m���f
��;H�,]��Rs�c��̶4/�n2;���r*��XFFMY�#����P9Kmnp�+0�"~1� S+��cܤ΋,MIR:�=tL��I!��0i�2��N[C05U4�:��:Al�\ahs���ҹTEg�+�
e�Rd�N����pw�0�r��C�CåH�(R9����֥����6�Ȧ`�ÿ�E.4���<���"c�&�j)���,%�6�<�_�������������QX�P��9��p���h  �ɹ�J���8��l�����Y�Y,6�4��+���u����f��Tpd��0�t�u-h!�p��:S�:����ntp���ZU@�h�����5c�#0�����jJ%m:���x���6���|�8��^�`����6�D`���a��,&��fW5����~:.��s��82�a*��E��e�����X2��N!<�H/6�G����|���x�ĒC«U��1Y�4N@'�R|����NQ�� R��Hv2}І���Wc�sJ�CAz�RHim_�"�W�/d�P����e��.inH�5�2%�v���І��%��S$�T��L�L<��� Z	�Y����J��y�K���:3tB�8(őC<�AU�戚�#X��iڹ��䝭8��H��Ed#pMAPK��X��eh�熵�o�Q��ޙ���c]Z�1��L*&�͌�O�i'T�d���S�M��:3�WW\S��C���Icvw=�z�R�j}��ŭz�#����ߧ���X�o�zl�H�2���C*g7��0��p�G;غ�(6|�}����r�]��v���n�_c��nˊ�|m�&4>��S)o�S��x<MC}OG�*sy&]"Eg�����n_�R�˻� �aF�O��"Mqiɀg}�:���BY4z,���8�L
��x�3o�;,?(�bJ��\WǶ@�lt͏@2]x�dTpr43<���c���1�����Ft[)���.����@Y,�����%2J�	͍��'$>��Z���W�N�2Z`�r�Z�n���S�L�x7H߫@A�:&��DdW�c����f����!�������b�F�2*8��u��qήb|y�RG�0��M�޽T0��2ͻ��#[� Y&��-�0�cz��n,�s��8�Ka�=88?������B�$�b��+Q���E�����f����΄�0��L�����4z��peT�f0u��"�aaA���r��Ҡ	!�����Z����Y� �����H5��)�ap$5��Ϝ+wD��Uz��!_Q��k(��&�xS�32;�J���jQo>
���y��ٟ�����9x�Y�;��Ƽ���T3�&�U�E��g� ����x~}?c���;U�2�!��^�;^����:��FviC��e&��z&67Z2�ltn���;�CI��
q	��% :��p!ɀ��Q'hZ�ˈҋ��L��Lh8���$�U���vzj�@��9:����^��������^C���w���a�ho�����^�tww�:/v�j��ޜ��[��c�ë�:@�?����w��v��G;�;�������v�u�:����Um�^T����n��fg��I�:=vM��s�����|p���������P����ãn� �;{0�.������z��P/ �����݁�A��F��I[���G[��k�����^��r�x�����ȷ^�v����G��nK�X��_�@��^w X]�����c_Μ�&�����5���(�P]��}��:�y�m`K��z�+��;�AgwW�w�`���U�{�fg���{��9�U�:8:B(��FOZ\n�:j�)�>bP�����]\����"�(K~���.-���;00�=���A��1~;P{�;/q[q���t���:[��8��y١��p�p߶;{��=3��@.�n��awk���vy��{0W�Zx @T�! r�>��  �kā��;�U�w)��A10��w��}���G�}X(:c����Gpް��齆��ϻ��#�s��CFx��������x��,!�$tv�[�� 7_���^ɶ)�(��^�V��B����:��rG�fGd��m��"x%���^)I�e^�虌l8�نߛ"iko�c�g�b�N^����,TxJ�R"�H]�t�%\X�gU ����c9��(�LPLlyOw$�ڴN�t���T8�����x䌽�f��`6������B�tg�����]ZܾXֵ�xI�<�B�y��:uh�8��X����,o�U@�x��^�.��:�A������s�ܩ�_fy!��!��|�5�0p�,�&T�b�4��fq���D�(�'�_īoV5�%��K�(F��Aա���S���cw���C��ؼ=֍A��l
"r�����ܻ3 �K��NUC�(1A"r=(�޺��?5#��PY�����Ա}AW��LmW��eSA��p9�}]�͙���҉�iGC����8��[ϥ*���V���;�N�z �N�{���}�:l���Ms߸���T��r༡j��B)9�=�B~����ƔL6��ӏV�t�zY�iU/�������:I��q��a;�*-�Z\C�E��&�+h,m��ĊӮ��,�<�KY���&���څ�j�����Md�Y7�ԕsj�ٵdu�#"���t:�l�///[gɬ�fgm��~�`�&ݸ�M���N����T��|Y�`�(�+$�`�
��e�W�(�klih*�/[	q=�i g��q�IQ60��R�F.v����5��������'���\��ִ�w���������<�=��T�+@����/�,��y���hy4�~�0�o����$EK�S���}w ��hY:�����܅��B��Gc0o�����Lg� �{�RCD�c��L�u0�-�JZ�}*����;���\�@���A�@`�8M��Lܤ�bM1Ԓz��\�W� �j{���/��Ӆ�-�n��^X�+�it�2^ͺ�MYw��b��xi|���ᛝ�k%YB��U�Í7o�!�R�.�4��Ñnn�0 ��p尉��Z��;�]1@,Kяɵ^W�l�e)��(-�g�,①!��m��*��R���ڞ���R�"\Jx^ݭ�VpAv1,�g��(�(Txk��e�`�0�caM�VL�c����U����	���MF���x���� ����nk<�B}���=y�H��>yL��m�w�<�x��[��p�����������k�7~�־�x��Y
%O����p��w��2���|��x�[�e����h+�:~�݄߻������_��r)'�B�K��m�~F�j%1�	�ABz {�w���ډiɀ�g!��TԨ3�c0Q-s|؇?@2�k?������mo4��eĄ�@�'�δ���+]/��m�1(����\���I�ɜ�3�!�`6�h1M3�(�[��St�SMJ
UB���-��2n�e�֙��^Cu��������EH���l8���81�@��2
��ݍ�I z��恄�K��/3	�|� �`P����Y����;�g3)D%N�b5K��l���L���%H�]`pC���,���8��S��x^J��+>.R9����wA����D�y���|�.QP��!��n��ޫ7{�����aT8����=�(�E�r��oL9��)�=�A��0��vo�E��9��
>�����e�p4�]�w��lR�.���1�3�`����dv��&.ǉ�����D�Y�+���Rgp�'�X���?��?p�AJ��� n���'���?ȣ�U{����+E���T�<�X[�����\x��hs㏛����7pt����a���U�Ӫ�ֺޘmg��ڤ D�嬲1;�c�Յ/���:��@~j�_��=U����ힼ����V�)x#6o��Ì��̫?5��W{�����6|����Cy���%�h�WZ��CsV�$w�Qj>����]�'�J�a�}C�o��М�j[S���CGD'�Ψ�E�U�]-�XB&T�o�m~\6�T�\a"8̙�� ���[ѿ�[˺p���\�]�Ŭ�z�I�s�h������� -�'e��z�����4:kqH��@��e�� �xg���HM��OFIc0���E��j��ڲ+��O����$��Z�i̝��ca�D��͊n͏KOyuZ2[a��H�ǃ�(�]_���X�O������M՞�'%7JϐI�W8SB��ҭ w�H��?`���E��_\�ق���a��3�Ҝ���̮�������ȹ�U-�ql���/n��7�%�!�v�
�o�u���Nx�R�A�����(9ۄ���A�h�c/x$Z�`��R¸@.R��ĸ�h@�p���\�h�?9Y_�|�hs������ZkMK$w��-䗹/ocv!�O'�"͢|��se�Lp�M��+m.��j�yV\�� 4�t?��{���m<����o�l-�MN�6`�R`���]����.}�cN���/�`��?j�7�?C��������_o�]]����o-�J��/�7Z������M ����~���y�)���Y��	ۿޭ���Z;Y��Ro�h������1o>]R�dX]��.|m����`�S�9��xv�3.`��{��]�ֲ�X�V�|B��OS�{78G�/ތ ,��MN�#@/,� �7y�s�R�"���1��f/�U�����ۀh�lw_v^����
O�쾧B��Q��#yt����6�����~�G[�����y�Ƽ�W��_��Dyk���+! �o��ݓ>q4/�a��	_K�=���(ŧ� Ne;��#��s4���w�����OZ(6� ��j��ҳ,�p�y�0��	�s���ך\́*���#��'�4��vm�wM`�|R� �*(��/����V����6��kI���BL<�XH��K�T���'��_�⛡���f�d��TF�E��*�&�D�H��
�����P?�#���!{1A��
��ɓ7��oJ.JCPt�����U��xYBpOm�G�wvI(6;s]���I�V>�f�5�"j5��SJ[���!6B����m�VJ��Z�/�H�d��y�jݣ��#`AdFGO����a��`&�x��3vN�_|���R��+4��g�[�]��d���xԴ����C�||:����̝�?�0;�g�<G����2\��j��B3�6�2$�H�z1[?�u2� w>�&R�3�����X��ڪ��d��AK��ʦp"�[���#¿O9L�1�
a��U���=&��'`�I�`X�xё�Ӣ��'���U*�lP59<K�s}�)Y�:�ν{xC�c2µ�d��x�O1^\����Bcz�m�;�3pTl�Ø��r�4n*@���Z�0�p�E,7��J���],ܑ�pSd\���r�8U=cmj��7�͒j�8����1g����p���#dc^���F�c���M�x�7��]���&D�Tw��=-g�W�.����6˻t^�XXI>���x`��Q/I�9�3[��p	����	�*|>��I��аY����'�Вo�A4.|Qh�t"��]K�q�� �7c�
u�����3��E��0syZ�&= 4o{{*�2��4'?�>��۝Cz������*S�+�l�	�?2 �'RV���(�0��aΦl��׬�,�l8u�Y���=a��:� )���+��M��2ˢ��AK�t\i�~�!���p|U�_ X;+�h��Z\	.�jǪ��D{�����?=�
zei駻� #�>cۜA�3�b�����c/tT�Σ�D���m�nl�{�4xN�x��,Z�B�m�2�"V�VinEؕ�ֲvfn���Pc?�P����):p�0?2S�v�T_Ȑ��U��l,G+
Kc�i�/�$AS����Ì�s�o�i�Lu^�*+�H/G�{JDrŝ:A����9u�ߨ7�u�p�|=��>���܆�쮒�Mo׈B׮��V��������_�.��YWx���	�b���u�O��$����9]��s,j��S�Rah���B���J��y+��X<ȅ�C�M�S-I�X�	�ϴ�ʻȲ|�TDt
П�Q#y��n��`�2��R$9�
�F�+��� �,s�Wo�YY��	�F��z_̹z��ҙ���1k������㍁��6OK��$�	uJ�?�J(�]@w�G��Y;�B�� l�xY7��@[a����Ytƨ�H_yˎWȂ?����Z&ZN'd�p�]�7^�T;��S�o |�N��S�au����j��z?�+8K��7EU��:ԭzg�N�OU*���흗���6�1�6�ŁO�������.B�
�s��:!O��`�&���/���p�|��ᅍ�CB���r�U^�G�
��~g��C���h��)M4v9JELYyds8���{��>�d_�fP��X�Ċ�5������:;�k����w2����Z�_o��2!����X[���(`0>>g8w�W�@��&:;��W�Q�ƱS5�hS�~�n�x飶͏�,v^�ƹ���΁�;��nz��Iiyc#�F��'��'X[k�QeV*YA�A�^�#�9�v2��0��쇶���*�y�dw�w�؍Y��]��;P���/w^0���O^��V�4��Rp����i�+��q��w|r9hMߓ��m�s�Gǥ���'2}9��� ��ŀ�Mm9����q-qˁ�!o	Pc�[Lv�j夭�.�4�s�a�O��)���'�Y��ؚ��H8������n��ْ@���i#���d��=
��~��vqL�|���7^t{%�y�O�x��py�=|6�^w���hs��O��|+?g�Q�������x���f�[I�����K�*��2OBV.F��3��r{0v2������c�R��PH��Qպ�.����4���:��h��JA6��Z�O9�^RDh�C�F7e960砀��nSr���40�v3�.:�~�`��ώ�AϢ&>��A{<�⡆c�	�lΊ ��%w,ȹ�V�W������"N�B���I��<�ݹ�����-Cr�~u�����:WB�Z�B�_�.�En8�R����,_B�oJ�K^�2��r2���w����_=���o���{C��i��C����o]oGܿ���;�(�q��$�)�G}Ʊ�����ǲ��������ȢF�����g���kϋm � EY�Ȋ�M�c�@�V(Tu�s2�f�Qn�� 	p�1O�~r�%>@�7P�w:�T Sx��.*R��!���,v�hP8�L#/�^G3\����?��l2D��Κ�@��O���	{�������~x����&޽e�Y[��V��i�q���1���Ի
�8mf 'B_X�g$��UL,g�{�	��';�7�@��Ϗ�c������<gW����֩l�e�*���g{���JIR��T�4�-����|
�pk��&Rxi�w��m
Y��!u0*{?�)ȿ�	��8-��%����h�왌��^�9ـ;1e/lby+���3K�̱~:��#Lq)!ȸ(�4�C�0*Ns}R� ���?E
z�}=��I�7"x��ms�����$d�\|�O5URL�4�i�7��n��߳��$^��	� �4��`�S ��a񓑩����&ȍse9�6{:{�=K�����$�\	�M%;�#�N��d��\� �Q�VB����Lcϝ���@h��x� ��-�0���}'��R�I)ƅ��
���k�,�Q�P�㞢�h��B�l�Y!�Qg-�(�9�b��V�z�Q�='��$z�<;�"�����P�ŋ>����E�A�s��ޠ~*=c��HKʉ'��1�w�G�s��4��1��Ե��Roz1w��s�9��n_҄J�M�V�WW��QC��?�i3�?�aW�V�j��{H9�9��\c�=�]��<�#8۞i�2���-�S�<V;���s�NH���+�u��bƛѩsm,�����E�_�iT���PǄ�i{��S�Y@U������l��MU�}��g�5k?f��CՎ��}�tۦj��׭����u��Rl�t�vfkf�^@-�qt�tñۆj���j�]۱W�:��R�vf��*A���Ш����v���Y��m'�t���x�T[�GP�*ZG�4잦��nu\ߥ0߳�@�t�훬f��QС��8mC<Oo������@u�0��i��< a�D����~�
:��P�f�ik^��RMU�b�e\�9V�~�*�bx���e��ڞ��!	Zљ�k��mz��f�6�w]�u���h��k��ؖ"U+Zܵ=UU5��ت�X�Ҧ~G��N�cP]5:�i��ٓ���Bo̶�u��MMj�����4z�����yX�&q��Y��|=�ڦbT1ں�imfȲ��}{���*:,�������&�n�Ű-�U�6uT�`ĉ�-�h`V��Slj�A;
������X�������	h#� �-��ѕ (�k��t��U1 iK�H��g�����1���tǢ��hJ۵T�6���O�-qo�M�p@]�cӀ9�%�=�*��Էm'p\�L�HO�V
l��m(v�j0��4����J`��gqpM��7�tSkk��Éx�f;. �&�4�m�0q�gf'ow�;�f(��S�C��  Z��_�ci����;�=��,��j����u�N�u;mK���,�kc�P�W©)PK��N�F��h4O�UR[S]��c�SD�d.j��i��<�u�cx��TV���q)������e&��z"�j�E;rd� !���*6T����j�WԶ����r�Fr��	Dp��1a�QN4@E���d1�<�`���ٮ�y�ZUa$�D��=5;�ۦ��u<հ}װ:���jG���u]-�(�WS;I����O��t�\*����8W�s۱��� 
g�g��P��N'h�����-�
:x��㸺�x^�WjΙW��_䝠B�Ix��{�xlR���HF4�>NCj9���C1K�j�	7+.�8�Uf��)��5�L�j��v� �
Pm��8�0�"La���f���r$s@d܀�vj��8����F�g�J�v �=���	�T�6��o��� �6��@�\
X�O�����X�u����b����:��mʹ}ص��Z@Q�@S�ko��� OA6�ݷ\�n�m���G��{@E���1�3�g��S�u���aَJaX�fQŅځS�c٥0E'��?��9�e�@C4h��Q���j�:��c�l�rtR���d����	'��!���o�,ؿ�-�V�r�=��*�G�m*m�3m -
�خ<	� 3a�����q�5b'�|��1FGl�;LAλ�tt�� )�����R�9=K3\χ]n����x>&�>��(�նU�Q�Growk�Mo���0$�w] ��AR���	��	��nROr�@���6���q�npd��NAbh'5�[�?�ྤ���}��r�iο�CyY����� ��~3�1�c�������6��������` _����W�?�H���H����1I�ob�C����<�{��3���/�{ϠNϡ}�"�'�(�:�XD����*v'�~��>�K:A��ev�D�<m����MF|��4@kvN��4z�( ��������]9���qym����Q�4��h*zSm�@y�ºy0�`<O^�YJ	+gY7��ٞ���9#6��w�̂�����W�a�o,|0	����Z�����`��7��,u_c���tA1�^�#'�`2c(��,��m���R;�H��������c����s�|�g6��32�n�8�gf~��4�P^�"�bڐ]� 1�\�.]ţ�y�3�H/�C\zÚ�\�]l4y�Gɛw�p�,���ED��}IIBj���a�X�3�����N��{G��w��F�RI0��UpnNX�Y'�	{���9�����_�� �9c�)�Dͫ JJ���10����r���37J��zJ]˩���o�8C�lg#A5�a
G�ҪHf37 ��D�G�Z�y+�X��������өaEg]�ʎNr�z�6��1%�+�CN�+�\	=W>f��CF#��3��Yxv�&Q��%�B�K��-���W���R���^ڸ��WU͔�5�������J�Ҷ�7(̓2��wb�R8rL��1Sf�)Yv9�<���J'�� !�4���F��e�CNmU��O��p���3���3�ڼI+��.F��������[�<�����䠧v��O���t������+LX�/������v�k�6}ɾ8�|=n�%p���,{(���Ǘ�4p�M@�b��0���ʞ���
�CKެd�f].��)~.�E8ɻ�Zr��!;a5�l6��o�w�� c���7/�;!|%^]oȒ���{�.o*<|r@�*��`�'f8�0��8㊊�cz��$�h��'0�bP�\�U�~�~S6*'�/.�k��#�p��֖J=a�9c͈�d"�՘m3�J'��L��p� �X�ɠ�7�x��5?њ� �7L�y>���w�&ѩM�H�#EEE�}���yk4��]��7������l�G��rswog�I���=�\��jg�U��0ߡM�`!���)��0C���Z��F��`+�}v&}Xk%��Xt����`���yp$6��$�@������;���1�~���Q]WE�+P�q!L�e@J�;�7I<���K�8��Nxnn�󚴩�/׺���`��w�J�M��XL���
(�Tȝ[���=MJJ<�:(T T��P�pI�O疗
���-+ͼ(�
��Ψ˅�|���\!$�3� S.$��H���9-L�<��O~�K��������2����xvs8�_a���R�F���kf�:���צ��Y'&��Č��`g��n�Md�&�#zO��y�AA�3�1��W'鑴h����v?d*�-����;��Ln�_2���#�JLÒ�a��6�0�S�9t����L�0-�]�C�W{{�G;�-���!����i��Rn�=ù��K�8��.�I���DCQg�93mF3��@I�0�����������8�,��Р�����ջ���ѳ��fՙ�Tp�f $TΠD7��Y�K >v�rf�_i˲Ƨg_�3��p�L.�n� ��%)���`i��l����$���A�];䈠��������wgZ����H�j��mc���f�F��a���a�R���"U��e: ���7x,;I�n������6���u��5��y�]v��1?K�݄�֒\d1���qPe�?�̺�3f���nX��/TTͶ*�ϕ�ǌ�K�m�|P7�.U��|���*����,��f<s�]�$�&�<�no�Oֆ䠘�=�A����.����줞kn�c��,?�TnX��6�����+���bU�����x��y�����h����xſߨ��;��~��o=a���n���f�����j)ze������_7_]єj�W�
^z[���[���"���O�XӮ��JҌ�{h���oh����4��R�Xp��*�]X�@�������y#]��O�i(ڑO�4r�  ������3�ȯ�a�Q�6��Z0@P�W���j��8�@q�106�ݟ8gQ�v�y�C�	��x�B]5�)�;��n��@9��}J����-�_�0�M3﷬7Y']R���'$Y� �&�.�"�YV��aDY�w�sx��/���5�SiM�,>_�O�Þ�A�WT�Ng'S��#�(�Nx�/y�k+W:6�T�o�m\��7TS�U鿦U��JҌO�{h���o(�������J��<mޭ���|z��譎(����������8 ��-����m^��9p�}�=��Gw{|t���ς�f�y�ur9=#t}��"r W�|T|%�pn���h޻ޒ�C~�{��������F�P�sn%���`��gs�	דf��f��-���	4a�`1�}=mԓ*3Jmd�T�-�0(+$�Y��+_s%X3Ao,�͗�ǊM�`n�\.�mZ��/�%�w_o�)��s�R(`mϔ�_���q_��E���#
��5Y�dU��NXO���X���^&�]�k�Z�.�CR�`�%�����Y��	��#����#3��
G#��%��s��C���NX�G-��Q;^�%Y{t�����$��DfQ�[HMG��������O���I�Q���Fac<	��R��$cs4�9L��R��F��[�;�����u=���馅��mW�+I˗c�� �C��~�F�/�#B��cB�)��t.��Ddo{�%�N���Y��<*j�9� �o�Q������L���8ք3�g�h��fg@p� ���� 	�T\����7�.o���9/h�¦u��������P�� d9:�)6���r�wk7��r�� '��3��k$��A<�����|��Ш�tb
�� �7vG>�L0f�YH���95�B'�>��:�P�+]���i�G�u�Y^��q7o���w��������� T���� �^8*|�e�Ḑ�G/�3�����%�I�	ߎ�0ik*1��߽����}9:x��/�������uٝ(8R��w�O�������c����_�/�͟~��9�}��p����ι�v�L�^]^~��u0����7�z��yǡ����G5o�!�b��K&q{I�Qx�0����� �����A���"�8�
q9k��c|:	����=�7�'|V \��������0���Vk��<fS+Xđ��S�B�{����j�/�5�/�}V�R�i<��1g��|�$b�,�7J#~���nK��z��/?����i��g�������/�G���`{���l���O������Fѧ��:������W?ۇ�oZ?�7[�[�������/�P�4b��q���J*�/7g�/�8�,�)?/�p��,/�W�̘e�O��%���1r�[W��Pd^��@�4���
n�aC��./�n���ț�y�n�� /@@h(/���3� �_��>����<�k\Q���ΐG��;Q�w�m:D��Y��R�n���3�3�Lt:�1{i��p��@by�O��oC��ۓo?]3�ݝ�Xp�c�Vj��*{�3l���YE����>�/�Jw�׹
Ҕ�\a�{��C�2��(qq����>E��9{�j2�)g��x�x� �1"�(�&r�A��8�y��Zz�W� �w:6�Ð_��n���;�E,�~q'�C��l��p3qqƑ�1L�~'�1&}�p�d���L�c(��7{���>��2�֯I���ı��u�;��A�h���`T�TCɯ�!�[�OX-^'zUˡ0�J�c��\��<�=��H�%�٭��q,B��g��^�^���?�b�xUkjM�	�-ו^����˿�G�R��EG�s �v/S r¼jJ�L�=~3k�B7�7&z�`���]R�CW�۝B�^o��Z�U�>�9�;���f����'�f���)&z��y�n�p��lQ�Ѧu��Dk��	Ʀ����_Z�������rł�O%���n�J��~+v�:d7#u)��-�䘖�E�RBt��E�+�SE�͗�'�UZ�ǝ��wn�r>F3 f�͇�K����#�n=�-.B�ÏtL?�Q�5����'O�y��$��7�u�$њx�g�c ��`�]�\��s����:��벜;�n8]�f)];���X �f&�����[���JR%��}��sv�CVRY������lN#��t�ܲ,�pb��1��\�@�����f���앟��)�5�/�mn�,�`�L&$��A6��#f��[u�a$Fu�Bt2	sR��Lk��)��rI�X�M��*I��}�J����ك
� ����:�9
<�p��$�Iʹ'}��j.,Ļ:�$��-�%�v콋�n�������.Q%7��|�$7+���\.��껼��f��D�W�:������J��yh���D�6q�?��;� �T�W(�b�E�+�.���<���1���`Q	��ÜQ�=�����4�@�tG�K4��+�;}��&�'����f�������U���$U����k��]��AdG�H!�_T&e6�Ɗ�sĢJ5�aǅ�S���A����%K>�ցW�\�=����NPO�D�F��p����d翎���V�+I��/��x��}�K��4���_��dOn�L��/��Q5�9�A����|�
Y8����㟘�$g&�ds��o� �2�&>��)�r��Ui\��ݥ��}�����-�D�Os�W����u����r=��W�x����eaR�9�a�l�F��p�����Iz�]�0��m���,#R��A�\��q����q� A���+���4�D�\b��(V�Y�W�3�o��|��+���$��[�!s����R;�c�T�D��{��>�	Z���C
"��I��P�^��\��S`�n�I�c���0Z�田�4�6q>�̂�J�Yd�L�.���G��D�����cݢ���(�%GJ��tܔ��s�5^�"*)2%,7WF+-�e=��Q��o�r�Ý�YX������ZLWM����ܢ!����U��L�3��V_�'Ó�y_��r=�+�orI�4aI�m��#�R�3�N�C��p�#y��	@���՟p]�z�$��Z.(x��7뎧v�����I�4�hh\F^��e�x�Ѳg�?���i+��T��F���"U���p��U�k���*�����������[����S���ߜ�߻(�-�������a ���[E�YU/e}�;��?(f���s����T����y��&x���m��g��u��L��+�7�O�9�[�\�N��K��Y��.X^����q�~#~Y��Hj^~P�3��P����%vj	��.]D�h��v%h��4��ǸP�0ޛN��{Բ:��u�rѧT�H�+����)��$S�L�˔U�vҵ�?������Y�/Mg����W�*�o���A|[���(`��	�]:̉�q[�e�f@]ÝC���@��*�;��� /h�'A��#9��/�Ae����f��n�p�KL�Q���$,��?�b������<LQ��S�3	s6���:#�AA��=R�l��4.�F��A8�I�Q��º5FD}�þ�=}�|ҧ�M��gX��N�]�� ���| /fAc�E~�/݅\�C� d��f�C�{�{2pH�{��U]��,�}l��ƀ۳��a%!��>l1��`��Ñh���~�˰�}����6��qz�M7P*	�-6�{�N��l��ֿ���)F�v��9�6�бZT_�d+	�\�%�
�`呀1W�YSf����}���:N:�����d�`��)�7כ����,ٛ�7F���&.m*�5�L���2����E�߻<��t#�_����]Q���E�+�߇��_��Vo��7�ꭶz�}���f�}t�_,��X�������E�uE���U�e��E�ow x��x�ã{�����kr{EfO`<Ѕ�k���2xvS՚�Q`��pwq(:KXg�vx����Akjָ�	#$�>e�jd��<	�S�ٜ�0���.�j���>���m���}�"���:#�'�^�Y`�6W��
�����բ֟�:��z��N�6��`?-B�p�!P[Q����r��WU�����ZV�]��Nv׍?Q�v��ӎc���n=� �Qm<��qdg[WpQ��)�u�0��$�<S +�/��9̊g�[,�W��F���ά�q6?��q����S֜�8cPPU��w{���Fx�S>޽Pp:�TK�{O�)Y�lNx�l>����"#dn^���3�F�\��,���Zwf���U}��z�i��g���m۸������������T����~��*���UVw��.���K�V�?���I�T�?�c�S�����_�Y���Ӭ���p�.s����6��*Ȃ�U���W�*�Ot8/���߀�7��
�01�q��9*(�xߐ2H%�])�M*!�(�,��Ӵ�3�Ћ�a�^:w������ӄΉ{��>��L�+oA[�BQ�#�e�t���Z9�OU�c���y�/_Y t "�|tK��� `�n�K�(�E�l:��6w0s��͉nײ�G��;��E�������+�%�2�_d�������u<d�^�#�f��/�h���f�S맂YѬ� h �}:r���o���Dπ{���Ɨqs�<_
+������q�5&�ͭ�G%f�sƐ�od&9��g*�� b��&W[� ]� ����Oρ�l���<3H��s"&�_i#њ��z���4\z��Ɇ�ytW���%�A6��	�2;�1�)��;�	6'B�](��P�`9R��M�x3�`{ŧC�^ �ѯ|�����lJ�f�����;��`�Fdsko-����J�|٦\��5��I8l�J�C:IQ�!����x���S8l�4���jSk�����iZM�i4ۊ����?���;�x�dַ1�ӿb'�Q:�8uG8ub�D+���}�;dt�OO���>�w�@W�:-��	�u��E��~��|3�g�e�O�>ؙ
���3�J�-Ơ`�;����w�������e����_TͶ*����!�� �C� ���א�N�#�����?d�.�m��6L������0>�z���60�s$W�b�hg�~A_A��s�xy�[��96#��ϖ���m�@�iL��	L�f�u�6o�(ؗq|�qD�n��`t�~���v/F�󹼝ܘ��3���:`���'��k�vEw�R��(u�����h����6�_����G	� -uq$�;��B���\߲\޽C-�ݫ�{�Ad\S���ǋ����6�1��p�q���x��|+l8��a���g�3ކ�����g��>�7tJ�sǏ�1p�!q"�z$�F��S�4a���q���2��l��Q?>m�@Wz�����ۤDi�7����TT� ���hx�(zF7�=|�I�͆��$�ߏ�4n�b/l(Q�� (0�o��xC��C�YC^q$`�g���a��m���W�I?�b�F�E0�V�N��Ƅ�k
��V�	���.�|�G��G�n�PG��Waԭ0�����?0�t�D>O�xR�Q��,�������%���#���a�~�R�28�Kp2�0�|���o�c�#��/�}�k��=��p����l~L�4��`=�+r������	�~�`a�ɜ�GGӅ(���o�}ݺ�g�l�h�m����6�����r�J>e�?��O��P��L���Ƃ�Ͷ��&���Z��U�?�H��gr�8�@�;���IrR�J�"4�A��4��6£V��y�2#��C���Q��pg�H7�!h��7�%e4����Q<�� �Ue��;�)Ao�����������#�Pd�!Kq�~^�_��T��_m�6��|��/���ڗ�m���@��w�uo�6�H�vP�¨A�ۍ����n�gQi�G��v�Z��N؝7������E�+�������Ϙ�j�Zz�[��i�fu��"-�Z
�Yqp���\����TX�99q��t�Hs.�~F|�����3�tt���/��D��#��������I4f!�W�L�S���@E�W�*�����/�����$�.��gi�����TU���[���$}kT�[��[��>�.yY��{��˄į�H0	'�$���d:���D+p����v�s��ّ�����@E� �NI#&/���H���o��Thz��{p�}׾��Z[���� &f0�&���Y��d���k����n�[כ��7[�;�w�m~�����J�H��=�;1�S��Y4_�T�ҪR��a0�O�Hx�����������R��0,�@���]���$ݛ��� `_�'kp>r�̠���z��$NL
�䬓��T�&)�jS)2��#��dɾ�Zx�Fe�&1]@?μx����a�(�0r��b����#�?�$�!�#��h�w2N5m&��Э'OYO�5ɦ�� ӀZ'�I,v��Ban�] c�ҐAܬ=Εf�p�a�_�y#�=��!�Ƴ�NZ�h�ܖ���Uh@�^a�y͒J���e���X9�O/���ߊ/�/j��.���3g4u�W�X�Š���!�%+� W�Ѝ;X��ǯ�m��bp NGv�Y{��;��p��m*k�AL'�LR�E��_kGcڍ@hUu�V��
w,��T�������vm�3���~k1{G�=�現�x�p\RYZD������ӸG���(5hf�;��qV�/^8�B�~�ug2	'ŏ0fAB~e3E�ݳ�00��dj~Q����<� W���EJ���h�����mV��+I���t����z��w��6A<q����16�}~���V�Ed.c:I�#�Cq,��~��QN�֔Y�-�R2eD= 2����>9���>��p
l�a6���BS�e���MhX�!x�� ���ӡOFa�4Q�_t&P7^�`6QS�|}t��!_�����8���o�,�&��=OB��&o��摍3)D�ω�K?Ђ�9wC֠�2�pxإ����mo�d�w��z��ͣ��7 �RadC�ܜ�����[{;��,�;x$0lG9��LYO�b��Ԛ*J���N �)n�$Y&�	��ԡ�����0��H8:@gg=�i\ϿG)��#�Եԕ���%�i�3ŀ�~<>H�-A7Ƌa��0�33�`~[g��O΄ʠ_�~���h��"��o�ݔ;������eE�7�l)ќl���甑�ym&׺̮�v8#z�u<���aq=�P��`�2�	%Ȧ@P��p1�q�iK���Z*%�k������{���� 7'�x�m,��U���f��[L�ת����_v޼�}��k�Fc8(�~�'uզ�����j�����֯��������?N��V��N��n���'�����������t�L�_���҂�o�j���-��C���*R%�����,�o�?��M���p�D��@>P+8ʋ@L�9�N�K!��o�
5����՗[Bq;�����6s�0:��,����ے�y�.����c^{�d��<�u�S���
�����]{?���Ӎ��Z�B�_�ZR��O��5���d_�n�K;w��pE�S���������r��n��ȁW,�y��r�T����T`8�f%C7�r�GN�S���L
���!0��!;�5�l6��o�w�� c���7/�;!|%^]o��e���a�����q�
(%���yx��� �`�I�tB�1���e�,����x1�l.Ӎ����f[�ʍ�)�������(<(���B;��Ew�Sv��\��0w�z�����������i��O�z�H;T\%�3q;�dP����x%��k�_��w�ZZ�4)$m���}��T�.}mBfK`�r�p͖��\)�Q�� J���e�*�z0�[(�'Ri���|f偔䦌�H��q�N{�蠴h��4u)	Jg�?��i�"Ƨꇧ<�_���X�����)��,���- C{{ pv��v�3$��39-����4��6��a8�:�8L��q��`OҬ�g�A���8Љ'ϡ31zl���K�dؒ�tbbp��	���\���@V�ެ:ŷn����o@���A�n���7�SL@����� �<H0b�M�
���9ZLS��3�3�kgL����¡kF�b)u�(�
qJ1Yxp��� f�eNB�Dӳ��tr5=;s&I������̍M"�EY̝,���]N�I�%��'��5�ϱ<���׫���<�o�*�p�3qP�S�[b��!w��W5���U�����&>�5�^09>�5d	O�\�K<|��W鮩\��	FK�^��5)�/~����W�%���-�e��-^��W���E��6x��׺]��g�<&1a���7�{�����B��^u�g���}�,��u#��`�:��`��������|~����u#w�s�5����y@0
2��Y^/�4x&s��f�<S
��~�6$C1�x�H��:���۽�����|�~�Y~�if�7O�w^n�����7���״��/���_E����/�����X���뷰 )J	H��?*��c�v���f��,���\�,8�u;��	� ��ۖ�W��*R����3h�� ��rC aޑI��|��V��#��W�)<�t[��ek}�~?ʱ�v�?����\�-�̅]�7�`��:�~�H�mw�`��v�$5����C�����Y�D��V=�$K��s� Y�M�-�3��:�X��PǿV�	�8�T_�s��]D��H������&f,��Xt���E�?[U*��+I�ɓ]�<Y��電J�]����^	=�y� @�*�G� ~�Er�\$����X�$���-���7"@	����{|��ź}~ADwk>,��ua��>b�:�N�5�� ifM
��8�;��_E�[�7�9Z/��A	�y�z�%o��b�8�$�|@C8��B�o�k�*U�JU�R��T�*U�JU�R��T�*U�w��?h�-| � 