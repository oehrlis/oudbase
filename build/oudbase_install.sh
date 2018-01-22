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
    DoMsg "INFO :   [-i <OUD_INSTANCE_BASE>] [-B <OUD_BACKUP_BASE>]"
    DoMsg "INFO :   [-m <ORACLE_HOME>] [-f <ORACLE_FMW_HOME>] [-j <JAVA_HOME>]"
    DoMsg "INFO : "
    DoMsg "INFO :   -h                          Usage (this message)"
    DoMsg "INFO :   -v                          enable verbose mode"
    DoMsg "INFO :   -a                          append to  profile eg. .bash_profile or .profile"
    DoMsg "INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This "
    DoMsg "INFO                                 directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default /u01 if available otherwise \$ORACLE_BASE). "
    DoMsg "INFO                                 This directory has to be specified to distinct persistant data from software "
    DoMsg "INFO                                 eg. in a docker containers"
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
while getopts hvab:o:d:i:m:B:E:f:j arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
      B) INSTALL_OUD_BACKUP_BASE="${OPTARG}";;
      f) INSTALL_JAVA_HOME="${OPTARG}";;
      m) INSTALL_ORACLE_HOME="${OPTARG}";;
      j) INSTALL_ORACLE_FMW_HOME="${OPTARG}";;
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
INSTALL_OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

DEFAULT_OUD_DATA=$(if [ -d "/u01" ]; then echo "/u01"; else echo "${DEFAULT_ORACLE_BASE}"; fi)
INSTALL_OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}
export OUD_DATA=${INSTALL_OUD_DATA}

DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/instances"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/backup"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

DEFAULT_ORACLE_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

DEFAULT_ORACLE_FMW_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} /usr/java -type f -name java 2>/dev/null |head -1)| sed "s:/bin/java::")
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

