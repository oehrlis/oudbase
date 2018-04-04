#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: oudbase_install.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: This script is used as base install script for the OUD 
#              Environment
# Notes......: --
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - Customization -------------------------------------------------------
export LOG_BASE=${LOG_BASE-"/tmp"}
# - End of Customization ------------------------------------------------

# - Default Values ------------------------------------------------------
VERSION="v1.2.2"
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="TRUE"                                  # enable verbose mode
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"     # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"       # Full qualified script name

START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
OUD_CORE_CONFIG="oudenv_core.conf"
CONFIG_FILES="oudtab oud._DEFAULT_.conf"

# a few core default values.
DEFAULT_ORACLE_BASE="/u00/app/oracle"
SYSTEM_JAVA_PATH=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_OUD_DATA="/u01"
DEFAULT_OUD_BASE_NAME="oudbase"
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_PRODUCT_BASE_NAME="product"
DEFAULT_ORACLE_HOME_NAME="oud12.2.1.3.0"
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.3.0"
# - End of Default Values -----------------------------------------------

# - Functions -----------------------------------------------------------

# -----------------------------------------------------------------------
# Purpose....: Display Usage
# -----------------------------------------------------------------------
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

# -----------------------------------------------------------------------
# Purpose....: Display Message with time stamp
# -----------------------------------------------------------------------
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

# -----------------------------------------------------------------------
# Purpose....: Clean up before exit
# -----------------------------------------------------------------------
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
# - EOF Functions -------------------------------------------------------

# - Initialization ------------------------------------------------------
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

