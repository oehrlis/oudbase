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
� b�]Z �}�vI��v����Ӯ����s@���W�b7����Ԝ�m	J�^I�-E��@��@�-q�|���}���c��~�8"2�*�. HT_PݒPY�����������]z��\.�lo3��)��\�����U6�՝�Ve{��ʕ������h��{��*�cN��..&|����<���θ{���^��/����_��~Z���T�77�[���[���'�� \b�/��W~UB87�~f��� ��^��rs{�ZWF��X��{>�,��<�4�́3���~�����q}�����C��a�L״<�5<�dկ6ؗ��*{90|���z�}m�?�����sG���E�Ԙ6��cc��W|l��a�#��,��^�y�Vt(� @���t�k�A�ܾ���}����7��M��V3���ļ�<˱cY���x��䐞ϰvǵF>��3៾�,�fwL�[����?�Y��H	�7=��i���0��а��{f�]8.3�+�ul�T蜾3����f��O��t+Ԇ���?�j�Rr�ϑ:%N1E��9�n�o������J��U�Z�<e��Dal϶|��+�E2B�J�X�`��������ф_�ٱ�s��-.`p�.T��{����ѫ������Y�����
Y`��C�踽�-!в��Ƈ�!pM#��^���=�A�׭����az3�<j�����ɫV���� ��������1� X ��v��}��o���9A6����=�;>=;l��5�p�˕�Ӄ���Ik����z��GYJ|����>jnKz�b.�ʹO'�g߶��I=Ko(��j��G��[���s8����i̲�z6s���o4�'�v�<�[�5`@;�L����^Ψ����^��2�C������x�W��3���cT�6-o40nx�9׎�p!15%5��ǲ{�/�X�W��䷅���
�G��!���n�+4�7�Ft����{��F���v_ �?c�*a��Obv����89ar����WI�FJJq7�x�ov.i�q����\J��;|$�^!��XǮ7-���$�Z㦀K$�sHa#�D�$�t�[�������Tn��x�	����K��<�u��Bb�z>+��_��ngd3w�a7��?�-���}���gs s���x��ˌ�/��mf�s]��:���e�oIa�5ԉ�k��Gj����S�$+_��o����u�K��f���`�{�܄�����@rujW2`FP���lt����� |7LnA�d�e���΀��ab�Z²��w�/��/�g_|[���E;���k���IzQ{Ja�]��=�=�=֪՛ͪ��w-C1ᑅL��# Kr�m�ՙP��Af��¤�TG��`�'`DY��7MV0������d0A6R�׷.���㞰�j��]G��-ъ$Nm]b'�Ӳ*-�����f\6ͱ۞=Kjӏ���H�N�E��@D�*E,*�)�@�������M���'A=!�+(����|0�t��6�=�⪢d�
�[�L�Z�.�7�$�1c�m���7�%�Wdm\c��P�w��WT���Z���pj��
{*|U+!�X4}��S=��h	y�x~ˠ*x9i�����y�!zj�T���L� k�ƕaP{��S�L���]��;�N����]�� f�]�.���#`�RQ"��ۜ�޶�}�/�/�afW-�5�|�u�B�N��������Ի�ضQ6��3��zp]OQ��nN�z`yiVq-[��Yx+��H7��j.�m���o�=S����7�PC$�m�HOh'
qXG��U���H�;�8R�g)R�o%��QEC�?�|�����W��J�wh$�6l�`��}c0p�a���b�}i;�6oz��W���Pr�:N'�й��D�����h���Cd�Y�k^���`�N(�ό0�����C�%���>��y ����\`�sqa��d��"�q�EW[8�/0[T��(_L�W�ee��+/,�2�Pq�>�8��O��˯X���"��Z)CmX�>��b��Yn��M8���{��Q���8��R��Ĳ=#t94��O9�[�n�A�E���BeP�J����?���~�k�k�UlZ�#V�L�#:]*j��ڴC��s�p���²܁a=�ƭp��#���U��Z:�����NAp�"��N����d�1hU6�Ӄ͔��׽p��L����G���'41��#�f������4�_Y�f��Z�梶,?�")�"|�-seE�^�#����ʳ����M���4/������-%��2�jK����I�xo�q�F�V��Ε�P~#[e�uu���P -���̈ɸ	"C[t,j�꼛)j��̎1(��z.%�,��R�=c�H�Q��J3q;{�7PW��
f�$����l�1ȟ��h��b$�<�()a�'�	"&�A'��S��2�N?!6��O0I\�@�+��L��H��V�&Z{o3	�+���  ���MS4䖓�Wb���4mm�;Ĝ%flK��lD��2xF�,��m�µL�H����ȧ�Ǯ32]�2=��8�4}����%62�.h�`�g:S����,��ݹ|��e<b�mۀ1$�х?0�|?7�p?�`�U���\�PZU�J}������\B^���&��x�[#�AD� D��5�]a���|T�s���_{�wv����M��H?�E��0���c>	i��o[��͕��^������Z��M��Ʋ��G��՝�D�;X�huǍ^�+G�-��):Ⴌ/d���B,�KR���1��&R�2\�$��}��z����gG�7�f\_��筗{�O���;��VH/�g�뽗�G'�]�ꕯ�����{0�'V�c��u�J(WsULz��*ֲ��Y�}�F��6yr�7��N�kv��iIBiz��<᪍�@��G��v%��O�x7U�JR�קae�O��Z������e�̭wH	���QU������2�Ō�%��~��3�<���N���^�;>��<�;T���Y��-{�i,>w%�U��5)�[����խ�>���2�q*�B�'eh�x�e��{�J�_Э����?��!h�C@��v5�������[��U�u�}��t������=>�G��r������U&�_���]-����\Y��>Ƴ���L��������
'P&I�=�N�������"�� ���f��e�����k�������ٱ.nB?l ¼w���>��v��'�݀Շ�������	���
p፹����}��0$����ٝu�8�dCfSwJ��ұ��k�Ċ<���G�Q}d��Gv�#˖>�K٥�����;�+7�y�ķ����zG_�9�q~�¥_��̯��_קz�; �� Զt�{ ��ٹ �݃��~+la.zÚUk���c��S�ꆐQ� �֤�'�~BӭWz�Qz�J���������w�b/ҷ	�Z��bK	l��s�o�'�E"#Feh��
	ơ8���VX�5q5k�{�h�1�=:�`�gW{���(!#��l������芭�qe5<r��3��
L�||.dx�89D�]B�(D�w	mO��t�s��w�b�l�6nK�xl",5���hؐp-%}��d��jF�k�p'F��6+$D�"���o��w�wk�w�bQ\ϕ�UJ���i�"*�x�EZ���tVdiV���3'��(Anp�8�����!Z��luc��y!�]~�6�I�[v����~g�|Kp����n>c��ddyR's1hY~�1]���8,���X<8m�N�`{���އ4�#O�2qmz�y�>1S�,O�D�@PF?�Wtps�+z��W��Y�-w
�
�޼�e�����?@�6��ݎ��lŐEy����Ϻ�V �����sJ8�^B"+��S��)��w��%4��[��ι�)?|�Ơ�h�5�"�<�E%yg�YA��c� tO��Ҵ[C��QE&�{�������/k�߯�cI G�^�
3����� t��.�l���YZ
�b��2��wٍw�RDi��(�[^���aJ;W�1����,�Qv��Y��-W�U����Ѯ�"B����a�#vA�Z�G��łh���!]̅B��|j�H���<�fr�NB}�T�c>DE ��l
5Ϛƍ������UX/�Y��F�c���Oc��i��<��a(� y�ro���3@�J|#*�<�q��k��8�<�7�Lq(7��������:)>�V�ȪrtRk�Y���,2N���@A$Aɵ5�����.����>;]�qWv�̾ƶ��ٍ��Î׬����ε��l����V���'k�n1K��\��,���@��ݱI�>��a>���eu��\B]�
E캑>%dB�D<1U�|�?2��~��'2�x�Y�?�7�7�����V�������,�??��g0�~.���A�\�ϧE����W�����w	��RQ�r���dK���7Ad?J_:��A�i8�����lt�Gu+=��[�j��F�>{�E��������:�o�� v8�À��1�K���9ʀ���`=[(��3�ɏ��E؋��[z���=h}����ߗ6hh�(#��@Eo���ݓ�A�𴱿�ɽ���|r�qk�>�T��'w铻��-��|rgr�]:�.�r��+t��S�ҙv��3�ҙ�'�L;�8�?BGZ�fՆ��"�h}X��*��1�l��r�5ϸ�]z����F��܌^�<޿,��\N�(�����t�������U\yUf<-��o�׋kxh���=rm���&S|����M����#���*���7��3�rq�6������u|�n��JϠR(ĴR�\JPAt'��*&QH(�wQ3�f�$j���ቄ�����pkfű�;���!A֛��f��ԝ7���	�b�����.>
�+T]t_e�I����½Y��oob�#���(ɗU�#;��y.�R��f�6�ҳ��:.J�ا�EUWQ��wb����w����8Ƃ@�H�o�V8��s1�J�.�Y�{?�e�����,��S�&���p�m��G��Nj�;M���B�JF��D�1\��:�]C����)�Ԙ�A��x�&MY�4:'QYxjE<�g�6N�4~�8���T<�C�����ӝ�c6�t�Kl���u�1��*�c@	��E7�z�t�_z���A�|��x�p�L�����(��4T�c���Z��$q7rw�
n�Ȍ@��3�ތCGm3]���
R��ԍy�Ϝ\�zKW�;<����G���o�,0�.�������V�)�Ww6w�*e���|�����8�_��_>��'O�;j�?HфiO�
�T����?��g�n6������J�?���#Y��H��'O���1����|t Ƶ��q[����ד'�	����3��K���γ"�_��1�}����5?<y���1���o��o��ʣ0ڏ��nZP����N���[�����,�|���'�O��7N�I\<'`����D��@q
�?҅��H�A�B���>.<���f��u:���xB��L��z��0��)�+߽�7��|2�=9q�n�1p�q��n.W�k�㎇+��ձ�"t��6]�?r��h�4��㝛�c��aQ_�*�ge�Ⱥ��
1����kN�fE�g#��>*�:O�b3k07��$��L|��C��Lz%�5�Q�����g��ڧG{�H�)!�:v<ҢJ�7�J�(�ɍ�?b[��ח��`h^��xځ��4.�K����aJ���Q`B�'T
��p�C@��TQc#�-��ѱ+�,�д�R�`�1?�L�Rd�l0D��b�?&Ϩ�
��)8�N����v��*�o$�{�Ʋ�w��Q���̬#��Jg��+��o�6��?�V�`(q�&�������;��i|"X( dX�!��<H��1G!�h����k���'�o�����k)���@h��k��$5� :UBɄNv@�3������=a ���v�e\��LW�K=p��7
 z��f��Љ��0��y��v�ug6�sz&�k˄�;qa	�T�&Z7�Bz�h(r���c@�ᯔ�zH|�rk�P�3�%��H�@�v�����"�,��
�Eq�cy�E���C���r���>T�X%CP
�I��cA4���b�V����sK$Hu,)IEPT\�b�^�k\.b�Z-�'���D�f��j�x�~1}����0�IȽ+Q�8�2��e8��[�@��w��==:������Ë��?3r
nyr��d�I&�b��N~DM[\"�>�En�wFZ��"r����7�Y�N����w�H���"��$�ޡCvp���`vƄFI�D�^�춚�C'~�ݏ���w��1�x��_�w��S�I�w)G8~.+�����ǅ�q��[t��\�Wz���@�-P	]�[���Yt"����g�v�u�y���c�[ů,�2����=sHn)3P?C�p�褅Z�\tм��W�=c�UL�4aߒ.��C�y�#�1h,�ń�!����4�]E�P+�m���:��j�J&���q(��O��<L�)��E�z7�م��*I���+8�%)����h9�� 'GvFGgA��V������E��Eh�0,�z3�9�7���<C㢑������9�j>�)k�P��GӤ&�t:$B'���gt6A[���}>�:�	��
g�E�X q�H�I@g�ޜ�މqJ����j�T��Idu�)�8kU)�M.΢%�@��p_�s~����si�vw^�/�͛ǈ��ѮN����=	tƕFTb���
��ry��%��7�d���������]��q���'S��a��`�1V���M�Tx\&:R�SO%*I�O@fB�"���~o�B��
��4+�+��*g��~��q�����%n��݆�X_]Du�E΁1����@����L�2*&�O_ᙷ�T��Uե��ί����jyt�ׇ�z  ��p$�Vǣկ�G�<H����Vj�)�Wu�$L���A��A�wr&)�\*JN��T�����>�2]ZC���Ű!Q�D�P���-x� xI�Q��Lȿ�4�<&��t�V�wn����� KQNl\G��ׁ�I�a�UCي���K-�#�Z�[D}-?+����`�M0����C�؄z�\�2��x��f��$eJ�:1k[�+�������r]O�N��cNuQL8iG�ϣ��C��Q\�bX�kP��*�i�{s�
[{Wi�錙�dT&�ni�<����CJ#��O$uң ��i�92��k&��C�
�*ִ��?w�N�Y��t�o+�ʴ��Ga��@�ΐ�h�~��|���U��P���p�Z�A����Jك���_�-��{gg��*!Q
ӄoxg���d��D�ۤj�r9+ae�^� ¢StL���z�B�x#�[#U�`Ζ�ҏ@��IϨ��cM\sc�b�ʑ�������
N�먛`k]�GH�I��"�<a��r+>��'�L1� I�L4�H��w�R�%j��}=�������6 ��2��	>2��;����Oc4��˽��t�/L����8���/��w�D�F���VK���~I��<֙c�4�6J̕F��`��z��E��:Ӧ�h�|����)(V������?γ61�i5�\%(ֱF�z�<�zGY�.{� �n���Ga��Z��
�.���p�͋{�T����ض�½�P+d����&�9!Oe�˯��pN	4��t�iJ^���'���+��E�ÄUbF����J��"6����UW��KX%t���UJDױ����S�1�=42��A²V31R�ӯ����g��_d��^в�V�`[�����Y�)�@g�������zz�.�a!}��Bq�T^H�?<;98$d��Hv��9̮�ϡL���	�#���<�L�d�;���Jzr	��Y+!��Pl5^NkJ]Wv�5)R+��O("-�ب�B�T.E�,�`9LO�*��e��I@�&����� ��C��]������^� Ă[�C��5�������8�3dc���	�ӞN`X�;=�^�5�˪���]���B��+�J��������b�}J�lf�/.��w�|���S���`=ar���� ��!#ik��&�
}���\�ئ�DBW4�ZŬ'3q��6X�Q)м(�:{���M�����b>R~�~<���V\�׋����aI�!DeW�(����p{�ZZ����0���H(�&}(�o�W˸y��K&v�ڝ�B~��Sv\`~�`J]�C~ރ��],{'�V�_����<c`p�K�S�(�W�����]g8t�c�zN+�T�l����:��az&d�<��^�J.�.V
�<���>�b;lh���������Y��E��:��'���Q�=ç#��0/[sM��J).:"dsZ��X�WH��Y<��1�6������XF/� Hx O��#���q�R�ck'Inug5�43������(�#l�G)���U�g���:@�5藀|~?$��C Q
��¡ųp�d���X�`���߄[��N�e0���秴l�.(Y(�ǽ6ܮ�ɜ'���C<��\��r#���eaU�T����P�<M�6N����m;�>|�`� �F��1���QR�7A��@<t�䋅D8�_�g5"�4����"]ع����a\A���� ���ۂ�O���K�={q�u��#OA�+��ܹ�6�5)-p�\w�>=�eK�!8M��{Ѯ�����Z(������|�MF��磚{�y/
��y�I(�\���zzG���'��  &.���t6������G�!�Ҍl��4S�"�c��YJ�˯h��[��	�s�Z�<��*��O���=�k�Ht3�4 Ҽ�ء�);�5m��.okY��(�k2e0�A�Q�w�Q�F��WHB9<�!�Z�P�y�B�;/R�C--h!�&נ�Џ�ς��:+d'qP�y�95$Ip�_���}�w�<�4�a�ٹx�b�p��L?%�s3̒ǫ�C[�ҹe�R75�G��5�z(�_X+�j��^��x�v�KQ ��Z�ϖ��)��$$�����𨟆K1�(= ��iHE��PƠ&I�_��Z5E0����Ⱥ7夞��B�x>��<���@5�<?}9�dKU*Z�D��L�r�BH�Tf����cC�KB�͌FD~̆Lb��$�w��x�0��T[�]��J"����E���t���M��|��|��Bba��#����[�� ܥ���7�o۱��<�p�1$5�1-����y,���n�������1-�+�K�lV˕��N�Ra𣺵��m/+����?vL�zx���(.�{�on-��q���Y��2s����[U�����ʲ����?i5��ⰻ�:�O������S�D�����w��
���R� �.-�i�unn�e_���_�n��k�]��BiG��=�`�����Z*��&��1�"�����(���'p���:���1�����v�U�S�:t�Z�o���<��hO��6��������=h�?�7�5}�8������7��'j� rw�:M�q8E$��$~��ѱ��D�6����]�q�P��-��e�5526%5:�vf�}��N����:�`W�կ�V��(Xa�S\�9�r����k*�(f2�iֱ8`�7�n�� v��z�t}]�e��Y�"h�ȳ��|lwh�]����4�mx�;� ��dݹe�:Є�ԧд	�`�akh����!iL7F���*�^40�+f�v-�7m,�qY�;7}bF�+��=��^����
qlRT]D�7, 4�;1�ѹ�BÎ-����R-�f�3=���]����~j�xޓF�c��XJ���:��1�\���`���N'|1�C��u�B����HdY��"{�(���*
�s7 ���������?� ����ڟJ�-.Q;]�|�a+%�c�[�W�
�*.T*���Ye�V����%<9Ũ�h�r.��q���k!H��J���m�kg'��W7�y[�_�����7����l"<%���f�}�І�7�u����v�����O�h
���+���f�(��î���4pW��L�26�s����ӠEh�BS�?W�";�)����L��C�O�jڣi��1�0�Z��7�-��HC�)Y�g��m��*��
�[�TENN�"$f^�+l4�-�wQ>��a̓�H�Xp#��\��X�6Dl�P
{��6�w؊���=u�����ҰH�X΂ɽ�l�Zw�h`S���M�&�9񣸿~��Q��a�`��d��9��`��B��y(���#	��|�r~QK����ň�1܉o��������#��&�^�)m��I=�G��\9�9yL!��� ��v��b18�C�')>�A���+����(.�\���U7�=߽�{Nμ�+*�
�8��l.Pl���A$#`�X(�䲯����VVe/˦*I��J�IE����~Bs����2^}2/��^��a���L��-�;�i1��Mοˣ�#9�Q����)��L�&�������y��(�fή��-�KU��%��Vj��d�������>41�tF\Su��~�)|�MM�ZJ��kGlud4�w`�
��(��W|�T&�]a��.�뼔�N)e|�>��]䡤w��]5'���AY��鹎���tӒ�( ��Ȃ�a�t�6R�1�7�|����Sm'�E\KI�v�6`u�H�끇�zÄ��k�x��M�A��f9-�[L)���å�ǎa2x�
9��qQ�fzR��g-��&�=M��j�FoEx�9bƅo�#}�	DIM�x��KpX���
��A��2�������S<l=XT��.R�}]�>�;�f��-��f�=� �� .+1l����Y~J���bK>�BpM �V������8g��q�����ӷ|�,i�������4�&�6�kǽ�)t�R�O��
�7�#��1�)��XUE�;�P�z�kY>p�����z�1�5ߔ�:S���e��p#�˛�zՕX�mqe>��,q1h�z����?%��_���D%�\S/�� ��v�]�D�Ec�~W��P��@�4P����0�z��y|�L]�\ܐ˳��a�\��X'�q���CW�y$����l�zsB�3�O�����5M.Z0/&@���)���	z�'nu �0\��ЄU���9���-���5O� m���|��a���v%�Fe�$"wEZ���1�I"�kW�O���3Ѻ!0�K��������SP�fiN!�h�'(�bh�;��p���'m�(C�w<�a��'h��w�{��E��d� �7aH����Q�9�~
�\=H�<Vs�/�`a�s��`D��6�n�*]O��%����ꦲ|�B����p@+]M�b�M���1���M���K�iH١I#ZT���N[�(/��nN���U۫!�t��4:��s��'&�R3&˫D��&d�[&��VM|,��:�A�|�S[�`ߣ�.ĕ}��ȫN2Zp0v�P_R�j�,�W�~��e��5�� ��]$�2���HND�^)��T@󢦅l���4���u�B�XPǐ���	�'<�huƸ��o	*M�i�Dj�|��R���#ĕ]P����:e���� ����+���7t�!���p(�h8�� 5V�-6���魖"�X���}��%�㷞1����"@�ʐ%P)�
 �y��A�TϘ\�v-�T�F�sX��Ԫ m�%��^�
VH*�����gؤ��~s�1�G�-�S��q���,��U��+L`����+U6x`��w����R-V���f�����+�V�@��&Q�@�jq���q'���=r�ﻗ����Yek+R�wx�\p�3�9�#���k�SC-UB'��1K���ZH��"�)�*n1M�IS���{���0h4�h<q���k��0H>I�R���H+�POtcTB��@��V��@_���%O)t���:M��p������Q^��*13e����	 5$N������A�+��3[ʹx*���K�=K.��D'j��ΕI�v���1���|78!H���b� �����ׯ��+�~���7.a�ʯ�o9 y�'�.���%u�j+:������+�'���k5�p�a#�)�P E#u%
���E�x%���&��D�J?&��D9�W��c=%��q%BP�@����?P�^����o�;�_�g���N#!�s�nr	�ڥ"v�����;�{������&7�"=��dt����m�wl�c�kGq7?m�"����l��)�K6��+�Կ�I�T�5�+��d�#�DT~#�r��ro�� ��+F�TH��@W��9#P~�<�������.vƾ���o��V�PA�rҗ�~��;oF�,`�p��	\LN&~�B?F����op
#�"�+�I����O^MȷI�y�d�����sy>�!�P[D�_� �� ����D(�x�>�2�
f��/����*ڑ�B�{����~���#�V*a8�b�2;ΰD�T�hc�@��R��ɬ�����������1����CH�g�cqo|>�x�J�C������V�mv$�Ь͓�ll��Ccrʔ�7��t��E��3��a�9�0Ōn��"�0�g� z����u� �E��Du^io�u�n �3���x�7�r�Dy�p��\�翞.�=��gYH���w�O�a�om����������xV~�v��%9f̦M�� ��^��r Uk��`�Ǟe���Ĩ�Έ&�_����֞7��m�=<��Kx Z�_m�/+�U�r`���;��6Xf�L��- m\��SS73�Sc��W|j��Z$ibk�����Ҋ|b��/���nu-?(��7<��>���D��bB�����W�N�,�ϦL՝K^W(��B�:���7��d��(>H4�7=�:���	����	:}`\T+B�uI�Y�������y��I��Z�[]�oj�Z��X�)V˕��<�1L�]*O0���Q�׳��ǡsc����'��xO����Sڕ���o��k�K�m$z�{�*sv����)�r^W\���7j@�ybT1%C'�!z������W�0H���0�s��a3�yF&C�z?H&�5&)�����h������l-R��ͽ���+��0�{�xn
���V�@ؿc VD�p\���p?F��
��m)3�{@ rm,�c�K�7?�W�g�$,�|{uL^)3����3�W6f��͋笙�ފG��y1���n�2���뀾f��U��p<r��K<�j�p��sA*�
�Y�1faY��L��Prw&���-�2A#���<	��I�G AR�F�� �a���y�JQ~�/�2�����r����V}�`��d��Υ���U��e�u`�3pܺ1�� C2����|7H�xR4o ��8ϭ��mI�P/yB~@�0���Ŷ˓{��mraq�n����w��� (���w7��N�������������R�e}U��
Ҹ��o� ���j�.|�vc (``w��,۱����u��܄!=5�b��x���E>Cý�hu=��}�3����E�9�P�]�W{M�$t��p���Ц�Ҙܚ���ܜ�ep��>h�!��H@�y�1��S�>�������K�ϣ<���ϟ<90:��� W����O��	�����d���D�����u$˟�����@fq`x>���ʐ��6f�����G���_�f�A�\>�Oh�]��>��������r�?��_]\�����������?���)Ǽ2+x�UX$&<ڮ�CU|�f��M%��n���UL����T3+w2T0��^$5�N��������ނ�Tg}���Ϸ��2�����.��c<�`�u̸���e�����0^Ţ�O�o�,��1�0b��꘵���m`�-��[^��Gy"QbR�����N�����x�p=��c��߮�lR�oo/���<�pL���������I��4�:ʓ����&�����t�)�?������1��ǥˬ��ⲭ ���e����ү?q�q;�UUE$�W���O��GQ�1*�x�A;{�1�2~��]���"�+FW�Q�#�� fOL�`kb8�����Hb��E�����������v��<��(Oj��9�1e������Nu9�?ʳ<��؇>~��=���H�fw�w9�!�G<��J�R~��a�Q���1x��"���"�5f�H�#^%��ؠ��E��Kz�Xߦ��~�˗�ۥ��}��qϻ�)���Vl��z�tg9�?Ƴ�������=A@|��c���^Aa��M�rp�.ƃ���oE`��|����o� ��b��_�'b�&��+9X�g/^����U�᷐�{n;}��Yp{�̎'s��~]�,�|]�Xvǥ�%��#by����������^��;�=i�O?�
���Q�Z%J��J��>���s�ß�r]�\꘦�mË������;�������m��k������sW���f]�挅��3jgX;�1E;%~]�S��b�ζ��k�)����Q�)-F ~��1����<�b�(Z���
t���l0�Ӆ�zm��8��y}*�4�PE{�� ��Rj�(��. �k�e�aZx����'���|�5�Fxi���ื�A	Ý�0���y��>��B?�/fV����7%�xM���|�#���h�����ũK�yɄ
�;Cg��<~M��k�iWH�Yk��Ӫ�4*PōS��&�����!;	=A��(�c}�� �'��Y�
�;b�%V�I��D�+=[�K[�x?�s�q�q�xgޢ x�Q����췹 �G62o�����=NE觞�gxqX4�e�
��>sz32��F�����E�/q �q�X��A���Ň%��V�=|�d��bx&DU��!��{����|��Y�*�sF��uN�
𲻆�=���_�D�*�I���D]\sׇ�o�A��=���I�p�uL����/�����������m��;l�Ϝ�m �ȼ#"U�A��e޾l�N�v�gڭ�W'{�ߝ�:n6N[��{����x̑��c<�_�0�|�Ȗ�"�Ի>�XǴ�����D���;�����e_�6��g�籹��Ad���p�Ӵ�ύ��y�3�F߇�1����������������Q���G��$�h�4-�޲7�l��3��?Il�XP2�-�4CM������T�s�	?k��c�� ��~t�:l�ς�����JY��S�\���z��>�M=�.����H���)%�Q����'/�P�59kK ɖ���i(r�W\��]Ą��1��{s3���S�^�{�g�E;ꯥ�����VS\���9)o6I��hA�~�]�.��۩�����8n/���X��q�qO�3���g�������C��u�;��$���?ǋGj�v���cӁ�:2�|'ȟ[4-��|���Y>�g�,��|���Y>�g�,�9<��[Z4 � 