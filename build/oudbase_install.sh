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
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA} ! -readable -prune -o -type f -name java -print |head -1)| sed "s:/bin/java::")
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

if [ "${INSTALL_ORACLE_HOME}" == "" ]; then
    export ORACLE_PRODUCT=$(dirname $DEFAULT_ORACLE_HOME)
else
    export ORACLE_PRODUCT
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
� 9
�Z ��Ms#I� V�ڧ��Ӯ+���U�5�'�b7�Q3(U�~=��=��j��@��. ��L��fqL��(]u��蠟��`M������##2#�YU=ș�&2#<<"<<<<�����<�S�T6�����o����+V]��U+��|�T��kϞ���F�Q9����rP��t�w���/�9���G�c�^4
K���1~�kk��j8�����jem�m���U ���w>��)#	�8�yn�g� ���n�-��Q�]8]/d�W+��(�n�-����þ;��oY{4�AĖ_l�P���gn�za8a��7+���z���9Qt���VX�ҋ~q��3���=���SgƂ���Qt��c;rO��wσ�ǖ}7,��ޕ|z��H@����v��E���F���������ÿ�Dq�z����^���T��;C?t9�@3��	�a�"����s�y�ڠ�2�C�,p�рu���#�Gn(�9:�y9���x���n���s^�hRar��QĎ~�*B����>�i���y�z�|%G'8:e>b!�8 qw��
�þ��:��TK�oJ�J�c8
c�/��pF(S���U,�!�4�?�1bt�/,����-=��,�Mh��{�8 v�9�-���[Ǉ��G�[{��k�W�����p���,C�]������-X#�^�~pz#7�G�r?����{����~�࠵����n�ٔ�Юs�sY�?c����.0��b��j�_6w�w��qK��q5�7���������2R� �[�rG��[ۇ�ͣ�ß�r������h}��(pS6����Q�����Vs�u���/dOL5L����[��S8��wS�5���s������a��n M��X���y�ux�ب�t���Lrp/G��}������;x�סs�.�u��ny��\�3n�IQ!5���w�3���{�����$�)�_���puo�M�m�����Ĉ����3�� V��t_�?g�l�0V<�;5Ζ#����ï���ꖕ�Q=�U������u�/e ��?�|/�|�3hly���M��:�M��:t/��W�K2j��x�ߒm�v�3bO��_��B�p��y����ް�Y�*�ݷ��r���=�4�y/�x]���n�ZY.����+�ޟz�����:�����yT��I`�j�Ө/r�������G�IV��?��!= �:�]�mp�ap�N\�O��m�59�����d氁2Y�O"p`�+675'y���Ǝ�w[�@G���tA,a��}�S�~���W�׿ڭ����V�zx�]u0�2�.P����	[5����O�w�@���Jn�t���)�&�L��� �Jqa\Yj�s�c�' \Dy�1r]Vt���j�j<U���3<�N#����=a����%\����m{��x9�w��g�z��m��i�4�i{��֧�l��HN?x����7�X�uS6���=�p4i�Ob�K�";V�+��"w��6%=�쪪�
�[�M�	R�.��H|Ɯ�?�$�g#<"�%ֆ�5�m�{�P�`0{%��ڴMH�l��´��'�ץ��@��Mj��!��/n4?��;-%��h�=�U�F�nD���΅��Pz4�S�N���z]����9?�a��a����t�������<�%��nub�>��-~8?���]������ �Bt�$E��'��W��F��/B'���}g`���\7�Dt+��IPw�0$�*-e�=m%(�M j���
����?=W����7pPKD-	��֧OXh���Nt�h���>���X��D�2�*C���#��g��4�����8���d��`���s���e���l�������g�{E,,%7)�o�t����]���WUc�$� k��]��<�z�恌���	�����h0�2Dh"��h��"�(V�UN�.�]L����)Kr��ȗl��"�q��Uչ��c,�p�����d��>~�/�a�nⳎ��j��a[;8(��4Ev���O���[O��nJ�[H�:���;B��<'��9!ˡB���N��
^�����}*����a-������4]���#0��В�Ԍ��R��Φ�H��ǩ&$���:޽t��G�3dy�ck�<��s9�`�5�)p>��HF�����e�HUR��˔�.{�z;s#dk�>.?���n��:C�z'~�����Wߪ�\o�������Fd�.�f��1݋BB־y�{�2����+c���r\��Q�gYBW�e�
�u����<B%~
�V��J;�������S}�����f��g�x\bK[L,J����+��̎�+��z�%�l�-�{��J�U��jq=��s*��� lā��G��*o;c��RC�e�S���7�1,&�AǬ�#����a?16����$.]�,����"Y�g���j{or���� `����-ё>L�[d���]hm5=9bL1��́�&��$��D�b�_�O�z��7��?�����A�!b
�������k�O��Q( 6����D5�c�8귧�Q\Ј#�m	�;��N��-����x���E�-��,���%����>lN/��{(˶��J�?�E�o��A�(��+�"�C�b�b�z�۰�vPf�oo2`;���/�T]h}R�$��oB�b���r��p�A�k�s�|�
��ÖRE�գ�5�.H��K���J/��U�▘��d��@v.d���A,�GR;[��W[m���p�b�x��B��?�����s��-�h��޻>l7�oŷpBzI��~���ڄ͡Q��h�xSec�4�� 栌|u����~���,�}^f�Щ��U��Ż�N�[v���t$�w挳�j�:%Λ+fg����'OQz��4JR�7�am��Ґz���������lvH�i���EC��eX1�!���~S�3�>�Ьu'�S�/[<�������o=�����{�)����e���=��RִZ��w�յ�����<�y$�B�Gmi�z���{�ʆ]Ѝ�������"��K@��z�J�#�������A��?�jZ�Ggq~,~j�O�'
��a�׫��
x����U�W�UY����:��}��K����N��`g��.	����鯾־d�߄�.�:!��1�=�%d<���T�	k`aR�Y��V��je�I�,x�\�n�j�"�	�rLq��V�nm�;�Y�'!Y,	��?���uP��5A�!.��������y��I���Y��J������ۯH�aVe�ȫ8K�{�x����z��^�?oc�Ǳ?|�ޤa��6����s��s¾���8��cv�7ITY�M�������u��j/����z�r������?6h�6x��:����p�c�Lo��d�L
�B�^���{Vb%֎��YK�������gJk]B)��[Z ��nooa��U�p."����=���}I5	��ahh/w+y��u�Pʀ��з�GMt|o�^U�x�T�B�G�ƥ�K�|��q�G���v����~��y���Y4*A"S�p=A�F��h�}�H`ހ9��w޻h�5�o �d��eeKX�O��"MKN����04�K�w��ZpV�2�-yjoM}�j0��!5<;G+K��x�fc�(Ê�%�a�K4�rD[����\�l���0�i���ġ�[�	]'@�7��am ݢ��}��ќ�sپ~־	|�[/����V����u�X��p'?�Wr�TnX!�0	F�o!	Ez.���?�LLOZ�k�i��`k�9@���a��`�����su~x|�w�����}X�_Z��S�,�Q�m���j!o�R}uBG����#����� ݏ�
�X� �m�.>��u"rP�:��P�m�$���8��� }mmhth�ڌ<Z>���c&EW�y�sxt��V����(�1`�תT�#G�'T��
��:��k���N^ �Hx��+���P7T�Nd=�O� $4B��^x�)��p/$=8��?Jg����>��>���_������>>.�k�|p�C�;V��S'Z�,Q�"��J��._O�����k����+��w��޿0k��ۛ�suhU--UÔ���~�c�9��{o����DZ�]A�aR�o��E�1f����wN�~�[�����z�~Z��>��b�m�'���}���'Fj���cMeb�p���b����pk����r�v�Z�E����9.�Hւ��d=M�z2k�iL�'�k6ᖉB!F�H*�DK1�ot��'�����%�[I�$�[�^G5f�s����SnS��S(N�>E��
�E�
�D�l�֘��@�� ��`�>��>�F�~���~��9�����q3&WO,��y(Û�s�j��xIQ�쓺8�bti��D@��7���L.ř�3i����F#v۪f����o!L0���Q� �wߒ>D�5��|;t!�b��O��)��NF��i�+��7y�Y��o|K��OM����z&o�T\69a�e��7����fD^�O���Z�V��VK�$aS�a�[a�7��}c3�5�v
�ņ��F��j�vi�4)9�x��&g��ӭ�o�	�j����d�X��8��`���bt5	Z���MO���ϡ4+V�q�#C���df��������;%��SO�
Ӂ�$c��[䌍��8�����M�~��K�*��ku�q� �x����K�/$`������w_���%O}8o_�/Y�va�'<�������o�RU��B�n�V�4����V��PZy�1�Z���C@7��!��U�MV����Ts$��d��0hV���~���K��F��A�9�3���X�q�)a��Dsl(��u�K�a��jJ��{�)�
E��M�sQǈ8p����[?)\kەu�j��k��=�L/,��v�Nju��ն9�*���(g2���[�b�ZIIc�.�؂�L!���n�Q��&���Hj�P�Ζ������ӻQ�1.��}ʩǍ:CA��P�H�}�v��_�5Ҧ��6k-:��G��p�C��"i7hsCI��D���nEyc\��V�ʋ��&̊ ��|�w)t.\���3̆����$��hz��MZ"8����v;�J�h�1�P�qk]��ԁ�'�	r���@a��Z#�#��X�?�r��E�C�7꺍|��i��⦵]$��E�o�������S�x�6�Y7��(1
��i���JP�7��Ϟf^5���8����o	��/��t'����4�{)H�g���zm+��sr-�v��$񻱎n�o�I��d�i�*��d��k[iMh�~!��E�L�W%)��l#/��7V��F�����|�;	g�u�hw���_�y��l��bܬ;��#���6�z^��)�t�������*<���j�Lg�T\%�h8=FJ+m/��1�,)9���f�n�L����Xtt]�.�ԒN+���؄�S&�I��
O�45��VV�&��S�v����tԓQm(�v���1���`�5�R�:������F5�(�M�������QС�dz�;usb�,P�Jf�^�`�q���[V�W3l E�e��L�h�n`dQ�t>�22��$v�����5�X�Y�xI��-9�Y��"�s�������
�V9�&���
"��!D�2U&��0�/�\U��&Nx�9�����@D<')B�y�9�Cq�1�����?���q��D{F�1��H9��zh�V��r\}�!�΄��꺁w�v�W�n��U����*bJ��`�p�xF���
F|�<��<��7Y�J����Q��K��+`�d��9wp�ht�T�`m���FTR&P"�=D,J�ܧQ0����j���[]�P�?�kc�V�P��Ju��1�/=����O-�/6�G"����@�Ϯ��
����.��(�_u5Y�Dt�jK6" �'|KY=�����~1H�d�� o��Qs�}�Q=~5A=�}�z\�<�����]�ax5}ʾ���>RF��lHl���+��=U{/EDN{�y��G�Cg�y�yl�#o�&>w,�qǬ|j�37����'s���檛Q����p�^�D^/(����11�Wv0� ��橽�A�3v����4{0��~ݫ�(M�c��jg���CAM�����Dُ���oW�oY�L?~�6��L�w��S<	���[�L���R��^%���^$Q1���v�P��b65c<LN���i��VÆ������n�R���xg���[<��[���S)�?vF`^�͡^H�Eb~lu"O�B�����8/A�@����}C�b�Ը�h �����R��=!+�J��{���@̡���c��W��o�o��߅��E��b�m��T����2,8^����n����K�q��C֢YS����.������%�+��L��x�$&�
<v���7��@ N:c�����!N���<�?d>��2o�:�Cbu�m[�����͢��.栋1�P�<֎��C�s�S���r��������~pV��r$,����(���-O
�+;Z��ʒ+̂�A�1��pEZ�i2[)&Q�_Y�;�ٔ�����Zzq��x��T2�͟))������0���1H�6������|
ʂQ�`/��q(� �,�2+��b~<\����G��v��QWjH� s/�yS?�9���w�
)�$��+�l�F�Y0�Ar�y�̞707��M��e�������|9��t�(ï��e��h����K$���k97�
�.�렳���/ҸCLs��V��^P�����ne}q �޻)s��^s�x�u�l���T��J�hC�����r�� �Xٌ�<�r���|�w_�����_�ȍAJ�`�3��2���J�4|�z&�x�4`|Zy6���sQA�J�"*�=!q��kMK8B=�/�!9�s���E��̡�� X1�6�-%�e��#��G�4���|$����U&��ϳ�}�q	G<ٝ�1�J�s�I�{<��;V׿���)�O6�'.���Hn��W�-k�b��$��[�K���]���q/̵JE?��&�P�B	�nbNir�$�fu�l��Y>��~��'w��$������������������c<s��Od��ܯ��Sd����|V��O����T�0��:?�-!�5%z���@��dF��wRzN���Yо��J��p	�naS�>w�ң��G�wv�O�Ǆ]͙�rt5tsj�k��#��� �н]�=-���;����`#_,ʿ��s�.��*�e�9�[�~���I��oK�:�m�1\�h����y��m�5w�6�w����&7�jn��+�mr�6���w�ҹM��&�n�;�I��(wn�{7�\!ۥ�r�ƴc�͍i�ƴ_�1�g�k��i#J��z3�� ����>���L�b�V�s�ѹ���jT\�Mi5*b�J��Cm������+�L�e t����C���S��By3��h	�	Q�9��lg��uߋ\~��֏�?�Z���t.�����V�� q����5� �
T]�Kn���x���(TbF-�%�"��a�*�(X*�S���3Nu�D�	ŋ�����jv�Qp&nVdC�lvin=��k�io~���p)�d�¬�v�|�j��.����$2�LQ��­Y5�㍿~L-�x\DC6[V��x��M��Jft���Ӈifv���E���4���n*�ls'��,r�gP�8�fZ-���J�~�N3Fe���,Eg��c�9����^O�Zgh"/��[�-Yu�`!u-�&�@����j��}d��程z����f����uHW���xh&�|7��Y�leaq,F+aq<��q���뢾�Q�TŢ�;O6&N���I���)��vs����@���4-���u)F�3`(k�6o��`n��������\�4t�c���Xg�$i3�ϊ�}e& N����ƞ�w�����잕���B�Ŏ�sV������-�Omj�Y>h�[:Vj�ic��w��Vy���k���Zu��TW�����������o���'Ov��o�?Kք��#�S������?����!��j�����(�߉���ɓ�rx�{n	���0���ƿ�=y�\����x��t�s�Ƴ��?��)Qm�Oz����~x��*������������������������?�mu��Q���ǧ��P��_��WN��ud{�sC���^ �RI{�t�t9��D��~ �KYJ;B�%�S�d��w��=s�c�:BM��`���j�<c����`���+�Zʻ��k�ɿ�u���=��d�)�Zx���N�ذ�Fp(\�/�s��՗�J�-l�(����
����J�ͣs��c"� �c�+�����FY%�-c"+��:c����b�J�!IQ�H�5����3��klg?p:=~9�W�z;��G�J$²Oe9Li�&�sPCH3�`�Tz�(ꬨ۲���PA33kj��;�L�$2eO㑲�z*s�8�O��곢%�@s�}�����N�꠵d�w�u	^:K��g fv+������qz�`~.�{TV�����ߤm�iǭ�0kR5>,���c>���1ϓ4��U�5�:o	�٦4�+#	���iY���i��"k�C,����"B̙��������r�9�''����ͼ��R��3s�S ��B�&�٘�����z�{����fs��CI�u%$&���\��s	cŰ���
KnL��h�a(f- 8#��������=���ѥ�8F��~l*X��o���� Hޢ�G����奏� ��WZ�L6�$����_��Q�g�^"��b��-�-�������WoM�8Ȳv\�,�����2����)M���(��E3�Fsv*Ч�rD9&��GJ��Y�X�^���E�x%�����ak�h��c��6%��n�t��S������R�lR�i����V��&?�҄�de�@�]� ̖\�.h�
���L��dJ��uі1�xpZ�6�wC5R>F<k�(�J�����~�Hbȹ�B������#������UU�}����{;�'��}�Vٷ˹�86�N6���� 8n �+�sBʌ~�<�O� ��Y�\�����нH�_]�I�aŞ���w�v���1����h�f�Q*}�)`	f�x�%�C�����ÖLَ'ڃ5�y�,����6��5x(�"M���r�6���m*i[�gW�p�������l��r�VH��i������-<4^��cʭiqD�4tv�ٹʡ�Mc+�����d��ؖ*ɑ���YCP	'l�oo�|O�d�*�V*y� ��E�t`gq���*^C���h�5�"ܞD�m��ְ�8!'�b�h��[L�k����4�v3���[$g	�>��'������k6�Q�8:�c���q���̛�F;)J�j�l��9ҭn����U��єF�d�,z��L(0��,&�	��5�e���i��t6k#�z0;w}�Ĥ��L�8����XY���3�'���mi�w������Ü�.���m���ܹ/����xNi�0�}�N\�Tx�&&�(_(5U[�-Ȍ�^���P�S��@m���z��rf����Q�h$�Bv����`].D7�Eʁ5��1��SQ� "A���0�G��n9��I7�_�/�I,nc��Y̥��ت�G�ji4\������h�oN=m���`���S��e��Ll���><�#�ׄ��5�V���7-�{�#�F��$Mi�Ե_�z=�%�bD�;!�F� ҘP�������n%/Aڗ���*����7���nRL�y+���/���pf�����x���|�Y
��#Lk8�4�i�͙��ÛN��j��Lk�V[��Ͳ��q���*�$�vkq
	��p�Y��j��a� Y|s�A@t�<�y�Ά��Y�r�q�7C������|�����$�`8-�f�m3�u��I��hH�J�{��gV;	hPpW�&m$���v�ς<������.G�r�*��Ȝ��ލR�k)�
)�wVKC�rw��&@q1����W�j%�?�U�����A�20U����Z�a&'�]d��4�7�f��E�r2Ǉ/�G`a�-:����y��C�k#u��g�}�3`lm�3���ł�DĲ�.r�V���w��i��z�Ri��±T���x��	g 47p���x�̔�H��A�EU�4��q3)�UJLߓ�#��@h.��h�i�$��lAH ��+�˸S�	�_~��0�_5��7}0I�j�ȡXg4}H���􍊮�l�LB+ɗd��#���m���_��%���*�a�szVD�;�5b�@��uJ�)���'��Y�&6<���7	�u���>�Q�%�ҏ�3�UW�(��ʪ$�¥KĦCx��m��3��=��-um�Q�&ԋ�5x�7��$���~����%a`�g��2��_�?����p�Β�Ǭ�3�<j�9gk�����	6QV?�Z��Z��16���H�c���ُ�cl{�!zb�CFj��i�������mZ(�R�7�5�1G���q
g:�2�+,P�j:��|��z,_NT,w޾M������5
�Ǵ��Ť��P�h��rF���ԬwG�?��1�M�����s�gQ��r*"=V�@*3��| a6p'h��<�`[{?���6�!�	�썱��5�b���Aٹ�+�+6�d�OTJ�^�J��������8�O7������I���:�}�|�ޝ����Ӯ����^C��7j���%����gt�aڒ-i,Ũ��SEv*Y�ک���Vς"��$G�z��RT$�L��m�M�`�{[q�����(�s�G���@N�?���Zn�P�C�M�3��)]wx.\��ld@���*��M*�����ͺĨ�YWw��Z��q��a<|�@����"�[=�ύj�=Մ�"�)F�H������<�lv�8���~�y4T:�Á�0H���߶��gP�-q�q�QM5-)��%�2�}�ػw,!Y5w��*�)����ш$\.=-4�����B�)����0�A��8���X��̡ La���V^�@�����v:���Xk��*��Ne(��#�:*u��p,h�O6�'��L�J5S���ÜDۇU~:��j �_��b�J�#' ���5�={�����PkcѨ�&� ��K*w�� p���k+�ki6��Cg�T<C�KX^|�w���
�� ����E��J�v9��La<����4H-=tjgˁK�ٴ�Mǃ����k��h�4��]�٥��8{+|����eSe}�����E>����J�nK�:�ą�X�h���j}��(���/p���a�q�y�E_t��C QV+6'�y���a�������������IYu0��(�ފPԊP��~p�]1g�)O��(���yOI�ĥ#���Sq���$��f����tT�������(pX��d�����\k@�U�S�C�����?�@�zdz�؞�hE:mp~�בb|M���� �V����5ܜr�^�TV �}��}t8͵����#3���}��Fn��^����O�P3+���J��J�^bB��D5�s�Pi]ӛ[,C�ϙ��8a.*���I�Z�P����L�c�%�X5�b"_��.�;�5i>5 8xY��l�{�N\�a�����,[���'J�D���ŕa&Skܣ�S�jQ-V��z�S����0с�N��R�5S��aJQ���7�<4l�>2�	�N6�G�{��#�c�<�w��q��l��'�hMk!�b��X�r�����������GAI�A+�xH����w�v���V�l��'����OBqGd�;��A)� c�J�Ox����6�uM=*+sMl���#'Q.-awPͫ�ًtO�؛Py�IH&)��ˡO��KI9>��M�$��ŕ'.J���#F�S��TO�M��{I��ڪL�	C�.����]�������|�uqV�L��t�Ξr�Tp�L�����rbc��ϧF#�?�C�Z)�	�N^��h(E%�Ex��D�H����e�}�l~G?n�S�O�Y+���铎�
n��_hNA�KV/+��v*��
����ZN�b��5��l1��cRΟ�{�m߃�1)�3�K���*���F�Ze�Gmm�	[P���w�����Ĭ.�CQ���um>���t���.�'S��Z�RY�l��W��������a����*����ǳ������ߵ���Vj���ߏ�,�ꀒ2��ڤ/��.�E������/��@,�:A��EK{�ao��R@]R��X����[�U�htV���׎a��ݰĚ=��|vn���p�؆���C�+�����o6"�0Tq�X�ﻑ��C/�Ю+쒾c�����X��{7�qJw)�!��8�"��J����_�[�x� "ti�s?�� =��ŞOVN]����-9��8�5n������+T��&�`��@�/Ͻ�9���a��$��@/�G2�Ϯ�u���=�D�����w��)q��>U���>ò��,tE�i�v2t��@(J�8V��Q0���H�o I&L�>������ƽ��s$�K���W#����AW��ᜱ�e�E�;�
��<q�)䳲�F�����? +�q��j#R���@S�C'��t��â|�����0�*����:�Ծ5��B�$���x�4���'�x=0&�+��y�O�ry\w#�4}|��,��Zb?����}��b�ܘ���������˿�% ��? ������q;��}������j��n��s��X����յz������|x�Q�Q��&�cc��#����f�)�N��L��Wl��)�_�����4�����Xxjx����}����*K��/醴`��ߍmh��<.��|��@�����$p���d�'>,ݾ�u'AK��M7�U&%��[1'8�z�
�45�Ѵ���8aP1�,��_�\�#�����,K/&��P��D�7��lMP�t{�`�xŝ�E<�=�0�n��� ����#��@���ms�p�@d�,����MSXs�� ��߶l�d4,wA�lh�'�malB����e�i|�c?��g���%�M2N0	�G.���Y��dʤ�S!<}�/�<BԀ���_t�R�zœ�OŊ�9�����2�ǆ�P�k�����lY�)<^������)����p�6����TU����&��Qb3�f/��&�3 ��z�Y��^[��|���9�ʯ�N(nϿ�_�v���h�eas�`�T*{������k���u3���D-Ÿ��%��ԓC�鮞�B�,�U�i��|�O{��fm����؀�^~��ST#�Α��q(��T�&����	��{�����.n�(�MS��^c)��D����|��y_�a>'��sDp^�~k����b��kK\u��w`9C��,���%�|-���o4��y'�LJ9���p��F"�}(���KR��Ot�7~�g�a^�n�k�(	 Gf����"r�O�'WL_`2p��V�I~ii�Cu^�M��ǔ���]tq��w��̴(F2�e���l1��Ƨ��J��d�`:%RrP|���MdV��矧b-��-�2��\�A%��Y�a��s�j_�ed��!�(�)��
q~�����@>�D�B	�ſO\�sbOաB��ɠ����q��96e~a�4e ���Gs�������q_*x�ȗTj5
*Y�V��i�a�#OQ��������A�f�9�"�4i�܋+��T�$�:�K?x�Sh7�K�\,R��#���)���X]D��jȁ���Cm^�����ӡ�,By-r�Ε纞�ު?\����*�8��й����f�� ���N0B����_���D%�\R/�}���H�E	��8i����<�dL��P? �艧N�'/�����<���g���:)�PÈvAQ�x�I.��$��f���r��<Kd��ȶ\�Z�,�����1��,r�G�u �P\��ЄSX�B���5�<�b(���4�OX���
5��G;��Q�UY�������ML�b���՘��ŖO&j7���(�z�?�1���0݅p����$'�GTY��Ǣ�H=���å�J:�P�K�>q�����"<OZ��v|�,�!���F�g�4�u��$��Ӭ:��`�;w�@��Y��E-$��NN\���l��|.���M^�6A-�g����G�HZ�PQZ�0�A��V�o)#H۬���(/uw����{Sk�
���x
�؂�G�
��3+n��].��\P�8���
Rf[���Px�|�<%���T0�}*]�I��
��ز�zz�s?P�N}�/TるX�'$ɞ��<�y�&��3�,hg�VV���]!^����+l���OT��3����ڢ�D@"ϩ���m�fPv���iZ���k%��:^KU�DI��R&e�Lue<�c�C�E�S��0a�n+ʟ2)�ռ)�	���S�0��I�DGY�3�k_�K5j���dJ�I^3R܎�+�Z�,9;��̑5~&�T��O�$1���j�p���p(�8�e�6U�-n۵k�3{-Y(t��k��j���n̂�^�C� 5*#�@�H/: ���z�fA{�F.ى#�X�qS@n��2t�h�ߝ�`��c&+�;�툵�����	/�F"$���=M#7zzq��㱜�y@���nņ��u��i��Z+�J��j�������j�U����$Q�B�Zi��`�d�ʿY����Z��T9���%���n���l���{�wB�tm�vLc������u%���U�~��¸�K\'R<~d%��w��{�1���Ȓ���0�~>J�R���2�ŕ*y�,��I@Q�w�I�\�o!����d:f�
sL�m8@Cv.F8t��it��²�f"������"o�7�q��h��O�2~�~%9���'u��E#�2N��O��dm���1���|;�{M`C�XE�
=q����Ll&�-)b�{"�=�y�4���Iw+˸�b�5Nt���1��E���R�\�}K�7Ѿ��wB�o5( �(��L�g���L�"g�4F〉Y���(�I繁Eĺ��p�'���_)�0C\c�w�k���/�����HL�l`�#���T����w��/��rk���jdORp9��t�C�\Ee�:��N����h�ƀ�����k��t<��m �סk~'���h[ҏt)�9�m��1�FJ�.B��^o��A��8��"����PwJ�ܳ?��A������G���d�oӁ��PC����Ƿ,�W:gn_��xyw�ӄ2�!�A�#����Ϛ�.���/<?"~�?�Lݬ�xn��P�ņ�gi����3��0G��T�>N��)(j�S�t�*KK�Io`Sf���jkq�č�5U�,%���6Q�|�Κ׊U؞!X��R�-�ފ0C%Pl�W#G����xAS϶�p۔0	 R�����.<)����0�U�-��b�!�UJ'Y�V	�W�����\@��e޻����(��r-�Q!�~��!��e�8GQ�j��B=�{�޴>����P4 �{��PZP�y�VG'}�G����_�J���׻�蕶)�F᯺l4 �F����(W^a�4�V���O�X��O��؁	^�)U���=���������Esayg{���n�s��?�֧}�H�ۘ������Q�n����ٳ���c<8�t�%/1�������3�����zu����7��|���ÿ}�<�u:l���,�|�����7���Ӂl�?���	���D�����}���-a�l�yb�܅�6t���������{�s�X��=냴1a�o��7�uc���Y�^�ߓa�t�)���ݭ�� �\՛�V؋Q2?ַ0Z�?$����-d��[��i;���b
�$��7+���z���9Qt���VX�_� �� mT���S���Ss��L|jG�)^��L͖�D]@�_xW�r�"1 ({C�V׋T��`��������-�/Y
�^�н�P�N�x1#P�i\�R�BK�W:u�J��O>?R���8h~gP�:i��52���A�wߓ��Q
�"��>Q'O�P1�hNf=�0Z�{]�����M��Q�U�Ϡ{�c���{2���Q�``V3=�O: \:W����g���a�̈7s�e��v���v�����e�&��[�%;��2�r��L���=#��4��kXR�@'Y �9S+{n-��e�k����l`;��N��ڍ8M�zMcD	3Z��A/�����/�W��H�_��>T��.�o�mr�
�h���� �Un
 �$��
52C��-�n�|3�1�j��#G���%�釫_K�g�,p���0���J���mr���sL&���=rw��p1|�&��|BUr��M��]R_{�5����m��%�I���t)xk��.o��*�)|S���z���r�JwƗ�k-.�2l܉�QH�>�P�K*V�z��Z f��H��|���ȴ;;ͣVc��`��N���ҨB��~��S ���3�|U��D}8�^�W!e��DqX�O��D�VQebP�^L�8�%y���+�g�̯�������%�V=p���]��P����o�$��o,]x����s��jD$1j;o,�DŢ�#b�'��$�_��Q <�������[{,�4b[�]��wiL@B����1	G�O�|�Np%�ꆰ"�5�'��F,,���"Y3���f�	P�^2��:��,�,����߹��]��_�Ͳ�������gk�R]__ݘ���������o�es�^��?�'��>�ꟸ�k�����c<s������ש�-��h���`��w��;
_�:x*�S�a�(�DCz#�������Z�lM��8~���1�����F2�����|�������| �"+��DR1ܻ�CM|�X�B�����ޮ��MRȷ�����N��n�,�q{�zu��o��g���k�Կ���o�z�i{��ٶ1i�WR�?��ן���c<��ۨ�:�Ku}mmn���+|�6�2�����'���pmL;���:�������<�(�������F�6���x�p�����^�X��__���GyR�x��ۯ���|��'#b�Lۨ�?�U+Ua����l�����\��(�3���+��Y�'t٩�x�!���	&���X�_�HȯCnR�!�J]OY�0+�h�I���r<5<���H�ZJ�XP� m��H>w�x�*C��`���זЉ巈}����M)'č_y�7�{{��f����������d揘a�����o�����̍>��㋵�ؑ"+0�~"�I�XC�C<��E�T�<�Ņ5��W=�&o_P$6�\P�;�$b*� ���{��O��6��G��V*�s7s������c�u��յ���������Q���?��������;����¬�]����;aD<C�?�T@�h@��4���6����W��i��G*%#+F���L_� ��'N�sΞ?W�{eq4ŭ=�m5� ��u0d�7����t�XY��������<��pn�m�v[{G��eT����F�V��|:���|���O��gB�Ι�1I�[���w���۠��������,�����d�(Q*�r�emNX�*>�t���SԤ3P��j��&��l2ۊ)�a҄ĦKdDe�c1��e4�L���*�E���� �h����.�.���F�l-������Ž��&:�Io����V�\#F�Mt� �3��bo�6�N�l���n�Ě<�-&m\ag�;8��P��CLQv�b��%t��Rn�(-�~ky����p��Yg�����eE7�ˉZ|t	>�ii�>&�%�*TA��.�;�������>��6���PE����w
�����}�L�r���9?C �����|��q���'������'Q)���,��҅/���/�n����{��]N�/��q���t������1p#��[�y:s�\�V&_�����厮�n�g$���}C$���ዔӹ�:,2�����˸lѬ�g��D<e��X����C4w��e"�ݓ�����5�� ���C�5�:AwGQ���0N������3w�?�E^�������<�Y�g�������_d'��[��<���j{��.wH�ށQ�zG^o����{��:��|�k�6_n�t��`�y�j���<�����j�>��-�S��֊l�<�c�`�����j�mLZ��6^�������|�?��.����0穽��A���p|fH���s�'��G�c��if*�������Y_����V��?����?���F�s�#���|qi�ϊ�G�A�c#��� �	�!�@S�t=�T��
ʄ=C����;V�Y 4�Z{[�c����'�.�M�O5����]܇�z�]��בHꪞ	5�a�⡋~�����%�f�KU%�yH�c$���I��WW�_��y��Gy��ZI���Z�z�b��� '`F����Ix0�ѕ���բ+ׅ!�v0|���
����\�Sg�e�?�;�N~ �g����L��/��p��A���p��%��t�DK�ަ?�$�n� �>lԙ���[A�Ԭi�̟�3����?�g�̟�3����TU � 