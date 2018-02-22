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
# ---------------------------------------------------------------------------
# Rev History:
# 11.10.2016   soe  Initial version
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
CONFIG_FILES="oudtab oudenv.conf oud._DEFAULT_.conf ${OUD_CORE_CONFIG}"

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
� ƎZ �klcI�&���v�����|�׷㯆R��^�׌f�;l�ݣ�,J�3��˽$��;M�˽�RjM�������y��@'����'	� Y8p� ��	l  �'���ު� )���gxgZ$�:u��ԩS�N��fv꒟\.���L��
����'H~����[Y^�/�\>��R�"˗M>}��l ű�p vx8�=�����<u��߬A�ܾ�qڗP���/,��i��y�`��)��ZB�7�����"�5���&��=�mf��FfƎv�6������r����8������M��G��^ϲ]2w�\��<UMo�n8��9�N
,����򰣹n��Z�zl�_�vG3�c'z[����e���R�m[6Yu�C�$;z��d�ҝy�д�E�>vydVrW������w���-�y��5Ys��e |�@��#�1,3"^0�ݾݳ�a�<C���ĵHK���N�f6t�jH4�غ�7I�j����;���6���p���f���w�&9�l��G�m��S�s�V�%���i(^Q��[�4D�vݞ��Ͷ �_��ɲsP���c�Vh�	p�e����\>�� S��W! Q�0��:�H��&_����*`J�/A
a3���-�X��)P��%�4Y�B����a���_���sP��������ř�ү�t
��m���Xv+uJ	��M����HRte#��Ki���\�B�G�����vz3Y�)��V������A%EF|��w�zG'�E���z:�}�Z)��6����Q�!H�8���{�����V�83�n��!3�����n���WY������ʺ�^�&>�؄�g^* �Y5{ff&�����k�TJ��^1E�xҠ���f^J����G��!�7��<�d�n*�U��,��{�j�<��ek0 3�v�����W�%e��xO2t�f��"��Ѝw�r�ȁ����y�2([ˆ��h'`̥#;y\H��&��-�ER�v�+x!��O��#�����m�����=�.��@�h�������.��c�n> �G�EBH���p2���Ѕ�~�d?��1Rb��Q�m��N?���*�bH����GȾk�aˆ�7p� [�	��c�E6�}H!=�DeIL�P��)0	�)9*ߦբ�	&���;Q:�28�<���)I�\�#�>���L�j�wt�,��?�7\7�pJ_��k\@�E���~h$O�c��"��c,&�\�K�nﲆ:m����KZύ�݃}�$�w��F1!}@�՞�4[���"u>��m ���)�SP��1 3��L4b������w�����I
~��<!�[����.L,MPKH�gw�H���4kw>Y���v�����C)��^|VsHf:�@�s�������J� w�{ �L��5���r�i�	W��A�
ua,-�Ѷާ	� Q��ru��5i<z9�q5�CJ|u�ơ��:n㸧Tc����֦�q֚�d��.����)�RMõmZ��Mc�{������~4��7�e�gOD�*E$(�) ��@�����p/A96�E(O���HΣ8��s�ޜ��fڐ�,����+PM�ZE�!�aI�"Z��T��V��N�Tap�鴆�a٨w轌\Da�"b2�S������◵�6 ���oZ.�T�3���/�?%P��+�oV<�v�T44��Ri6Z������iF�G�>��0��V�Ӥ\��h��Ki�3��XZ�<�y���G6#���-�oՂپ��P1�)�_��b��BHN�jj���a�i��}�D��ۄV���*��9�5IE�ĺ8��8T�
k�2G��[��v�*�F��ԙH����y�>@���|�xCBa���ڞԆ8�UQ� ���Hnw4qČ�l {~eޡuQ�&|�E�D��V*����X3M�8����N�R��χ���i���1�^����4$�U����uj��
5�^V_9��
�½lS?ʚ�N������~S�k���y&?���p�ߒ��um�i��n�$�V���|RC�L�/��v;�cYaFn!���1��$:&H�caD��>I
�J�1�JU�'"XP�8"V5��n!�wB��P�G>�	��%�^��wI�x-����AiX�&6
s���̐��C�������@�=��
���(�:���\�DC#|�@�1��%D�<�J���WR�d���a���2��{�M�$%�.����I�G�v��Jk�U8����q�XX���Ҍ��%�wm�GRJŖr)\�'�\jA�K6]�P�A�����rs�N}��Lj��6yR�]�N�㭥�V�V�߳-~8��Y��-��l`�al=�s����V^�r��f��-���)��|�,�9i28����;c�l�Ȍ�l��M�P�C���{1_
�dkϓ�����zi7BTU�U����sQ���+O`t��I�~(3B2.����;�dYHfasyC�d��)2���R��#�H�Q�^>�@��?�s(�M����
�mu���l�҃�Z�)m�LBM�0�RB�DO�D�?�)�{�B0@����?�$q�Cs!L����b��k�T��4��"��f^�>.󊜲fz�O�a�A���b�s�,P���P�@��� �'9d:Ͷ�Ӈ��?�@�i�A u{.��k[=�v�AJ!���_��6�ϒ�:�Ȋ�k�fZ���2U�Ó�<�cğ�ϗ�
8��o({L�i ��&��IGc;���;�i��:�_�d��Y�!חLO���s�%ef,��;��ýMt��Pdw�n
�Wᢂ?�}����}jfI���� С�"�%�Z�F>�R�˦!e���i��S��#Xo!�U�>�k���4�l�o��M��y!B��m[);l�S�X.�p�n1��m�T��0Ɩ�I\d���,�v韪7��-�K���_ɔV��]�9��9��_y���r�ZL=5�Oa���~M}��p{g���C1�![j�qw(O~C��,5�6�A%�L��~4���>��%/�Rs3�,�ª��O�Cr�/预��=N�)�ʸ�zudA�,�C���.
wS���P�ՉX���l�F1�7x�q�;c���iA0h��arF��:v"zG�j}}�Bl�y��TԒ7��*|����-O>�����Yx����9L�R\�F��ѫKu���dhi�� �W������3�)�*K���Wɻ�^�FU�����B$�����7՗
�b��MsoE:�d��}Q'��?�����]����R�����mu���1������*����5�{����͝�5PE����9_w���3��%�~��ӵ�fLX!{fTD���qx���C#��Kb���_og�z����J}��A.�W��-��pp�Iw�GRC��.����Y;L�&H6d6yGʉ����{K3:��=��O|���G�L|�'>�d�#=��Hsy������6���&�C�O|���<&?���*��O~��'����8�[2�ђ�H�����v�N���잒l��'��
�]3�*��*|!�1�] �,@3sB����t�d�.d��lk���(��'��w��b/з����dK�l�����#�"��#�4T�׹c�<��cӤa븚�T
����=�"Q�fW{d�t�.(�6Gms��.̯���rz�?r���w��<Lk�Ṉ7����6z稚O�6�ӈ���y �G]�t-̆��K����]<6����+ׯ���_qr(��jĶW��N��Dm��3�a���4�t��?E*2wg�O���y�j�"�k�+�����Y��)��}G��<u6L���\`��Mff	�7��>?�c��T�f��"���}4���}jr�j�ٌ�ꂑ�I-o̅���Q�G,tXTw�0;�Cbvﴥ�9�O�Ɍ��̗�3>"�;�&-�z������pK��W�74(�_,���ps��8��2(=�I[�z�2�R���2�GX�������[ �շ���e|��U�v'^�Z�_���BC���)���I�'\�>��_�=�.��_c��Ug������.�2�@+�'��F%yg�YZ@��1p �{��2i�\C��P@&�{�ɓ�zG3��={6;�H�?R�bOe��9�lt@�oC϶�����0�.3�}�Zx�ʆPdg[>D~ͫV66�@ig
<=r7Xs�ͼ�qZ�H;e
��:�{��'I��8���_�]������V	u}� ��>�2��Ns:ݶ�V����_#�%��HE&z��m�pH
G�ؘ֬��n1��ٝ�,�� Ө���H��F�J��Wep����p�d��|.���]��7����\�ʨ���3lSH燲}��T�L慩6ū. yA�����U<�,��q
�_��e o$ޒss�����|�4��w�������;�e�	(0���f���w�bm���մ��P?E��uuXQ�6��֛��g,�|�g��EeO~�i�Iʏ!�>gs1=������P�Rҹ�P���S�I�E���	a<�o�׫��D&���'�������_\E����$��<��k��������U���������~�ɭ*0[ڗ�KH���V亮�EhX�!�%���G^dG�>q(���f8��2�76�𕺕���5:���B�R���3Ѵ�ӓ�U*�ť���ȶ��:��c]N�s]�%A���u��J����d��,�AGkM<h�dZ�|�������*�=�#8P�[ec{}��U��/mN|r�����O�$n��'��1�ɝ��N|rӯ�O�H.��܉S���r�nvʝ8�@7q��8ӾQδ�G�:Һk�Zw�rn�.,��*��*�l�>t�5�x�N�F�`�Q�=7��(��Adr�p.�~slڗ|��b_��u�*.��f<HđV�E���c�;Y�9���Ĥ���v�q�q�����ds9H�'w6��X���陗�p:?O��/�v�[�V��X�5(2%��K	�݉����A�}"2�]T�;�VT%Bsx�_��pd�5�b�n�U�Y��bV�4�&��T�7_[O�t!�d�oFg�;���.��2�$����y�JR˧=�]xAQ���㉝7�b*��)�aF��(=;�R�E�z5����*J���/�1��e-�G��7P#�ӧ���w�j��FY���̸���2o}g��W�!U��p�ufG��NZ���rC+
U�jx���AY���&�5�OZ5�9�K��d�i=���Q��=�yk<�G�6��4�9���T<�C1/���Ý�C6�x֋����u��w-�*��A:��n�u��i���A]�N���1�-0����"�
	Ȑ��Q�j�������.I��#3�q��L|5�-�
�Vt�9��	+HD��n숻�����ɛ�z��nW���A��L�3�^J���s���
�/-./-�
y��/�,�&��W�|�ߝzkjjKk��*�\�&L��	�
���~'�3�����Fs�_����o���SS?=<��z=���q-?�[�8��?SS�Z��P�%^�]���γ����X�a�w�������������������0���(77]R��?�����_*,M��U<���s������~0�=���tq��r#x����e�ɅO�4auٓ�D�M!���~����23�lZ��yB��t��XJ7��)�+�>ss�x�	i���5�s�GlU�^gM}돘o}�ӎ�B�W�rɉ�]��!c�"�3|�C7x���y��EJ1:�/U?�Uw��+Or�`�\�2[����F|�	��nF��֘k6�L�P� ���w�$�]�
Ҫ�X�����nQ�h�	��/��0�&�J�_���qh��6�H�
�;�b���fu��ʃ��&^�Sfq��%oBjqK)0|1/�u�
�l�r8i�Z�n��;��U�mZ(�T����ziS���ba�JN`��3(�m�B��L�ي�گl�n��+U�w	�e~�ݽ�����\�=B�JX�n2:$q���q��)d��L.�`�� `f5ޫP����b�����Aa�J"qE�#� G���עNOe���!\��w1�U2�_ki�M�t$���I99����K+V�}��4LJ\��Y{'����S�6���r�(�e	&��̷���}jY��8�gЫ�#X��x^▀'Vf(��%���wz(������U�['ܢ�A��ݑ:��w����4@�I�|y�q�	����6m@b�
�x��V���� bEh��<,rU���e�մA�#Ĵ�bl���5�?|��R��c����T�
�I���d�)-T��R����D���3��v���E���'S���re}g�s��nK���;(LI��D�����X4�q{��	������� �g;�Ez>JoP�y�;����}JF��J/#U�ʸoſҝ���+��N�}��\L�K�YVh���s ��g�n�6I>x�7�p�˗����{�E|�F�#Q��Z������.A4�s"�8\��d���	����J�e����LM���W�S�Y딤;z��W�եG�r��ǩ��]��C��9.�B��@VOpk9�`uR=��@!tf��t��yD���M�I$UA�L>�v#��S���<���c41Q3�i��'E�3r�@�Gc�'O��TQLNIH�8%*&z^�Dr����$$�ԏ�˽����}[���;��.>���Jd2�v���Dk0ÌX�P�TN�Z�#Q�����ҋ���
o�a<�.�F�1Z�ܠ꾱���q,�\���u���s�	+������c�C$���}��5[����4-�������=�
$��C�q3�/�D �88ğ�����T��/�ed���@3���'>�B��a=����hqUE��V�̽W��h!|z�H3OTBTц�F1V��T���.�{_�r�rQ|�3��k8l���kgh;�s0�x'�)B�I.\�#/�Y</z�(���=��7��1�q�#�wg�8~;;������c��.�Є�;j���$�3� A���M�ˣ�-m����
��Q�:������`�tYV�}J���!8�l�I���B�<�x뼖�GU?����b�s#�bG]=�Q���1O���T����p�_,���2��K��5y���9ƌ�3f°��[��$n92�T.o���˔�\	�0 ѵ3
4q2�]_y�
3+@R�-��X���s�ib��	�&Fg�v�A4����(Tr
��9WI�L�@o������
:�v`g���85�T���y�TZ�y�-[kt�5�F#a�졢R�����O!��/���<�d�aT��|�#3|������<����(�wXein"�[�cʫ2���Y��#�ɠ��Po�K�d�3�H���A��VUXZ�V7C�%z�"��"B��s<�ȰW�=ø����4���8�u����N�L
zӬe��O�-��N7D�'���D}⪃��HP�:�a~,ck�����O��ɧV�!���1q�îg�q��&f��`3K���(O�\����i��QOJ]{��gZX��)�F9���c6�T!� �ƢWm��t��Ҽ����
*"���#[��gJe��(W�Q�m3M`���h�~9#"�*�LP|Ũn՞fgI��D!�pe��m��!���^vȝt��W��%���J1\#n���^�^jf�K�0k�� d�S��L�}���^\)v�͟����?./S�I=��EZ�/����Y��K�KjB�@��j�{�S�N�P:f�bO���'�g�������yLn<��R��|&=��N���~o�Cv����#b�rh�_TAC��N��h��kW�h)4�zw����І���<�
Ɖ2��PH��F<�sz�7�V��HT���Y�t���3yu>J�����.zv��B����NA#���W��mO#�QW�<��F��Y3�M�y�����h��_�j�p;'�T*e�=�����i�l�l��ʔa"}-T���5�D�e�U�/3u�8p���fY��{c]h��0,�=��D�QV�Y�6�l��ީI�*baY-Ӥ�}v!�˙loVP�)�M'�8l�q�G7�y\S�}e-!J����>���Y_�(%V/�Ƚ�n����e��zF�$q������l�e"%Ҵ�I8B���	:-9�*4*��2A�&3����%�<��M�� �_|��h�ޢaWWb`iO�_���痼�I�(Y4��XX��F���+ +[�"��|�@c��r-�!����U�n���qcPh�c��xDW����٘o'f�H���jk�����y~66�V�������ӧ�$f�]��tM��5���f�fI�uU՚�`Mp�=��oL߻Gs8je�K4 ��N�	Y�y� ⤉�ṁ��x��[*),V>��������т�xP����s��ʺ����a�{�gR�Ϥ�2y���S��/N=)#�1= ��4%p%}y|�r�,/= /�q���p��.�G�V�9Dzz�͆�)U)�k�`I��QrH��,���Ϣ�(*��6�wB뢨|UC���En�� �z�@YzT�Q�1=
dv$8�+�w��:(��#> ��=^:�J١�*9�����6?V�%}�0�{W5Qo�/h7W�ROԼ�t�^*��go���{���H%���p�-��d�=�d�Q�1�W��9�	ur;���x��C�,�;]��z��f�4��`���G�F��(�L��S�@��@ף�w	y��4���F��N�##P�}�������l
�{���ܥތ�_�b�Oz�+��4�y5ǰ������Bv6�K��]h��W]|oz�N:��Y�+��KZ��>>)���=�{S�:���K]6����է��h�cK��X���Q�Ao<� ��ԇ�>���zR.��6��L�� ,������e�.�=0��	&|��I�i��Pșb���FɂN�-ġ��g�t���ѓ�Z!'@�h2���u�۵�]f����tu`Z�nOw`~,�RR�$0�D�kz����U�g���E���h/����(Y5*d6�DoP��=�3��&	G��P�t0���uz��Yy~#H�K$�c	�t���,��(;�����^`3��*�b�fKY��D��aMJ�Z����d�'�@Y�,dQa���r�:��Ȧ��O3� Hzz{۶���_��s�~�	:8YO�'9:�b�L�4�  -�.�g�
^�,�<K���k�2��x`�ǚ��}6���qH�����^���]��h��cJ�C�TY�Tl��� �[�#`B��kk��`X,z<A��y)!Y˫)� _\��V��G��Il��xNxE��f3ү���!啓�P�~�P�U����0�cEӎ�3f��,�U��Fq�Rh�Y�
�Й��r!��W>�6$C�[ڐL��Lb�kH��/���iy��ې�cwip2��y��D ���wVkq����mK���eP�!g���c��*�A���׎z�<X`RV9�/�%_~���^�Gā,�L�D�jfN(���u ڛ$5ć,n�.~S0n�.��r�4JA2�i6�ߧ��a��'�#����CTP�p���i<�~�a=�=�ه���V�� ��K��暺&���)��k���(^-�g��*��!=��n�G�Ŵ�3ԌZ0x,z�
���?�(Z
Fw�h�:[��81�qo��?��WjC9�`zq	xUά�x�j�0
_��t�#a���Z�tl|��>�{�Ҿw54�F���oOb7���YD�s$�ށAx-
��܋��*'k�LYV����И�ʈ�7Cű���4�$�a]��Ǎ�����
'S)���,�"��A;�����b�JF��<Wˌr���e��߇NĚ��T��w�<�
,Plh|%/��Z�Cj�0��:�ɑ��{ �l+��<>b�'H��u"��Qј_����ix8A�4\9f`0���i`,Y�#��vj������Q�3"�x���a��[�����z���xc�ki�0��#:�'56?9����H�ԭN�2�ˍC����0Z�Ƃ���)�HV�F&#F�LLd����i�s�[2�����h��TSr��\c�z�͌�J���.�3�E��P���X[.51��)�@�$u�Ť���C�����]±wRd�W��f,Z@򺯮�<cx�V#{�e���K��Z\&�|~yye�,_6a�|�����ucy���6/���ki)��WW���h�/�����♦�'t%Iz�jQ���ǩ�_�T1��ޟ�kT݃����M�+q`�����-ԫ������]���xW�H5Ğ����&x���z��!����j+��uJX�J��Ao���#�����S:ܩ�bx[������)!����?�����x���q���:Ve�f�𛔼�ҩ(��F�o�א�A��_P�u��A���4��u��m]iƲhF���OK���@`��@����(�e��m4�7���IM��:TF�4�C�"���եJd�ɻ�i�bv���gG������8�{�7�#�,�}~d��<E����f�z��%4V[��v��m@�@�ҁ�����֧WSE��7�]�������I �E�^l��٠�ǶẺ���<��L��ze�0�/ȣ�����P�4��ZH����4ߞ����5��M54�|�;�I��ڠ��i�N�.qhDf�o��1OX|vF���K�ӸK���ˋP�A�K{LG����u����#w�FDMl�n͐�8@�%��҂|�����z�����կ~E/ dF����o��	*����?#�~.�u�0V��pa$�N�Ee�|>�_���
�-�O#����z���IDֹG\��2�yFf6~M3�u�����ӥ蘃28ZK_�"�I�}����G��{��@|r^eO�b�z��^�}BW�R��{�4����Jzh�ɜ�7�u񂉖>?�Q<:ݤ���n���ZM}�@����C(�?Z�l�G��f��t<��
5�l;L��xc� e�{ C�b��T��T�9q�ػ�b>3��&+�
GA/�.�o�y�^~�1�,�ݺ~�6����d���]a��c����vt��w�R��%�������[%��<���6:�W���O+1b\)��X�D��^/� �yH.6�P�tLD��ˡ�<J:�-�죙.�5�͎��>���h��K�M�E��5�u���ױZ8I&��Ԭ�ШjF/��w��@ܠvQ���A��7���@�t��].���b#�ksR#��6LG�����wq�K�:�"Isz����yL�tӶ<u��L/v��TY�=S���(J�M�fk�eA�Ȳd�^0J�����H�g� ơ�&Ņ��~:WH�Wj�����Zn�l�H>���F2��Ϡ��f.����sВ���G;�1���4$���1E�%�`F!fH�9��C�E��:�.>K��-z(�8B�����pޡ�B'�y�~L�a��T��Α#��'���L��A�����緘��J=�*�\d:
b��XG�榈�^ӗ���<�y?���W
1����9/^�D��5^&,龾����N��B�n����}Vg���j���k�P����(x�h��7�8��8� Z�QF�}J#۾d��kp�<#�*���q���,�g���Yn��,(��S u8�
:j�����!�����Y����!)Rؖ��¸@JaƼ$��l�6�C��M�.BR�JH�V*���YJ��7�E2�N�}4P�cԳI�٤w;���vɿ)E���LSNɠ�X��!�$DV˶��t�9�E��v�l�w�	*�FMD��;N�\�qe��x/���o�P���|,FkZ�p�3 �pi������3%��e֛��Ȫ��nt��<��f��M}�JR����*P_�1�hE��yQP�d.@���I����t����њ�&Oc�)���e%��e0g�}��}�qc�ev�;f��x
��fY�JQ~%�&n4d�ID�����0�vyE��T/%�����~���j�3��bc���@����՞�����+�E�7��c�c�l���5r]̬�d���܎���v���*YP�����R�Ȓ���׻�)ª�K1T5b����ctr�3�r�3�ܕ&I2�m��p��W2��R���}ѿE9M��{�<?d���Xgz�J&#l��h�N����'�]���Bc�[�sfV�C���Y��a��Q�;}�!J��@z��K��e`�CP���ų:|�q����D��Rn�օ��c<��I]�W�����6�!q�=^�b�YȘuH��cP�4w�e\XG�;,(dƼ��n�VN���2��8�&G���Y�4�Hل̣u`��,rI=l��n�\h��]��ck�X�kF����T���{��R��K�Sa�{2��+���W��3т�� �Nw�U0}�-c��/t�o����>�}�tU����=n�с���ര�`FXW�������_�ޝL���_vj���R�� ��J����Xg�>��4L+&/�-�c�Q��w;��N#TQ)#Z�M��7B����s	���b�]����j���C1�
��� q��4��=�}�m�l��ٴx���p5 ~�3B⬆Q��tT�������]�����̡^�㪣Z=��ws��E"S�2"�t�n��VkV9�qg�΢T��ut96��QLn�ͷ���N�|�P�?R���_��т
�h1��1��Bu��G�ZƷ33��@��?�'EPj��n�N�� ��ʒ����\����'5��uK�&c:��[*�3d�b7&CWv)8T�G�� uv�R��#=��/�[eug�bU����$�g
j�����'e?�i-0z����� г1@(Z�D^ 3��U�j ����-��ZG� ��Y�MlVtԞCcf5��E��7�3��SO�E�͙T�"��*�k���`"�����B��j���.(�%Y��)K�I��et���2}���I�h���`:�(4R%�z���z�^��� t�7и�����+y�q�e����9���ڙ/�����vbv�(��Jn�K�rL���$j�#�@Y� �K%"��l�bb�	�İ{�F�v��{J��-�
���d|z�XP�x���@��6��G��Kq��B�&3��-#�߬P|!�F�0jQ�OtТ`x-
`��\T��U(gݨ<�tT�R%rq�Y�x@���:Ӛ�:p~��Qȓ��)*T �}�V�����������~�7����C�Bf���EY�]㥥@�O�=�ʓ{���Q�5�%§,LY̌�,���6�>0�_�� �M��W�,nl���Z�68�p����(�^	5X��:a�!ࠫ��f��6c���?��
�B許�6و�
��T�WQ�J7P	 n���9���;�I.���h%�E�#��i�u�1���2ut�6Qp��n�tm�.`�G�?��.5L�[�߷,N�ļ���B�"�q�À���=��<5c���}�H�h�]堳<@��|�X�q~���
4��G����+%�[��Jp�%�C��ȷ�G� 
]�7i�Ҁ(���o2ދQ-�a�=�`Oq>�x0{)�J9���GJӉQ�}�*��h�׽/(������]G�V�S~7�Ȳ;�}�E��Hsu���IrZ����wL�/Hwh��k��]fk��O��(c�l��䧩�<���6@����艹���%�KАhr5-��ha�����֧���̰`��Rf�P�H#M�>"R������'?Wh�]	1�эCL��	�̆������p�Yk�iL����A��&<�i���"���h~�;�Bo�NT��K��Ȱb1�;�x��ݒ�,����tKJ� Q���+�:�5��4~�w/�����$�j�L(���Ċ��:L�.�aF߱aU3;�7dT%Ӻ����l��Y������MXxW��<WcX)�c�V�1N��r�Z��\ ����d�q�i��	QV�N �~���B�F���0��J?i0r$��Jq�Z@�Q��!|�본��Uĳsm��9k�,�iQ h�n��CPK��q��4��d�גɻ�IE�z�d�����v��|��t�;�z�`��i��g!�<m�M���I�t��m��$}��V��*�`���:
�\�|a�A���N��5��މ�b��h.��ꎏ�3E���V��d77�+��J�������сn|���Q��+�B���X�O�\��@9�2���--��y���s�ciuiy��*��w���s�6�=��f6�kdf�h�0%���>����[�kc����#U>'��/W�!OU�[� o�v@�>X !;����~��@�0q}��zd�D�A"Þ��[�/�]Pg�����]�NGd��ytu����>vy��+M��r�lj����
(��y& _0�=���y*"^00�Z)�k�=n�u2V�rA��%JNB�3�[����G;�pN�B�z0�FoA=�'���������j��˯��	�NNi�g�N@Z��
����}��s5����+������ 0tKX%�b��GЅ���ީ��	*^���j���a���~�!n�Q�q������7�+s_��Cp��0�v���׉�����!I��b�����'v�������P�]�q�#���6�����ߕ�B�^�b�_P���G�(ΐ7��m�Jy�Խ{���bv�Z,���z�S"M1�D�6�K��d$�|�e8N~hM�i���F��	Ȩ����BMo3A|��6	���+
>v,;�*���2U�><�H�@�N��P+l64��S��q�bW�1˗f��b���F��p'd��S�Cf�����A~o�R}�����pX��2�����
_���*����K���J�o��SoMMmi�S%�i�iS7�_�����k4����=�s�+��v $��4�� �3�:�_ &M�VP���/����ן^���'�	ƽ�2������j`�/�N���<����4�j���� �H�~�X���;��(�-�]��?b�nCZ"�-	|��5��z>frA��;���^]��50#��^�v:����s��p蜘�������^��^;�"�~5_�}���i{��q�<	ĵFfd���"�Ѣ#�� ��t��O�(W��R�Q��>Mh�kM��d>l;V��#C�0Ҫ�$(҂�x� :�|��H��,�^2mD���[dX��u�a=�p�*K���ƞ׽�i�[	�Эt�����%w�_+:M���C{�W��+��q�l%Z�������܉�C+0h�(~q�Uq�~MSs�9{	"��r��A��w�ݴWﳣ�xx3�_�e�1�1��A	z P�$�>�o���m��R`�j ih�o;�mJ�)�-�C ]
�0^'C��
C�=t�I�hGU*@�щ�ƌ���bEi2�#�k���AP#T���G^��z�Y�H/�j�T�vI��	�M���C67���uҁ�s�+&��g�E�d��`iX�.j}�� ��Խ�6C�qm/�aIQ؜�1s�:%���I
9��O�x�j���)
�-�3C�9�����e�.aRv[����cqΆ��!(��8{d�.(r���T���E�c�~0�����+X:-���F�����&�i׆��ԁ��A24��$�0��y�-��N���a�*ӞåL���^/1�h�j�� ���8�\I��m����<M���s�!"4���t���`-UffN|�\��7��,�e��q�1��w1��XXZY"��������s%�kn�5����v}�B��<�Ot���1d�VWC��M��U<�������_K3��u?�4�G�&���𦛃G2/^����iv����{C\lQ��a.�0z�	��GY��9f���TXd�?�V�8w��ե��%��Q
nȼ I�ݶ��ǹ_�aoF(&.J�U/u����[�.��=i�.ޭ�#���=��)6�^����6O����Vr��c�$�K_�����_Y\Y[�g���'�}s���x�C����a���t�'�G��������gr��Z��2xS5�� ъ���@ƫ�_�������(ެb���Az�r>���S.���h�A�_Z�����������U<�=�Wƈ���%�����1N��*���?�R�����j�0���x�{Jj�r�F�cs��?�U>�˫˫+��!?Y�]�3���)���3���{��#����&���H���F���_X�喂�������'q���ø��7����,��z��?��� �)���WV�7n�'��<�g�L��3�'�>nܺ^2&��<����Ϗ������|[�s���1��C���po�Ϸ���y���1��C�ɅV�/>��_�$��"A���g���<ߨ��ߙjL�S��^����w�r��wSS�o���Uq�����2~:Z�{kʜ�L5��{#�^*��?��S��R���#����N5��N�ޱ�'��:���r�C�o����|�ƍ�n��Ϫm�J�����'�/D�������k�G�~\��{��B9��h� ���a6���V�l:O�7o޼q�v��/_.}��@Wr��e>��`��,/��޼��;��Ư�'_�|u�����!������/��S[v����h�����F��5���u���l�����}G��;4bz�8�ۿ���7��k�GP���	τ7�kh����K�N���A7l��ٵ�=�����]���p,�]��>7 ?��>��CC�;<��͛�����f�҅ՏJ~������[�w��у��������Bs:�����&^ĥ�7��֏n����~�G?������w���������ܞ�q����;�7o�э�xti�j�p���;�3{��L_��⛿��������wn�;P��ڍ�4%��uk�9��m�&KY\���AG���͛7h���z�1w?��O,޻���<\����MF�;��Tn��/n��Fw���nB�?�я���7��7�fSo��WM<ǾЦ���ao���Tn��ԧS���M�L���~�L�ͩ?��w����z꿟�;S�L�é�c������w�K�8�J�$�$�Kd�D!���8���4�Y�q�W	=�J�F�N'N_%^&�T�M�s�?��s�!�W5��=�o&�(��^��O�'��4�%����N�ω�%�w�[�O�߉�ַ��˷������(<�G�[1��?������{my���v�?�{��~H���,�_��1@����ِrc/�v���`#����ȡ����v�������G�~����o7���fz�v��M��g���-x��o�~Z�	��[���[�7��o��]���M��fo~�tx��w(���[��p��ʴY������.���;��%��H&���a�$�����{��'�'���vb7���&������'�N�LX�e�W��ğL�3�?��3��ȴ�b�/%�r�_N���-�7�:e�X�?H�������M�6���*�&�'�U�)����������F����4�Um�c��)���=ՙjNS��t�����"&Y�]h���EL����5բ��T��4���x�Zb!C��@F�9y&��<�g�|C�o����J����<��k�$�.W�����Ѓ�v�~%2L�x�9��4ϥ�����'��o���|s����n�����j.G��,//O�\���?LFf�y,p��?x���������ZƐ�?�\~��[Z^Y.`�//--M����V/��S���}�l��u��n�'��7�a�y�!��ɛ?1yh ��DoЀ�r8.D�-��{�n�Z�I&wK��g����3�f�P�<�F{7 �������u���%��=���E<E�$��'D��X(������DA����@o�-������al4qm"�)2'4k/qs�������x�@�)��X}�����=94�7+���Q��� �\2n%���?����W�����Q�[��Ws��m��4����	�?��� k���8���-..��y�/�����&翯�W̜``������7ܾ��@�MR��#�r���\�p\�o,.%w0Ly��|!�[
��
�٪���%�֡Ē��o��"emB��^��ry��39�3�pw�@��l[ak�8�NZ�Kl^=�f�h�&�e�&|��x_&�9���{h�FN��)�d�ڍ�R�K�#)ޑ���M��5z}��+�a3-ݝ�-�l�6�kۥ���I�B�tk,_j^ �in{\ �l?�ϲlN���"w�D�|��^Ao�!�a�sA��������Z;5/2;NG���Zݔ���}\��U��=�V�0�^��h�<�a�{yS��R��xg��d�F�f��Ja�ȓ;γ�@c| ��������$ �nZ��B���3����χ7��Ac�����ͪ�,���2��i��^SK�$�G���&,���r!����ˠ��R�����gX.�Պ�v�� ����S�k�D��@~���!�̂���$��=�K��҇76��^�V6�а��,(��4��X���|�Jo\ �-��z�,����Y1�&gw��u�C ��{@v�|I�K���al�]Á�Ҳ��_����:��s���Ӊ������;��g��g)4�/��L�_�3��'����<���Ҫ���&�D¸�����	9�w:��_�_v��b����[8H��]�/����~��c��8m�vɃ��M��"��ͺ�i�ɽ{$�v{28^�U��^>y	���h=�l�:�v}��[(,,.,-,/���97���*[�����Ҫ����Z�P�-yw���j3��Y����zT���S����6j�R�0�o�������*�������X���;�ר�a�Ǥ%���#���e�t�U]#�K���	���Eϥ��#�d&Ow�d-L�9 �F2��f`Sl�ZZ-�9��Ct7�XM��7�O���^��kDH���$!#�Il�wUl�=o��-.{'st'c>CJ�/at�@Z�38��)X���V�qK0-�����������5��oZ���L:����,�&��
��֥�YΈ�;Ce�@S9k�Ե���^J�gVL�1e����}�39u���;;f+�'(�1J����40=�0��p�ʗ�𻫈�wtv%���8T�R�:|�i[Ǹi�8F��OP <K�u��@7� W6&k��M�=���觖�&K��nI�	��ϒ�'=��0��$����|��h�빒�!;2o�j[t+��;�^6R�7Ɠ�z�����f)�=�뛸�����;�:�g�dt@�����N����"p%�W���yF[���n��i,�7�u��gyT�O�I2t��@���W������bn���եŉ�w����k��Qeo�E0��G2���<�=��B��_�V8/��0 �ɉ�e�/���}�6��t�h�P0�����W*�����u�\�ugЈ���&�$(<?B$�R�r��;rB�Vz]=��ae�u�!����Z��w�؀?h]ڑfth�R�l�Ir��W�on����;[�(�o�l�Z�A�Z=�.��e�6��;{���
;t�W#̍��K��_�,���`+4�S�b�W8>N<�3�D���\�/��!"儵kj�����-~���]6Oi�H9���dk!���g���Vn���ʽ�����Pm�l�h6;��f�2�[��s�Ƽߧ�G%�Pߗ�̰�貢7w�B�"o��t��29C�N_e} >��@-d`3R���`^��b=�r�N��K�-�N�f�.M?������ޘG���@���8/m���qa�-r9���8���J�'��ەg�=�遤���.�4S�gr�䓇�������d��~����E�`do�Z{�Q�m}��[�`�ŋ�Z��Mr�g�O���K���˅U��/Vrt�gyui��{%�e��'�@dGX�l���Lg�E� �,"�U�C1��CNeτ�DZ�*����s���&]��AO�q{�Q9�&��Zܑ�֌�{��Wa.�f�G^���N���^�xT�+>�:}}섋��|q�i����Y򄅬��gdV@6��"��U������Cf@�(���;<ysg��y:JIF=XT ��� ��Yl;V��#����CZu�� EZ�U�� �	�{�B��zHQ/�6��v<Yu3B��l?�AXO<�ʒ%����u�gZ8�V'`)A�sT_�0�0�tY���|E��xcN�g+�4<��ߖޠ-�;L�e����W�Y�5ME4���%�@~Bf0V.��Z�M�N����T-~c�67���IB�V��$0��1B��J%����`9(fM)f=�� �����Cߦd����f��0ҥ@�p
CA���+� ��J�6:�@ޘ����ـ��A�(MF{���c�=jD�*@R�y��k�V�8��]z.իP�j�TfS��M��7����;=�M��"isV��uҁ�s�+z2��g�E�d��`iX�.j}�� ��Խ�6C�qm/�aIQ؜�1s�q5�C�&)�<�[<!�5���<��m97��Z��~v�l�u۶l)���Ά 2tvV����C��СS�82��쑡0
W�{M?�=�}�)�� �yq�K����;�m9.	@���D*�g�By�\f�R*���,o�T�,��O��)�ߋ#�T���}\�=�جȔ8���/���f����S��L���6M�v�
��;٩�s�Qf��E��PpI�wܬ���+33'�����ce�l�^uo�e��B�o�]\B�������J�<��!���y�w��H��Vk)^`�M�����E�2c3�����c�_K+8�Ws�����{��_y�}=����C��AS0�&����𦛃G2/^����i�W�P~C�{C\lQ��a.��z
��C�?���=����
�����<�b�����%�4�L�S�ͼ I��)���]���_l�K�4&.J�U/u�����0u���I�t�n���������dg����
a��[�鳎%�D�N�j<�������WW֖�Y{��	xߜ��8�����ʕ����ڕ����<��ra�F<����<�W�L�\����({c5�� ъ���@ƫ�_�������(ެb���Az�r>�	��5�A?� C�����U/������+���+y&�?��Q���� ��
�5zDЏ݅U0\N��(6�� ьh�����	�9C����L��D�m7�D�V�;���r��k,������/����3�Z~i)�R���C�Ti4]wY��t5�_� R�1$��f����3d�u��Itd�754���i�v�5d�&���a����b ��jn�0����l���j����j��H#E]�Ts���$�{���V�oJD�d���(B�-���a٭d��F�ĤUǘR�� N�[�)�C(o`&af�Ν�B�@���쁒�u�tA��m�n�D���>��M�g�L��3y.����l� 0 