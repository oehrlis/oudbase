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
VERSION=0.1
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="TRUE"                                         # enable verbose mode
SCRIPT_NAME=$(basename $0)                             # Basename of the script
SCRIPT_FQN=$(readlink -f $0)                           # Full qualified script name
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
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
while getopts hvab:o:d:i:m:B:E:f:j arg; do
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
INSTALL_OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

DEFAULT_OUD_DATA=$(if [ -d "/u01" ]; then echo "/u01"; else echo "${DEFAULT_ORACLE_BASE}"; fi)
INSTALL_OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}
export OUD_DATA=${INSTALL_OUD_DATA}

DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/instances"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/backup"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

DEFAULT_ORACLE_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

DEFAULT_ORACLE_FMW_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} /usr/java -type f -name java 2>/dev/null |head -1)| sed "s:/bin/java::")
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

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
            ${OUD_BACKUP_BASE} \
            ${OUD_INSTANCE_BASE}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "INFO : Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

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
� ��fZ �}]sI���������s��Ź�,	.�M�#�@�i�˯#(i�D-�	4�ݸ�)�?8����~�O�_��_���U�]� H��f=#	]]���������uj٥'����͍F�>������_�J�Zݬ�W66*�\�l<�<a�>c�7\@�s̉� ��ل���?�����N�y��+z��cr�W�7�V��+ՍZ�����^�l>a��%������/J�����,��������Yn�`�\���Yk�Zc/ƞe���Z�9pFC���/Yg<9��V^�:y(�1�s�5-�w�3Y�����Qe�����5ֹ��Mw`ؽ�#�g�"�Lp�9���+>v|�̰پ�w[qL/�<J+:��_��u�P�ݳ��tn�����a���W��-��V3���м�<˱cY���`���^ ϰN׵F>�vn�?}�Y64���sMl���3��oz��>���a���aك+6��;s\f����ԩ�9}g쳣7�T��3�V���}��K�s�9>E�8�<q���ܻ�þ�rܫ:��+��b�\y���ضm��1`��d�<�j�R�<�2O��H!�!0�	�0�c3�9Z|��Y`[P�3�~4|@�>�3�Gl��['���G'��F�Zy���6�9���go����6���k�|���M�ʼiv���Л��~�࠽�jd�_��l�g	x�8�l���3~��	�`���ٗ͝��o��dCM���탣���n��[A�Aΰ\9�9�=8im�����odK�p��ė�;P{�Z�pSҋs�l�s�<<:���l�YzC�d@WC�宕�o����.�w��1�r���ns{��j�;���o׀Y��3�����F9�r��{��{9���T�an���L��^{ƹ��g�Q�ڲ������\;�S���Ԕ�rv�s���{����h'�+�/\V�ط8����'����Y�ž5��ڃ�?��0�/����9{�T	c�~�S�l���a�;���H*�0RR��IŻ}������.ɥ J��G���o�u�F�r�.Nlװ�5n
�Dҽ�6I$KRJǺH�I�O�I�v�sO0�_��B�p��Yg�$VnX��ge�����l���4�������|���}60��|��\��(����d�>�%�]�X\F�֐��衆:Q}%���vn��>�I��U}�&�	�]��`2�l�+�9;5��m�5��@݀ڕ�df0��,l'18�5�[�'Yxa�<cGۻ����Xz���쯾���հ�U����_�ֿ�d��|�=<L/jO)L���C����Z�z�Y5�*��e(&<����pdiBC�ɲj@t0ȬR]��������l��(�>���
�2��ڸ�&�CJ���֙�]�q��X�/ _µ�hUܶe!Z�ĩ�Kl�dpZV�����ی˦9v���Im�¨�����{��HuB@��EE7e`��A�^ ?Z�(G�&��IPO��
�� {9̹(]a��iϪ��(�A�B�64�m�C���-,�ϙ1t�6i�{>�%�Wd\c��P�w��WT���Z��Vpj��
c*|U+!�X4}��S=��h	y�|qà*x9ln����E�!zj�T���L� k�ƅaP{��S�L���=��;�n����]�of�=v���nأT�H��jS��q`�o���4���ק�o�.P�����^�z��6�/�&�u�C���U� ��)*z"��4����fײU����"�t�j�f��6�H��30E�-1@hye1D�!�1�ƌ�v���u�)Z�-�T���#e|�"�K�V��U4D!n��s�Y
�Ϟ�#+�ߢ��Ұm�y������ц鯧����۹�y�S��f�������q:4����&*�|�EC��j ��K=�d�u�@�Gxf�yl��|,�",����4���&���+�*#U���.���)~�٢�.F�bR��J�-+��`]yf1�	p���i�IG�}�_~�
��gA��Jjúv�(8�Cv��r+g(m©�@v��؛��:���;B�b='���ˡA~�A���t/���f�<*�Wr��0����_b7]��b#К��f���RQ+T֦]R�H����?���v�^6n��}���ְ�r�ҙ��@u�v
�� t�E�n&�A��ɜl�d]���������^~�:8�pB�� )<2\`�N|�!J���Uo����.j{��+���*����2WV��E>�+߬<۽R�t� H�J��Z����Rr� s�����n��v���Ghďa���\��ײ�U�[U'
Z�Boʌ���� 2�EǢ6�λ��&l`����ح�R"�r:h!%�s�dտ�d0���~u�I�`&N�0��P����A���F�#�FI	�<�M1�:a����w��	��$�I��r]`�(�e�E��B6��{�I�^YLM �냷-ѐN�_�)2��,�^�w��#J�ؖ�9Hو�e���Y(�m�k��OW�b;@ÑO�\gd��ez�)$q�i��<YmKl(d�]� ����u���ñY��s�zE�.x�۶bHf�`�1�~8n��~v�b�^��R����!�������� y�v�����o�p�}� v�5�o~�Q�Ε����J�v����I��H?�D��0���>	i��o[,�͕��^�������9�+ �.[�e[�fO�;/��w�,���tV��[���Rt�Y_,�4?�X�2.�vZ���L�:e�XI ����z���w'��7�b\~`�/گ���;��]8��K���f����a{&�F���il�L��������\���\���]�Z�����54j%W��m�H�8�o�n\Ӓ���gy�Uu�:��,蝍JL���E�n���:�O�ʄ�f!�����y�ޙ[��)���AC��e1��K����g�y
�%��:O��,w�
|�����N=����Z��X|�J��9LkRZ�&���Ы�U}���eh�H��O����P�~#���4�����^�CC� �����j"�ߎ�����7��b����`=:��c�s{|����.\�����^&�_���Q-����\Y��>Ƴ���L��������
'P&I�=�N�������"��@���Z��e�����k�������ٵήB?l ¼w���>��v��'�݀Շ�Oȅ��u������s�<g�!�V�aH��e�>���;��q�Ɇ̦�x)�c�J�ր�yr���Ȳ����G�-|d>�Y!"�v�Wn@�ԉo�!;��W����s���^�����_dm�iL��Kw ���m��w���s ��_�V؃���V�Mnz���Iq�BF��[�z���	M�^�x�t�J��������K��H�&�j!��-%��΁�q�h��a�Y�}�%$����[b]��լ����d(��̃��]e쉣�F����D����n^s���������ѧ���+09���H��m�p�FtM�'��ڞ�%��0��`1Ĵ�<jޔV��DXjloѰ!�ZJ�"�� X�%Ԍ�׾�N�D'mVH��E�}ߊ�ǥ��;�XWs��Ji96M]D��Hk{�Ί,�
�{�$�%�.�?p�1Dt�-�-3�//ľ�O���%�sˎtP"��o�- ���3�oJF�'u�1���G�sЕNߍ���Ń�vJ��w9Y�}(As! /8�,WF��g�3�p��O�e��qϋn�xE������2����N��P��ԛח�,:�����H����5U����"��;�Y���
��z�`N	����
#���{rJjm�v	��c��S�e��_߲1(KZnM����wQ�A�Y�aV��E�X8 �C��4��Q��U��A�^~��~:0�����1�$��#E��F����Avw :�z��@�,-�� ��u���qv�8[��(-��9J�׭l|���x�3Es?�]�θ9	P��
�
:�{=��S�C�s�v+lu�.(Xkkw����Xm�ݔ8� ��P�;�O��	�6���L�Ih�o�J{̇�@�a!�M��I˸��_}5^��@���0�kD�P0�]�4F��~ё�O̓-���w+��[?sZ��7�"��ڼ���#�3|S��rC��l�N������|d��*���v����=�"�K��D�\Y����u��h>O����⍻��;�e�(0����^��v�fm�ǌ�s.�5P?e�/-u���4]<Yk����X�xM���Eg�$��$�M���>��1��^.���X���U(b׍�)� R$≩������1��������g��ܨm���Jm�?�����x�����3p?�Oޠ?]�ϧE����byS˳k����Dk�(t]���u�3�%�{�� ��/JӠ�4J���O6�죺�}�-z��3s�x�d�����jdf~�n4�oG �Oa@@�ޚ��Ls�Y3B��F�P��g�������|�A�S���ٷȪ?_ڠ����0��U���ۻ����'�\�E��.��.|r���O��'w�[��|rgr�]8�.�r��+t��S�v��3��'�L;�8�_�#�_���z�!�h}X��*��1�l��r�5ϸ�]x����F��܌^�<޿,��\N�(�����t�������U\yUf<-��o�׋kxh���=ri��M���^����v�w{����u6���i�`f�)�q�&���/�[�{}p�i��JO�R(ĴR�+\JPAt'��*&QH(�wQ+�f�$j���ቄ����pkfű{.vVdC��7i�=���ǩ;o~���	�b�����>
�+T]t_e�I����½Y��ooc�#���(ɗU�#;��y.�R��f�6�ҳ�k�P�ӌ�(K�;�\���[�}f���8Ƃ@�H�o�V8��{6�J�.�Y���˼�����yZ��4Mɗ��-�-:���&ԴcM���B�JF��D�1\��:�]C����)�Ԙ�A��x�&MY�4:'QYxjE<�g�6N�4~�8�o�T<�C�����ӝ�c6�t�Kl���u�9��*�k@	��E7-{���_z���A�|��x�p�L�����(��4T�c���Z��$q7rw�
n�Ȍ@��3�ތ=Gm3]�</����;�9�z��޷x>������o�$0�>H�������S���U�kO!'+WjOk���Gy��o��ɟ?y�kt�~��^�&L{�W�
��������@6���/*���Ͽ�d�W"���<�[�Ë�h40������K�_�_O��=�]g@�x���gE޿�y�.�}�O��3?>y�
��1������⿕Ga�/��nz�:&�����[���b�?Ƴ8��y���?��8E'q�)/<
OnD�]�y�S ��)��.Gj��B��<>��q��Y�->7�PΞ��`��'D�� T��fB�?}�W�&�O� � '.ٕ3n�"������p-t��p�?���_�΃ۦ�G�]����}�S3t쀲>,�]��`]��Y��C!Ɲ���p�i٬���d�:�GE^�Q_lf�f>����o|yHבI�$�����!J�qN�������������?�}JE�B���(�R�M�҄2�-Dr������z��e�9��0�v �/���h�%��r��/$x��� �`4���n�U�Xv�քat�+�$4m�TE-�sL�O"S�)L��n�X�O��3����Aq
N��4�z��yi��
���[	�N��,��m�MSET��03�È��ҙ'�Jc����s��G��)Jܬ	9��A�'�3�n)j�
�rHFp!�3p��Q�-ڪl��ڦ8�	���A��A�̵���M 4�w�uL_�D����dB'; ���]�e����0�O;�2.J^�+��U��=�n2��	�F��YAV�<;�[͝�
�3��9��ڥe�ĝ���b*r��w!	=s4���̱	 ��������oXPx��A�BP4z4mF�A�	0���ȵ����1�|���+��?�d��� ]x�8ɔ�����/���J��Vp���һ?���*]�!4���&�F�2�]/�V��e@��ddKc�-��LA�<ؙ@�2J�rL*�O�ς��KF�R�g�7���p�$�rk���u���	��cHO�[Ӵ�����-uvl/�����>()շ:�p�9��S�!��V`Y��/��MPX�y\�oq6%\ȧ���K�k�}7�G#��s������+�<r?����{�|$H��t*j�ҁ;8~k~4�cB�$�#������-ܭ?i�����+vO"^�)��S[�)���qʱ����������9h}��g���J/:x1��k"t˗74�N�a���g�N�M�u���c���,�2����=sHn)�PWC-qk����\����Z��c�UL�4yߐ^��C=y�#�2h/�ф�"���i5�]E�P+So�<����j�J&��q(��O����<L�)��E�:8�ٙ��*I���C8�%)n���h9�� 'GvF�gA��\����=�E��Qh�0,3�9�W��ƼD㢑������9�j��)��P��J�|�'�t@$B'����t6As����$}:�7:�	���
g��X,q�N�I@g�ޜ�މqJ����z�H��Idu�)�;kU)�M�΢%�@��p_��~��n�si�v{^�+�͛ǈ�̻]�4��{��{Tb�����ry��%��4�d���������m��1��	(S��a��`�1n��NM�Tx�&:R�P%*I�O@fB�"���~g�B��
��4+�+7�*g��߾�P9��ot��_G��(�WO	Q]d�s`���CzsF,����(k ����I|�ƣ�x�m%սYu�_�/�#,n��Z��CO=�T�t8T����7ܣ���w��Y�l+5���:H�d��#N���><��s>(JN�U���_���2]ZF����"QGE�P�ٗ-x� xI�Q��Lȿ�4�<&�t�V�wqNж��� �KNlbG��ׁ�I�~�UCي;��K=�/�Z�;D}%?+����`�1����CKӄz;\�2��x��V��$eJ�:1kG�+��t:;��MrcO�N��c�uQL8lD�ϣ�"�*�ǣ�,VŰ�נ2�U.�6�����Ҙ�31ɨL

���	yy1���F0�H�G@�Y��3e��L��'
�U�i	n9��$��N�V6�iKT���t;���!wm��~�"��|�݁U��P��`M(6����P){��S����{�v6�+���0M���7�x�@�!�M��I�&y!��V�����",:EǄٹXoQ�o�pk��N��r^�[��F.<��U17��.���a�H]Q����t�����ҳ\q�T��'�3���-,7����xb��	�����DS�tp�(\���'�)�@�/p�hR�(C銐@��G�qg|��i�<}����ν�ItU���أ�EB���N��h��f�%RZI�$�]�̱m��Kk�?�J�e�A0U��B�케:Ӧ{i�|����)(V������Bγ61�i5v�JP�c�T��yR���J]��AV]9c���DQ�$�]�:����0���)-l�mC�{�^ȮÓ�I�/rB�J��g�y8��}Z{�����Z���_?���]$�OX%�`t�=a����.bc+�H^u���U�G��)kX�Dt����?c�C#c�$,k5#e���j؉9{�I�E�[�-��ju����~Ή!X�Uɩ�t<����쭧�q�g񰐞)wT�d�����CBvL�d�ݟ��Z����y� =�?�����H���:Ϯ�'�P<��2��Ŗ�崦4te7Z�" �J��"�Q�"���*�I�PD�"�����XV��T �klLO��>1;�k�Ui o]h,�/�$B,�u�?�^���ʁ�O����;C6֠�M� <���E��#A�eIP3���4Mߕ��a��QH�W�qe^��ⵞ;}��jߟRXć�xw@����ӹ�$5�@�~��C�<v$-a`����d\�o�ܖK���H�V���d�`�k6*J�]e��{ѽ�;�� �#�W��q��[)��+�Y��S6_\��w�W�v���A�
ce	a�>�p(y �ϕ����(����0l�R�Bk[����bL�o���h�֕�\��>��>�Z��0���T[ d�D(��}X��U} + ��L�rqd����\�wo9ác �6rZAt�5�v.)ߡ� l�� LWF�;P�d)Bk�Xt�{�X�64�n�M�ơc��rѢp~]��t8������
�s��#��0[qM��J)��tH��bx�[�	h<���8f�&�o�dk|��X�%6	����|�~d9NRj~l�%ɭ����a�� [�p/a�J��?J�x�K|Ukx\�m�"�@����!�$�R0b��g��L��`����g
����&�`����vَ]P�P���{i�=�g�9O��(x���@WҍHJ���W�S�V��8�4��8�"tP3K��DHh��]�y<QMS� ^ϵ�^�%�8*��A��/,��[g��^���\�����0��e~M��D�{Vl��3�];�2����ޕxdH�f���*�nx_��;�βݥ�����ż$��JR�G��)�za��R�)$�S��G�q[�B��1��N��I�m���I(�t�>E?O���/���  &nד�E6�ᑼ��� ��fEL�X�����L�R��Ò��_��6�|.]�ٟ�iPc0X)<�~7�b ��"�4�.����t]ۂ��k�z�?
1�L����P8�7���B�P�2AC��6/�_�1X�	��H�J�����֘\�SM��?bD꬐��AQ�A�ې$��%|^�w�v�9�������s{������cP�R��3y~,<�&�a�Zv=u�V|ThYẈ�0?چ��>j��yH�׺�@9��l��	��VpZJB�Y����2j��q��=�����T4{p��w������K�'&PSD~I�T��kpkU���)$��S\蓏�TS����I��%��m����.�΄DM�a��M�.;6�@����hD��l�$�H���y�h{ 
�H�%`���<�$R���W�?�I�5޶x|��ǎf$���=�,/���/J�mh:�x:�����c(�<_RC<�Є����z�������/��cZ�W��X�U˕��f�Ra�^{�6+�����.���V���_[_���<=��������_�lln�j5�����ʢ����?l7[����@u =�������Y�D��V������-��R� �.��i��Pn�m_����?h)�V�p{֏�m����C{��F��	7�M8xcXE:wO��Q�K�O�0���u���Ys�q_��ڡVN��4�g�?��a%�ۚ׃�&\/t�p�&�0�AS�1��.�;�	�M<Xͼ!�$Q���G�1h�)��)"��%���.h��-�xe "�60?�S��B��b-�(�g&诮���%ɨљ6&���5v��Z�L���a{�r�zٷ�}D�
Ü��-\�ƦE��{�TQ�dV%Ӭbq� o$\qA��� ��� ����E��g������ƹX)�i���|w�E	�i�Sˆ��	&�O�ij�H���.��%��BҘn�r��SB&�lb8W�|�Z�o�X �rnČ�Wv,{��������V�c���"R�a��ܡ�NMv`aV�o�j6���yW���~�O��P���s�4����O�����Rr	��Q���`��ǎ��|}�F4��u�B����HdY��"{�(���*
�s� ���������?� �6�� ��K��ں=�|�a+%�c�W�W�
�*.T*�J�^�~]���aTm4�8g���Xt�$�b%��L�6㵳�ݫkI��+�/��ߧ�[����{6�VPB3Q>Gh��������J����'V4�B��{�}�+@y������4p��L�26�S����ӠEh�BS]>��"��)����L��C�O�jڣ�-��1�0�Z��5�-��HC�)Y���xm��*z�
�U�TENN�"$f^�+l4�*�wQރ�a���H�Xp�����X�6Dl�P
{��6�w����֝;u�����ҰH�X΂ɽ�l�Zw�h`S���M�&�9񣸿~��Q����`��d��9��h��B��y(���}���|�r~QK�NWWň�1܉���������#��%�^�)m��H=�G��\8�9yL!��� �{i��V18 �C�')>�A�������(.�\��ի�;����莓3/��
`�q�%��v�G�pW2����e�\�u4������e�B%	4Q@�@?�h ���T��Oh��>@YƫO�%~���؋55�iS���s� �@����xd�`a$�9
���5��������11o�e��ٵ�P���jR�$���Jmtz��=_Xv���&ƚΈk�N8"د2��C�)|�GIw툭��f�Π,�Y�2���o�d�Q*���o`��2�)��o�����?��<��.p^�����W<��;���>��d�(
 )3�`dX>���'G��"_�3p��Tۍ~�R�Y]�X]3��r��Pl���k�x��M�A��f9-�[L)���å�G�a2x�
9�qQ�fnR��g-��7M��j�FoEx�9bƙo�#}�	DIM�x��KpX���
����2������ē;l5XT��.R�}U�>��;�f��-nf�=��ܸ�/.+1l�	��Y~:��b�?�Bpm �V������8g��%q����M�۷|�,i�̋�����4�&�6�K���S�	�j�\-Zo`G{c2R�+ć+���Lw*�F��.Ѳ|��&^?�	_��|S��L��X�k�]��֫�Ċx\�+���f��A@c�c]w��!��y�������&*1�z��1̵K�&r���������:��Z����yԋgN�+�d�h�3ߚ\��	�{��ĺ1�Ȉv)����#A$�Ld� ԛ����|��E�O�erтy12&�X�O��XLЛ?q���Z��&��\����h����y"0h#|��k-�P%p���()0E0*�� �+��0Զ��L!\�j}坉�9�)D&�1~�<���`i/��g
7[HsqD��8A�C#�١���{x�6iCG�7��y
C�?A=�_�ߓ�+�G �g� A��Bzt�z�I�SP��A2汚cj�+���P#���v;W��x
U/�O|T���vJ��^�p�Z��jj�n�!��46x�gDE������NC�MѢ��
wZ؊�Ey90?�us�|�'��^I5�Ct��Q��� ��'?1���1Y^%J-6!��2�P�j�[c�n�9Z���kԘ�����n!��&F^u�т��K��z��U�f����,+����(���"i���MFr"z8�J�&��5-dM�~�),�Ҭ+Bǂ:�t�MH�8�)F�;�L~�KPi�N#&�P���Ŝ��̶!��ꀲ�N7�)��FV��^��tH���I�8�?�C8FÁ�-��2�q����Lo���h�B-�kT-�����ɭ�'��T�)�J�_T ��+�j�z��J�k�R42�ê�ݦVyh�,�}w�T�BR��>�&�vZ�/��p?jl�z�N�����fAOͮ�t\a� � �^���+�޸�Ά��j�Z�k�2vg�m�kZ�i��D���G!)�Nr��K�J?�>T�_�'���H���]r���H�@�hVhj�uJ�T	����,EBkk!m�������4�&M]bg��v�/ �����K���ц�w��w� ��$�J�:�#u��s.эQ	=��[}�}~�4<���#��4�N�*J�b�CWy����ɔ��"��N& Ԑ8-���+I���;�l5�"�M��	/��,�vl�5l��͟:&���z6�`>z��t���X�/(���ahb^�^H������� KW~�?��ɳ0	t9���T[�i'p���w��K줍�?!���_����!L�Z (�+	Phd�.�+	\�41h$�W���1	���$ʉ����)���+x
�����}����R�5F�x���	���>�5�p	���u��H`�.�ʄ�Dݱ�-��/�7�A�I�&�ۏ_�E>�h�@�ck��,X;��q�i��M�gC�I���xX���_{���L� /�J�I]��$�oI$���Y�{�{�q�\1���B:?��@���S�!�`��l0�w�3��%0~��ʆ
�& �!�/0p��87�,�t��A���	��P���'�rG��[��h���rR!�7��ב�m��b۞7Y%v8)?�\��ϑf�-�կ�Hϊ��J�Rp!�	|�H�{��H3ĻW���t��P!ý���~���#�^*a��9e*v�a��&%�:�~�Jy�|=�Ye������B(
 ��˓!%�5�Ž����{(��KP(O�۱��[�7ؑ�B�6O걱M�Y���)Sf^c�өZ,�����9��f�3��ڊ(��}��v���E� ��$��J;�[�N� @��~v���I� K�g��_���f��Y�翞.�=ƃ�O;rc��|�~?��j�Z�)��:��8��(�_��_>��'Ov�.����)Ӟ���?�|����l��X�ß��d��0�oA���Y�3�P���:���_�?���?w�v.��'��� uL��Ս����m.���<K��}��r̚m59��r۽:�= ��j��{1�,�8-���HQ�%�et�E���2�<��jx���U�����Qe�����5���G����6ڣ������9���+>u|�w$H	e+�ɣ���b�_ �U(��Y~P:�bt��O����B��bB����j��,�Ϧ�>֝�^
WH��F�u2<��7�p��#n������'Q�5��F��d�9Ú>�\P+µ�%�� |�F��r����^��b�Yx4���g��f�Z�<�恌a�by�y�(Pxt�����:W�o|�=�y�x�w��qQ�Si,�sܯ_�ػH@��lY����=�Y�崡����-��,����@{J�n4C�-%o?1��a�m�aN�4DY�ft5�L�ҍ�� �hDW��
���ñ��^N�W��Hٔkm���݈-8/�P��=�*S ��� tI&G,4a��qCV���+\4ZC��hCAr\�~����L?$`A��� ����	�V���L�-�&C���9�ܝ��(\ŵ�������n/r��r�u@_��X�*_�$���r�H��T-�x.H�\A6+�7��!,k��)J����|���A h$#b+�N��i�z�# ����D��>OUB��o�E�>"���;kqg�y�nl���	?QP� S���z��
��u��0ƾdHs|w9���IOJ��Dv�U2��!�f�r�'d�`�����,��Pl�<��K� 7oW�L�Jq���b�x����%��i,_X�P��q�jL,1)�~h,k��BAZ��	|�D���FT�� ��@� ���cٮ�\v	����,)�����7~^d�#�04�+�Vσl�}&��b���W(�����	:@��[}Ph�ZiLnE��On��O<�����_5F�<���[��?]g���Fmsa�y���������ek�^�\<�Oh�}��?u�W77c�~-��c<��������igܦY���`�Gra�;
?us�L��g���O|�#wt��T�N���?,�������a����c�����f4�����b�����U����(���598wᇪ�@g�`�bbMI���"�I���!Rs�v�a�X�{�+����+OkO���Կ~�����`�'9��|�6�˱���O��1Z��u�o}�Cec}}����+{�:�������'���pu�����0�:��P^��Gy"Q��ۏ��f�����x�p�S����QݬQ�ol,���<�p�P����ze1�?Γ�s�u�'��*���_�x�Q���a�y�g��q�3K앸4��f������i���?r�q����UE$��w��K�j��[�0*�x�A��]c�e2��c������YP$��W�9s�x������F�sM� �r��co9v�+唸��/�fjOr����q��f����GyR��ϱ�)�?t|��7�����,�>���'��#DZ4���}g����b����ט�xUo0��[&g�L�(�;��פ�U�.�zZt���x66�ų~������B��}��c�wS���zl�_�t���(�b�_���zy����9�����^Aa��.M��������ߊ=��q�Lq��o� ���U�����Տؕl�೗�wv��R����;5��>{�<��SfGW���_V2@����-��R�:����V]����m�=�9���ۻ��BUaz}<JV�D��Y��x;�}�y�s=S��K���x���<��&��-����6`ѵW�ж�3й|wL��#�=�ጅ��3jgX;�1E;%~]%�S��b�ζ��k�3����Q�,-F ~��1����<�b�(Z���t�����2~? ����ڼ+�q��̴)v;�4�PE{��S9��jRj�(�� 9b����4z��	�C�l���n�Ț�K��m����ื�A	�ݏ�^�S���ӅΖ_�,i�Ž���2u�7�9�;�����eE3ſ�HmN]��K&T��:�EH��k��=�ͽ@��ZKO�V��[�*n��6qg �n�I�	<G) ���50=q���3\Gl�e<�XI�&L�s�"�8�l�m�����%��c�`�xgޡ x�Q��7��t� �G62o�����=�E�s��4���h"˼r�}��jd6���ܿo���_� l8����[(�,�ы�K8lѭ�����KJ��U�f�x��eK�vo�������5�� ��9#�e���?�Gc�\��U��!��n��*`5���{N�͓z�똢���_��W�	��j����k���k���m� �ȼ#"�7@��e޽j����g:�ׇ�Gߟ�>h5�ڝ�7�͓��yة����83�|���C<�w�ϱ�i�R��_��O7k����e_�6��'�籹��Ad���pr�i���s�'2�ǽ�������66���:���|Z[��<ʳ�����$�_���޲7���(Z�#����a-@Ɍ�F�j��h&�w4��L��X���kR< ��V�$�@��M�!��Ս?�ȵ�ݞg��>��S�aP�[��j�R�E�x�E]����l����"�yH�d�"&̥���ߵZ��k������(��_+�v�_K?Y���H�uTsR�l���҂>��ztez@�^���ϑ���q�3�n�����xNq����\��/0�p�]�As����9��x�HM���c㭑�@>0��S!�Ϸ���E��Y<�g�,�ųx�����6< � 