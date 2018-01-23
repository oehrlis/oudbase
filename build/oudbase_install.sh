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
� V&gZ �}]sI���������s��Ź�,	.�ɯf�]��4�����s����D�n\w����G��o�?���/p��/��̪�� $AJ3���������������:��ҳG~�����:�7�����W<��Z�nV�*��V�T�7*���c#����P�sl>�vv6�hG��O�9��wF�h�?�^����յ��*�����Z^[��_[�l>c�G�%������/J�����,��������Xn�`�\���Zk�^a/G�e��ǚ��w����/Y{4:�ϖ^6�y(�6�s�5-�w�3Y��
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
?vΦ�QI���0����|�������Hk���� �rܻCۢEg�8�ӄ�v�)7�PhZ�����;�U^G]�k�W�3��4H�d�iC��F�$*�cA���������/����r(��ۡx�3q���z�M��_8�n7F��W�t(AS��E�9�.��@�1�5h�O�On����xB�U8���}LS�T�4�$�F�X�M���wfқ��M8sF��/��Ÿ���t>ucG��3#Wo�������v��"t�-�f�G�c��w��V�@�������d���������I�����|��Ϟ���f���	Ӟ����?��g�f:����C��J�?���"Y��H��g����1��b��|t Ƶ��A[����׳g��F����%^���?D�Y��/x޿��E�Ӿ�mw͏Ϟ��¿�G��_�����o�I��|������ms���V���ju>��♟��<�?O����n����xN���'7�׉�O�<�)�r�HV�C5Nm
!l`���h�,���A(g��\�n�	zn�'�#t����OA_����	<�!�%ȉ+v팀ۮ�k=ts�4\w<\�������Ŷ�B��CvGC��y�`��;���r���"XW?+CD�%}�P�q��@40\sZ6+�h>��Q��y��Y���ن ��'�_�ud�+I���d x��o������s���}�����t�R�P��#-J�yS�4��b��8�#�u�~}m���́���K�r�aɡ���	&�{,@� �(0��A5V�ݲa���"	M�.UQ�S�Ȕ,EF���A�[�*���a�j��oP��� �D,�n�o^���~��N��h,K�~�x�P��� ��z0b)�t�	�����kC�\��Qiu
�7kBNnm����L�S���ǂ�B�5�\ȃ��qr��*[<��)�|��6q��x�3s-e�~���]`mӗ�D���*B(����}mw�s�9�'#����μ������x�n�F�B�ی�c���:q@V�=���Vc����̦yN/��ve�0qg".,����D���]HB�E.�5sl>��|�.8�C��^�*�nѫ�.M[��;APpB�̪��7t-`�6r�*�ſ�J��O= Y%�4H^!N2�xy��U��?�!G�\Do���ǥ��߬��Jv�`�q#`��rK�G߲/�o*���sK$;S�F'v&Ч����J�C���a���j�����8�8�_D���>lm�~B�q�ғ��4�zFw �:c�_�ۋy�D�/�JJ��v�%}Τ�i����X�� fˮjVz��[�M	�)jj��R�Fo�-��H��L����}�����O=<:�#	�s��:�ʃ�;t`��ߚ�Έ�(	������íVw��Oگ��}�y�ݓ�W`J�G���pJ:�p�r����u����>.rGߡ;���z�ҋ^ze�z����͢oY�oF|��٨�x�j� p���V�1.�s��6,B��[�9��PK��?l��' 4+�r�Xd%M޷�*�POE��䈢�z4���=)iZ{W<���ԛ(�����گ�I*�q��&��S�xh<�i�}h���|v�x�JRf���pI��o�=ZN�+�ɑ���YAP�G<����@GdQ+yTZ������b��u8��1/Ѹh�5�8=9B�j��?pʺ8"c��4���I�!��� f�%�MМ%��8I�N�t{����b�$K\�l�hǅ7g~�wb��l�j��9R}mF]�D���ZU
k���hI0�g)ܗ��;�\�ݝ���g��1�G�nW'M����:���Xi��@`�\�$m��;D2��5��&� !x�jw~�Teuا4Xm�[�S&�ɂ���T@�JR��Ӽ(����;��/�&��*�ʭ�ʙ��/5TNp���-�7�-9���ABTY�3>�ތ�~l!���$(�b����[Ju�_T����˟������c ��S$#���h�������)g�2�JM0"�����9Y�C񈓽i�O$�Eɉ��*�k�Q�K�(�0�B$�H
6����/	#Jv�	�7��Ǆa��۪ �.�	�VR �d}	��M����{:P>�>�u�jb([q������S}��/�B��c�y���!F�RqhiSo�Q�WϾ�l���L��U'fm�yE֓v{'��An��)x����.�����h�Y��c��P�h�Ū�Tf��e�F�����Us:c&&�IA��[�!� /&�����I�(H9��|�L>��I����D����5i"���|�2����3m����Q�n'�75�n���Я\������?�j
��\���dtƾ*T����U��o���&ttUB��	���&��6��޷I�$/�rV��>��@�E��0;�-
��n�T�	�9[�K_�`k��QυG��*��:"��T�#9L�+jӿ��n�Q7����+������sF�y°��V|8��b6�x9�h
��O}���K���d:�1�.m@
"e(]<���:�c�ϗ?�р�/�_�ӹ7�0��j\��P{4�HHZ ߩm��l�DJ+����9�Mqi��\i�(1���W蜝�@g�t/��/�~�8���`}��Q�Y�&&<���#W	�u���>K��QV���Ȫkg��Q�(���¡K?B�!�~��Ft��=��-�m�p���
�5x��I�EN�SY��yr�)���y7V7R�R�ȟ��������	���.�Ǭ��R�Ellɫ�b��J��26e����c����SL{hd���e�fb�,ҿ_;1c/;I��v뽠e3R�����>�91�*9U��΂'�y�Ձ���]2n�B�,��#�⎪��LxvrpHȎ���s�]K�A��c0/�G�ǽ�y~��w\�ٕ����VB���b��֔���FkR�VBISD6*Z$�QQ�0�\�( Y��r���U\��ӓ
�pM���I�A�'f�t-�*����Ž�A���"�k�?R9��)�z=q`g�F����=���(wz$h�,	j��U���Ru/,~>���#��+5��S��s��S��
���O �(�py:��䯆�}���ǎ�%,tp����m��riS��	=��J���,�`�F�@颼ˌ}��"�Wcg��~����0n�{K��|}i1�}��˴�����nw�<(Sa,- �ܧ%%`��q��� �F�����UJ�[hmK3��P�R�i����aܺ2���'���S�\&��j���e�\�+|U���`�S��iZ.�0R�����-g0p���zN+��Р����;4=�uX��ʈxσ �,�B�bM˃.p"+����魰�i�8t�u@.ZίC@џ�����[�q�`�u�>fK�I�X)����Uoa�bk_ �'��.��ʄ�m�l�yK���&�1>Y��,�IJ͏��$��=��":�T�bK�%�Wi�G)���j�>����:@�%藀|~/$��C Q
F�p}�,\���i� 0,�>�L����SVD�6���.۱J���q��+�l<�I<��Ϸ:t%ݐ���@Y�q:l�(�3OS��.B5�t�����&	�5�����0e����(@j]R����/%.���B�q��ApJ�Y������?�L�j�Q�Gд<�@T�g�a�>�ص��b� y
�]�G��nh�y��Ri��E������4�]��\�K�F�$�zta�P��&�	�V#��=wB��H1n��Ph]�7&x�ɳ:	�m7;	E�N"�a��������"������zR��F6<����1 �Ҭ���4[�"Ôs"�YJ�xX�<��+�`�&��Ϥk5�3!jk"�g���fR@�U�����tMق�i[еpm|[�b�G!f�)����p�
'6�w׼�@���Y&h?������w#+=�~�Z	����+~t�I��gA�H���8(�<�}�$8��/«�>�N�`=�4�a�ٹx�b�p��1�~
U
<y&Ϗ����9�Sˮ��ڊ�
-k�yT�G۰V�G�3C7��Z�B(�р�-_=a��
NKIH:+���YF�b�0.Pz 6X���fN0���\8��?:xI��j��/ɑ
�un�J=�6���|�}�Q�jjy~�t>鶸D�t��<����֙���8Lױ��eǆh7���������BI04<�
m�Ca��������D*8^u��G?����&�o?E��ь��23�G���3޷�EI�M'>O�߶c��y��Kj�g��Փ#�X�2�;������uL����+��r���Y�T����>c돊�x���?vL�sx���X\p��_]����<]�������Zـ?������������?l5�����Hu =6������Y�D����>����-��R� �.��i��Pn�e_����?h)�V�p�֏�m����C{��F��	7�M8xcXE:wO��a�K�O�0���u���Y��q_�{ڡVN��4��g�?��a%�ۚ׃�"\/t�p&�0�AS��®�;�	�M<Xͼ�$Q����K�1h�)��)"��%���.h��-�xe "��7?�S��B�}�b-�(�g&诮���)ɨљ6&��v��Z�L�G�a{�r�zճ:=D�
Ü��-\�ƦE��{�TQ�d�%�,cq� o$�_sA��� ��� �
���E��g������ƹX)�i���|w�A	�i�Sˆ��	&�O�ij�H����.����B҈n�r��UB&�j`8W�|�Z�o�X �rnČ�Wv,{��������V�c���"R�a��ܡ�OMv`aV�o�j6���yץ��~�G��P�F�s�4����O�����Rrޣa���`��ǎ�|}�F4��u�B����HdY��"{�(���*
�s� ��!�������?� �6�� ��K�=��:]���a+%�c�[�W�
�*.T*���Ie�V����5<<¨�h�q΢�q���[!H��J���m�kg���WW�y_�]~��Oٷ���l,<%���f�|���74���/Y;���/>��h���+���f�(�� C����I�.���6dl��݁�5'A��T���|NE��S	y�|��*SդG�[r�cxah�p�kB[�s��0S�$�3����IUty�&�
���\EH̼�W�h�U��| �8')��Q��vY�9�1B��m����&"md1�z	�;w��<Od��a+(�R���{C	�<����&�M!^��?��s�Gq;���7��C����l�s��� ��"��P����"��#�����
�"�+�./��c�^5G!2diÕG(�M.��S�2[�z
��#�t� s�Bx-�)����9"�bp ��*OR|@�(�L��(J#��Q\`�h/>�UW�=߽�{Nμ�*�
��;W���)��]� ���z,�}r�7���w+����eS�$�D%����HJ�S?��jd� e�>���]r��a/��t�M���α�P�&���Ղ���(p���r�^�B\j�ļCv�}Sg�z�B�ޥ�qݒ\b+��鱃;�|}`��{�k:#��:�`�������%Eܵ#�:2��;���f�`��+�m(��F�|Gg��uZ�@��2�	���.�P�;�yŮ���_�p������tӒ�( ��Ђ�a�t�6R�1�7�|����Sm'�E\KIgu�6`u�H���wB�����#��㝦7�Z�2�%䴘n1��"��"�J5��dd�u*d䠓�EћA�I���J����x�4qn�A�I`���g��K8��5> $%5E�=�2@�/�a-�[�+��6�ˠ�b��SO��`Q!��H��eU�xh0��2�p��2$���r����İ�'�ge�� H�g�A���
��\Z峺w�v�v��u��RDZ7�N��M��e2/��#��Ґ��,ڀ���/��J�>�Z*����8�Fd��W�W`U��TB	��:�e���&^?�	_��|S��L���[��Õ�.on�UWbE<�ŕ}��v��� ��豎;��+���~UX�Fn�rM�����ڥ?t�ی@�]�zB���@��S��<��3��W2u4tљoE.�V�ˆ��reb�kd��p]�� �R&�I��	�S�d>�[�"�'�4�h��� |,اh
f,&�͟�Ձ���p-�BVa.wq�������<�����E�8\�Y��"�Ej���iyj[�T&��]�>���D��"�W�_���s����3��-�9	�8���Z��H����P{x�=<�w����ś��<�����/��I�َ#��3d� �~!=�:G��$�)(s� �X�1�d���u(��F
� ���tq<�����'>����;�{P/W8��\t5��i7M��t<�3�"�ux�p`�e�&iQuz�;-lI좼��9u��Tm�����!:��(p�z���㟘\J͘,����n�xF�Z5�\��-P^�5jLIlu�}�n�W�I#�:�h���%C}}Hժi����Z��[�TB�bv�4�TV�#9=�{�h�S͋���F��ti֕
�cA���&$R�����&��%�4Q�U�]�u�bNHefۏWvu@Y�D'����^#��䎏O��H:$��h��B�¡��@薂�X���8Vvhl��Z�Ph4b�������S��z��V�C� U*Ô@��/* x���R=cr�ڵ�)�aU�n��<�}�Ծ{U*X!�̎~�a�V;��W�L�5�pO=r'���S�KӠ�fWE:�0i��B ��T����vw��Kg��J�X-V���2vgol�kZ�i��D���U�BR���v�ʕ~�^T�_�'���H���]r���H�@�hVhj�uJ�T	����,EBkk!m��'����4��M]bg��v�/ �����K���ц�w���� ��$�J�:�#u��s.эQ	=��[=�=~�4<���#��4�N�*J�b�CGy����ɔ��"�Î' Ԑ8-����+I���;�t5�"�m��/��,�vl�5l��͟:�&���z6�`6z��t���X�/(���ahb^�^H�����߸��+����E��Y��hgy����8Z���;t�%v�FԟKԯ��C`���B- �Ε(42L�ݕ.j��4�+	h`�L�b�D^E{�����Ǖ<�E[xF�>�@�z)��o�}���~y���8��|����m$�j��xe�R���X�F��� ��$[����/�"L�e ޱ��ix���8��y���&��!��jL<,Q� �o<S�N&y��R%֤��b��7�$Qe����]�˽>�8v\��R!��M\���@���f
0�m:�»��
`���MZeC�1H_����f���n8<H��b"p2!�� ���Dx@�ȖxkS�!^ZN*D���Vx�:�@��Vl��F ��'姝���9��E���	�Y� R�_
.�2���s/s�`�x���.�*d��a��z�?�j�� ,�S�b��hP�jR�c���W��2�e�������90/�� p̞۷<�R�Y�X��,��R�P���D����Ux��*4k�.������2e�&=���r�}���sJ{aL1�k���"��ٷ�`wuuU4`�q�K�:������k�
 ��gw<����r�Dy�<�U�\�,W6�t�kcc~��)��1�+�P���_�{C��[]�������7?��$�_��_>��g�v��o���)Ӟ���?�|��Ӂl��X�ß��d��0�oA���Y�3�P��ژ��_�?⿭��?��vΟ�'���(uL�������_ݜ���y~��"�r̚n59��r���=��j��
{9�,�8M���IQ�%ket�e���2m�<��jx���U��
���^e���������G��㧏�6ڣ������1�{�+>�}�w$H	eK�ɣ���b�_ �U(��Z~P:�bt��O����D��bB�����j��,�Ϧ�>֝�^	WH��F�u2<��7�p��#n������'Q�5��F��d�9Ú>�\P+µ�%�� |�F��r����^��b�Yx4������f�Z�l@�@�0y_�<�<s(�:T\Or��k�7>�x�8��Żqf���(Ԯ��G�9�Վ�J�}$���(sv����,�rZW\G��Jm@�ib�=%C'�!z������W��O���0�s��a3��I&C�zx�E�L4���Rj��A͋�X�m/'���Z�l�5���v�n��q� h��l�) ��W �$�#�0�揸!�l���.-�!��[���9.H?^�X_��� ���G`�R�{�z]C&����!�y�E���`������`Rs^�b���o1�ڧ�Yu,g��� ρUj�p��sA��N<�B� ������O�%wg|n>��� 4��p�I�L
=���|X_��N��*�E�7�"o�I�������8jշXF
̄�((E��X_�]V\��8}ǭ#�	2$�9��@�w�$�'%A��";���2ѐl�j9��@0����Q_��g(�^��%n���w+N�w��k�@1��P���m�ĥ��/�X�C�8H5"��j/ꋚq�P��uFr� �$��U(�.��FP.���6�X�c�C�]�f�w�KJj���b���8�Z���`D�s��6�ÇX$��
��f�)��E�P��V� ڱV�[�?�㛳���>��W��:�:����V�6�Xÿm��?O�|��_[���l-<���'�	�5�'����fl�ï���gn����_u��<����$kp���H����G�n��@��px��o~��t���	�03⇥7@���?�_�xs�$��������6�������c���(�+,rM�]��*>�Y�����$���5�� ӀL]���9��Ӱ`,ý�k�կ��*��5xj_?����N0��h�uL��X����������V=v�;��PY_[��>Ń������������	#v=^�����F�?����I�H��G����u�R���S<z��ǩc��_�n�R�������<�p��P����Ze>�?͓�s�u�ǯ�*���_[�X�b���?��<ɳ���ę�Z�?�t���ldw�gp��9ø���ο*��"���TvȥR5��-J~4Ġ��1�2~�1�]�Q��b�,(�ګ\��yp<���ѱ�d�׹&D��\�{�رw�;ޕrB����v�?�'9~�l��������<���gXǄ�:>�������'y�NO�����ؑ"-��~侃�����xj��J�R~R���kLP��7���-�3��M&g��`��?�*Q��,�ɹ�7ށ�uz��g�|���+~�O�u,��c�������66���O������?��'��S��9��f��4/���l�� ��V�>ƍ��g�C�l+I��-� �����~Įdc��z���ח�@��Q��؋��2;��V_���y�u�h����������������ƽȹ��u��m�5��
���Q�Z%J.OK��>���s�ß�p]�L꘤��Ë��]���6i�o��=�3�������m����#��G9�6g,�Q;��Q�)(�((��*!����t�]]Ø��M��$��fh1��y�L���E���7��(��f{���0�(���]����g�M�۩���*ڛ,���	�V�R#D�Ut� ��o�Р����L@JgK�W�w�E��7X�m+��u`ǽ=J�~��:��gx��.t��bfA�-��U.��i߽Q�a�a��M�,+�)�-E*hq�|^2������.B*�_��xo�%�Z����j�-�
Tq��Xഉ;hgxw�NBO�J9�X��!���`|���:bS,#��J�5)`2��(ašgkti��Gt��$�#�3�;����E��n���<��ygؾW�M��,B?��~���FY潐�2G�C��o$���}]\d�`�W�f�Aqd�(�^|]�a�n?�wO�^RBO��j}4;�sw/["�{g��8�Vw�90gxX���� /�k����?�u�J�����@��5w}0��V����s�]��[�gX������*�N���:?��$������և�!�����;"Ry4�_����^�p{�C���zs�}��ɛ�f��>y��8�����j�9��-�3���֋l�<Ɠz���4�!5���acsu>����K�����<6w?��N�5-�sc?�D���{\x33�D���f`�Y_��ߛ�s��'y�������s����[��F�� E|�O<�(���4EM�M����T�3�	?k���qA�@}����l�׳�7�����ֵ��L܇�z
]���#�TM=J:�h�C�aܡ�kr֖@�-C?U�P��/�r��]Ą��1��{u5���Y^���{�g�E;ꯥ�����Vpa���9)o6I�_kA��T=�2] a�S���ȇ+���n�ƂČs�{
�>� ���m�H.���I8Ď]���[I�݁�s�x��N˱��H� �Lԩ���;A�ܢi�̟�3����?���{,� � 