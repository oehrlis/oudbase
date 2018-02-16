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
        DoMsg "INFO : save customization for $i (${!variable})"
        sed -i -e "/$i=/{s/.*/$i=${!variable}/;:a;n;:ba;q}" -e "a$i=${!variable}" ${ETC_CORE}/${OUD_CORE_CONFIG}
        
#        grep -q "^$i" ${ETC_CORE}/${OUD_CORE_CONFIG} && \
#            sed -i "s/^$i.*/$i={!variable}/" ${ETC_CORE}/${OUD_CORE_CONFIG} || \
#            echo "$i={!variable}" >> ${ETC_CORE}/${OUD_CORE_CONFIG}

        #sed -i "/<INSTALL_CUSTOMIZATION>/a $i=${!variable}" \
        #${ETC_CORE}/${OUD_CORE_CONFIG} && DoMsg "INFO : save customization for $i (${!variable})"
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
NG�]#x��J?z���~f(����ZXf���5t�u���D�K�֞z�ȶ���#J$l�2^�� ]�?��#���/�͒0ֿ�:���Gٕ�j�R�m�+?���Gl�^[%����w����	�z��E7���b�&u���N�G3����Y���_���Z��C$��V���2��{��Y�e����V�E��zyc}��!�c�9RP�0�)�,�n�n��\���_�wѲkz]�Gy-��h�@6��9r�DU�\(A��3�S���(�+ïl3���w̑��1@����v^���:���U�
��c����]���_&�&���C+���~����~I߯�1s,����!�HP���K�4i�2���`�d�J����ň�&6��;�;�&�q��=�Q���ݳ446%5<��M���Ǝ;k����`]O��/�v�l�l���X�9��0F��U�|t-�F.�*�f�C��U~1�iu5�q��*вFx������#����!�9��d�U�~��;�B���rf;&��^�O�	Rj�H�����%�*��1E��S�B�	�Y�`���ҳ��r� �L����3�Qٳ��;���������66)�6*0m���Ǧ?:�<�ؑ�Y���[�t�o-߿*��
:}����.�ɥ�q��[�5N,��Q�x�Б/��;i�5�U�<���#�����Sy}��`/q� &ҾREtn胹>dQ=|�����O�Dh�Q�o ���J��S;]�z�J�r���a�vK��X���@�J�XY?�Զ�_no|I�H�O0�
j��s�Rt�;�H�F����M���7��)��_z�
��͞��֐W������}�\�x�M�Ǡ���N�� �a�����2R�(�蟼�XєV#C�D�>�� #��w�*Lw��r�v���0u�nך-�S�z�%��3�>.q�tL�7���C�L�jZR����|� uGgDS��ʑ�u���ґy_9t�]0�U��U�Ҵ*(�Lz2_Q��%�E~F�+3"٠`�Ѿ{\���;�0]Ķ���?���;B�S�������t�#�x��B~Z�)�rJ�<p��V'�4�R�i�^�ڌJ��;)Ն���4�4��b�O'����v��Ժ�ӷ�{n���mF1���:J�E2��U�f�I���� w
�� v��s����?(W<[]��&�iWB�S��"�pJw�K��ʽ�V�8��Ί�\�`�|C�&\�3ne���x��3|-U�A�`i҄����!�H%�Z��%R���c��q��H2�ī.�����X�+�����Fm��q3y�b����H�R����M=�w�1���	�Ft�^�SxxC>���)�V*��q0�\!�t3iWi9�
�3�T6�6q���p��Ӏe5dZ�pO��Z.q_Y����!ZO�V�9���[+�y�,$��d�_D&��~;TIN6`�&�\ ��'��GьJ?t�V�/��ie�:����b�&�Љ źFN�`�R�M,���B��ҊEn�(��M� ]��iv���6�J%��-*�>����0���� ��w������m�B:�\�((|׀p��y1�$���-/-o"n��!��N��+QB 	��$DA>�7'b=������^P�p*Pވ���8����!�%��K�W<��2��Z���|���!(7��J9���\`� ̛�D�`�3�(z� �1����S�?r4� r{�` ݮ )9������U$�P�5�Kl���GWK�����+�]2X�ž  [��C'�X����8�3�!������xlq!��KZ��gd[�)I�'�n�����6�:�T�ڴ �+��
�AB�J������7(\߁`?6��N�<�i�F���x�����Ѿ�긹�5_V��������D�LӑAT�p"�]\��z�`J�D{-i�4���iޣnu���]�i���kx�BN���D�C��|<��Bbt�����gR렉ѩ�b���� ���k����
w�H��i5':���@��'\W�[̫�U<��P�İ�����[�j�^�)cUYUw�&96c�Jq�c�ȕs�]9��Y�XmQ��"9ɹ0e�L+�I��c�V�����ӷ��s��W�^cUi��O�/]�-W+��UA�5WB1����1�RXl�q�Z46=�(�3�!'=v ����L�20K��ے��6�$u�"DF�����@�=\��1U-�X�Y��˃5��O�UX�G~:,[ȕy;�jb������.���/H娨�B�������x�Lq��U9K*gӱ�5ښ��	k]G�҂�u��'��z�3hN��3�k��R�#��@ X,}`M��̋/ c�}-��#��B��:�G�b�@��ا����g�Ng S�.paK������U�G�_�"mQ��Ҡ�mW��Q,I��b2��z[��mL<������5q$��'4�
�.K"�����j"e
V��a�"�9�ř� x
/���
���qVw�6�2T� ����X���MТA���N��lO�����_
�������U|�%&&!ah��5L�̜z�c^}Ի�Q\l_�C�'mN�ڦ;��h�g�O�i%�zf�qȥ#n
sWw+}q|���ii���xO��] ��PH�e�I 1[��%���y��7�2�1{��� ��{�d;�8�����T�V�z���!�\�NVd�&C��{b�<.&�`��<�*吲C�F��s�������zg�ڪ�;��=��z��3j�%=����)��efL_�R=6!��2�P�z��Ɩ:]�,���#��^�� �E�Cl^uڙ�L��.U���{��<H;��$t��0��%���0SY��ȉ�C�M�S)I�X�	�k�jI�wq��eR!�CCw�\�!��\ٝ1��\&�����BΉ��P܋��P�,�Đ+�:�,���:f����>�I�,���T&ĝ\ݳ�� ���@�-�oe��S1ur����3P^:F�J����^+�B�0D�*D��D�ExzJ�ܬ'E�򍨽�-���X\#4:s��檣��^�T2C�H�* x���R=cz��G�*;��U�cjU������w�J馕٣Y�s����^s�?��m4�����}��Y��fW� T�C�G �^�b�z������/��p�AɧR�Uc�7!��8��i�ƵZ��o�;g�҄*�{�u�>���ꊒbS�lYƊ�m���6f>0e\�� �&-��V�,�l�4��)8�8�p�����Z��>H1X>ΐ�L�r�?n*(�'I �x��I���O!���N�tt�:Nv�� e-*ڧ��*q�d&�ʶ��W������+N���{�l5Ӧ�h�J�g�oK���Xh�� ���Ǚ{a�� }_�[09�f2���Xk������F7��|���� �K�{3v̷��'50>i<����i^�	��@5_ڈKOt�?�S@ԟp@ԯ��c[E��7jZ(� P�S�.� \\7h,�A�P�7	��4̉��t|�D1���}�)�N9��gJ���}��zV�S�]?@EњF��D���z�}$�ꘊB������Eu~#-�� �rf���sxM�/���f�2}6�\�F�O[��0~p��Tj�N��rh��ҿ���eT�5�[�k
L3ET~#�_���t��~��d,f���F����PkF�ܭ]3��6Lq��
`����Z%C��o'4�mt>f�I�ٳ��Z\Ћ�q�MD���8#~�`}�_a	ÿ�U�	!^�n&D����ڭ0���*�zMGR2�AJϯ�`-����"RK}��p��B5��?�Jb�b�Ig,�)��)����]����j]���u�(YA{C;/��mM��H��cx-�b�V�5N7<r1G��������>�;!"29�p��N5�}�?j�pN
o�_r����R^���h� "_=��g�x�2�UĻ+� �ۥ6��Q&��D���H��H��Ra;�[e�Z�ԓ���( \������ĳ��?>��9��A�*�����`��2��>�U������e��kL^�e�}�\1����M�ѕbQ��������4Lh�^�$��K{�;��v�@��l~���h@7?o�iv���j�J�?6+���(�]�d����f��e}���_۪m.�<Dz�2|K�h���3%�����fKs�)i<_cO���&�qG�^���Ś���.@��i��W����V�Zc_�a�f�y�^o��a���������
	���Y|o�g��v`��^��#��hM������lA�V���K{��p���W|�hrn�d�<˱ua�:��"?�lZ�+:�7�>;� u�#!�£ǞD���0BC�i���0��������}k���6<V�2�[F�\������.]�̽Ey*f~[hOaB\��J��%�+�����N'��	� h����Y�u*r����P\���gg��:�C:�'p�}���������Ǘ!L�b��\�E��H&VjF= ��M
�ߧ���h����8�=<0 �:r}�Va�����	eL^H���g���~M;�_I#�	k &�&T���0����j�m�ݯ�Ch��O�i�:&�}IE��a�LF�*_���֔QQ�Xn PG��O@��ͼh,K��m
<<]��+ʚ�v��j纱:u�>��H_��Ux(vb��-����� t\�e:W���4�Y�I��[�x0��M�I��O>����%i2t���P���\��~m���V�-��=L�����G��Ѿ�a�m�{��ݣ��?U��'����{6����c�K�O��ױ,��[�th�:�^ /&=>jcF��X��������ݝ��H�)v�^�2��6�[���������k�o��T���� ���g�Z���G'd�e����GI��*[��&A�ѝ�i�u���L��!�DQظç�V"|j�C*׸#���W�S��	�w|�k׿��Kso��Ѯԗ_������^�BX�a�2g�ۏE����Pg<~W�ᬮܨ�^��B��d���S2t���D"]����W�0��6aQN�,jr�Ef��p#2�L��/��<����5!1���I͋�fgE��uY�$4w���U�BK�'b* Z�'�� 2[�1ۡm-����ѲW����N�/:�2���S+6i9+~w�c}�~�EÚ�,�Q�v;�v
#7ҡ�Ő�0a��q�_��>��Asz ��9
�.ʁ,w��GX3�e&ejG_�5�r����G$s`��\8���ୖgW2�\΅��~Z�b�����9���L��'d�؊�2��y���xV;5��IA]ȎB��F��0�g����JLQ��H	�
P���C��0���̃���I3�e��e�*L��;p��9�0C:����/|��Wi����<ci������a�r�'������	L�}i�6ʓ���Ţ��͊�I�RܳF7�iEP����l�$�ۭ/_؉hc�y���8Y�C��_��W}Y3+�#n�O���j6Y,��t����<`��S��c�X//�K�a�C�K�%�x�q�Cӻ����0OCSҏ��G�V�X��$�ؕ����4�>(d`�tfiE�,L����M���Fo�cF��ze}�Z���/�[�σ�O\��������;�s�RS�����1e�W���~-��C������5��?I5�ju?AW�W����7�sWϤ^�x�3��[Hot�bۦۇ���`ha'��e��֘i��"�˵jmk��nmU��C$�Qqnȭ Y�G[����څ��y�;��/ו���mM�mЖ[��o��m����!F��p5�[l�{�7�_�v������~��M�����ە�/�ڮl�on� m�<��g�>���Z}�uL��76��?e��\��Z��$-�|���P���q$]P_� �؀�J�#���,z:�7�X���|�~l>��0��}�Q���/����r�B�k���߇H>����ol-��!R����q�a���U^�D��ry1�$Ţ>�K7���[��b�"�������N㿱��������Ze��?LʈS5�:ʓ��2���Wj�U�k��C�Ǻ���>��PN�����d��?q��:a ��2��"����w� ^=�E��y�u�<s��rG��o�K�����5BSo�N��Mȗ�s��9�`�!��1S
���?~�)=6�|������b���^|u�h��UF��Z�X��C�i���Q��o}����_�?e���U�.�?$���$~0��{�xc�6&.rtY��?�l�86�}�g�Z��9,,y[F�j�k����1+��D���Jj,kRd��Yk�A�p-+�5��=V1��W���:��'n��.9Sm�-��lt̻����������9罎��x|j������nN-����+�w�ij�`9�;@��P�y���,��.�{y��A�����\� �y� ps� 0���R��ϳ/�ҊB�n/��G&!�N����]�%�{�|A���,?�p�����F�)�lVwx���1���@��;���0�òy��F����	����-s���<0m�W_�o�c��:�=�K�Ȏe���X,{��xn*�K�stF^D�I���r�qB2r#� wt���^[���X���ƳQ��a-�I�S�^,�ǤRH)*Ajx�T1u�L�?�JEX�'��z\�t��O:����ͱ�)�������B�{�����З~>[[�=� ��0�1�b��6v}�bT�z�&��7r�J��t�1%#Wrϐ��q���i�2y07�ah��t�}KO| ����?��r�m�z��������|�~J��?���_��\��?HZ�����[�� ~p�����z�4a��.-������1�w+�c@C�ޑ�.��Z9p��*�W�qq#�@?8���gŀ={��Ǌh�7��{f�>{򄕂�H͎W��O~Y����&�{���G��̏���Zum}�����y+t����['�O�����0Y�&Wgş�7A��^�?V��?/�)���̥�i��<��Z��o���B���4�	�׷ox��3�嘢"�����̧HkF�̶��k�1&���Q�2 ��1�"��<:�S�0���4����0����zm��q�	�r(,�4�QEz��4�,t�#+3�5�&���. y�8ǆ�RxUZtϿM���?�B'�5���X�saG�>JňN��8S�
J%`��ۘm�?3J�,:�W��r����R���.��%S*H��b��À�]��@]��tE�iմ�S��я��`"p2��;�9d7e$x���q��ع4=Q���W����H��2�,��K~2��8�l�.|b�a�y�"1αݹW� ����u<$F ]v�^�N��+�t���S�
r�����/Y���or'W#���0�����Et��8뮸��{	�a�����pڢY���ϲ���`<�zgu��n^�Dd��:�ã@�\����-`�<w���v9]�����8�U�~�$X��.���� ��X�@��^�o�t�O����9�1E���>���j�L�����^������-�b�iR�u�@��W�[��ݝ7�vk�������/����V���������x������́?�[$�tI���2��ᭋ9�1m���h�����ͭE��I�sa9�~�'�N��!���iO�>v��)6���S�̛�
h��gc+��l����������A�B������z P����Z�,�@��F��J'��P�P��@3A��*(�y�OF��n�_E�bP?<j4ۧa\�z�f�2/��}[1�4ʧ�Z��ו?�((<� ��oI��\�S�g�?�mh���R��[x�E=������\UC1�?�=�)���/�R�T�������Vyc��A��^+�츽�6>[㭦pҪ����9	oN\iN��]�.��۩����<�^/��l��e�=�3�� �R����?�I��V���i����`w ��,��3�q� D}�!Y.,ԙ���A�جi�i�i�i�i�i�i�i�i�i�i�i�i�i�i�i�i�fH��P�+ � 