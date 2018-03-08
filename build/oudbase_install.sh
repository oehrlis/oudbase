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
� ���Z �]s�H� ��;�O��0111�M�Z�[$~Jr�ݴE�ԭ����v� H�Ll ����1��3�����`��/���y�����	��(�UT�&�̓'3O�<y�|����M�Z���6ٿZ�����k�zMk6z�h��hV���C#��$P	<{f9(������#��g��`���u�'A9�x�6f���������:�?�B�	� ���+����T�zFpQX!��= mu��!�K{�;�����z����kٳ/�7�nH~K�����C��b��u��=�}�	B��T�7ɖި��C#{�d0�$�+'�����k-�#cd�ٳC�?�'������7\rl_�C��{v�A����w� �Mo�;�F�W� |ya��zq͆����+rj_:�㹩"�V�d⏽�f�^ ͐��;㐄��υM��6a=$F@|;����,G��@`sv�0�id8��L�"}�'�{���K'&������4?Q��0����q�S��䤇�Sa# ���>�0<�;�*Ͽށ��^ֶ�UMoB����:�cɥ��0B�Z�u,�e�֏��p�m���=�x}��h�g���F���b��^�?��v�f������|�hw���m�T�	��ʞ?(�P:��}�?
n��d�����ѡ��������.�fa�}r�9��-����ɂ�
Ю��d�H߁�xlc�/������A���6z��WS�������Q��������!��F����|o�������ϻ�J8��W����'��ME�^^]-�g�ӳ��:���n�~C�d�Tô�~�Z�!��3
��|�n6�%�O�����A{o����M���X�e��9==>��
2E�&�W�D��10p�]}}�y{}�|J��='�kV`ɭ#9ETH������)��:&;����$�-]\���oqu�M��<'�=�-���|��}>��~���+ ���}V#��.���6N�C�F��÷)�/��g��)�����m~�ۏo���I�� R��G��%��1��=ǷM�$ȡ�Bo�)�2���!c���)�Sӂ��M�m�Y��eO��:8~��ᆕs��-��oHi�����[�|9���Z�qℬ������^+�%8^v}���}�pSX�^���a1:#*�����騯o>�~���9�MR�f��M�d]�M@���a1�ҳ����	������+#�� �2Y�OJ��|7	lnќ�)nr��9::<������͟KߌJ�X��|�����7��ƳgR����U�9��������U��bQ.���(g<��f��tCC
�)�]�ŀ�bE��0�,mü�|��.�"��6)�z�j*�j6��,)�1�p�a����=����Kq�<����,F+�rn�2{8�RT�i�����i޴�i{�<�O_��g#���=�X��!�PD��� �1�A�^�?:�G�6�቏g�:�㨸���]a�MI�2�ҥ��Q�x�I^�CA��p$c�M\*��`�G�L���&t[C�nz>�f�,7Q]�	���־�(��\��TB� 1��]/���vF��g�7��/���H�9��&zn��m'�C
Xyi\��G�?�>�Ko2�(�Л��ć�R��`��a�w���;��2����v=��;�pއ�ٖ\�>�~��a��Jj���a�����E���Lo42\\��@�3���A=t��JVi)[��Eh+A�8nQ�T�6c��A�6��=��A�/�hI(��Xp<a��Jc��:��	����qGǔ�YIT���
�hC#d�G�%´��8���dW��$ ���=e��~.�y�~p�+�u}��W��BQr�b�*N��Ȼ��F�����j,��#d�yŲ/+�d8�����RP���$�jMlT�����	/^L2t���j>-�d5#���0��Ԑ!��+p����hV���kH﯇h�6#���1R�XXQx��B�ŘH��S��X,ɁSQ�*�5��nU�λ}��B�;4�Ow���ϟ�ߐ���YFPiUנ5l� ���`/���z�`�%��>0RBo$��A�!H~����1Q�3�t��b	�#l���T�*�d�{X�E�����8MW�(�.��'���hF�q���3�IN*f��cԿ�e��^�w��C���ұ�V�3~���������(�#�P�Ĝ���R5t�S���dB\o;��@�j�����Í���C��1��c�!^�\\:;{;?�tv|�B�c��,`]2��&m�	9]��� ��2!#���мV��=,��{SJ�(J�*�)e�r�99��>�˅V��*���^t�JV��=�E�B���KAbi�E)Y�
e���^n�
�"`\�HVUМK��$Zɰ�������ں���qs��F��p2���:�)c� �!�2�S��do�3XL���X)g��`������M�ʆ��2I�+D$�C�>�Z�B��j�K ����=ޑ6L��[d���]�^KO�����pلT�$�/Y*���R�wl��kx�z%`@�qH?�����C�Sx��(�����^�}"�����i���JTI
/d�8v�!{:��JqN%�P���o6,����n��:o�KY*Y��*k2%B�=؞^�(K����|4���6��"Q9��)�^B�c��j��ѳ��έ�ʳ�)�������^jG���ZIP�	ۆ���.TV��O��/ἅ�ו�d} �2`c��T~)j[J���HsҶ�vZ�r1-)p�	60��?*�cG��<��O�_�h+UG�1�p��~�i���c��X7�>�����G�N���wn���^я�g����O;/a{�՟���no�t�7R�K۲|��
r��*�z������y�|�N���������p�g�/,>�C	}��8٠�*�.�Օ���S���)JO�NGI��F,m��t��n�t�Mc>;K�*�_�*�&`�Ѕ��2��td��~U���N��2��ݩ�&o��D��������L��k�ld��+s���aJ��Mk�B��Z���]�C�g|)$ ������3N�7��X,�Zo���h�UTC\���Lb��Wg_�7�
�b��K��D��d�Kۢ���?�����}��Z]���7|j5��������1�����G�b�͍�E���,�t��2��@��z-Y�qC߳& `�	9R�"�`l�N�:�ÇAX���r�����K������p��L��^;�ZI�&�)S��sR�o��W��l��^{qc�4��ِ���`J�T��ڇ�3$\�]=��~Ti��H�6�$���m�si�"�z�Uv4�S7��Bz��V����K���V����/�~�v��ߝk-9�В�@��܄�T�d#J x{KIv��Ƀ�B�v��5�|[�����4@��B�e?��6��۬�#��ƃ�Q.�N�oJ��^bn3X5gRCI���##���e�EJi蜽��A�p ь�ӷ�4k����	�=��"a�vW{��b7�PFA:��]4`v]�d�/+k���gs�:l;齈���#��Q%!D�
�w}���=�2��b��>k�T���L\k�r�ܸ#�YJX|Msȡ�RG��^�ob ��9�Xu(c@���w�w����;Ģ�t��N��m�]�Qш�Mѕ�6�/-r���,��5��a!���k��}���F������k_Qv	�[���7�;�V��v���,<��5��Vd�ޘxh����au���ꑷ�Ty����UQ�}�AWc@A��&�� ��}��b�٫��;(�<P��r$(�ʲ(�q[fz�*�L���J�+,{�J+�4o�����-�l�D%~�)݉�U)/n@�{��gE{J��~���4�C�@M���OU�����c����e�w�o�����^��� �Q�A�Y�eV���8� �S�7�v��nV��A�^{�v�74�;�߯m�8���憪r�!��/|�ً]��Sސ V�,�VyW�|W��@T�q�
|�P�ll���x�r7[r?_�$&��<B�	�2����[=�;�4����ŽN�9i�<><l���D�G7�4�`1�J^�NP����]�B��Yh��<�XQ�˂#;e4���k�1_��7�58/�E�6re�#��*B`V�ɕ�O�^0^��ؒM+��Lk?W#􀒾�Jt�Kr�:�WϰK!�;eǖ��T��
S��# ��U9>��D��T��"N|I�@>H|$�����*�T�O����%��x���1��	.l+�~�'^Ѷ�cǲ�+w�O��+V]N����նU.F��6}u��$��]������9�X��KuM����ɥ�sS��^71�t
�$�]e�r��r�Wa��D<����F-���k-������������_��3Zp��O֡_��g��ϱ��.k-�̡�#�ұp��+nL��S]2|/Ev��s��i�~�ZY��F~T�ҳ?�`��,�!�)1g/k:�ۅ?u:'�������&�,�����.��=. ����n�T����V���WCc�[���-hC�-��/ߖ6�h�H+��BEk���������Y� �ɽ�~U6�y���&������6��Mn�k��]�$77�͍r�f��e��QnnL;\nL�����i���+4�w���N�!�hC8P5U�1�c�.3|hn5�.�[��V�?c�Q~=���(�� *��8[?�9���
>U`q�.pw6����J;�RHđV�E�5�cN�i��\���RU|�����Ο��%�˛�F��`/�� q����'���ؠ�_�_����y���=�F�Qj�o�(A+�9�61�r�BFeu��R}�I�U�0�"n�f>0���]q���*�,cH!�]ʭ��}�8U�ͯ�9\�"�ۀ�iaxG����b�E�U�D�2ST���0kV�k�x�R�#�P�-+�G�x�捛�
ft�g����̮~Rq�*�~Z�\T6%YsǏ�������A<�`��LԌ�i!�����"cT��p�r8���^�"ϧ�zN�D2qܢoɪ��洡]{�7��е�a����w�*}�X��_yh�)��ȱ�K���L&�n�X��9k���1��������-�_d.�[/dP�[��A�|c��:�evy{ᄸݞ��J2�A�t>Mk������5�6�a)>��%6�y��]䩐 Y�X�-!�)2Iڌ�����2���L�Ƒ'w��M@�_�崀����ԋ�KiI������ϗ6��*4�-�Gj�ic����յ&�7��ު6�D�k�Z5��~����Ϳ|�ϟ<94Lr�%� X�{���
������_,�}vv�>����׉"����<�w ����xh��F�0��WN����=y����0}�m<�Y2�S4��e�������h�����e|��/������������?
�}�����ژ����fKK��z-���(O���e�?"K����SNQO\��EZ��s#�N6�y/-�b��r,ǉ��B�'�!�%djZ������!�@vx�P�W��)��п^� s����7|�k�f�к6MgMm�/�m}��.�F�V�ɵ��.�%w���;�<½~C�(*J���w���7�/;o��p�L�n�����h~#��T87#P�5�-ǧ%�)�E�����,R:����z�7��x�^ h��H<ō��\=f<+������:}�?@���Pr��ϋ�L��=�hP��j�9��?{,���CH5nE�?�K�عZ-�\��rҕ�T�{x�wG\�]�C��<?8~�>�K�h
S˼ ��d�Rxc�J١9�j�D�����:�'�N���\�ԣ,�qrz����܋1u!%��6�x���J���e�\+k����Q�i�O;Tu��z����9��AfX,$"r�2E~9c&n��,&��F&J��9-~�ZEC��S�̤n*��5�&����ML+K;�+�j���H��Ig7��Y�)	K�B�ʋr�(�m	"��̯���mj�|S��94�X�`��%jIXb��W���wT�Lyq�B�8pj5��w76Ƞq���(�H�GN`2�b `h���q��9��P�6��U�b"��(V��M��`�i&r��f�*x��2��Y�3ش:bm_��k�|�\-^��-5�R�)v�`���rwU�7(�ܷQ��J���}[4}�ec?�Z��}2�(��+w^�������Q�%�D�7hLyA�Ɇ�=��H�˶�k�<�{|v�g��{�n�w��nR�y7rD�?�愢Q�2�HE�=������Wn��L��=B�>nJ��YVpʲ�7�������w����-(<��E�i�cf�v���Q�HX��������?�&�� ����W���ϾCs����D[�G�r`k�m��"O5'�R�	[^�W����#p�c��F���bƥ�w����@O�j)�`uS���@!4f��t��iDޟ�L�M���AaL��t#���������c62Y;�-q�"FE�3r���Gc�7O��TLnHJ��!"���b�d�Y�I6H�M�[3�]�۶�#$`# �gjS|M��N���w�����`�q�B��*��E%�ol�K9��
k�y4���1ڢ<��ql�;<�\����h���[��g E����ؠO��*�'�oǬ��f�8"{�KF�N��ix�`nS�ǓS)�p�%ٺYЖ^B�[�'�ooO�v�*5ԍ��20�m� ������)�㴜�ZQh�����q+f��O*�OH)|�{d��*���@g�X��}1��qH�����3�OL���D\��%v
�d�3��9�K�����$�L����*��ҔD�Ԋ��$Z�K��)ԗ�����[��4z�=�ݕΖMc���iB�� Tg�e�$ǚF+L�ʳ�-��6"�M�
�]� n��+�`�u�̫�9����t`Sa��P%o"Ǻh$���g 3�{
(��N�w����z|@��e�N��*��LQ<40'������,|F6�FҁE��,1�#���7��w�9Ɩ��O���E��'���M���&�����
��N�:��ȭ�����'މ�B�5-���p��v:�`�1�`r=ԙ�=>�G��!(��-t��1��qo����F7R$R��U�|���TÛ��`:�e��a�^F ��|?��7��#���j'e��Y�;Dw}5�TM6WD��:Kk��X-=��.��<k�f�5���能�	9A�L$T0�zR�E�jY^���=HoS����T��p*9Z�j��i����Qz��Nz�q�/as�6!2*hN�S�HF	;�I<���ߝ�����,��,wGX�/em-=���uN��mS�1���-1d��!6N6b8�́�<b�:	�4�Q\���+ؑR�]�k�STS�E�Y��|��Ge�5;]W!��Pm��d�%]��Q�P��PU�|w`�y�T���
�9��n��Ɍ6��0#R��ŏ��]�MeՑ�Iҳ'@�+��sƾ�}��M��oJz�nҏu�;��b�G\�����^qu�G�q�{פ��8n��H$�gJ�h�UdNm�&-}�u���L��O$����, �ڬ�X,��= S
DxT�3�8tS��б�>��|Mv5_�_�9��6��Sj�;�'��7�Sz���)�k���3�Wƾ����;�P�0*nP
�������ͅ���a���;u��V�H��u��v� �b����.N�SA|2�y���5ݥ���U]ݏJ����|��ޝ�P�����S�HN���j���bjYꪕHo$�llh2�
����6\��g��i�LN�6���x�r��5U�J��@���T�nٛ��I��b��SIs��d�ճ���Ta!Lݲ �`����fƷQ�x�*��9�i}URW%�ă7&%��U���5�g��.9*����V�k��`%�?(�m����}����!�yF��j�7��}G�E,�5~�RZ�>p����T'e��2G�a��D���ko⳥Y^������~�]f��*H�����@M�)%��L����ux��T���2zmk;�#��؅e��攲�>��Pvk[�{w�}?�V��	�j�):�D���1��K������U�|R�:E�*�H�XS
և���'ctd?�����~���q�����B$��e��TE?�8Wf�N7h]=��e�)V+�w�WLG���D�;m��R��6_�f�hXV�'h,0P\oI?>�4צ���*�{��W�i�,#ǩ[�?��	C�;A+��-�9��~n�1X1�tώ��qٔ���Kp���+��WR�'*E�ҳ+�U޿85�(�����T\y��:�y��V�>Q^�'�!�'���rq�}v�s��!ޗ֠�Z��ҕ]��lIb1J�}���o����g4��w>kvR���z]C��䬻\��Q��$Oe�* �͂�ﳊ��,��2���C��;�}�E���x7�Y����G^�;FX�&��V%��pWd{�I�^S��6 ����1I`b�ܪ�v"צ����Sz�@��5��QFd�@b{D6��^�6)	ą
"��T�o�r$��#@�,�[?*@C+�&*����cA�P=ᆐ�6���Rbޏ�"�O5%�Ħ�+��>�7j�IC�����J�lQ(XA~��@J�e���=IȚ��v���V��7$��O7v�׊����F�)5%%���R׺�0�W���ue�l�V�U+kP>�Op`De{|^���0�ߔt��$34���h��w��#�7�i�2-�L*P���#n;�W��_���@����}�KB恾�
�+��g,�3!t?�7�y8Z�MՃB8�^Ʊ3@\ә�>U`<��D�B�yf�����*ݜb��T����R���"�Bx|HJ%t<���k�)ѵ�N��JTZJ/���sO���]^��׻��N� v��bQz/1̷Y�ZY���>f�������둑��dd.rV#���C�&��ۡp�ٯ$Ӗ!3b-���4�TYby� H�c$�%����Ak�o1̮l��eq�7َ �qUX�a�(j��~"�lHi�SJ1���Ӑ�P�K邘�Xܮ�':�b�����C]q�}y�%��">�G�1��>�	���=dF��6%��M^�cL���ܒT��x��W�o�9�My�8D!�M�>��x�A��Z�����Pa�Nj6=p�q����@B]t�$bL2�b��|�����F�7A�Yly���LX�hA'A���v��N� ��+n �G���)���c7�}������a�ϻg����)8��\�!��ȍdA��L�T�6	�S���$n��TK�1�9�3��T]�9a�"�0�Ϙ&�CD��깓0�\pڅ�]̋f5�2t���o�;w%�P!	rfqgw�z�',�"G��H����7Q�n�NB3B��[]B`qU5�ȶ�)n$���v�8�:s�Ec�JI�.(E(�=��Lz_Q���ʺ��g�KO����N�	_�D0d�c8FXG�!s�MY�K�@��Q���f�#��(f�;��?'�(���_�P���Q�13��K�bڇؐzF5< J�l;Ρ���MK� ��� i�f��G�'Q�����*I�����]���y4/a~=K鋯�%2�/B�K�K<��z>�Ϣ��hV�>������Y�PIS$���&�,���=
�3T2H��*�w��qI�TÞ�*���i: L9AB���3�[���HS:�GSi!�R��>��@:��'���B��T�=[�42�8��;�̗��yQ+�gUì����nsKEs��*
��3���;j�v�0z�w}�v'��#�<d��;_|t��"��Q��m37r�m�/>�C/�Pؘ��+A��W.G��qI�n�6	X�J�B/�R�'0$�p�����hL��ɳ.dǮG9�`w�SC���t9)�Jv0#����,Z�|��`g��^u�X�ӧ��s*�M���bbc�����ј"t�F&�R�m�� ��+JC�`�stDx�*9K�J�1��WV9�f3��X"�[�KE�@������kb<����$q���^D���ʺ�27����ĒXl0"�Z�PXV��3+˂5홗��%��O��ެ6���F�	i<4b����?����e�SY�&��ק��������i-����Jd~V��jQ��{�݂�[긗������,�2|��Ix�8�1��B��k|�<f�,q?ga� �
)����M�����ʤ=ļO�%�����6T�!�]G鏰{���b�lr�A��mCg�N8����W��ko���G�ރ���Eӱ*�K\�3)E�ҩ� ��F�3�����)���1ՠšG�b�l1}v�V�qO�2�Ԭ��=�$ �o�B�'0a���yu�� �A?N���!�P3
�0�6��ԉr��T�S��x�������(��ӧ|X6Ya��poE�y�R�M\�Fq��B�����1�C B������қ��S�ɌV0Ә3r���d|��(�
�!� $�g!�m��]&����bL�ǬO��Y9p��G����O�`�8�ѬZ�Th80дީ�{�;q�(�7��1\�G;�+���肶\P)�Fd�'.����gg�Hd ����%�qb����16��+��Ɲ��#O�.�\��ô���@`$�~��Й�'��1m�� �O��O4!�;�����Bޢ�dZ���T&�^	.`�Z�tc�tQ�De%]/�s��S��il�@5�g�U�X^�dT]��3��o04�A�i�y�dphhØ�-EǜU�M`��,Dޖ..���=�d���=�	�@'�����#�Q����A�D�����̆�`QRmĕ�������o�	&��<p����.�]`D=��ȳ�y�c*C�=8"��29�-�2�L�zb�
g45�����zc� m�j�9}���%:BHL�ȺpÍ�Tl��5a�&0�pV4�`v�`n��;�Ae������a�vJ&C,����_��������6��p0o �l �;�x8^�Y%�[�SPǫB�(�k1c]�i��~Ym���7�EC!7;����"���ǹ�<�;��-�쳉�2r,kh��m�!F�����}r�T��8���n��¾�5�*�ф��=�]�<7�]���{������^���)gLtq��vͥ9i��X<6LF��Vv�s?%�Bc��9>��X���xӱ8=fJK;����ѵ���L��2ɒ&lw��h�>*�5/&B�`�c��q��H2��+�����*iՒ�<׵�F}Gk�N��ZY�RZ���2�� ��v�Y�m	�ft�]�H�H#BJ$=R��%�M��lb���ہ��e t���Y7�I6�<s�Cu�\`��W7���u��K���6㐦� ����5�#���c+�^��x����ϳ�.Ju-�
��$2]�� ��Y��p��4}��zy������LHq��4�M�3A�}�F��K��7��s�R�)�����n��9�ؿg�՝]k�R̪��whx�jʮ��:ʮ����EV��#�AcY5kv�"���T���$W�n`Ym��6 �w�R��|��{1� pO�0%p���B���pI�7�VM~è@zÔy�`�>:%��3����\%�6�����,�L~��r�k�N�}LPa��*X��B��Z��������	�l�o�(6����k o�{0f�Z�ٓe�a��L����HС46�K��j��x�4��cډ����q�  d�px0����՚��;P�	i,���xj3!��2���+�+*���T��Q�|[��7UHJج�pQ%Z��;&�#+۸+*��'P�4Iؽ@���1$�Eu�4��B�Q.+�:�����;��MT�--��9f��M��"�l�R���6DFCv9Q`q��n�L�.��.�pӢj(�E�;���o�w~�QF4Sl���Xh�o3ᎌ6	�n�
�bQ{gpN�q�!u����2�\̴x��kA�Ah������$��vPt�{)uTHY|d���2�#�U�K�KY1�İ�s�Ƹ%�i�^�iʮ�TVP�w�Ȃ٘�}��)����y�ųN�/�Y�Kԣ<"�9�d^uF:++�SR�X�}��	mz�X(����Oŕ*��6���?0�2��
*��⊱�FuL�(����0��E+á��e�ĳ��ud�7�C��R�ᶅ�{�|ȼIݤ���KUEY[ƨ,L?�b�Z�X��OЯ}����-���n��L�W&�Q�hő����e���%U9J*�H#d�F�*D cK�e�3zi�l��(�"C��MnE�\ـ��"�hq��D�C^Q���=3M�b.!o���)
�)�x>�=��!�3̰�"��o�`̾e����^��+|�	ќ���|��&�]sK'��]�H������
m����M�D��2�?v%zg�U1�I ��meN��Ol2�G,`�_o�+�uQ��"6;���CT)3F�m��_�0c�� o���A5�<(n|�eM��CQ�
��P�
����-x�w/�L<�%����_�����a@�KUr�B{�x$f�Ȉ�+#�+s�a���vO��dn���`XK� Fd��1m�j�:�6�L�]�2֞��!W.w[d���/��v��[#_7T����{Z>�?�bВ
1hS��b�h�����Κ�r�gf�� -`$�".�\��u�x�3p��٦�'�qXQ8��e�j�D\ss>YQ�4�4�S��2�R\&�˘S9�šKc��s�
����������*�;�b�D7'9�i�QӀq��t֜���������M��(z�B� 4-_"o�U��zQ�/�5y���d\q�Jt�͚κ�b`܊!�O���y����S4�`{&��(G襮�����9ə��&ة�$�X����jI�wq�ReR.�C#o�L��r73r�	�:L&�f��\Ή��H�K��P�,�&WLu4��$O)n����5�9gO|Z:��?����N����C(F���[�ަ�t��d���יw��v�ܥ�齖t�bc����oE�NEt{JCv�F
���c|9[P�����I���d2]y���K���(ҷ ��F��Q�`v�XFmj��=�)Xs��2�n.�wj��nV��*T��y8>��E��&Ӻ�8pw���EГ��[*T(C��H_X���S�E0Nc�o\v���ۢ�%]�
�r���yE���[�z=Q��;c�*�{��ӣu�%æ,�ٔE9�+[m�|`μ2�A&-��j��
Y\�@1�!��c<s��+��a0��,�`�u�GȄ~�ISA=M�;�.$�$PQ�LG���~�дME�)])��(��C�m%��gn����Ɓ�K����X����}|@�$��8B��6j��8����.mz6�>0�#��Nf�&�o!B�s���� �$�* h��'�]C��+��_0@�5c\N_[y�*'PٍU�q���b"�|]y���y�JK,eS�	�y��E���� �:�������%5q�&"�g�t}���Y�9^V��N�/�����+E9)'�>�J��)����2=+�)D��M�p�	�����H��sʣ�sՎ̻S�kԙGZh� O��3�u�#7-T� ީÚmv����?e���᲋K�{S�-D:)��m �7���N�l oJ�ؒ|M���0���6��Q���P�|:�{?�M3ä9��A��Tp���@Y��� ��`r�BoJ�1��4�4��B�e2���0�����7���.�k�/�]�4�NS�)#��'6�y-���ܨ�E���B��0�4߻%7�[E��镔b�����d�>`O�%�rF8��PM���BI,T��Գak�oa7K�������!sP�T��V��E�
��t�V�rw�"ʚ!��\�a�p�}TZ�n�^t��EDɾ��:�d?�h��	QR�F �� ��PC}��G1���-����F$��֢]%0�o_ÿ��޴@�m��b�"��N�������B�!���8'a��
*;��S�#L=�����/���WX��Lz#�E��ooQ��6��8&^�`��m
�}�+�L\���e�D8tT�Z��ٛ K�&^�^�0��k1ż
1B�-��]]]�
����
o.���u;% �d�����f�;�//���̎��iu���?�-�����z5���O!�Nm�.��h�,�@6
�1��'y=Ɣ�����R� �c�tǭ��	��>HH�|��2]�|�����m�Y��j-��֪�����Vm˨�ֶ��o5�z������m�k�Z����o���˕��j�j鵚֨Z��a7��f��Y�[z�g��{pi4@�jǾf�����ZߪnZ���M[k��VK���am5�Ymȵc��f��3k����,���W�m�n5L@G뷠M����mV�Fk�ճ_}��mն�a֪���Ɩ]�t @kf�����om���l�4��4�u�2�z�׬[f����� X]�aom��z�زu譡��V����=������L6.yFloi[�:t������^׷�vd�f��iZ������j4�f_﷚[�v��4z��կ�V��k�Vk�^��-WKz\��t�ՠ�j���m��0,���a��Z5�YE��	���ZϪU��-�ٳ�-K��m��׌-�ok�hX	X�.��є+�:�Z�o�Z�gVM�$e�zo���f��m�lC׬�٪�AɞvӪ���js�_�A?�-8i��U�Y5�^m��t��jdtN����m�Z&m�i�pi0׍^�h�$�zs���ku�je@�|?nCqكsG�K�-� $鱡Սfm�蛍�V_�2m�2Ms�oW���]3���Z�0�]`�Z�jW����fo���U�jTku�V�Z���vs63��S�k�4�hf��2z��%�]�`�XF�o����
@�;jhvo�6�F��Y۪��ZM׵m���v���v��Xc	Ϣj��n��5l��Z�i��u�o�z��������:ٕL�f��iz}�޲�����k���4`�5�����ͫ^`z�Զ��h��4��4���>2o���[ֶa�uQSE~����?����?����j��l�y���x���e�1G��ך:������Uo���c<+����ꎴ��4;N���}k��.l���z��@D����̕ޘ�+K�\'��b��u��=�XuA�A`���&�vC^þ���`�I�WN���c�ɥ#��e�������$��|�{7��h�D�-dݳ�tu�we���C�� �2P�c9aT{��Lo����
��+rj_:�󦊈X1%�-����=)v�yB�(9�P�4=�al͝� �/�ipRD�S��@����)�~���c�ށ��vYk����$� s d��.B�.�����p�+�� ���j��>��ߌ���$>tL�YĊ ��$XE�B��'х�g�މh���x]a��O<�x[�&���ӸϦ�e�晰��]h����N�;�eT02x�Rh�=�����7ݳ���l����-u��#�$>&�`: �w�����[���T쁓!I(̔5��g������R�XT-q"J��
"hj�	5�:>��!��a�&O�ʍ����AK�Y�L�nPD)��Z��s'�4�"�K�[J�к�/Ң�S�S�bכhS��� 64}*z��B3a�6,F�Y���<�e�Y>�5^p�*��o	lz�\^:7�6s�?���3M����ژw�Wm������z-��?��w��_>��O�&9�� �=�{�S�?�?���]d�����7��W�"�,~��@r(cx�<���10��I���G����ǿ�W?�'�I������_��f3��k������x���`���`��� PC���a�D�j�F�O��e<����!�I�@'o8(�1�B34�(�>���C+�5�ՠ�	��0^����ås��G6߷Ow���KG\����k�&xw���B�&Rk�'k��i]$Yƿ�I���])�R�z�dM\�%����Y*`&ęyf��EfY��p:0�	�Kz��FF�',� �@Ϋ&^xx-��k:�Q����rٗ�G�6�벤I��?��7R-�p-A�J�-���y��;ҥ `(/z�E{ر�zvJ~V>;�����N�c-Z�Drߥ�X����iw�~,Q{��� ,�'ZN�m��)J#N��Ք���c[^��$�������t�Q�*,ϵ<���sn@��fZD^��>���&#R2I��T�$ҟ�lP�$�r���g�j�Ae��j�t�V+���*�}�]��ug�R|Fh\�2)���Oޭcri�ډ�֊��)���珆?���"���W/�iD?��Õ�ߓR�*����cH�|��J�v��������N�)`~�rzV�&�DJg@��xT8�V�Ҍ,J�E'��]$�`�JR�5n��<��K_+D�zSK�F������_�L@	��3
%9�T�bjy��p6P�wqi��V(*�~�mQ.�=]
��˥���Ka2v�T�����S�U1+ $"w�RI�������|Rv;+�B8k{8���/k�Mw7�g?�:~��..�09��H�b��V*�M�;���_� Ů��� �:aJ�Y]7fwG`$�M��FC:��hvx�n�Q�6f?�I����D��w׆��(?��Mo����$���k"��}��}I�0ȧ�i���Pv�^�{L<Ѯuc�3���
ث,|�!/����:e���K��(���l��−�1�a�?4�y1 ��f/�
s���۷�N��@$� �f%��أN�awMqg�Bk�6>}Yd�G�ad���I�p�--:���X���
�[���]:�ա���^�#��G6�]f����Z�Zo։�7���#=_�������{�r�~�O�m��6��j��Z��)_�����?_��Gq��E^�Qf�%���PI�u��Q��_-t����焬�(Ho4����~j�kI��P/+���p{�<��^�Q�����q���j���H�
e�RrfMt�m3��{�P�?�'�B�eMzٍ����6U�����TR��ߚ�b6R�P]�M3Bn��}�k���ް{XX��Z"�8��^���ћ��N���m�
p]ʉl���1O�o4$�?MG��F+_�����__��+���s���x�e��L�+�?��^X����ެc��W��������>t�b�� ��[��S��F+���'���pm,8��VK�6h���B>���$�4=H�_��V>���Q���E�Mk�4����h4���'��ڸ���P0��?�3%
�Rۘ���5����f���ߨ����1�5��z^��Q*J�"�(Z�H4�7F0�I�?c����������!¤�uő�ĸ���7FA�p�>�nw��Y��nʑ�?Ao{���+�;��3�}f
������Q��[gL�]��َs��Ϯ���}�"�K$����������O*�������k������z������̋���6���Z��������V��?<ʳ,�y�bn���F��m��dX��"-_�N.y��v�Ի8�v���VY���z��-y���*ӌb̷�"K�hf��][�EO-������^�����LL�̱=�,�L���68��u�\�6zo�f�q�����ܙ4�L�h��rv�w\�{�$LY�(����i�X`	Xϩ�}v�V��-�p}��u=jv�6I�F�?g����/� ���\�"�k因H�!�H]�����z*�}E�)ڂ�vqCT���?�r�{ կ��'x���V�M�s���H��Y���-r,���ǧ{p�)P�%�e��������Zb0�%���aN�	���fI$Q<�diL*�j$K��+���'<�_\:�:�4�����8����P��ެ��b�i9mۮ<��z�<�cª��1�R�L�ʸ̪�#u$-�x|�ՊGm75N���u`�ξ��U?S3,��9�삩�_+���ɝ>���gk�u �8�l��`��R���X=�ǅ^ֵG��H�u���	�0��<O���<�D�K̒��ڠ_FN�A�������8?�GM�P�����'+�Ѳۘ������z���?ʓ�������'0������{	�eû���kҟ`6qb���t�O��F^�PXj�����S�O��c�F2O�zqg�$���zsp@J#��?@i�g����9����\]q���`�,Á�s\ӧ�ˍ/7��fu��Y�ll6�4��G/O;������2�����F�Z�#�t�����n���>���9�U���<�������?Zz�����,m����-o ��t���S��3Pҙ���$���d�MU\#FH�,�	Z�c1�% ��D2QF�7s�&~y2��x��@K\�7���Zp8��pHl��Ţ=MtT��D=%*u��"�F������c��AZ��ݥ�
E�>�No26ʤm���Ћ 2�=��ѶO�g���kr�1�e��(~D�54odaCv�߃��s���t�2tz�M�o%�@��.��jf4�=*�%�*����m�!PW�x+�>��.�c�P��p'�p&pjĹ ho|{�^�L�4S����{i zJa�>�m<G��1�J|{h3�Tg8q���5��r�9�<�` �%�]x��}a�fT�a*�B�2�������k�W����4��B��~�%)��|�}��zl�,p��wl�xf}���~����V�nR����?��At�����B�mRZ�}�
%���^��*�� �G�ycܙ3�A(���nM�
��k�u<	Ǔp�s�~gzn����_;�5�#�)g7��L��|w4�N	Q�C��������<G�����l�s��Q�<�C��7���D��������y��<��r�i��w�G��9C-��x�m̑��ݟ��7�U��Ѫ5s��1������G���S;������<��^�����;G��������7��g>s���=�~�}~�g�ܺoN�\|�o��z���C<Y��e�����[�j����զ֪��_����������K��<��]��������y��{���U���y`gg;}���C��ilg�x�U����N��� uV�Ԭ��>��Au^rԥ�?��n5�x�@
�cS�@�ܩsr�湝�����~�'���<zaԽ%�1O�oc�o���k�r��Gy�·���a�S6T�x�Jn�f�/
�4��s�'��k��@��H��l�jZ������y��<�g��M�����������2�Γ����M���j����<y��_w�����L����t��f�����c<��G��3��Y�
d�<�g�k�%�?S�����_^�9��Y���?����j֪���O�C���E��<H�<T�h�3�~lF��-��a�d���F �&��`-%�-�#�B��
d*�%�_L4Yw�0�@$)u���s��=��w�t��c�G�^�*k�z�^)��?������B��B}�,�(�:q 99�ǜ��8Y����{���ی���E��B�$�?�x��s$�2�XJ��?�����-�����䗴I���e=�l5{\I#E]�Ds*��8Ax�(��Z�_KD߂Ch��0|� �p�x��`�;$zY�z[���`�":���(�����3�̂mB	�s�z�%s��sC�m?�|b{�QO��~��/͚�'�'�'�'�'�'�'�'�'�'�'�'�'�'�'�'�'�g�����v� 0 