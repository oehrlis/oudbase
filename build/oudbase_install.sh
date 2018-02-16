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
SCRIPT_NAME=$(basename $0)                             # Basename of the script
SCRIPT_FQN=$(readlink -f $0)                           # Full qualified script name
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
        if [ ! $(grep -q "^$i" ${ETC_CORE}/${OUD_CORE_CONFIG}) ]; then
            DoMsg "INFO : update customization for $i (${!variable})"
            sed -i "s/^$i.*/$i=${!variable}/" ${ETC_CORE}/${OUD_CORE_CONFIG}
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
    echo "alias oud=\". \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh\""  >>"${PROFILE}"
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
    DoMsg "alias oud=\". \${OUD_BASE}/{DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh\""
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
� ��Z �}]sI���������s��Ź�,	.�� H�pڅH�]~A�vN��@�Ѝ�n��H���#�h����_����~�� gfUuW� � %͠f$�����������2�l���S�\���`��&��\��Eb��j�R���6��\�ll�?b��0Lc?0=h��Z�A���	�E?�?�t��н`�~��<����9�����^�m����+[�X�ڒH?���������s�Yq~	�-�v������x��ٵ}�x�ƞ�}۱|�5�k�����_��x4r���<m�P�mZ=˳l?�L߷X��5�ee�ʞ� 8�ƽ�k_����70���}`-��m�M8��}�ہun:���{����_`>�3\z��@ ��C(���AXzi�􃝾�����+���Du���rl]ؾ�:�,��v4�F�oqHO�fX��٣�.�Y�O�b�]s:�=d��<+;��v-ĄX�l�I���0��д���V������sT��;��w�"T����0�P����.�z�s|��)q����ĭ�+��}T�zW��X�富j�����خc�9`��h�<��Q�`�-�������т_��u�{��5�ar�T��� v�9�M������Ó��A}��]��=�z�����Ԁ���>޽9ׄ92�;s0��;t(�]븽{xP���5GG��f=r���g3��@����b���m�a�F0����ݪ�5�ڷ��qS�q6�w�w�NN����
R�|�-��������qk�����z�Gyz�lwj_z�e�.�ō��|�}�8>9���h���yzB�d�Pð-�Wj�f+�q
��}���li5��o��5���V�]����0!�N?�:>><��s*E�}$9�gc��Dub���;��E����Y+�>�[��?�W<ÜkGr
����^5�}�����6�x->ȯ���m���������Vl�o@��6������K��>��ޤU�X��F�T9[	pq��O�/Ҋ�̔��^Z�N�꼥�ǳF�C|)���(I�@��f�޴=����7荗.uO��W�K2J'���E�/�i����'X���>G�p�������\�b/`e��k\ߝ�����2�������|K�����Z+��8^z�2���v�:7��.uj�s��<*��$�G�5�	�+��{����ыX$+_l�^�!%�uͷ�ֻ����ؙ�t9n;����Įt@�  3�96�dQ?�����1X��1���;��o������������/��/��_|������|�믕����E�)�iu�ҷ���wX�Vo>�fX�ߵFJ��,��D3 OR�u�ՙ�Af��¤�TG��b��M@8���C`Y�h*�1,�ͫ�`�l0��O�o���e�=�������u�*nڳ�Y��S{����ബJO�����Ms�'O���a?���#�>�s�"��"gݔ��G��{c|g� M[�R�'�=��+Ȏ���B��"w��6!=�쪢d�
�[�M�R�6�K���9t�I����7X&ט�5d��C����j�Y����
.�Y�oL��J%$6 �������m!OO�TǍ��V(ݜ>m�c�DO���Q=�`�ya����T*� ��A� ���;>없���f��^z��!�Gɐ�T��O�oۅվ�7���1����M-��<�6�KR�^|joxq]o�8(��P�MGW������PקAݷ}�$����R�,��hěh�j*p���o�?K����7�QS$��m̈O�h�
qZǺ�U��푊wTqd��R�x	�J�ߧ����m~�&Ki�W_b;�ߢ���t�� �����զ鯧���[ǽtx�3�"f�������tl��-����F7�@V����E��⁌�ڙ��g��`pe��D�]��8����3,@ P.n����]d6.��b��9f�s�捴\I�N�VV+���f,�*�O+Nvsه���؍}V��Z)CmX�"�����li��M��I�*{�Y��@8'R��Ķ='d9T��O9�]���A�̿|��S�0�Q%��~s�(��_���������4�����Z��7�`G�G����,�o�w�q+�x�嵎��y�K�r�; ��)p�Ph� ��c.�v�XgR�C���0%/��e/�o=+pG@�z������M�������;�}�(���vs���ֶ��^����,�QY�K��++L�����ov��_���dzx�y��UM���h9~�9T�XF^���[G{�;�T�'Z�*�T��ײ�U���.�
���?�	CAlj��EiT]ws��l`�옃�8��\"ϖtЂK�',��0�Y�a&�g_�5��'��Y��B�C�z����4�m�
0uJr��o��V�	3儠g,��OԚI�'\$.-@��S_.$YD��]̧j{�s)�+��/�����Mёk��_�%2��*T[O�XcB�ؑ�9p٘�'��Y,�c��g[@OW��q������~y��������(�H� ��_�}b����`���NT3Q8v�7��T^�h�����6$A|����XrL~��~x�]�ٲ_��R�XZV�J������켅�l��U��� �Gx��!�ҡg��!��(F/��|�^;%V��:6�s@�D�����)QK����"�M6~l�X��-�v5HxmuLVz����t�r"�8z��Z��@���m�VwR��r\�ܑL�m��bCf���o�r���q#��l�_�p!�1��J
�����/4^����V�˷l�i������v=��)���3���z����qk�z�k���o�L�������v=��ե*�z��2ֲ��I���N�,���-�x_p�_�k<xO[z��8+P[�Y���̂�٨$d��C��
aI���2�,�YR��?�|�����	��2��
�44q8_������ٯ�xf_�Zj٩��˖�A�o4�wԥ's3�CۙaK�]�c���i]��T��-F�V�>1���6N�T���L�����^��ft-i}���O@������QM%��xu���FU#]�~4�G�,~l�O=I�_n��Q��ke���_[�r��˕���C����G��'�O��W���H��u��ꦿ_��=��V��m'���Dػ��=䏬�}~�a�}J>_�៶1�\-�ol��6�?#���M�FR��	o�T�����e����&�w�ם�X7��=�lHl�I��Q:ѽ���i�ؑ�_��>��,[��.ld��Fva#���,��a'X�8�\��S�/lUoh�:';ΏaU�������A���w��V|���> �-L��@�s6��7����
�7�ᶽ�"3����kg��!��ZZ�r���U�~��Z�5+�
�f�7������`{��MaՂI]J����,U/+S�(�@�dGp0-lG�1�x�fM�l�4C�Gw����U��8i<�'+J�H�8��m��5�8�`�x�]9����
,ۅ�Z$��q|�v#�$��'��^��=�3�=�L ���b��f�q]Z�kQ��#�E��D{)i��u!�`%�P3�^��'1�y�!�lbh�f��.�^������R�u��\���n�B�'M����g���]�}kY�d�K�?bp�9Dt�-�-3�� ؾ�o�8�%�sۉP*���^_�׎ ������%	Y��	�\Z�_ApG�ES:�4��9$o�)�3,�^-�Bo"���+O�6qer�u�>0KN�<�����~�^�p�p�7|��3`e!��F��P���[з�,>�RZ����ƣ5�c�c�2���¯R�;�Y��
����z�pM��ܷ�GҨ��d���=��Z��{��θ�)�~�'�<�rk�E�<�����fE�[����;v݀s��6rԵ*9��˯^m�L����7˅G����W{��,�� �3 ��#ۯ�m���� ��e�������|)��܋r�੠k��4����|g��~��^��iشk.Ы���קS=�;D4'��6�^�􂂴v��(����u�C,�0��ž��	���O3Y��d���L��Rq���)PlZ��f`�i^	���/�~	 ͊_X�5$�0����~!p{��LÔ�d���4��ʭ��ϥmP�Q��	�C�^kV��~(d�K���]>Q'��Q�a@ޱ�OZ����V(�e�=�#�D[�$H�\Y���t���>�����;��;�m�0����n\���m�Ê�u/�5?e�/m�ug���<�Yku�|�,Q�����E'�$XE:$�-���1��}�V.�����RӅ�PL�SBA.�H�SU!�g����c>t���H���G���X�X�?+�[h�Y�m,�?"-�??��g8�~*���C?_��M��b���Q����?�)!��G,
YW�"t\�t��l|z�����,h��Ai٨|��eԬ���#�ы���;�;%��)gM'W#+��V�^�	�`<<�	�{iYoi����Qx�M��bQ������T�=�����lA�o�T���aGä�0��Uvv�[�������&�T�I��.��.lr���M��&wa�[��lrg2�]�.�rog�+d��Q�v��1���2�����OА6ض��ۭ�0�`@j�Tcԇ0���[˅�h2��jta5�[����F��Y(@Ź\����e_U���t���9@���xZ&��X�	��Q�9�lG�Ҳ�2�T���ӗ����ˋ|!w�׌>� �x]\z�' ׅ���݋��v(�Wz
�B!��b_�V�
�9�V1�pԄ���5}�A���0}�"��z:0<��Uq���ɪ���� �]ZX���q�ƛ��%r
��E2��	������"��D�VYPe&�v�pkV�kE�Ƨ����ET�f�*��O��	SɌ�q3Cf٥�z[�B�O3�����,m��v]�ι݋�q�ub%�vð��я��YpTR�p9L#��ȷy;��ؓ�^O�t�/���-^t�Ø&ԵךpC����w�>��P�q�E��|N?3`�>M×�㡙L����f�9���X`+fq<��q�����I}���E-�6(�nL���g�^j�g���ۍq�b���	%hIô�3w�E{=��-�)���-��O�O���P��Y�b�&�$�Ƚ!+z�33q��Lv7\���d��g$��F2vd��9�z��-L�o�>���'����8լ�R�d��r�V�D��Zecc-˕�������������|���v�f���	�=�+�S�?������l ''������?Ĳ����=�[��s4X���4 ƽ�㣶��o�G���͎�+��[�w��Ƴ"�_�ˋ6�gk��Z�=�O��������������ʃڧ���B�T����Q�T���_����!����ǹ�Z��w?�r�n��=K<�nn�É.n���-�r�Hv�#�O
!l � ��i�m���A(g����"�g�է�5!?���
��9#X�GD���h^s;�x�ֶ(�1��_p��8�]������++�l�9wQ��=�y�� NC���=���Ǽ~��z�x���X��>��yR5�<b�d�J=�v(�)g�jֽÝƞ���Dy���/vN�#�n(p��#��,���Jըc�('2>�9!3�0�H͸����s锎p��U�dy"GDyW�E�<8E&.�9吘QW����O�?f���|��8O����,(:\��YE<I{]���㜙�h����:�.�M��b�MlV0�`1�f׏����t��D8z!���M�Ȩ��A6�v�}Dx~h�WbȆ��@�����Ǒ�����F�aV&P]SHM��z1�ڜ��
�<9culIr�]_¢)�<>%A�81��V�&��]}G�7w�TcJſm|אU��oX���Q�s7:(��rY��{��99<�����=�hD�T�������H��\��y�>�{A;:9�������:]���;d�7�wVgL�(	^<|q��j�B^�$��'nn�mB��4f��Q�ލ1�6�6�ΰl���`�9��N(���4��(��H(�58J�:!�ΐ��7�*�����r�Ŏ'ߢҹ���B[.F$��a��,�n24� �kVX1#ňW�ߵ�����V�[�HtQ�䡊�%@�#"P<�Dʆu^_�� h��֐����F��DYD�i�V��|�����ZR	1��/^���<L�7�CI@�8W��x�pRM	c��a��B"'o�֑J�a�����w�X���U$����Ŗ��5W���dI�kp�t��,�4���N�1֚��$krӹ�aHK%Bt:���S�S8	�.֔gӌ(c���jU�P�����A&!�w��r�Wh'A)R�Q�S	F� Ċ�v�ZU
i�]��I8��B�ԗb����\�ݜ�nKg�1��{3�UM���<���s�,�{L`�T��m	�{ld:uk��G�6������G*G�e�WGcJ��A�>�K��pg.6
L~tU"�D%��)��н(.���`;��AM[�U���=ܒ�T}j�D�bD��~�ݓ����&���!���	@���ܰ�����״@���0�'/��J��j�_t�9�nb�Y����Z�#���x��57���h�o�me���`���!�*q�I�9.M7��=>��s�*BN�XM���_�K��}�����M���T _��В�ō�VB�-a.�K�^�
�����:%�T: ����Bp�8cd}(_d�F�q11�x�ǿl'3}�M_Y��_H��c�0y�	S*�4l�msf ������#v���)U�W�Ԭm=��z�n�%�7��55;iZ�#WQL8nų�c���G�Ɛǣ$3V��`� 3�mntK��1G�`~�IO��Qݎ� �K]	��(VL�K<���.�f�%�@l=ݾ���B�扨*{�+]�/���ه>2�bE� ^+h�n����q{`������ 7�A�L%-���,��tT�ȳ���-Q����J�ޤ�5��G�=)#P�C�[nA@����ӳ+V�L��k�/b;�Mq]�g씖le[�y��B�!��=�{��YH�%y�Y0���4���#�i���` �ۏмH�f��2����=qm�N���$�[�y7��RN����=a��Pb��]��#�+~Q ���)H�$�՗�k'\��S2{U�.�uI�j׿�\��E�ʼ���tmO�T��w^W ��Э�c��j����*)����d�+Ry(�2�#d8��v�mH�9�d��#�`R��ǅ�l�X4�^��h?4�����1e�=�6��]�ǖ8��Mn�6��4A��E�-�hC�2���\�!�_Z+�a�4Z�-壮_������
h"�$�'jb��9Q�������ͳ6!8j5��J�h%:�����r$U23G�r��k�z�ǒ'���% ���I�A��H��R��8�U�TDA��ARg%��	y*�_~���D(�b���͌�4���O���W��s޻�|/�kX&�W�Rq�EBq˫*/R5J���"Cu����/Ru���C�n���9���
�?�|�#鏿�E���)&t�)��I�0s�-6�eb�P �`�D_M�Zm�/�
�:�_�^m�l�t��P�vH[�K:Z�j�f�F�n7�	
ܴ�s�ܜZ��IV���i���Qe׷)J;���H[V��Ɯ��%��Y��
Z>'����ww��������}r����xC�Y(H_���uTH'����>V(�R���S���XvM��d��ϡLd�7+|�/���ݐ�c�Ukx5��>���������Pl9YN�J]߻�kRX�VBy?���T�Hj�����r)MD��u��L�*B&&���i�m����iف��f��Zv���������A�
�㑨�<�kg$Z�)fx���ť!kP��4t�OG��I\U��%F������Tݏ��F���&��J�xQ#Yk��k����)���L���F�K,t��_cI1���qo�6~��Ф9���<��c�]~RE6;�I�L�TQ��L������2���I^���F���a�B��+�j������>��*Y�hO�����<��c���a�C) ��R�u������'T�F�'q�#�E�R��m��{�T�S>������ќHډŽ���%yb�[��Lσ�eț�}�[��P���2����{|�Z�����;��@3�L�d�M����l�g���5�z������Tԝ��Hy]�E{'�%�P�._S�hE�V�B+:4·��1�+�е֜XsgkP�М�����s̬��w�1I��{I��-��:42z�0�Wi�z�A}L���7�#o�eC3�����2�f r�6m�;�yYB��W`�\�M��d�7�يgQ�7����"$�Í�b����o�����e���p�}k|E�.�Kܻ����M8,t?�%�R�~b.ѭZ %��Q�� �Ќp�HQ�J�h<J�d���r������\@�
�K����O�C4�2�� g�v�DnaC�]&?eM�Ao����t\��d��\����b�&S�l6�l<��@��}1[��8����s�N�6�����H4�>jf�d� ���9H��^�]�R�@H�����󞮺���3�Z������Ǳ��N�2�z���LS�;2wE7�v�KM����}(�B��O�g�h�� m[
����j%׊!L%a�3�@�eϔB�B��jJ��9�8��Rhc��Д�s�
J3h��~SlqRJ��ȣ�C��v����+4U��A(��RP���̰�"���N�K��t��B���#�u�}�u����k������~�]�K�bB��r��MC<уH�ꐗ���)+q�H5��u ����rۊ�ܶf-�i��w|~�WY���Q՘r��F��ֳ.lX$������%�+r5T���
��?�Y�_A���L7��{�,t=��W~A�)���A]�0"zv�E:��5�I��̬�>1�ȫ?
����vf�q�qƌCӜ��=ڣrW��&��E�r�����೬ +<`�T>T����J��+�.��%ƙQ���n�F[�vg��������5|z3��g����:E��ץ�B��ؤ_ιff���n���;���a�f�;{��#�Ð�_"_��ę�lg�"��JC�U/$�;w���R���5a��Q=���s���X�޴H�h�����#�+�t���`MkT<{�W�4��7���]r�'`S��L������2�wLAi2�rQ8�¾hjfy�gB{���R����HG?�Cn�Y0��lfv9�Q� �OfnF�:6�1��b�`d��%ꘉ�$�D���𢛴Q%�
NG�]#x��J?z���~f(����ZXf���5t�u���D�K�֞z�ȶ���#J$l�2^�� ]�?��#���/�͒0ֿ�:���Gٕ�j�R�m�+?���Gl�^[%����w����	�z��E7���b�&u���N�G3�����Y��`��Wy1��p��[��~�v���f��5��[[a�9���E��I�I�HAyø
�h$�������s�/����Dˮ�u��({8�������5U��r�A���N��{�����0��1G�o�� �����mx�N��h�V�*t���Jw5kOM���hv���B�};SC��%}�r�̱�_�h"A=@�.��Ҥq�@x��e��*�z��#�����X����.��ƁK.�D�s$v���ؔh��L7���;n�Q��c0�=t=�_�������ʪcy�6�xa{|We�ѵ�N�ܪ$�U,-�nW�����0���@��Y����b&�<@T���N�l�����W=���7� �Gʙ���z-�>�&H�#M�C{`zHƗh���:NE8
�'�g��R�K���2��.���Ge�v���w�����
�ؤ�
ب��������cG6f��Fom�a��|���<+���~�O�
s�'��ǹ�nlys�8��w~�G��Ql�BG���q�7�xV���|�:�*��N��yV���	�H�JEйY0����E�����?���G=�p�*�W�O�t}�+�˕�߇��-%+c�~U+�be��Rۮ~���%�"9>��*��r�YJѕ�#)�of4�O8�@�DW|�M*��7{�ZZC^�o��3��r���6�vXB;	z�І�7r���H��8��fbESZQ�����V��2D?�=�0�E68�!�Ft����]k�NUh�U��Z�`����1�ޘ�U3��iIQ�r����M�+G.��"`JGV�}�Йw��VE�W�.HӪ�@2�UD�,|E�F�<�p��̈d��WD��yp��;�D�t�&���4D48"�c�Ou����?�ӑ����~�i5���)5��-~Z����Jm��z�j3*���T~�:�ӸӔފ�>��JC��X8�S�Lߞ��=Z'�Ř���(�\nW]��w&�f0�ރ�u(����ED��q��/*�4�\�luU0&�\|�]	iNA2d�p�ed(�M/��+�*[���;+�s������p	pθ�5�g�
'��:��T�%��I��ۆ��K }��k!^�H�ˏ���"1Ȍ����b�Z�l�V�������䑊Q6�R"�K�7�_27�82�	��/�&�"с{�O����SHz"��[����dr�T��@�]�� *�`Rٴ����KtÉL�Րie�e<Yvj��}eQg�r�h=�[Mk��rl�4���P�瓉�lP��LP%-8�,����s�vg� �E3*��}[1�4ʧ���DH"���8�A��C'��9��K	k4����
JH+�-��"7��lt�k�ٝ^j�TL+����x�lJ/7�<J/8���Yf�Sj#�E�Y� lr��]��e���d��
��,��|�	��u�{;`�Du$<�N�	�`�ߜ��,��qJ�7�zA}é@y#֊��vn��S��v���/�_�����j#_S��3����>+�`V�r��0oJ�}���Ԣ���oO���ќ��yn��t�: ��7����7FW��C���/�ŗ]-�C�fjw��w�`=��l6��`9[S��0�Ȇlv@^�&R�Ņt?�/iug��mY�G�$q���y�
$[HJؤ�pR�j�� ++�	%+����"���p}���0�K:y�|��w�FF��yn���SD�����o�P|Ya�bf7�F^�3MGQ�Éwq��y�)]��qӼnr�y��=���o�w᧍SF8R|��e9��o�ͷ��l�
�ѭ��2t�IH��&ZD����\�.���3�+�E"	�Ԝ�\J�%fȟ\p]5�o1�@W��*B�����g�na��zU0��UeUUP�u��،A+��#W�)v�̓g�b�E�&��l $�Y2�8'�Ǐ�[��2B\7�N�,:S��^�z�Uy���.<�t��\��WoT�\	�Xx�:��t Ja�=\ǥj���0���x���؁�G��3iT��,nKj���ԓ�5��j�Z�p} |��T�84c�go�.ָK<Waa��l!W��0��}�_�~�<�¾ ����5B&.$��B�10��W�,��Mǎ�\dhkR��&�u}�K�I�F�F���C�a�H�9g�\S��K�Kabx�\��`��5-�Z0/���)���C�f�ط
��_�V�M5sb����q;�L_���-W�Z��"T	im��D�J�:$�]��G�$����$��mmL#�a|0�GN`r���đ�����*��,��Nh�#����)X�KC|��� g��)�\:H�+�G�Y�1�|h�Pis��r\�cS�7A��o:=�k�=%�z��)TB⪆��/,`T��o�D������c�0�3s��y�Q�Fq�}eb���9u�#j��0lJ����.,<��U�뙅�!���)�]ݭ���v�g��Q���ck�=��w�DZ\C!���&��Tl%���ے6jF�g�n� �`��B.�\��u��{��f~��BS�7"ZQ8���j��\sm:Y�Y����ă�����0�C�]����3��
s�g띍k�*��f�D���6Ψɗ`�x���'�Ĳ��1}�K]�؄�7��3B��!�[�tݳ��>Ə�R{�r��3N	�y�igR�S2�ǻT���E(�� �f�Х"���8*��Lemr#'6E7�N�$Ab�&Įi�%U��%K�I��uݱpy��n�sew�h
hs�XV�*9'NCq/nzB���nC�����'���c�s��'�����S�wru�N�(Fk5��M�iL���az�S�@y��+5b{�{��
��5 ����8��)ys�z���7��
����bq��D�T�A����RV{�Ry��"}� ��W��J���b���>TL��UA��K�߭*��Vf�f��UR7�{��gD�h�6�ј6����SDfi��]]�P�B�Px���S�A0g�/�������%�J
T�uބ�#��~���j�2��J���iF�]��:j�+J�MY�e+���זژ���q�:�TZ���
[1����Z�<�o���x�l�-V��kAv� �`�8C�2aʍ������$����>'��?�JZ;%��}w�8�MkT���h�Қ�Ĺ���~(�V2^y�2�+L�8�"�ﹳ�L���J(�Y�-�>�c�����wg�E{��}o�|�����
bb�!�3"���\c�! 
3� /��y��50��f���X������S�r�y-P'���|h#.=�=��OQJ�Q�V�muBhިi!�x8�4@�Nm:�X��4pqM�t���i@C]�$`b�0'�g��Yļ��q�h;�܇�)]?C\c�w��YQO�w� Ek=�::�����c*"4Վʻ�i������ �ORș��>��5-T�`��5��m��r]�?m�"�p���#nS�5�:)��m��/|K�Nz6��Q%֤nA�)0�4Qe���~]������N����L��2@��r�v�`��l0ŽBw(���o`�6h��F��������'�f�*�kqA/��]p7�JF��� �1��E@~�%��.TQ|'�xa����;k���&s���5I��)<<�R��$Z#f�H-a�-{��a*
՘��\*���/$�Y�4D�0���|G��jvqn�/�*�u�K+�Ţd�u�T�r�5�"�"��B���}TZE�8���5�5DS��z���h�/섈T��l���;�P�����9)���U:6��Jy�Z�Y�|���-�IT��V�Z��`�o�J�P�G� ���CKK q��"��K��\n��jISO�:�� p��7�C���Z����lhsG����KP�@�۳;x0��	J���W]6v�
TcK�%3�1y��j���;�r��3:�7a@GWr�Ef�l�����0	��z����/���ڭ" }���������	����T7��*��QY��x��f@9�:&��(��7C�/�����Vms���!��_���[2G�m��)����6[�;��MI��{�6�(�61��;��ꗬ-֤���vʴM���
0������{>0����zk�׏���G��hTH<m'�2�{c�8#����Ҵ�Fh���D�&8�eJ��v�^�3�`��<��#�D�s#%~�Y��שD��gӂ^ѩ���Q���a7 �KԨ	�e=�� :�O7�
rN�<�!��@$��w����[�د���Q�2���&ȝ����v�zf�(�[P1s��B{
�,�P�@�,�_��dtt:�`�HXo A�GЄ�̊�S�D<���jW\�>;#/��9ґ�8��3��|�L��u�H=�$aB���.G2�R3�8<lR`��>}o�G��������Y(ב���
�WLLN(c�B��w�]�8��4�k�yp�J�LX(0Q�0	�Ҡ�~v/�! ]_�oU�ms�~�B�/*M��1��K*��g2
Tq�2������r�r�:*h�n�@cY��<oS���^Q��c�(V;׍թ���%F����=��C��;Иo9>&�M���/ӹ��`�!����N��"Ń1wn�M�$��O-�H���4X��:���媔���k��
��\�����o��џ?z�ov�a��^r|���O��	�����d���X�����u,˟E��$] Z� �N���I��ژ��?�?⿭���w�~.Rj�]ƽ�:������Vl��o-��ä���ߛ�3�di>o�~�V,o�щ�e���0�Q��w��!�I�@t'h�x4�1S+�c<Q6��龕��A����5������Թr����������.Ch�+����߼�o��,�W�oز����cQ��/f<���e8�+7j��-��,5�g�A��x�(>�F���U2���MX��=��k��$�ň ��K�k ��F4|MHC���`R�b��Y�G��l]V4	���pxC�µ���X�
�����%�0�LƖ}�vh[��#�G��U��|�=ċNE�'�0"��ԊMZΊ�]�X_��EbѰf8���E������ȍth�G1$C<�G�us\%�ŗ츏�sМ@�|�����r� ˝x�Q���L}�I����}ͫ!�|����.-N�d.x���ٕ̅��sa6��֩X��Af�p�(�;�s�	�����F$�l�e�=��NͪeRP��k�Q}9��t���ST~�/�@B�T�����=�r��0�`m�@n��LF}?t��
���\�n�7̐�,��q ��_��U4 ��XZ%�$4prX�扨%d"!bh_EA���db(qC���u��d����� (FZ�f0"2	��v��v"�X`���"C,N�(��h�U_�L��Eiƈ��$>��M��+Cc )g�6X��ԣ���ˋ��`�����Rm�?~���Gh����d��>��Д�#��Q�)���"	8/v��f�B(���O
X+�YZ�?������AS�����<�Q��^Y_��61������B�� ���:B�������N�\�Ԕ�|q�uL��խ����_���i�����_���OR�Z�O��U��U��:��M����3�?�������]��;"��a)�2Z�I�yY��5f��_����r�Z�����[[������T�r+HV�����vᇪ�@��`���u�e;|[o��o7��ce�.�mb��p�\���^����W��j1~����{|ӹ�r���ve�˯�+���5H�_~� ��ٷ�+��V�o������O�?�6���I����G<���*�g� I�7@&6`������9�ޟ���;�:|6���g%��r�u�g��bm�\����Zmq��!�Ϲ�:n3�[���ũ��:f���o��7���\^��I��O�R�����V����Hz`���c��ߨn���ol,����D�{����VY���2�T͵��d�_��������F����B����xw�υ�0��e硷8h�O�`�N�﯌襈�����2�W�c(b�@�=����Q�������D�n���[���>yS���E�s6�b?{L���?��{J�M;�:n���*��X�"%��C7��o�Q���6��iZ��y�1E�[_����W�O��o����I�:3���:��ޘ����]������y&?���k��Y�V:~KޖQ��Z��5~���*�Gq~��˚$v֚zP*\�
s�fs�U�2�{~���i��}�KΔE[|�b=���>?a�s;�e�l~�y�#<G�%�)��yhD��SK��h�����j���XN��:�2D^�g+�"�F�^^cy���)/�/H �0`^& �  ��&������������Kt�I���ġ�{�xG	�n�^;_��} �O*�n�)�Qy� ��^�E�u�/�3�.�N>l8���l^���n�<<n�&7�A˜�y4L������2��e�&�� D�#�4�a7��J����Q�~R�#���a���܈1�ݮ~�ז�!��߬����,CT+xX˱D�����1�R�J�^&DL(�+�ϴR��	<���,�|�%��N��?�_s�c���`b�����&-.�<������oO2�� �h�خ�m ���C߸���޸�����R�:��}L�ȕ�3d�w�)�{Z/�LF�z�>:]v����=����\~��^(~�)q�;ߥ��4�O-���67�����b����/0��3~�w��+M�7�K�z;�b�c�&��ʻ���ǅw$���V��+�
�U }\܈�)���@��Y1`�^��"���F�Ϟ<a�`8R��U��_Vr������m��Q�2��!��V][_��m�m�
��;ǭ���I�S��0�x8LV����Y�'�f��M���Ꮥt��ˁJ�k��5s�c������V!��[d�����?�m����� ~D�kG9��Hg �$��)Қ�&�����o�Il�D&A����(�C@̣�d2O�N�T)L~y2��x����<d/|��^�mv��
�D=�uT��d9�+]����Lr��	����@�0α��^U���o��F�쏭�IF�`�.E0�� ��\X�ѶO�E1��55�����DI�B�F�6f[�.댒t ���������űK�yɔ
�C'���0�m�2;PW0{-]Q|Z5m��T�b��9���8g �n�M	fh~\�8v.DO���#��6����<�b璟��;=[�K�bc�H�@�slw�2�79%6s�H�����u�
.]��Գ�\�<���K�{%�����Ȫ�6Lp+�glu��9N��+�g�^Bq�d�,���2��hV�|�óll�8ϵ�Y����-ٽ����(-W90wtXg���]N�����`4�@��_<	򆰋{��p<�"V#������$]��kx�h�uL���Ox��Z.����"�냤W����7�c��}��;"hu$�_����A�xw�M���yq�{��鋣f��>�n�q��=��~q��"�ss����"�G��?�L�ox�b�uL���6�����ssk��A��\X�ߧ0扵��Ad���p�Ӥ����E�k���q�T*�������
�?5��������y�������4�_��@"=E��#�P�����j��	�>�@3�t=�L�o�
ʄ=G�����[�W�X ��Z��i׼��Y���K?t�V�/��i�V+�u�O%

O2H��[ҹ3W���Y�c��z��tG���þAQ��-��k�>W�P��w�{��m����1��{}=f��U�X�x���׊7;n��͇��x�)��*�n�hNÀW��EW�(�vꀾ��t����u;�,|�s��L�3���g:��d����C�8uZ;��4���?'��j�v\' Q��B�G�u&d��F�?6kZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ���o��� � 