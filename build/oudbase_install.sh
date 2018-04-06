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
VERSION="v1.3.6"
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
� |N�Z ��ZY�(Zo<�.�l#��CV�tv� ��bj���'�ER"-E�#$0es�����{�<�]Ӟ"B`�5���4H{\{�5��O���/������ӧ��}���m<��G�?�x��:��ٷjm~y�;��K/f�4�`)y-l͆���>̿� ?�p��lpۛ��V~��X|�Ϟ|K��l~[�������Sk_`-��������mD��0?�����h�Y|�\u~h���<N�<W��E4J'�(��Q��d�fS��r�W�>�0:��(ΧY����cC�a���aN����쬡z����Q6
���/z?G-��T�̀/;��y�ɗ�i4u�g�X��Q^W9}�J��
 Z�t���xZ����vލ��?����� �Eq�	}Ck<�e�4���K8:��g�d���:����H�	,<�G�ׯ�\e�t��~:�p��4��|��pJ9����8]�Y�0�T�\�Y�Б����T��n���-q���`���$�l�Ϡ����fx�Hi �p�ݸ%z?�6�����F�K�0�8��G���
��qE�oF��v�f>�uN�%��&gQ~�l�- >�8�+Osב�t��l��l�X����٬�L��>���vM�w��J�������T����m8�E�7���v�_�.�[�[�j��A�𰻿��v|��[S�~ �����O2�_��$#�<�u_�^uv{��"�N�J���m���w��/VV��je���l�u���~zQkOǓ}�jg�]��5�n��[++��w�9:>y��lw�^��/$!�,���Gg�k��6��W>
Ԯ��+�j�^gg���}���^����4�ڵ��A������Z���w{8��El|�D�d6�O���y�V��Vg������<�w�<ԫY�Gܻ+��P�w1���&Ϣպ�X���q>�W��gF@T%����ӽ�L�v�_�M��QD�����j��;��;��?�[��Us[}�}����ʿ!�L��+�!߫_�&Q�y^u1hr`/�#���sz_T���Ts�gU���Q�=Q�,���>Q�98۶?[/[7U?y�gQ���^��n�9�UB�%|�&�ћ9�K��?���]�o7=#�	G�{��kn������j�M՚��92�$���Ea�I�1�F�V>n\�����nW�����}>����^�_��c�bR6��$��'_�v�W��G�������׿�|t]�|�"m�>R �fWp	�3u�?�iH:�����z@B��U����=b}n(�x�,j���	>��� ������j���O�o��o'߼��fo�^�������h~�dIgb@�����F<��Z����^�Vŏ��a�b~�xb�uM�P"/�n�e�Emi�yȨ͚ ���ԧ)���й���w�c��Uҿ���pj��<��N��i륵Ro����.�����U�p�p^Sg����$*Ӥ{<�￯�����ys��7]6��e(�"ɦj68D�)�O�YZ��*d%����u$æ�Z��X���YK��K�֝�@I�y���@j��[�GЉ�T8Ng		�av6C9o�\��2$��4C9ɨ�N�q�)��jYy���?]:�+��� ��|�N�@sdc�Lw^^+�
�8�l�v�4s��+  �tV�F��є�>/�x�Ң����e#o��рF����9k��/�f���n���@�vK/������R��]VӇ��h����7� B��I~�����t��,IPn�P?���n��rG$wF���O��<K�'�e�F,�^M��p���oᏗ��9	me�ݽ47A�¥�u	,��n�hI1�} E�X� iL��-4����7<2��G�1!�(lśVG�v�-+sH@�н��}^iT�ֿ��x�0`o�+�S��N�\������N��Y>U�a��*m�<�R����R��FP�V4GBmbcm��.�-MG�8� E B����jũl���kL�pP4T:��mG�"��J���������
ͳM����']5���������1=��|�[�v�x��ϳ��H���]d�
���*�n�/�1�Y�g�0�Uժ,{
�ƺ�ȇ1PW�v��,�x���O���߫��@o��5���E� �p|AK9��ťZ�y��� ��1%��:���Z
�j��J}��]G�����a!ː�w�Q�T��/x<���XU�m�΁9	�V�'���ac�g�)��w�8�>��yz�VC�Cuh;i�DHX�v�C�`��T�hB.	㇪	<Xj��uM�	�����xݐO�1B�N��`�:�Ԥ�:��7�7��nf('��U ��U��b�\s��E��I8��u�w�"0���!���oc;�8�i�n�����{����9&�HqUݺ��գ����Zy�2*�u���4�D�
 (\i9X��]qb1U�����W������؈�+�s����"d� Wd�X񘂞M�*�у�SU�:���h�R�p�˹ܐc}�_@n�j���q5��t�Ha�vU������4^�%��H̝�s��\�J��-�#��Ϳn6k���k��wGtW�Cd�����k�z/̷��̀}����j�ϖ�h�hAhzA�.^+�/��M��7�YF_�'I��7�L���,�D�4�r\9|İ��އ����U�ơ�4ٷ��{���¼{&g\q�p���@��ҕ���u�L~E!���90�p �\0���PAAj��a���J��~�^��k
