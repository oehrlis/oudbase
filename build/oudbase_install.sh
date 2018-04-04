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
VERSION="v1.3.4"
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
� !:�Z ��zّ(迓Oq�,B������R�!*���%u�R��d��L42A��x��1/1���Llg�L �D��n��%8k�8�G��8i������}������k��_�Q�7��{�Z[�_�N=��ßY��SXJ�F�A��p�����?��)�:����Y��ο����ɣo����ol|��x���Í��Sk_`-�������mD��0;�����h���"ę���P�gY�DY����h�N�Q��?��l2I��Z}�ݫC�^�E�(��i�e���SC�q��Q�����YC�.����t&�;_�~8�Z�����_vf�y:�/{y4u�OG�ZM���2����g�� Z�t���8��_n���wcm�������?�7G�E��iB��g�I�E��9�����$Wy��"��<RqO�����0S�(�%��"�g�G����N)�1�q'�+5ˢ��S%�4M�� ���,Wǯ��05|EK¡�l8�y�O��v�Z�Nq�m�G��0�ߍ�Q�����n�ak����0a��t�h�3��Y)X ���`�pW�!�f���n������[����arew����Ⓨ��4�:R��n���퓣�����g+��6�5����S+��ծi�n2P��3��PۀʳQ�^��Y�}�F��ݣ�������z�a�Q-�>�v���Վ�^ukj��=@��t�I��K8�D@#`����ڋ�n�6]D�S�h�pgz[G;��'���U��h�ZY��{�'�;Gݭャ����xR�_��´+��m�{ke��;G�'/����ѳ��D"���SZ���~�V_GSB���:#�ʃZ�����lou{�gp��=��p�Z��{ttp�l-xy�;�=�Z�"6�o��v2��ǏQ�<U+�g�3D^J��E��;x��,�#�}*��Pww1���*Ϣպ�P���q6�W��gF@T%����ӽ�L�v�_�M��QD����SՌ�wx�w����߫����`{~��?Bp�N/��|�~��D��y�ŠɁ� � ^��}Qջ�R��>���?���BO��(�Ś3��m�����uS��g��4����t�p��{���|D�fN�ҩ�|�v�GW��Mψ�m�Q�������C�|�~��g�ZS??E��z�[�(L:��?f�Ԩ�ʇ�k�:���
T�����χqp�)���Q{�TL��xL��x�%n7A{�|�������a����U�G? ҆�"��
.Ar�N#�g�0�IP�P� @T� Hr�
U��GBl��ϜE�P5 ��;{����C���U�߾���͸���䛗���m~ӫ՟>u���,�Lz¼��p��jn���נU�;EYط�_#���{]Sϔ��K��jbQ[�y2j�&@�<5�1ѱ:�������aL3�J���<���s��j����^Z� ������
.�]��5uvZ�� M�2M��c����=�Ơ_�ț��!�.@HI65P�	��!*L��8�cYh����jB�ב��ku�c��g-	�.�Zw�%��]آ����n�7���p������u䬥zp�f�ʐ���)��HF-w���N�V����7����])��@-�4�͐��2y�y~�`*�㨳��5����N� 8 ��Y�͓E9�}^���Eo?���F�Jg������9k��/�f���v���@�vK/������R��]VӇ��h����w:�r$=�ݗ��NgI�r����x&�p�0� sDrgTЎ�h�ȳ�]�^&j`���j��׀;�X�x�l��8�Hh+�	�.�K`�uDK��)�K �(��rIc�Tn��u>?���]>r�	)Ga+��:�{�hY�Cڅ�m���J�����'��{{�]I�ʭ�p2���O�t��̲\]�I����p4J=���(�h�������s]b[����qz�@�* S+�ՊSӱ7�c�1M��A�P�l��u0��:w(��}�����MVh�mr�-<�iܶfTwv����������}�z���y�>φ
#1�w�I?(\PTK�W��t3�|��1`�͊<��	��Ve��S�7֍F>�������f�Ļ�/W}���^5���z����l8�.���Z��-.Eh��΋DE� ���q(ф�����R�U��P�[�`�:�\-`No�hY��3���F	R��x<���XU�m�΁9	�V�'���ac�g�)�Ɵ�'p�=��U�6�h��և ��v�@�����އX�>���ф\�Ux�Ԋ��,��	���2M�!�9b����S@�-t��Iou~ono���ݜ��l6V�W8��	s�!���&�|��ޕ����� �<�����8��/��kD��vZWG��ݝ��19D����}l���z�j�˨H{4���҈M+��p��`Q�wŉ�T�R���^Y?���X�;-V�s����"d� WLӱ�1=?��U:��Ǫ�ulC�����. )�s/�!�4�������̧7�j:9��:���V��/I; �<^�%��H̝�s��\�J��-�#��Ϳn6k���k��wGtW�Cd���m۵e���[�s]f�>	|XF	a��g�y4K��4� J�����&�ڛ�iF_�'I��7�����4�D�<�2\9|İ��އ����U�ơa>ٷ��{���¼{&g\q�p���@��ҕ���u�L~A!���90�p �\0���PAAj��~���J�پ�^��K
|�y�}��6�ƳQO�]��)�P��A;ˣ�9*0+��O��ۤ��O��\�i�������?��*�y�G#�?Ꞩ̽hz�%bm�x��g �����~������������u�[G���'�kE)��}Mm�V]>u9D�#���]Tuw�;����g��!�t�bؕ��~u���� D���;u�y����G�g��I�-�/���ӝ��^�{���u�g������j��3L���2V6���Ǚ����>�WW��]�|^�q֞�k�} m�>�1C��z��?���p���+��7;��Q���v�8�"��9��B7γ�Q�����A��̍�)��%d>7�1d�@]|���)!UU������+���t��v�]�8�͆�q�܀�V3׹g9��z[[t����3N��F�9X��9�kT��s��.m֞
�_���v��ɷ�����>�Gx}�=y�QyQ>�rlT��G��J����b����Hؿ�d��h�Y(7�m4���7	YQw���H�-� �n���Ɣх�Ng�#��]f�y6�K���ҋPX9�a�!'t^���ؘOf$!����[�"�m��?���{U
ңGe��B��{���P��������D�������O��������?_$���.��*��܈����Jk��+He_C���B��F�!������k�O�wb��.�^�&c�� ���~ĕψ�/w��Wͱ��A���1��Y�����ח׼�Qt����.m�����������;��Nh>҃�m�Yw���߫�������l�R�'9t�}���vE{�?T�u�ղ���K��.�����&r&ȼH�!0/�r��J�ּ��x��]��d �� _3 ���� �� _�0�8��	�98��W D#G�	뫐�`8��X
��$����p���
!Rq"��TJU�&h�#�}��Rz��$���{�JPq	��=��$,.
�'G2ʛ��>��W�*?���NA�סՙ����St��(��I�gźDľ&\|M}X��p���&YE��å��]�<qGQ�˓�t��4B!��s�0~�x�P�^_�~9��ľ<�c�yM�)ڰp��ۥ#�K��\/t�C΀S��aM�����G#�c"j�ZL�%���Y����K5ƫF�=B�0���h[Y���H}�׽f�ȨVVWW�O�~!a�n[��ɑ����G���~��l���5{�Hp���d��������$g��q�
�h�����H-�i�%�����G��0L'1��F���(~u�a��"�q�5I�$���M�)��O�
1�e��,�G�}�h��Cu�I|`���N�c���`��:(�D����:-���Ǜ�f� ���F�oN��:f��U����,���6�oU����r�ؖsM��|N��� ��I�1�lS.0�*{-e|�B�.@�%�8-��E<�
r�0[Zj�zeH8��e��s)le�8Q!���`<BsG�޸mM�C�Vڈ�{��u����h�r˶����}�3�Du�2�.?v�y��<OEC�����Ø�\���w_�\s&$@D���ˌ�Wk:.�`B�{[��9� �e]D߷�`�;ǝ��Lf��f�$�؍�������X%��a�}��xo�5!B+1���o=x�~�
����U���߮��ם�JǮd ^��2�-�����gY������--\!�YN���}�W�<Z�_�蒘F�N�rtxN_��o��G�?7#�@m�\i4fƻi:Q)���#M��)���6H2G(ï|�l���
�T�� Je�U��6�Ofȟ����i?�BD�T@7E��]<q�D�ثwE|�WW�[wT�~��q23�(��ȿLi)��o��T}�ݍ��c{<��"S�&^�#���=:���N<]6�Qe��?C9��34a�W�� �F@�E#~r疬Ձ�H��U�7��F�Z�t�|<&ʥ��m]�m��o���W�s�b)~ĺY�l�H�W}�r/&!�ߩ'��=p�!W�*8�����t�v@:m��=s�N!%.ڶ|˵�x��U����`՜�R�"QB���[��X��Z.o���F7xǐh���;9:��P���[��pP��.\�n�F|�RRҎ��ߣs��=�����)'�q1�]�٫�ʓf�C�@ST̐Q�"Wo��%y���(MsWll KĹ��O���0y������%H�|ٟ��������h6��O�@����D�`������ok����g�E���~����(��a��<�rv��Үo:l�x�����:���YD�G;��m�9��j6Mt�d�(c�F�U�Ŝ��"�/ս'v����J���7����tS������p�A�H��&����{���zTt��2�e�&0���
�(��x�����J<:�+����J�h�Q���L^!{uozU��F�HjR����m��\�\Oġkܝ(��!$�Ai�[yq�yv�>%��~,p��?U���D��U|n��J���SOX ��Oe�|���YM�C�&�`MI��G��Q(�1'����e� �\��:���q���b*�r� ����sl�dϿ�,&���j�?$�g��ڷ����G�_�~����?��R�����?b�����5��S��������	����|��}(��n������G7@F�g�/��M�ːX���I �t���Z��_�2�_ٶ��(<���t7��J�I����_(I�dը���|�m��\)�W�;�[Gݽ��qg׎�_�����M��מ�޵K���t40Q�f�G��������yg믯o��T\��N�!�f'���'��|��9H_s�~[Y0_s���kQ��9H_s��� }�A����5�k����9H_s��� }�A�m� ��6����p��%r��b�Ae�λ�"�@���F�e�=�W�8
��8�S�$#�筫��E��~��.�\C@[����5S�k�οn����q�L���^�[�!.ҍ$�q��0E�p�>U�O��{�j"�Ĉ�a�α�(U��;I1���oN���X�_���m�X]�`^7�
�OŹ����'0)tR^/��#F����:�%Tt�i��g<&ڨ��0�����Ø`۳附����
idK����B�u���+�l�Kg���-�ĿD�V��~MF���d]ǔ�deC��d[�ǻ\L�]*�;�MR���7OEr:9��R*�ҵT�"U��4I�XGJ����G���>*˝�.�
au|�$8��s��.��O:��0v��RsR`/���Ĉ�=?�Z8���9�ު��<�:�J�e��p�W���ɪW>�kq�9n�K�U9!��c)�X���g�8�';H���d�U�����/���M� �j��1�	��n>������r�`��`:SV�A鶟߼d�EV����e��Y���_	g�9�Aؘj���1\�hR�s���Z-ͳrNL��d�B���3��I�+�ݭ�>?���	T�F����~��8u�y^�
 T꼼��Yvfy�1�����$�w?à�d8\��QHc�IV���Z�	�{$�ُ\��Fsi�����g>�洚\F���2�m?u�0Lg���h�,����B"��?�=6��v�D6Y��'���J�l_>��{��ͱ8���G߮�K����k�����Gk_��~������b�߈�t����VF�k{N���5��s�,d_��c�n�2%�1�vh�s��U<�=QCW��դ`��}M������L㤏��7��6��*;7^<B~�p�"��O79Qz�F�r�����L�)���4���WO�*׭r�!�M�j�q��OP(֯j��s�qhԿL� ʊ��Vs!E8���,��f
`�dl�?��AQ�C��*4�Ijh�<��:������u�^SO��r jt�F�K{��a����Q揺[G�α	:���UR�V����?Q8탶�������O;��ݣ�g���S��{���֚:i��`s�'���xt}��j�#>1�qg��v�ۭ�ܷ�q�F������O����͵	|��7})u�_>S�9��~煟=���̇���AK��?t^7_=�t� �ҀR9�n����N1	��ݞz�u�T����Ԑu-Č,�����G�9B��UkBCk��T��mE�R+�A�ӈ�}�����vN��Ӵ�w�} *�7� E��7Mz����}��i������n����P��s��mu��;܅�ӓ�y4�P ��qxt��j�������;�r� �I���r}���B�Vj�b�͂�l7<��p�:y����$CR(�!B��@�Ɔϴ��!Q�|j�û.|=�������]Z1�.�]���:�_�Mg"�1����I��7Ƃ�.�d͛���4��m�j�ZhC��#�^68q:L���캥��s�"���Ha�u�|�p�ky��Aʂ����9��m�XH�k	u�`��yf{J���p�8���B��gɤj?0>I �AY �,p�3ψ�t�"I.���g��q��eJ���o��l��Կp���c�{ՁXji/8����Ȱ���u��S\;���s'�h�3�_:�;zJ��-'�%�JQ������g8�WQ��iA����s������&�C28��CQ�>
M�V�$M(Oc�C�c�\��.�D�x�qf�&ً���	��$=ۮKx�A��?qn��4ɟ�<�5p7�>��Ф�G�� �g7L)��0"��M,�`;Lʦ�kNu�E!j��}��^Y���BVGg���9�Cn��/���,�18���_B�$'��;u�ĔQ�r/_��:Eș� ���#-�Y��Q�wqL�|��z����
�@c#G�����R��x�@�L��6鏤���~�$!k7�[iO���)i;Ț��Ycc��J�JzƝ6�uo��|2���|�w5�I��[����;��p�yj�j�+�GrP���_�Y	���+��z2���GC�X�y� o{?N|��^ZB����Su���+�}��ɜ���Wh��?�q+hhoO��8�b.��U�Q�̀��="�t#�;O���B�V	�ڷkk�_������Z5,�HscXb�τ%M��a��1s>�o}
.,ͫ
�o�D���D�̼�ñ��?L��)
@e��ybP!��[���C~�E��5�Q�'�Q�t�}��Q>���ו�zNCi��Sjk͒~[:�R뢽R���+��S�/!Y�&��p��<e隿&���U�gM2	9�|ڪ��+���v�*���M�b��owd0Q��Q����	�1p�¸��l��~W���wڏJ���~quJ�]�f�� Pd���g�`*A72R�:K���K�S�je�����G�t�6���t.惡��+�q�\͗��1���~&p�" �t L��]l���6[��b����cGni���S@�������ȭ�Qa��Ǔ����t���RZE
���*&���]��#�>&,%�Nⓖ'��c��Z��cB_�ZS�d�D�X���M����?,��\ka�=ASt���w�2��N�����f�ఫ���gRnn�����ͦF��{˂�C�|��q��çӰ?�NȒu�Idx��V03	I�Q���T���eh��%*�w�j�H%�[͕��^�VW���K=�|�����A��3�5�ϙ��4I���7����KIP7����u[���`��O�}��N?Ţ!�o�I��"�ܕ`l�f�-�1Ĩ�l\Z����C����	6�U6�;�̝\��-��1�٤̌]Z!;j��f��1;fP�qs2"�s���b��1M�f׊��V����JV�h��Ӻ��i:;;�`@�����թ�<���iH�6�_Նh�C}�kO��֕����T���T�yT28�͸����a�eҞ}G3<�?�����-�X�:��1k���C;ker7,ֶ�=9t�;�k����J�@����3�K��`h>T��i>��7�������7��U���r_��[Nme��4NNN�T[���ZY���.�u��g_T�ں�D)�au�s�gX�)m]CJ�ewK^��������C-O\���s��b
��U�� QZ��Qd�؈&|I�>�������Y+��ѴE�k�����:�����t"���lr�)a����>�~�oo��d�lNw<5]�%S_��������[|�,yE+�bx��**7�vp$��A1$&wnX���
���sZĥs���p�����5��<�"��*ܥVsR@�m~w����x!w��y(p=)�e��oN 
�*_�%�ֵ�.?�)��>Z�+/�����$�����^8�a��>/���,K���#U{�Ŗ�M�fgw^��!�ɉ��\AW�h�VhӈS3�|�F�Y~�Dq}�:24�WB�ٔ�y���#꣫%e�H�$���� ���%Z<�T|T: Y�#�ǹ�U�����f>�E=]�i���z��C���I�	���=B�W�N��Ϳ�5�T�1����}T�]$�ye�@)�Ƒ��i�߳����V�2|( r&�� �3B�?��~~�,~D�7J�����̿��@T����/h�8�Ff�'@Mt$�[�K!�B=�OѵJ,�����3���+���w|����T�~����7A��͠y�v�?�訫n����wׅr*���]<E���}~��L�va���>��tq[��.n�������.�]�H>"�^�H޼]�W������s����E�ϫ��f���|ɔ��'��$bV���U4T���31`�i�v�rs�|^���a����.��ne��ԥH�tbYg�٧�4ER#T'
[��q�S �(--��`��h�}��܋�d���u90��a���V]1�^&��:��^F��9X�6�`z�_�2Q�A�{x���������l�&���$	l�Q�jV�9��h���y�%;Ü��Ɍk��z�f0�y0�j)XM�4�ڏ%<��ˊXV*�M����ƹ�������Gt�a���&��/ȱ;��T�JJ h��;�ݨ(GRG��=��E�?�tvw:�|;���Ұ$�*���ԟ�ޯ��}��[�����P��=o��{8���U�C�W�o7����A~�l��ʯ�$�f��o@k�r�`;Ɵ����Yjf��g��מ���5�I8͢����}���|��
��D�|�[[�Kr�_�N���h$���J�D���|V`����{�5���_j�S Yh~�k��a_�" ��m~��X-���6��SX���dKh[��kI��Xw�.�A5�LL�S�8�d}��%����VSX���S�t7+ڂ��&�@G���f�k�^R��(a����ܱ8�T��{+vx�c����@�T�ü�P�(L2�����ڧA-Lmjy���,ŗ�Ќ�Z�Z�F�Y��lI�����z�~�=�0�C�2|�
Y6
h�F�U�6עt+̇�W+�jc���eY�]�Fm�D��ܜ���H�V^�=N� �D�/<�i
P^��1���-��Bdm�!�:�ѣ���R�1����6��ciH,�;���$M�Nj�"�^�Ӂ��b�3���5dy��G#_����ra��(��?s�-�� 	���s�����4T��T�[�<�g��u�Js1�Шq���_y~U,WL�����b������� Q��L�+����?�5��:��Iu��U����F������Zjᵗ9��12�_#��dFv�|;��K^��@�'Ӭ���T�2K5_V�H�?z�8��e���+mٚ��+���O�c�a<�r�R��q����q$�.��G�$�dD�uwcs^b�#�s�h��x���{21-0�7m��4�i�G��x@�*^��݆ �@� b��Z??�C�,,*��D�3�>T���Nf�|8��~�F4�ӍoV�E�*�v��Sܶ΋9�,� 2�U�En��%C�e���$/d,/���C
�y�6˵_����ur�׎�ֆ�9O����1�X�<NWq�����؀:W�w�]��f�/�N4<��[Y��(�w�8��D�0\j�^�'�F��W���Y�%�ˬ@_M.]�n���j�s4j��8I�ܑƃ���},=�bC�(���TE2����B��%��m��k��V��EKK�,�)	⩮�.�Q��\�sn}���Ufr����/I��W~��2=,Vx�Nt���ca���-NAt^��_����<2�&y��y����E9���QE�r�	����y��-������k�V���8g?��Z��G"���s2B-FQ��g���<�߻W[)�]02��A9�G2�68�v�������u�ұ��t
���9��h �m�������<XWs4g���~T��@󓱪�V�$��u�C$��{4 Fa��r��.F�i���h!I���7����N����6l�0ޭ/<���H���n�58V��O��%Et"m�>�l��?��\v�L�/x9
�M\�ɮ�ＩR��[��+�PUHq��RD�<��]���o3�N1ߔ<u�:�P�2[�}��:0� �uhP�W�b5��c�]�GTn�q�1��X/Z��}���3���̕���V�W���0�,ݮ�.|`�E��sͨ��+~\�w|�	yTނtFU݌l��}|W�w�>�Ν$mI��X2̖tx�tЉtK�<r�pղ%�Z~jڒn�s�����y���]�eǺ��؂�8��c�7�y�k.y�k�b�i�K��HF(Hݬ��b���<�8�5�1��\�K��Sz5	��i�͊"Ġ�7��,(^�_l�E�K��r[�g��Y����Ռ�>�x�(¥7A��'=r�,:�R2be]��F��h�P+6�U_���aq}L���U���W��3j@�����l�Jǯ�jO�5i�ӡ�juw,��ſ�.�>#��>��~��/�7�Ϸ�]c[������yxQUB�|���<��50��`w\ݚ��\~��:(^�E� J����0���M'�w�K�ݴ1��{����"����YR`IM8]	_����^��x'��Y^���.�Ĭ� ���9��*���vk��e�� S$�p$����]^tv�kj�����@�?�\�Y?��_\i��:��B��=��7EQ�~E�AY)�k�q�z�is�%�/���Ɣ6���l8����aDV��=�i��6Rx��sy�	(_�2{7ޫy��p��m^u���K,�3?��2��M3�%xˮ�V���U!�_�|����L��Lr�98�N�*�z�S�fue�O��ZJU���/{E7w��9��1͡��2n��B7�����@�ǎ��ή6ݘT�6m$��4��]�^�]��\���**��+���
T�_b�����B���=R�Q��U?��Dx_rFZ�ܐێ��v)�X��YLa�ek*6��Z�I��)O}V���5T9�end�����q���>Y�����-��E�ы�
���P%u0�k����K�f��u/�}ˇ+ٴ���uc�3�r�ɢ����Ty>~�	FQ.��x(^��K���m�o|����/c�V���N�$���{M��5��&�oQ�c!t�wv���I�<����E�[z�|���w�����{����G�������S���������x��;[��^����x��ќ�__{�x�a��7?�������*~~��~��w�:����s@%(T5��ג����6���2K"���V:���g�ZݪӇ��4�T/�"K�2r�6���[�;)�:̆�tz��>P݋hz��8S���s~Ƹ���3�7��S̺���0��	;rr9����
P~�T���=����d��QzZ������4
� �`�c�jj�y>R��S�M�uΥ�����xQ4,�$�40p+����ɀҪ�ꖞDze�^9+��`�����<������QtX���?��:ٹ�S�I\�(��
��|fy#ȗ�8N�(�9���iG��Ҍ��$���K�M�q������^t�'�i8C�s�����_1_�z��O�`O�)�gO��Z��d�F^�y�}�ɕ���#o	��W��p�������
�HW2�d�l!M	�`��e�q#�;\B����_����0�R���a�7�%��4Ʋ^� ��ޭ�5�=��aiSƫE!�&�,�O��qO��a�1
�0�����z�L�	f�ji:Г�(�̥cpb���m46�Cw<mX[�W��$h�h��\jA�{��wz�����{|?S�c�$����N#���)� ��O9�
�7�crG\g�����v��|�2ܪEtN:Ńǆx(A?��!��b�,>�Gq��!`�<%J�}"��!��fy<X~��v�� ����Ǔ��h٬no<��s��>��n5�d�c�,��$��v2�L&y�;�XCYWVB���<����A���[�1�V�8@���Ѕ0[�=����L�[�ф഍	��Q��_!#�t�[�^���_v��$�V��6@�r�5�{8��"f�n��@"��0�����w���q݌x��݆{�0\��� �9u��ӻ���	&y��v���6a�}��S�Xj�{�Ob1{�9E^r%O)řO]Z<�)���40�fp�v:)�&��c�a@� ��E�R�����ˊ�>�0ƣ �#�za.���+��Y�B��+AtGr�f>�[�C�o�T��K�}��K�tT��t��m.7v��[p��,�ct<A|�K0��e)Q��7�(>a�!���p9рè��1R�@�/`����'*(3�2�]*S~c #ýI,i8�+����)��h2����`֗'�@z̀#̡WC"�P�D
�E��K�+�B�>K��R>i������@��5`D)"��9�H�v�4	��p��Ra�ٙA�p�I���m	IPY�ç�����j� Za�u�Ȫ`��X_V�R�ġ�3<]��]{�O�Win��@�Y��'���M�4�F`���C8��H[��cPp�_#��G;"�b�͉$��a�6�sMJ���'lZُ�p�8ӜpQ��?�X�'�I3�����3
t5/Ҙ��u�"����Gb��l�v�"hK���$#�\��W-�X����LS�@��P��,�i)@O�up-FS$�#A탘�燔]<A�á�R~I�<52L�4��B�ݣ����o���;�;�=l���Bb��k[���15O�|�-zh��\)�2Ze�n��a�]s���K��,R�D�n�f��(�c�=@	�wf��{hw�(�9ɄM���h��rJq��+����҄5�� �<�������I�(�ёԬPS��]!6�4��r�H�Hk̒a^��%͙c�A���v�U'�s�>�R�0;�;�0��[��
�0ՎevB,�qI "`����S��hqq��_�	�Z���dM��֫H��j�}P���V����S��g5E˂�v%fN9lgx=9J�6@���QhD�B��?Ws.�����;л$H�ed�N���,B�� ��a��S��4��� ѧ>��g���{�m�* �<���H*#��(��\����P��� �4fh�H�ёU�,'�T.QOÔZ�=��mg����h�P1v!?�`���e4�� ]DEt�{�w^���Q3:@���N%*�@YK(�̐ �B.��e܈/*y[&����b��_�7J�! 	E�6�p��2N8��y."��> 	-�u�ht&�_�vI^�OQ��j��D$0決+��I�9*�E&�]���!�r��~affs��ۢ[B�=#��X(-ꅒ�
�
n������$�آM��fD,�4�k	�f+�RRـa� �1Z�38�^��[�``�,i�X�'$N'=!�lyM���5X�e�����I����3��?�o�0!�zK�WjUO��k�>ZU�%G,�Q�*b�G�Γ}���{YY�ȑ)������B�C���AC���PT����f�;����9��@=�QcaG�im J�T��x��IP���Z/�T����(s�Ht���Qh�mc���Yx�Ɛ����mt��X8N�H���qے���(C�3�zu:��՘;
U�b��Q�>����R+D%Pcґ�����J�	�9�s�w���� ���41fq�,!U�"L@��9��Ӻ��M�òV��EIP��ū��f"��Uq��xq Q���CQ�P��X"�-6A�����^�&}��Zn!\l��)fD�S����h�$>`�.:c����
Θ�W�.!1an��1p�u�ȼA&�>V�~�5X.���Q4�j����h����k˷�@n���fC��=��#'�?&!� i4

�1G�Ե��b!�3�uڽ����p4w2�ɦ��d��O�Z9!�1 E:���p�/�K�Z�B"��sz��YP��Ԣ���)��� ����Fe��S����
8��$�}a�x+�ٿ���V��Zu��a�� a�4���jh�G�>��*��_��^�.Ո���=I`c6��]%��VX���ԀƼL��}Y��L�v�@�S����S��0��1�%Z�%u�Qa���S�0��1�/Z(U�x���+��]2b�6�N32�M#���[�K�����tO�x-�U-�=�� F˸��F�e:4
	�����|F^�A� EH���B��۔ч��O�`�a)+-Z�c�B�� plTW)ʵIR��M�ԀF2�ϒQ<�q߆�iKY������T�qB�2puHRX���+��2��Pg1���%byd��Y.����?`�Iz	��Y�;��h�y�>-�4	��~\�#�ϙ�镯�����1��0�	�R�-��j��D��>뚙���P>
�,���-FGfɀ�?��ԫ��0yj|g�c�T��a4e��|�h�
�˲�Q�f�pXQt����e�>�!��K��p�`��9OF�2������=2� ݚ�,�	�`��2'G��F�Yfl,�"��V�5E&}p%�N��p4l������Ć�Ki�E���i�1x���h�md��c��F4���.	�Q�f8��x�,z�n��������?�*�^��J��#`�X%;G+�R=�H���A������y3� �:����tD�=^�߃��#��/<�V�-Z2ځq�]����wx�JE�$Ⱥ��Qb�&f8��y���3d&�[��ƴ0r�Bp��p6nNEOR���i��a����9<pG��}s j-��n��m �5]�ӟ���
2 ��R�!V��FU1�%���z�2�����O+�|�T�J�,��H� �?�����`��|�7����uE����i?&��\�	���<�W�Y�8��#���N(�&�E�L+$���zW�"��er,3� u%%H:
߮�K�I��;�T��epk�0eg��C��I�������:>k�j.��-�p�	��y"3�@��0-� <�,�l\M��l
?;e�?l�X�A*��#f�c�g����4��F81�r��
&.�#�B�?�U�-�\��@���O%�Y��uj0*,@����ڏ�v\��SZ�]Pߜ��j�J�5�h7��=8�)��.��7fit�PP��E�q8>A�$s�6��BKx�"۞��D2~�:�X�Z�K��HEØѹ�ܾj:��E�\��$"
�����QƊ�+7h�2�M�Ѕu^��̾ �r���Hi�|by�4�����v�!VX�J����4y�%�V���	�.����mV4̷ZTv^�ӻa���*D�x�8Bm�ũ�F�u#�eXb@��Fv,q����M��m��eEV��^�Ye:� �>�� a��&�>X���%�gB����j�}�b&Q���6�����`�q'(ks׺e�"Ty����������ڪ8^���Zh9Pm�E����JpEjd��"z�����K�A]?�Cc)����ѫ��!�2���a#�%�yg�˴�%p	7y�f�,̳iڅ�A��C�8����FV�e(�����xḐ6�9E���P���Ԟ���'/��t���#��Nɪ�=�ڬ���=+�O�u��
#*�蚾HG3~�+�"耄�^]vܑZp\�IP����ok�Zq����R[�/+�	�E3b�����4�}	ON# 	�Pm�~}QzY�A�SB*[����wdm�����+�tȕ����
z '.O�aE��8�9��7�T�dbX�eF�?����.&�N���UZ�
�EƧ$�����R��|c:	�� �!Y�z�W���E��Z��ӢG���Ɠ0��]��D��/~��J��)����< s0����Y���p@�
�Y���s�Dm��{�R`C�gi/�j���`��UN�t�4a��؟�09an5�k��#d�a��f+ N�{}�dj..�[$R�ɤ�\>#L/��2�w�`��H䨹��F5>�F�7Ǉ�����.\|�r4�X���ei"'� �s�.��4D���/#VaH�k�`�����@v$�� V�|v���]�G'΁��Q"$/�jU�@W�G��o�ř6*��8��Ì$3VGѥN��M�1GX����h���^�|���=�w�-N������Es.��hct�����!;=a��J�Ř}>�:��Ak�vN}။FŞz�ojB��C��0��[̦ldl`Fe�$Q�����]Av��!��x�������IiV���\T�Ǒ|�M�>A�U�1= z�`�֜+��F�C�]��r9�o���B�*R�Z�[�0��ύ@��2iT�����2��>�$�&�ӌ�:�vo�ݠB�b�d!h�	c�Z��%�aX��[g���m������Dso͌삓(�6��r��	���qp�q��vFT°�����AB0ԳB�ӈ����x�u���5b�]�!Q%XC �h�����N
���7l�%�W/��|*h.�qd|oJ�:aHh�G=yh���ph��fcV2��VtL�S�c�(���i��"�[n�Fڸ|U7^���60��<��A�h�Uf9���71��@R���C�E'�>�(HD%��%��6�!��?o��`��N�ጟ�ˬ��&]0���EJa�$y�g:�ƍ����=Q��b�jOC�<@yq�A~5!Y1�(:@/F�*��,sR>����LnCarś�Rz��)40F���(z�F�L?B�4����a��#+�^X�>,g28� ����f(M3���A���;Khh���O��A��5�lI ����E��p�+�;D��w�^1'Bp�JYq��1А<0]��]t��e�۱5�8�NdD�x��"m�l���x��a�?�f�%��[Z��l���Q�͈�1��y�P_kP�+ND+�TRS]�T&l*�}qh�6O#R�}��/?%Htg�9ђ�tM���Ƈӱ[ύ�J6-��.tml�#�s��fƉ��0�S97Q"F��u�&����&��Hd���h'�U�(�����K֠)Te�Ҽ�0#��$�w	8��J������dJ<�\�7`]_ͻc��?�k�6���T���u��ؑ��%%��S��+�npR��Y�� N�{&��5��w2 󎣃��	[r���Q�^��������i�eG
G��#Bh~��c#��Cw�^���9%�WA�����A�Q(�N �� "���y���PH����Rhw� iY��Pĭ��[�1S=��"NG��G��I11��L��8fl����4�2w 	�Xp�*�=g-�A��{V^�L���&²,�]� G�?�
1����b���4���H�\AS� ܌pb��[��Sy�Ʀ���ma=c�9��A��|j�6����q��.�7u����pF'R�aq��4�lϺ�ZA�"x�P<P�k�a���#�p�'��tc�9��VwY^,��g���J9O�F�.�\{��o�������{Ns}I����@tTo���]U]��EN_J�!<�Ho�zsb�XU���n ����9�Y��0�%$sd�A�>�- ���,�i����Qz)ˀ~��I�
�?.��ޭ�u6��%��|�B�;�iL�Oʏ�#��.�@��ʸ;��m�x����C�tA��]�;pQ�q,��Ty��)K@gˌ���y
��2v}!��Ô�+��ؖ�$�&u�����Ei2�"�MJ�3kCM1�!S돉��?)��)ʘ�	qd�MIm�^�eSx�3��L��F\�"ͮ�8նŒ������2��=��G��v�����x�M�`�ѽ<'y'F��8+˷�sjT��f/�h���]R�^�X����Kv+�:�6��I5$f�x�چ������v�S��$���l'��F8b`����U7e��q��~�A^����m�ʥH����;t1�����;q
��#ˬ����9�Vu�m�%�η�km������m�r�� �5��+��pN��$���R����J �� �r� �b�	�l4O�|�t�&������x�{�����#2������� 8��%Qz4w�9Ԟ��PDUX�àռ����E-p��b#�`�7� "�:C٤T�ά/0*g@�,8 �?�̩-^L�+�9����X��w�8��|Z�v���U�F��bس\�	ؙ�~�FA�e1�����7�P(� <��&35(d@@' F���5$�BHwR�г�'�
J�OP62~���ܟ�x�Z���uq۔['�I�\#���na�(O� ��~ٮ��i�z��"%N���}P>�����
''	ݴd����a�TTE��`v�FX�7����H��ª���YV�l �h�� �ƻ�DJ(�`,�BElaA�V�M�=��Φ��NP	����<$��RD�E��f$�]SuQ Td#"�+�����P�0�@YUʑ^VU2�\���O챹���!�h��*<����y���4�%��ࠚA�ȕaȮ�59a�ɚ�T3��$(à��)A�KB��ΞJ[�=h'q�9{	���'���/���8���sZC���O��i��qAq�6�?������@">`9�8�ظg�~[�c�!ǘ��D��K��_�ȁ��e:|�L@�ݔosK�Ә�"���{ ��{�4��7�� ?�^��
!�p�W�UG%��z��(� ���"��D�q�����Gy�m�t	;�:G�v��(9�p�P ����E$���N��r(���R9$k>�����֤3�8�gY�,�DD�`�6�JN7��-�J��H��F���U�c�i��db���w���+Zr�^�!����gj�p�!��`ڐ� �+�aY��=��p_��;��I���K�h,_��_��2�gN���U񸫦S�#���K�L4$�a��8˩p��3��+��/��]��#�l��e����!�bdH��X'Q5���d�?5��]���9�<����ܒ\,�ye���c�N���Q��5<�c���c�[��ۼ�Hb�c�Q[�*�N���I�s����+a�]���&�k`�^QK�u��Z��~u�*2(���0��-����G�8+n��F��y4�uI�b1�b���݂A�9kBq&(~OA�y�0���V�rU�E�F�S�Be��&i���YH�G�Oy��i�4�(��;���X]w�^�#�Ngoٵ�1��ҕ�cz�;G�B.���,L��&�A��SD*�MNL)����ggZ�A][�=�^�s% +5Ӱ��T�=I��1E7���-
����'�*Y_o�C]�R��K��Nk:� 2�2]�	�P�L�)L�U�9�8)��O �m��ڄ6B�(�2�6��6��L����q�.^*�o��0�h�T�p�����4���a_�8d�,��O�S`�<r:'N7s	��&%<(�L��A�BΑ�X(� �2"j�4ou���D�
����U)�s�\�+m�si�A���-�f+�yU�"�1t���Mv51����\����N�jGɮa�`���h�U��ir�O�vH���sp���KZP\��\t�v�[�Wܖ}�D�]6>1ؐ��?1қ���슬O5�L$�+m	�i$�)v��9��$��RQ_�J�"�D�ݒ�tՔ�K��%YX��><�E����I�5����-�ړu.k[�s��B��	RpK�@��\�X�9�-�K����N�VE9�W,�������Ii���678�t�?��\ ���Ne�1nR�E��$)�:������`�4E`K
'���!ȍC��N�N��W���:�LnU�xƊG��BYG���i� A2��B���T.[}hfh�)�E*���غ�t0r�&��T �x��"���2#�S�GquWd�P@-%UP���d�f�g�򗶹��8q�*�2�{2�1
��c:'��B��d er��,��(�."�!���n�lr@�Ͱ�$�ʤ"s�Au��䠙�9� \�t7� �i]Z�&�(�Δ�N��*:Db�e��V�1�)-��}��4��C������RI�N*������Y��ͨ,&,�e�W�)X�#C8y�MiX;E��T5�?2����ӫ�<�Y
�c?���9�C�0_���²uf�z�z,XE��d��䇣��BZ��Ud*���j�`dL=��	�_` ��S� %�Ԧ;��L?���!'�'�՘�R�P���R�F�W�H��Y)��s�+�ͲYC�47��^��h;]�vh�k�Ғ\�)|�NZ�
~&�G�L��r�\L�}Ƽĥ���:3tB�:(őC<�A��抚�#X��iڙ��䝭���H��Ed#pMAPK��X���24�s�Z�7����)������c]Z�1��L*&7����N�)� �����@u0f���� m3"2�.������z:�F����F�[��3Fp�8bv�^��c-�����b u�Ԫ���݌*ð;Ñ�b�J��0�a�MX�����v��� ����64�oˊ��l�&4>��R)o�S˲x<�~'�#�J��<��.��3��RA[�݄�����G�o�Q񓢩H�D-�O\g���U(�F�%T�G"�I�4�sg�����B(�d��sul4`�g~d$�Ѕ%����a8�K�љ:F�Os��?laD��2�]�j���)>)���)�;�HX"�����{yB�S+��X�|%�d,��.����_(<� �1�!��w���
�cR�JD6�q�:ֺ,��`w��8�R<P?�r؞S��h]F�� g����*ƗG-u�	ú_G��K��i�[��*Ȧ2�<��F7`Lo{ދ�t�Н����!����ں\VH����d�JԢ�z�r��� B�0������ϙ��Q#��܎�I�'��+�����4������ȯ��K��M1w�3�
�

���Y� ��Ӽ�H5��-�ep$5��Ϝ'wD��Uz��Y!?Q\��k(��&�xS�32;�	�]�Zԛ�B6|��j/���Of}A���֬�]a� c�_����D�ɪ�"��3[��8���x~�~&�?��w�Z0�!��^�;	��{h��e#�t�Z�2�@����č�L�6:7p�����$�z8�BA\¬e	�N+"\H2`*n�	ږ�2b���!%��-Ψ�F�ÙĽ�u�NO��7���������~��~8��5����������:���w���������V��nW�v���I���=<Vo^v���f��U��v��Wo�v�w���<����q��`w�{D/T�av�;G�;�����v�]��uz��z�s���ձY|p��Q�ug���;4P�?���, ��كw�˝���W۰��z#����4;>h8��գ�b`�����K���|gw���j��9އ)v^�֫��Qp�����m)! ?���U����c��{�$=���9�c��^!��}�n{@A@u�v�Ew�x�u��-a�ޫ����w���]��݂�v�~T����-��Q���s�P�:8:�Q����8��8<vu�2S�}Ġ�kďW��������"�(Kp��G]����X��AňѠ.��E�������<A������{���E����sX��V�P�s���u~����9yd��z�ݭ��|�eP��`�x����:p�8"'�c�
."�F�?s�j�.#��=�!۝㎢ÿϻ������;���zu�[`XM����}>�/]��@_2�����WGE�Ù �8$!�sܢWox�j�L��R�MyW�G���y�u�_��u�y`�;�� pd����o���{�$�y<�g2b���Cd~o�|p��}я�Q��8y�+K|�P�ҥ8D8@�0�d�K������^�Ύ����3A1��=���h�:����S�d?PF�/⑳�
��#��@R/7�&������-��)z��}��k��%����K~שC �p�cZ�#��}Ve��A�w}H����pyrZ<$��3�s̀s���e��҆xF��ka��9Y�M����<��fq���D�(�'�?ī_V5�%��G�(F��Aա���S���cw���C������ Qq�9a��^K潈��%�L���_��F�!�yP��u�7RjF����,f5II�c����3��ڮ��-ʦ�\�!8�������~F�D2��4���A	Mq"1�����DZ�Zݪ��:��0�����y�cy�U�mxǽi��9ε>(.���(.�����/$�g���jLɴ`�(8�h�O7��5�V5 �>��U��^�I:���d��UiQ��r-�=5y�XA����OK�8�(yp�	^�
^��5Aa��]�&�Q�p��D6��u���rN-2KV�1�!Rߝ��d�ݾ��l�%�V:=k�p�������aҍ[���0�$�7?=N5���7M��o���\����r��e=r�-M��c+!�c�rG�W�eca؜�6r�S�`/�����d��o|Kxȥ�	��罃�W���]M�)���ʯ A��^|��߲��eDˣ�ÆI�z�|�MR��$<u���w�G����͍�.T�B�>Z��-��_�w3����s�JI1�mK3����� +Yh���p�^�����-hF�U�	��4}_3q��d�5�PK�5�{�^aD�ث�+�E�hZ��.�o�p�sk���
H\L����j֍oʺc�����S�/���<+�~ Z�����6\�`�%e��JcL>��"�W��w����+���Ħ)�1#y��J���/�u�%`0y��"^	�9���(��\̐�f���Y|�.u,¥����:n��a`�y�=���A��K�P�FS:��T��<Q:��_�/ϯ� ���l2j�������i�}��l�u[���cmm�ɣG
����c�wm����G��|��n<Y�x�x�ѺZ[�������Z��3C�K��ha;h6.��7�̿�$?����m|�-
����`HD��[��n�������?�QKy��L���%	U�P?#I5������ != �=�7�NC�Ĵd@ǳ��o�A� j�ق1��6u|8��@2�k?��p���mo5��M9�	���=
N�ϴ���+]/��m�1(��������'�'s�΀��������4�P���n}Oß��rhRR�z5�_a����������^Cu�������EH��|6Z[��R�^JF��F�&�=�H�@B�%�旙c>x����Vv������_�N���L
QɃ��X͒�9�!b��"n�u	R`�Ч'4K�e�'�����KiT`��Ej!��s��"�)萛���(�:�:�����X�����z�����V�k�N�����\��(Ga69��Ŕ���ѧ1�>�v����(�������{��Z-�A8�{�@A�g��qٸ��A�!��6��\�%��Sx���
���5�09��[���K=��>`�<|^��������)���a����V?��'�A��ڳ��6?)�.O�������������Ó�G��|�G�����M|E�]W�O��Z�Rxc�h;�/�& bh-g����qX��.��*�����y~�3��T}w �v�{���~��Z8���鱳;��2]j��w/��ϟ�篶�ﭿ�:��N�d��J�О�*�]c��Ϣ���.�'�J�a�}C�o�h���9��mMiZjY�pzF/Z��-�jُ%dBu��!����e{I��6�{у9YD��{+��zk��] US�k�z
̺��n���@�ڪO�P�@����B�{06���!ՃΖ�À �xg� q����'��1�T>�^m��^[6cŽ\2�i�7�dUs�W�'�yR�z,�����Y1��r�-��NKv+̾���x0Ex�K����t
�����T�|<)�Qz�L2���n��W
��#=�]D|�ƥ�-��<}�@׼���� C3���������Ԫ�86U��7��Z7��!�v�
�o�u���nx�R�A�����(9ۄ���A�h��"^�J����c��q�\�0��G��͵��������Ǐ6��NYo��ִDr'��B~��y���x��he{��tX��2]�6�R���p$�U��gE,BsH��vC��0g��6^�E}��['[GK�o��ؼt�yY�װ�rߥ�<6��i���,?�WM<��g(�כi�M0���`����\���7
�֢��������Fk���z�Z���/��8��������g��/���[o���v��dc�H��������_Ƽ�4t��א8 ��Z=va�-r�[��fL1�0;��m�kdܛ���^ˮbU�25����ߦ�~7�G�oF ���&��9� �i�ŀ�t���S�R��ZF�߬#Z�p>��������Ϋ��w�§�쾧B��Q��#yt����6��~���$z��R���6��v�~I.Sem����1�� �M��'}�h_·ſO�Y:�c8�k@�(>mp+���R쯣A<t���?�@`Z����'�Mw��l�b��߼O�\�	�s���ך\�	6T^��!��r����ٸ%�k�k;�&�o �����/~�okŰ8l3�O��D?X��G�p~�
S��F�t�{���~:��A�Ie[4^��l�߱@������C�P�ZX꧍���𐽘 �S����ɛ��7%�!(:T��܆��*D{|,!���Σ�;����\�9z�R����u��ZM�������Es��Pr�n�t[��R���M4� ����Z����X����Ak��9���d���Cx�Ή���=�������M��݃��.}s���I<jZ�	��k�>}����읟?�0'�w�<G�����+e<��-��5�f�m��0�F�ԋ��q����<�H���
�����c�R�h�����-�l+�hnQnFF�?�0�Ƽ*�iWy�(>���ހ�7E�aM�EW�n��6�tun{yV�H��jrx�F���[��;�ν{�B�c2BXw���8�ȧϯ�]�vi����6���*�\�a�xTg?�KP�q�V4</�y��황R�bw�-�Wak���9NU�X���Kp���,����ߘ3U@ܱp���+dc^���F�c���M�x�7��=���&D�Tw��=-g���-	ZC[p��]zN,@����/�=�=�	4��{fK�.�����#�
?�vĤ��аY�Q��`CK��u�qዒ@ˤg*���v�9AԹ�cۅ&ၭ����3��E���s���R�LzAh���T*4M�Ҍ�<��nw�ㆸd��^oW�z_�Ȇ���#�z"eT�@ᄩ��s6e3C/�fd�eé�����	k�1Hi��_�oB���X�Zj7���Jۀ�+��\M��"��ځ�" �%<�	.�jת��D{���٣�=�
ze�髻� #�>�؜E�;�b�����c/tT�Σ�D���m�nl�{Ǵ������� �h��@�&b%�J{+�]yj-kg�V�� 	5��A���ny��W,�#3�m��H�e��yY^���P��r���4����K45n�=̨���1g�&���T������b��D$WܩӨ^�1���k�Z3����?�|A�G5[�۰��U2=����qC��u"7�J���8��E�[�+<�TȄ�'6O]��a�v���9S��s,j��S�Rah��. Zfy%W�<Ȭ7/r��Pt��TK$VyBl�3-��.�,_&��gp�H�!�۩7�L�'��Eα©���'� -�^|��6�%M�0n�C�������,�Y�/^;�����Z�1�h�m�i�OO"0�P�D����r��;3�z��ڱj�``'�Ǻ��:
�=E�Fg�
�����z�,����Pl��N8ȼ座4o�4�v2ä��� �7O�_����'�6�T��σ���t*�RT��>iRAݪ>�t+|�R��n� ��@�Y����/|����M��6wYT� ���?xR'������U�������:t�h=�%T��+�]�5~����/�=UBe�D@ۍOi���Q*b��+��Q<��c����%��6�J\X�j%V���'��V�}���ٯ����Ə���
��|�b���?Z&$SU�PA=z������(��֩�Ύ��gԠu�T�&��T����ۆO<��Qۇ��J'�d�<�h��@�Q|7��̤���
���O#LߓW����5�2+�� ݠZ/�܍�;��La5����3�Jd�p���;�؍Y��]��(�d��ǝ�<������o]o�ܿ���;p�t;I[�\��vl'�.��XNR]�Z/��X&�"e���>�����_3/��  	R�勬8UDϤd8���K���^Os�OE�d��$�g�J��/����/�f��^���l�����L۬�\K��K�y�]K1���ewj���.�W�&n1P��[ 4��_Ų��e�7��J�"|_m2�wJNR.�]�NaGA��5�{��qS�d۰�-9�PyރJ#�JK����Q���*�c��EsXH�~c����9	�/��s8�g[���I��S�"�1%��I<Or����J��Y�7j�����pOp��.�fHbG覟�j�nP�Ó"+sF��g��Kl!�'���P���G���=����z�+m�����r�v����]x�PW�?�V��4.D��k��(�L��q
s
H���`r[G�>�������B�O���i�fG� ���ln4�mJ�P�I��)��A�SK�c��ef5�|���M�A�x>�B�o�����\
�[j�[p�wI��M���-�s��@��N�_O�؋>��?f������r}S"=�j7K�����	��׽��7�?|χO�]x��MJ���0:	���@l���]@�q���\jE����;��m*�)���)�Ĉ��$����7�E��K���q���?�#7�6d�)R;k.ͦ'��>}����s�$?ߐĻ���!jkS�*�s3m��#΢�`�"F9|<�z�A���D�� s��|���el~��$D�ɎE�M.P��w�/�����/���p�a��6\֯�X�z��~��X��� �OI%O�_�f��~�㓟�[��7��K����$�$hSHc�f�à��� �R�ў��:���T��2����g2V+{5�d��$�^��"�V���;g�ؙc�tiG��RB�qQ�i��PaT��"��X�A�$�)v��&��z�6��KoD�,A��\��q��I�����j�����iӀoL��=R���Q�x-�&H ����O[#��NF��/QMyǔ��X����"���jS�dJh�t*��q�t�%�HgR��Ehaŕ:�J5��� ���ω'���B�s��O�$�Y�#)�øH����N�5|�(_�X��q��N��j!J6�쨳e�mQMZ+j�ب�^J��$z�,;�" �����P�Ŋ�����A�A�s��ޢ~*����HK��'��1�w�G�s�)7��1�Cյ��Roz1s��s�9��n_҄J�M�V=T����e]Q���2CF�?��T�V�j��{D�9�]���{Q��%Dy*�G0�=���:�[���y,v��	�>���W��$����7��!�X��MM֊��,C���*��:f۲T�ҕ�lz��m�TU͵}������H��l�ڏi�e)��YJGWڪg���6eU�=�y�kY���}W��ٚٮa:���:q�N[6:zG�;�.k�tl���:Q�ڙ]���{P�VMC�]�㵉���u\��Z�"BmnAl"��U}S�TM�5��x�<�s-Ǉ�J�3t�Yn`�C���ɆmzDn�rGQ���8�j��6���< ^�زH��߱m�t:�j�ֆ)t;m� ,�ظh競����;���$ʺ��n���hFۅ��a	 Њ��K�-�uO7��������i��꩎j[����]�UE�� �6�lۖ�&^G֜N��M�4t��"{2GQ���܎߱�S�"& c[�]��t��<�r�8C L�4_m񉬷5�U�2̐	i^۳faͬ����+ꫮ��A��m[�-�rd@'[�=ߵ�YP�%񍶢�Sl�� �\��tU��֩�m:�:��b��n�J��:M��p�z������: m	���p��ZD���ھ㸚m���vLŵ�����sGܛv[,�P�G�6>@hۚK�x@t|ہͤ�窰�J�͚@�F�|G���-�f��nǓ}C�]��m��o�ž	��j[��,��C�j� #���F��`���U���ݩhl*�@U#D���/�m���S�df�.챼eitV��芥���
,<Qa�[�U��D�NM�Z�tJ���Q]�R`HmUqd�ݲ��S���E��0t�'�fwtW���j � ^���d�8�ԤVV�ܪ6[� G����8�l�@e�m�f(�
{Ei[.Z�)�' 'a�� ������N�g*�
g�n�&���Z�溪RU�$�/z⃞�i�P;��[���8;��QLױ5�Q����0�~�?'7~BL��RVU���8
�:�E\�`8�\�"��Jg@�;>�ʾI:��p��Yj��cێ�#��)61�̫�gy}T�쇾�wa�]�xSw5$#�b��1mEE�!�`U���JF�+��b��:��a���ڱͶb�'1��T[v�:�v9L�SE���ul�m���'~����ȶ�eK�������x-�&�o�9նt8��m�7մt�Ր8�V���p����X�Ao{* &�_�����V˃]�/��Uټ�F@K��q��<�Q��Ֆ;���p�*�Tȑ��C6�Zqfi?`m���e+���&�8�8�;�U
�w����˚���@��v�.1�x�������a��%��IQKg��?��m ���k{� еoSMؿ�)�V��g
E��#Ě�����>l���p�0�@W[���xg����Ko��u�c��| 0?�<bUJ�g���z���&ėe�S� ����A�m��}�!�v�v�{;5̓!9(F��|`����;p�`ҁ��@~Oq�z�È�������/�m�`��)W��!�a)n��-&�VP�}I	y��n�~Ø���2���At�@���f��x�a����e2в�Xp��k���r���tKӪ��U��7T$[|�TJ�ob�C����,�}�����P�_m�^@��M�E:�'vI�K�"��8�bg2֥��0�"t
_[f�QM���ƌ�,|ߤ�a��^L|��w���D/��5ٽ��b>~�+��;�0.��Q8J�FwMYk*m�B#π_h7�����RK)n�,�&�pB8���a6c�F��.�YP�#�\b�64@ ���o&ZX�@PK��X���5�����.�[��5$���"FՋY�d�Cf�_��؜�-�!Zj�w�����@zE0pL�u�O�̆�|F�sȬ�����/�8����X�YLi=@L�_�KW��~���,���ް&.�sM��q�� 7�/�|�Q�=OP�Z��s(<��0=ǽ��ֻ����ݟ7Y�ѧ��a�/o��Zp��(�aB���f��b=g�Wt3Ha�Xx
0QG�:�B�R`y{L�m ��܄�/�̍Rhy��B�rꬥ��5�,��P�A�b����*���- �'Q�-��m�	4֥�fm�xh1Eujh�YW������^�ͼ�tL��f=��sF*ׂEϕO)����9l�1��$�U��D,Vhs�T�����J��_*<9<H��� �Z��Ie�j���"-m�~��<�1��y'f��#���U0���eG��ϳ@���p��
�I�.�0HT-�r�h�ܭ|�d�;􏞹=`�G����mZ��u��g6��7������'��sH�=���q���'/Z�/�]a�Z~�UZKJ��I�flӗ����cv^B�+�A̲G<�{|�IKC��T��-`�3�_��IiY��h>0���J�N��B���'�����+�%'� �V3ͦ���?�[NKl쿾鄰�xs�!����Q�������Q��R"����U� ��} :ऌ+*F���c��9|�o�a�����L7*7����*lTF�?_^u���%�p�kK��.����fDa2��j�6�T�HM���@�	yj��lX�S�������=��S�k�'����IщMϤ�+%���G�[�t4�m��w�s��!�X�Ϧz�ڐ^o���l?k�Ҽg������l���I�whSjАʾ�����Ɛ�������Rc<���g{2����ލy^>�g;��Gb��7��b76��Y'��!�5��8�O�u�ׁ�|��\�R	r'�&�'�xp%5�/��[����&m��˴n���x3�u�;X���M�_L���
(�Pș[���=IJ
<�:,T T��P�p	�O�
����-+M�(�
��Ψ���|���\!$�3� S,$`�H�:�9-L�8��O�}�"�|j��h$���I�� �RS�|�ш'@7G#�	��m�Ku7�f�j�RK�I�O�)P�75��:1��%Vލ=*��&�xF`rv�s|��������1��}�p�	k����bB���Yc�m�>�s+�dV��%��L>��r,�5�k�cB5_B��pN��4�ݵ=􍵷�y��ݒ��=�~�\nZ����~�P2=�1�&��x�fE,��?шǙ}I-�ъ: 	)EĈ�-����1�0g�Ŝ��XfXC�~���zV�ܮ:�K�N������v02Cv�iw-gE���,m|z�u;�g��2���pU�"���FuQ��˒�ēc�</��?6[3��y��0쮝sԒk�������3�Ս���ռ�����2�T��4P������g%���-���k`�IBu��m�y|��ůq}&IO��\?�gc������=�Z��,j�4Χ��g�Yw�,���t3������Zf�������{!���Fޥ*�����|\�`�����L�enһ�$�`�G��L���S�5Ƞ��t���l�vvR�5�߱_{�o*7�\n��]��e��uS6����T��Ѽ�q��s4��Y�J���o���S����0|�C�qC�?C�t��L��3e���[E�l���ۯ�&�r���H/=������j�W��^q��;��aU�%iƍ��q������_M��j�m,��Qd�*�����������Ӽ�.JK�'�4m�I~9a�K�����a3q�_���A�6�̚?DP�"�Z�R�j�q���c`lh{0�ϢZ�p����3�w�u�d���0���(�9�rT�������-�_`S�M3뷨7Y��R���^����Q�hҰ�b)Ij���/dZ�����KmbbM�TZ&��WbǓ��gk�)�ի��ɔ��'
��K����ʕn�-���[n7=�u�P,��?���_E��	� m�|�u�G�?�����t3O��kc�<���?z��dUV5���V���/� ��dy��O����ρK�s�A�t'<�ߣ��k_��|2�.���0Ȣ�KW�3�L��	$�Gd�WO����-����{�[�z�/{O�����>R`\�H�
rέ��d��N����b�7�z�,7�L�����#��"�,f����zReF�M�(UuK+���
InV.��ʗ�\�L�[
r�e�b�2�[(��{��c��i��ݣ����VYnV
��R,�]��U#�+��FDP ����F���&+r������	�Iqt��7�d�+~͙���uHJL߾$�#�Rs6�b~$|���|�w[aP=/�����t�2 j!�1�x��Dd푑��m�I���̼3�:���������O���I�q������1��gc!�p��9�&�r)��OV#���-�=�X��Y����T5�D�ϲ*������˱|s��1s}?O#��W�����h�1��)���\�oێ������;M�"�{"y�ǹ�r��ғ�v�=�a��>	��+2����/��A@��&�) ?��)�������Jd�$(Rq�����@;O�M�G8�"�{�֙?(m#�ÁDpÃ��!d�u�Sl̅�e�� � nH�j��W���`���
��nh~rA�1�QY���4o��,a�賐��sj�8N }u<!W�Pki���t�Y^��G����#�͔6��B��O[#���J$>�A��·qYf�9^�p��	^��}^(Nv�};ڣ����@nH���~�4��������ΧC�}��w�Չ�ce��p��s�����@i�O['��?�\z�?�p�s����h����ι�~$O��\]]��:�n���7�Z?��d:�{���*F���`���Z}7
3K���<k��nH��Rd�Gh! .g�Q��'�p:8i���xC����
D�+��2��`��E�j�.�;:��E�ܞ�=�>�~V}a� ��h�WpH�'�p sDA�I�����'�d��Q��O�v[��������O?��鏟�3�����#��~�O����������>�}����ŧ��]	�`g�}�����ut�y���y��z���`�������?�#�шi��Q��k�D�ܜ��6�]`��H�x���ey	��`Ƽk\L`O��@G[��n]_fB�y���4lw4�+��G^����nD��;����%^���P^���g�Aҿ��}����k�y��2�� �[��!�x9w��=8�d�,������]5{^gx��dc,��B�'�(.�����.�f)�߅�}��'�~�a �{�����P���O�U���[��畤��O�s�2�t'|�� U��UV��?8T�b���/����}w6 ��7g�c�L���r��`��0���� #��5�=��'�H��d�қ�O�j ���б)���'wCU� ݫ�(b���{�R���#��%�g��ԑ�i8���X�{0%C� <�E���4`MtJc��[���aH�'�('���aDQ
Ec��(��Ҷ�~M��~�.�Z�.E�6-��*���ι��y�{��]��5J�y�[o�㘇����w�n����o�ƈ��T�J�[�+�╇�c�n������ (�^� �O�f
�L�=~Sk�B7��%��`���]R�CW�ڝB�^o����Y�>�9�;�4�fC���'�f���)�{�;x}�a�h��lQ��Ѧu��Dk�Vc�@���/-�GSR����b��EI���۹R��J�����H]
��Gw�]5��`Q��y&{���TBx�e��|�V�q��ャ�[�ܧ�h��_���c����[?�>�֓_�pj�I��C�Y����}�<}�\IJ��F��%Z/��}J`��K�+�z.We�j>Wc�Z]��`g��+��1��G�?���?�G���f����T�b���ߜ���T����c�0��~�L�[e�Wv�<�����7}�R����&^���S_3峆����M�e��ʄR�@�G�`q���j�ÖC]{��A�&]FT�Q7�Z�z
 �\�V�S��J�c���,b$e��.�!����
���<)�Iʸ'}��f.,Ļ:�$��-���v콏�n�������.Q%7��|�$7+���X.�e껬��qf��D��W�:������J��yh���D�6�s?��;��T��+�b�y�+s���<���1��7`Q	��ÜQ�='����4r@�tG�K4��+�;}��!�/�����F����+�Y���$U�������]��A�W�Bƿ�
,��l����E�j�7sE�D��5�N�7$Ɩ,��{\^�ri����l��QO��M��u���[���_C�EQ��������\<��w��>��@t�z-�l���dOn�L��ϡ�Q5�9�A����|�
Y8����c���$c&��f ��o� �2�&.�����4`*�$�������>�a����@����g�+�n�w[���Y���k{���	GË2�0)�0���H6R#xw4�ȫ	t���$=�.q�
��6�����a��O.���zHY�9d������������W�6����լ��[�T����{5I���w�܅�����X?E��w���ѝ�6�,=Ơ ��t�r�]�h̥S:��w{Nj#��Հ�J?0N	��BJ��,ة0�t�Id�%6�<�����Q�ja.>��ϝ�2Xb(�9L�my�>��5P(�HE����ʨ�eԬG�<*��MQ,x�s8s�b׿<ވ��Rٙ�[4d3?8��l��Ix�~��EOq"<���5�.�c�b0�&��	��)lp�b�aur
�K��O��z�Z����'N��{ޫ�~g�|��xj��O^j�$���K:���<��,���?u����1�O���U�����������W�_��=r�O�?e���r�O�=�������{���r�_T T��H3�h���v!`������p�`�5���W�*��w8�������O��Ͱ��Y�n;���w�z�ې���ϕ,��d	����;�%����Az�bn8��o�/�6�@��J�sf�
�0P�ĎC)������V����s(�
ƻ�	v�RVG���Z.����<t� q1�2���dJ��)�a��J�N�Q���}��d#���j���nV��JR��-�ya0�oK�;l�9!��K�9Q1��С���s(��0�ԝC�A~�>V��$�d��X8�+`P)��?���>mI�I?��6���� ���	���N�B��)�>{|�D݀M'��Τߠ���\�����n\ɍN2�p�I�I����$�E����i�ɀHm���u��R�+�����2���Y�dI�憗�B&��u 2)���C���{2������Wu�V�fYf�����g��.JB��l1�-�~{a�`��_�",�u@�=J���{�u��J��l���a��l�6f
`���Y���#��v��Hs�m�c����i�V���K�X�
 �#���|̎5�������M�t>�i:-�"\�}So�7�廫Y�7Xo��9�w�m\�Tnk�*+��e���Պ���y���V��,�{����T���W����]�������Po��[m�V�(���<��9�\�����3��LM�d��d���V��unY���&�ލ��E���0�������x�����e𬦢6e�������wV�����3{��pt�ZS��L�0B��F��Γ�?5��y��t4u�V��mH�|m�����>�x��.�))�z�	�1^�\ �+К�J�U�Z��ҟ$�/j���$�A���_�É�@-YV�/��Q4J�_W����Y}z!;o8�]7V� ,�Э��H_I�z� ���x�Zc�N�.�~�S��Za2�+?L�y�8.@V�]��s��f�X�$Y�bi>�Y�w�������J�OYsJ�Ai@UN>��b�r(}`9��x�B��S-��z�=��d��9aղ���b����y��"�Ծ����YT+����<-���ڧ��Ӭ�������q�ES��O��s%��������U�?������]��ۗ����Gn���������)Q�)/:�6�Z���Y�O�3�.r���2��
Ȃ�U���W�*��w8/���߀�7��
�(1�q��9*(��ߐ2H%�]+�M*!�(�,������󙡂^:�������ӄΉ{���>��L�+oA]�BQ�#�e�t���Z9�OU�c���x�/_Y �"�|tG��� `'n�K�(�E�l:��6w0s��͉n7��G��{��Y���*���*�%�2�_d�������u<f�^#�f���H0�y��l3���S��h�] 4���	0�\�)���i��g�g����F⫸9k�/���=j�o;��fV�A���1$��IF���Ù�45���A7��djk�럠~��6~B��90`���(t�Q�g��xn��@���#�H�� B�|���81�����p�a�.Ǖ�{�q�nH����2=�1�)��3�	6'B�](��J��A=r�8�ߛ:�f�A��GF� ڣ_���ץ�)��7�+@�$T��
�ͭ��v���(-5�r��FDGT�D�'�+��$Eu�<���nԟ�a; 1���XW�j���ME��l*M�ٖ���X�9�� I��l���6����W�� <J'����OoEb��X����9Px��G����q��ӂ͟ [��4���~���f /��ğ}�3�|�Ig~)�B[�A��2w��/�~/	`��/]���(�eV��*R��B>�A��,$��o 	��G��E���|�\���\�]����_=�������뱫>��|Ƒ\��额�c����6F�k��򔵰�6#�v@����m�@�i,�'�(��n�6m�Q�/���K��]�Ec������{�^�����ܘ��3)u�uH{�O<5X�r��,涥 ��P�b')/ H��/m��4ֹwc-$�������N
K�s}�rY����wo��i�qM�:Ol7��ڈ��ڣ�F�O/����VذG�{C_�g�3��T�g��6�}2%ŹcG�8�L�H���p�����.�!B�<�[�E&���=��+t��1��Qz��(�����T���r@� �� o�E��F��O���a���:	��4����9*��� � ��4�7�Y<Ğ5�GF�P,{{(րlX�e�xm���x�7�0 ,���0u
-7&�S8�@��N��f�u���h>J� <�0ug�:���
��Q�,l���$�'�y�>ēx�"}��X7�v7��W�3|�HB�І�@�=�K���(30,�ɠ�t�SP�_��� <����;B�i��h���
glZ ��11t�LV����a~�����0��W��I~t$]���1p�����׭�x��&����Mn�?��8.���Sv���$�Q
�Z�dyim,��Q-+��n0�_��)ju���T�|&���T�s/ٙRNjc^�Q�F7�;��`�چ{Ԫ;o�AjD��1������s�t3j��&��M-!���AF�н��V]Sк�bzk���;�9n8�^0py��T�QN����<FxS�ҿ�v-���_�5䷵/��Γ,�)G��w�mo�6�1H�vP�¨A�ۭ����nzgQi�K��v-�i'��@��n�q�"��@�����ĝ�_�5=�M˂�߰�:�W��F-9ͬ������?r.`��M�qN���Nǔ4���g���|�L<�O���}57j.˧@�����\�%ј��_�3�OA�& �_E�俊�W�����o�ϒ���l֟��_�U���T��M���-�������Q�o�no���:��N?(�^&$v�%���Hb$_
}j 9��<�h.q а,)�%��鑀����@E� �N�F,�~��'5���Nl@��{"}O��w��?+��Όgab��;�����'�y]]���ucݼ�<��o���?��:�Ÿ��L���)z9wb8���h&���T�U����`~��{����������3S�_�MSG���U���$=���� `_�'k0>rC�A�k��</)ٱT`'g��˝�l5�"Ϩ4�"��. �I��{o��nTf�`��%��̍G���b�#�`^�,f��9	�ϖڐu��zo�u2N5m&�*׭��Ӟ�hJ��'؃Tj]LB�(`��P�
u��K�F����\ijGF�e��7rߣ�J�xv٥�4��FC�Ň���*4�}�P��fI��S���TE���#�N�7o���5�z�P�3;�ڣk�G��b�����Ò���+Q���������6a�u18 �#���}��8�$�'�MfSY��c2)fJ�_8���v|9&�hD��PUmekop��_�l�t�wg�k;��K�o�[�����?���
�㒲��"�ŏ�g$��=�v5Y�A3�gO��i<��]@8X���a������dN�a̜��Jg�x�.�g�Q<�:����.�
��?vA�wW���EH�������:��eT��+I���p����Gz��w��6�?1����Q6�~�~�F�P�(��\�t��G�F�X�W�<�����)�[�dʈ�@d³��]}42h�`]H��تK���g$M��M��7�an��L0�A�ZtNG��1��R@Pў\B�x-��DM5����q 6�|]�V�����Vt"�AfYj�K��x"6Y��'$�l�I�8���7X:�-��s{8�
-�q��]��D�������������y�{�R+uF�P�Qt��	-xp����C/���E�v�����đ�d+F8K��,����2��N�e2�0�k
J�moo� C@����t��ӛ����q�BK=��>
]K]���_ҙV�:�x��w�ɸ���x1LVP\�btf�Ob�l�y#raO����	�;���-�����M��9x� ��ر�h�&�-%��MP��P�5���Z����cD������?,n*P�!m��F0B	��%83J�p\y�p<��JI�Z���������?'��I4^b�Y���Z�fj&��5+�%闝�7��;�֎H4��������qRWi���_�����n�Z��l�;�=�G��!��^���f��?1�;D]�-M�J����%��4-������t˔����j��"U�^�̢�VN���i��8�i��vD�����㡼D�w��pTz���4���P�K|��h}�%��i,�ߦ���?���2o��-(�I��e��X{�k����G���hJ��Y��r�S�k��x���%�R�񫴖�t��.|��/��[��Μ�g^ �!{ĳ��6��ܤ��Sl� r�d�%�=)-+��&�Y��ɺ\�]�Ԣ>&�px��DL�x�Nd�4�N����n9d,�u�����V��͆,\l��˛�|�Q��R"������9 X�Y ����J&R4&W@�l�%��ه����2ݨ�Hyo�5�ݨ�����џJ��@	֖Jy�p;�-R�n�'�6)�ԩa�/��	�������$�k��?v�MIء�*������g�z�Rc�pׯ�^1r��ki��������#��.R���	=�-��ʕ�-4[
rs�pG͖�\(�������hn�t����K�M��R��2�"�gۙ;�Ţ�Ң�B�ԥ$(�����6 1��h��\vU��{��|Au�2'Y0U{[@���@��nI#�m�H����i�fw?xR�%l7���=�ô@9'�>a F�$͊XV�hċ�x�:�w�F <]Z&Ö�p�ۀ������zd�N���v�	�u�'d|; B��Jt;̎�	�b�|v�·9�A��N:U��t��b�"Ŵ��9�Q���������Q#�*T�)�da����	3�9	{MϾng�����̞\&��"اB���27^4��e1w��:�wY8�g	�����kƟcq09���gmy*��Ut��gb�,����6��B�����W�?�H� ���&�Úw/�x����S��_��U�o*�����Ү��U��������i��_I����_�������m�MQ��^�m��n���$=�b��^/HK��dz��b2$r��1�9�A�^���������ah����T��*�SJ�ّB�<#���A@�I�WY���桄Q�1O��zi��2���4�`�B�����!�Q�ۨE
�ץ�]�g���#%�p�ߵ_{�o���������w{����������������H�/�������rv� E)�i�G������N������=\���fe�?����Դ��_E�����=����>@n�$�;2)z O��*�3[��c=�G�nk���l���G9v����Z����A�����+~��,�"^�<�������o���9d�N7Z@�>y�Jd��b��z�#H��4�+f�A�����[�g��u�q��ȡ�w�J�p>��<�"�̻�����2��a��&f,��Xt��XE�?K�+��+IO�g�ކ�ly�o�:(�v�R(��{%�l8�-z  `��c���ɱ�b��+�c)��ʂ?��7�^ %�/s�E��q:(���m��ݭy�H�ۅ�����G8�<wCJ3kB�o�����/pl1�nХ'r�^ۅ��l�BK�h+b�8�$�|HB8��Bf�o�k�*U�JU�R��T�*U���?�Ʋ � 