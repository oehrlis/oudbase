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

if [ ! "${INSTALL_ORACLE_HOME}" == "" ]; then
    export ORACLE_PRODUCT=$(dirname $DEFAULT_ORACLE_FMW_HOME)
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
� ���Z �}]sI���������s��Ź�,	.�ɯf�]��4����������D��n\w�G��G��o�?���/�����83����? ���蚑�����������:���N�Jekc�ѿ���Jm��+���j[����F�U�Ս����Јa{��*�cN����'|�����3�g�;���c�������_[�جa�Wkkk��������Vy \b�g���(#�^?����K mq�Wg�s{�Z�F��X��*{>�,��<�2/́3���~�:���q}����)@��a^��iy�kx��jOWٗՍ{90|��_\��Ε�o�����}ch�x�3m������;�����s�ff�Xl�1���]ɡw��J]g��=�J/����7�������e�a�j������g9v,�����ݑ��s�����g��.L��o2ˆ��]��2�c��m�uz&R��MObs܇~�8�54,{p�ƞ�c��L��r�::��}v��U����}�
�!��z�|9�gH�2���"Xܜ{�y�7�U�{]��J�TyZ�U���1�(��ؖovi�HF�S���U̳%�4{߁B3��3;6sΑS����E��:C�{���=g~��v�uztpp|��o,~T���<���C���B�m�����#G�Z0F���6cӻG�r��G�����f�u�<<l���W�<�1- �g��vn�c42A� ���v#���۹<��3�l����}�sx|���k7���m�3l�R����v����G�6�e8���;�P��G-�MY/^Z\��:�ͣ��o��V����'Ot5t��G�����s8��)Иe�+��^sg��j�;���o׀Y��s���F%�r��{��{1���T�an���\��^yƅ�\`���ey��q�3̹vd�����U���.X~g����W����ؿtY�b_�������n?c��Ԉ^k~��h�r��`�g�]R%��I�N��e'�!L��R�2�x�HI)�&����{�~\s4��$�R (��d�Kd�:�ڍ��]�$؞aCk�p��{o�H�"Y�R:�-��LB|JN*��\�x�	����K�7<�u�����+^����}�󻝓����ݴ{�0�|�o�c�>��ke���K._a�������>�%�=�X\F�֐��衆:Q}���H���?|u�d����MR]�xo2�l�k�;3��m�5��@݀ڕ�df0��,l'18�U�[�'yx`�c�;{�SࣽC�Xz���������Ű�E��o�_�տ��_}�=:J/jO)L���C���Z�z�y5�
��e(%$Y��n8�4�!��Y�	5 :dV�.L�Kut��q6�A�g�|�dEC�AIm\Md�!%z}�����8�	k���/��s�*n۲��˩�Kl�dpZV�����ی˦9v۳gIm��Q?�ى��9�ꄀJ��n���#� �@0~��P��M|	ʓ���U�A�J!�sQ��LӞUqUU��D��mh&�-�@��X_0c�m���b�Kd��:0��4��x�:.�z��VQ��
	�-��^���T��VBj�h���S�z8������AU�p���m����f'B8 ��Z���>�^��5@�QkO�:�3��}���vid���c�����o�=�%��
nmj{;��m�8?���=�����m�
!:=�"��S[ËS�c�F�E؄��ph�:����<EEO��6��y�Yŵl��g�G#������M.���L�jKZ��BY�`Hh̶1#=a�)4�ai�V`G�#��h�H��H�2<�!�GQ�[6��E���ӧ��J�h$�2l�`��}c0p�a��b���v�l��}������&&�u��̡s	j��
5�A�P9q��ڳrϼ,���@�<P��9a;x17�K���} ��@ 9�I�����ʽ�I�Ef㪋��p��c����Q���+��i��Z5XW�[��ܡ� }�q��e�>��_�b/�YEP��Z�ڰ�]$
'Ő�+���s�6��S$�[`�-DG� ��#H�������Р?�Sly���`��s|�
�A�+��k�����/���X^�h͏XIsA��t��*k�.)v��q�q��rp{�u/����k�X^k�z%�k�\NH��b;I�	
��
:�"f7�uǠU�dN6S�.\���va���V/?r~8���p�.0��v'���Y�Ҫ�����u��`��Yx�*����2WQ��e!�+߬ۻV���H�R��Z����Rr|'s�����n��ww���hďa�.�\��ײ�5���N�
���>�1!Adh��EmT�ws%M����5e�[ϥD�-ꠅ�`�X0�aT����L�ξ�k��OJ3q���u�B�6��OZi��`1`j��0��ΠF�1AO�x'���I�'�$�L �%�r_.`Y$�Y/���7���ԗ `��ᛖh�'�/��?iZ_�w��#J�ؖ�9Hو�e��Y,�m��k��O���v� ��#�~���t}��Sx�i6�����j�XbC!����~�3�L���ߞ�׫Zv�#�ضX߁d6z������g-����X.��T>�R�909=7��!/�iq��p<�� ��C �|����F��>�ы��_y����_ݤ�q����"W]��b�D��OB�`��bs�c����A��}�|�
��˖bY�֣���.H��,K���F/]�U�����pA�2�O|!�å����V����N.V�-~��z���w��7�l\�gK��/w�?u��x+��3��������6L��W|A���=�*�+�����e���5|u��ֲt��>B�����6o�/8���n|�%	��{�Wm��>��w6�1]~zŻ�JT��>+~���j�&��e�3��!% �RFT����0b3���#8�u���BK,;u�"{���(����ξ:���bFoh�3Lc�+��R�0�Iiݚh��C����O�.���c1"�?)C�C=��`�V���n$�o�_�	x}A��7j��~;�M޺ިi���ӷ����<֏����'���]�>����z�����F�R!��J5��}����~&��`��T�����ܞQ�h����e	� ���Z��e�����k�������ٵίC?l ¼w���>��v��'�݀Շ�g������	���
�p፹�v���}��0���e�>���;��q�Ɇ̦�x)�c�J�ր�yr��G�Q}dY�#��Ȳ�G6��|d��||G�	^��S'��Cv
��W����s���^��_�O̯���_7�z�; �� Ԗ��݃k��� o���W�U�`.zúUo���c��uR�ꆐQ� -.K=O����[�|�Z>a������'��%�^�oD�RŖ���@�8K��D
F�0�,�>��Cp`A�-��k�j�����Nc2{t�A��Ϯ2��q�y#^QBF"���N7����%[���Rx��Sw��U���\$��y��~#�&��Q�x'	mO��t�3��w�b�j7o�+xl",5���hؐp-%}��d��jF�k�p'F��6/$ĢE�}�J+'�e��p�X�V�'��R!l���
(w���68�Y�|=��Il-J�\.�(�"c��.[Z]b�_A�}����+��D����!�'� ���Ϙ�)Y��	�\Z�ApF�AW:}7��>$N�)�S<��.�B�B	��#O�2qyz�y�>1S�<������~8�E������_	Pf)���)�*v�z�2�EGX���P i<Ze�3v�����BU�U�v'?�Z^X���bC��)��^��H:�����Z;G�]BC+����{���W��|ʂ�[/��绨� �,�0+�ܢ,����\���(QWk��s/�}[?����wK��D��W{��,�� �; ��=�o�o���� ��u���I~�$_��(/]�9��TЭl|���x�3Es?]�(;��4@�+�*����hWO�!�	p;�����`�탽�&��bA��S����b��x>5�N$��Ls39x'���Y*�1�" E��@6���-�ZX̗~��x	�K iV��D�)B��gt�����EG��'[8� �V��~.h�߈�4Ohj�ڳ2�0��M!S�}��:��N�OC �=���ہz�z�4��.A�2PIPry�~��Z��C��<��g��7������נ�ؖ�7{Q�{���3VϹ�WA��Ϳ�`ԝ���t�d��+�c��5���.:�xx&�,�&iol���9o���땊���u.�.\�"v�H�	r!E"���	a>��?�c'���L<}�ύ�����������������1R�����?��S������n���)��OK�--Ϟ���=���u�.Bױ�ɖϥ���~�>s(M���p(���?�貏�Vz��!������⍒}�����둙�]�}�X�l<<��{c��i��7�Qd�]�bQ��O~�?,�^��̃���A볯�U���AC���0��Uv����{����n�{��A��fqk3�\�#���|r3����'w&���)7sʽ�S����N��3�p�3m�L��r��w���#�_���z�!�h}X��*��1�l��2��g̼F3���ר؞��k�����|4�˩���U�����8;��+�ʌ�e���z�a���6�G�L�=����o�9}�n�n�@����r����7�ŏ�pS(P����߽:<��x��P)bZ)�.%� ��a�
�($ֻ�k3v5TG��ċ����pkfű{!vVdC��7)�f���ԝ7���	�b�����>
�+T]t_e�I����½Y��Oob�#���(ɗU�#;��y.�R��f�6�ҳ�u\�B�O3�����,���rCo;��uv�u#%C��[X�����,4*�~�fɿ��/��_�gi���4$_n�{�h[��<�w�P�N4�
M+]9x�p��㸇v�(�~��Rc�/��C7�軑�K�s��Ǳ�V��xvo�tO�牃�N�39�Z��P<ݙ8f�Og��&��/Q��c���r���)]tӒǜA�u���4�'x�����?�<���*@C�>f�K�u�Nw#w���&����;3���w�&�;c���͋R\AJ@����#������@/s��E�ܮ�?Ȅο����� uL���T�+����^�ڪU�6Y�������?J�����'��ɞ�e�{)��ݓ��?5����������y||�Q���C$˿���ɓ�=�d�F�40<�q-�p�0�-�����c���uq4q�7�a���yV�����"yч�l`��=�Ó'���������o���>
��0�v���1y�oT�!2��ײ�ߏ������G���c>���St�	��£��F�:���C���O��`u9R�DЦ��������n��r���{�M<!�@/L��z��0��)�+߽�7��|2�=9qŮ�1p�5q��n.��k�㎇+��յ�t��6]�?r��j�4��㝙�c��aQ_�*�ge�Ⱥ��
1����kN�f%ͧ#��>*�:��b3k07��$��T|��C��Lz%�5�Q�2w7wwO�_u��v�@�)� �:t<ҢJ�7�J�(�ɍ�'�������hs04/�b<�@�_W*e����0�_H���� �`4���n�U�Xv�V�at�+�$4m�TE-�sL�O"S�)L��n�X�O��3����Aq
N��<�z��ye��
���	�N��,��m�uSET��03�È��ҙ'�Jc����sɏG��)Jܬ	9��A�'�3�n9j�
�rHFp!�3p��Q�-ڪl��ڦ4�	���A��A�̵���u 4�w�uL_�D����dB'; ���]�e��RN��9��y� �+��U��=�nr��	�F�����E#�w���g;͇z��+˄)<qf	V�NZK�L��h(��f@pA �#R�����Z����r�h+��1����
a~�ݽ�k3H�T��/�}�\^��0P�UJ�t1�$��/oX�x~�;�^"�����-�������W��k7���t�d\	X����e�c`��у*���s�$ES�Fwv.Ч����j�C��k��������8�B�sD���9jo}{J�r�ҧ��4�yFo(�:gK_���K�I�/�7JJ��N�-\~Υ����&X�� �ˮjVz���[�M	�.jiƅ��G�}7�Q#��s������k�,rS����[��$H�=t>j���;8�k~0�cB�,<%������-ܷ?i����;W�D�S�?�϶�S�����?$��+�9�q�s�<��-��^t���+E�D�/�j�xÊ3�5�F���v����?7��Yp5d�+��)`	z��R̡ֆ����Qu?��9X�;�"��(i�!Q��+�$���̠Ǡo*�ܧ��հwU-;X�z�ԜutPV2Iu8�s@�dp|ʟ��A`:M�7-R4�Ɓ��?WI��,��.Iq���Gˉu99�3�?+
'�������,j%��@�ր�`6�Y��ȿ�P>�/���'GHW��V�NY!G�b�i��[XF�0�+":�\���	���tw�i^ґN`�u�V8C,�Ĳ�+t�M:���̯�N�SZ��W�Ǫ�M"è��H���Y�Jamr|-	�\80��\�#|wk�K����]�l�<F��`~��ix�ޓ@g�ޣ+��L�˓�-Q~��H&s��}�d@ oV����B��������=vf¤£5Y�A�&8P����d&4/���w(Ď��K�I��
�z��r�x�4'8�.a�>����9� ��BTgY�3>�ޜ�~l!��$(�b�����[Nu�_R�������m��S�� }�����G�ji<Z�����g�Ӄ7�2�JM0"���^	ò��"'����J�9�%'捪d���u�D�^�H����`"Q�E�P��/z� xI�Q��Lȿ�4�<&L�t�V��sNѶ��� �KNlg�F��ׁ�I�~�UCي{��K=�9�Z�D}y1$~!V��9��[c�)���	�v�0ex��컭�!;DIʔ*0lub֎�Wd=�tvcٛ�О��B��
)^좘,p�>�f�G?DU �GqY��a!�Ae�\�m��+l�m�1�3fb�Q�����bR)�`�?����"��S�ɧ�d��L��}�
�*ִ���[N'��2����V3m����Q�n'�w6,~�nC�r%�z!���jq`(T�pM(6����X�x��&�U]ǿ�;���U	/�0M��79�xA�!�M��I�&y!�h%��1���",:EǄمXoQ o�pk��X��r^������W��XG����r$�"uEm�׳���:��r�r��Ruҟp�H7O�����g�=S�'@�M!�j�ݤp�Zb|�L�8�����c�HA$��+B�\ǝqL����1����F:��&�U��9���/��w�DE[�6[*��J�%���h�m�D\^-�q�<Z�SE�+v�/�h�3m��F�h?J��bu�J��o�P�<k�Vc火�:�HU�'Uo)��e�dյ3v�(LURX�Х��n�yq_#:�J�����6T�W����:��MR~��T׾|���sJ�a`�͵͔����O���S��E���UbF����J��"6����UW��KX%t���UJDױ����S�1���Ob��EFl��i�������iZ�bƷ�mX����1e"�t�U�VX�p�x�H�Z,_�,wON"���?��O�
�C�Rۢ�Yz(Z��Z9}'i�T/wG�=K�1~2����}s�`��L�E�XQ���oTʁ������sry�m￾��m�Cr>�c-�.k ���vٸ	�#6,�����^�B������NBv|ɮ;�ٵ�s(wu�e����qw�_��d���ٕ��%_~��|_\�bK�rZS��-Z�"R���	Ed��E]�$�K@EYT"b9|��U\~���' 1��'eY���k�Ui �i,Г�$B,���'��A�b��>|����#hC6֠����Zڛ�r�R��˒�fzY� }W���/F!�^�����Ft���z���b�>Ք�"�)FȈ��ʧ����K���1���GC��8,������m��I�sE��+UL�2S����D�@'��+��{�"�Usw�3����;:�x˥�Bcy)�}�J+�F���$�"O�T�c��2�R 0���I��� ���#6��H�C�q���#5*�(,��hQ�Ѩ˭��@�}��~8�ޅa�[��6-���=Q6��h��W��� ?���X����p#�u�ߞ����}��X�
�K?�q�sE��L`��{eD��a-�JC�bm˃k�w�+�aC���W��4l:�Ϻ -Z+u	(���qg:ƣ�+0.�F �e���ٲk��lJa��C"�r�Z�3Z �gR���ʄ�mgo�y�����TY����l����[CIr���5I��,�Ŗ�<�QX��&�r>^����{�u����/��~H>��@��؜ g�y�L��`���������*�``���O+ڎ]T�P��{e�=�g�9O��(x��}O�,�HJ���W�S�V��B��wJ�q�E�f�B�!�i�w�0F 9��x= ��.)ŢS�ŃD��_�s52�4l���"mpy�Oc��������4-7�/�[*�;�m^i�TZ ���s|4˶��Cp�L����Vr���*��~J��^@�ާZ���S��G�q���B��<�3T�9K�5���J(�t����e�a4JM�ƒn�
�b�H�]�#w�ۤ��xi��t�{�M\�a�y���,'��(�i0l�2̥k�}<��D
ϻ�c��@�?`�1�"w��+�u͕���o�yh*�L2e�Sl�l�7�\���G(�g�!�h&����/����m�j%bZ�QPkL����<��
��꬐��AQ�A/�$��;|�#�2��0��3>;�Q�}�{8&ӏ�J�'(�9��t�<Oxf��T��Q�e]1�����&�ʃR����.-�w�R�T%��'e�ӄ��?	Ig�Rz><���R
>��M�4��ك����cL"����^�<1��"�Qr�d]�[�RhN!i<�r$�H�@5�<?&=�t[\"Z��F�N�r�\H�Tf����cC�;~�͌FD~̆Lb��$�w���0�T[��J��D*8]�J�?������a��#F��efl�<���
n���Н�N.%��"���nt�Q�c�ܩA�	XhBWO@�c=[�}Yz�$|���i�1^ju�V��ַ*�*����'l�A��g��k�h��[]�������z����zN�a�����?onn`�����z����������^�4�=P@������ǎ�E��������@���1��M���B�]�[nۗ��_�-�@-�n��^:K[�� w��S �6�]��ˣ5�cV��m�Zqz��vcp{]cdz%�`�狾v�]�S�:t�z8\ᏱyX����#�
G�U���[C�߳�1�ʮ�;�	�M���!�Q���Gױh�<��+")���c��.h��-�xg "�i80?�3O�C��"��,�M��]S#cK�Q�3m�6;{�쨹�J�^�����q�b��ou����9ƕ4�-�/�޻�҈R.�"�f�x#����Sb7����WVYVy�e-���<M\���v����D��C���.ҀH �ОY6,$M�0I}
M�PF����p���p�^��f�(�=%Pʋ&�s��W�����0.3wx�S��{eײ�������B[U��M�otf�аC��~���a�ߚ�w]����w�T�5m<�I�y�4��zO ,�p{`<�tW���q�������Zhi���,��Zbop� %��RE!t�L䃱>bQ=�� �������7 ���2{�k�n�3�aD�j���X�㕱b?��ʋ�j��vZ]�׾�o|Iǂ��1�>����h|l,��Z�J�Z�h�A���鉅����$D������3�������A	+(�t�!�a������lCJ��g�&V4�b�K���e
�>� �fa��tp�����Cw���i�"4U����F���GB�p/�4��U���+/�:�T7��ő=ic!0�!��S��P�VE�W��������U��,z���E�.�{�0�n�r�*܊�9�>F(���q�A(��i�HY�;�EB�뮰:�� �S�?i�

�T,g���P�O�;A4�)uS`��&�O���q׹�	����ݨ�� �0{�r;�e~0Hg��4�U++"��#�����
��+������p �j�Bd�҆+�P��\z���,��K�s�@���M�8gܧ�_��`�A�~UA��D��a��DQ��������zm��3��+������ء@܁s�O��E!Q�+D�Aֈ]e�\�U�n�ەկ��eS�$�D��IE����z9Ą�7[(��*�y��%���cMMg�n��)z�%<vr�mO1X�q�7��@�mg�5/tX�F`$�[dG�7sv��(@�m���-�%��R]D��������E���s⚺S���|�w��7|[Ly#��[9��CXN�����+��*_�me����묜�N)�|�>��]䣼��zjN�?|�#�ڳs�:>���K{E eF�˧C����q�Q�t�j��/�ZZ:����kF�\�S�� �h8�<�izӯE�.�ZFN��S
+rz9�p)�D��L�^�DF�/P���a���DK{�����F�ڠ��[��o��q�����H_�BQRS4�,����ż�x8q�j(&�>3�[	⺛n_Q�����ϱc�����)?�;�ˊ[��p{V����W�|)��#�BpY�V���ˡ�G��8g����H���[�I��\��u�bErP�E���)�S�O��
�7�#��1�)���XUE�;�P��}��Y>p�{����g�k�)�u�\������U
����X	�qe>��,q1h,y�����*?��_���D%�\S/������/������ �.i=���i����`�⩳��+�:����*�g�����^�2�n�52�]���x�HI)�$���)�r��-���L.Z0/���	)�S�f,%�͟�Ձ���p-�BVa.w������=�����E�8\�Y~�"�%j��iy`_�T&��]�>����D��_����8&�7���~�+�l!�I ����EZ� R�����R|�e(P�
O���	Z���"���^��:Y>C�7�?������E���� >�8ݹI�z�ڗ&Z!i� qrf�F��-��a��X:c3yf��0~%����7?��hQGEI�2	"&R+ֶ�dR����(�uw(��{������q���(l)k>$+N�A�\K��r;�T��-Hy��'��C��)�=�_� ]9��Ф�DϮq{�-�����ѩN���mp�HV�D��6ѥ}r�	�Ԍ�B>QԳ	Yo��g��U��*[������>F-P��N0��E@�Si��U'Yz8�l����Z��ث@)Cs�rU�J�R�^̘�F���d$'��
��r�$eBS�V��Q-��uML(�Pǐn	�Y��M<(kuǸ��/�
*MT���d���f ���G�+�:�,v ���#K�䎏�$�����T�Cz"J�1�n9x+���ʶ���VK
�F,���J�zʎ��1����"@��H8P)�
 �y��A�TϘ\�v��T�F�sX��Ԫ �9&��N�
VH*��_V�gؤ%�nk�1n�-tD�\�sw���,��U���r`����+Uv�F��w����Z+�J��Z�����+�o5���@��&Q�B�Zi����)�������z﫥/K����z��o��MRr�-�#�鞚k�QC-UB'l;�1K���R��"V�)�*�~N�IS��N�k����0h�5w�h<q��%��a��>I�R>ΐ���p�*��,��Y �x��Y���O`����:��:Mv�p������U��*!�e��ȕړ	 5$N������A�+��3[ʹx*���|fz��8��N.6
N��ϜK�t�d=�c0��v:pB�5��bwT�ib^��M��\���x�c~S?����V	t9Ԏ��T[�i����G��|U�0��?!ě�_��G!�7�Z ( .	Ph��..	\Ԟ3h$�\��b4	���$ʉ����)�E�+�G����}����R�5F�x������U�p	��u��H`�>1�D�ݱ��ܛ�7��I.�ۏ_xH��h�@�c���,X<r��?m�"ư�jo��{�K�6��+�Կ��
�T�5�K��h�#�DT~##Z��zo��G�,F7�H��@���9#P~�?��������vƾ���o��V�PA���߇�,�Wf_��px�t��D��C��)A�c����/�0�.B���T�������́��,��0T��!��%T���J��F��1�x����P����4�J�e�u���d�F��fk��ĝ�S��%���6Q�|�5/��-M�BXJs�Pcx-�!�@�|x�x@9BD���z��yc���K �
m���/p��J-�}�?�@�V���/�.C$����Td.%@ȷ/�����\@��eޛ��z����.(�yX&yji4α_�R^�P��V���r�������1����U�g-`qo|6�xd0z{��e(T ��Z]��ŋ^i��m����694BG5G0E�2�*����R�ľu� R��sF��t��Zv�(��}��vWWW%� ���,��ʻ;���N�@��n��O`}ބN:]ǌ�?k[k[��V��nnf�?#a�����|�:&���ߛ��kյ��Z������GI�7��ϟ<�3���~/�|���O��	�����d���H�����u$˟�����5KxM6�<1T��a3���������w�jg�Sğ�A�2��j[�񿶕���I��-��{r̜m�1cx�;�:[| ��Q���U�|����F�vF�w��u�n����)@��a^�yU�B�M��t�}Yݨ���������*�������@M�%���|j�}X��O�<��5ҩ�2�����J\���/��7�n�,?(��bt�;=���B��RB�����*۱,�Ϧ�םK_Wh��J�.�CIs���I� �%<��a*P'��F�㤰\��djE��B���{�O��s�4L0�y�1P�}c�Ѭ�:<V��*[�Z��	��gO�Mp #�
�aa���\�C�����^7���F��#.�u�����oN����2{	��-ɜ�^��G���5����@<9 �,1,�����9S��O̫d��m�0�s��a3��N��ҍ��5ш.,L�f5/������/gk�����9
z/�p���^, ���{��� [�1 x$�LVh��ߣo���'��^i���=�hц�>� �p�}c�~I��ķ�@�u�y��΁z�M.�n��b��w�8*���bx�5�� Lu0 ���ȝ�K��}ͫc9�|E_�x�R˅#%��j�p��s�[�d�|c�²������N���Z��F2"��,	��I�G >R\�KA�����o�@��|�&U�
ڿ��iww����6�H����	2�K���J+��]g�c�;A�d0g�w��n��㯒�y����
mc����j� O����FcIn�@����.󭥰�y�ⴉ�w��� (�:!�v0�]'	��rK�V,0�o��K�GJ��K�6Q�(���	|��$��-�b�wAf7�rv����]��j�X7/�KgRR��Xo<����G�ah����#2�f�L���j�"aW�X$o�W;-�� ^� %?���)@!��1���gars�~���H��Wݸ�g���j��R��X���?��~��_[��������,%����P����mm��?����c����y���i��Uϡ	��)Xu����wG��n��@��pxWy�!�����	q?3⇥�Vt[��?�_�ps�4�����a+���8���V�| ��(��ȥb8wᇚ�@�&a���5�e'x�.�6�4 �n��G�9��հ`,����յ/�֫�k��uH�/�~�4�̚�Üͷ�i���c}cc3���0h�C�Q���/Ս����GI���K�ole��)���pu�����0�:��R�����H������m�Z���1���a꘽�7j[k������� u�~��W���qRJ�޹�Q����V���}cs����f�y�������R���'�{�<8�,C.��3���8��R�RDB~�q��.�T��x�Eo���҆�z����/R��R�,(^��W�H>w�x����IG/�N� �����o9z�+唸ѓgv��[J�?`�u�~��Y ;��()���9�1e������V-;��()s�xl����Ǯi��"��D�5�?�c{\TK�ʣz\$^c��U��/o��Q\l4=���3~$��val��Т�М���;��A��=��T��n2��g���c�wS�����������?J���l�����w�����{�yû2���kv>ƈx<��sNW�c��)��$�S��U�|�Z�d�#v%#+��ū�]��>�r�ΌR�Ϟ=n����������g`�R�����|D���V�V�W7V7�DΝ���^{���C��0�>%k5��ʬ����>�<��Ҕ�:�R�4�o���:���E�����in]{5m�>��w�t�8r�c�X(*>�v���ST�3PP���B>E[+%�l����!H#���I���b���(*��S-U�����/�@�Q/���W]`�WPZ�ͻ�]�L���RK#U�7YN;�^�(�F��!��1�#�_��AO�w(��<�ΖA���J��o��KWم���{{���^Qvf�㽿c����K�-���[�'��}��=�uGq>������h�����ͩK�yɄ
�;Cg��� (s��{�/�����ŧU���X��qx"p�ĝ�3�=d'�'���v������a0>+Oq�%��,��pM��L�$*%Xq�ٚ=���0����c�c�x�ޢ x�S�7��v� �G6ro�����=�%���5����K�{+������l�Is��ٿ��pĕӹ7PY0��ߗqآ[�w�ݓ��S!���.���˖��ޘg�΅�ŝk����sF*8���n�`��~��@'!B�uq����U�j9?��~��z�똢���_��W�	��ֲ���޶�_�����wTd�������ro_���G;��r�������oO_���������޷<�T��!�ni�o�^dYz����(���j�uL��6�k�ask-���,�Ҵq�>�>�͝�"C'��M���g�)2�ǽ��ꦹ����6����:����\��%e�������	�L@�}qq��j ��>��'����xa���{؁f�~GSP*�9ʄ��5H��� ��qp��ouN�����ˮ�y��S��P��y���M=�����H���)%�Q�����0nQ�59kK ɖ��i(r���T9E�.ዹ�1��{m-���U����=J����hG�����u�jN ��]�@5'��f 	�k-���գ+��� ��|�
�{��u�,x�s�pO�;���°���%^�3	�ص4wz�I��������l;6^�i��CӁ�:2�|+ȟ[4e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R�������2�L� � 