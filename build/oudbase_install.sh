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
� l��Z �kl#Y�&ξ�����n�����w�Ҭ�^�)J��{�-�{4��Eu��v�r�d��i��[U�Zӭ���@�8~�qb'�@'����'	 Y8p� ��	l  �'��Gս� )���gxgZ$��=�u��{�9���\r��rk++�~���\��>y"��Bq9����/�\>��Z�!+�]1L��l��c�C� ��p�{���IkЪC�܁�q:�P���/a�q����\qƿ��_�!�K�K(}����,�@Cs:�Y��\ls��u27q��q����,�{�0u�!�H�Z��n�䧤6��-�%�*�E�S���n��ښ����y/�R ���6�A��Djǆ��nw5�5�J�h==��:Q&�,܎e�5W?�L��w�A,�Y$}��賏\���Ճ�Ֆ�z��4���hf[o�;a�_�\�l _0�}��p���lo`�-Gg��͐Z�6�.q-��ᣣÄ��M���!��LҴZ:���ꎨ�A��a8�[O3��	8z�Z6��#öL:�08k���G�4�h�aX�4D�qݾ��Ͷr���ɲs����V��1P�e����\>�{?S��W	!�Q�4�к�H��&_����&`ʭ/�a1���-�X�H)���%L�4ـB����B�.�=����m�a����{P���^J���) ��S/c���)�@�la/^�$EW�92������|Tݯm��`4�����^u�RJ�?��ȘihWktuҵ��Ѐ/Z��c��vk�R�~y�v|@����������wP�)oWKsH�&�2�[Ll��+��Ս����K��������[P��K�4�f��ͥ�����A��j�R�/��/dO5��K��S���Q8<��w�H�,���Jn�7�ʕ�~�V+Md�L�L�������rI�".>�����D��10t��}��^䡣���E�2�[+���j'`¥#9yTH��>�X�N��6w��uV�Rp���;G6I�C�ݛ;@;ջ$]!�Ѫ���/��=��ǖݺ��<�*��t'��i�d��š�;���~�=b��d���7;z�9]~l��5��/� ���'A�GH��i�*��7q� ۚ	��c�Ev�=xB���%1�CÂ	��"Ė�|[V��'X�_n�>@�p���C��OI��y���fR4s��kf�l����2����S�Z��Z+�/:���F�49�.rjm3�b<�5zT`��/k��^_XL������{x �d���;�QDHȺ�s��dk��d0ۤ��G��m�5t9Eu
bW4 F��FLd2������.Xܼ1I��Z$�`s�Z:�ރ��b	I�����������~���������HY��㳚#2��r����O�T��TJ���+ ��$2���g@�.hH��)R"\N*ąa���f�Bx�N@8�R䕫�$�I��˩̫�h<0�R��1]��q�=�5�ԗֵe)E��e~�G�.����)�RKímY��M��w�����~t%��������H�uS 2�����^�p4j��x�q��Gv���5�+��!�YfWy	8*�W��d��:CÖ�M��50�$���n������e�{ӲQ� 0z��¸E�d���q��/K%Tl Iߴ\:�.gtyP�wJ�(��_�تz�M�^��8�葥�l�Gw)b�v�]�����0oX�n�bp�A��v|�.��π�ki-�t��ǻ@ٌ���nyd{k��U�9?���-9qd��mCauZT�P��l�NG��&�/\'Դz=�T�΁��H"z$��QX�ǡ�UXʖ)z�
P4����j*0M��ď�=]�����no`�̧�7%b[�?a��K}��:�������*����d�¯,�;��2qÄ�=�ɒ��������'�$;�LS#���۵�i��l��ܴ�M��y/��BQrb�j����ub��5��^V_8�{
���lK?ʚ�nW^<���z&�zl��d4L�5���6F�"e:(7V�IR�.��.���z����.��(��H�l+yo_yh���{է+N|uɫW���n^�TJ��4,k;����Nf���!r�IS����]�:R��9@�|?Ƿ�I.ˡB��I'��T"���K%�:��
U2	��0~����Oq��IJ�(�hI�ވ�������M*�Qq�u����,C���qK���Z����s)�K'��;@�K�S��C�"]���j7�4 U�T����x�0��[[w�>����o[8�pA�a{���@.�ؾ��&�#c����zu�Fi��~0A�Ȃ,�%���$�{����w�"�>�	�tw�恲VU���b ��j,�^$�ս�͍�*�C��.�T��碱2wG^(�^��j��g�x\�S�,J���(��̦����z�%RdNE͹�K������$1=��ϡ�*��� ,Ķ�㬇��K>j���
	u��F	��a1�
