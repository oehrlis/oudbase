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
    DoMsg "INFO : Usage, ${SCRIPT_NAME} [-hv] [-b <ORACLE_BASE>] "
    DoMsg "INFO :   [-i <ORACLE_INSTANCE_BASE>] [-m <ORACLE_HOME_BASE>] [-B <OUD_BACKUP_BASE>]"
    DoMsg "INFO : "
    DoMsg "INFO :   -h                          Usage (this message)"
    DoMsg "INFO :   -v                          enable verbose mode"
    DoMsg "INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This "
    DoMsg "INFO                                 directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$OUD_BASE)."
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
while getopts hvb:o:d:i:m:B:E: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
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
    export LOG_BASE=${OUD_LOCAL}/log
    export ETC_BASE=${OUD_LOCAL}/etc
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

# move the oud config to the OUD_DATE/etc folder
if [ ! "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    DoMsg "Move ${OUD_BASE}/local/etc to ${OUD_DATA}/etc"
    mv ${OUD_BASE}/local/etc/* ${OUD_DATA}/etc
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
� n( Z �}]s���&U���S�T�%8��H����]��sh���}]Q��޵����"gxg����N�!UyL^��/�o��$�`���Hyw�`�6gh4�F��h��N�%�j������ߧ��j}��+�m֫���N�Vc�g{��Wl{وa����*�kM��..�|�����s�w�?����K�cz�׷���P��7kۘ�Z��ܬ}ŪK�%�������*��?(<a��%����o����=��k�o���j�����c�>k[����,'`�g��x�z[{�L״.-ϲ��3}�b�o7�7��:{54��ܛ\^n���lyC��/�Csd<5�6��ck\O|�օ�#k�m��Z~����p��A �玠t�oa�}�v�si�_�r�� �[̀x����m�Id�x��7v}�Cz<ú=�,p٥�,f;�4�g1�Bf�̳���zn�BJ���KlNЏ>��F��o�ķ������\۞�P�B��I�Nߴ�P5|"�/�[�66��ߨT.!���S��Q��[�V ����n�X��o�ɞ2�@�0��؁mٵ�!!O�n�j�gG�i�)�4f��fv�^ �@C�%�2ۅJݑ�� b�^�>�`;z�>;9::=k6W>*O�r�&�ġg��e��8}l���(�6���0`o����Р�Iw��	�Yh���;��f���u���LO�w��ņ�%���9[ X ���n�Y|���~<��s�l����{�w|zv�:�4W֐��3l�Z*����N:��G'?4��`4.�˗{�P��G-�]E/n����������V�s�,��'��m�R�[{�9��ݕh̲��bᠵ��j�O:�nx���g4z�B����Y-�����^N�2�C���[��x�׾yi���Ǹlm��xh����)�Bbjz�v�KV�;|y���x'�X\{�l�g8���'w;�Y�͞��o����c�7��	����O���� �٩r���0���2�_�O)Ž�⽁ջ��ǳ�C�Gr)���(I��F�m���l۞��I����� �J�����+�%�݂	��$ħ�r��%�'��?��B�p����GxY�c�ˀU���p~w
���C�tZN�&v��|���gks���x�嫌�_؅����ԡu��˨���2/k���J���ν��ק0I־n�ߥ1!%�u�+��f���`p.ٹ��9m{ ����Ԯt��� 3�96�dQ;��A�n0���>)�+�;�;����������_��_�Ͼ����A��n���wJѓ��Ό�4�@�Ϩ���X�Vo��fX�ߵFJ��,��E#�Hr�]�5�P�Af��´�TGo�b�'`DE�)�,V6������t0a6R�?�/���f�㞰�j��}W��-�Њ��ٺ�N�eUZ�lm�u��lZ`�=�֦_�ӑ��xːϡ�T'T�X\tS6����,A9�5�(O�zB$�P�٫�p�E�
3mB{V�UM��w��l�m���$�d�ȝ8������Ⱦ��0�&4��x��z�P���[���pj/�{&|U+!�X4}��S}��h	y�zqǠ*x8i��wB���E�#zf�T��� k/�k������V�yם�!p'�_�a�4����5�����=*�DR�9��]f�_�_@ì�Z~kf�����>iz��ũw����"lB=w42\�3��}EEO��9����Y%�l����G#���9��q,.���-�j[Z��BY�pHh̶='=a��(4�ak�V`G�#��h����X�
<U �O�P����E����ߖb+�?����t�������Ն�f���Ε��8���^3KC�]B��8�X#��jj>�â�r�4��畾u]q&á:y��#<�<v�r1n�ȇ�� �Pr�r��Ņ�w[�����U]m���lqI�����+��i��z-\W^،Bܡ�}�q��e�>��߱r?�YEP��V�ڰ�}$
'Ő]0���J�h�)��-4��⣎u�qO�Xωe{A�rhЃ�r�)�<݀�����"eP�J���¿���~�{�VTlZ�cV�B�#:]jj��ڴG��s�p��²܁i?�ƭp��cV��U-�Z�P����NAp�"C��N����b�	hU���͔��׽p�]Z�;��ˏ=�Nhb6"�Ǧ��݉�;Di6����O�N�Cm/\~pEި�,�%��U�{]����7��nUFF6=:Ҽ��6��v��?��i,#�Wb'������)�XuJ:W�C��ll������Bi��eFB��HڢcQU�݂�	�3{�"v빔(����9G2����
����W� uH�`N�0{�H�����i+ �v�,A�C��&}�"b�t�H9%���a3M���č��<q�+�,�$�?�b�����½��� �|<~���d���"����B[�����SaL��8R;QS�\^9�e�w[��l���8n��h��c�[^`[>��8��ִ����0��Z�x������5�c�8��g����]0�)�nC>�w ��>��y�����e������TʕU���O.�P/���e{mn�M��=�mD�rAT�<x
��!@]z����;��Ω��ww�A������P ��D-1~:�3�6������ҵ�kX� �u�>Y���`�c��,b���ku��Q��&Z�I˗.Ȫq�KtpOJ�^�*�U��6(�+�z����~�uLu��T��-)�V>�b��z��#� X3o���Ϋ�Ï'�f�S~ˤ�����ޫã��.���w|U��ƍ��+�����{��+u|���*ֲ��y�}�F��l���x_p�߱;��H�z��8+�ڨuz}dA�l�
��.JvS��$uz}.Vf�,3��,�L���{ga�C� ���"�.�a�(�?�Gp�놞��)��Zv�<EF���#��[탽Cu�ɜ����v�ƒsWj_e�aZ���5�v���U�'>ѻ\��N�P�����w�q�XEs�����~�W��C�qH^߮�2���>}�z���.�Oߟ��XD����g���/w��"���[պ���ٮW���[��%���_��7p��_�j��(�g�������~c��Kr��m��N��	h=�l�{�[=��6��",z�|��ÿmg��z���Q}x��\x�_7�[Y�.�	W��sV�gJë�]v�;��n�}�l�l�N��Q:Ѽ��i�X���}d�G��>���,�}ds��GV���w����<s��=dg��}U�髺 ?�/�U������� k��Ms�_� ��@m�k��v��} ��||�[cKs�5�F����G���V7���heM�y2�'4���w�w�rYZ��B��~�.^\ 
���Q-��P���6��900�S�"��1#�2tNw���BX�cOXϳp5k���h���=:�`�gW{�����(%#��l������蚭���jt��So �5���\$��ur�.#�&��Q�x�Rڞ�%��&0e�b1Ĵ�:m�U���DTj�oѨ!�ZJ�!e� X�%Ԝ�׾�N�D'mQH������*�����;��X_���UVKQ��ETH񤋴�����Ң��oMckQ�<�
I�#C�@����*��JB�{�$�cݐ8��X��\����}��z���X���I�p�%��w�\���w�8�Cb��R8�y��Y�}$AW"@~x�IY&��Aϵ.�'f��V�>�3��׻4\���\�X@YF(m�? /T�)���e(����uס�d��|w��,Ug3"U�U�v'?�Z^T���C��)ќ{/Yy,�Y�����{'�]BC+����;���W�b�-�&^��3?�P�A�Y�aV��E��8 ���4�7P�nԑ�A�^������t��߯�I �F�^�
������t��젉nY�6�:�eV+����e��O%��Ƈ(�\���;34�����3��B��B����^�v��� �׎Z�
��=:8h��/D{�w�<��`.��P#�D>��,7�ow�薥��!*PlXd3�y�6o��|�￞��z	 �K_��5"�(���^~#pW��HÔpb���� �����ϕ-P�Q��	�Cm^g^���)d�C���]1Q'w�I�i@>��OV���F'T�2Ϟ�q�%HR
"	J��я���t��j>������Oz����e�-(0���~��u�fm���wo�P?e�olu簢�<<Yk��bh,Q�W��Eg�#Xe�$�O,���>��}y�ZU����%ԅ�P̮�S"A!�H�	S5!,f���q��"I�"O�_��s{s{3���m��g}k;��|���~!��p��V�?y��v�?�����o�ꎖ���	w	��>RQ�r��:dK�g�Yُ���Y�~�U����.��n��?c�^���� �(�g/�h:�[�?w:�ͭ���'�sм��uE��ʲ��5ctl�e�{<����{94/s�_�m��!���}iÆ�Ia*z���t:�����'�3��哛ǭ�}r���'7���}r˿$�ܹ\rs���)��r�n�t�͝i��˝isg�_�3��d�i���5:�p�`	@f�Tg��p�]dX��k4�1�ͽF�^�b{nN�Q�_
�p.�~s|�W|��� _��l�*�<*3��I�7��E�5}�cN�.�����+�)�p�y{������bsy],����XD��+q�T��/Z�~}|�� ��JϠR(ĴR�k\JPAt'��*��PH)�wQ;�f�$j����Q�w����,̊�R�
�*�YoR�=��ǩ;o�b=�S�%<���M�}�9|�W���ʂ��)3��s�{�*R+���&�GDQQ�/��Gv<��&\L�0��5�m��gW>�(���tU]EYZ߉�:F�u��2��90��JFxC����Ͻ�yhTQ�p9L#���/�v�_��Y���4$_n���h[��"�w�P��i�5�V1{<r���B��I��Q��̀��3_
��n2�wc��E�4*�cA�������ٞ�/R�=���r(�|�C�lg��?��R�<��pL�nM���P��t�M�>s�}�ׁ�c�k�4��)�!�b��,��&��p U���.��i:Iҍ����>2cg��d7��U�p�N@�_�.�����t)scG�� Wo�^��}���]m�	����̺�:����U�����Z�)��6�֞��ߏ�����_�ۯ�:0{���Q�&|�����:��+����7������%����,�&z�_@7��xhC����O������?��������v�)5i7
-�����m���V�����H���/s�#���5����):���,y�Qtr#~�h~
d�@��S }X]��8�)���y�����[n��}�wey�'D��!T��fB�?}x��&��O� � 'nح;n�%�������lt��q�?�{v`@�A�˃�#�잆A��>޹9v@� 垅�E��~V���K�������h`��f�h>{.����<�ͬ�P\j��`�3�/�&2镤�<D2<D)0/�����?�}�==:��'�Jɀ,����}[��9F�	e[��������z��e�9�70�v �L��
h���r��/$L
Lh�T�
B!0q`H7z�*jn��e�0:��mE��]���9f�'��؊��&c�h�U,�g���^Aߠ$gԉX���к1=K����Y��,��S�MKET��03����ҙ'�JsX��s͏Ge�)Jܬ	9��A캧ó�^%n�

�vIFp!�3t��Q�-ڪl���c��'�g����R��u���M(4>�2�Z�$5� :W"ɄNv@�[+�����ť�0D;�2.JI�W�K3t��'
 y����ȉ��0��y��v[�Mg6�s�	Lj7�w!�����M�:n܅$���0P�RS3Ǧ���_)���,����@�@g�+���.�*��X��E�X�Iu2^/I�w���_��J���i p����H�a#�<��#�=@%��(�q�ؽ���'�uA��E�j4���3v!pў�Ap˞�n(�����o%��t��eA�=rw����7!4*b�<,x��d�����vl~�޸�eH��c~a�����.�����{���z� �������va{~�����B�ؠ xB�y=��DdC+�-ɣn�M�}���c�;��(�0ʕ���=sDnyO7�֨'��tpΗ*(Iae�]� ��BT���#�@���
�$���J0�O*ܗ�kԻ�(�V�o1�`Rc��A�G�$ՠ$�!e��q�?σ�t�r/J�h���](�����y|Dc\���o���
srd�t{UΡ1�����>�U�J>u����"��ֵF��6Cń�`R4��Y�?A�Us��<B3VF1��p���g�tA#B��X��l1Ew���&{>�;6�	��
g�Y���(�MB:���̯�N�Sڝ�������E*è�o�H��U��69����y!��})��1��7�e���y�s�l�<F��4�fu�4�@�I��a�����'&��iҖ(��B$ӹ[�j2����}��Y�)V#���܂I�G鱡��Mx&�D-��)�Li^��?�;��/����*��g	ǟ~��R��
$�0�ߔ��O}&Bu�D΁1��/1�#���x�i-�a{Uu�^�/�k#��wjYt�և���/Bz	���x�;�ş��
�\�%�8R?���ɅD{��L�ýJY����hN��ъK�>FwP��h��X��!tnQ�~40�-�'^�*�d49=���i.�G���1i$�,S|�{.k+=J����Zy�}@��RadGʨ����ϫԳ�[���S@cH�D���Od;�v���-r�M�Ja���'�W�("3�t��쿅GBP��d�L�L��G��cھ����G���p�1�m7�ld�8����O��T�չ̣2�x�(��!U��b՞&Iy��<��D�3݁��Ѯ����E�4��Ѿc¦ZS�o�4p������6#`c�v�V�q��.ת>����m���;�?`�_Hi{��� ��-q]���W+����><�)Gp�㛿g�I�r)V ����>�nq�s��� ]�j�%��-��"v⍱�K_��U���*ˆ,��#���9h*e���Dr���t�rg	���$�w�� \י�5����Z�\�gk��ޫfv�rM���G yk�CH���������z/;l�B�)'��C
��C�Be���xU����_�]\���a9t僐i�0O��D}���{:a����0�j�.�:���S��EQ��[ជ�[w��Ѣ��'r|�Т�^;�[���y:�EF�4��	�3�9�Q.nA*���\��ͷ���=�|������	���6��1�@FcG��rak)�g�멌ŔR"�jі,�|�%�fQ���-)�%w|�X�,�Z���+�5��5{V����a�޽�s𫾄�]]C�]N+��)���B�]w4r�cӃ	H+W �{C�N,Fj�:zODx?�A���J]��D��z3J;.�Ao��F���xD1`=6�l�P4Y�09I� m
�K#��s�~�lͳ(V�R8��
`!շ=~X?z��DPz������X�Ï�op!&�U��X�Ք�QX�<�3[�$��'NNJr�,��K�2U�D0L~�/�Wi�G����	���G:���\ ��KH�`�O�!����N� �(��L�4��L���g�y���!�:��xp>�u�J����nL�/�l:�I<��?�{Wt� �C/<(;�<�N0QG�CQ��;��$�btP3K�;�>N��g1�n�'b��|T�4d�P�]�2�/��nq���`mR-�ssxE��py�/�K`�	m��� ����e�\�L2V�a�$�%��VK�-�j�c�hN�Y1��DL�����<�i&�����n�!��JNRbB�GQ�B�={�,���ؤ�jK�4W@:W�mII(�\�-��5��%r~-�L����b)ۘ�i���H��(��b�j:h�5e5���$�D���簐>���)��k*�C ъ��+������8�VC���驡���
~�(bt
1@�[�gO��;�+6�Ϻ�a�ʑ�B�6q�'��!�{c�����Y$`B���B.w�
CX�]X����Nǭ�$�S>�������81��#��d�xP�R�.PL}N[s�y8	�;�tj�\%�s��42�\�Bˆ��,sK���,T��Q@da���$��"	|l��k���IH:����V���J�&kR��[-�x��#����tt�BMq -� ��9�AR$�O� i2��ב�_%P�,/}��;ž�.��H��]�>�@�J���h�F�|Ȥ��ձ�V��rt�O*!kH��Jb��o�F�!Hs�9~����(���I-,3c{��6���,�m���R}������y���閵ȿF�0ZĢ�Fl?,��Y�_0^��Y�o�Tk5?�[�_��b%��x������:�������V�����no�����������/��y�?F��?����c��K���tk+3�Ou�^���&����<FzB:e���R���M�p+��_����5�O}���?˽_{4��ߧr��NjF
?�-�71����e�8�@�njc��=sl�k1���@si�T�As�&��0�	6+9�ӂ#��n&���x�Z�	��n�;�	q,t�g�7��C�ݧp�����p�H*a�d�~�����b�k�������{�5]:iCW�]X��z�Fƶ$�Fgڳju6��7(ӫ	t��z���Ab��	2�	.�Є�YZ+��w-�F��.�f��tx�=б����@&��,<ΊACD�!.`��G{�b�iP��h]�ޤ�4 H��sہ�&�O�iRj�HC���t��n���	��"���y��p.��Ƴ��r� �e�|7�aF�+��3������߀�ئ�:�T`�@h*wb��s˃�ۘ����M������J7�7��E�s�'��ǹ�g9:j�pX>AK�d�(����	_&����q���2�q=Y��`oq� %ҾREtj�	䃱>bQ=�� ���� d���G ��k���k�^߷�cD�Z��X�W���򠀁�ʵZ��yV�jԿilC޴ڽ�)Eû��FM\J�m�kg�7ʦ ��ʾ����3�H���l*<%찄f|��F�7��E�_��_����O�h)ن)�F��,pɻmÔvS�h1����XE�~��p�#�#/�3x��)U�J���Kӏ�G�B3��ʞ�5���Ґ5���/����*�bZ9)����%A���xR��E� F��2"��b���{`�"H���")��"D��b�+'*J;�#��i&��[A����,��J���u��6�n
��d�iz�S?F�<��q���`�(��9��`��B��x(��uy���|�s~Q������b��nĂ�B�Q��"�p�J��K�㔶�֤���m
|��!Ȝ�!��� �;��@�������� ��i�Ei,:�,��o��Ϟ��_�gNμ�k*�
��7�������]� �1� 5����&b�ݯ��N�� T�@�tӊ�")O58ܔ檑�B�e��t^��_��a���L��-�;�1��IJϿ��Շ#9�Q�F�+(��\�&�Eޙ���r��(��ή���OUӺ%��V�?\�����v�q�٪ �T�qD�_�������7�kWlu4�w`�
V�(�Wr�O��;������y� �R)L?|�S䩼��}5'�=�W���^zn�q}�Y��8 ��؆�atN V�1�?�}����Sm/�E\KA��6`��X����������k�x��M���]CNK�3
+rz-�p��9	�L&&�S%#�0Do��Fd82�y.�ݭ�"�H�A#��Q�~`��yXἄ�H_�BQRS4�,C����ts�@>yzJėE����Va��B�����uU�xh(��3��l�3 ۂB�)���p��������E�ͼ︨;��<�}]2�Γ'�0�"�[^o`Y�
��ṝui�AMm�7�w�S�r�j�\-ZohG��2�9oć+���L1�Q��1:���+32�,�~�N)���\�Yr]7��R��]^�֫�Ġ���[t�`�b�X�Yϛ���?
��_���D%�\S7�Q�N�K�ɯe����>�xO�����y����ɕW:u4t�inC.�6�煏�rcb�k�d��$�
�� �R&�I��)�c
�x��X���-�_@��	�)�3)z�'nu �0\��ЄU��]	���-�<޺/N��6�WX���U�GK;[^��J�$���ZZ�1�I"�kW�O��L�Kޙhݐ�΂������O��B�Q�h��4'�G4tKi12�ÆjO�ë��I:�P��]�M}�-�<�$���7ؾ+��3d� d]��C!���`���z��y�愣Y:���|wnjl���U�$�B�KA��me����=��+рV]��b�M���=�����\=�iD١IcZT���N[�(/��
7��W%���Րt��	��GZ�����{���\�̘.�R����~�xF�Z5�m��^�=[�<�cܘ�����6!����W�f��`���>>�jմi�ס~��e%�J#D/aɢLmc:�S�ùW�69м�i!��|MaA�a]�:�1���4!�����w0y�߰�T�FLT�v��q�9! ��� F\��!e��8n�SV{���;>9�r �|C7��
q�N����@�V·�2]�q���8Lo���h�B-�T-�������'��T�օJ�_T ��+�j�z��J�kfR46�����fVyh�,�}�U�`��2�z�e>æ���{/��p?jb�z,"�磧��AOͮ�t\a� D �^���+���T.F7��Q7jƦQŎ����w�"+](�Q��ՠ@���($���jwe�{v��S��f|cT�j[[�2�;���̡Ѭ��\��j�:e-�Y����B��3@��Wq�I/L����E��/ }t��;L���ц�w�埇Av�$�J�8G�:Vʁ��ƨ��d����g��?�*�R���u��� �K1¡�<&�U��L�+ק jH�y��ٕ��Q�}w��i�&R��D�B��\����
N����k�t�t=�c���~:�z8Zǆ���H�j,TM����u �J��H��,]y�g~ؓ�GZR�r��Q�����h=.��С�āQ?�O�&�&�'j�0Ej! q�|*���0L��W�41(Z6f �Ӏ�^L��ȫhY��j�3s���3��J����}���v'\����64v�i$�s�Ko#�U�TD��Ut'z/�0r����Q�'ٚ�� |0і�x'�>��۰vp%.�$�p��l�I�BK6��k�ҿ�I�eT�5�+��d
L3�DT~#�r���/��	�b�pK�t~4u.�Zs�Ǜ#�,����`
�b��3��2� ��@�l� }5�h��ĝ7��*�k�.���L�$�"~�`}-�;���쎮A�׶�	�a�W_^Fʷi���d�����sy>�D����V�"A<+��[�����Ť4^�Ͻ�E����Wt!�*ڑ�B�{�W��~M^�:��cC����&�:&A�J��R�PXg?v>���%�GP��}��%,�O�G6��Bo�Q��JD�}���Ux�*4k�W}6q�?��59e��Lz:Ս��~���f�3��ڊ(�̀=C� ����$���]VDu~eo�s���s���y�7�r�DI�?�W�ޮ��#��Y�R���_�<��_߬�lm��/�7?��I��~���ߗv���
��K��޿�k�u�y��!u�OY�� OKRq{���}KKڅ���ޓ�/���ݾ�C��	��޴N�o0�����A�������n*��X���lU�����wї��:�j1��d��F�R2��������ԼJ�a60��E9�s�V���jL�J�k���_�K1�3j��A͋!�m/'���Z���{'�k��M�~"����d��  ��	 Oą׸�[?�~�b��u�g@qѦ���h�	��n�R���nn���2IX���$��D.apA�Fy-�>���y�{.G��LP|[^��jO�l��f5�:��Eu8����́ܬ�����o�\8v���-�
��!�	f�`���L�Pr�����-�2A#���<��I�G(ABR ���l�u�i�!�9Ld��Ly��h��>3ց5{�����$p��`���0���_�A�";�ѕu�ݠ��0O�}��fsUڎ��vuz�T�=-*nݯ8YΔ�5� ŖA��#2�I׶�\��S/ԕy&�U2Y)�^5W5�X�,c�6d|��$AU;r�x s[C@����>dŞӌ���W��
阡Z�ğ��,2�p�ޭD���h
m�_�6h�G,RL��2���k���B(�7�� 
m8)�YY�?Kӛ�z_�T�����K˫c����Y߉�����?��x���@\��X,-�.�C]|������n�vK�������m�ڐ{)���.b�i�e/�9��׹�fޔ~�q�u��I������|�?F�C�ˮ�s������,?�y�e��Y�;y�?F�N�.��y��^�آ���|�?J�E	XJ���;�z�����p˩c��߮�lR�oo���QR"����ߪ���㤌���:}�W�n�B���-����6w���c�'L�KTx�^�kD�3�N��R��L���녷o����P^�|O�G{��wEQƨp�1m��̑_(�[����
�q1x\��^�v�zQ!�'�8�d�4��i))=~�b����]���?<Jʌ��:f�����ߩ����1R����N��Zg�}) �����|w�{�c;�֌Z�QpSØ�xU#�b���E`��E�S���G�Jă�A#��!�W��;��M��3��V�
w�z�7��±.�����Vb��z�4_�?J���|�������s~�'���Ʋ����b2� >�V�!��������V��[��Հ|"^������{�z�/����s�������2;�̪?�}����M�`;=���_��Ս����������"����I�sx���PU�^���:Qr}^���܏`_z�RiF����1K�ۆ���U۩���C��������������\��^���,�Y�3��/��a�ǔ���u�O�֌4�mCW�0fGLcS52	��c -� ~��1����<5��_-L~y:�bxiw�����=�6�p����>�Zk����r��(���
����@��R}R�g��;_ũ�ze��d�����o�Kυ��4(Q��1�u>�.�ޏ	]�dFቖ[����mh��I�e�q�x�Kt���Vbt8u	>/�RAzg�l#�ϯ	���-�7��?o-}Q|V5��.��qd*p�ĝ�;�?d7�'���vl�����a0>���:bG,# �b%�Y0��ITXq��Z}������@W�Ļ�#
��%�\��~�yd���t��X��a@?]ZA����_�B.�/�ގ�&������Mq��+�MW\9Sx�a���8~�U�-���}����	Q��`����_�Bl��:�w/�^�Á��πuN�ܱ
�+.�>��I��D�*�I���D]\s7G�a`��A�/=��'e���:f������Aw������ǣ�;���;�'t�*2�HeM�@��_u;'{�����듽��^�[���ٛ������y��1��l^�C�^dyZFʼ�m�u���6�����tg3���l��rp�>�>O̝�"C'��KM�����i����c��g{'��lS�������ϣ�����Ro4�M@�7EQ��F���$?��'��kJg�e���v����)(�e�o����X�!H� hw�ݳ��f1���JQ7��b׺���%�rSO����eb���gFIw/xbᙋ{�,��H�e��j�qK�B�������کn�s��1R�G;��_��V[\�캅�9)oI�jA��V=�
} a����ȇ��z��~����zCx N�.M���\��/0�p�=�Is����9��d�XM�ᮼ�3�|l�0QgB���K��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S��<�)Oy�S���?��� � 