|�e�}��6�Ƴ�4���S���$$�v6�>LQ�Yi����%m�~~�`�:pNK'����t��)�V����3=a�QDe�E�藈������,+뫇�f↎�:����o�N����R�5��[u�\��m��&s/TtQ�����z�ׇӱ�aW>Ǝ�����'� Z/߫�/�?��<꽨�K��@�}E�֞��� �ދ��#�x��u��U�/�� �sj#�X����}�gz�����\]y�wyK�y]�Y{���7���)���U7��������	>]��[���G�N�+��Y�0� *��7�8/jGEg��S���cj07��H����<�,�ϳz u񍆷c��TU��2R2®�n�����wy�\6�qr>[�\��\�mm��W���8�'e�,`iw�X�Qa�Oε»�Y{.H��^Hڵ�'ߪ��o�'�h������F�E���ب����(�D��Buoo��K�����Pn��h�_o���U�"[�A�PE3)�)�;�f�#��]f�y��%�{C�E(���0͐:���hl�Nf$!����[�"�m��?�ǲ{U
ғ'e��B��{���P��������D����������������?_$��.��*��܈����Jk��+H�_C���B��=F�!������k�;�;1��r��.c�� ���~ĕψ�/w��Wͱ��A���1��Y�S������k��(�����sz��gz��H�ydn�m��˝�m'4��A�6̇����V����������?n�R�'9t�}���nE{�?T�u�ղ���k��.�����&r&ȽH�!0/�r��� �y]3񸧻�w���f |� P_3 �f ��f |A������&���<�߀��&��B��A��NPb)|,c�xn���*�Hŉ�_F sP)AT���-��)FK�I���fB�+AU�%��/�xb��@�(0��(?v��q�JT�q�u
�����$-����E9�O�>+�%"�5��k���ԇӰ�~6�+r/]�%��{��_������� ��)����eCm{}u�eO�b��l��g�5�2�a�vd�KG�3����4�^�2��%��3�ÚJE9~s�FL�rD"��#��VK���v���j�W��{�u���̦4�le����#��~\��#�ZY]]�>M����m���&GJc�k7����j��r k���Z\ �f��/����F�kВ����+�����"��I�H�[���� 0����A�����=��ϋ��9�
�$��i��6ѧd6>�?(�d$�%6��Gj��y�6�!b$�I\��;�O}'��M�G�X�Z���괬��oƛ]J n����9!�ch��WV�^��~B�`�~�h�S���b[�5=��sZ�GhO���eӘr�V�k�(����v�.��i_.�AT��8���R��+C�,�Ka+�Ɖj/�O��;rl��mk���i���б`�wxZ�xK�1�V)װl�1xh�G!>�LTg1,#��cǝ�/��T4$h���?�)˅z����5gBD�I��X}������	&�w[�3�+�YQ�E�}�v�sܹn?�dV�k�H��݈�:�x^�,�U�*���w���A["�����֣w�w����;\E��J��z�a�	�t�J��/S]���!�:�|�G��Zz0�)�����"�e�6*����ђ��D��4�pB����s���~��ȅX>b�S�1�	��ΕFcf����bP����1���BNo�$s�2���V�p:���O�Q@q
�TvY��hS�l���h�y:���"2�� �)����'�h�^�+�C ��J��뺣���d'3��rK���������&�O�w�ݨ�>���:: 2�o���=�n\ޣc*+���e�)��p�g( ��P}�&l�*2 �h2�h�;�N�zn�Z���+Y�=lԫ�IWap���c���q���M����/����p.�T,ŏX7˙M	��W��$D�;��5�6�
W�������H��g��)��Eۖo�vOw�J���=���Uj_$J�Ֆ�y��^�����t���2�~'GgÓj0<0}�a
�օ�-шO\JJڱ�{t.;c��8=Q<��7.�a��9{u[yҌ|(C��*r��n�I�ǐ�gGi:u����T@��?��y:
������^�d0˗�i��1�^�8�f��e�(��'�#n�v�����xWk��h?<�-��W��s·}Nd#��A���m�v}�a�hX����� ����^�"b=�ٿn�P�� �U�i��$��F37�@��.�\���v��xmx���8�c�l�W���_��=��p���D�� jF��.)�T�W�K�ԣ���-�?�	.�7��8fT Ey���7-�MT��9_ɿ�$T�ES����$g�
٫{ӫ"� 6bER��&�o o���r�z"]��D�=!�J��ʋ���ȳk�)1͕�c�����:L� R}ר�s�?U�ܟBx�I*�H���X���h2�4qkJ��<̍B��9��d7H/����>�����̌�fS��39�V�X�c�&{�=f1��Vc�&�?�׾-��l<��k��o��5�G\��17�#�G�_�����e���?_<�͑��7��˗�[Ї���1�:����xr�d�}���.~���9��Q4	��NP�}Qk6��V��+�V��g_S��g��(5i��C4�'JR2Y5���;/_�l��8WJ�D�����Qw���ٵ���}������sώk�ڥ{�T:�(H3��y�~f��P}�����7�7�N*.Kg'�_�����'�[>����9H_Y0_s���kQ��9H_s��� }�A����5�k����9H_s��� }�A���A�n�ߌ7Ǜ����A���*st������-�(��Q�Q�@$��ሟr&q��<o]Eg-�/�_�s��u�����L���:_3u�y3u�쌛d�H�����-q�n$	��� �%�(��#��::��kT��'F�st��F�z��I��g�����N��5�������Օ���uS� 0A�T�;�. Oz�B'��Rߠ�:bD`N���]BEg���K{�c����s��N|�|0���=��$�EFvWH#�[���l��;&�� ek^:��R��I[%��5i^2�uS2��M2�m��r1�v�H�X7IEr��<����K�HK�R��T5��T$Ab)e�Vf93�>��,wڻ�w(���h�P`�[̅�D��t"�a욗��8��^���#����;h�P&��z��rd��x+ɖ���5^���&�^����渙/�V�4?���ci拟�� �� 	�J�a|VA�K���n4Q{��y�����& n��H<Ckz�W��[��� ә�2��J����� �/�j���.S̊]�h�J8�̱��T���������D+�*��>?�ji��sb�e%���n�a5_HzYI�n�H��IT�N��-��n�8%�s��͓��y�+�Py���
gٙMS�y�Ќ�%���9-F( ��u�B+N��Ԫ;g?r��ͥfO�+�y6Vͬ�\F���2�m?u�0Lg���h�,����B"��?�=6��v�D6Y��'���F�l_���=����X��������F!�����6?_��d���?�׹lӣZ	ѯ�9��,���,@��g!�6�b���}ʔ�ļڡ1�]pV�/�D]QJW�����(KB[�/j��I_/o V�m4�U~n�x *0��*;�E^� *�nr��<��{�L	`o!:�d)���4���WgQ��V9��&]�ĸ��'(�W���9�84�_���b����\HN�t4�Fl3���	6m����r�$5���^���mu^��V���jr9 5�^�˥=����csC��#��(�Gݭ�n��Cg��*)�+EP���(����%�5�?8�@����q�h��ÿ�6��i����O��<�\�~���\�����O�~������v�+�|��_�lw��S��}'ssm�A���M_J����N��y�g��g=����C��>��W��W�6�(H�4�T��`���SLB{{�'��n]�)/�)!5d]1#���:ov�e���|՚�К�=U�q[��
c���4bi�o�9�����4��l����;H�y�A���캭Fi��sڼ�!e��=8�0F�[E���V���9��:������I�i4�P ��qxt��f������?uF��Ɠ&����Fk��$j����ޏ���K�Ý��=H\��I�t��	EBU����G�D}�������/*��:`'wi�|��wM��m6����0��b�'}j��x�5o�&��﷝G�k�q�\{����0�"���̥���#�Q�a��ytPD¹���v)ֺ�����qc! Z�%�A8] c4��S��O��y߇r5g8K&eP���Ir ��y-`�CX_xF���Ira`�����/Srx�~���g�����������߫�RK{��E��D��e读_���	�'�;�G˝���y��S��o9ٯ�E�P�B���O���	���w�HZO�8�m��lm%���_"�c2��sB�脐�cQ�>zM�W�$M(]cD�#�\	�>�Fs�pv�l������\q䗞k���%�� ��>7�|�L_�<�@�,�BD��t�`�����VƘ�P��;ćiA��}b�L�_8�ǡ�정�Dd�k���]��7��͇��*��[�OҾo0�]W��W� ӕ����H�$uq|������\�U�Ŗ�HK�"m���
OGW��@�c���}DY4����^�-����y��s}ֿ�ƣ; �9�9����e��!� ���4�	��tBK%`w�_J�`���#K(��)N�An�����
۩�� ����r2���31m ��H��ט��7�8Ù)dC�`m�r8{4�5��M�c����~�IB��n���Ҟ<T+RS�~�7�ó&��D	�B��B�;i7�ެ��d��5�v��L'��nq����{h2�L��եJ�LR�9@�K��ź����'����t��a�y,��?�?@�}?N|��^ZB����cu��G�+�}��ٜ����Wh��?�q+(]oO���΢��	�W�{��Ǎ�w�<�ov
�Z%�k߮��W~E�Ư7��F��jհ$'͍aY-i�
�4ᗇ�����"d��)��4�*��]]₧ ���>Υʉ-X�\�)
@e��y�J!��{����T�a]|T�z-]�>��(o����zNCi��Sjkݒ~[:�R뢿R���+��S�/!��&��x�ټe��&���Y�\MrI9�|A�*	�I�Udg��+Kňo^�ݕ�Dy�F��a�O����ƝL��V��wՊ(�N�I�pp�/�NE3�+%�zY���Y"�JЭ�T���ҤezÒ��ZY�~����&]�Ms�7�˻i���\5B���|"��	��i: U:����U��
SF1^B[�cGni���S@�������ȭ�Q��Ǔ�UKm�t}����T��U0��j/�}_�_��c��d��(:�OZ�pS���k��	}Ejm]��]c����V��_�J��l!����� �b�������t��+�oO�����~�����1� ��Ge��!M���he���,쏢��L"�s_��I�F�E��x�ɘ�����]��3RI�Ve1������N�qS�+�t��t��!*4�r������I��i~[[�E@�G*�^���{�H̫;U����nE��,��t�/��X=d��4��Q���*�?�l���B�y��K�|}||���Ż����]y�Ͻ��[V�c�I�y��F|:�2���s��A�G���D��p$�D̏i��V��2�,V���GۚFXfz����sT-���)#U]
���z�6%	�q��pmt����u�i]�"��1�V�0�Z5ם
xOJ����}?c?��<�ӻ�i�g�g�]�T�xZ��&m̲l���V�����'���X�Q���U���qI������o�Os�Ms}���~}��ͱXW��_�}��y˩��������j��v���%��o{[�l����b��9���^Q���u�I-��/y�"Js�L\�N�f��=�6� ���p�!���Q��4��i�z%۵�U^�'�P&S�?�*"Ex�B\]p�vV�t5aZ�A�H��V�ω�<�.��E!�f)=��Qq�u?˙gx8�<|NH��[�c�������|N�<5щ%S_���������|� C�Z�x��[�S7�p��A$�wn8�����Sm�����p�wҔ��}ֵ8��]k5'#=���w7�7qVĜ�$<O��^P|㎑1t^d�ө��>0�QP�vʢ�]P�]��b�ɉy��'Q�[ӈ���J�F����/���u Wc�j峌_C��腌��.,��㝒)O0 ��E�i�����"�x�+.�R	���OO�YTP1�k=��d���/
u�\3)�Uw�#���W�N��Ϳ�5�X�1C��}R,X'j�2<��8ҕE�=����_�a� �7u"g@��JNH��gX�/���`�ŏ(UU�_�Ԕ�4�����U#�����ѨB����D�ƹUD���J��iDW!/(窻��������z�;>��L*F?/ {���V����+:��.�`G���u�t��.�yEOGs�x��c?��TX�����~���-�yE7W���|^�K2#����O�����ϛ��T����B-�\{�bq�����>���|ɔ��'��d���;g�����ϋ���m�*}�y� �u:�V�Q4��]z���.[u%A�9؝Q�w#i�������a}�ǝ#� �Xi���_�B��^�%���D�ˁ��s�-��i��0��*���i�"��3��"�f��*�~�u�of��D�g��� Vf�q$�!G�Yi4���E��e��s^&7�(kP/Z��1.�m�`�Ӏ�$�� /#,+dy�m	**@��\V`~�<2����?,�����^
r��8=@Uz%f2��c�nT�#�#ȂԞD���:�;��	���`I� C��zT������Vo=�'T�Ŗ8�7��g��*�T���+�w�sF�(�m6�l�++��7���]�V0����G�`Ѣ�?53E���⥞��=�5�I��Qۋ�HǾHO~�[�rT�Ҫ�6&���?�*�2�N4��~�l��j����^{�o�>�ɣ��/��H���ZՠA8�/l=#����^�m�,iH�UV����V�|�!�:��$,Y,6^�X&|�y �d}������VSX���S�t?+ڂ��&�@G_��fC`�^R��(a����ܱ8�\��+vx�c����@�T��i����Q��lk�K�)��O�"Z�g��S����HhFXXP�f�`��:[�@�)���)���x+̆���uD��Z���~���e�]�
��_�
ô����$-��Q[+�l��j'v6EҮ�����$�C�;Kʫp0~�s?�YE�F;ȵ�ctf� o�*t�~J	�Gȱ4�ֶ�Ih�&M�	�x�f�a6�S[�{f!xv��|�c��(�B�s�0rD�sD�Ɵ9�AW����l��HTu/U>��,R8*���ds�*�Ġ�}��y�OdN�Wŗ����OX�_,����C���ey2�R�!��hm)ddzR	=|�tU~�W�����Ü|rRX��0ڜ��n���wzk2#;�D���P4��p����Z�\�N���/+y���q�e�݊����E)my�ѕym�F�s�k��,�:�"���s�p�x���B[~T�gp�+u�v�1,�5��?���_<�ת\��LL������4�i�G2�x@�*^�1,s� �je]��+�Z?�\Gu�,*�u���>T��>"Nf�|8��~�F4�ӍoV�LW��v��Sܶ$�9�,� 2�Ue�n��%C�e�G�$�b,�����
Ai��ٵ_���ȏ�q�׎��F�9�����}N�X�GWq����7$ u�@�2��w���A_l�hxp�Ӳ
��5��fq�a��{���2��Oԍ0�/y��jKp�Y���\���(O���<NѨ�^B�ʀzB�����|���_�/./\SI�qVW|5LT�,8��ӥ���[Ւ--��$����I#25X�)����2ne�'0�`���̸z�	��78﷊.�>��*�����zΣ��C����r��$o�m5���[<�꼓&;2�F�J���V��TZ�*�ߴo����f.���Yз�!���@̗|P��5��&���i�xV�9�����(��,����<��?xP[)�]0y��AU�G2�#6�v�����#��u�ұ�'c
�0��f ��mr��������[Ws�x�a�y���h.��������D�ώ!��t<��Ķl��C���a�E��a<ZH����6~����rϧ-�w�Gq�g-2J�I�p������N�����"�:��Uo6ͻ��P�p�"����֮+WZ�
����yG�d
x��d�J(TO��8T�>O�chش��k��3�Kcʜ�
n��g�N�(��_�j��РX���j��
�b۝GTn1��1�r/��}��M�l��C�t7{�3?�-/ukm/Q �0�ݮ�.v`#��?�Q+l����-HgE������`}t�vҧ��$�-i�aK�ؒ��:nI�'N�T���SS�O/[�M�Ɯ a�2�3����X,�X[M�����������F�8�潾~���w������N�D�{�K2���������Ҵ�gE�cP���:���,��J��_b���9��3�ˬތ�X�'�nu�O)�,�p�J����#���J�z������`�&��K]�` -N��ɭq�ت
�u��2g��9�
DA�0[��bVVuH��͋���juw,��ſ�.�>#��>��~��/�7�Ϸ�]�a���������Eճ���\��������?������J�x5�(E;�[���s7���M/=w����EN�r��RkgIQ%5�\*|�*Z{M�㽈ogӢ�����"f5�����c~�yA=2��a�d�d��Mz��۫�.��<_Ԓ^pv�|��~��"W��Eí����S�
p�<����(���Ke�J'�ܧ�=2������Do�Դ�W�gMc^b���l8�"�+�����z�eG3���\��)SF�e�m�k�:�O1���ۼ�ڝ��j�3?>�6��M��%x�ΥV�F:�W�#Vc��:J������M��?sp*�ZU�>���ʊO�w���Z�WU����/{7w��9�ñ��u�Gn�앂K�y��;�ǎ��ή6ݨ�v6m���T��]�^�}��\V��*���+��Tҙ�d��ط� �H��,�8"�W��ÉA+>!茴��@�[�R�� ����X��Tlnc�B��5�CS��|���r���؉% -�����Թ�Qe&m���o5?��J(*W��֚~�V_��O^��ľ�Õ���PvϺ��J9f���ϭ�<?/�<�~<O��%���6����s������\�XLe'Z��\�&�������䐰A�����&)[TR�z�c�R�W$����Ql.����lA�w��3H����������ӧ��}���m<��G�?�x���ɷ��>Qk��O�}�;��K/fH�a)y-l͆���>̿� ?x��;[��^����x��ɜ�__{�t�q��7����N�}�9?���_U����F����uv�ᛗ�JP��&?o%#�qCm�Q�i�Dj���tr��g�S��U�ի,�T/N/1�g�n =��wR�u�[iv��>P݋(�B�y��	��O��R��J�+���S|��D���C.=�NΘ����%�O�3$��9��\r&�,���h�
�m�~�(�����A"�Q:�H�Na6�+3�{D�(jЊG���w�Y�\�B��}�(W]ayKO"�ذ8N��W���a�w���A��g�t����2���.\�T���H�WN�@��W(�L�0�6�����4J|Ng�0��8cP�ӵ$���b��,7�����qe�$�4��!B�9�)å�HŜ��'��d@�b�yf ��N&#4�R 7�+L��4|���DL���?�����yJk�)�a�#�tőWAK���Ҕ0�G̀��0�$|��A��4�+�_��j9`�üAO�M�돩�z�>�(���)Mi�������>�*ǝ�1��c�#aHu������"LM�x: �5����1������m46�Cw<mX[�W��$h)	h��\?B�{�)�z� ����~��u�)�tnD�r:�$bN2�2f�oD�+<#���q�a�^���I��A�/�p��8���(���<����4�S<s�)�PjP@�1�~%7�����3ܴ�xEh��WX��C8��`�E+�g�s{�t眰y���D�v�a$�c�,TAQ՜��Տa�d��0dQ֕�k 7�*�8�Хk�ց�z-��0N��,*?t!�D�E���!�k4!8mcs:AԠ�WȈ(�V��"O/;��$�V��6@���k��"p��E�^ݨ́D0~!a�����F��9�xa��a�6QGAs���w��ML�����m��@'3�X�{�O"��=�̐�\�SJq�S�O|
���&̤9���N��	�i��g�iH���(�@j�4�yY1�g�x�v$1�
l�1K�t�ö�3�Jݑ������֣�D�~Fj��Ra�J�R� U����͒�������p.Y8�a}sl�N�!�p	�@(]��A��cņA��fT�@���m>��0H#��&�I8|��23-S��2%m02ܛĒ�S�i�?��[H����L��<����`�a�u�"$R�<��_2^qh��Y�P�Lц��ˈٝ=�.�# F�"2���Kc��k
�K/fؑ�$
3�<�g�hZ�0I����M<%��T��
ɣDV�]���Ҕ�'5���������Js+&7��B��8��50�-��d�9='��	dF�ʈd����>�Qi&m�$�[7��?դ�L2�{�����(�3�	W:����}B�4
?H�=��AW�"��T���0@$͸�^�z!����)9 .��g��}��2"Ѐ���y�I�%</K��p�45
�|p���r�֑��X<�b4Ar�;?��"��R�'(w8t\jJ	���E�)��|]�{��S��m|�x{�x�`����ZXS�a�;<���)���E��=�+��@F�����%D�k���n~)t�Ej��׭�lBZ �q�@��(a�ެ;u� �.e|3'Y�I��SN)��z��X�\��f8���^�[�V5��5:��jj��+����zAW��6i�Y2�k�Z+�9s�3T�pB����+r�'��Hj��\L&�t+]X�!����NH�E=.	@�T"�>��؀�\�����XM��|k���A���=5��mE��Z?���~VPD�,nWb��v������kd���ES�< 4!-��#q�p�5d�\sz�D������� �G������XPw��!�U��#�ԧ���2 ����M�:`���@Ie�8������Й�>��f�	<:�J���d��%*��	b�0$ރ	�vP�(%�*�P8c��V?��\F��9	��ETDw��x�EJ0[ �%�l��D~Qk�P������	�+��U\������b��0`�S\LC���iKI>�&�Ӧ����	g;�E�� �E�J0�΄��.���)�y-����<Vw��B�1�5G���r�k�!��5Vn�"�/��l�0s[tKh~�gS8$V�J��z�������&�C,"2I< �hӁ&�9K�*�A�Z¬�
��T6`GA�c��������0�j$�lM�$�2
���IO�,[^pcgVv�p0haC#a����g�mcb���8��P��<���5Q�]r�b��V$��t�<ٷ�Z���5�)2���_#��8��[({HE=h����a6P;h��H��L�c����0vq��dH�΀�a��4 �-\����AIu&�ۛ�r'���D׾?���6F0�@���ghIxyZ� �FW,���+oX��-	��2�=��7�P�Y�D���Q��#��!�50��Z!*���t��հ��W�=�@H�`�.�� ��Ϙ���\��1�e	��	`j8�鎟��#��������n,J"��4/^}@54���ʈCƋ�´����b�¼Ěh�	j�U�m�ʥ0釩.P����(��bF�:��AK�FH�V�3fЀx
Ϩ��y}����>�g]G��d��c��y���>E�VD��F{n��^[�m@����m6��[�++Lh<r�cR	�F��`sJ� AC[,y��N�W"�uZ��NF6�T���V�	�@+'�8�HG��Y���uz�ZkÔ�@D�wN�0�ו�ZT2�i�B�|7�""�'�QY�n&ڜ#tT'�d�/,oe`;�גW�*XZ��10��$����QM���|]�4�K��إ�r�r�'i lL��^��$s-� K� ݞ�И�6�6�/Ե��ٮhv����c*=N�r�g�VbI�eT�m�D2L�es��ǋJ)j^}A���&~��دM�YN�,��r���D+��M�t���_�"�c�`��۝m��*P�C�����P��g��TP���k-ġ��M�}��dF)vq��Ңe9�+��vAŢ��6I���GtB���Af�Y2��1��۰5m)k}�����;�
4N�Y�I
��}z僃��X���,�\�iNt�X���l*����?`�Iz	��Y�;��h�y�>-�4	��~\�#�Ϲ�镯�����1��0�	�R�-��j��D��>뚙���P>
�,��ۭ�GfɀRA3�I�Ո�^�<5�3�1zV�0�2���t@�I��eY�(F���r8��(�@�]�H�2jא��%�b8r0U��'�]F�ȋJ?ӊ�]�ne1�g�!(�D���n�s����¡�UvM�I߃\	:���<r��#�A ��!�Rt�iolu�c�2Z�g��؟m���s�K}bT���<�0����[nb�0~�~��gc]�ߋAA�{��D``�h�T�G�"�	�^<�s��;Y_##o���\�����h���{�R~����ܪ�EKF;0��+�q?�Y)�յYw`�>JL����?O�Qz��tːܘF�Q���F�ͩvJ
>��!�Q!l}]��w�1E�>�9 ���|7��6��j������N9^T���QD����ɒ�A|=z��x�FT�����c*�v�}�ph�Q ���C��x0Sz>�LH��Ȁg�
bk֏	a�$W�GBb�)O��eV(���=h�
��
�"F��j|S��f�^�29��M���	$�oW�%٤�ם}�c�ڇLٙ�f�Ђjh��=i9������b��ˁ�t!\zc�H��%�f:A�5 .K<W��$����NY�[3�k�
�����ę-4v=(!N��!��ɇ�$���Є�Or�E�'�g3�=�SrŅ}k��J�������#�W�����qF��7'|���Rm�.Z��ArtNC�F������1W�=$}p�O��+ɜ��6x�Ƅ���ȶ�e;��ߺ��ֹ����*�F�0ft�xj�4�����b.�jFD�G��
c�����4w�&{��:	�l�Cf��]9F�J�4Q>���]GAB
`��+,�%���;�E�v�˕��*u�o�˩�>p[������n���~�
�4 �P�sqj��~��i�X��h%���a�)��-ڡ��j8܋4ϣ\G��GV�"L�:(�I@ý�Vo��ƀA	䙐�����e��I%i�9��0�0�emb��lR��*OqAr��u0�Z[u'�+��[#g�?��vP	.�H�<²ZD�u��6s)5��W�hb,�5���"z5vg�Q�:^�#lľ�1��L�!c����'��̝�y6A�06R|H���ó���
���Ðא/WG;��=��T_��v����y��wX�)Y���T�uX��g����7PaDe]��h�o��T������H-
8.�$��gg���5�-��&p�x�-˗�ڄʢ1Y�ʂx�SZ���'��I�8i��(��Ƞ�)!�����K��;�6�~�a�ΕD:�J��ie=��3��"���^�J*Ɔ21
,́2#��e��Cop���PD�*-b�Ɋ"�SY�
��a�[f��1�P{�ې�F��d`	�AV�}�iQ����{�I��ڮ�T���`i%T�Y��3=:��R9z�p�l�6��y���M�2Q�POX
l(��,�M��(i1u��n�&�9��&'̭2�f�8B&�بa���wЇ!J���ºE�p!%�L
��C0��"�-sx�pȊD��k|lT�o� ~s|hh)I����)G���^�&p�p='�R�OC�k�2b1a�$۰VQa?�ܡ��`$aG��
b%8�g���ڥ{t��X%B�B�V�te�p�����Z�k���~?�I2cu]���^֏9�uTEە����35��葼nq��g�V.�s�OE���g$�g���	KG�TZ-���y�Y�dZ+�s�\4*�\�Ӄ�	]�yr� .�1��:������I�x)7���쀉Cz��L+C�Ҽ�������#��z��}���lbz@��n�9W\�����=	�r,��e�U���.
Է�a��05���<�Q9Ԛ���p.t[��f�d$�<Os��۽!w��U�q��4��&��j����؆a�o�#&��9�_��[ͽ53�N�(kN�&���_&�OC�����	��QP	î���q�P��O#��CbrL��1�ֈ�Ftm�LD�`����c|t�z:)\�G,ܰ��T_1��������Ƒ=�)%R�!�1�0�5Z�á)v0��Yɠ&Z�1�N�sEi�p,�H�f��rf0��嫺1��p��iD�)|z�@;�r���ظ��9��� T��-:�0�FAb� *	�,�w���H���y�m�tv:��=��z�h���y^��H�Gx��m�*��`��j9!V��4T��WL�&$+�E�e��Q��N�G�`��~��m(L�xtABJ��7�����U�EЈ��O�/�S�f�Qv�0�02bd%�+ׇ�A'$�r2���i?�(�rg	M� ~�I�"y H�@#�&��"	`��{�H���ay�(��Ã�+�D�a[� o n��:��������L�b;�&�'Չ�/U�m��:�[ R� ,���|�Dy�C�P��0T1*�q6N�d��@�d�����
4�ĄԔC%U�� ��x_�C��ӈ�|�dj͏C	�zN��D*]S�&����t��s�r��M�j�]�H�����qb2;�T�M����k�I?$x��a-Y��8#�I|�$���镑K֠)Te�Ҽ�0'��$�W	8��J������dJ<�\�7`]_ͻc��?�k�6���TȒ�u��ؑ� &%��S��+�npR��Y�� N�{&��5��w2 󎣃��	[r���Q�^��������i�eG
G��#Bh~؃c#��Cw�^��ي������RP���x٠�(�Z'q�Y��<JJN($T�hh)�;s��,�`(�VD�똩���r�#Jģ�ͤ��p�}�n
3�Qua?K��HB4��
s�YK�d�s�����3������,�@�� �Q��B�����8'�+ͮ5G �:W�TB@7#��%�!�{&����;�ַ-�m��2Ǒ6�֜O�������A�x�yS��!�J<gTp �&'�d�f{���
��3��_��`��vw�	ԀcF8�ͦ����4n��k��b1L.8;���W�y¨6�ta���|�(u7���m%�3��H���'���z���
(�J%g(�p�BP
��9f@z��;��ƪ���F(u8%�'��aX}Ȣ��SIQB2Gt�3�rK������ٸ]�����J�Ԭ`��Ro��ݪ[g�X�9�G:!D�!�c���������;r�Rdבֿ���I����2Qt�.ȣ�~.*���0�ߢ*/М"e	��l��]�9=�A�v\�@Ʈ/$~�}e���Dڤ�@���(M&�B��I�pfm�)9�j�)��g�5<GS;!�L�)�-مa_6��1?��̈́��k��e*2��Z�񇙶-���4�x\�O�A��9�<BV��]}����ļ�����p�gqb�[���|�q;�F�.�`�b�V��΁�%����Иax!�)�d�2����ac˙TCbV��m�|#�~a�>պpO���z�v���a�#&:[�
Qu(3�=�c����*��U4lsV.E$��vޡ�i��'^X�݉S�D�Xf5���ι�]���l�(�7u��\k��T`,l���H�at�a�\��sr�P�&���"��\�T�d0�+��M�g�y�;�k51�&��ܻ�D�h����v�\� ��.�ң�{̡����B ���ż��,j�3T�[?UHQ��&�jtf}�P9�d�� ���eNm�b�]����U��"��s�)���:��|�<��Z5�mÞ���]H�μ��6
Z.���E/�h���B��� 67��A!# :1*�ׯ!�B���(脞�>aTPrvx����;��,����������cئ�:OZ��p�����<��(��5d�bG �A��C��8a{��A�h&c�ւ*��$t��� LL*�RQ-]�����7�J��-0���FbV�(^�ϲ��"���Npn��@����M�b*T�4l�����#[�l�x����N��P�CR�+EĩH�Y`jF���1U@E6"�/�\��e��A��Q��eU%�`�,����Xr������|�7]o�@C�Yr[�4�\���XÐ����I5é��c��6%�{IH7b� ��SiK��$�rg/��4��c����i<�l=?�܄���s1F�Ӳ|Z�z\P\�M:����hG5�}��7��X��(μ(6�Y��ߖ�o�1f={+b撡�W*r�4Ez���0�Fq7����|�4���"g�H���=jNڛ�o��H/MM�|k�+Ъ��e��e�ffl��o"/���G�っ�挶B����t�#\��G
�p��^(L���"�l�c'��9��TK)��5�Df�B���kҙK���,Yo""o�C�B%'���z��� d��|#���*�1�4�H2�Ys�;���-9[���Jrh�35v8���\J0mH@ �°,J���I�/J��������%`4�/DӁ/ԉ�S�3'����x�Uө�p���Q&���0�[��T��͙��A�X�.Hu��E6��2c~����e12�[c���Z�Py���K��G���xN��WnI.���~���T'G݂ʨ�P��1�QvƘ���"�6�R��u�V�ʻ�0wvM��e����s�.��H�50n����:߀}-�l�zH�E�frr�Dz�
��#K��L�L#q��<��$K��W1�Q�n���5�8����i�0���V�rU�E�F�S�B���&i���YH�G�Oy��i�4�(��;���X]7K�x�R'�����Z��W[���1= >E��TrO/X�KMN���T���>�R:CS	��δ8��4�{`� �J@V8j�a#�{8���c�n��[籁O�U���R����.9���1�j:� 2�2]�	�P�L�)L�U�9�8)��O �m��ڄ6B�(�2�6��6��L����q�.^*�o��0�h�T�p�����4���a_�8d�,��O�S`�<r:'N7s	��&%<(�L��A�BΑ�X(� �2"j�4ou���D�
����U)�s�\�+m�si�A���-�f+�yU�"�1t���Mv951����\����N�jGɮa�`��l4��Z��4�f��r;��G�98��E�%-(.�R.:G��-�+n˾pU�"	�.��l��ٟ��D���jvE֧��I&ɕ6��4����)��$��RQ_�J�"�D�ݒ�tՔ�K��%YX��><�E����I�5����-�ړu.k[�s��B��	RpK�@��\�X�9�-�K����N�VE9�W,�������Ii���678�t�?��\ ���Ne�1nR�E��$)�:������`�4E`K
'���!��*G��W� 6g���9bud����3���k���B)��(�dl��0%�+��\�����p)Rp�T#0��u��`�MF#�� X���Edх�eF<)�8�����	��ZJ��8!�Aɼ�2O�򗶹��8q�*�2�{2�1
��c:'��B��d er��,��(�."�!���n�|r@�Ͱ�$�ʤ"s�Au��䠙�9� \�t7� �i]Z�&�(�Δ�N��*:Db�墼V�1�)-��}��4��C������RI�N*������y��ͨ,&,�e�W�)X�#C8y�MiX;E��T5�?���R��&oi���O���`wN�G�7Lŗ����l�ۢ^��KV�)�'�ņ ��󵐖�t��J,9$�Z5�EO�t*����%H	"��d'�p�m�	��Ix5�8��:d�*�����U)xŁ�BV
5����c�l��%����W�$�NW���ڠ�$}����������4D+�;�?Si߁1/q�������Jq��dP5�����=t�v�i"yg+.�8Rpm�\�AԒ��$��0���ܰV��?��0���7�t|�y�K�:f?��A�䲙��:�ꐂ��y`��i�Tc���K`
�6#"c�9i�SoT
[�o���U�<c�}�#��e�A:��[���(R�L�j����ͨ2�3��.��$�q߄��)�\nW�� �-�klC�������6hB��<��:�,�ǳ�4���p�^�2�g�%Rt�Z*h붛���]�5���3*~R4i���%�����:~�
e]�豄���H2)�F�q�,�3vX~PŔ,y��m�l�̏�d��dTpr43����c���1�����Ft[)ߥ��.z��N��F�,�HI�E�%���F���Z�����+I'c-�u9l�W��B�ɍ�A&W���U��@�BW"����ձ�eq��k������Q�a{N1�u����
\$~���_���Q'�~�o/�#�yord� �d4y`=�n�����鞡;�R�C��7�#�u�>��4���d�JԢ�z�r��� B�0������ϙ��Q#��܎�I�'��+�����4������ȯ��K��M1w�3�
�

���Y� ��Ӽ�H5��-�ep$5��Ϝ'wD��Uz��Y!?Q\��k(��&�xS�32;�	�]�Zԛ�B6|��j/���Of}A���֬�]a� c>\����D�ɪ�"��3[��8���x~�a.�?��w�Z0�!��^�;	��{h��e#�t�Z�2�@����č�L3��q�N�P�z=A� .aֲ@�.$07�mKp�Az񐒉�Ӗ	gT�Q�ÙĽ�u�NO��;GG���ԫ�#�B�p��k���������cu�=��9>�n��?���ݝ���ݮ����/'��V��X�����p�wz]�;�`��}�������4����OG;?�>^�nw�腪6�N�a��x���u����kR�N�]S?��>xsl��A~R���n�����ãn���w�`�]�rgk��6���^���jwv͎�&m���{�������x�Z�v��a
�]�W��f�s�9:<�u[�A� ��vzV���阁 �0��P�s9{��p�꧃7�"`߻�PP]��}��:�y�m`K���f�+��àAgwW�w�`����T�{�vg��p�=��!����p��}F�g-.7�]��c1������.B��o`��%�����Q� ��D��,O� �b�hP��"�O�bj�`{�� ������O���
�٢l���%,d��+@(�mw�:?t{f���<��P������>�2��{�W<Z�@Q8c���1xp_#̍���]�s��R�����qGъ�ߗ]l}��@��lm�9���-����n��>����v�/����"��� B��9	nѫ7<|��
��z-Ǧ����zG��:�ow�:�<���	�F82�}��E�I���R��˼�31�p�!��7E>8�־�ǂ�(�b���%�Y��ҥ8D8@�0�d�K������^�Ύ����3A1�����h�:����S�d?PF�/⑳�
��#��@R/7�&������-��)z��}��k��%����k~שC �p�cZ���}Ve��A�w}H����pyrZ<$��3�śs�����҆xF�)�0���s���0P����:��!znM������~Y����n�I��U�b��N�2���	�!;tqk�b�{��D��D���{-��"f@�X3���~Qb����AI����H�����ʲ�E�$%����z�pfj��S�(�
r}����ƛ���9��ЧYу��Db o}/U�����UW�au��a"��{����^����{Ӽ7�r<����8o�ڣ�PJsO�����2|C�1%ӂ�����U?ݴ^�lZ� ��4oW��{A'�6Β='W�E}T�k�A������bK?-�⴫����'x)+x�"�q�Ez�va����F�?��k��G��X��9��,,Yd�ȇH}w>�N6������Y2k��Y[�{���u0t�n��&XD�i'ٿ��q�y�v�,M�j�N0r��2ʉ��J���5�44�ӏ���l��g\iS���a�T�����{�p���~'�~�X�C.�L0���9����j2��L�8��
�����ˇ-;\�>[�A�<�<l���7����$EK�sw��Cw! |�,�_M��H�Be^!��5�ނ��z7��/;�ީ����ض4SO������k�w��͎�~,�8ЂfdkP5� /N�57)K�XS��Y#���F4��ھ��_�:�t�~���[#�V@�
`]��W�n|S�+��7?^��q�eg�YI���Ѫ��Ɨ��K/)[Pc��H7�X	�|�r�ľK��ȝ\	�.� ���ǌ�Y�+I�㲿�׉w����"�x%h��<n;����b��7sdpm��{t�c.%� ���q+�]��Y�0J(
�,�C7=L�XBSy��D�tr~վ<�j����ɨu>��t~���3H��ng{����kkkϞ<Q��Ϟҿk�7�<�x��[��x����'߮�D��?��Sk_h=��Y
,%O����p��{ތ2����<Po���(8�Ǟ(�!�Vnu�v�	�w������D-�QN2���$T��@��$�$J.b�O��� ����;�Ӓ�6B����Qgd�`�Z��"p�:dX�~���$;��jH	�8�	���=
N<�i�)�W�^,�1)ڸcP��#s5OO2O洝-����W�i��xG�����?E�;�Ф�P%�j
���q[�у3�-���:�l5��3,+CՋ�:���ph�mqbJ�z)eI�9� >�H#�#	5��_g���Q:��Z���G��~�;�g3)D%N�b5K��l���L���%H�]`pC���,���8~�SC_</�YP��������X���Cn^uZ� �j� _��KTbiȧ�'��������_X�q;�g8
s����4�Scl��F�� ��	�U�7͢i���w��K��2h9�)=x 
�t6)��� ���R��h���uY2:����8���X[X��#+�e��������	 �������.?H	~��m����=���՞����I�vy2�<6�ֿm��7���?������?(�o�+�l���*~Z��Z���F��u�6) Ck9�l�Ďú�Xwua�79?']^����_࿧����ݓ��^��_����M��}������ssl�{}��|�>�o��͡|�p�%�h�WZ����VI���|՗w18yW�C�*~�F+����\mkJ�R{����U�h�J�`�e?��	Ձ�Ƈ s�/��%�'W��E�lduC���o�eSx
tTMA���),0�/��sx-�3`h�>�
@�}Rv0 \��
9���L���T
T8_����đ�:�#����`S�@Gx��zmٌ�rɌ�a��l�W��_-�4�I}�pR�[��fŴ�˥���:-٭0�j�k���`�/��K@��t7=#>�������F�2� �
gJ��S��.^)��G���w���~��_���#!L\�^bFX�s��,lXF�ރ�ޏ�s?R�Z��TY?�T�Oh�K�$�!(�����*��J�����&��l�����x�+�ˏ��r��H�Kh,<�?4�6���N��6�>�\{z;yd���Z�ɽ�~�en�m�.���\��Y�/��&�aQ��twؤJ���\Vm~^a�x�!ݟ��{�Ü!��xM��o�l-��MN�6`����-dY_���}���؄3�!�KG���_5������^o��7��ã��7[�s�+��`(�[��R�jǗ����z�qk�&�����>�S�m��^8�ڿ�N��u�~����������#���v�O^��~���ЅC
_C��k�؅ݶ��n�1Ŝ��P����2��qov��{-��U����/�M��np��;ތ ,��Mn�KZ#@/,� �7��9O)K�~k�y��h�������6C�N���:ov�Oܑ
�.���
yRF
��ѩF����z�m������J�O�Oؘ0���%�LA����:�Ǹ��6�����A��}9�>�g鼏�t�� �����lXp�K�������Vd���i�OZ(6� �!4݁ҳ,�p�y�0����Yo�5��3l���C\��(?�O�qKj���6�'�o �����/~�okŰ8l3�O��D?X��G�p~�
S��F�t�)��3 �4��A�Ie[4^��l�߱@����~�!H(Y-,�n�9���<d/&�T�w@6y��z�M�Ei
�բ6�ᾳ
�K����ނ�b#q2�u���Um�nv])�VS�<���@)j�b#�\��-��m�T��|�$H&꟧��=::8Dft�tК*{� �;�ƃo���s"���G/j-�l���Q)�l�`��Kߜ�wp���p�>|���������'�������H_4���q��W��ڽ��L���<�s�H�z1[?�u2� w>�&R�3�����X��ڪ�e��QK�	�ʡp"�[���#��O9L�1�
a��U��Ͻ&��7`�M�`X�xѕ�ۢ�͝��m/�*I6 TM���\_rK�ug�y� _htLF�N�?�����啱k<�.-4v�7ܦ�c=�@Ŗ+1���,�G�RTl\��o^��r{n�T����i7E�U��p.g�S�3ֶ0�����,�6��20x+��s�
�;�z�l�kqB7�h>w�v��o�&?c�gqsׄ����ӹ�e�l5t��"AkhnC��K!�ÉH�50�}`�G�"��X|�l)��%\VX:�V|�!T��ڎ��`[� 6�?�S�lhɷ;�A4.|Qh��"B�}�n�0'�z���v�Ix`k�5��̭lцD�*�\>-�T.�^���3�
M�A���G_����!}������*S�+�l�	�?� ^�'RV@U� N���0gS6s��k�A]6�:��Lޞ��Ps��V?���&TJ��eQ����vS[:��h�b����t8�*�/�H,�X�S����v���K���=���0��W�ΐ����0��3��Y���.��
L<<F�AG��<M��y�V.��&���wL��ϩ�p�-hs�$@��Vioű+O�e������Pc?�P����):p�2?1S�v�T_Ȑ���U��l,G+
Kc�i��$AS����Ì�s�o�i�Lu^�*+�H�F�JDrŝ:��=s��Uo53.����0�.���fksV��J��4�]#nS�N�Z��S�����r��u��
�p��橫|R<L��??gj�y�EM�x�CC*��D�,��*�����E.\�n��jI��*O�mx�%W�E��ˤ"�S����3$w;�c�����"��9V85�^1��ea؋\}����ƍ|�z�s����3K��+c`����ZC0�[-�m>-��I��(ו>P�]@wgF\��];�B����X7��@Ga����Ytƨ�H_yˮWȂ��O����鄃�[�{J��K�j'3L��� ���;�߰zRl�O5���<h*�K��/EU��N�
�V�٥[�S�J�xw{�!?��b�M|q���s"7Y���eAhP!�pnp��I���JG0��7	���f�J>���a����P�"��w���ɓB�?��LTu��{^m7>���.G��)+�lG�T�����}�z�8���{�}y��'K❒{�;��=��^�I��^/��X5"eǙ�<��8�q~�ة@���EV�nbv�2n�BP�����uew��p�Q�u�X�z*��l����/��+w���O�c68��)�	�UU�ak�1�"
$?<a(p"�/A�V��1�ٍ��!s�A��[�hhޡ��T���d���~h��d���c�5>Z�8Pr����2ZަJ��;��x��1��Dy�3+uYAe�r���`9|��xvabr�ٷSﾱ�P��' �{���,��!��ʮ�}
�<���Ǜ/��w����{e<�a<U���@��+�3���+>���GzY ��Y�Gǅ�Y����՗0~�F�� b�YWJ���;�9\ԯ�M�b�x�� hr�w0��e3�ˊo����E���d�;�������>�k������:�a�[,r67�gy*�0+-�҇�GỾǪ�]��a!%��Mz�$#��Z��(�m��c`���N��xƔ`��&�<�T���3+9�g�ߨ�KB�R��=��6�t+���M?��Bݠ��'EV�Ϩ���BrO&�5��g;�~K�{B!���ZW�$��)��r�v����]x�PW�?�V��4.D��k�\(�N��qs
H���`r[G�>���]���B�O���i�fG� ���ln4�nJ�P�I��)�ٜA�3K�c��ef5�px�&� B<s!�`BƜ���\
�9��-�ͻ$X��v������M�U���/gc�؋>��?
����|��.�.���4���$f������������~�J��F�!�#�I&E��Fl� w�D�ŗZa�4~���&n�
d
��EE�51"�At��N�r���"`���h�������?2�mC�"���R�lz�>�Q��WKa����I����{�Z��6��">7��;b��1���Ի
2?m
�c�/��3���*&�������';�7�@p���>�
Ϸ��?�W����T���~��ĊԳ=�t�b��)}J*�x���73w����$ܚ-���^����'~%A�B�5}H����p
�/e�N�cq)N9*�+Z;}&c��W�aF6`NL��_D�
7��{��;u���!�U\�	2.J<��*�ӜG�k8z�$8�N���_��f�|��%hۜi~6iQ7	)>��M��9:Ma���ۻG���?jL�D�� S�`0�) bk����H���%�	b#o��v�=-�a��l�6�M��vH��בK�ZP�@�t&UH�a�V\����Tcϙ��@h��x� (��-	1�������%^1�R<����+���Y�gq���h������ds@��:kQF��u�Ԡ��ֳ�Z���N��ϲS(���L�؎EZ��3����>i�균�3:q�����
1SyWxT:ךr3	8T]+�-�17k�<N������%I����l�}�q��Y�5��ch��Gխ���*R-p��1���`J��s�j׻�(Oy�ƶ�ڿT�!{�:����Y?��ܥBw��J|�D�?��fxb�G����Z���e���_ER��M��iW�ۺ�)J�l�ۆ�V]�%���]�ߛ����<���j�tl��mHXO�N���2�\ٳ�ک�����J(iC� �64�}������b��.��!���z��;mM3lb�uY�\����V�SĶ�}���vW�M�R5��̎�9ă����ˮ��=Cǚ�F:�i�lئGdh����#vl�0\�m:���Y �.�e���A)�3F:W�t_k+0᝶B ��o\���UƧx�#{�k���z����(�цE3t�C��3<�Rl�p]���m���86t�mڪ�z���*���[ܵ]EQT��mC�̶m�m�ud��t::���:my�=��(��h{n��XĀ��n�R�|W�5�4#��$�PUӰ۾��jېu��z[�]�-������ga�V�|ו}�U]O�5�@7?u˴�m[�=ߵ�"(���F[Qۃ)6TS'�\��*ۦ���m:�:��b���n��!�NG�}E7��+f��(�H[E��3\���a0���8�f�DsmUn;��Z�����ɹ%��� ������=X"�%�N<˲}ہͤ�窰�J�M a#[@6`fe(`���d�Pt��`۪��n�o���V�l�]C�l���e�my0q����N���4�U�5U#D���/�m���S�df���eixV�amu8N�cwڎ�i�
,<Qa�[�U��D�NM�Z�tJ���Q]�R`HmUq����[vyrP�������@�����*RY��k�!�:���'����J�[զ�v���\@BXǑ-�����Qa�(m�BK:� ��4�>D0��1`��i��L�Vݶ����p=K��uU��LI\_��=5:�ӆ�V�ny�nv,��1��b���9��wd�-����9��b� �����$v�Q�Ա� ~v �3΅s�P�(v�ok�$��L��:
u�cێ�ۮ�*��s�U볋�>*D��ǻ0�� ��=�]Ɉj����iHL[AvÐ�R���gf%��'�#��:�2�/�Bt[��f[�� ��� Q�-�@�|�����R���:6�6����d�����Niwd��ڲ%�h�t^���a��k�7��j[:��6��jZ��jH�K+Z_x8�DD{�э ��
���m�iDm�U��`���� EVK6�����<�\�5�D^�j�[�l8R�*�H�
Đͬ��Y�OE�,�E:�y�i�
�- ��Id8hN�i���d'��f��aQ=�*�@<Oi�~��ڰM��褨��I���6N|ݵ�=S ��{�&�ߎ�o+E�3�"|�
��or�tH�L\�kOB8��f�+��_{��	��v��KFܗu�c��| 0?�<bUJ�g���z���&ėe�S� ���7����2��(C��n���vj�Cr<������k�w� %��p�������R��
{8s����������©���x�
3׌o�������B�����1���e*�+��jx����_�q������d�e����G�d��]��_�4���YEz|ME������ā�&>D� ���͂h�ǩ?K=� ���v����d�^��hj�!��κ,�*���*r���`]�]�Od�N�k��0��6Y�(���M��E�Gkz.=H�P@^�݋�-��ǻr�������q���it�є��҆/4�0���v�p6�x��,���V΢n"'��=�)f3Flt�e��1��$�jC`�h�`����������^Ck�Y�"��XC�a�(�`T��EN��<��P��Z��	���¥v�{�˹�����1yQ���OmH�Gd:���-v�O����Shܡ<�E�ƴ�v�Ĕ0���t���θ�"� Qp�k�r9s��dm�o�1�q����u��%	�e?�£����s���o�����e�E}�J����V��9��NF��6��73V����A
�`�)�Dͫ 
J�e�190��`�rc�>�37L�ez
]˨����h�!X���r���0�#BaU�� �N��#Z-�ۼh�K�m�xh1EujhѢ+Y��I�V/�f�W:�DxE��"<��ܜ�ʕ`�s�c
x;�4�k��ˈ�gwH�*K[B+��T*����}%��-���E�L���X�T��k������-�J �d����g����c?kT��Z|
�y�>��:���	^$8��\��8V��{ȉ��r�"�n�?z����q�V�7i���8�?��|�y�}����8�L�C:�)ݵ����?�xђ~e�
c���o�Z\��N��5e���_�n���
8]�b�=������uZ:��r �n� su�Z�
eOJ�
F�%oZ2p�.�zd�?q߼ ��]A-9����I6������rR�Xb�`��u'��ī�Y��w���M��/\[9���D�� ��� 耓2��=!���`��3~����e�Q����7Un�2B���Sw��lP��xm�t��֟kF&c��Fm3�AU2��d�K������O�yo��+�^�y��ԸЬajw��$q�/)<��ٙ�p�����~���yk<�>���q.�7����l�����������V+�{�����v���D}�6���K�J�&5���.�V��?���pɟ?������n�;���_��g�Ć��R�W�nlno�N|�"�5f�8�O�u�ׁ�|��|���MbOr����8���{n�n糚���/Ӻ���`ץ�`�R:�k|1�z�+���B!gn)�jZ�$.)P���PP�By�%�?�[^(4�(���4��D+�s;�.B�](��BH�� S,$`�H�8�9�M�8��O�}�B�|b��h����I�� �RS�|�ш�@7G#�	��m�Kuw�M}ռ����:�;S�lob��vbb/J��zT�ٍ#��,���D�
�zO,�Aoǽc�q����=�49����k9���ۄ}��V�ɬ@�Kj=X��X�5jv�F!Ƅj>�ι�(�v�Y$�k{�koo�x��%aa{$}�\nR����|OQ29�1����h�d�,��?�Ǚ}N-�ъzR��!([X=g�a6I3�9�$*����|�&n1k��:�Yuj�.T�� �S(��`������ZƊ�+mY�����v>B���eܭ�pU�<���FuQ��˒�?Ǔc�</������<�|t�·jɵ��k����ݙ���XL�j��mc���jz��a��ah�\���"U��e: ���7x,:I�n������6���u��5��$�1sف�G�l,q�w�2�gXKp�E��������2��ΘE���n���:����Y��$=��^n�烲�u��g$�,�WAG&���y�$Sg����%�4X�p=27�T�A2(�.��?۽���s��w�מ凛�+���"�_�YG�ݔ+����J�[���������^ΪW��~������埿���ﻍk����k�f���)k���*Rj|m�|�5Y���_E�y鹗6n���fV뿊���s?m�b����+I7F�����_W��5i�������G�+���������O��F�(-Ş�P�cO��	C_�6�C��+����w3ͬ�C�&d��.U�(�<Ɔ�S�,��7��>�7��PWMf���<���6P�*q��4��e�l�a=�if��&�RW�ד�KR<�:���MV],%IͲ���BB0�۝���#|��M�i�Jk�d����xb�lR%��zu2;��u��l��~��^[X�ҍ���r�}�m�翮���H�U���W�
>�믿.��(��W��V���i�nm,�������Gou��ʪV��_Iz�o�@����.���5��-����̃`�Nxt�G�GW�
>��,���.�(�0Ȣ�K�fg�BF#2�<9�)s|z�%dpn���h޻ޒ�C|�{���������F�P�sn%���pʬ��gs�	��f��f��-���	4a,g1�|=m��*�6i�T�-�P���ܴ\lg�-���B�[
r�e��b�2��+��{��c��I��ݣכ��VYnZ
��B)���._֪��#$(�Ba��A�?�9�@V�y���8:�E�b���f�a��:�%s�o_���gO�9�p1?>�Y�?R���`<�z^b)6�q9$08yɄ� <�B�G��y^��GF~o8o�L#�n@d慘	��l�������Ν4�(�_j4&��l"dN�	6GB��x[.���jd�k�E�C�?K����f���YVe���T�|�o�?d��Yh���h�b�C�6ZcL%�xC2��۶Cio{�%�NS��H�q.��+��(�f�|X��O�M���{�ԗN�񘂣M�3 ~f�gh� ���!�.��HP��J���%��v�x�L�p�yAB�6�3~P��`�%��!�\<��Lx\��`������}5�I�Q[�|9�P�G��vC��2� ���@'f�6�ycw쑏ƌ>� ;:��^����P�S�q�s��6��xCr��x��������3��G��� ���h�����C��q�ۤ,3
&�/l����o��}�+L���v�Gq[3��ܐ�����i(��÷�φ���oB��������]�����@iON['�翼\z�?�p�s����h����ι�v$O�^}�t�c�p86t�mo<y���ˎMfý��j�xC@�0�L���P��Fnfi�	��!bm��	�>@
�,8�-��1
���d�'�{mH��i�p��d���d�O�[�I��Z�"��̞���>�~V}a�q�i6��_�!�D��q&�7؂/�D���Fiď?}�m)�^O^���w?�@.f?~$�����?�}�~[.�흓��F?���������weL;{�W�����΋��/����V���G?���ɌF�R4�^I%���l���A� o2 �tEʏ�K4l`/�K�Um 3�]Y�b
{��:�"0F�p��2S���<@��x�a��9]��>j����e�-u#��s>я^���>�}$�����O~�b���o0-�+
0�����s'*v߃�M�H3�X^��m�U��u��	Of�b/-T~@�p�$�gv�4KP�6$�[�=���5�ݩ��?�b&�����?ݪ�?�$U�b���A�;��\��u���ꐾ����)��(vq���7g�<}�x�j:{	g���xCyp?0"�8�&�g~��X�D=L�-����@��:��a�.}27T�Н��"{����!EI�`a0�YrpF!�1L���)9����S2��*�Q����Jք�4���kJ�T~b؁r�:���P8A��1*i�!����t��o�V�֥ݦePA��1f�s>��<�=��H�%��٭��I�C��E�]�[��|y���b��6զ���
/�x��y��أ[�G鼣�9 J�����S��B?���r���%�t~�.9��aW����U�v'W����*�f沏v��-͹����٭��|J����^��<��/[�F�i��8�*��cl������hJʽ|�.S�?�()u�v;S*:�Z��!�)�K ���n��Ƥ,
��3�d/�]���(Bo�L_=����?���;>8ڹ!�}8 �~��ChN����n����[���E�u�'�A����{����A^p%)}�L���Z���}L`��K�+�z&We�j6Wc�Z]��`g��+��!�k�C�?�H�?�G���f����T�b���ߜ���T����c�0��~�L�[e�v�<�����7}�R����&^���S_3峆����fԲ�MeB)q �#���A��B�����P��|tP��E��0��B*�ZTO�Od����q9��Do�ǯ�!�I�=���kH��E�:C���b9OJc�2�	C�쾚�� ��x�aq��{���&�~��KTɍ�![*�M˥�-�Ks��.+��y�f>{�U�N�{�=m��,{Z�f;)Q�����z�KUz�R+v�� �27����"X�A�J~�敀�8̂��9�:pL�&��c82\�a�_�����5��;i /��UE7R��@�_Q���%����>_�������v��2�yU`�Td�o�<G,�T��v�+:�*�t��!1�d����:�I��_�M�G=�>7����B�o]N��?E���V���_�s��/�	��. �i�4�=��>�a3��?�G�deX���c�*d��>��}����hJ�c8|Fx3��!4q�'WȤSq$Quw�>V�q�{w��6�>\qws׽�Zl����`�_��E�?H8^�B�II��E D������G^L�K�&�yz�CU�w���?��HӇ~|YTv��C�r�!>�o讨���J��~ �a�ܳ��f��ߊ�����U�߫I���C�6��-���v8��)j_�۷=���Ig�!|�$ۗ��/Ec.����ؽ�sR�����V��qJ�EP�8pf�N��Y���#�.���G��x��1�f�cݢ���(�%�B��tܔ��s�5^�"��gJhn��ZZFM{tţ��łG;�EX������ZLW��J��̢!����Ud��O�3�[�/z��	ͼ��w��ˀ�7�8O����6Ha�1G)�V'�!W���<�Ը?�7��՟0]�z�$��Z&�w��Wt�S��İx�R�$�hh��6^��e�x�Q�������ԕ����?���V�*��w���*��6^�����?U���e��-�?����)X�o���]���_��Q1 P���"�_�JY�B�"���������kz���$U�?�p����	>�{G+���Y�n;+�xκr�<�m�	�B��J�xp��VZF�����`Y9B����k��˼�X*P��㜙5�(�T/��PJ�fz����A����+A�%���
=ƅB���lJ�ݣ��Q�����>�rD"]!H�@���L�=$�R�d�oX��ҷ����~�,�H����������T��}^��R��F��N�o��aNT��:t(�W uw��
�J�9T�w�c�A�� ��PI��x����*������޻���/q0�G5�P��~�8����#�I^��0��'O�ϔ���wי�
Jϕꛍ_��'�ѩC��<�q!)2�qB`�cIy�þ�
=}�|2 R[��a]º��J�`�=�f�|4Y�o��%����lh@�LJ���P�.��m����U��i�پ��`c��"�u�EqȰ�x [Lh���^0�0�w�/u�:���7c��{�u��J��t��0O�1�H����|�a#��7���/Ҝj�Y�X-�/wZҕd��jV���H��+��)��c����>}w'��`Z�NK�W�FߔǛ���f��j�����x���r�6�ۚ[�ʊ�w����Z^��.O�4�H�����W�����J��!��W��՛��;z���j��/��b�5'���1��a&���ɒ�X��U��*Ҳ��<˷;����w#��a�=<z��C�5��<��1�B�5`�j<���MY�1xs��(���hg����~#݃�Ԭ1�)�{�:����8�Oͣsާ,M]���e�=]�>x���O#��KuJJ��^�Y`�6W��
�f��b��֟º�'I�ų=��t 1��8z���/��DC��,+�gq�0�������	�մ>���7���+^�v�֓�c���n=� �Qm2��1d�[�sQ��)�m-7����\(��g�������͗�+IV#_�OgZ�M:?��q����S֜�8cPP���w{���JX�S6޽�s:�T�yOc)^�tNX�t>����""df^���3�/l�t~�Jg�[��%qU_��^~*��̿��m7��Q4���T�?W���?�����_e��@���.��%��}	���G}��?������~�*�՝���k3�UZz*�r��v��������P@���Zu���T���Y�o�&���!�V�G�qh��aN����A*!�J!oZ	y@!�d��&%�q��������CLd��&tF�Kՠo$��~�"_y��r��/]���~W��b����/�����q��[�} #8pcR�hy�-/����0�������oNt���?ZE܁�\���B�WU���U��+I���"�D��l�Ϭ��0�����5��A�3�G�V0�O��rfEEwЀ�d�1�2M��,N�4<�=�`�6}��E�|!0�h��QCۡ֘�7������CL���d\�?,T����wS{M��6����l�'�������5\qf��O�6D$!="�Xk �艋�pȉ}>���ITy0�C�<�����-�,��s^��93�`sb D܅�;����#G�����Ma�t�xdD�+ �=�Հ�>y]:��Yp�� $pO"@5��������q���tS.u؈舊�����45`���&��ܐ'��`�Í�S8l$����JSm�u��(�a�M��7۲���?�� �w���Y��rT����G�������I�H�����!�\<
�Q�H߽1�m\a�`�����7� ���o��ȳ�2�'E�L�?_��_
%�c���-������$,����)�oa�E�̊�_E���\��9���%�8p�5$����^������e����߆�x�������H�!�����#�gɕ��,�Y4��+hc��/OY��	�f���R�w��ȁ3���d
����mݤ͛!
�e �x)ټK7hl8>�GC�a�^C�����X�Nf�������:��`����k�vysے��q(u�����h���7�_�ܛ���AZ��{w
���%������{GZһW����ȸ&@���gmm����F�����x��l+lأɉ����gg�3�T׋�x�>���ܱ#aq@�L����q�����.�!B�#&x\�@	4�L8={d<�N/Е����{�m\��~��3��C(�] �@b4�b9#�>�{R�͆��$���`5<�6����7�q���{�W	�C���tX�aY�	��m���!ߨ�1`L熙��k�1%���y��l
�E:3�K7�G�Q*���[#�1��Vu+��da�&8���!���s��;�ǺY?��co��|�I����G>rv�� e�%8T����c
�7��	ـ��G��z��5���8Z�M
`6;&�n��j��9��� �`������ �9Ɏ�$Q:<��� }�:�g��|��۠����m��;a5��B�|J���J�^��,/���?�e�����K15E��V�*���rp���w��;S�Hm�+5���u'��_�p�Z�b�;H����3����}?`΂�n�-�BЄ�7�%d4��=a4t� �UE��;晄��WGoi�L.����<�Y���('�ttI�C��N�_m��d�/���ڗ�m���#�M�����s��q�
(�`a� ���SH}I7����4�%W��i;�-�i'��@��v�q�"��@�����ĝ�_�59�M˂�߰�:�W��F-9ͬ������?p.`��U�qN����&�4g��G��b>S&.���򾈚5��S����s�?.��h�B�/�����?����"U�_E�+�_���7�gI��\6�O����*��j*�f�&���\��ZI�֨��D��`G}�eE��N/�ʒ��h$1�/>5�����<k.q а,)�9��鑀����@E� 
O�F$�|��'5���Lm@��{"}O������VjK�����[ګ��tv�uu][�׍u�z󴻿u��zg�x��L�V2E�J���܉�
N̢��ڧR�V�R���]�B��?d�ڗ��"��L�]7M��+V����to�� �}E��������W2��Y^R�#)�N��˝�l5�<Ϩ4�<��f��(��^sOݨ��$ƀ�K�Ǚ�b8� F����YL�1ps��-Ŵ!���$��d6�jZ!�*׭��Ҟ>kJ��؃Tj]L�(`��P�
u��K�FF���LijGF�e��72�ÙH�RkN[�������m��W(|V������aYn�BZG�ۍ �����ꋚ���D�ҙ=�٣+����b���搃����+Q��������6a�u18 �#��񬽳�Q���"��6�Memӏ�4�)�~�$�����t�!RCU]�����K��j�!��-<l�v>��_�[���;��?���
�����"�ŏ�g$�E=�v5Y�A3cϞz�h2���p�q�q@��;�i0��1s��)⽸��Fѐ���S�*����e�\���!-���ZF�������Q��$U�?�=b��"�!r���س<�G�8����]J@��4";p�ir1�c��&^���r�f�Jlɗ�	#��	Ά�n룑A{��B�f�V]J�&08#ih*�lB���	s7d����`6�q;-�	�/��K���0����v�:�Ɛ����p��
O$2h�,KMt)۟L��&k���d��1)G�>�K���}nG�A�e4�a�K�=��_����֛�����_6�w�A*`��0�0B��9��6��v�Y,w�H`�r���8�o�g�5��=�p�@���	�L
�}%@�C	�����0��H8:@g{=�i\Ͼ�	��#�еĕ���ŝie�3���~|s�[��o��d�U�.F3�`v[gC��{JD�/_����
4em��7�n���� �,����E�7�t)ќl���焒�ym�׺Ԯ�v#z�u<���aq=�P��`i;�4�J�M/�����Pb���Җ���TJ����}uM}����9nN���X��ˊ����5S3���Y��+I��������vD�	���V�e���JSf����jg�hw�Zog�������7�@�wz������?3b�{s��6��=Z��`��/���K�iZ��-CI�?�)������_E�������E����'����q�퐾��j9�CY��5o��{���i�_�F��T���bK(n�H:~�M�1���@�˼�G���(&�M��fc�Q�=l2�nu�ڣYbg�z�aO鮽����������k.r�o�Z\��N��5����_�n�K;s��px�S����;����r���N��ȡ�/�z�gr�P����P`4��%'�r�Gv�S�������c!0��!;�5�l:����夐�������N[�W��pY��{�,or{��_��J� v~��� `� `lQɕL�pB>Mp�}�gg&�*��d�n"��ּr�2J���Sw��lP
�xm�����ǼEJ�m���&ŗ:5��^:������$yA��4`�'�n�)	;�_%p�3~;�dX�y���X%��k����v�ZR�$.$l���~��T�.|mB�%�_�R���� 7S
wT��B����lP�^Gs%�D(�^]�m´<��̔�I?���i����.!Aɬ&ݵ�h��d@���岫�>ދ����+���$΂���2��gwK�n�G�gz&'���5��I��M�`L��,
��`����E�$+dYe��/t��s�L��c��2)�$�#����gu|�f�W#w2�V'7�N�[�>%�����P�`v�M�c�à�v>� ��v���?g��)f���iw�*5�\8t�H],%�yT�\ N!&.47@!�P�$T�I8;���A'W��3{zw�a�
a���x�4�^���I��0�e�t��XҚ\x��}���d��^5���p|�Wѹ����� �r��Xt����_E��V��c�V��k�ͽ`2|�j��L݋?|��W鮩\��
FK�^��U!�/~����U�%��������-^��W���E��6x��׺]��g��X��~x� -q�w��gX��ɐl�U��UǼp��ؽ�3f�����Ш�K���U�ǔ�#��%xF(������������C	� c�����L�eRg�I��2� ��'sC0���Q�J�K���vogG���n�k��,?�T��������7{����������������H�/��9�����rv� y)�i�G������N�R��O�.�Ȃ�_�����
���ejZu��"U�?��_@�+�;� ���� 	��L�@���
��̖��XO�ѧ���;�([����Q�]�{p�q������Z�o� d.�߼q�|���9���C`n��;�۽~b٭����ީ�Y���j�����%�g�����?gC��dn�`��rr��]�Ҕ0���/Ϲ��."����d�G���K�1��(V���R����J�c�ɮ�!=Y�a電J������^	=�y� @�*dG� ~`E2�X$���eX�8����-��)�7��D����<��0�u�6�����<X$���E��u�#�j��!%�5!�7��t`�c�/pl1��KO�p��%��b�\K�h+G q�i��p�υ�>���&~U�R��T�*U�JU�R��T�*U�JU�R��T�*U�JU�R��T�*U�JU�R��T�*U�JU��7��?��|� � 