:d�P�1����f���c��a�ԗ�H��}]O�"������䇀`����
o�)�w���
�Ã�W��30�`\6 �	<�!�ivl�>�����VP����{���m���)<b}�7���g��6�Ȇ�k�X����X��bU?;��
8���z$�π3k-�K������ϳ��w���˦��2B�/,X��i�� K6+L%�t]��'�h������+�\���b�\���N���%�Ncp;�����j]B�B��i�-B�dc���p���G��A«�c�І}ԦI�C ��Qo)e/
"�lK���J/�����`MC��2�Ol#�ĭ����Jy���y��3��D��{i��B���]<XЎ���{��;/�k��S3�vH�����vv���8���Mi�`��7$��r�e�d������籔��w��%4jan�=��f��E�'�9�c��tKB��#Ni]�Y���̂�Yɇd��C�<�%!Ϋ˰���iH�Rj�y�tt&6:T�?�,�"`�Љ��2�I��D��~U�3�:��"�\���lno�re{sG^zbW1��3�1����9V�k�Ҥ�a�T[�cT�u���xh��O� �W���������)�*vA�����;�Z�AEP�����B$����Ï�W

�b�ԣio?:��c��->�$��	׵��.s�����r9j���O��"M����כp_�_n��")�g�%���������/��7��h��m� ����S�!"��7���:aҧ�5�jO���f�Wj��52�B{�ka$����LEkwI�G>�F�o�{{��u�u�Ά�&��81�C��rokF��yt�����Ȓ����F�Lmd�6�SY�"��v�U�����Bv����mU'd�yV�S����]�Vw�FZ�� �� 	�65� �Nظ�݂��~���L�z��z���]��^-Ƭ���hnA�y��n��ӥ�S�m/^�}�D����&^���6�Us&Օt)���3t�F�^$�1���V����`�W��,i�:�f5�l�4:A�G�<H�a���=qP�W
H����Y��kfqtD�9;�_9z��P�<,�ᵈw����ڍ��V�v
�m��sd��D�Z�kZ)�O�w�ڄ�k`rkQ�!�^J�"�]Ƞ�B[�1�^y�'1
�kS�C��1��[��������k��3�}���/�M�7Q^��M�����/Mq�8�0��9�\2\���ݠ�d~i�������&��Svn���D�۝�ǧ�S�#V��VLW�,n�xs.�-Ů X}b�)�z����{���1lO�D�g>��9ޕ'i���9W?$��.�[�=zEC��Ų�G��C��2���3�eF�,S�)���nCIp�E�^��0�KıvS�e��O������kU���^h굼5�_s��C����ϨQRes_�K(Պo1zhj0+Sv��{�
a�U�����F!ig�YZ@��1p����2n�ZG��T@"�{�ɓ�FW3��?{6��H�?S�bOe���:�lvA�g��vJh��<!c`,0Yf>�4��4���η}�,�ZT�ll���xt�3Br�Ͻ�qZ��v�zu��:�TO�>�qt���� '�����2��|C��s�e��L�t�c9.m����Ʋ���;��h�%�=�aU8��������zE;�����;���`�a!W:)Ѓ��h����4L!K6
3@6��0����0�J� *�<.q�ͫ�K8\=��t~)׷�K��d��jW���$�P����z��b�p�-H��N�=��@��,���H�y����/Π�;�C�f�� cNGo����+���X-��\�S4�؀Y׀�n��Z��Iy��jz.�\Tq�N�������N-}蘳���<]����hpiչ�P@�S�I�G���
a2���󪓰�D"����seyeٳ��/���g��2����4���&�Oo�}U�?Y������������ܚ��}������E.�S��eR]2��|�y��ϧ�q����\&��z��R�҃���E���nk��{�5������^�x<�Π׀	�{����d}���$�>��R��>F=ٕ?����S�7ق�%"�~�mi��zI�a'*Z�l�l�W��;孩M�9����ɝ������2�6�S�ܩMn�u���$wj�;5�=�Q.���F�Sc�!�ƴSc�7ʘv�~2_CCZw�X�W/Ìօ- USE�^���$�ZN�FÀS�ѩ��l5ʏ�ƴe��E&�b�G6ǖ}Y��
,&���Z���Oi�S��c�\$X�A=�k��c]NL��O�T�W����J:������V�{ �4=�O Ni�{�O��kU�<Vh
�LD�E�ŭ͈�D@zXİ�~"2�CT	��6T����~������,����OV9f���ڤ��0���j���Z"G�Y$�xk0;[�x�ȧ/_tQm�9%Q��Վ�)̚U�Z~���������e���Q=�8y�&����f�6�3�s/պH�B��4�MEI����:�ް�C���5������B�{_6�飬l��pf���l����s�܍k���	'�� �9CۂY'�8�iB��TnhC�iY��\"{��]��s�B���ɝ~���}�z9�C3�೾ъ��^�Ǽ���[�[ߋ��g0*ˠ��rn�����!�<�E6y{း]���ij��.�|��bu[h��GP֠�|��xs,����#��C�@5d�c���X��$a3r�G�v��`}2ߌKn¡5 YAog�RD�cvD��	�z��MM�ϐ�����Lh���{j�K)c��w.W̭��wq9�˭�I.��Z(L�$}��ߙykff[k���L�&|6s���o��N|{<�僃}�������� ���o��������w�LWs\4 ƽ��^���&������Ӛ6��:n��M�>�r�o1؟`ц���7͖�bf��?�B����?�WBh�gR"
]R����ja94������+I���s�ó���~0�����t�ȿ�':�r�@r�[ -�]�e?�Pq���M�cసLB![V�nG�A�mݭ#V�V��	����k�L���A�O�4�@���#��N�S��#f[��#��հ\r�{!�3d�M�z��w���^��OC��d�=L�t���N�R�_~���X*�>=�c77RTՔR`�.VbJJ9�p�Y�ZۮWvao��۲p6����ݍ�E��0{����2D��Kr%<��\8�a�8_�2��r&���x0SE�W�>r�A)�&]���K�C�QR1tҳ�w�����'��4)�&ӎ(��s/��;�<���8��7ԙ9d���B��Ay�I��4��M���p�QE�E�v���e(p"��Ddg���.����V��4�Czt�?�l4�����o��~�c���{��dxE0q$l���8��8��uu��-0��L+)���x�s4�X�����������^����l�v���M�/���3
��X*8�:�Zx��\�K��'-T�?R����E���3��v���E����#{����_�8�����l��]�D��<�Չƃ-
��,ѓ6�t�r7
�p�9:Y�gG�%zJoR�dӻ駿ЛZ�,g�^�݇��
��h�57�d�)\Q0@���F�J�����XX��ٺ;�M���&n+�����{��Ո+�<R��^�5������"���tO�����>F{�C�v\��,��xl��d��pE�ZNZ�$��ƒ�.?�V��?N%#/"�>��8
�'Y���S�l#�E��M0�*��~�§y}F2��TT���*�@�2����8^OD�c��pl�	�-���q���&[�)��)	-��$b�Ƈ�����=����8�ݙr����|�]������B7��X������̺`�l�)�b*ʏ������4�i�p\Ja2*S���4��%��o��u,`�xK�:t�:�97ؓEe�Ei�Dх��9$A@�������b�r��J��OP�����#���P Y�9$��1M~�
r�؀���mv/h��K����VNF��������R!��j�JpQ�������*ְ�+�w�鐡0�"��'*�lhGG����p*�kqL1n������D\���&Ks2�����܌�%�	Q�����I$�ț�@��W)J"mj��[�M�P`�E�����4Gog����٤i��ץ�v����HB?�*�Xq�7K��<��Ҟ�*c%��[����Z�U�,he����.�jL�d5�k��7,*�C��ҷ����z"����i^ �6�!g;�T �Z�e�y�?�p��uu��zF3(��e�@�z�jq��(R�d\g��~PirJ7�ȣB���!��Z�5n������j��Y�c��:�dS��lT���j~П��ٳ��h�Oi��`��3E<ʲm
���x�mI7���璐��� �s�O<:l�h�����!�+�v`e
/���a%d��2�4&m���5�z�j:�1���Q���f���Q��E�b�}ފ����z�Z66��X��9��C�٘��]�x��H���!��3�yX�a�Jy��!'%R�9���r�z��/S#�Hp��eؗ,�y6�a����_���!�af,�aΰAf��\���%�c�qȃ��$=i���OH_��J)�"���Ϩ�R��R���1�k��<�������>�<�� sI�%���E��TD89Ώl�G<�8/��x�g;�X����H�/�o�{H��M�8��t��W��"�uP~�\?��V`���0�� ��S����}�q����)�Ҷħ��%2��0Vd�3���EHg�g�u~�0&n�c�} ߱����ݮ�n_B�|u�6�,����]��z���%�Aʋ8^2����(�!KC�e�#����-v� ��x$D��A��"]iοKŤ^;4%}�W���aQ�Pn��㢋��#IT��{�s���a�k�r�1�)�
$��5vF6|@3d���J
6� *n���<�L�wlb��]~=�:�T�@(�`"OՊ��x��W�R�=?4��e�֛1e���6��]�M���o�6��A��i��g�&��7�3�g�&e�٥�/��yQO>j9��a;�
[ݤQz����DE�%���`yӋ��,��J��K.6Z�F���I��9���#�X�͵h=Ƭ�I8C�߼��=,��Km�b5d* �$��4]�$	�<����{�G�0���\�]]^���#�R|���W��^�'��xyP�2D�"�
�.B�� �����\H�A�E��B�T_D�.&ߋW���x�����������	�Wc�S�\#N�âa��o����a�z�˫'�r��� �l c���i��:��u�N�%
\�hk}N햔ܶq�Q��
m�\+��\�7�߽W��%qJ藨������r�BA�ݵ�Sf�w�X��[*)�>��Σ�]�т���v���V��v�Y	(H}���著I%?��<�ɳ�RI2.�88��� ��pE�$�+�'�Ƿ�T��=�˸`3�� �|sC��G�����yz�͇�)M)�{�`I�QrHχd�
f�lTp�/���ڂ�ĵ��<h�=�� l3
7>��	�p���*������_ः>/���P�6�h�v��	����zd�`�R/�=���M��R5/e�D�+_e�異;~�v���	`�T"^*
�ڶ:J6��rDf�������Q��8�,����12ǰtG�v4ϡ�1��n��TQ�ꄌ�4,TR�
 O|i�f����!��3���[�eϯ+���EPn[�,d�,��S�߫�b��."�����;�8f�ܫ�e�,�e���X^�o�}Bŭ�{�0���9~����Ͻ��
�``Jy�O��x�4�C�@9��T�_���O,>�7D�m�[z�����sKvwo�>Z��S�0�<�����#�� V� ��;B�� ���6��LC�
��x��;���͆I�I���d���+*%�ӊ�F��Not��ӻx"ѵR�@uǫP ӄ��a�z��̬4�6y�J��uL��u��T�.1�'Q횝��6F��ٳ���i���6;K��k&rVͅ�-�n��)ع���� �h[p�I�?�[�!����;!%n��%åY�~Ci��b5;���y�\b+��#�e.���l�a���̱.��m�Ew�H�-����B�v��/Wj�l*\�,S�ס�Ap�m:y���>��w���D�c�I��@�ttp���2��7(K<������i�i	�Bܷ�c�n�1Ny�8pX�5�$�ۥ�Э������ǔƇ:�gϤb��X��؇bBͬkk��7j.�u�弔���Յ�/�..%&��B�1��ǘ�F�V��>�"�z�;�V��_� ��{=����]��ԏI;���.wuZ��cѢ�Aض,*�Bw^ʅ�J�0���ψі=#2-2�ӫ��H�dfD��!�B#�N�*(ʠ]\!��ŉ0(��"�Vv�;�!�Z0�PT���0�r1@��R5�*�B:Iͩg���
�� >�����S����su�$�,�I>L�H���r5/���8R�ݮk'�,x�[��/��ISV�,�Gidh@HCϬ��%k�u�Zn��,����FWɜ-GwUy�Q鳃Z[?2`��m𭥠etk�}����q�=�	��(Zr����@�	��Z�r/�x��U�J#� E�]�+oʙWe���f��3��}&L�9_�N�.qC�y�Z>�B��M���,N�v�?���a�d\#%�{�kQ@\TK�~��[�12eYΗ#Q�+��6���Ʊ�4|Y=������MT�^�GWS)��3��E�������uQ�����{;��q���s�����(?Uز1���UpW�~W�g1	�o�4��k��_J�^�=���¡���Զ/Z��զR�yť�ϡA$wz�Sꁅ|bT`�)�ʁf��E)�dO�4Ի�G+#�%���"�	�U� ��	b�3�U�q�����%�7���h��(�h�|0�Sʈ.�Iw��}#���g.���'��3�Z�1�p�?��!��c�0��Ƃ���k�<��]��`xe"38k_s�cT�S�ou=��/-˾|����V�}�Fr��.,V�����/��"��u��S�S5-Z�R��(�B��X|�W��C���_��,�������O�^å�1*����/r�Bq-���R(.ϐ�K�O_s��M��#�&��vIe�}�����Բ��;�g����_Y)���Ga:�W�p��� �T3��%���Z,ƍ��ښ����r��:��ri�jkiPn/�
U�R��y���y����_�{/[��2�7Ȍ^��v�<�3���}��/�J!t�N=���Z߿V�n����4���dH��q?��q ��e�Ժh�yⅿ��a!���a��ĭs�*�u���1���?��O�1ut-F�Z��w�E��)�3d�#ix�r�=/m�F�-F<ְ"������6z����6h |� cۺҍэJ?S�rm{��7�(Ѓ�ݳl��>�MjVf��^S��.���1�a�]��FW��I&����١��1�C��t�����-K�?+�8�+�<B��4f����;tVG�,����}@�@��i���w��ާ�I"J�H3F��j6��1Zu����"�i��r�lR�c�p]��2�Yy�#/d��e�������ÿ��:VhT�����T�5���mh؞��l��SC3�'��dk�;�-��P}uukL:<�	sͪ#ǉ���,������h�����>��)����pw~ב;��.<��f�c� �QoiA>vfA�s��E�a��կ~EP�C�� ��o��	�,�-GF��\>�t`�����H���@5�|>�_�����Wޣ^[�0�j��C�u�g$�L~�U3���� �Cs5��t������/EU�I�s��6ȇҍ����P|r^��.b�y�h ��=B�3�3�φ4�i�N@(�6�#=���}[_��(�nR�F԰`����>
[�Oel� ϰ0C�q��LG��:�X��!E�J���q�ol�l��lD[,1r���#�� �v{N�3��h�"�[kT4�Tt~g.�����:��6�����3&�
L��~��qu��h��c[�\��e�����T���$; U;����^L�*1b^�(�nr��d�FjEW+S��)�X���YŝF��/��D���VW�QY�e���9�զ��:ɺ�~h�� �H&���Ҭ�ШhF��� w�r� vQ���A��72��@�t��Θ��b3�KsR'��7LF�ܭ��wp�C�8�\���Y]`����֛�%�i0�t����3<��K��J%M�f{*�˂��e��x�j"&?FJG��p 3=jQ\8��s�t~��ϭ��s+g�G�\&'$���~�%6sE������񐖄T#ڵ��w�B�#J$=S�^R
��pb����PD�:f(�4�Ȱ�Q���g�e0pd������-��#�v�2}���0��Zk�F�1~�Vr3<�0Z�����J���*���r�|"����SĎM��e�h=�g�������PL���ͽ���?��4��E��5��,)���l<荧��"�����s�9�����ƚ�ѹFMŨ\anp��GϦ�|c̣��1���g�ݣud�l!�|�/�g�n~@�`�2�v4�$���-
�-~�E�:�a
<����ǚ�x�'7$p���I띟��O�����Q������I��0��I�(!�v�O0���0�[�j�i�"�5�Aɮ��&aVf�~�(�+�Q���?��`2-�I��:���'!�ڶ�b 햊 )9�	�`�03��LРpmԇX�㮃^��u�j4��{�`m�x�l6��`1[#�ҎC��`�K���}�	�0~6Vo�?#k"#8K�y�
�֕ f�BR�����*P� {Y��yQP�d!P��a��ݳ!�^A�h]���N�:	T��$"[2�����Ѿ�급�7f\�ˀ��_zy�ZM��c�I��R"5aD��MS�ɜ�h��X�/�^۹K;F�H����T�D����Ӟ�����+��F����c��T�B<r_̴xd��A܎���v���.IP=���ϥ�9�%�	�w2��U�bKNmUb������r�S�r���ܑ�&I2f�X~�f̈��;��Y�a�� �i��#���dTvF:����URa_��f�puz��L�;��wđ*��4�ز�3�2^Z�TLs�cމ���Q��t\�-��b��cr:h}��n:���20K��[��<�$u�Ff�Uem}1} ���H�8Tc�!M{��!���<�qa�鰨!S�eȮ����]v�<��8�*GI��i�4\HY�ģua���M#�������Ж�w���:8*�:T�"�q��z�C�S�怟=3M�b.!/����$��(
H�HEg�a� FXĒW�'�o#=�ǰ�_��j@�Sï��3n�م��po���`JXWi������_�%��fe�6�o�-��n�5�IT��ʘ���`�9����o.>^�G2�;:��V!̻�ovB�?�B���Hѫli�0���E�s <�K��rG��qVk�6�2T� ��c�A���&h���Qw4���2d��M��� �9O	����>ҁQ�/���İN�i��j�'pf���1�6��S(.�88�̥܄���N6��j˪G:�L�U�2ֆ��!�&�cͼ.t��6�ӥ�������s
��/\�iA�贘n��[����D�Z��33��W�h{,�� �`{�p=�8���آP��ح(x�2y�_<��4���Y��F��)ke!D)ΐm������QphR�jA���އ�,7G���_�����"Ū=��Iv�d����so�O�e-0z��\��г1@(Z>D^"s͖��Z ����#��VG� ��Y�ClVtԙCcf5��E���3�'���[3��%wDƫ^�(�g�K�+9�z(�	v*$	*V)B쒢Z��]\�T����PF��.�g�܍.��� M&�B#Eb.��©'�MOh�,��:W�׳t'O)�����3�8G|X:�??���N����!�ԁV7�=�qL���$j�#�@Y� �K%b}�[-�
���W�/�'��8��)u|��)Hҗ����قZ�W؋K��hwJ� qՕG)���Pq��"}��7+_ȅ��х"�ZT|�ZL��E���j߹
��g��
��Dn��*��)�!��@c�@8��WO:�z2���B�2���@��
�L�"�q �}h�����>(��󐡐YfU�<"�lwԩq���	�gLU�Py|O1"��5�����Dؔ�k��([e���W�3���aK-�C!�+h*���͝�>:�p�j��j�^	1X�#	�0�F~�TP`��G�F��@G�AY���騾L�>ٌ���(���+�@\?o+,<rg�wG�\ŷ��J���G�œ��c��e�h�m"���G�:��� z_�j09�l2��1��P_<<�^a��WE@�[�cWW{�y����{����/{��y�*;P�׀2��� ����ˏ����WJba��Fp����(�!
��S�.�!
]P7i �CRO�7Ũ���tp�8�W<*�e��{�3��Ĉk��cdzV�St,�EEђB��������m�h�1��,�jG�ݡ��5��F��� �O��Ӛu��kZ�|�z�6k����e�6:������.M~�J.��I�Hn���{�g|1EbI�4Ě\M��"Z��J�b��i��,3�X�&�L7
i�ʀ#��D��8cH��w����
��+!F��q���x�e2�*�|H����c�4km=���=zP	?�4���� Z�ǎaWXhؖ�B��B�G���adh�vKn8����#)
"����Wr\�Pmx�i<������ph�B5��?Jb�b�I���0���ر�������j]@�ae�X���������U�"Xx�g�z��1�n��J+����z=G+�Dt��z��8h���(�P#�Ơ��w
��� ��p���~R��X	�*�EkEg	t��9h��IH�V�Z,t\��g�X�L�A?����X��s�i.'���L�!O��ԓ=��H,�cw��8�@1�3h�泝>=C�,dZ��e4�`>	�.Sx�������U`��}X�t�Dą�B&�!�[`)'�j�c�"��g!�K>��A펏�3E���v��d�67�;�j�������рnr��Ӹ�?�+��B�@����?�"EPN����?r���<���rnƿ�V\�����4�5|N���[��J�mn��N�&��sSR~�D�*
���c��z�SR�k�½Jm��4���
0t����y�y��\�a��%R���K�F�#�4*$2,���2�}y��8���\���t9" �.��#<˰%�#��.[���2\/�ܖ�̮��	�
��g" ��׏\�B �S��S;nq#��R/Q2��Ax���]�4?� �+`�s��!!�� #�����|l���:�̿�ɭe
��*ȝ��������+�������v&�1��C������oo ��Q� �	��ظ�4�k�u*r�����P\m�����eS?�C:j1N�y���z�b&�ae=� nB�f�.�2�T2�>�����>}k���n��|����
�g9�!�p$�'0|!�ۻ�](?�W4�K�yp�J���p��aB�B2��#CD���ݪ����j�æ^�����c"�V�K��d$���e4N~iM���N��	Ȩ����B�y)��y��O���_;��b�s�@��]^b�>ZC��e|(6C��-�Y��b�X}L�'�l�4�Y��	���T�87�0r�ߝ��U�45t��P��?WX���|[��_1��?����o}�;3o��lkM�[#�	n��fn¿�������x(���+������ H��c�2�P�tA�D{��4�WC@�o�����_r�vNSd
\ƽ�2F�����Z`�/�M��դ���_����i�l�z��>�V,n��jg���$��6�-BX��w��NP3�:�gc&��x��m���e+^5��ً��kܾ���ésb��6����Gx{i�A/j�����GO;�O���I ��32/ ��N ��F���4JҍZ�qW	4NIF#2ܠ��1�x?�	+t㑡M�i5�*j�_qg1 d9�x��؈z�i'z���(ɰ�w�a#�`�&K����7��j�k	�PG	A�3j���R���Β����о�%Z�Jvv?ۉ֡�y����&-7"���
LZƊ_�|Y��_ӔEÚa�_�Q�v;�v�b^�C{5�#5��H�-+�T�}��X`:��@��-����r� ��`�V��=�� �����Kߦd�������0�K�������2ή0�m�Oz`F'�Q�Z�X o�H����lB���V�.�#����5"A ��<v��Z�_���z�{*Ec���0������z���� ]�y�6��n�=�Li_�H�L��յ�6p- M�{o3]��9�Q6����g�ݡFIh�d�B΃��c"^Ǹо0��l+��Đe�b~v�l٩I�����gC i�X����m��#�*��ha���b1�xD1>@�Ҽb
�N;0B�������f��k��P�BC��Z��j�%�>�6Ek��{a0L�i��R��3�]oe�%ԡ��'�Z-�gJzM}���X���t�
87��f�@E(���뀅XK��[_�7g���2��_��m�e���]�//���eeeym�������M���G�ݘ�P;�)2E;_�l#�am-4���t�_E���W���<�J��e��!��*X�*7U��
o�:x,������e�8���Ջ�w��6�X?�%]C;��}/˗�ƌ����e�1��ǵ3�/�����$�QrnȬ I�E[���څ/
����3.Kk��"Z�[n�t�?ݗ����*��v��Io�!��o�?�Z�J����vr��s�$��/�����_ϯ.��!���>��o��})ڵ�d�%���H�r����6��W���?���G0���*��� �ԧ7@�V`�������	�ޯ���Vݽ?������P��2r������������bqz��*�Ϲ�2�3�+k���ǩ��2����/�Îa:�W�Q�.������|a:�W��85�L�V��&\�(�_~-8��������q���ϰ���A@|<���t��B䚦�3I���f���_(�r���/�����R�ޠ��y_o̰���D4��/���?���=�����ךV�?�
O�4M�4M�4M�DR�}ܸu�՘�i���0! ��#����3�߿�?�)��?	����!�Lp����7���y�����C�əV�o>��ߡ$��"A��Ggj�4M��*����3�{F�����o�����U��nsf�������N�}k��~G�Og+{o͘3���Z�wn�K����z&�_*?�}D�߀��3�Ʊ�ot-���ۍ~�p�\�H���o~��߹q�ƭ�ƳZ�:����4�	��������w���Џ�oC���� Of�:�g̖�Dzq���7���e��D�/�.���\��%��R<=�y���K���|����o�k�`�3�ݿ�N��⏤7��k�[��h��(�}3y�����֧�;��۷���w��@�!r���o6-s�֏����ф7�mj]u���n�f|ɠ�����Y���>����.��_8��nPd���A}�إ�	�d����w~�s��ڇ��������ޭ߻���h���������\s����N~mb6ݾ�ݷ~x� �v��{?�я�'o��X>4�_������wޞ�y��n<ŋk�V��o�~���7������������.�y�ց���ݸI�d��n<J���dO����~��z�v�����o������?,ݽ��g<X�����MV��7ޮ޸��o��Fc�ݾnB�?�ᏰV�7n|�oʭ�޺�]���h�}�]1�W���5���̽�Of~9ӟ9��33���_���34�����3���?�wg���?��G3����9��$��$���Q"��K���i"��%
���G���'�O��J�v��0v�8q��2�2��|�_H��ğK�K����������;�G�����a�?K���"�_&�N�N�/������{��N�㷾��W�%�O%��~G�q>����14���ǟ|��ז����� ����O}���;���J�<�B�2R�c�E�N��l������r�/n ����o�G?��;����6�����?�u;S�&���yx��Cķr?)�¿�V�ʭ�@ⷿ�ޮ���&L���do~�|h���)��ʭ[�gp��I�CI�����f����;��%��H&���A�$��{����'�%6��Nb/���%����h$��n�LX�>%�W��ğL�s�?��3@�H�)�/'��Ŀ����F�o$�MJ��>������	���m�T�TRM�O>�Jܿ�;����i�M+捺��iQ;��f�2�3Lf��Lw�5c����7_~��J�B˫�.bi�﬙6]~]& ��oވ���K,d�f1����i��i��i�ڤo����j���4M�4}�S⛕Z�ތw J�k'��W"����������t�6����t��5���L��6����	t��?+k������2��q�X��L�2H���0�t��"I��r ���1��O>�_c���+�+��bqz��JҬxo�?��E�t��v�E�7�tA�F0v�<� ���͌�0yh ��s�ߤ�ewl�{��	�ݶ���L�>.����9tg��x�����KD� 8�z��7���u��h�t/N%�wJ�"�"%�Jy�'D���+������DA����@ov,������o<6��)2't�/9E��gc����~
�8��n�0�R�'Gf�z�>�&��/LB�E71�ξ��*0��}%I��P1p��_1�[^˭���b�8���$�Ɵ}ԩ��L�de��������c���a���\az��JҤ|&�m�������l�rh��n̑��d�cP�d}�)��~�`�[���\1�~-�f��\����D+K*z<�Z�t���nz�+�-�����ȃ�-�O�o������u�6\b���F�va�b������<r���Q]��r�[�����PM��DX�$xG��N�h7�i�J�+�a3m�]���n�7w�;����I�@���,_jQ �kng� �� �ϲlN�]'E�%R-�4z	�|DF�t�XY�%�Q�H�`��Z��+��\�mI�~������>�U�1�� ��h���Ì��x-˵����
l`�}+4���V
�N���<�t��=��!p �wKK�~���7x� 4�N?�C�"�c���"M4�@���o���gO(K`OX{�,�^��j���$��8�}²��1,R�L�J�ˈ=�#M.�F��{����:�K׽ľ�)z��k�e���`��֦��դiЏ��������s��V����9e�}�} s�Wq#���4��n����gYJ�gEG��|�Š�p�# ��{@����%��07菞��Li[��/6���M@J+�����T��5M����.�4���C�quu���J�t�����F���`��T�I�;����r8�v	�0�����H��&[8p����/���-~��c!�8�v���[[$�C:��[-�쐻wI���ep�V���|�����{�ٴu�K��:1�TXZ^*.�,���;7w6���՝���ҫ����z�P�=yg���b3��Y:����J���qשS�u�a5)c���R(r�o��_����o*�]~�؄��mg<�F�KG9&-Ig ����$i-%�-���\��d�L�ȭe�/�.=DI$0yz2'Ka��C�i$���a y�@O��9'P�^����C-��@C%�M�S��� N�F���"Z�#dcj�'�*6?���ns
��=�X̐r������m�
��}
������5�C<R��,Kn&9�@o��RԼ���]W�;��E��0����Y�Û�?����w)~�3����P�.�U��ַt��u�����GSC{L+�i�@�EN�8�@m�ώي	�x�\`?p.DO)�g�}�G��m$���zWg!��5`ǡ��[��SwH�:�C{�` �	�;���dEgT�/� e"dg�f�N���c�~��qj�n�|��v�!I>�|�Y�य�&���3���p�,�-���$�fq)(��E��/��ec��x��BoR�;{�,%��zc��r�!����ՠ�����e�4��;p��T��U�'�B����=w�7�F���y�k�Y�*�����C't��W\^����k���
��k���wi��Z�*����D�$���@�O������%��b�☜X�N@�r�=ݷkC]N�h���x����hc�V�bs:�E���߫�����ނ����W�DY�\N�yWN������א2�̃���v03@�u���G�K;Ҍ.-P*���@�a�\�M6wj孭��������/���;�W`P{�C/�K=�{�O(��~yc��.��3#�r����oR��tq���
�)n1�;'���P����R>(��!"焭ki���)��#~��F{ng�7Z���_?Q���-�����h����mG�d��%e�G!T;1�3Z��~�ٺ����c��\�1/��I�QY���� f�@�X�[�t�uA�7�o
�il���|���z�1ʂ����2���X�G0+^ر� C�ޠ�ۥ�G��
3�FN�_[EoLR��P3�3ɠM#���/���B.G���W���U�'՝�;�g�}������.�5S�gr��՝���Ƴd���p�����=��Z��f���9cn��{h.^:Ժ��#�MӤS���[�F�������
�9z���V���^I�����(��Z�7[��ӕdC�ŀz-�3��kU��P������a�Sa;����o��힠~�Ew1rA0�<�?xTI�
�<�s��U#�� J�5؀K�Y����iS��t�l��K���@�xŅW�Z�4�t�������,y�\V����32/ ��N	����S��VR���%3	�Q�|a�������Fy�t���F�� J�`.@��dI��HX	���v�i5�*j�_e��) � �;D/���b#�=����_���!6vw��!l$��dI�P�����S-�r-���������q`̅��e�n���n�9'�h:�7��KoҖ�ӝ�N&u�2V�����<���,�s�X ��++�rf�١j'��I�S5~gַ6k�IBZV��$0��1���J%[��sg9��-��=�� �����Kߦd����f�a����)O(�]a(x
P�щjT��F7ț3ts84��><�������Fl�A�HPH�:�y����ۺK�zj[���T�@����u�n_<���� ���;����̃�����eJ���E2w`�4��e���ky �h�{�!躶��a���9]<c�T�Ռ.I����`|j��1����b���pb�jM������e�m۲���?��5�]e�s65"B�N��ȰJ�G�B<�0\��u��Y<�@e���{�>)�?p�:��R� ��/xH��]B(��#׆��܅���3�*;$�4K��7{J���J3���W��7��rM�A�z+/�=�>�j90O�S_Sߴ��ZH�D��8�N���vM\<P
*���[u��q_�rc�����͙s���������M��Q�_x������Y]��\I2�#��\�Ø�l�(=p�$Jn��bvݵ����h�/����x���������\(���_[^�M��U����z���\�j��YGj���`TL����K�x}�3Bf	u��2�ئ뇹�Oj)$;x���;��3J�/�y���<��������%i�2X��)�fV�$O��K�.|Q�/�*�=�
.Kk��"�;�ç+�龴M�V᝿�wO�:���Dv7�O�V��z����=�\"IT촬�s�^�/���z~uyu�i����'�}s��H����W�����W&���p��+�UX������t�_E�������Y��J�17@��������~5rzr¢��#x��Uw�O�u���Z���~r.@F���++k����"��k��S��+IS����(�ON]���\�x���c��GOa���#�.�H4�:k"N@�(�~@��~NW ��'��2�@d���:�����^u�R�{�K):k�*c����|�L��/�)��G޿Je�f�хr���H�P�����Jʮ>F�����:��;CV[g�-�D{yS]�H��[�!퇾QG������1J��[^��]˭���U��!m��AU�2�XEM�+i$�k�hN�7� 'pO�P��u��lA��%�>��t�?,��l5׉�0i5ЧT�?�R�f
��XIƦY�k����	�u8{��fw�2]�u�ü�[�P�bf�τ��Y�4M�4M�4M�4M�4M�4M8��泦� 0 