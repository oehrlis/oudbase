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
� 㯡Z �ml$I�ƚ��멝��=�w���ml5�H��>�>I�pv�Iv7w�u,v��N�r�2��r�*�&3�lv7�ClA�cC'��a�0�[8�2���0�Gkl@�q6`�_�#�l������f��=S9î�Ȉ/^�x��M���]�S(j�
��U�Y(��'�R*�K�j���IAQ*���\u�����@S\����Z#��~�o�ӄ��1t��9�su��b� cN���(0�@
�9R���Ğo����QI�����-������52?u�G�y��K���ɝ�kZ��M������ay��Ic��ێG�l6��LC5چc��種k���2YQ*Er��z^���ˤqjz���Z������{ֈ4��e}�ul��lxFK�Ⱦ�q�&Y�w��4-gӴ�=���f����nzA����6:��6�;g����-f�,ˡqb��mŲ�/X���ӷ]�A�4C�c�=�٤m�G� �]�4���%��,�ٺ���=��[sԁqt��SM�{F������:1ۢ�
�ӱ9z�����mw�jC`��k�|r���<Ø�,Hܘ��z�}�*�9[��%WX�J���m��L�KN�y�bNQ0O��S׿.�8b4�f�-b��R���+��Y���=��A�.=m<��m�������������s��Z6d�q��l��9�زt���ۑ��6a��y�v�{��n6����a4ӛ����������ჭ����6���m�2����X �����z�n}����6�0IgSc�p���x����>��n�!��������������g뙼��gh����}����</���gҍ�����������z��B���Pð�?j?'��C:G����d�v&�[�ީonn5�@�ێ
2�u�[����녴H�I���Ґ�.C�tg_���<pն��D�Gy������0�ڑ�*�DM�6�]�M2�{w���x9:ȟg;'ɚ�C���{@{[��&��}s�ɾ�l?��.�G䋤J�v���VN=\z��ï!�O��'̔!ŝ��Z�О���1�]S�|i �����	��Ѭ�M�14\$ȮjAo�!�QwRH�'Q^2�tlX��X�ؒ�Tn�nS����{��Y>�E>�D�d�)�/>���J�����U��?��7��xN_]Xk�|��\�@hz�L�����%N�]FX�Gyf�
,��UMu��ť�s���G�H*��>O"B����>1H��L�M�|���k@9ubW2 F��J,d�������.X܂1���Y"�h{w��h� ������e��e�׏߿���������E������~�z�?�Z�z31�m�^ʐKx�B��j���)�<C�	��������:�����6�$ʐ�a��*�Ǡ�4�F�	�������N;8�i���A{i[u[��=�Iۻ��'ez�n[F�7Mq�>�(�O���99�?,R\P("Q�M3�A� p/`�OM�
��q_��ı�Y���8�^X
�\䮰�Ƥg�])Bvਐ}�I6@���s�l��D���J����͑L�]֐�k��r��ˉU'��Lqi_�~e,|Q*�b�H����Auq9�[ȣ��sU������V �ߩ7"�D�������GK��jvQz���(� o؃�N!x�@��KB��tmU'��������F��Jc�۰a��b��t������0��ѩ!�V���3�,�_�NH�{=Ւ�_��
"z"��8����R�*.e�=	mE(��*���
,�`,�>��k�^�|���l��	��Dl�	�	�P�!N�HW�*�ut{$�UC�g>R<��ߥ����|�M����ե�N姨$;U-K%.���۵�i���l��ĲO-��!�^3������th����ٜ��ӓ@?���I�t�A�[�Q
���,	��Ճ��َ�AA[����qfY��9��jļ�&��2d��4W��ߝ�f�)i����zH��h3��0y#����>�,�T~6&R����f�r�E�r�EMi�[T��n�$$�*�OW���%/^����y-6P�U)@mX�"���`O���b�`�$f�>0PB/E�i A�!H����4�1Q�_}f �e�G̤��
�U2��'0G�B������0��������ަ���
{f�
�T�d�c�?�e�vU�R�w��=G퓌Աr!�{�t�s-�����
�d�Eԁ� �YT��d8^�L��mxv�V.�wl�~���U������0��I��\�\�rmk�A)4�1RD�i�bp��Ӆw��=	�t� PsOZC71����CT���,�í����.�Z��$Se2����-����F�h����<#��"(�Lm>�(%��@:'1X�5���V�Kdȼ�s	�	f2���WҘ����uu��C\�A@p�g=�L���vf�*$��C;�s��y�	W�3�B"�`?akF�`�85 ]'�'J}�d��Z6���>O'P�_LL ��m�34��/����V�r)>8|�W����F��(��y�l�'g[�i =�A�eg����~��}��L�ŖB�Qؑ�=h>K�D;
=$�:�G2QE)<�L��1����yY��s*Q��r@���Y������q$��gM���>���DJ�R_ڰ<�Q�'��lo2eyo���>�m��E "�OeSؽx�S������c+O����?��y�5`��%BQl��;P�ŏ}�s�-$��8&�m��5Y�eᇢ�.ս�a�@ږꎫ�d.V�
\|�5�h�V�÷�**��1��,�x;���O#XJe�0ƒ n���w2�G���Ţz��,�ٺ�������yle���.���`������,��l��^��!����^�u� ��u��I�?\�Z�'ϡS��%��ź�KN�r��馄��#N�h[�y��̂ѩ(1i~�ŇI�X�zy!��a�[s=s8��q6:S*�?�,�*`�Љ��2�aw�&��~Y�4�J��ˎ]��&o�`D��������]�T�gZ,d��+q���aR��k�B�%F�\�>>���֏�T� ~!L�k�8ន�d�t��z���@�{�����i�RL$��xq��z�(�.�O>4v���Af_�-���Ƿ�f&|����T.����*�B��+3���xf�߯��;�p_�on��(�ω���u7�^���Wd����M�sl} &�5*r��f��B;|@´�$�k>��6��%�����Ն�d�}���	��H
�0᎙
7>"��PaH��d�2�ړk�ۼ��M<�r���u/(���]����g6��j#Mf6�3i2����H�l�9��~C�V�·.|3�1�g���U��﫰*��O~��'!������֒�-Y} j��P^�j�lD	 /n)�v�
�2S�ޚ��E�!���1�|����/��y_����?^�?&��ҕ�QN�N�koJ��^dlX5gR]A���#LOm&�E"#Ja�:���A�@��E4��ݬ*[P��� ���ϋ�����G��w��%d��8��n�� ��:!?�������\��am)�q4<��u�,	a�)R(�'�}�� {4U J��b����Q�<�f�R�[�	�R���0�
+�����;<���Ȩ�p1oRƀ��ۏ��ߥ�؊����c%��vM�D���Kg�/�p���(��%��a:����E�ݠ;day��K��s��8��ܴ"�<�����c����VL��	���
�\Z��z�}b���|����ޖB�!v������9�|�\ބm�b�\�E^ßn������v�9GܜK�,s��2r�e���PV�]���$:�Z/[i��e��G3D�-�����;��,���^l������O �d���Ч��ks�P�KH��c���d����.x��A�%��O<v=���E�fY?7'�sh���r��"9������֓�/�XX�q$,�)r��"�%Ydi]���80��u���R��L�Y�?�,?��c ��0G~-�Z66�@hg<u�-��?���8h�9�E�Çץ�zwi����{�r����ݭ���7D�{�y1��a2g���h'�����.q"C��f���{̇M�"ӂ7v6�7�3�1_�����/�I����c�ѠR"fU�i����i�[�ae6�q��| �nP�Q��q�C��֤���3�P��N١ec&V'�Q�@���K�*��k[�x6��8��nA�<�#�crq�~���$�D���a�/�@Ý]��g �X��1���=xI�~�K�O�e?�0뚰�4��6�\&P������E&=?�,=$�n�l�Y�<Lϖq�\�tn*��FƔ� b$b�*������[����Hă����[���O�TC��by��Z����+��&�����u�k�Y���c�?Ws���gW�O	)�]�"�u�SͶZT��s�i�̠t�7à��S�����jVz��������b����cMGg}#�����z�"p8��A�	���0�����0�i�5}4\�d���	��B+�E�ݮڞYо���I��oKt4x�Fp������������Q}gf��T�Z�����lri3�ܙM��&7�:��Nd�;3ʝ徜Q.���F�3c��fƴ3c�7ʘv��H_CCZo�\�m]��[ ��J4F�#�i��Y��3άFgV�o��(?���j�����Pq�/���ز/*�d�����Y�V\�)�xR&?��\/��sеIG��0�����{[��mm}��/�\d���;����ϳ����|i��S�����qc(�Uz�B!"�"��V�Ds" =�bT�		��!ڌ��vTn��������hVŁ��'���B
Y���z�\֎S6�|m-���,�q�U��:�w:
�+]d[eNI�(3F� �Y�
\+l7�z�!^xEI�����'o���gF縇������s�-B�ث	�EESQ�4v|���7l�e��a���AZ�d�n�=x��&�Q^��e0s^���m���%����������-:���6�k�%�v��W5x:��AY����OZu,1rl��9��D���>�IX��[��ɭ��[�I��0*�Ƞ�����㍉c:�ᤗ��	�#�v}��xU��B	���aZp����^F���A��K�!�-����O�"�
	�!J���u�L7#wz$�$����'3û�g�]h����v.. %4zi����ҔL�y�f��x^���k���o�8P�^I���r���ߕBQ�+ERPJ�Rqf�}-Ϸ���ޚ��U5�� ���	��ކ�"��
��w�;����o��?��ߌd�5�~sn�w@ϩ�~��uU�C`���:hp����~��T����-^�]�p�Ƴ<�Y�ߍ�E�f�ضt�������3�����_�>~*�Bh��#��tEu����R�V���ri��Z���ǫ��,��d�������'`��J����dg^ W�R�{�谻�q"���� �����a����m��$z� ж�#T�6��	�����M�� >$���c�y���#��A�����'̶>Ji'A%h�a{����Α)w�����߽~I��HJ�;�������Í��_��3��e�2�ߦ��9�C�}3��ZcQ7�3�����N���Uӵ�Oٽ������)�7��0�E�═_Ԯ�2�|��l?���y��IP�fuӛ[w�v��M���^rR�[F��7�B&���sIG�<�pd-dm�o��W�W�����w�7�;b.Mah�; �70�!��\��ͅ3����\G[�;���ϋw	R�������惍#�}�B�	P�i2$�,�ީR�sJ��+�2��}4"3�nQ����������a&��[)�}��#q>��?��"Q
��i�?��f�ֲ����D��&���C���ayi��E[�1�����"7ARÑ��唄��_�ʳ�Q�#��"�Q�?�Բ�&���gҫ�"#X��@-K�����4��j܁�!/|v���a\p�C��M�̹ �g���#��&@��&0ȁ݇���Z%�	8຤X7�;#�%��[x<�8˕�ˌ����F�O`��`�s���I�r�p����إԪ��+sưB?岕J<W�����u����+�R=Qj�s���Ԣ�/\yk�h��cfBG͖x#"�2)�6'���OE�����睑�"7b���>�@���~���A�5��GT㩡h3�U����V�+=�zͭ���?G���)�6�R����q `�so�XD���L(���E���e��E��F�#�J��D~�N� jx��=�8ܾ�~t��Z��zm�x=�	K�c t����uN�]#b�+���í�ct��Xp-f�+~��aqr�D�����A��3�Z��0�L�DH#���d","�����J7��}.��-=/,!xLnL��z���6�7g�*���..����$�����qNDL�b�`�X�	6H�y�[3�U�۶�-$�Ƈ�ߩ-8���w"�˅mG̱����7!T(�����(E�m|�E��q}k�q4!o�&1Z��P��84��6,.�~k�<4{}�-a�=�EB�TPЅ5�m�hF"��۷CV�L��6"{l	F�>��>"��<�܆X�G'������d�fB[z����<bqc�Kڷ�Z��n�%��hs!�PF�D����V��B��EɎ[23^�\?"a�,��j��0|VE�b����$��!]���9��>2�6�ep*�p�.��I�g��9�����	&\�#n�#E+z�*���=�I0��B�C�/��#Bw��a�vqZ{Y:�6�Q��2�	QvT]OI�3� Q�5��nQ0Q*O��;uld2uK��A\�^�x5 s�3D^�)��^��¶�U�8��P���Иݓ@,��}i�����ghҲ,BT(�����u��@C�o���ѣ^ON��gD�k$�4����c�r� ] �̑5������c�2c?�b�D4@�������?
��p�0�$��΀��б�E��'?	�??�?.d\S��,\�1������IZ�[���\g�Pgz��q>�u��@Q�O�3Y�q���XK�;��"�
����Z�8��d ,��(��vs��3 Ȗ��Ѽ�Ї�FX��b���cs�C,/�J��"R�}�YZ��j�!�5���Y���ɨ��@�l���g"4#�Gep��!��Y���X�:��H�N�����/�8�:������N4��n�,Nv� Dl
�Ӭ��Q����n/���GGD~�u�6����-�2���GZ:���)��|i��ly'�=s`�9OQ�f'A4���,�Dq.��d�i��IOF�|��疯.�;�್|8����
��-z�A��U�;>�K��T�!�<�Ғ�RJG_/�:��N�|(	��<�gbF$�%��o�����)0��gO��W �����Zd��l�%�g�"�[�_����[�x��*��{����◶i7�H2!q��O$��;%d4��0��p���ἼJn&��seim�C�7 �����X8����(�V�7�	ġ��%���š����������8�)�����>��N��Bt�m_�>`~e�7��AJ�\���2�Xn��}���w2�Z�O���؉��W�
�4�ōPL�	f<F�s�6;8v�����������ͭ�+�z�uFl�ō]��D7�b�?��Fp�6WC�m%S��RW.<��F����&Ѭ ���j��z|fI0�r�k���x�(��Q��P(��	�)���肽�Ξ�]~ibvc2iN֗�z�>]h�U�>�XS�L�<����`���E�1�3Ϡ$�h\_�U�������E�T�@�Գ�ņ�-�����������FAw�Z����&âw����H���X����>1���J��q�Un�:)���ի�g1N����æfn~v��h8���e�ܸ��A��3�(wI\���������G)��&�a�l�0o�T����s�+�]Y��<߾G�$�Q5�q�TT�S�E�z�D���?�b�_JDu�1��`�:��Aُ�:+�>��tz�5Ϋ_ õ��DֲDã8#���[�T����������C�I2�H����q$���:](p-���y-�o��iF���G{��C ����>��8צ�~�*���MP�Kg�4��,#Ʃ��?��'"�t/-��un!ح���sC�����q����h�ˆl(HN���<,$BXHN�
��g]���|vj���#�%���]J�B��<^nV���G��G���bv!=���s-�g��B��ԕuy��I`1R	!=^Dַ�E��UE���خ*�\Bא%F9�:צ'd�w�ǲ����n�`czRv�ى�!]�.r�z�z�y���H�
}�EЉo񮒣�!3t�g�<GV.���M�����>�-_Rv�:��� �?@/P�P@ �'1 L�[Rbiz=�t~J�������G$�F�ǿM+��EJ ёA����"<����y����2��
��rC*b�3T��!$�!�+1/Gy��ק��CbӃ�[�n��5Ф�\�P�Ju��)XA~��@J�yo��$"k�w��At|��Z�B+�!�����������^d�r��))	��u�����xa̿XdP� ��|�q1�� �9�FT���E~���~V)��L���9�T��L �\2��sA��I���nx������O�Q����@�WqH�<з���
J�v���}R���p�
����=	cg���0|+^>����b�Hu�EBrQ89� b��zI%��ǅ��!(����p����@�Rs"͝�A�BSj҆����0��y�˷�ƲOi�CÅ�}=����yR�n͇�y����[�&=��:ˤg�rVՃY�I���۞� �o�`�m���I�h�EǠA��"A#�^�	�E�2��vtֲS��X\�e�"��q�Y�a�jKjX螑y�R�����Gw.7�4$̔��b� �9�+�G>��Sgס��8ڎH^�q	��uB������=�����4� B�[���=f��NS�AY�e0�9���זme�,4�]�9U���h��ہ�Mp=S{B/u��Eܳ�l��>>�0>�D��	�����Y<�� �=G%nc�Q���� dM�R�@�tq%7�M�b%�&,��hB'A����H_��Kn �S�]���;
N]��<n,�T���]س���?nNb
'��7�[������tJ�TpL�d��1�J�B�iߘb;F~�5�Pe��ᘢS7'�P�d��D$~�_�z�(�4v��2�E�*�:�x�7�Kw%�P!
rd��n_��V�E���t!��'A�n�7��̠�4����/f�e��dK��RN�aG�Ï3�4F�eJVA!B��1�'��-��=�����zH���iM C��1�c��=$��)+vHHt;�t v��̂���5�,x-T=��(�{=�ꗌ���3*�g�qb�ZL�BϨ�_�R���P������ �]�Ҷ��#4H��kO��?d�ʌ"�(E��k�w���O��<�Y��L�W>�Ȝ_	�N�.q���p�~�ˍ6aY�s�A캠�?�!T�ɸF�	��
�]��*�l�Byց�+�qI_� �=��cL��x �\�.|���(f7U_�^�4��R������@?�<�]�.=tRM�l})�L� K^3�v��E�ĞMT���w���,�mlp� ���PCܦi��}Z����~����ܦ���56��ʱ�2��W�FO����c��|�zizb��h<_��@�b>��-��m�iMָFE��Q���'�F�ޠ�
�јjñ�o]H�]�r���x��6��x>!�Jr0#�ԡ�Y���~���,��ӏ:|���a����ذ��꣉�1D�ݘ�B��W]��d(��U�I�Vt�q�?�s�S/�)=�d�^\,r� *쿟{˹&��=�� ��x@���(Q7b�cLx�ŒXh0"�������?���k�3��7�/���T*�j�)(J�Z�#��n>����p�a벹����WT^�U.�R������P�������V`~��բZz����ni�:���ߤ�<]ut���c����j����!e��}ޕ@$R!���0�i�wp���7��w�ާvG�=���Ar�.���a����m���]�V����zf��ހ6ޟ��g� �9��=<�=�Bn�^�*���~�RpY:5����ȭ��Ul=��O)���1ՠƮM�bZ&,1-Vǐи�Q�35��7v�	H��4ӽ�ݳ_�<�5�1я�2�KE8Ԍ�(Le���!t"�N����6��x����������۷9Z�Ya�poEv���X5��R+ �#��v=g�!(
�P:��P1��r�}j?�P�4f�̮� ��=
$a4D@@��p�ؖw�9�M3�:���+��)�"cF6*;�5xJ�����
۸Io��Fy�	���U��4�؁�Yٸ�TS��O�=�7<����P)�Fdv��gg�� F��-<(�#�D�Ǡ�����?�n�y=D��u�Ǿ_;k�<�	�HzK+
�3�O@��> ������_��^@�����_���(?i�k|A򃂒w;0W�|�2��񢲬�d�ұR^+��UVh���#�U�Xv�$]|�I!�,�f�Ưi�N����cv�sT���6���y�s���$
��}AF�#P�JHj�Z/xGo����)"���Ȋƴ"+ۈK�3Y��^0�6�Ɓ;ΰ(�#j�0u{�n����M��L�rd�8�tT�=��]U8��q��^`\��;TC���\�#�����,�n��-K�qU�
*�T�H0���K_a�1�,�ݦq�i��d��S�`��S\���v�>�w�\���:CDx���|������d�#����Rf\�	�rL����M���_�I$�X�JC���j��cgyw�[��']�g�z��Q[�U`��9�ݦ���{�~l���m\$��mqi6��T4���t���y n�(���(����\�y�6gLtr��vƥ9ɐ-������\�6�ܷɢ/��HҼ='vX���vS\�&3��;���������D��I�&��)�A�ȳd.^����%�\E"0�ǒt
{%[(f��RX���
���#J��+��Tj���2��|A��0��ZR�h�>�_�ʑF�Hz$�$gK���h�
)>��!�@(xp=�l��l�z怇�б��5d\�`��[.���C�����r��9��[*�x�$���~��$�d�⡠��E�� ���8��vzM_�K���[���jq$���8��#A�u�F��K��od1��(,��Hڋ�gu�9����=���R�bR�87x���Ϧ�r̣䂓1����d�ݡmd'hl!�f����!Y@�`�r�z2�$�	,+�����$�Ip�^4� ����DN> 7��?�NI?����)�
���K�gi�p�)	�n>��i�(!��y����Bb��x��'������]��Oì̧�۩ůK�M[�Ԁ��t1%�b�1���& �ێ83��̞,!�}��fs��!��C��ȉ��Ӯ{L�Ӱ��fD���q��7@ �Va�E�� ��5,E�雐��h,���xh0!��e6��gd�/�nt��<�b��M}C��8���'U�6��c�"����A���HS_� �^ ���@�U�:y�M���.+��X��"�� A��P7�[f'�cv���c��,\)ʯ�V���D��1���L�]w���M3����塎^~����c�2��bs-����	��>1��g3@W��؛�7D������F���b���� �����zF��-�v�H��imNx.%ρ<��_��z;G~�y���,Ub��i`�r;P�r�4dU�-*(.;M�d�ۘ�}��W2O�R�'�"�}1�E9K=�r^3K�g�s���TF�뺣uLϠg�����@�q�?�Be������VF? QA�4W\1���=��`{��KԢ�`�CP�R�ų.��ydX.7�C��R��6|w�|�x��L�>U%em��0} ���D�84c�%�3@��e淏��",�#;�[Ȕy9��-9r��]v�<��<�*GA�h�T\H\Q�ģva�[,xF3��MƎ�\dh˾w�[��8*�4L��F�F����!w�@s�Ϟ��X2���������</Ȧ�X��2&�}����o"=�ǰ��������|��$ϸ-�S��]aK����������&�:�"��9�!���<�Vn)�L~�P�-�i��&�����8��e~$þc�.j��R�f't���*��	XeKCt��/�.���)��tP�.�g��������rZ�q���lo���w/*Gvl�%�������a@�Ut�B{����S���&pf�5L�V��I��;:�,֔:���M�6��r϶N<���(e�M�CN-��"�-v��v�e�K#�7T����t��3�z>Ң
iC�đ���X�b�I����,��7�fP#�XA�����v�=pB3_�EaS�7"ZQ8�e�j�\sy<YQ�4��dL����tKyp�����d��]�S-(p�������Hw��S�VQ�Y�P%�'�8��M��������'��͘��%.zdD֋eb�j�y��k��z ����#��^'� ��E�ClVuҙc�U��e��s�A ���[3��%""4/vT43���F�l�n>;�%	*VIB첤Z�]\�d����PG�X�g�܍��Lm���&���JEb.��i �EMOh|Yxۋ �� �t'O)�+cV�Y��>.��ܟ����W��mC(Fjmn>H��ipL���"r��@Y��5b{��Z��C؀�B����p(��S��h3R�/7����/��M��9Ȱ抣4���R��*E��oV)�+�3&W�y䪆?��A���1�*�C����R�r�M*�Cg��U7�;��w)�!��DcZK^�y�$���K*T(C� ��R��)� ����_��m�ꃒ��@�b�Ě�xD���S�r9R��1U߄*�{��٤5�%��,޲!+�����ڈ���qe:�DZ��r[1�������x��x�l�-V��/ׂ��_�N��2a�j�TЇ'����#�� ?��R;}�#��q����hآ"�Jj�p����뇆�JF+O\�Y���'D�{����a�A	$��ᚾ�Ƕ4Զ�q��i�to��/`-���1�]@L�54���{��| �^B,����V���S��f�����Q��{�&��@�'���X��N�,&R�ון��/�Įl
;�5o�i�h��$@�Nm<�H,�$pQM�x����I@]�(`|�0��g�ё�Y�����q�H;���)�;D\#�� ӳ��¿�}Y�\GBBg`��>R�����\�#�����u���  �Ir�֑�9p�B��;�Y3Tׄ�.ӵ��'-T�0,vpiqo*��@'E�4��k�艹��k��1��j�he��*�t���.���V������n(�D�jL���
a!��M���O ��\��W�NZ$C��OF4�Ix>��I��6������A��&�i
~0#~�`]~�sa�w@D���"�xb�C!�;�w����ͭ����H�b�P����]Rk8�T~IGp�����P�jDM��ľ���,�)�i%)������2UA������t�(YA{;+��MI�n����\�a�p�}TZ�n�vp�`�6D�}�t�ɶ��>���B�@��6N�)�����G[�#%B*����U���~.:K ��߃�AsOZ�B����k��񼾻��cCsm�	���S~bi$΁������Z:}�|��z��� �6:N�l��,�w͞ɢM����C�%��SÃ�4LP�L�K�����*0P�>,Q��y���\!G>��RΈݤ��*h��b^�����;==ͩ`�v�y^�������kle�G ����?m�3���
�����BY)����������,��u<�@�:4C8AϣU2�YJO�ԓ���S��_�LK�i�$�8.����.��9�z$^�C�?�x��WQǘ�_)�*��/��2����VԢZXY5����Q.U
�J��VZ��Q,5�rUo���'�|��@��הR�P)��jT��j�T�WW�rS��6aR���)�}�V��,U���^\U5]iU�BU����JU�WԒ^-V�ҡ_B�Vlj%])�
�h�m�[EmU-��ShՠU��o[-���J�i@{��ba��j�T�Tl��VV�����5K&��f�VR5]њ������
�/��� ʪ�Z9P��jce�\���*�ުJ�X���U��,����ZU���ψՕ�J��o՚J����U��Y-�-��iz�����X�T�jKiժ+�j�UU�m�U4���*Tk��r���X��l4��J�B�Z����ꥊ�+�fi��R�"�b�?���Zj�⪲�V����hΪVTJ�J���Z�#��]".2�1Wyl���ZM���% )CQ�+j�\�֚����*���JqP�'�QՋ�V�X]m�K�uv�j�P-j�fi�((Z�VI�H+cU7
e����*�XW����(��ʪR(�E=���q�KF�K�^�E�0 J��BY��VՖV)��
+�Q�5M[m�U
J�(i��J)�q�b�\4�E�P��ZV�bA�K�B��W
����UX�dp��N(�R* G�*Ś�l5�.��rf��V[�_�� d��J�h�jY� VK+%�+%E)�j�I1*j�ܥ�c�"��W�+-]+�W���2��Z��*JJI�i�K+�R�+ԁ��s�E�4�}�uk�PSV*��J�CY^� ��Nۘ����������������:=�\ix}�Z��kFY+�mFg��@ʱ�ZZ�ZժE��U
@�͕R�(�`_��5�zI�iC:_<�H�/�+:��Z`�Z�R))�b��i��Z���WJzIQk�@� �Є&CL�ܬ)e�`���,�fFMij�f2��1�|��ɱ�j���
�d��,RA�R4Z��j�kAm��e��FLQ�%U-���j���B�R)�j& ,��*��R��X)*�c��Q�Vb-V�b�Ԭ��j�Z lX��-�\,�A\�&'0\�K�&H�����T���rYkͦ�ө����*�["̨#��Tt�*jը�T��AO���W[��V���͢�'�����"�rEӪz�LK��o*�+0eK-�f	C+�Vkj!p��D�S�-�����p���U^Ai��+Ze�Z��4Q�d�I��<�ڂ�Y�I�jִuU�Y�&�`��5q0��j� ����J��*�R�B<�YUa-��A:l�i ��¬Tk+�&P�Ѭ`�
�Q ��f��D��ת�~I_����I��W]Ǆ�_�
,)�b��Uf�_��I���]ǘ��TU���LR����k���Z�[?���'�q:�4�N�E��52?u�A����er}��so�������I��I,��l,A��j�1V��9�����LV�ݐ{�:yMg�n/�Ʃ�=3=;�F�AJ�=k1�x_x�����B�D�m%���.��+���c�� ��PzK7������zLoz猍�&nr	��rh���(Ʋ�/X6�fkj��=�D;	���_��$F=����mx�7G�7������-B "E�t��I���l~*��B-W,(UB0B�Y����So@֏�	�����8���x��y4�n�ob<Eq�d�~ `� 7�B��gх�i���h���;��R����M��F��i� 
.�����Mp��y��q��]�"������3Q�f<``�I��fv;;�G���?�m��� �u`��)�p#��1���;S+��!Yh.K� ѐDf�D��6&� 

�ɾ��YT=_"���shr�/�i�9Nb�↜B�E�\*7��-FE0�� @�B<I���@�U^��Z�����x�f�����%��H��_'��7QĢǉ�P*�"�#�b��[��n�g�O�u�� m��0C�K���5<�M��~�8�?����G�::�J�+�c�����Q���v 3��Z�o�֯Ͻ57��jd�A>���ͽE��%����`2����C�K��w3�%��H9���uA�DLs렁�?1~��[��?���9{�ȑӕ�1z�+�R�E��V.���u<W���2���x� rH��<����Z�R��aa �������!�I�@�NB51X�c(V�f�hQ�c���V"�j4�C)�p!�_��u��p�Y���������C�^3���W�5���ǃ�w����瑫�� ~NM�D.�ߨɗ���BD�0�+ݚ:IMf3�w!��ެ�oF�v�
�Á�O`��n�M��H�����y�	�{�d ��F4H�H�O�=V̻��wwR����7Y�M���a0��j�k	��-�"��O��� ܑ6 C��m-����g��-�Yr�l'z��
qLZ�Dv٩���?={��@�f)��5�Z��/Z��m��������j�BdRG��4!��f*	,>oFcl2��d��2iݶ�4�.�����/h:g�ω�Q�A�d55�%���mt6ʞ����$�����_#w��;[���|�6���{��6��K�#YoCo�ǋx��I�D2bm�x�d��iy�OU��_Z������o�V����m�f�77Y#�_�Hz��V�'ʲ�����B�� �Z$��}=���k?#�#��xTH�Z��,ʙE7�'��!�(eI��>������t!Ssh.Vk����xz��L|=!S��	�;C�����"�s�-�@F��R3b.���\�*�B��b�x�ݔ�*aLw���i6�;�:��$RF)��f�������W藾�G2���إ.zN���=��4x���p\lE�{j6KW���5N<A�/�聍7�[�����uitw�	c,�J�6M�����1ꃃw}��.I~"d�����nn}����0��P�fwmg]xv�a}ac���ԏ��7f��+2Ȕ����'Xւntք��I.KJj����y��W&zxZ�X���.�(��0���^��{*0�G�T
��W��͆ō���Bq ��h3��^F�R+�x�� ����9H+�^mc�%���:g~�Q��;��� cCDC��7W��d�������S��^��k��G<���YǄ�?%�T*��eRP*�����z�������?��W�.��ٓ�$��L��1�X���?|����xf�?���Gr��Z�QWF�E���Pi�㠗o~4��«S�r�E�Az��w����i1�}XJ�zY�����W�ƌ������(�
���X��]�s�2X�rfMv�n:�.|Q�/�+0C1�$$6��2O�Sm��Zᩇ��W�+�=Uu�F�e����l6��o��Mߺ�\"����5�����TKյ2<k+���~�tɎ�ӭc��_��j�Y�����<3��W��d�J�C<������LWR�9==e����YǶ��N�����>���(L��b�VP��_������	#t\]�?��YC�o��f�O$Jە�q��_�)���_�#D!;�m6� ��F�şq�����R��?
���y&9��;���b?���3������f������f���_,
���/Wg���zRw���ޘc�7�I�z��Ş����m�o�h���f׾��3{f��=�g�\�I���}�͘=�g�����??��>S��[��[B�����Ϗ�����������?o�O�??��>9�J��G�ל�;�WP����B]�=������;sڜ3g̩�����wM�+�4�֯}�����7n|�ƻ7�ht������:����4��#�����C�8=���7lo�3Z������i���{`�����~����7��y���Lʕ��2y^��{�z~����~_Y��E������#��7�}/�ɿ�d��4�Z1��;�C�{�����?����Hx;��w�}瓝Ov��?���'п}zS��o�;��=�1r[������4�;�Y����kj���z��0�.����=�]�|�)q�ثO��x��͛�84�4z#Zt���P%��z���8��-�>�����n~�7�ܟ睟z-��t�����Lu5�����G�k�w������o���w�����{��h�7o��t�4�������w�#Ϯ���5o��o�7����>�74N�~�Ư~���������߾��8r��,%����M��'@4��;�7��tզ�eI��|p��'o?�F,�w>�����۟�[4]Z����9֌�-�}ÂV�P���������3|W� 7n����x�}��x��Ǿ^���_�+�m��������_��s<�'s���<�����?���s���?���s����5���J�S7S��z/�S��ZHR멟�>N�S?M=L=J}�RS͔�2R_�ܔ�:I��^���Կ��S%��R#�G�-�����Կ���S�a�o���������&��R���S�s�I����-�������ַY#��g<���J����e�߻o��O^_J�o���?�[�M�_�P@d�%�ɑ�#0Jx>a��ǉ�����w~� �O�͜����w�W�a�0���@f7��w~�ݷa.�w?\�q��[l.��wn�� :��+�����o�ߠ?WV�y��`6������ �s��l��S���%	�����sD���x���wS.��ԏ�X��k=���J�M�R��F�A��cJ�OR�T/e����ў�~���@��R�_N��Կ
��7)��۩'��R�n�S��;����O���^�?O� �_EvG&��?�l�����67������w���{}��~Gd�TZ�ޟ4�k[�9&�w��5����e��oD�m��������{}������˛���_�o�:��o������7��7r=���\wN�3�ZrM�zO|��?�]�o���~}��sm�w�a>��o��3�-Cs�Z6$gB;g��=�g�̞���k샠�k����=��k�����ؼ3�Ե���_`n�A�[�`h��&]��a�l�?���盻���=��G��j����\*Tj�B	�?*�����:��5�WP����*���_�#���0N��1�?JA���o�J�R������u<��7�����S����5�4v��"�c�_2�q4����J���-A=pم�Aǅ@�ޠO���t��~t}�]��pF�\�'�hO�M!��^��1�'�͙�k�:�����vg�[2d�d2A�	�{�X(���W�EH.)�1��A3���[����Ϳ6��)�$ ��˿9��������'�!�p\{�h�O�鱅�Y�of������0Lȴ������
Tg��u<����W(������*��Jy6����ƿ��o��M=�.\��1�:���_��3��ky�3�� �׻�������z�%]A���_����˅�zwl��w' ���ލ� k���=b8��nװ@�u���ލ�{7��
�.��߅�\��ѼV�D�z(@��h�[�čǢn:잡�R�P8�hX�T��U�{؂�/���a'$t`����N��Z�/�PK�����Y���a���������/�{)��x$G��� �\�s�h���`j$��&��]E���>ܭ�Eke�a.܇m�r��s:��e�Qÿ�k���w�f5���?*h��ov��3~vǶ=ܢ�:a�o��s2�X�9/��ﺺ�?�w�0�����b�I��ڰ-�F�s1<����D`����A�,�9��چe8@���j�m��7-�5$j��ݛt4�0�'��ݐ��[�.�<����e�پc��Bc��:�E<�Stj���}ɭ{\�+�+��� ���P��1���r���j����Z���w��ߐ��f��?���=�Z� �1���!�����0)䒝����th�W�CtH�"e��Q-�A˰r�Fo��c��N�<Q-�B�5���S�ȧ��!����ɩ���+�I��\A�~�t� q�on���.ژr�p�L�� $AR��0-b���mBH*�W��>��E�:�cdۄQEY��f����,�#XV]>��������0=��2�E�k�@��m��!0T�gml�;6v@���(�-5U|�05k�G�2|?�	����wN�ݴ��D��.0�5��o�i M!II��I��ݏ��nVk��H�խ,N�H�i�����mV�~]A~\#�����R<?:xx�����Ե_=pk�n�H1t����?�o++�'�Γӓ��m���O��ou�>9�Q���u�>���{Ϟ�~�?0�J���a�����lK5���wӚ�&Ф+��Q�@	�zKd6�Y��<�D�͢L�FP��0PG:�����]�~�u{��d�魑�a�*�ߴ��ڣpA\%���\:�tir]���p�c�gs?y�GKY޳A������6 ����,�����P��ɧ_n��{������������F�]��g�}�=��̪}y�������w?}����?���/�S�2�[;+���<��������_�������?�[��xX`lcҳ+��8�|C��Xv!0��(+��S8�
bcr6�Y���N��9���Ā>6�E��8J6� ��a<������]��� �$��UOͺg�6䵉w��� U"�!H��e�)l�a�6��p����BY>��Fd`�gr��$�ET��
Ķ1D��Q�=9�t�QS�5��q;O�O�	1yQ�����:���F���/�½z�����?�:�K�1F�SQ*��/|/�Zu��������V[W  ΔA�v�ʠĩ�f����Iayz��@� BS�gf�dR�^��mB��s0ꏿ7���@�&�e�@߲� /�xϵD�7��_��n�Dp k*4k��*�&}�N)o�m;����C��(r]�R2i�|�\�����8���J%@+&��:tgGG�A��:p��.��ˑG&�6ѭ����e��80�K�UH!!�@:ȏP�4�B���S,�-�&z��|l�6�i�k>3���'���ſ������z&o����dhdbY�po=2O�"���#C��+�\)W�
ǃ�����w��m=�
l���� ���O+��c<�=��8F/�e���s%Ҍ�����z���p�{�_��]������:�I>�:Xǫ"C�nMa����-�o�/CT��Vҍ��G��[��s�w�:F�$��|��1��P��}��R=Q���}$ek�Nr=ܔry'z��zp��ղ��@ �N�g`�^��Z*�� ��f�Ȏ���i{`!�2wk�d������I��'n�A���r}��{���|X�����"�����za�h"��SK	%#�YjQN-��RFܞu_�&�[�7��������S2��+W�J���Z�����m��w�7dv�ٛ>�k���ǎq��w�����Ճ]�'t9qQ+h&Zp�]�н� �^"��Fԭ�D�i em���kj?�=���c@�X$N�+P4�7<]����$7C+jw ��gFsS���t�m����Z>�6�Π�c�g���vnױ��}�ld���d����K��2��h�XC��˽���߻�}o(<��LM�*y<n����e�x� ��ӈw�ƹ>}ȹ��0_8�b�0��u]��4T� X��d��o��.U΢�,;��ඟ`l���F��f��/7o���$]ڂ���Ф�q�X��:5	�dWc��������?=Ư��&Ȱ 8��::���Ԅ���,�G��J�R���*ř���<3��5���|`���-nc�����<����8}���_���m�|�f/������nZ�aB�dq���3������5�H4������o���E���m�JRo!)����jl��M���0*�/3��Ly�x~)b;����fQ������aWsJ�J�
_�JN)\�f�޻���}X�y���?��n��q�,l��w![O=�B�/��9��D�Ft��~��%v^x�����Fi�M��G���uv�X�ξ6��ʦ���z}4�oN����et�����:}=��o�E_��8=Hbv�̘��J�z�Ko��<֥��J9&��+�_ശl����0O�_�UC8�w��D<�C
٧��z���#(�a��	�q4���915�#���Y�}�l��'S�ޣ����K(B��i���#�R���9��G �������H�Ʊ���@x�f���Ӕ�͗�Ev����@�1�H�Q�`�����p.)�����a���9���!�M@���
�+���]�T�5����>p�ɋ}%v�p;�㻱����m���W4������J��ϘxT�8I���Q�@�٭x.���q��
i�Vd�4��i>�8zpX�!�Gd1I�&��٭�(����[�&"� :_z��R�q<
/'���6&D$E���K;�-x����Q]��u��:#n[T�3HC�x/�S۱}�5�
�`��Y�3kA�>��; �a�,�,9�B�m�?[*B�j���^'N���6�aS,>t�W�!���U 	�@;�+�����7|��i��"JJ�-��aG�p*���w�Qܮ����ڿ`Nm��+�:才��Ԣ%\èw]�2x��&��0����K�L!v��V�<�ɥ�������R���������׭�O�]o��_0 �PŬ_����$4�ź����k@ߓ�455�AO��GQ��L�����0!G���]4�h�A���4��m�ix3ކ�������s�F��ە�5י��e|�:���Rܨ�3A���" %�	���@� ���u�qǁ&QS��-�d�ޤ'K4@B��l�6#I�.d��2@�}�F��I��������JYQf��u<��WJǎlʏU]?F��%v ���K�jt�K�Y��ky�?����[(�W�'C���ͱ��p��'�9MI�dBF��t��`{1u��\���bꍖv��[��;�	6�+�l+XhifY�v���'Ls���_��/�g�Fd�qq�~�c&���	" N�ӕ�'��ܝ�a��i�vp���M;�@��$�
���Oh�.dSb��4UUJ�S
[5�(~b�x1���A��F[�O�KH�\F|�p�Fr��P�Y�;���r ��q��+>8f??����
�4�P&�f\��h6V�}t1tq$�bh�3B�q�0T��Na6)Ie���iG;D>�� �B�y�U�ZD�GX��-}<�O&�w�Q��3��W���EHA��'��$K�	?M=?�&�;��ً8�ҋH�bʨ�X,81j/�X��K�PQ?B�	�v����}Vސg���W��\)G����l�w=��������ȷ 9aP��x	����	�Կ{v~��0;?���#t��`�������zq_����=�a��.�!��q垹k_�y-L�F>1��/�0ʍ�\�lu���*�K(�+��P$�V(������bз�H�0�4�6�O'��}��'Q�<B��=-�JG�p�j9��+�#��s-����K6�jZc9h�w �mcss�(��1�w�C��i�v�@��y[\�  ��w�t�4J5|=��=�=>��0�<��r����{7��2+b��|b���\z���L���tq��:��񼹶�-.l��ַ�h�҅e�y���r�%@��� p�E �AAɳbn�}7C�'B+��T�vL;�C4-o1
���Ǹ�"�Z��d��®��ˏ*��P�����[�X��hv�e���	�_6�[Yo4�nf��t��-0�����d���~�A���>�c�q ��uz��A��0{��hn�X�hn�ΰ��?��an_��1��T9x����?K�,��,����\��Z��r���B��b!>F�BJ	R�˨���=ar��W*��zO[O�� ��^��Z?q��b�A��
3��:����'���ϵ���������';��y����y��d����h�C�,o����J������?�3���������c�6Eq�J��j��J3��kyf���ڟ�W_�͙���x-�E]���ֿ��߱�N�6e���2�қ��f��݌%
��A�%.xs��Y��K��|���L���e��ȅ6f����,������!�p�.�E]Jڤ�~�h�����x��Dļ����,�t��'Ztg�Z��x=vWC;3�ݳ-���g"�4��D��?j�X�H�������r��]o�s�`���~H���� wk���(]1ϋ��8b���n疪���b�x�vm��/�� 	7�Po�Ƀ]�b�I���J��҅�d	U��R�x�1*� �_BIӓ��d�x�Z�ݵ�j7���@y�� dL�9ow��o�	e��٦�QOL�YS5��{��B��W�2M�(s�77�=���Է��\��ī��
������	��R�����0��� Ս��Q�!�G�~��x��2�J�8	��xi��E�;.��Mp���{�ԈTT��<8v7LD�N@�(�ꄓ���k�EX�ۆ��?�(�bn�\�)J�Ra��W
���U��I��r�����!��������^���;B�1�^a�|�� �-��"�f��Gά[�
��X���0Y}`����s�;�q d)s�$�-���+�� �S!� �x*�?�	����`��_S��ߊ�Y��kyf��kp�ߛ��o��81ՙ�?��_�����]rƍE.h0M���t&~�Dt�ܞ����U��ֵ5����j�[}Fg(��S����:�F�<4�e>3酙��b�m�� ��7���։�5�lp�O�=�<�ir=R�7��1�l�B[�*�s�v�5M��'1���CɈ����0�@��� ��X����Kq0*D��9�cX�"ҥ����y�Zк{����(�@��ꨚb,ԵF/Q�k���o��	�3׸5���k�ek����J�~��r�Oa��3����~�m܈�ϙ��d�6��o�)3��J�V�=����d4	K�)QGRv�6o�7�u I��,ۡ�sC�&�,���%M����^!:盅�/�;q�(9>�C�� ���6�Pȍ	vO{@�Z|�����y@�Z>��R> $�������[dW<���#L2�k�X�5�拾􋦘��}��"���][�ClYQq<���P����^kBۭ�����_����I��n&�$j.���%�?��Z��֣��M��<Z/R��V��^[�K�$�񅅏?XzԚ%W�ލf��n���с�s��J��2�VТ9����K�N�n���e$	���(�.�K۠�0��͚lm-�5��r�*�9�G�]L�[F�#���1�\c�_w ]A�[���X�n�C�ޭ��ٽg�`�%��Dcn�~U_����?��{il~0|�<ݞ"���L\�����vֱ���?���+�z�\��r����?��2�X=Z��^����d~�� �#�8��E1�I_��MB�d�߉`�JE��ѹ�\�\ȼ	�e�\���5[�Q����x��r����`��$߁�ǘ1�1�4s<�cfy�.p.�/>�Z��������-_��$�u�����&�����_o������?_���wAA|v��M��'��5�kJ/m���6��q.X`����s"�r�e^9h����C1�� ���X`��ƛ��Oޜ�8C9��ͱ�S��)���L�,}R}�����g���57\�G�w׉�B�P+��B�A��?����O;��^�V�{�Ze=���'�f��tخ��]�����Q����.T=ԙI��&����Zh����Ҭ���6Rf#� �C�kG;�(Yg`���?�I֚�f����}���d�,�j�����"�d�4��*[aA��4���`� ��y���ڼh�����&{�ċJ�[P.Or:����th��	���$�!o���ZD��s�Bb�,z"��!dH�RI����})����
B�b�\��^ �,;aL,_U�ŨY��[��
,�v,�[�1�r ���lk\�)�_JT �2��dJ��DWy��ޤ��t�w���7U�/1����>_����ٽ�w`�,���I	�8C-p��%�g�e��}DKl# �C�ĥ6�8����	2�֟�\"S��J��0f�n�*�O��R���)���Ɣ�����9���R��J�§n�!Q>��I9�YPͳ`�S?�cػ�g��{(�+��Z���:Z�$y!�1�L "+�/�`�v������t<@X���̜�x7���N��pH�V.+�̹�����_,}��v&6���@��=�u�d&��P7��H��\�-m�b_�E��z���0�t~52@�~�O)m:�Yk2��z��*������zn�m%=�=��9T��������z�(b�b�%=��pd9b�o�>/��욥�l[�p�U��K�zS��/U0��Gdq9�yj�Rrf����0n�aB\�g	��aq�ΌF��/��|*A�h�X���ySgi3��l2�x�Is���},"��F�h�`eh�u��rƎ�t�Љ
�NԱ�Mq�F9Qy��Sq����<rm�_e�_��*�j� :���� ;�Q�lxz�����i���
����<K�ᱽL�O��I�;��$؍�k$����vF��B0]<쥄��y���<�oe(5(dv�9�0CF��	���}�:�
�O�^�-=am��"W�m_ИR�[(^������%��o��''�G�!I���&��N,�,Ӵ��R���w��b�e��u�;rCc�>�0�bƫ�M����;zE	؝k�����-��
�nl� ߘ���M
;�P(���L�{�u��q��\��%u���a�kR��
Uu�E�ul��˕ZC|�oT�`;c�_�����Hz�o���O�	���)��{�m��������a����{ݳ���/��cн�������+���1�~�.t����A�3���3������w�����j�YnU�����[I����C�R���x��n,��`
#V�-�c�,R���m��8T�6Ng��K�$�] �ݸ���M���+��������v"l~��p��4�!l���,r��C�i���8�h�|S��%�Ê��q���i��u�|H�"��aN5ȍ6Uߢ]K�tr�͈`,p#=����Q�3�v���q��K�HD��|�%�NSi%{=3��y�3���h����W}`	@~�C�{xlD�Ǭ���5�8#^�|��#��n�,y�'�����o�K��"%3����7�a�	W�\�m-u���_�ˈ�\���DG��⥢�'m��C�ib2�'-W�_n�j��E��a͘�?�
7T�sQ/�̺1en�����S=Qg����7��Q�K�?��=�H�5�%܈ϭ=�t�T�P�fI�k���hIS;ʵY��\Z�J��Q�tZ���1*�]�T��B2k��R�V[�Z�p�H����|BF��Vb]�F$���k�=Ij��ƈ���Q�k���?�>��4|��3�O�Ou�� r0�oJ�E��j��4�NV�f���f7�D���&Q_�d1�q5}�;!A:�q��r�<�(��gr��_@c|�*)�I��D�*��c|d����b����P� fQqz��?K�]��	1;��ݏ�`��΀ŕ�h�WVLxPa��8�*��\p�X�B�L>��\j�3�T�8p�	Q_�|��$	��ͯZ������x��n��旳����2=����N���\[����s$�4h�灔��&�Ң�_|�eb0O������2'�?��[/X�������������f+���J��W�?��6�1_��b� ��F&>��y�ޔ���2���7�?�Z,��V�ժ�&����r�������[��<��?���7z���`t����o�Sw�ɽ�;�!ψOa����yG|ߦۇ��O)�v��_Y�aw������Wk��o�ܬ���Ro5r�+�S�\�3�ͣ I��c���]�Q���1����aMz8���S�>m����va^���sa{�N��@�������#z`�Nyv߹Dt옎qI�v����v�Yk���?�������ݳH+�_��t������~�W��&,�x���j��)?�����Y�d-�5'@���ȭ��Rߎ��dlz�v��Kݵ�_�V���V�� @6���f��T��g�Y����6R��!��ɿ�C�D� @�NO�(���W��ǁ�H��E I�Dger����N���w�:��D��<�d�jGǽÃ�(<Ϩ�قGK��ˊ��ZU���^��e��az4p�r�����K'C}l(�,�O`{���(�R.���A~K� ��i]��XX#mdR�&�O���o������#m��IWMl><YGMp�������x���M�����(���	]ht�?A9,�ǝ(��&�CE�t$ŝ�� "�+
�h�5�|z�4�P���≚���}0��r>�,�k9��{q޵j�S��<�)Oy��#��SԄ� � 