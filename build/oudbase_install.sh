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
� ��*Z �}]w9���q�s���!9瞜KkV�V��d�pL��"�Ѯ��(�;��j[dK����nJ��ړ�����5��M��7��� t�AR){f3���@�P(
�B�Բˏ�*����&���+���H��^�Tk[�j���͍'����4�|�T<ǜ����M�.���3I���θw���^��/����_��|R����_��on@�Ï�G�� \b�W���SF85�~�1+�/���^�-��k]=�c͗k��سl��X˼4�hh�>�-�G#�����V� e:�yn������y&�}�ƾ�n��ˁ������|�u�,�'�vo�H�C��S�i>6�~�q�ǎo�6;0���b+���G�J���/P�:C(��Y~Pzi����a����ל�-��V3���ȼ�<˱cY���p��䐞ϰN׵F>�vn�?}�Y64���sMl���3��oz��>���a���aكk6��;s\fڗ���ԩ�9}g��׭"T��3�V���}����s�9>E�9�<q���ܻ�þ�r��:<V���7%�ɞ0�@�0�c[�eإ�"!O�V�V1ϖ����Ri�h�/����9CN���08�l*u��O���z��@���U���������X��<Ջy`��^�q��7�@��a�G���`��>{mƦw��^��:;���\�yx��o5��G��y6cz�k�L6p�ٙ?������tڍ���n���7Na�!���������~s��XZA�Aΰ�J!w�wx��9jo��ȗ��(O/_��B�K�7e�xii)��7��O�o7[�F��P<���mK��o��k���^��@c�-��s{͝�f�u��t�ӿw\d��ϵ��������I����"S݇8����3�{���J�}��֖��5�0�ڑ�.$��W-g�;g�����+^�v��b��eE�=�ѽ�<���~Ɗ-�Ԉ^k~���h�r��`�g�}R%��I�N��'�!L��R�2�x�HI)�&����M?�9X]�K) �v�I��%�o�u�F�r�.Nlϰ�5n
�D�=�7l$^�,I)�L�&!>%'��u�I<��q��%J���:co�e���}Va������fnL�nڽ[>Ϸ��vC��̵2_D�%��0zf�nrs����g,.�|kH
�p���NT_)�>R;w�_�$Y���z�Ą�@�5.L��{��>g�&���킼��P��! 3���f[����$��`r�$,_`�xg�}|�wK����W?���|�}����W�|��o��GG�E�)�iv��w����X�Vo>�fX�ߵ��$���G@�&4���<k0�D��*ՅIy��n���!N�8���o��h(�1(����`�l0��O�o����U�=a����%\{�V�m[�y9�u�-�N˪�4�ڞc�q�4�n{�,�M_�����x��ρ�T'T�XTtS6�����/@9�6�%(O�zB$WQ�+�`�E�
3mL{V�UU�����l�]bo`I|Ό�3�I7��1.�����Ӵ��븨w0轒ZEm�*$`��S{aV��S�Z	��b��ێO���tFK����U��Qs{�h7'ϛ���Sk�bT�g�X{i\� �G�=��4���x�#�3����ۥ��`��c�>~ �Q.I$Up�S��q`�o���4���7��o�.P�����^�z��6�/�&�u�C����� ��)*z"��iP�,�#�*�e�=oE8�&�@���mr��=�g`�V[b����b�CBc���	�H�!�HS�* ;Z�tGG��,G����=�h�Bܲ��/�����Y���dW�m���o�6L��*v^��se��{E�,%71��td�KP�MT�����ʉ;�@֞�{�e��䁂���	�����X0�1DX"�o�h��	L�8V�uN�.2W]t��S��E%]��\q�N[V֪����b,��ӌ��.��	���{��*�Z��
Ԇu�"Qp8)��\�-����	��"��co!:�Xg�A���X��.�=�)�b��8��/���T�j\�5��`,�����b7]��b#К�����RU+T֦]R�H����?�����^6n��}���ְ�J�ҹ��@u�v
�� t�E�n&�A��ɜl��]���������^~�:8�pB�� )<2\`�N|�!J���Uo����.j{��+��FUd�/�e����BDV�Y�w�22���!��6W�0�����Q�PMc)y�;j��l7�шê]й2�w��5���N�
���>�1!Adh��EmT�ws%M����5e�[ϥD�-項�`�X0�aT����L�ξ���'���8	�D�:C!z�~�'��4�m�	05JJ��o��	g�	#嘠�L��O��$�LW&���D�/�,������ޛ\��b�K ����MK4䆓�7b���4m��;Ĝ%flK��lD��2xN�,��m�̵L�kxc;E@ÑO�]gd��ez�)��4
����k�M,����wAlS?әj&�fq�o��U-��Cl�,��@2=�S����q����[��^*��*B�������vZ�$=|k�;����(��+�|�j�R����^��]f�ooR`�8�O�g��� LL�Z"�t�'!m��m��bs�c����A��}�r�
��˖cY�֣���.H��,K���F/]�U�����pA�2�O|!�å����V����N.V�-}��z���'�7�b\]����;��:��;��VH/�g�۝��G�m��o�����{0U�7V�s��s��(W�j����e�e�ݳ2��ZYZ�ۼ� �T�e7�-�$�N�qV \�Q���Ȃ�٬�t��]�*QI���4�L�iR��?�������z�� �KEP8\.ÈQ�^B����m<��S-���y��eK���7[{;��ԓ:���e�0���ľJ�ô&�uk�����Q�'>ѻ\�6��P� ������qoXY������~�7��}4pH^߬%2���6y�z���.�Oߚ֣�X??�ǧ���/w��,������_[��J��+����!R�������K��N�L�r{F���_����%�A����hA��]�7��n�yy#�k�]�~�@�y���}���<WO�[�?��ȅ��u������s�<c�!{��0���e�>���;��q�Ɇ̦�x)�c�J�ր�yr��G�A}dY�#��Ȳ�G6��|d��|xG�	^��S'��Cv
��W����s���^��_�/̯���_7�z�; �� Ԗ��݃k��� o���W�U�0�aݪ��M�!|�:)nuCȨX��V��'�~BӭW~�V~��煅�������%�^�oD�RŖ���@�8M��D
F�0�,�>��Cp`A�=f]��լ����d(��̃��]e����F����D��ݝn^s��K�����ᑣOݱ�War��s� Û��>���"OD!�Kh{
��{�������V�yS^�ca��-�EÆ�k)鋔v �`ŖP3�^��;1��y!!�,��VZ}W~��!�ե�jy�6M]D��Hk{�Ί,��{�$�%�.�?p�1Dt�-�-3�� ľ�O����sˎtP"���^��w� ���Ϙ�)Y��	�\Z�ApF�AW:}7��>$N�)�S<��.�B�C	��#O�2qez�y�>1S�<������~8�y������_	Pf)���)�*v�z�2�EGX���P i<Zc�3v�����BU�U�v'?�Z^X���bC��)�{/Yq$�Z�DNI��#�.����b��tʽL����[>屖[/��绨� ��0+�ܢ,����\���(Q�j��s/�}[?�E����BL"	`�Hѫ�Qats����܅��7�7K{�f�X��r�]~�]�Q^>s�᩠[��0��+�|g��~��Qv��I��W�U����Ѯ�"B��vZa�#vA�Z�{{M��łhg���!=��b��|j�H���<�fr�NB}�T�c>DE ��l
5OZƵ��/���2�� Ҭ�\#R������1����4L1O�pJ7@ޭ�0n�\
 �%�i��8��gea��B�8����cur�@��� �+zdU98���,��i'\��e� ����
��]��ˇD�yz��No�ŕ�,��A��-�o������5k�=f��se���)�e��;�����Z�W���kz)�]t��L�Y�M���$O�s�0�7*u��\B]�
E캑>%�B�D<1U�|�_�?�C'���L<}��������������������!R�����?��K������>)��S�?�)U��<{Ə�KH����Bו�]�>#[2<�����}�P����PZ)U��eԭ���Clѫ�ݙ�%��9M��#3��v���q8��xx
���4/h�^��(�f����|�(π'?�a/�y�A�s����Sd�_�/m�� )#��@Eo�����^{������ށk�(��,nm�Kud>��On�[��|rgr�͜r3�ܻ9�
�.9�N �9�fδ?+g�y���i��U�ۋp��a	@f�Dgԇp��gX��k4�1�ͼF�^�b{nF�Q�_��p.�~s|�W|��b_��l�*�<*3��I�7��E�5<�c����2�f�)>��~s������bsy�/�v[�X�o�Kq�P��ϛ�|ux�i��JO�R(ĴR�+\JPAt'��*&QH(�wQ+�f�$j����a�7Ӂ��,̊c�\�
�*�YoR�=���ǩ;o~���	�b�����>
�+T]t_e�I����½Y��Oob�#���(ɗU�#;��y.�R��f�6�ҳKu\�B�O3�����,���rCo;��uv�u#%C��[X����,4*�~�f�?��/��_�gi���4$_n�{�h[��<�w�P��i�5�V6�<$r���B��q��Q�L���4^
��n2�w#��F�$*�cA�����������-��gr(��١x�3q���z�M��_8�n7Ǿ�W�t(AS��e�9���@�1�5h�O�On����xB�U8���}�R�T�4�$�F�Y�M���wfқ��M8sƠ믘祸���t!ucG��3'Wo�^��}���]m�Ȅο���̺�:&�W*�'��]ŷU�]��?�U2��I�����ў�e�')��ݣ��?5���<��3�����E%����,�J��w����%c4������ �k�Ǉ�_�_���74�.΀&.�<L�:ϊ�����H^�a>�;v�����-����������V�Ѿ̤�(��:&��u����������<�?O����n����xN���'7�׉f�@q
�?҃��H�A�B���>.<���f��s���xB����	B�a&��S�W�{=o��dB{r�];c�k�Z�\.�B�W��k�%�<h�m�����!h^?��;5C�(�â�5q��U����uI_1b��?ל��J(�OF��}T�u��f�` n��H0���Ɨ�t��JRk ���d�n��l�����ݧT�,����H�R(E�T*M(��B$7�Ķ�ï/���м��9�qy\��A#,;��Ô~!AR`B�'T
��p�C@��TQc-�-[�ѱ+�,�д�R�`�1?�L�Rd�l0D��b�?&Ϩ�
��)8�N�������*�{o$�;�Ʋ���MQޏ�̬#��Jg��+��o�6��%?�V�`(q�&���������i|"X( dX�!��<H��1G!�h����k���'������B�̵���u 4�w�uL_�D����dB'; ���]�e��RN��?��y� �+��U��=�nr��	�F��YAV�<���݆
�3��9�&�+˄�;qa	�T�&Z7�Bz�h(r���c@�ᯔ�zH|�r+�P�3���H�@�v7����,�,¤:����;���/�e�\^���P�U1L��
��o���
�����8\��n��`��:���"_���B�;�8o�X߿f�"7�����7�|g�A粠�.����L��e�C<xu��n�~��I;6_�7.w��_XJ����j8%���Kq|�����.�����G5��y�=:��Y��+���ՐW(���-_��+:���x����|�n� p���F�2
�s�w�,B��[�Ӎ�5�	�Gm��
JRX�m�;�"��$�oH3Pࡦ�<	�#��_�ӂ���#���"����O"�ԘttP�Q2I5(�s@�dp\�O��� 0��܋)ha�gg��$en���8zFۣ�ĺ����^�sh�w��~��tE��O]�Gi�p���<�u��ȿ�P>�'��x�O�t�\.5�Д�QD(Ɯei�Y�!]Ј�� ��'�OН$���ɞN�t�����Be�21�d���@;.�9�+��V�E����m��0��)8�jU)�M��%�@��p_��v��n�si�v{^�+�͛ǈ��߬N����=	t.�J���J��&��IҖ(��D$��[�>j2�������Y�)V#�{�ԄI�G鱠��Mp&�D5��	�Lh^���P�]�@�feb�賀�O_j����/��{�?F7e(�SO��P�$�s`���CzsF�����hZIu�^V������n���X��!��uG��F�fy<Z���e�g���7gVA=�ԋ@��y|!��9:��p.�zj���d�N��$�atu��_�E�@���G#�߂�Ⅽ�N@�����\��By����z��2����粲ң+)h���T�)�v���:|Ј��J=�n�y�Q�04��e���D��NgW��$'�Ĭ&Y�|�x��"2�Q�0?���{$U:�Gq���$!�@K>��{���`xd�I�
C�v��F扒YA�i�D�NJy]�K=*�����R��#P(V�I���[�SL��:�������<�0I_��@�K�&l�U%��FAww@5���[��\���X���X�x������{��|��}!�Y�=^3����9�Mt���N^i,Y�Z�?��X��i�o�� O�%ʹXP(o�p����́rX�t᪁���«�؉/��_�Ҕ�"�tVPi6d�`5l���5 �A)S�ZL$�L\Kw�w�P@i�I|g��u�Y����`��e�%~�9�l�w+W��?�}���8�;[T�*{1!����͖ˤ�rBq<��c�4)���^*��é8�y���y-�MW>��󘈌�'*����F�Ic����m,�8Uy�%o1����v�.-��~,�7-��㾅ߜ��\�a$M��P9S�������M4��߫�_�ι ��0ߓ�'	���>ʟ���ox��d4v$�-綖Rz&��JYL)%��m�ɧ.[bk%otݒ�hQrG.�U�|���Pn����_�g��]�(���9��1�j�O��5P��rl�����/��v�C�>4\����0�qb;W����`�6�����A����J/��Ũ���]������w�klh��G}��aQ̆.E�%y ��Ц�8w0�<���V\�b�+�C)�R=������J��i�=�ٕ	�����b2`\���E_MY���?�%NRj~��$wI���s�a�� �����*m��(���?����HG�ۮD^�~	���C�I<�`��D�	��ߜi��`���5��S��^�3�}��g;vQ�B9^8���D�M�<�v���V���@p�e����	&�(J�T'\�jf���'B���,��m��D�A���
��*�kUF��B���/���M��3n��H.o�
���ж?��;yhNQ6ȅ�$eU.��U�P\��mդ�R�����d�S�@�48��b�p�f�p��4�b���$%&�x5*�n�ӧO��M�^��Ir�s�ږ������B=ZS Q\" ��|�d������I���4�_�R�(V��&S��]Vc��JJȸ	~s�m}���A��&R8 ����Bп�{
��#hՅ驮������7�<F�$�Ex�$���;�b#��q�K�+�I�!dh��q�����1�7�Z9Ϟ@&d��,�r���� ��ޅ�I=�t�I8��py���v�����aߨ	���%�pȃږ���w�b�p��K���I�!�Sc�*)�O-��j�Z�gY��[b��d�z��";�K'1I�c�W�^C����OB�Y���l5\J��@��D`MC*�=p�E}�q$=|&𒎎�)�%�@�5H�X#��)$��S�:�������sz�XgB֥b=�S�K҇hW�<������B��:���^O�IE `��ZI����U����|ߴx`���<z���ṍ'n� �h�#?�D�&b�N,n^�(r�e-��Q=��(�2�ψ퇅�1-��K��?����J���Gmc��\(V"���?tM-7��[ܾ��7����s����f��jm���Z���nnV�����Ԇ5y�4�-��Ǔ����?��Z5����Z��!�c҉(({W���d�GmR�[iۗ�����@}�n��I��Z�� ���{$tR3T��imΈa��-3F�"wSc���#�+�� 㾜�5�fN��4h2�`󰒃-8����`�f����7̡����k슾c��D�z�q��Z<��=
Ǩ�<���K����.h��-F�6�!������P����6tޙ	Z�kjdlI2jt�=�fgo��z{�2�C��!�W�:�$�Ș Ü�"MH������{�TQ��V%Ӭbq� #���:v��j�duU�e��Y�"h��3��tlwiOU�;K�$\W{�;�"��}�Բa�cB�I�Sh��Z0Ґ5�]k|��}�jL7D���)f^41�f�r-�7m,�qY(���m���ʮe�?��{����7`�8�(�"������t�a�f��Fo-�f0=���]����~j�x�I���Y��'V���<E�+cx�yė�h��x\'-�}\�D��n-�78@�I_��:5� ��X���_��_��
@�m}�p����[\�u{��#�T�^�j����9TT�V�����F��u}�k���%N(�M\)Uť�i�f�vfbaq�l"x��{���=U��>{�&�cP�
Jh��gm|C;[��9��U	����Ċ�`�p�m�n�-L��6HI7UO���
M�U�7��Nq$t�er%�lBUӒb �R����Д�8��"a,�4dE:e���iU�xxR1�
���\EĤ�W�h<���Sn)��P��P�9�1B��e��f���"md1�	��e�^�4������@J�rL�%`�ԺD�R7�xIl2�4�Ή�k�����@0{�r;�e~0Hg�Hz<��<�
�q>G9����劧��b��nĂ�B�Q��B�p�J��K�┶�V����m
|.�Ȝ�!��� �;��@�����ʒ� Jl��%��Ht6X.ڋ��k�w��o_�'g^����+|
��tpG�d�w��Pv�ec��nWVe'˦*I��J�IE����nBs��v�2^]2/�X�/�q?��t�M���Ό�P�$%����ꃅ��(p���d�^�B�LjFD�Ev�}3g�z��ܦ�Iݒ\b
+����[�|}`��M�l�a�O8"د��NR���午�+�:r��;���f�a�?�+��'_�I��~`봜�N)�|�>���T�w��J=5'�>�W��윻��q}{i��( ��Ȃ�a�tN R�1�7�|����Sm7�E\KA��6`u�H�����xÄ��k�x��M���]AN��S
+rz%�p)��9	�L��S%#�(�����pd��L�%�[;Ax�j�F�"<�1��7�y	��������h�X��%8����f�|����/����OM��V�E�w����q�Pl96c,6��2c@�9�dS.14l�r��Y9�_5�%6����d��x�u��:��;��>��n�ݾ�dI��_�vV�!5Y�_9�_L�ˑ�}r�Th��q��H����*2�TF	�����и0��O8����r]g�u���H���wyq[���τ�o���ɋA@c�c]w���k�( �~UX�Fn�rM���vZ�_
�L~-c�~���P��@��{ү<u} ̣�=��������Nskry�&</<�+��X# #���P�w���2�M�PoN�R.��G���O�erтy�dL�`��o0c)Ao�ĭd|�k�_��
s�+a/�_�e��[���6�F�
��Z�J8�pigɫV�QY������tL�`���U�S�8��w&Z7� ��`�z�����o���~�%�l!�I ���EZ�డ����*nd҆�2ozCW{C�?A=�.��$�Jl���2@�.Iǡ��Qg0�~
�\=H�<Vs��,�`a�s��؝�`�s�.��P����GuKY�`�t��
G8��@�S��v�d 9|Oc�G��ATb{��4��Ф-�N�q����]����W�A��jH���_n�#�I�n�x����SL.�fL�W�R�M�z�L<#T�����R��-P�1jLIlu�}�b������ȫN2Zp0v�P�S�j�,�W�~��e%�J�R�^�.�F���d$'��s�mr*�yQ�B������úR!t,�cH��iB"�	�Y�1�`�x�A��:���B�"���sB@*3;~����ʒ�7q�@���Y$w||z�6@�!��n@;$␞�p���[���t�Ʊ�Cc3��R�B��4<�Q���b��3&�Z�B�R[*E~Q�3�?����+ծE�J��p�v�Z���ݩR�
Iev���|�MZ-�v^3�~���=�HDл���fAOͮ�t\a� � �^���+�޸�φW�Z�V���K�.�^�|�,���5�j
�J����i�.�=��Η�]TK_�*'Ս�H�?����NH�@�hVhj�uJ�T	����,EBkk!m�������$�&M]bg�"{��a�:�k��'�x�hC�;��a��>I�R>ΐ���p�$�1*��Y �x��Y���O`����:z|A�&;I8@E�R�p�*�qt� >2S������E^�`z�x�x�iי�fZ����P�%���m�������S��$];Y���Go����ֱ� *"ҠU�zpi���=�=�qKW����䑖�jGr���贃4Z��c8t�4v`Fԏ'Ó�I����	!L�Z H*�(42L�ӧ�5ML���)@��$`��('�*�{��D>����\.����}����R�5F�x���	���>�5�p	���u��H`�.�?��Dݱ�-��/�7�A�I�&�ۏ�p'L�e ޱ��ix��\��*�/l�?�F������ ��3��d�x)UbM�.&�|�H"U��Ⱥ�C(�j�3lL�]�R!��M\���@���f
0�m6�»��c��4��m6�**H_L@�"�/0p��87��Z��Ã�.&'?N��#XOD��l�1�ëE��B�o�Փ���m��b;�7Y%v8)?�\��ϑf�-�կ�Hϊ�����3t1)��s/s�`�x��.d]F;2T�p���t߯�[��`TRnm�A�I���_�R^�P��V�����;���J���e���Ž����Q]��-ʗ�P��kuq�
�/ Y�fm����6�gA?4G �L�y�IO�Z�Rb?�H�S�3`�]KmEa�Ϟ"z����U� �%�=/�����v{��.�g�����n�/�`��n����Y��=D���,����*[��'����������f�"���/�}���.���^�z	�����y��\"/���/����)m�iI*ns]��oiI�>~�{�B���ܕ;��wq�\۾�����Q�5��;�20H��X~7���~��U�����xϖe�n��_!{~9m(�c���h@�ib$+%C7�!�[��O̫d�C[_��9�o�����T���4��;J�u��9�V�ԼRp��rB���E�Q��s�VX�$��b�) �"[E
 a��x,.�����	�c� ϯ�>��6��̅cNX�p{�:�$�p�Sc�~Iȷ� ��%r1�7��k�����ˋ/Y3�;2�f����b8&���e��6���}ͫ�9�|�=�x�f-�x.x��±�o!W��
��1{��f
F���;97na~�	Ɉ=p�I�L
=	�p�Řd����vc���a"�DgʃL��2~��*�f�8n��N�!�i��� �����$h�@d�1��J���"��	�/�A�|�h,K�۬L�2������'˙R�5G��زB(��`��6	��r˗Vⅺ2ϸ�L&+�ڋƲf+�a�߆�O�$�jG.}dns (aP�Z�,ߵ����u���@!3�@��x���E>Cý�h�<M�m�3��E�)�X��W;-��#^� %?�f�	@�'�1K+�gars�ok����Sx~iquL��T�k[��o[����A���������*�ģE�~����#�r]y�	�n���u"�vS��^�{|+E���E��}0u�쥎7���:�L�̚��9η�i�?n����|����Hxhu�u�e��������W^tw������!Rxbwqu�����&0���d��AR$J�B���_ߪֲ����kXL���fmk��s3��b�8P����F5��&�D�k���jec��?W�7�l<�������"=fz\��c�R\#��{L^�^g�7�0n7�}��K�K	���T����zgPe�
7aжs�z��U��/���+C��܎V� ��;��rw��p2�{�~=�d>7�fi�)9~�|����Y�>����H����Xǔ�:>��[�l���9�>������wW
��hF�x��]�����R����aLQ��L1x��"���"�)f�H�#^%��ؠ��Eᐝz��ؤ��	~V*��L�����p��c������7�<�����H��������sʏ�d�¼�]���������ߊ5�s�t�Y95��A�V�*�O��KV?b!�Y�g/^����%�����wj��}��Yp{�̎'�j�~[�-�|==XvץC���#be����������N����>j����_
U����(Y�%Wg�_p������ϕ���K���Mx���-��s���2�o�in]{5m�>�+����Y�g,�Q;��Q�)*�((��* �����t�5]]Ø�M��$��V	h1��y�L橖*�E���W��(��Vg������.��k��a���󨥑�*ڛ,��C�K��`�*zL T�)��'5h�q���U�ja+�Wv�
%��7X`��5v�:0��ޞ%w7¸Χ���1��,��{����(�e��wo�sXw���eE3ſ�HmN]��K&T��:�EH��k��=�͹D��ZKO�V��K�*n��6qg �n�I�	<G) ���50=q���7����H�XI�&L�s��8�l�m����D�+f�9�{��}N�"�x���@�Ƚ1l�kئ��x����M?�ċc�/Y��s��#��o$���}C\d�`�W���@qd�(�^|U�a�n?�wOF/-#�'BT�?�]�ۗ-۽1Ow�s��W�p`���N	�3R�u�%�c4���h_:	򞨋k��p<�"V#�����ۤ�[��X�������N������x�����rg��>wD�=��"�T� ���{����>��~�봷_��p���<nwN^�4O�~�g�;���g��x��"��"R�]os�c������_G���'[����dٗ����	�yl�$~r89��kZ���>K�M�ot�S�?�[��g���m=Y��$e����x�ifZ�	(��7����3��?Il�XP2�-�4CM�������T�s�	�k��c�� ��qp��ouN������y��S�\���y��>�M=��+���$USϔ��(Z��ē�(ꚜ�%�d����44���1��{}=���U٬e��C��_+�v�_K?[策�"X�uTsR�l���ւ>�Z=�r= a�� ���ȇk���^�΂�9���x Nq����\��/0�p�]�As����9��x�HM�����3�|h:0Q�B�o�s��,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R����,e)KY�R�����?bj�� � 