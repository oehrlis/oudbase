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
� �X�Z �}]sI���������s��Ź������f�]��4�����s����D��n\w�G��G��o�?���/p��/��̪�� $AJ3������ʪ������<��ғN�rykc�ѿ���ru��+�Ԫ�r���Ye�Jec���m<4b�ƞo�����A���	�E;�"����N�y��+z��c��W�7`�a�+ՍZ����^�l=a��%�����%$�3��g�Xa~	��vzu��;�c׺4z�ǚ/���g٦籖yi��д}�K��F�볕�N�t��tM��]��LV�z�}U٨����������\Y���;0��ܑ�7�f��:�&|l���㊏�<7lv`�݁�V��3��z�_t@���t�g�A�ܮ���}þ0{ϯy��?�[̀x�#���,ǎe�x�ñ;r<�Cz4�:]���w؅	��Mf��4�k2�Bfx�5��ͺN�Ğp|ӓ��a=~�\��g�ع�2Ӿ�\ǦA���;c��n�j�Dx�ðBm���#�^*]@���N����,Hܜ��B������J��u�Z�l2ƀ�0�c[�eإ�b7B�J�X�`�-������!�	�0�c3�)Z|��Y`�P�3�~4|@�>�3��l�Z�Gǧ��F��T/d�l��zEǽ��m��m�?ׂ92��1��=�y�>���7`43����a{����jgٌi	h�8�l�\�s~��	�`??������m��dC�M�������^��[A
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
,էi�Rp<4���Y��~N�eaq,z+bq<��q�����I}���E-w6(�nL����^b�g����ͱ�`���%hIô�1g�C{=��-�	��)�-��O�Oh��h���,uI�N�I�f�����8�d&���ڄsg���yQ�H	H�Svd��9�z��޷H�����Lh�[<ԬR�d��ry��������z���ʕ�f����~���O��ɓ=��:���5�'���_�<�ٿ�d����������H�%����'rx��fq`x> �^~�#`�k��ɓ��|C���
h�o�������<��E����ܱ{�'O�C���#�������[���(��e&-���1y�o�6�����^�Z���H�����G`��S����St�	�2�Qxs#Ntq�!n���@z���~"�Pa�� ��M�g��\B9{N���&�A���P=BG�	�����^ϻ��|3�=>qŮ�1P�5Q��f.��k�ᎇ;��յ�"��6]?2��j�4��㝙�a��aS�x^�*�ge�Ⱥ��21n���{N�fEdͧ#��1*�:���0k0�m�D~*���!�#�VIj����(��������ۯ:�{;�H񔊐�r:IQJO�5��'�Q!�O�X�����p0T/�a��@�_��%�K��0�]H���� �`4�����Q�XN�քbt슐E�v\���9��'�)Y
��&e�h�Ul�����QA۠xN�wbih�z��pM�7��@cY����릊�� fևKY�1O8���7]��_�J�S���	9��A��'�3�n)��
�r�Gp&�30��Y�5�*o��ަ8����I��A�̵���u�4�w�uL_v5� �B΄Fv���f�������Pw@'��/J^�W�K#0��'r Z��d���Ј�g�Fr�l7w*4Nv��,oW�	Kx&b�0�HLZKnL���$�!�/���/�t��S^C��&�|�G:�F�����y�֙h�L������)8��a�k<,�Ж�G9AY����s���>�����W�s�'��xy�����?�i!G�\Do���'�w�����Jv�#�v����N����li�%䴡��k	?|Rc@�ǆV���
�c`��Ѡ+����
�mGv.��� 9,�9��j���a�da/��[�^�g�@*~�2\�ɴE4��~�|�K�����Gߟr�>2��y�o�����d8���;zσ�"Z|Ζ�����y���/��M2��N�-L�Υ���-��!S�w>�MP���I�����BT���7�ю�!"y^0��g��͞E"s����G�O�˹EF��#B�]�*a��fwLh��eHP����v����'�T~�V�|pŹQ�2���ۨk8%��8I����saIp�~�q�C��WH$������#qF��Q�ꪻ��?�
f�'ƃkie��
�6��C��s��|���ze�����e�lAZ7�00#���"�i�n�N8�1�s���:�\�fK��3�D y9��(�o�Q�B���y�/�
��D���x�o���#�[�0Cѝ[��4Ҝ*�!�)K"���܍(��$�sг�ฤ4σ��>�6�أ����\�6�]���b;B%)f���h9�� 'GvF#tAa��$���=�E�d��j4`8Y�f��9����Ƭv��������@k��)z������ �Y�4��N1W��l��EB�����4[�� ���+�!6�b��R� �����8��į�N�R�L��>%���	�ϵ��&�sђ`"υS�/��D��nMsi�v{Z�+�͛ƈ�춁�h���$�3�)�+���L�ʓ�-��n�L�n���(ɀ,@���S��H3U^�)MV�x ���}fY(�y፴�'*I�O@fB�"����� �ѷ!hҪ�B�ܨ{�9^F�R]���0H�{�c�������d)�2�7g���ӾyT���0����+��-�����E7L��6W0R��}꩗3�������h�naɟ�Zr��T�j+%��{Mx%�����lݼst*{�y�91�`%��ۇ��RS���t��R��قg����9;���-�Hc⠂�?� ���)j|R ��
��C�����:P��ޏt�bb�[�r����S}��������J�1g1‒ 0��P�5��g��:�}��<d��I�R:O���󊬧��n,{��$f'=|���r�@��ڇ����pŢ2��(΋U6,�5��b�˴��9b���-7������3�T��i���tB�ArL$�!�{LJ
Rn'���i^�	O�]U(��XӖ�n��`Z��u�o+��tP���b��@���}�n�%<�z>����q`�Z����.�ډ�]�nN{��Rp�R����B��o��u����N|
��O &����Sd��� @rO�M�� &>���F�G��>���UmL�A.�_ w퐰�ȅ�޸<��"U�'�w�Ljӿ�\��,E�H���ϭ�,W\IV��BW���:���Zd��5�`n���B���R<><*�sN�,�wLⱌ�xTlL>}�n`Ɖ�Ŋ�Ɣ�{�;/�S,�����\��PG4��J�Ja�s����r��{���ޜ{�sl����Z���hYb�{=��=�(�*Ӵ)��X�PӖ�L���`}��%�y�&����W	[�X#��<{��IU�̑�����Z�I�$���#�h��H/nG�� X�c�
�*�HH�aH�/rB�J���p�d̻Y�L�K#�Q���_}���;�O�&���a��A)��Ƕ����>qO����S6�J���>qW?�^|��m<���b�[��g��xX����p5ڶ�62�\:.����ֺ�)O�䙰��u��X�Ų�H�R��$�N�S贮P`=��zNڶY�Q��U�Nҙ�^nN?{��s�B?��.��A�>K;[�,���g��ΒOD�,�-��[�l{�����C� $�u�)���"�Y(H_�K�MXH'����>R(~c���,����Hv�J�]{?�2��L�>�?~M���#��7�xv�}r	�
�VB�/,C��x9�)}��Ia1Z	���"�Q�"����o��%���-�!��O�*b�Ʋ��I�m&���Iف�&f��Zv���7́����A�?��B�hj���18����䐍5(�7��A�����<╠��Ĩ�^V��Bߕ��a�Q�}/a��	�F�x��z���b��ޔ��Q/:v���ʧ��]@M2V�䗈�7~�;�9���p�����?�!kr'�CV�h�e�@|i�
��FyW{��E$���N3��K��{hu�W��,��)�/������ۍ�Sa�,!�ܧ%`��I��� ���'�6��I��ağ*e���&�s�Q)�j�F�
h�ќH�蓙�É�.L<�NUmA~]��a(���
ߤï���:zp%uUǆ)���p� ݩJ��jZ���ɾ���Z-�M7xӕ��Љ�;B�BsBi���s#�7y�]۹�|G�KD��+<�mR��r!t�Ƥ��{1�64�n�M�F�b�� �g�n�K@��˗��"̄���� 8�譂��&E\T
+�>섬��_+�K���es��1�2��;�\�LQ��(qx�\��,��#��.���v���U��..�T�b��,�Wi�G)��뷌�׎��:��+0.A�����$�R��2��
�& ���4��qy0(k�z�����%�x�W��c6��$8p���[��=uD��@پ�-b|le|(� �T�H?��卜�DH���]�yt�A��� ^�GH���%b�.��ABx�/��rB� �x� hE���+�?�M�jf���E=d��ł��z���m^i�f�g����s|4�a��CpS3 ��Vr���+�ǔU��8��R�)$p�[��S
m��b�S�n����C����ݙ`�1��E�.�_� Sň���6U?�iPj�����V���l�������G��|�@کH�	L��H��>�
�V./N�R�*zI���K�)�ЗC=0UE��wK�y�XL�H�ɍ4 ���vCu�n����Cu���x��,urW5���و�^����!��-㷸�sX`0r�M�푪�i�A04��Ly�kd,p�ZveEi
�v������x"Zv�e;��3���N��>C�Ƚ?�>��uQ�����sxwZ�>��z�Ō���d]��.���X+w��z��x��V�%GIʝi������
wz%$}V�� �bp�I�tl"��!�ܳǍ�}�Hz��\�%uizS��K�o��kp�j���)]ϧ\�J�p)PM-�]3L�']q����a��҇�:�9��65��-����шp�ِI,�#��PD4���Q@x�M���H���^���'�*<|��Qqf(�@�XXf��H���F���At/1�%�m'5�G^��l�� `�y�z�q��B�s���I�J>h������J�Z�T׷ʕ
������X��'���k���ĨN�CQ��ǿ����I=�����������o��W66��(	���;�vq�{�:�?6�����\���\�-��?FZ�M-e���N���P��������O��6% 2��g�(�ҭ�h�gdr�.�ǺP��Z�5t�L~^h3
M���N�>���12�"k���E_s� ܩc:�� ME����<��`G3��քŏ�V?����!��Y���v^cW����&:�`�����ݣpL����pO�A�D��vAktl1⥁������@��\�5��c[ ��� ���֍-ٍZ?�io����`C�F�^�a���q�F��ou��
ݜ�.�^�[���G�TQ�dV%Ѭbq�����v�8L���#��U�-k�Ϻ�A[x�'*`gc�K�bc[$G������q���@��>�l��0`���5}B-i�Z�E2��crx5���Q*�{���Mt玙�\��M�_vn9�U����ʮe�?��{��?�7�
ql�W}D�7,�h*wdx�3Ӆ�Z�����������R�wM�ۧ���yc�9'��Ǿ���8:j�P�.�R|<�W����q��Q���ky���,��Zdop�@O$}��B��*���:�������?� ��� ��K�-=�|��+%�s�W�W�
�*(T*�J�^�~U�����cTT�8�Q��Xt�`$�b%��L�6c����)��Z"o��w���V�r}��M�Ǡ���T���0������sFzŻ�w+��E!�3�%o~�(��腙��2�i�@�{���:=s�H���TK��R���p�#�c�c�O<TɄ��%Eɹ��F��)mq��E�XLiȊ�.x-��U��U�o��*(rBrag�E��F�X<�=�0�����a��s#�@��mraoZG��,�-�"�"t�b��� S�?iڊH�X��ɣ�l�Zwk`S�&O�M�&�9��sAH�Q��(�Dצ�zd2;�e~0Hf�H:<���p��Q>G)�����
g��b��.D��B�Q:��}ÅG(�K.��K�*[�r
�'�t�s����8g��zu����U�$��QdsXf/��F�� ��r�Q��^��y�}Ew\�y�WT :w�\�S�9'�7
u%�H����P6�e_Ec�ܮ��F�M�$�&
(h&XR2�jp�	�U#�(�x5ɴ�cɾ���XSӉ6�Z�wrYl@q���{�6Fr�#��S�S�FM�횩��ّ�͜]!r�}��&Kr�)��FK�.�����e��>	41�CF��<���7�DI}Ïl�7"֞8��h*�*�2�,�Q~���|-�<�3ZP��R���MX~8���Ky��+�ԜT��.�g��u|���K{E`ό,��ON"���z���.��v�_DXj�x���kF�\�S
A��]4qM�ﴼ�a��`v+Hi1�bJa�O�D.�p� ����pj�� OE1��{c�������[x�?qm�*A��(0�|sČs��%�F������` ηగ�-����È�r(������cl5�T�pW)Ծ�J�I�a3Ƥ�33��Sh
<���[�tp}V�_J�W�l1���B݇s�|V�3�.v�P�����HQ�A����[�I��L��u�QdU*rP�E���)�hR�O.�
�7�#��1���"��XUD���ȁ�J�K7-(�����=a���o�}�)�u�}��p�6��Dm'V�[�\؇Ϩ7K���c�d��/Ѡ�W��m�:Q�!�ԋ� ����� �d83�wI�	E�dL�NO� ����;�����E��5�=[��ʕ	�uc�t#Nإ�z(īG�Hr��!A(7'O1��ģ�F�'�29k���2&XK�O�7��� 7�ZR>
ŵ�/M؅��T��/P���z��H#|��k-�P%p�����5E0+�� �$��0�����L!ܻjc�U惉�9���^c\M����t�/���-$9	�8��Z�C�/�F��H�	q�;5�CG
=v��T��5�"�A\d��@����J��U��(��Ӽ��`�;7ICZoY��D-$��N�L<����1�U��[gl&�L��ƣ��
N�}�/;-jD';-��D'&�V�m1��Q+��Q���P#r���+\��)��4?qV�R�|ح�$�r)-�JtЩdEG�2��'�3�)�=����Rvh҈v�g�x<�V��Ӌ���b���|��j\ĒU�+Q�D����C4���b�<5c2�Od�lB��e��jU/��rݞs�@y�Ǩ*��	JQ
A%�K�,�:I����%C}�Oժ>��^B�<��U;��S&��Lem2��C�E�S�~�0��nk��˨��ݺ$&S�cHQ�h'i��Z�1��`qA����X�C�,r����� w�H�ʡz���z�j��-U���e����S�ﰫ��D8�b4�R�6V�#Nەc-�魖,�X���y��%��=cr���!D�*�.��R� <�J�Z��1�R-����L�* ��UA:sLjߝ*��TfW��Wؤ-�nk��-4D�n�;z�Fn���*K�m9M�~@y��*�b#�鍻~�|xU���J�V,�@pv���G��j3��(IT*P�Z�q�<b%�;�[����R��X>���G��C����l�T��\�j�:��1�Y
��6�����OW�=�&-]�8�0�-+a�:�k��'���ن[�X��Az�$�J�8C�2V�5��i��'���>'��?�J����aS�>�I�*J�b�CWy����h����!�8=Zy��+L�8�"��:��L��ס�H�g�gI݁c�h�b#�Di�̹4I�N��9�o''8�ؐ�[EY��y=�`W	���x�c������U��~9Ԯ2�T��i���ח��O좑�?�W��_���e!�7�Z (�I/	P���.�g/	\T�3h�_�@c4	�Ť�y�=6R"��W�K�m����3�祈k���rm����QG�˚F��������m$��
�BU������zYn��\���I
.�ۏ��$�UTf ޱ͏ixl��柶Paؤ�7D�h��@��� ��3�路x)UbM�.ƚ|�H�"�����P`�7��#ǎ3��Q$�s��[pԜ(�s�L!ƿ�S�d;c_��y� ��@�d� �~���S�+�����qs8=���n"0�!��A�c�	_���/1�b�!^ZN*D��q�<4<`p��U୊6�_
�_�~Fc؈3����q�5��0eD�}.��Re��Բ���ر��Z�>q�~EU-s�a�M�� �@g�K�*lK,_�R�-�^�0C%Ph�z��<l������x��)a@�BG�g��.�S@�o�0.D�-�K.�	�*�%��f	t�ۗ���lO.�B��2�M��J��G^�TBD��	�yX"~bi	$α_�R^)_�dV���2�������1����U�g�cqo|6��1z{��%(���۵�x��!�i��c����64�@5G�D�2�����b�Ⱦw��R��sF����Z�(��}��vWWWE� ��$��J�;���N� @��l��o`}ބF:]ǌ�?�[��re�J�?77�?#����<�|�:&���ߛ���zy�V��_�Զ�?%�����?�d�貃����ݓ��?U��G����s6����#�K�w��ב,��[X>�x�,b�v�y�Gݥ�f4�����o�����ݫ����"��Rǔ���Q�D�m�������~�G|��d�9�>c��r;�:�= ��z��{>�@��z�j;#���:B�^y���L�0/�*���@R�~�ƾ�lT�ˁ��g���b�u@ ��t�������"Ou�p>5�>��ħ�o�����lv�y���wE.g����7�n�,?(��6�͍��_�h�]x1!~�Y��K��X��g�<��ƥ/�)���]������(a�*�`�������vJX#�uR���s2�"�J�VDؽ�'j�9� *� �ɼ�z�}g�լ�:<V�.����re�<��@z0�;
�
��*������S����|^7��1������:�����7'���U�����zǖe�n��н�_�Dg�J���b[�h^g��:Ktϩd�F3DC�*y��y��t`x��t�B�#�O%:��@&P��� �Fl
^S'Ɲ�j�%ռ��z��#�r�&+'ԭ��`x�#�q�Ŝ�* ڿ'�}
 qwg�$�ݠNgd���	�Y������2�����M&}�rV�����2�,��5�^~ ��7��gj��)u7�t��OE�^<gх�p���&��.�1�)��P�X�F�.�d��L����kV�Y�+�L�s ^Z.�N�\�V˅�+��B� ��OjTkk��)�3J����|B����h]F#~6�R�=��J̪eR�.`GA�]�ˁ_����o���|�J^�
