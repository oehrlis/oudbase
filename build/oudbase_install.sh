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
� Ͽ�Z ��z�H�0X������e��E��*9�jZ�Ӫ�֒lw��,5D��$�H�*[��ż���7�2��?ɜ-6 $%Y���6�:-��XN�8�9q'��}������Ǐ����]Y{���G�>\{�t���ZY�?�N=����4��L%O����`0�wY�����s��N�ǰ��4o�g_a��������#��G��>z����õ'�S+_a.��������6��I���T��>��Q���8W���4��(��ft��(J&��p:��D-��<��;�ateQ�O�0�#��������5��0�LN���iC^ē�G�0L�w>��p������?v���4�'� L�^t�c��Fy]����ҳ� Z�tow���m�q3��q�VV��Zy�Z�#�r��y�&��q���<�/a��a/��5I�i��E*N`�I/R<�*�&�D��~��L'Q��;:�]ʹ�k���RM�i���<�҄�@�N'���f���h��4;;�L��z�}
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
2�)ơn��/*̍+�f�7.j���n�p��ŋ|h�����[c�����>z�׭g�f2���U��.�Z�rr�se���ո�78^Fv�I]�,"��UZa���)�W��4�����T�.�/�L��Es*6�Ab��W�,��t0��[��Ά�\{U}��C!��t�. i������|�@;L�GO�J��;���x̼hM>N��ǻM���ݕ�NWvͺ1-w�g'Tn�Y���fcx<`��l��l^>��]����<fHW�gS����O�wE��GTct����Z�+�%W��3o���l�ʷ�>��~�k�1�����e���O��>Q+����<��z��'�������oomtw�_m�ǓG�f���ʣǫ�����o���U��a������=�l��7/=��HP�>o%u�aC��I�e�Dj6;@0_f���D-o��z�E�:L��^$-95�Lz-��T��V���_�{e��	�s��zO&���)�K���x�F|�I	���C�v�qh��
o��Q(?E��PО31�!6)+�p�^�͘��K��,
G �a�#��j��:T��M�u��V���xQ�"�l5�50p)Ȭ>�I�:A8���� �V.���=��w�X����e
�Gy|���x!�/�K�''�E+P�>�=q(��<�^^����4�����$J��O��0�{T1(�����J��j�i���Ijk�(�ѕ�\��,2�	�.�9�SG5D�9�7��`Κ�S�����\��x��
G�u�ɥ����"�	�'�4Ðn�9��N1��z�߰���?�%�)a�;�_��0"���A��4�'\_���Rr5Ʊ0���I0�b�}�������X�<�SjL-�xO���B�I�X��Z���N���J�Х���z����&0�|�K�e�Ti�-�\���<q^�6���u�m�[�g��$h�	h�ޜ�-�}��$�o�R�	g��5��_�`r����v#���,:�ts�q@�Zs�{���>�E�g����t�Y�Ount����7��(��������$Ɠ�/ �F���B�A��@@�~<@�\/���g�h���	2��>��h<�~�� ����Нq��)^�D�ӭ�,v�bP�F]Y�����d���]�W^B���<ꨀ�aO���[�1�VB?@3��Ѕ0[�V�r��e@��MNr=:�M@����*����E�א���`y�����lB��y/��\���:�H�&9��i|��n�q �����pw�kuD1�αgzU��&�$�^�_Z&,�t2������z'���3�y�%��ڣ.-�Џ�?�As�c;\��4�"��Hn��$��>P�Y E��<���3�#�
`;��N6}r�%Q:�aY�x&��Hb���Gp;�+%�^Fj��Ra��Y�C)��#�&Ay�Í/�}�-8d�/v?=�&���� � ���)Q�� l�(>ant���p8�hŨ��1R�@�/`���'*(3�2�_*S�W =ùI,i8�#��zӌ�4�aL���E#�� ��S`�sx�Iܣ��1R�<��_0^��G�}� T�4����"bvg7�kf���̧g@"����X$�����SmQ�
Z�A�0��|z�v�#(�,!�L�l��>��@��(�YAgr�=�Ĕ�^�����w� G`����J�U�[1�)v���	ί�"�5�F`N��͈p���2$�Ǡ�F��u�#���M�$��a�4�&���=
WO�0���Cq�9�z:W9�Y�'�Is�����3
t4�Ә��u�u�4��zB,��X�7�|ƀ��ρ����@2W��eK$�p�,9�=��(���)�2�yXG
�Cc6��h
���w$~�sn�/�(w8t\���0��n�օ��;�����WGnnm��b��)��ޯ9<���)�>E�9�)�sGF�������k�:}!t�Ej�׭�lBZ �Q�@��(a���;u� �Ne|3&��I��Sv)�={��!&MX3��a�sj�˭A����5ڒ�jj0�K����|AW�6i�Y2t�s���9s�.T�pL��P��|'��)j�g\r&�t+]X�!�:��NH�E=.	@�T"�>��wl@��s�����;L�&s
P>��^E� �U�.��"`tT��B_���Q,�ӕ�1e����@�(�� OwxJ�E8�	MHK`�H\!�p5�t
�܁��@" ,#�GP�G����됝D�;�� w����}�Q�Gp�LDަ����g>�DR!EA<>��g��ND���)0CCG��,�b�;Y�r�
(x�&]��`L��T@<J줚��؅����82�phv`t��)�y���6D	{�� �_����De-��C2C�
�W�"���e� 4��'���bjM��>B(´�����l^��Ďs� � $�H����3���&y}7E�#���t����l^�#&������F\`�F)B���
3�E���7zF0�MbuL�4_�J�,+��.B^�ED&��m:�6'b�P�>�_K�5[ᙒ����xc����A�a�z�Xp��dG�Ī(!q��1�e�k� N���.C6� Lb��Q���1�_3�c���C������5G����#�(�Eݰ��K�ɾ���=��aL�)������B�Cj{�NC����f}���f_w ��	rL��z���.��ӵ@����)�<Lߒ����K�^44()[��(w�Ht�{�ah�m#���ix�Ɛ����mx��X8J�~���q�DY���.��zu��H�j��*[1BΨa�[�[���1�PWI^�l}���	l���s��)��� ���41fq�,!U�"@��9�񓺢��h�aY�	���v¢$(K���TC3K���8�a<9�(L[�Iy��(f(�K�	���V�EM��\
�~��RW!l��)fD��`�h��I|��F��O���1��]Bb��8�`��ȑy�L�}� �>o�\����(�j����h����c˧��ľ�}j�a�w3���~��T��0(��R��nh�� π�i�Jd�N�����&�jS�]*#<�h�ǀ��PT>+7�ֿN/Pkm�������n��A�P�J�$MY��XD$��6*k��D�s�N�*��L��)������ٶ
�֪}�w	��q�OTC�r�>W�M�Q,�v�Z<\�I�����2	G\�'�BH��'4�ʻ��a!��V01�5�Nћ�rDT�	��4�J,���
�-��H�	�l�q��x�B�k��H\������)7�ɠ�E�¼[�H�����p7.�Q-�=�� F˸]�Z�*e�7
	�����|J^�~� EH��B��۔����O�`�a�)+-Z�c�B�P?plT�&�h��߹�!��d&�&�xc�[Ӗ��'�)(- ��@ㄘe�ꐤ����K���NA�GJ�]"�GƱx2��,n;/�v�^�r|���&�r�O%MB <���snAzr�넴��� 1yD�q�h��z�r<(�ڢ/��k�Ϻf&`}C��B���vku�Ym�4�Գ��0xj|g�ct{��a4e���|�h�
�˲�Q�9��Qt����e�>���K��p�`��9OF�2����*�=2� ��b�τC0�Q
�t��#�`#�476w��Md��"��	8�A'�Y84�|�#�A ��!�Tt�imlu�#>2Z�g��؟m����s�K}bT���,3�7	W7���a��8�MG�.�)�8�;�0p,������S�Ca�H���A������
ys� �$!M�a��{�a�+�|`_!x:���4e�c��rwSo��P�<�u���ĤM̰��$���L@�ɍia���ث�tܜ�{���S9��!�VW5z�����	���>������6T�q�Oz�g*ȁ�JE�X�"UŤO�D���k�m�0�
>�d_�ESy�K�M#���$Rƃ���)�dB��*�x&� �f��FHr{$$6��4(Qf���у�+� ���,bdZq ��7ջj�,�c��+)�@�Q�vE\�M|�٧�1����/���h�6-��&�ޣ�sn����6��Hv�¥&��~�4�\m���X����Q5�N�1(��%��5c���@~����^������{	;�V�]���EcA_hB�'�Ђ�œs������1��B��Z��R�~�	h���iǥ��=�i�����	����A�T[���p��݃�P������72#VwSP��A�~8>!��)� ��6��BSx�"ێ��D2~�:�X�Z�K��HEØѹc�������b.�jFD�[��
c�����64w�:{��:	�l�Cf��]:F�J�4Q> *.�!v		)��C��x�xOn5y�%X���	>.����mV��S-*�VH�#Y=�P!Ҁ��j3NMګ�!-�� �Mر�9�?|_/�}�hK�v(+��"��(ב���:���J`�p�c��j���gPy&�kh�A�vه(fEI�hC��4��C�;AY����)�)��S\���E��:�K��:����쭅��3Ն�s��T��(R#��D�s��\J����KL�v� ��^���Ȩ����g�/y̫8�,�X�%,�K��-3Ga�M]�*����9|���l04��/C1�0�5��ǵ���)z�o�"�����D$8yqG��C���&vBV}�!�f7F�YA~b��TQ�E��y:��E@!Ո$��<w�s���SDh���z�D\�4w�Ԗ���mBeь�,Ge�<�)-�_��H�$���__�^Vd�����V�}䥇��Y�f/�0B�H"r�������p��SwAXv�
6g/�%c����@���g2Bǡ7��	���@(�y���`E���)�,c���3^��N��=�mHV#���eN2��yQ'��>���z���8LbmWb*Qm�?����4c���;dFi�=@8K6ZP�<����k��e��',6Q}��&X�����M�N朎�I�c�V�X3d!�Kl�0Kq�;��%Ssqa�"i��O&��&az�ݖ9��9dF"G�4>6��B �>>4���$w�⣔��jG/O	8a�u)ק!�~���
C�mX���E�PGX���#IE���C]}���:��p6���!y.V��	�2\8�PV��)εQ��i��$��:�.u�`�a�#,QG�^�]�a��>�Psx��+�'Z@|rb��D�1:μG~�̐���t�N��b�>�G�EK���R;�>w�E�b�E���L�2=��	���4c� c3*#'�b�\�
����{�g"���'�y	w3Q�G����\��~�-CL��!ح5�K��b��[ �\���Ῥ�����E���:�q�'F�pV���+�ZSA]v΄n��q���d�g@`�7�l�l�q��4��&��j����؆a�o�#&��9���\NM4��L�.8���9I��/���?a�g'l/`G`DA%�
O���.C=[ �|1�Ðmo�����F�7�k;d�/�k�] ��3A��I�=b�������������@��=1���M)�B'	��!��TM���t�J5ъ��t
&�+J��m!E5�Ζ0��6._Ս���#�L#:K��3�\�W���sl\�Ĝ�}Im *P��Pz� 1l�s���;Zdh��X����6�~:=��|�Xn��5���<�S
[$�#<��6n��n��b��+T{��ʋ�&�c�S���2aDx��0�s'�Q0Kh����6W�: !�W؀�B� sa�,y���h���}����p�M#��Y	����f9}���I	�\�L�?Ei�A�W�� <�iB]�,�O`<	W$I�cd�d�Y$�Bz-	��q;� o���ux�{Ĝ�,+��č^�G�@C��tE��%��	_l����:��ㅢ����uC��yD
���9'4�-�E���*�SU��lF���8�"1���D�e<�D�M%1!5��EIa2��"^��k�$"5�����P�D��-)�J����h|8��ܨ��dӲ�B��9�>gn�nf���C=�s%bd�ZGm�� �nbX�DV;<Έv_5�&�xri�Ҁ5h
UY�4o�3̉9�7���.�QP��xݾ}[�L�'�����YgS��@r-���C6��.�cƆ{��� v�@��I�`�Ba��=[���k��=�S��	7s���tȼ�`o�n��;zԬ��#� Ѕ>enwZ�Gّ�ѵ���/�����Й����!s�"�d�!���c�9^�)2
� ���	D��Gd�8���
	U4�@
���#-�8���{�:f�������hqS)�F9�i�mT]���<w;��9g����}��0�\�g����$z��DX��s��| ����GT!fxv�pP�ݕFך#i�+hJ����NLt���=�Zl�A�i k��Q��5�up`:X��7��/]2o�3�Y���
N�x�$⤟,�lϺ�ZA�$x�P<P�k�a���#�p�'��tc�9��VwY^,��g���J9O�F�.��{��o�������{f}I����@tTo���]U]��EN_J�!<�H/�z3b�XU���n ��r�9�7Y��p")JH����N}[@n��X"��V3�+���B��'5+X���,Dz����@&�`���NQl��X�"�1�>)?�܇���{+�>�h�5�m�L����|�߁��� 8�c�{��4�HY"8[fd�eD�����s	��D?Y�Ǧ$�6��/п�>/J���alR:�Yj�A�Z}L�t�Iq�P��N��nJjKvnؗM�q���r3a/�ep��4�Vl�a�m�%o+u"W�eг{%����xbg߫��71o�)F��x0��i����L�f�ΨQ��#��آb�s tAi{�c=4f�Hh�/٥��9���r*Ր�U��kNoh�?ؽO�.ܝ0:���(�cᐁ��D�BT]�.��E� 7�Hp[�,�9+�"	|r;���4tx�/�ή�)`��L,���~�R��[�Z�Y��m�ț���km������m�t�� �4��K��pN���$���R����K% Lv S�B[1ڄx6�'@�C�V�|`BAI����ID�����[k`��� �S�(=���j�ZO(�*,�a�jV�[�ʢ8CU�K��uz�e��lR�Fg����!I�ڟ�Q��/&���_�X,R�+w��n>�S;����U�F��b��)�s	ؙ5�FA�e1�4�9��7�P(� <��&35(d@@; F���5$�@��:
:�g�G����ld�N) �9?i�D5�@%!���)�N������#�����Q�l@u��\�# Ӡ���E
J��=��|4�1bkAvN�i�s�&�� �������a%ߌ��Sx"���j/�gYMd�WEK�8'ލ^ RB�� c1*b�B�m|摭U6}�v��Hx��]��!�ߕ"�D$�,05#��ꘪ��"�X�Fe��X�ɠ�ʰR�����~0��?�~b��F���@��VI�t> ͛�7���,���E�Cve�a�	�OVT����Dv��1��n�Խ$�k1p�謩�$��$�rg-��4x�c����I<�l=?�܄�@�31F�Ӳ|Z�z\P��M:�M��h{5�}��7�����(�<)6�Y����Θo�1f={*b搡�W*r�4Ez���0�Bq5����|�4���"g��K����jNڛ�O��H/MM���+Ъ��e��e�ffj��o,��@��ぽ�挶B����t�#\��G
��s���(L���"�l�c'��9��TK)��5�Df�B���sҙ��3-�o""o�C�B%'���z��� d��|"���*�1�4�H2�Ys�;���-9[�b�Jrh�35v8���\J0mH@ �°,J��I�/J�����ӛ�`4�/DӁ/��2�gF���U񸫦S�#���K�L4$�a��8ˮp�3��+��/��Y��C�l��e�|q��!�bdH��X'Q5���d�?5��]���9�8����ܒ\,�ye���c�N���Q��5<�}���1ǭ�E�m�q�1�1먭D�W'a��$�p���]+ag�]���&�k`�QK�u��Z��~y�*2�)���0��-�t���G�8+n��F��y8�yI�b1�b���]�A�sBq&(�NA��BabI�3�>0�$6�����B�ʵ�M��ﳐ��,���g	�^iQ
w|{b��n�^�C�Ngoٹ�1��ҥ�b��z�f���^�09�����O����>�R:ES	��N�8��4��o� �J@V8j�a#�{8���#�n��[Ǳ�O�U���R����.9���1�j:� 2�2]�	�P�L�)L�U�ٷ8)��O �m��ڄ6B�(�4�4��6��L����q�.^*�o�� O�w�q8�T��Zr}Ӱ'B�2R��ӆ�X<�܂Ύ���\��I	�!Ӄ"r���s��-VJ#@����3�K�9%r<Q�����~UJo��|���J��\���f���
m^�:��w��3�@c�]NML��g* WC�{v9�����B�k��X�0�����:M�������p�ppI��½�����t���۲/\�b�H£��g!�t�'Fz3�b��]����/��Dr��#4��:���x��7�/���Tԗ�R��=i��8]6e��sI�*���<JBN���b��n��:����>�L!w)���S Sj�s���Ֆ֥Q�Mf�~���
�+�Q�YSV��e�4U�R���
�H�FL.���J�2�7���S���m��RHy0L���%�����L�C��N�N��VX��:�nU�xʊG��BYG���I� A2��B���T.[~hFh�)�E*���غ�t0t�&��T �x��"���2#�S�GquWd�P@-%UP���d�f�'c�K�\xb�8X�[�o2�1
��c:'��B���er��,��0��#�!���n�|r@�Ͱ�$�ʤ"s�Au��d���9� \�t7� �j]Z�&�(�Δ�N��*:Db�墼V�1�)-��}��4��Cת����RI�N*��.����y��ͨ,&,�e�W�!X�#C8y�MiX;E��P5�?���R��&�����O���`uN�G�7Lŗ����l�ۢ^��KV�)�'�ņ �ᨳ����t��J,9$�Z5�EO�t*����%H	"��d'�p�m�	��qx9�8��:d�*�����U)xɁ�BV
5���}�l��%����W�$�NW:��ڠ�$}����������4D+�;�?Si߾1/q�|\g�N��8r�gү�Qs�:M;�4���X)8��l}�� j�Z`K}�\�F{nX����N��n�i:��,֥e���Ԡbr����D�vBuHA� H�<0�ش� ��1�xu�%0h��1tٍ�4fw�ө*��V�ZX���\c���=���f�~:��[���(�R�L-k����M�2�3��N��$��qτ��!�\n��� �-�klC��mY�mЄ�g�y*�tjY���I���H�Re.�$�K��L1�T���k�^Jvy��#�;̨�I�T�i"��x�'�����*�uA��*Z�#Ȥ`��9������B(�d��uul4`�k~�'sх%����a��!��L��'��ՌV�0��J�x/E5�t���
4e�DJ�A(��(�'47�n�����k5�N_I:�h���ak���
8HnLu2��� }����t\���.���X]#0���ԋ2�s���˨XD��V�"��]���"�a���Ƚ{�`A0ͺ��#[� Y&��[�at���g�XH��98q��
��~p}����a��q��&�W��Ջ��%�}�(�:|�	a.5b�����4zl�2*	�MSX:�n�L�����
Lp�ĀjiЄ�~FWVAV51�b��z�{��=�4��&۝c�q�(�:�J�003�� �3И`��oʁqFfg8���CT�z�QȆ���R�Н����/����ך��3,m `��K�a~A5�h_Y�G�}fsP���}Ϗ]��Ř�}�NU&7�ñ�kv� ���Z�w��6m���"��b3q�%��F�nܿ?�����P�0kY�ӊ���u��%��� �xH���q˄�3*���p&q��]�u�v�Ի��Ag��G�j� P�{?tv�h��w����{���;[GG�M��Ǡ������y��U۝wxsҿot��Ի��]��ݿ�:�ã�����lm��@n���x��������f��n�j������muqo�6��T�sӮ�w[G�����{����_�v7��Eu�}��{x���v`�]�qkwc��&̥�^B�{Gj{V͎��&mu�8��{���v^nmo��Z�W[G�0���3�x��9����v[�A� ����`�{�1t�����F�r��6�rՏ{o�E���7=� ��j����q������0�ᛝ����::��j�������o�6����Bic�� {��e4z���r����Q�L1v��o?��n#$���֊X�|,��;?t	�N�`b�{1#F�^�,b�(��v�6�^��l����x�P8[���C����l�|`%ܷ��N�8f �l7��~wc����T���V�Zx ���1�������������g�d���e�T�{����f稣h����.�>����u66��y��������]�\/��@2��W���7E�Ñ� ��%!�����p���+j�l����5l��.4�l�ݢ�(��$�&�:�A������w���KI*.��{D�d�`á��6����H[{�>��p�
W��f��J��� E���S,���?��Sx!:;�c�S��Ė�tGB�M�$O��?O��Y�@=>����+l&�fI�� �X�¦;��~���b��Ų��K��7��k�שC �p�#Z�#��]Ve��A�{}H����p�rZ<$��S�śs�����҆xF�	�0���3���0P�œ��:��!�nM�|����Y����n�/I��U�b��N�2���	�";tpi8c��H7���-(��	���Zr�F̀�/�f:U����u!׃�쭫���S32M�e1��qJJ�t�����v��lQ6���I��o����N$]�dq4@Jh�����B�i)ky�����t/`�"��{/x�#��U�mx۽n��69�h}P\�7T�Q�+%���_H��l��՘�i��Qp�Ѳ�nZ/k6�j �u����н��tHg����Ң>��5� Zd{f�j�������Xq�UQ������#���yz�va����F�?��k��G���X��9��,,Yd�ȇH}6����틋��i2m��i[�{�_��:��I7ni,"´���|�8ռG;_�&X5
�
	��ks���C%�z�[����VB�G6	��5��(��°����N݂�X�FRV��q_\�$��K3L;/���u�t5�g����jr	�t������x�-� Zq6LzǛz��l���%�;\�; >Z��.�hn$w�2�����ۂ��z7��/;�ީ�ހ�ض4S�h����k�	w��͖�~,�8Є�dkP5� /Nҏ57)S�XS��Q#8��%F4���ނ�o�:�t�~���[#�V@�
`]��W�n|S�+��;?^��p�fg�ZI����h��p���pH����-�s(�1�p��[,���?\9ll��?�N��C�C�R�cFr�ץ$�q�_���3J�`�L�E<4ds�Q\E1Cʝ9ҹ�g�9�б^�Ww��6��e��{%��
o�ԡ���t,��܊�Y�t:>�l_�]6����x�:����;��g���^������F��4���ʓG�����c�we�������'O��õ'���>]}�VV�<Y��Z�J��>Sd)0�<�涃f����y1���O���l��oQp��=�QC"������f~�&������Zʥ�d
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
/ڕ�K��X/�e�P 9����4X�X=�:�1}.���o@�t�biq9��3b ����t���z:&p��V�A[�M/bn��y.�RgA_��K�Pi��٪�j�j�?��+j��ǰ,����Q��YE�$�a4挽 \cϽ�\��8��#۞j�R���-�s�<�;g��s�N���+�u��|���}m,���f���,���e���)ۀ�i�����O��x��r-��E�<M��zc�~�rH�(-��y��4�Ј��M��u]mY�)[���b���L�\���mk���m5u�l�MEo:�mʎ��<]!b��.�s_�]�'�k[�f��!{-E&�-����q�6�� 6�ՖU�{�����r<�� <�r|�Ք�g�X����ElMQ-۷�P䖦�-�p=K�\���c6�V��� �q��ҷ<�i�-۶I�媖�kM�����BT�	���8C�UUӚ�؎n�-ߴY�U�4[:t�6|�s5G �Vt��X�m��xP�i���8�c�M�VU�SնLY�����]������(�j7]��Ķ�&�Z��Z-�h��R�º�l�Eq`$F�s[~�"�5@&Ku���ʶ���bda���jv��4_m��Yoj��6epٔ����YX3x!k��ʾ㪮��A��M[�-�r�E`�<6�,(ъ��FSQۃ�1TS'-�\��tU�MEU}�t�u�/iy0�W���ji���c��t�l�Ot@�(�ݠ��"�`��㸚m͵U��
l9�����#Zt��m����̬k������p��k��ȡ��M1x@��cC�9�%�\�Ȱ�ĳ`W�lDU�<W��Yl�|��˖�0�����my�o(�ka�mU�m7�7��Sm����i�l%�~�Ѵ<�8���r���Yu �mC�eM�ѠG���~S��Zr�T-ن�s{,k��VlX[]�t�ح�㴚�OTX&��d �.ѯ�S�����St_�Ѩ�l)0���82���-;�<9(ȘTL@Cw�ybivKw)��	��@Mv�K�qe��-r�E;rdi. !����T���k�⨰W����&�b�zrQ�)aj0�@���!��b�nS��ua���Z�溪RU�$�'z�-�i�P[��[���-�n���QL<�G�[���T{����	1��KYU]X��(p��q�W�@�|tM�� *��n�MN�2]������9���9�MO��1g^���2e/�}�G���<6��Lw5$#�,�')�cHE�!�`U��LR��K�?#��I��a�Bt[m�pf[p�+�&��T[v�:�v1L5S�\�����"1��'~���lɶ�5�'�������x-�&�o�9մt`�M�Uմt�] ΅��'<:��ˣ=��FЛ�
���m�iDm6U��`��cE�}8᯽�K�	x
r��k��V�j�-[�L��*�H�f�!�Y-?�����Y��t@�tӲ[��T��p���-�*��;�N��E��M�j B�Cu�IY]��O��a��%��IQg��?��m ���kk� еoSMؿ-�)�V��c�E��#�5�����>l���p�0�@W[���P�m2�#�ބ&#�޴[�i�����U!	�p���;���plB|Yv="�}�o�}�i)�-S����������vE�`H�g�8:0`����ϫ�k ��8q���l^8 �ia�[p�۪-@e�88�-`�͸f|���
�BB~��@��0�������?|�(�����?$�;������e����G�d�x]�_�4���YEzzME����O�ā�>D� ���łh�ǩ�J]� ���V���ڤ�^��hb�!��ֺl�*���&r&�~]��K2A��ev�D�,�g�e���ÿw#⣵ ���$|�( ��������]9���Qqm���N�4�è�Z]i�@�}�B��?�`<OV�ZJq+gQ7�����35��w�Ԃ����dS���o4|�����J����f�����o1րx�:� U/b��q@0�1~�cs�����p�����rn~n���1qL^Թ�>�SR���r���S3�l�w(�c�1m�� 1!L��.]���Y�3�H/�C\r��\�\N�Y���w�p�,>��G��<AIBh��ϡ�h�3���ww{�G�ý�;�n��OY��8_�*83'�ଓQ�Ä��s�͌��z��/�f���`���U �%������ 0O�1o��&в=��e�Y�7k�!X���r���0�#BaU�� �N��#Z-�ۼh�K���P	��b���Т��dEG'[�\�Y_���z��!���T���+�R�[�\s�]D4<�C�(VY��X���Rѿn�J	�n)�lp/m\��+��)���jP�K-�W���E�0Ox��։�k��1��FL�ŧ`ّ��,P�s�#�ೂg�0��=Ū�y9q�U�V>�2�-�G��.�ۂ#��j�&����E�g6��7:����'��sH�]���q�������7�0f-��.��%]�_S��K���d�1;/���� ��C�M�=�\����o*r��0W���P����P`8Z�%'�r�Gv�w���I�Ԓ�l �1��d�I�y7�[N
Kl�{}�	a+��zCd����dy����F�D �?S��9 ��� t�IWT��K�� XGs�������A�s�lTn�y�M�ۨ������_k���y2Z[*t���5#
��LW��Ԡ*�@j2���M��Pc�g��7\&Idԯ�T��#R�~@�橝5ד����������R͕�ꊒ�C�#g��t8���&x�3�ږ�~���'T5l���;��[��$��b��7�[���� Z�j4��/}|.��TPs���ZU��B��'�Q$��ٞ�a��wcށן��َ����X��S���؍��-։/��n�)�N�e]�u�/_�&�0��T����I�O.�_J�C����V�|>�O���2�[`$>^vU�V�&����ix��9:.r�b��E��O�
�@ -/(�'_B���Bë�"�KKS_J�BUDn�U�R��R��)�D}�䊥fK_';���B�Db�]������dR�(Zc�j����p�¸��wR�uR�3o���ʿǾ(��q����؋��Z��|G;q�5����+ԩ�a0輸{Hh_=��G��$�l2�� �&g��|�O�J2�Q'~I�!� +6������0�O���97��=���@gm]]��nnw6%,l�?(Ӛ*.�$�S�Jιd��	��0�$Y!�*�O8��qf_RCf4����	B6P��k�g��}����|Nd����!_���<�NnV�����n@@�Jx3�]� ⤳�1
�J[�6>=�����ЇS{rwkq���@�)�K#��!�K�.�1�?���A�r������{}w���]M*V�^n�?T�������.����H��o��`����E'	�m�bxз���:�Z׋_��L��2��~���7�{��YԨgi<U�O����Yd�o�Z�������e���J�SJ��6x>(�KU<#1_e�4�
:2�<-��&�:�ܠ�3q��2������SI5Ƞ�����?���ۉ皛�X�$��ۊ�l��̶��l�� �E U��եv��Gȕ�p8j��coږ,+�Cm��l�؝��.����$�b��%!O��]��e]C�oS.�?V�J�o��ϛ?L��x1�^j�����:��c��~�)��^ڸ>�o�����h����T���6�G�C��5TK�`�h�kʥ��JRj�m�|�5Y���_E�yں�6n����/���Sֳ���q��7����$͸"��6n���Z���Is<�-���"+Vn��(�?�$=���mI�"	E=�$?��2���a�1������c�Q���̊?@PG!3�p�i���@q��C^�'�iX��o��y�?��h��zb@�3�qls��1qOR+{�Ħ���UAۯ*u�j5�$�#��b0>���b)I���/dZ�i�o���F�b����&L��؎/�a�� Պ��yE��t�����^YX�Ժ��R����q��_W�R����-��U��~�����_��?��a��r��?]�[���X��ϧ��'%Y�U�*��U���A9 �ڞ,����m���B`�}�(�'wS
xr�V���jOf����L-�rz*�	�a8$#��C�c�哼� �s�g�'���������e=�/��7�p���s#`(Y<�f�(����7�ͷ��o9&��H���9�y��]���(�J�BUפ�l�l���b��l9�`���� 7[&+:.���r���I9f�����9x��.�*�MK���5S��~�˗�g�}�����O@(��\ (��xE�1�]u�:q5.���Q�F��w������qɜ��8���}j��&\��t���Dw3��;�X��q\	N^2a) ���G�x�Gd��G��$���y!f3y8��ӧ��Z�>ſsG�A0���$8��`�͑�0ޖKQ6y�Y�ڡ�����Ҵ����&�����R��eX�9�����_��M����ň��m�ƚH�~x2��۲Ciwk�5�N��K�q.�8���$�jO}X��OFu���={�K'�hD��&�) ?�GS4=�ż !����HP��J���%����x�L�p�yEB�6�3~P�a�$��!G\,��Lxl��`�`[BW�P��� �h[�|9�P���vC�s2� ���@'��6�ymg��ƌ?H;:��n���g�P��q�s��6�ި-��N<������w!�Δ��T��O�C��m@%�M�� ��ܷqQf�s9^Xs�>�	kި��<W"�����j㶦ٖ�����a(������uϦ�=��Qh�B�P�?���x�������q|r~��������{��;�Ov��n����d�����O����������ͫƯ�6�v�?������a�/>���-�n"j�����@���5�o�r}�Yp�Z��im'��$���k�� jK��i�ppI�_��32zG�k�N�N-gG^fO�
��i�c?ˍ���(���i�WpH��ѠsDA�J��5���'�x�)����O;e������~����|��g������/ѥ����t�om���8���?6���(<���?��o�6���|�.Z��5~o4�6�?���:��]�_��h�4E�0��T"[n�_H
p���;(R~^�f{Y\��j�1�����%���12W{W��d^��@OU5���
n�a���/.�n�k��ȝ�y���� /@@h(.���3� �_��>����<�i\Q���N�G��;Q��/�m2D��X��R�n���=�3�Lx<����O�Pӱ�;�婝?�T��{��'�?]3��Xp�c(fb���*}��-���YE*���>g/�
w�׹
R��\a�}��C�2��(vq��ܣ�>A��>{�f2y	g��OxCyp?�1"�(�&��~��8���M[z��)W� �u:6�Ð]�dn���;�E,�~q'�c��t��`�����B~c��>	&rI}Bq�d���T£(B�7}��	Ohl)z�W�>��İ��u�;)�A�p��cT�TC���!���s��K!�Y̠0���c�g]��<�=��H�)u�۩6�q�CEUg��^�����7u#�xE��u��-�^���󊿱G�B��yG�s v/	�ң~v�~Ə����5J��-}�
0����Ef?t�h2W����e.�`{��6�)7�w�=17�y��o)0��������e?V��'3�z�
��i`<��r��~��O�J��ʔ�μF<��tx'%u	��)�횔�E�R\t��E���E�͗���UR��_��{�7D�O'���Y�f�!��B���l����S�K��P��#ӏA����{����A^�=+���:xkM����)�e30�U�P��\���\��jUQ΃�q7�.E������N��O7R�~����,�?W�J�O�sV����2 �������fc����EY����?e"��MߠPo�73�������T��}�lsSjY�2��D��	dX� DAa�Zq��=��n��.C*a�B
���j-P=\.��ө�r@)�޲�_IC1�2{P�א����U�O��r���$f����y3�]�A�q��z�1��Eu7��M���Tw����C�T���KW[,��2�]Vv��83�|"u�H�j��u{�@%Y�<�H�v\�bƘU�	�Q��˕Z��<ѕś��G�2����P��0�|�a�(랑��d�gj$Q:�#������>M]������_Ut#�����,��W�J�_��5������ i��H!�W�ND6�Ɗ�sĢR5����\�)V�`���Ŷ�ؒ%w��+S&͞�Z�m��i��iԝ. ��rz�k���(Jy���T��b����Nx�ǿp�N�X����qu����)>�98���(�:Wv����U!s��)p�՘d�D]���3ě9�Ƹ��s8?��@&���#�������������=�%�h�i�����������b�tV����/��A�Q��"LJ2'� ,!����N=�j]�w4q��K�¾�E���eDb�>��ˢ�;�.R�; �1?����OUz<\���X��r������+�*���V��&	�����p�`����맨=!Vw��<��:���H���l_�����pB�c�n�I�c���0Z�G�)aUh@��|��;Uf�2��Ɨ�]�;�1jF�Z���q��s����󘎛��|��k�PD��L	�͔Q˨i��xT����X�`{�&Ů~y��U��37�h�:�~pp�t������V=ŉ��f>Vػ\���e���\�'LX\|������������]�}*��0k�gL׳;	��y�"�݉�|��x*7����4�j��D@C��8
;��/�s�.�8���y�O])��h���K�o���x�K����h�%�W���S�OY&��܂�S�������s�� �����R&����J�oif������ ,�� ���������JR���g���������w�֟:k@�m�31޳���yr�c�^�N��
�hY��.XV��)��Z�F�2o#�
�����8gf͡ 
�U�8���^���q�j!h�J�jha0�B�q��a�;�a�(Euԫ�ŢO���CW7#n!SjI��J��˔ez<�Z����ǒ�4���Q��Y��+I������ ��w6
�$uB~C�s�b�֡C�P�p�P�aP�;�R��},5�s�q*���pҗ��R^�����~�;���~Ram 5	�A���cl�=��,S�y��L���Npw�J@A��Ru���]��k�*d��Гj�"��֭6��)0��o�ӧ!�'}"5����%�J����7 ���l �gAc�%��^��,̆�Ȥ���k5�+����:?H /[�Zq�fa��+`{6ܞ���(6�a�	m����x��KU����Qw��шns��K�t��!�b3p���[��Ll�>���N0�}�E�Sm#����NK�����]R��
V Q	u��6��`v���?����Lk�iI�
��Qy�y��l��f��\`�1���-7qiS���e*����iV�W�����韦�������R���;\��>�w�R��|�����˷���A���y ��i}|�c��f����,Ɋ��Z���"-��̳|;#�8�{7���ãl�<�_���3{�.t�Ư����Z���7����Y�vV�
N��#����f��<HA�$�#�Y����Ł*��e�h�@�:/[������ۍ�w4��ںT�����U_� �xas5 <�@c*+V-l�%�J��^����GC���y���N4jɲR}W�a\�����P_M���y�Iﺱ�9q`in5�8F���V�� �U���Cv�u9��_���r��}��~<�3�q���}?�ôx:���x%�j�K��L+��S�/-�<e�)�3�U99��ۍ�ˡ��<g��8��L�0��4��uJ�UK��Z�)"Bf�媊8S�͕�ϢZ�uf�iI\��>���f��_}ܶ����(���J��+I���������y \ey��P��ܾne��>p����@i�s?�?�O��Ny�y��2-=��r��v��������P@���Zy���T���Y�o�&x�� c+���8�Ɖ�0��>"e�RȻRț�B�7(�,������󙡂^2w��b����фΈ{��>��T�+nA]�B^�#���t���Z�OU�a���x�/_Y �"�|xK��� `�n�-/��E�t:��6w0s���D�k���U�x̅��,�U��[%���T��/2�G��F��:�H�?�^S��Wd4�y��l3���Sάh�] 4��>aL�LS�7��*Nyπ{'��D�Q}�<_+��{���v�5&�ͬ�Gf�s��od&�g*�Tb�:��&S[� ]��c��3�Oρ����ck�83H��s"����Z�5���ŉ�9��>���d����%�&mlmI0���ǜW�p j�D&؜w���*a���ȑ�8�w�D���+�
 h�~5�;�O^�N��n�� 	��P&j$ml��lܟ@i��/ݔK6":�"�& z4	�5X)oH&	�#7�I|7��]}�m�D�B�cU����.�E3����zS6>V_`��ܺC$�^�]`2�[B��_��(�x��C�:>i����c�{dt���@�=
�7�^��+l�l��:�N#�m��w��ȋ�2�'E�L�?_��_
%�c��̝��û�IX��KWS����/�j�%���T�����s��!K q��kHg;�gx�{d�2�?��6�����W��C�� �>�쪏�0�q$W�b�h��~A_A�a��C�<e-l����[ۣKI��6" �4�ޓ	L�f�u�6o�(ؗq |�d�.ݠ�������{�^�"�sq;�1o1g,R��k���5{���e��Y�mK�ǡT�NR^@�l�5^>l��4ֹ����AZ��{w
&��%������{Zһ7����ȸ&@�'�gm��1q��]���8��8�
m{8>����hz
8㶵����>���A�#S��;v$��#Ȉ	�u�n5�_�¥�G#{���(�F�	���KF���
]�}L*���%
�'h؞�vBQ�( ��5��)iW��$�I�7jJ���O�iT��^h�a�g(0�o������!��&�80��b�S�C���mY�	��m���ߨ�`Lg���ɵ\��M�<�j:��"�֥���(���ԭ��wK��F�?�������g�� Oj�9����cݬڝ�7�$��Gz��<:�Ϝ]��@G��a	N��옂��bL�0X��b�w@���y�éG+��I�f���M2Yڣ�!���.^�Ð�^!X`<'�ёd!
���}��d��F_��/��x���'��� ��ø\(ӃO���� B)�kP�奵���G�������)������*R��_n �?P���xgJ��y�Fݠn���k�Q�T�a�}Op��`2ؠ��Y0�Ͱ�^���Mj	5o`�GA�;@�iU�5��o�y*�������>�q����#��g�"K2儜/诧�o*��Cێ�>ٟC��:����r�yr��9�q��n��n��9i����#X�~��R_�u�4�#sɕ``�N�Q�s�	;��~��z\�l�P�?��_����W,EM�Ӳ��7,�(��U��QKN3K.��n8����{�C�e���c�'�1%͙|��y6�)����򾈚5������s�?.��h�B�/�����?����"��_I�K�_��?7�gI��\6�O����*��j*�f�&���\��ZIzlT�1��M�Q�Gz]��{��˄Į�$:J��K�O$'�>�Z�K 4,KJKz	��a3=�^�h�(@�T���G��R������T����4�����W��ԙ��L�`�N軥���IgG^W׵u}�X7�7O;�6��n�;��:�Ÿ��L���)z9wb8���h&���T�U����`~�Ð{���������3�_�MSG���U���$ݛ��� `_�'�1>�-͠���z����Hʱ��N��V]��R�gT�r�i<�$J�ݷ�S7*��0�1���q�F��E�E1H��a0�`�tܜ����6�ݱy���[`�̆S�@����u�紧/�҆�	� ՀZ��� 8
X�,/�B��;�Gƒ:��Q��4S��C�Q��Y��v�{8���.�Ԙ���p�4�0���\��
��j4P�<9,�MUH���=b��Tt�V<^}Q3]�w�U:�GS{x%�VZ:�rP�p)
ݸ��ߐ~�^�"�`td�3���(
;#���:���l���3��o�d�^9��N8 �@*������7�c�o�l�d�wf�+۟�K�o�[�����?���
ゲ��"���$�F]�v4Y�@3#Ϟx{�h<�:�p�߹�(������$��?9	����^]tN��h@ur��SD��삲����鋐�Q-#��t��L�(�?W����1���R��mb�Y�ףl���t/$�Za����$�����c��y�����)�[�d�@d����m}42h�`�K�ت���$M��M��աan��L0�A�ZxL��4
"`��A�E{ru��f5����Cǁ��uq[���O[�D�u�e��.e{�I�8Xgm�,�1&E�����`��Z��g�`HZF���}��u���mu�����q����Vj?Á#�萙Zp�`csw�^��r���p!���#��Vq�SYn��1�	d0�-� ˤ0a�W:� ��8ܘ��R	G�l�'7��ٗ�0��xģ}���2�ۿ�3��u&��OG�����x1LVP\�btf�Nb�t�yCrnO����1�[���-�������x� ��cر�h�&�.%��MP��P�5���Z����cD7����?,�*P�&m�F0B	��83J�p\Y�p<��JI�V��(���?'��I8^b�Y���Z�fj&��5K�%��wov�m�^9 �N�^��3�I�.��*���~�}���{���yt�s�K�hh�v��~g���F�G��o���å����R���Dџ���2�$��n�2���\��U�R����Y���hR:�g1����ہ|��s<���\s������\H���jx�O5�/���v0����[�����?X�>2�]��E1�}�l7k�z�a��~���N�;��[��Jg��������o���KkqI�;���Tn��~�;9/���zZ��PN��<{wosc��uZ8��r n�@�1��QB��²B��|`hB����˹��O�c2. �7|�������X�L��$�-'��%6�޽��xs�!�[;��&�_�E@�ȡ�`�g��m Vp �M*�����%�7�g1|&p�`���ҹL6�Rޛm�+7*��/.;k����p��֖Jy�p{�[��v��mR|�S��^�����~�H�T�MV6�T뒰C�UW?㷃�Պ�H�U�]��z��1l�%���B�vN��תH���:�`��+S
��l)�͔�5[
r�TRlp\4�\�ù��}"�v�.�6aZHIf�芤�mg��
�f
	S���d����Z�D4b|2�~p�r�Ui���o����pg�T�n�����)a��C�z&'��5��I���M�`L:�4
��`����F�$+dYE��!/t��K�L��k#��2)�$�#����gu|�f�W#w2�V'7�N�[�>!����P�`v�u�cg���v6� ��v���?�c��)����Ig�*��\8t�H],%�yT�\ N!&.47�L���I�ؓpz�u;�N������"��>�<|����I��(����a�����<���1>�0>_=������j8k�S�x�Wѹ����� �r��Xt��3���^���"F�6qּ�{�d��T�%����(�ڽ/�]S����v�`��B�_4�D�M+��JRy����Jq�1^���E��6x��׺]��g��T��~x� -q�w��gX��ɐl�U��U�|���{�g�"�_�S���Q��R���HO)�gG
=K��Pڙ��������ݭ�}	� c���u�L�eRg�I��2� ��'�-�Q�ۨE
�ץ�����ޖb{���گ=�7���zok�����aoe��n����E�-(��*R����(�?���]��H^J�&-B�U��ǘ�9�4�+͜�i�å� Yp�kV�X���LM+��U���;�g�����.@n��.@��#�������G2��>�x��r�N?���~�~cW�\\��;x���[: ���7o��" �u��x���������n/1��T�C��'�D����SL�Q�z�ޒ�w��3H�CV�_�tK�2�N0�W9 9���UiB��՗�\�y��RSp<�!_^ǌ����+o�g)r��}%��l�kKϖGXzt�AI��B����+�g��!o� � [��(��H�}��X�KT��%�9e�FP��"s����b�n��/�nŃE��,P�GL_�?�I��m)ɬ!�'}{���|�c�AtGz"��E�](�>�Vϵ�7�Q�$��I g�\��� m�W�2��Le*S��T�2��Le*�7��?<�� � 