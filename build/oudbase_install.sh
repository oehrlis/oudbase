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
CONFIG_FILES="oudtab oudenv.conf oud._DEFAULT_.conf"
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
while getopts hvab:o:d:i:m:B:E:f:j: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
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

# define default values for a couple of directories and set the real 
# directories based on the cli or default values
DEFAULT_ORACLE_BASE="/u01/app/oracle"
export ORACLE_BASE=${INSTALL_ORACLE_BASE:-"${DEFAULT_ORACLE_BASE}"}

DEFAULT_OUD_BASE="${ORACLE_BASE}"
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

DEFAULT_OUD_DATA=$(if [ -d "/u01" ]; then echo "/u01"; else echo "${ORACLE_BASE}"; fi)
export OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}

DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/instances"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/backup"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

DEFAULT_ORACLE_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

DEFAULT_ORACLE_FMW_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

SYSTEM_JAVA=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA} ! -readable -prune -o -type f -name java -print |head -1) 2>/dev/null| sed "s:/bin/java::")
DEFAULT_JAVA_HOME=${DEFAULT_JAVA_HOME:-"${ORACLE_BASE}/product/java"}
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

if [ "${INSTALL_ORACLE_HOME}" == "" ]; then
    export ORACLE_PRODUCT=$(dirname $DEFAULT_ORACLE_HOME)
else
    export ORACLE_PRODUCT
fi

# Print some information on the defined variables
DoMsg "INFO : Using the following variable for installation"
DoMsg "INFO : ORACLE_BASE          = $ORACLE_BASE"
DoMsg "INFO : OUD_BASE             = $OUD_BASE"
DoMsg "INFO : OUD_DATA             = $OUD_DATA"
DoMsg "INFO : OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "INFO : OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "INFO : ORACLE_HOME          = $ORACLE_HOME"
DoMsg "INFO : ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "INFO : JAVA_HOME            = $JAVA_HOME"
DoMsg "INFO : SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "INFO : Installing OUD Environment"
DoMsg "INFO : Create required directories in ORACLE_BASE=${ORACLE_BASE}"

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE=${ORACLE_BASE}/local/log
    export ETC_BASE=${ORACLE_BASE}/local/etc
else
    export LOG_BASE=${OUD_DATA}/log
    export ETC_BASE=${OUD_DATA}/etc
fi

for i in    ${LOG_BASE} \
            ${ETC_BASE} \
            ${ORACLE_BASE}/local \
            ${ORACLE_BASE}/admin \
            ${OUD_BACKUP_BASE} \
            ${OUD_INSTANCE_BASE} \
            ${ORACLE_PRODUCT}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

# backup config files if the exits. Just check if ${OUD_BASE}/local/etc
# does exist
if [ -d ${OUD_BASE}/local/etc ]; then
    DoMsg "INFO : Backup existing config files"
    SAVE_CONFIG="TRUE"
    for i in ${CONFIG_FILES}; do
        if [ -f ${OUD_BASE}/local/etc/$i ]; then
            DoMsg "INFO : Backup $i to $i.save"
            cp ${OUD_BASE}/local/etc/$i ${OUD_BASE}/local/etc/$i.save
        fi
    done
fi

DoMsg "INFO : Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

# restore customized config files
if [ "${SAVE_CONFIG}" = "TRUE" ]; then
    DoMsg "INFO : Restore cusomized config files"
    for i in ${CONFIG_FILES}; do
        if [ -f ${OUD_BASE}/local/etc/$i.save ]; then
            if ! cmp ${OUD_BASE}/local/etc/$i.save ${OUD_BASE}/local/etc/$i >/dev/null 2>&1 ; then
                DoMsg "INFO : Restore $i.save to $i"
                cp ${OUD_BASE}/local/etc/$i ${OUD_BASE}/local/etc/$i.new
                cp ${OUD_BASE}/local/etc/$i.save ${OUD_BASE}/local/etc/$i
                rm ${OUD_BASE}/local/etc/$i.save
            else
                rm ${OUD_BASE}/local/etc/$i.save
            fi
        fi
    done
fi

