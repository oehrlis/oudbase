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
� ս�Z ��z�H�0X������e��E��*9�jZ�Ӫ�֒lw��,5D��$�H�*[��ż���7�2��?ɜ-6 $%Y���6�:-��XN�8�9q'��}������Ǐ����]Y{���G�>\{�t���ZY�?�N=����4��L%O����`0�wY�����s��N�ǰ��4o�g_a��������#��G��>z����õ'�S+_a.��������6��I���T��>��Q���8W���4��(��ft��(J&��p:��D-��<��;�ateQ�O�0�#��������5��0�LN���iC^ē�G�0L�w>��p������?v���4�'� L�^t�c��Fy]����ҳ� Z�tow���m�q3��q�VV��Zy�Z�#�r��y�&��q���<�/a��a/��5I�i��E*N`�I/R<�*�&�D��~��L'Q��;:�]ʹ�k���RM�i���<�҄�@�N'���f���h��4;;�L��z�}
-�'��6�#GJ���oǽ(�K�a�����/w����Nڏq���kE
f@`h*X2��%-�~����Q�!���Q8����Y��F��N��6������<�m{�>�	�{�y|��wt���|��m�Yl���yj��i��&}��pu�	�<N��p8��[.$x�=8���}^;_m���j��^g�����vt�[S�>� QÓa�;��x���_�v��^u�o��y���A��3s�q��t����>_ZF<N�V���zp����u��8�;��y�=�k����6���kp��_o--Ղã�����ng�{�FߐH����KK��ѯ���(#$^�$P��3"/=�;������A���9��M��]�wt������`g�4���~t�N�á��9ꝥj	��hu��ki���e�]��&=Ľ��wuws �Qo��4Z��OE����ax��pd�AUByz���䧪���jO��"B��<;�T3V���������P�M�=����.������"������P?W�T��`���^�G /�/3�>�z��P�x=�z�w�>�΢�0�Śс�l���z�غ�z���8�z�v�V���r/��#�73�.�
~���]��vzJ$l�z{�$$W�.�����j�NԊ��2�$���Fa�I��6�F�>�]�����nW����(z>����N�_��a�bR6�G$���_�t����'Z�������V�[pU�|��6�)`�K8ɩ:���>ô$@M]]� Q� !��*T	H@�	��>7p<�5��j@���v�ǀ?;�@�� +�ڿ|�c�Q���w�׿�Y��V��y��`��ɂ���۷w�5�Ϋ������5hU|�KQ�,�׈�!�^��s%�A��Z��ז�@�����	� OM}�����sh�����nL38J���,L̷�3<�4k��0_�k?������
��r���:+-���&Q�&�ᶽxQ�����'y}��5]6��e(�"ɦj:8@�)�O�XZ��*d%����U$æ�J��X���YK��K�V��@I�y��6@j��[��ħ*�ӄ��0;������!�)�2$�4C9ɨ��v�!t�jYy���?^ؿ+��� ��|�NhCsdc�Lu^^)
�t6��F�9~�9,  �pTz��ɣ	u�=��x�Ң����E=o��a�z����k��.�7�f��}�~���=@�vKO��������廬�`aQ�}�����Y���Iz�__�~�v7�&	�-bꥣQ��ݭݢ�~��N�ء��Ѣ��ɇ$�HT߈��1�_�tB `5��M���w�<'��,����:�[848/����5-I"���d�H �$���R9���y����[g���&���xC����֢ee	h^o÷6��+�j����:<��J�TN���!n��S��S�e�O�E�$��A�8���#0^H0��ҌfH�Ml��?W%���� ��D�0�2�Zq*y]:���lu�N��|�^����p��,�����S�w4Y�y��o>h�NW�u0��a��J~���^}�ه�G[I<����P�'FuÃ�,2���jivh�O7c���ج�3J�ЪjU�=�|m�h����;l�O�{�t������U�_�ٝ�7��
��cm#P�j8>����^����a[�Ь��I�:4�=�EsG �0�L�OMYs�o����y�����=\dI��p2��H��?�&]��c[�_0=f?|���:�}��c�l��_����N��[���$Ǫ�-��JmA 4
�혥�1 aCX����2R�)H�	9&�7�&�`�O�i4Iǀ����,�C��Z��!Bvf��ӱ�&o���x}s����z�ҲQ�X�'�"pVC�C���}��-���K�=��4?x�x۱�qF�_tה8�mVW�����E����}l����z�kj�ˮH�44�_R�e+��p�ecQ�w�����c�ꅲ>��X�;0��#����"d� cd�Hq����L�*�у�cU ��%i�R�|���眓#�}�Ct�lfS�q;��/���R��J[ �I<�,Kᅞ�S9��"�M9Ǚ1\�G���\o�*��W��Iѯ����O��6lW��^q���23�	��2J�E�[�ȃi��.����x��}i�l�߽9��0��$i�h<����te�8�q���ag������U�¡�$9��ꅏ�p�pb�9�=�8l�F^�k��{��`^�^т��A�ݞ��F؇�^r�zy	��,5cu?o�m��l�w����K
��e�� 鶴M�5���I<F�1�x]��H`Mm}��2�����,o�Oڪ��j��{`��7i��t\�)�V����9=a}S�D}>��s�5k�{�|
r=̬��K:�{�k�W�kP�yT[;}R�R�H��ԦgU�3Q�C�C���o�ҋj��fg��s�t}�1��v�S�b�w=�Cg�rx�A���ak�����������W�g����{@/��=_}������[U�������SY��>z��}���m�	����wyI�.��<SW�'�D�=�1C��|��V�V��ǫ�6��mcy+W	rE�;�f@�)g�K�y��������]t��Dp �2�����Y�.��f����������K�{��t6w�v]�8�͆�Q�\��V3י{9��zK������v��Z�9X��9�cT�s��,�מ	�_���v���S����s��&�!}N�U����J�(�V���O4�/T���o(Y�9�~^�`��v�D�GW넬�;�vU�ȆcG�T�d
}J��N�i�Hr|�Ys�fp�Á�E(��81͐گ��hx���$!���B]�"�M��ߗ�2�U
ңGe��B���̗ZR����/���"�G��?\y���c��Ç�����W���������7'�#�_��C���+�
O�����F!��#�շ~��J���ڭ����W�ɘ�_)��"�q�b�K�݇/Ts��wP ]?ƞ]5˷���~x}y��@E_0��|�ۥ噷w�x��$2��M��˭�M'4��A�6̇,��ϖ������������6QՃ��>Fz���	��������~��5a�F}CFV9����P�T9�o%@k[WL<��,�f2 Է�o �[������H��r��̄Z�����#^��UHr�	l�1J,���7��6{@����B�T���E0�D��	���q�b��d!Ij&�R�TE,~|a��&	��B�ɑ��s����Y�ʏsl�P�uhuni����(ʩ|�X�.�o	�R�>����q^���p�|�-AW$O�Q������E(YNƏ/�j�{W�_d�$*�/�F��xf^�(C.W@v�t�}���C��.s�Pb�4C:��T��/�p�t,G�!B��P�i���]�:k��Yz�Fx�(�ǝP�	�l��Pf��--_�Ts��w��^�#dTK��K�N�� a�n[b��1��ƕ��W�Q5sX
s9�5j�b-.��3q���	�W�S#�5hI������vw�^�
Z��$K��ŭώ���N������}u�����g���Xj���$�T��S2��
+�e��,g�G�}�}h��Cu�IL`���v�s��f��*(�D�V��:M����G��z�B��F���`�4t��K�Z/�m?�Y0o�o�߫�i��e�-����"w 7�P���eӘr�V�k�(����fA�.��a_��~T��8���R��+����,
�Ia+#ŉj/�O��;tl��mk&�I����b�x���ц�c�R�a�6���м�B|Ι��dXF��ǎ:/��ǩhH�8��"S�su�o��+�k΄��z���jmAg��Lv�+�>��W ��������f�s�~�ɬ��i"i.v!����Yi��WɪtM�{��/���mM��RL�c�[޷�/���q�K�����u'�ұ+��s�LuAg�`�X�i��jy��My�����,3u�q_���5����$� �'�������+��}"=����O��H'P�3Wꍙ�v��U���~D���&��)��m�d�P�?��ْ�N'Qr��!
(N���#������L�?8O�Y/�BDT@7E��C<v�D�ثwE|�����YuT�^�L�dj�QN	�?��R��_'ߩ����v{XGD��M<<�F֍�ktLe��x�l>A����\��Єm^F�M��x�|)��Y����f%��O���z��&�*��xL4�:��uݷ	Pӿ�M2���ė���Q�f:�1"��^��ʹ�(~�������Æ\��46��i�m���~���BJ\�m��kW�t{�4_�>@/�9V��E��Zm9���c��s���\������C��5B��d�lxB��o�3L�A�Һpa��KII;��@�ӷ������Nx�b淚�V��'��C8@*fȨ���7u�ϒ0��>;HӉ�6֐�������a�|X������ $�Y��{��Y�ތ��pڏ^f�A��b�=Q��q���������Z��E���mцou��9�9E�9�В��֦���u�-�a/\��A������E�z��{�殚�>��f�D�I����d��uZ�\̳p��p"�Q���T��ql�:�/%@���|7�_oaO�((	�
;AԌT�}Rn�^T�K�Sz��?C?�I-��98fT E����7-�MN��9G�?�$T�IS���t$g�
٫{ݣ"� 6bER��&�O /���r�z"]��D�=!�J��ȋ�x�ȳk�)1͕�c����Tm����kT�՟*���0G��Oe�l�\�iM��&.aNI��E��Q(�1'7����E� �\��:���q���b*�r� ��3l�dϿ��%���j�?$�g���S�����y���[�ϯ����#.����ϑ�#v�o�?��n�׷�������H��������%�My�g�m��v��?�V��.{~a��C���C�8�c�w�ךM������ʶU����Ԥ��WJM����%)����ޞ��c�m>ΑRx$��q����u�m���n?���u�=��ڳv�5��&
�t�hV�_�a5P߿�l�����������I�ŷ����$��G����-鷕�-�?�r��
~�A����-�[ҷ�o9H�r��� }�A����-�[�o3i��a=^�ֻ_#iRW�:����PW������_��#���JG�� �C�ʙ�a�U���h�W`�oW�;kh��2u�e�|����dg\'SG��-�-т�F�ฉ
�[���J8D������^����?0�l��sl:L�c�NR�?���c�;��9��7 ��mo���>نWM����8w��|<�1
/)�-��E����!�l�P�I��5�6�B�I��<�_-�cb�mO�S	i���R�����9[�B���WHٚ��t��-�����u���4+ɺ�)�ʆ&ɶ�v��r�T$���"9�����K�H�R��T���T$Ab)e�Vf9#�<��,wڳ�g(���񆒨�P`�[̄�D�o�#�n���8�����Ĉf]9�vZؔ��92ߪ��<�:�J�e��p�G���ά�>�sq�9n�K�U9!��c)��0���zqOv�m�� >� ��Wx�.4Q���������: n��H<Bkr�w��{��f ��2��J����� �w�j��uS̊��=��p�c���&��A����V U8�}v���<+g�$�J�-dY]?�j�������(��˓�n�@�k$O]/qJ�w�ĩ�'M��W �rSg�E��3�����)K�}�sZ�P@��%��4V�d5*�U�����~�J�K+̞�W��l��Y5�*��z�\���]� ��.���<�����h��lc�M�dvw�ȶ�+%�}����]���Ƙ���te�>\{�����ӕU�������o����[��L����'�7���6=����ڞS��}��me��=ٷac���S���C.
EF�sμ*nݹ�\H�u�K+���m�7_�W_�}
m��C��o�w꧆����Ǉ{o6�?��|U���35��*
��=���t�}�BFv7R��4����s��9:��>�������;������q����?�_�o�ӣ���7�����[��7�������!e�������{�c�;`x�V�})m�o�Rk���0�pⳇ�١y��v��b��1?tn�6?=Yw� I�F�Z7���W�*�;7Ǔ@/��}\Ep�J�5pW�`����f/�!�׬	�y�SE�]�\+�A�ӈ�]�����v���iz�s��*�7n?E��7Mr����=��h���	��B9��&���P��c��lu�����u��$�)Ǿ����f��]�8K��������&M��U ����R�W;��4f��A��g[?��9;�}n����B�8��ƚ���@���W��g�P�?WWB;S��Bk�������tF���w' C�&��i|�UּQ�5����8R�W!�����k;������:��3�F~�E �p"�fDQ=�ӝ���J� wЬ`j-l^����XjP�}���~8	]�c��s�Ry����=�X�0Z�tgI�tj����-��f8��g(Y�o��:���s߈���2����i4w�?��}�/�>�g�]�!�"�C�������U���z}�j�O�tP�^;��󶣇4�p�_��С�(�� ��,
��	h>���R��%��7Y��$�a�g�|*���B�)�(�I�_ѵ��_�\z���R)�gd��=�m��=^#���&7=�2�<_z�D�\?���E�������04��.?���V��E������מ�W���	���B{#q-��±�:@T��j�z��y[j!KJ �M<^������ϳh2��Z���ҙEa_I��=���EW�:��ա�����mR�H�"�g��IB���h�m�=�����^j?o��M����)�����սQK�� 8�kr��HǇ������p�}^l^ά�*%He�bO�
C�����5|����-%d�o�0�}����~��>N��^ZB�Շ�Su��'�'�}��Ɍ��O�Oh��?q�>٪8`3�տ�tWTG�����4���z��5��:ך����i,m���)�oO[X�F�N�� �W��+(g�|vu�S��u��V�D��ӕ��ʟ�����k�k��O��z��i��$:�7���^��kֻE����ЛΛ̛ʻ�֝��02�t���ǜ�R���g�p0�Kж�E�ߊ�mP��ϰݼ"���]��[��W?+$.zř�){s��+.O%�Cv��B�@�%*V�����}��:!��94�ΑX7�������ҷ,/��Kk����fR�b/^T��*����(-�w�|E	R��#e4e�ٌF��eKm�ԭ$����"�i�V�����I4�k�4%�l�=��1��v�����$NN�Ե�*�,ꚰ�z;��W�g�q@Ҽ%-���g�������~���s����"w]o�>lv�9�6k&�F��8^oh&%7fU9q�l"@L.�	��4{�����D��wٴl!W�p�"?��⡚)!_x��]^������T��{�Xz[9Zk�����H{��ǺR�.	���������n*�:/��6���Y�m�V�~#M�t)�����m�������^�+�3k%�����]��7��X}%%9�t\�.����]n{n���[n7g��9'�J��"��i�'�V�73�,?+}���V:���)����%��,q���V�|���WA�<D�2�>�W�3�4Q�U�0ɣ�i�n��6��M��.���;���n��ӽT����v��.���Y��._���9�XU%oK\҃�3��d2P��k>��w��5�����7ǚU*w|e��z�M����K'�'�����|��q��M��N:���y���*��F����]Ü�.�#��	�LPp�c_�*���q
��Rġ��e�~�� �=��촕��y+���(kQx�	�;�`���]A�^��p:����T�c^<�~Me*��'���|��w<4�C_�_���='��I;��"�{��
��t�;��?���V�~է��m�w�
Q5�&e������!��'r���5�琊F��*�)�]�h�r�瘲_]Y����rU^x����_,\ W�����83���sO֬ 祹	x>�n�-*��J�3���J�Fɱ)J[A��(c��i�7���\���tr��hu��9�i50�p-��^�^�3�-����6 �� �����슌�HGrb2l�z	�\�o�M#O��%��2�Y���>+��j���
�_i��1�����|V,'j՗Iq��r�09���������O����G0T�%*(������'@�>��$���ОE�
��3 SK��T��)U�P�V��-�n��oo���w��ƛã��Ѥb	�y��?o��re_�y�}�^xI��s�_�Ͽ�9�W4��枚�4����;&��0-��^�-.C?/4w������7t0n���y^�_~�[�s��Gr���y�_�����Ux�x��$���*��z�*|��~[�T��.5��U/t�����U�A��lϽ�.щk�a淣#vR���ʺH�:��%VDi�����ףu�����m�o�}�dq�7��a�,��])��t����@�X	LNk��db�ՙƪ�;p�
O���t�gL��# NfL�$� �����8���
��y��ř�En|~��[�z�����ª)`>�i@��J{�[Dd=!/���-J��,-O�����U~�b�,��~���$���߶e��(��� �uL ���ZA@v��$:]�����L�n+�BJ��˭����k��k��*ު��gCg��|�X��̽ԡ��R��Z�~E/���&'�T����߁\-��Z�����O���a?5����$A���ٹX������%�/��
�P=R���qb��+���Z{Ʒ$=����ڳ������gژ�A8��m�3Hy���_kw�"����9Ga�q��6"��v�Z):��
2!������(3_� '$�����{��^��m��Q���z��/�iAIzA��d�絚��!�?U��ޒ�^�X���.8˒��IﬡFQ�䬘��c�ףN�V�)�*�9}��x��!�Q�Yԟ���g��$�;�w
$�#���XA3��X����`��Mjs�54c����7�����J���:V�`�Fm�dϑzJv`gQ�!�Zy�8���p����c�79����Y�K���1�F P�7\�->�(i�S�mi�;X�k*�m1M�Nj�*�.¬/�6��Dp�p�$���!��W���gr`d�g�(Z��9�AW���؍b�FO�>�B��3��q>9���^UԸ˛m��b���X�5���9Ş�5�����ދ��kp��QoJshK��y��v�}D����+:~�����I9��u3ާ�v�W�nǛ��ٹ������x~��� �R/�L��X�#=����L�g�w�=���%^�<{���4��<�8�'z�H#.���>�hۯ`�B�/�y��Ĩ�טh�\9%���U�-�S>���E�JB�&���K��vQ1�$(Kݢ�[%@=רA�쵪j���,��!WnZȿi���T%��p*��S1�OH�\����lq�+�N����p�W����9���+{��^t�U��16U]}����
�a�L��ֱ��a����2g����.i^���Z��=[�{.6�ef��Wm�W13�GȀK��2�S�g/OT�?Hh�[�Dw�A���>��T��������aQ����uG�
&�/Zx�O�4z-y��R�q$���K�JȜ��O8�~�ReV�v�x�ނT����g]�C7�n?���p&�\$�^����9��W�X�D��'�̺���9WȒ*�*�&Ud%�j]nYP7e߆Q�A2�Pϱ�`p|�^m�4Nۻ_B:�=J���Isx�w��w�4����B��{��#{�'�FW��K1n)\`.:��s=T]����=���m�oa���NT��@��;]H���m��A��w�)�@��s�q��\"-�����]@�� ss���9 �|)���;��-y�uBJa�Z㥍 f=��Es(�[�KD'����z�\��O��$�?�Bjð�r�9���j�N���+�[{t/A���mw�V.���u9�oҭ�N6�3��܍�JP��AA����w�9(V��_1�9�󺂾ؼq�����Jt�U���y�VH��k_���W�^ѫ����b��ܤ���k��@��u�V�x���o_9><:�E��7��P7=ۍro'��]�w��K�池�m,�^x輠ST���y�+�,x�I���>�����gr8��T��ѱ;?�v�D!�BG�W�Z�u ��(c��ZP[l��FK��9��#�ɨވ�Xo�mr�f��BS�w�Zc�h���e~e⓫~�ՠ
��� �M6�e6�i!��O.�[3=�����=��\(�����ݾ�6�#=*=�嗞Uq����\�N���h�զp��~Ew��@���Cc���/�]p+x�1Ǆ�j&��г�X5���k�)�mE?(fVUK�@�/E_U0a`��-WQ$�[�M���"�__K_��_���e88%n�I�[�R��m��]�cxט W��5B4:� ���Yz��P���څJڇ(�W�I��J����<��$�OF��b�`��WN' �A�s����M�FF���.ç���)�꣸�7��z Vh������~�k�����]��~��(|�E���6P���VQt�ߵa�(xg1G��[�O��Z5.����~�7*�ދ$�K{�3��l�
2�)ơn��/*̍+�f�7.j���n�p��ŋ|h�����[c�����>z�׭g�f2���U��.�Z�rr�se���ո�78^Fv�I]�,"��UZa���)�W��4�����T�.�/�L��Es*6�Ab��W�,��t0��[��Ά�\{U}��C!��t�. i������|�@;L�GO�J��;���x̼hM>N��ǻM���ݕ�NWvͺ1-w�g'Tn�Y���fcx<`��l��l^>��]����<fHW�gS����O�wE��GTct����Z�+�%W��3o���l�ʷ�>��~�k�1�����e���O��=V+������N=�������?q���6���ݯ6��ɣG3�u���Շ��_{����_�������F����t������JP$�j���:�������2M"�� �/���l��7��P�ʢH���F/�����`&���^���A+�N�/�=��K��9�L=�'LN����%�y}�v#>��h{��`;�84N_�7�|���"Gk(hϙ�����p8L/�f�Y˥�~�#�հ�Hr5�o���	���:�z+Xv�f<�(P����
dV�O	� ~�[zy+��J���c,~����2���<>��m��k��%ߓ�â(L��8�DT��R//�P�w�N�d��d%}ާ�i���=*��F���D���X��4G��$�5A��JW.Rw��m��z����"�ԛrDm0gM�)F�f��p.�x<D���º��Rv���`����K�aH��L��IE=�o�AK֟�Ҕ0��^D~�� �|��/��y)��X�x��$g1־Q{�}�j}�Q�)�
�P�'��A!�$�,�O-�vg�����%d�R]��Y�a��X�E����2B��E��^.B�z�8�b����:�6̭ǳ�N��4OoN��>`r��O�Ä3XÚ�g��N0�����^N��D�q�S�9b�8 @���=�Ep��"�3�?�Ot:ɬߧ:7�U���t��qS�^�MBJC�
cy|�I� c��]r�Ԡp�b  }? J����i�3\��xDh��Wx��p4B��f�O{g����8���T"���V�H;�1�C��,wM���a2�yEx���+/!V_NuT@q���C�Э�Z+�����T~�B�-�|+W9M�2 d��b�&'�Q�& D�	��vzqR��"�k���z��ZWx{z6!^ü��m.b��Z`$��	���4>�x7�N�8�͉��m�;ݵ�:
��]��3���l�a�w_/��/-��:���z\H��Y���g���P�f�Q�|���̠9�.��sg��{$7�[tRd(�,���E�VL�Ān��f
'�>9�(��,�<Dw$1�`�#�ҕ��K��
#��u��G�,ᡔ���M��������>��p����Q�w@|�C�B���t 6�L�07:�\P8�h�bT�N�)@��0Iv����i��/�)�+����$�4���H{�iF�I�0&]J̢HO���)�c�9���$�QB�)D��/�H�#�>M��	�|�z1���� �53��RD��3 �b�ci,|M�x驶�P�� Q�a[>=A�
���E��K�i6�{��_ ZaJj�Ȭ�3��HbJB/�J��`��k�#�so`\%�*ͭ��;Ut����P
�l#0'g�fD8��HK��cPp�?#��:��M�&T��u�0p�zMJ���'lXُ�١8�s=����,�Ҥ�P�~J��:��i�I�:˺�H�qc=!�B,՛�S>c@\��@[{X}aH��+U�%�K�_��jj���
Q��<�#�1�b4Ar�;�ݏ9�x@ɗc�;:.�_�~�ˋq7f�BG݃�C���ī#7����v��J��	�H�׎Sc��W����͔¹#�U�X��b��5������"5��Vi6!-���(F M��0�`���G�v��2����$닎�)�灞�R��&�����95׀�֠UM^��mI�
55��%b�K�`��+������,:�I�ќ9f�~8�c�_�x���`�5�3.9�I��.�p�SFf'$��� �X*J�Q�;6���9�� H��&V�9(�Z�"i���i�I�v[0:��K�/h��j�(�	��J̘��N��{ r��l���;<�P�"���&�%0$�N�E:�c�@�h ���#���#DM��u�N"ԝ�d��Aum�>����#8@�?"o�I�l��3h"����� �s]ڳ}Y'"p�����#�GG�i�Н,S�D<A��.�{0���* %vRM��c�B~z����h84;0:����ϼH	f	D�����u��/j�JT����P�!�!p�\��+K_DƇ�T�u��i�k1�&�\!a�TK��c6/�lb�9�x z Z��b�茙��Vm�����ȑ�щH:`�cuW6/��XsT�s��]����r��~aFfs�ۢ[B�=#��&�:&P�/�%]��p!/�""��b�6h��d�Rԯ%̚��LIev�av�1�xh	�� �0t�c,8@��I��EbU��8���Ȳ�5a 'v�`e�!�v&1��(�H�E���A���R��@�S������DUv��h¢nX_Υ�d��c�V�0&Ȕ�N~���c��l��!�=t��GxQT����@��;����9��@=�Qca{��Z J�T��x�oIP���%Z/��-���;�D$:���04ֶ�a��4<EcH���z�6�da,�X?���l��B^tv�I��:�B$j5�B��!g԰ᭁ��
Q	Ԙt��$/�u����}�6��йއ��N� a�U���Q��*Y� ��Ӝ��I]Q�}4İ�ńUDt;aQ��q������%|UF�0�H����P3�%ք�p@�MP+̢&h�G.�A?Nt��6EY�3���R����h�$>�c#�c����
Θ�S�.!1an����u�ȼ@&�>V�~�7X.���a�i�@�Jk��vp����D`b��>�͆0tû��	�GNb�OB*�pc�B�Kk7��B�g��k%2]��ao�`d�M���.���	�rL�c@��t(*��`�_���6L�Dt}�t���x\	�E%s��,��p,"�{B�5�f��9B'@p�I&��T�e�X�l[Kk�>��;���Ӹ�'��i9z����&�({��?-.�$���	��Kw��#��`����S�]k��@]+����f��M�C9�*��h�h%��]F��N@$ÄR6Ǹsp�h�Ԉ5���
�l�wqȈ�ڔ��dP�"[aޭs$�Xylo����?����g� �eܮl��u�2������bl>%/^�B�"��?k!m�mJ��}m�'{0J����-�1^�u�8�*yM�IR��\��ԀF2�O�a<��߆�iKY�����yW�qB�2puHRX��ɥ�r���P� �#�͉.�#�X<�ND���;I/@9>�xe�v@9�٧��&!���p��9� =��uB�`���<"�8F4Vj�i9Pmї�µ�g]3��!�G���y����,�6@�I�و�^<5�3�1�=P�0�2��s>t@�I��eY�(�Ӝ�r�̋(�@�]�H�2j׀��%�b8r0U��'�]z�	ȋJ�pҊ�]�ne1�g�!(�D���n�s��;�¦�TvM�I߃	ڠ��,r���  v��q*:ȴ66�:��್��{��6ˈ�v�9�%�>1�[�u������nb�0~�^���#]�ۋAA��8G�����ʩ�!���K$�{� ��C�du���9� r]��&���tD�=ް߃��>��<�V��2ځ��m9����y�JE�BȺ}��Qb�&f،�Y��Sd&�[��ƴ0r�Bp��`:nN�=RX�i��a�������s����g�ZS^[Q� �����?=�3�@xQ�"C�F��b�'K����5�6�Q�V�/�"��<ե�Y¦�F�)��L��o2!	�{u@<T[�^L#$��=Oy�(�Bq����AÕP�DX12�8�T��]5��B�ɱ
g�ԕ�H �(|�".�&>��S�����`��4K�TC�v�Q�9�ou|��\$�[���|?�Df.�6�aZ�xpX�騚L'�~vʒؚ��]�T ?C̎�^/qfs�]�ʽ�C+wȮ`��"�1��/4���\hA��ɹ���E{TјEq!AO�S�Q�?g��4�^Ĵ���ܞ�4N�����OT���U���Ek��H���a(�HQaj�����)(H� `?��Oǔi��Q
m���	�)<v�mG�v"�u��s-�%AU���a��ܱH��Kb{�F1k5��#"�}T�����MC���l�=ta��W��!���.#c%R�( �������v�!VX�I��'����,AqU���S�y�+���E+$ۑ������i@�b��&��m���a�E �ˌ&�X�����>C�%B;�Y�s��y��H����
P��D%0	h�����`��3(�<�54��Y��C3��$m�![vf�!Ɲ���AL\��M�P�).HXP���}̅��V����R|��B�ș�j��9v�v*�e��GX"����f.��u}G�%�f�Z RD�F�ud��L��3��ؗ<�UId,�����䆖��0Ϧ.h�A�����vx6Y����r��Z�h���7C��R{�n"���#O�!��� ;!����j��#�� ?1��*���k�<N�"��jD�o�;R���9	j��)"4�mc=S"�l�;^j��e�6��hFL���`������/���I$A�Gگ/J/+2�zJHe��>�����M�r�s$��҃�}ZYAwD���婻 �;}�3�����
���L��s����3������ib ѼJ�Xa��H���D���qX��`L'� ��6$��C��2'X¼��ek�vZT�h�A��h&��+1��6��YZ	U���L��2��I� �%��p@�e���5�L�2�����>K{,xIZ�_]FaƦ[�	sN�����1s��C�2��Ɇ%6j���8���a������n�4\H�'�ry�0=�n����2#��f���!�_�CJ��p�Q�� b5�������\������y�Z��XLX�!�6�Uԃy؏"w�#,�Iؑ���X	N�١��v�n�Dt8V�G��<�U�].b(+_��ڨĆ��s��XE�:z0а����b/ڮ솰WO�y�9<F��p�- >9�rь�"�g�#?{f�NOX:D��r1f���΢%C�Z��]���Q��"�If&t������`��u������D1�R��w�S��=�3Cw�Ҽ�������#��x�C.�Dh�̖!�D��֚s�%ވx���-�@.����_V�QE�Y�@}kƸ�#P8��C�C���.�gB��w�jIF��3 0���r6p�ڸ�B�F�d�P�QKlð����ۜ{�d.�&�yj�dGQ֜�M��ÿLȟ�0��3���#0���]�'��b���-^>����a�6��Z�H�S#�ѵ2�U�5�.�F��љ �	�p��x`p��^R}��px�w�����Gv����H����x�Ð��h*����|:b%��hE�D:��Uö�"��Yg���H�����K�p������^.Ϋ�r@�96.ob�þ�6 ��l�N(��Q�6�J��JG�-24�C,a�bA?��LS�Y,�^ؚtx�p��)�-����l7�Jg7X�D�ZN��=U� ��U��1Ɋ)G�z�0"�on湓��(�%��xjr
�+^���+l�M�i��0z��E�G4������g��L8ʎ&�FF��{a�z��>�`ःV.@�ޟ�4͠��d ��4��I�'0��+���	�12j��,� F!�����V���R��:<�=bN�������F/�c�!y`������˄/�}k��wR�Ȉ��BQE�Vٺ���	"
�����ϖ�"ozh
�)�*FE6#��I�L���n"�Z�2q"Z������r袤�0`S��Csȵy�����L��Q(A�[ω��H�k��D_4>��znT�@�iYt�kc�i�3�@73NLf���9�12p��6�d o71�E"�gD;��G�i<�4ri�4��,W�7����H����(�da�n߾��J�ē��{��լ3�)�Sq �mc�!�N@��1cýNRv ;r �ޤd0v
��w鞭NJ�5K��)pτ���Ԁ�N:d�q��S7aK��=j���zaP�B�2�;�ң�H���{D�Qpl��~���cc��9K�]2x�T
J�1�/��Q��@�"��#2�\�EI�	��*L �vg���EE܊Ƚu3���\��tH�x���P�δ�эa�6�.�ei��I�Ɯ��Ta�>ki�r�߳��pf�ll",��9�e> rTp@�#�3<;`8(Ή�J�k����4�� P��'�	�E���-6��������_�(�՚��:80,����q��.�7u����pF'R�aq�Oi�g]n��z<r((�5�	��iw��@8f���l�1�͜L����,/�䂳Ém}��'�j#NV�=`˷�Rwch��V�=��>�$�[R�	:�7N�쮪���Tr�"	�/���c��]���1l��
��e�R7�SQ���՛,�Y8�%$sd�A�>�- ���,�i����Qz!Ӏ�P����\�"�[u�l K0c�H'�(6�w,vҘ|��wG�C]�콕qv4�ۚ�6R&�}�yt>v���EetƱ�I�	�]�,�-3�sB�2��|Zt�����S����cS�H�����B����Z�06)ά5� �\�>&b���8�g(cj'āI7%�%;7�˦�8�gv���v�2�LE]�6�0ӶŒ��:����2��=��G��v<��������7��{y<v�4N�rkqV�o3ngԨ���Zl�
��9����ܱ3O$4��R�u��ll9�jH�*q�'�7���ާZ�N]O��1�p��Dg"[!�.e��q��~�a$��-xۜ�K�	>�w�b:�G�VgW�0�[&�Y�K?��s�-W-�,��6J�M]_T�����@uF¶i:��^F�ɥ�N8'�U�k��A@J)�]���� &;��\!��mB<� �!]��i>0��$����$��@��L�5�k�� �)vI���c�g�'Q��0h5+�-deQ���X�%��:=ڀ���P6)U�3�L���$@���(sj��~��b,)��;Ny7�֩��{��Y��F1��޹�̚�k��鲘[��݀�pY(�L�	`s��2 ��B	q�| �uR�г�#�
J�OP62~��土�x�Z���uq۔['�I�\C���ka�(�� ��~Y���i�|��"%N���}P>�����
;'	�4d�9���a�TTE�	^��䍰�oFL�)<�XŅU5���&��ȫ��S��F/)�ppS���
��[!�6>���*�>^;Aa$���.T���Jq"�p����wuL�EP����� �#��CY,�dPeeX)GzYUI?p�D?���#ֆ\F�ac���@:��M��@|��ւ�j�"W�!�2�0��'+�OR�`";A�Ew@�M	�^ҵ�8@t�TZ�~�VG���`�Z��1�	|��$E���anBk����iY>�[=.(N�&���`���>t�H�Lglg��,}�_Kg�7���=�1s���+9P�"�̀B�o�h����ini�bS_d�3c�%�b�n��'�M�'�O����B��h�Q	��^�2J3�?���7�Ki�����^^sF[!]B�N���]�#J�9\EO&e�yI6����n��m���CɚO"�x!B��9�L�������7�7ء��������yK��Cn 2Rj>�~�q��Bf$�ج9r���늖��W�	~%94ƙ;�z�@.%�6$ ��
aX�s��$�%��|�D����0����z��S�3#����x�Uө�p���Q&���0�[�eW����O�A�X�,Hu�!�E6��2c�����e12�[c���Z�Py���K��G���xN��WnI.���~���T'G݂ʨ�P��>FQvʘ���"�6�R��u�V�ʫ�0wvM��e�����.��H�50n����:߀}-�l��O��E�frr�D��
��#K��L�L#q��<��$K��W1�Q�.���9�8���I�0���VrU�E�F�S�B���&i���YH�G�Oy�i�4�(��;�=�X]7K/áx�R'�����\��U[��]1]f=A��DrO/X�KMN�����T�NNL)����g�Z�A][�ݷ^�s% +5Ӱ��T�=J��E7���-
����'�*Y]m�}]�R��K��f5xS�L�.�T��&������
���ƌ'��6�mmB��Cd�p�Y��{&��ki��`/�7�q �'�;�8��q�-��i�!v)���iCs
,�GnAg�I�a.Aqפ���A9�\�9��+��UFB��Μ9�� XAP�g�*��bl>сkx��b.��tX��l`�6�J�Q�;�N�c���.�&&��3����=���ig�a!�5L��z��XU�P�&���Tn���H8Q����e�^�A�hw:�|�m��J1G$��e��Y:�#���P�Xͮ��T��D"��� �Fb�b�{<a���ap@*�K�U�T䞈�[r�.��s��$K�b��w%!'r�eS��s��d����h�k�������҅)�)5�9V}�jK�Ҩ�&�S�UQN�˨��)+p�2xR�*g��Nu]$�#&@`j�S�`���y���)IJǶ���ip)�<&MQؒ�Ibkb&ơ��Q'�U'��X+�m�XY����<e�#�Z���P@���$J� �j!L	w�
c*�-?4#4\�\�"��L}l]z:�j�шl* V<�kYt�Bc�O�)Σ��+2m(���*(N�rP2o�̓���m.<1N�ʭ�7������1���pK�iq�ҁ29wbwAI��aG�S�@7`>9 ��fXfyeR����:�c��Lۜj ��L�F�N��-Dn�TgJ_'�a"����rQ^�
�͔�Ѿfn�aơ�k���\M��M'XBo���`�fT���+�,��!�<զ����"``���bb)ivY��@Kx��b�:'z�#���K^T_X��mQ/[o�%����bC��p��ZH�W��́A%�^���ɢ�q:����t����tG���8x�6���8�Q�Sj
2�W�BJ�h��	���|!+�}�xžY6k��T[�+Sm�+�mxmPZ��>E�O�I�T����H�	����e�����oߘ���?>�3�@'̃R9�3�Wm���?�E���k�H�ي,��[D6�>�t�d-0��>L.B�=7��}�j'�`���4_t�Ҳ���djP1�lj||�N;�:� c $F�jlZv ���i�����͈���FN�������V�k-,nuh�1������t3W?i��P�M}�S���~H��T����h'[Wņ���g���U.�K]� ���5���ﶬ���6hB��<��:�,�G��$���p�^�2�g�%Rt�Z*h��5a/%��k��	�fT��h*�4AK<���u|wʺ��c	�ǑdR0���Yx��a�A!S�T�:���5?ғ���Q���0��st��Q���jF�[�m�L����d:�z�[��X"%� 	Kd���y7OH|j�s��$��e���尵^���$7�:�\�n��W��uL
]��:�V�Z���k����C��E��9����eT,"pf+p��qήb|y�R�0��m�޽T0� �f�Eȑ�R�,���-�0�czٳn,�s���8�K�^?�>������B�8�b��+Q���E�Β��>f���΄�0��L��v�L=6\��Ħ),�E�H�XX�D~&�\b@�4hB��?�� �� ���u1	�Z=ͽ�TߞR�GR��α�̸rGnP�g��u�hL��Ro�7��8#�3�P��!�E��(d��zg��R�N��d�T���k����60��%߰���A4���
�#�>�9��]Hྎ�Ǯ��bL�þ|�������5�c�P����ld�6T�[f�S���ђif�s7�߉JR�GP(�K��,�iE�ILō:A˒ \Fl�^<�db��eB���Ip8���݃��:T�{�]�࠳{��z�w�?����:;u�G߻�~��=R�݃�����z�c�����������;�9��7��G��������mv��Q_��U����v�7��<����Q�zo{�{@7T�atzQ�w����8��[�]wN��9�i�Ի���{o��䃽W�ɏ�[���ݢ�����=<�	@�[;0�.������f��P/��ݽ#��+�fG{� G���w����=�x_;/��� ^x�֫��]�`��o����o���-� �N �[�U�쿽阎 ���Ngw��c9k`�p��ǽ7�"`�ۛPP]��}��8�z�m`K���NW�}x���m��݀�v~T�݃�[���~g� ���wp����2=iqp�qxl�e���Aݷ�ov��{kE,Q>�`���h'�w[01�=���A��1~�S;{�[�p[q6�v�v<\� �-�v^�!`^�D�h>0���fg��C���3�K��p������ ���CX+n-<�NT�{@��}��A@�Ոc�3w��v�2R��C��`�s�Q4c��e[twPt�:o�a|fs�N��.�������f��������"���{ B���	nqXo��j���Z�MyG�G���e�u6�n�q�q`�[X� pd�{��E�J����$�y�=�g2b���Cd~o�|p���я�a��8y�+K|�P�	�Kq�p�"at��)�pa��T�)���1��)g�bb�G�#!Цu��C̟���,~����Cg�6G���^n�M,�aӝ�Z
?Sti1p�bY׊�%����5���!q8ב-�Y�.�2��� ɽ>�\�[�u8�\9-Y�)�9���S�L�BniC<#��ka��Y�M����I�_���]���Q�O¿�W߬j�KZ7֗�Q�X��C1Z�U�N�_�n�:�4��y{��D��D���}-�w#f@�X3���~Qbꉺ��AI����H�����ʲ�E�8%����z�`jj��U�(�
r}���u�7g��sJ'��O�8�%4ŉ�@�z!U�����QW�cu�0u����<��ת�6��^7��{�O�>(.���(Ε����/$�g���jLɴ`�(8�h�O7��5�V5 �:��Ug�^�I:���d��UiQ��r-�=3y�XA����OK�8�(ypg	^�
^�k���<=\�0XM�U���ⵉl�#�fw,u�Zd���c�C��?�L������E�4���촭�=�/`B�ä��	a�I�o�z�jޣ�/K��w��c�\����r��e=t�-M��e+!�#�rF�WZeca�	�m�b�n�^,\#)��˸/�}Kxȥ�	����{�o���?���3�S�N5������~�vW<ϖu-��8&��M=�i6I�ƒ���wߝ -Kg�c47��P�[��h�m�?}[������a�Tjo@��ql[���F�X�B�τ���f�V?�khBS�5�L�'�ǚ���)S�)�ZҨ���#�^moA�7�EY�b�P���׭��+ q0�.VƫY7�)�V̝��O�?8|��s�$Kh�@�js���m8���Cʖ�9�Ƙ|8��-D���6��R�r'W¡�!�e)�1#���R���/�u�%`0y��"�	�9�ێ(����!���\۳�]�X�	/���u�
d���Y�=���~��K�P�FS:��Tn��,Q:�]�/�.� ���t<l�MFC؝��3~�i�}��l�t[��Wcee�ɣG
�}��1�������h��j��ړ�ՇO��=V+�W?��Z�J��>Sd)0�<�涃f����y1���O���l��oQp��=�QC"������f~�&������Zʥ�d
�.I�2�-���J�I��� &��	�0�!��wj'�%:�m�|�RP�����D���E��uȰ�����A��6�ِ�q�{�x2ծS�.u�X �#R�qŠ��#s;5WO2O洝>M����g�i��xG�����?A�;�Ф�P%tk
���qS�у3�-�;u��hP��XV��!u�'������Ĕ�R�(0�v7r|�F�j.�7�L%���tڇI��,}�w2�O�R�J.�d�j����c�q;�K�����]1�Y2N=q|1���x^J��+>.R9����wA����D�y���|�.QP��!��v�L?��;�����aV8�ʹ��=�(�E�r��oLُ�)�=�A��0����$�&�3�|0/uoˠ�8h �t�((�鸰]6nģ#�gH�&�6:�e�,��&��X~�mma"L����Eӻ�Rgp�� ,��&���8� %��+t��_m��{����Ϫ=]Ym���`�y���>m��6W�>Z_����?*���-�l��xuY��j��*�7f����jO�S "��rVو��u����ܗ��|�ty"?5����������nw�_v�/~Vs�S�Fl��څ�n�Wj��o��v��/���M����7��x�@f�<���ч֬�I���|�uw>�;�W�C�*~�z+����y�65�i�dqDt��*^�X��3Ԣ�%dBu��&����EkI���kѝ9Y�G��{K��zk�}] UC�k�z̺��.���@�ڪO�P�@����B�{06���!����À �xk� q����'����P>�^m��^[4bŹ\0�I��0�Uc�O��yP�z���ݳY1��q�)��NV+̾�ڣ��F������=�NO�O���d4.�az�L2���n��g
��#=~/">������<y�@׼���� C3����~���s?P�Z��T�_�T�'4o�%�C�H�`�
c��F�|�RKUIQr�Yi�����"^�L����c��q�\���ң>�������Zs�������G�+�o&���VZ+Z"���o ��|y���x:��p�s�x��(�e:�3lR�\isnO.�6��E��BsH�s�.��~���j��w�G�{�o��ؼ��YY��a��w��	gLC��`��?k���?C����_���6�l̈́������o��J�=]����Z������t�j���]t����Na��q�����K��j돭���'ks{:�8��?:~�o�e̛MC�v)|�2���c羶A�vk�Ќ)�f�b<���n��{��]�֢�X�V��b�ŧ���k����G ��:��%� �i�ŀ��9	O(K��j�y�Ѫ������M�hov_u�l�=�.���
yRF
��ѩF����z�n<��I�m����	��t;@�$�)��6�Z��WB xߦ���=�h]����c���{���, (�'� Ne;��C���s؏�w������OZ(6�!4ݎ��,�p�y�0��	�s��p�5���,�<�!��b���|Ԓڵ��5���q�@ $��<����Z�-ی�c�%��s1� b!�/Qa�k��C����5 �4��NfIe�7��h�߱@����~�.H(Y.L�v�9���:�g/&�T�O6y��z�M�Ei
�բ67��
�/K������b#q0�u���Tm�nvU)�VS??���@)j�`#�\��-��m�T���%H&ꝥ��=8�; Dft�tМ*���V�g���!<c�D@��G�k-�,���I)|����٦_�w;8�GMk8�@�������g�f�|��`��)>kg�(���6�_)��Uo�v�)4Sm�,����S�^�֏#�(ȝO������ �{;h:�/埁�j�?Yp}�R���)�����fdĈ��S{`̫B�fp����K�I��	�{R$�4�wd��cs��s�óLE� U�ó4:���E�3�ܻ�74:&#�u'�œ�|�A����5h���n�ܱ��k�b˕ƌGu��q� *6.׊���;/b��=7U*�E�bᎴ��"�*l`ؗSǩ�k[P��@�	n�T��a��M��9S�����a=C6�8��k4�9V;
�t
��|���ѵ��kB�Hu��ܓ�q�:�t��5���Xޥ����$�
���3أ^�@s$�g�{�.+,mO+>S����6#&-�@�f��>�`CK��u�qዒ@Ӥk*���v�9A�o���;��_S�Ϝ�-HԮ���ii�r��м��Th��Ҝ�<� oov��qC\2����2���Ȇ���#�z"eT�@a����s6e3G/�fd�eé���O��	k�1Hi��_�oB���X��[j;���Jˀ�K��\M��"��ځ�< �$<�	.�j窏�D{���Y��<�
zei駻Z #`ۜI�+�b�����c/tT�΢�X-��m�nl�{G4xN�'x�� �h��@�&b%�Jk+�]�k-kg�V������X�� �`]�<Oс+����¦co��2@�̸,�Z~`�fc1ZQXKO}}�%	����f�pp���~L�g���
TY	Gz5�>R"�+�ԩW/艘Sw��z��q�Pw����p2'꣚��lX��*�����f��!�:�j��OO�
�/���r�\u��
��+Ɖ�CW������_�dh�y�EM�x�CC*��D�L��*�����IΝ�n��jI��*O�mx�%W�E��ˤ"�S����3$w;�c�����"��9V85�^1�&�eaX�\������}�z_̹z��ҙ���1���}�������@�m���w%�	uJ���J(�]@wgD���U;�B���xY7��@[a����Ytʨ�H_y��WȂ?������鄃̚��K��K�j'3���v �yP���oX=(�����
��¡�MQU�ՠ��U�lө�J�r������Ѧ1�&�8p��9��L�m� 4�A8�8_xP'������M�������*���z�S�tW���k��Q᝿��LTu��{^-7>���.G��)+�lG�T����+�*qa��X1����S����Ngk��sO_{'3�����`��-��j≵�PA�{��g�gN�(��橉Ζ�gԠylU���T����ۆ'A���C�c%��W�q|�xp��(��^odRZ�Z�H�'���-�	���yT��JV�nP���Fο��� �0���V��C%2o:8��:<�;؎Y��]'�P���/u^rG��6�_mmW�4��Rp����i�K���q��w||�oM>���m���{G��y|o$2}9��M�t��Y�;�6���t�ͫh�[�)�tjl}�:�]����u}�ŝ�&r�:���I�4�B���IaVp,�&6����cí�|s�$P%��A�gi9�>b�B�~�_)�]�S?�!B*���n��9K�	��"o����ͪ�Nݺx�A0�����%���YrTgE,jd$�*%�9����VR �0�2�R��ʠ�̓������2����L}�)��X�7�lT��rH����%r9	�*�`�m|{�R�́�V�S����Ҍ!�F��4�2,rl�����^����lǀ@3;�߮׵��Τ?̙�볣k�Ө��%i��x��xn�~:"���%w,ȹ�V�W�������y���K�Q"�CtgR��&����M��������ֹ���*m@
�j�pa/r�ɗ�p���c	�r}]"]�ڕ�4��������p���,�~���_?�Lc,��26����u�mYp���/���d�Iڒx����vҞvb�N���4���bYԈ�{:�,�cc�y��@�(�Y�;D�86n�BP 6�LÍ�. �8�؋/���h�
�N�cn�
d
��EE�51$�~t��N�r���"`���h�������?3�mB�"5��R�lz��Q��WKa������oH��[����)m�4��gѯ?N�>�Iݫ ��fr,����yF|>]��26��Vb"�d�"���}����K��rk�û��j�S0�`��6\گ�X�z��~�NY��� �OI�����̝���'?	�fo"��6?~�_IЦ��pMR���3���KG{����X\�SA����N��X���l����Q�����n��9��N�'sH;B�b���O�<�
��4��'�� 	N�S$�7���#�7_x#�g	�6g����MB�����DS%�d�N�|c���΁��G�I�#= `J#F>@l�;�\�@5Al�)�a�����3�E"��պ������T"��:r�TJ��Τ
i'�+u�3�j�9�>����5�� !���O�8�Y�#.�øH�����>�c�/T,Gø��'l7���>-;�AE8g�AS��
/ڕ�K��X/�e�P 9����4X�X=�:�1}.���o@�t�biq9��3b ����t���z:&p��V�A[�M/bn��y.�RgA_��K�Pi��٪�j�j�?��+j��ǰ,����Q��YE�$�a4挽 \cϽ�\��8��#۞j�R���-�s�<�;g��s�N���+�u��|���}m,���f����,����HM��,O�ul�h��|�hMǓ��ki�g(��i����c�CZDi�M�S�i(�F<�l����j��MْGk��f�����m[3G�m��+f�n*zӱlSv4���
k�vi�k���>q\���7ӵ�k)2�l�u}շ����}�����
�S5��̖�9Ṗ�ˮ�4=Cǚ�F-bk�jپe�"�4�n���Y���|����Z���������yM�oٶMZ-W�t_k*M�m5��N�7.X������$�vt�o���Ȋ�ʦ�ҡ[�����9��3<�Rl�p]ǃjM��=Ǳ[m�����ꨶe�B�����Z&hЯ4]EQT�i�m�Noږ�$^K֜V��M�[��[Xw�-��(��hzn�oYİ���d�NS�]��t�T�,�bs:CUM�n���MC�}"�M�vզ,.�2|���5k/d�w]�w\��4]3t�i˺eZ�ܴL��æ�%Z��h*�a{�<�j�%X�k���ʶ���o�μ�"-Fb�J��Z-M��p�z���-��_ E�4\� 2@d���wW�M���*7S�-�;�:rD�N_�M�W<߁�uS�a�غa�~M�v9�♾)� ��sl�0�D�K�x�jہ���窰;�͚O6u��fV���V�-O�Ew- ,��j����&�}�MU648}׀�� 0b�O]6��G�Vnv�6���m����!���}�o*�WKn��%�0�vn�e�R�ӊk�+�N��t�V�T`�
��X؂d�%��p*2�R\�q���8Օ-��TG��a[�e�'��	�a�4O,�n�b!�� >�����N~r�9����En�h�@�,�$��qق�ʰ�|�P��Ҵ\ ҤUR�AN� �1#L-&��4TTl�mj:��.׳T��\WU��ʔ��D/~�S�e;Mbj�Ut�st�e���3�����~K��b�j/�?!��r)��Kb��|�".�j����i�@�3��-����@Z���Q��65Ƕ8']��)61�̫�c��=T�����h�W x��с�鮆dD5�et�$%p�H=d�����I�pp���a�P;IW6L`Z�n�-�l��8@T�j�.P'�.���a��+��0R� ��#�"���o�S�-���&�D7>�W�6}�����8����C�	������¹Ĺ����G�py���z�S1q��M4��ͦjX�Z�tL�(�'��7z	0OA��|�3�jZM�e���ɞ�@E�)�1d3��g��S�4�v�h�nZ�B`��jفځS�eZ�0y'��?��ؾ�W@��v�.1)��4u�i���6l�D1:)j�l��p��À_wm`�@ ��M `�	��e:��J�{̻�����4]��"ׇ��0��b��^#zj���-C�t�қ��d�ڛvK>��u�*$n�Tu��`��M�/ˮB���-�o6-E�eJ�Q�����~�ݮh��lG�l�߂��y�c� ��'��:���k�Y M�2LzNq[�e�'��׌o��Q�_H���w(����?��Q���@e������d�w�0}�����6��蚬���� #��떦��?�HO��H������8��������X-�8�W������꾀:]��ыtM�0$��Z���S�7p�D�d��K��AtI&������h�����,|ߠ�a��nD|��w���/���ٽ��#>~�+���� *��P���FwuY�+M�B㹏_h7������RK)n�,�&�p8�c��a6c���.�ZP#�Lb�64@ ���o��ZX�@PI��X����ִ���R�-��[@G��E,r2�!5��/�blN���.���ػ]���m �"8&�ɋ:�ԧ~jCJ>#�8`Vn�Sj�m�B��y,�4���� &��/xܥ+T?Ku�}�p��KnXc�˙ˉ:k�0~�����|��۞'(I-��9wf�����no�{��v��a�)+���Zg��u2�}�зyn����X�����R�3�L�Ѽ
�СX��C@Y �)7��s>s�Z֡�е�:ka�f�3��v6TnP�&wD(��`6s��I|D�����u)�Y*ZLQ�Zt֕���$c��k3�S"�Y��"<��ܜ�ʕ`�s�S
x+�4�kۣ���gwH�*K[B+��T*����C)��-���EQ5%��P��a�f���"-m�>B	`�������ܑc�g�*�R�O��#��gY�X�pG8�g	Τa{0�U-�r�h�ܭ|*e�[􏞹]`�G����MZ��u1���l.�otޣ�%N&S���Jg��������o�]a�Z~�]Z�K��q��lӗ����cv^B�#�AL��<�{|�NK'�T���`�S�_��qaY��p>0��MKN��\���'�����#�%�� �cV3ɦ���n~��2���{����V����,�
[;��&��.��J� ��V�s p�� 耓2��=&��A�����ك��J�2٨�����*�Q!�|q�Y���(���d��T:�r��kF&c��Bm3�AU2��d�K�������yo�L�Ȩ_A�j�F����f�S;k�'����K�NO��+��%���G���p�GM�jgR�-��T�O�j�hK�7vv���5I�3��p�o����%�A�.�h`e_��\��6�� U�����TO�H��=�Ê�I�Ƽ�?����Å�����T�U�[[�_��jS���'ʺ���_�BMa
.}� ��ۓ؟\Կ�j����s����|V�6��e���H|���=�RMJ'�/&��tst\(��-�ZM��%:�~ʁ Z^P(O����s���WE"�����h���ܸ5�b)�⳥ 7S
��l)�K͖�NvZ33�Љ�
�V��K%���/Ȥ�Q�Ʈբ	�Ӎ�~�qy[浪;꤮g�R��I��}#P.6��N;1	�F۵=��v�k<#0>
�W>�S	�`�yq��:оz8q���I��dJ� M�J1�6f��1�d2�N��C�Vlg띵a�!��/�sn0&{I���.�����8��lJX�JP�5)T\�I�����s��օa4I�B�Uԟpȋ�̾���h=�'.�l�la�R���1�0�����ZZXC�z76��yZ�ܬ:53�N����)��f0R�t�Ig-c���,m|z�u;����"���p��~S<��F�C���]�c�6:kg�����5v����,jy���T����6����'�&��54].�W����"�h�^�N����(�o��u�����$=e.;p����%�nb	�k	.��Q��x�"��ZW�����ߒ�X�W15<�U�*��������m�|P�Y��xFb���iptd�yZ��M2u��A/g�L�e�9�'�-8(��j�A�uiolu���57߱R%H�}���j��mR�ق?�5�@���K�@��+�p*���<޴-YV���n�� �;�]ƻ��IJ�ƑKB.������˺��ߦ\��$����7~����bV�� /��u�Oǔ�/���S�Kǽ�q}�߀sߢ��Zy��$�������Q�P���5#���ri�������_7_MV�r�W�r��[�?=�������lu?m�b����+I3���������j�OrKmc���Ȋ�[C7J��+IO�F�x[G�HBQ�<�O"�|�7|��_a&����X|T���4���Q�L+\jZ!* P��h:Ɛ��}V*��?v����3ꮞ��n�A9j�qLܓ�ʞ�/�i��ħ�wU���J�ZMz/I�Ȫ������XJ��E%���`��{���X�}*�	���+��cX�5H�b�a^QE8a0����WV.�T�ws�m\���C����>y��iƯ�=�q���e�����\��O��{�6���i����IIVeU�J�o��P ��'�{t{rm�'�PXr�3
�;��ݔ�\��d�Z��Y��'yŀ.S˽��Jd}�H�x�P��s�$�%����Y�ɼw�%�����dYO�K�#�ō$� ��JϽ���'�/�x���r���[���+<p&�`�b��zkW�*3J�R�P�5�0(+Ĺi��03[sX3A�),�͖�Ɗ��`n�\&�uR�Y.'%�v�n�˷�r�R(`m͔b�_��e�q_��k!A���
k5
�5^�}dW��N\����g��т.�]�k�~�*�C\2g+�%�z�x���	�C����#5��F#��+�bs�C���LX
�C-��Q;�����d�w��6�$��Df^��LNG������O�����a���FAm<	N�B��$cs$�9���R�M��F�vh�;�����4-���j���_����T�|�o�?d���ih��r8p1�)t��&�?�ހ�e���P���y�ӄ*��ǒy��,�� =�k��S�o�Q]zE�Ϟ�҉=Qp�	{
�O��Mπ`1/@H�s2� )��;�q����8�&�#s^��=�M�L��6FC��#����#E��K�1�a�X�8ؖ��(���8) 5��8_C�'�a�����"@��:Љ) �h^�y䳄1�O�ǎΩ��8�,��`\�\��M�7jK���:�~��y�]��3��'������heP�D{��>�{�(�m\��\��\�Oy7��>ϕ&}{�}��ø���@��w�?n���p���wݳ��s��uZ��?TG����7�/{}�9>i�������m����������]����g���<�|syy�Sc02t�}w4~���M����O*�-�b���&v{K���Znfi�1��bm�۶�\ Aq��rZ�It<	����=�ڒ'|Z \�������Q���Z�Ӆ<�S�Yđ��S�B�{����r�/�5�.�}Z�R�q4��Q�.x�-��I�4^�GJ#~���NC�{�v����>��#9����8}����Kti�:�>]�[�Ǉ�;?������5
�?}�eD�ۻ��7�'����֫w�_�������~z���z 31M�8��y%�Ȗ�����e ����������^�`�Zf̻����Dq	t�G`�����e&��y�.�SU�v�s���}X���ˠ[�Zx1r�|��1�$���}:�8H��ϟ2�z�|!�_cZW`|kq�S�/�NT��g���f0���۠�f��/O#/8/F��p�t��Abyj�O��oC�����O�By�6������*�J��tK-�V���?���ˠ�u��T�:WAXu@���P����� �]3>��O����^Ǽ�LG^��c���P��}�4���쩟<1�@��eӖ��}�U �g���M�0d�>����N}D��_��$]�0�,9�?���&.�O�Ʉ�DR�P܃)��1��(���M_�k�[���ե*?1�@9q�C�rP(���xG������D�h<B�����E�R�~3(������Y�|>�wO}�+�FJ�v��`�PQՙ"��ש�|����M�1^Q�j]�~�u��A����o�ѭУ|�Q� ��KA����]���cc��j���z�E����v��4�̕�vw;hF��>���Me���wO��n�%�[
����������v~����0�U�,ŉ�L�Ʀ����_�����2����R��2��3�;1�II]��Gw�}�&�`Q��y&{���DBx�e��|�T�i�������Q��I8b֯�|����w;�?�>�T����"�*�H��cFi����y�<y�|�J�A���Z/��}J`��C�+�j&We�j6Wc�ZU��`g��K��!�k�����@�ӍT��:}�7K�ϕ�R������섇���2���/{�٘�����eQ|eGn�c�O��x�7(���m�E�+?�5U<kx_:�ܔZ����L(%'~� 7QP��V��kC>:�[�ːJ���B*�ZTO�K2��t�PJ����WҐE���T��5$����c���Sw��'�1�����v�̅�xWe��x�Ű��n��wQ�M�v`>��%�����-����˥�L}����<�3�H]�*R�ڽs�7PI�=-R���Ɓ1f�zgBb��r�V�:�Ate�&��E�̃��!&����+�q�3ʺgd��1���I����@p��u~���OS�������W�H��E5K�������|�����3H��*R���U���Ϳ�b���T~$�8Wt�U8X#�t�-1�d����:�ʔI���c���zZ=nu����ߺ����(�R���$������_���/\ �� �kih{\$}r�f�����8ʰ>���cU���}
�D5&3Q�6Fp��f�1.Ch��O�.�I}��H��>�.},����>n�o	$l�}�����{���,���¾��ǋ��pԼ0����	#�@�d#1�w�S���@��M�������lQmj������莫���C|̏�h��S�2��(�a�ܳ��f��ߊ�������߫I���C�6��-���v8��)jO��ݳ=���Ng�!|�$ۗ��/Ec.����ؽ�sR�����V��qJ�EP�8pf�N��Y���Cy/���G��x���f�cܢ���(�% �<��<�5���(Q�<SBs3e��2jڣ+���(<�ޟ���I��_��tUx����,���\E6]�$8e���EOq"<����.�e�b0�&�	�)l0�(�:��d>�*r�>�G�
�t�Z�����N��zޫow�3߬;��M&vz4��q<��83��/��K���8��j��SW��)�����[E*�?���+�?�x�������T��S���)����?#��|��ߜ�߻(�-��(�����b ���[E�YE+d}�;��?�F���s��%���T����Y��&x���m�����u��L���+�w�G���B���ă�%��2ڟD� ���#�A���V���ۈ�%+?(9ΙYs(��l@�;��o��.��ZZ��Z Z̾�c\(t�N'D�=JQ��:j��S(G$����Ĉ[Ȕ�C�)�R�|�2e�O�V���}��d#���j���n���JR��-�ya0�ǥ���6I���ХÜ��u�Po�5�9zo�T�Ρ� �CK�y�J��c,��%0�����ot��������TX@M�b����f�|/y��v�=>S�n���]��PP�y�Tݨ�j�.�Z�
�~0��ڹ����1�u��$�E
����i�I�HM��u	�R�#�����2���Y�dI�g���B&��u 2)���C���{2�����Vu�V��Yf�
����g��.�C�F}�bB[����#� |��Ra�o{�ݣt4��\���R7�@�|H���i;��=S [�A��"4��<�n|��T��B�jau�Ӓ�$ s~��+��@�GF]�M�4�k�����8��tZ�F��5zTo�7�廫Y�7Xo��9�w�M\ڔnkn�J+�?e�������wy���F��,�{����T�������]���-�쿩7��|�}���f�}xZ_,��X��醙��&K�bi�V��H�:7�,���&�ލ��E���0�������x�ݷ��e𬺢�e=����wV�����S{�H8���Ya&R"	�uV#r}gq���G�GY:�:P�����$z����vc��x��.U))�z�1�1^�\ �+И�J�U	��_$�/*������y*�`��Z��T_ĕ�p׿�r��+�W���Bv�pһn�xNXځ[M:������3 �G��;�Ɛ�n]�E�������d|�+�O�Lq\��8�l�O�0-��n�4^I���|:�
G�����KK'OYsJ�Ai@UN>�vcb�r(}`9��xw��$S-��z�=��x��9a�����b����y��"��;as��V:k��yZW��O��Y���W�m�&�?��0�����JRy��;���+�WY�%>Ի�?�/�[�����'v3P��܏�O�S��S^t|mf�LKO���c�]��7��e���1��V���$���pV���	��7��
�01�q��9�)���H���&���
y�(�<)��3�|f������$�b"�e4�3�^�}#���3��[P�����~�:�D���VF�CUdX�3���W m��3�R�! ����E�Kly�-���!����~?:��Z��hqs!�/�_U���V���$�&��L����?��G �4��Ob�����Mq10ی�|b��3+�u ���OFS.����J�S�3��	�n#�eT�5�Êf�5��j�	3+�Q���1���IF���Ù�4Հ���Nj����&@�?A��������s`�8k�a��Ú+����܆���$䯇�k����=qqbj9����m�.G��;�q��I[[�2=�1�)��3�	6'B�](��J��F=r$8�ߝ:�f�F��G�� ڣ_���ץ�)��7�+@�8T��I��k!�8�'PZj�K7�R������	�M�aV��I���y��;hW��a�'���XU�j���uE�ì+u�ޔ���X�9�� I��l�������W�� <J&����OoEb��X����9Px��G�h�
[��?���r[�B��mf �L�I�;S�����d旂@	��� ,sg�����w� ���Ք��0���Zf���"��.����@8�����Ny�^������e����߆�/y����o��P�1���.��#5�gɕ��,�i4�_�WP{��/OY�1�f����R�w��ȁ3���d����mݤ͛!
�e �x!ټK7hl0:���f�^C����\�Nf�[�����ڧ�`���j�k�vysے��q(U�����h�����/�u�h졅w���8�ޝ�I�cI~�oi.������M�=� 2�	P@��F��B[�pL܁=l�zy)�')ζB����>��θmm=����~�9l��Ȕ��	c��2bD|�[��קpi���2��J�Qd��i�Q?:��BWz����q���	�����P�� J��hx�(rJ��.>�{R�Ǎ���$�ߓ`�<��rX��
L��(jk�x�=��+���X��P:�>i[�e�xe���x�7�`X��6sur-�&�_S8�@��N�Hg�u���h>JE <�0uk�:����n�Q��,l���$�>'�Y�>��x�<}��X7�vg�.�g�����5ρ{�3g�j5��Qf`X��A���+;��|-��6� <����;D�i��p���
glR ��11p�LV���o�a������0��W�Ivt$Y���1p�����׭�x����:�����o��?��0.���Sz���$�P
��dyim,��Q-+��n0�_��)jy���T�|Ɨ��T�s7ޙRFjc^�Q�F7�۩�`�چ{�*;o�AjD��14��6��s�t3l��:�~�ZBF���QF�PnZUtMA����c�J�Azs�w�Os�`|���,���R��G9!'���� ě�����жc�O�����!��|��v�\`qN8b�t�[o��g�AA'����F5��n<�ԗt�;�H�\r%���`��p�μ��n�W,[� ���=��x�,8�KQ��ߴ,8��0��iiԒ�̒(�����v���Pa�����tLIs&�|F|��g��3�dt���/��@�e������\��˿$����z*�)��τ����H��WR���w��M�Y�� ���Ӵ��k�J����������%���V��~Lt{vԧ��^�t�^��2!��,ɟ�#�R�S��t�σ�V� ˒Ғ^�h�L��W��Z(
Px,�"����T;E��{0����8¾�?�U�,uf<{ 3��ni�n~�ّ��um]_7�����λ̓���7��t1�`%S��t�^ΝΩ��,���}*�iU)��0���0��C�})m,���D��u�����b��+I�&�?�  �W��j��lK3h%C���%%;�r�䬓�U��������g�F�?��}�-�ԍʬ!Lb8��~���0vс�`Q�ad�+��47'��l)�iwlި'�X'��T3�fb�r�z�9�鋺��}�=H5�֥�$ �;�K�P��񑱤i�AT�<͔��p�a�_����N�@rǳ�.5��18>L�o#� ��B᳚.O�rS�r8z��n8]��W_�L�]$B�N���^	<����7��\�B7�`�7��W�C|h�����g�=��ΈD����l*+~D&�L��'ٿW/Ƥ�(�
�ꢭl��X���2�񝙇���g�R���֠(��8���}������,���8b���)	�Q��M�+��ȳ'��4O� ��wn0
�~�u{2	&��0fNB~�3E�W���0P��xj�Q����칀�wu�"�E�_T�H�?�?�2J�ϕ���G�G����T�;Dn����{���(G�p?]�	�V�Fd.c:I�#�C~,���+v�~+'pcJ�Ė|)�0�.��tpy[��+�F��E0��B�6��)ICS�e��Guh��!x�� �ӡ'���iiDPў\@�h-��DM5����q 6�|]�V�����Vx,�~fY��K��x �Y���$�l�I�8���7X:��t��=����8���.Ev_�~�vw{�G�ý�;�n�������p �):d��;���ݦ�f���"�a;\��~���z�C���T��x�uL~'�2)L�� �%��67f�!�TF��:���M�z��8L�%�h��%�L��/�L#s������~<n*�1^�W�����E ���8xސ��"�~��C�V�)k�����~C�h�'@f�v,-�	�K��d�D=#�d�k3�֥vE������+�!o��끅
T�I[��P�lz��#W��� ��Rҿn��k껧,��	p}�����_V4�������I�͒�_I�m�ݛ�wۿWH8��������qRG����oo��m�l�^�no���;�Z�����������>�����pi��e��T$�/Q��i���%���[�L��.��������C�73ڟ�N��YL{8�C�v ��eE *�m%��a�%��7|�^�S�G�-��L#���u�0:����y��Lw�mAQLz�,���ڥ^{�d��8輷�S���r�����Y�8��������[.r���Z\���;�5����_�N�K;s��px�S��!�������r��N��ȁ�/�z�gr�P����P`8��%'�r�Gv�S�������c!0��!;�5�l:�;��w�I!c�ͽw��;!l%�\o��e���A�����~6r(%���zx��� �`�J�d"�cr	4�M�Y�	�=�x>�t.������f[�ʍ�(������F)<(���B;��)E��cz�_�T0w�z��vw��_*��vӀ՟:պ$�P~�������A��#Ra�pׯ�^>r��kI�㸐��ӯC��*R���=�-��ʔ�-4[
r3�pG͖�\(�*���pn�d��ݫK�M��R��2�"�gۙ;����¢�B��%$(������'����\vU��{��|Au�c2�Y0U��@�vwA��lJC�m�P����I�zg?xR�%l7��=���@1'�>a ��$�
YV�pȋ�x�:�w��x��L�-	�H&&��Y���������ͪ|��O��f �())��f0�}8��� 謝2ȃ#��d���阡�4A�i>:s�Y;�
F5�]3RK��FU(�S���0f(u*�$��~�Π����=���兰O�0_en�pb/�b�Au�?�p:�b,i��=��W�>G�`2�_����T8�Ut��gb�,����6��B�������?�H�z+�M܃5��^0>�d	{}���
�v��t�T��E��]/����?Q�_�����T�����R�������m�uQ��^�m�n���$=�"��^/HK��dz��b2$p�{�1�9�A�^���������ah�������*�SJ�ّB�<#�v� ��$�,wkc_�(Ș��y�$Sg��Yb�i�L!Hr��l�b��6j�B�uiolu�������k���M3�����~�q�{�[�����aQ�_@����T��������ϱ )f�oa���I��o����1�;��J3��pi.@������V ��-S��������������[� ��� ��$�D<�+�p���l����}��ܿӏ���_���U���h��?���@��.��w���x�s?�?涳���n��K�!;U������;Q� ��SmT�A����]1�R���t �=�̭��U@��kU���q��9y`�E��Ԕzȗ�1c)<Ƣ�����Y�\�_Iz*=���ҳ����uP����Pf?,�J��.pț�  "�V!�8��+�a�"�V,�R��l	oN��� ��\��Ǉ領����»[�`�<�����`үxn[J2+B�o��I���*2_��b�Q����zlJ�ϳ�s-���`��A&	�}��?2�|#�_����Le*S��T�2��Le*S�����P� � 