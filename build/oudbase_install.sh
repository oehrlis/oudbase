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
� �C]Z �}]w9���q�s���!9瞜KqV�V��d�p�ޥEڣ]}]Q��\۫�"[b��nnwS��֞<�<&�y�o�/��!? U����(�3Ә���
�B�P(
��]y���Z�nmn2��)��Z�����j���V}���Yc�Zm�i�	�|h�0M<�p�1��lggS��v��L�)��3�@���W�P����ol>�c�����ՍM������V} \b�W��K�� �� ��J�K ���o�����֥ѷ<�z�ƞO<�6=���Ks�G��߲�d<v\��<ow�P�k��kZ���g��7k���f����N���X���2ݡa����12�<5�6��ck�W|���a�s�-��^�y���л?�� �3�ҝ������o���?���o~X��?�,G��Y��"?�l�w�x&��x�u{�5���s��̲�iv�d����k�������p|ӓ��=~��^��g�ٙ�2Ӿ�\ǦN��8��n��j�Dx�A�Bml��c�Q��C��)R��)案7ޭ@�=p��^7�Z+W�)׫���1�(��ؖoCvi�HF�S��k5̳%��?�B3��3;6sΐS����%��:#�'���=g~��v�}rtpp|��o>*O�R��?ǡWv���!б�����#pm#���^É�ݣA�ם����~z3�>hv�����ѫN�͙��w�ӡɆ�9;���1� X ��n��������)A6����>�9<>�o�u���p�+T���Ó��Qg����f���yz�bgj/|�2�T���B!�����O��ڝ�f��P<���m��J�7l�5�px/�wS�1�
���^kg��nu��&��׀Y�r�����f5�r��{��{1�{�T�an���L��^yƹ�Rd���my�q�3,�vd�����U����Y~g��k��ע���4�tY�b���������<c�6�Ԉ~{~���h�r��`�g�}R%��I�N��'�L��R�2�x�HI)�&���M?�9Z=�K) �v�I��%�o���f�r�Nlϰ�5n
�D�=�7l,^�,I)�L�&!>%'��u�I<��q��%J���:co�e톕�}Ve������fnM�n����X>�W�X�����Z�/"��W�?�r7���u�Ck�3�Q�5"�e4~��NT_)�>R;w�_�$Y���z�Ą�@�5.L��{��>g�&���큼��P��! 3���f[����$��`r�$,_d�xg�s|�wK����W?�����|�}㫽�W�|��o��GG�E��iv��w���OX�Vo>�fX�ߵ�$���G@�&4���<k2�D��*Յiy������!N�8���o��d(�1(����`�l0��Oo`����� �=a����%\��V�m[�y9�u�-�N˪�4�ھc�qٴ�n{�,�M_�����x!��N����l21��� �h�ė�<	�	�\Cqd��9�+̴1�YW5%;HT�ށf�m�bt���%�93F��&M�p�'�D�ʬ�kB����������j�y����
N��y�o΄�j%�6 ���o;>u���-!�[�oTG���N�ݜ<ou#�BϬ��Q=��`�qiXC����j� o;�a� �Τ7�+>l�F�[�:F��+|�� أR�H���g����l���3h��W�o�,�q]���'-B/>�5�8��;�m�_�M��F�����\�ST�D�볠�Y�G�U\�V9zފp4�M ����l��"�{h����� ��,��	���l�s�ڑBC֑�hU v�<R�&���Y���S�{T���e��_d)��M1�R�#ɮ�6����m��~��ye_�Ε͛���0�4��Ą��ӑ9r.A�6Q��c>(*'�HYV雗{2��
>�3'�c/c���a�����q$'0)X@@�\\X��9���l\u��N�3��t1ʗ�r�U:mYY���3��\�;T�O3N:���'��V�G>�j�֪Pֵ�D���seVX9CiN=%����btԱ.0��1��9�l�	]z�S:Ŗ�px�_>��PԸ�k@������o��t��@k~�J�zD�KM�PY��H�#u��s�BX���3�{ٸ��]c��Z�6�y\K�rB: ��)HNP@dT�)1���7��&sz���t���s�w���z������	M̆C���p�|�;�u�(��V�����i�������U��䖹�"t/�}X�f�޵��Ȧ�@���\��|܎���G�C5���u��s����:F#~�NQ��d(�����ª:Q�Z(�z�Pf�d\���-:�Qu�͕5asf�V�n=�yV�A)���`$è�m-������{�k@J3q���uFB�6��OZi��d1`j��0��ΠSF�1AO�x����i�'�$�L �%�r_.`Y$��(���7���ԗ ����M[4䆓�7b���6m��;Ĝ%fbK��lD��2xN�,���m�̵L�kxc;%@��O�]gl��ez�)��4
����k�M,����wAlS?әj.�fq�o��5-��Cl�,��@2}�S����q���K[�*.TJ�e��ԏLNύ��e;mn�M��5�Dtp@T\�����G5�P����WygWX�ۛ� ΁�S�Y�j( S��?�IHl|�bIl�tM�V5�x]�OV�a]���r,��z4�Z�E)@���e�Vw��˰jT�ܓB�.�bAf���/�r���p!��n�_�`"�)��J��GK�Zo�tr�{+��[~�y�����̿�K�`��~��y�p�نɡY��/h���Sce�?��}���r�P�W�[�Z��=���Ш��:��̀�E��-��m���$�wz��"᪍�@��G��f-����x7ՈJR�קae�O��Z�������w�;��_�(�*`����rF�bF�zG�n��Bh�eg�Sd/+��j���SO�,f�G�=�4���*uӚ�֭�f�;��F]��D�r�:C!��24p<4��
ƽa�/�F����_����4�! y}����c�����ͺƺ�>}k:X�.b�X���z���܅����oT��~mm֫U����2���H���g���/��W8�0I��u��~鮿_���r���GZ��:�	�>�v�{��=��:��",z�|��ÿlg��z���Q}xE.��诛�-��pޘ�h�+��wJë�]v��;��n�]�l�l�N��R:ּ���a�X�'�|d�G�e>���,�|d3��GV���w����<u��<dg��|Uo髺 ?���U������� kg�us�_� ��@m�k�=�v��} ��||�[c�7jX���=��^7ŭnPaE�y2�'4�z�wk�w�r^|0�������]��؋�m��Bj��R�}����v�H��F�:��B�qh,�%�sM\���>�iL�b��<(���Uƞ8n=o�+J�H�8�����5�8�d�^Z�}�M|���C���޴���oDׄy"
�]B�S� ��� ��,���[ǭ��*�KMl�-6$\KI_��+������7܉р��	Q�H0��[y�]��
�]|�X�W�w��r1l���
(w���68�Y�|=��il-J�\.�(�"c��.[^[f�_Q�}����+��D����!��lXo7�1}S2�<����<?������t�n�}H,��S
�x��-�B�C	Zy��'e��2=�<c��)�[���D�@PF?�����W����(�H[���zJ�E}ʢ#,{�(�4�1ϙ�=S���!�*�*Q���u-/�@�{����pν���4�N-�@NI�#�.����b��tʽL����[>eI˭�����]Tb�wVp��dn�?@��q|.M���kudrй�߾m������r1&��p���ި0��9��A�B��蛥�as@�s]f��.��._���,��9*�Tԭl|���x�3Cs?)|��qs�v�ztz�z���H�����v��]P�����^u}� �ٿ�p��as�4p<�A'�i.������D�,���Q�"�B �B͓�q-,�˿�j��%�4/}a"׈�`�3��i�����#S̓-���w+��[?Z��7�"��ڼμ�#�3|S��rC��|�N������|`%��*G�N����=�#�K��D�\Y���u��h>O�����Mz��;�e�5(0���~��v�fm�ǌ�w��5P?e�,u���4]<Yk����X�xM��Eg�$�%�$�OL���>���}i�ZU����%ԅ�PĮ�S"A.�H�S5!,f����c>v����ē�g���\�\�?k�[��Y����?#e�����3p��Oޠ_����2�?���ruK˳g����Dk�(t]���s�3�%�s�� ���JӠ�<J����6�죺��p�-z��;w�x�d�=���zl����67nG ۟�Na@@�ޘ����@֌�u��/���9��G��"���8�<h��>�Y���K44H�c8P�[eg�����?n�f>�w��/�'7�[���R�On擛�䖾$�ܹ\r3���)�nN�B��;�fδS�eδ�3��ʙv�q2�@GZ�a5F��C���� 3U�3�c8�.2�e�5Ϙy�f^�?c�Q�=7��(��/�h8�S?�9>�>]a��/pv6�hW�O�$���"��1'C�mb�\�������9y���i�@����s����7��G��)������^�t;�y���
1��
�T݉����i�C
�]Ԏ�;��#ax�EX��l`�5���=;���!A֛�y���q�Λ_�'r��G2��������B�
U�WYp9eƸv�poVEj�x�ӛ���"*J�e�Ȏ'wބ��F7������lᣎ�R(�iNwQ�U�%��X�c��m�>���n�cA�^�d�7t+��;��F���,��?�e�����,��3�&���p�m�]D��Nj�;M���B�*F��D�1\��8�]C>���)�Ԙ��K!��M&�nl���De�q,��8���8���y⠾�S�\Ţ�;;�v&����Y/��s�G����w𪜞%hJݴ�1g�G�=��M�	��)�-2���Oh��
�P��y�j�������+��#3q��Lz3��	g�t��W��.�n��;~��-��\�o�>�������|�Y�������F�)�׷������֟�g�ߏ���?��'��ɓ=�����h�wO�������?��/��| [��G�����?D��+���=y�w�����xh����0���ƿƿ�<�/�od�\�M\�y��#t�y����ϑ���|:4w���ɓ�Z�O�����������=
�}�I�Q��>�7`�ף�������H����s�#���9����):���Ly�Qxr#z�hv
�!N�T�@����q"hSa�� ��E�ga���B9�N��tO� �s�?A��#̄|
��w�M��Ah�AN\�kg�vM\롛˥�Z����h�,��-�M���{"��x�f��e}X��&���
�Y"�.�+�B�;����ӲYE���u��ʼ������6| 	&?���#�^Ij�C$�C�|��ݭ�ݓ�W�ヽ����ʐ�r:iQ
�țJ�	e[��������z��e�9��0�v �L��
h���r��/$H
Lh�T�
B0Q`H7z�*j��ek�0:qŕE��]���9��'��X���&c�h�U,�g���^Aߠ8gԉXY��м2\S�b�'�X�������"�����`�RV��v�1�M׆���ǣ��%nք��� vݓ�~�5�O�k;$#���8��(�mU�x|mS^���]� � g�:���:wûĺ�/I"�EEU�P2�������sq)'���μ��R�����*����r79��m3t‬ kz�݃��nS���M�^�I��2a��E\X1��VǍ����9�\jj��|�+�ñ����
(�q��?�%P��+�3;�K0��|Q��XQy�n$�P��x�B���i �$V+���,DR��R�$��n����2��
	RKz�"(*�?1D/�5.1_��/�O��t@"M���tH<�z�0}������IȽ�P�8�r��e8��[�@��s��>>8������Ë��?7r
nEr��׺�LJ�H?�������D*|ԋܐ�/D�.����ٳȝ����0ڑ �Eh�I<��G���ȭ���M����
�:��q�N��=�/���w��1�x��p�l����R�:p�\V.5y���������xf��������^Y��&B�|y+��DWC3��@���N����?7�_Yp	d�+��)`	z��Rf�~�����Q�<��yW�{�"��i¾!]P���)�$��(Ǡ�����{��Ұw�C�L��"F��::��*����9�l28>�O��� 0���o)���gg�G�$en������Fۣ�ĺ���9��;p�[�����t>��e�9k�p���,�h�_�c(���F^��ӓ#���d�� ���#B1�M�.,�t���b����mYB��c��,�H'��:H+�!Ib�ĵ#�&��v\xs�Wx'�)�΋֫�cտ&�a��N�H��U��6�8��y!��}	����5ϥ���y�|�h#�z0�vu�4<_�I�3�4�+���L�˓�-Q~��H&s���d@ oV���O=���������=vj¤��2Y�A�&8�P����d�4/���w(Ď��K�I��
�v��rx��K���F�/qs���6���� �[,r�tHo��R?�eM`�Q1��x�
ϼ����/�.���Ew~��6n�����_z���b�Ñ�Z�����^|�=��͙�̶R�Hq���W,�����;G'�r΅����N������(�Kk(�0�6$�H
6��%�/	�"Jv�	�7��Ǆ1��ت ���	ځR �d)
�������:P>�ޏu�jb([qw�i�|�S}���B�c�y���	F�Rqh�Ro�Q�WϾ�n�C��L�T'f��yE֓nw7��E���)�w����.��G��h�E��C��P�d�Ū�Tf��e�������Vs:c&&�IA��[�!� /&�����y;-)H9�|�L�E�$<�w>Q��b͚Hx��t�iI.ӝ��l*�6��/��vy;C�u���6�1�wV�C�rw��:��k��1:c_�jU�~��6�oO�
誄�R�&|�;� w<l ��&z�$U���+X	+sL|x=��N�1av.�[*�;���s���� ��%=�Y�5qU̍uD���*Grh*RWԦ7/8ݮ�n���-W!U'�)g�t�a���p6��3�|$�p84�"]���!J��%���t�c��\8&ڀD"�P�"$x��u�9��/�O\�l�so|a]ո���$�h|���@ �S'*42�l�\!���K����ۦ���V�s�2^�SE�+���Kh�3m��F�h?J��bu�J������"k�Vc����:�HU_$Uo)��e�dյ3q�(LUKRX�Х��n�yq�":�J�����6T�W�����MR~���ֿ�&9�@���Oן��.�(Bޯ����]$�OX%�`t�=e����.bc+�H^u���U�G��)kX�Dt���]<c�s�!�\R'=��] )�'�9�����0ݡ����ر�F��:�Ho����pa��
���ť�\Q�#Ӄ�����֔G��+Y*�������������a#�����4l�f��2ǢX5=��{:�@Ρ<0������h�����tG�R8��
��V�K$��=��s̮L���!7ָ��2+<& ����(S@��8I��1q"ɭc�E��"��x��e�U�D�Q���_����o�ۮD^�~	��B�I<�`&�x<��	���l��`|�+�A���2cd�s�e۱KJ���q��/�l:�I<��Ϸzt�
�C�c(;0]�N0���C�	�;��8�"tP3KO��TH8��Ǽ!��Ac���!�#��<���	�����j�J����"�"������"jG�4?�:桥Lq����0OYW�m�"ŭ�%��C��6�4��Xz"��I��h���C�`��y�m6Ģ[�I:O�$)X����.�,���֫�UO�4œ�6f%U.G(��b�#(5e�Cn+��;X�4��,���b�*M�L�qӴOE(��ӉYI\�.i>_1(!�'8-�k�4j�>��������i@�ya�l(Fˆf�l���F���L<�;��p��1_���҃P�_�!d�QEp�t�Mk�a�Z	+����kP����� ���
�ie��Ix���C���\r0�3>;/P�}�{8&�gqnF_e�q�1K��S�n����G����,̝��V~�[=�L�酅ϥ�q��2��>��n�_+!�\Nχ��.���H�tl"�f!������|9��?9xI/�)�烓ϳ!�C$F��s����)NW�Ώ����@Bz�XgB�b=�S�K҇h7[=������B��:���^`K�"`��o(�$R����_�?�I>x�o�<N��c�v��efl�<���vn��hZ$/�D�C�n,�)����H�G�B_8�pK�R�sGb�<I��<h��a����V�ت�0�O�����m>(V"�����L-X��{(.�}��od��8���v�?���)��Ӎu�����j�������:��^�<�?P@��i��^ݪ�"��^ݨg��#-�2�.���ږ68P}�:��?���C�P���۷~�[��h<�m�
Ƚ":�*|<Z�p���:t��5�p_�{`2�������Yk�q���N��4�h:��_a󰒃-8����`�h����7�z��C���+��q�l�0o��-��!��S8^M��q�D$� X>?�������"B;EC��?u���8t��]�zf���ے��i���[c��_�L/'�a{�d�0�X��`�a�pՇ�+X=����k*�(�r��iV�8`�����<
v��j�juU�e����"(��c��tb�hoY,t��*\�{�;�!�ҳ�ԲaIeB�I�Sh��Z0Ҝ5��]k����jB7�D���+��^�0�f�r-�7m,�q�(���|���ʮeO>��{����7`�8�)�"������t�a�f��Fo-�f4=���]���~j�zޓA�c_����X�.�){2�tW���q눯K�<��~Zh1���,��Zfop� %��RE!tj�䃱>bQ=�� ���� �ܺ� ��k����^���1"X��`��+��Xi��@u�Z�T[?�m4�_76�&gq�^�������rM\J�m�kǦ7�' ������O�w��g��TxJXA	������oh��?��+a{���Z�,.2R��Y��w�)��Y�"4U����}�2��)����L��CUN�jVR,�\�^f#�ؚ�G�\�!������H߶ vG�<��>��-'UA���Y�
��V�]D��ax�5%�%*���9g>F����2���,B��,ƽ�"��c>���f�ҰH�X΂ɽ��Yw�h`3�_�M柦�9����~��KQ��aG`���v�9��`��B�Ty(���q��|�r~QKʕNWWň�1<����������#��'�^�)m��H=����\:C�9E|Cx-�)wd�}8"�Np���LR|@�(�L��(J#�9Q\`�h/~Ө��y�}Ew��y�WT ;�;t��)����4���A�c�Bj�B�&���6�]Y=��,�B�$�&
(H�DR2�jp�)�U#�(�x�ɼ��y������3m
���t�	Ā4-9�6��,��8G�����Gs���z�R#0>�-���;��C��6UM��3X��~�=�{��ˎ��hb�������#��*���+�� RވX�b�#���sh �iV�Fy���ۍ�����7�N+9�J�7a���ßZ g�}8��WsR��#�О�s��1�{?�5`��[02,��^D�#��Ƒ/�8\`��E��k�������r5��ro��]4qM�4��aq�`�+�i1�bFaEN�D.�8v����p�d�S'eћA�!���K�t��x� qn�A��/0�|š3��%F������` Ηఖ�#������⨡�����0Kl5XT�p�)ܾ�j�̘csFf�4s�g\P�F�[�>ܞ����U3_f3���^�;�g笳�$� Һ���o�%-�{~Z���d�|�|1�>N����R��vĉ7!3 �@@|����S%0�\�c���9#�����<����o�u�)�uC�"�~����m��Jj<ʾI��&/�e���	X�G"�����6r��Đk�evĳԂ�S ~r����������:��Z����y����W2u4t�MoM.�ք����reb�kd��p]�� �R&�I��	�S��>�[B"�k�\�`^||3ا��XNЛ?q���Z��&��\���h���mx� h#|��k-�P%p����U���,S�D�H�ð�:�b0I�p��)Y�iq�;�r �q9|������7���^?�n���$�iq�"-FFp~S��)q��5iCG�7}�C�?A=�5�����l���2@#!KO���Q�3�~
�\=H�<Vs̳-�`a�s��؝�`�s�.��P����Gu[Y�`�t��
G8���fv1��p�����H����K�iD١IcZT�^�N[�(/���nD���U۫!��������ͻ��!zOO1���1Y^%J-6%��2�P�j�[c�^�9Z�<�cԘ����E:W�H#�:�h���C}�Oժi��^�Z��[7TB��bv�4��֦#9=�{�h�S͋���FB�tV֕
�cA#
�N)Nx���Mp�G�*M�i�Dj�|��R���#ĕ]P�|̉�:e���� ����+���7t�!���D8��c4�J�6V�+6���魖"�X���y��%�㷞1����"@��H�P)�
 �y��A�TϘ\�v-�L�F�sX��̪ m�%��N�
VH*��Gc�3l�ja���	��&�G��=Ÿ4zjvU��
�� �<�J�Xi�'=�r6�����r��^�bGpq���f��.��I�jP�^^�(į_Jkwp�H���E��u�zR�؈��#^*��d�f���Z��PK��	;hq�R$��Ҧ��zF��[��xa��%v�(�?_}탽��~���6Ծc-���T+��I�X	'X��z����
��hxJ��G��i���T�,����GW��$3mGn�N �!qZ�gW�\Qmw��j�E��P�^
�Yr��&�k�(8Q�?u.Mҵ��l��b������!q�5#�p���51�����*�>���7.`��C��S��<C�@�C��:@��vrG�qy���N���|27i5�pHa#�)�P ���S�F�����������@Ѳ1h`��L�b�D^E{������UK��E���?P�^����o�;�_�g���N#!�s�nr	�ڥ"(�����;�{������&7�"=��d���m�wl�c�kGqc�b���φ��H�!0�Da���L�;��^J�X����I&�0�HD��7�.�
,�����q�b�pK�t~4q.��s��C�),����`
�b��9�QC� ��@�l� }1�p����7��,�k�.���L�$�"~�`=H�;�%F�/B����
�acO^Mȷi�x�d�����sy:9G����V�"A<+��[�������4^�Ͻ�E����K��{��P!ý��}�"/���qY����&�:&~�Jy�b#�[eo;����B(��~Wx�"�&�#�G����(_�BE"ܮ���*�̈́d����>�������2e�5&=���j�� .�vNi/̀)f|-�Q�>��쮮��,;�yET�Uvw�;��N	�>���?p��A�(����j������c��?˃�1��Wu�����_[�nn>�����f5;��i�7t��9f̧MΙ ^a��`� Uk�\c�'�e�����Θ&�߲���V���E(�5�s<����=��o��׵�:{94|�ԝ����.�X?�.?{ �q=Z橡nf§��8�����3�H�$�V@)���+���  NVP�ӷ��ta���m����w@���	��rd^Z8;Ų�<�Tw.y!\�����dxJ��xZ��[�� ���$��o$<N3'��qQ�u�%�f!|�F��:�}g�j��-t;n�c�ru�s�Sh�&ﮒ'�BpW��n_ǡsm����[G��'y��H$�Zs�����wW�6�=[�9{��~��M�崩�����Z��y Y��!���h�h<u%� 1��a�m}aN�T�U> 3��E����Z�(�׹S�ZavP�bh�y��	�r�)F���Q�Zyy��^� ���*R �w��&?\��͟p?F��
�ۯ��{'@qѦ���p�	���S����j.��IX���H0y�d���ƍ �[�=9&� ��k.G���P�_^��r��b9�:��yu8畯�ρܬ����o�\8v��-�
�Y�1faY��L��Pr�����-�2A#���4	��I�G AR����Ah��3�o����4v���;�m6��3�':�d*7��C��W��{��q���w��`N��.0�����_%A�";��*{�p��j�'��`�T���,�MPl�:�;+� 7oW�LmJq���b�
�x����$�K�i._Z��q�<��2ٸ�j/�˚1�T��4~�:>�K���T�]ҭ!�\�Q�o�|�n��{�͋�rǅ���d�b�MF��8��Z���`����D��#	��R��|^��ޏx�����S' �v���V�����,�J��=b
�/=\3�?���V4����Ff�y����(n�� ⪼�"p�v���Cp5�\W^v���mx�
��o����n��2�㻈�N����4��ނ�ɍyS�1���1k������O���	�>tw������#�y凮�N�[Y�?F
O�>\����	�A������� u�~��o��Y�?F��5<L���f}k��s3���b�8��ۏ��Z6�?NJ�ر�:������:��T�7�n<�������#-1=.Qn����g��>�ņ����3��n���r�RDBy��=���E��M����5F^.ǯ1¿:�R�qe�>"z����G�{ǓQ�*�N&r�֯'���f�,=`J���:n?�o�kO���1Rj���1c������V=��%eN������u�ݕ"-��A$�a�wW��>�n�\�>�nbS�jS�:=�l:;��w�?���W��06�adQ8d炞x67���~����E�&S�~�))��1��o�����O����1R6�g����}@@���c>�|���hxW�y1�fg��P��b��8�|V�G-�r��߰U�����ՏXHvV�ًW��x}	|����ހ={��!��ɬ����r@����,��ҡu����V_[_�X�\{z'r��ou�:�ǭ/�����x��׉����/��v�����J3��/��Y��&<��ߍ�V��-������O��ګih;��\����B�u9c�����֎zLI��@A�_W�m���������hl�F&AT��@�1�`ẉ�d2O�\�/�&���F1���{����t�^�w8�z�P^�G-�4T��d9�vZ]J�CT�g�zM��>�AO�t����
[���W,�������sׁ��4(a��1�u>5��ޏ	]�d��ܒ�[����mh߽I�a�q�x�Kt���V"t8u	>/�PArg�l!�ǯ	���M�7��?o-}Q|V5��.��qd*p�ĝ�3�=d'�'���vl�����a0>���:bK,# Yb%�0��IT˰�г���ŋ�#8W�����w�-
��9%�\��n�yd#�ư}�i�>��Q�~:7�\/���d��B.��_��&�� ���Mq��K�MG\9�{�a��8z�U�-���=����Q��`���n_�Bl��<�uέ^�Á9�;�:%x�X��\L���oW�}�$D�{�.�����зJX� ���o�Ro�Z`3�?t����;���zv��Q����˝���������;"RY4�_����~�hg�}���~u�s��ɫ�v��=y��:����9�:ģ��3c�-֋,K�R�z[`��?���:��o>�Z���c$˾4m��O��cs'�Ȑ����\�>7�Y�o�}����i���
�?�O���t=��y���T�O⍦�	��M@a���g-�G�ɏ`�Ib��� %3�C���v������
{�2�cRcw<�!H� hv��ݓ��f>���J^7��"׺���)�rSO��ч�2� I��3��3�<2���-��&gm	$�2�s5͸%|!u���^_��mU7���)�׊��������y�-�Vv�՜�7��$𯵠O�V��\H��5�|�9��<8�y��k��e�9�=���S�sö~"�x��$b�n���%��A�9^<RSo�-�� �Lԩ���[A�ܢ)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)Ks��k�-+ � 