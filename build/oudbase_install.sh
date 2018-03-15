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
VERSION="v1.2.1"
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
� k�Z ��zɑ(꿮�HCl��`!��m�%DBmnCR��m��"P �Ta� R�����%���G9�r��Ɩ[U�$�����i�@f�{D��I�7_�gmm�ۇ����]�x��ʏZ���p��������~����KOf�4�`*y-l����:̿�$?gp��
˛��V>�c,>��G�>x@�������Gp������Z�s)��?�;�k#
���0������Vv��j����d�E؏s�y�P�fy�Dy����h�N�Q2U�Wǳ�$ͦj���q���y�Eq>��<�����7ԋQ8��e���:�����Q��o}���8j�Ϧ�.|ٙM�i&_O�A���h��b��Fy]��Y+���}*��c����S�{e7̧[�09��Ϯx��é�m�_p���"��4)5�_p��Y6I�!=�Qǽ,�L�4U��3�T��Ғ^�x�*�UMg���w"�F�����1g��8��ѕ��Q_�LE�E��	*�0�M����&_Ѽp�0N��|��>���3ܝ6�X�$P�ߍ{Q����p�y���o�~�{i?�QG�?�(R0+��Mˆ3��E�7���V<N3�B�uN�%��GG��g�>X~�m�-���8�;�9Т�t�^m���n�?Y����٬M�����vM�&}�na�ۆ�2M��p4���XP�{t�s���v���h�ׂ���aw�I���U��n�sp9<E|�1�N&���q�I�yg���]D�\I@�]�[G;�'����U���ZY�'{���;Gݭ��������F>�م�W>x��~���J-8>�����v��GOj�����n�3��Z}e��+d���+�j�^gg���}�=>~w���,��������ѓ��E��?N�|���>#��^���K����h��>i�v�OF�7����R�G��^~�j;���&�(���E�������>���V��jn��@��o���?��p�/Ӭ������j���*d�������=�5��EU���2�{Vս7�z�8g�d��8����h��@��T���v�E=b {a��怫ܺg����GDK��.��'jGXtU�����0��/�:\s�x�~�ׯU�|��ԏ���'�^��(
�N����3j��a㚾�F�{u�ū��A\���*��#Өi<&f<�RW�v}�|�u���:N�����*$��}�w�I7��ː���������^Ö�k�!�! 2���B�� 䬓�oCs3gR�?T�����^��h��!��o�|��f�������o�6�9��?v���,�L�z¸�Q�qk5��=��kЪ�ѝ�<��P#��|]SO���ˠ�jqaQ[�7L����^���y
�c3t���ݫ�`L3�R��|���!�{�5�;�/͵�zC|���
.]]�
��:+-���&Q�6��=}Z���ݯ���7�K�gC"]��B�*�nj�f �ԛ����G�_��$�'$yɱi�V7<�+pڒ�쒫u�9PThޅe�-�btK��\��t��$f�3T��:��5#��佗f(w�N��!6n:��V���o
��R��TBb�H�I:�C͑��y�yv�`(�㨳��5����qa�`���J�h�<�`���"�G(=z�Y__y+���a��zC��p]޶�Q��ە/ =�-=I����=N��wYC�¢�������,����I��/]w���fI��؈z�x&>��O ��݁� -�� ϒwIz���ӧW>��鄶��^�7������yN�[Y�w/�Mзpip^�� Z�DLu_�"��X� iP}��-4����7<2��G�1!�(,�fG[�-ZQ搀v�{�jC��Ҿ��������`W��r��>r�����ϳ|�.�$	U��0�R���i)�|%(J3�#�6��6�\�ؖ?��h�^�B�*���t�bU6�@n<m���v2�L�;pP*�����P����p��,���f�.t�K����=�𤫆q�:�Q�A�1�ڿ@���o�&�楝$�����ͨ �Q��"����`ᢢ��]Z��X�AƄ6+�F��Z��dOQ�X7�� *k����?]������T�_�ڝ�7����c�� �p\AK9P����Q[�Ь��$F:� @я��l�R�US�6�� v1�0߷µ��,Q�	n��<�~�{<�KUsl.��V�����+���#A��c�6��[AX�Ɵ�8pp��U��`���� ���آ�>��DF���̘���@JM�Ga�U5��e�G�tH���d)^>��"]�p�'a�0E;�q�[/���͟6��J�F�c� >q�a],�k+���绸���\DF4=8��y�1�ml�v�9-~�-\S㜶Y]uww�:'�)Ϊ[���ʟ�b7��=�}�nih��>�%
W؂�Ֆ�E��2nB#|�B#�Se�1��߯؈�+���$?�3�Y:VS��i_�Oz;�P�6 �В4}�f������	A�#, >v6�l��5��|�`a�vV����{8�We�� �9�Æ.#8��I��j�f��Z������������|8|�-�vm���!��\���O�QB�/���A�-��/����E��u��n�� �#��+�$I�@ Ǔ)�~���(��Q�3��x��¶�a9���FU�ph8�@.���z�5�1��w��+.����o^��6�{]��#����P���Cl#���?9=����<5cu7o�u��l�u����)�,콃>jg����hO�m�Q.��	Р�M��STnV����I[�_/x����*-7��?��*�9�G#��ꎨ��Qv�'b�q�W�A·����R3�CG}ouM�
g��7�j+�O�׊2c)z����*=U:D�$����`T�w�;���c����ӱ
�+bG5����:�V��w���G�Ojo��[�s�ӯ��;/��^�{�����'�Y���[�����38�6������wwq��o���X���}���K���g�F��Ҵ�33T��׻��Ê�
'�p�Ҷ}�c,�:�\�$�r��P1G�Y��yR;*:����t����H. ]B�p��A>�"��7(~#%��꿔���v�� 4����ξ��ٰ?����j�:�,��Xoi�����~��?�(3g� K�;'r�
���\+�K��ǂ�ת�E�]�{����=�G�����'7*/ʧ]���-�Q~���h�X�>�[$��d��h�Ic-7���a�O�R�$�E�)��"K��9���fT�+#K�f�#��}f�y��Eȏҋ�XY�Gi��Й�Gc�t2#)	=�X/[+?����/s�GR�$=xP�UR���c���JsQ������_#��������pc����}���%~����J��������K�w�W�c]))���/��n9�_�#���j�G���Z̈́��nԽ����c�+"�>#��}�T5��;�\ᣛ��N�����s�r(ڀ���sz��gz��H��cn�m�ݳ��m'8�B�A�6\�l���V���������o�Q�ԃ�>KFz������w��DE�s򒆰S#�����D� �7�5�}*��G�к�5�[���P9 �k�� �5�k�?o�&п@��ܴZ$���+���CބVHv �%����dp�? 6LT4P+DjN��2���D��	j��q�bd�d)ij&�D�UE�����1L �ɒ@y�9�G(z�����4|\��AZj?E�:�v*�D=֮K��k���䇥�ga��l�Wd?�_:�%��[��_����3��!�)���@m{}u�eO�b��|��g&6�24d�re�>.!a,9�_5�^�2�%��2�ÚJE9~s�FL�rD"��紘VK����vr�K5ƫFQ<BOad����䵲z�S͑��9�{�N�Q����H�&�BByݶD�������A�W�^5sX
s9�k���l\ �f��/���'���-&y���W5���5@jhO���&
�>?Ɵ 0������v#��%�� ~�8/RG�RQ�4N�Q��D���������X��3��]S5��>��恡DD�$20���y'�sD�f��:(�D����:M����Ǜ�f� ��D����14t��+�Zg�mF�a�~�h�U����`[�@=��9�n#� �XJ���Ә{�)V�t�@�0�����B�]���\��� �qf�����W�3iY2>��VƋ�^��
&$�w���Oפ7LóJ;r�c�����ɖ�f�V)밼��w�@�>��Tg2,7�zd'�gO��T4��8��9F��B��띻�d�3!"Ĥ^f���[�cp�'�wo+�>�s�cQ�E�}��v�sҹn��W�k�H��]��:�x^�,�*Y�n���w����[["�����ֽ�����[�E��J��z�n�	�tlNf��^���g�`��Y-�j����<KCW�왙�۸����_KRl]ӈ��	UB�!���5~��B�S�U�i��Ε�13�MӉJ1��������M���A�9~�i+�N�*dR)CP��]*;���vp��~0 4Zq�β^�ŏ�N�n����x��y=c�*�!\]�_�m�Q{zi2����F�%D��0JK�~w�����.����a��7���Y_.��1��V����X8�s�sa�>C�y��l4�O񓳦d>�Z�]��V2+�zبg���������DS)k[�};5��_%����\|����n�3� 8�U�܋I��w��kh#8l��
�e��������[�3w�R⢽˷f�J��Ҥ=~PTs�J�D	5�ro��c��s���\|�@7x�;��ڡ�wrt66	w�ӷ�&�@i��0���ԥ��)k�O����v�q>z�2x�io\��|Ws����.P��2�U��M��gIC~������Rq������(L�m����zI `�/��^�0�^�8�f��Y����'�7X;��~[k���K �w�m�6�U�}���>��1�Z� ��ٶS��)�"�¥;�#ȷu���A�X�v����9�ýj6u���|m��F�27�>�Z0�[�[��p*�xqx��9��N��+	_��o����[�[
j��I�� jF��6)�TO+n��S�Q�����ŋ�\7*ТFg��Mn��:�*����J3i�Q���^!}uozY�E�f�HjU٤���e�>^�ZO��k��(��_!$�B	�G�v��{�F%ƹ~,p�?U��x	D��e|nU�Jg��S^X ��Oe���M�9� O\���8F��1*�)-���ˤB���:3�4�>���X�%MAΥ�)��X�ɺ��K���|ޏ��bE�W����v���Z��_6>����K�|�����̅�W��S������_���_��)�/���iXƫ����W�O������=|��c��}
�5���w9�wQ4	�vOPzRk6��7�'[8m�|�Mx��Nx���W��R�L�������3�6?΅Sxo�R���u����tv-T�r�w�7��_�-\{/�+��Q�������̼����Yg�/�o��V���yc_s��1r޾�{�5������5��k��ȯ9o_s޾�}�y����5��k��ל��9o_s޾�}�����x����n��w���xs����nӺb�De>ػ�"WC���D�e��%��n��8���$�& \W�y���[��
~w]x%�6m�kV�׬��Ya��YaN&�M��$�@zQ���<���T��Y�:i�?)�kT�;��8��V��R�P;���`���=V����������Օ��uS� 0A�T�B�]@>��N�륾Acu��Q�>bQg;����!m�֌�D�'���z90��=��%�F �3$���~���BY����K����@ى��u���6/��:�)��ʆ&�Ͷ�OĹ��qio.����9�o���trߥ���s�N{���4�M�X�c����n���V�;�]�;����&N�w(��-���D�?�D�`윗��9��^��M��{��Z8��I`2ߪ0C�R�%yYZz��+p���ɬW>�sq�;n�U�U9��Ϙ*�X�c��W9�'�>H���d�W�����+���M� �j��w1�����7�5=�;Sȭ���s6��2[���n��ͫ�L����r��_U{V�z������96BX�j���\��R�s��g�-��sNL��n!���|�g���R�>?]�S�~�4������}r������y�+6��P�e�β3��x��)K�}wsw�P@��%�CV�d5*�U�p�Gl&�Q�$��d,�0{�^�̳�jf�� ����Y�����A:�]E#ey��IR~����ƶ�I����~���/�2��_ޓ�_(�lq�ߣ~����6����?����K�|���u���������)��a`�6�Lk_� ��� %�n��0�1��R��1�#��gSO��R.ֺ���RꟘ�^�Wża����^�z
Z�VAG&Qu�㗧�����?��x]���c5�샺��e>���l�d/�����0%�,_�(y��}�y���os=��q"`�y�ymDjr���z���:M��N�@l���x3���luv�VT�gn�g R&X\��
���*���B�D�y>��Iw�p�s�=���h<��
����`��։��I��g���}�h$M���Ĥ�R��{o4f[�Q�";/�Ԙ�����hR� qrO������������!\_�H錣�b������p��l:P�7j^�4���zb������QXK6��ޏ��'��p\X�1��`��L��.K#1m�x����ĝ�[�t�tL��p�ky�����i���9=.ml�:f*���4��;��OlX�-��];��q�c�zc h4K����8D8z����Q=�1����.�[����|�[7�/�\�Oh���"�d�?}���[u���[�����D.�Y褻\�2��'�;�Gs����y��C��?r����)G�y���~�'�Փ(|Wt��t���J�i�VD���#�ӫR�����贐ճ3�	%���=�ILbq�>��hm!��#	Z��*��]�<ژ��JZ��ӟ����+��hdoNUI0o�d����h:��.����\(T�Dv735_��jFb���8���;Cz6�0!4�КjGW��q8����4��|��V
#g�1��,B��T�D
jaTd�DE�$-���n�"p�c��ډcb8^���W`	����'�"f��3�+�,8���_G��˟M&R�Z���t���k��W�h	��c�d�8�G�e	;��dv�%w�e�n��'�\���q�*D���v*'@��K9A�5���I��pu��r��Ĭ�x����T��E`��;H��S��s(���P�~d~��gf�^am��.�͞wX���v����L�P�)�$��`����$���4o�neF�c�*6T�����I�s,$i8E=b~�������Z�%ߛ�;��i3/%��!ݟ�-�R��U�]`x�<r�h<�^yaj�ڲ��#LQhLET񢑽`i'�)����x��0(` L�|�T�FW����Z�H�A~�,p�p�s#���~� w��f�a�X�`�wp��)��9��J�q��B
��6���J�E���}Y��h���o�k��g��c�_Zʸ��Wv����()�<��ㅸj(UԖv~�����n��(��#��ǀ���
8Oá��L���`*�~���5��U˯�̂�y� k��Q莯>k�Ulم�~��N��?tQ;S�C9$��C�_���������f
"�m����*Bݙ,o���(�;���� N������Ma�|�f�@��7�1�������3�c��NLm�X4���n�&����p~����#�'�~<��	�bb�ը5sP�iM3+��WRs)"����i�F�)Yx��p�PDvG�9)@fϟ��.��cxV����/q��+v�륞|V�������К��w�TC���7��E��A�nw�!�g�LSD�285=��J�����R�z����1���(��b��H7��{���Y鍮��-:�9��H)w*��n;N�Mu�|\��˓�C���[6=�lj��Co�n����x?>�M�l���ZӁ�H��/�8y���9��<m��T�mv6�4�[^+�7;�,V����+s���6����<F:l��;;�V�߮"k��XB5ם���O��B�t`��.��\_�
��|��M�P*�ap;΍	�g����������/�W��� �@�I'Ӂ��M�a��i�o�ѯ�9����)R��z�M����S'�gW��9��_D�;!�u�
��L�Q}�����9��H��EC�
���m]�D(� jZ�@�U5>c�!ؓ�7���r��	�h�@��"s��#�ew����J��V�����G�E��(*�TL;��ӻ�üg�תn��˝������&w�U��1>���PnaW�����I�n��T���}9���.yԓvhd*�'�mw��cn<���');N��jFz1_���>&m��ʺϏ����U쪹)��ҿ�)8����(Ws��P#O�w��sl�( mMeXA��7VK	I�Z�p��;z�
T<]�y��TΣ*d�9�V����%WRέ����|Լ�Z�u�j=ݙ _�/(0���ă����Ì?�`X�9+��D�����J�xzL����&�5(=��Q�IB"G����J{rW��(
����7��%��h���=riL�{I�Ʒ9�hPވ�_xȣ�ai����6w���3oNϮ�Y�W�uzvGS4zP�9)w���X([�ԴO�H]w#PJ���:�%�Y���?V�at2j�}t�ќ��������~:��<�V�fq�L<�F\�U4;��t���ݱҼ�/�X��W�Ek���ev����sv*���zb4ί� -/�H��U�	�\C��>�e���u���^6O�"̱��۽�o��z��馃���6W�m��k[.O32��~q%\%���wK3~�tޜ�T��ɩ)P_!&Q�$�H+ ��|~�%��!���׮��������Q>ˢV����1�&vzد�U<��Q��<���%���>0W�z��oa�iX��Q�t:.�;�f�g�Οp�J
�e�I�}��@��Z���Ϳ�5�X�1�k��9������u������#�����D̉o��@�x���*~C�G�����>"��|����d����a4���x��D�n��owZ�m�:?	Z-�&`�����Ҏ-X�x^��af�N��'�4��ͤ^�N>]�����L4����	�����\�?/4�|Ns��[�c�5�i���u�{q��Bs7�m�|^�C��{�ϛw���r?o)O|CDq$��y=���]|�����`�B��E�SR��U,9�*�<�NESf���yU��U���� BT6�Ͻ�.��vFq����z�\{��tF���8�B\�Ң�T�7oW�mKf��M��e߬��\�B��rI�������)���..�k��k��*`�yiW�t����<�� R�1����X��j�f$fs��,�3�s��"7<>�Pt����>r��̈i@�XKg�[Dd#/�^k��{����C^��r���|�gw�FY
9���b�qP�A��/�"�%	JD���NǼ�@�).f!���j�^������ϵz�G++�aMBJ�c��X�y���L}��v�}���m�I�#kO9�7 d�o�V�Z�@�*z��f�_{�>(�_e!x��/��h�}��g�F�Y�����p{sM������z�1���X����/��(�9ε�C�p_ؚ- ��~����TŸԵ��$�`F��N, ��q;͵�yVU��$�:��-��FQf�4�^{�)L�f*t��)m��q�1{��/��FIzI펢��'���C0�Zם]�X��,D%)���ް��Q�䬴����d.�PLF0���QC�y��"1am3��E�Y���<�	N�"g�N��be0�43|��#�<����6�bEC������w��[Z�K��n�;�FmV�nr.��Y�G�V���P2,�v��&�¹�����y�$چ�.F5l �y���O9�����P��Uc-(�:I��ӄZ<O��0�˙-�<=<8�B>��:�hD��]v�;��"�8�CA���3ly�
��6vRn 	�+�,T�K�Q�S8*������3Ra/n��[~ �}�M;@o�������H�5�r,!�%6E�A��%-Y��޺��sȒ�ғ��=�t ��O�O�n���A�y�=p��� ��f���%��\�t�_���K�"s�7������K��z�l#1�8f�ϙXԼ�禈 `�?%`n��������O��T��A.l���~�� +rb�<������L��F:�ә��"�[Y�B`m���Ms�lu�������\���}Lr��Ssg�+���W��l�3����|��QV>��@Õ�짙�!�gxۘUr�Z ��t�������oz���z���(>� ܯz�:K��j�!.X0x1�&-��a�<R�R�(�/THFkah[�in�~��#�G��W=B��|��-B�"FbF�ݒ�N'k�hi�$��µ�ǹ[��ոEj��`�CT���u;'��Z��Д:FR���/���cǵIP��� �C���BQ�@�ݠS��i}��'u�R����Nƍ��\��U@m��3
ު	���Y>Mo��R���2ЋL�s�����l�Oڙ�$}�Oޙ_�ܗUjŕ��_Z�{�<|��V�`����)6�97��,N6�5m��#�{]q��t�[���M������� VN�j����%�?���U�a���-RZ�a�@ZX��mG�q�R,W�9�)�Z6�bsSn͞��O2��[S����My.��A�B��-�dK�휺A��d�s��Ą)�r�ܭ�g���{Vq��������i��x�ͯy~4�R�$�]�n��]������G�;~u����D��;��!����4��s7�鍧1G�Z<��Nv�W>`�k�P�9�W��,�E(}<�i�"	��`�%��0W�k?�T�駽��c��_�^������ߪ�����>��z��'�?�����������w����ۃ9翾�������o<Z����/�*~^�R/��ݣή:|��C	��b��組��o��?�?ϒHm�a���,>N��V�>Tϳ(R��`z�����+��9� ��k��b� ����4P݋(��@�8����́S��O�H\�c�h|��vh{�P<�`�nӄ�#~�K�ϐ94��>��M(F8��Q��[.�fQ8�[��DD�Fq�#u8;���Sc7�0�4�QD5��;�PA�7�B��ջ8�S�"Y��Dz��T�nZ�;��,�ϝ�x?��s,Ϗo�`2Ix^q�$Ns4P&jH�H��@�gWh ����`�t�q2��>���,�B�;*��FĘ�����X��<���4�y0�S�G���Cz���!p�$��ʛ��ތk��d�<�bЙ���8�p2�(�c�qX�a�����0��Dc�D���+�aH����Og!D��;�B�%��a	iJ��=����$
��tp�|��/÷�(������`�ŘF� |�j}�Q��S�L-�@�W�����4?�*ǍO�"��1ʚ R]����0C`�R��y"���~D/C���O��:�!F�N����Ac3<t�ӆ��xv$A�H@���A����h�}
�%��ʡ|?S�:Š):7"{9�F�N��ª3�����.�arG�g�����v���_"֭ZD�S<xl����lRx�,��xOc~lU���K> �����fL?�E���W��H;���{�'#��h��7�7�n�QM�X�v�n�D��1&C�.�:�<�(�d���qȼ�b������
t��u���J��t1�ʇ�.�ق(��r���B&�-�hB�$o�"j��(1�=ܭB/֛^��N�$�V��
�8ͦ�k����x�����Q�=����I.p_h�E�@������6�pm���(�Թ��^�]6m0ɻ��C���	K��̀�aj?�@�D1{�!/�"T�Y{ԥ���1��A3hgl�C�b�E��cy��2���"{G��	�o�)�b�� �s~2Z^�	��7}�v%Q:�GW�x&��Hb�G�vLv�7�
*�ԂץBz�?�B=x?�Y��Q���!�n�%G��������d6 �.A��S�2��a��g���o�  �r�ˉ�FE �H}��Ir����L�T~�L�� �MbI�^��כe���@�ͤgY4�	P�?v�{����=
4� ��#��%�?=��}��N�h��I�e���n���F�"2��D�����H�5�륧ڢ�Z�A�0�G����(�v7���'���S���ޣ�ų`��,�Ĕ�^�� �`��k�#�so`�t�U�[1�)v���	ί�"�5��͜�g��2#-eD2�A�	~�t��F��-�$��a�6�����iWO�0���q�8Ӝp�����r�	i�\(|?%��B]͋4�p^>�G$͸���z�C,՛��{Uq�Bm�af���d�Tͫ�H
,	�yYr�{��Q�ǃ[(D��E��0R��q.FS$�C/��=�5A�á��$��<��1_:�����6��9�9�?��k-Lǋ���NSc��Wߢ��͕���*k,ps���w�Q��@���"5��Vi6!-���8�M��/(a���;u�6ڝ6��fL2��/:`��R�z�JuCL��f��Ñ��<AXnZդC���HjV���̮\�]9L�пHk̒�M�Ds��d��ᄮ�AI	r�'�!5�!�� �D�n�+4d��� �`Q�K{,���(����s>`'d��ɜ�b�W�4H�մ�F��h3:��K���j�Q,�ە�1��=9J�6���;<����>�	MHK`�H\!�6�s恻{�D�����~-@]�G!jw�?G�lA�)Nx��%G��G-��e 2�y�~�mx�M$���[���W�3;�u"" �̀:xtd�����.QO�<4(�{0���* ��E/Ff�"�a!?�`���e4���=������H	f	D���n:@���N%*�@YK�]�#�!��
9Ō3(�/"�CY*��:��4t�(5�5�뗡�&���&v����@B�t �	�<�]���S9�Z :I�y����<bk�
���Eb�(C��k ��(E�_���\aƶ���F��pH���.-ꅒ�
�
n������$�آM���D,yW	���Y��)�l��0��-���a�/J�``^?�Eb�OH�NzBd��0�;k���;�v�D�oQ�"Rb�0f�m01�[J�][�zj�_s�њ��.9b� �B���y�.�'�_K����1E�tp�SD�ۻ����ܪ���=FQ5��jGo���l$�G&�1}�i�r�A���dH)l����M.i *[ڿB�ECo%���7�Γ@�It�{�Qh�mc܆H���!	O/@� �芅�p���Vo�ee�A�3:&��,��՘;
U�b��Q�>����R+D%Pcґ�����J��z8�r>@�z��s&�{�O�	[@��Ęō��TɊ0 5��t��ꊊ�!�e-&�"��	��[Y�>���X�Weġ�ɁDa�
O�KE1Ca^bM��h�	j�Y�m�ʥ0���N��r`S��H1#
O���w��F#$�I���yk@<�gTpƼ�Bt	�	s� �5�Yב#��p�X�}�`���GQ��Q+�ў��-�זo���0�͆0t˫uʄ�#'���J6i4

�1G�ԕ��b!�3�yڵ�����;�dSmj�Ke���Z9!�1 E:���p�/�K�Z�M���s��<(^W�Ԣ�9MS����=���w3���vp7�L��)�lg�Z�l[Kk�9��;���Ӹ���i9z����&){�v��Q�\�I��@e��Kw��c~�9�7X�n���֘�fZЗ�6Ե��ٮhv����cz"7�����Ē�˨0@���d�4�c�98^�Pj�����j_������)7�ɠ�E������hc屽�n�\��Z�{l���q��� �thV#;������x�
��R��8�= �)������(�*.RVZ�,�x�֡~��.�Q�h�M�z|�lR=�L>KF�8F�[Ӗ��'�)(- ��@ㄘe�ꐤ���gW�v���P� �#�͉.�#�X<�ME����������G��@�������BI���E8b���-=��uB:`���<&�8n�h��z�r<(�ڢ/��k�Ϻf�_�m���>o�1v2K����|�z6"�O��Lp�^|:���ax���6�p�,�h��QA������+iPF���]=�dYG�j�#�d�+�@߀��D(.p̊�]�ne1�g�!x�Q
�t��#�`#�,76w��Cd��"���p%�΢a84�~�Gl���Ć�Si�E���i�1x���h�md��c�YFԷ��.	�QM8�a<a=	W�̾�����{q֛�u�)/Rq%v���X%+G+�R�$.�)��Ń<F���52��(;̰�6Ȅh��	�o!�~�W��`���/�sܞp��M��uW��~��R@�3�� ���G�I���0z�$���L@�ɍi��1
��W������|.�Cڣ2B���fAov�1E�>��Z��kj�a|�����Gx��/�Td��(�QUL�dI��A|=z��x�FT�����q#p�ⳄC#���,R��3��S�Ʉ$�+ꀼ�LPAl�z1!���
�HHl<�iP���
�1��WBA4SaY�ȴ�@R�o�w�,�Y&����+)�@�Q�vE\�M|�٧�1����+�)+3�Y:��z7����{�Z�gm�A��@r��.�0��wsO�a�h3����6.K<W��$����NY�[3�k�
�C����g����8�dF81�r��
&.�#�B���E�'�g��=�Q�Ņ}k��J����@s�EL;����1M�.�oN�D�Z�ښ]�������b��[�ߑ�mu�@_���	�lB�����ؘ��C���l'��k��^�:��_TE�(ƌ����uۋ6��X�IDA�*�7W$n:��ed���$����}6��12V"����/�bב@���.0�
�W�7���"o;�7AqU���S�}඲W�[-*�VH�#Y=�/P!���js.NMګ�!-�� �Mر�9�?��>C�%B;�Y�{��y��H����
 (�d���4��X`��Z0n�y+�<�54��Y��C3��$m�!Gvf�Ɲ���ALWl�'�"Ty��������{��U'p2�����0r&��p!5���@%��"5�{'z�����K�~]�¤������)�Wc��6A��xy�{#�%�yG�˴�%�k(R�t�(̳	��� H�!Y��w��C#+�2���9���#|휢��f(R}QjO�MD��w�	:D�}0�3��k�6밸1F�
�c�o��.��/�ьކ@i����ܑZp\�IP����o��-��Os�KmY��<�&T͈�rTL�������E@pKB]eI��E�eE]O	�lU�G^z��^��i�B#t�$�!Wz��O++h@�;�\�����p8sx�o(�0��(�0ʌ��p.#tzc���;M�"�Wi+Vi���2V >K�2���$��܆d5r��r��%̋��Z��ӢG���Ɠ0��]��D��/~��J�����g:dF��=@8K6Z��y����k��e��',6Q}������㯮�0cӭӄ9�c��䄹U�!ּ3��Ɇ%6j���8���a������n�4ܝO&��!az�ݖ9�{8dF"G�5>6��B~s|hh)I����)G���^�&p�p=&�R�OC�k�2b1a�$۰VQa?�ܡ��`$aG��
b%8�g���ڥ{t��X%B�B�V�te�p���\j8εQ��i��$��:�.u�`�a�#,QGE(ڮ솰WO�y��<F��p�3- >:�rќ�&�]g>#�~�̐���t�N��b�>�G�EK�Ak�vN}။FŞz�>3���!N��zf[�Q9I/e�&xWЀ�mj��<�04H���%�m�E%�x���;�=�I���lbz@���Zs��!v�{��X���
9�H1k]�o��7�~j
g�yHP9���]�sw���a]5�$#Y�0�9�cn�����6n���ф1Y-�q��0,���s�d�6�6�˭��ޚ�'Q�5�i���/�w��������(��������`�g��gS�19&�V�	{k�|#��C&��J��@���1>:D=���#.��K��^��T�\�3����ޔ)t��z��M���;��ƬdP��H�`����j8R�Q3��n�3i��U�xi8���4�a
���+q^�jϱqys�%��8�zȶ�����a��$�g4���"C#=���-�����t0�ٹ�:�Ѥ���Ax�R�"I�ζq#�tv�eO��X���P5o����`z5!Y1�(:|�P�a�Q��N�G�`��~��m(�xtABJ��7�����Y�E�шO���y �8��p�M#��Y�텙��r`���I	�\�L�?Ci������ <�YB�I�O`<	W$I�cd�d�Y$�z��Z(~��vXA�!JE��� ��9�cXV����������Iĺz]��2�-lMp�N�8^(�H�*[7t<�7A�@AX��9��|�.�V� �a�bTd3�l������-�����
4�ĄԔC%U�� ��x]�C�ͳ��|���s�a.�P�Dw�-)�J����h|8��ܨ��dӲ�r�}����81��z(�&J�����ڤ���İ��vx��$�jMg���ȥk���Zi��g��1�������}���T2%�E�������1L���ɵhK�t��N"��:I��ȁX͒���)��ޕ{�
8)I�,y{;N�{&��5��w�y���^݄-��w��yK/G�A��e.8�ң�H���{D�O�rl��~���kc�!s�"�d�!����`s�(2
� ���	D��Gd�FI�	��*L �vg���EE܊Ƚu3���\.�tD�x����!�δ�эa�6�.�ei���$Dc�]`�0���4L9��Yyy83�:�˲pt��9*8 �U��0�Dw�ѵ�DZ�
��h�Q��'f	�E��J	~M�v��ւ�~��HTkΧ����`Y�� �K�tɼ���g%�3*8	�����~�H�=�rkՓ��C�@��I�M�OL�;H�j�1#��fӍAl�d7X�5dy�&�Nl�+�<aTq��r�[�u��Ck����M�$Q���M�Q�q`���bt��sI8}!(��`�3 �����acUUh.#����Ћ,졯F��é�(!�#�:�y�rK����<m5�q��/J/e��8�Y��ǥ^`!һU��2�s��tB�bC|�b!���I�qw�>ԥ��[�aG���)#e���7]�G�c�\TF�a>�]��9E���2#;'�(#�.��Eî/$~�}e���Dڤ�@���(M&�B��I�pfm�)9�j�!��G�9<FS;!�L�)�-مa_6��1?��̈́��k���Td�ѵ:`�3m[,y[	�x\�O����s(y��l�S;�^���yL1��ǃ�$���(�ge�6�vN�
]����[��C����;�Cc�ቄ���]J��#��-gR�Y%��a�d��1����T��=	���	ہ�:��x3�ق�V���@���q���F�a�E�6g�R$Aڟ܎;p1�����+q
��#ˬ��+?��s�-W��,��1J�M]?������@u�¶i:��^Fz��+��pN��k��A@J)�]���G��� �r� �b�	�l4O�|�t�&������x�k�����#2������� ا�%Qz4w�9Ԟ��PDUX�àռ����E-p��b!�`���(�e�R5:3�� T@�,8 �?�̩-^L�+�9����X��W�8��|Z�v���U�F��b��\�	ؙ7�FA�e1�4���7�P(� <��&35(d��N@�
%��kH����:
:�g�G����ld�N) ˹?i�F5�@%!���)�N����F�#��na�(�� ��~Y���i�|��"%N���}P>�����
''	�4d�9���a�TTE�)>�䍰�oFL�)��XŅU5��󳬦��ȫ��S��F/)�ppS���
��[!|7zdk�M/��0��*yH�w��8I8L�H��:�� ��FD�V��B١,�a2���2��#��������D?���#ֆ\F�ac�x ��y���4�%���A5�Ƒ+Ð]kr��5�'�f0���|��{�ۦ��^ҍ61p6�YSiI��$�rg-��4��c�q��-�8���sZ��b�Χe��n���8]�tЛ���B5�{���@">`:�8�ظg�~[�c�!ǘ���3���R��)���V��3 -WS��-�WLc�E93v_B/��Q;�p�����Dzij*��^�V�.�E/�4�{��Y�&�� ?���3�
�:v�u�p�2(P���*z�@0)�ϋH�ُ��t3�PnS-�rH�|��j>�%�K��3-�o""o�C�B�KN7��-�J��H��F���U�c�i��db���w���+Zr�^�!����gj�p�!or)��!$Wò{P��\nH�}QR�h�'MD��N/��|1 �|�NT��P�9�V�W�㮚N厀[�/�2ѐD܆���,�^h�|Ʈ������T'�XdӞ8/3�w	]_Q#C�5�:����'������z��ω��TM.x��b�+�|Kur�-���E���Q�1��s���ѷy�5��Ǭ��U^�����h�E.w�H��#v�G�`p�i�q;xE-=���kag��]��ا,J6Ð�� �}V��Y⬸e�g�����%Y�ż���:w	]��	ř��=�O��%�ϰ�h0�����,�6R�
*מ7I34��BJ>�|�{�'H{�!D)�����Yz��S�:!t��e�R�Ǽ�JW��p3c|�`ar,59�ϟ"R�or�`J�M%�>;�J|�������4�+Yᨙ��l�r��H��)�I�^nQ8�>IV��zK겖��\�V�4�����Ȉw�Xt)'�B�/0i�0�W-��V�46f<�ܷYnk�D� ӄ���ڔ�39$^K[��v�R�����0���T�p����Zq}Ӱ'B�2R����)�x��'����]��C�E� s!�H�[��)� �2"j�4/u���D�
����U)�c�\�+-�si�A���-�f+�yU�"�1t��o��rjb^=S�
ܳ��v֎�]Ô���٨�U��ir�O�vH���sp���KZP\��\t�v�[�Wܖ}�D]>1ؐ��?1қ���슬O5�L$�+m	�i$�)v��S��I~���4X�JE�H�%��);�h�%YX��><�E����I�5����-�ړu.k[�s��B��	RpK�@��\�X�9�-�K����Np���
�+�Q�YSV��e�4U�R���
�H�FL.���J�2�7���KS���m��RHy0L���%�����L�C��N�N��VX��:�nU�xΊG��BYG��٢�(�dl��0%�+��\�zߌ�p)Rp�T#0��u��`�MF#�� X��/Edх�eF<)�8�����	��ZJ��8!�Aɼ�2O�򗶹��8q�*�2�{2�1
��c:'��B���29wbwAI��aG�[�@7`>9 ��fXfyeR�����:�cr�Lۜj ��L�F�δ�-Dn�TgJ_'�a"����rQ^�
�͔�Ѿfn�aơ�k���\M��M'XBo���`�fT���+�,��!�<զ�������P5�?���R��&Oj���O���`uN�G�7Lŗ����l�ۢ^��KV�)�'�ņ ��󵐖�t�o�XrHx�j02&���	�T�/0_�J�Dj��N���	ڐb���jLqN�u(�^U
)M��R$���j���a�l��%����W�$�NW���ڠ�$}����������4D+�;�?Si߾1/q������0Jq�Ϥ_5�����=t�v�i"yg+.�8Rpn��\�AԒ��$��{r�a��P{a��o����a�K�:f?��A�䲙��:�ꐂ��y`��i�Tc���K`
�6#"c�9i�S/T
[�o���ձy��� !�w�e�~:��[���(�R�L�j����ͨ2�3��N��$��qτ��!�\nW��l$�[�؆��mY�mЄ�g�y*�tjY�g�i�߉�H�Re.�$�K��L1�T��m7a/%��k��	�fT��h*�4��x�'�����*�uA��*Z�#Ȥ`�ǹ����a�A!S�T�:��m�g~�y���%����a��%��L��'��Ռ��0��J��.E5�t���h�b���P$,�Q�Ohn�<!��j,���t2��[���zu�/p�ܘ�drŻA�^

�1)t%"�Zk]�o��F`o�)�e���7Z�Q�8�����ďsv�˃�:���aޯ#��y�i�[��*�2�&l����˞�b!�3t����_*p{����a��.ׇ�&q�l^�Z4V/Rnp�D���Q2�7t�9�<j�21n��g��	{ÕQIx@l����\t�d��M�W`��%TK�&��;�]��

{U�.&AX��yבj��[J��Hj��96�9O�­��3C~�8�	�P��M`�gdv�'�v�բ�|��c�a��ٟ�����9x�Y�;��Ƽ���T3�&�U�E�g� ����x~}7c���;U�6�!��^�;���{h��e#�t�Z�2��]=��-�f6:7p�����$�z8�BA\¬e	�N+"\H2`*n�	Z��2b���!%��-Ψ�F�ÙĽ�u�α�?Po:GG������#�B�8��5�����ϓ���:��휜t�ճ������V��nW�v���I���=<Qo^v����s�U�'찳����� �[���xy�<����Um�:�����N���zg���I�:�0�z�s���Չ�|p��|������P����ã��1L `�����������m�KC=�'jwV�N�&m5t����m��?;�vvw`��Y��;'�0�]�g��j�s�::<8�o! �?�9������ǫ��0��{�Ys Ǆ�U��B����67����ϻ[';��l	�����~� Р�����[0�����{�zg���{��9�]�:8:B(��F�Z\n�:j�)�>bP�5�ǫ�]܉�����"�(K~��Q�6�����LO� �b�hP��"���bj�`{�9� �������ǁ�+��e;�pc��Dvh>0�%<���^�E���3�G������������� ��U�ǰV<Z�@���1B@��s^�E@�׈c�g�dW��e�T�ǈ��v礣h���.�>���F��lm�:���-�������}>\/]��@_2��睝�WGE�Ñ`$!�s�������sj������%ų.4�l�ޡ�(��$wdO`uA������-�Ob<.%��̫�=��G"��{S�#m�~,��R,v��+\YX⛅
O)]�C�	�K6�ΰ���,�
��Rtv,����	��-�鍄<@��Y��0�
'���2z|���W�L��z�A6�������R���G���˺V� ^�9�y�����w�:�E�u�C˿G��ªL w<H����Ub� ON��D�qNy�9p�T�/���[��H>�F�7$��	�X<���Y��6�4��I���U�I����4�k`Pu(�@+���)#����C�� ��36�Ǻ1HT�mAADN�=�ג{/b$�5өj�%&HB�%�[W#��fd�*�bQ���:�/��9����JO٢l*��n'��5ޜ���)�H@�eq4@Jh�����T�i)ku�����tOa�����<ת�6���4�{�O�>(.���(.�����/$�g���jLɴ`�(8�h�O7��5�V��u�����^�I:���d��UiQ��r-�=6y�XA�`i�%V�vU��`s�	^�
^�k�a��]�&�Q�p��D6��u�K]9���KV�1�!R����f�}yy�:Of�4;o�p��S�PC�0��-m�ED�v�������h����F�[!�#W`m.���z�DY�\cKCS9��J���M���+-����0��6r�S�`/�����dܧ7��%<��̴��g���N��߻��c:S9N5����~y�e��eDˣ�ÆI�z��&)�X������G���j��Fr*�
������ӯջ��~A�9�N�$�Ƕ��z�`LG��,�^�X���W;���<�@���A�@`�8K��LܤL�bM1ԒF��^�W� �j�
�~�/��Ӆ�-~n��^X�+�it�2^ͺ�MYw��b��xn|���ᗝ�g%YB�D�6�_ކK,��l9\@i�ɇ#��ba@$����a�.��"wr%�b�X��3�g��$َ��R^'�Q�&�Y�3AC6�q��U43���#��=��ѥ�E���|�[ǭ���bX6Ϻ�QBQد��`Iʸ��aJ���ʣ�c����}9�j�67G�Qk8��t~����O{�ng{�����kkk�<P�﷏ҿk�7�<�x��[�~��ƃG~��Z[�����o�����3C�S��ha;h6,���̿�$?w���m|�-
N��>�`HD��[���n�������?�QKy��L���%	U�P?�#I5������ != �=�7��B�Ĵd@ǳ��o�@� j�ق1���9�ß�ֵ�py8��ζ7R�2b�` t���Og�u�zÕ�pL�6�}���\���I�ɜ�ӧ)�`5�l1M3�(�[��3t�SMJ
UB���+��6n�m����㽆:�l5�ы����EH���l0���81�@��2
��Ӎ�E ���构�K��O3	Ƽw/��aR�|x�lKC������'Y��%�!�!b��"n�u	R`�У'4K�i�'��Ի/���(������B����uE,�S�!7�;-Q�u^5t�����X�����z�����f�s�N{����\��(Ga>9��Ŕ���ѧ1�>�v�>�fѴ7��]���R�����pJw2�M
�e�6@<:}�l2�`��.Kf�N�i�v��Wx�-�A�ɑ�߲�`�k/uw}�E��y�D���������������i��G?��lm��O��˃��0�X[�����\���`s�����7pt����a����i�Zk]
õ����@mR "��rV٘��u�����ίr~N�<��Ë�g������g�����Bx
zĦ��>�x�t��96߽<�s>��چ�����P>^8ВY4��:��5�U���(5�G�e�.惓w��0����ZaO]h��j[S���CGD'�Ω�E�U�C-���L��7>�|�l-�>��Bp-����~4ѻ��������!�P5�����Y����r�h������� -�#e��y�����4:oqHu�@��e�� �xg���HM��OFI�?���M��j��ڲ+����޻�$���Z>h̃��c�D��͊a͗KoyuZ�Za��H����(�S_:����O����9��M՞�'%7JϑI�W8SB��ҭ w�L���c�ǿ���߸����g��	a��3�Ҝ�������л_��r�{jU�c�*�ᇛ��	͛���D;� �7غ�XE7�Q)߁��RU�D��o�D�� }��c/x&Z�`��R¸@.R��ĸ�Q�`�a�����\t��������Ï�G�[k�5-����!���م�b<݀�p4��=^�:,�z�.��T)W�\�e���Iq�����8�/�Xo�5]Է{�u�up�d�69qۀ�K�͛Ȳ�����.��	gLC��B��ԟ5������^o��7��ã��W['s�_W�(�[��R@������Fk�u��v����8�o�;�;��2�<k�:a������Zk��6B:�:�9<9}��e̛OC����V���m���,4c�9�١O>�X#���vW�Zv�z���'��6U���=��x3�t�7�}�h�  q��H,ܤ#`�4<�,E���c���:�UǓ��Ϗ�:��>��=9u!>]���
yRF
��ѩF����z�m�����=�J�O�Oؘ�N��Kr��(oc�u��q%��m��=�G�r>,�}���y���_��v ��`y�O��:���o������w?i��x
����Jϳ�U��=��O��S d�{���H���l�qƗ��>��-�][�^�,��@�
�C�����`i��$>�Z-�`!&E,����c*L}�y�;N�g���Y��/$�l�px�
��~��*����� �d�0�O���𐽘 �S��>��ɛ��7%�!(:T��|��U���XBpGm��;�%����s����j+t��H����1��JQ�� ��r�n�n+�ZU-��h$A2Qo��Z����X����As��9�������Cx�Ή���=�������M��݃��.}s���A<jZ�d��C�||:���׬��?�0'�wm��#}��w�J�zK�{M��jg�s�J���':P�;�F)�[��v�t�_ʿm�ҿ��z����m�P8�-���Ȉ��g�vϘW�0��*�\��^�@���H0�i����m��擮��^�U*�l6P59<K�s}�-Y֝Q��|��1�^w��0�F�S�gWƮqO���؅�p���\[��0f<�����JP�q�V4</�y���R�bw�-�Wak���;NU�X���Kp���,���l�o̙* .,\#{��٘��n��<t�v��o�&?c�gqsׄ����ӹge�l��x�E���܆by�B��;��P�/��=�9	4'�{fK�.�����g�
??��I���a���~.~�-�v!�D��%��I� �ؽd�[(�	��z+�]hl�������-Z��]��˧���e�B�w�R�)�7Hs������9����ߏ�w����E6���O�)+vU� N���0gS6s��k�A]6�:��Lޞ��Ps��V?���&TJ��eQ���vS[:��h�b����t8�*�/���X�	c	O-�`�s�W\�=t����_��q��t���m-��wN�qlΤ��u1��g`��1��:*n�h4Q�ú�\��Mc�f�S�)>�,�V�P�M��M����UZ[v婵���[}�$�؏�2T���y�\1͟�)l;�F�/dȌ����j6�������׏^���ipK�aFg�9�7��}�:�A��p���=%"��N��zAOĜ����k͌��C8d�<��>���܆�쮒�M?�7��]'rC����Y���Yt�U��L�L��qb��U>)��C����u�cQ-�r�А
C�v7�e�Wr�ۙ���I.��n��jI��*O�mx�%W�E��ˤ"�S����3$w;�c�����"��9V85�^1�&�eaX������Β&O7�w�������,�Y�/^�w�����9� c�9�t���R�c��tB�寺�ʽ��j�V������W�(��10���+o��
Y�g�3�b�����	�7]���͗�Nf�� ���;�߰zPl�5���<h(�K��/EU��ԭ�K�§*������sB~D��L�����O�q��dzns��A���p��A���JG0��W	���f�J>���a�u��P�"�\w�����B�?��LTu��{^-7>���.G��)+�lG�T�����+�*qa��X1~���S����^gg�b��6~<�Vf0��g-�?o�eB2UM=��*���Q�`|<d:�+P���S�=�KϨA�ة�4��x_UM��x�gm�+Y������%wD���f#����*(F�?�0}O^	O��&�ȣʬT��t�j��gp;r������f���:c�D���ݝ��n�ʕ�:߁2Of`�|�yƀ�l�>�٭�i���FU���@W>h9����ߚ�'c��H����������,B,o45�ó�6��������U��-���%@��o09Ū�����xR�D�U�Uw�)��\����f�bk�g#�8N���6ܺ�/gKU����p����#�(����K�����R�w���I�a�O�x��py��|6��w���hs��O�N�����ΊX��H�UJ<�s
m�ѭ�@Fa�e��V�Aq�'!+#A�ex�#;��NS���ın)~o($���j]�T��Q�K�r�U[D��wt�}�B� �]�ڧ�.)"�Ҍ!@�����sP@�w7�)��X}����h�I�[0�w�gG� ��Q?��A{=�⡆c�	�lΎ ��%w,ȹ�V�O������"N�B���I��<�ݹ�g��[p[��d��<���u���9�J�B?�%\؋�p�Gi����,_B�oJ�K^�2��r:���w���'/�����>��� ec��ɰ����=7� 	��Q%�6j����¿��DrS�L���1����о� J�M}��:jq��o����?��h���΂�홞�E񔼖����u���/"]�ۍ�p�������2���~����'/�,ܦY+}��gh��H�e1�xO��(����^m@=��^�������#��Oi���9U]8;�
�ؑ*�S�1���)��* �o�2K�v>�sk��)x��ϣ�$�SHo�ZGj�T��p|O��=��ӭ�

*c)�кɸ���Şn�EL�a�C�Q$���6��7{H��%M��P�6�C�4/ns}�b ����&Ŀ>����%���?���L���#�D�Lt�`��������S�gC�ą�� p����O��b�Hap��	� �8X���V�<�n�����RB;��Db'1rf�� �Hg�B��9fXIP'�P��;�����Н8D�k���)��5���f�*�n%ϸ�^�������W�0��V�N������֭6�����:��#{�IuUI�Q��������}t�%d$�FUô�i�1���b�Y��R		�tWΌGdEF�"3#2�RC�����a�1�p�֘��
+��^�J���o��^>�N�<z6�c;2�q�WXܟZ�1}.��[��A�Wl�"i\���b &��n�t�V�j:Ƴ��V�A[�M/�n��y.�gA���%N��_٪���f�?���J���%����z��g��ǔ�1�  �%�ܫ�r��)����D���4�o!^2�a�s�N�q���9�=����G�ꟙQǂ��R��� ��_G�u�ް�M��lHu�1���6M�m�R�zS���W�6k?F5ٰK���6�궥�0َ�9�옪��:m�b��֌:��7%�0�z��h��6�uE�5U3�jiuY���X:�K��*���&0$��h���٦%��[�M��M��J��u]Q���-���Mm]R-ɶ����tߖݦ�a�\#W�$Ų]Ŗ��kX�TM���J��MK������F/[��r,C��B�Ł(�nC�M
�7$[5M83��q0M��f(T-����M�h��FSu\����5T@�VtRS5�F�Y�4j�nY�e]�)5LIwd��6�z��e-�RdY1:4V�a�M �4a��ͦFUYk��b�=�e�e��jz�YuSn�iY��غ"�R�65&�+�$�63:c
��[Ium[r-[�USu*�VÔ4�nXRà�,9�m���DK<ZW���d7lɁ���b��:̌\7$j�*��H+�t*��ȍ��l�̵n�0�zC��M�)K��89Xۿ�P\��ܑ�f�ݖ
gd���uZ�lKw�:���0d葥����l�J�ʹ�fM ��]KS���5a's�� X�M��H5�j�p%��̽`��4IW%�	���r-���&��1�.������;���ɱal4�6P U�o�����Wk.cf�3����$;Mh_S��$�G�
n���K�ՀE��M�B��j� sQRΒ&�",l��Ȱ\���u֓�Tiݩ���.3���nhU�L�YIQ��4`��Râ�ل�$92�=����PJ�Qjʉ�]4���fp�4d *�CtK��Qwh&��������c���=�AKU[7���\�\���,����������8�n�?'�6�I%؋��u��� �G��7`������+��{������Лk�ĸp�[TSL��ԭyS�v�E^"����]6����R�kV�$X>X�m�u	6�t��dH�۠e�ZWTl-B�H��T8
\ �#�)��6�nbY�
2]�4����b�uF�T$ۅ��pĸ�ք��0L;cJ��j���85�p���i��*�*VCR$89u`]t�1`�J���i9�=
h�6a7w$M���4��/S��8�r�{���\as�h ei�մ���4˅v6Ԧm���5a�@���.��'�G������ld(�ԆmkF�)�9g@�a�77o<�) ǵ��.�����7�H�Դἳ� RmH�m��v��lǤ@�&��$َ�0��	�^��vp�����{��-�0h0�	d{�Ұ�U`K�Y����lE��	��J�	t!թ!�6a� K@rM�.�+�a7��dtssw�����	�>]�������c���\�_D�a���y<��X �k��s�_�놢���P���H���sf����4~�����sZ�����nʷ0�^i}��jbO #������+(�1i}����}J��&O!o�,�ɴ��$��~pM'�z|�F��*O��L���"���;�#r�n[�K������U��?�p�VJ�:� .�b��m~o�������� ��AX�Z<�� �v4�`lI��Y����v؃36�Q0f���VףAb͗o �y0���@:g���r�?�6�=گ�U��+��w��O�P���Ƚ�	�{b��_��Ҝ�!��ۯ�WI卭D��2.g��5�@&Q�X�g>��F��>�����3��t���y/��B��#����t't1>�^$:�.�<���]|�� N	�U^�I�]h���AF�v��^���sa�X�-�������ۧ���w{�n��9�Q.m��8��2���ފC{�f��,���ᜱ8p���M������!2D��I�[#;��Տ��L
MK�W�o�X@�h�!`<��	�"�q�az��"j���PcY�o֦G��<Lǃ�κ6o�l�2u�}��D�7�Tć���1��-zR|��xl�5Y��U�[4����[¨�Օ���]�?<���̕��q3�/˚,%�����Z�����P���I OT�'<m �R�M�V0�������<��/�"�=����$BÉ��Q���u���}\��B�XMs���[p�X޾2\�W�������q�=�GZyù�9��퍏�~<k}���߸k������lD��sֆ�	K�5�b���M� `��}I� �f�	_���oe�ʠ��Y �/�R`�ra��|dhu�@zV��L����u \G[P���=dGlh��q�`~��3Bl�Yv@�L�]�˂��wOo,X|e��!)���̂m��T{:�dL-*��5�,yC�������J�2^����}�Vf������u{����C N����vh�8c��Bg$���M3����~-�������~֋+�8RjC U.9ވ�B��i�����qe�⟙�tH*6ɪ�凚C/j��`�{M�*��"�?��ì��Z������΋Z-�{�����N��=a�/������K�R�33��X[�||E*�IH�1'=�})n�8l��/�lC���8�E*�"6ckg�7���>�^e
�h�ʹ�)�e�/Wf�q0�.�!��%���I�(����h�4=��r�Q`9>.��L��Y��d�7����<��̞. Ys�x�	�Y)����~.�
��s��[� 6^ ܌7��� b�"q��(�P���BAn

7�Y(��f!�����Ԉ9>4"��T"�H3��l���+�`[��` ?�_��)ۣv�2�3�����M?�wc��[�cl\��S�t/
f�F�"���:��:��e����݉Z$�M|��C��h2�u�1�Ď�8�#�Ĉ/��"�(kPmo|MT�g{o�6���7��E�����n{� �9 �3�6ʇ���	e�g^����7aL�,�g����8��1\4�E�`<�w�O�F��x:���$3����DV�n^�5n4���+�̣��@S�C �r�ſ�ĞZ@q��H3?Ғe�O����m����Y3�j{̲07D����y��y'�E�ko\�S�`��
�c��=V�W�]m�?TYU��_�?tU����u����q�S���k`�d�����U��*��.���:x���ǻ>#�9w2���<C�| �'�`�����	�e�d+�2)��z�:��+jF�[1P����>=g�܆k��G�M\�"�������L0S2;q��n���(Ws�����[CL�b3�,)��I����n������;)yq�6�-���[�V�	�?�(�oX��:�Ő�D����].��%������5d~����|A�� xlimŲ�z$�Ҋ��oG���=|��w��1|��ϔl���g]���u�����Xv�EAG>��-Iz1��H/=R��׿j�Z1��Hi�8S��_7��-iƍ��q��ה��_O��j�u,���%��̿�����Z��Q4J$�'�8��!n9�������p������>*��j�Yr�������6SW�c)�<Ɔ�{s�JG['?�_࿭,�U5V�3�[\d�pL1����U3�_`2�9owY��.�6)������CWV]�"��_����k.���xd��ڔ[��Wd9���s�h.��^F<�7��_⠗�s�})��>�V[��򟬫��7�,����hP�]��z���%-�i�~u,��4���&I�
��kJ+��~��=[�E�����=�����;��������������gK< >[��Y�	��|'��!�h�`@G�	�r���g���g��{6�9��L|�{������!%�8"� j�!
8/���[�I��85.GU�ָq���� ��`g�h��U����)�V��b\`6f/�r�;'[��p�^�o&/��_S0�е�f�Raxc8n�C����:���s(��vf�x�W6�i3U\s���OQ>��d�Jņ�(�����*��-G����0*i]�k�,�,�E�k~8����f�A�}���#����F#�q&B�q��p��-A�r��(�� ̋��v����{#�l�I�7 H�!7�;��P���ŰiQ��C��'�7��C���x��B���cu��q����ޘ�W���[�{Ա��7�R��א��B�wM�������Y]O[�u�4��m�	C�	q���ӧ� h�O�w�� =a��q /)�(s�N]:�>�Z���}��cN\rn�F����9�b�cH��$���#*d�����V�����6�yM}��5I�l���G��� �hB�#��r�"�T�f�<,�$�A'� �J�H�`�؀��Cb�)w�6L.i? ��+��)P�	�^�9����C����sJ�{�Y@}�w2��<Sj����B�G�h�7��1.�s��g%����� 6��'�#:�Q��8/3�ƙǯ�n��gT�%���&=szv5Q]SA~h��t:?n��������;Ӿc����7��{"�O���o�_{rc|^;;����M�������ݳ������v/��i�������Q�k�������گ�&����?+٣�@�~꯰3��[ʜ?T2#��ư���|+(Ӵ2�@%0�;ϰ2���l�M{g����
�F���i�K�AG/��V�l"O�І���I-�{��.}lq����~��(����k8�쳠߃�b(�����av�i4SOt�����{5������������/�����_�k�ב�����=;��8��ÿ����ȿ����#���o\�=:�b_5_�~o���:?և�>���o�X���4�g?��GnΚ_�]��i
av+��/�wTL`O�!��V�Usn����ȇ@_z��}��3����Ct�.�*�=��\�J�<��W���=�s=��^�����y��2�{5���!ï7���s �s���O^��ȱ�6��"���d>��b�f�kL�Mǻ�'��Cq�h+�a�����O�?ȕڒ�Uǂ�]U$��W�����YO
�?Qk���2(���eP�R{�WAX����ظ§��(�\̹��a�"�^%o'ӑ��3�,g�e��z�� E�D�ԍ���SXo�ENy!�8�Th���6�x�~�!�%|����)#a6��7 .�X��?�C�I�ܛL�y@z�Q#Q�ϘdǨ���9��Y|)v1X%�Llb�����&�&����\��\\a���5�ƌ!�p��R�&�уb������Y�}T���Ru���@J���5o���3 ���.g|����L� ��T��\��
��x��8����k����C�9r��� ���W��ыs�gf!�iz�E�������nE���s$����I&�x���.I�sW��"�u�����a�;�oN>l�f���� �[�.ڨ͔�b�*(������r�޼��s��9P'�wRP��S�����Kv�WNh��o��`r*���L���-b����RD�U\��_:'�ǻ�$������Y?f�1T�B������.G���"�2���G���QEFn3M���Ux���Uy�Z�3����d��p۴t��{ԱH�רד���������T�|��欮�-􅒘�?��?�lM}�}6A�X�^�p�?��~������L��C>s"�?�x�I�|Sɝ�iqt���ׇ	�|d�� ��+2�́v�VCAd�dH��!�J���H�t��lXBN�-W��GT�F�dl�I
K����c9!��#�C�h�X�Y	W��ɱ�`#n��ճ#¾��v��#�cjh�P�:��4T���%3/�%�\K��n9N�*s'���QfJ�s�P���,�M=�Ѥ�B[�jp�����u���a�.��4��^�u3��o�ɬ��=�:��}A'�џq��X�ND)�gg����������WT5���T����z����T��� ���5��DvC�'d��ڿ�\��o�<Gp*�����.EZ�B���"�)y�C��\"͞�j�/�.�AuC;�{] .���e��O��_����_G*��u������� ����"�	5@��4�+�����5)�a�\��K<|���G���c���� 93Q%[#8~xY�8�!Tq	�)����iP\ѭ����z�����v�GMy��e��;#�p�nl� �G*��`�A�Ǆ��P��H���L�zMbW5Q˓������4���C슠�FwFy�]�y��e������\��K����� \����SdM.��גf�_V�B���8]�8W�!.��W�����0�O��o-�����O7����~%�%�%�9bw��o~���b��s����.w���=���o/q��V>�O-���D��%�0��u�S��ٝЛ6�+,�y�m�%��T6��]��B��¨I�n�YXZeA<�=�Ņ�1�͊K	q���N.�ċ�;�����T(���_D������އ?���e iޡrΓ��}��|�x�B�J.j�F�Jj�3GB�q��M�=�Pa5�ye���(�L��.����)H��\����eߠ� �/�����":c���o�\�||�(߆�j"r�pG�)���ً�w��G��"Nv�C�����c������[���'��h ��q�|s����F���XIZ������!���za���T��=���?��_��$q6uK�9��ៃ�A�������x?���0r8ML���G����qxݣ�N������(�ճ�6/~�<ú�ţ���y������]��C/j�	��!� IűIy��Y��*�2d���!�K"K���9����*A�m�Z����GI���o0?~����� ٧��Y�<��A���^�B	�w�	�Q�;��1ҙ���&}�� �/]Ԃ]�<��(_7�v8n��5�VW��?����r�����
8�{����2�~r:b�_P��0'L��	��,�<܏RD-�5��� ��bZ1E�vv���9Ŷ�ر�_^�$3	Ĝ]%��a��qc�Β�\渞W�������2�H��W�0OO���5oz������c�9�<��q*��
�������PH:켫��VQǂ�U5���Gֈ$�V���%�JN�^��܉���`x�r:�p@���y>{'���վƧJgoa����T%-s�2��;��yGv�����+}D/q�7��BDf��"r�Ur��wٹ�RJUC�j�/7v�m�����&)È��./W~!�iy3�Am*�5^̯�����JL&�D���ek(� ǀHI�˯�¾?���T� ����g���$���Lq�.�G{Q�rZ&+�J����	�-㐛������`|�?��y' ��Q<�	x2�Yh�	y�,t8�I��d|r���%���h1�R����hc�9l��9/y���a0ja6S�<E�	/���M��RD�L��Mq��ŕ�ϢRɨ�g�i��,0J'�}�~iV�S��SS֥��ʅ��S���.������,X�6���|:��J.��g��T�E�O�U��+�?T�S���?��.�?��?d����.�REv�A�?�!�Vx�gU/�u�B�[��7g]�!��>�V�p�#�%:���=�D�;]}P�oro�������3i�^Ɛ�B�>&��#p/�/��|)]��ؗ(��J�ۙ�~�5(j��s�d�n#�\*%�nkR��8����A0���w��*� zp&��8gҲ�[VtK��ې��vfn��H7����P�u,������d0��n��:Ra�������� 7���Tc�ߩ0?�)�k:��h���˻X�9�J<k;�����
��n�I��8笢W�O�̚O4��AbM�d�F~�+�9]8K�jg/\�΍1���i���P2X*?���t��x�9���`�Y>�A	�a��G{Z��4��g}���8���}o�2m���q��}��� �0�aP��@Ӿd��дhm�nqq����SV�}nL�Zyj�
� ��ˬl�3:��$�)e��k��p�;������ař�>c��+�5R=R'P+P}0��8g@'1�#��pi�v�U~	�}�a��ǲ\U�M�ʲ����\ժI�Xf�//�����ĴA�(�Q���� �x�q�Np������[���=�6��K8�O g�@�XM5�"d����9��7_ـ�U�I[T��#�P<�+!��b**,r��i��O�� �Q�OIc�?C*�u�B���?=}	0��FI�or^!��q5==9����>����ͧ����O�0�t�x�9@��5l�Ɯ��3?dS˞��!�i@��	�u�f�M��#l������a�nQYta�N�[�^��K~=�>�p�{�w9b���Gn%*�i�z�,n����X�b#�(h��6N��o��޸SFN$���]zx�L���Tے\޼c�-n���{�@�Rb�@��@���Z���}sЪt���؟�/��9��-ms4��-u3*�l�~sx��fǎ�c<:��bt��,�N��O��!��9�B�MccĄ��ڧ�^pVy���>ƅ?��Dn��[SўL }=$����
�rG[�j�8���VEN5��7*N�Z���م�X7�Q�Rg�[Vg73F�"��Pҭm�Q��:�q?\��Pg��)���2����9��t�G22�I�_G�I*��H�w&�V�.(�N�����8J�|zs��i<Hvg�X6�po�����	;B+�v藐s�T耢(��D���<9� ��BWB`�y߁�}��}���p�� �͏��g��E�@m�x���u��F���hLҽ��D�v����̷����-�5_W_W����ot�w�A���&�	��������Ԙ���ձ�����V@2���K]�
�ﵤ�
<x�t�rn�`y=���h� )��;*�"�&��3�:|P�{����9��
�bj�����G&�Y�x�Ɵ����Vń���7{#���}�ܺ��=��wHi{�+`G��(g��z���|p��>�kx�OWN�m#�h~�j�һg����q�l���C�u?w�uv/`ٜ�Oa���% V(~���1��Ug�Wq'���x` �ި�X5����}>.97�?�h��p�����
�X��)�=���uI�O7�B�s-���
����f�����o�hłc����1?�S�\9����:��r]<�%�揽�)?�=�q����[�����^�ZO*����/����*�����3$Q�6�U��,-z��u�������r��u-i�Q�a< =Q@�^�`u���_x�/q�/y�g�m� >{y3琟=�o��;�W;/���ڇ5w����q�����\�vc2�FJ����΀��$���e� ��$���8|��1��
C`g�3R	ț��}R�J�'@�T�3����"�7�������c�a��#{��i��DiS�T7�M}�~���;�>�}�{p����*�Q�8���F�e�/d�q�n3`�}�秄��hz���Y�>Գ�:�����h,��\/�����-�,���¶"S�Y�̐��<�f�=#f@2�l�'�Y��*�r^rU�rY�#`6�{�λ0:�0�b�
�1��A����X%�Hqd7pWI:և�M�Is̰R��5�F�㙦��7��K��WU��|�5ȴQ7Io��)
�����XX�$��ȅ1��TK�S����˃%�R����{<;����ڠo��n��_�T��c�yɜ
r�'Ce����ޡ� M����UӁ�.���9�������b��������`���ލ-���ɧ��*mc�(���\U�9
������ʝ��܀N����[��*�\�i���&AKhF��+Joq�_�,�xh�h�v�P����#���ǘN�(�{�Xd͐�D����աv[��T3r̉s8�Ӡ��w��4?��;�x��G�s��|b#��v{8}f/�c��wKi����vm���:}��Oӕ�������Q�ZOz��xΙ#�U�<�+p���K��*{�7�xڬ���U�򝌥d_B� �Î�'�ف�NbA0�G�x����XAc+1sl�����wv�Ͱ��EwI��)�zW�ٌ{C��H����Pqh ��9�C���My��dDQOݜ\A�`ÇE�d���h�yͨ��T�Ѕ����*�4�a�u�i���<9�i��	ɨ~����ڼ0�V�P3Or|ؤ����w��}�99|�������H*�������g$�xx������c#Y�G��zB�ۙ�H�ђ�q�2WY�鎈0��}#B�A1�����d�(�۰w@��f|�����cl�Sd�F�i�g���SK������(귀5��]�����<�ό�"��A���3��愊�߼���j�^#�m����������e���2�hn<A��ʶ�yu�^�$÷{�}>�7�Cc9�P�����=�o� /_��g��6#�Wzo�9�l+�M�����F�zsS��7��������$����l�l0����w=�݃�{��J���.L���{-W%���oowv���?�:�ۧ�{'�tO�`_��t��mu���7���z?j��`e��Ez��'��P�gi��7��������Ջ����P��
���[��}����e'�m!�i���^3�HT)���q�Ǆ�ӝ�b�ϽI%4���b�+|;r��!V��6>����a�zF�%�j��x��߂�y��]��a��� ��:n�7S�򆇪%G���q�Ϗg���5�[&��'�A��Y�&"��������x +@F������[�_���oe�ʠ��Y�$��س\X`0�'���49�"3���|QG �k��H>��zȎ��8�����fY	f��><x���x�\��{����xz㋅���_ː��`�g�t8� ��6j��cz�����?�C�0�a�����n�wY��Ŕ^�|��ru��`?+��Si�� )w�gKX/��M��]:Ew?%���_2�������!�W�X�E�]�a��5��K��r��F����a;�8�|؈��" ai'_�kY����*�`ە���4�)(\]�P�P1X�,�S�V�s��5#@�7C���ö�26#�gӚ;�Y�~.h
H�x;�G�7no�h�eK2���x.�Q���Y�������,��mؒ��AVno��<s@~g'wTmo��T���b{o�6��䣱���`L�,�g�a�!8�/���褶2"��$�o"��&�>/�b1]��B�3Iqz�����:�!�^�ſ�Y:#}��q�On�i�CNǜ,�1QL�И��Ɛ�FU���ȩ4�����'3�ۅ�}<�<�ӳ)��bK���q���á9������N��26�?�y����<�G^����ƗƁ�_�3)G�7ugcUw̙��������cZt��3���R���#�G�
VB漝U|g�������zW�P�ح/�}S���4Vv�H�_�hj��U�����T��>�����������o��W�(����u��_/u��x�g�<'9�o���~B=�K�?9)���'[��I3�_`Z��c���)jF��C.��u����8;���*�I+u�2�?(����#r�'f�Bf'���\�8����c�%�V'-�b�Eà=��$�{��Ngw�Dv�����H	���>����6�-���[�V�	ާ��w�4���ݝ�7[��'�u��!k��'3���T��]K*���'�ʞ��7�(_P+,�[Z[���I��b����x�V3�.�����D%^��E��u����������ZR����3d�|0w�sK0^ڑM��x�����%�W/�1>��]zx�/ys��~_�� �_����_��~G0sq<߽��F��y�/��><�=��tcS�v�-8�>�}v��j�*u�R+�=¤o���x��� ��i�%z��[�g���h:K�P���s.���e��@Ќ����V1c%u,������K]B�/C2���kI�#}��٫��zx�5;�%���/���7"�W�K�,�Xxt^UsKL�c�a��R�&��Mz%�n�8��Y�a����8陣�7H�S�=j�����m�<[<S�=��FHtc>���s1�Ϸ��؛_��T�"�HE*R��T�"�HE*R��T�"�HE*R��T�"�HE*R��T�"�HO4�H�> � 