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
    DoMsg "INFO :   [-i <ORACLE_INSTANCE_BASE>] [-m <ORACLE_HOME_BASE>] [-B <OUD_BACKUP_BASE>]"
    DoMsg "INFO : "
    DoMsg "INFO :   -h                          Usage (this message)"
    DoMsg "INFO :   -v                          enable verbose mode"
    DoMsg "INFO :   -a                          append to  profile eg. .bash_profile or .profile"
    DoMsg "INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This "
    DoMsg "INFO                                 directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default \$ORACLE_BASE). This directory has to be "
    DoMsg "INFO                                 specified to distinct persistant data from software eg. in a docker containers"
    DoMsg "INFO :   -i <ORACLE_INSTANCE_BASE>   Base directory for OUD instances (default \$OUD_DATA/instances)"
    DoMsg "INFO :   -m <ORACLE_HOME_BASE>       Base directory for OUD binaries (default \$ORACLE_BASE/middleware)"
    DoMsg "INFO :   -B <OUD_BACKUP_BASE>        Base directory for OUD backups (default \$OUD_DATA/backup)"
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
while getopts hvab:o:d:i:m:B:E: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_ORACLE_INSTANCE_BASE="${OPTARG}";;
      m) INSTALL_ORACLE_HOME_BASE="${OPTARG}";;
      B) INSTALL_OUD_BACKUP_BASE="${OPTARG}";;
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

# define the real directories names

# set the real directories based on the cli or defaul values
export ORACLE_BASE=${INSTALL_ORACLE_BASE}
export INSTALL_OUD_BASE=${INSTALL_OUD_BASE:-"${ORACLE_BASE}"}
export OUD_BASE=${INSTALL_OUD_BASE:-"${ORACLE_BASE}"}
export INSTALL_OUD_DATA=${INSTALL_OUD_DATA:-"${OUD_BASE}"}
export OUD_DATA=${INSTALL_OUD_DATA:-"${OUD_BASE}"}
export ORACLE_INSTANCE_BASE=${INSTALL_ORACLE_INSTANCE_BASE:-"${OUD_DATA}/instances"}
export ORACLE_HOME_BASE=${INSTALL_ORACLE_HOME_BASE:-"${ORACLE_BASE}/middleware"}
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${OUD_DATA}/backup"}

# Print some information on the defined variables
DoMsg "Using the following variable for installation"
DoMsg "ORACLE_BASE          = $ORACLE_BASE"
DoMsg "OUD_BASE             = $OUD_BASE"
DoMsg "OUD_DATA             = $OUD_DATA"
DoMsg "ORACLE_INSTANCE_BASE = $ORACLE_INSTANCE_BASE"
DoMsg "ORACLE_HOME_BASE     = $ORACLE_HOME_BASE"
DoMsg "OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
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
            ${ORACLE_INSTANCE_BASE}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

