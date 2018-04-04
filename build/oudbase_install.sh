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
‹ CÄÄZ ì½ÙzÛX’0X·ƒ§8E+Û¢›‹$/Y%§ÝMKtZUÚZ”íÎ?¥†HPBšØ )Ye«¿¹˜—˜»ùæQæQþ'™ØÎ€¤dËYUÝfW§Eð Î'öˆs'íß}åÏÚÚÚ÷+ú÷	ÿ»¶ñˆÿ•Z¸ñøûuøß“ïÕÚ:üñøwêñ×~fù4Ì`(y-lÍ†Ã¿Ë<Ì¿ÿ ŸSØÿt68éMgy+?ÿ
},Þÿ'×Ñþ?ZôðÑ÷`ÿ=Üxò;µöÆRúüßÿ{¿o#
œ†ùypO5ïîÐŽ³ø"Ä¹êüØP/fyœDy®¶£‹h”NÆQ2Uÿ¤z³É$Í¦jõÅv¯ïôÂè,Ê¢8ŸfažGjãõ‡õÇêÇQ8žf³³³†ê]ÆÓ¿FÙ(Lw>èýpµø³©¼“?vfÓó4“{Óh&ê :ÏF±ZM£¼®rzÖJéÙ¿NeZýtowñ´úmøq;œÚ~7ÖÖÿÐZ{ØZÿür]Äyœ&ôñp–MÒ<â¶/`ëT¯ŸÅ“©š¦ê,‚Î#'0ð¤)¿
s•EÓY¢úé Ây¦Ó(×ýŸÃ.åþ‡q2ºR³<¨aš©(¹ˆ³4¡-ƒ¥?OgSuüf»	]ÃO4Ä!lô†ÀÎ§ÓI¾ÙnŸAËÙ)Î½Íë‘#¥LÃîwã~”è)üx¸Û|ØZûç»ÛL€´—âa°øšG‘‚Á"ðj*˜2ìÆMˆ~¥g4ÛqšáòÁŸãpŠ-áýó09‹ò;`SmñIÇñ_¹›Ï…} tðzûäèààød{ÿÙÊGçÛf³Ø2=ÃóÔJ³³Ú5uÞM*~áµ¨<MÕ›p4‹òÏœHð¦{ÔÛ9ØV»Xom´6jÁöAçð°»¿ý¬v|ôº[SË>÷ QÃÓQÄ;Ãád È/zÝgµ—ÝÞm ]DÙ)4@	83½­£Ãã“ýÎ^÷ÙÊ*âq´B­¬Õƒã½Ã“í£îÖñÁÑOÏjíéxR£‡/wv¡Û•^ƒë¶ÿzke¥ôŽ;GÇ'¯ºíîÑ³}C"ÂÎÂ.­|tz¿V«o¢Œxå£¬ÚuyåA-Øëììv¶·º½Þ38qÿšf!»Vÿ<è=[^ôŽaç€4ˆçíAtÑNf£‘úô)êŸ§jÛ`ou^‘WÒ6p‘çË6žA½œ%}Ä½ÏÅuws(ãQ¯óð,Z­«EŠ»ç“QxÅî°g\hƒª„òôh;ÝËÏTmgÿåÚäNE„ø¹y~‘©f¬~Àƒ¿³ø³¿Õ}®šÛêàïƒí}øûWþûÁeš^Â	y®~©êD©æyÕÁ Î½  ^_æ¼}QõvÅ¡šózVõzÿ<ê¿'
E“QÜ'Š5€3mûÑØzØº©úÉ³í8‹úÄöÂf“ÍW¹r/à‰šÈ#¢7sÞ.í
~à‰Ú]õÞnzF$l¶z÷àG$$×Ü.ªŸááúµjžMÕšúå)2ü$ÐÓÜEaÒIÿ6¦FíV>n\ÓÏÑ˜¯nW ŠÕï¯)z>ŒƒëàN¹_å‰Úc¤bR6Ç$½Œ'_ãtÓj¯Öƒ4¿ýÃ×@?®·ùàº
ùè"mø>R ÀfWp’3uÁ?^Ó>tXjuD5@BƒU¨€œ9b}n(àxf/jðEÕ€ïìuO ön@VTµþî§æwãæwƒ“ï^m~··ù]¯VúÔyõèhþ«É’—‰ÁÛŸÑïÁŸkÄ3œWk5·ÁþÝkÐªøè—¢<ì[Ì¯ÏCÌ½®©gJdƒâ!ÐMµ±¨-õ<µ žšú4Ñ±:çÐ¼é§Å`L38JúÏü<NÍ·Ës<ï4jìö÷0^ë õº¸íÌì°
—Î®r†‹ÁyM™–g;H“¨L“îpÛž?¯šÓßÙêWòæ‹w×tÙG—	 ¤Š$›¨ÙHà¦èC<½cYh£«•dÕ„¯#6Í×ê†Ç"UÎZ¬]2µî4J
Í»0EµRn©· Ÿ©pœÎÒÃìl†:rÞR=8T3beHÖûi†r(’QËíbã¦]hÀjYyý¦ð/…ïJ!$& j Ÿ¤SÚÐÙ)“Ç×
º‚/G­Ý®‘fN^tz……ƒ…^Ú+½FýäÑ” {Ã‹0¡´èÍg}}ä­t6„i:ëŸ³ˆóò–ý`Fi8PïV>¾: ôh·ô ]p—Î·——ï²š>„‰E÷ýGKßïf¬g@ÒƒÿúÒÙðë´»Ù,IPn£P?ÃÄ·ñà¹#’;P …ühäYò>I/50bùôjÂû×€3Ð°Àðþpø½8ÏIh+îî¡¹	úŽKÖÂuDK’ˆ)î+X²Q$Ë$i R9…æÔyøüø†[gùÈÙ&¤…©x]Àèh©Ý­EËÊÐ.¼Þ†omhŸWÕ¼ñ/Ý9? ìív%y*§Z¯“!.Ø?þ±^Ð©þ4Ë§ê2L’På mœ‡£Qê˜YJ0_ŠÒˆæH¨Ml¬­?×%¶åé(§ D¨0µ2¯Zq*{ {ir6Š@¥³>ßê`¡uÎPš…}xðbvæBG“šg›üæƒîtU7n[3ª_vŒ¬„Ö/ÓãÁË/7û°õh'‰§q8ú2*@bT7<Î"“~ØP8 ¨–fWþt3þ|Á1`ˆÍŠ<£„	­ªVe¡ØSÈ7ÖF>Œºš±CÇføÄ»çW}ú¿ü^5…ŸÝz½®¯AoØ×..
RÇ'´”Î|?µÅ±ÍZùy‘´¨ ñþ1}XÌÈÂh3…?5eqÌ¥¾Ý`×ójó{+L{¸È’ä¿ÀÉüO”#Õ?ýnÒ¥ª9¶oòÓs`öÃ_•u·CG·ï“pL"1/ãü#+ƒÚãÏö88?ÍÂ‰ªyz´VCD‚ÕvÌÒ@x!a#˜½¿b+e¤ú3JrLoTMÖƒeW<egÑ4 ²úïO²rk‘&F¸²“0$˜¢Žõ5y[_Ä›Û›¿nv73”–ÚÆŠ <qóº2×ÒQ/èÎoq]í]¹ŒèypKó£Çˆ·±Ûç´øU·pM‰sÚfuuÔ=ÜÝÙê“[¤8ªnÝÇÆj(ÿ¢'»¡V¸ìŠtHC#üù!¥(Q¶ÂŽ´l,Jó®PqÚàÚ ž+ë“ØxþOë6bÆÊ¿@Oç$/©1ÈY:VSô£i_¥?z+÷X• ÛÐ”4]©f¾‹åâÎÉ1AŸÃü;šùTG–Á¸NŽ:„pcaªvTÿ‡?¤XÃi<¼*KáHÌ©ösÁ¦\àHŠ.ø#G›ÿÜlÖ*­ð×ÎÞIÑ¯ºÈÊÇÃ·Û²l×–ÿ^qùë23ö	áÃ2JÛEž[ÞÈ£Y¢…. ì±ºx¸è}iÝl²ß½9Ìâ0ú
ž$iàx2¥¿³teÓ8Êqäðˆ×ÎNl{¦ÃÝ9ªÊ‰CÃirpŽÕs­áŒáÀ¼s&{\qØpŽ<×X³ðÐ•—yÝ{E6Òi8øv{:ôs`á þxaÈÑèå¥Ee©«ûyû/+ífû¾{Täí_Sàž/Âþ{xGíl³¯a<Mã	ºŽ1HÅÕ> 4µiôaŠÊÌJûãþÓ¼ý.i«öÓë} ï}ZÚÁ_¤å¦¸òSê­™sz4Âú¦î‰úÜ‹²Ð5k{Å=\=¹FÖW÷KÍÄ%¼qÔ5ý+ì5¨Þ8ª­>)^+ÊŠ¤èkjÓ·ªó¹¨Î!Ú!Yeæ·PéEµww»sHÿéy]å˜ŽU€]ù;ªXçíŸOÐY´^¾W÷_tÜÙÿxÔ{V{—4ß^û’þ¬=Ýùqÿ è%°½gëOY_|öqëê¿Tû/Á ƒ}j#ËXÙÀGï~¸=Ý÷¼­>ÂWWòã.O	ž×ÎÚSu~¢¤YÑ33TÝŒ×;ÎúaÅi…|¼^iÃ¾Ù6–·rV®hzg¹Ã¨˜#å,té<«¿ßvño´‹ŽÙÁœHè BæpòA>ÏÔÅ7 ÞŽ‘RU½¿”‘’Avåð 4œÎöÞÎ¾Ëç²Ùp0Ž“ðÙjæ:w/çòXoj‹¶¾’Ý~ÁÎ?Ú(3gÁ K»;ÇrŒ
|rŽž¥ÍÚSAúkÕöÂÓ®õ9ù^ýþ¿àœì£‰p„ÇGŸ“Ç•åóÇFåù(¿Q‰òðO4Z,T÷ö	û·”¬_í>«a0åf»f¢Þñõ&!+êNù¸]5²åÇÑ%U4™L.ì4›%Ž$Çg™5çY‡ ïå-BaåÄ‰i†œÐ~ÅEÃãt2#		ˆ<ÈWêZ)oƒ¾þ¾<”±Øí¨R=*¯()D~`‹±Ê|©%¥ù·Žáþ’Žÿç Ò¿EüÿÃµï¿bâÿÂßÿÿðá·øÿßâóUâÿÿábÿ«âþÍ‰øÇˆû—(ð(³öÊºÂSþ-äÿ¿QÈ¿ºÃ~õ-„Cø¿Rü}­öÙA÷NÌýÝ…Ü«¿Ë˜ûß(À¾"´qåbîKÁÝ½çª9V?8( ncÏ®šÕÏŠ°¿yx}yÌ»@E_0¾º|ÎÛ¥é™·÷Âx¤Ä$2÷õmõÃ‹ým'4ŸéAÓ6Ì‡,ºÌÏVŒïÕáúõùñú‡o·QÕºá>Kzz·¢½	óàÕÝGUì°süŠº°C#ØÀ‘ÕDN¹×i>ó‚*ûù{É ÐÚÖ5;:‹7 ê[À· õ-à[À?nÀW$Ì_9ÎnÂMöóø5ÑÈoÂú*$9 ›t‚Ká±À&ñÜfˆUõT‘ŠY¿Œ`ÍA¥Q%j‚¶<r\¦'¥;YJ’š	¹¬U‹€_èqÇ$apQ 0Ÿ	”·£}„¢G‰*?Ž±¡NA±×¡Õ¹í¤¥öSt²£(§òIÔgÅºDÄ¾%\|K}XšúpößÏ&yEîÃÃ¥ã! Z‚®Hž¸£¨ÿåÉ	[:ÿ ‹P²>œâ?z¼Ô¶÷®b¿ÌâiTb_žÀ±ñÌ¼&Q†6,œ®,ÙíÒæÀ’ýû›×]æ03 Äi†tXS©(Ç_.ãÑˆéXŽˆC„Z{¡Ój‰Ý»uÖ.ïóôRñ¨QL;. ÐSèÙ¼¡Ìh[Y½ì«æHýà×½fÇÈ¨VVWWä&ýAÂxÝ¶DèªÉ1ÒøÆµˆü	gýA5s˜
s9XkÔìÅZ\ Áfâ’õ¯¸¯þ§Fîë¥%9ã7ŒÛW;ÛÝx5D*hN“,‘&·>?ÂŸ; ÐDï«ÿáûêã÷ÕðÏ‹ÑÇ>°
Ô$“i”©6Ñ§d6>…/V2ËYÎ#5ŽÔû<
Ð›†ê1’˜À$.÷çíÂ§>ˆ“ÍÁ&œ£uP,‰J­×áuÖÝ‡ý7ãÍ.…þ7‹ÈÿÞœ`ý14tÌþ+«Z/Õm?¡Y0o¿k´ß©öYý«e±-çš†Óó9­î"w 7´'ÕÆÄ²iL¹À «ìµD”QðÕ
Ep» p—hb·€/ñ *ÈuœÃli©áê•aàLN–‹Ï¥°•‘âD5„Œð§‚ñÍ96xã¶5‰Óð´ÒF\x±`¼wxZ÷xKè1C«”kX¶ý¸;4ï£Ÿs&ª3–tù±ãÎ‹gå~*Òjœìî?Œ)Ë…ºÿ—{÷•É5gBDˆI½ÌX}µ¶ ³ààiMhíÞUL}œ— ³¢¬‹èûŽìvç¸sÝ~€É¬ö­Y"i.v"öüé˜ãyi²«dUºáÚ{¿¡/Þâ/mMˆÐJL´câ[Þµß­Âëïp­+íwëíûu'Ò±+™/çv™ê‚v‚­cÍgy´«åæ7åñ[Z8Bd³ÌÔýÆ}ÿW×<ZÒ_“è’˜Fœv¨º6§Ç×ø]"ñ{Äþ§Æc¤¨Í™+Acf¼›¦•b ½‘ïc¤	¾o
-8o$™#”áO¾`¶bÀé$ªB•2DÅ)X¥²óÈªhG›êgò£çé,ëG^ˆÈ*è¦¨¶¿'î:‘G3öê]â ÀÕUúãŸ×§Ÿ&Ó8™l”SBäß ´”î÷7Éwª>ûîDmÄ±ÝÖÑ‘)dÏ‘uãòSYi&ž.›OQe…í?C9†ê34a›W‘© ÁF@“õD?;_JÆsKÖê¬úWH³’Qù'ÐÃF=Zo“t×|<&šJWÛºîÛ¨é_þ"™¯çâKÅPü(u3œÙ‘Àa¯zså\LB¿SO^C{àÐaC®pUpÀþcÚsvÛoa÷Ü=SH‰‹¶-ßrí*ž.´Jóõø=@QÍ‰*µ/%ÔjË¼…—·ËåÇâC¼ ºÁ;^™Ö¿“­³áI¸j ˜¾uÎ0	JëÂ…î–hÄ'.%%íX~ŽÎe¶»óÑ•ÁSNxãbæ·š3W·•'ÍÈC8@*fÈ¨V‘«7uëO’0†ü>;JÓ©«66¥âÜÿùçÍÓQ˜¼ßüå—ûõ’ $À,_ö»½vaÖ½7ã¤?š¢lè; X{OÔ n°vv¿ý®ÖxWk—@´ïŸÙmøV÷ýœó×>§2‡Zò ÃÙÙ¶C»¾)Ø"ñÂ¥;øäÛ:ØÛë YD¬G;û×mÕà\5›&:M2n”%s£¬Óªébž…»ÐØ"€ŠÇ†‡êëd;¼’ …ûÿüÝì~½…nº  $xKTØ	Â f¤jï’rKõ¼â\:ŸÒ/øBø©LjY<	ÌÁq0£)Ê`tæŽß´€ß69‰¡sŽ’
I¨4ƒ¦
ÕéHNç²W÷¦GEœAlÄŠ¤&•M()ž ž†ïÍålõDºÆÝ‰BzBr” ÜÊ‹»|ÓÈ³kõ)1Í•ðcÓ×ýTm¦ã©¾kTñ¹ÕŸ*Ýî§ž°@’ÇOeÉüE¹9ä³>š‡ M\Á˜’8?s£PªcNn-ÙÒË¤"¹>äu:5>3ã(‡žÅT¦åLAÎ¥)ÖçØ¬Éž‡™K:ÿ‡Õ˜¿IþÏÆÃµïMþÏÆC¼ÿåÑÆ£où?¿Éç[þ¸”ÿcNÄ?FþØ!¾åÿ|ËÿùXßò¾zþš#aü¯ww—Ÿ§ 7åŸíc´uþ¹Û=|öèF Ê>{~ao£è}ŽÄâ}M8¥”wŸÕšMý÷¢‘±ýÊ¶U/GáÙ·Ô¤»éæ7JMšªÿ%)™¬ÕÙÝ—¯c¦m>Î‘Rx$Ñîº³¿uÔÝëîwv-TüqØ÷ê‡·ÝîŸ{®=k—îYSéh`¢ èGóà~a†ÕPýð¢³õç×‡7ÊN*Kg'1ˆoÙI×÷“|^>Ò·¤o9H_Y0ßrøó-‰¨à·¤o9Hßr¾å }ËAú–ƒô-é[Ò·¤o9Hßr¾å ý}æ M7ßoÆ›ãÍáf÷kä MëŠ]•9:ïëŠ\Õ¿þùK”qÄöÔß(ã(T ÄãpÄW9“8Œ‹€<o]Eg-ø/Ú_õøÛuáÎZ´õo™:ß2u¾eêü÷ÍÔq²3n’©#ñÞòå–hAˆs#IpÜDá-Ì@Q%¡OÕùêp¯QM¯ˆß1âl˜£sl6JÕcíNRÌ?ƒýîÛô;í8Öð× ÃìnÛVW>Ú†×M¡‚Àñ©8wz]@>îô:…—”÷–úô"Fôöa‹^¶C¨xÙß¤íÒœq›h¢þ Â\ØŽ¯—Ã˜`Û³ìLBZ²;B‚ìOéoŸ³U(´î˜ƒ”­yéLŸ—²%+ñß"i«D]¿%#ÍKF²®cJF²²¡IF²-ô…].¦Ü.É…u“T$§ýÍS‘œ—Cw)iéXªS‘ª /ME$Ö‘R¦meö‘ÓÃí³Êr§=Ëx†BÝ o(‰¶ºÅÜõo—èúgíHŒó²Ô‡ØÃ‚ßÞ–Ñ¼+‡\ …MY˜˜#ã­JÊ0äÕñV’-£¥‡k<7XŠ›Œzå£?×›ãf¾[•Òü<–ÒK3_ü¬ñ$`IÐVšã³
Ò°t[ú…7í4Aµˆ¡š‡í_o²Àm7‰{hMÏþÊrë`ÿåœÅtº¬Ì!*.¥Û~~óê%Ów±j¼œwSÕš_½ûEÃ[ÂyÉÛ LL5‰oë›\œhR…sØççZ-Í³rvL²¬n!ËêæVó…¤•ÔîV‰T_žDuëªß"yêf‰S²~Ÿ8uó¤©y^ôŠE¨ÜÔyyQ…½ìÌ¦)Æ¼÷ChFÊ’`ßýƒ#asÉºF!;YÍ†
jÕglî‘Üg?r¥Šõ¥fOÛ+ïy6VÍ¬š\ z¯Þ2—m?u§0Lg€²«h¤,»<èB"¦ƒ?Ú=6ßØv›D6ÝÝ'²­ýF‰lß>Ÿõñ®âþJ},Îÿû~íñ÷”ÿ÷d}ýÑÆÚ“uµ¶þðÑÃoù¿Åç[þŸ¸˜ÿÇ'âï:÷mzT+#úµ=§`ãû–ø÷•¨s÷ìÊ¾	³c®nŸ2…z\ŠŒrœyUÜºÓA¹Të§VJÿÛâmo¾r¯¾ûÚQ‡B«ß*èï§†ö…Þ«“ÞÁë£­îÏk¿\×ê5õTM. ŠÂŸpzOót4›Flß¹‘]ÇW}šÁÁQþ99ìwöŸÝÿËÏaó¯æÿZkþñ¤ùËƒÍÕŸá/ø·þñÑõÁêëíOxÍê§íOÛ½n·¾r?`8¤lv÷õõ¸?ü ß¡o<•bÇÀOÔú¦/¥íóÍ_jƒŸÓæ‡°œøì¡}Ö3ñÃ^Pl>æ‡ÎÍÙæ§'›N iÚ(•Bë†:ØÁÿàl¯JoïöxèéÖµ«¸Ü¦„ÒuÜÕ<Øî¾ì¼ÞÅ‹…9Bˆó5kBCjÞïT‘ÆmE×3×
0HÂv±´ë·òœ¿ÒÎñÑ;M{{'Û âyýR$ž~CÐ$·:»n«QÚGoàœ6/ ¤°8§úÈ¹U4íÏm…J¬îóln«ãîÞánç¸Û“¶Óh<¡@ûÆáÑÁöë­cw“,ÌúS*ûÏ1MšÇ—ë@Zë- ï¥†/÷Þ.hÌv³£.Ïv~¤rvÒúÜBª±ˆ8ºgÆšÔâ»ï@‹[°×…ŸçþP±?××B;CÓBkêçÐù¶Ùtz²º€¡_“?Ùƒâ4þÜYÖ¼^è5é†þ¾m?RW!ˆ£¸…Úk;¨÷«­t¯›:“\Ð™F~éŽE ²p"ófDQ}Óé…ÐììZî wÐ¬`j-m^ðÝãôXjRˆ} ¥°A8ÝEÇˆ•g6x¥´äµkþ8ÎûX/a´ÒgI¡ µŒßƒdüÕ-Ðf8Äó™g(Y
·Hv€=zûÌ7¢-^¦Ö>xŸF3xÿÙ"ð¾°úìŸc„wÕ†XŠh=~[t°J¤ÖVÆºóõ©ªíP?ùÒN=zítü§Î›ŽîÒü}ËÎ~/B‡z¢ô‹~€À3
Ð£(üVŒ& ñTÃÁ©hÔKäÁßeý“Ü†aœÁò±¨Nž	Õ¦”¢|’&Œ~E×~ã¿\¹ô.U!¥<R€	ÎÈ={:Û^K{¼AÜÓßMnÚ¡2™>[yèDÎÜ<À„™E¦ú…ÀÂØ04¯Í.?ù‡‹V»þEšùÀÅØƒô«rñ FrŽl¡½‘¸IxáØA *KµF=Æ^ÆÅ–:EÈ€zOGWDD®@.`ümùöó,šÎ²D­­è¬tfQ8P’åÅa¤ yÑ¶&huh'i&ê~›”3R¼ÈzÅÙ¤i’)k7ÚYiOî«^]S/u7ûÃ³&^F	ÕÙ”Øujl7ê^¯¥þ¤ìë9ïª§“^o·Ø[ï+vwÔ=4áÅæåÌj¬R‚T:)Br6PÕ¯Æ?¬á•Ì¼l)!#…A`†åî÷Gû˜Ê#ø8ÁKN{i	mÖþáÕmx?ê?±í“‡Oæ´¥ú¨ÿ„¶ø#ÃõÉVÅ››­þe¤»¢:jÍ·\(E¥A|×hÕ[Æ®!7¹ÖìÜ¶=§±´Å¬loM!~{ÚÂÊ7Švý,{Uû»ZEãÌ[Ì®z{U¹ _ëkµJ¯}¿¶¶^ùa6þ¼Qý3"s­vƒù¢ùé7œï3>­ó§DôÖ+åÎW¶ù†‡õnQìö‡ô¦ô6‡óvó6‡òîVëÎËY|6ÁpýÎm)Ëáü3I8˜Žó%h[ý¢ ·âxÔ·Çí3l7¯b:!2BW­øz÷ÕOJ‰Ë~q$uÊÞ\¯äŠKÄS‰ë*ÎP'Ð <°$CÅªV–ß½+<Ú$¤Þ4‡fÓ9›á7WüÅ¬¹sÿlé[¦¥¹MÓys3)‚w1‹çÏ«æQäâér”VÍ»u¾¢©}ô2š2ôlFãÉôª¥¶têV]RåŒV‘€h@Úwƒ…U#»ëýÊ‹I4ík4%’l†=ûË1¤vš†Šøô4NÎîÔµª*Ó,êš°èz;ÿò/^%ŸùÆIó–´lÎ»Ÿ«þ«bº†Óyúþ&ÂÏMºÿJ]‹Üu³Î°ÙÕæ„Ï™3	¸·šõ‡ñèf]3)¹5«ÊéˆÜ²‰ 1¹h&@ðiöGÑ	™‡oÜ‰€çwÙ´l:!WähÔ"?¶éêî„ž9â¡š+!_x…Ã]]±K_/½É¨¼÷x²ô¶r:´Öî9ýõ˜èH{îòú†ÇºRÐ.	ºêæ²®º¸«n+ñ:/¡÷s”§¯3ÓÏQ[üVšäé(RÊ	m¶Ûr3:!ÊÇ¥á½:>>TþgÞL°i¯²©‰–7îäX}%%9îlRæ¶.£Žœò]nnêóó[^*ÜnÎ<ÃsNk+UØ‹`>¦	žìZq±½‘©fùYékÕG¶ÒIï¯NÑÅÏ=-A¦ç‰“,´·Úäk4¾
ríé Ú–¹ò1¾VŸ°¦‰j®;…I•L»w·Ú{7°Ö]þê)‰wÔÃ“ù=ÜÎ§§¡TæÜBç¶ŸÛ.‹Ù÷Y«ð._·WâêX€’·%.éAø™dq2ªûß5çê»æúþ÷	ýùÿ›cM„*•;¾¶|R½ó†S[Yý5““Ó+ÕVlh¾VÖ8mþ¦Cp]'Ógê<T[N•ÎôW#ÎvÎwfŠ®aÎt[—öêxÇ„P&(8-°¯H•Êâö8‚HF©âPläªX?&|€Â>ˆÆivÖJñj„¼•GÙE”µ(<ÊôõøáØ(g`× ØËØàîÏ&÷Ÿ–ÊwÌ'ÃØ¯©LBE}ñÀ’¼™ÂÉàŽ»¦Ã¸¤ëËQ~÷³~P·ç„Ñ:i‡^]@Dr5]áÿ†ÎvGÞýÇv¹– ®ß_÷ér…wÛêÝ®BTM¥I™rö‡›‚s÷âÜá æ À9¤¢‘XÅ#t!¹Ë]îâSö«++p6Ÿ£}UÎÊo2ñØþ‹…àJqQóçxg&½¿0€`áÉš@à¼´0Ï_»Ûø_‹ŠoµÒëtùõ¼gQrbŠÒVÐ«$ÊØhjñªw8–Ý(9›ž31Z_ãyŽñfƒ|–EÌA-\‹=¢t…—üpKçª>Â¤X\xë
pŸkÀ=2»"½>Ò‘œ˜[5_Z®ú7Íf‘§@äÜO³,L€bŸÝyÛWµNó…Í¿®5ÿXƒ‡åŽÅBìx>)–‚µîË¤8è{9VœæÿôO€c9!×ƒŸô/üGÐUñ%*(õË‚ºõ¹â§@²Þ±$»¯¨ÐžG£
•Ö3 SKëÖTº»!U´Pí³ Õ-[°Ýý7ŸŸîãƒUjëuïø`c4©X}ž¶øÏ› ®\Û—|žl_òŸ^Òeù\4Á—ôó/oNÁâÍñy¡¹§&9Í½çwðŽ	h-Ë</´×Åf‹ÓÐÏÍÝ¬·¹ó¼úŒ[|C?oÞ‡×î—ßó¦òÌg7ÅžñÄ{Ãy^~Å×€í+þó]Þ;Y´;%	ªê½Š©¡«
Ÿg¢ßV4•+¯KMùyÕGÝÃ*Øø¼ª9¨×•Íá¹×Ü¥":q­3ŠÃüóèˆ…TðãDÇ².ÒãÎ'h‰QZ´ÃÁ ââõh]{·â l[ò›4l’,.fv?Î•%Ôª+…Ô©Ùt_uÀà´¦I&¶^0Q% ìÀYú*<¹oÓ-\ž1•"Ž`q2cr%QÙÔXÍ<HÌâä£/”*°2æqˆsDn|>kî-Z=ìûreaÕ0Ÿ×4 êk¥½Î-"²ž—JÕRŽ¥Þp––'ýZìåû*¿y"d¤_5¹`4	f÷ð·FY*/Ju¾$,ÄN€nd´V»è%¨-‰NE—jgw§cj$S{ªÛ
£Ò­ùjëAýÙêýüß§Z½õ€Š·*+âÙÄÐy0Vï!Œ•O«¥`ê+íwíûP>Ê_›M2NX¨aû¿¹ZÌƒµ‚õ?+iREÃ ~jüµç$A‘µÙ…XàÙ¿ž£í—%òOðƒ
³P=Qí´»¶üqbÛÎK¬­½^{Ê·$=ÕÒõƒÚÓ¯5ç¨ºƒçÚ˜ A8/lö3Hyë¬Ã_w¼HEŒýQsŽÃFã<ÞpmD˜Áí¾µ$Rt|ïdBz!L SÇ3¢Ì|õ œ Sæ×îÍÆSxénF´•ŽÇir´ëÙŠ?á{¤%é%µ;ŠržÕjîs‡@þ\5¯{+¼Ì±jî¿üRp–%)¨åÓþyC£0ÉY1ïÇˆ).®O@±V¾)¾*×90ÎR¼Ê‰ÇË¨Õ,ÌúÞË‰³«à$þ;£w
$Ý#Ö½¡XA#ÃËX¢ŒÓ` ¯Mjs±54cè÷™þ7ÿªVxM«•f½Þ^èXÑ‚eµXÉž#õ”lÇÎ¤hCÚµò îq3ò#à~g)¬ò*lŒY¿é¹]?=E»tÉX£o
ð†k¹Å@Â§%-vj³-y+RbM²-¦IÓiB-^¦Ùe˜d×ãžîŽ!ŸÆXv4"xx…*¼|.F¶(q¶ˆ¢…ø™Óoyé
+á6v£n 	#Ð§Y¨ò–a¡bæá¨ÜÏGÈæúuE€A»¼Ùæ/¶™N¯ŠõXƒÉññOX›Sì¹\³úßà jà½h‰¹7úõg4†¶dk›7©hÞG´*þ³¾¢ãïù:Þ9)X¸Î`ÎûtÛŽúŠ×íxc2ÛÝÞÍ¹ÞÇg8PñN kb.õbÌPÍ•<ÒãgX}³|§‘1ØÙ	mQÂÑ•É³ç+‹ñNc,Ì3Œ³|ê WŠ4â2ÎQèAðñTÛ~»Ðø‚¿|ñÎ›î6F-¼ÂD+øçÚ)ÙÏp¼Ve·ˆNù`~c‹^•,<„ÈM™ýW°èÛEÅ˜ï’ ,u‹&n• õL£e²×ªf¨mP7+² k‡\» ´Û:f«‡R•ÜË¡,a‡b®Ÿ*Öc¹–ÏÍß/„Ùâ×~H÷‘¸á:¯óŸ;rêaÇ×öf1¼èÜ%'ª‡clªºú*lñè5fxÃœ<èa­½¤‡©²j¦Ëœáßfpº¤yá&j™fömMï…Øà—™¹É^µ%^ÅŒ@!³\ú–Qžò={y:œ¢2ÿ^BsÝ$Œ·B_6÷°Õ|¨Š•_5$.\Ÿ~‹rGW¬·¯+˜Ì¿hé?ÅÓèµäAKK9,Æ‘"¢.õ+!s¦zS<å¤ú„G:H•Y=Ú­ãÅúKRyêsnŸwÝ`S¸ýHt÷Â™üS‘h{‚Ïn–fä\{ä_Ec—ø+$ªÜ<IeÞÕG·¸¿È¹j@¦TTY¼0©"+a^ërKOÝÔ´WúÑÍ=B£(äwÈ¨ùA€äñ½{µ•ÒPÚŽÁÌB~<ÈØ.JC}PüÝwíƒ4…ëÊåÅŠ÷(IHÐÏ•÷³Ÿ2KAö^Š2¨Œ¯p÷ûŸ›¥êjŽJC8>Ø>àq°^¢.`Œ¹#ŠJÃ™Åþl|)$‘ü#oÿî0-îï1Sò¡®çç-ïT1˜µxV?ŒG¿Ñ^ù#¹ã½‚iàÝú,ÂBÞñNy	„‰^ñàÅHŠzŠ‚æ%À›5i‚5&¾àÍá	nA2ÊœàÀªÇ›Msá›? ‡'"'ôKÂÂ‚óÇ„B««û:Uô+._tïÒP‚Šå¦£½ÛAV^9G)¹'vòpÄ¼XN6oÑ3EÝ£JP€ÊAÕ[ˆ ¯ 3W‹š¥X¯šÅhÌÏ°ØPóÙ•û‚}4Ì*¡Ò0½vk½ù¶wx­r/Ö—sg1í|azÃíÏùd xç:€«îî<xÍ÷ÈœôŽ>#×Â‰Îº¨Èv£Ü{u×îmºü’$¬,i¼aKÊ’:/èd›%¯<r^áBK^xlRýô•%¯=©~íÖ9)Î¾#Õñ²ìÎÏ»'ïñÔ¥ ˜›ôªøù H–xi¬P[\leSKýû€GÊâžï¤W¯Ça¬7æs²ç-t)¨2ƒÖµ+Ñ–i¯B¿2‘ÖU?êºVKW±“À¦Mf^óY!jÇOk.ð[3<ª¼²ª}©Öð)fçÊí­Õ]XHŠß‘•žÑôKOª¸Ïüùi.{'üálZ´Mk£>Æ†¿¤[cÆ XÄ“‘±±Èžþ.¸µHÔ„£Û‡ñ5“Yˆæôùg¬Ã
\Ë5P•Þ¶"Ÿ^03«ê¾V ß—¢¯*c°fþŽ«¬á­Ä¦ßó?£"ƒ®,EP´¹E8¹oÓIîÛô’û6m¸"þ]äcxkš WyY;KªhtÄ«@î¡±³ô³¡P%¹õ·÷Qd/Ÿ“b!•Þ®¹7qy¶iîŸŒÒÉoÊÁØÓ®+Üg°\GÝÎ1ïã£×Ý¹šb?1ŸŠÔ;G¤t§©âÖr
?ëXE N¼j¼ó@=º7x©Íø¼w±þüg½ˆåíK/Îµl6oE‡+Þxï,z
?|áòazýß¨Z?ÿèÇx7„^$	_
Ý–þ¨®òY+s“²"ê³Wæo»ïËJŒãÌn´àFmÖÁmŽ’ã{™7Ð\£°Y±Ýtÿí¦?ŸM7Ú Å÷Më£¿Ì~·cÕc¹‹±–ëµÜõXEÙºñx5nðŽ¿”R!9‹(|Á*­0Éxê†µo^p -¼rÁmÇ$;”¢sûKS€µlLÅæ6<ƒÅð".e>‡ÖMÞçù«)xUßÚ„âPÈáòs]ÁK–´ÜnŽŸÒ†4ÉPç¾_ &¡ƒæ£o¥k³¾c¸ŠëxÌ!iM?L«ÏÇÛm¾éüÖàJvK”³nLÓ]°úóS*7Á‘×ñaó1<²›x>Üç6/Ÿ÷Öî²=¿ñ8æHW‹GSù’³è+1òðš©kŽ¨Æ6èJ{9¡µÜ’W¼¯L…çÞçKÀlöÍ¯{Ki¿ýµûX|ÿ'ß—©ïÿ\_{¨ÖÖ×?zü;õøk?ÿÃïÿÄýßÝÙêî÷º_­X'ÍÙÿõµG×öãñã'ßîý->ªâóãþkõcw¿{ÔÙU‡¯_ z(A‘ ª9|ÞHêàÃ†Úø£úÓ,‰Ôlv€81¹Êâ³ó©ZÝªÓCõ2‹"ÕK‡ÓKŒ^$Ë&¹@‚û-õƒTÿæÃVšµŸª{eWè?s¼™zO§˜œ€)“+’ŽxíF|ŠI	Ðöà¡88Á84N_…7G|ó¨”Ÿ!h(hÏ™Ž8›”•p4J/ñfÌyÓ¥Ïa…cp°Õ1È?´j”ß:R‡³SèMßuÊõV†0íxQ "ÿÌ(ÈõbàT(Y½“%t‚Hõ>oéNä­\î+Å{ÞËïN°øOóË$:ˆòøÃ·ñB6,¬^†W|O
‹V z®!q(	v<¥^\¡yïæ6‚éÒÇÉ4J¼Og³0á{Tì1(õˆ‰’‰Jó±j×YŽ›Íijk‚(ºÑ•®\$pvqeZüf9@‚¡¿¥"ÑÔ›qDm°`NfÉSŒœÍÌÊ?Å±„“É-òŽ
ó
“+Ù\>L‹H&LÄ¥?½¢†t»0Žñ§t†™T	C(´Z2ÿ¦¦„	o1õ2Â(‚ð=WÀŒ§?áü2¼œ—’«1úƒ×/{Ÿ“,ÆÚ7ê ÀWÏÖÇå-=¥VÁÐŠ÷ÄuuPÈ9‰| KãS«²ÝÙ£?@£\	 ÕeœŸ×¦ŒÕŽ0Q¤Ò~:ˆ(s ¤J[théÅà2Ä¬ç©ó*¶qÐØt¯ãnÃØú<:’ í# qÚõæän÷““4Ü¥Î`k>Ÿ)¾:Åä2Ú7"{9íFñN²è‚ÒÍ3ÄlÊÀîN‚aò‹8Î0/?Ñé$cø€êÜèV-¢°Ó)n<6ÄM	úQ6)+Œåñi<Š§1_ Œ*wÉ]¥…£éñQr³†…ÏpÒ."à¡9ÒÊ¼Äûˆ?„ãÉà.A>ëŸÛKwÎ©_gx¥­n5Œd²c,ƒš'j˜r×$ L “iÎ3Âkte\y	±ròPÅ1Âž]C·ÔãÕ2X	p:€.fPù9 a¶ 
ð­\å4Ä«€	þŠ5šÐ:Éõèˆ4 !JLhw«Ð‹“§—)^C>É7ƒÕõºÂÛÓ³)ñæ½¸8Þæ"f¯nÔaÍD0~!a’ÃœÅïFÑâº9ñxa»w\›¨£ ŠÙuŽØÒ³ºÏ–&y÷õtˆþÒ4aŠ} “Ð?¬Ç…Ä=Ð;‘EÌžxfÈK®hÔuiqÇ§€~Lþ©ÓÀtšÃÛî²è?gqÉzåæpË€N#@Šì=ÅiR¡Á»ÈÃŠ‰>ƒ0Æ­ ¶#ÙLáTÖf@.­$Jg9L9ÑÉA?˜þhÝzt¥$üÒ¯ ÂH-x^*ìS1Kx(¥ãð|d³$(O£p¸ñ…x@¸‡,áÅîgçÔ½ÄCàdPº<%*ƒ<y&ŠO˜›€0'šzH#ôþ&ÉN8|¢‚23-Sù 2¥ ÎMbIÃ)‰´ßŸeäÎ£Î@ãÅ¤K‰Y4é	Px0vŒko!1‰û”=A
‘G0üKÆ+’üˆµÏ\ÕÉMW>i½Œ˜ÝÙÍÀÑ53d¥ˆÌ§ç@"Å.ÆÒX$øšÂñÒCmQ¡
š™A¢0Ã¶|vŠÖ”£UYB.™¦Ñàï*h…)©Q"£`r×=‘Ä”„^–• Ôp†»k#°co`4"ò*Í­˜Ü;UtÂãÇ×P
èšlãbNÏÉ9‡ë2#MeD2AÁ	þŒtë¸GT7EIþÖ„ÃÀiêO5)!+Îž°ahe?.f‡âLsÂõt®r–³¸OH“æBá)±g:èh^¤1'=ë,ë"iÆõ€XÔ£b©ÞLœòâ"huÚÚÇê#Z¹"P5¯Z")°$€ûeÉî™¦FîN¡•YÎÝ:R€îÓ°q,FS$¾#Ñƒ˜s‹‡”|9A¹Ã¡ãRüEè‡¹¼wc¾.tÜ=Úë©Îþ6^¹½s¼s°ßÃÆk-,S'Ü#½_;vxLÅSÚ_}Ššs4W
g@F«¬±ÀÍÅ¿kŽâ÷p|)tEjèÈ×­ÒlBZ £qŒ‹4CßPÂü½wê-´;l”ñMŸdì&Y_t4ÀNÙ¥8ôè•ê†Ð™4aÍp0€-Ï9¸,·­jòB”×hKjV¨©ÁÈ®\ã]9L$ªÖ¤5fÉ „Ç&UDsæHW¨á„Ž~¡â²øN€åSÔ0ÌÏ¹ä2L$éVº°ÂACV˜ê02;!õ¸$ °ÏR‰PúŒÒß±.Î¹6¬„Üab5S€òA¬õ*’é¯šv4Ô¨c·-FGÕú)À‚6ø¬&KÅ2`8]‰éS6ÛOÐ‘£äg³ÈxºÃ3
(®ó€Ð„´æÄÂ)W£HgpÌÕ»$H„edôcêÂ8òQ¸|±ku§8ânP]A8¢O}ja÷éÈÛtÒ4Û<ðÌšH*#Äá¯(ˆÇ\×ƒöìPæ‰ˆ œ4fhèHàÑ‘Uš,€“i*—¨€‚'ˆa2ÑEx&tÚY@Ä£ÄNª)@ñnŒ]ÈO/Xý€#sFf'`.¢"ºã9Å3/R‚™Ñ†(aùE­¡]@‰J4PÖR`öHfH`¹B.ÃÃ•¥ˆ/"ãCY*ã†:ÅÁ4ô5„˜«’äC®Š0mª¥àø1›—p6±ý\DÜ= 	-Òu1ht&Ì_p«vI^ßOQäÈkèD$0æ±º+›rI¬9* Â|b×(C k¬Ü(E¨_˜žÙ\aú¶è–PÿFÏ¦°I¬ŽÉ*-ê…’®
Â
n¸“b‘Iâ±E›4Í‰Xòª‚k	³f+<RRÙ€apoŒ1Z¾38x[ïÃ``Òãh’X%$N;=!²lyMÀ‰5XÙå‡A;“‚4Ž"Rb‘0fðk01Ö[JüZ[¨zjž_sôÑš¨Ê.9b± BXÔëË¹tžì[|,ÝÃÊÆ™ÒÁé¯QpoÏÊRÛC=ÂÛCQ5ÌjG/š}ÝYH>LcúÔÓå0v‚NrQ2¤R?gÀó0éI€Ê–®ÐzÑÐKIÙòÀíMG¹“~Ã‹DÇ¾?…ÆÚ6Æeô7ÏÐ’ðð´Þ¢®XÇ)Ö°z;N›(«ÂîQÔ@¨Ó,D¢Vcî(TÙŠrFûÞÞJ­•@IGºJòjXgë+½=Ð‹ÀÆ ]ý:×ž1‘ß…EØr•&Æ,n”%¤JV$€¨yà4§3~ZWT{1,k1aÝX”DXÊR¿xôÕÐLÄ¾*#m$
ÓVxR^b(Š
ókBÄu@‹MP+Œ¢&hƒG.…N?Lu©«6EY3¢ðôR°ú´Ôh„$>`#Úc^Oãœ1¯¯]BbÂÜ8À`¯ëÈ‘y‚L¸}¬ ý>o°\‚ÝÇ£(Ój¨•ÖhÏíàÙcË§ˆÀÔ¾‡0µÍ†0tË»™€	GNb&!•,ÒhcŽB©Kk7´ÅBgÈã´s%2]§!4·3²É¦ÚÔd§ÊOë	´rBŠc@þŠt$*Ÿ•`ë_¥—¨µ6LñDt}æ4ØûyP<®´¨E%sš¦,„Ëp,"’{B•5îf¢Í9B'¬*à.&™ìCÆSØ—ýcÉ£m,­UûÖïFOãJŸ¨†¦}äè>®²›ü£XìeÙ¥þiñp±'i lL–½tWI8æª>ê@º=;5Kcª¼km@ZP×
&f»F Ù)zSàPŽ©€J8¥Ã1ž%Z‰%u—Qaˆ¶…SÉ0“Í1î/Z(5bÍòêRµ®lâwqÈˆýÚ”›ådPË"[aÞ­s$ÚX¹o¯»€»[<ÿ¨éÛg€ £eÜÎl£…u2…„ÕÈè…bl>#/Þ B€"¤Ô?k!mÈmJ†èCmà'{0J0‹‹”•-Ë1^¡uh8¶*yMµIR÷ï\à‚Ô€F2“Ï’Q<Ž†oÃÖ´¥¬õ‰r
JÈï¼+Ð8!f¸:$)¬òýôÊ_â‚rýCj¨3â‘ÒæD—ˆå‘q,žÎ¦"‹[àÅùÃNÒKPŽÏ"žY ÝDCPÎcöi¡¤I„çã"1Îí’ž^ù:!m0ù?@L“iF4Vj½a9PmÑ—ÈÂµÑg]3°¾ÊG¡ì…öy»µºÈ,‰6@òIêÑˆÐ^è<5¾3Á1º=Pè0š2ÏÃ>t@´I…óeYÐ(F³œrÆE]Vˆ]‰Hó€2j×íê‰%Ëb8r0Uû'£] úäE%‚J8iEÌ.H·²˜å3á¼Â(…DºÌÎn°s–‹;ÈÂ¦2UvM‘Iß[	8´A§Ñy86ä|Ó#¶AÀÚbCÄ¡4è ÓÜØ4ê¼Ç|d´‚Ï62öï±?ÛL#Ø‰æh—úÄ¨n-ì×y<ao®n™uc‡ñ³÷ã¬?ëºÜ^¤âJìøFÀ‹cq”Ì­œJõH\„]"!Þ‹yŠ6b'ëkdäÍQv€%×%	i€[HG´ßã5û=X)?âû—§Üª¹ECF;0BÝ•ã¸Ÿz›‡¬P„*ä¬;0l%&mb†ÍèŸ'é(=CfºeHnL»FŽQŽ½ÎFÀÍ©`F
>“Ó!íQ!l}]³ ·;‡á˜¢q`@­åàÞ5µË@U×ÿøÇ'x¦‚/ªTdˆÕ(¢QULúdIô–A|=z¹xàFTÁ§•ì¾c*Ou¥}–°i¤Q òŸÆÀCŠÝxk¦tÊ7™„á½Š: /<T[³~L#$¹‚=Oy(³BqŒ÷GèAÃ™PÍTX12­8Tã›ê]5‹ôB–É±
g‚Ô•”H é(|»".É&>îìSÍËàÔÞ—Å”™™Õ,mZP½š´{ZÎ¹}£ã³¶Ø ær ÙÝB—ž˜ðçû¹'Ò0s	´™C@Ðb‹‡%ž«Ét’O@ág§,ù‡­Ý5HòsÄìíõg¶ÐØõ4 ŒEØ1´r‡ì
&.’#úBŠ?ÉU€-ž\ŸÍ@ô÷°OYô½uj0*@Ö/<Íµ1í¸26·§4Œ3:< ¾9áÕ60h•jkvÑn6’£{°Š5RT˜ZþFfd—ÕÝ$}Ç'ä³	Åç#sÔ†B<`cBh]dÛÓ²HÆo\G{ë\KIPi£h3:w,’¢÷’Ø^´QÌÅZM"¢ÀˆzkUa¬¸¹"qÓÐ†æ.#Ûd]X'á•­~Èìû°`WŽ‘±)M”,œ»Ž‚„Àv!VXI¼§ŸÕyÛ%qV‚âªÔ	>.§æóÀme­Ì÷ZT­lG26zº? B¤7!ÔæœšL´_·1BZ†%Ä/3š°c‰s<ø¾žûÑ–íPVd5ÎEšçQ®#	Bë#+  “©J`ÐpÏcÕjÁ¸1à¥òLH×ÐÔƒFí²QÌ$Š’´Ñ†lÙY˜Fw‚²61qR6)R@•§¸ aA9ŠÞ÷u0w-µ¶êN†Wâ³·FÎT.8Ï±¨—Q¤Faa%¢ç:ØK›¹”Ôõ!Ô1fšïj•"z5v®##(s/OqmÄ¾ä1¯bO2!c™–°.è%7´Ìí…y6 Y)>$‹søÛáÙ`hd_†büá•×+'^8®EŒvNÑ{|3©¾(µ'ì&"ÁÉ‹;ò¢ï>Ø)Yõµ‡T›uXÜ£gù‰±Î7PaDe]ÓéhÆ…T#óÜ‘Zp\ÌIPÏÎ¡Ñoë‘Ú%âÊ¦¹ã¥¶,_Fh*‹fÄd9*à	Ni	þ}	ON# 	¸$¡.¤ýú¢ô²"ƒ®§„T¶ªí#/=üOÏÈÚ4û!‡:Gé+=Xß§•4 Â'.OÝaEØéKØœ9¼Ô7”TŒdbX˜eÆÅ<—:½1LÀ&BÍ«´ˆ:+Š4ŒOId+‡¥n™þ
Æt@ínC²9ôÎ¯r’%Ì‹€¬Zû´Ó¢Gë’÷Æ“0‰µ]‰©Dµ©/þÀÒJ¨³Œíg:dFÉ†=@8K6Z«Ây–µÿMç2QËPOX
l(¢ú,íM±’$i1u…›n&Ì9û“&'Ì­2±æ•q„L6,±QÃLÄ	tï C”LÍÅ…u‹¤á®”x2) —7ÁÓ‹ì¶ÌáÝÍ1 #9j®ñ±Q<Zð›ãCC{HIr.>N9@¬Fpôò4‘€v€ë>Q—r}"ÏXë—‹	«0$Ù†µŠz°ûQäu„{ 	;’TT+Á	>;ÔÕ×.Ý­“ˆgÃÊø(’bµª +Ã…#eåë˜â\•ØPœöûaN’«£èRG8ÂuT„¢íÊn{õð™‡šÃcôHž	·8Õâ“S+Í9ø§¢Ñqæ=’ågÏÙé	KGèTZ-Æìó~ÔY´ä´Vjg×n¸hTì¹q™	]¦‡Ü9a AÎ2¶260£2r’(^ÊÀMð® ;ËÔ2wÏñHDÃÐ }Rš—p·1•øàqäï×‹#Ú¯²eˆéÑ;\vkÍ¹âÂhD<„ØåîH —cùvø/+ä¨"Å¬uQ ¾µcÜð‡©(œYæ!AåPk*CË.Ã¹«ÛÂ;t\5ƒ$#™ä9˜|áë98ZmÜd!h£	c²Z¨ã¨%¶aX†õ[çˆÉìmÎ=m2—SÍ=53²N¢(kNÓ&þËá_&äO¯0ÁÁ‘Ç	ÛØQP	¯]…'Ü÷"ÁPÏ/ŸFLm‡Ä0d›Ä[­c$ì©óèÚ™ˆ*Áq@#ÇøèõtR¸fX<08ac/©>bx8<ç;PAspO#{à{SJ¤Ð	CBc<êaÈCk4‡CSì`>³’AM´¢c"‚)æŠÒ¬a[H‘FÍ,‚³åÌ`¤ËWucà¥á8nÓˆÎSøý/çUn9 ö—71çÑ@R€ŠÃª‡l‹N(}€Q6ˆJ‚¹JGÎM24ÒC,aÞdÁ N‡3¾Y,·^ØšttÁë</R
[$É#<ÓÙ6n•În°ì‰bµœ+T{ªæ-”WL¯&$+¦EèeÂˆð¾¹Q˜çNÊG£`–Ð~ã™Ém(t®xt@BJ¯°7…¦æÂèQòEÐˆŸëûèŸ)J3á(;F1²rÙ#×›åÀ ƒ“X¹ ™ú`†Ò4/_Å&ðpg	&Y Ÿ@®H’&ÇÈ¨Éf³Hõ
é¹P$üÇí°‚¼C”ŠþÖáAîs"Ç0­t77úÑ ÉÓu ßGW¼¼Løb[Ü“êDFŽŠ*Ò¶ÊÖç)P–ÞçœÐ|¾DyÃC«PÏ0T1*²q6Nãd†Ä@.wÁ×”ñˆÑ
4•Ä„Ô”C%U„É ›Šx^šC®ÍÓˆÔ|ßdªC	ÝzN´¤D*]S¬&ú¢ñawìÖs£r†’MËj »º66È‘ö9st3ãÄdvê®œ“(#C×:j“~HðvÃZ$²ÚáqF´“øªI4ÅÓ+#—¬AS¨Êj¥yÓaNÌ¾$üW	8Ž‚JÆóöíÛzQÉ”x¹zoÀº¾šwÆ0&$×¢m,=dÓ	è’<fl¸×IÊ`GÄŠ•”ÆN!ö®Ü³UÀIIºfÉÛ[q
Ü3áf®15 ¼€Ì;Žöê&lÉ¿£GÍ›z9B/
 ô)sÁi•eG
G×Þ#Bh¾Íc#Ä÷CgÖ³™3Ù%ƒWA¥ ´<›ãe@‘Q(´N âþ "³Èåy””œPH¨¢ÑÐRhwæ iYÄÁPÄ­ˆÜ[×1SÝŒå"NG”ˆG“›IÙ1ÊáLûÝ8fl£êÂ~–æ¹HB4œ¦
s÷YKÃdsýž•‡‡3“èecaYÎ.ó+GÄ?¢
1Ãó†ƒbàœè®Ô»ÖHë\AS 
¸áÄ,A·9Þ3¹úÄ¦ÞÑj}ßÂ²¹Ú/siƒjÍyj˜–Enèâ¸ÄK—Ì›:íqVâq8£‚“ )Þ0‰8é'‹4Û³.·VP=î9”øštØûÄ´»ƒÄH 3ÂIn6ÝÄfN¦qƒÕ]C–‹arÁÙáÄ¶¾RÎFµ§+Ç°å[G©»1´Æo+éžÙTŸ@å­?)ÐÕ6»«*VAW*9C‘„Ó‚RxÏ1ÒÓ®žÁÜ€6VU…Æà4B©À©(Ü›CÃêMý,œJŠ’92ø SŸ—- ·Äê,‘ÅÓV3·+þ¢ôR†ï¡'5+Xÿ¸Ô,Dz·êÖÙ@&–`Îð‘NQlˆïXì"¤1ù>)?îŽÜ‡ºÔÙ{+ã>lo·5Åm¤Lú¦òè|ì¢ß‹Êè 8ŒcÁˆÊ4»HY"8[fdÇ„eDÕø´hØõ…„ÂS¢Ÿ¬óc[’H›ÔáèßBŸ¥ÉÄZˆ06)Î¬5Å ‡\­?&bºþ¤8†§(cj'Ä‘I7%µ%»0ìË¦ð8ægv¹™°vòr™ŠÔ»Vlüa¦m‹%o+«öÉòÒ³{%•íxjGß¯ãñ71o€)F÷òx0ìäYœåÖâ¬ßfÜÎ©Q¡‹#˜¹Ø¢b«sVè’ÒörÇzhÌ0<Ð”_²SÔasd³±åLª!1«Ä×6ÞÐN°{Ÿj]¸;att=`ÛQTÇ0Â/&:[Ù
Qu(38=ŽcõƒÜcÁ5lÁ£hØæ¬\Š$Hë“Û~‡.¦¡Ã{œxauv&N½eb™Õ‹åÇx uÎ½éªUe[ØF‰¼©ë‹ê±ÖY¨.ÀXØ6Ç‘ÚÂèP¯urå¶ÎÉ!C•pM²1H)E°‹¹¿T.€É`*Wb+F›ÏFóÈwH×jbšL((‰78w9‰h?Ð>"ykìš¹ú€Š]¥Gs÷˜CíYë	…@T…%9ZÍ‹yYYÔg¨*&b	¶¾ŸŽ6 ¢¬3”MJÕèÌøP9 I²à@ ÔþlŒ2§¶x1Ñ®èçðÿ*Æb‘ÒŸ¹ã”wóiÚy¾gß¨5êmÃžÏàà]HÀÎ¼ñ»6
.‹¹¥A/Ðh¾—…BéÀá™ 67™©A!#°´bT(!®_C‚„¼Nª£ zû„QAÉÙá	ÊFÆï”²œó“OTCT².Ža›rë<i™kd<Â™~-Ì%àiÀ6 DQ×¯!Ó;0ïZ¤ Ä	Û#Ü¸ÊG3#¶Taç$¡›Æ€Ì0aÚ`R9Šj¡è:Åkq¼VòMo©<…'«¸°ªFñr~–ÕT&yU´tj€sâÝè"%n
0S¡"¶° a+„ß&çÙZgÓÇ+'(Œ„wº…J’ú])"NEÎS3’ý®Ž©º( *²‘}àz`„Pv(‹e˜j ¬Œ*åH/«*C.øcÑOì±¹Àˆµ!—hØØ*ð!hÞt¼ñ ÅgÉmírPÍ qäÊ0dWÆ†œ0üdMHªNe'(Ã èè¶)­º—„t£EœEtæTš’~ƒfG¹3—`ù\¼ã1Ë	|Oç4G¶žŸanBk ô\ŒÑù´,ŸÖ­‡k“ú3q0Z¨f}ºëHÄgbg÷,}À_KgÌ7ä³ž=•¸bæ¡ñW*r 4Ez™Y
¾a: ‰âlÊ§¹¥ùŠiL°È"gúHèÅÔÝjNÚ›úOŸH/MM…¼=Ã+Ðª£Ãe½èe”fpÍþØ"ëßD®ràGÚãP^qF[!]BÇNºÎ®]æ#J8\E&eùyI6û±“ôn†Êmª¥”CÉšO"³x!Bíâ‚1éLƒ%ðÀ–Œ‹7‘7Ø¡Í¡Y%'Åò–z¥‡Ü d¤Ô|"ýðã*Â1ç…4ÌH2±Ysä‚;ÎÙ×-9[¯büJrhŒ35v8õ¹”`Ú€ ’+„aÙ5({.7$á¾()w4ç“&"Lo§—€ÑX¾M¾ÐKTœÊPž9¹V¾WÅã®šNåŽ€[Ö/2ÑDÜ†‘Øâ,»Â…^¨Ï|Æ®’¿¼…õÏ‚T'‘XdÓž8/3æëÞ\_Q#Cº5Æ:‰ª¡•'ëÿ©±Äïz„ŒÏ‰ûáTM.xå–äbÌ+ë‡|KurÔ-¨ŒºE¨±àQ†1Ž²3Æ·ÞÑ·yÇ5ÄÇ¬£¶Už„¹³“hÊE.w®H„-vÉGš`p®i€q;xD-=×ùìkagûÕ}ªÈ8 ,J6Ã“´ ÒV°®Yâ¬¸eŠg‰ÄçÑÇ%YŠÅ¼Š¹Ž:w
]çŒ	Å™ ø;õO…‰%åÏ°úh8Ä«’Ø,ú6Rž
*×ž7I34¾ÏBJ>²|Ê{Ÿ'H{¥!D)Üþí‰ÅêºYzŽÄS–:!tœ½eÇRÇ¼ÚJWîŒé
è)š¦’{xÁÂäXjr$ï?E¤Òwrú`JéM%è>;ÓJ|àêÒØìõ‚4˜+Yá¨™†l¤rìáHê)ºI¬^nQ8ìÇ>IVÉúzKê²–ºä\ÂVÇ4«éÀ›‚ÈˆgÊXt)' B/0i§0W-æÐVà¤46f<œ·YnkÚD¢ Ã„ÓèŽÚ”ß39$^K[Ç]vñR!}óÀx¢SÃñ§:€6hiÄõMÃ¾9°;ÈHYÔ×OšS`ñ<r:;N7s	Š»&%<(‡L‹ÈAæBÎ‘·XqQZeD ÔžižêÜ!‘ã‰
€%}ö«Rz+úæ¸†Wš-æÒLG5[ðÍVhóªÔE¾cè41^46ÙåÔÄ¼z¦r5¸g—Ó;í¨!,$»†)?€U³Ñ «jªÓäš9žÊí~	çà 
—´ ¸,ÜK9èíN§œ¸-ûÂU)ˆ$Ü»L|b°!Kgb¤7*«ÙYŸjþ$™H$WÚ<@ÓH¬Sì~§l“ü2HE}i°*•ŠÜ‘vKŽÓUSv.ÑK²°T)ÖïpQr"']Ö0»?·pkOÖ¹¬mö¹f
¹û;HÁ,]˜™RscÕçÌ¶4/n2;Á­Šr*ˆ¯XFFMY#–Á“ÒP9Kmnpª+0è"~1¹ S+ÊcÜ¤Î‹,MIR:¶=tLƒÓI!åÁ0iŠ2À–N[C05U4Ž:¡¯:AlÎ\ahsÄêÈÒ¹TEgà+Ö
e…Rd‰N£’±­Â”pw¬0¦rÙêCÓCÃ¥HÁ(R9ŒÀÔÇÖ¥§ƒ‘«6È¦`ÅÃ?‘E.4–ñ¤˜â<Š«»"cÐ&€j)©‚â„,%ó6Ë<Ë_ÚæÂãÄÁªÜÊÀ“¹QXÝPÓ9Íp·š§h  ”É¹»J²Œ£8ºˆl†œººóYÈY,6Ã4“È+“ŠÌuäÕ“fÚæTpdÒÝ0‚t¦u-h!šp£¤:Sú:ù«è‰ntp”‹òZU@Çh¦´Žö5cÓ#0œ«®öçjJ%m:©Àºxƒ‡ç6£²˜|°8—Í^ñ»`Ááä©6¥D`íºªaý‘,&–’fW5¹B³€Ç~:.ö³s¢‡82¼a*¾äEõ…eëÜõ²õX2°ŠN!<ÉH/6ÉG¯…´|¥«Èx©Ä’CÂ«Uƒ‘1Yô4N@' R|øšNQ‚” R›îHv2}Ð†œœ„WcŠsJ­CAzðªRHim_•"W˜/d¥P£Ïí¯›e³†.inHµ5¼2%ÑvºÒéÐ†×¥%¹èS$øT´LüL<¤™ Z	ÞYåø¹˜JûŒy‰Kýãã:3tBÀ8(Å‘C<“AU×æˆšû#XôÐiÚ¹¦‰ä­8ÀâHÁ±Ed#pMAPKÖ“Xê¯Éeh´ç†µºoüAí…ìÞ™¦ã‹Îc]ZÖ1û™L*&—ÍŒOÔi'T‡d€ÄÈSMË :3WW\S€¶C—ÝÈIcvw=z¢RØj}£…Å­zæ#Øï„˜ß§›¹éXËo…zl¢H2µªõC*g7£Ê0ìÎpäG;Øº’(6|Ä}–¯»¨r¹]éúv°Èn±_cšÿnËŠŸ|mƒ&4>‹ÏS)o SËòx<MC}OGê•*sy&]"EgŠ¡¥‚¦n_öR²Ë»æ ÞaFÅOŠ¦"MqiÉ€g}â:»Žï®BY4z,¡¢õ8L
¦‘xœ3o;,?(„bJ–Š\WÇ¶@³ltÍ@2]x«dTpr43<Ä©cÔüä1·šÑúÃFt[)ï¥è ™.ºžâ³@Y,‘’¼Š„%2Jþ	Í¼›'$>µòZ…ÃW’NÆ2Z`ërØZ¯nñ…Â’S‚L®x7Hß«@A:&…®DdW«c­Ëâþf×Œãí!Åõ£ŒÃöœbþFë2*8£•u‘øqÎ®b|yÔRGì0ŒûMäÞ½T0à2Í»‹#[¥ Y&Ðä‚-ô0ºczÚón,¤s†î8üKa=88?ŒÐÖåú°BÒ$Îb“Í+Q‹ÆêEÊŽ’ƒñ…f”Œè¾Î„º0—±LŒËíø™4zÂÚpeT›f0uÜÝ"™aaAù˜àr‰ÕÒ 	!æüŒ®ÂZ…µª‰Y“ ¬ÕÓÜëH5ðí)¥ap$5ÙîÏœ+wDáÖUz„!_QÆk(õð&°xSŒ32;¯J»þŠjQo>
Ùð±þyª½ÙŸÌø‚ªñ9x­Y»;ÂÒÆ|¸âáT3ˆ&ð•UÁEäßg¶ õ„îëx~}?cŠöå;Uí2¹!Ž^³;^‚®ßÐ:¿ËFviCµ¸e&«z&67Z2ÍltnàÆý;ñCIê½á
q	³–% :­ˆp!É€©¸Q'hZ€ËˆÒ‹‡”Lì·Lh8£Ò[	g÷ª{ÔU;=µ ÞvŽŽ:ûÇ?©—Gøƒ:<:øñ¨³×PÇô½ûïÇÝýcuØ=ÚÛ9>în«?ÃÃÝ­Î‹Ý®Úí¼Å›“þ}«{x¬Þ¾êî«ÿv§×U½ã¾°³¯ÞíïìÿH ·:ÚùñÕqðê`w»{D7Tµ¡wzQvŽŽwº=Ç›í®;&Uëô`Ø5õvçøÕÁëc3øàà% ùIýyg»¡º;¨ûï‡GÝ^ °wö`Ä]øqgk÷õ6Œ¥¡^ „ýƒcµ»3ƒfÇ {“¶:àïu¶^Á×Î‹ÝX/¼VëåÎñ>tAk×á‘o½Þí‡¯zÝ–â% °àG;½?+˜,ì¿½î@°º c/µÇ¾œ9°M8]õÓÁkd0ïÝmoQp¡ºj»û²»u¼ó¦ÛÀ–ÐMïõ^WÖ»w@ƒÎî®ÚïnÁx;G?©^÷èÍÎ­ÃQ÷°³s„«´upt„Pöž´8¸Ü8<vuÔ2SŒ}Ä îÄ×û»¸GÝ{sE,Q>– üÎG]Zh'‚·;00Ü=ƒŠ£A¯À1~;P{Û;/q[q¶ößtêîªÀ:[”í¼8À…yÙ¡ñÀp•pß¶;{»=3°Ï@.Ùn¨Þawkÿ€ßvy©ö{0WÜZx @Tö! rò>¯á  îkÄ¾ñ™;ØUÛw)ÕîA10Øîwþ}ÑÅÖGÝ}X(:c­­×GpÞ°¾£é½†¸³Ï»ó¥#¾s´èCFxû²³³ûú¨ˆxØó,!‚$tv‚[ôê 7_í¼„®¶^É¶)ï(ÿ¤^ÁV¼èB³Îö›:ŽÒrGÖfGdû¾oñÝ"x%†ÁÀ^)IÅe^è™Œl8òÙ†ß›"ikoôcÁg”b±N^áÊÂß,TxJéR" H]²t†%\XÿgU …—¢³c9¦þ(åLPLlù@w$äÚ´Nót„ùóT8™Å”Ñã‹xäŒ½ÂfâÈ`6ÔË²‰þBØtgö€–ÂÏ]ZÜ¾XÖµâxIû<çBûyÅ÷:uh‰8œëX‡–ÿ„,o„U@îxä^Ò.í­Ä:œA®œ‰ÌãŒòsàÜ©ø_fy!·´!ž‘|Ê5Œ0pïœ,ê&Tübñ4ð¯Îfqˆ®ÛDÓ(ß'á_Ä«oV5þ%­ëKÒ(F¬AÕ¡­øªS§Œä¯cwÈ‡CœŽØ¼=ÖA¢âl
"rÂìù¾–Ü»3 ùK¬™NUC¿(1A"r=(ÉÞºú©?5#ÓÔPY³ˆš¤¤Ô±}AWÏÎLmWºÊeSA®p9é}]ãÍ™ÿýœÒ‰ôiGCô „¦8‘È[Ï¥*‘–²V·êê¬N÷z ©Nß{ÎýË}­:lÃÛîMsß¸·ÉñTëƒârà¼¡jâB)9Ì=ýB~æËð­Æ”L6Ž‚ÓVýtÓzY³iU/€§¹»êÝ:I‡´q–ìa;¹*-ê£Z\C¢E¶§&¯+h,mü´ÄŠÓ®Š’,î<ÁKYÁ«±&ˆéáÚ…Áj²®…þ¯Md³Y7°Ô•sj‘Ùµdu#"õÃùt:Ùl·///[gÉ¬•fgmîÑ~ê`è&Ý¸¥M°ˆÓN²óÕãTóí|Yš`Õ(¼+$œ`ä
ÌÍe”W•(ë‘klih*§/[	q=²i g”®q¥IQ60†RÝF.vêìÅÂ5’²úƒôûüÆ'±„‡\š™Ö´ó¢w°ûú¸»û“«É<¥=•íTÓ+@Ðÿ ß/ï·,¸ây¶¬ƒhy4Â~Ø0éo‚À§Ù$EKÂS·»þ}w °øhY:¿š ¹‘Ü…ÊÜB¨ÇGc0oþéÛêÝLg¿ ì{§RCDŒcÛÒLÝu0¦-ÀJZ¯}*ÜýÇ×;¶ú±\ã@š‘­AÕ@`¼8M?ÔLÜ¤™bM1Ô’zà\§WÑ öj{‚¾Ñ/ÊêÓ…ú-¾n¼^X‰+€it±2^ÍºñMYw¬°bîüxi|êþÁá›k%YBÃ¢U›Ã7oÃ!–R¶. 4ÆäÃ‘nn±0 îþpå°‰½—Zÿ;¹]1@,KÑÉµ^W’lÇe)¯Ï(-“gŠ,â‘ !›ó¸mâ*šŠRîÌàÚžÅçèRÇ"\Jx^Ý­ãVpAv1,›gÝÃ(¡(Txk°¤eÜ`ô0¥caMåVLÎc¥ÓÉùUûòüª	ËÜMF­óéx»ó»ÄÏ í·ºí½nk<øJ}¬­­=yôHá¿ß?yLÿ®mðwø<Úxüä{µþpãÉúú£õµ‡jmý!<ýZûJãñ>3d)0”<¶ƒfÃá‚ßy2Êüûò¹§^oãÅoQpŒ—=PC"¢­ÜêøÍv~ï&ÿûÿú‰ZÊ¥œd
¥.I¨2·-€ú1IªI”\Ä &°Ÿ	é0ìßÑwj'¦%:žm„|£RP£ÎÈŒÁDµÌñE`þ uÈ°®ý„ÓÃNv¶½Ñ–q¡{œx:Ó®SÖ®t½X €cR´qÆ èÃ#sš«'™'sÚÎ€†Àó‚Ùø£Å4ÍP¼£èný@àOÑõN94))T	ÝšÂ·0{Ë¸­—Ñ[g–[z{uÔÙjP£gXV†ª!uÎ§³áÐúÛâÄ”õRÊ(0’v7r&|èFšj.á7¿Î$óÁƒt6€AµòódYú6ïdŸÍ¤•\8ÉŠÕ,éŸ³"Æ0-âv\— vÁ}ºb@³dzâøbN½úây)õ‚
¬ø¸H-äü}®^WÄ"Ürsð²ÓXçUÃðó9»DA%–†¼+»q2û Þìýïÿóÿ†Qá·Óþ{ö€£0q0ÊQ˜ON#¼1å0Æ¦¼oô4ÑçOÀÐ®Ú½iMûçÔ¿+ø`þ^êÞ–AÃqÐ véÞ=PP¦³Ia»lÜˆGÇ Ï‚MFlt®Ë’Ù¥S¸›¸'ònkkardå¯,2èÚKÁYŸÀbQ?¼_0ÐÿøÿÀá)­ß¿¸Íÿj«Ÿáß“þ ~QíÙÚz›¯m—;SÍó`cmýûæúzsýáÉú£Í?l>þƒBßÀÑñ&Þ"Ì†‰ŠWWÅO«ÖZëRxc´ý—j“1´–³ÊÆLì8¬{ŒuW¾ü:çë¤Ëù¹y~ñü÷Týp Çv·{ò¢Óë>ÿE-„§àØ¼±³3Þß2¯þÜ›ß^ì9Ï_Àó×Ûð}ëÏ¯åñÂŽ–Œ¢y^i¡£ÍY­’Ü5F©ù,ª/w1œÜ+w„¡÷¿eÐ
kêBsž«mMiZjY0;£Š-Vétµìc	™P8o¼	Ð·ùqÙ\R½s…‰à\40g"«ƒh¢woEÿZo-ëbÀ]  ªrTwa³.ëe'}ÎO ~ÁÚªO¨P´@Ÿ”—ë©BŽ{06Óè¬Å!ÕƒÎ—-D‡¤ãýÂŠ#5u&G<%Áºò×«M?ÔkËz¬8—Kz<ûïg“¼ªOþiy§1wêS…Ý¢{6+º5?.=åUÔiÉl…ÙW#]{£w}iß_c¥?Ÿ‚î¦gÄ'7U{:ž”xÜ(=C&^áL	ÑsJ·‚ÜÅ#Vÿ€‘¿qégÞkž>x „‰kÞKÌKsÎ"C3»6,#ÃÛƒê· ç~ Vµ8Æ±©2¾¸©ŽOhÜ´– ‡$Ú!(¾ÁÖÆ*:áJù¥–ª’&¢äl²Öé£ÍE¼à‘hƒåÇJ	ã¹HãÒ£ÁÂÍþCsm£¹þäd}móñ£ÍµÇ·“GÖ[k­5-‘ÜIï·_æ¾¼Ù…tc<€‹p4‹ò…o¼ÎuX”õ2]À6©R®´¹’ËªÍçYqƒÐÒýÜÄîÁs@¬·ñ˜.z·{¼u²up´¤û69qÛ€ÍKÍÈ²w/¿»ô=M8}²¿‚å§þ¨‰GÞ`ÿÅöÞf|:<:Ø~½u<wýuÅþ€B¾µh+T{8¾\ßhm´Ö[[k7ürï­ü. ÿ©ó¦S/Î³ö¯ ¶¼_oý¡µv²þdc!¤ÞÖÑÎáñÉËÛ/cÞ|º¤ð5$È°ºV]øÚ9Û­ÁB3¦˜s˜Šñì6g\À÷f§»ú­eG±ê­25øŒŽ—Ÿ¦ê÷npŽª_¼X:ß›œ¾4F€8^X¤nò"`ç4<¥,Eú«•cäýÍ^D«ö'oë¯·Ñ:Ùî¾ì¼Þ=>q!ž.Øý@…<)£…GòèT£ÈÍmú
=|7
Iý$ú€¶R÷	có„y¯t;@¿$—)ˆò6ÖZçÿWB xß¦ÿð»'}âh^ÎÃâ÷¾–Î{»£ÿ,,P0ŠOÛœÊv€åG<ûçhÝï4"ûµ¦5pŸ´Pl<üÃÕt¥gYŠá*~ó>arÅþçYo¯5¹š	&TÿG|9ÊOài>nIíÚÂïšÀfù¤ð  ’UPúÅ_`ƒõi­ K‡m&ñ	Ö’háƒ…˜x±û—Ž©0õOdO¿8Å7C}H?Í"È|!©Œ`‹ºÃCUèMô;ˆV‘”Õ?	%«…¡~4GØ½ÀCöb‚`O~d“'o®‡ß”\”† 0èP-jsî;«íñ²„àžÚ:úïí’Pl$væºÎÑÿ³ª­|ÔÍ®k EÔjê—§”¶(E-šCl„’Ëu»¥Ûº­”jUµ€_¢‘ÉDýóTÕºGGGÀ‚ÈŒŽžSå›Ã8€ÿÁL¬ñà]9„gìœè¿øèY­¥œ)´W>j"…Ïv¶:»ôËÉ~;ñ¨i;Õ‡‡®ù>ø|¨‹Ù¯™;_"˜avŠÏÚy:ŽôA3¿-„+e<¸ê-Õî5…fªmœeHÎ	*õb¶~ëd@Aî|M¤ìglHßÛAÃ±~)ÿ´UKÿÉ‚ëƒ–ú¶•MáD4·(7##F„Ÿr˜Úc^Â4‡«<p_zLeOÀÂ“"Á°¦ñ¢#C§E›Ï::·=<«T$Ù, jrx–Fçú’S²ìuF{÷ð†FÇd„kÝÉúçñ4"Ÿb¼¸2vÚ¥…Æ.ô†Û4w¬gà¨Ør%†1ãQå|iÜT*€ŠËµ¢aàyáÎ‹XnnÏM•
}»X¸#má¦È¸
XöåÌqªzÆÚÔ°=o‚›%Õfqoe3¾cÎTqaáÙ;¬GÈÆ¼'tsæsÇjGa›N!ð–oò3!º7wMˆ©î\{Z6ÎV¯Ž7\$hmÁm(–wé"¼8±°’|eñÀÞ3Ø£^’@s,¾g¶{á.+,mO+>Uø|RÛ“l‹ a³üQŸŠO°¡%ß.D‚h\ø¢$Ð0éD\»–ìãv…9AÔSoÆöê„[ë¯©ïgNe‹&$jWaæò´4R9Lz@hÞööT*4e|iN~}€w·;‡ô¸!.þ»×ÛU¦ÞWÙ°Rd@<PO¤¬XU)PØaª«'ÂœMÙÌÑ¯YYtÙpê¸³3¹{ÂCuÌRZ}ýWèÇ›P)e.–EAÿƒ–ÚMmé¸Ò4 ýŠ1B"WÓáøªÈ¿@°vVbÑ"Œ%<µ¸\€ÕŽUq‰öÐ!w3GzÆôÊÒÒOw5FÜ1}Á¶9ƒögÖÅü‰‡Ç^"è¨¸G£‰Z=¯ÛÊÜØd10öŽi4ðœÚOñgY´¢…B/Úœe’E¬\­ÒÜŠ°+w­eíÌÜêó ¡Æ~<–¡"H5X×-StàŠa~b¦°íØ©¾!Ó/Ë«–ªÙXŽV–ÆÒÓ@_zI‚¦¦Á-µ‡5œ=æ¬ßÓö™ê¼UVÂ‘^Ž¢”ˆäŠ;u‚ê=sêî¿Qo43.êáùzND}T³µ¹«Ù]%ÓSšÞ®7„®]'rC­ôé©™ó¿]n•³®ð S!~Å8±¹ë*ŸƒIÚ¡ûõKºvçXÔD‹§\14¤ÂÐÀ¹Ý…h™á•\EóVf½±x‡‡¢›&§Z’ ±ÊbžiÉ•w‘eù2©ˆè ?ƒ£FòÉÝN½Á˜ebÝi¥H,rŽN¸W=¡hYæâ/®Þj³²¤ÉÆü•õ¾˜sõÆ—¥3KýÅ+cÖNs÷ùC0Æ·mž–ÞéI¦ê”(Ö•>P~»€îN8Þù³vl…š1ØØñ²n¼µ¶ÂxO³èŒQÁ‘¾ò–¯Ÿp´L´œN8È¼áº»4o¼Ô©v2C§ˆß. øÎân§~ÃêN±ßÕüOõ~PWp<–v¥oŠªšßgu*¨[õÎ.
ŸªT*Ç»Û;/	ù1mc0mâ‹Ÿ?<Ç!r“á¹Í]„"ç€ó…;uBž*Á¸L~_'¬_X›á>(ù¬¯Ã­‡<„Jqå¼«¼ÆÞùüÎDU‡PºçÐtãSšhìr”Š˜²òÈæpOõ÷Xm!|`É¾²Í ±Z‰ãkêI?¥lìuvö+ÖxáiãËcïdó?Ÿ´¬¿Þà£eB2UM=±¶*¨¡—QÀ`||Î(pîÀ¯@¶7NMtvt?¯<£c§jÐÑ<¦âýT5Ü6<ñÒ'mš+Yì¼’sç£å%wDñÝôf=“ÒòÆ*(FÒ?0}On	O°¶&ÖÈ£Ê¬T²‚tƒj½€Gp7rþídvga
£Ùmu_1T"óÀÉîNïØ°³rå»NÃ÷ Ì“_>î¼`@‡o·O^îìVÉ4‡úRp£ªêêi +µœqÝöw|r9hM?±Àm¤sÿGÇ¥¾¹¯'2}9“ËÍ âð¬Å€¬Mm9¸£îá²q-qË¢!o	Pcë[Lv±jå¤­ëƒ.î”4‘sÕaÕOŠ§)àþö'…YÁ‰ØšüÑH8Ž“ª£·nóÍÙ’@•ø²i#œ¥ådúˆ=
ýú~¥ÀvqLƒ|Ž©è7^t{%ÌyšOÑxÕðpy›=|6«^wëâÁhs“ËO¼—|+?gÉQ±¨‘‘«”x¸çÚf£[IŒÂËôK­*ƒâ2OBV.F‚Î3Êðr{0v2õƒ¦ÏýcÝRüÝPH²ýQÕºÊ.©î§£—Èå4«–ˆ:Ãßhã…JA6‡ºZµO9è^RDh¥C€F7e960ç €âßnSr±ú€40þv3Ð.:ƒ~¿`Ðï­ÏŽ®AÏ¢&>–¤A{<ˆâ¡†câ¹	ülÎŠ ø‚%w,È¹œVƒWœ—˜çŽáƒñ"NçBÄßÒI”ˆ<áÝ¹ô“Éè­¸-Cr²~užƒÔÝÂ:WBßZ¥B¡_Î.ìEn8ùRêîÿû,_B®oJ¤K^»2‘Òr2ÑÂÂ»Ýý_=—éÓo—øëGC€”iŒ…C’3&Ãæ!›õµÿ¿½o]oGÜ¿«ïË;à(™q’±$Þ)¹G}Æ±´§ØÇ²“žîôçá”•È¢F¤œØÓÙgÙûûkÏ‹m ’ EY¾ÈŠÓMôŒcƒ@áV(TuaáF wóDì'—ZQâ4y…§ã±°M2…÷_ì¢"…Á›ÒQ?>Íb'ˆ…ÃÍd0òRêu4ÃE\ÿþóŸ¹Á¶!CM!í¬¹4Ÿžø„ß(ž°WKiþßÿî‡§É¯¯hâÝ[ÖÚµµm•ñ¹™6ÀßgÑ¯?N£>žI½« ‹Ófr"ôe€…yFr>]ÅÄr6¿÷šp	Qx²ãz“Ô¾ ûüøà9Vx¾½ÿîÍsvµû!ŒN`Ê6\Ö¯˜X‘y¶g~€Îx¬”ä eOI%OÓß’Í,œýðÇ§ ·æHo"…—¶ yçI^IÐ¦ÅpÍR£²÷3œ‚üK™@{ŽÓÒëXRJPAÊèŠÖÉžÉx­ìÕl“¸“QöÂ&‘·"ŒnðÞ9³ÄÎë§sÈ:Â—‚Œ‹’Ló<„
£â4Ñ'Å‚ )NñS¤ 7!Þ×c¯™4_z#‚g	Ú6çšŸŽ[ÌMB†ÏÅ‡üTS%ÅdN˜|cúëöî¡ú=ûGKHâ•š = àJ#F>@|?™ÜI‰j‚ÜÈ1W–Ãnc±§³gØ³T¸+Û«M²É•ÐØT"±:réTKJ¨‘Î¥
²Eha%”:ÙÊ4öÜiù„†Ï‰§‚áÚBÐsÙ¿Ü'pÝ,õŠ‘”a\È/¯àß©»†ÏâåËÑ0î)ºÁ‰6Z-DÉfŸ‚uÖbŒ"œ³-æ ©ÁjE­gµÚsòËN¢—Ï³3(€žNàØNEZ¼è3¬M]ô„>Yîê· Ò36q‰‹´¤œxÒH13yWxT:×›J3ºL]+ï -õ¦s7kÑ<N™³ ¯íö%M¨´ßlÕ}µqµÿE1T-õÿ£ØÌÿ¦[•ÿŸU¤Z*àRNcÎñA%×ØsÏj×»„(OEõÎ¶gÚ¿L§!ñ”9ÁÎy?âÜ¥Rw¾öJ|Äö¿˜ñftêÜGö¿¥+zÑÿ—mÕþ_Ej+Ô1ayÚžëèTÇ}PUo»¾¢w<[÷}SU}_'ÿÙlÍÚÙ.íPµcµ}_3Ý¶©š:õu«­ùah;°[1]E®ÙšºPËpÝ4]Ãpì¶¡Zm§­m×v,ÅÕµŽo¨T®Ù¥ulÃ¦–í(Ð€nÙZ»mZÐsC3”ŽjÁó\­#ÕöÔ¡ŠÖQ=»§éj [×w)Â÷l7P<]mû¦5KŒ:ÔÑUÍvÛ4MUéè†ÓñLÏ·UÝƒùê¸V[ít¬ @'QGñ é;¾ß¶‚Žã8´Óñ4Ûô¶ÚÖ¼N[¥šªêÅÆeË¸@s¬ PýÀU|Ý3-Å€fÃ´LWÕÍ¶çx¦{HVt¦ïÚªc›0+¾am30|×u\Gk[Ž¦i¾æjŽm)Rµ¢Å]ÛSUUsÚ Þ1UXhÇVÚÔï(ºÛétª«FG3Öò"{2WU]èÙö½NÐ±©é@MÂÖÜ¶xŠ£–¥šyXå&q¦¦Y¦Ó|=ÐÚ¦bT1ÚºãimfÈ²øì·}{ÖÌÚ*zàyJàzšçë†nRèfÛQÛ²]¥mSGUü 6Æ,(Ùf[ÕLÇ‡)65Ë À\ÛòÉq,UÓÇrçuˆ÷Å¤FbjÛò;]	TÃtM˜z€®Z³£* m	ÉöÏôL¶2U`0& vàºžîXT÷Mi»–êÙfàÚüÉ¹%îÍ »)Î (â£sl0°DºG]œú6ìLÇ…Í¤ºïi°ÃJÍš@¶Å\fV±†V{_	LÕðl Ž£éãû&™njmM1u8ÑÏúà0jÂOC1Û¶Gñvavòv§. ±c&˜Rzä´Uø«£t,ÍV˜q§°Çò–¥ÑYÍµ5TÛ ®Ói»n§m©°ðTƒermlAÑêQãJ85j©Ð)Õæ)¶
Cjkª«Àþp€;Eä)@Aæ¢fz˜†ÍS[w:†§ÚHeu€O¯—êèŠ[œ\fR«¨'Âª6[´S G¶îÂú¸®bÃ@Ømnª®{EmÛZÚ)i$ 'aŸ A'L&5àDTTÍkëœ’×·5ÛÕ=OSË¡*ŒÄÈžø §fÇqÛÔ6µŽ§¶ïVÇvÚ8+TO^×Õ‚Žâ{å0µ“ÔNnü”ZJÈ¥¢i,‰ÓqU8·›zÀoÁ pÆy–Mo •Í€êt‚¶Þ	,Ú±<ß® NTÇÒ]Çqá¬ó¼¶¯:Ôœ3¯ú	¿È;A…È“0ð.Œ÷ ðØ¤Ð3ÃÓ‘Œh&°}œ†ÔrT©‡b–‚ÕÔnV2\âp«ÌÖÑSLj8ZÇs×†\í´ ÚŠÔ)pÊajE˜Âô½Ì5©åHæ€È¸:@íÔvGq¿|Í†Ïæ•zí Æk{uÎ©¶mÀñßn¿¡j–mxžŽÄ¹°ªŸHG'À©±ël#m_ÄÄñ+Õu
ìfÚ>ìZÃr- (A )Öµ7Zú[€§ ›ëî[®f·í¶Òq._õ= "@ŽT†ò™Õ‹3Ëú©êºíxHtß ÞM¥°,_³¨âÂíÀ©Ý±ìR˜¢“üä_ÔœÀ2m !š´Có¨ÅØUµm XhÃ±`K”£“ª•Î&[ §8@<L8ñÏöL`kß¦Y°;–[¾­Tå„{(”á3~µc ¿¨´-Ï´´(Ô`»vð$„Ì„iº¢:Æµ×ˆ€:ð‘^ÇT±6ì09ï¶ÓÑO¤ æG›G¬JI çô,Íp=v¹é:”Šâù ˜Àû ß¢ {m«Š£0º2äÞîÖÎ›ÞNM÷aH®ï88º 0`mƒ¤Ô‡Ó1ßWÝ¤^æ06.0~À €T ‡Ì»ªé® êøª§xªóÃyKùÖê*¸/)!/tßm ÜošóïÿP^ò¿¢é(ÿÃ~3ÿ1ï»c˜þàò™´ì6Üÿº¢âúƒÜ` _Âú¶®W÷?«H¯©H¶øþô1IÈobàCô‚ÙÛ<ˆ{œú3é‰¨§/¶{Ï NÏ¡}ô"Å'Š(Ñ:ëXD¼‚“*v'Ó~ô>âK:A§ðµevÕD›<mÌËÂ÷MF|ïÅ4@kvNž†4z†( ¯ÉïÅÿ‹ñã]9ÔÞñqymø¸ÂQÒ4ºÃh*zSmÃ@yüÂºy0`<O^–YJ	+gY7‡ÂÙžÀ”³9#6¼ÀwÑÌ‚²ÜèáäWµa°o,|0	ÐÂâ‚ZúÇûôê`¯¡7•¿,u_c¬õ±tA1ª^Ì#'ã€`2c(üÂ,ÆæmáïÑR;ØH¼ÛÜüÜÒŠc’˜¼¨sÏ|êg6¤ô32nå–8õgf~ùÆ4áP^Ä"ÌbÚ]ô 1¡\Á.]Å£úy¦3ðH/€C\zÃš¸\Î]l4y›GÉ›w‚pÂ,¾àóEDÝö}IIBj™ÅÏaðX¸3§Ïõ÷öN¶Ž{Gû¯wÞäFóRI0¾¼UpnNXÁY'£Â‡	{›ö›9«‹õœ_ÑÍ ƒ9cá)ÁDÍ« JJåí10”·àžr¾¾à37J¡åzJ]Ë©³–öoÖ8C°lg#A5‹a
G„ÒªHf37 ˜ŸDÉG´Zò·y+ÐX—Á›µ¡’à¡ÅÓ©aEg]ÉÊŽNr¶z…6ó¾Ð1%Â›õ+ÃCNÏ+©\	=W>f€·CF#„æ°3ºˆYxv—&Q¬ò´%â±B›K¥¢-ÝàßWÒßÝRáÉá^Ú¸šÿWAÌW…ü§›š©²÷_­ÒÿXIZÚý%€y2ÀCfÿóNÌ^
GŽ‰Ÿ5¦`Ê,>%ËŽ"GŸgÃ]éŸ$“†\œÁ(Qµ,zÈI¢­
·"ð©’nÑ?væö€Ý–qfV›7i·×Å(v>ó¹|»yØ}‹ž§–8™\ƒôÔîÚûéßÞŸn¼ÿÔ"¿pw…	kùåW²–”ôüÓ.|ÍØ¦/Ù§›¯Çí¼¤nWòƒ˜eE63öør–n±©ÈW,À]f–¿RÙÓÒ²Rá|`hÉ›•Ý¬Ë…9ÅOÂÅ·( 'yWRKN²<d'¬fšÍ&q÷Íün¹d,±µÿæåu'„¯Ä«ëY’¶wÓåM…‡/BˆZ”’ìüÄ¬ç æï3 Ð'c\Q1zL/Ñƒd-às~ó&^*›Ët£
ÓÏÛoªÂFå„üóÅewýÚ`Î“ÑÚRé '¬?g¬Q˜Ldº³Í`Ué2“é/5nB„«?½árI"§~¥ê5?Ñšðš7Oí®y>‘wówÿ&Ñ©MÏHÃ#EuE¢}ßòéyk4ë£	^ãœÔ7Èþõßð„ªG­òrswogûI«•æ=\÷ýjg»UÿŽ0¢MÒ`•òþ)ùÒ0sºÜZ¼FãÉ`+¿}v&}Xq%íÝXtàåçó`¶£¿yp06üÿ$@“»±¹½Í;ñå·Ñ­1…~ÀÉÿQ]WEø+P™‰!LÁe@JP<¹=IüÉÅýKÒ8ìüNøoÎçóú´©î/×½Fâýõ`×Éw°J’MþšXL¤áÙ
è¸TÈ[Š·š=MJJt<û:(T ´¼¤P‘|IåOç–—
¯ŠD.+Í|)±
u¹qkÔåRHÅgKAn®õÙR+—š-!}Ýü´æfÌ ©v£‘˜—¶ñ/ÈdÄQ¶Æn4â	ÓÍá~…qùÛoHÝu3×3¯™áê¤.¾'¾›Úqg˜DØ‹£íFƒ|Ç»IÀ5‘‘˜…è+ã™¿i0è¼¸wÄh_=œ¤GÒÚ¤Çl:¥ý¦`¥˜~óOìJ3¹Q'~ÉŒ!“ +1K²†ÍîÚ0ÂOÍçÐ9/†“®3Ã´@wm]]íímít·v†ä7Æ´¦…ÊK¹é÷³Òs.ãpÂ»0Œ'iVÄ³ÊúEqœÙçÌ¢G ð$eÂˆ”/ìZæz:æ¦ã,³˜;@kCk k*WïÆ7>ÏªÓ›UgfæRuÀ©›P9ƒÝFf—.øØ]Ë…¥-ËŸž}ÝÎÀGèÃ™3¹Hº5ƒ8BsD¢ßÏ¿ƒ¥!²jÉwäË{Ì;àÏawí|#‚B··¾Æ¯¡÷_ÞE­îuW“ÊÕ¼—ÛÆýÍ6TÿÃb÷¿¦n(Õýï*Ruÿ[¦"<|ƒ×À²“„ê6x1
<èÛàoó:øZ×‹_ãúŒÇÜe®ó³±ÄÁßM,Áža-ÉE3ZOUFÿ3Ë¬û;cÙÿë†•éÿBAEÕl«Òÿ\IzÌÈ½ÜÏu#ïRÏHÌ×x>®‚ŽL0OÏòzi¦Á37ÙåL’iòÌCé>'ùdmHŠ™$„dPzìïâíÞÎNê¹ææ;ökÏòÃMå†•ËmcÿoHü¿b þ¿a)•þÇJR¥ÿ-ñþEóâ‡ÉûÏÑ /gÕ+ðŠ¿QgwLùýòÏßzÂðÙ÷ÝÆ5íÿLÍ6tK·ÐþÏRôÊþo)³	¾¿6n¾þº¢)Õú¯"¼ôÜK·XýÿUëÿ)ïç~Ú¸Åú›vEÿW’fÜÝC7_C«ÎÿÕ¤9^¨–ÚÆ‚ûUQíÂú›ú¨îî?=Îé¢´”x¢OCÑŽ|¤‘ù6þG˜‰G~ý‹jÿ³™eÖ‚‚:Ž¸jµÇT«åÇAŠ3±¡íþÄ9‹jµƒÍ£ºOðçÆêª™*‹ön”Ø@9¦Ä}J½™•-_à0ë©M3ïw]Òö©“.©×ÓÞ’Œ¬ŽŠø@“†U—KÒ,+_è0¢¬ ×¸Ý9<Ü?Ä—ÚÄÄšõ©´&LŸ¯ÄŽ'ñaÏ× ÓŠ»†zuáDátÂã~É“^[X¹Òºù£¥rŸ}Ëmãºç¿¡šª­*Hÿ5­âÿW’f|‚ÝC×_CÿÿgTþŸV’®çiónm,àÿ€çÓ“õGouDÑM·+þoéñ0 ¹¶GË»tt›×ÀG·x\rŸs‚¥;áÑÝ]ù*øhþ³à£ÙwÁGÅ‡A}\NÏ@†C:"¾ˆÈ•9._	9œ>ë=š÷®·äõ_ö-ëio©}dÀ„¸‘†#”äœCÉâ©?˜pó$åÙoÂõ¤Ya¾™6|Ë1pyEDÍE+XÌr_Oõ¤ÊŒRÙ(UuK+ÌÊÅ
InV.1ÌÊ—Ã\	ÖLÐ[róeò±b“2˜[(—‹{›–ã–‹iÉíÝÃ×›oŠ­òÜ¬
XÛ3¥xî¶|y{FÜWøÿFDQ ~ÿ„ÂFÃ‚"~MVä YÕç©Ö“âè$eo´ ÉzWüš³Ÿ©Ëë”,ØÊ}Iò‡¾3>`ö;|ÂåüHúÀf9ùÈLô¶ÂÑˆéyÉ¥ø'åÀàä¥–ðQagÃŽyIDÖ½ADý-:‰ñº‘Yâ6SGÓê:|8?k$êâ»pÒ|†Ãh~©QØOÂ³±”q0	ÇØp“m¹”ÇæG«‘Å¯íým,àÿl]Oýjºi!ÿgÛ•ýÇJRÅòåX¾9Èÿ¹¾Ÿ§‘CãËáÀÃˆ‡Ðm´Æ˜`
?üËøm;ÙÛÞ}	¼Ó„)‚y§Ä‡<ÁE–{…'ŠÚaÎ4€å›tÔ$/è þï;“€|tF#Ž5áLø™3šb ÙÜ_þ )ùD'>@‚"Wz‡>.yÀ´ÅÛdv„cÎy§°iÝ)ðƒds4„=<"7<ÈBŽ„xŠ¹ð¸ó]ÀÄÁ‚®¡{5ÀI¨ñ¶Àù	<a)¿í†æ'Ÿè 4*«˜b8€æÝ‘O?Œ}Ò>vtN½Ç	 Ïa¡Ž&ãJj-mšýÑñFÝd–×á÷CÜÍÛo"ü+m>ª…îàŸ¶†@+7 •h¼?é€¸Ž
ßÆe™q8.äøQÃúŒ'lø£îóB‰pÒwFÂ·£3LÚšJäùw¯÷Ã¦©j_ŽÞ~úKï|:ð½ãGv'
ŽÔÁñÁð]çÓ+ÿû}µ=þØ:ýøéüç—ýó§öwNwß~<Üsþk¸sî¼*“­W——Ÿ~lF¦a½íÆ¯^´~Þqèt°÷öQÍmH¨åþƒIÜ^Rf&Þ(Ì,+6ò<@¬m »Aë¤ È‚#Ž°B@\ÎÃ0üŸNÂiÿ´â¢Ã	Ÿˆ—4ÿ¥?8§£7.z°Õšl!ÙÔ
qäçöÔ­Ðèžö9ö³ÚèkâËiŸ•‡”wú0GÄÁoð_>‰˜&ôÒˆú°ÛR÷_½¿þËï~ú~šþø™º}ûïÿøÇ?âKûç‘ýá"ØÞ9=:ÛýaøÓ»¿o¾ý¯QôéÃ_þ®Žhg¯ýéÕÁÇÏöáEçÅ›ÖÏãÍÖëVïëì_‡?¾iÿK;T8˜fhåÿ¼’JäËÍÙàiƒDŽs ‹tEÊÏÀK4`/ËKðUm 3æ_YàÓöDy	t±EaŒÜÕÖÕe&™—y€.ÐSMÃñ†sº‚Û}Øá¥ËË [êFt1òæ| ã!¼$ÀÊ‹}8û8Húó¿ÏŸ2üzÅ|!ÏßàZWà|ky3ä/æNTâïg›Î‘ep±¼¿Û`«æÌëŒ(NcŒÅ^Z¨üœÅÃ¥7Xž9ÅÓ,EõÛ¼oñöäÛO×`w§6Üÿ˜ª•Úÿ©ŠÆÞÿ[«îV‘ª÷?¹ÏùË Òðu®‚4å:WAXuÀÞÿàP¹ŒÅëŸ¸ J\œr>÷ø¬O‘§oÎ^Ç¼šLG~ÊÙcðƒÞÂ0<‡}Œ2J®‰œi>1Î@b¾%³–^õÆU Èç…ŽMñ0ä—>¹ªêèN}D‹¿_ÜÉî¡$[°(ÇL\ÜŸq$nS¢ÃÉ„~ŒIŸ2Üƒ)àà)“ðŠ°ýÍ^¥k¢,¶»õk’w&?qì@9qï#†rP(£€…xÇ€$•¶ÕÆDòh:BˆèèíV‹×I„~Ör(Œ ’éñÀ9—|>OvOs¹+’¸FÉnvë­p‹P1õ™"ø®×­|>ƒ¼àO½1^ÕšZSm~Ëu¥—A¼òðýòoüÑ­Ô£tÑQò ¥ÝKÁ€œ0?›R?“ÇÆrßÌ¥Ðô–‰><%éãa×€”ÿÐUõv§P¶×Ûëª–n²wºí+-¸Ù0¸ãîI¸Ù­»„|Ê€‰Þöö_½Û<Ü).[1F´ig8Ñš©u‚±i jò÷—Æ£))÷òõ»\±àìSI©£·Û¹Rñ¹ßJ†ºÙÍH]
¿GwË};¦¥`Q°”E&îŠöTBzóåúê‰|•Vüqç½£ýÃ¢Ü‡ÑˆƒY¿Fó!4ÇRïßìnýˆû [O~Ë†‹Pëð#Óagãó{÷ÉÓôA^ò=I~ûi<I´&žáÙû˜À²9j—)W¨õ\®Æsµ|®Îsõº,çÁÎ¸NW¢ÙCJ×6~‡6È†™ÉðÃ`ïÿV¥ÿ¹’TÉrŸóòßœð•„Tü÷ÿå¯0›Ó~? ·,Ë‚/œØ+yÌÿ1!oú¥z¢™¡Cý8{åg¾fÊgïKg››2Ë27“	IêqþG`qÃ…ÙjóÃ–C]g‰ÑAÝ¦]†LÂœ…17ÓZ`z
 ¸\Ò!VgS'ä€J½e¿’†,b$cö .ˆ¨Aàë3†ŽuŽ%ÜÅr>Éb’rî	Cßì¾šñ®Î!ÉñxËa	½Ý{ï¢º›êí¦À~ª»KTÉMð!_*ÉÍÊe«-—Ër¹ú./»éû‚æ>{ìU¤Î´{çº=m¡’,Z¤f;.Q±MãÏªõÎ¸Ä/UéJ­Øu‘ƒèÊýÍçç#`¹ýECL)ùõXT¾ã0g”uÏéÄ…c2ù35*Ã‘àëâŠÿNŸ¦®ÉÿßIxÿ¯©†™ñÿ&òÿªfUöÿ+Iÿ/÷ùüÿCWægÙ*RÈøUÉG™Í¿±bð±¨RþFØq¡è”¨pðFÐéòálÉ’»‡uàU)—fÏý„oºÔÓ:¦Qwº \hÿm(Ùù¯£þ‡ªªÕýßJRuþË}.žÿå;áaÿÒ :â½&CÇê Ù“6S~ü(pTÇqŽu®ìð?Ÿ¨BŽï38àø'¦1É™‰&ÙÁá3Ä›9€Æ¹©‰Op~
u\êsGW÷qwécuw¿÷qûbK ÑàÓðÀ÷w7wÝ»­Åfé¼\öý•=^tÿƒ„£áGD˜”tN8AXB&©¼7œúôÅºÄîh’žg—8L…}w›iû3ËˆÔ0}$—Eew\=¤,w2@cþ†îŠfø?M=á—Å6ŠÕ{ÖÿÕíÌþ[µ5ßõÊþ{5Iâÿ–wÈÜ†û»ó·ÔçX?U;‘bõž8¾Ïv‚Öd³ôƒ‚H¾Òí+Ôv—b1—>²ÁØ½›sRó©¥®Œ–üÀ9%ì¢¨Mœ8³`§`Ù “P¾Kl|yìÑµ¹#£b„ª…¹øX·è¾p>ÊaÉ±Óç07å9®ùx×@©ˆJŠL	ËÍ•ÑJËhY®xT¼ö›¢\ðpç`æ¦Å®~y¼ÓU¥²37·hÈ:f~ppùt“ðŒÿ®Õ=ÅÉð¤fÞ×ø»\ûŠåÀÄ›\’'MXR|¤°ÁH ï¯“ûP¨(\úH}jÂÐ10kõ'\×³ž8	ºêy¯–ž=óÍºã©Ýdbx zÒ8M&Â“—txÙ=^yüìYþO+òÚJù?UçüŸQñ«Hÿ':\ñÿÇ¯ø¿Šÿ{àüŸ&ñê2ù?õüŸö{äÿÔ?,ÿ7çý÷.
`ø?Æ/åâ¿h ¨âÿV‘fÖ_ÕKYýBÀ"ÿŠ™éÿáÜÁúëFÅÿ¯$Uü¿èpžÿŸ¿	>ÿŸxG›aý™³tÝv6ã9ïÊíMèÓoCNøB?W²Äƒ“%ôÒ2úïD– ³–—#$éÄÂp\¯ßˆ_m$Rš—ÔçÌ­9T@a> z‰‡ZÂ7³KÑ?Z+­]	Z+-æ@ê1.:Œ÷¦*íµ¬Žvu­\ô)•#Ryè
AâbÄ-dJý!É”z%S~Ã2e•¾t­ø÷ûþc+fÿKÓ™ÿÃªäÿ•¤Jÿ[îóÂ`ß–òw>
Ø$sB~C—s¢bÜÖ¡C¼P×pçPê½aP©;‡Jƒü}¬4ÈäI*âHŽÇx8éK`P¯wr°Ùë½Û?Üþ’“~Tãm 5	ËAà÷O§Ø60{ô;â‡<SÔ}òøLÂÜ€M'¸»ÎÈoP4|Ô7?;K¥Ñ©Cf}ÒøDTþ8¥°nQŸeÀ°¯¿@OG Ÿô)i“?ÿÖ%ª“n—<ÿ€ýú<ŸÀ‹YÐd‘_sÃKw!—…ùÐ€: ™$¯Ù¾ÆPãºâžÒýž ¼|UhÅÇ,Ãl_Ûç°1àö,üuØEIÈ°Á¨[Lj+ðßýp$à€ï¸_ê2,ümŸ¹{$Ç#¶Í%{œsÓ”JÂ‡l‹ÍÀáž¶l!3°õï%ø<BÃFŠ‘Ç½Ã/dNµÍ<t¬Õ—;-ÙJ2wIµ+XDy$`Ì~ÖTÀ‚ÙñFp{_¼¾»Ž“Î{0­A§%Y„+X£oÊãÍÃõf³|w5KöæëQ<çøn¹‰K›ÊmÍ-SeÅÿ»L³ú¿zQÿ÷.Oÿ,ÝHÿ—Ç¯ôW”ª÷ÑáJÿ÷!½ëWú¿Õ›ýêÍ¾z«­Þj„þ¯¸™b5ÇËà1ñ†i¥üŸ¥+DQm]Ñ+þoiYçf‘åÛÀÄÞ{1^þðè>»`æ!úšÜ^‘Ùt¡÷0~µžÝTµ¦b¼9Ü]ŠÎÖY²ž9ƒo„£{Ðšš5nò@ÂI°O™³™ë;OÿÔ|6ç'Œ¥c©µš¢l³Oã§kÛû¯7wß°ˆGkë¤ÎHé	¯W– ã…ÍÕ ð¼B ­©¢¶xµ¨õ§¨NþD¤^<«±è„ 8ÅO‹PÅ;œhÔVµþ,©EÃ¤þU•{½=©¾–Õg²ó†“ÝucÅOÔ…¥xõ´ãé+©[Ï? TO°CkÙÙÖ\Ô/Š~]+LÆw…âÉ4ÏÇÈŠóËöƒt³âÙìKã•$¯Q,-¦3«pœÍO)xœ¿¬tú”5§4Î”TäàÝ^/!<‡Ñžó”w/œN:ÕÒ<¬çÞÓxJÖ)›^-›«j!¦È™›—«*âL½‘6W6?‹je³Ö™§%qU_û´^~šµÿ™õqÛ6nbÿ£ê*·ÿ©ü®$U÷¢Ã¿Ÿû¿Êþçp•Õ]âC½Kü}û¸•ýöÀí7•ýÏýØÿT>%ª;åEçÁ×fV«´ô4+ÿ)'œ¶ËðýÆµÍ,þƒ
² ÆÕ«ûÿ•¤JþÎËs6Á7 ü0¶‚3ŒAŒCkœäpŽ
Ê Þ7¤R	yW
y“JÈû
y%†(ÿ4-ùL0ôbf˜ —ÎÀ$½b*ëå4¡sâ^¦}#Oô3ùÊ[Ð´P”ûæ~Ù:ÝDô»ºVNø“CUäXþsžÿËW €ˆ3ÝRîk  Á©„ã’E+JlE‘-›Ž‡!µÍÌÜ~s¢ÛµìÿÑ*â<æBþ_‘â¿j*ãÿíŠÿ_IªLþ™ü#ò?d£n Y¤×å¯™õÿ:šâ<b`¶CùÔú©`V4ë. ÂaŸŽ0¦\®)ø›Çi%ƒ3Ñ3àÞ)Æn£ñeÜœ5Ï—ÃÊfý>3ôw\f	s+þQ‰ÿœ1$ä™INÁåûÃ™Š,5€˜{£nf¯ÉÕÖ&@×?@ý„ƒmü„öÓs`À8ýaè:Ã†'Ï’ùñÜ†ˆ	ò×CÚH´æ Bè~€žx81—ž:çƒp²áxÇ•ƒ;ôqÉnÍím³ÌÌyAA
¢æNAd‚Í‰qÊï¬”5˜GŽÇý{S7žÀŒ5Ø^ñé¢W @{ô«ß1|ò:9›R¶Yp³¿ $ðNc@5˜¨ÙÜÚ[‹`Ç9¸?Ò2_¶)—:lDtDE@M@ôx°RþNRTGnÈ'b78Þ`£þÛ>E…îûºÚÔšmCiªªnšVSmÍ¶b¾¯?ÃúO…u$ýŽ80™õm!Çô¯Ø‰x”N<NÝN˜4Ñ
á½|_ÿÝðÓS ð>ƒôÝA/ÐÆ¶N6l~gä¶ßDø;ßÌ äY}™ø“¡v¦ÂŸ¯?éÌ/Rh‹1èXæÎòÿ¥áÝï$,ôÿehÿocüU³­Šÿ_EªøÿBÈç9Èÿ%€$pò5$ó“ñÈ3¼è=2þ™ïŸËö_›ë¿Ó_ñü«çù_;ƒ!ù!Œ„¼¿ê£ÌçÉ•«˜.ÚY<†_ÐWÐÆ0ôœ!^žò6GcŽÍÈ­í³¥dïp›1w“·t…¶ÙÀmÝ¤Í›!
öeŸxAÑ¥46;ÃßpD¯¡Ý‹Qì|.o'7æmîŒ…¤®¾X/xã‰‡¡ïZ®]‘ÅÝ¶ øJ]î$ãÅ mÀv Zã§à£ô—Æ;w<öÑBB8HK]	ïNá¤Ð±4?×·,—wïCK{÷*ùžv×( óÄñbàl¡­hL½3Ühœüé¹<ž´8ß
Îp|êlë£éàŒ·¡¯'5µõÙo"‡úÒâÜñ#aqHG\€H®ƒ	«‘âú”.ÍB9C.x\µ@)4†L8={tÔO/Ð•Þû´ò{ò6)QZ?EÃ©lç!.€² ±Þ 1ŠžÑzŸÄ}Òûa³¡æ:	û÷c8¾ØJTö9 
Lì›é(ÞÐgñ{ÖW	ÃC¹ìì¡lX}ºaÛ¶üâ•mÒÏãØ¨ƒ`Lç†U¨Sh¹1¡ÿšÂy²ÕtÇE63¼K7ßGóQ*á„©[#Ô«ïUu+Œºdáë&ô‘Ï÷žÔÀsé;ËÇºy?´»#pI?Ã$ìmø.tØ§Ÿ»Ôh€Ž2Çœ&L'_ù1åñÅ˜nÀ`Áã‹yß½#äšæ}¦.­pÆ¦0›/Íä5XþŠæ÷|€{0xÂ†A¶_ X`2'ùÑÑt!J‡ÇÁ½cöt†ÃF_·.ç™/›/šxôßÿ'¹:x'­ÆÃ¸\¨ÒƒOÙýðã“0F)Ôo1“å¥µ±àþG³íÄÿ»Éý©–®jÕýÏ*R¥ó™\n Î?PõÎ½dg’œÔÆ½R£nPw2Áâµð¨U)vÞ°ƒÌˆþDrÆÐâ2ÔbïÜY0ÒÍ¨Å_šðûMjIàôGa¼;@¹iUÙ5«ûoîŽyJÐ[yu¸|Àr¼p|¼àÈ,gÈREÜG9¥‡ì×³A„7áGöGÛ®Í?9Ÿ#à‹º¦òºö¥vÛyò€Åù(ã¦ÃÝ~ÝÛ9‡rÒ8…]”G²0jPüvã)d¾¤›þYÔDæÑ+ÁÀ´…£–ï¶€vç ûv»õ¸bø
°`ôîù¿Ä3fÁù¯Úª–žÿ–mÃùoÚ¦Yÿ«HK£–‚fV\@ÅÜpþ8°·ÿê–qNN\Çû83ÒœË§ŸŸgó¹2ñL>/ ï‹¨¹)QsEùôüvû.ýÇå_YHÿ#“ÿTôÿgÁPÑÿU¤Jþ«(EùË;øû¦ü<Éú_€€ËfýYZ@ÿuEcþ_-UÕ-ÃÂû?ÃV*ÿ_+IßÕþ–èöì¨¡K^Vtú^éô2!ñ«,L‡CÂI>	f 9™Žðy0Ñ
\â  a…¨òþCÃfv$ ½";4ÐBQ:€¢SÒˆÉËã½=Ò8Cäÿ[8q šÞ)ùžaßµïÿ¬Ö–:3¾3€‰Œ¼	{·tV7?Ùì(ëÚº¾n¬›ëÖõæi÷ÍÖáÎë7G›_gº8w°’)Ò46EÏçNŒàTpbÍÄ×>•ª´ª”ñÌïÓ0žÿ#î¨})m,âÿ¬Tþ7Ë2Ðÿ¿jWï¿+I÷&ÿ?à  ØWäÉœÜ 3h%C¹žç%‰“;9ëä_é4»IŠ<£ÚTŠLãñø'Y²ï½žºQ™5‚IL GÐ3/&.:p<ŠA6Œƒy³˜¥#àæüÏ!	mÈºãˆF}"ZàÌ‡SÍA›‰­*tëÉSÖÓgM²é€=È4 ÖIG‹‡â§P˜Û|—ÈX2‡4d7ks¥™=eù—ÇjÞÈ}¦~H¼ñì²“Ö4š´†·%†)þm¾W|^³¤Òå)`Yaª"VGïSÇ‹§âë·â‹ê‹šé½‹e¨äÌMá•À#Vi1èp|sÈaÉJ0À•(tãÖ~Aúñkm›rÄ‡†º€Ó‘]ÁxÖÞ9£8êŽhü)œ|lr›ÊÚfÓI1“Ô~$û×ÚÑÅ˜v£ZCU]´•­½ÂË~{Õ`C¦;¾;ó°]ÛùL=†³ßZÅÞQwýù£¯5^8—”E–G.~48£á4îQ¯«+JšùÎÄßŸÆãiÜ„ƒ•ø‹Ž¢ºŸ|Ý™LÂIñ#ŒY_ÙLQÿÅE÷l:ŒL'7™šßET<ÿÇ/(O<ÀÕ»:}‘Ò"ÿ/šmfüŸüŸe›•ýçJRõþ#Ý#æpÿ^*â¢°MÏAœ=+òzŒc_„Ÿ®áªeÙË˜NÒûˆáPK6ñ‚Ÿ§”¸5eVbK¾”LQˆLx6¸¼­Fíl£Oä"œ[uA˜M`xF³ÐTxÙ„úÿqnÈä;À E§átè“Q;MFõÉÔ×"˜MÔTC;_bcÈ×%må8pN<mE§„ö›0Ë¤‰.eOÆ“q°ÉÛ<:¥ydãL
ès"¾ÁÒÁ´ sÎÁ5(µŒÆ1v)vú„ùuÛÛ;Ù:îí¿ÞýyóhwÿH¼ÔAEFÄÐ!7'¬àþáæÖÞ»4Kä	ÛBö3GÖ“­á,µ¦ŠÒrÆc¡ÈaŠ[8I–É`Â¸¯(u(¶½y´9e2ŽÐÙYOo×ó/ÇQ
-õˆÇú(u-ue:·IgZ¹ëL1à­’qKPÅñb˜¼ ¼*ÌÅèÌ.˜ŸÄÖÙÀ÷‡ô“3¡2è—¯ß%àoš±¶ïï›o7åŽæà} d&§°cYÑäM8[J4'› &ê9e$k^›Éµ.³+B­Îˆm]y;qX\,T`"Xƒl‡ŒFpB	²é83\FŒp\yÚp<¼–JIÿZºÁ¿¯®©ïžòü¿ ÀÍI4^bøEÕ9ÿ¯Ù†néÓÿµ*þ%é—7¯vßìüZ;¤ÑNÊ_«ßrÇI]µ©ðÿj¿¼Úy³s¸»õk­·³u|¸{ô“ã Õ;½“·»›'¯ÿÁ‰aïø ýmtg¸4ýÁ*Ý_*“ÿ—(ú³´`ÿÛ¦šÆ0lKaûßPªý¿ŠTÉÿyùÿ!‹þ[9íOF§s,¦38{;ƒÔ
Ž‡ò"“kŽ·Ó{á¨ôAið¾B/ð©Ægõå–PÜ§19z»Íœ1ŒÎÿ@÷Ë¼ÁG¦»ò¶¤(FÞ¦Ëv³±ö˜×>™o7»oá”.±³B½å §v×ÞOÿöþtãý§ù¥9âW²–”ôüÓ.|Íä¦/Ù§[ðÒÎ­g\Q å){(²÷ö·6÷¾\§¥[lª ràdã¹%•=--+Î†&„YÉÐÍº\è‘SüÔb>&“pxÃ÷DLëxÈNdÍ4›Mâî›ùÝr3ÈXbkÿÍËëN_‰W×²tY°½{˜.oz{ðE\D­JÉ v~bÞæ àgÀ.Øb’+hL/&xÙ>Kàsó&^*›Ët£n"å½ÙÖ¼r£rJþùâ²»Æ~m0
Êhm©„PÄwF¢EFÑï”Ý&%—:5Ìà…^6'{»½£/5Bü°Æo°ú“A·Þ$ÒW	BýLÜ>Ôk~8¢5^	wýšç#Çð¿–:M
IÛ9û:d_ë2¨K_›ÐƒÙØ¯\)ÜB³¥ 7W
wÔl)È…Ri±ÁiÙ 
½çJ÷‰TÚ»º4ß„Yy %¹)c+’}vÜ¹Ó^,:(-š+$M]J‚ÒYë»k}³ˆñé€úá)ÏåW¥'x/–|ƒ/¨®xJ‡ã$¦joÈÐÞœÝ-2„ÝæÉoìLN5»køÁ'Íç°M¼pNºÎ4Óå`Üôû„Æ“4+âYeÐ¢¡(tâÉsèLŒÞ#àéÒ2¶¤„#˜ØÜçu¬f*W#ƒp2U§7«Nñ­[ª>¡ã›¢¤dP¢›ÁàvôMàçƒ°»v>È!ŒØqÓ©‚?§cŽÓ)¦ÅèÌÇîÚS0jà¸pèš‘¹XJ5Š¨B…@œRL\hn(€™0C™“P¹'Ñôìëv\MÏÎœÉEÒ-?‚}*…yø*sãG“{Qs'ªÃýq—…Óy’`IküÉÇø|Íøs,&çÿõªá¬-O…ã›½Š.ÜÿL”á”ó–ØÆ¢û_È¹ÿUêþgi0Bo%°‰O`Í»…LŽ¢@YÂ“>W÷_»÷Uºk*×ÿb‚ÑÒ®ìMŠÿ‹†Ÿ¨ÿ¯ëÕþ_Iªî‹ú_î‹×À¼ûÕmðuQ º^úmðµn¿Æí!ILAXÀõÃë²ÄÁßM¦Çža-þ'G²P!»Wó™óÄîeŸ1‹øÝÈü?˜¦Îü?Øjuþ¯"=f$Ÿ)ì,Á3BÝÈìœÄ|çïmoŒ‚Œyz–×K3žÉœ%¦™&Ï”‚$§Ÿ¬ÉPŒ9ÞF-R(½NöwñÇvog‡$öp7ßµ_{–nšÙÿÍ“í—›Ç{G'+ãÿ3³ÿ5mæÿhAµÿW‘*þ_âÿ¸ÿ@ùÿ9 åìú-,@ŠRÂÒ"äÊÃÿþóß‡æ}¥™ó?{¸4 ÎÝÎâ+€÷ÿ¶¥ëÕù¿ŠTùÿàGÿÚ_yøßÁÈ-|€ÜÐH˜wdRô "ŸàµU8þHg¶ÄÕÇz
=ÝÖîßéGÙZß¯ßrìªÝƒëk´tï×‚~K saWüæ;XæD¾Î¹ïsÛÝ?Øy³Ý;IÍ!»u¶ÁÐ²õÁÿ¨6AÖ9Q-­UÏ{Éß’&wÅÜ3HÃGVô_ÓtKö2·N8.V99Ôñ¯UiB9Î'Õ—ç\äy‘ü¿R3p<8A¾¼‰Ká1Ýÿ¨vÑþÏV•ÊÿûJÒcòd×ß O–Gxúæ®ƒÒn/…rûa¹WBOö€CÞb ¾
9ÆQ.€x‘û(I>ðb9–2	¨,ùcKysÆàP‚ø"wñ_ä¦ƒb±nß†_ÑÝš‹ä{]X ¸˜¾„“~Í÷6HšY“B|.NúÎ(ñW‘ûÇ‡èºìDŽÖË`{P‚ž­^hÉn…£$:I!ÐÎþ¹ùçAþÚÄ¯JUªR•ªT¥*U©JUªR•ªT¥*U©JUú§ÿa§jX ˜ 