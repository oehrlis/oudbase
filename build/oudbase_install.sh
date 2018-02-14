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
� ��Z �}]sI���������s��Ź�,	.�IRaڅH�]~AI;+jyM�I���u7Hq(n��~�_���/������ߋ�3����� I����I���������S�.?y�T�T676����[���Ebյ�z�R][Zc�jucc�	�xh�0�=�p�1'�lgg��v��H�)��3�@���W��P�����o@�C�Wkkk��������Vy \b�g���(#�^?����K mq�Wg�s{�ZF��X��*{1�,��<�2/́3���~�:���q}����)@��a���iy�kx��j�VٗՍ{50|������Υ�o�����=ch�x�3m������;�����3�f�f�Xl�1���]ɡw��J]g��=�J/����7�s��⊓�e�a�j�����g9v,�����ݑ�������g���M��o2ˆ��]��2�c��m�uz&R��MObsԇ~�8�54,{p�ƞ�cg��L��r�::��}v��U����}�
�!��z�|9ǧH�2���"Xܜ{�y�7�U�{U��J�TyV�U�Oc Q۶-�2��t����Z+U��gS�i��)�4f4�fvl�!�@CK08�l*u������z��H�m�u��p�褵�X�V���<���C����B�m�����#G�Z0F���1cӻG�roڇ�����f���<8h������<�1- ����svf�c42A� ���v#���ӹ<��S�l����u�}pt���m7���m�3l�R������[G���6�e8��˗�;P�ⵖ᦬/-.�s������7�f�}����'��m�Z���-����n
4f��J>����i�Z��N�<��5`@���\��p��Qɩq����^��.2�}������;x�מqn.�uT��,o40�x�9׎�p!15�j9��9�o��gu^�j����.+Z�k��{�{[���b_��k������헎�{	����O���b?�٩r����0���R�_$O))�ݤ�ݾ��@ӏk�V��R
 ��a��{��[g]�Ѳ\����5lh��.�t/��W$KRJǺ��I�O�I�v�sO0�_��B�p��Yg���ް��*��W8��9�̭�i�M��c����k7���\+�E$^r�
��gV�&7��.qh�r��2ʷ���G5ԉ�˅�5�s{���L��/�+7ILH	t]��@�u�`0���Ԅz��]��@rujW2`FP���lt����� |WLnA�����m�O��v`b�Z����������/���[���/|��R��0��=�0�.P����k�����+������d!�3���ӄ�|�g&Ԁ�`�Y��0)/���;�?�	� Q�}�M�e<%�q5L�������3?x���'���_ ��k�Ѫ�m�B�"/��.����iY���[�sl3.���mϟ'��F�d$g'�C��@D�*E,*�)�@������@9�6�%(O�zB$WQ�+�`�E�
3mL{V�UU�����l�]boaI|Ό�3�I7��1.�����Ӵ��븨w0轒ZEm�*$`��S{aV�S�Z	��b��ێO���tFKȣ�U��ask�h7'/����Sk�bT�g�X{i\� �G�=��4�[�x�#�3����ۥ��`��cǋ���{�KI����v���|q~3{j����ۮBtz�E�ŧ����uǶ����	u��аup�;��y���um�]��H��k�*G��[�F�	D5P3p�m�\$~���Ֆ �����"��ИmcFz�@;Th��:��
���G*��đ2>ˑ�ex*C~�*��l�9�,�g�
���o�Hviض�<����`�h���S��k���\ڼ�)�^3KC�ML��8�C��jj>惢�r�5����yQ�ǃ�:y��#<s�<��r>n����� �@r�r��Ņ�{������U]m�?�lQI�|))W\�Ӗ��j��<���C��4㤣�>}�/�`�^䳊�Vk��a];HN�!;Wb��g(m©�Hv���[��:���;B�b='��9�ˡA~�A���t/�����<*�Wr��0�	���_b7]��b#К�����RU+T֦]R�H����?���v�^6n��}���ְ�J�ҹ��@u�v
�� t�E�n&�A��ɜl��]���������^~�:8�pB�� )<2\`�N|�!J���Uoտ���.j{��+��FUd�/�e��݋BDV�Y�{�22�����6W�0�����N�PMc)y�;l�lo5�Јê]й2ʯecklqE�(h-H�}(3b2.B����ڨ:��J���9�k�b��K�<[�A)���`$è�e5����}��PW��
f�$����lz�OZi��`1`j��0��ΠF�AO�x'���I�'�$.M ��r_.`Y$�Y/���7���ԗ `���mK4䆓�b���4���;Ĝ%flK��lD��2xN�,��m�̵L�+xc;E@ÑO�\gd��ez�)��4
����k�M,����wAlS?יj&�fq�o���U-��Cl�,��@2=�S����q����[��\,�K*B����^���m��Iz8��w��! Q�w`WX#��G������W^��.��W7)�A��'���UW &�X-~:���6���ł�\���j��:j�,�ú�鲥X��h���R�(}����K�a���%:�+�@7\��ł�@�_��p)c�Bj��<��:�D�S���p�זX/4���d����l�E�����a��?��ǰBzI?�_m���?lo��Ш~�4�܃��?�����}PF��X�W�_/a-K��������_�y3�}A��|�np[���$�N�qV \�Q���Ȃ�٨�t��]�*QI���4�L�iR��?�������z�� �KEP8\.ÈQ�^B����m<��S-���y��e����7[��{�ԓ:���e�0���ľJ�ô&�uk�����^�'>ѻ\�6��P� ����W�qoXY������~�'��=4pH^ߨ%2���6y�z���.�Oߚ֣�X??�ǧ���/w��,��k����_��J��+����1R�������S��N�L�r{F�������%���\�kт��No�����Ff�:�
�����%����O�x����v~Tޟ��#��&x#+�Å7�*�yΊC�����jv��������y$2��S⥔�5/(�kX&V���3�G��e��l�#�2��G6�"��a'x�4O��2�)�3_�[���ɏ�sxf~}?1�>���{Ә�ŗ� �� P[��w���s ��_�Vك���V�Mnz���Iq�BF���,�<���n���j������7������{��M�BH[J`��}�4�.)1�(�@�hKH0-��=������YC��G;��P�љ>���G��xE	�';�ܼ�Gl�KᑣOݱ�War��s� �������"OD!�'�=�K�=N`J��b�i�yԼ)�౉���ޢaCµ��EJ;�A�bK�i�}Ý�Nڼ��	�}+�������1bQZY,W�K��i�"*�x�EZ���tVdi^���3'��(Anp�8�����!Z��liu��!�]~�6/I�[v����~g�������n>c��ddyR's1hy~�1]���8,���X<8m�N�`{�(�%�b��<)�������L9����'z�2���%7G��G�%X@��@�r�@^��U�-��Pa	���C��h�y��횪�V
YT�W�ڝ��kyaRߋ�^0��s�xɊ#���{rJjm�v	��c��S�e��_��1(ZnM���'������ì(s���p ����siګ�D]�!��ν��]�t`����/bI G�^�
������ t�.�l���Y�6��e������|9��t�(�SA���aJ;W�1����d�Zv��I��W�U����Ѯ�"B��[a�#vA�Z[���M��łh{��!=��b��|j�H���<�fr�NB}�T�c>DE ��l
5OZƕ��/����� Ҭ�\#R������1����4L1O�pJ7@ޭ�0n�\ �%�i��8��gea��B�8����cur�@��� �#+zdU�?���,��i'\��e� ����2��U��ˇD�yz��No�ŕ�,��@��-�o������5k�=f��si���)�i��;�����Z�W���kz1�]t��L�Y�M���$O�s�0��+u��\B]�
E캑>%�B�D<1U�|�?0��N���x<�,��kk��gum�?k����c����3���������|Z����>+U6�<��w�KH����Bו�]�>#[2<��"���̡4ڏá�R��h��>�[�ѷآ�;;37�7J��.���Ff�w��Ac�6p����4�i~����4G9�5#tl�E�{<����{90�3���ϾFV�����2�T�V���:l����;�O���哛ŭ�|r���'7���|r�?$�ܙ\r3���)�nN�B��;�fδ�eδ�3�ʙv�q2���~ݪ��p��a	@f�Dg��p��gX��k4�1�ͼF�^�b{nF�Q�_��p.�~s|�W|��b_��l�*�<*3��I�7��E�5<�c����4��&S|n����m����}���:_�����3��q�P��/�[�{}p�i��JO�R(ĴR�\JPAt'��*&QH(�wQ+�f�$j����a�7Ӂ��,̊c�\�
�*�YoR�=���ǩ;o�`=���<����=<|�W���ʂ��)3Ƶ3�{�*R+���ƆGHQQ�/��Gv<��&\L�0��5�m��g�u\�B�O3�����,���rCo9��uv�u#%C��[X�����,4*�~�f�?��/���^��i���4$_n�{�h[��<�w�Pӎ5�
M+]9x�p��㸇v�(�~��Rc�/��C7�軑�K�s��Ǳ�V��xvo�tO����N�39�Z��P<ݙ8f�Og��&��/Q��c���r���)]tӒǜA�u���4�'x�����?�<���*@C�>f�K�u�Nw#w���&����;3���s�&�9c�����R\AJ@����#������@/s��E�ܮ�?Ȅο����� uL���T�+O��{�Z��?���Ju�im3��~���O��ɓ]���;��R4�'j���<�ٿ�d���������H�#����'zx��fi`x>: �Z~�#`�[��ɓ��|C���h�o�������<��E����ܶ{��'O�S�?�s������=�[}F�a&�F��c��߀�^����Z%��������G���c>���St�	��£��F�:���C���O��`u9R�DЦ��������n��r����M<!�@�M��z��0��)�+߽�7��|2�� 9qɮ�1p�q��n.�k�㎇+��յ�t��6]�?r��j�4��㝚�c��aQ_�*�ge�Ⱥ��
1����kN�f%�'#��>*�:��b3k07��$��D|��C��Lz%�5�Q�s2w7wvN�^w��w��@�)� �:p<ҢJ�7�J�(�ɍ�'�������hs04/�b<�@�_W*e����0�_H���� �`4���n�U�Xv�V�at�+�$4m�TE-�sL�O"S�)L��n�X�O��3����Aq
N��<�z��yi��
���[	�N��,��m�MSET��03�È��ҙ'�Jc����s��G��)Jܬ	9��A�'�3�n9j�
�rHFp!�3p��Q�-ڪl��ڦ4�	���A��A�̵���M 4�w�uL_�D����dB'; ���]�e��RN��٧�y� �+��U��=�nr��	�F�����E#�w���;g;͇z��K˄)<qf	V�NZK�L��h(��f@pA �#R�����Z����r�h+��1����
a~�ݽ�k3H�cT��/�}�\^��0P�UJ�t1�$��/oX�x~�;�^"�����-������W��BS��l2���,�����2�1���A��ly�e��)h��;�SFIQ�I���!�yеq�Y��|�F^dN��9"Pnm�����=!O9`�Srk��<�7X���/Ύ�����%��V��.?g҅�te�@,PT �eW�	
�=���-Φ�y�4��i�Zo�y�H��\�=�}��=��T=::�c 	�s��σڻtt�����(O�����ív���Oڹ��{e���(�����t��8� ������k�}\�4��A��3��|��"��E�5��˻�E'ް���x��Q����:A��1�ύ�m\��r
X��9$�s�������F�O.EhV�.�N��*&J��oHCT�Ɗ<	�#*3�1�ۄJ#���i5�]UK�V��Dy(5gԃ�LR��P6��'C�y�NS�M��q�3��U�27��p�KR~���rb]AN����
��I8��|{��{�$�Zɷ2Ч5`8X�Mfs8��1�����E#������Us��<�SV��s����Q:�H�N1W�|��,!��]�t��t��}ݦ�K'�l�
�`���@;.�9�+��V�e��Α�u��0�*(R$p|֪RX��EK��<L����ݚ������vW>�7�=���:i���$�����J���$iK��i"��ܭ�_5��ۀU���P�*��>��jc{���0��hMt�	�B��&5?�	͋��:��
��+�hҬ�B�ި��9����	N��K����:�9G�z"\��,��c�қ3b�ԏ-DY�eTL�C7�Ɠp˩��K���|�]by���jy<�=�X@R1��HP-�GK_q�>��~z���Rf[�	F�8_��+aX�Pd�d����I9烢�ļQ������(�K)�0zL$�H
���E� /	#Jv�	�7��Ǆ��ު �~�	�VR �d}	�������:P>�ޏu�jb([qϞ��<�S}��//��/�J�>g1bk� 0����4����:�}��<`(I�R��N����'��N,{���SH�X�Cŋ]��������
��(.�U1,�5��b�˴-�9b����4�t�LL2*���a�tB�A^L�!�L�'�vRR�r*5�t�L�Ix��|�@�YŚ6��t��ӂ\�;}[�j��Q5_8
���Ά�k�&0�+W"�b ���B�� �t�bc ��/�Պ?ſ����wl���*��	��&'�� �6���7I�$/����9&>�A�E��0;�-
��n�T�9[�K? ��!=��v⪘�PSU��U���M�zVpigr�i>�����ܳ\qU-<�m�Uð���8�O��R>�x8�hE�>T�a��L="�$nX�C��&��N�Wŉ.������	|�s~�ϕ��P�C�ۯ�C3��.�\�ȡ$�h|���!�Sga����R�4rR��9��wsl����j����ђ� �{^�{v^D�i��;b2D�X���ST��}C'>�Y��͵;\%�b�T��-e�������r�.���jA
+��#�½E/�HE�niSW�c{�
�*
N��_���I�/rB��ڗϒ�pN	�'��t�iJ^��k��~�L�{w�|?a�؃Q;�#�R*�B�-�#y�%z��\�]��,Е�Ez�
}�T|�io<�cf'b���g������p����e1a�9�k�.�Ăպ�B߮�"�\��ˑ����q�U����i]��z�[j[fUg��=j�����`��1|�<���ob��	蛃ۓ�@Y�q5J̜�b���D�	Z>'׾!��ޛ���`A;$�н1��p���h�����>b�B��H��_9/$��?;y!%d�����i�0��~e�~��L�>�?���������s&<��>��rPA+!����R��֔��h�֤����~B٨h��FE6I�PDQ��X�'d7{Ʋ��I@L&���I�A�&f��ZvU�KR���;Ƀn��.��L��:��b`����|ݐ�5(rg6���6^�܎����$��^V=�@ߕ��a��QH�W��suA��㵞;}���	7����?">u��	?�B���J��Q���B�^i)vt2�M����7\�������*vw�)P�@[�B��Q��޿gͪ���"�R~Ź=d���J������>���a�b#���s*�����i�C) ��b��V^J�r-~�����:�V��$�f��F�X��-�<Z��	t"(�O��޻0Lp�8զ��.ʆ.mV��~�@��C����4R.`��������б�[�ZA<� j��\R�C�؀�m�^�x�N�����X����}ĭ�v����U64���.�E��J]�NGt�����P�
�s�H@n��}��t�RX��y���V6�H@�[��1�4��\�C^��/�(gx�V����=[�$����P�ܪ�DlMf*`��-��֫������׿��3ƀǬ��v �2�K@>��O�!�(#6'�Yh� 2� A`,X0b}�>��A���25q�󣘶c�,���^nO��dΓx`�!
�ou?��#�Ҿea�U�T����x���Rm�p:���)��DHhZ�]�y�@^�� ^ϵ�^�%�XtJ�x�k��]�/�3����)\�����0x���h~M��]~��}�
�+j���*�|_D�<�β'������\���Jn��l����O)P����Bk�Br_bJ��H1ns�RhC��'���u	[�_X	E�N"{֚�L� �fA�	�f�GWA8@L\�)��|d�.y8# /��nyO��+2L9�5���D#�v�&�"�m�9��t����'�����H�y�{��Htv�4 fS�~"u�O�����õ�M=��Z��I�Ls�����Ƒk^X ����!4��;��q�ūL�����T��wL�
j��?:z��aAHW��8(�<�"�$8\����]����F�|��g��9����q�d�YET)�x�<���%O-���} >*��+�QY��?�Zy�-5,]&�\�P�~�|�pxT28�(!�\Jχ�5\J����=�����T4{p��w�đ����K�'&PSjJ,��kpkU���)$��Sι$�7����g�'��n�KDK7����]n�	����l��]vl��v���шȏِI,�#��.��@<�ْjK�x�A���H'��^���'�:x���Q�P>v~*��̌��1Í~��Sб��#dķ��u<�yl�;5";M���y�g���p����ۃ�1-�3�K���*���f�Ze𣶾��m<(V"���vM�}x���P\p��_[���qR��>��2s�S���M�����z���������n�4�=P@����i�_�E�������~��@�k��1��MKj�B�V�[n���_���@s�n��^�[�� 7�h3=�Y�]�&ȣ5��V��m�rj:��vcp{]cdz%�`���v�]�S�:t�:\ᏱyX����F�
_�9���[C�߳�1��.�;�	�M���!nMQ���Gױh�.��+")���c��.h��-�xg "��60?�SO�C��"��h�g&(Į���%ɨљv:���Uv��Z�L���a{�r=|ٷ�}D�
��bMf�h�U��{�TQ��V$Ӭ`q� o$\q�C즕� ��ʊ �*���E���������N�X_�(�qh?�|w�E	��Sˆ��	&�O��j�H���.��%në1��"��Jy��pΘ�ҵ|ߴ� �e�>Aܼ�y��X��#{��/�� V�c��j#R�a��ܡ�NMv`aV�o��2l�[����5�n��������=��=�����Q�	���Z�ǣHw����5���r�뮅���+���ح%�P"�+UB��6@>�# ������G���5��*�w���<�=F����>��^9^+�s��X��k'��z���Ɨt,����5�9���Ƣ�o� ����f����X��^^MB�]���>e_+���߳��������9B�О���|�k}�~bES�(�d���^� �C�xn���Hg�<���:0t�NϜ-BS��Cx)��.Nq$t�|L�_U0��iI1�r�cxa@�p?mJ[�s��0S�,�Q�iU�x�*�
���\EĤ�W�h�P���F)7�b���s�c�rH�w�R؛F���Ÿ/W$T��-�^�>������@J�rL�%`�ԺD�R7vNl2�4�Ήw�s�@�.ߍ
N0	�G.���Y�G�t�I�_����/�>B܀�Q��/�`)A���ʊ��b�+��(D�l!m���{ɥWpJ[a�RO��>� dN��DK�s�ݾ�E����}�W$)>�A�������P\`�h/>����<߾�;Nμ�k*�
�8���)
��]� ��"�F�*�䲯�w[ܮ�~��,�B�$�&
(7PL*��d<��!&4W��"@Y�W��K�.ɗ��kj:Ӧp�N�+@(᱓�o�x���H�s�a(
m;S�	x�O/5#��";ʾ��k=D�oSդnI.1����E��-�>����/M�0��ԝpD�_������;G�qז���i&��r�,��|�_�}H�Z��g�X��tJ9�0�p��O�"�}8��SsR��#�מ�s���^�^�k�(
 )3�`dX>�C��'G��"_�3p��Tۍ~���!v�X]3��r��Ѝ	�E����Nӛ~-�v��2rZL��RX����K%���d26�:%2r����� ȬC�?�$Z�{-<��87r�� ފ&0�|sČ3��%F������` Ηఖ�-���#~���PC1����G��J���ݤp���}�7���_x���N���#@\Vd�µ�۳r���j�K����B��*�uw����9�,,`�EDZ7�n��M���r/��X+Ґ��,ڀ/�_L�k��}r�Th��q��H�����*2ݩ�=Իt���?�x��'�oP_�M��3�n`}H��R��Д���Jx��+���f��A@c�c]w�,V��������&*1�z��7h�~�l�3�wA�	E�tL�NO] �O��W^����E��U�<[> �ʥ	�uc���B�=tţG�HJ��&A�7'tO)���o���O�erтy�dLp�`��o0c)Ao�ĭd|�k�_��
s��d/�_�e�߷艈)������8,B�p���΢�����,Q�D��H�� �:�b0I�p��ix
�w&Z7� ��!�z�?����`-��R�fiN!�h�'(�bh�l��p��.'m�(C�b�x@���O�B�o����Jl���2@１.L%}�s-�>�4��)X���MҐ�[־0�
Is��S7.m���/�����3ӄ ���[(i����їD���I���I1�Z�����z��Fy��#@���[0vp�p=8��Џ���EaKY�!YqJ��ZZ(����mA���=	"�$O��:����!e�&�h%zz��SlYl=���Nu�/Tm��D�J#*��@v�x�^ߓSL��fL򉢞M�z�L<#T��EW�b��-P�1j�Jlu�Q�.��J�,�:�����eC}�Oժ=��^J�㕫*UB��bƤ4�TW'#9=TX�8��')��9�jy�X�kbB1�:�tK��m�YR�;�m_~9VPi�"(f�P%���6! 5�m?B\��e�< q�@���YR%w|\'	���h��B��P��p t���X���mW��l��Z�Ph4b����U���Sv�ɭ�'��T��J�_T ��+�j�z��J��d�R42�ê�ݦVyh�1�}w�T�BR���2>�&-�vZ�/��pol�#B������X�fAOͮ�t\�� � �^��+6r�޸�φ��Z�V���J�.�^�|�14m�5�j
�Jk��XG����,��P-}Y��T��#e~��n����l��L��\�j�:a�1�Y��������O�Wq�s/L���v"]�Ǘ��Ak����@㉣�,������I���q�$u���F��d	=��[}�}~�5<���/��i���T�,����GW��+3mE�ԞL �!qZ��W�\Qmw��j�E��P�4�Sӳ����Mtr�Qp�6�\��k'�����ͷӁ	l(Z���B�8H��Ml:��R�P���X����`H�HJ�ˁv�J�ڊN;���<EEG�b�D�	Q�D�ZM<�n�a�!�@�iI�B��tp�jI����@#q֒��I�D/&QN�U��XO�,b\��_8R��g�㏔����1��ȭu���j���H�����F���'L%��u_h��޼����HO2p�~��C�\Ec�[���g��ۮh�i1�MV{C�߫��xX���_{����V /�J�I]��D�oI$����z�{�=r�`1��EJ?��@�����!�`��l0�O�3���&0~��ʆ
�& �!�e1p��87��Z87�Ã��&�?N��#XODi���7܅Ag��B�oxǏ'�n�diDj��q.��ǗWj�6�`������b����Ϥ�U�,����$c6V7[��'�ܯ��e.ѭܶ���جy�Єmi�E�Q����kah
]��+��"Z�d\^P׳m��4%\�Uh��t|��W
h��#�"���)�"�E�<�"s�(B�{��O�p�*d�,��t�/�}���eD�tN����2�CPKˠq��"��ʅz.��޵?���9�P ��w�'=��<k�{�ӡŃg��[�/C�n����.^�J�n��W=6�ɡ:�9�)ʔ�W�t��*%��3�rŜS�<6�CGW��Ef��kD����,���eQ�W���j�u�E �t��}��&t�y�:f<�Y�\۬T7kt�������c$������P�����)��Zum��Vy
���e�?%�����?�d�������ݓ��?5��'����{6�ͣ�C�K�O��ב,��[�>Jx�,�5�h��h��h���o�����ݫ�YJL��c��߬mlF���f6�'-�����1s�uƌ	�-n��l� G՛�Vً�:?,�[P����K����V� e:�y��U�54�ڳU�eu��^�?u��竬
������ m4��x���C�9�aM&>u|�7�H�f˰�.��/�+q=�7�  ��P�ݳ������-�l��w@��K	��rh^X�lǲ�<�K]w.})\���+��h%�U����4AKx$���T�N�)ፌ�Ia!0�
��Ԋp)�V�����g�h�`�'��c���£YWux�>+U6K�J�)4d�=A7���`0w(^FNU\��sc�+�7>�x�<l��K�掸Q֩6��ǿ9�׏/��]$B�{�$sv{��<1�r�P\���-6�,����ȝJ�n4C�rI%o?1��a����i�����jt7�J7t��D#��/�V�Լ�y��rB���E��rk�0�`��F�&{���
�����@l�� ��2Y�Efd~���N����	��2r���D
��������%�Y$�^z ����;��/�Ի�sL���/Zt�!�⨈v6����t%�0���\�FoE^
��k^�y�+�2�s`�Z.)�\�V˅'��B� �����5H�%wwrn>��� 4��p�I�L
=���|�X
�	/�>��*����4��W��޺��<j7�� F
̄�((M���X�=VZ��:�mc�	2$�9����w�W����0�Wh�DlV�yB}@�0Kr�mT&�p�o-�����M$��k�n@��	�x���:I��X��b�S}�4 ՘Xb<R���XҶ��E�G�HN��$	�n���2�9 ��0�{�=��ڍ�Wk���y�]:��lƪ�x���E>Cý�h�<��6�g��U#	���"y3��n	��B(�/N 
9_(�Y\�?����37�?@R����<����V[��*Ս������(�n�����_�yk�^��Rb
�5������fl�ïl�?F�쿟�������X��`���Uw��|w~������� ��)�'���͝�33 ~XJqhE�5)���E7�L���j���67��ߏ�x�o%��/��*�ܻ�s~��k� F(�\S^v����m�L��x{����[�r��^]��Y��t�i}R��g_>�����0g�c������X��x����H���������zv�ǣ$�W��uܥ�76���F�{�:f��Zm`���d��QR$J��q��Y�e��I��0u�����5�����GJ�p�P����z5��'�D�k���j�*���7�n԰�A���?����<��^�����v��'�e��?q�q��5�U
_�Hȯ=�R�%�J�O����^�p�C/�㷧���E
�R
����*w���O:��xb0����	�#wx�"v��"GOv��7zr��n�sK��̷����0d�%��1�:������߬e��%eN������ؑ"-0�~侓�����xl��j�ZyT���k�P��7��M�3����g�a�k�?�*a�=-���@O���Y���J�C�&S�~�)�:�y�1e�_[����O�f�ߏ���?��g���s��;��^Aa��.M������1"����U@�ئ@n�C�|+I����U ���!Y��]�Ȋ>{�zg�/���ܽS����σ�{evtŭ=�e5� ���Բ�.��3>+��յ��Սէw"����a{��w���PU�^���QreV���ގ`�{�\i�u�s�c���b�w���ۤ��L�{�4�������m����c��J9�g,�Q;��Q�)*�((��j!�����t�U]]���M��$��f	h1��y�L橖*�E���נ�(��Vg��.0�k(���]�î?`�Mqo����*ڛ,���	�V�R#D�U�� ��/RѠ���;L@JgˠWvv%��7�⥍���u`ǽ=Jxs��(;5����1]�n��܂�[���ܓT׾{�ú�8�K[�YV4S�[�T���%��dBɝ��]�T^��g��H�Yk��Ӫ��~�
U�8<8m�� �����x�R@;��k`z�0��g����H�XI�&��s��8�l�m�b�l�O1�?G�s�P ��)��ow:\�#����{�����ӹ��xke�%˽r�}��jd6���9ܿo���_� l8����[(�,�ы��8lѭ�;��ɋxʈ�U�f�x��e��vo�������5�� ��9#�e���?�Gc�\��U��!��n��*b5���{N�MJ�~�uL����/������k���GI��{�����s�t�;*2����@��w��{�����N{����ѷ'�Zͣv���v�d�[v��� C�4Ό�7_/�,=D��?�L�o�u5�:��x��5���ts-���,�´q�>�>�͝�"C'��sM���g�)2�ǽ��ꦹ����66���:���|����<J��?��'��3�#������F�� E|�O<�(���4CM�������T�s�	?k���aA�@c�����wa7�ɗ]��������L܇�z�=��Oc�TM=SJ:�h�C�aܢ�kr֖@�-C?V�P��/�r��]�s�c����Z��k�����{���kEю�ki��G���@��n�jNʛ�@�WZЧ��GW�$�u@>��p�<���Y�2��Bw �)�a[ߓK��f�k7h��V�`w!�/��;�rl��t��u*d��V�?�h�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)K)������ � 