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
� J$hZ �}]sI���������s��Ź�,	.�IRaڅH�]~AI;+jyM�I���u7Hq(n��~�_���/������ߋ�3����� I����I���������S�.?y�T�T676����[���EbյZm��^�ب�J�����m<4b�ƞo�����A���	�E;�$����N�y��+y��cr���7�ְ�����������Zu�	�< .��3���_��N��[`��%���ݫ�Ź�=r��gy��j��{�mzk���M�g�d��h�>[~���L�0�M״<�5<�d�g����F������WY���7݁a����14K<ՙ6��cs��W|���a�}��,��^�y���л��� ��3�����w������{q���2��n5~�Y�˳;�E~������L���t]k�3�a�&��7�eC���x��1���6�:=)���'�9�C?z��=�bc��3�e�}a��M�
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
�+T]t_e�I����½Y��Ooc�#���(ɗU�#;��y.�R��f�6�ҳ��:.J�ا�EUWQ��wb�������:�q�����!��-�x�}�l�U?\��ϗy[�{/��VOi��/7��[�-Zt��;M�iǚrC����.�<c�P�q�C��|A?S`�1M��B⡛L�����9����XP+�q<��q����A}���E-wv(��L����^b�g����ͱ��U9]JД.�i�cΠ��:�{u��<�S�[d��?��Dq��j��%�:M'����CVt�Gf�����f�9jΜ1����y)� % ]H�ؑw����[���z�"}nW�dB���I`f}�:&�W*땧����k�R]{���?N�����'��ɮ�e��{)��ݓ��?5����������ytt�Q���C$˿���ɓ�=�d�F�40<�q-�p�0�-�����c���uq4q�7�a��yV�����"yч�t`n�=��'���������o���>
��0�v���1y�oT+�Zt��W7���);��y���?��8E'q�)/<
OnD��N�<�)�J�HV�#5Nm
!l`���h�,���A(g��~0��"���O�G�3!ߟ���ݫyx�'C������]�z��ra�:�x��X]�/A�A�mӅ�#�쮆A���>ީ:v@Y安�E��~V���K�������h`��lVB�|2r���/6�q�@��O�7�<��ȤW�Z� �@�%�8'swsg�d�u�hw�t�R	�P��#-J�yS�4��b��8x�:X���6C��*������q�R���P^S��I�	�PA( F�!
�FoPE��`�lUFǮ��HBӶKUԂ=�T�$2eK����dl�V����t�<��+���4�:�C�����k��_�����6�4UD5x�3�>�X�*�y®4����?�xTZ����͚��[Į{2<���`���a-�d� =�x�ܢ����mJs���N����\[���B�nxY��%�Aѡ���J&t�r_����\v�/儁��}ڙ�qQ
�2^�[>Q ��C�&����m�N��aUϳ����i�08�i��0�]Z&Lܹ�K �"7��q��3G�@�K�� �(��.����J��*E�G�Vq�A��A��*��\X@����G����ҧ>����ZP��'��xy�����K��!G�]Do��������*\���Jv�`�q#`�����e@��dd�c�-��LA�<ؙ@�2J�rL��O�σ��KF�R��7���p�$�rk���u���	��cHO�[Ӵ�����-}qvl/����>()շ:�p�9��S�!��V`Y��/��MPX�y\�oq6%\ȧ���K��z�nȏFZ��"~����W�y�~���ѷ�H���%4�T�ޥvp���hvǄFY�G�_n�[�['~�~���w��=�x��pOm��S�)�8~.H\�W^n��"�y���Y��+���Š������-_��,:�f�W8��:�7��	��n��B�0W|oS� ��!���C]�ĭ��6j|rBs��k!��EV1Q��}Cz��T�IxQ�A{A�&T�'%M�a�*��:X�z�ԗutP�U2I%8�s@�dp|ʟ��A`:M�-R4������VI��,�.Iq�Gˉu99�3:=+
��������,j%��@�ր�`��Y��ȿ
�P>�%���'GHW��V�NYG�b�U��[X<�0�":�\���	���t'��i�ёN`�u�V8C,��b�+t�M:���̯�N�SZ���;G��M"èk�H���Y�Jamrw-	�\80���#|wk�K����]�l�<F��`���ix�ޓ@g�ޣ+��L�˓�-Q~��H&s��}�d@ oV���O@�������q�=vj¤�c4Y�A�&8P����d&4/���w(Ď��K�I��
�z��r�x��*'8���`������� !��,r�tHoΈR?�e`�Q1��x�Ͽ-���/���K�Ew���6.�����>��� I�H�#A�4-}�=��3z���3K�m�&��|U��9Y�C񈓽i�O$����AU2��׺?�|/-�|��a���"Q(���=k �$L�(�a&��hD�q:n���8'h[I�s��%'6�J#���@�${?֍���lŝz���N-�����+����`�1����CKӄz;\�2��x��V��$eJ�:1kG�+��t:;��MrcO�N��c�uQL8lD�ϣ�"�*�ǣ�,VŰ�נ2�U.�6�����Ҙ�31ɨL

���	yy1���F0���II@�Y��3e2�k&���gk�D��-�Lr���me���D�|�(L�ț����Я\��^���;�Z
��\���dtƾ(V+�������ޱ�O�
誄�R�&|��� w<x ��&z�$U���[�V���z��c��\��(l�7r�5Ru'�l9/� [���bxĉ�bn�#B]LU9��T���6��Y��vuSi�g��8�:�O8g��'[Xn`Ň��Ğ)� ��������4��Q
�D-1�O�S#�P_��1�� Q��!�������8&�|��x�r�U#�{����e�Jb��	I�;u��-r�-�Ii%���vy�3Ƕi".����X-I�����g�E4Й6�K#��%NA�:E%X�7tr���	O����U�bk���ϓ���U�w����|&��)�p�ҏ�a�߼���G�}Oia�m*ܫ� �b~R�&)��	y�k_>K��9%�00�ӵ�)y����O���3��E���UbF����J��"6����UW��KX%t���UJDױ����S�1����_��EFl��i�������iZ�bƷ�mX����1e"�t�e�VX��o�x��H�Z,_�,w��#���?��O�
�C�Rۢ�Yz Z� �Z9}'i�T/wG�?O�1~����}s�`��L�E�SQç��[Tʁ������sry�mｹ��m�Cr>�#,�.k ���vٸ	�#6,����;\�B������NBv|ɮ��ٵ�s(wp�e����q/w�_��d���ٕ��%~��|_\�bK�rZS��-Z�"R���	Ed��E]�$�K@EYT"b9|��U\y���' 1��'eY���k�Ui oi,Г�$B,���'��A�b��>|���닃gC6֠����2ڛ�r�R��˒�fzY����+U���磐|�@���R#:��k=w�Z1u�jJa��bD�� �~փ��%�]b�3��?��c��R��Av�����$�9��m�����*�i�)P�@[�B��Q��޿gͪ���B�R~���H���J������>��r#a�bCc�'p*�����i�C) ��b��V^J�r-~�����:����j�f*��F���-�:u��p"(�O>��޻0LpK5զ�i'ʆ7mV��~�@��Ӽ��4R.`����;����б�[�ZAt�5�v.)ߡ� l��6|���w<��^��b]��cyp�>�ye;lh���*���C��Y�Ek�.E�:�L��xzƹ�� ��(;[vM��M)��tH��b@_+{F$��$���]��ͣ��!/c�y�/<�*��_��-r�R�ck(In՗ �&	3���Җ�-
�U�D�Q���_��c��9co�y�% ���'�H����,4O ��i� 0,�>���vߠSVE'8��E۱�J���q/�'�l2�I<��Ϸ��j�Ii߁�0�*t*�J�P r�N�6N����B}"$4�����F �?c��ZR��R,:%_<H|���7W��K�����+�����46=������A��p#\������S�楦J����aO:G��l�j8��4p1o�k��e�W)(��S
����>��Z��ܗ�Rl=R��ܧ�P��	����Y®q�]TBQ��ȶ�f.S?�YPj�7�tcU�DJ�"ٸK�&����K���[��l�S�;M&f9�ȸ��D��H�a�p�a.]���Q��`�&Rx����� �#���+E]q��k��pm|S�cS!f�)Ӝb�d#�q�=B9<��G3y�C�~��`�'�h#U+��"��ZcrŏN�i'VX�Tg��$�2z��$	���8q�i'8(0�4�a�ٹx�b�p��1�~�U
<A)�A��+�y�Sˮ�z��
-�yT�G4�V�J��D7h	��Bw(�*��-_=)�&N�IH:+����\�Rp�A�tl"��!���E�#q$=|&��	���#n ��Z�z@s
I���� �G�����1�	�����ҍ6�vz�[gB���0[Ǧf�b����|f4"�c6dE$���K�=����0^xV"�$R���W�?�I�޶�=3��1J,,3c{�t�Up�_���tr)��m'v����NUN�B�zj��b�sG����H���A���V1�km}�R�2�Q[_{�6+�~��_���fM���{(.�}���g��8��tv�?����j�j��_�X�d��	����l�K����x�����k��Z5��k�+���i��t)cW�,����ܶ/���/Z���3ܞ��t�����@��H��B��Gk<0�*�ݠU�(�����������J�9����}�P���u��u�
�c��m�[�[.+��8Cӷ���g�c�u�]�w�l�X�yC܁� w��c�tz�WDR.K��]�[���@Dh�p`~$�.�Շ�Z�-X������FƖ$�Fg��mvvW�ask�2�C����e�e���+s�kj�Z._��wM��\nE2�
�F��w��nZY	�����8�Z]y������.93B��f�w�]��@��=�lXR��a���:��4n���"_�N8��͠Q.�{JȔ�M猙/]��M`\f��ĭ����ʎe�?�7����`�8�(�6"������t�af��Fo-�f�5=���]����~j�xޓH�c_��i��@X�/�F�x�0�ᱣ�!_�����qݵ���q%Y����� J$}��B�ܭ�c}Ģzx�����Hp��o \�Oe�W�ݞg�ǈ�ղׇ��+�+c�~���bu�^�}Y���aT}4z9g���Xt��$�R���L�6����˫I��+�/��ߧ�k�M��{6�VPB3�>Gh���M��/Y������O�h
��Q.��}��@}�����4p��L�27�S����ӠEh�BS]eg���)���តi<�
&T5-)�^.u/�nNi�#{.��B`JC��y� ^c�4���cU%UA�ӓ��Y�
����]���a�(�&T,�=�s�|�P.��n�P
{��6�wY���םbu��ާ�ҰH�X΂ɽ�l�Zw�h`S�ωM�&�9��sNH���Q���&a����9��h��B7i�VV�E�3�G��9��E,%(W<]Y#���@,x%��Ȑ-�W�t/��
Ni+lY�)<r������)�h	pN�w���aU� ���$�4���4{��4r;�,��g��ڝg��Wt�ə~M�C�����}
�G�pW2��#���"������+�_e!˦*I�����")O�r�	�Uo�P��U$��K��?�Ś�δ)�¿SJ����[<�b�0��nq�����k^�L�����Ȏ�o��ZQ���T5�[�KLa�6:�vѳ��,;~�@c���5u'�W���ߩo���Fܵ%�:r��;���f��-�W|�U�����$�i9�R��&L?|�S��Gy��+�ԜT����g��u|�׫��0�@ʌ,�O��#���z���.0�v�_ĵ�tVmV׌d�x't�A�w�p�5y����_��]f����-�V��r��R@�P0���N��i�$z37+���3���^ϛ'΍\�A#����	<�1��7�y	��������h�X��%8���y���&�~)�PL�}j�'�,*�u7)ܾ�j�Ɵc3F��J3��SP~t|������?U��RpIG@���.�
yݫC;�<Cq�:�C���M�۷|�,i�܋� �Ŋ4�&�6�K���S�A�j�\-Zo`G{c2R�;ć+���Lw��FG�.m�|��&^?�	#��|S��L��X퇫@?4%j+�s��>|F�Y�b�X�X��9�U~Nm�*,l#��J��^b��ڥ_t�)�A�]�zB���@��S��<��S��W2u4t�	rU.�V�����rib�kd��p]�� �R&�I��	�S��>�["#�k�\�`^||Sا��XJЛ?q���Z��&��\���h���-z"0h#|��k-�P%p���(10E0*K� H#��0Ծ��L!\�j}�坉�9�)D
�^�M�o<?L{!�X��B��@�#���	��A���'�åxJ:�P��%�C1������E�=i��q�|���o��V@���D?e�$c�9�ٗ�@���� e0"�H`�s�.��P����GuKY�`�t��
G8����v1��+�=���Q��:�� `�!e�&�hQuz�;-lY좼��Iu�*Tm�����":��u�x�~ړSL.�fL�W�R�M�z�L<#T���V�b��-P�1jLIlu�}�n�WvJ#�:�h���eC}�Oժi��^�Z��[UB��bv�4�TW'#9=�{�h�S͋���F��tו
�cAC���&$R������&��)�4Q�U�]�u�bNHefۏWvu@Y��'���#��䎏O��H:$��h��B��P��p t���X���8Vvhl��Z�Ph4b����U���S��z��V�C� U*û@��/* x���R=cr�ڵ�S)�aU�nS��<�}�Ծ;U*X!�̎~�a�V;���L�5�pO=r'���S�K���fWE:�0i��C ��T����vo���g��j�T+UKk�
vg�m�kZ�i��D�
j�5�BRt��v�J���}���,UN���2�Ż$�ݑ́Ѭ��\�j�:a-�Y����B��1@O�Wq�q/L�������W_�Ak����@㉣��X��Az�$�J�8C�:V����ƨ�g���>g��?���R��72�4�N�*J�b�CWy����ɕ��"�CO& Ԑ8-���+I���;�l5�"�M��	/��,�vl�5l��͟:&���z6�`>z��t���b�/*.^Po��ļ~��`G��/�=������/~���g��r���R����N.i=.�=ѡ��	%QB�2Q�V�6B�"� P4�Y���0\$�Y��ib:�Hd�$���c0ыI�y�=�S"W"`m�����hk����q�.��}�;�4�9�&����]*�	K�*�c�Z�_�or�(ғlMF��ď|0і�x��>��Y�v�%~�<E|a���w�j5&�(l �מ�'�<�K�kRWt1��F��2�F��B��� �A;.W�.n���ρ&��PsF���z3��6L�]�}0��I��f�����	H��y3��"�n��� ႋ��Ʉ��S(����a�#[�ma�X�xa9���[����6IX�m���;���v.O��H3����G$�gE�xK�RP&�	|�H�{��H3ĻW���t	��P!ý���~���#�^.c���9e*u�a��&e�:�~�Jy�B=�[a������B(
 ��˓!e���Ž����!���-ʗ�P��cuq�
o�$Y�fm����6�gA?4G �L�y�IO�Z�Rb�:c�+��^�S��Jj+�3|�5��]^^�Xr���+�lo��:�" }��-��&��,QҌ�j�k���&?���iv��1�?�ȍ��c��/�������mT�*O������ף�����|��O��]��a��S
�{�W������ytt(~b��	�:������G��^���"��p�����1��������ݽڙ���g{�:������fd��mf��q��/p_����f[MΘ ��v�� ppT��j��{��K���uF����u�2����)@��a��y5�L�ժ�l�}Yݨ�W��O����*��������@�Q%��3|j����O�<�	RB�2�C
���J\1��/��*�n�,?(��bt��O����B��RB����j��,�Ϧ��֝�^
WH��F�u2<��7�0�a��`�Ds|ӓ�Ӛ^x#�q2МaMl.���ג�Y >Q#πp9��}O7�j�o,<�qU���Re�T�T�B�@�0y_�<�<w(,�T\O�s1�+�7>�x�<l����掸��ԩ6��ǿ9�׏/��]$�{�$sv{��#.�r�P\G��-�,���� �J�n4C�=%o?1��a�m�aN�4DY�ft5��|��!�k�]]�R+�j^c;k{9�_��"eS��}�^�Kw#��XhH@��d�L ��b �%��Є12��Ye{D�ׯ��h�{�֠}�qA������,���o/=� ��'�[�k.r��4��ϋ/Z��F�*���`x.E~�p@.u{��?�����W�r^�� �X��GJ<��r���炷�+�f��8=�eR3�A�ݝ����0?�dDl�i8-�B�@|�85�����K���*!Y�7�"om����;�rg�y�nl���	?QP� S���z����u��0ƾdHs|w9����<�*	�7�a�/����6�U�<!�> �o�%i|�b��=\����y��dzW����v cxŻ��V/A\XNc����ӀTcb��H��CcI3��Ҳ�HN��$	�nD��2�9 ��0�{�=��ڍ��e���y�]����la��x���E>Cý�h�<����g���!	{y�"m��n��`�B(�w�O 
�X+�Y\�?������wR�jl�y�1��w���t�U�k����Q���k�����½ڙ���j�O�������_�����?��Wu?M3�8�6�5�>��9��(����3(?�o��͏�ѝn��;!�gf@�����~^R���Kn������6���77ֳ��1�����EQ\e��p��5�Κ�ŗk��N�v]�m�i@��os�v�a�X�{׫k_>�W��=��C����g��`֔�h�uL��X����������A���ʭ��n��g����0^�C�q�������1R���꘵�k�`�u������GI�(�R�����f����c$=\���1{�o�6ר�76���()�����_�f��㤔��s��2y�W�T�����Ӎ�?�����Q�����+qok���ݥӞ�%���v��N����P_{ܥ�K.��9�nQ¨��m?w�����K����"Ÿ(΂�Y{�+�s��'��:1�l�܄����o;�v�c'�RN�;�pf7����������?����GI����Xǔ�:>������ߣ���㱝>~�^;R@�E3ޏ�wq����qQ-U+��q�x�	�W���erFq�����xM�'^%��ؠ��E�!9�w`c�<�{�Y�|��d���4%]�2�:���k��������QR6�g���^�  �sN�g6�+(�ޥi~\���` ��[�7�"�)��$�3��U�|"~�����}����^_
~�{�F��gϟ�w���[{��j���30Уew]
Zg|>"VVk�k���O�D����n{��C��0�>%k5��ʬ����>�<��Ҕ���R�4�o���:���I�����in]{5m�>��w�tq�8r�c�X(*>�v���ST�3PP��UB>E[+%�l����1;#���I���b���(*��S-U�����/�A�Q/��.��`��PZ�ͻ�]�L�b�SK#U�7YN;�^�&�F��!��1�#��>�AO�w(��<�ΖA���J��o��K�Vٹ���{{�0���u:5����1]�l��܂�[���\.S׾{�ú�8�.�YV4S�[�T���%��dBɝ��]�T�&Z�3���$����D�i��[����щ�iw�������� �s�rر>_C �����<�uĦXF@��J�5)`2����`šgk�h��Gt.�$�#�s�;����E��v���<��{kؾװM��,A?��~���F_��;!��玮Ff��H����������#��ͽ��0ȂQ������
������Q��hv��n_�Ll��<�qέ.�\s`���N	�3R�^v�p{�c4���h_:	򞨋k��p<�"V#�����ۤ�[��X�������N������x�����j{��>wH�=��"�T� ���{����>��z�봷^n}{����<jwN�l7Ov��a�:�0tK��x��"��C�Ի��XǴ�o��F��n�e��1�e_�6��'�籹��Ad���pr�i��,�7E���w\x37�T���f`��X��ߛO�2��GI��G��$�fzPx�V����h��`�Ib��� %3�C�f��v������
{�2�'cRcw<�!H� h���Z����F>���r^7�T#׺v{�)��pSO��A}�il���gJIg-xh�9�[uM��H�e��j����!UN��K�b.uL��^[��mV6����2�(�Q-m<�h��Z�#u�-P�Iy�H�J��s�������n��#���z�:^�S�S��8�=7l�{r�׿�L�!v�͝�j�.�����#5u[���F�n ��t`�N��?�
��MY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R�"��y� � 