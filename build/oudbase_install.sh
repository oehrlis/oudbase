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
� g��Z ��rI�*��}O>~��p8|r ���&.�+�nj!5gx3Au��-w�*AV� 
��'��?���7�������~�x��Te� I�RwWvKBUe���\�r�����S�Zm7������Vk��HĨ��j��4�j�V�	i>t�0M���@S|������E?�&���M�3�^0�����1{�k�*�9�@��a��*4����%�~����7D���_����@[ٳ������N�K�v|�y�A^L}ǥ�Ov�%z�u�[қ���$ k/v{�P�g�s:��LLߧ���A6�f���AПL��7H��	~�����Ko��9�e������cg\x�Ё�#z1:dͣ�:�ٻ����>P�����N�^�7����S��5�]3��V3���^:�㹉,��v<��=�rH/ gHϚ8�9���%�]s-Jx��	�.�<��Hx�ekN/`}~�L�^��Om2�&�����s٤��\xӀ�~�[���k� �jC`A0��+�s�9���T���H� ��ҧ��|X�M���j��[�Z�hB����:�c�%��0B�V6�Ӗy:��@�p)��̞K�b
t�� ��D^B������a��^��b;z�{vrttz�{���Qy�.m�s\zeor^�a�6����(0p��F�À|g�ԿG�
�uOz{G�;0��ݣ��q�pw�xz�[$����fH��;'~��1��_��;�W����n�a	����˓��ӳ��Awge1�:CV��Ӄ�ݽ���ӣ�?�+�h\d/_��C�+�7�xye�X�vNNϾ�vv�';E���Ʉ��i[���~C־����ݬ�5KV�������I������71aA���B����d�ZP1��3�����"�}���[���v�7�yN����8m�u��м��\;�S���٫]��?'Ž�WGd�W���J�Rr�7���'_v���.��{�~���j��&�+@���]Z%��.Ґ�UN��F���SF�˴�)+%��$��uA��l����б]� ��;J}/}�����:j�&ALz3� �:t/��W��d�NL&x�ߒ���{�<��q��5R�����qCJ���w_���d7_��v\��N���[�X�a���Z�/F���W	{?p
7���u�K�#�Q�3b�h�PK����z�#�����S�$����ݤ!!K���)�vr��='}
��|l-��0���]� �A&&q�ɢ~2�A`s���N���A����6�R����T�jT��>�������׿�Z)zr�]ԝS��.P���k��-���w-C9%�B�7�hن�|S$;D��� �JvaV^V�u�a��M�����S@))��zKj�j6�0,)�ӿpA�tu�략��������*n۳�Y��s{����ബJO���=�&i�����>}a������!�sH"��"'�,�������	�9���0Ob�I6��٫�ឋ�v����+C��w���%p1t�|G�sb����8qsr>�#�_&=X\S��!y��	�f��VQ[�
	���־�(��\�*W��@1��]/`���vƎ���7�������n�ݜ���b=�VV���Ӏ�^���3D�Q�ã�қm!��?�a��a���g�����o� =*e�H\}n{��]~8@Ǩ��o�-ߝL`��96�"��s{Ë�ٝL]�!����tup�;��}�EO�Z����}�Y%�l���F㸉�j��ץ�$~�R�kG,v����X"�А���x�B;Q��u�+Z�:v<R�E�+^��
��YE#$�?G����kk=vR�
ɮL�5����9z�2��\���}�zW.�z�W��RPr� �z�N�Ȼ��"C��|X4bN&#d�yŦ�w:�Y�2P�Ԗ�$�jO)�a��&�/^L�U�(�Ag��|V�)I�FͫLaz��!Af�Wb��Wˑ�p!����_	�8n�'�0�����7�.H�Jf�,��NqL`�8N`D9-W��Ԏ�5#<�B
aۡ��l'�n.��	������g��Z�Fjú�qPp�+�B����
F[b��C!�z�� ��)��L!N(��SEƨ�8�`���ψIհ�sf��5����o��tE���B�~Lz[gDC�P93[��dl&8��KAY��t�%{W�?��cR�:֨�_(����t�B���a����)����L�^�Ÿp���9�1��^~<�p��F+v�!��؜ 2(��!Q�\\:ۻ�?nw�'ȅ��"�`�����ê�\���t図N�UDF4=:��y������2r�(s�"����ur�=��{�9�˅D���:V�C���l��<S70vF���?�	����\�������2��E��D���� �I��aU��(`&.�_��u��Bqsa��h�1̟v2�ƮIC�yX�$�Iߐg��hg��RN��`��Z3��������<q�+�(�C�n���R�B
��b�K �����]ё>L�[d2��]�QON��c��ԕ�P�WG���Y*����`�P��kx�z% @�q�~O�1�������Qԑ�Ch>����v2�L;���u��cx!Ǳc����eXb��	��fӆ?�����#��U���J���b"��у��i���do��G�a���nU/B�#ƛ��%�d�W*��+o�
�|}�:�L�����)QK���6�-7~��T\�����[�z=uN�΁]��Xd5�E\�R[�{]�e����N��t*V�3\b�-I��x!��&
�����,�x���c�W/�J���%��GG�d:����o-�̫�d�E����Ǔ�N�[zg�W�g��ׇG'ݗ�=�_��No��WR�sǶ'0��+5|���U�e���
��Z[���]�x�.�T�&7xa�J�;}��:k���B�^_Y0;M#��ϟ��4l�$C�o�ʖ�%�uv�'�o��Y��06 �RVT��-N�a�(�c?eFp��ҧ�w*��Zv�N�$y+�G��wv���'s3��.��%w�Թ��ô.eMk�@��ڨ���]NC;�b)� R������qoHE�X����&��+��!����$�7k��~;�;To�4������t'����E���'���U�>��w�Q���7�j7k�*��6r���H���g���/E�[(�����9���ߛe���T��z���Ϟ�	'�P����1���u����l-�媏������	~k5�G����p?��v��8��=T��½�4"�(3�Wپ�������6�eCdSo���҉LgH��#�x�#��:�$ב�u�I�#��H�:҂D>�"���p�37�\Cz�\W����K���Z����/L�v�ۙ�-��h�� P[�By�]�% ���$?���T!G��v��C>�.d/C}q	�ʚ��d�O(��+o7*oI�|���(��'��W�d/6�)�Z��"K	e��f`�S�"��1!��tO_

ơ�m �=%ք�i��5(PNC	�=f󢴆����i��N����l8���z�"���.�꟟�F&g��i -7`s�^O�Eb���v��	a�٠��{���8���蛀���Ű�����M���D����ʍ:����W�A��8B-8��7��р�C[b�a�5���Vޮ���o��g+��Feu=�z�
G<����m�qVhiQ��ԧ��Z�`ʆ�d�#[C�>!���[d_���sǍMP*�H����apߺ��o�cT"���
�\Z��zxc�¢~�����֖J�=�Vd�w]� ��ɛrL\�K��r���O��������_���eP�R[�z��,��u�J�+,����Vi:� �7�XT����*�*����u./�@�{��g�{J�羇��4��C�T�v�Nt��֬����>����w�b�S-�F^��3?� ����ˬ$s��qpNN</����F��QC$�{����C�}�����z�"	`�Jѫ�Qa��� ��b3{��p�� ��eV+o�o�����y��O뺔�/#`�9�L�fs�g+�dܜ�M���
:{z}v��P����ݨ�1��@��G��Łh���!��6,�R����	f��O�%.�H��LԀS��aS�ز��ͳ]�ZH�W���*�� Ң��6H�L|F�J�Ve|�aJ�F�P*[�i�:�I��J�P�Q��	�C�^wQ��~)D�Qv��XL�ɵ0���4 H�gR����nȞe�q�#H��A#���~����ӇT�y��/>.��� �������A��=�xM�~�����`?e��Xu}8Q�	ZVS�\�%�n�J��(��-�KRa���w,���F����˚.T�br�؜�!(D#�wUE�9��ʵ^��'"�t�y��֛�P�Ө�Q������>J��??��g��~)���C�^��V�����U���<�xK����Q���E�<w�d��\�&�����
�Y�~
�ղ��.��j��:����_�C�Sr�^p�tz=��?v��;������>,�����g��=��К1��K%�{�vr�
Q�jh���?gڀ|����ץ;&e�\����w��{�=<���:�w��/J'7�[���:r��\'7��-}I:����J��R�ݔro�T�͕ig�˕iseڟ�2���~������=��>�m G &�JUF}%�e�͵F�s��\k�g�5*�����d� �r�G2Ƿ}U��3,.������ʣ��i��i�^DX�G9�t�&�����D����g�w�<<Rd.o�녣������7���xp��Ί�����^0�Wz�B!��"_�Q�Du"@=�bV�	)��)�M�'�uTo��Q�7���,��ɹ�Y��2�z�r�ar_=N]y��DN��H��6au����(¯�u�u�&1���.0(\�U�ZQ�������ET���*�19��y*����f�>,2�+��(��TUUEI�܉�::x~��<��Z,Ȋ����BJ�?Y�Eƨ���r����'~�{yt��<������`�ܿE��E��9�iú�VcnXG�k�⎧�gtʪ<Nm�k�G�Z5��96|)(���ߍ;k��FYh�ъi/�m��i�"uQ�B�x!�bQ˝��+'d�٨����c�vgx*�2����4���ڨ��G��`�|��xq�m����S�(B!A3T�c��$[��$I5�Ɉ�&�+3q��Lv7=�o
��=/'��F�g^��XJKR���U�o�>����P��|�Y������j��B��F�m��5�����\��Q������>yr`Z�G�^�&|��o�O��7�����Zd����b%����,��x�ϟ<�W�����xH�C�P��O�{���=y�o0�ȴ&�R<�y0�T�y����ױ�����=צ�<�K��?`���?��7�k<
�}�I���@u�^���Ѯ������~���|��P��l���S���+Yn����V aRMZ��p��~"إ��	 ~����i	���=�=��Z� �s�!T�5G�	���U0�^� ��	�3'���M!��(g�t�/�n}�.�JPW��5C`�ɒ�(���i^��Y_5��N�۳�ћ�������?�rY����Fb�I�pnF�jk��΄�,&@��d|e��1�j����4�[��A�`_�[��)���0%=%�0$�_���8x���6J\
�g�ۼ�H$�������Λ}������K1�L�V��ü�����\�U�ȧ\Y+Y{g�Gp���=$jzƳ����}5󦐙����AɅ7�<��\(1�u�g�:��wN�=�c	2��������j/�̄,P���dTHY�+�V���r�\Md|u����\j|�e���;EN��5�b!��b�W��3f�&�����)�z����[.k���vIQ��Y({Jה��N�U���ulG�՚30E�	��n(��Q�
+�R�*���1�3�H�Y\1�?����&���sX����V&�+���*�ͮ_Ic�������q��j�#��N�������Q�Q����p� :@�h=0�r���m�b�ƄpG�΅��1�ь��<Iru�:����w����i}2�ھ@�״���Z�J�)1�J�	r��*F'���1�P��o��U*�C绎�2�}��~4/M>�H9��d�Q"�U�<=:��W�cjK��oP���5'�Dʏ��A.[C8���XD�������=���a�iP��T����~�֔5�"HeX��p�xo%~���/\+��N�{��~\F��Y�ڔ���6� ��oB���%F<~w����+�aKÏ�q�y�ĝ�Gi��^�Y@'#������Znqx|��s�-����(��ax�+��	E�N �TԺ!�!���*���]w���?7�X3ʕ�{�=s�*{�W������5�j��0�LdD�#���h�l"ŴJe���|ߨ0���9�p����޲-s@DM��B$0����SU2���`=nH
ˀ/C�X�(��f��sy��LbW�-�	���7��)�f��E'��r�v�������yaL��*��������HǗrNƕ�T�pB?�-2c�Fu@�{�H�w�{�����7P���ЄU� �6PK�!����3�y�GߎHW�Vۈ�q�(MK8�sD��y��eh������Y���fA]z��B�<�{e�{귋Z��nt$V��l!�Pt4�#$(&���|�!@�����ǭ����t��0����t�u�T��N�T��b���{ߟ�r�r_|3� Up8� �$g;�sp�Wp'�)��)*\���cEB-z�*����I�����ؗb�û[�\����g��1�_f4���3	�<@�be��S&��iԖ��~����] nyoV��J��9e���p>`SᮿP$oBúp$���4fF�b����� ��O�hڮ�B4��<�M��)t'������'�7�̝�-|Ϩ�׈9�f���%7����Z@�#o�ʻ{'g�c�{����	���	����M�<E���U��?�5tbcQk����O�����h��E�9f�q���.�J�B&�1��"�[4O���pyT����X���J���5�Vʿ�}�T9�Ž�i���9�8Ũ�pXf��!@�;���}>"Ȩ5�[���]O-�-6wm%��DI>WD+�;�J��H*�Q_�S��Wy�����l��n�#y&JSбz�gY{z^�����Od�0����L�(p��Y�b��I����Qz����	�/as��)�M�]�(:	۬J<���D�===&z��f�f��#旲����G�:��䶩�bk�*k�'1�zn��k�1_��Y�0��b|̵֑R�]�1-��G��(��RZ�]���6��0O�f�E2	}�@�^2��u���t@��wV_WwJ��� [� ow�&��pf�򨞅	�&��6(qbԯjo*+�BL�=i �'\�b�3�8n0 �_��>��d�������}<)&{$$�bߋ��W�~���M*�	��F��H�f��Z\En�m���7Z�I͔�H�$�\�� \��EP� j��@��jR{&d�n
�`:V�2-�WUK�U���1��؞g�Fk�joT��d!�����Nǫ_s�2��&b�f�ߗAY¨�~��c���w:ZZ������ą�[1C�
։��ՃP��	W<:����7UN��Hv���m�t���vV}?*Mf�Ճ]����j׿Y�F��UW�涚�Q���^ ��.x6]!��Z�'�L��E�����`x�D�J�L������	�--P]�!L������99���4�!܎j˗�:\����y,Y��{a]b��p(�3����D2i���(�d��N�L�����[V�u�v_٨�y�2^�-�t�/Y��^�P����:�Chg	Ys�NQ	��-�԰����E����U�t��TE/��[R$��H��t��Z9�"=�4	W(�ٛ�Ғ�4Pa^1�v�����7I�c���ӛ�_�<F}s+=G��Ђy[�VF^6��OȻ����;�M*���5C�+�%D\����.U8��(3��J���2!�|�Q|��m:F+�3!J�p�3[�������h7�	��(Uk'�f�y������x����I�L��:�X��Xo��^q	�v���
n�����KQ�ۢܨi���M{��ܒZ��yV��^[�?� ��SD���+�"-MT'oK6F�t"��v'hł�XE`����φ3L�����1�2+��� �}	ο7Q!�B��X�PwPI;�R���3Mʔ��>�]i*ٵ�K(���
���K}�x7��Xv�rNͮ�O/!V�%���*[M�Ӻ�����5)$F+��Oѥ�Q����b��f�N�\�V.�kH�uGȢS���މ��}Z �i��}Zv�٩�ὖ]�"26Zg� ~':��܋�p�f��Ϳ7��h�(E�J�1�
s`n1x;�%Y�+�V���"�;�/�)��L5(|�$�C���q(�/���V<��������W�f��G�#������\r��O�Z�4��,_xT���?B��$�4a>��e�S����k��!�F*�a&V��de��m.�^��}FȻw$��u��:��w��)BB+�.��V~����Z��>��Ϙ6$�β�8�Y�e�X{�0V>�q(� f}��VYM��Q��c
��S���I��dT�mX1EJ��u*~����Ѯ��n�KRgb�v����yc����|!�d�N��W�C\tq#�W �(~��}-Y�g��;?Z��M��D� �����0M������ғ�M
O�	�Hy]Sn�Ћ�Z(S���~�"�� �B-(������14�S�ZkN���5(VhIMz�F�{�lgE��Sv�p�+��������{�`��֯�+t�Ǵ��{��p=22�b����"e5�k;�o1��}HG�I�q�a�-$&C�E�&��2V
+$/����zŬ�)�Ġ6ob�]Q��宩7�� JU��\�=�����DV����'��r����Q�� ���p㧨^�Ol>*�d�O�P��~�ٞx0�k0/�����v�FTB�^����0��� �p��\���J���!ʠ/nt+��]�-)YX�W��ʜ�b�fc�lN6��=�K>f�x�A��Z�����05W�N�69p�qP3�W�@B�p01�?D�Z̼�&��� �6�Tl/$8��b����˂vn�+҆��H�R]�k��0վ�C��nK�q��^iwV̙�7���Y��du.�R�k]��i��Vr�h�	u�9������
�[�9�b�x�FhN��U�9E���DLMs1�Y���8�Ty˺ָ��̬��z�g$޹+)�q�33ț�#�0=^aAe9b�3�M��A���f�H�.��a�G��5�WtՃtm��z.�����KŬ��{��]Pq�1{N+���T��N��Bb�iN����	a��=�![���9\6f%��" ��3�$.`�j붢ں���nG@�'��B�~�CՙsSD��~B/؋Y"e8��`_����4
"l�bU+�쳢G �M�y������I�Bǯ�,��c$�p�~DWn���F�KX�_�R��+a���� ����}��O���0�4�V���x��7}�^@�ɩFhp�eYQ�C�/Y��~�(T��[Yt�y���3QP��/<�I&�^H���C�1n��"�J4��Z��F����~
�y=�e�zdh�n�y��YĈ��yd>��s��=[��)��H�p�X�!�\�L����L�־�n�}�V=���ҁ��NnKo����@��;p��|Vud�|�	e�	e��=��	T��q��
���h�|�1j[����Ӛ�y��g��P �F��t0�\�1�`٣)��_G>��w��޹�i2��$��hjfy�prF{�o�S��_uJw��S���ن�&63��بߨ������`:f7&�P�l�M߿�+�Ca�st�x�(9�݊�1��Wv9����wy,�[�Kx�Q@E������j�K�&��*��i���!u/8�L��؈X�"���Y
P�ܡo�����C�1/��K���2����|�a������s��A�<����hd���V�����C�<��c����^!���DF���Zn��^�������mNl�'i���,rӊu ���h��[�!c%0���GV,�n�`.�2��/���>�_h���!ԡ7��6�u�����iz���P�DG���6pF�~�	��!���}���pHDx����r�,�����5"�R,��T�~Ao��b�{�4 ��ߟ�S5�q�1������6<��0��a�ƙ�tz�;,��)L�=�&�E��p,�M�1�K'��(V�sc�L>�T�D�Px&���p��d��ٳ0�ٳgbX6�a.I�
�Iy�a�O]�i�	��Bu�����c��@�ҁ�����7��gj�)�`�1g��	��*��+��"��з�N���W'��0dW��"x��ge�q��w����Gh�q�E��F��ʝ���O'бc��yco�%��]�`*/X��;�0�̓�˦ǽ���ys4�Yz�o����t��ѩ�i���(u�y\7a�y&.Τa;Lk�|�F"�+�(��ga�`��a�X=|��������r�����_+�d>-ۧ�HeZ5*��U�����.
��d%�~f4�k���M����������k�	BR-뼙Y�D�f��	j)qbG
���s��֐J����>�F1�x��̄G����d���(��"|��_v�S<�?7��9�(E*���L���7� �t}��lp�e������y6�-6�*4�%�'+����1'�S��x��U�K�l�SXo|��H�?�/���XG��)Y���a����*l^:N��L�"�u1^Q�ѩ,��>��Fi3""c�eO��
wwގ��"�aD��y��]HF��B�*!-����>�8^�a�8�Ɣu9�F��O���_�C4�ZmF���JJ��ǹ�<�:����ӑ�2rl{Hq����#}w
�}r�T��8���s�$�=uk�Lƚ����=�]G�7�]��9���E��e(W�?{&[\|�]nNd��瑡��^����ȚdǸ'iўKo�u߰v��8}���;�����'���T��2I�&�{��V����ׂ��-��S9�K�Eb0�'^�N�f�Z+�3���llW���G�r�\��Rj���YxW���S�,�ՄX3:���)��2��
Jτ�f/Jv�c0��!�t;iF�����3˦��&��0 �%��Րye�m<Yvn��%��3�i:B���f{��Rl�4���`��S�9�"��"�t��LP-��"�5� N��f��	�W��~o�7��3�U�	)
��ļl:��ט{9ذ�x}3���N��B	7E"�b,��mָ G-���K�[�i�����_M��XG�# s����{��ȯ�F��]�((�� s��}�r6JD��k^Z>�D�B�C�����FC �,H�}�o����=\����T�p,P�pa^A�]+Xt�](��+�E(hW	�
e�c4+/���E�|��i�*�~� ��R�S�?�k���Z=Z@`ʶ���l��s� ��'�ճse��7�i�<�΀J�F�-��g��:�+�X4�]؉?�}@�
�+�&X���l�0�؁lN������ʙt�?��L��WdO��;�<�M��/�IJ"ج�pQ�j�;��!)[�+Ɣ�Śz7h
�{;��)0�SsHL���O:��XV2t,�s��w���[(�[Z��Ec�fŗ�i��"�lRT��6eDC~9Q�N ��N�L�.̋.�QӢ�e��u�;���o�w�A�cF8S|��ڼ\hᷙpG�{J|���B�^�>�9�2d�IH��]�XM=s�^y��Z"��11O����mkNt/���
)˟�q}V&��z�yŇ*�Ƅ�)�w!�B� L��3U@q�eR Fc���d^RP����EQ.1s���笒y�9�<}�~D��ugb]8ew���P��L^i��oï��{.VF#
U@�%WB0ިN�)�e�?�=\ƥJ��p�!�F�"�
�|Q���(��U*$�TJ����ԛ��8�TՄ�eti���oS��ЌU�X�):��N�\��}�ò�\�W&Ga�h�
����e���%9*"�P"d�F�"D@sK��G�I�l��h�E��!%�B��Y���0+��0�}by��Sq��%Ś���&��\(|b H,}"����T�dLQ�#��o0cD�U����]Ê+|��9��[G��M�q����/���a��QV	I;�"\�e�!q��<���T,&� oks9�Ⓣ�<r37��zC\����k�i�p���	;���j,eʨ�!>��E2s0}A�^nL�+��F�Y�u>4a��9@J9�����뛠F�����l�ɾ'���݀�+�w5��|I�P��/T&�Fb� ���Q�6�2�ju/��z�4�����!�$��pfDm�=�Mi�޳�%śi��2�ڧ�r�
�O�n�B\`7yf�5�uä��x���C -.����1LbSG+ѷ�:{ڬ�#93�u��fL+�"H5�Y7�NqNi�'�)�*�FVd�z9��!�ܘ�VL-MM�����H���Ɂ�#&�T�Xv�ҘIA������PGz5��[Uvg�AՔ����g�j�m/z<FK��)��efL��R7=2#��2�P�z��AV,��=P�1~���d\q�Hx�ͫN���`܊�>ާj��Lބ�)�h�=�1]�@���%���F�ؘ�ș�C�M�S�I0�Jcb74ђ��▥�E�:F��8?��n��XSTt8O,+Me��1�!�W=a���^\9��Ȳ�<ø�>��clsN��$wQq+���ݳkC0Fkkn%|�(�����K�^�ށ��1tWj��f�Z�ʍ!j@T!����p*��S�sTP�/��W���p7�0��T�A����RV{Y��*E�V�3�?����+�<zU�)}>XU�<�Vy��\Z��T�@ݴ2�lU�T%�p�����!?*�MT�uuv���S.Di��]݂P���E@y��**O��8���q��"�ow�|
��uބ�+��~��7�2�J���iJ��N�u�Qw���d�2v��m�1��9��e��0k��b�d	ak����㙫�X��߭��d���I�)F�qUA	=�!�;.�)(P��)���[A���6@EY���)��J*�Iȇ�u%㕧n����ʁ�+����X����]t@	9�>�)��\���.N<}��K����ނ�����ٕ�������P�̇ Xb ���bʮ���L��O;/8 iʛ2.ǚ���@��j�ϸ����¢����~�&u*ꄐ�������� E2���b� ���%q�Ƃ�e}���YL9�W���ϔ�"֕pF�+E;)��>�J��v��o��\Ίr
�}C��G"D�`'�}d`�9�hG�݉�$��"-�� Ǔ	�L�B���L�/���a����].kc�Oۨb�����Tj�L��Rh���ߙ��eT�5�G�i
L3m�Xe��	�l���!��yn�����
h��@ ���"�(@���`
�Bo(��n`cw!�**�~?����1o��sZ���@/Z���i"ԝf�#����?�	�ߨ��K���2!�7<-�n��ͦV�_hv%%# �T���Jk�h�0S�4	�b9#�S����)$�"V4H�S��[�M����bvqo�TѺ�%���b�����2v^*�;c���y���Z��>
�"3N/�rG�5D ��6�d��Qi_�	1TaJ ��9.<)����@�����_�L�I�4����*����5�;��MTHPWm-�.�`�oW*���9��<�0zli8�iPb����v����Е���uE�ы��	u�+<�:�����]u���(_�B�l��/��@�6��>��M�.�V���a��2���r�L��M��\�Ϯ�M���bQ��������*�`ٛ�WDu~e�e���-��������6�~y^�4��C�ڀ����QG���x�T���	�%Z��d��QOO��1.ď��؝�������[1v�x���4�>-�7�s��c&��ň���!꘳���z#�������<Jڬo�5���E[��&mԛ�~�߰���z���}�Ѳ��]���0L�f�z��5��7km�n��:4ZՆ�����-Z���q��~�a��z�ڬٍ�I[�V�Q��[�F�o���p�i6M�b�`j�~�٪�ږYm�ƠE�-�	�d-��4�v��TKG��L��&4�֬n5�ͭ~� ��>�ݴ�s�VJK�V�6���>�����f}��M�^�om57i�6ڍ��%Su�-:�׶�-kPo�M�yՄ�3����h�jt�a��Ձ@�m���F��蛛Ԁ�BQ�ٮ�ZƠ_��lss�e��+�[���V�]��}c00Ɩ�Ǝl���Y�]� �16�-�50��&�Zf�jmj�n�A��no5��J�bq�����v������ڲ�M�6���V�]bPm�@��<�{`PZ�fۦ��f˴5���o4��c H�om�[:�t����hB��j}`Y�AߪY6��&5���Ym�[�~u�MM�j�v=	J5�-��4j��A���i����i�j�fU��MZ5�v�Y�joK�nٴڀI�l�[[�*�u��4�0	���jnՆ]�S�(�#������#�%�� ��h7������Bz��o�[��٠0��F�1�L �~
�Z�Ԁ����Aj���U���Z�Q���f�]3,�ڂ�P�X�� ��*P4�Yk��A��nTa��fk@��v[��.5���I͆�,l�7�U�Fu˂��m�զ��h��X�8�Vo���nU�p��j��F�P�� �#���:ޕT(�֫�~�]����fmP��а�f� �l��F�a 04�R�<�]n���M�l,�i���1p�*ݲ�f�f !�/jqA籸1�ÆfZF}�Yk�7��e ���j4�`�͆���.�ś��&����L�U�aLl��:�0�:���aE��O�oh�[U�i�Ѧu��h�`1�f��o�@g�ع�V�[�5�'�5�&4�4���-
{��T	z���m�Z�"dIy�[��ED~hcQ����j����2r�����6�e�1��o�[���v�@� �͜����7��}�̑�y�~JV��m��t�������m�c�~zc&��-�	��ڋ��:���}�����}Jj[d�y�VПL��7H��	~�t=��F�t���Z>|�L�o"���j\rĤ-dͣ�:����2���>c�R(ݵ� ,��o��K.7yq�g`w�rJ�����Kw�D��g��3�Maq�ޓb�=`d����A��sD�����9'�`
���lP�;E�O�v����hl���r�j�!@��m��G�ހ��3�+�� ���J�Q?��ߌ�́�:��5b�P��7�A�'ф�O#�DTr]�Y�\�����'�=r�N���,���(-ݳil��y*��$B��o;��4�QjF#��M
�s~O����M���`�:�{G�e��r{��0|��@�	˘tH$��-����4�64}�K3����;�Y ���t�m��Bܫ�<���k�!4����4�:>�}IE.�êN�U(�͇)��(������>��?9���N�Y4J��ԷT�v%S^dY�n�T�HM�7V�nׅG��?�=J��\�Sh�	��<e�w=��k>��5^��2�U\I��Sv�\^:5�&u�?�U	�H8���IJ���y��V���٪��Z9��(�o��?{�O�<90-r�#/��{���
���,�szz"~b���y,�?���+�������u��8:�xz�Ì�����v�������g�RSL^� u�Y��v�[��v�����Hu�0	��T�%�y t�*��[)���i�1��,�l��%������q
Dw��B#�"TCC�Ra��Z���P��p�.���l>n_.�k70?���s��z�Xz�e\�����v����o�*�X\�wdU��X�苙�-���Q<*E��Z��Ejr��ᯕV<C�R����^��U2���MP���GM��Ȍ�BE�	Ԡt�5���� �f��N���}yt�j��3�z�.+��ݽ�pzC������
���3�� . ]y�c-�Î�Oh٩�Y	��$z/:�e�h��}�Vl�rR�����U���H4����@�:i��b�0;S���3C,�,n{.���+N���9h9��X�=� 	]i ����	�j�����We��9B}uR�@ 1H��%�Ef~%�p6P\%Qnf��
����B2�̅��\H��0���+�C����a�F�����R�$�/�|��lu��J�R0����'���=$E�݉���]Ǥ(�K3=�fNQ#&>�"Ŧ�Tb��͞��!^� %-E��3��L��ά�ɟ볻#[��MH��!=� i�ip���g(D���'F��K�.-�aygu�c@��3����dǜ^�agu+��wN�;/	f��0fJ���G��°�	o�0���|�*�=�Pd��{�Ly�,�%��j�qp:�}��=L ҄�7��R��UE���3*�8��� (XA�o#��R@��Y�̝>�jc�OG��1��02'ײY�8�^!���}sCTE������E��֟�є�tI����ůT�<�����N��~�x;��N"Vr`�a������U-�e�0-(���z��j���l�s���I_��������^>�W?��ut�[ǜ�_k��~���1R.����_M3�)V��gH��`�UJ.�{~����ċ�O|F�Snŏ��L�>�;�b����5�$���jn����7juv�[��AG��Z;��~���XŹ=ׂ$���Ný?���a�V(��+/{�ۆx�a�1��)ޞ(�4���!&Ãzp=F/&�{���_��n�p�f����ۮ%R��~n�ͭm�Uom7 mon�#��ui��[�-��y�����T��j����()���,�q+ԟ+�a�Ψ� 3�\N�q��Y�/�����Z��M��+?t�����o����������1Rd��pu,8���[k2��:�B>���b.V��ۯ�z;���I�K���c��_�6��*��o6���?FJ��y�:n���D>���2\-��9��j���o��j�p���F���Q�S��O=���~�ε� �-��#��
q�m9z)����B�����8�#��1���9�����;+���
uQU}�v�#- _��Q����S��)�R��%�Γ��+�ߖ[����Z���)���X��7��v�����Z#��%�sܸ�:���z����O�?�j�����H˒��/������ɔE:�6�q7��缓�_��]�.�.N+���-�]6j�j#v��f�qUYD!n[�KvYd��][�E�-!��vw��Q���#���10�2����Y0��Rr�`x�=r�o�ؽ�
ǅ�#q��
�A~e:F5pĔӣݣrԻ%���!��0ީ����ٞ����"o��k�"��a砻�A�̵�/W\� �a��L x8@ KY~�|��WDi�z�٘1#."!:n��ʭ�:���]\��}(��*���+�kQ�)���˾�uO���w�XŰ��òE��N�����.`
�	6h��7��i����n56_ǲ�q��q��Z�e�F7������b8�o��I����f���ܑu���=���F��5��0�}8��8lH"�y�Ƅ��cV)�!�q�UG�PY\���+��Nb�����(�~�-��N�X��v��������r���6����z�K�[=�9��.�u����c[\e���1�����xT�����3*�
>��ceM`m�����]�={���d����V�nr��4�� Yv��?����h�r��GI������Zy����s��|�W��lxW��^���	s��� �c��PG^�P_j�@���3�π���F�O�~q��#���z��OJ#���Cn�o����9����Mqk�k`�lý;�5a���7�Ս�F}����h�i8�_�t����/eT����d��F�٢�Ɔ�݀}�}�s�9a�R�<����?��lmv����r�����,�����3rgX;�1%�;%�)�Z9�g���5���T�L����0�]b�%�yv3�ra���i�^��2���a����kh��
���,,�i��
�&�i^9��oI5�&��
���a�bCk�FP��y��3:闍�����2��?��$�"��O<��Q�O�E�a�kj�!�e�$J2��7r�!��wj{�'� 6R:��������G���%S*H��bC�|�{��V �,^�-�ϫ����*T22ݩ9�	�)q. ����2<����I�^��a����#��Iخʰ��OB�'=[�f
��'��Cd\b�? xWإ��!^2B ]6�7���qip�Mޗa��iP�:��$�]~W8��߁NxǶ#�S����	����PY��w�l.[T+����]6�P\����p��e+��}�
D�U��V����*8h�k��h���`%�Wa�	y�F��;��0pJX��Ͻ��&�e��:��)�?[�F��QR��!�������?��?���y��<�g�s9�4���P��AP���:���h�/念���l������~���;�+�P������Dl�\��~x�=��|W�u_�9�;��ٛc�����w{���?q��{s���;s�/׊<O�����v9g����6?��j�*��i�����{�3����9��ߵ�y��<�g�3��y����
�9;��츕�G�!���6 ��h�����@���a.�BYΊ}��r�(�sca�s��H�3g�-�8#"h"�csNl�<Jo,J��>�/�b򟉉G/����:���m$�����v���(�q/�|k��<�;��Ad( �vv�i�}����)]�k��@��H��l���|�?F��y��<�g.�M�����������"�������-���n�����<��;�gb�?@$�y�2�g��n���1Rn�������� ^=��Y���_I����&/��d��_o6ۡ��f��v���>J����?�𿐻 ��C� 	=���F���j��G<��tċ�R��,P�=��,���@2a/�&�b������u�p�;G�����Yh׸Sd�M+?���f�zf4����È�Bb�>��]��d#g����T]}�)��O(��E�	�-��{������q;g��e|��:����z��o�ڬ���c���6�츨F[?[Aͮ�(^�B֜1o.J\kB�����ѷ`���_p�x���`[�$|Y���S��`���t�w��$����H�mA�9Y<V�5|���tB>�lԙ���[A�ܤ)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<e��� 0 