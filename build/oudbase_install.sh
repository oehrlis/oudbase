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
� =��Z ��[l#I� &��ܩby�_��NT�ǈO�R��Y�,�U�n�V�����F�$Sdv���̤T�*�^������ǯ]k�k��0���׏m�	؀=Xc�����.�`�c�s����(����]"�y���ĉ'N�S7����\.�Z,���>s�e���/��r+�b~�����Ja���b�����P�����р����[��0�V�y�s�N�i_A�ǿP�����(��0�@
�)�������|���E�kN;9M��K�mf��FfƎv�6�����E����8������M�������e�d�A�6yj���m�p\[s��_$��򨣹n��Z��vb�_�vG3�c�����3,�e���r�m[6Ys�#�$;z��d�ҝy��g�>����iX]�]m��{fSs���f���S����˖��ӏǰ��x��v�v�rt����5l���"->�:1Lh���	k!�b�n�$��cOX����a��u5�윒��7ɑe�<6lˤ�
�Ӷ�.�\IC������JCdm��9k�l �u�,�1Y��>�a��!UY�����3��3�\~����p�C�u�`�L>�0������!���2�u���\��L�u(��_j.T�2ؓ�K:�v*�{;;������+��Z:d�p�e,��:���Ml��둤�*0G��<�:}ݹD����{�����f��S�ݭnWJ����j�����v�zG'�E����z:0��`�V-��7k��Q�)H�8�j�{�����jif)�>Cfr��������^u}g��R*�v{)����&�>�J8˪�333�dm����q�\��R��'��m�T��{�(���;��s��,��[��r��W��J@�Y�2�h'�{{;{�\R��ˏ$C��o6��.C�xg��9p��>7O^yk�pz���t$'�
)Q�Gk�i�������
^��t��&i�|��{chb{�z��+�C#��m������Ĳ�����Q��nG;-�̹�8taq�_1ُ��G̔��vT�F[o��ˏ��:F��R��$���w�4�RŰ�.dK3�5v�Ȯ{ OH�?��$&whX0�X�ؒ�o�jQ���͝G���qD����I�\�#�?���L�f�wt�,��?�7\7�pF_�Xk\��E�����H�%Ǿ�EN�-FX�G�F�
,��UMu��s��W��ۻ��H��-�E!M �j/t��}
��l��Mַ������]��A@&1���vR�H`q��$?Hj������!���.,,MKH�g�>O���5�}�vok�^-5��Rֽ�����tu��(w�S,U)7���{ �D&���H�)�,EJ���� @��0���h[��	� 'Q��vu��5i>z9�y5�SJ|u�Ƒ��:i㼧��b��umZJ�m�_��á��l�`t
���pk����y������6�a�]��;�*���"��"d���{��{c|i�W [�"�'�{�%�{�yo�E�
+mHz��U^�
�Uh&Y)��ΐ'�%n�k�M*�kv��[d'Cj0��tYC�ްl�;�^F.�0j1�å}~T�š�e���@b 雖K���n!���?���UO�9|P�::zh�4-��]�Xy�kF�G�=��0��V�Ӥ\��h��K��s��XZ�<�y���G6#*)�[�ޚ�}�mΏ�azSο<4ն���:M*E�ه��e��k�M��jXݮf��
@�t$=��0�[��P�*,e�=
m(��WTA5���X��О��[m�	B�7�Q�Sě
�G�O�h{R�4E)jG�Gr���#f~fٳ�+�-��L�0�k�m������|`��	*�N4�Ԉ�{[�t,e��|(�90_�։ɚ#�X(J�B�_�Ӟ޵�A��Q�fs���'vWAY��m��Y���x �У��o�Y�cm�uT��g�Z<�d��Ag��\���D#�JC��/jȐi�%��n��x4+LI�5���C6F�G���),�(��٧I!R	0&R����#r�Ed��¢���-���AHҫ;�U�����%�_Û��t3�Z��Rj>�aY��)8�%{2Cf掐�Kb��=%�|����>���L�NHr��U0IǨ*�9�`*��O_HU��If?�9�k���O��tBR��Bi~@{��FD헼\��gnP���������d�-͸��]�~��z$�4l9��=~2ɹ�����:*ҁ^P{.��I�ҞI���!O���	q��t��٪�{���Z�Jw��{���>��xn�>6�*k_�U�l�B�m��,`]2�aNZ��r��Θ'[�2!#���B�<R��
�1�^�BV�����d�����^��ÅP���*UFc��hl��,�ݣy�Bm��tA`j�E)Y�����Z��:YnE��D�̨�9� ��7�aV�4�D ����9�զ��qq�����p2}��G�̔�+�P m��0�� ��f�>�#`?~m�o�8ѡ��&H}I�d��׵t*R}���^�M~f^�>�����n�	_"���V�����U0 \�M!
�H�AOr�t�'��lCz:�'��������m�t�5tk
�X��lC��c�M$�� �� �����D��d4�c�X��O��y�S���="�g���&��EGc'�x�'�i��:�_�d��Y�!�,O���%�,��;��óM4��Pdw�l
�W颀?�}����}ffI�����С�"�%�Z�F�P)��eː2�؁�4?����1췐�j�̵@\��4�l���M��y�B��i[);��S�X.(p�n6��m�U�P1ƶ�I�d��۬�w韚���=�K��W�ɔ�|z���s��2���hc��^��zf�����!���`����^u��R���*�t(O~C��,7�6�A9�L=�pK�}v?K^A��f���*k<��xr�3<�xE7%��:�d��U�w�@��,�b>$���0�i/	�^]��%?Nwk�R{�O'�3�ѡb ��f��NƗa�H�c'bDp��ڧ�W*��w�JE5y3�; +[�����iͮa����W�ȱ�]Ô&�k�B���\P>>������T ~-M�k�8ទ�b�t&h}���7@�ۨ����^,D���0�P�XPHۧ�{;�q� �7m�:Iן��73����\����j���1������:�����쿽	�U���F��"�xN������{���L��K�����V�&�=5*"rzz�8:����m%1^��1�X-��m~�6�_#�k�׎�GR��	w�T�v����Ci����&ۗ���X;\�M�lHl��;�</��ft�{Dg��H_��4��HOl���Fzb#=���,���Xe{}��M,�����*��VyLv�7aU:�����Ohu�qi��d��%+�@i�KP혍(��-%��7O����f�U�9�u�B�b�� (i�f愜'`_����>[�>#�����Q��N�+oJ��^`l#X5gRI����=#LW�G�EJi��sưyu ވM����nVS-(PO�d{�΋T��
�#���pA��;77jh"�캎��/�g�+g�}j���am>��nxR��F�U���N���,��1x��Q׀(]�aM+���Yv�����&����籠�W܅�+����wx� Q�6�9ČAZf�e�����gX���L�Y>;;�7M�Dy=6EW�6X?K�4����Ț�Ɔ�p�}�Ct�n���Y��s�ϯ��	e��H�u}|F�>39b��l�tuA�⦖7�B�R쪇�#,��q��!1�w�R�c'�tFdz�s���]y���s=�s�#��b��أ��7t(�_,����p��8��2(=�q[fz�2�R���6�gXD�U+-S��H�o7tYf��$*�H�N�V�<� !^�[S�5�<$�0���~U6�T��R�����:��e��w��iZa/����(� ���4Kh>>N@{ϲ\�M�k�QH� s�>}�V�h拵��g�C�#�g�Z왌s^U����l�v	-��'d�&��f�����!�ٖ��_󪖍M#ڙ O����g^��8;��v�zu��:�TO�>�qt��� '�����2��|C��}�eӝ&L�t�m9.m����F�Kɐ>��h'�=�aU8��������Êv�5�?�ן��`�a!W:)Ѓ��hP����4L!{A
cK6���2����0�J� *�<.q�ͫ�J8\=��t~)۷lL��dV�jW����$�P����Z��b���p�-H��N�=97G��,?��H�y����/N��;�#�f�� cN[o����+��K�XM��\�S4�ĀYW��n��j��Iy��6}&�\Tq�懞����2s�0���s9y�\Zun*��ƔvA����Bφ�kn�*�?��������T\��?�K�h�YX�����4���!�Oo�}U�?Y�����+������ܪ��}������E.�S��eQ]2��|�yv��'�q����\&��z�V����w�E��#7�5J��ƚ�O{z��ju��|<�v�[�	�{��/�d}��$���R��>B=�k?y��Zڷق�%"�~�mi��zI�a'*Z�ll��U�����͉M�����ɝ�-����2&6��܉Mn�M���$wb�;1ʽ�Q.���F�c��&ƴcڷʘv��H�@CZw�X�U�օ- USE�^���8݇N�FÀ�щ��[l5ʏ�F�e�D&�b�G6ǖ}Y��
,&���Z���Oi�S��i�\$X�A=f�c�"�ȉ�� &U�'��O�T��n�H:���|rg�⿀=�x��y�' g��4��������*P+�
�LD�E��V�fDs" =,bPf�
��!��ڌ�D�VBs������hVž��'��\C�Ym��z�\֎S5�|c-�#Ѕ,�q�5��Mt�t�ӗ/���ʜ��Qf�jG�f�*q-����Ihz�����e���O��qS���p3BFٙWj]�L�W#��ʦ�$j��v<�[���q��jr���a!��/G��QV��e83n�K��[��~H�ǵzH�D0q m���hƴ�M{�7��д��`�����U��o�^C��Ucpɞc���㡙L�Y�h��sT/s�c�[��ѭ��-�DN�s�dP�K��A�pc��?��"�<��p@�.�]C%54�A�t>L��:M�ׁ�#(k�e>�R<���a��M䡐���1JYB�Sd����%i;zf0?��oƶ%7��ꃬ?��2a)���;"�ҘL�y�&���H7mj�F&4��zj�+)c��w.��[A���b>���&��ד���oO�35��5�N�|&X>���
���~'~g4����=�������w ����NM������u�LGs\4 ƽ��n���&�������6��:n�:,��r�o1�`ц���7̦�rj����B�����~毅��̤Dn��2���\~y98����-ir��f�x��o�����7q�.�J�77��d'�@��H.|�	�˞�'�
!n �ip��A(d�j����"������ա��jBv>c�ڧc�`n��c�6м�b񈭦�p�Զ����)��+m5,���^�s����z�#���+�/R���A���am�`o��4�6���-ӕqx��7�sL`�}3"m���\Ӱ)d*�:�? ��&I��W�Vu���]<ewۈZE��OQO~!�9W��i�<Đ���k����m��R�P(8Z�΋�L��=�IV���������KޅT�R`�f^b�jJ9
�pґ�Z�:���W)�i!SS7w�˛2��� P�
� A�1���F,j�D��X�����fy�Z�K��(�s���T���V��2W��N�� ��uO�L!��,er!��[O 3��^���7�R�?�cd��d!V�$S�=��#q�Z�ٙL�R9�sZ�.��Z��ZZ2�:	<�iRN��䣥E��҆�d[�!��`�� ��H����1j9%a�A(P9(�E;�,AĴ���U��M-o�w�j,`0������,�2C��#ilո�C^�?2�Z5��q�-���<�3	}�p��@����g���a��>Ԯ�A,U�����P�A�@�0�@l����,WE�2Z�^}6}�VC��6��F�����Y��Bc,b�J�|Rn���œ���\��OʏˢH��9�B;�X�"��ϓ�E��\�������!3��fK��wP��V'�D��"A��B�uO��@D����������З��4(�AM�M�"��Ro�i5��Uz�W�s+���\��V��t��#��b�_�ͲR�(��g1 X�l���&��w{
w�|k���{��Ո��(x�Z5�ޫ#?su��E�?A윊%��:�-���zG���mY�Ā�����8՜��H��ly%^]~\�"r�c�8�l����>T����(T`�d�����AV�S��B�af�H�F���DZDRQ��#J7B�>�qK�sKH^?FW&je=g]���"��J�˽�ˋ�ld�&g$$z���zV�D2����$$����˭����m[�j#0�wjC|J��Fd2�9��3bB�R������^o���/��+���ф�]e�h�r���ƾioǱ`q��֑�f�/�%��X��Kt`�u�H���{0���
�i�\Gd�G�Ѵ��GD��[��xpb*����͛m�
r��A����/i��K�����XF�����B�ݞ{�A*d|�3X	.
�U;n���{�r������w�4�T�!X��hc5�OE�<��2���a&��A ����(�+P���v�L�~��c2#~�vB�"��d�I0�6<�ų�W��H�Z��xy,C}�?twn�������E�l�4F���.MȲ���HB?��Xq�7M��<��Ҟ�,c%��[��6
�Z�U�<h�� �b�.�jL�d51��XT��/T���b�����GTf@��؆��9�Qw�iԪ,c�����;�o�&ϝ �	�}��
��RwrM�{F��Fʁ9や쌹b��{��vyT���0��ʹ�[#��Yx��W�t��$���v�:��;&Q٨G�l�7�3e�����j+$� g*x�e��A�\Gio����^HBNȴY���U3W�\������i������3�TځM�)��#g������ Ҙ�]SPX����TG��A0-���2�N'C0�l����D���{�2C���1V}n����Pn6�$�c�5�b R���y@�5�xVt|�R�%��I�T�@������V�����Hp�6eؓ�D�l"�^u7>�1�
�2
C����X�Üa��}Y`�
v�:y0���'M~�]]�� �K])"�R$~��R� {�1���ڦt�9��SU��W�����md.�/by^AwqDN��#[��Q.�r%��Nf�v@���3����ن���{�C����B�.�_������C�m�[���~J� ��|�?����"ж&z�4cH���SW��� ����!�y��~28���a��<|�����w:b�}	���mZ?(��]H���/%�]Nһ��w)/�`��j�ڣ�,���8��ӳ���$
������t���"�z�Д��^Y��v4G%C����.�.�$Q�^�S,<�;5�QJT�fr�;�<����Q%�_��sJUR���k1���rB�*Y��!%��3S��A�8^0��Ra���8q���vLYa�w��jp�k��%rDÛƨ#&E�C�c�$�Y����z9��W�L����b��3�ެ��'5�t㨕F��n��W\HB}�"Ɖ�Ce�B�����q��G���	�P#�}�8{��IV��̑N����Z�cZ�$���o7��N�М�n�VB�2r��TDA�^�$	�<����{�G�0���\�]YZ���#�J|���W�^��^�'��xyP�2@�"�
�.B�� �����\H�A�E��B�T_D�.�ߋױ��{x����C+{M�#I����\�ҹF���E��6�8'���<u#�WO��DY�AR�@�l�ٳ��5J?k��I����ڌ�-)�m�J�Z���V�ɹ�oL5�?��a��ЯPe��;J;����q�YӘ/	>�&��TR(7|���Ǘ���!񠶿����h�Ɔ��>O����Ϥ��I}��� I�$]�ZDE��� ��R����c��ۈ�����]]��y \�#�Kϣs��`�<=�f�����Խ[�$��(9����F�D6*����QEdmAY�Z�P`7ʞGe ���G����
��D��r� A�B���p�~��N��(gT�F�d��i�k�]�W�m�:�Y{�&AU���2j�����R�m?{��w�#�0qB*oK�KmYm%�||9$3���^xֈ��(Kr@%�r���e�#�};����i|��N�������C*�F�'��4E3��Fay��$���F�s�L�aԂ�9s�����l
�{���,P�"��)��m�cnq̼�cX���L�Y!;����'T���'~�#~/���s�T��x�mT�S�C�Dr����Hʉŕ���%|b�	�!�m���;���U�[�K��2$�����@����
o�@3�X� ���ؿN�K�i(�[�
���{�BQ���P#�q!���V��)v���`�,xN+�BK:�����O�ʌD�Ju��B�Lc�Һ��Z�.0�Ҍ��i*��	���XK���\b�O��5=�c�m�j���#o�"]�m�IW�L䬚2��j7(R<�sŝ!E�Ѳ0�2��U!s�Nc�J�%��w��M@��d�4M�o(Ͳ��f':�o2W��lEZ���a��M8,t_�֥���-��n�)�����YH3�.��Jm��M�˟f�=�:�6	��mA'���x��������z=���݂n��na Cw�]&;�e��A߶�_����@(�C�>��&���'��Up\Or;���@�6�-||Li|hT�L*6�q�~��ő��} &�̺�F������Z'\�+	�Z^]H�!��J�͌/ֆE�xohE�Id+ү���.��`�%���#]�Ō�M�D���b8�0���Q,Z�:ۖy]��+��3�&���!ڲgH��@&qz5$[�����T`-4$�ح������[���8,�heG���!���
EU,��
c/� Ta�/Uӫ"��,��Ԍz6m����Ñ�;	�?u�;
>W�Nb��m��Ô�T�O+W�º�#E���q��pȂ'���j���17e��2|�Fց�4��ZnM��[S���|�~�o�A��rtW��%�;���c	��Z
ZF���i1�+��S���
��%��qn�Aԙ�L
(���\��� �
R$���.��{U�n_�a�9S��g������7$0����}/�(ߤ��@�┅6������H�5R"p�ą��.�ǡ
:T!S�5�byчڅ2���PFq�q�>_V��B�}G�bFqc�<�h����T���{~�4d��=�d]��&��΅zf��=��=s��>���lD��K�U�ǘ�yBB�g�:����Z<�sMmӚ���rW��u�_e+�j���t�D�2({,��a�5)��v�!h���Υ��%L��p�2r]�nf.S� �a�
�{n�Pۆ��Y%�t�����_�{�{�����r��cݰ��0�t�;���jl~�Yl@}�V#����	�e�Cnq?��l,�X������Ո:W&2S�m�4�9��JC�`�}�Gx��3J�
�1{'͌�ҍfJO*,�߹х�H���`l-����L%����yA��JԵP�@e*Ąc�`Qd����a,R@�cLR|jZ��U�1,�����?
 Ir�|�X�"ū���y��V���n��� /��q㿴����㿔+�'�_�#MS����U��$zЌ+0�Q5��Ο��T��e���M�Kq������~j���S������+�ʦ�����o?�K�c�8��;R�`܏V[����i`j�Z��z�/�yX�Άb��,r#Bt��]��w�O+�O��S�{G�D�.z�w �I��)+/\�#ix�r��!m�F�-F<ְ"�ľ�����6:Ձ;u�f�l�:ۺҍэJ?S�rmk��.h�=�ÀQ�]���I�hP�/!���u�X��f�^P�Jc��K��$��h0;Ԁ��e��8L^����-�̍$S���U;y�R������;謶��q�~��v��z:��.z�OC�D���f����l$�4>�G}>HE8
�o���٠�'�Ẻ�0d3Fe�yd��i���������j�u�Ш*X)W3L��}�4�W�mhخ��l��SC3�'��fk��f����΅z��&���eՑ�D�=��O�^`�<���k���DkTF;,����wY����B4k�<�	=���cg���}0�{�Y�6^P�_��W4 ����~�%OQ&m4�9��s��ӆ��̆#�vդ��t~�0��Vxo��u.���Q�p�j���s�9#�e��q�x�N�NZ�0f�K��e>p���U�����s�['J��������0����>b�z輻w��B7z�����4�i�t9�h�ɜ�����`���Cw�N7)�#�[0u�VS�-Ч26��g��![��Q��٭>�O,TՀ��%Ieø�76P����K�\�!��Ȥ�̉�����̰"��t*U$]�ߙ��F�SA`�u�2}�;$��d��SI���\�1x/���V>v�uD�u�N�w�ի�����i�N��b��S�J���CJd���2٫�D�������ƈ(�{9t�Gq�!��}4�e�F���qԇ�}=}q�i��:�F�n�Z�:V�drC^����h�8����.J��;H��F�ȗ�/,p�D'�i�\��:���a22�nF�^��{��	q�y��9�:�Z��	�7�K�Sgv�,��ţxG�8�#�;�2$J����T$��#�s��DL~��0�q	�@fzԤ�p��K�
���a>�V\^��'��3�LNH$c)��Kl� ��5�〖�T#ڱN�ƥ^�$��)�!)�`0
�B��|(�.G2y4�7�~h��,���*���*2,�������������௧j��9��y[��x�(����?�b7
*�Vm,���n���ر ��L;6Ӕ���"�y/�;̯b�=�)/��D��5�,)^��l<�������gr�9����yF��ѹ�MŨ\anp���Ϧ�|#̣茣1���e�=�ud��l!�\>.�g��H@�`�2�v<�$��ީ6�-~�E�a
<����\�x07$p���I띟��O�I���Q������H��t�I<EH*G	I<!��1:�������xLé���Jv�z6	�2�����_�ۓ������ �i�O2(6�Q�a"�e[.�n���#��i0�;��
�F}�5>�8�<��R��FC��vz�7@ �Va�����5-�8�� f��o�@J�ә��q9���3�&2���T���l]��+$�	lPq8��)�琕�_J�U�6I�=B�����!Z���/3���X&"t �9��ۏ���[��Qc�� �#��R���DD+v8�dN�Q)�!R�EV�iJ5�Q�]����k;���(�)6�К^L4��@�]�N<��B�P�ڂ�j�1:�0��vY#��L���A��9���z�hG���"���Z�\J�Y�_�ຐ!� �xX��C��C��u�q�O��S̪� +(.;M�d�h���Đ�c
�9�䙣ѷ�(�i�^����Y2,;#��i�?)�����v�m�:=SL&�zz�q���.<?��L��w+d�\qŘw��w��@�:���0��E����������q�y��7�D��R��օ��c��<I]��/�CUEY�A,L��1R-՘uH���%�EvIO�e\�Fv:,jȔy��EŶ{�'F�.�86���QR�y!GV!�h��&�Q+g�{G�.2�E��]�y�ʉk�H��F������T���g�LS��K�Kahx2��k���kR�kAX| ��t�u�	��[�H�_�1,?�/��}���֧��lt`�8ܩ)l)��UZ�g��0ľ�נ���(�Y���ۮ@���jM�dB��2��#(6�x�#&0u�������UsBᛝ�����"RF�*[�#�o�0}Q� O���A5������͇�6�i���k��	Z4�x�m�l��ٔ�ԇ��3�W5�|��
�_hc��ĠN�j��]�'pf5�W��)��C��jL`\�K�Ti�e�cO��*Jk]G��_e������ �ɀ������cm�9�w���贠�BtZL7�N��P�BV�Q�������� Z���"�5�^7\O����k�(T$}#v+
^�L^���k.'+j�&�f�s�ZY�Cʃ3d�b3a(��ԣZP�:;a+�͑v������3O�*FOtq��z5�������ShY��^�"=2 �|@����L�iսH?�g��-��'�8�x��u&�ИYM�y�����9��S}�L*t���:*�����J��n��
I��U�����dy�,U&�":�ѵ����*w��"��GS@��Ģ�H���9�p�{A�Z!o���C��,��S��=��,����|��Oe���{|�u� �(u���zOCyj�S2u2����3P�;@�R�X��VK�B�0��D7o�F��wzJ�s�-F
���d��r����5��"�&ڝ�9H\u�Q��/-T2C�H�2��
�r�*`t����ǃ�chQ C���w�B9�F�٤�B�*������CJ�h��7И6���ՓDF��./A�P���#�~�B%��ȃ`�~L����ۼ�%�|22K�
�Gđ�:5^^���3�*L�<����u�PC^Q"l��5�YQ��������+�D� ��ۊ��ŕ������vD�m��
��b5�O��,~���Lq�7h*(��I��x��H�-� ��RO�tT�j�lD�
�[T�WQՕ"	 ��������;�N.���h%�M�c��I�u�1���2u4�6�q��n�to�/`5��>�]�@m��U�W��y�"�~ǭ��������<Uc����H����]���<A��|5Xq~Q���
���G����+%�hE~#��V�Ct0��שGp?�.���4�>
������bT�qX�:8R��+�<g��S����tb�5B߱2=+�)ږ㢢hQ�\G|Bgh��6R��r��\�#�����uv#��� �'U�i��:��5-T�`�C�5]s��2]��BE	�d�&�M%���H$���8����� _L�X���&WӢ����ү�X`��s?�3�A�ҍE�2�H��2�e>� ��h8��B��J��okb|7j��J�P�����'�ZKO�c~Aϟ���n�~���1=������!.�/���P�{�a�b�w�����̭<?��HJx��(����~#T�a����S2�8��P�鏄�X�X�BR]���?�1�(�;v��f��삪�ZP|X�.%+���cg�|���^����b+�[��ʿ�iyG�^�ъ(��p{A��l8�s;!J*���o�t��j��H���$<����5V��Jq�Z@�Y��|��x��UĻsm��9k�,V4Ӣ@���,� �fA��i���ί%��iU�z��>	������g�<fw����\Kӧ�ȟ�L��6��'a��e
�}أ&���
T�K�.����Q��2�s�,�Xuz����N��,DsɇX=����IF�3��������zu�VM�� �_��?Ѝϛ@t��G�XX)
���J~���:R�����#�����㿚[ʡ���������u��P���m�5z��f6�kdf�h=7%�G��ڠ��[�0%V��W?%5�&�=���!OM�[� #<;�a�/���ݐG�u�v��Z$5X���mt=2�J�B"��Z�,ޗ�.�3�}�ՏP/M�#2��<�:³[�>ry���M��r�lj����
�����y& _0�=���u*"^00%�=��7�>l� u�%#!j�G�-��O�`��:��
��~0�N�A;��ڱ��������j��˯��	́�LN�.\ό�iq*`~Ql`B�P�=�8P?K����"�5=`葰Z��;A���[��!'�x���&��˽�����#<����g�)��+f�V�����&T�`&��ѱ/K%����*�Z���77Y|э_��7v�3 B�v-�1d�db����/�r{W��g���~Q9^I�8C� N�1B(U�C���sd�H��[�b��_�x��˟R�uLd�|��򙌄����/�I�"���ډ�?�t7�B�1/�>o����=����kǲQ�r�(S���K�Իc������F�@c Z��8MW,R�i�4�7�-��0}�;�[�*2c�FN��g�j��n�`�
�"��
+|�W�o���[�//M��kI��޷�ޙ���d�F>� �M݆��������P�����W��/�������G 9d����ԉ�x1iz����_����?����R휤���{%e�����j`�/�N�������_��-��i�n�z��!�V,n��jg����I�mH[��&��ѝ�f�uP��L.�!�D�۸ë�V"�jZ��I׸}����S��t��l��J�����+.�����g����מ�d�Ӏ���dV@6��@p������������d���zdT4	���hc>l;V��#C�0Ҫ�U�H���b8 �r����c���N�b�EGd�a1���F��hM�4	��=ox=���8�`s��g��%7�G�&�t[��=�K����8~�=�����қ�܈�S+0i+~y�ei�~MSk�9{,�/������G��0u���x�,�����t���J%i�n~P`�'ɹ���@����v�۔�R�[���z)P8��P�M������r�I�hG5*Pk���	�1�MH؊�etD��Z=�ۃ�F$�$u�ǎ�^k�J�^\G��fO������t�&^��Ĩ��3����M��)��&�,�diX�.i}�� ��Խ�6C�qm��Eas:x��5JB'�r�O-�:�Հ��Qd+�C������e�&aRv[��d��cq·÷!(��4{l���Z��*j��Ȣ�E?� ��J��)X:-���F�R>/�M�Ӯ+C�IghV�I�a���[�����0�=�K�&N�{����P��f��j5���)��ڣb-",O�i*�l����PP	Wj`-5ffN|�ܜٷG�,�e��q�1��w)��TX^Y&�|���:��\Kz���&����߮O_������/���!󿰺���m2��#M��7��U\�~%����� mpP,_����/^��]<�z���g�L�[Ho����;�r�z��.���������[c���˅%�1��ǵ3�/�.O��kI,���ܐYA�<���_�ǵ_��aof(>\�ּ���i�n���"�'m�Ż1������bC�E��0�<a��k[����%�􃾬��{-�����i����'�}{���HѮ��[�0��X�����h�U\���kI��7r�#��m��cn�D� +0^I�z���E�7G�f��<қ��q	ç\u�����ؿ������������u$?N�Օ1����o���/H�����s%e��/����$�)9�Tj�4Ә���ɯ��_(�WW���B~����4����)v��3���g�^��_�\��f&i�_��6�˹�rp�q����kI��f�5|�5�>��CѠ���Pz��`��v kp��N+_kX�޸+<I�4I�4I�4IcI	�q���Vc�&i�������Ϗ����������.�$��#��G�3�����䟷��]�I��G���'gZ	��H�|���
����ɓ4I_��{�ߙjL�S��޿�����Z�J��6����_�{���7��e�t���֔9��j���V�T��?��S��R���#���͝j�O�^�c�M�U�u������;���~�۷nݺs�O�z^k['5z��f?�_�ο�[V���������_�hf��ȳ'�ٴNX}��<�^ܾ}���û?|�j���E���;[$�����d��|vv�����K��~����o�k�`�S�߿�O���Jo��u��w����Q��v�Ν?q���O��w���;��ޡ�Њ�9��{�}�a���~M~��Hx&��NC�`�W/w:5�Kݰ�Ng�r4���3<��w�W��±lw�"�� ��X�uM�p7۷o����?��KV?,?������w�����=A�zG?81�n�s�i�4��/��Mĥ۷���n�����~�?�����w���g�����ޝ�u���w�o���[���Җդ���w���[O��:����w�~���޽��@+�j�n�'��;�/��:�ٓ��;�t��޹ۼ}�>z��;�>��'w?�K���w�|'�x�����w�����~�e�9�NO7�����X��[�>�7�fSo��.WM4ǾЮ���+a����Tn���'S���M�N���v�L���?��w����z꿟�[Sw��M����c�����ķ�I�0�J�$�%~��&r�Bb)�Qb#�I��ēįz��h'���8I�&�L�J���?���>��\�$���_M�+�3�ǉ�����~�?I����,�'�f�N�/������{��N��w���X�#�W%�w~W�q>���gbh�㍏?���o,�����������ɽ���{��[�H�)�1�d'ȊM6��a��9���[Hmw���?��~�ԏ|������߹��)q����,�}�!�;�n���+�xg����o��kw>����7�۟�)�Z��;�z�Ν�S8Wo%ځ$�_N�wS�������J$�M|?As�L������jb;���K����Ä��'�N�LX�%�׉�ğN��?��s@�H��|�/%�r�_L���-���:%�H�?H�������M�6@��*�&�'�T�%�����{�����F]������l�c��)&�s�3՜2������ ��Xd�w��{��ށw�T�.�.���7o�CF�%2T�ȈzN�$M�$M�$}M�7�A�5���&i���)��J��`�;%Ե��+�aj�A�;�`h�?�L�ޘÀ��������'��|�߫�9����j.G��������H���bdf�WA���� '�I�������!���*���\\)p��������H�j�=�����q��gב-�8"O��o����7��3��䑁���A���)����(�ek]'��-�\���k3��(��\}��ۓ� p��z[o��#�!ꎥ� �^�BV��E<EJ$��jO�h 1WJ+C����7z��)��h[$U����C�h"l"�SdN�,�_"r�C����U<�#��q���`a��NO����}3I��_����nB�-���U`r��Z�,��Z���|ni5���ߖ���ZRh���!u��靎��!����2�����r�m57��}=i\>s���6�#[s\��p����7IM������|r�q(~�����A?\��f�Ln9�~+�f��\ܺ���C+K*z��ڊt��	�nz�z+�M�����ȣ�M右o������u�2\b��6�E�6a�b����}�<r����PY����S����SM�.�DX�$xG�&N6i7�4� W��fZ�;7[��*oln�����$��=d�R�AOs�C�� d��|�es����G�Z�'i�
���������;����^;5/2;NG���V۔���}���5��=�U�0�^��h���Ì��x-˵ړ��
l`�=+4���V
�F��s��:� ����8��%%p�w���<G�w�����H��>��D�=�~t�'�51���ؓ9��M��W��Z��$	%1N~��l~ʅ�"��/�2bOmK���a��^+��������M/�ot����cC�?XC�����kJ��������)�紕�.ԭ�s�-�.���>V�;�B>��]k���rY��˲�\ϊ�6��8�A��� 2%��,�|E�K<��an�]Á�Ҳ^�_l KE�@J�\�E�l��������x�~����C������������?Y�G������;M�{�
��w��/:����&/�#|~�}���b��p����/���-~��c!�8m�v�Ã�M��"��ͺ�i����$�v{28��*��i>y����=�l�:ҥvs��[,,.-./W.ԝ��{խ��~�M�Unzq}=Y(О\���،�w���u���j�y�q��:㰃���1L�+���W\ί��?j�7���>�m�b��s� ޠt������3PB�p������Uq�h.	Hl�D&P�V3�=�"�$�	�<=���0�� dI񂇁MqH�i�4���m���x��Zh�$��|JTN��׈�~4^D�p��b�cCm�DP���yC��m��ѓ��)7���I�A i���hۧ`izX��Z]?�#E����f��
��-D�Y��5��oZ���,:����,o&��
��ޥ�YΈ�C%�@W9[�Ե���^J�gVL�1e����}�395���;?f+b$(�1r����4=�0����q�ʷ�x�*b����"�׀�
VnR�O�!m�큂��X��Sd ϓ�Q1Կ�������'��:%SwO,�EƩ�������$�������Ӟ^r��z��JL�J>�	X�xx����̛ť�X��͊����w��5����K�Ai��y�����M<
D�U���] W��z2:������N����P%�W��8yN{�ܥn��i,�w�M���I��'bRc�!����J��\�-� ���./M��H���7�Q�eo�F0&�#�D�HҞx� �du�/Y/\��'��ꃰu
�����]�r:F�d(���mEc+����.��u�^�ug�����&�$<�B$�R�r�λrB�VF]���ae�u� ����Z?��ȉ4���c�����;�V��Z��L��<\?���lm������{�k9�ʻ�S��Q�����7���ߍ03B,�o}���&eQL{) �0������q�}�A�
y�*��r"�wNغ��j��"oQ=�w<l^�yZG�j"g|�De����7x�Ӄ]�n	+���� �QAK�pC�vb�k4��D�u�í'��Pc^����\Q�@̰�貢7w�B� oR�d��29A�F_u} >�9C-d`3R�(�`V��c=�|�N��K�-�N�f��M?�������ޘ�����flg�A����x�_��\���-M�]KzZ�~��]}��ӝpz��rO3�|&��K>}Tݮ�m�?O֪�{�����o��>g̭v����#��?��$�;E��Ǹ��i��_-V���PX���������Z�U��'�@Վ���
�u��� 
/�k�YD^��m����D7NO��Dj�.����s���&����H��x�q%�*��F̑�W��g(��`.�f��^�_�M�S��^�x\�+=�:}}�^=j����G��k�N��)sY!6�g�ɬ�l4�%x�o���7ZI�wH/�I ������7w�˛g��dԃEP�  s��&K�mG�J �xd��s|H��W9P#-�*K/O	 ���!z� =<Q�1�č��j�}�����p�a#�h�&K���ƞ7��j�k	�l��d��P|�C� �`.��m-sw�%uw��9���D��y����&m�;ݹ�dR'-c�/O�,�үiʢa�0g�������r)g�m�vڟ$>5P��w���Fm�,IH�J2�f�1Fp{P�d�2u�,9�l�I"����@����v�۔�R��� ��R�p:�����+O�3�Q�
����ysF�n�f҇��t��V��� �	� I]�#��Z��lKw�T�A-�͞2��!*��;x��m�����6ׁ%mn�N��N:0�`m~Mo�{@��,�h��L��ձ��w- M�{o3��9�Q6����g�,@e\�萴I
9Ƨ��x�j@�,�f+�CVk�6�Ϯ�/�nۖ-e����@����*�X���p�t
ǆU�=6�A��ju���g��Ȣ�E?� *�4ۥ�Ii��׶�����C��g�Bi�6��4$��Y�&��Y򭟸�S��W��0=���r�pc�*���wo�2�����SQ����0���Mӱ��DM�ݍ��T�9ب�k�⁊PPI�w�<,��+7ffN|�ܜٷG����n�����������wi�?+���kI�y�C�k�0�!�)J ���aK����O�eS���ˌM<����j��]Z*,���_]Z�M��u����f���\�j��Y�j���`TL�����ۮI�xs�3B�	�t��2���ܦ뇹�Oj)$;x���;�3L�_.,��+y E��ŉ�-i�2X��)�fV�$O��K�.|Q�/6+�]�
.Ik��e��w��O��鞴M�V����wO{:�[�Hv6�O�V��z����>�\"IT�4���^�/���Z~eiem��{��O�����ǑB�?sX�>,l�^��_,r����
,�x���Z����H��7r�#0��Z�?�H��>�2��ԯGNO�Y�~soְ���� �i>�B���8���!��R�����(.�����4����4��!��������������N?=|�V�p5�?���j=�D^����d��.�d$�t�{�<�+�D��\�#IZ-��V�+�C�^c)Eg^e�~�|�ϼ��旗�)��G޿Je�F�хr���H7Q��u߀Jʮ>��z��{:��;GV[g�-�D{y[]�H����퇞q����c)c��'������+&��u��!m��AU�2�ZEM�+i$�k�hN�7� 'pO�P��u��lB6%�>��t�?,��l6ֈ�0i�ѧT�?�R�f
��XIƆY�k�����u8{��Fg�2]�u�ü�[�P�bf�υ��Y�$M�$M�$M�$M�$M�$�9����D 0 