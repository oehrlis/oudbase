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
� 훟Z ��rI�*��}O>~��p8|r ���&�*\IvS3��9Û	�{�ni�U�Z@��@�-q����9�~s���O�8�����KUf] �)uwe�$TU���ʕ+W���qkO8i��i�������M�/ODoԛ��j�M��z�]BZ�0L� 4|hJ��3�A��p�wޏ�ߟI��{S��N�jp� u̞�zK�9��P�u�@���=@[R�W>�OSC�E�)�,/��=k��,��\�����b8�d׾�G�dl�!�-�O'��ڋ��:������N�Fؤ��A6�V��a8�����?���p��7���U������cw^x>����#��9dͳ�u�wU���}��jzc(ݳ�0*��o���=���l�w�0�[΀X���	�MeX��?��Az8C���LBz�܆.l��5״	�!1����%�g�8^h�5�0���Ɔ㎮�4�-2�|b����tRar.�iHN�ۭ@����{�
�!��0�۵�9�ptjl�$q���ҧ��|X������Um�Z��6!(
!{�:ƈ\�>#���U]�<��k�T��ц_��s�7DL��V`qV�K��;?!4�>�K��؎�잝����|���+e@���^����7�=��>޿%
n��t�����ѡ�w�������fi��{|�;��)����ɂ�)�1�d䝓�?�����_�{;�W����n`	�1���˓��ӳ��Aoge1�:CV���������I����ɟvʵp<)ӗ�������J���Z���R.�O�'�g�������2}B�d�Tô�|�j�!k�1��|�n��%+�ʥ���~ww����� N���X�U��;99:��J2F�&�WS�D��20p�]}C�.�&0��u�1I[w�`22�Y�%׎�a!Ej�j�;�Iy����fo$'���ťO*�W��!�����sR�%� a�����cX�W�o��N�eUBH�"�i�d-��a�;<���*��Rr��Y���|O�ߞ��ҥ R��$���w���ή��&n��p�7~�̡{oȄ���$�tjZ0�؄ؖ�Un�;��	6���G��:ܰ|ΐ� /�R9�F�}���[�|9���Z�v�,�����l�`��/��F���S�)-}��\Z��
�1eXƓ�Z�t���Ki?��ߜ�&����&	i^�xo�l�kX�9������zCNA� ە�db��,�'Ep �6�hN��@�넜��� ��ac��-!���O��ƕ��������`��~y�믥�''�E�9�����P���V��rY���}W2T3�(d���2���o�d�p6 �DV�.��K�0/<��	� Q�|
m�Ti=F%�u5L����\8�0z���uO[����K�jyJ��Yܬ�˹����lpJV����Z�k�i�����>}a������!�sD"��"�$�4�N�����	�9���e0O|�8I֑Gٵ�h�E�
;m�{�ɕ.e�
�{�M��
�J��#�91��ԥ���O�TIהnkH�M�G����U�*�V! �5����ߚ_�J(� (���tR������@U�p�}�ߋ����~b�`���J��z;����ƥጐ{T���� ���#�B��y�N|�/e�of�y����#@�ZU4Rט�߾�}�·�1ے�7���>�6Ǣ\�Z|noXq:���u��2!��WW�8+�X�L��yP� ��U�˖1z�J`4�o�j,p]���o�?#�����o�̗H�$dk-8���N�1�e��R����qGG���%����Z������1;dI���ZO�T��B�+�u �~a�F��L7��q߻ޕ˺���U0��ܤ��ڦ{�][m#C��|T4fN�����fٗ5w:EY�RP���$�jMm�����	/^L�e�(�Ag��|V�)ɪF�+Mav��!A��W�b��Wˑ�0!���_	�nF#�0������_�K%�1�Je�&1[��0���+�j*�ݺ�w�!���Pq�|��7�|�_~C*V��@�V]�ڰ�}\撀�T%+kC���X���H����}x� �9��J��DA#��@�1��%�8X.��3fR�d���`���2����4]��$�P���ޖ�Q�E�+���&e8)���a�RP��;0�{��%�}cB�JǚZ����Z0�L(Ph�FA��8�&��=����K�2��z;�Coh����.?�h�.=��> C��0v��ť�����vo�G.4:1��6�%�j�fp���ӥo�:9������浲��b>&�����!��r����w����{���V��U�̆�;��:Yy&o`�Q�H3R4.1���'�d�(Ub{�i�j\��Q�2YQAs*A��h%ê��^�LL���;��2;����s����c�?�d��]��� ��N	
��!� 1��>c��R�9���f��6�+���$���,��])gJ�oJ�+��/�����wyGn�0��o����v�f#=9|L0WSW�B@e\i�K<g�®�+C߱����U� �'!�}�{�;���+6FqGv����'��Q����v���H���R6�c�X�o��M]�α����;�͆`�1�M=^G�M{�!�A��+�JmU�D(�����|y��.����Й��&�^D jG�7��Kh��_�}<�:��uk���Ml �0�3���ږ f�T-	�:fې��؅�S~�ӷ�K8o!���9Y;vZc��T~)j[J�낄HsܶRwZ�R1-�p�	60��?*(cG��<���v��_�h+UG��p+~��~�ǳ#��X3�ޓ���{�O�;�n�-��^џ��^��^����͎Z;-���_I��]��ajHYW����7�X����5�:���`�{��~��Ѿ&7xa�J�;u��:m���"�^]Y0;-=��ϟ��4�t�C�n�Җ�'�uv�'�o��Y��P6 ��VT��.F�a�H�� cFp��ҧ�w*��Yv�NE%y+�G��ww���'w3���.���w�̹��Ô.�Mk�@��ڬ��]FC��|)$ �������qoHM�X���!��+��!��F�����~;�ϾTo�������щt'����E-��'���T�>��w���Q�~uZuMc��z�������L��т���s%`Xq='3B�/]�{�
�?���Ht����)0�pB�Ĩ(�ئ3����a��%�\��_�2�R5�o���:ܿ"�G����GT��
wJU���T��i����*����^\Y;��}�l�l�T�S:ս����{d/t�UG�:҅�4)t��BG����W�����y��WhHρ_�*�RWyIz��C��П���OB���w;s�%�-Y} j+T(KV���הd�_�<�*�x���Qu��Ѕ��/�!�$ZY|���	E�A��F�-���?��R�$�t��%�6�Ts"5�d)��>R��A�\$Q0!��v���KN���$�����m<���il�d�ڼH�a���=r�}���(##����>�0��K��秫���'sB�u����{��'����rB�x:(t��f�=�+�= e�a1l�n��{S{�f3q��˵r��g)��g�Ca��P���ob �Ж9�Xq(a@�곷��k���[lE��J�^[]��&��O��+wl�%ZZ�x=�Yh�KPe�R��1�K�!z@����*���9���;�}Eɹ�&&(x��G_�P�o]X�7�1C[ ��Ԋ�\
Z��zx�¢z����G֖R�=�VD�w1]��ɛtL\� �k�'b��Vf�>�gPBx�y��ˑ�P-�*��jDm��%+T1�z��c(I���֫ZZ��d���7m�g��(*ѫL�N|V����稜��)��^��D��=U���;Q�J��{��L����E��)(O��
y�/ς�G&qg�YE������O</d���F��QG$�{���#�}�����z�"q`�JQ���a��� �����A8�Y b��2���卷�Z
Dm�<�Q��uU�Ɩ0팁�&w�9����b2n΢��0�^�?��Փ�C�s��n��\���ˣ��.���@�wxSc+#s�r�!�������R��j&j��c���)PbY����ٮq�%���t�K i��\���>�B��L�2��0���e(�-ٴ2�˴�s%�@(鋨D�8�!w��(�p����Qv��XN�ɴ0ա�4 H%�R����^Ğ���q�#H��A�#��F����҇L�y��/>.��ē�������Npa[I�{<��;��]��~��_9��p��}����j9�H��+y袢H��v�^�r3d6�c!��45M>��&�6��
%争9�CP�G$��*��s���k�
�OD������m�������g�Y��}�T�~&��h��R�?Y�~����*�?G�s��u�<ƏxKH�:�Q伮�E0=wHe��\�&��H�
�y�~
�ZU��z~T���?c����/�!�)1g/i:��إ?�z�;�������,������.���=)�����N�R�h's�!�F�y�A�s֠�7���|]ڨ�Q�V����*{�/Oz����~��{���tr�ŅN.����-tr��ʗ����Jn��[(��M)��vi��B�v�B��P��Y)�.���Hn;����C�цp�b�Le��P�]���Bk4���-�F�Z��znA�Q�A
Qp.�~$slۗ|*��^��l�P*.=J;��I��V�E�5�cNGi�\��{�RQ|��������$�˛�z�h7� g�8�Me�#� ܬ���/�/�������c��A�P�(��Wx��Q�P��U8nBFau�vS}�I�Ua�E\��|`x5���?�7���B
Y�R�=L�ǩ*o~����R�8��N�;���.��2�$������i�JT+n7>}�Z����tY9<*�7o\�T�<�,ЇEfv���P�ӂꢲ�(ɚ;~\G�/=w��Ӹ@�� ���q�aZH��'s���d=\���Ďy/�_��y���5�@\���[��2:�1mh��*��(t�f���t�NY�ǩ�r��]����=�F/9�C5�仉c�s�(s�c>Z	��ŵ��5�_d.�[(/�P�k��B�|e��?�2����p���NCC%���[:��Հx#�u`��t����!n����xFy($h��},R�`��$�F�I��^�	��of�q��]zS�����j�A�h�z�Ŏ���$Uo޼B���s��~�	��g���A꘭��iM�����NGouu��v�]�?J���Ϟ��'O����҄��-��ß�����_��잞��_����?�"��������'�
��1�����BT Ƴ���>���_O���76Lw@�x#��gy޿ay�u"/�0F��k��<�+��?`���?��7��?
�}�I���@u�^���i$���(��c������D��?g�&����h'`��R��F2�la�V Z�
Ă��D�A/�6 O�C<4NK�� 4���m?�B����Bhs����O�\�����+��H��;�^s7�x�ַi8k�[�t듘vU��^H��(v�,��\���������EY:����=��9y��A{������x~��7�kL@�s35Q[c�r|���]�_�ɕE*���� �F�o����}�o����<��g�������#g���6��(~)��-f��"��b��v{��o�1��.�C@o/�R�[Y���R&v�Vs)W�<�te-e����W��򐨩���^v��\ԛBn� �70�)��\vh��B����<7�i��x�{���K�Z��%�O�v߼<�{1�&d���&�B�2_��j��WU-�����323��I����^�}<��<H˥$@l܎��_FΘ����bnnd���!���o���fHO�IM�f��]�JrX;1XZE^^ڱYWk���E8X�&�j8���3F-�(,]6*��F�ΨK 1d~�E��S�曘¦ϡ��
#X�</aKB�:7�z%���w zH���ǁS�!�0n�;�B��&OG�F?v��� A����Ì_0ȑއ:�	:��*Q�E�:n�v& +D3[x>�4�U�����W���A���k��_��#�j�*ŧ�K�ȥҪ����RƸB�澕*4W���ﺢ���-+�Ѹ4��"�F�(T������OgL���-�F$�Ae�ڜl8�!?^
�l�0�&��'��B@���~�ڧA�&U�w#CT��mNi3j�TF)���V�'���µ����GH���p�e�MY��os X�|;��.ѓ���^~��Z}̌��Z��l8R��h�H�B�cĈoG�b���M���ߢ����P�-ã^9�5�6BwB�������.�D����v�8�1�s#�Ea1�\�G��P3�H �'x���|���^�X��*3�D�A�8"�ψ&�&R��P&_�����ChzޚC��1�1Y;�-�2D����Ec�]�<e%S�1�!)��d��2Ҋ%�"�m&� 97��_���wu��B���S]p��k�w�Z��mG	̙&��ʔʯ�ߡ1���x��u|i �t`\�M5'���"3Fk�T�7�U{G����z��^�sMX� �(��!�I2#Q��d��0�l��H��Ҵ��<Gd*�'�[��xra*9Y�yN�nԥ��5�
�W���~;��*��Gb�6�e�'�u���q��`5��4z�UQ��5��J�FJ���
C�*:�� ��|_΢y�}t��T��@/a�r��8�D�c�x���0EP5I�+a�cx�H�E�T%�6բ�=��R00�2�?xwk��÷���]�l�8F����&d��Bu&a��HR�<�{J�$�<��ґ��b#��[��d��k�m�ʡ�a�-��xN�bu1B ��T��/�ÛȰ.	=����ѽ(v�3@Nv�ӳ ��+�u:>`S��z`��	�~!�@8���M/u'gq�3��5b��8�`��9�i9}��x��Ǩ�����X��+. zvF�&,s3O�BabxUc�s��X����x���m!#�zg�r�Ym���z����Ђ�y�������a<Z^e�"��.W8Ź�=n���otE$��{Qq�7̑}F��@X&�@Q�;U��g�����yy��	2j��Vm�t�3|��][�Gy=U��Q�����D�0�J���gT��gU�,�&�,���=&�H���t��d�i־��g=���Sٻ��"3;�E�
�Hv��(p�;�ź~��.���n�K؜��M��Ԧٮ�$��mZ%]�q��ߞ�5�u��3���
�KY[K���l��Iz۔wL��rE��|����N=�_�5O���N��,~�Wy99�J�H%�.������#�X�S!-�.\�d�p�'^���
��
�>] I��R������* ��k��;�r�uW��|���LP283Zy\�H�J(?1�W�7�G"&IÞ, ��@2ϙ����W�V@���u��M6�� O��qI$���z啵=�=\�dB���"�D�)"�W�ٴś�t���CR3iF?�$I;�dq ��fM�b����`8�!£�О�ء��=����\K�U��|��s��6��9�������&=]�n������̬�=���:��eP�0*nP	F������M����Q���;u��֌���u��v� �bb�����M�SA|2�y���5ݧ���]ݏ*����|��ޝ�P��7��S�H6���*��V�4�u��D7Rφ�e�L+`��V���FQ��OCN8���R�P��k��ׇo�܆�ʖ���L&S�Bmx�}F��nG���D.\���<���𽍰.��W��Mˊ�r"���^VT\�Z��w*R�FE�-��t��m���R���DL�T��y/zl����:�C(g	Qs�N^	��-�԰����E����U��S��E/��[R$	��H���gk��I��
��+����MPi)H�P�T�K\�$雌�ұ�tMH��M��sB������!Dth���F;'/�ɏ�'���R�ޝ�ޏ&��hyRȚ#aM�J
�R"�D^Yj�)���'�9�I�DRB�O>�(>��6����v8���GTe��[X����n����fs�<���\�I<]��g��pW$JZR�%
�̷o���w;��m	�#��^Q��,�mQn԰�dO�=P\nI-~�<��i�-�P�|a�2D���+�",Md'oK6Ft"��v'h咐X�`{���φ3L�����1�2+��� �}ο7q!�B��D�HwPJ;�R���SMʌ��>�]iJٕ�K(떫͊�'�}�d7��Dv�rN�.��.!V�%���*[M�S����ݒ5I$F)!�OQ��q������f�N�\�U.�kH��u�ˢ3��ީ��}V �Y��}Vv�ٙ�ὒ]�""6Zw� ~':��܋�p����Ϳ7���h�(D�R�	Q
3`n1x;%i�+�V���"�;.�)��L(l�$�C%��qH�/���R<��L���ܝIVM��G�#�����\2�(H�Z'4�,_XT���?Bd�$��S���2�)~�c��Tǐz#��0+�D�"S�6G�H�>#��;�����{���;�O!�\2X�>[�Y[-�����gT��gYtJ��ra�=E+���u ��R{[��f@������ߍ��U�5~VΐR�|��Jރa*G�o��}��b�ԙX�\=�C�إ��� _���������}��.fD��
��Y<�����<`�}��ٔ+O�pؼ��? Ӥ3���?�x���MOZ$��K���B.�+]PD?JTRc!�$Y���~���Ix�4'����(��&���c�=b���v�)=]���wb�����{�`��կ�+1t�Ǭ��{���p=26B�b��m�E�j��!�r�ߤ@Q�86�<������[HLF����6�e,�H^<�����Y�S��Am�o��]���\So�A��1߹�{��a�����!��O��pW�3��L5,%�a�Oq�R��|�����2�"Pj����{0�k0/������v�F�"�^�����0��� �p���L���JD���ˠ/nt+��]ϭHYh�W�e���٘'ځ�MB�|O�O�&zP���>?�4?T͕���M\b�����P"�	F�V��7�t=% ۺ���B�Ń�Z^l 9���vY��pE�P��/S;@��%�����!
[��ؘшk_)w^̙�7���Y��du.�B�k]��i�(Wr#i��)u�9����j$
�[�9��x�FhN��U�9E����DLEs1Ɖ�Q���$�Ty˻ָ��̬�S�z��$޹+�I�33���#�0=YaIf9�3�M����D�f��.��Q�G��5��WTՃlm��z.�����Kż��{��]Pr�1{Nk���T��N��"a�YN�����`��=�!�Z���9\6f���b ��3��.`�j붤ں���n�@��$����~�C՝sSD&�޷/؋ibe8��`p_�����8�aKT-9�ϋܶ��#�όb.N��*~�g!T#ф3�k��rk�'2�]�*�r��g_	K$ΟI���x��|��F��Q�����#>�E������HF5"�C�,*ȋ"�}�����@����ʢk�;Dϝ����}�1M�0�&�BH�b�qK�iT���T�_�6����S��c��-��cC�l��;��"F���#�y�}��E�ق@UOaxxGGb�ۜ�R���g�|�n�*�w[�Ӷ�	��nwr[z���ش�gݡC$糲#+�3�+�6u/街N(�L��� ��E+磍�ے�>v��$`�kT2{�=�� �52��a�"���M8 ��:�A�����5gH��$? ��xxSs�3��3ړ���,��S��̟rg�Y��6,6������-�F^V�nF�1�1��d{b�^�P��#�SE�Y�V�q6����0�(}��b��\���*�Ȍ��T]��P	�&�ķM�����T�X|0E�sc#R`����g)\@�s��)$�3k]Ǽ�o/)��5�m>!��n�_y�'�8����c��� _�f��7:9�����ъ�_���R������ZTdD/�q���z�������k�_X�o9?	�%g<��[�V\�A=������+��
Ro[�0�i�1�Ә�A�tG���Bq> T���������G�=��hOы6��%:�E���3��N8���W���7�C"z�#��h�G�ۢ�X�-��ᑔ�`�T���z��#���1�?P���A�#�:�t؟�6lþ��Fe��NJ��AำA3��Q�c�,�ՅcRm"�I]�7F��E�2�#(#e�ٵ�NTK�gi�aqh�'�Lp��=�b�={Ƈe��f��)7�d��(���5�Vg�a�.d��A�OM:���/��>U;ͨ#�9cgd���W����"@�p"ߖ��U�G3_�N�.��yLQ���1#��}ǝ~ �����U��]U4-wb���Cǎ��捾u�����Z?􁩼���B=2�S�N�{�����Hh ���)�2M'��<ԣS���	�Q���n�z=:�_$�	�v��*��D�WZQ�)����Z��`�z�|AC���� dB�������|�V`�#���ׂX�V-]�\�0PYE�+z�Lon�7�[��S��)F���7$E׾�D��묙y�x�f��	j)1bgK�1g~��FVC~�\\����� ��;2�NTB��?Gh�����A�N����̊洢�Ч�3Y1��L�����]想]��@�,ݱg��%�T�&�D�dUr�[%:�>�뉅*�Qռ$�fՁ��&�e�s�≙Kt���ԑ5aIE�X�Ϋ�bU�S�*h ��*��\��w�������!mN$Cd,��	��_����Qu��6��p0o �l ��x8^�Q%�e��QǫF?���՘�.���"�Yu�O�+u�"ޑ�ͩ4�Tɨ6�8w�gQ�9��}6��Ǝe�l���u?�Hߝ��{�t��&�p<I�q#�7�RiOޚ�e�h�P���#n�lEz|N">~��g�UϞq�D[iל����c�xd(me�~�;�3�&�1�I����i]�7��t,΀�!������,kt�+|#��F�J��	�=߆�h5�>j�5g/XK����L�w�$ƩW����Y���}�kۭ�ֺ?�W��&8���~�%�� ����Y��	�ft�]�S$��.!%��	)�^��$�`6�C��v ��\o�g�Ͳ�MW_�6@(K�,�!��F�x���r)Kb^g��t�x?U[M���/��JiF�� �.w�y�E@��ѹ�jJ �E +6�K�e�M>�W��z�W7�ڙޮτ�Mc^>�	��kԽlXR����xd�H`!��"�C1��6k�����Z�٥�-ŬRijp��篦�r��삋���]d���md׏l#�\wͮ��^e��`���q9%���5+-o"y�� %���C�!� f�X�>�7��_�.I�]I�oHo�0��ݮ�L�G�.p��"����^�ҿ�1����g�"\������ �FΠV�UY+Eѩ��K~�-�M 0UK~SE������� y�cf�ٙ2^���4[�\�@��[���_��3�p���uL;�]X?�$�  Y�Ã��,VkX:p�g�@6'���fb�͘t�?��l[��Ⱦ(�":Sv�z^�m%R_.��F�Y��J���w�!ZCR�~W�)YK4�n�$f�v �S:`�ƈ��S�t
~G��D�X��6��4��7Q��(��Ƙ͋/����Ed�(�(	m����r�Ĝ@���r�H]�]^��eU�F��tw���ߨ�܃Ìh��ZC�y�Тo3ᎍ�6	�n�
]{Q���"̑q�!�wQc5�\̤x乣k��AhO�1���(��v����R�������gU�̫��|��lT�a��]ȳH��	Sή�LP�w��Ȃј�r��!���y�ųF�/�Q�+�?B��9�d^q�:O��QId�c���'��b���:�k<WZ(����+����hD!���Ƣ�i0��4���ɸd)Z=�(��Pa��#��f$�e`�r	�-$�#�}�M�}_�*��*��a�@��7��bqh�j@L�N6����aa��h!�U�Q-Z���rF�rhĥsIE���/�������w��AZ8�=:Js��m	�W�pV�lh��B�hq�>������)�{f�bE]B�
S�S-�>Q$�>�]���T�d�P�#��o0cL�e����^��+|��9��YGY�M�q���N����	aC��qZ	K;�"Z�U�!~�J�<����/&� o+s;�b���<bS7��z�_ɰ��k�j�0���	=����*,eƨ��!9��E0s0N�^lT������Y�u>a��9@J9�����ꛠF����lUɾǻ��݀�+�w5��|i�J�_�L�ĬA��de$pe���^V��)��͝�C�IlI`̈ܦ{L��h�g�Ko��.J	��F�+��|2�pk�� ��2ӭ��*����{�?�?�bВ
1h9��1s�R}K��g�Z5�3�\wo �`$��"*�T��u���g��f~b�®$o�aE� ����~Q͍�hE��D�d|OI+�tKip�x,b2L�f�.M����+8�ru�W#���{���S���ݜd��IBM��ŏ�h�:;���܌��]�Gfd�]&���/�7Ȋiy���>&��2{�q��+��.�Y�YwR�[3���T-_�Wɛ�=E�gR�K�jԼ�UQ����9�yȺ	r*8	�V)L�"Z��]ܲT����P�؛�!�g(ߍ��s����E��,1�sb�4b���'����+�:Yz��7RGVyLl�����b��oe���{~�m��(m�ͭEoSe�\SRur����;PV:��R����^K�B�1��+D�yA�NEt{J����$�+����dAm�'�:Lt8%u���ʳ��^Z��d�J�e ��*�r�j��J1�ZU~ʞZ,��UA�7�տ;U�Q7��>]*U�<��ȏ�hS�i]��{��E�'g�� �P�p�X���S�E0N#�o\v���ۢ�9]��j�5!�8��Y���f���;#�B�*�{��3�u�%C�,ݲ�E9�+[mB}`μ2�A&.��j��2Y\�@[��c��x�j�#V��wkA~�$�`�@<a�oRUP@O�@���C�	~
Ԕv
���VP�d/�PQަ�|�j��Jd��|]�d��8�|4�r��+��-V3=�|P"N`���x����.N<}�K��������oǳK�h���-���� �(�* ��&�]C�=��v_0@7c\�Cey�*'P�X�qn�J��y�.�y�JM,�T�	.y�M� %�g�ej��%�d�KJ��M���f㳘5r<�|��)���+�W�rRN�}��b9���X���"������Ĉ����}�`�9��hG�ݩ�%��"-�� �'��:ϑ�
_�ݩÚmv����?e���᲋K�[S�5D2)�Im��o[�N�l /�J�I>��HShYCD+�oT�g!8�����sӄ�0iPfzP�@3E�� P�,����}[&�+�������1v-�����3�>�3��8�+����˃R<MD���4gD��<�3a��3�Uy	!^:^.D������-���*�M��D��
�^�aMR��f�&Q\,g��aHՄ�~(��BĊI����q���8�����2UI�.r�ie�X䬠������E��XD!G�x��1����B�،Ӌ�\���Q���N=�T��zBU��`z��O
(��@��-�n&�-��:�F0R)�E.�J` x�N�x��UD[���0�۵6�zN3�8�k�[Z�sVh����]*=#?�'{C� x��?r"��˺�Ń�`�0W���-�נ�:�}�ċ�,P�M�{e��K�U`��آl�y���zU��?yS )���k&tr-��!FH���A뮮��X����.�����{ �x�����f��/ϫ��f�д&<�(E��U/�?<F*EL׉��%Z�d��^Z��g������_�NKD�ZC�h�-��x�O�4�>-I6�s��c&����W��!꘳��F3���	����i��i�ms�n7[v����A��6���]o�f�v��w�Z�~@7��a7���a��Y��3l4�a��5�����޲ÁT:��9�7���hh����v��j7����7fgk ��VːAH�
��4Z��ЪoZ�҇m[k�-�%Ko֦Ѱ���\:6m�Ԡ5u��v{K���@��-�c[���j�V{(�*���nnv6�W߬k��-�c�(��ڴ��ivL,���n��F}��2��vǀ�k��h�z�^����`��U �l���l6[́�iC�M(jov��>@����6���%㊭Mm������@���#�jXC�n����16[m}�io�[�a�h��cd�v���lu͖�%�6��@omvZ��Zgkk�j�K[�N��ց��#�y&	�P��mt,���lf��׷ͦm� ڛ��
+۪�63���P�VkMS̺i��hٺ>�4�f��h���5khviP�1�ݶ�a���6����	�V��uS46mM7;�V=�A�--{˲�&L�f���jh0׭A�h�$�z{�Hߴ�V�|�6�=8wĽ��ba
@��ް[�[H���`��7�6L���iM�Is��C�V4u�f�z]�u�l5u��Y�z��5VK��u�no�~�����y���l�;�`8 ������hm���Q��K-�l�F�h����h躶e���nZ��j6k,a�To�@M���8�h��a�i����0u��- �ɮd�@�vC������67�C�BÚ�@|�Z����tId�.7;�P�&ov����w&����5��2F��!�/rqN籸>l��f�zc�Uo��-�l�p�h�7��nl�.��-�o5[�@j�Fs84�v݂1�`j�ôP�р�~\<御=hkP�f�c7�V�i��c�ii�A� :�j��ŶJՒn8��˛�9��Ҩo�Z���ݶ-�v�L����8�-��""?4����G����z��l����HYز���7m��G>��N�U�������r��9�2�O�ʞ�MV�6rS�}�A^�"^r�b�OoB啿%}.�\{��_�2}�>G_uA�A`����rC^æ�����_9�O���'��h������Rˇ��ix���{?���%GT�B�<;XGS7xWe�߇|P*�{�F�W�� |��&/����^�ȀX����]#�E|`ٔ��Tk�[\����a�Q�d$B-CP���cm�l~O��b�0��kD:�˝"�'��A;��mxԷ�Z�Z��6!�!{������P^0��w�����B�3��P����9�W#�t�F�p JU��Ph��$�p��:�\W �+,����i���CTҤ�\t������<z\!�	M��b�ht߉H5�����&��9����?{��zt���ӽ��*d���� pd�db�ǄfL;$������z+Z�>p�%	����`��,�R�"`��6��T}!�UKg������Gj�r�پ�"��aY'O�ʕ����NK�Y�T�nPDɟ�Z��s'�4%�K�[J�P��*/Ҭi�S�Q��כ�S��£u��%�C��L(���^n�R����4�/�q�*��m	lz�\]:5�&s�?�U	�H8���IH���y��v���]o �?
��Q������>yr`��O�^P|��o�O�����Yd������	���D���W�9T��]׉�����q3������o�ǿ�W?������c���t�fb�7:�F��#=����$ ?S@���- P]���n�����F�O�̲�����tDHK�)����l��P5J��3|zh!� F@���1����+���}e�t�����f����w�b�q���������^l����q�ޑU�Ӵ.Q@�/Fv��8�`G��)!'��d���2��qXJV:�{��W�0��6AqNo79�"#��;��'��҉� ^��h��b�;;�������E����ź,Iv�N��D7\J���K zOmr pC� t�E���;�B�N�Ί�g'�3xީx,�EˍH�����?�ҟJ�a�pW��(�i�;E1ةҶ��badq�+1�_q�>���A�ȁ\��v	ו"�jZ� ˌ�ƙ��Xuq��S"�W'P��LI���_��2�f�U�f��@Y	�o�r.$�\�\΅T!��K��9���@VeĬ )U*���P�'xIW�l�T��>���h?�_��!)��Nl}@�:�2�.��(�9ō�lE�MS�BI�=���P
Z�f{g ���I�YY?�gwG�H���NGCz�Ҝ���+��1�6a�(/!���F՝�Q��Ϡ~�y��1�(���>:V����v^�\�'`,ʔ�k}��'��Q7F>k�(��W{�՞`ĳ��=��<h䒺�{�NX_�QOCȄ0!��-m�B�1����}��ԀJ*�p; �P����-�$�wVs�ϴ�h����m|�6��Z4k�D��K�����an����upa 0R1IR���9��U.Iy����5����5˾���x�_:��꥓��X.�9���_YKoY�L�z�Qo�����jt
�ϣ�/\��r����o/�ޫ�E�L�:�˭c���w:���������~^������V�3��IQ��*�߽	?wq�B���'>#�)��G|���K��S�}XJr�v���f5���������mhhС��_�4��Q�SJ`%��L��,�^�:�.�P����cX���!��Go��m�
���{"	�ķ6��������`�r����{=�ܛ�JOo��H)���76���v��݄���� �ץ!�m��:�����d��������QRa��Y�?�V�?W�?�$�Q/,@f6`������%��_��:�;z������%4W~�:�����ov4]����Na��)6��:�������wp����H	+R����S���$ե��Ա��oh���Q��V�U��c�������]A��)ǅ�R�#��5�����v����j6����1�S��O=���~�ε�0�-��!�oF��������L!ڤ
��uő���P��o��R�{���
���BC]T#U_����K�W�w�s��E��c�g�uɾ���������q��v�v��?FJ9�{�:��u���:x�۬7��Q�<Ǎ˨c��h4���N�h(��hu���#-Kf����s�����F�:��37��缓K^�%]�.�.N)����-�S��U���~K^����4�����%�42`�-󢌇���z���D�j�����}L�̱=�,L��%�mr�`x�=r�n���
ǅ�c~��r�AAm:A5pĔӣݣjܻ%���!^ 1ޙ��%��ڞд��<o���Vy\���Aou���k�3V��. L��ٹ �p� 0���X�*(���Ԋ��1�F\D@t�p-	�Y1�u��Y��.
�H��U��ߗ����S<��u��}��`�+{ ܥc���Ê�ʖy+����G'�p�)M|l�*�o��6����jb0�Nd�⒧����c�$���n27�c%���p����	�/��	�ɍ#�c�����b��7�$�7k��Q<�h��q�(�T��	+�ǬR�)2B*�2� �ԡ����W*���8�> ՁQ:��[��r�/��9�삩�_���'F�m�����"#�zsX�]J�q�Ƕ�Ы���	�����dT�����3J�
>��ce��6���	����>�	�iч��	~j���M!�����$ˮc��������v���(�����Q+O ?zf�Y��R��ʶߏ��p�ф�[qo��1zt�#/\�/�r��[�����1v#�^�8���JH^���'�1���!�50��y�����DΎ�����K0|������i�b����Q�hl47Z�;���˓�A�����*W�x�����H>[t��ؐ��Ͻ�4',�R����X�g��ZM�C����_��=|ZڂE��[� ~F�kG>�"qg���ÂB>�[�f�l*�����̑	Z�
c1	�% �X2�G�7s2&���F��e�%.ɛ FZ�-��6��pDl��š=MtT��D9�+5��"�F��Wa�5�Qlh-���b;�>uF'���5z��^%]�GX��^�s߃u�(qz�&�"NX�AI�$,�z#s��|��G�I`�	����x7���D=6�>+�QA�d�h������[�a��]��X���j���)C%cÝ���������!{3���,�
�$��)���Զ����H�vU���~�*�8�l]�*|����7b0 ��]�	��ҮͰ�� %�eC�{����<�}���K�ah�ɗ�����J��{'p`��%�c��ѩ^���yn�{(�,Z�;I��-��߃�.[�/�K��Iq��ek��x����7����Mdp�.�2|�hN��`%�Wa�8	yGG��;��(t*X�Ͻ��&�e��:���?۝f��QR�����Y����?�?���E��"�g�s9Դ���PR�NP�~0Ybs�4���z��luE��GI?�_��ޕN�`��f׻���zUc��~x�;��|W��^�9�;��ٛc�����w{ݳ�?1��s���;Cc,׊�H�����v9g�wZ�;���m����:�B��QR�����Y��\�����"�g����Y���g��[���sv��ǋ����@o�tf��[ES] ^��0�Y�,gž�
s�P˹�0煹\z$˙�3���M�4鱈�9'6f�7��s�N	��o����-��y�_x�4�_�S�<Jr�K8�Z;�9O�NQ|�Jȹ��+Z`���E�o���Zn$�y���?;��V���H�����Y��,����S���3��?@$�y������:����T���u��L���:��O��l�:�b�?F*�?���E������?+_��+���������\�����V'���j"��i7
��GI����G��
 qz( Ѡg8�؈��[X�ø��B��� ��x��Z��j�������H.�%҄_�7Yv�@$nu��w��?��w�tՠ)c�G�^ݬjgz�Y+��?��(�� ��B��\}T,�,�2u�����9%�I����q�nQԷj ٞA~��A�q&��v_,��y���H���h�z��=F*.i��N�j�����r!��u-b�)����"�OJq~-}K�e����爇����%��&�˒7@�R� S�s��!�/��0���C��`#�	9��t�DM������~���`�΅�>�
��&ME*R��T�"�HE*R��T�"�HE*R��T�"�HE*R��T�"�HE*R��T�")'�oݰ�� 0 