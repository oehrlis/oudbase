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
� /��Z ��z�H�0X������e��E��*9�jZ�Ӫ�֒lw��,5D��$�H�*[��ż���7�2��?ɜ-6 $%Y���6�:-��XN�8�9q'��}������Ǐ����]Y{���G�>\{�t���ZY�?�N=����4��L%O����`0�wY�����s��N�ǰ��4o�g_a��������#��G��>z����õ'�S+_a.��������6��I���T��>��Q���8W���4��(��ft��(J&��p:��D-��<��;�ateQ�O�0�#��������5��0�LN���iC^ē�G�0L�w>��p������?v���4�'� L�^t�c��Fy]����ҳ� Z�tow���m�q3��q�VV��Zy�Z�#�r��y�&��q���<�/a��a/��5I�i��E*N`�I/R<�*�&�D��~��L'Q��;:�]ʹ�k���RM�i���<�҄�@�N'���f���h��4;;�L��z�}
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
2�)ơn��/*̍+�f�7.j���n�p��ŋ|h�����[c�����>z�׭g�f2���U��.�Z�rr�se���ո�78^Fv�I]�,"��UZa���)�W��4�����T�.�/�L��Es*6�Ab��W�,��t0��[��Ά�\{U}��C!��t�. i������|�@;L�GO�J��;���x̼hM>N��ǻM���ݕ�NWvͺ1-w�g'Tn�Y���fcx<`��l��l^>��]����<fHW�gS����O�wE��GTct����Z�+�%W��3o���l�ʷ�>��~�k�1�����e����V=~�VVW?~�;��kO?�����������v�� �'����U��Շ��_{�t������GU|~�}�~��v:�j��K@%(T5��[I|�PkR�&�Z���ƗY|z6Q�uz�^eQ������FKN�0�^K}/�����f����G�%z��o�œ	&'`�����>^��`R�=��P�c��C�yT�O��5��LG�s�M�J8�x3���g?���j��$9�����F�w�r��,�A3F�ȿ[r\
2�qҧ�N?�-=����}�x�{��1���i~��D�Q�b�6^Ȇ�5��I��a�
��tO� J"*�@���h(Ży'�`�p�q2��>���4�B�GJ#b�d���C��u���fs�ښ �nt�+�;C�v���i=���Q�h�M9�6��&�#g3�g8�p<�o��Qa]ar)����t��Dz�D��%�0�ۅq�?�S̤���7셠%��a	iJ���W/"��?�tf>�	ח�弔\�q,s��}��kߨ=�z�>�(��ZS(��ꠐs� �槖e��SF�a�2t�.����0C`�v�	�"_��~D�!UڢCK/!f=O�W����fxxw����a'	Zq���7'wKw09I�ۧ�a��a��3�W'�\F�Fd/��H"��8��)�1C��\��"�O~���':�d��S�ݪEtv:ōǆ�)A/�&!�!b��<>���$���Q�.�PjP8� 1��%������.�E<"�F��+���c8��y3ȧ�3{�tg��u�W*D�t�A$�a�ԡQW��&eb�0��"�FW敗�/'�:*�8F�ӡk�ց�z-���O��L*?t!�D�����x2�_�F��\���A�Ąv�
�8�qr��5��|=X^�+�==��aދ��61{y�0����Ip�k�F�@������6����DQ̮s�^�}��0ɻ��C���	K��̀�a=.$�މ,b��3C^rI�@���K�>�c�O�f����E�9��H�=���-:� )�qHQ��"O+&�b��؎d3��M��sI�NsXr�	�;��~0���JI��WA��Z�Tأb��PJ���ȦIP^F�p�q�pY8ċ�OϨ	�� >�!��tyJTy: y&�O��a.(N4Z1*B'a� ���$;���
�̴L嗀ʔ�@�pnKN�H���4#�$r�.%f��'@���1��Bb�(!{�"�`��W$�k�&���p>i������@��`D)"���H��4	��p��T[T��Vf�(�0�-���]C��"K�%�4��O�/�0%5JdVЙ�uO$1%��e%�j0��5�ع70�y��VLn
���*:�q��k�tM���3r3"�@f��I�1(8Ɵ��a���h*�ߺ�p8M��&%d���6�����P�i����U�r�	i�\(|?%��B��4�g�e�G$͸���z!����)�1 .��s��=��0$Ѐ���y�I�%�/K��pO55
�xp
��Ls֑�И��s1�� �����ǜ[<���1���/B?��Ÿ�u����Ρ��n�Ց�[G[{���x��e��G��kG���xJ��O�Cs�fJ�ܑ�*k,ps1�����N_]g��u��4���@�h#���J�0�@�#@��FߌIf{��EG�]��@�^�n�I��}�򜃚k�rkЪ&/Dy���f�������q0_Е�D⃍@Zc���ܤj�h��U?ӱ�/T�A��	�|����A��$�JV8h��#�`Q�K{,���(����kc $d��ɜ�b�W�4HմˤF��U����g5E˄�t%fL�l�{�=9J~6@���R�G�}B��?W'\�"��1w�wA4����ԅy��&p�:d'�Nq2�ݠ�6�pD�z��� ����i�y��4�TF��_Q�Ϲ��پ�8�p
��Б��#˴X�N��\�
� ��D�=�ig�;�� E�1v!?=g���E4�� �GEt�s�g^���Q��B�:@���v%*�@YK(�̐ �B.�Õ��/"�CY*��:��4�5��Z�����0m����1��p6��G< = 	-�u1�ht��_p��I^�MQ��k��D$0決+��I�9*t�9�ĮQ�@� X�Q�P�0#��m�-��L`�X(�ꅒ.�
n���b�I��E�4�͉X2T���f�Vx���;�0;�c<�|kp�އ1 ��$��"�*JH�vzLd��0�;m�����A;��iE��"a���� �Xm)��m��y~��Gk�*���4
aQ7�/��y�o�t+kdJ{'�DD��{{�P������#��(��Y_mi���@�yd��o���(����=�t-%C*�s
<ӷ��li��JʖnoʝD"��tk��0�o��1$��h�D^�0�R�`�v\6QV!/��G��� B�d!�sG��V��3j؇����Vj��jL:�U���:[_��BtA��\�Cx�D~'����*M�Y�(KH��H P��iNg�����>bX�b�*"���(� �Ҹx���L��*#mO$
�VxR^b(�
�kBD8��&�fQ��#� '��U����F�Qxz)X� Zj4D�����1��S�xFg��)D���07�B��:rd^ n+@��,����0ʴZ j�5�s;8E���i"0��a��fC���L���#'��'!� i8
�1G�ԥ��b!�3�yڵ���İ7w0�ɦ��d��O�Z9&�1 E:��������Z�x"�>s���yP<�Ԣ�9IS��8�=���w3����
8��$�}a�x*��,y�����j��A��i\��д����Uv����]�{����l쥻L�W�	�P������}X��L�v�@�S����Q�pB�c4M�K�.�� m' �aB)�c�98^�Pj���RW6�8d�~m��r2�e��0��9m�<�7\��͟�T�t��3@��2nW��º�@���B�jd�B16���_!@RꟵ���6%C��6�=�@X�y�J�����:�����&�$��w.pAj@��ɧ�0�؇o�ִ����r
J��+�8!f�:$)�����qA�~�{j�S���D���q,�L'"��΋������F��@�������BI���y8d��[��\�:!m0�?@L�i#� +�޴
���Kd��賮�	X��P�B���Z]d�D �$�lDh/�ߙ��(tM�g�9: ڤ���,h�i�F9��E] ĮD�y@��k�v�Ēe19��}���Ѯ=��E%�J8iE��.H����3��@�B"]f�7؈9͍�ŝda�Y*��Ȥ�A�m�It9��m �@l�8�dZ�F�����V��F��=�g�eD}�p��@�խ��:��̂�M��71v?{/�zӑ���E� ��Ďo��D``�h�T��E�%�x�gh�!v��BF�e �.IH|�B:��o���J��W�p��M��������<d��"T!dݾa�(1i3lF�,I��)2�-CrcZ9F!8�j07��),�TN��Ge���U͂�m��9�c��}�j-�)���M U}\�ӟ���
r ��R�!V��FU1�%���z�r�����O+�|�T��R�,a�H� �?�����`��x�7���Ὂ: �	*��Y/&��\�	���<�G�Y�8�{C���J(�f",��VH��M���Ez!��X�3A�JJ$�t�]�d�w��f�epj�0ee��M��I����۷:>k�j.��-�p�	��{"3�@��0-� <8,�tTM��|
?;e�?l�X�A*��!fGh��8��Ʈg�^��;dW0�p��A��P�I.��h����l����=�h̢����֩��ԟ3�_x�k/b�qiln�h�tx@}s�'�m`�*���5�l$G��0k��0����Ȃ��$}��Oȧc�4@��6x�Ƅ��ȶ�e;��ߺ��ֹ����*�F�0ft�X$E�%��h�����DD���>��XqsE⦡�]F����N�+[���� `����)M���Kg�]GAB
`;�+,�$���[�E�vI���*u�O�˩�<p[�u�T�ʢ��HV�FO�T�4�q��ڌ�S����6FH˰�"��eFv,q���׋b�!��ʊ��ùH�<�u$Ah}d�(�d���4��X`��Z0n��@�	��zЬ]�!��DQ�6ڐ-;���NP�� &.C�&E
��$,(G�����Rk�N�dx)>{k�a�L@���;a;��2���#,E�\{i3�R���#��S�]- )�W#�:2�e����F�K�*�$2�i	K��drC��Q�gS�
c� Ňdq�a;<����P�?y9��q-b�s��㛡H�E�=a7	N^ܑ'�}�{����U_{H�Y�ōzV���|FTv�5}��|PH5�	�7��E�Ŝ��������W6�/�e�2�@�PY4#&�QY0OpJK�ߗ���$�� 	u�#����t=%��Umy��zE֦�9��9�H�\���>���;"�y���]V����͙�K}CI���p@&F��9Pf�㙌�q��`�41�h^�E�0XQ�a|J"�X��8,uÌW0��` jp��ȡwv��,a^�ɲ�O;-*p�� yo4�Xە�JT���,���?��~�{���Q�$GΒ�ֆT8 ϲ��C&j��	K�ET���	�$-�.�0cӭӄ9�c��䘹U�!�G�d�5�R@�@��0D��\\X�H.�ēI��	F��g�e�n�� ���Q3���j|������!%�]��(�h �����DN���D]��i�<c�_F,&�d�*��<�G�;��$�HRQA�'��PW_�t�N":�+�DH��ժr��1���c�smTbCq��9If���K=hX�K�Q�mWvCث��<��G�J�ŉ��X�h��?m��3�=3d�',�Si����Qgђ!h��ή��pѨ�s�$3�Lyp� �e0��:������I�x)����쀩e�㙈����Ii^���LT�Ǒ|�c�!�y"�_f���wvk͹�oD<����H �c�v�/+�"ŬuQ���c��ǉ(�U�!�ʡ�TP�]�3���;t\5�$#Y��|��98[m�d!h�	c�Z��%�aX��[���m�=m2�S�<5S���(kN�&���_&�OC�����	��QP	î�����P�/�DLm�0d��[�c$������*�q@#���L�tR�f�X<0�`c/�>bx8<�;PAspO�#��{SJ��	CBc<�a�Ck4�CS�`>��AM��c"��	�Ҫa[H�F�,����`���Wuc��8nӈ�R��/�Un9���71�a_R���C�E'���(HD%�\�#��!��?o����NO&�)�,�[�lM:<g8���I�Ou��A��,{�X-'�
՞��y��⪃��dŔ�� �L�77��I�h��o<5���/�HH�6��4�\=Kޢ�#�s}_}�3Ei&eG�##FV��0s�YNd0p�A+ S�OQ�fP�Ul2 Ow�P�$�O��A��5�lI ���^E�oq�+�[D��o�1'Bp�J�yq���1А<0]��Ct��e�۾5��;�NdD�x��"m�l���x��a�}�	�gKt�7=�
�C�"�g�$N�H�r7|�A�8�@SILHM9tQRE�����š9��<�H���A�n�(� ѭ��DKJ��5�j�/�n=7*g ٴ��е�A��ϙ[��'&��P�D���Q��C2����"���3���W���4�\�4`�BU�+͛�sb��$�K�qT�0^�o��@%S�I����j����8�\�����M'�K��^');�9koR2;�Pػt�V'%�%o��g��\cj@x'2�8�۩��%w��5k���0(t�O�۝V�Qv�pt�="��(86B|?tf�1pȜ��.�j*%�l�u���(@a�u���E.΢��BB&�B�3�H�"�"nE�޺����`.�q:�D<Z�T
�Qg���Ɓ0cU��4�ݎ$Dc�Y`�0s��4L9��Yyx83�^66�e��2 9*8 �U��0�Dw�ѵ�DZ�
�Rn (�f���"�x���zG�z����/si�j�yj��En���K�̛:�qV�q8��� )�0�8�'�4۳.�VP=	9���t��Ĵ���H�3�In6��fN�q��]C��ar���Ķ�R�F��+���[G��1��o+��D�@�?)���ovWU@AW*9E����Rx�1�ˮ^�̀6VU���2B���(�\�C��M�,�H��92��S���[by�����튿(��i�{��I�
�?.��ޭ�u6��%�1}�B�;�iL�Oʏ�#��.�@��ʸ;��mMp)E���<:��w�2:�X�ޤ��.R��Ζ�9�FQu>-���\B�)�O���)I�M���o�ϋ�db-D��gֆ�b�C�V1]}R��3�1������ڒ��eSx�3��L��F\�"����i�b��J���U�d��C�#de;�����x�M�`�ѽ<;y'F��8+ӷ�3jT��f-�h���]P�^�X��'��Kv)�:l�l6��J5$f���چ�����v�S�w'���'l��F8d`����U��2���8FQ?ȍ0\�<��m�ʥH��܎;p1ޣ���+q
��-ˬ����9����u�ma%�/��Z[d}�� #a�4Gj/����m'��C�*�5��  ��.�b�R	 ��T��V�6!���	���4�PPop�r�~�}D&���5s� ��$J���1�ڳ�
��
Kr�������PU,�l}�m@DYg(���љ��C�tH���gc�9�ŋ�vE?��W1�������O����=��FլQo��|
�\vf�ߵQ�tY�-Mz�n@��,J&����L
��Q���~	>�:���N�Y�F%g�'(�S
�r�OZ<Q-PIȺ8�mʭ�e���g��0w��g� E]��,W��4h�l��'l�p�>(�d��ZP����n�2��i�I�0@*������u�FX�7����H��ª���YVY@�U�ҩΉw���P8�)�XL�����~�ydk�M���0��b*yH�w��8I8L�H��:�� ��FD�V��B١,�a2���2��#����������cs�kC.#а�U�y �@��h >Knk�A5�F�+Ð]kr���'�f0���|��;�ۦu/	�Z@ :k*-I�A+���YK�x-����qt�"[��07�5��L����,�֭�k�zSq0�^|��$��36�3O��{�>௥3�r�YϞJ��9dh���(M�^f@��7� �P\M�4�4_1��/�ș��z1q����������'�KSS!��
�ꨄ�pY/z��ٟZd�˥4����x`/�9���.�c']��.�%���'
�����$���Iz@7C�6�R�!�d�'�Y��vq��t��x�LK�ś����f��@�I�F񂼥^�!7 )5�H?����p�y!3�Ll����s�uEK�֫����L�N=d �L@r�0,�ҹ�rCrGs>i"��fz���t��Dũ噑k�{U<��T��e��(I�mi�-β+\��̧� ����:��"���y�1_\��B��ҭ1�IT�x�<Y�O�%~�#d|N<�jr�+�$�`^Y?��X���nAe�m(B��r�(;e�q�}}�u\�A�q�:j+Q��I�;;�&\�2p׊D��b�|p�	���G��s�o��v�_ާ��}ʢd399A� "�g��%Ί[�x���@|Nq^��X̫��s�`�uƜP�	��SP��P�XR����*�͢o#�P�r�y�4C��,��#˧��Y��WB���ߞX������P<e�B��[v.�y̪�t鮘.���Ya"���,L��&�A��SD*}'���N�T��S����.�-��[/H�����i��F*���񈢛�����ql��d����Ծ.k�K�%luL���)��x��E�r*���v
�y�b�mNJcc��y��6�M��!
2M8��M�=�C⵴�p\���
��8 ���j�?��a���\�4쉐����E}���9�#����$p�0���kRr����d.�iq����*#��L�RgN�OT � (�_��[16���5�҂l1��ld:�قo6�B�W��(�C��1��d�S��
��P��]Nﴳv������ V=̆}��e�N�k�x*�C�}$���(\\҂�p/�s�;�r>��W��#����Y���,�����LD�X�fWd}���d"�\j�H M#�N��=���M��08 ����T*rOD�-9N�MٹD�\���J�~��;���9鲆�����[{��emk��5S���A
n`��Ȕ���>c��ui�p�٩ߪ(����eT`֔8d<)M���f���.�� 0�ҩL0�M���$�c��@�48�R��(lI�$�51�PE����f�ր6G��,��@Ut���a�P�Q( E@t%@��m�����c�1�˖�.E
�A��a�>�.=]��hD6 +���,�p��̈'��Q\��6PKI'd9(��Y��X��6�'V�V���}���zĘ�	l�C��д8E�@��;���$��0����aȩk�0����b3,3��2��\�~P�1�h�mN5 WA&�#H�Zׂ�	7J�3�������X�FG�(�Ut��fJ�h_37�0�����j��TҦ�
,��7x�q^0a3*���s����N�jS�@�N00T�d1��4���e�� <��q�?X�=đ�S�%/�/,[綨������Ut
�IFz�!H~8�l-��+]E���K	�VF�d��8��J��k:A	R�Hm�#���<ArBlp^�(�)���J!�i�}U�^r`���B�>w�b�,�5tIsC���)��ӕN�6�6(-�E�"���e��g�y$��J��2���Tڷo�K\�יy��A)�����6G�����N��5M$�l�G
�-"A�k:�Z���R&�ў���G�f�[xg��/:�uiY��g25��\65>>Q��PR�1 #L56-;��`�4^]q	L�fDd]v#'����t�Ja�յ�:4��~�a��}�������V���&���)S�Z?�rvS���G~���+�b���~�3a�z�*�ۥ�o�Dv�����w[V��k4��Y|�Jy�Z�ǣ�p�{b8R�T��3	�):S-�t�����]�5���3*~R4i���%�����:��
e]�豄���H2)�F�q�,�f����)Y*r]�����\t�Aɨ��hdx�9:SǨ��cn5�Շ-��R&�K�A2�w=ŭ�@Y,��|��%2J�	͍��'$>��Z���W�N�2Z`�r�Z�n���S�L�x7H߫@A�:&��DdW�c����5V����!�������b�F�2*8��H�8gW1�<j��v��6r�^*�GL��"��V)@�Ior�z݀1��Y7�9CwN��� c�\Fh�r}X!ig��敨Ec�"�g�A��B3J�t�_gBC�K�X&Fp;~&�� ��J�b�����[$S,,h"�\.1�Z4!�����U�UP�UM̺�a���^G��oO)M�#��v��xf\�#
���3��:��4&XC��7�śr`���N(��բ�l��c��T{)t'd2�����f��K��oX�_P� ��WV�����.$p_��c��s1��a_�SՂ��pl���1H�w����]6�M��-����L�h�4�ѹ����%���#(�%�Z� �"$��F��eI .#6H/R2�{�2��J�$8�I���AWm��=��sp��=�Q��;��������:ڣ��?���������QwS��1���oomt^nw�v�ޜ����#��uwW�a�����/l�w[G[�?P�{�?l���(x����=���0:���;G[�C��ۭͮ;'U�´k�����7Gf���+��G�׭�͆�nQG��?�����q~����~�	si�����ޑ�ނ�A���F��I[�;N���l�����[�[ /�V����.A����7�lw��7�{�ݖbB' ���ÿ*X� ���tLG ]�c����ű�5�M�\���d���M(�����nm��6�%s�f�+�><�N������n�|;?����ۭ��Aw��u�P��;8�^�v���8��8<�u�2S�]Ġ�[ď7������"�(K���]����-��AňѠW��?���ͭW�-�8{�o�?.T �e;/�0/a"[4�B	�m�����{�`��%�u�����?�w�G@�m��!��H'�{�= r�>o�  �jā��;�e;v)���!b`��9�(�1������� (:c���7pް��9|'pk�w�KG|�`3Ї���Ugk��A�p�= !vI���8�7�|��
��x-ۦ����z[��:�o��8�80�-�	��z82�=m��"x%����R��˼��31�p�!��7E>8����ǂ�0�b���%�Y���ҥ8D8@�0�`�K������^�Ύ�zÔ3A1��#ݑ�h�:��!��S�d?PF���3�
��#��@R/7�&������-��)���}��k���y�����u��8��H����,o�U�@�x��^�.��:�A������s�ܩ�_�y!��!��|�5�0p�,�&T�b�$��fq���D�(�'�_īoV5�%��K�(F��Aա���S���c����\�ؼ=ҍA��l
"r�����ܻ3 �K��NUC�(1�D]���${��o��ԌLSCeY�"j��R��]=g05�]�*[�M��Gp���ƛ���9�I�'YЃ��Db o���DZ�Zި��:���Hu���H�k�a�v���ƽM�'Z��U{�J�a����3[�oh5�dZ�q�~�짛�˚M� v���3t/�$��Y���䪴��jq9�ٞ��Z��A}i�%V�vU�� ��/e�È5A�a��]�&�Q�p��D6��u�;��rN-2KV�1�!RߟM&��v���u�L[iv����0���aҍ[���0�$�7_=N5��Η�	V�»B�1F���\F9v�P���Ɩ��r����M9�t�+-����0��6r�S�`/�����e��>�%<������ý�7G��]M��l��\����~q�e�+�g�:��GC�����4��hcIx�׻�N������1��]��-�z~4�������t��ΰw*�7 A�8�-��C#��d���g��x�e��54�)�T&����c��Mʔ)�C-i��uz�b��� ����N1]�����������F+�լߔu�
+�ΏWƧ���ٹV�%4| Z�9�x�6�`�!e��JcL>��"��W�{����+���Ĳ���\�u)�v\���:�0�<Sd�ٜ�mGW�D̐rg�t��Y|�.t,����:n��a`�,�F	Ea��[�%u(���)Ch*�b|�(���.�g�M ssx:��&�!����?���>�v6w��Q�+�������#��>}��]Y���y����S��p���꣕G����Շ+��N�|��x�)��J�Fs�A��`��e��'��S{o6��(8�˞�(�!�Vnu�v�	�w������D-�RN2���$T��@��%�$J�c�O��t����;	�Ӓ�6D����Qgh�`�Z��"p�:dX�~��� {[��lH	�8�	���=
N<�j�)���^,�)ڸbP��������'�'s�N��������4�P���n�Hݟ��rhRR��5�oa���������Ý�:�l4��S,+CՋ�:��``�mqbJ�z)eI�9� >�@#�	5��_����A:�äZ�ك����;ħS)D%N�b5Mzgl���L���%H�]`pC���,���8��SC_</�QP��������X���Cn�^uZ� �jx~>c�(��Ґwe;N��۝����0+��f���p�"F9��I�7���ؔ���� ���e�p�E����
>�����e�t4�]�w��t\�.����3�`����dt
w�q,?ᶶ�&GV��"��]{�38�c ��������~����[����	�=����g՞����J�vy0�<�VV�6WW���W���q������a6LT��,~Z��Z���z��}���) Ck9�l�ĎúGXwu��or�N�<���g�?�O��{pl���/;��?���)x#6ol�w7̫?5G��{;�����&|���}y<w��h�UZ��CkV�$w�Pj>�ꋺ;�ݝ�+�w����E�`���<W��Ҵ��8":avJ/Z���j��2�:p�x`l�㢵�z�
���Μ�,��A�޽%�k��h�>�.��!�5P=�f]�e}�O�~m�'T(Z�G����T!�=�it���~�
� �a@�t��[�8RSgqēQ��`(��6�P�-��\.�$�}���1��Ń�<�O=�Jt��٬����WQ��f_�t�Q��#���cHߞ�n���'�U{2�x�0=E&^�L	�sJ����3V����q�g�k�<x ��k�K�Ks�������v���ȹ�e-�ql�̇/n���7��!�v�
�o�u���Nx�R�A�����(9]����A�h�c/x&Z�`��R�8G.R��q�Q�����cse����xue�����7�GV[+�-����7�_f���مtc<���p8��o��uX��2��6�R��9�'�U���"�w�9���Y�{?��b���t޻ݣ�㍽�÷ɉ�l^�٬�,zװ����؄3�!�{��ԟ5��k쟡���L���A�{�o6�f�_W�FWȷ�m�t��.V�Zk������u:~�����.:�K�m�0_�8�ڿ�N����a������ꓵ�=nl�����2�ͦ�s����V��s_� g�5Xh�s�C1���K�Fƽ��~k�Q�z�Ln1���T��5�Q���# �{�������4�b�u^위'��H�r���ދh����m��&]��7��:o���ݞ
Ow��H�<)��G��T���m�
=|7
I�$���R�	c��yC��_��Dyk���+! �o����q�.�a��1_K�=��� �v ��`y�!O��9���;��~��i��'-���nG�i�b��߼G�\��9Bv��_��	T���g|1̏�i>jI�����f���  �UPz�_`��i�� �m��1֒hჹ�x������0��O�~q�o���^�En'���2��Ua4��X ZFRV�m$�,�z��a�f�{���'�<ys=���4�A�jQ��p�i�h��%���Y��`AB��8��:G�O���I7���Q����Q�Z��h�J.W�n�R�U�~��$��RU�� "3:z:hN�o� �+�ƃw���s"���絖r��^���>����l�/ǻģ�5@�]�}p�^�_�v��D0�����t�f~�ۯ��ષT�����q�{�pN�R/f�ǑN��'�X�~�V���4���@[���,�>h��`[�NDs�bp32bD��	��=0�U!L3���@��$P��=)k�;2tZ����ѹ��Y�"�����Y��Nɢ�u����º����ID>� xyi��K�]��i�X��5P��Jcƣ:��Ҹ�T �kE�����ܞ�*�"v�pG��M�q6��˩�T���-�a{ �7M���0�ʦ|ǜ����kdﰞ!�Z���5����m:��[���X��Z��5!b��su�I�8[o�H�ڂ�P,��Exqb�|�x`��Q�H�9�3[��p	������U�|V��l��a��Q��O��%�n�:Ѹ�EI�i�5�K�q�� ꉷb�
�[믩�gNe�$jWa��4S9LzBh���T*4e|iN~}��7;���!.���p[�z_Yd�NH��	�D=���R���TWO�9����^�����qg��r��5�������Џ7�R�\,����-����q�e@�%c�D����U��`�@bF�Z�`�s�G\�=t��ݬ�_��q������]-��wN_�mΤ��u1��g`��1��:*ng�p����r76Y��#�<����Y�V�Ph�� � �Z����ܵ��3s��O@B��x,CE�j��[�������Laӱ7R} Cf\�W-?0T���(,�������MM�[j3j88{�Y�	��3��{���#�F)�w�ԫ�D̩��V��̸@�;�C��~8��Q��f6�fw�LO�iz�F��v�����'f��Zt�U��L�L���桫|R�M�ݯ_2��<Ǣ&Z<务!����e�Wr͂�jc�$�NE7MN�$Ab�'�6<Ӓ+�"��eR�)@
G�����z�1��z�J�X�+�q�zBв0����jY��	�>d���\��e��R���i�>�Csh�xs�����;���:%�_u���.��3"�w��[�fvv@��om��0�S��,:eTp���e�+d���g�b��D�t�AfM�ݥY�A��E�v;��<(���7���C��T��c�P������jPAݪw��T�T�R9���zEȏ�h��i_�����u��6wYT� ���/<��T�ƍ`��&a�����A�gu^Xk=�)T��+�]�5~����_�w&�:���=/�����Bc��TĔ�g6��x���j���m��0��J�_SO�)�`so���[㹧�/�����|�b��z���	�T5���b����3F�3��
h{��DgK���3j�<��� �b*�OU�m�� }���ٱ���+�8>\<8PrG�N�72)-o��b$������kkb�<��J%+H7��xw#��Lfw S��nh��ꌡ�7oo�lǬ\�����(�dƗ�:/���w�ǯ���d�}})�QU��4ХOZθj�;>��&�X�6ҏy������<�7���E�卦f:���Y��������U��-�y:5��y��.VANں>��NI9WV��x�r��_��0+8[�?	�qRu����m�9[�_� m����L�G�_�ϯ�.Ω��!��@�W���WG������f�p�n]<� mnr����o��,9��"52b���B�lt+)�Q�c�~��BeP\�I���H�yF^��N��ה�?q�[��
I�?�ZW9$��t�����a�h0��6���P)��@W��)�K@�wZiƐN�kve96}�@ſ]�O�u���c@���o���ECg��L�����5�i��ǒ4h�Q<�pL<7u?��~�ݒ;�\N��+�K�s��A��<Ng�����(y�!�3)�g��[��L����yRw�\	}sh�6 �~5M�����Ki�����|��.�.y��DH��X�oww8z�B�O�]��R�1IN���@l����u�mYp���/d�Iƒx����vҞvb�Nz�ӟ�PV"��rbOg�e�c�=/�U H�e�"+N71�e(�
�*�.��8 �8��O.���h�
�����6�����obHG��4�� 7�E��K���q�����ۆ4����2�|z�~�x�^-�5����&?_�Ļ���!kk3�*�s3m��#΢_�"F9|<�zWA���D�� ��|����l~�5���d�#�&�}����s��|{�ݛ��j�C8��:�m��_%0�"�l�� ��X)�Aʞ�J �����,���ǧ ��Ho"��� y�I^IЦ��p�R���3���K�@{����XRJPA����ɞ�x���l����Q��&��"�n��9����s�:������L�<�
��4�'�� )N�S��7!��c��4_z#�g	�6皟�[�MB��Ň�TS%�d�N�|c�����=�����+4Az ��F�|
��!,~225�����c�,���bOgϰg�pW�W�d�+���Db't�ҩ��,P#�Kd7���J(u�3�i��>��O�5�����r��It��+FRJ�q!����N�5|�(_�X��qO�N��j!J6��쨳c�m1MV+j=ۨ՞�_v�|��A� ��t�vb(��E�a�h�� ���roP�����K\�%�ē�@����˻£ҹ�T�i��e�Zym�7���Y��pʜ}m�/iB���`����(��j���nڶ��4ì���"�R��rs�_���ծw	Q����mϴ�NC��)s+���~ŹK'��|��:��1���Թ�6�KW���/۴�����V�c��=�ѩ��,���v}E�x�������N��ٚ��]ڡj�j��f�mS5u��V[���:v`)�b��\;�53t/���8�i����mC��N[5ڮ�X��k�P�\;�K�=3�O��9��,�6��*�w�����+��ԡ��Q�*tO��@�:��R���n�x���Mk�u������i�����㙞o����q����XA�0N��7@��﷭��8�t<�6���5��V�'a�q�2.�+T?p_�LK1�Y�0-Ӆ#��9�i��@��黶�ئ繾am30|�u\Gk[��i��j�m)R���]�SUUs� �1UXh�V���(���t��FG3��"{2WU]����Nб��@M��ܶx�����yX�&q��Y��|=�ڦbT1ں�imfȲ��}{���*z�yJ�z���nR�f�Q۲]�mSGU� 6�,(��f[�LǇ)65ˠ�\��Mq,U��r�u��ŤFbj��;]	T�tM�z��Zp� �-�"����i�V�
��\���ꞣ)m�Ra���͟�[����b��">�0�&>,��QW���;�qa3i��{�R`�&�mC�W��Ul�a��^�WS5<���hz�xžI��Z[SLN��3�>� ��墬mۇ���vav�v�.��cj��k:�:��%h��WG�X��80�Na��-K���kk��A]��v�N�Ra����؂�ӣƕpj
�R=�S�(8�Sl���TW���؆��� ����a.4Om���j#��>�v\
��+nqr�I�����l�N�ٺH�㺊U`������m{@hi������a|��0uL�x DԀPQu4��pJz0\��lW�<M-��0w"{⃞��mS��:�jؾkX�iw�P-<y]W:����NR�9��Sj) ���y�$N�U��vl��;���Y6�T6��	�z'�h��|���j:��:�g��}ա�y�O�E�	*D��A�wa�x��&5����dD3����4���jH=����p����Xe���bZ�xP��:��6�j�p�� �V<�N�SS+��g��`��I-�@2D�h�j��;��m�kn4|6��k0^�s��pN�m��v�U�l��t$Υ�U�Dz8:N��Xg�h� &�_q��S���Lۇ]kX�%4ź�F@K�ds=�}����V:���⫾Tȑ��C>�zqfY?U]��������kU\8�8�;�]
St���㋚Xx] �h��Q���j�:�Іc��(G'U+�M�� Nq�x�p���
�־L�`�v,�|[��	�P(�G�����-ϴ��(�`�v�$�̄i��:Ƶ׈��:�^�T��6�09��сO� �G�G�JI ��,�p=v��:���� ��� ߢV�VGateȽݭ�7����Ð\�qpt0`��8H�'׀��M@~_u�z��ؼp �����w�w4G��ʀqp2���[I����*�/)!/t�m��o����P^N�M�A���f�b�w�0����2h�m,��1tE����0@���7l]��V�_S�l���c�:��������y-�8�g�PO_l��A��C��E:�'NQ�u�	��y'U�N���:�}ėt�N�k��0��6yژ1���,>��ދi����<i�P@^�ߋ�-�ǻr�������q���it��T��چ/,�0���u�`:�x��,��Vβn"'��=�)fsFlx�e��1��%�j�`�X�`����������^Co*Y�"��X�c�(�bT��GN��<d�P��Y��	�����v��x�+�����$1yQ����lH�gd:��-q�����3h¡��E�Ŵ!��bB���/\��G��Lg<��^ ���5q����h�6��7��Y|�狈�������2����pgN��9��l���_����#�>��`|y��ܜ���NF��6/�7sV�9���As��S��:�W�:���c
`(o�=�&|}�gn�B�;����Sg-�߬q�4`��F�*j���U��fn 0?���h��o�V��.�7kC%�C�)�SÊκ����l�
m�}5�cJ�7�V����W0R�,z�|� o��F�agt���.M�X�iK�c�6�JE�Z��������ý�q5����������?l�z�]IZ��%�y2�Cf��N�^
G���5�`�,>%ˎ"G�g���]��$��\��(Q�,z�I��
�"�n�?v���ݖqfV�7i���(v>�|�y�}����8�\���������ޟn���"�pw�	k��W������.|�ئ/������nW�eE63��r��n��ȁW,�]f��R��ҲR��|`hɛ�ݬ˅9�O�ŷ( 'yWRKN�<d'�f��&q���n�d,�����u'��ī�Y��w��M��/B�Z����Ĭ� ��3 �'c\Q1zL/��d-�s~�&^*��t�
���o��F����ew��l0��hm�t�֟3֌(L&2]��f0��t����7�B�՟��p�$�S��R���hM�͛�v�<�Ȼ����ԉ�g�ᑢ�"Ѿo���5������qN�d���oxBգ�y��������J�@.��~��ݪG��&i���y���i�9H]n�N�?#��d0���>;�>����n,:���y0���<8��F���������[��֘B?�������������2 %(�ܞ$����%iv~'��
��y}�T����#��z���;X��&M,&��lt\*��-�[͊�&%%:�}�*� Z^R�H���s�K��WE"��f��X���ܸ5�r)�⳥ 7W
��l)ȕK͖���n~Zs3�GЉ�
��H�K	���d2�([c7����p?a\��R�F����kf�:���o�Ŧv�Y'&���h��`'��npMd�&G!�J��x�/A:/�1�W'鑴6�1�Ni?�)X)����;��Lnԉ_2c��#�J���a��6�0�S�9t����L�0-�]�CWW{{�G;�-���!��1�i��Rn�=ì��K�8��.�I���DCQg�93dF��<I�0����y������8�,��К�����ջ�ōϳ��fՙ��Tp�f $TΠD7��٥K >v�rF�_i˲Ƨg_�3��p�L.�n� ����7���`i��Z�������A�];䈠���k���wgQ�{�դr5�嶱@�C�M#�������Ju���T����H��5��$��^��6�ۼ����׸>#�1wف���l,q�wK�gXKr�����S����2��ΘE���ae��PPQ5۪�?W�3r/���A�ȻT�3�5�ς��#�ӳ�^�i��Mv9�d�<�P��I>Y��b&	��^'����vog'�\s���g��r��嶱��7$�_1P�߰�J�c%����x��y�����h����xſߨ��;��~��o=a���n���f��[h�g)ze������_7_]єj�W�
^z[���[���"���O�XӮ��JҌ�{h���oh����4��R�Xp��*�]X�0+��+I��F�(-%���P�#�i�A@~�����f�_�����lf��`���#�Z�1�j�q���c`lh�?q΢Z�`����w�	u�L�E{7Jl�S�>����ʖ�/p���Ԧ���.i��I���i�	IFVG�@|�Iê˥i���/tQV�k����Kmbb��TZ&��WbǓ���k�i�]C���p�p:�q��I�-�\i���R�Ͼ�q���PM�V���V��+I3>�믿����gT��V���i�nm,����ӓ�GouD�M�+�o��0 ��G˻tt���G�x\r�s��;���]�*�h����w�GŇA}�\N��@�C:"��ȕ9._	9�>�=�������_�-�io�}d�����#��C��?�p�$��o���Ya��6|�1pyED�E+X�r_O��ʌR�(UuK+���
InV.1�ʗ�\	�L�[r�e�b�2�[(��{��㖋i����כo���ܬ
X�3�x��|y{F�W�����@�����E�LV� Y��֓��$eo���zW������됔,��}I�3>`�;|���H��f9��L���ш�yɥ�'������QagÎyID��AD�-:���Y�6SG��:|8?k$��p�|��h~�Q�O³��q0	���p�m����G��ů��m,��l]O�j�i!�gە��JR���X�9��������C����È��m�Ƙ�`
��:���v"����x�	S�N�y��,�
O�Üi �7�I^����L���8ք3�g�h��fg@p� ���� 	�T\����7�Ro���9/h�¦u��������P�� d9:�)6���r�wk7��r�� '��3��k$��A<�����|��Ш�tb
�� �7vG>�L0f�YH���95�B'�>��:�P�+]���i�G�u�Y^�߇����D��+m>�������@+7 �h�?����
��e�q8.��Q���'l����B�p�wF·�3LښJ��w��æ�j_��~�K�|:��Gv'
������]��+��}�=��:��������wNw�~<�s�k�s�*��W���~lF�a��Ư^�~�q�t���Q�mH����I�^Rf&�(�,+6�<@�m �A����Ȃ#��B@\��0��N�i�����	���4��?8��7.z�՚l!���
q���ԭ���9����k���i����w�0G��o�_>��&�҈���R�_���ˏ�~��~�����}�����?�K����"��9=:��a�ӻ�o���Q���_���hg���������E�ś������V���_�?�i�K;T8��fh����J�����i�D�s �tE���K4`/�K�Um 3�_Y���Dy	t�Ea�����e&��y�.�SM��s���}���ˠ[�Ft1��|��!�$�ʋ}8�8H��ϟ2�z�|!���ZW�|ky�3�/�NT��g���ep����`����(�Nc��^Z����å7�X�9��,E�ې�o����O�`w�6������������[��V���?���ˠҝ�u��4�:WAXu����P���럸 J\�r>���O��o�^Ǽ�LG~��c����0<�}�2J���i�>1�@b�%��^��U �睅�M�0�>����N}D��_��$[�(�L\ܟq$nS��Ʉ~�I�2܃)��)������^�k��,���k�w&?q�@9q�#�rP(���xǀ$����D�h:B����V��I�~�r(������9�|>OvOs�+��F�nv�p�P1��"��׭|>���O�1^՚ZSm~�u��A�����o�ѭԣt�Q� ��K���0?�R?���r��������><%��a׀���U�v�P���몖n�w��+-��0���I�٭��|ʀ����_��<�).[1F�i�g8њ�u��i�j���ƣ))����\���SI���۹R��J�����H]
��Gw�};��`Q���E&��TBz����|�V�q����Ý�܇����Y�F�!4�R���n����[O~e�E�u�'�ag���{����A^�=I~��i<I�&�������9j�)W��\��s�|��s��,��θNW��CJ�6~�6����������J�s%����>��9;�!+�,����_a6��>� �,˂/��+y��1!o��z���C�8{�g�f�g�Kg��2�27�	I�q�G�`q���j�ÖC]g��Aݦ]�L�17�Z`z
 �\�!VgS'�J�e���,b$c��.��A��3��u��%��r>�b�r�	C�쾚��!��x�a	��{����~��KT�M�!_*���e�-��r��./�����>{�U�δ{�=m��,Z�f;.Q�M�Ϫ�θ�/U�J��u��������#�`��ECL)��XT��0g�u��ąc2�35�*Ñ�����N������Ix�������&���fU��+I�/����CW�g�*R��U��G�Ϳ�b���R�F�q�蔨p�F����lɒ���u�U)�f���o���:�Qw� \h�m(�����������JRu��}.���;�a�� :�&C�� ٓ6S~�(pT��q�u�����?��B��38��'�1ə�&���3ě9�ƹ��Op~
u�\�sGW�qw�cuw��q�bK ������w7wݻ��f�\���=^t�����GD��tN8AXB&��7�������h��g�8L�}w�i�3ˈ�0}$�Eew\=�,w2@c���f�?M=���6��{������[�5����{5I���w�܆�����X?U;�b��8��v��d����H���+�v��b1�>��ؽ�sR��������9%��M�8�`�`� �P�Kl|y�ѵ�#�b�����X��p>�aɱ��07�9��x��@��J�L	�͕�J�hY��xT����\�p�`�Ů~y��U��37�h�:f~pp�t�����ꋞ�dxR3�k�]��}�r`�M.ɓ&,)�R�`$P�w���}(T.}$�>5�������YO�]��W˅	Ϟ�f���n21< =i�&���K:���<~�,���?m����s�Ϩ��U��������c�W�_��=p�O��?u���z�O�=�������{���r�_4 T��H3�ꥬ�~!`������p�`�u���W�*�_t8������O��Ͱ��Y�n;���w��&��!'|��+Y���zi�w"K������@ba8��o�/�6�@��j�s��*�0P�ĎC-�٥�� ���֮����s �
�{�	�v�ZVG���V.����<t� q1�2���dJ��)�a��J�N�V���}��3�������aU��JR��-�ya0�oK�;l�9!��K�9Q1n�С��k�s(��0�ԝC�A~�>V��$q$�c<��%0���;9�����nI�I?��6���� ���Sl�=��C��)�>y
|&an���]g�7(H�Gꛍ��ƥ���!3�>i|"��RX�ƈ��2`��_���#�O���ɟ���I�K���~}����,h�ȯ�᥻���|h@�L��l_c�q]qO�~O ^����c��a����s�p{�:�$d�`ԇ-&��o?�8�;�3w��xĶ�d��cn��RI��m�8��v�-dc� ����Gh�H1�s��̩����բ�r�%[I@��.�V`+�(����Ϛ
X0;�n���w�q�y�5�$�pk�My�y��l��f��\`�1���-7qiS���e����iV�W/����韥�������R��/:\��>�w�J��z��C��Wo��[���7�@죳��b<�"��0����t�(��+z���"-��,�|�� �8�{/����gl�<D_��+2{�.�^Ư������T��7���C�Y�:K��3g��ptZS��MH!	�)sV#s}�I��������t,u�VS�m�i�tm{�����hm��)=���� c��� �W�5U�����ɟ�ԋg5v��$��i��`��ڊ�֟%��h�Կ�r��'�ײ��Bv�p��n��������v#}%u��g ��j�	vh�#;ۺ����Oѯk����P� ��� Yq~�~��aV<��bi���5���tf���)��N�����Ҁ�����%Ā�0��s����I�Z����{O�:es«e�qU-�!s�rUE��7����gQ�lֺ3�$��k���O��?�>n��M�T]��?��ϕ���Ot��s�W��<���K|�w��o_������O�f������ʧDu���<���j���f�?��v��������PA���zu���T���y�o�&����Vp�1�qh���QA����A*!�J!oR	y@!�d�埦%�	�^�������@Le��&tN��Ԡo$��~f"_yڂ�r��/[���~W��	r����o�����q�[�} #8�pc\�hE��(�e��0�������oNt���?ZE܁�\��+R�WMe��]��+I���"�D��l�ϭ�� �����5��AGS�G�6c(�Z?̊f�@A8��Ɣ�5�8�dp&z�;��m4������R`X٬�g���ˬ1�on�?*1�3��|#3�)�|8S��so���5�������p����~zg�?]g���A2?��001A�zH��@��'���S�|N6ϣ��`p�>.y����M`���9/(H�@��)�L�91"�B���`���ȑ�8�o�����+>R�
 h�~5�;�O^'gS�6n���i�5"�[{k�8�'PZf��6�R������	�O�aV��I����D��lԟ�aۧ���}_W�Z�m(MU�M�j�M��V���gX���� ����&���!��;1 �҉ǩ;©�&Z!�����!�~z
�g��#�ڸ��i��O���oAn�M���f ���ğ}�3�|�Ig~)�B[�A�2w��/�~'	`��/C��㿨�mU��*R��B>�A��,$���!	���G��E���|�\���\�m����_=����a$|���Um`>�H�\�t���1�@_A��s�xy�[��96#��ϖ���m�@�iL��	L�f�u�6o�(ؗq|�qD�n��`t�~���v/F�󹼝ܘ��3���:`���'��k�vEw�R��(u�����h����6�_����G	� -uq$�;��B���\߲\޽C-�ݫ�{�Ad\S���ǋ����6�1��p�q���x��|+l8��a���g�3ކ�����g��>�7tJ�sǏ�1p�!q"�z$�F��S�4a���q���2��l��Q?>m�@Wz�����ۤDi�7����TT� ���hx�(zF7�=|�I�͆��$�ߏ�4n�b/l(Q�� (0�o��xC��C�YC^q$`�g���a��m���W�I?�b�F�E0�V�N��Ƅ�k
��V�	���.�|�G��G�n�PG��Waԭ0�����?0�t�D>O�xR�Q��,�������%���#���a�~�R�28�Kp2�0�|���o�c�#��/�}�k��=��p����l~L�4��`=�+r������	�~�`a�ɜ�GGӅ(���o�}ݺ�g�l�h�m����6�����r�J>e�?��O��P��L���Ƃ�Ͷ��&���Z��U�?�H��gr�8�@�;���IrR�J�"4�A��4��6£V��y�2#��C���Q��pg�H7�!h��Ԓ2����(xw�rӪ�k
V���󔠷��p����x��x��X(2ΐ����rJ?/�ϳA�7�G�Gۮ�?9�#�������v�y���(���~��9�r�8�]�G�0jP�v�)d����Y�D��+�������ﶀv� �v���b�
�`�����3f���ڪ����m��oڦY���HK���fV\@��p�8�����qNN\��83Ҝ˧��g�2�L>�/ �)QsE���v�.���_�YH�#��T��g�P��U�J��(E��;����<��_���f�YZ@�uEc�_-U�-���?�V*�_+I��������K^Vt�^��2!�,L�C�I>	f 9���y0�
\� �a��������H@{Evh���t E�����{{�q����p� *4�S�=8¾k��Y�-uf|g 3y�n�n~��Qֵu}�X7׭���Ý�;o�6��tq�`%S�il��ϝ����,���}*UiU)��0�ߧa$<�G�Q�R�X��Y��o�e��ծ�W��M�� ��ȓ58�Af��J�r=�K'&vr�ɿ�i*v�yF������O�d�{-<u�2k�� �.�g^<L\t�0x�l9�
f1KG���?�$�!�#��h�w2N5m&��Э'OYO�5ɦ�� ӀZ'�I,v��Ban�] c�ҐAܬ=Εf�p�a�_�y#�=��!�Ƴ�NZ�h�ܖ��o�Ѐ����%�.O�
S�r8z�:^8_�_T_�L�],C%g�h���J�A��CKV��D�w��ҏ_k۔#>4��� ���
Ƴ���QwD�O��c��T�6��N����� ٿ֎.ƴ�(��ꢭl��X��T�������vm�3���~k1{G�=�現�x�p\RYZD������ӸG���(5hf�;��qV�/^8�B�~�ug2	'ŏ0fAB~e3E�ݳ�00��dj~Q����<� W���EJ���h�����mV��+I���t����z��w��6A<q����16�}~���V�Ed.c:I�#�Cq,��~��QN�֔Y�-�R2eD= 2����>9���>��p
l�a6���BS�e���MhX�!x�� ���ӡOFa�4Q�_t&P7^�`6QS�|}t��!_�����8���o�,�&��=OB��&o��摍3)D�ω�K���s���A�e4���K��'̯�����q�h���ϛG��o@*��(�0"��9a�7��vإY"w�H`؎r���8��l�g�5U��3�@S��I�L�}%@�C)��ͣ�`(��pt���zzӸ�9�Rh�G<�G�k�+ӹ�K:��]g�o�x|��[�*n����Ua.Fgfp��$���?���	�A�|�.+Ќ�Ex�|�)w4� 39�ˊ&o��R�9�5Q�)#Y��L�u�]j�pF�h�
x�ۉ��z`��d;d4�J�M/�����2b���Ӗ���TJ����}uM}����nN���X��+����6tK����U��+I��y��f���!��p2P�Z��;N�M����˫�7;��[��z;[Ǉ�G�89> Z��;y��y�������F7p�K�����2���?K��m�i�ö������H������迕��dt87�b:Á��9�@��x(/1��x;��J/����jx�O5>�/���v8����m�at��?X�>2�=��%E1�6]����Ǽ���|�y�}��t���-=���~�����?��/��������v�k&7}ɾ8݂�v�l=+��(�H�C��������:-�bS��X ���(��iiY��p>04!�J�n��B����1����'B`Z�Cv"k��lw��A�[�o^^wB�J��ސ�˂���ty�ۃ/�" jPJ����6 /8 v��\�Dcz	4���Y��'0�bP�\�u)�Ͷ��S����5���(<(���B;��Ew�Sv��\��0w�z�����������i��O�z�H;T\%�3q;�dP����x%��k�_��w�ZZ�4)$m���}��T�.}mBfK`�r�p͖��\)�Q�� J���e�*�z0�[(�'Ri���|f偔䦌�H��q�N{�蠴h��4u)	Jg�?��i�"Ƨꇧ<�_���X�����)��,���- C{{ pv��v�3$��39-����4��6��a8�:�8L��q��`OҬ�g�A���8Љ'ϡ31zl���K�dؒ�tbbp��	���\���@V�ެ:ŷn����o@���A�n���7�SL@����� �<H0b�M�
���9ZLS��3�3�kgL����¡kF�b)u�(�
qJ1Yxp��� f�eNB�Dӳ��tr5=;s&I������̍M"�EY̝,���]N�I�%��'��5�ϱ<���׫���<�o�*�p�3qP�S�[b��!w��W5���U�����&>�5�^09>�5d	O�\�K<|��W鮩\��	FK�^��5)�/~����W�%���-�e��-^��W���E��6x��׺]��g�<&1a���7�{�����B��^u�g���}�,��u#��`�:��`��������|~����u#w�s�5����y@0
2��Y^/�4x&s��f�<S
��~�6$C1�x�H��:����{;;$������ڳ�p���o�l��<�;:Y�o����i3�_@����T���_����ϱ )g�oaR���!T��ǘ�>�4�+͜�Y�å� Yp��v�X���-]���U���?�g�����.@n��.@¼#�������G:�%�>�Sx��v�N?���~�~�cW�\\��;x���[: ���7o��2 �u��x�������Λ��Ij٭�����G�	�Ήji�z�#H��4�+�A>�����[�g��u�q��!ȡ��J�q>��<�"̻�����1���	��M�X
����G�����T��W��'��y�<���7w�v�x)��˽z��; ��U�1�r�����G�H�˱�I@e�[ʛ3oD�����"��0�u�6�����|X$����}��u�#��k��A�̚�pq�wF����8�8Do�e'r�^ۃ��l�BK�p+� q�I
���p�υ�?���&~U�R��T�*U�JU�R��T�*U�JU���<�y�W_ � 