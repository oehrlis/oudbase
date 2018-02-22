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
� �ÎZ �[�#I�V����f[�����uwtcX�S�->�5S3�v��S3�R��{f�{�I2��i2������Z]�lY��G~H0dI���0][~�؆���2`ؒ�gC� �>'�� Yլ���L��'ND�8q�ĉu��N]����VV�\e���2���/��r�++�e���WVSd�	ç︚�8�>�������>ߐ��o��5���w2N�������9�`�B>���2Er�@K�������Yd��洓�$=���l6������Ʊ�4Rz�H�������c�c�����H���Y�K�󐧪�-��ǵ5��I�E�~~�@t4׭��Vk�TO�+��hfs�D�h]=Þu�8xY�m��/��~��dWo���Y�3O���h��.o�L��B�J�p��3[��n�5��7�/k�_��/Ⱦ~l8�e�@��׷{��3L��gH�a=��i���։aB�̆NX��[w�&iXM[�ruGPsІ~t����sJ���$G�Mt�ذ-�v*tN����a9E�+J�t+���ڮ�sֳ�@���:Y�b�8`q}��
�C>����u���grd
��*!$
!���Z��66#���|a�L��%H!lC`F�!�e�9*�����&P��5��\ �U�'��t���k�����Nq��k=��q[8�2��J�Q*f���t$)�2��~�%�N_w^�Bɇ�����Nz3Y�-��Uv�����a%EF|��w�zG'�E����z:�}o�Z)����Q�!H�8����{���v�83�n��!3�����^���_�8�����ʺ�^�&��܂�g^( gY5{ff&����j�TJ��~1E�xҠ���f^H�������!�7��<�df!��.mn����J�Z��ز5��F;Y����/�2G�zO2t��f��U�����;�t�CGk�s��EP�����N��KGv�25M*[�N��6w��uV�b�����6I�#ݛ;�;��$]&��,���/��=�'�ݼ��<�*��t;��i�d��ɡ�;���~�=b��d���7�z��~l��1T.� ���?�}��}�I�,�[o�$A�5jcǠ�l�{�Bz<�ʒ�ܡn�R`bSrT�-�E�L�/�v�t8cp�y��3�n�$G�~������Y2��o�n�Eጾ�;0�
��ċΟ#4��H�%�>�E�m�XLF�F�*,��eu��s�����;{�0I��/�E1!}@�՞�4[���"u>��m ���)�3P��1 3��L4b������w�����I
~��<!�ە���L,MPKH�gw�H���4kw>Y���~�����C)��~|VsHf:�@��������J� ���xD&���H�	9�,E����� @��0���h[��l��(E^��NҚ4��ʸ���!%�:m���~��q�S���w�^Jk�R�8o�|��CkY���P����6-S˦1v�ݻQuz�Z?����2�'"�	�"���{ Az�`|n�����"�'�z\$�Q{�yo�E�
3mH{��U^�
��&� -��ΐG�$n�k�M��kv��Kd'C�0��tZC�ްl�;�^F.�0j1�é}~T�+C��Z	U��@�7-�v���]B��(
~�6�*�vS�W�zh�4-��]�XIԎ5��ڣR�|~���iR��o�ي�4�9�t,�I�̼�d�#�D�薆ַj�l_a��#��ޔ�/�_�mh!$�I�5��ڰ�w�i���mB���L]�蚎��Gb]�u�p�Y��l��G� Gc�qBT#p�i�L$~���� tye>D�!�0�ʈ�	m_jCց�(E uty$�;�8b�g6�=�� �Ђ�(��v�"K����+�O�Hv���F���Z�c)���C�Ρ�̴NLV�}/���Pr�*M�z�:�ZG���y/����]e�n��g�~��LC�RTV�)F������<��ekH��o��Ѻ�6�4˹��.�*F���0:��P ��Kr�����XV���[H_�	�oz�б0�p�g�&�J%��J��S��,(�C���
���r���ֻG!I�v(�#�΄�䒗/�ͻ$���	TJ��4,k��d`Of���JAJLS{�g��JR��9@�|���	I�c���
a �U�"GL%���+�
W2���0F�zy�=���lJ��ۤ�#j����5s�*�T�dǸ,,��mk�+��%�wm�GRJŖs)\�'�\jA�K6]�P�A�����rs�N}��Lj��6yR�]�N�㭥�V�V�߳-~8��Y��-��l`�al=�s����^^�r��n��-���)��|�,�9i28����;c�l�ʌ�l��M�@�C���{1_
�dkϓ�����F� 7BTU�U����sQ��Y�'0�F�Z?�!h�����Z��$3������u�܋�I��QQs)A�o$è~/�D f���9�զ��qr���\�p6}��G�̔�[!�&@Z)!a�'�"Ɵ����=F! ~|j�o�8ѡ��&�}I�e�	���t*�
}���^�MN3/��yE�X3�˧�0��Yhy)�9|(W}S�B eZi���2�f���#�Ё�N!Ŵ� ��=�~߳��n��� ����ȯHy�g�r�HdEеA3-S�U�*���hǊ1�����y�s��7�=&�4��Z������z܎ĝ��Af��/g���̉��K��{Z����23�w�����&�^x(��T7�Ջ�?wQ��ɾ����>1�$��Yn�����C�K#�P)��cӐ2�؆�4�����1�����r�̵@]jd6�7E��R��!R߁���6ǩR,T�x7�h�K�6_*jhcK�$.�\�m�K{�O՛JՖa�%����dJ�>���Ŝv��ޫ<��y�_-����'�v�O��>�|���_ـ願��-��+�;�'�!�_��M� ��u��IO>��Rf��͒P���%�\aՀ�y�'�!9��tQB��'�Ve�y
�:��wV�!m~x��)O[I(��D,M�q�[�����8靱�U��4��4t�0�#FZ;=��_�>�>S!�ȼCg*jɛ���T��ܑ'��yLkvs��,<{E�U��T)�[#����:���e2�t��B �Kih�xXO}���d��3��k��� ���C@��J!���������+�u�~ꦹ�"�
2}ݾ�������\����{i9W@�o���R���w~��}���������u���N��"b{NV����������\��K�����V�
&��=3*"rzz�8:�����%1^��3�X=���~�>�� �+�׎�GVxp�.Iw�GRC��.ۯ�=��v��-�l�l��;T=/��ft�{Dg��H_��4��HO|���Gz�#=��"���xe{m;�M<�����*��WyL~���U:����Ohe�aq��d��%+�@i�W��1;Q��{J��o�\�+dw�X�Pwȫ���Ƹ/vP� ��	=O��Dӭ�}��}B���K�����ޕ���@�F�j.�:�-ų�{N��V���2�0�,P9���a�h ^�M����jVS=(�N�{�̋D�]E쑃ҽb��@����*�0��c2���Y����F���09�χ�"��J�;蝣jBH<m�xO"���>�u�ҵ0RZ.�βxl���7�W�_-%<���P\�%Ԉm��Ý�ڴ).!f*��0��$�d��?A*23�'���_5y�x�]��`�,���뾣bk��:&���.0���&������b��1�*�3�A��}�>�|F�>19b��l�tu��⤖7�B�R쨇�#:,��q��!1�w�R��'�xFdz�K���y���s=�s�#��b��X�K���/���X�9�d�e�����-s�d����yuJ�#,�z�K����-���]��2>�J�*R��U-�/@�{������}�$��C�Sׯ��j�PȊ�1F�3_^v��{�
a�V���k�k���3��,-�y�8 �}�r�4m��D], ���=���z����֟>��I$��)j�g2�y�d6:��߳�g�E�SR�L���>I->IeC(��-"��U+F��3�����f^��8�y��1�^F߽�Փ���s�fٯu�.�Ykcw{���>_m�e�t�	�9�n[�K+AO~௑�Gr��"=��G8$�#
NlLk���)�����N�K�i����\i�@�^�C��̫28��	���P8[�ne>�a�猇�.P�Q��q�C�^eT����)��Cپgc*T&��T��e�<'i�ZUv��+�z{�8���/A�2�7oɹ9��g�yU>D���}�vq�\��2��p�z3h~�;^���մN�EP?E�OuuXQ�6��֛��g,�|�g��EeO~�i�Iʏ!�>gs1=������P�Rҹ�P���S�I�E���	a<�o�׫��D&���'���ʒ���_ZC����$��<��k��������U���������~�ɭ)0�ڗ�KH���V亮�EhX��%���G^dG�>q(���f8��2�76�𕺕|��5:���B�R���1�tp�ӓ�U*{������v��:��#]F�3]�%A���u��J����d��,�~GkM<h�dZ�|�������*�=�#8P�[esgc��]�9(mM|r/����O�$n��'��1�ɝ��N|rӯ�O�H.��܉S�Ŝr�nvʝ8�@7q��8ӾQδ�G�:Һ��zw�rn�.,��*��*�l�>t�5�x�N�F�`�Q�=7��(��Adr�p.�~slڗ|��b_��u�*.��f<HđV�E���c�;Y�9��gĤ���N�Q�Q���ήds9L�'w���X��g��p6?O��+m|v�W�V��X�5(2%��K	�݉����A�}"2�]T�;�VT%Bsx�_��pd�5�b�n�U�Y��bV�4�&��ǩ:o�����B�����&�w>���W]T_e�I�)3ĵ#4
�f���O7�z~����|Y9>j�;o��T�3\ÌP�Qzv�J��)�jDwQ�U�D�_�c���<2Z~7�@1o�F �O7tI�}�8����.Ùq[_�e����}r7��C�&.#��9��:���6�jO�V���,����J?�M�k��<�j.9r���%���zF3���Z�{��
x��m�i|/rP�éx$�b^ʅ��;�l��Y����v��ZxURC�tJ��4���D�=����#<�c�[`��?QE~�!k��%�:E'	���]���Gf ���j�Xr��>��sz+V�"�����w)��՛�7q�>�sݮ���ο��gf��2��r˹U��^^ZY�/VI.����6������?���[SS�Z��V��B4a��M�W����;��P���7������|��ߞ��	�����虎�� �k��*��6�������6΀:.�:�2�}t���f�?��s��o�M������������~毄�^�G����<�W�����_^*L��U<���s������~0�=���tq��r#x����e�ɅO�4auٓ�D�M!���~����23�lZ�g�yB��t��XJ7��)�+�>ss�x�	j���5s�GlU�^gM}동o}�ӎ�B�W�rɩ�]��!c�"�3|�K7x���y��EJ1:�+U?�Uw�7*�sOa�\�2[����F|�	��nF��֘k6�L�P� ���w�$�=�
Ҫ�X�����nQ�h��	��/��0�&��J�_���qd��6�H�
�;�b���fu������^�Sfq��%oBjqK)0|1/�u�
�l�r8i�Z�n�ʻ��U�mZ(�T����FiK���ba�JN`��3(�m�B��L�ي�:�l�m�*U�w	�e~������Ɓ\�=B�JX�n2:$q���I��)d�L.x�� `f5ޯP���b�����Aa�J"qE�#� G艳�ע��d���!\��w1�U2�_�i�M�l$���I99����K+V�}��4LJ\��Y{'����S�6���r�(�e	&��̷���}jY��8�gЫ�#X��x^▀'Vf(��%���wz(������U�['ܢ�A��ݑ:��w����4@�I�|y�q�	����6m@b�
�x��V���� bEh��<,rU���e�մA�#Ĵ�bl���5�?|��R��c����T�
�I���d�)�Z�"s��?-=,�"���,�K�XcM����O�%"H������5�BGݖ8�wP��@ɉƃ5��h���v�Sr7p#v�����k�v��|�ޠ��wU�7���,�^F�qߊ�;W��W2s������������$�  ���ݾm�|��no@᪗/-<J�����3�����G���^噫�],�h�b�TLq�|��^��t�;2lǕx���QO��l�������Iw�/�$�K+�">Ə3�̻Ӈ
�=r\�
�3�����>r6���z
m�B�4�<���<?#�H�H*��|D�F(�g2��yn�k�hb�f�s�2�O�pg�&�.��.O����������qF"TL��b����y�I>Hƙ�{3�Y����%$P#0�w�]|J/��d2>�h����`���J���}w��G�����9�/��T�xB]���c�D�A�}cߵ��X0���[��E��g�V^,JC��	:0�:G$HT�=x��/
�k�L#��#�iZ�	�#"��-�{<80HF3�d�fD_z�@�qp�?�3�+���R����$��aos!�Pz���L�
9��V��J��Uŏ[q3�^�R?�a�<���#�<UqQE:�X��SQ2�cz���0��@'�W���8�P���V�M�v��c:c~�wB�"�����0�2<���W��X�z��xy,�}�?|wn������E�l�<F���MȺ��jOB;��Xq�7M��<J�Җ�*!��ܭ�_p��<Z�j v�N�e�ߧt��x���TX�/4�C�w��k�|T�#�P� *��0B.v�ճ@5+��}.�L����'����n�!/�;�4�\�Ǟ�=��s`̸�!;c&����O@�##�I���~��LYϔ�?];�@'s���'�0�$e���С�E.��?��?�&v��lbtn�Dc�Z��B%��	�s������|�팏@Y��7�SiVq��_�SL���G�I����ݲ�FG�Qo4�L�**u;��������x^��}��^#�����zd�O�ܹ���C9Y_%�.�,�M�}�tLyU&58<+�l�1I*��1� )��GC���٬�A�N���:���s����Q�u�>�	Z�V�|+%	f�*���N$C�@Ъ
*Cx��%z>$25�(ݱ/�Y�~e/5F&{e����<��9�{4�:�e�@�Ők�A@<�#�l_�q<.�6W�#�pZ�gԓR���S��L�e��6���(�<������2juy�F٘�Kwe,�+�.���"qqdK��l!]�j<���J	,*-�/��2T�D�y���=����
���B\*��s.=�0�#2{'��;�|��ү����%W�Fܤ�'������ܗ�a��$@�g����NݡR�p�?�IKH\^�4�z�	��_i
M��YӄK�Kjb�F��<���+Β�iԑs��\��Y���,�Q����ɍǺ_�u<�w�3Q�)�}�ߛ��M��7����#c��e��餝��k�v��ɍ��'���;�3mf5OW�q��vyERb���眞�6 %��_b��\��?�eQq&��Gi{�Z^!E�Ntu%W��Q�)h�ì�*%�ܪ��y���G�&H��j&7n�����!{m��s���sJm�R��ӣ1�S/��������K&�iA%<���^lJ\F�Ne�2����i�oƐ���z����٣a�K��"e��V��If�tM���t�oj�&��_�d{��OIo:��Q+�;&�I��:����(9T&/����<gi|���X��"a���lg��S"I�5�D:��6k�H�4-d�P��?���?N��/Aݤ��FP��L*-+`I���z��9$���� �1��hA�ե�Xړ/�W�}���%�ɤT�,Z+cL��\A�Y�t���g!�Y >h<���r-h!����U�n���qcPh�c��xD�����٘���Q��KX5�5����q���<��W]j䇊V������Ɠ'�$f�^��t]��u���g�fI�uU՚�`Mp�:��oL߽Gs8�	e�K4 ��N�	Y�¤ �Ȇ-m̧����s][*),V>����W;�%�z����+�uY8HMO����Ϥ2��IMd��(y��:8uI� �� �bҔ���1��U��� �plVC���#h2���C�����Y�6ΧT���݂%I"F�!�����j?��>��@�ڠ�	����ETEbP��-:�ߌe�Q@�F���(p�ّ�����RD\2V���_H��T���x��"'e����x����s��|z��,�t��yD}M�Ϳ��\�K<Q�ʇ��{�趟����,�"���å����Mv���C��Y7�Ky��@v���bd���J���WG7���&�o��v4,'_GiX�dR@��Z���] ��S��J[�%/�9���@w
t�2�Ź���25�Y�n��_�bMzL*��4�y9ǰ�����Bv6���]h��W]|oz�N:��Y�+��Z��>>)����{S�:���K]6����է��h�cK�Р���Q�No��H��ԇ�b��� )�Xyd���� ��~Pz�̲�
���������䂴{���L���t�dA'��{_���!2��~zg�$�V�	�;A�Lc"i��v-s�YqF��4]��	��������.	��Q�����:F���Ӏ��i���6ڋ��k&JVͅ
�M�.�)�����H�Ѳ�
*&�D�l�^�+e�D��R�zɿ���P�e7e':�o�͋lF7+eYY�l)�w��"3�Ii�CKw�ܙ� �(ˑ�,*��_�T'��T��if�C��ao�4���|n�o>A'"�	�$Gg�U�	����e�lW��E��Rc||mZfZ��-�D����s��;Ip\��^�ݣ��kA�6-�L���'K��7\�d`yyLh�um�8�/E���N�����:��	B�ť�5�Kr�[�ĶɈ��W�ab6#���;�]q�ן�"��y����d�􄩟(�v��+��,�w�z�?�;�B�p̚WЅ���9����!w�!��҆dZ
d�^C�|���ΐL+\݆d�K[�#�1�C�'� D��Z��0�e-n[�"..�
9��s2��U�ذ� v�v�������~Q,��n��r�'�$2=�}�B	Lͨ���$�� >`qu�q�u�t���YP�61�O���>�]��<�q�5����;|L���{���Q퉇�>7g���|�gHm�0��u�5u]qM]�x�=(F�>�E7Ui�N�}t[?6`.�u�0L3�Z�3]������EKQ��Q m[g�pE97M��T�Jb� G�YF�?�ʹ��t�F��3��}$�Q8_���/q��y�R:��XFߨ4??��A��_>�pa�dR�;y�Eq�i{P�PN��)�*p��c�B1�e(�8�=r���yd|!��#71㸱�R�z��d*�tH���
���}��)�U��'��)^�eF9�H.�2����"b�FD�����;F�J�g��54P�Du=�!�n��j���h���$v����	��$�޺G�����h�,��k�4Κ���Z�|/�U�40(�G��i	��zj�����Q#�3"�t��ʢ��[�GЏ�C�z���xc�Ti�0�#:0'56?��8����H�ԭN�1�ˍ#����0Z�Ƃ���)�HVwG&#F�LLd����i�s�[2�����h��TSr��\c�z'͌�܍J���R�s��a�P���X[.516��@�$u�w�DC���A���±�Rd�W�$f,Z@�:�iZ��e�1��/�/G���F��ɯ�.M���&�o��?����)oW2��%���<-/����ښt���������+y���= �޽J�RB��q����T������R@L65�i|%������:�y[�4B�/v��|m���i�<������/�;����ӝ)u�ޟV[93ϯ��2T�:��z��`����M��Y侈�Û�F�w�O	��'���Շ�F@#N��i�; ݤ�q*3���ߤ�]�M�i��6*�x㹆�Ѝ�������TJ�X4(�i��t���c�J3�E3*�L]1J��EZ�"zЇ����-4ӓ�ѠN4��4u[�P����>S�Ac��K��$��i0;P��I3O{즅��,�,�,3 ��I?v��R��L�5]h����q�~ۀ6��/z�O�&�(o�2�FG���OЇ�04@����؆�K�I�Ol�uu3��i̧�Y���ʖa�������%�
i,�[��(W3��i�}���u*�g (�7�jh&�Tw��lյA�j��6��iD^�o��1OY|nF�|O<h�Ӹ����ˋP�A�J�LuDc����⇮��#�~^籡[3�h���� ;��惱ރƢ��B��_�蘭�c@���,y�:W���OI���g�6��f6\I��xQU:�O�j������+�� +�x��ˬ#�u�!$�L~����_��Ct��C�&�t):�̇����y�n?��u���)��@�ˡ���"��������#t!#Eܾ�t`AC�H�С�̹֙x�[/h����ǣ�Mʻ ��ݮ�ԇa���M>;�Qe�6NqT�hv�O���n@Q��$���7�	P�o�RK�\�"��Ȥ�̉��-�aE4YT6�z�\t~c����+�AEA���WiC? i�Mv�X0��+?��/�F�e~��/��aQb�����qO�U@(c�j�c{e��԰#��ٍeNT����B�X5�bc
�uD�:ʣ�Ӑ���>��]������C˾����ݲZt�\'Y���q���d2�)O��s��f��H�z�.�jez�d||#���K��`�����S��I�`~�0r7�s/�̽@�:�"	sz����yL�tӶ<u�~K/���TY��>ዑ�(J�M�fk�eA�Ȳd�^0J�����H�g� ơ�&Ņ��~:WH�Wk�����zn�|�H>���F2��ϡ��f.�d��
sҒ���G;�	��̔4����1Es$�`F!fH�9����E7��:�.>K���	u(�8B�����pޡ�B`y�~(�a��T��Α#��'���L��A������X��J=��*�\d9
b�h�XGB���^Ӗ���,�y?���W1����9/^�D��5&,龶����>��B�n��q��}F���&h���k�P���(x�h��7�8��8� Z�QF�=J#�uc�qjp�<#����q���,�g�vmYn��<(���S u8�
��i���Y�!�����Y�����!)R�N��¸@J���haɆn�A&4p:�$�"$���$� �?�;z���oy�W$����@%;F=��Q�Mz��_1ؔ��R��l���4���5�?�LBd�l�LW��ZD
�`7�fz�1��Baj�D�����h�s�h��B��N/� �*,�7��b�F���0=����ȉ�:Sҡ��^^�9������F_��Ӏa�����$�lPq8����S��P��_UJ��^���!���}_��Im�4�����]F��Ps�ٷ��7�7�[FG�c4�~р��9n����Wk�F;�9�d� ����
�nW�iJu.Q�]���׫;��8��)6��[\4��@�]�Nܛ�T�-�h��gSe������bf��� ��
�v\�G�#W�V�Ȃ�n%�ߗR�@�d�W��.dȧ�^<.��d`Ԉ�����A=Ȃg^�)fVY��:L�d��x�O��W��Rޑ��}ϿE7MO�{�<?d���Xgz�_J&#l��h�N���{��]cAli��w�O,�3+���@�,W�0����>���V =��%[�2��!�Fi��Q��8�M�;�YF)�p����1�E�.ҫo�MU�X��H.��q1�,d�:�a��,�";돻�2.�#�2c^��z�+�?O��\qlS��d��,BN$�lB��:0�Mp�6�F��B.
�Ea�]�g�ʉ�5B��5#�i�{�}���gf)V�%�0�=�d�%EA�KR֙hAXL �_1�2������1���˷�ō�Hf�>�~�S��m6:0tS���*5���Bb��kлӀ)�Q���ˮ@���AUJ�`�y[�S?��L���F��E�%þc�,��bY�n't��	b�**eD���!���F(s�u.p^LԢ�����Y�>�|(�P�s�� N�Ľ����G�ﻭ�-��![��u���xFH��0��*8������y�}����9ԙy\uT��p\�n�`� Zc� SFd�^��$�՚U�uܙ��(�u�CNL~ԑ�@�k���&�S#7����@:�w��h���B4ZL3�F�l�P�B^�Q�������P -���I�l�����#�|�&��do�fE��+���|�I���lE��ĥ��NE+����ٶ؍�Е]
U�Q+(H�������H�;�s�VYݙ�X�':9�aE���������OhZ����"'=2 �|@��7��L�iսH?�gp�-��;�8�xo��'�ИYM��*E˛�r詧���L�t����mŵL~q0��C�M�S�IP�JQbӒ��┥�\E�2�V�t�>C�n�d4��
h0�X�s=�WN=u/�zB	��h\��^�ҕ<帎ڲ������a�̗�|W�k;1��?��p�B%7륆�T����d�֑{�,w�ݥ���ZK�B11��b��_�� ���=�a��cI�r2>�\,�T��V\��D�Sr�#W�8zi�b�
E���oV(��U�E���'�?hQ0<�0�o.�~*��nT�-:*T��8�*oާ̏�h}�i��_�<iCd�dpy
B�
m��*�<EncG0�{h�������>���󐡐Yb$DnG�;j�xy9��Sxτ�p����D@�k�iEyF��)S3�(Ke���Wf3��AS-�C%�(<,T���6\b�j~1
⟗B?Gx�Nqv5�*(��Y��x��X�-�`��B�:jH�M6�h���&�U���I�ۇ�}%��GN�����A�K���5Z�t���_�x�~]wa��L�M����[�:]D����ϧ�K���������+b�C@/�U����Q���՞�b���1�A�C$N�F�˞r>W��
T>���8?��(�����#"����eI~%�卒�!
Ʃ�B��Ԇ�D��B��G�u�Գ�B�{1��8���)�����#EY)�^�Hi:1���X�����E�p������H��}�C�sӎ,�C��[�ى4Wg ؞� �5�j?{Ǵ���t�k����e�6:����2��6.M~�J.��I�Hi�:����� _L�X���&WӢ����ѯ�X`}��}?��A���4�d���#"eq�|�1,@ػ�p�s�Vߕc��8��jؑP�l(�l ����1w�����d~@�T��j����1-������7e�#,����D�_��+#������-	�����L��D����^^ɷx�����+<�뜌.v�&Tf�#a$&V<�T�aj�wa3��������!;�*���Vf�E�
��l�,�or7�»iC���J��h��qZޖ��r���+\^Ю'���N��O��
u��[8\p���6���GW�T�Ich#LT�����h���_�ŝ(���"���k�n�Y�f��L�A;w�T�Z����i.';��L.����ɒ},Ko���=�2�y����]�E����ȟ�L�ᶌn�'a��i
�}XR��MzZ:�ԃ)J��D�(dr���rJ�:��נC{���y���#$�;99�haƲ[Y^����ܨ�T+i@zt��G��E�~F���_)�
�#?��qO����#��������[ʭ@�/�-�L�\�3�.u|F��F��Gz ��fs�̌����`��CTTr�xۉգ��{��礹{��<�jzc��H����}7�AGsݺ�o�I&��tC���h4Hdسrˀ����_u�#�K��́2:�����aS��.o�� w�i�^�-�q7�_��S�et9�D ���8O�@��܆Dw�Ǎ�N�
[.h]�D�I�z��cKw���hn���i��#�B\�Fڨ��"�'��@?��u��� �[�r�U�;A8��)�"���	H�SPw��b��z�Ɓ�Y��7�m�Q �n	�Pl<����u�;79A��{�P]m��<:��N?�M:�1N�y���x��&�ae;�`�B�f�.:�:�T2�>$��Zl���Ucכn��t����
�g9�!�p$�&0| ����U(��W,��~p�H���p��aB� ��wϑ!"�^�NU�es�|��aSJ�)�H�|��򞌄�o����I�"m���ڈR<�t6�B��%�/��&���5�yEA�ǎe�Xe_7P��ׇ�i����aj�����@�x�q�".[�f2f���S\�p�(��lqtjxȌ]�~9��^k��������n�a�����
�|�W�ok��[�//M��+y����N�55��5�n�|.��M݄��������P���W����������2P�t@�D<�4�WE@�o�����_�J��<�O�01d�����im2��湬���Y �P@���6 �G���c���ݱ��Gqn��~q��w��!lI�@'�x��1��m�Q�>��겍��A�P���IǸ}����C��t���������	�������O��ON��q �S2+ �v���������~rG�ic���z�_@#����o��aۑ�@'����V�'9@�|Ń�p �	�X�"�C�X�zɴ�;ˢo�a��Q��ăѪ,Yʛ�^�z��3n%pB��I*�S��ܑ2|�4٠�Z���_�g��g��h�W�oKo�r'�WZ�A�D��ӯ���k��h�3��K��r��������覽zu������,�����lJ��J%��|�$�l#x]"��P[ IC�ۡoS�DHIo�xD�R�p8���~3
GW
�O�Mz`F;�R��N,�7f$��`h6 }x+J���_k��f���
��t�8�Z��+�z�z�V��J�"�w�F8H�$h�-<�����m��<��_�0�P�8�/�$� ��au,���]��FS���Aǵ�$�%Eas:d��uJB'�r��-���Հ��Sd[�f�,s����N]¤��;�I�����C&PVq��ݫ�ju���#c����`zgW�tZ��*��$R9/�M�Ӯ3C�I�dh�wH�a��������0U�=�K��߽^b�%����SAVӁq깒^S۠?*R�y�NS�pSDh�	*B�%�\],��Z��̜�:?�:�o��Y���No�,cD��R~i����Lr������/W���_����o7�_���'��8�2�����Zh�÷����gb��^����ki���X���`����|q�ts�H���3�2�Nq �ѣco�W[�#}�K:�vB��Q�/o���/������<Ν�|amy��_�����2/H�g�-�G�q����F�ۃ��KRb�K]�%���+<u_Z��w�xň��wO{x����F����v�����>�X"I�җ������W�Vח�Y��	xߜ��8�����-c����"������kem2��䙜�������T�?�H��>92���j�W��'Ǭz�>�7�Xe��x�^���{����.#7��_P���r�<=����O��^���Spye�����[��������	��s)e��/������G����)Wk�:�1�1���_�㿰����J����ߕ<���ޟb���1���8���=���s�k򼞏4�/i����\n98�Wp����+y���<�k�zc�}��ǢAo���-���)������;�|�au{�&x�L��3y&��<cy��ƭ�%c�L���>(����!�L��o�Ϸ�<��'���?d�	��|������'���?d�\h%��#�KN�J�(�~|�*O���zp����Ɣ=�Oi���w�~�}�*��}�15����?�['��9�}�-㧣����̩�TS-��7����џ�
�ʏ|Q���6w�Q?qz���>��U��17��o}��o�7nܸu��xZm['Uz��f?�_x!b�?����]�?4���������FS�'��i�ܳ�f�y,��y�捛��?~�b���E���;[$/���due������7�=���˳��%V!�~7пٯ�ڲ�?��8���o�7��������[��g[�m���n��;��ޡ�Ћĩ��]��ٰ�=[?�*?j�Mx&��^C��e�^�t��W�a[�Ξ�����縟��B�>��c��E�������]���a�o��7~�03�.�}T���߽������[?x�,��~xb4������}�6�".ݾ���~t� O����?��O~����X>�׍_�������wߙ�y��n<��K�V����o�y���7c�=����o�w�޹u�@-nk7nҔL�֭�g����,ei��;���wn7oޠI�p�G����g<�x��;��p����7M�l�S�q����K,�yv{�	���G?F�6o��ߔ�M�y�;\5���B�b�cn�����;S��{S�N�r�7u:�g�����2�7��h�ߙ������~��L���0������s��I$�M|/��D*1���x/�M���R���f���g�G�_%�D+�N	;q�8M|�x��S�6��%�l��%���_I���_K��Ŀ�����J�{�?�$������;�?'����M�o��=�'��[�z�[,�ܿ�2�[���8�o���d�O?{����;������?�!���Yz�x�c�@w+)�!�>�^��[�!�F��?�8��C~���w��?�ɏ�M������nП�����������f��[�����p���X9+��n ���6{�~룛0n�����V�����PD�[�nO�X�9�i��9��M�]`��w��K|;�L|?��I�%2��w?O�Kl$*���^b?QM$�&j	-QO4����=ʰ/g�?��g:�g�m�i���_J��Ŀ��W�Z�o$�uʼ�.�����0���m�U�TVM�O>�JSܿ�;���I�M3�:��iZ;��f�2[SLk{�3՜2������ߗ�EL�һ�뽋�\o�;k�E'`�� �i�����B�(����s�L��3y&����<�b�������3y&���I�]���My��m���Jd���s��i�K�k�0Y�O���������>�����9�����\���YYY����������L�2X����*�I�_�#�������!���������R��_Y^^���_�3�^��������=���Ȼ-�8"�1�o����C7�73~b��@T��ޠ��p\�[����ݲ���L�>)����g��x��y��$n
 8z��7��7�!ꎥ�K��{
�))�x�I*�QO�� �PJ+C����7z��)��h[$U������h��DJSdNh,�^��q9�?V���S�Ǳ�v�]�'5zrh�oV�ɣ���Ah�&d�J����&翯��?4\�����-���0��ray��_���Q��2��q�1D�[ZZ�����_�[�M�_�3��9��\�摭9��o�}[��������zm1���?�X\J�`.���2�B&���Ue!n]KܭC�%e#�bmE�ڂF7�p����gr�g������ٶ���iqt���ؼz��"lѸMx�
1L����L~s�����X��r�[�����F�.",GR�#C'���k��!W��fZ�;7[��.m��vJە�E�����X�Լ@�����8@�~.�eٜ�'E����$����|CF�t�Xٽ;xG"]��vj^dv���?(s��%�/��������{X��c��ڥ�Hy�È��8��j���~0ɞ��2����®��w������0 �'�9����aII �o� 4������g8��'=��-n"���h�v�G[U1�Y
	,e��w���U����a1IB��'�MX6�=�BN�Ri�A��v���ϰ\~�C�TyRZ�ວ����^���cC�?�C�I��+z&�>\��ol��-! ���lv�a]�XPn9vi0,��z�7.�3�ܕ޸ �[.��zYv!��b�M>�� ��� 2#���3
��Η��o�ؠ?��#�e=��XW�t )��rϒg��7�	���w��0��rh�_^]����g2�O��Qoy�Ug�;M�{��q�;��g�Sr��t�0�������b��p����/����~��c��8m�v��í-��"��ͺ�i��ݻ$�v{28^�U��^>y	���h=�l�:�v}��[,,.-./�,�^�97w6�+ە����Ҫ����Z�P�-�0j�q���<v���u=���IǩQ�u�a5c)c���RX����r~���Q����w���,^�u��k�ΰt�cҒv
J��N��2Q:ۢ���%�M����Zڢ��M@��T2��;s�&��N#^p3�)6ɡ-����݆�!���Z����Jڛȧ��I/��5"��O�Ƌh���$6P�;�*6��7d	����9��1�!��0:	� -ۂ}�,M�]��G�������LrZ��dwQ�Fvm����7-��� &��v�z�W�fTX�R�,gDѝ��]��
��o�Z��rG/�ɳ+����2V��̾���:q���������~`_��r�����X��x��U��;:����ZV*X�I>u���ܴf#���( �&�:�b����T�+��4�u���X���SKw��#W���$����ɃӞ^t�z�؊L�J>�X���\�G��7��A��-�	�o/)����s�Ay��y�����-�
D�U���] W��z2:��ljvs����n���N\�<���k�b��q�4Û����<��'�:�{ ���K�y~��Zn)�������D���gr�������7�"s�#���xҞz� �du��X+\�='��ꃲu
�����_�r:F�d(���mUc�+� ��i{Y���hD��yz�!e)z9E�9!z+��Cʰ2ں�L��� ���;rb��.�X3:�@��6Ň$�Z��+ӷ�j�Ճ���_�6ww`����,�y�Z
�2J�P�����V�:��F�����/R�pq���
�)N1�+'���P"�CV.�B���r��55W[�y����a�.��4J�����	b����Wx��=Qo	+���� �^AO�pC�6b�k4��D�u���G��Pc^����ÒL���K`fX@tY�[�|�u@�7id
�il���|���r�1 �\���2��)[TF0/^X���@�^����G��
3c��E��XCọ��\�flg��6��񸿰�
���[���u%���΃͝�����@��l{�G�)�39�_���Nes�i�Z�8��<��v���R�=�,ն�`­z�����#���&��3�'j�?ƥ?}������[�
�9�����<�������W��#� o�`Cq�3�"��Z�{�Ǫp١����òg�v"-	|��|�9E�z��b䂠'۸��F�y|-�HWkF���«� �\��C��/R���j�Y<,�j��>v�ET�j�8��������,y�BV����S2+ �v����3��VT���!3	�^�ba������Q�:�$�,*��hXH�,	�	+t�����!��Or�"-�*KO	 ��X!z� =$����Lqs'����!6vw�� �'�VeɒP�����3-�q+�������9��q`����e�n���n�1'�h�W�oKoЖxНWL�e����W�Y�5ME4���%�@~Bf0V.��Z�M�N����T-~cֶ6�gIB�V��$0��1B��J%����`9(fM)f=�� �����Cߦd����f��0ҥ@�p
CA���+� ��J�6:�@ޘ����ـ��A�(MF{���c�=jD�*@R�y��k�V�8��]z.իP�j�TfS��M��7����;=�M��"ikV��ҁ�s�Kz2��g�E�d`�4��e��ky �h��{�!踶�䰤(lN���̘Y b\�萴I
9��O�x�j��,�f[�f���@k��]?_vݶ-[�n��!���U��8���P'"t�(��8{l(̃���^S��~��E�c�~0�yV��R��4���k[�KCPi�� ���:�P��$׆��ԁ��A24�;$�0���w{J���H3U�g��k�7�*2%N�{���K���٧�����0��5�Mӱ�B�&���Av��n��1q��"\��4k�%�>w���̉��3��X��[åF�c�쿐��������6�����0�a}c�}�������Z��uS?y^�����k������X[˱��KK��U�kKK�����gb��^��<־�f`V����)�s�𦛃G2/^����i�W�P~C�{C�ڢ��\�'�����X�{���/����y ��k+��J�i*`� ���yA�<YWD/���E���*��h(<L\��^�2O��a�
Oݗ����*��W��iO'z���&�)W+�BT����K$�����x������?Xϯ.��/ó����9k�q<�񟩕+�K�[�+��WVx���*L�x�ceme2��♜�����Q��j�1'@���	���WS�==9f���Q�Y�*��ǃ���|���kb�~|!@���K++k^���e���V�&��W�L���?��?9	�?��k��>��`���Qlp�@�/�Xc	2BI�d$��{�2�kD��\n I[-��Uv�՚w������2f�l>�g���j���lJ����R��tta�e�>�M�,�7�H9�ǐ�V/�q_�{�Α��k$ёA��� R���qDۡgԐ�3�0�2��rKK���k���D���g�I$;h�Q��k�)s#�u�Sͩ�f��b�Zq�)}�Mh�f��綐�e����:��VcJ5:�8�ni�������al�E:w:�Q� �^��Jjt6,�U_�=�{�u,f��\��[4M��3y&��<�璞�p�> 0 