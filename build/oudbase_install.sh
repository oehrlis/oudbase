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
� 0�Z �}]sI���������s��Ź���h|�k�3�.D@���J�9I�kM�G@7��A�#q�����7���S�\��^���U�]� H��4�����ʪ�������<��ң{N�rykc�ѿ���ru��+��U�+����f��+����Gl��i��M�]kl>�v~>��G����`��Q���|���C�ǿ��c�_�n����7`���*[�X�ڒH?��_�E	I���{�V�]h���m�8s�'�}avl�՟���#�v,�g���Á�여5]/`�O��i�V��,�<��-V�z�}U٨��}3μQ���Z�v���M�3�F���i�i>�GA����V`��;�z^�fˮ��O����&0�� J7;v�^�3�`�g:]��􊣿aQ�j���[�o�N"��������[�S��j{�0`�˺�ӳ��@ל��x��3�
Fk�1��/[s҃q�9�50m��F��a��,���\���v�Q������jC`� �ۥRr��;%�1Y��5�a��\�j����Q-W6c�Q�u��6�������R5*̳%��;? B1Z�3�sϑR���=L�"ہJ݁��@��=g���v��qz|xxr�8�-~P���y ���S�p�n���t:�ǻ�#G�0GF���4�#˿C�r/�ǭ�Ã�f�qX?:j4j����<�2- �g}���.;��9Z�X ���V��V�k���LA6����9�=:9=��7k��H���X.�N��N��͝����k�R0����=�}�Ấ7��I�����f��<���	ٓ	Cö�A���-�����4g��J>�_�ݫ7��V�4��3aB�^�y||x\+�T���Hrp�FN��.����v���v��ٵ��C��6l�7�x�׎�R!5�j��~��w��m^�j|�_{+��[�ݻ@;�'��`߂�i����#�헮�y����M���b/�ةr���0���2�_�O�)Ž����~Gˏg�v��R ��Q��{����N�a{V	�o:�/\*��6���d�N&x�_����]bO���;|������kxY�f�n����7��;9�͝�e:u��#;��?T��Շ�V�q���eF����un�k]�����yT`H`�k�֗���݃�'�HVo�\�!%�u�w�ֻ���tٙ�t8n�����Įt@�  3�96�dQ?�����2X��1���;��o�������������A�q���wۏ����o�Q�gu&��Jߢ���a�Z����a��2)I�|�̀<-hH��yVcB�O�U���R힋��6�$ʳ��e����ǰ�6�ƃ	����?��}�O�=���j���^jk�ժ�iϢf�^N�]jǃӲ*=M���:V�7�p؞<I��g���FN�����!�T�X�uS6���܃p4i�K��K� ;��ᚋ�Vڄ������8*doB7�H1�`�`K�e��9$��^w�[d�`-�\#Z֐��]��g�UT��Bf˸����1�*��� $���4�>.g��<�?�fP<�w���ts��ފ!=�V*F��V@����i�Qz��S�L�������v����_�o ���f��w�@%C6R�6��-V�&ߜ�CǬ�Z~}b�����9�"��{Ë��z#�A�E���``::��-�u|EDO��6	���$Y%�l�����E#�DC5PSP��X�%~��[�׶� ������"�ЈmcJ|�D;Vp��:��
hm�T���#c~�b�K�T��>U4@&n;�s�7YJ����۩��d������g���6M=��p�9�û�!�1�T�\'��ަck�^�Xm�@��|X4N�����Ա.JΨ�Wd|�ΜP�>���+C�&���>��i �@��a�rqc�]��"�q�E[8��1[��%0o��J�tڶ�Z	���6c���Pq�|Zq���>~�/�`�N��@��Jjú�)8�Ev�`����m���Hz�P�[��:��98A�b?'��9!ˡB~�I���t7`��s|���A�*��k�D����8L�,����Ǵ��pDt�T�
��i�;�8�8�τd9�}Ӿ��[���3�,�ul��ǽt.'�`]ѝ'����:�bj7��G U9�NS�/\���ֵwd��z.N?\��j�GM�!@��w�Ҭwao7��nn{(��.��U��䚹��t/
1yX�f���J�H��G����Z��|\�����CU�e��
�y���S?A%~�U͂N��P~-;[e�+�BA{��[��C���q1Ħ�X�F�u7gh��̶�/��z�%�lQ-�{�����f�z��_C]=*��� ,Ğ;�G��0�H��K� �P�$�I_�ư�h3SNz��;��D���E��t]`�8��B�E���|���:�B���� ,~8z���h��X"��ǭB�k���`L�9R0.����9�E~l[<�l��
�8n�`��#�Z^`[>�^qEi@��k�O,���1�@�Q?щj*
�n�ߜ��+ZvA#�8�I�g6;�������gm����X*��T:�R?��8=5�� /�mp��`��!� ��C�t�@��G���ы����7N����΀�P?�D�m`jJ���#�i��[,�Õ��]��	����r�К6[JdG�VG�� �2v�-��N*�tV��[b�ے	��YOl�LT?�X�26n���#��.�:f8[I�������ߝ����y��-=m>�=�pܪ��8�7�CzF?���>?8<n���P�|�74�<���?��ꝎcPB��X�Wo�]�Z��<)�Щ��5��ɻ�N�v��hKB��gj�6�Bq^�Y0:��,?y���T!,Iq^_��?KCj�������3��!! �RfT��&��0c5��2"8�u���BK-;q�"}���!�����d�bfg`;S,cɵ+u�2�0�KYÚ���Ũ�W��O�.��1b�?*S��v�A�׬��]KZ�b����*��8$�oTS��f^t�Q�H��M���Y�����SO����p}�ߵ�2��¯��j�L�������!��������b�+�@MX$��D�?u�߯���L+k�xng���B��V�>���	�>%����O�x���76~Pޟ�	���X#)���7a*�z��2��jz�ݻ��No��l�p6$6����(��^Xzߴ�L��Ӌ�md�F��md�6�ln#;�����
����c�rC�g.|s�	�綪7�U��称*������� k��em�_� ��@msӾ;P팍� ��-������Do�mo7�L�!l�ZfuȨh����'�~Dխ_z�Zz�J�½����~�'o�%�^llSX�`R}E���C���<KՋ�
Ɣ0�*�<��C���[`m��ݬ����b���΃���J�'���dE)	�{�-<��Gl�Kѕ���Q -���]H�E���h7�KB�xB
!�MJ�3�<����\,�-m�O�ץ�6�9�Z4�H����HY2Vb5%�ox��Q�b�&ƀ�o�ʛқe���[a�,��TJK��k�&*�x�DZ;��xVxi^��ȷƑ�(Afp�d�#�C�A������
��{�&�c];��� ������5�}��z���X���M�p�%���w�\4��O�8�Cb��R8Â���,�6⠋ ?��l�� �Z��#��t��W����uG|�'�?6P�r[n��J�}��3,����Pi4\e�;�ږ*��*�*U���u)/�@�{���	הh�}/Yq(�Z~OFI��c]/�5+����[���W�|ʂ�[c/��x(� �,�4+��b|l��ޱ���v����V��A�^z�z��o:�߾]*$8� ���kfAW9�>��O=�^m��7l
�U.�,���W��K	��n��O]�Ƨ�\�G�;$���r0�Oæ]s�^�=�>��)�!�9n��:���s��_GY_l�v�Kb�߁�\,�\?�NЍ|��bn*�f�m��{̇M�b�B46���Jh̗~�x��%�4-~a!א�`�3��i�����3S-����+�Lj?C�AIDź'$�{�i	G�g���%.�F6w�D��>PG�� yϊ>iU����x�y�4��mA�<P I`ry�~��R��C��<{اǋ?j�����W �8�߳:q�{4��+VǽtVA��ݿ�a֝�����f��1�D��^�"�D|��`鐴3��҇Ɯw,����rY��'��.L�bz�ؘ
rFb���
a6���󡓴�D"?������Zh�YY�B��������!�������b��;����4��	��_�--Ͼ���}Ģ�u�)B�u�I��Ʒ�g?z?7(͂�e�����]�A�JO�?���ۛ�C�Sr̞r�tr5�r�k6�j�7�#��g0!�{�,�M�w�5����`-_,��S��_����g}�;����-h�-��Oߖ6�h���p�������qs�ypRߛ��ނj?+�ܹ�ڹM.�1�ɝ���mr���M�T&�s�ܹQ��r�l�4ʝӎ77���~Qƴ��������`�yf�lHM�j��F��tk9�Mf�[�έF�`�Qq<7��(��/�8�K?�9��
>]`q�.pu6��W�O�$���"��>�1G}�m��\Z�;�*>w�|u��������sy�/����D�����P��O�;�{qt�j��JO�R(ĴR�1n%� ��a�
GMH)�Q#�g$���/���'ãYXG^W��
�j	�ޥ��0���n���Z"��KX$�x�0;;�x�(��Ht�m�%�Qf�j�@
�fU�V�n|z��^DEi�����ɛ01����0S�a��]���E)��4���j*���Nl��������h�h�@P;V2j7+��>�G%���4��|��sx��=�����I'�� ܿA��Eg�9�iB]{�	7�Q�Z�ls���3�UG�k�G��3���4|)8�����N�Ӱ,,��b��[g[?M��70*�ʠX�rk�����	�6�vy
{ᘸ].��i�P��t1LK>s��ׁ�c(k�2�b)���b��$��.�P8�U���.)�i2IҌ����>3c'��dw��U�p�@�_��FR@Jit!�`G������h�����S��~�	���P�z/u���.��˛h��^���D��remsmkn�� �/��/���G�f����%k�w��
�T��?�x��7����1�E%����,�F���G���p����7� �q/�p�0�-�����c����p�p���n���xV�����byц��o�:���G����s������=�[yB�<�Q��?�7�+�r|��W����!���ǧ��Z��w?�r�n��=K<�nn�É�o���-�r�Hv�C�O
!l � ��i�m���A(g�m����"�k�է�5!?���
��#X�GD���l4���A<BkYΘl�/�m}��.�J�V�ؕ�@6،�(�����^_�!�f�����c^?�h>����x,~����͍<���Z��U2���K;���Z5���N}O�G��<GǇ�;'j�!]7
8���WD���e�jT���f�����k���f�}^��tJG8q�*�H�<�#������D�"��rHL����K��`��H։g��h���m�~��K��"�$��.YA��q�L�R�E�}gmyʦ�A��v�&6+��Y���Gy�|�T��t"��kH���BdT�� �c;�>"<?��6�+1d�|P�E�A��^������q�M��0+��)�&O�`m��b�N���:�$��Ю/a��H���T���Z�b�Z�>��
囻V�1����_�e���V��yar��܍��\�k�7wN��?�Ad�!��i/�9�p�'R16��q֦�ApŞ�B�ON�G�&����Fo��6�;�;��Q3J���_�4��?I%���[r�� ��d��wcL�Mi��o2,�y�<+y���
�y!3�-?�J�-�h�Ҫv��3�g���
fFG#�+��\n����wh�tn{~�Ж�	/mX;<�ہ+H��V�H1�խ��f���?׊qK�.ʕ<T�=sD���g�Hٰ����M���\�ш��"�(�H>���JV�/�~5��QK
!!&����k<4���8��v("�H��O�N�)alT3����rrQH�䍝�:Ri��!��8�ܼ���V2���c����Դ��*��|,�`y����њe�f8~��=�Z6�dMn:W:i�D�N1Ss�|� '!�Ś�l�el�]�*�[b�ڹ�#�$�3��3[N�
�$(E�8ʡ|*���X��.R�J!m��=	'�L(0��R,zctwc�ˢ����m�l�4F�uof��i��>��g�0rq��E&N�iܖ0�W�F�S�F=�<`sO�	�x�r�YVxu4�4Ytp탼�
w�b���GW%BLTҺ�Ҙ1݋����
��o$дUY�X!���-��էFxA-FD��q�=9�o�-R̙ dH��~|�{M� �Q	��x�/�,g�/�v�K�E����&�����^X�z��pZ1��Q-��K�p���f<���VV[)	Ƹ8�«7�����t����S�9��"�$�Ք����n�$�K�7_0:�k n�D
O�E��-�[���a%����¸��� \�l��SRN��9��*G���7�f�Ӂ�E�n�#ފGz��v°0��w������Di>�,�w� 0��H�6��g��:�}�Q?bG�I�Rz�M���󊬧��^"{��]S���5Q�X1r�d���Q<�,��>|hy4L2c��2���F�t�s�!�������խ���Tѕ i�b���cZ��l�]�����9ʍ.�a�������E����}�!s)V����Uu@89nl-���f6ț��%�v@���s���z�������=.V���&�\ǿ}�ߓ25>d[���\�9=�b%ȄX��"���Dׅ|�Ni�V�%���)D°z1���)���^�7�Ø�M���<"��`d��r��͋�m�(.�\�J��&�$��Mһ��w)/�D�)��ڣ�*%���8Е�?t��W"�H� ��DO"]m1�v¥^/1%#�W���]�d�v��i�eݎP$�̋�Q�r��č@��~�u���?�?�;�[����/�Jvп"��R(�:B�C��o�چę�N�:�&��Hox\8��E�U؋�CSN\.k}SV���`���zl�CI��1mÈI�P�Xt�R�61�� sO�0�ub����K�%قP>����y��
[ˡ�&BHB}�&�ɚu�J�����,k��Vc랫��V���l�X�!GR� Ss�+w�񹖮�X�<	g(��,���O��}E:������B�� 
��:$EpV򋜐������y8A�b.��\���K#�A���_}���=�Oʧ��e�zE)�]$����"Us��k/2TJ���"Uw1{,>��6���S�O�p�3�G<���KX��bB�r��3w�b�`_&�rV�O��D��f�R�`���M��6��vH��
n������%��mZi��t���M;9��ͨ�O�d�9y���Uv=�����NP(��eU�o��L\�5ɭ��sR��m���u}�����}4���|�j@A��"���B:!D����B�����|��d����ǲk*%%��~e"�8�Y��X~i}�|ˮZëٕ��%��m��|_\�bK�rZWj��-^��b���1Ed��ER;�ߤ�Ki"��8��	-dJV21���O+ l36�O��75;�ײ��@F���m�o��V 'E���_;� �M1��'..�H�"���3|:��M�R�,1j��Uo��w��^T�;���6\�Pjċ�Z�nO+�_N(,�d�_��5"]b���K�	- �{s��C�܇&��aߎ�9t���v�I�쐿&�2�RE5*3��HSTd6ʻ��۷,&y��v�L�O�E�
a[�/+���R���/+d]Ģ=%�V"3�L�c��2�R 0��қji)���O���vO�TF�q�R��m���T�S>�������KډŽ���%yb�[��Lσ�e�ɛ�}�[��P���2����{|�F��+��;��@3�L�d�M����l�g���5�z������Tԝ��Hy]�E{'�%�P�._S�hE�V�B+:4·��1�+�е֜Xs�kP�Ќ����s̬��wy��|ǽ�|ǖ�c�W��~-,F�E����m���q��ڽU6�L9�@���M[�6��@^�.�]c 3��My��Y�M)���	y�p#z�.-����^���҂��o����~�{����	���G��QJ�Ol�%�U��6�T���)�W��G)���+��됯hm�$/ø��z�d;D#J!C�	p6j� M@4��60��e�ӁpPVE�V8
��N�u�J����.M�#�l<��v��a��Ɠ�~���t(��E�����9��j����A�,�D#�c!�f6�L���� ���d= �}!���{	0;�骻{y�1��y��HY>:��,��� ���4��#3Wtq#lǺ�$�,�܇�+�i��x��Ҷ���K���Vr��T?
�[�L(�+$O�&��#���	�6�XM(:s��4�vy�7�'Š$�<Z9�.m'a�ka̼BS���8,5� UZ�+��("hJ�$���M��+�qx8�Y'A٧NY�A����)�Y�F:~�J����j^Rr���]��hB���D�V��,ugMY���@��u�	=���V��5k��H�������
�������6���ua�"A}����g��n(Q\�����D\V�U����r�
b��e�I��d��Y����*N�xWG�@�"�ѳ/��e�L��gf}�1C^�Ih����+0ۏ���0f�����������7��/�����eY�C��Y��~&�(T��]Yt�((/1N���t#6�R�;5�8�T��'�ᓛ��?����.�)�p=�.�zt�&�rέ03��vk�|�q��?{6%P��n�����ʐ�&�lg;�Q|T��z!߹Í�o��v��	+D����0��@�����@�FK͇~_���XѤ;�&kR���C�*��A����~0:�#<��Wd��=\0M~h��cJ�������ES3�sW<cړ}$��,��F:��r�\Ȃ�m�n`3�ˁ�Z��2u32ֱ�I-�C��/Q�L4$	&���ݤ�*�Up:���� �V�ѫ�3E�����23�G��;�k=l$]ҵ��+�D��D4 Q"a����E�����,�O��x�n������1��?�ˮ�U˕��V�Ra𣺾��m�k�D����n[�;aT/�����㿶>��I�}������^�ت�7�0������?H��?n��Mcй�: ���Y㿶����V^��y��@:G
��U E#�%��-��7���/���n ZvL�c�(�Eكa���/�� G������%�|&wj��Fwe��m�1��9�|��������n�w�X��@����W��{�Vr��Y{�����D�Sw`� ������/���;b�����?@	�qrw(�&��@~,��T�_�����Ć�}G�zO��<t�5�]r��� ʟ[ �{��ƆD��g�����W�q}g�2=�������e�n����WV�3������*����t���V$Ѭ`qhw��/F�0���1.VVZV	�B�>3y��v6r�d3'���������Qq@(�>R�l�D֫!�)4AJ-i��}�C2�DS%x5���q*�Q=�=�l�2_zvX��)�t��`F>*{�3z�^�����*lc��*`��v,~,pl��3˃�٘����M������R+�ݣ���+̾�b�\犻���Q����y�*G��p��|��I��o����q=��ulE?����0�{�0���*��s�`@��! �������'
@Ïz~��Tb�q�����[V�+%�s�SJVƊ��(V*���ie}�����W��������=g)E�_
FR6*��,h"L�p��N����W��ov�մ��.�.���g�[�œ�l,<%찄v���o�=|���zGqF���؊&���'��-�e�~��Va��lp�C���̅�;p;�$h1���ԫ.�����q�#�cz��'�fLU�����\��;:#��W�\�#�E���,��ʡ3�1���]��UA�dҫ��Y��:�.(y,�;�0r_��������Wwމ��"�Mą�I��sDD��:��η��?~�#�����jL��j�[��:��ɕ�L����fT��I�6�8q��q�	��}:ѕv�ӷp�'�}��=�s��Nn3�1_�Q:,��ܮ�4[�M�(`���P������ㄏ_T�i@���ʊ`L4��L�Ҝ�d����P��^zW��,�1�wV����k-�j7���q+k��N��3u�᫩�JK�&,��)�@�(��B��-��S%�\Eb0�'^u�W�r�X�<���7ַ�7�G*F�(K�d&��@~�,����p'cK�����`D��%>��7��O!鱐�n��Z�A�RM7�v����P<�qe�n'�/�'
|0	XVC&���dى���E����I��To5��S�_ȱ�ҜOCA"�O&�Ed�i@�w�3A���d� �nR�pڝq�{ͨ�C�]���(�V6�c!������ i,R�k��,%���b;��*TX(!�X䶌b��d���կ�fwz�IS1�T�ܢ�ɳ)���(��t`b��}O����/d���񵋂�w����I"*ڲ����& ��R��d�M��&��h;AB$�1~s"ֳ8��))�p����X+΋sڹaOr�QB�D��.*/�ϪU�|M�w���r}����YY�¼)�O��>S���60���1Pl<�#Gs
 ����� ��S��0 _k�^e@�%[���_�}t��ț�ݶb�%���a� �U�<��_`��lMK��<C��yYK���a�0��ՙ~F�dA���y���Y*�l!)I`��I�M�����p[$�,ǚz;h��{3����#�������F�a�a����;J�ۨ��Y0�iC�e�ዙ��  _yMD�4D�'r������taB�ג�M�ɝ�=��P�/�a߅�6N�H񹆗-�D���;0�Y�ǳ�+t F�Z�n/��q&!5h��/��<r1>� n?���<�p�$��vPs�s)}��!r�u�`�żz ]�S�U�J�Y軅���U��2V�UAq�i�cS�7<��\9�ؕSO�e���,�����fɤ�t�[��2B\׽v�,:S��^�z�y���.<�t�w\��WoT�\	�Xx�:�Gt Ja�=\ǥj���0���x���؁�G��3iT��,nKj����ԓ�U��j�Z�p} |��T�84c�gmo�.V�K<Waa��l!W��0��}�_�}~�<�¾ ����5B&.$��B�1�0��W�,��Mǎ�\dh�R��*�u}�K�N�F�F��!��g$М��g�)��%ԥ01<F.��@�X��g-�_@��Z�1�3F�[�H�/t+���&��9�O}�ϸ�v��/\��+a��Q�����6E��g�AۮXϣX�zK�d�B��6���0>�x�#'09��׫�H��FOhd�]�Df'����D���!>��E
s��3��^.��ރ���m>4e��9@N9.ѱ��ۛ�E���3���1؞o=�ȿ*!qUC��0����7K"L�C���1k���9�Ǭ��wO��ؾ21��Oڌ:���Mw6��zϚ�L�*J���B�KG���{�� ��3��(�i��5����@"-���H�@�@b*�}K�mI5#�3�\�o e0c�X!A�����v�=pJ3?�E����(��ry5ZB��:���,M�X���Zy\L���wy|U�e�.I
\��le�9ҳ���ƵUw
U3z��I�g��K0z<����SbY�̘�ܥ.zlL֛e��j�y�-�;�Y���Gn��N9A�'���ؼ�3)�)���]�V��"Oy�v\3I�Ra��Kea��:��c����d�R� �JbW5Ւ*�⒥ˤBD�:��	�<Cr7����#4��L,+M���	���7=�HYx7�!Wu�Y����u�j���9}���Y��ũL�;��g'j�����[
�&ʴ��b��0�שg��t�ܕ��ٽVt�ra�U�N��j������Y]N
���Q{[�[���Jh"t*� Y�UG)��T�<d�J��U ��+�j�z��J1�^UvJ�
��Ī �ͥ��V�
�M+�G�B�*�����3"~4D�hL��}��)"�4Oͮ.A�P!�Ћ (�R��)� ����_D�m�ꃒO���oB�qj��N���ce~�9S�&T!�ӌ���u�VW���d�2Vm�-�1�	��u��0n��b(d	e��q�_�=H���ن[�D�oׂ��Q���q�$e�qSA	=I!��=N=~
	��vJ�����q����(kQ�>�5W�s%3	�P��d���e�Wޟ\9prE�s���6-/�J(�Y�-�>�c�����wg�E{��}o�l�����
bb�!�3"���\c�! 
3� /��y��50��f���X�������S�r�y-P'���|h#.=�=��OQJ�Q�V�muBhިi!�x8�4@�Nm2�X��4pqM�d���i@C]�8`b�0'�g��Yļ��q�h;�܇�)?C\c�w��YQO�s� E�=�::�����c*"4Վʻ�i������ �ORș�>��5-T�`��5��m��r]�?m�"�p���#nS�5�:)��m��/|K�Nz6��Q%֤nA�)0�4Qe���~���>���N���m�L��2@�)�r�v�`��t0ŽBw(���o`�6h��F���w����'�f�*�kqA/��]p7�JF�� ���E@~�%��.TQ|'�xa����;k����s���5I��)<<�R��$Z#f�H-a�-{��a*
՘��\*���/$�Y�4D�0���|G��jvqn�/�*�u�K+�Ţd�u�T�r�5�"�"��B���}TZE�8���5�5DS��z���h�/섈T��l���;�P�����9)���U:6��Jy�Z�Y�|���-�IT��V�Z,��`�o�J�P�K� σ�CKK q��"��K��\n��nJSO�:�� p��׷C���Z����l`sG����KP�@�۳�x0��	J���W6r�
T}K�%3�2y��j���;�r��3:�7a@�Wr�Ef�[l�����0	��zݒ��/���4Z�" }��������	����T7��*��ج��<DJ3��u�����6+��Gy��㿾��1���i�d<���Ѧ[��J mq���g6tSR�ʞ�*
�j�i��%k�5i�i�U�2-�ꢯ����~�ʾvÞ�� 8�F��*k�����둙7O�	��^ Έ��:G�4-Gl���:�;�/Q�	pق�͎���L?��vO��4���Hɀx�c���u*�E~�ٴ�Wtj',n�}2v�@�5*FBd�G�]+�N��`����`�aq?	��"�'��F;��mx�|m���j��	r'029�]���y��T���О�$�=�8P?K�W"{�ND�:�@Є�4�;�"�T<��?��������K�u��td1N�B�Ly=_3�5x�'R�/	B�P�샹��FǑL�Ԍz ��]�O��;��hw��~�{x`@�u�������ʘ��*�]i*��5��v��F0� 
L�1��4(���`H��[�r��_���˟J�4uLj���|��ꙌU�L�).�)���� ��Dş�
Z��y+�X��%��xx�F�W�5y�X5���ucu�v}x��<�&n��P*l�4Ƃ�[���� t\�e:W���4�Y�I��[�x0f�M�M��O�j��#M�n�`�� ����b�W�_[��[���Ϲ�� �/��/���G�f����%7�w��
�T�ϟ�>���@�ON��O,�?��_ǲ�Y��oAr0��e�A�D{���p������m�����;�s�RS�2��1a�omT�b�mk>�&�����4 _� K�e+ �+u�ĵby�N,��(�,�����<��U�IM���;A��렡��ZC����q�O��D��2-�(T�qG6?7��Ε������^��7\��hUjKoF�y��~sYb�c!,޲%����ŢE_�x�3�+�pVSn�F��Zp�ij��R��)��Q|"�.��Kͫd�gC��(�{59�"3�I8�@&P��� ^ˍh�����K�����p��"����麬h�������k�%�� �ߓ�K aH��-��vh[��C�G��U��|�=ċNE�'�0"��ԊMZΊ�_�X[��EbѰf8K��E������ȍth�G1$C<�G�qs\%����sМ@�|�����r� K�x�Q���L=�I����>}ͫ!�|����.-N�d.x���ٕ̅��ra6��֩X��~f�p�(���s�	�����F$�l�e�=��NͪeRP��k�am)��t{��ST~�/�@B�T�����=�r���0�`m�Hn��LFm	?t������]�f�7̐�,��q ��_��U4�/��X\!�$4prX�扨%d"!bh_EA���xb(qC���u��d����� (FZ�f0"2	��vkKv"�X`���"C,N��(F�h�U[�L��Eiƈ��$>��M��+C�)g�4X��Ԣ���ˋ��`�����Rm�?|���Gh����d�:>��Д���Q�)���"	8/v��f�B(���O
X+�Y\�?㻳��h�U��j�6�:����U�֪�묌���_&}��_G����w���yJM��g[Ǆ�_��J��5������O���\��$�����mp\�^����o߄/]<�z�ө�[�8������q�M=�K)����N�������1�����8�-�W׷�0���Ve��?D����
�Ux����<�]��*>���#���rMy�
߮��u�r˷��M��61�H����x�s�b�F���j6�����-�t.���]Y���������:���G�����g��]�϶�I��Ɔr�����7����I�����G<���*�g� I��7@�6`�������ޟ���;�<|6����g%��r�u����b��V�R���������0|�}�q���ؚ��C�(N���1����m��������|�?H�E}��:n>�׶*���?D���Oӏ�Fuk��cc>�$%"��C7���
d>��2�Tʹ��x�_����k���͍*�?���s��C����z��a(
���Coq2�؟8�x�0�_�K�����d��"P�<Ɓ���9�s����w�E�{{�\����xA�}����9�ڗl0�~���)�~�?���v�u�|��U`s��?DJ/��:n���*��WE�o���4)x�,� �������W�O��o��s��I�:3���:��ވ���������Oy&?���k��Y�V:~KޖQ�����k����U"���n%5�5(2H�5��T��暍��e�+��h����n��)����ź6���c=~�J�vxˎ����^Gx��K<>5R��a�Јz7��r�����;�45���� J5(e��F�
��D\�ƽ��� P��S^._� �a��L �9@ KM~)=���1SZQ���%���$D�	��P��K���@�`��/�¾ߗ��n����ը<E���/���<Ƃ��H�v;6f|X6/ZYo�^7`�zؠ%N�<��m����v)��ob�ø���8 Q��,�ŲG؍�Ơ�D<�@gT�E��T���(w'$#7brG��_����o�%�7˼�a<��
Vs,��8E8��"|�+������qS���3�T��ZO���u K'�z���S����� ��*���m�忇I�K?}�狵�ۓ"+3*�kq@ac��7n*F���7nbn}#ǫ����Aw2r%��w����K ��s���N��w����A��#�,����ߟiJ���v�4I���X��77�������|����/0��3~�w��+M�5�K�z׿b�#�&��ʻ���ǅw$���V��k��U }\܈�)���@��X1`�^��"���F�Ǟ<a�`0T��U��_Vr������m��Q�2��!��Z]][]_�Xݼ:wv���̓���Uaz�p��V	�+��O�͈�� �S�ß*����}��t׆�jfR�$�o���z��o���\���4�	�׷ox�	�3�嘢"�����̧HkF�̶��k�1&���Q�2 À1�"��<:�S�0���4��;�0����zm��q���r(,�4�QEz��4�,t�#+3�5�&��� y�8ǆ�RxUZtϿE���?�L'��;��X�saG�>JňN��8S�
J%`��ۘm�?긬=L�,:�W��r����R��&�.��%S*H��b��À��l@]���tD�Iմ�S��яGf,p2��;�9d7e$x���q��ع4=Q���׸���H��2�,��K~2��8�l�|b�a�y�"1ΰݹ�� ����5<$F ]v�^�N��+�t�w�S�
r�����/Y���os'WC���0�����Dt��8k����{�a�����pڢY���ϲ���`<�|o���n^�Dd��:�ã@�\����-`�<w���v9�����(�U�~�$X�[�.�k�Q?��X�@�^�o�t�O�����1A���>���j�L�k�s��!�����݃��ܱ�]�>M����/��y�y���6�j�8�=����Q�~�l��ܭ������^��H������E2O����,�޺�a��?�������ܚ�z�d;����)�yb�$zr�8�v5)�S�~��b��9�ʼ٩�&�6�B���:����\���<H��T�O��U@�
����Y������~5@�wJ�)j��h*�Te!O��h�T߭��R, j�G̓F�4�k^�Ӭ�P�:�*�WF����^��ʟJ�d�vǷ�sg��)vг�G64RU�L(���-��}����I[I�}�������I��3�c����Z��k��1��� in�ov�^K�_��VC8iUN�Bќ�7�'�4��?W��\P�i� }A�p\��봷Y�2��B�@)^�t��$^�+	��vj�v��i�ې�N�����N ��児�,�L��� j�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4OS��6��{ � 