# - Main ----------------------------------------------------------------
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
DEFAULT_OUD_BASE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/${DEFAULT_OUD_BASE_NAME}"
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
export ETC_CORE="${OUD_BASE}/etc" 

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE="${OUD_BASE}/log"
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
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${OUD_BASE}

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
    echo "alias oud='. \${OUD_BASE}/bin/oudenv.sh'"                     >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# source oud environment"                                     >>"${PROFILE}"
    echo ". \${OUD_BASE}/bin/oudenv.sh"                                 >>"${PROFILE}"
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
    DoMsg "alias oud='. \${OUD_BASE}/bin/oudenv.sh'"
    DoMsg ""
    DoMsg "# source oud environment"
    DoMsg ". ${OUD_BASE}/bin/oudenv.sh"
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
# - EOF Script ----------------------------------------------------------
__TARFILE_FOLLOWS__
‹ ÒÉÄZ ì½ÙzÛX’0X·ƒ§8E+Ë¢›‹$/Y%§]MKtZUÚZ”:K‘ „4	°R²ÊVs1/1wóÍ£Ì£üO2± IÉ–³²ºÍ®N‹àAœ-Nìç4NÚ¿ûÂŸµµµo?Vôïþwmãÿ+µþpãñ·ëð¿'ßªµuøãñïÔã/=0üÌòi˜ÁPò4ZØš‡~—y˜ÿI>§°ÿélpÓ›ÎòV~þúX¼ÿO¯=¢ý´þèá£oÁþ?z¸ñäwjíŒ¥ôù¾ÿ÷~ßF8óóàžjÞÝ gñE8ˆsÕù¾¡^Ìò8‰ò\mGÑ(Œ£dªþ z³É$Í¦jõÅv¯ïôÂè,Ê¢8ŸfažGjãOõÇõÇêûQ8žf³³³†ê]ÆÓ¿GÙ(Lw>èýpµø³©¼“?vfÓó4“{Óh&ê :ÏF±ZM£¼®rzÖJéÙ¿NeZýtowñ´úmøq;œÚ~7ÖÖÿØZ{ØZÿ#ür]Äyœ&ôñp–MÒ<â¶/`ëT¯ŸÅ“©š¦ê,‚Î#'0ð¤)¿
s•EÓY¢úé Ây¦Ó(×ýŸÃ.åþ‡q2ºR³<¨aš©(¹ˆ³4¡-ƒ¥?OgSuüf»	]ÃO4Ä!lô†ÀÎ§ÓI¾ÙnŸAËÙ)Î½Íë‘#¥LÃîwã~”è)|¸Û|ØZû—»ÛL€´—âa°øšG‘‚Á"ðj*˜2ìÆMˆ~¥g4ÛqšáòÁŸãpŠ-áýó09‹ò;`SmñIÇñß¹›O…½§tðzûäèààød{ÿÙÊçÛf³Ø2=ÃóÔJ³³Ú5uÞM*~æµ¨<MÕ›p4‹òOœHð¦{ÔÛ9ØV»Xom´6jÁöAçð°»¿ý¬v|ôº[SË>÷ QÃÓQÄ;Ãád È/zÝgµ—ÝÞm ]DÙ)4@	83½­£Ãã“ýÎ^÷ÙÊ*âq´B­¬Õƒã½Ã“í£îÖñÁÑÏjíéxR£‡/wv¡Û•^ƒë¶ÿzke¥ôŽ;GÇ'¯ºíîÑ³}C"ÂÎÂ.­|pz¿V«o¢Œxåƒ¬ÚuyåA-Øëììv¶·º½Þ38qÿšf!»Vÿ<è=[^ôŽaç€4ˆçíAtÑNf£‘úø1êŸ§jÛ`ou^‘WÒ6p‘çó6žA½œ%}Ä½OÅuws(ãQ¯óð,Z­«EŠ»ç“QxÅî°g\hƒª„òôh;ÝËÏTmgÿåÚäNE„ø©y~‘©f¬¾Ãƒ¿³ø³¿Õ}®šÛê;àïƒí}øûþûÁeš^Â	y®~®êD©æyÕÁ Î½  ^_æ¼}QõvÅ¡šózVõzÿ<ê¿#
E“QÜ'Š5€3mûÑØzØº©úÉ³í8‹úÄöÂf“ÍW¹r/à‰šÈ#¢7sÞ.í
~à‰Ú]õÞnzF$l¶z÷à{$$×Ü.ªŸàáúµjžMÕšúù)2ü$ÐÓÜEaÒIÿ6¦FíV>l\ÓÏÑ˜¯nW ŠÕï¯)z>ŒƒëàN¹_å‰Úc¤bR6Ç$½Œ'_âtÓj¯Öƒ4¿ýÃ×@?¬³ùàº
ùè"mø.R ÀfWp’3uÁ?^Ó>tXjuD5@BƒU¨€œ9b}n(àxf/jðEÕ€ïìuO ön@VTµùæÇæ7ãæ7ƒ“o^m~³·ùM¯VúÔyõèhþ«É’—‰ÁÛŸÐïÁ_kÄ3œWk5·ÁþÝkÐªøè—¢<ì[Ì¯ÏCÌ½®©gJdƒâ!ÐMµ±¨-õ<µ žšú8Ñ±:çÐ¼é§Å`L38JúÏü<NÍ·Ës<ï4jìö÷0^ë õº¸íÌì°
—Î®r†‹ÁyM™–g;H“¨L“îpÛž?¯šÓolõ«yóÅ»kºlÈ£ËPRE’MÔl$pˆ
Sô>žÞ±,´ŒÑUÈJ²jBŠ×‘›ækuÃc‘ªg-	Ö.™Zwš%…æ]˜¢Ú©…@·Ô Ÿ©pœÎÒÃìl†:rÞR=8T3beHÖûi†r(’QËíbã¦]hÀjYyý¦ð/…ïJ!$& j Ÿ¤SÚÐÙ)“Ç×
º‚/G­Ý®‘fN^tz……ƒ…^Ú+½FýäÑ” {Ã‹0¡´èÍg}}ä­t6„i:ëŸ³ˆóò–ý`Fi8PoW>¼: ôh·ô ]p—Î·——ï²š>„‰E÷ýGKßïf¬g@ÒƒÿúÒÙðë´»Ù,IPn£P?ÃÄ·ñ	à¹#’;P …ühäYò.I/50bùôjÂû×€3Ð°Àðþpø½8ÏIh+îî¡¹	úŽKÖÂuDK’ˆ)î+X²Q$Ë$i R9…æÔyøüø†[gùÈÙ&¤…©x]Àèh©Ý­EËÊÐ.¼Þ†omhŸWÕ¼ñ/Ý9? ìív%y*§Z¯“!.Ø?ý©^Ð©þ2Ë§ê2L’På mœ‡£Qê˜?/%˜¯EiDs$Ô&6ÖÖŸëÛòÇtÓP"T˜Z™W­8•=Ž½Æ4¹E ÒÙ@Ÿou0‹Ð:g(ÍÂ><x1;s¡£É
Í³M~óAwºª·­ƒÕ/;FVBëˆéñàåç›}Øz´“ÄÓ8}ž 1ªg‘I?l(PTK³«@º¾àÇ0ÄfEžQÂ„VU«²Pì)äëF#Æ@]ÍØ¡c3|âÝó‡«>~„_~¯šƒÂÏî ½^×× 7ìk©†ãZÊg¾ŽÚâX„f­ü¼HZTÐxÿŠ>,æŽ@da´™ÂŸš²8æRßî°ëˆyµ€ù½¦=\dIòÏp2ÿåHõ‡?à&]ªšc[ñ&_0=f?üUYw;ttû>	Ç$ó²1Î6²2¨½0þdoƒóÓ,œ¨š7¡Gk5´AÐ(XmÇ,ôˆ1‚Ùû+V°RFª?©4!Ç„ñFÕd=XvÅSvMÓ	 «ÿþ$KñÐ!·ib„+;	3@‚)ÚéX_“·ÕùE¼¹½ùËfw3CiÙ¨m¬ÀW8¯‹!sÍ!ýõ‚>áü×ÕÞ•‹Àˆž‡°4ß{ŒxÛ±ÝqN‹_t×”8§mVWGÝÃÝ­Î1¹EŠ£êÖ}l¬†òg=ÙµòÀeW¤CáÏ)E‰²– p¤ecQšw…Š›Ð°Ðõ\YŸÄÆó?¬Øˆ+†žÎI^R2b1²t¬¦ éÓ¾JôVî±*- ¶¡)iºRÍ|ËÅœ“c‚>‡ù/ :v4ó©Ž,ƒq;ÿx/àÆÂTí¨þH;°†ÓxxU–Â˜S9ìç2‚M¹À‘1\ðGŽ.6ÿ¹Ù¬UZá¯¼“¢_u•‡?lË²][6ü{aÄåw®ËÌØ'„Ë(!lyny#f‰º€²Äêâá¢÷¥u³É~÷æ0‹#Àè+x’¤M €ãÉ”þ>ÌÒI”Mã(Ç‘Ã#^;;±í}˜?vç¨*'§ÈÁ8VÏ}´†3†óÎ™ìqÅaÃ9ò\cÍÂCW^æuï-ØH§áàØíéÐÏm„øà…!G; ——”¥f¬îçí¿­´›íûîQ‘·I{¾ûïàµ³Í¾†ñl4'è:Æ Tû€fÐÔ¦Ñû)*3+íûOóöÛ¤­ÚO¯ô¼öii“–›àÊO©·
D<dÎéÑë›º'ês/Ê.@×D¬í÷põäzY_Ý/5—t4ðÆQ×ô¯°× xã¨¶vú¤x­(+¢¯©MßªÎç¢:‡h‡d•™ßB¥ÕÞÝíÎ!ý§çtý•c:VvåCì¨bþzr€Î¢Õðòºÿ¢ûýÎþ‡£Þ³ÚÛ¤ùôÚ—ôgíéÎ÷û@/í=[Êúâ³ÇèŒ[Wÿ¥ÚëìSYÆÊ>zûÝ}ìéþÛçmõ&¸ºòwyJð¼.pÖžªkô} ÍŠžù˜¡êf¼ÞqÖ+N+ìàãõJöÍ¶±¼•ë´rEÓ;Ëf@Å)g¡KçYí¨èøýº‹ÿ ]tÌæDB—p é2Ÿ€“ç˜òy .¾ñvŒ”ªêý¥Œ”²+‡ át¶÷vö]Þ8—Í†ƒqœÜ€ÏV3×¹{9—ÇzS[´õ•ìö3vþÑF™9XÚÝ9–cTèä£s¬ð,mÖž
Ò_«¶žv­ÏÉ·ê÷ÿçdM„#<>úœ<Þ¨<(Ÿv86*—ÈGùJ”‡¢Ñb¡º··HØ¿¥dýúh÷Yƒ)7Ûm4õŽ¯7	YQwÊÇíª¨‘-Ç8Ž.©¢É`
ta§Ù,q$9>Ë¬9Ï28yo(o
+'NL3ä„ö+þ;§“IH@äA¾¢P×²Hyôõ÷å¡ŒÅnG•‚ôèQyEI!ò[ŒUæs-)Ít÷ç|tü?‘þ#âÿ®}ûíÿÿþÆøÿ‡¿ÆÿÿŸ/ÿÿOû_÷oNÄ?GÜ¿D‡@™µWÖžò¯!ÿÿBþÕFð«¯!üÂÿ…âïkµOºwbîï.ä^ý&cî¥ ûŠÐ~Ä•Ïˆ¹/w÷ž«æX}ç  <ºyŒ=»jV?)Âþæáõå1ïe}Áøêò9o—¦gÞÞã‘“ÈÜ×·Õw/vö·Ð|
¤MÛ0²è2?[0¾W‡ë×çÇëþ°Š¨îäÐ÷YÒÓÛíM˜¨¾ëþ;ªb‡ãWÔ…Á†Œ¬&r:È½Hó!˜TÙÏo%@k[×L<îè,þf2 Ô×€¯ êkÀ×€Þ€/H˜¿pœÿÜ„šìçñk¢‘#Þ„õUHr 6é%–ÂcMâ¹Í«&ê¨"'²~ÁšƒJ	¢JÔmyä¸L1NJw²”$5r)X	ª"?¾0ÐãŽIÂá¢ `>9(?tŽöŠ%ªü8Æ†:Å^‡Vç¶“–ÚOÑÉŽ¢œÊ'QŸëûšpñ5õaiêÃiØ7›ä¹—Ž‡ h	º"yâŽ¢þ—''léüƒ,B!ÈúpŠküèñ2PÛÞ»:ˆý2‹§Q1ˆ}y6ÇÆ3óšDÚ°pº²d·KG˜Köï\/t™ÃÌ€S¤ÒaM¥¢¹ŒG#¦c9"jí…ZL«%vïÔY»¼ÏÓK5Æ£F1=î¸€BO¡gó†2£leõ²¯š#õx\÷š#£ZY]]‘wšô	ãuÛ¡«&ÇHã×n òGœõ{ÕÌa*Ìå`­Q³kq˜‰KÖ¿Là¾úŸ¹¯—–äŒ_1n_aìlwÿàÕ© e8M²DšXÜúüî€@w½¯þg„ï«;ŒßWwÀ?/FûÀ*P“4N¦Q¦ÚDŸ’Ùø¾PXÉH,Kld9Ô8Pïó(@lªCÄHb“¸ÜŸ·û N6›pŽÖA±$*µ^‡ÿÕiXwö?ÞŒ7»ú?Üü5"ÿ{s‚õÇÐÐ1û¯¬j½T·ýˆfÁ¼ý¶Ñ~«Úgõ/–50Ä¶œkzNÏç´º‹ÜÜÐžTË¦1å¬²×QFÁW+Áí‚Â]¢‰Ý¾\Äƒ¨ ×q³¥¥†«W†39Y,>—ÂVFŠÕ2^ÀŸ
Æ#4wäØàÛÖ$6LÃÓJqáÅ‚ñÞáiÝã-¡Ç­R®aÙ6ôãîÐ¼B|Î™¨Î`XFÐåÇŽ;/ž•û©hH«q²»Cþ0¦,êþßîÝW&×œ		 &õ2cõÕÚ‚Î‚ƒ§5¡µ{[1õ9p^‚ÌŠ².¢ï[f°ÛãÎuû&³Ú·f‰¤¹Ø‰Øó§cŽç¥É¬’Ué†kïý†¾xˆ¿´5!B+1ÑŒ‰o=xÛ~»
ÿ­¿ÅQ´¬´ß®·ï×@JÇ®dV¼œÛeªÚuv¶Ž5ŸåÑ"¬–7˜ß”Çoihá‘Í2S÷÷ü_]óhIM¢KbqRØ¡Jè6Øœ_à·‰@.ÄïûŸ‘N 6g®™ñnšNTŠô~D¾‘&ø¾)´à¼mdŽP†?ù‚ÙŠ§“¨
9TÊ§`•ÊÎ#«¢mªŸÈŸœ§³¬y!"Cª ›¢Úþ.ž¸ëDÍØ«wE|ˆƒWWéYwTœ~šLãdf°QN	‘?€ÒRºßß$ß©úì»µÇv{XGD¦M<<<GÖËstLe¥™xºl>E•¶ÿä\ªÏÐ„m^E¦MÖAüä|)Ï-Y«³ê_ ÍJFåŸ@õh½MÒU\ó1ð˜h*u\mëºo ¦û›d>¾>œ‹/Cñ£ÔÍpfD‡½êÍ•s1	QüN=yíC‡¹ÂUÁil ûiÏ-@Úm¿…Ýs÷L!%.Ú¶|Ëµ«xºÐ*Í×ãw E5'ªÔ¾H”P«-ð^r,Üz,—7‹ýñèïxeZ#4üN¶Î†'áªx`úÖ9Ã$(­º[¢Ÿ¸””´cø9:—Øî>ÎGOTO9á‹q˜ßjÎ\ÝVž4#á e¨˜!£ZE®ÞÔ­?JÂòûì(M§®ØØ@–
ˆsÿ§Ÿ6OGaònóçŸï×K ³|ÙïöÚ…Y÷ÞŒ“þh6ˆ^d°A ï€bí=Q7€¸ÁÚÙýöÛZãm­]Ñ¾f[´á[Ý÷sÎ_ûœ"ÈFhÉƒggÛíú¦`‹hXÄ—îàGoë`o¯ƒf±íì_·Ts4€sÕlšè4É8¸Q–Ì²N«¦‹yîBc;ˆ *ª{<N,¬“íðJîÿË7³ûõBºé‚‚’à-Qa'ƒš‘ª½MÊ-ÕóŠsé|JoT¼àgá§2©eñ$0ÇÁŒ
¤(ƒÑ™;~Ó~Ûä$†Î9Jþ)$¡Òš*DT§#9WÈ^Ý›q±+’šT6¡¤xx¾7—³Õqèw'
eèAÉ}P‚r+/îòM#Ï®Õ§Ä4WÂN_÷Sµ™Ž?@¤ú®QÅçVªt¸ŸBxÂI?•Q$óåæXÏúh2‚4qcJâü<ÌB©Ž9¹µd7H/“ˆäú<×éÔøÌŒ£zS™–39—V¤XŸc³&{þf.éüVcþ!ù?×¾5ù?ñþ—G¾æÿü*Ÿ¯ù?2àRþ9ÿù?b‡øšÿó5ÿçS`}Íÿùâù?hŽ„ñ¿ÞÝ]>|ž‚Þ”|¶ÑÖù×n÷ðÙ£(ûìù…YüEïr$ï¢hÀ) ¼û¬Ölê¿ŒíW¶­z9
Ï¾¦&ÝM7¿RjÒT}‡høß(IÉdÕ¨Îîî¼|3móqŽ”Â#‰v×ý­£î^wÿ¸³k¡âóÀ¾SßýÐíþµgáÚ³véž5•Ž&
Ò€~4îgfXÕw/:[}}x£ì¤â°tvƒøšô›¾ŸäÓò‘¾æ }ÍAúmeÁ|ÍAâÏ×$¢‚_s¾æ }ÍAúšƒô5ékÒ×¤¯9H_s¾æ }ÍAúšƒôÛÌAšn¾ÛŒ7Ç›ÃÍî—ÈAšÖ»*stÞÕ¹ªý5ò—(ãˆí©¿RÆQ¨@$ˆÇáˆ¯r&qyÞºŠÎZð_´¿ê+0ð·ëÂ5´hë_3u¾fê|ÍÔùï›©ãdgÜ$SGâ½å-Ê-Ñ‚æF’à¸‰
Â[˜¢J8BŸªóÕáþ^£š^¿cÄÙ0GçØl”ªÇÚ¤˜ûÝNÐï´àXÃ_ƒ°»mX]ù`^7…
Ä§âÜéuù¸Óè^RÞ[ê4>Ð‹ÑØ‡],zÙ¡âe“¶KsÆm¢‰úƒsy`;¾^cb€mÏ²3	iÈî	²?¥|ÎV¡ÐºcrüR¶æ¥3}ZÊ–¬Ä‹¤­uýšŒ4/ÉºŽ)ÉÊ†&É¶Ðv¹˜r»T$ÖMR‘œö7OEr^rÝ¥T¤¥c©NEª‚¾4IXGJ™¶•ÙGN·Ï>*Ëö,ã
at¼¡$8Øês×¿]¢ëŸ´#e0vÌËRsR`~û¡Äˆæ]9ä-lÊÂÄoURŽ€!¨Ž·’l-=\ã¸ÁRÜdÔ+ü±¸Þ7ó¥Øªœæç±”ÞXšùâg½8ˆ';H‚¶ÒdŸU†¥ÛÒ/¼i§	š¨Ý@Õ<ü{ÿbx“n»ùHÜCkzöw¦[û/ç,¦ÓeeQq)Ýöó›W/™¾‹Uãå¼»˜ªÖ¬øêÝ/ÞÎKæØabªI|{XÿÇ¬àâD+*œÃ>?×již•³c’e%pYV7Ï°š/$½¨¤v·J¤úü$ª['PýÉS7Kœ’õûäÄ©›'MÍó¢W,Bå¦ÎË‹*ìeg6M1æ½B3R–ûîç´¡€›KÖ5
i¬ØÉj6TP«>asä>û‘+UÜ¨/­0{Ú^yÏ³±jfÕäª Ñ{õ–¹lû©;…a:”]E#eyÜåA1üÑî±ùÆ¶Û$²Éèî>‘míWJdûúù¤w÷êcqþß·kOÓý_OÖ×=zòd]­­?|ôhíkþß¯ñùšÿ'.æÿñ‰øMçþ±Mj%`D¿¶çl|_³ [Y€:wÏ®ì›0‹1æêö)S©ÇE¡È(wÁ™WÅ­»0”Iµîpj¥ô?±-Þöæ+÷ê+±O¡-u(´ú­‚þNpjh_è½:é¼>Úêþ´öóu­^SOÕär ª(ü	§÷4OG³iÄöMÙuÜHqÕØ§uàŸ“ÃÎñq÷hÿÙý¿ý6ÿÞiþ¯µæŸNš??Ø\ý	þ‚ë]¬¾Þþˆ×¬~ÜÙþ¸Ýëvë+÷†CÊfw__ûÝwòúÆS)v<ÀðD­oúRÚ>ßü¥6ø9Ýa~Ë‰ÏÚg=óð?ìàÅæác~èÜœm~z²éD’¦R)´n¨ƒüÎFñªôön'žn]û¸ŠËmJ(Y×À]ÍƒíîËÎë]¼X˜#„8_³&4¤æýNiÜVt=s­ ƒ$l§K»~+Ïù+í½Ó´·w²} *ž×ï Eâé7Mr«³ë¶¥}ôÎió@Ê ‹spZ¡œ[EÓþÜV¨Äê>Ïæ¶:îîîvŽ»=i;Æ
Ä±ol¿Þ:vg1ÉÒÁ¬?u ²ÿƒÑ¤Ép|¹$ µÞú^jørï‡ÙnvÔ%ãÙÎ÷´ó@ÎNú@Ÿ[h`C5¶ G÷ÌX³Z|óhqöâºðóÜ*öçúÚChgrZèoMýü:ß6›NOö1@w0ôkò'{PœÆŸ:Ëš×½&ÝÐß·íGªój!q·P{`á¾cµ•îuSg’:ÓÈ/Ý±DNdÞŒ(ª¯3âcº3½Zƒ]ËäšìO­¥Í¾{œKCŠ±´6§¡»è±òÌ¯”–¼víÂÇyŸë%ŒV:à,) öñ»qŒ¿ºZÀ‡x>ó%KáÉn°GoŸùF´åÀËÔÚïÓhï?[¾‚ÂvCŸýsŒð®ÚKí¡Ço‹V‰ÔzÃ*ÐXw¾>Uµê'ŸÛ©G¯ŽÿÒyÓÑ]š¿oÙÙ/áEèPB”€~ÑxFÁz…ßŠÑ4žj88mƒúl‰<øMÖ/0ÉmvÀ,Šêä™PmJ)Ê'i2ÀèWtí÷8þË•KïRRÊ#˜àŒLÑ³§³íµ´ÇÄ=ýÝä¦=*“é³•‡NäÌÍL˜YdÚ¡_	,ŒCóÚìò“¸è`µë_¤™Ï\Œ=¸ñ@¿È °`$çÈÚ‰k‘„ŽÔ¢°4ÀPkÔcàe\l©ÃQ„,(¨7ñttEDä
äÆß–o?Ï¢é,KÔzÑŠÎJg…%Y^öH
š]aë`‚V‡v’f¢î·I9#Å‹¬WœMš&	‘²v£ý·•öä¾ZáÕ5õRy³?<kbàe”PM‰]Ç Ææp£îõZêO:À¾^‘ãð®z:éõv‹½õ¾`wGÝC^l^Î¬Æ*%H¥“"$g…!PýjüÃ>PÉÌË–²ù7RfXî~°_€©<‚¼ä´—–ÐfýáÿTÝ†×øƒþÛ>yødN[Z úOhûÇ?1\ŸlU°¹ÙêŸGº+ª£Ö|Ë…RTÄwV½eìòx“kÍÎmÛsK[\ÀÊöÖâ·§-¬|£h'ÑoÀ²Wµ¿«U4Î¼Åìª·W•ðe±¾V«DñÚ·kkë•?fãÏÕ?#2×j7˜/šŸ~Åù>ãÓ:Jt@o½Rî|e›oxXïÅnHoz@os8ow0os(ïnµî¼œ…‘Ág×?áÜ–²Î?“„ƒé8ÿ\‚¶Õ/
p+Ž·A}{Ø>ÃvóŠP ¦"#tÕŠo¡w_ý¨D¸ìGR§ìÍõJ®¸D<•¸Ù¡âu" ÀK2T¬jeÙùíÛÂ£MBêMsh6#±i~sÅ_Ìš;÷O–¾ezá`PšÛ477“"x³xþ¼jUA.ž¾ GiÕ¼[ç+JÚGï)£)CÏf4žL¯ZjK§n%Ñ%UÎh	ˆ¤}7XX5²»^Ð/¼˜DÓ¾IÃP"Éf(Ñ³_°Ã@j§¹a¨Há€OOãäìN]«ª2Í¢®	Û‰®·óç?{•|æ$Í{XÒ²9ï~®ú¯ŠéNçé»›?7éþu-r×Í:ÀfW›>eÎ$àÞjÖïÇ£›uÍ¤äÖ¬*§#.pË&Ää¢™ Á§YØE'd¾q'žßeÓ²é„\‘£Q‹üØ¦«»zæˆ‡j®„X|áwuÅ.}½ô&o òÞ?àÉÒÛÊéÐZ»çô×c¢#í¹ËëëJA»$èª›Ëºêvâ®º­Äë¼`„ÞOQž¾ÌL?Emð[i’§£H)w$H´ÙnË4Ìè0„(—†÷êøøPùŸy3Á¦½Ê¦v&ZÞ¸“cõ…”ä¸³I™ÛºŒV8rÊw¹¸©ÏwÌoy©p»9óÏ9­­Týa/‚ù˜&x²kÅÅöF¦šåg¥¯UÙJ'½¿:E?÷´™ž'N²<ÒÞj“¯Ñ@>ø*Èµ§ƒh[æÊ‡øZ}Äš&ª¹î&yT2íÞÜjCîÝÀ~Xwù«§$ÞQOæ÷p;Ÿž†R™sÛ~nO¸\,fßg­Â»|Ý^‰¨cU JÞ–¸¤ág’ÅÉt¨îÓ|œ«ošëøß'ôç#üoŽ5ªTîøÚòIõÖNmeõ—4NNN¯T[±¡ùZYã´ù›ÁutNŸ©óPm9U:Ó_Œ:Û9ß™)º†9Óm]ÚG¨ãB-˜ à´À¾"U*‹Ûã"¥.ˆC±‘«bý˜ð
û §ÙY+Å«òVeQÖ¢ð(Ð×ã‡`£œ]`/cƒ{¸?›ÜJX*ß1/žc¿¦2	õÅKòf>
'ƒ;îšã’®/GùÝÏúAÝžFë¤zuÉ=Ôt…ÿ:Ûy÷ŸÛåþI¸~Ý§ËÞm«w»
Q5•&eÊ]Øïn
Î!Ü‹r‡ƒ˜7€çŠF`Ð…ä._4v¹CˆsLÙ¯®¬ÀÙ|ŽöU9+/¼ÉÄcû/.€+ÅEÍŸã-œ™ôþÂ ‚…'k^ óÒÂ<ínã-*¾ÕJ¯Óå—óJœEÉ‰)J[A¯’(c£©iÄ7¨ÞáXv£älzÎÄh}ç9Æ›òY50µp-öˆ^Ð^òsÀ-«ú“6`qáA®+À1|®÷ÈìŠôúHGrb2lÕ|iý¹êß4›Ež‘Kp?e4Ì²0 Š}Ttçm_Õ:Íÿ6ÿ¾ÖüSb”;±ãù¨X
NÔº/“â ïåXa<ršÿá€c9!×ƒŸ ôÏüGÐUñ%*(õó‚ºõ¹â§@²Þ±$»/¨ÐžG£
•Ö3 SKëÖTº»!U´Pí“ Õ-[°Ýý7ŸžîãƒUjëuïø`c4©X}ž¶øÏ› ®\Û—|žl_òŸ^Òeù\4Á—ôóÏoNÁâÍñy¡¹§&9Í½çwðŽ	h-Ë</´×Åf‹ÓÐÏÍÝ¬·¹ó¼ø†®˜[è@?¯î@Çî;ÐÏ›÷áµûå÷¼™?ó¹SÅÀ<Û30ý¼üŠ¯0ÛWüçº*¼w²h3KWÕ{SCµW>ÏD®h*7d—šòóªŽº‡U°ñyUsÐÆ+›Ãs¯¹Kttž[g‡ù§‘;
)øÇy‘e=ªÇ#Îç££´h‡ƒAÄµîÑ÷vÅÁï¶¤CiØ$ˆ\Ìì¾Ÿ+z¨UWh©; Rÿ¾²ïézëOÁiÃ æ¤ØòvÀD• °¿gé«ðtæ¾M—vy¶W
P‚ÅÉŒ…–$äjc5ó 1G”¾ªÀù˜%: Î}¹q‘ø ¬u¸h$±ï_È‡UCÀô_Ó€Šµ•ö:·ˆÈjE^ªlK)]”©ÃI]ž°l±—¯·ü<äEˆ,¿‘:ÖäúÒ$ÇÝÃßve©)•“˜±;u,º‘QrAL£—@Ô¢¶$i=°ÝŽ)©Lí©Ì+ŒB*½æ«­õg«÷kðkõÖªõª¬DhóHçÁX½‡0V>®2”:€©¯´ßn´ïW@ù m6É–aí¥b[„íÿÄp±&Ö
ÆBü¬| Iíˆø©ð×žO%HV~bg>ür:6w–DÎ¿À*Ì2@õhD¥ÖîÚPÈyp;/±÷zí)_ªôTãjO¿Ôœ3 è=žk’‚á4¾°ÉÒ ®³ÒmÜñ: 1æJmû93óxÃ5)aÂ·ûÖ’ÐI1	x¯ Òaâ‚œ²Ÿáheæ«—/àD˜ªÀþpo6žÂKw3¢­t<N“C ]ÏVü	ß#¥)I/©ÝQ”ƒ,ð¬VsŸ;ò§ªyÝ[±àeŽUsÿùç‚o-IA‹ŸöÏj…IÎz|8FLat}Š¥õM­V¹ÕÈq–âÍ_H<FX=D­fÑ`Ö÷^vHœ]§N€3z§žÒ=b]ÐŠ42¼»¹!Ê8æ ú–¥6×fC«‡~Ÿéóïj…×´ZÇÖëíEš^¶Q[€•Ì?R~ÉvìLŠ6¤]+àG<¹!·îw–Â*¯ÂÆ˜õ›žÛõÓ‘Q´Kw’å1ºR`¡ o¸ô[$|JAÕbÖ6ÛÒw°€%–` Sdš4&Ôâeš]†Ù@vm1î™àÞáòiŒcG#‚‡7®ÂËçr`d‹g‹(¸ˆŸ9ý–—®°nc7èá0`}š…*aÕª}ŽÊý|p€l®_WÄ#Ô¸Ë‹pîðœéôªX¾5˜ÿˆ¥<ÅüË%®Ÿñ…¯¢^£–˜[s£÷QFchKr·y“j|àõE«òç¿è=~Ë·ïðÎIõÀÂísÞ§ËyÔ¼Ç“ì\÷vÎmp<>ÃŠWYƒ	s)/c†j~¬ä‘ôà8Ãê›å;Œ}ÈNhkŽ®LZ>ßpŒW cŸaœåS½R¤—qŽB‚§ÚT,Ø…¶â¨+î¤—wÞt·1ÈáæeÁ?×N…†ãµ*{Qt†ƒð[4ðŠ*`"DîhZ(p«®`TŒùê	Jj·hâPÏ4jPâ{­j†Údu³šºÔÈµBù·-ë`–±z(Uµ n9”% ìPÌmRôz,·ø¹éþ…(#[KáÚ/+é>òã<»èµc-´aJNùìøÚ^„#†êä¡âpŒ	Vk…-¾½ÆÌ/¤3ƒ=¬u¢×ƒô0UVÍtU4üÛNW@/\\ƒC-ÓÌþDÝüª47Ù«¶„·˜è#d–K_Ú2ÊS¾–/O‡STæßI$¯[²DƒñVèóæ>¶šU±¡ò‹ŒÄåëÓÏQTîèŠåù5 bÁ“ùw	-½¨x½–<hi)‡ÅøADÔ•%ÂÎ{Š§œ£A¿ƒðH©2	ˆ#ÁuxYIæO}Î…óónì¡o
—%‰NàÞO“,m/žðÙÍ²’œ[’ü›kì¼–›ç´Ì»)é×97È”*b0‹÷+U$1Ìk]né©›ƒVâJ·»¹vh…rãÕ ?<¾w¯¶RJÛ1˜y€AÈGùÛEi¨Ê€¿ù¦}ð€¦p]ù£¼XÑâå	zàá¹ò~ö3a)ÈÞKA	•áî~ÿ‹sU]ÍÑ@iÇÛ<Ž–W´±ÅŒ1WJQ%9³ØŸŒ/…œ“æí¿Ã¦Å½ó=fJ>Ôåÿœ¢å*Æ¾ÏêûñèWÚ+$w¼W0¼[ŸEXÈ;Þ)/ßÐ#Ñ+<£IPQÐ¼|y³Æ M°ÆÄ÷Á9<Á­_&B™KXõx³iî‡óäðDä„~¹QXpžá˜Phuu_§è~Å]îuEJP±Üt´w;ÈÊ+'à(%÷ÄNŽx€·kÁÉFà¥{¦† »q´C	
P9¨ºQbëàeæ&R³ëUó¯Í‚ùy  j>¢r_£†Y%Tzñ¨×niøÏ¿ïö¯»UîÝÄZãr®ý,f©/Ì†¸]ž:Ÿï\pÕUŸ¯ùÚ™“ÞñÑ'¤fx#ÑIuÙn”{-£îïÚ½|—_’ü–%7lcIZYòÂCç›³ä•GÎ+\rhÉMæ°Ÿí²äµ'Õ¯Ý:…ÅÙw¤:^r’Ýùy×êÝ"üºs³ú_µ?É²^m«#‰‹í±Êj©ãHYÜóôêõ8ŒõÆ|JÒã¼….åU&ÜºvåÏÚ2íU¨àW&0»êG]«`é*vØ,ëOLƒ>+DíøYÐ~k†GÅ„WVµ/Õ>Åì\¹½µºiCñ;Ò£Ò3š~é)P÷™??Íeï„?œM‹¶imÔÇPò—tÉÌ‹x226¹òÓß·t‰šp0ü0~¯Æa2Ñœ>ÿŒUcXk¹ªÒÛVäñ³æafU™Ø
ôû\ôUc–Øßq•U"¼•Øôë`þ'0`Ð••Š–"·þçn:¹€›^.à¦WÄ¿‹|/Yä*/kgIqŽxsÈ=4v–a6ª$×•¡þö.Šì]uR[¤ÒÛ5÷â.ÏÀ6Íý“Q:9âMY"{zÀu…û–ë¨Û9ò}|ôº[#wCSì'†áSM{çˆ”®@õQÜZNágÝ«Ô‰wBwa¨¢G÷/µyŸö.–«ÿ¤±~éEãÃ¹ñ¢–Íæ­¢èpÅ¯1£àEOá‡¯;\>L¯ÿ÷àçŸý¯’0Ð‹$ás¡ÛJ!ÕåE>ienR…D}òÊüc÷}YErœÙÒ¨¢Ã:¸ÂQr|/óš[6+¶›®ËÝôç³éF ø¾i}ô·“Ùïv¬z,w1Öry—»«([7¯Æ¾’Áñ—²ãO
*g…/X¥&OÝ°–âE¤…74¸íØ€d‡RtnÎ`
°–©ØÜ†§`°ÞÛÅ£Ì§³áÐz¢Éû<5å¾¯êKžP
9\~®+xÉ’–ÛÍñSÚ&êÜ÷´Ã$tÐ|ôà­tmÁwWqý¢ 9$­éûiõùøa›/F¿5¸’ÝÒeç¬Ót¬þüÔ‡ÊMðcäu|Ø|‡ì&ž7Ãã¹ÍËç½õ»lÏo<Ž9ÒÕâÑT¾ä,úÊŒ<¼&Cêš#ª±ºÒ^Nh-—ê/Ñ+Sá¹×ÿ0›}ó¿ætöÛwÕÿ,¾ÿ“ïËÔ÷~»÷®?~üøwêñ—~þ‡ßÿ‰û¿»³ÕÝïu¿X°O=š³ÿëk¯?,ìÿÆã'O¾Þÿúk|TÅçûý×êûî~÷¨³«_¿ ôP‚"AUsø¼‘\À‡µñ'õ—Y©Øì  ù`r•ÅgçSµºU§‡êeEª—§—ŽH¦Jòí5€¦ö[ê;©þ7Ì‡­4;k?T÷"Ê®Ð!çx3õ8žN1Û s&W$îðÚø³ í)ÀCùn‚eœ
oŽøæQ(?CÂÞPÐžS1 69(áh”^âÍ˜ó¦KŸÃ,
Ç ²`«chhÕ(au¤g§Ð›¾ë”ë­aÚñ(¢ÈCþ¸KëÅÀ©Pd²z'ÊÐé]ÞÒÈ[¹ÜWŠ÷¼—ß`ñŒ†æ—)êsåñÆcã…lXX#¼¯øž­@™ò\CâŒN’ÔxJ½¸B{!ÞÍ;mÓ¥3Ž“i”xŸÎfaÂ÷¨ØcPê39$µ”æbÕ®³,7›ÓÔÖQt£+]¹HàìâÊ 4áÍr€CÿjˆDPoÆ!²Á‚9™%O163+ÿÇN&#4±S|)Ì+L®d7pù0¿+"É–0—þôŠFÒíÂ8ÆÓ¦F$ü¡ÐjÉüs˜Bš&ü€	©—†„ïp8¸f<ü	ç—áå¼”-á¼æxÙû4˜d1Ö¾Q ¾z¶>Ö(oé)W
†P '®«ƒBÎIäXŸZ•íÎÎýÂE ©.ãü¼Þ0]`ðu„‰"föÓAD© !UÚ¢CK/—!¦1OW±ƒÆ¦{xwÆÖçÑ!Ó®7gk¸w˜m¤á(˜pkXóùLñÕ)f‹Ñ¾ÙËi7’ˆ×p’E”?Ž˜!vxî¯pp“_Äq†ù;ù‰N'Y·TçF·j]€Nqã±!nJÐ²iHy…Xa,OãQ<ù`lT¹Kî*5(¾tˆH?ˆ‡ˆ’›ex0,|†“vÍ‘Væ%ÞGü>OF wÑòYÿÜžxXºsÎå:Ã+•hEèt«a$“cT%Qe”»&eb ˜Lsž^£+ãÊKˆ5“G€
(Ž!ótèºuà ¯–ÁJ€Ót1ƒÊÏ]³Q€oå*§!^„LðW¬Ñ„ÖI®GGÔ QbB{¸[…^œ¥8½LñòI¾¬®×ÞžžM‰×0ïÅÅñ61{u£k$‚ñ	“þà,¾Ðx7ŠÎ€8×Í‰ÇÛm¸;àÚDQÌ®s–žÕ}6M0É»¯§Cô—¦	SìÌ€þa=.$îÞ‰,böÄ3C^rE¨@£ö¨K‹;>ôcòO¦ÓöØv—Eÿ9‹³HÖ{,7‡[tRdï(ð**ÞEVLôÄ€1n°IO
§²6òQ%Q:ËaZÈx$ˆîHbøÁôGëÖ£+%á—~FjÁóRaŸŠYÂC)‡ç#›%Ay…Ã/ÄÂ-8dá/v?;§&èö‚ø ‡ „Òå)Qäé°ØÈ3Q|Âd+ „Ép8ÑvÃ¨@Â)@ ÷0IvÂá”™i™Ê¯ •)Ÿ+ ÈpnKNñH¤ýþ,#ÿur/&]JÌ¢HO€Âƒ°c\sx‰IÜ§ë	Rˆ<‚á_2^‘äG¬}–àªN¦h‹òIëeÄìÎn.ˆ.‚!Œ(Ed>=)†.–Æ"Á×Ž—j‹*OÐÌ…&¥å³S4/`ä­²ÈrÉ4P=D+Ì1 “»î‰$¦$ô²¬ †3Ü]ƒ{Ã‘WinÅä¦@ØY¨¢'8¾†ŠP@×dszNÞ6\'i*#’y
Nðg¤{XÇ=¢B(Ú’Hò·n NSªI	™epö„C+ûq1;gš.p “³œÅ}Bš4
?H‰=£ÐAGó"9‹Y§MI3n¬Ä¢­Kõfâ” A32ÐÖ>–SÑÒ€ÌªyÕI%Ü/KŽ€pÏ45
tp
…¨ÌrîÖ‘t×˜Wc1š‚ ¹ð‰pÄœ,<¤lÊ	Ê—j.B?ÌåÅ¸óu¡ãîÑ^Ouö·ñêÈíãƒý6^kaÝ¡8áéýÚ±Ãcj,žÒþêSôÐœ£¹R82Zen®.`ø]s¿ÃâK¡ë,RCG¾nfÓÒ(c\¤:€æïÌ¸#P÷h¡Ýa£Œoú$ë5Éú¢£vÊ.Åy G¯T7„Î¤	k†ƒlyÎ±½5`¹5hU“¢¼F[R³BMFv…ØàÒ8/èÊa"a²F ­1K <6)Ã š3‡®‚@5'tìðUc}Àw¬‡¢†a~Î5Da"I·Ò…²ÂT‡‘Ù		°¨Ç%ˆ€}–J„Òg”ÏŽhpqÎÅ.`%dà«É˜”b­W‘4HÕ´ç F»­h1:ªÖO´Ág5YŠ(–ÃéJLŸ²Ùx‚ˆ%?›EÆÓžQÄCq„&¤%0$®N¹¼D:ƒcî¬Þ%Ñ@" ,#£c
PÆ‘GˆšÀàëˆ}%¨;ÅÉwƒ
ÕÂ}êS»Gp€L¿GÞ¦³ Ùæg>ÐDR!EA<¾àB´g‡2ODàü£0CCGŽ¬ÒdœLS¹D<A“Z.Â{0¡ÓÎ* ejR‘ 
`cìB~zÁê™Ëh42;ktÑÏ)žy‘Ìˆ6D	;Ít€È/jíJT¢²–«°G2CËr].E|ÊRAh0Ô)¦¡¯!Ää“$rÁƒP„iSþÇé¹„³‰íç"âèHh‘®‹	D£3aþ‚[µKòú~Š"G^D'"é€1Õ]Ù¼{LbÍQ&Õ»F\C`åF)BýÂôÌæ
Ó·E·„ú7zF0…MbuLVi±P/”tUVpÃ„¼‹ˆLˆ-Út 	lNÄ’W•`\K˜5[á‘’Êì£ÍxcŒñÐðaÀÑØz&XA€“ïF“Ä2'!qØé	‘eËkÂ Nì¬ÁÊ.¯8lÚA˜Ä¤q‘‹„1ƒ_3€Aˆ±ÞRâ¨ÚBÕSóüš£ÖDUvÉ‹hÂ*mX0Î¥ódßâcéVÖ0¦È”N‰ˆ‚#x{¶PöbhèÞŠªa6P;zÑìëÎBòyd‚Óo žÆ(‡±°‹tÖˆ’!Õî9ž‡YLÒ T¶tp…Ö‹†^JJno:Ê|^$:öýÙ(4Ö¶1.Ã¤¿Yx†Æ„‡ õmtÅÂX8N± €ÕÛqÚDY…¼hvz¤Þ Bf!µsG¡ÊVŒ3jØ‡ðÖÀðVj…¨jL:ÒU’WÃ:[_éí^„6è‚ìÐ¹þ»ðŒ‰ü^ø,Â«41fq£,!U²"t@Í§9ñÓº¢ÚûhˆaY‹	«ˆèvÀ¢$ÂR–úÅ£¨†f"–ðUqhÃxp Q˜¶Â“òCQÌP˜—X"®Zl‚Za5A<r)tú~ªkW…p8°)Êj¤˜…§—‚Õw ¥F#$ñÉ ‹ÑóÒ€x
Ï¨àŒy}…èæÆ^h {]GŽÌdÂícè÷yƒåì>E™VD­´F{n§È[>m@¦ö=„©m6„¡[ÞÍLh<rû0	©d‘F£ `sJ]Z»¡-‚<C§+‘é:¡¹‘M6Õ¦&;UFxZO •RòW¤#Qù¬Ü [ÿ*½D­µaª ¢ë3§ÁÞÏƒâq¥E-*™Ó4e!\~€`‘ÜÚ¨¬q7mÎ:aU'p1Éd_2žÊÀ¾ìKm«`i­ÚÇÀ°~G0z—îD54í#Gðq•ÝäÅb/Ë.M‹‡‹=I`c²lì¥»JÂ1—é	°òÒíÙ©YSå]kú°Ð‚ºV01Û5ÍNÑ›‡rLQÂ)Žñ,ÑJ,©»Œ
C´-œ‚H†y•lŽqÇàxÑB)új–Wªue¿‹CFì×¦Ü,'ƒZÙ
óná"ÑÆÊ}{ÝÜÝâ±øGµH÷Ø>-ãvf-,””éÐ($¬Fv@/cóyñ!¥þYqh{@nS2Dj?ÙƒQ
„Y\¤¬´hYŽñ
­CƒÀ±]P›hªM’ºç‡¤4z™|–ŒâqŒ0|¶¦-e­O”SPZ@~ç]Æ	1ËÀÕ!Ia•ï§Wþr”ë7RC”6'ºD,Œcñt6YÜ/Îv’^‚r|ñÌí&‚r³O%MB <áˆùsn—ôôÊ×	iƒÉÿbò˜Lã¸0¢	°RëËñ €j‹¾D®>ëš™€õP>
e/´ÏÛ-¾EfI´1 ÒORF„öBç©ñ	ŽÑíB‡Ñ”y^ð¡¢M*œ/Ë‚F1šål”C0.¢è²BìJDš”Qû¸†lWO,YÃ‘ƒ©Úç<íÊ !Ð' /*T“I+zdvAº•Å,Ÿ	‡àD)$ÒevŽpƒ˜³ÜØXÜA6-©²kŠLúÞJÀ‘ :ÎÃÑ°!ç›±Ö."¥A™æÆ¦QÇà=æ#£|¶‘±ýÙfÑÀN0G»$Ð'F…ha¿Îã	³ x“puË¬›;ŒŸ½gýÙXÚö"EGPbÇ7^‹£D``æhåTªGâ"ì	ñ^<ÈS´Á;Y_##oŽ²,¹®1H|ØB:¢ý¯ÙïÁJùØ—¸<àVÍ-2Úê®ÇýÔÛ<d¥€"TòdÝaû(1i3lFÿ<IGé2Ð-CrcÚ5rŒBpìÕp6nN0R˜ð™œiÊaëëšý°sxàŽ)÷æ ÔZŽÖÝXSÛ°TÆqýOz‚g*Èð¢JE†X"UÅ¤O–DoÄ×£çÛˆ>`D|ZÉ¾àË0¦zSWÚg	›F ÿi<¤Ø·fJ÷§|“	IÞ«¨òÂ3A±5ëÇ„0B’+Ø#!±ñ”§Añˆ2+Çx„4œ	ÑL…e#ÓŠI5¾©ÞU³H/d™Ëj&H]I‰’ŽÂ·+â’lÒàãÎ>ÕŒ±Ní}YL™™YÍÒ¦Õ«I»÷¨åœÛ7:>k‹j.’Ý-„pé‰	¾Ÿ{"3—@›é0-Ö°xpXâÙ¸šL'ù~vÊ’Øš±Ð]ƒT ?GÌŽÐ^/qf]OJA„C+wÈ®`òá"‰1‚ /4¡ø“\hAÑâÉ…ñÙDûT¢˜Eq!AßZ§£Ò`Á dýÂSÐ\ûÓŽ+cs{JÃ8£Ãê›>QmƒV©¶f­áf#9º»¡X#E•¦åodFvYÝMAA"Ðáp|B>›PÀ=2Gm(´Á6&„†ðØE¶=-Û‰düÆu´°Îµô—U‘6Š†1£sÇ")z/‰íEÅ\¬Õ$"
Œˆ ·öQÆŠ›+7mhî2²MöÐ…u^Ùê‡Ì¾vå+‘ÒDùÀRq	±ëH HHlb…%ÄxúI}‘·]2a%(®Jà“árj>ÜVÖŠÀ|«EeÑ
Év$³a£§û*Dz¡qBmÎÁ©ÉDûu#¤eXb@ü2£	;–8Çó‡ïëI±Ïm‰ÐeEVÃá\¤yå:’ ´>² Š0™ê &÷<X½¡Œ^J Ï„tM=hÔ.ûÅL¢(ImÈ–…Ù`„q'(ks×e“"TyŠ”£è}_s×Rk«Nàdx%>{k¡aäL@µá
ò;aJpEjäVJ"z®ƒ½´™K©A]_úAc¥¥ù®X)¢Wcç:2‚2×ñò×FìKó*ö$2–i	Kà
]råÊÜ^˜gš…±AâC²8‡ï°ž†FVðe(Æ^y½râ…ãâÂhç½Ç7C‘ê‹R{Ân"œ¼¸#OÐ!úîC€’U_{HµY‡Å1zVŸë|FTvÑ5}‘Žf|³OHEŸ	ñ7Ï©EÇÅœµðìý¶±©]".Uš;^jËòeä6¡²hFL–£²` žà”–àß—ðäà4’€Kê:?Ú¯/J/+2èzJHe«Ú>òÒÃÿôŒ¬M³r¡s$‘¹Òƒõ}ZYA"ÜyâòÔ}V„¾„Í™ÃK}CI…ÁØp@&Få€9Pf\üÇs¡ãÐÃÁÜib Ñ¼J‹X¡³¢HÃø”D–±ñqXê–é¯`L'Á Ôà6$«‘Cïü*'XÂ¼ÈªµO;-*p´Þ yo<	“XÛ•˜JT›úâ÷,­„j0ËØ~¦¡3@æ`”=ÈÑ„³d£µá€°*gYû?tÎ!µõ÷„¥À†"ªÏÒÞKC’ƒñWWQ˜±éÖiÂœÓ±?iarÂÜ*ãk^GÈdÃ5ÌT@œ@÷ú0DÉÔ\\X·HîJ‰'“ryŒ0½ÈnËÞÝƒ2"‘£æÕøÀ¡¿9>4´‡”$wáâã”£ÄjG/O	8a¸îu)×§!òŒµ~±˜°
C’mX«¨‹°EîPGX°’°#IE±œà³C]}íÒÝ:‰èp6¬Œ!y!V«Êº2\8ÂPV¾_)ÎµQ‰Åi¿æ$™±:Š.uô` a#,QGE(Ú®ì†°WŸy¨9<Fä™p‹S- >9µrÑœƒ*ÚgÞ#Y~öÌž°t„N¥ÕbÌ>ïGEK^Ak¥vv}á†‹FÅž‹™™ÐezÈ”á,cë c3*#'‰bà¥Üï
°³L-s™D4Ò'¥y	wsQ‰GþññŽq¹Ú¡ý*[†˜½Ãe·Öœ+®tFÄCˆ]înr9–o‡ÿ²BŽ*RÌZê[ë0Æ¿ŸÂ™eTµ¦º²ì2œ»º-¼ÇU3H2’IžÉ¾Þ³£ÕÆMÒ€6š0&«…:ŽZb†eX¿uŽ˜ÌÞæÜÓ&s95ÑÜS3#»à$Š²æ4mâ¿þeBþô
yœ°½€•ðÚUxÂ}ß ‚õlðòiÄÔvHC¶I¼Õ:FÂž1ßˆ®í‰¨¬!w4rŒÎ QO@'…köˆÅƒ6ö’ê#†‡Ãs¾4÷Ô8²¾7¥D
0$4Æ£†<´FCq84Åæ³1+ÔD+:&Ò)˜b®(Í¶…iÔÌ"8[nÀFÚ¸|U7^Žã60è<…ßÏñBpq^å–jÏ±qys$µ¨8¬zÈ¶è„ÂÐ‰aƒ¨$˜»qäÜÑ$C#=ÄöçM¶ÒÙét8ã«Ârëu€­IG¼ÎÃð"¥°E’<Â3mãFPéìËž(VË	±Bµ§¡jÞByqÕÁôjB²bÊQt€^&Œ/…yî¤|4
f	í7ž™Ü†BçŠ'A$¤ô
pSh`.Œ%oQôø¹¾€¾ñ™¢4Ž²£a„‘#+—½0r½Y28é •©f(MóRñÝjÒw–h’ð	ô'áŠä iqŒŒšl6‹$€Q¯žEÂïpÜ+È;D©èoä1'BpÓJyq£Ð1Ð<0]Øù]tÅËË„/¶°5Á8©NdDàx¡¨"m«lÝÐñxÞ ‘aé}Î	ÍçKt‘7<´
ùC£"›gã4NfHä¶6|­A8­@SILHM9tQRE˜°©ˆçÅ¡9äÚ<HÍ÷ýA¦|ø8” Ñ¡çDKJ¤Ò5Åj¢/vÇn=7*g(Ù´¬º«kcƒiŸ3·@73NLf‡¡îÊ9‰12t­£6é‡d o71¬E"«gD;‰¯šDÓY<½2riÀ4…ª¬Vš7ýæÄáHÂ—€ã(¨da<oß¾­•L‰§‘«÷¬ë«ygSðgâ@r-ÚÆÒC6€n½cÆ†{¤ì vä@,AIÉ`ìBaïÊ=[œ”¤k–¼½§À=næSÂ;È¼ãè`¯nÂ–Üñ;zÔ¼©—#ôÂ  BŸ2œVéQv¤ptí="„æë86B|?tfí±1ë9S‘]2xÕT
JËc°9^…Q€Â@ë"î"2‹\žGIÉ	…„*M …vg–EEÜŠÈ½u3õÑÁX.âtD‰x4¹™Ô£Î´ÑCaÆ6ª.ìgiž»€$DcÁY`ª0wŸµ4L9×ïYyx83‰^66–eáè2°rTp@ü#ª3<?`8(Î‰îJ½kÍˆ´Î4Í`¡€›NÌt‹ã=“»Llê­Ö·-¬ƒ«ý2Ç‘6¨Öœ§ÖÁé`Yä†Þ ŽK¼tÉ¼©ÓÎg%‡3*8	â“ˆ“~²H³=ërkÕƒàžCñ@‰¯I‡M°OL»;HŒjÀ1#œäfÓAlæd7XÝ5dy±&œNlë+å<aTqº°rì[¾u”ºCkü¶’î™Mõ	$QÞú“MÐQ½q`³»ªbt¥’3I8}!(…‡`ð3 =íêÌˆacUUhN#”ºœŠÈE8ä0¬ÞdÑÏÂ©¤(!™#ƒ:õyÙrK¬ÎÁY<m5³q»â/J/eð*qR³‚õK=ÁB¤w«ndb	æé„Å†øŽÅ.B“ï“òãîÈ}¨K=½·2îÃö&q[SÜFÊDÑ¡oº ÎÇ.ú¸¨Œ‚Ã8¼Q¨<@³‹”% ‚³eFvL¨QFT]€O‹†]_H(ü0%úÉ:?¶% ‰´I~þ-ôyQšL¬…c“ÒáÌÚPSrÈÕúc"¦ëOŠcxŠ2¦vB™tSR[²Ã¾l
c~f—›	{a×(/—©È@½kuÀÆfÚ¶Xò¶ñ¸jŸ,/=»çPòYÙŽ§vôý:ó˜bt/ÃNžÅ‰Qn-ÎÊðmÆíœº8‚™‹-Z!¶:g….)m/w¬‡ÆÃ	Mù%;•A6G6[Î¤³JÜxmÃÀÁà•ëô»÷©Ö…»FG×¶Eu#ñb¢³‘­U—2ƒÓã8FQ?È0\Ã<Š†mÎÊ¥H‚´>¹íwèb:¼Ç‰Vggâ0Ñ[&–Y½øW~ŒRçÜ›®ZÕY¶…m”È›º¾ykm‘õêŒ…mÓp©½ ŒõZ'Wn;áœ2T	×$ƒ€”R»˜‹ñKå˜ì ¦r… ¶b´	ñl4O€|‡t­&¦ùÀ„‚’xƒs—“ˆöí#2‘·ÖÀ®™« 8 Ø%Qz4w9ÔžµžPDUX’Ã Õ¼˜·•E-p†ªb"–`ëçh"Ê:CÙ¤TÎŒ/0 •$@íÏÆ(sj‹íŠ~ÿ¯b,)ý™;Ny7ŸÖ©ç{æñªQ£ÞF1ìùÞ…ìÌ¿k£ á²˜[ôÝ€æpY(”Lž	`s“™2K@; F…âú5$ø@Èë¤:
:¡g±O”œž ldüN) Ë9?iñD5´@%!ëâ¶)·NÀ“–¹FÆ#œé×ÂÜQžl@uý2]±# Ó ñþ±E
Jœ°=Âû |4“1bkAvNºiÈs¦&•Ã ©¨Š®S¼çÖÉa%ßô˜ÊSx"±Š«j/çgYMe‘WEK§8'Þ^ RBáà¦ c1*b¶Bømrî‘­u6}¼r‚ÂHx§ûM¨ä!©ß•"âT$á,05#Ùïê˜ª‹ "ÙX®Fe‡²X†É ÊÊ¨RŽô²ª’A0ä‚?výÄ›ŒXr†­à ‚æMÇÐP|–ÜÖ.ÕG®Cve¬aÈ	ÃOÖÔ€¤šáTv‚ò1Šîn›Òª{IH7ZÄÀYDgN¥)é7h&q”;s	–Ï¥Á;³œÀoNãqdëùæ&´@ÏÅOËòiÝêqAq¸6é ?£…jÖ÷¡»¾D|Àp&FqæA±qÏÒüµtÆ|CŽ1ëÙS‰+f¥"JS¤—™¥Ðá¦š(Î¦|š[š¯˜Æ‹,r¦ï„^LÝ­v0 á¤½©ÿù‰ôÒÔTÁë0¼­:*!0\Ö‹^Fi×ìO-²þMän ~¤=åg´Ò%tì¤ëáÚe>2P ä€ÃUô@`R–Ÿ‘d³;IèfÈ¡Ü¦ZJ9ä¬ù$2‹"Ô..“Î4Xâ œaÉx°xyƒÚlšUr¸Q¼ o©WzÈ@FJÍ'Ò?®â s^HÃŒ$›5G.¸ãœ}]Ñ’³õ*6Á¯$‡Æ8Sc‡Sy‘K	¦	 ¹B–]ƒÒ¹çrCî‹’rGs>i"Âôvz	å‹Ñtà½DÅ©å™“kå{U<îªéTî¸eýÒ(IÄmi-Î²+\è…úÌgìŠ ùË[Xÿ,HuÒ‰E6í‰ó2c¾¿Íõ…e12¤[c¬“¨ZñPy²þŸKü®GÈøœ¸NÕä‚WnI.Á¼²~È÷±T'GÝ‚Ê¨ÛP„eã(;cÌqë}}›w\©AŒqÌ:j+QåÙI˜;;‰¦\ä2pçŠDØÙb—|p¤	çš·ƒGÔÒsoÀ¾v¶_Ý§ŠŒÊ¢d399A‹ "=`ëê‘%ÎŠ[¦x¦‘¸@|Íp\’¥XÌ«˜ë¨s§`ÐuÎ˜Pœ	Š¿SPÿ´P˜XRþ«†C¹*‰Í¢o#å©P¡ríy“4Cãû,¤ä#Ë§¼÷y‚´WB”ÂÀíßžX¬®›¥WáH<e©BÇÙ[v,ÅqÌ«­tåÎ˜îtž¢Ya*¹§,LŽ¥&§AòþSD*}'§¦”ÎÐT‚î³3­ÄŽ .-ÁX/Hƒ¹ŽšiØÈF*ÇŽ¤þñ˜¢›Äêå…Ã~là“d•¬¯·Ô¡.k©KÎ%luL³š¼)ˆŒx¦ŒE—r*Ôø“v
ÓyÕbmNJccÆÈy›å¶6¡M„Ð!
2L8î¨Mù=“Câµ´ÅpÜe/Ò7ïq Œ'8Õ8ª¸aƒ–F\ß4ì‹»ƒŒ”E}ý´¡9Ï#· ³ã$pƒ0— ¸kRÂƒrÈô°ˆd.äiq‹¥ UFBí™æ©Î9ž¨ XAPÒg¿*¥·¢o>Ñkx¥	Ùb.ÙÈtT³ßl`…6¯JQä;†NÓãEc“]NMLÀ«g* WC{v9½ÓŽÚÂB²k˜òXõ0°ª–¡:M®™ã©Üé÷‘p¢ppIŠËÂ½”ƒÎÑîtÊùˆÛ²/\•bHÂ½ËÄç!²tö'Fz3¡b±š]‘õ©æO’‰Dr¥Í#4Ä:Åî÷xÊö7É/Ãà€TÔ—«R©È=i·ä8]5eç¹$K•bý÷w%!'rÒe3±ûs·ödËÚÖhŸk¦»¿ƒÜÀÒ…))5×9V}ÎlKóÒ¨á&³Üª(§‚øŠeT`Ô”8b<)•³Ôæ§ºƒ.á‡“ 0µÒ©L0ÆMê¼èÁÒ”$¥cÛÃ@Ç48R“¦(lIá$±51SãPEã¨úªÄæÌæ€6G¬Ž,Û@Utž±âa­PÖQ( E–è4J€ Ûj!L	wÇ
c*—­>4=4\ŠÜ€"•ÃL}l]z:¹j“Ñˆl* V<ükYtáBc™OŠ)Î£¸º+2m( –’*(NÈrP2o³Ì“±ü¥m.<0N¬Ê­ü7™û…Õõˆ1Ø‡pK¡iqŠ@™œ;±» $Ëè0Š£‹ÈaÈ©k 0Ÿ…Åb3L3‰¼2©È\G~Pð1Ùh¦mN5 WA&Ý#HgZ×‚¢	7Jª3¥¯“ÿ°Š‘XàFG¹(¯UtŒ€fJéh_36Í0ãÐÀ¹êj®¦TÒ¦“
,¡‹7xøq^0a3*‹É‹sÙì¿üÈNžjSÚ@ÖNqa «ÖÉbb)ivU“;1Kxì§ãb0;'zˆ#Ã¦âK^T_X¶ÎmQ/[o%«èÂ“ŒôbCüpÔùZHËWºŠÌ—J,9$¼Z5“EOãt*Åˆ¯é%H	"µéŽd'Ópð mÈ	±ÁIx5¦8§Ô:¤¯*…”¦ÑöU)xÅùBV
5úÜþŠ°Y6kè’æ†T[Ã+Sm§+mxmPZ’‹>E‚OÕIËTÁÏÄóHš	¢•àUŽŸ‹©´ïÀ˜—¸Ô?>®3ó@'ŒƒR9Ä3TumŽ¨¹?‚E¦kšHÞÙŠ,Ž[D6‚×tµd-0‰¥þš\†F{nX«ûÆÕ^˜Ánái:¾è<Ö¥e³ŸÉÔ brÙÌøøDvBuHAÆ HŒ<0ÕØ´ì ªƒ1ÓxuÅ%0h›‘1tÙœ4fw×Ó©'*…­Ö7ZXÜªg®1‚ý>@ˆù}º™kŽµüV¨÷Ç&ŠÔ)S«Z?¤rv3ªÃîG~´ƒ­+‰bÃÀ‡AÜ7aùº‹*—Û•®o‰ìû5¶¡ùï¶¬øÉ×6hBã³ø<•ò:µ,Ç³Ñ4Ô÷Äp¤^©2—gÐ%Rt¦Z*hêö5a/%»¼kþ‘âfTü¤h*Ò4—–xÖ'®³ëøî*”uA£Ç*Z#È¤`‰Ç9³ð˜±ÃòƒB(¦d©Èuul4ËF×ü$sÑ…·JF'GÃ0ÃCÌÑ™:FÍOs«­?laD·•2ñ^Šjé¢ë)>)Ð”Å)É;¡HX"£äŸÐÜÈ»yBâS+¯ÕX8|%éd,£¶.‡­õê_(\à ¹1Õ!ÈäŠwƒô½
¨cRèJD6Ðqµ:Öº,îß`vÀ8ÞR<P?Ê8lÏ)æo´.£bq3ZY‰çì*Æ—G-uÁÃ¸ßDîÝKó.Ó¼»9²U
eM.ØB£0¦§=ïÆB:gèÎÁÃ¿TàÖØƒƒóÃm]®+$Mâ,6Ù¼µh¬^¤Üà(9ˆ_`FÉˆîÐáëL¨s©ËÄ¸ÜŽŸI£'¬WF%á±iSÇ}Ñ-’4‘_	.—P-šb~ÁÏè*¬UPX«š˜u1	ÂZ=Í½ŽTßžRGR“íÎ±ñÌ¹rGnP¥G˜òuÅhL°†Ro‹7åÀ8#³ó:¡´ë¯¨õæ£ëŸ§ÚK¡ýÉŒ/¨Ÿƒ×šµ»#,m `Ìû+¾a~A5ƒh_Y\Dþ}fPAHà¾ŽçGÐ÷s1¦øa_¾SÕ.“òáØè5»ã%!èú­ó»ld—6T‹[f¸ªgb3q£%ÓÌFçnÜ¿?”¤ÞŽ P—0kY ÓŠ’˜Šu‚¦%¸ŒØ ½xHÉÄîqË„†3*ý ÁáLâ^uºj§§öÔ££ÎþñêåÁþ ¾?êì5Ôñ}ïþûqwÿXvövŽ»ÛêÅAçðpwg«ób·«v;?àÍIÿ¾Õ=<V?¼êî«ÿÃN¯«zÇ|ag_ýp´s¼³ÿ=Ü:8üñhçûWÇÁ«ƒÝíîÝPÕ†ÞéEuØ9:Þéöpov¶»î˜T­Óƒa×Ô;Ç¯^›Á/Èê¯;ûÛÕÝ!@Ý?<êöz0 €½³#îÂ;û[»¯·a,õ ì«Ý˜4;>hØ›´ÕÐq0 ¯{´õ
¾v^ììîÀzáµZ/wŽ÷¡Z»|ëõnç(8|}txÐë¶/! ?ÚéýUÁdaÿíuÇ ‚Õ{xK=öåÌ9€mÂéª^#‹€yïn{‹‚ÕUÛÝ—Ý­ã7Ý¶„nz¯÷º²Þ½c tvwÕ~wÆÛ9úQõºGov¶hŽº‡#\¥­ƒ£#„r°Ïhô¤ÅÁåÆá±«£–™bì#uß ~¼ÞßÅ•8êþÛk˜+b‰ò±áw¾?êÒB;8ü°ÃÝ3ˆ¡1ô
ü`ãG@±µw°½ó·Egë`ÿM÷Ç^à®
¬³EÙÎ‹\˜0Œ W	÷m»³×ù¾Ûs0ûä’í†êv·vðøð`——j¿sÅ­…Du`"'ïcð"à¾FèŸ¹ƒ]µ}—‘RíôƒíÎqGÑˆáß]l}ÔÝ‡…¢3ÖÙÚz}ç[à0šÞk8;û¼8_:â;GÛ>d„·/;;»¯Šˆ‡=À"HB@g'¸E¯ÞpóÕÎKèjë•l›òŽòêlÅ‹.4ël¿Ù¡ã(ýÀ wdM`vAÖ‘±ïÛß-‚Wbì•’T\æ5ðˆžÉˆÁ†#‘mø½)òÁ‘¶öF?|F);àä®,,ñÍB…§”.Å!ÂŠ„Ñ%@gXÂ…õPRx):;–cêRÎÅÄ–÷tGB Më4OG˜?O…“Yü@=¾ˆGÎØ+l&ŽfI½Ü ›Xà/„Mwfh)üLÑ¥ÅÀí‹e]+>€—´Ïsn ´ŸW|¯S‡–ˆÃ¹ŽuhùÈòöAX•äŽIîõ!]àÒÞJ¬ÃäÊiñÈ<Î(Ï1ÎŠÿe–rKâÉ§\Ã÷ÎÉ¢nÂ@Å/Oÿêl‡èºM4ò}þE¼úfUã_Òº±¾$bÄTŠ1ÐŠ¯:uÊHþ:&p‡ìÐy8Ä©áˆÍÛcÝ$*Î¶  "'ÌžïkÉ½1’¿ÄšéT5ô‹$!×ƒ’ì­«¿‘úS32M•e1‹¨IJJÛtõœáÌÔv¥«lQ6äú—“Þ×5ÞœùßÏ)H@Ÿfq4DJhŠ‰¼õ\ªi)ku«®¾ÃêtÏ¡‘êô½çÜï±Ü×ªÃ6¼íÞ4÷{›Oµ>(.Îªö(.”’ÃÜÓ/$ág¾ßÐjLÉ´`ã(8ýhÕO7­—5›VõØyš»«ÎÑ½ “tHgÉ¶“«Ò¢>ªÅ5ä Zd{jòj±‚ÁÒÆOK¬8íª(yÁâÎ¼”¼zk‚a‘®]¬&ëªQèpñÚD6û‘uóK]9§™]KVÙ1ò!RßO§“Ívûòò²u–ÌZivÖÖáíç0 †îaÒ[Ú‹ˆ0í$û7_=N5ïÑÎ—¥	VÂ»BÂ	F®ÀÜ\F9qõP‰²¹Æ–†¦rú²•×#›rFéWšecaØ)Õmäb§nÁ^,\#)«ßI¿Ïo|KxÈ¥™iM;/z»¯»»?ºšÌSÚSÙN5½ýºñýò~Ë‚+žgË:ˆ–G#ì‡“Þñ&|šMR´±$<u»ëßw‹–¥ó«	šÉ]¨Ì-„z|4ó¶àŸ¾­ÞÍtöÂÎ±w*u0$AÄ8¶-ÍÔ]cÚ¬d¡õÚ§ÂÝ¿½c«Ë54 ÙT&À‹Óô}ÍÄMÊ)ÖC-©×Îuz…b¯¶· èý¢¬N1]¨ßáàëÖÈë…¸˜F+ãÕ¬ß”uÇ
+æÎ—Æ§î¾ÙÙ¹V’%4| Zµ9Üxó6Ò`é!eËáJcL>éæ"áîW›Ø{©õ¹“+áÐåÄ²ý˜‘\ëu%Év\ö—ò:ñŒÒb0y¦È"	²9Ûö(®¢©˜!åÎ®íY|Ž.u,Â¥„àÕÝ:ndÃÀ²yÖ=ŒŠÂA…·KêPÆFS:†ÐTnÅä<Q:œ_µ/Ï¯š°ÌÍÑÙdÔ:ŸŽG°;¿ûgüÒ~û¨ÛÙÞë¶Æƒ/ÔÇÚÚÚ“Gþûí“ÇôïÚ‡Ï£ÇO¾Uë7ž¬¯?zôíÆºZ[¸öxãwjíÇûÌ¥ÀPò4ZØš‡~çÉ(óï?Éçž:x½¿EÁ1^ö<@‰ˆ¶r«ã7ÛMø½›\üïÿëÿ%j)—r’)”n¸$¡ÊÜ¶ êÇ`$©&Qrƒ˜À~$¤À°G|Gßi¨˜–èx¶ò>H@:#[0Õ2Ç}øÔ!ÃºöN;9ØÙöFCJXÆAL„îPpâéL»NYo¸Òõb ŽIÑÆƒ¢0lÌj®ždžÌi;ÏfãÓ4CñŽ¢»õ=?E×;åÐ¤¤P%tk
ßÂì-ã¶^FoYnéí5ÔQg«A¾ŸaYª^„Ô9ŸÎ†Cëo‹S
ÔK)£ÀHÚÝÈ™ð¡iH¨¹„ßü2“`ÌÒÙ ÕÊÏ<eièÛ¼“a|6“BTrá$+V³¤ÎfˆkÀ´ˆÛq]‚Ø7ôéŠÍ’qè‰ã‹9õê‹ç¥Ô*°âã"µó÷¹z]‹ptÈÍÁËNK`W/ÀÏçì•Xò®ìÆÉì½z³÷¿ÿÏÿF…cÜNûïØŽÂ\ÄÁ(Ga>9ðÆ”Ã›ò¾ÑÓDŸ¿ C»j÷¦Y4íŸSÿ®àƒù{©{[ÇAØ¥{÷@A™Î&…í²q ƒ>C
6m°Ñ¹.Kf—NánârœÈO¸­-¬A„É‘•¿²È` k/ug}‹Eýð~Á@ÿã?þ‡¤´~ÿ
à6ÿ«­~‚Oúƒ<úYµgkëm¾R´]îL5Ïƒµõo›ëëÍõ‡'ë67þ¸ùø
}GÇ›x‹0&*^]?­Zk­KáyÐvö_¨M
@ÄÐZÎ*3±ã°î1Ö]]øòëœ¯“.ä§æùÅÏðßSõÝÛÝîÉ‹N¯ûügµž‚7bóÆÎ>ÌxË¼úSsl~{u°ç<Ï_oÃ÷­¿¾>”Ç;Z2Šæy¥…Ž>4gµJr×¥æ³¨¾ÜÅ|pr¯4Þ†Þ7Tü–A+¬©Íy®¶5¥i©=dqDtÂìŒ*^´X¥[ÐÕ²%dBuà¼ñ&@ßæÇesIõÎ&‚sÑÀœ‰¬¢aˆÞ½ýk½µ¬‹w.€ª.È5PÝ…]Ìº¬—ô9<økh«>¡
@Ñ}Rv0 \®§
9îÁØL£³‡T
T8_¶^Žwö+ŽÔÔ™ñd”4cèÊ_t\¯6ýP¯-ë±â\.éñ4ì¿›Mòª>ù§åÆÜ©O=vJt‹îÙ¬èÖü¸ô”WQ§%³f_tíq<Œ"Üõ¥}‰•þt
º›žŸÜTíéxRâq£ô™dx…3%DÏ)Ý
rXýFzü^D|üÅ¥Ÿ-x¯yúà&®y/1#,Í9‹ÍìÚ°Œoªß~€œûZÕâÇ¦Êxøâ¦:>¡qÓZ’h‡ @ú[W«è„7*å;”ZªJšˆ’³MÈZ¤6?ñ‚G¢–+%Œä"HŒK7ûÍµæú““õµÍÇ6×ßNYo­µÖ´Dr'½ßB~™ûò6fÒñt.ÂÑ,Ê¾ñ:×aQÖËtgØ¤J¹ÒæBH.«6ŸgÅ5XBsH÷s;»ßÏ±ÞÆcºèÝîñÖÉÖÁÑ’îÛäÄm6/6o ËÞ5l¼üîÒ÷<6áôiÈþR–Ÿú£&yƒý3Û{›iðM0èðè`ûõÖñÜõ×ûo 
ùÖ¢­Píáør}£µÑZo=l­ÝðË½àwø/7Âxpžµ°ýËàÝzë­µ“õ'!õ¶ŽvO^þÛ~óæÓÐ… …¯!q@†ÕµzìÂ×¶ÈÙnš1ÅœÃìPŒg·9ãÖÈ¸7;ÝÕo-;ŠUo•©Á't¼ü4U¿wƒsTýâÍÀÒùÞäô½ 1‚ ÄñÂ"°p“;§á)e)Ò_­#ïoö"Zµ°?y[½ˆÖÉv÷eçõîñ‰©ðt9Àî{*äI(<’G§}@nnÓPèá»QðHê'Ñ{´•ºOœ'lÌx¥Ûú%¹LA”·±Ö:ÿÇ¸Àû6ý‡ß=éƒGór¿ŸðµtÞcØýga‚Q|ÚàT¶,8â¡Ø?Gƒxè~§Ù¯} 0­û¤…bã	à®¦(=ËRWñ›÷	“+žð?'@Èz{­ÉÕH0¡òhü‡8âËQ~OóqKj×~×6Ë'…_ ¬‚òÐ/þ¬OkXZ8l3‰O°–D,ÄÄ£ˆ…tØ¿tL…©o|"{úÅ)¾êk@úi¹@æIe[ÔªBo¢ß±@´Š¤¬þ© H(Y-õÓ 9Âîí ²{ªð; ›<ys=ü¦ä¢4…A‡jQ›ÛpßY…h—%÷ÔÖyÔg—„b#±3×uŽøŸTmåƒnv])¢VS??¥´µ@)jÑb#”\®Û-ÝÖm¥T«ªü$H&êŸ§ªÖ=::8DftôtÐ˜*ßÆüf2`ïÊ!<cçD@ÿÅGÏj-åL¡½òA)|¶{°ÕÙ¥_Nö;Ø‰GMkØ¬><tÍ÷Á§C]Ì~ÍÜùúÁ³S|ÖÎÓq¤šùm!\)ãÁUo©v¯)4Smã,CÂpN€T©³õãX'
rçÓh"e?c+@úÞŽõKùg ­ZúO\´Ô_°­l
'¢¹E1¸1"üû”ÃÔóª¦9\åk øÜc({ž	†5:-úØ|ÒÑ¹íáY¥"ÉfU“Ã³4:×—œ’e¯3êÜ»‡74:&#\ëNÖ?§ùƒàÅ•±k<Ð.-4v¡7Ü¦¹c=×@Å–+1Œê,çKã¦RTl\®Ïw^Ärs{nªTè‹ØÅÂi7EÆUØÀ°/gŽSÕ3Ö¶0 †íxÜ,©6‹Ã00x+›ñs¦
ˆçÈÞa=B6æµ8¡›k4Ÿ;V;
Ût
·|“Ÿ±Ñµ¸¹kBÄHuçêÜÓ²q¶zu¼á"AkhnC±¼K!àÅ‰…•äc(ËˆöžÁõ’šcñ=³¥Ø—pYai{ZAð‘@¨Âç£ÚŽ˜´`[| ›åúX|‚-ùv!êDãÂ%†I× âªØµd·[(Ì	¢žz3¶¯P'ØZM}?s*[4!Q»
3—§¥‘ÊaÒBó¶·§R¡)ã;Hsòóè¼»Ý9¤ÇqÉðß½Þ®2õ¾²È†ú#âz"eÅªJ€ÂS]=ælÊfŽ^xÍ:È¢Ë†SÇ5˜ÉÝÖªcÒêë¿B?Þ„J)s±,
ú´ÔnjKÇ•¦íWŒ¹šÇWEþ‚µ³‹a,á©Å•à¬v¬úˆK´‡ñ¸›9úÓó0® W–ö~º«	°0âŽé3¶Í´?³.æðL<<FðAGÅí<MÔêyÝV.àÆ&‹±wL£çÔ~Š8Ë¢-zÑæ,“,båj•æV„]¹k-kgæVŸ> 	5öã±AªÁºnyœ¢Wó#3…mÇÞHõe€™~Y^µüÀPÍÆr´¢°4–žúÒK45n©=Ì¨áàì1gý&˜¶ÏTçà%¨²Žôr½§D$WÜ©T/è‰˜Swÿz£™qPw‡Ì×Ãpº ê£š­ÍmXÍî*™žZÐôv¸!tí:‘j¥?HOÍœ/øµèr«œu…™
™ð+Æ‰Í]Wù¤LÒÝ¯ŸÓµë<Ç¢&Z<åŠ¡!†Îí.DË¯ä*š·2ëÅƒ\8<Ý49Õ’‰UžÛðLK®¼‹,Ë—IED§ ý5’gHîvêÆ,ëN+Eb‘s¬pjÄ½bè	@ËÂ0qõV›•%Mž0nä¯¬÷µÀœ«7¾,Yê/^³vš»ÏÿÐZ€1Þh¸mó´ôNO"0P§Dù³®ôòÛtwzÄñÎŸµc+ÔŒÁÀvˆ—uã­´Æ{Š˜EgŒ
Žô•·ìx…,ø£øˆ«Ø e¢åtÂAæ×Ý¥yã¥Nµ“:EüvÀwîp;õVwŠmü®æª÷ƒº‚ã±´+}STÕü>©SAÝªwvéTøT¥R9ÞÝÞyIÈh³ƒi_øôá9‘›Ïmî² 4¨A8· œ/Ü©òTéÆ`òû:aýÂúÛ÷AÉg}^Øh=ä!Tºˆ+ç]å5~ô¨ðÎ_àw&ª:„ÊÐ=/ˆ€¦ŸÒDc—£TÄ”•G6‡£xª¿ÇjáKö•m•¸°ˆÕJ¬_SOú)`û`¯³³_±ÆO_{'#˜ÿù¨Å`ýõ-’©jê‰µÅPA½ŒããsFs~
´½qj¢³£ûyå5h;Uc€Žæ1ï§ªá¶á‰G>jûÐüXÉbç•lœ;-ï(¹#Šï¦7ë™”–7VA1’þi„é{rKx‚µ5±FUf¥’¤Të<‚»‘óo'³;SÍ~h«ûêŒ¡™7 NvwzÇ>€Ý˜•+?Øu¾ežÌÀøòqç:üaûäåÎn•Ls¨/7ªª> žºòAË×mÇ'—ƒÖô=ÜFú1÷pt\ê›û÷z"Ó—3	±¼ÑÐ ÏZÈÚÔ–ƒ;ê.WÑ·(ò– 5¶¾EÀd«VNÚº>èâNI9WVÝñ¤xšrî¯R˜œˆ­É„ã8©:úØpë6ßœ-	T‰/{6ÂYZN¦Ø£Ð¯?àW
lÇ4ÈçˆŠ~ãE·WÂœ§ùWG‘·ÙÃÇ`³êu'°.žqŒ67¹üÄ{É·òs–ÕY‹	±J‰‡{N¡m6º•È(Ì±L¿Ôj¡2(.ó$dåb$è<£/·c'SßiJñÜ8Ö-Åß…$ÛU­«ì’ê~:jq‰\NÃ°j‰¨3ü6~€P¨ds¨«Uû”ƒî% E„Vš1htC Q–a‘cs
(þíf0%×«XÀ€@são7í¢¡3èwýÎúìè„ð,jâcI´Çƒ(j8&ž›ÀÏæ¬‚Ÿ!XrÇ‚œËi5xÅy‰yî>ˆ/ât.Dü-D‰ÈÑKA?šŒÞ*€Û2$'ëWç9HÝ-¬s%ôÍ¡UÚ€ úå,áÂ^ä†“/¥îþ¿ÿÇð%äú¦Dºäµ+i -'-,|·ÛÝÿþøÕs™>ýv9€¿¾7H™ÆX8$9ûÿÛûÖõ¶qdÁß«ïË;à(™q’±$Þ)¹G}Æ±´§ØkÙI_ÒŸ/ ¬D5"åÄžÎ>ËþØÇØ_{^l« )ÊòEVœn¢g
·B¡
¨'Ãi&UaáF wóDì'—ZQâ4y…§ã±°M2…÷_ì¢"…Á›ÒQ?>Íb'ˆ…ÃÍd0òRêu4ÃE\ÿÿú¯ÿÊ¶"h
igÍe ùôÄ'üFñ„½ZJkðÿþw?<M~}EïÞ²Ö†¬­Íh«ŒÏÍ´þŽ8‹~ýqŠåðñLê]Yœ63¡/,Ì3’óé*&–³ù½×„KˆÂ“Ð›\ öØçÇÏ±Âóíýwož³«Ýá`tëT¶á²~•ÀÄŠÌ³=ótÆc¥$){J*xšþ–lfáì‡?>i¸5Gz)¼´É;OòJ‚6…,†kö:•½Ÿáä_ÊÚsœ–^Ç’R‚

TFW´NöLÆke¯fƒœlÀ˜Œ²6±ˆ¼atƒ÷Î™%væX?CÖ¦¸”d\”dšç!T§¹ˆ>)Öì IqŠŸ"½	ñ¾{Í¤ùÒ<KÐ¶9×ütÜbn2|.>ä§š*)&tšÀ4àÓß·wÕïÙ?ZB¯DÐé Wa`0ò) âk„°øÉÈÔàNJTäFŽ¹²v‹==Ãž¥Â]Ù^m’M®„vÀ¦‰Ð‘K§ZR²@t.UÝ(B+¡ÔÉÎP¦±çNûÈG 4|N<E×Ð‚F˜Ëþå>“èf©WŒ¤”ãB~}ÿNÝ5|Ç(_¨XŽ†qOÑN´Ñj!J6û¬ì¨³cáœm1MV+j=Û¨Õž“_w½|žA‘ „ôtÇvb(ÒâEŸaõhê¢Ç ô¹ÈroP¿•ž±‰K\¤%åÄ“Î@Š˜ùË»Â£Ò¹ÞTšiè˜ÐeêZym©7½˜»Y‹æ¹pÊœ}m·/iB¥ý¦`«î««ýÿ(Š¡j©ÿÓ6ÑÿfØ•ÿŸU¤Z*àRNcÎñA#×ØsÏj×»„(OEõÎ¶gÚ¿L§!ñ”9ÁÎy?âÜ¥Rw¾öJ|Äö¿˜ñftêÜGö¿¥+ºäÿKÃýo›fµÿW‘Ú
uLXž¶ç::ÕqŸTÕÛ®¯èÏÖ}ßTUß×É6[³öc¶K;TíXmß×L·mª¦N}Ýjk~`ZÇ,ÅVLW‘kg¶f†îÔ2G7M×0»m¨VÛi«FÛµKqu­ã*•kgviª´Í1ÚªéXm×këž¥›ÚvM‡Q9ŽgHµ…}u¨¢uTOÃîiºèVÇõ]
ƒð=ÛOWÛ¾Éj–u×óÛÔt<·ãºŠ×Q(`¬E-³­ZzûÉâ“V´vÓ¨£x€ôßo[AÇq
½Ôl#ÐÛj[ó:m•jªª—-ãÍ±‚@õWñuÏ´ÃóMÇ0-ÓUu³í9žiÀ’@ é»¶êØ¦ç¹¾am30|×u\Gk[Ž¦i¾æjŽm)Rµ¢Å]ÛSUUsÚ Þ1UXhÇVÚÔï(ºÛétª«FG3Öò"{2WU]èÙö½NÐ±a6¡¦	akn[<ÅÑËRÍ<¬r“8SÓ,Ói¾hmS1ªmÝñ´¶3dY
|öÛ¾=kfm=ð<%p=ÍóuC7)t³í(†mÙ®Ò¶©£*~ c”l‰G@Ít|˜bS³ÚQ ,Àµ-ßÐÇR5-p,w^‡x_LÚña$`´åw:º¨†éš0õ 0Íì¨ŠH[E²ý3=Ó„­LŒ	¨¸®§;Õ=GSÚ®¥z¶¸†6rn‰{3ÀnŠ…3 ŠøèÂ›Ì,‘îQW§¾m;ãÂfÒÝ÷4Øa¥ÀfM Û†b®3«Ø@Ã «½Ž¯¦jx6ÇÑôÀñŠ}“L7µ¶¦˜:œhgj¶ã0jÂOC1Û¶Gñvavòv§. ±cj†¢k:¥:ôÈ u*üÕQ:–f+Ì¸SØcyËÒè¬æÀÚªmP×é´]·Ó¶TXxªÁ2¹6¶ hõ¨q%œšµTè”j
ŽFó[…!µ5ÕU`8¶a;Eä)@Aæ¢fz˜†ÍS[w:†§ÚHeu€O¯—êèŠ[œ\fR«¨'Âª6[´S G¶îÂú ¶a 
ì¶@7UWƒ½¢¶m-í”ƒ4“0ŒOÐ ‚¦Ž	„ˆp¢*ªŽ'‹ç‰ÃõmÍvuÏÓÔr¨
#q'²'>è©ÙqÜ6µM­ã©†í»†Õ±vÇT;ª…'¯ëjAGñ½r˜ÚIê?'7~J-¥äRÑ4–Äé¸*œÛŽM=à·`P8ã<Ë¦7€Êf@u:A[ïíXžoWÐÁVwÇÕÇóÚ¾êPsÎ¼ê'ü"ï"OÂ À»0vÞ<Àc“@ÏOG2¢™ÀöypRËQ5¤ŠY
VSO¸YÉpp‰wÀQ¬2[GO1-`<¨áh`TpµÓ8@T€j+P§À)‡©ajÓwô0CÔ¤–k ™"ã4è µSÛÅ	ü6ð57>›Wêµ¯í9ÔL8§Ú¶Ç»ü†ªY¶áy:çRÀª~"= §Æz¬³`´}Ç¯8T×©Önk¦íÃ®5,×Ššb]{# ¥¿x
²¹è¾åjvÛn+Çð8RUß*äHõgˆ!ŸY½8³¬Ÿª®ÛŽ‡t@÷ËvT
[Àò5‹ËÔé@;pjw,»¦è$?ùÇ5'°LhˆæíÐ<j1vUmA' ÖÚp€tËÑIÕJg“­?€S &œø†‡L¤
ÀÖ¾L³`ÿv,·|[©Ê	÷P(ÃG¨À¶©´-Ï´´(Ô`»vð$„Ì„iº¢:Æµ×ˆ€:ð‘^ÇT±6ì09ï¶ÓÑO¤ æG›G¬JI çô,Í &v¹é:”Šâù ˜Àû ß¢VÛVGateÈ½Ý­7½šîÃ\ßqpt0`ÀÚ8H©§'b& ¿¯ºI=ÉaP`j E4Ø€^A›zpÀ¸l782àx§ 1´“šÉ­ÕŸTp_RB^è¾Û@¹ß4çßÿ¡¼,äEÓuÿa¿üoÞwÇ0ýÉåÿ2hÙm,¸ÿ1tEÅõ¹Á0@¾„õ7l]¯îV‘_S‘lñýéc’:ßÄÀ‡è²·y-ö8õWÒPO_l÷žAžCûèE:Š'NQ¢uÖ	°ˆy'UìN¦ýþ:é}Ä—t‚NákËì0ª‰6yÚ˜1–…ï›,>ŒøÞ‹i€Öìœ<iôP@^“ß‹ÿ#ãÇ»r¨½ãâòÚðq…£¤it‡ÑTô¦Ú†/,€0òø…uó`:Áxž¼,³”VÎ²n"'„³=)fsFlxï¢™e¹Ñ1ÂÉ%®jÃ`ßXø` …ÅµôŽ÷éÕÁ^Co*[ê"¾ÆXêcè(‚bT½˜GNÆÁ<dÆPø…YŒÍ	ÚÂß¢¥v°‘x·+¸ù¹¤Ç$1yQçžùÔÏlHégd:ÜÊ-qêÏÌüò3hÂ¡¼ˆE˜Å´!»èbB¹þ‚/\ºŠGõóLg<à‘^ ‡¸ô†5q¹œ»Øhò6’7ïá„Y|Áç‹ˆºíû’’„Ô2‹ŸÃà±pgNŸë9îíl÷Žö_ïþ²É#Œ>æ¥’`|y«àÜœ°‚³NF…ö6/ì7sVë9¿¢›AsÆÂS‚‰:šW”:”ËÛc
`(oÀ=å&|}Ágn”BË;ô”º–Sg-íß¬q†4`ÙÎF‚*jÃŽ¥U‘Ìfn 0?‰’h´äoóV ±.ƒ7kC%ÁC‹)¦SÃŠÎº’•älõ
mæ}5 cJ„7ëV†‡œžW0R¹,z®|Ì o‡ŒFÍagt³ðì.M¢XåiKÄc…6—JEÿ^ºÁ¿¯¤¿»¥Â“Ã½´q5ÿ¯ªš‘Å2-½ÿÿ¿’´´-úJ ód€‡Ìþç˜½Ž?kLÁ”Y|J–EŽ>Ï%:‡»Ò	>+H&#¸8ƒQ¢jYô“D[nEàS%3Ü¢ìÌí»-9âÌ¬6oÒ
n¯‹Qì|æsùvó°û=O-q2¹:9è©Ýµ÷Ó¼?Ýxÿ©E~åî
ÖòËod-)éù§]øš±M_²/N7_ÛyIÜ®ä1ËŠlfìñå:-ÜbS¯X€»:Ì,¥²§¥e¥ÃùÀÐ’7+ºY—=rŠŸ„‹oQ Nò®¤–œdxÈNXÍ4›Mâî›ùÝr3ÈXbkÿÍËëN_‰W×²$+lï¦Ë›
_„µ
(%Øù‰YÎ Ìßg  NÆ¸¢bô˜^¢?É:ZÀçüæ	L¼T6—éF¦Ÿ·ßT…Ê	ùç‹ËîûµÁ<œ'£µ¥ÒAOXÎX3¢0™Èt5f›ÁªÒ	d&Ó_j Ü„"5V2(zÃÍ®žê5?Ñšðþ™7Jí®y>‘÷ðwÿ&Ñ©MÏHÃ#E%E¢}ßòéyk4ï£á]ãœÔ7Èþõßñ\ªG­òrswogûI«•æ=\òýjg»UÿŽ0¿¡MÒ`á”òþ)ùÒ0#ºÜZ¼FãÉ`+¿v&}Xg%íÝXtàåçó`¶£¿{p6üÿ$@“»±¹½Í;ñå÷‘¬1…~ÀyÿQ]WEø+P™a!LÁe@J;¹3I¼ÈÅýKÒ8œüNxm.çóZ´©Æ/×¸öáýõ`×Éw°J’MþšXL¤ÜÙ
¨·TÈ[Š·š=MJJÔ;û:(T ¼¤P‘hIåOç–—
¯Š¤-+Í<(±
²ÿ^¤­u¹’î™B™+„„|¦dÊ…ä|I_C7?§…é’§4÷É w©Mv£‘›vM€A&#•²mv£O€¸n‡ð+Øß~CêÞ¨›9¢yÍÌX'uñ=ñ”ÀxÚÔª;ëÄ$Â^”˜p7ì<ÞMÂ¯‰Œ<Àä`DÏ	ø4Ï¼'HƒAWÆ½#æNûêá$=’-=tÓÙî‡€L›ÅôÛ˜b‡RšÉM<ñKf™|X‰YX’5lv×†|j>‡Îyá0œti¦ºk{èøjooóh§»E°°3$¿36-T^ÊM¿g8—žzé‡Þ…a<I³"žUÖŸh(ŠãÌ>gfÍh"=ñ')F| |a×2?ÑÓ1ÿ0g™ÅœØ”˜]XS¹z—¶¸)zVÞ¬:3:—ªNÝ€„Ê”èf02+u	ÄÇîZÎDü+mYÖøôìëv>BÎœÉEÒ­Äz$Eò÷,‘M¾#^ždÞÁ>»kçƒš¾õ5~)½ÿòîkuË{_©\Í{¹m,ÐÿÐlÓHõ?,õ?LÝPªûßU¤êþ·LD2xø¯e'	ÕmðbxÐ·Áßæuðµ®¿Æõ!¹Ë\?ægc‰ƒ¿› ‚=ÃZ’‹,f´4.ªŒþg–Y÷wÆ,²ÿ×+Óÿ…‚ŠªÙVõþ»’ô˜‘{)¸žêFÞ¥*ž‘˜¯ñ|\™`žžåõÒLƒgn²ë˜$Óä™‡ÒNòÉÚ3Ù5È ô:ÙßÅÛ½ÔsÍÍwì×žå‡›Ê+—ÛÆ"þßøÅ@ýÃR¬jÿ¯"Uúßï_4/~˜¼ÿðrV½Ò ¯ø÷uöÇ”ß/ÿü­'Ÿ}ßm\ÓþÏÔlC·tíÿ,E¯ìÿV‘2›àûkãæë¯+šR­ÿ*RÁKÏ½´q‹õ·u«ZÿU¤¼WœûiãëoÚý_IšqctmÜ|ý­:ÿW“æx¡ZjîTEµëo•ÿÇÕ¤Çy#]”–Oôi(Ú‘O‚4rÂ  ¿âÃÆÿâ3ñÈoßañQí4³ÌZ0@PÇW­ö˜jµü8ˆ@qæ106´ÝŸ8gQ­v°yôC÷	þÜxÂB]5¹)¢;‰ön”Ø@9¦Ä}J½™•-_à0ë©M3ï·¬;Y']R¯§½'$YUñ&«.—"¤YV¾ÐaDY®{»sx¸ˆ/µ‰‰5ëSiM˜,>_‰OâÃž¯A¦WT¯Ng'S´®#œ(œNxÜ/yÒk+Wz6¶Tî³o¹m\÷ü7TSµUé¿¦UüÿJÒŒO°{hãúëo(ðãÿŒÊÿÓJÒõ<mÞ­üð|z²þè­Ž(š¢é•ÿÿ•¤ÇÿÁ8 äÚ-ïÒýÑm^Ýâ9pÉ}Î=–î„Gw{|tå«à£ùÏ‚fßyôur9=#t}éˆø"r Wæ¸|T|%äpnø¬÷hÞ»Þ’×C~Ù{´¬§½¥ö‘âFŽP’sn%‹§þ`Â’”gs¼	×“f…ùfÚð-ÇÀå	4a¬`1Ë}=mÔ“*3Jmd£TÕ-­0(+$¹Y¹Ä+_s%X3Ao,ÈÍ—ÉÇŠMÊ`n¡\.îmZŽÛ0¦%·w_o¾)¶Ês³R(`mÏ”â¹_Øòå-q_áÿEøý#
Šø5Y‘dUŸ§NXOŠ£“X”½Ñf&ë]ñkÎb¦.¯CR²`÷%ÉúÎø€Yìð	—ó#é›åä#3ÊÛ
G#¦ç%—âsœ”Cƒ“—NXÀG-„Q;^ä%Y{tôýõ·è$ÆëDfQˆ[IMG¨ëðáü¬‘¨OˆïÂIóQ£ù¥Fac<	ÏÆRÆÁ$cs4Â9L¶åR›­F¿¶[ô;´±€ÿ³u=õÿ©é¦…üŸmWö+IË—cùæ ÿCæú~™F/‡#B·ÑcB‚)üðt.ã·íDdo{÷%ðN¦æòYîž<*j‡9Ó –oÐQ“¼ ø¿ïLòÑ8Ö„3àgÎhŠfg@pù ¤äø 	ŠT\éú¸ä7Ð6o“ÙŽ9/häÂ¦u§À’ÍÑöðˆPÜð d9:à)6æÂãrÌwk7º„rìÕ ' Æ3Øçk$ð„A<¤ü¶šŸ|¢ƒÐ¨¬tb
ˆá š7vG>ýL0fôYHûØÑ95öB'€>‡…:šPŒ+]¨µ´iöGÄu“Y^‡ßq7o¿‰ðw®´ù¨º€Ú­Ü T¢ñþ¤ â^8*|—eÆá¸ãG/è3ž°á¸Ï%ÂIß	ßŽÎ0ik*1äß½Þ›¦ª}9:xûéo½óéÀ÷ŽÿuÙ(8RÇÃwO¯üŸ÷ûj{ü±uúñÓù//ûþæO?ìïœî¾ýx¸çüÏáÎ¹óv¨L¶^]^~ú±u0™†õ¶7¿zÑúeÇ¡ÓÁÞÛG5o´!¡b”ûK&q{I™ax£0³¬ØÈó ±¶üíA®‚"Ž8Â
q9kÃðc|:	§ýÓü=ˆ7ˆ'|V \Òü—þàœŽÞ0¸èÁVk²…<fS+XÄ‘ŸÛS·B£{ÚçØÏj£/¬5Š/§}VþRÞi<èÃ1g¼Á|ù$bš,Ð7J#~üéÃnKÝõzüúo?¾ûéúiúãgêöíþüóÏñ¥ýËÈþplïœíþ0üéÝ?7ßþÏQôéÃßþ©Žhg¯ýéÕÁÇÏöáEçÅ›Ö/ãÍÖëVïëì_‡?¾iÿK;T8˜fhåÿ¼’JäËÍÙàiƒDŽs ‹tEÊÏÀK4`/ËKðUm 3æ_YàÓöDy	t¶EaŒÜéÖÕe&™—y€.Ð7MÃñ†sº‚Û}Øá¥ËË [êFt1òæ| «!¼$ÀÊ‹}8û8Húó¿ÏŸ2üzÅ|!ÏßàZWà|ky3ä/æNTâág›Î‘ep±¼¿Û`«æÌëŒ(NcŒÅ^Z¨üœÅÃ¥7Xž9ÅÓ,EõÛ¼oñöäÛO×`w§6Üÿ˜ª•Úÿ©ŠÆÞÿ[«îV‘ª÷?¹ÏùË Òðu®‚4å:WAXuÀÞÿàP¹ŒÅëŸ¸ J\œr>÷ø¬O‘§oÎ^Ç¼šLG~ÊÙcðƒÞÂ0<‡}Œ2J®‰œi>1Î@b^&³–^õÆU Èç…ŽMñ0ä—>¹ªêèN}D‹¿_ÜÉî¡$[°(ÇL\ÜŸq$nSg¢ÃÉ„~ŒIŸ2Üƒ)àà)“ðŠ°ýÍ^¥k¢,¶»õk’w&?qì@9qï#†rP(£€…xÇ€$•¶ÕÆDòm:BˆèÚíV‹×I„žÕr(Œ ’éñÀ9—|>OvOs¹+’¸FÉ¼ovë­p‹P1õ™"ø®×­|>ƒ¼àO½1^ÕšZSm~Ëu¥—A¼òðýòoüÑ­Ô£tÑQò ¥ÝKÁ€œ0ÏšR?“ÇÆrßÌ¥Ðô‰^;%éãa×€”ÿÐUõv§P¶×Ûëª–n²wºí+-¸Ù0¸ãîI¸Ù­»„|Ê€‰Þöö_½Û<Ü).[1F´ig8Ñš©u‚±i jò÷—Æ£))÷òõ»\±àìSI©£·Û¹Rñ¹ßJ†ºÙÍH]
¿GwË½9¦¥`Q°”E&îŠöTBzóåúê‰|•VüqççÞÑþáÎQîÃÇhÄÁ¬_£ùšc©÷ov·~Ä}Ð­'¿eÃE¨uø‘Žé‡0Š³Æñù½ûäiú /y›$¿ÿÎ´ž$ZÏðì}Ì `ÙµË”+Ôz.Wã¹Z>Wç¹z]–ó`gÜ§+Ñì!¥k¿Cä?ÃÌä?øa°÷«Òÿ\Iªä?¹ÏyùoÎNxÈÊ B*þûÿòW˜Íi¿ŸN[–eÁNì•<æÿ˜‹ˆ7}ƒR½ÑÌÐ¡~œ½ò3_3å³†÷¥³ÍM™eŒ›É„$õ1ÿ#È°¸a„‚ÂlµùaË¡®3ŒÄè nSˆ.C&aÎBŠ˜€›i-0=\.é«³©r@%‰Þ²_IC1’1{PDÔ ðõCÇ:GÇîb9Ÿd1I9÷„¡ov_Í……xWçäx¼å°„Þn‚½wQÝMõvS`<ÕÝ%ªä&ø/•äfå²Õ–Ëe¹\}——Ýô}ÁsŸˆ=ö*RgÚ½sÝž¶PI–?-R³—¨Ø&®ðgÕzgœà—ªô
¥VìºÈAtåæóó‘G°Üƒþ¢!¦”üú,*ßq˜3ÊºçtâÂ1™ü™H•ŽáÈ@p‰†uqÅÿ OS×äÿï¤¼€ÿ×TÃÌøùU³*ûÿ•¤Šÿ—û|þÿ¡«ó3ˆì)dü‹ªÀä£ÌæßX1xŽXT©#ì¸PtJT8x#ètyƒp¶dÉÇÝÃ:ðª”K³ç¿~Â7Ý	êiÓ¨;] .´ÿ6”ìü×QÿCUÕêþo%©:ÿå>Ïÿòð°éñ^“¡ãuìÉ›)?þ8ªÆã8Ç:HWvøÀŸ€OT!Ç÷püÓ˜äÌD“lŽàðâÍ@ã\†ÔÄ'8?…º@.õ¹Š#«û¸»ô±º»ßû¸}±%hðixàŠû»›»îÝÖb³t^®ûþÊ/ºÿAÂÑð£"LJ:'œ ,!“ÔÞN}úb]bw4IÏ³K¦Â¾»Í´ý™eDj˜>’Ë¢²;®R–; ˆ1CwE3üŸ¦žˆpƒKŒ[Åê=ëÿêvfÿ­Úš‚ï¿zeÿ½š$ñË;dnÃýÝ‚ù[j‡s¬ŸªHÑyOßg;Ak²YzˆAA$ß?éöj»ÀK±˜KÙ`
ìÞÍ9©yŒÔRWFK~àœvQƒÔ&ÎœY°S	0‹lIðÞ%6¾<öèÚÜ‘ˆQ1BÕÂ\|¬[t_8å°ähés˜Ž›ò×|¼Æk TD%E¦„åæÊh¥e´¬GW<*^ûMQ.x¸s0sÓbW¿<^‹éª‰RÙ™›[4d3?8¸Š|º‚IxÆ×ê‹žâdxR3ïkü]®Ç}År`âM.É“&,)¾RØ`$PŠw†×É}(T.}$>5áè˜µú®ëYOœ]õ¼WËÏžùfÝñÔn21<ä<iœ&ÉK:¼ì¯<bö,ÿ§ù?m¥üŸªsþÏ¨ø¿U¤Šÿ®ø¿ŠÿcWü_Åÿ=pþO“ø?u™üŸzþOû#òêŸ–ÿ›óþ{°üã—rñ_4 Tñ«H3ë¯ê¥¬~!`‘ÿÅÌôÿpî`ýu£âÿW’*þ_t8ÏÿÏßŸÿO¼£Í°þÌYºn;›‰ñœwåö&ôé·!'|¡Ÿ+YâÁÉziý"KÐÙËË’ô@ba8®×oÄ/‹6©@ÍËjsæÖ* 0P½ÄŽC-á›Ù¥‹èŸ ­•‚Ö®­•€–s õ
Æ{Ó	•vZVG»ºŽV.ú”Ê©<t… q1â2¥þdJ½’)¿a™²JßNºVü‡û}ÿ±3‹ÿ¥éÌÿƒaUòÿJR¥ÿ-÷ya0ˆoKù;l’9!¿¡K‡9Q1nëÐ¡Þ¨k¸s(õÞ0¨ÔC¥A~‡>Väò$q$Çc<œô%0¨Œ×;9ØìõÞínI‚I?ªñ6€š„å ðû§Sl˜=úñCž‡)ê>y
|&anÀ¦Ü]gäw(H¾Gê›_œÆ¥ÒèÔ!3‡>i|"ªœRX·Æˆ¨Ï2`Ø×_¡§#Oú”´É_ÿ
ëÕI·Kžÿ
À~{žÏàÅ,h²Èo¹á¥»ËÂ|h@€L’×l_c¨q]qOé~O ^¾ª´âc–…a¶¯€ísØp{þ:ì¢$dØ`Ô‡-&µøï~8pÀwÜ/uþ¶ÏÜ=’ãÛæ’=N¹éJ%áC¶ÅfàpOÛ	¶™Øú÷|¡a#ÅÈãÞÎá2§Úf:V‹êË–l%™‹»¤Z¬ ¢<0æ
?k*`Áìx#¸½¿/^ß]ÇIç=˜Ö Ó’,Â¬Ñ7åñæáz³Y¾»š%{sõÆ(žs|·ÜÄ¥Må¶æ–©²âÿC¦Yý_½¨ÿ{—§–n¤ÿËã¿Wú¿+JÕû¿èp¥ÿûÞõ+ýßêÍþOõf_½ÕVoµBÿWÜÌ±Îšã‹eð‹ø?Ã´RþÏÒ¢¨¶®èÿ·Š´¬s³ÈòíŽ`â ï½/xtŸ]°ó}Mn¯Èì	ŒºÐ{¿ZÏnªZS1
Þî.Eg	ë,ÙÏœÁ7ÂÑ=hMÍ7y a„$Ø§ÌYÌõ'j>›óÆÒ±Ô…ZMQ¶Ù§ñÓµíý×›»oXÄ£µuRg¤ô„×«?K ŒñÂæj x^!€ÖTQ[¼ZÔúKT'!R/žÕØ	tÂ@Œâ§E¨â‚N4j+ŠZ–TŽ¢aRÿªÊ½ÞžT_Ëê³ÙyÃÉîº±â'êÂÒ¼zÚqŒô•Ô­çŸ€?ª'Ø¡5Žìlë
.ê×¿D¿­&ã»BñƒdšgŠãdÅùeûA:‡Yñlv‹¥ñJ’×(–Ó™U8Îæ§<Î_V:}ÊšSgJª
rðn¯—žÃèÏyÊÇ»
N'jiÖsïi<%ë”Í	¯–ÍÇUµSd„ÌÍËUq¦ÞH›+›ŸEµ²YëÎÌÓ’¸ª¯}Z/?ÍÚÿÌ¿ú¸m7±ÿQu•ÛÿTþ?W’ªû?Ñá?Îý_eÿó@¸Êê.ñ¡Þ%þ±}	ÜÊþG{àö?‰›Êþç~ì*ŸÕò¢óàk3«UZzš•ÿ”NÛeø~ã¿ÚfÿAYã¿êÕýÿJR%ÿ‰çå¿9›àþ[ÁÆ Æ¡5Nr8GeïR©„¼+…¼I%äý	…¼’C”š–|&z13LÐKgàN’^1•õršÐ9q/Sƒ¾‘À'ú™‰|å-hZ(Ê}s¿ln"ú]]+'üÉ¡*r,ÿ¿9Ïÿå+€@Ä™n)÷5 ŒàTÂqÉ¢%¶¢È–MÇÃÚæfn¿¿9ÑíZöÿhqs!ÿ¯Hñ_5•ñÿvÅÿ¯$U&ÿ‹Lþù²Ñ?·ŽG ƒ,Òër„×ÌúÿMq10ÛŒ¡|jýT0+šu á°OGS.×üÍã´’Á™èpïc·Ñø2nÎšçKae³~Ÿú;.³Æ„¿¹ÿ¨ÄŒÎòÌ$§àòýáLE–@Ì½Q7³×äjk ë ~ÂÁ6~Bûé90`œþ0taÃ“gÉüxnÃÀ@Äùë!m$Zs !t?@O<œ˜†KOóA8Ùp<ŽãÊƒÁú¸ä7Èæö6Yf‡?æ¼  …Qs§ 2ÁæÄ@ˆ¸åwV‚ÊÌ#GŠã€þ½©O`Æl¯øtHÑ+  =úÕ€ï>yœM)Û,¸Ù_ x§1 LÔˆlní­E°ãÜŸ@i™/Û”K6":¢" & z<	‡X)H')ª#7ä±o°Q
‡mŸÆ¢B÷}]mjÍ¶¡4UU7M«©6f[1ß×Ÿaý§Âºƒ ’~G˜Ìú6†cúWìÄ <J'§î§NLšh…ð^¾¯‡Œnøé)PxŸÁGúî hã
[§›?¶¿³rÛo"üof ò¬¾LüÉÐ;SáÏ×ÀŸtæ—‚@)´Åô ,sgùÿÒðîw’ úÿ2´Œÿ·1þ‹ªÙVÅÿ¯"Uü!äóäÈ@8ù’ÀùÀÉxä^ôÿ‡Ì÷Ïeû¯Íõß†é¯xþÕóü¯ÁüFÂG^_õÑæsŽäÊULí,Ã/è+hczÎ/Oy›£1ÇfäÖöÙR²w¸ÍÈ;É[:‰BÛlà¶nÒæÍû2O¼ ŽèÒŒÎáÀo8¢×ÐîÅ(v>—·“ó6wÆBRW_¬¼ñÄÃPƒw-×®Èân[
P|¥.w’ñb ‚6`; ­ñSðÑúKã;ûh!!¤¥.Ž„w§pRèXšŸë[–Ë»wÈ¡¥½{•|O;ˆŒk
Ðyâx1p¶ÐÖF4¦ÞÀn4Nþò\OZœo…g8>u6ŒõÑôpÆÛÐ×“šÚúì7‘Ãý†Niqîø‘0Ž8¤#.@$×A„ÕHq}J—æ !Œœ!<®Z C&œž=:êÇ§èJï}Zù=y›”(­Ÿ¢áÆT¶óŠ
@Ù Ø o€EÏèF½‡Oâ>éý°ÙPs„ýû1œÆ_ì…%*û … ¦ öÍtoè³xˆ=kÈ+ŽŒá¡\ööP6¬>Ý°mÛ~ñÊ6éçñ@lÔÁ°¦sÃ*Ô)´Ü˜ÐMá<Ùj:ã"›Þ¥›ï£ù(ƒðÂÔ­êˆÕ÷*ŒºFÝ?²ðõ“ú‚Èç‰û Ojà9ŠôåcÝ¼ÚÝ‘?¸¤Ÿáƒ@v„6|:ìÓÏ‚]j4@G™c	N¦“¯ü˜‚òøbL7`°àñÅ¼ï€ÞrMó¾GSŽV8cÓ˜Í‰—fò¬GGó{>À=<aÃ Û/,0™“üèhº¥ÃãàÞ1û:Ãa£¯[—óÌ—ÍM¼úïÿ“Ü¼“Vãa\.TéÁ§ìþøñI£ê·˜ÉòÒÚXpÿ£ÙvâÿÝäþ¿TKWµêþg©ÒùL.7 ç¨zç^²3INjã^©Q„F7¨;™†`ñÚFxÔª;oØAfD"9chq™?j±÷î,éfÔâ/Møý&µ¤Œ†?pú£0ŠÞ Ü´ªìš‚Õý7wÇ<%è­¼:Ü?>`9^8¾ ^päŠŒ3d©"î£œÒÃöëÙ Â›Šð#û‹£m×æŸœÏðE]Sy]ûR»í<yÀâ|ˆqÓán¿îíœÃ9iœÂ®Ê#Y5(~»ñ2_ÒMÿ,j"óè•``ÚÎÂQËw[À	»ó}»Ýz\±|Ø0ú?÷ü_â³àüWmUKÏË¶áü7mÓ¬ÎÿU¤¥QKA3+. ân8ÿœØÛu‚
Ë8''®ã}œŽiÎåÓÏˆÏ³ù\™x&ŸŽÎ÷EÔÜ”¨¹¢|z~»ý?—þãò/‰Æ,¤ÿŠ‘É*úÿ³à ¨èÿ*R%ÿU”¿¢üåücS~ždý/@Àe³þ,- ÿº¢1ÿ¯–ªê–aáýŸa+•ÿ¯•¤ojKt{vÔ‡Ð%/+:}¯tz™øU	¦Ã!á$Ÿ„3œLGø<˜h.q Ð°BÔyÿ¡a3;Ð^‘h¡(@Ñ)iÄäåñÞiœ!òÿ#œ8€
Mï”|Ï‚Ž°ïÚ÷UkKßÀÄFÞ„½[:«›Ÿlv”um]_7ÖÍuëzó´ûfëpçõÎ›£Í¯3]œ;XÉi›¢çs'Fp*81‹fâkŸJUZUÊø?æ÷i	ÏÿwÔ¾”6ñV*ÿ†eèÿ_µ«÷ß•¤{“ÿp  ì+òdÎGn´¿’¡\Ïó’Ä‰Iœuò¯tšŠÝ$EžQm*E¦ñxü“,Ù÷^OÝ¨ÌÁ$&€£èÇ™8Å FŽÁ¼‚YÌÒpsþç„6dÝqD£>-ðNæÃ©æ ÍÄVºõä)ëé³&Ùô?ÀdPë¤?	£€ÅÎCñS(Ìm¾Kd,™C2ˆ›µÇ¹ÒÌŽ2ŒüËc5oä¾GS?$ÞxvÙIkMZÃÛÃÿ¶
ß+>¯YÒ@éò°¬0U+‡£÷©ãÅ€Sñõ[ñEõEÍô€ÞÅ2TræŒ¦ÎðJà«´t8¾9ä°d%àJºqk¿"ýø­¶M9âCC]ÀéÈ®`<kïœQuG4þN>6¹Mem3ˆé¤˜Ij¿
’ý[íèbL»Ñ ˆ­¡ª.ÚÊÖ^áŽe¿½ƒj°!ÓßyØ®í|¦Ã¿Ùo-†bï¨»‡þüÑ×/ŽKÊ"K‹ˆ#?œÑp÷¨×Õ¥ÍŒ|gâïOãñ4îÂÁJüÍGQÝO¾îL&á¤øÆ,HÈol¦¨ÿâ¢{6Æ¦“›LÍ"ª@žÿã”'àê]¾Hi‘ÿÍ63þÏ@þÏ²ÍÊþs%©zÿ‘îs¸ÿ@/ñQØ&ˆç Îžy=ÆÆ±/ÂO×ð‚ ÕŠ²ˆìÀeL'é}Äp(Ž¥ ›xÁÏÓ?Ë	Üš2+±%_J¦Œ¨D&<\ÞÖG#‡ö¶Ñ'rN­º Ì&0<£Yh*¼lBýÿ¸	7d‚ò`Ð¢Óp:ôÉ(Œ&#Šú‹ÎäêÆkÌ&jª¡¯Ž±1äë’¶r8'ž¶¢SBûM˜eÒD—²'ãIˆ8ØämÒ<²q&…ô9ß`éàZÐ9çÎ`È”ZFã»;}Âüºííl÷Žö_ïþ²y´»ÿ¤^ê Œ¢#bè›Vpÿpsko‡]š%r†í!û™‰#ëÉVŒp–ZSEi9ã±Ð	ä0Å-œ$Ëd0aÜW”:”ÛÞ<Úœ†€2	Gèì¬§7ëù—ã(…–zÄc}”º–º2Û¿¤3­Üu¦ðÖÇÉ¸%¨âÆx1L^P^æbtfÌObëlàûCúÉ™PôË×ïð·ÍX[„÷ÏÍ·›rGsð> 2“SØ±¬hò&œ-%š“MPõœ2’5¯ÍäZ—Ù¡ÖgD¶®€‡¼8,®*0¬A¶CF#8¡Ùô
œ.#F8®<m‰ 8^K¥¤/ÝàßW×ÔwOyþ_àæ$/±ü¿¢êœÿ×lC·t‹éÿZÿ¿’ôëÎ›W»ov~«Òh'å¯Õo¹ã¤®ÚTøµ__í¼Ù9ÜÝú­ÖÛÙ:>Ü=úùäø hõNïäíîæÉëŸ91ì ¿nà—¦?X¥ûKeòÿE–ìÛTÓø†m)lÿJµÿW‘*ù?/ÿ?dÑ+§ýÉè4pn‚Åt†'borðZÁñP^brÍñvz/•^"!~ÃW¨á>Õø¬¾ÜŠÛá4&Go·™3†ÑùŸèþ`™7øÈt÷@Þ–ÅÈÛtÙn6ÖóÚÃ'óíæa÷­3œÒ%vV¨·ôÔîÚûé?ÞŸn¼ÿÔ"¿"GüFÖ’’žÚ…¯™Üô%ûât^Ú¹³õ¬€+
 œ"eEöÞþÖæÞ—ë´4p‹M@¼bÌc<—£¤²§¥e¥ÃùÀÐ„0+ºY—=rŠŸZÌÇdR oøži= Ù‰¬™f³IÜ}3¿[nKlí¿yyÝ	á+ñêzC–.¶wÓåMo¾ˆ‹€¨U@)ÀÎOÌÃÛ ¼à, Ø[Lr¥é%Ð/Ûg	|.pžÀÄ‹Aes™nÔM¤¼7ÛšWnTNÉ?_\v×Ø¯Fáá@­-•ŠØáÎH´È(ºã²Û¤äR§†¹¼ÐË&ðdo·wô¥FˆÖøMV2èÖ›DÚ¡â*A¨Ÿ‰ÛÁ'ƒzÍG´Æ+á®_óübä¾ó×ÒB§I!i;g_‡ìk]¦uékz0[û•+…[h¶äæJáŽš-¹P*-68-T¡×ƒáÜBé>‘J{W—æ›0+¤$7elE²ÏŽ;wÚ‹E¥Es…¤©KIP:kýqw­Oc1>P?<å¹üªôïÅ’oðÕOépœdÁTímÚÛ³»E†°Ûœ!ùÉi¡fw?ø¤ù¶‰ÃI×™ÆaZ Œ›~Ÿp Ãx’fE<«Z4ÅN<y‰Ñ»`c<]Z&Ã–”p¤;€û¼N€ÕLåjdN²êôfÕ)¾uKÕ't|3 R””Jt3ÜŽ¾	œbâ|v×Î9äA‚;n:UðçtÌÑbš"Å´˜ùØ];c
Fü]32K©£FU¨ˆSŠÉÂƒÍ0f(s*÷$šž}ÝÎ “«éÙ™3¹HºåG°O¥0_enüha/ÊbîdAu¸?î²p:O,i?ùŸ¯ŽåÁäü¿^5œµå©p|³WÑ…ûŸ‰ƒ² œrÞÛXtÿ¹3÷¿ªQÝÿ¬"Fè­6ñ	¬y·ð‚ÉñA¨!KxÒçê^â¡àk÷¾JwMåú_L0ZÚ5ð‚ý¯IñÑðõÿu½Úÿ+IÕýoQÿ+Ãýoñ˜w¿º¾.
T·ÁK¿¾Öíâ×¸=#ä1‰)¸~x½@–8ø»ÉôØ3¬ÅÿäH6*d÷ªc>sþƒØ½ì3fÿ¯™ÿÓÔ™ÿ[­ÎÿU¤ÇŒäó#…%xF¨¹ƒ€“˜¯ñü½íÍ‚Q1OÏòzi¦Á3™³Ä4Óä™Räô“µ!Š1ÇÛ¨E
¥×Éþ.þØîíìÄîæ»ökÏòÃM3û¿y²½óróxïèdeü¿afö¿¦Íü-¨öÿ*RÅÿKü÷(ÿ?Ç¤œ]¿…HQJøSZ„üYyø?cþÇ°Ó¼¯4sþga—ædÁù¯ÛYüO`ðþß¶t½:ÿW‘*ÿüèŸAû+ÿ;¸ ¹…º 	óŽLŠ@ä¼¶
ÇéÌ–¸úXOá±§ÛÚý;ý([ëûõûQŽ]µ{pýq–îàýãZÐoé d.ìŠß¼qË|€È×9÷ãýCbn»û;o¶{'©9d·Î6Z@¶>øÕ&È:'ª¥µêy ù[Òä®˜{iøÈŠþk:€nÉžAæÖ	ÇÅ*‡ ‡:þµ*M(Çù¤úòœ‹<0ï"’ÿw@jÆ Ž'È—71c)<Æ¢ûÕ.ÚÿÙªRù_IzLžìúäÉòèOßÜuPÚíâ¥Pn?,÷JèÉpÈ[ì  "ÀW!Ç8Êð/’cå"É^,ÇR&•%l)oÎ¼J_ä.þ‹ÜãÃtP,ÖíÛð"º[óa‘|¯÷Ó×ápÒ¯ùÞI3kRˆoÀÅIß%þ*r_àØâ½Q—ÈÑzlJðÏ³Õ-yÃ­pƒÄA')äÂÙ?2ÿ|#È_›øU©JUªR•ªT¥*U©JUªR•ªT¥*U©JðôÿÚÊÿ ˜ 