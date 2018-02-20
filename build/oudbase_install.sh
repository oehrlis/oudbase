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
� ��Z �klcI�&ξ�����n�����WCiVR��%�h����=��ˢ�{f�{���y��{��^J����Cb q?�8��m ��������� 	�,8@��ο6�䇓s�qo�}��DI�3���{�NU�:u�ԩS�43;s�)�˭�����>s�"��������J�Hr���ja��\v�0W��)���������>ߐԀ��:t�8�s	u�B�?_XY^�W`������������|�g��"	44���%��%�6��Z's{`GZ�pH���7pSwRя�����K~Jj�~߲]�p�R[�25Mo�n8��9�N
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
H� s�?y���j���g��C��g�Z�sQU��.���l�N	m��'d�&��g������!����#�U-�F �3���s/�`�ֽ��2�^?�=Փ��Os�f��u@/�Ikcw{���>�m�f�t��9��X�K;Ao$௱,��2��j&�fɸ�|�(0-xcc�Y�h'\c>��w�_H��rI�^���B��/8�0�,��i(� ٰ2k���s΃@7(შ@���!w�:.�p�;���\��.�����x� /HڡZ�����'���=M!��[�0�H�\X�_~�_T�C��<~��ǋ3h�����' �����[A��?����+V�:6�@��?6`�5`G��x�VoeR��D����#�D�����!ik�SK:�c.>Os9y�\�tn*��Ɣ� �c$`�)�&����1�:	�O$�A�Z�?W�W�=������+S�ϫHS��k���&�W���u��k�����G���ɭ)y��/���A,rYW�"4-���w�Cϳ}>5(���f��2�7ֻ앚�|��=z��5v�X�Ę�c��य'?�V�Jų���v�L��c]N'�s]�'����t��J���1�ɮ��E���֞Zо��.�I��oK�u�K�#8Q�Zesgc��]�9(oMmr�A���M��o��&��1�ɝ��Nmrӯ�M�X&�S�ܩQ���r�l6ʝ�75��ӾQƴ����Һ��zo�zf�.l��*��*�l'��rj5�8��Z���V��xnL�Q��_rQq.�~dslٗ|��b]��uQ+.��V<%��o�֋�9��t-��#r��ωIU�ɝ����j�ӝ]I��0���ݪ�/`�g<MϽ����EZ�^y�Ӈ{�Z(�UZ�J�QJ�wq+A�9�V1��߄���UB}�A�U�9��_��h`x4���n�UYn!��vij=L.jǩo�����B�8���::���]T[eNI�(3D�c �Y�J\�o7�z�>^xEQ���㉓7nb*��)�a���8#;�Rm�T(�jLsQ�T�D�߮����<4��0��b��f���n����y8���.��q�_�m����}r7��#�&��p�}�D�0�	��SE����e�&s���Fw���A��'w�K�i�=��d���F+�QX��[����-��EN�3�eP�k9�A�hc��?��"�<��p@�.\C�45(A�t>L���-�ׁ�#(k�e>�R<���Q��]�p���1N]B�Sd����#i;zf �>���Ǝ%w�������3a)�ы�;"�τL�y��gH�mj�Z&4���=5��1��;�+�V������k�$�_^-���W�����̼53��5�n�|&X>��	�
���~'�=����>�FK�_��{�,���o��������w�LWs\4 ƽ��^���&����㘯�5m\u��u���}4��y����$�m�]}�l�/ff� ��_`�������g�J��LJD�K�c��_Yͭ����:��W���?����g��&��`�)z�	�"��s#Ntz�2n��·@Z����~"���q�����aq���lY��yC��u��P��&d�S0V�}2as�x�i���5�3�Gh5��3���G̶>HiG^%h�a��D�B gȄ�����q�~�����.{�8;�~�:�J�~���c����؎��HQUSJ��w�R&��Ts)g�<�tV+e�m�+���S�mY8�Ռ��ݍ򖜋������Vn�9��^�+�aG�h�³���L!��,gr������T��U���|PJ�IW�g8�R�Pp��DE������/��ɷ�9MJ��%�}v��L���c�p�C��CI�+X<+<I��fu�I�1N5�h���N��ҔA�N����,a.`��]=���S��uH���b�m�&�9Z�?�f����������
0q$h���0��8��uu��-0��L+)���p�s4 X�����������-A�4 �B�?}��_�A�*�m�U�I-wW��~���E+U�T�'�GeQ�����}�i�8w�5z�.�U6�����י5�����ʔ�9�p�'B�6�5t�6��{B�b��>G/(��쌲Do�@�Mj<lzW��zs@����+��p�ZA�=�Ju���]&3�Ԁ�PL�K��T�e�4�����݁m�|0��7�P���R�edDe�"��V�H�jz�k ?su��U�?C鞈5x��>F��C�v\��,]xl��a��pEYNZ�$��֌>���U+ut�������>}�85�O�����HٰΫ��	�m$�l��f�§yE2��TT�9�*_@�r&a�B<LD�c��ph,FU|c��>��L6uSV�SZ�OIĺ�=�<"�{6/�%�q���6|e�'�T������Z��Oh�L�	�-�m�}`]0}�=R+���G�wأyMT|����4�i8p����Æ��w�9-#�D=�M��,��Y�.��=�u�,+�(]�H'��R9�$���2j0��?�����Fd2����#X,"�
589����<'��1mr�r�Հa�ٍj/h'�k��^K�������R!#��j�jpQ�����؃*��+�w��%/�à�'*�l(��ALԈ7ŵ8����6F���\ԖW����r��9�xxܱ���D;!J�S2�$y�(�Y�*UI�M�qyO��<
���;� ݝ������v^:�4�Q��4�kY�WI�3��A�G�L�ʣ�-��VM�
�uP�պ��g+�gtt�W�cJ'��n��aQa.��������|T�#3�{Pl�xn���{P4jU�!�)~.�n����Ż��vJ<�����uK��>,dN��3.ȸ΄�q����n*�G�8>��C���k}>/[����N���X�ǖG+uu�ɶ�QŨG���?�38c��x��j+$� g�x�e��A��F{n���璐2��2��窹�x.N\؂�BA;:�!�,*�v`e
7���a%d��2�4&m���5�z�j:��Lꁣ�����5��e���H7(&���ٛ��9kl����s>�C�٘��]�y
�H���!��3�eX���[���CNJ�*Зrd֚��g��j[��eje��n�C�%�j^Lد��Ob�/�3��03��0g� 3�m�7��1C�`v�IO��Q]�� �K]) �Q$~��R� {��1���:�t�9��ǧ��}�p�O5�:�\�y��|qQw~@N��[��#�r5���7�v@���3����ۆ���w�+y7�/��U������2�q�XnA@��2�z�d!b��"���"NS1;�9Cږ�t��D��c�98C��^�t��zVܷ�c�4����=�j�݁����%4�W�i���rz.i�_ֽ��w1I�\r�����%3��k�B�4Z6<�@:N�b��(��GBx$z*ҕ���NL�CS�{e�.�a��8.��;9�D{�F9w_h6��*#ځ�@�L�[cgd�4C��:��`����vO��C*{	&���CnCȀA%tXB	&��QmxP8��y.U���CcN\&k�SVg�a����d�A���1jÈI�P�6�|�nb�~�37m�iR��]��r.۟-�䣖�n�Ө��MF�I�OT�8Qs�N^	��1��9�ڸ��X��*a�ꤼ/�$V�ȑd5�����l�E�1fO�J����x��V�-Yj� �!S�H%A��"$Ip���'�����yAxb.�]]^��KG��
y�{_�{~�{1�����A���T*��).ye�E��B��^Ĩ.�A�E��b�X���m��[au��p�5��x$}�K��s�bH�q�cw�|�`����]^=їe�Ie�ͧO��)��{t�.Q�G[�s*ZRr�ƕF�V+�	r���s�܄Z|�n\�÷�)�_�ʮ�w#�v�	
�"�e�/�� �D���\�RI����Vw]�N��ć���m��E�l�J@A��4�O�B*!����B���J�q�ųS�����<�]Q)Iٕ�(�[Z����˸`7��@v�j��]z]B�oK���y(6.�t���݂5I,F)!=RDt*X$�S��MT��&"kr��BFd�:CY���6�`����{#��s%��D̓r� A�\��op�A��N�J(gT�F�^�����r=2P�m���Y{�&AU�Z�2j������R��x���l�8!Ո�~µ���RL>�Q�{gEokĀmi�=6 ��t��C��s+ݑþ�s�y�,��d'U�f�z	��!+�T�"�'��4E��F��!��3���[�e��*�O��ܶ�Y��Y,-̧�W���j]D�=%:��wba,�"��W�"�Y��>-d�#����`���[��O5`��M�s�#�-�{I;<������*��8�i4�R�rbq��8k	�X|o�f�0��.��v��r��}�ɧ>`q>"�xr����G��A�^2����C6���g
�V�|�l�pC(�4Z$=.$��ВR(v���`�"xN+p!��%�
���m�w�D�k�9��נ@�	5i���,s�YiN��,��M����XK�H���0�D�kv·����g�GަEz���,�����Y5:d���nR�x`犛7<���maDd&]��@l���
K,�GBJ:��K�K�t���,��Zv���&s��V�!�|�f[ل�B�%�c(��m��e���ϔ��B�v���W��l*\�,S�ס�Ap�m�� ����������z=����4� B�[��]f��N�AY�e�G��e�M�LKYh���}��->f�)O�����v��=��>[�����P���Tmq<șő�}($�̺�F�.�����Z7\�K	�z^]H�!��R�VL�g�dA�yohE��c+ү���b�`����#�L\�Ō�M�X���|��r_�����8-J�mˢ.tG�\ɩd�Y��(m�3��r��8�Q,`��OfFZb-4��ĭ�����[���8(�heW�C�!���
EU,��
c��Ta�/5�k"��*��Ԝz6m��Z�Ñ�;	�?u�;
>W�Nb�ҝ��Ô�T��*W�º�#E��v��`Ȃ'���Z���1�4e��2| �Fց�4��Zn]��[W���}�~�o�e��r4��#�H�������o-=�[k�����)N�e�@Ւ��8w� �LP���{��sx��WjA)��xXyWμ*{��&0_��t�3a���Z�tbt��������o��~�gq�\���Y\�S$�)�^�
��NzW��@ݒ�Q(�:p��*�\u�.(�7����e�L�.��wl3����)E�؏n�R�X7g��@���=��%����7��v΅�q���sc�z�}��*�٘@U�*��D�+ɳ����W�\�5i�/�F�˞q�{�Pfx{j�m��ZS�U�����sh�ߝ�T�z`����mJ�r��+{Q
z�� u'磍����r��`�jT0��	b�ԕ5�q�����%��l�KMU4v>�)eJ���;�ѾxSc�3ZC���,��L8�r�K�mo`c����[�<��݌�`xc"8k_s�cT�S�ou=��/-˾|�
���V�}�Fr���+V�����/��"2c�8D�v�j�X�v��"}P"���� 2!�߆�-d�Y����|�.����K�cT����_.���Z.�'�P\�!+��*��������'�M����8��/��5�e5/w�ό=��cmu� �_Y]���U$��*�>�L�uIu >V�Ÿ�_^[��?��_έ.O�\E���`�ۋ�B5��@�rn�j��?����d͖f��/�5���	���lm�f_ve���	]�S�vt7��o-���c�8M��;R�b܏vG�K��i`j�.Z��x�/�{X��bw�,q�_t��nI]��ww@���k@L=����*��]�ݢ���2�4�`��\��z��#k�ji��_P��aA�]�:34��u�m]AcE�Q�3�}*׶��~yc�fz0���{�-����I���<l�֥{e<%2l������R'2��A4w�8��ySfWTp����b�ܹ�Ѳ�ܿ2�s��Ȳ�#�
Hc`6��"W �:��bǵM�E��V�0L=�.yا�I"j�H3F��j6��1�����"�'��r�l��ǶẺ�0d3"g'j���ʖa^�G���2�
�X�QU�Q�f�:;��ל~C��c{fe�F��I>��$[smؐvh�N��3�']{`��1O�wj�9N4l�g��x��������~�ׇ{+�QG��s��pd Ú!�q� &��Ҋ|��@�s�Ȣ�����W�����G n�7Y�7�͖�?#�A.�u:0W[�pe$�Ib��t>��/�����{�+�Q�0�U	�Y�!�(���3�\&�Ț����nP���5cv���pXᇎ�֗��$�9z�C����gd(<%��rDw���w4����������gC+ъ�� �h�ɂ���z�^��/�wN7)�#jX0u{VK-�S�|�ȳ[̐m\�(������'�jHU����e\���?��K�\�#�����,��㞏��̨*Z�
tU$]���E�/����nC�}G�1��P�`zjt3~��;��+<��υ�Q�(3D��>:�>��MLv��"���}/�F�1/G��79Qu�W�+5��
����ԿEQ��r�,��N#z��h����V��㨏��20}~�e��:�N�n�Z�0�,��䦼4�/4*�рq�9�]�܁2�]���w����?3P.ݸs�3&:��L;�Ҝ�d�����P�]���wȂǘ`ޞ#��u��vS\��wg��-��3a��)߁��!Q҄n�ס!�,HY����%B�`�c��q��H 2�У����^:WH�W����Jq=�r6y$��erB"�H�g�_bW��P���iMHE0�]�yg;���D�C!E�&� ��+���"�R3��aJ������>K��x&���5dTYo�Y.ts���{�_O�V�5r���8�R���q(�G��?88(�6|,��sp�ʝ�� ���O;6R����<�y/���WC!�6�7�����N �P:$_ר;AX��heC��:��B
�C|r4T�Y�8�_�kvG�5�J���9*=��ˍ1���� F�w��w����*���s�6�v^�{�}�8��p��z�.���yA�)�t4�*^NkR�0RnH$��1��<�;7�))�0s�	��	X�ϋ�ʹaO��QB�(�`8U�a�l4#�0H�k Aɮ��&aVf�~D*�+zi���?��`2-�I��:�u�'�ڶ�b �
 )9�	�`qq3��HСpkԇ��㮃N���+k4��{�`m�x�l6��`1[#�R�a������J��:�a�0l��F�DAp����Ӟ�+1�b��0��'U�6%@�����B�B���&	�gȝ�`?кDkQ�<�A�з�H�dyβ�"D�&��&cs��q�5V�g���T�q5��N$��xTJe�ԅA��
7M�y���C��z}��ex#��ނ�{7nO{��f��Е�nd�;n��3��SA��}1�~�q�evOq;��'ڡ�{�H$A���6�?�R�@�d�W&��ɐO0�[�˲Q%���:z�!w<�*gL1��YAq�i�$cƢ�wu�H;���cO�5Ϗ!��n<r^1KFg�3;�~c%��l7;���3�d�މ�׸#��Pم��ǖ�����N���b�+��NT΀�� ��㒵h���4��A�n6�t��VԨ��Y�5ܺ�pw��'�K4���(k3�:���5� F�š�i�t>�Ĝk�)���N�E�2/Cv�X��w/���e���#��#�r�T~�FHÅđU�@<Z���<�4���h�(�E��$4�K�|��Q9֡a�ixh�	;�Q�O�~��4Ŋ�����'�L�� H �"��̋ c��-y|�}�-C��/���X����}jt�v�m6�0u��L	�*=���J`_�kИg@ެ���mW��~TO��|2��z[S߁L<������K�H�}G�t�*�9���N���7�5T)#�ʖ���!�.��)�X:�F��q���Z��P���� 9-�8F�jo�<�uG3�z+C�,�%�0��?�)!qUC/�G:0����O|LCBO�c+���9�Ȥ��vO��`T��2�u� F�6]`ؤF�=��x2MWQ�X:���
7s:�����M��.�|�P�?�������Hj(�b�đ��P�BW_�F-��Y��7�f��XA�����v�=pD3_�E�"��(x�2y�_<��4���Y�v��)keJ)ΐm�E������Х>Ղ�ٽ[Yn�t���0pm�ŝE
U1z����7Ȩ�WG��^\�B�Zl���.r�#C��-�Uˇ�Kd�ٲ^��3x���d�q��w�ͪ�:�b`̬&��H���y�<��S4�`k&�dDd�慎��0�_�ȡ�C�M�S!IP�Jb�Ւ,�⒥ʤ\D�:z��t�<C�n�8f4h
h0�XT)s9�N=q/hzB d�M7�\1�f�N�R\WŬ�3�8G|X:�??��p'V��Dې�Q�@������Ը�d�d�בg��t�ܥ���t�ba��W���j
������ی$������lAm�+��EE�d�\y���K+��P)ҷ ~�J�\��1�ṚV��ǃV�cdU����E��\�rҍ*�Eg��U"7�[������m`�1m ����'���<9���B�2��@��*�L�"�q �}h�����>(���P��YfM�<"��wԩq�(�	�gLU�Py|O1"��5�����Dؔ�[��([e���W�3���aK-�C!�+h*���͝�m��
��|-�O��,~���Lq�?h*(��I��x��H�#�� ���N�tTW)*N6�� �-*ʫ��J�D&����V���ʻ�+N.��[�x5�M�#��I��1���2u4�6�q��a�to�/`-���6�]BL�5���h,ǙWؼ��U�x�a���՞�f�����A�$� D�eOqj OPe��2PF\82��CNx��x�JM,ʘ�	�y�M� CD�uj���FD�j�F��������9�W>�����z�3E�)�^�Li91���X����qQQ����#>�3�vt)XyLy��ڑywh�|�:�����  �IrZ����wM�/���fM�6�L�F矲PQ�0����oS�5x:)�m��]}O�l /�J�Iނ�X��iQ(���;��k!؟v���2ÌEk�x�t�@�F�8P}L��ߠ3�{7L~���`��ߍZ&C��χ4��>��I������_���.����V#�AF� �:<4��B��*?�B<2�X��O�[bpù���I�H\=����Z���9^4��áI
Հ��P(���/$5tX�SÌR�#bU5;?7dT%պ�Ň��bQ���z:vV�W��`ᅶ�y.ưZ��>*��k��w��a�6D	��:�d�q�h��	QR�F �A��PC�A��-�^c�)��N��U���"�%��'�sИǓ����"޵X�n�Y�f���6�x�e)?�4��M�RNvq=��C�T��'{�C� Xz����q�e]��Π�3�Kx���Ph�"n�h��|&(]��؇=j��Io��@���D�"�:
�\�|n����A��5���b^�h.���;>>�h`Ʋ�Y^����ܨ�Ԫi zd����G��y�N���ȯV��#?��q)ʀr�u���+.������s+0�ŵ�����U��w���sj�6�=Vhs��u27q�����%rmPQȭ`x!�O׫��_��Uj�P���m�U���అ���{�nȃ��{�n/�,\_�6��x�Q!�ai=d�������ꇨ���Y atM�Y�-Q��lA�j�p��s[��n0��{'l*hr��Ȁ/X�}���u*�E�`ٔ�c�Ԏ[���d����k����e=�u�?͏6��
�xC��1�H�:�!�~���c?Y����3��L!�_�����]���x��T�������8��{(q�~��_��D�zz"*��#a�w>�&|ݷN�CN�0��-~������x�xHG-�)8�>S\�W�d3�����M���L�E�c_&�jF= ��Mr�6ۧom�Y\��_�6ww2���ڳǐa8��	�	�����]�.���+�%�<8x%��YH0Q�0�� �zvρ! U_�nU�ms�~��AS/JMS�1��+��g2T~�2&��&��t�r�*%2h�n�@cY
/|�&���5zxE����F�ʹn�Nծ/1R����2<�
����`��,\�X(@������q�,��oqt�x�L��~9��N=֪	G��	��K�c���+���_�Q��|q���jҷ�����ff��&٭��7�g37�_�����g<�僃}�K�k��v K��c�2�P�tA�D{��4�WÌ������?����B������{)u���k+����_^����I����4������
 �J�}~�X���'��(�,�)I�mJ[��&��ѝ�f�uP��L��!�D�۸ë�V"�j�EJ׸}���W�S��t�l��K�����.bj�������v֟gɓ@L�gd^�l�:��N�-:����Q�n����J��qj2����`?�����D�2tちM���j�M�H���bx�	�&�1���b#�=�H�b1F�i��b��q�F��x]�4	��}ox=��)�8� ���g��% 7�G��%t[��}�K����8|���y�|\z��]tj&-c�/N�,�ӯiʢa�0�/��a�T;y!5顽^��a�Ȗ�d*	,>g},0���� r��-����r� ��`X��L�I����.}��9BJz��#�9�]J.�N�\�Q΅�+��B�'�lF'�S�V��Lޜ�r7��f��lEA��ֈE{0��U�$��cG���Ҽ��{hu�S)ثxo���x����![[�t�ta������I�2eJ���E2w`�4��e���ky��4��6�um��EAs�<;���;�(	�LR�yy|j񘈇W�FQPl%7���P�/���85	���z�l $#-�s6�� qdX��##�����!#��G����*�+�`鴰#��/xH��l6�N�6��.t$��U�!��Y��clS�v���T��.�8���6^Bz�}"��r`�z��ׄ�G�VDX���T�y�)<4�*@A%h\](��Z��܂��8�;�o��Y���Fo��cL��r~y�P\-�\~eeym�������M���G�ݘ�P?�)2E;_�l#�am-4���t�_E���W���<�J��e��!��*X�*7U��	o�:x,������e�8���Ջ�#�b�zl��.����������[cF����2����ǵ3�/�����$�QrnȬ I�E[���څ/
����3.Kk��"Z�[n�t�?ݗ����*��v��Io�a�%��*�j�������Y�I�A_���ｿ�_]^]/BZ�}�	pߜ��$R�k���1J�_Y����0�sqem:��$M�\���`(�7U�-�Oo�m�d%���ӓ�_��u��{2@����%��r�u�ƻ�bq-����������U$�s�u�g�W֦�ɏSqyu�9���/�_����t��"�>]Jg���k��t��"Iqj�J�N�qM��Q���Zp����+I��ߟa��/����Q�L�K���Qj�^�$��K��������󿸖���+J�{�V�5|�1�>o��Yo�������������v�ִz�I7x��i��i��i�&���ƭ�m�4M�4��	����?d�	��-��M��m�I��G���g��{�~������'���?d��i%��#�kN�J�+(�~t�.O�4}��ݿ=Ӝ�g�-���?��Y�Jk�6gf�������߷���wd�t���֌9��i���F�T����gB��#�G��h�;�l;�F�B�ؿ��w������[��淾��7nܺ��n<�u���^xO���/����,��}����~��6D@AZ�h���c�lY�����r�H/n޼y�f��^�������%�2�˽�DVW���7o���|i�W��/_�:��_b�Lq�w����ީx-�Hz�m�~��߈~����7��n��[�n}���[�}{���z��D"�~�w�9�f�2�l�:���qMx�ݦ��P�^�vkƗ,wӶ��=�1�����К߅^}�ǲ�
�3�\��:vi`�;Y�y�������B���a��o��w�w��n}�1�/5���c��v>ל�nb��_ �Mæ�7���o����~�?������������=�={��㝷go���O��ڶբ�蛷�y{�ƍ'�|�zEh��{�����w޾u�@/nk7n�'��[ρn;7ٓ�⭷v��޽ݺy�>z��[o?��G�?�Kwo���|7�t���퍷�7n���ĺјk���P���#l����r���nzW�f?Z`_(*f?�*�۸&�=���7���/g�3'3f�_��+3s�f����t濞��g���?���3�h����?g��D"��w?J�s�w?Md�D!���(���$�i�q�W	=�NtF�N'N_&^&�T�O��?��s�)�W5��=�o'�(��A�?L�g��<�_$����I�ω�%���[�O�߉��7���ʷ������(4���[1��?����O���������������{'��^�G ��V(R&CJ}��(�	�bS�̀[7qB	������������?|'����Fz�A�t�'�n'`Jܤ?6o߂w�V�'��@�����Y��vH������[ބIp�����o�o ���6�Q�u���՛#�v(��W3����r�g��ķ���?H��B"�x/q7��Ľ�F���I�%���A�Y����D3�M�	+ѧ�*q����.����/%��Ŀ��W�z��H��ĿI�������q�?��o���J����'Ui��w���?-�iżQ�� -jG5��Zf{���ߜ�δf��Cu9�����"�X�]hy��E,����5Ӧ˯���"���9#��3Բ��휦i��i��i�ڤo����j���4M�4}�S⛕Z�ތw J�k'��W�����������t�6����t��5���L��6����	t��?+k������2��q�X��L�2H���0�t��"I��r ���1��O>�_c���+�+��bqz��JҬxo�?��E�t��v�E�7�tA�F0v�<� ��ɛ�a��@P��I����(b��	�ݶ���L�>.����9tg��x�����KD��|��~Go>�#'"讥� �^�J���E>EJ$��ZO��db��2"����LTx�w�fЛ��������O�ͤm�,	�b��SDz6���1��c�&�(!=9������4)�aZ.����p��V����+I�����k������Zn��ũ�%)4��N�e�'��c����\����_����
���W�&�3)�m�<�5ǵMw`�<�C��t��`�|��'[�[��'�M)��K�Z&_���kA7k5��صDl%�XR���q��Z���-@��k�T�H>�#?#���?I�
m3o���m����#�a����(;�0�k��{3y�h';裺)�`����{7��=���I��tM�lQ4�i�JP*��fں�0_��.o��w����%�����Y�Ԣ ���� �9@ �A.�eŜ�N��K�V,&i������.���K����^;�(
;NW�V�Vے������u��}X��c�c�ҥ�Ly��M�V�k�ǻ���$�66h��7��4�:y��l>�����C�q ��[Z��c7���Ksst�������s�H4q�c�ۏ��x�&�?{BY{����eq���%<,%I(�q�q��V
)E&H/�
"�v����gT)k���/�� ��{�}�S�����!��*���M快IӠW�����%�紗�.ԭ�!s�.��� �>v�:�F>��]i���rY��ϲ�\ϊ�6��<�A��>GddJ�12�w4�K�^��s���̔����bXZ�?�����=O�N�_�:����O�(�O1��WW����$M����?n�/`_X�k��KM�4�c]�=!��n�0y!h���^�m��'~�܁��>&n�h���鐴K�?��"���G����2��{�d�^_Ύ��
w�O^�Z��3̦�#]jׇ��Raiy�����z.tn�l�W��;�������0Y(PL�\lF��a׽_WR�?��N��3;��H�俕B��+��=���S�����&,�o;�	�5JgX;�1iI:%D��O��2Q2ے*��%�M����Zp�w�! �D2�'OO�d)L�y2��x����8$��Z�sm�5�.�M<�b=tT��D9%*+��kDp�	��E8@�0Ʊ��x"�B���!I�6��,Г��)����I�A i���hۧ@iyP��ZC?�#E����f��J�M[��7�����{gвH��Xt;��rx7�g6PA�a��g%#*����rh>�}Kך.P�;~--^|T55�ǔ���f��P�Ԉs�V�쐭����'����@���`~���}��F@�ˈ�wu���^vj�r�|��X�xh�8�v'� x��茊��%<��@��L>�L�)��{l��30Nm�M�]�>$�'�/?K����c�דx�VbbV�N���ó%Cq�d�,.�2��hV��w��ll!?OV_�MJsg/��d�Xol�Q Z�2`V���՗�A�̖f�vn���*Q�
x�,��.�K�A�5�XG�u��gI��'b��`��_qy5����s+ �������U�i��k���̲7V#��L���iO<mS�zƗ�v&�19� l����B7z�o׆����)*��0u[C��Jm ��t��,ݿWe�y$"v�#	�ï���������QW�!eX�]%&�`aȭ��;rl��.�H3��B��.����&�Z�l���[[��������_�6ww`��r�Y��.a
�2
Nh�����V�]:�fF�����ߤ,��� ��
�)n1�;&��Pj��R>(��! 焽ki���)��#~ǃF1���;-5M��o�hLV��o|�pO�[�����a���%e�� �H���V��k�.����X�?h,K�}R~T�����6=V��� ]h]�Mꛂ�l[''(�h�«l��� g�ぅlcF*�̊v�'�P��7(3�~�������Ĺ金����V��T��3Ԍ�L2h�����o���Q���թ��Iu���N�Yr_w���uv��}͔��/��Au�����,Y�n<��<���pxo�V�Y�oΘ[�������3�Hr�4�����֟��m�������j��������W�.k�?5�hv���V l(��t� �Px1�^��"�Zn;�?$�qzX�T�N�&����o�'�_o�]�\�d��UҨB0����j�x6�Rx6��iy�a�<}����������~���o���Q˗�>z�Yz�%O��
��<}F�E�f�S���������ruz�L��(I�0��]�xkw��u:NMF#XU ��f`.@��dIy;�y��x`��s��V�or�EZ�U�^�@��b����XlD����;��j��1�����q�F��x]�4	��}ox=��)�8� I� �����e���A����͗�ݍ7�|���y�|\z��̝�\t2�����'_����4eѰf����EX�X��3k�U;	�O����Y�ڬ�&	iYI����s�no W*ٲL�;�A0�l�H.0�e�L����v�۔�R��� �ۥ����O�\8�¹�)����NZmtc3ysF����MH??�etD��Z#���FdV%��:�yXk�K�mݥ�R���{�t�uT��w�M�:z�/��6�%mm�N��A�0�`m~Eo�{�2�y|�"�;0Y�VײK�����`�{�躶��a���9]�x��h��]�6I!����c"b\h��9�b+��Đ՚�����g+�۶eK�m�6 P�k���>�l0jD��đa���x�a�Z�C��Y<�@c���{�>)�?p�:��R� ��/xH��]B(��#׆��܅���3�*;$�4K��7{J���J3���W��7��rK�A�z/�=�>�j90O�S_nZ��`+$j"�n����
�&.� �d�ǭ:@ɸ/\�3s�����̿9Z����p�^�&X�(�/<����E����M�?�$��a��a�C�S�x�$Jn��bvݭ����h�/����x���������\(���_[^�M��U����z���\�j��YGj���`TL��o�K�x}�3Bf	u��2qD\lS���R�'������Oz�%��<��j��������%i�2X��)�fV�$O��K�.|Q�/�*�=�
.Kk��"�;�ç+�龴M�V᝿�wO�:�ۘ{��n�J�Z%��@m;9{ֹD���iY�纽�_~�������z��{��O�����'�B�?S�T�nԯL�_Y���W
��4����������4��q-�?�썕�cn�D�� C0YI�j���E��G�f��ޟ����q)������\��X��WV�<�+E���V����W���?d�Q���� ��e� ���cɃGOa���#�.�H4��5' c�t? cA?�+�X��	_o ���r�H�jiw��S�ս{���5x�1�E�y>�^&W��ٔ��#�_
�2H���B��\}�[(Y�z`@#eW#JZ�`�}�𝡨�3�@�=����A$��-��oԑ�3�`"u���䖗��r+���wizHlvPU�̇7VQS�J��'�S��$�	�E���|]<�&[��V��s�H�K�ò��Vs�x�V}J5��(�nk�������Al�%�v:KQ��������nX���n{��t�X���� _7k��i��i��i��i��i��	��EXc� 0 