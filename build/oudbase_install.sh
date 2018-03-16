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
VERSION="v1.2.2"
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
� �īZ ��zǕ(��駨@tDhp!)�v(K��$&�II�c9Lhmݘn�#s��������(�Q���u�[w�$�v2�d,�Zu[��k�Y������־y�Pѿ_�k�_�Q��7�?����o�����o�~�~���,��L%O����`��{Y�������?��Oay�Y�ʇ�a�����7��o|�������ܿ��wj�3̥��?������(p����j��@[��o��[{��a?�U�yC=��q�ڎ.�Q:G�T�Q�&�4��է��u�sF�Q��4�<Rj�o�n��p:=�f��u|O�e�0������q��M�]8��3��L�<�F�0Q�0�j5����VJ���T6��K�лۏ����n�O��ar��^��o�S;�� ��&G�E��iRj���f��l��Cz
8��{Y<��i��#�g�8��%�H�
U��,���K��D:�r=��!�c�0�q'�+5ˣ������8K:T8�a:���W�M��y�Xa46�N'�f�}-gg�;mޱI�8���D/���n�~k��n����~<��>��Q�`V���
�gvE��oF�9�x�f����8�bK�_��"o�&}8���'�T[@�q��S�E�����>=:889������k�Y���-l��y�&�M�*��<��e6��W�h埰��U��x�`�q�b���ڨ������������nM����rx6���c�%�L" 40�Ӄ���ڳ���G����3���8p����vON�;{��+���	���VN�O�w��['G�?����I�>|������\���Zp|�9:9}��lw���/$W!�7���{g�k��*��W��^��W�Ղ���ng{��{|��濧Y��ݣ����k���~���,�!f}
F0�۽���z����j]�/���8���+npˣ#:,$����ӽ�\�v���M�Q<��ËL5c�^�}�������V߁X��އ�����_�Y� ��c� J5�U�N���)2�10{�kN����7eN���{o��q΢�(�q��Y����{�軩z���8�z� ��V��W�uO�5������]:��OԎ��~��9�'`��w�#u��v�@� �_���T��!�O�̭Q&���3�g�n���5}����v�W�M��8�n��U^�=F,�Q�xL�x�:��j=xO���?|y�r���{�UHH? ��o#�nv�!9Wg������-'P� CTC d�Y�*A�Y'!8߆�fΤ�Z]�����)���!0CT�߾���ո�U����_�m~u\�?z�t=:��5Yҙ����q���z��jn�{��נU�;Eyس7�F1���+��A7��¢�4Fo�b{;'@�D5����f��G�ӻW���fp����0L�_�C��4k�0_�k?���Е�i>\���.�5uVZ^m?M�2m��c{�jM��ݯ���7�s�gC"]��B�*�nj�f �ԛ�w��3G�_��$�'$yɱi�V7<�+pڒ�쒫u�9PThޅe�-�btK��\��t��$f�3T��:��5#��佗f(w�N��!6n:��V���o
��R��TBb�H�I:�C͑��y�yz�`(�㨳��5�����qa�`���J�h�<�`���"�G(=z�Y__y+���a��zC��p]޶ �Q�՛��/ =�-=I����=N��wYC�¢�������,����I��/]w���fI��؈z�x&>��� ��݁� -�� ϒ�Iz���ӧW>��鄶��^�7������yN�[Y�w/�Mзpip^�� Z�DLu_���"��X� iP}��-4����7<2��G�1!�(,�fG[�-ZQ搀v�{�jC��Ҿ��������`W��r��>r��ӟ��/�|�.�$	U��0�R���y)�|)(J3�#�6��6�\�ؖ?��h�^�B�*���t�bU6�@n<i���v2�L�;pP*�����P����p��,��Og�.t�K����=�𤫆q�:�Q�A�1�ڿ@���n�&�楝$�����ͨ �Q��"����`ᢢ��]Z��X�AƄ6+�F��Z��dOQ�X7�� *k����?]�����T�_�ڝ�7����c�� �p\AK9P����Q[�Ь��$F:� @я��l�R�US�6�� v1�0߷µ��,Q�n��<���G<�KUsl.��V�����+���#A��c�6��[AX�Ɵ�8pp��U��`���� ���آ�>��DF���̘���@JM�Ga�U5��e�G�tH���d)^>��"]�p�'a�0E;�q�[/���͟6��J�F�c� >q�a],�k+���绸���\DF4=8��y�1�ml�v�9-~�-\S㜶Y]uww�:'�)Ϊ[���ʟ�b7��=�}�nih��>�%
W؂�Ֆ�E��2nB#|�B#�e�1��?�؈�+���$?�3�Y:VS���i_�Oz;�P�6 �В4}�f������	A�#, >v6�l��5��|�`a�vV����{8�We�� �9�Æ.#8��I��j�f��Z�������������?|�-�vm���!��\���O�QB�/���A�-��/����E��u��n�� �#��+�$I�@ Ǔ)�~���(��Q�3��x��¶�a9���FU�ph8�@.���z�5�1��w��+.����o^��6�{]��#����P���Cl#���?9=����<5cu7o�m��l�u����)�4콅>jg����hO�m�Q.��	Р�M�wSTnV�����7I[�]/x����&-7��?��*�9�G#��ꎨ��Qv�'b�q�W�A·����R3�CG}ouM�
g��7�j+�O�׊2c)z����*=U:D�$����`T�w�;���c����ӱ
�+�cG5����:�V�˷�������GǏko���s�ѯ�G;���^�{�������Y���[�����38�6������wwq��o���{X���}���K���g푺F��{Ҵ�33T��׻��Ê�
'�p�Ҷ}�c,�:�\�$�r��P1G�Y��y\;*:����t����H. ]B�p��A>�"��7(~#%��꿔���v�� 4����ξ��ٰ?����j�:�,��Xoi�����~��?�(3g� K�;'r�
���\+�K��G��ת�E�]�{����=�G�����'7*/��]���-�Q~���h�X�>�[$��d��h�qc-7���a�O�R�$�E�)��"K��9���fT�+#K�f�#��}f�y��Eȏҋ�XY�Gi��Й��@c�t2#)	=�X/[+?����/s�GR�$=xP�UR���c���JsQ������_#����FE�������_��K����o.ܿJ��D~�@~�;֕��/������#��o1��V��?8��3E��j&��v���o:�������G����Rx�����s��nf�)1�7�/�yȡh����]Z���#%F��ݷ�wOw����|
�]�p��2#[�3�W���G���FUSr��,�͊�̃?P�u������N�`'F�9����L��緒�u�k&$�xS9 �K�� �%�K�?o�g&п@��ܴZ$���K���CބVHv �%����dp�? 6LT4P+DjN��2���D��	j��q�bd�d)ij&�D�UE�����1L �ɒ@y�9�G(z�����4|\��AZj?E�:�v*�D=֮K��K�ŗ䇥�ga��l�Wd?�_:�%��[��_����3��!�)���@m{}u�eO�b��|��g&6�24d�re�>,!a,9�_5�^�2�%��2�ÚJE9~s�FL�rD"��紘VK����vr�K5ƫFQ<BOad����䵲z�S͑��9�{�N�Q����H�&�BByݶD�������A�W�N5sX
s9�k���l\ �f������'���-&y���W5���5@jhO���&
�>?Ɵ 0������v#��%�� ~�8/RG�RQ�4N�Q��D���������X��3��]S5��>��恡DD�$20���y'�sD�f��:(�D����:M����Ǜ�f� ��D����14t��+�Zg�mF�a�~�h�Q���g�`[�@=��9�n#� �XJ���Ә{�)V�t�@�0�����B�]���\��� �qf�����W�3iY2>��VƋ�^��
&$�w���Oפ7LóJ;r�c�����ɖ�f�V)밼��w�@�>��Tg2,7�zd'�����T4��8��9F��B��۝��d�3!"Ĥ^f���[�cp�'�wo*�>�3�cQ�E�}��v�sҹn��W�k�H��]��:�x^�,�*Y�n���w����[["�����ֽ7�7�����E��J��z�n�	�tlNf��^���g�`��Y-�j����<KCW�왙�۸����_KRl]ӈ��	UB�!���5~��B�S�U�i��Ε�13�MӉJ1��������M���A�9~�i+�N�*dR)CP��]*;���vp��~0 4Zq�β^�ŏ�N�n����x��y=c�*�!\]�_�m�Q{zi2����F�%D��0JK��p�����.����a��7���Y_.��1��V����X8�s�sa�>C�y��l4�O񣳦d>�Z�]��V2+�zبg���������DS)k[�};5���$����\|����n�3� 8�U�܋I��w��kh#8l��
�e��������[�3w�R⢽˷f�J��Ҥ=~PTs�J�D	5�ro��c��s���\|�@7x�;��ڡ�wrt66	w�ӷ�&�@i��0���ԥ��)k�O����v�q>z�2x�io\��|Ws����.P��2�U��M��gIC~������Rq������(L�n����zI `�/��^�0�^�8�f��i����'�7X;��~Sk���K �w�m�6�U�}���>��1�Z� ��ٶS��)�"�¥;�#ȷu���A�X�v����9�ýj6u���|m��F�27�>�Z0�[�[��p*�xqx��9��N��+	_��o_���[�[
j��I�� jF��&)�TO*n��S�Q�����ŋ�\7*ТFg��Mn��:�*����J3i�Q���^!}uozY�E�f�HjU٤���e�>^�ZO��k��(��_!$�B	��v��{�F%ƹ~,p�?U��x	D��e|nU�Jg��S^X ��Oe���M�9� O\���8F��1*�),���ˤB���:3�4�>���X�%MAΥ�)��X�ɺ��K���|ڏ��bE�W����f�a1������K�|�����̅�W��Sӗ��/�_���_�7����C�4,����W�+ѧ����	ڿ���>~�!p�>��^G�����(�p�'�=�5���̓-���z6
Ͽ$��S'�M�w���B�o&WKuvw�e��e���)��h����:��u�O:�*~9�[���n��������T�obi���~b��@}����ח�7�y+NK�1�/9o����/��|�y�1��}�y���F4�K�ۗ��/9o_r޾�}�y����%��K�ۗ��/9o�'��3޾�a��t��f�9�lv?G�۴��3Q������P��/�+G�ml�����B"B<G��8�Ǹ	��Utނ���V?���]^I�M[���%+�KVؿnV��	t��0�-�^�Ǥ".�$�q0��0E�p�NZ�OG
����#Ά9��f�T=Ԏ(��3��>E����c%	2����bu�mx�*L?��q��=�A���z���A1v��X��N���Hۥ5�1�B�I��|`�^�s�mϲs����	���_??�P��1A���R�>.=Pv�_"A�D]�$��K|�NgJ|���I|�-�q.�|Xڛ�&ioN����9��w)�m�\��ު�/M{$��X�me��3g���N{���0�>���
lu����.���:�2;�ei`)���z]bD��r�ea�̷*L���TGnI^����
�`+n2���\\cUlUN~�3�J=��X��U�I����4���a��
=�2A�������]n��m7�GhM���r�`�ٜ�t���V+n��~~��-ӯ�j����W՞�����;��e����ķ�_g��T�\��Y}K3���|>�[��y.�|!�i%�����OO���T�_"M�f)z���w���y^��M�<�yx���̦)��BhFʒ`���#��pɺF��'Y͆
j�G��	l�%ɬ7K+̞�W>�l��Y5�*@��~`��~�.a�� eW�HY�wy҅�_��l���CR&ev��2����L~@�����g�1[����������?x��%������������'��cS��|mF)�־d��� %�n��0�1��R��1�#��gSO��R.ֺ���RꟘ�^�Wża����^�z
Z�VAG&Qu����/���?��x]���#5�샺��e>���l�d/�����0%�,_�(y��}�y���os=��q"`�y�ymDjr���z���:M��N�@l���x3���luv�VT�gn�� R&X\��
���*���B�D�y>��Iw�p�s�=���h<��
����`��։��I��g���}�h$M��u���z�G�᳽��-�K���k�N{p�[h4�E�8���@	����N�z�����]�t�QL��w}M�i8m6� ��5�X��S`=�`i�ymia��(�%Sk�GTÓ�}8.,��d0�T&F`����6Y<Nd|B���z:C:��Q8ص<H�`K�4�Zڜ�66s\3�����Q�	��X��6����qԮ��8�1\��14��g�~`"��om���
���`��-��`�h>��ˁ�I��'���l�
2����C�ĭ:K��-ſJg�\"�ެ
t�]�O���Oԣ������!��8�O�E�[������|��c���I�+:yi:�pp%�4p+"Zpˑ���U������{tZ��ٙ���ba��$&�8z�f4���Jӑ-��^�_�.��6�  �������`d���n;ٛSU̛9Y0<�,�βD�31s4
U7���L͗⻯����<8άzf�ΐ�M#L� �0���ѕfq��)�2�,�:�����e�)�z<�!��Z9Q�4IK�;��ۧ���v��תl�X�o�D�;�	j��� �L�
��``.����8��gD��Ԫ���o(�h��څ��?XB2�X=�*���sY�N��6�]�c�]r��*�	&ת$z\�
�?4���	�7�RN�@|��f�tn \]��\;1+6)8�+ff��c�h�T��J+!$���ߧᙙ�WX�F���t����ᄯ����hDwC=}`TGy�)Iy:�b��[��tu �ۨ[ق��|���/�ǥ�kR����INQ��=�4�x1��<gi�����%n���D�}`H�'Fi˨kjUb�6��*O�W^�Z!��,g�SSU�hd/Xډkʫ�<�i%
�+�&U��� n5��VE�ҧD��-/���Hr3�B�7���g�;�9��)a��j���a\5��ń�{C9�M��s�o�`_EC�>���ۇ�����m�ᗖ2n=�ߕ�|�$�3� E�5��x!�J������$���ÿ!
��'�!`����ph�=S�����0������A�&y���z��+&�`y(���GC���h[v!�_����+��.jgj�`(�D��/�+����T�r� u��LAD�m��QE�;��흣S]%}�UW���)��ғ�)lW��ڬ�?��@9f�����O��qL5щ���}���d�2�>�/9=��~��dߍG�7AW�@���fj\2�if��Jjn #E$u>�=���(:%o5n�6`���h�"'�����p�e��"c��j�"X��Nwu��r�ԓ�Jy�x��[9Z����jH{���w�(�1���Ρ:D򬜩`�HQ���~[izz|�[j�Apus2F�:E�Q,^�;u?�^�"+��v�E�0�t)�NcB6�m�ɿIC�Ks|qrr���y���ǕM�rth��-2���g��I�m�SXk:�	�C�'�=�����-��*����&x�k�=�f����JV��|�cn�#����t�8��H�M{g��*��Ud-�+B��S��A���6|@���~�唞��cA~=�y�4��$D܎scB�%<%*�﫽n��j�U(��. 'z���t��~�|������߯����U���)|O��S[Y�)��ӳ+ՆF���/"�����NH|&��^~Nj��{U$i�!k��Ͷ�w"��35-p�@����1���r̛ǊWV���T�h�~V��l�߲�����C_��y+E�R�ʣ�"�Z�d*�Ӈ?����aވ��kU�Q��N��i�wg����*�������
(��+I��G���[w5��u_��_�K���
�w�]E�$Ę�e#�IʎSG+���^�g��z��I�{����f�@�w�j�DJ����n
��d;9����&/������o��)
@[SVP���RBG,Ɓ�:Eh��ޡOGWd^u:��
YmΟ�}�j~ɕ�s�h��15o��j]�ZOw&���3
ln�!�`�㟃l�0�1�h�
C�<Ѳ��h��?�ƃ�f��ɂ@fJ��z�i����n���Ҟ��30�B?o��M�6E	�+�:C<}F�\S��^P��m�&�7��g�{h4, ��y*W*@��-�qsd��(�3��)�U:��2�nB�hHO��/6�#��r���PH��B�{)U
����h�N{i	m�����6��FQö_��zN[��Wh��<�O�?�V�r\6,ϱ*z�%�^��k��4�:�F�9Y�G�*[2�~�]�%�)g�����Q�k�����L��ŅR�~��JeB6״���e���u���^6h�����۽7o
�U{��馃���6W�m��k[.�32��~q%\W���wK3~�dޜ�T�3��ɩ)i_!9&Q�1'��7 >��|~�%��!��׮�������bR>ˢ֭���1�&�zد�[<�lS��<���%��>0W��z���a�iX��Q�t:.<�f�g,�sIJ#�e�I�}��@<�Z�����5�T�1U���9���Z��u�v����S%����D̉o��@�x���*~C�G����>"��D����d��>�a4���x��Dg{��owZ�m"A?
Z-�Fc������-XБ^��a.[��ǀ4��ͤ^�N>]�����L�����	����\�?/4��
Ns��[�c�;�i���uL|q��Bs7{�m�|^�C'�{�ϛw���r?o)�}�Eq$��y=���]|�����`�B��E�S���U,9�*�<wPESf���yU��U���� BT6�Ͻ�.�O�vFq����
�\���t�F���8SC��Ң�T�79oV�mK.��M��e߬��\�B��rI���O�>�$+��N1̄��n��*`�yiW�t����?�R�1I�D�X��j�f$fs򣟱,�3�s��"7!?>�Pt���r��0�i@�[Kg�[Dd#/%kRq�R�{���OC^��rY����gw�FY
R�:�b�qPǥ��/�"�%	JD���NǼ�@�)�f!���j�^������ϵz��S++�aCJ/�c��X�y���L}��f�}��{�m�I'k�:�W d�7�V��ZyO�*���f�_{�A(�'f!x��Ϫ�h��}��F�Y������p�s��g�F�z����H����ϸ�(FF��@�p_�*/ ��~����T�8�q�$�`F��N� �q;͵�yVU��$�:��-�FQf�49�^{�)L�f*t��)m��q�1{��/��FIzI펢��ǵ��C0�Zם]�X��,ċ%)���ް��Q�䬴����d.�PL_0���D�y�υ"1a54��E�Y���<�	N�#g�N^�be0�43|��#�<��Y�6oEC��������[Z�K��n��G�FmV�nr���Y�G�V���P�,�v��&�¹�����y�$چ�.F5l W����O9�=��P��[c�(�:I��ӄZ<K��0�˙-�<=<8�B>����hD��%w�;��"�8�Ca���3ly�
��6vCXn 	�+�,T���Q~T8*������3Ra/n�ټ[~2�}�M�Lo�(����k�Xt�K��ށ��K"�N��uc5g�%ѥ'�{z�@J����$ԛ��{�JI���A��W�J�K:T��.�t��I{��t+��7wI��Bm�t����F bz��'*@��ys�M���s~L�ݢ�K��������K��)�\�@{����砋�w�W��B|k�ׂ�$��L�L�J꭬j!���UG�9��:N�yN���y����>&9\Щҳ�Lە�~�+�P���_Q3`>TU5+�m �����X(��ڐ��3�m�*�}-��Ի�J�L��tB�7���Mk��ߋda�W�U�%^W5�,1��ߟ܃��C�5@��m�7-$�0��5��?H��#T�ʫ7��
>~�!T#1�nIQ���}�4d��o�Z�v�֯~5n�Z�*X��5C��G�Ή~ٖ�@4�2����įC�K�|��qmR��k=���������<P�R~7���|\_���Q�8p����q�=-�IjE��o�Ō��j�}�O��F�����@?�g��"S�T�6��:���v�&i��w��=�e�]qe7�#D�k���j.-g�So΍0>��MM�n�I�^�h�0���'|{�-���;��S�ڭ�G.mI�"�`iU~Xe<u˚�^;���v��dܹ~�l
��M���(E�'>���̧���V!�ʃ�wSب~B����s .��r;��Pu�/����>1a
�=w���=��U��(�bdDk�nZ}?^o����Tj�e���j��|~���_]x>z��o���fH<��>M;���M{r�i��O������Xs��,�k���5�*|J�{�H��>qG�l@ɭ?�|����i����X������=��ظ����>��w�������wg����lc�#o���ڃ�������o����K������/���~����_>�P�"��&�y%o�j�O�/�$Rp�A ���*�χS��U�ճ,��q:�^b}�g�
$�A5���Z�;��4��4;o?	T�"ʮ0�!��=�q<E��=�+~��:���ڞ<�&X���.���R��3$��9>�&cX�F�e�o�K?�Y�A��V' �ЮQT�H��`4���AЋ��xQj��M�����P�z�6N��"�ۼ��^�<�����N0}��sg*ޏ�����[7�^�W���Ì�0��-���3P������i#�.]q�L����t>����#�1BA�'i�!�e9��q�9MmV�����Q*g���a h֛� 	����`��7����5�-O�tfv��%�LF1J�Xiօu��4p�0h)"A�0���f��8�����$���n��sXB�&�F�;>+<�·8�3�~����m<
	��ļ����4�d1&Ū _�Zk��� S(���A!�&�,�O��q���� a��#�T�q>�7�sa��ȝ����!e�ӥ���e���S�+�q����an=�I���<�~sH��{�Q4n�^	g�r(���N1�΍�^N��D���,�� i�1����g��`����o�+��d�旈u��8���(��,�5��,�Ә��F����R�������x�(�Y����p�."��5��<÷�ޅ���.�A>�퍇�r��9���ۭ�,v��M�Y�)�x�� 0�漢p2���X}�y�����]��n8�ǻe��t ]̤�!�a� 
�\�4ū��	~�5��>���4!JLhw�ЋC聯)�:�7�����'N�)�潸9��"f�n�aρD0~!a�����F�9�9�xa��\��� �9u."�Wu�L������e�{@'3�����=�'�E̞�xf�K�h�ui��g�~L�i�������Ug���X��,���R��@B�|�<���3�㜟���j©�M�|WI����q�	�;���0�ѾӃ]�M��
#��u���5��Pޏl��e.7v���[p����z>�&�0�@|�K�B���t�l�(>��; c�r�)�Q��1R�@�/`����'*(3�2�_*��>@�{�X�p�W"��f��h0��x3��F�@z�π�C/$&q�'H!���x�O�"k�%���)��|�z1�����3=d���̧C �b�bi,|M�z驶(��Vf�(��|v���M�,��<�I������A%��w(n� �<3K$1%��e% 5������X!y��VLn
���*��q��k�tM�q3�C���>��HK��cPp�_#���e�h�"�ߺ�p�M��&%d���6���I�(�4'��cj���}B�4
�O�=��AW�"�98W�I3n�'Ģ�K�f��^U@\m�@[{�'0���+U�%�Kx^��ij���
Q�g�i?����pa���Ʌ�ąŋ8v@�kMP�p踤,	�0C�i�ׅN�G{Ǫ������wNv����Z���G������X<��շ边Gs�pd���2o�]s��7.���H��U@�MCH�`4�q�f� J��5�@ݣ�v��2����$닎�)�灞�R��&���p�9?OP�[�V5��5:��jj0�+����|AW)�o��d �s��ќ9��~8�k�P����	0�G�|��1�0��[��
�a�$��X�� D�K%B�3���4�8��	����j2� �X�U$�o5�H���n+ڌ���R�m�lE˄�v%fL9l<AD����&���)���}B��?W���y���%�@" ,#��
P�G������NPw���eb	�}�Q{Fp�L�Cަ_�c���@Ie�8�����O��e����G3`���Y��8�j�KT@��0��L足�
�Govы��tX�O/X��+s�F�$`�.�"��=�;/R�Yц(a��E��S@�J4P�R`�HfH`�BN�|H���P�
B�x��Nq2]JMA~���e(´�����{m����"����"]��Fg���j����E���ND�c��rx!��Ě� |c��5�h� +7J�fd6W��-�%4��3�)�c�K��z�������"�C,"2I< �hӁ&�9K�U�Ap-a�l�gJ*�#���1�CK�wG��s����$���h�������Y��&���������$�TZ�G���X$�|�B����������}�&��K�X,@��"cV�K�ɾ��ҽ��aL�)��G��n��!/�j��Gx�QT���ћf�;���	rL߁z���.B�op�(RB�9�<|�K�ʖ���z��[I	]���@��$o]��lk��a��,<GcH���z�6�ba,��@���q�DY��h���I��:�B$j5�B��!w԰ᭁ��
Q	Ԙt�����u��R�ބ肜й����^�l���41fq�,!U�"@��9�񳺢b�h�aY�	���v¢$�V��ū��f"��Uq��xr Q���CQ�P��X"�Zl�Za5A�r)�n�2C��e5R̈�S�`�-h��I|��d;:c�O���1��]Bb��8�z�p�u�ȼ@&�>V�~�7X.���Q�i�@�Jk��vp����D`j�!Lm�!��j�2���I��$��M���a�Q(u]���X�x�v�D��41��F6�T���R�i?�VNHq�_��D�r������C��{7�ו6��dNӔ�p�n�EDrOh����L�9G�]���$�}a�x+�ٿ�<�V��Zu��a�� a�4�O�jh�C����*��_��^�]�v/{��9P�6��]%�_m�V�۳3�5�N���e�u�`b�k���7.嘞��t9ƳD+���2*жp">��w�-��&f{���W6�8d�~m��r2�e�-��c-�Xylo���[<����g� �eܮl����@��B�jd�B16���_!@R꯵���6%C��6�=�@X�E�J�����:��=jM�IR��TvAj@���g�(�÷ak�R��D9��w>h��\�V�����ₒ���x��9�%byd������xq}�������Wh7� ��}Z(i���G̟s��gW�NHL���dǍM��ZoZ�T[�%�pm�Y�̔�K��mr���>�NfI�1 ҐOR�F�����	�ыOB�є9/���&ΗeA��r6�!�Qt�!v%"�ʨ}\��'�,����T�s��ve������Y�#�ҭ,f�L8�p J!�.sr�lĜ����N�ph�,�]Sd��v��Y4G���o��m�w��q*�ȴ66�:�1_�್��{��6ˈ�v�9�%�>1���5�'̂�'���71v?{/�z���&�E� ��Ď=���D``�h�T��E8%�x�Gh�!v��FF�e���-�8��-�#�������}���n�ܢ)����u�O��CV
(r�|dݾa�(1i3Fo�����	�!�1�9F!��j07�����vH{T�@[_�,����C8�h��}Pk9xwcMm�6�Ϡ�����5ީ *b5�hT�>Y�m_�^Cn#��U�i%��/C�\��,��H� �?������L��o2!	��: o<T[�^L#$��=Oy�(�Bq��F�AÕP�TX12�8�T��]5��B����(A�JJ$�t�]�d�_w��f�epk��f���n�-��M:�-�޾��Y[lPs9��n!�K/L����i���L�! h��̓����d:�'��S���֌����1;B{�ę-4v=
(5N��!��ɇ�$�����/�hA��Ʌ���E{Tw�Eq!A�X��R�d��3�\{ӎ+cs{D�8���>Qm�V��f��� 9���X#EՓ�wdFv[�CAA"��p|B>�P�=2Gm(��6&����E�=-ۉd��u��ε��U�6��1�s�")z�����b.�jFD�G��
c�����4w�&{��:	�l�Cf߃�r���Hi�|����u$$� ���jT�<�����N�MP\�:�7���|�����F�ʢ��HV�FO�T��F�"�ڜ�S����6FH˰�"��eFv,q����E��m��eEV��^�y�:� �>� �0��&�>X���}�J τtM=h�.��L�(Imȑ��Y�q'(ks���ɤHU�₄�(���`�^jm�	���go-4��	�6\�c',P	.�H�<��މ��`/m�R�_ו-i`|,~��v����)�MP�:^�ވ}�c^ődA�2-a	�����;
�lA�06R|H���ó���
����;�wN�p��D;��=��T_��v����y��wL쌬��C��:,n�ѳ���X��0�����t4��!P�4$��<w�s���sDh���z�v�h����R[�/3�	�E3b��������'g�ܒP�L�~}QzY�A�SB*[����Wdm�����+�tȕ����
���.O�aE��38�9��7�T�dbX�e��8�:�1\L��&Bͫ��+�4�OId+��n��
�t@�nC�9�W9���E@V�}�iQ����{�I��ڮ�T����ci%T�Y��3�2�lB� �%��]�<���5�L�2�����>K{��At����WWQ����iӱ?iar��*�k�G�d�5�R@�@��0D��\\X�H�N�'�r��0��n��=�2#��������9>4���$w��㔣�jW/O	8a�u)ק!�~���
C�mX����E�PGX���#IE���C]}��=:��p���!y!V��	�2\8�PV.�ڨĆ��s��XE�:z0а����"mWvCث��<�\�G�J�ř�>�rќ�&�]g>#�~�̐���t�N��b�>�G�EK�Ak�vN}။FŞz�>3���!N��wf[�Q9I/e�&xWЀ�mj���<�04H���%�m�E%�x���;�=�*H���lbz@���Zs���!v�{��X���
9�H1k]�o��7�nj
g�yHP9���]�sw���^]5�$#Y�0�9�cn�����6n���ф1Y-�q��0,���s�d�6�6�˭��ޚ�'Q�5�i���/�w��������(��������`�g��gS�19&�V�	{k�|#��C&��J��@���1>:D=���#.��K��^��T�\�3����ޔ)t��z��M���;��ƬdP��H�`����j8R�Q3��n�3i��U�xi8���4�a
��5+q^�jϱqys�%��8�zȶ�����a��$�G1���"C#=���-�����t0�ع�:�Ѥ���Ax�R�"I�ζq#�tv�eO��X���P5o����`z5!Y1�(:|TP�aU�Q��N�G�`��~��m(�xtABJ��7�����Y�E�ЈO���y �8��p�M#��Y�텙��r`���I	�\�L�?Ci���K�� <�YB�I�O`<	W$I�cd�d�Y$�z��Z(~��vXA�!JE��� ��9�cXV����������Iĺz]��2�-lMp�N�8^(�H�*[7t<�7A�@AX��9��|�.�V� �a�bTd3�l�����T!�����
4�ĄԔC%U�� ��x]�C�ͳ��|���s�a.�P�Dw�-)�J����h|8��ܨ��dӲ�r�}����81��z(�&J�����ڤ���İ��vx��$�jMg���ȥk���Zi��g���1�������}���T2%�E�������1L���ɵhK�t� N"��:I��ȁX�����)��ޕ{�
8)I�,y{;N�{&��5��w�y���^݄-��w��yK/G�A��e.8�ң�H���{D��rl��~���kc�!s�"�d�!����`s�(2
� ���	D��Gd�FI�	��*L �vg���EE܊Ƚu3���\.�tD�x���T�δ�эa�6�.�ei���$Dc�]`�0���4L9��Yyy83�:�˲pt��9*8 �U��0�Dw�ѵ�DZ�
�g�Q��'f	�E��J	~M�v�Vv�~��HTkΧ����`Y�� �K�tɼ���g%�3*8	�����~�H�=�rkՓ��C�@��I�M�OL�;H�j�1#��fӍAl�d7X�5dy�&�Nl�+�<aTq��r�[�u��Ck����M�$Q���M�Q�q`���bt��sI8}!(��`�3 �����acUUh.#������*졯F��é�(!�#�:�y�rK����<m5�q��/J/e��8�Y��ǥ^`!һU��2�s��tB�bC|�b!���I�qw�>ԥ��[�aG���)#e���7]�G�c�\TF�a>�]��9E���2#;'�(#�.��Eî/$~�}e���Dڤ�@���(M&�B��I�pfm�)9�j�!����sx�2�vB�tSR[�þl
�c~f��	{a�(o���@�ku��fڶX��j�,o=��P�Yَ�v��:^��bt/��I�ǉQn-���m���8�Y�-Z!�:g�.)m/w����	M�%��~G[Τ�J<xm����;b����օ{FG��Eu#�f����U��2���8FQ?ȍ0\�<��m�ʥH��?�w�b:�ǉVgW�0�G&�Y��W~�R��[�Z�Y��c�ț�~Nkm������m�t�� ��^'Wn;�2T	�$���R�����0�L�
Al�h��h� ��ZML�	%��.7��Gd"o��]3W? �O�K��h�s�=k=����$�A�y1o!+�Z�U�B,�>�Q��&�jtf~���$Yp  j6F�S[��hW�s�c�H��qʻ��N�<�3�=�f�zŰ�3�x�3o������bni�tZo�e�P:0Ax&��MfjP�l��J��א�!�IutB�b�0*(9;<A����R@�s��jh�JB��1lSn��'-s��G8����Ql@u��\�# Ӡ�~�"%N���}P>�����
''	�4d�9���a�TTE�)>��䍰�oFL�)��XŅU5��󳬦��ȫ��S��F/)�ppS���
��[!|7zdk�M/��0���*yH�w��8I8L�H��:�� ��FD�V��B١,�a2���2��#��������D?���#ֆ\F�ac�x ��y���4�%���A5�Ƒ+Ð]kr���k�OR�`*'A�E�@�Mi׽$�mb�l���ҒtZI��Z��ki���,'�#[�qd���&�@���O��i��qAq�6�7��j������D|�t&Fq�I�q����t�|C�1��[�;f.�"JS������f Z(��|�[�����,rf쾄^Lݣv0�᤽�������T�72��:*!0\֋^Fi��O-��M� ~�=�g��%t����e>2P�d��U�D�`R���d�;I�fȡܦZJ9䐬�$2�"�..|�K2�8�gZ2,�DD�`�6�f��n/�[�r��R��Ï�8ǜ�0#��f͑�8w_W��l��C�+ɡ1�����C��R�iCH��e��t�ܐ�����ќO��0��^Fc�b@4�B��8��<sr�|���]5����_e�!��#-��YN��И��]$y���N:"�Ȧ=q^f̯���,F�tk�uUC+*O��Sc�����é�\��-��"�W��>���[Pu�Pc��ce�9n�/�o�k 5�1�YGm%��:	sg'є�\�Z�;G��4��\� �v��Zz���������T��OY�l�!''h@��� `]=��Yq��4�ϣ�K��ysu��Ι�3A�{
�
Kʟa��`�!W%�Y�m�<*T�=o�fh|���|d���>O��JC�R�����u��*��,uB�8{�Υ8�y����c�	��f��x���Xjr$�?E���������J�}v����ԥ�%�}�i0W��Q3�H��Ñ�?St�X�ܢp8�|������:�e-uɹ���iVӁ7��RN@�_`�Na:�Z̡��Iil�x�o���&��:DA�	�ѝ�)�grH���������杏`<Qߩ���S��4���aO�8d�,��O�S`�<r:'N7s	��&%<(�L��A�BΑ�XqSZeD Ԟi^��)��
�%}��Rz+����WZ�-�Ґ�LG5[��Vh��E�c�4�1�46�����z�r5�g��;�!,$��)?�U�Q�j���9���~	�� 
����,<K���N����-��U)�$<�,|b�!Kgb�7*��Y�j�"�H$W�<@�H�S�~��l��2HE}i�*����vK��USv.ѐK��T)�}x��(	9��k��ݟ[��'�\ֶF�\3������.L�L��α�sV[Z�F7���VE9�W,�������Ii���678�t�?��\ ���Ne�1nR�E���$)�:�����`�4E`K
'���!��*G��W� 6g���9bud���3��k���B)�EgQ��VaJ�;VS�l����R���F`�c�����U��FdS���_�ȢˌxRLq��]�1h@��TAqB���y�e���/ms�q�`Une��d�cV7�#�tN`3�-���) er��,��(�."�!���n�|r@�Ͱ�$�ʤ"s�Au��䠙�9� \�t7� �i]Z�&�(�Δ�N��*:Db�墼V�1�)-��}��4��Cת����RI�N*������y��ͨ,&,�e�W�!X�#C8y�MiX;ō��jX$�����UM�,౟������!�o��/yQ}a�:�E�l����SO2ҋA��Q�k!-_�*2�*���j�`dL=��	�_` ��3� %�Ԧ;��L?���!'�'�՘�R�P���R�F�W�H��Y)��s�+�f٬�K�Rm�LI���t;��AiI.�	>U'-S?�#i&�V�wV9~.�Ҿ}c^�R��q��:!`���!�I�jhsE��,z�4�\�D��V\`q���"����� �%k�I,���24�s�Z�7�U{a��o����a�K�:f?��A�䲙��:�ꐂ��y`��i�Tc���K`
�6#"c�9i�S/T
[�o���ձy��� !�w�e�~:��[���(�R�L�j����ͨ2�3��N��$��qτ��!�\nW��l$�[�؆��mY�mЄ�g�y*�tjY�g�i�߉�H�Re.�$�K��L1�T��m7a/%��k��	�fT��h*�4��x�'�����*�uA��*Z�#Ȥ`�ǹ����a�A!S�T�:��m�g~�y���%����a��%��L��'��Ռ��0��J��.E5�t��h�b���P$,�Q�Ohn�<!��j,���t2��[���zu�/p�ܘ�drŻA�^

�1)t%"�Zk]�o��F`o�)�e���7Z�Q�8�����ďsv�˃�:���aޯ"��y�i�[��*�2�&l����˞�b!�3t����_*p{����a��.ׇ�&q�l^�Z4V/Rnp�D���Q2�7t�9�<j�21n��g��	{ÕQIx@l����\t�d��M�W`��%TK�&��;�]��

{U�.&AX��yבj��[J��Hj��96�9O�­��3C~�8�	�P��M`�gdv�'�v�բ�|��c�a��ٟ�����9x�Y�;��Ƽ���T3�&�U�E�g� ����x~}7c���;U�6�!��^�;���{h��e#�t�Z�2��]=��-�f6:7p�����$�z8�BA\¬e	�N+"\H2`*n�	Z��2b���!%��-Ψ�Z�ÙĽ�u�α�?P�;GG����ճ�#�B<?��5�����ϓ���:��휜t���������V��nW�v^��I���=<Q�_t����s�U�'찳�^���?'�[���<q�8����Um�:�����N���jg���I�:�0�z�s���剙|p��|������P����ã��1L `������������m�KC=�'jwV�N�&m5t����m��?;Owvw`��Y�g;'�0�]�g��r�s�<:<8�o! �?�9�������ˎ�0���z�Ys Ǆ�U��D����67����Ϻ[';��l	�����~� Р�����[0�����{�jg���{��9�]�:8:B(��F_�8��8<vu�2S�}Ġ�+ď����G��x	kE,Q>� ���.m�������AňѠ.��E��������3<A����W��wW`�-�v���<����|`�Kxn۝���8f �l7��awk��vy���a�x��� Q8c���������������ɮڱ�H�v����IGь�ߧ]l}�݇��;���zy�[`���K��;�|�^��;Gہ�d���:;�/����#�"HB@�$��q��᫝g0��96�]���8��]h��~�C�QƁI�Ȟ����#c�7-~[��0x\JRq�W�#z&#�<D�����G���X��X쀓W����7�R��(F�l �a	��Y@H���X��7J9[��	y�6��<a�<Nf�e��"9s���82�$�r�lb��6ݙ=���3E��/�u����s����y��:uh�8��D���,o�U�@�x��]�.��:�A������s�ܩ�_fy!��!��|�5�0poHu*~�x�Og�8D�m�i�ߓ���/���֍�#i#����P��V|թSF��1�;d���.glz�uc��8ۂ���0{~�%�^�H�k�S��/JL��<J����F�O��45T��,�&))ul_��s3Sە��E�T��;�N�k�9뿛S:��>��h���'y�T%�R��V]}����"��{Ox�y�U�mxǽi��9�j}P\�7T�Q\(%���_H��|��՘�i��Qp�Ѫ�nZ/k6����4oWѽ��tHg����Ң>��5� Zd{d�j�����OK�8�(y�������#��"=\�0XM�U���ⵉl�#����rN-2����c�C��N���v���u��Ziv����'0���aҍ[���0�$�7?=N5��Η�	V�·B�	F���\F9q�P���Ɩ��r����#�rG�WZeca�)�m�b�n�^,\#)��ɸOn|Kxȥ�iO;O�v_�tw�w5�Gt�r�jz�wz���n˂+�g�:��G#����&|�MR��$<r���u'������͍�.T�B=?���-��_�w3����s�JH1�mK3����� +Yh���p��/wl�cyƁ&4#[����xq�����I�2Śb�%���N�0�A�����_��)��[ ��y��W ��be��u㛲�Xaż��������/;;�J����Vm.7���4XzI�r����G���H��Õ�&�]j�E��J8t9� �,E?f$�z]I�����N���L�)��g��l��#��h*fHy3G�k{ߣK�p)��t��[���0�l�u����_���:�q��Ô��!4�G1� J���U�rxՄmn��'��p:�������G���^�5��1��־~�@��|���]������ï�Q��7n|�`cc�Z[��������g���3C�S��ha;h6,���̿�$?w���m|�-
N��>�`HD��[���n�������?�QKy��L���%	U�P?�#I5������ != �=�7��B�Ĵd@ǳ��o�@� j�ق1���9�ß�ֵ�py8��ζ7R�2b�` t���Og�u�zÕ�pL�6�}���\���I�ɜ�ӧ)�`5�l1M3�(�[��3t�SMJ
UB���+��6n�m����㽆:�l5�������EH���l0���81�@��2
��Ӎ�E ���构�K��O3	Ƽw/��aR�|x�lKC������'Y��%�!�!b��"n�u	R`�У'4K�i�'��Ի/���(������B����uE,�S�!7�:-Q�u^5t�����X�����z�����f�s�N{o���\��(Ga>9��Ŕ���ѧ1�>�v�>�fѴ7��]���R�����pJw2�M
�e�6@<:}�l2�`��.Kf�N�i�v��Wx�-�A�ɑ�߲�`�k/uw}�E��y�D���������������i��G?��lm��O��˃��0�X[�����\���`s��͇�*��l�+�l���*~Z��Z�����?;P������U6fb�a�c�����˜��.O����G���� ��n��i���G����鱳+��2]h��w/��ϟ��/��ﭿ�<���d�a���~h�j��1J��Q}�����]i|#�o��-�V�S���֔������	�s�x�b�n�P�~,!����6_.[K�O��\��,d�B���o�eC�ytTA���!�f�e�좇�Z�'졭��* E�H���py�*�c3��[R�/P�|�Ftx#@:��/�8RSgqēQ��a(�q���E��lĊ{�dĳ��v6ɫ�䯖�>�X8(�-zg�bX���[^E���V�}5ҵ�q�?��ԗ��9v��)�nzN|rS���I�Ǎ�sd�A�Δ=�t+�]<S`�����"��7.�lA��ٽ{B���Č�4�l24�{�22��W������Z��Ǧ�|��:~B�8$�8@����0V�oT�w (�T�4%�0��6Hm�X���0X~��0.��` 1.}�'Xx��6�6��_���m>|��������ZkMK$�2��/s;ocv!�O7�"͢|a�����^���&Uʕ6BrY��y\܃� 4�t>����9 ��xM��l�n-�MN�6`�R`�&���a��K�yl�Ӑ��,?�gM<��g(�כi�M0���`��������o 
�֢�P���r}���Zo�o������ ��ΫNa�8��?�N����v��mk�t�덅����vON���~���Ѕ ��!q@�յz��n[�l�͘b�av(�����ȸ7��ս�]Ū^ej�/�M��np��;ތ ,]�Mn�S�#@/,� �7��9�(K�~k�y��h�����C@�N���:/wON]H�O�쾣B��Q��#yt����6��~���$z��R���6���� ��\� ��Xk��c\	�}���}O{ �Ѻ����t��p:��������lXp�S��������fd���i��OZ(6���n����,�p�y�0������^kr5,�<�C���(?�O�qKj���6�'�o �����+~�okX�8l3�O��D?X��G�p~�
S��F�S��g@zi�@�Ie[4^��h�߱@������ H(Y-L��9��<d/&�T�O6y��z�M�Ei
�բ6�}g�=>��Q[è��n	�F�`��=�?���{��RD��~|Dik�RԢ9�F(�\�[���J�VU�&I�L����=::8Dft�tМ*{� �+�ƃo���s"���G�k-�,���^)�l�`��Kߜ�wp���p �}��5�u1�5k��O3�I�]��H_4��B�Rƃ��R�^Sh���Y��� �R/f�ǉN�Χ�D�~�V���4���@[���,��k��`[9NDs�bp32bD�����3�U!Ls��=�@��$P�,�)k/�2t[������g��$�TM���\_rK�ugԹs_htLF�ם�7�����镱k��.-4v�7ܦ�c=�@Ŗ+1���,�G�RTl\��o^��r{n�T����i7E�U��p.�S�3ֶ0�����,�6��40x+��s�
����a=C6�8��k4��m:��[���X��Y��5!b���t�Y�8[�;�t��5���Xޥ�����N�5�m�{�`�zF͉���R�K���t<� ��@����j;b҂m�h�,�����`CK�]�:Ѹ�EI�i�3��+v/���
s���ފm�[믩�gne�$jWa��ii�r��м흩Th��Ҝ�<��nw�ㆸd����]e�}e�;!�G&��Dʊ]�2 ���z"�ٔ���u�E���;�?��'�1T� ����~�	�R�bY��o��Ԗ�+-گ#$r5����kg'm�X�S�;�X�\��h�q;k���a\A�,�!}u[`aĝ�'�3ie]����xx��%����0M��n+pc����;�����~�8˦-z��l�lb�n��V�]yj-kg�V?	5��A���ny��WL�gf
ێ���� 2㲼j������hEai,=����$hj�R{�Q���c��M0m����3Pe%��(zG�H��S'�^�1���+�J3����?�邨�j�6�a5��dzjA�k�ah׉�P+�~zfV���]n���� S!�b��<t�O��$����S�v��X�D��\14�����ݍh��\E�vf��x�����&�Z� ��b�iɕw�e�2����?��F���N���eb=h�H,r�N��W=�	hY��o�>j����ƍ����,0��/Kg���W�����h-�o4ݶ����X"0�P�D����r��;#�|�ڱj�`'`�Ǻ��:
�=E̢sFG��[v�B�Y���ؠm��t�A�M�=�y�A��E�v��<(~��7���C���>
��ҡ�KQU���Au���ҭ�J�r�����f1�&�8���s"7����eAhP!�0� �?xP'������e�������:t�h��)T��+�]�5~���/�=UBe�D@ˍ�h���Q*b��3��Q<��c����%��6�J\X�j%V���'��f�}���ٯ�ㅷ�������Y�����h��LUSO�-�
j�e0��
h{��DgG���3j�<v�� �c*�WU�m�'A�Yۇ��J�d�<�h��@�Q|7��Ȥ���
����"LߓW����5�2+�� ݠZ/�܎��a2��1��쇶���*�y�tw�����r��N÷�̓;�t�2���ۧ�vv�d�C�(�QU��4Е�Zθn�'>�췦��X�6���G'��y|o$2}9��M� ��ŀ�Mm9����y-qˁ�!o	Pc�[LN�j礭�.��4�{�a�o��)���7�Y��ؚ��H8������n��ْ@���i#���d��=
��}�R`�8�~>G�T�o�}f��S4^5<E�f/�ͪ����x�A0������o��,9��"52b���B�lt+)�Q�c�~��BeP\�I���H�yF^��N��Ӕ�?q�[��
I�?�ZW9$��t�����a��`�|�P)��@W��)�K@��4c��@�,�"��P���`J�#V������n�ECg�oL�����3�y�ď%i�^�x��xn?��#~�`�r.����%�c� B��ӹ�t%"O8Dw.��d�Vܖ)9Y�:�A�na�+�o�����f	�"7��Q��/K�����׮L����N����nw��ɋ'�|���=7H��X8$9g2l>b��Fύ�=@�qT����Z���}���l2��T Sh�"C���C���|:�o'ȀRpS��d��Z\�������-�[�@MQ���,hޞ�)[O�k����_��P��<�սݨ7Z�h���-3 ���w>1�Qy��"��mJ���gKz��O��X��k�RɎ_���s{���=�po����=2�����)�SՅ�󪀉��=��[)���+�����/��a���<�:>���m��<�K�9��u��I������	�3N;�1�J���2�����{Y�Y��\�$�69DE�n��l3�ma}��4
\�Eo�<�J��6��`�� bp��H!nB���^K_iA^�����I��$X|.:�M���dA��}L�m��?�64I\��� �|� �!,�wZ����p��l����F����-�� �C�J$v#g��	���t�*�N�c��u�����9�݉CA���Q��ҿ\X�nf�b�V���9�;;��nq|��11n����6�d��������u��$ip����;�Ȟ��AR�KR����4>v_�G�.YBF�4���O�����ۈ̺d�JH!��ʙ���[dfDd\��l�9h��ZA�U�R��������� ��g��cC�/�
�S=��E�{����M\�"-.=������[<*]�u�����m���uЖx����`���Y�c�}I*��#��ڸ���$i����M���������u�J��S~�\⃀B��s�*�	!�S^=����/�i�J!^2�Q�s�O8q��	�;�������f��Y�Ƃ���Ҍ�/�������+5Ks,�v[�㘞�MS�ܖ$7u�м�g+��Y�����-Y�Z�f�-�P`�Ou�2l͵5[�<Yk��S[3�6ǳT�p��D��n�4I��-���e[o*��S�4õtEn9�k��V˖]ű�&`4�z�f�V,�6�ڑ}��+j�r��m�T�v��K�-9NK�UǕ��#{-IÚ�F�lK��x�#)Mϴ���Z��z�A���eZ��jf�̖k���lRWR�UT��E�-�2SrT˒�|�e\�)5�TlhZ���[��2�fKu=�80ɳ�T �VtRK��f�+Cm�-k���:��%�+�2��'T�[�5Y���CguY5��)�0Z0}�VK�*���� َٓ!���Q�f��2e˶%]qtE��`���Ulw��1�ˮ��z�#y��8�
�"aӒ4�0m�iRK�\�1�YP�%5Ԧ꺺#9MGr��kj��e��Ȇ)Q[Vi��D\�i˥���4�VK�`�u[��כ�l���,i��@l��qœ�7�X8 ����S�vl��@�-��z��;��ɶJ]�ʅ�fM �-G�T�q�-��<0жMXHI��&�$��'�n*p��p��mf�ppR��$�i���Q����Y�SX\�zg�	@U�a��� ��2�f8gY\Td�%�kJ˖dCq%� hK�tɱ���T�Mh��Y$.*��:���n�2lז*�!�~�[*5\C��\fR+ɽȪ6]���w�e����M=�=<6�$�2,�bx�.���b�Zr��a"������Hg�nk�ᘆK[�'��k5�=���Ď���z�:�e�-�{�a{0h�Y򌖧���k-Ǆ��+����9��ô9-*�Y�j���np�t�	SLUU���P��M<�5E5�A
�3aa<W�m���
Kg����R{\��C�Ȟ�y(�ڲTJq�j�����z-� R�%Y�۔L�u���TSE���$�	����U��p�pY-�r5������p=|NQ���Z��x�]�O�Zp�%�`,�RU�e,�` S����Z&��Jp�"�ͩ;����	'`r�,�M˩kH�����+i�kJ0�	x︶���6M�-�R8r��U��[i�������H[5Ֆ㨺��`㛀ŀ���'�G��燣�
g6��J*���j�x���l:��-�Ov�u��G��"+F�ћ�?���  U��~�m��hIǵ(��E��W�]nsςyG2vq"����{�ݭ�0i0�hg��t�k�@���)�
+M]َ�N �`~L8�=�}��DuWsMS���զk�I�����W�W�N&��t}���%��d����H���;��O�����nc�����Y7L`�$�%�����/�9>g�諑�qq�s�b�m�+��)���zq����=���t�g���w���Nע}�U�+(QZ�<���� �'�~�t������w�<�g�2���D}�@ˎ�!����>^��ȫs	�?�hP*�w�A��~�o�6�����+���x�� ~�EX�Z���E����t��%9$f�Y܊zr8`�ظE�H�Y�[]���5_�l�����cY����b�t%y�}x{�_S���W���0Ӏ��
:*��-�{q0���0��9AC��;h�W�`坭Ş�r.g��k��L����|��6��3�nu;�gfg�0h���(6^c��G�	���n�b4z�Lu�=y�#�D�� �0�u��I�#]d���AE�v]��^h��sa�X�-������{ۧݓ�w{?o��y��88\�J53'����ȧ{+��	3V �����;s��P��:��:� ��F�PV'�{n�i�� ��u0)t-�^YؿYca��݇ 52�X3r�'��`�q��I|����_�2x�6=<��a:��kS��F�v,�f�w :JDx�JExHy:9��[��'�����ΈH��]�,\�M�Jٳ%��^_�i���M��SzJ̉�����Y�d)��5���iJI��#=��`���qO�Ⱥ�z���~1uGf8�-�ˤXnO��g9��B�p"�`���ݵġ?#�d"V�]vw��E�V�wo7��(�>�I~�u�y���V�q�z@��rg���������Z/&;��J6⒎{ց�)I�%�bu���M�P��>���a���,����7�9p��[��JU({VXV(0��NӒ��v9�#+�)rG ��#���� �c24�f��w0�[v
Kl�YvB�J�]n���w�,o�X|�x���C)��̂m��T{ :�dD-*���,y#�����G�J�2ٴ���}�Vn������Mg����K n���\�Nd�8c��Lg��U�M3J&���~� �G�����Aދ+�82jCP�Zq��D�+�f���%����?$8����9$�fG��.�l����o}4�]�j��P�/�j�h�7[{��;/�$��b�귻;�귄y���쑏/�_Hm���bkU����'�Q(��ٚ�a���w�o>_z��́;����y�؍��މ/��z�)��Mj��Ձ�<�����x� �c)K�-�ߐ�	`귑���izV4�Y�:�@r|\v�|�T#��oD���y���3](d�-�[M���%�3=�:(��zA��Q&�?�[^(4�(xii��U��ȍ[�*��}��fJ�?[
r�R�%������̌�t"���b�H¶3�����k�pG��p?a\���:�N�2�3��T��M?�w��� {Q`l\��[�t/ed��"���:����e����É{$�Mr�&S��ir�uɷ1�Į�$�#�Ԉ/��b�8kX�lMT�:��Cұ����l죋�������6��֐��hۤPq);��bVr�%cNx��$�
xVQ�aTg�f��Ƽ#�Hq?����z4�����8����5��0�ե�wc�M���ݪ3�h�:��� ��B	�#��@�w62�̏�eY�Ӌ��|�>\X��[3�i{̒�6D����y��y7����l\2�`��
�c��+��������*��WE�]U�R���T�W��Q��C��E��[��yQ��*�����/%^|<�!Ϲ�	\_�b�q?�����N(�y웭Lˤ�2���Xh���9�o�D���{���]�Bp��Fdm7u���~P�,�
z3�LU��&�Z���d]q������!���q��E��$�{��Nww7�`Sy~ד�T�$�w[V���l�F[��n��O���b�+W�Ƃ�������͐�r��#�������7d~����bF�� xlnmż�z8�ʊ������{�f5@�����٫�S��+�?I.�?בR{�kc��WE3%��I��r�בr^z�����T�r�ב�^q���X�,����7F����_S��=i�����@�#K��[]�K��Z��Q4r$�'�$��%^9a��_����p��8��o�����if� �Ӏ��;L]]|�E�8���O���R9�:����m�`���"v����b;(��Ϩs�Z5���ؐ�~W�*�j5�=!�Ƞ�Jª�����/tPV�k.���xl���TX&��Wl9���k�j.��^E8�?��_�WV�sɾ˔���}�mcy�O�UM��8���_G��� m|�g���Z�r�6����O��D�Ӕ4�H������Z�J��ϒW�g��?��w�g_��� ��<��g�{�{������ϖ||��1�����	�r8�#�F�
���ͳ�{೻��=���� K&>�=[������ FOQ`�����`­ͤWs�W�#kܤ�{���NQP�L���A4w�ծ�Uf�I�P{1�0�+Ĺi���'[��R��L^r�d�dC��e07W.�7)�R��;{����ܴ�{;3�x���Y3U�s��Z@�?��x�Ź�(����ժ������_/��0*�]�k�,�*�E\��2�6t��3��.��6��Gf}��FL�L,��9.�N`2i) �vG!�Q^$�K�^w�Qw�NB�� RG��9��t�*�./j�E�=�o}���`~��_O����q4���p�-��7�g�����v��6���!%�M
�_���)���z��9��i� ?O��7Á�A7a`h�5!��qt 
������'L��9#.�E,Eq bM=XөGG�gy���t �s��GέшAc-XS�}a�����5I����J�d��}�	���7>i0�s^��9��mO� [�!���x0 ;����:��f�2��o�Q�M��(�c5p� t8�l@V1�ǔ��@&Wt~���0�l��\��`������sj��8X }	�w2��<Wk����FwF�x�7��1n읃 s��g������6�'�#:	�Q�۸(3�ǹ7�9^��5wT�-�+�O��(��j㶦��&��v���e�������w/��9��i`��D�?��޺?�����qv~u����������g{�Ϗ����^Z��d��������H׌�������ϻ���?�8����A�h0��[ʜ?�r3ˊ��, �֐�i$�1(r`�'��<��g�?��߃�MT�7����f���tt���j���Mm�����*=����{�x��k�i���s�0Q�������Sc��=6~���^C>|�n���?|��{z5��3���~�����yd~��vv�N.�����_[��{\}�������7���6��[�?�����p���r,�cc��s���փ#[nΞ_x\��i`�(B�g�;j���%��րTso-p5�}Q\}�Q#��w{�	EBg�ktIU��ᜮ��֢���e�O}-�9s>����P$�Gq�O�k#?x��ϟ2�z�|!�P�j0��tnq��'��NT��g���fpr���t�U��u&*�MC׿*F��Kq�hkx`^X�.A���p�ڒ������*������G+�?�I��'j�= �V
�r��
�
���a�{�k�&���#P치S��}��{���LGnB��г���0B��}�4��D��K���SXn�CJy ��r��Э)^v�4�|�~ ����^�����0[���Ll��a�T8�'z�>e�S4@�����t��³��9�/��u�a��&�j��n�41`H��1�U��	�%�@�LP��tf� ч��
7I��8�ƈκ�bE���_��R�L�Sm��0
U�)����jη;���	q�J]��u@y���<���-��_]=����Pؽ$TH�����_��=�3�\7�.��`$��t+���A�#����~��䲏w�:�$%`}o(�^���-��{������n~��1�U�2ō�L�Ʃ����_���ܛw2ż���R'�w2��K�=qi����	���)�ߚ����R�erՀN�m�h���ܖ"f���?���=9<޽#�}:f@��1��>z����N5���V�dL��A�6�*2r�i���L��s�l��sժȞv�'K턻����ߣ�E���a����������[G*Y���|sv��f�"N����ǟW���>� M,�����2a?��jDP�u��!�9*�F�y�)_�L�0e!�Z���a�� 	�9 ��8kDC����2hzȶS-�w \�bi6-%_��+��#*@#J2�*�"E5|}�𱚢�s���K�h�X�YW�ѱ�B#nËԳcľ��v��� �cjh�P�:Əl�87-���X.��Zڼ��F�2w��eOU��=ׁq�����2���M�8�Ŭ�LP�B��Hw�� ���9�"Z�~�0���n���{�s�3zٗtb�u��I���6Ap�B}~���iI��^��EUS�_IE�_Y1����������O_��Ad7�}B�?��K�E��κ�s�R�I��R���D��m���Ja�i��W{|C�P�١�K ���_������,k����T�����w�S�� ����"Cˍ4@��4l�������5��a�\�1!����c��ܵ���� 91Q'[#�~�(�h���������j�4,Et��o)�[���0�!x��i�xԔ��-+�Z쌀���1pk������A
&%�~>,!�"��g8u��	t��j➧������4���C�`��2�"qWO�{ Dc���(���Ҳ��}���Y�o������Z����jO�ݳ\���s��"��L���
��T���֒ʠOk
�t˾�뷐�[��[����q�o\�˹=��s���v�9��ߥ9.���<�k�k��b<���Z�ӊ��P9��É�is�����ܕYR�`Ie��<�k�r3���2jګ[t�VY����ܤ��K1q���]4��5o�_�|�B��R���'~`���
�cp�y��'~ؗ����O�r�M@����@+���[A+���	=ƅB7q�tB��$�Qn���:��t�#�w���V_p�v�#�}����� �:�z��� ��7��pG����zT��ѡ��gp"�V/.�C�p0��q�3rg&6����.�X�����ab������s�[��U�x��R ���������6S��W���{��|�{t��ǿ��I�l�:�s\%~�����/�W���������4��R���RF��������;_�XV�*�8x�b�����~K\��a
:/^uI.�lL'��.�oP��\�T�j?[��֪B��]R�"��QX�ڈȯR`��_����J��4����TI�C�����M6�糠1�"�f����C�sNT�mq�t栣���"����V���8O�0��-�]�}��߄����������������{�*��_�̲�����3��	�b>��m��ci��ֿ�o�
�#O���_Ȝj[Y�X-��vZҕd��rְ��x�1GgiSs\����]^p��?�R�@���1�ӓ3����7=��ҊM{`�1��C���8�vL�L�R��ӌ�'b� �����U��@������d�H�)i���ZҪ����fo�M� �'�ۗ{�q�n���y�L�W������(��uY�KZN�2G�䆓���#;��5���+}D�p�7�BDfQ�p;ܪ�l�{�^f���Q�z��/7v�m�����&�=^��*0���v H ��T��Z��+�%B/^UO�c�!F��<Ԉ�����$W_ŕ�`׿�2PAB}%��(�y�I�xEmX�SM:����,OV�T*�	vh�#>��5��_�_7r��m��Q<�3�q���9J�0-��n�4҄�F�t4�i��t~
�������8cPP5:>�wチ簳���������d��y��7x��)�^-���j!������*�L�+��E��Y�����g8Y`�N���=�Y�O�POMY���*���kL����?��R��$]W��R����*�e�?����{��dGuԿR��A�?�ߓ�g�إ�g����L�����G�H�>��g]6���
����%���T������?�7@�*�p�\��q�'���K����M�������e�
��ˤ䫈��f�1|�܋�!&<_F&����0wb��~��_qʂ���0]�������0��ۚ��N�ydF��8��W�5 #8pc\�hy�-Ϻ�������fn�K�L�����P�m,������d2��0K�o���{t�?�]O����x����L����5Mq��K��]���S%���D��4s7�dp��8笣W�O�̚O4��Ab-�d$F~�+�9C8��j��pM�DU�,��'�3,��xj�����5�9�d�]>. 	�a��G�CZ��4��o��885��Y�Ҷ���Ҝq��}�	�� �0�QP��Ӂh:�дhm�nqq����S֘}n��Zyj���T�0��ˬl�3:��$S�vn���ᆀw0o#�������p&~�W>j�z�N�V��p�k�p�N�G��%�ְ�A����>�
��U��ԛ�T�eU׍�\��MI�Xe�//�����r����Q����@�d�q�Np������{���-�6��K�\o w�@��M8b`����9�7�� �U�Q{T��#�P2�+A��b,*-r��i��O�� �QS�OIc�?S*��u�����z�`6�뭜���*�����������w�`H�����\�Ok����[4Yċp?�AD{�;�Q���5s|F���--{��
ᄰ�!yO'0i7��.m�q�/cx�kbE]�Cc�ѥ5�5+�5�{=
����dƼí�I�����7����eڍ��}~�A���d�7��5�pڸ	���Nrx�N:��+N��"r��OrK�3}Ksy��9��wo��I�KI�jO,'6�jc��a����7�x��|[�����jk������V7����(���Ni~��0�ǧ#�,��g�uZ~}
��!��!g2o[�C&���>�ó�k���1�����K�Oа=�Ʉ����t x���^cQ�h��E��t�ߪəN��=��a͍�B[
�>{pB � �f:
��,b�j��a��P,{{(V��M�4�F��M�y<�6�`X��6rur-�&��S�瀑�N��Hg�w���h>J��9�����wJ��*�zxd��%��C>{��$��|���B�7r7�3|���]�5׆��sD9�jtH���X"��y�^SP��BW�`���y�����}�6\�p�&0�_'��5X����H�����	�y�`a��dGG��(���o�}ڜj��������o,�;� �F)Iz�)�� �<�Cd�sS��6�Q���
p�:�1T���^KZ)����+*���z����� ��;*�#�3r>)��ae=fN>z�������=K�4�3R~ߩ��QsV�����;�������)|d�ȱB�\ �D^l)=^��� �~�ӕ�qǌ>Z���:���Y�RF_9CPE���y�;ﺻ��mN�������k��}��Ѻ{��$t��p`/�Qõ@?�s� |\r-n�>���?���'Hs�����S0�{D������j����T�%�W�������÷=�b���a���ʙ�3n����d�]�.��W�.^�t�.��>��T������V����X����֓�������v�������I���C`լ?K��45���k��"����\���H+>�*��� ����~��{�k�[?�o��ɷɛ9����+~���u�<%�>�����D�7	���1���5Rb���x����.s0 �Qo�p{k�9�����B��t��.p��ӟX�'u�|�"�p �w�+0I�5�9��	Ӛ�o��MeS��6�Mc�I�;�>�}�{p���s���5Η����f�,E$0�Ңiy�y)��0���0�G�z�����E��.+�����?�F��-ie[0O���@a_���qҬMf��Vm3K�+$9
m6ȓԪKf��)/�.婬����.�΂�Lb8��~\8�0�����Q��ad(�[��4� �C��φ�;VԨK�x'��L3�f��F�O�%��:�r?�dڨ��?��~���Bq(,T�M=�@2����q�˃%�3߃��g<��1&���nDÌ���k ru���.O�rS�r8z�ZN8.ߊU_�LλP�J.����
<`����w���\���l�<O~��P�������^D�U>X�0�hx�O��ܹAe��$�I*�DG�����1�8$h�(�qE�-�`��T��� ����g�0|���`(�����	������,w�Hb����a�:U�*��ȵ&��4O�  ���������d�O�a�ё�+�)�;�a8`���<�M�u)K�q�o�<���7!-��4]I�k��3�2��z���s�Q���)]����3���JQ ٬E��T�ӝ��d_"��k'f��g�g:I��at=z��k~����
:[K�c>�bp����װ�ȵ?R�0�q���!RQ��aa���0|�v�A����%#?��(�[�k�n0����� \���!����
���28#�_��&u@���x�#.�y�'g4�t�P"��o�|�ZX[��`�ZF�I�Z}�\�����O�'���~�:�;< N��:�` �Jd�<<����e�1/�#�b;��LY��xK8K��$5��8R��0OwD�Y�0�[
J��l�l� C@)߆���6��fVw H�%N�Y��%����/�L##c�����Q<nj$�]�W�y����E ��ظ��^Y*�~��C��@3���k������O���v,+?��K����:���ؚ�f�Pfw��d����-�ތ.���B��Ȏ��~X�|
�6;�p\ٳ% �x���4�G�&��)	���t��'�x�m,��%9���5 �e��������_v����Z9��Naʟw�s���.��T~y�{�{���k���}z�w�S�����n���V��O�������gW�?Z��KE��
Y���0��W5���(��:�C���*PA�� O[ ����e7�m�iV�^3�HT���s�ǘ�ӝD0J"~���ߎ\�a�!��OCr�~�y�]�B��t���]`��/�>Yׯ��z��~���N��;��u�����??��?^5�/��b������u�k�R}I�X�\�'-`G����Q6SK��LK;�T���H�	qK({VXV(0��Ӓ��v9�#+���|Q��ր�1�����I6�Ľ��ݲS�Xb���Ͳ�W��rC�;{���&��/�� h�PJ��#s: /8 ��6cj�cz����>�C{0�ѠҹL6��_�Ms�)�i�a������~��% ��h�.R��]v�[�:Ų�
�P�Nfo�{�B��W�@��t�u"��H��EB��j��G��+�	���8���H
�Ņ���~��U�D�
_�Ѓ�دL)�N�� 7S
w�l)ȅRI��YѠr��J��Pڹ�4ߐiy8V2S�V$�l�s�=_tPX4SH���8Jf�?�l�i�c[2���x.���P|�/�cxF��8�j���}��;�d;����͝�w6��K���fq��?�X��O
����`N���gA�Qq83^|�	�ImmD))�bKr�$Z������t�vd�|Τ��ݪS|��O��n �xz)��n0�g�:Д1�ˁ�ٸd��в���?�c��)����yg��F��\�ة4I��F�'s�ۅ�}<�<�ӳ)S��bO����v}%N/.��u�-7�}*���q�I��(�Θ�_�1<�/����1�r1t=����8�m8��1��?Y/�*��ǴH��3�_Y)�?�H�:���Ѓ5��^9>D*HW��\�+z(x�ޗ龩X��q+/�����/�j������_֒J����Ž���.��E�ȼ���R����ċ�'>#�9	)�	��(Y +���1��?����G�c�leZ&���e���E����9�O3����Z�sv�����\C�Ȥ��z�������9��3U!���jQ.sE���Q� D���-X�h���7�������%�]d��]O:RA���;�tҖ�f�-��� ��-��>%�����_����:�?魋�SLYK�?���R��w-���y���.{����bF�� zlnmż�z8�ʊ��������Y_s����iT╹�Y$�5������LC)��������g���+�.`���]��YG6y0�-ZY��df\�l&���w�᝾����})Ʈ��~Y��{xY
�W:��������"0�h�a��f��h�`��KLQ;U�������=��ͺԓ�Q�z��J�cY<�Ss���t �=�̭��U��c�ܥ*M(�q��9�yd�2B�@hF �=�똱�6�d3��bHh�eJf�s-�|��w;/���'+�ى�4�?��6gވ�I^g��y��輪�V\X$����}��M�ß�+��&Ifŷ?�j9C�pqҷF�o����8Dg�a7p�Yہ��l�\K�p���q�I���p�υ�?�	�c~e*S��T�2��Le*S��T�2��Le*S��T�2��Le*S��T�2��Le*S��T�2=����a�� � 