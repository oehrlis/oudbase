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
VERSION="v1.3.5"
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
� WF�Z ��zّ(迓Oq�Z�������R�!*���%u�R��d��L42A��x��1/1���Llg�L �D��n��%8k�8�G��8i������}������k��_�Q�7��{�Z[�_�N=��ßY��SXJ�F�A��p�����?��)�:����Y��ο����ɣo����o<zG��~�;���R��~��~�F8����j���v<�/�A����|��I�ej;��F�d%��7՛M&�4W�Ϸ{u����h�Y>�,Rj�?�?�P?��<?�����w����0�����q��M����3��ө|�ˣa����|:��jeu��g��>��\ ��c���yuo�r;��k�l�=l���9�.�,N���x8�N�,����T�?�'��Su�?瑊Xxҏ�_���F�,Q�t�>�<��|��pJ����8]�Y�0��(���iBG�?Og�:~�݄��+Z�f����|�m��g�rv�{o3<2�4�i8�n܏��w�[k��Ä���A<��� fQ�`E ���-�i\ц�QzF��S�:sl	�럇�Y����j�O:����|�H�{�A��O��O����|p��l� [�3�O�tzV��ɻ�@���\C@Cm*�F�z�fQ��	^w�z;��j뭇�ǵ`��sx���~V;>zխ�e?� Q��Q�'�/�d�������j/:���tMO�J���m���w���VV��je���l�u���~|Vk��I�>|��Ӯ|�\���Z�;����v��G�j��NNi�3��Z}M	�W>Ԯ��+j�^gg���}��������tµk�σ����ѳ���A��phA����=�.��l4R?F��T�`���y)my>��y�������x�C����zԫ,<�V��C��n��d^q�;�mP�P�>�N��3U��q�6y�F!~j�_LU3V���������~����;���}�����e:�����j���U�&��<x9�1��EU�K5����{�<�#
=�&��Ok� ζ�����M�O�m�ӨO\`/L`7�9�UB�9|�&�ћ9�K��?���]�o7=#�	G�{��kn�O����j��jM��~�mn��0�$���S�v+6���h�W�+P���k�>��up�ܯ�F�1R1)��1I/�ɗ����z������
(��o6\W!��H����+�ə:���ô$@MC]� Q= !��*T	H@�	��>7p<s5�CՀ��uO ��n@VT�?|�c�q���7/7�����W�?}�t=:��5Yҙ���y�Z#��t����{�A��Gw���o1�F<1����)���@7�2Ģ�4�<d�fM�xyj�c�c3t���ݧ�Øfp����y<��_��x�i�8��a���A�Mq۝�e>\���.�k�촼�A�De�t�����U{��A�z�7�]�eC]&�2�*�lj�f �CT���q~ǲ�2FW!+	Ԅ�#6����"U�Z�]2��4J
ͻ�E�R�Ro@'>S�8�%$��ӳ��YK��R͈�!Y�S�3@��Z�7�B�V���o:���R�	�Z �'iN�!#e���Z�T��Qgk�k����^p 襳R7�'�r��0��J��~�ח����F!Og�s�q_�o1�(��ʇ���^�;�å���廬�ac����hi��t
��Hz�/�w�ӝΒ�1
���8L��6>a�A��Ψ8��Ѳ�gɻ$�L�����Մϯw:!����p��{q���V��Ks�-\\������$Sܗ �Q$�����4P��Bs�<|~|�#��|�R��V�)`uj�hѲ2�����W�g�F5o�KO���� ��,�[��dȅ;��T/�T�e���$Th��h�z��K	�+AQZ�	������Ķ�5E���U �V����coH�^c�܃�����@�o;�`�u�P:����ٙ;:���<��Zx�UӸm̨� �Y	�/�����7���h'��8}�FbT7<�"�~8P����N�-��f,���c��yF	ZU��B���o��|u5k����w�_������j
_��f]_��p�]
R�'��3J[\�Р�������P�	��#)���)��Էx��uĹZ��ފ���g���������T5Ǫ�m�`t�I��Xw't��>��$3��?My��0�d?����4�����Gk5�>�P'��c�JĀ�E�`�>�
��H�g �&�0~�����V�_gQ�N M���i�����#��$��h�cMMz��xs{�����d���
 ��*�y]L�kѿ�4	绸���\F�<8����ml��9-~�-\#✶Ӻ:���lu��!R\U��cc�(֛�P+\FEڣ����F�hZ�+-�r�+N,�
