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
� ���Z ��zǕ(��駨@tDhp!)�v(K��$&�II�c9Lhmݘn�#s��������(�Q���u�[w�$�v2�d,�Zu[��k�Y������־y�Pѿ_�k�_�Q��7�?����o�����o�~�~���,��L%O����`��{Y�������?��Oay�Y�ʇ�a�����7��o|�������ܿ��wj�3̥��?������(p����j��@[��o��[{��a?�U�yC=��q�ڎ.�Q:G�T�Q�&�4��է��u�sF�Q��4�<Rj�o�n��p:=�f��u|O�e�0������q��M�]8��3��L�<�F�0Q�0�j5����VJ���T6��K�лۏ����n�O��ar��^��o�S;�� ��&G�E��iRj���f��l��Cz
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
�=w���=��U��(�bdDk�nZ}?^o����Tj�e���j��|~���_]x>z��o���fH<��>M;���M{r�i��O������Xs��,�k���5�*|J�{�H��>qG�l@ɭ?�|����i����X������=X����Z[_��ߩ��{b��?��/<�ݝ���q���A��=�s��k��/����o�����������/���~����_>�P�"��&�y%o�j�O�/�$Rp�A ���*�χS��U�ճ,��q:�^b}�g�
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

{U�.&AX��yבj��[J��Hj��96�9O�­��3C~�8�	�P��M`�gdv�'�v�բ�|��c�a��ٟ�����9x�Y�;��Ƽ���T3�&�U�E�g� ����x~}7c���;U�6�!��^�;���{h��e#�t�Z�2��]=��-�f6:7p�����$�z8�BA\¬e	�N+"\H2`*n�	Z��2b���!%��-Ψ�Z�ÙĽ�u�α�?P�;GG����ճ�#�B<?��5�����ϓ���:��휜t���������V��nW�v^��I���=<Q�_t����s�U�'찳�^���?'�[���<q�8����Um�:�����N���jg���I�:�0�z�s���剙|p��|������P����ã��1L `������������m�KC=�'jwV�N�&m5t����m��?;Owvw`��Y�g;'�0�]�g��r�s�<:<8�o! �?�9�������ˎ�0���z�Ys Ǆ�U��D����67����Ϻ[';��l	�����~� Р�����[0�����{�jg���{��9�]�:8:B(��F_�8��8<vu�2S�}Ġ�+ď����G��x	kE,Q>� ���.m�������AňѠ.��E��������3<A����W��wW`�-�v���<����|`�Kxn۝���8f �l7��awk��vy���a�x��� Q8c���������������ɮڱ�H�v����IGь�ߧ]l}�݇��;���zy�[`���K��;�|�^��;Gہ�d���:;�/����#�"HB@�$��q��᫝g0��96�]���8��]h��~�C�QƁI�Ȟ����#c�7-~[��0x\JRq�W�#z&#�<D�����G���X��X쀓W����7�R��(F�l �a	��Y@H���X��7J9[��	y�6��<a�<Nf�e��"9s���82�$�r�lb��6ݙ=���3E��/�u����s����y��:uh�8��D���,o�U�@�x��]�.��:�A������s�ܩ�_fy!��!��|�5�0poHu*~�x�Og�8D�m�i�ߓ���/���֍�#i#����P��V|թSF��1�;d���.glz�uc��8ۂ���0{~�%�^�H�k�S��/JL��<J����F�O��45T��,�&))ul_��s3Sە��E�T��;�N�k�9뿛S:��>��h���'y�T%�R��V]}����"��{Ox�y�U�mxǽi��9�j}P\�7T�Q\(%���_H��|��՘�i��Qp�Ѫ�nZ/k6����4oWѽ��tHg����Ң>��5� Zd{d�j�����OK�8�(y�������#��"=\�0XM�U���ⵉl�#����rN-2����c�C��N���v���u��Ziv����'0���aҍ[���0�$�7?=N5��Η�	V�·B�	F���\F9q�P���Ɩ��r����#�rG�WZeca�)�m�b�n�^,\#)��ɸOn|Kxȥ�iO;O�v_�tw�w5�Gt�r�jz�wz���n˂+�g�:��G#����&|�MR��$<r���u'������͍�.T�B=?���-��_�w3����s�JH1�mK3����� +Yh���p��/wl�cyƁ&4#[����xq�����I�2Śb�%���N�0�A�����_��)��[ ��y��W ��be��u㛲�Xaż��������/;;�J����Vm.7���4XzI�r����G���H��Õ�&�]j�E��J8t9� �,E?f$�z]I�����N���L�)��g��l��#��h*fHy3G�k{ߣK�p)��t��[���0�l�u����_���:�q��Ô��!4�G1� J���U�rxՄmn��'��p:�������G���^�5��1��־~�@��|���]������ï�Q��7n|�`��kjm�����Sk�i>��Y
L%O����`��{^�2�����Q/���(8�Ǟ�(�!�Vnu�j�	�w������D-�QN2���$T��@��$�$J.b�O��� ����;�Ӓ�6B����Qgd�`�Z��"p�:dX�~��� ;��lH	�8�	���=
N<�i�)�W�^,�1)ڸbP��#s���'�'s�N��������4�P���n}G����N94))T	��¯0{۸����g�[��ꨳՠF�gXV��!uΧ������Ĕ�R�(0�N7r|�F�{j.�7?�$�޽tևI���{�-��w2��gR�J�d�j��l���L���%H�]`pC���,���8~�S�x^J��+>.R9����OA��<�D�y����KTbiȧ�'�w�������_��q;�e8
s����,�Scl��F�� ���U�x�E�ސ�w��K��2h:�)ݹ
�t6)��� ���R��h����,��:����q*_ᱶ�&GV~�"�������	l���������Rڿp���V?����~��ڳ��6?)�.���`cm����zs�����͍o7~��7pt����a����i�Zk]
õ����@mR "��rV٘��u������/s~N�<��Ë�g�����ӧ����Bx
zĦ��>�x�t��96߽8�s>
��܆�����P>^8ВY4��:��5�U���(5�G�e�.惓w��0����ZaO]h��j[S���CGD'�Ω�E�U�C-���L��7>�|�l-�>��Bp-����~4ѻ��������!�P5�����Y����r�h������� -�#e��y�����4:oqHu�@��e�� �xg���HM��OFI�?���M��j��ڲ+�������$���Z>h̃��c�D��͊a͗KoyuZ�Za��H����(�S_:���鏧���9��M՞�'%7JϑI�W8SB��ҭ w�L���c�ǿ���߸����g��	a��3�Ҝ�������л_��r�{jU�c�*�ᇛ��	͛���D;� �7غ�XE7�Q)߁��RU�D��o�D�� }��c/x&Z�`��R¸@.R��ĸ�Q�`�a�\�h�}����������G�[k�5-���� ���م�b<݀�p4��=^�:,�z�.��T)W�\�e���qq�����0���Xo�5]Է{�u�up�d�69qۀ�K�͛Ȳ�����.��	gLC��B��ԟ5������^o��7��ã��['s�_W�(�[��R@������Fk�u��v���^;�o�_:�:��2�<k�:a�����ַ�����7B:�:�9<9}��e̛OC����V���m���,4c�9�١�?�X#���vW�Zv�z���G��6U���=��x3�t�7�}Oi�  q��H,ܤ#`�4<�,E���c���:�UǓ����:��>��=9u!>]���
yRF
��ѩF����z�m������J�O�Oؘ�N��Kr��(oc�u��q%��m��=�G�r>,�}���y���_��v ��`y�O��:���o������w?i��x
����Jϳ�U��=��O��S d�{���H���l�qƗ��>��-�][�^�,��@�
�C�����`i��$>�Z-�`!&E,����c*L}�y�;N�g���Y��/$�l�px�
��~��*���ǂ �d�0Տ���𐽘 �S��>��ɛ��7%�!(:T��|��U���XBpGm��[�%����s����j+�u��H������JQ�� ��r�n�n+�ZU-��h$A2Qo��Z����X����As��9�������Cx�Ή���=�������{M��݃��.}s���A<jZ�d��C�||<���׬��?�0'�wm��#}��w�J�zK�{M��jg�s�J���':P�;�F)�[��v�t�_ʿm�ҿ��z����m�P8�-���Ȉ��g�vϘW�0��*�\ŧ^�@���H0�i����m��森·^�U*�l6P59<K�s}�-Y֝Q��|��1�^w��0�F�S��WƮqO���؅�p���\[��0f<�����JP�q�V4</�y���R�bw�-�Wak���;NU�X���Kp���,���l�o̙* .,\#{��٘��n��<t�v��o�&?c�gqsׄ����ӹge�l��x�E���܆by�B��;��P�/��=�	4'�{fK�.�����g�
??��I���a���~.~�-�v!�D��%��I� �ؽd�[(�	��z+�]hl�������-Z��]��˧���e�B�w�R�)�7Hs������9����ߏ�w����E6���O�)+vU� N���0gS6s��k�A]6�:��Lޞ��Ps��V?���&TJ��eQ���vS[:��h�b����t8�*�/���X�	c	O-�`�s�W\�=t����_��q��t���m-��wN�plΤ��u1��g`��1��:*n�h4Q�ú�\��Mc�f�S�)>�,�V�P�M��M����UZ[v婵���[}�$�؏�2T���y�\1͟�)l;�F�/dȌ����j6�������׏^���ipK�aFg�9�7��}�:�@��p�g��%"��N��zAOĜ����+͌��C8d�<��>���܆�쮒�M?�7��]'rC����Y���Yt�U��L�L��qb��U>)��C��O�u�cQ-�r�А
C�v7�e�Wr�ۙ���I.��n��jI��*O�mx�%W�E��ˤ"�S����3$w;�c�����"��9V85�^1�&�eaX������Β&O7�w�������,�Y�/^�w�����9� c�9�t���R�c��tB�寺�ʽ��j�V������W�(��10���+o��
Y�g�3�b�����	�7]���͗�Nf�� ���;�߰zPl�5���<h(�K��/EU��ԭ�K�§*������3B~D��L�����O�q��dzns��A���p��A���JG0�ߗ	���f�J>���a�u��P�"�\w�����B����LTu��{^-7>���.G��)+�lG�T�����+�*qa��X1~���S����^gg�b��6~<�Vf0��g-�?o�eB2UM=��*���Q�`|<d:�+P���S�=�ϨA�ة�4��x_UM��x�gm�+Y������%wD���f#����*(F�?�0}O^	O��&�ȣʬT��t�j��gp;r������f���:c�D���ݝ��n�ʕ�:߂2Of`�|�yʀ_o�>�٭�i���FU���@W�k9����ߚ�#c��H����������,B,o45�ó�6��������U��-���%@��o09Ū�����xR�D�U�Uw�)��\����f�bk�g#�8N���6ܺ�/gKU����p����#�(����K�����R�w���I�a�O�x��py��|6��w���hs��O�N�����ΊX��H�UJ<�s
m�ѭ�@Fa�e��V�Aq�'!+#A�ex�#;��NS�'�ın)~o($���j]�T��Q�K�r�U[D��wt�}�B� �]�ڧ�.)"�Ҍ!@�����sP@�w7�)��X}����h�I�]0��gG� ��Q?��A{=�⡆c�	�lΎ ��%w,ȹ�V�O������"N�B���I��<�ݹ�g��[p[��d��<���u���9�J�B?�%\؋�p�Gi����,_B�oJ�K^�2��r:���w����'/�����>��� ec��ɰ����=7� 	��Q%�6j����¿��DrS�L���1����о� J�M}��:jq�������o�y4E}k���y{��lQ<%��s����C���HW�v�6�hm��.>�� �G,���� F5|�Iǋ �)A�J�,��?-bY�?�S�!J%;~�WP�콗���ý����ȴ�S'�pNU�Ϋ&v���Th�o�hFJ��
�C��R쇝O��Z��D
�����h/	���֑'U�3��S&h�8�x�t+����X�6�n2�e�f��p��z��yI�A���Ķ����D(pId<���*͋�\D�5���)�"��	�O{-=|�Ey	�6{��&m*�`���7�*��2��1}��s������$q!�j� 4B`��S �g���3R�iEh�;�K��ic��2��ꮶT���i+��I���j'�#�Y�P;y�V�I<�"��f�(G 4t'��BD9~J�rM`������[�3.������.���/,�ĸU,��o�ۈ��sj7j�&A��o�[��Ƒ��ꜼFɌ�K�U�ԣ�Ʊ���۟e'}I^ Y�,jDʎ=�}�}�����V 	R�%ǲ��&f&#�@�V �
u�{��4UX����U*}C~ٍ��yvE�ӳ	\ۑ�H�}�Ճ�����"˽C�Tz�&.r��O:)b�/��J�zU�ơc|��k�����B�f-���)q��n_�J�UAV=T���QCՄ��n�&��������T��c�ϘK|��{�Ui9!D~ʪGp�=��e:i)�K�<V;����>�����+�8��1����~�6��Rf�A�b��#��A�m���xM�u�����jxMEm�^��5{�F��Z��k��T�i�޴�,t����n��sG��T�)�Nl�L�pݞ�+u��)���v�Ptj;* �^���-�vb�V�lSS���՛j�騞�ڽ`4�����٪cI��}D����6L�n��R�TtGqݦjꮧ4tW�5k��TG�������YNC�u[��=�N�&��iٞ�l��u�-ϱ�z�A=E�<O�5�t5C�i��Y��۶�e�,��Q7,́�U�_��Yͺ�h�^�j.A��*�@+:���z�ф����VW5U�R�VLO��k��FO����k���jvÄΚ�^oؖ�h��5�M�����XdO�uի�
�1���6-�v��\SSl�	Xك�I��7��ˊΘ¥�V�{���Ws=�D�V�r��EmU�z��ς�-�h]o�g���pjx�a��^uX�n)�Qu�38WL����6�^��+�֦c�ԛU�7ͦ����@�l��q���7�X8 ���iҺ�:fϬ�hpn���gZ�kن���3��l�P�vCw]��T-��:����נ=Ű{�I��L758�L8� ��6�88�	��ٰ<�ޣ�_+�?�v��:�8.���80��0�zN6h� cf�3���EI��*ྡ5E�k�B5 m�=Sq�l2]mBƭpV���nynN	ρ��4<�kSWM���~R�:�{usvr�I��v�Um�hg%�ۂ9n*�����9���Saɴz�n*�4����~�E�~0�iF{ZC��3�t��Zu�6��b�݀�z��Pv�ueO|�S�5�:ܲfO�;=�炪��͞f�i4]��^>L���I���mR��fp�rL�G�g@�0�T�U
_� �̀�����tK3\� z,L�3U�p���٦3o��.�uQ!���z(��z�޴uJq��������fH��b���b)ͻ�e���^�t�-LB������p�L� 8��j{��Xջ҃L8�.>��B�`mMq{�]���f4��,[��؊��F��4�L��=϶�_]��hnNӵ��,8� ��g!kZN���J�p�{�az��`[������O^�r���k�#��Z5�M��k�M�����UCo��nZF6�X�X�r/}2|�j���p58B��F��RE"а�M��7��y��n��]S�Q���Z�隍:�?�]��\  U�y�m���:В�gS@S��᯸��z&��=��d T�ŉ|�����Ag��ä���6��mZ�լ^S�ĳ�NQuXi�NT/q� (V�ǂ����T���e�`�����N�b$��z�����	�>Ӝ/�A~	�?հ������R�_�|�a���y4��X���fr�_5��{
C���_Gz���3s��HҸ8�9y��ȋ���ݔoax�(���Ğ@�F:�����+�ӱi}��J��&O#o�.�ɴ��$��AxC'�z|�F��*O��L���"���h�9d�V�ҧ�+tu yU.��g(� ��P{��q��vns���k�;H�Ws
�^�ŭ�k:[$���M'[�CbV;��V֓��p�F-JF��2���4L���`��sN�d�C�r���ӥ�	�����~E�*_�Ҿ�L�a+言bT��G��A��c��,������_%��w�yZ˸��Zh�)2�bĢ8���4��H ��U�d����;��	�"6^c��G�	���p1*y/��<���\,�\ ��*o�$z���N�ig|��(О'=�K-�x.�e�����~w��sr�n��-��9/u�K[����uz)|j��baO���Lٜe��1�3�L���ԡX�>P C@i�t�5��3>\�Z���Ե�zen�f���vTa��p�'��d�q��I�|ˠ%��_�2x�6=<��a:��kS��F�v,�f�w :JDx�JexHy���[��'��������j��C.ܡQT���"��WW~��#w����3"�i�v�_UUI��b��V���HE�?�Dy�y\��f �.������/������ x�)��I��,'!(4'bF��_�]K�S���O���;���(2�*�{c�9�G���O�����{��s�r�Q����x��xU#�p�z���W��t��6|MH�/�����m��N[�ٗdE63L��LK'�T����n�+U��YnY��p>0�:MJ�N��L���'�Z ��-��F� �#24�f��w0�[NKl�YvB�J�]n���w/o�X|<BPˠ�`�Gf�6�0՞��"Q�J�cz��$K^�ӡ]�x1�d.�M+�ﻵ2�����o��g�]p+�6�"u���2��Wb6�(�Lf���L�/�'c���W�q�Ԇ�T���#Z�+�f���#����?$8�����$�fG��j������o}4�\�r��P�/�rPk�7[{��;/j�8��b�귻;��y���
�#_���ʀ�1������+RO�P��=���+q�Ƣo>_�f;��wh��/R�ir7�vvx'�� �U�Џ�������TfSp�#9�IY"?ha��TN S�~G����h���uF�����2�V�B������y���3]*��-�[M��E%�3=�:���zN��Q&�?�[^*4�(xIi��U(�ȍ[�,��}��J�?[
r�R�%������Ԍyt"��T"�H¶3��젔��+�pG��p?a\��)��v�2�3�����Ȧ�ѻ��q҉I���16�T�-x�
i�ѵ�6���������x�|u�p�Ik_���}@��u]�m�?�+)��ƈ�%1�>�Ȁ)�V�� CU��ι�П��i�����i�d��M��=$�1�6.�_ʉ�'��y��ޅa8����ן`(���~�pјwD4%*�|�|a7���1�0'�ٜІ�&2��r�n�q��:�[uf-U�� 	�(��`$�����Fʘ���,k|z񸝁�Ї{rukq���,�kCd}�oɟ���w�_���� u

�T8([�X)_�w�m,���U]K�:������u�B����ߔr�R,���"Ί�eWY�8�?�8x)����yΝL��2�+����%�?�%�vB��c�lEZ&%�Y��B�M��k���ç�삕��p5��h���T�]��&>�+��3u)��"w�ɺ�\S�K��[CL�l3�,)��I����n������')�q�7�-���[�V�	�?+�oX��6��R���Sp�u���_K*��E�?k��T9�9 ��Za���ڊy��pj�3_�֋l���j�~����W}�d�W�����\GJ���e�_�4�Rt��V�X�u����i���_�t�X�u��W��i�+�ߴ��-iƍ��q��7���_O��j�m,����je��4�B����<m�I�>E;�H/��0�_����p�����o������If�7@P�WWw�����@q�106�ݟ�A�t�u�}���z�B]UcEl����";(��Ϩ{�X5��6�ې�~�%�2i�r9�=!�Ƞ�ê˥�敀/tPV�k.���xd����[&��Wd9���k�h.��^F8�?��_�V�sɾ����%�}�mcy�O5u���ς�_K��� m|�W/迵��<mޯ�����c�OK1T�h���kI+�g?�_���VP��k���}����;��������������gK< >[��Y�	��|'7�B'��ᐎ�'�r���g���gw�{6�9��L~�{������OQb�����`­͔Ws�����5n��=��Y'�4�,c��|��Q�=E���^�+����
QnR������ֻt��/�7�����/�2�еQ�͔K���q�Ը���񻭃l�<7)����L)���-c�L���P��?>�Rq�,?�U9¸Z�yZ��8��EQ F%��~M�E�嵈J�@�oC�1�,>�r~ }`3}d֗��h�4��R|��rx �Ɠ� �P9aw�i � �:�u����$D	"�(���N�#Ty�tyQ��(�w��������R#�2��c)�h⏱9�<F[teo��
�*-��m,�������T(�����T�����쮧��<l�.݄��	ք����7�� �P@�w�� =a��� O���=���N{tT}��{M�?Ϟ�ȹ=1h�{
�/��C�@�&��xP�����0���'F�a�k�g���)pdk4��>"`G��@'��R�5��� � *�:�r���g�Ȫ@ �xL���arE!�W^���Lcl����ȣ�	F/��i{;�ƾ��З�z'��3�V:�ltwԎ�{~���9�7W�}V�O@:o�pm���p�?���e���2C�����3���*��3%�I�	Ϯ�0jk*�-�N��-Sվ����{�r:����V3蝨�ӣ���[�þ����ί.~ӿ��~��p�l��������K��P�l������v4�F�}g4~����M�����J�%�d��K&rzK��JffY�1��D�
�4-�? E����2����l�O�g�{���FR ��������\�_�U�B������Km�{��n}�q����~��(���Y��p��g��@\\�
_��95��J=�c�?���÷�����Ç��W�>S�o�맟~
o��G֧����������?�k�����O��:������ۣ����u��A���V�]��}����?4��+�ؘ&������H����ҡp��=�P��莊�i~	�� ռ[\M`_�@_z��}��^fB�Й�]RUlw8�+���<�����#w��zC��Ā��/���se䇃�������2_�3T��-8��_����9��٦s@$���/�%]l��y�e��i��W���)΀�m�;{�Ũ~��"R[2���X �1uM��5����g=I����n�0(��0(w�=mQ���`�6nB�,@��bN͞^�)��U�v2y1�>C�rP,��?�c�Q$%������9����{H)� 8P�w�5��NH��W����-����Ƨ��"��d��!C�Q�ܟL�yH��a#L� e�g��cX�a
Ϟ�,�Vɇc���!{���Ā!!
��W!&�7U2}@�fܙD�WX+�$zPL�t4#8�f���V��~Q"H�3�v��C.�<Sw��ow`���&P��VU���r]�y�������z��:D� �{q0��.�����8�{�gR�n�'\��+��_���V$���>G2e;��6z!�d���%IB���l��zݾo����u���ɇ�����~/��V��7j3���
�F�al��ro�}H�]\�:y��*^z�h�K����!p�v��ָ,�\���m�mk�H��ܖ"b��?���99<޽#�}:f@��1��:�z����v9�����xL��A�4�*2j�iʨ�T��s�t��s��̞v�'턻����ߣ�E��V�����u��_/��u���[/�7gw=m�Opb����yek��	��2����:�!���A�f��:��&�̉P�4�̓L�"�Ro
S����!~ Z���0z�Ȁ���
T�
Fd�xH��!�I���p7t��ٴJ�`-W��GT�F�ddT�E5|}�𱜠�s	���G�h�X�Y	W�ѱ�@�#n����b�WC;Vώ�15�W�y�G�T���KV^.��r-m^v���̝pv�SG�)q�u`\C=h�泌6�8G�:
m1��=�"W{[�.c�E�.���4��^�3>��6Ȭ��=�:��}I'\�џq��X�n)�gW�����������t=��Ut��U�z����T������k �;��
�'$��ڿ�\���<�q*����.t�"�� ��nN�<�%W�H�������jP]a�v/�B�S��
���j��:Rq������]O����誊��mOh�$�i�V��/���5�)�a�\�1!��G�#��̵���� 91Q%[#�~�(�h�ʐ�������j�4,Dt��o!�[���P�<e���xԔ��-+�Z쌀���1pk�����xA&%�~>,!�"��w8���	t��j��'������4���C�`ЋdFy��<�2@c���(��Ҳ��}���Y�o�j����Z����zW
�ݵ=���s��"��J�����t���֒��Ok
�t˾�뷐�[��[����q�o\�˹=��s���v���ߣ.���<�k�k��b<���Z����F���
�x��o�����10w�_��6XR�@*�����(=��������U�ǻG��07.v�b�RL\I�����["�֛������t����_(��X�o�j�?�ß��D�*�4P9�I_;�h�V���Z���Z̑�c\(t�N'T�Mj^��:�#|�%�/�ߝ�Z~�5�y�X�-J�����0�}.��ops.����+aE�.� 5�C�;�O�D�'�^T|��`$�y�S2g&6����.�X�����ab����E�3���U�x��B ����������4K������{��x�{t��ǿ��I�l�:�s\%~�����/�W���������4�%�R���RF�u��:���;_�XV�J�8x�|�����~K<��a
�/^uIj��M'��.�oP�T<���*?ە��,Cf�z�rET�8����Q_%����@O����)i����'(�v�|� ���t �fAc�E~M/J��C�sNT�mq�t梣���&���KWu��8O�0��-�=�}��߄��������z���G���{�,��_�̲������3:�	�b>$�m��ai��ֿ��o�
�#O;��_Ȝj[i�X-(�vZ��d��bְ��x�1GgIS=渞7������n�X��+��cX�'g��5oz������c�9�<w�q*��
������`� ;���U��@��떑�T�(�����ZҪ����foԛ��n��/���1
��1��2�Ư�5>U;+�� ӫ�VU���e���7��yGv�{0*�W��^��o���̲��2r�U���wٽ�RjUE�j��/7v�m�����&)Ì]^��*0���v H ��TQk�ZP�+�%R/^�O�e� F��,T�� ŀ@-EQ˯��A0���V� ����g���$�V��,��-�G{Q�r�'+�J��;���mcAM����׍�d|�)~M�Lq\��8�|��9L�'��-�4!��--�3�p��O.x���t,W�SgJ�����~':x;+x�K>�}_<�S-��fJ��S�Nɜ�j�|�V1EF�Լ�Vg�@�\��,���Z{f�v?���t��w��!��j�zjں�?u���\c*�?ץ�9_�������OG�S�-����?�ߣ�';�E�
�����~O���b�����2��J��2�����MՒ�?k<��n��:R����������� ]�`��s�]�Q؞�#�.��?(�7�7�W0{O���Y4�
/㒯a/f�1|�܋� �<_J&��%�0wb�D?�/�mAY�o���]X��k��@�mM������<2#hD���+��
��I�1�Y�,�eݒ��}pos3��W���R���x�6�R�WU��W�
�o���{t�?�]O����x����T����5Mq��K��]���Q%��LE�L5s7�dp!z|��sV�+x��pf�'�� ���2b#�Q��ߜ!��t��W��sc�*ud�Ԍ�ʏh<5S�V�}�V\y2�.��0����!�DZ�P�w>Aw\���C��ˁ?iٮK�aaθ��>�TX�{�y��9�t��04-Zۢ[\܆�3<A��f�c9�V�:�f��4���2+[����7�Ŕ�݂��5�h�!��ۈlm�o��lܟ�_�������>���
,�7��������;h�_�}ߧ����XV�Z�a(UU�M�^U�F����̾��%�0�����.��t ���ؽh�;��	��7"Z!����"k�_��;�c���F��o��T�C!�	���Н� �@^���G=��$��-Ƣ�"�ϛ���t/p��=��T��S����[G*���A�����#���	^��+����MO��{g��{��!�å�������uA�E���D���k�x[�1�g���Ҳg��Ng��t�v3`�������2��'�&����.����آ����(�?緓���'��#��x�V�»�jWdq��O@)˝d�7���p�x1���Nrx�N:�'�k!\z��L���Tߒ\޽c-����{�A�Rb��������Z���{تt���<��8�-{8>�[��hz8��ͨ��9�M��A�)�������tę�H��LX�e�'wi���r&���1d��i��Q?<��F�I�����Dn�[SٞL**|=$����
�rG[�j�x���VEMu��?+��-%��܃��7�Q��g�{V�W3��r��Cɰ��eYVh�[ۤ���Q#�"��V=S'�reB�=�{����dfx��TH�3����NX}����¨�G��@Q�A_���}��5� ���cݴ½�7����@v�V<:��ςr�T�"+��D���<���|���������zHE��L�Zᎍ`6�&n��k������܇�6���� �9I����;<�3ߢ346�:t8�|S}]E�����H�w�AZ�B��S"�:y�� z5�`em,���E�5��M��RוB�{-i��J���(G
��i�{�����x:�4�4���
��u��r����9��J�bj\V��#�,�g|P��HU�}�jRF������>`�\W���+��;�t��5��#�i�s��W ��Rz>��/�5|�ӕ�q����QmSy���)���!��s�#w�λ��%l���)�58�$�
�ow�<�u��]U<	]z;��T�����1H�\�[�O~4��}9�	�\�o�m,��4��.�z]с�3-���\K*迂�+���zj�����.Z��\u1�t�o����F�nc2���.3���ܔ�rE9g��c�sE�Os��p+j��$�1��O�I��_����?�^��_���$���!�j֟�E�?�.����f�������:Ҋ���x z�>�f� ���ſ��_��_���^��p@|��f�%?{�����wïv]JOɵ����қ��S��1���5R"���x�&���.s0 �Qw�p{k�9�����TB��t�T.p��ӟ؀'U��|�"�p �wSK0I�=�9��	Ӛ�o��MmS�46������w�}��n��d�1�ӛk�/Mc����Y$0�Ңiy�y)��0���0�G�j�����E���j�����?�����Z�ʶ`�@��¾"S�Y�̠��4�f�<#vH2�l�'�YU�*�R^jU�RY�# 6d9J睈΂�Lb8��~\��0���Q��a�(�[��$� �C�6�Ά�;�h�#���t<��������d=}U%[�'؃Lu��'>ܯ��i(^��Jrh�0���j�y�43F�CC��`ɭ��`����.;�M�Im8pjb���k���;���i wy2X�������{�vC��p�V<Q}Q38�B*��GS{x+��UZ�����p�;ܻ��_�<���C�F�F� ��+{�+}�Ga���ʟ�W�s��V/��l&)�"��_K'�c�pH��Q���[�����4>�3�C����e�8���P�u�1�:���qNY$����'��O�uۺ�����gO��i8��m@@X����(������ğd?ő�+�)���a8`�bj�&������ķ����雔���%��F�խ"��z���s�Q���)\�˝�
S���JQ (l��C '�t'#)��uxM�����@�L'�p`8�c�x����XAg+1q����_n��]7��6����@�]f3�_�$D*J��>,�B�� 	s��t��̟=2�C �Ɉ���=����F 3�:��	�C���ҚQ[)�������*�4�b�u�q���<9�i��h��`�����/���5(��Ɠv)��������n�vN����u�wx �
/u��@�0�H�	+xx������c#^�G��v��LX��hK8K������X�s��;2�4L�� ���v�N�f�!��o��Jۛ��o3�;��b�Ȭ�R�b��s�u���1�o�pz�[�*d��a��0O�33�`zk��+{Be�o�}��hF^#�m�ߒ;���	�����eE���d)��x�V��[��Ucv��I���l��Mqi,*0��Bv|vF����k8P��p�a��J�- Ǜm��?r7�wOIp����aW������WTa��@����/��I����;���tL�1�?���jU��)��v�`�xo��Rgw��x���������������9=B�G�=\��h�.���+d�YZ��������nhl��b��#=�_��t;G
� �)�_vs �&L{8���!G�J1<��S=�Ԝ�Ă� W� 84���b�k|;��!7���?����gtYV�]F�w�������x]�f���O�����{{8�+�PG9�퍏�~<k}���_2��~%QI�;k�ׄ���|�ۙ><OR������"���|Y����m*r�f$�8�%�=�-+����II�I��鑝�Tc���@k���?��xȎ��8�M����n9	d,�}x�f�	�+�v�!Kr����xyc��!#j�����܃������͘Z:!����i�&{.����.L�T2����c�k�if3�7-?�?_ߴ7��
��Vm<�Eʝx��"�eg��1�S$�)a� �~�dv��:'_J�x~�$���A�\%�n�3&��/��h�W�`���q�)�:�
I[;�:d_��P��V��%�_�R��fKAn���R���b���Aez=�-���{{i�!��p�����H��v�N{�� �h��4u�q�Z���Ӱ˶d���\.Q��,�_P����QL��6I���+���v�=$���;.Tmo��T�����CҶ������'�0��Y�ʃEq83^|�	�ImeD4%.�`K|��ڀ��N����� |�$��ݪS|���O��n �xz	��n0�g�*Д�ˁ�޸����v⩂?�c��)����y{��FU�\�ȩ4���������R�>�r���ـ���i�'���q;�����:��>�܆?��x�$�^�EgL�/�y�_DXR_y�~�����6��Uɘ3򟉍�\��cZ$�������u���@�N��3��D��U�>W����"�7��1Nceb�E����������E����B����_y��1��|���YQ02�8�?�8x)����yNB
|�/J��'�~L=�k�?9*���7[��I3�_h;�nc�ghz��3,�������]��g77�P%*i��^F��M|���:"Gp~b�.ev�\C�2W�q�)r�%!J��NZ�� ��A�Xz���?;��]�E�����#%�y�{N'-Uo4[j]��H�F��OI{��if�W�;�o�N�O����4K5�Oe�?u�����T��<��Of�=Y�o�P>�VX =6��b^m=�Zi������[Y̬�9�g��$*��\�,���%��������V��kI��~!Ϡ��W�=\�|��;���ӎl�`�[���/���zٌ�����;}�[�����]�p��DK������t 3vA�ݻ�y>`d���x�������N�����lá�i�w�VU��ֵZ9�&-y�d��3L�C2���tK�3��?�V9�����4�|D�W�\摽�H� �8t���b�J�X$�Q���K]A�/K����kI�#}��YQMj?<YA͎�H��bڜx#'Ax��g��£�[�`�<���7��/yn�ę%�������I�E�AR_����Q����flJ�ϳ�3-��m�A'1�#��]?2�|'ȏ}��HE*R��T�"�HE*R��T�"�HE*R��T�"�HE*R��T�"�HE*R���D����� � 