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
            ${ORACLE_BASE}/admin \
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
� aA�Z �}]sI���������s��Ź�,	.�� )�0�B��.�������&�$zt��87��?گ~s���?�~���~�pfVUwU  	R�YԌ$twUVVVVVVVV֩픞<p*�˛��}��-W���"��Zu�R���?��r������m<4b�F~`z���Zc�A���1�E;�"���uO�y��7���1������������Zy}�}����� �D����_��NM��[`��%���ݭ�ř�=��K�k���j����c�>kZ�V�,'`�d��p�z[~�l�L۴�-ϲ��3}�b�g����F���Ap���WY��~����tg���9��jLp�1
z�'>���tؾ���6[v-��|zg���7� ��qP�յ�����[=�9��/�9��fխf�<ˡui���$��<������!� �a�g��܂z�h�ӱo!3}�Y��a�k!%���%6G=�G�À_�v��l�[]v�z�r.m�u�S�sz�(`Go�E�>�gЭP��Я�J�st��)q��(�ŭ�w+��}\�z�5x,W��3�Z�<e��Dal۱��K�C2B�JըT0Ϧ���� Ri�h�/��:�=CN��08�l*u��f ��z��@�m�u��p�褹W_��<Պy`�����z��B��t����#G��0FF���1�#˿G�roZ�����:�f���88h�5����׭<�2- }���svf�s8�@� ���V=���Ӿ<��S�l����u�}pt���m�����3l�\���4�[[G�����`0��˗�;P��G-�MI/n,.�s�����w�F�uX���'��m�R�[~�9���h̲ŕ|n����h6[�vx�7�g4:�\��p��^Ωq����^��2�}������;x�׾yn-�Ǹlm���o^�3��)�Bbjz�tw�s���{��j���x'�+�.=V�ٷ8����'��Z�Y�ɾ5��܃�?��0گ\����9{�V	c�^�S�l9��a �;<e�L+�2R2�{i�;=�sAӏg�v��R ��Q��{��[c�޴=����5h��.�t/��W$K2J'���I�O�i�v�sO0���������;xY�a����op~wr��[}�tN�Fv��-~���g�s���x��ˌޟٹ����ԡ���˨���2>�P'�/r���{��`��|U[�IcBJ���ֻ�����S��r�v@^�	��]��AAf&sl�ɢv���]e0��}���/0v���:>�=���j	����_�_uO�����n�v���7J����΄�4�@�;Ի�;�U�7�W3���Z#%�B�ov���	9�&��L��� �Jua\^���s1���<�X+��xKj�j<�0)����gA�t��qOXc�� |	׮�UqۖEh�^Nl]jǃӲ*-M���:VR6Ͱ۞?Ok�F�t$�'�C��PD�*E,.�)A�����@9�4�(O�zB$WP��˅p�E�
3mB{V�UE�����l�m���$>g��9������Ⱦ��0�F4��x��z�P��N[�̖qj/Lc"|U+!�X4}��S}��h	y�xqà*x8ll�B���E�#zb�T��� k/�K������R�y���!pG�_�a�4��L�5��x��w��%C"��[��޶�}�/�ϠaVW-�>�|��B�N��������Ի��qP6��;���zp]_Q�S��M��k�>iVI-[��ix+��H7��j
.p����=}K����7�PC$�mLIOh�
qXǚ�U���H�;�82�g)V�O%��SE�?|�����Y!�R�-ɮL�1��{���]m��z��y�\8�Û���1�4��$���ӡ5p/A��P��c>,)'�@Y}^�Z�%g�䀘
>�3'�c�/gc���a�����q%'0)X@@�\\Xy�9���l\u��N�3��t	�i��*����V�u��X.�*ѧ']��|�+vc�U�Z+e���A��pR�9�-.������"��Bco!>�Xg�A���X��.�=�)�b��8܀���y*R5��Яa,�3�?엿�n�by�F�5?f%ͅ=�ӥ�V��M;�ؑ:�	ǹ&,�����l�
��9dy�a��<��s9!���$'( �*蔋��,��V�9=�L��p��۹�C`[���sq��&f�>Rxhz�ڝ��C�f�K�֬�Pk�<����Wd፪�_r�\Y����>�|�l�Zedd�� �+m�jb>nG���̡��2�zv�:���j�?�U��se:�_��V��:Q�Z(�z�Pf$d\���-:�Qu�����9�c�Kb��K�<[�A)���p$è�e%����}��PW��
f�$����l�1̟��h��$�<�()a�'�1"&�Aǌ�#��1�?6��O8I\Y@�K��\ȲH��V̧Z{or)�+��/��ǃ�MѐN�_�)2��,����1Ɣ��#s��1�/��9��X�۶�3϶�����A ��>�ܡ���#����(jHs���6�ԆB���L�\g��8��Q�=��W��GL�m� ��lv�L9&��M?��.�l�/�a�T,-�|�~parzav. /�nr��`��!� ��C������F��ы��{���c��J��d�q��"WM������OB�`��bs�my���A�k�}�|�
��ÖY�֣���.H��,K���F/]��������hA�2�O|!�å����f��j��N.VR�-~��z���w'��7�l^]���W�{����S<��K���f����ak&�z����o�L�������v=����*�:�v	kY:~^b�Qˋk�u�7���7��>Ғ���=�
��6�Bu^Y�;��.?����T!*Iu^���	?�Bj������3��!% �RFT����0b3���#8�u���BK-;q�"{���>(������:�d�bfw`;SLcɹ+��2�0�IYݚj��C��W��O�.���#1b�?)C�C-��`�V���n$�o�_�x}A}��7���~;��ߺިj���ӷ����,֏����'���]�>����z�����F�\&��re���i�������s��N�&L�r{F����������@����xA�	<�;��n�y�C�c�]G~�@�Y���}���<SO�[�?��#��x#+�Å7�*�~Ί�����jz�����N﬛�y$2��S�g�N4/,�k�}&V����>���#��>�sY6������}d��||G�1^�!�3'�����s_�[���ȏ�sx���~f~}�����>ы/���@���k�=�v��} ��||�[a�7�ٵ��=��^;ín ����d�Oh��Kǫ�cV:/<��L��~�.^B���6ET!�Wl)��>t��T�H�`�����-!�8����x�fM}o�4C�Ggl��*cO5^ԓ�d$r��l�q�{]��?,,EG�>uF`^�ɡVH�E�o�{�7�kB�<��w���8/A�85�)�!���Q㦴��&�R#Gx�F��R�)�@�J,�����wb4 :i�BB,�$���X9./�߅c��XY,WJK��i�"*�x�EZ���tVdi^��ȷƱ�(Anp�$�����!Z�{liu��!�=~ı�H��N��R�G~g����;��n>c�ddyR's	hy~�2]���8,���X<<m���`{�(��$�b��<)���!����,9����'z�2��z熋�#����(��-w
䅊�ނ�e�����?BW����lFĢ��J���g]ˋ*��^b�u�9%�s/�%+�S���)��}��%4��[��N��)?~�'�,h�5�"^����J��2���-�����n��i��u��L:�һw�Ӿ�\�޿_*$$� ���fA79�>��/<��^}��7l
�U��,�����RDi�<�Q���ne���v��c�	����G�7'!j7\�WAgw�O�z�t�xN��nF���km���6P����X�wa0�=��t"�����;M��Ri��(6,��<i���b����FK�^H��&r�H1
&>������/>�0%<٢a(� y�ro���s1�@��FT�yB�P�ך�q�y�o
Y�Pn�s�O���uR| ���Ue���
ճ̳�yd�h	����H������W��.R����>=]�QWvg�̾Ʊ��Ս�ߣ�׬�����
�l����V���'k����%���b��,���H��ݑE�>��a�/�����?ѹ��p��uc}J$�E�yb�&��,��0��N���x4�,��kk��gem�?��s���Hs���������'oП���S������(ojyv�p��h�#��+w:�sF�dx6�#����Ci���Ci٨�d��>�[���آ�;;S7�7J��.����V�w��A}�6p����4�e]�`���ad�]��bQ��O~�?*�^����Oك6`�"���}iÆ�Ia*z�l�m�v[{G���O�����ɝǭ���Rs�ܹO��'��%��N�;wʝ;���)W�vI�ܹ3�psgڹ3�Oʙv�q2�@Gڠf���C��� 3U�3�c8��2���k4�q�5:��	{���)�Fy�Y(@ù��Q��i_5��
�|����G����xZ&�X���ю9�l{�ʲ.�C���^����V�w{����u����iF`e�).~���B���hl����I���+=�J��J��p)AѝX�W8B!���E�D�����:�/^D�L�[�0+��s��* �d�Is�av_?N�y��DN��H��6atv1� �Q�_���*N"���NA�ͪH�o|z�]DEi�����Λp1����0S�a��]���J|��]Tuei}'��zx�u�����X�+��?vΦ�QI���0���G�����{ɞg�zB�d�|��ߢm�h�iBM;֔j(4�dvxH��Å*��.�5���K�i��d��v7��iTǂZ1��齍�=�_��[8O�P,j��C�dg��?��R�<��pL�n����P��t�MK>s�]�ׁ�c�k�4��)�!�b��$��&��p U���.��i:Iҍ����>2c'��d7c�U�p�@�_�΍����t!scG��3#Wo������s��~�	������ u���.���O��{�R^��V��=]��?N�����'��ɮ�a�m�{)��ݓ��?U��/�����L�qtt�Q���],˿���ɓ�=�0�þe�M?@`\�/���=y���o`v<�-\��y��Ct�y�����X^�a>�[�N�����(������?����V�Ѿ̤�(�@u���Mx������|�?F����<�?BO����n����xN��E'7�׉�O�<�)�r�HV�C5Nm
!l`� ��h�m얀�A(g��\X^�	zn'�'t����OA_���	<�!�ȉ+v펀ۮ�k}ts�4=w|\����y�b����!��!B��^��wjE�P6�E�g�~�����!"뒾b(ĸ�(�9m�(�O���}d�:�zb3��7��$��D|��C��Lz%�5��Q
�s2w7vvN�^���w����S2 �:p}ҢJ�7�J�(�ɍ�'�������hs02/�b<�@�_��%�K.��0�_H���� �B`4���n�U�\w�V�at�+�$4m�TE-�s��O"S�)L��n�X�O��3����AI
N��4��ݾuez�
���[	�N��,��m�MCET��03�����ҙ'�J�X��sɏGe�)Jܬ	9��A캧ó�N)n
�tIFp!�3t��Q�-ڪl���Ƙ���m� � g�Z���&wû��V I"�E�U�H2�����
��sv)'����μ��R���R�*���Er79��m=r��Y����;�[���
����C� �ەm���9��+v'��%w&�|tnR�PؗT`їH���)���yS�s��cG����p/Ԉ��ti>,�H��ya���¡goI�c�%�/�}�TZ��0P�U
J�t��$��/P������Vr�[�C���K��p\z���ǵBS��q������	J\`b�C�/�|���6��~-чo@k�=�����w��������:t�7v�Cf����	� ��7�RP3?1$H�����Z� ����.�9�\[D#�ۇ������OȕXM:�ܺ��>p�@�-}uv�,�i����2�7ۭ��I:�>^����a��� P��0?��Dߒ�O��45��n�޾r������v��k�<v�����{�$H�](�t�j���'<)l}�:#B�$\9���ZM�X?ik�w�+6zb��ܩ\�)��q�	��2���_����B�1?�^��1�j���l좿� �`f��ۿ�nqh_��A��;��<�=?Px�śU�lЯ=�ہ��Z��+����u4�oZ�|���(NzፚQ��氀%@�#&���]T���[�2��.���܀Y�B@:�)�
<T�q����Jh�.a�ksWTR"�S�+d;E�H��r�����%�\E$q)���6��<L�)wBF����3�=X�27��u�K2�����rb]aN��^�
�·:��}{��{zr�Z�%5\�h�p�Suk0��1�O��&6�!�I�2_�X��31Q��5'- V�:��I�N1S7�|ʂCB�����$��X'��z�+�!V�b��j�`���@;.�9�+����f�e��Αꬔ�0��1V$�תRX���EK<�ྔ�1��5�e���y�|6k#�z���i��ޓ@g\S�%V�-�8��I[��N�L�n��z�ɀ.@���!�TY�)V�����\٨�������� 3�y1P|�pg�B���	4mVV!VnԵ�O~�����I,�|�1��I�Ӻ"ʊ�c��c& ҟ1b��O,�i]�2*!��^�����K���%��{�t�3����>���i�"c��h��w����޸Dv�h���`L��&��x�tNwG�><��s/%'�īd���u�N�^������,qOO�P�[�/�vxIXfQ��Lȿ�4�<&v輲
�o����'�A6���4�f�Ӂ�I�~�W#ي��K-�p�Y�;D}y1"~!Q��9K�;��)G��1���0ex���;��;@Iʔ*0�wjֶ�Wd=i�w�t 5;��QL8lĳϢ�"v�*�Gä,VŰ�נ2�U.�vJg����Ҙ�31ɨL

��Ҏxy1���F0���qI@�a��Cy2�j&���g{�D��-�Lr���e�����|�(̶ȫ.?�7�^�r��z!����I`(T�pM(�+����X)���S������N>�+��R^Ja��/����lC���}�VM�Bn�NY�c���DX|�N�s�ޢ�C����H�#�����6����WżDGD���r���"uEm��ӂ�:ʤL󙧖������j�).�Э�#>�v?�Cvз�N"�����L)�yv(#z�����b���ä���5�lmM ��×+�S\>��4�,���~U�b��S|��E%�G�+��U&m6%�-�H�&%�|�yt;�qH[(����X.I����;g�E�"Z�>$&54r�Γ�:E%X�wt�u���YY����U���h��X�%Uo)�Ե����y|��/��L�J?"�/�
���bt���`��/���0���Ԋ�uH����"'䩬}�,=g�P���Oמf䥞�(Bޯ�ip�.y�'��i�<����WJ�ԉ�t,���N]N+��K���R"��N]PϞ��1���x��D,x3�L��I?����Е0�l	'U���X_�W	�e���U�mf5�h�Y�+X��^Ոj!���E���eZ������M۾�����ϳpLn'F~@�}�꧘�4�=e����X83v��r ��p'h��\�F`[{o��1�%�<�O@��p����1���S2o�B���
��c����|���4���ǲ�g2�����I�V�e�����#<�|˞<Mó+��K(�1��}q	�-%�iM��k�xM�H�J(�����ImT|��V.Eeq����}JVqi"+�V �dl|��dmjvx�eW���
�ѷAQ��<���w��͢N�3��vw�'N�H�"7RÛ)h�44���S	Z/K���eՓ�]��?F�{J>W�љ0Y��ӊ�{f
����$�(���;t3�;���_�!DЖVܰ.G���/�m�?B�"<M�wL�T1��L�z����0��=�iV���F���+gС�_6V
��<��)_0Vȥ�EkF�sF�ҙ0���e� `
���ji)�G��G0l�Ց4bG�,��GjT��Z���壁�[,�r������p���w3MW��]�lx���a�/��W�4~<�n�H[ԑ�F��j.Z 9�B�Y�ʠ��.I�|��Й������[�Z���!+4#�����u`<��&/���W����a����{Ef�Kk��b]�1��������̠�[e�tP��4��ڴ��P��
�ӻ�rA�q��]8����-{�>�VF}D��b��^+;|4���k��1�����\�BQ^Q������,�Eb�G��IJ�O�2%�UϏĪ-�T���+�Wi�G)���ۯ�>�]���@�e藐|A/"��C Q
eZN��рd�����A�����NYe0z�(�Gr�)*Y(�K׻2����'���C���\�M�C�����h��(�Cq��;��$�btP3��.�����x&����4�~���
�ZE�KĲ\�Ń\g1�h�����?��>��<T�g�Y>��<2����(4����r��c]i�fV��}���}t8�&��Cx0Q�����Vr���+�ƄU��؃�Ph-VHn�L(�+�7&�P6R�x�Ŕ=��s�8(�x�|�L��b;��UR� l�a�1x�sY�7DKܬ*�������3�OP{ k�!{�#k�A�����=RJ��.h����p짜^�r�#��z� D?��5k&JX�# ����$��������4W�Zdϸ��1��|�iL�O�!���K�0��4����<�(*x�n�:nر��ȣY�~AѲ�*JgN�O,6��U~#�YO!�������^����`x�d��Q�}@�P�}(~�ϕ���Gy��蘯<�zj;�L�Q�dM=@-���X+*�F>����o�GAx��04�@=Hk��JH��0���u#<�#P�61X���g����c�q$�`t&𒶩1����c� ��T�yRxI���3I�g���y�1�dbS��-v2FAv��gB8g�0]�ff�a����|j4b�c:dR�$����+4�E���2^th'�$V���k��po��ƕ)�'κ����=28��ѯ�C_:B�z܏������G�O�8d^:@����(�,����m�
���
/KiR�o��[Y��+���r��V��kO�ƃb%ҟx�ߎ塝o���n��k�����u;;��L����zyc�����t������[�Zk����x��������j����է��h�I�r�q�i�I�@��p�-�����APk��׵����`���"r3w�( Z�&�h����ե�!��F��� ��~�Z��}��}����p�X����G���0�56+���L�U��b���;�{ ��v0�}W�}�8ю�q!�?�-)jqrw�:M�q�E$��<? ��ѱ�MD������a����R��5��mѳ426%5:�g����`ѽJ�^�������b�gwhoڎ�\�JMS��%���k)�0r��4+X0��ʸ/&v��J�zeE�e����"(�����t�t�GA,>
t-���u�Dy��v`!bA�I�Sh�Z0Ҽ=����l|�[��jD7�ƹ��*_^60�7f��� �,�q���7�aF�+;�3��������� +ıIQ������T��􇧖;�1+�7zk�����ץv�YA�G��P�f�w�L�皇���D��m�ԣa���`�ώ�|5�+����B��ǕXdq�V����H�JEй'����E���D����.����� ��K���:]�z��+%�c�[JVƊ��/V*���Ie�V����5�o><�[�T���c��7B���J���m�k�����W�yW�]���Oٷ�g���l,<%찄f|���74�E�_0�-(�u��[�,��o]"��Ɨ)�� �W�[�I�.��Ydoy�.݁۵&A��T��z׆�	��)���靏h<�*�T5))VB.uL?�Wm�Mh�+{.��"`JC���0f��TE�W���Ҫ����UD�,zE��PK�.�{�0
Ӕq�*�
�gF��)��n�H
���5��r�]������Od��a+(�Q���{C	�?����&�M��S��?��s����&��˗�#e���m�s���$��nR�Wa��싸m��7�s�#��*X(W<]Y#���A,x-��Ȑ-�W�t7��
Ni+lY�)<������)�h	pN�����Qa�����4�4��`��DQ�������Zu��3��+������ء@ܾ{�O�u�©(ܕ"��'�2I/�:~�����W�Ȳ�Jh��rɸ��HJ�S�dLs՛MB��}%���}�{��f3m����Ā}<=�.��8G�E\��S�����R#0��-���:��Ci�6U���X��ޓ����I��#���9qM�	G�U��>�����w�����f�Ρ,�Y�rx���ܤ��嶤|F���}Z�A��r����.rR�w�󌮚���ؼ��{n���u�^Fq H��#�� ~�>9b<������N�����N�m��X�,W}����H�.����w���kq��̖���ń�^�1\(� &����i�����7�h�2�?�<�hi�5�z���U4��x+����!3�+��p�k|@H Jj��{�e�8_��Z���W �y"�C��ߧ�b+�B\w���+��q�rl�+�s˔����.�U������?���y#�%�Bx��V����f��8g�����H���فE��\��u%cErP�E��]��z��'WK���G��̀���
��"ӝz(��3�C��� 8�����}ᙂ�Z`�u�%�u}�"�~�J��#S��3�dW��3��R��ƒ�:�V��#h�Uaa�MTb�5u��W0h���|��2�wI�	E�uL�N_] ���&W^����EǹU�<[>�ʕ�u���B�=tŧO�HJ��&A�7�t���}ⷄ��'ִ�h���2�x4�O�7��Hћ?q���Z��&��<�N؍�h���m�"�h#|�h-��P%p���)�20E8*j���kytS���L!\�j}��坉�9�)�
�^et����G�i/���6[HsqDC/�$A�3����{�_2iCG
����zq=
���`;�@�ϐ!�x����1�U��8��Ӭ��`�;7ICZoY��B+$�$NN-��r��0?I��Kgl&�L���o!���և@-��&��A&A�Tj%ږp�K�5#Z��\wG�2����p��X�zpO������¦��C���˵�H
*�CNd+ڂ��F�{(<�?I������e�&i%zz��SlYl=��[�Vu�/Tm��D�d$.��z�x���SB�gfL򩢞��z�L<#T��EW�b�랆-P�1n�Jmu�Q�n4��J�,�:����8%S}�Oժ=�`�C��_d^U���K��(SY��X�Pa��TΟ�Lh��jx�0��׵��	���%l4����gH���}��ca������#�,Tr����� ��qeW��%gy⸾NY�1��J���NI��I�8d'�� ��p tK��D���mW����Z�Ph4b����U���Sv���'��T�сJ�_T ��+�j�z��J���'R46�����&Vyh�1�}w�T�BZ���5>æ-�v��/��pod�#B�����X�AOͮ�t\�� �E �^��+6�����W��Q5*ƚQƎ���÷#�f(�Q��T�@�X�(�E�Jowx�j��E���(�T��ce~�W�����l��L��\��j�:e�1�Y��������O�Wq�w/����v"��Ǘ��As����B㱣�,������I���q�$u���8��d	=�!��=�=~
�4<���o��i���T�.����DW	;,3mŮTO �!uZ��'W�\Qmw��j�E��H�5�S˷���u,trqPp�6�^Z�k������ͷӁS�	l(���lC�I���r:��v�H��,���o��-$����@;n�PmE��z\1��9��@����p�~�&j8j���j!�x��4@�ef2�Xl�4pq{�d��ti@C��8`��('�*�{��D1�Dd4)��3��GJ��P�}���:\��`����U�p������H`�>���D�݉��ܛ7���I.��K��H��h�@����mX<r��?m�"�p�jo����BK�6��k�ҿ��
�eT�5�K��h
L3�DT~##Z��z���G��,f7�H��@S���5%P~.<��������vG�#�d�oӁV�PA�b��.�����U��¹9$]p5���QE���"~%w�K��/
ǋ/m7"~�ˊ|yu(��K�0Bml�X|)<��Rck&�3E`�0X�=��0e��}&���d�ro�������Z�>q�~�T-s�n�MԬ ��f�KE&l[S,�����-�^�pC#P�ݝR�ѢJ�򂺞m���)�@�B[���s.�R@�o��0a>�-�Ka�	.*�!��F	��+�wt��;P!Cg��{����_+�Q�2�%�����@�E*�
�\n��k} G�s̏�( \���m_zP�x��G��͢��(_�B"܎���]����)�F᯺l�C#tTcS�%3�2�X5����H�f�)m�С�k�Ţ3�-��]]]&4\�$��K;�[��v�@��n��O`}ބN:]ǔ�?��k���f��>���|���O�_r���~?U����A��W�6��?%�����?�d���6����ݓ��?U��G����s:����C�K�w��ױ,��[�><jx�7�<1���A3����G����������yJM1��c����(Wb�m�:���~�[|�r̜n�1ex���[| ��Q�ƫU�b����&�v��w����n����.@��i��yU�f�M��l�}]٨�W}3N����*k�������@M�O5�q>5F��ħv`�����lV����w׳���[];K/����F/�y4�/�Hɀx�C��Fe;�E~�ٴ(�s�K�
-�_i�E{(Y�:��(ID��G���A�d���x���h�L��Rh~/��y<��) F}2�>j��l<�u]���3��iT˕��<�1x���2���Q�`R�Tq=��]B8t�����{�M���ӛ9�2~W�R_:��W;�*�w��Y�ْ�����zd�苙�R�pZW|ˣ�}-��45٧�!4��x����J�^j^%C?�kE9���Ff�S�6%d�	��i�5��G������ �Z H5/F��� �'^M�de���}vo�e}#���D@R@��d��  6��1��/h�Z?�w��W(���mi��=����>h�(�p�c}�~IDÜ�,=���aɽ�n�\�5�9&o���m:0�Vq�D;���p�LA�@,u⡈�X
3�d&ehG_��5�J���]��9/-�d.x���ѕ�o!W���5*������%wg|n> �� V4�Q�D���L�ǳکY�L
�BqR�|X_
c��/������4��W@������8jշXF�͟(LN�ɨ/�.3V`�tܾ���Q�������=�x�+��J���Ev��+����4���<��B$$L`�ˍ(�Q�%���nW�����5� e�)���F�&A\�n}��N�:�ӐT#b��P�����m\�r׊���'xI]��-�FP.��6�X���#�]���w��@js�=�b���8L�Z���aD�ߟ�6�{�X����ʼ�n
G�B(�]AN 
��(�Y\�?㛳�S�>P����,����VY[��?]g�������H���:����ek�^휧��j�O�������_���in����_u��<�����kp�������wG�n�ʼ���gx�y�!�����	q�E=⇥�Vt[��?�_�ps�$�����asc}>�?F��0��(�+,v%�]��*>P����rMy�߮��Z�˷��x��n5,�q�Ze��g��ӵ��uH���}�짾*���l�uL����������0h�C�Q���/�������c$�W��uܥ�76���)���puL�����fy�)��R���GI�(�R�����f�:���Hz�և�c��ߨn�Q�ol�����D8������2��'eD�i���J�����7�nT��A���%-0=.yn������	�.;O<ː���u�;r�ʈ^�Hȯ}��!�H�O����!^�p�?��W��ߵE
�b��~�Y{���s��'��;6�t���б�o;�v���;BN�=���n������m���a���}������?���,��W]ߘ��c�D��N`�h���Y�1A�[[[_���П2���,W+s��1Ҭ6��N9�ΙgF�r��.k�[`���wĉq�l�p��q�ƨT��z��&�`�c�RT,~���eM�ns�Iuk�Q��N���*F����:���*���ۥ�@߲ع�!nx�X�{Ð�Ā_`?"�#�~����@�S����FԺaʃ1�W�Tפ"zB���P�y�s+X^�I����U��+�Nx�|A�A�3�� �Z"xi�+?Ͼb
�����&!�N����ݠ�:݄�v� �~_�W���Q�W��t�FVsx����!��NA��;�q�aټ���n��?l�&7��%��<"%�{���~)F�ob��X����Q��-�ŲGԍ�����D<� gT�uD�T�H�(w�2#7RrG�������oH$�7˼��!�:��X"�~�hE�W
9EeH�.�
"�����gR��j��Z@� ��>��E����fX��f���os��=N�;}?���O��{G
���y�c�Ɯ��?�c{\W�J�Q=�S�1E��`�����(.6��Q�w�?�|	l2�`l������z�Xߠ��~�������O4�]�:�:&�����ӧ�󟏒���|������S~�k>�+(�ޕe]����#b�;t�3�
�9�Y97��A?c+�_�'�uKW?W��b�^���aE�,�7��{j�{�����P͎G��Y�= ��&^Y`;�bp���������������;�s{o밵��;j|)T��G�j�(�2-��ڌ���>�<�����y��O�vm�|�f&uL��6�A����ߛ��7��>�l��Ѿ[� ~F�kG=��hg��$��)ښ������^A��T�L�(o@�a@���GQ�d�
�̩Z���t�����]��^�@i�6�pt�>����Zk����rک��ju)5"LQE�	�1�"EZ��M��d(�L;�5�tm�sυ}�4(��m��vj��".`Z
�܂��N�¼ݓZӾ����:�$�K�h�����ũK�yɔ
�;Cg����R��ev�`�Z����j�菩B�|Ff,pr��;�=d7�'���al_��8�g��#6�2�-V�E���9�+=[�K�xM�{���#��$�!޹w( �����!H�@�ν5���;Vp�z�ӹ�xk}�%˽r�}��zh�}���=�:W�r�p �]���[(�,���Z��݊��~������\��!��}���[�t��s�s�w�uJ�ܡ
�r�����QP�D�*�I���D]\s��~`�A��=��&����\��3�c����}��?�r������%�k���k��Z����ȼ#.^����˽{��kno�ϵ[[����?y}�l��'o�'���x����.R?3��lO���C$}���D���.fXǤ�o��F�ߞn����c$۹���O��s'�Ȑ����\�>7��t����Ixu��L@�?���gc��o>]���<J��T�O��M@�`��N}VCx���46xXP:�=�h���a�
�MA��g(~6� 5v������Ak��>�m�M��2��4j~0/��݋��Q>������R
�I�t}K�䦞b�z���$USτ��0^���sط(�Y��%�t��O�4���C*� k�b&uL��^[��m�7��%����h������u�jN ��]�P5'��a 	�k-�럪GW�$�v�@���p\�<���X�2��B��)޹��?�K��f���i��W�`w ��,����r� T}�!X.Lԙ���[A�ܢi��i��i��i��i��i��i��i��i��i��i��i��i���?�n� � 