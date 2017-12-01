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
    mv ${ORACLE_BASE}/local/etc/* ${OUD_DATA}/etc
fi

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
� ��!Z �}]w9���q�s���!9瞜KkV�V��d�pL��"�Ѯ��(�;��j[dK����nJ��ړ�����5��M��7��� t�AR){f3���@�P(
�B�Բˏ�*����&���+���H��^�Tk[�j���͍'����4�|�T<ǜ����M�.���3I���θw���^��/����_��|�E�_[�nb�Juc}���U�K,�����o������=f��%���ӫ����=v�K�gy��r�={�mzk����M�g�e��h�>[y���L�0�M״<�5<�d�o�����{90|������Ε��d�����}ch�x�3m������;�����3�ff�Xl�1���]ɡw��J]g��=�J/����7�s������e�a�j������g9v,�����ݑ��s�����g���M��o2ˆ��]��2�c��m�uz&R��MObs܇~�8�54,{p�ƞ�cg��L��r�::��}v��U����}�
�!��z�|9ǧH�2���"Xܜ{�y���U�{]��J�T��3��H�vl˷��4]$#��J�*�ْy��A
!�M����9g�)���g�mC��������@ϙh��j����K��z1l���+9�y��h�=l���������g������Ѡ���Qg�`���k4���F���U;�fL��w�Ӂ��9;���1� X ��N��������)A6����>�9<>�o�K+��6��T)��OZ;G��ャ��?��勝]�}飖᦬/--�s��������f�}����'��m�R�[y�9���h̲��|n����l��ڝNx���k��,u������Q��S9��=����]d��07��w&�b�<��\)��Q�ڲ������\;�S��������y�,�����y�k�N~[�_��h��8�w��'����X�Ş��k�����C�W��{����O���b?�٩r����0���R�_&O))�ݤ�ݾٽ���5G�Kr)���0I��D�����hY���I��6��M�H������+�%)�c݂	��$ħ�r��9�'��?��D�p��Yg�-��ް��*���8��9���i�M���c����>�n�9��V�H���F�Ϭ�Mn�s]�����e�oIa�5ԉ�+��Gj����c�$�_�Wo����ƅ�@�u�a0���Ԅz��]��@rujW2`FP���lt����� |�LnA�������O���ab�Z�����W��W������W���/|��R��(��=�0�.P���k������������d!�3���ӄ�|�g&Ԁ�`�Y��0)/���;�?�	� Q�}�M�e<%�q5L�������3?x���'���� ��k�Ѫ�m�B�"/��.����iY���[�sl3.���mϞ%���~2��o�9�ꄀJ��n���#� �@0~��(G�&��IPO��*�� {�̹(]a��iϪ��*�A�B�64�m�C�K�,�ϙ1t�6i�{>�%�Wb\c��P�w��WR���Z��Vpj/�
s*|U+!�X4}��S=��h	y�|~à*x8jn����y�!zj�T���L� k/�K������Z�y�z�w��>_�a�4����1z������=�%��
n}j{;��m�8?���=�����m�
!:=�"��S[ËS�c�F�E؄��ph�:����<EEO��>��y�Yŵl��g�G#������M.���L�jKZ��BY�`Hh̶9#=a�)4�ai�V`G�#��h�H��H�2<�!�GQ�[6��E���7�"+�?���ʰm�y������ц�wS��+��v�l��}������&&�u��̡s	j��
5�A�P9q��ڳrϼ,���@�<P��9a;x17�K���} ��@ 9�I�����ʽ�I�Ef㪋��p��a����Q���+��i��Z5XW�Y��ܡ� }�q��e�>��߰b/�YEP��Z�ڰ�]$
'Ő�+���3�6��S$�[`�-DG� ��#H�������Р?�Sly���`��s|�
�A�+��������~�[�+�WlZ�#V�\�#:]�j��ڴK��s�p���²ܞa��ƭp��#���Q��Z:�����NAp�"��N����d�1hU6�Ӄ͔��׽p����3��ˏ\�Nhb6 �G���݉�;Diֿ�����v�Em/X~pEި�,�%��U�{Y����7����UFF6=8Ҽ����v��?��i,%�[`G��ݝ��1�cX�:W&C�N6�ƖVՉ��B���ۇ2#&�"$�mѱ����n��	�3�Ơ,v빔ȳ%���F2���Vs���ٗ�����T0'A��]g(D�`ӏA���F�M#�FI	�<�M1�:a����w��	��$�I��r]b�(���E��b>��{�K�^YL}	 �>�i���p2�FL����f���x�p��0�Ɍm�������Q.ω��"߻-���	Luol�Rh8�����L׷LхW�PakZ���ZmKl-d�]P����tΚ�ͱY�۳�FU�.�{��;�F���c�Mq���M�Ŗ�����ʌP�Gf��F���K���6"z9 ��<���.�T����W~g�Y�ۛ� Ӂ��Y�+ S��?�Hq|���a��%,m��:j��������X��h���R�(}k���Kd���%:�+%A7\��Ū�@_��p=c�jj��<��:�l�S�˖pK-�hh����n�Wl�y����ǣN#��.��e����v����Q{f�F�[��il�FL��������\�2
ץ�z�tkY~���>B�V����6o�/8�o��|�u	��{�Wm�:�>��w6�1�~zŻ�JT�:�>+�~���j�&o�e�3��!M �RFT����0b[���#8�uC���BK,;u�"����h����ξ:���bFoh�3Lc�+��R�0�Iiݚh��C�n��O�.���c1"�?)C�C=��`�V֜�n$�o���x}�A��7k��~;�M޿ެi�������E�<�����$���]�>����F�&��6k�
��V2��I���g���/��W8�0?��uv�~鮿_�����Vף-�w���X��=�̮uv�a�K>_��_�3�\=�o���>��"���M�FV��o�U�������jv��������y$2��S⥔�5/(�gX&���3���e��l�#�2��G6�"��a'x�4O��2�)�3_�[���ɏ�sxf~}�0�>���ݘ�ŗ� �� P[��w���s ��_�V��\�u��&7����뤸�!�bZZ�z���	M�^��Z�+���7��_���B�E�6AT!5Pl)��>p��D�H�`�����m!�8� ��c�uM\���>�iL�b��<(���Uƞ8n>o�+J�H�8����5w6�d�~�9����y&�z!>	2�i�ˈ�	!�D"޻����y�ǩL�;X1m5��7�U<6���[4lH���nHi2Vl	5#�o���I�b�"��no��w�w+�w�bQZ]*����a��ET@񸋴�����Ҽ��gNbkQ�<�rq�CC�@w���2��
B��$�m^�8��H%]����}g�z���雒��I�`�Š��g����w�8�Cb�ഝR8�y��,�>��K! /8�,WF��g�3�p��W����㞗��J���`e�i��y�bW���/CYt�%`���ƣ5�9c�k�:[)dQE^%jw��H}/6�z��ι�Gҟ�O���9��Z�-�M������
��cPk�5�"^�x��J��
���-����9�ϥi��u��L:��۷�Ӂa_�߿_.�$� ���fA7�����]��~ݲ�7l�5��,�������1���0G�
���#Pڹ��w�h�'Kegܜ��p�^�޽��)�!�9n��:b��}���D]_,�v�o�bqЃ�\,�ϧFЉ|��Yn&��$4�-K�=�CT�ȰȦP�e\����/�z	 �J_��5"E(��^~#pW��H�sb��� �����ϥ -P�Q��	�Cm^{V���)d�C���]>V'w�I�i@>��GV���z;P�RϞ�q�%H\
"	J��Џ�U�|H4��w��t��]\ٝ�2����f/j~;^���c��9W�����W��SXQ�.��5{�|`,Q����Eg�#�E�$�M���>���}q�RQ����%ԅ�PĮ�S"A.�H�	S5!�g���b~�$�?��ǣ��������V׷�������>D��??��g0�~)���A�^��'%����7�ʖ�g��w	��RQ�r���gdK���� ���JӠ�<J+���6�샺��p�-z��;s�x�d�=���zd���n66nG �Oa@@�ޘ����@֌�u��/����G��"���8�<h��>{������$e�1�譲��}��k�7w3��;p�哛ŭ�|r���'7���|r�_�O�L.��Sn�{7�\��ŝr3g�	�2g�̙�g�L;�8�_�#�_���z{n�>,�L���N��k�y��3f^������kTl���5����B>��ԏb�O���OWXl����ZŕGe��2���z�Ȱ��v���a��#W�y�l2����oN޴��?Pl.����n+� k�0�Mq�#� �
T�ys���O:m�<^�	T
��V�}�K	*��D�zXŤ�!
	��.j�ڌ�DՑ0<�"��f:0ܚ�Yq잋�UYŐ �Mʼ��}�8u��/�9\�#�ۀ��Ø��G!����,8��2c\;Q�7�"�B���Mlx�t%��
xdǓ;o��T
�\��ІYzv风�R(�iFwQ�U�%��X�c��m�>���n�cA�n�d�7t+��=��Fe���,��?�e�����,��S�&���p�m��G��Nj�;M���B��F�GC�1R��8�]C>�x�)��p��K!��M&�nd���De�q,��8���8���y⠾�S�LŢ�;;Ow&����Y/��3�G����w𪜮%hJݴ�1g�C�=��M�	��)�-2�O�Oh��
�P��Y�j�������!+��#3q��Lz3��	g�t��W��.�n��;~���-��\�o�>�������t�YR�d��Je�������
�+��'�J��� ����}�/=�3����$E�{����/����of�<>>⿨���?�!��_����ѣ =�d�F�40<�q-���#`�k��ѣ����F����%ހG�?B�Y���x��ɋ>̧s��=�����O����������0ڗ���T����֣�#�������G���s>���St�	����F�:���"N�T�@z���q"hSa�� ��E�ga���B9{N��tO� �s�?A��#̄|
��w��M�9�Ah�AN\�kg�vM\롛˥�Z����`u-��-�M����"���x�f��e}X��&���
�Y"�.�+�B�;����ӲY	E���u��J�����ĥ6| 	&?���n"�^Ij�$�C�|�����ݓ�W�ヽ����J��r:iQ
�țJ�	e[��������z��e�9��0�v �/�+�2h�e��r��/$H
Lh�D�
B0Q`H7z�*j��ek�0:v�mE��]���9��'�)[���&c�h�U,�����^Aߠ8�ԉXZ����2\S�b�'�X�������"������a�RV��v�1�M׆���ǣ��%nք��� vݓ�~�5�O�k9$#���8��(�mU�x|mS����4q�?[ș��2{�����.���KR��CQQ!�L�d�6����_�	���3/��{e�4�
|� p���MN�1�A��8 +ê�g�`���Papf�<�äve�0q�".,����D���]HB�E.54sl>����XɂOXn
tƸ@�����������E�TǣՂ�y���ſ,��˟� ��j!���Z!6���0�=B��T���b�����,|bXGt^\��z=_=c�2 ������Y������FP��L7�\��%�q;8�i~0�cB�,vȃ�����-ܯ?i�����.C�~�K)�p_]�$��w)��?8����[���6��G��3��|�����5����yE'� �o�Pu��ۭ���(^F�m�a��%@�Cr�{�q�F=a�਍s�TAI
+��rQd����i
<�T�'�uDU��}ZPY�t$X��UDu�"|�I����?J&��q(�����x�Ӕ{Q"E-��L�o�����#�G�h{��XW��#;�۫��p�����o�����V��(�����9������㢑���b�	���˥���2�Ř�,���>�0�:�\�d�	���t7��iޱ�N`�u�U8C��B]&F�l�hǅ7g~�wb��j�h��=V�-F�~#E�W�*����U�$�s���KpՎ�ݭy.��n�kw�y�������I��|�'�ΥR)�Xi����D�<I��w��d2wk��GMtB�6`��ϣ3�"��>��jc�r���0��(=t�	����&5?�	͋��:��
��+�hҬ�B�}p��K���EW q����E~�0��$r�tHoΈaA���M+��˪��2|�]٭�ˢC�>�T��h��H�,�G��r�,��>V���*�Ǒz�6�/$Z;G'��E�RO���w�,�I���=��N���K��Y�ܼ��h$`�[pO��U�	�pr�_���\(�p�cR�yY&��\V�Bzb%���b��J3��Ў�R_���W�g�m5�!J��Ɛ��l=��v���jY��䛘��$k���^QDf>j���s���J��(.�T�$��b�Ǵ}�9b�,1�U�`cH�N���<Q2+1���I)��s�GeT1pQ��}�Ū5I��ty��\g:}[�#�]�'&�\h~�uÄM���q�(h����~w`�!��k����8`_��~�U7�o���/�4���kf W�8���7Q��+�%KQ����#8����䉸D9+ 
��nS�8�9P� �.\5pct�[xU;����K_��U���
*͆,��-���9h"eJQ����c�1��
(M5���,�A��3#kpY�L�!�������!�����n�*��G��@����`g�*|Qe/&Dq�^��r�4RN�!��rl�&��Z��K�Ѳ�9g=��=;/��ô��!�pa���DX��t�h^5	a���Y`u����*o��-���=������Eݏ��ơE?½vܷ���t��6��iB�*g*sR��߀������{u��o��93�{��$!u�G��}�M O3b�Ǝd����RJ�D�S)�)�Dtբ-Y"��eKl͢䍮[-J���%�j�/��-�W\s��k���+e�0�;GU>��Wm�	��
��V�0R^���R��p�؇��V0�@l������u��>��~<҃^����<���>b��64�n�M�����Ϻ 4,���%�h�$`r����F�C�� ��يkR�r�p(�"�B�g���~�Z[���B7M��1�2��=_�BL�+��)ˣ��y�'��IJ͏����.��8z.1�T�b�0����^�M��|���\��{�u��+�/��~H>��@�;��h��2��3�����tʚ��t�����l�.*Y(�ǽ2ܞ�ɜ'���C<��^н��l�t:�D�E���jㄋ�A�,���DH8y��ż��Ӟ�1���QR�AB�vͣ�H�XH����R��I�t��q������_A�������t'�)��0���ʅ=ú�����[
�ۼҜ�bJ��'��Y��LÝ�F],������F�{��ia�I�kՖ"I��t�Zے�PT�Y�Gk
 �K�����l�׽�B�1��"�=�&�PJŊ3�d*жk�jLuS�A	7��a.}���S6�1`�D
 �5�W�7yO!Rq��0=��S]3=�C�����b�$�ϞD�w|'Vl�3�yi�p%�C#	4�m�8;NxuC�?&��"U+���H��lr��\�47��л0?�磝�[�!I�:|.w����8>��#!��dyP�R���QL}N[s�y8	�;�tj]%�s�e�S�\�B˺��,sK���,T��Q@da�r�$��"	|l���k���IH:��󡃭�K)�b(���iHE�n��o��2����^��q5Ł��Ⱥ��IkD�?9���|�_G��@5���yN��LȺT�g#}jvI��*�g3��!�X(2VG�Z]���?��!QS+�Tp2���~�����7C��GOba��#<��d��`ms�'���D�Չ�͋EN����5���<E_f�����:���x	x�g���U�V��m�?b��J�_y������:z������F���zNw������_��o֞�c�����f������ڰ&o�����x������U�F�������y���t"
��ա�&�Q��V���?���CkP�z�۳~�{��p4@�G�	��0~Z[�obX:uAˌQ�����������J�9��/�}ͥY�S�:t��L���'�<��`G��!8X����sh=��<�����'�6ѭ�yC�d� w��1j:&��!"�����5�Z�c��D�vH�ꢧ6�8p�]�wf�V�[���iϪ��[c��^�L/��a{��U�N��-2&�0'�C,fi�`��5�F�r�U�4�X0����kݴ�2Y]dY�qV�"�q;�]�S��:	�՞H"�t=�lX��a���&��4d��A�_�f��� Q.�{ʁ�M炙�\��M`\��ssf佲k�����?���X!�-���H����rG�7:5]hء�Yy��[˰�Lϻ.w|���}�_��1��qҩ{�k~z����	��c��G��
��;n�e"Z�<�I-CW#�e�[K��D�W�(�NM3�|0�G@,��� ������q[��\�oe��bݞg�ǈ0ղׇ��+�+c�~��bu���Q�}]����i�{��wWJUq)q����XX�(���*��>eO�#��޳������-�B������U�6<{?��)X$\d��m����R�M�S�Eh�BSc��%��S	y�\��*�Pմ���1��`}�/4�-��HC�)Y�NY�i�BiZ=^�TL��"'%W� �6O��(�A��[J$3T,��s�|�P$i"�Y(��i�HY�{�DBEig"��<Me��a+(�R���{C	�4������M!^��?M�s���g�|#*81� ��܎:g��Y(����*���>B܀�Q��/�`)A�����<���Ps"C��6\y�ҽ�ҫ8������s��Kg 2��oo�%�9�<<л#�j�'x��$�4���4{��4������7����g��Wt�ə~E�C���
��9�Q�+D<��F,�]r�Xl�ە�C�ɲ)�Jh���nR�@$%����\5�]���W��K<���܏55�iS���3# �0I������`a$�9
��t�8�����;��Qn�e��ٵ�@5��jR�$���Jm���V8_Xv<�@#[�D�����|÷��7|�Fy#b튭��f�Ρ,�Y�r�������rGR>���:-�S�9߄釃j�<��]�RO�I����կ=;��c\�^�k�(
 )3�`dX>���'G��"_�3p��Tۍ~�R�!�X]3��j����0�h8�<�iz��"j�lW��b�Ŕ�^�0\
(qN&����T��A�$J�7�`#2�<�h	��N^�ڠ�����7G�8��`^�a���!�(�)���|	ky��Y ?=%�ˢ�b��S���`Q!�]�p���}�7[���Mx���mN!ٔK[�\p{V���W�|�M��8�;D�<�~]2�����0�"��n�o�&Y�r������Ui�AMm�W�{�S�r�j�\-Zo`G{c2�9oć+���L1�Q��1:�{�+34.L�~�N)����\יr]7�.�k�]^�֫�Ġ�3��t�`�b�X�X����?
��_���D%�\S/�� ����0�_���%�'}>�1��+O] �gO�+�d�h��ܚ\��	�{��ĺ1�Ȉ�q�=��#A$�Ld� ԛ����}�Q�#�k�\�`^|<'ا��XJЛ?q���Z��&��\�J��h����=q������E�8\�Y��`T��A�{��a�5S1�$B�v���,δ�䝉�9��,�^c�~9���i/�u	7[HsqD�8A�C#8l����8������ś������O�BϣK�8ɽ�u�|���K�q(�s�L���2W�1��s4KF XX�\wG v����\���)T�4?�Q�R�/�A(݃z��h%���.��4@����Q�h�؞ã�;);4iD���k�ia+b����@�����@P���.���A���HkҼ<�c���K���U��b��.�U�&�5���9�A�|�S[�`ߣئ"d�41򪓌�]6���T��6K�U�_�eY��������Q��6ɉ���+E��
h^Դ�5�x����ﰮT�R�c��Hq�nVw�;�<�oPi�N#&�P���Ŝ��̎!��ꀲ��M7�)�=FV��^��tH���I�8�'¡��@薃��2�q����Lo���h�B-�kT-�����ɭ�'��T�օJ�_T ��+�j�z��J�k�R42�ê�ݦVyh�,�}w�T�BR�]=�2�a�V����L�5�pO=���)ƥY�S��"W�4��! �W�l��J�7����U�V�����R;���W6�5�t�4GM�Z���:G!~�FZ��cϥ���{��ץ�Iuc#R�xaGp��9�#���k�RC-UB'��1K���ZH��"�)�*n1I�IS�����|�E���;�	4�8�P����n��OR���3$�c%(�n�J�q8��s�+�X���)��_P��NPQ�#��c]%����r}2���i�W>�^9^;f�uf���C��ux)�g�e�c��a��Dm�Թ4I�Nֳ9�ћo����ul(���4��B�ļ\Z���ye�o\�ҕ�=9 y�%�.�ڑu�j+:� ����*������dn�j�q|�FS� ��'
������)xEMӁ�ec
���1	���$ʉ����)�����83��,<#`~���m��7�>nw�e���hMc�FB>�`��6X�KE�Oa)QEw��B#�K�MnEz������!��m�wl�c�kGqW�J���φ��D�!0�Da���L�;��^J�X����I&�0�HD��7�.�
�����+F�TH��@W��9#P~�9�������.�+>C�-#0~��ʆ
�����y3��"�n��� ႋ��Ʉ��S(�����r�#[b���j�xi9��z��e4�|�$�؎�AV�N�O;���s�j�h��#ĳ"� ��)�]LJ�E���\D*�!޾�Y�ю2���0��+��־9��[[iP�jR�c���W.�s�U�������90/��~�k�g-`qo|:�xTz{��e(T ��Z]ܭ��HV�Y��걱M�Y���)Sf^c�өV����R����bF�R[E�᳧�`wuuU2`�q�ˢ:������ﴋ ��g�<����9X��۟��nnV��_�"�,�c����Vu�	�m����A������C$q��ż�_��?�+�S/�wx�<��םK�E�����u2<��o<-I��a����--I��/{�_?_��r�t�.�k�7>�x�<j�� �sG\�T��ƿׯ��*���0�ٲ�����+do�/��u,|=�b��:M�d�d�F3D�{+y��y��t`h�s:������՘*�5���rGI�Ηb0��
���C
��^N藳�H1ʷv���
˛��X1@�Od�H ��1 �Ņ׸��?�~�b��u�'@qѦ���p�	��n�R����j,��"IX���$��D.fpA�Fy-�>���y�%k&G��LP|[^��rW�l��f9�:��yu8畯�ρܬ����o�\8v��-�
�Y�1faY��L��Prw'���-�2A#���4	��I�G AR ��lw�y�nl��9Ld��Ly���X�=VZ��:�mc�	2$�9����w�W����0F�V�v�v XdW�<a��6h�o�ei;�b��ɽS�����y��d9S����v [VŻ���&A\ZNc��J�PW�7��d�T{�X�lcŢ4��ې�	^�U��Ţ��m �"�^k��v#ܟ�#�n^|�(�cho<����G�ah�����)��&ڠ��H0�����j�%�r����l:(��4fiE�,Ln��m�SYZx
�/-��)���zm+�mk3��<H��7P qU^e�x�h��5�!�w_�+/;���6�N�n���kCr�o��2�㻈u��������:^�	�YS�1���1m������O���	�.�������?��Y|��ʋ��N�[Y�?D
O�.��Y��V�ؠ���l�?H�D	XH���[�Z����p��c��߬m�S�onf��AR,����ߨf��ä��s��2y�W�l����O6�`���_���3=.Q�1{)�	�t�=&/H�3�g�ܾ���𥈄���{�]�SU�3(�2F��0h۹k�\��*�ח�K�Ǖ���nG�w��OF�;db8�ȽW��H2��E����?l�u�~�߬U�d��C���qs�c�����Z6�?Hʜ~���g��+DZ4��H�È�p�}h�j�ZyP��0�(^���urF�tzF�3~$��qal��Тp��=�ll҃g�?+���M���JSR8�y�1e�_߈��O�d�?=H���l������S~�'�����4/��l<� >�V���������V���
�U�|"^���Ί>{�jw�/���ܽS���gς�;dv<�U{��jn������.Z7>+k������͵'w"����Q{����R�*L�G�Z�(�:+��� nG��=�4%\�\꘦�m��ݨn�@�ۢ��L�[|�ۀE�^MC۱�@�
�l�gz��E�g�ΰv�c��v
J��
ȧhk�$�mMW�0fGDcS52	��UZ�@� �cE%�y��
~Q�0���4����c<> ���ڼk�q����<ji����&�i����Rj�(�� �kJe�IZx����|�Z�
蕝�B�5��}����ื�A	�ݍ0��y��~��B'�/�k�Ž?Jpٺ�������G�DgY�L�o9RA�S���	$w��vRy�� h}��{s.�����ŧU�o�R��G&�M�@;��Cvz� �Q
�a��|LO���#��2�%V�I��D�+=[�G[�x?�s��Y�x�ޢ x�S��5��v� �G6ro�����=%�s��5���K�{+�������l�	r��Y���pĕ3�7PY0��_�qآ[���ݓ�Kˈ�U�f�x��e��vo��]����U9�3��S��Tpq������p%�W�NB��'�⚻1|���r~�9�6)��9�1E�Cw��������g�?$�m���o���mO �ȼ#"�5@���޾l﷏v���:��WG;�?��:l5�۝��;͓����ΫC<��83�|�Ȳ���z���6��m8�������z6�"Y��i��}}�;�D�N'����}���_�T���V`�٤�[O�3��I��G��$�h���o
�lǍ>k<�L~ �O,���x�0�P�=�@3A��)(�e�/����X�!H� h��[����F>���r^7�T#׺t{�)�rSO����:� I��3��3�<2���-��&gm	$�2�s5M�%|.uL��^_��mU6k���)�׊��������y�%�Vv�՜�7��$𯵠O�V��\H��6�|�9��<8�y�׭��e�9�=�� �S�sö~"�x��$b�n���%��B�9^<RSw�-�� �Lԩ���[A�ܢ)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,������� � 