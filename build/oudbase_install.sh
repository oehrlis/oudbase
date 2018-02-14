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
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

DEFAULT_OUD_DATA=$(if [ -d "/u01" ]; then echo "/u01"; else echo "${ORACLE_BASE}"; fi)
export OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}

DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/instances"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/backup"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

DEFAULT_ORACLE_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

DEFAULT_ORACLE_FMW_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

SYSTEM_JAVA=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA} ! -readable -prune -o -type f -name java -print |head -1) 2>/dev/null| sed "s:/bin/java::")
DEFAULT_JAVA_HOME=${DEFAULT_JAVA_HOME:-"${ORACLE_BASE}/product/java"}
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
�  �Z �}]sI���������s��Ź�,	.�IRaڅH�]~AI;+jyM�I���u7Hq(n��~�_���/������ߋ�3����� I����I���������S�.?y�T�T676����[���Ebյ�z�R][Zc�jucc�	�xh�0�=�p�1'�lgg��v��H�)��3�@���W��P���o����Wkkk�������Vy \b�g>��(#	�^?����K mq�Wg�s{�ZF��X��*{1�,��<�2/́3���~�:���q}����)@��a���iy�kx��j�VٗՍ{50|������Υ�o�����=ch�x�3m������;�����3�f�f�Xl�1���]ɡw��E���J�{��^�1<�o��f������u���rh^X��ر,��v0vG�grH/�fX��Z#��;7៾�,�fwM�[����?�Y����oz��>���a���aك+6��;s\f����4�08}g쳣7�"T��3V���}����s�9>��)�����sV��P��^��R-U��j��S�pƶm˷��0]�F�S���U̳)�4{��>b4�fvl�!�@CK09�l*u������z��H�m�u��p�褵�X�V���<���S����B�m�����#G�Z0G���1cӻG�roڇ�����f���<8h������<�1- ����svf�c42�� ���v#���ӹ<��S��l����u�}pt���m7���m�3l�R������[G���6�e8��˗�;P�ⵖ᦬/-.�s������7�f�}����'��m�Z���-���E��hβŕ|n����l�۝Nh�7�k��,u������a��S)��#����]$��7��w&�b�=��\.��(omY�h`\�s��)�B"jz�rv�s���{������ �+�/\V���8����&����Y�ž1��ڃ����0�/����9{�T	c�~�S�l���a�;<��H*�0SR��IŻ}������.� J��$��ɷκv�e�f	�k��7\b׽�7l$^/I)L�!�$'��qΉ=����
���g��w�zÊ�>���_��n�d3��a7��?�-��[����gs k���x��+�ޟY����׺ĩ��	��(���2=�T�^_.䮩��{��`��~Q_�I"BJ �L��{��>g�&���}�~]N�n@�J� �23�m�L����*��-�<<�|������	���,,=KX�W_|[�bX��w��7�/v�_t򅯾R������Jߡ���a�Z����a��2��,dzF7�yZА�o����2�&�:�}�8�$ʳO�i����Ǡ�6�&�	����?��u�O�}���5V���p�9Z�mY�V����%�p28-���xk{�m�y�����6��z?��;�!�s�"��"eݔ��G��{c�h� M[��'�{�%W��+�`�E�
+mLzV�UU�����l�]boaK|Ό�3�I7��1n�����Ӳ���(w0��ZEm�*$`��K{aV�S�R	�@b �ێO���rF[ȣ�U��ask�H7'/��H�AGO���Q=��`�qaX���T�� o9�A� �θ��;>l��� 3p�;^��fȣ\�H��֦����j���3h��S˯O-�v]�!D�GR�^|jkxq]wl�(��P�[W������PצAݵ<�$����R�,��h�7��j*�m���o�=S����7�QS$��m�؟0��>�ii�V`G�#��Qő2?ˑ�ex*C~�*"�l�9�,�g�
���oQIviض�<����`�h���S��k���\ڼ�)�^3KE�M���8�C��jj>烢�p�5����yQ�ǃ��x �#<sB=��r>������ ���s�r���+�*'E���.���{��E9]��KI��"����U�}��X.�*Ч']��|�+�"�U�Z�����N��(�s%��|��&\z��w����c ��#)�sb۞�*�ড়t�.OW� �̿|��S�0�Q%��~s�P�a��%�%�+:��-i.�_�j��޴K��s��8�υd9�]ú��[�~�5F,�5l��ǽt.'����;N�;@/�=Q���;��&uzp����e/�o�l��#����X��#�b�Q����4�_X�V��z�l?� oTA�k�*
ӽ(D�a�U`�W*!#��@׼�֪��z�����j,%�[`�택��*�cX�:U&C��ll�-���n��yF��E� 2����4������l`����8��\"�uЂK��,��0�Y�a&�g_�5��'�����B�:C�z�^��v@Z�m�X`j��0����f�AOYx'���I�'X$.M����\@���g��O�����WS_��냷-ѐ�M�Kd<��Uh}->8b�1c[
��e#�_��s"g�ȏm�g�e=]��)�|�}�:#��-�CL�!�=@��V��
}$�&�s��f�plG��T�^ղ1ım@��8�у?���<��<�h�%����r����!��΁���� y�v�����o���}� r�=�o~�Q�^,_�}問�2+u��9t�D���
���%BO|�&?�X�+ӽ�]^G��s�W 6]��"�͞VwA2e�`[��Wz�<��� w%���ؐ�~��ne,�H��W'XH���l%��%�ͷ�;�ǳ�e��[z�~��w}�i���1�^���Wۯ���[�84�_�Mc�`��O���f������.�����KX����2��F-/���m�x_p*_�<��-	��G�Wm��>�`t6�1Y~�Ň�J�$�y}V�4���N>��Fgn�CB ���"�&MΗa�(j/aDp��:���)��Xv�:E��Ń}�����=u�I]Ō�вgX��kW�X��aZ�҆5Qm}�Q]���]�C�Gb*D R�·z�+A�7����HZ�d����*�8$�o���v^�|t�Q�HۧM��y�����SO����p}�ߵ�
��¯͍Z�B���jf��)���L��������
#PIy<�.��O������@��յhA��]�7��n�zy#�k�]�v��	�>%����O�x����6~Tޟ�	�#��&X#)�Ä7f*�yΊC��2��jv������n��y8�zR⥔�5/(�kX&v���3�G��e��lf#�2��F6��,��a'X�}���e�S�g����U����*���~bv}�����1Պ/� ��@��̴�T;g�> x{>����3�֭z����F��bV7���hqY�y2�'T�z����1+�̾o.�{?y/��"c����(��@g��i�^$R0��QV��і�`Z�Fl�u]w��~��z�!ۣ;
6|u��'��/�2Rw��lw��[]��?.,�W�>u�>`^�š^��E��6��nD��y��ㄶ��y	�ǩD�;X1m5��7��6���Z4lH����Hi2Vl5c�k��$F�wm^p�E�ھ�V�����w��(�,����B�4u�x�DZ;�����Ҽ��gN"kQ���rq�C�C�Aw�����
���&�m^;��� %�����=�`��|��MI��N0�b���
�3b���qX�!�xp�N)�b��nQzr���\yR���#�s�3���r����O���㞗<�J���`e�nˍy�bW���oCYt�%`���ƣU�9c�k�2[)$Q�_%Jw�.�Hy/6�z�����%+��Q���(��}��%4��[��N��)�|�Ǡ,h�5�"^�x��B��2N���-���	�:�Ϲi��u��D2�һw�Ӂa���T�q$,�)z�7*̂�����_�0���fio�k\�Y*�W������y��O]�Ƨ�\�G�;S$���k97'j7\�WA��G�z
wiN��n����im���6Q���2�X�`2�}��t#�f�����;	M��R��!*PdZdSz�e\	��ү�/�~	 �ڿ��k����g4�����Eg��%[8� Vn�~.h�?��4OHj�ڳ�P��C!S\�m��:�}���� �#+z�U�?���,��i	'܂�y��$ѓ����WՂ�����>{�x�.���`�}�my}�U���i��b��K{�O��Kf�)�(Mo֚�R>P�(VӋi䢓��w�"���&Y�И�����^��������T(�׍�)uA.쑈%��B�φ�f���I�"�G���scmc-����m��gm}#��|���~&��`��T�?y�~���OK����g�ʦ�g��O	��=�E!��S��c��.�K_���}fP���aPZ)U��eլ���l�띝��%��gMGW#3��v���~8��xx
���4?�d�`����6�Ţ�=���X����ق�g_#���mi��I�a'*Z�l�m�w�{G͝�&�T�������f6�TGf����f6���M�L&��Qnf�{7�\!�ōr3c�	�2c�̘�GeL;o?�?@CZ�nՇ��C���� 5U�1�c��ӭef5ϘY�fV�?b�Qq<7��(��/��8�K?�9��
>]`��.pu6�W�O�$���"��1��m��\��f�*>��~{����޾�sy�/��wZ���o���xpS(P�߽ͭ>8鴁�x�'P)bZ)�n%� ��a�
�($և�k35TG��ċ�����hVű{.NVdC��7)�f���ԍ7���	�b�8���::
�+]t[eAId���:�[�*\+���ƦG�/��$[V��x��M��Jft�{��0��.^�(�b�f4UMEY�؉�:��r�3�<�0ԍ��aaŃ�g��QY���0K���|������=Ok���I'�� ܻEۢE��8�iBM;քj(4�lt�K��݅*���5�p��K�i��d��FV/���zYX�ފX�nm�ni�"qR�¨x&�bQ˝���t�餗���#�vs�;*�k@	Z��0-y���^F���A�|��x
s�,�����(B� ��1K]R��d���;dE7yfF N?�Ioƞ�6�����l���R҅ԃ�gN�������s��� ��N5��1���RY�<E���j������U�kO��3��GI�7��ϟ<�5�l��~/Y�{�W��������@6���/*�����d�7��_?y� ����h`���0��:ƿſ�<�{�74�.��&n��M�!ϊ����]$/�0��m�g~|��?��0��������G!�f�"
=P���F�����k�l�?F��|���%����WN�M\�'`ʀG�͍h8���C���o��`w9R�DС��������a��r����M�!�@�M��z��P��)+߽�w��fB{|�]9c��+�Z�\.�B�w��k�%<h�m�0~d���!h^?8�;5C�(�æ�5��U@���uI[1db��?`����JȚOF��cT�u��a�` "��	$��D|��C
G&��Ԛ�Q�sRw7wvN�^w��w��@�J��r8IQJO�5��'�Q!�O�X�����p0T/�b��@�_W*e����0�]H���� �`4�����Q�XN�V�bt슐E�v\���9��'�)[
��&e�h�Ul�����QA۠xN�wbyh�z��pM��ݷ��@cY���曦���; fևKY�1O8���7]��_�J�S���	9��A��'�3�n9��
�r�Gp&�30��Y�5�*o��ަ4����I��A�̵���M�4�w�uL_v5� �B΄Fv��Wf�������P�O'��/JA�W�K#0��'r Z������Ј�g�Fr��o5w*4Nv��,o��	Kx.b�0�HLZKnL��h(��)f@pF �#=�=�!|�Pk=���ѣ�8r���Nh*X��O�F�� H�Q������ry�S�@AV-(��X��|sW��a�r�����x��#܊.��|\~�����_��nM%;Ȳ\;�v�ڻ'�"��J?_{nYch"�Q�_��Pg�b����zqq�1��h�����k�Զ��;}@<[oN��ZR~b�!y�q7����|H%��I��2٢�F���[G��ߞ�����R��(�<�7(���/Ύ�Y��ݾ%��V��FDg�(��o�@KlyT � j�=.ӷ8�.D&-��q+�x���lt�F~.�}�6׾ŞGb_����E�J�˹�C�n�A�]��`W{͏fwLh���EPp���V��'��'�����������aJ���pJ�Qq�r����w�~���C��W�������#q
��Q�����
f�g��+iǆ
�4��A�3��|���zi�@���eLjAZ7�80#����i�i�N8�1�s�X�!0�\��\K��3�D �/J�(o��Qƕ[.�5�yb.�
������x(��L�ב��-�p�p�mGI|iN����#�K�����J&)��qz6m&C�y�ާ�j{4�u ��)���+s��DG�$Ű9�-'�����h� (��#�ڷ�Ӿ�鵨�lH�}�'��]�T7�#�*�C��]l�a�|\4��5c�:Ea�1�p�`��Ð&���� �j�O�!HH�1?�fv_�p�2�Q,\�d�3�gޜ�ډQJ����z�H�.J$u�)xkU)�Mޢ%�D��P_�Մ�ݚ������vW:�7�}=�=��h���$�3�)�+��L�ʓ�-��N�L�n���(ɀ,@��굞��2U^�)MV=�{ ��½RY(�yᝯ�'�I�O@fB�"����� �ѷ!hҪ�B�ި{�9^���:
n�����?��u��<���[�()�2�7g���ӾyT���0��˩��K�E7���6�R���}�����ʤ��h�+n�ȟ�q��J�j+%��{Mx%�����l?�}x"{���91�[%��[`��R��:M��fRǛ��g���*9;���-�Hc�(�.� ���	j|R ��
��c�����:P��ޏt�bb�[�6���,�S}��//��_���c�b0� A`Jš�kB��D^u<�N�y���2�
tϝ����YO:��X�&�'f'������(&����1���De��Q��lX�k��.�iG�s�
[{[n��31I�L2
���	ii1i��F0���IIa@����[t2�k%���Wk�B��-�Lr���m�H���|�,L������Mp��~X/�@�X-����� �q:c_��~�U��o���'U�K�L�a�*��Z�6���o��I��-Z	;sL|z=�.�1fv.�[�(�9\�Pk�\�~ ��CrFc1���E176�,��Ɏ�H\Q�������)�|�5#�dl�g�⾭Zx���Vð���'h�LԓHk��S
�^�Iqw��x�8Ďu�@�,D0�'":�Q�-]Z<������/�?�)��b�_5ҧX|��z�l�CI��N&i�I[M�^�fKe��I&cj�αm�ʫ�?.�GK�`=�y���y���M�Ģ�J��u2V�����n�γ6�*k5v�J��c�T7���[r$uo>3G�r�.�kɛ�ɓp�ҏ�\���}��3X��a*D��#�b~R�&)��	y�k_>K��	"�v0�ӵ�)yi$��O���3��9��xR>��G����J��:����Uwԉ�i%tK���VJD�ԉ����c�n��~;��
�?�|�s�Ͽ����Pt��	G�q�0uG$���eLoY �{U��YM�Z-�/G
���ǑWu��z@�u��!m�m�U�D�����w��o�rw����4�щ�Pq�7	�"MmOY�-!�y͜mu%��0�	Z>'��!��ޛ��8�`A$���ѿ�P���h�����>c�B��H���;/$��?;%d�����%�0��~e��x��}$���/�G�ǯ��������	��|_\�bK�rZS��,Z��R���	Ed��Eݿ$�K@YY�#b9|��U�e��
 �L���M���*7��[��;��q��chu�ў0л{}q�o��y����s�@Y/OO%h�,1j��U�^�w��~X�|v�+򹸠ԈƄ�Zϝ�VL=3�RXx�E�$8@��ߴ�ۓIv�8�����!r���}9ڄ�N�m��2!ogb�c`���\f
�3����d�w����YD�j�l7��_�s�-�ri��X^�����
���pψ���V:���X��̡ La�|\+/%@��`{�F�I%v��NS[_S�R������\c9�
��'އ�]�&x�������e�8PۇU�	�_����.up�#uQG�)�k�p{ ݩJ��jZ�wɾ�Ɨ�� ��M7xl����Љ�;B�BsBi�� �scQo�	��sI�M�� �Wxƻ�v-,��E����}�N�v����U64���C��E��.E+*_��	
�s�[�|����.P)������>|���-��7����҄�m��q�3E������uiY�����l�w)5?�˔ݭZ~�vma�� ��s�Za�J�h<��x�\e��qmׁN^�q	����'�H����,T�@7�@� �������+��AYe�����whm�.*Y(�Kǽ4ܞ�ɔ'���C<��~�П#Z�|���l�c+�C���;��x�E�A�,/���'BB�����
2�4�z� �����m����?1?��j����^hE^��+�?�M��j��G�E=d�����u9���6/5a3ͭ��p+z�9:��]�!������f_���(g�JAq�1�@M/ � �Z��4S��G��Ç)�6��;^yo1�?b�+���I�^S(��Z1(5�vN+��(�r��GN0�����K;/H?�H;5Px�rgnrg�հڽ���=��	O�2��d�W���ɚ�����>:�h�i@L��_��K]3|��ڃ�z��
6��3�)�`6�gk�ya�#��{��~������c�{aa��Zq̙�	��~t�S�_�_�:)�'QP�x��_=<�(7rq-���\�����$��4<G��Y��HL�x���u�7V�{����e�SM0�G�'��c�_��Z��4՗Ew�.��Q�5[�z�:���ϔ�tB.���;�.����@��D`MC*�=�3��;z��Hz��L�%�7zSx�J���kp]^�U�)]ϧ\�I�<'PM-ϯ�O�']S����Ғ��Ӈ�:�4��65��-���шp�ِI,�#��.Q�@4:G�"K@x᭖��H'��^���'�;x��1Df(��XXf��H����FF��&t�,�>�m'c����� ���'`��zWm{�b�s{I��&aN��uL����r�k�J���Y�V����=a��H?s��]�E�!F���
n?�k���?N�9݇��Of��j�*0��������'��v���.{T������񇁯�"�V�f�%-�6��r~�ioN�J("w�m��_����m�=��Y�K�mk8��Y-t�O-*��Nq���ڙ�Bk^~��v�k�L�Ě��}�׮�w�X���1@k����56+����U�Ua4c��34}k�{�?�}W�%}G?Ѷ�n&�7�.j� r�(�&7s?�v,��#�vAktl1⡁������H�O]�\ 5�<c[ t�� [��֍-ٍZ?Ӂi�����[�����`Wn�/�V������5�[Q��� |tM��\nE�
��3nډô�8�^Yݲ��lk���q�v:��d� ��%rt�"<�w�����Sˆm�	&{�\�'Ԃ�歡50\$�K<i�Wc��"��8�y�Dwޘ�ҵ|ߴ� ����W\O����X��#{��/�� V�c���#R�aAGS�C���.4��¬|��e�췦�]�;�k��>�/\���8�4<��&��Q�D�6w��Qd�Bg��ǎ��|��=����\��Ǖ�gq�{�z"�+UB�M�}0�G�YT/@���) ׎����Tf�pG��y�{�^-{}���r�2V���Q}�Z-V�N���ڗ��/���FU@Œs���E��FR)U�4h3��X�bo�&!�ؿx���C����DxJXA	My���o��߿`��Q��>?��)XCS�X��ƗɁ��a���i�.���6wdo��Lݡ�3�A���
M5��Jl�8b:�{>���CUL�jZRt���^��2<���G�\�!�����,�U�O�BiZ=^z�J��<�'WvfA�W�h���cߣC�O)�,P��:c�9��C��`��!��uD��b�h.*@7��;^w�?�����联��*�<����u'�6�nr��d�ir�?�8紀�_�2Nt�	�G.���Y�G�d���Ca���7p �5�s�"���XJP�x��"f,��A$x%���![�7\x�ҽ��+����e)�p?f�g <��oo�K�sʭ�x�OG8��a�PI�H%6�e�Yi$:�,�g��ڝW��Wt�ř~Mp@�s�%>g�E��dI�>X#�$���hl�ە�C�Ȳ)���D%ɤ�KJ�S2��jd� e�$��x,ї��kj:ѦP�N^=�(�̓�oq?���H�sd��r�;Ө	x�i05=�";򾙳k#D��oSդaI.1���h��E��?��x��&ȉ0�'W�����o�!��F�ZG9M�CXNӂ�0��?Ҕ��!�|F#āuZ����s�	���9)�@y��������윻��q�zi��( 왑3���^�>9c\o������n�KLNP7`u�H�ˁwB-���#���7=,��l)-&[L)��������`1N����$F3p�+���3���^o�'��\�A%��Q��o��q�����H��BQS4�,����ż��_%��x犭�
�(��WT��rlƈ	�hư	s
���"X�a+����{]�/�U�^��pnU������s�YX@/"�<�}�t�}�7I��˽�
�n�HEJ���t�|3�6Z����R!�zı7&5 9D|� ���S90�w�r��e01��'�xP^�M��3�n`}H��R8�P����Jxю���f��A@c�c]w��4V�=������\'*1�z����o��L����.h?���i���� 5��i|��;�hf�*�g���Q�4�n�4�n�	�P���I.9$���)�r�x��H��Z&g-�_@���)�3���O\�@�G����	�0�_�B�jvy�MO��i��|��a���v�e�fe�$\yDZ�1�I"�{WmL��|0Q�!'09i�׫��ѧ
��7��,�߳
[HrqD��x�b_��9�:��)�wR��<z��y��	j�E����v�,_!1B���*)�FpQ���y5�/�*Nwn���޲���ZHZ;����xpi#h~1{�/���L��A-�G!�����G_vZ�,PvZJ7�NL�X�b&�I�V
w�<���F��-�;8W��S��	h~⬰����[qI��RZ���SɊ� e
|O�� �Sb�AC9��Ф�DO��x�-�����#�hU�A���%�>K��n���h>>9Řyj�d&���ل����3Bժ^t�-v{�i�����V'(E)@��s+����$Mc���>U���{e<.V�T�R�^L���3���HND�N��I&��7�Rڨ뒘L��!�t�U��M��ju�x��C��&
�buE�@ȉ3R��#�+�:�Y�Z@7�{V{�l��>.���_��}�]�8�'¡��@薃��2qڮk�Lo�d��h�B-ϫT-�����[�/!T����"�� ��W��J��ɕj����hd:�U�M�
�ЙcR��T� ��2;z7��&m�vZ�/���ol�!B$����S4r���fWY:n�i��C ��T9�No���g��j�T+UKk�
gg�m~��6n��D�
j�5�B�S��vY���>TK_�*'���H��b�TbR�-�#�Ꞛk�RC-�C';�1K���R[�"Z�)�*B'�¤�K'Rx@�e%Z����>�8�p�k��0HO��X)gHR�J��=M���$P���$�W�'�@Y�S2=���'�I8@E�\�p�*�qt/�2�V$�����E^�`z����vǙ�f��	�@r>5=K��D#'J�΅I�v���1���|;8������j@%����t ;J�Ȑ�����r�b1$/7%�ˁv9K��ڎN�R�����E��bW�D�	��D�ZM�sq���!�@QgtI�B��tpWuI����@#풀�I��(&��ȫHﱑYļ��p�h;��ǟ)=/E\c�7�k�p�߇�:*^V5z�u$$t�Mn#�U�T����wǆ/��rk^��jd�ORp�~<$Y��2�m~Ló`��uW4�����&��!�k5:��m �מ�'��K�kR�t1��FRQe���h=����9v��]<�"��M܂��@�-�f
	0�m6��&��
`tp���Z%C�����x^i��E|-����A�w�i����#XO�������B���rR!�7�}�ɐ���̭�Ot�!]�%T���Ju��Ft�!�t���!��((#j�3�t�*˄0�����Ǝ������+�j�K+�m�d�:k^*Ta[�`�Ӕ�n!��Z�A*�B�0{�s����4�l��ưL	� ":�?��t��j|�H���co�_��HpV)/��\4K�#߽�ǧKxr24��`����?���2"Z:�L���2�CK� q��"��ʅz.��޵?���9�P ��w�'-��<k�{�ӡ�}p��[�/C�u܎���]�K���W=6�ɠ�9�%ʔ�W�4��*%��3�rŜS:<6`@GWr�Ef��kD����,���eQ�W���j�u�E �d��}��&4�y�:f��Y�\۬T7kt�������c$:����P������)��Zum��Vy
��e�?%�����?�d�������ݓ��?5��'����{6�ͣ�C�K�O��ב,��[X>Jx�,a�p�y�Sڅ�f4�������������,%��=��1e�o�66#�m3����~�G|�d�9�>c���{u�� �����W�����6�-�K�H��%��z�E�S�2�<�����I��l�}Yݨ�W��O����*� ������@U�%���|j�}ؓ�O�<��5���2�h��J\���/: eo(��Y~Pzq��76zq���v᥄��g94/,�cY��MsZ��������v]t��f��!�I� �-<v���T�N�)a���Ia#0�
��Ԋp+�Za����g@��`4&�c�-���W����X}V�l�j��Sh��{�f���`�(��-t�����'4N�+�7>�x�<l���|sG\z;�TK�����Ǘe�.�l�=[�9��~C��~9m(������q@�i�P%C7�!�S��O̫d��c�0�s��a+��(N��ҍ0dQ����'��
����D��^�ѯfk�r���>F/8p���^�����{Һ� G�1 x%�TV���ߣm�r�'��������=��hSA�r��~����D?��`���K����>W��@��K�Y�c2�/�h�u�p2��"��,�A�)��P���\�F�E/_�5����m��9�J-Δx.x���o!W��
��Qz��f
����;97�ka~`Z�Qg+�N��i����G���R��8x���[���_�JU����؝��Q���0S`%�DNi�L��~��
w�8n��N�!�i��� �����$h�@d�9��B�x$b�Z%��@0郎���$�Q��Fe����RXܼ]q:DR����v �c��w;ᩓqa9��+��7N��I�GJ�K�1Q�(ψ�	|��ā�#�b�w�g7�r&v����]��j�X7/�KcR��Xo<����G�ah�W��328f�L}�gՈE©t�H���[¬A��Jz@Ë�B�Jc������,�̕��T��zp7�:f����֟��Juccm3��<J���m�����Z�W;���B��C���󿶹���+����2�������V-�&h���`��7S���:x&��S�a\&�DCz#�w�����RZ�lM����í1�����f4���F���Q����� �EV\e� ^�vᇚ�@�&`���5�e'x�.�6I5 �n����:��մ`,����յ/�իOמ��!տ|��LO0kJvs6�:���J,������l�?FB�u]G���_��Y��GI�����olf��)���pu�:����:��d��QR�K��q����Y�e��Iw��0u�>���5���l�?J���}�:n?�׫���8)�c�\�L��U+Ua����t������y���t���J�F��=v�x�.���	��������_{ܤ�K&��:���aT���6������x v���H�ZJ���xA�^%l{�����x��IGCM'x��������y��lJ9�o����疒�̷�ۯ��
d�%�Ə�cS����oֲ���2���6���Zy�H��{?�$b�!�!��Z�V��"1��W5�o��Q6��Q�;�$b(a�=-
��|�'>��z���g��!w�	~?Ӕ�i�uLY���c���ӧ�����l����Y�<�A|�r��l�WP�7�K��0�bgc��}h;g
����M1��o�������
�'�:$�����賗�wv0|1|����n�=D���������t_�@����u����:��Z[][]_�X}z�����:l����?�^�����Z�zre���ޮ�>�:��Ҕp�s�c�����w���ۤ�L�{�4�	������m����c�A%��X����(�a�(���x�ZȧHk�$�mU��iDbS%2	��Y���r�<�H&�TK��Ha��k�i�K���x���ڃ��k� �a�0�&����HC�M��n儡%�Q0D=& r��@*��6z��	�K�l���n�Ě<�-m\e�+8��iP��#Qvj�a��1t��RnA�-�~+q���wo�sXw���eE3ſ�Hm޻��L� y0t��t�8e�7�;�Zz���j:x�B�'�C�@;��CvF� ϑ�i��|DO����b�;	�$��tO�R����٣_t��\�M�1:<��w�2��9ſx��N�3ye#�ְ}�a�>��-�8��~��Q+�/Y����sGW#��#�����!ٿ�	�pD���[(�,�����e��hV�|�d �2bx"XU���%��}�2��[�t�9��xŕ9�;�:%x�Hx�=������o U�~�I���Ի��n��*b5�;?��~��~�uL����/������k���GI��{�����s���w���H ��ܻW������\����p��ۓ���Q�s�f�y��-w;�y}��[g����Y�"��X&�7���c��?����x������H�}aڸ~�����N��!���ɹ&|n�t�����I�in*������@������7��e�?��2����I��L�*�0^\\��#o����I"��� %�C(�f��z����Q�
{�<�'�R}w<�"H� h���Z�� v#�캜ו?�H��n�3�s��)�Щ�?�-@RU�L)錢M��q����I[I��XUC���ܥ�	�v	_̥����kk����F���QRf�E;j��͇��Vpf����9	o6N�_iN�~�]�ta�ۀ��ϑW��q�s�n�/s�)�)t� ����=���_`%��v��No5	vr���⑚��-�� ��@>0X�S!�Ϸ���YS����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,eiB��|}Y � 