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
� ��	Z �}�z�8���]=Fv�-��؎��QfKI{Ʒc9��&Z�,�%RCRv܉����w�<�V  ��m�Iw��� P(
�B�P�p�ҟ����ݝF�>������_��V�\�n�+���~�'��h����*�gO�ٺ�	�E;�#���7��/���hh��1���;[;[��խݝ��.��vu{�O�� \R���W�\B�0�^n��� ��}��V���w�M�	X��&{9
�ִ��7�n���ڣ���C����.@��i_ھ��o�ͪ?l��+;U��o��?���d�'�����k��#s`��1m����(�y�����c������A��fx���P��x(ݲ�0*�z`�^�t/m��-'�����g9������T��g;�C/�9���3���a�B��1��g��u���i�}F�۱$�ځD�]���k`:n����b]�g�{���K�	���F!;{�,B���P�B�d��aP+�.!��	S��
P�w�s�Q��	��ok�Z~f�0�=c��0a�r't�>��}� ��`�w�<��/���:@*:n�?�ldh&4��2�G|7����G{��� �F�� w%���H4��m�/��s�ו ��*[ɂ���5�ج谡���������q�����$��s'g��������Z���#p-�ZwP9�&��Q?do����ؽm������e��k7NNZG�z���M+�f|V`x�}�
�u�a�6�-���ݪ�_5���r�<�ε�N�O�Ώ����:"����9��ӳ�Z�f봞�7�\&�\���g��[�G ����hL�Ս|�h6O[�vX�o�o5:�\�����^Ν�|�-zsp0s�x�d�����vh���j�Է�G ;.`@@�����+��@�}����bQ����!���W}�Re��3g�W#��������=�٤�þy���弅uW��_/��9�h��أ��w\���ѫcV��7����ػF!���s)��/X1dϑU�׀=W�>~��X�������8;�/�mL��TٌA<�l���v8gKI�)54z��p�2�����N[������8)2EX�N�2GF6�%	>PL>�~�к���.{��;V�Y�}���=��I\����6\�?GN��~���g���̗����ˌһN�.�4�3��:k0\Ԑ!��r|����9�Ѿ�m�M�mg��@#�o��A����Ӷ	��@��eC ��=3������C�6L�Q��������΁�O`ʲ@b������w��w��w?վ;�}��~�Q)zz:��;�0M}P���k����������xd!;0;���l�|�gu&��`�Y�"2)/���y�?�	� Q�}	mPMe<F%�q5L������n���p��X�_���*�۲�D���e�p28-���tk-ϵӲi����EV��1�g#9;�@>Ӵ�`��AD�����{�	eu
Z/|f3�{� �����Q�r!�rQ��D���UiUQ��@��-  ��@�,�/�9�F.��9��}`�6���j(�;�����چZEu�*$`��3{aV�h�d��3�l�[��B��ڪ�h^��Z��2�7�[!�F�_�!���������c訒!�T�mMmoۃiW�v]h�m�����P������uM���3�}O#�_�v����n\��}�OOm8�('�gZ,���
�/�����F��׳;W1ˠ�:ƩkwP��osRN�l\N�2����-ٛ�And�J��[�DJl�a,��tc����xtٗ/��Ϭh%>�j�V�P[.Y[GoAiu�RS�l��
��H=\�(���!� P[懣3l���2!'�z���\I5j�k<���{�����ê/J�}]rG�>'��_Y��
\���`Oݰ��&�(����N�ISQ+Tt��14� �� ��rp��z��-'�9V����iu���q������l6�v���ta3�=E���x�d�#�"�e>�uQ���ÚS�Z5�!"��O~��N~�������BbU��� 30�	4��&��;���c2 �b[]�������A��f�+]��VAg��
�*Ve��p%UI���2I�ƾb5�,���{��y��rOL�q�:�C�C�p`Q�VXǷq�ejH�%�f8�-���>����8k���+��H�8?�o��w�ҷ�h�Y���#�p�tF!`^)X+��� û���!1U#�D"އ�����
&Y�{A��.z����]i���R#�!��z��Kq(��;hE}/P X)%F�k�p�F��6/X~�!N_J�46>�>�������X-}���
q�T5?�xҔg��Ί����$�%ɥ�Glb��gk�k�W2η޵���.�MtP&p��Q����
�z���@���8�im̥��/��8�P��s9����Ӿj���gg��Vq�U��LyA�^dX3@;���۾b.��sG�w��Z�+6�7�B����5@���w �
*�����7'��p��*�BL+žå��J� ��UL*��QX�f���I�P	3	q�wӁ��,̊#�R�
�*�Yo��2�P?���pp�H���"Q�c�~U����1�@n����!(�v�}a��y���a`1�������`��> m�J�6���<��M��P���[�W�����"�K�`8Ei<_�,��q2!�3(�����p��ȇDE�5b�����Ϻ�W ��pB�[�r�7&�N���K�Xu���8dR�'Nj������f�"�b���]jx�t�6P��ݕ<��ɝ7��+���03�a��]���J}b/�&��.5�RIv��7Faݑ�wb��*��u.�n�cA�N�d�7t+�����B��2�9L#���/����^��Z=�i���k�� �Ѷd�y4�Դ�rC�����U�wk�b3zYhא�6?�q�@~�qҖ�L�d�iC�G�,*�P!����nx^���VqiS��BKU��e�&��բ:EP5	�9��%��e  >�b@���Ӛ�E��U���ge����s�_���u����]����`DL��� a�	z���4�n7F�7���P��t�Mk����@�1�5h���|a�-���X��&�rU�P��Y�j����SU�V��Gf������8��&t�������V�2�.���?6���Xލ�	kF�ލ��vg��Z�2�)OYЯ�����bv��ޭ���#��U!���e�8�v���
L�$Fg�"���f���A���]m��G�si�U���������
�U�lo�+K��x���_��;p��o�/�a���7�)��Kw�,h�w�Q~���\}��mG���o�{�w�5��cߔ�1[�/}����x�k��5"��5f39/]����q5nqB��x{kZ�C��^����Ϸ�mK���-]��.˿)��;-�n˃�Sk՚�_����M�s�h�_d�!�_	�䝋��"/nl���ȫIr����֊��[�|ʀ�\�����2 ��� `��ɻ&w[�r�Y�2��@��bIG�;!���KO�'��ѓ[0��p�o��6-�bo�x��}j[���ttzJ4fh1h�8���]��)(+ZnM���� �Q�A�Y�aV��E�88 �S��4�j(Q7���s��_���U��ǵBJ"	`�Hѫ�Sa��"��Kz�W�3:��� V�.�V�����/�@��.�%xK8~=�o�<B-�B>�{�Ǵ"b����q�vA�ZY>�b�o�`.{^R#�^���$R����<�?��Ї�u�߇�I��e�9�1M���!*PbXd�P�i�
���|7Z��@���0�kDJP0�yF�n|T��ļ,�qE�&�q��g��U���ۚ�q�媋�LH={��.>�]v)��Bg������g[���*��t
���=��#�?���Q�U�?�w��
���fD�ϭ���<K�ϯ���ߋ�'��dV�6�-ĳ���\Xo[���	�b�X��|1���bZ;=>M��[���	/q�������]>�7���NG��ΎO�K�<%�=%-���T.������#9�fxt>�?)��#�G��'�Vl��|{~�����lvgR�8Rv�R?�x�̚8�(m� P�?�}��}k,s�(\&�^�=�K��uѸ�m�꾭�8�K�V�c�ۺ�m]��'{�>��kD�e ݇{��L��0�W��@�G
�ڋv�����,w��O�#|j��'�VB��eӋOmMK�A����&$\/4p���5N�9����[	�F�Ig�\�6�?��h�#-o�'�A�V3#=a��*4�^%�������M�܍�������
q��]*���ʞ��_3KCI:���zڨP�1����T�q��c�'�;���=�s<9�N��N\��7�,�����=�{<��(�ө�}��9�;�Xު�O�[>ƣ{���~���N��gh�Oa5�@�I�k�)� Abh���ѼC���Jb��K�<Kxw)�^�h$� �{Q�RăJo�P+�ؙ'c��n'��y�QR�dO|DL<�N)g}��;A���L�?���D>&4��+��w��s"g���n�]߱��n!��� �Ð~�����C��a�;6���4�������
_�5�c�8��g�튖]0�)�n#>�4Ϧ��y�����E��WK�ҚʌP�f��ܗ��7�]z0�����!Q:�M�YX(��'�M[-}>�1(}pK����� Ӂ��S�) 3�T-	~:�3�6���Ŋ�a����xm�Ođ���RY���miu�Q��;�u�-_� +'u.��)	:�'Ve&ڠ�j,�8h6N�O{�=�-�V?;b��x���c� X7o��������ϧ�z��[� ˤW�3���������ʏ|US����
�7+�S5)�p]�b҇�kX�ڇ%����œ[��^p�?�;��L�J�{�q�ʔ�j�Ȃ�٩���]��
Q)Ý�2�3�:����M�e�̭wH�?�(�*`����rF�bK2zG�n�}�Bh�e��S�]�3f1��<�4���2�j��5i\�fڮЫ�U}���eh�L��/����P��(���4�;�����^?BkP�����j&�ߏ�����w��b��ǿ�X�ڊbAuL���z��l;���lg��+[���K�ߧx���_��7���-���c�4�a�Q[�ub���v��>
�3��� ��Q������n*Q=@R�o�Q��ZU»�<��tXN{[,C@t%G��<!��|P�`����iy� �3C�"�K;<G��#��S��W�;o��S��9q�n�p�-qm���צ�9*Э�Ѐ΃���GΈ���=�;�����z��V�����uIGb�.� ��@�|�*����<�n���Pj� L~.��`d����j�}$�C�B󒎭6��޴ώ��-��B�N� pT�c4�PF�H;��za=�rA!�ϛ�}&��K�r�d�%��r�r�$z��� �"`4���~�e��fd���|�Z�д]O��4�X�$2%G����tلh�U\�0&Ϩ�
n��)8�N����`Yr�8���w��@cY����ۆ���`fփKY�Wܕf?�}��;ߏ�S0���CN��X���SJ^�4,2�鑌�B�g�Љ���h�ʖ�[��OX�3����n)���Hh<�"kۡ$5w�R*B,�p'�}kG�+\v�^~:�x�\|!:��z��od㏷����38h�q��
°��98�k�ӻC���
Lj7�w.�&S��(7x&��a�ȥ�vO>����X�ɂoXn
ܱ���K���x%��[�E�TGÍ��2�u=�ÿ��Jk_z ��J!���Z162�q��H�*��Z1��M���H�0�#:/.�0�V�b����y����-{�ء����A	��Y��h�'OG~�'�'���%�%*x��t������'���]V�î8*��S~�-NY���xNr��ȧ�-��CTsOg?�ն��A����V��F�N(��D'� ��	ǉX�o[�s���)��F��8WکK� �̪I0"�2������ga)�!.I�ߑҡd����	U��9�ฤ���A`�k���o��p����B�=2l�@�n����X��
��ۘs�Zi��k��/��%���'Ӣ��Y$DA*��;�4�0`y81��l����������r�b�%��=6Ȝ�#Be�"��d���@;.���Q�(�3�֫ƛ�3�7(�uT�/Q$
~�U�09��-�d�\xq�'�όo�ݟ��q��6ⴅ�nc�x웁�0�t6#��b�8q��$�=K��d6�k���9��s�6釁���)[ݴXM�l�/�r�� %�|�(Q�j~2�� ŵ�HW}%��ԟ�X!�,�a��?;QI�'�,K�U��&0;�2X��1薳7@y}l��55��|�/yf�
��Yc&�Ǖ��"����Y�~����;���SP��Z	�J�8'�z.��]e,z��k<;�4i�������D䋁Ӈ��Kُ�eƿE�jG>�����.W��X�NǤ�:��Y�'�}X_��QH�4��C:�fJ��EeL}ܓN��U�YɅ��S@�/L*[[�'����Z�]w����k���y$QDf>m�����;�
�i4L&U&I/�.�QC�.@4q���|�b���liێ;�'If!���H���uunl�aU<F���1U��bՙ$I�sy�ϊ\{z=W�-���'&��2�.:11a]�(m�����p�?�Vl�;n�ey�b���g�����n>Ar�D��f�t��\�4��9�Mt�K��^i�:�Z�?��X��i�o��#O�%��Fg����Zt��́�ْ�/�)�q�%$�Ğ�14�^zLS����YA���ʥ��U=�p�H#i;��޷q�,��m@��&靎3�ufd.럂)ڤ��W�w���ѫ������U4��Y��*��a{K*|Ie/%D鸃��J��rB�a<�����&���ɚ#qf�N���6�%Oa!�pa�������T��Zm�V�X�q��6/J�cx+����}�|>Z�ѽ"�7-��:�R�ަ�7�u"M��P9S��j��6<��d^��W���!��sA4�a�g[�2�Q�}�?!��?D�4s&ș�cZ>N`�z&����RJ$W-ڒ%�O]���,J��%cѢ�N.\R���Rk��x|�����Y2p�ʆQ�O+|�����t��v9���>`�$W��o0��Ӈ	H+�KQMn(ߩ�H�[���Ah���de5�.FE*�~L�]�̰��d�t ���"�u(�,C�CD�Q`\z 	�}�xf�m�:Z�XJ+D�����<&@���DPz�âoq�nl�����7��J�d
z-��(,`����r�R�S�$�U'c~řJX*�?�׫�����O׿������)£D^�~���b�I<�h��]E�	��v, 7>s�+�MQ��������[T�P�W�c���ɜ'���C���\1��Dp�e{���	&���5OS�M.A5�Կc�!��	z��@N{"f?]�gHM�y��5�&�b!�R�-B"����u�f�w��Ss@��.ږ��a݉��)���A�Ԫ\�3�����������A����n7�N6����y��t〆�4��p�U�^KD5�έ�ƣ�Q�vÞ?�7O%6Y���R$�).�(�����B=YSQk��k>a��^��Ix�Ƭ4�Ef:�&�PJŊ[��XNY�]e�7�1n���\�D[��hTcĮ�� �+j���o��B��Z5az�)���fz��*�]-��E4@�[��0��;����Ōo_;0\	��H!C���'�+���{c���K\���!~_��z>��5�$r/�������ρ��þI9sO%�p̃ږ���w�b�p��+��CJ�*t�.��Ӡ�ػp��X+���в�x�����0RT�9·7�~
��d ���S���efA~ P=��Uf{�St��/�](����O�>�qI�:��t���dD��eNW���X'JLC>�=ETC�>3ɐ�3!�Y(vz]��.�wz�&4��J�KuD;u����|������<t�o���7���B�|����������n�Ra𣺽�'��P���?����']4Z�������������y,������������l�R�����T�����iV�-c`-��ǳ���_ʻ�J����[[��/O�*�$�(�
-�Ȝ��n��^�����ڃ�f����*w<����F�
ȝ:��}����Z�c�t�VC%<���1X��9��5��㲧9�pX����GC�m�����kQ��M%���qp�����MvC�1N�k�39hZ��!�E7�j�-�� "i�M��p:�vAktl�ھ��о@��D�/�>r�-�{t҄���ڠ��FƦ$�Fgکi�7�27)��t����A8�v?H��Z�������F��Me&�][i���mH�����/=�0��66�@�,�<ΆAAD!.`#�[/���C�]����u�D�4	fX[��a���$��4����#��$�� @��\K9&��<0��b��A�Bnd�Ww�=����+ıIQU��t\��CN�`xa�а��~�T�t��� �-�C�;=�_�1���P�����$GGa襕������;k��5;�h�G-B7�E�[�P"�+UC���@>�C �������/
@�-\p���{\v����A*��c�*�+c�^�+�be뼲]�~_���|H�+3�F������p�ClO,,���@���/�s�t鋏l"<%���f{���7�.��/�Uqʱ�'V4��{���q�_a��{��9/��)�4U���j�]V7��BGށc�PU���ĂLH3�Vǻ!S��ɞK4���Ґu���.Ӫ�xx>/�
���]EL̂�W�h<�b��~�]c"Y�b�m܁�o(�(�d��V��b��b�%*H��O^�3����������,��J���ug�6�n
��d�ir�?��S��)�g�a�����9��d��B��x(��y���|Or~Q��b��^Ă�B�Q��b�p�J[٥7pJ�`�RO�>�^dNSo�%���n+}���"��ϑ��*K��`s�f�Q�&�s���r�^��V�z�|��89��o� v(����[(���(ܕ"��z*�Yv�Tl����C�ɲc�%�D%٤��H��S6��jd�e�,���E6���(���L;�[�w:)b@	�����&�Fr�����P���zM��}����Q�͜]�!
u��&uKv�)��B/�n ������	41�QN�)>�`���[���]#%E�Z[9��CXN���0��Io��d�q(�����\�r�)������Z G%��gXjN�?~E_v�ݻ���Z��$ ��Ё�����O�?&�@g�p����� e?ө:�c'���s�2���#��㝦7=,��t9-�[L)����Í%N�d22���:`�ތ�m�pT��L�%�4Cx�j�F��
��2��Ѽ��H_�B�fTS4�,#����t��@>}fH�E���6aѢB�;������P\96c,.��1c@�9���|��t�g�g��/&��3\��}�{�g��<���H���9�M��\��mtZeCrP�E���_��:ڨ�'WK���G��̀t���
��"SL]���a�n�0����WP�v�;���)b]g�u]߹ʴnR��ؔ��ĠƮP��3��2���Z�:��7�<�~UX�Fn�rM�`�Q3-�+�%��H�kZO(�|�c�U�7��> �Q�^�W^����EW�M�<��=�ʍ�uR���J�=�; A$�Lb� ֛3�����(��k�\�`^L���K23z�nu �0\��ЄU����~��]o;g�@�+�Pkq\�*�㥝C�W�)�QiP���D��c:�b0I�p��)Y�iq�;�r �	(L�dt����Ѵ�xě-�9	�8��W��H���S{xBV��K��Q��n�����O�Bϣ�8���<�,�!#!��`���ْ�A��٘�jN��e#-�x��#@��6R���\�K�)T�4��Q�T�/�A(ݣz��h%���.��4@�il�XW4�v���i�N�MҢ��wZغ�Eyշ?Q�qu�*Tm���K��m�49�4�F�'��:�Iɥ���U��b��/�U�&�M�ڱ�����&�)��ΰ�Qxu�]�y�YF�-���c�VM�{�hYV�n��0"�Rv�q��lNFr"z8�J�&��5-dS=��),�LJ(BǢ�1�-MH�8�.�3�L�5�4S�U�]D�u�bNHef?LWvuDYrt&����^���OO��H:$�Ѝh��B�?����@薢�T���8Vvh\��Z�Ph4b����M���S��z��V�C� U*üB��/* x���R=cv�ZX��M�*`��UA�>�j߃*��U怸L�������+b&܏9������p���,��U��+L`����+U6x`�m�:a�;��T��Q1��2vgo\�k[�"i��D���G!}�¸v�F�Oa�K�XW�{�|^��N��;^���d��f���:�PG��;hi��Hhm-�M]	��~�Xd�¤�K쌡�"V_�A�����A㉣��T�����T+���Ա2�}$7F%�4D��8��,P��BG����d?�([��5���Ff�K�2� PC��+�O�$���x��L������6�(p�2�sm��pQp�6�]ۤkg�������Ӂ�#�:6:D��S#�jb^��8P�ǲ'4�`�Jv�U~đ�'�2�"����~ɘ$��sZZ��S^t�2uKԏ硳�I��G��!L�ZH��(62L�Ǳ���4ML���)@#��$`��('�*�{��D>��h[.��L�}��bc�5F�x���	���>�M�p�������H`3n��Ut�z/�0r����Q�'ٚ�N/|0і�x��>�8�v0�.*$�p��l�)�"�6����ֿ�I���kRWt)��f��2�F�e��r��� ���+f��a�u�\����@����`��l0�w1^��� ��@�l� }5�x��ĝ7��.b�pӍ�	\LDN&~4�"~�`#�;�eF����@�׎7"~�𦁼/�o�����*��I�i��bt�4Cm�~=D�xV���T�����Ŕ4^�Ͻ�E����k��s��P!ý�+���./��������I�T�h��H��R���m���O��wɁ1���~�x�F��2��{�/A�����nF�'Y�fm�d��K�Y��!�)[f�d�өj�����һ��0����VDf��9�����&4<��$�J�{��v�@_�~v���I���%�s����_O�d��̷��翲�{g�����S<	���1��w+;��������3<������iq��ռ�_���+��^/���m^�;ɋ��-���8n�i�Tܟ��y�M�u!|������E!�+wN���йuC����[k<w�eܡv���a���ڇ�{���ɜ��_!{��+��qr_��4 �"3~����̐i���e�U2��C[o�ӻ�o������l��P�厢~�/E�S+�j^�8k{9�_��"eS����VX�$�"�) Z��lUc ����q�5�`�����X�x~]�9P\�)&e.s��7�;��1�%��_�k��HD��� 	&��K�иś{�K�ɠǼ��3��+��5(�//�cr��\�Ll�}��׼:���W�H�@n�r�`I�T-��t.H�\Q6'�7��1,�?6S4"�ܝɹ�p��L�HF쩀���eR�I�����H����Y������0�}��Q&���,fl kv�����Q�E��\D�}��QR����}��������j9�w_4h�F��Y_��C(�S��;%nO����+N�S��o�@�e�P����M�ĵ��׮��{~e�Q}�L�J�W�5�6Z,J�(#�|�D���>B�� s}@���j�|ǭ��	��ϋ�r�t�hB�$�.2�p���D�
`4E{+_�6�A�Xdl�����f�)��D�P�n6��pT��.&7g�����'>���:���������;K�ϓ<<��r�@\�WX"
/�.�CU|�n[��-%��n���L����Rr+�RT��]�ނS�+njx_N/�Y
�Y<���:���������<���:�������x����c���Vw��)�cy9���sb{�uL��*�J���������������Yaz\
��^���3}���pq��s��;Q���aĉ�$����T;dSUwg(�&F1hϥo�\�ߥ�k���l�t)%�9Z�y!��'�4��6�.��<�p,�����ve��=ͣ��YL���Nuw�����,��'yQ�R�����n�����x��ͷ����N��l��O�7�:�����S��[�,�O�,�>����7��y ĸhFǉx�	�M�����R~R��0�(^���urF�tzF�3~&�^%��ؠ��Cᐽ+z�Xߡ���~��W������L�;�:���[[����S]��O�,��$���Z���[���"Dd�D��nS�@��ax�9}�Qg�$�:u _x�|�	/���:5%漋_���>� ����+"M�_Bo�!v��k��P�Y�;��NO�����o������{A�ڢi�<�36
��2���7��V�eZ�o-��>��u�z���1wJ��a�%�_��^1�����[G������vk�������oN���V���~���g~���}�]��׋`�,�{���6�!5�[���lwy��<�{�8hZ�����k8?�9��/QC�{b����/��>�oty|S���Ύ����ޡ�x�r�?�3����k+�}�k�h���,Y�͹
O���>֎�NQY��~�F#Ȫ���������ǰM�u���� ʻ�c2��({�0�����7�Vl���!�!b1?ݹ�����Nؗ7���L��LPNY��rZ���v)8bLQ��@��j�X��T�m�({~m�Ա�h�ٌ��O�!�v:İ�v�}�}~Nh�V����7%�xM��,�u��l�c�q	�J�o)QG����%3�H�E6�%��b\�Y6^�v�䟵"K��&~[�X�<5~��x��7�?p/�W�e�����O���p0T�?�jW���q�ʷ)|��*�J"[�"WO�-ǻ��(t�x8G�s�Q|�)1E���AݵC��ɀ����\oK&��{!�?��n�v�_M�CG޺�������I��>������K�\��!F�����u�2�D�8�h�q��@���3��ɂ�6��ޣ�os֖@ i�2}�xGa�wސrB�|$z�E�>�C���L�kO��g�u}s�c��/R���VQ�#�ϥ���g����_��ʥ�x�M�(dT�2�}X�RI�y0����2�n�ߴj��M�@�/����F�{w���iԾwPY4�S�C�x��y{I	1<�JS�W�+�������U��RxOXR�S�eky�Q%ou�똦�m����=[�O�,�����{�w�7����

�wc�W�[���*.�t�?rI�U��ηr��?��_�'���v?�YSqhz��WoX�n���.L��c/^�R8��12o��_*���2����ti����Xެnnmno�l>{9���N[����ƷBUq���(Y�%7f��p�G�݇`_{^>�g�,��~�?�1Z h 