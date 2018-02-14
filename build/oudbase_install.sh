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

DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} /usr/java -type f -name java 2>/dev/null |head -1)| sed "s:/bin/java::")
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

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
            ${OUD_INSTANCE_BASE}; do
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
        if [ -f ${OUD_BASE}/local/etc/$i ]; then
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
� ��Z �}]sI���������s��Ź�,	.�IRaڅH�]~AI;+jyM�I���u7Hq(n��~�_���/������ߋ�3����� I����I���������S�.?y�T�T676����[���EbյZm��^�ب�J�����m<4b�ƞo�����A���	�E;�$����N�y��+y��cr���7�ְ�����������Zu�	�< .��3���_��N��[`��%���ݫ�Ź�=r��gy��j��{�mzk���M�g�d��h�>[~���L�0�M״<�5<�d�g����F������WY���7݁a����14K<ՙ6��cs��W|���a�}��,��^�y���л��� ��3�����w������{q���2��n5~�Y�˳;�E~������L���t]k�3�a�&��7�eC���x��1���6�:=)���'�9�C?z��=�bc��3�e�}a��M�
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
CQI�%`��DXI����e������m�f(;b�XXf���3���F���)��R�)+��N�F<�˝����&t��<ֳ���I���K·�A���V�j�jm}�R�2�Q[_{�6+�~��_����L���{(.�}���g��8��tv�?���)�s�Z���nlԲ�����n�vۥa�� z<]_O���Z����m��1���R� �6�h��vn�m_���_����g�=�{�,mG�#O�`ې"t�j.��(�u`XU��Ak�Q�A���1���u���Xs�q����QvN��4��p�?��a%�ۚ���*UtVq��o���<��*���'�61���F-@�]Ǣi�<���\�Ə�c��5:�x㝁�Ц���H�O]<�5��b[�83A�wM��-IF�δ���쮲���*ez5�#�CǕ��˾��#
V�W�h�\�$3x�J#J�܊d�,��D�+�N�ݴ�2^YdY�q���"�4q;�]r3ƃ:�#�H"�<C{jٰ�4��$�)4uB-i�Z�E6���ox5��A�\d��@)/��3_���6������N1#��dov��?��
qlQTmD�7, 4�;4�ѩ�B�,�����Z��~kz�U�㻦��S�"Դ1��'��Ǿ�Q�8:�=���^���(�]a0h�cG�C�G����k����J$�4vk����H�J�й3����E���D����. ��� ������q�=�|���e�c�W�WƊ�*/V����Iu�^����%><¨�h�r΢���!H*�j���m�k�'���W�yW�_���O�׊s���l"<%���f�}�І�74���_0�)�Z���X�,��{\,����)��,���i�.���6dn��ݡ�3�A��T��:�.%��S	�=�x�WL�jZR��\�^P1�,��G�\�!�����,�SLA��BiZ=^F�J��"�'W� �6#�h�A�0�Q�M�Xp+����\�7�����"md1�	������Oe��a+(�R���{C	�>������M����?M�s���&�:��w��L���m�s��� ��n��W!���pg��7�s�#��*XJP�x��"F,�ÁX�J�9
�![H�<B�^r���Vز�Sx�.�υ3 �S�7�7���r�6~ѣ#��a�UI�h%6�i�Ei�vX.ڋ�굵;����莓3/��
`�q�%>��D�dI-X#v�Er��ѻ-nWV��B�M!T�@�(&DR2������l�,�H�%~���؋55�iS���� ������x<�`a$�9
�0��������a���po�e��ٵ� ŷ�jR�$���Jmt�?_Xv���&F�ωk�N8"د�ߵS��m1卸kKlu�4�w`9�
��[>��&�|-���3�F��r:���M�~8��v����W�9�����k�ι��x�W/�5`��Y02,��G�#��F�/�8\`��F��ki�>����r9�N�F����k�x��M�E��j9-�[L)����å�`2x�9(�@I�fdV���g-��2O��j�FoEx�9bƙo�#}�	DIM�x��KpX���
���L��R�������sNl%XT��nR�}E�>��?�f��/ܓf�?�P��� .+2l�7��Y9~�
^5��j��
�e!\Z�/�vy��u0���"��n�o�&Y�r�WA��i�AMm�����/��oL�>�Z*����8��d�`w�W`U��TC	���]:�f���L�~��E����\יr]7�>$�W)l~hJ�Vb%<�ƕ}��v��� ��䱮;��#��t�~UX�Fn�rM������K��6rN��������:��Z����yԋ�N�+�d�h���\��
{��ĺ1�Ȉv!����#A$�Ld� ԛ����}�DF�'�2�h���2&x��O�7����7�V2>
õ�/MX���!��/в��[�D8�F�
��Z�J8�pigQ�a`�`T��A"|F��a�}S1�$B�v��4<b�;�r S`|�
����xj��B��p��4'�G4��i14�H=jO��K��6t��@�K<}b��'h�緊�{�z%��d� �w�H������E��W���t�&iH�-k_�h�����ɩ���p�懡��b���iB���-�4�S~���K�E%�R�$��H�X�bN�I�V
W�<���Fd�-;8V��S��	h~⢰�����8%�r--����Sي� �m��
�O���v~�t吲C�F�=���)�,��^̏tG�:����E"Y�Ot�<|<@���)&�S3&�DQ�&d�]&��V�l��sN�(��@%�:�(J�{N�]�W�d��`첡>ާj�\b�����U�*!Jz1cRe������*,R�����	Mu[�SF�<���51��BC�%�fq�6���/�+�4Q�{��JNt����!��ꀲt؁8n�SV{�,��;>����_��CR!�p(�h8���m�LG�+�Z6�[-E(4�PK��*UK�);z��V�C� U*#�@��/* x���R=cr��]�S)�aU�nS��<��Ծ;U*X!�̎~Y�a��X;���L��7��!r}���S,r���fWE:.�i��C ��T��No���g��j�T+UKk�
vg�m���6i��D�
j�5�BR ��v�o���}���,UN���2��k7IH�]�@�h�{j�uJ�T	����,EBkHm�X�����9�&M]b;����KV �����K���цK�X��Az�$�J�8C�:V�Q��n��g���>g��?���R��W�4�N�*J�b�CWy�������"WjO& Ԑ8-���+I���;�l5�"�M�����Y�v��&:��(8Q�?u.Lҵ��l��|�����	��6�U�Q�^��y�&6��r)b({|�,��Mi��3$�[%��@;.�PmE���z\��U��\���o�~�&-8l���j�h �$@�ef:�Hx�$pQ{�t�� rI@��$`��('�*�{��D1�Dp3)��3��GJ�KQ�}���:\��[�W5~�y$dt�Mn#�U�T���UvǺ/��ro^��fd�'��n?~�!y��1�-~Ló`��mW4�����&��!���jl<,Q� �=S�Nv+��R%֤.�b��7�$Qe���h=���9v\�]܈"��M\���@���f
0�m6��'��
`����ZeC�����_i��E|-����A�W�k��P���'BPr�������rR!�7��ǓW7n��
�P�Ɔ��P���+5<fA0C���[C�C1PF��g��*M�	�MZv�1	�����w�WL�2��Vn�D�
�lּTh¶4�"a)��B���04�.����-04./��ٶ�a�.�*��:>��+�����[�ҿ���RR��h� !߽�ǧK�s2t��`����?���2"Z:�L@�a��!��e�8�~�Jy�B=�[a���Q���B(
 ��˓Te���Ž�������-ʗ�P��cuq{/z�i
�Q�������e�̫L��J����H�b�)mС�+�Ţ3|�5��]^^�Xr���+�lo��:�" }���>��y:�<t3���m�mV��5:���iv��1�?m~�M��c��O�������Q]�<��_���󟏒��o��ɟ?y�kt�~��^j���_��������=���ѡ��%�'���H�?��-L%<j��l�yb�܅�f4�������������,%��?��1e�o�66#�m3���~�[|��9�:c���{u�� �����W������-���H��%��z�E�S�2�<��x���b��*���Qc�����U��{�����6�VK<�U�!����&�:�y��k�S�eXQ��ޕ���_ uo(��Y~Pzq��w6zq�;��~᥄��g94/,T�cY��M�;�������V]�����/�4AKx$���T�N�)ፌ�Ia!0�
��Ԋp)�V�����g�h�`�'��c���£YWux�>+U6K�J�)4d�=A7���`0w(��U\��s�+�7>�x�<l���掸��֩6��ǿ9�׏/��]$��{�$sv{��2�r�P\���-��,���İ�J�n4C��L%o?1��a����i�����j�:�J7�k���D#��0�V�Լ�z��rB���E��rk�0�`��F�&{���
�����@l�� ��2Y�Efd~���N���_x��2r���E
��������%�Y$�^z ����;��6�Ի�sL^���/Zt�!�⨈v6����t߃0���\��"w�._�5����}��9�J-��x.x���o!W��
��qz��f
����;97ka~Ɉ�
��$pZ&���Hq>j,����N��U1�o�E�T�+h�F���i�[l #f�O�&�Tj,�+� sw���6�������]`��+��J��Dv�+���["6�U�<!�> �o�%���6*�{�̷������&�R�5G��l�P���w�$��i,]X����q�jL,1)�~h,i�DŢ�#b$'�	^�V�T�E��� �Eؽ��w�F諵K`ݼ�.�	HI6cUL����"���^I�z��`��3�����]�b��^o��[�x�����' ��/��,.˟���Y��� ��_u�n�u�n�]��?]g�����ff�y������������p�vf)1��߇�S�ms36�ײ����2�������iV=�&X���`��73���9x&��3��]Q䉆�F�cs'�����RZ�mM��0~���1�����f���͍�l����+a>�}QWY�R1���CM|�X0B����]o�d�o7��CŜ���jX0������ڗ��էkO���_>��Yf'�5%�9�o��%v������l�?F u]G����T7��3���H���K�olf��)���pu�����0�:��R�����H������m�����(I��0u�����5����l�?J���}�:n?�׫���8)%b�\�L^�U+U�����t����f�y�������J���'�{�,8�,C.��3���8��R�RDB~�q��.�T��x�Eo���҆s�z����/R��R�,(^��W�H>w�x����IG/�N� �����o9z�+唸ѓgv��[J�?`�u�~��Y ;��()���9�1e������f-;��()s�xl����ǎi���#��D�5�?�c{\TK�ʣz\$^c��U��/o��Q\l4=���3^���W	�06�ah�uh�z��ؠ��~V*r7���3MI�1ͻ�)���zl�_�4��~������?��'��S�ߙ��

�wi�W�l��xm献r�6rSb�[9H�gl���ĵ��G�JFV����;;x}1|����n�=��+��+n��/�� _������u)����XY������n�>�9���ۻ�������x��Ո�+��/��v�����JS��K���x���<��&��e��ç�Xt��4�m�t.��T��q�u8c�����֎zLQ��@A�_W�m�������� �hl�F&AT6K@��`ẉ�d2O�T�/�&���F1��:��_u��_{@i�6�
pv�3m�{K-�4T��d9�TNx���!
����@��~��-<�ޡ`�P:[���[(�&��/m\e�38��iPFxE٩y�����Bw�/�����o垤��������_ڂβ����r��6�.��%*H���"���=�;@��ZKO�VM�cU�����iw�������� �s�rر>_C �����<�uĦXF@��J�5)�3����`šgk�h��d;�xn���9�{��}N�/�x���@�Ƚ5l�kئ�������M?��[+�/Y��sGW#��o$���}C\d�
`�WN��Bqd�(�^|_�a�n��wO^�SFO��j4��s�/[&�{k��8�Vw�90gtX���� /�g����?��J����yO��5wc8�V����s�mR�-�s�c����~��_t'��[��<Jz��{���~�;���AP�yG^o���˽{��kno��u�[����=y}�j�;'o��'���S����qf��z�e�!�>�Ad�|C��9�1m���p��Q����k���d�����	�yl�$~r89��kZ���>K�M��?�W7��4�����6�1���ӵ���QRf�Q�?I������7���(Z�#����a-@Ɍ�F�j��h&�w4��L��X���kR< ��V�$���O�캜׍?���ݞg��>��S�aP�[��j�R�E�x�E]����l����"�yH�d���KS����"�_���,�ߣ��_+�v�_K?Z���H�uTsR�l���҂>�\=�r= a�� ���ȇ����^�΂�9���x Nq����\��/0�p�]�As����9��x�HM���c�%��@>0��S!�Ϸ���ES����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KYJI��*x � 