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
# License....: GPL-3.0+
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes/updates
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
� �Z ��zIr(�SO���#R�Bp�B�4�HH�7����mN(��`@�V���q_��;�}��(�Inl�U@J��gƂ�-���{Fv��O_�����hsSѿ��յ�W>������x���|�V���G���6����3˦������vЬ�_�����w�������Lo:����+��x��6W��i�ך��?���X_[�'���R��_�{��@�� ��jw�hK��-�t�`O'�E؋3�zUU/fY�DY�v��h��GQ2UT'��8�L�򋝓x�$�ΣIg�I�e�Z{RU���k��0�N;���yU�\����&�0�����QT�ϖ�6�ؚM�D~<�F�0Q��`2��re+*�g�����TP�#x�݋���0�n��<꽸b��S۷� �&��E��iRh��fG��8�"��hF�t'�x���:���A����t#�3Ta�&�t��nڋ�4��hN��À�Fa���,�z��NT�\ē4�E�����:}�S���'w�zC`��t�m5��r�A�4c�8 q�~/�F��«���z}�_�|���^܏��_�(R0*@cS��aͮhR��0=���	���Sl	���Rd�ٸ���`kj�`:�����h��w�ovΎO�v�-}t�m�*@A�s܅�tr^�����J�w0�����v���m8�E�L(x�>>�=<x֬�;������γ���vE��s�8�#^����x�~qx�~Vy��;�xѤ�h6��������Ak��li�=���VW��������������*��h\��/w�����^���z}i�����O�^�[;��g���*���e[���~���F�򥏂������`������9n��<�m���$��Y�����������/_I�r�t�������K����hyE}̳ٝ8�+npǽ#9*$��G;�~v�*�/�w\�/���D�b�=��������sU�Q߃F��9��῏`�_���K ����N��ʈ�:W�S�#���m��e���9�O�^���{�˓h<��ė� p�m?�|/�|�T7y�O�.���0��L�+E�x���xɜ�˂x�vE:�����{Y�q��r�kn�Տ�y�j�S��~~��>	�4��Q���޿�@�Q���k��s4����8^��������:�sYW������GM��.��������#�s����)��w[�ˈ�>����#J��
6Cr�:��c�v�_�	�5���AWV�J@r�I̷�@��5��UYQ�tw�}t��5U���~�}7�}�;����w�[ߝTV�>u^=>��jr��$]������/ث�o��6x��{�%�R��]�*$А��+�5 �tS�.,jK}t)��c2�MTQ�NAq���~4oz�j1����3����v9�}O��n��Kc�^�:3;���gW:��༦�L���IT�Mw�lϟ���o�僼=�6,���<�j66�G�)�O��rt��+Q�{�ȎM��#s����-h�.�j:́�B�6LSm�C���X��*���4�pr>Ck9���\3k�޻��0'�����m�Ѐ�2�����߼����� $�~�NiQ3gdB��^\+�
�����F�9{�:�!}c����ES�=/�x�ڣ7�f�&���l�#�t��Ň����	`�i�S?-}|}�Ѩ�A���o��I
Ҿ��y&���7n|�=� �p8=�"��o��N�;�%	�/�ꦣQ����>\/sT�R��7Aݏ��4����R�mh+Gш7��T�$���0�a$��e��y�S�l�%<bۼ%>a�;8�m�������#��☳?����R��;�'OVr�ʟg�T]�I���A8��6�Ӎl�M�>I/��}���������1G����j���U��LFȵ�^t�Hfáir0J��YO��7���
�/��]x�bv�BG��;k��:.IY7n[g	�_����������xV�I����8~��1m���),,�(4�&W�V�t3V�|u�)�����@��VEU�3wך����Jf�б>I���U��
�����r?��zm�Bo��"���k�ʁ��)�f�l��������)΄@4Lt3�8F߭�W�+KO��z4�zٟ`��'je��E�T�s�M>��z�Xi�:s��MR2mL�wB�n?�������t�Uś��j-� �Xw<����0�!`��\���t����&�S��F���<��c Z���$�͇bVd�1<'@S�5$o��E�����V{k�:�1�X��'�z=X�#
.VrZ��[����\BF2=<Լ�$��c�ޜ����nN�Ɋ:n��n�N1�PU{ŧ�r(ғ]SK\�E�����c8\��-�:��܆G���G����c��l؈}�K����3(�t���GӾ�*�0��
�64%�_ʅ�c���}rJ��(���"�c�e��6y��"
�ϭZ��}�Ю~�} �>�ۑ�\3��Y�c��"	��^\��9�j�h5xlN#͓w -k5�*���8z��'IZ�3O��I:�&�8�p���qd'�s ����T�D��tZi���OTy
�i'ƃ�t:�hzͅJ��/�'["�g����?�����Ā{-V���,5j��.%�[�� �^����V�|4N�1�51Àh�^
��4�0E�~����i��)i����9�����i�� ,�z�Q�!o�q0垄|N���ZHz'�,�������&�z^�+��8k���w��s�ռ�%��l�k�ā��!:��<���Ѽ��i�N� �1Ì����X��ֻ��b�b9�|��h��=�x|��SR�	춗�g�����6H�gͧlf=���PS��j�G�כ�4��.�ᣟ�������yC}�I-/���6O���է��� �g������2��,X��fA��y����$,ie�Î��緍�U�G��Ν���gA�ih�0_��X�YɊ���=O��T���%y�A�o�����g�{�8�� +J�ҵ�+ü)�[�Rg�g��ƚ/�du���Ne+� ��l�[��B�ת�e+]kZ�������=5�-�i}s���?����7�<����sc�ޅ�X��SR�}~Ï��漽�%�{},���F���o�߿��[����m6�?J��d����蘜�e�R���S�����4���S�����A�׿a�uI�7���_�|O���H}�0<�}����Z�>Ѻ8�=��Hln<)��vaz���0*�[���-��7�oV���7�o�����7��퓘dT��|߲�o��-����(���������M�oA��#��MY#�ۤ1��O��� ��-����S ��9���T_-�q�o�)���d<��|8���hiY�y����?U?����W˂��,��T8a{��-a�¤��/Ÿ�M�4��Er/�0�h�nchfʬ�=՝Dh͆~�i"�l�Ϋ8�a�놜�^<+vTҐ�q��{�!~�˺P����}{\���l
#o�p�Z)�"Aû��f�����B���d�s�ݣQNS|G��:m]7����,��Z;kK錭y�iV���%��0���Q[�c�����?-�W~�Q�,5~j6�ة�F��x1�ܔ
�xvxiE�z�E��Zޠd��8~��r{��_����V���ћ$�$v'�*n����5��)���YbN#M�����sh>���U�	�~P_�p"�nNJ:/����qI����KPf��9f���ܨ�~U��n~�+}�*�#���S�d���$�`@Eu�m9u�_�u�~W|3T�wX���,+i6��,�M�����-�:��T��?�Z��@�{���32�����P��:���)ukg���KxÚ?c,���\\>;g~����Z{�E�e�	*1H;˸�j���O�pr��S榽-��5$rй����Vg&�~���J�#	0�S�n�]�+�;(�A1��<�6�5�e�7~�T�4
 ��m�|[�l��@ig���-��ϖ>�Ÿ>3C�f��=y3��9��Ҝ��ݱ��������[��A�{p�`��a6s�6H�)M�n�[��*�l�������PPn[�`�`�l'�����nv�%�t[�� ����`�gL����"�;?�|?�u�$/+�L��K(�@Tnz�q��kߖp�=�A�HT���J�O΢�Q���|P���*��[m���=7\A±&H�
�����ǿ4W|�P�>����K6�e�3�
�$�Q/�~��yۿ@b��ˤ
꧞�e��e4����W�g��[�4�\|���FT� �!�5�M�ymcu�5��KC����_7�����b$����������y����?�>��N����]������[|���N��f������~������\�7�n���Y��?�����zB<)�f/�!�^���/��ѳ�O�#�f�N4�齋��2��Q4`��1��Y�V��b�\����^��o	��	�S�=��?~꫙��8;L�F��݃���~�വ�-��3��o*��[��o)��Ƿ�o)��RhkK)��ʠ��C�-���rhE�+��~�}] �[���׿��׻.��7��:݊�F[��:��T����EN�]�����Yl�-��[���q���n���W+藦�8ע��}���+,	�J�p�^q�#�F�h��/l��s6L�&��e�W	�⃃���w��_�˛�Jp��c �6��-}����
������7Gg'm�<��:������M	z�����E/�!���/�NaθH4Qa&l��7À(H���\��!A���-�W}iڥ�k�7�8\��@�����a5E�#K_Vu�S���(��@��@
'�:\ˎ��+l��,�T��OG�$#T3�k�an1�۬��G,�K��n���fv���s�)o�I?>��x����7�aYT�迺�����2��������><x��ϛ�Sӕ�u <����_�����14��<�&
Sk�]��l�cT�묇~�U*�΁�j5��arJ��8���s�%AX��K�}r�������r�o��+�|v��͹���|�+��-�{s�vk6M1%��$�e��g*�@LOa��$�K��0���)ݻd�r���>nӗV�<����=�ڤ|g� ���?��ԝB?�����׋
RɠW�v��Ew��-�����	��;���g�ǻ��+��8���ƣ�����H�6�76����Ϸ���'��7��y�7��t���=��\�C�[��^���ZD�'1�?/���DtO,e�^p&m~5/L'�M��*2w���OQ��ׇ���g_W�\��bz�:y}vr��x����Ϡb�uY���}J��k��%#�.�f�������
�~�Ɨ=���O��,ΦS� �>ؗ�F�Wl'���_��z�����,]�=��p~�8�=��HF6͂���֛=�Yc�	S�BPH�u�k#��ӈ�h����vN��iz��s
��o/E��7#u��綢��sۼ �2���V�VѴ;��Ǻ��N��G{�����ŋ�����GǇ;o�O�Y�'io֝:P9v��Ҥ?�l�����:�B×��4f�q�E���UXX��S�I� �̥��"������"\_�D���X���z[��p�m՜���[5/����zf�R���Ğ��7 ��oZDn���+����u�DkQ�K����.�K1!Y����C��뭺�OL�����ؙ��١�\�E���~ 
g�2�OqL�@� �B�s}fïT��]�ʵ~g]��Cs�Y~&0��l��>js|{�(�p�g��F�yޙ�1�ܵ�7/�\��h��l�6�/���Lv+[���.�o�5v:.�KoT9>�N�猶C��K;�x���[o[�K��'v�Kx2j�s��ŏ�{���ۧ��?�q�%)� r�Ag�N9���݉y�����z��nv|z���s<��F�;)Q61�΢QwF�h�4/�
��^j�����9��(!^�\6̜��z��7��lߟ����&�t6IT39��PhY�iaFj~,��G$Z�3���^��4����x��J�84�"u�:}�]?�dS��R�{�2�4�z<՗�
i]��0�e�9�����s�����k'���9g[#K@��-��	�H٠�B�
p�� �"�yH$ ,�����"��	���[j7Z��va輮O֐�S&Y?q,7��C��K�'0�Rɮ�tS�<��ZT�kU�2�C����]�[�d�׶��.�T�H6��0���OX�+�iS&Q����A��il�͡�BJ����=;f�^)N��G��o�Թ7фo��fŨG�~��&����K�SLr{/yo���x��A�f}�o�|�=��e����c�I��p�vDi�i�����oL�%�YZ�e�3@�/ͥ�~z��f�J���gMb�6��*��W�*�Tâ��=LQiLEU�6��R���sF!ߖN�ɕC�*Bt9�;M����<��%����ls���4�֡q����V����3��u&~�v
������QJ0��{���z]9�M9�2����P_I�w��>����ۧ�����]���WK�vu�0��+	xF ϱ���=���2nK��k� ˩ۣ�*���)`ݺ�|�&ry�]Sڬ	�*��l ����.���9Fc0�,�~�`L�����l��w|�Y-�.�&!�+��[-�bNc:�\��1N�Op��Ԅ�h���f
*�]��p�`YN�����h*�c���{|&?V��^����(
9�>���V{�;��
�����Å[����O��O?��B�cՎ�Ec�9i�o3Ja��L?ax������U+�"pg�R���Ktui� K�7�H���g^O'aw�����`�Elw8�S�� d��e4�
zˑ15�G�UHU-}�5wy�by��&����?������к���w�\C�s�׷ܓy��A����g���upjzⷕ�g''{��-ʰ.mNΈ��NZ���_8n}¾�Mfz�-�?�"�A8��H)w(����h8I	[�%ڮ٨0�ק�G��̛6=)mj���c�do�y�Ot��E��JL�����_Cp2�p����yB1�N�hv�o��.��q�NՊ�
_�>���{6?��� $�	M�æ�ݳ�}�� ��:@�^k:�7V<p�h������W\I酾>��� ?-����hfԹ��֌�sKxJLF?V{�X�f���/�7q] N6�x'Ӿ��]m3S�՚k�߇���7CS�8#qE���ϩ,-����Y�J5�ǵ��Db�&B�4�
a�B�1}�����Yя*����B��ٛ]yA8�W`jZ�@�M5�>cԡ������K�K��/���S���y�~t�x�A-�DB��~6���O��w<O��ʗ*(w��$�e�p����w9��y_��o����
����]C��Ę����qʁS�*�����W�����OȚ{����Qm���w�r�DF�;��o���s�����T#���|��G���QS�V�����0?>g,���:F���>�O�W�^u^*�˕�s�f��-gR<�G#(���y������v�3��Q��c!�n�%�`���m�4�Oqx�C)]Ѣ�*������I-Q��A ���J�i���Ѩ6�c�1��G`�^V���km��XK��x���Чt������wٛXP^�'_����Qa����.��u��C���gW�l�[�~~vOs4���=2�yWY�&�5S�sG������8���^ZB����'�m���مm�?�Ӗ����>~���|��e�R&	�n�9>��[y�c�I�k��KݫN���u��y#�c-8X���G��ĝU���3mO��������ɲ�ģ"#���'����t��e6��i�!��J#�b���O�G��2t��P�����%-wn7��L�a���	&�d߻�?>o�E������l,m��I4�ӈ�C����a/JΧv5W��?��Fx�@6�DU,�""K�cHo���P�.���G[AՆY��K��5��0[�����h���M�V�ːN'��s}g��`%:0��$�����l��Ҫ�_a�VkO��|�²vL�*��&��{bq��2,9���G Č�փ���G�U�t�����g>!v@�}��E�g~݈� ��d�Tj��n�E���x�[���ςV	�؂m���S�,X<oNN��d���=��גFxm_���}��{�d�:�gN��7�����<�܋8ͽ�w��=���<ϵ���i����YT����},��~^���/��M�����H<��y�?�c_�/�*��٢�)�e�L%��}�Ip����_]h���^ �_��5��9<���\D�-��`~���ҧ\����P����܅�¥E),�!'2~Zr�!'�5l�5.{fv��jj��KV���+:2e�}`p:ą�u��0V �8��*<��o��V^F �x����Z��j�f$s�ѷA���9������Yȇ���r�_����i�S*�uf	���p�"w��� R/_��eċY/#�\mB�I?����2�R�1�"�F��:�Ș`�~�K�BQ[ҠTN�j��LuwjOy�0
I�Ζ�V�-߯���ZY�?��he5=�J�E��X��0�~]f(+ fe���Z�~	����V��G�"�rX��@ɖ�x�$f���&����b�_{�>�r\e!x��j���}1�g�E��	�{4�B�_#��5v_�� ��S���V����8�	p�s��ه�4���`@�k���Z�
�@�bB��UN`D��5' �ڸ/���y^U��I���&ţ���|5'~�������{鎆���Fir��ْ?�{d%�%�;�2P�U*�s�a�X6�{K�̱l�?����JR0٧�AU��0��h���]�%�xa��v��Ɂq��[�L�XzM-O�ެ��<���3z��=e��4����p]�*K}�T�碣C����_j�QZnKkt����l�� +x7�,��י�G�R��;���aX\�I
H^�u1�,��8d�����DnC����E��;X��L��I�Ԝ&��e:�'=Y�Ŕ�ǁ�CȦq�=]>&!>M�݁�Y��YJz�gN�E����6vRn	�+�I��!V���N���G�V��" 4]|�����b �&' ��W�]R�%�΢��{���fgr,Y}�sg5�!K�KO��w���.x~vrz|��No:�s�W8�������	m�9�7�P��z�K빗t����r��������7�z�	�9�@���-M�*���>5r�'��	��B���0���B�����O�쩔���A.l��Ї~��|���r�r鼨������[���0��@�ҲV+K~PynZe%7ؼ��� ���y��OI�tj�,^�F)���
8�}��T �Ce5ʊ~Dc`��=V%5�6�t
a_�� ]n�`&'�o9��[^����^��y6��R��+GU놨�s�ֳYLs���03�`H!{�
�G��DN��v*�ϻ:���*;�U�P��
��*�*O�x�۔9��|��c����.���J��N�C�����%�}���ۭSs�4f9֤��у��˟uQ�"E2�0Ǐ�g���+�M�y��e�n�R�'�y�b���z�^�U0n��bI�z�.�w��(f��S_��$�y�^��:)�Ͽ�)h�z^d})t{����ga�6G��gc��]�����n	�/��;�>�+�'��\�)%�57��'[����򻮧�i�۝��[<���c�+��[׎֒�?��ڤ5�a���-A��P�@ZX��mG�qǒ/F�%����iP�榘(:5��d6����b U	��M����6ԃB���-�wJ�휪@��d�s��9�IB���[�����j�I����y��i��x��w�~2�BY$���n��]������%�ú���|��b����xns��v߻H{~�a�Q���%��X���ϫ�����J�qI���{,x̦��u��D�����׾cj��_|_���Q������?�ͯ=0�����ow�}p��j}�%osֿ����\ϭ����Ʒ��~��*��:x�^��ǭ=u����)$��䠭W����Y�5X�  ?���烩Z�^����$��Iڟ^b�x�'M�k����R�������<P�hr��q��n��):�,_���ó�q��ж�PCcIl΃�7�|���!�*h�)s���\�p8L/�^=�7]�M�pj�:���F��Cu4�@o��1��vEU�0�"��� ����P)x�>Nz�z����;��2�*��-�;�X}�_�:۽(�ϱ�=^&��5�����$������3	I��(��
]rx�޴Lo�q�L����t>'!|��=�1i@Ri�!�=9���Zm�ڃ&�.S�[���!]�@��6� �L��ތ���dP�b����SK8cT���7��j �0�("�(Q߹��t���t�)8	C(�-�SHS��w��0�$|��A��T�'���ƣ,]���8�{l��x�9Uu��g�S��PO990��2M�	9;�7`a|jY�/RF�#T� �����J�t�i@f����M{]�ұxڴ�bpb���y�8dl���q�al]I�-�8-�9KX�����G9�D3X���g��N1+�֍�^F��D���$���e�qu��~�k��`��"�3���O�;�3��M�Vu���).<6�E	��dR���N<��1_���JW��R���H�@����$�U���g8i�p��	3/���h<��F�ͺ��uN:�s���ݪ�dGx��A4��, � &ӌg�7�ɸ�a�d����%�骺u��c�P%�i��Ae �l!�[��h�W�k2!<��H4 aJ�h���ȋ�ᦗ)�:ζ����+N'S�5,{9��"e/�� ΁E0}!c�������90���x�Uw\����Yu�Ҭgu���������i���''����<2�@��$b��s���H�F�q�:w��c�O�����v��x	�Gri�@��b�3�]_�U�a�ğAe|/�\N7=�/%Q:ˆW$x$H��b���Gx;����n	Fn��R!�c����,	���mn|!�m�&�x�������d��6�$N���eP��Qf�����  L#�͉�&E ����@I���(����Tv�L�� �MbYC�D���&W��@cdҽ����$ܛ�8F��[�L�.e�Cd��銯�E�>K��)��|�z�����ч/�HR����HqV�6	�����P�t�ff�(��-@٬�^,�MX]B���=:GA5��n� �\3K,1%��u% ՟����ثX�e��V�nr���*��q�㫪tͶ����O�3�T���������mDp�3��o�@$��T�����V��sҨ��ƜL��\'��D4i&���xF����Es�����!�N���z�!�����B���:���v1uH��+S�.�k�^��in��`
S�k�	F�]c/��X
B�"wH���@��ڧ۫ƨw8|\N	�07/�j̷�N���'�u���|vvOwN��jϻ�	�H�WNSa���W�u���j��X�V�9��Ȼ�0~��\
_g�:�m��,��� �h#�f��N��7���#D��F��Ih���F�U��@�^�v�I�{=X���W@�V�UE^��
-I�*5�R���`�`+��T�7
i�E2 �I��XΜ 
U/Ӷ�/��/��xG��l��UP`"K�څU��a:���X�� T�.k%��'�:�hpqƇ* 2pG�UdL����H��*��_���V����tS�m�YEP�2`�]��S�O�ѣ�g�d���9e.���#2!+��#I�pZ�י.�.�aCK@�0�,B�� _��@�)N��t8J��S�Z�5�� l��6}��<p��I*��ᯨ��| ���H扄 �8ah�H��e�,�ӷ��L<!s��(���v;+�@xt)]�8!�����e.��Ь��"ʓ;�S��%�)o��{� �_�ZԨ�e+��O:C�
�Q$���u� 4��S����׬��K��L�c68~��h6��\D�= -�E�i��,_p��H_?HQ��*��D�0屹+�r�I�%* �KI\���>�rc�}azfw��ے[B�;#��"�9&XZ��']��p'!/Ģ"��j�vh��d��k�+<R2�@aJ#/�qZ��8�\���l$��\/F��5!IX�1�e+k� v���.c� ��nE{4�ȈE�8�_' ��YWo�F�S���c�V�Tv������xP������m�nV�0�(�;�D����[�{�ըh�1�TU�IO�j���D�~d��o`�ƨ�����%W�J�tF�d^z%�dK{W轨jT�+����̹s��D۾;���6B4A�����Ixxz�ІW����o`�v;N�8��®�	�7@P�I�L���Q��U#d��!�50��Z!)��u��p����vO#!��� �|��><g&��H�v�&�-n�%�JV%��y�4�=�YQT�1�k1c�X�D@e�_��@j�&b_	���i+2)+��e�u!"�cTr�����K��S}F2�́MQW#Ì8<�,�+5"�Ozx��֘Q�)H<c�3�u�KHB�X�z%2O��O`�gU�K��xM�Y f�u�s;�Ev��n&0��!L�!
����2���I��$�$�A�1���TSU{,�x�<N;Wb�+40��vF>�T���T��	��+�d8�H�b�Y���uz�VkšI��{N�����JH���4e%\~�`	��ک�iw"֜�tV�&���we`_��%���󴖭c`D��H;�KF��vQ��x��j���K!����H޷)h�(�U��Z� /9E�=�Ԙ�a�Л��z��mW�8�h
l��ANis�f�6b��eR�o�*޽��wN-�b#�z���]�.�_�r'9�&��X�^-�X�o����[<����g��g��l��'�3����؅�l>�(^�D�"��?k%}(m
��#��'0j�0������1]�w�8��58�j����)��րNr�ϒa<����ּ�h��q
F��*�8!a�6$��s壃���aHUuJ<rڌ��<r����Ttq<??�Iz	��y�3t���y�1-�4��p\�C�ϙEi�ʷ	i�)�j�\��ب���DP���X"+�ƞu�L^�h���1o��srK����b�z4���:OM�Lh��T>���Ax���6�p�.�p��SA�����8��<8��q�ٯ�X�,�#�Ru�d2��B�w@�7"WfC��.ȷ&1�g"!Á�ĺ��m�s��;�ܢ2UM�K��l	Z�N4����oz�>�] >DJ�62͍]���{�[F��#��ǳ�4���8P�I`L����z�1� x�hu��M�&�ލ'��Hx�2E�FPc�7F��Qb00s�r*uB�"�)�^>�S���8i���7C�a�5�A'D�.p��|D�=�p܃��cް/=-�V�m2���lǃ�[<�@"�Ӡ����G�I��a1��$��(L��)�iq�8�`۫�l�|Ht>��!��%���"���ѡ�8����=0k9�vmU� Fx����C�SA�M*r�jѤ*.}�$zh�X��Cf3x�W�y%ǂ/CDNVb��hdQ �wb�!�n<�)ݟ�]&�ax��Ȉg�
j��K.�D�&R��-ʢP��!F�p&�D3�E�L����z��"��urx%�]Ɉ��ʷ��nR���1�	S����L���faтrl��mԝ}�V�gm�C͕@���.=1���3O�a�h7������%����t�����,Ň��5��Rv��z�3[��z��AX1�r�
�.���J_��E�'&f��=�R)VŅ=�A&�ނ��X�݈yǕ�=�a�����I�(��A�T{���p���݃�P����F�7
#�VwQP��F@8����Ɣ4��Q;
m��	�!l�Ķ�u;ьߺ��չ����*�F�1fl�X4E�%�h��K��ED�Q��n�Q���"	�Ђf� ��]�B�+{�P�waW����(M���2 ��$����v�)VX J����ꋢ���I�+3'xg�����\�GZU��|G2vz�?�A���*s6NE&�]�9BZ�%�ob,a��D��}=)��/ڡ��f8�4ˢLg�6F�@&S���,���ǜ�7܂i�Ǩ�LDW�܃F�1�$���Ѫ,�y8�1�umNb�b<�)��3\���E��6��Km�:����쭇��3ӆ+�q�*�e���Ex�:�s���\J�Vt�I�oc�jL�9��	����Sč��<��I&d<Ӓ��׍H�Ϲ���&4� ÇtqN�a?<;����PL?�y�9���"�s��b��n(2}QkO8LD���w�):��}0�y�u�T�uX�ad���W�`DcC��p�eC�4���ZpB�IP	�ϑ�1n�Z�䧙��"_Fh*�f$d9+�)Ni�}IO:�DI��鸾�l�`�)!��l�(J��3�>�n�i�ΖD>�j6�iu�h�+S@Yq�g�,�%%c#�Vf����s����کa"�R�X���J���DV��qD��/�L'� ��6��Q@op��,i^d����%4�R%}o4�X���K��������7���LCg�,�� g͒�֦V8!ϊ��u�!3�	��	k�UE\��=�à:�~����(����i��?ier��j�)֌G�d�;5�T@����0���R\D�h.�$�I	��F�^�e	�.�� ��Qs���rz���oOU!%�]��(�l �����DN8 ��D[ʍi�>c�_F-&�d��*��"�G�;��$�HR1A�'��pWߺt�N2:�+ңdH^�תt��1��k�ƙv*��8�vÌ436G1��t,p�%ڨE������5��ؑ<n��
�ÎՋ�l��Xc��y���!?=Q��J���}^�V-��K�����#t��Ĥ.�C�(����&�dj`Ae�$1�#����젩n���H��� }V�h�:��x�q�o�qȕ����3������zs���1av�����x���9�H1[]��o�Ø7�aj
g�YHP9���C�s�[�����A��Lr�f|�c��U�8Z��d%x�Ic�V��%�aD��[gH�m�<k2�]��53���hR��5��ӿLʟ�0����	�8QR	�$���P����;s�>	Y&�V�	�k�}#���&zbJ��@���q>:D;���#�N��Kʷn/�\�l܎	d��hJ�:iH�G;eh���Hh��f#62��6tL�S0ų�4kX2��2�`o�	3�i��U�di8�[�cD�~�S�ʬԑc�&�<�������}�	���0��H0�Tʾ�I�F{�%�ϛl5襳δ?�ԙ�:�Ҥ��s?�H)m�4��\��q3���+�(W�I�B���*����`z5&]1�,:��O�a��a�eΑ�j�-���3s�!׹�I�	�x�M��5�,�%/Q���$و��	���1β��a��Q#Kў�^,9�� ��P��f�M3����t�Ý%�t|�I�"E H�@#�&��"I`��s�L�]��ay�8��Ӄ�-�d�`Zi/�"mt��rL2�����ˌ/��5��9G�ȉ��BQɱ��wC��yD����Lh6_����W(�f���Ō�q2Cf ��E�e��Ĵ�%�@jʩ�rT�� ��x^��C��NDf�B��`��(�$�ݾDK
��u�j�/v�a=7+�/�i�t�ks�m�On�mf��,Cݕ�%c��zG����Ĵɬvd�Q�$�jMg����[Д��\���G��+1����T��}��F*�;�k�l�y{���$��z����|:X�&��k�� v�@����qP��+wo�hR]���a��L���L�� ˎ������߱��M���9z���I��#����4�˹��=k����ę�������RP@����&�((��&u��[�r%� 2�h�7�:��C^q2I+b�6t��Gwc���!ģ�ͤ��L����al����$�2��h,��殳ֆ�!��=K7�L���O�uY���`�
H|D�r��'��9�]�wm9��gMU2@H3��Y�a
���R���"l=�c�e�9��C��<�<6����qɗ.�7��3�Y���|�����L"-�lȭ��{%%�&�6�11� 5���!7{��f>L�&���,/Ü���
g�0��$]X:��=�:K�͡5q[9�9��H���'���y���pU	t��sTI��BPH��9@z��3���Ϊ���F(u�(J@W�p�����rD	�9|0��h(,�<�Jy�kf�v%^�^�0�=4�f��z��L���6��%�3|���;�YL~L�ϻ��.�@��Ҽۛ�mMq�$�N}�y�y�|܁���$8�c����4�H�Dq��Ȏ	-ʈ��nѰW2
?M�~���IH"kR�_`|c^tL&�J��I�tf��'9d��I̴�0?���c� ı9nJf��/{��q?s�ͤ�ph��e*2P������[,D[	�D\uL�Q��9�<B6��}w���yJ1��'�a%�����fe�����8���-Z!�:C�tl/s����	M�%;��
,�,6��I5$���ڇ�������S�w%���l;�V0�p���`[.�n�N�����0�Hh[�(��9��	~2�oߥ4x�/����)`��L<��W~�r�̛�Z֧ls�(�7+��3��E��0�M�q���2�׸N��v"99e��9l
RJ��.�/�0�������&$��=�򵊸��
J��]v"�t��d�Z��~`�r�����=�T{�zBaeiI��V�r�B6�����X�-r� �Sg���љ��r �f�� h��e>���D���#���%J�NP�=O����#��F٨�n��l�Bv���Q�pY�-z�m@��,j&	�$������2(��B�p��!�u2��0��%�

�OQ6:~�����4���Z���u	�#�Nֹ�&"<ѯ��c<��$��5d��G �A�}\'%N���}�y4sb�ւʭ��1�0�@�6�TL��Z��N��M������T���U\�T�|9���T&yU��� gǻ��J(�`����Â��~<��d��k')��w�D�J��]�"NE��f$�]Wu^T�#"��+�QB9�,�ar���2,�#�SUI/�s��D�`�=�Tr��ͭ�� ��M�7P_b��֢�j�"W�!�2�0��WU����TV��c��6%�{��n���A�3��4�8ʜ�7ϥ�+��Џ'���"[��7�5 z.��󴬟�X;.��:��$�h�����$��36�3��{�?௅=�;r�[��JĘ�d�����M�]fP��7L4Q�Mq7׵\1�	y�L�=I���K�P@�9����'�KSS!/��
�ꬄ�HY/{��ٓ:y��r�
 ?���O��K��I78µ�|b�D����äS~^F�=��J��7CN�6�R�)���'�Y��q�%Yr��� x�Kƃś����n��`�9���EK��Cn2rjޑ~�q����1�HNb���w���+Z�i��E�+ɡ3���ᣇ���Ӫ$�^!�⠰�ܐ�����ҒO��2��^Ec�b 4��B/Qq*�y朵�*�t�|*sܢ}i���ĭm�=β*\���f� ��C���:��"{��e�|�!�btH��X+Q���d�?��݈��9q?|T�^�%�X������R��u&�nCj�xa���9S�[��ۼ�Hb�c�Y[�*�N��9H4�"��;Wd����3M09�4��ܢ����k�`��}��أS�송 'X��{l `]=��Yu��4����KN)��U�ԹS0�:gL����)��+L,G�����}L�*��bo#�)1�2y�c�&��;��"�ν�S���bn�v�bu�Iz%R�:)t|zˎ%?�y����c�	��f��x��X��1H^�H����#�3t�`��\񁣨Kc˰{6
Re�l��f�6��ʱ�C�<��&�z�E���$�J�ͺ:�e-uɹ���餢or*#�)�ѥ3%f|NH;��j1G�'cc��~�e�6�=�Sd���Q��{�����q�.Q*���y���zN5'�� �ڤ�!�7����� eU_?�jI���(,�8)ܠ�%��#�A1e��'r�i	��R�+#
��L�T��OT ,�(�_v���o�с�x�	�b.UY�tX��lb�v�J�Q�;�O�c���.�&&��sP�!'=�|�ӎ�Q�B�k��X�p2�aU-�uj\3�3����D�"�����k)���i���e_�*���{���#vd�ӟ���L���jqEާ�?Ifɕv��4����)���|&�b�TٔJE�Ⱥ���);�h�]X��w���(	� ']�0�?�pkO�pY�
�s�r�W��X�02��:�ϙma^�4����,�)��b5�
���ʧ��&��
�.�S 0�ҩL0�M�sѽ�$)��:���$w��i�2���N[C05Ut�:����؜����Ց�s�����s6<"��6
%��:Q��VsaJ�;^S�ly��Pu9Rp�TL#0��u��`�M�"�G���_�ĢόDRLq��]Q0h@���TAqR���{�u�	�_���ッeg+�M�>�`uS=b<�	b�S��дE�̙;�&��0����&aȮ�b0�����j3L3��2�(\�~R�1Yh�mN5 �@&�3Hg�ւb	W�3_��a"����21^�
�͔�پflZ`&��s���\K�`M'%TBo���,��fR�粧W�.X�#G8E�MiQX[y�@W�?2�I������jYH��8���9�C�^5_���ºuf�z�z�XC'��d���䧣ηB�ѕ�*���j�`L�<M�I��X` ��j��Dj�;��L_���)'$��Ո�RP���R�F�W�H�'�[���s���fݬ�K�Vm��I����;��Jǒ\��3|�NZ�
�I<���$ZI�Y����J���{�K�����q�GN�Lze]�-j�`�C��4O��l��@
�-"A�k:�Z����>N.Cc=W��}��'�Zxg��/ĺ����3'5���dfb|bN;�:d c$f�jlZw ���i��⒘�ͨȘ��fN������V͵:�:1��z"��>���KGZ���cEOꔩemR9�U��p��?���(�b�ć^�5i�����ە�o�Dq�����w�V��k4��E|�Jy}�,�G��4���p�^�2���%R�I1�T���k"^
~y��#�;̨�I�U�y"��x6&�O���U��E�%T�G*�9�i4g��[�`F��r��rJE��c_�A]�#��E��	N���71gg�5��[ͨ�^ǌn�e�-� �E�S|V"�Q(�%R���DF!>���w�䧖^��p�J����غ�֫[|!w����)OA�P����U��Ds���d�W�s����-fWL�m��ф���b���2&'8��H�8��bz٨��V��6r�^ʹGM��"��V)@6hr�F݄1=�y7�>�p����c�3�u�>��4�'�9�+Y���E������(�:|�	ua.5b���ę4yn�2*)HM3�:��n�̰����
Lr��jmФ�������*���C��i�u��v��08��|w��gΕ;bp�*=������ȏ@S�u�ztX�)&����ڮ�Q���'!�>��:J����Ɍ/(�C�Z��#,, Ṗ+�a~A3�x_Y\D�}fHAH���G��3q��i_~Pբ�M�p|�Z�1J�~C���٣�ꖙb�\|&n�d:�ٹ�����%����(��%<�,	�iI�i�ō9AӒ\&l�^<�df�Y7��LJ�$9�Y���q[힨�C��u|�:8�A�<<�������~U�������N�Q�x�����^�����v�[/��j��oN����ѩz��}���ݓ�:9m���������+�}x����ק��ý��1�PՀ��Eu�:>�m��8����1�J��]Q�vO_�95�_��_vv���K���~t�>9� ��}q~�=��{�c�� ���T���̠��a5�ޤ������������bwo���j��==�.w-�����qp�����]W�B ?�=���b��M� ��}�l�r��2�t��oPD���v<� ��j����}���]Ŗ��ɛ��������=u�ކ�P'�㷻ۄ���Qk���}x|�P���9��<�t�2s����[��7{��������"�(�J~��q���D�n��gC1aT����@b�j�pg�%.�������'����%�֋CD��.�F�X�u�i�^�O��>�d��N��ۻ����Ǩ:8������Z�����1x	�@����.۾�D��O����iKш��ml}�> D�kmo�9���-���؁��8_���;��dD�/[�{o��=
$����d���ݗ���kY6�m��kX�mh��y�K�Q��A�
N`vA������w����O
�T\���9��!��{S�3m�~��S,v��W����7��q)NP%�.�:�.l���*��K�ٱSw��IP<���H��iu�t���p2������{�����l"�w6�,�a�;s��~���b�����%�KZ�97��k�שE(�t�S�Z���PVe �A�{}�����t�rZ"$2�s:瘁�N%�2�rgK�ɦ\���Q7i����u6�Ct�&�F�>	�"^}���/i�X_�F9bUL��h�W}t�h�:'p���Y�ǩ���#�4*>mAIDN�=�גy7b��7өj�%&HB�%�[W#�bt�
��Q㔌:�/��9����JW٢n*��=����5ޜ����8���L⨏��'y��T%�Z�������=�D���=�~O�V���-���o�[�x��A	9���B-9�<�B����ڌ)�l?Z����-�z9�<��U/�C:d��f��Ui���J��=5�j�����Oˬ��U^���S��U�N"��";\�0�L�U�0�ҵ�l�3����rN-2�K6��1�!R����V�qyyY?Of�tr�����0������	a�I�o�z�jޣ�o�&X5
�
	ǘ�ss�صC%�z�:[�����VB��d��k\iRt�N�n#;u�b�9�������;�@�\��p�zqr��洽��k�<�5��T�+ пҍ���\~?[�A�<b?���7A��lEO�S���}w �|�,���n�p�2������B��z���_v��S��>)"&�my��:�`%m�>���ͮ�~,�8Ѐf�kPP��.:释ɛ�!S�)�ZR����
3�_moA�7�E���B�_�FQ/����4�X�b����;VX1w~�41u����ε��������ƛ�a�7nR�.�4��Ùnn�0`��p就��Z��9g%�b��$�8f$�z]�a;.�K�:q�2�=Sf��|���(����!����Y��.u.¥����:o��i`�y�=���^I�K�Љ���X�BS��A�t:\5.W5@smx>���V��?���8n�v���Q�+�����pcC῏nҿ�k�>k��Us}ms��Q������R�_i<�g�"�����vЬ�_�;OF��N>�����-
N���`�D��[��ݩ�������?�qK���\�t�%)U�0?zC9j%1�	�AFz{�w�uBĴl@�QntA� n�ڂ1xPm��"��:eX�~��a'��;�h��p&ax�x:ӡS��t�X`�#2�q�`��#Ls���'Y&�����G��4C��b����`��ФdP%tk
���qG���3�-'�Uu�ڮR�W3,+CՋ�;g�Y�o�mqbJ�zG�(1�V7r&r�&��j.�7��$���tփAճ�������;���3)D%N�a5K�vC�X�NҎ�� .0��KWh����H_̩�/��B/h�J���B>�����T���Sn_��b �s���<��(��ҐWe/Nf�������0*�N�}�pT�"NF9�q'�S�bl��FOcP}��q2�D���w<����e�p2�U�w��l�[.����)�3d`��tY2�:����8��pY�X�G���*�������c@�����_���R�߿���n��߳n/�~V��j��W�6���� X[m>�5����Ysck����c�����-�E�%�.K�V�֛Rxc�݃��j�1��O����qZ��.|�M��I�cmp�3����?�m��>{�:i?�Y-����ؼ�{ 3>�6��X��^�;�_��7;�}�/o���nEmPꡣ�Y-��5B��<Z�	��|pr�4���74�n��é�y�v4���}q�t��9U���I����>��	ׁ�Ƌ }�o�K�W.7���Ld��C��-�_W�7u��.0P��ʻ��\|�I8�	��/�����& et����p��*��3���R��q��&D����0��ԙ�d�4z#��G:�A?�Tn�d_��c'쾟���>���;��S�{,��ݳYҭ���]^Ɲn���r�k��^o��������sн����jLGれ��($��+�))zN�Vлx� �0���<��/.���{�΃��䌰6� �Yܰ�o���~����Z����x��|B�&\�h���@�{W��h�WK�;P��L����-�j��?��G��K5��"9Ȍ�z�qmu��|x�\����Z��4}�Y_��j��Nz��e��;x��n��pgQ���7�N��Q���樔�m.��j�y���bZB��O�w�j�f��wۧ�gۇ�7tߠ n��F`�rӻF�߽�=OL8}�#+O�Q��������<�6tt|��f�t.�u��[�B��h)T�?�l������z}�6�_�s���?�޶r�e�٤�؄�_z����ճ�õ��N��w�N�^��A����Ѕ E�!s@�նv��׶)�nZ0�|����>e�X���nw��u�V,{��>��wS�{��G�/ގ�8���4FP�8_X�Vn�"P�4��)E���a���^D��'o믟�~��~�z�wz�B�=�`���<RD��|@on�P��QpK�'����O�
�'��Ӎ �\� �Xk��cB	�}����uA��y9����Z:�1���3��`w��F���<�����4"����s��Qm<�Cl����I��*~�.Qr�����~}|5L�8�!��r����lT�ڵ��5��d��/@ �V�x���ֻ�,!ی�3�%Q�)�8b%�/Qa�[������5 �t�@�+IE[�n�\ob߱B���l�sA�R����As��Ox�QLP��o�|�����!:U��|������xYBpOm��{�ʍ����9F�T�����u��JE�����JQ�Z��rݨ�n+��e-��h(I2Qw��J����D��1�Ac*}��?�I�-�+�范�=�ԕ3���Gͤ����vk�~9;ha'7�`�}x��χ�X�����'Bf�x��Q�7��m!\)��Uo�v�)4S��,B�tN�Tj���T�Φ�X�~�V���4���@C�����>��?c[Y>����f�Ĉ����=0�UaLs���A��$Pv,�)�k/�2�[������g��$��gir^�a���:�ν{xC��2B\�&�A<�(�/��_�i������;�3pT�ǘ���2�4n*@���z�0�<w�E,7�g�J���]<ܑ�pSf\��
�r�U=gmj��7�͒r�8��&3�c�Tqa�9:�G�μ:����kGi�N!���3!�7s]����\��):g˱�ZU{p���]�/N�a����7�=C=�%)4�{fO��.����ԃ�W�r�_�NĬ��hX+~ԯ�'�вo�NA4!|1h�t"b��c�n�0'�z��ؾB�0`��5��̮�ӄ����\�F*�I��ޚJ��	�A�Q�Goཝ�=�JH��>9�S���$�i'd�Ȁx��JY�U)�[a��'ʜ=��a^�����	g�fr��u��������7�R�\,���{u����q�i@�%�D����U^~�b�`bF����`�c�[\�=t����џ�Gq9������]M��wL_�lΠ���������c/1t4��p��+�r76��zG4xN�x�� -��H��&Ab)�
s��.]���3s������X�� �`[�8N��K��+���H�e��~Y_���p���dEii�=�����hj\W�x����G|�7�c��u_�)+�H/��:��;+�Kz"��>x��ja�c�-�!��(�.��(ks���R��4��F��v��U���3�~͇�Jg]A�B&��	bs�e1)�4B��t�ϱ��VO�bhH��Ar�����BE�0Ӭ.����٩�$H��ت�Zr�]Y�N**:%��`��>Cz�So0f�XwZ���c�S���SOh Z�����Km0K�<Q��Ǭ�5'�����Y�/Q�;-��hu�o4܆yZx�D20�T�D��.����9rwz��Ο��+Ԃ��v��u��&z�8�Ι�+���
[�G�+b�Jh"t:� ��Ҽ�R�:��"}� �;w�?����;�6~W�?��A]����+}ST��>�S!ݲw�hW�\��8���}Iď�h��i_���9���m� t�CX ���Iy*�B0�}��}a�mF����l�k�uBi��t�eQ㍍�;�ߙ��*���$�nܡ�ƮD)�)+�l�D�LO���nXW����"Q+�b|M=٧4������A	��6�<�NF0��V���[|�NH������S5�"	��L~		4�qj����y�95h�ec���	鱗�6��ǐ~��������K�8w>��s��*��ޮg2Z�Z�h�����-�	���yT��JV�mPn��F��4��ALn4���Oؼp��{r�؋ٸ�]��{0���/��^0��w;g/w��t�#})�1U��,Х�Zϸn�+>��է�Y�6ҏ�����B�ܿ����I�獆f qz�b@֧v3����M��{�n����_�"`��e���n:�R�D�U�Mw�)�������g�k�G#�8�Q�m�u�oΖT��{�5§���>�¸~�_ɉ]S/��B*���n�����WU�FQ����`'�x'�.�q�v7���{����)9��"5rb����B��t+�Q�a�~��BeP\�I���H0xF'����L}�9�s�X�7�|T���K����v9�2Qg�-|�P)�Z_W��9�K@�-uc��@����sH@�o��)g���40�v;�.:�~�`��m̎�Aϣ>�C�v{�C��s��� ���p,�|��8/�]#�E�΅����(}�a�s9��Do��s�W�s��[X�J��ë�A8��Y�('_
����e����4����V��k�:}�\�O�]��W�)��$�̆�C`6�U�n$����J�=���tP�g㱜M6��/rT��0JΧ{w�t(7�"��K�ꨥE\������d��4E=��YЌ��{�(j����_��@��*�սݬ7[�x�K�u����w>6�Qe��"�"m
���g��-�)����+����Ы���������wȵ�K'g�NeΎ�&�H��Ј�Jт�BI%�/������溵Љ��"m}��Q<SHw��@j����~�LȞiډ��V����mh�d����Şm�ELa�E�^�����Il[X���B�K�!�h4�#�4ˣ9O>�j	CS,Ery_�v��R��<��u?7�L���| �d�Jr� 0�����q�9���Y�B�D 8i���ͧ ��a�d�4������7�,���f�E�b����ZW-NB;"T"��9�j'�3�٪P�Y�'�$��d(e�uf�G 4'����2|J�rM`}�����[�5.��W��s��x�&����e,��m5H��sj;j� E�l�
4�譬��ԏm��Ϗ-@& ��A�7]�׳Y+a�Ez�	�7�B�.��$�=v.?���Zc�ݝ�u���Z}�n�I;���We3%��^m�� ����v��'� �"N�w��I�uQ��V�����n4פ������&��Y�V�����=���\`H`U�bϭ��o�?��V�m�/�4�^�e*+���8��|� ����+��|h���� �}ܰ�77�a��ף͵o����<�l>�o�?�E��;�עnw�as5|�{�h��հ��(W՟������f3������^u���a�Io�I�	@������j�I�mϚ57>�G;��?~=ڈ��֣���z��$z�|���p���=���v��fuc}�����I��Zo3z�ք�on<�t���GQ�y[�G<�\[vov�'뛝n��\]�v�O��������n��du�,=`�ovV�:��Zwu�q�Q�q3\���k��'��ΓG! ���}�����y���1�lum��[[_�lv�6���v��$b�s�dܓǫ�n<Z�@��~�	��=z�z���Gk]��j?|9 ����p���'�������67��Q�(\��57��<�|�w^˟�{�_o�`7����VaO }O�<و֛O�67!��Γun6�:��ѓ�ͨ�$\�|�}���k�z��Z��aq|X�G�>eEG���]]�w����Z�����5�����ƣ��:��Eas���>Z/�rO�E��$6������o�nGܿ�s�%3NzL��n�z��(���ı�Yvҗ��P$$3�HIٱ��O������* $A��|��8M�L��[�*T6MՂV�Z�`��03Z��R ON�Y�m��Ң*̋�Y���**�u�W���mjZ}����UK�2�H�w�����'�M!�+N!H�c��0�V�V����U�#��D��گ�aw1a��Z&�iH �~���[���ӭ:4������*mlUꍾ�Y���\7�M]�UT�	�l��~�U����6������ZI�Sظ*��گ6z���i���\���נ[��ffj�Ӟ���e�aMZ=Ө�6-�VE�5�P��U�u�^��tW���u�k<Dg�R�Fz��n�h�ت�{@�ji@�z�_���4e5D�n�E����A���V����zU�n6�݂�nT-N��>�@6V�m(]9���b֌�Q5k}��Uk�`j*�z�R���6L���Ʃw�h5��ð�[T��ok����Z��U��o��JE�Z��n��F N��fT�JC��V���7`b�VM�Q8�4�:�֛5U�.W�u�������y��ZFW��	�S-`��i�VWa��F��T��]в��j��W��0[u6�z6�~���~cK3���*a��JW���_��ˋ
��f��j�����}���l�ah�C5*��V��Ƹ`(*}�h��6�MUWᜪ���XV�ZU���QH;rS��V�읖Z�Y��h ݛV�b�6uk�ѳ�{�g�\gs��Y3h�j��̭�imZ�>�s��e��Z��U� WS�^Z���1�d���諰#�}�3���ШZ�������;��fz'�a<ٞ��Y��T��5���f�&�.&�@��j�.ˀ�u��3-����Uմ4͂��0�����*;�PjZ�Bx���1PE��aF�ִ*'5�ׯ��U�rq�h��6*x����v��Б}�#���C ,�I�'Q��eׁr_�6[����Z��e�?ز+��Ԗ�0Lr�/�^ts��jM�X�:��H������/L8>g��Ѥqu�3�|�j��G�)o��z�K�;��&v�7��/^�t^B��A��<��)ѷ6��:y�S��&���\��5�0�����%��Sn���^"�;p�9d�V�¥�Ku y%���g � ��Pzײ����}��������J ����wk�qH��8���÷%9&�#<ne;9��~X��$�<��n@�؛/�V�y����@�t��q�r�]�6�9�W*%����w��M-�P|�-�/�b'��3~aK3��n��o%��7V	#��B���+���oĢ8���4�/Ȓ���*2��Β`�D�s�6^��
�È���1*.y/b�>y�Gt��/��K�Γ�6$:ᦝ�A"^��,��^������緌�����n�vN�����/^>�PG��pI/�Ę0�頗"��+��	/����Y:��9�q(�D���J��%�2D��I�[C�?�Տ�%LJMK�Wf�o�Y@���!a�q��xҬHnw@�D)f��Z��x/�X�������`�ӡM��	߱T���(�MG(��!�i��&nD���1�;.�#�%��\��_UJ�-�����w�d.򟞒|�R9/�����55���v�W���V����/Mx�2�,)�i ɐZ�EX�0�3wd����r �D
����{Z�>'b�Nh���>�)b\��\�XLs���[
{޽2\�WN`|���}�z���pnz@�:Zk���Ϛ/��wZ/d;�~"�!�i���k�R}���d9�$�ZR̾8{(��c����d��U�P�f��勽T%سLX	`8z�Ɛn/nr�EF��G- ��hI&�a6������ ��nV/ƌۇ�o; |&�ܮ˒��wMo$X|2�_N���`���6�p՞B��"S�F�cz��$O^���]xѩx,�E+���R��o�_��[��O�p*9�K8HM�8兇Bg(��Os����~-��Ǔ��s;ŕK	�!�*,ס�2�V�Z7-"���C�3ß��b����*[���L��?�:�\�b��-���Y�/7��������r9�{��L��ݝr�G�"_���/�_�b37��\[�||I��g;������Q�Ƣ��\����	g�b�Q��܌��o��?|$=e�h�\��D��טk�u�d�{�e	��k�� ��(⎊��I;��f�ی���v���G�%�ă�.&��xS{�ԛ	�k�A�BHiO��ڙ�R(`_� Joe��Lx	hx3R��bh�(�čK�(C�>�	(�ৡ W��������&F�������n��-g��l����%�`km��'���9 E�i�!S�1�K�(��>��ߍ���Fx>�"��XQ�)x�>&2��c}��J���K�y�"�����	[$�Mt�FC:p�hR�uѷ1�Ď�(�;#�؉/��B�0kXj�}|���4�t���2&����1D��~�d��M��?oeC���1eEg^�ǡǛ0�(��YY��G�怋μ����yG�Į��'c�a2�3�9�{M� hk�ͫ�̝����nř{�Th�n$R���w��SK(�[�	g�GZ�����q�#û
�5E8��d�Հ�!��ʏ���|�:�/l��~a'vAa�
�c��+e��.��9������
��*5���"������&��K5���68�
�Ce���\�<u�ԋ��>#�2���"C,| &�`����	�2�}���6)��Z^s���J��[o��w��-?=c����P#m7���~����
F3�̊�ىr�"��t]anM�K���[����f&YR�"�9��v:��Q�³��t��F�~7���VS�W��*�����.Q0۱r�u�Y�zC����Z�j��_E�����?���T%� قZ����ڂe��Hj�_ߎ��;�{�z1H����ً>S����uU��?W�b���q����Z=��U�T����q��o`��|����Qq�S�=��������0FK����_���5iF���1G���0����Uk��w%�Y�)%�0}��c�~�r��'�������ӏ��w)�,�mDu�ssu����ױ�GƆ��1�����ϭ��o�9{�b�v�q 3�?��y����/0X��ȇ���(�xI��Q�		{@��+zV]�"��_�Ч�[.���x���ڔY��W�9ư�s[��L��x|w��w��A/�-���}�)��K[�����^U��i*B���W��������|Xs���Z��?jU#�����o%i�����om����������o	�N\�e����]��ͽ�[����-o ��W���wr=�A+�C�K�W��G��R��kw��[�u���)�/��}����2�B�^D�D�;#D�e{��L}9#�r1�Zx�F�?�/\t��&;K9D�0_�bXd�N�43���o�b�07����sr�~���=�b|So�2|��5�|�6���\���;�F�;{����Zyn������ʦ1馊k�����k �*�	{��3��#|W�8�J��caT�cTܺ�ׄ[TQ��2�R|Z����f�A��}���#��v�Y��P|�C8܀p �A�Xh���������;����6�Ԁ Q �w2q�����H	�(�wq��u��l(�Uƞ;KG�;�ꨏ�.х�1��*��*�:P����7�j��� �����R�������������7hp=��-E��`y�?�,�Β�A>���{|�����3bA�)��t Ƥs:�S����{Em��ex}rn8��j0&�{d8|�?ma�1I.�gqD�L���.a ���+ƴa�+�g��{�H��Zwō�ј$����&�2�P3_=�$�&� � �J�H�`�؀��1�ǔ߻@�Kj@_Yel�L�b�veϱ�����\:���(��bg��މG��T�����tZ�po��Ǹ�w|������g`�����6��hp����N��8+3pǩ�W������(��S�70���uM$��I����ܮi�ד����\Ll�<�������'�}z4��u����p�m���g���\Y�_~>�=�{~�o��p��x?T��7�חo�G�S���w��W��v:��߯L�)Ѥ��%:��,���Y6���F�UP�id��0(J`H'v��2t����s'�3~�A�T�߈|��&���0��Z/��<eC+��J,����>�8_��k?]�	�'�
4�,�0Pň��+|���kLz����_>�7�������/?����/�7h���_��9��W��ݳ�����_>�����������9t���y����K��j��A��q������>���ۃ���*�6&1=�ɟ7nI�k~�v!m
�	��_��P`O�!��*��Y7\z�.�!0��>�z7�x�Y��0$�b��M�%?T����0�^�s�g#���Ub xd�}}Q7��W���2�z�x�̠p3� 8��0B~�j�@���p��qg'�����͚1�1�?��{�M�ه�*��*�a������O��D�v�'T��O���������j��YM��h���-W�ڝTe.���
��6��c�:W�BF.����h@�}/�7�ı"�}���Q-��;�@N�%2&�躙�����)O!< Ǜ
͚�a'�I�-��4B��q{�`�SF�l}w\2��|�C�H���<z�e�Cd�N��Iv�j:�`����/��%��fb�,7P��3" �rRbDpQ5P��TkF�q!�p��R��1�b����p��Y�6V�K���I	C ��t[Ų;�sQ�)��mS��AD�&f��@�KzI+��e��aT|XV�7~�9>}���E�A��t�^������9;�?�J5#�b|^	Gt{�°"�-�9���t�[�$�}�{�$1����B�u��Ͽ�E�;��O>��w���� _�*_ĴQ�*��w��h��kߦʀ{��C�?�̀:y���
.�r��(��^�F�qB+;~k��PBj��4�%�-"����R��UT������;���s
��t��Jc��{�oq=���_qwk������q�h"�����VL��<WO�Vxn�(�g@����:��/t?H�g�ۨ����Z����s�o)�V+��X]O[��X���^iO|���C�X�^p�o�~��agZ�C�ZA|�ςe#�<ɄOb"�'0dkZ�:�[��a�]���:c苮@ђD�L���{��; ������s�rA�}Dh$IƶA�$Q��ח��1�<�a-�6���
�p�ޛ����16���l|�<;$�ZhG�����B{���!}$���.�y.��V��mY�U�A8;쪣Ȍ�g0.�4��5�8Ò:|�bڂ{�Q�L�ma���9H�����$	-q[?����~�N����)�����F�D��p� �Р>=�K�p�%�� �9��^����j�5�����$���7��?}`~�]a��������|��m�gN�5�`Ѕ�Rh��+���M�%r�2�i���t���TW��=H8����I�?�M����*R~�����^]O��������KX�ėiXW��/���5	�a�B�1%����C��Ա?��bf���(�����u��sR�p�B;�L���n���Ut�U�����>5ey�۪��#�p�nl�<U�#���aP�1���<�.�>0����ILU�<��03��f�ϼ�Pv?�e��:��<�ˀA����Q����m���( ������t�����+IS�U��s�]ò��8�<@�g��7��o���J-��V��G�V�����a��\����-�b��5�\�co��s����/w���=p-���.q��>�O퍧��Z����cF�"'w|`wD4m�WZB����/��6�����M����J&L%n�6�6Y��w��qanv�aí�����ӓ�K"�����y�+p�_(>�_F(��X�w�Z��_��Oi|}H�w��q�����5�+�>�Z�D�߈Z�@-u�Hj1N��3'�V��UF����ʈv����w� ��s�v�"�}���d� �:LG��@��g_�D����JTQ�)HՄ����4�I���P?���ȓ���*85��&�v��b�[�N�`��,�h�"ߌ/���H�
���[��[��wCoH���Z�����=z�����/܋�M���F���Z�g�[�}~������7����!���׬��-e^����|8<���e�V�u���f���gX7�x�Gb�<��z��KR��Ey��:�? �(�I�m�7C�V��"d�ݡE�K�����*�^�Ȱ��CK�� �(�$�̏_$���w@��d OgAe�E>%�&!��>;*yǖ8�tfb�%�6H�'��E{�k��Y����-����ƿ�+n;XzR]}��m����#~��)ʸ�C��ON��%Ì���D�r����(��B�S X�O�6+Ќ(�{���(�Nb�b~q���$sz��3��@���:������\�?�w��ǰ$�
�^�#�<=9�o׽i9�Kv�y�<f8����)�cz`ʍR���?BH:�+��Q��O�Ҩ���JT��V�����E�ii͞���3�ӗGб������i�L��{�(����@�%M/�Ք�e���3z���#�v�K�^���q}�EfY�p�*Xl���\f��J�4������wm഑9[� Eq���/Cc<-oF��"(OT�̋��s�W"��e��]ց��/�X��"m��V|��aX����I���<�gu'<��%���f1j8F���2Y�P(�=l�:'|��7��_�O���1~�8N@�%��hc�xt����ih1�q��x|2����Б^a4�@�����~'�x�+x���}W\FC-��FB��S8O��b�x�T
)E&�ĸ�TG�@Z\���+�Zkj�v����t��g﷐��?�L;5}U��-��\a��?We�9{]���9������O��Sτ�������h�ɶjѾ��s�����d�Nvn���~�iZ�S�|K��ե��i��g���\����*R.��J���������*�\��B��q�lO(�N�B�w*�y�ra��
{��K�E�R0�bd�����$�c$�%lab_ls'�O�3��k��Ԑ��f��<�E��TB���$X��p���#�`đ��)�)� zp&��8c�Ғ[Zt���ې�fvff�s.O7�[���)��+�I�jj���F.��"��������i{ rg9��j�;��O�
��:m��9�yY=�L��}�f&���<�7�G�e ���q�Fψμ�d'?�H��c������7�g	[�����7є:�R�%C�E����`�k�`����bʃ�g�8%���?:R%�҄�n�34��aPz�̸�]�i�&�;�ۻ�P��0��Q�g@Ӿ	dj�Ӵ�m�aqq����S*�?7�r|Zy�<A
i��˼l�3�� �	e��+���@w0nio����\�Q\�������>�ܡg��=�K�0�f������E���6�jI�*�Z�����M�����+^\P�����0A�(�` Qf��� �h�q�Np���Q��X�E���Ï'��@+пVS6��������7_ـ�eq�$�-�i�h(��Q�m>�9�t���$΍�R��?�*���7�\�[E��o����/&_x�Q���\���{���'�3�!��GH�pm>U0���7Nh4��``����5�!����9=#g~Ȧ�]÷�!z����ڵ�f�K�w#l������Iw��v.��m)�h5�{�Ɨ�z}��^�$��r�Z�+�J(�i�zE��Oa����H�x
����Ɗ��M��w�ȉ��8Q\���R��m�sy�9��uo��QQJ��i{��u5�15mc�T��A�OΗE��όfuÙ��f�fe#,�oL9��tB�c�π1�?.u����քwZz~2��18Ɛ�7MP��Os�:��Ly��>F�?��!Df���ٟL����{��^���b-b,����h�F��=w'�b���T���}�!�O�u3q�fe��e�<㸙1:�aG���nh��hԁG��N�el��j;@E0��z�L�fţ���9��ă�#ޤ����$P�$�{�	+o�u/�Z>��������'7wOk�A��;�ǲ�(�{�e_�/�A	;B����9)
R%8����<��)�W�ӕ����j�w o��Y��I�V8c# ��ǄmF��k�?��'��}�<a� ;�-t0�d�h4����>0�-:�cc��皯K�J�����j��>H��k��`��?�'{n�����똣��Q�?�Z����s��*�B��Y�?Q�i+pXXO��{?� HB���I��wc��.��Fn꽀�'�Z6���"I��q�8[ ��K�s �m�Vn�-�X��)dn|�cd��(p��/N"��	<I���煯�y�M&����E�,͋�V������_m���&��~����߆��#���~�����]Rz>D]�pH8�@�>s��&j$»��wF%����.S�� ���BH�F���>��'�W�?��d���~"�`4���I@�����0|�a��َ�1}��x��n����Fm�~���;�>�}�{p��VF�s�+I]g#��m�O��8~w��>�S��a4�ˡ�e!*K>Ժ�:���j#��*����?9������fо� ��VdbΚ5���ȣm$�3b$šM�U�Jj�DҜ�VR�\֩�F�R�0�V��ԇ1��WЌ�C�X֋d'���U�N��!�_��;C�C�iQob�5����-��y����,���V ��� υ3�:�Ŋ��@�=�G�y�;(�%��)���
*����O,����I�m���C�W��_NU �~^2����I�Xj�|����a@Q��k�D�y�t`�d�dd8cx#r�������1q.9<����q7�Tء|!@�-�v�=�R>N�\��y�[����z�LR�]�ߟ
'Wc��m�#h���k��0����m �4O�+�;�\�'���2������\�^��(���c@`����{��1|�XFwb�(pvj�*�Z�f:��Y��`<	Z@�0�7]�wax¯���z�0�b���f���h2lv/�~i�������E�J}�ӯ���՚��V���z#������/���Y �E�=y((��i%`b�=Y� * ��R��4�ɘJ�E�� 165?~�x��	�á8 �X�+~�����D�	�;�����a{��\�`���vG4~"�9h��ba ��9�C���N�{<�G�C����l��È�4�����AXr�a]	�����5tP��&% �3<�K�Γ3�$:� ��������qa�CV�T3�q|ؤ��e��}�99|��[�d�� du���-��I$Ƅ���w��&����$X�������.IG)��p��;2�$N����E�v�'�)d�(�ܰw@��F���H���((k�Դ(������)'���oO��~KX��v>N(�
�465��&�<�-kH/�ʨ_����j,������-74��339��@�ߤ��M={{Aٶ5�NAP�� 7<پ��иZ(�C��l���%H�W�����c�{p5����O�����\�?}���̔���fW�������Z���Z�~����s�%��݃7{��
���.L���{���J*�O��7���{۟
����㽓_��G�/�v�����w��sz��o��1�s{��e�,���?K����-����l�W���_EZ����e4;C� �	C`vr �&Lch>���|=E�Bʩ�	5�;�n���$	�B���
o�,&a������'�w���s�+�\ƃw@������h^���s����}�zo't��%G���q�Ϗg͏�e�{*��'�B��Y��"������|�>�	 a����?�n��MMv/]U
�m��x�\Ē`�2a%��ld@u~���&�Zd�?�Y,� x�ʇQ9@١e�A�;�ݬ^�!������7�벤G��;��7R,|:��")��/,<�p��m&�R��cz����?�C�0�S�XF�����}�ij1%-��\]��ٟ
;�Tr֗p���NG���~�<cJ�P�S�\�~�`v��:'_�Xn�+$��s�U,i�&-���],X�C�� 릕�3�w���,��v�uȾ��(}-A�!�]	(\N�P�����5� ��gY�J����֌m��d�Jb�،ğ���aO�ڙ�	 i��(����>�{�6���=�\��E�Y�������,��mؒ��AVnm�!�<cH�`'wTj����~��b�C�k��� �����G0�(��YY��� �=��И ��(��&��h�&0��y�>��7C�����ӻ�xs.���n�x�1�n8x�4�Q\�nk��Nn�ы�
~NƜ,&QL�И����YG)�'.*D�x/�����]R�v����C��������6}�'���]�Ͳ|X�RبG��|lEVt�8�>��x�yH%��� ��/�ܙD �����(sJ��(z�Qa.?�y�_ȝ��jz��YE����`%taΧ��=��U������<=4e�1Icaj�y�����Z�������\I��������������N��Qx����:x���[�O}F�3P�p~Q�@>�}X���[�c�ly�M������:��U��������s5�;`��Nnn�J4�L��w������>"��$fV��N�[�왋(�&r��)�ouҔ|Y4D:@�r����tvw	=�yWxvם�P�f��9��Zes���+�fRss~ާd���4��Kݝ��������?��Uc�Oc�?u5�o%)��y���*{����lA-� zlim���j$���oG�Z�{��������U��������7������<��JR���Sd���0�F>E���lF�����.,?�K�\/7�K6u���5= �˭��3�L�9����fE��U;�	 #1��ã݃�N7rEmقC���g�\+m�ԮV���ɠ/Z���X��i���!^��Olh��eNIw�.xңaݡ�G���,."�JC�H�? A���.�%�XH��?Z#��RW����6r�o%)��O7;��I��'��	��"�E�9c�;Ap�P����<��[�`�,���7���
��$QfAznh�N$�%��tZ��7�p� �?OO�d�]' ��z�#��Y?3�|'̏���)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<=���`8Ls p 