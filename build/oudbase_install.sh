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
# License....: GPL-3.0+
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes/updates
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
� �#�Z ��zǕ(��駨@tDh@��H](���,&�I��c;Lhmݘn�#s��������(�Q���u�[w�$�N2�d,�Q��jժu�Ugq���g����>��P��#�wum����j?\�h�?�Xo?V������ߩ��=0���i��P�4Z��~�y��I>g���
ӛ��f>�},^��G�>��_[[k?Z_��_���wj�3���������B8�apO����-��7�ҝ�=�⋰��mC���q�ڎ.�Q:G�T�Q�&�4�����ux�8�Σ,��i�y�֞6ԓ�ƚ�vN�g������/��ߣl&�;�~8����Tކ�;��0����i4u�Q���(����5Sz��SA@�����n?����v�|�5����ѿNm�n���Eq�I�����βI�G�Ќ:�e�d���:���a�����"�3Ta��h:KT/�G��t�z4'CXǜa�_�0NFWj�G}5H3%q�&���8�t6U'o�W�k���=�e���p:�䛭�9���!vZ��Y�8v���DO���ݕ�������K�� ���|ͣH�� �Mӆ5��I�/���f<N3D!�9���ף��[�I,�����-���8�;w�)Тw��^o���n�?_z�|�\�M�q6��vM�&}��`�ۆ�2M՛p4��O�P�{t�s����\�:�����絓��ݚ����qx6�x�c�#�L"�1 ���q�y�eg��#�]D��F��X�[G;�'������e$�X�ZZ�'{���;Gݭ�����Z��F_��B�K��-����R-8>�����v��G�k�9UK˶����Z-��2������:S�҃Z�����lou���ö��4ao6{à{ttp�|5p)��W����%=$�O!w��o �R���<Z���E6��Qx��w$'C�D��h;���Umg�����E�aex���X}��{ghb���Z�V_�F��އ��a�_�Y�%�7ꧪN�ZV;u���('� ��ۜ�/�^��)s^Ϫ^���[��Y4�=�Ks 8�M�H����<ߎ��G�/L`6�p��{O�D/��viY�OԎH��v�sbO ���|������<l_���ZU?=CQ�z�[�(L:I�?f ʨ����k�9����
���UE�qpܹ���Z{LX̣��t���smu��r=xO���?|}B�����*"�����H���]�fH��Y���=�׀ru�C5 FЕU�Ё�y��m(nfMj�E��J���uO���A���j����+_�W��~�j�ͯ�k�gϜW��濚��2Ix�#�=����[����^�f�G��a��	4���z�D(n�T���R�a��혀p��/SPWBg?�7�}��i[J�����|�⾧Qc����X���Ň�������U�p18��3��l�i�y�.�7�T���Ճ�=�>6,���"�j668@�)zO?�rt��P�{�ȎM�պ���]AҖ�g�]����Q�y���@�!�M�X��*���4�0;����7�1l��5d�4C��ɨ�v�v�.4`����~[�7�w�R��@�O�)-j��Lȓ΋k]�����n�h7�/:���o�^�~�hJ����E�P{���n�y+���a��zC��p^�? �(��ǥ���<ZM=H���{����q>��E}�����f`��'-�����봺�,IP�P/����������;P���~�Y�6I/�7j��j��׀=�
�,�	xx��8�Iy++��6�Kpၺ�%I�\��l	bcكdA�U*���:��7n�d����eB�Q�����P�.-zQ氀V��|kA��ҵ��ƕ����=��$OeWk<v�}��^���<˧�2L�P�`y��(�̟nd���DiDs4�l�]<�%���(�`Dh
0�2�Z�*{ ׾i���V2�L�{�P*�����P���İ��,����s:���Q��o>h�JWu�u(���(J�8^ލO��K;I<��ѧ{P���E�'Y���FES5�
�2���2�+�L	lV�%�hV�*+ɞ���6�� .k����?\��/���J��;@���*�}�"R�{8Q���(��{�%1Nh�̇E�����O����	D7F)��9���b ��XX�[�ڣI�(�;��P�T�#.ҥ�9>o��s`���J��б�{�(�z�hcڿ�ep{a�I1���Y8Q5ob�5�M��,�������� >�
n�H�f��&�0q����uY�m��4� ���O�7Jo�.F��I�1Lя�v��������ϛ���gcαa O\�`XO�#
.����-���+���L5�z�y۱_rN��u��8�mVWG��ݝ��	EJ���}����'=�5���_d[^��9F��PP�ڲ��ݻJ�mx�Xx��F�}{��� q�b�O�Ӑ�'�`�#KǊa
��7��Is�� lCS���Z/`0V�/�''}�2�������>�k:=��^�����Q����p��ZyK,G]F�(8�"����@d�+�J/���S���C ����mA۵��\~�,�}F��L"~Q���h�h%8|A�.n.z_Z��pD~e��P�<I�`��ɔ�>��I�M�(Ǒ�#Ɲ���>L��sT������l�o|��=�����q�f�9�\���MWFs�{E+8�i��x�;�sa��a�y�%�����y�K���}w���?� A_��������8�x6��c���u@
4Xn���������gy�Ǥ�ZϮ������*-7���Ro�xȒ��6vuO���(� �����������z�~��ġ��7�����S�G��gūE��@=�mz֔�)�o�Mh~�`4�w�;���c���c��Xإ��c�u�������˷����;���~LV~;�%�Y{�����K{����~|������o��k���`�Z(2���я_�Ǟ���MK��	./=��]�<���g��G��Ңg>e������Ê�
+�Ѯ�m�n�K�&�]�w�A s�����絣b`��*�F��!̎�.a�&d9;�q��<"�]|��	R"���o��]:< �������ƹb6���r�Z��]˹2֛ڢ�������ke�,`yw�D�Q��_�m�{i��L��Z��$�k�O�?�7�}t�p��}��V�Q>ns�U��'��J����b��xo���������5L��l����i>EOH}��|ܪ�,�r��*�Q�� "5�%�6�����Y!?�[D�ʚ?J��,�;:#��iI��AǢTٲZ�!$��C�]�*#i}��U2���㡹��ʍ��:���6���u�U�����G���~�%����|������͆�W�����x��ɺ�R�%��_<��_;��N��?8��WͿ��~�+��Wd�#)|B�})����2V_;+�n�n�)���O�/�y8�X&*��y�4=��^��8?�_�����淫/��_��՗��/��_�ۅE��I�2���
�/��7���g��y�w� �[��~� �� ����7�{���\!��$��秚r z��F�	T{ǉ� �óE��m�ϖ:ތ7���k��I�CC�����<������U���rI�$W�v�~����)~��wsj3Da{���`�¤F�/Ÿ�M*�4<��^,8a)�=������,Bk6�S%�O)d{t��KW]7���y�������ݝc��s�؅���{��q�_z�)���a�^�E���:G���5!<!���c����y	��YD9M�5�v�s�z���[�D2��D�-����t"X%ꖸ�~À��GmM8�RL���~l�������h>Xj��nݯ;�/�e0^N�7��,�^��gy�����b������@����}�W�/����y���M�����D 2.HbN#M����s%h5>�NT���~P_�p"�nN�:/����O�"�d�I�{!�±A� �ݥV�>8�T?�?�-9A����yA����Mєx�ei�<�K�^����d'��h�2]���Z���p�4������&��E��@��I�d�T�幸�v���0��7}�^�?y��t�;g[�=�7��_����22��@�e��N�-VgO�e%ն�؊i�Yvfj�	`�,j�*[=�-<T+���SK�����۝q�6&5��JP�y�=�.a2Tq�.#k[ѭ�Dgdz�Q�NY��7Q�5֐���s��6�Fa�v���KR@�Y��w{�¬{o�Iovϋ�>|����u�k�?�o�Xk�Xk�@���-�V�=��F^�fhJ[��9ER�l)N��l�Y|�BZ[{{����ٿn1ĕQ��ʊΗSt���*��V(���)�.�E ��v6O��+�R����f��FH��/(O�
,����!H�_a��2ђ���^�e�$ֲ�y�@ ��:_ՙ^��ޖp�%Ɓ�H��l�Z�ONa�Q����S+���]��=H_C±f_�
�����ǿ��>�Y�_���%��К�~q�/��a�/�<��{����9⤟^&�z��1�3���p�~�f�
�p��<r�I$��<�
���;�9Ol��W�WW]�Kiqi�eU�֔PX��J]���8Yn�.���G���_VN����Gm�����1���m������/���Q���p�*��b�~�����������l����U���'3z��{�	����`�p�~��t����?� ۟�Ϣ��]�͑Ѽ��I ;|����k++��[�����W��Qx�%���9�y��FR�J}V�}����n},3m�q���m��F;�[Gݽ��Ig�B��}������˱�kwॻU:��w�>�E[�*o�K]�/y��Ǘ��/y�_�W���o���%q�K���%n�
YN���p� ܗ��/	��T	�w]��0�z��v3�ov?G��� �U�,��+rwU��k$j�Qj�1H�P��$�#��*�� m�7��Х]�������6.��d4�h����/���$��"����/Qv�V9��r�YP���
�� ������:�~�H�a�N��(U�ͩ�z���N����z^������l��zE�`�N���l�����q(�;=�N�%彥�B�^Ĵ+ =�b��v/�K�]�3.M�D�������0��x��K�V �#$����d����l����$���Z�]hDp���W�����觽�f����ƾň91�Y_;j��]��؉HGUi��\�:+�ʚ__�yy�9��K���8/�~�e汛u���N<)X~+M�]�[�X�+�i�ˢV���G-7��a6��g|�`���fެo���OE'D̫�\5��w19�닦�����Daj��ǅ��w,��|���夿J��9�����aN�雘�T|6����\�eI^l��o��>��������~��t��s�o�K/�c�^�o�z^�H:�i�)Z�� �G��~�Q�� hd&S̼.���
��MG*�(w���<)h��Kk���V>����JV�3o�͟�~�Na���ZFoCy��A�����epU�*��M�dx_N|��Nx���>޽W��������7>����퍶Zm?\_[����k|����6������s���A�IAJ�'hXv}|9��}
@ҟ-�߄Y�y����0r�SB/8�������Su��śꎧ(Vī�p�{Kt�=��a@{�m����7p�������V��՟�k��z�&�}�N�Oػgy:�M1	�
4�x����	6	�Klw_v^��5�| ��!��_#�����i�Z��ʋ�H;'�4=�;�> ��뷟�F������u[�1��m^ H`qN+Aq�hڛ�
�K����V'ݽ���I�X��-}#�0��ã���['�,&Yڟ��TOaf�4�/�k͵f�	������w���K���o�ט���`�7�S� qpύ���WV�z��z��]�t�Q̠�o�M�a8�6W�|��[5�����zn�R���Ğ�I'7 ���E����+��
��%�DkN�����.�K1!Y �C^��z�DTL�f"�ؙ��ޡ�BJI���~�g�2d@�R�@�e�'��a�>�^*r�.G��?�������9�,?��C6�d�>��zc8�s�q#�"�, ��f�2ᛁ�Y��g���|��C��!��U���jv���;�إ7��t��sFۡ~�z<���ϝ7ݥ��;�9���9
a6��a{N�5=��o�p��D{[�D#��T���ʽl��ד�����̞c����ޣ��"��E��%�ҼH��6zy�O�����Wr.�x�
	7s���ɗޘ�������ˢ�,KT[����Ph���nFj~����G$N�3�����i���Z��J�84�"u�9y�� ��C[)^�y�h�"�Ou����E��D�Ww�t�O8�1�s�$��;m���^`	��%W=A)�`_�^.�1f?r�	K#�|F2q�H�j�:+��ڍV��]:u�5$����TI�� �Pt~����Rz��n֚��\���q�*T|h�씓�l�W��}|m��J�_��D�Ʉ��h��7���_�5�2�f�i�h�Tc�l��RJ�G��ixf�蕶�I�t}q��m�{pM���mV�zt�GYl��(OA��9�t0�<���Z�� ���;A�dl>Pņ�W����5+�\Ow��N��S�#*3Y�mN:jqcz-y�Ғ��-�s�J
k!��ók?1aVz��?k��p��?�P�x2���
ٌe=�{��Ҙ���%�zy��'��4�RJ/��+�fU��jw��[��y�S�y�n��-,��Ԥ^�2�!)[B&π;�9���)Q��jN�C%��fx����u�6���L�F�
�C}	���`��GoNkKgwMcD_�-���|�$�u�"ǚG�L�ʫ�-a~�����n������#���u���	����vMi�&X�?��J>�zz��csB�`�]5���,��
`��������Z%�]�mB�g8��Z����t��}_O���S�RE�MTDҁM3���h�FI�̖�w�N��Z��+^2?W����jOv��_��2��(o9����O��O?��7��Ԏ�Ec�>�vo3Ja���L?`x��w����U+�"p窶������(@��o$H�H�ϼ�fao�����`�Elw4jR�� d��i4�
zˑ1ՁG�YJ��|�wy�b�^z��Jy��d�m�th��s�;f�!���[�ɢ�Ơw�;��ٳr��%��:85=��J�����R�e(W6'gD�#'-Y^�/u?`_�*3��.���[ ��Q��;L�l�� �&u��k>.����ɡ�?�M�+������;�[w^����IYl�SD+�a��=��'c������'��T�f��	��Z����J�Y�kէ�s����v���9�|ش�{v��B��@ޢ_���W���
�u��Z�!<��uWRz����h>���i(��Šs�ϭ������~����;̤�_�h� �l�I'Ӂ����F��Zi��џ���M���)r�p�����s'�gW���8��_$�7�u��J�/�������͜}��,�\,dm ����E%��}��T��T��3F�>A�XZ���'`�E����f�G����/��~J��f����)��(+�܊wL���J��8s�Vu[���	q�����3>����D<��OUP� +I����I�n��\���}9���.EԓVht*�'�nw��cv<���')N��ZFz2�a��>&k��RۗG+���5쪥��Կ�-8�sd�1��N�R�L>���-�1Ƿ	5�iŏﬖ�:�`14��(B�w��x:�"���R�0\�"��4��ͯ9��9A)o�'��ͥ�V��ӝ|�"�aw�-�[�lC��ð�s�J劖�UE_��xFLVu�Erk�i.r�&	��F�K��}=c(����|�MQB������Ϟ�=���N��Wt��.{����3wy�=,M�u��%V?/?s�����*�e�5���g�4G��M�#(�w��Ϭ��JP�1�"wtI�1��(]��c:�%�i?|���1�����%:x����O�zp?�oG�UI���x����V��Xr�ں~�J��Ӿ�b��_u�(�XK�σ�_C6��Sqg��#�L��q~{he�D
��2����:���/{E:�S)�v�=�?ĘcUk^l�~����}ԛ�N7
�4���䣥���f}��1���3�d�9��{w4�o��7�2���J`r:�KT���$�8��4�n�x<�ߍ����C��������1ީ�ϲ���DDd�q���;=��%G��(��� ~/{�{࢜�NQN�y=�=���=6��:�WX�f��s}砂`%:0�@����E�E�=U��_���WW���!|Ě�vL�(��&��{bq��r�o9���G Ĝ�փ �O�G�U�t��OJ��>!��~��H������a4���x��D��r����qY-�
y��h����i��-X�x^���� L�U{D�?_IZ�}��K�%�y�%���|�;i��ޜr�+���Bs/F�4����;���?,��^g������gQ�����7������}x�~�=o*�}GD�'G�yo8�˯�����|AW��N�N�ȯz�bj(�U��\�;M�n�RS~^�H�*����9�������"����(�����TW�R}�`��s��.$.-Z�Ha�
9���C�-9�a��q�7��v�v��]���H�K˾�#S6��C\x��5 &���_��3�m���� �\��RKPT��̃�bN>����8c9�� r��ヰ9�p�}�BnE�V1pJ��-!�����^�T�C��+2?�x"�e�[ɨf4�g��&YJ9�R����S'@��/z	T(jK�*�P�ݝ�)LO�)/F!���r�A������/�z�%G+��a�M:,:��=����2C���R�ǵ��
(���
Y�D�a��%[b㵊���{�T1*����%��f�q��T��?�e����`���f�{4�B��#��5v^����3���V����8�8�9���C�p_ؚ-�����}| W1!u�?	3��x����3�Ks=u�W�{e�ƅ>��cG�(3_͉_�����{�^��!m��q�3{��O��FIzI펢��絚��a�?T��ޒ�.s���O?���L�io�P�(Lr6�{ Abr��(F0E��b*�y�7�!3a)3��E�Y�{�ay	N�"g��)�{$ʠ7T3hd��/�������EG�~��������ږ��n6$;�F-V�n�YHۯ3'Z�V���=v�סð��Y
H^�u1�-��8d-�����DnC����Ei�;X�kA��I��8M���4�����b������!�Ӹ���V������Pv��O�%��3��2�
xp�	)���ѕi�|����S8*�������M��ү���Ƚ�J@oy�UW��"��k�X��;��5;�c����;��Y]z���;m^s���㓣�$wzc�i�u\��{��k''�����Bu��/=,����7�V�̕��/m,H����;O�-P���li���	K����	`a���$�-긔�;��9�?z*�7E��(�_���a��\:/��� �5�ւ�F�|�3L3D*������ڒ�T��V����4���:/>�)ɑ�N͝�kڪ��{^����0��
 s衪FYy��hW��*�fԆ=T��]SV)�kT�+L���D�M'�}�Ktߴ�K���F�^�~ը��uUNq��� �i65fF)�Z��(�whȉ�B�N%�yW/���=Be����\���WmA)Ot[�m:��kC���l�����o�;�ֿ	�~>BE�v�Q�sb.��<��3a4%�P�rp]6�L��W�e�Yw0��tS(j�ba�[���	|ܻX���^�R��u��[�\��Y ��5����X�Kn�����R��O�~�׸�E��������������V���v�o�Ԋ3�%P�� ��Xy0��T��Ƃn�������8���閎��u�����|�w7�����X9ժ��wҖ��,�z���Y�S�Hi���ia�j��K�\᧌� �A��r����[.x��t6ؚ�TGp>6�v���P1
9
<���(-�s�U��}�� &M����n�>���Y%���/fF4�����m�����
'9��uc���Ϗ�W.��յ~�w<�f�nG�s��մ#��E�7��k�`*_�(_z����C��(k\��\���v�,x�Ń�&�����D~�۝n���^�s����/�/���Zk?Z�V��G��S�{`��~�����Vw������K���{u}�����k��_��5>�����k�mw�{��U��_ y(!�RR�|�H��ÆZ{��<K"���pL���|8U�[uz�^fQ�����V�Ļ=�(Uu����N�|�L���7��^D�fF�9^�9����bprE�Sϒ�g��g ��	���Mxs�) �J�����⇙����G��2�7�yӥ�a�cP���	�H�5J�������C�!�QԠ�"*JͿ��
r��
��Wo�O���u�͛�y+�������<����e�ޏ������7x�$���%m��:Ԑ8�t?�R/���,̧�`z��d%}^��Y���=*��z�$I����X��<�++���Qt��RE�,�t ���Y�`���A�h�͸�z�`N�)V����X��d�2���a^X��WчyO��D����+aH����Og�2D��7�Bؒ��0�4%J�C��f��oq8�3������n<�*�jŌs��vL��ժ _=[�j��z�!����xuH�ى�K�S˲�xq2�?@��	 �e����-E��'�k/�GtUDH��i�ҋ�e��S�Ul㐱�^�Ն��xt$A'I@���f�q4�>���`)Qޟ)�:�,*Z7b{9�F1'YtAy�H���
�'�0�Eg����hw���֭��`�S\xl����lR�1��xOc�lU����v����� Ir����p�.!��9f^�����dp� ���v�ꆜ�t�u#��� �Ɏ�t�h�ʽ^@21 L�9�(G��+/V_v*�8^�@���[�1�U���T>r!�B�����x1�_�&�a��A�Č�p���8{oz��=��|3Xn�^q�MIְ�E�x�����V��`�B�$�?8�/4ݍ�s`$us��"v�
�qG!��\UZ��>�:�����!�Kӄ)��Of���?2�@�D�x晡,�"R�Q{ܥ���1��N�ikl��hc�E��\�i�YD���bҁ�h�*�b�Ϡ�s�\��	���>���(��+�<$wd1�`�#��^�K��#��y���ǇR��G6K��4
�_��D[���ޫz>�&�0�@}�M�����t@6�LT��2 �i��9�Ĥ@�9@��(IV��y�ʯ��龟  þI,k8�-��z���~��a�L�ǑU#О���3ǈsx�Iܣ��	r�<��_2]�ճ(�g	bu2E��Z/#wv1!��� I��|:)�3��"����j�Nh����Z����g�ż	ˢKȽ�4��O�>����- �kf�%������3\]C�{K����Ҋ�M���RE;<Np|����6"s:� �	tF�ʈtC���V����vM�������ԛjVB��=Q���~|�ՙ�	'���,gu��&ͅ��SϨt�ּHc�����}$Ҍ���Gb��L�.�
H��[xk��5�sE`j^5ES`M �˲#`�3͍��Ba*t-2��h�k�8ƱKA�\�i\X͈�ht�����˩'��H\����I�h�Xu�����������16^m���8���ډ#cj�����]��죹Z82Ve�nκ7�ne��K.���J��U@�MCX�`4�I3. '�ߚqG`���a��o�$8��b�u�*�y�G�T7�Τ	[��>,y���@�֠UM^��-I�*55�R���`�`+��T�7
i�E2 �����9a�~8�m�_蔂����!5�!��A��,�jV9h���R`юKP{����(����� &d���ɘ�bmW�6H�t,�F��U� �೚�"�e���ӧ,����G��ɸ��sʣ(�OdBV�G�
ᴡ�3\�]$�:2��tay��	���8���S�p5�0����k���;�m��<�y��4�TF��_Q�/� �١�	$�h�����#�4Y �omw�
xB��AQރ	�vVP���/�B2#�����e.��Ȭ��"*�;�S��%�)o���� �_�ZԨ�e+��G:C�
���$���u� 4��������|��a��L�cA8~���h6��\D�= -�E!�it&,_p�vI_�OQ��k��D�0屹+�r�I�%* �KI\����rc�}azfw��ے[B�;#��"�9&XZ��']��p'!/Ģ"��j�vh��d��k�+<R2�@a
&/�qZ�389^����$��\�F��@!IX�	�e+k� v���.c� ���E{4�ȈEƘ��� �h7�D�����2��أ51�]v�j:��43�v�<��x[���-�)
����#����-�=�*W4��1��a�W;i�u���!����1�a��"})��!�i;���tI0���z/�t&���(w�b$Ѷ��F��#��f�9:C^��; ��+c�8�#�ݎ�&�*�E��ktL��Y"S��t�l�٣F|�l�l�VHJ`Ƥ#]*h9������k$$�0�d}���ކ����	[���ĸō��\ɪ�5����ꊪ�#�u-f�������,��[H�D��2�Ђ��@�0mE&�%��X��,�.D�zl�Za5!�r)t�n��t��9�)�jd������`�F#d�I���3j@=�gLp���Br	Is� 8�Z�Q"��q�T�}�`���GQ��1+�Ӟ��.�ۖw0��}aj�Q�W����Nb&� i4

�1Ǡԥ��c!�3�qڹ�������dS�j�Se�'|����P�"��g�X�W�%Z��&�X�9�~�+!�hdNӔ�p�v�%D
Oh����L�9G��M 2�e_2�����oKm��i�Z���~G�0v��@34�D��v����c/h����ő$�T��Q��$�5�^ʊ|{vfPcJ�ik@oB���]#���)�)�tgn8��1�%ڈ%s�Ia���3P��8vǸcp�h�G1���
���wiȨ�ڕ���P�"[aͽ�Z��r�^ww�x,�V-�=�� Fϸ��Z+ g:4	�����|NQ�~�ED��J�Pڔч��O�`�a)-Z�c�B�P?p|t�q4�.IݿS6���&�%�x#߇�yK������yU�qB�2pmH2X��ٕ���r��!5�9(��is�K$��9OgS��-���@`'�%���,�a��1ǴP�$��q�X>��gW�MHL�P���GĈ%�F�7,'��-�Y�6���f���QD����y����[}@4�ԣ���yjbgBct��ate��t��Ʉ�uY�(F���r�E]0ġD�y�u�k�~�Ĳeq9��c� �ѯ�����1z�vA��Ŭ���`b�2+G��N�Yn|,� ��T94E.}�%h�΢a84d�#�A ��!�P��in�u�c�2��g��8�m���ārtHcbT��kOX��D�[o��0q�^��fc]���AA��9�F�����˩�1���J��{� ��C⤽JN�u����=�8��M�#:���l��}��逴Z٢!����v�O��CQ
$r�rtݾ��1i3,Fo�����	ؖ!�1-��l{5��@���n`��;�=C����Z}�sx�0�):�f�Z��][Uۀ����~��� Ƌ&9b5�hR�>y=4H�G�!����+���c��!"'+1KX4�(���b�!�n<�)ݟ�]&�ax��Ȉg�
jk֋�`�%W�G"b)O��eQ(���#h8J����"A��j|W�kf�]�:9<��dDKG��UqI7i�v�j�T��� Sff�YZ����z�Mg߾��Y[�Ps%��n!�KOL����SiX��M�) ���f�g�j6��0�9(K�a���pr�|����^��:��t�V��!��)��,�(����W��A��Ʌ����~{T��UqaA�mP�I��` ���,�^ļ���ܞ�0�i���OT���U���Eo�YH���n(�HQ&���E��(�Hz# �O�gJ�G��6y���6\b�Ӻ�h�o�@{��\OIQm��36w,�����^�S̥Z�"���zi׫(V�\��ihAsW�mr�.����^?�=@ؕ�d�$J�壯8�ů#� !%�]`���h��G�E�vz�$�U��3\I����
��c�*�UH�#�;=�� ҈�D�9�&��m���aID �ˌ%�x����'�1C�%B;���}��y��L����
 (�d���4��X��[0m�������{Ш]�!��dQ�5ڐ%;���NP��$�+v��K��<��Q��o����֪�8^I��zh�80m���NX��\F�y���?��^�ͥT���cR�x{��P`���ة�MP�^�!nĿ�	�bO2!㙖��EJ���e6��Y>��s����aht_�b�a�k�I�������wC��Z{�a"R���#O�!��C����W_GH�[�Ս1FVP��|F4v14}��f\7N�f@����Ԫ�bN�Zx~��q�X�Ԣ�&?͝(��2�@�PY5#!�YY0 OqJK��KzrpK@���쒎��ˆ��2٪�����?=#��셜F�lI�C��`c�VWЀ�v�2u��/aq��R�QR�06��Q`%`���1W:�1lL��L�"�W�+tVTi����
V`>�H�2�����҆t5
��rҁ%͋�,[��Ӣ�F���Ɠ0��_��D��/~��J�����g:d	F9{�h�|�6��	yV���s��eh�'�6q}��@���󯮢0c׭ӄ%����䄥U�)֌G�d�;5�T@����0���R\D�h.�$�I	��F�^�e	�.�� ��Qs���jz���oO!%�]��8�l �����DN8 ��D[ʍi�>c�_F-&�d��*��"�G�;��$�HR1A�'��pWߺt�N2:�+ӣdH^�תr���0��kǹv*��8��436G1��t,p�%ڨE������5��ؑ<nq��GgV/��������k$�����JGTZ.���z�Y�dZ/���\,*�\�M��I]���9Q �e�dj`Ae�$1�#����젩i���H��� }V��h�1��x�q�o�qȅ����3������zs��41av�����x���9�H1[]��o�Ø7�nj
g�yHP9���C�s���z���A��Lr��|�c���8Z��d%x�Ic�V��%�aD��[�H�m�=k2�]��53�N�([��+�/���?�a��#��p 0���]E$܏"�P�/�E�m$0d�$Z�s$�������)�I #����R�n�X"08a�/��b�9��;pA�q�L ��GSJ��ICBg<�a(Ck4GBS�`>��AM��c2��)��Yò�!��Y{�M��LW��� K�1H�#���/Ē�Un%����7	�Q_�6 ���N(��Y��6�F��WS�M24�C,i�dA?��M3���ۨ,M:�`<��I���i7�J�n��r��+4{��!�˫�W�S΢�{	uV�y��h�:n<3g
�+�m���W؄�B� ���Q�E�ЉO���y 83�,;f5�텑��r`���9X� �z��4����K<�YB�I�'П�+R��	�1rj��,�F�!=ʄ��6�w�S��:=��bN�������F/�c`�!��$c]������b[3ܾsԉ��/U�*{7t>�7@�@AXz�τ��5��z��|���QQ�H�q'3dR�\_�P�-NL+�\����(GE�����ũ9�<�����AH9g��2%Itg�ђ�t]���Ň�qX����iZ6]��� G��[`�� &��Pw��D���Q{�t o51�E2�gT;ɯ�D�Y<�2zi�4��,W�7����EL<���(�a<o߿��J�ĳȵ{��ռ=�G�g@r=���C>����`õNR ;z ����`Be���[��C׬y{��=�n�:S�;Ȳ��`�nҖ��;vԼ��3�  B�2�6�Qw�tt="��l97Bb?�g�1xȜ��*�j)%�j�o���@a�mQ���E.�QR
B!��F�H�Ù}�e'C��"voC��}tG0��8�A<��L
��δ�ٍ�6�.�ei���$Ec�^`�0w��6L97�Y�y�d�l|"���>�e> sTp@�#��3<?a8(&Ή�J�k���>+hj��@�M��P���� �a�q�C��I��5�p�q�,rSo��%_�����ΐf%�OT�!@�7L">��EZ�ِ[3��JJbM:m�cb:�Aj$p��Cn��1��|��MVwY^.�9�'����<aVI��r�{�u���Ck�r�3��H���'���y���pUt��sTI��BPJ��9@z��3���Ϊ���F(u�(J@W�p�����rD	�9|0��h(,�<�Jy�kf�v%^�^�0�=4�f��z��L�f����>�	a���_�,&?&���Q�P�z oeއ�M򶦸�tE���<�<v1��Eet������U�S�8[adǄeD�x�h�����OS��l�c[�Ț������a|R:�Y;j�I�jo3m?*���:qd���ْ]�e��8�g����2�LE�]�6�0Ӿ�R���H�U�d��C�#dc;������M�P���<+y'Ƹ�4+÷'n�Ԩ���\l�
��9��c{��=4nHh�/٩��8���r&ՐXT��k�"�?8�O�.ܕ06���(�cሑ��$�BV]�N�����0�Xh[�(�9��	~r����4x�/����)`��L<��W~�r�ܛ�Z֧l�(�7u}#��"���ئ�8Z{Ah\'Wn;���2T	�6)�vq�J����
Il�l��� ��ZM\�I%��.;�:Fd2o��]W?�O�Kb�h�s�=[=�0���$G@�y9o!�Z�U�D,�9�ѩ3�MJ����P9 I��D ��l�2m�r�]�ϑ�U���?s'(uj���y|�j�h�Q{>��w!	;����(h�����6��\
���g���LJ�
�S�D�~	��:��BNY�E�`��(�SJ�r�OZ�Q�PIʺ��['�I�\#��ka��� ��q���@h�x�4�@��G�yt͜���
+'�i(sP�%�� ����S�-�97�F��-0��pGb6�(_�?e5�	D^-}4���n��J7�G�"���c+��&C�m�����I
#�.����d~W��Sф��Ԍ丫�.*��|D�_`�%���&�+�J=�;U����H��س�H�!�h��*�X޴�q$f�m-:�f�8ru�+cC>0�hU�I�Le%�<�!�=�mSºw�VH$:s*MI�A3��ܙKp�\��1�	�8�̖x�z~F�	��s)F��e��n�8\{�7� ��j����o 0��1�yP�ܳ�-�1ߑc�zvW"��&C�T�@m��2�
��a:���lʻ���iL��#g��K���]j�α7�_�?�]��
!x͆W�Ug%F�z�˨� Ξ6��7�+_ ���x �W|��p\B�N���]�%J�9]E&���2����N��r*���RN9$o>���u���7�gX2,�DL�P�v�K�nT/(Z�r��S��ӏ�$��aFr�-G.���}]ђO�U,�_I�q��=d$��6$!��
X�}��$�5厖|�D����(����z��S�3笕U��S�����KcL4� n�h�q�U�B/�g>�P�_b�� �IG��cO|.3�
�Xq�C�5�:����'�����F�L̉�ᣚ\��-��*�W��>���[0u�Pcţce�L9n�/�o�k 5�1�Ygm%�<;Is� є�\�\�	;K��4��\� �vp�Z~��p����W��"c�NQ����`E ��u��g�-S<�h\�>�f8.9�X<W17P�N���1�:���i�0��3�>0媤6������u�M���g�H>�|:�>O��JC�Q�����u��*I�,uR����Kq�j+]�3�j��1͌�5�)���� y�)#��S�����U��sm���.�-���(H���Κi��F*����񘲛�����~lⓜ*i���P���%��:�YM'�TF�SƣKg*����v
�y�bmN:�Ƃ'��6�mmB{B�(�0a7��6�����-��]�T|_��8 ���jN<�ܰIK#�o�DɁ�AAʪ�~�В��QX�YqR�A�KP�5Gr���H�.�3�+"��WFB����� XAQ�{��HoE߼���J��\���f���
�^�:�(w��=�Hc�]NML«�*�PCAzv�x�������0���a6�cU-�uV�f�gr;��'�94��E�%-(/�R6:g��.�-n˾pU�*	�.�G��ҧ?1ӛ���⊼O5��$�+�	�i$�)��S����2LH�|i�)����uK��eSv.ѐK��T)��pQ�AN��a&~n�֞�sY��s�r�W��X�02��:�ϙmi^�4����*˩��b5�
����ʧ��&��
�.�S 0�ҩL0�M�s���$)��:���p��i�2���N[C05Ut�:����؜����Ց�s�����s6<"��6
%��΢��pw�0�r��C�C��H�-8R9����֥���k6�����)�.\h<3I1�yWwE��] �RR�IYJ�m�y2ֿ�υ���V��,}���z�x���pK�i	�@�3w�wAM��aG�M]��0`>9!��f�fyeRQ����:�c���ۜj ��L�f�δ�-�n�Lg:�N��*>Dj���b�V�1
�)-��}�ش�L@窫���RɚN*��.����y��ͤ,.,�eO��]��G�p�T����v����jX$�I���UM��,%�q�������!�o��/y�|a�:�E�l����SHO2ڋMA��Q�[!M��*
F�xrHy�f0
&K�&�$TJ,0�X�j��Dj�;��L_���)'$'�՘�RP���R�F�W�H�'�[)��s�+�fݬ�K�Vm��I����;��Aǒ\�)2|�NZ�
�I<���$ZI�Y����J���{�K���:B�8�#�x&����5�G�ꡏi�'Rt�bK �����5�@-[��R'�������D��ޙ�󋆱.-���I*&��L�O�i'U�dL���S�M�`:7�WW\S��S���I�vw#�z�Rت����V��#X���ߧ����X�o�z��K�2���C*g7��0�p�G;غ�,6L|��=�����
�]��v�H�د���i�O��A3_�穔7�G��x<MC}Og�*sy.]"E�COMݾ&��w�?2@�Ì��]E�'"jɁgc��t�]��.X�XBE�q��#�F�q�,�f�����)�T�:���5?�\t�aɘ�hd��9;S�����jF�M��Z&�K�A2]t=�G%��X"%y+	Kd��Zy7OH~j����8�h���ak���
8�٘�d
ŻI�^
J�1G�JL6�y�:׺���bv���R>P/�8m�)�o�.cbq�3Z�����*����:�`�a�o"�{�4�.B�l�d�@��0��&��iϻ����sp��/8{pp~�����a��I���4�d-�78JN"��x�dDw��u&ԅ�ԈubD�g��	��ʨ�< 5�`�.�E2�&�+0����A�B�/�'�
�

���[AX���בj��]J��Lj��9>�9W�����3B��8M	�Q��M`馜gtv�j�>F��7��l�Xo��(�B�'3��j|]k���@1���E���	|eUp���- }!��:�A��ř�}�AU�&7����kq�(!��m�bd�T�[f��s�ْif�s7���JR�GQ(�KxjY�ӊ���s��%	�Lؠ�xD��n�iRÙ����pfq��G]�s���w��������������=��5��}���Iw�Dv��vNN�����A��pwg��b��v;���I���=<Q߽�����qW�t���}��������p������o_��v��GtCUz��a��d�{��x���uǤj�cvM}�s�����|p��|������P����ã��1 `������������mKC� �'jwf�N�&m5t���m����;�;�/�V����>tA���ȷ^�v����G��ݦb@����_�@��;``�u���ؗ3� �	���?x�"潻�!�U�ݗݭ��7���n�_�u��' 4�������s��:����"<u;;G�����#�r��d�����&౫���c�#u� }���ELu��5��D�T��;�u	�M����p�a(&��?X��H�@�l��e��:����8p�x�$�yq��y١��K�n۝�η�c�2��@.�n�������=�2���a����@���1B@��u^�F@�ׄ}�3w�˶�2Q�݃c��`�s�Q4b��E[u�Q��:[[��`�a|Fs�v��>�Η����v�7�������"�a��BI��8�7\|����z%˦����zK��:�ovh;J?0��	̎ ��7�n��P�q鐊+���3'b���#d�~o�|p���я�Q����
W��f��S:.�)����%;@gX�VPRx)6;�c�R>	�[��	y�>��<��y*������E<r�^�3qt0�H��|D���-��)���}��k���y�����u��8��D���"o�U@�D��^�.��:�A�������9� �S������҆DF�)�0�Ľ!y�M����i�_���]���Q�O¿�W߬j�K�6֗�Q�X��CqZ�U�2���	�!?tpj8b��X7��O[P��f����ލ��_��t��E�	���AI����������Ʋ�E�$%����z�`fj��U���
q}���u�7g��s:N$�ϲ8`%4ŉ�A��F�i-ky�����t�@"�����~O�V���-���o�[�x��A	9���B-9�=�B����ڌ)�l?Z����˖M�v���!��!��Y���䪴h�ju%�Vٞ�s�XA�`i�eV|쪨yr�)^�*^�[�a��Cl&�Q�p��d6��u�K]9���%��@�������d�պ��l�'�f���t�G�PS��Ѝ[���0�$�7_=N5��ϗ�	V�»B�	f���\A9q�Pɲ�Ζ��r����M٣t�+M�Nca�)�m�b�n�^,\#GV��~���N,�!�f&�v^�>��~�Z2�hMe9��
�ot�����W��Vt/�F�;&��Mx7�C�Ɠ���w� =Kë	�)\��-�z|4�П���=������T�`@��	l[���ƴX�B۵�D��z�V?�kh@3�5�(L@g黚ɛ�!S�)�ZR����
3�_moA�7�EY�r�о��׭Q�+ q0M.Vǫ�0�)�V̝/ML��8|��s�$kh�@�j����mؤ����=�8�q�p��[,���>\9lb��?��Y	�/�� ��ǌ�Z�+9l�e�\'�QB�g�,①#��q�%T47�ܙ#��?��ѥ�E�����[� Bv1,����,�(�WDk������a:��)4�K1ƠJ���U�rx�h^�OF��t<����?㧟�ZG���^�9��>VWW��+����wu���g}m��c�~������~��X���nl�N�~��x��J�F�A��`��<e��'��S����(8�˞���!�^nu�f{~�&������[ʥ��
�.I�2�-����Q�(��AM�82��#���,�AL�t>��F�
�F��-��2'�}��)ú�N;9���FCFX�IL���0p��L�N�n���b��������0m�j��d���v�4���-�%:���w�C�t�&%�*�[S�f����Yo9�k���V�};ò2T��s>�6�'��w��#iu#g �h�y ��~��L�1<Hg}T3>x hi�ۼ�A|>�BTr�$V��7d7D�5`�$�.A
��ztŀ�8���Ŝ�y)���ĸ�,���\��HE�
:���e�)�>W/��C��I,yUv�d�N���?�����1n���Ge.�d��0��Exc�a�My��i�ϟA�]���Y4��W���{�{[�!X�{��@��&��y���=C69m��P�%��S����S�	���5��pd寬2�:J��^� ��^/����7~����m�wK� ����y��j�V�-�R�U�L������v{��𴽾��ds������&�"̎��W�%N�V�m)�1�����I	��Z˧����8�{�uW��:����aex���L}} �v�{��s���'���7b���>�x˼�������`�y���ކ�[y}(�vt�(V��:�М�2�]cԚϣ�M�.惓{��0����w�N]h�s��9MS�#�f�T��&݂�n�XF&\�/�m~�i.�^��Dp.�3��~41����7o��]`��
Twa�Y|�I9�	��O�����& e�����p��*��3�Λ�R�/p��&Dt���0��ԙ�d�4�c��G:�E?�k7�X�/o��,콝M�>���;��S�{,��ݳYѭ���]^ŝn���j�k��~��������s������jMǓ����($��+�))zN�Vлx� �0���"��/.�l�{+gc���3�ڜ�dhfq�:2�ݯ~�J�jY�c��*�ዛ����M�8��8A����0U�oT�w�(5U�6%�0��h-~,��D+�?Vj(E
0���	.���յ�����������Ƈ�#��jsUk$w���/s_��Ӆtc<퀋p4��o��uZ��2]�6G�\ms!$WT���"����|�݃o�h�p�.z�{�u�uptC�-
ⶀ�o6o 7�k�x����Ąӧa�7B���5��[������̃oCA�Gۯ�N��_W�(�[��R@����Zs��n>l���˽��w�ϝ7��xp��~���s�m����z�~�������������/S�|���5d(��֎]��ۭ�B���0;����qkt�����nڊUo���Gt|�n�~������1��{�����
��6�j�m^꜆gtJ��j�y�ѫ�����뇀h�nw_v^��
Oo�}G�<�D*�ѩ&Л[�Tz�nܒ�I�}����	;��t+��$�)���Z���PB tߢ��=P�h^����S���{���, (�g� ve+��#��sԏ�w�����O��6��!6]@�y�b��߼G�\��9Fv�ל\́*���#���47�vm�w�`�|R� �*��/��z�V�%�a�I|��$��`!%E�����c*L}�y�_�⛡���f�d��T&�E��*�&�+D���������P?���~�C�b�bO~�䓧h�G�t�(�`ЩZ��C��B����{jk��Z�Pn$v��1���-��ͮk�E�j�gtl-P�Z��j.׭�n�R�Y�~�F�$����u���@�#4��7q ��������r��88����ZS9Sh-��L
��luv���v�q�v ؇���>�x��ů�;_"�aV���0Gz���2\��j��B3�>�2$L�H�v1{?N�a@!�|M��glH?�Añq)�TS�Ɋ냦�3��E�hnQnFN��>�4�ƽ*�i�Ty�:(>u��;E�aM�E[�v��6�u>t�,S�d�@���Y���7쒛^gҹwoht\F��N��ӈb�A����5�:�0n��c=�AŞ+q����,�K�RT|\��w^�rs{n�T����i7e�U���.�NP�s�61����x�,�v��00y+��s�
����a=Bv�5�@7�h:^;J�t
�7}���ѵ���B�Lu��ܳ�s�;�p��5���Xߥ����&y
q��3ԣ^�Bs"�g�{��(,-O3~!���EmG�Z�->��+����Z��B�)�&�/F��AD�X\r��-�$QO��W�l�����ٕM���]�����He3��{�[S�Д��9�y�����ㆄd����]e�}e�M;!�G��T�
�J��
S]=Q�����Zt�G��N8�?��'�3T� ����~�	�R�bY���o��Ԗ�+M�/'$J5�����k��0���"&� �����S<�f���<�+ؕ�5���j���c��es�Ϭ��?x&3x����6�F�<����؜b`��h�9���΂���B#m����*ͭ�r՚��̭>~ �j��c.�\�m��8���/,�#՗6d�e}���57������ח^���ypS��N�����3�9x	���#�E�� ����	���D©��F��¸��;DC��a8]��Q-��6�w�BO-h�a��!t��j��O���/��r��uE�
��+&��]WŤL�
ݯ�ҵ<Ǣ&Z=务!���"�i�W
��L��x�����f�Z� ��Sb�k��wQd�:��蔠?��F���N���ub�i�J,z�UN��WL=�h]��#W/��,Y�Dq#��ׂp�^��vf��De�t���14�b�1�p[�i�c��tR��Ϻ2�o����;֎�P; �!^֍�6�R��)R`�3)8�W޴������b��D�t�A��]�y�Nu�:E�v�w�p;�Vw�m����׃���qcW�����}T�B�U��Ү�J�q�����f1&�&�:���s"����A�P!�0� �/ܩ��Tƅ`��:a���ی�A݆ͧ֚y�!��yWE�����~g��S���h��M4v%JENYyds$�g�{���>pú�Ϡ��Z��k��>�l�uv�+p�p���w2���_�����uBrUM=���*���I�P|<d:�+H��S3���+ϩA�ةt4O�x?U�O<����ϕ,v^)ƹ��͝'wT���v=����(F�?������`mM��G�Y�d��v��n�����F�����P�� ��;�'>�ݘ�+?�u�c�����I�:�n����n�Ns�/7��ޠ���^��-�'����9�F�1�ptR���z"ח3	��� N�Z���nw�=�i\EO��@ёwP��[LV�
s�֍AWJ�Ⱦ��;ų�p��¢�T|M�h$�9����n���r�*�u�F���s�G�Q���+��c��sTHE�1��0�4�����(�6��lV�w��'�hw�+O��|/?���:+�Q#'!V)�h�)��N���9��Z-T��D�\��gt�������ךS|����C��UvIu?���.�aX�"����#*�2�ժ}�A��!�@+�4�%�(˰ȱ�9��v;�r��X�@@s�o�풡3��������<Z��rh�n�xh�|n?��?C��=�����%�c� B��ӹ�t%�O8Lw.�Ŝ��-CrN��sRw�\	sx�v �~9K�����K�����,��]ߖI��ve&��t����w��ߞ��F�O�]��oR�1IΙ���lګt�H�"�G���ک���:
��&9�
l
�_�00��Q��O����P
n�E���L�QK�����߼�>�ri�zb���=�S�(�R��Y�����ӡ���HW�v�6�lm�.=7MG,����F5|�Iǋ ��)A�F�,�3�|Z�Ĳ����B�Jv|C�v��������@�ݟ�89�u��pv\0�E�lOu��|W��J��84��,�~8�40׭�NL�i�8�����B���R�*~�(�#eB�L�NtL�.(���hC&�l�,�l.b���,"�"�n��lOb����4J\�E�yA�y�E�1T# H��b)Rț�������WzDP���f��٤Ee,=�&S�P��Sh����;G�o�5��&z �I#o>@�F�%#���V�&����d966[.˰�1��jSu8	�P��Nr���$�Hg�B��9����N����w6;G=�a8q� ���,D��S��k���LU�J�qQ?|����cXo���r<��ep��VI�yN�`G�[�(��mQ��z+o�7������������ H�ab[iq�:���ΰb�\���~^��t�4�NB:�s����������j�\��Q��_��Tӛr��|^	'[,�.�b>�����s�������z{�����x����׾���5>�1p�"�1h�[�zp;'D����j�������L�c�s'p�O�3��z%~���x3���������R��Ǐ}���Ƨ�$j����Q/�=>�{����� ꯮�>~���:X��Sj����o<z|�>y��q{�i;z��� i�i�=z���x}Џ�������z��WW��>~�����u����p�a�=���֟�Vݷ��� z�~���Y����W�=y��~����d��4\����|ģ���O�ޓ����Í�^�ۀwW{��퍇��꓇�����:�Yy�h�>[];��z����ٓv�0l?z8X{m<=[?{�8�o<}��w��>�=^}��	�x��_{�v��[[o���Gk�W{�$b�s�d�����o�m$I��goƧ�/��c{�8���=��n�D�q=I3��H��ٝY���ԣ��ݔF��N��Ab8�����H�v��]�a|�� ��	�� A�@�﫪�n6I=(j�۵;"Y��^_U}_����a��-�Zj���T�*ղ4_�q�e� ��y��Ztb�����VQoU��RQ�JR	�GK�T,����|�+ո��de��-I��R�U�j�Z�R�*��d�G铵Բ��q���b��HՊ��ZbIVK���UU)�[�F�ĝdF�T��s+ڪ*�[��j�|@��<�&`: ��H��V+�~P�&�^.�4����*jP�BQ��*��H动����9WJzU�E�i��U���*�З�%�\�%'5Y��������甸��X� ��Z���[j��.�ud؆�G�B�T)��V�Z]+�R,�~H@�v�(��v���d�HJ�骄۠^�ʕ�(i���T7a�Kv���j�d��bi��)嶎�W"�#�w
�������p ���\n�m��6 cd�#���^ZҪ�~Q��D��.hEj�D��c� U���P8あ�E�P��2�Zvk^�`�VR�R�`=IՂ^��%�\�R+JM�UL�NZ.�u�c\�[z[�âO5	֞\n�K"?z<ȢҶ,��
tc��Lo�� �!�VQ-����Wa�+EM����R�U$[\���--�%���R[*�[��`_��v�ږ+�R	𭢪�v<L����	��M��"���y��J��*�V����0�z� �z�dJ��BE.��[���JRK/ʊS��Z���ФyM�lZ�6ޅas5�PU
��k��5 �`q�9]*����J[Z@��,i�^,����
�?lv8
�%8 Z�)UIъ}� �
M�A�	�F�S
��#�Ȣچ���i��*���"agQ)�����p��֔
�RGn��'gIUZ%M��?
Q�r�(�U�
��&KZE�aP*����*h�yY������˱=��\�ϗ�U�ZU�ZR�y�Նv���Z(U�UX���x�b�Z�������*�uܳ�l�u�0���J�*�9g����ܸ�$� �jIj��,�n���ˈ����y�1 �:/�N�(�S��-USt@SE�ۢ�j�������27@�����Օ��Ǎ�t�\Q m`o��U�Ү�,��S$ �]�Z^��h¼Z�5]�%!��-�}���Z- ���G��S����9=�g�ى؀|_�4���%���bK��`�,L	��n�/8�G�����$�(�/;)�0��	�?�p�9�%���I��i7�[+ڂpk�`}3�ut��yZ_����ȷ�{�}o�q�4}m;��8�.��9<Yx g�۲{��sB��p�tM����(���a�O-���	Ko�@�v�5r�*ܶt��:������1�[Y(���_�֪⸋����!��%$�s10�f!~k�f�h�����%)$���4ny99�g�W#�$L4��n[wm�xX&�A��c��8������D��`}5[ȉ���>BL��a-h�@G�n.�܋����8�B4�8���N��J:colֳ�19sZh�ttd���Epb�=�i�_!hP�+��<Q;7�@cΙo��Ǌ��	l���k��({��d����:�Gp���g8�h�h�����tLM;b��y��4�ў���s!���-e��ݭ�6��k�V>�S��7i�u�9\XK54&$c��KfS��3}�\H�,j�����8�`���0�\�|`a�@�eҩ�V�Ǝ�pu|ha�\�B╱��W�:��}pP���h��07+��	 ���Ỹ��?�
4�%��uz8x��Cd<H�~Ӧ�ፐ�X�ΰ� 4����-����T#JC��%ś�E�&ɪt]�.��{^��{����n���E��ezJ�\9�K��I*Jb@������2���s� .)0���@ؤ�}fVг�E���� � /<�����$���D����E͵x�?��HJ���4��� �9C��V��+��y�q�Wt���7jO�>��NE���T�}ѻ�bg��A^xNM�yd�독Y/���� 5 �^)J-\��$qZ5�f_m�h����85�hU���@��Z�\ޝؼ\s00�:rZ��ɑ)�$f��e ��Ɖ�z� �=2ԏ&���xp�Zḏ����q��ă�u��#�V6����׌Gp���,?#l 0U�> h,��(��Տ�v ����S:�	�:���h���Y�Vd������Qm�|͒C N���9�*�Z���C�����D��(��IT}_��	���d,~ˈZq�GHlreҚ����~eX��6�j����Tpv��'dU!*f'���5}?���gۨ:��2����gx�e���p�����t+���nA,��~���ϼ'˗9!K����o
Y��1d��2;B�kW��bo��~뺬�_����
ghV�i!ۖ�fԗ�h#^� �e{Ў!�+�I��jKD5��-Ġ�w���As����&`�{��(3���eV��(�/�;#������e���y0��=������d��rr{z�j����}=&St+�����e2��/�Ml ��qid�\�����P.���sA,��?�j���1́F���٬�)�匿 �l��q6�ڰ��M�B����BF���)��¥�a�N?�w}������Q6�f�)���9
ca�ޱ�:���N����ܺ�}�3�;^����\H�-@��v��֥I�H�#�2"�J|^"����(3W�5tM�{�Z�eה�k�j��h�iu���\[0�b
���������y~M�6�tm?ʡQq�qL�G�]���ʼA�<�C;J'v6�h��҄^7��Ƹ
�5��0�-��Wc�*M���'��\q����P9��F�Óح͆��/hɒ�{{�H�6�)��׬>�a���̍�˃�'|q��A'��a�f���.ȄRa���{��
�b��c��GA*���o�?J�����N"$��{���\^�*�Cn��W�����:8�>���c]/^��� ܤF&p~�e�����l��L;��E�lI8N4�ί����r!"�-WP�;���?�$,�܆J�	���NE�d�@<��5�,p�?��b��ˋ-���~�K+��i�m&��N<��	k+�g����[�I�<�N'�-����T��.H�By�aa�
?���W�o#ֿ\���'��/��R��'�����*2_V�o�@<��h \4�6f^m2�Zz��כ�zю-�������>{�gJ4�B��,J���$B�}~uw���[A*��70���O"D���K'_��J!����
�R��@��c�c8�'a�G��X�$�߄B�^O����:=E?g��g�f���������ts[j���q78	IHB���$�%����W.�IHB������>��_��)�~�}�ŕ�a����>�~�X�+��-�9�>gا�>��_��l�J1�#�jN1%5�>�y�D]NB�Py�/O�S��>����ԗ�g--i=W�����������ڟ�M�����唟nMu�rSZ��|M�����?]����_���Sj����R"}�.��H	����[S�6eL��5���O�����4m`ZL��i��6�KGG�u�t[���_���E/z��G�+_z�������_��>�qc�:h5�{���+�N�}ߴ,������As���ǜn��C�O��fܳz�y�%\�zu�js��~*��9A.T_�	�V*�P,�_��:���H����;<����?�k�[��?��������7��t���\�}o`��70W�_�v���Շ���5g~x��F:O��Ms��dlE�:��
�<U-���q�3_S=l�z�4Ƒ�`nնLs�r��3|tĴ��g���"֜��9��q����3�Ă3����C?����Y�����u�k?�#_�v�#�:���Csw>TU'N��ku��7Q��kW�q�����c?��?q㧼�h�陛��z-㓞��:�o޸���7�ߙ�JR����1�z�զ����3_��wo�]�Q�7h5��_���8W7w_H̍���vu�TZ�I���ޛ�yx�)Sx���_�;�����g��Cj��x���b�(Ұ��;Ъ
���~��UbZ��������������7�z���S?9%O-M�N�`ͧS�<��S�5��So��O}o����hꏧ�����oS�c�N��ԕT:5���ԍ�O�~*5�S��O���咽������T+����˔�rS����g�?����_J��ԯ�~5�k��H���o��V�o��N���Q��� ��R���ԿM���L���N������֕���⭎����CCq�mW�� �����k�\���?D�O��޹Cp�ǅ
���GL���
z(F� �č���kooA��j���AD���� {;���i@������_�
���;=7==s����߾6�%Xd��(��=������|�ڵ��`]������eX��嫸hg�Έ��|��������˩��~$���7m��
�m=��ZN�O���S�Fj+���&A�ݔ��KY�W�#@�ש�O�9@߿����_N�@�_'H��R=�7R3�[��N�N���! ���I����A��0��x0�r'�����o<�S;f��)zw�)�߰;�^uʿGIB���$$�R�/������'!	I���[K��{S�	Y�k���y��?\�C�Y�/���<$������$|aC�+���q
��R%���H�sczu�|��r��3�0��X�.�/J�T���XJ�?L$�;EB��̱�-�fS��Q���-<G1?O�V�������\�njˡ�Ub��7Ǆ@q��^W���me�I����n�߅[hl&��1�b�ǳ���a�]��!h�R4�������p6�3BM�d����3�D�似|.A����tt��Z.^��X�@�X�K+Ҧؒ0Xt�<�	f��A`]�f�3Ǳz�J]0q��Y��e�"	!�?�g�x�8��gQ��_�����>��P�i�rB�M$��Ö</ۜ����1��+�e��kE,J�(�r!��3�0V{�}�?��k(��i��\?��shw��O��~6�?�G���~@׏i�z�P��_=��	��4M���͙�;��t���|�2�sS���>n�>co/�8�Z�j� 28�5æ�&�;yQl�E�&9�j�ǯ�}����'��8D�n~2^�>;��B��R��ov�X���}���|\�x��ml�-x�:���h�����H>�\ ��:��s.�l<�?��Jc�\��-�墱��4������YGG���u�Q�Y�"�՛����~+�/�mY.^�c��u�Ԑ[�?^�X(,�Ԕ�:q�@��w�2�^"�hu:��$�����7 @� '[�8������n�][�m��V�Y&�c��A�g/����5�n��&�p(^��ձ�]���r����t��[�c�1u=�"�\�~���Q(�.�=@��:C#��JY,�����O��N($��d����r� �Ew�LC����`��v�h�>��9����}��mb�S�4�c,E�`9;��kÜ��z'w=�5�n�?M��®��h�����N���C,1��t[���d��=�Ȣ�'|� D���uw���P�;����Jvp_���V)y��9�<Z�=��@J��b��+) ��!�UC qC��.��@7\���2FG��(����"`�`��ml��v@���m�:t1Zj���BW;5o����.��~�f{����K �M�\ �tw��^�m��DҺq��Ս�hNVmo� �u���#9,{[�G�ӫ���§����$��\r���~��ԭO��J�ioJ�ֺ��z�@�pm[����wv�?��}�՟}�����dwcU�sy_yb��⃣����u�S*��4:���-+z�X}r=�v8�tB�Xg0�ˌ8�FF�d��^n �f��Y���БC<!�`��˚�����Vo{'�wA( �d@�pʶ��w���r�L�Z�t���:*����'k?~�GKuܣ�6�4u�5�a��=�?K��|v��7S�t�x���J^Z{�����>�@?�=|���+����ݣ�G�����������泧߭?���s���ߕ:���������W�����������|���'�"o�t�����8�������)l� F�"�`xtGV�4>��,�j��6����K[�>R�����::� �Kڬ����K��� L| ���s�Q$�a���J��l/�^e;�k��2L2^�3d�̐�΍ϰ���������h�@����Eo�Ȭ)���8;=W��1�P�E)�,n�{J��Q��'���J���'���Lu���)d�{��������L&0�/(�w�[riw�2(v�]� ,o��`86�\��.�P��h�����֑|�	l�	���}�, ���2��n[&бHv�["������-����FJ� ��|��Ьv�6)y�>�������Wgv>CP�L�c�@%-\׮��}Tصl[�u�m�`#��w�;��#X� O�9�TU/s�S��M��Ґ=���D� !�u��BL�ί�dz�ך~c:}�`)wNpЃz��� 6�U�4���Rn���@�����Y�䭮��l��L_|ܭe��b*I,��S]\���sRP�/�=�Ň�ŧ�W�Z:!���� b��V; M|�͵�{q������DC*Ҍf�@˹�\��z\C������m4Vk�0���^C��k�ǰ�<�u�xef�Y��'��X�������>�j���������j]�������ʾ������l��\�O�B��}-�u�wi��>*�P� �8�|�t�2~.��ŸfIEjL�����.��Z�.��\�X>!��u�@���1!��Z�xe�!��Z��t�f��ߧ,�*G�F$e�L(V��r8�@c�=�>;N&�	'�����}�Ix��o�\��Ke��_N��I���,�7`u]n��qb���.}^����c#M̳���l �6� �a�J0���kn�O���#�y
=:��������i��ܔ>Z&�r�� �{���SL�u��#bhz�nRD� ��#���dX%���cj�
@#J�
�$���!��	��&���Wñq(�c���ŵ��W���	�q�v�c��b�UB���~>%��(y��G8��f���R)m���i�T����>�O"�+�MnxQ���G��#I����ܘ2Zz��.c�Y�.iA&<&aD�֏ꦿ����Qy�3v�O.{_�[p\z?]�n��|9�&������=8��?���_.�_���\N�&����/�0=��e&���T�W�����`�i�KA�3�%O*�V�v�(Qr�\rx����tA4Q�����t8R��$q�"���TL��I��������.���] ��*�/�T4&<�a]��?�W��H�1AF.�����7F��=8�h���DN�w��1��Q*��� NSh�6S���n��M��&{E��V�2t�q�����W]���|���x�U�#Y�	  �cB��Q �]�7}��=M�gC��U����.����,�~����"0�ޝQ�uWw�3v �>~d��p~���Y. G�����d�(%��	}�/���5Q^	��+��ċ��8�Q��r%��&Ʉ�+��o"a�t�����|<�w
�o�q~C���X����1�c�}�>j����Rno{�K���G�ܽ�^�cK�#\��9�A���g���m����e���i��('�"SP�,\��3k�.��10'�_�)mpLa.��'k@bC�
�y
A���,[d�ϸ���c�l���ĥY.��pIV�ڶ�'ܢ��Z�[��x���:^��[�䁣����a_����<�K�7} M状���cA�CA�1��άs-ƉB3qj�ֹ�$ŕ����If�.|f�n8��-*�N[D��9p���C��9p�0�8�����rX�9	*p�x�Р��C8��q��e_���텟�PB�`���c����=�'8ܞ#dw������i�[<���Bb,�X���W��"W8��B)���`H��.������/l��M�P�����J�ǀ;W����p��M���z���-�ެ��,%^s��h<]�Xz������u��cŃ���H<�=A�h�v�6P�B^���=�ٞ�d��*d�ُ�쑘�f �m���=$~��0�َ �	�a[�CKo:��l�¼�o��8�V�}�>~7��QPD	����Ӯ�>;���,q�t���%�P����m���D���!�5
�}�ß���7:۰������YV|Ƶ��a�5��/lu���3��b>˭���a��Зk��_'|��j,o����c1'3�a	f�9�J��� ��F�U���zZ	.���wǱ�pN���X8�y�t*Po�z���/�Y��=xP�9��S��tƐ��=���0&	��(�=G#�
�J1�����(U�b��?�0.>-zA��iۊ�����K-�h��׹����L���*����s������W,@n��k��#a��S�N�>�G�4,�����5�{���&9�I�A�˛���۳Kk��@i#q6;'d`ĝ�&-�����i9 R ��<-������kŝ4�	��D��ގBe�P�"�R�W�qL����@q��<��u'`<���ނ)6Ԍ�p���̈́y�L:���ؠY��d3j��;�ǳ��x/�}���8Av����cdF7�iBZ"��gP`+�X�8~An�^a@n1��ʶ���oc�1d��1�iW-�0�57s���y
Ƅ�cX)�!C�2� ��cnq�3�T0j��qZ~;���E��oB���c���I��D�s�!�������u��&����^�O96��E����D�O�U��%��*�)�I��d'����2��b�n�<�z���KR���,S�υR��M"$�ߤ����s��hZ�v��� ���x!�t��}N�>��L_��]^f/f�p)��s�a�=���#p&�σ��|!Y����c�X���5D��`0O'a��
1��ٚ��)��__0#� Dy��_@v8���LZ�s��n�p�����lw��%aX8���"�������U+��+W�o!���p�?\]�[�*�Q����@����h���>�;_�9"Jܯ;��
~S3ނ��Z|��9�̡U�K�D��W�Nb�Q���:1Z~���Վ^��1�cE�� �/��ǰd���T_�Zv۴Z��U������C��n�z֓҄�V�%4G�aȶ�e߰�EU����3����0 Y��F�9��	8����Em[4��ː��>e����X���{-׆�BSw=��D��ј������j��~OGo�.��[G�/��:��\��]�������޵-3�����=ҿ�������p�o�.+P{��rrn�(�$�P*�sR���K/2D����n��}OPT`+2Kh@����s��w�M9:n�E��|�yY��6���'�ցV�~��<l
�9�N�.=v�;]� �N�Q[�����?�cA"�h,J4r����������R�?�"��)WĄ��DH��7����� �^�r�����y	�w��t���G�a
 ~PIz��g1���C'ԟ�=�_�@Ăi���(Gk�w���2_#SK���.���+<�m�#�8f;I�'ClK���PPX�NP���WLC�*��P�a�U^����պ|�.��rϬD�6-T/����(���Io �gay�n����4�C�E�I`Vq|�̤�eG�Ǉ����mPh~�x�~�K�jۊ�u-8]]5s!�|�]�?~v�,���,�:�=�u�0畔���X��c��Gǎ�]`,�C�E���:�N��O�Ԭ#��bR&s���2��,��mw'{�'����x9b��h����ɸ���C��x`o�/w�B��1������B����k�ܬ����%�a� :�M��.��[��g73��|�=XCA����J�Ruh�������,��\(G�Dj���'=8瀑��p|#C�t�u4�\]�����Iʫ	F�
��Y��E��l�o���@�D�w�e�VW:�q����$��j-h���b�S6��:�Kx�=7�c
�g��J�L�{8(��A*jP��k��
g����1a�~$-AZ��Fz�vp:/�nK�,t��p�t"b�G�=%�[z���[�j>�������~ӻ�[��Fr�t	Cp�t�m�� jyb�`lu���"{��e��Kh��\��2<�xty�bn�`y]��Uo�B<5T�y\D���u�$�ck11������]��'�LԲ$��N�>#�����qY�P�;���Y���,o=����T��!��Uqu/f�/�Y���]�~�3�װ�MW�ǵ
KT^9@G�J����H�r�T��v����K����l6���a����) fuL;����9m���N����� �Y�������.�s1t���{cч� ���X��OF���+����J!���HH迄�K����l���ڃ&j��X5�u�KO�P��
�FL�1�O�;���}�Q^�rQ�%��E�sI��\pc���w�SJ�?M&$�r�'��|%�r�/����YF���J��׊��"%�_'Ƽ����%��oV������1��c���C6��VK�?���?�O~�:��;/��dڇ4w��胈�@��j�v��)�l��;�^Ux�C�9�QB��D1�t��"O�W�)��qv��+��Z]�{���Bn����#����w��|v��
��ߒ��0|�b���&�4���8'��s���s������Ǜ�7eT)�:���e2��w���w���>>�z�;0�&yd�9�Q�X�I�Ir��S$���rB�M$�m9E	�7����,%��>�J�ͅ�3Aq�����I���JN�R^RN�RY[ 6�{��#�D�s��S]ӳ��ݠ^��n�(�!�U6���E����9
�TX��a�!h}�M���p���NN�k/ai�9a۶���C�|(�URKo#Fl 
��K��&�hpv��]�,y!���4KP����c�M��g�d��H���OK�T;=,��C�a�5]Q]�)���h���j�߹<TaO��s(p����3p�;����縟|�^��B�Jk� ��++��J?U:�S���e��q�t���v4RH?g[����î^s�$�4�Q���\���S(��j}�C��W�J�?-OP��ZE�Nh(�f��1y�4CD�o{:_]�D1�t4���zn��� aV��Zǂ�{�˶m��D�3�R>&#��vm�g�ї`Cs�'��B���7�M���F߸0��+����w���J��i2��7���%��ǹ�$���FG/C����� �Yc��T�ҝ��$)�D+���c:�{v�xz���&;�X�=z�'�����c6>k�8:��n�,�����w(�qkO\��mꇹ9��)@#a�n ���X=S:�$���QN]���;����L2Z���v4V���WW�+ �����#��9i!������b�ֹ�����JC�&K��?�a��+�I*�jF�I
��*�1��\�jl�=Z������8�k�r�����	ɸ�Q_\]&�/D=�b=���v,Ҝ�$��U����Ä~�5��T߬�C@߆��V��������C�"�6rM�-�l�ט|辐ux��ֺ�o*���f�g�X���Q Ã��34��[�A���*Є�Fx߭?���{	�,���%Y���`*Q��F��}�l[��d�.J!'����8қ��8X(@�¬�d�=�n��/gG�lFد��� p<�ƾ�~'v����^�Ɔ0��6���t�X��_����T�_�����w2����+��?No�Nva�>�>�kRN����?X~�����q��������ask���F��J���C��4����Q���c�M���8���?	#��\�|��P���/���?�p^�"
��[��}���%'�m��TLCq�k�*��#F�S���_L;�7	�C�o�,f�ۑF8�"���}������O.��\B�7��愿�'�����b���F�b���7����7�����;/���o���Y/���� 5`�^)J-�Ç��	2�Xda�h�E��-�W_�&��*�P�B��������2����"y��jM��H�&�-j/����~9 ��G�A\y<�Y� 2�X\{|��Bg�����#,�l���_,�fwN>�R<��g�<�  4c? X����m���G�[�����S>�	�:���h�-�f�FSx������Qm�|͒C N���9�Ԉ�-�^��+��t��~�k�_0��Օ��� hV�^H`�[F-�����b����LZ�:z��`Vբ~�.0�g��2qK;H5Ij��2\jZП�ʅ˩?Ćr��������f��u*�j���_3\nuxn� ��������H���{4��5��:;�Gm�[����&Y�~��Cc�j�ϼ4HAѿ��zQ0T���%���\[LXy�)|FNn?S�6�	��{�j��]Sz��g����m
�tm?ʡQq��e�=�ֻ���f;�,�yl�7`\p��ic��8�͙��~��:>�s�m�{2 �?� �s2Բ

tz ��6�o��7Wi�C?{]�=)z�h�nmv��Fe�N�gTZ���2�����>�r���~����i�%No�b��{{{�}�5Ks`�rf�/dl4�v�q���ԇG���[����ι�\�3!C�ú3;�;����� �G�:&�F��Bl���$'�?�F�@�Jhע��X�4�U�m*��
.��I8k���"��خ�G��K���b�����B��e"!�����_~�}>��iG�G���yO������>����]�	�M�ՁO��śa�q6�ۇ��O���\�ɖ��>��UZ�c�W���X�H	�7�p��� ''7�P$a!t��d���T_�a�����c�,��"�cK,v��D�����1H�a�ۘ{NX[�?K��e�ӋL�<�N'���M��]�^�
���\(/!,�W�'��L�{g}�?�\Z�_�Z�lN���+R1��$��S��	��υ��DV٥��h �3j��Eskc��&é���|�9����|f�f��;���c33�����������,'��DBb���}h?�H>�	�S؀9�	+l�&j�?Eӓ0��l���9y�N��ї��>_�/�ؕ>�/Ǩ��_���`�Nh�376��s>�_8�����x���UQk��P�4�Rەr�9�)��|&l&|����S�0Y��Oz4��3��Ս� �QюU������ϸ�[���? B�k4���a�X�u�#U�/e��*b%��9��<�G���	��K{Q��.i8{|>mN�� ;�{��R��E�q57��$ij&��FL���������L[��0[�	? �m���	��1E!��9���8�*����#5���q���m�n�Y?2M>������$$!	IHB���$$��?U91t � 