# Print some information on the defined variables
DoMsg "Using the following variable for installation"
DoMsg "ORACLE_BASE          = $ORACLE_BASE"
DoMsg "OUD_BASE             = $OUD_BASE"
DoMsg "OUD_DATA             = $OUD_DATA"
DoMsg "OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "ORACLE_HOME          = $ORACLE_HOME"
DoMsg "ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "JAVA_HOME            = $JAVA_HOME"
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
            ${OUD_INSTANCE_BASE}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

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
        ${ORACLE_BASE}/local/bin/oudenv.sh && DoMsg "Store customization for $i (${!variable})"
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
� �BfZ �}]sI���������s��Ź�,	.�͏f�]��4�����s����D��n\w�G��G��o�?���/p��/��̪�� $AJ3���������������:��ғ~������7����:�W<�R�V��땍�
+W*��'l��g����x�91d;?��]�#��'�A�;��)4�{E�� uL�����f��Rݨ��������V~ \bϟx�/���,pfx��+��h��^����ص.�����5�|�Y��y�e^�g44m���uƣ���l�y���2ü0]��|��<�U����+U�r`���;��Xc�+���t�ݛ;����,�δ�c���c�7���}w`����̣��Ci���]g��=�J�v������{~���2��n5~�Y��K˳;�E~������L�9��t]k�3�a&��7�eC���x��1���6�:=)���'�9�C?z��=�fc��s�e�}i��M�
��w�>;~�*@����>�n��X��G^�T����3�N�S�C,nν[�<�;�*ǽ��k�R,?-V˕M�H�vl˷��4]$#�T��
�ْy��@
!�M����9��)����ۆJ�����b���1?�`;x�:=:88>m�7r��z!l�_��+:�E��h�=l���������g������Ѡ���Qg�`���i4���F���U;�f|��w�����;���1� X ��N��}������A6����>�9<>�o���p�˕������Q{�����F��GYJ|����>jnJz�b.��t��Gǧߵ���Q#Ko(��j��G����s8����i̲�j6����m�ZG�N�<��5`@��L����QΨq����^��.2�}������;x�W�qa���ǨlmY�h`\�s��)�BbjJj9{����8`u^�Z�����.+X�[�;�����g��b߂�k�����C�W��{����K���B?�٩r����0���R�_&O))�ݤ�ݾ�}Oӏk�V��R
 ���#��ٷκv�e�f'	�g��7\"�C
�$�%)�c݂��$ħ�r���'��?��D�p��Y��-$VnX��ge�����l���4�������|����l`���"/�|�Q������}�KZ{�����!),��Cu��J>�ڹ���&��W�՛$&�t]��@�u�a0��̄z��]��@rujW2`FP���lt����� |�LnA�d�e���O���ab�Z²�����W��W�ӯ���W�����R��(��=�0�.P���k���f���������B�gt���	9�&�L��� �JuaR^���w0���,��&+�xJj�j2� )���[�~�v��qOXc�� |	מ�Uqۖ�hE��.����iY���[�sl3.���mϞ%���~2���!�s "�	�"ݔ��G Az�`�`��M���'A=!�+(����|0�t��6�=�⪢d�
���L�Z�.�7�$�`��ۤ�����^�u`p�iZC��u\�;�^Q��:k0[��=?+����U���`1��mǧN�p:�%�q�����娹�������N�p@詵R1��3}�%��5@�QkO�2�3��}���vid���c��I��w���DRW��ގ�}�/�ϡafO-�>�|�u�B�N��������Ի�ضQ6��3��zp=OQ��֦Aݳ<�4����r�,��h��@T5ض�E�wО�)Zm�B�X(�!	��6f�'�#��8�#MѪ �hy��M)�)^������!
qˆ�C��R��4Y���dW�m���o�6L=U켲��Ε͛���0�4��Ą��ӑ9t.A�6Q��c>(*'�PY}Vꙗ%{<��
>�3#�c/�c���a�����q$'0)X@@�\\X�����l\u��N�s��t1��r�U:mYY���s��L�;T�O3N:���'��V�E>�j�V�Pֵ�D���3E�[9GiN=����|tԱ0��1��9�l�]z�S:Ŗ�px�_6��PԸ�k@����Ϩ��_���e�����4�N��Z��6�bG�'����,�gX��q+��ƈe��������d�t �+�S����� ��S.bv3YwZ�M��`3%+��u/o�m��#�����H��3�hw��Q��/�z��C�]wQ��\��U��䖹�"t/�}X�f��޵��Ȧ�@���\��|܎����C5���u��}����<F#~�v^��d(�����ܪ:Q�Z(�z�Pf�d\���-:�Qu��5asf���n=�Y��A)���`$è�e%����=�k��OJ3q���u�B�6��OZi��`1`j��0��ΠF�1AO�x'���I�'�$�L �%�r_&`Y$�Y/d��7����D ��x��%r���1E��O���k���`D��R1)����9�m[8w-��Rl� h8�����L׷L1�$N��!�}@�'�mb����`����T3q86��~{._�h��b�6`AL�l��L9��M?��.Xl�+�!W*��U>�R?809=7��!/�iq��p<�� ��C �t����F��>�ѹ���o�҉]b�onR`�8�O���� L|b�D��OB�`��Kbs�c����A��}�r�
��˖cY�֣����K��,K���F/]�������pA�2�O|!�������V����N.V��>Zb��|���X1�޳���;��:��]8�����f����Q{&�F���il�L��������\���\�N�]�Z�O���Gh�J�Ɠۼ��p�߰��HKJ�{��	Wm��>��w6*1]~zŻ�BT��>+~���jd�&��-zgn�CJ ���"�.�a�(f/�Gp��6���)��Xv�<E����(����ξ:���bFoh�3Lc�+��R�0�Iiݚh��C��W��O�.���c1"�?)C�C=��`�V���n$�o�_�x}A��7���~;�N޺ިj���ӷ����<֏����?����p}���z�����F�\&��re�������3������+�@�$���:E{?w�߯�����Vjт��No�����Ff�:������%������x����v~T�?!�G��M�FV��o�U����[��!iv��������y$2��S⥔�5/(�gX&V���>���#�>�Y��]��.|d��||G�	^��S'�����_�[���ɏ�sx.��~f~}�����1Ջ/���@���k�=�v��} ��||�[a�7�[�6��=��^'ŭnPnE�y2�'4�z����	+]�̿o.�{?{/!�"}� ���(���f8��Y�]$R0b�Qf���`Z�zl�u]W�����v��أ3
6|v��'����29Nww:�y�=�.�����#G��c0���P���"A�7ͣ}��5!D��B�;Ih{
��{�������V�ySZ�ca��-�EÆ�k)鋔v �`ŖP3�^��;1��Y!!r	�}+���NV���	bQ\͕N*��|�4uP<�"��mp:+�4+�z왓�Z� 7�L�P�E�-�]����࿼�.?	b�W$�-;�A��C�3J�!�'� ���Ϙ�)Y��	�\Z�ApF�AW:}7��>$N�)�S<���d�w�ͅ���ȓ�L\��k��O̔�-˓>�;��ǽ(:�9�=��+��,Җ;�B��Ro^_���K�^�
 �Gk�s�n�Tu�bȢ��J���g]�+��^l���9%�s�C"+��S���)��s��%4��[��θ�)?|�Ơ,i�5�"O=�E%yg�YA��c� t���ҴWG��VE&�{���������߽[��$� ���f^7�����]��~}��6�*�e�K'ٵ�l)��|�(�[^���aJ;W�1����4�Qv��i��W�U����Ѯ�"B��vZa�#vA�Z�{{M��łhg���!=̅B��|j�H���<�fr�NB}�T�c>DE ��l
5O[Ƶ��/���2�� Ҭ�\#R������1����4|b�l�0�n��[�7`��� �%�i��8��gea��B�8���ecur�@��� �+xdU98���,��i'\��e� ����
��U%�ˇD�yz��No�ŕ�9,��A��-�o������5k�=f��se���)�e��;�����Z�W���k:��.:�xx&�,�&iol���9o����rY]��:�P�B�n�O���"OLՄ0����؏��D&�>���Fm��Vj[��Y]�X�>Ƴ���L�����������n��)��O��--Ϟ���=���u�.Bױ�ɖ��o��~��p(M���p(-+?�貏�Vz��!������⍒}�����둙�]�}�X�l<<��{c��i��7�Qd�]�BA��O~�?,�^����Oك�g�"���}i���2�T�V���>j�������;p�哻�[��ɥ:>��܅On�K�ɝ�%wᔻpʽ�S����N�g�	�δgڟ�3��d~���~ݪ��p��a	@f�Dg��p��gX˅�h<��kt�5���s3z��x�����s9����Ӿj���ggc�Vq�U��L2��^/2��s<p��ȕi�g6��3��7�o����(6�W�|�`�~�5@����; 7�<���ݫ��N8�Wz
�B!��b_�R�
�;�V1�p�BBa��Z�6c'QCu$O$��L�[�0+����* �d�I�av_?N�y��DN �H��6`t�0� �Q�_���*N"����@�ͪH�o|{!]DEI�����Λp1����03�a���}�qQ
�>��.�������u=�����E؍3`,ԍ��na����Ш���r�E��G���>�����zJ�d�|��ݢmѢ�h�iBM;єj(4�dtyH��Å*���5���K�i$
��n2Ѵ��K�s��Ǳ�V��xvo�tO�牃�N�39�Z��P<ݙ8f�Og��&��/Q��c���r���)]tӲǜA�u���4�'x�����?�<���*@C�>f�K�u�Nw#w���&����;3���w�&�;c��W̋b\AJ@:���#������@o��}��s��~�:�O3��1���\^/o��w��^ۄ��\�mֶ�ߏ������?�d�貃��M����O�����?�7��l�_T������D�_?y򷠇��h`��0��;ƿƿ�<�{�74�.΀&.�<L�:ϊ����]$/�0���g~x��?��?b�����˿�+��h_��(�@uL��[<��:��k����gq����<��g?�q�N��9S^x�܈^'�8��@��S =X]��8�)���y|������[|n��=���tO� ��?E��#̄|
��w��M�9�Ah�AN\�kg�vM\롛˥�Z����`u-��-�M����"���xgf��e}X��&���
�Y"�.�+�B�;����ӲYE���u����������6| 	&?���#�^Ij�$�C�|��������W�ヽ�������r:iQ
�țJ�	e[�����������hs04/�a<�@�_��%�K��0�_H�(0��*�h8D�! �����얭	���WIh�v��Z�瘊�D�d)2R6����
T����gT{}���P'bih�z��pM�7��@cY����릊��`fևKY�3Oؕ��7]���J�S0��Yrrk��uO�g��R�4>,2�同�B�g����[�U���Mq�ַ���ك��k+���@h��똾$5� :UBɄNv@�k3������=a ��v�e\��LW�K#p��7
 z��d��Љ��0��yv���g6�sz	&�+˄�;qa	�T�&Z7�Bz�h(r���c@���#t���߰��T�u�^��h�h�*��1��:`V�=��kH��T��/�=W*-�(�*y�A��
q�)w����_�7�9­�"z+'��8)��U�c��T����k ��w��[A<������-�=�D�3mt�`�}�()�1��?1�?6.1K������É��Eʭ�����������!=InMӞg��s�������'O�����T������\:N���hZ�e�
`��6AaU��I���ٔp!���F`\.�>��!?i5�����_��_�g���G���c�#Ar�РSyP{����[��%�<xu��n�n��I�u_�/6�\�{�
L)����NI�NR�=p�\��.����E�a��;t<�\�Wz���A�,P]�[���Yt�+̈�p8u��ۭS���(>f���a��ަ�%@�CrK1��j��Gm�����`��B���b������B�ȓ�Q�A{A�&T�'%M�a�*��:X�z�ԗutP�U2I%8�s@�dp|ʟ��A`:M�-R4������VI��,�.Iq�Gˉu99�3:=+
��������,j%��@�ր�`��Y��ȿ�P6�%���'GHW��V�NYG�b�U��[X<�0�":�\���	���t'�i�ёN`�u�V8C,��b�+t�M:���̯�N�SZ��W�Ǫ�M"èk�H���Y�Jamrw-	�\80���#|wk�K����]�l�<F��`���ix�ޓ@g�ޣ+���L�˓�-Q~��H&s��}�d@ oV���O@�������q�=vf¤�c4Y�A���
(QIj~2��u�;bGW�%ФYY�X�QW9s<�����	�}�#����ctK��~�D��E9ƌ:�7g��[��0	ʨ�ćn<~���VR���U��e��;���6.�����>��� I�H�#A�<-�=��;z�Aʹ�̶R�Hq���$aN�P<�doڝ�SI9罢��|P������(ӥe�O=!uT$
�}قg����%;̄�M��c�0N�mU|�m+)�x�����&Vqd�}(�d�ǺQ51���SϿ�c�©��C�Wr!��Ҽ�Y��#L�8�4M��Å�(ë�g�m5�!JR�T����v��"�i����$7���<V�H�]�d���a4�<��!B�y<��bUy*�X�2m�o�Xako+�9�1��ʤ�`�-��g��zHi����Nz��EM>S&�y�$���|�@�YŚ6����	>Kr���me���D�|�(L�țr���Я\������;�j
���� �� 2:c_*e��Ŀ*���wbg��*!Q
ӄox��d��Dj�r9+ae�^� ¢StL�]�����F�F����-�/@�uH�h��#N\sc�b�ʑ�������
N�먛J+=��I�I�9#�<a��r+>��'�L1� I�L4�H��w�R�%j��}2������6 ��2��	|dpw�1��˟�h�ӗ;/��_�DW5.�q(�=_$$-��ԉ���m�\"���K���q�ۦ���V�C�4Z�SE�+t�/
h�3m��F�h?J��bu�J����(�<k�Vc火�:�HU�'Uo)��e�dյ3v�(LUKRX�Х��n�yq#:�J�����6T�W���:<ٛ��"'�Ծ~���sJ�a`���fJ^���'������"�~�*��K�	�l�Tt[�F���%��?��MY�*%����E������� aY��)���W�N���N�/��z'hٌT�C�����sN�¬JN������t�g`o=�`�����>�����H���*/$��cz$���f���P&�����q�`�_�G���yv%=��������e(�/�5��+�њ��P�'���IlTT!L*��"
@y��'dWƲ��� \�`czRv����!]ˮJy�Bs`�~q'yb����������T�}
l�^_���En�A�iO'0,ʝ	Z/K���eU�i��T��_�B��+�J�������k�T����">$���� ʧ�G��=%��ar����B�#i	ܿ&��~��\�Ԧ8EBO4�RŤ'3K6X�Q!P�(�*c�ޱ�����i�)��7����Jq5�XY������*m�������#�T+K#�i�C��|�tR--'@�(~�Z	�F�*��-�����>R�R�i����aܺ2���'�ׇS�\&��j���e�\v�*|U��`�S��iZ.�0R�����mg8t�C��FN+��Р����;2=�X��ʈx˃ �,�B�bM˃.p�"+�Æ����i�8t�uA.ZίK@џ�����[�q�`�u�f+�I�X)����Uoa�bk_"�'����ʄ�m�l�yK���&�1>Y��,�IJ͏��$��=��":�T�bK�%�Wi�G)���j�����:@�藀|~?$��C Q
F�p}�,\���i� 0,�>�L����S�D�6���.۱J���q��'�l2�I<��Ϸ���J�Ii߁�0�*t*�J�P g��T'\�jf��B�	M�k0o�'��a����� �WtI)�J�x��������=g�W��;���<6=�F��F�@��pQ��)�Lb�κ�y��)�w%����敦J��>��N;�G�lwi8�o4p1/ɏj%)ף{�U��0YN)T����)��#Ÿ�rJ��ޘ�Q'��$�E��$u:�l����'KPj��t�S��I�"��H�^����K�"�[,�l��SΉL&f)q�aI����H�a��>�����x�4�1���w���I1 �~T�D�W[�ue��mA�õ�M=����I�w�z��N(�؈�]���G(�g��!�H���/ލ���a�j%`\Z�FPkL��ѩ&�ӟ1"uV�N�(��mH������L;���F�|��g��9����q�d�1(T)��<?�J���,���k+>*��+�QY�m�Zy5��<$�k]
y��F~�|��ax
+8-%!�\Lχg5\��ø@��D`MC*�=8���;Fp�Hz��\�%��)"�$G*@�5��*�`����).��GY������	�����ҍ6��jz�[�B���0[Ǧf�b�݈�lf4"�c6dE$���+�=��{��0^�cV��tt�+�����oZ<���cG3���y��x��%�64��H<�B|ۉſ�1�c�/�!�	XhBWO��c=[�|�~�{��σ�1-�+�K�Ԫ�Ju}�\�0�Q]�=a��x���?vM�sx���P\p����/��q���}���d���U��+խ�ecc}����`�����vq�{�:����i�_+oU+����k������,�b�.e���
�voP�V�����O���2�h��g�(�&��h�{<��l�Q��Pq��ڄ�7�U�s�����t����^��^�5����j�T�Ac�{��A�SlVr��y=xk���@�gh��4��Ўk슾c�P�ă���N�x �{t����8�"�jpY?�������W"B�`��?s�.�8p(ւm�b{n���[���ic���[cG��5��rF���+��W}��G�0�)���klZd�wM��LfU2�*�F��5w�nZ]���
���8�ZMy������.m���p����}�w�]��@��;�lX��a���6��4l���"_�.$��f�(�=%d&�s��W�����0.+w���@��{eײ������`�8�(�."������t�a�f��F��a�ߚ�w]����w�T�5k<�I�y�$��zO,%���=E�+kx�y�חhD�x\g-�,}\�D��n-�78@�I_��:w���X���_��?��?Q rn��������⪭���w�R��0V{�xe���`��B�R��N+����������1F�F�s���EW^AR.V��4h3^;;�0ݽ�����B���}ƾU���c�1(a%4�3�6���/L��ڡ�m|�nbES�(�_���7�B��j���Ow�δy c�=s`���9Z��*4��3p*(�=��H����<T����=�ݒK�C���_S��Ȟ�4���Ґy�!�ז/N��ǫ�X5IUP���*Bb���Fc�~�=h�9I�d����zι��e mC�6��7�i#�q׫H�hݹS'��y*�'[A����,��J��u'�6�n
��d�ir�?����]��jf�LfG����,I��B_]=��@!n��(G�U��\�luU�XÝX�Z�9
�![H�<B�^r�U��Vي�Sx��ϥ3 ���h	pθ����a��<Ty��D��a��DQ�Ύ��E{�i�Z��|���89�¯� v(w�\�[`o�x
w%�H::��P��e_Ec�߮��^�M!T�@����")O58��檑��e��d^�wɽ���XSә6�[�w:�b@	����GVFr���O\S�˙zM�]p���Q�͜]�!
Uz��&uKr�)��F��.�����e��}hb�錸��#��*S�>���7z�q׎���h&��2�,�Q�����L������Y)�R��&L?|�S��CI��{jN�?|�ñڻs�:>���KK�� �2#F���q�H}rĸ�(�:�L���q-%��Eۀ�5#Y��)�6O�.��&�w���k��lV��b�Ŕ�^�0\
(q�&���ש���NEo�&e@j�y&���o�y�Ĺ��6hq�V$���#f��f0/�0�����@���� � q����o1�@>�@�/�����L<��V�E���"��WU����3l�h���fƐ�s
ʍ���� ܞ�ᧃ ��-A�*�pi����	�	��s�YZw�K}i�t�}�7ɒ��<����JCj�h�r��|1��P����R��vı7&3 ��B|����t�J`t(��-��~o�����A}�7�Δ뺁�>�~����m��J��ǵ����n��4�=�u�xb���@ۯ
��m�C���A�\��.`"w�1H�KZO(�|�c�uz�� �G�x�,��J���.:���ٚp��W�L@�c���8`��+�<DR�D6	B�9�{���'~K\���Z&-� c���M������:��Q��~Ah�*��.���~��]~ߚ'C�6�WX���U��K;��S��HѺ"-Cm똊�$µ�֧�Qޙhݐ�B$`������x��B�y�p��4'�G4�[�i14��jO��G�n�6t��x�;��0�������=I�"�u�|���/��Q@��D?e�$c�9桖�@���� e0"�H`�s�.��P����GuKY�`�t��
G8�����v1���Nc��}�ATd{��4��Ф-�ήq����]��]7��Wy���ՐtQ�8DG_��x��K���U��b��.�U�&�5��������F�)��N������>ib�U'-8�d����Z5m٫@�@˲r�J�b�^�.�F���d$'��s�mr*�yQ�B���W�.ͺR!t,�cHW�ЄD��b��c���7��&�4b�
��`��Z�	�����ʮ(K���q���kdu������ I����T�C�C8�c4�R�+������VK
�F,���F�z��[Ϙ�j}b�Je���E �R��V�gL�T�q*E#�9�
�mjU���ϒ�w�J+$���o��3l�ja���	����G;z�qi���H�&�~@y�*<��~�|xU���J�V,cGpq���f��.��IT*P�Z�q���$�;�T��C�}��u�|ZY_���-�%��d�f���Zg�PK��	;hq�R$��Ҧ��zJ��[L�xa��%v��n'��"Z{͝�Om�}�Z~7ҟOR���3<R�J8�����,p���,�W�'�@I�S
="�N��$��d)F8t��8�J�L�i;r;�d@��"�|0�r��j���V3-^�
���Rhϒ�`�6�_�F�����si����gs�7�NN�%����"�z�&���t ��M_�����t�����<�@�C�,�:@��vG�qy~���Nڈ��o����x̰�A���ѹ� �F���"����EMӁF"|%����^L��ȫhﱞY����p�h���(=/E[c􍷏۝p�/�3^������9X7��V�R�LXJT������R}�D��dk2���%^䃉��;��1ς������6O_�d6ĝ�Z���%
@��g���$�R�Ě�]L2���D"���u��P`�7�}ǎ���[*��s��+pԜ(?u�Laƿ�Sx;c_�!Q� ��@�l� �~����wތ����M7$\p18��q
E��z"< wdK��)�v�/-'"~�{+<yi �&	+��yc�Ub��������i��"Z����~ ��/B��ǋ�����T0C�}	��ϖю2��o��V��?��� ,^P�b��hP�jR�c���W��3�U������.80/�� p̾;�<�R�Y�X��-��RoQ���D�]���Ux��*4k�������2e�5&=���r�}���sF{aL1�k���"��ٷ�`wuuU4`�q/J�:������� ��g�<����r�Dyf<�Uݪm�+[U:����8���?�ȍ��c��/��)���6*��&��:��8��(�_��_>��'O��.;���)Ӟ���?�|����l��X�ß��d��0�oA���Y�3�P���;���_�?���?w�v.��'��� uL�[Ս����m-���<K��}��{r̚m59��r;�:�= ��j��{>�,�8-���HQ�%�et�y���2ü��jx���U�����Qe/�㋋5���G����6ڣ������9���+>u|�w$H	e+�ɣ���b�_ �U(��Y~P:�bt��O<���B��bB�����j��,�Ϧ�>֝�^WH��F�u2<��7�p��#n������'Q�5��F��d�9Ú>�\P+µ�%�� |�F��r����^��b�Yx4������V�Z�lB�@�0y_�<�<w(�:T\O�s��k�7>�x�<j�ƻq掸�(ԩ4�Oƿ9��O�J�m$��;�,sv{���,�r�P\G��Jm@�Yb�=%C7�!z������W�0H���0�s��a3��I&C�Fx�E�L4���Rj��A͋�Xgm/'���Z�lʵv���v�n��q� h��l�) ��W �$�#�0F揸!�l���.-�!w�[���9.H?\��X��� ���`�R�{�z]C&����!�y�E���`������`Rs^�r���o9�:��Yu,g��� ρUj�p��sA��N<�B� �����5H�%wwrn>��� 4��pgI�L
=���b�X��N��*�E�7�"o�I��]�����<n7�� F
̄�((E���X�=V\��:�mc�	2$�9����w�$�'%A�";���*ѐl�j9��@0�����X��g(�Q���%n����+N�w��k�n@1��P���m�ĥ�4�/�X�C�8H5&���j�7�5�z� -���A"I`u#�P�]����\���k�l�n�.{�͊�r���`K��?/2�p�D����6�>mp��H��+h��NK����ܭ>(�c�4&�"�'7g�'l�|T���u�u�n��U�7�Y���Q�Z����������^�W;O��j�O�խ����_�������y���y����i��)X��\����O�<������������&չ�~f�K)n���%�����i�����������?<��r��Eq�E����?T�:k~#kJb'H]�M2���z����[�2܋�^�}��^٬m������;��Or����1m��c���76����U]G���?T6�����xe]�]�ck�������Y��Z� X��ʋ��(O$J���q��_۪T�����a꘽�7�[5����?����q>@������8OJ�ι�Q������k���rm}s}�������<KL�K�Yb/���AL7����v�N{����3��n���b�("���Ke�\*Us<ݢ�Q��#�~�C/�����Ÿ(΂"�����ș{ǓU��N6r-��N$��͢�����������F��8��(Oj��9�1e������Vu1�?ʳp�xl�����Ǯiь"�D�5�?�c{\T���z\$^c��U��/o��Q\l2=���3~$��ual��Т된���;��A/��#�,��gnJޟ�t˼�2���c��������Q������g���s��;�¼�]����5;"�/�{�q�(��;��A?e��_�'b�'��+�X�g/^�������7��wf�}��Yp{�̎���g��d�|==Zvץ�u��#by��V[[_�Xۼ9w����{����BUaz}<JV�D��Y��x;�}�y�s=S��K���x���<����-����6`ѵW��v�sй|wL��#�=�ጅ��3jgX;�1E;%~]%�S��b�ζ��k�3����Q�*-F ~��1����<�b�(Z���
t�����1~? ����ڼk�q��̴)v;�4�PE{��S9��jRj�(�� 9b����4z��	�C�l���^�Ț�K��m�]��ื�A	�ݏ�^�3���ӅΖ_�,i�Ž���2u�7�9�;�����eE3ſ�HmN]��K&T��:�EH��k��=�ͽD��ZKO�V��[�*n��6qg �n�I�	<G) ���50=q���S\Gl�e<�XI�&L�s�"�8�l�m�������c�`�xgޢ x�Q��7��v� �G62o�����=�E���4���h"˼r�]��zd6���ܿo���_� l8����(�,�ы�K8lѭ�����KJ��U�f�x��eK�vo̳]����U��3��3��Tp���3������p%�W�NB��#�⚻1|���r~�9�6O�-�s�c����~��_t'���-�<���rg��.sD�=��"�T� ���y����>��~�鴷_����<nwN_�4O���a�:�1tK��x��"[<���>�:��H���?ln���1˾4m��O��cs'�Ȑ����B�>7���Od��{���7s3M��ll���u����Y[��<ʳ�����$�_���޲7����3��?Il��d�{#�5��4�;��Ra�Q&�l�Aj쎇5) ����~�s\ ��&�\��ƟJ�Z�n�3epn�)�0��?�-@R5�L)錢�L<yq����Y[I��TMC��<��)�v�R�T��Z-���U�X��{�g�E;ꯥ�����Vpa���9)o6I�_kA��T=�2= a�� ��ȇk���^�΂Čs�{
�� ���m�H.���I8Įݠ��[K�݅�s�x���`۱��H� �Lԩ���[A�ܢi�,�ųx��Y<��Ȼt5 � 