��B����!6���� ��b��0�9�H*B�r�4+S��i_�3z0{�J[�6�MQ���b9��rL��a�ȍ]�|z#`0�����)lծ���0���UY�.����a9�����ۂ9r)���f�Viy�v:xwDwu?�AV>���][��{a��>�e���e�V�|�|�G�DZ@��t�ZQi�l���9��`�|��M }�IN�N�I4��(Õ�G;���}���QUn�S�};p�����.̻gr����{p4/]��^-�Ȥ�����П����C�p@�.�f��g������U�޿��7���w�G�l�a<�������> !��<z�������4k�Mڪ��z��u���N�7i��\�S���gz4�����܋��_"���g�z�<����:x�k�W8kP�uT[8}R�V�H��Ԧo��sQ�C�=��̽P�EUww�sH��yF\rL�*�]�;�W��_O�A�^�S��w���p�{V{�4߂.��~�=��a� �%0�g�OYG|�p�����:��Ω�,ce?z��}�������lpu�!��-��ug�F��Ҧ�33Tݬ׻��Ê�
'�x��n}�c,�:A�hng��,��#�,t�<���_O�t�����H�. ]B�p��@6����7ގ�RU�_�H��rx �Mg{og��s�l8���l5s�{�sy���EG_�n?��m���`��ݝc�F�I>:�
��f� ��j{!i���|�~����Yp��Gߓ����.�F%�|�ߨDy�'-�{{���[J֯�v��0�r��F�P��z��u�lܮ��r��*�IaL]��t�8��e֙gS�Yo(����rB�����dFy��(��,R�}�sy(k��Q� =zT�()D~0���|�����۾���A������k�~������5�����"���t��Uq��F�s��KxTZ{e]A*���/��0�_}���/_�}rнsw!��7s�+�W��#�|F�})����j��w
�G7��g���'E��<����]���;�]6�wi{��^���G�v�V�=���vB�)��n�|Ⱥ��lu��^�_���f�R=ɡ�d��+ڳ0o��������v�_�vi460dd5�3A��@Z�yA���V2 ��u�����o&@}� ����f |� ��� �������M8���y�!9�MX_�$��!���R�X�&��f���T��Y�� �R��5A[9�S��ғ,%Ḯ�V���K�_���$a�pQ`>9�Q�t��q�JT�q�u
�����$-����E9�M�>+�%"�5��k���ԇӰ�n6�*r.]�%��;��_������
A֟S���ˆ���� ��i�G� �����kMц����.a�Xr~���z��r���ΐk*e��e<1�q�Pk��bZ-q|7����}�^�1^5��q�:��MhF+���e_5G�;7���5;FF����"}��	�u�GWM����n8�G��{��`+�� ً֨��@���%�_&p_�O��נ%9�W��WG��x5D*hN�,�&.�>?'�A`:��W�3���F�;���s`�I'y4Um�O�l|
P��H,Kld9��8P��(@l�C�H���<�w
� N6�p��A�$*�^���iYw�?ތ7�� 0��5��{sB����1���j�T���f�����~��g�/�;0Ķ�kz��sZ�EhO���eӘr�V�k�(����v�.��i_.�AT��8���R��+C�,�Ka+�Ɖj/�O��;rl��mk����F\�X0�;<�{�%��G��kX��<4��q&���t�����g�y*4Nvw�Ɣ�B��۽���3!"Ĥ^f��Z[�Yp���ۊ���Ȭ(�"��e��9�\�`2��5K$��n��?</M��*Y�n{�;��{����	Z���`||�����U�o�-���`��v�}��U:v%�r���.h��lw>ˢEX-=�ߔ�oih�
��r��7�+����ђ��D��4�pB����s���~��ȅX>b����js�J�13�MӉJ1�ޏ���i��M���A�9B~�f+f8�PUȧR�(�8P*;���vp��~2C�l4�,�M��"2�� �)����'�h�^�+�C ��J��a�Qq�i����`��"�~0��t��I�S��w7j�����L�xyx������J;�t�,G����L��Єm^E�M��ɹS��[�V�_ �JV��@�j�C�U\�1�(�:��uݷ	Pӿ�M�_�ŗ����f9�	"��^��ʽ��(~�������Æ\��46�ә������;���h��-׮��Vi���QTs�J�D	��r0o��c��k���Z��/��Cf�5B����lxB��o�3L�A�Һpa�%�KII;���egl��'*������8�w5g�n+O���MQ1CF��\��[��1��ӣ4�]-���,��O?m�������?߯� ��e�kw̺�3N��� z>�}k�u�7X;��~[k���KC���m����9��>�2�Z� ��ٶK���E4,�Kw�G�o�`o��f���_�y��h ���4�i�}p���e�Vms.\@c;\�T�6�T�z�رN��+	P���of��-� %�Q�$�����M�-�����)����g�Oe���M`>��HQFg��M�m�xt�W�o!	�f�T'�:5ə�B������3��X�Ԥ��%���𽹜���C׸;Q(CBH��(���.?4��Z}JLs%�X��u����T�5����O�n����@�ǟ�(��@�9d�>�� M\���8;�s�P�cNn-��ˤ"���u:5>3�(���T��LAΥ�)��جɞ�YL:��՘H���õo��?���5~���ȂK�?�F�s����k�����O�k����As$����������<�}��οv����h e�=���7Q�.Cb�.�&��	ʻ�jͦ�}���~e۪���kj��L�+�&��;D��$%�U�:����u̶͏s�^I����ou���ǝ];*~9o�w�7��_{v\{�.ݻ����DA����33���睭��:�QvRqY:;�������~����� }�A�me�|�A⟯9HD�� }�A����5�k����9H_s��� }�A����5鷙��o�ی7Ǜ����A��]�9:��\����K�q���_)�(T ��p�O9�8�@@��������9���rm�k���L���:���:Nv�M2u$�[zQn���H7��MT��U��T�?��5�i��#Ά:�f�T=��$��3��9A����c2����bu�mx�*L?�N��Ǔ����Iy��7h|���؇S,�l�P��?��Ҟ�h��"�L>�_/cb�mϦg�"#�+���-��s�
E��㯐�5/���R��I[%��5i^2�uS2��M2�m��r1�v�H�X7IEr��<����K�HK�R��T5��T$Ab)e�Vf93�>��,wڻ�w(���h�P`�[̅�D�?�D���5/K�qH��,�כ#����;h�P&��z��rd��x+ɖ���5^���&�^����渙/�V�4?���ci拟�� �� 	�J�a|VA�K���n4Q{��y�����& n��H<C+?�;Sȭ��s��LY�CT��~~�j��Y5^�{��
fŮw4|%�A��ac�I|{X��@pq�H�e��k�4��91ɲ�qYV7ϰ�/$=��v�J���$�['P��S7K��}r��͓��y�+�Py���
gٙ�)Ƽ�ChFʒ`���#��pɺF!�'Y͆
j�'g?r��ͥfO�+��t���jrU��z�\�����0�ʮ���������h��|c�m�duw�ȶ�+%�}����Y�/4����o}��Q!��ᣯ������?Yp1��o�o:��mzT+#��=�`������Թ{���i�1W�O��x��W;4ƹ��*ᅞ��+J�jR0R�>��I�b�EM�q�����UpMg��/�
���8C�׿ȅ����(=O#�^9S�[H�N&ӔDxXy@�_EЫ�Q��V9��&]�ĸ��'(�W���9�84�_�Se��y����"�f�h�Gl3���	6m����r�$5���^��^muZ���V���jr9 5�^�˥=����csC����(�Gݭ�n��Cg��*)�+EP���(��A�K�k�pԁ�'����������)l����_k�?�4~������?<�>X}��������q����W���8|#�H���맂��N���ڎ�>Q뛾���/�����s?������z��G�a���?|�:�����l:Q�di@�Z7���w�����nO�ݺS*^NSBjȺbFlw_t^��#�!���5��5�{���"\�� �i�Ҿ��s~K;'F�i��;�> כw�"���&���u[��>zC�yC��{pZa� �����V���9��:������I�<O(��8<:�~�u����`�ϝQ9~ ���p|����h!�Z+5|��fAc�u�x����G�kt�!)�ΐ?�HH��sc�g��萨o��w��]���EŁ^_��.��o���qa���ͦ3��wV���O�c�bo���B�d����H5c-�!N�k/�8��Sdv���ス�]��Xb$�0�:�W>�
�H8׵��� e�Z�Zڜ^�6n,�D���:��0F�<��=%�
�d�q��}x!Ws��dR��$��,��8���gDZ:n�$�h�3���|�2%����7��h�
�_8}��1���@,���Zt�Jd�[V�����)��P�z�ܙ�/��=������^��(DP�~��3
�Ы(|W����T��[�����V��dm���!���j�	��t�l�&��1�Ǳq��z�j�r��� �X��E���qd��?�m�%<� n�87�P���V�8��R�
atNh��#xt��3��XZC�&�`��e�w�5�:��Y�>�f����u!��3D������!7^�Y���|D�/�G����:�Wb����j9���DK�"��@�@�sP���]�,�ר�8�Q>Mu���`��x���#SI��`l�RP<Q n&�~��G����	�i�����'��
Cה�d��𬉱�QB�P%� �N�Í�7ki>� �zI�ݻ����-�����uM��<�J�T��I�#9(|�J��/֬�zp��]=��t��!�y,��?�?��=�'��i/-����?��������>y�dN[��+���̸4���XcR1����*�(Gf�����t�z���'��N�V�y�۵��ʯ���F���Z��d��1,��g&��|Ƙ9\���>��U��ԷI�K\p"Nf���X�؂�Z��2��<1��S�JQ�!?���Ú����(J��>��(or���v=�����)��fI�-V�u�^�[�������Ǘ��gLP8�l��t�_���	H��⳦���G�mՏ��T�\;{�X�&��Tq���;2�(K�(��g���Ea\I^��|��V|G�;�G%��e���:%ͮW
���(�N	��D0���C��A��%�)V�����m�M�~��zo:�w�\����j.������D~?8P y: &��.����U��
SB1^\[α#��p��) BLV�luFm�V�ި0ƀ��I~�R[:]��j)�"�i�V�宏����u��E'�I�n�1�x-[�1��H��k�}�k,���^����
I���v��0מ��):���;]��s��BS�\|��p����O�3)7������fS�����eAסT��Ѹht���i�E'dɺ�$2<�e+���$�ѨEAf�{��24F���ϻU5g��ȭ�Rw3i��՝^�VW���K���C0Th ��km���1y�><����F�9z��D��С�����Ww*j
n'b�݊*��8��OP��<>�"�l�I��"��Ua8�f�-1��@�l\Z����C��,�v�Uw(�J�?wr+�ʢ��g�2/wI���t�E6�L�ܜA�GϹ�H"�RG�}/��4A�P+�[�j�?+�Y��MO#�
�ϧ���܃O��v�JTg��PZ-Ԗ%!� �U۱�
�����=%LhW>���#c��S�Q�^}7�V[��f�u��{j���d��󗖏�����l�Ƥ�6P;ken8,ֶ�=it���k����J�@3���r�K��` i>T��i>��7�������7��U����p�k��[Nme��4NNN�T[��Cv�=.y]'�ۗ$y���/Q�/FX���X��`J[���R�ݒW-"�4���ͦh5-�nC��;k����H_�kLcH�V��W�U���QZ6����'(���)~wU,Y�a4�tz�J�u���EӋhڢ;�����Ǻ���3ܟM�?�$�-�O��_������%Y3���OMtb�ԗ���w��n�0�8���&�?�ָ��c2��PdIcŝΣ�ǂ{+��q<ݣ��_%\�'iJz��>몈���w�Ռ��dw���t8��Y�f"�=�����]��;\����n<ެyN'O>p���_8�ojo-Z
��
���{rb�9W�$����4�l�;�E�Qr��3�Y_��N��a�l6��������I�9I�~�= X� s) O�e��\��3�qzy$�k���OgQA7B��l&$e^�P�{d�`Bi;��GE�N�U���_a��k�?��C̴��=vCk�r�v��<��#����g1�b�K4 ��e�6@�LH[[�������,����(��'2�H��yW��I������hTa:�� �D��о�� �*�0��]KB������?=i�<�R[�z�{QLeO��`��y��YlG�󊎺Ц�>�Q~w](���~^��S.�.��w�τf�h>���J��?���漸]�ϫz�م����'�Q�ŉ��MRҪ�z�x����=9�����r"����d�Bߓe^�����*T��Y�P�6g[D�yɒ�u:�V�Q��]z���.#{%Aӹd�Qf�F��IYP�l}�ǝ#�zC��h��A�/b����s/ڒ4�O��������ZuŴza����z�:�`��<�Y~1L3�D�a�፺�73wz�ϳ�Sd kj��$�!G�Yi4���E��e��s^&3.4�	(���1.�Ԫ�`Ӏ�=�� +#,�aY�F6%GR�G�E��r?���WR�\�� ��0�S�c�6(��!��XQt��IA��$
�����阊�ԇ�HÒ��t��zP�z����Vo=�RҪ�bS�獳z�Y���#�a��J��F����>�o�M���E��<x�h-b�����6X4�O�LQ�����sS���ܣf1	�Y���Uұ/�S��\վ�ꩭ�%��/��
�S�N4��n�l��j��$�^{�o�=�Ƀ��/��)�,�e�5B�0�/l]����`�m�L�H�9Y�Ď�)���xC$t\��kIx��l�.�A5�L�S�8�d}�������VSX���S�t7+ڂ��&�@G���ff�^R��(a����ܱ8�T��{+vx�c����@�T�ü�P�(L2�����ڧA-L9jy���,���Ќ�@�Z�F�Y��lI�����z�d�=�0�C�2|�
Y6
h�F�!�6��t+̇�W+�jc���XY4=�Fm�D�����H�V^�=΢ �D�$<�i
P^��1���-��Bdm�!�:������1���5��ciH��;�p�$M�Nj�"�^�Ӂ��b�3���5dy�E�G#����ra��(��?s�-�� 	���s���z�4T�S���<�g���� �w���>���W�
�����G�V,&z����ߴ5���<���3ZC[
2��T
_h[�_��-�-?0�''R���O/� ��&3�����9^��*��f�E@̥x�Y����Gz���YV߭���/X\˖i]�WC�w|�k��i�;�"���3�p�8��!	v�-?*�e8U":���O���k��kU��zO&����m���?-�HfO�hQū�����Dy���@�����<T�¢�[?D=��C5.��<�d�̇��'lD��1��fuYtu�kw=�mK��c���	 �]UN��^2�]�yHRA��H�[1�Mg˱\�U{ݏ��$�@}�hm8��:A|m���N�tGX�����sz����i�b�DÃ붕UH]t7��L�å��u�n�9~ѫ��U[���
��4�ҕ�FYʯ�f�0G��;�mt+�a<}��G�ҳ�*6T~U���pMU$	�Y]��=P�B���ږ>�fnnUK^����b�� ����ej��9�C����_e� ']�(����zE��y���[b�w�Dq���>v_����C��9�A0ڻLsm�7�����-�s�{�U�_��H�׺ܲ��ܫ�&��謏s��;Q���zz$b�J<'	T�b���ع�c� �{���~�#���x$#?`�3m�Ay�o�i<�m^W~)+Zp��X9��O�P�1ݦ�럪�������9�xe��z���U�ܯj$����c�"�ݣ1
[��V�.�u1"�HޏGI|�༹4ǯu��^���a���n}��(��E*(svK���i���/|:�ȭ�(r��Z��fӼ���cd�ן4�v�*_X���vP�v��,���\��Uew;(�T��S��� :--�6�����Ҙ��H@�������(Jl�|���4(֫�_���󆂱ؤ��#*������U"�5}����������}�^�����S�nW=�o�I�>���ͩe���?Ev�;>���)oA:��nF���>ի�vd�N�{���m,	eK:<t:輹%]9]��ْ�Me?mI7I1s�r�?Ƽ�X���.�c�D~�A�#�X�N��t5��\5�}1�4���[$�b�nV��ud�@sy���i��� ��r�v,�N�%���U6+J�"�p2��x�dRj�%�K��r|b�g��Y�����U��>�x�Å:A��@r�G,:�R�a�y{΅���Z�`�&Ϡ�K]K�`r,N��I�q"ǪUx��:}Fň�B��_0� ~�-Q���U턷�p�WT"S�4��7���g�ҧ@]������F��ءk�+�����d�<��*�]>��E��ڦzp�;�ZN�Sy.�}B��:�_.�h9s+q&煉ɻ�e�n��W�����)O�Z�`�,)Ǥ&�����@Ek�i|���,/:�\��bVc���m�����e�������{�)�Y8��l�[0/:��p��|QKzƉ��ݔ����\E��M��r��N+�Ǳ~�(���Ⱦ++5�*ݶs����y�C�9q�-�[<5��&WUӘ׆X*3���޾��a��=�S�Yv4�
�xn�2e�Q��ƣ5���nؿͫ�}r|��s��g_����g�oٝ�*����⻊-�g����4�_��\U��3��UT�bp��,u��`�SDK����=�e�i��n10�Y867�.P��m��R8�2_�y!h����[���զg��Φ�N���s�k�k����+p��ZE7��z50���A�CB��<��}e�q�w@��O#�ܱz%�8�����C�H_r۱��.��9�)��lM��6zk!4)@b>4�������*��̍VX�r�9.u�'K�ۿ�e�h?z�V�1@�c�ā�r��a��}^}��l���E�o�p%c�3�ݳn,w��R�?Yt0�*���D��ʅ��S7w	7�����c��\x~�e,��*Sى�$4v�ɪ��c`��9$l�)}��j�I*��&y���o����kXG��w_���A�o�7�����e���7�Uk��?��z���?�������������_l�ǓG����ڣ�����ɓ���?����W��~����_=�P�"AUs�y-��j�O�/�$Rpؠ�o���i|v��խ:}�^L�H��a~��d�"wn�b�������l�J�g��ս��W��35���<�g��0:	;|�)>�h{
�!��`�#g�C��<� �gH�
�s�19�L�V8��Ѡ��.�N�p�:q��Fi�#u8;���[���.���QD����� ����Pؾz'ʱ���[z��{�Xʫ�w��{0U�;SX� ��3LV�F�^�W�.L*�d�z$��&9�W���+_�i�� _��8ɣd��t6�!�gJ3b��$���C,�w6��f�:�Szѝ���,28H̑HS\�~�|�Ƀ?��=���=5��k	'��m) �&Wr>L~�H�%LDП^�
�Y~��Lg�7H#]q�T@В�g��4%Lx���F���p9��~���F�hJ50��aޠ��&�w��z�>�(�丆�aL�������>�*�==c��(�2���3fD�ҫ��t@vg��1��A�t�6��;�6��ϫ�A�w�No�� ý�T<=�	g�=��)v�1��΍�^F��D����9c�xH@���3�M���f��+��d1D���j]��N��!JЏ�yHI�X1�O�Q��a�+OɅR�������x�(�Y����]D�+B{$ȼ�r����d�.ZA6���;�D�3|�� B�[#���L�"�
���(ÀI��0�P֕�k 7�*�8�tХk�ց�z-��0N��,*;t!�D�E���!�k4!8mc�o:AԠ�WȈ(�V���旀y4�6���:�н�x�^�w��٫u�9��/$Lr����B��(:�@\7#/l�� �&�(�bN������a�I�}����M�b���D�蓘F̞�xN��\�SJq�S�O|
���&̤���N��	�i�Xg�iH1}G�v��(i�)�b�� ��(��H�^�l��J�t����3�Jݑ������֣�P�~Fj��Ra�j�Rb����1�%Ay�ˍ��\�p��]�C�L�tYJTyz��!�O��a�3\N��0*� a� ���$'���
�̴LeW�ʔ���poKN�J���lJ>?��0f:���-�� �3`�s�Ր�!!�Bd,���������$GK�OZ/#fw�0 ��� Q��|z$R�\,�E��)\/�T�aGvf�(�b�f6;E;�E��Xj�)~?�'�V��%�*�"֗���=q��O� G`����R�U�[1�)v���	����j�+M���9��N 3�VF$����H�𥎈Ji;"�ߺ�p�M�\�2���	�V�㢜(�4'\!Dg�O3�	i�L(� %��B]͋4�]S`�H:��zA,��X�7��݀������Ɉ@2W��UK$��,9�=��(���-�2�xZG
�Sc�\��Ʌ�H�� �L�!�OP�p��b�!/�S<����q�h��:���.������~�������V;vxL��S:_}��{4W
灌VYc��Ko~���0h�R�:��0��[��4�� 
F��4CW P��Yw��]6��fN�]��/:`��R�z�Ju�l�4a�p0�#�8��,��j�!�jt$5+��`eW�.�����&m��d��&5JDs�he�ᄮ�A�J��O���0�ι2L$�V���AC L�d��� �z\��g�D(���=`Z\�q%|�Vdb5YS��A��*�鷚��hb���j�Ƃ6�YM@Ų`�]��S��FD�����v�gQ��Є���k��3���.�a�R#z =�5�;��#����'C<��$G��O-��e 2�y�.�6��&��q�-
��W��3;�}"" �̀:xtd�6��6�KT@�İ�D,���,��Q*1UР�(�.��~����F#s �����xO�΋�`�@�!J�eFC�����)�D%(k) �=� W�5����E%���a<�Ps\LC����GI6�j �Ӧ6���	g;�E�� �E��.�΄��.���)�Y-����<Vw��B�1�5G�����k�!��5Vn�"�/��l�0s[tKh~�g9�c��B�P�UAX�w�!�$[��@،�%C�Ơq-a�l�WJ*�#��1�CK�w���s�`�L�%mk ��i�'D�-�	���+�q8��0�����t������� �Xo)q5m��y~��Gk�*���4
a�E,���y�o�t/+k92���_"��8��[({H%=h�����t�v4�lw�|� ����1�a,��:�Dɐ
[��Ü7i *[:�B�EC���3 �7eN
��}6
��m�`��7����������X�)V��z;n[�4e{F=Ro �N�!�sG��V��;j؇����Vj��jL:�e�W�:[_��@!��� �t��.<c"��@�r�&�,n�%�JV$�	�y�4�;~ZW�pbX�b�*"�]�(� �Ҽx���L��*#/$
�VxRVb(�
�kBD8��&�VQ��+�¤�s]�-�ˁMQV#Ō(<u
V߁����'��Eg̠�8�Q���
�%$&̍|�κ��7Ȅ��
���%8}<��Z-����"{m���m?S�lC��gU��x�$��$� �FA�0�(���C[,y��N�W"�uZ��NF6�T���V�	�@+'�8�HG��Y���ez�ZkÔ�@D�wN{?�ו�ZT2�4e!\��`��ڨ�qw*ڜ#tT'�d�/,oe`;�גW�*XZ��10��$��ƅwQM���|]�4�K��إ4q�r�'i lL��^��$s� K� ݞ�Иg*�6�/Ե��ٮhv����c*��t9ƳD+���2*Ѷp
"�Ҳ9�]��E����� Upe��CF�צ�iF�id߳p�z�6V�ۛ.���ſ�E��� �h�;�haQ�L�F!a5�z���ȋ7��)��Z�C�r��!�P���R ��"e�E�r�Wh�킊,E�6I����gB���Af�Y2��1��۰5m)k}�����;�
4N�Y�I
��}z僃���I���,���<#�D,��cq>�E���;I/A9>�xg�vA9�٧��&!ޏ�p��9� =��uB:`���<&�8F4Vj�e9Pmї�µ�g]3���G����y����,PB�|�z5"�&O��Lp��}:������/mR�|Y4��,c��"�.bW"�<����5d�zbɲ�L�>G��hW�}��AEô�Gf�[Ә�3��@�B"]��7؈9ˌ��]d���*��Ȥ�A��it������  v��q)�ȴ76�:�1_�್��{��6ۈv�9�%�>1���uO�AO��-71v?{?��gc]2ߋAA�{��D``�h�T�G�"�	�^<�S��;Y_##o���\'�����h��+�{�R~����ܪ�EKF;0��+�q?�Y)�ՃYw`�>JL����?O�Qz��tːܘF�Q���F�ͩJ
>��!�Q!l}]��7;���Ѹc@��Xݍ5�`������SA�U*2�jѨ*&}�$z`_��Cf#��U�i%��/Ø
�]i�%i���1��4̔�O�&�0���2�����:�Ǆ0B�+�#!��A�2+�x�4�	��²��iŁ��T�Y��L�5g���DIG��qI6i�ug�ꔱn�}���@�thA54����{�Z�gm�A��@r��.�1���3O�a�h3������%����t�M@�g�,����5H�s�lzfT������'�V�]���EcA_hB�'�
Ђ�œ�����~7��B���NF�����S�\�ӎ+cs{J�8���>Qm�V��f��� 9���X#Ee��w�z+��

��8�'�s�dNֆB<`cBh	�]d�Ӳ�HƯ]G{�\KIPi�h3:w�ۗ7M'��h�����DD���>��XqsE⦡�\F����N�+[����`W���)M�O,O��bב@���.0�
KZ�7����"o�d�JP\�:�7���|������V��Γ|z7l�t�@�HG�͹85�h�nc��K,���h%���a�)��-ڡ��j8܋4ˢLG��GV�"Lr��$�����7Ԃqc���LH��ԃV�Q�$���ц�Y8�0�emb�·lR��*OqAr��u0�Z[u'�+��[#g�?���vP	.�H�,��XD�u��6s)5���yhb,�5���"z5v5�Q�:^�"lľ�1��L�!c�����&��̝�y6A�06R|H���ó���
���Ðא/W�F;��=��T_��v����y��wX�)Y���T�uX��g����7PaDe]��h�ou�T��J��H-
8.�$��gg���5-���n�x�-˗�ڄʢ1Y�ʂx�SZ���'��I��0i��(��Ƞ�)!�����K��;�6�~�a�ΕD:�J��ie=����"���^�J*Ɔ21
,̀2#��e��Cop���PD�*-b�Ɋ"�SY�
��a�[f��1�P{�ې�F��d`	�AV�}�iQ����{�I��ڮ�T����gi%T�ٔ�gzt�9%r� �,�hm8 @��,k���9d�6E�=a)���곴�ciP�b0��*
�l�u�0�t�OZ��0��r�5C�2ٰ�F�'н�>Q25�-��)�dR@.���m�û�c0@V$r�\�c�x#��CC{HIr.>N9@�Fp��4��v��9Q�r}"�X��	�0$ن��z��Q�u�{ 	;�TT+�	>;���.ݣ������(�b��\�+Å#e���L��P���aF����R�����#,QG�Q�]�a�^>�Psy��;��Z@|rj�9�T�1��|F~�̐���t�N��b�>�G�EK���R;����E�b�=�75���!ON�e-fS�260�2r�(^��M�;`�^r<�JD��C��4+�nc.*����?�ަ����*[���C�[k�Ws#�!�.s�@�˷�Y!G)f����u���F�pv��4*�ZSbv΅n_�r���d��i�ys�7�nP�i1n���ф1Y-�q��0,���3�d�6g���rk���fFv�IM�y��9�˄�i�8��8a{;#
*a�Ux�}� !����i��vHC�I��:F��1߈�퐉���!w4r���QO@'�k����6���+���s�4��8��7�D
�0$4ƣ�<�FKq84�f�1+�D+:&�)�1W�v�B�4jf�-7`#m\��/��q�Ft����w��*�P{��˛��h �@��!ۢ
C`$���`��{G���K؟��F0Hg��p���e�� G��.���"��E�<�3�m�FP��˞(V�	�B���j���� �����r��	#��Ga�9)��YB��g&��0��M�	)������W�G�G#~�_
���NQ�	G���0�Ȉ��`/�\�3�t�����3��T��L�˝%44��	�'�� iq���l6�$�QCH�"�w8n���T��r��!8�m�����я�hH����.�b�2��ؚ��T'2"p�PT��U�n�x<o�H���ԟsB��]�-�BA6�PŨ�f�٘����<e(��5(�'�h*�	�)�.J��6�84�\�����?�T��$�3��hI�T��XM�E���ح�F�%���@�66ȑ�9st3��dv꩜�(#C�:j�~H�N�Z$���qF����I�����ȥk���Zi��W�s��@��GA%�}��mT2%�F�������1L���ɵhK�t*GɌ�:I��ȁX֒���)��ޕ{�
8)I�,y{��=n�S�;�y���^݄-��w��y[/G�Aa}���J��#��k�!4?������;k�����ي������RP���x٠�(�Z'q�Y��<JJN($T�hh)�;s��,�`(�VD�똩���r�#Jģ�ͤ��p�}�n
3�Qua�f�;��h,�L枳��� ��=+/g&QgcaY�.�����Q�����A1pNtW�]k�@�u���g�nF81K�-B����ecS�Z߶�B���GڠZs>�L�Fn���K�̛:�qV�q8��� )�0�8�gi�g]n��z<s((�5�	��iw��@8f���l�1�͜L����,/�䂳Ém}��'�j#NV�=`˷�Rwch��V�=����$�[R�	:�7��쮪���Tr�"	�/���c��]���1l��
��m�R7�SQy��Շ,�Y�K��92��S���[bu�����튿(��e@?T�f��z��H�V�:���Y>�	!���]�4&�'��ݑ�P�z {oe܇�M�r<F�Dѡo� ���.������8|Q��@s��% ��eFvM����qI���P�aJ��u~lK@i�:��[��4�X�&�Ù���䐩��DLן��eL�82馤�L/��)<���]n&�]�.S��f�ꀍ?�j�b��J���U�d��C�#de;����u��&�0��^��<���Z���ی�95*tq�[�Blu�.)m/s����	M�%��AG[Τ�J<xm����Ko����օ{FG��Eu#10�ق�V����2���8FQ?ȍ okP^E�6g�R$A�Of�����q��ٝ8L���eV�ʏ�@�y�U�:˶p�yS�[ȵ���@u�¶i9��^F��ɕ�N8'�U�k��A@J)�]���G% Lv S�B[1ڄx6�'@�C�V�|`BAI����MD�����[k`��� P�(=���j�ZO(�*,�a�j^�[�ʢ8CU�K����t e��lR�Fg���3 I�ڟ�Q��/&���_�X,R�;w��n>�S;���c��U��F1��.ޅ��[�k��岘[Z�݀�pY(�L�	`s��2 ��B	q�|!�;���N�Y�F%g�'(�S
�r�OZ�Q-PIȺ8�mʭ�e���Ou�0s���� E]��lW��4h�l��'l�p�>(�d��ZP����nZ2��i�I�0@*���k�2;y#���Sy
o$VqaU����,�\6yU�tj�s���"%n
0S�"���a+��&��Zg��K'(��wzJ��])"�"	OS3������( *��}��z`�Pv(�e�j���*�H/�*C.�c��'��\`�ڐ�4ll���Cм�z��ϒ�ZpP͠q��0dW���0�dMH��r��aPtt۔��%!���DgO�-���8ʜ������YN�gZ�x�z~��	����b�Χe��n����\�tП��юj��Ѕo ���Q�yQlܳ��-�1ߐc�z�V"��%C�T�@i��2
�a&���nʷ����iLc�E��=�Ћ�=jNڛ�o��H/MM�|1�+Ъ��e��e�ffj��o"���G�っ�䌶B����t�#\��G
�p��^(L���"�l�c'��9��TK)��5�Df�B���kҙK���,Yo""o�C�B%'���z��� d��|#���*�1�4�H2�Ys�;���-9[���Jrh�35v8���\J0mH@ �°,J���I�/J��������%`4�/DӁ/ԉ�S�3'����x�Uө�p���Q&���0�[��T��͙��A�X�.Hu��E6��2c~Y���e12�[c���Z�Py���K��G���xN��WnI.���~���T'G݂ʨ�P��1���1ǭ�E�m�u�1�1먭D�w'a��$ʹ�e����s�.��H�50n����:߀}-�l��O�E�frr�Dz�
��#K��L�L#q��<��$K��W1�Q�n���5�8�����P�XR����C�*�͢o#�P�2�y�4C��,��#˧��y��WB������X��;M�x�R'�����Z��W[���1=㝣Y!����&�R�� ��)"��&�����T��3����.�-�X/H�����i��F*����񘢛�����yl��d����ԡ.k�K�%luL�5xS�N�.�T��&�����
���ƌ'��6�lmB��Cd�p�U��{&��ki��`/�7�� O4p�q8�Tg��Zq}Ӱ/B�2R����)�x��'����]��C��E� s!�H�[��F�V�g��:wI�x�`AI����ފ��F��6d��4� �Q�|��ڼ*uF��:Mw���&�����W�T@����rz�]�#��d�0����t4��Z��4�f��r;��G�98��E�%-(.�R.:G��-�+n˾pU�"	�.��l��ٟ��D���jvE֧��I&ɕ6��4�����o�_����/V�R�{"�n�q�j��%z�,,U�u��"JBN��fb��n��:����9�L!w�)���S Sj�s���ݖ��Q�Mf�q���
�+�Q�USV��e�T�R���
�H�FL.���J�2�7��KS���m��LRHy0L���%������ơ��Q'�U'���+�m�XY&����<c�#�Z���P@���4J� �j!L	w�
c*��>434\�܀"��L}l]z:�j�шl* V<�kYt�Bc�O�)Σ��+2m(���*(N�rP2o��3e�K�\xa�8X�[�=������1���pK�iq�2�29wbwAI��aG�[�@7`69 ��f�fyeR�����:�cr�Lۜj ��L�F�δ�-Dn�TgJ_'�a"����2Q^�
�͔�Ѿfm�aơ�{���\M��M'XBo���`�fT���+�,��!�<զ����"``�����R��UM^�,౟������!�o��/YQ}a�:�E�l����SO2ҋA��Q�k!-_�*2�XrHx�j02&���	�T�/0_�)J�Dj��N���ڐb���jLqN�u(�^U
)M��R$���j����f٬�K�Rm�LI���t;��AiI.�	>U'-S?�#i&�V�wV9~.�Ҿc^�R��q��:!`���!�ɠjjsE��,z�4�L�D��V\`q���"���� �%k�I,�ar�a��T{�N�L��E�.-��L���Ό�O�i'T�d���S�M��:3�WW\S��C���Icvw=�z�R�j}��ŭz�#8�1�O/sұ��
���D1�:ejU�T�nF�a؝�ȏv�u%Ql�0��&,_OQ�r���� ��nq^c�߷e�O~�A��g��7ЩeY<���P�Ñz��\�I@�Hљbh����n�^Jvy��#�7̨�I�T�i"��x�'�����*�uA��*Z�#Ȥ`�ǹ����a�A!S�T�:���3?2�y��Q���0��%��L��'��Ռ��0��J��.E5�t���h�b���P$,�Q�Ohn�<!��j,\��t2��[���zu�/p�ܘ�drŻA�^

�1)t%"�Zk]�o��F`o)�M9l�)�o�.�bq��Z��ďsv�ˣ�:���aݯ#��y�4�-B�l�dSM�B�0��=��B�g����ÿT�`썃��m]�+$M�il�y%j�X�H��Ur!v`FɈ����Lh
���n�Ϥ�`ÕQIx@l����\t�d��M�W`��%TK�&��;�]XX�Ĭ�I��i�u�����28��lw��gΓ;�p�*�������(�@c�5�zxX�)����ҮQ-��G!>�?O��BB�'���j}^k�t��1���E���	�dUp��-@}B�u<?}?c���;U-�ܐ�F����F�=��ﲑ]:P-n�M T��f�FK�S��q�N�P�z=A� .aֲ@�.$07�mKp�Az񐒉��	gTz#��L�^v��j���ԛ��Qg��G����P�G?u��������qw�Xv��v�������A��pwg��|��v;o������7/��� �����q;��7G;�;�?Ѐ[�?����8xy���=���0;uT����n��zg��I�:=XvM��9~y���,>8x��������P�����G�^ c�����������mXKC=�������4�M���q10�^�h�%��y�����g�^�����|��n�(8|utx��������`��x�1ta�=|g�r��1�vՏ��E��w�=� ��j����u�����0M��^W��;�A�����n�z;G?�^������{��9B(m�(��FOZ\n�:j�)�>bP�5�ǫ�]��Q�?^�^K��%8~燣.�����,O� �b�hP��"Ə�bj�`{�� �������
�٢l���9,d��+@(�mw�:?t{f���<��P������>�2��{�W<Z�@Q8c���1xp_#̍���]�s��R�����qGъ���]l}��@��lm�:���-����
n��>����v�/����"��� B��9	nѫ7<|����z)Ǧ����z	G��:ۯw�:�<���	�F82�}��E�I���R��˼�31�p�!��7E>8�־�ǂ�(�b���%�Y�pN�R"�H]�t�%\X�gUF
/Eg�rL�Qʙ�����H��i�f���p2�(����Y{��đ�l ��d|@�tg�����=ZܾXֵ���y����%���!q8ױ-�Y�>����� ɻ>�\�W�u8�<9-���9f��S�̲BniC<#Y�5�0p�,�&T�bq�Og�8D�m�i�ߓ���/���֍�#i#����P��V|թSF��1�;d���!nWlz�uc��8ۂ���0{~�%�^�H�k�S��/JL#��<(�޺��?5#��PY�����Ա}AW��LmWz�eSA����_�xs�?�t"�tGC����8��[�KU"-e�n��wX��{���Hu���<ﱼת�6���4�{��Z��U{J�a����3_�oh5�dZ�q�~�꧛�˚M� v���st/�$��Y���䪴��jq9�ٞ��Z��Aci�%V�vU�� ��/e�^Ě ��H�.V�u�(�G�xm"��Ⱥ�K]9���%���������|��n_^^�ΒY+���u�G�{XPC�0��-m�ED�v�������h盦	V�·B�	F���\F9q�P���Ɩ��r����1����+m����0lNu�ة[��H��w2��7��%<�����������&��T�S�W���E/�_�o���ٲ����aäw�i��&)�X������e��j��Fr*�
�^����ӯջ��~A�9�N��$�Ƕ��z�`LG��,�^�T���vl�cyƁ4#[����xq�����IY2Śb�%���N�0�A�����_4�SL�@8��5�za$� ����x5��7eݱy�����_vv��d	?��\n|y.i�����p�1&�ts���pχ+�M�����ɕp�r�b����<�u%�v\���:�0�<Sd�ٜ�mgWQ.fHy3G��,�G�:�R���n�� ��0��<�F	E��[�%u(���)Ch*�br�(�Nίڗ�WM sst6����N�w��?���>�v������ͱ�����#��~��1�����ϣ��O�U�7��o<z���Z[��x�wj�����!K��di��4|ϛQ����{���6>����� E0$"�ʭ�_o7��nr�������<�I�Pzᒄ*�������D�Eb�i�� ��}��vbZ2���F�7� U 5�l�LT�:���_�ֵ�p{8��ζ�R¦Ą�@�'�g�u�zÕ�pL�6�}����A�ӓ̓9mg@K�}�n��b�f(�Qt����O��N94))T	��¯0{`��`���rKo���:[j����P�"��Y>��-NL)P/��#�t#g��h�y ��~��L�1<HgXT+;�@��Яy'��l&����IV�fI���1րi��)�n���%�2��sj��4*���"�����z]��t����NK`�W��sv��J,�Tv�d�^���?�����5n��w�Ga.�`��0��F�b�a�M����D�� C�j��i���i~W�����}-����ҽ{���I�l��GǠϐ�MFlt�˒Y�)<Mǉ|����D�Y�-�ft��]� �h>/X��������0���n���ߓ� �~V���z��m�'S��`cm����zs�����͍?n>��B����&�"̆�����Uk�u)�1o���j�1�����L�8�{�uWv~��s����<���{��;�k��=y��u��Y-OA����ه�o��?5�滗{�����W����__��'Z���y���~h�j��1J�gQ}�p�w��0����l�L�ќ�ն�4-��,��N8=��-V�L���2�:p��`n�岽���
��������a�޽�m��l�O�.��)�5P=�f]�e7}�O�~m�'T(Z�O����T!�=�it���A�
g� �a@�t��_�8RSgsēQ��a*��6}Q�-���^.��4쿛M��9����<�O=NJt��٬��|���WQ�%�f_�t�q<�"<��s	H:�MψOn�v>��x�(=C&^�L	�sJ����+V����.">~����k�>x ��k�K�Ks�������{P��r�jU�c�*�ᇛ��	��`	�D;� �7غ�XE7�Q)߁��RU�D��m�B�� }��c/x%Z�`��R¸@.R�q��������Fs�������G�k�o'����ZkZ"���o!���م�b<݀�p4���=^e:,�z�.��T)W�\8�˪�ϳ"�9��s�!v~�3�z�颾�㭓���%ӷɉ�l^:ؼ�,�k�x���~�p�4d�����&y��3���4�&txt��j�x.�u���|k�Q�P���r}���Zo=l��d�{o���b�t^w
�偳i��	ۿޭ���Z;Y��p�������ɋ��/c�|�pH�kH�au����9ۭ�B3��s����6w\�52��nwu�eW��W�|���oSu�ܣ�7# K�{�������4�b�M:v��)e)�o�#�o��Z8����f���v�E����;R���v�S!Oʨ@�<:��rs���B���WR�G[��	c��	��t;@�$�)��6�Z��WB xߦ�pߓ>q�/����'�,��1���� �`����� ��x)��� �ӊ�} 0���I���?��;Pz6M1\�o�'L����9B��kM��*���W|9�N��lܒڵ��5��f��7� HVAy���ַ�bX���'XK��,�ģ��t8�tL��o|#{�c�=C�H?�F� �2�-�/Ua6��X ZERV��!H(Y-,��Fs���x�^L���l����𛒋��Emn�}g�=>��S[�Q��	�F�d��=�?�����RD��~~Jik�RԢ9�F(�\�[���J�VU�&I�L�?OU�{ttp,�����5U���v2`���!<c�D@�ŏ��Z��B{�&R����Vg��9���$5��}��5��>�b�k��ϟf���v��#}��wǕ2\��j��B3�6��H�	#U��l�8�ɀ��YM��glH��A˱~)��UK�ʂ냖���C�D4�(7##F���r��c^�4��<p�{Meo�"����+C�E_�O�:��<�T$� P59<K�s}�-Y֝Q��=|��1!�;��y�G�S��WƮ�@���؅�p���\[��0f<����˥�ظ\+�޼�����T�����;�n�����5�\���g�ma@��%�YRm�e`��t�o̙* �X�G���1��	�\��ܱ�QئS����E����\"F�;O瞖�������-���.=��' ��P��������c�=����pYa�xZA�P���j;b҂m�h�,����O��%��:Ѹ�EI�e�3�K�q�� ��۱�B�����k���[٢��Uع|ZZ�\&� 4o{g*���iF~}�w�;��qC\2�{���L��id�NH���B=���R�p�TWO�9����^�����qgf���5�������Џ7�R�\,���-����q�m@�c�D����U��`�@b��Z�`�k�W\�=t�����ߞ�q��t���]m��wM�ql΢��u1��W`��1��:*n��h�V��r76Y��cZ|N�s|�Y�V�Ph��� �Z��Ǯ<���3s�O_����X�� �`]��Nс+����¶co��2@�̼,�Z~`�fc9ZQXKO��%	����f�pp���~L�g�s�TY	Gz1��S"�+��iT/艘Sw��z��q�Pw�̟�a� ꣚��mX��*��Z��v��!L�:�j�?HO��?�Ϣ˭r�d*d�]�����I�0I;t����]�95��)W�04pn-����hd���py(�ir�%	�<!�ᙖ\yY�/���N�3�j$ϐ����Y&֓V��"�X�Ԉ{��Z���a/>p�QȒ&O7�!��Y`��_��,��������h-�o�ܶ��ԧ'�N�S��]W�@�wݝq��w��
5c���c��j��"N�3FG��Zv�B�U|D(6LN'd�r�S��^�T;�aR�ow ��'�/�I��Փb��?��AS��X:�~)�j�4��nU�]�>U�T�w�w^�c �,�`��>}y�C�&�s��,*D�� �<��T�ƃ`��*a�����A�g}:l��*]ĕ���?zT�������2t�"��Ƨ����(1e���(����B���se�A%.,b�+��ԓ~J+�>����W�x�m��c�d�>j1X�y�-��*���b������sF�sg�
h{��DgG���3j�:v�� �c*�WU�m�'A���C�c%��W�q�|�|r��(���lfRZ^[�H�����+�	���yT��JV�nP��
�Fο��� �����V��C%2o8�����Ƭ\���y��y2c�������o]o�ܿ���;p�t;I[�\��vl'�.��XNR]�Z/��X&�"e���>�����_3/��  	R�勬8UDϤd8���t�a��zw���9L����j�As�%|ƗV~��^3�L/�BI6k���x�m�~�%z�%�߼Ѯ���z����;����v��x�(^�- ���]��b����tq�x��6��;%')�~���������8��N�mX������<�A�f�%X���(|��X�±�}�9,�D��I�B�Q��W�9ų-�|�|�)XϘLr�$�'�J�[~f%G���5zI�^Jr�'8�f�n3$�#t��}�P7(��I��9#��3j�%��ޓIM(������R��RHz�G�֕6I�~
b���m�l�hc��.��P�+Ȇ�x��S��
"h�5Jn�L&��8�9$��f0��#z� ���nZDC�ӧ�t�4{��a�i`67̶�x(����tΌ �)��ϱ��2�q>sx�� B<�s!�pL�ODw.�-��-�ͻ$X�&v������M�U��Я�s�E���3���f|��)��y��%�@Z��Y���������ç�.<��&%@RZ�F��L 6�LÍ�. �8��K.���h�
�����6��ы�kbD�A|��N�r���"`���h��������l2x���5��f��ٍb��Z
k�_�9O��oH��[����)m�6��g�o0N�>�I�� ��fr"�e��yFr>]��26��Vb"�d�"�&���×X��������j�S8��Ne.�W	L�H=�S?@g,VJr�ҧ��'�d3sg?���Oí�H��O�y�W�)�1\���aP�~�S�)�h�pZxKJq*�Q]���3����s�sbd/l|Y+���3K�̱~:��#Tq)!ȸ(�4�C�0*Ns}R�� ���;E
z�}=v�I�7"x��ms���E�$d�\|�O5URL��4�i�7��n�)����	I�A� Li���ȧ ���b'#U�뗨&���c�r�m,�|�{�
we{�)m2%�C:�H츎\:Ղ�j�3�Bڍ"���J���{�t�|B���Aqm!H�����'p�,�����a\�_����>�c�/T,Gø��'�h�%�Zv�Y�2�pζ�����^l�j/�_v�|��A ��d�vb(�bE_`�h�� ��HsoQ��^ЉK\�%����P����˻ƣҹ֔�i�С�Zym�7���Y��pʜ}m�/iB��&g������Ȳ�����@�?�fT�V�j��{D�9�C���{Q��%Dy*�G0�=���:�[���y,v��	�>���W��$����7��!�X��MM֊��,C���*��m�Ve�혆滞ac�)�����.��OL՗��ٚ��\UW-O�;m�m�5S�ۮ�v�k�.�uK�}��9b����w5K��w\���PE�Ȳ�[�mk��9�������3�4b+f����Q��,�$mMsݖ;�y]w]����P��G��jG�j�l���kf���y��Z�/����k��P�mh�a��ۺ�QTE�;��̀阎'��Ė]@�����t:�j��Vڪ�i+`i��E�8_�M�W<ߑ=�5LY�u��4E3ڮ�:�!Z���Z�m��x��a�<Ǳ��m�VU�SնL��E����(�j��m(�ٶ-�M���9�NG'��wTC�-/�'sŁ�m���� ��-bZ��V}W0M`r��M�U5��{��!�>�^[�]�m�!Ӕ����YX3k+�&pe@I����lۀʦ��m�N�|��fA��x�7ڊj�L���:�� �Z���nZ�������A:�^��+m��t`3)��0� ]1;FG�u@�(�ퟁ����1 �}�q5�$�[�혊k����'玸7�X8���̱���i.qdXp�Y���l&8O<W�V
l�6��;*̬l�U���x�o(@	�8ض���[�`���UȂ	8d��� 0b���l�-&���Y���۝:�ƶ��20��h�#��e���_�c��lÌۅ=��,��j6���X:q�N�q:mS��'*,�ca�����©�P�p�V���hTW�R[U��m�]D�d.j&���;�<�4�����TV���v��&;�ɥ&����V�٢� 9�4���qd*�n�5CqT�+J�r�ВN9H=9	ø��0u�x DDw�0<S�U��l�0\�R-Gs]U)�*S�=�AO���e�W�-��͎e�;��QLױ��R����0�~�?'7~BL��RVU���8
�:�ǯ�8�\�"��Jg@�;~[��tL�358�8�4ǶM�]��)61�̫�gy}T�쇾�wa�]�Dz����0ŅӐ���"���R���gf%���G�Bm�0ۆBt[��f[�� ��� Q�-�@�|��Z��"L��:6�6����d�����Niwd��ڲ%�j�t^���a��k�7��j[:��6��jZ��hH�K+Z_x8�DD{�э��=�/�Dӈ�n�����Ձ���l�x#���	x
���k��V�j�[�l8R�*�H�f�!�Y�8�����Y��t@�tӲ[��T��p����*��;�N��e��M��z@;��4�x�������a��%��IQKg��?��m ���k{� еoSMؿ�)�V��g
E��#�2�����>l���p��<�����׈���nǐ)��6�0YW;V��h��R ��#V�$�qz��;���plB|��=E��}�o��m)�-S��2�����~o��y0$ǳmp�m`m}� \���	����)NR/s�굁����I���e�Q���;D6�3��%5�[�?�ྤ���C��r�a̿�Cy���
����?�7�H�Cw�\�/����Ƃ�]�\�t�KX�Ҵ��g���ߟ>�R�����C�6�E��,����W۽P�g�z���EDR;�����N�ؙL�u�w1�����ז�aTm��1c,�7i|������<$�t@yMv/�����ʡ��7��k��m����FS֚J�� ��3������y���R�[9���8����`����%��f��F�'����}��[�I�?��g8֧7�{�)�e���c`��-���Q�b9�C�j16'h{o����F�ݮ���.�^���E�{�S?�!%���2+�ĩ?5��7N�q��<a�F�E��<�ҕ?��g:�>��8D��7������F��y��y'���>_x�m��$��i�
��;�L�qo����w|�v��Ma�)+u���[���u2�}�зyn����X����R�3�L�Ѽ�СX��C@y �)7��>s�Zޡ�е�:ki�f�3��v6TnP�&wD(��`6s��I|D���w�u)�Y*ZLQ�Zt֕���$g�Wh3�S"�Y��"<��܂�ʵ`�s�S
x;�4�k��eLó;$�b��-��\*�k������
O������h&�U,H*{���?�$-m�~��<�1��y'f��#���U0���eG��ϳ@���p��
�I�.�0HT-�r�h�ܭ|�d�;􏞹=`�G����mZ��u��g6��7������'��sH�=���q���'/Z�/�]a�Z~�UZKJ��I�flӗ����cv^B�+�A̲G<�{|�IKC��T��-`�3�_��IiY��h>0���J�N��B���'�����+�%'� �V3ͦ���?�[NKl쿾鄰�xs�!����Q�������Q��R"����U� ��} :ऌ+*F���c��9|�o�a�����L7*7����*lTF�?_^u���%�p�kK��.����fDa2��j�6�T�HM���@�	yj��lX�S�������=��S�k�'����IщMϤ�+%���G�[�t4�m��w�s��!�X�Ϧz�ڐ^o���l?k�Ҽg������l���I�whSjАʾ�����Ɛ�������Rc<���g{2����ލy^>�g;��Gb��7��b76��Y'��!�5��8�O�u�ׁ�|��\�R	r'�&�'�xp%5�/��[����&m��˴n���x3�u�;X���M�_L���
(�Pș[���=IJ
<�:,T T��P�p	�O�
����-+M�(�
��Ψ���|���\!$�3� S,$`�H�:�9-L�8��O�}�"�|j��h$���I�� �RS�|�ш'@7G#�	��m�Ku7�f�j�RK�I�O�)P�75��:1��%Vލ=*��&�xF`rv�s|��������1��}�p�	k����bB���Yc�m�>�s+�dV��%��L>��r,�5�k�cB5_B��pN��4�ݵ=􍵷�y��ݒ��=�~�\nZ����~�P2=�1�&��x�fE,��?шǙ}I-�ъ: 	)EĈ�-����1�0g�Ŝ��XfXC�~���zV�ܮ:�K�N������v02Cv�iw-gE���,m|z�u;�g��2���pU�"���FuQ��˒�ēc�</��?6[3��y��0쮝sԒk�������3�Ս���ռ�����2�T��4P���t���]E���t@��o�Xt�P�/F�G}�m^��z�k\�I�S�׏��X���'e`ϰ��"�-��)���e�Ý1���5��������Y��$=��^n�烲�w��g$�,�WAG&��ey�4Sg����%�4X�p=�|27�T�A2(�.��?۽���s��w�מ�Ǜ�+���"�_�YG�ݔ�j��"U���_4/~����rV�� ���[u�wǔ?,���'���m����P-]35��LY���V�2���k���ɪ\��*R�Kσ�q���4�Z�U��W��i��oX�_I�qc� m�~�u�:�W��x�Zj�Y�
�o�F��u%�i�H���}�6�$?��0��_�a��0���ү�a��?�Yf�"�wS�v�j��8�@q�106�=��gQ�v�y�C���񌆺j2SDg��n��@9��}B���ʖ�/����Ԧ��[ԛ�K]�^O{/I����4iXu��$5�J�2�-��nw����61��}*�	���+��I|س5Ȕ܊����dJ�u���	��%Nzma�J7揖�}�-������b(�"#�WՊ�_I��	� m�|�u�G�?�����t3O��kc�<���?z��dUV5���V���/� ��dy��O����ρK�s�A�t'<�ߣ��k_��|2�.���0Ȣ�KW�3�L��	$�Gd�WO����-����{�[�z�/{O�����>R`\�H�
rέ��d��N����b�7�z�,7�L�����#��"�,f����zReF�M�(UuK+���
InV.��ʗ�\�L�[
r�e�b�2�[(��{��c��i��ݣ����VYnV
��R,�]��U#�+��FDP ����F���&+r������	�Iqt��7�d�+~͙���uHJL߾$�#�Rs6�b~$|���|�w[aP=/�����t�2 j!�1�x��Dd푑��m�I���̼3�:���������O���I�q������1��gc!�p��9�&�r)��OV#���-�=�X��Y����T5�D�ϲ*������˱|s��1s}?O#��W�����h�1��)���\�oێ������;M�"�{"y�ǹ�r��ғ�v�=�a��>	��+2����/��A@��&�) ?��)�������Jd�$(Rq�����@;O�M�G8�"�{�֙?(m#�ÁDpÃ��!d�u�Sl̅�e�� � nH�j��W���`���
��nh~rA�1�QY���4o��,a�賐��sj�8N }u<!W�Pki���t�Y^��G����#�͔6��B��O[#���J$>�A��·qYf�9^�p��	^��}^(Nv�};ڣ����@nH���~�4��������ΧC�}��w�Չ�ce��p��s�����@i�O['��?�\z�?�p�s����h����ι�~$O��\]]��:�n���7�Z?��d:�{���*F���`���Z}7
3K���<k��nH��Rd�Gh! .g�Q��'�p:8i���xC����
D�+��2��`��E�j�.�;:��E�ܞ�=�>�~V}a� ��h�WpH�'�p sDA�I�����'�d��Q��O�v[��������O?��鏟�3�����#��~�O����������>�}����ŧ��]	�`g�}�����ut�y���y��z���`�������?�#�шi��Q��k�D�ܜ��6�]`��H�x���ey	��`Ƽk\L`O��@G[��n]_fB�y���4lw4�+��G^����nD��;����%^���P^���g�Aҿ��}����k�y��2�� �[��!�x9w��=8�d�,������]5{^gx��dc,��B�'�(.�����.�f)�߅�}��'�~�a �{�����P���O�U���[��畤��O�s�2�t'|�� U��UV��?8T�b���/����}w6 ��7g�c�L���r��`��0���� #��5�=��'�H��d�қ�O�j ���б)���'wCU� ݫ�(b���{�R���#��%�g��ԑ�i8���X�{0%C� <�E���4`MtJc��[���aH�'�('���aDQ
Ec��(��Ҷ�~M��~�.�Z�.E�6-��*���ι��y�{��]��5J�y�[o�㘇����w�n����o�ƈ��T�J�[�+�╇�c�n������ (�^� �O�f
�L�=~Sk�B7��%��`���]R�CW�ڝB�^o����Y�>�9�;�4�fC���'�f���)�{�;x}�a�h��lQ��Ѧu��Dk�Vc�@���/-�GSR����b��EI���۹R��J�����H]
��Gw�]5��`Q��y&{���TBx�e��|�V�q��ャ�[�ܧ�h��_���c����[?�>�֓_�pj�I��C�Y����}�<}�\IJ��F��%Z/��}J`��K�+�z.We�j>Wc�Z]��`g��+��1��G�?���?�G���f����T�b���ߜ���T����c�0��~�L�[e�Wv�<�����7}�R����&^���S_3峆����M�e��ʄR�@�G�`q���j�ÖC]{��A�&]FT�Q7�Z�z
 �\�V�S��J�c���,b$e��.�!����
���<)�Iʸ'}��f.,Ļ:�$��-���v콏�n�������.Q%7��|�$7+���X.�e껬��qf��D��W�:������J��yh���D�6�s?��;��T��+�b�y�+s���<���1��7`Q	��ÜQ�='����4r@�tG�K4��+�;}��!�/�����F����+�Y���$U�������]��A�W�Bƿ�
,��l����E�j�7sE�D��5�N�7$Ɩ,��{\^�ri����l��QO��M��u���[���_C�EQ��������\<��w��>��@t�z-�l���dOn�L��ϡ�Q5�9�A����|�
Y8����c���$c&��f ��o� �2�&.�����4`*�$�������>�a����@����g�+�n�w[���Y���k{���	GË2�0)�0���H6R#xw4�ȫ	t���$=�.q�
��6�����a��O.���zHY�9d������������W�6����լ��[�T����{5I���w�܅�����X?E��w���ѝ�6�,=Ơ ��t�r�]�h̥S:��w{Nj#��Հ�J?0N	��BJ��,ة0�t�Id�%6�<�����Q�ja.>��ϝ�2Xb(�9L�my�>��5P(�HE����ʨ�eԬG�<*��MQ,x�s8s�b׿<ވ��Rٙ�[4d3?8��l��Ix�~��EOq"<���5�.�c�b0�&��	��)lp�b�aur
�K��O��z�Z����'N��{ޫ�~g�|��xj��O^j�$���K:���<��,���?u����1�O���U�����������W�_��=r�O�?e���r�O�=�������{���r�_T T��H3�h���v!`������p�`�5���W�*��w8�������O��Ͱ��Y�n;���w�z�ې���ϕ,��d	����;�%����Az�bn8��o�/�6�@��J�sf�
�0P�ĎC)������V����s(�
ƻ�	v�RVG���Z.����<t� q1�2���dJ��)�a��J�N�Q���}��d#���j���nV��JR��-�ya0�oK�;l�9!��K�9Q1��С���s(��0�ԝC�A~�>V��$�d��X8�+`P)��?���>mI�I?��6���� ���	���N�B��)�>{|�D݀M'��Τߠ���\�����n\ɍN2�p�I�I����$�E����i�ɀHm���u��R�+�����2���Y�dI�憗�B&��u 2)���C���{2������Wu�V�fYf�����g��.JB��l1�-�~{a�`��_�",�u@�=J���{�u��J��l���a��l�6f
`���Y���#��v��Hs�m�c����i�V���K�X�
 �#���|̎5�������M�t>�i:-�"\�}So�7�廫Y�7Xo��9�w�m\�Tnk�*+��e���Պ���y���V��,�{����T���W����]�������Po��[m�V�(���<��9�\�����3��LM�d��d���V��unY���&�ލ��E���0�������x�����e𬦢6e�������wV�����3{��pt�ZS��L�0B��F��Γ�?5��y��t4u�V��mH�|m�����>�x��.�))�z�	�1^�\ �+К�J�U�Z��ҟ$�/j���$�A���_�É�@-YV�/��Q4J�_W����Y}z!;o8�]7V� ,�Э��H_I�z� ���x�Zc�N�.�~�S��Za2�+?L�y�8.@V�]��s��f�X�$Y�bi>�Y�w�������J�OYsJ�Ai@UN>��b�r(}`9��x�B��S-��z�=��d��9aղ���b����y��"�Ծ����YT+����<-���ڧ��Ӭ�������q�ES��O��s%��������U�?������]��ۗ����Gn���������)Q�)/:�6�Z���Y�O�3�.r���2��
Ȃ�U���W�*��w8/���߀�7��
�(1�q��9*(��ߐ2H%�]+�M*!�(�,������󙡂^:�������ӄΉ{���>��L�+oA]�BQ�#�e�t���Z9�OU�c���x�/_Y �"�|tG��� `'n�K�(�E�l:��6w0s��͉n7��G��{��Y���*���*�%�2�_d�������u<f�^#�f���H0�y��l3���S��h�] 4���	0�\�)���i��g�g����F⫸9k�/���=j�o;��fV�A���1$��IF���Ù�45���A7��djk�럠~��6~B��90`���(t�Q�g��xn��@���#�H�� B�|���81�����p�a�.Ǖ�{�q�nH����2=�1�)��3�	6'B�](��J��A=r�8�ߛ:�f�A��GF� ڣ_���ץ�)��7�+@�$T��
�ͭ��v���(-5�r��FDGT�D�'�+��$Eu�<���nԟ�a; 1���XW�j���ME��l*M�ٖ���X�9�� I��l���6����W�� <J'����OoEb��X����9Px��G����q��ӂ͟ [��4���~���f /��ğ}�3�|�Ig~)�B[�A��2w��/�~/	`��/]���(�eV��*R��B>�A��,$��o 	��G��E���|�\���\�]����_=�������뱫>��|Ƒ\��额�c����6F�k��򔵰�6#�v@����m�@�i,�'�(��n�6m�Q�/���K��]�Ec������{�^�����ܘ��3)u�uH{�O<5X�r��,涥 ��P�b')/ H��/m��4ֹwc-$�������N
K�s}�rY����wo��i�qM�:Ol7��ڈ��ڣ�F�O/����VذG�{C_�g�3��T�g��6�}2%ŹcG�8�L�H���p�����.�!B�<�[�E&���=��+t��1��Qz��(�����T���r@� �� o�E��F��O���a���:	��4����9*��� � ��4�7�Y<Ğ5�GF�P,{{(րlX�e�xm���x�7�0 ,���0u
-7&�S8�@��N��f�u���h>J� <�0ug�:���
��Q�,l���$�'�y�>ēx�"}��X7�v7��W�3|�HB�І�@�=�K���(30,�ɠ�t�SP�_��� <����;B�i��h���
glZ ��11t�LV����a~�����0��W��I~t$]���1p�����׭�x��&����Mn�?��8.���Sv���$�Q
�Z�dyim,��Q-+��n0�_��)ju���T�|&���T�s/ٙRNjc^�Q�F7�;��`�چ{Ԫ;o�AjD��1������s�t3j��&��M-!���AF�н��V]Sк�bzk���;�9n8�^0py��T�QN����<FxS�ҿ�v-���_�5䷵/��Γ,�)G��w�mo�6�1H�vP�¨A�ۭ����nzgQi�K��v-�i'��@��n�q�"��@�����ĝ�_�5=�M˂�߰�:�W��F-9ͬ������?r.`��M�qN���Nǔ4���g���|�L<�O���}57j.˧@�����\�%ј��_�3�OA�& �_E�俊�W�����o�ϒ���l֟��_�U���T��M���-�������Q�o�no���:��N?(�^&$v�%���Hb$_
}j 9��<�h.q а,)�%��鑀����@E� �N�F,�~��'5���Nl@��{"}O��w��?+��Όgab��;�����'�y]]���ucݼ�<��o���?��:�Ÿ��L���)z9wb8���h&���T�U����`~��{����������3S�_�MSG���U���$=���� `_�'k0>rC�A�k��</)ٱT`'g��˝�l5�"Ϩ4�"��. �I��{o��nTf�`��%��̍G���b�#�`^�,f��9	�ϖڐu��zo�u2N5m&�*׭��Ӟ�hJ��'؃Tj]LB�(`��P�
u��K�F����\ijGF�e��7rߣ�J�xv٥�4��FC�Ň���*4�}�P��fI��S���TE���#�N�7o���5�z�P�3;�ڣk�G��b�����Ò���+Q���������6a�u18 �#���}��8�$�'�MfSY��c2)fJ�_8���v|9&�hD��PUmekop��_�l�t�wg�k;��K�o�[�����?���
�㒲��"�ŏ�g$��=�v5Y�A3�gO��i<��]@8X���a������dN�a̜��Jg�x�.�g�Q<�:����.�
��?vA�wW���EH�������:��eT��+I���p����Gz��w��6�?1����Q6�~�~�F�P�(��\�t��G�F�X�W�<�����)�[�dʈ�@d³��]}42h�`]H��تK���g$M��M��7�an��L0�A�ZtNG��1��R@Pў\B�x-��DM5����q 6�|]�V�����Vt"�AfYj�K��x"6Y��'$�l�I�8���7X:�-��s{8�
-�q��]��D�������������y�{�R+uF�P�Qt��	-xp����C/���E�v�����đ�d+F8K��,����2��N�e2�0�k
J�moo� C@����t��ӛ����q�BK=��>
]K]���_ҙV�:�x��w�ɸ���x1LVP\�btf�Ob�l�y#raO����	�;���-�����M��9x� ��ر�h�&�-%��MP��P�5���Z����cD������?,n*P�!m��F0B	��%83J�p\y�p<��JI�Z���������?'��I4^b�Y���Z�fj&��5+�%闝�7��;�֎H4��������qRWi���_�����n�Z��l�;�=�G��!��^���f��?1�;D]�-M�J����%��4-������t˔����j��"U�^�̢�VN���i��8�i��vD�����㡼D�w��pTz���4���P�K|��h}�%��i,�ߦ���?���2o��-(�I��e��X{�k����G���hJ��Y��r�S�k��x���%�R�񫴖�t��.|��/��[��Μ�g^ �!{ĳ��6��ܤ��Sl� r�d�%�=)-+��&�Y��ɺ\�]�Ԣ>&�px��DL�x�Nd�4�N����n9d,�u�����V��͆,\l��˛�|�Q��R"������9 X�Y ����J&R4&W@�l�%��ه����2ݨ�Hyo�5�ݨ�����џJ��@	֖Jy�p;�-R�n�'�6)�ԩa�/��	�������$�k��?v�MIء�*������g�z�Rc�pׯ�^1r��ki��������#��.R���	=�-��ʕ�-4[
rs�pG͖�\(�������hn�t����K�M��R��2�"�gۙ;�Ţ�Ң�B�ԥ$(�����6 1��h��\vU��{��|Au�2'Y0U{[@���@��nI#�m�H����i�fw?xR�%l7���=�ô@9'�>a F�$͊XV�hċ�x�:�w�F <]Z&Ö�p�ۀ������zd�N���v�	�u�'d|; B��Jt;̎�	�b�|v�·9�A��N:U��t��b�"Ŵ��9�Q���������Q#�*T�)�da����	3�9	{MϾng�����̞\&��"اB���27^4��e1w��:�wY8�g	�����kƟcq09���gmy*��Ut��gb�,����6��B�����W�?�H� ���&�Úw/�x����S��_��U�o*�����Ү��U��������i��_I����_�������m�MQ��^�m��n���$=�b��^/HK��dz��b2$r��1�9�A�^���������ah����T��*�SJ�ّB�<#���A@�I�WY���桄Q�1O��zi��2���4�`�B�����!�Q�ۨE
�ץ�]�g���#%�p�ߵ_{�o���������w{����������������H�/�������rv� E)�i�G������N������=\���fe�?����Դ��_E�����=����>@n�$�;2)z O��*�3[��c=�G�nk���l���G9v����Z����A�����+~��,�"^�<�������o���9d�N7Z@�>y�Jd��b��z�#H��4�+f�A�����[�g��u�q��ȡ�w�J�p>��<�"�̻�����2��a��&f,��Xt��XE�?K�+��+IO�g�ކ�ly�o�:(�v�R(��{%�l8�-z  `��c���ɱ�b��+�c)��ʂ?��7�^ %�/s�E��q:(���m��ݭy�H�ۅ�����G8�<wCJ3kB�o�����/pl1�nХ'r�^ۅ��l�BK�h+b�8�$�|HB8��Bf�o�k�*U�JU�R��T�*U���?��� � 