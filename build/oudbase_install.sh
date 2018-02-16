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
        sed -i "/<INSTALL_CUSTOMIZATION>/a $i=${!variable}" \
        ${ETC_CORE}/${OUD_CORE_CONFIG} && DoMsg "INFO : save customization for $i (${!variable})"
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
    echo '# Check OUD_BASE and load if necessary'             >>"${PROFILE}"
    echo 'if [ "${OUD_BASE}" = "" ]; then'                    >>"${PROFILE}"
    echo '  if [ -f "${HOME}/.OUD_BASE" ]; then'              >>"${PROFILE}"
    echo '    . "${HOME}/.OUD_BASE"'                          >>"${PROFILE}"
    echo '  else'                                             >>"${PROFILE}"
    echo '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"' >>"${PROFILE}"
    echo '  fi'                                               >>"${PROFILE}"
    echo 'fi'                                                 >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# define an oudenv alias'                           >>"${PROFILE}"
    echo 'alias oud=". ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"'      >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'                  >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg '# Check OUD_BASE and load if necessary'
    DoMsg 'if [ "${OUD_BASE}" = "" ]; then'
    DoMsg '  if [ -f "${HOME}/.OUD_BASE" ]; then'
    DoMsg '    . "${HOME}/.OUD_BASE"'
    DoMsg '  else'
    DoMsg '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"'
    DoMsg '  fi'
    DoMsg 'fi'
    DoMsg ''
    DoMsg '# define an oudenv alias'
    DoMsg 'alias oud=". ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"'
    DoMsg ''
    DoMsg '# source oud environment'
    DoMsg '. ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'
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
� ⹆Z �}]sI���������s��Ź�,	.�� H�pڅH�]~A�vN��@�Ѝ�n��H���#�h����_����~�� gfUuW� � %͠f$�����������2�l���S�\���`��&��\��Eb��j�R���6��\�ll�?b��0Lc?0=h��Z�A���	�E?�?�t��н`�~��<����9�����^�m����+[�X�ڒH?���������s�Yq~	�-�v������x��ٵ}�x�ƞ�}۱|�5�k�����_��x4r���<m�P�mZ=˳l?�L߷X��5�ee�ʞ� 8�ƽ�k_����70���}`-��m�M8��}�ہun:���{����_`>�3\z��@ ��C(���AXzi�􃝾�����+���Du���rl]ؾ�:�,��v4�F�oqHO�fX��٣�.�Y�O�b�]s:�=d��<+;��v-ĄX�l�I���0��д���V������sT��;��w�"T����0�P����.�z�s|��)q����ĭ�+��}T�zW��X�富j�����خc�9`��h�<��Q�`�-�������т_��u�{��5�ar�T��� v�9�M������Ó��A}��]��=�z�����Ԁ���>޽9ׄ92�;s0��;t(�]븽{xP���5GG��f=r���g3��@����b���m�a�F0����ݪ�5�ڷ��qS�q6�w�w�NN����
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
��E2��	������"��D�VYPe&�v�pkV�kE�Ƨ����ET�f�*��O��	SɌ�q3Cf٥�z[�B�O3�����,m��v]�ι݋�q�ub%�vð��я��YpTR�p9L#��ȷy;��ؓ�^O�t�/���-^t�Ø&ԵךpC����w�>��P�q�E��|N?3`�>M×�㡙L����f�9���X`+fq<��q�����I}���E-�6(�nL���g�^j�g���ۍq�b���	%hIô�3w�E{=��-�)���-��O�O���P��Y�b�&�$�Ƚ!+z�33q��Lv7\���d��g$��F2vd��9�z��-L�o�>���'����8լ�R�d��r�V�D��Zec�V�B��������ä����|���v�f���	�=�+�S�?������l ''������?Ĳ����=�[��s4X���4 ƽ�㣶��o�G���͎�+��[�w��Ƴ"�_�ˋ6�gk��Z�=�O��������������ʃڧ���B�T����Q�����^^���H����Gh��9����)����,�(��'��r�@��[ ]�]�T?t(���x����qX���]����Ro� О�"T��#Ԅ�|
�*��`a�w�g�y���Zۢp�d[�m��vV��n���0����E�g���x����8�7�_�ppv�~���f�Y���ci��tl�on�IՔ��]���o(�\��ȧ�ժY�w{j>��9:>l��9Qs��Q���'�h�"��/+U�jT�u����l���\�x�"5���z�ϥS:���W1,@���]=<�'����\�CbBD]�^Zz?S��E�N<��F�<�gh3����p�^Jd�$	�u�
:�sfR��-"�;�ȻP6��#4�Y�\̂Ř�]?��擦�=���\@�7U"��G�������w8\�!�-�f�"G~^��SlņY�@uM!5n|�� ks.+t:��ձ%ɽ�v}i��`D��������Z��jw�iU(�ܵR�A(���]CV��ae?�&G-��蠌��e���qk�����SnD���oP�����{"csY�m�W�I,����{tn"zϏ�t�j�M�ް��Y�15�$xYX����N��
y�T򟸹%�	
Ҙ�OF�{7��ڔf��:ò��ϳ���J<`n8�P�2S���cj�d�"����(���;C~X��`ft42��k��;j�|�vH��
m���҆�ó��а���Yq`Ō#^�n|�j�"p�c��Z1n	#�E���*� �g��@��)�y}ջ\��ZCr�+Z "QP$eɧuPZ���ԯf�6jI!$�D:8�xM��� 0��E$Y ��\1���I\�I5%��j�=`�?ZN.
����3ZG*6�1Ǜ�7��bQ�J�W�x�C�[>���p\E4�O��%,�!���<Z����O:��Xk¦���M�J�!-��� �jN�O�$��XS�M3����U�BbK,X;��x�qfˉ_���HG9�O%u�+�EjU)�Mv��'�D�fP_�Eo��nLsY�vsZ�-�͛ƈ���V]4M?�G�lF.α���1��Sy�%��5���ԭ�_%��So6�m�^�)MV\� /����(0��U����4fB�b���k�����	4mUV!V?�pK�S��^E���}\wO���jK��s& ҟs�B���^�> yT���0����2+�v�˪�2|�-�x��mpfy�֧�j5�V�d8bT�������?��9���VJ�1.������'�?�4��n��Tb�}�9	c5%��.��R���.��[4��S�|ѷ@K�7rvX	��0��0.�{y*�3;디S�x��
�����u�|�����Ĉ�����0,�,�-6}e)B~!Q��9K�8�'L�8ҰM��͙�(ëNf�k6��rR�T�^mS����"�i����� {���iM8V�\E1Y�u�>�1�C���X�Âa��,���-�{`�qȃ�=$=e�3Du;��/Ut%@Z�X1�.�� �y��3��t��r�9B�'���}�tQ��޾f��\��x����=��'�큭G����ۂ��y3���"�h�tN�Q#�v�s��Eq�g_+U�{�~��o����@��Vl���vNϮX	2!��ſ���7Q�u!��SZ��mID��{d
�0�^�3���EJg!����g�0�n�`;# ����6[���n?B�"u�9��,׷��ĵ�;�zw��n%��@�K9pJ���h��JC�e#$te�\��UD�H<�"�� ѓHW_���p��KL�H�U��t�A$�]�fVpY�#�*�"�vT�ҵ=q#P-<��y]�d:B�Ə5&�����`����H�ʼ�����ۡ�!q欓�� �I=,���cр{���Ќ��Z�ǔ��47ب�w�[�PRG4�iL�0b�=T:�\�M�7�ܓ;�r��i���hY� ���~�s�+���r(���P���q��D����[�C7�ڄ��ؾ�*a��褺/�'VoȑT5����{|���1K��3�~D��x��'M�"OK�j�tW!REi�I���"'䩬�UzN���y7�73��H��?!�_ipo�y�Ɠ�i�<�a��^QJ�u	�E,���H�\(��ڋՅR"��H�]�����Gx?�T��+�L���?���B��й���'E����8ؗ��C��U�}5k�Y�+X�~{�M����B��!mm/�hɫ}�U5���&(p�N��rsj�'YmNާ%B�G�]��(��"mYU�s6�|"fMr+h��TnD`[��ͺ>B����>b�}>du� �}���Q!��B��X��HIXH��{v2�NɎ�c�5���]{?�2�q�ެ�},����wC��eW���������6^B�/.C��d9�+u}��Ia1Z	���"�S�"����o�ʥ4Y[�Cօ2%�����ߧ ��ߧeޛ��k�Un �O46ҷ�Q+���G�v��m�h����	����l�A����>Y��&qU�^�5�˪�~�Ru?*�E�{� .N(5�E�d�=��S�/�~2ѯB��.��E~�%ń�ǽ���!D�C�v�oG�:�y��v�I�쐿&�2�RE5*3��HSTd6ʻ�؛7,&y5�v�L�O�E�
a[�����r���/�d]Ģ=%�V"3�L+��҇� `
K����r
���l�Pq�ĩ���JY�c�S��K�S�L�����#�Fs"h'�*�˳���o�3=�5 oZ�qn��C�>CːJ�k���k)��{�<�2�z�6}��a���
�P���=���RQwbz�"�u5흀��B��|M��sZ�i��T������B�Zsb͝�A�BsjҎ;��0������$�;�%�;�|X�����0_����R]�1��o�Ď��͠�_cC�t���t��ڴ��P<��e	��^��s162�ޔg+�E�ޔ�
ˋ��W7�׊��cZ��6���]Z�Ý���A��/q�b���6���Ȗ8J���-�D�j����F�JXB3½"E�*}��(��?��=�:�+G�s�+0.!��~�>�шR��s���-@ ��=�v��t �5Q��~��q����r<s�K��1�Ly�8p�?��$w0 px���l��(�C~��;��$�bxP3�#��DH��<��t<@��� Y�{�vE_H�!��^���{���^�xohE^��+�ǖ�N;5�`��>2M����]�۱.5I;�+���
y�>9�ŢEk��m)h�wޫ�\+�0���ϔ�=S
��
�ӫ)�b�H�dfJ��	�BS���*(͠]��M��I1(ɂ"�V�K�I�Z3��T���0KM0@���J3�&��R:�/�g���
�B�|�IP��S�yP��>v
{V��N�R����v5/��	9R�ݮ�N4!U�D"a�C^�:���YF ��:ց���[�m+�rۚ��v�Y�����^e[NGUc�Q�ZϺ�a��>D�R�3�Z7�(�`��Pq".+ĪV�Pf9~1��2ݤ������N_�I�H���R u��ٍ��2�&�3�>�Ę#��(4{_d����ǭ�I3Ms���`h��]YGܛ��i�yJ^J�ϲ�����S�,Pq?3*�ܮ,��O�泥��W��ˊ�z�� f;ۙ�S�Bt۪����\�����G�0��@�AGq �c��� �D�?j>tU���o�&ݡ51X������%�����h�T�N��po��$������4�O�ۘ~�X45�<�2�=٧������7I����b��l�l��]l�-�����c��5&�P��L߿D�ѐ$�Hd	/��U��tt�5�wA�Eڣ�M�d��;���ef쏰�A>�z�;��������lۉ &�	~�|'�G?������дs��GM�X�^�����V֫�J��U�T������{m�H?s���C�3F���
n>����?L꺝����f���U���W66+�����;��~�v���f��5��[[J�>��卍����H�I�@A9C��h�cIb���s�/���F䴮�u��{8��%���'���1����bqO}��;%�;�"[y~e��v�c�,�`������۰6֡7����U������j�^��093���Z�=���v0����K�~�aG��r�?�#R�� rw)�&�rG�v,��Ԩ_�����Ć����zG��<t�5\r��� �[ �z��ƦD��g:qo����qcg�2=À�����e���W��3��De$��i�b�ѵ�N�ܪ$�U,-�n�a4��j��~uU�e��,�ocq1�{'*`gc�C63b3����w��#��vL�a�b�\��Ԃ���=0=$�K4U�Wc��"��ֳ��v)�g��`��M��3�Qٳ��;���������66ɫ:6*0m��j�c��Yt��Ƭ|��m:췖�_�ځg�>���i�o|�d��8W܍%o�'6���b<�W��]@�4���u�>��/��F�c�B�|*��°�%N�D�W�(���}0�G�,���4����( W���m���^᦯���7�4.WJ~�j�����9tT_�T����Jm����Ɨ����*���=g)EW���lT
��Y�f;>�0��^Kkȫb���}ƾQ̬��a�1(a�%4M��6��#���SF����7+�Ҋbd�H<��J���臷g����g9D����\��C�kM�é
M5u�e��K1��i>�P����'�:0����H}>�/��XG��)Y��Cg�cZ]^� L��I�W!� �u]��X�w�a�.#�
\����%���SEl����������"t<՝���?�,DG:���,�՘2/���7�iu�O�+���8U�ͨ4��O�6�8u��q�)��}:ѕ�v�;�pԧ�}��=�s{�Nn3�1_�Q2,��ܮ�4[�L�(`���P������ㄏ_T�i@����`L4��L�Ҝ�d����P��^zW�U�"�1�wR��� k-�j7���q+K��N���F��k��JK�&,��)�@�(��B��-��S%�\Eb0�'^u	���r�X�<���7j�卛�#�l��D2��o �dn�q$�%��%^PMHE0��������DHi��X=��� �
����H�J�ATȟ���i�	�՗�9>�,�!�ʆ�x���r������W�4�z������/��Zi΃g� �#�"2�,��;���JZp�Y k7)�8��(�=�fR����b|i�O+�Չ�DP�g�p�4��N)�5rb��db�n�*,��6,r[D1n2�����L�;�Դ��V*�nQ��ٔ^n�y�^p60����>N���B:�\�((|W�p��y1�$���a/-o"n*�!��N��+B 	��$DA>�3'b���t���7P�p*Pވ���8����!�%��K�W<��2������|���!(7��J9���\`� ̛�D�@�3�(z� �1����S�?r4� r{�` ͮ )9��r����U$�P�5�Kl���GW+����+�]2X�ž  [��C'�Eē'_II��8�3�!������xlq!���Y��gd[��H�'�N�����6�:�T�ڴ �+��
�AB�J������7(\_�`?6��N�<_i�F���x�����Ѿ�긹�5WV���p���D�<ӑA�p"ǯ�ëz�`J�D{,i�4�ۯi�cnu���]�i���khl-'Z�m"ܡ��b>�� ]�!�j�{� CǙ��:h�g��}1�~�q���q��5b�y`��H$A�����K�s�������-��h*�E�bTbX���B�l5T�
Ɣ����
��N��1h���1rݜb��<yV(VSl�H��Cr.L�%ӊs�y��**#�u������3�\��U��X�GZ�����K�{���hz�*���J(��ձ?�Qr���:.U�f�����wF;���<�_��Zf��p[R�=�ߦ���Q���PUS�调��3� ��š�>�xc��Ưt�)�
��O�e�2�`�aP=�{�����e����_�2q!�U"�9�)�p�
gI�l:v��"C[��5a���\ZаN�4B4�}R;��I.3�P������/=�>���Y���1�X�}�����V!��Ê#|�I�f�A����^�3ny�.0aK������U�G�_�"� Q��Ҡ�mW��Q,9��b2��z[��mL<���A��5q$��'$�
�."�����j"e
V��a�"�9�ř� x
/���
��qVw�6�2T� ���x����MТA�Ť��]��)�݀�K�W5�{a���_xM#��$$��������}�y�Q�Fq�}eb���9u�#j��0lJ����.,<��U�뙅�!���)�]]����v�g��Q���ck�=��w�DZ\C!���&��Tl%���(�6jF�g�n� �`��B.�\��u��{��f~��BS�7"ZQ8���j��\sm:Y�Y����xă�����0�C�]����3��
s�g띍k�*��f�D���2ΨɗX�x��#'�Ĳ��1}�K]�؄�7��3B��!�[�tݳ��>Ə�R{�r��3N	�y�igR�S2�ǻT���E(�� ͸f�Х"���8*��Lemr#'6E7�N�$Ab�&Įi�%U��%K�I��u)�8�3$w���3FS@W;�4U$rN$���^�� e�� �\9�!fi'O7�1�=���OJg��2!��ꞝ�P��jn)|�(�������^�����1rWj��f�Z�ʅ!j@T!:�#�p(��S��d�8)(җoD�lAo�����Щ��d5W���R��*E�V�3�?����+�<zU�)}<�*�S��<d7�ֿ[U*H7���
���n����ψ��ml�1m,��훧���<5���B�B?�<�J��ԃ`�~_8|����J>�
��	�Gĩ�N;5��be~�9S�&T!�ӌ���u�VW���d�2Vm�-�1�)��u��0i��b(d	e��y���=H���ن[�D�oׂ��A���q�$e��qSA	=I!��}N}~
	��vJ��G��q����(kQ�>�5W�s#3	�P��d���e�W>�^9prE�sg��6-�E�P�?�|[j}\�BCm'�>������ނ���7����ZC�CDM5�����p�: �R�ǌ]�-l�y8�C���+�)x9�\ �Tہj�������|₾�?�Ḩ_��Ƕ�:!4oԴP�y�H�6\�Yy��&n:ИK�4���o01�i�y�3��H�,b^	W�8S��r��ϔ��!�1��;������~���5�p������H`�1څjG�݉�4��FZ`� �')��N_��*_�͚݉e�6lv���柶Pa8������B�K�6����'=�˨kR��	��f��2�FJ�.B��� ��\'�X�E	��MU�֌@�[�f	0�m6��^�;���30~��J�J��Nh���|�ēf�g񵸠M�.���B�"�qF���" ���V�(�B���L��Ý��[ap��U�������
�_���3E��0��=��0�jLM.��RŊ��,X�S�IS�#bu5�87�Tպ�%���bQ����:v^*R�ۚ`T��y!��Z��>*��k�nx�b���)��=��}4�vBD*dr6��t��j��H���ҿ�*�Y��h-s�,D�z��ϖ�*dh��w-V�A0�K%l�ѣL��a��!��%�8�A�J���v.��^���'AQ �V�ء�q�g-`q|6��#bz{��%(T ���<����e
�}��.;t[�1�%ʒ�ט��Q5���K�b���0��+9Ģ3�6Zwyyi��p�^IT��vwZ�V�>�����рn~�����?�������C�4�y�1��G��Yِ㿵��	�_��\_��x���d<����f[�gJ mi��͖�6tS�x�ƞ�*
�Mj�h��%k�5i�i�]�2m�ꡯ����~�ƾrc�f�y�^o��a���������
	���Y|o�g��v`��^��#��hM������lA�V���K{��p���W|�hrn�d�<˱ua�:��"?�lZ�:�7�>;� u�#!�£ǞD���0BC�i���0��������}k���6<V�2�[F�\������.]�̽Ey*f~[hOaB\��J��%�+�����L'��	� h����Y�u*r����_P\���f���:�C:�'p�}���������Ǘ!L�b��\�E��H&VjF= ��M
�ߧ���h����8�=<0 �:r}�Va�����	eL^H���g���~M;�_I#�	k &�&T���0����j�m�ݯ�Ch��O�i�:&�}IE��a�LF�*_���֔QQ�Xn PG��O@��ͼh,K��m
<<]��+ʚ�v��j纱:u�>��H�S��Ux(vb��-����� T\�e:W���4�Y�I������ܹ�7���	�����빈�x>[��+ڏ ��H���4X��:�������U����j��B������ѣ}�������G���O����l ''��'�����cY�,z�� 9��2 u�� ^Lz|�ƌ�����m�����;�s�RS�2��1e�o��?6�׷��a�}���M�� �� ��@�R�L\+����Ă쏲��y�(��]e���$�] �4m�ژ��1�(
w�t�J�O@� Qb�2�wd�s��p�\9�����w���wx{i���(ڕ����o^��__�ثX<�7lY��t�u=RN�Ō�:��{�gu�Fm�z�Eꙥ&�,5h����������ԼJ�A60�	�r�gQ�c-2㟄��d5�|��܈��	�aȯ�Fj^79+B�H<��ˊ&��{o�Z�Z?�L��=ټd ���ؒ��^�CG֏h٫��	�|'z
���pNZaDtש��������L?�Ģa�p��� aI�T;�����^�bF�x�LD��ŗ츏�sМ@�|��;��r� ˝x�A���L}�I����}ͫ!�|����.-N�d.x���ٕ̅�Ɩsa6��֩X��Af�p�(�;�s�	�����F$�l�e�=��NͪeRP��k�Q}9��t���SP~�/�@B�T�����=�r��0�`m�@n��LF}?t��
���\�n�7̐�,��q ��_��U4 ��XZ%�$4prX�扨%d"!bh_EA���db(qC���u��d����� (FZ�f0"2	��v��v"tW`���"C,N�(��h�U_�L��Eiƈ��$>��M��+Cc )g�6X��ԣ���ˋ��`�����Rm�?~���Gh����d��>��Д�#��Q�)���"	8/v��f�B(���O
X+�YZ�?������S�����<�Q��^Y_��6k�\��X�Z�$}��_G����wߩ����ҝ/η�)󿺵����k1�"-��W���<�I��U��	��*X�*�P߾	��:x&���S�1����@z��sG��6��>,�\C;��#/����L��kq�[�Uk[[�wk��X�"����sCn�*<�Btu�.�P����P|���l�ok�m�����x{�l��M1�����b��k��j�[-Ư���s�o:�X��?ݮ���ves}s�i�˯�`~>��y�t���c�������)c�����b�� iq������2�\%�� ������WR9=7g����s��i�L	c��w������_�*W*t��V[��}���sی���b�"Eq*����[�u���^./����Xԧ{����}�R]��C$=0���1��oT��i�76��AR"�=�q��_�,���Iq��ZGy���R����Jmcs����m��{��Xw������yC�����[�4�'N0^'��WF�R��z�s��īǱ1��q��g�\�q�m}	��^"W�Fh�-^�i��)����gl0�~���)�~�?���v�u�|��U`s��?DJ/��:n���*��W�m,��!Ҵ���c����^[��П2���*W���uf?��u�=��1E9��̓���L6~�>׳X�t���-�R5ʵ��k����U"���n%5�5)2H�5��T������e�+��h����n��)�����z6���c}~�J�vxˎ����^Gx��K<>5R��a�Јz7��r�����;�45���� Ju(e��F�
V�E\�ƽ��� P��S^._� Fa��L �9@ KM~)}���LiE!G����#�m'X�C��.�݂�v� ��@��T���S�W��A6�;��v�^Zg ]ڝ|�p��aټhe��~yx܄Ln�a��9}�h��٫/�7�1d|��%Ld���Gfi,�=�n<7��%�:�/"���G�E��8!�c�;�]�r�-�?C,��Y���Y��V�c�$�)�	/�cR)�� 5�L*��:P&W��i�"��xj��X:��K�'������X��V���ok!�=LZ\�y�K?���ߞdYA��P�]�� 
���qS1*��qs�9^��u������+�g���S���^��<��0�}t�쾥'>��z���g��6w�P��LS��w�K?�i��Zb��mn.��$-����?�-_`?�g�~�b�W�0ox���vp���M���w�1�!F��HH�s�8�Wl�� ����S�K���b�����cE
����=3�N�=y�J�p�fǫ��'����}]�=�Nǣ�e��Cby����V[�Xۼ:wv�[����Ƨ�Uaz�p��V	����O�͈�� �c��+������t׆�j�R�4�o��g�B�����o!���ۄ���7<���֎rLQ��@@I�?�S�5#Mf[��5���T�L�(o��Q@���G�d�
�̩R���dE񂇁]y�^��i�6�
�8�f9�z�"��r�W�ĉ����QLQE�	��a�cCk)��-���&׍��[�����]�`J�繰��m�%�bD�kj�)f�������m̶��w]�%� �+�e9�M�o)VA�c���)��Nv1T�a@ۮev��`�Z����j�h��B���cs08q� ����2<�����q�\��(�g�+�Gl�m$qw�y��%?evz�F�>1�0�<r�������+d orJl�:#�.;r/M'��\��[Ʃg��y`y�,�J��7����U�m��V���":�s��uW\�ν��0��Y\��e8mѬ���g��Bq0�k��:Ds7/["�{i���Q Z�r`�����;R�A����u��hԁ*Q�
x,�a����x�E�F��c��7I��'�����"��u���O�\���ͅ���U����A�M���G.F�&��Z]	���{��u�:��y�k�v^�|���8i�O��m������_��H����E�H����,�޺�c��?����:����Z�z�d;����)�yb�$zr�8��4)�c�~��b��=�ʼ�����6�B��F��om�/�$-�?��'��*�P�HOQ�������?idp��t»%�5�A4�[��2aϑ'�d�A����U) �ã�A�}�5��i�`(��ݷ�K�|Z��Jy]�S������t��U=�.z���؆F���)%�Q�౅��oPԳ8iK 隡�U5�����"i�b.uL��^_��m�7�$-��͎�ki��5�j
'�ʩ[(����0�������jѕ�
��:�/�!�����r��6_��3<S��(�뙎�#���_`%�;N��N-vr���ⱚ:��	@Է����B�	���͚i�i�i�i�i�i�i�i�i�i�i�i�i�i�i�i�i�i�iB���[z � 