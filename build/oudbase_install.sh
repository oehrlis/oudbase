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
� �ݼZ ��z�Xv(�����M�b�� �S�\vBK��nM�d;u��j�E�I�H�j[������G9Or״' $%[��N�t�"�������ڧq�����Y]]}��=�W���Qk���?~p���Gjum������~��g�O������vЬߟ������9��O����d�7��W�c���?z������ڃ�?��p��?�կ0�������cQ�4��ո�@;��������O�8��\mE��0��d��YM��4����[G+��Q�EY�,��H�����_{��^���4������E<�{�äw��GQ�?�;�c{:���x4��a���A6��r�+*�g͔���D��MG�v�O�߆��w}u����������at�q��/4ƃi6N��>��SG�,O�$Ug�3�T����n�x�*�UM��ꦽ�N�\�w<�]��5
�dx��y�S�4SQrgiB[K?H�u�f�]�O4�>l����8�h�Π������ȑ� �a�;q7J�^�4�7W���6 ��G=���Q�`D���
��qI�_���v�f�|��(�`K�_w&gQ~�l�M >�(�;w󹐢t��_o����l�=]��|�h� [&gx��ivV���;IO��/C@�� ��Éz�Q��	�t�������ך���Z���>8��m=����Ԣ�@��t�N��G8G@# ������ڋ���M �G�)4@	83G����'{���ӥe��h�ZZ]	�wN��;����?>��&�q���ށn�>z�Z��ͥ�Zpt�><>y�iou����vvi����Z~e��KeծV���Ղ���N{k�st�Nܿ�YǮ�����ç�����c�� Ђ���Ջ�[�t8T�>E�A������+�J�.�|��3�Ӥ����xàn�`�e<�u�E�+�c��n��x^r�[�ڠ*�<=�Jw�3U��{��6��z!~j�3Ո�x�� �6;�TcK� ������ !�H��8!���U�(�T������e���UoW��gU�wQ�=Q�,�.Q� �iۏ��s���M�n�Y�%.�&0�l�ʕ{O�X���viW�OԶ���v�3"a��;�/��\q���~��kW�q6Q���'��@Oss�I;�����[��~E?GC`��]�*V����y?��[�~�'j���I�$��2��M���|��m����q�{WU�Gi���6��C�������v���R�+ �! ��B���̑�s]�3{Q�/�$�x{�s��{ t������w?6�5��|�j�ݍ�j+O�8��~5Y�21 x�3���K�x��j��6�ǿ{��R��]��5�y��W5�T�lP<���!浥>��!�6c4��SS�& :6B��7��4�iGI�����|��y�Qc����X{���Mgf�Ux�pv�3��k�̴<�^�De�t����Y՜~g�_=��/�m�eC]&�2�*�lj��c �}T����e�E��BV�UR��d�4_]1<�*p֒`풩5�9PRhށ)�M�ZtS���L��t���fgSԑ�:�C5%V�d��f(g�"5�.֯ۅ�����\�Å�])��@-�tB�##e���JAW�尽��1�����Qa�`��J�Q?y4!����<��(-z�Y[[y3�{a�N��q^޲� �0{����W������������;���abQ�}����;Y+����࿾p6�:�n6M�[�(�MG�0����^��Th!?Xy��OҋD��X>�����L'������_~7�s�ʂ�{h����C�㒵�@]ђ$b��
�l���rIc�TN�9u>?���Y>t�	)Ga*^0:ZjwkѲ2��
���[��F5o�w�� �v��<�S��ɐ���RЩ�<�'�"L�P�m��0�̿.$��EiD3$�6�֟����t��sP"T�Z�W�8��<����4�E��iO�o�7��:g(��.<x>=s���
ͳ~�^w������/;FVB���q�ŗ�}�z��ē8~� 1�g�I?l(PTK��@������fE�QfU��P�)��kF#��@]�ءc3|�ݳ��>}�_������ �^�V�7�k����ʁg�[�X�f�|P$-��x��>,�@da����8�R���W�j�{+L{�Ȓ����O�#�?�3n҅�9�o��s`��_�5�CG��pL"1/��#+�����88?�±�yz�ZCD���v��@�x!aC���b+e��S�JrLoTMփeW<eg�$��rk�&����0$�����5y[�㍭�_6:J�FmcE ����`E���?_)��o�ڽt�s� ��ǈ���g��E�pM�3�f+�s����>&�HqT�������Z��+�!��燔�D�
KP8Ҳ�(ͻB�uh�Xh�z��Ob��?�؈K�
=H^R2b�1�t�� �GӾJ�V�*- ��)i�R�|���眓c�>���!:v4���,�q;��x /���T���i�p�/�Rxs*��\D�)�8�"�������?7�J+���wR���C �����,ەe�F\~�̌}Bx���v��7�p�h�({A�..z_Z7�wo��8���'I� 8O��,G�$�r9<⵳�ڃ��cw��r��p��܆c��Gk8c80��W6�#��5��=t�e^�^т�t�~A�ݞ��F؃�^r�zyiQAYj��n���R�Ѻ�y�������Q�[�kM��x��cR�@��I`Mm}��2�����$o�KZ���jN�{`�v�Wi�� ���z�@������;�>E�9蚈�G�=\>�F�UwK��%��q�h�W�kP�qT[;}R�Z�H��ԦkU灨�!�!Ye�P�E�wg�}@�9����1� ��1vT��ۿ�죳h9�x��>����xx���.i����Y{��ro�%���kOX_|��qk�T��^/�}j!�XZ�G�~��=�}���>������O	����'�
�DI��g>f�3^�8��v��Z��z�X��5Z����3�b��3ץ�vXt�~���h��9��%@:��'��9&�|���o@�#%��z!#%����>h8���=�7�d�ao'����u�^�����m}%�����^f΂�v���:��+<K�'��W�內]�s�X����졉p��G�������z��(�^���O4�/T���o(Y�>�yZ�`ʍV�DG�W���;�VU�ȦcG�T�d
0���l�8��e֜����/o
+'NL3��+�;'�)IH@�A��PײHy���後�nG����AyEI!�[�U�K-)��:��K>:���H������?2���?�������������_�oN�?FܿD��@��W���o!���B��-F�o!������k���wb�o/�^�.c�� ���~ĕ/��/w=S����Axt�{v�,V������c��(�����3�.Mϼ��C%&���o��o�m9��H��a>d�e~��c|��_���vQ�Ɂ�wKڛ0~_���T��ǯ�;4�YM�t�{=��C 0/����K�ֶ��x��Y��d �o �2 Է�o �� _�0�8��	49���� D#G�뫐� l�	J,����s�= VM�?P!D*Nd�"�5�D�����q�b���d!Ij$�R�TE,~|a��;&	�����H��m�!=JT�q�uu
����m'M����E9���.+�%"�-��[���ԇӰ�~:�+r�/�tE��-E�/NN���Y�B�������E���wu�EO�b��l��g�5�2�a�te�n��0���o\/t��̀S��aM�����C�c9"j텚O�%v��Y����Q��w\@�'гyC��
��|�U����<^�#�ZZ^^�w�	�+�%BW���7��@�O8����T���Z�f/��	.0����}�?5r_/-��bܾ�������>RA�pd�4��+�#��C �I������n1~_�b ��}��@��8�D�j}J��S�Ba%C�,��e�!p4�ރ(�Al�C�Hb��ܟ��� N6zp��@�$*���[�a�~��h#��P��׈�?��?����iY륺�'4�w��;�:[�jY}l˹��d0��m���I�1�lS.0�*{-e|�B�,(�%��-��y܋
r�0[Zj�ze8��E��3)le�8Q!���`<Bs��޸mMb�$<��^,���9�z��*��mC?���(�眉��e]~���i�����';��c�r�����]er͙� b�Rf��Z[�Yp�&�v�*�>��YQ�E�}�v�}ܾj��dV��4�4;{�t��4Y�U�*]s�����&Dh)&ڃ1��{�Z��+�p�{K�wk��+N �cW2+^��2��:;[ǚO�hV��o��4�p��f�����
�oE�hIM�bqRءJ�6؜_�w�@.������N�6g����N��U���~D���&��)��m�d�P�?��ْ���
9T��`���#���n��ȟ���Ӭy!"}������>��D�ثwE|�����YsT�n�L�dj�QN	�?��R�?^'ߩ����v{XGD��M<<<G֍�stLe��x�l>A����\��Єm^F�M�A��|)�Y���_!�JF�@�h�M�U\�1�h"u\m��&@M��W�||}0_*��G���Lǈ{՛+�b���z���r����� �Ӟ[���~���BJ\�m��kW�t�U��G��j�U�}�(�V[�-��X��X.�=��9������Fh��l�O�U����s�I8(PZ.t�@#>q))i��3t.;��}�����r��0�՜���<iF��P1CF��\��[��1���a�N\-���,��O?m������?�])	@��e��+��f�t��^�<�}k�u�������j����3ۢ�V|?���)��a��<�p���Ю����E�p�~�6�ww�h����U�A5�=8W���N���ke�\+�j��g�.4�Á��᡺����:�
/%@��|7���DH�]PP�%*�aP#R�wI��zVq.�O鍊�!�T&�̟��8�Q�e0:s�oZ�o����9G�?�$T�AS���t$��
٫sݣ"� 6bER��&�O O���r�z"]��D�=!�JPn��]�i�ٵ����J�1���~�6���T�1����O�n�SO�#��2�d��\�iM�}�&.aLI����(�ꘓKv��"��H��y�N���8ʡg1�i9S�saE��6k���b���a5�7��Y����������?�����*�o�?2�R��9��?b�����-��s`}�����?h�����Y<|��ޔ�|������N���k({���Y����9��Q4���Q�}Zk4���F��+�V��g�R�n��_)5i�~@4�o��d�jT{ggV�����8GJ�D�����ag��w�ޱP��Y`߫�v:9�p�Y�pϚJ�=i@?��3�����Ϳ�>�VvRqX:;�A|�N�]�O�y�H�r��� ���`�� ��[Q�o9H�r��� }�A����-�[ҷ�o9H�r��� }�A�}� M6�o����F�k� MV�*stޯ(r	T��k�/Q��S���P�H��!_�L�0.�5�5�h�W`�oW�;kh�־e�|�������7S��θN���{�[�[�!.̍$�q��0E�p�>U����F5�"~ǈ�a�α�0U�;I1��:oO�ﴷ�X�_����eX^�h^5�
ħ��9� �q�'�)�����wh|�1������B���&m���D����v|��� ۞fg�"��dJ�}�V�кcr�R�f�3}^ʖ�����u���4+ɺ�)�ʆ&ɶ�v��r�T$�uR����OEr^rݥT��c�NE���0I�XGJ����GN7�>*˝�,�
at=��$�9��3׿U�럵#e0v̋RsR`~{[bD��r�6enb���*)G��GT�[I�����\c)�3ꥏ�X\o���RlUNH��XJo,�|�^ē�$A�iҏ�*H��m�޴�M�n �j��{޿���|$�99�;S����3��2����n��ͫ�L�Ū�r�]LUkV|��o	�%sl�01� ��_�mVp~�H�a��k�0���1ɲ��,��gX���WR�%R}yՍ�~���%N��}v�����fy�+�rSg�E��=�����)K�}wsZ�P@��%��4V�d5*�U����r��Е*�՗V�=m����H5�jrU��z�\��ԝB?��.���<�����h��lc�M�dt��ȶ�+%�}�|�ǻ��+�1?�����9�����G����_�<��-����|������D��s�ئG�0�_�s
6�oY���,@ɘ��&�b��y�B:�Pd�;�ī�Ν��u����[J���Mo�r����Q�B��2�������W'G��7;?��|U[��'j|�U���{����$b�&ȅ���\��fJ��Y��^�`���z/���
(��,�]\�ڈD�4b��o�9���v��l�J���K��As�l︭�i�O3�<�2���V��VѤ;�*M�ϳ���;�;��Α��D�1~�7��^o��gioڝ8P�_��OҤ?�X�k�5�����};�1�i;d��~����������ZP��{j����߁�0g'�f��7���EJ��D���'���m��e]]�y�Ԝ7�S���Ֆ&�ԍ[�0� ��D5�	�l��P��O:�Me`vN_�i��F�1���ߪ��c�j����]�����ͅ��*bc���1��S�}�yw/���
c��S��.g;jW�Q�w�^����3�igGV�K[��ث�1�>���p��� �#�O}��b�e���	-����_A����g{�Q�U�a��=�����N�%r鍪@'�����v��|i��u:�s�M[wi��ag���!/-R��cY������?Y��[�Mé��3�f�/��[�B�L.K�^���?�#Ef�O)�z�RKbR��QwJCh	�4/�������'�*���$��B�ٌ�)0Z);�ێ���T���nF&�/�&�,Qk�D��AB-ND{3R��T�HL�gT]�z�H�&&e��Z���R�6�-��sԠ�q�O�J���"��E=��0MA-�Ԍ�HM����7��x��\9�U�kU6<,�7v���D�l�}fz	k��I0X�c��1Xq�2���<jU��הj��}���1�7���:V����p,@ء���"s��H�\��ozɕ*�W�BT��&�T9�&��	\��� ��NB ���O��4'f��K[|���L3���A�l��� ]Ci僄Q���{��!z�m�,�L7�:cN�j�uv�zt�s6hv������	���SW��P����%����P�B{\�&�쎱$������㲋�k�c��|n���Pb�͸L���̿0r\z��W�
��p��?�P�h<��B�
Q�e9�{�������EH{�N�U^���N+aPC�\�04����q�a�*�'��$��tQ0{aԗF�;�!L]?w��f�a�X�`�wp��)��9��J�q���+&<���Am
O����|+8�*2+
xwc���o7ǵ�ų��1�/-e�z6�+;����IXg��k����n5�*jK+���AVc����!�&`�k��qh��S:����0����ခ�&�ά�Z��+3gz(���gC���h[v!�]�!_����,�gj�`H�D�,�+������r�]�L@,�M�IE�=����]w%}�Ut������Ғ=lG�G-���>_��wz����N?��9����Ԇ�yc�:�t�3Ja6���Fo0<Y�����##��G���ږLj�9�[=%u>�q"�:
�y=���0:!Kn5n��^���p�$g�����p�e�cP�j��X��+��]�қ�W�{�'Ko+�Ck~���Si�]^]�Le4���>PH��3LS)�����o+MO��vJ����nNƇ���x�7G^�/vnp���^��ڡR:��r��� ��\$�Aݡ���J�{u||��Ϭ�`ӣʦv*:4�V��ʿ����r:.�J�K
;M���`�Wo�Y�J�vs��sZZ)݂��,�i�'�V\kod�Q~V�Z���
��<K���&�t�8�H{M{Ng�#�=Fd���(Tc�)'�`�����}@�������=���|4��<eJe�#tn��6��LS����^���9�� �X��=��d�Ww�k<��w��u��#���7Gu�<#17
�S��Ԗ�I����R��"Ǖ��Hb�&D�Z��'>cv�[{.�sv�*��3р��o�eK�X
w��L(���Cb���h)����Tj!9cE���e���1���l��5St��<�Σ�IqC���?���
 {���������R������mI0X�?�$o��pܻ��0.��b������s�h��B�@ �����^�=��b>Nً爬Vl�S�eD���{Dj�ӥ5�h6�9:��qT�P�V�i�p]p'ȑ�gf�x�.&���7H��yZ�J�v��[M�>�vi����:FH6�(�Ǔ�%�����IF��/�kiF7�ͯ9�r��������R�DV+�� �����jl�&�`���O.t|�M,X%Z��P*w�l@)O����d�H�����gSeN��8i����Rk|W��H�����5��%t]���h���m�s�O��{E9��ٛ��^�G_���΁���$�VO�h��K�,�>��L����u�M��Jk��&C`DO^Ξ��
}�ފ"�sq��Az G�q�KKh�v��?U�a<1�>�}t�ь��������?yp?����7�l��a�,�U4p�LB�����Ґ�/�fX�7�ּ�)����fv�1V;J����t41���h�1�ɽ��*CY�l�YD	����s�꾮���C�=V�V��V�ݻ�#��n��p0o���ƒ�,5wn�cF°�+΄k!T���҈�=�5�2����\rbJ�WtI�q<�i�����X��%g�#�V��?��FxsO>͢:�X��0�7L� �^�bx�I� +Ã<���!�>0��������-V|��6����d��3��O�|	��O3����?)�ؽ�j���6����Sb�VĲc����5�އ���5�����0'>u�' ��=�tU|]�#���YrOAP}_�A��}={� VX�=�85љ?n����aO���ςV��т�����V,�,����w1��
��) ������+��O��K���K&���<uE��9E�V4����i�=��wl��?,��^�H�����Y�ns�y�:y���~޸��-��M�oA(��p8��y�߹`_�����ɼ�)i�U�UL9�*|��렢)3�rS~^�p�*����9�����ܥ"�2��0�ϣ#vR����{J���X��#���*-Z 8E=��n�Aؖ�Tk�$_\���^Δ(Բ+��8 R��͗�tc�G`pډ���&�0V% ,(/|�Nݷ�I��L�2&��4�#ȦFj�Ab'}ib��1�s@|�		�AXoxѡd�?�ky���5+L�0Z���""+y)x���Q�J���w2�"D��Ȩ��KH.���m3�R�*ղ�E��:��Ȩ\ v�K :Q[��TAtj�l��= Ԟ"ka\�/7�<]�[���T[iޣ�Ze%<��G�3a,�AK���
�YYj�[oݭ��Q��h���Z:�����y���Y�H�*�\�S3௼��!2<W�W�d�g��j�3���,T��T���������X�=� �h��<�J�΀Z`��LS<4'��R���[^�"Ƶ�m��a�q�־�EJܗfZ�<k��
� �:��-U�Qf��Q����{�^��!m��Q� �z��O��AIzA���������!�?U��Β�.s����?b��T�IwPW�(LrVλ�1b2�u	(����r��,��*�x��Z΢޴��8�Nqg�N^�b]��42�p�!�8u� �j�Ec�~����j���Zg���l�	���Z�d���9ۯ3'ڏV���6�����,�E^�}1�7����A�\��gX&@�V�p";�̦�����U���$MNj�"�.¬'{6��8p�p�$���!��;��݁�ٟ��
��gN��+���؍�$��L�P�C�3F�1���G�ƚ�8�1h��ͫ�n��*��1�f���U����4ʱ ��} q:�V�$y�Fh�6J�OΞuо��>9:>�N��7,��+%�}t;�ro�*�P.x�:Tr�K�/iG��
��D]���9�^��0�F bzѰ'*.㰨y}�L�Q�r�� ��Z�@gw<#����RS9���*�����Qt�e��33o�IQљ��0����Ҳ�jK~�Nu�s���Ğ���p��
/>�1��~Nu��{ڪ��;^�ٮgE��|��bU���@Õ�~��!�{xۘUr�Z �)X�	���.��Kox���J��(^ ܯz����j�!+Xix1�},��ﰥBJ�4�>���
�Y��V
�Yp���*P��P����_�yU�H���KR��dn7��Lz�-�����͏�-R��k���F'���>ַ�R�C*I�J�:�t㔏W&�~�x�z;�jJ
�U,�v��Z<��{��~֋X�����p�5-��iE�ٯ�Č��f��_.�x�^������_���1ЋL�K�۔��<��Z����^��v���ę]�_��{�Q�DG+պ[X�˔#ޘ%~'��6�"���w3���|{�-'c��ۏ�S�ح�F�k���"�\hU~�e<q�Y�;��7v��`ܱ�}�h
�����Ds'ޕ���'�~�V���s�WS�X�����Q��ޙ��,i��Sa��ԓu��>1�4=v���5��U��(�bDs�aR}>�n�]�7W*�〲S֍q�s�~�߾r|��
;���73�p=$��\���=��0fX�S��]�Xk��,ԫ��Ƶ�*;Jͺ��H�g^�F�l�ȭ^+����|�O/�v�������O��յ�����z�������?���lov��:_�����������������?Z}����_�*>/�^�����a{G�~�EJqS�y#au��j�O���$R��A ���2�����BՋ,��Qڟ\`U�x"eUՁ�w�������4;k=T�<�.1�"��f�Q<A���Ɨ$z�0_4>E�=�=x(j��N4�vC�yJ�O�����(@ΌM8G8�Q�̚.}�(�����A��U��ϡ:��Bo��+���Eu�0����p� ׋�S����}��(���ySw"o�r_��Y~w��!X��_��ӽ(�ϰ(<ެ��'�Ex�ٔ80��@�v�!qp$��<��_���f�ԃ����$Jz�Og�0�{T�1(��q�I��X�Y��Ijsf��EW 8��t!9 A��4H0���c�A�)W����,y�%�3��Op,�x<�Q���0/��˻�ˇ�R�ل�����4n��1��N1ʈ �o�VK��Ҕ0�-z���q����
����'�_���Q�1���5��>'�8�1�V�����X�����#Z@�4��
9'�`i|jY�/�E�#�[�����J�t��N����M{�GR�>Zz1�1"x⼊m46����0�.��$h_	h�v�9�Y�����Ga��3X���g��N0�����^N��D���,:�Pl�1⃮q�{��`��"�3���Ot:���w��VM���)n<6�M	�Q6	)D���i<�'1� ��*w�]�:v��{qQr����p�."��9�ʼ��>�����A>�쉇�pd����ӭ��Lv��S�ע�*�F�� 0��<#�ENƕ��''� P+�ӡ��ց�z�Z+N��* �f� ��UNC���X�	��\���A�Ą�`�
�8�or��5��|#X^[Qx{f6!^ü��\����Xs �_H���g�ƻatā�nN<^�n��A �"�(�bv�K�Y�e3	���z:Di�0�.�����#q�Nd�g ��KB�G]���)���40��Ƕ;tT�Y$�=��#-:� )��T�8���:�"+&�b�(�˓厔p"k�#�Y��|xI��G��� �L�nGt=�ҭ��H-x^*���T���M��<�������p�{���(L�}�d�P�<%*�<y&�Ox� �HI8�hHbT a� ���$;���
�̴L嗀�t�L ���$�4��H��iFC��0^L�$�E#�� �{S`Ǹ����K��c�yÿ`��O��O\��c>i���������$���RD���H���4	��p��P���A33Hfx5N>=EsV��UYB.}����=J�B���xT L�:%����˲��Oqwrv�u�ˍ�Js+&7��B��8���U��&۸����p�@f��I�1(8Ɵ��a	؈r��U��o�@8���D�2��	�V��togc�Б�Y��>!M���ĞQ蠣y���C�{��7�bQ�V��z3q�%) .�m��]�L�Ҁ���y�I�%�/K��pO55
tp
��н��F
�]c�2��h
���wH��jEzۧ+��(w8t\��~�kq7f�Bǝ��#�����B[����{G�x��)|q�=���c���X<��է�9G3�pd����o�]c����B�Y���|�* ͦ.�P0ŸHS�K %�ߛqG���B��F��I�t��EG�]��@�^�N�I�{=���׀�֠UM^��mI�
55�%b�K�`��+����7i�Y2 �IF�h��U/ӱ�/�� ����Z��a>�td�Hҭta����0�)`vB,�qI "`����E�c\�s����ab5S��A��*�鯚vcԨc�-F[պ)��6��&K�2`8]��S6�O����g��x��3
�(�s�Є����I]ߧ��wA4����#ԅq��&p�:d��Nq��ݠ�/A8�O]ja������]ll��3h"����� �s��ف�8�p
��Б��#�4Y ��w�
(x��z;ރ1�vP��(��0#�6��9�pd.������yTDw<�x�EJ0S �%��#�"��5�(Q��Z
��.�	,W�)j�uI|�RAh0�	��+K�	ȯy��\E�6�D8~�%�p6���G�= 	-�5#�h���_p�vH^�KQ��k��D$0決+�r�I�9* ��]���>�r��~azfs��ۢ[B�=#��&�:&�4_�J�,+��NB^�ED&��m:�6'bɫJ0�%̚��HIev�ћ�1�xh	�v?�z�c�ǐs�Ms�B�4��c"˖ׄ��i��]^q���$����h���1�_3�A���T�8�D�S������DUv��hg̽v�<ٷ�X���5�	2���_"��ޞ-�=�P4����a�S�z����B�yd��o���(������O J��w<o������K�^��RRp{�Q�\DËDǾ;���6�e��7��������/YG)^Kh�v�6QV!/�ݣ#Ro �N��Z���Pe+F�5�Cxk`x+�BT5&�*B��
[_��^�6��й������n�,�&��41fq�,!U�"t@��9���E%�òV��EI��,��GP�D,�2�І��@�0m�'�%����0/�&D\����(j�6x�R���D���p8�)�j����������FC$�IS�h�yi@<�gTpƼ�Bt	�	s� �(�^� G�	2�������r	v�L��VZ�=��Sd�-�6 ���6��M��)���>LB*Y��0(��RW��k�� O��i�Jdz������&�jS��*#<�'��1)��+ҡ�|Vn���^��ZGvhB����`��A�Ң��I��.?�	��H�	mTָ��6�������d�/Oe`_��%��Y��V�c`X�#H=��`��v������n�b��e�� ��Ş$��R���t�I8⻂������,�����}XhA]+����f��M�C9��Y�	��4�J,���
}�-��H���9���E�~�Y^}@�֕M�.�_�r��jYd����'�6V���.����?�E��� �h�3[ob��LF!a5�z���ȋ׫�)��Z�C�r��!�@���R ��<e�E�r�Wh��킮ҍ&�$��w�Ć 5�у���d�b��۰5m)k}�����;�
4N�Y�I
�|?������d�0��:!)mNt�X���t"��^�0�$� ��,��M��<f�J��@x>��!���.�饯�������qaD`����A�}�,\}�53�x�%.���y�W��Ym�4�ԣ���yj|g�ct��a4e�s>t@�I��eY�(�Ӝ�r�E]V�]�H�2jW���%�b8r0U��'�] ��E%Bq�cV���t+�Y>�+�RH����1������,lZ Se������#At�a�.���."�N��ƦQ��=�#�|������fQ�N0G�$�'F5]`��Y�I��i�M���ލ��t�kVy�"�#(��/��Q"00s�r*uD�"�	�^<���;Y[%#o����x�L��]��&���x�~V������i�jlҐ��Pw�8���!+9E>�nϰ}����6�;H�az��tːܘv��{՟��	o`�gr:�=*C ���i�v�`�!4����:����`F���ڟ���T��E���E4��I�,��2��G�!�|��*���}�!.NV|��i�Q ���C��xk�t�7���Ὂ: /<T[�nL#$��=Oy�(�Bq�w��AÙP�DX12�8�T��]5��B���q� u%%H:
߮�K�I��;�T3�28�we1eff5K�T�&�ރ�sn����M6��Hv�¥'&��n�4�\m���X���a���j2��cP��)K�ak�BwR�|����^������	;�V�]���EcA_h�{���h����lz���]��â����֩��ԛ3 Y��4�nĴ���ܞ�0������OT���U���Ek��H���n(�HQ�&���]VwSP��A@8��O����Q
m���	�!<t�mW�v"�q��s-�%AU���a��ܱH��Kb{�F1k5��#"�}P�����MC���l�=t�
	�l�Cf߅�t���Hi�|�m��u$$� �s��X�<�����N�*u�O�˩�<p[Y+�X�ʢ��Hf�FO�T��B�"�ڌ�S��vWl���a�E �ˌ&�X����'�>C�%B;�Y�s��y��H����
 (�d������X`��Z0n�x)�<��5��Q��C3��$m�.[vf�!Ɲ���AL�l�'�"Ty����}_s�Rk�N�dx)>{k�a�L@��bl;a�JpEj�^1N�\{i3�R�]?�:�+�g�Z`��^��R�e���	��ؗ<�U�I&d,���7�H�ҙ�0�&4c� Ňdq�a;<����P�?��z��׋�z;�s��㛡H�E�=a7	N^ܑ'�}�!��Nɪ�=�ڬ���=+�O�u��
#*��>O�S.��I3@B��sGjQ�q1'A-<;C�F�m�Gj��&?�/�e�2�@�PY4#&�QY0 OpJK��JxrpI�%	u�&����t=%��Umy��zF֦�9��9�H�\���>����<ry�+�N_���ॾ���`l8 ��r�(3.�Ù��q��`�40�h^�E��YQ�a|J"�X��8,u��W0��` jp��ȡ7��I�0/�l��N�
]���7�I��JL%�M}��VB՛fl?�� s0�e���Y���p@Xȳ��7�s�D-C�=a)���곴|D</u��n�&�9��&�̭2��q�L6,�Q�L�	t�C�L�Ņu��ᮔx2) �7��������1 #9j��^�<Z���C]{HIr.>J9@�Fp��4��v��>Q�r}"�X��	�0$ن��z0�Q�u�{ 	;�TT+�	>;���.ݭ��g���(��b���+ÅCe�R�q��Jl(N��0'Ɍ�Qt��a�:*B�ve7��z��C��1z$τ[�j�ѩ��f�S���8���g���Ct*-c�y?VX���Vjg��n�hT칠k�3�L�s� ��3��:������I�x)�����,S��e瑈��A��4/�n}&*����?>�1�!�`"�_f���w��֚s�U��x���-�@.����_V�QE��)P�Z�1n����,�r�5
t1�g�nK̺jIF2�A�s^����r6p�ڸ�B�F�d�P�QKlð����ۜ{�d.�&�yj�dGQ֘���ÿLȟ^a��#���#0��^�
O��D���-^>�����a�6��Z�H�S#�ѵ2�U�5�.�F��� �	�p��x`p��^R}��px�w�����Gv����H����x�Ð��h(����|:b%��hE�D:��Yö�"��Yg���H�����K�p�:�R�}�we��*�P{��˛��'�@�a�C�E'���(HD%�\�)�&�!��?o����NO'�)��έ��&��:����I��t��A��,{�X-'�
՞��y��U��1Ɋ)G��5�:�k��<wR>����OMnC�sœ�Rz��)40F���(��F|�l��c���)̈́��h`ad���e/�\o��N:H`�d�)JӼT\�\:��NM� >��$\�<$M ��Q��f�0��s�H�m��ay�(��Ã�#�D�`Zi/�#nt�:�&��}t��˄/��5��9�NdD�x��"m�l���x� �a�}�	�gKt�7<�
�C�"�g�$N�H����֠�G��V��$&���(�"L�T����rm�F���� ĜSs�$����hI�T��XM�E���ح�F��%���@wuml�#�s��fƉ��0�]9'Q"F��u�&����&��Hd���h'�U�h2�'�F.X��P��J�?��޾���p�,���۷���)�4r�ހu}5�a
�TH�E�XzȦ��xal��I�`G�ʘ��N!�.ݳU�II�f��[q
�3�f�15 ���;�wWLؒ;~G��5�r�^@�S��*=ʎ���G��|�-�F��ά=6f2g*�K��JAiy6ǋ�"�0
Ph�@��^Df��A���PH��a�RhwfiY��Pĭ��[�1S���<N���G��JM3��L���fl���n��HB4��
3�YK�d�s�����3��ecaY΁.�+G�?�
1ó��b���Ի��H�\AS^
���4A�9��@)��i�j=nb]i�9��A��<�L�"7�q\�K�M�v�8+�8�Q�I�o�D���E��Y�[3���J|M:l�}b��Ab$P��$7�nb3'Ӹ��!ˋ�0���pb[_)�	�ڈӅ�c����Z㷕t�l�O ��֟h�����U��+���H��A)<���iW�`f@��Bcp���T��nua}u7ڟN$E	�|Щ���[by���i����Qz!À�P����\�	"��+��@&�`��NQ���X�"�1�>)?�܇���{+�>lo�5�m�L����|�߁��� 8�c�+��4�HY"8[fdǄeD���h�+s	��D?Y�ǖ$�6��/п�>/J���alR:�Yj�A�Z{H�t�QqOP��N�C�nJjKvnؗM�q���r3a/���2�w����L�K�V"W��g�J!+��Ď�����ļ�������gqb�[��2|�q;�F�.�`�b�V���Y�J���1��@BS~�N���#��-�R�Y%n��a�`��2����T���	���ێ�#�b����U��2���8FQ?ȍ0\�<��m�ʥH��>���b:�G�Vgg�0�[&�Y���~�R�ܛ�Z�Y��m�ț}���"��	ۦ�8R{A��N.�v�99d��I6)�v1��0�L�
Al�h��h� ��ZML�	%��.'��Gd"o��]3W? �G�K��h�s�=k=����$�A�Y1o!+�Z�U�D,�>�Q��&�jtf|���$Yp  j6F�S[��hW�s�c�H���qʻ��N�<�3�oT��6�aϧp��%`g��]���Ҡ��4߀�B�t`��L ���T��X�1*�ׯ!�B^'�Q�	=�]¨����e#�KY��I�'��*	YǰM�u���54�L���$` ���א�����&)(q��7���Lƈ�U�9I�1 3�A�6�T��Z(�N��Q'o��|�[`*O��*.��Q���e5�	D^-���x7z�H	�����T��-,h�
���#[kl�x����N�Q�CR�+EĉH�Y`jF���1U@E6"�/��!��b&�(+�J9�˪JzA���E�{l.0bm�e�6�J���7o<@}�Yr[�T3h�2ٕ��!'?ZU=�j��	��0(��mJ��%!]kg�9���ߠ��Q��%X<�:�x�rB?�0�%E���anBk �L����,��X=.(�&t��`�P���w�7����(�<(6�Y����Θo�1f={*q��!C�T�@i��2�:|�t@�ٔOsS�Ә`�E��ݓЋ���ԝ�7�� ?�^��
!xC�W�UG%��z��(�����Iֿ�������⌶B����t�#\��G
��q��(L���"�l�c;��9��TK)��5�Df�B��Ņ�I��x�Kƃś����f�Ь�����yK��Cn 2Rj>�~�q��Bf$�ج9r���늖��W�	~%94ƙ;�zȋ\J0�K@ �°���=��p_��ۚ�I����h,_��_�%*Ne(ό\+߫�qWM�rG�-�F��K"n�Hlq�]�B/�g>eW�_���gA��I,�iO�����/�(��!�c�D�Њ�ʓ���X�w=B����p�&�rKr���C���:9�TF݆"�X�(�E�c�[��۬�Hb�c�Q[�*�N���I4�"��;W$����#M08�4��<����|������.Ud�Q%�a��	Z�+XW�,qV�2�3����p��,�b^�LG�;��3Ƅ�LP����'��Ē�gX}��c�UIl})O�
�kϛ��g!%Y>������n���bu�,���)K�:�޲c)�cVm�Kw�XmO8��1�^�09����O����>�R:ES	��δ8��4��g� u�J@V8j�n#�{8���#�n��[���O�U���T���.9���1�j:� 2�2]�	�P�L�)L�U�9�8)��O �m��ڄ6B�(�0�4��6��L����q�]�T|Ž�8 ���j�?�\�AKC�ovEȁ�AFʢ�~Zל��[��q�A�KP�5)�A9d�_D2r���Ŋ�R�*#��L�Tg�OT � (�_��[�7���5�҄l1��ld:�قo6�B�W��(�C����.�&&��3����=;��iG�a!�5L��z�{XU�P����Tn���H8Q����e�^�A�hw:�|�m��J1G$��e��Y:�#���P�Xͮ��T�'�D"��� �Fb�b�{<a���ap@*�K�U�T䞈�[r�.��s��\���J�~��;���9鲆�����[{r����h�k�������҅)�)5�9V}�lK�Ҩ�&�ܪ(����eT`Ԕ8d<)���f���.�� 0�ҩL0�M���$�c��@�48�R��(lI�$�51�PE����f��6G��,��@Ut���a�P�Q( E��4J� �j!L	w�
c*�-�7=�]�\�"��L}l]z:�j�шl* V<�KYt�Bc�O�)Σ��+2m(���*(N�rP2o�̓���m.<0N�ʭ�7������1���pK�iq�@��;���$��0����aȩ��0����b3L3��2��\�~P�1�h�mN5 WA&�#H�Zׂ�	�K�3�������X�FG�(�Ut��fJ�h_36�0�����j��TҦ�
,��7x�q^0a3*���s�����N�jS�@�vqa����bb)ivY��9Kx��b0;'z�#���K^T_X��mQ/[o�%����bC��p��ZH�W��́�J,9$�Z5�EO�t*����%H	"��d'�p� m�	��qx9�8��:��*�����U)xɁ�BV
5�����Y6���T[�+Sm�+�mx�SZ��>E�O�I�T����H�	����e�����oϘ���?>^a�N�8r�gҫ��Qs�:M;�4���X)8��l=�� j�Z`K�5���\�V����n��n�i:�h�Ҳ���djP1�lj||�N;�:� c $F�jlZv ���i�����͈���FN�������Vk�M,nud�1���G��]�������V���&���)S�Z?�rvS���G~��]Qņ���k��uU.�K]��-�klC��mZ�mЄ�g�y*�tjY���I���H�Re.�$�K��L1�T���k�^Jvy��#�;̨�I�T�i".-�O\g���U(�F�%T�G"�I�4�sf�- 0#���PL�R����h����H�o��
N��~����3u���<�V3Z��Ĉn+e�m� �y�S|V �(�%R��B��DF�?���w�ħV^�1w�J��XFl][��-�P��Arc�C����{((PǤЕ�l��ju�uYܿ���q�ݧx�n�q؞S��h]F�� g��.?��U�/��0��q��ܻ�
�\�Ywrd� ��\��F7`LO{֍�t�Н����!���ں\VH�Yl�y%j�X�H��Qr!��Ì�!ݡ�יP�R#��q�?�FOX��J�b�����[$S,,h"�\.1�Z4!�����UX���V51�b��z�{��=�4��&۝c�q�(�:�J�00#�� �#И`��oʁqFf�uBi�_Q-��F!>���K����Ɍ/���ך��#,m `̇K�a~A5�h_Y�G�}fsPAHྎ�G�ws1��a_�S�.�����5��%!����ld�6T�[f��gb3q�%��F�nܿ?�����P�0kY�ӊ���u��%��� �xH���aӄ�3*���p&q�:��}�������a{��G�b�P��/ۻuu�O�;�q��;V������Ζz�c�>8���l?�騝�[�9�?6;���Ξ�G�o��:�踍/l勺����{/	�������/_��w�:�tCUz��A��x�s��x���qǤj�#vM��>~����>�@~T��۪��6����a�� ��wa��q{os���������c��3�f��� {��:��v7_�����mX/�V����tAk��o��i���:M�K@`�����`�����m ������f�r��6�tՏ���E��w��E��ꨭ΋�����N[B7G�w;��G� 4h�쨽�&��}��:���ޤu8���q�6����ѣ&��ǎ�Zf����y���zoW���a��%����~yء�vp"x���3��1��
�`�G@�}������Egs�M�ǣ�]Xg������0�a �4���V{���s�`��%�uut����?�w�G@�^��#�+n-< �{�9y��p�4�@������jg�10�j���}��և�=X(:c���ׇpް��9z'p{�w�KG|�p+Ї���E{{��a��}XBI���8Z���j�t��J�MyG�G�
��y����l�q�~`�۲&0;� ������w����JI*.��yD�d�`á��6����H[{�>��p�
W��f��J��� E���S,���?�)���1u�)g�bb��#!Цu��C̟���,~����Cg�6G���^n�M,�¦;��~���b��Ų��K��7��+�שMK��\�:��Gdy{ �� rǃ$���.pao%��r�xHdg���N��2���u���a��{���0P�œ��:��!�nM�|����Y����n�/I��:U�b��N�2���	�&;t�qj8b��H7���-(��	���Zr�F̀�/�f:U����@���${��o��ԌLSCeY�"j��R��]=�?5�]�*[�M�~���u�7g�wsJ'ЧY�у��Db o>��DZ�Z�\Q?`u�g��Hu��3��X�k�a�vo��ƽM�'Z��U{�J�a����3[��k5�dZ�q�~�짛��5�f��y����^�I:���d��UiQ��r-�=1y�XA�`i�%V�vU��`qg	^�
^Gk�a��]�&�Q�p��D6��u�K]9��]KV�1�!R?&��F�uqq�<K��4;k�p��3PC�0��-m�ED�v�������h����F�]!�#W`n.��z�DY]cK]S9}�J��M9�t�+M����0��6r�S�`/������g�>�%<��̴���G�;��;;?����S�N5����~q�i�ϳeDˣ!�ÆI�x>�&)�X���u���G���r��Fr*s����-��o�w3����3�J��I1�mK3u���� +Yh���p����m�c�Ɓ4%[����xq�~���I2Śb�%���N/1�A���}�_��PL�@8��5�za$� ����x5��7eݱ������ovv��d	�Vm7޼�4XxH�r8���G���H��Õ���^j�C��J8t9� �,E?f$�z]J�����N<��L�)��G��l��=��h"fH�3G�k{���p!�xu��[���0�l�u����W���:�q��Ô��!4�[1� J���e�bpـen����`2����?⧗v[����n�9�}�>VWW=x���Ǐѿ���>�>z���?|�=��V��>^�'�����}��R`(y�m���9��d����sG��ߢ�/{��DD[�����I��������K9�J7\�Pen[ ��7�T�(9�AL`?�}`�C���4�NLKt<��F�
�F�-��j���>��a]�	����ooy�!%,� &B�(8�d�]��7\�z�@ G�h�AчG6�5WO2O洝����G�i��xG��������rhRR��5�oa��qK/���,����a{�N�^N��U/B�O�����ŉ)꥔Q`$�n�L��=�4�$�\�o~�J0�{��j�{�dY��6��M��\8Ɋ�4��c�&q;�K�����.]1�Y2=q|1�^}�zAV|\�r�>W�+b����n�����y�.QP��!��N�L?�7�����aT8ƭ���=�(�E�r���oL9��)�=�A��30����$�&���
>�����e�p4�]�s��t\�.���1�3�`��tY2�t
w��D~�mmb"L����E]{�38�cX,���������~��6���~�O��<�Y���k-�R�U�L5�������Zc���ڃ���7~��7px����a���e�Ӫ��ޘm{�žڠ D�嬲;�a�չ/���:��@~j���������tN���:�~Vs�)x#6ol����6ͫ?5F�W��������|����y<���h*-t��9�e��F(5�E+����'�J�a�}C�o��М�jKS���EGD'�Ψ�E�U�9]-�XB&T�o�m~\4�T�\a"8̙�r/���[ҿ�4u��.�P�������"�e'=��'��`m�'T(Z�K����T!�=�it���^�
������^aő�:�#���Fo]����բVj�z�8�z<��㼪O�iq�1w�S���ݢ{6+�5?.<�U�i�l��W#]k�z�w}a�_c�?���g�'7Tk2�x�0=C&^�L	�sJ����#V���q�g�k�޻'��k�K�Ks�"C3�6,#�۽��!羧��8Ʊ�2��i�иi-I�}P }��+�Ut���JMU%MD��d��G��x�#�ˏ��9r�$ƥG=����}cu����dmu�ჍՇ7�G֚��U-��J�7�_f���مtc<���p8��o��uX��2��6�R��9�˪��iq��������� �ZxL��9�<��?\�}���-���fdѻ����]���&�>�_��S��#���b{o3��o��<����b�5@!ߚ����]��7כk����� ~���~���~�.���Y��	[��ޯ5�o���=Z��h�p����ſ�1o6�R�dX���}m����`�S�9��xz�3.`��{��]�֢�X�V�|FǋOS�{�8G�/^� ,��uN�s#@/,� ��y�s�R�"���1��z/�U����כ�h�lu^�_����
O�|�B��Q��#yt���������~}@[�����y�Ƽ�W��_��Dyk���+! �o��ݓ.q4/�a��	_K�=���(Ƨ� Ne+��C��s؋��w�����O�(6� ��j��ҳ,�p�y�0��	�s��h�9��	&T��G|1�O�i>jJ�����f���  �UP��_`��i� K�m��	֒h⃹�x������0��O�~q�o���n�E.��BR��u���Л�w,-#)[�\$�,��y�a�f ؋	�=U��M���~SrQ� C���M��B����;jsu��%��H��u���'U[���]�@�����O(m-P�Z4��%��VS�u[)լj�DC	����T�:������Ȍ��S��8���Lz���]9�g����i���)��>j"��v�7�;���^;�i;�Շ���>�|��ٯ�;_"�av��� E�����2\��j��B3�6�2$�H�z1[?�u2� w>��R�3�����X��Z���d��^S��ʦp"�[���#¿O9L�1�
a��U��/=&��'`�I�`X�xޑ�Ӣ��g���e*�lP58<K��ʂS��uF�;w��F�d�k�κ�x�O1�_��=��Bcz�m�;�3pTl�Ø�Ns�4n"@���Z�0�p�E,7��J���],ܑ�pSd\���r�8U=cmj��7�M�j�8���)�1g����p���#dc^���F����QئS����E����]"F�;W瞖��ի�	Z][p��]�/N,�$CYF<�w��$���-�^���
K���OB>��VĤ��h�(ԧ�lhɷQ� �(	4L�WŮ%���BaN�ě�}�:a���k���S٤	��U��<-�T����=�
M�A���G����=��K��>:�Q��WٰRd@<PO��XU)P�a��'M����YYt�p긳zS�{�Cu�RZ}�W�ǛP)e.�EA����Im��4���1B"W����ȿ@�vVb�"�$<��\�ՎUq���!�3Gz�����O�5F�1}��9��g�������^"訸��X-Vl�nl�{G4xN�'x��,Z�B�m�2�"V�VinEؕ�ִvfn���Pc?�P����):p�0?1S�r�T_Ȑ��U�լ/F+
Kc驧/�$AS���Ō�q�o�i�Lu�_�*+�H/��JDrŝ��=s��Qo43.�6��zN�D}T�����]%�Ss�ެ7��]'r]-u{驙���]n���� S!~�8���*��IZ���K�v��X�D��\14�����݅h��\E�Vf�>�s����&�Z� ��b�iɕw�e�2����?��F���N���eb�i�H,r�N��W=�hY��/��j����������s�Ɨ�3K��+c�Ns��C0��e���9�L'�)Q��+}��vݝq��g��
5c���e�xkm��"f���#}�M;^!�(>�*�i�h9�p�Y�uwi�x�S�d�N�] �;��N��՝b��ٟ�����x,�J�U5���TP��:>U�T�w��_�c �4�`��>x�C�:�s��,*D��;uB�*��L~_'�_X��>(�������<�Jq弫����3��DU�P���t�S�h�r������fpO��Xm!|`���͠�Z��k�I?�l�ﶷ�*�x�i��coe�?����^�eB2UM<��*���Q�`|<`8�+P��S�m��+ϨA�خt4��x?U�O<��Iۇf�J;�d���pq�@�Q|'�^Ϥ���
���O#Lߓ[����5�2+�� ݠZ/�܎�3��Y��h�B[�Wg�ȼp��}t�؉Y��]'�{P���/��3���['/�w�d�})�QU��4Х�Zθj�;>��5'�X�6ҏ�����R�ܿ����I�卆f qx�|@֦��a�`Ѹ����@ѐ� ����&�X�r���AwJ�ȹj��'�Ӕp��¬�DlM�h$�I��ǆ[���lI�J|ك���r2}��~��R`�8�^>C�T�/��f��4^�=E�f�ͪם��x�A0�����%���YrTgE,jd$�*%�9����VR �0�2�R��ʠ�̓������2����L��)�3�X�7�lT���K����%r9	ê%���7��B�R����V�S���Zi���5�FY�E��(������\G�>`���]���Π���{볣k³���%i��x��xn?��"~�`�r.����%�m� B<�ә�t%"O8Dw&�d2z� nɐ��_�� u��Ε�7�Vi�P�ӄ{�N�����������D��+i -'c-,����{y��L�~���_/R�1IΘ��@l�V麑�H�'�*��Q+�5@����ǒ�
d
�_d�00��a��M���P
n�M���L�Q������߼�~�����΂�噜�E񄼖����u���/#]�ۍ�p�������4���~gc���'̓,ܦY+}��gh�4O�e1�hW��(����^m@=��^���m�ݻG��_�89�}�:pv\0�E�lOu�F|W�f��J��80��,�~���7׭��O��i�k?���`N!��j�qR�?�%�=e���ӎwL�*(���hC�&㷬�,�t.b�X�l"�"I7hw��ض��YC.i�����yB�yq���c�F@18�\�7!��I������ /��f���Ee,>�&R�`��Sˀ>���מ�?�$�EP�� ��F�|
�x�sF
�;�Mp;y��r8ll�\�a+F��:�M�� �ZJ$v#g��	���t�*�v�c��u������݉A���Q�O�_�	�o73U1t+��E������E�8�����ep����o]oG=��/�U2�ǒx��^��c;iO;��r������V[5"�Ğ�y���߾ة@�(�Y��D�d-(�
�*�.�VQ�y�
��:k1F��s��`��֋n���u;����	@HO&pl'�"-^�V��.zB��,��[P����EZRN<������+<*��M����	]���wЖzӋ���h���Y��v��&T�o
��ڸ��������1-���Y�����Z*�PNc��A�"��s/j׻�(OE�ζgڿL�!�9���y?��ܥRw��J|������ft��G���+z���m���_Ej+�1ayڞ��T�}PUo���w<[�}SU}_'��l�ڏ�.�P�c�}_3ݶ��:�u����ah;�[1]E��ٚ�P�p�4]�p춡Zm��m�v,�յ�o�T��٥Y�gut-p]�r���mճݶ��w�����vG�-�#�C��zvO��@�:��R���նoX���H�|���l�c� M���s�a�-��M�s �qu����m+�8�C;O��@o�m��U���^l\��봕�eؚخ��v|�c�0\?�����8m*�@+:�wmձMσΚA�&�u���h��k��ؖ"U+Zܵ=UU5�m�c��Ў����Qt���TWa!L�F���\Uu�7f��:AǦ�5M@X[<���R�<�r�8S�,�i�hmS1X���xZ[Q ->òس�f�V��S��<_7t�B7ێbؖ�*m�:���1fAɖx4 l�LǇ)65ˠ�\��Mq,U��r�u��ŤFb*`U��+�րl0� ]�:fGU@�(���&le��`L@m�1��XT�Mi��3pm����f��g �х96�X"ݣ�N}�vǅͤ��i��J�͚@:��@���G�\�3}hB`�`i����������S�-�L�v��ը	��ٶ}��F/�a���4vL�PtM�TW��%h��t,�V�t���[�Fg5��Pm��N���{�j���6��h��q%���T�j
�f�VaHmMu��m�Ny
P���Y*�yÅ橭;�Sm��:���G�K��-N.3�U�#aU�-�	�#[�`�T�s]ņ�*���T]��ڶ= ��S�H@N�0>B�N�:&L<"j����:���8%=�ok6 ����PF�dO|�S��mj�Z�S�w�c;펩vTO^�Ղ��{�0���Nn��ZJ���i,��qU8��z�o��p�y�Mo �̀�t���	,ڱ<�����������p�yp�9Ԝ3����;B�ȣ0�.��� �ؤ�3�Ӂ| �`�*�>�U� ���q����Xe���!-`<��h�j�6�j�p�� �V<�1��V��!L��;�Q�Z���D�h�1-��~����+����F�L8�ڶ�����Y��y:�R��~$=��z���`�}ǯ8Tש�nC�î5,���b]{#���x
����jv�n+��8RU�*�H���Ջ3�����xHt߰lG��,_�������ݱ�R�����_Ԝ�2m�!��C���U�m� XhÎ[�N�V:�l��� � �N1<�3��}�f���Xn��R�#�P��P�?
lNOϴ��(�`�v�$�̄i��:Ƶ׈��:�^�T��6�09�Ӂ�!�m�*%�ӳ4��|���P(�� `�|�Xm[U��}�!ww6����k�Cr}�����ktt8x|GW7�}�M�e#�a�4��zmͥ�#��N�z�$5�[�?�ྤ���}��r�iο�Cy��tK��?մ��E����?��_&-���?���l��0@���7lݨ�V��^S�l���S�:��������x-�8�W�P�_n�_@��C�ыtO�(�D�`5�N�؝L���I�� ��t
_[f�QM��Sw�X�o��0�{?�Z�;p�<��t@yM~/��X��ʡ��?��k��-����FSћj�� ��3������y��RJX9˺�8����d������f��F�'����}c�[�I�?��g8ާ������m���c`��-���Q�b9�C�f16'ho����F�ݮ���6�^R���E�{�S?�!����p+�ĩ?3��7Π	��"aӆ��	���p�*��3��Gzb�����r�b���<L޼�f��/"��KJR�,~��9�\�qw�h�]�p���/<��S^j?	Ɨ�
��	+8�dT�0ao��~3gu����+�d0g,<%���y@�C)��=� ���6 �Sn��|�F)��CO�k9u����gH��l$� f1L�PZ�l� �(���AK�6o�2x�6T<��b:5��+Y��I�V��f�W:�Dx�aex��y#�+���ʧ�V�h��vF1���$�U��D<Vhs�T�?K7���w�Txr��6���UUӵ��75����V���"-m�>B	`������Wc�g�)�2�Oɲ����Y�D�pG:�g	��ag0JT-�r�h�­|�d�[􏝹}`�%G����MZ��u1���|.�o�ޣ�%N&W� �}���q���'ݏ�Z�W�0a-��F֒��҃���%��������T��I~���f�_����-6U 9�������W*{RZV*0�-y����u��#��I���$�Ij�I6����L��$�-7��%6�޾���x}�!K����A�����E�Q��R2�ퟙU� ��} :�d�+*F��%�c���|�o�ċAes�nTa�y�MUب����쭱?���y2Z[*���5#
��LWc�̠*�@f2���M(�Pc�g��7\.I�ԯ�T��#Z~@�橽5�'�n���$:q��ix���H�Z>=o�����h��8'�.�����P���%�6vv����Zi�3��p߯��Z��	� �$X9 ��� �3�˭����1�F���ggr+������|�v�Ɔ�_�hr76��x'��!�5��8�O�uUԁ_��La
.R����I�O.>�$�C����V�|>�O���r�[`$>^v�|�� �䯉�D��`��K�ܹ�x�Yѓ��Dǳ��R@@�K
ɗT�dny���j�H��̗�P���F].�T|���J!Q�-�r������Okn��:�Za7�y)a�A&#��5v�O��n��'���zK�ި���y�W'u�=����Ԏ;��$�^�m7��{��\y��Q���1��K��΋��́���Iz$�Mz̦Sz���oc��Ci&7��/�1d�`%�`Iְ�[F��t����L�0-�[�EWW���۽M���!��1�i��Rn�=ì��K�8��.�I���DCQg�;fȌF�#x�2a��v-�=��q�Ỷ�5��5�5��wc��g��ͪ33s�:��� H��A�n#�K�@���rF�_i˲Ƨg_�3��p�L.�n� ���e5`m��[�=��2�N��A�[;䨠P�{�Ww�Q��ݕ�r5�嶱@�C�M#���L��0u���[I���t@$��Gx,;I�n�����~���׺^��g�<�.;p����%�nb	�kI.��A��X�2��Yf�����_����mW�+IO����p�)��h���T<'�&>�+��3u)���"w���$���=��u�o��N�=&Qv����?[���ԃM��Mw ��i�ﮪ�;]�k@�;�����r��嶱��7$�_1��߰����H�����͋&�?G��U�4�+��F������{������-��,Ũ��V�2���k���+�Z��*R�KϽ�q���u�Z�U��W��i��o��_I�qctm�|��:�W��x�Zj�TE��ofu����4o���R�>E;�I�FN�W|��?a&��{,>���f�Y�]�U�=�Z-?"P�y�mO���V��8�����>c������`�F���cJ�'�;ͬly��yXOm�y��nr��H�����dduT��4��\��fY	�B�e���������&&֬O�5a��|%v<�{��V�5ԫ�'
��K��������*���g�r۸��o��j�
�M������`������P�?��������yڼ[�?���d��[Q4��T��*���` rmO�w���6��On���>�Kw�=
>��U���g�'��O��<�:���:�>�tD|9�+r\>)�r87|�{2�]o��!��=Y���R�Ȁ	q#G(�97���s0��Iʋ9ބ�I��|3m��c����0V��從���ʌR閪��f�b�$7+�f��a�k&�-���2�X�I�-��ŽM�q�Ŵ��������VynV
���R<�[��=#�+�_#�(|Ba��A&+�������	�Iqt��7Z�d�+~�����uHJl�$�C��3�>�r~$}`��|d&z��h�Ի�R|��rH`p��	� ����=�aǋ�$"k����xD�M:���Y�6S���:�~~�H�'�w��0���R��1��gc)c��9�&�r)��OV#�_�-��X��ٺ����t���)�]��$U,_�囃����e94�<�x�Fk�		���?�s�-'"�[;��w�0E0���'��r���IQ;̙�|Ӏ���%��|g�Sg4b�X���9�)��������Ot�$(Rq�w���@CQ�MfG8漤�w�֝?H6FC��#BqÃ��!�H(�ؘ��1��A�t5�ثN
@�g���H�	�x@�m74?�D1�QY���4o�|��`�賐cG���q� ��pB1�t��Ҧ�u�7�%���n�z��\i�I-t�is���D���>�{��m\���B�5������}^(N����������%����0U�����O�O���_�"�������C��k��{�j{|�:9�t�˫�����Ovޟ�:�=�>w�������O?��#Ӱ��G��/[�l;t:�}��捺*F�_b0��K�����e��@����o��>@
�,8�+��1���dN�O�{w�'|V \�����9�epу��d��M�`G~nO�
��i�c?�����(����/��N��1�qFp�|��O"��=R��Ͽ�Խ�o�o��Ӈ����?}������������"��>9<��q��l���Q�����C����������탋�˷�_��7����ٿ~z���v�p1��8����J�����i�D�� ������h8�^���� f̿���	���b�������L(2/� ]������t���!�K��A�ԍ�b���<@�CxI�  4����3� �_��>����<�k\Q���ΐG��;Q���m:D��Y��R�n���3�3�Lt2�1{i��p��@by�O��oC�����O�`w�6�������������*��jR��'�9T���U��\�*���*��x�@��S��;;���7g�c^O�#?��1�� oa��c�2J���i�>1�@b�%��^��@��;��a�/}r7T�Н��"����!CI�`Q8����?�H��.DO�Ʉ���2܃)��	������^�k�S[���5ɇ��8v����w�C9(�Q�B�c@�Jۂjc"y4!Dt��	���$B7k9FP�t�x���>�'����I\�d7{�V8�E���L|���>�A^�^��jM��6���� ^y�~�7��V�Q��(y��`
@���M���cc��of�R�z�D����.�z�ߡP����ǇB���~�?d�l�q�$���]B>e�Do�{�?ll�-
�#ڴ�3�h��:��4P5�����hJʽz�!W,8�TR���V�T|a�nCv2R�B��ѽrߎi)X,%Dg��_�{�=U���|��z"_���g�p�`��(��i4b֯�|ͱ���;�?�>�Փ���"�:�����0��������y� /��$����%Z/��}� `��ǔ+�z.W�Z>W�z]��`g��+��!�k�C�?���?��������JR%��}��sv�CVRY�?����lL#��d�ܲ,�tb��1��\�@�����f���앟��)�5�/�mn�,�`�L&$����@6��#f��[u�a$Fu�Bt2	sR��Lk��)��rI�X�M��*I��}�J����ك
� ���/:�9
<�p��$�Iʹ'}��z.,Ļ:�$��-�%�v콋�n�����Tw�����C�T����V[.��r�]^v��3��!�٫H�i��u{�B%Y�<�H�v\�b�8ƟU�q�_��+�Z��"ѕ����G�r����R����|�a�(�Ӊ�d�35�*Ñ�����OS��������T����U�*��������|�����3�l)d�����Tf�o�<G,�T�	;.���Z�Ζ,��{X^�ri��׏��;B=�#au����߆���:���V���$U�����_���/] �� �k2t|��=�a3�ǿ�G�x�X�����*d��>��b���h��>C��h�ː���Pȥc��H��>�.}�����>nOl	$|������{���,���þ��ǋ��p4�(����	'�@�d#5���S���@��M�������l1mf���䲨쎫���Cb̏�h����#.`p�Ql�X�g�_���U[S��W��W�$�oy��m��[0K�p��S�#)V���l'hM6K1(���'ݾBmx)k����ݜ���H-u5`��G�)a5h@m�|��;� �����]b��c����#T-��źE���QK��>��)�q���k�JETRdJXn��VZF�ztţ�������07-v��㵘��(����EC�1󃃫ȧ+��g�o���)N�'5������W,&��<i�[ �F�xgx�܇BE��G��S����V�u=뉓����j�0��3߬;��M&��'��d"��q!<yI���㕇Ϟ���"�����Su������T����W���������i��.��So��i�"���i��9�wQ [��1~)�ES���[I�YU/e}�;��?(f���s����T����y��&x���m��g��u��L��+���O���B?W�ă�%��2�7"K������@ba8��o�/�6�@��j�s��*�0P�ĎC-�٥�� ���֮�����/�
�{�	�v�ZVG���V.����<t� q1�2���dJ��)�LY�Ǔ���~�l���i:��`X����T��}^�q)磀M2'�7t�0'*�m:���uw��f ��s�4����J���A��"��x������zG�������/I0�'5�P��~�t�m�G�'~��0E�gρ�$��t����I��H}��ӸT�:d��'�ODU��	�uk���"�}�z�4�䘒6��_a]�:���w��߾�g�b4Y����]�ea>4�@&���1Ը���'��~  /_�Zq�ea��+`�6ܞ���(	6���
�o?�8�;��c�ɻ��=N���J%�C��f�pO�	���Ll�	>���M1�]���Sm#�E��NK�����]R��
V Q	s��5�`v���?����Lk�iI�
��Qy�y��l��f��\`�1���-7qiS���e�����4��������ҍ�y��J�wE�z���һ~��[�����쫷���A����y ��Ys|�c�g�V��Y�B�����V��unY��Q L������6`�����=��@�o �W���MUk*F�����š�,a�%[�3x$݃�Ԭq�FH�}ʜ��\�y���9?b,K=��e��4~����fc�-�x��Nꌔ�z�	�1^�\ �+К*j�W�Z���/D�ŋ;��� ��Q��U\�É�@mEQ�/��Q4L�_U��ߕ�kY}v!;o8�]7V�D]XځWO;�������3 �G��;�Ƒ�m]�E���践�d|_(��L�Lq\��8�l�O�0+��n�4^I���b:�
��)��N�����Ҁ��|��'Ā�0��s����I�Z����{O�:es«e�qU-�!s�rUE�������gQ�l�z3�$��k���O��?�>n��M�T]e�?f��s%����v��*���UVw��.���%p+����$n*������|JTwʋ΃�ͬVi�iV�S�8m�9����j�Y�dA���W��+I��':����l�G �0��3�A�Ck��p�
� �#R���+��I%��	���C���|!z13L�Kg�N�^1��r��9q/S����'���|�-hZ(�}s�l�n"�]]+'�ɡ*r,��9���+�@ę�n)�5 ��Dqɢ%��ȖM�Ð��fn���v-��������W���������W�*��E&�����[�#�A��'9�kf�����8��m�P>�~*�ͺ��pxLGS.���qZ��L��w���h|7g�����Y����Yc�on�?*1�3��|#3�)�|8S��so���5������P?�`?���0���0t�aÓg��xn��@���!m$Zs !t��x81��8�p�u<���ʃ����7����Yf�?漤 �Qs� 2���@���wV���#G�����O`�l��tH�+ �=�Հ�>y��M)�,��_x'1�LԈll�E��ܟ@i��/۔K6":�"�& z<	�X)H')�#7��oЭ?����ƢB�c]mjͶ�4UU7M��6�f[1?�_`��º� �~O�����c�W�� <J'���NL�h��^~���n��9Px��G�h�
[��?��r[o#��of �L���;S�����t旂@)��� ,sg�����w� ��2����1����v���"U�!����@8������x�^������e����߆�x����o����F�G^�_���s���UL�,��+�;=g������јc3rk{l)�;�F�����=��D�m6p[7i�f��}��'^Gt��F��p�7�kh�b;���ɍy�;c!���}��x�a����kWdq�-(��R�;�x1 A����)�����x�ލ}���RG»S8)t,���-���;���޽N��D�5
�<q�8[h���7p����_��Ǔ�[���'N�XM� g�������g��>�tJ�sǏ�1p�!q"�z"�F��S�4�a���q���2��tw��8>i�DWz�����Di��S��C**\ e@b4�b=��z��}��q���:	��4��_셮�}�B S �f:���,b��#cx(�=�=��vm۶�_��M�y<u0,���Z�:����)�g [M'p\d3ût�}4�bA��5B��^�Q�¨�G���`��� �y�>��x�"}g�X7�vg�.�g� ���߅���`���Qf�X������+?��|#��.� <����;B�i��h���
glZ ��11��L^���?����pO�0��KL�$?:�.D��8��~��p�����<�e�eo����&�A���x�Uz�)��~|�(��-f���6��h���7��/��U���YE�t>�����޹��L��ڸWj���v�!X���*��v��I�Z\�Z���;F���A��I-)����Q��PnZUvM�����c���@^��g9^8� ^p���3d�"�����l�MEx�~q������9��g*oj_j��'X�S�7�֛��9l�C��)�*�<��Q��O!�%��Ϣ&�0�^	��,�|���;o ٷۭ���W�- ��s��%�1��V����l��6���_EZ�4��*.�������ݽ�G���sr�:��t�Hs.�~F|�����3�tt���/��D�������\��˿$���+F&�����2���$U�_E�+�_��o���$�.��gi�ו�������V*�����F��ބ�{�W��W:�LH�*���p�OHN�#|L��8 hX!j�|��a3;�^qwosc��(J'PtB1y�nw�4���N���wB~`� G�y퇿���N��`f#o�.��MP6=ʺ�����u͉�y�y��f����י/��d�4���w�gF0+83���kLUZI��?��i	��wԾ�6�V*��e��_���ߕ�{��p  �+�d�Gv��_�P��yI�Ĥ�N�:�W:M�n�"Ϩ6�"��n��,���Oݨ��$&���Ǚ8� F����Y��!ps��!	mȺ�F}"Z��̇S�A���*t��s��M���{�i@���I,v��Ban�] c�ҐAܬ=͕f�p�a�_����M��x��e'�i4inKS��V��{���5K(]���*b�p�>u�p*�~+�����>лX�JΜ��^	<b���7���\�B7�`�W��ն(G|h���8�lg�3��ވƟ��i��T�6��N����� ٿ�/ƴ�(��ꢭl�5�X���2�񽙇���g�1����b(������}���Ḥ,�8r����q�z=]Qj���w&��4O� ��߼p������dN�â���f��//zg�a<`:���|Q����<� W���EJ���h�����mV�+I���t����z��w��6A<q����16�}~���V�Ed.c:Io#�Cq,��K~��YN�֔Y�-�R2eD= 2����>9����>��p
l�a6���BS�U���MhX�!x�� ���ӡOFa�4Q�_t&P7^�`6QS�|}t��!_�����8��z܄Y&Mt){4����M���	�#gR�@�#���A:��Y�R�h��a�b�0�n��G����{ov~�8��{R/�F�@�1t��	+�w����͞���G�v�����đ�d+F8K������X�r��d�y�0�+JJ�mmn� C@����tv��{����q�BK=�>J]K]���_ҙV�2Sx�w�ɸ%���x1L^P^�btf�Ob�l��C�əP��7��X[�����rGs�~d&'�cY��M8[J4'��&�9e$k^��Z̮�v8#z�y<���aq=�P��`�2�	%Ȧ@P��p1�q�iK���Z*%����CuG}����nN���X��+����6tK����U��+I�n�}��v�����p2P�Z��;N�M��W�����택��j���w;��<z��z��~g���?91��G��.M�J�����%��,-�������R��7�j��"U�^�Ȣ�fN���i����N������㡼��w[�pTz� �4�_���T��rK(n�Ә��b�F����e��#��y[R#��e��X��k������pJ��Y�ܲ�W{k��x����E~-D����%%=��_3��K�����sg�YW@9E��l����:-�bS��X ���(��IiY��p>04!�J�n��B����1����'B`Z�Cv"k��lw��A��{o_]wB�J��ސ�˂���ty�ۃ/�" jPJ��3��6 /8 v�&�\�Dcz	4���Y��G0�bP�\�u)�Ͷ��S����5�g�Qx8PFkK%�"v�3-2��x'�6)�ԩa� /��	<���~��5~Ӏ՟z�&�v��J�g�v�٠^����J���<�9������IRH����!�Z��@]�ڄ̖�~�J��-��R��fKA.�J�N�U��`8�P�O���ե�&��)�M[���Ν�b�Ai�\!i�R����vLc1>�qx�s�U�ދ%���*���8ɂ���2��go�a�9C�;��B��~�I�;�&^8'=g�i�r0n�}��I��2h�P:��;�L��#���2���#�����u�f*W#�p2�U�7�N�[�>�����dP����v�M�烰�v>�!��qө���1G�i��bt洷v���]32K��FU��S���0f(s*�$��}�Π���ٙ3�H��G�O�0_en�ha/�b�dAu�?�p:�,i�?���������^5���p<ګ�����AYN9o�m,���ܙ�_լ�V�#�V��ּWx��� 
Ԑ%<:��^��k��JwM��_L0Z�5����I�����u���+I��oQ�+���x̻_�_����_�v�kܞ���\?�^ K��dz���?9��
ٽ�Ϝ� v/��Y���^���*���SF������5IT����������O02f�Rf?�5D.��"W
��~�HW�c��1�^'{;��V{�$vq��7���7F~��IW�۝�
�5 u��	p�(�4���G[ۯ6�����7���״��/Kժ���T���_����ϱ )g�oaR���!V��c̿;��J3��pi.@������V ���+�%�����������[� ���0�Ȥ�D>�k�p���l����{��ݿӏ���_���U���h��?���@�®��w���|�s?�?$涷���v���C��l��d�w�Tm��s�ZZ�����%Mg����迦��dn�p\�r r��_�҄r�O�/Ϲ��."��f�xp�|y3��c,��Q����*�������َ�%ϖGxzt�Ai���B����+�g��!o� � _��(��H�}��$x�K�T�����9c�F(A|���/r��A�X���Dt���"�^(>FL_����{]�f֤߀��cg����}�c�C�F=v"G�e�=(�?�V/��7�Q����ig�\��� m�W�*U�JU�R��T�*U�JU�R��T�*U�JU�R��T�*U�J�P���̨ � 