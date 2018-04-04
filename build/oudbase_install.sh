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
‹ ]ÊÄZ ì½ÙzÛX’0X·ƒ§8E+Ë¢›‹$/Y%§]MKtZUÚZ”:K‘ „4	°R²ÊVs1/1wóÍ£Ì£üO2± IÉ–³²ºÍ®N‹àAœ-Nìç4NÚ¿ûÂŸµµµo?Vôïþwmãÿ+µþpãñ·ëð¿'ßªµuøãñïÔã/=0üÌòi˜ÁPò4ZØš‡~—y˜ÿI>§°ÿélpÓ›ÎòV~þúX¼ÿO¯=¢ý´þèá£oÁþ?z¸ñäwjíŒ¥ôù¾ÿ÷~ßF8óóàžjÞÝ gñE8ˆsÕù¾¡^Ìò8‰ò\mGÑ(Œ£dªþ z³É$Í¦jõÅv¯ïôÂè,Ê¢8ŸfažGjãOõÇõÇêûQ8žf³³³†ê]ÆÓ¿GÙ(Lw>èýpµø³©¼“?vfÓó4“{Óh&ê :ÏF±ZM£¼®rzÖJéÙ¿NeZýtowñ´úmøq;œÚ~7ÖÖÿØZ{ØZÿ#ür]Äyœ&ôñp–MÒ<â¶/`ëT¯ŸÅ“©š¦ê,‚Î#'0ð¤)¿
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
9\~®+xÉ’–ÛÍñSÚ&êÜ÷´Ã$tÐ|ôà­tmÁwWqý¢ 9$­éûiõùøa›/F¿5¸’ÝÒeç¬Ót¬þüÔ‡ÊMðcäu|Ø|‡ì&ž7Ãã¹ÍËç½õ»lÏo<Ž9ÒÕâÑT¾ä,úÊŒ<¼&Cêš#ª±ºÒ^Nh-—ê/Ñ+Sá¹×ÿ0›}ó¿ætöÛwÕÿ,¾ÿ“ïË”û?¯?|¬ÖÖ×?~ü;õøK?ÿÃïÿÄýßÝÙêî÷º_¬X'ÍÙÿõ5ÜôÂþo<~òäëý¯¿ÆGU|¾ß­¾ïîw:»êðõ@%(T5‡ÏÉ|ØPR™%‘Ú€Í&WY|v>U«[uz¨^fQ¤zépz‰áˆdª$ß^hj¿¥¾“êÃ|ØJ³³öó@u/¢ì
¢qŽ7Sãé³0‡arEâÎ ¯ÝˆO1Ë Úž<”ï&XÆù¨ðæˆoU€ò3$ìí9u#b“ƒŽFé%ÞŒ9oºô9Ì¢p"¶:†VVGêpv
½é»N¹ÞÊ¦Ý "Š<äß€»¹^œ
E&«wq2 M‘Þå-Ý‰¼•Ë}¥xÏ{ùÝ	¿Àhh~™¢>QŸa<6^È†…5ÂËðŠïIÁaÑ
”)Ï5$Îè$IG Ô‹+´âÝ¼ÓF0]:ã8™FÉ€÷élf!|Š=¥1“CRKiþ!Ví:ËÂq³9MmME7ºÒ•‹Î®!®AÞ,H0ô¨†H´ õf",˜“YòCa3³òOq,ád2B;Å—Â¼ÂäJv—ó»"’l	qéO¯h„!Ý.Œcü1ajAÂß
­–Ì?‡)¤)aÂ˜zaX@ø‡ƒ+`ÆÓÀŸp~^ÎKÙÒÎÁkŽ—½OƒIcíu à«gëcò–žr¥`hpâº:(äœD>€¥ñ©UÙîìŒÑ ŒQPê2ÎÏëÓ_G˜‘(bf?D”
R¥-:´ôbpbóÔyÛ8hlº‡×q·al}IÐ˜Ð8ízs¶¶€{‡ÙFî€r	g°†5ŸÏ_b¶í‘½œv#‰x'YtAùãˆb‡éþ
÷'Á0ùEg˜¿“Ÿèt’u{@unt«ÑØé7â¦ý(›†”WˆÆòø4ÅÓ˜/ ÆF•»ä®RƒâK‡ˆ€ôƒxˆ(¹Y†ÃÂg8iðˆÐie^â}ÄïÃñdp ŸõÏí‰‡¥;ç\®3¼R‰V„N·F2Ù1ˆAUUF¹kP&€É4çá5º2®¼„X9y¨€â2O‡®¡[êñj¬8@3¨üÐ…0[øV®râU@ÈÅMhäztD€%&´‡»UèÅYŠÓË¯!Ÿä›Áêz]áíéÙ”xó^\os³W7ê°æ@"¿0ÉáÎâw£èˆqÝœx¼°Ý†»ƒ ®MÔQÅì:‡`éYÝgÓ“¼ûz:Diš0Å>ÐÉèÖãBâèÈ"fÏ@<3ä%W„
4jº´¸ãS@?&ÿÔi`:ÍamwYôŸ³8‹d½Çrs¸e@§ EöŽ¯©rÐà]äaÅDŸAãV Û‘ô¤p*k3 U¥³¦…œG‚èŽä †L´n=ºR~éWPa¤</ö©˜%<”Òqx>²Y”§Q8ÜøB< Ü‚CŽðb÷³sj‚nß!ˆp²@(]ž•Až‹<Å'L¶@˜Ü	‡m7ŒŠ $Œ‘z“d'>QA™™–©ü
P™ò¹€ç&±¤áDÚïÏ2òÏQg ‡ñbÒ¥Ä,ô(<˜;Æ5‡·˜Ä}Ê°ž …È#þ%ãI~ÄÚg	®êdŠ¶(Ÿ´^FÌîìfà‚è"²ÀˆRDæÓs ‘bèbi,|Máxé¡¶¨òÍÌ Q˜aRZ>;EóF¾Ñ*‹,!—LÓhð÷Õ³@´ÂÓ(‘Q0¹ëžHbJB/ËJ j8ÃÝ5ÈØ±70¼y•æVLn
„…*:áq‚ãk¨tM¶q1§çämÃu™‘¦2"™Ç àFº‡uÜ#*„¢-‰$ëÂaà4õ§š”YgOØ0´²³Cq¦9á:ù8ËYÜ'¤Is¡ðƒ”Ø3
t4/Ò˜³˜uÚô ‘4ãÆz@,êÑ
±To&N	Šq4#míc9…-È\¨šW-‘XÀý²ä÷LS£@÷§PˆÊ,çn)@wyÕ8£)’ß‘çAÌÉÂCÊ¦œ ÜáÐq©æ"ôÃ\^Œ»1_:îíõTg¯ŽÜÞ9Þ9ØïaãµÖŠî‘Þ¯;<¦Æâ)í¯>EÍ9š+…3 £UÖXàæê†ß5Gñ;Œ ¾ºÎ"5täëVi6!-€‚Ñ8ÆEš¡3 (aþÎŒ;uÚ6Êø¦O²^“¬/:`§ìRœzôJuCèLš°f8À–çÛ[–[ƒV5y!Êk´%5+ÔÔ`dWˆ.ƒñ‚®&&kÒ³d Âc“2¢9sè*TƒpBÇ¿P5Ù|'Àz(jæç\C&’t+]Xá !+Lu™ ‹z\€Øg©D(}FùìØ€ç\ìVBî0±šŒ)@ù ÖzIƒôWM{jÔ±ÛŠ££jý`A|V“¥ˆb0œ®Äô)›í€'èÈQò³Yd<ÝáE<×y@hBZóGâ
á”ËK¤38æÎê]$Â22:¦ uay„¨	Ü¾ŽØW‚ºSœq7¨P Ñ§>µ°{‡Èô{äm:šmxæM$•âðWÄã.ÔA{v(óDD Î?š34t$ðèÈ*MÀÉ4•KT@ÁÄ0©å"¼:í, âQ¦&	  6Æ.ä§¬~À‘¹ŒF#³°FQÝñœâ™)ÁLhC”°ÓŒ@ˆü¢ÖÐ. D%(k)°
{$3$°\!×ÕáRQÄ‘ñ¡,„†ñ Câ`úBL>Iò!<E˜6åOpü˜žK8›Ø~."î€€„éº˜@4:æ/¸U»$¯ï§(räµ@t"’óXÝ•Í¹Ç$Ö aR=±k”!ÐÀ5Vn”"Ô/LÏl®0}[tK¨£gSØ$VÇd•õBIWa7ÜIÈ±ˆÈ$ñ€Ø¢MšÀæD,yU	Áµ„Y³)©lÀŽ0ÚŒ7Æ-ß­÷a‚H00ùn4I,s§žY¶¼&àÄÎ¬ìòŠÃÆ „IAG)±H3ø5„ë-%Žª-T=5Ï¯9úhMTe—±X€F!¬Ò†ã\:Oö->–îaecŠLéàô—ˆ(8‚·ge)Ö¡†áí¡¨fµ£Í¾î,$ŸG&È1ýêiŒr»Ag-(Ríž3ày˜Å$@eKWh½hè¥¤ôwàö¦£ÜÉ§áE¢cßŸBcmã2Œ@ú›…ghIxxZï ÑFW,Œ…ãX½§M”UÈ‹a÷¨Gê Ôi"Q«1wªlÅ9£†}oo¥VˆJ Æ¤#]%y5¬³õ•ÞèEH`c€.Èþ ë¿Ï˜Èï…¿À"l¹Jc7ÊR%+@Ô<pšÓ?­+ª½†–µ˜°Šˆn,J",e©_<ú€jh&b	_•‡6Œ…i+<)/1Å…y‰5!â: Å&¨FQ´Á#—B§ï§ºvU‡›¢¬FŠQxz)X}Zj4BŸ°(í1/ˆ§ÀñŒ
Î˜×Wˆ.!1anà…°×uäÈ<A&Ü>V€~Ÿ7X.ÁîãQ”iµ@ÔJk´çvpŠì±åÓD`jßC˜ÚfCºåÝLÀ„Æ#'±“Ji4

†1G¡Ô¥µÚb!È3äqÚ¹™®ÓÀšÛÙdSmj²Se„§õZ9!Å1 E:•ÏÊ°õ¯ÒKÔZ¦"º>sìý<(WZÔ¢’9MSÂå8É=¡Êw3Ñæ¡Vp“Lö…!ã©ìËþ±äÑ¶
–Öª}ëw	£§qéNTCÓ>rôWÙMþQ,ö²ìRÐ´x¸Ø“4 6&ËÆ^º«$s™ž +o Ýžš¥1UÞµ6 -¨k³]#Ðì½)p(ÇT%œÒáÏ­Ä’ºË¨0DÛÂ)ˆd˜WÉæwŽ-”¢¯fyõ©ZW6ñ»8dÄ~mÊÍr2¨e‘­0ï.m¬Ü·×]ÀÝ-‹T‹tí3@€Ñ2ng¶ÑÂB‰@™BÂjdôB16Ÿ‘oP!@RêŸµ‡¶ä6%Cô¡6ð“=¥@˜ÅEÊJ‹–å¯Ð:4ÛÕ°‰¦Ú$©ûw.pAj@£™ÉgÉ(ÇÃ·akÚRÖúD9¥äwÞhœ³\’Vù~zå/qA¹~ƒ!5ÔñHis¢KÄòÈ8OgS‘Å-ðâü€a'é%(ÇgÏ,Ðn¢!(ç1û´PÒ$ÂóqŽ˜?çvIO¯|6˜ü &É4Ž#š +µÞ°
¨¶èKdáÚè³®™	Xßå£PöBû¼Ýâ[d–D ù$õhDh/tžß™àÝ(tM™çá: Ú¤Âù²,h£YÎF9ã"Š.+Ä®D¤y@µkÈvõÄ’e19˜ª}ŽÀ“Ñ®}ò¢A5™´¢Gf¤[YÌò™p^á@”B"]fç7Øˆ9ËÅdaÓ™*»¦È¤ï­	Ú Óè<r¾éÛ `í±!âPtinluÞc>2ZÁgû÷ØŸm¦ìÄs´K}bTˆöë<ž0‚7	W·Ìº‰±ÃøÙûqÖŸu¡m/Rq%v|#àÅ±8JfŽVN¥z$.Â.‘ïÅƒ<E±“õ52òæ(;À’ëƒ4À‡-¤#Úïñšý¬”ñ}‰ËÓnÕÜ¢!£¡îÊqÜO½ÍCV
(B%ï@Ö¶“61ÃfôÏ“t”ž!3Ý2$7¦]#Ç(Ç^g#àæT#…	ŸÉéö¨¶¾®YÐ;‡á˜¢q`@­åhÝ5µË@e×ÿô§'x¦‚/ªTdˆÕ(¢QULúdIô–A|=z¹xàFTÁ§•ì¾cª7u¥}–°i¤Q òŸÆÀCŠÝxk¦tÊ7™„á½Š: /<T[³~L#$¹‚=Oy(³BqŒ÷GèAÃ™PÍTX12­8Tã›ê]5‹ôB–É±¬f‚Ô•”H é(|»".É&>îìSÍËàÔÞ—Å”™™Õ,mZP½š´{ZÎ¹}£ã³¶Ø ær ÙÝB—ž˜ðçû¹'Ò0s	´™C@Ðb‹‡%ž«Ét’O@ág§,ù‡­Ý5HòsÄìíõg¶ÐØõ4 DØ1´r‡ì
&.’#úBŠ?ÉU€-ž\ŸÍ@ô÷°O%ŠYô­uj0*@Ö/<Íµ1í¸26·§4Œ3:< ¾9áÕ60h•jkvÑn6’£{°Š5RTiZþFfd—ÕÝ$}Ç'ä³	Ü#sÔ†B<`cBh]dÛÓ²HÆo\G{ë\KIPi£h3:w,’¢÷’Ø^´QÌÅZM"¢ÀˆzkUa¬¸¹"qÓÐ†æ.#Ûd]X'á•­~Èìû°`WŽ‘±)M”,W»Ž‚„Àv!VXÒH¼§ŸÔyÛ%V‚âªÔ	>.§æóÀme­Ì·ZT­lG26zº? B¤7!ÔæœšL´_·1BZ†%Ä/3š°c‰s<ø¾žûÑ–íPVd5ÎEšçQ®#	Bë#+  “©J`ÐpÏcÕjÁ¸1à¥òLH×ÐÔƒFí²QÌ$Š’´Ñ†lÙY˜Fw‚²61q]Q6)R@•§¸ aA9ŠÞ÷u0w-µ¶êN†Wâ³·FÎT® Ï±¨—Q¤Fa¥$¢ç:ØK›¹”Ôõ¥Ô1VZšïj•"z5v®##(s/OqmÄ¾ä1¯bO2!c™–°®Ð%W®Ìí…y6 Y)>$‹søÛáÙ`hd_†büá•×+'^8..ŒvNÑ{|3©¾(µ'ì&"ÁÉ‹;ò¢ï>Ø)Yõµ‡T›uXÜ£gù‰±Î7PaDe]ÓéhÆ7û„TôóÜ‘Zp\ÌIPÏÎ¡Ñoë‘Ú%âR¥¹ã¥¶,_Fh*‹fÄd9*à	Ni	þ}	ON# 	¸$¡®ó£ýú¢ô²"ƒ®§„T¶ªí#/=üOÏÈÚ4û!‡:Gé+=Xß§•4 Â'.OÝaEØéKØœ9¼Ô7”TŒdbX˜eÆÅ<—:½1LÀ&BÍ«´ˆ:+Š4ŒOId+‡¥n™þ
Æt@ínC²9ôÎ¯r’%Ì‹€¬Zû´Ó¢Gë’÷Æ“0‰µ]‰©Dµ©/~ÏÒJ¨³Œíg:dFÙƒ=@8K6Z«Ây–µÿCç2QËPOX
l(¢ú,íM±4$i1u…›n&Ì9û“&'Ì­2±æ•q„L6,±QÃLÄ	tï C”LÍÅ…u‹¤á®”x2) —7ÁÓ‹ì¶ÌáÝÍ1 #9j®ñ±Q<Zð›ãCC{HIr.>N9@¬Fpôò4‘€v€ë>Q—r}"ÏXë—‹	«0$Ù†µŠz°ûQäu„{ 	;’TT+Á	>;ÔÕ×.Ý­“ˆgÃÊø(’bµª +Ã…#eåû•â\•ØPœöûaN’«£èRG8ÂuT„¢íÊn{õð™‡šÃcôHž	·8Õâ“S+Í9ø§¢Ñqæ=’ågÏÙé	KGèTZ-Æìó~ÔY´ä´Vjg×n¸hTì¹q™	]¦‡Ü9a AÎ2¶260£2r’(^ÊÀMð® ;ËÔ2—ÉñHDÃÐ }Rš—p·1•øàqäï×«Ú¯²eˆéÑ;\vkÍ¹âJgD<„ØåîH —cùvø/+ä¨"Å¬uQ ¾µcÜðû©(œYæ!AåPkª+Ë.Ã¹«ÛÂKq\5ƒ$#™ä9˜|áë98ZmÜd!h£	c²Z¨ã¨%¶aX†õ[çˆÉìmÎ=m2—SÍ=53²N¢(kNÓ&þËá_&äO¯0ÁÁ‘Ç	ÛØQP	¯]…'Ü÷"ÁPÏ/ŸFLm‡Ä0d›Ä[­c$ì©óèÚ™ˆ*Áq@#ÇøèõtR¸fX<08ac/©>bx8<ç;PAspO#{à{SJ¤Ð	CBc<êaÈCk4‡CSì`>³’AM´¢c"‚)æŠÒ¬a[H‘FÍ,‚³åÌ`¤ËWucà¥á8nÓˆÎSøý/çUn9 ö—71çÑ@R€ŠÃª‡l‹N(}€Q6ˆJ‚¹GÎM24ÒC,aÞdÁ N‡3¾*,·^ØšttÁë</R
[$É#<ÓÙ6n•În°ì‰bµœ+T{ªæ-”WL¯&$+¦EèeÂˆð¹Q˜çNÊG£`–Ð~ã™Ém(t®xt@BJ¯°7…¦æÂèQòEïÑˆŸëèŸ)J3á(;F1²rÙ#×›åÀ ƒ“X¹ ™ú`†Ò4/ß­&ðpg	&Y Ÿ@®H’&ÇÈ¨Éf³Hõ
é¹P$üÇí°‚¼C”ŠþÖáAîs"Ç0­t77úÑ ÉÓ…ßEW¼¼Løb[Ü“êDFŽŠ*Ò¶ÊÖç)P–ÞçœÐ|¾DyÃC«PÏ0T1*²q6Nãd†Ä@nkÁ×”ñˆÑ
4•Ä„Ô”C%U„É ›Šx^šC®ÍÓˆÔ|ßdÊ‡C	ÝzN´¤D*]S¬&ú¢ñawìÖs£r†’MËj »º66È‘ö9st3ãÄdvê®œ“(#C×:j“~HðvÃZ$²ÚáqF´“øªI4ÅÓ+#—¬AS¨Êj¥yÓaNÌ¾$üw	8Ž‚JÆóöíÛzQÉ”x¹zoÀº¾šwÆ0&$×¢m,=dÓ	èÖ;fl¸×IÊ`GÄ””ÆN!ö®Ü³UÀIIºfÉÛ[q
Ü3áf®15 ¼€Ì;Žöê&lÉ¿£GÍ›z9B/
 ô)sÁi•eG
G×Þ#Bh¾žc#Ä÷CgÖ³™3Ù%ƒWA¥ ´<›ãe@‘Q(´N âþ "³Èåy””œPH¨¢ÑÐRhwæ iYÄÁPÄ­ˆÜ[×1SÝŒå"NG”ˆG“›I1ÊáLûÝ8fl£êÂ~–æ¹HB4œ¦
s÷YKÃdsýž•‡‡3“èecaYÎ.ó+GÄ?¢
1Ãó†ƒbàœè®Ô»ÖHë\ASÑ
¸áÄ,A·9Þ3¹ËÄ¦ÞÑj}ÛÂ:¸Ú/siƒjÍyj˜–Enèâ¸ÄK—Ì›:íqVâq8£‚“ )Þ0‰8é'‹4Û³.·VP=î9”øštØûÄ´»ƒÄH 3ÂIn6ÝÄfN¦qƒÕ]C–‹arÁÙáÄ¶¾RÎFµ§+Ç°å[G©»1´Æo+éžÙTŸ@å­?)ÐÕ6»«*VAW*9C‘„Ó‚RxÏ1ÒÓ®žÁÜ€6VU…Æà4B©À©(\„CÃêMý,œJŠ’92ø SŸ—- ·Äê,‘ÅÓV3·+þ¢ôR†ï¡'5+Xÿ¸Ô,Dz·êÖÙ@&–`Îð‘NQlˆïXì"¤1ù>)?îŽÜ‡ºÔÙ{+ã>lo·5Åm¤Lú¦òè|ì¢ß‹Êè 8ŒcÁ…Ê4»HY"8[fdÇ„eDÕø´hØõ…„ÂS¢Ÿ¬óc[’H›ÔáèßBŸ¥ÉÄZˆ06)Î¬5Å ‡\­?&bºþ¤8†§(cj'Ä‘I7%µ%»0ìË¦ð8ægv¹™°vòr™ŠÔ»Vlüa¦m‹%o+«öÉòÒ³{%•íxjGß¯ãñ71o€)F÷òx0ìäYœåÖâ¬ßfÜÎ©Q¡‹#˜¹Ø¢b«sVè’ÒörÇzhÌ0<Ð”_²SÔasd³±åLª!1«Ä×6^¹N°{Ÿj]¸;att=`ÛQTÇ0Â/&:[Ù
Qu(38=ŽcõƒÜcÁ5lÁ£hØæ¬\Š$Hë“Û~‡.¦¡Ã{œxauv&N½eb™Õ‹åÇx uÎ½éªUe[ØF‰¼©ë›ç±ÖY¨.ÀXØ6Ç‘ÚÂèP¯urå¶ÎÉ!C•pM²1H)E°‹¹¿T.€É`*Wb+F›ÏFóÈwH×jbšL((‰78w9‰h?Ð>"ykìš¹ú€Š]¥Gs÷˜CíYë	…@T…%9ZÍ‹yYYÔg¨*&b	¶¾pŽ6 ¢¬3”MJÕèÌøP9 I²à@ ÔþlŒ2§¶x1Ñ®èçðÿ*Æb‘ÒŸ¹ã”wóiÚy¾gß¨5êmÃžÏàà]HÀÎ¼ñ»6
.‹¹¥A/Ðh¾—…BéÀá™ 67™©A!#°´bT(!®_C‚„¼Nª£ zû„QAÉÙá	ÊFÆï”²œó“OTCT².Ža›rë<i™kd<Â™~-Ì%àiÀ6 DQ×¯!Ó;0ï[¤ Ä	Û#Ü¸ÊG3#¶Taç$¡›Æ€Ì0aÚ`R9Šj¡è:Å{n¼VòMo©<…'«¸°ªFñr~–ÕT&yU´tj€sâÝè"%n
0S¡"¶° a+„ß&çÙZgÓÇ+'(Œ„wºß„J’ú])"NEÎS3’ý®Ž©º( *²‘}àz`„Pv(‹e˜j ¬Œ*åH/«*C.øcÑOì±¹Àˆµ!—hØØ*ð!hÞt¼ñ ÅgÉmírPÍ qäÊ0dWÆ†œ0üdMHªNe'(Ã èè¶)­º—„t£EœEtæTš’~ƒfG¹3—`ù\¼ã1Ë	|ñæ4G¶žŸanBk ô\ŒÑù´,ŸÖ­‡k“ú3q0Z¨f}ºëHÄgbg÷,}À_KgÌ7ä³ž=•¸bæ¡ñW*r 4Ez™Y
¾a: ‰âlÊ§¹¥ùŠiL°È"gúHèÅÔÝjNÚ›úOŸH/MM…¼Ã+Ðª£Ãe½èe”fpÍþÔ"ëßDîfàGÚãP^qF[!]BÇNºÎ®]æ#J8\E&eùyI6û±“ôn†Êmª¥”CÉšO"³x!Bíâ‚1éLƒ%ðÀ–Œ‹7‘7Ø¡Í¡Y%'Åò–z¥‡Ü d¤Ô|"ýðã*Â1ç…4ÌH2±Ysä‚;ÎÙ×-9[¯büJrhŒ35v8õ¹”`Ú€ ’+„aÙ5({.7$á¾()w4ç“&"Lo§—€ÑX¾M¾ÐKTœÊPž9¹V¾WÅã®šNåŽ€[Ö/2ÑDÜ†‘Øâ,»Â…^¨Ï|Æ®’¿¼…õÏ‚T'‘XdÓž8/3æûÛ\_Q#Cº5Æ:‰ª¡•'ëÿ©±Äïz„ŒÏ‰ûáTM.xå–äbÌ+ë‡|KurÔ-¨ŒºE¨±àQ†1Ž²3Æ·ÞÑ·yÇ5ÄÇ¬£¶Už„¹³“hÊE.w®H„-vÉGš`p®i€q;xD-=×ùìkagûÕ}ªÈ8 ,J6Ã“´ ÒV°®Yâ¬¸eŠg‰ÄçÑÇ%YŠÅ¼Š¹Ž:w
]çŒ	Å™ ø;õO…‰%åÏ°úh8Ä«’Ø,ú6Rž
*×ž7I34¾ÏBJ>²|Ê{Ÿ'H{¥!D)Üþí‰ÅêºYzŽÄS–:!tœ½eÇRÇ¼ÚJWîŒéNç)š¦’{xÁÂäXjr$ï?E¤Òwrú`JéM%è>;ÓJ|àêÒØìõ‚4˜+Yá¨™†l¤rìáHê)ºI¬^nQ8ìÇ>IVÉúzKê²–ºä\ÂVÇ4«éÀ›‚ÈˆgÊXt)' B/0i§0W-æÐVà¤46f<œ·YnkÚD¢ Ã„ÓèŽÚ”ß39$^K[Ç]vñR!}óÀx¢SÃñ§:€6hiÄõMÃ¾9°;ÈHYÔ×OšS`ñ<r:;N7s	Š»&%<(‡L‹ÈAæBÎ‘·XqQZeD ÔžižêÜ!‘ã‰
€%}ö«Rz+úæ¸†Wš-æÒLG5[ðÍVhóªÔE¾cè41^46ÙåÔÄ¼z¦r5¸g—Ó;í¨!,$»†)?€U³Ñ «jªÓäš9žÊí~	çà 
—´ ¸,ÜK9èíN§œ¸-ûÂU)ˆ$Ü»L|b°!Kgb¤7*«ÙYŸjþ$™H$WÚ<@ÓH¬Sì~§l“ü2HE}i°*•ŠÜ‘vKŽÓUSv.ÑK²°T)ÖïpQr"']Ö0»?·pkOÖ¹¬mö¹f
¹û;HÁ,]˜™RscÕçÌ¶4/n2;Á­Šr*ˆ¯XFFMY#–Á“ÒP9Kmnpª+0è"~1¹ S+ÊcÜ¤Î‹,MIR:¶=tLƒÓI!åÁ0iŠ2À–N[C05U4Ž:¡¯:AlÎ\ahsÄêÈÒ¹TEgà+Ö
e…Rd‰N£’±­Â”pw¬0¦rÙêCÓCÃ¥HÁ(R9ŒÀÔÇÖ¥§ƒ‘«6È¦`ÅÃ¿‘E.4–ñ¤˜â<Š«»"cÐ&€j)©‚â„,%ó6Ë<Ë_ÚæÂãÄÁªÜÊÀ“¹QXÝPÓ9Íp·š§h  ”É¹»J²Œ£8ºˆl†œººóYÈY,6Ã4“È+“ŠÌuäÕ“fÚæTpdÒÝ0‚t¦u-h!šp£¤:Sú:ù«è‰ntp”‹òZU@Çh¦´Žö5cÓ#0œ«®öçjJ%m:©Àºxƒ‡ç6£²˜|°8—Í^ñ»`Ááä©6¥D`íºªaý‘,&–’fW5¹³€Ç~:.ö³s¢‡82¼a*¾äEõ…eëÜõ²õX2°ŠN!<ÉH/6ÉG¯…´|¥«Èx©Ä’CÂ«Uƒ‘1Yô4N@' R|øšNQ‚” R›îHv2}Ð†œœ„WcŠsJ­CAzðªRHim_•"W˜/d¥P£Ïí¯›e³†.inHµ5¼2%ÑvºÒéÐ†×¥%¹èS$øT´LüL<¤™ Z	ÞYåø¹˜JûŒy‰Kýãã:3tBÀ8(Å‘C<“AU×æˆšû#XôÐiÚ¹¦‰ä­8ÀâHÁ±Ed#pMAPKÖ“Xê¯Éeh´ç†µºoüQí…ìÞ™¦ã‹Îc]ZÖ1û™L*&—ÍŒOÔi'T‡d€ÄÈSMË :3WW\S€¶C—ÝÈIcvw=z¢RØj}£…Å­zæ#Øï„˜ß§›¹éXËo…zl¢H2µªõC*g7£Ê0ìÎpäG;Øº’(6|Ä}–¯»¨r¹]éúv°Èn±_cšÿnËŠŸ|mƒ&4>‹ÏS)o SËòx<MC}OGê•*sy&]"EgŠ¡¥‚¦n_öR²Ë»æ ÞaFÅOŠ¦"MqiÉ€g}â:»Žï®BY4z,¡¢õ8L
¦‘xœ3o;,?(„bJ–Š\WÇ¶@³ltÍ@2]x«dTpr43<Ä©cÔüä1·šÑúÃFt[)ï¥è ™.ºžâ“@Y,‘’¼Š„%2Jþ	Í¼›'$>µòZ…ÃW’NÆ2Z`ërØZ¯nñ…Â’S‚L®x7Hß«@A:&…®DdW«c­Ëâþf×Œãí!Åõ£ŒÃöœbþFë2*8£•u‘øqÎ®b|yÔRGì0ŒûMäÞ½T0à2Í»‹#[¥ Y&Ðä‚-ô0ºczÚón,¤s†î8üKa=88?ŒÐÖåú°BÒ$Îb“Í+Q‹ÆêEÊŽ’ƒñ…f”Œè¾Î„º0—±LŒËíø™4zÂÚpeT›f0uÜÝ"™aaAù˜àr‰ÕÒ 	!æüŒ®ÂZ…µª‰Y“ ¬ÕÓÜëH5ðí)¥ap$5ÙîÏœ+wDáÖUz„!_QÆk(õð&°xSŒ32;¯J»þŠjQo>
Ùð±þyª½ÙŸÌø‚ªñ9x­Y»;ÂÒÆ¼¿âáT3ˆ&ð•UÁEäßg¶ õ„îëx~}?cŠöå;Uí2¹!Ž^³;^‚®ßÐ:¿ËFviCµ¸e&«z&67Z2ÍltnàÆý;ñCIê½á
q	³–% :­ˆp!É€©¸Q'hZ€ËˆÒ‹‡”Lì·Lh8£ÒÎ$îU÷¨«vzjÿ@ýÐ9:êìÿ¨^áêðèàû£Î^CÐ÷î¿w÷Õa÷hoçø¸»­^ütww¶:/v»j·óÞœôï[ÝÃcõÃ«î¾:@ð?ìôºªwÜÁvöÕG;Ç;ûßÀ­ƒÃv¾u¼:ØÝîÑUmè^T‡£ãnÇñfg»ëŽIÕ:=vMý°süêàõ±|pð€ü¨þº³¿ÝPÝÔý÷Ã£n¯ Ø;{0â.ü¸³¿µûzÆÒP/ ÂþÁ±ÚÝ™A³ãƒF€½I[ð÷ºG[¯àkçÅÎî¬^«õrçxº µëðÈ·^ïvŽ‚Ã×G‡½nKñXð£Þ_Ì@öß^w X]€±‡·Ôc_ÎœØ&œ®úñà5²˜÷î¶·(¸P]µÝ}ÙÝ:ÞyÓm`Kè¦÷z¯+ëÝ; AgwWíw·`¼£U¯{ôfg‹Öá¨{ØÙ9ÂUÚ:8:B(ûŒFOZ\n»:j™)Æ>bP÷âÇëý]\‰£î¿½†¹"–(K~çû£.-´ƒÁ;00Ü=ƒŠ£A¯À1~;P{Û;/q[q¶ößtìîªÀ:[”í¼8À…yÙ¡ñÀp•pß¶;{ï»=3°Ï@.Ùn¨Þawkÿ€ßvy©ö{0WÜZx @Tö! rò>¯á  îkÄ¾ñ™;ØUÛw)ÕîA10Øîwþ}ÑÅÖGÝ}X(:c­­×GpÞ°¾£é½†¸³Ï»ó¥#¾s´èCFxû²³³ûú¨ˆxØó,!‚$tv‚[ôê 7_í¼„®¶^É¶)ï(ÿ¨^ÁV¼èB³Îö›:ŽÒrGÖfGdû¾mñÝ"x%†ÁÀ^)IÅe^è™Œl8òÙ†ß›"ikoôcÁg”b±N^áÊÂß,TxJéR" H]²t†%\XÿgU …—¢³c9¦þ(åLPLlyOw$äÚ´Nót„ùóT8™Å”Ñã‹xäŒ½ÂfâÈ`6ÔË²‰þBØtgö€–ÂÏ]ZÜ¾XÖµâxIû<çBûyÅ÷:uh‰8œëX‡–ÿˆ,o„U@îxä^Ò.í­Ä:œA®œ‰ÌãŒòsàÜ©ø_fy!·´!ž‘|Ê5Œ0pïœ,ê&Tübñ4ð¯Îfqˆ®ÛDÓ(ß'á_Ä«oV5þ%­ëKÒ(F¬AÕ¡­øªS§Œä¯cwÈ‡CœŽØ¼=ÖA¢âl
"rÂìù¾–Ü»3 ùK¬™NUC¿(1A"r=(ÉÞºú©?5#ÓÔPY³ˆš¤¤Ô±}AWÏÎLmWºÊeSA®ïp9é}]ãÍ™ÿýœÒ‰ôiGCô „¦8‘È[Ï¥*‘–²V·êê;¬N÷z ©Nß{ÎýË}­:lÃÛîMsß¸·ÉñTëƒârà¼¡jâB)9Ì=ýB~æËð­Æ”L6Ž‚ÓVýtÓzY³iU/€§¹»êÝ:I‡´q–ìa;¹*-ê£Z\C¢E¶§&¯+h,mü´ÄŠÓ®Š’,î<ÁKYÁ«±&ˆéáÚ…Áj²®…þ¯Md³Y7°Ô•sj‘Ùµdu#"õÝùt:Ùl·///[gÉ¬•fgmîÑ~ê`è&Ý¸¥M°ˆÓN²óÕãTóí|Yš`Õ(¼+$œ`ä
ÌÍe”W•(ë‘klih*§/[	q=²i g”®q¥IQ60†RÝF.vêìÅÂ5’²úôûüÆ'±„‡\š™Ö´ó¢w°ûú¸»û£«É<¥=•íTÓ+@Ðÿ ß/ï·,¸ây¶¬ƒhy4Â~Ø0éo‚À§Ù$EKÂS·»þ}w °øhY:¿š ¹‘Ü…ÊÜB¨ÇGc0oþéÛêÝLg¿ ì{§RCDŒcÛÒLÝu0¦-ÀJZ¯}*Üýû×;¶ú±\ã@š‘­AÕ@`¼8Mß×LÜ¤™bM1Ô’zà\§WÑ öj{‚¾Ñ/ÊêÓ…ú-¾n¼^X‰+€it±2^ÍºñMYw¬°bîüxi|êþÁá›k%YBÃ¢U›Ã7oÃ!–R¶. 4ÆäÃ‘nn±0 îþpå°‰½—Zÿ;¹]1@,KÑÉµ^W’lÇe)¯Ï(-“gŠ,â‘ !›ó¸mâ*šŠRîÌàÚžÅçèRÇ"\Jx^Ý­ãVpAv1,›gÝÃ(¡(Txk°¤eÜ`ô0¥caMåVLÎc¥ÓÉùUûòüª	ËÜMF­óéx»ó»ÆÏ í·ºí½nk<øB}¬­­=yôHá¿ß>yLÿ®mðwø<Úxüä[µþpãÉúú£Çë«µõ‡k7~§Ö¾Ðx¼ÏY
%O£…í Ùp¸àwžŒ2ÿþ“|î©ƒ×Ûxñ[ãeÏÁˆh+·:~³Ý„ß»ÉÅÿþ¿þ_¢–r)'™Bé†KªÌm ~F’j%1ˆ	ì§ABz {Äwô†Ú‰iÉ€Žg!ßèƒTÔ¨3²c0Q-s|Ø‡?@2¬k?áô°“ƒmo4¤„eÄ„Á@è'žÎ´ë”õ†+]/à˜mœ1(úðÃÆ\ æêIæÉœ¶3 !ð¼`6þh1M3ï(º[ßøSt½SMJ
UB·¦ð-ÌÞ2nëeôÖ™å–Þ^Cu¶Ôèû–•¡êEHóél8´þ¶81¥@½”2
Œ¤ÝœI z ‘æ„šKøÍ/3	Æ|ð `P­üüÁY–†¾Í;Æg3)D%N²b5Kúçl†ˆ±L‹¸×%H]`pCŸ®Ð,‡ž8¾˜S¯¾x^J½ +>.R9Ÿ«×±wA‡Ü¼ì´DÖyÕðü|Î.QP‰¥!ïÊnœÌÞ«7{ÿûÿü¿aT8Æí´ÿŽ=à(ÌEŒræ“ÓoL9Œ±)ï=Aôù0´«vošEÓþ9õï
>˜¿—º·eÐp4€]ºw”élRØ.·âÑ1è3¤`“Ñë²dvéî&.Ç‰ü„ÛÚÂD˜Yù+‹ºöRgpÖ'°XÔïô?þã?pøAJë÷¯ nó¿Úê'ø÷¤?È£ŸU{¶¶Þæ+EÛåÎTó<ØX[ÿ¶¹¾Þ\x²þhsã›ÿ¨Ð7pt¼‰·³a¢âÕUñÓªµÖºÞ˜mgÿåÚ¤ D­å¬²1;ëcÝÕ…/¿Îù:éò@~jž_üÿ=UßÀ±Ýíž¼èôºÏVá)x#6oììÃŒ÷·Ì«?5Çæ·W{Îóðüõ6|ßúëëCy¼°£%£hžWZèèCsV«$wQj>‹êËÀ]Ì'÷Jãaè}CÅo´ÂšºÐœçj[Sš–ÚCGD'ÌÎ¨âE‹Uº]-ûXB&TÎoôm~\6—Tï\a"8Ì™Èê †èÝ[Ñ¿Ö[Ëºpè¨ê‚\Õ]ØÅ¬ËzÙIŸsÀhŸ±†¶êª -Ð'eÂåzªãŒÍ4:kqHõ @…óeÑá… éxg¿°âHMÉOFIc0†®üEÇõjÓõÚ²+Îå’OÃþ»Ù$¯ê“ZÞiÌúÔca§D·èžÍŠnÍKOyuZ2[aöÕH×ÇƒÁ(Â]_Ú÷—XéO§ »éñÉMÕžŽ'%7JÏIW8SBôœÒ­ wñHÕ?`¤ÇïEÄÇ_\úÙ‚÷š§aâš÷3ÂÒœ³ÈÐÌ®ËÈðö úíÈ¹¨U-ŽqlªŒ‡/nªã7­%À!‰vÈ
¤o°u…±ŠNx£R¾A©¥ª¤‰(9Û„¬µAúhóc/x$ZÀ`ù±RÂ¸@.R€Ä¸ôh@°p³ÿØ\Ûh®?9Y_Û|ühsíñíä‘õÖZkMK$wÒû-ä—¹/ocv!ÝO'à"Í¢|á¯se½Lp†Mª”+m.„ä²jóyV\ƒÅ 4‡t?·±{ðýëm<¦‹Þíol-é¾MNÜ6`óR`ó²ì]ÃÆËï.}ÏcNŸ†ì/…`ù©?jâ‘7Ø?C±½·™ßƒ¶_oÏ]]±ÿ o-ÚJÕŽ/×7Z­õÖÃÖÚM ¿ÜûÁ~€ÿÒyÓ)Œ—çYûÐ	Û¿Þ­·þØZ;Y²±Roëhçðøäå¿í—1o>]RødX]«Ç.|m‹œíÖ`¡SÌ9ÌÅxv›3.`Œ{³Ó]ýÖ²£XõV™|BÇËOSõ{78GÕ/ÞŒ ,ïMNß#@/,Ò ‹7y°sžR–"ýÕÊ1òþf/¢Uû“·õ×Û€hlw_v^ïŸ¸
O—ì¾§Bž”QÂ#ytªÑäæ6ý…¾¤~½G[©û„±ÀyÂÆ¼€Wº _’ËDyk­óŒ+! ¼oÓøÝ“>q4/çañû	_Kç=†ÝÑ(Å§í Ne;Àò€#Šýs4ˆ‡îw‘ýÚÓ¸OZ(6ž þájº€Ò³,Åp¿yŸ0¹â	ÿs„¬·×š\Í*Æˆ#¾å'ð4·¤vmáwM`³|Rø É*(ýâ/°Áú´V€¥…Ã6“økI´ðÁBL<ŠXH‡ýKÇT˜úÆ'²§_œâ›¡¾¤Ÿf‘d¾TF°EÝá¡*ô&úD«HÊêŸ
‚„’ÕÂP?š#ìÞà!{1A°§
¿²É“7×ÃoJ.JCPt¨µ¹÷UˆöxYBpOmGýwvI(6;s]çèÿIÕV>èf×5"j5õóSJ[”¢Í!6BÉåºÝÒmÝVJµªZÀ/ÑH‚d¢þyªjÝ££ƒ#`AdFGO©òÍaÀÿ`&Öxð®Â3vNô_|ô¬ÖRÎÚ+4‘Âg»[]úåd¿ƒxÔ´†ÈêÃC×||:ÔÅì×Ì¯?Ì0;Ågí<Gú ™ßÂ•2\õ–j÷šB3Õ6Î2$çH•z1[?Žu2  w>&Rö3¶¤ïí áX¿”Úª¥ÿdÁõAKýÛÊ¦p"š[ƒ›‘#Â¿O9Lí1¯
ašÃU¸ŠÏ=&²'`áI‘`XÓxÑ‘¡Ó¢Í'ÛžU*’lP59<K£s}É)Yö:£Î½{xC£c2Âµîdýóx‘O1^\»ÆíÒBczÃmš;Ö3pTl¹Ã˜ñ¨Îr¾4n*@ÅÆåZÑ0ð¼pçE,7·ç¦J…¾ˆ],Ü‘¶pSd\…¬ûræ8U=cmjØˆ7ÁÍ’j³8ƒ·²ß1gª€¸°pŽìÖ#dc^‹º¹Fó¹cµ£°M§xË7ù‹]‹›»&DŒTw®Î=-g«WÇ.´†¶à6Ë»t^œXXI>†²Œx`ïìQ/I 9ß3[Š½p	—–¶§	„*|>ªíˆI¶ÅÐ°Yþ¨Å'ØÐ’o¢A4.|Qh˜t"®Š]Köq»…Âœ ê©7cû
uÂ€­õ×Ô÷3§²Eµ«0syZ©&= 4o{{*š2¾ƒ4'?>À»ÛCzÜ—ÿÝëí*Sï+‹lØ	©?2 ¨'RV¬ª”(ì0ÕÕaÎ¦læè…×¬ƒ,ºl8uÜYƒ™Ü=a¡:æ )­¾þ+ôãM¨”2Ë¢ ÿAKí¦¶t\iÐ~Å!‘«ép|Uä_ X;+±hÆžZ\	.ÀjÇª¸D{è»™£?=ã
zeié§»š #î˜>cÛœAû3ëbþÀÄÃc/tTÜÎ£ÑD­ž×månl²{Ç4xNí§x³,ZÑB¡mÎ2É"V®VinEØ•»Ö²vfnõéPc?ËP¤¬ë–Ç):pÅ0?2SØvìT_Èé—åUËÕl,G+
Kcéi /½$ASÓà–ÚÃŒÎsÖo‚iûLu^‚*+áH/GÑ{JDrÅ:Aõ‚žˆ9u÷ß¨7šu‡pÈ|=§¢>ªÙÚÜ†Õì®’é©Mo×ˆB×®¹¡VúƒôÔÌÀù‚_‹.·ÊYWx©	¿bœØÜu•OŠÁ$íÐýú9]»Îs,j¢ÅS®RahàÜîB´ÌðJ®¢y+³ÞX<È…ÃCÑM“S-IXå	±Ï´äÊ»È²|™TDt
ÐŸÁQ#y†än§Þ`Ì2±î´R$9Ç
§FÜ+†žÐ ´,sñWoµYYÒä	ãFþÊz_Ì¹zãËÒ™¥þâ•1k§¹ûü¡ã†Û6OKïô$Ó	uJ”?ëJ(¿]@w§GïüY;¶BÍì l‡xY7ÞÚ@[a¼§ˆYtÆ¨àH_yËŽWÈ‚?Š¸ŠZ&ZN'dÞpÝ]š7^êT;™¡SÄo |çNñ·S¿au§ØÆïjþ§z?¨+8K»Ò7EUÍï“:Ô­zg—N…OU*•ãÝí—„üˆ6‹1˜6ñÅOžã¹ÉðÜæ.Bƒ
„sÀùÂ:!O•Ž`Ü&¿¯Ö/¬¿Íp”|Ö×á…ÖCB¥‹¸rÞU^ãG
ïü~g¢ªC¨Ýó‚hºñ)M4v9JELYyds8Š§ú{¬¶>°d_ÙfP‰‹X­ÄŠñ5õ¤ŸÒ¶ö:;ûk¼ð´ñå±w2‚ùŸZÖ_oðÑ2!™ª¦žX[ÔÐË(`0>>g8wàW @Û§&:;ºŸWžQƒÆ±S5èhSñ~ªnžxé£¶Í•,v^ÉÆ¹óÑòÎ’;¢ønz³žIiyc#éŸF˜¾'·„'X[käQeV*YAºAµ^À#¸9ÿv2»³0…Ñì‡¶º¯Î*‘yàdw§wìØY¹òƒ]§á;PæÉŒ/w^0 Ã¶O^îìVÉ4‡úRp£ªêêi +´œqÝöw|r9hMß“±Àm¤sÿGÇ¥¾¹¯'2}9“ËÍ âð¬Å€¬Mm9¸£îá²q-qË¢!o	Pcë[Lv±jå¤­ëƒ.î”4‘sÕaÕOŠ§)àþú'…YÁ‰ØšüÑH8Ž“ª£·nóÍÙ’@•ø²i#œ¥ådúˆ=
ýú~¥ÀvqLƒ|Ž©è7^t{%ÌyšOÑxÕðpy›=|6«^wëâÁhs“ËO¼—|+?gÉQ±¨‘‘«”x¸çÚf£[IŒÂËôK­*ƒâ2OBV.F‚Î3Êðr{0v2õ¦ÏýcÝRüÝPH²ýQÕºÊ.©î§£—Èå4«–ˆ:Ãßhã…JA6‡ºZµO9è^RDh¥C€F7e960ç €âßnSr±ú€40þv3Ð.:ƒ~·`Ðï¬ÏŽ®AÏ¢&>–¤A{<ˆâ¡†câ¹	ülÎŠ ø‚%w,È¹œVƒWœ—˜çŽáƒñ"NçBÄßÒI”ˆ<áÝ¹ô£Éè­¸-Cr²~užƒÔÝÂ:WBßZ¥B¡_Î.ìEn8ùRêîÿû,_B®oJ¤K^»2‘Òr2ÑÂÂw»Ýýï_=—éÓo—øë{C€”iŒ…C’ÿ¿½o]oGÜ¿«ïË;à(™q’±$Þ)¹G}Æ±´§ØÇ²“žîôçá”•È¢F¤œØÓÙgÙûûkÏ‹m ’ EY¾ÈŠÓMôŒcƒ@áV(Tués2œf±QnÄñ 	pÇ1OÄ~r©%>@“7Pøw:ÛT SxÿÅ.*R¼‰!õãÓ,v‚hP8ÜL#/¥^G3\Äõÿç?ÿ™l2DÐÒÎšË@óé‰Oøâ	{µ”Öàÿýï~xšüúŠ&Þ½e­Y[›ÑVŸ›iüqýúã1Êáã™Ô»
²8mf 'B_X˜g$çÓUL,gó{¯	—…';¡7¹@í°Ïžc…çÛûïÞ<gW»ÂÁèÖ©lÃeý*‰™g{æèŒÇJIRö”Tñ4ý-ÙÌÂÙ|
ÒpkŽô&Rxi’wžä•m
Y×ì!u0*{?Ã)È¿”	´ç8-½Ž%¥¨Œ®hì™Œ×Ê^Í9Ù€;1e/lby+Âèï3KìÌ±~:‡¬#Lq)!È¸(É4ÏC¨0*Ns}R¬ Ø’â?E
zâ}=öšIó¥7"x– ms®ùé¸ÅÜ$dø\|ÈO5URLè4iÀ7¦¿nïªß³´„$^‰ 	Ò ®4ÂÀ`äS Ä×añ“‘©Á”¨&Èse9ì6{:{†=K…»²½Ú$›\	í€M%;¡#—Nµ¤dé\ª »Q„VB©“¡LcÏö‘@høœxŠ ®¡-0—ýË}'ÑÍR¯I)Æ…üò
þºkø,ŽQ¾P±ãž¢œh£ÕB”löY!ØQg-Æ(Â9Ûbš¬VÔz¶Q«='¿ì$zù<;ƒ"ééŽíÄP¤Å‹>ÃêÑÔEAès‘åÞ ~*=c—¸HKÊ‰'1ó—w…G¥s½©4ÓÐ1¡ËÔµòÚRoz1w³Ísá”9úÚn_Ò„JûMÁVÝWWûÿQCÕÿ?†i3ÿ?šaWþV‘j©€{H99Ç\cÏ=«]ï¢<Õ#8Ûžiÿ2†ü-ÄSæ<V;çýŠs—NHÝùÚ+ñuÛÿbÆ›Ñ©sm,Øÿ–®èEÿ_¶iTû©­PÇ„åi{®£S÷Y@U½íúŠÞñlÝ÷MUõ}üg³5k?f»´CÕŽÕö}ÍtÛ¦jêÔ×­¶æ†¡uìÀRlÅt¹vfkfè^@-ÃqtÓtÃ±Û†jµ¶j´]Û±W×:¾¡R¹vf—¦*AÛÑÓÐ¨­šŽÕv½¶îYº¨m'Ðt•Óéx†T[ØGP‡*ZGõ4ìž¦«nu\ß¥0ß³Ý@ñtµí›¬f©QÐ¡ßî8mC<Oo«š¥Á¿†î·µ@uÛ0•i´­< aœDÅ¤ïø~Û
:ŽãPè¥fÀik^§­RMUõbã²e\ 9V¨~à*¾î™–bx¾é¦eº°Úžã™ì!	ZÑ™¾k«ŽmzžëfÐ6Ãw]Çu´¶åhšæk®æØ–"U+ZÜµ=UU5§àØª°X¶Ò¦~GÑÝN§cP]5:ši°–Ù“¹ªêBoÌ¶ïu‚ŽMMjš€¶æÂ4zŠ£–¥šyXå&q¦¦Y¦Ó|=ÐÚ¦bT1ÚºãimfÈ²øì·}{ÖÌÚ*:,©¸žæù°¢&…n¶Å°-ÛUÚ6uTÅ`cÌ‚’-ñh`V˜ŽSlj–A;
€¸¶åšâXª¦ŽåÎëï‹	h#± £-¿ÓÑ• (¤kÂÔtÕê˜U1 iK H¶¦gš°•©ƒ1µ×õtÇ¢ºçhJÛµTÏ6×ÐæOÎ-qoØM±p@]˜cÓ€9€%Ò=ê*°àÔ·m'p\ØLìHOƒV
lÖ²m(vàj0³Š4°ÚëøJ`ª†gqpM¯Ø7ÉtSkkŠ©Ã‰x¦f;. £&ü4³mû0qÿgf'owê;¦f(º¦SªC¼  Z§Â_¥ci¶âÀŒ;…=–·,Îj¬­¡ÚuNÛu;mK……§,“kcŠPWÂ©)PKõ€N©F àh4O±UR[S]ö‡c¶SDžd.j ‡i¸Ð<µu§cxªTVøðÚq) Ž®¸ÅÉe&µŠz"¬j³E;rdë !¬ë*6TÝè¦êj°WÔ¶í¡¥rFr†ñ	DpÂÔ1aâQN4@EÕÑàd1à<ñ`¸¾­Ù®îyšZUa$îDöÄ=5;ŽÛ¦¶©u<Õ°}×°:¶Óî˜jGµðäu]-è(¾WS;IýçäÆO©¥t€\*šæÁ’8W…sÛ±©üì 
gœgÙôPÙ¨N'hëÀ¢Ëó-à
:xÂê®ã¸ºáx^ÛWjÎ™Wý„_ä BäIxÆÎ{€xlRè™áéHF4Ø>NCj9ª†ÔC1KÁjê	7+.ñ8ŠUfëè)¦Œ5­L€jÃ®vÚ ˆ
PmÅê8å0µ"LaúŽÞfˆšÔr$s@dÜ€ vj»£8ß¾æFÃgóJ½v ãµ=‡º	çTÛ6àøo·ß Â6€‰@â\
XÕO¤‡£àÔXu¶Œ¶¯bâø‡ê:ÕÚmÍ´}Øµ†åZ@Q‚@S¬ko´ô· OA6×Ý·\ÍnÛm¥ã¾Gªê{@E€©þ1ä3«g–õSÕuÛñè¾aÙŽJaX¾fQÅ…ÚS»cÙ¥0E'ùÉ?¾¨9eÚ@C4h‡æQ‹±«jÛ:À„c‡l‰rtRµÒÙdëàˆ‡	'¾á!©°µoÓ,Ø¿Ë-ßVªrÂ=Êð*ðGm*mË3m -
õØ®<	á 3aš®¨Žqí5b' |¤×1FGl£;LAÎ»íttàÓ )€ùÑæ«RÀ9=K3\Ï‡]nº¥¢x>&ð>À·(Õ¶UÅQÝGrowkçMo§¦û0$×w] °¶ARêÃé	‡˜	Èï«nROr˜@ä¥½‚6õà€qØnpdÀñNAbh'5“[«?¨à¾¤„¼Ð}·r¿iÎ¿ÿCyYÈÿŠ¦ë ÿÃ~3ÿ1ï»c˜þàò™´ì6Üÿº¢âúƒÜ` _Âú¶®W÷?«H¯©H¶øþô1IÈobàCô‚ÙÛ<ˆ{œú3é‰¨§/¶{Ï NÏ¡}ô"Å'Š(Ñ:ëXD¼‚“*v'Ó~ô>âK:A§ðµevÕD›<mÌËÂ÷MF|ïÅ4@kvNž†4z†( ¯ÉïÅÿ‹ñã]9ÔÞñqymø¸ÂQÒ4ºÃh*zSmÃ@yüÂºy0`<O^–YJ	+gY7‡ÂÙžÀ”³9#6¼ÀwÑÌ‚²ÜèáäWµa°o,|0	ÐÂâ‚ZúÇûôê`¯¡7•¿,u_c¬õ±tA1ª^Ì#'ã€`2c(üÂ,ÆæmáïÑR;ØH¼ÛÜüÜÒŠc’˜¼¨sÏ|êg6¤ô32nå–8õgf~ùÆ4áP^Ä"ÌbÚ]ô 1¡\Á.]Å£úy¦3ðH/€C\zÃš¸\Î]l4y›GÉ›w‚pÂ,¾àóEDÝö}IIBj™ÅÏaðX¸3§Ïõ÷öN¶Ž{Gû¯wÞäFóRI0¾¼UpnNXÁY'£Â‡	{›ö›9«‹õœ_ÑÍ ƒ9cá)ÁDÍ« JJåí10”·àžr¾¾à37J¡åzJ]Ë©³–öoÖ8C°lg#A5‹a
G„ÒªHf37 ˜ŸDÉG´Zò·y+ÐX—Á›µ¡’à¡ÅÓ©aEg]ÉÊŽNr¶z…6ó¾Ð1%Â›õ+ÃCNÏ+©\	=W>f€·CF#„æ°3ºˆYxv—&Q¬ò´%â±B›K¥¢-ÝàßWÒßÝRáÉá^Ú¸šÿWUÍ”Þ5‹½ÿêÕûïJÒÒ¶è7(Ì“2ûŸwböR8rLü¬1Sfñ)Yv9ú<”èîJ'ø¬ !˜4ŒàâF‰ªeÑCNmU¸O•Ìp‹þ±3·ì¶äˆ3³Ú¼I+¸½.F±ó™ÏåÛÍÃî[ô<µÄÉäêä §v×ÞOÿöþtãý§ù…»+LXË/¿’µ¤¤çŸvákÆ6}É¾8Ý|=nç%p»’Ä,{(²™±Ç—ë´4p‹M@¼bîê0³ü•Êž––•
çCKÞ¬dèf].ôÈ)~.¾E8É»’Zr’à!;a5Ól6‰»oæwËÍ c‰­ý7/¯;!|%^]oÈ’¬°½{˜.o*<|r@Ô* ”`ç'f8€0Ÿ€8ãŠŠÑcz‰þ$ëhŸó›'0ñbPÙ\¦U˜~Þ~S6*'äŸ/.»kì×#ðpžŒÖ–J=aý9cÍˆÂd"ÓÕ˜m3¨J'™L©pŠ ÔXýÉ è7§xßë5?Ñšð š7Lí®y>‘÷ñwÿ&Ñ©MÏHÃ#EEE¢}ßòéyk4ë£ñ]ãœÔ7ÈþõßðlªG­òrswogûI«•æ=\ôýjg»UÿŽ0ß¡MÒ`!•òþ)ùÒ0CºÜZ¼FãÉ`+¿}v&}Xk%íÝXtàåçó`¶£¿yp$6üÿ$@“»±¹½Í;ñå·­1…~À™ÿQ]WEø+P™q!LÁe@J;¹7I<ÉÅýKÒ8¼üNxnnçóš´©Ö/×ºâýõ`×Éw°J’MþšXL¤ÞÙ
(¸TÈ[Š·š=MJJ<û:(T T¼¤P‘pIåOç–—
¯Šä-+Í¼(±
õÂÎ¨Ë…|Ï‚Ì\!$æ3… S.$àûHúºù9-L—<¥¹O~½Kí²Äà”°«ü2¹”í³xvs8„_aÀþöR÷FÝÌÍkfÊ:©‹ï‰·Æ×¦–ÝY'&ö¢ÄŒ»Ñ`gáñn‚Mdä&‡#zOÀçyæAAº3î1—ÚW'é‘´héÁ›Îv?d*Ø-¦ßÆü;˜ÒLnæ‰_2óÈä#ÀJLÃ’¬a³»6Œ0èSó9tÎ‡á¤ëLã0-Ð]ÛCçW{{›G;Ý-‚…!ù±±i¡òRnú=Ã¹ôäKÇ8œð.ãIšñ¬²þDCQgö93mF3éˆ@I™0âå»–ùŠžŽù‡é8Ë,æÄÐ ÄôÀšÊÕ»´ÅÍÑ³êôfÕ™á¹Tpêf $TÎ D7ƒ‘YªK >v×rfâ_iË²Æ§g_·3ðúpæL.’nÍ ŽÐ%)’¿ï`iˆ¬lòùãò$óþóAØ];äˆ Ðö­¯ñ‹éý—wgZ«›ÞûHåjÞËmcþ‡f›Fªÿa™¨ÿaê†RÝÿ®"U÷¿e: ’ÁÃ7x,;I¨nƒ£Àƒ¾þ6¯ƒ¯u½ø5®ÏyÌ]vàú1?KüÝ„ìÖ’\d1ƒ ¥qPeô?³Ìº¿3f‘ý¿nX™þ/TTÍ¶*ýÏ•¤ÇŒÜKÁmð|P7ò.UñŒÄ|ç³à*èÈóô,¯—f<s“]Å$™&Ï<”no’OÖ†ä ˜É=¨A¥×Éþ.þØîíì¤žkn¾c¿ö,?ÜTnX¹Ü6ñÿ†Äÿ+êÿ–bUû©Òÿ–xÿ¢yñÃäýçh€—³ê•xÅ¿ß¨³¿;¦ü~ùço=aøìûnãšö¦fº¥£þ§j)zeÿ·Š”Ùß_7_]Ñ”jýW‘
^zî¥[¬¿­[Õú¯"å½âÜO·XÓ®èÿJÒŒ£{hãæëohÕù¿š4ÇÕRÛXpÿ£*ª]XÓ@ÿÕýÏý§Çy#]”–Oôi(Ú‘O‚4rÂ  ¿àÃÆÿâ3ñÈ¯ßañQí6³ÌZ0@PÇW­ö˜jµü8ˆ@qæ106´ÝŸ8gQ­v°yôC÷	þÜxÂB]5¹)¢;‰ön”Ø@9¦Ä}J½™•-_à0ë©M3ï·¬7Y']R¯§½'$YÕ ñ&«.—"¤YV¾ÐaDY®w»sx¸ˆ/µ‰‰5ëSiM˜,>_‰OâÃž¯A¦WT¯Ng'S²®#œ(œNxÜ/yÒk+W:6´Tî³o¹m\÷ü7TSµUé¿¦UüÿJÒŒO°{hãúëo(ðãÿŒÊÿÓJÒõ<mÞ­üð|z²þè­Ž(š¢é•ÿÿ•¤ÇÿÁ8 äÚ-ïÒýÑm^Ýâ9pÉ}Î=–î„Gw{|tå«à£ùÏ‚fßyôur9=#t}éˆø"r Wæ¸|T|%äpnø¬÷hÞ»Þ’×C~Ù{´¬§½¥ö‘âFŽP’sn%‹§þ`Â‘”gs¼	×“f…ùfÚð-ÇÀå	4a¬`1Ë}=mÔ“*3Jmd£TÕ-­0(+$¹Y¹Ä+_s%X3Ao,ÈÍ—ÉÇŠMÊ`n¡\.îmZŽÛ/¦%·w_o¾)¶Ês³R(`mÏ”â¹_Øòå­q_áÿEøý#
Šø5Y‘dUŸ§NXOŠ£“X”½Ñ^&ë]ñkÎZ¦.¯CR²`÷%ÉúÎø€Yëð	—ó#é›åä#3ÈÛ
G#¦ç%—âsœ”Cƒ“—NXÀG-„Q;^ä%Y{tôýõ·è$ÆëDfQˆ[HMG¨ëðáü¬‘¨OˆïÂIóQ£ù¥Fac<	ÏÆRÆÁ$cs4Â9L¶åR›­F¿¶[ô;´±€ÿ³u=õÿ©é¦…üŸmWö+IË—cùæ ÿCæú~žF/‡#B·ÑcB‚)üðt.ã·íDdo{÷%ðN¦æòYîž<*j‡9Ó –oÐQ“¼ ø¿ïLòÑ8Ö„3àgÎhŠfg@pù ¤äø 	ŠT\éú¸ä7Ð.o“ÙŽ9/häÂ¦u§À’ÍÑöðˆPÜð d9:à)6æÂãrÌwk7º„rìÕ ' Æ3Øçk$ð„A<¤ü¶šŸ|¢ƒÐ¨¬tb
ˆá š7vG>ýL0fôYHûØÑ95öB'€>‡…:šPŒ+]¨µ´iöGÄu“Y^‡ßq7o¿‰ðw®´ù¨º€Ú­Ü T¢ñþ¤ â^8*|—eÆá¸ãG/è3ž°á¸Ï%ÂIß	ßŽÎ0ik*1äß½Þ›¦ª}9:xûé/½óéÀ÷ŽÿuÙ(8RÇÃwO¯üì÷Õöøcëôã§óŸ_ö/üÍŸ~Øß9Ý}ûñpÏù¯áÎ¹óv¨L¶^]^~ú±u0™†õ¶7¿zÑúyÇ¡ÓÁÞÛG5o´!¡b”ûK&q{I™Qx£0³¬ØÈó ±¶üíA®‚"Ž8Â
q9kÃðc|:	§ýÓü=ˆ7ˆ'|V \Òü—þàœŽÞ0¸èÁVk²…<fS+XÄ‘ŸÛS·B£{ÚçØÏj£/¬5Š/§}VþRÞi<èÃ1g¼Á|ù$bš,Ð7J#~üéÃnKÝõzüú/?¾ûéúiúãgêöí¿ÿãÿˆ/íŸGö‡‹`{çôèl÷‡áOïþ¾ùö¿FÑ§ù»:¢ý½ö§W?Û‡oZ?7[¯[½¬³þø¦ý/íPá4bš¡q”ÿóJ*‘/7gƒ/¤8Î,Ò)?/Ñp€½,/ÁWµÌ˜eOØå%ÐÑ…1r‡[W—™Pd^æº@¿4ÇÎé
n÷aC„—./ƒn©ÑÅÈ›óy€n†ð’ /@@h(/öáì3à é_Ìÿ>Êðëó…<ƒk\Q€ó­åÎG¼˜;Q‰wœm:D–ÁYÄòRünƒ­š3¯3¢Lt:1{i¡òp—Þ@byæO³ÕoCò¾ÅÛ“o?]3€ÝÚXpÿcªVjÿ§*{ÿ3l­ºÿYEªÞÿä>ç/ƒJwÂ×¹
Ò”ë\aÕ{ÿƒCå2¯â(qqÊùÜã³>Ež¾9{ój2ù)gÁxÃxð ö1"È(¹&r¦AúÄ8‰y˜ÌZzÕW€ Ÿw:6ÅÃ_úän¨ª ;õE,þ~q'»C†’lÁ¢p3qqÆ‘¸1L‰~'ú1&}Êp¦d€€§LÂc(Âö7{•¬‰>²Ø2ìÖ¯IÞ˜üÄ±åÄu¼;ŒÊA¡hŒâ’`TÚTCÉ¯é!¢[·OX-^'zUË¡0‚J¦cÄç\ðù<Ù=Íå®Hâ%ó¼Ù­·Âq,BÅÔgŠà»^·^ðùò‚?õbÄxUkjMµ	ø-×•^ñÊÃ÷Ë¿ñG·RÒEGÉs ”v/S rÂ¼jJýLË=~3k”B7Ð7&zì”`¤‡]RþCWÕÛBÙ^o¯«ZºUÈ>Ü9è¶;¬´àfÃàŽ»'áf·îò)&zÛÛyônóp§¸lQÄÑ¦užáDk¦Ö	Æ¦ªÉß_Z¦¤ÜË×ïrÅ‚³O%¥ŽÞnçJÅç~+vê:d7#u)þÝ-÷ä˜–‚EÁRBt™üE¸+ØSEéÍ—ë«'òUZñÇôŽöwnˆr>F3 fýÍ‡ÐK½³»õ#îƒn=ù-.B­ÃtL?„Qœ5ŽÏïÝ'OÓyÉÓ$ùí7¦uð$Ñšx†gïc Ëæ`¨]¦\¡Ös¹ÏÕò¹:ÏÕë²œ;ãn8]‰f)];ØøÚX ÿf&ÿÁƒ½ÿ[•þçJR%ÿÉ}ÎËsvÂCVRYðßÿ—¿ÂlN#øýt‚Ü²,¾pb¯ä1ÿÇ\„@¼é”êˆf†õãì•Ÿùš)Ÿ5¼/mnÊ,Ë`ÜL&$©ùA6€Å#f«Í[ua$Fu›Bt2	sRÄÜLké)€àrI‡XM*Iô–}üJ²ˆ‘ŒÙƒ
¸ ¢¯Ï:Ö9
<–pËù$‹IÊ¹'}³ûj.,Ä»:‡$Çã-‡%ôvì½‹ênª·›ûý©î.Q%7Á‡|©$7+—­¶\.Ëåê»¼ì¦ïf˜ûDì±W‘:Óîëö´…J²üyh‘ší¸DÅ6qƒ?«Ö;ã ¿T¥W(µb×E¢+÷.ŸŸ<‚åô1¥ä×`Q	øŽÃœQÖ=§ŽÉäÏ4°@ªtG‚K4¬‹+þ;}šº&ÿ'àü¿¦fÆÿ›Èÿ«šUÙÿ¯$Uü¿Üçkðÿ]˜ŸAdG¨H!ã_T&e6ÿÆŠÁsÄ¢J5øaÇ…¢S¢ÂÁA§Ë„³%K>îÖW¥\š=ÿõ¾éNPOëD˜FÝép¡ý·¡dç¿ŽúªªV÷+IÕù/÷¹xþ—ï„‡}üK€è4ˆ÷š_¨ƒdOnØLùñ/ ÀQ5Ç9ÖAº²Ãþ|¢
Y8¾Ïà€ãŸ˜Æ$g&šds‡Ïoæ ç2¤&>Áù)Ôr©ÏUi\ÝÇÝ¥Õ}ÜýÞÇí‹-DƒOsÀWÜßÝÜuï¶›¥ór=Ø÷WöxÑýŽ†eaRÒ9áa™l¤FðÞpêÓè»£Izž]â0öÝm¦íÏ,#RÃôA\•Ýqõ²ÜqÈ AŒùº+šáÿ4õD„\bÌÚ(VïYÿW·3ûoÕÖ|ÿÕ+ûïÕ$‰ÿ[Þ!sîïÌßR;œcýTíDŠÌ{âø>Û	Z“ÍÒC
"ùþI·¯PÛ^ŠÅ\úÈS`÷nÎIÍc¤–º0Zòç”°‹4 6q>àÌ‚J€YdƒL÷.±ñå±G×æŽDŒŠªæâcÝ¢ûÂù(‡%GJŸÃtÜ”ç¸æsà5^¥"*)2%,7WF+-£e=ºâQñÚoŠrÁÃƒYX˜›»úåñZLWM”ÊÎÜÜ¢!ë˜ùÁÁUäÓLÂ3þ»V_ô'Ã“šy_ãïr=î+–orIž4aIñmÂ#R¼3¼NîC¡¢pé#yô©	@ÇÀ¬ÕŸp]Ïzâ$èªç½Z.(xöÌ7ëŽ§v“‰ááæIã4™hh\F^Òáe÷xåÑ²gù?­Èÿi+åÿTóFÅÿ­"UüŸèpÅÿUük¼âÿ*þïóšÄÿ©ËäÿÔ[ðÚï‘ÿSÿ°üßœ÷ß»(€-àÿ¿”‹ÿ¢a  Šÿ[EšYU/e}ô;‹ü?(f¦ÿ‡së¯ÿ¿’Tñÿ¢Ãyþþ&xøüâm†õgÎÐuÛÙLŒç¼+·7¡O¿9á[ý\ÉN–ÐKËè¿Y‚Î.X^Ž¤Ãq½~#~Y´‘Hj^~Pœ3·æP…ù€ê%vj	ßÌ.]Dÿh­´v%h­´4˜©Ç¸Pè0Þ›N¨´{Ô²:ÚÕu´rÑ§TŽHå¡+‰ˆ·)õ‡$Sê•LùË”UúvÒµâ?Üïû­˜Yü/Mgþ«’ÿW’*ýo¹ÏƒA|[Êßù(`“Ì	ù]:Ì‰Šq[‡eðf@]ÃC©÷†@¥î*ò;ô±Ò /h'A¨ˆ#9ãá¤/Ae¼ÞÉÁf¯÷nÿpûKLúQ·Ô$,ß?bÛÀìÑïˆò<LQ÷ÉSà3	s6àî:#¿AAÒð=Rßlüì4.•F§™A8ôIãQøã”Âº5FD}–Ã¾þ=}|Ò§¤MþügX—¨Nº]òü öëó| /fAcE~Í/Ý…\æCê d’¼fûC{èŠ{2pH÷{ðòU] ³,³}lŸÃÆ€Û³ð×a%!Ã£>l1©­`À÷Ã‘h€¾ã~©Ë°ð·}æî‘Ø6—ìqzÌM7P*	²-6‡{ÚN°…lÌÀÖ¿—àó)F÷v¿9Õ6óÐ±ZT_î´d+	È\Ü%Õ
¬`å‘€1WøYSfÇÁíý}ñúî:N:ïÁ´–d®`¾)7×›ÍòÝÕ,Ù›¬7Fñœã»å&.m*·5·L•ÿï2ÍêÿêEýß»<ý³t#ý_ÿ½Òÿ]QªÞÿE‡+ýß‡ô®_éÿVoö¨7ûê­¶z«}ú¿âfˆ}tÖ_,ƒÇXÄÿ¦•ò–®EµuE¯ø¿U¤e›E–ow xïÅxùÃ£{øì‚˜‡èkr{EfO`<Ð…ÞkÀøÕ2xvSÕšŠQ`ðæpwq(:KXgÉvxæ¾ŽîAkjÖ¸É	#$Á>eÎjd®ï<	üSóÙœŸ0–Ž¥.ÔjŠ²Í>Ÿ®mï¿ÞÜ}Ã"­­“:#¥'¼^ýY`Œ6WÀó
´¦ŠÚâÕ¢ÖŸ¢:ù‘zñ¬ÆN 6€â`?-Bìp¢!P[QÔú³¤r“úWUîõö¤úZVŸ]ÈÎNv×?Q–vàÕÓŽc¤¯¤n=ÿ üQm<Á­qdg[WpQ¿ü)úu­0ßŠ$Ó<S +Î/ÛÒ9ÌŠg³[,W’¼F±´˜Î¬Âq6?¥àqþ²ÒéSÖœÒ8cPPUƒw{½„ðFxÎS>Þ½Pp:éTKó°ž{Oã)Y§lNxµl>®ª…˜"#dn^®ªˆ3õFÚ\Ùü,ª•ÍZwfž–ÄU}íÓzùiÖþgþÕÇmÛ¸‰ýª«Üþ§òÿ¹’TÝÿ‰ÿ~îÿ*ûŸÂUVw‰õ.ñ÷íKàVö?Ú·ÿIÜTö?÷cÿSù”¨î”_›Y­ÒÒÓ¬ü§œpÚ.sÀ÷ÿÕ6³ø*È‚ÿU¯îÿW’*ùOt8/ÿÍÙß€ð7ÀØ
Î01­q’Ã9*(ƒxß2H%ä])äM*!ï(ä•,¢üÓ´ä3ÁÐ‹™a‚^:w’ôˆ©¬—Ó„Î‰{™ô>ÑÏLä+oA[ÐBQî›#øeëtÑïêZ9áOU‘cùÿÍyþ/_Y t "Î|tK¹¯ `§nŒK­(±E¶l:†Ô6w0sûýÍ‰n×²ÿG«ˆ;ð˜ùEŠÿª©Œÿ·+þ%©2ù_dòÈÿþ¹u<d‘^”#¼fÖÿ/èhŠóˆÙfåSë§‚YÑ¬» h ‡}:Â˜r¹¦ào§•ÎDÏ€{§»Æ—qsÖ<_
+›õûÌÐßq™5&üÍ­øG%füsÆod&9—ïg*²Ô bîº™½&W[› ]ÿ õ¶ñÚOÏãlô‡¡ëž<3HæÇs"&È_i#Ñš¡ûzâáÄ4\zêœÂÉ†ãytWîÐÇ%¸A6··	Ì2;ü1ç)ˆš;‘	6'BÄ](¿³PÖ`9RôïMÝx3Ö`{Å§CŠ^ íÑ¯|ÇðÉëälJÙfÁÍþÀ;Õ`¢Fdsko-‚çàþJË|Ù¦\ê°Ñ5ÑãI8lÀJùC:IQ¹!ŸˆÝàxƒúS8lû4ºïëjSk¶¥©ªºiZMµi4ÛŠù¾þë?Öô;âxÀdÖ·1„Ó¿b'àQ:ñ8uG8ubÒD+„÷ò}ý;dtÃOOÂû>Òw½@WØ:-Øü	°uøEÛ~áï|3gõeâO†>Ø™
¾þ¤3¿J¡-Æ `™;Ëÿ—†w¿“°Ðÿ—¡eü¿ñ_TÍ¶*þ©âÿ!Ÿç ÿC– ’ÀÉ×ÎNÆ#Ïð¢÷Èø?d¾.Ûm®ÿ6LÅó¯žçí†ä‡0>òzüª60Ÿs$W®bºhgñ~A_AÃÐs†xyÊ[Ø96#·¶Ï–’½ÃmÆ@ÜiLÞÒ	LÚf·u“6o†(Ø—q|âqD—nÐØ`tî~Ã½†v/F±ó¹¼Ü˜·¹3’ºú:`½à'†¼k¹vEwÛR€â(u¹“Œ´ÛhŸ‚6Ð_ïÜñØG	á -uq$¼;…“BÇÒü\ß²\Þ½C-íÝ«ä{ÚAd\S €ÎÇ‹³…¶6¢1õÎp£qò§çòxÒâ|+l8Ãñ©³a¬¦g€3Þ†¾žÔÔÖg¿‰>è7tJ‹sÇ„1pÄ!q"¹z$¬FŠëSº4aä¹àqÕ¥Ð2áôlìÑQ?>m¼@WzïÓÊïÉÛ¤Diý7¦²‡TT¸ Ê€ÄhxÄ(zF7ê=|÷Iï‡Í†šë$ìßá4nøb/l(QÙç (0°o¦£xCŸÅCìYC^q$`å²g°‡²aõé†mÛð‹W¶I?b£F€E0V¡N¡åÆ„þk
çÈVÓ	ÙÌð.Ý|ÍG©„G¦nPG¬¾WaÔ­0êþ‘…¯?0˜tÐD>OÜxRÏQ¤ï,ëæýÐîŽüÁ%ý’°#´á»ÐaŸ~ìR£28ÊKp2˜0|åÇ”oÄcº#€/æ}ôŽkš÷=šºp´Â›Àl~L¼4“×`=ú+r˜ßóîÁà	Ù~`a€ÉœäGGÓ…(÷ŽÙoÐ}Ýºœg¾l¾hâmÐÿŸä6èà´ãr¡J>e÷?ÀOÂ¥P¿ÅL–—ÖÆ‚ûÍ¶ÿï&÷ÿ¥ZºªU÷?«H•Îgr¹8ÿ@Õ;÷’IrR÷J"4ºAÝÉ4‹×6Â£V¥ØyÃ2#úÉC‹ËüQ‹½pgÁH7£!hÂï7©%e4üÓ…Q<ðî å¦Ue×¬î¿¹;æ)AoäÕáþñËñÂñð‚#°Pdœ!Kqå”~^°_ÏÞT„Ù_m»6ÿä|Ž€/êšÊëÚ—ÚmçÉç£@Œ›wûuoç6ÈHãvPÉÂ¨AñÛ§ù’núgQi˜G¯ÓvŽZ¾ÛNØ7€ìÛíÖãŠEà+À€Ñÿ¹çÿÏ˜ç¿j«Zzþ[¶ç¿i›fuþ¯"-Z
šYqpÃùà\ÀÞþ«TXÆ99qïãtÌHs.Ÿ~F|žÍçÊÄ3ùtt¾€¼/¢æ¦DÍå#ÐóÛíÿ¹ô—I4f!ýWŒLþSÑÿŸ@EÿW‘*ù¯¢üå/ïàï›òó$ë.›õgiý×ùµTU·ïÿ[©ü­$}kTû[¢Û[°£>„.yYÑé{¥ÓË„Ä¯²H0	'ù$˜äd:ÂçÁD+p‰€†¢vÈsø›Ù‘€öŠìÐ@Eé ŠNI#&/÷öHã‘ÿoáÄThz§ä{p„}×¾ÿ³Z[êÌøÎ &f0ò&ìÝÒYÝüd³£¬këúº±n®[×›§Ý7[‡;¯wÞm~éâÜÁJ¦HÓØ=Ÿ;1‚SÁ‰Y4_ûTªÒªRÆÿa0¿OÃHxþ¸£ö¥´±ˆÿ³Rùß0,Ë@ÿÿª]½ÿ®$Ý›üÿ€ `_‘'kp>rƒÌ ý•åzž—$NL
ìä¬“¥ÓTì&)òŒjS)2Ç#àŸdÉ¾÷ZxêFeÖ&1]@?Î¼x˜¸èÀað(Ù0ræÌb–Ž€›#ð?‡$´!ëŽ#õ‰hw2N5m&¶ªÐ­'OYOŸ5É¦ÿö Ó€Z'ýI,vŠŸBanó] cÉÒAÜ¬=Î•föp”aä_«y#÷=šú!ñÆ³ËNZÓhÒÜ–¦ø·Uh@ø^aðyÍ’J—§€e…©ŠX9½O/œŠ¯ßŠ/ª/j¦ô.–¡’3g4u†WX¥Å ÃñÍ!‡%+Á W¢Ð;XûéÇ¯µmÊêbp NGvãY{çŒâ¨;¢ñ§pò±Ém*k›AL'ÅLRûEì_kGcÚ@hUuÑV¶ö
w,ûíTƒ™îøîÌÃvmç3õþÍ~k1{GÝ=ôç¾Öxáp\RYZD¹øÑàŒ†Ó¸G½®®(5hfä;§qVâ/^8ŠBè~òug2	'Å0fAB~e3EýÝ³é00Üdj~Qòü¿ <ñ WïêôEJ‹ü¿h¶™ñò–mVöŸ+IÕût˜Ãýz©ˆwˆÂ6A<qö¬Èë16Ž}~º†¨V”Ed.c:Iï#†Cq,ØÄ~žþQNàÖ”Y‰-ùR2eD= 2áÙàò¶>9´°>‘‹p
lÕa6áÍBSáeêÿÇMhX¸!xï ƒ†Ó¡OFaì4QÔ_t&P7^‹`6QSí|}tˆ!_—´•ãÀ8ñ´ÚoÂ,“&º”=OBÄÁ&oóè”æ‘3)D Ï‰øK?Ð‚Î9wCÖ Ô2ÇpxØ¥Øéæ×moïdë¸w´ÿz÷çÍ£Ýý7 ðRadC‡Üœ°‚û‡›[{;ìÒ,‘;x$0lG9ØÏLYO¶b„³Ôš*JË…N ‡)ná$Y&ƒ	ã¾ Ô¡ØöæÑæ0”ÉH8:@gg=½i\Ï¿G)´Ô#ë£ÔµÔ•éÜþ%iå®3Å€·~<>HÆ-A7Æ‹aò‚òª0£33¸`~[gßÒOÎ„Ê _¾~—€¿hÆÚ"¼¿o¾Ý”;šƒ÷™œÂŽeE“7ál)Ñœl‚š¨ç”‘¬ym&×ºÌ®µv8#z´u<äíÄaq=°P‰`²2Á	%È¦@PàÌp1ÂqåiKÀñðZ*%ýkéÿ¾º¦¾{Êóÿ‚ 7'Ñx‰m,àÿUçü¿fº¥[Lÿ×ªøÿ•¤_vÞ¼Ú}³ókíFc8(­~Ë'uÕ¦Âÿ«ýòjçÍÎáîÖ¯µÞÎÖñáîÑ?NŽ€VïôNÞînž¼þ'†½ãô·ÑœáÒô«t©Lþ_¢èÏÒ‚ýo›jÿÁ°-…íC©öÿ*R%ÿçåÿ‡,úoå´?ÎM°˜ÎpàDìí@>P+8Ê‹@L®9ÞNï…£ÒK!¤Áoø
5¼À§ŸÕ—[Bq;œÆäèí6sÆ0:ÿÝ,ó™îÈÛ’¢y›.ÛÍÆÚc^{ød¾Ý<ì¾u†SºÄÎ
õ–ƒžÚ]{?ýÛûÓ÷ŸZä—Bäˆ_ÉZRÒóO»ð5“›¾d_œnÁK;w¶žpE”S¤ì¡ÈÞÛßÚÜûr–n±©ÈW,yŒçr”Tö´´¬T`8šf%C7ër¡GNñS‹ù˜L
Àáß!0­à!;‘5Ól6‰»oæwËÍ c‰­ý7/¯;!|%^]oÈÒeÁöîaº¼éíÁqµ
(%Øù‰yx›€œ »`‹I®tB¢1½šàeû,ÏÎ˜x1¨l.Óº‰”÷f[óÊÊ)ùç‹ËîûµÁ(<(£µ¥B;Ü‰Ew¼Sv›”\êÔ0w€zÙžìíöŽ¾ÔñÃ¿iÀêOÝz“H;T\%õ3q;ødP¯ùáˆÖx%Üõkž_ŒÃwþZZè4)$mçìë}­ËT .}mBfK`¿r¥pÍ–‚Ü\)ÜQ³¥ J¥Å§eƒ*ôz0œ[(Ý'RiïêÒ|få”ä¦Œ­HöÙqçN{±è ´h®4u)	Jg­?î®õiÌ"Æ§ê‡§<—_•žà½Xò¾ ºâ)Ž“,˜ª½- C{{ pv·Èv›3$¿±39-Ôì®áŸ4ŸÃ6ñÂa8é:Ó8L”ƒqÓï`OÒ¬ˆg•A‹†¢8Ð‰'Ï¡31zlŒ€§KËdØ’ŽtbbpŸ×	°š©\ÂÉ@VÞ¬:Å·n©ú„Žo@Š’’A‰nƒÛÑ7SL@œÂîÚù ‡<H0bÇM§
þœŽ9ZLS¤˜3 3»kgLÁ¨àÂ¡kFæb)uÔ(¢
qJ1Yxp¡¹¡ fÂeNBåžDÓ³¯Ûtr5=;s&I·üö©æá«ÌM"ìEYÌ,¨÷Ç]NçI‚%­ñ'ãó5ãÏ±<˜œÿ×«†³¶<Žoö*ºpÿ3qP„SÎ[b‹î!wæþW5ªûŸU¤Á½•À&>5ï^09>ˆ5d	Oú\ÝK<|íÞWé®©\ÿ‹	FK»^°ÿ5)þ/~¢þ¿®Wû%©ºÿ-êe¸ÿ-^óîW·Á×Eê6xé·Á×º]ü·g„<&1a×¯È7™{†µøŸÉB…ì^uÌgÎ»—}Æ,âÿu#óÿ`š:óÿ`«Õù¿Šô˜‘|~¤°³Ïu#w°só5ž¿·½y@0
2æéY^/Í4x&s–˜fš<S
’œ~²6$C1æxµH¡ô:ÙßÅÛ½’ØÃÝ|×~íY~¸ifÿ7O¶w^nï¬Œÿ7ÌÌþ×´™ÿ/ Õþ_Eªø‰ÿ/àþåÿçX€”³ë·° )J	H‹?*ÿûcÌvš÷•fÎÿ,ìáÒ\€,8ÿu;‹ÿ	¬ ÞÿÛ–®Wçÿ*Råÿƒý3håá ·ðrC aÞ‘IÑˆ|‚×Váø#ÙWë)<öt[»§ek}¿~?Ê±«v®?®ÑÒ¼\ú-€Ì…]ñ›7î`™ù:ç~¼HÌmwÿ`çÍvï$5‡ìÖÙCÈÖÿ£ÚYçDµ´V=ï$KšÜsÏ YÑMÐ-Ù3ÈÜ:á¸XåäPÇ¿V¥	å8ŸT_žs‘æ]DòÿHÍÀñàùò&f,…ÇXtÿ£ÚEû?[U*ÿï+IÉ“]ƒ<Yýáé›»J»]¼Êí‡å^	=Ùy‹ @ø*äG¹ ~àErì£\$ùÀ‹åXÊ$ ²ä-åÍƒ7"@	â‹ÜÅ‘{|˜ŠÅº}~ADwk>,’ïuaâ>bú:üNú5ßÛ ifM
ñ¸8é;£Ä_Eî[¢7ê²9Z/ƒíA	þy¶z¡%o¸Žb8è$…|@C8ûçBæŸoùk¿*U©JUªR•ªT¥*U©JUªR•ªT¥*Uéwžþ?h¡-| ˜ 