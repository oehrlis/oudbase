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
VERSION=1.0.0
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="TRUE"                                         # enable verbose mode
SCRIPT_NAME=$(basename $0)                             # Basename of the script
SCRIPT_FQN=$(readlink -f $0)                           # Full qualified script name
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
CONFIG_FILES="oudtab oudenv.conf oud._DEFAULT_.conf"
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
    DoMsg "INFO :                               directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default /u01 if available otherwise \$ORACLE_BASE). "
    DoMsg "INFO :                               This directory has to be specified to distinct persistant data from software "
    DoMsg "INFO :                               eg. in a docker containers"
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
    INPUT=${1}
    PREFIX=${INPUT%:*}                 # Take everything before :
    case ${PREFIX} in                  # Define a nice time stamp for ERR, END
        "END  ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "ERR  ")        TIME_STAMP=$(date "+%n%Y-%m-%d_%H:%M:%S  ");;
        "START")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "OK   ")        TIME_STAMP="";;
        "INFO ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        *)              TIME_STAMP="";;
    esac
    if [ "${VERBOSE}" = "TRUE" ]; then
        if [ "${DOAPPEND}" = "TRUE" ]; then
            echo "${TIME_STAMP}${1}" |tee -a ${LOGFILE}
        else
            echo "${TIME_STAMP}${1}"
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
SKIP=$(awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0)

# count the lines of our file name
LINES=$(wc -l <$SCRIPT_FQN)

# - Main --------------------------------------------------------------------
DoMsg "${START_HEADER}"
if [ $# -lt 1 ]; then
    Usage 1
fi

# Exit if there are less lines than the skip line marker (__TARFILE_FOLLOWS__)
if [ ${LINES} -lt $SKIP ]; then
    CleanAndQuit 40
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvab:o:d:i:m:B:E:f:j: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
      B) INSTALL_OUD_BACKUP_BASE="${OPTARG}";;
      j) INSTALL_JAVA_HOME="${OPTARG}";;
      m) INSTALL_ORACLE_HOME="${OPTARG}";;
      f) INSTALL_ORACLE_FMW_HOME="${OPTARG}";;
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

DEFAULT_OUD_DATA=$(if [ -d "/u01" ]; then echo "/u01"; else echo "${ORACLE_BASE}"; fi)
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

