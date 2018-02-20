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
� �t�Z �klcI�&ξ�����n�����WCiVR��%�h����=��ˢ�{f�{���y��{��^J����Cb q?�8��m ��������� 	�,8@��ο6�䇓s�qo�}��DI�3���{�NU�:u�ԩS�43;s�)�˭�����>s�"��������J�Hr���ja��\v�0W��)���������>ߐԀ��:t�8�s	u�B�?_XY^�W`������������|�g��"	44���%��%�6��Z's{`GZ�pH���7pSwRя�����K~Jj�~߲]�p�R[�25Mo�n8��9�N
�/���+򠫹n���K�vl�_�vW3[o���3,�e������X6Ys�C�$�z��d�ҝE��g�>����4�����+=��9�FG3�z��	CEs�����e�׏ǰ�P�e��}���{@3�ִ��K\��u����0�kfS'��Ds����4�����\��9��8:|�i��=!Go�C�&�ydؖI�c\r𨒆��m�!+Ԇ�:��wֳ�6�4;Y�1Y��>�a�����,�d~�����B.�J�BȦi���%G��h�<�B&��<k"O��p!�!��0�e�):���ə&P��3��\h�E�'�t��>���wwꕝ��K��z:d�q�e,��:���-���ۑ��*0G]�<Һݹ@�������ݝ�f��[�۫�TJ�����3��j��N�V��E��u`, ��n�ZJ�/o��h�S��p6�6�7��;��jin)�>C�r�Ƀ�zes��q���y)�u{�}xsj�{�d8ͪ�3ss�d�P��Z�T�K)�ٓC�6�R���,<b�9�N�%swR����V�Rٯ�j%��,[�	�iv������R.)S��G���?0�HT!n���<t����H^yk�p�]�e�p�HNR���*ֶ�&�͝��d�U��'�ΑM��g�����F�.IWȇ F�*;���}f��e����%Ϣ*!$݉"vZ9Ypqq����b�E��)1���͎�|N�[�w�&�K1 �~�I����:i���a�M\$ȶfBo�p���OH�?��$�thX0�X�ؒUn�jS��˭��NY>�<���S�n�$G�}�뻙����Y6[b`�,����)}�wa��/�|���F�49�.rjm3�b<�5zT`��/k�S�/,&_�~n��=<�E2�����("�	d]�N@��O`2�m����p�~(��NA슆 �2шi�L���80�%��7&)�AR��lnW�@G�{���@,!����y��^��V�ݏ���^��Z�����~|QsDa��@�sԻ�)֪ԛJ���J�LD�tGk�3 E4���).'��*ąayi͎���6�$J�W����&�G��2������_��q�z��;8�i���w����-K��=�x8�w�=N�*�4�ۖe�a�4�a�{7�O���9>�.�?{,R^P("A�M3�A� p/`�/���Q_��ı�Yrٱ�=�譹�]a�I�2��Kف�B�*t�l�CAg�c���ֳ&��5�=�-��!5�\��!{oZ6�F/#WQ�
�,�Ҿ8.����e���@b 雖K���n!��N	T?��[UO���+��D�����8�K+�#�����'�y�t[�k����~)h?�����ӹ��yd3��2����Y��W���:����ő嫶�洨��V���=0M�_�N�i�z���+�\ˑD�H�ˣ�n�C%���-S�8��h�o�j*0M��ď�?]�����no`�̧�7%b[�0��%�tE�ZG�G2�Q�3?���Y�������L�0�k�m������b`��	*Ɏ5�Ԉ�{G�v-e��|$�yh>7�c�u=F�Kcf�(91�M�z�:�ZG���y��/��=d�n��e�A�+/��h;�\=�{2��ȋ�� ��s�2��ō�}�����DUla?�lAN�|&*WX�S������<4Izm�����'����+x�I���*��sPֵ�H��$)��2�p���_z�T��){���Ԁpv$���m{��r�Ѓ�b�I�<U���30�RI�N� B�L�9̅_��C~�S�c��tJ�ZҤ7"*^�r��޴I;*�1�1��2pۚq!�D����IJ�X1�½t2ɹ`]ҝ'`��t*�j7�4 U�T����8^��󭭻V�V-߷-�~���հ��k6��z'���I��X���^]�Q��L��'� t�4s9��-�a靱H�OdBF2���<P֪
�cz��_��j,&��H��{[��T�ZU]T�2��EgdPн��-��!�� 
S�,J���(��̦����z�%RdN͹�K������$fbz���C]*TAX�m��Y'ӗ^�����B桝&z��b�t�L9��c�!��o�0��-�:����/�,��}]O�"������� `����
��)C�;|���
�Ã�W��30�`\6 �	<�s����6}h:��	<1�40�^ߥ��l��ۮ�;�Rx�p�w���g��>�ȎBF�	�D}W%��(�Ś~v*/��F4~l� >ά��,9;�C?<�Nd���r.����t���`q��5�C^�Ya*�ޠ�}<ADDv�ր\a���/\��/w>p�O�,�~p�9�~(�_�\����%@O{lR&;���+5�>�]^M��6�+�5M2���R��` ����D�;��RyX.(n�n
&��7d�!�P��6bI����ڪ��蟚����al%��K��ʏ?������v���߫>��y�_+���駰C�O��>�|���_݀š���mhJ+x�'�!�_�[-� �|u����~8���?��%/�Ss��q�u�/r8��)��[�Lq�H۪�:O�Wg��J>$ˏ��0�)��8�.�҂�!5J����y�љ��P! �H���IC'��0c$5�1"8�U���B�,;r������]�˕��y�]ŴV�0�X��kW�XŮaJ��5Rm}�Q-ԅ��.��>�_IS��z�N��$���
Z_#��h}A]���W
��~6/?�^)(���S�����$�����T���e&\�b��\�Q�_���R���o.?����4���&�_o�}U�����8���h�n��^��$���r��a�����{7O������4O|;l@¤O�'k>��6��%�̀�Ԇ�kd�{�����H
0�����t�|(�0<�d�"����ۼ��M>)qbJ����֌.�;���S�+��%S٩�,���Nmd�6��E^�!��\���Bv����mU'd�yV�S����]d��<*���7 d��mj�w���q <����ɥ���֍�*5ӻ
�Z�Y]2J��!牼�Pu�d�.e��l{����&b���7��l/0���3���K�t��q��5"�"��%��
T68cм6o�fI��q7��g����	�=z�Aj[]��R�������^3��#2���y��ѫ�����aqX_�E���;h7�JB�x����}��sd��D�ZX[Z)�O�w�ڄ_j`rkQ�#�^J�"�]Ƞ�B[�1q��Ó����seh����4�t�.>�Vd��e���~��M��񰉴r���,���끣#k^���%���\`��M��	���پ�n���1e��H��}|J�>59`��l�tuA�⦎7�B�R�
��'�ҩ�qX�!��w�N*c��dNz�s�9��]y���}�s�C��b��أW�7 ��/���Xx8�dj������-3
d��M��EuJ�3,�����i�_"�5���,�e|��U�t'^�R�_���BS��)����t_�|F��*���^BiV|��CS�Y���W޻Tʬ�[a/�a�qmb�vp��En>>N@{߲\�M[��Q�
H� s�?y���j���g��C��g�Z�sQU��.���l�N	m��'d�&��g������!����#�U-�F �3���s/�`�ֽ��2�^?�=Փ��Os�f��u@/�Ikcw{���>�m�f�t��9��X�K;Ao$௱,��2��j&�fɸ�|�(0-xcc�Y�h'\c>��w�_H��rI�^���B��/8�0�,��i(� ٰ2k���s΃@7(შ@���!w�:.�p�;���\��.�����x� /HڡZ�����'���=M!��[�0�H�\X�_~�_T�C��<~��ǋ3h�����' �����[A��?����+V�:6�@��?6`�5`G��x�VoeR��D����#�D�����!ik�SK:�c.>Os9y�\�tn*��Ɣ� �c$`�)�&����1�:	�O$�A�Z�?W�W�=������+S�ϫHS��k���&�W���u��k�����G���ɭ)y��/���A,rYW�"4-���w�Cϳ}>5(���f��2�7ֻ앚�|��=z��5v�X�Ę�c��य'?�V�Jų���v�L��c]N'�s]�'����t��J���1�ɮ��E���֞Zо��.�I��oK�u�K�#8Q�Zesgc��]�9(oMmr�A���M��o��&��1�ɝ��Nmrӯ�M�X&�S�ܩQ���r�l6ʝ�75��ӾQƴ����Һ��zo�zf�.l��*��*�l'��rj5�8��Z���V��xnL�Q��_rQq.�~dslٗ|��b]��uQ+.��V<%��o�֋�9��t-��#r��ωIU�ɝ����j�ӝ]I��0���ݪ�/`�g<MϽ����EZ�^y�Ӈ{�Z(�UZ�J�QJ�wq+A�9�V1��߄���UB}�A�U�9��_��h`x4���n�UYn!��vij=L.jǩo�����B�8���::���]T[eNI�(3D�c �Y�J\�o7�z�>^xEQ���㉓7nb*��)�a���8#;�Rm�T(�jLsQ�T�D�߮����<4��0��b��f���n����y8���.��q�_�m����}r7��#�&��p�}�D�0�	��SE����e�&s���Fw���A��'w�K�i�=��d���F+�QX��[����-��EN�3�eP�k9�A�hc��?��"�<��p@�.\C�45(A�t>L���-�ׁ�#(k�e>�R<���Q��]�p���1N]B�Sd����#i;zf �>���Ǝ%w�������3a)�ы�;"�τL�y��gH�mj�Z&4���=5��1��;�+�V�����[+,�$�_^]��������g歙�m�Ivk�3�����M�W����;���@���7Z����d�~{f�� �g�~��g���0��g�j�7�����|=�i�
��������,��-��'��h����fK13���s����?�WBh�gR"
]R����j�������Ǖ�������Y��w?�r����{�x��������[ ��-��.���z(���x\����1pX\��9[V�nG�A�mݭ#T�6��	����k�L�� �'�G�m�y���ZM�ጩm���RڑW	�jX.9ѽ�2�.r=�ǻ�G\�_�!�f��&���ǼN�R�_~���X*�>=�c77RTՔR��]���m(�\� �'��JYk���.��z[�f5c}kw��%�n�<{����r�>���Jp�%Z��,���|!S��3˙\(����C23U�~��#7�Rl����ΰ�<$5QC'=+y����z�maN��i2EDI~��{9S�<F�X<�F����f�AR�
��OR��Y�mRx��S�*-�����4e�(C�y�&";K���dFfW����T�iңc��XD`[��(D�V�O��}�#�}�=�i2�CL	�?o8L��7��`]��|�4�J��j$�� V&g ��h�ᩭbK�{ ��OA���Wh��Cs[iU`R��U��_�xr�J!U�I�QYT�}?ce_hGC-�]�D����r���������ufDD7x#�2�mN4�РMd����랐��X������
�=;�,�:P{���U<����fd9/�
�>�ߨVPsϿR��kn�ɌG�&5`!S�ҭ6�6EY@?�1�f�uw`�$���M(���p��{Q���k�8R�����\��aD��P�'bB^'{像�`�аW�-C�v�:B7\C���)Iw��5�ϫk�G�J��ǩdㅬ�s�O_8,B���, ��&R6���w�@	4�d�Yt��iD^@�L�E$�AaN��P��I�������5˃��Qߘ��Ohy�Mݔ������S���C�6�H�Ğ͋d	a���F�M_Y�	;��5"~����,�wv�~�qXL�m��J%7����h^����!t)l:��a�c�] qN��(Qϟ|��c��k|֡��sϹE�,�
(JW'҉.�T�!	f$���/�O(f�)��̡d|)���H� ���BN%'k3��(L�\���r5`X{v�����Z����ג��hsE�y�@��'�TȈ1�Z�\�,��+������J坁u:d�K�0h�
C0��h5�MEq-�"6��Q���A ��(�+b���diN&�wl�f�/�N�R�LA"	F�m�xָJUiSk\�o"O�c�/<@wg��8z;;����&Mc��.��Z��4�UG���x�c���,��(nK1�U�FFS�Bc�.k�Y��.��]������j�[u�oXT�!�oǿ��a"�����^ �6� g;�T �Z�e�y��K����zr�%����2xbD�R��ق)�2�3�y\?�49��J�Q!��x��g-�Z�������F��d�,���J]�z��zT1*�QF5?�����o4�'����
I0�ř�e�6�Pw��ƞ��u�9�$�L$��?��j.'���`���EЎ�b�;�J��F�5rvX	�;�"�I.�ekͮ^���h@,Ӆz�(��v3}��@�"{1���>oŃd�f=d�[�cl����Pi6�$c�u�B Rž�vH�5�xVu8�V��G����
�������Y��V({�ZYGf��P�}ɴ���{�����L�0�A?̌e>�6��|����v��<�ݮAғ&?AT�|:@��EW
HiI���~F��*���`b��o=��)�#D����*~�+�S�ë2�t^�;_\T��PA������}`�È�\�y����� `錤�*��a��d���C�M��w�~-�_������C�m�[����8!YȄX>埈m�;����T�Niΐ�%>��.�)��`����!�y����9Ø�%�a��<|ϣ�sw�w�b�}	���m� (���K��u/$�]L�;��w)/�x��j�ڣ�,���8Ё�ӷ�)�$
��^���t�9���z�Д��^Y��vXE%C���.�N�$Q�^�Q��Z���ʅǈv�*�4������͐���*)����d����
�^��qw���2`P��P��<yT��cހK���И��ZoƔ�Ygبw�6�cP"G4�i��0bR=T:�M2����ߠF��M�e���g�������E<��夛��4*lu����B�1N���W��}LonN�6.8*5�.�J�h�:)��&��3r$Y26G:�6�k�z�Y��p��/��)�;a�UzK��:�j�T@"RIi�I���<'��/��~tF���yW�Wc�ґ|)�B���W����^�'��xyP�2D�"�
�.B��@^Yy�����1��DP}���<�bu��VX���C+{M�#I_���\�ҹF���E��6�8ǡ��"uG�WO��DY�AR�@�l�����uJ?���K���������ܷq�Q��
m�\+��\-7�߽���-nJ藨������r�B��h��˄/'>�&9�TR(7|�՝G���!�a�`w�z�/�P��<��S��J~!�y��g$��d\t���"*";>dWTJRv������j�����2.��<�]�Z!g��G�����yz�͇�)])�{�`M�QJHχ�
��TpU.���ڂ�ĵ�Yy��PV�<� ��(��<*;�����\�.s��5@�>?�[�t��Ӹ���Ѯ�;q:��\�(B[�`�G�ޱIPU������e�f��Tu�/����{ � &NH5⭟p�m����/G��YћG�1`[e��Ȣ-]l�"��Jw�oG�z3��6�I�١^��~H�J%ը��o M�B �Ѽwy��$���f�s�J�S�"h�-r2wK�)��Uj1s�ZO��蝅X�c����`�O��(/�7�>����=�S�w��?�HEh��^�NO00�<�Gx<�`͡T��X\��/�Z�'����6�-�K}�]ƹ%�\�y-C�X���z�\b�m�hf�׃��;B�ǐ�Gm�癆�.x�;���͆I�I������+*���
\#`I��7:t���]<��ZiN���5(PhBMڰz=��fV�S�<K�|�:���u��4�.1�'Q�����>F��ٳ���i���6;K��k&rVͅ�-�n��(ع��� �h[�I�3�[�1���󑐒7�ǒ��,]��6�n�����\F.�Az�2�v��V6��}I�Ji�C[p�n�)���3e9��f�]&���D�#�
�?˔{�u�}m�$/��x�s;>�D;x#�COrpj� M@4��0t��e��oP�x��9p�a�2�R��ekv���p�����&8��'��.�~�l��>>�4>Ի>{&UF\ rfq$�C
	5������.������R��WR�@�������/Y�c�Z7�؊��X�2X�������#Wt1#lS?V$�8_��i�v�?�E��a۲���x)Wr*��C?#
D[��(�($N�F�#��V�X�(:q��(�vq�<�' $�8Z�U��`�ka��BQ�/���+5� UX�K�����
�$5��MG�+���p��N��O��΃��ձ�سt'y�0e#���ռ�.��Hw���h<���~k�V{�,r'MY��@��u�!=��[����k�u_��߃�}s�����g��~d�"A��[KA��֚;?Eq�z�~Y!P���4��0��:��|�^ ����FPA�Ļ:2b(!!��y��.cM`R�>3��'�y����e�)nW`��W�^�B4�I�ۃ�=*s��soq<L����Dx.x-*�J�]��tZ2F�,����b �PAq�qlԄo�g�-t�cc���D�K)�~t3��ǺÞ_:�o�A�K��߱���s.̌s��3�;Qa���zO��#:WI���#�E��h�z��")5z]v���1��S۾h�&ךJ�����C�HN�d�!��
���ؼnSr��0\�UR�՝i��;9m�ܖ�Ö��& kT���=�G��Bϭ���;8<�}�P?,���_��f� ��C�Xw(#P�']��v���[���Ҟ�#��f�ga�W���\��m�x�]�߂�iuw�f���Y(�Y����ΞҐ ?��3YvأTP��2�7��<���]c�]�,,2c8�C_u�j�W4b�n"]P���bz��0!>���dwY����|��*�k�ZǨ��/?�\��ŵ\>O�K��<CV.�U<}���7uO �ԝ�%�q��_.N��jR�j^��{�Y����~e%?��H8���re���.���j�7��kkr�':�˹�4�˕�Y���A���*T�KDPb��6�����S���@(miv��R\P3z�.��P�K�ֆ�g��\����Е;ulG7�}���<O0������!�.��hw�<�֡6P��������n*v��7�E���5z�~�p�!����?����sqzh�B{܅�-�O��Y I��Kͅi��7jk1ⱆ��6]�߰��ص�3CӀM�����+h�4*x��O����/o,�L0`vϲ�N��c4�՚���M�ֺt��B���c]]�D&��#���0o��
ӝ;^��;w8Z���W&q�Yy�Ri�&�^�@VGv\����8�(�j���g�%�44ID-i��]�F2>F�1x4���T����$�_ΐM���6\W7� �LbF��3�Q�2���h����_�Va+4�
6��Sg4���o�6tl���l��SC3�'��dk�������PM��kL:<�	�N͚#ǉ�]�,�����s�3���>ۊ㩑���po>��~X�`X3�1N�D�[Z��h�`��Y�6^��_��W4 ;t����&K����r�g$;��N�j+���;IT������z��^xo}�=�f� �*���:$EqF���Y3��0��
28��c�N��+�����RTC��;G��o�|(]x����G���P���"�����7��#T1$����lhE#Z�����3Yp1�S����Q�����&�]`D�n�j飠p*C�/yv���Ke:�����BU�jT�T����|c� u��u#�b��t��ԑqs��ѿ�UE�U��`�����������w���m����H4&�
L��nƏqu��xE�Ƕ�3
e�ߠ�G�=է���Ɏ^U�#�X���Ԩ#��Y�&'�N�jt�Q��r�1����"��^���Q�iDo�bMtٞ�juu��u_���A��6]'�I���Ck�?�E2�ܔ�f��FE30�>�k�;P��=�>���gʥw�p�D'�i'\����|�0J��K����Y�� ��sdu��.��n�K��`��,���csx�8×"�;�2$J����:4$��#�s�DL~��0�p	�@fzԢ�p��K�
��j=�[_)��V�&��3�LNH$���Kl���#Z�!�	�F�k�/�؇z_�Hz(�������pb����@D]jf �4Lɰ�Q����g�]3�d����*�-��#˅n��:}��� ���j�F�1~�VJ3<�(]�����ކ��Ub�X��>�Q��)`ǦAʲ_���3�er��ja(������A����	@�C����u'��lh1S�SXH�~��@��
:��`�Kxc���R��bT�078GţgSt�1�Qt������3���62+��y�چ��r/B \�oG;N~A�
��?�"h� ��X��iM� F���|0�w��z�V8%�f� ?aT =���yqR97L�)BR9JHbh(�'NUz�-�ӈ�4�@P�k4�I��٤�J��^��ߴE��&0�LK~�A���G]�I���m�H��@J�x�>X\�L�$t(��!�����+�G��M=�^0X���  [��C3�X���q��o@6å��R�΄t?��Ɵ�5Q����<��g�J��X!)L`ê�I�M	����l� �P�h���I��� r'� ��.�ZT'O}*��� �3Y�����Ѿ�급��7�f\t̀���jzy@\MD�c�I�l�R"uaD��MS�������P�/�^߹�<F�H����^�D����Ӟ�����+t�F����C��T�6=r_̴xd��A܎���v���.IP=���ϥ�9�%�	�w2�̫�Ŗ|�lT������^t�O��S̪rGVP\t�$ɘ�h�]�1�N($�ؓg�F��cȦ����G̒Q���΢�XIe��.�͎���L1��w��5�#-Tv�i��e?gje�%+���+ƼՁ3��4����d-Z6=�(���t���#�t��5�e`�r�.4�]�y�I����*���Nb�@x�'��jqhƼC�� �O,1�x
.��>��a�B��ː]/V.���lt��2��#㈪%����p!qd"�օ)n27��r6;Js��-	���upT�uhX3Dq��z�C�S�怟=3M�b.!/����$��(H�HEg����a�K^�`F�}���=��G�"�,6s b�����q��.L�;#�-SºJ��"����4��7+3�C|���Sm)�L�A��V��w���y��ny��?�a��'�
a�c|����bUD����!8��Fs��� x
/����~���� m>e��9@N9��Ņ�ڛ�E�v��̶�ʐ-�w�:w��yJH\�Ћ���*�~�Ð��<��
&pf��2�>��S(.98��c݄:���M6��jϪG:�L�U�2ֆ��!�&��͜.t��v�e�K#�7T�����4���p҂
��4q$Fb+ԷЭ��Q��zf������=��E�k��n��|��WlQ�H�FD+
^�L^���k.�&+j�&���s�ZY�Rʃ3d�b�na({4;t�O���uv��V��#���/\[eqg�BU����$��2j������7Շ�в�1z��\�Ȑ�g��2B��!��k�������E�:�g/�b���Τ3��?/R�|x�!=�M4ؚI�.�y���8�䗆7rh�Pt�THT�R��%E�$˻�d�2)ѡ��50]&�P�=���L&�F��\��SO����Yx� W��Y����U1��,����|��Oe<܉�=>�6d�b�6��f���25n�)�:�D�u�(+ w�Flo|�%]�X���{�_�� ��;=�~��6#I�r2~{9[P[�
��D�D�)���5W����J�!3T��-�߬R|!W�f���Uŧ��U��Y�vsQ�;W��t��l�Y�r����Ve�>%~4DhL��~��I"�4O�./A�P����~�J%��ȃ`�~�l៷y�J>�<(d�Y"��#�uj\,�|�S&T�S�hw��!�(6e�Ŭ(��_Yj�#ƕ�"ia�R�m�P���ڂ��vys'�Cgn�B=?_��+!��c$!F��

�a�(��0�H�#H ��S0Ջ���ͨ6@Eq���*��R�1����m%��G.����ʁ�K���5^�t���ߠx�~Cw���L�Md���hXG:�D�X&#�Mf�h��#�q�6��U 4^�u0vu�簙�j`,|P�� 	x�S��Tف*^
�>����7^D�^�R�2�w�k�h�<@��Q�|��hp��Q�����@�%��z��a��(Fa��Ϡ�#ų�yŃ�LQv��W?SZN��F�;�A�gE=E�r\T-)��O���G
VS+��vd�>_��n��:; @|R������]�B��;�Y�5ǀ�.ӵ���,T�0Lvpi��Tr�N�Drh�CGW�S=���k���!��jZ�he��*�Z��]<���0cњ4^3�(P��*T(s0�Ì!�ލ��+���-��wざ�Pj��!�~ixҬ��4>����A��&���~�?@�Mî�Ш0��ʏ���+"����|��pn���GR"�DDWϯ�9��p�i<f����ph�B5��?Jb�b�I���0���XU����UI�.r�ae�X���������U�"Xx�m�z��1�n��J+����z��Q����=�t4��vB�T�Hc���;�Pw��h��XxJ?��zlc�⢵�Eg	 ���4��*$h��w-:��wֳYlh�M3�{Y�A,͂�9pӴ��]\O&�'Ua���P$ �ޱ��g{�eY��3h���>=C�,Z���2�x0��	J�)<�a�Zd`��*0P�>,Q�ȼDą�B&�!�[`)'�j�c�"��!�K>��A뎏�3���v�W�d�67�;�j�������рnr��Ӹ�?�+��B�@��N�\I�2��t���˫y>�k���
�qm���j��;�x�95Go�+����:��8X�MI����6�(�V0��է��OI��I�*�E(S��6�*���p���K�=`7�AWs݆=h��H�/u]�L�Ѩ�Ȱ�2ˀ���_s�C�K��,�0�����,Ö��\�\��t�e�^�-�q7�]��649�Dd�,˾~d�:�"^�lJ�1zj�-n�}2v�rA��5JFB�2�ۺ��G�puN�<�!��@�H��A?��ڱ��������Z��˯��	́�LN�.\�L�iq*`~^h�`BS�=�8P?K����"N==`葰� 
�;A���[��!'�x�����˽}��=�C<����g�)��+f�V�����&T�`&�ѱ/K5����&�Z��ӷ��,.��/���;�Bs�Y�c�0�Ą�f_H���t�����r��Fa��$��cPj�L=�����/f��Ŷ9p��񠩗?��)�����R��3	*?|�_Z�FE:b9@��?�t7�\��,�>o����=��Y�׎e�X�\7P�jׇ������aJ�����P�x�q��X, �|i�	n�8a�w��8:U<d&�M?���w��mՄ#M݄��%�1B��V��� ��p�Ẉ�ϩ��[����[33�Z����g�೙�� �~����3����>��%�5�w;�%�?�1Ht�g� u�� ^L�ݫaF�o�����_r�~NSd
\ƽ�:F�����Z`�/�M��դ���_����i�l�z��>�V,n��jg��$��6�-BX��w��NP3�:�gc&W��x��m���e+^5�	��"�kܾ���+ésb��6����Gx{i��7j�����GO;�O���I ��32/r6[�@�'��:�"��%�F�����&�&��P��f��~�Nd^)C7ڄ�9����@���+�,�g �@�|"xx,6��c�D/�bt'9/�!l$��eI�P�����S-�r-��
)�~Fm^b pC�p��Y�A��x�׿D�^�Ύ�g;�: �w�ǥ7i��E�V`�2V�����<���,�s�X �G��A��C�ګ�$�!F�lYI����sF���9(N W*ٲL�_.G0����\`��������ҷ)�#���x="�ۥ����O�\8�¹0��|��ft�:h�э���)wsxn6!���V���_k�X���Y�L�<v�a��/�{X��V�=����w�FH�G��-�����F7Hf�ͯ��t/S�4�/Z$s&K��ZvI���!L�{o3 ]��9�Q4�˳Ϙ�C�����$���ǧ��x�q5�}a�VrÉ!�����يS�0�����@2��8g��ې	G�U�?2Bq�\�ᡊb1�xD1>@�Ҽb
�N;0B�������f��k��P�BG��Z��j�%�>�6k��{a0L�i��Rn�3�]oc�%����'�Y-�gJzM�A{TlE��i:M����C3�T���u�B����-���û3��h�e��l�6�:���.痗��"��WV�צ��+I��������ۍ��s�"S�����1b���B��M��U����z����ӯ�X������rSu���𦫃�R/^����Yv��^��8".����a)�2Z�	��{Y��5f��_,,����y\;s��Zq*�_Ib�%��
��Y���<�]���_P{{0C�����=-�e��OW��}i�.ޭb�o�����^����R�V	��^�NΞu.���e=����������"���އ� ��ٻO"E�V�l������O�?W֦��J���ǵ���2xS%�� т����LVR�9=9a����YǪ��'���|\�*�]Gn��� ��r�<��[,N��^E��9�]�y�em:�W��8�Wǘ���"�E�o�1L��*R �ӥ�q�����/L��*�������4ׄ���˯�?�Aq����4����v������$�������L�����?j���\18��k�������7h�a^��3���?���Jo���P�`��m�kM�ןt��i��i��i��i")�>nܺ�fL�4M�k��?����C������ߔ��柄~�?��}&x����7���y�����C�əV�o>��ߡ$��"A��Gg��4M��*����3�{F�����o�����U��nsf�������N�}k��~G�Og+{o͘3���Z�wn�K����z&T^�?�}D�߀��3�Ʊ�ot-���ۍ~�p�\�H���o~��߹q�ƭ�ƳZ�:����4�	��������w���Џ�oC����Y�>6̖u|��-����͛7n�o����|q��_8]"/���Kdu�xzz���͗6�;������%��g~70���⏤7����[�����(�}3y�����֧�;��۷���w��@�!r���o6-s�֏�Ï�ф7�mj]u���n�f|�r7m��ݳM}>��9�]��g�p,�ݠ�>3 >��=�c�&p����7������-�k����wo�{�~�����R��?<6Zn�s�i�&�:� ��0l�}�o��������~����O�~;�[@�l�0~=0ܓ۳7n�:�y{���?��/�m[-L��y����o�x��7�W��o�w����x��[��v�&}��޺u�(�s�=Y.�z�aWk��ۭ�7��޿��cn|t�S��t��۟�`�wK7Y���x�z��߾�K���v��	����?�Vm޸�9�)�Zz�w�n�����b�#����k��3��{3���r�?s2�gf�ř�2�7g�h�ߛ�Og���~������8�f����s��I$�I|7�D*1�x7��D6�Kˉ���O�&'~���D'a$��q�$�e�e�O%��Ŀ����?���%�W-���v�+�$�������E�L������_/�%�������o}�-��|KP��J�o��B�|n��ch��͏?����-������'���Ȼw2���yn�"e2���ȋ�� +6���q�!��_�@j�������~��wR?��m����O�r�v��M��g���-x��o�~R�	�����[k7��o��]���M�������V����oS@�[�n��\�9�h���5����= ��w��K|+�L|/�I,$2��w?O�Kl$����^b?QK$�%�	-�H4݄��}J����?���:�g�l�h�R�_N�+�5�'����H���x�} ��(�'� ��6�� �n�����|R���w������V�uQ�ҢvT�ͮe�g���͙�LkƘ9T��o���.b��ޅ�W�]��z�Y3m���L /�߼�3�-�9C-����i��i��i���M�� ���Ɵ�O�4M�W8%�Y�U��x����v�~%
�?x�-�g�I�ks0��O��_����4}m�o�{y�@ǿ�������?+++��W�����̴.��~�C�N��*�d�/��h#���s�5������R��_)���$ͪ�����Q�IG�m�^�x�<AT�ac7ɳ0�����&��a��!���"��A�@�m[�9��^�����]�CwVٌ��?�޾D��G]�w��s?r"��Z��ũd�NI^�S�DR)�����A&�J+#�ʹ�D�7z��i�ٱH��������D�LڦȒ�,�/9E��gc����~
�8��n�0�ғ#�|M�r�&�墛�Ig_�a�����$���F����-�����_�P���W�B��>���^�2�:F���E��1O��0��Z�0��y%iR>����6�C[s\{�t��9�HM������|�ݱ(~��ؔ�A?l��e�L�p�t�Vc.�]K�V��%=|�E:J������Je��39�3�`o�@��ĭ�6�8�NچKl�=�a֨�.��C����7�G�v��>���Rv+��wj�ѣ�ˑ�H���Es�� ���2<o��������N}��]�_")��^��K-
 }�� �����YV�ɾ�ȻDj�b�F/�����h��B*���1J��S����tE�a�k�-�|�/?��]\wXه��><� ]͔�p��^�oe�V{��_�L�oc��}��J�'�:���� �}O�9���%��>v���D07G�_ࡏ�H��??��D�1���j��jb��'�%�'��[w��Z��R���''����a��Rd�T�2� bjG�\>~F��V
���`�ທ��:E���M���������T���4�q�A?�X_�[�AxN{��B��2���ڠ`�c��#n�3�ܕF� �-����,A����h�ϳ��sDF��##�qG3���%��07菞��Li[��/6���M@J+�����T��5M����.�4���C�quu���J�t�����F���`��ԄI�;����r8�v	�0�����H��&[9p����/�c��?���h�I���í-��!��[-�쐻wI�������p����%����=�l�:ҥv}H�-����K+K��B����~u��sP~]��M/�����q���f��Yv���u%����ԩ�:㰃���1J�[)���R̯��?j�7��.?Ml�b��3� ^�t������3PB��$i-%�-���\��d�L�ȭe }�bI$y��dN��ě� �H�<l��@��L��9'��^����C-��@G%�M�S��� N�F���*Z�dcZ�'�*4?���ns
��=�X̐r������m�
��}
�����5�C<R��,Kn&9���d���y#���w-�4�a:�EǱ�,�w�fTv)|V2����P�.�*���޷t��u������GUSC{L*�i�@�N�8� m��ي	
x�\`?p.DO)�g�}�G��m$���zWg!��5`ǡf+����u���@�@�lw�	2�gɊΨ�_�A�D���c�t����ǖ�<����d�����C�|�����I_/9Lp=�gl%&f%�,Y<<[�1�I���RP,�i�f�_�{�;����d��ޤ4w��YJv�����*f���A�Y}��livkw��n	����'�B�Q�➻�t]#��pt^��~���"&9��	�!��W�<��Zn9����Zqy*�]E��������,{c5�1�?�4��y����&0%�g|ɰp^h�`B�k ��	^.t���vm���M���bS�5�a��PhNǻ����{5P֝w@"b�[0� �8�
��K��)8��	��u�R��y��U�`���z��#���@�Ҏ4�K+�j�"(<l�����N��U�xX;����E�`sw�
,מ��K��p/���f��/olU٥#�af�X��`;�Mʒ�.b) �0������a�}�a �y�*�r�wNػ��jK�"oI=�w<hs;��R�D�����dm!��Ƨ�D�%�\o;&�(�
ZR�18
���l�h����f�2��ۏ�s�Ʋ�'�Ge��
�/��a�cUo�>Ѕ�Aޤ�)Ȧ�ur��(����x(r�>X(�6f�bQ��xa�z�z�2#��[��+�L��~9��~m�1I��9C���$�6������
���[^���W��Twl�T�%�u��^gǻ��L)�ɱ��OTw���ϒ�����̓�����Vk�G����猹�x�P�:��$7M�NQ��	n�i1��V
kl�_(������Zqj�{%���SS��fGh�l��bLW��� �,"�U�CQ�C���O��Dj�.����{�������Hv�x��Q%�*��Z̑�V��g(��`.�f�G��ӧډ�j/�<*�i݁>���|i��ࣧ����Y򄹬��gd^�l�:%x�o�N�7ZI-W��̤�����号v7�[���d4�U@�`��M����W�Ѝ{;��i5�&Z�_e��)�$x/v�^9 ��F�{L���߬�sl���!l$��eI�P�����S-�r-��������q X�0 �t[���|I��xsN�g;�: �w�ǥ7i����E'�:i+~q�ei�~MSk�9	,��P���K9���P����$񩁚?������i����d*	,>g���r��-�Թ�� �����^���$Mm�m��M�!%��@�9�]J.�N�\�TɅ�+��B./�щ�T��F76�7g����ل��[QPFG��5b��jDfU2I��ؑ��v�4��]z/��P�갧L�ZG�xo����w���jkX���dK�3��W�f��)S��-����iu-��\���ί��k{��(
���فg�݁Ƹ��%i�r^�Z<&�!�Հ�Y�C,��NY���|��~��m[�T���g ����Cq�áFDh�)@Vi��P���5<T��A����#�A�4�yi�G����c9.u	@��������%��<<rmX�]�H8C��CRM��[?q��/�4Sazn�q�~s�*�����1�����Ѭ���0��5����B�&���Aq*�<ܬ�k��
PPI�ܪ���;3� �.�����e�l�^�uo�u����S_��\D�������J�a���Z�<d;E�gH��Vo+V`���i�h����{����G�X[�1���˅�*������t�_E���W�+ϵ���up�68�
F��T|�&����ԋק>#d�`PJo�Y G��6��>,�~RK!��{h����טQ�����?��!+�X[���W�f)�e�rnfI�d]a�t���b�Rޣ�������=-򧾣=|��K�t�n������������&��ԪU�\Զ��g�K$�����|�������_ϯ.��!���>��o��})4�3�J�~���A�������y��
K#��XY[����H���r�#0��X�?�H��>�2���ԯFNONX�~}oֱ���� �n>�B�]�O�Ȉ�yee����RD�muyj�y%i��C��E�ɩ?]��N?�<x�V�p9�?���r=�D^ Yq2FM�2�s���=A���"�n.��$��v��;�Zݻ�XJ�Y�W�_���3�er�|��M��?���P*�4[�.����G����4Rv�1�����1���:#m$�3ț�D���2)�FI;�&R�(�Ony9��w-�R��W�����fU5�|xc5�����y�9�L��=Q��A-��ţo�(l5K�>��t�?,��l5׉�0i5ЧT�?�R�f
��XIĦY�k���	9��p�@M��e� ��yO�`����^�	�u��i��i��i��i��i��i�p����T 0 