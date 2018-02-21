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
� ��Z �klcI�&���v�����|�׷㯆R��^�)J��{�-�{4��E�{f�{���y��{��^J����Cb q?�8�cH�$?��_��$A�@$$��/�����z�[u$%QR�k�E�ުS��N�:u��9u��N]r��r+KK�~.��\��>y"��Bq1����/�\>��\�"K�����j6��X��|���p�{���Iu��<��}'�/����_(�`���K�����q1�2Er��K(}����,�@]s��i�_h3��U23v�{�q�5��.��}�0u�!�H�X��n��=R��z�풹���<��izK�u�qm�qtR�`���_*���u�v��Z �c��J�;��;�[ZWϰ�J�	/�}�m��e��5�l�m�c�9Kw�C�e,��c�w@�au�t�i�^��q�ښ�қ�OX�W4ׯ[΀/X�]��p�e/X���ݳ�A�4Cj��ĵHK���N�f6t�ZH4�غ�7I�j����;��6���`���f���w�&9�l��G�m�tPap�V�%{�*i�^Q�aX�6�vݞ��Ͷ g����e=� ���>��=��*�>Y���|&�A���/B���n��uȑnc7B�|!��c�������!��0�e�)���ə&kP��5��\@�"Г�:ٶ�+���{����K��j:d�p�e,��:�T�&���x$)�
̑~�%��N_w.Р��nm}{����l�wv�[�Rjow��"#�i�]���I�j�C�h���`�߮UK���9�m�a
�.Φ�������Vy�Z��C
7�ϐ��|ros砲�[]������ʺ�^�>|���ϼT2�f�♙�T��W��;��Z�TwK)�ٓC�6�R����=b�y����9Kf����r��[��J@�[�2�h'���ۻ�\R����$��o6��.B�xg�!ǋ�;ZK��'/���b8��v�2��v$'�
)Q�Gk�i���փm��*^�t��&i�|��{}hbk�z��+�##��-��%����ز����gQ��nG;��̹�8taq�_1ŏ��G̔��vT�F[o<�ˏ��:F�� R��$���w�4�RŰ�.dS3�5v�Ȯ�OH�?��$�thX0�X�ؒUn�jQ��ˍ��NY>�<���S�n�$G�}�뻙�\��Y6��o�,����)}�w`��/�|���F�49��.rjm2�b<�5�T`��.k��^��O���\���߃E2g��i����\' ��'0�����d}� ~]NA����d�� ��o'%p`�7oLR����	�[߬ m�������~v���n�N���'�w6W��R�~(�ݍ/j)LW(}�z�?�Z�zS)9�]�^ɐ�H���h�肆|�"%�ŀ�dY��0(/��Ѷ0���N�y��:Ik�|�J*�j0/L)��i���븍�b�վ�R\��R�Y[�x8�u�-N�*�4�ڦe�a�4�a�w/�M�Y�G#9z�]�X�� �PD���f ��A�^�_�%G����g�yd�^�ܼ��"w��6$=��*/e�
٫�L�R�!�aK�"Z��T��V��N��`r�鲆�a�(w��\Ea�*`2�K�����*6 ���oZ.T�3���+�?%P��-�mT=���~��8�衵�b�Gw)`�v������� �Y�N�Bp�~��v|�.��� �ciM�t��'�@ٌ@R�8��5V�*ۜB���\�8�|ն���&�"��C[Ê�ѵ�����	5�nW3Up�s�k:��	uq�M�q�d��e������U@�@��3��	����V|���l���BlK#�'L�]�qZ��T�����∙��@�,��B~�V�E&n���6Y�|0ة|�J�c�45����:K��?�v���ul����{i�,%�!�⴫w�#�u�ٜ����U@�e��Q��w:�⁌�������`0e�D^\��x���1,�@�\�X�'I!��lLtQ��㇘-��B=����me!��+B��P��>]q��%�^��wI�x-#�Ԛ�AmX�v
N'I��̐��C�6�ғ�z7O�;�u����� �~�oۓ\�C�|�N��
����J�u��d��a.����{8L�$%�����IoD�~��J{��8�:�Q�XH���Ԍ�%�wm�GRJÊ�I���%�)p֡�HzA��M'�>HU&U�{�))�/L�����]�d����N?\��j���i6��z'���I��X��~�Z]�Q��L��'� t�4s9����a�1O6OdBF2�ށ�y��U���h19�9d�XL^{��Vw6���{��aU�W�2��Ecd殼Pн��-��!��@�6X�F�u7�Q��������K�Ȍ
�s	r�x3f�{�$fbz���C]m*TAX�m��Y'ӗ^����wK$���6Jp��o ��W�3e�B�Yx��A��[$�u�#����G����j:��=MFP�(&? 3/wWxCNY7�˗�p�A�Pq1<8|1}S��e�_���<g:͎mӇ��=���J��\�}Ƕz������#�G~C*[�>{,��D62�6H�e �{*Q�D��,��٩��W�s����G��8�ք��h�<��<;m�Y'�˙l:;+�!��҂���xy�z������k��<�m[r�=���pQ��ɾ����>5�$��il`������Z� F�P-z�a��2�ر�4?\����j��j�̵`_�4�l(?zԛJ��Hc����K�a�����!�@�ߐ���LC�ۈ%q+c�Fj�Rޡj�B��c+�f^|�P~���6��i������������R꩙~
;��k����[ۻ�5XJ�ن���g0y���e�ٴa��Wg
���G�X���{Y�57��WY3��<�������K�%���'�We�y�:�`t��!Y~���)O{I���2,-�qR���|�7�����4��
�4t�0�3FR#8#��_��N!�ȲC�)�/����\�\ߒ���ULkvs�e,�vE�U��4)nX#����bA]���2Z��S! ��45p>��>�{J��]Щ����o�ַP��) h}�I�g#���륂B��>�h�ۏ�c���n�O5	�_f�u-�������o+K�\������߫H��k���&������j�H��y�v��g��K2��/�k[�>�>�w��{�����ķÆN�)�x͇����c�>����~�Lx��^7�ZI�&�!S��=���G���^�^wtc�0��ِ��'�t�y^�M���#�.>���RY2����Ȓ����Fvb#�Y�������<v�X��?�U=����8�êpb��5�냬խG��V|���> �ML�.@�c6��g��c��<�4�Z�fzWa�W�1��BFI43'�<���n��Ӆ�S�m�_�}�X����&^���6�Us&Ցt)���3t�z�^$P0���V����`���Fl�4lw��z��z� ۣw$l��*|O���Ed��q��^��kfqtDf9=�_9z�軀y����ZĻ�qyw�FTI���B;�iD�c�< ٣�Q�CL+��i�.^��K�Mn-�7��K	[��Vh5b�+��$F�vm�s��2�}��}�}:�"��3٧����4y��x�DZ9�`�,���뾣"k^���%���.0���&�����l�f7AL���s�P$p��>>�p����n�b�� dqSǛs!h)v��M���8,��Xܻm'��`{2#
=�9���<I�Ĺȹ�!yEt1�R��+�:��/���Xx8�dj������-3
d����yuJ�3,{�~ȃ��-���]��2>�J�*R��U)ϯ@�{������}I�'�Z>�FI��]U/���b��TgV�����.�2��V�x�6
1H;s8��"7'��kY.��U�$r��g�<Y�w4���g��!�ā�3E��T�9����Fd��6�l���Y�2��ef�OSOS���l�ϑ�_󪖍M#ڙ ��w�H�3/�`�x��2�^?�=Փ��Os�z�ou@/�Ikm{s���>��o�f�t�	�9�n[�KAo$௑,�F2��Bm���|�
�٘�<�h'\c>��;�Y�/�Q�r��=z��~
!0{��L��d�0d�ʬ���ݠ�����ܼꨄ��3�PH�r}��T�Nf�vū. yA�ժl�V=�,��i
	�߂�y �$ޓss�����*�T���������;�m�	0���fP����m���մ��?E��uu�Q�6ެ՛���,���g��E%�$�izH����҇�9k�����\N������M�z����.H�=�ĔU���f��W���'q�w-��K�K���g~q�?ť���U����5�z��b���͵�\���C�??��V�<�ڗxJH���^䲮8EhX�!�%���G�g?�|bP��0(�e�o�w�+5+��b[���1r�X�Ę�g�i蠟'?�VwJų������:Lh�c]N'�s]�%����t��J����dW��"�AGkM,h�dZ�|��������%i���h�����[ݬn�7&6�����&w�vb�K���Nlr'6����&w$�܉Q��(�|F�\��N�i���N�i�(c�q��|i�Uc��Z�3Z� TMi�zF��tk9�g�X�N�F�`�Q~<7��(��/
��8K?�9���
>U`1�.pu�:��~J+��I�7V�E���c�;Y�9���Ĥ���V����j���mI粟�OnoT���3��g^�	���<-~������A�
��*=�J�QJ�;���ќH�T�G!��:D�P�q�hCU$4�?�+>�faU��-~��!�R�j�&���v����kk�.d�����l��A�#��|�E�U�D�2CT;B�0kV�k�x�ǡ����(ʖ�ãz<q��ML3:�=�medg^��H�B�F4�MEI����:�^��C����jJ�xð���W��Q�(+��2�����mo= ��Z=�i�I�8 w�ж`�q4c�Ц=U��PhZVk0���ot*��7Q�!~r��1�d���C���L&��g4��9����1נּ��������#'���G2(浜۠x�1qH�Oz�M�^8 n�����r��K:�Y�X�&�����5�2a)����0��&�P8��,}�R���$lFnwIڎ����Of⛱e�M8�� ���LX@�@z>�`G����7Gob�}�tݦ��eB��́�f��:��r��2�s����˅����Jҷ�ݩ���6�ٮ��k�gS7�_������wFY���e�h���}?��[�������z����h������ީqo㟩�?���Z��P�-^����E�Y���,�Oyц����ͦ�bj��?�������~毄�^ϤD��:��exZ��b~2��$M�\����M����S�&.��E�#��F0����e�Ʌo�4awٓ�D�C!���|7����25�ٴ�u;�m��Bu(:\M�Χ`�\�d���}"x���ל� ��tΘ��1�� �y��������!cn"�3|�Mx�����r�"�޿��_0M�ט����� �e�Eh�1�4l�55�K�I�I�;���Tw�N��Cu��Uh�����ƽ���Q{�	��:ơ���l�#��'8&�f����*70���T��70�L�y�g����^-���[v)�=���O�O:����6*۰�U�mZȺԌ�k�9����>��� ��sa�Kw��P/&�l��ګn�l���5�c��{c~������ڞ܊�(�JPٙ1��,���|!S��3��\(���23��n�*���R���dy�d "W�	�‑8�-��T&J���)~�WEC������NG��4�$�U���*��҆�d��!��H�w ��Hಁ�a ���HA�IyV�;�.AĴ��!U��,o�7��*`�������2C����:�W^�� $؛jr�Z��.�w7y8R����4\с04	���8L���Yw�]��X�B1,)�ӡp��3 Xa��ȶÁ�Y�
^e���l�6����m4r�������X�8�.�|Rn���
œ�V��\��OˏʢJ��+�R;�X�"��O��݈(\�������3���I��;�Ly@щ��-Z�ȉ�v�r/�����z��g��%zjoPyӻn���}�F��J�����Z���S�+=�z�m���?-X�Ŕ�t�d�(+��1f�?[w��I����ބ½-�@x�z/#��3��ɌGª��^����]��h�9a�D,q�I��Ny�4�;4lǕh����,M���W�I�uJ�=`�+���j� ��ǩd��e�s�O9,B���,��>R6���z}�v@h����ӈ�>#�H�H*���d|D�Fߧ2a�yf	���hd�V�3�2���0Z��.��./��)�"�����qJ"D|�پ�\߳)�,��Sߟ/�Y�:�`�[H�F@����������d2>�g9���/bB�R��������O_ߒ�f6S�hBݮ�2b�F�C��a߀��X���%[��E�����U�(JG��:��:�$����{0���
���#��C�4Z�	�#"���-�F<81��g��͛-�%�]y����&��b�Rs\K,���j@X��n�=� 21���F��*���bL�R�~@����F�y����vt4���ا�x�t��0��� ��Z�K��դ\�a� N&^?C�1���D;!J\M2Ԋ$y(���+UI�Mm�yK��<
����[�;3�����i�t6n��uiW#d�Qs\u$��Qr�8���`�T�mi�o��h�V词��a�� �]��e^�)��&=p`� �
s��*yx�]��z"��d4/ �mx���u�,�F��2�<�K�9���Y��!���w���y.u��fd�j��3.H�Θ�~P�sJ��ȣB�qo/O��������Պ�����-�wHԩ'�$�*Fe8ʨf����9(������АV[!	�8S���,�����:�{}�@���\rB�RƟ�\5f��y([0��&h�J{�;)N�؄���<rvX	�;�"�I�5�ek��~@u�рX����Q���d蹥�-�#ݠ���V4�`oVC�汅>A��f�Ο�fcNB0�Y�)"U�+��[c̀�aU��oT�;d9)��@O�Ykj^���V�e/�;�٩� T`W������՝`�q��e��Qr�f�2�����e�c�qȃ��7$=i���OH_��J)H�t�Y�gTJ��l��B����j��-_�^�����"l�<�j#sI票�y��T@89�l�<F9/��x�g;�P��Kg$�Wѳ�=$�w�K�����2�ZĿ��a��8�
,�  |i�A��d!��)�����S�8�O��fi[��y����Cj5�Z|�"�3�ֳ�gc�s3����X{���NGL�� =_ݦ��2�鹤=~��B���$�s�yg��"�̬&�=
a��Ph����[9=��H��/	�u��HW��"2��MI_앥�hwrT2���Ѩ��n�IU��8�b���S��DU i&׭�ӽ��!;UR��Q�p;'T�!�������q�^�d�ֆ�`"�LUă�q�`��Ta���8q���fLYa�w��jp�k�%rDÛƨ#&E�C�c�$�Y����z�9Q�L����B��3�ެ�����N�q�J��V7i�+.$�>Q�D͡:y%X�'�^�8kィRc풫��V���l��zF�$�AF�H'V�fs-Z�1-x�P�ŷG�'lNN�S+�X9HD*	� M!I�����<���?����s1���rL^:�/�W���
��sދ�T/jX�W�RA�EHq�++/"5R���"Fu!��/"u��ūX��=��y����������	�Wc�S�\#N�âa��o����a�:�̫'�r��� �l�`���i��*��U�NW%
\�hkuF햔ܶQ�Q��m�\+��\-7&��݋�9�c��%���z'Bi����,�b\v�4�C�O�I�-��lu���n\�`AHܯ�mo�=2��!+��Ӱ�=����R�
y6@R*I�E�N-�"���@vE�$eW����o#���=�vu�f����9��<��0<��ӳPl6\NiJIݻk�X�RBz>��hT�Hd�����r("kr��BFd�atCY���6�`����{#��s%��DD�r� A�\���8i��k�Q_��*Z�E�w��e�.�+P����B���c���T-K5Q��7A�{��_����!l�8!Ո��µ���RL>�R��NF_;kĀej�%9 ��v��C�̯2ݑþ�s�y�4�[g'U�f�����!+�T�"�'��4E��F��%��3����e�-2�O� n[��e�Η�fS�߫�|�.�."�������0��̫9e���d���P^�o�}Bŭ�{�0�w��?�HEh�g^�FO00�<�J�<�`́T��X\��/�Z�'����6�-�C=,^ƹ%���� -C�Y��z�\b�m�hf�׃��;�oQ��g
�V����K���P��i6`$=.$��ВR(v���`�"xN+�BK:�����O�ʌD�
:tGC(PhL(�Yݮe� 3+ͨM��R�i�|���c	���K�IT��g|輍Qm�,p�mZ������ꚉ�Us�AfӠ[��v��3�ÞH0ZƫAf�A�)d��iP�����N�\H�K�K�t���,��0;���9t]`+�Òe'��l�a���̰.��m�Ew�H�-��)ˁ�4#�2�_��&:�T��i���Co��h�t����}n��>�G"�1�$g�v�	�:���ev��t��^=آw|mZfZ�Bs<��c�n�1Ly8D�q<��t(8�Je�|���1��/�3��p��A�,�D}�!�fֵ5�t�5�:�z^J@V��B�A�Rf|5�(��c�{#@+�N"[�~��t�X�/@w��qwd�.f�m�Ǌ��a{�y
>���bѢ� l[�p�;/�JN%C�|��gH�h˞!����Րbs$~23��� k�!E�ne�..�G��D��AG+���y-�W(�b�W{��
�}	MEUYH'��l:�\!5��#w�w|���Ğ��ԃ�)�~�V��u1G���u�D���O�*�a���17e��2| �Fց�4��ZnU��[U��V}�~�o�4��rtW��%�;���#	��Z
ZF���51�+��S���
��%��q��Aԙ�L
(���\��� �
R$���.��yU�n_�a�>S��g������7$0�w��=/R(ߤ��@��0������H�5R"<����.�ǁ
:T�P�5�|eчڹ
���PAq�q�>_V��B�}G�bFqc�<�h���h*��ts�=�t�ރ\�.
ݿ~}o�\=3��r�q�a[6"P�%�*�cL�,!!�3CqxNWc-놹��iUv���O9�ѭm^2��C�R�9�u��A$/�����[�b�n�!��V��\*�{P�4�頜�"#�t3sl��!�Bm�sfH:n����C����&��M� �>ƺaҥ�|҅�h����̳� |�V#�R���߲�!7����h�]���G�721B�`d"�vOs�c<+�4$��G{��߈�)���ɄWX(�Xi-Zȭ��GEd��q.���N� �hJK�D:V�D\��c��BL76��G�NƲ�'�;r�$�#5tϘ0�����:����x��B._(���y���8E�.	%}��4��e��F��R��p��K��d��"���Va��f��K����q㿸������/������?W�����e���P#5A@ٌ�[��G�O�5*߃�����et{4����9��b_�a!�V��S�itK���Ű��c�8��;R�`ܗV[���é`*�Z�O��'�<�d{]��t�y)� EǗ�����SD��1}b����o,�t������4�"���<��,���vAkTl1ⵆ�P[��������n	j�X�]�i��w��g�J7VD7*�L�kʵ�����a���Z�������2�z���Z�n��6�T�����R#2��]A4w�8`�<�K8Lw�z1����ݲ��2�{�_�d�g(�z�lP�8�G��j�N}��7�h(��������44MD-i���F2>F�$x�~ҠT���y�{Pΐu���6\W7� ��bf���3�Q�0���h����X!�U�r5��ى������10+7���L��8'ٚkî�M�w�tOK}��}��y�<73t�8᰿��c�~/0\��jt��W�e�.<�pX\'~��:r��<���0��'�D�[Z��� C��\�Ag�z�x���կh 2v��1�[�M�<��K����H���g�6��f6\I���(�ϧ���j��ե��ۑ�=����D�{�I.��gh�A�aZ��dphoŘ�.��Tx��Z�B"O��g�N>��T�{F�#P��J(�@�Z�{G}�{����|1�{6��!X�}��P�m&s.F�����>?�Q<8ݤ���n���ZM}�@����k-�e\�l�G��f��t>�Pe��$e�:0�� @���ϐ�Xb�!�&5dN�M����g�U�dU��Ѩ*h ��*�Μ���7�Mۭ��C�UeL$3,��Y�������6�3�#ʬ#�l�;����]?v��v:���>�VcļR#�e�D��^�� �>P�6�R��ND��ˡ�<�;i-_죉.�5�͎��>������s��E��U�u���ױZ�H&���Ҭ�ШhF�� wms� vQ���A��72��@�t��]Θ��b3�KsR'C6�o����ѥ���}��	q�����Y`�����M��ԙE5�go��!9���H����&t��
�� }d�c.^0L�����H	�W� dơGM
��t���/�s�K������|&��	�d,��A~�-\QC'1�K�Ӛ��`D;�1���Կ�D�!E�@%�`!VH9�DԵY"�f"�F�W�����0b(�8D�����p١�Bw�y��_�a��TŚ��#��Ǳ�Ҍ�BA<�Ul������R�[ǂ�*!G�ܚ����c� ^�/����3���ra $?�g���y�@�|]��`��"y,�c�x
)�]��H7g����k��]j�T�*��x�l�.7�<�.8��Qf�}�#;�f��lp� �S���q���$���Xi��, � R��p�U��Ԡ���!����x��a���	;Ӗ�0*�����ܑ[R97L�)BR9JH�Y:���*=��-'�ch�}tP�cԳI��٤�V��~���#�gL�)?ɠ�x �G��I���m�H��@J�x�>X�L�$4(���1>�8�V��RϥFC��vz�7@ �Va�����5,�8��3 ��R�j)qWgB:�Fl՛��Ț(�b�Rq��r�u%�W��&�A��
ԦH�CV6^T(��z>h��{6����}�C�&��S/w
}{QnDPI��,�o?B�o�:nl�'G�>y2`v���^�A,V����D����G�T�HMwZ�)�,K�u~���_���'�o��\�{b�y���j�u����:�Z�Vۍ�q�!U�*h��/f�<��Ή n��{D;tuo�$��vPt�s)udIF|e�����!�%��<h=*1t�^��O��W9c�YU��
��N�$1N+�2b��1�ky��Ѹl~|�4u,�����Y2�8#��i�L*�����v�m�:=SL&�xz���H�]x~l�ϙZo��
*���1�D����(��0��E�������Z��y��7�E��R��օ��c<�<I]�AQ�CUEY�A�<L��1R-h�:�a�ѽ�s߀��2,l#;2e^�l{qd��^�c����GGT�(��<����#��x�Lq��P����ѽ���mAhp����r�b�ix݈vڣ�
4{��i�s	y)O&�|EA�@zE*:c-�@��K�*�3��[�H�_�1,?��P�>�}j��v�m6:0u���L	�*-���J`_�kШZ@ެ���mW��~�HS>�B��V��w��y���_��?�a����
a�I|����1D�2�W��a|#�9�:� x
/���垂��fm>e��9@N9�щ��ڛ�E���̖�̐�7�:7��xJH\��O���*�~���'uBW�\/+=�3s�5�q�Qm�Bq����1d>��� &��8]`�$�ՖU�t<���(e�u�C�M~I����k��l&�L�F>o�����4���pE�5��b��wbdo����5j_��r��A�cy\�����{�4_�E�"��[Q8��e�x\sa8YQ�4N�S��b`R�!���
C٥١I=���� ����AGa��*�;��b�D'��k�QS�����=8���،��]�Gd=[&�����L�iսH?�g��-��'�8�x��Uu&���YM�y��������S4�`k&���x腎��z&�0Ɂ��&ة�$�X���jI�wq�ReR.�C]�o�L��r7��2}44�L,*��������4=�Yx�t�j�g�N�R\G�Y�g`q���t�s~*���X���!��@��zOCej�S2u2����3PV:@�R��o|�%]�X|�
��Qm�C᝞R�mz���$}9_�T,^a/.�n��)��ġ+�R��Rq��"}� �7�_ȕ��+�<jU�)z<hU0=�Vy��\T��U)'ݨ2tV�\%rs�QY@�����y�=�@d�����
��> ��T2y�<Ɓ`�w�d����[}P���@!��P�<"�lwԩq�(�)�gLU�Py|O1"��5괡���Dؔ�1�YQ��������+�D� ��ۊ��ŕ���fy}+���6�b�Z~>��+!��#$!F���

�a�(�h3hK�#H ��)���C��(���EEy���Jd���x[�`��8��3�r��(�a�V3ݴ<�7(��_�Ch},SGCm'�>�֑N�����x�����R����dx�\9����= 4��
�z��Ʈ��6�T����� q<�_v����Uv��}ve��mvz�;tӜ�\�ׯ���X����7��(z 
��S.� 
\P7h |APO�7Ũ��y�3��H�,|^q��8S��r ��ϔ�#���5��YQOѶE
=�:�:kG����ǔGc��w���ר�i�� �?�BNk��q��i���m�t�1`��tmt�)%�\��6�\���"���wt�=ճ��*�&ybM��Eu��Q�_������~�f,Z�F�
4Re���#e�|�1$@ػ�`�{�Vߕ �G�8��n4�2JH?��s�|LÓf����1���O�]p7�EF���A�}���'�
��]^��XN�Ȱb!�;m��n���V��kz$%bDTp��J�w�ƣ�x���.�&)Tj�C�$*V��T�ai�Oa3J�������!��*��E.>�L������Y)_�n(��<E���j�����qZޑ��s%$n/�Гu�A�}n'DI����-�.�S@u�b����S�Iݢ#�U���"�%БO�g�>�'-P!A[E�k1�vݞ���"������R~bi$ξ������j2y�<�
SO�؇"����1<��,�:�ŝ~�k0�����g��<����I��t��c��I�&��U�����D\�(dr���rB�:=��`@{'b�y���#D�;>>�h`Ʋ[Y^���X_�nժi zd����G��y�N����/�����������e@9�:�����|�Wr��%��Jqi���*����x�95Gm�)����*�;X�MI����6�(�V0��գ��{��פ����<��iz}`�o8l��>�򰣹n��Z��W���GƎ4*$2,���2�}��8���\���t9"s �Σ�#<˰%�c��.[P��4\��̆�k̮��	�
��g"2��eW?2p�
e/X6%�=��7�>l� u�%#!j�G�-��O�`��:�Aaq?i��w������OV�g��Ln%S��A��@@&���3cG -nA����>L�cj���g����@DB�'��=V�и�4��u*r�����P\m��ܯ���Q?�C:j1N�y���z�b&�au�	=� nB�f�.�2�T3�<D��Zl���q�"Ϯ��������,4׎�8�ÑLLx�Ќ���ޕ�B�Y���_P΃�W�(̐5�u� Jy�Գ{��bv�Zl����z�SBMQ�D�V�K��d$���e8L~iM�� �N��	Ƞ�����e)��y�O�����v,�*纁:U�>��H���n��P*l4��[��p�b���K3Op3��i��7���ѩ�!3vn�Q�$�7q[�&ij�&/��!����������b�N��+H���w�ޚ���d�F>� �M݄��������@���v�W,���ہ,	��O@rȠ@=����b��N3jS�~V������s�"S�2��1d��,V�qe2��&]����4 o� N�f+ �+u��bq돞XP��8�|2�O��n]�"�5	|��5��z6frEx�'���^]��5P#����P�������2�:'���`#�[z���Ǝ��P˗f��?~�^}z�%O���Y���l��o��~�zI�Q�?�(1jF�ɨG�˓24��86<����W�Љ�6a~N���H���bx�	��1���b#�=���E����#��в�v���5Y�$T�w���T�\K���J ��S�� ܐ2Gv���m-�����вW�����N� :�7��Ko�r#��N���e����W�Y�5MY4���%�@�.l��j'/h#=�WRC<E�#ݳ�3F���9(N W*I��r� ��`�Q�f�Lm�I����}��9BJz��#�9/%N�p.�(���΅�g�^6�ը �F'6�7g�܍��ل��[Q�����Z��v{0��U�$u�ǎ�^k�J�^�O��fO�p����t�^���x�k�3��W�M��)S��M����au,���]�����k{��(
���فg�ܥFIh�d�B���S��D��q5�}aŖr��!�����يS�0�����@2��8g��ې	G�U�=2B�\��u5�bd����|��_�Y�,�v`�r#�)���&�i׆��܁���34+[$�0K�}�M
�N���`�
Ӟ������^/2�p�j��@���<�LI��o����<M�����.<4�*@A%h\} P���Ԙ�9�u~psf�-�������Yǈ�����b��\$����$����\�kr��?�����9I�)���x�2�++���&��*�D�{��_����R,[��U��U��:��(�����ԋק>#d���@z�W/����#~XJ��v���^�/o�&��,�cn9�kg._X)N��+I,���ܐYA�<���_�ǵ_��aof(>\�ּ�E��L�����+m�Że1���ݓ�b����Tj�*a��k����%�􃾬���`5����Z������9{�q�h���c����$�����K+��%ir��Z�C�����hA}rd �ԯFNO�Y�~}oְ���� �n>�0|�eב��/��ŕ\>O��.�L��^E��\^#�?�����Ab���U�@ԟK����q%_���U$)N�A�R;���\�0�O~��������2��_�O�W�F9�}0��_`������������$��I���4����B1�+������%)q���ü��7����,:��/���?�����)����V�7n�'i�&i�&i�&i,)�>nܺ^4&i�&�5L�����!�L��o�Ϸ�2��'���?d�	��-��6���?o�O�??��>9�J��G�ל�;�WP$���LM��I�F%ܻg�1eO�SZx����|ߵ*�f�mLM����V�	�o|�k���le�)s*3�T����{�����OO��K�G����[��;ը;�z�B�������������������7nܺ��n<�����^v_���/�X���,��}������שּ�r����!��ǆٴ��[}��<�^ܼy��̓�?~���Aq�,.�N��|.��Y^*��޼��;�����'_�|u�����!������/��S{��c�s��Z��#Z�?���L޺��n}���������}G��;�cZ�8�ݣ�7,s�֏�ɏ	τ7�khv���N�f|�r7l��ٱ�=�����]���p,�]��>7 >��}�c���w���7������̥+���wo���~���K���M����4t����&����{�G7��v�o��������;���������ܞ�q����;�7o�э�xui�jRw���;�3{��|�F��7�����������s���7�L�֭��@�����b��;���wn7oޠ�����;��������ҽ[�|���;�K,�d8���N������/�n4����&T����Z�q�|Sn6��M�r���s��鏹�6���L��O}:�˩���ԟ������ߜ���g�?��������3������?��?��ϩ�'�H|7�ď��L�N�D6�K����O�%'~���D;a$��q�$�U�e�O%���?����?��%�W-���f�+��%�����O�Y�?O������_7�%������Go}�-��|KP��J�o��B�|v��ch���O>��ז����� ���O������������[�H�)�1�d'ȊM6n�A��ه��Hm�������O~�n�?���v��|o���n'`Jܤ?6o߂w�V�@�����Y��rH������[݄Ip�m����7��o�Z�ܺu{
��͡D;�d�˩�n�����S�_�ۉd���&Hb.�I�����y�~b-QMl%v��Zb/�,q���D#�I�	+ѣ�*q����&����_L���_N�ˉ5�%�F�_��������0������HuC%���䓪���ۿ�O�����4cި��_�����mv,�5Ť���:S�)c�P]��}�]�"+�-�޻������Ztv�^�߾�3�؜!�brF�9I�4I�4I��I�b������I��I���ەZ���w J�k'��W�����������t�6����d����O�77����	r��?K+������4��q�X��L�2H���0�d��"I��r ���1��O>�_a�ߊK�K��b�8����4���[�y�>'}vz�C�]���� �>��f�f��<4Ծ��7�Ct�Şw�=u�l��$�;�OJ3�wu�e3��o��z{� u������y�ci4H���ᝒ���H��R����A&�J)#�ʹ�D�7z��i�ѶH��������D�D�SdI�,�_"r�C����U<�#��q���`a��NO-���}3I��_����nB�-�}��U`r��J�,��Z��b>���[A�o�Bq"�_I
�?�8��2��q�1D�[\,R�y�/���Vr���W���3'�k�<�5ǵ��o�ܑ��t��`�\��'W�W����K)��K�J&_���[A7[5��ֵDl�,�X��6�k+�Q�t���T6H>�#?#w6�?ξ�f����e����#m�a��m�(+�0�k���2y�`'�)eo����[7&L�.�DX�$xG�&N6i7�4��T��ʹtwn���Y^�:�*oVgH
j�{�ʥ���涇 ����s�,+�d�8)r�HX�'i�
���������;����^;5/
;NG�T�Vې���}���5��ݯUw��^��h�<�a�{eS�r��x{��d�F�f}��J�'w�g����0�}Gts(;���wKJ������%��yw����������H�rc�An?��㍚���	e	��k��ݫz]-��B���'�OX1�?�BJ�	R�A�������ϰR~��B�T}\ziﺗ��:E������!����������IЇ�����z��s��V����9�}�}�r�Wq!���4��n����eYB�gEG��|�� �p�C22%�Y�3��%]/��߆�AtfJ�zN�,-�h RZ��'O'��oh
���w�i���Z������W�&��d�5�0�/�:��4Y�%��XןwN�a��!L^@G������#��o���? w�<t7H�����@�I�%�76H��t�1�nֵL�M��#Y�ۓ�c(�½���K辦f@�f�֑.�����Baaq�����|��\�ZۭnV��ʯK�rӋ���B����Q�����g��^��+������3;�K�俥B��K��
=��������&,��:�	�5JgX;�1iI:%D��O��2Q2ۂ*��%�M����J����C@�#�d"O����R�x�2��x����8$���Z�s8vn��&j��*Io������5"����ƫh�!�86`�'�*4?���n�`�d��d�gH��%�NBH˶`G�>JӃBO���!)�� �%7��Vr���BԼ��]U�;��E�0����َQ��f��l��*�]
���� z0T�t�C�a뛺�p����ki��ê��=��t5��u�F�#��zg�lE�<F.�8����3��#V�6�]El����T���P�����SwH�:�C{�` �1�|��Y��3*�Kx H�٘|���S2u�ز�g`�Z��,��|H�O8_~��;��%ǀ	�'��Ĭ�C��%���J>��0ɼY\
�e8mѬ�Kx�xgو!?OV_�Jsg/��d�X�o�Q Z�2`V����Փ�^fS���}��wK@��_�~�,��]�s����k��ޝ׽��%��I<t�q �����<����[�-����R\��W�&��%��2��X�`L�G2��xҞx� �du��X/��}����ꃰu�����]�r:F�d����mEc+
�i{Y��ʺ�HD��yF�_!u)r9�]9!z+��^Cʰ:�ںJL��[?��ȱ4���#���
��;���j-BC�ol�����7�Q�[�ނ�˵c9�ʻ�S��Q��f��-�mT٥#�af�X�� ��&eAL{) �0������a�}�A %�<`��^9�;'l]Ss�O����;4/�<�QBM���O �U����k���vKP��v8L�Q����0�j'f�F��я5[�A?�|,��4���>-?*ˈ*�b�D�U���0@Zy�z�  ����	�7��{k�,��h`� ۘ��Ey���	0��uʌ�]*oqtz�03vn�Q�$���U��$U��5c;��4D����B�[(�r��oq��Jғ������������x�{�)�39�_����Vuw}�Y�V]��]���`xo�v�h�|��cn��4/jg���&i�)j�?ƭ?MC���Ra�����=�YZ)N��$]��b
�v���V �)��t� �Px1�^��"�Zn;�?$�qگx*l'R��w��շ�ԯ7�.F�F����{�*iT!�G�b�t�j<@)�p�4�<�z�<m����������n����cG\x���K�O�?m�>=Β'�e��x�>#�"g��.�[Su��Jj�z�L�P/I�0���xc{��q:JMF=XU ��f`.@��dIyۑy��x`��s��V�G9��|����D���!z� <<Q�1����x��>ḏ���`�a#�p�&K�����7��j�k	�l��d ��Q|��2��\X��Z���+��ƛs>ۉ@��F�}�M�2w�s�ɤNZƊ_�|U��_ӔEÚa�^�7ac�Rά5�T�$�?I|j����̃����i����d*	,>c���r��M�Թ�� ��&���^���$Mm�m��M�!%�� �����S8<Ur��
炧���f������f�挔�187��~~`+J���_k��nf5"�*����ؑ�k�^i����^�נ��fO�N� h��Aӿ���G�Uk��66`'[Z#�y�6��7ӽL��,�h��]�,�c�%��Z^�h0u�� t\�{�GQМ�<c�. �jF��MR�yy|j��1����b���`b�j�������m۲���; (�1�]e�s65"B�N�ȰJ�G�B<�0\��u���Y�=�� 2�K�]j���8pm�q�K ʍ�<�|~�.!���k��P�@C����-�j�%����=��{q��
�3;�+�7�2&N�{���K����'����0��5�Mӱ�B�&���Aq*��W�5q�@(�$�;n ���33'��n�웣e�l�^�uo�u���S_��XD�������J�a�����y�v��ϐD��X�]7��t�m�E�2cS�����c�_�e��+�������4��^��W�k_O50k�PmpP�ꁉ:��(�����ԋק>#d�`HJo�Y cm�?,�~RK!��{h����טa�����?,�!+�XY���W��)�e�rnfI�dUa�t���b�Rޡ�������=-򧾣=|�ğ�J�t�n�����������:��ԪU�\�6��g�K$�����x�۫���?X�//.�!�����o��})4�3����������KK���Ra�F�����4��W�&�?���G`������hA}rd �ԯFNO�Y�~}oְ���� �n>�B���8���!����Ҋ��c����������J������#��� ~�, ^�G8�X���SX����"��� Mx����j�������H,�1򄯍7Yws��@$i���Sݪ��{���5x�1�e�y>�~&w�/�)��G޿Je�F�хr���H7Q��u� $eWCJZ�`�]�𝡨�3�@�=����A$��M��C�8@������1L��[\��]�-&��U��!m�F�o���4��5O4�I��'��?����x�M6���t��B:\���J6��{����S�с@)vK3�w��$b�,ѵ�Y��݀�u�x��Fg�2]�uۃ��[�P�Bf����Y�$M�$M�$M�$M�$M�$�9����8� 0 