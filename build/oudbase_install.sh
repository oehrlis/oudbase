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
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"                  # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"                    # Full qualified script name

START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
OUD_CORE_CONFIG="oudenv_core.conf"
CONFIG_FILES="oudtab oudenv.conf oud._DEFAULT_.conf ${OUD_CORE_CONFIG}"

# a few core default values.
DEFAULT_ORACLE_BASE="/u00/app/oracle"
SYSTEM_JAVA_PATH=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_OUD_DATA="/u01"
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_PRODUCT_BASE_NAME="product"
DEFAULT_ORACLE_HOME_NAME="oud12.2.1.3.0"
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.3.0"
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
    DoMsg "INFO :   -A <OUD_ADMIN_BASE>         Base directory for OUD admin (default \$OUD_DATA/admin)"
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
while getopts hvab:o:d:i:m:A:B:E:f:j: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
      A) INSTALL_OUD_ADMIN_BASE="${OPTARG}";;
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

DoMsg "INFO : Define default values"
# define default values for a couple of directories and set the real 
# directories based on the cli or default values

# define ORACLE_BASE basically this should not be used since -b is a mandatory parameter
export ORACLE_BASE=${INSTALL_ORACLE_BASE:-"${DEFAULT_ORACLE_BASE}"}

# define OUD_BASE
DEFAULT_OUD_BASE="${ORACLE_BASE}"
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

# define OUD_DATA
DEFAULT_OUD_DATA=$(if [ -d "${DEFAULT_OUD_DATA}" ]; then echo ${DEFAULT_OUD_DATA}; else echo "${ORACLE_BASE}"; fi)
export OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}

# define OUD_INSTANCE_BASE
DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/${DEFAULT_OUD_INSTANCE_BASE_NAME}"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

# define OUD_BACKUP_BASE
DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/${DEFAULT_OUD_BACKUP_BASE_NAME}"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

# define ORACLE_HOME
DEFAULT_ORACLE_HOME=$(find ${ORACLE_BASE} ! -readable -prune -o -name oud-setup -print |sed 's/\/oud\/oud-setup$//'|head -n 1)
DEFAULT_ORACLE_HOME=${DEFAULT_ORACLE_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_HOME_NAME}"}
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

# define ORACLE_FMW_HOME
DEFAULT_ORACLE_FMW_HOME=$(find ${ORACLE_BASE} ! -readable -prune -o -name oudsm-wlst.jar -print|sed -r 's/(\/[^\/]+){3}\/oudsm-wlst.jar//g'|head -n 1)
DEFAULT_ORACLE_FMW_HOME=${DEFAULT_ORACLE_FMW_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_FMW_HOME_NAME}"}
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

# define JAVA_HOME
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA_PATH} ! -readable -prune -o -type f -name java -print |head -1) 2>/dev/null| sed "s:/bin/java::")
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

# define OUD_BACKUP_BASE
DEFAULT_OUD_ADMIN_BASE="${OUD_DATA}/${DEFAULT_OUD_ADMIN_BASE_NAME}"
export OUD_ADMIN_BASE=${INSTALL_OUD_ADMIN_BASE:-"${DEFAULT_OUD_ADMIN_BASE}"}

# define ORACLE_PRODUCT
if [ "${INSTALL_ORACLE_HOME}" == "" ]; then
    ORACLE_PRODUCT=$(dirname ${ORACLE_HOME})
else
    ORACLE_PRODUCT
fi

# set the core etc directory
export ETC_CORE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/etc" 

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/log"
    export ETC_BASE="${ETC_CORE}"
else
    export LOG_BASE="${OUD_DATA}/log"
    export ETC_BASE="${OUD_DATA}/etc"
fi

# Print some information on the defined variables
DoMsg "INFO : Using the following variable for installation"
DoMsg "INFO : ORACLE_BASE          = $ORACLE_BASE"
DoMsg "INFO : OUD_BASE             = $OUD_BASE"
DoMsg "INFO : LOG_BASE             = $LOG_BASE"
DoMsg "INFO : ETC_CORE             = $ETC_CORE"
DoMsg "INFO : ETC_BASE             = $ETC_BASE"
DoMsg "INFO : OUD_DATA             = $OUD_DATA"
DoMsg "INFO : OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "INFO : OUD_ADMIN_BASE       = $OUD_ADMIN_BASE"
DoMsg "INFO : OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "INFO : ORACLE_PRODUCT       = $ORACLE_PRODUCT"
DoMsg "INFO : ORACLE_HOME          = $ORACLE_HOME"
DoMsg "INFO : ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "INFO : JAVA_HOME            = $JAVA_HOME"
DoMsg "INFO : SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "INFO : Installing OUD Environment"
DoMsg "INFO : Create required directories in ORACLE_BASE=${ORACLE_BASE}"

for i in    ${LOG_BASE} \
            ${ETC_BASE} \
            ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME} \
            ${OUD_ADMIN_BASE} \
            ${OUD_BACKUP_BASE} \
            ${OUD_INSTANCE_BASE} \
            ${ORACLE_PRODUCT}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

# backup config files if the exits. Just check if ${OUD_BASE}/local/etc
# does exist
if [ -d ${ETC_BASE} ]; then
    DoMsg "INFO : Backup existing config files"
    SAVE_CONFIG="TRUE"
    for i in ${CONFIG_FILES}; do
        if [ -f ${ETC_BASE}/$i ]; then
            DoMsg "INFO : Backup $i to $i.save"
            cp ${ETC_BASE}/$i ${ETC_BASE}/$i.save
        fi
    done
fi

DoMsg "INFO : Extracting file into ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}

# restore customized config files
if [ "${SAVE_CONFIG}" = "TRUE" ]; then
    DoMsg "INFO : Restore cusomized config files"
    for i in ${CONFIG_FILES}; do
        if [ -f ${ETC_BASE}/$i.save ]; then
            if ! cmp ${ETC_BASE}/$i.save ${ETC_BASE}/$i >/dev/null 2>&1 ; then
                DoMsg "INFO : Restore $i.save to $i"
                cp ${ETC_BASE}/$i ${ETC_BASE}/$i.new
                cp ${ETC_BASE}/$i.save ${ETC_BASE}/$i
                rm ${ETC_BASE}/$i.save
            else
                rm ${ETC_BASE}/$i.save
            fi
        fi
    done
fi

