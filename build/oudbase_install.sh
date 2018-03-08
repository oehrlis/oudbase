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
� _�Z �]s�H� �ݻ�O��0111�M�Z�[$~Jr�ݴE�ԭ����v� H�Ll ����11����o��a����/���� 2�C%���*�$�y�d�ɓ'O����V�<�iZ�� ��&�W��ٿ�!z�Z�i�FC�M����xh����*�g�,�����~D��L�̿7�Ρ{�$(�����64�s:�@ U]��Rh<!���z~���
�@�.
+������[;du�`�|�Ұ���_o���q�  {��=��#��oIw2{~H�_�u7�Nװ�o;A�A`���&��U�zh�aϟ��{�?���p��#}d��2{v������$��|�c7���K���u�6H@ߕ=��!��鍠v�r¨���//w`[/����aܶ\ `EN�K'p<7UD����L������5}g��#�����B�\�&����o����e�Hx�l�.`>��^�I`[����v/�s���\x���}�W���'�w�ZC`a8v*����pt*l�dq@��ҧ��|T���;�U���v���MBpB�]'t�!��}F(�W˺�eZ�L����!��������-?��,��Ш7r~2B@�>��G�؎�읟����~��픊@6� �^����@ǵ���ǣ@����C�1���=:T��s��?>څ�,��ON:G{�ų�7�"Y�Y�5zC���;���m`, ��q��[|�>���F� �j�<�?9;?jvvWב�]�3dU�(�����v^���y�X	G�"}�j� Z_������˫��B��}zv�]���9�-�oȞ�j���OR�7d�{F����]�d�i�p��?h��v��]��?x��l^:��ǧ�ZA����$�j�HT�!n�����"oc`�o�OI޺��q�
,�u$��
)Q�W{�a0 ���W�d�5���䷥�K���-���#�����礴G�1��;��?��'�گ<�z�����j���E����z���6w�6��eV���2���Uݼ��t�����1)_�@�w��D��!��������94\�?\�н�7d�_Q^2�vjZ��7�	�-9�ށ7��	6�Oǯ�;ܰrN�����)B����pw��/���]�?L���[�T��?�C�kE��ˮ����n
K��2��!#,ƣBgD�����:����'�����7g�I���<��"B���k|�	H��5,w@z6�c��5�_ÐSP7 veC b��u@&��I	��&��-��"|!�B��;�@G�'��X �����s�Q�����v�9���[�x�L�zz:��;�2�]���=����[,���ߕ�GT�ÌW@�nhH�7E�K��\��f��m���q2�ET$�C�&%CZ�QMe]��%%>N?��]]ວXc��|)���4q۞�h%^��]fg�S�J=M���\;͛�8mϟg��+�l$������7�H�u�d26��G'| �h�Ɨ!<���,YGv�6�=�+�)�YfW�T8*�@7�K�b(�2���b���K%q�L���Iׄnk��M�G�����&��6! �u��7�ߘ_�J�� $���tR������@S����I7�/�����@�m�V��vH+/�K�����G��A~�M��z���_ʰ���3,�n��w�@��@RW��߮�}����1ے������>��cQ)B�>�7�:�]�(�p���F������H"z&��<��NP�*-e��m%(Ǎ#��Z�
\�f,�;����v���8(�%-	���',�SiqY'��4���<�☲>+���V��mh�L�q���$���7'�?����p]� �_á�,���e;o��w岮O��JXX(JnR�_���y� V�(P�5U�����>�X�eŝ�Q�Q
ʛXb��P����A��<�0�ŋ�@����q�Xͧe���f��fW��2d:~��;~��
S�p���� ��f��a�0F
+
|�uA�T��Tq�QB�%9p�"�Y�Ң�rܭ��y��R�p��#��N8]��3��R�?�*����m��2��2Y]�#����FJ�$7 ] �3�ϙ\�P�2&*�`��QU,!p��b�ퟱ��P%��~k��(������%݅�����͈:.�ܠtf6��I�L6p���B�ܡ��K�.Q�cRT:V׊x�/8ׂQ�t���؀"Cu��@����\��.y�|\�L��m`���V�?�=\~���]z�#<6| ��a�<�k��Kggo�ǝΎ�Rht,b6��l�K�1Ԥ��r#!�K�9��Z&d$��������~oJ�E	Ye7���AN;'�/�gx��ª��Re6�ߋ�V��Sy�g��[��C���q�!H,m>�(%��@��0��McX�V�Kɪ
�s	�D+V�o�b����C[T�!6n�  �ވ�N����Y'3e�$5X�vJp��y��w�+�B�"�`?16��O�I\�0\�X&I}��dq�ǝR1S}SȠ^QM~	 V?����;rÆ�7|�L����k���`B���B.��J�^�%K%v�\����to\�h4����~��b
����;��k�O$��P0�A2mQ?W�*I�lǎ1�oO�u])Ω����;�͆`�1�M=^G�M{�!kA�/��ReM�D������� e��S��&����&�^D *�T6��KhQ�_�|:zT޹Ryv360t�����K�H 3�T+	�:aې��؅�
�����%������@\lL��*�/EmKi{C�i�@�V�N��T.�%.>��`f|T��GEc�X�C��G����	��m���0ƒn���O2��t~���������z���iw���-����+���l����i�%l��3v��m��N�F*i[�sPAκZ�W�]�V��=��OЩ��{�a݀��������'z(���'We�E���`vzJ��?E�i��(	�^݈�-����-�ξi�ggi�C� �KZE�,�p_�#�����կj�ߩZfݹ;�䭞���;�?�7����a�w��,�{e���=L�Ҵi�T��aV�Uu���xh��/��������S|�	��T��A�-����j�K@�z��I�#���K�FU!]�zi�H�q�,}i[��y�G�3�/b�]�kU���O�FUӘ����?Ɠ�!��h��R쿹���������n��U����[�%+:n�{�L8!GjT�m��_�v�0˶�X���/�|���6T�_�	�#�kgX�#)�Ä;e*�}NJ#�4��jq����k/n���� 8�|#L���^T��p���=���6ҏj#Mr��F��6ҹ�tn#�Y��Bϰʎ�|�Ɨ[Hρ��*��VyIv�_ª4�����OB�����s�%�Z�� ���Pރj�lD	 oo)�N�:y0S�ю�ӡ搏aٝb�8���hu]�y��gT��w��w�2�x0;ʥ�I��M�8�K�m��Lj(�R"�}d��L�H�bB	#������1h$��b�6�fՂ�46A�G}^$l��*b���_��(H���`��&̮뒬�ee-v9�lNB�\��ag#��a��}z��9�$���A���.��S�٣g Q�VCL��g��St��kM\n�w$>K	��i9V����+��M�D�"��ehaX~���n��x�X���V�镵��k�!*�)�r���Y�ENד��Eּ56,��\b��O�6�����>w�q�+��71A��c�>����}�r�j�َڂ���V��RЊ�����8����X=�*O�|�**��9�j(�\ޤc���\�O>[,�"{��~�%���^��ZY�� e�#n�L/Y��)���CIr�e`�ZiE�&�Mxߴe����į2�;�*��y/���hO������t���������PК�c���c����.�������V�y�>
1H;��J�4���y!��r��*9��ko����a�����G��╢6{#��P�A�9��3{��p�� �*�e�*��� .Q�o���-#ڙ O]�fK�竟�dܜG��0�^=}zz�'q���8�����	� '��Ǉ�m����h��� ��,�R��B�	�����K\Ȑ>M�����!*PbYpd�����q�5�k��f��%�����F�RbS?�A�B̪2���I���P[�ie6�i��j�P�Q��q�C�^gQ���v)ds��ز��j�Ya�C�y@>�R@�*ǧ;�H<��{\D� i�����:��;}C�����Ӿ��Ov}8f_� �:��m%����+��{�X�w�n��)���������ѳڶ��HY"٦�N#�D���K����!�9g�}��i��?5�un*���&�A!�����BX΁�Wn�*�?��'�/��֨E��z�����z��Q�����F�b��:���l���9���e���94~�[B:��"�u�-��}�K���o�Ȏ�}nP:��àT+�?��jVz���ћ���;�:%��cMg�c��N�d�~8��dԃ����?�������5c4�-�J��x��
q�jhrڟ�mH�ER����F�i�\�h����s�9:k�6�w�گ�&7�[����6r���&7��-}M6����F��Q�݌r�l�6�͍ig�ˍiscڟ�1��~���Ꮃ3��<�mG ���4F}#�e�ͭF�s���j�gl5ʯ��e�D��b�G6Ƕ}Y��
,.�������Wi�S
�8�j�H�F�z���#��+��@\��/u~8�����ѱ�syS�(��?� .xSZ��7 7�����?�99�v��X���(T"J-�%hE4'��&fU�QȨ�N�^��8I��*F�_����W��+N��Y�e)d�K��0���j���Z"g�KY$�|�:-�t�W,���ʜ��Qf�jf�*q�o��Cjy���ʲe��OܼqS��n��@���O*.R��O��ʦ�$k��q<��ܾ3��q�� ���1�0-�t��_d�*�.�Y?�c���W���^��HF .��[�-Yu�Ü6�k��v�V1Lx:��AY����+�:�96z�9��$ߍk�8g�2�8棕�8^��x����E}���y+w6(�oL���O'��./`/��ۓ��TI�5�Χi- ��B{�=����3,ŧ0���?�~<��<�!K��%�:E&I���#R�Wf������8��.��	�������2�ޘz�#r)-�ԛ���z���Ҧ�_�ƿ��H�� m̶�ִ��D��V�u����5�Zn��(������_>yrh��K�A�&|����O��7����������)�Dk���I�����ɿ9�l��C�<4���,�r��0�G��ɓ��F���h�oȒ!���,/�w��K�E����w-��'�[��G,�������G!���Q27=P���V����_����<��Ǘ���,�ξL9E=q�O�i�bύd:���!�@����˱'�^
!l ���xh����AhI�3?�~����9B(:\M��`�B�z���c"���4���A<B��4�5���d��IJ��A[/$�v��L��E�g��^�������(�_��ߝw�ߜ����á3y�e�2^ޣ���P�܌@M��X���,�@�32��H�>���p�-{x��U����7��s���W��c����f� ��B��b>/.2	����Aa���� ���8���!ո�2�0/b�j��r��IW�R�����1q�v-��Z����e�@.E�)L-�@r�}�J�1+e���R�1m��:����:]^s	R�������ޛ�gr/�ԅ,����d4H�E��+�Z���r���
�:�aFa�5>�P�����"�����a�������P䌙��������(�v��Y,k��NI2��Y�xFפ��n�61�,�خl�5g`�",r$5�	�P�;f-�$,]6*/��`g�%��2���
��e�ML����Tc	�lL$���%a�U�[\����Q�;0=���!���ՐG7��� ��}���x#�9����t��I�b~�a�/���C��V��8஢X�7�;����-<x���UF����f��`��d��}��Y�s�x���K�إ�U�O��U9cܠxs�F�+5����m�d�����h\lh�s���ԢD���yyv|��sfBG͖8�ߠ1�E'�D菗"A.�B8���DF���ٟ1�=��ߥ�iкIM�����h��F��ʨ"���ފ�7W_�U23���	��)��fY�)���� ��o��%z2w����ˏ�я�y�F��F�#aeF��C~��� F|�8�[_mr�>������my��ʁ�ɷ��<՜�nHih'ly%^����w������,J��J�=rX�Z8&Y<��}�l���M��-��h�Y&�"�yF2�6�bV�1��ҍ�od����R4���d��e�a��U#�]�<e#SE0�!)��d��2��%�!dm&� 97q�_n��wun�B��������-8L�5M�;Q.�c�Qs.F�)f�!�
���sh�"�h���/M�N�+���фz\[d�h���Ʊi�0�`sA�[����n	+�e��2C�c�>I$��̾�f�-��/M8�sD��y��M�O.L�$Ù�d�fA[z	Anq�0���1�=��y��P7>��p���v({4�c"(����rk!D��㢊bǭ��G?�\?!a�,���^�0���b����,��!����7��>1	�6�ep*�p�)��I4�0vL�`�/�N�RW�L�2	F>�'�DV�JSiS+zޓh!/��P_��G��nMs�����vW:[6�Q�z0�	Yv4�P�Ig��k��P0I*��t�ڈd6u+�w��1d����9��2���.V�!pl�M���B�<��뢑г���̌�%@��r����Ь]Y����y �ʯ5SN ���I@>%ozi89�Ǟ�-��r`̈́ !KF����z@�#C�q���s�c�����I(�������M,<����U��?,4tjc�[�����O����iZ���9f���t��ch��<&z�2�z| ?���CP�*�K�b)�S�+���� [)���H��y/����9�ϩ�7+�T�(�u��2��� ���~4/��1CF���N�v=��w���j<���l��R��u��&R��VzJ{]�5xy��͂k2)�1�{�r��H�``��N�vղ��y�{�*ަ.�ũ."U�T���D����-����t�%�tp��_���mBdTКf�R�lvh�xtF)�;;;!�3�;X��Y4�0�_��Zz�e뜌�ۦ�c�bȢ�Cl�l�p��"�y:�lufi�"�ʋ�1W�#����׬���=�:��"�ޅ+�l#���kv��B� �ʢ���K��⣾���;��
)���j�N��|�ds:��]�	(�m<ngaF�h%���իڛʪ#1��cO��	W ��}��d�R# ߔ�*�ݤ��w�'�t��&��{	���������I
!q���H�ϔ�ъ��|��MZ:����!��4��H���Y ��Y�X8�{ �&��&�g"q�p�cu}�����i���s��m|ϧ�Fo�Orod��t%��S��&�g̭�}G1x�w6�+�,aTܠ�����;�-��W����w�Bݭ�L�DY��A(%�D+�c�ݛJ���d$:� k��k�KOs������G�`��;�C���o���|p���Tw[��(2�U+/��HU<.��3���Z&'CU��G<9��J�JS�^��}}x<dR&[*Y��2%�L[��99��,!�aG���T.\&��<���𽍲.��W��M늒z"�(���(�d�BO�T�@��XXV�u�v_٬�e�2^DB������=�K��qI�!���h9�&o���FjXfk�����}�&O;'�Nʪ�e��-9�D]�s�ko⳵V��H+�'�
�b4Z
�*4*��2I�&�t��#]��&��%��^���.�":�`�f�9�,��O�#���V�ޝ�ޏ'�xyR�:EÚ��TڥT\����.S9)�O*(�h'�IeJ=�0����d�^��\�����t=�)˗���ݘ_'$v�L���h8U��Ε���~VO+w�CY�C��DŊ��]����Dt�#Q�ND[;���-*����	޴O�[�ϟO�9���*�/�a�
Y�y�E����m�Έ�O$����X�l�����p�`AH|�=;>D?4feS���/���&��B\I}���JϮd�x��Ԓ2�8�OWT�Rq���Ķ�*Z��Dya���x�(.{��ť��5��J��x_Z�jk�zJWvճ[�%��(5���*��:�����T�����I����etYb���r]tFQ��;U��Ϫ �66��*<;�8�W��\D�Fk���Gb,x�V�~oa.n���)��7w�Dv.O���߭J[�~���S3|����e@�tt�*u	��� 01cnUx;�k��Z��#=n�wGtG\�#2Q �=�?"Ub/b���BD�*��~4y����H
���q	R�T�ı e坰���A�c�$�Gy�Ŧ�:��O�I�k��m���n�qP�	��F%e�(	� ?�J �ҲO	y��$d���~;
-O�SL��[a����kE��sq����a���!K�_�T�+c��:��`6V+歹�(��'80��:>/�[9��oJ�������O�S�8|��Ű o՘w&(oz�w�鋷?�/��} w{H��>�s����	��3�I�����m��j2� s/�� ��L'��0�U��;��<3|�Hz]��1~�\i�^CQ:)UpCc!�%$-z��~�5r.��ZA'��b%*-	���h�'��vW�.��s��]�r�v ;�n�(���۬~����y����}������͋M2�9�B�\ˡ��E��PxW��Q���9���1Y�m�EY�,��x��+��C�
�ʠ5ϷfW6�ﲠ؛lG��*,j���lt?�U6���)���ry�aE\��tA��*nW���J1��
Sgס~w8۾���_x���#Q�z��sP��D���2vvM�&��Q�1���znI*BK���+÷��ͦ<�N�����fD�M<���_-|~\i~��-{'5���8ȅ��� �.:�1�u�0��v>I@vtu#����I˵��Dr)q᳠�Њ��f;�_'v���
�#����^vKW�1w׾R��i�n�߰h��ݳ�E��Iن.�M�In�F�?�S�vs*d�ͩTKT�us�%� �]ԜJ�Fzs�.�/AH���dL����m��I�il7�B�.�9�N�	Nox�+䝻�aj�9����;V]�d�#a���A�?𛈨���J&��Hcq��!���=d��7��p�M�b�~�9�1�^�$i��{̞�J&��(��ie]��3����CV8��/�h"�|�#�#��9�˦��%Y �i'с��3�ݑ�jw�ڝX����l�b��/{��s�ȘY ���{1�Cl�=�E���' ��s���0���V��m���p�8��(s�J_�Y��Ht�"*��Z��܁��
�����W���!ҥ�%��`=�v�gQRk��*q��Hb�vb�,⏤)�q���~L�_E��*�k�Jց��Š�w��1CS����c���RNЅЮ/<Č▪�+�|H��T�_�+����3��c��-��c�l��;��"���#�e�}^�G�ق@�exx�f�ۜ�R���F�����L5��9�ڧ9�]�n���m�/ٴ��ݾC���r-z��͔}�����K'��&��J�fF���Qdd\�q��M�<��ţ������� ���qp2�l�h�ف�Q2��Ը`s�4]N�@�	��:�>u9��7ؙh�W�"���)w�\ğ��b;�����o�e�|a4���ɬ�`�c#��J�Ґ ����J���g���U?��L�=�����Rqo$Pq�Ea�-����j�5I\c�t2#�P��Rֲ��)&<5+#��Qy�"�tҝ��<���m������D�'��"��7�'��Ј��+��������Nyd=P��^�6��VK���濦���_��Dt�(�U���s��x���{����R�	��e���pXrFc���ڦE�4By���-����h�D*g�c/�7M0W`c;(���>.�����P4�hSw�?��a#����b��1�/����8�"�_�߯�	�0	Fx�O{<��MǪlt,qϤ%K�6��_�[�xo "�ah��{>U����:�K�m�}[�=1��8Sːv�p���c�z=�	��G�/�Ǥ6=:���o���]��8c�ٵ�N����h�bu���g.8MO�F9Ξ>�ò��3}愻L��S�
Ho�Զ��0Xr�� �'&�K�OƗތF���f���Ɯ�34|$�+4��W AE8Ql�W�2٧��|'m+`�<f@��X��ʁ�N>����?�_��G�j!R���@�z�F0��>t����l��[�p�� ��tCD��~pA
4"�?q����,>;CG"����뙌�E�Ǡ�����_i^7�y����±��L~�#��+m(���Wa�`��a�h;l� ����	��� n�o�E@�
���2��Jpkժ�#��&*+�zI�������Nc�F�9=ìzxL��$������he}��9O��c� �C[!��l):��oc`of!�tq���o%{����Lxj8QE������h����B�UR����g64��j�<��d=�L#L01�7恻��v)�#�y�tG�eσ�S��Yu��!nq���`B�KU8��y��!a\��h;֤��'f.�Bb`RGօ'q��b�<�	�5�A��������s��W�i*l�g�g〴S2�`�4@��
wwLގ�<�a̅�y�f_���B�*!<�ص�:�8^��Fq^��rN��{%�j��4�Q�(J��)��$�F?�]�Y�iNo�f�Mt��cYCg}n�1�w�ހ�;��Ʃ=n�p�,����hPь&��A�:恸A�D�ߓ�������J��O9c�����k.�I���a22Զ�k?ŝ�)Y��$����Z7�ś�%��1k`�ؑ�7Pd�nq�of�w (�I�4a��@D���Qa��x�0�3%�K�E0��^YN�VI���湮�4�;Z�v�^�ʚ�H���-䗩���i,<��ohKHE0�C�
�EZSR"限��E�nrf�;���D��+����̺Y~���!jt���ȼ��6��;�^ʓ���4�!�OU�����E[��x�"���M��tP�w�TP%��"�� ��榀����h}��[e�\oVgB����)o:�	��k4�lXR���ո�n����M�8��gu�5���.J���Z�bV�47�C��WSv��Qv�����.��^P�% �Ȣ�]�[�yT.اr`\�&��bt��j�����Ve�o���I�;��)������W|��KR�a��F���+�k��ѯ
�A����*�����d�f�e�|-^�tZ�cb�
C�W)�������G��%��_M`0eK~SF��菆�� y߃1����$.���e�-���@���Q_"�W���\�qe�N�.���  [�Ã��&X���t��؁bNH�ͤ�S�	�0��ٶ_�]Q�et��<����J���BR��f5��*�?�1�hY��]AP�d=��ݠI��� �t �O�!1,���1���rY�Ա��mv�I�ho�:niYf�1;-�l����e���<%�!2�ˉ� �v�e"ua^vy��U[%��ݡ��~���j�2��bk���B�~�	wd|�I�w3@Wڋz	8��p��3�s��v���b���� �^�B{L�~hG�H$A�����K�k�B��#\������x^��ʊQ%���{6�^!O#�*gLSv�����ˤ@���M�Lɼ���/�u�}1΢\�N�9o�Y%�3�YY�8���Ǻ�Nh�;�B��u��x*��Pم��W�����ѕAVP1�W�E7��`B/Di�ć�d-Z=�(�'��l��#��}"�e`�r�-4�C�C�M�&M}_�*��2�a�@�o3���Z@L����,� ނ˰���vX`Ȕyere�V|Q��!�\q�\R����4Bn$��B�1���]���V�f���.2�M����p�ʕ��)҈��JD=�h���3�+��V���r�� ��3ٳk�A�>C��5�9���[�H�_�5,����	�}�GɊor���5��t��L	*=���F�X����y@Ѫ,��cW��qvXS��B��V�4^�&�y��aZ��&��a�1��
a�5b�z��1D�2cT�֐�a�Es0=��^lT������Y�m>e��9@N%�0 ��ڛ�E���B^�Ɂǻ���݀�w5��|i�J�_h��ĬAQ�de$peε�^V��)��͝�C�kI`��=�MBZ�Y��ƛi��R�ڳ�8��垗,X���>�n��tk��j�xOˇ��PZRC!m�0�A��T�RF�Y�V��̬�����=V�E�k��nO~�@�3��$}#+
Q�L^����kn�'+j�&�&�{�ZY�[ʃ���c�a*G�8tiL���u�_�Q��#���[eqg�BU����$�gM2j�.�z�����Զ6�`�v���EoW����K�M�jZ^/���&��2{�q��+�W�.�Y�YwR�[1��iZ�</�7�x�&lϤB�<���UѴ��7g#9=�;��!vSQ-��.nY�L�Ethc�Mܐ�3T��xL�9AS@��Ģ�L���9�p�{I������������F���)�ՑU�&6��OKg1��2�؉�}�Cq(�(8Pt+��T�.���L�\��:���N���"�;�ג�Pl1q��6���nOi�1{�HA���r�/g*�q7�0���A��+��4|i��E���w�(� 7��n˨MM��6�cnSP���e��N�r�ͪs@W��U2�{��(�!��AcZWt!�zrqyB�
e1 �kT2yʼƉ`������}[�����P�Z�12��3��uk\�'��~gLU�PE|O1"��uz�����dؔ�1���(Ge�M�̙W�3Ȥ�Y[-�C!�+(<JUz�g�6<b�z~7�?��,�.��0Õ6i*(��I �x炑��?�*
����1������(?e�+e���~h��d���m�5>��8prI?�k�Z��(��߳Gh}<�FCm'�>zޥM�����r�������$��:D�v�1�b� ��X@c�{���kh|��<Uc��H8�f�ˉ�.,/P�*{�3��rYX���.o?#�?o_i�e��;�5o�P2��X�6\"@��&n>�DҀ,���o0>�Y#���w�ə�E���!�q�('���_)V0E\#�7�A�gE=�H�����#1�3�~v)XyNy��ڑywj�b�:�Hmv��Ir�y��s䦅��;uX�����.ӵ���lT�0\vq�ro*��H'E2� �&��ߩ��Mi[���)�F����7���
�O�x��i�b�4)3=(P��*�^(ÜB���L�W�MB	0F�����]�L��f �!�3���%|����A��&"�i
~2eD��<5sa�i,�U�y	!^:�T��&��{���fs�(:3��q�3x|~�L7�`���yF��X��Ð�	5}_(����z6l�-��f)�q`U5;�7d��j]����t�(Y����ՊU�"XD�?�z��1�n��J�؍Ӌ�\����(	��xA����s;!J*��7�r��j�/��(<�#���Ґވc���Z�����k�w�[Ûh���"�Z�_��8ةT���qU(?���$,�ZAec�PxJ�v��'{C� x��?t"��
+��ՃIo䰀���-�W����ċ�,P�M�{e��K�U`��cآlQx���jY+�?{`)����k&t|-��W!FH�E� �����A�=P��������n�@��l~w�4�,sg��EP���4��WE��Q�a��j���x��	]�6c��y� ,���bL=�I^�1%~l�E��LN�$��q�dx{�:_z&��C�?�rpa<Ds�?,�d��Z����Gy�j[F�ж��f�a�k����-m�_k��ZϬ7�~�N~_�d�T�VK�մFժ��in7�5�����=��݃#H�B�T;�50��f��h��Vu��Z��o�Z�l�Z��7k˨Y�jC��%4�f�Wo�e�u���U��Vլ��Vm[�{��n�K�-�c�U����j��HSߪj[�m�e��jo{��eW-�Uo�X3ۃa�U5���U��{ͪf���[�iԛ͖mVk�v�ٳ[* V�l�[[�z��3�lzk�-{�U�6�~O��,ck�i4��K��[�V�ު�������u}�jaG�kV߮���i}�.�@/��F�j��~��eo��M���[��m5��l��뵾��r���E��鍭V�⪵����Zð�^���lUk��ւ��"�y���v�gժ�����Y斥ـζY�kƖ�ڂ�hX	X�.��є+�:�Z�o�Z�gVM�����ޖ��[�VO�j�\�l�ҠdOH�կW���z�al�I�ܮjͪ��j[����V#�s2�4�m���0i@�0\�u��00	���nl�ZݪZP$ߏ�P\��ܑ�R�nK�) Izlhu�Y�6�f���׶L���ݷ��hz߮���V-{��.0U�^��U��m��]�MXٍj���jVCkUu�nn�f���\w�@y���lT[F��������h�m���R�~G��m�F�h 6k[5�Y�麶m��5�nZ�ܮ�k,�YT�5{�M���4[k6�~�n��^��0UӰ���Q'������55M�o�[vMo���k���4`�5�����ͫ^`��m����t�ڬ۵f�D���[ 
4����3j}QSE~����?����?����j��l�y���x���e�1G��ך:����$��Uo���c<+����ꎴ��4;N���}k��.l���z��@D�����ޘ�+K�\'��b��u��=�XuA�A`���&�vC^þ���`�I�WN���c�ɥ#��e�������$��|�{7��h�D�-dݳ�tu�we���C�� �2P�c9aT{��Lo����
��+rj_:�󦊈X1%9/����=)v�yB�(9�P�4=�al͝� �/�ipRD�S��@����)�~���c�ށ��vYk����$� s d��.B�.�����p�+�� ���j��>��ߌ���$>tL�YĊ ��$XE�B��'х�g�މh��4�x]a��O<Xz�&���ӸϦ�e�晰��]h����N�;�eT02x�Rh�=�����7ݳ���l����-u��#�$>&�`: �w�����[���T쁓!I(̔5��g������R�XT-q"J��
"hj�	5�:>��!��a�&O�ʍ����AK�Y�L�nPD)��Z��s'�4'$�K�[J�к�/Ң�S�S�bכhS��� 64�~*z��B3a�6,F�Y���<�(�Y>�5^p�*��o	lz�\^:7�6s�?���3M����ژw�WmF���@�]���Gz�����'��ɓC�$�]���'���o���ߋ�l����X����(�/���$�2����C�:�^S��t��������v���w��g�d>	��1{��Z��J��Z�����1��:�?��g����y+ Ԑ*�xX)��Z�Q��in� Oy���tDHk�)����|���-J��3���J��@��f5(�c�o)�W��q��p�\����������1z���ɺ��ڻ��]켻�����`�ɚ(iZ�\��/Fv���@oW���*�i��e&��
��qrH��9.{�YV*0�}��^/F9������@&�SÉ� ^��h��b�B;;�\���ѫE����ź,i��O��T7\K�r{K :�@}� ��t) ʋk�vl��������N��0�S�XF��;��wi%-c���]�K�EÞ�= 乢�~�v�2�S�m5+8u���ޖW`*	���$c�1��b����s�B��c�}�-w�>���&#R2I��T��ן�]P�$�r���g�[�Ae��j�t�V+���*�}�]��ug�R|Fh �2)����OޭcBl���֊��)Ѭ��珆?���"���W/�iD?�����ߓR�*����cH�|��J������������]b�t�!h��O�tF��?��k|����V2O4�R���Rl�����I�_�L@	�M3
%�T�bjy��p6Pd3qi�V(*Y��mQ.�|4]
�˥���Kaw�T�����S�U1+ $"/�RI��������I��*�BZ{8���/k�Mw7v#?��1~��.�����H�b��V*ѽ�;H��_� �f�~�� ��>J�Y]7fwG`$�M��EC:��hvx��稅�~���F ^Bq�z!^˻k� 32��B��7��]czQ�ݵ�Lqp�>��$X���4C[T(�T/�=&�h3��1�
�Џ^�U>����{J}�Я�%Um-�8��N����	����Ta~iqu�vթ�T��v $*������I >�)�b_h���'�/��8��Z�5I?I����g07D�{F~���3��{���]:�$֡����G��ˆ���1-����Z�ެMo4j�\��(�W��w�����o/W�����|�ͼ��Ɯ�_m�R뿖��=Γ�����_q��E^�^�3n�Wr���:��(�ܯR/9�)!+,������)��ZR0���?��z�=f��_�֨�Mk�wjz�U���GyV(���0+X��l�q�<ܻ��*��F�?��/k��n���߶�^O�m𷧒.P��������m�p���_{�N���v����m�)�I_w�����ެ5w���lm�W����v�\n���FC���t��k����(O���E����?W��P���{ �D`������%��_���:�9~��_��O{0}�C��-��b���:��n�r���x���Ƃ�_o��j���׀���'��Aڸ�������G���0m,��kZ��i4�c�����1�T�h���C����ϔ(TKmc��G�����7��*��^�����xV��x�y̓7D�]���h�"�����f������K���M��Mj/_�!PyL�
m|c
'��vW��U���z���Gx�@�½�h����g�/�S>��K��?��/E\n���ah���c<�؏�Ƣ��ZZ���z.�?�3/��2ژ#��juz���?�ZZ5���gY:���ܾ��� �'4�4w�H�E���\�:.�v�wqJ��=ly��^-k���[��ե��o%E���̐���̋2�Z��������ߑ�'��d�c{�Y4��%�m2p0=��`7l��]�������sy䨠2�8R����q9�ݒ0e	��H�w�ib�%�<�� �مZe^�<���5���}�Y�$E����+n �(a�T x8@ �K[$��|�7D�b�@]�7\OBeN��܃@[p�.n��A0�gU�v��ո��vӺ���vN�����1��⣺E�e�����t0�^�B�̲9�C�~�_KƳD�(/}�8N@\<6K"����&KcRAV#Y�g\�M<>��q���Q��)�qĠt�]��AW�����f����i�v�q�,��#�)V-�Y��Rd�T�eVE�#iq��3�V<j��q�|��t���د��A~�m̑�`L��Z���8O����N?[[�� ��qfc4�l��6`���=.���=��E"�oxUN`�qXg�y���阰�'�_b�4��2r��}����6���	>jڇ�M����>Yil���<�O=��c�|��'����Q/O`?z=�ߙ��
ˆwe��פ?�l�,���Ǆ��=<��!���8p�m���a�����S�^�I)$������P��e�<N*�h,GW�����>�p`���i�j����Yݬm�7��;������a�����*7�x���V�H>]t������/��gNfͥ�1O�kF��(�a���ެ���c<K[��{��/(�a�(ǔ$��tfY('Ik�,�mS׈���&Kd��*�X�Cz	�e$�L���͜,��_ހL#)^�2����M #��\�#3ۥi�hO��7QO��A������`�&,�2��l�FP��ywi,=V��ӛ��2i[?��$�"�|vp��S��Y��횜g�8a�&���`�Yؐ��`by��� 6����^�w��[I4�a�K᳚dO�Jv��
h9�ef�.ފū�k����2T22܉1�	�q. ����1,����i�^��R�Om�-~��������%��YNj��E>�\`�#)�q�x�"x_سcE���@�l(�`�a�����(�<���|I
o9_~_8�ۻ��.��.�Y_�꣟~�j���ջ��p��9��{�a#f�B���h���n_�B���w�W�h�ʀy�;��Qx�Xw�l
���[Ӵ��Z�oO��$��z�ߙ�x0<��F$M�c���{:x>�M��SB�����v6��1G�����l�s��Q�<�C��5���D����_���y��<��r�i��u�G��9C-��x�m̑��ݟ��7�U��Ѫ5s��1������G���S;������<5�^�����;G��������7��g>s���=�~�}~�g�ܺoN�\|�o��z���C<Y��e�����[����W�M�U��?���8O�=����]����x��5�������3��r��NH:;���}�d��ͧ:3�譒�.��uv�άL��Rwfe�\(	��T��t.=�̼�yB�2$�Hh�JT������3O2�H2����?	��o����-��y�_x�k4�_���<�㸗p>��vs������Pr;0C0~Q�ϟ�>��_��:/�C:�g�V����O������?su�m��������L���	t�����lb��V#�����������d�'���6�F�����?���y���W ���?K_���+���������B����k�Z-��QE��V�V����x��r��,�/�!@��B�D���c3�Goa�#�6H6�%k)A@h�q@�~�P Sa/�'�b��Ⱥ��	"I���'����y�ϸ[��]+?Z��VY;���JQ���ΠT�0��J]�d�D�׉�ɡ>����Ɋ�6�߻EU�f$-�,/2��$���c�#i���Rژ��ј�'��mi�\�{�'��M��T�(��g����J)�Z$�S��%�	�kE����Z"�,B�܅�H�������!�˂���R�� ����!�_`GaMw�n��flJ����-�×���o��ۃ�z*d�� i֔?��?��?��?��?��?��?��?��?��?��?��?��?��?��?��?��?��?��?3���N�� 0 