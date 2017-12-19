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
� ��8Z �}]w9���q�s���!9瞜KqV�V���g�]Z�=���e�ε��-�%����v7%kl��C��c��������RU ��� )��=3���n�P(
�B�pfٕ'������&�������W$V[�Wk���j���������Јa�x��*�cN���ϧ|�����3�g�?���������_��ܪc�����ՍM������V} \b�W��K�� �� ��J�K ���o������֕ѷ<�z�ƞM<�6=���+s�G��߲�d<v\��<kw�P�k��kZ���g��7k���f����N..�X���2ݡa���12�<5�6��ck�W|���a�Cs�-��^�y���л?�� �3�ҝ���{������?���o~X��?�,���Y��"?�lGw�x&��x�u{�5�����̲�iv�d����k�������p|ӓ؜�=~��ް�g�ٹ�2Ӿ�\ǦN��8���j��j�Dx�C�Bml��c�Q�\@��R��)案7ޭ@�=p���4�Z+W�)�L����خm��1dW��d�<�z�V�<�2O��#H!�!0�	�0�c3�9Z~��Yb;P�3�~2|@�S����4�_�O�ON����Q���8�ʎ{��%:v���x�\��d�W�pbz�Рܫ�qw��	��k���:�f���e'��LK�����dC炝[���M, ��a���?o�u�x�� �h�������;��
r�r�������i{���srx�C3_�G�<�|���>hn+z�r���uOZ�'��wZ��q3OO(��j����[��s8��-Ҙe��|n����j��;�nx��k��,������q��S9��{��{>�{�T���bG߹����s��>Dek���C�gXp��NSӫ���]�����C���E;�Mip岒ž�ѽ{ <q��y�Jm��������>��~�����Oٻ�J+���*g+>N#���)��UR񄑒R�M*���K�~\s<�z$�R (��d�+d���Ͷ�=�$ؾaCk�p��{o�X�"Y�R:�-��LB|JN*��\�x�	������<�u�����-+]����}�󻝓����ݲ�?�|���~K��!̵2_D�%��2zn�ns����>g,.�|kD
�h�PC���R�}�v��<�I��Uc�6�	)��k\�4[��}��L���i�y$'P��v%C f�̶@'�I�w����IX�����~��h�&�>�%,���~(}5*}�?����W�������*E��Ӌ�3
����Q�៰V��|^Ͱʿk�	I2=���<Mh���y�dB��U���R����C��p��G�4Y�P�cPRW���`Hɟ��:�����{����K������,D+�rf�[8��Uii��}�6�i����iR��0�'#9?�B>"R�P)bQ�M�db����� �Ѭ�/Ay�"���8�^-s.JW�icڳ*�jJv�����d;���2{K�f���M���^Lp��Yׄ�5�=�E��A��*��V!��ڋ��ߜ	_�JHm M�v|�T�3ZB����2�
�[;{�@�9}��F��Y+�z<�'��K�ʰ��=j��fA�q&�>A�Io�W|�.��w 3t�>{[���!�G�,�T���loׁپ����0���ߘY��@!D�OZ�^|fkxq�]wbۨ��P��[W������P�gAݷ<�4����r�<��h��@T5ض�E��О�)Zm�B�X(�!	��6�'�c��8�#MѪ �hy��M)�)^��
����
qˆ�#��R���bd��G4�]�m0���1:�0��L��Ҿ��k�7=E�+afi(��	�cs�\�Zm�B��|P4TNܑ����7�*�d8T'|�gN���/Ƃ��!����>��y ����\`�sqa����"�q�EW[8��1[T��(_N�W�ee��+�-�r�Pq�>�8�貏��oX���"��Z�BmX���b�ΕYa��M8����{��QǺ�8'R��Ĳ='t94��O9�[�n�A�e���BeP�J����_P�a��-v�5�+6��+i.��.5�Bem�#Ŏ�9N8��aYn߰>�ƭp��c���Q��Z:�����NAp�"C��N����d�	hU6�Ӄ͔��׽p�]��3��ˏ]�Nhb6"�ǆ��݉�;Di6���Ə�N�Em/X~pEި�,�%��U�{U����7���oTFF6=<Ҽ��6��v��?��i,%�[dǝ��ݝ�	�cXu�:W&C��ll�VՉ��B���ۇ2#&�"$�mѱ����n��	�3{ư"v빔ȳ�ZH	��#F�ok9�����C]R*��� LĮ3�G�� �
H��&�� �P���I�����p�2RNz��;E���L�?�$qm��0O��r�"	��F)�h��%p�,�� �G�ۢ!��L�Sd<��Yhc=�9b�(1[*� e#�_��s"g�ķmK�e?���)� �}�}�:c��-�CL��Qؐ���_�mb����`����Tsq86��~w.ߨi��b�6`A|�����r���~��]�زW�s�R�,�|�~t`rzf�.!/�ms��h2��1� ��C �r����F���>�хʇ�o��[��*�ަ�q��
��"WC��b�D��OB�`��Kbs�k�W��A��}�r�
��ǖcY�֣���.J��,K���F/]�U������pA62�O|!�å����v����N.V�>Xb��z���C�X1�/��΋݃��f��]z+���3�����L�ڷ|A���=��+���������:�z��2ֲ��i�}�F����o�/
8�o�-n|�%	��{�	Wm��>��w6k1]~vŻ�FT��>+~���j揧��e����!% �RFT����0b3���#8�u���BK,;s�"{Y���V{�@�zRg1�?��9���ܕ�W�s�֤�nM4[ߣW7���'z���։
����㡑�V0�-�h~A��׷�o�
�~���!���Df��קo]o�5����[��zt������ԓ���.\���w}�J���k{�^���o����>F��?��o0�~)���	ԀIRnϨS��Kw����?��om=Zв}��O@���[`�C@���Y�7�6aѻ�u�e;/���n�����+r�}D�oad�Op፹�v��҈}��0���e�S�u�w֍���M�)�RJǚ��7�!+��♏��Ȳ�G6�e��l�#���
����S�r��N|�������}U���9�
3��_�_d��j���Kw ���-s���]�s ��_��؃��V�Cnz���Mq�AF�TX�z���M�^��Z�-�\̿o!�{�x/!�"}� ���*���f8��Y�]$R0b�Qf��Ɏ�`Z�zl��\W�����v��أ3
6|v��'NZϚ�29N�v��y�=���򟗖�#G{0����(��"A�׭���5!D��B�{���8�A�83�)}�!���I붲��&�R[x��	�R�)�@��-�椽�wb4 :i�BB,��V^}[y��"��B�m��\��.���]���NgE��_O<s[�����
����˖ז�Wb��'Al�ĹeG:(x�wF�o	�[[ ���gLߔ�,O�c.-Ϗ 8c�+����q����)lo
�лP�B@^p�IY&��A�5��Gf���>�3��ǽ(;�9�=��+��,Җ;�B��RoQ_���K�^�
 M�k�s&n�Tu�rȢ��J���g]�+��^l���9%�s/�%+��S�?�SR{�X�Khh��#4�q/S~�*���AY�rk�E�<�|��f%�[��=v�K�~%�Z�t��7ogCþl�{�\�I$,)z��*̢n�{C����г�&�fio��\�Y��ͯ��Wb *�a�
<u+F��s�����Odgܞ��r�^�޽��)�!�9n��:b��s���B]_,�vn+bi؇�\*ϧFЉ|��cn.�$4�7K�=�CT�ȰȦP�m����ﾚ,�z	 �K_��5"E(���~#p��H��d��t��ʽ���B �(�H�ơ6�3/���2š���.�����8 �Y�#���q��g�gO��8�$.�%WV���jE]>$��ӻ}~�x����a�}
�my�5���Y�?a��;���������3XQ�.��5��|`,Q��i좳��g�m��'&y�P������Q����X���U(b׍�)� R$≩������1;I�Od�����n�o�����m���olf����2������_��'oЯ��s�������\����?�.!��C*
]W�"���l��\�.��G�3��4h?��j����.��n�'?a�^���� �(�gϸh:���?u:G͍���&�3мצyI���4�9�5ctl�K%�{<����{>4.2ڟ��ϾCV�����2�T�V�=�9��wNZ{�O�=��������f>�TG擛��f>��/�'w.���)7sʽ�S����N��3�p�3m�L��r�]t��/Б�oX�Q��n�>,�L���N��k�y��3f^������kTl���5����B>��ԏb�O���OWXl����!ZŕGe��2���z�Ȱ��v���a��#צy�l2��:�O_w::8Tl./����^;� k�0�m��w n�E*����G��p��*�BL+ž¥Dw"`=�bZ����z�cm�N���H�xV|;n�¬8q/�Ϊ��bH��&e���S�8u��/�9\�#�ۀ������G!����,8��2c\;Q�7�"�B���ulx�t%��
xdǓ;o��T
�[\��цyz��A�E)�4����*ʒ�N,�1���c�[a7΁� P/R2�����~��C����a�����2o���9{���M�A���w��E�.�qx�	5��PC�i��C"�.Ty��Ѯ!E��XjL�ॐx�&}7��itN���8Ԋx��m��i�,qP���x.�bQ˽�g;�l�鬗��9��#�vk�;xUNπ4��nZ��3죿�C]���O����g��'4Q\�h���<uI�N�I�n����8{g&��ڄsg���yQ�+H	HS7v�?r��e��wH�����L��[>̬R�t��ju����ߵ�����F�Uk�[�[����������ɿ|�d���.�)��ݓ��?u���<��3����1�E%����,�J��wO����ec<����� �k�������'O��=g@�xC���gE޿�y�s$/�0��]�o��俖��?b���?���k��h_f�nz�:�������Ft�o��g��1Rv����<��g?�q�N��9S^x�܈^'��y�S ��)�>�.�j��B��<>��q��Y�->7�Pξӻ4��"���O�G�3!ߟ���ݛEx�'C�3���ƙ ���z��re�:�x��Z=�/C�A�mӅ�#�잆A��>ޙ:v@Y安�E��~V���K�������h`��lVF�|:v�2��d 6��Cq�@��O�7�<��ȤW�Z��@�%߸ swko�t�e��p��>�2d�\G�GZ�B)�RiB�"�q�$�u�~}m���5́���+�j�aš���	��=��P ��Cҍޠ�k�nٚ0�N\qe���m���{���Id*�"#e��� ڭ@���0yF�W�7(N�Y u"VFV�?4��TA?�-��4�%xl�j��j�~ff��U:�]i}ӵ����:C��5!'�6�]�dx�߫DM�S�B!���.�Az��8
�E[�-_۔>a}�8ȟ>ș��2{�
����.���KR��CQQ!�L�d�1����\\�	����3/��{e�4�
|� p���mN�1�A��8 +Ú�g�p���Tapf�<��`R��L��s�@LEn��q�.$�g���"���96�J�p��d�',�
:c\���t	Tiw�J���C��L� _�<VT��[T�/^�P�,@u �Պ1�0��o�D)	(��yp�L<�B�Tǒ^���k�1̓��+G,�h��^.}�H�lw;�Ԡ�?L��=�?*����V�e�j9~�2��ɫE���=���pJ^|���F�p�n|�t	4���bR*C:���:��0�UQ�^��e�q|!Rv��ϾÞF���������A��A�=:`�l��foBhT�DP����N���r�'m�}�.׼s�&I��/���;dk8%nx�r����|rax�;�}\��N�G��s��|�����-�5��ˋ�E'�`���p��^uڧ8��U\ɂ{�\�-LK��3��rU2Tw�;���uM��K��&Y�|Hs�-�
<TG�'�uD%�P#��4{�����`e�M1R-��A%W�$u�8�e���}:4���4宲H�@�>;W�X%)s�8G�$ś7�-'������۬ (<�#�wwN�DcQ+9Nʲ�0���b���M8��1gиh�5�8=9B�j~���o��7"c�4��I�!���� ��OP�%�O�>�����>�
g�u�Xq�H�I@g�ޜ�މqJ���r�Du�Idu�)x5kU)�M^͢%�@^�p_�?~����si�vw^�/�-�ǈ�̉]�4��{�+���J�%��$iK��k!��ܭ�� 5����UC��N�*��>��jcxz���0��PLt�	:��%5?�)͋��:��
��+�hҬ�B�ݪ���q�R#�ǻ��K\V�!��F��"��	��c��[0b�ԏ-Di��2*&�O^�1��T/�eՋ����<�ų?�<z��CO��O*F:	���x�[�ǟ�	ޜ[�l+5���:x%���
;��4�{|*)�\*JN��T�����n��4��	���B���D�`O/_�!�$�d����iyLؿ�T�
�o֜��'�A��ث*���짱nTMe+n��/��[pj����BH�b�4�s�!��S*-`S��ra �����ڭ#v���)U`L�Ĭ]=��z���Ų��[=1;���8V\�E1Y�s;�>~��@���X�B^��,V�L��[ V�ڻJcNg��$�2)(vK7��ŤR��"o�%E )GN���ɴ����O�O(8�X�&��8�`Z��tg`+�ȴ��Ga��@^�P�`�6}徃�b������P���p�Z�N���W�ZՃ�������	]]��R
ӄoxM���d��D�ۤj�r+ae���Ga�):&�.�z���xc�[#U��`Ζ�� غ�g4�I&�����u1U�H�FE�������u�ͮ���S��?�8�n�0la����S{��O�$��&�B��Ӑ�@)������Nq�A}��D��HDJW�>2��;�����c4�!���t�/L���8���/��w�D�F��͖+���~Iι<��c�4W�*.T���`��{���E	t�M�ψ��G�SP�NQ	��=�x\dmb��j�>p��X���ዤ�e���]���q&.���jI
+��#���7/�HD�Ni�SZ�bۆ
�*:@��߀��M�/rB�����$��h�wk}+%/u���~����"�ӄUbF��S��J��"6����UW��KX%t���UJDױ����S�1�=���%u҃�둲aD������ �z�k09��.`�����v��ȱ��;� �\\��5�;6=�M���=}�LyP���B]�X��}ٚ�62��`��L���4��z s,
O�#�h�����cQ*0."�f�!ia+�I�2(�C9�!�h��keQ�D�=��>��ڄ�mec��@��� �[�,�2ԁ�X����'�ܪ�16[��*X�����^�M��|��%.��!ꆽ�:@�藀|� $��C Q	�ab�ǳP~��i�%�VƷ`�btʚ(�aE&>�U���d����p��Ϧs��;Q�|�wIW� 8t8���U�s�?���S��.B5��d
�O��s/�q��	!�4��z>(@2�<#�hI�x�8��s�ƥ���."�+ҫ��ۿ�*��u�M@�=�cZ�7a	K1��u��(R��ZR=Ԋl�Z�N�w(·�vO���h8>�����fC,�����J��������`2�Ml�]�$y=S	mcVBQ�rĀ���!�>�RS�=䆱�p���vEN���9� �/F�!����t7M�T���Y8���ĥ��������B�V[��ق�ƀ�)��~�1 �;o�D��Fˆb�lhF�F���m�1.��ɔ�SѽS�	G9�%�k^Y =���B�ZH�1�4'ش֑��H"i�{@?0�E~��o�鬐��AQ�A��$��+>?�����%g#h1��s���gḇc2�q�f�U�ǡ���=��F��O|Th�P�����k�g����^X�\:��/?[�����������|����R\�J��M�,����wT��h/G��'�/�<���Hp�6d]ch�Ĉ5"pn�A�x>��*��Q��Z^HH��\ȼT��#}jvI��2��s���!�X(2V��bs���k�X����D*8_���{?���u��&��|��.��̌��3��έ�M��ŗ�qH�Ս�.���b����X��z.b��$���Y�0^��\�olWk5?��O��b%ү<�O�tќ�Q}��₻���F�����N�a������m�o����z�������;��~�<�?P@������_�n�k��_��od��#-њ�.���B�v;P��:��?���C+����۷~����h<�=�
ȍ#:�j<Z�����:t �9�p���c2�������Yk�q�.�iN��4�hG�	�_a��]-8����`�h����7�z��C���k��q�lO�0o�;/��!��S8^M��q�D$� X>?�������"B�FC�=�?s��8t�]�zn��ے��i#���_c��_�L/&�a{��e�J�X��`�a�p	��,XJ�J��k*�(�r��iV�8`���7�p
v��j�juU�e����"(��c��lb�h�Y�z��*\�{�;�!����̲a}eB�I�Sh��Z0Ҝ5��]k�;��jB7�D���+g鞷0�f�v-�7m,�q�(�ύ~���ʞeO޳W�����7`�8�)�"������t�aGf��Fo-�f4=���]���~j�zޓA�c������X�.�]{2�tW���I�/R�V��~Zh1���,��Zf�q� %��RE!tj�䃱>bQ=�� ���� ���� ��k����_���0"X��`��+��Xi��@u�Z�T[?�m4�_76�&�q�^�������rM\J�m�kǦ7�' ��������w�i����TxJXA	�����oh��?��+a{���Z�,.2R��Y��w�)��Y�"4U����M�2��)����L��CUN�jVR̓\�^s#���G�\�!������HG� �G�<��>�1'UA���Y�
��X�]D�@�� lJ$KT,���s�}�P')"�e(��Y�HY��*EBjg~"����d��a+(�R���{C	�7����f�M!���?M�s�Gq'��˗��c�����s��� ��"��P�����D<�#�����
�2�+�����cx�5G!2diÕG(�O.��S�*[�z
?�-�r� s����&Z�3���/�pD���dU����Qf�f�P�F�s���r�^��Q_��|���99��/� v(w�\�S`���j
w%���<�Ԍ�2M.�mz��z(SY6�PIMP"�N+��d<��S��F6P��J�y��%���bMMg�n����%�Zr�r#X�q�7<�Cя��5/tY�F`��;dG�7wv��(��]���-�%f�R�{������+�� �9qM�)G�U��Y��[�����VGN3y�� �Ӭ`9��J���k�*��9nh�Ur�)��o�����?�@���p^�����G<5�=;��c\�~�k�(
 )3�`dX>�È�'G��#_�3p��Tۋ~��!�X=3��z���2�(�h8�<�iz���j��W��b�Ō�^�0\
(q&������AGPʢ7�8D2R!�<�h��� B���U4�8_`�����K8��5> $%5E�=�2@�/�a-�G�+���x��QC1����1��j���S�}U�>>5Jc���Q����qA��Kl[8|p{V���W�|�ͼ�>��8DY���Ғ�R�H��X�I��\��MpjUrP�E��^��:<��'WK���'ބ̀��
��"SL}��耍^�zꌌK��K�k�)�u�\���D��Zx�#���+1��\(�&�/��4�=�s'x~`���@ۯ
��m�C����a�R�N�ɫf����>�j���> �Q���W^����E��5�<[~�ʵ	��b���R�=tŇG�HJ��&A�7'tO9���o	����mrтy�dLp�`�o0c9Ao�ȭd|�k�_��
s�'c?�_�e�߷��������8,B�p���ΒWm��La"-c0ꘊ�$µ�֧dq��%�L�n�Lg���������<O{!��O��B��@�#���	���aN����aW�ؤe(���}�-�<�,���/�=G �g� A�,ݖ:G]�$�)(s� �X�17�d���ubw.kl���U�8�B�K@�#�me����=��+�V.:��Ŵ�&cK�{<  �2�wx`I`�e�&�iQuv�;-lE�<���u�*Tm���K��U�::�Z4��G�V<=��Rj�dy�(�ؔ�w��3Bժ�o�z}�,h��QcJb��{�X\�"M���$�cW��S�VM�e�2�/в�ܺ������Q��6ɩ���+E��
h^Դ�55,����粮T�QLt��Hq�SVo�;�<xPi�N#&�P���Ŝ��̮!��ꀲ�pN7�)�=FV��^��tH���I�8�'¡��@�V���2]�q����Lo���h�B-�kT-�����ɭ�'��T�݆J�_T ��+�j�z��J�kqfR42�ê��fVyh�,�}��T�BR�==4;�a�V{����L�5�pO=,���)ƥy�S��"W�4�! �W�l��J�?�����u�^��k��r;����6�5�t�4GM�V���:G!~�RZ��{D*?�/k������F���R��F?$s G4+45�:��Z��N�A�c�"����6uE�3�U�b��Ӧ.�3FA���0h�vh<u���k��0HO�Z)�HR�J8�����,p�5�,0P�'�@E�S
=T�N��$��d)F8���8�J %�i'r;�t@��"�|8�r��j���W3-^�
���R@ϒ�`�6�_�F�����se����gs�7�MVO���P��S���y=�`O�"�=�q	KW�9�䁚�i�����c<Z��C@t�&v\Gԏ�哹I���F
!L�Z H���
(42����g�5M����@��4`��('�*�{��D>�Z��^.����}����R�5F�x���	���>�5�p	���u��H`�.r��Dݱ�-��/�7�A�I�&�7���@>�h�@�ck��,X;�c_�d6�eEZ���%
@��g���$�R�Ě�]L2���D"���u��P`�7�}ǎ���[*��s��+pԜ(?\�Laƿ�Sx��!`!���ZeC��)H_���f	_7�px�p��D�dB�')A�뉨�ܑ-1�x�B���T��{�@�MVl��& ��'姝˳���E��	�Y� �ҿ��.���"}�e."�o^Ѕ��hG�
��_��ya����ʭ�4(@5���1�KTʫ��*{�yO~�BI���³��79Y<���C�
*����V��&$�Ь�_���&�,���)3�1��T/W��q�sF{aL1����"���w�`w}}]6`�q/*�:�����9�vJ �)�gw<����r�DIw?�W�ܬe�#E�Y���翪���m:��^��܂����f5;��i�7t��%9f̧MΙ ^a��`� Uk�Xc�&�e����x�Θ&�߲���V���E(�5�<��Q�=��o��׵�:{14|�̝\\��.�X?�.?{ �q=Z橡nf§��8�����s�H�$�V@)���+���  NVP�ӷ��ta������w@���	��rl^Y8;Ų�<�*Tw.y.\�����dxJ��xZ��[�� ���$��o$<N3'��qQ�u�%�f!|�F��:�}��j��-t;i�c�ru�s�4d�Y��G!�+}A���й�}�=�W���+��p�eX�n���v򇷃���
{�
�-˜��@�C�6�r�T\���C-b�<����xZJ�^4C4���w��W�0L���0�s��* �]��"_Cix-w����)�uJ�0;�y1����~1_��|{�8~���IދE2S t��l) ��;`���`��O��XG���ݓ��S��hSH�\8��g˩c�K��7?5��g�$,�|{�$��_2fpA�F�-����1�y�5��#�+R(�//�cr�׏��|�׼:���W���@n�r�`�炷Z.;�\�r٬ �����aj�`D(�{�s��������Sw�Nˤ�#� ).��� �_���JA���!���Z'�������#B2������ʫ��=g�Mc�;A�d0g�w��n��㯒�yC�ua��=h8�Uy5��w0�*���\��&(�Y�ޝn���w+N�6��k��@1~�P���msĕ�4����˹e�Is�l\J���e͘V*IK�Y��%�\��\*�.��P.�(�X�g7��}���w��BJi`�V1�&�ϋ|F�{#��{0�c�g�Z���}�D[>/w�b�G��J~�ݩS�B;TJc
+�gqzs��j���]Sx~���a���׷��߶7��?��x���@\��X$.�.�C]|�i�����n�vC��]����m�j��ҝU�r|��w�40tTo�i��8�ܘ7%s\l������������Hxh�������F���	�+?t�������1Rxb��꘷���M`���X�����H������}���}���kx�:������:���f6�%��q<@w��l����c�uT���jՍu����olmla���_�������(��^�KL�3�v��[c��T����W�m9|)"�����j��TU����Q�&c�v�#/��w�ߍ�q)�2t9���h���'ǓQ..�N&r�֯'���f�,=`J���:�>�o�k[���)5~��1�C���������2���v���:��I���0�0�+�c��V�U�71�)�W5�)o��Q6��Q�;ŌH}īD\�0�(�sIO�����Y?��j�2w�)y�Ҕ�u�u̘��7b�����v6�?F���l������3~�'����4/�7�|2� >�V�!��������V���
�Հ|"^����J>{�ro�/����3����O��;dv<�U��Z���70Ѓe�\:�n|>"V��k�kk�k[�"����qg�sp��R�*L��G�z�(�:/��� �F��=�4#\�B꘥�m��ݨm�A�ۦ��L�{���������k���\�ȏ �Y�3��Ϩ�a�ǔ���u�O���I:ۚ��a̎�ƦjdDu����v�<�J&���U��ha��K�i�K���x|@�O��y7�����y��HC�M��h��ե�Q0D}& �ה����tJ���*���+���2k�,0h��p��qoO���c\�3����ЅN�_�-i�Ž?Jpن�ݛ�����G�DgY�L�o%RA�S���	$w��vRy�� h}��{s�������gU�o�R��G��M�9@;�Cvz� /P
�a�|LO���#��2�%V�I��D�+=[�O[�x?�s��Y�x�ޠ x�S��5_�u� �G6r�������=e��ϵ���K�{#������l�	r��Y���tĕ3��PY0��_Upآ[���ݓ�K+��U��f�x��e+�v�ͳ=����U9�3��3��Up]q����O�&p%�W�NB��#�⚻9�}���r~�9�.)���1C�Cw����N��on�g�?%����=���mO �ȼ#"�5A���޼�t�ww�庝��ǻ'?��<j�N:��W���������#<��<7��b�Ȳ�)����1k���p��������z6�#Y��i��}
}�;�D�N����ҧ��7:~z3�?�ہ�gsc�?[��ϣ�����o4�L@o
�lǍ>k<�L~�O<�(���4GM�`��=MA��(~1� 5v������Q��=.j�o��u�O-r�K��2� 7���}�/�TM=3J:�h�cO^ܡ�kr֖@�-C?W�Ќ[�R�L�������vu�����2�(�Q-m<�l����`e�-P�Iy�H�F��k�������^��_ ����^���^�3�S��8Ž0l�'r�׿�L�!��&͝�Z������#5��;�� ���D�
����-����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R��4G����U� � 