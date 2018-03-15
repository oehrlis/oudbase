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
�  5�Z ��zI�(�;�"Z���%����[��}���)��i)ee!ej2%7x��������(�Q���u�[fJ6`��{�����b�׊�8i������~�����k����������o���U����oW�|���,��L%O����`��{Y�������?��O`y�Y�̇_`��������������������_{�;���R��~�w��B8�apG���@[��o��[{���a?�U�yC=��q�ڊΣQ:G�T�Q�&�4���[Gu�sFgQ��4�<Rkj������Q8��f����:������Q��o}�{�8j�φ�.|ٙM�i&_M�A���h��b��Fy]��Y3���}*��c����S�{i'̧��09��O/y��©�m�_p���<��4)5�_p��Y6I�!=�QG�,�L�4Ug�3�T��Ғ^�x�*�UMg���w"�F�����1g��8��ѥ��Q_�LE�y��	*�0�M����y�Xa46�N'�F�u-g��;-ޱI�8���D/����������q��xG}�̣H��`#x7,��Eߌ�3Z�8�p��q8Ŗ�EޚM�p`��OvEmL��?x�ρ��{��r��p��dk���{篍�`��oa3��jW4�n�W����-�.��T�
G�(�����G��{����`k�sp���z\;>|٭���4OG�q���I4`?�?�>�=��}��(;��8�h�p���d���}���Ȟ �QK���x��dk���y����Zk:����g�;0��{��U���\Z�Gǝ����V��q��BJ�Qñ-�wF�R˯���|�l�U�1}�^-��l�t���GG��Z�{��p7��a�=<�?|����'���͒"�� ����7�y��yx-���"�݊��(���<:���BBj�h+���Tm{�پ����C�qex���X}��{{pbo��D�l��A��o���?��p�/Ҭ������j�V�U�N���)�1�y�kN���7eN���{o��]΢�(�]��Y����{�軡z��8�zD�w�V��W�uO�5������]:��OԶp�~;��'���w��#u��v�@������T���!�O���Q&���3`e�n���}����v�W�U��8�
n��U^�]F,�Q�xL��x�:��r=xO���;xyL���ƽ�*$�{÷�!7��ː���������^Ö�+�! 2���B��䬓�oCs3gR�?T�����n��h� J ��o�����x���7/6�����V���zx8�krMg�.�����+��[�����^�fŏ��a�ހ14�૚z�D(^�T�����a��� ��ԇ)�+�sMO�^-c���ҿ��x05]��Ӭq�?�|i����cWf�U����U�p18�����j�i�i�-ۓ'Uk���~�$o�y_�>�2�T�tS5� �����_@8���UO�{B��H�M�պ�H]�Ӗ�g�\���@Q�y��6A�!�M���3��YB�x���P[Λ�.׌���^����d�t�X���ZF�^�)���w� �@�O�)j��T����+C���͝��nN�v�
}�ԍ�ɣ)�>��x�ң��v�:ț�l�'�t��Ƈ���#��Ұ��,����j�I���_�ޣ�}���,,��ׯ���2�!�N��������t��,IP~�P/�����	���#�;P���~�Y�6I/�7b��r��׀;���Z��&~�:�q���V��Ks�-\������$S��e�H66�;HT_�rͭ�������sLH9
K���V�G�V�9$�U�ނ�Z�>�4�y���x� �h�+�S��z��p���O�����Y>Ua��*�c�F�G`�|-�|)(J3�#��`cm�*�-N��8=� BU����jŪl�\{��G�d6�&w�T:���m��gډ��Y؃���\�h�BC�
���ē��m�`Fua��Jh�18�?������x��Ϸ�4FyË�N2������jvhaP7ca�ج�;JѬjU�=E}�m4�AT��6�'>�����j�_�ڝ�7j{FñvpS�z8^���(p�{�%>Nh�̇E�� ������b	D6F)��)�c�b ��X��[���I�(�7��P�T�#҅�96o��s`��ߕ�;����HP&񘷍q�V����g�ܟf�Dռ�����6B�`�[4�'�P��v�߹�3R�H�	�'���&�²,޶�h�N i���,�ˇ�[����$� �h�c=Nz��y�����Fw#C�٨s��'�b0���s�a���~�|��Ȉ���5�=Ƽ���.9��Ϻ�kj��6�������f��"�Yu�>VVC��^�Z��/�-��ׇ�D�
[P��r�(ݻB�Mh�Xh�z��=�;��v���k��giH򓊐1�̑�c�0Iߛ�U���sTi�-Iӗjf���X�����9���cg3���6_�����jg�{J۰��xpY����c9l�"�C9Ǚ1\�G�n6���R���_9����������dۮ,;��0�r��2S�	��2J�E�[>��Y��0��1�x����^Ya��� �#��K�$IW� �'S�� K'Q6��g��مm��r�cw��r��p��\܁k��Gk�c81��W\6\#��5�,�t�mn{]��#����Q���Cl#���?9=����<���n���Rk�u׽*���8�Ӱ����-�C�g�i<A�1�x�Z�$@��6��MQ�Yj��{���$-�zt�`�=pN��7i�� ��)�V���9=a}WwD�>��s�=k��g�|r>̬��:�{�k�W8kP�yT[A}R�Z�H��ԦgU顨�!�&Y��^�����9��y�^瘎U�]z;�Y��_O�щ�^�Uw�v�o�?<z\{���=��Z{��|o�%����G�?>~�κ��o��[�����Z�2���7��ő�y�R�a��K���./	>���G�
�G�IӢ�|�Pu3_�:�+n+���v�m�f�X>�6�\�$�r��P1G�Y��y\;,:����t����H. ]B�p��A>�"��7(~#%���-#%���>h8����=�7�e�a'7���u�Y����}%����__+3g� K�;�r�
�|p�ޥ��#A�+��Ԯ�=�V�����p��Gߓk���.�Z��(�V���O4Z,T�.�?R�~y��a�����0ͧh	�o¢���[U�%����TE3*����f�đ��>��<��"�G�Eh����4SN����1r:����d,
�-������ܗ��#�R���˻JJ��b,4�aQY�6�[��s������5��_�����[�������K�|������ͅ�W�����h��ɺ�R�5��_<�_�r$������j�G�������~���`�}E�?��gD��"��������9b�����n�X��w�(�b`s��ޥ�޻a<Rb���}K}�t{oˉӧ�zP��!�-���>�u�~}~����-�:� n��5#�YҮ�y������u�9~ACةl���e"g���T��?���V��Zuń���o*@}M�����|M��M�������p��5��_��?2,���ɯ{�ԑ�Y���z�;���:P[^_}����������H`M����q�
c�{�@&���b�L'&��>?b� 0�D�����v��%���`�8/�W}����F�ѥ����/�{4'�v3�Ҳ�/u����7���:�����euN�sZ�F�/�K�1�L�J�QB�&Q�����Et��
�|9��Q��rB�%`pA��1�|�����K�*�<�
�,�O�B7rlj�c����i�ͧб`�sI�xS� C+s�;Z���4�E
	'��9�a�+w�>.�Sѐv�dg��>8T�\��۝�6q�Co6�����l���Lv�u�p�|!'O{B{��b�s�<��4��}�\m�sܹj���4�k�H��]��:`p^��*i�7�{�;t�y@���	Z���`@k�ޛ֛e�o�΢yo���ݺ[w�����x91����l(:ˣEX-=(�5(�����"�C��6�*���f��˖D�4�pB��m�(}|E��$�|C<wj,�:�ܹ4�z;i:Q)F��V쏮e�o����I�HB��/-p:�� ah�0�Ie[���7ԏ�OF���Y֋<�{uSԓ�Ơ��U�M�n�N���&�8����D��8ٹ��&)	�7�]�
�����+EU�Y����kᬆ|��!�����ٖ0���$m#!r�'�4�|>��:��2!dV�=�N��;$�8M���K�@*�2��u�3�rӿ�M��^�ŗ�����f:�	"��D��
����H=��$�ٸ"T��c �ә[�t�~{��Bz[4�6TW�s�U)�o�Z��R�"�A��_W����\.n<���������e����]��ڭ)�	5��Z�,w��y�LR<5�'�
r`��8=���)�p������m��,�!\��/dG�ȻWt��Ӂ\=;L�)�h��k�8q������(L�n����zI�`����^�0�^�8�f��iZh��'��X��zSk���J Zw�l��U����>��G,��A���e�vuS�E4,�Kw�G�osw��1�l�]��ʨ�jeEG+J�Ŀn�~�԰�c0�����"���'�^��d+�����fv��DH7�RP�M*���J�jo�rK���f:?��0~���<_��wp�-�`tx�ߴ��6���s"Aٍ�d&Mi��9���W���E���ݏ�������ƬZ�1 y�Vr-�v�2:��IQ��t�J�&��-/�/�֮����:�lo�/���Ʋp�K�I���\?j������~z�4@LՋ�@���(�@Ȩ�4�411��CArL��V(.Hʏ��3�)~�����KKGKS�8ׂ{�x����U��z;v��C�o����Y!�5��ﯮ=\������v�ۯ��������_)��\���1i|�����ێ�_m��iK���Y h	���ٹ�xQ�̞2I8Fk�_�݃��G���ƧQ��{Eos$5o�h��`����ʊ���d{���³�	��	S�=��Pꃉ�W���yY f��ǹp
�-څ��6��ݽ�Ύ��_��V}����둅k���{U:��w&�>�g�m��O;�}yp����t��������y���ל�k��ל��9D#397Iy����5��ӒDT�Hz����5Y�k���d�/��p۩
�p��t��F�1�lt�D���2�U�+��U�K$9PZ�_(-!T�8���s$����v���Κ�_4��"���U�*=mZ�k8��p��������Np�M��%\TzQh��<��&�Ǌ[�����zB�?v�5���F�s�]�F�z���*!�o��}}�f�}���V�w���نW+B�u�.�ף. z�B'��Rߠ�E1�	��X��N���H[�5�1�B�I��|`�����mϲ3qcdw��_ү��Q(���_;�tbG��~MX���`�7��`@��`[�w7\L��t�M���7OWp:9��R�µs�NW��~m�� �r0m+3�>>C�,\ڻ�w(�����x�wȬU ���D�?�D�`n�;���-���z]b7�p�Nea��L�*r_���AAH@�����`/n2���\�N^p|�U9k�u/��68��w0OL�H�6�d�UІk��W�i�	��=@�r�����&�rSx����L"7�����Lg��4��V���7��2�����yo*T�Y���o���[��`aj��������\+��>?��T��$C�1n��1_JzZI�>"��Fy2�'�Y\�cQ��?��%�K�(���4�8�^�Ha����c\M��#��da����#t�.����T�K���=$��d,�4zO9�&����2 ���q�/{���A:�������˓�����e��>&�Ef�5��f?�v�Ŀڏ���cq�����r��Z{����V����ֿ���?_�~���p��?lߣ�k��f����k�o;H��F�
��_>-��q�2�sE�4�� �25�ێ����>yv̻e:�͉�E��o4x2`���p���h���f��՟�j��z�&}PF�W���y:�M#6q��ˈ�o��zS�c��=��[�g��;�d��I ? '���a���F�V�K�~+ϩ(�߯��h�dk�9o�~��oJ�fg�mE��y
 e��58���ʭ�ion+���gs[wwv:��#i��������[/7��UL��?�M��Ũ"i2_�ךk�vhE�������K���kL�OzpϛhҩE�8��F�����'q5�k}WW.R:�(&����&�4��6V�h��5�X��S`=�`i�ymia�ݐ�k6���G����'��p\��1�i�4���ci$�M��Ɛ��y��N�����B�v%�P:�R0�7�m.OދIW�<d@1�͗����c<�c��^�8jW�q��������3�i?0����@qTc|�Y��[����|�[��^&�>x��2x��E�+ȴ�n1���<,U���*��3p�\z�*�Iw�>e��O>wP��:��󪣇4��`?��!o-R��oY���ʏɥ�'Q��胦�T���hsɭHd�-��N�������Х"�瀂ǔ���(0?1�ѻ�7�i��T��$hm�UV~%��o<�����bV�4�ӟ"���+���coNU�o����h:��fb�h.jj"����/%��jFb���8���;Ez6��1���|t�Y�zb.(jH�8˧n����E�)�z<�a��Z�)�Yr�Vw^u�N8�1��8���U��.����	?w�T �A���%���`��#aq��ψ&�U-PG��P�����C�L~��d��z2U��#�r;��d�<�[.�t�5=��J�D�+U!2��&�T9��&fˉa���؏�N�!���w�˺&f��;�{�_�3���f�i�h�D��J+!$���ߧᩙ�W��F���t���1��	_]�ɉш�z.��Ɏ��&���)����RW�P����-����P��{\��&��α/��������a/�ג�,-���0(ݙ C��e��>2��3#�eT�w�*�O��C�'�K/���[�3x�)
���*^D���]�Uai��3�ɥC�*��j��^��y�s��O�^/���hv3� �kf�1��3�����0ES5'@�a\5��ń�{C9�M��s�o�`_E&E�>������ڧ��m�ᗖ2n=����|�$�3� E�5��x�J������$���ÿ!
��'�1`��O�qh�=S�����0���y�M�ىv��+&�`y(���'C���h[v!�i�n71�7]��+�P	v_tO����})m�)"������|�n4<��H|&�[ۇ'�e-}�U�������ғ�)lW��Z��?\������?[��?��7���Ԇ�Es�:�vo2K�a痜�L?bz���ƣۛ�+V F�3ܵ�ԸdZ��
z�G���Q�L�4{��,��@�ۀ("��Q��� ����y��[���<��Rhfe�8��%���RO>+�����Ro�h��s�;b�!�yȫ�ɢ�Ơw�:� ɳr��,E���m�����N�y=����Q�pMF�xy���p�=��{����FW�������Q��;�h�'���k>.�������-�U6��ѡ��r��|�y@��u�&e��rLa��@[$l�`��cx��e�w���o��mv6�4�[^+�7;�R���g�O�W>��\��m.H�����tش�wv��B?�B֢C$�+m�ő��������?����)=�ק�|8��y�4��I܎scB�%<%*�﫽j-�1)��W(��. '}���t��~�� W߬�����u�o��byEb����xө--������jA#D�+����N�|U��P�3iG����KR3�D߫"I;Y+ �n�t��t_��i�"T�t���`O�Ǽy�xi��-O@E�ꃊ�e���݅o�3��*�Κ)���fe�Q֤�$S�>�0��J�u�5^��-W�DL��~w6���������� ���r���+�(��s뮦B���Q��wɣ��B#S�=�n����s�_>I�q�hV3ҋ�w�c��is���>?Z����bW͝H)t���M�y`�l3G���X��xZ���425hk*�
�?��Z�P�H��8�T����;T����̫N�r[�L��giE��_r%��6�A)n�G͛��ZW��ӝ	����[nH<X��� :��c�%���P*O�l�*ڪ���d%Qw[dA �e�p��4IH�h5Z[jM��E����g+�m�zZP�t�x���4��㽠d��M4(oģ/<�a���H��s���e陃�7�g��,�ټ	=��)�S�������9+��CjڧT��.�;�(�����N{i	m����SuF'�vaۇ��iKx�^�
m��������Q���0�f�96�B��ٱd�+�u펕�U�}��:Ǿ��(�XK�/���o��1g��#M��q~}hy�8D
��2�L���D��/zE<�S�v�<��0Ǫ�*tl�޼)|�6���n��X���zy��1���+�W�+�~�4�'O�͹L������G�+��$�8��4��oy>�߉����C�ի�����1>t�ϲ��U@�e�y�������j!�*
�6|�����#p)�us~�G^~M�bM����ip�i6�<�w����PR�,N
����׻{��Y������b�#�4�s�������o�ŉ���с�i��?"�ķ�����C?���#�ӂ�+rOA�}[�E�g~Y��0U�d�Pj�s��
���.��V!���m�`�{�>/�؂������.fQa'�yH�����+�ɧK���y����u~;a��ߜb�+���枏�i�}~}l��?-�y���p/.C^h�梺͝ϫ{��b���]�v���[�c�Q��x^��r��c���/���d�锔��~KC�
?�ŹSє{�)^��l���9����s��KE�K��Q��'�;�)̥�J'`�X���.�.-Z Ha�
��x�� lK2�5l�5.�fu��JjٕK�����9�L�h��vqa^���k LT	 ��v�Ognoz�ϋ S�L� �%Ȫ�j�Ab6'?���;c>�� r�ヰ1Ew��.o�VM���T*�tֹEDV0�R�E!��*��_��<�E�,��Mn%�b�$����e)�j��M#�A�ndT0���PԖ$(U�:;��j���h���F���{���wk�j��=
�VV�Ê��,:�����a���L}��f�u��{�mc��G�"�r8�o@��x��g���U��Ò��}P2d��B,��_T�����3�/��
��=Q��/���
���Տv�?��H����/��(�9ε�C�p�ۚ- �����}��@�b\��Tf0#��5' Kϸ��Z�<���y������ G�(3��_����{�	:�Ҕ6��8M��=^�|�T�$��v�Q���Z���!�?V��Β�.k�Z�O?���T�io�P�(LrV�{�Ab2��(&#����Z��,�W�������Z΢���uvH���d�3{'���2���E�K�@u�9�~��Ņb�С�3?X��Z�-�֥�v7���l�� +Y79Ҏ묉ΣU+���@u(O;Ka���\��M�v��<d-C����	�6�E}�i%�4�Ґ>XKkA��I��8M�ų4�����b������)���׏F`��C�-r>�s>�Ο9Ö7��nc7 ��л2�B���2e;���8� m��
��xq�/���k_�m�zôW�A<��_�(�
�^bS���\Ғu���9�,�.<�{�cN�Rv�����&���t�g�WJq|�r�Ą�����;T�^��~���__ӭ�+��k:=X8{M�[�-`"��lq����7��`a �<��-��;�9�ɟ���Л"ȅ�z߯SQ0pE�B,��Us�ߚ� �H�w:�4S�yK�Z�-�A@ձi�z^�yN���y����>&9\Щ���L[��~�+�P���_Q`>T�(+�m �����X���ڐ��3�m�*�}-��D��J�Lt�p�7�@�k��ߋd|�W�U�k��j�!.Xx1������Ȃ!E�Q*|E���h-�Tq��TH��#Tvʫ��c>~�!T#1��nIQ���}�4d��o�Z�v�֯~5n�Z�*X��5C���αy�� W�΄���`�C�KO���qe��k= (�A<l5���*�A�/���b-�Oꈥ~Ku���i��Q��(��~�-f�U ?t�4��o�K͟�c|�@/2�υn����?ign���>yg~�s��R+��@�҂��c���ct�R�k��b�s��O�d�_ӆ[:R��?N���	��d�k���b�T�v+ߑK[����QZ�VO�"�����ū�v4w.�r��3���&Ulnʍ��_��I���``k
R���)�cT���Q�^������r;�nPu/����>1a
�=w���=��U��(�bdDs�nZ}?^o�c��T8�e���j��|~���_]�w>z��o���fH<��>M;���M{r�i��O������XA��,ԫ����*�uJ�{^�H��>H�l@�[I�Vd���~����~�k}�1����e��_�����W�j�����ߩ_zb��?��/<������Q���A����9����������=x����_�GU�<�{��w����u��)��)E��+����PkR�%�Z��8&�Y|6����:}��eQ�����V?�g9)�����T�K	�A>h��Y�I���Qv��q�d��)���ܟ\����\������ࡼ8���	=G����!�h(h�!~y�،p4J/�~3��\�9ȢpB�:�v�;G�`v
���n�b5hƣ��R�w���\o.�J׫�qҧHF����M=����0|n��w� X-�;S]�~��gX�����"��J�&m��:Ԑ8�d?��RO/�b��M�����4J�|Ng�0��8bP�$��b���,��LS���15z����=�g�Zg9@����D�h�͸�z�`Mf�S�����s	'�Q��<��uaaf>�>�{�HV&Lĭ?�������t�!C	�C(�[������	�хa�K���;`����p}��GQ�X���ߜ��,ƼZ��W�c��b�`jE��:(��D�����e9n|�� �Q���"·��Ö"��ѵ��#z*"�4~���1�1�w�t�6��;�6̭ǳC 	I���o�jpo1G��S�,�����b�)FQѹ���4���p�E�g��!�xP.�p�;�<���|E����4�n�$� '���cC<��eӐ��A�ƣx�c{ب��]j��� 1��%7��`Z�.�E�"�Fڙg��߻p<�E3�g����uCs:�:�#t�� �Ŏ1;
�STB�]/@� &ӜW��@敗�/7� PU�K�Э�x�V����T>t!�D�����x2�o�F�'y�Q�& D�	��Nzq���"�wB'�F�ܮ+|�4��aދ��.b��Z�H�&���Y|��n�q �����pO���:
��S��zUw���$�^�_Z&,�t2����H�}Y���g���P�f�Q�&|
���̠9����q�~���NˀN#@��-�$����ӊ�>�0��oy�&�������D�,]g�� �#9��3������*�0R^�
�y�P*����fIP^F�rc��O��,ỪgCj2�� ��Y �.O�� O��F���>��0�.'Z�H#��&�I8|��23-S�%�2�� d�7�%�x%�^o��ۏ9�7��qd��'@���1�9�Bb�(�x�"�`��W��,��Y��:��u�'��;{�!:YD6Q��|:)�3��"�����j�24he��_-�g�h��b޴�"KȻ�4��OyT�?z���
��3�DSzYVP���A��ν�%ӑWin��@�Y��'8���P@�d7s:$'�Ȍ���<'�5�=��Q6M������ԛjRB�\=a���~�׍��ʄ��uXn���OH��B��)�g:�j��1���x�>"iƍ��Xԣb��,��
���YhkSF�5 sE�j^6ER`I �˒# �3M�=�B!*�,2퇑��q�s1�� ��������赭	���'��H<����q�p�Hu�����������6^mb~^���Կv����t���7�h�΀�VYc�����[�o�Q���,R�@�n�f��(�cܤ:��oͼ#P�h��i��o�${8����v�)�y�g�T7���	k��>y��Ԁ�֠UM:Dy���f�������q0_Е�D*����,���$=A4gX��N����� �}�R�0r~2L$�V���ACv��0;!��$ ��R�P��B��M.�9	vB&�0���)@� �zI��[M�"j4�ۊ6��j�`A��&[�2a�]�S�O����k��x��3��(�s�Є����iC?g��wA4�����ԅy��&p�s��ԝ�d��A�\�pD�z�\ ��g���w>�DR!�EA<>�:�Y'"p�����#�GG�i� N���P�1�˃"���,���#^�dF*��sV?��\D��9	أ��xO�΋�`�@�!J�G�D~Qk�P���؅]�خ�s�8���"2>����0`�S�LC��RS�_�?��0m҂p����lb�9�x � $�H� �љ0���!y}/E�#���t����^�#&�� ]$v�2��ʍR�����fl�n	�o�`
�����b�^(� �������L�-�t�	lNĒw�`\K�5[ᙒ��C0�`�����A����&��$	�94Z$& ��i�'D�-�	���+���p0hI$��("%	c�f ���T���D�S������DUv��h�lfL�v�<ٷ�Z���5�)2��ӟ#����-�=�)W4����a�W�z�lwg#�>2A��;POc��X�E�Q.%C�i;���tIP���%Z/z+)'��(w��M�kߛ�Bcm�6�@���ghIxzZ� �F�,���_��z;.�(����7�P�Y�D���Q��#��!�50��Z!*���t�����W��כ��� ]��:�{�1���M�r�&�,n�%�JV$��y�4�;~ZWT=1,k1a�NX�D��Ҹx���L��*#O$
�VxR^b(�
�kB�}@�MP+̢&h�W.�A�MuNg����F�Qx�,�-5!�O���Gg�[�)p<��3���KHL�X�κ��Ȅ��
����%8|<�2��Zi���n���|ۀLm?��m6���^�S&49�}��T�I�QP0�9
�.-��A��Ӯ��t�&�����&�jS�]*#<�'��	)��+ґ�|Vn���^���@vh����`��A�Ҧ��i��._���H�	mTָ��6�������d�/Loe`;�גg�,XZ��10��$���%.PM{���|]�4�K��˶K���bO�*��^��$�3�>ʊt{vj�Ɣ:�ڀ�,���L�v�@�S����ӛ��.�x�h%��]F��NA$÷������R�l�� U��&~��دM�YN�,��܇�E+���p���_�"�c�`��ە�5�� P������P��g���WP���k-ġ��M�}��dF)Vq��Ңe9�+���vA�GSm���;�aC���Af�Y2��1��mؚ���>QNAi��O'�,W�$�U�>��������0��:!)mNt�X���l*��^\0�$� ��,��M4 �<f�J��@x?�����n�饯�����1��qcD`�֛��A�}�,\}�53���(n����y����Ym�4�Գ��0xj|g�c���a4e�s�t@�I��eY�(F���r�E]v�]�H�2j׀��%�b8r0U��'�] ��E%Bq�cV���t+�Y>�;�RH�˜�1g�����,Z Ke������+At�Ѡ!��>b�] 6D�J�.2��M���{�WF+�l#c����2��]8`�vI�O����y�	� �I��i�M���ދ��l�Ry�"�#(�c��7��(X9Z9�:"qN��x/��`���W�ț��0�� �e'x��tD�=^�߃��C���p{:��V6i�hF�;r�R����"�Y�o�>JL����&�(=Cf�eHnL�G�Q���F��G�7��3���!��m͂^o�;�c��}������V�l��������x��/�Td��(�QUL�dI��A|=z��x�FT�����q#p�ⳄC#���4R��3��S�Ʉ$�+ꀼ�LPAl�z1!���
�HHl<�iP���
�1��WBA4SaY�ȴ�@R�o�w�,�Y&����+)�@�Q�vE\�M|�٧�1����+�)+3�Y:��z7��֛ν}��6٠�r 9�B�^��绹'�0s	��C@�b��%����t�O@�g�,����5H�!bv��z�3[h�zPv#�Z�Cv�I�}���pЂ�œs�����t��B���NF���	�������"�������qF��7'|���Rm�.Z��ArtC�F�
0��Ȍ춺���D�/����|6�~d��Ph�lLM။l�Z�����h/`�k�/	�"mcF�ER�:��E�\��$"
����v�
c�����4w�{��:	�l�Cf߃�t���Hi�|���u$$� �s�V�<�����N�MP\�:�7���|�����V�ʢ��HV�FO�T��F�"�ڜ�S����6FH˰�"��eFv,q����E��m��eEV��^�y�:� �>� �0��&�>X���}�J τtM=h�.��L�(Imȑ��Y�q'(ks�%��ɤHU�₄�(���`�^jm�	�/�go-4��	�6\Y�c',P	.�H�<��߉��`/m�R�_��1i`|=~��v���ة�MP�:^�ވ}�c^ődA�2-a	�<��&�;
�lA�06R|H���ó���
����;�wN�p��D;��=��T_��v����y��wL씬��C��:,n�ѳ���X��0������t4�
�!P�4$��<w�s�³3Dh���z�v�h����R[�/3�	�E3b��������'��ܒP�]�~}QzY�A�SB*[����Wdm�����+�tȕ����
��C��"���^�J*Ɔ21
,́2��?����.&��
Bͫ��+�4�OId+��n��
�t@�nC�9�9���E@��}�iQ����{�I��ڮ�T����ci%T�Y��3�2��D� �%��]�<���5�L�2�����>K{��At����W�Q����iӱ?iar��*�k�G�d�5�R@�@��0D��\\X�H�N�'�r��0��n��=�2#��������9>4���$w��㔣�jW/O	8a�u)ק!�~���
C�mX����E�PGX���#IE���C]}��=:��p���!y.V��	�2\8�PV�=�ڨĆ��s��XE�:z0а����"mWvCث��<�\�G�J�ũ�Z�h��?m��3��l?{f�NOX:B��r1f�ϣ΢%R;����E�b��T���e��'��=�����̨��$���2p�+h��65M�u��h�OJ��6�_<�����r!%B�e�1= z��n�9�\������=	�r,��e�U���.
Է�a�~75���<$�j�]�.ù���z���A��,r���1�{C��V7YH�h��8j�m�a��9b2{�sO����Dso͌삓(�V��
���_&�O�0����	��QP	�]�'��"�P��O#��brL��1�ֈ�Ftm�L�E�`����c|t&�z:)\�G,\���T_1��������Ƒ���)%R�!�1�0�5��á)v0��Yɠ&Z�1�N�sEi�p,�H�f��rf0��嫺1��p��iD���X��-Ԟc��&�<�KjPq���m�	���1
�QI0�jʽ�E�Fz�%��[l#觳��`�5�s�u��IG�σ�<��E�<�3�m�FP��˞(V�	�B���j�Fyq���rB�b�Qt�.�#���0ϝ��F�,���3��P\�"肄�^an
M̅ѳ�#�ޡ�8��=0qJ3�(;�F1�r�3ׇ�� ���X� �z��4oW�x���@�,���x�H�&�Ȩ�f�H��P$�6���M��~��A�s"ǰ���77zQ���u�6���e�[ؚ���T'2"p�PT��U�n�x<o�H���ԟsB��]�M�BA>�PŨ�f��8��)d.��5(�'�h*�	�)�.J��6�84�\�����?1��\ơ�n<'ZR"��)V}��p8v�Q9ɦe5��]�H�����qb2;�P�M����k�I?$x��a-Y��8#�I|�$���饑K֠)Te�Ҽ��0�O,b�)GA%�u��m��dJ<�\�7`]_ͻc��?�k�6���`M�D�u��ؑ��%%��S��K�npR��Y��v��L��kL� ���ݺ	[r���Q�^���}�\pZ�Gّ�ѵ���߲����Н����C�,EN��UCP)(m����:��(�Z'q��Y�b%%'�h40�ڝ�GZq0q+"��u��Gs9��%���fR��r8�F7�ۨ����y���w����s��0�\�g����$�ll",��=�e>`����GT!fx~�pP�ݕFך#i�+hj��F7#��%�!�;(%�A4-ڭo�XZ�e�#mP�9�Z��e�z�8.��%�N;C��xΨ�$@�7L"N��"���˭TO�G�%�&6�>1�� 1�ǌp��M7���i�`uא��b�\pv8�����Qm���ʹl��Q�n���J�g6�7�Dy�O
4AG�Ɓ�]ЕJ�P$����s̀���W07 ��UU�1��P�p*J@O����z������d�>���m�-�<Kd����튿(��i@?T�f�z��H�f�:��̙>�	!���]�4&�'��ݑ�P�z {oe܇Mⶦx����C�tA��]�;pQ�q,�>wy��)K@gˌ�P���� ����P�aJ��u~lI@i�:��[��4�X�&�Ù���䐫�"���9<BS;!M�)�-ٹa_6��1?��̈́��k���Td�ѵ:`�3m[,y[	�x\�O����s(y��l�S;�^���yL1��ǃ�$���(�ge�6�vN�
]����[��C���;�Cc�ቄ���]J��#��-gR�Y%��a�d�)2����T��=	���	ہ�:��x3�ق�V���@���q���F�a�E�6g�R$Aڟ܎;p1�����+q
��#ˬ��K?��s�-W-�,��1J�M]�Ȇ����@u�¶i:��^Fz��K��pN��k��A@J)�]���G��� �r� �b�	�l4O�|�t�&������x�k�����#2������� ا�%Qz4w�9Ԟ��PDUX�àռ����E-p��b!�`���(�e�R5:3�� T@�,8 �?�̩-^L�+�9����X��W�8��|Z�v���U�F��b��\�s	ؙ7�FA�e1�4���7�P(� <��&35(d��N@�
%��kH����:
:�g�G����ld�N) ˹?i�F5�@%!���)�N����F�#��na�(�� ��~Y���i�|�k��'l�p�>(�d��ZP����n�2��i�I�0@*����_u�FX�7����H��ª���YVSY@�U�ҩ΍w���P8�)�XL�������=��f��'(��wz�J��])"NE�S3������( *��}��z`�Pv(�e�j���*�H/�*�.�c7�O챹���!�h��*�h�t���g�m�vP͠q��0dW���0�pU�I�L�$(à�.�)��t�M�Mt�TZ��A+���YKp�Z|�1�	�8�Ȗx�z~��	��s1F�Ӳ|Z�z\P��M:����h������o 0��Q�yRlܳ��-�1ߐc�z�V⎙K��_�ȁ��ef+t�����)���+�1�"���/�S��h8io�@~"�45B��@��J����Q��=�S��y��j�By�m�t	;�:G�v��(��p=Q ����E$���N��r(���R9$k>�������L�k��3-�o""o�C�B�KN7��-�J��H��F���U�c�i��db���w���+Zr�^�!����gj�p�!or)��!$Wò{P��\nH�}QR�h�'MD��J/ ��|1 �|�NT��P�9�V�W�㮚N厀[�/�2ѐD܆���,�^h�|Ʈ������T'�XdӞ8/3�
]_Q#C�5�:����'������z��ω��TM.x��b�+�|Kur�-���E���Q�1��3���ѷy�5��Ǭ��U^�����h�E.w�H��#v�G�`p�i�q;xE-=���kag��]��ا,J6Ð�� �}V��Y⬸e�g�����%Y�ż���:w	]��	ř��=�O��%�ϰ�h0�����,�6R�
*מ7I34��BJ>�|�{�'H{�!D)�����Yz��S�:!t��e�R�Ǽ�J���p3c|�`ar,�p$�?E���������J�}v����ԥ�%�}�i0W��Q3�H��Ñ�?St�X�ܢp8�|���v��tYK]r.a�c��t�MAd�;e,��P����S�Ϋs`+pR3�@��,��	m"�Q�i�mtgm����-��n�x���z�� O�w�q8�Tp�-���i�!N)���ӆ�X<�܂Ή���\��I	�!Ӄ"r���s��-VܔF�V�g��:wJ�x�`AI����ފ��F��d��4� �Q�|��ڼ*uF��:Mw�7�Mv951����\����N;kGɮa�`��l�ǪZ��p�O�vH���sp���KZP\��\t�v�[�Wܖ}�D]>1ؐ��?1қ���슬O5�L$�Km	�i$�)v��S��I~���4X�JE�H�%��);�h�%YX��><�y����I�5����-�ړu.k[�s��B��	RpK�@��\�X�9�-�K����Np���
�+�Q�YSV��e�4U�R���
�H�FL.���J�2�7���צ$)�:�����`�4E`K
'���!��*G��W� 6g���9bud���3���k���B)�E�Q��VaJ�;VS�l����R���F`�c�����U��FdS���_�ȢˌxRLq��]�1h@��TAqB���y�e���/ms�q�`Une��d�cV7�#�tN`3�-���) er��,��(��#�!���n�|r@�Ͱ�$�ʤ"s�Au��䠙�9� \�t7� �i]Z�&�(�Δ�N��*:Db�墼V�1�)-��}��4��Cת����RI�N*������y��ͨ,&,�e�W�!X�#C8y�MiX;ō��jX$�����eM��,౟������!�o��/yQ}a�:�E�l����SO2ҋA��Q�k!M_�*2�*���j�`dL=��	�_` ��S� %�Ԧ;��L?���!'�'���R�P���R�F�W�H�%�Y)��s�+�f٬�K�Rm�LI���t;��AiI.�	>U'-S?�#i&�V�w�9~.�Ҿ}c^�R��q��:!`���!�I�jhsE��,z�4�\�D��V\`q���"����� �%k�I,���"4�s�Z�׾S�a��o����a�K�:f?��A�䲙��:�ꐂ��y`��i�Tc���K`
�6#"c�9i�S/T
[�ךX���<c罏��2W?k��P�M}�S���~H��fT����h'[Wņ���g���U.�K]�6�-�klC��6����6hB��<��:�,�ǳ�4���p�^�2�g�%Rt�Z*h鶛���]�5���3*~R4i��[K<���u�vʺ��c	�ǑdR0����Y�f����)Y*�\�Ͷ�3?�<t��Q���0��st��Q���jF��M��R&�K�A2]�<�'��X"%y+	Kd���y/OH|j���$��e���尵^���$7�:�\�n��W��uL
]��:�V�Z�������}��E��9����eT,"pf+�"��]����T��0��U侽T0��6�{��#[� Y&��-�0�cz��^,�{���8�Ka�=8�>������B�$�b��+Q���E�Β��C3JF�?gBC�G�X&��v�L=ao�2*	�M3X:��n�̰����
Lp�ĀjiЄs?���WAa�jb��$k�4�:R|{KiIM�;��3��Q�u@��a`f��Ag�1�J=�	,ޔ�����Ү��Zԛ�B6|�7L��B!���_P5?�5kwgX:@��w���"|�j�~�*8�����>���}Ϗ���bL�þ|���&7�ñ�kv�[B�u��ld�T�[f��gb3q�%��F�nܿ?��^GP(�K��,�iE�ILō:A˒ \Fl�^<�db��iB��^Kp8���î�>R{��u��w��z��_����燝݆:ާ���y��;V�������z�C�98����<�骝�k|9�?7�������G𯷏��踃���������ps������/���;[�Cz���SGu�9<���<^mou�9�Z��]S���_�<6�����_�����M���yp�=:�	 ��]�q�����y�si�� ao�X�l�ʠ��~#�Ѥ����������g����6�>��l�x������7_�t�����Gݦ�- ���GU����x�1�`w�ngo��c9k��p�����"`�;[ަ�Fu�V�Yw�x�U��-a����]��c tvv�^w��9�Au_mo�>v:ۇ�K����e���a��ˍ�cGG-3��C�B�x���;q�����V��c	��<?��F;8�ކ����P��_X��Pl_��om?�c����{���(pw�٢l��>n�S��6�f�������<�9��c��vCt7����`��j�֊GՁ3F��|��K���{q`l�̝����jg�10��w��}��և�=�(�c��͗�p߰�������ǧ��+�}��KFx������x8�>l!�$tN�[���~Cm��cS�U�A���xڅf��W�te���	�� �>2�}��E�I��G�$�y�=�g2b���Cd~o�|p��}я�Q��8y�+K|�P�)�Kq�p�"at���pa��T�^�Ύ�z��3A1�����h�:����S�d?PF���3�
��#��@R/7�&�aӝ�Z
?S�h1p�bY׊�K:�9/ڟ��S���ù�uh����@X�	�I��!]�¾J����i��:�(�1Ν��e�rK�ɧ\���dQ7a������t6�C��&�F�=	�!^����/i�X?�F1b��h�W�:e$�Mv�<��pƦ�X7���-(��	���Zr�È�/�f:U����@��${��o��ԌLSCeY�"j��R��]=g03�]�)[�M������ƛ���9�	��,��A	Mq"1�7�HU"-e-o���X��	�@ R�����=��Zu؆w��q������yC�ŅRr�{��$�̗�Z�)�l�-����fӬ� �N�v��:I��q���8�*-�Z\C�E�G&�+h,m��ĊӮ��l�<�KY��(bM!,�õ��d]5
�.^��f?�n>`�+��"�{��  ;F>D���t:�h�...�gɬ�fg-��z�`�&ݸ�M���N����T��|Y�`�(|+$�`�
��e�W�(�klih*�[	q?�i w��q�EQ60��R�F.v����5��������7���\������h��qw�W�yDg*ǩ������/�6-��}���hy4�q�0�]o����$EK�#w��]w"��hY^N��H�Be^!��9�ނ��z7��/;�ީ����ض4S������k	w�r�V?�ghB3�5�L��黚���)S�)�ZҨ���#�^m_A�/�EY�b�P���ϭ��+ q0�.VƫY7�)�V̛όOݿ8����$Kh��h��r���pI�k/)[Pc��H7�X	�|�r�ľK��ȝ\	�.� ���ǌ�Y�KI�㲿�׉w�6��3E�LА�y�vDqM�)o�pm��{t�c.$� ���q+�!;�ͳ�a�P�+�5XR�2n0z�ұ0���(&�D�t2�l]/W`�WFg�Qs8��t~����O{��ngk������������������?�k~�������_[__U����V�V��|����J�F�A��`���e��'����_n��oQp��=�QC"�������
|�M��������G9�J/\�Pe^[ ��?�T�(9�AL`?�}`�#~��4�NLKt<��F�
�F��-��j���1�	�a]�	����ooy�!%,� &B�(8�t�]��7\�z�@ Ǥh�Aч�0l�j��d��i;}��V���4C񎢻��?E�;�Ф�P%�j
���m��Fo�Yn9�m���f�=�aY�^��9���o�S
�K)��H:��Y�{i�I�����<�`�{��Y&�̇��ɶ4�k�� >�I!*yp��Y��"�0M�v\� v��=zb@�d�z��aN���y)��
���H-��}�^W�"<r����X�UC�z�.QP��!��N��ީW�����aV8ǭ���=�(�E�r��_L9��)�}���`h���iM{C�|0/u_ˠ�8h �t�((�٤p\6nģc�gH�&�6�dv��&nǉ|����D�Y�-���Rgp�'�Y4�L���;N?Hi���m�wK�����y��j�V�-~R�UL������+��J��I{}c��)�o�+�l���,~Z��lK�yж���
@��Z�*3���1�]]��e��I�'�����'���~��N��i���'����鱽+��4]\��^��:�?��_n�ߛ}y /�Y�+-t�CkV�$w�Qj>��ׁ;�Nޕ�7������u�
{�Bs>W[��4�.�8":avF/���-�KȄ��}�C��͗׭%�'WX�Es�܏!z������uC�ytTA���!�f�e�좇�Z�g졭��* E�H���py�*�c3�ΚR�/P������F�t��W�q����'����P���~��z�+��5#�����I^5&u��1�S���ݢw6+�5_^{˫��5�f_�t�q��"<�k��;��t'=#>��Z����F�2� �
gJ��S��.�)��{���w���~6����{B���Č�4�l24�{�22��W������Z��Ǧ�|��:~B�8$�8@����0V�oT�w (5U�4%g0��H-�X���0X~��0Α�` 1.}�'Xx�߭������W7�o�>�8y��\m�j��VF��en�-�.������Y�/��2�aQ��twؤJ���BH.�6?��{�����ǁ��>D���tQ��������5÷ȉ�l�ؼ�\�װ�r�k�yl�Ӑ�k!X~�Ϛx���Pl�7���`����������+�� �EG)�Z��E{���l7�7Wo���k�m �K�U�0_�g��A'l���n~�\=i?\[�h�p������1o>]R�dX]��.�I�vk�Ќ)�f�b<��;.`��{��]�뺫XիL>a��oSu�ܣ�7# ׮�&��)� �i�ŀ�t윆���H�5s���YG�j�x�[��1 �'[�g��;�'.�§�쾣B��Q��#yt������~���$z��R���6��ӭ ��\� �[Xk��c\	�}���}Oz �Ѻ����t��p:��������lXp�S��������fd���i��O�(6� ��n��ҳ,�p�y�0������nsr9,�<�C���(?�O�qSj���6�'�o �����+~�okX�8l3�O��D?X����p~�
S��F�S��g@zi�@�Ie[4^��h�߱@������ H(Y.L�Ӡ9���<`/&�T�O6y��z�M�Ei
�բ6�}g�=>��Q�è��n	�F�`��=�?���{��RD��~zDik�R�be��Pr�j5u[��Rͪ�M4� ��7LU�{x�,�����9U���V�g���!<c�D@�ŏך�YBk�&R����fg��9��� 5�� ���k�>�b�k��ϟf���6LǑ�h滅p��W��ڽ��L���	�9R�^�֏c�(ȝO������ �{;h:�/�߁�j�_Yp��T��r(�����fdĈ��SS�g̫B��p�{���s�I��XxS$�4^te��k�IW�c/�2I6�V8<K�s��[r]wF�;w��F�d�{��z�x�O1�^��=��Bcz�m�;�3pTl�Ø��r~4n*@���Z�0���E,/��J�~�],ܑ�pSd\���r�8U=cmj��/�͒j�8L����1g����p���3dc^���F�б�QئS����E����]"F�;O瞖��ջ�M	ZC[p��]zN,�$_C�F��w��g$���-�^���
K���B~>���I����J�G}(~�-�v!�D��%��I� �ؽd�[(�	��z+�]hl�������MZ��]��˧���e�B�w�R�)�7Hs������9����ߏ�v����E6���O�)+vU� N���0gS6s��k�A]6�:��Lޞ��Ps��V?���&TJ��eQ���vR[:��h�d����t8�*�/���X�	c	O-�`�s�W\�=t����_��q��t���m-��wN�qlΤ��u1��g`��1��:*n�h4Q�ú�\��Mc�f�S�)>�,�V�P�M��M����UZ[v�5���[}�$�؏�2T���y�\1���{#՗2d�ey��C5ף�����׏^���ipS�bFg�9�7��}�:��@��p�g��%"��N��zAOĜ�{��+͌��C8d�<��>���܆�쮒�M?�7��]'rC-���Y���Yt�U��L�L��qb��U>)��B����u�cQ-�r�А
C�v7�i�Wr�ۙvc�$NE7MN�$Ab�'�6<Ӓ+�"��eR�)@W�����z�1��z�J�X�+�q�zBв0���\}�fgI�'��;��Y`��_��,����;�������1�h�-�i�ϑD`:�N��W]���twF���_�c+Ԍ�N���u�t�{��Eg�
���7�|�,�����ؠm��t�A�M�=�y�A��E�v��<(~��7���C���>
�ǵC闢���I�
�V�١[�S�J�xgk�!?��b�M|q�ӧ�8Dn2=��˂РBah8�N�S�#���˄��o3�%�v:�5��*]ĕ�������g��C���h��)-4v9JELYyfs8���{��>p͹�͠�Z��g�I?�l��v��*�x�m��coe�>h1X�y�-��jꉵ�PA����!��Ё_�-o���l�q^xF��v�`�yL���j�-��#H�}h~�dq�J6΃��(�#��7���WVA1��i��{�Jx��5�FUf���T�<�ۑ�?Nfw6�0���V��C%2o ��l� vbV��`�i��y2c���St�z����N�Ls�7�������^�W-��'����F�c��46��D�/gby��@�����]�{pݼ���끢!���ַ��b��I[�]<)i"��ê;�OS.���o
���5���p'UG_n�◳%�*�e�F8K���{���ܥ�vqN�|���;�t�$�0ͧh�jx8���^>�U�;�u�`����'^'���YrTgE,jd$�*%�9����VR �0�2�R��ʠ�̓������2����L}�)��X��7�lT��rH����%r9ê-���;:�>B�R�+]�ڧ�.)"�Ҍ!@�����sP@�w7�)��X}����h�I�]0��gG� �g�
~,I��z�C��s�ٜA�3K�X�s9��8/1�m��y�΅�ߥ�(y�!�s)���[pK��d��<���u���9�J�B?�%\؋�p�Gi����,��\ߔH��ve"��d����w�{Ϗ_<���w}��!@�4��!��a�!��*=7� 	��Q%�6j����¿��DrS�L���1����о� J�M}��:jq���������y4E}g���y{�'lQ<!��s����C���HW�v�6�hm��.>7� �G,���� F5|�IG� �)A�J�,��?-bY�?�U�!J%;~�WP�콗��ý���{�ȴ�s''pNU�Ϋ&v���Th�o�hFJ��
�C��R쇝O��Z��D
�����h/	���֑'U�3��S&h�8�x�t+����X�6�n2�e�f��p��z��yI�A���Ķ����D(pId<���*͋�\D�5���)�"��	�O{M=|�Ey	�6{��&-*�`���7�*��2��1}��}�~B��i��A5� !0��) �3BX�)�"4��%�ᴱ�r��ՍrWuW���Ah��H�$F�l�d��U��<�+	�$J{��3�#���ps!�?��&�~��T�Э���s�wvz�����cb�2���7Z-D��5�5n��|�E�V�Wުo�=�cW����� ���m�(��u��N�b�\�O?�:�i�t�4�N\:������������j�<��R��_��Tӛr��|^	'[,��.�b~0h�)b՗cq���������Y]_{x����_���?�Qp#�1��XU7�s��fF��bx��6��b|+�2����y�@q>g�t~��u~��ˎ7�a�%Ƹ��?�v�T��ۇ�������{߆��a/�~{:h�������������VW���ԟ��r�ط������q����:'�Q2�ǒxEI=�o�I{ڱ�Yvҗ���ʊ%R#Rv�����c��Ŷ
��(K�e9�&f&#��­ Tu���8�S,k�ܐ��iQ��TM������f�tbk�0m�N�E�$K�[rݔ͖N5S���є��"���4��P]�U�"�Zݰ%�l����Ii*Н�!9�#��#��6���FKՠ��e%�jɚj�RS�d�%ձd���#��bZ�bAM�n6eC5��(���:t���V3���mԥ�m�R���!Vl[QS���l�VC�%K583��q���l�u]ݔG��-[��j�Tۡ�]��IhE'�TCm6[�NM�-�-Y�5JuC���7�VCk:B���]�CV����d��4t	�т�k�Zu������uD�Ȟ̴��p�zS7���e�4%M�4E2��e��S�"�����)\zn%ձ,�1-ŲU�|*�fӐ�zC7��NY�KWgQ��x��6U��,�jaC	 ���Հ���DMY�9�iE�-�J0/r�a�Z�s���֔�FKk�R�V�,���m(.p�H{3�nK�3��hk�������4uzd���k���eS�v�ʹ�fM ����(-�޲L6͆5ݒq�zKm�$ۙ�L7aߑ4U�� hX7L�T`/����m��P���Yi�S��Ʀ�Z�
�*���0ǒu�13��RT�a;گ+-S��-QP��I�	����-��~#��`A梤�Հ]�6aa�M[���Re�zXOrK���Q3;�̤V�{�Um2ig%EmPC�1nIM�:F6Xx�d˰�����$�R�����x^�C��1�n�RS��=D3�V��6m���u�hB}����Jl�뉞������ni�܀3V�M�d�i�EW5�M�,��ǩ�b�9��ðYpx�^�j��f6`+����&1UU���[`e#�5q/�+���-���ab[�MZW����yS���E^"{���]6�6Ԗ�R�k�nJ6�|�8���l ���MI�Z�A��K�jCQ��0-8�a�S�(p48 L؏��l���u��jOx�遤���[��0��&4W�#��~]7d�!�
���8�0�TulC�U	��&p?prj�aj��Î��?
Y�r
{�*m�nnKu��%C��lS���b7u��﹒�s��U��Ԭ�f�ji�ݴM��T[��jz�_��G,���>?���?,š�g#�@��6-���Z2�#p4�V~s�Ɠ�p\[��P��Ȱ[[Z���O�;� զ��fpn���M�6(��A)�-�6�	�c��7�F��(G��m�twK*��a ��ަ4-EwZ*�%�|��Amٌ�%NCqZԑ��A�uKW�a�&,<��`cLSQ5'*���]xųp��DnB�O��������\ׁ��A��R�_D{�a���y<��X ��5E��5tE��GB(��u��a��93G_�M�N{N^��m�b�hc7�[^/����C5�'���n�����N��������`b�>%Jk� ����p�d��o��� ��t=��F�Bb����Y&|�b�H��� xY���V�ң�+tu yU~�� ���һ� �K��7�`�ߛ���3���x5 ?p���,H�M'[�cbV;�ŭ�'�����j���e0���i�X����j�9=6����0.��.�O@�o��+jU��ʧ��`PkAG��<r/v����f�4'h���k�U�_yc+����˙�b{M1�I#u����Ħ�~Ap���"'���,� �-tp��Kb��=�H0��=�]�������#�`�{D��E.�S�v��y��FD�ig|��Q�m[x�jf�\>~��s������i����ޯ[<��su�K[��Ƅ�:�}j���О0e���9˺�c8g,��3xB�A1��}`��uҹ�ֈ���p�cli�B�Rꕹ�5:,�}XC��8C�x¬f�@�D�g��Z��x'�X�ᛵ����`���ME�)۱L�i��(��z(�!�ie�&nD���3�;�#BMVý
X�p�FQ��{K���������������r~�:n��e�.K	�_���_])��u����Lx�2�<)�i i�ZoB����/������ |�)��	���$rhN����_�]K�3�q�
!b5�egp�o�QdbUx��pq^��������{��s�rԕ;���x��xY#�q�z���و -��_��k����q�$��>���a���.S���V�A9�� �-_b�*����
 �����4��̤ə�O�;� ����BezȎ��8�����f�	f��><x���x�\�9bg�8��X���~-CR"�ݟ�����tɘZT��k� X��9ڃ�;��e�hC3��.�̢�������Ya� �J���Vh�8c��Bg$���M3����~-�������A֋+�8RjC U.ٞKK��ʴYegò�������:"�d���Cͦ5w:��Gӱ�)���O���0+��6y������V��^@.��~��S+O���*���������T̌�,�V&_��x2p��/Ƥ�/ŭ�x��m������H�Q�fl���F|��GҫL�mR9�7�����4���!9�ݲD~Ђ�5�� �~�����@c�U�3
,���p���0K��F8���'3��� s.�5=� �==�:�E�A�zPv+����@Û�↗@3@�@Y$n\e
w�Y(�MA�?�"�,���3�Ú1ۇF��ÕJdI�rƿ �m��q�L`k��'���9 e��$.S�1��I9���3~7�?N1�9�ƕ
;O��@aaFat,��?>�3;�3/^F?_�ܝ�E���Gn<�}�&c]�O�H�3�1"~I�����+2`���������D��q�7�&cx1@gc]4��o��v�	C�;�mc�|(3��PV|��}Nx��$��yV^{�a�#�3�Ec^�(R����|b7���1�0'�ٜ���&2��t�j�q��8�]qf-����,��p$�����Fʘ���,�|:z���Gh�Ș\E͚!�P�c�Հ�!�>�����|�;�/^g�b��C�T�(��R���j�X���ʪ��������ja���T��>��oJ��y,���p��
]e���u��]/u��x�g�<�N&p~�g�����l�\;��c�lEZ&%�YW�B�E��+:���ç����p5"�h���T�]��~`VЛ	f�Bf7έ��[�+����c�~,���ӱ��$K�"�n��=�g���{�)=��NGJ^��-��V[n��vR�ق?�K�7�\mֿ���D��p���V��u�B��Q�����OU�c�/� �-��XV[��VZ����^�c��oV��.�?��^���Mw��lHra�����C?\�ο�(u]b��$I+�)��A���Wu�^��:R�+���q����b�_K�qc� u�~��Jq��'��B��:��Ȓ�g�_�k���Z��Q4J$�'�8�k'��0p�o�@�8�L,��{wK���d���:���������XD�#������������ɏ��o�uU�����q S�?��yb�����zlC��]t�ˤC����D= ���U���A�:�)��˻�Ǉ��6���6善���YNE>��$څK�����M'<�8襅��\w�EJ���Ͼ�ֱ��'k*��?�-i���q��Q�kI�yڼ_���Ԉ�?u�.I��x�[KZ�}������j/ʟ�������ݩ������~����=[��ْ/�ϲO�<�;����@+�C�;�W��G��e����5�ټ��2�A�٪_�V�^�0�x∈��uk�(༴nm&���ԸUZ�ƕߣ/\t
�����e����v9*2��Hڹڋq�٘�X �M�~<�l�K�%x	����~M��C�F0���K���Aj��w�n� [+�M�P�ۙ��_�4��Tq���*>E���3�Q+���g4+GW�<OK����^�
@è�uٯ)���8d�	d�mh�#f��]���l�����r�s]�q&B�q��p��-A`�r®�n�EAb�t�t}���t�u���N�.�<|�U"-��{������|(׫�'�h,dM�1VG}�h����YqE��JK�ſG��!��u 1�L����T�����笮�-�:�\݄��	ք8S���yR 4�'�;{o���0�?�ؐ���1u`N�u�ϲVc�� �g���˰��)��C�@8&�%��Q!����0 ���'ƴa�k�[g���)Hd��Zw	ō�ф$]��r�"�T�f�<L�$�6A'� �J�H�`�؀��Cb�)w�6L.�  ��+3p�(� j��6�B0z�ȣ}l��vP_��L(F8ϔZ�x۰�-��&�>ƅ�s��o����䙟�u�������D'��f���2o�ɱ�����HP��
.��7�n���FuM��M��������ד����^L�u��S_o�Ή<8=~h]��9����y������7�+{��w��ޟ��=ܽ0�������˟jGW�7�w���׵_w:�V�ܶ@�~꯰3��[ʜ?T2#��ư��|+(Ӵ	2�@%0�;Ϩ2����l�M�g�{��
�F��i�KpA���W+U6��lhC���S����K[\�����-���>��u�0Pň��W��?̮1�f�n?��y�&�}7~���>��#����}�_���Kp���꟯��ݳ��ޏß?�k�������Kviw�y�����~|�z}P�u�U{W��������濕c�oӄ����7ni�9k~�v!l
�)�٭/� �Q1�=͇�ZV;�r�"}�Q�#��w3̄"�3�����pNSp�+a��|�S_�\k��z�+#��#���K����s5���!ï7���s �s�F�O^��ȱ�6��"���d>��b�f�kL�Mۻ�'��Cq�h+�a������O�?ȕڒ�Uǂ�MU$��W���zq�������0n�eP���ˠܥ�������=ñq�O��P乘s���>E��J�N����3�,� �e��x�>� r�["c�����)���� �<�� o*4k��]x�T�R?Ѝ���^�����0�D��LL\ׁ�!Ƥp�M&�< }ʨ�h�w�gL�cT�e
�Ϙ��,����&61Q�F�po}F� �Q�BJ�	.��0b��ךqc\D�>/�T�I|�����h4\8�z���R��~R"H�3�N�捃0\Tyw;�ow��"���R��@�bY�y/>l;�u���u�>An��`P$=|��*�3zq����,�2�@O��W��wЭH�C}�d`���z!�d�u�%I��z�
PĽn�7�[�0lu���ɇ�������`t��EB��R=�SE����06UܛwR`��2���N
*��kQ�c�6{�c��	�|��1LB�Rs��U:��E�#<�s[�H�����K���x�����ܟAq4��l>��Xh����O�:��W�]�Z��>���AR9����)#�S�
�Uҹ*�Uˢx�}�,�n��6�:���F���5�����֑
�o�"ߜ�����Ps����畭���&����k# ���T�O�6��!֡A� y�gN���<ɔOb*9S��5-����0ត����sE�1�î@�j(��	<=d���; ���K�������
�H��m�8Ia	__1z,'d�\ `��Im�=+aઽ�s�!9�lb��||�zvD���Ўճc�L�j^G����r�d�E�$�kis�-�Ye˞:�L�{���A�7�e���9��Qh�Y��ۡ�26?�A��#�c�&��k��n����:����gWg��/�Ą�2�3��i��"����?؃Ӓ���4�����&��������(�֒
������0?��n����V����|��u��N�6�`�CݥH+�W���ۄ3%p���K���_���C5�^h�v������,��Ix��r�8�ב������z�ǿp���x��аC��1��?�C,pp��A�u�2d�_�#��~c���q�?15H�LTɖ��/� �2�*.�4�v���"�+�U����[��a�Bp�����)w]��U�bg����-^t��H���0(���a
q�]XéM_O�I�&jyr�����v�F?�~�]���(ﺫ�;�=��>�qt���piY��>���Y�o�\���������՞�g�v/��{H����=��&+L�S�B�[K*�>�)����~��B�o	�oI�o���]��_.��~�\�@�|��e�r<�f���K\�����S��2QkiI+f�.r*��=�z��x�%4O�����������<�k�rS��\5i�:K�,��ǻG��07�Y�a)!�B��I�%�xQs&ވ���x��
�<��:>��[������0>�þ$�;T�yҗ�o����o_�Z�E�܈Z�A-t�Hh1N����*�&9��rs��	}�%���;I���k������Q�a��\Da̿��M��+���@�ې�PMD]�?EQ�0{����n/�d�>d
�l<��]<�Xp顽���)L}R9�*g�7���n�Jo$�������=����������kL��ߣ����=����OgS����*��9�T��x?\a{����#���lKy4�k`K��;��v?�|�bY=+�:`���Q���3�X<�=�=����x	�%����6��:���Tl���*��k��*C��mR�$��Q�ÊK�W	2l�o���>H%}J��o���ˤ�!���>}����,��ȧT��J��k�O��Jޱ%���,t�4��|�&��IF����qc��Y����"���KO���߶�p��\;e�:d����e�_P��2'L��	��,�<܏RD-�=��� ��b�1E�vw���9Ŷ�ر�_^�$3	Ĝ]%��a��qc�Β�渞W�������2�H��W�0OO���5oz������c�9�<��q*��
�������PH:쾫��VQǂ�U�����\'��K���-iUrZ��f�u&������=�،������L��W��*���Q�ҫ�R�ꙻ�9W,�nXqh��;�㍌�[<������߈��Ż����V�f��c�2K(Ua�}���9|��62g��#�z�\�U�`�����;@��$�x1��W`��J�V�*1���:a���,�P����$�_E�}���0pABy%)�8�y�I,xIM��U������LV.�J�	6h�>[�!7��_�O���>~�8N@�%��x�dt����Y�p8�������K��{�9�8b �n�����s�^�s^���{��`<��8l�.7x��)^,��J!�����
�H�+�E��Q�̌���Y`�N���Ҭ�������K�S���5�B�s]����U��Y��+ll���t�?�\�Ϭ��|���l��W�>����-�F�]����4+�I=�������d]�����ϪV��H���.�oκ�Ct���
]�%:���=�D�;]}P�oro�������3i�^Ɛ�B�>&��#p/�/��|)]��ؗ(��J�ۙ�~�5(j��s�d�n#�\*%�nkR��8����A0���w��*� zp&��8gҲ�[VtK��ې��vfn��H7����P�u,�������3�����:Ra�������� 7���Tc�ߩ0?�)�k�Nq��K��]���Q%��LE�LUs7�d0
[r��sV�+x��pf�'�� ���2b#?7��oN�R���W8�sc�*ue�3�����h<5]��i+�8x��sP`����V"-M(뙟�9CŤg�����ˢ�0g\a{` *,�=�|��9дo�04-Zۢ[\\��3<A��f�S9�V���F��4���2+[����7�hJ�j����b4� ���%[��>�8�g�W�F�G�j�&ްg�$�{�m.���/��� ,��X��J�Y����jZ�*W�զ�},3���t����{bX V�wЁ(S�c�
�U<�8r'8r|�HX��X�E��%�6Ï'��B+оVS6��&�f�Cw|��W6 yU~@�4�4�J�(ƶ��
��?oZ2�ӽ$���_�D�S�3���.��:R!�}񟞾���z�$x10
9��������ɏ@�CR����
�s���	�'q��:�h=�"����1�g���Բg�� vs��t�v=`��nS���2�@&�"Fؤ[T6p/����a���+70��ד����'��#�
^y�V���7����,v��,6�1ހ�V`y�nc���6:��;e�DB�8�_�Х�7�4,�O�-���;���ֽ���D)%F
�=1� ���폩50��J�߉�����h��Ѯo��Ќ�V7�����0�w��Niv��0�ǣ.���g�uZv~r��1�Ɛ�7MP��O{������'}�$�#���1���=� �zH:���厶�]Ԉ�I�ǭ��j$��soT�p-�%?�;�	�n�n�Vg�[Vg73F�"��Pҭ>m�� ��:�� \�����Ȕ��\��O�Az:��#ޤۯ��$P�$�;�	+ou'�zxb��%��M>���$���|,��B��ڃk�>�DЊmB�m�%�*:�(Jp*��<O�)���Е����j�w o��y���	G+��1 f�cb`ř�k�?P���}�<a� ;�-t0�t�h<����>0�-:�c��C�s����U�������}f��Iz�)��>y�( �5�`eu,���D���5���P�B�{-i��� =�;��[ X^O��g?�+HJ��J�H�����̽��ae-fN>z����+�k쑉{��=ޯ�g�*��U1!�b��������[�������)-o|l�k�rF�~��[JχW��h�㽆�t�t��Ï����&�{V����G���<��[�s�]w���	H��l_�b����:Z�G~wB�ތp�5۬�l���qɹ�q���Gc�؇� ���VX��O���!��hH*�����kI�W��7;_O���?|�C+���������@������mLf?P�"s�/>�5�(��sv�?�>W��4�����:nq�G�?Z�i=�8���8�g�8����ϐD�_�V-�����G�����]���kI+ވJ��� ����~��s�c�S?{�o���3ɛ9����#~�	��y)=%�>�����D�3	���0����)�n��;�^�|�A�9�Q�Ԧ�T3�����W�+����H% oN��Ie�+� TS���?�Z0���4 ��K0|�1���ք���7�Ҧ��n�7��Ɲ�s�`�x�����ַ2��G]�H*
�������̀=�I�����]�{d��<P�J�X���J��Sg��F���%�l9e�o8 ���
g��d��o��6��1���f�<I���WI��R��:u���Q����,hX�� F��+h��
��G4��b�t#ő��]%�X�5H�7$�1�Jm����g��6�4�"/YK_Uɖ�� �F�$���(Lv�ca��L� �| �AP-=OA3c48;0�.��N}���G������OjÁY��-SA����%s*ȝ��e��gp�{�V 4,_�_TM��@�JF�;5�7"�Y�Ũ���1{93��ý[���O��T�� Q|_�������K�Kor^��J[N@'�LR�-��?�N�ƴ�`��%4�@�����ٯPh�tf��J�_���q�[���j�cL't�ˁ�q,�fHH"��`D���R��JR	�qmcbN��4� ¬���\߃�G_w'o��}��Ol�P��`��%¡y��n)���ߞtz_�oBZ���5%��]g�_C/�?�'=�[<���*w������%`j�=�A� m�@�*f�N�R�/��V�a�������L'��?�ǣ�U��g{������9�`��F��;��f�^â�$W�X�+�lƽMB��mڇU�84�F��!� ��?�C��^ ,>q)��+(l�0����� l���!�Օ�
����?#�_��&U ���x�!-Vy�'g4Mt�Q"!��o0}�ZX�`�*jF�I��}�\�����O�'���~�:�;< I�Cy�?q��$Rc� ����w�{l$�XO(xa;i3Z�>�R�*��<��qB�oD(4(F��u�5�%r�H�،��6Ӻ~�-v���(4-�l?�}Qcj��°��?�E���7��qr@qV����\�0=�������ҘP��w"�wB��k�����[bCS�>1�3X�4z�O�͍'hupAٶ5�ΐ�R�d�vO�o���fxh,�
0��Bv<�G����+�P��0�f��J�-> Ǔm��?r���UonJ���fW���ֱ������S��/�L����]O�m�������1�ǰS����{,��U������݃���O��������/��#�w���{[�w����{z�ޏ:�1\��h�.���+�YZ����.��ZW���7�����P��
���[��}����e'�m!�i��^3�HT)���q�Ǆ�ӝ�b�ϽI%4���b�+|;���!V��6>����a�z܋�a5�e<x�oA������.��2Wo|��ow��)]y�CՒ�����8��ǳ����-[�و -��_��k���db��P<	��#d���������40�UeP�,@O��X�Y.� 0���H�L��i���Tc��# �5�{$�� =dGbh��q�`~��3Bl�Yv@�L�]���=���q<���������eHJD��3s:�E ka�	�tB�1����J�\��ˡ=��S�XƋv��,��bJ/Z�����l��v���n<�Aʝx�����~�:c�N��O	sx�fo�{�D����1蔫DX�i����Š\�=��x!�6,;g��1�Y$,���}-�;BY�Z��B`�RP��f� 7��k
r*��u*���p.P�fh�fh� x�VRC�f$�l�s�=:�M	CoG��ǝ�>zlIƙ���7�=�>���T�;��q�C��[��>�ʝm2��g���䎁���`��w�X,o�M:�4�b�|4f�}��I���<l�0�=��wИ ��V\�H1LB-�&L` ��2Ӥ��!�9���+N�Y^(>���!��%X�����UP�3Bq1�:����f<T��t��b�4��9�l��nT�����J���o2�]����P�s9=�2�8-�ğ��1�+q:���Y��Tp�(cc�[��1	��cx�^|QIm|ic�j�%;�r$~Sw6Vuǜ���(z�Qa�?�E���;s�++���:��E'P�z0睬�;����|U��ջ��n}���������k�E������6P�_U��/kI�������k�y�;��68{��{q\\?�u�R׋�w}F�sP�p~�f��| �'�c�����"l�}�i�4�����:�uE��u]��o�9;`��Nn��Jd�N��w�J�ag�������ٍs�a.sE�ja�p�}k��`1Ȣa�>Bo��=�g���K"������t���n�g��I[V����P�:�v�ާ��w�4������7[��'�u��.��Of�?�����T��<��Of�=Y�o�P��VX =���bYm=�Zi��׷#z�,f�]����?�J�20����]C��zC)������?�g���#�.`���.`��#���-���K<�9�^6c|�����N_���a���SW�\�,Q�=��,���`��.x�{76��x��0�_�sx�{���Ŧ��2[ph}Z�l���fU���VN{�I�<Gw��3L�F6���4K�3��7�9�Ѱ�*4�|D�W�\摽����8����b�J�Xt�#������_���?ג�G�l��W5���d/jv�K�_̛3�%�W�K�,�Xxt^UsK6L�mu`��>R�&��M�%�j�8�䙟a��!��8�n�$��)��r;��7�p[ �?���d�=7 ��Nb�Gԃ�~.f��V�{�+R��T�"�HE���C��F p 