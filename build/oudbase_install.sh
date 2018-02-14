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
� �E�Z �}]sI���������s��Ź������f�]��4�����s����D��n\w�G��G��o�?���/p��/��̪�� $AJ3������ʪ������<��ғN�rykc�ѿ���ru��+�Ԫ�r���Ye�Jec���m<4b�ƞo�����A���	�E;�"����N�y��+z��c��W�7`�a�+ՍZ����^�l=a��%�����%$�3��g�Xa~	��vzu��;�c׺4z�ǚ/���g٦籖yi��д}�K��F�볕�N�t��tM��]��LV�z�}U٨����������\Y���;0��ܑ�7�f��:�&|l���㊏�<7lv`�݁�V��3��z�_t@���t�g�A�ܮ���}þ0{ϯy��?�[̀x�#���,ǎe�x�ñ;r<�Cz4�:]���w؅	��Mf��4�k2�Bfx�5��ͺN�Ğp|ӓ��a=~�\��g�ع�2Ӿ�\ǦA���;c��n�j�Dx�ðBm���#�^*]@���N����,Hܜ��B������J��u�Z�l2ƀ�0�c[�eإ�b7B�J�X�`�-������!�	�0�c3�)Z|��Y`�P�3�~4|@�>�3��l�Z�Gǧ��F��T/d�l��zEǽ��m��m�?ׂ92��1��=�y�>���7`43����a{����jgٌi	h�8�l�\�s~��	�`??������m��dC�M�������^��[A
��ϰ\9�9�;<m������odK�p���/vv���G-�MI/^�岙�q�����v��>jd�	ٓCÖ���~�V^s
����n�4gYn5��k��6[��v�� ����0!��~�}ttp�(gT���Hrp/�v��>����w����+ϸ0W��c���,o40�y�9׎�P!5�j9{����8`u^�Zt����.+X�[��;�@���g��b߂�k�����C��W��{����K���B?�ةr����0���R�_&O�))�ݤ�ݾ�}Oˏk�V��R
 ��a��{��[g]�Ѳ\����3lh��.���6������&x�_����:Ğ`���{����g����r�
>+�w���ngd3��a7��?�-���}���gs k���x��ˌޟ[����׺ĩ��	��(���2=�T�^_�g>R;w�_�"YyZ_�I"BJ ��M��{���`g&���}�~]N�n@�J� �23�m�L������-�,<�l��㝽�)���!,,=KX�WO�/<��N�~W�W����F)zt�^ԞR�V(}�z~��j�f�j�U�]�PLH����pdiAC
�ɲb@t2ȬR\��������d��(�>���
�2��ڼ�&�SJ���ֹ<]�q��X�/ _µ�hUܶe!Z��S[����ബJK��9��Ms�gϒ���~2��w�C��E�
E,ʺ)�������@8���%O��K� ;�������Vژ������8*doC3�6H1�������Cgl�$n�c�"{Eց�5�e�{�qQ�`0zE���UH�l�����7��W���@ҷ���匶����7������n;�nN�7;�����Z+�z<�'��K�Ұ(=j�T�A�vƃA�q��w|�.��of�=v�����G�(�T�զ����j���sh��S˯O-�v]�!D�GR�^|jkxq]wl�(��P�[W������PkӠ�Y�G�U\�V)zڊP4��@T5ض�Y�wО�)Zm�	B��(�)L	��6f�O�hGJⴎ4E�������H���H�<� �G��[6��M����_�#;�ߢ��ʰm�y �����Ѧ鯧��W�{۹�y�S�f������q:2��%��&
�|�EC��j ��J=�d�u�@�Gxf�z���|4\"4����4N�"�:(7V�uF�.2]t����9f�r�X��r�E:m[Y���s��L�;T�O+N:���'��V�E>�j�V�Pֵ����IQdg�,�r��&\z
�w����c ��c)�sb۞�*�ড়t�.OW� �"̿l��S�0�Q%��~s�Q�a��%��*:��-i&�_*j��޴K��s��8�υd9�=ú��[�~�5F,�5l��Žt&#����;N�;@/�=Q���;��&uzp����e/�o�l��#����X��#�b�Q����4�_Z�V��z�l?� oTA�k��
ӽ�G�a囕g{�*!#�B׼�֪��z��?��j,%��gG��ݝ��1*�cX��:U&C��ll��VՅ��B��ۇ<#��"]��b`QU��LQc6�fv�AI��s.�e9���f2��_V2����s����$T0AX�]g(X� ӏA����w,���%9L��7�ń+脙rL�S�	�'�f�	�+���D�/�,v�Y/d��7���ԗ  ���MK4�w�/��?iZ��G��!flK��lD��xF�,��m�ܵL��kxc;`@ÑO�]gd��ez�)��}6�����j�XbC!����~��L���ߞ��+ZvA#�8�H�g6z�������g,����+J�*B�X�������Jz8��O��! Q:p W�#����\���7^��.��77)���C�O���� LL�Z"�t�!m��c�%q��1�K�� �u�1Y��}`�e˱,����iu�%Q��%Z�q�����QqKpW2�n�!����'���V��n�yHu��T��V��>Zb��|��<X1�޳���;��:��]8�����f����Q{�F���il�L��������\���\_�|���,�<+��Ш�\��n�f����S�����Gڒ�;}�Y�p�f] ��3Fg���Q|�*�KR�חae�OӐZ��������mtH���YU������2�E��%��~]�3�:���N]�H_�;< �����W���U��-{�e,�v%�U��5)mX��w��������<�y,�B�'ej�|�g��{�J�]Ѝ��-��?��"h�S@��F5��oG���G�U�t�}��t������->�$��	�g�������~mmT�e��-W���������7�p?�_aj�")�g�%�����~U�����R��l�uzc}`����72���uh��0�S��������j	|k3�G���2�}D{�ka$�{���LE;�XaȾUF^�n�{{�ٍu�8�gCbSOJ��ұ���k�Ď<���F�Qmd��Fva#�6�م��`��o;�*7��ԅoa!;��V����s���V�����]dm�nL��K7 ���ma�w���q ����V؃���V�Mfz�a��I1�BFE�[�r���	U�^�d�t�J�������K����&�j���.%��Ɓ�q����(a�U�}�-8����[b]��ݬ����d���΃�_]�����F�������;<��G�l�K�ᕣOݱ�W`q���k��7ͣ}��%!D�:�:�$��)p^��qf Q�CL[���Mi�M��ƶ�-Rڅ��B����7<�р�]�"gc@۷��I�d�Ο ��\�RZ·MS7QA��M�����
/�
�{�$�%�.�?dp�9Dt�-�-3�//ؾ�o����sˎP"���^��[ ���WLߔ�,o�s.-˯ 8#�)�~�������)los�л���B@^p�I�&��@�5��'f���>�3t(��{Qt�p�+zd�W��Y�-7
�
]�޼�e����n?@�֘�ݮ��lŐD~�(��Ϻ�V ����kJ�澇��0�F-�'���Α����Jo1zh:�V���U�-�����؋xy��.
1H;+8�
2�'�{�8>禽:rԵ*9���o���������r>Ƒ�p���ި0�:��@����h���a3@�rYf�t�];ɖb J�a�<�u-�F �s��L��Os�`ܜ��p�^�>���)�!�9n��:���}���DY_l�v�oJbaЃ�\(�ϧFЍ|��bn&�$4�6K�{̇�@�i!�M��Ӗq-4�˿z:^��@��a!�:)҃��h�����4L1K�pJ3@>��0���h�?��4OHj�ڳ�P��C!S\�m:�}���� �+x�U98���,��i	'܂�y��$ѓ++��W�������>{�x�.���a�}�my}�U���i��b��+{�O��+f��(Mo֚�b6P�(Vӹ4r�I��;	f�I{c�,}h�y�||_X/���lp	ua*��FƔ� �H�SU!�g����c>v���H���g��ܨm���Jm�?�����H���d�L����'oП���f��b��u�����3~�SB�k{QȺ�����K��ⷁg?z�0(M���0(-+?YﲏjVz��!������⍒c�����둙�]�}�X�l<<�	�{c��i��7�Qx�M�BA��O~�?,�^����Oق�g�"���mi��I�a'*Z���o������݅M������]��]��R�܅M��&��%���d��0�]���(W�vq�܅1�pcڅ1�Oʘv�~2�@CZ�nՇ��C���� 5U�1�c��ӭ��j4�qa5���	[����F��Y�GŹ\����e_U���t���1@���xZ&��X�	��P�98lG��4�3�T�����7�����˫l>s��
?� �xS�}���|��?on����i���+=�J��J������hN��UL*��PX�V��8H�P	�/o�ãYX��8Y�U	�ޤ��0���n���Z"'��Y$�x0;{�x�(��Pt�m�%�Qf�jg�nͪp�o|z�a����lY<��ɓ7ab*���afh�,#�����}��\T5eIc'���zx۱ϭ�pg�XtP7R2������G%���,�?�m�����,��S�&���p�m��G�0�	5�Dn��д���.��gt�<�{�א���g
,էi�Rp<4���Y��~N�eaq,z+bq<��q�����I}���E-w6(�nL����^b�g����ͱ�`���%hIô�1g�C{=��-�	��)�-��O�Oh��h���,uI�N�I�f�����8�d&���ڄsg���yQ�H	H�Svd��9�z��޷H�����Lh�[<ԬR�d��ry�������zukc��+������q�_��_>��'O��.;��Kք�����?��g�f6����#��J�?���"Y��x��O��-��Ec4�Ł��h �{��Î���'O�����+��[�w��Ƴ"�_�ɋ6�gs���<�����������o��ʣڗ���BT����Q�جF��z�������?>������|��+��&.�0e����F4����C�)�o��`w9R�DС��������a��r���{�M�!�@/L��z��P��)+߽�w��fB{|�];c��k�Z�\.�B�w��k�E<h�m�0~d���!h^?8�;3C�(�æ�5��U@���uI[1db��?`���͊ȚOG��cT�u��a�` "��	$��T|��C
G&��Ԛ�Q�Rw7wwO�_u��v���)!�:t<����"k*�O(�8B$3�ı��×��`�^\�xہ��4.�K ���aJ�� )0��*�h:D�! ]�������	���!�$4�TE-8sL�O"S�)L��n���O��3����A��P��������*�{o$�;�Ʋ���MQ�@̬3��Jc�p(��o�6��%��V� (Yrrm�8uO�g��RT5>,<����L�g`���k�U���Mq�ַ���كܙk+���i��똾�j`At)**"��	�젻�� v=��K� ��N�_��|�̗F`V�O� .����(6&8i�����=�n�6Th��4�%Xޮ,��LĘ%`X���:�ܘ$�ѹICn_��_" �D�0����M(��
��t8���	
�B�3�\$�����;SpB��,�xX8r-�-i�r��$�ſ�J��O} Y%�4H�!N��]�򆅫����*B�p+����I��NJ�~��X�!4�� Gp�|�9n�"�"�'���sK�iC�+n�~��ƀ���~��l���ߣAWrcsRێ&(�\�-rXxs*y�0����^ 7���^��T2��e�Ɠi�hD����j�	�����?�&}dF%���r�D��pW�w���E���-?=?���d�C_t�dLZ�v[�8�K�1��ZPaC���|R���%��}��#����n�CD�`.ϼ-�}��=�D��>�D�s���G�ڻtU�.����(	ː������v�)�O:��­����s��=dJ��Q�pJ��q�r�����F㈇"-��HL�����9F�N��`�Uw�=4b�O�����&;l�����
m9���q�5��ˈق�nXa`Fl��E��|�n�"p�c��F��t���g�� �g�@�r��Qj�>8j�.7�$	)�/�<_d��P7$�+�p߀3^G6.зha��;�l%i$�9UVC�S$�D.-�/::�Q2�MI�g��qIi24���}�m��G�=�ٹbm,�23��v�JR̮���rb]AN��F�
��T;bI~{+�{��Z��5��h�p��Lus8��9��Y��6���E�<_3���S�V3]') 6�:iJ�b�V�ل���t���i��A`�5^W(Cl`�R��VA&A?C�q�͉_���H�T�}J$u/)��kU)�M��%�D��P_�ŉ�ݚ������vW:�7�}=�mu�4<_I�g�SD9V�-�(�'q[���&"�L���Q�Y��Xէ>��f��:S��6��@��E��̲P ��iAOT����̄�E@�Ý
��oC$ФUY�X�Q�^s�����.
��a��?����)�a�	�-��2R�dHoΈ\?�=�}�Ǉa<~��WR�[,��-��n���m�`���k��S/g$uS����7�?���2����VJ�.����J���?�:ٺy��T���^rb6�J�_�Z��復�/=t�5�
_�� -	E/rvX	�7Z���A]VA�S�S��� �9H'���ő��u�|���F�Đ����R��o��Q_Ʌ�����c�b0�%A`Jš�kB��D^u<�n�y���2�
t�����YO;��X�&]+H�Nz�X�#�.�(&����1��Ee��Q��lX�k��.�i�s�
[{[n��3��gH�Lr
���	��1q��f�B�M�cRRX�r;8���L�ZKx�@�uŚ���t�Ӓܨ;}[9�Cj5_8�52vF�un(�)��1�wV�C�rw��|t��NK�
v3�������
E��d�6�c?-T����U��o���&J|6��x&+��X�aP0�~��"�!�M$s��K�n4g%���E<��1�|!6���9\��ڨ��\\� ��!a����qyҍD(P�rS��3��Ԧ;+���]���z�K;�[�Y��Ҭ�!p���1l������&*{��݀��)�R�S�x|x<Tb�:Y��"��c�ؙ.r
|���Č�&?�)���w^6ҧX|�?�,ǡ$�h|;��ä	d�a��mH�'{u��ϱmxJk�?�J�e�A�v��B�����PӦ�LbEM]�R�ST��}G���Y�,�;\%lab�Tw<���[r$U�03G�v�.�k��%ɓp�ҏ�"�3��	]���d�����*D��# ^�CR�*%��	y*���N��	"�v0�fm3%/��G��~�����~<)��ˣ��	��TT+S	D�j�D���?�HQ
(%���D���{�1V��/��=[l��i>�a��_���Xh�b�̄s�h���[d�*�|͓gÊ~V�&b�˖"Kݓ�ȫ:�O=�ӺB�����9�[�j�f�F��CT��;Ig�z�9a��Y�q� D�x:�7	�0�l��ȋZ���9�KK>�Ӹ�lFneC������2���H�� ���>d� �}�.7a!��B��H���^H��v��JȎ�#��{,av����ox�2��H��5�_��d��@�ٕ��%�+,Z	���Ŗ�崦4��[�&��h%����FE�$6*��I*��"��(��r�>!������' ���'eޛ��k�Un ��4�w�!�X�'
Q��h�F����7/�l�A���A4:N$����%F�������T��_���{	� .N(5��d����S��~�1L��P>嗝�k��+ ��t��C��	0��aߎ�/tl���v�!YÐ�9�2�R�$@f
�7����l�w��w�XD�j��4��_���V;�Jq5�XY������*��pO���� <����}Z�P� &�+�TK�	P>�_�}�i�잤*<T��꾩Q)
l�F.�
h�ќH�蓙�É�.L<�NUmA~ݏ�a(���
ߤï���:{p�%uUǆ)���p� ݩJ��jZ���ɾ���Z-�M7xە��Љ�;B�BsBi���s#�7y�]۹�|G�KD��+<�mR��r!t�Ƥ��{1�64�n�M�F�b�� �g�n�K@�T̗��"L�����"8��킭�&ElT
+�>섬��_+��K���eu��1�2��;�\�LQ��(q�xc]��,��#��.���v���U��..�T�b���,�Wi�G)��뷌�����:��+0.A�����$�R��2��
�& ���4��qy0(k�z�����%�x�W��c6��$8p���[��}uD��@پ�-b|le|(V�T�H?��卞�DH���]�ytB��� ^�GH���%b�.��AB��/��B� �x)hE��+�?�M�jf���E=d��ń��z���m^i�f�g�����s|4ˁ��Cp�S3@��Vr��	(�ǔU��8��R�)$p�[��S
m��b�S�*FIv��^g��@��yy.�L]�"F��S� ԞA�	�Ҳ[�7@K��F6���&�gc����v��~v�v�}����a�k��ǫ��D^Үn�5
SI����PO L"�1D�~��s�$S͇ �q#�)��P]��k6@�PQ���w��˳`��]՜�g#~�蚗0|jCxqZ��os��(z`�@ ��#U+~a�1�Hgr����j�X�
Z'��$ʊ�^�PI�,I�B���npkg���b�}�̑{�}(zկ�\�7�����ִ�'|f��T[�Q�ɺz]|�W��V��O�KG�
���K.����05,_���n�JH��(��C .��B�@��D`MC*�=�a�[ ��Ƒ����Kj�&������	��J�ԋ�S�4�O��|�R��Z�;e��O��7-]7(]>��u.�s*�ljv9�!Z�g3���!�X(�	F��]��h(t�'����;Pa%�
NGW����O�Ox������P>vu0��̌푾&�3ʍX�z�Fb��I��N,^��3�H	A��f�<�������'a���uL�����+�j�R]�*W*~T�kO�ƃb%ҟ������:yE����b�'����N�'3�?���Y��lll.��1��Q�����@u@l����?|��Z������i����5�O�Y:�B�R�[oۗ��?�ښ���3ܞ���*���|��Dp:H�BA�{k�\Э2�y���(45�w<�������9@��}͉�p��u�4��ܟc󰒃�X�[;Z�8Cӷ���g�c��y�]�w�n��ȃyC<^� w��1i�&��-<���Ƈ��ѱň�"Bg���?s�7�8pȷ�m��zn�<�Z7�d7j�L������m�ez9�#�CǕ�ѫ�եsv+ts�{=T~���6]SiD1�Y�D����_�ە�0����WWE��q?�m�y������.�[��m����w�w�]��y{�̲a�c��'��	�`�kh��
���՘"G���).z^4ѝ;f�r-�7m,�~ٹ�WbF>*��=��^������ +ıE^�)߰���ܑ��LvhaV>n��2l�[��K�5�n���捁�`�T������qBak�����(2\�3x�c��#�_D����:h����jĳ<k���	=���*
�s�*�>��#�,��� �O��O��k��,�����<�z����>��^)^+�3��P�*���z��U}�+��~t�Q5P�G��cѕׂ����<G3ڌa�'���kI��-�/���g�[�J��;6�VPBS8>Ch�������i/����M�h
��N0�x��
�0D��f~��tp����Sw���i�"}�BS-�K�"��%����^�i>�P%���=$�:�:Oݦ�ő#ic!0�!+�W�4_�VE�W��ђ���	�U����6}c�X����ЯVJ$,���s�}�P i"�Iȅ�i�6��؋���m����<L%��i+z �b�
&���aj�	��M��<�'6��\�ď��- uF����]�����k��� ��"��P(�����#D����2�"�+�����c�	^1G�d���t/��*.i�lE�)�S���� ������q�5��n|w#<TI��D��a��DV�΂��EG��z�v����qq�_QP�܁s�O�����(ԕ"��	k�B�$�}�ms��z(Y6����(�D��T4`I�x��a&4W�l�,��$��%���cMM'�j������]|r�m��3��y�7�.AN�g5/�K�F��[dG�7svm��5�m��4,�%��R-A�x������$����#��*��s%�?�QވX{�#���3� �hZ�F����ǀ�<���h9��J�R�7a���ßZ /�}(��SsR��#�О���1�_/�5`�=3�`fX>9��'g��"_`0p��Rۍ~a��c����r5�N)I�w�p�5y���E҂٭ ��d�)�>�!�P�,&cé���<1�h�eX�y&���o�u�ĵ��6�q0*�����3�}3X�p�{|@H Jb�F{�e�8߂�^���W w�"�ˡ�b��3/|��`S!�]�P��*}�7$E���B����bN�)�@^+3la���Y~�^5�� N�Atέ�Y��@��=CqN:KK��D����n�o�&i�2��ׁG�U��AIu�W���o�ЮI�>�X*��@�8�Ƥ$7��`U�b*"F+�.��|���&������k�)�u��������5
����Xo�qa>��,q3h,{�������_���D%�\R/�� f��0�����%�'y>�1�:=u ģ�;�２{GCM����lM�`x8*W& ֍�FЍ8a���1"�e"��ܜ0<�L��I�X����Ș`3�>E�`�b����kH�(�B� 4a�r��^��@�.���	�9 �����8,B�p����"��@��,R����H���:�b2I�p揄ixט&j7�&2�z�Qp5��O�Y�����$�vh�ž��"u�'��S�դy(��^21���Ћx6<q��:Y�Bb(iATT�WǢ��O�j _�U���$i�e�K���v;93� ��V��V�J_l���<3-�Z�BK+8����촨)�촔n���[������F��Fy��#@���[0wp�p98�������YaK��a���˥��*�A��A�8��
�@������rH١I#ډ�]��[GO/��ѫ.�y��pKV�D�]���zr�1�Ԍ�L>�ճ	Yo��g��U���u{�Y�����V'(E)��s,����$Mc���>U���"{e<�X�V�b�^L���3���HND�N��I&���&�R�u뒘L��!EͣU��M�ku�x�˃��&
�buE�@ȉ3R��#�+�:�Y2�'��=�=F�T��IB�/N���îB��P��p tK��X��8mW��l��Z�Ph4b����5���SN�ɭ���T��J�^T ��+�j�z��J�X�S{42�ê�ܦVy��1�}w�T�BR�]=L_a��X���DLx�7��!����)�Y�S��,��4��! �W����\�7�����U�Z�+�Z�����+�5��̀��$Q�@�j��QH�h��� �n���J�b����)�[qKLJ��|DS�Ss�3j��r�c�8f)Z�@jKWDk?e\E��$Z��t��D
�ȷ��A�`������gnYb-���+��I�X	�}���z������
�(ixJ���M��d'	�(��]�1���bYfZ����h��"�|0�r��h���V3m^� 9���%u�m�������3��$Y;Y���Gn�����N`C>kEt5d�����:�]%g�{|�=l�y�>~������P�ФNPmG�]C�F\^b�@��F��_w�~�&�V9l���j��'�$@�ff:����$pQ}�t�ozI@��$`b�zN�U���H�,b^	/o8S��g��ϔ��"�1��ȵu����F/k=�::�&����c*�
U�ʻc��e�5�or52�')��n?j�,WQ��x�6?��Y�y�+��BE�a������K�6��+�Կ��
�T�5�[�k�#���2�FJ�B��� O�;�X�.D��ρ&n�PsF���y3��6La��}0z�I��f������	H�OY<�4.������ ��4���Sz���'|qr��؊�ka�xi9��Ɩ�d����M�V��):ؐ~*x|~��	�a#:�NB�����P����T�J�eB�S�NRfc��jkq�č�U��%���6Q�|�5/��-M�|yJu�cx-� �@�	|�>�9BD��z��ycX��I �
���/p��N5�}�?�@8���/�(C$8���Td.�%Бo_¿�e<��
˼7�w+}�y�R	-^P&��a��!��%�8�~�Jy�|=�Yeo��P���B(
 ��˓T%�5�Ž�������-ʗ�P�:n����.��e
�Q���d���e��kL�V��"��K�f�0��k9Ģ3|�-��]]]Xt܋���+��l��;� }��羁�y�<t3���nնʕ�*���\��|���O�_���|�~o��5���^�m-�>J�����'��ɞ�e�{)-�'�������l ���G�'�����#Y�,|���|�
�Y� ��D��K��h�/���������W;)1E�Y��)�k�\����Vu1�%-���J��0s�}ƌ	��vzu�{ ��U���5�|����:�vF$w��u�l����C��a^�}U�灤X�z�}U٨���������� ������@U�E���|j�}ؓ�O�<��5���
��h��\���/: eo(��Y~P:�lt�=���B��bB�����
۱,�Ϧy�׍K_Shi�J�.:CI3��Q�$U�;��a*P'픰F�뤰\��djE��B���{�O��s�TL0�y�1���«Y�ux�|],o���&4x�=A3���`0w�]�DUL��	�ε���n5^c���#.=�u*���oN����{q���-˜�^���.��./�gŶ<|=�|'�R�u��S�Ѝf��U���*���\+�霅(G02��Jt(!3�L��g��|#����N���\L�y�U���G��lMVN�[;G��G�7�<ڋ�<U �Oz� �08��zI��A�������B_���e0i��F�L��������e�Y k��� ,��o����8AR<��R�0ݞ���x΢�l�M��]c�S`���܍:;\`9�ԗ���~�׬���W4���@��\8��ୖgW<��\A6��Ԩ�� 5S0g���ɹ���[Ѻ�F$�l��v{4���Uˤt]���^�5����K���*���7�"���t�.zs��m��l 3��O�&'�Tl,�+��d�:�mc�	2$�9����w�W�����3r�t���46���<!�L$�� ڗ;Pl�<�J��+,nޮ8k)�]st; �ASŻ��L������s��gAW��$�#����e��P��V��>�K���!o�໰4�rx@��ϲ]�Z��X7+�K����ao<����G�ah����328��L}���E�9y�@�̫��0�/t������9�Ҙ܊���ܜ����U��Yǌ��Z�V��o��recc��}���m�������t�v.Rb
��5������Vl�ï������~^��:�~�j`�rh�68�
V�}�໣�SWϤ^�|�3�eD�hHod>6���ߦ��R�A+��I��/z�5f���^�
��oma�����b����+n>�|�WX$��]��*>���C�������o���&m�����Hټ�o��-�	��#����k��ju�mƯ�t�2K��K,�m���W_�+����:��W_�#�����o��ݜͷ�i����N����:�{�:ʷ��R�X__�>FB�]�]�ck1���B�}Wǌ��_m�\ۤ�/������ u�~�׶*���?F�ݵ>L���Fu�F㿱�����b�x�������b����w�u�'��*e�����os������b��i��~�3K쥈'�'�{�<��,].�������U1|)<!��Ad�"Uu<EQè�m�p��������w=G�Z����xA�^%�y�������IG�3'x���о����y��l9�o���z��?��?`�u�~��U`q��Q�*����g�������_u}c1���b���9����zuL��j���������V��8�{�4���QΎ}�a�Vn��c����8QC����
G+����0�J�X^��Dl��]������E�-#F1�f-�=�0�i�vY�Xf�b/wѹ�<�v��C ��g���B7�y�ϭa�`b���ϡ��n�_^i<B3P����A1lݜ0�N���)�w�iR�;=%�pJ(Uy����,|��7���k,K!�Ny�l^N�S�� P-ἴ��˲�L�"�!�v���$D��W�P���\G�[����ea���
w:�J�jX�bi�5��}�ia�+��K�����
,��Λ��l`2#Z���=Rb���O�wˑ��&�=�Uˎf�X${ػ��������x�O"x�0w��2%7��o׽������K�oVx{�AW+���a�$�)�^,�I��RT���eRA�}er��3�T�k�X?�? ׁ^:��K��R��ͱ�)�������B�{��0�~l����di�y"�#�����-�+�J�Q-�Ø"{U#�b���E`��E�S����K ��s���Cv����=x֏�\~��Y(~�DSR8�y�1M��[��77�?%-����?�-/`?8g�~�b�WP�7�+�|?�f�c��c�8�
����Y�7�ʁ�V�
t��,~�B����^���e
���;3��>{�����H͎W��~Y�<@��Y`�]�|p���kյ������杺sg�����?n~)�*L/�'�U���Y�O�����Ͻ���^�S�]=~P3�:��� �?׹��-��[���6a���-O ?�t���SP�3Pb��i��$����� �Hl�D&A����#�1�"��<:�S�0���4��{�0����ڼk�q��̴)��4�PEz��[�ahu�5BQE�	�1=��-���!�]�[���|�5{��؅��
��}�0r�����x���X��bfI�M�Ya�
�ֵ�޸��(N<h#^����"�y�|^2������.�U^��g]�˟���(>���c�P1���LNF�3�vF���$��#8��K����,���-���d���kR��'].C����'��q���~�O�9�y��]F�/��Ab��v�a�^�6�+�}_�q�0�L��G_��[���e��Gfó`��<ckp1+�'`ñ�ʼ��0ɂY܈�e8mѬ���gو�8ϴ?�]��ۗ-ٽ1�v�(-W90gtXg��� /�g����?��JԯB?	�z�܍�x�[�Ft��^�o�t�On��Fs�c����}��?�r���j��ߏ�޶�_���e�Lo�`%R��K�@���/����w�N{��������[��v���N�t�{�����E�����-�Ez���`�������6��m8�k��ms������,�Ҵq�>�1���D"C��M
���/�}Sd��{�A�ֹ����6����:���ڬ-�%-�?��'��*�GP���J�� Y`?��'�V�Lx����{�f�~GUP*�9򄟍6H����� ��qp��ouN�|ݤ��,͚�K��C�}��U�|ZY_/eu�O�!���y�t��U=�:���H���)%�Q������oQ�59iK ɚ���j(����G<E�.⋹�1���V��m�7��%-쵢hG���5�jN���S�@4'��f�	�k��럪EW�]��6�����5xp܋L�[g�ˌs�g
�< ���m�H&��XI8Įݠ��[K�݅�s�x���`۱}�M7�|h:�P�B�o�s��EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�EZ�E�c��7�)F � 