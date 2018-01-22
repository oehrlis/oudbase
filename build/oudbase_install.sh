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
    DoMsg "INFO                                 directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default /u01 if available otherwise \$ORACLE_BASE). "
    DoMsg "INFO                                 This directory has to be specified to distinct persistant data from software "
    DoMsg "INFO                                 eg. in a docker containers"
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
    INPUT=${1%:*}                     # Take everything behinde
    case ${INPUT} in                  # Define a nice time stamp for ERR, END
        "END ")  TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S");;
        "ERR ")  TIME_STAMP=$(date "+%n%Y-%m-%d_%H:%M:%S");;
        "START") TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S");;
        "OK")    TIME_STAMP="";;
        "*")     TIME_STAMP="....................";;
    esac
    if [ "${VERBOSE}" = "TRUE" ]; then
        if [ "${DOAPPEND}" = "TRUE" ]; then
            echo "${TIME_STAMP}  ${1}" |tee -a ${LOGFILE}
        else
            echo "${TIME_STAMP}  ${1}"
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
SKIP=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`

# count the lines of our file name
LINES=$(wc -l <$SCRIPT_FQN)

# - Main --------------------------------------------------------------------
DoMsg "${START_HEADER}"
if [ $# -lt 1 ]; then
    Usage 1
fi

# Exit if there are less lines than the skip line marker (__TARFILE_FOLLOWS__)
if [ $LINES -lt $SKIP ]; then
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
      f) INSTALL_JAVA_HOME="${OPTARG}";;
      m) INSTALL_ORACLE_HOME="${OPTARG}";;
      j) INSTALL_ORACLE_FMW_HOME="${OPTARG}";;
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
DoMsg "Using the following variable for installation"
DoMsg "ORACLE_BASE          = $ORACLE_BASE"
DoMsg "OUD_BASE             = $OUD_BASE"
DoMsg "OUD_DATA             = $OUD_DATA"
DoMsg "OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "ORACLE_HOME          = $ORACLE_HOME"
DoMsg "ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "JAVA_HOME            = $JAVA_HOME"
DoMsg "SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "Installing OUD Environment"
DoMsg "Create required directories in ORACLE_BASE=${ORACLE_BASE}"

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
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "Extracting file into ${ORACLE_BASE}/local"
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
        ${ORACLE_BASE}/local/bin/oudenv.sh && DoMsg "Store customization for $i (${!variable})"
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
fi

# Any script here will happen after the tar file extract.
echo "# OUD Base Directory" >$HOME/.OUD_BASE
echo "# from here the directories local," >>$HOME/.OUD_BASE
echo "# instance and others are derived" >>$HOME/.OUD_BASE
echo "OUD_BASE=${OUD_BASE}" >>$HOME/.OUD_BASE
DoMsg "Please manual adjust your .bash_profile to load / source your OUD Environment"
CleanAndQuit 0

# NOTE: Don't place any newline characters after the last line below.
# - EOF Script --------------------------------------------------------------
__TARFILE_FOLLOWS__
� ��eZ �}]sI���������s��Ź�,	.�ɯf�]��4�����s����D�n\w����G��o�?���/p��/��̪�� $AJ3���������������:��ҳG~�����:�7�����W<��Z�nV�*��V�T�7*���c#����P�sl>�vv6�hG��O�9��wF�h�?�^����յ��*�����Z^[��_[�l>c�G�%������/J�����,��������Xn�`�\���Zk�^a/G�e��ǚ��w����/Y{4:�ϖ^6�y(�6�s�5-�w�3Y��
���^e������־��M�o�ݙ#�g�"jLp�1�{�+>�}�̰پ�s�[rL/�<J+:��_��qP�յ��tn�����a��ݗל�M��V3���м�<˱cY���`���^ϰvǵ�>�vn�?=�Y64���sMd���5��oz�����a���a��k6��.;s\fڗ���ԩ�9=g䳣��T��3�V���|��J�s�9:E�8�<q���̻�þ�r����+���b�\�`��Dal۶|��K�E2B�J�X�`�M�������ф_�ٱ�s��->��,�-��X?> ���#��7͓������^=w���
Y`��^�qϳ��@��b�G��5a���>{k�G���e޶���{u��Ls�qp��kֳG�oZY6� �k��M�w�ٙ?�����_�[���N���7Na����������^c�U�-!�� gX�����4�[[G���׳%0�R���=w�e�-�ŋ�\6�>j�|�j4[��,��x2����r7J�l�-�pH��Әe��lf����h6[�vx�7�k��,vz�����a��Q9��=����d��07��w&�bo<��\ʳ��lmZްo\�3��)�BbjJj:��9�n��g5^�J���z�.+X�[��{�{[���d߂�m������W��}���}H���B/�٩r����0���R�_&O))�ݤ❞ٹ���5�}�Cr)�����{��[c�޴\����5lh��.�t/!�Eɒ�ұn�R`�SrR���L�7;��Q:��|�{��[V8�Y�}��w;#���7�aw�ad�<_�zK��>̵2_D�%�/3J?�2����u�Ck�3�Q�5 �e0|��NT_�gn���{o�`��|U[�MbBz@�5.L��{��>g�&���퀼��[P��! 3���f[����$��`r�$/,�g�h{�u|�{ K����W����|�]���W�l��o�����E�	�iv����w�wX�Vo6�fX�ߵńG2=���,Mh���YVgB��U���R����C��pe�'�4Y�P�cPRW���`Hɟ^�:󃷫�{����K�v����,D+�8�u�-N˪�4�ڮc�q�4�n{�"�M_�����x�!��N����l41��G��h�ė�<	�	�\Aqd/�9�+̴1�YW%;HT�ނf�-�bt���%�93��&M�p�G�D����kD����������j�i����N��i�O��j%�6 ���o;>u���-!�/oT/����V�ݜ�l�#�BO���Q=��`-Ѹ4�>j�Z{*�I���Q�K|g����K#����ˎs7��{��I�������[|q~3�j����[�Bt��E��'����uG�����	u����up�{��z���uu�]��H��k�*GO�[�F�	D5PSp�m�\$~�離Ֆ �����"��Иm}Jz�@;Th��:��
���G*��đ2>K��%x+A~�*��l�9��,�����o�Hveض�<��{F��h�������v�l��}������6&�u�́s	j��
5�A�P9q��R׼,٣~_�<P��a�57�K���} ��@ 9�I�����ʽ�H�Ef㪋��p��a����Q���+��i��j%XW�Y�eܡ� }�q��e�>��_�B7�YEP��R�ڰ�$
'Ő�)���J�p�)��-0�棣���q���Xωe{F�rhЃ�r�)�<݀���0��>O�ʠƕ\�5��F�����MW,����G����Gt�T�
��i�;R�8�8�τe9�]�z��[�~�5�,�5l��ŵt&#�P]���$�D�@�r���:#Ъl2��)YA�{�x;7}gl���?���l�G
��G�_w�Ҭwi՚�j����^����,���,�%�̕�{�����7+�v�UFF6�? Ҽ��&��v��?��i,%��g�������cX��:W&C��ll��Չ��B���ۇ2#&�"$�mѱ����n��	�3;F�$v빔Ȳ�ZH	��#F�/+����_C]=R*��� LĮ3�G��M�?i��n��H�y�QR�$O|cDL8��)G=e�#~Bl�ɟ`��2�\��'�}��e��g��M���f�WS@���]S4䖓�b���7���;Ĝ%fdK��lD��2xF�,��m�̵L�kH����Ч��34]�2=��8�4� }����%62�.h�`�:SM���,��ݹ|��e<b�mۀ1$�х?0�|?7�p?�`�E��\�PZT�J�������\@^���&����[C�AD� Di�5�]a���}T�s���o�ұ]b�onS`�8ҏ���� L|b�D��OB�`��bs�m����A�k�}�t�
���cY�֣����K��,K���F/]��������pA�2�O|!�������f��j�N.V��n,�^h����>�,Wl�e�����a��=�ǰBzE?��l���?lm��P�|�4�u܃��?��ݮ}PB���b��X�����F-�Vyr�7��N�v��7�$�4��Y�p�F]���#zg���'wQ��*D%���Ӱ2�YH�z�p�~޼wf�;��_�(�*`����rF�bF�zG�n�~�Bh�e'�Sd/���h�n�SO�,ft�=�4���*uӚ�֭�f�{��ZU��D�r�8C!��24p<Բ�ƽe%�/�V��&��������! y}����wc�������ƺ�>}k:X��b�X����#���g��]]+��/��\�����[�������~&��`��\�����ܞQ�h�����u�$���j��e�����k�������ٱήC?l ¬w�g�>��v��'�݀�ԇ�Oȅ�	�u�����sm�`��V�aH��e�!���;��q�Ɇ̦�x)�c�J�V��yr���Ȳ����G��}d�>�sY!"��v�Wn@�ԉo�!;��W����3���^�s����_dm�O��Kw ���m��� ���s ��_�Vأ��jV�EnzO��Nq�@F��[�z���	M�^�x�t�J��G������K��H�&�j!���-%��΁�q�h��a�Y�u�%$����[`��լ����d(��̃��]e쉣��z����D����6n^s��K�������ѧ���+09���H��]�p�FtM�'��ڞ���0��`1Ĵ�8jܖ���DXjdoѰ!�ZJ�"�� X�%Ԕ�׾�N�D'mVH��E�}ߊ�ǥ�%�;�X�s��Ji16M]D��Hk{�Ί,�
�y�8�%�.�?p�1Dt�-�,2�//ľ�O����sˎtP"��o	�- ���3�oJF�'u�1���G�!sЕNߍ���Ń�vJ���9Y�C(As! /8�,����g�3�p��O�e��qϋn�xE������2����N��P��ԛח�,:�����H��
��1U����"��;�Y���
��z�`N	��Hd��tj�=9%5�u���Vz�1B�)�2�篂o��-�&^D�绨� �,�0+�ܢ,����\�vk(QW���s/�_;��E�Ç�|L"	`�Hѫ�Ua�us����҅����7KKaS@�r]f�t�]9Ζb J��a���u+F��s��L��Or7�3nO�n�B��N�^�v��� ��[�
�����m��/D�{�%����`.z��S#�D�M�17��w�蛥��!*PdXdS�y�4���|�W_�a����/L��"�}FW?���_t���d��t��ʽ���\ �(�H�ơ6�5-���2š���.�����4  Y�#���a��g�gO��8�$.�%���ǯ*y]>$��ӻ}z�x����`�}
�my=�5���Y�0cu�+{�O��+F�)�(MO֚�b60�(^ӹ4v�Y��3	f�6I�#�<}��y�|L/�����?ֹ��p��u#}J$Ȅ�xb�&��,��0̧~��'2�h�Y�?�W�W����&�V�����O���??��g0�~.���A���E�����byS˳k����Dk�(t]���q�3�%�{�� ���JӠ�4J���O6�쓺�}�-z��3u�x�d�����zhf~�j���G �Na@@�ޙ���f@��u��-��)��G��"�U�8�{���=h}�-���ߗ6hh�(#��@Eo����nk僧3�ɽ�~Q>��s�\�c�;�ɝ���$�ܩ\r�N�s���9�
�.�;w�n�L;w��I9��:N��H�׬ڠ�z7Z� d�JtF}
'�Y���{��3νF�^�?a�Q�=7��(��/�h8�S?�9>�>]a��/pv6�hW^�O�$���"��1G}��c�\������k�;y�j�no_�����3�;������� ���T�ec�woN�-�<^�	T
��V�}�K	*��D�zXŸ�!
	��.j�ڌ�DՑ0<�V|;n�¬8r��Ϊ��bH��&ͽ��C�8u��/�9\�#�ۀ������G!����,8��2c\;Q�7�"�B���]lx�t%��
xdǓ;o��T
�[\�Lцiz6w���}��]TueI}'��zx˱Ϭ���X�)���
?vΦ�QI���0����|�������Hk���� �rܻCۢEg�8�ӄ�v�)7�PhZ�����;�U^G]�k�W�3��4H�d�iC��F�$*�cA���������/����r(��ۡx�3q���z�M��_8�n7F��W�t(AS��E�9�.��@�1�5h�O�On����xB�U8���}LS�T�4�$�F�X�M���wfқ��M8sF��/��Ÿ���t>ucG��3#Wo�������v��"t�-�f�G�c��w��V�@�����zu���ʕՍյ����<�7��ϟ=�5:l��~/E�=�+�S�?������t GG�������E��+���Ϟ�-��Ec8�ž��� �k�������g������3��K�>��γ"�_�ɋ>̧}s���=�����������o��ʓ0ڗ�h7
=R�����z��kՍ���g~����<��g?�q�N��9S^x�܈^':?��@��S ]X]�8�)���y|������[|n��]�sa��'D�� T��fB�?}�׳&��O� �� '�ص3n�&������p-t��p�߷:�_�΃ۦ�G�����}�S3t쀲>,�]��`]��Y��C!Ɲ���p�i٬���d�:�GE^�QOlf���f>����o|yHבI�$��>���!J�qN������֛�����?�}JE�B���(�R�M�҄2�-Dr������z��e�9�W0�v �/���h�%��r��/$x��� �`4���n�U�X	v�V�at�+�$4m�TE-�sL�O"S�)L��n�X�O��3����Aq
N��4��ݾye��
���;	�^��,��m�mCET��03�����ҙ'�J��sɏG��)Jܬ	9��A�'�3�N)j
�tHFp!�3p��Q�-ڪl��ڦ8�	���A��Q�̵���m 4�w��M_�D����dB'; ���]�e�잌0�O;�2.J^�+��U��=�n3��	�z��YAV�<;�[���
�3��9� �ڕe�ĝ���b*r��w!	=s4�T�̱	 ��������oXPx��E�BP4�4m��A�	0���е����1�|���+�?� d��� ]x�8ɔ���
W}�/���J��Vp�����?�>�*�zKh*�A�M�5��e�V�-!}˾@��ddK#�-��LA�<ؙ@�2J�rL*�O�ς��KF�R�e����p�$�rs���u���	��cHO�;Ӵ�݁��-~uvl/�����>()�7ۭ�p�9��S�!��V`Y��-��MPX�y\�oq6%\ȧ���K��}��G#��3������k�"r?����{�|$H���t*j�Ё;8~k~4;#B�$�#���o�ZMܭ?i�����+vO"^�)��S[�)���qʱ����������9h}��g���J/:x1��k"t˗74�N�e���g�v�m�y���c�[��,�2����=sHn)�PWC-qk����\����Z��c�UL�4yߒ^��C=y�#�2h/�ф�"���i5�]E�P+So�<����j�J&��q(��O���<L�)��E�:8�ٙ��*I���C8�%)n���h9�� 'GvJ�gA��\�����E��Qh�0,3�9����ƼD㢑������9�j��)��P��J�|�'�t@$B'����t6As���$}:�7:�	���
g��X,q�N�I@g�ޜ�މqJ����f�H��Idu�)�;kU)�M�΢%�@�	�p_��~����si�vw^�/�͚ǈ�ͻ]�4��{��{Tb�����ry��%��4�d���������]��1��	(S��a��`�1n��NM�Tx�&:R�P%*I�O@fL�"���~o�B��
��4+�+��*g��߾�P9��ot���D��(�WW	Q]d�s`���Cz3F,����(�����I|�ƣ7x�m)սQu�_�/�#,���Z��CO=�T�t8T����7ܣ���w��Y�l+5���:H�d��#N���><��s.%'惪d���uD�.-�|��b���"Q(���<��$L�(�a&��hD�q:n���8'h[I�s��%'6��C���@�$�0֍���lŝz���N-���������}�b0ĆA`Jš�iL�m.D^u<�N�q�P�2�
V�����YO��X���'f�@����(&���g�Ǐ�Cȣa\�bX�kP��*�i}3�
[{Wi�錙�dT&�ni�<����CJ#��O$uܣ �,j�2��j&��C�
�*֤��?w�N�Y��t�g+̴%��Ga��@�Ԑ��nC�r�Z>����q`(T�pU(6����P){���UYÿ�c;���U	�R�&|��� w<x ��&z�&U����Y	+s|��z��c��\��(l�7t�5Ru'�l9/}��MzF=q⪘�PSU��0U���M�vZp�]G�TZ�Z�8N�N�c���	��X��l<�g��H��o�)D�?��s�.QK���� ��pL�)�D��tEH ��#��S�	>_�4F���~]O����$��qY�CI���"!i�@|�NT�En��)��_��.�{��6Mĥ��r��� �*�^�sv^@�iӽ4b�@�Q��ST��}GG!gY���ۏ\%(ֱF�z�,�zGY�.{g �����Ga��Z��
�.��p�͋{�yT����ض�½�P+d����&�9!Oe����y8���X�H�K]|#Bޯ�kp�/�&�{0����VJE��l$���M\�*���ؔ5�R"��M\�Ξ�O1��g�������H�~5�Č��$�"ۭ����H�:��{�0��,̪�Ty:�L�}V���vɸ�xXHO��;��B2�����!!;�G����av-}e���L�����ez${�q�gWғK(��Z	�^X�b��rZS꺲�I�Z	%}L٨h��FE¤r	(� d��azBVqU`,+OO* �5	6�'ei��ҵ�4��.4����!�:��l�Y�H�@ߧ�F��ā�iP�O��tâ�鑠��$��^Vu���Jս���0$�kP��2�Ԉ�O�Zϝ�VL��O(,�Cb<����|�}���S��v �]X�!D;��0����k�?.�mn˥Mm�S$�D+ULz2S�d�5���.3����^���F���+~ø��-�����,��)�/.��;�+k��]�L����0r��8�<���J���b���J6�V)n��-��vCmJ��	�ZHj��q��X&P:�\_O+ra��NT�) 2�C"�/p�>��E��>� A�i��?2\�HI�򫆷�����Y�9� zB�g;W����@��aM�+�=��W����%E,z�}�8��~����a��1|��hQ4�Ew:J�gx�nƹ�1ב[�x�-�&�b�VX:$BV���Ɋ�}��3�s��+��yP�>�e(������dy>�?�')5?�Ȓ�V�`ck�0SI ��x���^�M��l����5�<.��� ���_����|�D)���ųpUd���X�`���1��˂NYe0
���G�l�.(Y(�+ǽ2ܮ��'���C<��\ЍtCҾea�U�T������<M�6N���ҿ;�>Z$|�`^T���я�s� �UtI)�J�x��賋
�����)g�W��;���<2=F��F�A��p�Pq���)�Lb�κ�9��)�w%�{��敦I�E���N�G���vi8�o4p1'�����х�sB��^@X,'Z����	��"Ÿ�rB�u�ܘ�P'��$l�E��$u:�����#KPj����S��I�"��H�]����K3"�,�L��S���'f)q�aAs��/H�a��>�����x�4�1���u��{I1 �nT�D�W;�5e���@�¥�m-����I��v�:��N(�ؐ��]���G(�G��!�D��/^�,��a�j%^\Z�FPkL��ѡ&�џ!"uVȎ�(��mH�������L;��F�l��g������q��d�)(T)���<>J�ǰN-���i+>*��)�QY��l�Zy5�]<$�k]�x�F~�|��ax+8,%!�\LχG5\����@��D`MB*�=8���;p�Hz��L�%�c�)�$*@�5��*�\����)��'Y������1�����ҍ6��jz�[gB���0]Ǧf�b�]��bj4"�c:dE$���+�=�q{��0^�bV��dx�-�����<���c'3���y��x���$�.4�H<�B|ێ���!�c�/��	XhAW��b=[�|� ~|��ϣ�1)�+�K��V˕��f�Ra𣺶���?*V�����1]����cq���um��O�t����gS�?�����_Y�X���S<����Fs�Ut�����ZZ���7��H��������Y��0]��ե%0mߠ*­��������e@��n��Q�MZ�a7yh�;�	�X=��ƣ�	o�H��i�3}����1x��14�"k�1��yO;�*©b:�F�쯃��<�d[�z�V�녁�����=h�?�W�}�8�����7��$jqrw�:M9�q8E$��$~ ��ѱ��D�����G��Y]���P������5526%5:��d����[+���:�`W�_�zV��(Xa�S\��ٴ�0x�J#��̲d�e,��$�k� �ݴ�2]^dY�qV��"�,q;��9��":����:H"�<Mwjٰ62��$�)4mB-i�X}�E6��-]H�̀Q.��JȄW犙�\��M`\V���́���ʎe�>�����?�7�
qlRT]D�7, 4�;4���B�,����R-�f�5=���]����~j��{ޓF�c_��I��0XK.��{4�tW���Q�/0ъ���ZhY���,��Zd�p� %��RE!t�䃱>bQ=�� ���� ��� W�c���e[��0"l���`�vK��X���@ŅJ�PY=��ժ_�ֿ���GU�7�Y4>.]z+I�X�s4ӠMy����t��J"�����)�Vq7|񁍅Ǡ���l�/� ����0�%#s���Ň�M��:|�~��P`��s3?	�e:8�恌M�ԁ�;p��$h���T������vq�#�#/�/�P�c���(�K.u/��Mh�#{.��B`JC��y� ^[�8��.�c�$UA�������
��J�]��a�$%�9*�0�9g>F(����<���$B��,�}�"��u�N��z���4lR*��`ro(�'֝ ؄�)�kb����u��(�o�_t�fTpb�9�=2�mu�2?��P$}
}yy_>}��ߣ�_T�R�r���e1bywb�k��(D�l!m����ɥ�qJ[fKRO�{>�NdNSo�%�9�nZ��7G�U��P�I�hE6�i�Ei$:;�,�����g�Wt�ə~C�C��}�
��;�#P�+D��V���O.�&��ne�P��l
���(�D�W4I�x����4W�l�,��'��K��?�Ś�δ)�¿�9vJ����[<�Z�0��nx⚂\N�k^�K����wȎ�o��ZQ�һT5�[�KL`�z=vp���,;~�@cMg�5U'�W��7���ӣ���v�VGF3yg� �Ѭ`��O��e��)����׷NK�R�7a���ß�EJz8��UsR��+��ޝs���^�nZ2`��Z02,���F�#����/�8\`��D��k)�.����r��N(�y�w�p�5y����_��]f����-&V��R��R@���0���N��tҸ(z37)R��S���^ϛ&΍\�A#���"	<�2��7�y	��������h�X��%8���y����~�PL�}j���,*�u)ܾ�jƝaSF�7S��QPn�����p���?I�l1�P!�6�K�|VwO�N�NQ����\�H���Y�I��L��up�}YrP�E��^���B��'WK���Gވ̀�
��
��"ӝJ(�ѣ�CG�,8����g=�,���o�u�)�u}�"�~����m��J��ǵ����n��4=�qGx b��@ۯ
��m�C���~�\��.`"�H�KZO(�|�c�uz�� �G�x�4��J���.z���ي���W�L@�c���8`�+�<DR�D6	B�9�{���'~K\��Ě&-� c���M������:��Q��~Ah�*��>���~��]~ߚ'C�6�WX���U��K;��S��HѺ"-Cm똊�$µ�֧�Qޙhݐ�B$`�
�����x��B���p��4'�G4p\�i10��j���Gqo�6t��x�;�0�������=I�"�q�|���/��Q@��D?e�$c�9梖�@���� e0"�H`�s�.��P����GuSY�`�t��
G8����&v1���Nc��}�ATd���4��Ф!-�N�q��-�]�W}�#]7��Wy���ՐtQ�8DG_��x��K���U��bc��-�U�&���t�Ӡ��F�)��N������>ib�U'-8�d���Z5mٛ@�@˲r�J�b�^�.�F���x$Ǣ�s�mr*�yQ�BV��W�>ͺR!t,�c@W�ЄD�c�:#���7��&�4b�
��`��Z�	��l��ʮ(K���q}���kdu������ I����T�C�C8�c4�R�+������VK
�F,���B�z��[Ϙ�j}b�Je���E �R��V�gL�T�q"E#�9�
�mbU���ϒ�w�J+$���o��3l�ja�����	��F�G?z�qi���H�&�^@y�*<���:~�lpU���Jq�XƎ����w�B+] �Q��T�@���QH������R��݋J��b����)�[�K.�����
M͵N���*�v�☥Hhm-�M]�~��&�¸�K���N|�E4�w�{	4;�P����~�?��Z)_�x���p�%�1*��Y �x��Y���O`����:zDv�&�I8@E�R�p�(�qt�8�2�V�v����E^yr� ��vǙ�fZ����О%���m�������S��$];Y���Fo���K`C�E�u�6M���� v���B���t����è�<�@��0�:@��vG�qy��N�Ďڈ��o����x̰�A���ѹ� �F���"����EM��F"|%�〉^L��ȫhﱞY����p�h�ا(]/E[c􍷏۝p�/�3^������9X7��V�R�LXJT������R}�D��dk2:��%^䃉��;��1ς������6O_�d6ĝ�Z���%
@��g���$�R�Ě�]L2���D"���u��P`���}ǎ���[*��s��+pԜ(?v�LaƿMSx;#_�1Q� ��@�l� }1�p����7��,`�p��	\LN&~�B?B����om
��"�K�I�����
O^Gȷqm{�d�����sy::G����V�"A<+�@*�KхP&��"}�e."��_ÿ��E�#C���/L��R���^�T���s�T�8�
PMJ�u����J�Z&��޷>���9�P ��s��'BJ<k�{�Ӂ�c�P�ʗ�P��cup�
o�#Y�fm��e#����C�S�̼¤�S�X.����5sNi/̀)fx-�Q�>��쮮��,:�yIT�v��Z{�V�� ���?p��Q�(ϔ翪�����f���ژ��z���v���#�1������UV�x�k����z��/��/����g�F����唂i��
�T�������@6���O,����_G��Y��� o�x�,⅙h(��m�h�/��������{P;�O��g{�:&�����fd��n����<��}��9fM����x��n��ppT��z��y��K�&�u�������2�����C��a��y5�L�ժ�|�}]Y���}��O����
k��������G@�QE��Tg���=��ھy�;���%X����Ҋ\1��/��*�nu-?(��1���'^^�h�_h1!~�Y�K��X��g�b��e��+����:���x8���`�Ds|ӓ�Ӛ^x#�q2МaMl.���ג�Y >Q#πp9�f}O/�j��,<�q]����by�X-W6�y c���X�`�9
�#*�����ε�y�m����83G\�jW�ǣ��j�W%�>��[�9;�^]v~9�+��ar_��6 �41Ҟ����CK��K̫d�C[��9Q�0�]��$��t=��"H&��E)�����x�Ӷ���t-R6�ۇA��t�b΋�8T �~O�� b�+ ]��MC�GܐU�G|�
����{���PЇ���/��	X����#0~)t��U��!�zKk���x�"w�p0
Wq�l�k0)�9/�r�Ӎ���|��׬:���Wt ���*�\8R� U˅'�R!W��
��qz��f
����3>7ka~Ɉ�
��$pZ&���Hq>�/�?�D��S�آ�|����$h�[��i��[�#f�O�"�T�/�.+.sw���֍������]��A�Ǔ��y}��xn���hH�Y��	Y �a|è/J�3[/���7ȇ�ͻ'ӻR�5�w��C(��`��z	��rꋗV,֡o��K��J��E͸^(H�:#9�o�HX݈*|dv�(``w�{,۱롃�.�u��܁%%5��R1�F�ϋ|�{-��z0"�͹�D��C,��
�~��{�"A(�w�O 
�X+��-ɟ���Y��G[�����i�e��W�kk�\Y__ݜ�����������ZxP;�O��k�O�������_�������y���y����I��)X�������O�<������������&ՙ�af�K)n���%�����I��ju3�}s}m>�?����*���}QWX����CU|���0B1qUIl�k"�A���.Rs�v�a�X�{�*�_?�U6V7jk�Ծ~���`�'9��l�4�˱��k�����O�`ЪǮ�|��*�k���O�`��Ǯ�>���9���x]�WǴ�_���������'%�Q���_ݬT������q꘾�׫���������$O,�#�q��V���O�D�i���Jym��R^]�X�������$���g�kqi���ݡӞ�m���v�k;��&�H�o<�R�!�J�O�(aT���������d�m��w-G1.����H k�r7r���d�KGǆ������I�s���y�'9~�l����^����>ɓ?~�uL����c��Y���O�̝>����'��#DZ4���}g����b����ט�xUo0��[�g�L�(�;��7�>�U�.�zXt�sAo�����Y?��r�"s;W��D���Xf]Ǆ�u-6��ml���������Z/O?8�ܿs>�+(�ޕi^���٨�|���}�G�����V��9[��*@>?Y��]��
>{�fg�/�����S���/��;evtŭ��e%����Ѳ;.�3>�+ՕՕ�����{�s{o밵��;j|)T�ק�d�J�\��~�}�w#�瞇?�3Ế��1I�[�������m���\�{�gf]{5m�>��wGtq�8r�em�X(*>�v���SP�3PP��UB>E[+&�l+���1;#���I��"�b���(*��S)�񋢅�/o@�Q/��.��`�7PZ�ͻ��L�b�SK#U�7YN;�^�&�F��!��2�#��>�AO��)��<�Ζ@�l�括�o��K�Vع���{{�0���u:5����]�l��̂�[���\.SӾ{���:�8�.�YV4S�[�T���%��dBɝ��]�T�&Z�5���K$���tE�I��[����ѱ�iw
����� �3�rر_C ����,?�uĦXF�c���kR�d:'Q.C����/ޏ�\�I�F�g�w�=
�%�|��N�yd#�ΰ}�n�>��Y�~:7�L/��&��{!�?d���f��H��������5��#��ͼ��0ȂQ������
~�����Q��hv���^�Dl��<�qέ^�ˁ9�{�:%x�Px�]�����ȯW�}�$D��.���Q߷
X� ������=�:&�����UAw�������'y޷�^o�>d�gTd���렁��2�_��Z��[2��֛���O�4G���������<�T���n��}o�^d��1�Ի�gXǤ����_��������e_�6��'�籹��Ad���pr�i�����'2�Gݓ����&��7�������X���<�3�����$������޲7����3�	�?Il��d�{#�5=�4�{��Ra�P&�l�Aj��5) ����^�}\ \�&�\��ƟJ�Z�N�3epn�)t1��?�,@R5�L(��M<yq����Y[I��TMC��<��	�vfR�D���Ո��fy}��I���V��6~��[M�	�����椼�$��}�S���t���N��#����g��3�)�)t������#���_`&�;v��No%	vr���⑚:�-��[#M7�|`:0Q�B���s���3����?�g�<���;PZF � 