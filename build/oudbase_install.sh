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
� ǡ�Z ��rI�*��}O>~��p8|r ���&.�+�nj!5gx3Au��-w� �Ta�
��'��?���7�������~�x��Te� I�RwWJ$��̕��+W�\���T�<p�V��f���-��Zk�"�^kԫ�f�h��a4[�'����4�Ӄ��.����3ދ~�&���N�3�^0�����1{�k�*�9�@��a��*4����%�~����7D���_����@[ٳ������z��i�>�� /���P�'�����ɘ:�-�M'��ڋ��:����z����}Jj[d�h���}oz~�AzWv��F�c-�ч昖y�&ڂ���ip�z�e/�C�!G���dͥ�:�ٳ�˞�>P�c(ݵ� ,��o����9�֋k>��fխf�<�	��}�uY���x�M\�rH/ gHo�ٓ�.9���ہ�9Jx���S�\��H��ekN/`}>�M�]��O-2t=B�K�s6�09�4 ��햠jx��=�i���EL��J�rN�8:>b>�8@q��i��!�V���6|���V�V5Z��(��9v`�#rI=F�c�ʆ�y�2O����! #�O��u�;DL���`q��K���?�4�>��[lGov�N��N�vwV>*߶KE@���^��΋7�]��>޿n��t���є���P��Io��pf��{�9>���OO�t�d��p��(��dh�s2�@X ���^w����߻<��>,A2���{y�w|zv�9�!�;@g�Ju�pzp|��w�}yzt�b%O��᫽}�}壖ᦢ/�������ٷ��n�d�Ⱦ!y2a�a�V>*�ߐ��8��s1|7�l͒�g��Ago���{���v ��z&,����=99:٩T���Lrp��� ��>���-w�E���<�k��c�����dd^�K��)�B���Ѯ{������#��+ވO���K��l���C��×�礴K�6��=��?��ǰگ\�z����K����E����Z���6w��Q�2�x�J�(�\��{��xt2��.e P�%������d�����&ALz�e�K���L�#FK2J'�<�M�o�i���sF�`�������g��и!��Tɻ�qw
��/G�t:��o�v��|�ݰ�t{���x�嫄=څ�����ԥu��Ө�3�e<y���F}m���s����)l��W��nҐ�%�u��� g�]�bp�I����� �59ulW:@F`��Ix������n���9)�R\'�t�{xtp�l	)��W*}5.}e�}���W�_���_�=9�.��)�v(}�z����j��j�g������d!ꛃhن�|S$;D��� �JvaV^V�����Q� pɧ�RR2������l0a6XR�a�����{�j��7�^�V�ժ�mϢf���]jg�Ӳ*=M��r��MK�������~z#����!�T7d�H�t�d:2��;x �h�Ɨ�<��$�@rf���{.RW�iܳJ�%;PT�ޅn����0�e�=�ω9v���M�|�Gd�Lz���l[C�>p=�;�^Y���h0Yí}}Q�͹�U����b��;n�&���!O;/nT_N:/��!ws��Ӌ��ZY1V�OX{h^���G�?�1�Kw:����.�����-��\�"oW>~{�Q)�F���s��sa�����:F-�|cn����as,�E�����g��M�!�����jw g�
��
�>�����Jr�*F/�[1��q�@-��C9I��3��׶X �xe�D�%�![s��v��!.�XW�*�u�x��;�82�g%V��*��g����|�C�������I�($�2�$>���h�j��ws����^9���^	3KA�M���m:�c��j�5_�aш9�����E/+�t4
�<�e�ܩ%WI՚R���z� �����Q��2�/���S�V��W���bSC��Ư �vG��#Y�B!!���q�):,NHabaE�ϻ.H�Jf�,��NqLb�8N`D9-W��Ԏ�5#<�mB
aۡ��l'�n.��	������k��Z�Fjú�qPp�+�B����
F[b��C!�z�� ��)��L!N(��QEƨ�8�`���ψIհ�sf��5����o��tE���B�~Lz[gDC�P93���L>p����܁i�K��`��R�:֨�_(����t�B����`����)L��s��?��)�q�<!��s�@[���sq��F+v����� ����(M..�������r�᱈3��De�/�İ�l��1>]yg���k�M��ah^k{�.���?���.#��NN���{/;�x��hUw]��t(������g���h!����4#A�bC[�bb�KV��BY#6���QEhp*Q$+:hA%�s�dXտ5
����W~u]0f�Pܜ�A�ܱ =M?���Nf��5Ib0딤0����3V�)���� ?Qkfџp���0\��'�}�eq���R1U
}SH�^YL} V>�+:rÇ�7b�L柵5����`���:�*�J�^9K%~�\z6|��'�[4����N���ǖ�#>FQGv�����'��Q�x��v ���H��B:�c�x�o��C�.���!�3�ͦ?�����#�d�U���J���b"��х��9xy��.��������&�^� *G�7��K@?��T>~�W�:R��&6t����,rm+ SS��F�mH[n�B婸��Q��[�z=uN�΁]���j"����V��$!����՝��T�g��$DG�qT4Q0Ə�<d�x�����_�p+�G��p+mq��|�ǳ#��X3�ޓ���{�Oz;ŷN�-��^��ů�^�t_���c|͏Z;M�2�_I����`*HYWj���7�X�����:��R珻��|]��~Mn���#;��g���u�Vm݅���`v�F���?E�i2�(I�^߈�-?Kvk�Of�4泳��al �RVT��-N�a�(�c?eFp��ҧ�w*��Zv�N�$y+�G��wv���'s3���,��%w�Թ��ô.eMk�@��ڨ���]NC;�b)� R������qoHE�X����&��+��!��F�$�7k��~;�;To�4������t'����E���'���U�>��w�Q���7|j7k�*��6r���H���g���/E�[(�����9���ߛe��@��F=^�vϵ��`�	9�" B��:�ÇAX���r�����K������p��T�Q_;E[Q�*�	U��sR�o��G��l�G_{qe�d����!��7R~F�D����="B�^<ב~Ti��H�:�$ב�u�siA"_z�Vv8�_�!=~��|K]�%��~��\��?	Y�����Ֆ�V����-W���.Y� �^S��~�`���m{���!C����8���heM�y2�'�������r��`z�Kѓ�ū�	���R-��H���2�P	30��r�X��F���/���6�pƞ��G�4k�(����yQZ�wW�{��b'YQJF6g�{=T�z]�d��OW#��O�i -7`s�^O�Eb���v��	a�٠��{���8���蛀���Ű�����M���D����ʍ:����W�A��8B-8��;��р�C[b�f�5���Vޮ����؊��[���uM=D�#�TE��6�8+��(�z��Yh-J0e�B�����!v@����*�����^1rn;�	Ji���7�[G ���ẁJD��Z�K@+rSwB\TX�o�8�Cb���R)��'�Ê,�.��+ ?4yS��k�s�|"T.�"�}�%�띗]���>Ӳ,���Cj�U/y��@�w]?���
Ki���B�N6��N�Uy�r��
�J���k�ˋ*��^b�Y����!)M����3կݽ].�5+��衫�uy��]�����T˭����<dbw�p��dn1?6.@��uNM�m��5Dr�W�a�?2����ޭ�'(� ����.r#��_x0�;��=!@�q^f���XI����G9*�m]���eL;g����l��l壜����i7��WAgO��n��� ���:&����ࠃ��8��T8��Ȃ�\*]�~�:�,?��Bz�)ҧ55�Ա�|�(�,Dc3F�l׼�տ�j�
�%�����F�Rl�Q�RC�U_i����2�ʖ|Z��eR��B`��ET�{��P��]q�x�_
Qa�i6ur-L}(>��R�T��d��g���ED�����b��H���g���!U|�=틏�?��n��k``ۿ�V\�M�&m�ǎe�W�����W6��>�(�����*Ca������.:��h�AK�T�!�9��y�Q�����䲦U��\76�l
ш��]U�r��r�W���H<�|���f=��4�m���5r����r��Ϥ�.�_��'�ЯW��U��s�?��ն����o	�X�8��ו��2Y2|/zvd�s��,h?��j���z~T���?c����/�!�)9g/8i:��������m�`��qt�{J߳����Ih�Uw�����@;�k��y52�sڟ�m@�AT���҆���.T�V�;|y�=��v�s��;`�����-�urY�Nn����䖾$�܅Trs��\)�nJ���K*��ʴ3��ʴ�2��J�v��H�@E�`��owB�6�# S�*�>���2݇�Z�Ɍ��h�5�3��sj��x�P��s��#��۾*���wgs�Rq嫲�i��i�^DX�G9�t�&�����D����g�w�<<Rd.o�녣������7���xp��Ί�����^0�Wz�B!��"_�Q�Du"@=�bV�	)��)�M�'�uTo��Q�7���,�S�\ܬ
�jd�K��0�������j"��Kh$�|��:-t�x�Wĺ����Rfk�ͪP���������ET���*�19��y*����f�>,2�+��(��TUUEI�܉�::x~�:C�<��Z,h+����������a����1����+�<��s�&��p�}�]F�0���[��a��U�w<~G���ש�r�U�V̀�z�
��j2�g���Q�b�bǋkgk�H]ԷP*^H�X�rg�����	�6�vy}��ݙ.�J�P�m�b�V}�,�ׁ�#�k�m>ES<���6�y��)]���*��H]���x���7&%/}e� ο���ơ�va�N��_���$�����̋KiI�ޢy���-��V��"*���B1��1[��ZmT[���h��V�����V���?J���Ϟ��'O�9ꑿ��	�=�[�������O���@vNOO�'V��Ͽ�e�?����ɿ>�lN&#Z�~�
�x�z�0�O���ɿ�|cs��H�7��NPyV����_��sD��~x���-�?������������xD�2���꘽�[u�]���F#���()���<��&�������%.�	PV*�܈��ͭ@�
�����t9Q�D�K!�� � ���p1�i����K�A��48C�>k���)����^� ��	�3=�k���z���f���\�>�i�a%���䚆!��d�]r�o���4�_׬/����E���Y�������wp茟n��L�wY|#��$T87#�jk�Y��r�� �k2��H�>����h�-{p��u���-s�U��s�����W�/Ssdm���� %.���m^$L�Y��n�U��>���~��B&q+jy�a^����z.�*T�S��������#8�j�Z.5=�����ξ��yS���@������c����\(1�u�g�:��wN�=�c	2��������j/&̄,P���dTHY��+�V���r�\Md|u����\j|�e���;EN��5�b!��b�W��3f�&�����)�z����Y.k�ʷ풢&u�P���)%��,�"+/�؎��5g`�2,RD5�	�P�;F-g(�\6H��*��ΨK"1dq����S���M��B��F�2x^���&Vynv�J{�$�@��G$��VSa�pw"���M���~l�W�M��33z�!�z���� ֪aLHw4��\�q���Xl����$W�Z^6|
��'C��TM����E��%�X�8A.�V���]�2F�'��T��J��|בU��oYُ�ɇ)Gt��4Jd9��ݗ�G':�*tLmI4"�*������H��R8�ek�5y��=9=�� ��7�;�>j0�y'4D��`ʚQ�2,�X�]��������U��=BL?.����,kmJ���a ����`�9Ĉ���z��"li�25n;o�����(����GzPo�U3�A]�-���wN�Eu������[.�G��ak�(B��Z��)�hL�W�՝ﺻg���(:`aX�(W��Q� ����	^�#f�o��0�!�J�\3�m���3�����:(���n$�}������qLoL��z˶�5E�3
��XxcW7OU�TcLnH���!),>�b���j�):H�M��Wh3�]]趰#$�FB��L����(��Q�Qs&G�f�!�1���s`��&j�~#_�9WjS��	���Ȍ����#�ޑ�����0@���BV=H(�@-eF���C�Ht�=};"\5[m#�ǡ�4-������1□=_�ZN�f����u�
��B�����.je��ёX��-��C��$�����P>N��� �FW�*���f�ҩ~��Hh�3�#ӹ�aHR�:�R��i4O@���}��}l�}u��T���S�@�p�a�8���_���H���p�"�z�	�赪�fZ��'�B^
f`_��G�n�sY�v{\�+�-�~=�ф�;�~��$�3� q���O�8��Q[6��ld:vk�w��9��X54 7��*���-V�!�pl�M���B�<<	�0Һ�Ҙ݋���;dG?=K�i��
�`�� 6�_��Н �
S�|���2wr��=�j^#���	�C���0�#���7h�W��q�*���E����'& bgg$h�2�7�-.V�G~0�k��Ƣ����E۟|&o9Ѵ�;��s�j�n��]����L�c6E��h������r�%t���)Α��qk����c�("�r����9�3&�M�spp�Q�Ѩ�n?C�|w�Ϋ�|D�Qk��j;���Z�[l��J4�뉒|��V��w��&J��T:���"?��f�5g�8����19F�L���c�8β���"�Y�����a&�ٙ,"Q�D���d����-����t�%7p�_���(!jSP�f�RQt�Y�xt�ǉ6~{zzL�����K�uG*�/em-����uN'�mS�1��*1T��!6N>b8��~�<b�:	�2�a\����k�#���״T���Ƣ��Ji�{�(&�H��<њ�U�$LX��Iz�PB|4�5pwT�!�X}]�)�����le���e����ʣz&D�TB۠ĉQ������
1�����pU �y�ĳ�`HV�*5}�Uɨ������>��=�H������+k?��sֿ&Ȅ�q#�"���"�W�۴E��r���CR3eF?�8I;dy �fE�b����d8�!£�Ԟ	١��=����LK�U��|��s��6���������&=Y�m������ܬ�G1x2���ˠ,aT��̉���;�
-��W#���w�Bݩ�!O�D[��A(�Ą+���ߛ*���d$;� k��k��Ns;+����G�`��;�C���o��Qlp��U����i*���n��MG��V��	-��EQ6���!;]3Q�R(��5���÷CmCBeKGTWf��k�7<~NN?#+x����墎.��KVj��FX�X�+J�&eEq9�L�i/+JY���;)0�"��u��W6*^�LVeB&��K��y	/z����	N�!����9Q�����yjXfm�����{�*O�ǉN���e��-)��]�S�kw��VN�HO%M��>D�&���'T�W��%/d��MER�XG�$����9!�Q��J��"<�`�V������G��nnip�Ny�G��i�<.d͐��JŅv	W,�*�KN*����R".�L�'fcw�N�
�L�;��#��|�-,ڍ�uBl7J��I���bqp��q<]g�g��pW&FZmR��
Vo��q	�v���
n�����KQ�ۢܨiY��M{��ܒZ��yV��^[�?� ���RD���+�"-MT'oK6F�t"��v'hł�XE`����φ3L�����1�2+��� �y	ο7Q!�B��X�PwPI;�R���3Mʔ��<�]i*ٵ�K(���
���K}�x7��Xv�rNͮ<O/!V�%���*[M�Ӻ�����5)$F+�<Oѥ�Q����b��f�N�\�V.�kH�uGȢS���މ��yZ �i��yZv�٩�Ṗ]�"26Zgd~':��܍�p�f��Ϳ;��h�(E�J�	�
s`n1x:�%Y�+�V���"�;�/�)��L5(|�$�C���q(�/���V<��������W�f��K�#������\r��O�Z�4��,_xT���?B��$��1���2�)�����Lǐy#�0+UD�2S�6�
���>#��;��:�{���;��!�B�_+?[�Y[-¿O���3�I��,:e�a�0֞"��Ok�:�Y_���UVS�|��؆���&��`ҿ*UqVL�R�|d��߃a*��o��}���ԙX�]=�C��%��� o��y��t�|�>�E7��{����<��ג�}O���
�lʔ'B8l^F��i2�d>�`<����hR@xjz�"�qM��C/j�L�&�ъ���i���r�v�z����O�k�9��.֠X�%5�;��1����O���q�X�����S,*���CZ���D�E����]L��q��dLM)�@��fG���ǁ�q��.F�Bb2B?Pdͣ,��RX!y� (�O��+fO�&����[vE��]So�A��p߹�s��a�����!e�O��p��3��L,!���OQ�J��|T����r�"Pf����0�k0/�����v�FTB�^�l���0��� ����\���J���!ʠ/nt+���))YX�W�wez���٘'ہ�M�{��%��M<p��X-b~e~��+�T���8���+� �D8�L�Э3o0G�z>*@�}#�ċ	����@j0'y�������;�_��G���%� L�/�����l�hġWǝs���y~�;=YD�Kk�T�Z��%l�>���(Z`FB�mN�t��9��B��lN��.���S�9CUnNѥ���0S�\�p"�C����9� 3U޲�5�"3�Ⅎ^v��w�Jʅ�����H7L�WXPY����v���a��ҠKif�D�keM2��]� ]����,�/�R1�/�\�$eT�l̞�J*�?�,��"����f�C�S��/iB*�n�V��!u��Y���@��L���ں���nk��ۑ ?��(���_�Pu���	����{1�C�=c������Fa@�[�jř}V��)?�0?3��8	�W��U��Pq�D�Я��ʭ���(w	���YJ�}%,�8$]^���I�s��Fݪ�0� �&���H#9�ᵬ +�x��%T����*�w+��5�T=w&
J����4�ä�)]_x�9�-U�WdQ��7S�!�H��>�O�;��Ƿ��B�-ӭ3�42�q�;����y��g�=����nsK8$��)�����ڷ�m�O۪'8�^:P���m�^^c�(�}t�6Q�Ϫ����0�,�Q�^.:�C/�@�9wI�@��V����%�}�>����רx��{ 
51  o�L���Es�=�"p@��u�L~Ǜ�kΐ&�)~@���f��'g�'�;�Y�U�tg�=��P���mXlb3�ˉ�Z�����/܌�cvcR������+��a8$&:G������ح��lre��A:Q�~�ǂ�5���T��{+�&���a�®q�6��wR��cy��Ό�ȀE*"�o��p���&O�,wPy�:���xI<�S�ڮb�'��j>!͇n�_y�'�8��t�c��� _�F�����0����z����z��4��+�q��Ȉ]��V+�-u������3c�`��Lϲ�K�x�"�0��P�y(���ER1Vs��8�Id���	�����e�aܧ����T1�:��#���a����=M/��
�����������5�_��������cT"`=An��cնX�FDR
��3�J�/��Z�xobC�Ĉ~`��:U�G.s��ذ?)l�ՆqW�6�L'��;� p��`�^Oa���I���0m"�I�#���X���2��R��B�D�gXZ���s���g��gϞ�a��n��$u*L&y�)��?uL�L��0X��n?�6җ��L�/��>S;M�#��c{dz��W����"@�pBߖ�:e��2_yvP`�<���E��ʾ�L?��������*l�.����
L��;1�I�zбc��ycOm�!��]�0��~��Q�Gfo��q��v�`��>�[��$6]��zt�x�9�<4J�}�MX�GCG����3i��Z&����H{�*��s�Y>X�,V�/h�?��?� �\h�{ ���
��ρ��w�2��֪UIVFJTV2��Q?3۵���&�Tsr�Q����IJѵ�!���u��,h"L��u���8���w�Y����9�Hk����w�O�Q ��#3�(a�%4��s�6߱���������ͬhN+J�
}"�>�� #��1��9]��2u�!껰tǮE�A���
M5B	���� �8FtL�|��U8��yI��p��O�����ŕ3�!0�#kҒ8�R�^�W�ū@��iU�@��UD��.�+�4:��ۧ���!mF$Cd,��	��_����Qu[�6���?o :| ��h8^�Q%�e���ǫ�^��՘�.���#��iu�W�+��&�Q�ͨ4�TI�6|9w��Q�9��}:�Uƶe�(��ܺb��NA��s�On�J0�$���{��d���n���X30�=��H8���!=~�#>�Q�gʕ�Ϟ	��_iׂ�S�Ec�yd(m��~�;�3�&�1�IZ���i]�'��l,N��!���켁,kx�+|#��F�LҸ	�oCC��>*��`/xK$����T�w�$ƉG����Y��JF�̨n7������\-W%G���o��d���q�3K�a5!����+��k�KH�gBJ�%;�1�B�j��4#W��[��e��|��W�ʒ��jȼ��6�,;�\X��4�!�O�V�=r��)�V���E0Hĩ��tP�ut&���t����R �Ys3�����U~����r��h�fB���&1/���)�5�^6,%^��b"�S(�P�M�ȡ�gu�5.�F�Q���R�bZ�$5�C��WSz��Qz�����.��^�6��G�����f�.

�2�\�Oe߼��Q������_o"~��!Ş��E�� �,H�}�o��_х.I��_I�O8(O�0� ܮ�C�.p���"���^��_�����w�"\>f���� Fv�R�UY)�ѩՏ�K��Z} �)[�2��g����=�\3�g��x)O�i�<�΀J�F�-��g��:�+kh�$��?��@�
��A�L�\�)`��a�����?���'�3�0��Z��Ȟ,�#:3v�y^��/�IJ"ج�pQ�j�;��!)[�+Ɣ�Śz7h
�{;��)0�SsDL���O:��XV2t,�s��w���P��(��Ƙ͊/���Ed�0��	mʈ��r���@���b�(]�]^��E]�F��tw���߰�ǌp��ZC�y���w3�����x7x����}�}~d�8��������z.���r�ѵDn?�b�"��֜�^J_R�9���L��y���U��	1(~�St�B���UA�2v�g���ˤ@��,��ɼ���/�5}1��\b��!:��Y%�s�y���*"#�7�����ס\㙼�Baކ_��{.VF#
U@�%WB0ިN�)�e�?�=\ƥJ��p�!�F�"�
�|Q���(��U*$�TJ�G��ԛ��8�TՄ�eti���oS��ЌU��):��N�\��}�ò�\�W&Ga�h�
����e���%9*"�P"d�F�"D@sK��G�I�l��h�E��!%�B��Y��аA5�a��4��14���K�5u	u+LLO�P��@�X�Dv)'-©�'Ș�4G>ş`ƈ|�����W�2�16s
l�������v#X:�pNG
.��GEX%p$��Y�<@�pU�Y�ı+��(:��R��d�P���i�$�O&����ܴ��q%�?��1�zDj'��#����)�ʷ������X��[x�u0����]gYS��Є�R� )-�B���o�"�;w�U&���;Lv�BH��Ы�%B߿P�<�Y�06CG��H�ʜ�ս�>���0.�;>�ܓؒ:���M��6��zϺ�o��.�k��rȕ#l>�S��q}�����(���ck�9������BZ�0�AL�D���i�V���<���2�1}��� ��g�d;�8��������qX�9���j��Tsc>Z1�44�3��#�2\&.��S9f١K&�s�
��B�Ո~�qoUٝuUSzb���5N������1Z��N�m-3c�v���Yo��g���K��2��~��~�_���:�W�(^b���8�b�_�S�zy^&oB�U4��ɘ.u �a�WEY#cl�n���!�&ɩ�$[�1��hI�wq��yR��Ccw���a|7z��ST�9O,+Me��1�!�W=a���^\9��Ȳ�<ø�>�����>�I�,���V&;��g'ֆ2`����J�4Q�'40U'��N��c�Ԉ���"+�CԀ�Bt���T�����=稠p_~9j� z+>�(n�abé��d5W�����J�%3T�����R|�V�gL���Ue���`U��[�azsi��S�u���U�S�������+����6�Q���ف�7O�Y�yjvuB�
# ��TQyJ�Ɖ�������}[�� �cP�V��&�^��;�ָш����DU�P�tOS"`ݵ��������%[���hGm���̙W.3HŅY[��C&KX����\mx�J��n-�N�$,�.�$O�b�W�Г(b�}�Q�B���������1�KkT���h�Қ�D����|([W2^y�6�+ͯ(�ﻋ��-�E����SߖRס��� ���G߽��l�~.�-X�;�]�Xk�ooYZ%�|�E!�0���0�����0���X������)�r�*�T;��6����`�P*a(,�Oq�/��j�Q��N�kZ(��?P$S�. \\7h,h@�P�7��Ŵ�y�;��L�,b]	g��R��r����`�{�;��(����74|�}$Bt�K�#�Ω( D;*�NL_$Q�i� 8�L g.�yʹP���N֨��p��6�����!��/.aM��ʤH*��������� ^F�X�zM���4ӆ�U����B(p>Ὗ�$	�9`A��A�M�tA��AY3�LaW�N0����b�.ZEC���g4�}t?f�M�yNK�X�E˃Q<M����4cD���"�7aa�3�Uy	!^�n&D|����ޭ���*�ͮ�d��
�^�aM�f��&a\,{��a*՘�~(��RĊI}
[Ctc;i�wX]�.����"Z��ĴrY,rV��P��KE"w[c,#R</�^���G�Ud��W��ȱ�h��x�����>*�=!�*L	�?=��'�P_ ��7���e�ı�TJCk����^��ioZ�B���hk�v�R����Y&�q��C`K+�qN�+�Wַ�g䇮T��#(
 �^x#;�=���Xܟ��6w�͞ޢ|
���۷x1_�ʶ)���,2u��
LTg[��7�4訕�e�'w
$嚸}v�oN���"��7�<h���U�d ˮw^��������^�@�o~w�T�,c��y��l��j�D���Pk4s���
!�uB9A�Dˣ:Y`��#��)~=ƅ����Ӓѣ��=�+�n��Y��Fܧ%�}�9y��ֿ�a>Ds�R��K�����c����Y3��[�5�l�F�Y�7���9�7i��4Zְ� �+W���i�LZoԷ���f�=��a�N��V�an66�t�և}�t\��_kXm�^�6kV�m��`�ըW��M�����p�i6M�b�0�Z�z�UZ�-�ڶ�a�V[�f�mXF˴6ͺժ5�ґiCÂ.Ӷ�	ͮ5�[�fs�_���f�e7������RŶU����f�O���f��YߢmsP�������f�F{�%Su�tX�m��z�mBϫ&�Qo��F�V�[�?ܬu �l�nn6�F�ܤ����v��2��*���ͭ�يW�WlmV7[�v�?l����h[V;�U���6X���+ �c�ٲZCc�nmҭ�e����a�Z-:����F}hT�Z,n�Ѡ}���n��V�[[[V�iZF�_�j�k�v�چ��!�y&	�Р�NͶEk�͖9hԌ�V�Ѡ� q���n�ҭ*n3�	k
}n���`P���k�I��iV�V�_�lSӨZ�A���sЖUk��ְQ��4MXLдZ�UT��MZ5�v��� ޖ&ݲh���ٲ���U��f�i6a����2��f�@Q�Gn�q�sG�K �-& ���ju������n����,c�Aa���vc80�4�)8�jESn��j5蠿�0��լ���Y�j�fhk�C�b�S�k֫@��Z������Q�Uc��!���@7]jVi���	Xتo�i�^7��� ���4���V�[c1�Z��j�UmR��z�e���"e05��- ���@���j�hl6ڴn4ӀI�5֬6�-�Y����1C��&��&��Ѐ���Zs����'��V��5K��̯���sBD~�:��_�V�q��F���1R���:����z��߮��7?�?Jz��پg�H�<D?%+{�6YY:��Me��y�6�xɱ�a?�	�W���Lr��no��Lz�����3}�����rC^æ������]��O�CדKo4^H�y�N�����4�p=��!�%1iYs����n��%0���TJw-;K��~��M^\���]���_�,'���m3�E��ٴ��LkSX\����a�Y�b$�,CP����6w����g�I��C�B� "��N��|k���6|5���v�V5Z� ���KףKo@Iz�����XW�r%Ψ���oF��p���k�J�L%Xo �&�O�	W�F։��� �x]a	�O�M{䘝QI�Y3p�QZ�g�8�2��T�qI�&411��@���ND��6)0��=�����7�ӣ�����!�u������1&,c�!��wd��B�[������.I̄6��gT�u�0��q�Z�8���t�?JӴ����%���:y
T�|7�pZ�̊�bw�� *��TЊo�;�f�(^R�R��ڕLy�eM��R�"5��X��]:�an�ޣTx�b
m3�������Cts�ӹ���s\��
#�+I[|�.��K��ߤ.����PO8���IJ���y������Z���������_��'��ɓs@�z��%5�gO�~j��W����e1�����K�'���,�$z���s(�xZ׉�����q3�������������<�����A꘳���j#����f=_������`��� K
�� �.U^	�R���Xc�'Yf� OKR}sO9"$%	����M��6FjE������^=��#�Zr�]\q��|ܾ2\:�N`~�3�]�d�;�^��˸h=cg����o/��^U���d�Ȫ�9�.bQ@�7fz��(CG�=i!'���V2����"�t��"5��a�m���n?jr�Ef��p*2 O����<<���1�0xwz�M5�ˣ�W���׋uY�$���n���ODW t���<d �t	 �ʋkQvBB�N��J��'�3xѩh,�E+�Hb�����?��%F�a�pV��(�I�;�1ؙҶ��badq�-p�_��>���A�ȁ\ł�:� I�JXX� ˜�F����xuQ��S!�[;P��Lq�W�_d�W2�f�U�ff��@Q�O�j.$�\�\ͅT!��+��9��n_Vm�,)�J���0�o�.�X�T
<X���>B���CR8;�������4�c,Lh�5��)6M�#�o�d��@(i)��f��tfeM~\���"enB:�HsN�3.W>C!b�n�_1:&Bvi9 ��;�#
��A�w�z;�4p�;���Xa�s��yI03p5�X��0Sz�~�>B����y�	����QZ{��Ȏ�����Y�Cj�����t��:{�@&�	doVg/�
7�����gTJq@��P�0���Fdq��x����;}���*��?oc�%�alzײY�8�^!���}sCTM�����Ҁ�խ?��)[�����_�y^��eřF���vwV/�D�����r���_���Zz˒/`ZP�[7��Z�� U�٬�s�ϣ�/\������o/�ޫ�yJM�:�˭c����ۉ�����)��~^������V�3��qQ��*%߽	?wq�B���'>#�)��G|c��K��S�}XJq�v��Gf5�����5n�Y���;�F�����GIO�U��s-Hb�h{��4ܻ�EM�`֏a��ú�>m��&�O���"L��Zb2<���b��7�����u���7���v-�B�sۨonm�zk�i{s��_��X�U�r���7������h����()���,�q+ԟ+�a�Ψ� 3�\N�q��Y�/�����Z��M���|�:������hW���6۹��c��p���Xp�Q���d��u��|�#�\�<H�_��v>���t�&SǢ�^m��U���l6�����A� u�~��+�|�#e�Zjs�?F�h���F�լ��7���ߣ����=�z^��0�c�a�-Z�+Go���r�P��}�s��S�V��(�<Ƅ��=s�
ǝ�owV���
uQU}�v�#- _��Q����S��)�R��%�Γ��+�ߖ[����Z���)���X��7��v������;���O�7.��9�_��`�������]�9��iY2���ܞ3�L?�,ڰй�H��I�?�\�:.�t�wqZ��=ly�Q+W���5���"
q�:�X��"���R/�Dh	�����O�r��y}���)�9��ł������sÃ��~���m�V��|��>Gx�+�	��#������-��<`q}��NUM,� �g����(Uy��4X[q;��Rd���x��0	fg���X�2�c�+�H�"J+��ƌq	�v��8Tnň�1�g��,��#Y~V�^o_)_��O�l��^�M�{��h�K{P+>,[���z�����0�A��y4?L�䇯�w����:�=�K�Ȏe�ԒH,{4���T�����x�O*x�(w'0#7�䎬k�����ϟ0���������áV�a�@I�S4&�X4�J!����ˬ�8R����g^�h�v��� TF��so�_t�t���:���&���{��}<����V�k_����a�aEw)�&t����(�G����u�o��g���"����"f���K�����`_ƶ�Nw������&���?��j�}�&��JSZ�e�1O��H���V+��~���������'��>����{�	ˆwE���5N1�0w+�1�9F�u���V�x�<�g7�~����(�)�՛�}R#��r[}�<� ϟ�J0��������F���21ܻ�<���|�Xݨm�7͍֝�s���I��{x��RFU�^<�H�jl$�-:~al����އ?W�q)u����<�3�͆�f�L�/��>-m����-o ?#w��#SR�3`P�aA!�­��x��]���1�M��$�j�c1	�% �QX2��`7s*&߼�F��e�%/�FZ�Ϳ�6���P���a=�uT��d9�+3��&�T#j�)��� ��)6�ouh��w�9��~����X/���#�N�.ȹ����}�(��]S�;(��$Q��P�������S�%�I`�����WD7��J��.]��L� }2t�����a�-j��`�Z,Q|^5=��T����L��L�L�s�����ݔ��af�GNb�Ҁ��`}V����H�vU��g~�e8q��:S��>���7.b0 ��]�	���.�X�n�B�鲡����C�+�{_�y:�A�3�H
?���pz=�;����mGD�z�p�湅�8,�p���2\��V�#��ûll��/t?�ùۗ�0������*5W90wrX}ϝ��]�ez��4�L��J���8	�.��w��Q`��1��{O�M��z9u���R��ڍ<�ǣ���C�3���x����?���y��<��r�i�s�������=��:���h�/念���l������~���;�+�P������Dl�\��
?��vO�^�+��/ߜ�����1��n�컽����8q�9Fu�9�kE���Hi��e�������Z���k�V���4ۍ\��QR��=�����\������<�g�3������g��[���sv��ǋ����@o�tf��[ES] ^��0�i�,gžLs�P˹�0煹\z$˙�3�M�4�1��9'6f�7��s�N1��g����-��y�_x��,�_���<J��K8�Z;�9O�N1|
ȹ��kZ`���y�oJ��Zn$�y���?��z5_���r�o�3�����oӧ<��/'�gb��H���=�g�?��9��()������X�	t�����j���������?����/�W����$��W�3������ ���כ�v����@��ݪ�����r����4�/�.@��P.@�AOq���c����q����$�b��' �t? A��+�L�K�	�o ���a�(����q�p�w�5�٪AS�ʏ�{��Y���F��;�0"�Pƃ,�J�.w�Q�����ԆF��>�t'�'��ݢ�G9jK �A~��Ab�q&��v,��y�j���ۮ6k9��)���7;.�����VP�+�4�׵�5g̛C�ך�?.���x�-X0��`�/8G<܀/�w^��$|Xp��Sj0�/�)޹�H���I8ā���N#� r���ⱚ��� �O��1ua�΄�_�
��&My�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)#�o�Zj# 0 