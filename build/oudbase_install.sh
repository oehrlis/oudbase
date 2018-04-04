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
� ���Z ��z�X�0X���8E+ˢ��$/Y%�]MKtZU�Z���:K���4	�R��Vs1/1w�̣ͣ�O2�� Iɖ���ͮN��A�-N��4Nڿ����o?V���wm��+��p����'ߪ�u������/=0���i��P�4Z���~�y��I>����lpӛ��V~��X��O�=������o��?z���wj��������~�F8����j���g�E8�s����^��8��\mG�(���d���z��$ͦj��v�����,ʢ8�fa�Gj�O������Q8��f�����]�ӿG�(Lw>��p������?vf��4�{�h&� :�F�ZM���rz�J�ٿNeZ�tow��m�q;��~7����Z{�Z�#�r]�y�&���p�M�<�/`�T��œ����,��#'0�)�
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
9\~�+xɒ����Sڐ&�����$t�|��tm�wWq�� �9$���i���a�/F�5����e��t���ԇ�M�c�u|�|���&��7��������l�o<�9����T��,���<�&C�#����^Nh-��/�+S���0�}���t���w��,�������~����?~��w��~������������u�X�O=����k��?,����'O����k|T��������~����_� �P�"AUs���\����'��Y���  �`r��g�S��U���eE�����H�J��5���[�;��7̇�4;k?T�"ʮ�!�x3�8�N1� s&W$��ڍ����)�C�n��e��
o���Q(?C��PОS1 69(�h�^�͘�K��,
� �`�chh�(au�g�Л���a��(��C��K�����Pd�z'���]�ҝ�[��W����ߝ`����)�s���c�lXX#�����@��\C�N��xJ��B{!��;mӥ3��i�x��fa����cP�39$���bծ�,7����Qt�+]�H���� 4��r�C��j�DPo�!���9�%O163+��N&#4�S|)�+L�d7p�0�+"ɖ0���F���8���F$���j��s�B�&��	�����p8�f<�	��弔-����x��4�d1־Q �z�>�(o�)W
�P '���B�I�X�Z������E �.����0]`�u��"f��AD� !UڢCK/�!�1O�W���Ʀ{xw����!���Ӯ7gk�w�m��(�pkX��L��)f�Ѿ��i7���p�E�?��!vx��p�p�_�q��;��N'Y�T�F�j]��Nq�!nJЏ�iHy�Xa,�O�Q<��`lT�K�*5(�t�H?�����ex0,|��v�͑V�%�G�>OF w��Y�ܞxX�s��:�+�hE�t�a$�c�T%Qe��&eb �Ls�^�+��K�5��G�
(�!�t��u����J��t1���]�Q�o�*�!^�L�W�ф�I�GGԠQbB{�[�^��8�L��I����ޞ�M��0����61{u�k$��	���,��x7�΀8�͉��m�;��DQ̮s���}6M0ɻ��C���	S��̀�a=.$�މ,b��3C^rE�@���K�;>�c�O�����v�E�9��H�{,7�[tRd�(�*�*�EVL�Ā1n�IO
��6�Q%Q:�aZ�x$��Hb���G�֣+%�~Fj��Ra��Y�C)��#�%Ay�Í/��-8d�/v?;�&���� � ���)Q����3Q|�d+ �ɝp8�vè@�)@��0Iv����i�ʯ �)�+ �pnKN�H���,#�ur/&]J̢HO��c\sx�Iܧ�	R�<��_2^��G�}��N�h��I�e���n.�.�!�(Ed>=)�.��"����j�*O���&��S4/`����r�4�P=D+�1� ���$�$�����3�]��{��Win��@�Y��'8���P@�dszN�6\'�i*#�y
N�g�{X�=�B(ڒH�n NS�I	�ep��C+�q1;g�.p������}B�4
?H�=��AG�"�9�Y�MI3n�Ģ�K�f┠A32��>�S�Ҁ���y�I�%�/K��p�45
tp
���r�֑tטW�c1�� ���pĜ,<�l�	��j.B?��Ÿ�u����^Ou������㝃�6^kaݡ8���ڱ�cj,����S�М��R82Ze�n�.`�]s���K��,RCG�n�f��(�c\�:���̸#P�h��a��o�$�5����v�.�y�G�T7�Τ	k��lyα�5`�5hU���F[R�BMFv����8/��a"a�F �1K <6)� �3���@5't��Uc�}�w����a~�5D�a"I�҅��T���		���%��}�J��g�ώhpq��.`%d��ɘ�b�W�4Hմ�F��h1:��O��g5Y�(���JL���x��%?�E���Q�Cq��&�%0$�N��D:�c��%�@" ,#�c
PƑG�����}%�;��w�
��}�S�Gp�L�Gަ����g>�DR!EA<��B�g�2OD���0CCG����d�LS�D<A�Z.�{0���* ejR� 
`c�B~z����h42;kt��)�y���6D	;�t��/j�JT������G2C�r].E|�RAh0�)���!��$r��P�iS�Ǐ鹄����"��Hh���	D�3a��[�K��~�"G^D'"�1��]ټ�{Lb�Q&��F\C`�F)B�����
ӷE���7zF0�MbuLVi�P/�tUVpÝ����L�-�t�	lNĒW�`\K�5[ᑒ����xc����a���z&XA���F��2'!q��	�e�k� N���.�8l�A���q���1�_3�A���R��B�S������DUv��h�*mX0Υ�d��c�V�0�ȔN���#x{�P��bh����a6P;z����B�yd��o���(����t���!��9��YL� T�tp�֋�^JJno:ʝ|^$:���(4ֶ1.���Yx�Ɛ����mt��X8N� ���q�DY��hv�z�� B�f!�sG��V��3j؇����Vj��jL:�U�W�:[_��^�6��й������^�,���41fq�,!U�"t@��9��Ӻ���h�aY�	���v��$�R��ţ��f"��Uqh�xp Q���CQ�P��X"�Zl�Za5A<r)t�~�kW�p8�)�j�������w��F#$�� ���Ҁx
Ϩ��y}����^h {]G��d��c��y���>E�VD��F{n��[>m@��=��m6��[��Lh<r�0	�d�F��`sJ]Z��-�<C��+��:����M6զ&;UFxZO��R�W�#Q��� [�*�D��a� ��3���σ�q�E-*��4e!\~�`��ڨ�q7m�:aU'p1�d_2�����Km�`i�����~G�0z��D54�#G�q����b/�.M���=I`c�l쥻J�1��	����٩YS�]k��Ђ�V01�5�Nћ�rLQ�)��,�J,���
C�-��H�y�l�q��x�B)�j�W��ue��CF�צ�,'�Z�
�n�"���}{�����G�H��>-�vf-,����($�Fv@/c�y�!��Yqh{@nS2Dj?كQ
�Y\���hY��
�C���]P�h�M�����4z��|���q�0|��-e�O�SPZ@~�]��	1���!Ia��W�r��7RC����6'�D,��c�t6Y�/�v�^�r|���&�r�O%MB <��sn�����	i���b�L�0�	�R���j��D��>뚙���P>
e/���-�EfI�1 ҐOR�F��B��	���B�єy^��M*�/˂F1��l�C0.��B�JD��Q���lWO,YÑ����<�� !�' /*T�I+zdvA���,�	��D)$�ev�p������X�A6-���k�L��J���:���Ѱ!���."�A��ƦQ��=�#�|������f��N0G�$�'F�ha���	� x�puˬ�;���g��X��"EGPb�7^��D``�h�T�G�"�	�^<�S��;Y_##o��,��1H|�B:������J�ؗ�<�V�-2ځ�����<d��"T�d݁a�(1i3lF�<IG�2�-Crc�5r�Bp��p6nN0R��i��a����sx��)�� �Z���XS۰T�q�Oz�g*ȁ�JE�X�"UŤO�Do�ף�ۈ>`D|Zɾ��0�zSW�g	�F �i<�؍�fJ��|�	Iޫ���3A�5�Ǆ0B�+�#!��A�2+�x�4�	�L�e#ӊI5���U�H/d��j&H]I���·+�l����>Ռ�N�}YL��Y�ҦիI�����7:>k�j.��-�p�	��{"3�@��0-ְxpX�ٸ�L'�~vʒؚ��]�T ?G̎�^/qf�]OJA�C+wȮ`��"�1��/4���\hA��Ʌ��D�T��Eq!A�Z���`� d��S�\�ӎ+cs{J�8���>Qm�V��f��f#9���X#E���odFvY�MAA"��p|B>�P�=2Gm(��6&����E�=-ۉd��u��ε��U�6��1�s�")z/��E�\��$"
�����QƊ�+7mh�2�M�Ѕu^��̾v�+��D��Rq	��H HHlb�%��x�I}��]2a%(�J����rj>�V֊�|�Ee�
�v$�a���*Dz�qBm����D�u#�eXb@�2�	;�8����I��m��eEV��\�y�:� �>� �0��&�<X���^J τtM=h�.��L�(ImȖ���`�q'(ks�e�"Ty����}_s�Rk�N�dx%>{k�a�L@��
�;a�JpEj�VJ"z�����K�A]_�Ac����X)�Wc�:2�2����F�K�*�$2�i	K�
]r���^�g���A��C�8����FV�e(�^y�r����h���7C��R{�n"���#O�!��C����U_{H�Y�ō1zV���|FTv�5}��f|�OHE�	�7��E�Ŝ�������]".U�;^j��e�6��hFL���` �����ߗ���4��K�:?گ/J/+2�zJHe��>�����M�r�s$��҃�}ZYA"�y���}V����͙�K}CI���p@&F��9Pf\��s������ib ѼJ�X���H���D���qX��`L'� ��6$��C��*'X¼Ȫ�O;-*p�� yo<	�Xە�JT����,��j0��~��3@�`�=����d��ူ*�gY�?t�!�������"����KC���WWQ����iӱ?iar��*�k^G�d�5�T@�@��0D��\\X�H�J�'�ry�0��n����2"��������9>4���$w��㔣�jG/O	8a��u)ק!�~���
C�mX����E�PGX���#IE���C]}���:��p6���!y!V���2\8�PV�_)εQ��i��$��:�.u�`�a�#,QGE(ڮ솰W�y�9<F��p�S- >9�rќ�*�g�#Y~�̐���t�N��b�>�G�EK^Ak�vv}ᆋFŞ����ezȝ��,c� c3*#'�b���
��L-s��D4�'�y	wsQ�G���q����*[����e�֜+�tF�C�]�n�r9�o���B�*R�Z�[�0����eT�����2���-��U3H2�I����ސ�����MҀ6�0&��:�Zb�eX�u�������&s95��S3#��$���4m��eB��
y��������Ux�}� ��l���i��vHC�I��:F1߈�퐉���!w4r��� QO@'�k����6���#���s�4��8��7�D
�0$4ƣ�<�FCq84��1+�D+:&�)�b�(���i��"8[n�Fڸ|U7^���60��<����Bpq^�jϱqys$��8�zȶ����a��$��q���$C#=���M����t8��r�u��IG����"��E�<�3�m�FP��˞(V�	�B���j�Byq���jB�b�Qt�^&�/��y�|4
f	�7��܆B�'A$��
pSh`.�%oQ���������4����a��#+��0r�Y28� ����f(M�R��j�w�h��	�'�� iq���l6�$�Q���E��p�+�;D��o�1'Bp�Jyq��1А<0]��]t��˄/��5�8�NdD�x��"m�l���x� �a�}�	��Kt�7<�
�C�"�g�4NfH�6|�A�8�@SILHM9tQRE�����š9��<�H���A�|�8� ѝ��DKJ��5�j�/v�n=7*g(ٴ���kc�i�3�@73NLf����9�12t��6�d o71�E"�gD;���D�Y<�2ri�4���V�7����H����(�da<o߾��L�������ygS�g�@r-���C6��n�cƆ{��� v�@,AI�`�Ba��=[���k�����=n�S�;ȼ��`�n��;zԼ��#�  B�2�V�Qv�pt�="���86B|?tf�1�9S�]2x�T
J�c�9^�Q��@�"�"2�\�GI�	��*M �vg��EE܊Ƚu3���X.�tD�x4����δ�эCa�6�.�gi���$Dc�Y`�0w��4L9��Yyx83�^66�e��2�rTp@�#�3<?`8(Ή�J�k����4�`���N�t���=��Ll��ַ-����2Ǒ6�֜�����`Y�� �K�tɼ���g%�3*8	�����~�H�=�rkՃ��C�@��I�M�OL�;H�j�1#��fӍAl�d7X�5dy�&�Nl�+�<aTq��r�[�u��Ck����M�	$Q���M�Q�q`���bt��3I8}!(��`�3 =����acUUhN#�����E8�0��d��©�(!�#�:�y�rK���Y<m5�q��/J/e�*qR����K=�B�w�n�db	��ņ���.B������}�K=���2���&q[S�F�Dѡo� ���.������8�Q�<@���% ��eFvL�QFT]�O��]_H(�0%��:?�% ��I~��-�yQ�L��c�����PSr���c"��O�cx�2�vB�tSR[�þl
�c~f��	{a�(/���@�ku��fڶX��j�,/=��P�Yَ�v��:��bt/��N�ŉQn-���m���8���-Z!�:g�.)m/w����	M�%;�A6G6[Τ�J�xm����������օ�FG��Eu#�b����U��2���8FQ?ȍ0\�<��m�ʥH��>��w�b:�ǉVgg�0�[&�Y��W~�R�ܛ�Z�Y��m�ț��ykm������m�p�� ��Z'Wn;�2T	�$���R����K��� �r� �b�	�l4O�|�t�&������x�s�����#2������� 8��%Qz4w�9Ԟ��PDUX�àռ����E-p��b"�`��h"�:C٤T�Ό/0 ��$@���(sj��~��b,)��;Ny7�֩��{��Q��F1��ޅ���k��Ი[�݀�pY(�L�	`s��2K@; F���5$�@��:
:�g�O����ld�N) �9?i�D5�@%!���)�N����F�#�����Q�l@u�2]�# Ӡ���E
J��=��|4�1bkAvN�i�s�&�� ����S����a%����Sx"���j/�gYMe�WEK�8'ލ^ RB�� c1*b�B�mru6}�r��Hx��M��!�ߕ"�T$�,05#��ꘪ��"�X�Fe��X�ɠ�ʨR�����A0�?v����Xr������ ��M��P|���.�G�Cve�a�	�O�Ԁ���Tv��1��n�Ҫ{IH7Z��YDgN�)�7h&q�;s	�ϥ�;���oN�qd���&�@���O��i��qAq�6�?��j������D|�p&Fq�A�q����t�|C�1��S�+f�"JS��������(Φ|�[�����,r�^Lݭv0�᤽�������T��0��:*!0\֋^Fi��O-��M�n ~�=�g��%t����e>2P���U�@�`R���d�;I�fȡܦZJ9䐬�$2�"�..��4X� �a�x�xy��l�Ur�Q� o�Wz�@FJ�'�?�� s^HÌ$�5G.��}]ђ��*6��$��8Sc�Sy�K	�	 �B�]�ҹ�rCrGs>i"��vz	���t��Dũ噓k�{U<��T��e��(I�mi�-β+\���g� ��[X�,Hu��E6��2c�����e12�[c���Z�Py���K��G����N��WnI.���~���T'G݂ʨ�P�e�(;c�q�}}�w\�A�q�:j+Q��I�;;��\�2p�D��b�|p�	���G��s�o��v�_ݧ��ʢd399A� "=`��%Ί[�x���@|�p\��X̫��s�`�uΘP�	��SP��P�XR����C�*�͢o#�P�r�y�4C��,��#˧��y��WB����ߞX����W�H<e�B��[v,�q̫�t�Θ�t��Ya*���,L��&�A��SD*}'�����T��3����.�-�X/H�����i��F*����񘢛�����~l��d����ԡ.k�K�%luL���)��x��E�r*���v
�y�bmNJcc��y��6�M��!
2L8��M�=�C⵴�p�e/�7�q �'8�8��a��F\�4싐����E}���9�#����$p�0���kRr����d.�iq���UFB���9�� XAP�g�*���o>сkx�	�b.��tT��l`�6�J�Q�;�N��Ec�]NML��g* WC�{v9�ӎ��B�k��X�0����:M�������p�ppI��½�����t���۲/\�b�H½���!�t�'Fz3�b��]����O��Dr��#4��:���x��7�/���Tԗ�R��=i��8]5e��$K�b��w%!'r�e3��s��d����h�k�������҅)�)5�9V}�lK�Ҩ�&�ܪ(����eT`Ԕ8b<)�������.�� 0�ҩL0�M���Ҕ$�c��@�48�R��(lI�$�51S�PE�������6G��,��@Ut���a�P�Q( E��4J� �j!L	w�
c*��>4=4\�܀"��L}l]z:�j�шl* V<�kYt�Bc�O�)Σ��+2m(���*(N�rP2o�̓���m.<0N�ʭ�7������1���pK�iq�@��;���$��0����aȩk�0����b3L3��2��\G~P�1�h�mN5 WA&�#HgZׂ�	7J�3�������X�FG�(�Ut��fJ�h_36�0�����j��TҦ�
,��7x�q^0a3*���s�����N�jS�@�Nqa����bb)ivU�;1Kx��b0;'z�#���K^T_X��mQ/[o�%����bC��p��ZH�W��́�J,9$�Z5�EO�t*����%H	"��d'�p� m�	��Ix5�8��:��*�����U)xŁ�BV
5�����Y6k��T[�+Sm�+�mxmPZ��>E�O�I�T����H�	����U�����������?>�3�@'��R9�3Tum���?�E���k�H�ي,�[D6��t�d-0����\�F{nX����^��n�i:��<֥e���Ԡbr����D�vBuHA� H�<0�ش� ��1�xu�%0h��1tٍ�4fw�ө'*���7ZXܪg�1��>@��}��k����V���&���)S�Z?�rv3���G~���+�b���A�7a���*�ە�o���5���ﶬ���6hB��<��:�,�ǳ�4���p�^�2�g�%Rt�Z*h��5a/%��k���fT��h*�4��x�'�����*�uA��*Z�#Ȥ`��9������B(�d��uul4�F��$sх�JF'G�0�C�љ:F�Os��?laD��2�^�j���)>)���)�;�HX"����ȻyB�S+��X8|%�d,��.����_(\� �1�!��w���
�cR�JD6�q�:ֺ,��`v��8�R<P?�8l�)�o�.�bq�3ZY���*ƗG-u�ø�D��K�.Ӽ�9�U
�eM.�B�0��=��B:g����ÿT��؃���m]�+$M�,6ټ�h�^���(9�_`FɈ����L�s��ĸ܎�I�'�WF%��iS�}�-�4�_�	.�P-�b~���*�UPX���u1	�Z=ͽ�TߞRGR��α�̹rGnP�G��u�hL��Ro�7��8#��:��믨�棐럧�K����Ɍ/���ך��#,m `��+�a~A5�h_Y\D�}fPAHྎ�G��s1��a_�S�.�����5��%!����ld�6T�[f��gb3q�%��F�nܿ?�����P�0kY�ӊ���u��%��� �xH���q˄�3*� ��L�^u��j�����������������?��5��}���qw�Xv��v�����ŏA��pwg��b��v;?��I���=<V?�����N��z�|ag_�p�s���=�:8��h��W��������PՆ��Eu�9:���pov���T�Ӄa��;ǯ^��/ȏ�;����!@�?<��z0 ���#�;�[���a,� ����4;>h؛���q0 �{��
�v^����z�Z/w���Z��|��n�(8|}tx��/! �?���U�da��u� ��{xK=���9�m��^#��y�n{���U�ݗݭ�7���nz����޽c tvw�~w��9�Q��Gov�h�����#\����#�r��h������ᱫ���b�#u� ~���ŕ8���k�+b���w�?��B;8����3��1�
�`�G@��w����Eg�`�M��^�
��E�΋\�0�� W	�m������s0����v�v���`��j�sŭ�Du`�"'�c�"�F����]�}��R�����qGш��]l}�݇��3���z}�[�0��k8�;��8_:�;Gہ>d��/;;������=�"HB@g'�E��p���K�j�l����lŋ.4�l�١�(�� wdM`vA֑����-�Wb앒T\�5���Ɉ��#�m��)�����F?|F);���,,��B���.�!����%@gX�PRx):;�c�R��Ė�tGB�M�4OG�?O��Y�@=��G��+l&�fI�� �X�/�Mwfh)�Lѥ���e]+>����sn ��W|�S���ù�uh�����AX��I��!]���J����i��<�(�1Ν��e�rK�ɧ\���ɢn�@�/O��l��M4��}�E��fU�_Һ��$�b�T�1Њ�:u�H�:&p���y8ĩ���c�$*ζ� "'̞�kɽ1��Ě�T5�$!׃�쭫���S32M�e1��IJJ�t�����v��lQ6������5ޜ���)�H@�fq4DJh�����\�i)ku�����tϡ��������ת�6���4��{�O�>(.���(.�����/$�g���jLɴ`�(8�h�O7��5�V��y����ѽ��tHg����Ң>��5� Zd{j�j�����OK�8�(y������zk�a��]�&�Q�p��D6��u�K]9��]KV�1�!RߝO���v���u��Ziv�����0���aҍ[���0�$�7_=N5��Η�	V�»B�	F���\F9q�P���Ɩ��r����#�rF�W�eca�)�m�b�n�^,\#)��I��o|Kxȥ�iM;/z�����?���S�S�N5������~˂+�g�:��G#����&|�MR��$<u���w�����	��]��-�z|4�������t��αw*u0$A�8�-��]c��d��ڧ�ݿ�c��54��T&����}��Mʐ)�C-���uz�b��� ����N1]�����������F+�լߔu�
+�Ώ�Ƨ���ٹV�%4| Z�9�x�6�`�!e��JcL>��"��W��{����+���Ĳ���\�u%�v\���:��b0y��"	�9���(����!����Y|�.u,¥����:nd���y�=���A��K�P�FS:��Tn��<Q:��_�/ϯ������d�:��G�;��g��~������ƃ/����ړG���������ϣ��O�U�7���?z��ƺZ[��x�wj����̐��P�4Z���~��(��?��:x���E�1^�<@���r��7�M���\�����%j)�r�)�n�$��ܶ ��`$�&Qr���~$���G|G�i�����x��>H@�:#[0�2��}��!ú�N;9���FCJX�AL��Pp��L�NYo���b� �I�����0l�j��d��i;�f��4C񎢻�=�?E�;�Ф�P%tk
���-�^Fo�Yn��5�Qg�A���aY�^��9�ΆC�o�S
�K)��H��ș�iH�����2�`��� ���<�ei�ۼ�a|6�BTr�$+V���f�k����q]��7��͒q��9����*���"�����z]�pt����NK`�W/�����X�����z������F�c�N�����\��(Ga>9��Ɣ�����D�� C�j��Y4�S�����{�{[�Aإ{�@A��&��q �>C
6m�ѹ.Kf�N�n�r��O��-�A�ɑ����`�k/ug}�E��~�@��?����~�
�6���~�O��<�Y�gk�m�R�]�L5σ���o������'�67�����
}GǛx�0&*^]?�Zk�K�y�v�_�M
@��Z�*3���1�]]��뜯�.�������S�����ɋN���g���7b���>�x˼�Ssl~{u��<�_o�����>��;Z2��y���>4g�Jr��注���|pr�4���7T��A+���y��5�i�=dqDt��*^�X�[�ղ�%dBu��&@���esI��&�s������a�޽�k����w�.��.�5P݅]̺����9<��kh�>�
@�}Rv0 \��
9���L���T
T8_�^��w�+��ԙ�d�4c��_t\�6�P�-��\.��4쿛M�>����ܩO=vJt��٬������WQ�%�f_�t�q<�"���}���t
�����T��xR�q���dx�3%D�)�
r�X�Fz�^D|�ť�-x�y���&�y/1#,�9���ڰ�o��~����Z��Ǧ�x��:>�q�Z�h��@�[W��7*�;�Z�J����M�Z��6?�G��+%��"H�K�7��͵��������Ǐ6��NYo��ִDr'��B~���6fҍ�t.��,���:�aQ��tgؤJ���BH.�6�g�5XBsH�s;������c���������ђ����m6/6o ��5l�����<6��i��R����&y��3�{�i�M0���`��������o 
�֢�P���r}���Zo=l���˽�w�/�7��xp��������z돭���'!���v�O^��~���Ѕ ��!q@�յz��׶��n�1Ŝ��P�g�9��ȸ7;��o-;�Uo���'t��4U�w�sT�����������1� ���"�p�;��)e)�_�#�o�"Z��?y[����v�e������t9��{*�I(<�G�}@nn�P��Q�H�'�{���O�'l�x���%�LA����:�Ǹ��6���=�G�r���t�c��ga��Q|��T�,8��?G�x�~�ٯ} 0�����b�	���(=�RW��	�+��?'@�z{���H0��h��8��Q~O�qKj�~�6�'�_ �����/��OkXZ8l3�O��D,�ģ��tؿtL��o|"{��)��k@�i�@�Ie[��Bo�߱@������ H(Y-�Ӡ9��� �{��; �<ys=���4�A�jQ��p�Y�h��%���y�g��b#�3�u���Tm�nv])�VS??���@)j�b#�\��-��m�T����$H&꟧��=::8Dft�tИ*���f2`���!<c�D@��G�j-�L���A)|�{��٥_N�;؉GMk؁�><t����C]�~������S|���q���m!\)��Uo�v�)4Sm�,C�pN�T����X'
r��h"e?c+@����K�g��Z�O\��_��l
'��E1�1"�������9\�k���c({�	�5�:-��|�ѹ��Y�"�fU�ó4:ח��e�3�ܻ�74:&#\�N�?�����ŕ�k<�.-4v�7ܦ�c=�@Ŗ+1���,�K�RTl\��w^�rs{n�T����i7E�U���/g�S�3ֶ0���x�,�6��00x+��s�
����a=B6�8��k4�;V;
�t
��|���ѵ��kB�Hu���Ӳq�zu��"AkhnC��K!�ŉ���c(ˈ������c�=����pYai{ZA�@���ڎ��`[| ���X|�-�v!�D��%��I� �صd�[(�	��z3��P'�ZM}?s*[4!Q�
3�����a�B󶷧R�)�;Hs������9��q��߽ޮ2���Ȇ���#�z"eŪJ��S]=�l�f�^x�:ȢˆSǝ5�����c����B?ބJ)s�,
���njKǕ��W����WE�����a,�ŕ��v���K���9���0��W���~��	�0��3���?�.��L<<F�AG��<M��y�V.��&���wL����~�8ˢ-z��,�,b�j��V�]�k-kg�V�> 	5��A���ny��W�#3�m��H�e��~Y^���P��r���4����K45n�=̨���1g�&���T��%����r��D$WܩT/艘Sw��z��q�Pw����p� ꣚��mX��*��Z��v��!t�:�j�?HO��/���r��u��
��+Ɖ�]W��L�ݯ�ӵ�<Ǣ&Z<务!���.D���*��2�Ń\8<�49Ւ�U���LK���,˗IED� �5�gH�v��,�N+Eb�s�pjĽb�	@��0q�V��%M�0n䯬�����7�,�Y�/^�v�����Z�1�h�m��NO"0�P�D������twz��Ο�c+Ԍ��v��u���{��Eg�
�����x�,�����ؠe��t�A��ݥy�N��:E�v�w�p;�Vw�m��������㱴+}ST��>�SAݪwv�T�T�R9���yIȏ�h��i_���9���m� 4�A8� �/ܩ�T�ƍ`��:a�����A�g}^�h=�!T��+�]�5~����_�w&�:���=/�����Dc��TĔ�G6��x���j�K��m�����J�_SO�)�`�`���_��O_{'#�����`��-��jꉵ�PA����sF�s~
��qj����y�5h;Uc���1離��G�>j���X�b�l�;-�(�#��7뙔�7VA1��i��{rKx��5�FUf���T�<����o'�;S�~h��ꌡ�7 Nvwz�>�ݘ�+?�u�e�����q�:�a����n�Ls�/7��>����A��m�'����=�F�1�pt\���z"ӗ3	���� �Z��Ԗ�;�.W��(� 5��E�d�VNں>��NI9WV��x�r�R��������8�:��p�6ߜ-	T�/{�6�YZN��أЯ?�W
l�4�爐�~�E�W���WG�����`��u'�.�q�67���{ɷ�s��Y�	�J��{N�m6���(̱L��j�2(.�$d�b$�<�/�c'S�iJ��8�-���$�U����~:jq�\Nðj��3��6~�P�ds��U����% E��V�1htC�Q�a�cs
(��f0%��X��@s�o7�3�w�������,j�cI�ǃ(j8&�������!Xrǂ��i5x�y�y�>�/�t.D�-�D��ѝKA?���*��2$'�W�9H�-�s%�͡Uڀ ��,��^䆓/�������%���D��+i -'-,|�������s�>�v9���7H��X8$9�������qd�߫��;�(�q��$�)�G}Ʊ�����k�I_ҟ/��D5"�Ğ�>�����_{^l� �)��EV�n�g
�B�
�'�i&Ua�F� w�D�'�ZQ�4y��㱰M2��_�"����Q?>�b'����d0�R�u4�E\�������"h
ig�e����'�F�ZJk���w?<M~}E�޲ֆ���h���ʹ��8�~�q����L�]Y�63��/,�3���*&����ׄK��Л\�����ϱ����wo�����`t�T��~��Ċ̳=�t�c�$){J*�x���lf��?>i�5Gz)���;O�J�6�,�k��:�����_��s��^ǒR�

TFW�N�L�ke�f��l�����6���at��Ι%v�X?�C����d\�d��!T���>)�� Iq��"�	�{ͤ��<Kж9��t�bn2|.>䧚*)&t��4��߷w���?ZB�D�� Wa`0�) �k�������NJT�F���v�=�=Þ��]�^m�M��v����БK�ZR�@�t.U��(B+����P���N��G 4|N<E���F����>���f�W����B~}�N�5|�(_�X��qO�N��j!J6��쨳c�m1MV+j=ۨ՞�_w�|��A� ��t�vb(��E�a�h�� ���roP�����K\�%�ē�@����˻£ҹ�T�i��e�Zym�7���Y��pʜ}m�/iB���`����(��j���6���fؕ��U�Z*�RNc��A#��s�j׻�(OE�ζgڿL�!�9���y?��ܥRw��J|������ft��G���+���K��o�f��W��
uLX���::�q�T�ۮ����}�TU���6[��c�K;T�Xm��L�m��N}�jk~`Z�,�VLW�kg�f���2G7M�0�m�V�i�F۵Kqu��*�kgvi���1�ڪ�Xm�k랥���vM�Q9��gH��}u��uTO��i��V��]
��=�OW۾�j�u����t<�㺊�Q(`�E-��Zz���V�vӨ�x���o[A�q
��l#��j[�:m�j���-�ͱ�@�W�uϴ��M�0-�Uu��9�i��@��黶�ئ繾am30|�u\Gk[��i��j�m)R���]�SUUs� �1UXh�V���(���t��FG3��"{2WU]����Nбa6��	akn[<���R�<�r�8S�,�i�hmS1�m��3dY
|�۾=kfm=�<%p=��uC7)t��(�mٮҶ��*~ c�l�G@�t|�bS��Q ,��-���R5-p,w^�x_L��a$`��w:����0� 0�쨊H[E��3=ӄ�L�	����;�=GSڮ�z���6rn�{3�n��3 ������,��QW���m;���f���4�a��fM ۆb�3��@� �����jx6�����}�L7����:�h�gj��0j�OC1۶G�vav�v�.��cj��k:�:���u*��Q:�f+̸S�cy�������mP��]�ӶTXx��2�6��h��q%���T�j
�F�[�!�5�U`8�a;E�)@A�fz���S[w:���Heu�O����[�\fR��'ª6[�S G���� �a�
�@7UW����m-픃4��0�O� ���	��p�*��'����m�vu���r�
#q'�'>��q�6�M�㩆�ձ�v�T;��'��jAG�r��I�?'7~J-��R�4���*�ێM=�`P8�<˦7��f@u:A[��X�oW��Vw����ھ�Psμ�'�"�"O� ��0v�<�c�@�OG2����ypR�Q5��Y
VSO�Y�pp�w�Q�2[GO1-`<��h`Tp��8@T�j+P��)��aj�w�0CԤ�k �"�4� �S��	�6�57>�W���9�L8�ڶ�����Y��y:�R��~"=� ��z���`�}ǯ8Tש�nk��î5,���b]{#���x
����jv�n+��8RU�*�H�g�!�Y�8�����ێ�t@��vT
[��5����@;pjw,���$?��5'�Lh����<j1vUmA' ��p�t��I�Jg��?�S &����L�
�־L�`�v,�|[��	�P(�G�����-ϴ��(�`�v�$�̄i��:Ƶ׈��:�^�T��6�09��сO� �G�G�JI ��,� &v��:���� ��� ߢV�VGateȽݭ�7����Ð\�qpt0`��8H��'b& ���I=�aP`j E4��^A�zp��l782�x� 1���ɭ՟Tp_RB^��@��4�����,�E�u��a���o�w�0����2h�m,��1tE����0@���7l]��V�_S�l���c�:��������y-�8�W�PO_l��A��C��E:�'NQ�u�	��y'U�N���:�}ėt�N�k��0��6yژ1���,>��ދi����<i�P@^�ߋ�#�ǻr�������q���it��T��چ/,�0���u�`:�x��,��Vβn"'��=�)fsFlx�e��1��%�j�`�X�`����������^Co*[�"��X�c�(�bT��GN��<d�P��Y��	�����v��x�+�����$1yQ����lH�gd:��-q�����3h¡��E�Ŵ!��bB���/\��G��Lg<��^ ���5q����h�6��7��Y|�狈�������2����pgN��9��l���_����#�>��`|y��ܜ���NF��6/�7sV�9���As��S��:�W�:���c
`(o�=�&|}�gn�B�;����Sg-�߬q�4`��F�*j���U��fn 0?���h��o�V��.�7kC%�C�)�SÊκ����l�
m�}5�cJ�7�V����W0R�,z�|� o��F�agt���.M�X�iK�c�6�JE�^��������ý�q5������2-��������-�J �d����睘��?kL��Y|J�E�>�%:���	>+H&#�8�Q�jY���D[nE�S%3ܢ����-9�̬6o�
n��Q�|�s�v��=O-q2�:9�ݵ���?�x��E~��
���od-)���]���M_�/N7_��yIܮ�1��lf���:-�bS��X��:�,����e����В7+�Y�=r����oQ N򮤖�dx�NX�4�M����r3�Xbk����N_�W��$+l��˛
_��
(%���Y� ��g �NƸ�b��^�?�:Z����	L�T6��F����T���	�������<�'����AOX�X3�0��t5f����	d&�_j ܄"5V2(z�ͮ��5?њ���7J�y>���w�&ѩM�H�#E%E�}���yk4��]��7������\�G��rswog�I���=�\��jg�U��0��M�`���)��0#���Z��F��`+�v&}Xg%��Xt����`���{p6��$�@������;�����1�~�y�Q]WE�+P�a!L�e@J;�3I����K�8��Nxm.��Z���/׸����`��w�J�M��XL���
��Tȝ[���=MJJ�;�:(T ��P�hI�O疗
���-+�<(�
��^��u���B��+��|�dʅ�|I_C7?��钧4�ɏ�w�Mv���vM�A&#��mv�O��n��+��~C�ި�9�y��X'u�=��x�Ԫ;��$�^��p7�<�M¯��<��`D�	�4ϼ'H�AWƽ#�N���$=�-=t��L���ۘb�R��M<�Kf�|X�YX�5lv׆|j>��y�0�t�i��k{��joo�h��E��3$�36-T^�M�g8��z��ޅa<I�"�U֟h(���>gf�h"=�')F|�|a�2?��1�0g�Ŝ���]XS�z���)zV�ެ:3:��N������f02+u	���Z�D�+mY�����v>BΜ�Eҭ�z$E��,�M�#^�d��>�k����5~)����ku�{_�\�{�m,���l�H�?,�?L�P���U����LD2x���e'	�m�bxз���u����!���\?�gc���� �=�Z��,f�4.���g�Y�w�,���+�������V�������{)���Fޥ*�����|\�`�����L�gn��$�䙇�N��ڐ3�5Ƞ�:���۽���s��w�מ凛�+���"�ߐ��@��R�j��"U���_4/~����rV�� ���u�ǔ�/���'�}�m\����lC�t��,E���V�2���k���+�R��*R�KϽ�q���u�Z�U��W��i��o��_I�qctm�|��:�W��x�Zj�TE��o���դ�y#]��O�i(ڑO�4r�  ������3��o�a�Q�4��Z0@P�W���j��8�@q�106�ݟ8gQ�v�y�C�	��x�B]5�)�;��n��@9��}J����-�_�0�M3﷬;Y']R���'$YU�&�.�"�YV��aDY�{�sx��/���5�SiM�,>_�O�Þ�A�WT�Ng'S��#�(�Nx�/y�k+Wz6�T�o�m\��7TS�U鿦U��JҌO�{h���o(�������J��<mޭ���|z��譎(����������8 ��-����m^��9p�}�=��Gw{|t���ς�f�y�ur9=#t}��"r W�|T|%�pn���h޻ޒ�C~�{��������F�P�sn%���`���gs�	דf��f��-���	4a�`1�}=mԓ*3Jmd�T�-�0(+$�Y��+_s%X3Ao,�͗�ǊM�`n�\.�mZ��0�%�w_o�)��s�R(`mϔ�_���-q_��E���#
��5Y�dU��NXO���X���f&�]�k�b�.�CR�`�%�����Y��	��#����#3��
G#��%��s��C���NX�G-��Q;^�%Y{t�����$��DfQ�[IMG��������O���I�Q���Fac<	��R��$cs4�9L��R��F��[�;�����u=���馅��mW�+I˗c�� �C��~�F�/�#B��cB�)��t.��Ddo{�%�N���Y��<*j�9� �o�Q������L���8ք3�g�h��fg@p� ���� 	�T\����7�6o���9/h�¦u��������P�� d9:�)6���r�wk7��r�� '��3��k$��A<�����|��Ш�tb
�� �7vG>�L0f�YH���95�B'�>��:�P�+]���i�G�u�Y^��q7o���w��������� T���� �^8*|�e�Ḑ�G/�3�����%�I�	ߎ�0ik*1��߽����}9:x��o�������uٝ(8R��w�O�����j{��u����//���O?����x�����ι�v�L�^]^~��u0����7�z��eǡ����G5o�!�b��K&q{I�ax�0����� �����A���"�8�
q9k��c|:	����=�7�'|V \��������0���Vk��<fS+Xđ��S�B�{����j�/�5�/�}V�R�i<��1g��|�$b�,�7J#~���nK��z��o?����i��g������������pl����0���?7���Q�������hg���������E�ś�/����V���_�?�i�K;T8��fh����J�����i�D�s �tE���K4`/�K�Um 3�_Y���Dy	t�Ea�����e&��y�.�7M��s���}���ˠ[�Ft1��|��!�$�ʋ}8�8H��ϟ2�z�|!���ZW�|ky�3�/�NT��g���ep����`����(�Nc��^Z����å7�X�9��,E�ې�o����O�`w�6������������[��V���?���ˠҝ�u��4�:WAXu����P���럸 J\�r>���O��o�^Ǽ�LG~��c����0<�}�2J���i�>1�@b^&��^��U �睅�M�0�>����N}D��_��$[�(�L\ܟq$nSg��Ʉ~�I�2܃)��)������^�k��,���k�w&?q�@9q�#�rP(���xǀ$����D�m:B����V��I���r(������9�|>OvOs�+��Fɼov�p�P1��"��׭|>���O�1^՚ZSm~�u��A�����o�ѭԣt�Q� ��K���0ϚR?���r������^;%��a׀���U�v�P���몖n�w��+-��0���I�٭��|ʀ����_��<�).[1F�i�g8њ�u��i�j���ƣ))����\���SI���۹R��J�����H]
��Gw˽9��`Q���E&��TBz����|�V�q�������Q���h���_���c��ov�~�}Э'�e�E�u����0��������i� /y�$��δ�$Z���}� `��˔+�z.W�Z>W�z]��`g��+��!�k�C�?���?�a�����\I��?��y�o�Nx�� B*����W��i��N�[�e�N�<�����7}�R���С~���3_3峆����M�e��Ʉ$�1�#���a���l��aˡ�3���nS�.C&a�B����i-0=\.����r@%�޲�_IC1�1{PD� ��C�:G���b9�d1I9���ov_ͅ�xW��x�射�n��wQ�M�vS`<��%��&��/��f�Ֆ�e�\}����}�s��=�*Rgڽsݞ�PI�?-R����&��g�zg�����
�V��At����G�܃��!����,*�q�3ʺ�t��1���H����@p��uq���OS��������T����U�*��������|�����3��)d��������X1x�XT�#�PtJT8x#�ty�p�d����:�K��~�7�	�i�Ө;] .��6����Q�CU���o%�:��>�������^���u����)?�8���8�:HWv����OT!��p�Ә��D�l�����@�\���'8?��@.���#�������������}�%�h�ix���������b�t^����/��A���"LJ:'� ,!����N}�b]bw4IϳK�¾�ʹ��eDj�>�ˢ�;�R�; �1CwE3�����p�K�[��=���vf��ښ��ze���$��;dn��݂�[j�s����H�yO�g;Ak�Yz�AA$�?��j��K��K�`
���9�y��RWFK~��vQ��&��Y�S	0�l�I��%6�<���ܑ�Q1B��\|�[t_8��h�s�����|��k�TD%E�����h�e��GW<*^�MQ.x�s0s�bW�<^�骉Rٙ�[4d3?8��|��Ix��ꋞ�dxR3�k�]��}�r`�M.ɓ&,)�R�`$P�w���}(T.}$�>5�������YO�]��W�Ϟ�f���n21<�<i�&��K:���<b�,���?m����s�Ϩ��U��������c�W�_��=p�O��?u���z�O�#�Ꟗ����{���r�_4 T��H3�ꥬ�~!`������p�`�u���W�*�_t8������O��Ͱ��Y�n;���w��&��!'|��+Y���zi�"K������@ba8��o�/�6�@��j�s��*�0P�ĎC-�٥�� ���֮����s �
�{�	�v�ZVG���V.����<t� q1�2���dJ��)�a��J�N�V���}��3�������aU��JR��-�ya0�oK�;l�9!��K�9Q1n�С��k�s(��0�ԝC�A~�>V��$q$�c<��%0���;9�����nI�I?��6���� ���Sl�=��C��)�>y
|&an���]g�w(H�Gꛍ_�ƥ���!3�>i|"��RX�ƈ��2`��_���#�O����_�
��I�K��
�~{����,h��o�᥻���|h@�L��l_c�q]qO�~O ^����c��a����s�p{�:�$d�`ԇ-&���~8p�w�/u����=����=N���J%�C��f�pO�	�������|�a#������2��f:V��˝�l%����Z�� �<0�
?k*`��x#���/^�]�I�=�֠Ӓ,���7����z�Y���%{s���(�s|��ĥM�斩���C�Y�_���{���n����W��+J����p������+�����O�f_��Vo�B�W����Κ�e���?ôR�������������s����`� �/xt�]��}Mn���	���{�Z�n�ZS1
��.Eg	�,�Ϝ�7��=hM�7y a�$ا�Y����'�j>���ұԅZMQ�٧�ӵ��כ�oXģ�uRg��׫?K ����j x^!��TQ[�Z��KT'!R/���	t��@��E��N4j+�Z�T��aR��ʽޞT_���y���'����z�q���ԭ��?��'ء5��l�
.�׿D��&�B�d�g��d��e�A:�Y�lv���J��(�әU8��<�_V:}ʚSgJ�
r�n������y�ǻ
N'�ji�s�i<%��	����U�Sd����Uq��H�+��E��Y���Ӓ���}Z/?���̿��m7��Qu���T�?W���?��?��_e��@���.��%��}	���G{��?������~�*�՝���k3�UZz����N�e�~��f�AY�����JR%����9���[�� ơ5Nr8Ge�R���+��I%��	���C���|&z13L�Kg�N�^1��r��9q/S����'���|�-hZ(�}s�l�n"�]]+'�ɡ*r,��9���+�@ę�n)�5 ��Tqɢ%��ȖM�Ð��fn��9��Z��hqs!��H�_5���v���$U&��L����?��G �,��r�����Mq10ی�|j�T0+�u �OGS.���㴒���p�c���2nΚ�K�ae�~��;.�Ƅ����Č���$�����LE�@̽Q7���jk���~��6~B��90`���0t�aÓg��xn��@���!m$Zs !t?@O<���KO��A8�p<���ʃ����7���6�Yf�?漠 �Qs� 2���@���wV���#G�����O`�l��tH�+ �=�Հ�>y��M)�,��_ x�1�LԈln�E��ܟ@i��/۔K6":�"�& z<	�X)H')�#7��o�Q
�m�ƢB�}]mjͶ�4UU7M��6�f[1�ןa��º� �~G���6��c�W�� <J'���NL�h��^����n��)Px��G�h�
[��?���r�o"��of �L���;S�����t旂@)��� ,sg�����w� ��2����1����V���"U�!����@8������x�^������e����߆�x���������F�G^�_���s���UL�,�/�+hcz�/Oy��1�f����R�w��ȁ;��[:��B�l�n����2�O� ����Ν��o8�����(v>����6w�BRW_�����P�w-׮��n[
P|�.w��b �6`; ��S���K�;�h!!��.��w�pR�X���[�˻wȡ��{�|O;��k
�y�x1p���F4���n4N��\OZ�o�g8>u6����p���ד����7����Niq���0�8�#.@$�A���Hq}J�� !��!<�Z�C&���=:�ǧ��J�}Z�=y��(�����T��
@� �� o�E��F��O�>����Ps����1��_�%*� � � ��to�x�=k�+���\��P6�>ݰm�~��6���@l����s�*�)�ܘ�M�<�j:��"�ޥ���(���ԭ���*��F�?��������� Oj�9����cݼ�ݑ?����@v�6|:��ς]j4@G��c	N��������bL7`���ż��rM�GS�V8c��͏���f��GG�{>�=<a� �/,0����h������1�:�a��[��̗�M��������V�a\.T�������I�귘����Xp���v������TKW���g���L.7 ��z�^�3INj�^�Q�F7�;��`��FxԪ;o�AfD"9chq�?j���,�f��/M��&����?p��0���ܴ�욂��7w�<%譁�:�?>`9^8� ^p���3d�"ҏ���� ��#���m�柜��E]Sy]�R��<y��|�q��n����9i�®�#Y5(~��2_�M�,j"��``���Q�w[�	���}��z\�|�0�?��_����WmUK�˶��7mӬ��U��QKA3+.��n8����u�
�8''��}��i���ψϳ�\�x&�����E�ܔ���|z~��?����/��,�����*���� ���*R%�U������cS~�d�/@�e��,-����1�����a���a+�����o�jKt{vԇ�%/+:}�tz���U	��!�$��3��LG�<�h.q аB�y��a3;�^�h�(@�)i�����i�!��#�8�
M�|ς�����UkK����Fބ�[:���lv�um]_7��u�z��f�p��Λ�ͯ3]�;X�i���s'Fp*81�f�k�JUZU��?��i	��wԾ�6�V*��e��_���ߕ�{��p  �+�d�Gn�����\��ĉI���u�t���$E�Qm*E��x��,��^Oݨ��$&���Ǚ8� F����Y��ps�琄6d�qD�>-�N�é���V���)��&��?�dP�?	�����C�S(�m�Kd,�C2���ǹ���2���c5o�GS?$�xv�IkMZÁ����
�+>�Y�@����0U+�����ŀS��[�E�E����2Tr挦��J���t8�9�d%�J�qk�"����M9�CC]��Ȯ`<k�QuG4�N>6�Mem3�餘Ij�
��[��bL�� ����.���^�e���j�!�ߝyخ�|�ÿ�o-�b層�����/�K�"K��#?��p�����͌|g��O��4���J��GQ�O��L&���,H�ol����{6����L�"�@����'��]��Hi���63��@�ϲ���s%�z���s��@/�Q�&�� Ξy=�Ʊ/�O��� Պ����eL'�}�p(�� �x���?�	ܚ2+�%_J���D&<\��G#����'rN��� �&0<�Yh*�lB���	7d��`Т�p:��(���&#�������k�&j�������1�뒶r8'���SB�M�e�D��'�I�8��m��<�q&��9�`��Z�9��`��ZF��;}�����l���_���y����^� ���#b萛Vp�psko�]�%r���!���#��V�p�ZSEi9��	�0�-�$�d0a�W�:���<ڜ��2	G�쬧7�����(��z�c}����2�ۿ�3��u��֏�ɸ%���x1L^P^�btf�Ob�l��C�əP������X[���ͷ�rGs�> 2�Sر�h�&�-%��MP��2�5���Z����gD�������8,�*0�A�CF#8���
�.#F8�<m� 8^K��/���W��wOy�_��$/��������lC�t���Z�����ΛW�ov~��h'��o�㤮�T��__��9�������:>�=���� h�N�������91����n���?X��Ke��E���T���m)l�J��W�*�?/�?d�+����4pn��t�'bor��Z��P^br��vz/�^"!~�W��>��������4&Go��3������`�7��t�@ޖ���t�n6����'���a��3��%vV��������?ޟn���"�"G�F֒��څ����%��t^ڹ����+
��"eE�����ޗ�4p�M@�b��c<������e����Є0+�Y�=r��Z��dR o���i= ى��f�I�}3�[nKl�yy�	�+��zC�.�w��Mo�����U@)��O��� ��, �[Lr���%�/�g	|.p��ċAes�n�M��7ۚWnTN�?_\v�دF��@�-�����H��(�㝲ۤ�R������&�do�w��F���MV2�֛Dڡ�*A�����'�z�G��+�_��b�����B�I!i;g_��k]�u�kz0[��+�[h���J᎚-�P*-68-T�׃��B�>�J{W��0+�$7elE�ώ;wڋE�Es���KIP:k�qw�Oc1>P?<�����Œo��O�p�d�T�m�����E��ۜ!����i�fw?������Iי�aZ���~�p �x�fE<�Z4ŁN<y��ѻ`c<]Z&Ö�p�;���N��L�jdN���f�)�uK�'t|3 R��Jt3܎�	�b�|v��9�A�;n:U��t��b�"Ŵ����];c
F�]32K��FU��S���0f(s*�$��}�Π���ٙ3�H��G�O�0_en�ha/�b�dAu�?�p:O,i�?���������^5���p|�Wх����� �r��Xt��3���Q���"F�6�	�y�����A�!Kx���^��k��JwM��_L0Z�5����I�����u���+I��oQ�+��o��w���.
T��K�����׸=#�1�)�~x�@�8�����3����H6*d��c>s��ؽ�3f�����ԙ�[���U�ǌ��#��%xF��������������Q�1O��zi��3���4��R�����!�1�ۨE
����.���������k���M3��y���r�x��de��af�����-���*R��K��(�?���]��HQJ�SZ��Yy�?c�ǰӼ�4s�ga��d����Y�O`��߶t�:�W�*���A�+�;� ���� 	�L�@���
��̖��XOᱧ���;�([����Q�]�{p�q������Z�o� d.�߼q�|���9���Cbn��;o�{'�9d��6Z@�>��&�:'����y� �[�䮘{i�Ȋ�k:�nɞA��	��*� �:��*M(�����<0�"��w@j� �'ȗ71c)<Ƣ��.��٪R�_IzL�������O��uP���Pn?,�J��p�[�  "�W!�8��/�c�"�^,�R&�%l)o��J_�.�����tP,����"�[�a�|�����pү��I3kR�o��I�%�*r_����Q����zlJ�ϳ�-yíp��A')���?2�|#�_��U�JU�R��T�*U�JU�R��T�*U�J������ � 