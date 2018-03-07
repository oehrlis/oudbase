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
� ��Z ��rI�*��}O>~��p8|r@���&.�+I55��3�����lI�]@�jU��)��	?8����/��?�_��_�^+/U�u@$�ݕI�*s�m�ʕ+ץg٥g���r�^'�o��-Wj�/OD�Vj�r�^�j��i�F��?t�0M=_w�)�c�����y?��?�ԃ�w��9tϟzE���=��z��? @E�`���H��K���_�M	Q��{�RX^h���Y]:�3׺��#�7���Գl��Hۼ4G�dl�>�-�N'�����vw�tush������y&�lo�-�^!oF�����p�I�W����t�Xz����Ydi�(^������]��696/ܑE��� }Vt���| �}g�;���Wt�߻��i��f�����n9�`YN�K˳;�E�`�N����L����]k��!C�\�Ĳ�kv�$��D��k�S���đp|��9��y��4�-{tM��i���Ӿ�\Ǧ�
�s�L}r�}� U�+��L+Ԇ�.|��JC�9���؈yH� �ͥO+���q�w�kY+������ � E!d߶|K�K��a�<Z��i��)��
�2��	3;6q�)���,�كJ�����C��=g~����m������}���Y��S���C\zE��oh:��}�;r\��t�������ѡ��������.�f�}�:9��w�g�o;y�`Z��{#���!X�A�LL , ��q����:���F� �j����;����6��Z�ȝ����O;{gǧ�͗��$O��?��W?+nJj���j>�=k����i�;��y�ɓSӶ�Y�����0���٠k��>��[��v�����N��quX���E�szz|�[��q��d�^O�>"�}���[���v���>4�7��(mm[�d�_�K��)�B���Q�9�$����찊7����pq钂E��ս8q��yI
m�-�F�>��>��j�r\�5 �K�!�B
I�N+'�>nc���[J�ˤ�	+%���T�a�?���5'#�O�R
 ��a�{��C��n�r�>n�P��7n
�ġ{OȄ?��$�tlZ0�؄ؖ�T��R����7HnX>k@��C��>)�/p�s��{#S�[��o����~������Z�/B�˗	}>�r7���u�K�!�Q�5��x�PK����F�3������3�$�ov��$!!M���M��{����	6�}��0���]� �A&:�-���~R�I`s�$_H~������9���	l,�%$�w����͸��q��w;��|��o�x!==M/j�)Lw(}�z����*���r��콒���D!����
��1�&Ov	g��Ad�¬��������6�"ʓ/�i��.�Ǡ���f�	����k�߮.p��Vc����Ҷ�R�m{6+�pn�{8��U�i���c�qڴ�i{�2�O_��'7r��{��HyC@��DI7�@� �@��0~��`��m|	�=N�5$�A��F��"u��6�=��J��E���&�.��.��H<$�ؙڔ�����^�taqM鶆���w���\Ee�*`��[�Ƣ��s��\	e ŀӷ�N���=B��^��
����:ws��Ս��Zi1Z�g���P�ԭr�J4m�=g:2(ߙ�/؉���-��� �W?w�Q*�F��s��u`���� :fr����ׅ����P���+Ngם�6�/\&�w�c�V�U� ��$=ju�C��(g�e�^�"�����Z l�d$�;���佶���8(�%,	���',�SiqYG��T���#y�Qđ�>K��%�V���h�Dܲ�����oooDN*@!ٕn�:���G#GY���Kv��m��f]O��
�YJnb�_mө9v.��6��fk>(2'�XYyY2�˒=��,+0��35�*	�SŃ��9�އ��C:JwP�Y`%�qJ����JS�\�ojH��������r$+LH�%���C4��E���)L,�(<��9�R�l��R�)�	���1�(&劳��q���݁EH.h;T4����%_���ߐ�y-7P�U+CmX�
.sI��+���R�pK,Py` �ވR��>:C�����	9�c��>
b �U�G����2�
V2��w�F��|��oq��H^�](ݏHos�����Jg�>e8)���a�RP��;ԭ{��%��]}B�J�j�<��s9N�`�%�.P(6�А��:rq�I�S��l*�.y�|\O��mh���V-?q\~���]z�#<�]@�a�<�K��Kk����Ng�E.481��6�%�����r#§K�rx-#2���	�emc>&�K���!��R��sr���:�˅X�:*V&C���l��>�70zF���?�1�����\���
������J\��Q�<YUAs*A^�`%ê����LL���;��2;����s����s�?�d��]�Ć ��N	
��!� 1��>c��Q�)���f�	6�+���D�/�,��S�'J�or	�+�����ڼ#7l�~÷�x�Y�P���F���-X!���4��9��P`�Ʌ�k��O���v
@���~>q������aK���#�#h>{,��$v2�.p�-@�*RE1<����1����yMS�s,���r���h�n�l::����H�i/Xd�+�y�T(�ɘ�~t`{z��?B^��f���t�[��DՋ D��pz��O>2����G/��{�DJ/nR`A���	��<׎01�j�`�	ۆ���.TV��O�t/ἅ�ו�d}�2��O�bY���i(uo"�p�J�qq�J��Q��Op_��~xT��GEc수�C��G��v���[�:2��$�[�l�L�?��ź~������?�|��Ϳ������~̿�st|�ك�aW{��Z�u���_I��-�paJHYW+����kX����%�:��Ze�;��|��)� 7xa�J�3u��m����^]Y0;u-��ϟ��4it�C�n�Җ�&��v�o��Y��P6 I���EC�˰b�ӱ�0#��U���;BK,;w����Փc`�[���#y�I��tcl�ld��+q�R�0�KiӚ(P�ì�*���g����_
�_����a'��#�))K7כ�7\?B�����z%�o���ٗ������?��<8�.�Yxj]�,=~��L��I����r���S�^)������?F����H�;Xp��o��+"��dF����~o���~k�hA��]ǘ�	'�@�����ٷס>²�$��>��V_�&����U��W������	��
�PᎩ
w_�|+�0<Z\e�>�ڋ+k��| ��M���RJǺ�>ԭ�r��♎���H�LG:ӑ&��t�#��Hs����3���1O��2�9�3]�[�*/I��)�J3��_��$d�}�;W[2]ђ�@��L��X�d%J x{MIv��ȃ�B�w��U�|]�n���2J��u�牼_Pt��o�ޓ�p���(��'��W��d/2�	����$K	d������"��!��t��8cЂ6�`�VH�5�4��(�1	�=j�"������Y��n����t8����"���.�ڟW�B��/��-�`s�و�E|~h��v��	a����{���8����途��Ű���Y���f�RS�k�	�RB�+� ��{���(@ԡ�s
�jQ����K�����{lE��j�VZ��&�����+wl�%Z��x=��Yh�KPe�\��!���!z@w������s�ۼ��ܲ#�<�o(��6���혾)YXjk.-�L=�	qPaQ����x��kK�p���UQ�CHAWC@^`�&�'���b��٣/�;(�wXt�r�+zT˲(�P[�z�
�R��1�DWXB�U-� �t�I<g��M�g+�(*ѫD�N�V�����Ŗ��)����D��=U�jr	�Y�=F]=�����w��%�B^��s�w��A�Y�eV���X� �S��55v��nVɁ�^{�n�7��;>�m�(����*��#��_�0����<!@�0^f��>��>_��(��%���J��2��1���n6�~��YL��yд��ˠӧף�zuq���o����9j����������X�����i'��~[H/q!E��f��<����E�ol�h���k.1_��o�kp^H��/l�� EF0�*D`Z�ѕ�)�/.C�lɦ��\ƥ��z@�_DE��9�{�E��gإ�ɍ�C��|�N���ŗ1 �D
����t�,��8��A�4���u����>$��ӧ}�q�}<���}�my����H��cΕ�	������'J�E�j�(�a������.*�xh�a�%)7Cfs�:���B�\����ɥM�B�ndN������"����Z�B��x:y���z5��ԪM����2����2��'���/E��u�׫��(��9����rS�s�����t�=E��[��c�,��<;��Bi���Bi���l�?�Z�ٟN�Go�딘�W�4�]O��;����m�p`G�qt���H�GӜ��LPup7_(�����V���#}�i���5h}�-��/_�6�h��Fp�������i�st�:�tr_�Nn�8�ɥud:��Nn��[��trR�͔r3�ܻ)�r�.���)�� �)�fʴ?+e�e�#�
i�kg��y5Z� TL����J��t�i��3fZ�����Xk�_�-�5��=�B>
��֏d�m���OeXl�ܝ�Jť�Ҏ�d~��zau�ӑC�8#W����T�;��p�C��ǣcI��6��;>h�/�f�)�~����Z�Uk�oOλ�<V�9T
��R�|�G	ZՉ ���Y��&$V���3N����o�ëY���߬r�r)d�K��0�������j"'��i$�|�:t�x�WȺ�����Rfk��*Q�������ǅW�����Q9��y�*����f�>,2���նH�b�T�UEI����::x�s�5�q���GJ��i!�����Eƨ$��2�E�;���&/�z=�k"�� �nѷh�etc�Ю�W��Q�ZI�3���wt�*}�(�_�k�X����!�x�&}6���qNe�q�G+�q���q����E}���y-wV(��L����^b����ۭ��`���%�Χi�#��@}�=����4�S�[d�?��E
	�!s��%�:�'����cRp�Wf�����n9r�x�usX�3H	��H�������͛��z�"=���W�P��x�Y������r��@��Z��5����6j�L��Q������>{v���q��� M�����O~�����-�uvv�>��~�E$������g����E}2�ő��� �g���.���g����}w@�x#��gy޿ay�u$/�0�F�m���=���?`���?��7��ѾΤDnz�:f��FUkV��V��?J��?���#���9�~0���E;S��
-7��d3+���)ǭ@8]Nd?�Ra�� ��C�g��LBsN���&Z� С�#T�6��	��̕�^/y��B|��뮅�5wS�Gh]�������L�>�i�A%������B`ɒ�����a^��X_���V������ӽλ�8tFO�LV��;4�_c*��h�5�˥9�1�y���L�R8��@�z�3��x��_ h��K<����\=&��CB�e������ی`���Pt��͋�D��=0��kw^��`�6�C@o/�R�[^���R&v�Vs)W�<�te-e����ራ�k8H�Ԍ��{�9���������Aʅ7�,���Ss��L�9L�u�9<9h�u�</��ea�����۽3�jB�KP�m2*$�,��V)V�Z�Z,�2�>�aFf&5>�P�����<������a>��ە1���3q��ZL�͍��R=�SZ�,�����NAR��Y({Bפ��n�V���vlW�՚30y�	��n(���S�.� �g��`g�%��2���ԩe�M�¦Ϣ��"
#X�</aKD�87�z%���w zH���ǁS�.�0n���B��&OG�F?��>�+��&A��>`��uh#tkU0&����`u.�(� V�f$��|�q���W	-�>�>�L��!����&�GH��U��bs,U#�J�"tR�J�
œ�V��\��?��o�*�Ϸ��G�RgC��#�O�%�P������Ι
U[⍈��ʔ�9�p�'B~�r�¾M^F"bO����>�x���.�O���Tu�Q�OfJ�Q�2(HY�6�[����+�Jf�S�!��R��u��6%���O1 `�sM��D����z��"hi�21n;k��Q�H����Cz��� zx�8�[_Mr�:������n9�ʂ��5��8��nHadFty%Z����>G�����F��b���w��f�@fO�j1�`uS���@!Tf��t�qDޟM�M$��A�L� w#������5��crc�v�[�e��)B�������y�J�
crCb��I`�a�K$E�@�L�A�nBO�\����\��!�5"~���0��40�D�Xێ�s1L0#!�)��}�4Q�����@����B�jN�ǵEf��(�zo���<64�u>��~䚰�@@Qj)C0�=��hF�2����!)`��r�<$�i'z�HT<������Tr�6�l�,�K/5�k�G�o�O�v^+U���20�m. ��O��	�1��8��j�it8���q+j��+��G8��>�=��k� Ut��A,U�>�D�8�������G&��W_�.@�;p4	�Ǝ��%܉a��j�
W"����H�@�^�JBm�E�{,�``
�%�D���8��o�ǵ��ٲq��׃Mȼ����L�8#�Xi��B�D�<��ґ?ha#��[��d��k�m�ʡ�a�)��pN�b�1���T��/�Ó��.	-��	��ѽ(v�3@Nv�ӳ ��+�5:>`S��z`
�	�~!��?����M/u'gp�3��5b�8do��9�i9{��x��Ǩr{�����;�?=;#A���	��p�0�<*����\C�6����.���3q[Ȉ���Y��cV��Ng�V�09��<�ޢy| ?�G�k��U������8[��ǭ�R����y/(�zd�So2����P��FEz� d���p^��C��Z#�U;1����as�W�Qވ�dsE��Ǭ��4�*��)�u���Y�7��(��@�['��3����գ,8��U�����A,{��\$f���X�S�΂N;'�X׏�Ӆ�p����߃�����MAm��RI�IءU���������	QSZw0k71k��0����t�?��9�ķMy��[+WĐYˇ�8و��3�E\�t���$8���Yp��c�����b_�R^={��bZ��L��y�5�.�1H������&���m(����B�;�ꆼS*7_w�Hy��4%�3����,L����A��zU{SZ�$b5�I=�� $�k����}S�{䛂V������=<)�{�%�|ߋ���W�t,��wMJ�	���E$	>SDF-�<�i7i���ˇ�fҌ~&Q�6�dq �fI�b����`8�!£�О	ء��=����TK�5��|ިs��6��)�������&=^�n��k���fVƾ��<X�eP�0*�W�F������L���𣏕�t��P�Kz�S�:QV�|�11��G�y��a��ҩ <��<�ڿ������Gw��_>�%�N�P(w��E�)`$\�p�jn�h��j����g��2y�0{B��dd�(����!�]SQ�T(��5���÷CnCLeKETW���k�6<zNN>#Kx����e��.��KVh��FX[�J��eEQ9�H�i/+
6Y+��;)P�"�ձm�ݗ6K^-M�D&��
����=�M��qN�!����9V'����zjXfm�����}�*O;'�Nʢ�e��-)��]�S�kg겵VL�H+�&�
�B{TZ��*�+��2Q�&#�t��#]�tz���G�nm'�aZ0o��H�Kg��y���w����I�$Z��HX#��B���+�W��%
'��Qe�tR*�P�ē3����M'h~΅A�����UY�~wc~�ٍ�v�a�����~O7��Y-.���V��K�������GL»�鎄�;n�Ò���(7�F�'xӞ(,���|������(@�0G	"d��f�&���%#
:�B��|NH�B�����g��&�m����P��M�.`��� �ߛ���a!�y�P�;(�]I)��٩&eBv|ɮ�4����%�	u��f�#��>n��y$�l9'g��'�+��ya����)]�U�nњ$����ǋ��갈�|FU�r�f'v.J*��5$�Qʺ�e�	Yy@�XV�<� ��$��<);�����\�.S�5���	[1t�(\o��Dx��q7�8
��TxB��[�NEI�J��� ����n�?&S
�; ��P���mR��8���+����,wg@�U��y��`�$��E1��)�b��M�$�D ��~���x*	(�ԧ3��\�w�쾖�Ro���c��HVd
�F��h!�i��|�@"_�`�8x���"$���Bz�����ky��%�Q|N�!Ix�Eǡ�:,��
�X��Πl �����Ji-�g�	�m(0Om�n&���V�a�)��gک�=�| �F��ǻ-&I����׃;č]�������n���؇��bF���1@�������sx�w�V�fS�<2�a�2t� L��$#�� ��$�D�3݅I�+��z���JяR��X�I���s�|L�$�V�i�b�ZR����رO���]^��۹��NM���|^z.�wI�ZY��>&��Ç���퐱��/6���m�������(j��Ƒp�`����d�~�Ⱥk�X�Ra�䅃 y?�Z/�5��Mjs\���ʄ�6sM��vP��|�Z�P9��F�YeCJ�;���.g�7��JXL"Ì��z�>��(����0�"Pj����:0��0/������v�F�����,���0��� �����L���J���ˠ/nt+��m�.HYh�׎{����٘'ځ�M�|����%��M�w��_-|~li~��+{&U��8ș�+� �D�wu�Э5o�G�z>K@v4u#����	����@r0'q������f;�_���.�K�0��C�nK�1�ۼR83�o�������"�\J�b׆.f��Y��F��b�ns
$���)T��fs�Et���МB��rs�.]%.�����b���m��Q���v�q�Yǔ��+N1H�sW.�� gf7gǪaz��rD�g�� ��J�0-]R3�&R�X��	̯����(��(<\`i}闊i�}��*&I���dc����}E�؎��`�IN����	`��=�!Z���9\6fŮ�B ��3��.`�j뎤ں����@�%����~�C՚sSD&��5/-؋iBe8��`p_��~4�0�a�T-9�O�ܶ��#�όb.N��*~�g!T#ф3�k��rk�'0�]�*�z�ғ��%�'Aҥ�%��`=�vZgAhiԭ*p��boB�,���1�Q���^�
Ң�~_�@E�l-P��:p���Z�N�sg��0{_xL�>L�������a�R|y�h~3����d�����zt˺/���2�:�N#��'���<��s��=[��)��H,w�X�!�\�L��؝T�֞e�}ڑ=�����NnKo���@y��XDr>+;��>ø��kR�r�zi�����KZ	�L_�r>��-Q�c�iMּFE��Q�� X#=:�.¨[�����ݯ#��;�T�\s�4�O��쏇75�<s89�=�7؉�R�:�;��)���Om�b��]Ll؂o�e�r�f�0��X(B�'��]��!�0�9:@<U���nE��+����m���b�g$Pa�Ef�-�����J����|�$�ߡHݍ�e�cD856"��Ⱦq���:�M� N���ű���X��J���IY����3R�a������s_��ST������l����W��J��1�J����jQ���ǭ��[�ؗ����gʮ�~a�a�$���Fn�Zq��P�?,p?�b�� �rx�Њ��M�������Ik�q�����bu��G��w�?��a%���^���,��/����1�߳�)m���ﯝ)��ƨD@{<��Ǫl�,p��K�:��_����^ǆP�������Tj9�)�m��<0avMe�b�q�:)���&���&��f
Fa�W��WV�jYhLj��>��/���A)�ͮ)u���=H��C�?qf�����y���s>,�̍0��N��$�<E����v�j�q��Bv���c@�@�ҁ�����7�ѧj�	�`�1kl�t��
�y�zC��`�B���u�H�i�+��}��2�)�2<fd�r`��O�������#�
�ئQ��Q�n�@�r��7�.t��¬l��SK��Lϻ.u}��Z�wA�(�#�;������?;k��0K++x�4�D�+�P�N�Z���F����q��p��s~�p.�aZ��\ 0IoiE!t�8�k}�E�a����G��	��v�Z"��������e��]�Z5J��H�"���
�VЪ�Zm���Sߢ�jN�0�P�I(��='$墶�����i�N����#v��sVᷞ>47��pq�~�ȷ���d&<%���"�����;�#x�����q�凙�iE!T��%�g��c��1����]��3m��@�z,ݱc��E�T�&��dEr�[%:�;����BΨj^�d3���zc� u�2�9}q��E:BHL�Ⱥ�$�Tl�Ua�*ЩpR4�`r�`n��
;�Ne������a�6%�!2L����pw����c�T؛7-6�d8�Ԩ�2�]Ȩ���U�/6��jLX�sjd뼤:٫��ZD��զTZ�$T���ʓ�Ӝ���>�Jc�0F&��ܺb��NA�!�'wH�Ob{���&����[��I��J��u�q�E��G�����
���9a�����k��I��±a<2�6�K?ǝ�9Y��$��s錀�n��n:� ����i`Gz�@�5��������T$I܄iw�!�p%����%��`�c"�q��H��#�����*�+�q��w굝r�v��V,˂#YJ��_R�� i�=��oiM�E0�#�
��Z�RB限��E�ntf�;��n"�ȕ����f�$;�x�%j�����2�l�����-�$�u�>M�A�S��t�\`����f4x�q�RǟG1]�j�
��2]�b��I�����0}���Zq�X>�����`�q�K��3A�}����K��7���,�pS$t(F�Y�f�s��q�B�;�Լ��T*N�P��Ք\n�u�\p10�����W�����md��ٵ�ܫ0�S��/g�DX0��f���ۀ�^�2H���v�h�O�3�c,G��K�Wx��KR<aW����&��q�k���E
8�Ror�UB�B�h�f�a��|.�pZ�cd�r#�W���,����G��%�-
�����I��s�?�N�]��T�3e��'��4[�\�@��[�>�_��s�p�����f� ��7��@�
��~�L�X�	`��a���,��?����&c�a�0.�i,�"�� ��L�y�y�5�H}�LR�fU��*R?�1�hI��]AP�d=�ԻA�����N週��#�T&O}�)�Ĳ�cY����־�⸥E�]4�lZ|و��-"�!EyHh]D4d�9���D�¼��
5ͫZ6�_��C���}��f3���͋���	w�4��w3�W�ڋ�'X�?E���9j��j⹘I?�:ȱG��=ߜ}���)QP���	��5P"E�1�ϋ��W</�Pe٨���=ݻ��x���]�,���2ɑ�1s��C2/)(�g�F_�(�9~��sVɼ�uVVЏ�$2±n���7�b.��:�k<WZ(����+�����hD!���Ƃթ7��4���ɸd)Z=�(���Pa��#���f$�e`�r	�)$�#�c�M�&}^�*��"��a�@x�7��bqhƚG���l2�x.��>��a�B&�+�� Z�b{e���2ЈK뒊%�_ �q#�d" �>�%n3�#��p6yt��"A��M����\�а~5�a��`yM�3~��$Ŋ���Ʀ���}� H$}!m���T�dLP�#_�O0cH�e����^��+|��9��YG�M�q��,�;��#��J��"�8��Z4v E�*��C���yVm)_L�A(�V�4t��&�y��nZ��&��a����
aN=B�z��bUXʄQe[Ct��`�`,z��-��:�D������)�|(�P�s��r\��]�7A��*��w�Ļ�W!$�j����BݿP�<�Y�0�G��H�ʜ�ս�>��S0.�;:�̓ؒ:���M��6��j�:�&�L�]�֞��!W6��dN��/��v�e�[#_7T�����4�o~�ŠE%b�R��b�h��SgO��b(gf��� �A��cT�;������	���6��$o�aE� ����~P���hE��D�d|NI+�tKip�:,b2L�f�.M����k8�ru��#�{���lP���ݜd��QBM��_O��uv�mk�����M���z�L,#T-_"o�վ��H_�k��-��	7ȸ�x���U�t'���%]�z�����"y������L�t�Q��*Jmsv#g6Y7AN'A�*���TDK2��[�ʓr�;S�g����՟�*��xbQi"K����9ؽ��	m���������F���)ƍԑU�F6�䉏sg!��2�؉�==�6c�6�斂��2]��)�:�D�u�(+Aw�Floz�%Y�����ۼ��� �"�=����!C���a{9YP[�Gq�NI$���,���V*.��R�o |g���R5cr��G�*=%��
��ܪ ՛K�ߝ*娛T怮
��$����)�"��BeZ[e��<�Bd�����-*� \� �/�RI�)�"'��߷6;_��m���A�J�ʚ�xE���[�Z-R��U�B�=E��v��юZ򎒠SoYʎ����6�>0g^�� fm�\W�,.l�-����c<s��+�� =}l���@<a�oTUP@��@���C�	~
��v
���VP�d?�PQڦ��Jj��Jd��t]�h��8�|4�r��+~�,V3=�|PN�gz���8����6N<}��K��������oǳKi���-��� �(�* ��D�]}�#���^1@7a\NCey�*'P�X�qn�J��y�	.�y�JM,�T�	.y�M E�'
ej��E�$��J���H��f㳘4r<�|�)���+�W�rR��}��bx)���X���"������������}�`�9��hG�ݱ�%��"�7� �'���u�3-�`�c�5S�,8�2Y]�FE�f�6���kdR$��@��z����� ^J�X�|��&_ד��V����@(p>Ὗc�	�ާA��A�Mp��@���f

