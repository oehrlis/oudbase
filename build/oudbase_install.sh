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
�  ��Z �[l$I�ƚݽ�]m�ۻ����э-��d/���g�w�Y�=��K,v��v�r���U9��Y��E6���[�-˒��C�ؐ��е�׏m�	؀��!�-�6$�����s����"Y$�g*g�Uy���ĉ'N��0���%?�Bauy����Y(-�O���bii����\\"�bqy�4E�/�b��]Os�*�������y;�Ϸ�i�����4��9�s	e��rƜ�?@�X��RX�"�K�K������O�H��Iv|`��h������w�#�e���p��ﻆ��.��G�i���呟�z�׳��ݯ��!O]�ۺ���h�������r�<45�k8�v{�ԏ�K�15�5�Jok]=Ǟ5�L8xY�{��/�~�YdG�8�A�lݝ'.M��4�#�w@�iw!w�ex~�M���;���[�OX�W5/([�dO?2\ö" ���;=����@3��t��G<��u���İ�iVS'��Ds��{}�4햎=a{�+j�߁qt����<!}Wo�C�!�ud8�E�c�=���������!+���:��s���6@��;y�c.�8 q}��
�C>����5�Y(�
��J��
!8
!���I�t�`��\��0������!��ض�}���]��̒u(��_jT�"���K:�vU�vv����Wү�l��k����N;sJ+P�Z�Ƌ�#M�Ua��M�<�̾�^�A�ǵ����vF3]ݩ��ֶ����ޣZ���L�jS'��&�|�z=྿S��3*��s��h�$]�M���������V�<3�n�!3������Auc������y9����M|��	�ϼR N�j���L&]߯��|\�Tk{����I���a�y%�~J�3
�t�}��tΒ����Vec�R�����2��G�����5;�����^���)��#��=�[M$��C7��w��E�Z[��'�¼�j�=S;a c.�ɧBJ�4�jo�m���~�C�X��A~��9$k�qvolMl���l�|bD��߿`�wa��N��=�<�B��8b���9�.,��+!�Q\�����݉�����t�q��i4)_J@ �;x�!����U����E�li��I@�u�!��x�%	�#Â��"Ė�|�v��'X�_m�<D�p���C���$��H�<� �w+-��n�U�Z�oxn�U锾�MXk\����/�~h�O�c_�b��#,ƣ<�K�nﲦ:�����+�΍��G��H��=�#B������	H��	L�M:|�X�6�_C�ST� v�c b�h�2@&�I	������� �yB�7�j@G[����@,!����<{����:���ڝ��;���HY����ZC2��r��ܝO�T��LF���+ ��Gd�]�̀]А�O3�L��T��`i͎��A��pe�kO�IV�棟S�W���`0��W�cz����{Zk,�'P_Zז�q֖�
%m]l�S@��F[۲-=ʛ�8l��ŵ����J��y���})/(�0� ��6��Kû�h��#<���,����/��k.rWXi#ҳ̮�8pT �A3�:H1u�<�-q�h]�oQI\s�}�"�9R��է������A`�rr�Q���.���_�_�J�� $��e{tP]\��r�r��@Q�c���Y󥛃��z�㠣��J��r\ݣ��D�H3L�����0��}�E1xv��a;>l���g@c�Z�<�y���G>'*)�[�޺�}�m��azKο44�q���:-*E�ه��e����-��j�ݮf��J�@�r%=��0�[��R�**e�=
m�(��WTA5X��X���S�6����(�)�O	�ؖG�O�h{R�5E)jG�Gr���#a~�C���+�.-��Lܰ�k�m������|h��	*Ɏ5�҈�{G3M[��?�vY/,��bMO���,%���iO��G V�(P�9�g����,�˷����7Mdz����-1K�����AX�lGkB��~[Ǝ��qfYλ9��bdXi�3�E2�4W��<�f�)i����zH��h���0y#����>�$-D*�D*U�b�p�`a��\TT�T������=4I�u����ӕ0����kx��m�^�TJ-�4,k;���`O����!r�`I�R}����sR���G�|���	i.c���
f �U�"G̤���
U2���0G�r��Oq��IF�](�io�����R����M*pR1�u����,C��ҽK��9Z�d��-2��O�9ׂ^�t���X�BEL���B�@�4� �YT���dx�0��[[��������8�p�嫴�=�� �al?�s�Α�V]�b����o���)��t�4�i18����;c�l�Ȅ�d��]�PYC���{	_Ye� �̓�����ze"��ͫT��碱%2sW^����j��gDx\�BS�,Jɲ<��)���f��2���\��#�L�Y��b�����PV�
;D����r������3S�n�D� ah���_���`e0S�)��` �	j3����ı�u�0a�K�$�]���e3�Z��t��lr" �y����rʺ�'|���Z�����W��pշ�(\6$��	<�!�Yv��=t��R,;�����]���g�.��X�nC�Y��&�P ��L+@��T�
Sx:�Ʊa��g��ΩD��>b�f��`���I=G�I{� �n��3�l~V�D�����}��`�F�)˻}�3zx���>���Ma���/=�g�?p�Ϭ<�p��:t�@Ŀ�Pk��'RJ��v�2�L7v�2͏}�s�-$��<&sm��6M2ᇢzK){^�i�@�Vʎ��T.V\|���4��b�o5T��-b7Yn�6��]���/�j�0��n��w2�'���Ŝv���ޯ=��~�W/g�Y�g�w{@�f>�x���W[��\��m���x:T$�!�_VZ-� ��u��I�>��Rf��˓WШ��E�\c̀�y���9��WtSB��'�ʼ�zuf��,#���!�S����ՅXZ�t�F9�7��q2:c*�iA0i��a|f��;vcFg��}}�Bl�y��TT�7��"|����-/>�����Yt����5LiRҰ�*��1�K%u���xhe�O������������)�+K���W�O~���**�����R,����K�՗K
�b��CsG:�d��mQ'��?�����]����R�����mu�T(0������*����5���b�͍�5E��,�_u���r��%�~��s�VL�!�jTD����qx��C'��Jb���_mc�Z����Jm��F&�Wh�c-��pp��vɇ�C��&����X;Z�M�lHl򉔛�;�<?��f���=�Ol���F�Ll�'6�db#=����Hsy������>O\�&�C�Ol��h�<&;��*��O~��'����<�Z2�В�H���	��v�F���얒l�[$�f
�]3�j��*l!�	�] �4@3sB���Qu��-䟑|{���(�b'��7��l/4�1��3)Sҥ�:{����z�PƐFZj�뜃1l~�?bӤ�踛�T
������"Ն�����~�~9ZP 펃͍:�0��#2��������f߃�aqX���E��T���:G����Sh�=�i{� {44 J��lX�je�r����f�\}�[�	�R��+�B��B����;<�Q��]��bƠ�-sw������gX��ݙ��b~v>h����{<j���m�~�xi��u���5�A����.4���!�����l�_߱�c��+4@���>�|J�>�8b��l��tA�⦖?�"�2쪇�#6,��q��!1��Rʜ`'�tFdzpЙ ��_y���s=�s�C��b�eX�k�:��/����x8��\je�����-3�d��M��yuJ�3,��������[ ��w��,����U�t'^�R^P���"S��)���I�'L�>��_Ս=U/�T+��衫�ly��;�]&�eZ�V�O<p=���9�fY����	��ٶǸik9�B	�d�٧O��f�X{�|v>8�`��Ş�8�Uu��4A����v�h���0��,3��Yx��GP�g�D~ͫZ66�@hg<�r7Xr?�y%�����)�e�����S=�;4��mT�V�􂜴�w��*(�����i�a̚-���l�v=�z��d�8�!}\5�N�{�êpD�i�+�ЛU�k�gv�?�%�4j��B�tR�#�ѠR!fU�i�D��i(�-ٰ2�˨�s��@7(у�P��!7�6*�p�;������1)�Ya�]�H^��K�*;{k5_<K�{�A�	� Q�;��������b����>z���&��a�}�e��V��h�/�b��ck�O��cf]v���7��V.�+K$���$rQI�śz���k�l�Y�<L�.
��?2����T(���)�t�#!{WY�0�����U�"�{���wqyѷ�,.���gii���J����5���b������\���C�?��V�-�<%�}�b/rYW�"4m���w�C߳#M��&a{;J��[�]�J�J�?��=���A�Qb��3ִ��ӟ�j�女��ȶ��Lh�]A'�]論���t���f����\+Y�SkO,h�fZ�|���շ���?�#8Q�Zec{}��U�ޯlNlr�A�o�M��o��&��1�ɝ��Nlr�o�M�H&��܉Q���r�l5ʝ�@71��ӾUƴ��G��zk�Zw�vf�l��*��*�l��>tb5�X�N�F�b�Q~<7��(�� 2y�8K?�9���
>U`��.pu�LԊK?�O~��r�`5��}�&�8"Ǻ��XT�ޮ=9xR�}��#�\e��;��������+<8�����W�?}�{P��B�P�D�\�n%hF4'��"e��Y�j��8H��j%4�'�G�G��*��6?Y��R�j�&���v����k��.b�����l�{G�����E�U�D�2#T;B�0kV�k��_O"�#�^P�-+�G�x�䍛�
ft�{��0��μR�"e���\T6%qcǷ���yݶ�v0�#ԘwP3�3�7��~�<���.Ù��_�m����r/��C�&��p�mgG�0�m�3E�����&s<��F����~��'w���K��'r��f2ᴞ�J��^�Ǽ�Bǣ['[ߏ��g0*ɠ��rn������2��6y{ᐸ]�{6�Jjj��.�|�f]b�-�ׁ�#(k�e>�R<����a��1M䡐���1JYB�Sd����%Y'~f�0?�Inƶ-7��?��sQ)���;"�ҘL�y�&��gx�����|��7w�Y/����߅�Ra����P\\Y\��_���}{ꝩ�-�Iv��3��0m�&�+����?�����PV����7������|��ߞ����9��3���� �^~z��q|�LM�I��jMW@�x&���Ƴ�[��!X�an�����_NM�a���@���������ڛ�(��.�����P,�����2��W�L�\����m����S�&.��EX���F8����e�)Do��`wٓ�D�C!���~7����15�l���{C��u� ���:\M�Χ`�<�d���"x�9�ל� ��uΚ��1��0����������#cn"�3|�Cx�����r�"�޿H�_0M�ט��k��@�e�E�h�1�2
��)d ��w�"�]��sj�����P�� Fۃ?E�9�q/�n��=�����k�qh�)6��X~�v��BV@�ꦫ��G��ʼ�3J�OT��Q`��]b�gJ9��p���Z�:���FV)�e#�R6w�+�2���sP�
�� A�0�ҽf"��D��D�����fe�V�1��r���T��˭�ыb������9�K�R��[�"��� f��Uo<,g<��9��2�0B�\Y&�;@�F�4����S�(�r��]L^�ү��du:xLӤ�W9@K�H��+�YC:&#��"�@RÑ�eclrJ�ґ�P�rP^1�v@Y��i'�C.��G�Y6ޤ)n�4�X�,��%j	�[冂���:�W^�7H��M5��qY-fԻ�<�S	}�p���@��-�gg��0��j׆� ��P��ˊ�t(�0�!V�f(��p�Q���W-C��Bæ��s��F�q�p�`���KGإR�����rƠ@�r�B�+�I�qE�?ca_hG�Z���1���+���w�>?`�r�8�W"�
Shu��`K��x,r��=��Ž�����~x��9|��B�қ�@���/�f�V#�Y��q���z���S�+=�z�m���?-Y�%�t�d�NqV����Y���;)��t�
��|�����Ո��(x�Z5��k ?�t��E-8'4O���T��V�?F��C�q=��l�zl������D4jNZ�$k�!�]�WWת��?N%K/?�e =a�8
8 Y<�|�l���E����4���"�y}F2��L\����ҍ�Oe���ߏ�[Y�X�!(���E���r����)��*��)���$Fd�D���H���M�did��|��_չ�BBmF�N-�a�Oh�_ވ\.��,�7��ElB�P*'��=��WQ��X��p����fjM�۵QF��(w�z:��^��=4n}��]�=���t�X���5�=$a@�
���+`�r�=J��Oxk^bn	6�ቩ@�:sH6oF���*���Cf�g7y��;/���[b�6W�
�w{�I@���qT�`%x(4�\TQ��cr����CF�Ξ�0Ҭ�`U���Q���>��8��X�7�և�\��^��&��p2�������%ډP��j��V,����P�V^)J"mj+�[�O�P`�����ݙi.���Nk祳q���K�!ˎ��#	��2@�c%��4E��8nK{~�����n��:(�k&��Y�� ��9]������ja����0_�������Ÿ��Tf@�B�؆��9�Qw�iܪ,c,������o��%�i Z	x}��
��R�q-�aF��Fʁ9い쎹b>��{N�vyT���0�?�˓s�wCf�!��F��f�Y�$��;$�ԓo��e�2eT�������F�NH94��VH�!.�T$��g��A�YǛbo����_HBNĀY���UcV�.�Cق�B�3a+W�C�Iq&��&�N摳�J���eiLڮ)(lGk�����#bL�룣��4s��RA�ً�nXLx+�y�7kc��Lc��f�Ο��fcN"8vX�)"(��[g̀�aEG�7��]����HE���Xк
�A���x�ށ��j�H�=���&2��v�������0�~/ʌe>�6?̗��`Ǭ���oHz��'������dѕ"R*E�Ѵ�ϸ'�
���#�[O�cI�|�#�0U%�{E�
�yx�A�-JQ!��t�GTR��8?�� Y��(W�Q��dF`�kTX:#須�cX�!���]vɝl��W��%�����~����r��a4NH���O�'����R��|&a�4cHے��3����P�!���!�����08����a��<��������n_B�u���,����U��z���%�Aʋ9���(�!KC�e�'to��lv�!��x$D�7A��"]y&��Ȥ^'2%�W�����Q�Pn����K�1'IT����ߺN�<B,U��Y\��N�h��:��`����'T�!eJ�������!�!bz��ZR��=3U+��c^�K���Ј��Zoǔ�zgب�w��aXbG4�i��0�z�t�Zd6O71t�A� 0'��eQ��_��r&ߛ5�壖�m�����-�I�OT�8Qr�L^��1�W=�ҸਔX��"a�i��/g���#�j��9҉�w�\��cL��3�~	���������;��JC(V#F�J�(H�K�H���!������0� |1aWW`�H�_�������I�8^ְP�H�º���"++/b5|X{����r��������U�n���<����
�^���G�׿��1�)Ft�1��Q�0q��7�qd�0O�E�}���� �|(c���Y(i��ϚO�k����6�vKFnۨҨ�jE6A�wr��S���K�s��%�KT�ut3Fi���Pa1.�d��!�'B�$�I�F�����b7�� $>���l�=2��!+��Y����TB2��L����%㢋�S��pL�+*%	\IC��FT����vu�f���|F���s��p����l��|JS���-\��b�R��,�Q�,��
�o���TY[�C��2��э�����6�pcz8��XpHW�en "UL�s��I�=^:����mP�-����/�vI_�"��~�zd���U�j^ʨ��W�	J�KEw���^�}a��	�D�--�mw�l�����w2��	Y#�,S�,�q Y,���bd~����h�C�c���;��6;ԇ�iX��@����2��K���$$yU67*�[d
O��ܶȝ�ݝ/��f�י��]j]D�=%�ۣ�-q�M#���s�<����?+�gc����`����`��O5`��d�~����ϼ��
�`���џ*��8�i4R�rbq��8k��X|o��80�t�zX��sKv)q�Z�3�( �.�\b��hf��� ����Ax)2|+]B�%p�pC(��5j$%����	hIɔ��WT0J<�}!��%�
�E���eF�k�:��V�P�1Ui��vmk�YyFm�4��-�����.��e�d�.1̧q횞	��6Ƶ���Б�e���5;��krV̓Y-�n��)�y��{"�h������SȜ���Rf��� ��j/.M��J���ٱ�[̡�[D�<�8iXmeݗd�u)m~d.�[�@�la�<Gь��A�R��x�3��r��M������s0.~�y���D=x%�>COstj����h�C�[��=f��N�AY�yЃ-zg�זme%
��v�5���l0�z��a\���\Ӥ��+	������ǒƇƾ`iR�ю��,�D�1�f�s4�茆�kf��W������B�ť��_D9�8���Њ���V�_�u9+���K�]~�G����a[��"i'Ej�y�<���F�hQ� l[�t�;��BN%C�b��gH�x˞!�C���Րl!s$~23$�� k�!Y�ng�..������$aG+;��y-�W(�b�W���
�}��~yTe!�dfԳ�xs��|�|�IP�S�yP8];�=K��S>V�>�\͋�b|�s��ډ��!��Uʯ���b�pܔ9��Y���3k�5�ZnM��[4K�=<���8g��]Ur�@z��яX$hk)h�Zs��(�`n_q�/+���|'91Pg�2u(��$�;r��2�*L�xWǿ�ʛr�Uٿ}5�Y��L�k�	cd��B�c�Kܐ�|ޫU��H�h|���}�S� ���w�"�Ȉ�x�Z�ֿ���*�Pe�Lyր��Ej�ʈ.�"��Ƒ�4zY=�����ōU�A&�WS)��3,�"�i`z{xɺ(���M���s��(W{ȹ{�z�}��-lوHU�0��D�1��D<�u��;	\K�xl֚ڦ5��/<��n}�+<��V�0����=4��eP�XB��pkR���5%B�JÓ�K�}J�:��he亄��\�6!\�*��D���9�J�^��0�C��$�&��M� �>&�aҥQ8��w��^���̳؀�$��VK=�~˒��8�"~bF�Dp1�A>��ս��� t�Ll���i�{�g����h��Tg���c�[9�ϔ�TYh�3����P���Z�5��ߩ0Mk��XG���8�,�T�	'����s	�	�X���uG2�<�yZv3�e����2x�����)��ˋSd��+���<��?l�[�\�uIe`������_\]�?��_,,�N�\�3M�M4(�W���4��<�F�:�;�R���洌/��ۣ>��}��O}�s��w��E��΢"a/�������6����H�ĸ�r���2�
j&ڥ���/�yX�Άb��.p�Bt��=��w�O+�����J�D�.��� ݢ���5��4��4�`�� ��Z��#kXz�o�/)����v�DӦ��,�C�mGW��*�Q�gj]Q�o-�-P��}0��k;B�?�Mjc��DKw4�
̨�����46��Ԉ\:}W�]�5`�f�<�ݻ~���wy�,0�L����X�J�ѷ��>����:�SW�s�M���l�4�<���>MS
F�1���9H��h�I}>LE8
�׳�٠�ǎ�y��0d3Se:{d��iX��������j�u�Ҩ*X)O3,�i��4���hخ��l�h��Y��uO�u�)�C�w;tOC}u:}��u�<����q�A���c�~/4\��bt��_�cB7��]ׇ߇����'�4k�<�	=��`g&��}0�{�Y�6^P�_��W4 ����~�'OQZm�\�9��żہ���G#�N�d��lq񠸴Vzom�=�vbo�*��>$1Y�sFR��Y5���0���28��a�N���������B\E�f;G��o�|(���{N�#���s(� �[�G}����	�J�x�=XАZd���C�L�<���E��m}~��dt�EiQÆ�۵[�0l�>����|˨��%�2�i��|b��5쑔9���|c� eJ�!m��ȅBH�LjȜ����/��+�Ŋ@w�qE�@R�E�9��+h4����/҇��HV(X0e:2>�����2�mpawXGTXG'�Aw�W����^�G�t�/�{>3�Ęy9�D�ȍ+��^�A}�\lB��=��b��Cgyw�Z���]�k�Z���>������s�M�M��5�����g�m\$��yi�_jT4��h:�];�E+�]���w����?s�/۸{�3&:��L;�Ҝ�� ���!w+>�]\��9!�1��>G�	�uSh�i_���e��m��?$��+߁��#q҄n�נ"�<Hy���V!`0�1V�8�U$��q$�Eq�`��-��ŕ�bamyi��|6y��+�
B"K�g�_3W��9�����hIHE0��}��|/��&��@Lq7I9��Q�R~Ά"��$CQD3��y�n�F����,�|�,�"����x4��|������/�0�z�֚��#��ϱ�܌�BA<�Qb���v��R��&��+!�FA�ܚ������ N�/Z/���r���Ji � �c��y�@�|]��`��"9��c~�
)		\T�H'g��mp�g���k�T����(x�l��7�<��8��Qf�}ZGv^�2����yF���-�jG�I"��w����YP�O��P�p�5��Ҥ���x�����N�X����Hag�r
�)��掼�M���I��t�i<EH+G	i<;���;���o��\$�@+�k��Ҧ�ȧaV��~�R�+����?��`r-9%�b��u*&!�ێ�a 햊 )9&�}����I&hP�6j"���tѭ�ۥ�+��z/���Bo� ����~,fkZ�q�3 ��G�����3!�#v��gd]dd�>�8O}y9��)QH�ؠ�pR�JSd�!+�?/
*�̅�z>l��{6����}�$Z��䩗3���('"� �9��ۏ훨�[��Q�&E��!�l��D�+v8�f� ����	��+�4���(��Ώu��뷝��b���khg/&��n ޮ�B'.�� ]��(z��hw�gSm��&���b���� �2Oq���#ڡ���H$A���V'8�R�@���W&��͑OVI,y��A�Q������~:�]_��SªrWVP\t��Ɉq:�m��u�)\�ȓg���
�kfY�zA��Cfɰ�t���3��2¾�8͎���L1����5�#-Tv�i���`je�u!+���+��վۧ�ԅ?և�d-Z6=�(��$t��#�r�)%�e`�r�.4ܦ�"�$u��Uem��0} ���X�8Tc�%M������}<�qa�鰨!S��ȎG���&;\qdQ�����5B.$��B��L���ш*g�{G�.2���]�6{.�ʱkFH��F���>��T���g�LS��K�Kadxr��k����פ�3ւ�� �1Vv�u8�-c��/���X�X�>�}j��v�m5M�:.ww
[
����Yh!q��5hT% 
V�h���+�� n�ZS>�D�P���i�"�&��	Lb�?�a����
a�)����bUDʘ^eKCx���/��)�X:�F�{���Z}��P���� 9-@�%zM�7A�	��Ym��#�R�H3 ~�WB⪆~��t`T���σ��	]�w����̡f��j��<���Q[�c�|b��L��t�a�*���v���4]E)cm�hrl�K�̭�\�`30]������SxO�Nk(D�%t���ފ�-b�7j�@�̠�_
���|.�\��u���{��j�f�BU�7b��p�����`=���p��fi"�&�S��b R�#[6��	C٥�ФՂ��y [Yn����_�����<Ū=��I��f��o\�s��~"�Z"`�r���gb�P�|��@f�-��@��?�Gn���9A�ǳ��ج�3)���k�ϋ-���#_<eq�qͤB��9�z�����).�����&ة�$�X���jI�wq�ReR.�C]�oyL��r7�42�}44�L,
�������6=�����\1�~�ҝ<�8S�Y�ghq���tp~*���XݓZ�P�RZݼ��S�����E�VǞ���!r�J��&�Z���!�@P :��5�p(��S�Ko3R��/7ԗ����h7���A��+�RR}i��
E���oV(��U�E���'~<hQ0=�0�n.�}�*��n\�M:+T��9ެn<�ď�h}�iC��_=�@d������
�:�+T2y�=Ɓ`������y�����S,B�Rn�U!��8��q��KK�<��{�T�	���#�\�Aj�+J�MY�f	+���W�ڐ���qe:�XZ��r[1����֠��U�؎�び�X������k!��#<B&���6أ$�S��a$Б�ǐ@^��`:�3�O6�� %-*ʫ��J1��%�J��]�Y����K���=Z�t��8ؠ��~Cw���-�-d���h�G:���X�#�Mf�:&T�L��L�#Y+l�G@C���Gr�0d��i/`3O���y�r�!wc�eW��,OPe*_VG�_!f�"7�y�1��y�JI,�Q��y�U��]��!
tj�х�ǡk�#���C���!��sV>����UǙ��Cx�~���q��w��Lϊz���z�(ZP�ב��Z'���<��?W�ȼ;2|�F��H�tv ��IrZ����M�/X��fM�\6�L�F矲PQ°����oS�%�:)�m��\]}O�l�/�H,IނFX��iq]D�wT��B,�?5��϶��Ek҈�t�@�ƪ8R}D�̣Y�3�{7N~���{b�蚄ߍ�Z&C��/T�Ep>��I��ֳ��/�Ӄr�Maq}?�G}Ѻ<������� �b<2�D��C��[bp�����I	_�1\=��sDj�;L�Q9�HKF�C��!5��P+^Hj�4�0��|ǎU���ܐ]P�T��+�Ţd��u�,W�r7���!��\�a�p�}TZ�8m����9Z%$n/�Г�E�}n'DI��4�m�.�S@u�ր���T�I�bc%���%БO�g�1�'-P A[E�k1�񼞻��cEsm
���S~bi$ξ������Z:}�<�	SO�`��z�1��8�@�1��ot�t���!2�ӎ�4�x0��	J�)<�aI-ҷ�m�J�(] /q���+���vX�	���_�흈!�Y���zP����F�l���Ź�͍��v����@6?��4��7��gT����J�T��?V��W��P�����?
K�+E>�����2���������U<�?�ƃ/�9�hk�H`��h������ݔT.��h��Bn��=�^�����4w�Z��<uMo������-��@�vC���5�~��@�p}�;�zd�F�D�=k�x_�{ ���uO?D�4]����h�i9�D}��>�er�Z�����\o���?a#PE��\ �` {����TD�``J�#zj�-n�}26��@��%JFB�2�ۺ����puN�<�!��`��:�!�v���c?Y����s��\�P\�����]��{��T�����Ä8��{(q�~��_	�D$lz"*��#a�w>�&|=�N�CN�0���-~����<��xHG-�):�>S\�W�ds��}���M�B��L�E��@&�JF= ÇU�6ۧon�ȣ���o�l� �B�ڮk�8\�Ą�	�^H���t�����r��FqF�$��c�P���L=�����/f��Ŷ9t������?��)���E�R��3	+?|��_Z�FE:b9B�%2j�n�Pc^�/z�&���5zxEA�׎e�X�\7T�jׇ������aJ��Ё�@�x�q�"��,��|i�	n�8aw���:U<���M?����&n*�G��	��K(c��_(���_	����o���8��������=���Ԗ�$;u���6u����o����FCY����_1ǿ�n�@RA��@rȡ@=g�ԉ�x1iz����_����?����B�<�O�21d��.�VC�qu2��湬���i �R@���V �W��k���=���GIf�,dx���i��$�] ����ۘ��1�(rwxu�J�7@� ��b8:�w`�s��p�X�������^�1�^{Ņ#�z�<���ѳ�ڳ�<yrd���
�f�
���]� ��t�6H6�%��d4b�I �0@Ǆ�!`;�����m�H�T9T#-��;��  �QD2��d���i'����c�ȰZt�a#�p�&K���ƞ?��j�k	�H:	A�3j󒀀RF�N�u����О�%Z�Jvv?ۉ@��F}�OZnDtѩ����<��<K�f)��5Ú��ÚE�vP����j ;j����x�s�}��X`:��@e�4�7?(0���\`�� ijoM�6#s����GD!�^
N�(F���pvE�0��l�3:q�
��0��9#A7C�	�[Q���H�Zk$v{ԈU����ّ�k�^y֏��'��*�����0�I�U�x=ds��f�ͯ��t(W��-����i��S����ģi�����?�eIq�\��Ϙ�K�����"��P��D���4�}aٖ��!�ł��ٲS�0)���Ά@2�
��g�ؐ	G�]�=2"�<��w5�bd����N@��b
��
;0B���D��e��l�s`e��А,p�Vu�d�V9���E�:�^Sa�7��k����[x	u�jΉ�V˅yꛒ^Sߠ=*�"��4��Σᡙ'���q�`��Rcf�����͙}{�̲�W6zg#�������%R��?��/W���_����oק/�����;_oC�iu52���d�_�3��^��Wqy��T�V���aU�|Un�>�vu�H���S�2�nq �ѫcm�~�K��v��^�/o�&�/�Y���J��B��:��x5��(97dV��Ȣ-W�q��%��z�ۅ���Rb�O]�����<uOڦ�w+b���{'=�ņ���`xy®�׷��g�K$}Y+.���Zqeqem	���އ����ٻ��w�>�2��������B�W'��J����k��e�J�	7@�������~5rzz̢��#x���v��u���ç\v�����ؿ�Z(�������߫x�8�Wƈ���%���� 1N��*�PԟK)���q�X���U<R���\�~@�1���a���*�������z��T���������;�}��G�3]���_�\���|��I���/-
K������d�_ɓ��oa^��S���?z���<���LQ�`ޔn�����퍻g�L��3y&��˓b7n]o5&��<o�����Ϗ����������6�$��#��G�3������7��m�I��G���'gZ)��H�S|���
����ɓg�|�ܻ��Tsʙҧ����w�n�}׮V[}�95�7����57��5�}�#㧳�������TK-��7������?;�/��>��o@ݼ�f���5Lm"��F�4\�P�R�|����o߸q�֍?q�y�c�������a@���oۦ�]k<6��ۿ�.���FK�gO�e߷�V�}*��y�捛������Kdq�p�@^���������߿S,o��{��ק��K��-N�^h|�r�>�g�~(�q��Y���oD��G���[��ĭO7?���9�}���{�I=ơ�{p���=�FӶv�������,x�fb�O��f���A7�4wm�@c��?��||y��/\���)���Ϡ��e�P��.w�}�����Ù�li��ʃ�����|�������`i���c��u>�ܦN�����@\�s�;����>����w������}7-�|�o������7X?yw���?���.m�-�N��y�'��޸������o�{�;�7��[�.��v�&M��o���p۽�R�n�����y�u�Mz��[�>��'�?��{������w��Z������������Ĳќg��[P��~�C��ƍ��J���n����?�c_hWLĕ��qU~w�0uꓩ_N��N����?;�W����O�;S���=��O����;�������1�N�?�T�۩�~�ʤfRwR?M�S�T)���(���$�i�I�W)=�NuRF�I�NR_�^��L�L�S�?���.�WR�rꯦ��Կ�����H�{�?���������S3�?�����N�o��=����;�x�k,�Կ��;���8����3	4���ǟ|��7������ �ÿ��|�������{��>��[�H�)�1�d'ȊM6n�a��y9��7��n������'���6����?�u;S�&���Yx��Cķ
?.�¿�V���@ⷿ�ޮ���&L���do~�rh���PD��[�nO�\�9�h��9��M�m ��w��K}+�N}7��Iͥr��R�R?O�O��j���nj/UO��RZ��j�̔��S=J��S��?��'R6��l�h���_J��Կ��WS�Zꯥ�uJ��.����S����m�T7URM�O�JKܿ������Q�M+፺��EiY;�;�i[�)&�sʜjMS��r��?���,�һ�뿋Y\o�;{�M`�� �e��7�!c��YdL='��<�g�L�����AP�_K>��<�g�|���7����)�@0򠮝��_�S��aCs<�7�zc&�����k���<_�'����H����Y^-����������x����ʵ.��~�CAN��*��_�6�2���)��������r	�yiiib�ϴxo=?���D�l��u�G7�StA�F0N�<� ����\��>4�#�9DoR��;.D�=��{�n;Z�M�w+��g����3��|W�<�z{� ��^���A�<Dm����)d��H^�3�L2�����s���2!�8x���N�f�&������Fai�bsBg���3Dr6����g�k��&�'uzzh毗�ɣ���Ih{�&d�B���X&�����?T\���T,,�V���Rii"�_��q@��z'�(c�����D����[-L�_�3.�9a�\֡����oz}G��[��;Gs�zm>���B?^_\J�.X�Vs�R��r�v�Ug.n=[�֡�%U=ކ|m�:�ڄN�|w���&)�
�g���&���ٷB�����:iqx�H�yآ~�0�
1,�����,9���{��FJ�ߩ��֍��F�n"lW�c]�[��h��!W���ں77[�٪lllW�j�$��=`�2�AO�:C�� ���b�es�w��C�Z̧i�
�����ͅ���;����^;3/2��)��\�oJ�KA�>�풚��>���0�� ��hf��Ì��fx-+�����*l`�=+4���V
�F��q�φ:�����8@ �%%!�w���<G�wg��Q�?���h�$	{���ZO6�b���X�k��ݫ�]-��B�D1NA��lAʅ�"��/�2bOmK�+�a��^+G�������u/�o����5�2���
F��?W�L�>\uЇ����`��V��P����)��4���X���\�p�@v+�^/�Br=+:�D��,)�{Ȕ�# �g�]/��߁�AtfJ�~A�,/�h R^.^�O'�߯�9���O�a��������2��~%�d�����Fy��`�&�T�q�;���	9�&a�:����ӷ|�< �xN�>������A��~p,�C�y�hs�d�H�t���r��{ݞ���J�~ZL_B��4zϰ���t�]_'J�K�+��΍����Vm{���*7����,�hO����،�w���u������t��:粃���1L�[.-q�oy��J�����D���gl�w����3,嘬$��������\�̶��kD�HHb�%2�������y�a$�L��ɜ,��7�@��/x����=���@�M�$���Z����JқȧD�A|���TA�E�G�*�86�OUlA�7$	����=ɘϑJ������c�
��}
������5�C<R��,K^.=�@o��BԼ��]S޻��M��(���:y�h�y3�g>T@��.��r�?*م�ʥp����5=�.o�RZ<��b�h�)c%]��k�@�Ԉs�v��협�����B��@���`~��}�*�F��cWG7u���^v*X�E>u�t�c<�
bc��O�<OWuF�P�2RF B6��h��-�;��9���+���I�)�����'=��0��4������~��l��\�'�&�?��a��-��]�,k��ӵ�z������)�=��x�����;��g�dtP/��9�����{e�JԯB?q��.��ݾ�Y,�w�u��gyT�OĤ:�8�C俥ŕ"���ZX,,������8����������,{k5�	��$��y*����&0%�k|�z���Ä8&'v���<hFW��P�cM���`Kw4�a��
Plnǿ��Ѓ{5�כuA"b��[0� ��
�(K��):��	��9u�R�����U�`�fh���#���@�Ҏ4äJ%��V��ڄ�L��<XT�����Eecg�
j�v�w��p/��	�٫�o�إ#�af�X��`=�Mʂ�..�RHRa8�-�`����<�J�U+��2D윰u-��|Eނz�����`�R�D������m!o����vE�%�\o;'�G-)�=8�ډ���j�����2�[O�s�Ƽ�'����
�/��a�eEo�<хf� oQ�d��29AF_m} >�9C-d`3R�)�`V��c=�|�A��K�-�N����M?�������ބG��9C�9�8�6������J���[������im���v�yzOw{��uv��=͔���/��am�����<]��?�������.��Z���F�`�s���v�\�|����#�M�q?q��1n��3d��.�V���TZ)���ե���<������T;F�v+ �C`�r�l(�P�xf{�
����qzT�U�n�&����o�ԯ��.F.F�������YT!XG�b�t�j<@)�p�4�<�{�<m��X�������^��f���W\x��˳��=�=;Γ��e��x�>'�����m��:�he5��d&4ʒ/� ��ɛ;���QJ2�B(�f�� �$�ɒ`;������vn i7�*�j��_���) � �;D?��d���i'nl'W�`F�����v���5Y�$T7����U�\K��C$%#�}��kE sa�nk���/���	�l'z ���?i+���E'�:i+~y�ey�~�Rk�5{	,��P���K9���P�����1�@�_Й����4!-;�T�}���@e�-�ҹ�� �����>PG IS;xkҷ�#d��9�A�@�t�BA���+
� ���F�jm��@�������ل���(]FG$x�5�=jĂ*@R�����v�<��=z/�oP��T�S=@�xo�����=�]��,isv��ub�̃��5����ʳ��Erwa�4m�v�Z߳}�x4������'�,)�krp�3w�2�f�$k�R��	��g"~�x�>�s�ٖ��!�5Q�d�ϖ]wۑ�;z�l �i����l8\jD��őa�g��x�axZ��*���1���D�'@e^�g��>)�?p�:��Q� ��/H�|~�.!��!�s`e��А,p�Vu�d�V9�~�fO�^\i���������͚\�߽���K�CWsND�Z.�S��T���7-�q�5v7�S��F�]	*BA%��q� �众�ܘ�9�u~psf�-sH��h��B�{c,c��R����VV'�W���a���Gl�(=p�4Jnm�
�k?y.���ѽ������?���������
������d�_�3��^��W�k_M50k�PmpX�ꁉ:��Ux���#��O}F�4��.��P�@����c�0�I-�d��v��^c���K�E�a����auy"�_�3M,c��s3+HR$k
�k�(����.u����Rb�O]⩁�=L]�{�6]�[�w���;��Do#����?�z�F���Vz��s��Q�Ӳ�/tg�����kŕŕ�%x��{~޷g�>�'2�s�ڃʣ���+���������
,�x�cyuy2���������Y��J�	7@�������~5rzz̢��#x���v��u���'����� ��/./���?��P�_]Y��^�3��!�������H�\���c�~,���)���r�đ��z �'�Pg��	�%]��H���
$�y�W�����\G ��Z�٭mW����r���ʘ�����{/W8(.-�3��bp)�� ͖��.s��m�d����]}�i���t��w����H[ ��������C�=� I;�	c)c��������ZX.M俫x&���j�U5�|xk5U�������9�,��;Q��a-��ţo�]�j����6�����v��\#~b�n�O��	?�R��f	��XIƦU�k����	�u4{����n[����c��mX�1��g�|ݬi�L��3y&��<�g�L��3���肢� 0 