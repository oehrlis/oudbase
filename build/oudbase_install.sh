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

# Define Logfile
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
export OUD_BASE=${INSTALL_OUD_BASE:-"${ORACLE_BASE}"}
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

for i in    ${OUD_DATA}/etc \
            ${OUD_DATA}/log \
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
� ��	Z �}�z�8���]=Fv�-��؎��QfKI{Ʒc9��&Z�,�%RCRv܉����w�<�V  ��m�Iw��� P(
�B�P�p�ҟ����ݝF����6�+V٪�+���r����;����v�>� 4}@%��� [�;�hG��7�\@�{#����\��F�[@������l����U���݂�߮�T����%������%d�3��VXq~@[ݷjlu�`�|�ڴ��5^o����q� `M���{Á��/�==?d�/���i�����N�fج��&���Se��f^����M־q�_m�o��ܑ>2����|l�狏���.;�{~�a�X@i�Gi��7��-�	�ҫf��L�Ҷ^�r�7�0�[̀x�S��	�Me�x���?��Cz	<����,�o3�}�\�q/��&�wa�;@"x�HD�zЅ/����o�(�-��|f�׎�ԟ�/=o����"�
��.�(@F`�0�R�r�.�0%N� �p�=�ʰ���<����g���3�-wB��k�G
B��FyW�sh�m�����v�#�F�fBC�.~�w���Q��q��zA��jT*pWlX��DCH��6���=�y]	�8���,踡�Y��͊�>�kh�(��{9xO2�j8wr� ��_����9�B�u� ��k��C��쏠�����i{���^6*��q��uԬ��Nߴ�l�g��yч��.Yׁ�ph���/�ۭz�U�� x�-0�����\{�t�����qت��� r�+�j��><=;���h�N�yzC�e����~V�ޱ��|@�h�]��4[�����f��nׁE���&X��˵NO�O�����'آ737�7J��K.��n�v���I}�>p����4�m_�`���ad�Ї��/���\a���{�7/U�}<�q�}5r;����Yn�C^�M�N0웷�M`^�[Xw	8�����.��=Jjz��%���:f5�}3��k��az;�"���C�Y~�s�����,��{)��:�z��� ��Ɣ�N���cʦ�? ��l�s������QC�Ga*�Ym�h�u�::k���"S�š��a.�pdd�q�]��������W��;�����X�c�ː���Yسݜ�u�o�nõ�s�<����}���(�|	Y�]��(����rO3@9Sp: ����E��z!Ǉ���ɛ�:�����vf^�4r�4��X���H���x-�?P��\T�����̰�`ڌ�$/,_`�l��uL}xS�*���w?���ο����a�v���J����E�)�i�����X�Vo>�f��ߵF�#فىG@�f[��<�3�`$��*�Iy��N���1N�8���Kh��h*�1*����`�l0��Ϡ�t���㞰�j�����Uqߖ�h%��.����iY���[ky���Ms�/���Q?�ى�����"
��'gޫ�H(�S�z�3�i��Pw�D��4���є��&ڔf�J���*do�� �`�`9�́7ri�7��.���al�hVC���|��@�6�*��V!�u���¯@�'�G��e��b����V�D�4��tȕi���Q�"�7������p0}ϴ؇��?CG���
nkj{�L�B��B�lK-����R�w�=ܘ�k� T����{!�:�߸W�w㲖�{~zj�QE9a<�b���|V8|�$l6�7B ���ݹ�Y�8�)0N]��Z���rRf�rR������l��Lr#+Wz��t�j%Rb�c�w����ƣ˾|�/fE+�YEP��R��r9��:zJ�{�2��dk�lVh�=@���D��Q ���0?�a��(�	91w��4�p�J�QC_�a�F߻���p�'V}Q���;��99V�ʊ��Pಿ�{��5�F���'u�N��Z��wh���i'�\�����ףlo181́���4N3��Ո×����m\`㰹�Coܧ����(��E� c��.�9���Ҭw֜ڠ֪�i,|�u��6eEx]s��-�% ���O���5���᭶��q {��T�d�/hJ6KX�R]O�
:eW�Wٰ*[�P�+�Jr|'�͐Ib4��Ad�g]���͋̕{�`�ܠ�;Ģ�8kܕ�S�#<XԨ��m\s�"dM��q��<ƈO%�E%�/�ٕed&���a�~��C�Ĭ�se��u��3
����BZ�
r�k�9S66��CD�0�c`��	�a�8��(����E�EkL���N��ʟ6�Z�I�R
��}�}ý�N޼`�U��~-(����P���> ��j�C��V�����Փf=[���V�H^��(�'��(��H.�<z㉖�>[�\c𿂐w�=�m�nH�9n��2��N����W ��ͧ	���AOk�/-�xY|��B4�K5 EWTc�����8S�}��+���e�z��"Ú�4G}��`����s�,�;j�;�j���X����r�����w��ϸpW(P񗍽�99o���x��P)bZ)�.+��T
`=�bR����z5Sm�N���H��H�+���ia���b�U@V1$�z�8xސ���}]��;��FBnhL�
������X�\�rY��Aɷ�������/���Ͽ4<����iV}��tp����mJ䅊�ނ�z�'� ��Y
�)
���g	��+�	��A	M>�X���,�F>$*ʯCT��L5Y~����8g�bݒ�#�1atZN>X
�j�dg�!�K���)��I���(m,*R+��ޥ�GLQ����a�n����]I�#��܅ý E��zf�6�ҳ��u\�B�O���~�e�_*��A��&)�A��N,݁�A�p��e܍3`,�I���naœ_;�YhTRF�9�i����%����+�b\��4�3�}t����=ږ,:������ASn��д���u��nPlF�#m��FCH0ȯ>�C�^��B��L2m�X��E�*D��QэЫҊ.mvT�Ah�j?���dj�;\T���&a<���ds� �'V��t|Z��������0��,��}������N?p��1��2���)��~$��:A϶��&���(���JД.�i-`^�B��=��M�V�/���[b�k���S����1K]R��t�|�j��~��L@��K3�G�ڄ�7]ݾ4�
R҅��<�'"�fUcT˻q7a�(ѻq�}��lXk`[F>2�)���qcU���X�.�>�5�Qs�#��*���v���RÎP�����h�SD�c׌]�0N����7�H�o.ᾊ���v�Y��ʕmx[�?ų���J��р���������M��^�kgA�m�kW��ܵ���m;j/����˿s�奯�$��|����x�k̖��K_㥯��ߌ�1���x�j�t5~��q��Ү��[��:���H�f�x�Em[�,�n鲼tY�M�,��i��t[ԜZ�֬����pMnb(��Gc��"s���
H0&�\�yqc�ԿF^M"���FN��V�w�z�G��B-~�.�� YLM ��O�5���#����������K:��	����^zr/=��܂�g����{�~�^�i�{����S���'Ǡ���Sʸ1C�A� �!��OAY�rk�E$���
��:���-����z^�%�UC��YE&�{����E�t�j?�RI �G�^�
����^�г�z���8�� �����҇��|)��v�(�[���q~��j	����=��� �ߌ[��
�����}s�����:f� ��\%����$�>,��>�Lj7,S���hr����Q��B ;���M�VX������� Ҭ�]��)A�����Q�����ݚ��%v��#Wi^�WnkVƹ��.>3��"�a��Lw٥\�s��.3�󂞞my��S�h��)�^����{�G�'����n��w���Ve�������+�F�����k<���y�<�o�#�ؖ�{w���:_�������N��A�>F8�V+�m�Kz���w�o�O�D�=;�Q����ӟ��3O�rOIˠo,���j�i}G�HΣ�O�O����Q?�����9��߿�����ݙ�=Ο��ǥ��*�!S&N?���1 �vǏd�kd���.��I��i���ҩn�G](.}[��o�2��ҷ��X��.}[����ɞ�O���|H��ޭ;S�'L��;`1���w����]ht�`|W!˅a�S��ک�ɡ������S[��Aл�D��		w\��@��uN~�;��V���n�B5���E�O��'Z�B���In����HOh�
�'ɸ}7Cxz�tG�8�Dqt�)a|$�h�B�qqg�/����6�W���P�~��$݄6*�|�GEc��h Uw\e�X������ǺO�O�������z%��!��~��<��s�O;4ʘt�C_~a��9��j�S����螯�_`��������SX�3Pv��dFJ�%H�ڢc�o4�F�DĐ&��ح�R"���BJ�,�<���R������7���'v��Xi��I��cj��0��ϠF�A3�N?16�����p Q�O�	Mf�J�<�ܝ���Y,��b�wl`�[Hq�"H��0��'�7��бr���ͣ�5ͣ��}�#_�:g����,���Y}��e�b��ۈ1ĳi��a�1��8���v�!���R���2#��Ń�%�c�Mn����3�mD�r�@��}x
�����VK��~J�+�x76�t �D���j
��'UK��N�L��8�w�"vX�71^[�q�鰵T��h[Z�)E��㎆q�i˗.��I�KtpGJ�N�*�U��6(��E�-����=�m�˖p���hh����1n��7Wl�e������v=��-~�e�+���q����ikf�z�G�����FL�����)���P��V1���5�e�Ë��Z_���-�H/8���|�u	��=θ+e�_5cdA��TR
��.JwS�����E��ǙI�z�t�޲w��;�	�?�(�*`����rF�bK2zG�n�}�Bh�e��S���3f1��<�4���2�j��5i\�fڮЫ�U}���eh�L��/����P��(���4�;�����^?BkP�����j&�ߏ�����w��b��ƿ���ڊbAuL���zVى����\���]�^��>ų���:���W�o�����y��r�;�&�~�Q`���������wS���R�r����eЪލ��#�rڣ�b����8��	~�g��%�W_PN˃��r�^��9BqX��d��
��yxΞ��%ȉv덀�n�k�'�6}�� �N�n�t�ص}�?rF�h�����^�������Ͱ��~V���K:2��$p�h`x� (���s�T��^�t����R��`�s��"K���Vk�#���tT�qpp���}v|���h)e@�u������ф2��@��������
#�r���3I�_��%s8,y��Ô[%ѣ��vO� �����,347#3���g�Պ���z��E�!��'�)9����&D���ʇ�0yF�Wp-M�i u"��˒XƩ�_������7�6TD5x� 3��X�*7��4����?���~\��D����g{ aĎ�EHc BV!���.�AbFN�8���E�<	�����$�<s`�XH��2c�����.��J"sw� ���w��ܷv�����y��c��!Ͽ�0��G�Fv�x��N=2�L����  +z����A=�#�y���Dv��0Y�An"є�}�q�f�>�,�k��d��C^)��,����A��]�+��;�*�`��N�n�M^��t4�(�h2P�����Ri�K�BV)�0��*�F�<��#�:@%�]+&q��9�����u�A�Ņ&�j�BP
D-�8y ^��d��Ⱦ1�<o��0�e/��ó����#�7?�t����oE�f�;#B�$b�D�ߜ$@��0߸�w�G�~�c�/�	F�)����oK��ax�-�U���Oh��:~*��%���·��-=щ0H�v��"�g���V�����;�6�Ȃ�J;�	X��Y5#�_�~���)m�(i���&У{��[��FXTكax���H��J�'^,7��,I-
��l�
�I�n$�Ag�a��lj$7�\��3�o	�1q�.��oKt	{l<7�O��&46b�4Ձv|���pR�o��W�7g�KN��
X�HgJ�Jat��&ZI����^�o<�{s�8�?�=����q�m�'<�p�7�W�lF.)��q�
�I�|�$&�4�l^׸��S����l�c'*r<�S�.zH������=�@AJ�tQ����d&4/�+}(���AJ�11�!V�>�U�揭��K�'���gl�ۙ���Cǽph����.^grM�3�_�;�ٽ�Nf��8�	�m%e�)s$l�Fõy�/��q� ���H�V:-3�(쟞KrxWk5�_���2MZQ�$��h�:qǛ �b���s�R�㪕�o���0���z<9=���i.�G���1����d�	��1=
����Zyaæ�L�06l���;����J=+y����a
htCIek��D��v�@�ڠ��3��c��Y=
$��̧����oq�HA:��i���$�@��[j���&N���OZ,rՖ��!m�qg#�$ɬ Ĵ?��IO^W��F�U��cD)#P(V�I��?������5��s���Z�y�a2~,#ܢ�F��@v���{8��G�Ám�����]��q��+V�����l��7� 9tG"AJ�D:���xP��&��%Ag�4VE��|x,R��4�w ϑ'�EF<�c���s-��V�g����XǂN��ݸ	�Jb;��a/��)[E�����%���t��� 8M�����HN�۸L�{�}�c���T��Â��:3���O�mR��ܱt��������n�*���B����!d���
_R�K	Q:iವi:���W� �ݮ=����$�k��H�YA�ӽ,��v�IW�4\��Dd�����9�$��V[{�Ձ6�j���͋���
�<vx�z#��mt���C�~ě��9�w���@Hӄ*'T�T�Z1�O�.�W��H�\�t���ֳ�|�}��O���<ͤ�r�����I���,���U��dI�S�-�5��7�n�X�(���Ԫe��Zh����:~V��+��a����
s𫺀��-#�]N+g�)�Uq(�<���a�
� �R@��wj0R���q:}��h $*YY���Q�ʃ��Fi�c3��6��6� �h��Bá c�&�P���m��B�g��ٺo[��V8��
`!e9>?�'k+�^�+�[��syl�M.�d��?���<
��e�����Th(InC���p[q�� ��$�]��*m��(����p�k���r
���ס_"򅽘|�D)vrw�Ad��'tƍ�\�:eS����(�^d���,���ߘ�%�l2�I<��� t:W�.:�Aٞ�+t��:�:��ӔjӄK�A�,���DH8y��ł>�nӞ��O��YR�֤vͣ�I�XH���jP�oH�t�v;���v���_�K���o؟@w�l��v�5�*��&e(�gX+�&��u��}�y���
a��w�>;��8�� ��0�ծ��Q�4�sk��(jT�ݰ�ϟ�T�M�Ϋ���MK���r9�PO�Aq����O�l�׽�B�1+i��N����RF��]3=�R�GDW��M�%G���1�>�����k&�# ��+D������8�VM��j�驦��j�
~W˿x������N�)q�|1���WB96�@C��&�L���ʆa(����X�j�Δq!�f�������Ov:n�$����E8@<D`F��s����oR����S�4󠶥�(��*��8抃���
��r)�;� }�.���V.�Q�eMq����_��~��)�9�XF�)��>�1\�3�O9d��I��;��XW9��� O�I��@U�:p� 3��S��v^��-/}R�&��o���c,։ӐOfO��#�όF2Z�L�d"��'*z:�鑒�4Dn*�.5���͕S�;��w�.��ɿ�s�ˇ?���:&����������[�T��no���,+�����w0�I-�v�(.��om/��i��,v��i���nUw�=���*;Ϫ��������1�T�������/��j����8���_���>��4�(�
��Ȧ��.n��^������ ��2}��Un�:�a-���t�.V>��]�:�����-I�Jx.�c�shk�1��eO�&�4�A�����(�6+9�ע0�J(2���7���=���솾c��F�vоO-�Cn�n���k�ADҰ-�V-��������}�͉����_��@[����]�ӵA#�m��MIF�δ]�hn2X�nR��#�0�M1׃p��2~�ԡu�sAA������L޻��#�ېL���h)^t�caB7mlD�,66Y6y�-���<B\�.Fx�:^h�ר���1�?� ��sV�����$�)4IF-i�8}�G6��}6H��@���rV�U�y`��	C������҅y�8��{{�����V�c��� R��6�ɜ������a'f��F��鲿�Ap[j��vzT�5b�/��qo�IH����K++h��1v�8�4<��Z�>n$"�`���D�W�(�NM3�|0և@,��� �_��_������j�.����X��#�TJAƪUJWƊ��)V*���ye�V����=9�jWf��-,q_�8h3�؞XX\���^����`ϕ��/>����p���BD������W�)G�_|�X�,����O�m~�i�2��6Ō{0�@K�T��ƪ��z�S
y��CUM�j�2!u� >$o�Li�'{.��b`JC֥?Tt�`L���U�!��*(rNv11�^q�����14����d��7�^7��@�<��)b[�R8�F�q#�q��D� �A��z����5l�T,g���P�L�;C4�)uS���&�O���1��o�M	l�G.���Y�'�t���Caml����7�{�#��*X(W���#���"�j�Bd�ӆ+�P��.��S�[�z
?2)��� s
�Bx-����[��q~��եPUY�h��4{��4���K����փg��W��ə~C�C��}�ߢ@itfF�l�g��S�̲˦b�ݯ��L�C�,�&
(�&�DR6�jp�	�U#�E(�xeټ�/�y��G���g�1�¿�qJț��{�H{�0��n|������k^�I��(<�Ȏ�o��ZQ��T5�[�KLa���up��7�O��Q�r"L�9G�U��-S5�o]))"֪���i&��r�,��r"�Bb�P&��˜:��\�r�)������Z G%��gXjN�?~E�z�ݻ���Z��$ ��Ё��䢟�O�?&�@g�p����� e?��>�c'���s�2���#��㝦7=D��t9-�[L)����Í%�(�d22���:�`�ތ�~��R��L�%�4Cx�j�F��
��2��Ѽ��H_�B�fTS4�,#����t��@>}pI�E���6F8aѢB�O4��7T��a�rlƸZ©d��Zs
��n"X��
�n��ѿ�T��p\^wH��r9䜕<���H���9�M��\��mtbfC�qP�E���_�:���'�J���G����t������!SH]��勮�0���WP�vῂ�L)bYg�e]߹�4nR��ؒ�-ĠƮ���3��2ׂ��Z�:���7�>�~UX�Fn�rE�`�Q02-�+��%��kZN(�|�b�M�7��< �Q��^�^����Ew�M�:��E�ʍ�uR����J�=�; 9$�Lb� V�3����� ��k�\�`^L��N#�K23j�nt ۣ�[��ЄE�ϝ���|��]n;��@��Pkq\�*�㕝C`�)�AiP��!�D���g:�b0I�p��)�im�;�r �),L�dt���ڴ���{-�8	�8��/Y��H���S{xBHV��L��Q��n���ԷO�@�򐹖��,� #!��������A�k٘�jN��e#��x��#@��.R���\�K�)4�4��Q�TV/�A(ݣz��h%���.��4��il�x[4�v��(n�N�MҚ��7Zغ�Dyշ?Q�qu�*Tm���K��m�49�4�F�'�R;�Iɥ���U��b��/�U��M�ڱ�����&m)���0�Qtu�]Zy�Y6�-���c�V-�{�hXVBo��0"�Rf�q��lNFr"z8�J�&��5-dS=�),�JJ(BǢ��1�-MH�8��2�3�L�5�4S�U�]D�u�`NHef?LWvuDYr�&����^���OO��H:$�ύh��B�?����@薢�T���7V6h\��Z�Ph4b����M���Sl�z��V�C� U*C9C��/* x���R=cv�ZT��M�*`��UA�=�j߃*��U怸L�������+b&܎9������p���,��U��L`����+U�w`�m�:a�;��T��Q1��2vgo\�i�"i��D���G!}�¸v�F�O�K�XW�{�|^��N��;��]�d��f���:�PG��hi��Hhm-�M]	��~�Xd�¤�Kl���"V_�A�����A㉣��T�����T+���Ա2Ξ$�E%�4D��8��,P��BG���d?�([��5��:Gf�K\2� PC��+�O�$���x��L������6�(p�2�smt�pQp�6�]ۤkg�������Ӂ�c�:6�D��S��jb^�8Pb�ǲ'4�`�Jv�U~̒���2�"o���~ɸ�$���bZ�˓ft�3u&Lԏg���I��GЉ!L�ZH�(62L�G§��4ML���)@#��$`��('�*�{��D>��x].��L�}��bc�5F�x���	���j�M�p�������H`3.��Ut�z/�0r����Q�'ٚ�N/J�\0і�x��>�8�vw1��)$�p��l��%�"�6����ֿ�E���kRWt)��f��2�F�e��r��� ���+f��a�u�\����@����`��l0�s1���8� ��@�l� }5�x��č7��.b��ҍ�	\LD>&~4�"~�`����eFˎ�	A�׎7"~����/�o�����*��I�i��bt�4Cm�~=D�xV��T�K_�^J/��^�"R���5�ǹ�vd�������\��u����P.�A�I	��QX�RA�P��6���'r�������[?K<k������P�=ʗ�P�w�tp�
o Y�fm�d��K�Y��!�)[f�d�ѩj����һ��0����VDf��9�����&4<��$�J�{��v�@_�~v���I��s%�s���������S<�n.�c��������y�<��Oi!uL�����3y����6���������j�׿/�����c/�wx�6��׽��E�����kdy���Gj�Os]��/�ɺ>}�{�B���ݛ;��xq�ܺ�������i�-�V�;�2�Q�R_�0�ۇ^��M��O�����dΎ�ӯ����\���8������s�DL��IfH�UW��2�*�ち�7��]�7G@`FW�F�d(�rKQ�ڗ�_��f5/Fs����Яgk��+��?M_1,oR�� ��Iƪ1 �H
������C�WܐS��<�:�(.��2�9a����]������5�Y$	"�][�����,nh݊�ލ�J&�d�e^|ՙ�ߕ�Z��1��Q.^&�Y����k^�y�+:�s 7k�p��sA���N:�B�(��b����)J����|���A&h$#�T�]d��2)�$HD
��`$��A�U�c}�s�ȾPL�(�Q_�36�5;^����(���`.��>��()�IYЂ��ctu��whtY�剻/�Q�BӬ�I�!�)O�7�����'өRܷ���3c(��`ĶV	����k�N*8^)*��kd�T����i��bQZF9��$�U7�������E�V��;n=vP8$�~^|�;h�cF[*&�h�u�������o%ZV �)�\�J���"c/�X�-�7�M��'t��p���Ў�Ҙ�u��0�9k��N.�E?�����1���U�M����Y�����s� ⪼����v���Ct�&n)��(u[��7�`�HM�ؒ[����X�o#��*�޳S�K{jx��R�����E�����.���y�E�����e�?���]\�����M�����$Ϙ�s�c��W)�T����m����ݥ���
��R���Zܶ�s-&曆C���3�߉"��#N'��ܦ�!���;CQ41*�h�A{.}s�r�B���JN��+@73P����r�xOO�k3��Yȓ
ǲ�:��mW����<z����1{��Tw�(����R�{�'%j!u��o�V�����Ɏ6�:���;�ʳe�?�36~�똲���O��n��\�=ųt�|j��߬����'�&|7�{�S;`V�J�I03Ø�xU#�b���E`��E�S���x��c�^�C���w`}�^�W�Y._����?�3%J�\�:�om%����Nu9�?ų���h'�k=j�ou�n���Y[�M	#1�����G��s���ԁ|�%��&�x�e���X���.~Zv����_���4�	�!��q�}c�f��@�9]<QS��'c�E�Oloط�B���k������(�s�c�������[����[��O�o��?j}̝R�w�r��W�*�W�2�_����Q�t�c���{s������f��>��8?���9h�9A��z����"X>�x���0�:��H����<�]���$��^�&��9�y���"C'��K�PꞘ(�6�����]_ǔ񿵳#��w�w(�����I��-�е_[��]X�G�L~f�bm�Ux��+���vTt��j_,�S7AVe�od��7�E?�mJ���u�Q�5�Ð��@�GY��<���e-/���E�b{o������U���pt¾�A��fR�f�r�r_��b4��kH��`�*,& �7U����p[��k�k��MF��f�|�4q��!�����x�ӈ��sB#���׾)��k��`dy�3�d��K�V���D-N\���̨#�ٌ� V�/�q-f�xy�5�֊,Q|���m�
`q��D���q�������^!�s�	r��?���P-��6�]a���V(ߦ�ytj�lT*�l�\=��ãЅ���νGY�1��kf�w�u��F':��s�A,��r��;��u~7My��F�ך
�Sv���'��f�<� ^�g�/�s�Ov����X�ב��%⬢��U�5r I^��P�&���s{����Y[�]����Q8�u`R�yC�	�����`��"�2A�=ݧ�)��ͥ����H���[E���?���⟥�����*���╿6E��Q�:���a!K$��	�,V��`�E�~Ӫy��7���l�s�����A���Q��Aqd�(N�q��2�_��%%��\�*M�_Y���/�K��W�J�=aI}O����F��	O�u��c�������~�l��=ɳ��]�����/�� ^��*(�ލm_�oYw���y���]���%�V��;��A��6� ��3��gMš9�b�^�98`E�b�o�ۺ0�N��x�J�`�f�ȼ���@>�ě^��ӭ��#by����������A��?�;m����
U�����d�J�ܘ�~�m�w�}�yx�,��|�����\� h 