SYSTEM_JAVA=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA} ! -readable -prune -o -type f -name java -print |head -1)2>/dev/null| sed "s:/bin/java::")
DEFAULT_JAVA_HOME=${DEFAULT_JAVA_HOME:-""${ORACLE_BASE}/product/java"}
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

if [ "${INSTALL_ORACLE_HOME}" == "" ]; then
    export ORACLE_PRODUCT=$(dirname $DEFAULT_ORACLE_HOME)
fi


# Print some information on the defined variables
DoMsg "INFO : Using the following variable for installation"
DoMsg "INFO : ORACLE_BASE          = $ORACLE_BASE"
DoMsg "INFO : OUD_BASE             = $OUD_BASE"
DoMsg "INFO : OUD_DATA             = $OUD_DATA"
DoMsg "INFO : OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "INFO : OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "INFO : ORACLE_HOME          = $ORACLE_HOME"
DoMsg "INFO : ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "INFO : JAVA_HOME            = $JAVA_HOME"
DoMsg "INFO : SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "INFO : Installing OUD Environment"
DoMsg "INFO : Create required directories in ORACLE_BASE=${ORACLE_BASE}"

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
            ${OUD_INSTANCE_BASE} \
            ${ORACLE_PRODUCT}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

# backup config files if the exits. Just check if ${OUD_BASE}/local/etc
# does exist
if [ -d ${OUD_BASE}/local/etc ]; then
    DoMsg "INFO : Backup existing config files"
    SAVE_CONFIG="TRUE"
    for i in ${CONFIG_FILES}; do
        if [ -f ${OUD_BASE}/local/etc/$i ]; then
            DoMsg "INFO : Backup $i to $i.save"
            cp ${OUD_BASE}/local/etc/$i ${OUD_BASE}/local/etc/$i.save
        fi
    done
fi

DoMsg "INFO : Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

# restore customized config files
if [ "${SAVE_CONFIG}" = "TRUE" ]; then
    DoMsg "INFO : Restore cusomized config files"
    for i in ${CONFIG_FILES}; do
        if [ -f ${OUD_BASE}/local/etc/$i.save ]; then
            if ! cmp ${OUD_BASE}/local/etc/$i.save ${OUD_BASE}/local/etc/$i >/dev/null 2>&1 ; then
                DoMsg "INFO : Restore $i.save to $i"
                cp ${OUD_BASE}/local/etc/$i ${OUD_BASE}/local/etc/$i.new
                cp ${OUD_BASE}/local/etc/$i.save ${OUD_BASE}/local/etc/$i
                rm ${OUD_BASE}/local/etc/$i.save
            else
                rm ${OUD_BASE}/local/etc/$i.save
            fi
        fi
    done
fi

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
        ${ORACLE_BASE}/local/bin/oudenv.sh && DoMsg "INFO : Store customization for $i (${!variable})"
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
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg '# Check OUD_BASE and load if necessary'
    DoMsg 'if [ "${OUD_BASE}" = "" ]; then'
    DoMsg '  if [ -f "${HOME}/.OUD_BASE" ]; then'
    DoMsg '    . "${HOME}/.OUD_BASE"'
    DoMsg '  else'
    DoMsg '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"'
    DoMsg '  fi'
    DoMsg 'fi'
    DoMsg ''
    DoMsg '# define an oudenv alias'
    DoMsg 'alias oud=". ${OUD_BASE}/local/bin/oudenv.sh"'
    DoMsg ''
    DoMsg '# source oud environment'
    DoMsg '. ${OUD_BASE}/local/bin/oudenv.sh'
fi

touch $HOME/.OUD_BASE 2>/dev/null
if [ -w $HOME/.OUD_BASE ]; then
    DoMsg "INFO : update your .OUD_BASE file $HOME/.OUD_BASE"
    # Any script here will happen after the tar file extract.
    echo "# OUD Base Directory" >$HOME/.OUD_BASE
    echo "# from here the directories local," >>$HOME/.OUD_BASE
    echo "# instance and others are derived" >>$HOME/.OUD_BASE
    echo "OUD_BASE=${OUD_BASE}" >>$HOME/.OUD_BASE
else
    DoMsg "INFO : Could not update your .OUD_BASE file $HOME/.OUD_BASE"
    DoMsg "INFO : make sure to add the right OUD_BASE directory"
fi

CleanAndQuit 0

# NOTE: Don't place any newline characters after the last line below.
# - EOF Script --------------------------------------------------------------
__TARFILE_FOLLOWS__
� �Z �}]sI���������s��Ź�,	.�IRaڅH�]~AI;+jyM�I���u7Hq(n��~�_���/������ߋ�3����� I����I���������S�.?y�T�T676����[���EbյZm��^�ب�J�����m<4b�ƞo�����A���	�E;�$����N�y��+y��cr���7�ְ�����������Zu�	�< .��3���_��N��[`��%���ݫ�Ź�=r��gy��j��{�mzk���M�g�d��h�>[~���L�0�M״<�5<�d�g����F������WY���7݁a����14K<ՙ6��cs��W|���a�}��,��^�y���л��� ��3�����w������{q���2��n5~�Y�˳;�E~������L���t]k�3�a�&��7�eC���x��1���6�:=)���'�9�C?z��=�bc��3�e�}a��M�
��w�>;z�*B����>�n��X��G^�\>���S�N�S�C,nν[�<��*ǽ��c�Z�<+�*է�1�(�mۖova�HF�S���U̳)�4{߁B3��3;6sΐS����E��:C�{���=g~�����ur��t��k,^+O�b��?ǡWr���!ж{����#p-#������ݣA�7�����^z3��o��Z�����v�͘�w�Ӂ��9;���1� X ���N��������)A6����:�>8:�k�����6��X)�vNZۇ���o��?������}�Z�pS֋���Q����v��>l��	œ]ݶx��~Ö�p���|7�lq%��mn�4[��v�� ����0 K�~�}x�ب�T��Orp/�v��>����w��	��k�87��:*[[�7W<ÜkGv
����^��]���^�:�x5�����-�5���=�����sVl��A�����w����K�����'U�X����T9[�qr��O)�/��'����nR�n��~���5G�Kr)���0I��@�����hY���I��6��M�H�����+�%)�c݂	��$ħ�r;�9�'��w�_�t����3�^VoX��g��+���l���4�������|�׵�l`���"/�|���3+w���\�8�v9cq�[CRX����D��B�ڹ�w��&�����$&�����d�ٺW0�svj�?=N�.�k 9���+0#(��`�:Y�Nbp��&��O����Ǝ�w�'�G�0��@-a�_}�m�a����Կح����J)zx�^ԞR�f(}�z���j���j��]�PJH����p�iBC�ɳj@t0ȬR]��������l��(�>��Ɋ�2��ڸ�&�CJ���֙<]�q��X�/ _µ�hUܶe!Z��S[����ബJK��9��Ms��ϓ���~2���!�s "�	�"ݔ��G Az�`�h��M���'A=!��(���B0�t��6�=�⪪d�
���L�Z�.���$>g��ۤ�����^�u`p�iZC��u\�;�^I��6k0[Ʃ�0+����U���`1��mǧN�p:�%�Q�����᰹������N�p@詵R1��3}��4.k�ڣ֞ju�-g<��w�|Ň���~0�����o��=�%��
nmj{;��m�8?���=�����m�
!:=�"��S[ËS�c�F�E؄��ph�:����<EEO��6��y�Yŵl��g�G#������M.���L�jKZ��BY�`Hh̶1#=a�*4�ai�V`G�#��h�H��H�2<�!�GQ�[6��E����g��J�h$�4l�`��}c0p�a��b���v.m��}������&&�u�͡sj��
5�A�P9q����rϼ(���@�<P��9a�97�K���} ��@ 9�I�����ʽ�I�Ef㪋��p��a����Q���+��i��Z5XW�Y��ܡ� }�q��e�>��_�b/�YEP��Z�ڰ�$
'Ő�+���3�6��S$�[`�-DG� ��!H�������Р?�Sly���`��s|�
�A�+��k�����/��.Y^�h͏XIsA��t��*k�.)v��q�q��rp��u/����k�X^k�z%�k�\NH��b;I�	
��
:�"f7�uǠU�dN6S�.\���vn���V/?r~8���p�.0��v'���Y�ª�����u��`��Yx�*����2WQ��E!�+߬۽R�t� H�J��Z����Rr|'s�����n��v���Ghďa�.�\��ײ�5���N�
���>�1!Adh��EmT�ws%M����5e�[ϥD�-ꠅ�`�Y0�aT����L�ξ�k��OJ3q���u�B�6��'��4�m�	05JJ��o��	g�	#删�L��O��$�L�&���D�/�,������ޛ\��b�K �x}�%r���1E��O�����#f��3��bR6��E<'r�|۶x�Z&�����"��ȧ��32]�2=�^q�i�����&��P�軠6����L5�c�8������]��!�m�w ����)�������E�-y�?.���%���wLN/���˶[�$=|k�;����(��+�|�j�b�z�+�|l�Y���� ΁��Q�+ S��?�IHl|�bAl�tL�V5�x�O��a]�t�R,��z4{Z�)@���e�Vw��˰JT�ܕB�.��bAf���/�r���p!��j�_�`"�)��J��kK��ow��{�������j{�������cX!������_����`rhT������TٟX���^υ>(�\]��㯗�����ev�Z^\�ۼ� �T�b7�-pMKz��8+�ڨ�y}dA�lTc���.�wS��$�y}V&�4���N���zgn�CJ ���"�.�a�(f/�Gp��6���)��Xv�<E��Ń}P�����=u�I�Ō�вg���sWb_��aZ�Һ5�l}�^]����].C�Gb(D R���z�+��7����H^�d�����8$�o���v^��u�Q�XۧoM��y�����SO����p}�ߵ�
��¯͍Z�B���j���)���L��������
'P&I�=�N��O������@��յhA��]�7��n�yy#�k�]�~�@�y���}���<WO�[�?���ȅ��u������s�<g�!�Z�ax5���}�ugw֍���M�)�RJǚ��5�+��♏��Ȳ�G6�e��l�#���
�����r��N|�������-}U����9�
3����_dm�iL��Kw ���-s���ٹ �ރ��~���\�u��&7����뤸�!�bZ\�z���	M�^�x�|������O��K��H�&�j!��-%��΁�q�h��a�Y�}�%$����[`]��լ����d(��̃��]e쉣�F����D����n^s����ǅ���ѧ��̫09��H��m�p�FtM�'��ڞ�%��0��`1Ĵ�<jޔW��DXjloѰ!�ZJ�"�� X�%Ԍ�׾�N�D'm^H�E����V�����w��(�,����B�4uP<�"��mp:+�4/�z왓�Z� 7�\�P�E�-�]����࿂�.?	b��$�-;�A��C�3z}Cp�mXo7�1}S2�<����<?������t�n�}H,��S
�x��[��އt1�G��e���\�}b�ny��=A�p�󒃛#^�#��,��R m�S /T�*��e(����u�� �x��<g�vMUg+�,�ȫD�N~ֵ����ņ^/�S�9��dőtj�=9%��u���Vz�1B�)�2�篂o��-�&^���wQ�A�Y�aV��E�X8 �C��4��Q��֐�A�^z��~:0����
1�$��#E��F�Y��Avw :�z��@�,��b��2K����q�Q^:s�᩠[��0��+�|g��~�x-;��$@�+�*����hWO�!�	pۭ����`�����&��bA��wS����b��x>5�N$��Ls39x'���Y*�1�" E��@6��'-�JX̗~��x	�K iV��D�)B��gt�����EG��'[8� �V��~.h�߈�4Ohj�ڳ2�0��M!S�}��:��N�OC �=����ہz�z�4��.A�2PIPry�~��Z��C��<��g��7������W��ؖ�7{Q�{���3VϹ�WA��Ϳ�`ԝ�t�d��+�c��5���.:�xx&�,�&iol���9o���땊���u.�.\�"v�H�	r!E"���	a>��?�c'���L<}�ύ�����������������1R�����?��S������>-��S�?��*�Z�]�;�%$Z{HE���]��c��-�K_���}�P����PZ)U��eխ���l�띝��%��MGW#3��v���~8��xx
���4?�`�`��Ț�6�Ţ�=���X����ك�g_#���}i��Ia*z�l�m�w�{G͝�'�\�������f>�TG擛��f>���O�L.��Sn�{7�\��ŝr3g�	�2g�̙�G�L;�8�?@GZ�nՇ��C���� 3U�3�c8��3�e�5Ϙy�f^�?b�Q�=7��(��/�h8�S?�9>�>]a��/pv6hW�O�$���"��1��m`�\��f�)>��~{����޾bsy�/��wZ�X�o��׸pS(P�߽ͭ>8鴁�x�'P)bZ)�.%� ��a�
�($ֻ�k3v5TG��ċ����pkfű{.vVdC��7)�f���ԝ7���	�b�����>
�+T]t_e�I����½Y��Ooc�#���(ɗU�#;��y.�R��f�6�ҳ��:.J�ا�EUWQ��wb�������:�q�����!��-�x�}�l�U?\��ϗy[�{/��VOi��/7��[�-Zt��;M�iǚrC����.�<c�P�q�C��|A?S`�1M��B⡛L�����9����XP+�q<��q����A}���E-wv(��L����^b�g����ͱ��U9]JД.�i�cΠ��:�{u��<�S�[d��?��Dq��j��%�:M'����CVt�Gf�����f�9jΜ1����y)� % ]H�ؑw����[���z�"}nW�dB���I`f}�:&�W*땧���^�ܬU7��Ju���z���(�/��/����'�F��w��h�wO�
����?�x��7����!�E%����,�F���'O���1����|t Ƶ��AG����ד'���F����%ހ��?D�Y��/x޿��E�Ӂ�m�̏O������������{���(���LڍBT���QŇ��__��?J��|���'����7N�I\<'`����D�S q
�?҃��H�A�B���>.<���f��s�L7�=7���:�L�����|�j��������%�r��mWĵ��\���;��V��K�y�b�t���!��!Bм~��wj��PևE�k�~�����!"뒾b(ĸ� �9-��P4��\����<�ͬ�@�l��`��/�:2镤�<@2<D�7������9�z�9����ݧT�,����H�R(E�T*M(��B$7�Ķ�ï/���м��9�qy\��A#,;��Ô~!AR`B�'T
��p�C@��TQc5�-[�ѱ+�,�д�R�`�1?�L�Rd�l0D��b�?&Ϩ�
��)8�N�������*藻o%�;�Ʋ��7MQ�w�̬#��Jg��+��o�6��?�V�`(q�&���������i|"X( dX�!��<H��1G!�h����k���'����93�Vf�7�и�E�1}IjAt(*�"��	���Wfpw=���K9a �f�v�e\��|���F�V�O .����)>&8h�������j�4Th��4���.-��\ę%X�;iu,�3I裣a�H��f�M ���PzH!|�Pk=���ѣ	�8r� �N�*X��w�F�� H�Q������ry�S�@AV-(��X��|sW��a�r����p{��#܊.��|\~�����_��nM%;�ɸ"�~׋�ˈ���?�U2���I������L�O%E9&��'���A���#f���y�q8���@��}��:�?���<�1�Oɭi���P`uƖ�8;��
�B_to���[�v[���I*ҕ�M0�@Q̗]�&(�
�<.ӷ8�.�]�����k�}7�Q#��s������+�<rS����[��$H�=t>j���;8�k~4�cB�,<%������-ܷ?i����;W�D�S�?�϶�S����?$��+�9�q�s�<��,��^t���KE�D�/�j�xÊ3�5�F��v����?7��Yp5d�+��)`	z��R̡ֆ����au?��9X�;�"��(i�!Q��+�$���̠Ǡo*�ܧ��հwU-;X�z�ԜutPV2Iu8�s@�dp|ʟ��A`:M�7-R4�Ɓ��?WI��,��.Iq���Gˉu99�3�?+
'�������,j%��@�ր�`6�Y��ȿ
�P>�/���'GHW��V�NY!G�b�i��[XF�0�+":�\���	���tw��i^ґN`�u�V8C,�Ĳ�+t�M:���̯�N�SZ���;G��M"è��H���Y�Jamr|-	�\80��\�#|wk�K����]�l�<F��`~��ix�ޓ@g�ޣ+��L�˓�-Q~��H&s��}�d@ oV����B��������=vj¤£5Y�A�&8P����d&4/���w(Ď��K�I��
�z��r�x�4'8�.a�>����E �p!��,r�tHoΈR?�e`�Q1��x�O�-�:�/���K�Ew���6�����@�>��cI�H�#A�4-}�}��3����3K�m�&��|U��aY�C����j�O$����FU2��׺g�|/m�|��a0���"Q(���=k �$L�(�a&��hD&r:x����9'h[I�s��%'��J#���@�${?֍���l�={���N-�����+����`��1����CKӄz;\�2��x��V��$eJ�:1kG�+��t:;��MrhO�N!�c/vQL8lD�ϣ�"�*�ǣ�,VŰ�נ2�U.Ӷ�����Ҙ�31ɨL

���	yy1���F0���II@ʩ���e2�k&���gk�D��-�Lr���me��6G�|�(L��;����Я\��^���;�Z
��\���dtƾ(V+�������ޱ�O�
誄�R�&|Û� w<� ��&z�$U���[�V���z��c��\��(��7r�5Ru,�l9/� [���bx؉�bn�#B]LU9�V���6��Y��vuSi�g��`�:�O8q��'[Xn`Ň��Ğ)� �������5�nR
�D-1�O�Sc�P_��1�� Q��!�������8&�|��xs�U#�{����e�Jb��	I�;u��-r�-�Ii%���wy4Ƕi".����X-I�����g�E4Й6�P#��%NA�:E%X�7t(r���	O����U�bk���ϓ���U�w����|&��)�p�ҏ�u�߼���L�}Oia�m*ܫ� �b~R�&)��	y�k_>K��9%�00�ӵ�)y����O���3��E���UbF����J��"6����UW��KX%t���UJDױ����S�1���Ob��EFl��i�������iZ�bƷ�mX����1e"�t�e�VX�p�x�H�Z,_�,w��#���?��O�
�C�Rۢ�Yz(Z��Z9}'i�T/wG�?O�1~2����}s�`��L�E�XQ���oTʁ������sry�mｹ��m�Cr>�c-�.k ���vٸ	�#6,�����^�B������NBv|ɮ;�ٵ�s(wu�e����qw�_��d���ٕ��%_~��|_\�bK�rZS��-Z�"R���	Ed��E]�$�K@EYT"b9|��U\~���' 1��'eY���k�Ui �i,Г�$B,���'��A�b��>|����#hC6֠����Zڛ�r�R��˒�fzY� }W����G!�^�����Ft���z���b�>Ք�"�)FȈ���'����K���1���GC��8,������m��I�sE��+UL�2S����D�@'��+���"�Usg�3����;:�x˥�Bcy)�}�J+�F���$�"O�T�c��2�R 0���q��� �Z���eu$ǡ�8�T|M�J1
�7Z�u4�r+�D.Pz�|�N�wa���j�M2�sO��$�>���9��=�Ə�z�-i�:2\�Hy]�go9ác �6����j��\R�C�؀�m�^�xXK�����X����}���v����U64���.�E��J]�~9tܙN��h�
�s�@n�v��t1�RX��yŀ�V��H@�T��1�4����[�C^F�/�@`x0U����=[�$����P�ܪ/AlMf*`��-`֫������׿��3ƀ�u��v �2�K@>��O�!�(#6'�Yh� 2� A`,X0b}�a��A���2Xp��ӊ�c�,���^nO��dΓx`�!
�ou?�%�#�Ҿea�U�T��������Rm�p:���A��DHhZ�]�y�@�� ^ϵ�^�%�XtJ�x�H��t�F����=��W�.o�ilz_S��3?����F��>wKw���KM�J��/8�t�gٶ�pΑi�b޾�j%7�n�RP������}J��H!�/1��z���O)����<C噳�]㈻���N'�m]�\�~F���o,�ƪ  &�E>�q��M�� ��fO�������w�L�r��qA;�_��6�(�\�V�G�C�A��`M���=fm$�F�)rW���JQ�\)������ǀ�B�$S�9���F|��5/,z�rx&f��8��m��JO��F�VB ��������N�� ��
�Ie�"I���q:�.�NpP`#h>��s���gḇc2�8�x�R��OW�󄧖]O�>Z��,̏hb�<(�9���~.�PNU?[�zR6<M����tV.���3�.����@��D`MC*�=8���;�$�Hz��L�%��)b%��@�5��*������)GA��d	TS��c��I��%��m�!��.�΄DM�a��M�.;6�@�����hD��l�$�H���y�h{ 
CQI�%`��DXI����e������m�f(;b�XXf���3���F���)��R�)+��N�F<�˝����&t��<ֳ���I���K·�A���V�j�jm}�R�2�Q[_{�6+�~��_����L���{(.�}���g��8��tv�?���׫�Ju���_�X�e��	����l�K����x����������J����~��@���1��M���B�]�[n���_�-�@-�n��^:K[�� w��S �6�]��ˣ5�cV��m�Zqz��vcp{]cdz%�`���v�]�S�:t�z8\ᏱyX����#�
G�U���[C�߳�1��.�;�	�M���!�Q���Gױh�<��+")���c��.h��-�xg "�i80?�SO�C��"��,�L��]S#cK�Q�3m�6;��찹�J�^�����q�b��ou����9ƕ4�-�/�޻�҈R.�"�f�x#����Sb7����WVYVy�e-���<M\�N�v����D��C���.ҀH �ОZ6,$M�0I}
M�PF����p��/q�^��f�(�=%P��&�s�̗�����0.3wx�S��{eǲ�ٛ�����B[U��M�otj�а��~���a�ߚ�wU����w�T�5m<�I�x�4��zO ,�p{`<�tW���Q�������Zhi���,��Zboq� %��RE!t�L䃱>bQ=�� �������7 ���2{�k�n�3�cD�j���X�㕱b?��ʋ�j��vR]�׾�o|Iǂ�0�>����h|l,��F�J�Z�h�A���鉅����$D�����S�����=��A	+(�t�#�a������lCJ����'V4�b�K���e
�>� ��fa��tp�����Cw���i�"4U����F���GB�p��4��U���+/�:�T7��ő=ic!0�!��S��P�VE�W��������U��,z���E�.�{�0�n�r�*܊�9g>F(���q�A(��i�HY�;�EB�뮰:�� �S�?i�

�T,g���P�O�;A4�)uS`��&�O���q�9�	����ݨ�� �0{�r��e~4Hg��4�U++�"��#�����
��+������p �j�Bd�҆+�P��\z���,��K�s�@���M�8�ܧ�_��`�A�~UA��D��a��@Q�������:���:߾�;Nμ�k*�
�8���NP���A$�`��U�e_Gﶸ]Y�*Y6�PIMPn��T4I�x��CLh�z�E����"���]�/�a/��t�M����W�P�c'��������(p�8�v�^�B�ejF½Ev�}3g�z�ߦ�Iݒ\b
+��E���|}`��{_�a>'��;�`��7|�N}÷Ŕ7�-�Ց�L�94��4+Xo���⛬��V���9�N�9�r�7a���ß�E>��.p^�����G<�=;���^��׀Q Rfd�Ȱ|:d�O��E�@g�p����"����h��f$���;����#��㝦7�Z�2�e䴘n1��"��#�J��dl�uJd��%ћA�Y���I���Zx�<qn�A�M`���g��K8��5> $%5E�=�2@�/�a-�[�+���3�K��b��S�9��`Q!��I��U��o��1�pO�1��B񣻃��Ȱ���g��Y*x�ȗ��9*��piU���y��s�YX���>��n�ݾ�dI��^\�.V�!5Y�_:���B�1U��j��z;������!>\�UUd�S%0��w�@��g0��iOx���r]g�u����h?\����)Q[���pW��3����ƒǺ�O����1h�Uaa�MTb�5��n.�.����9i����>�j���> �Q/�:�����������ry�*\<�K��X# #؅�{�G���2�M�PoN�R.���I�X����Ș���>E�`�R����[��(�B� 4a�r��^h�@�.�o��`@�+,_kqX�*�å�Eᇁ)�QY�������uL�`���U����-�L�n�L�Q��*H�c��a�᧿��ҜB���/NP���"��=<�.�P��Q��.�����*��I�؎#��3d� �y#��J
��[^}�i^�S��ӝ��!���}a���'�&n\��1��^36�g�	Ap�P�N�}�/�uT�DK!� b"�bm�9A&�Z)\��\wG�2���`��X�zpO�'������C���˵�P
*�Ne+ڂ��-�{(<D>I��u�UЕC�M�J��
��ز�zz90?���$_ ���d5NHT<�i��� ]�'��0O͘,�E=���v�xF�Z�����n�9Z�<�c�����(]$�9�vY^u�����ˆ�x��U{p���24�+WU��(�ŌIi���NFr"z��Hq*�OR&4�m58O���k^�Ąb
u�0��I�ă�Vw�۾�r���DEP��J(9�mB@j��~������a⸁NY�1��J���NJ��I�8�'¡��@薃��2�ۮlk�Lo���h�B-ϫT-�����[�O!T����"�� ��W��J��ɕjw�N�hd8�U�M�
�ОcR��T�`��2;�ee|�MZb�_3�&��BG���9wGO��͂��]�,��(�ReWl�:�q�/�/��R�T-��*�\����Vch��9j�*���8
I����ܿY����Z��T9���G����$!%w�9���)5�R%t¶c�	�- ��+b��ү���$^�4u��D��/Y	���ns{/��G.Yb-���T+��I�X	G����z������
�(kxJ��_^��d;	�(Y�]�1��RXfڊ\�=� PC��+L�$����8��L��7��hΧ�gIہc���b��Dm�Թ0I�Nֳ9�ћo�'�^�P(VqG�zq�&����t ;ʥ�����8�7�����<n�@��:@��v�K�qyD��W�s��B�����x���~C����� �����"���E�9ӁF��%,F���^L��ȫhﱞYĸ��p�h+���)=/E]c�7�[�p�/o�_��瑐�9X7��V�SO�JT���.˽y}�����d�2�����乊��;��1ς�#�]���&*b������W�!��Di���L�;٭ ^J�X�����&�0�HD��72��
���{��q�btq#��~4q	.��3�'�C�),����`
�lg�+�1�N`�6h��?L@�C��b�~�qn�pn�I\M�9~�B?F��A���o�#�"��I�����O^����*CE2�^B�/���1l�3�wl�;�@1{�I��4Y&\7i�I�l$�n��Oܹ_1U�\�[�m5+�7�Y�R�	��� ��4w5��"�����W��#D��и���g۞7�iJ���V��������G�#DlxK�R�2D��JyHE�Q�|�
��.��T��Y��_���ȫ�ˈh�2��e�����A��E*��\n��k$G�s��( ��,OzP�y��ƧC�G���(_�B"܎���]�蕦)�F�zll�C#tTsS�)3�2�X+UJ�[g"�9��yl@���d�"���׈`wyyY2`�q�ˢ:������봋 �9�����M���u�x�����Y�n����ӧ����H����%71����?��S�����Fu������>J�����'��ɮ�e��{�-�'j��O����l �GG��'�����#Y�,|��0}���Y�k��扡r:���?������߿�W;���"��Rǔ�Y�،����l�?NZ�n�?�c�l��[����� ��7_��ct~X��0Z�3"����#t���N�t�ϫ�rh��g����F������WY��M��? �hZ-�TW��Ss�ÚL|���n��N͖aE]@�_xW�z�o|A Խ�t�g�A���[��������2���м�Pَe�x6-P��\�R�BK�WZu�J���| L�,�h�kP�:Y��72'����*�'S+¥ZE��|�F��a
�Q�̻��Z��f]����T�,�*է�<�1x��2���Q�``Vq=��u@8t�l���{�M��oě;�2�Z��X:��_?�,�w��g�ْ����zd���iCq_���� �NÒ*��ћ3���ļJ�A:0ܶ
s:�!�F0�����k(��	
^���ZavP�b��Y��	�j�)�˭�à��������* ڿ'�{
 ���G�d����=�(;}�~�F�`���m(�C�ҏW�7��g�,H|{�X��������R�f�1y!/�h�q�p0��"��,��_�}�Tr�ۋ���|�׼:���W�e���*�\8R�ୖN<��\A6+�7��!,k��)J����|���A h$#b+�N��i�z�# �����J^:}�V	�,��iR����;�vg�y�nl���	?QP� S���z����u��0ƾdHs|w9����<�*	�7�a�/��6n�جV	�,��0�a4��6
ۨL��2�Z
���+N�HJq�����B�n#�u� .,��ta����i@�1��x�T����m�r�����'xIX�R-}dvs (a`�Z{,ߵ���.�u��t& %5،U1���ϋ|��{%��y0"�m��DܫF,v��E�fx��n�P�:^� r�P��,&7g�gn����Ս�y�1��w���t�U�k����Q���k�����½ڙ���j�O�������_�����?��Wu?M3��94�5�9��(����3(?��"O4�7r�;!�gf@����ЊnkR���n������6��?ln�g��c$�[	�싢��"���܅j�Ś8��/ה����x�$Ӏ|�!�*���VÂ����W׾|V�>]{Z_�T��ٗ�2;��)9��|�6�+��?�76�f��1�{�:*���������>F�x�]�]�c3���Haľ��c����6�����J6�%E��>H��k�����GIz�և�c��ߨm�Q�old��QR,��q��^����I){�ZGe���Z�
�����5�P�3�ϣ���%�-�W�� <��cg��gr�O�a�np��_�"�k��TvɥR5��-jx+�x��6����������w}�µ�gA񂬽�E�{Ǔnh�L:z�uB��巈}��ѓ])�č�\8����R������?����GI��G̱�)�?t|��7k���GI���c;}�h�<v��H̽��$�!�!��Z�V��"�#��Fxy���b���}G���O�J؅�AC��Cs>����=x���R������iJ��i�uL����c���ӧ�����l����Y�<A@|�r��l�WP�7�K��0�bgc���ch;gt�;�)���;��A?c+�_�'�uHV?bW2���^�������o w��(u������^�]qk�Y�= �z�,��K1���G��jmumu}uc��ȹ��u��m�5(T��ǣd�F�\��~�}��#�瞇?W�r]�\꘦�m����]���6i�/��>�m��k���m�g�s���G�{��E�g�ΰv�c��v
J��Zȧhk�$�mUW�0iDcS52	��YZ�@� �cE%�y��
~Q�0��5�4����e�����J�yW����iS�[ji����&�i�r«��Q0D=& r��T4h�i�����2蕝�B�5��xi�*;w��qoO���0�+�N�3��wL�[~)����~+�$յ�޸��(���t����#�9u	>/�PArg�l!�e�xo��Zz���j:��B7ON��3�vF���$����Î����8�g��#6�2�%V�I��D�+=[�G�&۹ēpcx����; �sJ|��۝��F�a�^�6}�Ƿ�tn��&�Z}�r�\~�;��~#i���"�W8 ��r:��� Fq���2[t+��{�"�2bx"DU���%��}�2��[�t�9���ś9�;�:%x�Hx�=������o W�}�$D�{�.�������X� ���o�Ro��cS�?t���j�;���Zv��Qһ�ޫ����!�����;"�z4�_�ݫ�^�p{�}���z}�}����V��9y��<������>��-�3c��׋,K���"�z]ͱ�i�ކ���?<�\���c$˾0m��O��cs'�Ȑ����\�>7�Y�o���q�$��in&������������7��e�?��2��j�I����&�𾸸�g5�G�����kJf��0�P�=�@3A��)(�e�O����xXC����?h�:'�]؍|�e��n��Fn(��<S�ᦞb�����$USϔ��(Z���s�(ꚜ�%�d�Џ�49��C�� k���\�������ڬld��%e�ZQ���Z�x��:o� 'F�[����f3�������ѕ�	{���?G>\��=���u��9�����p�{n��������C���;��$�]��?ǋGj��/�4� ���D�
����-����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�RJ���(� � 