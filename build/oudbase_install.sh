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
� �[,Z �}�vI��|Y�,�l?����s ���W�b7Z�D@j��%m����"QM�
SU Ŗ8�>Ǐ��_�M����#"/�YU�P��TvKBUeFFFFFFFFF�:n��=�J�������'��Jm��+���*���V�Ze�gs��#�y߈a��*�gO���Φ|�P��L�)��7�@��qP
��P����ml>�a�Wk��땍M������#V�\�W���SF8��~�1+..���^�--��\Z='`͗k��8p\;X˾��hh�!�-�G#����V� e:�}n����6�}�ƾ�n��ˁ�����|�u���G�Xno�H�[C��S�>6�a����Nh�Y.;����a+�X@�J��C(P�zC(��9�*��k�v�r����kN��Fu���rd_:�㹉,��v8�G^`sHρgX��;���;�៾���vm�[Ȭ��v8vY���H	/���q�1�0���r��5v��y>��K��\�T蜾7���V��O��t+Ԇ��a8
���9��"uʜb�8`q{��
�a�Wy�u+�R��dOc Q�q�б�������Z+U��gK�i�~ )�4f��f�\�!�@CK�08�l*��ΏV��z��@���U���������X��=Ջy`���^����7�@��a�G���`��!{m�vp��^��:;���\�yx��o5��G��y6gz�k�l6��ٙ?������tڍ���n�3�o��dCM������^����aK�B�x��s��>>8���/��Q�^��مڗ>n�f���R>�9n�|�n��G�<=�x����ۖ>j�߰�ל�� �M��,[Z����;��V���4������R��k5*9�#�ޓ܋��E��3pp�}g/�*������-'�k�a��#;).$��W-o/8g�����+^�w��b��gE�=�ѽ�<���~Ɗ-�Ԉ^k~���h����`�g�}Z%��i�N���'�!L��4��eZ�2���V�۷�4���h�tI.M ��;J�}/�}��6Z�owq�`{���'�K%�sx�F�ɒ	�݂	��$ħ�r��9�'��?��D�p��9g�-��ް�y�*���8��9���m�M���c'���>�n�=��V�I���F�Ϝ�Mn�s]�����eT�Ia��k��W
���Ν��W�0IV���ޤ1!%�u���f�_�`p�٩��8m� ����Ԯt��� 3���dQ;��A��1��T�������O���ab�Z������W��W������W���/|��V��hrQwFa�]��g�{�'�ը7��3���F�RJ�����F# Or�M�5�P�Af��´�TG��a�'`Dy�)�mV���J�j:�������P=]�q��X�o _µ�UܶeZ��3[�������ZK���y���M�g�����~:���>�����J��n���#� �@0~p�{P�fM|)ʓ���U�*{���\��0�&�g]\U�� Q!{�ɶA�!�%�����zc�4q�?�9(��1Mk(޻��z��+�U��Bf+8�慿9����� ,���ԩNg��<n>�aP<5�w�J�9y�����Y+�z;$��K��r�=�VgA��ƃA�q��W|�.�� 3�{���`�rI"��[��ގ�}�/�ϠavO/�1�|���B�N��������Ի��uQ6��7Z�	���z����B]�u�	Ҭ�Z�����V���nQ�\�6��A{�h�#-o`�,���m�IOhGqXǚbT���H�;�8&��r�x�ʐ?���(�~�"K���o
����Hve�������`����3��+����\��	�^3KC�MB��8�C��jj>�U�H9��ڳrϾ,���@�<P��9a;x�7�K���} �󀒜��\`�sqa�_��"�q��T[8��0[\�%(_J˕T�ee��֕gc9�;T�Чg2���'��V��>��V+Pֵ�D���s%��r��&�z�dwS��B|Ա0��1��9�l�	]z�S:͖gpx	�_>��H4��k@������o��t���h~�J�S=bҥ�W��M��ؑ:�	ǹ!,���YΝl����5by�a�<��s9!���$'( 2 *�����l��V�9]m��]��������Y~�{8�pB�� )<�|`��N|�!J���So����>j{j��Yx�+����2Wф�e!�kߜۻ����H�Ҙ�Z����&��A��Mc��v�>���n�?�U�`re:������Ҫ>Q�ZHI�}(32.F����ڨ>��J���9�k�b��K�<[2A)��15�aT����L�ξ�{��OJ�q�����B�6��򧭀�m�	05JJ��o���f�)#嘠O�x����i�GMW6���Ĺ/�XI�֋�Tk�M.�{e1�% X�x��%r���1E&�O��6֓�#f��3v�bR6���<'r�|۶x�;6��5�q�"��(�߇�7��б�^qEi�����&��P���6����L5�c�8��򍪑]��%�m�;��V���c��p�����Ö�����·P�&��V��7Iǃ��":8(��v�5BhQ�^*��6(�sˬ���� ΁�S�Y�k SS��?�I�l|���\���%�j��:z���ú���D��h���R�h}����˔a���%:�+�@7Z��ł�B�_��p)��Bj��<��:j"5)��J
����X/4���� �V������rg��Q�����
�����r�਽�C��-_�46q�����n�z>�A��R_�{���,�{Vf�Q+K��u�7��ʷ��>Ғ�ޙ=�
��1�:o�,��jB���E�n���:oN�ڄ?�B�4�G����YX��i���AC��e1�!H����g�y
����9O��l�� �fkog_�z&�bVo�sLcɹ+��&�aF�&uk���3zu�fN|�w�m���I8��o�ް��t#y}������h����YKe��1xm���f�`]l��5�֣�X?��ǧ���/w��"������_[��J��+����!R�����Հ����
'P&I�=�O��/�����O����xA�}�7��nʼ�����uή#?l ¢w��>��v^�'�݀ԇ�W������)���
wp�M��v���=�z^��{���u�8�dCf�wJ�	��S��,g�Ċ<�x�#��>�,��|dY�#���f>�BD>�#��\E�_�!;~�zK_��q~	��̯���Y���3��&; �� Ԗ��݁k�� o���W�Uvo.zúSo���C��u&��!�fZZ�z���	M�A��Z�+��Ϳo!�{�x/!�b}�"���h�e�W΁�u�j��a�Y�}�-$��p`����o�j�2���Nc3{t�AÆϮ2��q�y#YQJF"���N7����%[������ѧ�8̫09�ɹH��M�h�FLM�'��ޥ�}��{�Z������V�yS^�cQ��+�E��Dk)�4�@�J,�椽�wb &i�BB,9$�������n�.�C,J�K�w��r!j���RO�H{�Κ,���4�%�.��?p�1Dt�-�-3�� ľ�O����sǍuP*���^��w� l��Ϙ�-Y��Qc.-Ϗ x#�+����q���vZ�	lo�d���]� �ȓ�L\��k��O̖�-�_}�g (��^�ps$(��W��]RҖ;�BŮVo�\���K���R�ƣ5xc�k�:[)bQM^�jw��EH}/1�zjN���xɊ#������92�Z�[��N��)?���P��"^���J��
���-����y^ȥi��u��L:��۷�Ӂ�^�߿_.$$� ���f�4�����}��~}��7l�5��,�������	���(G�
���#Pڹ��wfh�'Kegܜ(�n�B���ܽ��i�!�9n��:f��}���D]_,�v�o�bqЃ�\,�� �FЉ|��cn.�44�7K�=�CT�ذ�N��I˺���}5^��@���0�D�Q0�]�F��~�)��C�Ȼ�{&��K
-P�Q��	�Co^{^���)d�C���]>Q'�4I�i@>�b@V���z[�gϞ�q�%HR
"	J��Џ�U�|H5�O��������;�e�5(0���^��u�am�Ì���5P?e�u����}<Yk�Jye,Ѽ��&���"�I���I����C}����F��/��K�W��]7֧D�\D��'�nBX̂�'���I�"�G_��ss}s]�V׷�������>D��?����p��Oޠ_����?���Re�ȳg����D� �(t]�����3�%�s驊�G�3��I�~��R�g]�A�J��?���ݝ�A�Q�Ϟs�t|=�sj���#�폇�0 �yol���m�r kF�:�����x�#�Q�b`�g�?gڐ=EV���Ҫ����0��Uv����{����n��\�������f>�TG擛��f>�ş�O�\.��Sn��yN�B�K:�fδS�eδ�3��ʙv�q2���aݩ���p�a	@f�Tgԇp�]dX��k4�1�ͼF�^�b{nN�Q�_
�p.�~s|��|���_��l�*�=j3��I�76�E���c�������)>��~s������fsy�/�v[�XDo�Kq�P��ϛ�zux�i��JO�R(ČR�+\JPAt'��*��PH)lvQ+�f�$j����Q�7����,̊c�\�
�:��lR�=����i:o�d=�S�%<���-�=<|�W����ʂ��)3��s�{�jR+���$�GDQQ�/��Gv<��&\L�0��5�m��g�>��h���t�]EYZ߉�:����3�<��90��JFxC����ݳyhT��p9�Rx�#_�m�`�&�zF�d�|�ܢm�h�iBM{g(7�PhZ�����Åj���5��9��T��d��FNo�Ө,<��b��{O�4~�:�o�T<�C����g;'l��Y/��s�����8�𪜮%hJݴ0o�C�=��M�)���[l��?��Dq��k��%�:C'I���CV��Gf�읙�����&�yc��W��RRAJA�0qcG�� Wo�^��}���]m�	�K'��z/uL���T6*O���Z�\�nnVY���d=���0�o��}�/=ڳ����A�&|��o�O��_�������y||�Q���C,˿��ݣGzx��vi`!: �Z��aG����ףG�����3��K���γ"����9�}�O��۳?<z�_���1��������a��f2n��:�����<���F�����H���/s�Cy����~p����s���(:��N4;r�@*�S =X]��8�)���yB��!p�[Bn��=�{a��'D�� Ԁ�fB�?}�׋&��O� �� '�ص7n�&������t�	p�?p�NX�΃���G�]���>ީ9v@�徍�E��~ֆ��K������J40\s:.+�h>��Q��y��Y���ن ��'�_�ud�+I�y�d x�Rh������{���s|���t�R	�P�C/ -J�yS�4��b��8x�:X���6#��������q�R���Q^S������vO�!���p�C@��TQkM햭	���WIh�v����s���D��h2R6����T����g�{}����$by��z���m�7�g�Ʋ���MQ��̬#��Jg��+�Ah�.��%?5�N�P�fM�ɭb�=�v�q��T�P@Ȱ�G2�y���1G!�h�%�k���'�����ٽ��kk��k%4>�"�ء$5� :W"ɄNv@�k[�]�e��RN��;��y� �k㥡�*���Er79��m#r‬ �f�݃��nC�����~�ڕc�ĝ���(1���č��D�9�\j��|�k壱����
(�q��?�%P��+�3;���0��G�.�U=��X*��?�,�`�B)�"d䛇FHI=@E�����<�2	F�,_TU-|b�P�c\���z=_��h2V�D���Y�2�����&GP�ob7���%�rW�մ?��1�Q�������v�v�O����;�r�"aj���M(�n�Ni.��&��s�|>yv��a��;�;s� �z��[$��%|�;���Wt"ȁs,�DW����:A��1�ύ搤n�r%7�,���[^�;��GmT��J[ۘ���"���$�oH���R�<	�cZLu���zw�#��&2��59�O#�T�LtPU�2I�)���l:8>?L��� 0����)�6�3�R�27�;i�K&����c�ĺTN����4��z{�;z��Z��N�\0,b��b{8
��1�O�&E#�!��P$]�L�yt�"*&~�4S��m�jD�tu�ͧ�Y�]<jOg9��:��ճV��]͚E���3Ўo���$8��~�|�{�;f�2��(Ǌ(�X�*���7V�D�p��K���ݭyn�ݞ�>���c�_��
�O�V�=	t.�J��Ě��	L��Ӥ-Q~��H�s��}�d@ o6~[=��k�:�S�.9ة�
��@�u\FQ����d�4/���P�S�@�feb��s'�~�qU�!a�W����P����(��S"���	A���t��+<��2ѷ{Y��^�/�$���wjY��6���/Bz	���h�[��ş�ޜ9��R/���ɅDk��D�ûHY��~��hN��}�K��Ч�h�&_�tn^�~4(0�M�+/̚tXR���4�N �s�96%�J#+�G �lw7���H���*Ǫ���L-������():�(/�.�4�*�lX���Q(��*ͬ���!;D��4�N8��c��N:�]#k��S�R�f#��Q,���G����o�Qtq7%%�.�4�T�!���@�"��q)&�J�^���D���'��3������~8�.W�"�y���� ��v��f�n!�1=�W��j�s��$�D�d�Y�_���0ie�b�op��f����#`#�q�3��q��*V+����n���;7?���_Hi{�W� ��-qV���7q��K�%G['�><�S��'��D9K

#�<npӷW�L(g��Фh6n,U5��OP���UY���+k���&<�T�4�7vV`�,����cʡhs�l�° ���R�7��Q2�q�.�8��Ce�I�})�>���t�D�j���G"�m�J7'����Y�}�lLf/����$�/q)�ĸ^�i����E�-�I�"��\y�%�ui�*����T-˚������y<�K�`I�����N�'*����3W��ILFm�{�t�D�t�rQ����и箂���|�r㱔8��G�}��3A�]��Ѿ����H�Lm�����7�"|���M�;�5�b�'�OR�Q�}�?!���(x���w�����&,�񵔱����S����7��JYJi��˩�Zj�Ժ�yŷ���8�@�E�0p��Q��9�U�����2BN+ǖi�k���mo8��Cˇ	�(�E�wE��� Fj�:zOD�C�¬��R]��D��{���Za��Ɔ��xh3d]E��P�̒O4���u�sc�]w���lŷ)z�V8���n�6�G(��q��q̮l����׸�!����0z���(,`���-q�R�gI%�K�,��Ԍ2��DxP~�1�Wk�G9���1��ր�~���= �
�"_؏�'�H�հAࠀ2��D���ع�:eM���㐻4��[ԲP��e�=�g�9O��(�ӽ���%Bپ�kt��:��[��i�&	���Y�/#�S!��	zx���~�A����z����y���pq����uR-�� xE��py��%0���c �)@#�� 9l���\%���hWM���j�k_n���l�('��yL�qM��y�i��RU�IJ��x45Ji7��ӧQ�	�&�9)�l�0��y�Pt�3�O��JM���Aa����AN����3}�/��!���!IS��S� �5a���M'&mR�,�t�����S�Bҵ�2]�U���S)��~���	 �;9�ĚW���f����z�"���1|�����A�M�ЋF9�o_: =�h�B�Ho �1�[C�J��X�Z��I>@?��E����S1FLV�O�8���|D�ʈ���s��X�Z�0��\�@��E8�����Ĺ�Q�Ki�*]3O�>��&>j��k��0�v�Z�P��"E��7���h���N�;G��ʁRB2Y�49�7����@���`�B*�]95��' 9�A8>xI7�)�'�O� �Z$F��{uI��4��t�6������|r�8gB�M�z>�O�.Ia`�y�ln4b#|>dR���H��{9:�)�5��X'��^)��9Y�i��s�O�S����=�o�eܘ���dH^Z�e�X�D��ę�t�_�ݤ�w-b���
$6[Y�0^��Z�mlU���V�X�6�+�~��?���v*���ܾ��7������;����������z��������C$���6,�ۥa�� z<�ؘ��땭Z5�����,��C�ǤjQP~W�V����J���v/����Z��Vֳ�����v��nvT@����H������ՠ�4�zEۥ�U�a��k��Ě��s�7��E8��D����Z����a%;Fp�`���Ђ?�o�)ᘇ�XcW��ĸ6��`��T���ݣp����㰈H:*X6���vAkLl1⹅��~���@�O}t����+�lPv}� cK�Ѡ3��5;{k��k���:�`q̗�W}��G�(����BkdZ�X�wm��\nU2�*0"���+�nZ]U�lVWY�x�#���<D\�N�n�v��r�D�n��z��.ҀH ]xON6t��>�&J�#M9Cg`ѵ�W��	��t3D��ܞv
�E��`�+�	C�����ܚ�y��:��{�����V�c��*!R�� ��ܑ�Nmv�`V�o�ֱ\�G;�˝з�n�����A�a�|�������q�a����Q���`@V���G|��F����2B���Xd!��{�(���*��S�, ���������?���6�? ��_��-.��~����c�WNVƊ��*V����Iu�^����5y4�R�UwSWJUq)�$hs^;4���Q8�U�=�}ʞj紟�gS�1(����B�oh���?���ja;���Z�,R.2V)�F��,pɻ�UJ��|�Muhz�*��^b{8őБ�	�x��)U�J�ݑK+��%D�W3��ɞ�5���֐邦B0J����*��iZ9+����A���x���ErFG'D�Cł�U�,�U2��%b�ER8�E�I#�q�X�0�<I��f����6l&T,g����vͬ;E4�uS���&�O���1��._�N��G.���Y��t���C᭮ʳ̠�7�s�#��.XJP�x��*F,��G,x-��Ȑ-�W�t/��*Ni�lE�)�0������)�h	pN����H)�U����Qb�f/Q�Ƣ��r�^��^[����}�����ء@܁w�O�O��4�J��y��e�^6��ve�P���B�	4Q@�@8��I�x���4W�l�P��
�y��%����M�̴���s; ��W���y��0��ntJ�����k^�J��07�Ȏ�o��FQ���T5�[�K�`�6z�uq���7�S����r"L�	G�U��T��+�����VG�0y�� �3�`9��H%7�k��)���m���s�)�\h����G?�@���.p^�����G<�`<{�b\�ޤ׀Q Rf���pB:�O�?ž@g�p����"�%�#hp�v,�� ��%�a�w�p�5}���f��4�� �%t��59�c�	�ĩ�L���%#
)��Tdd�9�y.�ݭ�"�H�A#��Q�Ah��u�j^�ad��!�(�)��
q���<��-�O��QC������rتZT�p��}U�>�_/���'f挲��8{�%��+<9�=+G�F��f�w�7}bw^Ͼ.�X��cq����M��wB�,i���kuJiUrP�E��_��z2��'WK�֫��`Lf@:k��pVW�)�6J`��F�� ]p�օ������Ж�:[���E��p-�ˍ�z���x&�}��L_���c<��>��W��m�6Q�!��K�@�%4�>S nr���������+�B�3���<z�����+�:�茷&�gk¡#�^���n�5q�>V�C!�DR��6	"�9�{J��'~K@,}b-��̋/ c�C��K)z�'nu �0\��ЄU��]{��-�<�~ ��6�WX���U�GK;G^��Fe�$��ZE�31�I"�kW�O��L�Kޙhݐ�N���5����+��B���h��4'�GT��%	��Z�h���S�0k�i҆�2o�Ã���z2����خ'��3�B�.I$E縏�D�\=H�<Qs�-���>�ĝ�`�s�.��P�R���GuK[�`�tW�r�#�Z��]L�i2* ����C�� *�=��vRvh҈U�׸��V�.ʋ������A5�jH���_����֤yW=������K3�˫T�Ŧd�]&���M|kl���NU�|�SR[�bߣ����ib�U�-8�l�w�Z7m��+�_�eY������K�E&Q��6ɩ���+E��
h^4��5=����K��T�R4k��Hq��|Nw�;�<���4U�U�]��:n1'�2�ƈ+�ZQ�<ɉ�&e���� ���+���7t�T���D8��cݲz�(������VK
�F,���F�z���̘�jsb��Je�d��E ϼR��WjfL�Ըc&Ec�9�
�mfU�������Y�
VH+�k��3l�ja���	�����¼~>z�qi���H�&�~@{��j<��a�lxU��j�ji�T������w�"+���IT�P�VZ�($�_��nu�@���E��u�rR�؈��#�K�n�B2+9bX����)5��%t�Z�	�XSW� =�_�-6i�0m�;c�������^sg?��SGj߉���'�V��9�ԱRΩ�7F%�$(�w����(xJ�c�x4i���T�.�����DWW$3m�n�N �!uZ�fW���G�v��j�E��H�]
8r�6�k�(8Q�?�.mҵ��l��b������Qp
#�=�n1oF7�j��#�Z�t���YRH��I�ˡq�G�Ɗ�8�c��<�CgV�pD�x>����xԢ��A�)@��T@��a68<�?��ib6P�l� ��Ӏ�^L��ȫiY��j��x���3��J/���1�����N���Y���H�����F�w���*,%��N�^da�~����HO�5Y�~2.?�`�-�N�}l+p`�(.`K\TJ|�����5(K6����6��I�M�k�Wt	�ZV��2�F��B��� �A<7)W�.n���ρ���P{N���ts0�m>�»�x� cl�I���|�u6Ԑ����E�_`�Λun�pӍ�	\L('?�@?F���X��R�G�� �KǛ�a��@�0���4a�v�`�J�pR~ڹ<�#�P[D�_� ���-�KQv�bZ/��^�"R���%]Ȼ�vd�������_���������K�T�2h�H��r��˭�����w΁�����y�ƧC�ǰ���(_�B"ܮ���*���d�����������e�5&=�j�J�}/.��Ni/̂)ft-�Q�Y!{��vWWW%� �<��,�ʻ;���N�@��~v���I/K�t��x|v��!R̟�^�~���U[�R翞@�Ju}k����z���7t�9f̧MΙ ��N���h��Z��{��g����@�ވ&�߲���V��:(ӱ�s<���}��o�����{9���������X?�>?��q=�/�/���L���}��:�}�I���
�!���w%>1�!��
J�{N�J/�ZA���O�_�h�_X)%~�Y��Kg�D��g3b���%/�+��!u�O��7����$�ځD�tzፄ�I`��^��P�@]Rl�'j�� �� l�W�<���A���:<V�)U�J0�=�恌a�
"y�q�(���t�2�k7�>�x�<j��p�G\��T���xׯ��*�����ٲ�����+�o�/��u,z=0B!��9M��e��3�C�ky��y��������N�[����P-�5���rGɼΙ"NO�f=/P�����/�k�f�o�%���7I�e��?��b a�N x,.<�����c4� ϯK?��6E��EcNXp%�>�$�p�cc�~I�w��A�ɛ4n��n��1�_r��wdx�E���pL.w{�����}���9�}�=�d�f#�d.xk�±��o!���(|��r3����N�͇[�d�A2bO�i8#�F%A)�G�e�O�����P~���bl����q���00`��D��U�Rc?�Xix��<�a�COeHs���� �ի��J�Dv�K�d�A���+*O��j�+*���X��&(�Y�ޝen���۷+N�6��o�n@3~EP����lsĥ�5�/��k�e�qc�l\Z��eØV,JK���%�\��\,�>�� P.�(��Y��6��=���w��BJ�2Y���E>C˿�h�~���h�}�"�v_,Җϫ����/L��pw����֘���0�9˷�fe�):�tṵ�T�k[��o[����!���������*���E�~���|���쨷�mty
��o㗤��JQe,�w�x�M����=9u��&���c���c��O��767�d��!Z��:>g�gc#��y���ﻎ�������!Rtb��꘷�k�M`���X�����X��{����}�Z���!���~꘿�7k[����������qu�~�oT���a҄���2}�W�l���Oe}����P�����!�cf�%�=f/��$�L��c�:�薔�r���R��-E/E$�W�S�Ҟ��AQ�1*�x�A��}k�r��"���Dg\J<��:D/p;Z��(w�x2ڕ$S��Į���D���,��{L���[�����Z�I6�?D�?n�u̘�����U���I���C;��l�}w����� �0�+�c��Z�V�75�)�W=�)o��Q6��Q�;ŌI}īD|�0t(�wAO���8?��J�"w�)y�Ҕ�u�u̘��7��Ɠ'��O���?���=������{�Eû���5;"��k�����v>j���$����U �����~$B��b�^�����K�� w��*u���3u{�̎'�j�~[���zzpܮO�֭/G��Zmm}mcms��g�sg�����?n�T�*L�G�Z�(�:/��} �#ؗ���T��!u���6�A��nT����-������O���khh;��\��F~��:��PT|A�kG=��ig��$���|��VJ���Lucv�46]#� *[%����;��T2��Z��M�_^�N�^Z�=��b~�pϬ-���p �ϣ���io��q@;
�.�F��%��1P��TF�4�E�S:��WqH���^��+�X��`�A��ع���{{�(���:��gx�ǘ.tr�R[�����߃q�c�Q�x�Kt����c�9u	>/�RAzg�l#U��	���l�7��?o-=Q|V5��.��qd*p�ĝ�7�=d/�'���v������a0>+��:bK,# 9b%��0��ITJ��0�5{�ŋ�#xW����w�-
��9-�\��n�yd#��rà��!��Q�~:��\/���d��B.��_���� ���q��K�O\9�{�a��Q������
~�^ZFO��j���s�/[&�{c��z�N������g�:%x�H��\���8l W�}�$D�{�.���� t�X� 痞�o�&���:f�����j�;���zv��A����˝���������;"RY4�_����~�hg�}���~u�s��ɫ�V��9y��<����9�:ģ��3k,֋,K��&����:f�x��u���|������H�{i�8�@�'�N��!���ɹ�|i�t�4�Fǻ�1������?�O���d=��y���t�Oꍦ�	��M@Q���gM�#��0�����Z���>�@s�t;�\�?�4�e�/����_C���88l�:'��F>���r�4�Tc׺t{�-�rSO��ч�2v I��3��7�<����-��6gm	$�2�s5͸%|!u���^_��mU6k���)�׊���2����y�%��vݔjNʛ�@��FЧ_�GW�$�u@���p<�<��֙z��NqO�;����r��%��3	��u4wki����N���l�+>�Cۃ�z"d��V���h�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,MI���� � 