# Store install customization
for i in    OUD_BACKUP_BASE \
            ORACLE_HOME_BASE \
            ORACLE_INSTANCE_BASE \
            OUD_DATA \
            OUD_BASE \
            ORACLE_BASE; do
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
    elif [ -f "${HOME}/.bash_profile" ]; then
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
    echo 'alias oud=". $(find $OUD_BASE -name oudenv.sh)"'    >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. $(find $OUD_BASE -name oudenv.sh)'                >>"${PROFILE}"
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
� ט*Z �}]w�H���q�s���!9瞜���D�~H�f8�wi��hW_W��;���B$$bD\ ����'9'��k^���o�HUu7���Hy>�3�	������������vʏ��*�������+�M��H��Q�Tk�ەj�����'��ֲ�4��T|ך����O�.���3Ig���w
�ƾ���P����mn=�a�C�oT7�6�����#VY.��+��ǿ)#��~?���� Za�Wg���=��+�g���r�=��c�>kYW��-'`�e��h�z[}���LǴ.,ϲ��3}�b�o���խ{90���_\��ε�hy��-�sh<ՙ6��cs�]O|�ֹ�C��l��Z~����p��A ���t�ga��;}ӹ�z�o8�[fխf�<˱ue���$��<������!=�a��g�����h�ӵo!3}�Y��a]�g!%���%6'}�G�À_C�v7l�[=v�z�r�l�u�S�s��8`'�[%�>��ЭP��ȯ���s|��)s��(�ŭ�w+��}\�z7ux�T��7�dOc Q�u��6��򐌐�Z3�U̳-�4{?�B3Z�3�sϑS���g��@����� ��@�Yh��j�������S���	.p��w��%�N�x<r�cd<�ks0��{4(��}��=<h@o�Z�ͣ��A��?9~�γ9�c�]�l`��{��m�a�F�����n�_4�:�x�� �h�����4�ۍ�*r�r�*�����ik���srx�}#_��<�|���>jn�zq�P��:'������V����'O&t5t[�R�-[}�9���i̲�Z>����k�Z��N�<��3a@�~�}||xܨ�T��Orp/�N��>���-v����+߼�V��c\��l40ox�׎�r!15�j������8du^�z��ߖ�W+��)��������3Vj���F�Z����F����^ �?c��*a��Ocv���89ar��	ůҊ���	Ž��ݾս��ǳF�Kri ��Q��{��[g]�Ѳ=����7h�7\*��6�H�L(��L�&!>%���s/H<��q��%J�[��>go�e���.Va������f�,�i:����W�X���� �Z�/&���W�?�s����u�Ck�3�Q�=$�e8Z�P'��s���G�N`��~U_�McBJ�뚗�ֻ���\�3��q�vA^�	�-�]��AAf&sl�ɢv���]g0��}���/2v���>>�?���j	����K_K_�N�����~��N���J����E��iv�ҟQ�៰V��|^Ͱƿk��$Y�ٍF@�&4���<k0����*Յiy��n���N�8���S`Y�d*�1,����`�l0��O�o���u�=a����%\{�V�][�{9�u�-�N˪�4�ڞ�XIٴ�n{�,�M?1�#9?�!�C�N����l<1��;X�r4k�KQ���H��8�W�ᜋ�fڄ������$*doC3�h1�`o`I|�̡;vH7��1.�}�u`p�iZC��u=�;���VQ��
	����^���L��VBj�h��P��8������AU�p���k�����f'F8 ��Z���[�^�W�=@�QkO�:�;�B���}���vid���k�ػ����=ʆDR�1��f�6_��Cì�Z~sf�����iz��ũw����"lB]w84\�3��|EEO��1����Y%�l����G#���9��q,.���,�j[Z��BY�pHh̶5'=a�+4�ak�V`G�#��h�0>˱�ex*C~�*���9�,�o�)�V*D#ٵ�8&�A�����;��Kǽvx�'�{%�,%�	��tl�+P�-T����Fʉ7�@֞�{�U��䁂���	����X0�1DX"�o�h�B�	L�8V�MN�.2W]t��S���%]��FZ��J�-+k�p]yn3�q��C�iƙ�.��	����z��*�Z��
Ԇu�!Qp8)���
��(m���Dv���[��:��98A�b='��9�ˡA~�A���t7`��s|���A�+��{A������M�,����Ǭ���Gt�T�
��i�;R�8�8�/�e9�}Ӿ��[���3G,�5l��ǵt.'�P]���$�D@�r1��źcЪ2���)yA�{�x��wl��y.?���l8@
�L�!@�_w�Ҭe�[����^����,�QY�Kn��(B��Ӈ�ov��ߨ��lzx�y��U-���hr� s���	y�";n���4OЈ���]Թ2��eck���N�
���>�	#Alh��EmT�ws�&l`�욃�ح�R"�
:h!%�3�dտ��0��~u�I�`N�0{�P�����i+ �v[,A�C��&}�"b�t�H9!�&�)�'�f��	'�k�u�y�ܗYI��K�Tk�m.�{e1�% (|<z���d���"����B����`L�;R1)����9K%�m[:�l���8n	�p��#�Y^`[>b
�8���� }�ZmKm(d<� ����t���ñY��s�fU�.x�۶!�;��f���c��p������V���RyE�C(����s�{	y�n�����A`�pB�C�v�5B`}P�.�?|��9eV��vl�@����,r���)QK����$�6�m�Xl�t,�
V5�x�OV/`]�t�J"��z�zZ�E)@���e�Vw��˰J\�ܕB�-��bAf���/�r���q!��j�_�p"�)��J
��G[��o�tz�{���%[y�~�{���ȿsJ�`��~��}ypx�ށɡQ��/h[�See�?7{=���r�P�W`-+�Gh�ja��n�f����S�����GZ��;��Y�p�F]���#zg����gwQ���D%���Ӱ2�O��ڍ������w�;��_�(�*`����rF�bF�SzG�n��Bh�eg�Sd/+��l���S��Y��mg�i,9w����9LkҤnM5[F�n��O�.���1b�?)C�C=��`�[V���n%�o���x� A�׷j��~7�Mߺުi���ӷ����"֏�/��'���]������f�����V�R!��J5��}����~!��p��R���	��ܞQ�h�������/����/h;���Ơ���-4�! du������]�ź�����	|g7������>��n��0��=\x���g�4dO��W����_w~g�$�{ ِ�ԝB�D�����=`bE�^<�}PY���f>�,��|d3Y!"�v�WnH�_�!;~�zG_��q~	��̯���Y��3��&; �� Ԗ��݃k�� ����W�U�4�aݮ��M�!|�:�ꆐQ� V��'�~Bӭ_~�^~��ť��-����%�^�oSD�RŖ��C���<K���
ƌ0�,�>��Cq`a�=f]��լ����b(��̃��]e쉓��F����D�ӽ�n^s��+����+ё�O�q �War��s� Û�����"OD!�Ki�8/@�83�)�!���I󶼆�&�RcGx�F��R�iҁ��XB�I{���h@t�慄(�$���X{W~�
�!�Z���Z^)FMSQ!œ.�����"K�Ǿ5��E	r��%�\l��c+�+�+
��� �uM��vb�
<�;�׷��# ���3f`IF�'u�1����G�sѕNߍ������vJ�	lo���H�"@~x�IY&��@ϵ��'f���>�3��׻0\�����X@YF(m�S /T�*��e(����u���x��|w�u-Ug3"U�U�v'?�Z^T���C��)ќ{	/Yi$�Z����Z�Ǻ]BCkr�1B��2���o���ZnM����~�����ì$s���q zǮpiګ�D]�!��ν��m�l`:����W�	�$�E#E��V�Y��ANw :�sz��@�,��b��2+�w��w�rDy�"�Q���ne���v��c���i�����[�Ы�'w�O�z�t�xN��mE���k���7Q��݃�2�X�`0�J}��t"�����;M��Ri��(6,��y�2o��|�w_�W`���/L��bL|FW?���_|�aJx�E�P��n�ހI�g!�@��FT�yB�P�מ�q�y�o
Y�Pn�s�O���uR|���U���ճ�gO��8�$)�%WW���E]>���'w��t��]\ٝ�2����V/n~�:^���c����:�����6��3XQZ���zF>4�(^ӅI좳��g�m���y�P�����Y����D���U(f׍�)� Q$扩������c>t��������������?����Y����?"e��_��3p��Oޠ_���������Q����?�.!��G*
]W�"t]�l��l<#���̡t���CiŨ�l��>�[���GآW{{s7�7J��s.�NnFV�O��Qc�.p����4�e]�`���Qd�]�RI��O~�?*�^̋̃���A��Ȫ�|_ڰ�aRFÁ��*�;�����Is/�����I��fqk3�\�#���|r3���O�'w.���)7s��<�\��%�r3g�)�2g�̙�g�L��8�?AGڠnׇ��2�hX��*��!�l�2�Mf̼F3�џ�ר؞��k�����4�˩���U���8�8;���+�ʌ�e���z�aM��˶�G�-�9d���ߜ�i��tp��\^勹ýV�� Q��R�#� ��T�ys�O��N;m�<^�)T
��V�}�K	*��D�zXŴ�
)��.j%ڌ�DՑ0}�"��v60ܚ�Yq�]��UYŐ �Mʼ��}�8u�͟�'r
��G2��	������"��T�WYp9e&�v�poVEjEx�ӛ����"*J�e�Ȏ'wބ��F�������lᣎ�R(�iNwQ�U����X�c���9�/�n�cA�n�d�7t+��=��Fe���4���2o���{6��3�&���p�m�]D��Nj�;M���B��f��D�1\��8�]C>���`�1M×B⡛L����M�s��Ǳ�V��x~o�ɞ��S����r(�|�C�lg��2�6yᘺ�.^��5�M颛V|�z���Pנi>�S|�p�M����S�(��4T�c���Z��$I7ro�J^�ȌA��33��ڄsw���ua$���7v�?r��e��wH_���'����8ͬK�c��w��Yy�����V�V��X�����}��7���>����]v�a� E�{����/����o��<99濨���?�!��_����ѣ�=�0G��eL?@`\�?>���z��`����p�p�7�a���yV����?������uzևG��k�?�#��_���{��� ���LڍBK�c��߬lV7��������H���/s�#���9����):���,y�Qtr#~�hv
d�@*�S =X]��8�)���y�����[n��=�{iy�'D��"T��fB�?}x7�&��O� �� '�ٍ;n�!�������lt��q�?��v`@�A�˃�#�쮆A���>ޙ9v@� 垅�E��~V���K�������h`��f�h>y.����<�ͬ�@�l��`�S�/�:2镤�<@2<D)0/�����;�y�99���G�Oɀ,����I�R(E�T*M(��B$7�Ķ�ï/���ȼ��9�qy\��A#,���Ô~!aR`B��T
��p�C@��TQs=�-[�ѱ'�,�д�R�p�q"~����H�`26�v+P��6L�Q��JRp@������kӳT�/��H���?6_7UD5x? 3�>�X�*�y��4��9�?W�xԤ:C��5!'�6�]�txV�-�M�S�B!�Z.�.�Az���8
�E[�->_������gK93�Vf�ס��<�K�c�� ��PT\E�$:��o���z.;�r�@��!��˸(E�^/�Э�( \�!w�S|Lp�6"'�
°���;�i�5T��4���0�]�Lܹ�K(�b7��q��3G�@�K����|4�#���[��1.��G����e%tF`�`	&��(�Eޡ�G��ry�S�B	V-&�B+BF�yh�B����륻�R�P-~b�G�b\��z=_��g2F�<7�Y������GP�o^7����%�r'<�i}��cB�,6�Â���w�-��?iS�'�˽���=�:6����y5��\��M����y0<�� 5���w�3vn{~�����G^۠CxB�y���D+�P��N�u�u���c�[�)�50ʕ� �=sDny�7N�J��Q-�Z*	jeC^n2��B����%�A����$��iS0š���ݎdoԻ���V�s>�`R���AI�$5�$�!e���ya:4���4厖H�PQ>;W\ %)s�Ƹd�/h�=ZN�+�ɑ��3VAP����[���zOoUQ+�݅���X��r����h���I��k�g1DIW�+Ss��x�	ń?-͐�a�0��:�B]i�)ꕄtOڳY��N`���U8Ch�B�&F�l�hǅ7g~�w��j�h��;Q2RFU�cEB�X�*���'V�$���	ܗ���;��$~�;�}.�-�ǈ����N���=	t6#�X���1��sy��%��5�t���������]��o�GuEVG}J�����>;�`R�|l� x�	)QMk~
2S��u��(Ď��K�i��
�J�Y�	��j<��p0z���?��m(8TOD�P�(�s`��C�F����zZ��ӽ��t��������;�,�|�CH���!=����x��-w����o��zb��N���B��{|*��^�,����}4'�wҮ�%y@�Su�E�/�� :7/e?��'/̙tHR�v�S4�N �s�6%����#�|����f$�pO�cUOxv���]-D.&J�N�ʋ-*͔
#�Մ�:|���J=�^�yĎP|14�Nd���D��NgO��$��Ԭ�Y�|�x�"2�q�(���[x�U܍GII�
9!A!kH��,��`xL�I�
G/C�v��F打YA�i���NKy]?�x<G�+���<�GB+PN��D3OwИ˅��w�}9�I�y�a2y�,��>ڷL�Y���E����p�>���ȳ����q��JՊ?���������Ǐ��R�����6�+�dK���D��8���K�V�	���eʑ�ė�(bIA�C���n�j8�`��ƍBU�<��A^��I9����\m��yAEKCuCg���h�:=���WϦ#� ��k*U���F�����t�1��
(MOJ�Gi�	Ng\Ǥ�$RU�t�`��4��*ݜ�g��gU<���1���&*�Qnf�<^�R̉q�6�ӆ"T�v4R��R&��T&r���\ǡ���^�s�<Z�5�B�痺�%4�X]~!$-��;Q�� ����Z-�&1Eh�u�X舉Ʃ*�(y��p�}Ǎ;��h���c)9phя�� �g���j�}1i�Q%�ʙ�LY/�7!�o�yE.�^�����w������l<I�G��Q��|_»�,���H�L|�7a��������T,���J������T�RJ�_N%�R���R���:~��SeÀŻ�U>��Wm	�	:���9���`����v���u�L& � `\9�5�;�|�`��=}�y���ǅ��<���>f{w\64�n�-���f�� 4l�^�%�h�%_hr��.�D�� =�٪gQ�v�p$�"��,z���Pz�ê��][���s!&C��)a�Z��QX�<�#+p�R�gH%�U�OhF��X",(?�ի�����O����_s�c>ao{.y�%$_Џ�'�H��a'&�Fd��w��= ��s�+�uQ�����NI�B9^�޵��D�M�<�v��v��n`@p�e����	&�(^�T�$\�jfi���O���'�Y����1�z>*@��[]o��u$_,%�⢠�a�Z:� ��t����/�K`�m��� ���F�@r&�
��žN�Ëɮ�e�Ǻ��-'E�:�N;'��,4Bϵ��N�.��JNRbB�GQ�B�=}�4�5��D2'e�M���#b;o�*�c��S���������厠�p����AN����3}�/��!���!IS��S� �a���M'&mR�,�T�����S�Bҵ�2]��C�O���=Z�' ����k^]���}�����ъඞǰ!b��S�7�7�l��V�ue�� ��=/hY#E����N�pWR�HƪVL�����5(rtԜX[Dg��4�3n�G$	]�A8�|��}.0�3�8/P�}�[�鞑87�3�t)�U�k���'��G��u�]�ޮX+?���O�������Q�A��T���13t���tV6&�C�f#�!(���YHų�Nͨ��?����^��t
5ŉ��.Ⱥ����hD�:���|�WM�w�@uby�q>�S�s!�&b=�'f���0��y67�>2��bcu$�=�ɔ�E�5��X���|Ҝ��޴x��9�'��R����7��2n��h2$/�T�2b�N"�a�x��/�nR���V�U�.K�cV������Vk�ەj������#��T�D�����Zګ0���,.�{�olf��0��v�;�����gs���?W��6�����܆����T������ߨlת��ߨl<��?=DzL*��*�J��3PY�v���?���CK��z�׳�;��p4�M�
ȝ!:��w���p���t��V1�h۔�2���w͑��9��?}�_]���:t��o��7�<��pW��#8X�����>4%���욾c���3���
�x �{�SSayI'��}�]�[�xn""�/4�>�3��ƁKǨ�
�s�^���ؒd��L;u���:���:ez9�#�C\�e�u���;
s�k<�T�Z��"&�]Ki��˭I�Y��F�����Mkka ��5A�ugG��""���ӥ�d��5(�M�l�o�E	�+���ʂ�ԧ�D)�`�){hL����8�՘n��s��SNC�hb8�|��A`9X ��P��[�0#�=�`������o�
qlQT%D*0m 4�;6�љ�AÎl�����ڦ��h��M�xV��S�"Ԑ9�]��O�����5N<,8��z<�uW���I�B���^Zh!���,��j�78@�i_��:5���X���_��?��?Q :nK��������R�����Z��0V{�de���a��R�Z�n�V7뵯�[_�g�v/uJ��n�Q�RO�6�CS��S�[����g�r^��{6�vXB35>Ch���������J؎g�V4����Ôr�qq����aJ��|�MUhj��p��`�8őБ�	<Tݔ�f%��ȥ��GQ�m�mqe���XLiȪtEC1�YU�xx5�
���^ED̢�W�h<���"��#�"١b��{`�*H���")��"Ĥ�Ÿ/R,T�v�$Fx=��L�O��*��`zo(�f֝"،�)�Oj����uN�]�M���'F���#��U�,�I:ER�����f�G��9��E,�+�����c��5G!2d�hÕG(�K/��S�[�z
?�+�r s����&Z�3����"bJx����KS|@�0���+���|(.�\����6>{�{E�99�¯� v(w�^�Sh��CT
w��H�<��H�2L/��mx��z(CYv���(�D �V4I�x���4W�l�,����K���$�:�i'p�N�w@(1�����	��H�s��i�_3W�	x�O*5���!;ʾ��k=DQ��RմnI/1�����ŝv�>��d�O�&�-ˉ0��W���V�o���F�Z[9��CXN���0�#���\��冧|Fﷁ}V�A��s�����*��yFO�I�G�x�A{v/<7��νI��8 ��Ȇ�at:"V�1�?�}����Sm7�E\KBG+�6`w�X�끏�K�Ô��k�x��M��3^ENK�3
+rz5�p@��!0��M�KF:b��#��Xs��\�%�[=Ex�j�F�b��1�<��y	��������h�X���%8����n�|�̘�/�����,�����E�w:���T��q�rl�@{�qf�h{���\bi:£�۳r�7�j�6������z�u��:��;�>��nzݾXdI��߄��֤!5Y�_��%_L�G��}r�Th��q��Hg����*2��F	����+�м���!_����Xr]g�u���L��Gw�q[���υ�o����A@c�g]o����������&*1䚺����Z�g
�Mn3c�~W��P��P�4Q����0�x�,��J���.:���ٺp��W�-@��`���8`��C!�}DR��6	"�9�{�\��% �>���E���1�1�}����F����[��(�B� 4a�qW�^d�@�.���3}���V��8*B�p���ΖW톣Ҡ����GQ�tL�`���U�S�8��w&Z7� �p�z����o􎧽~�'�l!�I ��ϒEZ������S�0+^j҆�2o�����z:����l���2D��_RH縯�D�\=H�<Qs-�pa�s}>�;W56�n�*]O�ꥠ���ꖲ|�B����h@+��gv1�������F��`�.�4��Ф-��np����]��]7��WE���Րti���GZ����������\��1]^�J-6%��2�P�j�[g�n�=[�<�cܘ�����W6H#�:�h��8eS}�Oժi�`�B�-�J�}�F�^�.2�2���HNE�^)��T@󢦅��A	4�]�u�B�XPǐ�ZӄD�볻c������JSu1QE�E8_�-愀Tfv�qeW��%�r⸁NY�1�:H�����m��C�ݐvH*�ar"�B��M�鈍ce��az���F#jix^�j	=���gLo�>1DP�2p2T����g^)~P+�3�W�]�1����U�6�*�C�gi���J+���Ӄk�6m����}Ā�Qc��c�^?=Ÿ4zjvU��
�X?�<�J�Xi��ݠ|>��֌�Q56�
vg��kY�Bi��D�
j�G!y�ʤv�ǾGw
��]V����ius3V�xaKx��9�#���k�QCmUB��%1� ����6u��3�U�b��Ӧ.�3Fa���0h�7wRh<u����h��a09}�j�|�#I+�J|cTBO�@��v��@_���eO)t�X�:Mv�p��ҥ��U��*a�d����@�	 5�N���������(Ӟ;_ʹx)���K�|[.�]�B'j�g�E�v���1X��|7X=�cC�cD�G5Э&����:�=%�${���<�7?S��3)t9�N��T[�i�t���|��j�<���çs�V�^5B�"��8J?Pdd�����+n��-3��Əi�D/�QN�U��DO�,|\5ő�\l�����O��}���v'\�����5v�i$�s�Ko#�U�TDa�Ut'z/�0r����Q�'ٚ�n?��|0і�x'�>��۰v�%.*%�p��l��f�BK6��+�ҿ�I�M�kRWt	��f��2�F��B��� �A\')W�.n���ρ���PkN���ts0�m>�»�x� c��I���|�U6T�����e�_`�Λya��pӍ�	\L�N&~<�"~�`}��;��d��A�W�;"~à���i(�oӄ���1�*��I�i��l|�4Cm�~}D�xV1���/Eۡ�ii�H�{��H3�ۗt!�
ڑ�B�{����~U^�۷#C����&e�:�A�J��b=�[co�����#(���-�E,�φ6�eCo�P���D�=���Ux9�*4k�W=6v�?��99e���Lz:Ռ���кg�f�3��ڊ(�̀=E� ���k�$���]�Eu~yow�}�i� �3���x�7�r�DIw?�W�ڪf�"��Y�R���_�������Fu{s�	�����_���$ǌ���9�+�����Uk�\g���lTqZ��D�[�����V�e:�u��U0ί����:���Uc/f�y㋋uց�G���gK@ף��{��nf§�8軞��	�s�H�$�VA)���3���@ '+(���AX��g���?}~�;��~aFJ���[W6�N�,�Ϧ�՝K^W(��B�:�&�o<-I�-T|�hn`�u��7'��t�и�V���b�>Q#ρP�`�������w6�f�����Q�6`n{���UD���Q�J^���8tn����{�u���/qw�Sm����]�����Ƣ��g+2g��ׯ����5ױ��@�4 �,5`����i����U2&C[_��=�o������l���4��;J�u�yzB�0;�y1����~9_��|k�8y���I�O�*S ���l �w�cq�9�`F֏��XGx~]�)P\�)"e.s�������1�%釛+��DD���	&oL\иFv�x�L�ɠǼx���ߑ�՗�1����.TX	��k^�y�+�'s 7k�p�$s�[-��d.x��lv�o��#X�`b�pD(���s��������Sw�Nˤ�#� !) �=y���<i7v� �&�Ot�<�d4V�C�k��]w�zs�a�t0g�w�^���Ҡ���ha�l7h�Ev%�u_8h�F��X��#(�U��;enO��[w+N�3��g��@�eEP����Lmĕ�6V���ےe�qc�LVJ����6V*I�����%IPՎ\*��� P.���X��4���}���w��B:fh�V1���/�|��w#���0�B�����S|�D;8�v[b+G��J~�ͦS�BNJc
��gqzsV�j����St~iyṵ�T0�O,���Vf�y����(n�� ⪼�b�n�v�j�Cx�
��P^v·��mt�
��o㗥��IQe,�w�xN����}9u��&4��c���c��O��7����_����������,�߃$<���:>k�o;���Hщ���1o��j[� ������I�(K����c�Z���!��a9u���[����,���D8�%�q��Y����I"v,�����_���A�+�O6�`���_���3=.Q�1{)n)	�t;=&���nK�+g�^��F�RDBy��=�.��E�G���3�~.�/-¿�:�b�2t����h���ܽ��(W�L'�^��I�K�h�����-�����[��l��41~��1�C�'������2�߇v���:��I1)��a,�a�wW��>�nըV�75�)�W5�)o��Q6��Q�;ŌI}īD<�0�)�{IO�[���?��J�2w�)y�Ҕ�u�u̘�76���'����)������>  ~p��1�l�WPX4�k˺ܰ��` ��[�xn�N>+�[9H�o��W�Xx��G"$;+�ū�=��>�r��L��gϞ��w��x2�������31Ѓ�t=:�n~9"V�k���[�O>���;�����I�BUaz}8J�jDɵy��p7�}�y�K���R�,�o���fu���6��e�����,��jڮs:Wxe#?��c�X(*��v���SR�3PP��U@>E[3�t�u]]Ø1�M��$�ʶ���v�<�J&�T�
~Q�0���4����g<> ������q���<ji����&�i����RjD(��� �kJe�IZt����|�Z�*蕝�����ھ�.<fp��ӠD��F���:�{?�t����Znq�\��}��=�uGI>��.�YV4S�[�U���%��dJ靡�]�T>�& Z߳�ޜ+$����D�Y��[���Ƒ��iw����ݔ� ��rر>_C �����|��m���d���gQ�$:'Q1`šgk�h��Gp�1 ]1,��[ �sJ�ƛ���F��~ñ��À~���\/���d��B.�ϝ܌��� ���q��K�W\9�{�a���8~�U�-�� �}����
Q��`u���^�Ll��:�s/�.^�Á��πuF�ܑ
�#.�>�q� �D�*�I���D]\s7��A`��A�/=��%M�j�u�����/����������޶^�����'Td�������ro_��ǻ;�s��Ϋ�ݓ�O_��'�����������y����l���^dYZF�x���5��m4�7�����F6�"�Ε���}
}��;�D�N�����}���_�L���vh�٢��O62��I��G����h����o��l'�>�!<�L~ �O,���x�0�Q�=�@sA�LS�D��	�k��c�� ��qx�>huN������y��S�]������>�M=��+���$USό��(^��w(�Y��%�t����44����1��{c#���]٪e��C��_+�v�_K?[策�"X�uUsR�� �т>�Z=�r= a�� �ȇ���z�^��9���x N�.L���\��/0�p�]�As����9��d�XM�����3�|d�0QO��?�	�MY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����)��T�6 � 