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
� ��Z ��zI�(:;�"F�����0=��nc{lS��Ɲ�RVR�F)�x(�w~��8��we?�~��nq�L�LUw���JE��X�b�cE'N���?���77������m��Q�������͍�C��ln>\�'�����Y6'0�,���f����e�߿�O�?���`z�YV�_���뿶���N�����Z߂��X_[�'���R��_�{��@�� ��jw�hK{�m�t�`O'�E؋3�zYU�gY�DY�v��h��GQ2UT'��8�L���ݓx�$�ΣIg�I�e�Z{\U���k��0�N;���yU�\����&�0�����QT�϶�6�ؚM�D~<�F�0Q��`2��re+*�g�����TP�#x�݋����0����<�=�b��S۷� �&��E��iRh��fG��8�"��hF�t'�x���:���A����t#�3Ta�&�t��nڋ�4��hN��À�Fa���,�z��NT�\ē4�E�����:}�[���'w�zC`��t�m7��r�A�4c�8 q�~?�F���ˣ��z}�_�|�_���G=��fQ�`T�Ʀ�iÚ]Ѥ�azN3�D!�9
���ץ���q,�����p�t�w�%Т�������<]��|ۮU�������rMh'=���`�ۅ�2N��p8��/�P�}|�wx�Y_v[GG�ݧ���7튺���q�F��1�������������.�Iv#�l���㽣ӳ����ӥe$�X�ZZ]	N_����wN�xZiLG�
=|���/}�\7���KK���u|z����m?��7�T!,5,��G��k��6��/}�]�0�/=��[{��������Sؖ��NB؛�� h?]\���dp/fI��K�������˸ԛ,<��W��<�ݍ��0��w�;���B"jz�����Ue��š�掫�E��6���Z���ݽw 4q��~�j��{�(z���/�����t�{��L�\։R�A�S�jy�rbr��y������2��I���A�}O|y��q��� μ�G�����&Ow�I�%��:L`6�9�JQ����<"^2��²���=��e���Ğ@��?|�����}�#<l^���T������O=͝a&���o3e�n���5�A��v9�W������8��\֕n��LX̣��t���kmu���J��wp���d���eDHP{���%wr�!9W���1n�����ԇr@��+�P%�9�$�[U �̚T����(u���}t��j ��/��P�nT��w�ݫ��^owRYy��y��x���/�t��?��ÿ`�^�������5��|�KQv���@C
����JԀ�f�M����-����ގ	� 7QE�:ű:�Ѽ���`L3�R��l����� �=���g/���z]|���ro�]���:3-ζ�&Q�7��={V6��1������ٰHW �R�����`M��C<�
��M��Dy�	Kn";6�WW��E�
���=���4�
��0M�Z���w`��p��������嬮N`s�H�!{��;����nk��BV�(�Wn�F��VBj�h�I:�E�P��	y�z~��+�r���o���y�$�8@��k�OM	��0��!j��|�͛ 盧a� L�Yw���C�'��aO�����!�G���[�q�')H�6�}�X�s�߸���d���H��_�q6�:��d�$���{���Fa�[�p��Q�K����u�e�Y�l��oC[9�F��@=P���$��%���#�u,�̛�Je��-���-�	���!n��T�.`td�xGǜ��Ƚހoh������?~���T�<˦�2L�Pe����0���nd;o��Iz�����{5l�%����8��VG�P�7�Z�d2�@�=k���F2M�{�Q��zz�X��Y��V~�$��s:zw��Y�7�qIʺq�:KX��5dȄ�@�v�/�Ƴ�N��$������� �i�pt�<�HaaaG��7�
�J���J�SL	}l�������*������4�n?V*0c����I����W��U������kszþ�)��_{PWؤ�pؐH!4�g�</P'@��P�Lq&�a���Ԭ��0�n%���X	XzZգI���;�?Q+S�#.ҥ�8�o�9�m`���J��б���n���hcڿ�ep����<��O'�XU��m�V���Y�uǣ��
|�圁���@�K��o�=�k���Σi:���OR�|(fEF��p�0Eo[C�\�ۻۿl��'�����kx�׃��:��b%��;��+���K�H��G������v�ݛ����u��i;YQ������)�
�j��TY�Oz�kj�+��B3�r��ˡ ��eaQGv�������L�}{��� ���O�Ӏ�`�`���"�hڗYe�6U؆���K�0^�`�T_�ON	�e`�Y�}���� ]�&O{�!XD��]��z����կ���ǣw�2�kF�?�x,�_$�6֋�#0�X����i�y��e��Q�ZG@OW�$Ik�~F�)�}4I��dG�1��Dv`��؝�*�(4�N@+mQ?�*O�A9���x�N�M��PI���dK��8s؃��r�C�p���~����F�qߥDx�����ڪ�]v��f�i<Ƹ&f`�C�K�r�F���/5><�?%�xr=6�s@�B��!�����B/9�:b!�m7�ܓ��I4� [I��]��sP�a4]u��D�Q��{E�g�@���.��|.��W�d���t��831D���X1�w���#�ω�>f����[���z���C�X,�������{�O�V~Jj?������<�{ypx������ͬ��j��V��h�zX�r֥5|�������?=k��0��u~��i�����D]c��#$��_q�Bc���Q������,h�7/Qq���%���b����������(�չ��!5 ���"�6m�˰c�8+Y�������
���{��"/���!(���{��+���(Nn!Ȋҫt���0oJ�ԙ�����>Y]桭S�
9��:[��v��jx�Jך���o��tOqhZ�\+%�O#����5�tq~~��أwa?�~��o����9o�w��^_����Q�w�[��o�����;������-��!� :&�j@ٷ������D�;������4��P��o�k]�鍤��ׅ4ߓg�6R�;+�n�n�%�ַO�.�y8"�O��]��y�u��-�_������7�o����շ��o����E��I�2���
�o��7���g��y�w���{d�~�}��}��탷�{���즬��mҘV�'Ir z�� �T{�)� �����m����8ڎ�۔��[d2��I>AC�����<��W��f�����T�|�eA�I��?|*����ږ�jaRCǗb\�&�rvJ�"�sNG
�Ow��143eV��N"�fC?�4�B�G�U�Ѱt�uCN[ϟ;*iH�8��;�?�e]���q�=.�kw6��7A8l�e���]�� �k|MOH!��T2�9p^���	�(�)��#�m����ȋ}k�HN�����t�ּ�4�`B���oP�����X��1`�`��O����+?�(��?5�W��\#�`��HnJY<;��"t=ˢEd-oP�`P�ep�=D�Dݯ�W�+����M];������y������`�,1��&d}����
�H�*ńC?���c8_7'%��������_��r�%(3��3qyzn�W��Ho�
?���B��N��)G�zFY�u0���ᶜ:�/պN�+���;�d�~���4WU��&�����D~U���}-�v�������be�{x�jc�����w��%�a͟1��p..��3�U
P�y�=�"ϲ����e�f5�Z�'�89N�)s��6r��9����q�3���?�|�����)~��.���t���?����b��D���2�?U�?U���E���^6�F���O��k�gK�b\���]�B��E��`iN����Y���BZ;��_�P��h���k�l�Zm�fS���o��+�U"|�01���=�á�ܶ������nx%������>�K ��A�!)���Ϙ�gE�w~
�~v�dI^VΙ,z?�2P�����D�p�׾-�{��B������B��E��� ��jyU���F=�{n���cM�"$	&���i�����}>�o��l�Eˮf�(0I��^��n����꥗I�O=��v],�h�)!Q�^1�'�|i��$��ɍ�FAR9B�k�������k���.?9�nnM	��H._�u!܍��-k��>:��6�}��67���5������-���|�����?͆�G���	}������7���Zo����M�@O8���߿��xRz͞3C8�G�_���G��F�h��{E�3d4�h�c���J�����8���}E����^��^��{$���W3Q�qv���%{;���������Ϡڿ��o%����R�Rh���~K���-���*��[���ˡݮ�C�-�u�o���r_��r_����`��t;�m��F��L rS���9�wY��[�g��$�oI��I��e�'_��_���\�~ds,�]���$@(��!zŝ������~�H�a�~��0U��"�Q�^%����޵�98t|.o*+�����l ���# �++�����_�������3�^R�[�;4%�E����.�l�P�D��9�"�D�A��<�_�� g�s�g
dw�ٟҷd_��i�~���l�p	�B1�w������,}Y��O-J����)�|�p-;n����=,^����S�G~<y��P͌�ц��n��K��8/~�ev��٩��N�u����&���.�-F,��޴�eQ�����o����6�0����b3o����z6o�7LMW������.&�����~��(L�v�γ��5P����5�W�d:�[��<���)�g�7�eX�a�V.A��������n�O��U�������7��|��I�tʷH�ۭͩ�4Ŕ�no�H�e���t�1=��S�k��/I���r���t�)ʭC0W��M_Z��t�b��d�j�򝙃xsdf�4Rw
�t��rt^/*H%�^�����Qf��[f�'|~��o���Ɩ�����כֿ��6�{�Zm�ol6����o�߿O�7o����o6��H-r{<��p��,�,pI��~Nb�^�+B;��Xʤ��L��j^�N02�N�Ud�;��X�ɝ�Ͼ�x������u�������N��՟A���lK��.:�PAKF�]��.�MO-+���D�/{`ß�:Y:�M1���}�/�����NP�5���=��[��Y8$��{%.��jq�{���l����7�x��.�X������FTw�k�~+/�!� �������!(�^�����ԝ־ۊ�:�m�@� �spZa|�[E���Vh�>��:m�>�o��O�-^�5�n�8:>�}�s��b<I{��ԁʱ#L?�&��es��Voց��x�nAc���Q���i���9uљT	� qpO]��(r�J\��Y/���K�N?�
����?��v�I���U�9o
��,u1�-M쩛�qb*��E�&Hj�([�;^L$���D���삾4���M�=�=�ު�O��t�O.<����j��]�ol��pv,��Ǵ��/t1�1ק6�JE���\;�Gq�e��104��g�>`�&��6��W�b|�Qn���9���]�y3�"����������/a��b�=�d����\��R�VXc����F���t}�h;�O��S��:������4bg��!�9��Q�X�\��szx��'�P��"�t�=�����hoѝh�w�8�^�g��fǧ�?`��=���i�S�es�,�ug4���J�"�p�襖?�O�7��ȉ�5�e��y��g(zc*���iN�/�oMg�D5������f����+�yD���8���u��M���P�����Cs/RG��Wh���I6uh+Ż/cM���S}	��ֵ��\�ë[oۻg���v2>̝s�U1� �����������z�/T� ��)���D�҈+��L!R)��N��v���k����d��|0e���r;��$y#)��
O7��SL�UA��V%*>49p�I�5�%N�A|m�pJ�Hu�d�		���o���%���6e�zݎ4�����J!������Ӱc���}tKj��I�;qM���mV�zt�G�l"�0KA��a��?�$������ ���;A�dl�W���W��W�ZV�����=��I'oG����ۜ\����Z�%�[f�:���\�맧�~a6��Jiy�$v��js(���xze��RH5,�����TT/k�K*5?�\?�a�m�A�\�04�"D����T�J�H_�i۹)�6��K3n��h8l�<�X�`�wh�@)��9	���WLάוCڔ3+31�N(p��d{���in�}:�}.��5�}}�iWw�����g��k��#0y*/㶄�����=��y��֭���h"�W�5�͚`���*�8�K��c4Ͳ�f��<P �-�φ(|�7�5�2��Bl�����Ղ+��0������_�gOJM���H:�i��"�u�����x:��28f˻{�g�c%}�U��y������x�l�'�Sد �l�?\�� Y����'+��3.d��1V��X4�ݓv�6���`q~�����'�0�� ]�)7p�*�̸DW�F� ��#A�D�|��tv��yxˁp�P�v��:�?@�_F󮠷S3xTۅT��^�p��,�W
o�Z)��C�,����[zN'�5�=wy}�=�����n�H!{V�P��q^��'~[izvr�_hޢ����(�p�U�k�����'���d������,�S:��r��)+ۍ����M]�획
c|uzz��ϼ�`ӓҦv::?�N�֝���D�l\����*��n�5'c���+�'��T�f��	��J���T�����S񍏹g��sO��A��D>l��=;�W�o oѯd鵦S�c�����|@H��l}ŕ�^��sAn��i�4�D3��m?�fD�[�Pb2�����R�0�|����p��Ǔ8�����j�����\��nџ��M���)r/w<����K'g�+ՀFH��/���Ӹ*|��
i�����kr3gE?�<K;Y fo6t��t_��i�"4�t��Q���/P:���,��,���k��O9j:�m<|�ѝ�{��	q�����>E���D<��+_���V����q�on��\���}9�~��.DԓFht*�'�nw��cv<����)N��ZFz2_a��>!k��RӗG����5�ʥ��Կ�-8�s��1�枮�R�L����-��n6FMiZA��;��D���I����h��;��T<^�{�y�x�/W���Z��'�淜I����7����Rn����� �F�C�����̃�����ӌ?�aX�9K�tE�����J<�#&�D�o���tz�+A�IB*G���������1zY��?�a�)J�b-�0��3��B��	�����eobAy=�|�.��G�I�����g1ޞ�]��	o��m��=��p����]e�36t���tL)�]w#0J7��؟N{i	m����ar2f��ZߚӖ����>z���|��e�R&	�n�9>��[y�c�I�k��KݫN���u��y#�c-8X���G��ĝU���3mO��������ɲ�ģ"#���'����t��e6��i�!��J#�b���O�G��6t��Pඡ��%-wn7��L�a���	&�d߻�?{6o�E������l,m��I4�ӈ�C����a?JΧv5W��?��Fx�@6�DU,�""K�cHo���P�.���G[AՆY��K��5��0[�����h���M�V�ːN'��s}g��`%:0��$�����l��Ҫ�_a�Vk���|�²vL�*��&��{bq��2,9���G Č�փ���G�U�t�����g>!v@�}��E�g~݈� ��d�Tj��n�E���x�[���ςV	�؂m���S�,X<oNN_�� L�U{
D�?�%��ھ��%���<����u>O�4�/oN��%��y��#p�{���{Z��y�k�3�����s�ݳ�ns�y��X���v^�_|ϛ�S���ɑx����+~�Ǿ�?_�UE�S0���+�Jh��<��NIS���Д��� ҿ6>/k*Disx�5w���[�5��<�,>bG!�O�4DO��:m�	�K�(RXTCNd���lCN�kؤk\���^��.Բ���8 R����td�f���t��5�0�`�
 Xq��Ux:sߦ뭼� 2��ȕ� �E�H�<H,��o�ʉ3�s��"3	<>������/���!`�	� �T\��"Y��E�`M�A8�^���ˈ!�^F>�ڄ
:�~v�c���c*E*>�;u4��1�@���@����A��
���k���Ԟ�a��-��<]�_�����R@���jzX5��΅�|a,���PV ��R㧵��(�����D"��߁�-��JI�j�#M*�Oŀ���}P3��B*���_ղ���b0����
' �hH�b�F؛k*�����'|���l?�'_q����8׳�i|a�����d�#�����\ńԵ��4�����kN. �q_����+(�4.�&�M�Gi���jN�:t�'7��(��i'������%���4J�Kjwe�<�T�����l^��,t�c���9����`�O���Ea����	���K@�0�T��r{��<�k������Z�D�Y�{�ay	N1$g��)�{$ʠ7T3hd��/��U��6��EG�~��A����ܖ���$;�FV�n�YHۯ3'Z�F���=v�סð�ړ���b�7X��q� ��.F5�	��"�>�c%4�R�w�7V��4�9M�ŋtrNz�f�)O���M��{�
|LB|�»�-�>��>���Ϝn�����m�&��FW��PeC�dG���a�����/HE@h��*7c���@�MN: z�c�@+��K���E֣�6E@���X�>�z��j>C�D���=��7\������6ɝ�t���p���ɵ���sVo~�<�����s/�����2s%6{�K�gox��ds����1[��U���}j�&O `�?'anQǅ����9���S)I�Ƀ\�@G��:�W����yQ5�����4��;�a�!R���e�V��$��ܴ�Jn�yA���y���s��)���Y���Rz��p(���/� 0��j��.���p�{�JjFm�C��5e¾@�A��
�LNt�vݷ�D�m�Ŀ�l��W���QW5��g���`Scaf���B����"{��h�u�T��wuh��#Tvʫ���>}UT�"�D�)s"S�d�ǜѿ�]����~��p���w!�;�K��`?�[��^i�r�I	��u7�?�@E�d�a��Ϻ�yW��2P�@�����O����J���"�-���`��ŒF�]h���Q�w��
]It�0��ouR��	�S��-����R���u�Y����m�t������7�ař��_8�w�+|�V�Oxc�6SJz{njy'N��9m��!�w]O��,�;���x�w�n?VN-j���%mQ�Ik��,�[�4_�ځ��4�ێ�%_��KF��uӠ��M1Qtj�<�l:��m�@�8�rWG�m���[����9U���s�P��s��@��c�&�����,��yu�������n��$�dp��H(;e�g� ����K��uu%����Ŝ�;�����z5��w����Ø�`-L�K�K�>�5��We��[��"�>)���X��k	�Mq�d݉����K���}�������,��kku��Zm67�V�Im~�����_���{;탓�W�.yۘ���Ս��zn��6~���7����˃7�e��}��WGo�y(!�B��|�J�zU�=V�%�Z����I|>���z�^L�H����%�~�w}�Ѥ*��n]}/%��Y��N��վ�&W�igx��(��n����i,=<�w0�m; 5�1���<Hxs�) ��窂��2�����u���2�Ճyӥ��$
G�v`�SPJk�(9TG����C�!hgQT�#*�̿��2��
��W��G������y+����:��c<Q����e��݋�����e2xZ#���H"A�Z8А8���-�Rϯ�%��M������4Jz�N�p��(�cP��$���bݓ�I8�զ�=h��25����Yҥ� ]o� ������h�͸(y�`N�)V[��?�����0F�Kyü��1���"�N���+aH���Hg��C��7�Bؒ�g0�4%Jx�!���H��8ĀO��M�n<���꿌s��v�'1�SU� �|�>�(���C(��ꐐ�yƧ�e��"e$�0Bu@��8�TM�a��(�ݴ��!��MK/�!��N�W��CƦ{xW����!����⛳��{Ll�p{��J4��9y�����h݈�e�I�8O��[F�W7��W�F8	��/�8���D��<�|ߴnU'� +���cC\��M�!�aQ�,���x�e{بt�\,U����Dߋ�H��Ex0,|��v	�͑0������C��h٬;�;P7ഡs<wO�ݭ��Lv����D�O����`2�xFxÝ�++VOvʑ8^R@���[�1�U���T6 r!�B�����x1�_�&�a��A�Č�h���8nz��=��l;Xn�(��t2%Yò��-.R���
�X�2&���y|��n�s �����[uW�5�;
��U�*�zV�ٻ�,ﾞ�_�&L�|r���#s�JL"��<'(K��h�w�s� ?f��i`:�`�mw΋'��{$�vZԉ�(&�8s ��U^EVL�ԀQ����u0�Tpӣ�R��lxE��G��� �L���~�pa�</�=��P*����̒�8������l�p������(Lf}P`L�tYJ\e: e&�Ox� �4B؜�aR a� ���$+�ȉ�̼LeW@�tN �a�$�5tpK���lBq5��0F&݋ȪhO@½�c�9���$�R&�9D��/����Y��:��?�g���;��}�B�$El> �gkc��k
�K�N'hf���	���:�%��؄e�%�K�ޣsT3?����
��5��SRzYWP���!�����%�QVii��&��Y��'8���PA�l�9P��:#MeH:�!�1��|��Ft G;I��D��n�N5+!�
Ξ��ou?>'��Lm���:�u���OD�f��{)�gT:hk^�1���������Gb��L�.�
H��#xkS���й"05��)�&��e�0��F��v�0���a� �5f��X�� D.r�4.��y�}��j�z������s�"��|[�}��D�v���������	6^��y�8���ʩ#c*�����]�n��\-����
7g�yW���K��RCG�m�eS�$�bD����	��f��{�hwب�>�M���h@��Jq��+��3ia�K�q��
��
���QV�%�X��#�Bjpy�l�0�J�F!��H <6I�˙�A��c�v����e� ��~���

Ld�V���AU0L��Y���v\�
�e�D8��R��.��P`B����)@� �vi��WE{�+Աۊ��R�n
��>�*�X�+1}�b;�	z z��l���;<�̅<�{D&d%�|$�N��:����%�@b �#ch	HƑEH� ���h;�IW�G	��R�F��M@٦��c���@3Ie�8�����К�<�@�g 	<>�L�p��v����'�an��=�ng�.Ţ+'d"�b�<�`���e4�� ]Dyr�}�{^�3�Q�q/ �YC���X�l� ^�ΐ �B>��GI.��C]*���:��Tuy&5�5�����(���/D#�Ml?w@@C�t�`�1�\�}��RT9�J 6iLyl����ck�
��CרC�����Eh_���]a���P�����Hl�	�+��I��`�6�I���Ȥ�ڢ]��f�,���ZƬ�
��L6G���c������N6��0�+I10׋�$�@MH�VzLl�ʚ0�;������A?H"�[��"2b�1N��	� �h֕ěv���2��أ1�]v�j:��t0Tv�<��x[���-�)
���/qpo��r5�z��U�p�S{i�u���!����1�a��"}���!�;���^I0���z/��t�
���(s��a$Ѷ�Ά��C��f�9:C^��; ��+c�(��ݎ�&�*�E��ktB�Tg"S��t�l�٣F|�l�l�VHJ`ƤC]zg9\a�+���HH`a�/�� ��ϙɿ$� �J�7�r%�@�<p���(�Ƌ�ֵ����n,F"���/n} 5t�����Cƃ�´���b�²ĺ�	*�QT�lp˥�釩>#�������aF�^
�߃���'=<�Fk̨�$�1���
�%$!̍,�k���'Ȍۧ
��*�%�}<�&�,��:��"�my���������x�D��x�$�aQ	��� �sJ]���=B<}��+��Bs;#�l�]Mv�L��O��c2�W�C1��� K�*�D�����$��=���ς�v%���i��.?���H�	�Tִ;k�Q:�@�Lr�熌�2�/�ےG[�yZ��10��Q$���%#�M�(�{�]e5�G��ڥ�F~sq$	���q��*	G|-r���"ߞujL�0m��Bu�`ⶫZ�b46����9F�D�d�2)�ѷ���^cw�;'�J��^�A���.~���گ]���j��V,s/�k�ط�]��-��U�|��3���3ng�V������A�fd�Bq6�S�W�@QꟵ���6G��v�?�@��E�F��嘮�;���M�KR��[Ak@���g�0���ak�R���8��w^h���\�V�޹��ARPΌ0��:%9mF|�D9���l*�����$���<�:L��<�j�D@�?.�!��̢�s�ۄ��� 5yD�qD�Xl�z�r"(`�b,��kcϺn���D��Z蘷{�9�%�� DC1I=Q�s��&v&4FW*	FW� ��ML�L8_��b8��)� `\��CJD��QǸ��WO,[ǑC�:�2�� !�; ��+��Gn�[���3���@�Bb]f�6؉9ˌ��dn��*��ȥ�a�-P'��~U�7=b�."�J��ƮQ��=�-�|��q|���fQ�N(G�$0&FEO`��E�I��c�&�g�Ɠ�l�<y�"H#���#��(1�9z9�:!uV��x/�	�`H�4W�ɛ��0Úՠ�g�^G>��o8��F�1o���H����u_��A�-�R ��i�u{F�Ƥ]̰�A��s&`[�ƴ8r�B��U6i>$��	����h��lj�n���aSt�����q���v���|�x�T��E����D4��K�<�$֣�ٌ�`�|^ɱ������%,Y@��dH�gJ��|�	iޫh2♡��:��D0K�#����A~��(��xw�4�	%�LEd� ӆi5���5��.d�G	rW2"�������Ty�sLu�T��� Sff�YX����zug߾��Y;�Ps%��n.�KOL����SiX��M�) ���f�g�r6�dc0�9(K�a���pr�l����^��:��t|V��!��)��,�(����W��A��Ʌ����~�T
�UqaAmP�I��` ����k7b�qe|nOh�y�|s�'�}`�*���7�,$g�`7�k�������Ȣ�]T$��'d�1%ͣpԎB�<`sBh�.��ֺ�h�o�@{��\OAQm#�36w,�����^�S̥Z�"���zi7�(V�\��ihA3W�ms�.\!啽~(컀�+��XJ�&�G_�_GABJ`��+,%���g�E�vz�$ŕ��3\I����
��C�*�UH�#�;=�� ҈�D�9�"��!�Ò� �71���s"����ї�PWd3�E�eQ�3	B#����NJ`Pu�cN�n���cT{&��j�A�vŇf�EI�hU��<��w��6'1]��\��P�.�XP���}�ť�V����Jb��C�ę�iÕ�8w���2���"�M���N��n.�z+��$u����� ��_����en��	�F�K����$2�iIK��F����^Xf���A��C�8����FW�u(�ƼƜD�z޹�~N�{|7����'&"���;���>X���:B��:�n�0����x�h0�����t8㊲!p�tD��y�H�
8!�$����H����H-�h��̉R[�/#��U3������ ���'�X�$�e�t\_�^6d0����V�|����Y�f7�4BgK"r�����D�����PVD���ř#K}GI���H@fF���pfD��\A��F�1�vj�E<��#��,��0=%���|��c��9�I1 ���j�\e�K�Y��i�E	��TI���$�~%�宾�k+���&�?�� K0:��D�䣵退Nȳ��w�s�Lm��{�Z`U�gm�0��_0��*
'�u���t�OZ����p�5c�Q2ٱ�N3P'0��112��-���)�dRB./�Q��mY»�c(@F$z�\�c��x"����CUGHIs)>J9@�F���4����>іrc��X�Q���0%٦��y���Q�u�G �:�TL��	=;�շ.ݥ��g���(��*��ÅCLe�Z�q��J�(N��0#͌�Q�c�a�6*B�~e7��|�,C��1v$τ[t���ձzќ��k��3����#3�'*bPi9����ª%c�z��U_��bQq�n~���ezȝp��ل��L,���$��wd�6t���4�Ms�X��J��V�o<����#�R��2{���C�[o��>"�!�.s�@�Ϸ#� G)f����w�?L�B��2	*�Z�Bs�p.v�X�53H3�IҌ�u�}�*{G�����o4iL�
u�$6�Ȱq�)��͙gMf�k���fF~�qMjӴ��r��I��&88�8a#J*aܕD��� �
�|��r'bn�'�!�$�j�#aw��o��v�DOL	�H� 9�Gg�h'`��u{���	I����߁���1��M)�B'	��h����P	M���l�F5ц��t
�xV�f�B�4Zf�-7a3m\���,G q�x�h����`J�W���:rlB�$��=9� \��/:�4�fAb� 	�J�w4��h���y���t֙�g\�:�QX�tx�x�)�-�����6n�>�`��j9)Vh�TU�C��WL�Ƥ+��E����4",T>��9�Q͹%t�xf�6�:W<	� !��	7����ѣ�%�>��$��#0p:f�Yv40�02jd)�s#׋�� ��s$�z
���iFW�x���@�.�O�?IW�iHc��d�Y$	�Cz.�	��y;l ����uz��Ŝ�L+�eU��n���@U΁Iƺz]1z����f�=�98_(*9�U�n�|<o�ȁ���>�	��kt�7<�
�S����`�4Nf��0�(�֡�[��V��$HM9uQ��0`WϋSs(�ى����AH9Ls��$����hI�U��X������8��f���4-��.vmn�����-��L��a��rv�d��]�=�C:�����"�Վ�3���W���,�^�4`�RU�Kݛ�3{e!&�R�q��0�����H%Wb'r�ހm}5o�����\�����O��$"�p������wU�a0
��w��Mʡkּ=�S�I7s��ѝ d�q|�zŤ-��w�yS/f�A��e.8mң�H��:zD�w�rn��~h��mc�0q�"�d�*��c�9�	(

c ���	D��E��DI!��*�M"�g���E�EҊؽ3���X.�tH�hr3)Fg8�.f7�E۬��;I��$)�s��묵arȹq����'��e�a]��.����Q����	�A>qNlW�][����YAS�Ҍhb�`X��蠔���[�XlY�eN#�P�8Om���M"7�i\��M}�iV�q�D�|�$�C?�H�=r����C�@I�I�MpLL�;H�n�9#|��7��Ӹ��#���0g�9�ľ�'�j#I��=`Ϸ�RwshM�V�{N�z�*o�I�f�h�8�9\U�]��U>��C0y���v��&İ��,5�J� >�Е'�/�FǳéQB6G�3�
K,ϡA���ټ]���2x�8�Y��ǥ�`.ӻ�b��b	���0ŪĎ�/B�����(|�K=���4���&y[S\F:��S�tA};w�2:	�X��� �*�)Q��0�cB�2���[4악��OS��l�cW�Ț������a|R:�Y;j�I�jn3mn���uL�86�M�l�\�e��8�g����2�LE�]�6�p�}��h+�����2�9<��G��v<�����79o@)���d0��y���Ҭߞ��S�BG0s�E+�W�`蒎�e��иax �)�d��[�ő�Ɩ3��Ģ^�0p0x����}�uᮄ����mG�
��lAb�e�M����q��F	�aE�6g�R4A�Of����Q��ٙ8L���gV#����@�y�U���mn%�fE�p�����@uF"�i8�֞SF��ɕ�N$'���5��AAJ)�]�����t s�\[>ۄd6�'@�C�V�|`RAI����ND�����[�`���O �Q�=Z�ǜj�VO(�,-��j^�[�ƢV8CU2˰E��Dt�u�B5:3�� T@�,8 �?���G[��hW�s��`�D���	ʻ�i��y~d�(5�m�Þ�`�]H�μ�>
.���A/�h���B��$�6�0S�RF ��T(�_C�7��N���F�DQA!��)�F�o�����wTU+T��.�a{��Ix�:��D�'��0s��'� �Dݸ�LW� 4h���d��	�#ܼ:�fN��ZP����4�(ӆ��i�TTU�)޾�a#����S�#���j�/矲��"���>��x7{�X	������P{Xб�o�Ƕ���x�$���N��P�C2�KUĩh�Ԍ丫��+��|D�_`x%0J(��3L50V��z�w�*�}.�c���g��jC.#P��U<�}��i{��K̒�ZtP͠Q��0�W��|`xkU�H��Oe%�<�!��`ۦ�u�ҭ�8Ht�T��~�fG�3���Ty�c���3[�Qd���&�@ϥ}����k����Cݙ-T��u��d|�p��p�A�s������|G�q��]�3���R��)��*t���&��)�準+�1�"���'�Sw�
�:�����Dvij*���^�V��)�e/�6�8{\'��X.Y��:�P^��q	�;�G�v�O�(��t=P`�t���H��[I�fȩܦZJ1吼��2K"�!.�$KN� �a�x�x1yC�m,9�Q��h�Wz�M@FN�;�O?.� �s�;��Il������uEK>�W�~%9tƙ;|���\8`Z�� �+D`Y�=��t_Ԕ[Z�IQ�w�K�h,_��_�%*Ne8Ϝ�V~Tœ��Oe��[�/�1Q���U�-��YV��P�ٌC�y����T'�Zd�=�̘/�sc!�Y���k%��^<4�l����21'jr�+�$�`^Y?��X���n�d�m(C��"�Q49g�q�}��]�A�y�:k+Q��I�;��\�2p�L�Yb�}p�	&����[��s}ހc-l��O{t���0�+�t���G�8�n��F��y8�q�)������:w
�\�	ՙ �;%�Os���ȟ�Q��)W�Y�m�<%&T�#or���>sG�Q�ӹ�y��WB������X��;I�¡D�R'��Ooٱ��1��ҕ;c�6�;�̘^/Y�K5>��O����>x�t����k#>puilv�FA�,���p�L�f6R9�p(��G��$^/�(�c��TI�YWG���.9���1�Tt�MNe�=e<�t&�Č�	i�0�W-��V�cl,x�o���&�!t��v�;jS~Ϝ!�Z�b8.�%J���;�<Qϩ���S�U��4���aW�X����U-)�x��'����]s$<(�L���A�B>#-a�<R�zeD!ԑi���!Q��
��%��ˎ����;:p�4![̥*�+���M���U�3�r��i�c�4v�e��$�z�
5�g��w�Q;JXH~S~ �N�=��e�N�k�x&���}"�C��\\҂�p-e�s�;�r���W�X��p�2�y���,}�3���P�X-���T�'�L"��� �F���{<e���/��T̗*�R��=Y�8]6e���K�b��w%!��f���n��.k[�u��B��
Rrk�@��\�\�9�-�K��{����e9��W,���S�C����P�����TWa�E"�4b
�V:�	ƼI}.�w�$�s��@�48��<!MYؒ�Ib�b�&���Q'�U�3W���:�tnU1xΆG��B�F��AQ'J�!�j� L	w�c*�-���.G
n���i�>�.=]��XD�( V<�K�Xt�B㙑H�)Σ��+
�ȑ��*(N�rPpo��3a�K�\x`|p��le�����n�G��9A�p
����h  �9s'~�d��qt�$�uUf���Xm�i&�W&���O�9&ͼͩ��d�a�L�Z�B,�j�t���?,�C����Q&�kY����B:�׌M��4p��ڟk)�餄J��~��\�L�����\���+~��H�)m 
k+�誂�G&1��trU�[-	x��b0;'{�3ë��K�7_X��lQ/[o�5k��ғ��bS��t��VH�7��Q%�R^���ɒ�	:	�$��AR�H�qG��8x�6���8�Q�Sj
҃W�BJ�h��	���|a+�}nyج�UuIsê��9���v�v�V�X�K>y�O�I�\�?��4�D+�;˜?Siߞq/q�|����0:��)�I��k�E���z�cڙ��-��H��E�#�qM!P��s����eh�����=R��	�ޙ���.-���I*&7�����N�Ș ������t0n���$� o3*2�.������F:�D��Us��ŭN�5F�އ1�O7s�ґ��r���Eѓ:ejYۇT�nF�a8���v�+J��0�wMZ��,�v���"Q�b��74�ݺU?���h|��R�@-���l8�=1��W���t�}R=4u�����_�u�� �3*~�wi���%�����u|w�`�c	mǑ
d�`��ٳ�0��#�\*��R����h�F��$sх�%c�S��?�M�ٙ:G�?<�V3j��1��j�x/E-�t����h�|���p$,�Q�Ohi��<!����j,���d���.����_�]� gc�S�)�&�{((Q��+0�@���\뢺��Ux[�|�n4�=��������I�h/�?Χ��^6��8��q��ܻ�r�DӼ�9�U
�M�\��F7aLO{ލ���0�����!�؃���m]�+$��IlN�J֢�z�q���$B|��'J�t�_gB]�K�X'Ft;q&M����J�R����[$3,,h2��\.9�Z4)����+�� ����u���z�{��ݥ4Τ&ߝ��s��:�J�00#�� �#Д`���n��qFgg<���cT�z�IȦ�u��Rh �2����е����oX�_�� ��WV����G�������L�)~ڗT�hrS>�w�����6�+F�iA��e&�X=���-�Nlvn���;�CI��(
9u	O-KtZ��B�sqcNд$�	��(��m�Mj8��;Ig��}�V{'��P�k�NP/��ut|�����N�{��O���}�z������������vZ���j��oN����ѩz��}������:9m�{�������K�sx�����W�������1�PՀ��Eu�:>�k��8����1�J��]Q��N_�95�_ ��_�v���G���~t�>9� ��0�6��w���f�RU�����߃�A���j��I[�_��w^�����=�^��b�� � ܵx�;o�[��ћ�Óv]1
 �x��/
f ���7-�0^�e�ؗ3� �	��~8|�"潿�!�V���ӽ��*��nN޼n�ONh���W�o��u�>~��Cx8n���K;�������h����&౯���c ��"}�9�GL�����D�T��[/�ۄh�&�w{00\=C�	�J���0~ ;T�w�^����m�p�X<[�m=?D�<����x`�%\��������C�g �lW��Q{g��߁� �U'0W\Zx @T�! q�:o`# h��;�e�w�(���	R`��:m)1��������(�c���7ǰ߰��9y;p�W�K[|�x7Л���Eko��q���C@!�$tV�[��T\|����y%˦����zK��Z�o�h;J?0�=�	̎ ����n��P�Iᐊ+�z�3'b���#d�~o�|p���я�a����
W��f��S:.�)����%;@gX�VPRx)6;�c�S>	�[>�	Y�>�N���<Nf�u��":c/�8:�M$��ك>"�qg����]Z�>_ֵ�tI�<�B�y��:�E��u�S�@�w ʪ s"Hr����Vb�� WNK�D�qN�3�ܩ�_fY�liU"#ٔka�ހ<�&T�b�4��fu���D�(�'�_īoV5�%m�K�(G��Iա8����N�_��:�85�y{��Fŧ-(��I���Z2�F̀�/�f:U����@����{��od�T�NSAcY�"j��Q��]=�?3�]�*[�M���Gt���ƛ3��'НI�1���D� �?��DZ�Z�YQ�cu�g��H��g���ת�6���6��{�O�=(!>7TQ\�%��g_ȁ��:|U�1ׂͣ��G��qӕ�eS/G�����j��}H��q��a9�*-ڣZ]C	�U�'�\-V� X��i���k^��y�����IĖ BXd���ɺj�#\�6��~f�|�RWΩEfq�� ;f>D���t:�n4.//��ɬ�N�:ݣ����=<t�6�""�;���W�S�{��M��F�]!�3W`n���v�dY]gKUs9}�J���L٣t�+M�Nca�)�m�b�n�^,\#GV��~��z'�K3N[�O�ߜ��p-�'����jz�W����~݂��g+:��GC����&��͡h�Ix�v׽�������ݍ.T�B=>�y[�O�V�t����w*u�'E��-��]#Z�d���'"�_�ٳՏ�Ќ|�
�E'�P1y�2d�5�TK�5�}�^aF����-�F�h�B9]h�����(����&��Ulߔu�
+�Ώ&��o��ٹV�54| V���x�6l���Mʞ��Ƹ|8��-L�]�6��R�2笄×CL��ǌ�Z�+9l�e�\'�QB�g�,①#��q�%T47�ܙ#��?��ѥ�E�����[� B�1l2ϻ�YBQ�+��`I:q���tShJ�b<�A�Nǃ����h�����`:�����㧗v�����v}��J}���nml(����&�����ᳱ������k�kͭյ�[j������'�����}f(R`(Y-l�����d�����sO��ŋߢ�/{�
�LD{�������N.�������K9�J7\�Ren[ �7��&Qr���qd�� ��|G_'�AL�t>��F�
�F��-��&N,���S�u�'�vr��덆��	'1a2�G����3:e��J׋8"Cg�><´1��z�e2���x^0�xL3��(�[?����MJUB���-�w5=<��r򺪎[;Uj�r�ee�zr�l:��m�-NL)P�H%F��F�$@=�D�@R�%�旙$c>x��z0�z6x�@�Rշy'��|&����I6�fIw�n�k��I�q]��&7t�-�q��95�%�R�X�q�Y����z]��pt���V]`}�^���X�����z������/�
Ǹ�v�s����Q��l܉�Ɣ�����T�?�@�j�L'Ѵ;��]����m4�`���e:���m�zt
����F]�̢N�j":��'\�:� �Ñ����`��(����E��z�@��׿������� n���G����ˢ�Uc��l𕢍bg�6�V�k�f��~���^{���Hal��tof�Dɫ��U���ޘm��šڦDL��Se#fv��=º�_~��u�Ł�X\����a��Ϟ�N��~V�)x#6o���v̫?�F�W��������]���7G�xaG7��6(��ч欖I���|���b>8�W���~7A��ԅ�<W�����kq�t��9U���I����>��	ׁ�Ƌ }�o�K�W.7���Ld��C��-�_W�7u��.0P��ʻ��\|�I8�	��/�����& et����p��*��3���R��q��&D����0��ԙ�d�4z#��G:�A?�Tn�d_��c'쾟���>���;��S�{,��ݳYҭ���]^Ɲn���r�k��^o��������s������jLGれ��($��+�))zN�Vлx� �0���<��/.���{�΃��䌰6� �Yܰ�o���~����Z����x��|B�&\�h���@�{W��h�WK�;P��L����m�j��?��G��K5��"9Ȍ�z�Qmu���:k�nonl�n~�>Ҭ��W�Fr'���2��]<]H7�����([�ƛL�E�(��asT��6BrE��<��`1-!�ϧ��?|9D���tѻ�ӝ�����oP��|#�y��]#Ƌ����'&�>ۿ�����IF�b����f|
::>�}�s:��b�-@��Z����]6��k�f}��z�/^�s���?�޶r�e�٤�؄�_z��G�ճ���BH';�{G�g/��Hy�y�B�"א9��j[;v�k;l�-�b>��p�������qo���ߺi+��U����ͻ���[��o� n��mv�s#(@�/,� ��y�sv�"�U�0��v/�W�����OQ?�m�h��?=s!�����
y҉
T)�SN>�77�?����(�%����J�'L�v���F�qI.Se����1�� �A��wϺ��Ѽ����g|-��VG��CP0�;� ve#��C��s؋��w���S�O�6��!6]@��$�t�y�(��	�s���u}|5L�8�!��r����lT�ڵ��5��d��/@ �V�x���ֻ�,!ی�3�%Q�)�8b%�/Qa�[������5 �t�@�+IE[�n�\ob߱B���l�sA�R����As��Ox�QLP��o�|�����!:U��|������xYBpO���{�ʍ����9F�T�����u��JE�����JQ�Z��rݨ�n+��e-��h(I2Qw��J����D��1�Ac*}��?�I�-�+�范�=�ԕ3���Gͤ����Nk�~9;ha'7�`�}x��χ�X�����'Bf�x��Q�7��m!\)��Uo�v�)4S��,B�tN�Tj���T�Φ�X�~�V���4���@C�����>��?c[Y>����f�Ĉ����=0�UaLs���A��$Pv,�)�k/�2�[������g��$��gir^�a���:�ν{xC��2B\�&�A<�(�ϯ�_�i������;�3pT�ǘ���2�4n*@���z�0�<w�E,7�g�J���]<ܑ�pSf\��
�r�U=gmj��7�͒r�8��&3�c�Tqa�9:�G�μ:����kGi�N!���3!�7s]����\��):g˱�ZU{p���]�/N�a����7�=C=�)4�{fO��.����ԃ�W�r�_�nĬ��hX+~ԯ�'�вo�NA4!|1h�t"b��c�n�0'�z��ؾB�0`��5��̮�ӄ����\�F*�I��ޚJ��	�A�Q�Go����=�JH��>9�W���$�i'd�Ȁx��JY�U)�[a��'ʜ=��a^�����	g�fr��u��������7�R�\,���{u����q�i@�%�D����U^~�b�`bF����`�c�[\�=t����џ�Gq9������]M��wL_�lΠ���������c/1t4��p��+�r76��zG4xN�x�� -��H��&Ab)�
s��.]���3s������X�� �`[�8N��K��+�]��H�e��~Y_���p���dEii�=�����hj\W��D'g���o������ SVґ^�t�UwV���D©}�V���8Ǩ[DC��Q8]��Q.��6,w�BO-h�i��!t���j��K;f�����κ$�L�L����bR&i���/���cQ��r�А
C��vQ7�+���a�Y]<ȅ�C�M�S�I�Z�)�Uϵ��(�|�TTtJП�V#}��n��`�:��T%=�*�F�˧�� �.s񑫗�`�,y����Y�kN8�/|Q;��_�2wZ�����@1�h���Ήd`:�N��g]�s����?k�W����/��[h)L�)p�3)8�WV������W�b��D�t�A��]�y�Nu�:E�v�w�p;��w�m����׃���qcW�����}V�B�e��Ӯ�J�q�������f1&�&�:���s"����A�P!�0� �/ܩ��Tƅ`��&a���ی�Aͧل���<��q�ˢ��w��3S�)T��yI4ݸC�]�R�SV������ͥܰ��3(��E�Vr���z�Oi���[{%8^�����;��ϯZ�_o��:!����Z�O�Ћ$`(>0	�%$��Ʃ�Ξ���Ԡq앍:�'T��ʆۀ'C�U����J�;/�����΁�;��~z���hyk��w"<�'��'X[k�QeV*YA�A�]�#�=��tv1������>1T`�����ɩ`?f��Ov�����'70�|�z΀��ힽ��/�i�����T�Գ@�>j=�����W�~ g��H?���O}s�^O��r&!�7���Y�Y������G7�+(:�n j|}���*�aNں1��JI�W-6�q�x�r�o�SX�������8Gu�����9[P%��A���rN��?
��=~%'vqL�l�
��7F��f�fSt^U=E�f7������t�I0�����%��ϧ�Ίx��I�UJ<�s
m�ӭ`@Fa�e��V�Aq�'+#����r{0~2������c�R��pH��Qպ�.��c��4�PD��o��=�B� k}]���t/"�ԍ!@�[�&,rl`�!ſ���u��0�\����@�d����A��1;�!<�j�X��A-��M�gs0��g�±����� <��D�q:"����D�	���堿��e weHΩ_}�A�na�+�o����/f	��0�|)t����e�7���2�BԮȤ��������~����g2}���4H��X8$9g6l�i��u#a� wU"�i�V�k��(�;��l*�)������.�Qr>ػ�C)��o^2UG--������&�ȥ)��΂f�L�أxFQKg���:O�ϗ����fm����[]z��8�X$��!�r�(�NAiS���>X�gh��H�e5��bQ*���ځz.`�9z�/<�=|w��\���qr�T���J`�Tٞ� ���-H)�Tq`�қY��p�o�[��H.���q%�3�t����IY�Q�Gʄ왦��n%\PHKц6L�o٨Y��\�$�6YD�Eݠ�ٞĶ��i ���2.�F�<�J�<���c�F@� 14�R$�7!��i���/���,���^��q��$Xz��M���d!�	�cL���7��?k�%.$PM� ��F�|
�x�KFJ�;+IMp;y��r8ll�\�a+Ƹ+۫u��$�#B%2;ɑ3�v�,0#��
��ex�J�:I�R�^gv�zB�p� A��Y�(ç�/�ַ�����\�~|	��:�1,��|ab9�[�28�v��$Y?�F��FRA�6�@S���+�A�@���y���Bq ��`b[ip�|=�u�b�\����~^Z!��i�O��c��C[(�5�ݩ^�O߭�W�澘�C9Z~U6SBo��V	�_�io�}pҮP,��{�|�>��_��k�������FsM��ln��nb�����o�~�O`��y��V�-��Jp;'D�'��j�������L�c�s'p�/�3��{%~���x=�_�����<���z������->�;����zk���V��Z��nl5W�ǽ�7=\;k�pU���(�ۊ6�a���}���뽨���{��{M v6�:���ǡ��=k�����G[��~�=�nD���Q�hm��|m5�ol�=v߶��6��n���n�o4�����6��kM��ƣN���u���|��������h�>^��t����zg��}��\��V�w��ǫ�f��~������׺�k��;���z��Z�Bw6:����G> ~wkc�q��pu��lum��[[_�lv�6�[kW��a1׹s2���G[�:�u��o��{�����Z���E<E��x=\��1 <�<�q77����f=W7{͍����G}����G����&v����(|�
�x�{���F���x����A�t�����\�<�G�5���p}����0\_ע�^��������ʏ�}ʊ���k����vW��no}c}3j6;����H��G�����w�A�'����o�nGܿ�s�%3NzL��n�z��(���ı�Yvҗ��P$$3�HIٱ��O������* $A��|��8M�L��[�*T*�Љ�����jA	�Q�j0_u���P)�''ά��`iQ�E۬[[[�֫���65��U��Ԫ�[X$߿�P\��ܓ���ݕ
���^��i�R�V{FϪ��R�zU������0`F-ٴ$s�W���~u���VkzK��U�6�*�F_լ��K������**�f��^��*�[Uk������H����)l\�z]�W��fm�4�ЀC��ꍊ�kЭ^_335�i��J�2�&��iT{���c���u�W۪кU��^�+́Uպ5���^�S�=�R7{�olU�= sU�4�t�ޯ�T�R�����\7���`�}}S����Sk��Y7u�n�P7��'�VF ��6���ZZ1kFݨ���V�Ѫ5z�
5��Q��`v���g�ԻQ��D�a��-��η�Y�z�^�W��ǪB�7a�i��Q-Ml7be# '_C3�z��WM�^��01}���(rL�Q�͚�J��ͺh~�u�}�<as-��+�����0X@���U���\U�om�u�.hY{i�R�+�Z�-dـ�a���`����7�4êN��X�t��.��]���`�k����f�<��׫[p�6���1T�R�n�oM`�K ��ҷ��[Qa��TuΩ�	�e5�UJ���#7�h�n��i�՚�Pa�нi�*VmS�6=+��zf�u6W��5���Vo�ܪ�֦��C;7+[�Y�5�[�
p5�쥥�]OƏX��
;�ާ=�����M��[[�ڰ�nn�w�Ɠ�p8�5�O�M]��Ѭm֑��a��b�������8oQ׫=�2(��Ai_UMK�,؁;�^�l [��c
��U)T��2=�gU�b�5��k}�9U����$e-,�(�Fkj��Ǩ	K�Z�a����W8��}<���{�,\v(��j��?(/���U�X6@��-��Hm���'���x�E�1G����P�G�a��r���_�p|����I��g����$��6
S�����w�SM�
�o�#�9^��鼄2�0V�x��S�om`9u�N���M�ҹ��k�a��7K<5��2�{��D"�w�rȴ��K��� �J\��@�je���eQ����ls��+>;(�2 �a��"�	?p����oKrL�kGx��vr�aN��F�I�y�]݀�7_��0�`�鱁��` �|�t!��mxs��TJ��>���&�ZX*���[�_��N@�cg��<�f<���~��J�o�FZK���/�W2	߈Ep�=�i�_�%���Ud���%��� ��m�����	<���-bT\�^�6�}��>t��"�_8!h�x�'�lHt�M;�D�mYҥ�T3{υ�c�onw����>������_�|ơ����^��1a��A/ELvW,�	^ 	��t�;�s��P6�7!�!K�
d�(i��#��\*��aK����0��lߴ���a��C�*<����Y��8�09�R�b���^��,�7��#�Cf��@�C�ʁ7�c�:��0P"⛎P*�C��L9M܈#)>c�w\�GKVù
�s�=����[ī聾���\�?=%�0�r^J7���V�Ԙ��6��_U���U�e��K� ��0K
x�@2��kV0������ᬰ�/�B�=����$��ω����õ�O��)"�\vw���E�^�w��_� �o��c|��7������Z�8��ǳ���2�����ί��ziZg-��T_�/F+Y��$I ���/��l���65ٽtU)����a�b/U	�,V�F�^�1�ۋ��j���$�Q �:Z�	m��!;dC�l6�{��Ջ1#��������7��$G��G�	_����S$%#���y��@ \��`�H�Ԣ�^c� ɓW��|h^t*�h�
7Ň.�Ԣ������:�Sa� �J��RSx-Ny���~�S����d��_ ���d,��NGq�G�l���uhAįL�U��M��+������'#��$mfG����(;������)��$�o��aV��M򺽷���\��C.>S�fw�\���ȗ%���������̍�(�V$_e��N�����0�jԺ�h��/���a��X�E��.7������IO�@;�D9�64Q~�5�Cp�'�jY�8h���('@�?���"hz�4�Y�6��r|��"�fI!�ோ���<��Ԟ.�fB�ZcгR���v&�
��3��[�6^ތ7��� b�2q��(�P��OCAn
7�i(ȕ��!��n/9���|hD�=�(�[$a�A&�(e/bE	<�Z��!�	��vH�tZqȔw���+��O?�w#������p6Vv
�����$��XD��g~�Rg���|ysw�Is�ѐ\ ��w]�m�?�#)��Έ�%v�?�Ё)��Z�C�&*� �3ݡ뵌I�F ��}Ѵ��>�mm6����F@�P��{LYљ�q��&/��yVV{�� Ǒ��9�3�Ct5�q}�Q>��qD�ɘ����tN`�^:ښz�j,s��8�[q�-����c,��p������z���,�|2z���Gh����fM��?�f5`n�l��#��2�N��m�_؉]P��F��z��J�f���c��GE�������JE����H���q��	���R,��ߠN���PY�:8W/O|+����yƃL�������%�>,%�vB��c�ly�M�=��W�\������h����O��+=n�-Ԉ�_ۍC�"�t񁽰��L0�"ev�ܪ�m3]W�[�ǒ~,�V�'�#��I����A����n����;)�ѣ�M������z�
���?�K�v�\lsֿ�Ъ������ֵZ��W�r��G��O;2?U�o�@���{ <���`Ym5�Za��׷#z���^�����|��ϔt���g]�r��U��C{yu�}�+�V��)�g)u�c��/���dT���q���5��%i*�����W���_M��j�u���h*�yr�k�Z��]Iz�t�F�$�D=E�X���`���xA�8�x&��#�;��]�3}Q���\�d���u,"őǇ���g��B�}�s�9��|Ξ�*E��"��Ņ~ ��Ϩy{5��a=�!��.J6�E�"�b�zB�芞U��)eA�:�)��˻�Ǉ�x7���6e�����zN�1���օ�0S/"ߝx��/y�s��t�yJ��R���q��W���_E��ж�:����s�o%�v�?V�����#�φZՈ��z%��[IZ�>{-��[[��|�>�~k���[B�W��k�a�ks���nq�v���� �\OF�z���:��r���}���o��f]�-a����E��-����x�%Q��Q�ya��6S_��\�޸Q���ģ����R�<�W���S$�L�Ũ����X ̍�~>���%�b�����~M�$��a07�x�7��������A�V�C���3�s��iL�����)>E���Ȩ�b�^$�g���*β-��AU��.�5�U��"��t�߆�1>b�Y|��|_��F:�ȼ/�]�ag2�7 �h�b'�:�"/|$�C���=p��M� 5 H���ÝL4y�|1RB+
�]D�>qݡ?�q����RƑ玱:��8�Ktaw�k���J����:�������mh �n���������g���-�6�\m|K;�.X�O�˦�� h�O�w�^�1�?�X�'D��'�1�ÜN��)����^Q�g^���ð��	���:�O[�pL�K�YQ.�,��K ���J�1m����,��$�v���Bqc q4&I��)�	�L<�̗G�I�I0�(��8R�:�"6`�|A@�1��.����WV�!��]�s,�����#���3J��Y@}�w�Q|�<Uj��m�B7�V8���1.���f�k��X��!l�M�1z�#�����6���q*���?`"�b9
.���GDv5�a]I~h��t:?�k��������;�2O�}�7����f�?l]��~=h��������o�WV���w��ޟ��=ܽ0�Uo��������Ԫ��g��U��]�N���k�iJ4�'~�΄Ao)���F���a/��|�i�~ ��	��g�]�<8����L��v�$�7b ߾��/��:/Ư�Kl"O��
�������ĥ�-��~��O�r��ɀ����<�C1"8�
�����p�������{e��ͻ񻿿�����r�������_���oN��Ug��d�����j��oǿ���i��o^�9:��8��zuP�m�.�+w~���}��`����ʷ�IL�~��Gnƚ��]H��iaz+B��;��l>�
�j֍ ���l��G��<���0EFg�+I��pFSp���y6ƩW�+ǜ���c�2B��`�G_�����ﳇ��0^(3(�� ��f�����9Pa`/m:E����l(��b�f�j����&��^fb��8��s�
n�##}�E����;Q���I��1G�S��t�������V���'Z�-�q˕A�v'�A�K�i�����.��ظ�U�P ���97{:Pd�K�7q��g��g�8mT�0F����j��I?�nfAa%��>r�S��B�&x�	mR~K�$�{�E�^=����0�D��Lz��_�#R8w=��d@5�٨<c���3X@|��?g�K1�`�|����D-���&����\��\Ta��՚QcD�1/�T�A|�����p4�pֵ���R*-~R�Hq0�V���\Tq
/w[�Tlw���"���^�J@�rY�z����ߺfF�OD�� �y�cP)$]���*�3�qΎ��<�R��H��W���0�H�Cc��`;��F!Ie��0$I����,��{�~��o1B�����������n?�׭�1m��Ju�*(��ZƷ�2�^��� �.3�N��$���v=
i��n��ʎ�A�� ���E&7h	k��:F����h|��k���x�����ܟBq4�l6��Xj����[\�b�W�]�Z��>���A\9��h-f)��:�Փ��[)��P��i2�N�k���� ���6�����V����\�[E�E�Պ|3V����$����ǯW��>�'�ſWF ���ĳ�(mؙ��РV_� B�È:O2ᓘH�	Y����x}�p�G���"����+P�$�!�!����^l���@긦C�f�"8�\�\P{� I��mP 'I� ��%��bL6�$FX�įc��>\��f&>$�b�M~q;�0�	��ڑyv�����^��uHI�07��g^��s��6�m[�`�y���(2#���h��|ncM=ΰ�������z�"�z[�.c�E�.0"9&IBK����f��߭�i{�vu�.��z=8.ßу!�}9�&�.4�O���.�n��?�x��W*���ZA�_M���?+I9����O���AdW�>!㟶�%�2�g[��Sn�$ta�Ze�
1�w�p�d	�\��E�>�+]� �h�~hR ����i��O��_Ӫ��������>��W�S?�% ����"C� �e֕}�,pp��A�u��dL��7�!�о1u��㟘$g&J����3De`�\�T�%����7S�A��[d{s�jUt�b��.Ç��_MY�����8\��[<O���b�1F�hL��0���D���Ģ�<hSՄ-�u9�L}o�Y�3�(��uFY��<�2`}�~l��t[��!
�9��t�7]�j���J���k����wװ�.*�+� ����8���3��R�忕��ѧ=�túz��7W��wK�o���C�q�/����~�\�@�|����r\�����K\�����S{�ia�֭%-񘑃�ȉ��M�㕖�,���-�nil �iS�,7���	S�[u��­Md��ݣi\���l�p+!� ����ᒈ���=wD���
\�W�Ϲ��:>�]������S��b_��*f\�k�;}@�犷O��3Q�7��3PK�9�Z��a�̉G�դe��o.��2"�]<�"��)H���ܢ���e�`� �/Ȧ���B:o���7��h>�U�B
R5!9tx �M�y���;�lGl/�d'>�
Nl4�ɡ�?�X��C{���S ��D9*��7���n�B5�Bb!�V�������������0�����{��KF��`Sw��*���jߟ�.�������a�ibH���5�k`K��=jw:�w��oY�x���(����,��X.��䷞� -zQ�x��F� $�e�b[��P�Ue��}wh�h*�8�0��C��12l����g>H%J6�����I�E~��}�!���YPd�O��IH��k�O��Jޱ%�/��hɳ��� �d���q��un�������o��
Ã�� ��TW��[�#*���v�2.��y��S�-�0�Â0�.&�C�ܦ��8J!��� ������
4#�<��%3���ر�_\��3	Ĝ^%��`��qc����,p=���Oi��m�1,ɰ�W��0OO���uoZ��҂]{`����<w�q����r����)����;�J�E�1G�S�4���G�Uk����%iQrZZA���=Ç�����t,�က�?��|Z'������'J��0:PzI�Kj5�{��bvÌ���#;�Ȱ��}���n�F\_z�Y�5\��
�.;�YjA���-h�b}��]8md��7HF�uy����O˛ w��U+�b~�����H�xY`2A�u �h;��4V!� ǀH��_��}���0pARy=.�8�Y݉,xI{0ŶY���²ŤLV,
c��	�-c�M��W��zj0~L���<��s��(�<�44�DZg\�4�L�8~1t�W��#�@�bk���	7���
���w���PK㰑Pn��S<&�X<7�BJ�	21.7đ:�W<>�Jţ֚��/���(�<���-�i�O=�NM_��gE��?W�r��U��^W��gκ.�����ӱ��3a�?����-���Z�/��\����-���������e����.�Revu��kZCz�Y��?Wj���������f���B��1�
>W�P-�A>�J��ӹ���
}ރ��\�{��^Ƥ�RxA���&�E#� �/��|	[�����I��E���95��`<Owo.��5	��?����Ȃ�q��{�
"��I�1Θ�������6�������\���M�V�h���:�������`�_����H��ߣ����z���Y�����N<�����G�tNy�EV�)S�i��ī����7�M�h�q4|���Q�3"�3o>�ɏ?k��CF���dx����Y�V;�p�c:�A4�N�T>C�P`Q~A�)�2�=c���`�Y>�@	�a���T	�4�����1q�=3.l�k�I�A�θ��.a ��=��x��дo���4-z�bX\\��5<���
�ύ��V��FP�C���2/[����7�hB�j�����k����C����>�8�gW�F�G�j�<w���YC�Et���E��0L�Y|����@�cQ+�ͪZҴJ�V/i�jiS�},2���c�t�#1L+�;@����s�*w�9>nD�Bx+?D�ƽ|g����	`9�
�o��T�M!D����;>��W6 yY\"	a�rz�~!Da�OE�GΟ7����I�s�Tb�O����5��V�r��x���K��^o�/l#��r9���y�{H~���:\�O����M�(� �9tMc�$�kh;cN�ș��e��� v��$ ��vm����R���2vA&�"�h�*��ch[�!Z�^9��%��D�w��=���V��ð
oZ�^����SX,��(7�1ހ�*�<`��"�~���Ɲ2r""*N�B��p�Tâ�D��\޼c�-jݛ�{�@�R"�@ڞa �@]MLM�6��_����e�4��3�Y�p&#��Y�K���D�������3`�K.,���5᝖��̩9B�1�B�MacĄ��ܧ� 8S^a���Q��}�Y>"��D�'�@E������ޮ�W�h��A��t~n+Z���~��I�Xb-4U?�sv�`�L��Y��Cl�"�8nf�e����[�l4u�Qo��~�b��Pg��*��Y��'p΁ =����G�7���h6I�<���u�ʛ9E݋��O,|�����@l������x�����l2
�c���|DP��A�-�EpN�B�E	N%��=��c
��t%� &<�����G.j�w҃��� ��1a�Q&/�Z��F��wp:OX7��+D�$�;MDf�8��}�N���ǹ��ҫj���������l䚤'�b��ɞ��h!c��:��t��C�O�� *��\����P�gi�O�|�
֓5��7��xt��y���>8��a���z/��剪����H�ev������'���l��[ rD�xf
����>*
�s���H��kOҪ��y�k~��I����`�G?K��դ�_k�p�W��߫I������<��a��������_�y�x|���Q�6�/���.�����nr�Q��E~����g7H6���C�% �O���2�O��)�g䧟H9�epw���i�%�e�0z�czL�b<� ��Fe��Qۨ�k8���w������Q�\�
GR��H�p��l3��]�O���M�r�wY�ʒ��.��y�_�ڈ����a�_�O���"-l9��o8 0����fM2E�7�hI��Iqh�A~խ��(�4祕�4�u� ��T0̯��=�aC��4cd��!��"ى?vo�`|�� ��7�uZD����|�"�m�ia�B^���/K�m}���"6��s���Nb�",,Pn���c��J�g	hf�'>��i&���%�xz�a������E7���SGg���̨ {v�4�*��a�-j�PTp�Z,Q|^5��+��ވ�g��v�w��f�C�Knl�w�M>v(_Pi��]eO�T���-���w^��v?�^:�~�����՘�|�Z�;t�Z(����� �`}F@+�S��=��(�5�L��.�~�&#׻�-3��@{���pd���z�;�ѝ�#
�]��������ex��$O��7L��M��]����^�#��ر>��@1�5��]Ƌ�_�����`�s�5�R��+�9�_����U|�������&=���s�h�{O
JntZ	�XeOV#�
@a��x�0�y2��}!:@̇M͏���g�E��p(�>V��9?���*{l�����{�kb�^���$W���+�l�����@m�%�X�"k��l �柹���O�Q�Ptw3�+(��0�0�#��0vV��fXWB.`��:CE�`�I	�{�����&�N<�)Ȩ+����?hak\��U(Ռ�s6)0��v���n�vN����>�;< Y�C��o�8|F�1a�������.�	�!�"	�#D/lg,$m�K��QJ�;�鎌0��}#B�A���I{
"�%7������6�f~�-
���(5-�l6�}ac�	}�����ӣ��V�����ʳ�"�M��<��A,�l��Kã2���>����2|�j�o�M���L�`�2���7)�@sS��^P�mͪSTl6��O�o����84n�
0�P!;.�#�f	�l(pv��f�\M�-> Ǔm��?2�Oߨ�73%��ٕ<��:����V���V�_�����_I�}�������1�ǰS~���{������S����������Bgw��x�����싻����v�ݯ|����[�o����i�)K�_����<��zC���:[��z��W��%��@���<m�v�����	�چ��32_OD���r�fB��N���35	BB��P?;���#�IrE(o�������\�J��4����%�/�>������\}� �o���	]xÅi�QGk�����Y��e����-������uւ��H�5�b�2_��z E){(�����_oS��KW�Bi�i�8�,�$سLX	`8P�C���ɩ�Oe�( ^���aT�Cv(�F�l�f7�cF|t���g���,�v����_���/�HJF��1�F ka�	��#��^�na�k.����.��T<�Ѣm�|�e�ZL�E�7�/W׭u���8���%��S�����0Ϙ�)��0�F�_<�������!�[�
	,��nKDZ�I�/�D|n���/�;��i����]`=:�����EyG(J_KЂilW
��4�&�puMCA.@E`�YV�R���3��5#A�7C��ö�26#�g�7s�Ӡv&hH�h;�Fm0n�h���:4p�x.רvQ}~�/h�wF��0�j���}��[�d+��?���Z���"�`�����Z�$p#�l4���/��yV6(�a�x�4&� %�Ct5���%�D��	�}^���j���P�����n�)ޜK�=:�)�z�ſ|:C��Z��ăF`������1'�ID�t4漵>b�Q
����
�(ދx �t���?C0+���q�!�%�d���A_��hdxWa�,֩6�Q���=[��?��c8f�RIy|i�;@��K w&H��/Jǜ��x�^pT�i��r������V�l��7X	]��)�(F��|Uw�-��E�c�>OM��_L�X�x���&���V�h�_���?W�r������}��y�j�Ӫ`�sup�^�:�V���S����_�,���Äzl��?9)���'[�n������-��y�_U���j#��\Mz�X~����[��4G/�]��.>�ﴏ�<��)��VE.{�"ʭ�\�m��[�4%�A�z���?;��]�COt���u�#T�Y�yN��V��jj�J�Y���܂���)Y�=<M��Rwg�u�t���*�Ooh�X�Ә�O]���[I����'�ʞ��7�([P�=�[Z[���I��`�������}����?~�fa!`���)�o����z%����������x$? ̣ǀ�O��*B�D#��e#������5�ˍ��M]�%�EM��r+��3w��=��YQ`d��r�Hf��h�`�Ӎ\Q[E�������:�J�%��U��b2���2�Ĵ|j�y��Bf��'�x�S����hXw(�Q�*B$���Ґ0��@Ь�c���o	3R�<��ֈ��U��j����[I�/���N�j���*j���|o�<��N\%��i�1�輨�,�$�l�����z��e6I�Y��[Z���I|�C�c4�;���,�&@����S5��m�	@�^����p����?�	�co~y�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)OO0�|�{ p 