# Store install customization
for i in    OUD_BACKUP_BASE \
            OUD_INSTANCE_BASE \
            OUD_DATA \
            OUD_BASE \
            ORACLE_BASE \
            ORACLE_HOME \
            ORACLE_FMW_HOME \
            JAVA_HOME; do
    variable="INSTALL_${i}"
    if [ ! "${!variable}" == "" ]; then
        sed -i "/<INSTALL_CUSTOMIZATION>/a $i=${!variable}" \
        ${ORACLE_BASE}/local/bin/oudenv.sh && DoMsg "INFO : Store customization for $i (${!variable})"
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
    echo '# Check OUD_BASE and load if necessary'             >>"${PROFILE}"
    echo 'if [ "${OUD_BASE}" = "" ]; then'                    >>"${PROFILE}"
    echo '  if [ -f "${HOME}/.OUD_BASE" ]; then'              >>"${PROFILE}"
    echo '    . "${HOME}/.OUD_BASE"'                          >>"${PROFILE}"
    echo '  else'                                             >>"${PROFILE}"
    echo '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"' >>"${PROFILE}"
    echo '  fi'                                               >>"${PROFILE}"
    echo 'fi'                                                 >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# define an oudenv alias'                           >>"${PROFILE}"
    echo 'alias oud=". ${OUD_BASE}/local/bin/oudenv.sh"'      >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. ${OUD_BASE}/local/bin/oudenv.sh'                  >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg '# Check OUD_BASE and load if necessary'
    DoMsg 'if [ "${OUD_BASE}" = "" ]; then'
    DoMsg '  if [ -f "${HOME}/.OUD_BASE" ]; then'
    DoMsg '    . "${HOME}/.OUD_BASE"'
    DoMsg '  else'
    DoMsg '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"'
    DoMsg '  fi'
    DoMsg 'fi'
    DoMsg ''
    DoMsg '# define an oudenv alias'
    DoMsg 'alias oud=". ${OUD_BASE}/local/bin/oudenv.sh"'
    DoMsg ''
    DoMsg '# source oud environment'
    DoMsg '. ${OUD_BASE}/local/bin/oudenv.sh'
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
� �K�Z �}]sI���������s��Ź�,	.����f�]��4����������D��n\w�G��G��o�?���/�����83����? �)�jF��*+�*+++++��vJO8��孍F�n���u��H��V]��+k�UV�T66֞���F��LP�]kl>�v~>�hG��$������)4/���{�:Əu}�ƿR�X[+�o����U������H?��_�E	I���{�V�]h�;�[�9�cϾ4���/Vٳ�o;�ﳦui����r�K�����g�vʴM���,�<��-V�j�}Y٨�}3μ���*k_����7��̑�7��S�i>6FA����v`��;�z^�fˮ��O����&`t��nu� ,��k��v�t.��k��M3��V3���Ⱥ�}�uY���p�]�␞Ͱvǳ�\va�?=��4��X����>�`䰎۵�'���%6�=G�À_�v��l�[]v�z�r.m�uhPapz�(`ǯ�E�>��0�P��Я�J�st��S�=�#��f>��=�[�*׻��c�b��2���&c8
c;��f�]Zv#�T�J�l�<�������-���]���H)�P�&g�mC����� ��@�Y�i��l��6����Z1d\��3\�"C��.���x�\�Ȩ�Wfd��hP�U먽s�_���5����f=|���gS��]�o��{��m�a�0���ݪ�7v�w��qS�p6���v�O�{���2R�|�-�������Qk����z��yz�|gj_��e�)�ō��|�}�8:>���h���yzB�d�Pð-~Pj�a˯8��{�}7��lq%��k��6�ͣV�]����0!�N/�:::8��s*E�$9��#��Dub��f;��^�o^X��!�[��?��<ÌkGr
����^5�=���w����x5>�o��K�m���}�����SVl�o@��6������!��+��>��ަU�X��F�T9[pq��O�/ӊ�̔��^Z�N�꼣�ǳ�}�C|)���(I�D򭱎Soڞ��E����� ��u���W�K2J'���E�/�i�v�bO���=x������xY�aŋ���ۯq}wr���}�tN�Fv��-~���g�k���x��ˌޟ۹���׺ԩ��	�����2>�T�^_.�>P;w�_�"Y���r�F��@�5�Y$[�&�s��,��������@݀ؕ�df2��,j'80�U�[8&yx`�c�;{�S���CXX� ��������Š�E��ok_�վh�_�=:�.�L(L���C���Z�z�y5�
��e0R�,d�f'�yZА�o�΄�2���::=�G8�$ʳ��e����ǰ�6�ƃ	����?��}�OW=���5V���p�Z�mY�V���֥�p<8-���dk��c%y����Ӵ6}f��������9d�ꂀB��n��FC`����1����&-|)�=��+Ȏ���B��"w��6!=�쪢d�
�[�L�R�6�k�_0s����M�b�[d�`m�\#Z֐�w\��g�UT��Bf˸����1�*��� $���4�>.g��<n<�aP<5�w[�ts��юut��Z���[�^����G�QkO�2	�;�w	B��:=���vi�~0}�첓�� y���
nmb{�.��-�9?��Y]�����-σBt�$E��'�����F����	u���ttp�;������
um�=��I�JJ�*EOC[1��~�j���Ǳ8K��ӷD�m1Ah{e1E�)��Ɣ�	�H�C�ֱ�hU v�=R�U�+^������2qہ���R���Bl��[T�]��c2������4��D���y�Woz��W��RQr�`�:NG�����B�����h$�xd�i�k]��Q��.��ϜP�<���+C�&���>��i �@��aA���ʻ�I�Ef㢋.��?�lqN��y#-WR�Ӷ��J��<�˅�C�!���d��>~�/�`�n쳊�Vk��a]��)8�Ev�`����m���Hz�P�[��:���?F�b?'��9!ˡB~�I���t7`��s|���A�*��k������/q��X^�h͏iIs���RQ+T���H��ǩ&$�����t�
��9dy�a��<�s9����)pޡ�HzA﹘��b�HU���Ô��.{�|��wd��z.N?\��j���C�z'���Y�Ү5k��Z5��p��Yx�
�@�\3WV��e!&+��ۻV	����慶V51ףe��^�PUcy�;j��l7�Q����UЩ2ʯec�lqE](h/r�}�3<.���-�Qu����5�c�Kⴞs�<[�A.���p&ì�e%����}��PW��
f�"���d�!̟���n�%� �P�$�I_�ư�h3S�	z��;��D،�?�"qeAw]b�8��B��.�?k�|���&�B���� ,~8|������D&�[��ג�#V��3r�`\6&��	<'r��ضx����5�q�"0��0�߇�;����|�^�>�����k�M,���1�@l Q?Չj*
�fq�oO��-��Sۆ$��3�]�K������ϳ�6[�K\,KK*B��]X����w���4�Jz0��O��!Q:�L W�#�� ���҇���҉Sb��o2`;����"WM������/B�d���p�my���A�k�c�|�
��ÖY�ѣ���.H��lK���J/�������d�hC�2�O|#�í����f��j���3����[�`��B���N�l`ټzǖ��^��8j��'N�vH��g���G�mXꕯ�����g0�'V�c���`J�W����%�e��i�}�F-/���-�x_p�_�<�@[z��8+�ڬ�y}f��lT���!JS�zI���2�,�YR��?�7���	��2��
�44q8_������ٯ�x�_�Zjى���@�o4�v�ե's3�ۙbK�]�c���iM��T��Fu��/|bt9m���Q�8j���ް�ft#i}���O@��������QM%��xu���FU#]l�~4�Gg�,~j�O=I�_n��I����d���6��2���+s���Hs��Od�N�����05a���3����M�4��2�����N���>�w�{�Z��:�ÆN��)�l͇���3��������Lx�^7�ZI�&�	S��SV�o��Wӛ���^wzc�$λ�ِ�ԓ?�t�ya�=��3�#O/>��}TY6����Ȳ����Fvn#+X�����<s�[�N�?�U�����8?�U�ܮ�'f�Y[������ y} j���݃jgl� oo��w��`&z��]k���c��3���Q� -.K9O����[�t�Z:a������~�'o�%�^llSX�`R}E���C���<KՋ�
Ɣ0�*�:��Cq`�-��g�n����QOc1d{t�A�������q�Y=YQJF��ݝ6^s��K��ǅ������( �+�8�
ɵHt����>ڍ�"O�B�w���8�A�83�(�!���q㦴��&�R#GX�F��R�)�B�Jl���{���h@����hc@�7c�t�Nce�tR)-������Ǔ&����g���]�|kY�d�K�1����ǖV��Wl��7A�ع��(xdwF�o�# ���+f`IB�7u�9����W�!sєN?���x����vJ��7���ۈ�.F���ʓ�M\��k���̒�-�_}�g�PF?\��p�p�7|��3`e!��F��P���[з�,>�R���BH��*�ݑױT�͈HT�W�ҝ��KyQR�KL�n��Dk�;xɊCi��{2Jj��z	�����3ne��_���	(Zn�����~�����Ӭ(s��qzG�pnڭ!G]�"��̽��M�o:�jo�.I �f�^�
�����Nd�g�l���Y�6�*�e�J'�Փ|)��t�(�SAײ�iB;������t�����.Ы���קS=�;D4'��4�V�􂂴���(����M�C,��0��Ş�����OSY�Me���&�f�}��(6-��y�4���|�W_��`����_XȵN��`�3��i�����3S-����+�Lj?C�AIDŚ'$�y�i	G�g���%.�F6w�D��>P �}Ҫ�Z�x�y�4��mA�<Pt����e��JA�����a��_�Qwv�;Ʊ��Ս�ߣ�״��X��
�l����v���7k����%���b��$���H��ݑE�>4�a�/�����?1���0��uccJ]��z$f���f�����1;I�O$����n�m������-����o��?#��??��g8�~*���A?_��M��`���Q������)!����(d]y��q�s�%ó�M�ُ��J���8J�F�G�]�Q�J��;���ݝ�A�Qr̞q�t|=�r�k��뷁#��g0!�y�-�M�w�5����`=_,��S�ɯ�GE��y1���1[��$՟�-m��0)3��DEk�����^k���;�ɽ�~V6�s��s�\�cn�;�ɝ��?'�ܩLr�F�s�ܻ�
�.i�;7�nnL;7��Q���O�ghH��ڠ�z3� � ��J5F}#�Y���[�&3έF�V�?b�Qq<7��(��/�8�K?�9��
>]`q�.pu6��W�O�$���"��>�1G}�m��\Y�;�*>��z}��������sy�/�v���Do����P���ۿ{yx�n��JO�R(ĴR��JPA4'��*��PH)�Q3�f$j����Q�7����,��#�B��
�*�Yo��z��׎S7��l-�S�%,�q�M��]t<t�W$��ʂ��(3A�St
�fU�V�7>�NL��_DEi�����ɛ01����0S�a��]���J|��\T5eic'���zx�u��h��XtP'V2����O�G%���4���6o�`�9{���	M�N�����ŋ΢qӄ�v�	7�PhZ��p���3�UG]�k�G��3���4|)8�����nV?����8��8���8���Yꤾ�Q�TŢ�;O6&N���I/��S�����(p1TNǄ���aZ���CY���K��[�'ُ�4Q��4T�c���X��$I3ro��^�̌A�|2�݌}Wm¹;Yٺ0�R
҅̃�gF������-ҧ6��,�����A�o�].��7��{�R^�Xߨ�rems�:��~���O��ɓ=������5�'����<�ٿ�d����������X�#����'r�a�}��~����_8l��z���1���x�Z���s7�Gh<+����w��h�|ַv����ɓ�T�����������V��>ϤEz�:����������_����I�����Gh��c����St�	X2�Qts#Nt~�!n����@����~"�Pa� ?�M�o�\B9�n���A�Vp�P}BG�	���U�]Ϻ�g|3�=>qŮ�P�5Q��f.��g�ᎏ;��ݱZ�X�dw4D����άȰ��)�,</�}г2Ed]�V�7�Y�=��0Y���sq�^�qOf��"��@��O�7�=�pd�*I����@���� uwcw�t�e��`o�Oɀ,����I�Rz����>�����8x�:X_F���zqs�m��Ҩ\.�DXr)/�)�B¤��v�� ����t�7���jxZ�*�#O�,�д�R���1?�L�Vx�l0)D��b�?&Ϩ�
�%{p@�K���[W�g���ｖ�����6^5TD5x�1��X�*�y��4���90>��zTV���DdM�ɵ��=�tJq��X�P@�K<�3y���a<�B��Vy���6���oR'���3�RV�W!Ӹ�Eֶ�����RT\D�8�Aw_[a�z�;g�rBA����K�(�^�/�Ь��\d!w�SlLp��##�5*˽{��ح��8�i6���]�,Ṙ1KȰb1iu,�1Id�s�
�ܾ����@��NaxuMϛR��(�p�Q���Zg��"H0]Z�Co��F��EX��p��@[��eI��_,��>� d��� �+F8�7w����~`|��U��V���қ?������a��T��hõ�]���w��X��K#�+!��,��]K��k�Cb96�2�]+..c;�������A�!��h���E� ��7�RP3?2�<�ps��k�|H%ǯ]Fk<���F4[�/wɑPk����Sn�GfT2��m���h4N������a�����/�O�������&Ӄf��&N��d����Tؐ� f;��&(s	��Dߒ�p!�kj��x�ߐ�</���3k�� �fOc�����ߡ�'���"�N���]�p��{�3"4J�2$,x��h���sJ�N*?s+t>���(f�Q��m�5���{�d\���y�$x@��8�H�+$���cj�x��8���(Xu�]h͟X3������Cu���ߢy����B[.j��A\�,�n2b� �V�[1��ho7^������Ql�� �Q��Y��%@�#"��eg�ڷ�Z(��!IB��<�Y�|A"���
<�7�L�ױ��-Z����-[I�hN�Ր��%�K�����F�LrS��9��tp\R��A`z�r�f��pOtv�Xˮ�Mc�����x{��XW��#;����0ՎY��ފ����V�pw50�,B�S���h�V�I��kp�t���5��=E�U'L�I
�ͬC�RG�����z>e�"!��h�l��zl�}���X�Tp�U�I���w�ys�Wh'A)R&Ul�R	F݋Ɗ���ZU
i���hI8�gB�ԗrq"Fw���,z�=�ݕ�fMcD_v�@]4M?�G��q��E&N�iܖz~��H�S�F=�d@ oV���o�Y*��Ɣ&��q|��`Q�>�l���FZ���� 3�y1P|�pg�����	4mUV!VnԽ�/#~����{�h�$�|�!~DJ~غ�i�j���s& ҟ1b!�Ol�i_�<*��a�_�}����K�u�%��&�t�+���Z�>���i�"���h��5����h-�Dj�h���`���&��}���N�n�9:�=�S���M���׿��C�{���F]��G�����|ѷ�@KBы�VB���A�1qPAןU�T�5>�x�	E�ġ�14���/��#ݸ��V���_j	���B�"�ˋQ�����q@I�Rq��So�3Q�W�̾�l�C�L����fm�yE��v{7��A�
R��>Q�H�K ��G��x�Y��C�bQ�h���*�Df��e������ޖ�~�L��R*���Ḵ#�AbL"������N��'Ӭ��(Pp]�'-%<�rA�� 7�n�Q���Z���lM�������	7���Ȼ�&�![�;��B|��NK�
vs<��¨����Ͼ(V���&�\ǿ}��$�/���b�_Йx7Evj�� ����䢝��ħ�#�и���b�G~����ա�}I(4ȅ�3�mt�ѝ7.z����AU�I�[F���o��u5K�32oaiGs�]�ב��S���*�#4N��`���o��F���)�R(�.T�7���C�!qƩ���!�I=�������@���/�	L9q�P�㘲xgx�E={�%�o��9��Mn�ҶQ��Ŝ�/�T"ў�p�5���\�!a��Z��bi�$1׽�_�_Q�i9MI,~�eK]�u�J��o��,kB�Vc�����G���ne��zK��*��H����s-}w� y�P�Y��Y��4���t,Ս�3T�H�$�uH�0��9!Oe�˯��p�e̻�����F��	y��J�{w�{?��O��q����R*��Ol�cy�-}�~^���gl��M}�~�����h��O�~+����4���/a�j,4m	MdʙtR4��9��}�P��+aE?�V�V��K�����I�U���iM��ZH[�E�[�jۦ�F�B\�i��z�a��i����D�x�г�)�,�\���KV���:K>����|Nne#���W������H�� ��{>du� �}�)�7Q!��B��X��m^H��v�jJɎ�c��;(Qv���$og�2��X���_��eO��ٕ��%��'Z	���Ŗ�崦���[�&��h%��c��Fŋ�6*��I+��"��8��r�>%��ך��ߧ ��ߧeޛ��k�Un C�4�6�w��H�'
/���I�F���`��[�6Ҡȓ�0䆧	�xW����fzY��
}W��E�/�Q���M '���1Y��ӊ��z
'���%f�(��Jt�4�P�_ ���!D���v�oG�:rX�o;� �,Y�Y���X��ŗ�B��)*2�]a��[���;���.�W�X�ō�l���Ky��c�`�������׍��3a,/ �ŏ�J�K'��R
��l�`�(�'���k��ɧ�?P�2���� �\�9�
��'��=�&x���ڂ��e�0Z;G�I�_���U��4JꪎM0R^Ws���S+���մZ<��}!�C�Z{[^��+C��Cw:�b�f�Ҷ;��!������t���Y>,u@2z���7i�ZX���6����ۘ!�㲁tz�l`�23�9]�v��f^���!&.����GOlٳ(ڢRX��Q'��~�Z9�\�%/�{]�ٕ�;�y�*g�2�E�{����<g���"�Rj~b*�[5MI��L%,��^ɢz�6�x�����~��s_�8ڞ���v_Ћ�O�!�(�<-'�٨��n��naO��W����*ʠ��Q�� ;�ST�P��wez]1f�)O��(���yG�S���.���"��QƇ��wJ�Ɏ����Y�Ɖ�������3��G�dGj���|P��*�Z"��.$|����&�	��
�V��"�����i�f2j�Y�G��\*����[�:֕&lfy�?^YO��G��k8�15p	��j%7��RPpL(P��3�	��b��΄b�b�pbB���P�bB���w3vH�t�7;S�b����Ӆ��`�35�Ԧ��<K�1Q���
�!Z"��S��9m��}���$�u*�}�u6��§����ǫ���^�.o%�!kJ����POLE�5D�~��Rs�$�P�G R�qcH����PM��ivC�H݂��3�<F��U�	�u6䧗�uiòAm���B��n��j�]{�j�3l�+f-.:�%^�
�A넖GYq��k*)b�%)����z����`v~�S�ϐr�OB�E��E]���n���ݛ�7��l��i1#>*=YSo�����5�ʝ����(V�����I�r_���7�{��}^	I�Fv>���b�W�J��&kR���{�H��7����^R�6�7���t�FH�&W�f^��Х�|�%��˖����-�|�ǩh�F��!{��s��3q�n`3�ˁ�0�b�?������B1N04}�
�@DC��?)��݂�*�Up:���� �F���&��3E������23�Gz�@�(7zhE��;���'�nۉ�9<�B�d#3(��{Ի��P-s��篚����1��;�K��U˕��V��������'l�A��g���cy��ĨN�CQ���m}>����n�a'���ǟ��on���W66+�����Ԃ�`�t�������/Wc�V^����?FZ��-e���n���P���[�����E���׵����`���32�O�c]$�qo���U&?/��F����'C�~�Z��}��~�Ӝ(w�X����Gs����96+9��n�Ua�c��;�{ ��v0⮝W�}G?ᎅ�<�?�#:jqrw)�&ir?�z,�섨]�[�xi""t�ط��3}C@�}�|�86���H���ucSv���t��h�2�ԯR�#0�=p=����:��#7��C��i�`�ѵ�F�܊$�,p�r�6�ie%td��"�e��Y�<h��D�l�t�fClnrtm���u�����3ہ��&{�\ӧԂ���7=$�+<*�W#��"����y�@w��ʳ��r� �e��c\M�������={��/�� V�c���#R�iCGS�#��Y4��Ƭ|��m:췖�_�ځg��/\͛}��8�4<�5����Q���p�al�"g�ώG|��
1��u�\��Ǖ�gyV���	=���*��s�,�>��C�,��� ���������j*�7��t}�-z������n)Y+�r��X�+k���Z���Ɨt���j�*�=���Ǣ˯#)�G3ڔa�����i��)�.���g�����[6�vXBS7>Eh��*����.��Oߎ�h���0�x��e
�0@��Va��lp��XޙSw�v�I�b}�BS��Ck���GL��.F4�x��1UMJ��sӏ�Fgn��ʑ�5���Ґeye,�ZZ0&U��U�o��*(rBzQgDE�F�X<�=�0���e��� #�@��mqaRGd�,ƭ�b�"t�b��� �?mڊȨX��飡l�Xw
k`�&O�M���9��{AH�Q��8�Dצ�z�r;�e�7If�H:<��ʁp��Q>�)���ŀrų�1cy"�k!�(�٢���#�^�%m�-K9�{��\�}�9|CxS_�3n����o�n��*I|@�0���Kd���,�.�\|��U��߾�;.μ�K*�
��w��)Ԟ�����A��Za�D(���/�mnWVe#�ftTC�4㊆,)O58̘檑mB�e��tZ�d���~���D�A-�;�-6���OϿ�=y�#9ϑ�F*ȩ�T�&�E�����|�����ή��ƾMU�%��Rj�5iO����v�q���!'�T�rDp\�~�����6�kOu�4�w`9M��(?�W�P��Ǟ��(��Y)�R�,?|�S䥼� �]5'�=���ٽ�� ��u�^Fq �3Cf���X}r�x�0��,�������n��X�,W}��B��|G\��;-ozX$-��2RZB��PX���1�� %�9�b221�)9ț�!F3to,�2��S���~�����\�A%��Q~`�yXẄ�H��BQS4�,C����ż���_%�Yxi����
�*��WT��!)rlʘ�xf��3
M���"X�������i�7�X8a/��}8�*�u[�r��9�,,��Eľnx��X�I��]�^EV�"%Y�_��;��B�&U��b��zC=�����,">\�UEd���-�;t;����Y~��/(����Yr_׷ߥ�W)`C�J�vb���>|F�Y�f�X�Y��E�U~�u�*,l#׉J��n��0f��0�����%�'y>�1M�:}u ģ�;K��{GC�V��lU`�8*W �I�F؍8aB��>1"�eb��ܜ2<F.��G�����iqւy�dL��`�o0��"7�ZR>
ŵ�/M؅y�\��/P������H#|�h-��P%p�����5E8+j��Uky�A�TL&��]�1��+��D톜��_�2
�&~�l:�Ţ���B��
-١�3�~���8|���ԡ#��*�~~�zφ� 6خ+��+d� ƀ��C���j6G��U���t�&iH�-k]Z������ə�W��A�7˗{b���iA��xZZ�)`�d���d�et�����J�-a��6jF��� e0cgo�������$�B>NA�#g�Meχ݊KbX/��".�D�HVt)�|�{b(<8q��<�倲C���=���)�,�������W]�U;�"��:]��'��=�����`�ә|*�gc��.�U�z�U���ga�|�k�R[���T"α����4=�S2���T���2�x�0T��F�^B���3���H�E�N��I&���W/�RZu뒘L��EͣU��M�SkwFx�˃Ņ��
�bu�D�Pȉ3R�	b�+�:�Y2�'���=�=ƶT���I"�/N�þîB��` �h8���m�L[��+�Z�[-Y(4�PK��*UK�)'z��V�C� U*�
A�H/* x���R=cz�Z,�=��QU@n��<t�־;U*H!�̮&���i[����s"&<��h��tw���4��U���r�`����+UNņ��u����R5�F�X3�8���t�Qc���9J�
�k�4�X��C薾ﾫ_����z��o1�-1)y��MuO͵Ϩ��ʡS���ephm�-]1���q���ha��%�) #߲̓���~J��m�eI��nd��R���S$)c�\���&K�I)��q�)�SH���)��6E4��t.F8t��$���f�Ih���㕧.�����ʁ�+��;]ʹ	x	���|f������F.2N����K�d�t9�c0��v2p�#;����QԐU��c � v�p��	�w�9�1���^H^J�C�:�:A��v	Iqy����$.��S������k�BC������� E����b������9���<�5F〉QL�9�W��#%��y%<��L�v�1��?S�~����o ��᾿uT��j��HD����F���p0(T%*�N_���ּ����؟��2;�d�M�\Ee���X�o���h�i�CZ{SD��ju<,�� �/}K�Nz+��Q%֤n��)0ʹ.���)Ѻ�{}<=r�$c1;xEB?��@�)��{��`��t0�M�;
��'0~��J�
��� �.:e1�Ҽ���Z7GӃ��&B�?��?B�������Rc+F���fB�o[ʗA�C7�[���`C�&L������k4���0S8�G�SQP����R�*U�)�Nm'M�������7�WT�2�V��D�
�uּT�¶5�"�*��B���0TE&�Q������6n/h�َ�`�&D*t�6���;������F�ҿ����R^R��h�@G�y��Ζ��*dh,����.��`��J%DԸ�L�σ�CKK q��"��K�Z.��޴ޓ���GP �����/-�J<k�����͝���[�/A�uܮ���]1L���W]6rȠ�1�%ʒ�W�4�e�}玀�\3���M��bQ����쮮�� �wQ���ݝ��~�U�OA6��7�>mB#���c���խ��re���n��>F���/y�� u���	�7���卵5�������磤����|��O��v�f����{�W�
���O�q||$~b��	�:��Ϣ�ˇ�W@-�����.�1���?࿭���w�v�Sj�ٳ>H���F���k[������<�+�#����S&���ӭ�� ^Uo�Xe�F>���Yo�cmwHr�/Y[���Ϛ��i���WŰ|>H�կVٗ��*{�7���]\��6�?X^? �Q�j�TS��Sc��L|j�9��L͖aG]@�_xgp9�7�� ���t�ka��]`������5�&څ)��rd]�(l'��<��u_7.}.L���+��%�T�Gr��TA�[x�47�=�@��S����F�����V
�"��>Q#ρP1�hLf=��[�[�f]���Q�2���&4x�=A3���`0s�Y:DUL��[	�ε����j�_a���#.���+����oNz���{s���-ɜ�n��{.����/�guŶ<z��<'NS�}��S�Љg��+U��R�*����\+��E(�02�Jt(!3�L�:g��|=����NL:�L�y�����G��tMVN��;G���G�7�<�O8<U �~Oz� �08��zA��A�������B_�?��e8i�2G�L�������%�Y$k��� ,��o�%��XC9R<�R�0�������M&��*.�h���M��B�`�wu,��R��'3)S;�ڧ�y�#䕯h2�́xi�p:%s�[-ήd.x��lv/�Q1��~f�p�(�;�s�	���u�H��<���xV;5��I麐��v1�/���×n��U�o�E*y�+�]�庻�8nշYf���MN�ɨ/�.3V`�tܾ���Q�������=�x�+��J���Ev��+t���4���<��L$��ڗ;Pl�<�J��+*nݮ8k)�=kx; �ASſ��L�����ҥ�p��gaW��$FC��w�%��X��V��>�K���!o�x�4��rx@�����Y��X//�K����a4����G�a`z���32<��D}���E�9y�H��˝�0�/t������9�Ҙ�e��0�9K?��U���Ͳ�)��k����:���ؘ�)}��_G��������yJM����f���_��J��5�������O��Ug�OS�Z���U����\|w~���ԋ�N}�������f����#~XJ1hE�5��#�E��L���+[�������������%q�ߊ� _d�y�k~���k�f(�\S^�÷��m�6���x{�l��M����!Z�b�U��5ۭ�Wt�{����%��6���ڗ_�*�k��uH�/��G��c���>��9�m��9�c}ccs>�#�Ӻ���|��/�������c$�W��u�e�7����)���puL9� ��m��6)�Ky>�%ż�>H���k[��|�#��Z�������F㿱1�����x�������|����w�u����*e��Y�m��F�������1������M8tO�t�yx�Y�\�'����+#z)<!���Ad�"Uu<EQè�!m��́������wm�ܵ���xA�^%�y������c�Iǃ3�x��о����y�o9�o���??���=���m�_�a���}���h��	�?���*��W]ߘ��c����N��^Ϣ�	������������V�:?�{�4���QΎs�Q�Vn��em����8qC����
G+����0F�j��c�7q�k��b�5�,k�w˘QL�Y�p�"�u��]V1��W���.:W�e��]r$p�-�]���7���5Lx ;�9�����/��h��r|�<0���S�􈹾"x��&��S��T�R��k\X���M���k-��<�<:���	`:Q���@1�����~�}�,
9�i��/LB��`9�߻A�u�{�|A���,?�p�����F�)�FVsxٗ�����@��;�q��aټ���n�>8j�&7��%N��#%�{��v)�_ǲ����q ��Y�e�z7�#��ܢ;�/��I���}]f������׻m9��b	��2oo� �j�Vs,��8E}E�1�R�J�Z��+�=��L��&��z����{�:�Kǟz���Sf���1A��U0��ۚ����Fߏm�����ޕ"+0�A,�a�X[�C?��uŨ���:5�)�W5�)o�Q6��Q�;Ōh�2z07�a`S8d�=��oЃo� ?��w�����g��±κ�I��������9���(i�����ioy���=����뽂¬�]Yֻ�5;�GlC�=�P���!G�ʅ��V��+��U��DX�t�#������.+R���@��itz��SV
C5;^ū>�e%� ��51d��t<��m~�N,�VW�V�W7V7�ԝ;��G����q�s�Uaz�x=Y�RO�L�Bl���M�}�u�S%�������A�L�$�m����\������o.�=|�ل��{�<���֎rLQ��@@I�?�S�5#Mf[��5A��T�L�(o�À1�"��<:�S�0��%�4����0��������k�q�	��r(��4�PEz��[�Qhu�5"LQE�	�1=��-���&�]�[�����]��A��saG�>J��N�άs<R��,K��[�r�mVX��8�5�?꺬3L�ڈ��D3ſ�X-޻��L� }0t��u�e�Zf' �
���+�O�����*T��32�c�������!�)#A�g��b��@�Da0?�_�>bKl# �b'�Y���I��q��]2��09�ڏ0�I0C�so���)��x H�@^�ν6���;Vp�z��+�50j}�%˽|�m��zh�}&���3�:�r/p�]�O��k(�,����X��͊���~x�����\��!��}���k�l��r�s�w�uF�ܡ
�r���=�QP�D�*��`!o�wq�]���]�jDw~�5�6I�����?�a�?�������t��6���(�Mk���~�m���.FP"���T	���{��:��~�k��_�w���8n�O_�4N����`�/�\�~n����"���H�����o]̰�I��F����mn����c$۹�\�Oa�k'уȐ����B�>5��t�����i�uf*������P�������6���?����U��F�s�#���x�I��j�,�A��F�J'��PMQ�=�@SA��*(�y�OF���{XE�bP?8l�7ۧ�m�j�U�z�f���Y����b|i�O+�를�����#D�A:]ߒ�=����E���4�IU�3��;�<���-�z'm	$]3�cU���p���H���I���b�_[卹��GIs{�8�q{-m>�h����0#��-�Ixsp��Zs��s���u���:t_p�t�
�w��vj,|�s��L�Ӈ���t��$^�+	��q�v��i�;��N����o�N ��児-�L��� j�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4O�4OwL���]� � 