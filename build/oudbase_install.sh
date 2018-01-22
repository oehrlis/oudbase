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
    echo 'alias oud=". ${OUD_BASE}/local/oudenv.sh)"'         >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. ${OUD_BASE}/local/oudenv.sh)'                     >>"${PROFILE}"
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
� J�eZ �}�r#I�X�J���i���lmm���x�Յn��@Us��%XU�[��&�$�M �� ���2�Q��&��O�/�鮋>@��� @d��]U���S�.={�\.o��3�w��[�����*���fu���^a�Je}��?6b��<�p�1��lggc��v��D�S�g�=���#�������_][ߨb�W�뫫�u������3V~\b�/��~UB85�^f�f� ��v��r3{�Z�F��X��
{9�,��<�4/;3���~�ڣ��q}�����C��a���iy�kx�ɪ�Wؗ��*{�7|����������`�}����=c`�Scڀ�����s\��g���͞۷ؒczy�QZѡ���� Ŏ3�ҭ���s;��o���쾼��o~X��?�,���Y��"?�l#w�x&��x��;�5���s��̲�iv�d����k�#�u����p|ӓ���=~��_��gvٙ�2Ӿ�\ǦN���9#��m�j�Dx�A�Bm���C�V*�C��)R��)案7gޭ@�p��^��\)�����c$
c۶�[F�]�.��T��J�l�<��� �����&��̎͜3�hh�g�mA��������@Ϙi��i����4���V����8�{��%Zv��p<2�	cd���[�?2�4(�u���߫Cof������^��=:|�ʲ)��]�o��s��,�a�&��r�ݪg_5v����q
C�p4����N���zn	9�9�r�|�h�ह}��:�?���-��a�_m�@�-�mI/^�岙�Q����V��:�g�œ]ݖ�Qj�eKo9�C� �m��,�-g3���F�y�j���ӿs\d��˴�����I���� S=�8�َ�3�{���R��Dek��}�g�q��NSSR����Yv{��>��W����лtY�b_�������j�`�&�Ԉns~��h�r��+`��CR%�zI�N��%'�L��R�2�x�HI)�&����M?�9�[�K) �v��d�Kd�������$خaCk�p��{	)l(�H����u>�������8�$�`����������{H�ܲ¹����W8���̭�i���#���r7�[�l�a���"/�|�Q������|�KZ������),��cu��R>sC���;xs�d���m���qa2�l�k�9;5�.�m�5��@݂ڕ�df0��,l'18��[�'Yxa�<cGۻ����X�����o����Š�E��oj_�־hg�_}�=<L/jO(L���G���Z�z�Y5�2��e(&<����pdiBC�Ͳ:j@t0ȬR]�������l��(�>���
�2��ڸ&�CJ��z֙�]�p��X� _µ�hUܵe!Z�ĉ�Kl�xpZV����vی˦vۋIm��Q?����9�ꄀJ��n��FC� �@0~��GP�&M|	ʓ����A�r>�sQ��LӞUqUQ��D��-h&�-�@�;X�3c��l���|�Kd���0�F4��x�8.�z��VQ��
	�-�Ԟ���D��VBj�h���S�z8�����AU�r���i����F;B8 ��Z���>��K������R�y����wF�_�a�4��L�1��8w��>�G�(�T��Nloہپ��g�0���_�X��@!D�KZ�^|bkxq�]wdۨ��P�[W������PW'Aݵ<�4����r�4��h��@T5ض�E�7О�)Zm�B�X(�!	��֧�'�C��8�#MѪ �hy��M)�)^������
qˆ���R��<Y���dW�m���g���6L;Q켱/l���MO��
�YJnc�_���8��V��P�1�w����(u�˒=�������W��`pc��D>���8���,  p..���T]d6���j��f�J��I��*����V�u��X&�*Ч']��|�+t#�U�Z+e���A��pRٙ"�-���	����co>:�Xg�A���X�g�.�=�)�b��8��/���T�j\�5���X�g�د��tŲ��@k~�J�	zD�KE�PY�vH�#u��s�LX���5�ٸ��]cȲZ���Y\Kg2B: ��)HNP@�T�)1���3��&sz���t���s�w���z������	M̆}���p�|�;�u�(�z�V�Y��֪������B���_r�\Y����>�|��l�Zedd�� �km�jb>nGK��̡��R�yv�:���j�?�U+�se2����VYnY�(h-H�}(3b2.B����ڨ:�f����9�c�Kb��K�,�項�`/X0�aT����L�Ξ�-��#���8	�D�:!z����V@��Y���%%L��7FĄ3蘑rD�S&�1�'�f��	&�+�u�y�ܗ	XI��
�Dk�m&�{e15 �n�5ECn9�~%��x�q���j�s�,QbF�T�A�F��(�gD�B�o��\�~���)� }�}�:C��-�CL!��(lHs���j�XbC!��� �~�3�T���ߝ��*Zv�#�ضX�@2]�S����q���[�J��J�ҢʇP�{&��F���&7IF}��":8 J���
k����+��}啎�+}u��9�~,��D��0���>	i��o[,�͕��^ª�����9�+ �[�e[�fW�;/��w�,���tV��[��;Rt�YO,�4?�X�2.�v����L�:e�XI ����z���'��7�d\]�ŗ���{7��z��.�
���~��zo����C��_���q����J�5�]���r5WŤ�����%v�Zʭ��o����W��nhIBiz��<᪍�@��G��z%��O�x7U�JR�קae�O��Z������y�̬wH	���QU������2�Ō�%��~��3�<���N���^�;������S���Y��,{�i,>w%�U��5)�[����յ�>���2�q$�B�'eh�x�e��{�J�_Э��M��?��!��C@��z5�������[��U�u�}��t������=>�G��r������V&�_���^-����\���>�3���L��������
'P&I�=�N�������"��H����hA��]�;��n�yyC�c�]�~�@�Y���}���<SO�;�?��/ȅ�	�u�����sm�`��Z�aH��e�!���;��q�Ɇ̦�x)�c�J�V��yr���Ȳ����G��}d�>�sY!"��v�Wn@�ԉo�!;��W����3���^�s����_dm�O��Kw ���m��� ���s ��_�Vأ��jV�EnzO��Nq�@F��[�z���	M�^�x�t�J��G������K��H�&�j!���-%��΁�q�h��a�Y�u�%$����[`��լ����d(��̃��]e쉣��z����D����6n^s��K����bx��Sg���j��\$��q��~#�&��Q�x�	mO��
t�S��w�b�l5nK�xl",5���hؐp-%}��d��jJ�k�p'F��6+$D�"���o�������?F,�˹�q�����.���]���NgE�f_�<s[�����
�����W��b��'Al�ĹeG:(x�wFɷ����v��7%#˓:���A��#ΐ9�J���aq܇���i;�p����,�!����yR��KC�s�3���r�ey�'z�2���E7G��G�EX@��@�r�@^��Q����Pa	���C��p�y��혪�VYT�W�ڝ��kyaRߋ�n0��s�$��P:������ۇ�]BC+����{���W��lʂ�[/"���]Tb�w�p�dn�?@��q|.M�5��+Udrй߿��������b>&��p���ު0�9���A�B���蛥��) V�.�X:ήgK1���0G	�򺕍#Pڹ��w&h�'���'j�\�WA�w�G�z�tyN��n����km���6P�����X�wa0
=��t"ߦ���;	M��Ri��(2,�)�<i��b���/F��^H��&r�H
�>������/:���y���P��n�ހq�g.�@��FT�yB�P�ך�q�y�o
��Pn�s�����uR| �����Ue���
ԳԳ�Yd�p	���H��KK��7��.����>=]�QWvg�̾ƶ��ٍ��Î׬����Ε��l����V���'k�n1K��\��,���@��ݑI�>��a>���eu��\B]�
E캑>%dB�D<1U�l�?2̧~��'2�h�Y�?�W�W����&�V�����O���??��g0�~.���A�\�ύ"�?���y�����5��]B���T���E�8�ْ��uُ���i�~��b�']�I�J��=���ٙ�A�Q��^r�tt=43h��kw�#���0 �y�L��i3 k��:X�
��x�#�a��o��=h��>�Y���K44x��p�������ak��w�ؙ��ރkT>��s�\�c�;�ɝ��~L>�S��Νr�N��s��]�)w�L;�ܙv�L��r��u���#�_�j�Z�1�h}X��*��)�lg�r�5�8��{����F��ܔ^�<޿,��\N�(�����t�������U\yUf<-��o�׋kxh����=re��&S|f����]����}���&����4��3�r7�p��S񗍭?�98i���x�'P)bZ)�.%� ��a�
�($ֻ�k3v5TG��DBX��d`�5���=;���!A֛4�f��ԝ7���	�b�����.>
�+T]t_e�I���)�½Y��o�b�#���(ɗU�#;��y.�R��f�6Lӳ��P�Ӕ�(K�;�\���[�}f���8Ƃ@�H�o�V8��s6�J�.�Y���˼���W�EZ�'4Mɗ���-:���&ԴcM���B�JF��D�1\��:�]C����)�Ԙ�A��x�&MZ�4:'QYxjE<���6N�4~�8���T<�C����œ��c6�t�Kl���u�1��*�c@	��E7-z��w�_z���A�|��x�p�L�����(��4T�c���Z��$q7rw�
n�Ȍ@��3�ތ=Gm3]�</����;��z���wx>����A���I`f}�:����k���^���V67�Y����V��?������ٳ]�����R4aڳ��?U��/�����L�qtt�Q���]$˿����߂^4�þY������_8h��z���1���8�����0���<+����w����|�7����ٳ�P��������/���<	��8�F�G�c��_�\۬D���|�?�3?��y���?��8E'q�)/<
OnD���y�S ��)�.�.�j��B��<>��q��Y�->7�Pήӹ0��"���O�G�3!ߟ�����Yx�'C�K�W���]�z��ri�:�x���[�/B�A�mӅ�#�쎆A�z�>ީ:v@Y安�E��~V���K�������h`��lVD�|2t�"��'6��}q�@��O�7�<��ȤW�Zs�@�%�8'swcg�d�M�hw��>�"d�\�GZ�B)�RiB�"�q�Gl�`=��2�͋+�O;��F�r	4Cy9L�<
Lh�X�
B0Q`H7z�*j��e+�0:rŕE��]���9��'�)Y���&c�h�U,�'���^Aߠ8'ԉXX�n߼2\S�j��/�X�����"������`�RV��v���M׆���ǣ��%nք��� vݓ�~�5���k:$#���8��(�mU�x|mS����u� �(g�Z���6�û�ڦ/I"�EEU�P2�������svOF��٧�y%/ӕ�R�*����r���m=t‬ +z�����N]���M�^�I��2a��D\X1��VǍ����9�\�k��|�C�]px�t�7,(� UrݢW!(]��
Cw������UqOo�Z��m�U>��ϕJ��z 
�J^i�.�B�d�}��������M%B�p+����q��wǥ��߬��Jv�`�q#`��rK�G߲/�o*���sK$;��������42Qq%��!�YP�q���j�l�V�VΓ�"0ln�����=!w8��8�l�ߙ�]���yr>�$��$�f���=g�W��b�@3	�DT ��Pw�;���%��L܈��q�����wK�3�P>�;kWh߿f/"WR����`G����N�������G�3"4J�%"(���p���:��~��׼sņI�0���;gk8%t8N9���sAȺ���>s�5��o���r=_�E���@#tM�n��Rfщ���7#����n�m5O8p�s���w@���ۙ� �g�-E�g�n��Pɓk�v�
�e,������[Rx��"OBrD7���P;�Γ4�����`e�M��RE��A�W�$��8�e���Y~<4���4�n�H�@�>;SZ%)3�8G�$ų7�-'����N�� (��#��wwT~�ﱨ��(�Y��Eo`f1C�:C٘ch\4�|��!]5[�8e)�1�h�oa��Ð>�D�d3u��&(��C��O'�CG:�=�?Z��F�#��	6	���3��;1Ni�^5����5��.w"Eg�*����Y�$�3���K�͏�ݝy.����k��Y��ף9������zO�Q{�J�4�[ 0Q.O��D��"�����P�]��X5l;?�d��:�S�6���ة	�
�dAAJp�)�D%��	Ȍi^���P�]�@�feb�V]���ۏ5:Np�}����7�]8
��qAT�X�3>�ތ�~l!���$(�b���y[J��_T=����ʟ�x���G�}���I�H�#A�8.~ŝ��;:�Aʙ�̶R�Hq���$aA�P�d���I9�BQrbn�J���VwA����'�.F��&����l����Kª��fB���A�1a��*�qs���@<Y_Bpbߪ84���O�cݨ��Vܜ�_j1��B� �K����Xi��,C��TZ������@��Uǳ�4� %)S���ԉY�z^����މeo��zbv��+p����b��a� �}}��>T�<�e�*����Y�r���7C���w�ƜΘ�IFeRP0�v�3ȋI=�4�i�DR�=� R��&#�Ϭf�<t>Q��bM�H�s����Lwz���L��j�p��	����60�+w��c ���B�� Wu�dU?#Fg�B�����We����lBW@W%$Ja���l��lC��}�TM�B.g%������	DXt��	�s�ޢH9����HՃ ����#lm�3��TW��XG����r$G�"uEm��ӂ��:��R�r�	Ru�s�H7O�����g�=S�&@/}M!�����p�Zb|�L�8�����c�HA$��+B�G\ǝrL���1�����z:��&�U��rJb��	I�;u��]q�-�Hi%��uy�3Ƕi".���˕���`��z���yt�MWш��G�SP�NQ	���~�emb��jl?r��X���᳤�e��읁��vF.���jA
+��#���7/�TDGPi�SZ�bۆ
�*:@��]�'{��_�<��/�'��h�wcu#%/u��	y�|����H~��J���R{�:[)]��V����*6q	��.cSְJ��:6q;{*>Ŵ�Fƞ�OX�j&F�"]��H3v���l��Z6#��lk����C�0���	�,x��Y�[O/�%�6,���a!==R(����g'���ɮ{<�ٵ�����2Az$�!����q_u�]IO.�8;k%dza�-��iM���n�&E@j%��1Ed��EU��%���E,��	Y�퀱�<=� �$ؘ���}bvHײ��@^���[�_�K�Xp� (��f�#�}���gtl�A��>A�w��	�r�G��˒�fzY�O��+U����Ð|�A9�ʼR#:>�k=wzZ1վ?��	�!"�:��	w���NI�j؁�]�a��y�HZ��B������߶�-�6�)4���T1��L���lT��'�e^f��Q�;ۍ �#P|�q��[*.��K�Y��S6_\��w�Ww���B�
cia�>-q(y �ϕ����O��K�u#~�v	�GQ.��-����n�eI&� x�p���A�[X�r�����x��C��R����lxq��a��l�W�,x�10O��t��+�U~��38�pl=�DwhP�l����:,�teT����Jr!t����A7���a���V��4l>��: -���!���@gB��٭�8w0�:rKO��%פ۫��
C�D�*Ʒ0Y��/��ƃ{n�cve��6F��!^�ђ���,�}���$���VZ���>ll!f*	`�e��֫������׿�W�F�Ǿ��v ��K@>��O�!�(&j���Y��2� A`,X0b}��mfA���2}m��#]�c�,���^nW��xΓx`�!
�ou.�&�!Ij߁�0�*t*�J�P�f��T'\�jf��B	��k0����i����Q���2��3*��Q¡�.��[���^��\�����0��e~m��MDŃVl��5��;�*����ޕx@H�f�W�:�ex_D�;iN��������<%o�JRnE6�	�za��Ph5RH�t'[����	���c�W�<����q��P��$�%|�~�,A�1�,�PA8@L\�'��ld�#y�)# /͒�n�L�'*2L9+2����͇͋?�*�m��L�V�A��Ѡ�`�&Rx��n(� $�REi^MlCהm蚶]�Ƿ�,F}b&�2�!��;�pbCntw�K���g���cm<LN�x%b��.����8qi�A�1��G'�4o���Y!;���̃�!I��K�"<��3�N�3A����g(�>�=��G�P���g�Yx2M��:��Z�έ��в��Hea~�k�{��2t�سu)ҁr"����S��I��Ĕ���r1=�g�p)N��`�5	�h��#j���#���3��4O������ Y�����mHϧ��'g����GL���n�KDK7����]n�	����t��]vl��vꋩшȏ�I,�C����@<��jK�x��yXI����U�����l�k��S���H,,3c{�y^<�}�ߏ�[�t�#�
�m;���N�y��Fv&`�]==2��l!����.?�ZǤ��/��Z-W�k��J������3���X����c�h��[��₻���ڼ����:���Ϧ���Z]�T��+�k��������h��#���X[K����f�����je��)�ZӥlA\]Z
�6�"�j˾����К4���v���5�q��61
�jp<Z���ư�t��A�б��a���C�+�F㾞���"�*֡#h�q�:���J��5oE�a��L�aރ��#�q�]�w�j�xʚy�R��!w��cДT�SDR.K�q�]�[���@Dh?�o~$�.܅�^�-�p�LPd]S#cS�Q�3�P6ڻ+찱�B�^�����q�:��guz���9�E"��`�M�����4���,K�Y���Hҿ�ނ�M��A ��eA�gU��)"��ӑݡt�..R��p���4 ȣu��k$:LR�B�&Ԃ�����7\d�+�څ���"���Ox��p���ʵ|ߴ� �e��<�,�y��X��#{�������&E�E�|�BS�C���.4��¬��(�2l�{��Km�5�N���f����=i�=�5���Q�	�5�Z�G�Hw��`�5�B�i�묅���ˑȲحE�P"�+UB�2@>�C ������'
@΍��p�?��{\�u���#�VJ^�j���zT\�T
�Փ�Z��em�K:-xx�Q�ъ�E��bѥ�B����<G3ڔ�Ύ-Lw��$!�л� ������XxJXA	�V���oh�_22{(a_|[�,
��W����.Q ��];7��]��3m��tO��kN���
M����l�8:�2�"U>��I�b��R���8k�>؄�8��"a,�4dIn��勓���*0pMR99����yA������E� �AOR"��b���s�c�bH���C)�M"D��b�+*Z���	�x���I�VP �b9&���yb�	��M��B�&6�_�؏��v�E�oF'Ɲ��#��V�,�A:E��З��E$�G��=��E,E(W8]^#��p'�j�Bd�҆+�P��\z��e�$��G�s��A��1��&Z�S��/zsD���48U����Qd3�f/Q�F�����r�^|^���{�{E���y�7T ;��w��-0�Sp���A$�#`�X(��o����VVe/˦*I��J�qE����~Ls����2^}2/��^��^���L��-�;j1�D�Mο�ì#9�Q��ǯ)��T�&������y��(��ή��-�KU�%��Vj��c��������>41�tF\Su��~�)|CJM�;>J��kGlud4�w`�
��(��W|�P&�S��^}봔�N)e|�>��]䡤w��]5'���IY��9w���%FQ H��#����m�>9b\o������N􋸖��m�ꘑ,W}�b�'|G\��;Mo���e6K�i1�bBaEN/E.�8w�����T��Aǎ��7�ؓ2:5�<�hi�5��i���U4�8x+�����!3�|3��p�k|@H Jj��{�e�8_��Z���W �r �A��ߧ&�a���B\w���˪�����6ehn�y3e|�E�Ɲ|qY�a�n���B�T����k���gu7���9�,,�;��>��n����dI�d^^�ߗ�!5Y�_9�_L�K��}r�Th��q��H1����*2ݩ�=�;t^��/L�~�N3����\יr]׷.�+�]��֫�Ċxv�+���f��A@c�cw�#V���������&*1�z��͵K�&���������:��Z����yԋgN�+�d�h�Wߊ\���{���:1�Ȉv!����#A$�Ld� ԛ����|��E�O�irтy12&8[�O��XLЛ?q���Z��&��\����h����y"Jh#|��k-�P%p���(*)0E0*�� �+��0�L!\�j}� 坉�9�)^&�0~�<���bi/�l
7[HsqD�8A�#���{x77iCG�7���
C�?A=�l�ߓ�-�G �g� A�
C�t���I�SP��A2汚c�j�+���P#���v;W��x
U/�O|T7��vJ��^�p�Z��jb�n��'��46xhDE���`��N�MҢ��wZؒ�Ey�7?�us�|�'��^I5�Ct�ѹ��� ��?1���1Y^%J-6&��2�P�j�[a�N�9Z���kԘ����]u!��&F^u�т��K�����U�f��	��,+����(���"i����Gr,z8�J�&��5-dE��),�۬+Bǂ:tMH�8�qF�3�L~�KPi�N#&�P���Ŝ��̶!��ꀲ�N��)��FV��^��tH���I�8�?�C8FÁ�-��2m�q����Lo���h�B-�+T-�����ɭ�'��T�,�J�_T ��+�j�z��J�k'R42�ê��&Vyh�,�}��T�BR��:>�&�v�ۯ��p?jd�z䂈�����AOͮ�t\a� � �^���+����W�j�Z�W�e�.���|�,���5�J
T�����;��.�+}߽��,�O*kk�2�����́Ѭ��\�j�:a-�Y����B��1@O�Wq�i/�����]��W_�As����@㱣��X��A��I���u�G�X	^��z���z�z
�(ixJ���g�i���T�,����GW	�)3mEn�O �!qZ��'W�\Qmw��j�E��P�^
�Yr��&�k�(8Q�?u.Mҵ��l��l����	Q�6lPDaW���ļ~א`G��+�=�qKW~?���C1	t9���T[�iGq��y�L�ȍ�?!��_����!L�Z (�+	Phd�.�+	\�41h$�W���1���$ʉ����)���+�
�����}����R�5F�x���	���>��p	���u��H`�.�˄�Dݱ�-��/�7�A�I�&�Ӌ��E>�h�@�ck��,X;��q�i��M�gC\P���xX����x���L� /�J�I]��$�oI$���Y���{}�q�\1:��B:?��@�)����!�`��t0�w�3��%0~��ʆ
�c����y3��&7�px�p��D�dB�G)A�#�X�ܑ-�
�0�)B���T��/���ݤ�|'�ض�@V�N�O;���s�j�h��!ĳ"
�ҿee/��^�"R���5�;:]D;2T�p���t?,�|��J%�GX<�LŎ3(Ѡ դZ��/P)���e2��}�#���s`^E��=�oy�!�ĳ汸7:X<��ޡ|	
�p;Vw��:;�Uh��I]6��?��19e��+Lz:U��"��_]3����b��R[E�ᳯ=����h��㞗Du^ig{���n ����x�7��`��Ly�����Y�l��_��_O�`�ӎ��Xy�:Ɵ�������5<��VYݜ��z��/��/����g�F���唂i��
�T�ϟ�����@6���O,����_G��Y��� o�x�,��h(�(�m�h�/��������{P;�O��g{�:&����F%2�W7W�����¯p_�tA�Yӭ&�| ^n�[c�G Um�^a/G�e����`�!)��fm��.�l��P�m��x^o��@��>_a_V֫�u���Swt~��ڠ��`�x���F{T�?5ՙ>5F~�qŧ�o��)�l	�!y����"WL���
�[]�J�v@�nq���׼��ZLȀx�C��B�4�E~�ٴȺs�+�
)��h�N��4�[;|��-X� ���$괦ވx�4gX��jE�����p�O��3�\��Y_�K��Z��f\���X�,V˕h�&//�'�g�Ź������Cn���sm��G�o���xQ�����ڕ����wǽ��U���D���e�N�W׃��_N��h���b�M�:M���d�D3D/�R���*������tNC�5�`FW�2�d(]o���Ft�QJ�0;�y1.���~=]��M���a�{�.ݭ؂�b� �?��2����@�dr�B���7d��_��E�e0�p�6�!�������@$������`oU�nȤ^ٚa2�;/���rwfx+&3��pH.v��� ��}��UGsV��. ���Z.+�\���¡���+�f��x=�e�S3B������0?��dĜ
��$pZ&�� 	Hq>�/�@�D��S�(��|����$h��]��i��[�c��O�"�T�/�.+.{w���֍������]��A�Ǔ��y}�Fyn�̿hJ�Y��	Y �a|è/J�3[/���7ɇ�ͻ'�R�5�w���C(��`��z	��rꋗV,�o��K��J��Eͼ^(H�:#�1|�D���VT�� �}@� ���cَ]]\v	����,���&���7|^d�#�00�k�V׃l�}&��b���W(�&���	:@��_}Ph�ZiLnI�̏o���%���Q�j��Y�q����+W�����'z~��_[���l-<���'�	�5�'����fl����O����������X�q�d���Uɹ9��(����S(?��A�͏�ѝ�U�9!fd@�����~^R���Ko�����V7���7�����S<<��r��Eq�E����?T�:k~ #W��v��&Rd���"�P1&�ow�e�q�����Zecu��O���_>�[	�}��Ͷ�I�������1�O�`ЪǮ�|��*�kks�ϧx0^�c�q��_����$O���꘶���u`�5���<�O�D�>Jw����������5>N���zus��}}>��䉅�|�:�>��*���i����3��<~�W)��b�Wʫkk������z�g��q�3쵸�4��fw�����i����?q�q;���UE$�7w��K�j��[�0*�h�A��]c�e2��c����EW��/���*w$gOV�|tl8���ܿ�H���E��#>���g[�����je~��I����3�c������|��g����N?Y/�) Ң�G�;�8k�����+�'��H��ūz�	^�2>���drFq�	f�!��ual����된z�X_���~���۹��}��c�u��յ�����1��~�g>����i�<A@|�r���|��0kxW�yѿfg�~_��b�1nE>Sbg[9H��l�� �D,�d�#v%+��՛���>�rwO�b��^�n������ו�#��k`�G�����|D,�TWVW�V�W6�E����nk��c��0�>%�U�������>�<���	��ͤ�I��:����5�o�������?3��ګih���\�;��{ā�.ks�BQ��3�����������)�Z1Ig[��5����T�L�(o�C?��GQ�d�J��_-L~y:�bxi�w� ���zm�5�8��}f���Zi����rک��j5)5BQE�	�1��	Zx�M��t�ze{7_d~�%^ڶ��]fp��Ӡ���x�өy��~��Bg�/f����_�r����u�����t�β����R���.��%*H���"���5�������^"񧭥+�O���ҭ@7��N��S�v�w��$����Î����8�g�9�#6�2K�$\�&�9�rVz�F��x�~D�
O0B�?C�3�Q |�(Q���v�\�#�w��{u����"�ӹ�gxql4�e���!st=4��F�����E֯q �q�l��A�����%��V�=|���%%��D���G�C<w��%b�w��snu�\���)�s�*8���nw�G~��@'!B>uq�]���U�j9?��~�'���1A�Cw����
������<���z{��!sH�=��"�T^���y����:����i���n}{���8j�O�n7Nv��A��o0pK���{��"�?����>�:&�H��*���\����x,�Ҵq�>�>�͝�"C'��sM���ϟ�>��?����4�������6����:��y�gn�Q�?I�?7=�	(�e+n�Y	��g�����q-@Ɍ�F�)jz�h*��4��L��X����kR< ����f�$�@��M�!��Ս?�ȵ���g��>��S�bP�Y��j�P�F�x��E]����l����"�yH�d�"&̤���߫������<�ߓ<s�(�Q-m<�d����#u�-P�Iy�H�Z��K���t���N��#����g��3�)�)t���������_`&�;v��No%	vr���⑚:�-��[#M7�|`:0Q�B���s���3����?�g�<����Q � 