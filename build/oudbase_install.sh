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
� vn�Z �klcI�&ξ�����n�����WCiVR��%�h����=��ˢ�{f�{���y��{��^J����Cb q?�8��m ��������� 	�,8@��ο6�䇓s�qo�}��DI�3���{�NU�:u�ԩS�43;s�)�˭�����>s�"��������J�Hr���ja��\v�0W��)���������>ߐԀ��:t�8�s	u�B�?_XY^�W`������������|�g��"	44���%��%�6��Z's{`GZ�pH���7pSwRя�����K~Jj�~߲]�p�R[�25Mo�n8��9�N
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
H� s�?y���j���g��C��g�Z�sQU��.���l�N	m��'d�&��g������!����#�U-�F �3���s/�`�ֽ��2�^?�=Փ��Os�f��u@/�Ikcw{���>�m�f�t��9��X�K;Ao$௱,��2��j&�fɸ�|�(0-xcc�Y�h'\c>��w�_H��rI�^���B��/8�0�,��i(� ٰ2k���s΃@7(შ@���!w�:.�p�;���\��.�����x� /HڡZ�����'���=M!��[�0�H�\X�_~�_T�C��<~��ǋ3h�����' �����[A��?����+V�:6�@��?6`�5`G��x�VoeR��D����#�D�����!ik�SK:�c.>Os9y�\�tn*��Ɣ� �c$`�)�&����1�:	�O$�A�Z�?W�W�=������+S�ϫHS��k���&�W���u��k�����G���ɭ)y��/���A,rYW�"4-���w�Cϳ}>5(���f��2�7ֻ앚�|��=z��5v�X�Ę�c��य'?�V�Jų���v�L��c]N'�s]�'����t��J���1�ɮ��E���֞Zо��.�I��oK�u�K�#8Q�Zesgc��]�9(oMmr�A���M��o��&��1�ɝ��Nmrӯ�M�X&�S�ܩQ���r�l6ʝ�75��ӾQƴ����Һ��zo�zf�.l��*��*�l'��rj5�8��Z���V��xnL�Q��_rQq.�~dslٗ|��b]��uQ+.��V<%��o�֋�9��t-��#r��ωIU�ɝ����j�ӝ]I��0���ݪ�/`�g<MϽ����EZ�^y�Ӈ{�Z(�UZ�J�QJ�wq+A�9�V1��߄���UB}�A�U�9��_��h`x4���n�UYn!��vij=L.jǩo�����B�8���::���]T[eNI�(3D�c �Y�J\�o7�z�>^xEQ���㉓7nb*��)�a���8#;�Rm�T(�jLsQ�T�D�߮����<4��0��b��f���n����y8���.��q�_�m����}r7��#�&��p�}�D�0�	��SE����e�&s���Fw���A��'w�K�i�=��d���F+�QX��[����-��EN�3�eP�k9�A�hc��?��"�<��p@�.\C�45(A�t>L���-�ׁ�#(k�e>�R<���Q��]�p���1N]B�Sd����#i;zf �>���Ǝ%w�������3a)�ы�;"�τL�y��gH�mj�Z&4���=5��1��;�+�V�����[]��I.����<�������g歙�m�Ivk�3�����M�W����;���@���7Z����d�~{f�� �g�~��g���0��g�j�7�����|=�i�
��������,��-��'��h����fK13���s����?�WBh�gR"
]R����j._��b�0��W���?����g��&��`�)z�	�"��s#Ntz�2n��·@Z����~"���q�����aq���lY��yC��u��P��&d�S0V�}2as�x�i���5�3�Gh5��3���G̶>HiG^%h�a��D�B gȄ�����q�~�����.{�8;�~�:�J�~���c����؎��HQUSJ��w�R&��Ts)g�<�tV+e�m�+���S�mY8�Ռ��ݍ򖜋������Vn�9��^�+�aG�h�³���L!��,gr������T��U���|PJ�IW�g8�R�Pp��DE������/��ɷ�9MJ��%�}v��L���c�p�C��CI�+X<+<I��fu�I�1N5�h���N��ҔA�N����,a.`��]=���S��uH���b�m�&�9Z�?�f����������
0q$h���0��8��uu��-0��L+)���p�s4 X�����������-A�4 �B�?}��_�A�*�m�U�I-wW��~���E+U�T�'�GeQ�����}�i�8w�5z�.�U6�����י5�����ʔ�9�p�'B�6�5t�6��{B�b��>G/(��쌲Do�@�Mj<lzW��zs@����+��p�ZA�=�Ju���]&3�Ԁ�PL�K��T�e�4�����݁m�|0��7�P���R�edDe�"��V�H�jz�k ?su��U�?C鞈5x��>F��C�v\��,]xl��a��pEYNZ�$��֌>���U+ut�������>}�85�O�����HٰΫ��	�m$�l��f�§yE2��TT�9�*_@�r&a�B<LD�c��ph,FU|c��>��L6uSV�SZ�OIĺ�=�<��E�~0N}�܎����T�����S+T@�	��;d�����F϶�BR�Қ����2����Qߺ�7�v|�0�1�(�x�ed4�gN�Y`ױ�-��=��E���܊N�_���DV'�3U.Ɣ�'3�ۈ��P2�p�"r��j�-�X�'������d�>���@n�0�=�!�mcy�����_��p��rx;P�{�A*d�^�Y.�[_�P�D�{������ޥ�4�D�!Et4��8�t���(s�� ����J���/\6`�3'π;�Z3�h'D)�wJ��#�0E<\�*���.�7�'B�1�a;��3�\�����Kg��1J_�fp-K]��#	x�U<ȱ��o��	Ry����*c#��[����Z�5�,`e���R�.�jL�d5ѕ�7,*�m����_��0���~Dc�t/ �m���u�)�F��2�<��%��z]��xW��6�V<%���Z�o�l���s�יp�<�T��ҍ$�Ǉa<x�W�b-��e��yx��f�t+���h��N=�>=���(����?`Ff�7���CCZm�$��L� ��l��?���h�������\rBf�RƟ�\5���)[0Z��"h;G1�?��l�L�9;���]�Ƥ�²�fW�S�f4 ���?=p�qv����vT�l����D����1{�2a�-�16}a�G�b�4s���:O!�b_E;��c��:�}�R�#{�I�T�O��ZS���Zm+��L-�#���~���dN͋��ս`�I��ex�P�f�2�df����];f�C�n� �I�� �k> }ɢ+�4����B?�RJdco-1F���Vǔ�"G���T������U�K:/��/.*������q~`�>���yA�ƃ<ۙ����h�tF�~}�0�C2�nz�!����J���{XF��!ζ�-_X�Yo��,dB,��OĶ��R��b*f�4gH���S��|a � gh�݋��<Zϊ;��aL�z�0�@��Q�;л]1ݾ����6m�YN�%�����.&�K�;��q�df5y�QC��BˆG�4��[��@|�H� ��DOE�Ҝ��I�vhJ�b�,�E;�������wG��b��(g�-��wO��cD8PH��uk�\l��f�^WG�l~AT2��	UyH�b/�ĸ~��v�m-�d�NJ(�D�6�
��1o��
{�~h̉�d�7c�
��3lT��\��1(�#�4Fm1)�*�&���M�oP�b��2M���K�_�e���|�r���v��IC�p!	���'j��+��>��5'Y�k�\%l�B���e���9���#�X�͵h=Ƭ�I8C����흰�*�K��b5d �$��4]�$	�R~����{?:#O�ż�˫1y�H�_!�{�+p��y/ƓRQ�<�a�^�Ju!�E �����\H��ڋՅT"����]L�W���x�����������	�Wc�S�\#N�âa��o����a���˫'�r��� �l�`���i��:��u�N�%
\�hk}NEKJ�۸Ҩ�j�6A�ur���P��ލks��6%�KT�u�n��N9A�Y�1���e��X��Z*)�>��Σ���������v�������Y	(H}����_H%���<Pȳ�RI2.�xvj���+*%)��|e|�J�Y��@~a��x�._���KϣK��`	�<=���售�Խ[�&��(%��C��N�Dv*���*�DdmAY�ZȈ�<8g(+{U �fl|�xodvx�d����sR� H���� N:���i,	�l���h�띀8~E�G
�-��.�#k��$�*U�RFMԲ��2�^���o�}�=�M '��O�ֶ�Q��Ǘ#
s����#`��-����d�.6~�yk�;rط�y=���w�줊��P�`|?�a��jTd��7��h!��h�;�<{F�Wyk��9[���a���9�;������*���C�����D'^��B,��Y�1�j�AY0�s٧��|���l�Pq��������|��c�"��s/i��'�R�S�<G0��P*PN,.U�g-��O��l�ޥ~�.�ܒ]�ۼ��!��,��B�O.��6�43���A����cȆ�6��LC�
���t�nE݁fC��ǅ��wZR
����R�i.���S�[����.�Ht�4'���(4�&mX��e�3+ͩ]��R�i�|���c	�?�擨~����y����Y��۴HOs��%��59��B�̖A��M
�\qۆS�`�-���̤�>Ȃ�Ӹ�Ra���HHI��c�pi���P�e�Xˎu��dn"�؊ �;d�;�l+�pX�$s����-�@�l������XH3�.��J}��M��e�=�:�>��m�`\<��}��Y��'98�[�& @p���2��7(K�����R�i�i)�q߲�5���l8�v��a����n��C_P��gS�Q�=��#.�9�8�����Y�ֈ�E�\X��y)Yϫ)_ ]\J�����+��1� ���|lE��@w�=�b�� A���z�ݑ�+����+�v���]��^;�ǢEi��mYT�����+9�a�!���-{FZ�W#�̑��̈B+C��F��UP�A��6a�aPE���C0�0`^����\a�b�*,��fzM�Z�t��SϦ��R�Ax8�q'A�Nq�A����I�Y��<|�����Y�j^X�q���]�N4Y�D_5^�=^9�����Y� ��:Ё���Y˭K�r늵ܺ�Y�������9[�FUy�Q鳃Z[?2`��}𭥠gtk������}=�	���Z�x�b�@�	��*�r/�xN�U�J#� E�]�1|�Fx�μH{��&0)_��u�c���Zh����+0����/:!����A��9M����&P�SR"$����.�ǁ
:*�P�u�|e1xD����86j�7�3���ݱ1��h���O?��J�c]�a�/�ƴ��ץ�B���D_�9fƹ�C΍���Q��gcU=����$�b�r�"�e4s=�n����.������m_�E�kM�V�K�ϡA$Gv���f�[ub<^�)9��n��)��N�4ԯ���6FnK�a�EZ�5�Q�잣#�z��V�H��>Y��xlr/�Ѿ2Q ��!`�;�(�.^G;@�M�-�|ciO�gd�Գ0�y+~ȍC.[Ƕa����.�o���;v3b�ፉ,�}�q�QgOiH����Ͽ�,;�Q*���[���eWX��1ʇ.�G��?���S5�+�R7�.(��Bq�X,��UC���	����,����D>Mב��K�cT����_.���Z.�'�P\�!+��*����������M����8��/��5�e5/w�ό=�,���*�~e�8��H8���re���.���j�7��kkr�':��-7��ri�j�iPn/�
U�Rc��y���y����_�;@P[��2��Ռ^��&%�ӳ����}���/�)t�N���Mc߿��.����4���dH��q?��G��u�ԺhAzⅿ��a%���������*�(u���1�m�?��O�1u�bF���w!w���SdzȄG����R�a�/��Z�x�aC��MWA�7lt�5v-���4`Cp���o�
+�
��T���D��K4Ӄ�ݳl��?�Mj�f�EbS��.�R��a����FW�:�I&����š̛2����t������%�
�I�~]�E�T@�I-��Ց;�=h"(
�皆aj��w��>MQF�1zFW����рhd� �(x�	�3d�f>���M,�!��A9;NÌlT�s��<������U��
����r5���a;����30+7���L��8'ٚk�n�C�w:T�A�����y¼S���q�a>�ȃ~`�<���϶�x�䰸>�s��:r�
օS�y�0��V�Cg�ڀ>��}@���4�W��@��>p�ɒ'��m���r��Ӂ��ʆ+#�Nդ��t~��/��[_y�:��?��J��IDхG���2�E��8h<L'w��-���%��
?t���Ր'���3�� J�_�>#C�(ax%���罣����UI���>ZшV����D�L\���C��m}q��xp�IiQÂ�۳Z�(h����H�c�l�G��f�t>�PUC��$u/�:0�� @���݈�Xb�!�&udA�"�|�/fFU�bU�cب*h ��*|d.r|��FǠ�v�Ep�;��d��Sg���c\�1x/^౭|.�BD�!�7.��qO��/ne�cX�/�{15�ƈy9�F�ɉ���]�A��\mL�����j��#gyw�[��G]�g�Z]G}dݗ���s�-�M��u�u{����`�L&7�Y�Qь���A���ΔA�D�����od���r�Ɲ;�1���f�	��$$C67LF�ҭ��wp�C�8Ƽ��Y]`��������4��;�gn������H����&t���eA�Ȳ�\�`-�#%�#\E0���(,��ҹB:�Z���W�빕��#�L.��Dj?��[����b�I��xHkB*��Z���;��%�
)�0)q0�X!�t6Q��<S2�l��p�Yz��3,�!��z�x���r�[�N߃�(�z�����c��Ǳ�Ҍ�CA<JW,�y��q@�7�cAe���� V�Op�M~
رi�������{�\=�Z
�����wP��'v���С ��F]%E+Z����R��;�����2�9X�B�X�;�Ԩ�U*��Q���]n�y]p<0���̾{��̢�-d�۶��ܣ�[�ю���_г�a��ϳ�ڈ0H���V�Z�"���rC"'���޹NI��@�OHOx�j~^�T��x��T��&��	�S�˶5�1�ľ���lfe6�G�����6�7m���	&Ӓ�dPl��Q� �m[.�n� ��#��7�?��
�F}�->�:� ��Q�FS��v��7@ �Va�����5,E����p�ﻡ���3!�����gdMdg�8O��ٺ/-VH
ذ�pRjSd/ +[</*�,�z>h��{6��!!��K���S�
}{�D�L��,�� B�o�:nb16Ǎ�]3`<x���^@EWQ���D�9�G�T�H]�9�pӔj����:?��˯�w�=�Q�7Rl��1ѼwC����:q�l�
ݺѻFF����8Ð�;�S��3�Yf�D���}�����DTO;hs�s)udIF|e����q�%��,Ub�����Gr�S�r���ܑ�&I2f,Z~�f̀�
I;��Y����i��#���dTqF:���CVR!��v�c�:=SL&�xz�;�H�]x~l�ϙZ/D�
*���1�Du��(���a:.Y���MA1J��?�g�H7nl�j��\íw�xy��D������6�n��>^�	b�Z�1=@GK����˰���tX��)�2d׋��}��]v�<��8�*GI��i�4\HY�ģua����M#���Ǝ�\dhKB���m~�c����F������T�9�g�LS��K�Kahx2��+
��+R�k��� 2FX�W�'��g�2Dz�B�a���;���اFw?ag�f�S�ᎉaK�����c�������D�����vz�G�T[�'�h���1������s1���^|�ďd�w�OG�B�#��nx�XC�2�li�0����9 ���jt�Og�8�5@�E*l��B�ctw���&h���]w4���2d��]��݀�s�W5��}��
�_x?���0$�4�I��	��#/�L��j��FH�!�^7�0aDn��Mj�ڳꑎ'�t�����qȱ��o3�~|��d�������ck�9���/\����B -M���
�-tC&j�2����:h-`��q�l�n'�G4�[*��ъW/�W����K�Ɋ��������V����ٶX�[��]�S-(p�������H����VY�Y�P�'�8ɾy���zx�����)���f�^�"=2$��2��P�|��D�-���@��?�Gn���8A�ǋx�ج�3)��j�ϋT-�g�CO<E�fR�KFD�k^�(3����<�;��!vIQ-��..Y�L�Et��gL��3T�F�cFs�����E��"1�s|�����'�B�t�C�a���)�uU�*?�s����3���Swbu�O�����Y�i�L�[`J�N&Q{y�J�]���kIW(�~���ר6���NO��=��HA�����^��V�B,.Q4QtJ� q͕G)���Rq��"}� �7�_ȕ��+�<jU�)z<hU0=FVy��\T��U)'ݨ2[tV�\%rs�UټO���"���yҁ�8͓��K*T(C�� ��R��)� ��߇&�_��m�ꃒO>
�eք�#��~G���2��{�T�	���#�]�A;j�+J�MY�e1+���W�ڀ���qe:�HZ��r[1��������]�܉���ن[�P��ׂ��J����IȄ~���z�<�7:�:��*�LG����d3�PQܢ���j�}Ld���x[�`��8��;�r��(�e�W3ݴ<�7(����Ch},SGCm'�>֑N���ւ���g��%�ZC=���r�y��{ h�_ �`�]]�9l���1@�w@^���Uv���eą��- 䙀��ׯ��"�����7�4P0HD _�6\ �D��&n4�@��(���o0>�Q��y�3��H�,|^� 8S��r ��ϔ�#���u��YQOѱEK
=�:�:kG����ǔ����w���ר�i�� �T!�5;�8{״P���m�t�1`��tmt�)%�\��6�\���"�������T��b�Ě�-h�5���"Z��J�B��i��,3�X�&��L7
h�ʀ��ʜ�0cH��w����
��+F��q���x�e2��|H����c�4km=���=zP	?�5��`����԰+,4BLp��n!�#Ê���05_�%7�[y��鑔�:Q���+9�N�5a����D3z8��P����X�X�BRC���?�1�(�;"VU��sCvAUR��\|X�.%+h��cg�|���^����b��[��ʿ�iyG��hC��q���CO6����%j��q��N5��?��2��O���X��h-r�Y�|� >�y<i�
	�*�]�������l�i�L��^��CK� q�4-�dד�;�IU�z��>	��w���gY�E,�=����O�P>�)ⶌ&�'a��e
�}أ���
T�K�.2/q����e��� X�	���_�퟈!�E���yк���Ff,����9٭͍�N���wA6?��4���7��4����Ja�P(0������HQ���c���\qy5��-��[��/�W��?�";C��Ss����@��l������ܔ�,�{h��BnCY}�^������p�R[�25Mo����� �-��D�vCt5�m؃v{��`��R������
�K�!�x_� ���5W?D�4]����h��2l����8�eJW[�땞��w���;a#PA��LD|����G�S�,�˦�"��v��F�'c�-�.^�d$D-��豭��i~�W�P�4��CB܏D�����|l���:�̿�ɭe
��*ȝ��������������v&�1��C������oo b��Q� �	��и�4�k�u*r���A�P\m������S?�C:j1N�y���z�b&�au=� nB�f�.�2�T3�<l����>}k��bo��|�����,4מ�8�ÑLL8Nh���Tn�Jw���_��/)���+if�@��:�a �y�Գ{��bv�Zl����z�Sj����l_X�/uX>����×�0��5iT�#�3 T�(��AKw3��Rx��6	����+�5|�X6�U�uu�v}x�������T�h��g)����2͗f��f���f�op'x��S�Cf�����I~w��VM8���M,^B#��\a���
�m��<�����W�����̼53��5�n�|&�>��	�
��7��;�,��X�_��Y����A�z�R'��Ťٽf����������'��4E��e�K�c��_[)�����t�_M�����i �P@���V �W���k���=���Gqf� OI��nS�"�5	|��5��z6frEx�'���^]��5P#���8R�������2�:'���`#�_z���&�p���/�?|�����8K�a<#�"g��	�~��h� t,����Q�n����J��qj2����`?����D�2tちM���j�M�H���bx�	�((�1���b#�=�H�1FGs��b�q�F��x]�4	��}ox=��)�8����g��% 7�G��%t[��}�K����8|���y�|\z��]tj&-c�/N�,�ӯiʢa�0�/��؄a�T;y�4顽[��a�Ȗ�d*	,>g},0���� r��-����r� ��`HX��L�I����.}��9BJz��#�9�]J.�N�\�TɅ�+��@�'�lF'�S�V��Lޜ�r7��f��lEA��ֈE{0��U�$��cG���Ҽ��{hu�S)ҫxo���x����![[{t�ta������I�2eJ���E2w`�4��e���ky��4��6�um��EAs�<;���;�(	�LR�yy|j񘈇W�FQPl%7���P�/���85	���z�l $#-�s6�� qdX��##�����!#��G����*�+�`鴰#��/xH��l6�N�6��.t$��U�!��Y��clS�v���T��.�8���6^Bz�}"��r`�z��ׄ�G�VDX���T�y�)<4�*@A%h\](��Z��܂��8�;�o��Y���Fo��cL��r~y�P\-�\~eeym�������M���G�ݘ�P?�)2E;_�l#�am-4���t�_E���W���<�J��e��!��*X�*7U��	o�:x,������e�8���Ջ�#�b�zl��.����������[cF���²���ǵ3�/�����$�QrnȬ I�E[���څ/
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
�2H���B��\}�[(Y�z`@#eW#JZ�`�}�𝡨�3�@�=����A$��-��oԑ�3�`"u���䖗��r+���wizHlvPU�̇7VQS�J��'�S��$�	�E���|]<�&[��V��s�H�K�ò��Vs�x�V}J5��(�nk�������Al�%�v:KQ��������nX���n{��t�X���� _7k��i��i��i��i��i��	��-�A� 0 