# Store install customization
DoMsg "INFO : Store customization in core config file ${ETC_CORE}/${OUD_CORE_CONFIG}"
for i in    OUD_ADMIN_BASE \
            OUD_BACKUP_BASE \
            OUD_INSTANCE_BASE \
            OUD_DATA \
            OUD_BASE \
            ORACLE_BASE \
            ORACLE_HOME \
            ORACLE_FMW_HOME \
            JAVA_HOME; do
    variable="INSTALL_${i}"
    if [ ! "${!variable}" == "" ]; then
        if [ $(grep -c "^$i" ${ETC_CORE}/${OUD_CORE_CONFIG}) -gt 0 ]; then
            DoMsg "INFO : update customization for $i (${!variable})"
            sed -i "s|^$i.*|$i=${!variable}|" ${ETC_CORE}/${OUD_CORE_CONFIG}
        else
            DoMsg "INFO : save customization for $i (${!variable})"
            echo "$i=${!variable}" >> ${ETC_CORE}/${OUD_CORE_CONFIG}
        fi
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
    echo "# Check OUD_BASE and load if necessary"                       >>"${PROFILE}"
    echo "if [ \"\${OUD_BASE}\" = \"\" ]; then"                         >>"${PROFILE}"
    echo "  if [ -f \"\${HOME}/.OUD_BASE\" ]; then"                     >>"${PROFILE}"
    echo "    . \"\${HOME}/.OUD_BASE\""                                 >>"${PROFILE}"
    echo "  else"                                                       >>"${PROFILE}"
    echo "    echo \"ERROR: Could not load \${HOME}/.OUD_BASE\""        >>"${PROFILE}"
    echo "  fi"                                                         >>"${PROFILE}"
    echo "fi"                                                           >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# define an oudenv alias"                                     >>"${PROFILE}"
    echo "alias oud='. \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'"  >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# source oud environment"                                     >>"${PROFILE}"
    echo ". \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"  >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg "# Check OUD_BASE and load if necessary"
    DoMsg "if [ \"\${OUD_BASE}\" = \"\" ]; then"
    DoMsg "  if [ -f \"\${HOME}/.OUD_BASE\" ]; then"
    DoMsg "    . \"\${HOME}/.OUD_BASE\""
    DoMsg "  else'"
    DoMsg "    echo \"ERROR: Could not load \${HOME}/.OUD_BASE\""
    DoMsg "  fi"
    DoMsg "fi"
    DoMsg ""
    DoMsg "# define an oudenv alias"
    DoMsg "alias oud='. \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'"
    DoMsg ""
    DoMsg "# source oud environment"
    DoMsg ". ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"
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
‹ í›ŸZ í½ÛrI¶*ûœ}O>~ğ‰p8|r öÔ&€*\IvS3©9Ã›	ª{Ïni¸U²Z@¦ª@Š-qÂğã9¯~søüàOñ8üî€×ÊKUf] )uwe·$TUæÊÛÊ•+W®ËÀqkO8išÖiµı·ÍşÕêMö/ODoÔ›­İjéM¢éz«]BZİ0LÓ 4|hJàÙ3óA¶ápÆwŞèßŸIÀü{SëºNƒjpñ uÌÿzKƒ9§óP×u˜@…Ö¢=@[RéW>ÿOSCÁEé)©,/´•=k›¬,ì©ï\–îëòb8®d×¾´GŞdl»!ù-éO'ÏÉÚ‹İş:”éö¹íÛNúFØ¤¾µA6õV¼a8ğ§çç¤å„?ÙşÈp­¥7úĞÛU–¶‰²ààcw^x>ÿØí¡á’#ûÂ9dÍ³ƒuĞwU¾û}È jzc(İ³œ0*½²oáËÃ=·­×løw0®[Î€X–ûÒ	ÏMeX¶ã©?ñ›Az8Cú¦ïLBzäÜ†.lâ¸Ğ5×´	ë!1âÛáÔ%¦gÙ8^h¢5§0ƒ¿Æ†ã®É4°-2ô|b»—ï¹tRar.¼iHN¿Û­@Õğ‰¶{Ó
µ!°‹0œÛµÚ9äœptjlÄ$q€âöÒ§†‡|Xåù×Ûğ¨éUm«Z×ô6!(
!{®:Æˆ\Ú>#äÑëU]Ç<‘§kıTÇÑ†_˜Ùs‰7DLV`qVÈK¨Ô;?!4ì>ĞKöºØŞìíî¬|”¶+e@›ğ—^ÕóÏË7´=×Â>Ş¿%
nÖÈt’ïŒÑÔîÑ¡Òw½“şŞÑáÌfi÷¨{|Ü;Üİ)Ÿ¼é•É‚é)à®1Ùdä“¡?ŒÉÄÂ°_õ{;åWİışàn`	’1®¦şË“½ãÓ³ÃîAoge1Ü:CV´õÒéÁñÙîŞIïåéÑÉŸvÊµp<)Ó—¯öö¡ö•J†›šZ¼º²R.õO»'§gßöº»½“2}BòdÀTÃ´­|”j¿!kß1‡÷|ønÖéš%+ÏÊ¥ƒîŞ~ww÷¤×ïï NÿŞóXUó¢Ô;99:ÙÑJ2FÜ&¸WS×D¤º20pË]}CŞ.ò&0Îíµuò1I[w`22®Y†%×èa!Ejúj×;ÎIyïğÕÙfo$'ù‡ÊÅ¥O*ùW÷Ş!àÄáËŞsRÙ%ß aíÂïÙïcXíWo½äNŞeUBHå"Ùiåd-ÄÍa›;<å¿Ì*±RrŠûYÅÍÛ|O·ßŒ“Ò¥ R¿ã$Ğ÷Ñw›˜îÎ®ãÛ&näÀp¡7~¸Ì¡{oÈ„¿¢´$§tjZ0ÁØ„Ø–œUnß;§ä	6øûG¯‘:Ü°|Îü /õR9‰FŞ}û»[İ|9²·ëZÿvê„,ßÊÇúıl`¯ù/»¼Fèû¡Sº)-}¯Ë\Z±
1eXÆ“‡ZêtÔ×ÖKi?÷ßœÂ&©µıì&	i^×xoàlıkXî9ØğÅÆÖzCNAİ Û•db×,î'Ep ¾6·hNÊğ@Êë„œîôÎ ac±€-!å¿ûêO•¯Æ•¯¬³¯¾İşê`û«~yıë¯¥¢''ùEİ9…éî¥ïPïÑ±V¥ŞrYÎğŒ}W2T3’(d†¯€2İĞƒoÊd‡p6 ¹DVÁ.ÌÊKë0/<Ì·	Ğ Q™|
m›Ti=F%•u5L”–”ø\8Ã0zººÀuO[ÕşÚKÛjyJ·íYÜ¬ÄË¹½ËìálpJV©§éŞZk§iÓ§íùó¬>}a£ŸİÈÅï!èsD"å™"’$İ4™N€õÂøÁ	€9š·ñe0O|ô8IÖ‘GÙµõhÏEê
;mŠ{–É•.eŠ
Ù{ĞMò¸
ºJ¾‡#ñ91ÆŞÔ¥œ¸áŸOñˆTI×”nkHŞMÏG¾ƒÀìUå*ê‹V! “5ÜÚ×…ßš_æJ(Û (œ¾ë…tRÜÎèò´ûâ†@UğpÒ}¹ß‹¸›³İ~bà` çÖJ‹Ñz;¤€•—Æ¥áŒ{Tú£ëó ¿ô¦#‹B½©yÁN|Ø/eØofäy»òñÛ#@ZU4R×˜Ûß¾»}Î‡Ğ1Û’Ë7ç–ïù>Œ6Ç¢\„Z|noXq:»şÔu‘á2!ÓWW¿8+XôL¨yPœ  œUšË–1zÜJ`4o¨j,p]›‘Äo¡?#›÷Úá„oà Ì—H´$dk-8°ĞN¤1ÄeèŠR´äqGGÎú¬%Š×à©ùZÑ‰¸ãÂÏ1;dIíßÚZOœTş€B²+Ãu ÿ~aŒF²L7—ì¼qß»Ş•ËºÃïU0³”Ü¤ˆ¿Ú¦{ì][m#CÍÖ|T4fNü±²ş¼fÙ—5w:EYÂˆRPŞÔ«$†jMmÂæçù†	/^LÏeè(İAg…•|VÅ)ÉªFÎ+Mav¾©!A¦ãWâb»£WË‘¬0!—Ş_	ĞnF#¤0±°¢ğÀç_—K%²1–Je§&1[’§0¢š•+Íj*Çİºw‡!¥¨íPqÔ|ºæ7—|ú_~C*Vâ³Ü@¥V]ƒÚ°®}\æ’€½T%+kC¤‚ñ–X¡òÀH½¤¤}xŠ ù9“‹JœÇDA#üÄ@’1ª‚%8X.±ı3fR¬dœÙï`şù2òÛßâ4]‘²$»PºŸŞ–¢QÇE—+”ÎÌ&e8)›ÉaÿRP–;0œ{ÉŞ%ì}cBÊJÇšZÏø¥§Z0ê’L(PhÈFA¹„8Ğ&æ¸=—Šù£K2Æâz;·Coh«–Ÿø.?Ühù.=Â> Cˆò0vâ¥ÉÅ¥³½»ıãvoÛG.4:1ŞÈ6à%“jÒfp¹àÓ¥oÎ:9¸–Ñôè†æµ²‡îb>&ßËÉñ£È!‹ìròúëä¤w¼¿÷²{Š—©VõÖU¬Ì†ò;ÑÙ:Yy&o`ôŒQµH3R4.1‰¥Í'¹d™(Ub{¹iŒj\‹€Q‰2YQAs*A“h%Ãªş­^ÂLLş¿ò;¨ë‚2;ÄÆÍßsÒÃÑôc”?ëd¦Œ]‹¤† óĞN	
“½!Ï 1ñÎ>c¥œRè9Áò·fı‰6‰+†ëó$±¯¡,û¹])gJ¡oJØ+ŠÉ/ÀÊÇãïwyGnØ0ı†o‘éü³v¡f#=9|L0WSW°B@e\iÁK<g¥Â®“+Cß±Ÿ®áëU€ '!ı}ì{Û;À–Â+6FqGv¡ùìµÜ'’ÙQÈúÀ™v©Ÿ«H•ÄğR6cÇXãoçM]ÉÎ±ÄàÊâ; Í†`Ó1ØM=^GâM{Å!«AíÏ+µJmUÆD(õ£ÛÓÃ|yÉŞ.–§£Ğ™àİ&ª^D jG”7…ÓKh‘Á_©}<ü:¨½uk¤öõMl è0ø3ÿ™çÚ– f¦T-	Œ:fÛ²ÜØ…ÊS~íÓ·ıK8o!êõå9Y;vZc’ÕT~)j[Jİë‚„HsÜ¶RwZ§R1-Épñ	60ã£â?*(cGÄ²<âíïvé_ıh+UG†–p+~’é~ÿÇ³#¼µX3®Ş“Õ½×{‡Oú;å·nå-œİ^ÑŸå¯÷^ô^Âö°£ÍZ;-¼ÒÉ_IíÏ]ËòajHYWêøêí7«XËêÛç5ò:µ¶Ò`¯{¬ğ~ÃÑ¾&7xañ‘Jè;uÆÉ:m«²î"†^]Y0;-=ÅÍÏŸ¢ô4ét”C¯nÄÒ–Ÿ'»uvÊ'³o‹ÙYÚìP6 ÿ’VT‹†.F—aÅH§ã cFpõ«Ò§Åw*„–YvîNE%y+ÇGÀÂwwöåÍ'w3¬±ã.°‘¥w¯Ì¹ÊİÃ”.åMk¦@ı³Ú¬«Ÿ]FC»§|)$ ’–®‡íò×qoHMÑXº¸Ş!¿ù+àú!Š¨F¸®·ê™È~;¯Ï¾ToÕÔÅş©—æÑ‰t'ÈÊçÖE-Òã'¡ÿÍTø>‹şw£©ÕQÿ~uZuMcúßz¡ÿı©ĞÿşLúßÑ‚û¥ès%`Xq='3BÁ/]õ{³
ÿ?ê·ŞHtÜĞ÷¬)0˜pBÄ¨(˜Ø¦3¼õğa–­%±\õñ_¶2øR5Áo­ş¨:Ü¿"îGÔ×ÎĞGT¸‡
wJU¸ÿœTÆäi†áÕâ*Û÷Ñ×^\Y;İæ} lˆlòTS:Õ½¨ôáŒ—{d/t¤UGš:Ò…4)t¤éBGš“ÈÇW„¡•yîÆWhHÏ_è*ßRWyIz¼ŸC«´ĞŸü…éOBÖŞáw;sµ%ó-Y} j+T(ïµKV¢€·×”d§_<˜*äxÛÙîQuÈÇĞ…ìç¨/!£$ZY|Èû	E·AííFí-©¯?˜åRô$ñªtœì%æ6ƒTs"5’d)‘Ì>RÂA¦\$Q0!„‘vŞéKNÁ´¨$š±§Äôm<ÍªÊil‚dÚ¼H­a»«ğ=rÚ}±“®(##³ı½>ª0½®K²úç§«±ÉÙ'sBËuØ¶×Ó{†ï»'‡¨£rBØx:(tğŞfô=Î+à= eèa1lén÷´{S{†f3q©©ËµrãÄg)¡ñ•gCa¥P½òob êĞ–9…Xq(a@Ãê³·µ·kğ÷ú[lEõÙJí­^[]»&¢¢O«¢+wlœ%ZZæx=ìYhÍKPeÃRºı1K¬!z@÷ÉêÆ*ÿÖ9Ùçæ;®}EÉ¹ã&&(x¬İG_ßP¸o]Xí7Û1C[ ²°ÔŠÖ\
Z™™zxâ¡Â¢z‡Åñ‹GÖ–Rá=ÁVD¡w1]‰‘É›tL\› ŸkÉ'b‹åVf¯>ÑgPBxşyÕÃË‘ P-Ë* ìjDm™ê%+T1¥z×Õc(I®°ŒÖ«ZZ¤édƒŞÔ7m™g«Æ(*Ñ«LîN|V¹¼¸Áï¥–í)ñû^’ÊD¨ı=UıÚİ;QåJ³ò{ŒºL——ÙßEßÊ)(O•Ü
yá/Ï‚ĞG&qg—YEäæóãàôO</dÔÔÚFŠºQG${õ‡¶#Ã}¿ıîİêzŠ"q`ñJQ«½‘a®«â ×şÂ‡™½ØA8åY bñ2«µ·å·åZ
Dmõ<ÎQƒ§uUÊÆ–0íŒ§&w³9÷³•b2nÎ¢¦İ0†^?½½Õ“¨CŒsÜŞnÜë„\£ÖË£ƒƒ.òúü@´wxSc+#s¥rá!íµüÀ§…ôR¤Ïj&jÀÉcù°)PbYğÆæŒæÙ®qÍ%æ«÷ÕtÎK iÑñ…\¤Ä¦>£B¥‚L«2¹Ò0¥ôãe(”-Ù´2Ë´ôs%‚@(é‹¨D÷8Ç!w¯·(âpñ»²¹Qv¬ÙXNÕÉ´0Õ¡ø4 H% R•£“í^ÄåÚ—qâ#HšòAâ#¹¶Fü¾®Ò‡Lñyş´/>.ÁÔÄ“İÙ×ÀÀ¸Npa[Iñ{<ñŠ´ı;–å]¹À~Šî_9°êp¢´}´¬¶­j9–Hºé+yè¢¢H€–v…^’r3d6ç¬c!¾¯45M>ş§&—6«
%äº‰9¥CPŠG$¡ï*‹–sàÿ•k½
ıODâéäóøÿm´‘ş§Şè şg½Yøÿ}”Tè~&ıÏhÁıRô?Y‡~½úŸí*ü?Gÿs«ªu”<ÆxKHÇ:ÀQä¼®¸E0=wHeÉğ\ı&òìHß
¥yĞ~
¥ZUÿÙz~TµÒÓ?cŞìï/Ü!Ö)1g/i:½Ø¥?özÇ;ÍÛÀáÀ§ã,èŞ÷¶ı.Ö÷¶=)­™ êàN¹R¿h's­!¯FÆy¡AûsÖ É7ˆª¿|]Ú¨£Q’VÁ…ŠÚ*{‡/Oz½ÃÓî~¡“{¬ı¢tr¿Å…N.­£ĞÉ-trÜÊ—¤“»Jn¡”[(åŞM)—óvi¥ÜB™v¸B™¶P¦ıY)Ó.Ûé¨Hn;ÛãíŞC¨Ñ†p bªLeÔÇP²]¦ûĞBk4±Ğ-´FÆZ£üznA­QïA
Qp.¶~$slÛ—|*Ãâ^àîlŒP*.=J;’Iø‘VëE„5”cNGiáŒ\Ùö{âRQ|é°÷ıÙ÷½Ş$™Ë›òzéh7ş g€8ãMeå#Ş Ü¬¯Óâ/º/ÿøæø¬ßÌc•A¥Pˆ(¥ÈWx” QP«˜U8nBFauŠvS}ÆI¢UaüE\ñÍ|`x5»âÔ?ç7«²ÜB
YíR¡=Lî«Ç©*o~±šÈàRÉ8ß¬Nİ;Åø³.ª®2Ç$ª”™ÂÚ…i³JT+n7>}ŸZñ¸ğŠ²tY9<*Ç7o\ÅT£<Ã,Ğ‡Efvå£Ú©PêÓ‚ê¢²ª(Éš;~\GÏ/=wèœÇÓ¸@‹ù ™‰’q»aZHåø's¸ÈÕd=\³ÿÄy/_‘çy½Ó5Œ@\€·è[²è2:‡1mh×Ş*Ìí(t­f˜ÌñtôŒNY¥Ç©…rñÈ]«æÀ’=ÇF/9ÅC5™ä»‰cåsÖ(sc>Z	ãÅµó5_d.ê[(/¤PÌk¹³Bñ|eâ”Ì?õ2»¼€¾p‚İîNCC%™” [:Ÿ¦Õ€x#õu`öòt›ÏĞÏ!n‰ÍşxFy($h†Ì},R—`ë$­FîIÅÏ^™	ˆóofò»qèÉ]zSàõ×ìójšAÊhôzîÅˆ¥´$UoŞ¼BÕûés«Ú~‘	•«g‘˜õAê˜­ÿ­iM­úßÍNGouu¢év³]è?Jú›ùÏüÓ'O“õÉßÒ„ïü-ü©ÃŸÿàùŸü_‹ì°_´Äÿ‚?ÿ"‘åÿàïÿù“'ÿ
øğª1™ŒìêÈBT Æ³üÓã>‡ñâ_OüÌ76Lw@x#á•gyŞ¿ayÿu"/ê0FökÙ<ù+ÿÏ?`îÿÿ?üÿ7ş«?
¢}™I‰Üô@uÌ^ÿí†Şi$×³Ù(Öÿc¤ÂşãóØDšø?gÛ&œ¢–¸h'`‹°R±åF2œlaòV ZÚ
Ä‚ÓåDöA/…6 OğC<4NKÈÄ 4§å™ïm?ÓBÛáBhs¸˜İOÁ\…şõ’˜+ÄÇHğá;¨^s7…x„Ö·i8kª[Étë“˜vU‚º^H®í(v•,¹‹\Îğí½àæõëŠõEY:¿èö¿=ë½9yÙûA{‡Îäé–ÉÊx~Æ7âkL@…s35Q[cÍr|š³œ]Ø_“É•E*Çğ¨Õ ğFÓoÙÃ­‚}õo©ƒ§¸<œ«gÀŒô”¼Â™#gèàı6£Ø(~)”œ-fóâ"‘ bÌ”v{¯ºoö1øÏ.óC@o/ùR‰[YÉÃóR&v®Vs)W¡<Ÿte-eíœíÁW©×ò¨©Ïö^v÷å\Ô›Bn ’70Ù)Ş³\vhææB‰™¨ó<7×iïàx¿{Úëó¼KZ”Å%Ovß¼<•{1¡&d¡•İ&£BÏ2_éõj½ªWU-•ñÕÁ÷323©ñIŠ÷^ï”}<£×<HË¥$@lÜŒ‘_FÎ˜‰›üÏbnnd¤”ê!œÒâo±¬ÕfHOÛIMêf¡ì]“JrX;1XZE^^Ú±YWkÎÀ”E8X¤&ˆj8¸¡à3F-§(,]6*ÏÊFÁÎ¨K 1d~ıEş¨SËæ›˜Â¦Ï¡¡Æ
#X™</aKB«:7»z%½£w zH‹ã‚ÇS«!0n¸;±Bõû&OGùF?v“Áè A“ ÅôŒÃŒ_0È‘Ş‡:´	:ˆµ*QÀE°:n’v& +D3[x>ğ4ÉUÁ«„–WßÍŸA¦ÕÉkûÕ_³æ#¦jñ*Å§ÔK§È¥Òª”»«RÆ¸Bñæ¾•*4Wªøİïº¢Êè÷-+ûÑ¸4ØĞ"åˆï“©F‰(T¹÷òôèäOgL…ª-ñF$¾AeÊÚœl8Ø!?^
¹lá0¼&Ï±'§§B@¼÷ì†~‡Ú§Aí&Uw#CTûƒmNi3jœTF)·‹÷Vü'½¹úÂµ’™ê¿GHèÇå”pe¥MYúÿos Xû|;œú.Ñ“ñ»£…§^~´ˆZ}ÌŒÛÎZÄïl8R«ÌhôHÏBÛcÄˆoG×b‹Ãã«M»§ß¢ºŞĞñƒPÂ-Ã£^9°5ù6BwB§š£Ö©Œì„.¯D«»ßõvÏ8à1şs#é€Ea1ã\é»G‹ƒP3ÇH ³'xµ˜|°º©^ÃX †*3ÍDºAÄ8"ïÏˆ&Ò&RÎê P&_»Ì÷ChzŞšCŠÆ1»1Y;ë-Û2DÜ¡ÎÈEcî]Ş<e%S…1¹!)Öã†d°ø2ÒŠ%’"¤m&é 97±§_®ÍÄwu®ÛBĞS]p˜âk˜w¢Z­ÆmG	Ì™&˜‡Ê”Ê¯¢ß¡1ˆš¨xûu|i çt`\¡M5'ÔãÚ"3Fk”T½7U{G›šßzÃÕ^ßsMXù  (µ”!ÁI2#Q™÷dôí˜0Õl¹H‡’Ò´€“<Gd*'ˆ[öxra*9Y›yN¶nÔ¥—È5Î
ñ·W†¿§~;¯•*êÆGbÎ6Âe'áuŒå”òqšÏ`5„È4zœUQô¸5óè“JõFJŸÚîµ
C*:ĞÙ –ª|_Î¢yÒ}tïóTî“@î«ƒ/a r‡8šDãcÇx†üî¤0EP5I…+aäcx¢H¤E¯T%¡6Õ¢ç=‰òR00û2ì?xwkœËÃ·ÛãÚ]ñlÙ8FñëÁŒ&dŞÑBu&aœ‘HR¬<ü{JÁ$±<‹ÚÒ‘ßïb#³±[Á¿dÀkàmÀÊ¡˜a-ÓêxNébu1B ÇØT˜ë/ÉÃ›È°.	=«û™Ñ½(và½3@NvÔÓ³ šµ+Ëu:>`Sù¥z`ŠÜ	 ~! @8ÈÇäM/u'gqß3²æ5b¬™8ä`ÉÃ9‚i9}ƒxåÈÇ¨òîŞÉÿXöŞ+. zvF‚&,s3OñBabxUcşsÚXäÚ÷»xûïÄm!#šzgárYmÜí÷z‹´’·Ğ‚ÉyÌæ¡ÈôÍãøa<Z^e®"¾„.W8Å¹Â=n°•²otE$•Î{QqÏ7Ì‘}F¼Ù@X&@Qª;UéígíÎ÷ÃyyŸ	2j°Vm§t×3|‹Í][‰Gy=U’ÍQÊ±ÎÒÒDª0–JçÔ×gTƒçgUŞ,¸&“,½¿Û=&ÇH‰Ôt¬dÁiÖ¾š—g=ë÷÷SÙ»Ôä"3;•E¤
œHv¼˜(pÒ;¾Åº~”.´„“nşKØœ¼‘MˆÜÔ¦Ù®Õ$„mZ%]ƒqªß5åu³ö3³Æİ
óKY[K÷ı£lÓIzÛ”wL¾µrE™µ|ˆ“N=³_Ä5O‡˜­N‚Ã,~”Wy99æJëH%ı.õ˜•ÊêÙ#×XÓS!-ğ.\Édép”'^³ù¢
ƒ„
‹>] I¯èRˆæºîî€ê* Äà»k¬Ë;¥róuWí|·»LP283Zy\ÏÂ„H‘J(?1ªWµ7µG"&IÃ, É®@2Ï™øÉêW•V@¾ªèuü»M6ñï OŠéqI$ß÷özå•µ=Ç=\“dBä¸áÿ"’D¿)"£W™Ù´Å›´tò×åCR3iF?’$I;çdq ˆÖfM¸bá”îˆš`8!Â£šĞ‰Ø¡›Ò=˜•µ\KóUÙÒ|¾¨sŒé6¶ç9¥Ñı£ÜÇÙ&=]ˆnâ´í«ÓÉê×Ì¬Œ=£‰¼:ë÷eP–0*nP	FÆÄúâúM…–Öï«Qğùæ;u¡îÖŒˆ§‚u¢¬vù ”bb¢ó‚‰ÇîM¥SA|2y€µÛ5İ§§¹]İ*şŒ£¿|°ËŞè¡Pîú7‹‚SÀH6¸Òá*×ÜVÑ4ŠuÕÂD7RÏ†ËeòL+`ö„VÉñÈFQ¶ıOCN8º¦¢R©P®ÑkÛ×‡o‡Ü†”Ê–Š¨®L&S×Bmxòœœ}F–ğnG•åËD.\Æùÿ<–¬Ğğ½°.µŞW”ÌMËŠ’r"‘”Ó^VT\²Z£§w*R FEÌ-«çºt»¯mÔş¼R›¬ŠDLºTÌáy/zl—†Íãœ:ŞC(g	QsªN^	Ö÷-õÔ°ÌÚøéE©±ÿÀUôS”E/ËÕ[R$	»§H×ŞÔgk­šI‘
š„+”şˆíMPi)H¨P¯T»K\È$é›Œ¤Ò±tMHÒéMÊÏsB½±¹•‡!DthÁ¼íF;'/Éâ'äİÜRàŞòŞ&•³hyRÈš#aM”J
íR"®D^Yj—)œ”ò'”9ÒI©DRB™O>Ì(>Æî6 ø¥v8ö™®GTeùü[X¼óë„Än”©µ“fsÅ<üàà\™I<]§îgõ´pW$JZR®%
ÖÌ·o¯˜„w;ÂÓm	·#ÜÚ^Q‡¥,÷mQnÔ°¬dOğ¦=P\nI-~ş<¯Íi¯-ÑP€|a2DÈÊÍ+Í",Md'oK6Ft"¡…v'hå’XÅ`{‡ßİÏ†3Lâ›şéÑÚ1 2+›²À õ}Î¿7q!âBêûD¡HwPJ;’Râı³SMÊŒìø>‘]iJÙ•÷K(ë–«ÍŠŞ'ò}Üd7ÄûDvÙrNÎ.½Ï.!V’%ÄûÊ*[M—Sº²£İ’5I$F)!½OQ¥ÕqõıŒªåÎfÍNê\”U.£kH“”u‡Ë¢3²ò€Ş©¬ì}V ·Y°ñ}Vv Ù™Ùá½’]¦""6Zwä ~':·âÜ‹£p½¦ÖñÍ¿7ŒÄİhâ(DŞRá	Q
3`n1x;%iÌ+åVĞê"º;.¸)ÿ˜L(lï€$ÂC%ö¶qHÅ/Ôâ¾R<¾¯LŠúã²ÜIVMµÅGê#€ù’Å\2¦(HéZ'4é³,_XTÇûÍ?Bdâ©$ âSŸÎô2ò)~Ûc÷µTÇz#åç0+•D²"SÄ6G¯Hó>#äİ;’àøºû{İÈÁ;ÍO!¡\2X«>[ßY[-ÃŸÊëÕgT’ÄgYtJ­Ãra¬=E+ŸÖ”u ³¾R{[¯­f@ùÈÁ±Æñ©ßÁ¤UÑ5~VÎR¯|¤JŞƒa*Gào”ë}¼Ûb’Ô™X \=è±CÜØ¥¯¿ş _ˆáû€èöˆúŠ}ˆ‹.fD½÷
èå¯Y<£¯ëûŞ<`ç} ¨Ù”+O„pØ¼Œİ? Ó¤3Éüª?Àx ‹èMOZ$½®K·èÅB.”+]PD?JTRc!Œ$YÚÎÙ~ô™øIx­4'ÑÜÅ”(´¤&½ôÆcÏ=b¶³¢vù)=]¸ŞÍwb°¿î”ËÒ{‰`şÕ¯§+1tŞÇ¬¾¿{—Ğ÷p=26BóbƒŒmÃEÊj„Ğ!×rèß¤@Qû86<€“ãÜÃÈ[HLFèŠ¬ù6e,–H^<’÷©õ’YÃSº‰Amo±–]Ùğ¿Ë\So°A”ª1ß¹{®şa£û‰¬°!¥İOıÅpW«3ÔâL5,%‘aÆOq½RŸè|ÔÊéúŸ2¡"Pjı†³í{0Èk0/Ñğ…ñğ‰vğFÔ"‚^âà”ªÁ0ÒÀ€ µp€ ‡LœİJD“²ÁË /nt+ƒŸ]Ï­HYhWeøŸ³Ù˜'Ú‡MBÇ|Oã’Oè&zPö‚¯>?®4?TÍ•½“ªM\bäÌòôP"ú	FèV‹š7£t=% Ûºº‘òBàÅƒÇZ^l 9˜“¸vYĞÎpEØP³é/S;@—ôŠ%ƒı˜ê€Û!
[·¥Ø˜Ñˆk_)w^Ì™£7ÌçùYÿôdu.¥B±k]—²iú(Wr#ié)u·9²ÕÚæj$
‰[³9ÅºxüFhN¡ÖU¹9E—®—ÀDLEs1Æ‰„Qî¶Òæ$ÌTyË»Ö¸‹ŠÌ¬ŠSÊzùç$Ş¹+şI33ˆ›³#Õ0=YaIf9Ú3ÊM€üßD¥f˜ƒ.©™Q©G¬•5Á–WTÕƒlm”òz.°¼‹¾üKÅ¼ë¾ä{“¤]Pr²1{Nk™øşT±ØN‹Ì"ÂŸaò›ƒYN‰Ò¾¤‰`Èü=º!ŒZ‘‡Ì9\6f¥®ªb ™¦3‰¤.`˜jë¶¤Úº­¨¶nÇ@ü$£š‚ï~ÙCÕsSD&ìŞ·/Ø‹ibe8è•`p_öÈ¾·í8·aKT-9³Ï‹Ü¶ÍÎ#ÔÏŒb.N¢ø*~•g!T#Ñ„3òkÀ»rkæ'2Ê]Â*ür–Òg_	K$ÎŸI—†—xîƒõ|ÒëF¡¥Q·ªÂÍÆ#>ˆE¼‰é³ğ’ÆHF5"ƒCø,*È‹"ù}É•ô³µ@¡ëÀİÊ¢kÍ;DÏ©‚Âì}á1Mû0©&ğBH×b†qKğ•iT¢ùÍTê_È6’½¿ôSàÎcèÉ-ë¾ĞcCËlëÌ;Ì"FœäÎ#óyç}ãEìÙ‚@UOaxxGGb¥ÛœÀRÉæúgŠ|Çnç*´w[íÓ¶ì	Ônwr[zƒ—×Ø´Êgİ¡C$ç³²#+ê3Œ+û6u/è¡—N(ûLº¤• ÍôE+ç£‘Û’ô>vŸÖ$`ÍkT2{ä=…š €52§Ãaì"ŒºËM8 Ûı:òA»ãÍõÎ5gHÓù$? ÙşxxSsË3‡“3Ú“ƒÙ,õªS¸³ÌŸrgÈYüÜ6,6±¹ÙÅÄÆ-øF^VÏnFÓ1»1™…d{bÁ^ÉPŸ£#ÄSEÉYìVòŒq6¹²ªá‡0›(}¿ËbÁŞ\ÊûŒ*î¿ÈŒ½åT]ÂŞP	´&±kÌ§M¦ÿŠÔıTàX|0E„sc#R`±Šˆìg)\@és‡¾)$Ë3k]Ç¼øo/)Šÿ5şm>!­‡n¦_yü'œ8÷íôªcëêÀ _ÍfŞü7:9şÿ†ÖÑŠø_‘Réª‚”¢¸ZTdD/îq«åá–zîåÿ÷ÿ™²k°_X†o9?	ƒ%g<¡‘[¨V\¤A=”ÇûÜÂ©+ª
Ro[±0»i‚1¸Ó˜ØA•tG÷éüBq> T¡µÆµù®£ğGØ=¬ähOÑ‹6¸‚%:úE÷¶¡3†öN8¥ïWôûµ7…C"zÀ#Á•hGÛ¢áX•-–®á‘”¢`éT§’öz£¶#ŞØª1²?PğªA#:ÅtØŸ‡6lÃ¾­ã®Feœ©NJ·°Aà¸³A3½Â„QØcÏ,úÕ…cRm"I]Û7F”ÿE±2œ#(#e°Ùµ¥NTK¥giaqhó'ÎLpš=‹bœ={Æ‡eƒ¹f’Ô)7™d‘§(ÁÔ5©Vgùa°.d×İAèOM:Â—œÜô/½>U;Í¨#9cgdøˆÆW¨Ì¯Ğ"@‹p"ß–¯ºU²G3_ùNÚ.ÀyLQ—‰à1#›•}Ç~ ßü÷÷¡UØÆ]U4-wb“íCÇÌÊæ¾u—üÁ‚ëZ?ô©¼ õôˆB=2ûS—N{Íü³³æHh ³ôô)Ş2M'‰éŠ<Ô£SÇÓî	ã¡Qê°¸nÜz=:òŒ_$œ	Ãv˜Ö*ùŒDÖWZQ)ÎÂğÁZŸÀ`ÑzØ|ACÿñÿ‘ dBûß¸í¿ÖÈÈ|šV`¿#µ©¦×‚X«V-]©\”0PYE×+zãLon×7·[›ÔSÍÉ)FÕÃª7$E×¾ã„D«êë¬™yĞx˜fîë	j)1bgKŞ1g~çöFVC~¨\\¾ƒ¿äÉ âù;2NTB‘é?Ghãèğ½Aè‰Nò¸şüİÌŠæ´¢«Ğ§í3Y1ÒßLœÛëóÀ]æƒ³]Š»@ˆ,İ±gÙó %ÆT†&¡DúdUr€[%:†>¥ë‰…*œQÕ¼$ÉfÕõÆ&êeøsúâ‰™Kt„˜Ô‘5aIE©X¯Î«ÂbU Sá¬*h Áì*âÁ\çãwÊÙØ÷ÃØ!mN$Cd,˜ì	İÕ_áîÁÛQu›Ç6Œ©p0o ºl âÉx8^¨Q%„e»QÇ«F?¬—çÕ˜±.çÔÈ"ÖYu²Oó+uˆ"Ş‘«Í©4¶TÉ¨6ú8w•gQ§9½å›}6ÒÕÆelœõ¹u?ÄHß‚î{çtŸÜ&µp<Iíq#ï7ÉRiOŞšíeÍhÀPúø®#n„lEz|N">~‘égÊUÏqÂD[i×œ›“²ÅcÃxd(me—~†;÷3²&Ø1æIš·çÒi]Ç7´İt,Î€é!ÓÀô¼,ktç‰+|#“¿F©J²¸	Û=ß††h5à>jì5g/XKƒÁøÇLãw‘$Æ©W……“½YÑê½}¦kÛ­æ¶Öº?¢Wµª&8’¥Ô~ş%·ğ® ¹§˜Yâ­	±ftä]áS$¯¥.!%”	)Ë^”ì$Ç`6±CÊév ²Œ\oıg–Í²óMW_£6@(K,¯!óÊFÛxºìÜr)Kb^gìÓt„x?U[M÷Èæ/¢ØJiFƒÁ §.wüyÓE@©ÖÑ¹ jJ ÓE +6ÎKœeÍM>ÓWûÑz¯W7«Ú™Ş®Ï„ûMc^>	’ïkÔ½lXR¼¾™Åxd§H`!…›"±C1Ïê6kœƒ£ZİÙ¥æ-Å¬Rijp‡Šç¯¦ìr¬£ì‚‹€¹ı]dõ½ md×l#‹\wÍ®ä^e€¹`¿ªq9%â‚Ñõ5+-o"y¡Ë %ŞÎØC£!“ f¦X>À7×è_ñ….Iñ†]IÊoHo˜0¯Äİ®•LÛG‹.pµŞ"””«„^…Ò¿’1š¥—Égù"\¼¦á´ØÏÄ •FÎ V‚UY+EÑ©åŸèµK~¦-ŠM 0UK~SE¶ñğº€“ yç¾cf«Ù™2^Æö‹4[\ç@‚¥[£¾Ä_‚3êpú•uL;ñ]X?˜$¾  Y…Ãƒ™ü,VkX:p˜gâ@6'¤şÏfbâ‰Í˜t˜?ŒËl[‹¯È¾(È":Svz^óm%R_.“”F°YÕá¢JÔÆÏwŒ!ZCR¶~W”)YK4õnĞ$f÷v ¹S:`ì§Æˆ•ÉSŸt
~G±¬DèX–ç6»ï4ƒµ7Q·´(³‹Æ˜Í‹/›Ğô¹EdÙ(¤(	mˆˆ†ìr¢Äœ@À«r•H]˜]^¡¦eUËFñëtw¨³·ß¨ïÜƒÃŒh¦ØZCµy±Ğ¢o3á÷6	ğnğ
]{Qûçü"Ì‘q¦!õwQc5ó\Ì¤xä¹£kÜAhOˆ1íè‰(¨ŞvĞæÄ÷Rê¨‘ªøÉ×gUòÌ«—|¨²lTˆaãïî]È³H¼Ê	SÎ®òLPÜw™”È‚Ñ˜¹rÿ‚!™—”yáÅ³F£/ÆQ”+Ô?Bçõ9«d^q†:OŸ¢QId„cİõÍ'´éb©ôâ:’k<WZ(ìÂÛğ+ÏÏÄÊhD!¨˜äŠÆ¢Õi0¥¢4ü¶‡É¸d)Z=Ù(ƒPa“­#Û¸f$Še`•r	·-$Ü#ç}æMê}_ª*ÂÚ*º´aò@øŒ7ˆ™bqhÆj@LŠN6˜Ó¼—aaÙí°h!æUÉQ-Z±‚½rFìrhÄ¥sIE’È/’¸‘²ÇÁw™ç‘AZ8›=:Js‘ m	îWÁpV®lh˜™BhqÁ>°‡¼¢Í)¿{f’bE]BŞ
SÓS-•>Q$‘>‘]›‘îTédÌPš#Ÿ’o0cL¾eˆôş…^Ãò+|ñ›9¶YGYñMŞq»æ–NÀÓÂ‘‚	aC¥ÇqZ	K;"Z•UÚ!~ìJô<«¶”/&Ñ o+s;Éb“‰÷<bS7­øzƒ_É°ßèkŒj…0§±Ú	=şğ±†*,eÆ¨²­!9ÃøE0s0Nğ^lT¢ËıúÆ×YÖu>a¨Ğ9@J9®Ğõ€¡ê› F÷ÎÜlUÉ¾Ç»äÓİ€ü+‘w5ôê|i¡Jî_¨LÄ¬A‘£de$peÎÕê^VÕî)—ŒÍœCæIlI`ÌˆÜ¦{L›Ôhµg½Ko¦é.J	ëÀFå+—Û|2§pküú »É2Ó­‘¯*ıÇÖÀ{š?´?„bĞ’
1h9ÃÄ1s´R}K©³gÍZ5–3³\wo Í`$ô±"*‚TƒuÓíägàŒf~b›Â®$oÄaEæ ª—ñ«ñ~QÍùhEÕÒDĞd|OI+‹tKip•x,b2Lå˜f‡.M¨¨ÎÑ+8Êru¤W#ûƒƒ{«Ìî¬S¨ŠÒİœdÿ¬IBM½íÅÇhé:;¥¶µÜŒÙÛ]æ¦Gfd½]&–ª–/‘7ÈŠiyƒ¨Ò>&¯Ü2{qƒŒ+‰.±YÕYwRŒ[3äÇûT-_WÉ›ˆ=E¶gR¦KˆjÔ¼ÔUQŞÈè³9³yÈº	r*8	ÊV)Lì†"Z’ù]Ü²T”³èPÇØ›º!ãg(ß sŠª€ã‰E¥™,1çsbæ4b÷’ª'´‚Şƒ+¦:Yz’§7RGVyLlÎÙŸæÎbêÏoe¢±»{~¢m¨Æ(m Í­EoSeú\SRur‰ÚëÌ;PV:îRØŞü^K²B±1Äˆ+D·yA±NEt{JıÙç$î+¨ÆíådAmÅ'Å:Lt8%u¼æÊ³”×^Z©¸d†J¿e ğÌ*År¥jÆìJ1ZU~ÊZ,¹UAª7—Õ¿;UÊQ7«Ì>]*UÉ<ïïî½¢ÈŠhS•i]•¸{ó¤‘Eš'g—· ¨P‚pX¥’ÊSæE0N#¿o\v¾ˆïÛ¢İ9]‡õjƒ5!óŠ8³ßY·ÆÍf¢Ìà;#ªB…*¢{Ší®3 uä%C§,İ²œE9ú+[mB}`Î¼2™A&.ÌÚj¹®2Y\Ø@[Àıc¥ÇxæjÃ#VªçwkA~ú$Ø`ñ¸@<a†oRUP@O£@„ñÎC	~
Ô”v
¢£úVPÇd/«PQŞ¦¢|Êj®Jdâò¡|]Édå™Û8«|4¿r ä+¾ï-V3=´|P"N`úx®ŠÚ.N<}¼K›²Ï¬ËáóoÇ³K“hõÂã-‹¡™ Ğ(Ä* ê“İ&”]Cã=æ©Ÿv_0@Â”7c\Cey*'PÙXqnÌJ¥…yı.ıyıJM,êTÜ	.y£M‹ %şgŠejóÁ%ÂdKJâæMÈÉúfã³˜5r<¯|œ)…¯+îŒWŠrRNÀ}ü•b9ì¡ßX™œå"Üû†‚¸ÄˆÎÀúÙ}¤`å9å¸hG¦İ©é‹%êÌ"-´Ù 'Èæ…:Ï‘™
_°İ©Ãšmv™¬®?e£¢ˆá²‹K—[SÉ5D2)’Im áo[ıNål /§J¬I>‚¦HShYCD+ÃoTèg!8ŸğŞÏsÓ„Å0iPfzP @3E¨½ Pæ ,†™ƒ„}[&·+ô¦¡ıàæ¦1v-£¡Ôè÷3ı>¾3ğ¦Ù8·+øšèÅËƒR<MDºÓü4gDüÁ<ü3a¡¡3’Uy	!^:^.Dü†§ùŞ-¸ÙÔ*òM¯¤D€Œ
Ÿ^ÉaMR­áfğ˜&Q\,gŒÓaHÕ„˜~(„ÄBÄŠI¶†øÆq³„ï8°ª˜ß2UI´.rñie²Xä¬ ½‘Œ•ŠEîÂXD!G„x³1¬®±B«ØŒÓ‹®\£‘£Qˆáñ‚N=ÙTÚçzBU¨È`zËO
(¡¾@ü£-àn&á-ı—:ÇF0R)­E.ºJ` xÿN«xÓÔUD[‹µ‹0œÛµ6´zN3Á8k”[ZsVh© ¶¾]*=#?ô„ª'{C‘ xö…?r"İãËºÅƒé`ì0Wİôí-Ê× Ğ:¸}ÇÄ‹ù,PºMáµ{e‘©K­U`¢ºØ¢l‘yƒƒzU«’?yS )×ÄĞk&tr-¦˜!FH¾ÁæAë®®®ªXõüó¯.¨íï½ìö{ úxó»Ûÿ£Òf•Ó/Ï«€šfûĞ´&<ÿ(EĞà¡U/ü?<F*EL×‰ÍÂ%Zéd²^ZŒ¨g§äõâÇÚ_ôNKDZC÷hş-»Ùx…OÛ4â>-I6ìsÏÉc&ºşùˆWƒã!ê˜³şF3áÿ¥	¯‹õÿi³±iÔmsËn7[v³ÑÒ­AÓÒ6‡–]oÌfÛvšäwÕZÚ~@7¬ºa7š­a£³Yï˜½3l4ìa³­5ÍææÀŞ²ÃT:©Ø9¨7­Şhh­ºÕìvÛÜj7šµµ©7fgk §˜VËAHæ
æ°Ş4ZíÆĞªoZÇÒ‡m[k›-À%KoÖ¦Ñ°Úõ–\:6m¨Ô 5uÀ¼v{K×ÚÚ@³êƒ-³c[ÚÖĞjÙV{(•*¶íºİnnv6´Wß¬k›-»c˜(¼ÕÚ´ë–ŞivL,™©£nÚÃF}ËÜ2‡vÇ€kŞh†z«^··šÖ`¸©U ¼lËŞÜl6[Í±iC›M(jovõ¶>@–±¹Õ6ÚÉÊ%ãŠ­Mm³İìÔÃÎ@õ¦¾#ÙjXC»nš–¦º16[m}ØioÚ[ÃaÛhææ°cdµv§³ÕluÍ–‹%6šö@omvZ´­ZgkkËj´K[íNˆÖ¬#ˆy&	ÖP·í†mt,»ŞÜlf³®×·Í¦má Ú›ƒá–
+Ûªâ63š²¦PçVkMSÌºiÁÚhÙº>Ø4´f§İh›ÛĞ5khviP²1‡İ¶êa³ŞŞ6››†‹	šV×ÚuS46mM7;V=¯A¬--{Ë²µ&LÚfÛÚÚjh0×­AËhÁ$èz{«Hß´êVÉ|ä6—=8wÄ½°Ûba
@­–Ş°[›[Hï¶­á`ËÒ7›6Lø ÙiMèIsC™V4uàfíz]·uÛl5u³®Y­z£©5VKëÔuÓnoÁ~¨‚“¬ê€y­†ÍlÕ;Æ`8 ¼„¿›¬Ëhmü¿ÓQ¨¦K-ÍlÚFÓh¶›»İhèº¶eÂÿİnZËÜj6k,aœTo´@M·´–8Ûh·a³iíÁÀÚ0u™­- ÔÉ®dÚ@évC«èÒÖĞÖ67ëCÊBÃš›@|€Z½ŞÔštIdí.7;æP‡&ov†¦½©w& ±ŞÖ5ÍŞ2F«®!/rqNç±¸>lÀ†fÛzc«Uo·´-İl›pÚh×7‡ÀnlÁ.›-ç»o5[›@j†Fs84Œvİ‚1±`j°Ã´P²Ñ€»~\<å¾¡=hkPÓf³c7ôV³iÀc‘iiÍAÛ :ÓjÂÎÅ¶JÕ’n8´ Ë›–9èÀÒ¨oÂZƒ¡‚İ¶-ÖvöL¤¥¢¤8Î-ÄÇ""?4±¨ÿGØøÚõzúlë…ÿÇÇHYØ²ë˜Ãÿ7mÏG>ùÿN³Uğÿ‘ş†r¶ï©9Ò2ÑOÉÊµMV–6rSÙ}½A^ "^rìbØOoBå•¿%}.“\{±Û_‡2}Ã>G_uAèA`“úÖÙrC^Ã¦üéùùé_9áO¶®'—Şh¼®²´RË‡ïİixáùü{?„­Æ%GTÚBÖ<;XGS7xWe˜ß‡|P*¥{–F¥Wö |Éä&/®Ùìâ®^ÍÈ€X–ûÒÁ]#•E|`Ù”°ÀTk“[\È÷¤Øa˜Q£d$B-CPõôÜcmîl~O“b‡0…ÈkD:¨Ë"è'ùÖA;æëmxÔ·ªZ§Z×ô6!ˆ!{¬íÂõèÒP^0æÀw…öÄµÜB‰3êçPÿ›±¾9ğW#Çt˜F¬p JU‚ÕPhÜù$špìØ:•\W ¯+,îş‰»i³ÛCTÒ¤Ã\t”îÙ¶Êê<z\!¸	M‚¿b·htß‰H5£€‘ÁÃ&…Æ9»§İß?{ù¦zt°÷İÓ½£Ã*d¡¹½ pddbÀÇ„fL;$âöô’ëz+ZŠ>pÒ%	…™Ò—`âó,€Rƒ"`ªî6†€T}!æUKgşµ‚šêüGjšrŸÙ¾´"—ÔaY'O‚Ê•ïæÃäNK¤Y‘TìnPDÉŸœZòÍs'Ğ4%ÂKë[JğP»’*/Ò¬i·S²Q¤¢×›¨SµëÂ£uãŸò%ÃC®ĞL(´Í‹^nRÀ»ÑÍ4÷/ÏqÂ*Œ®m	lzñ\]:5ı&s‘?ÿU	÷H8ÓÔĞIHŒ y÷õvìÿ¿]o ÿ?
şÿQÒßüËöäŸ>yr`˜ä¨Oş^P|÷äoáOşüşàóYd÷ôô„ÿÄÿ	şüóD–¿ÿWÀ9TÑ¼]×‰úâè˜âéq3ÿÕşü·÷oşÇ¿¾W?‹”™òâ©cÎúït´fbı7:­F±ş#=ÔùÿÁ$ ?S@àç- P]ª¼ân¥„×ª±FíOòÌ²’„úætDHKø)İÉºŠlŒäŠP5J¹3|zh!Â F@µäÂ1º¸äÆ+¶ù¸}e¸t®İĞøÀfà»îÉÎwè½béqÑúúÎêÛéïß^l¿½ª‘qÉŞ‘U‘Ó´.Q@ã/Fv„¶8Ã`Gò¨¿)!'©Éd†¿–2˜ÉqXJV:Î{‘™WÊ0Ê†6AqNo79Ñ"#ù‰;å€'ƒÒ‰× ^‹ƒhôšb¼;;ô¦œ÷åÑá«E„ÍÄëÅº,Iv÷N¢éD7\J¤¢ŠK zOmr pCº tåEµ¨;±BËNÉÎŠÃg'Ñ3xŞ©x,£EËHî»´‹–‘â×?í¬ÒŸJ¢aÏpW€ò(Õi»;E1Ø©Ò¶œbadqË+1‘_q’>ö˜ÌAÑÈ\å’å¹v	×•"°jZÉ ËŒ¬Æ™¹¹XuqÖ‘S"ñW'PƒŒLIü—ò_äæ—2fÅUç¦fı´@Y	¯oËr.$é\ \Î…T!ãŸK¹Ò9¤¯Ş@VeÄ¬ )U*Âú‚PÀ'xIW—l¬T©„>¬Çîh?¡_Öî!)›îNl}@í:ü2ÿ.Ìô(™9ÅğlE†MS¥BIç›=ûƒ¿P
ZŠf{g …šîIYY?×gwG´Hš›ˆNGCzîÒœÛá“+Ÿ¡1ú6aŸ(/!»°¯FÕÕQ€ªÏ ~Óyş1½(ÃÎê>:VØßïöv^Ì\Í'`,Ê”k}‘'¢…Q7F>kÂ(ô£W{•Õ`Ä³ãà=£¦<hä’º¶{œNX_§QOCÈ„0!‚ì-möBª1³ª¸¸}»âÔ€J*èp; ÆP‚ÛÁˆ-®$ïwVs§Ï´ÚhåÓñçm|„6ŒÿZ4kšDÎÀK¤—‘¶¯anˆ¬ˆóupa 0R1IRİúÓ9š²U.Iy›ı±ü5€ªç5Ë¾¬¹Óx¹_:ŞÎê¥“Š•X.÷9ÿËò_YKoYòLÊz£Qo¶Ñş£Õjt
ùÏ£¤/\şërùïÿüo/ŸŞ«ŸEÊLÙ:ºË­cÎú¯w:©õ¿Šõÿ©ÿ~^ù¯¢ÿ‹ËV×3¤ÁIQ°ì*¥ß½	?wqğBâÅÏ'>#ä)³âG|£¦÷KˆûS±}XJr‚v‚şÇf5·ÇÌãÿ›õ½ÿmhhĞ¡Áş_ï4şÿQÒSJ`%çöL’è,Ú^ì:÷.üPç¨‡õcX¡ø²!½ìGo›üm—
ÆÄÛ{"	ÓÄ·6†˜Œêáõ½˜`îr´‡íö{=ÂÜ›õJOo»–H)ú¹­76·¶õv£½İ„´½¹ ÷×¥!–m·Ü:æñÿ­–dÿ£é¨ÿÕêëÿQRaÿñYì?’V¨?WÎ?Ç$›Q/,@f6`¹œúãğé¥%³Ş_ãÍ:Ö;zµ Ÿ›Îç%4W~è:´Åìíov4]§ö¿­Naÿû)6Ü¸:œÔÿ­·¨ıwp¡˜ÿÇH	+RÇí×£SÌÿã$Õ¥ÉÃÔ±èúoh­¦QıÿV«UÌÿc¤”š¨ãöë]Aóÿ)Ç…ĞRë˜#ÿÑ5½Ãî›­v«óßj6›…üç1ÒSÕğO=¯¹ñ~ŠÎµÈ0ò-ÿ•!ŒoF¸ÿ¶¿äñßL!Ú¤
ÑòuÅ‘ÇÀ˜P÷¹oŒƒRé¸{úíÎ
ş½½BC]T#U_ş‚ŞöKÈWºwåŸs°ñEèÅcŠgşuÉ¾‹¤ğÿ’û·åÖqûıvv±ÿ?FJ9î{€:åÿu­ÑÑ:xÿÛ¬7şÿQÒ<ÇË¨cÿ×h4éı¿Nÿh(ÿéhu½àÿ#-Kf¼˜Ûs‡¾„ş”Fæ:÷é37©Áç¼“K^Ç%]•.õ.N)¼‡ƒ-¯SÕëU­™¸~K^³±¸ª4¢³­£%»42`â®-ó¢Œ‡–àêz»»ûD¯jäïÈëã}L±Ì±=ğ,L…·%°mrî`xÖ=rÁnØè½Ú
Ç…Ÿc~ßçrÏAAm:A5pÄ”Ó£İ£jÜ»%µ”Œ!^ 1Ş™ª‰%€ñŒÚĞ´¥ª<oõÜ×Vy\ÇÃîAouƒ”©ké3V®¼. L¢€Ù¹ ğp€ 0–²üXû*(“¯ˆÔŠõµ1£F\D@tÜp-	•Y1¢uíÀY»¼.
ÁH”ŸU¸ßß—Ê×ãòS<Ûåu‡•}Óï`Á+{ Ü¥c–£†ÃŠÊ–y+»ış÷G'»p€)M|lĞ*ÃoÍÓ6ùá«àİjb0¾Ndâ’§²ãÄÙcµ$’Èn27•c%’¹ùpÆŞÄã“	Ç/ÎÅ	ÌÉ#¹cëÚï÷ûbı³7”$°7k¬¿Q<ûh¨¥qØ(‘Tó	+Ç¬Rˆ)2B*ã2« Ô¡´¸âñ™W*µÔ8õ> ÕQ:ıÜ[ìrİ/±9üì‚©ó_§àÿ'Fmôñ³ÕõÚ"#¶zsXÒ]Jê€q«Ç¶¸Ğ«ºö¨	·®±ãÍdT‚Ù¥è³3J
>Òıceù°6èÃØ	Ğé®÷>±	ÜiÑ‡Àù	~jÚûÒM!øı•¦¬$Ë®cü§™Úÿ›ív¡ÿı(©Øÿ‹ıQ+O ?zfßYì÷R–ïÊ¶ß®ÉpŠÑ„™[qoˆÍ1zt¤#/\¨/µr Ä[äü§Ãğ1v#é§^½8Ãé‘JH^½Ùß'•1âùï!·50ªæyşœÔÂñDÎ¦¸õç¿ÕK0|–áŞ×ôiübãó¢¶Qßhl47Zí;çŞáË“ŞAïğ´û¥Œ*W½x¼‘¬×éH>[tü¢Ø·°Ï½®4',âRê˜ÇÿµXügàÿZM½Cïÿ¨ş_Áÿ=|ZÚ‚Eóİ[Ş ~FîkG>¦"qgÀ ¤Ã‚B>‰[«fñl*»†áÛ›Ì‘	Z§
c1	é% æ‘X2‘G§7s2&¾¼F¼àe %.É› FZ­-¸†6ÍpDl—†Å¡=MtTâŞD9Å+5âƒÿ"¨FÜƒWa5ŒQlh-ŞªĞb;ï>uF'ü²‘5z“±^%]ëGX„^sßƒuû(qz»&Ç"NX¥AIâ$,¡z#s²­|¦–GÌI`Ó	üÚÈÔx7ù¿µD=6º>+™QAöd¨h—ª€æÃŞ[¶a†€]áâµX¼ø¼jú¨)C%cÃ£™À©ç ½Éí!{3ÁÂÌ,
œ$î¥é)†ÁúÔ¶ğÑáÇHÜvU„§~´*œ8Ôl]‹*|Ú¹À˜7b0 ãÛ]ú	À»Ò®Í°İâ… %ÂeCé{Ãƒ×¯<ÿ}æéÜKİahûÉ—¤ô§ËïJ§×{'p`Û%¼cÛáÑ©^ãÜñ¸yné{(‹,ZÅ;I¶—-ªÿßƒè.[È/ÆK½¶Iqîöekí¾·ûxˆš«˜7¹¬…çMdpĞ.×2|ëhN¦á`%ÊWaœ8	yGGÏÜ;ãé(t*XÎÏ½§ß&Íe½œ:æğñ?ÛfÿãQRáÿ¡ˆÿYÄÿü¼?ñ?‹øŸEüÏ"şgÿs9Ô´ˆÿ¹PRùNP«~0Ybsø4÷òßzúluEüÏGI?ô_ïöŞ•Nì`”Şf×»ßñØzUcÿ•~xİ;ìì½|Wê÷^¾9Ù;ıÓÙ›c ½½şÙw{İ³ƒ?1âÖsŒêâ;Cc,×Š¼H‘²ÎÿËv9gıwZõ;ÿ×ëmŞÿ´:ÍBÿ÷QRáÿ½ˆÿYÄÿ\âßïÚğ"şgÿ³ˆÿYÄÿ¼güÏ[ÿœÑsvÜÊÇ‹£ùÑ@otf´Î[ES] ^êì0—Y¡,gÅ¾Ì
s¹PË¹±0ç…¹\z$Ë™3‹ˆ–Mœ4é±ˆ9'6f¥7¥÷sëN	ùoàÑ½î-±yò_xË4ş_»Sè<JrÜK8ÂZ;ƒ9OéNQ|àJÈ¹+Z`Ÿ»õEºoÊÖÿZn$ĞyşÒñ?;†V¬ÿÇH…ü·ˆÿYÄÿ,ÄÁ·éSÿó—ÿ3µÿ?@$Ğyü¿ÿ³ş:­‚ÿ”TÄÿüuÇÿL­ÿˆ:ÿOÇÿl·:­bı?F*ì?ŠøŸEüÏÊÀ«ñ?+_ãı+‰ÿ™ÚÿÏÄıò\€ÌÙÿ­V'òÿÑj"ÿßi7
ıÏGI…ÿÙÿGş—
 qz( Ñ g8ıØˆàÑ[XÂÃ¸ÿÈBƒ‡õ ’x‰ÁZŠjº‡… ßÑH.ì%Ò„_Œ7Yvó°@$nuçè¸w¸Û?‹ìwÊtÕ )cíGë½^İ¬jgz³Y+«Î?ôØ(”ò ¦ØB¸Ë\}T,ä,ÿ2u ‘²«9%½I²à‰qønQÔ·j ÙA~®®AñŸq&Î¢v_,¥yò­ÑHøÿíh­zÁÿ=F*.i“ÍNŠj”õğ³Ôìr!äu-bÍ)óæ áµ"ôOJq~-}K¡eîÀğ…çˆ‡ğàùç%ËÜ&ÑË’7@ŸRæ SüsÃŞ!”/°“0ˆ¦»C÷Î`#¶	9ØçtñDMæè¥ç†ÀêÛ~ùØö`£Î…Ì>ß
òç&ME*R‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠT¤")'ıoİ°‡ü 0 