�j����6�ۍm6��k�'r�d*6��C�Wa�t���6�������]`��+��J��Dv��U:X�C�U�A��Z&t�o �˃(�Q�L%~�7oW�����9� �)���Fx&A\ZNc�Ҋ�Q������D�R��ƲvpU(�S+F|��%qt���P�]X�@� <���gٮ������ߥy���񰊉7~^d�#�04�k�Vσ|����s�"᜼P Q��NKZ�:@Ih
r
P�DiLnE��On��O��@���w�cF�o�R�U�7�Y�?.�?���p��-����_�����EJL����f���_�ڊ���������ϫ�Ug��S�ZM�GU����B|w~����ԋ�O}�Q����������#~XJ1hE�5��C�E��L���+[����������*���1����� �EV\a�pW�vᇪ�@�&a��˚��]o���o7��#e�.�m·P'�_��s���n���i������,�v.����Wj_}]�l�6���_}� 󧾛�}Jvs6�:���r,������b�?FB�u]G���_*�����H�����ol-��1R����q�A��m�k��������"^B������V����H��և�c��ߨn�h�76��QR���q���^Y����R<�ε����_���?5��mnTq�A�__��#-1�/yf������v��7����?r�q�A�ݿ*�/�'�W7��A����(jb< �1�2�����]K10�/H۫9��۟t=x�3�h`�Б�ٷ�};�ѓ!����\�OO������̷�ۯ��
,��>JR�?�������o�Q���o,��1Rl��?�t�R]ϣ�)�_��^��П2���*W����uX5�ٱ�]#���{{�ã�x��'j����Z�h��8�X���Û����K^���B��Ȼe�(&ѬE�G�:��.���W���.:W�g��9=r$p�L�]X��7���5Ly ;�9��m���+�Gh��r|�:(������s<E�N4M�p'��dN���"o���W��o���^{y�e)��)/��K ���z* �  ��%����zY��)X�3d�N7_��h��J*�w���t��ټ,�yY~R�NgW)_�S,����:�#,xe��tiu��0ヲY�e��yspԂLf�"B˜��GJLu����n9��D���c�q ��Y�d{7�#��ܢ;����I���|]�������7�9��b	��
oo� �j��2,��8�}��1�R�J�Z�L*�=��L����
{����:�Kǟ{���Sj��9�1E��U0���Z���Fߏm�����ޕ"-0�A$�a�X[�C?��u�X)?��ubSd�jS�:9�l:=��w�?�z	d2ran��Тp��{z��ؠ��~���37��hJ
�:�:���c�������磤���X�g������Z��

�we����|��y�B��c�9+��[9p��*�W��aݒŏXHvV�ًW���@�"~�{gF��gϞ��?���*^��/+�辞�!,��n��uby��V[[_�XۼSw��o������/�W�����d�J=�:k�	���6����ϕt�ϫ�wJ���j�R�4�o���:���E������&,^߻�	�g�ΰv�c
�tJ��1�"��d�5]\��M��$��V�b��! �QD2��B's�&���FQ��a`O�W��^�w8����6Ž��F�Ho��v+?�.�F��!��1�#�RԠ��<;�K��b+t��/�f��p�A �pX�ѶO�Fn�ӵ3��qs ˒_�,i��6+�[a�Ժ������m��r����R��6�]��K&T�<:�E�����L��u����ŧU�A{L*F����Ɉs�������� �s�G�si z�0���q�%��,��pM��B���E�q�ٚ=2��09�ڏ1��?G�3o���(�x H�@^�μ1l�kئ��0N��ib���K�y+������lxLp3�gl.fe^�l8�B�7P&Y0�Q��-�� ߽�,1���K4w��%"�7��.��*�� ��9#�e��w0�Gc�T��U�'�B�Q�➻1|��Ո���k�m�.���-��h�uL���Op��Z.��_mq��Q����˝���̑���D�x��/��e{�}���.�io�:�9����a�y��i��}���v^��H��x�E�H���,�޺�c��?�����mn���1�e_�6�ߧ0汵��Ad���pz�I��E�o���q�4�:7�T���V���X���[����ϣ���G��$��B�*�0^t\��#�GP�$���j��	�!�@3�t=�L��
J�=G������V�X 4�����o���t����Y�qi�~软�*�O+�륬�����#D�A�=ϔ�=����C���<� IU�3��3�<2��-��&'m	$Y3�SUE��p���H�E|1�:���j������������V��6~��[-�	��z���$��8��9}�S�����{�t��t��{��u�,x�q��L�;���°��$^�+	�ص�vzkI��������l;�����M�T��� nִH��H��H��H��H��H��H��H��H��H��H��HwL��a�1 � 