�n1�ܮЙ�`����]���R�?�h���~LǛf}h�17���.x�t�)�iʈ �)��x�f�BCgD7�0�B���T��O�["p��U��^I� 	<>��Ú�Z�L�1M��X��C��1�@����z&l�-�e'	�q`U1;�7d��h]����d��YA{;+��-��B��<gcX-\c�V��\�#G����z��y�����(�P%��t��O
(��@��-�n&�)�K��c#���"]%0�����iooZ�B���hk�~��o�T�4��D�!��%�8�~���J;��s�#T=����1/ܑ��X�,�M{c���OoQ��6��X}������^��G���Z&�5�-��7�0��E�'g
$�8=z�ÄN���"D�ɷ�<h���UQ� ��;,�����^��) З������6�ܘ~y^�4��C�\�/��C�����J]��?<F�Lש��%Z��d#�QON��1&���蝖������[2v3�
��h�}Zm�S��c&������!꘳���j��O�����I[�-�������`�n֪�r�ޫ�A�nV��~�a�5�b)�~�R3�Z����n6�ۍZ�lloi�^��݃#H�L�T:�5�*�^�ި�ʶ^nڠa��z��ZC7���Ѩ��ҡ]B̀��Mc��5+��v�^� `���A�-�>�M��ЏmT��`k��3���V��U�6�z�Z�mo׷̊�5k�>�LV07L�k��mUL�уT���U�h�{zu+nVT �l�nnm�j�ZO�25譮5ͭf����2�3���ވV.YFlo���f�7h���@�i�F;�]5f��7��@�@��V�a4ڠ��2����+���h��r��ܮUZٔ�E-.jfO�o5봭�����Q����U��J�Y-7a i����4���4LņޯU��v�V3��^c�7�Va%�D�fFc��ܖ��~�<��+}�
��Դޖ^�5�^y�i�Z����8(��l��Viljխ-]߂�F�RnT��^u�,k�f�^IkkK��6�r&m�aloW�0��^]��$hZc����kF�H�"�~��玸v[,���QתFo{k��v�>�m�V̈́	�՚�A_rP�%�P�	LXQ�R�L����kZ�R6�j�\��r�����6lf*8�t��W�����땦�� /�w�����7�* ��^6{[�^�뀅��V�lT��V�����f��r��]�E�XĲ�P��r���6��V�L�� �#���:ڕD�F�Q.k��ZӬj�ZM�`a��˵^C�eV��P2�Z�]��U�ۍFS�z�ެ��l�=:Q6���>����8���x��L���E�?ju��
����2�������e�1���ᙟ���$�?��z��?FZ�e�?Rs�e�W�꾱CV�6pS�z�I^�"^r�1�3���ߒ.�I��jw7�LW7����]��LR��$[@n�����;7I���2]t=��F�t����Z>�oM���﻾9@�$*m!��m��<+2	��}>(�����ҫ���1�ɫk6md�	��rj^Z��Ʋ�,��jmr���;� ?!j��D�e��M?��N6����9)6p S��@����)�~��,�c�ށ��v��,V�Z�ā�}�v�zt�(/s�B{�Zn���s���P�N�#�o1�X� ����и�I4�ꙡu"*��y4@.^W��w�:f7��I-�)��4.ܳ)Lp��y&��Bp��}(��@���ND��6�ׇ����|�m���p�Zg��GE�Bs�8�g�0<�Ā�	�wH���-$��V4�6}�K
3�.��;�Y ��T�m��B̫�8E�ky4����4�:>�}qE.�òN��+�͇ɝ�H�"����:��?9���N�i4J�׷��v%U^�Y�n�d�HE�7R�jׅNl����(r���B�L���f�n;,D7�|��k��2�U\	���⹸tj�m�"�,Մ3M�����w�Wi���j�������3��������>{v���q���������O~�
?���,�uvv�?b��?�<�埄��pEtoG�u��8:�X9�bF�����;����{�3K�)"r~�:��f�֌��j���x��P��� �Le iR��� @u�򚻕^_���?I3�xJ���!.I�@t'�[�(�1�+B54�(�6��ꡅ_��j�����������ҹ�}����[��ߣ���7\�E�j�k刺����D�E�} k"g߸�D������]ɣR�x���\�&���Z�Џf�R��aދļR�Q:0�	
s:��ɑ��W�Y(� <��N<��XD��t���ɡ7�{�G�6o�$Ih���n����E� t���<� ��t1 �ʋkQvb��������N��0�S�X����wiE-#ş��]��DÞa�= 	�Q��v(v
b�S�m595���↓c"	,�jE}�1������9ñ�$�+D`�oD,3B�f��bՅY/DN��o�D@@2E�_���_�4�WI�����y%�.<�˹��sa�r9R�x.�.���:=uX�3<hD`�T(�Bq ��C��dc�B�wa=�F#��2�G$߷wC+�Cj����{a�GY���)l��a+l�
J:�����
P�R4�;(�tO�����1�;�E��t:ҡH34�s&W>G!b�n�^Q:&Bva9 ���k#
�C�}g主��w��k�X��u���#���/4�X�)9W/x"O@�n�\ք���<�(�=ވg��{NMy�,�&��Z�qp:a}�=�u ��˳R��U�����TRq@����0���Fhq%������;=�j��O�O�x	m��h�4�8���H/#m/`n����»�)�ITݚT^��dOG�/C4k+\��9�c�j������Z���u���.���
$,��rv�.�X8e_���J=���_Y�o�2��U�Z��5R���j3��<J���6�������r�~f)1%��.��9��l��?|���c�L����_E��)���gH���`�UJ&�{~����ċO'>#d�Y�#�Q��������>,%9A;A�C˜��c����J���V��βVi�2��Q�
%��s{�I4m/t��{������	�P|X�v��5��Ec�i�?=��i�]CLu�z�^L0�&9��_�n�C�{��an�k�� �;Zuk{GkT;5H;[�����4Ē�[�<��^������Vof��QRf��$�QC֟+�b�̨g 3�\N�q��ܒY﯇�f��^Ч��i	�g>t�����5˚F������1Rh��pu,8��fS�ԩ�wp!���H/-R��������$�+��Ա������r���_�׳��sc� u�~��+�l�#�x!Zjs�?ZYk���Z�Q����k�Z&�y������7�B��ޢE��2�q�A �-�y�߷S��S�h�:���c`L�{��c/�;i�}����wVi��b�����a) �r����s6���xL�¿.�w��_� ��:n���.�����H1�PǢ��V�6�M���Uj��(i���e�1���Vk��_�?e��4˕���e�̣s����=ߝ�h�\�� ]�i�{�;��u\���R����{8��E�R,�"�o�k6W�Fb�u���M#F��/�xh	���n�X&Gޜ``�e��c�`*�-�i����AX���a��6h+D,>��}��=y����SΎ��ŰwKj)COb�Us, �9�=�iJy������x\ǣ�agm��w�sV.�! L��٩ �p� 0���X��˓o�Ԋ��1�F\D@�l=
�Y1�um�Y;�!
{�H��U��=��W��S<ۥu��}��b�+�ܥ������V����O�p��M\l��o��y���a-2/"ك���8a�P-�D���͍A�X�hn>�a����$���sqSr�A�к����X��	%	��:�o�>ji6s$��<�c��1�b���ʸ�*�#u$-�p|�
Gm76N�O@u`�Ξz���S��%�1���]0v�kf�����㱍>~��^�@$�VbK�KQ0�c��ZQ+?��Eĭk�xS`�~8gg�qr�g��x0�g�_b�,��2�<t��|��������	>��s7���W��,��y�Zl��5�����l����E�<�@����}g��KMX6�+��8�&�)Ffnŝ4��с��p���ʁo���O��c�F�O�zqF�#��~{p@
c���Cn�����KR��9;��V^�V�=��:�{��K��O7����fu��Y�l�i8���N;������2�\���F�R�#�|���K�n��z~�4'��R����Y�g���5�I����_��=|ZڂE��[� >!w��#S��3`P�E!�ĭ�x�M�]����M���r�c1��% �X2�G�7s2&޼�F��e�!.�[FZ�ͻ�6�����6�C{�Ľ�r�Wj��u"�F��Wa�5�Qlh-���B;�.uF'���uz��Q$-�GX��^������}
�0��]���/Ҡ$a�P����Q�{S�!�I`������x7��R��]
��L� y2T���G�a�S���]�����j���)C%cݞ꣙�������!;	3���,�
�F��)���,o�9�ɏ���;O�$��p�P����iz�c�8����Klw����ɰ�� %�eC����]����c�ih����7��C�{���������,X�f��vyt�7� wn�����"V�n�-�e�j�?�{/�����\�٧8w��%�v?���
D�U̙�V��s&28h�m�q<�'S��0N��|���g���t�[���S��I��a/��9�_B��F�V����H���,�g��+�������f�?���Y���P�,��BI��9A-��d�u�����_�+���ެf�?%����?�|ȝ��(�ɮw���b��˽{�9���}�u;{oO���t��ho�{��~���O��uߞ����@y˵"��C�����]@�Y��z����*�F���ԛ�L��QR��=�����\�g����,�g�3������g��[���sv��ǋ����@o�tf��[ES] ^��0�I�,gžL
s�P˹�0煹\z$˙�3���DD�4�1��9'6f�7������������^��X�<�/<�U�����?%Y�%�a��Ü�t�(>�9��·��S�>K�M��_ˍ:��C<�g�Z-g��1R&���f�?3q�m�����������	t����l���f=��%e�?��?c��"������?�f=[���2��,�g�����Y�����x�J����sqA�< s��j����k��7�L��QR��C�������H��H0�	N?6x�V��0�?���a=�$#^d���d����d!�wt�
{�4��D��<�#�[�=>����]�n��4e,�h|Ԋ[��V����-4
�<H��L!�e�>
r��Z�H��ǜ��$Z���8|�(���d� ?W� ���8�Q���R�<�O�Z���m�때�{��]�F��(��g+�is!��u-`�)�f���"�Jq~-}s��߅�󇈇���q�9��C��9��>��#���u[x�P��N� ��]�wz�I����������9�����OL6�T���� ?5i�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)K)�kQc 0 