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
� �e�Z �]s�H� �ݻ�O��0111�M�Z�[$~Jr�ݴE�ԭ����v� H�Ll ����11����o��a����/���� 2�C%���*�$�y�d�ɓ'O����V�<�iZ�� ��&�W��ٿ�!z�Z�i�FC�M����xh����*�g�,�����~D��L�̿7�Ρ{�$(�����64�s:�@ U]��Rh<!���z~���
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
�8�j�H�F�z���#��+��@\��/u~8�����ѱ�syS�(��?� .xSZ��7 7�����?�99�v��X���(T"J-�%hE4'��&fU�QȨ�N�^��8I��*F�_����W��+N��Y�e)d�K��0���j���Z"g�KY$�|�:-�t�W,���ʜ��Qf�jf�*q�o��Cjy���ʲe��OܼqS��n��@���O*.R��O��ʦ�$k��q<��ܾ3��q�� ���1�0-�t��_d�*�.�Y?�c���W���^��HF .��[�-Yu�Ü6�k��v�V1Lx:��AY����+�:�96z�9��$ߍk�8g�2�8棕�8^��x����E}���y+w6(�oL���O'��./`/��ۓ��TI�5�Χi- ��B{�=����3,ŧ0���?�~<��<�!K��%�:E&I���#R�Wf������8��.��	�������2�ޘz�#r)-�ԛ���z���Ҧ�_�ƿ��H�� m̶�ִ��D��V�[�F�hz�Y���ߏ��ݿ�WO��'��I���k�wO��T���?��_�O��l����O�����D������O��[����x<��C#� ��+']�Ŀ�<��Xnd�>�6�,�)������DY�a��}ײ?>y����������g�WB�:%s��1{�7k͖�\��Z��Q������D��?g�������'`��R��F2�l��^ Z�Ă��X�A/�6O�C<4NK�� ���l?�C�����&d�S0W�����1|o����� �um�Κ��_2��$�]F�����k;J�]&K�"�3|wL/x�{���}QT��/���λ�oN_v�j��Й<�2]/���F|�	�pnF�&Zk�[�OKS�� �_Y�t�[�o8	�=�@�*�W��x��ùz�xV�+L	�׉1t��o3~�H�K��l1��U{`Ѡ��y�~s���Xz{ɇ�j܊J~��
�s�ZJ�
��+k�h��|���J���LM-x~p��} �����y 9��>H��Ƙ��Csj)Ԙ�6SK�uO�g�./���GY\���x���3�c�BJP�m2$�"�ѕ^-W�z�V�R_�0�0��v��x��n���sz̰̓XHD�ve��(r�L�L�YL�͍L�R;�sZ�,�����m�$�I�,T<�kRMk7K��V�vlW�՚30E��	��n(���S�.���Q�3�DL�_Q�?�Բ�&���sh����6&�KԒ��*�-�^Ic��������q��j�#��nl�A���Q������dp� :��$h1?�0�rd��m�b�
�DpWQ�΅��	�
�L��<�rU�*�e��w��g�iu2�ھ@�׬���Z�J�[j���S�R�*�'�1nP��o�
ϕ�c���h2�|��~4.6��9��djQ"�W�<;>��93��fK��oИ򂢓{"��K� �m!���y"#�����������R�4hݤ��n�j��	E��YeT��p{xo�?қ���*��N�{��}ܔ�n����e��n� �ϷÉ�=��;ZPx��G����̼�#~g����2���!?m�M#�A^�-��69i�}��z}�B��<L�z������	E�jNZ7�4����n��;G�@��ύd�ŌK��9,B-�,���>R6���zc�Bh4�,�ӈ�?#�H�H1��|A�F�72a�yk	)�ld�v�[�2D��0g�*���.o����"�ܐ��qC2D|Y�ɐ?�6�l���8�/�f�:�m�GH�F@������&�(��19��3�B�R�U�94z�J���Ɨ&rN'��T�hB=�-2c�Ey@�{�شwx������������� �2PK�!�A�$UxOfߎY3͖qD�ؗ����9"��<�ܦX�'�R���K�u��-�� �8O�������Uj��e`8�\A;�=��1S��i9�����qQE��V�̣�T���0R����p�U�Uс��T��b���c{ߛgr��r_|�2��K8���$g;&s0�h'E)��I&\�#�U"+z�)���=�I���B�S�/��#Aw���i�v{Z�+�-��(}=�ӄ,;A��$�3� I�5��V(�$�gq[:�mD2����@�2oVN��l�W�sJ���86���B�J�D�u�H�Y��@fF�P ��x�����,�fm�2D��8U~�!��xh`4N�)y�K��Y<��lz���&9X2b8G0-go��r�-�ퟞ���%�OBD)
9�p��M,=�+���U���?,6tjg�[�����O�ׅ�kZ��+:f���t��ch��<&z�3�z| ?���CP+�[�b)�c�+��� {)��n�H�ҁ/����9�ϩ�7+�t�(�v��2��� ���~4/o�1GF���N�x=��w���j<���l��R��u��&R��ZzJ{]�5xy��͂k2)�1�{�r��H�`d��N�vղ��y�{�*ަ>�ũ2"U�Tr���D����-����t�%��p��_���mBdTМf�R��vh�xvF)�;;;!�3�;X��Y4�_��Zz�e뜌�ۦ�c�[bȲ�Cl�l�p�#�y:�lufi�"�ʋ�1W�#����׬��>�z��"�ޅ+�l#���kv��B$!�ڢ���K��㣾���;��
)���j�N�\}�ds:��ݦ	(�m<ngaF��%��ջڛʪ#1��gO��W ��}��d�R# ߔ�*�ݤ��w�G�t��*��{	����������I
!q���H�ϔ�ь�Ȝ��MZ:����!��4��H���	Y ��Y�X8�{ �&��&�g"q�p�cu}�����j���s��m�ϧ�Fw�Orod��t%��S��&�g̯�}G1x�w6�+�,aTܠ�����;�-��W����w�Fݭ�L�DY��A(%�D+#�c�]�J���d$:� k��k�KOs������G�`��;�C���o����p���T[��(��U+/��H����d�$UYm�\��,	f�@��mT�� ��k�^�*��{�<���ݲ7�ٓ��/� e7���b}�>�g��%"���B��eA��N?�!̌o�0L�U%sF�����J<ʉoLJ.Y�PUkP�&�s]*rT6+Y����A�
JfP��&ۥ���i/C��h9�&o�����Xfk����}�&O;'�N��e����3��g���gK��?[�7��̠�U�����=����SJrG�ĥ�J��H�O�</	e���vvFNѱ�6k�)e)|��ֶ��|�~���$��StĉZI�cJI�(+�3իR���u�~U��Ա��3���7N���~��Y����L�'Z�|�0����Hb/�4<J3���*~�q��$�n��zZ=-ʘR�$*V�w����z'���w"��YU��(�m�<͈Ѱ�dO�X`
��ޒ0~�|�i�M	�U��0C	���"�YF�S�dJ�'�tw�V,�[�s����Pc� b���+��)�
Rߗ�WR	!���OT���gW���qj�Q�'�+JY���~	ub�x��}��0)NvC�O����������&YC�/�A��t=�+���/ْ�b���tU�WQ��h*Q�|��NUY�2��,1�Yw�6=�(�I�*��gU v��g��Y�+�e."һ����w�#1<�,� `a�n���)3t�w��Dv.���M�߭J[����S����&�m@�*.$ c��Č�U��D�MӃ)�����*�-kp����D���(��lZ���mR�D�;� ����H\�G� Y(��~T��VHMTSǂ��z�!�mI��ļ�!D^�j0J>�M/rW�}Fo�@��r�'@��٢P$���H+��J�>%��{��5���(:>-O�HnH���n쮯��ō�SjJJ�38F]��uSa�� �������X���V�2�|����������a��)��I,fh�W?�N%��)F�o��dZ�T�\>�G�v���������!�����}�fWЋ�X2�gB�~
o��>p�
���p̽�cg���3|�>�x W�. �b���#�uU�9� r��zE�T�E������J�xh����?R�k���!���$�^z��� 3�]U��B�5�wE˝���Ţ�^b�o����C�}�����	[�###4/6��6\�Fr-�*L
M�C� ʳ_I0�-Cf2� Zdݷi"h�����A�B�H�K>!+t+��<�b�]����zo�Ad㪰�Î;P����DVِ�b����!q�
��1ϱ�]�Ot>*�t�+L�	\���l��:�K4|�E<|�D%b��A}pzȌ��mJ4)��2ǘ<���%�-�����s6��8q�B:���}L7�Ѓ�|���q���&���lz�� ��������7H0Ęd�7����$��Ս�o�.$���+ə��uтN�@+���H����W�@� f܉S8
.]��<n\�J���%�9~�Ɵw�N1�SpFq
��C�'��ɂNO�
Ω�m8�R-QI��ͩ��c�7Ys*5f�Ω�ts�E a*V�1M$⇈z��s'	`�������j8e�8��)ޜw�J��B�����X��O6X�E���r!��o"�Z3�2�7��f�"'��.���j2�m�S�H��6�q�u洋��{���]P�P2{N+��������u���BY�����`��=�p����C�.��R�d1�L��DRW?�,xG2�Q̂wb�#~N�Q���w��jϹ�"cf�ۗ�Ŵ�!!�j0x" �
?�v�C���%��2LK�Ҷ��#4H��kO��*}gT�"��5

��rk�'�h^�*�z��_	Kd�_�H�F�x��|�i�Ey��&��}�#9��������H�5"gM�Y40-{4g�d��*UX�V�ީ"�=MU1�t �r�.�v}�!f�T_��t�����B~���}���tCOnY��;�f{��idq�%w�/;��Vb���Y��;Fa+�����67�Uxwg�!n�qw�>��a���"���NnKGxyȦ�w����"E���fn���46_|��^:��1�W�43��\�"#��vl��!�,�^D�&fO`H�ߏ�јj�G�g]Ȏ]�r���x��6�3��rR��`Fթ�Y���L���DK���@�O���"�T�ة����|+/���1E蘍Lf��Ap�W2�������TUr���<c����r�1�fJ?�D�����#���/
co9��x�7T�I�����u7�u�enL1ᩉ%)��`D�+�)����?�gV�k�3/��Kb���Ֆ�"��7���xh�����������a�<��L�U�O��Z����_��<��c<+��Y!ʫE���w�n��^����T� �g���$�}�јfn��]�5>�P�P�����0W�H��q��ܦ	��
Lcle�bާ��{@��A*��Ү��G�=l�x_1�6�� ���3�'�PD��+���7�sF�#���i��Pڢ�X�]�%�ᙔ�d��@��z�b��D�^��|�ǘj��УA1]���;�o+ø'�QgjV��n��7i���0
{��Bʼ�pLj��k�Ɛ�p�Q���][�D�Px*��)VX<qf����i����S>,�,�0SN��"�<E���&�I���
�u!��Bb��!�t��a`|��h���dF+�i�9C�G2�B{x��a T��Ŷ|�.�}Z��w��v���c֧L��٬8��#������X!�{4�"4�wj��C�N,�捾u�����J7�A.���Tʦ���K�ǽf��:�,���E�d���(B=u��}�J�q��x��S�?~�0�e�.��_iC1tf�	�k}�E�a����?�M@��� p;���(?�V`�'���W�X�V%�)]0QYI�Kz�\��T�v[4P��f��3��'U׿�D+��i�x�f��0fgK�1gU~{3�������w�|+c?Of�#PÉj(j��m�F3|D�_z(�"�??��9X�Tq�}&�!f�a����1��tp�KiQσ�;�,{�Ę��d��$�Lq��L����X��M�{$��:���$@۱zN_<1s���:�.�p�,�yMX�	*��M$��D<�|��NcPY`�=�>c�����>�p�W��c�v�>�c.��6��N-�jV	�����A���6��Z�X�sZd�AV����:D�P��Ni4v��h6�q�*��Nsz�7�l�����8�s�~���;=�t��!�p4N�qCo��d��/o��G��f4a(}r�1�b%z��$|�E�e�W�=}�]\l�]siNd(������]�)��Oɺ�X$i�ϥ7ֺ�o(�t,N����Ď���"ktm�+|3S�A�L��	�� "Z��
{����0���)a\�.����8�ʢ�p��JZ��7�um�Q����G��VքD���o!�L���&Hc�f�xC[B*�zW�-R9҈�Iτ��lIv�c0��!��v �<D/�g��r�M7��P:�4D�Ս��tݹ�Rn���8��<�~�bM���/��Jmƃ� ��n���,���R]����(�L�8/p�+4�4M_�G�^�*k�z�:R��7My�y�L�|_���`Ò��ͬ��\#���n�ġ�h>�۬q6��Yhugך��j��������-���+.� ��w������n��FE͚�:��C��p�>��r6I��XV[|���$��x;`�^L: ܓ;L��|@n�п�;)\���U��0*��0e^�G<+���NI��*�E((W	�ͣ%s4K/���\��bT:�JVe�e��?b,�;�(�j�)[�2���@4�������g�do�?,�ly|=t(���1��4�:+�v�w�`�`�� �*��/0�b�f���e�sBKl&%��LH��ü̶���슊,�3�i3�V2�M��6�9\T�����	D���6�
�
%�	T�Mvo�x�~b�aQ�<���w��J��een��N2D{�qK�2�h��i�e�*��,��)��ѐ]NXx�[,���+ܴ��(A��u�����c��[kh�-Z��L�#�M���¸X���\�St�iH��=4��<3�^y��Zw�cb�C;:E"	����^J]R����L��e���R�RV�*1l�ܳ1n	y�W9c���<��]&�`6fn��`J�%%e^x���q��(��yc�*�W����
��TF8�m߼pB��)
/�#��Sq���.����L��~ ���i��b,�Q�z!J� >L�%k��p�!(F<�l�6�l�n���P-��k�m��:2oR7i���RUQ֖1*���x���4�b��k�d~�x.��>��a�!S��q�-Zq�r��rxĥsIU���/����
���wY��^Z9�=:
���6�w�[�8+W6 f�H#F\�+��WT�9�w�LS��K�[ajzʅ�g
�$��d�f��G�3����,�o"��װ�
_�{B4' �1+���;n���	xdW8R0%l��8�Ba�c�CS�QD��L;ď]����aUL�b�z[��8��L����8�כ�J�}�@]�*�ť��N��#�UDʌQe[Cr��!��X�8�[x�uP�.�_gY��P���� 9-��B�yC�7A���ŋ*��w�맻�W#%$�jP��F�ܿ�:�Y�02����H�ʜk���>��S(.��;9�,֒:���{L���ڳΥ�7�t���g�qȕ��Y���~}��d�������#6�폡���Bڔa⃘9Z���,��f��Y��#@	{��� �`g�4�����g�)�I�FV�v����ܜOV�,M$M�����L���ɡ�2&�T�hq�ҘjA�����,7Gz5�?:�������=��In�d�4`\���5g?�mmj���.s�#3�ޮ+M˗țdմ�^��~M^�e�:�W�]b�����b�_�Ӵ|y^&o"�M4؞I�.y �z���i#�o�Fr&z(�	v*$	*V)B즢Z��]ܲT������ț�!�g�܍��s�����E��"1�sb�4���'!�S�,=�S��#�|Ml�����b��oe������P�Qp��V���:]n�)�:�D�u�(�� w�E�wz�%]��b�1��_Qm�SݞҐ]����$}�_�T,>�(n�a��)��LCW��i��F�%34��-��Q�AnT-��(�Q���d�m
��ܦ�����ߝ夛U瀮
��d���_Q�GC���ƴ�*�=�Bd�����
�.b �֨d�y������/���h�A�GסB�\c(d^g�;�ָ^O��#�Θ�0����bD@���hGyGɰ)Kc6eGQ���V�0�3�Lg�I��Zn+�BW6Px����\mx�J��nL>1X|]�2a�j�TP@O�@D��#�	~	T<�Q��c���44mSQ~�BWJ�$
q��t[�d��8k|8�q��(~�-�2=�|P"I�g���x����.2N<}��K����������٥�I`C�[����c(��# 4	�
���	c��� �y���g���F����V^��	TvcUg�;���H)_W�~F<|޾�K�w�k�(j�d��,@�Nm>�D,�,pIM�|����Y@#]�,`|�F���3ŋ�u���JQN�	���R�`��F�o��Lϊz
��}S��GbBg`��>R�����\�#�����u��� Ǔ*��B���M�/�w�f��]�k��O٨(a������Tr�N�dr@�M`��S=���$�$AS�)4��!���oT�g!8����sӌ�0iNfzP�@3U�� Pc+�9��m1�ܯЛ�`�:0M��h�%�?�@�C|?f�M�1�K��;��˃r<MD���dʈ �	�x^��Bs@$7�8mB�t���7�;��n����VQhcz%%��g4���*��C�����tDI��N�!)Tj��P+:$�l��[��R����jv~o�T%պ(ŧ��bQ�|#;���E���f�<cX+�b�V��]�F#GQ�o��N=�4��vB�T�Ho2��'�P_ �Qx�DxK���	�*���(EW	����路�7-� A[E��X��q�S� ��-�<�P~bi$�IX�����N���SO�:�"���D��Vt����aѦ��[ԯ@�:p���X�t��k��"�z��D�ǰE٢�&ղV&�&�R��ף��L��ZL1�B��|��vWWWe�,{��*�/;G�N	�>�����h�Y���ˋ*�>��?hZ]�F��U�?Tk�<��c<�H�:�C�DϣY`�lc��O�z�)�c�/z���AZ� 	��['���}�����3�e�������!ژ��a�'���Z�z���٪mUC�ڶ����]�5�^�W���~�aWk=�޴��:�}���?P�[-�V�U��2즹ݬ�4k{K����v� ��R�����W��Z�Y�[�mCkYz�ikM��j��4�-�f5��v��lU{f�ҁz�[���[���mԭ�	�h���)���ͪ��om�z6�oU��ڶ�2�Z����ز��ު�L��i`n�m��4Zֶe�z��߶��}�_3��V��o4�v���T ��ٰ����F�gl�:���[�V�Vm����Y��v�h&�<#����f�߇��}��o[-��v���UӴ4��%�E��hZ;�o5���>���̭~ն�v_k�Z��Z_�l�Z��n���V�Aq�Z���V�aXz�Wۆ�����0�U1ϟ��ޮ��Zu[�2�=�ܲ4��6�z���Z[�++�%�63�r�P�V��MS��̪iՀ�l]�mZ��l����m��7[�4(��nZ�V�^mn��5臱's��5��֫mٚn�Z���ɴҰ�-[�äm5-.��k�]on7�u�nU�(���m(.{p�H{)`����$=6��Ѭm}�Q��k[��Y�in�m�*�޷kf��U��LU�W�jU�u��m�u��Y�j���jVCkUu�nn�f���\w�@y������j���{@��w]�Uc;���Z* �﨡ٽ-ۨ��fm�f7k5]׶M����Ck���zb�%<�@��7��6�l��4���ٷ{=k�TM���F��J�S���4��Uo�5�Q�:L"�1��AFw��y����e����뭆f��v�vo�4�:z�J���)j��ȯT{���C��`�Ǻ� >^�����������^k�|�[r0��V=���(��o�p���#-�$͎�+du��!�K��l��$/�/9�0s�7���ߒ.�I����n@��a0V]�Fؤ��I��ݐװ�=2l���d�zr�H�t�=;)�|��=	/<����>�%QmY��`]��]�i`��1@���XN�^=0��%ӛ��f3���A9� ����ڗ"�VL�lK�6�ǅ|O��@�-JN"�3MOv[sg;@�x������.w����;���w૾]�Z媦7	!��g��УKG�$�`$܁�
�,�+깅g�ϡ�7c{s8��a�" (5	V��x�It��ٱw"��4�+^WX<��4���h�I=�)��4.³)Bp��y&�Ap��(��@���NDj��vO{pp��M���p��g��Ge(BK�xA��0�ŀ�	-�H���-$��V,�6{�dH
3e.��;�Y %�"`��6��T{!UK�����GBM����/m�%uX�ɓ�r��0y�iV$�[ TQ�''��b��	4M������<���Ƌ�h:�����&�T��0��D��%�C��L���QnV(�=�e�f��{���\��
c�+�[�^<���M��\�����LSG'�tz�6���U���_C�?�\�����Ϳz�/�<94Lr�%� ��{���
���������)��5���׉"�"~�oAr(cx�<���10��I�����o����w�~�O�P9?H�׿/[��_k���q��:�?��g����y+ Ԑ*�xX)��Z�Q��in� Oy���tDHk�)����|���-J��3���J��@��f5(�c�l)�W��q��p�\����������1z�������ڻ��]켻�����Z�ɚ(iZ�D��/Fv���@oW���*Yi��efp�
��qfE�9.{�YV*0�}��^/F9������@&��� ^��h��b�:;{�\���ѫE����ź,i��O��T7\K�cK :�@}� ��t) ʋk�vl��������N��0�S�XF��;��wi%-c���]�K�EÞ�= 䉖�~�v�҈S�m5�6u���ؖW`*	���$c�1��b����s�B��c�}�-w�L��K��'\�dDJ&IZ��j�E�� �J���C��T��{M1��W�����j��[��/�k���U��LV&��!�ɻu�.�PC��Z��� %��\����0�Z�ݘ#���e?��g����{R�We4�{{����^ix���A��y���?��K̟.�{"$M8�����?����]Iʫ��G�l<�	N+�M-��3.z!JJ�6���� �6�P��H�/���
gE6��qh������R�gӥ0��\
�n��H�J�KH�z=uX��@"�+��{����Kʾdo�R)�ᵇC�����H�twc7�C�8�����ʈ�Y�� Nc�ݛ���*��
PlV�yP�o�ԙ�u�qcvwF��Da4��f`��Lq�Z��1��n�%��հ��60cC�)�ozC��5&��];�����K��Al�L3�E��K���c�6��C��0��U�^e�yq���W
��\R��␎�1��$�ih �>ZP���^H�W�oW�z�IՁn@��Jp;�K�����O��Vm|2���������Z�$��Rz놹!���3���̧mΗ���v�2D�F@��������2uL��kz�V�7�D��Z+��=����]�����˕{�32�l3��1g�W[����O���'��Y���\����g�$��P9�u��Q��_,�^�r�SBVX�7za�q�S4⇵�`0ha)���p{�<��^�Q�����q���j������P+%7`V�Dg���y�w�U���+_֤���m��mS��x��oO%]����)F#==j�4#�&9�ǿ���a����ۮ%R����赭��Yk�����چ� ��e!��X��6��������a��z����Gyr��/���td��J�S<����h&˕�GN/,Y��zoֱ��� ��|~ڃ�S�m1�o��-Mש�w���?��~x�6��z��W�������c<�(=���������<jT��ic��_�-M���7�|��I�1z�6n��1H>���L�B��6��tMo���z�٠�_�z��Q�5��z^��Q*B�"�(Z�H4�7F0�%b��r���~0�x����qG�B����I���U�{g��:)G������"P�p�,�?�d�����Ϩ���}�"�K����������O*�������k������z������̋���6���Z��������V�s��1�e�̓s�n�7�П�l��%�"]i7��wr��d�ۥ��)���p���z����o�k6�W�f�b��Y�G3C&��2/�xjn���w@��F~G^�`b�e��g�d:�������0�{�ݰ�{te"�G���呣��d�f�H)g�{��wK%"^ 	ޙ������z�gj�y�����x^ϣ�agm�it�sV��! ����S�� `.m����MP$�	��u��>fD@t�p=	�9Y��m�Y��!*�PԟU��=��W��<�M�����9ŊWv�K�,F�Ê��9��n����=8���
�2���y�M�~-1�ţ����8q��,�$�ǣ�,�IY�di>�q�7��d���KGy"����ұw�]����؛u�_�;,��ڕ�a�@R���xLX�x<f�BJ�	R�Yq�����ϼZ��Ʃ����ٗ�b��gj�%�1G��]0u�k����<���c;}�lm��P��ƙ��L�]Jڀq�����˺�����q�U9��a�]��I�_��c��~�Y�|X���	0���~c�۠_�'��i
7���W�d��Yv��?���_o6s��Gy��?������c���~/��lxW��axM��&���{}Lh���#yB��'�&O�?����<��q����B����)���� ���Q6/�����rqtŭ>��^x��F�qM��6�� j����f}��ټ�p��<�v���_˨rӋ��j����E�/J/z�����z�d�\J��fd�����h��Z.�=Ƴ��������rLI��@@Ig��r��VΒ�6Uq�!IHl�D&@h�2��8���XF�D����R����4��/-qH�0�jk�5�82�!�]���4�QIz���ԉ�7��1
o�" C�ql�oUh��w���a��:���(���#�NB/���`G�>J�ňޮ�y���iR��	�м���Q~&�G�q�`�	����Ux7���D6�>���@�d�d������[�a�@]��X���f�h�)C%#ÝÙ�������!{3��-��&�)���Զ����x��*���\R	�5�ġk[�����<򐂁��w�-2���=�Q1FI�A�DȆ����^y��2����~h�ɗ�������뱽8���ޱ���5�>����+Z��Iq�+����6b�/����Ii��u+��~�{x���7����epg����k��5M+ ��e���$O�] Ρ7��鹁�#~�`���0��ݼ�3�����d:%D�����ggC_Ns俌���V=�����?��_���_A�<�k��5������.����_zT��3Բ����������Z���Z3���y�9z��y_8��1pz�]�~�S/�e��Wx��s�9�����|s����7'�{;������f̭����w��0X�y�<ēu�_v�9�ը����Zmj�*]�����Q�<�{��5����9����<�k��5�����g��[�&��ptvZ��K����Jo�/uf2�[%{] ���,�Y�6g����¹P�͹�:�e�\z�͙y=�d@���4��2O�9'ug�D8�D�K�~����F�[b����6���h��f+��x��q/�|k��<eCE�(��v>`�`���Kc�?�}���	t^��t��V�����1�\�����������)��������� �<�_������F.�?ʓ���u��L���:O�O��l6Z�|�?Ɠ���?�����@V����&��W��3������ ���ך�Z������f��������?��Y�_�C���C� �=#��f���*&�G<l�l�K�R��,��=�,���@��^"O��D�u7D�Rw�O:G{��ȟq�HW�0V~�>�孲v��땢�C��A��aZ�-��,�G�B����C}̩鍓Om̿w����HZ Y^d��)4H"�3���9G�.㋥�1O��1�O�������(O~I�D;��Q���VQ�Ǖ4RԵH4�K��׊�?����D�-X0�����7��
��C�������!|J��+�C(���� ��.�>��,�&�`?��'Z2�/=7Q��#�'��T���[A�Ҭ)�'�'�'�'�'�'�'�'�'�'�'�'�'�'�'�'�'�'f<�?�Z2� 0 