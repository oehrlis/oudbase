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
# License....: GPL-3.0+
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes/updates
# ---------------------------------------------------------------------------

# - Customization -----------------------------------------------------------
export LOG_BASE=${LOG_BASE-"/tmp"}
# - End of Customization ----------------------------------------------------

# - Default Values ----------------------------------------------------------
VERSION="v1.2.2"
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="TRUE"                                         # enable verbose mode
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"                  # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"                    # Full qualified script name

START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
OUD_CORE_CONFIG="oudenv_core.conf"
CONFIG_FILES="oudtab oud._DEFAULT_.conf"

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
‹ “Ä«Z ì½ëzÇ•(š¿é§¨@tDhp!)Év(Kˆ„$&¼IIãc9LhmÝ˜n€#s¾óã¼Äù·¿ó(ûQö“œu«[w $Êv2âd,¨Zu[µîkÕYœ´÷™ÖÖÖ¾yøPÑ¿_ó¿kø_ùQë÷7®?øæáƒõoÔÚúúÃoÖ~§~î‰áÏ,Ÿ†L%O£…í Ù`°à{Y‡ù÷ŸäçÎ?õOayÓYÞÊ‡ŸaŒÅç¿ñõ7Ðùo|³þõƒûàüÜ¿ÿàwjí3Ì¥ôó?üüïü¡(pæÃàŽjÞÞ@[Ùéoª•[{’Åa?ÎUçyC=åqå¹ÚŽ.¢Q:GÉTýQÏ&“4›ªÕ§ÛÇuèsFçQÅù4ó<Rj¨o×n¨ç£p:=Ëfççu|Oÿe£0éßú¤÷ÃqÔâŸMå]8ø²3›ÓL¾<žFƒ0QÑ0Åj5òºÊé³VJŸýûT6 ÕKÇÐ»Û§¦÷Ên˜O·†arõŸ^ñöo‡S;¶Û ¿à&GÑEœÇiRj¢¿àf‡³l’æCz
8£Ž{Y<™ªiªÎ#øg©8¥%½Hñ
U˜«,šÎÕKûîD:r=›“!œcÎ0à·q'£+5Ë£¾¤™Š’‹8K:T8œa:›ª“WÛM¾¢yàXa46œN'ùf»}-gg¸;mÞ±I 8¿÷¢D/áùánó~kíßný¸÷Ò~<ˆ£>ŽæQ¤`V°¼›
–gvE‹¢oFé9­xœf¸…ðë8œbKø_Ž"oÏ&}8°üÖ'ÛT[@ÓqüòS EïèÞ¼Ü>=:889ÝÞ¼òÞùk³Yšžã-l¥Ùyíš&ÐMú*ÜÂ<·×e6šªWáhåŸ° àU÷èxç`ÿqíb½µÑÚ¨ÛÃÃîþöãÚÉÑËnMÝðçàrx6Šø cø%œL" 40ÀÓƒãîãÚ³ÎîñGÀ»ˆ²3¸’€8p»Ž·ŽvON÷;{ÝÇ+«ˆñ	Ðµ²VNöO·wŽº['Gß?®µ§ãI>|¶³£¯¼÷\·ýî­••Zp|Ò9:9}Ñílw×è/$W!œ7œÝÊ{gôkµú*ÊÕWÞË^×ÝWîÕ‚½ÎÎng{û¨{|üîæ¿§Y´ÕÝ££ƒ£Çk‹Ÿ~œîÙ,é!f}
F0¸Û½‚™—z™‡çÑj]½/ÒÚí8ŸŒÂ+npË£#:,$¤¦¶Ó½ü\ÕvöŸ¨M¸Q<äšÃ‹L5cõ^ñ}À‰ý­îÕÜVßXÑßÞ‡ßâßáÊ_¦Yÿ ÿõcÕ J5‡UÈNƒ«Õ)2‹10{økN÷‹ªî7eN÷¬ª{oõÞqÎ¢É(îqšÀY·ýÑè{è»©zÉãí8‹zÄ öÂV“ÍW¹uOá5‘ˆ–Ìé]:üOÔŽ°èª~»é9‘'`øïwž#u¸ævñ@ý ®_«æùT­©!¿O½Ì­Q&¤ÿ3àgÔnåýÆ5}€÷êvŠWÝMÑçƒ8¸náU^­=F,¦QÓxLÌxò¹®:íúj=xOëÜÙ?|yœrý«Í{×UHH? û†o#’nv—!9WgüÓç½í½†-'P× CTC dY…*AÈY'!8ß†æfÎ¤¨Z]©“½î)àÑÞ!0CTíß¾ú¾ùÕ¸ùUÿô«›_ím~u\«?zät=:šß5YÒ™¸ôþˆqþŠ£zãÖjnƒ{ü½× Uñ£;EyØ³7 F1øº¦+Š—A7ÕâÂ¢¶4Fo˜b{;'@¼D5õó¤ÇfèÜGÓÓ»W‹Á˜fp¥ô¯ù0LÍ_—C¼÷4kö0_šk?õ†øÐ•Ùi>\ººÊ.ç5uVZ^m?M¢2mºÅc{ò¤jM¿±Ý¯žäÍ7ïsÐgC"]†€B‘*’nj f ƒÔ›¢wñô3GË_…ð$»'$yÉ±i¾V7<©+pÚ’ôì’«u§9PThÞ…eª-btK½ù\…ãt–$fç3T™ó–:†Ë5#¶†ä½—f(w€NµÜ!6n:„¬V‘µ×o
ÿáRø®TBb HúI:¥CÍ‘‘yÒyz­`(øã¨³µÛ5ÒÍéÓÎqaã`£—ŽJÝhœ<š`ïÃð"ŒG(=zëY__y+úašÎzCÖøp]Þ¶ ˜QöÕ›•÷/ =Ú-=IÜý¥ë=NÛwYCÀÂ¢¾ÛÿÁÒþÝ,ƒÂéôIŠð»/]w§ÓÍfI‚ò‹Øˆzéx&>¸ ×ÏÝŠ -äË Ï’·Iz™¨¾Ó§W>¿Üé„¶€Õ^€7ñûËÀïÅyNÂ[Yw/ÍMÐ·pip^²¨ Z’DLu_À–"ÙØXî iP}•Ê-4·ÎÃç‡7<2¸ËGÎ1!å(,ÅfG[í-ZQæ€v¡{þjCû¼Ò¾æÍéÉñüàñ`W’§r«õ>rá‚ýÓŸêë/³|ª.Ã$	UšÇ0RÀüy)Á|)(J3š#©6±±6ñ\—Ø–?§£hœ^€B¡*ÀÔÊtµbU6ö@n<i÷£‹v2L“;pP*õõý¶Pû³Åp‡Ò,ìÁOgç.t´K¡µ¶É=ïµð¤«†qÛ:˜QÝAØ1²Ú¿@¬ŽÏnÇ&Äæ¥$žÆáèÓÍ¨ QÞð"¸“Ìà`á¢¢ªš]ZÔÍXôAÆ„6+òŽF´ªZ•…dOQßX7šú *kæ›éŸ?]õóÏðÍT³_øÚ 7êúŒ†cíâ¦ õp\AK9Pàî÷ÂQ[Ð¬•‹$F:ïŸ @ÑÅˆlŒRøUSÇ6êÄ v1°0ß·Âµ‡“,Qþnè¡<©þøG<¤KUsl.ÞâVçÀœ‡¿+ëî€Ž®ß#A™ÄcÞ6Æý[AX·ÆŸä8ppš…Uóö`­†¶‰ š»îØ¢>ñ†ÂDF°þÎÌ˜‘êÍ@JMÈGaœU5Ù–eñ¶GÓtHë÷Ÿd)^>äÞ"]Œp‡'aÈ0E;ëqÒ[/âÍíÍŸ6»›JÏFcÅ >qƒa],k+¸¨ôç»¸®ö®\DF4=8„­yî1æmlÇvÉ9-~Ò-\Sãœ¶Y]uww¶:'ä)Îª[÷±²ÊŸõb7ÔÊ=—}‘nih…¿>¤%
WØ‚ÂÕ–ƒEéÞ2nB#|ÀB#Ôeî1Üé?®Øˆ½+†‘†$?©3ÈY:VSô½i_¥Oz;÷P•6 ÛÐ’4}©fÆŒåêîÉ	AŸ#, >v6ó©lƒñ5ž|ð`a©vV¿÷§´{8We©¼ ‰9–Ã†.#8”œIÃäjàfó¯›ÍZ¥•þÚéàÝÝÕý€¬¼?|½-ÛvmÙñ„!—û\—™²Oï—QBØ/òÞòAÍ-„…/ˆÙÅËEý¥u³Énùæ ‹#Àè+ø$I›@ Ç“)ý~˜¥“(›ÆQŽ3‡xïìÂ¶÷a9ü±»FU¹ph8Í@.îÀµzâ£5Ü1œ˜wÏäŒ+.®‘×ào^ºò6¯{]´€#ƒ†ýŸP€··Cl#ìÃÿ?9=¼´© <5cu7oÿm¥Ýlßu¯Šôþ)ú4ì½…>jg›ýãÙhOÐmŒQ.¨ö	Ð ¹M£wSTnVÚï÷åí7I[µ]/xœÓÒþ&-7À•?¥Ñ*ñ9§G#¬ïêŽ¨ÓÇQvº'bíqñWÏAÎ‡™õÔÝR3ñCG}ouMÿ
gª‚7j+¨OŠ×Š2c)zšÚô¬*=U:DÛ$«ÐÜ•`Tƒw·;‡ôŸcÏÐëïÓ±
°+ïcG5ë¼þëé:‘VÃË·êîÓîóý÷GÇko’æÐsŸÑ¯µG;Ï÷€^Û{¼þˆõÇÇÑY·®þ[µÿÖé÷38§6²Œ•üèÍwwq¤»ož´Õ{XàêÊ}þ¸ËK‚Ïëgí‘ºFÿÑ{Ò´è33TÝÌ×»ÎúÃŠÛ
'øp½Ò¶}³c,å:í\Ñ$Ïr‡™P1GÊYèêy\;*:†¿œâ¯tŠŽÂÜH. ]Bæpó“A>Ï"ÔÅ7(~#%¤ªê¿”‘’våð 4œÎöÞÎ¾Ëç²Ù°?Ž“ðÙjæ:÷,çòXoi‹Ž¾’Ý~ÂÉ?Ø(3gÁ K»;'r
ƒüì\+¼K›µG‚ô×ªíEª]ë{òúÃÃ=ÙG“á¯¾'7*/ÊÇ]ŽÊ-òQ~£åáŸh´X¨>Þ[$ì dýòh÷qc-7Ûí•ÕašOÑRß$„Eý)·«"K¶ƒ9º©ŠfT€+#KÍf‰#Íñ}fíy–ÁEÈÒ‹ÐXYõGi¦œÐ™Åÿ@cät2#)	=ÈX/[+?…ý³¹/s±GR¥$=xPÞURŠüàc¡¹‹JsQü·Žÿç¸Í_#þÿþúFEüÿÆú—øÿ_âçKüÿ¯ÿo.Ü¿Jü¿D~‡@~µ;Ö•’ò/¡ÿÿâ¡ÿê–#ùÕo1”ÿVãø?8ˆÿ3Eà×j&ìþv£îÕo:ìþŒ±¯ˆðGø„°ûRx÷ñÕ«ïœs…nfÿ)1ö7°/ÏyÈ¡hÆ—Ïé]Zžé½Æ#%F¹Ý·ÕwOwö·à|
¥]Úp²Ù2#[í3þWì×çGì¾ÞFUSrèø,éÍŠöÌƒ?Pßuÿ­ÃÎÉÂN`'Fþ9äÞ¤×L÷©ç·’ u©k&$·xS9 êKÀ— õ%àKÀ?oÀg&Ð¿@¤ÿÜ´Z$œëÉK”‘CÞ„VHv ë%˜ÂÇ›dp›? 6LT4P+DjNäý2‚½½D—¨	jóÈq’bd”d)ij&äD°UEôþøÂÁ1L óÉ’@yÝ9ÚG(z–¨ûãê4|\ÛAZj?E·:Šv*ŸD=Ö®KÄìKÊÅ—ä‡¥Égaïíl’Wd?Ü_: %êŠô‰[Šû_žž°¥3²…!ëµ)îñƒ‡Ë@m{}uûeO£bûò|ŽŽg&6‰24dáreË>,!a,9¿_5¼^è2–%¦Ø2¤ÃšJE9~sFLÇrD"ÔÚç´˜VK´Þ¨³vrÓK5Æ«FQ<î¼€BOadÓƒ˜Ñäµ²zÙSÍ‘úÎ9®{ÍNQ­¬®®HŸ&ýBByÝ¶DèªÉÑÑØãÚAþWýN5sX
s9ØkÔôÅl\ Áfâ’õÏº¯þ'Çîë-&yãŒÜW5ÛÝø5@jhO“Œ&
·>?ÆŸ 0œÄï«ÿüêv#øÍ%¸µ ~€8/RGÂRQ“4N¦Q¦ÚD³’Ùøþ à’‘XŸØ3ŒÔ]S5ŒÂ>´Áæ¡DD $20‰Ëãy'òsDÌfîÔ:(D¹Öëð¿:MëöƒÿÇ›ñf— ›¿Düÿñœý14tìý+«ZgÕmFÓaÞ~Óh¿QíóúgË`[Î@=§Ã9­n#ƒ ôXJ’‰õÓ˜{)VÙt‰@£0¬•ŒàÃBÃ]ŠÃ¾\Äý¨ ëqf³¥«†ÓWƒ3iY2>—ÚVÆ‹’^ÀŸ
&$ôwäØéO×¤7LÃ³J;r¡cÁÀïð·îÉ–Ðf†V)ë°¼úÑwè@Á>çüTg2,7èzd'§ËãT4¤Ý8ÝÝ9FâÂ”åBÝýÛ»Êd 3!"Ä¤^f²¾ª[Ðcpò´'´wo*–>Î3cQþEô}ÃÌv»sÒ¹nßÃWÛk–H²‹]ˆ½:òx^ò,Á*Yœn¸÷Þwè¨÷€ø[["´íÁÈøÖ½7í7«ðßúœEëÞJûÍzûnÝ	§tlNfÇË^¦¡Ýg‡`ëˆóY-ÂjéÁü¦<KCWˆì™™ºÛ¸«àÿêš_KRl]Óˆ“Â	UB·!çôñ5~“äB‰SãUÒiÕæÎ• 13ÞMÓ‰J1œÞ×Àþ¨‚ýMù§·A’9~åi+œN¥*dR)CP´‚]*;˜¬Úvp´©~0 4ZqžÎ²^äÅ¨N€nŠªüÛxâîy=c¯*ñ!\]¥_þmÝQ{zi2“™ÁF¹%Dþý0JKéþp“¬§ê»ï.ÔÆÛãa½™7ñòðY_.¯Ñ1Ÿ•Vâé·ùÕX8þs–sa¨>C¶y™ºl4¹Oñ£³¦d>ÈZ]ÿÉV2+ÿzØ¨gë’®Íàš”ÇDS)k[×};5ýÛß$ÿñåá\|©˜Š«n¦3› 8ìU®Ü‹IˆâwêÉkh#8lÈ®
ŽeØÿ˜ÎÜ¤Óö[Ø3wïRâ¢½Ë·f»J¨­Ò¤=~PTs¢Jí‹D	5Üro¡“cõÖs¹¼ñ\|è@7xÇ;Ó×Ú¡áwrt66	wÀÓ·Ž&á @i½¸0ÜíøÔ¥¤¤)kÀOÐñìÀvÏq>z¢2xÆio\¢Ã|WsÖê¶ò¤ù.P†Š2ªUäêMÝúgIC~Ÿ¥éÔÕÈRqîþðÃæÙ(LÞnþøãÝzI `–/ûÃ^»0ë^Ï8éfýèiú¨×Þ'ê7X;»Û~Sk¼©µK ÚwÏm‹6üU÷} ó÷>§Ð1‡Zò ÓÙÙ¶S»¾)Ø"ñÂ¥;ø#È·u°·×A‰X’vö¯Ûª9êÃ½j6u²¢|müëFÙ27Ê>­Z0æ[¸[íp*¨xqx²î9µ°N·Ã+	_¸ûo_ÍîÖ[é¦[
j‚·I…³ jFªö&)·TO*n¦óSêQÑÁÏÂŸÊä–Å‹À\7*Ð¢FgðøMn“”:ç*ù÷ÄJ3iªQ–ä^!}uozYÄEÄf¬HjUÙ¤’âàeø>^ÎZOÄÍkœ (–¡_!$§B	Êùv—ù{­F%Æ¹~,p»?U‡éx	D®ïe|nU¨JgûS^X ËãOeŒÉüM¹9ä³ O\Áœ’8Fý¹1*Õ),ÛõÓË¤B¹¾ä‹:3ž4ã>‡‘ÅX¦%MAÎ¥•)ÖçX°Éº«ÙK‹ó—¾ü|ÚÎÿbEñWÉÿÚøfãa1ÿþø’ÿõKü|Éÿú•ò¿Ì…ûWÉÿSÓ—ü¯/ù_ÿÂù_ê7ð”ËçÏCÛ4,ãåîîWÁ+Ñ§õ”‰Á	Ú¿ÿÚí>~ð!pØ>Àš^GÑÛ‰ÌÛ(šp»'¨=®5›ú÷Ì“-œ¶‹z6
Ï¿$¼ýS'¼MÕwˆ«ÿB©o&WKuvwçe™e›çÂ)¼·h©ßÙß:êîu÷O:»*~9ì[õÝën÷¯Ç®½‚—îTé¨obièóà~bÞÞ@}÷´³õ×—‡7Êy+NKç¼1ˆ/9o¿œ·/ïÞ|Éy£1¾ä¼}Éyû’óF4òKÎÛ—œ·/9o_rÞ¾ä¼}Éyû’óö%çíKÎÛ—œ·/9oŸ'çí¶3Þ¾ä»a¾Ûtóíf¼9Þlv?G¾Û´®Ø3Q™ö¶®ÈÕPýí/‘+GÙml‰ý…²ÛB"B<Gü¸8‰Ç¸	È×UtÞ‚ÿ¢åV?º‚ß]^I¢M[ÿ’ö%+ìKVØ¿nV˜“	t“¬0É-^”Ç¤".$Áq0„¸0E–p„NZçOG
ðÕôŽø#Î†9ºÕf£T=ÔŽ(Åü3Øï¾>EÕþc%	2ýÁî¶ýbuå½mxÝ*L?·Ðq=…A¡“òz©¯ÐA1v°‡XÔÙN¡¢³HÛ¥5ã1ÑBýI„¹|`¾^ƒs€mÏ²s‰­Èî	²¿¤_??°PÖß1AþéóRç>.=Pvâ_"A°D]¿$¾ÍK|³NgJ|³²¡I|³-ôq.¦|XÚ›ë&ioNû›§½9Ãw)ímé\ªÓÞª /M{$ÖñX¦me¦›3Â‡gº•åN{—ñ…0»>¾‰õ
lu‹¹ûß.Ñõ:‘2;çei`)°—ÿz]bDó¹rea˜Ì·*LÀ§TGnI^––®ñ
Ü`+n2ë•÷þ\\ïŽ›cUlUN~ô3¦J=–æXùùUâI¨’ ­4Äç¤aé±ô
=í2Aµˆ¡š‡ÿè]n²Ám7óGhMÏÿÁrë`ÿÙœÍt†¬ÌV+n¥Û~~óê-Ó¯ÿj¼œ÷úWÕž»Þþ¦á;õ¼eŽ¦šÄ·õ_g§ôTá\öùY}K3úœ“|>[Èç»y.ß|!éi%µû ”½OO×ûàT½_"Mïf)z²¢wóô¼y^õŠM¨<Ôyx…³ìÌ¦)Þ÷BhFÊ’`ßÝÃ#ápÉºFÁ'YÍ†
jÕGî›	lÔ%É¬7K+Ìž¶W>ól¬šY5¹*@ôº~`Öä~ê.aÎ eWÑHYžwyÒ…”_´»l¾±íCR&ev·Ÿ2¹ö‹¥L~@þ—÷äùgÊ1[œÿ÷õƒ¯¬òÿî?x°ö%ÿï—øù’ÿ÷ëäÿñ…û'ÏýcSÃÀ|mF)˜Ö¾dþ¶³ %Ênô«0‹1êãR Ú1—#óØgSOóÂR.ÖºíÈÚRêŸ˜ú^WÅ¼a«³îÐ^‡z
ZÖVAG&Quøã§Ç/¶º?¬ýx]«×Ô#5¹ìƒº¿Âe>ËÓÑl±d/Æì€ýÅí0%š,_â(y°Ý}Öy¹‹Ïos=òÁq"`y®ymDjr±ã·òzÒÎñ»:M÷N·@l÷Æí§x3ý† luvÝVT•gn›§ R&X\ƒÓ
ýžÜ*šöæ¶BÅDy>·ÕIwïp·sÒ=–¶Óh<¡à
Ûãðè`ûåÖ‰»ŠI–ög½©•}¢h$MãËuÀ£ÖzˆG©á³½×³-ä¨K‘çkÌN{pñ[h4©E€8¹ÇÆ@	ÈùÈåNâzþ×ú®¯]¤tÆQL±éw}Müi8m6 ¨ë5¯XšÓS`=¶`iˆymiaÝ(¬%SkïGTÃ“Ð}8.,åÔd0ÝT&F`Œ¥‘˜6Y<Nd|BâÎç­z:C:¦ÔQ8Øµ<Hî`KÁ4ÐZÚœ—66s\3•ùçíšQƒ	ÝÆX‚Ç6¬€ÝÎqÔ®ðã8ï1\½14š¥gÓ~`"½àomâ¨Æ
øØÓ`—Â-ÒÎ`h>ö­Ë—I®Þ'´Þÿlø
2í†¾ÛCŒÄ­:KÕì-Å¿Jgì\"—Þ¬
tÒ]®Oí€ú“OÔ£¹ÎÀé¼êè!Íï8ØOáEÈ[‹”£à¼Õý|¿ícòÙêI¾+:yi:Õpp%Ú4p+"ZpË‘¿ÓéU©Œïäää{tZÈêÙ™ÿ˜’baôå$&±8zõf4¶JÓ‘-ŒÛ^•_É.ø6æ  ±’¢¼æô§`d¥ìÊn;Ù›SUÌ›9Y0<¿,šÎ²D­31s4
U7‘ÝÍLÍ—â»¯š‘˜ç<8Î¬zf÷ÎžM#Lˆ Í0´¦ÚÑ•fqœŽ)â¨2â,Ÿ:¸•ÂÈÙe¬)‹z<Õ!‘‚Z9Q‘4IK«;¯ºÛ§ðÿ¹vâ˜Ž×ªläXÂoìD¤;â	j„ˆÙ ûLõ
öŽ``.Ç×ƒ°8âògD‡‰Ôª¨ƒÄo(ÝháûÚ…¡ã?XB2ûX=™*ÎúsYÂN…÷6™]ûcÉ]r™§*é	&×ª$z\«
‘?4±Ê	Ð7ñRN@|ÍÆf¼tn \]ü·\;1+6)8â+ff˜…cæhëTïéJ+!$”º™ß§á™™¢WXÛFªâ„Ët³§Ã–á„¯®ÝäÄhDwC=}`TGyÊ)Iy:˜bðæ[‰çtu ÅÛ¨[Ù‚ðØ| Š•/¼Ç¥ékRÀÆî‹INQ˜=½4ºx1½–<giÉ÷æ†áÎ%nÚÌËDÉ}`H÷'FiË¨kjUbž6‡*O¦W^˜Z!‚¶,gðSSU¼hd/XÚ‰kÊ«â¾<Þi%
“+†&U´ÑÕ n5„¼VEóÒ§DŸ-/‚úÔHr3ÄB©7Èë¦ÙgØ;–9ùÜ)aŠ¦jŽ£¼a\5¼ÐÅ„‚{C9¨M¡à²s‘oç`_ECï>çæáÛ‡ãÚÇâÙmãá—–2n=òß•Ã|êŸ$ì3Ê EŠ5ÿîx!®Jµ¥ßíà$«±ÛÃ¿!
àáˆ'ø!`½ç«ÎÓphµ=Sº¬°£Ã0µ˜Š©Ÿ€Aî&yÍìÄzÕò+&³`y(€ÅïGCºã«Ïh[v!®_»á·“+ù›.jgj˜`(‡D“¿/ú+Âôø¾T¼rÃ uàÒLAD¾m¿žQE¨;“åí£S]%}ëUW™ŸÀ)·°Ò“½)lW€Ú¬È?üÆ@9fÞýÏ¶üO¦ýqL5Ñ‰©‹æ¸}ÜíÞd–2Ã>Î/9=´™~ÀôdßG·7AW¬@Œàºµfj\2­if½úJjn #E$u>Ó=ÍÂÞ(:%o5nÁ6`ŠÈîhÔ"'¥ÈìùÓpÞeô–"cìÏj³"XÙáNwuÅîr½Ô“ÏJyýx±Ô[9Z³ôœñŽ™jH{òú†w²(³1èÝíÎ¡:Dò¬œ©`ŠHQ§¦Ç~[izz|¼[jÞApus2F”:E“Q,^é¦;u?à^ÿ"+½ÑvµEþ0§t)åNcB6ÛmÇÉ¿IC¢îšKs|qrr¨üŸyËÁ¦Ç•Mírthâ­Ü-2ŸïÇg³I™mºSXk:Ð	›Cú'ï=§ñà§-–’*¸ÍÎæ›&xËkÅ=÷f§šåÏJVýÔ|åcn¾#þÜÑæ‚t˜8™ÇH‡M{gçÛ*ôÛUd-ú+B¨æºSÖáAÝ÷ñ€6|@ˆÁì~Ýå”žëëcA~=ä‡yÓ4”Ê$DÜŽscBä™%<%*£ï«½n¯ÄjÆU(ª¸. 'z’ÅÉt î~Õ|˜«¯šëøß¯é×øßUÅòŠÄ)|O½ñ¦S[Yý)“Ó³+Õ†Fˆ×ò/"‰ùùºNH|&í¨¾ö^~Njæœè{U$iç¢!kÀÜÍ¶®w"”î35-p @„ªšŸ1âìÉrÌ›ÇŠWV¹ßêT´h ~V‘¹lüß²»ðÆøC_¥Ùy+E×RÞÊ£ì"ÊZ•d*¦Ó‡?ÏéÝìaÞˆ³ÆkU·QñåNÄÄiîwg“»è*ÈßŸâú§
(·°+IÞÌGá¤ÿ›[w5ºµu_Žò_ï¼Kõ¤™
î‰wÛ]E¨$Ä˜e#óIÊŽSG+°š‘^Ìg¸ûz§I›{¼²îó£f¶@õw»jîDJ¡»ôïn
Îãd;9ÊÕÜÄ&/ÔÈÄÓúoð›)
@[SVPüñÕRBG,Æ–:EhþŽÞ¡OGWd^u:•ó¨
YmÎŸ¥}àj~É•”s«h¥¸15o¶–j]½ZOw&À—þ3
ln¹!ñ`íãŸƒlè0ã1–hÎ
C©<Ñ²½ªh«Ò?žÆƒ“f¢î¶É‚@fJÏázÔi’ÈÑn´ÿ¶ÒžÜÕ30ŠB?oöçMô6E	½+Ú:C<}F\SÁñ^PºñmŽ&”7âñgò¨{h4, ³öy*W*@óÀ-…qsdú…( 3âÍ)àU:Ëø2·nBïhHOÐã/6‹#µòrÚå÷PH›öBé©{)U
ÔØðãh¬N{i	mÖïû§ê6Œ€FQÃ¶_ßÿzN[Âœ÷úWhûíŸ<¸Oé?V¼r\6,Ï±*z•%³^¡­k©¬4È:í‹FÙ9Y§GÑ*[2É~ž]ü%¸)g©Š¬ÄQùkºž¿óë³LËýÅ…Rà~•¡JeB6×´¥‰ée¯ˆ§uª¥»^6hëâ±ªµÛ½7o
±U{Óàé¦ƒ›·6Wüm©¹k[.32†ý~q%\W¢íwK3~òdÞœËTû3‹É©)i_!9&QÆ1'¦È7 >Þò|~¿%çÓ!”Ö×®ƒß¿¿£ÆøbR>Ë¢Ö­–¥ç1¢&ÚzØ¯ë[<ÀlSÎáƒ<ø½Ü%Ç>0Wà÷zäÁïa£iX¬¢Qµt:.<Íf‘g,ÏsIJ#˜eÀI}ÿí@<é©Z§ù…Í¬5ÿTƒ1U«ŒÙ9ý¬ØZœ¨ußv‹¿“ãS%‘ÓüDÌ‰oÝû@ÿxÏÿ†*~CÃGêÇáä>"žDü¶ˆ‹dý¼>œa4ªðâxÁÔDg{¹õowZ†m"A?
Z-ÐFc¶»ÿêÓ•-XÐ‘^Ÿìa.[¢ŸÇ€4þçÍ¤^ÛN>]²üÏLü®óóØ	þôæÍ\Ñ?/4÷¼
Nsïó[ècó;üi™ÏíuL|qúóBs7{Õmî|^ÝC'{èÏ›w¡ÛÝr?o)}ÓEq$‡ãy=œÏË]|‡‘íâ¾`¨B¿ÓE§SÒäªúU,9´*ü<wPESfìå¦üyUàþU°ñóªæ BT6‡Ï½æ.ÑO¾vFq˜±³
À\­¡¯tÊFˆÕá8SCœçÒ¢‚TÔ79oV„mK.½†M²Æeß¬îù\éB­ºrIÝ‘úOŸ>§$+“ÓN1Ì„¶õn€‰*`ÁyiWøtæö¦÷?½R 1IËDX‚¬j¬f$fsò£Ÿ±,°3æsˆ¡"7!?>åPtÚþò¢rÕ°0‰i@Õ[Kg[Dd#/%kRqªRç{ù‘íOC^„ÈrYñšüàÉgwð»FY
R¦:¡bÓqPÇ¥£Ä/ê"µ%	JD¨ÎîNÇ¼±@í)’f!ÁÔùjë^ýñêÝüßÏµzë…S++éaCJ/cõÂXùy•¡ÔL}¥ýf£}·Ê{ùm³I'kß:ÿW d‹7½VáåZyO‹*úÑñ§fÀ_{áA(²'f!xîóÏªÙhÙ}þøF…Yè¨þêçp”s†gøFÇzí¿ÂøHÛ÷à“Ï¸ø(FFÎõ@ƒp_Ø*/ ñ­³Ñ~ÛøûTÅ8áµqÿ$Ì`FÎÇNô «q;ÍµÔyVU¯ò$½:ëÉ-ŽFQfþ49Â^{Ó)L÷f*tº¥)m¥ãqš1{¼â/ù©FIzIíŽ¢„ƒÇµšó¹C0¨Z×]ÖXµö,Ä‹%)¨ìÓÞ°¡ÆQ˜ä¬´÷€ƒÄd.ëPL_0ÅÜåDÆyŠÏ…"1a54µšEýYÏëì<»	N‘#göN^Ôbe0Š43|ì¹#Ê<æúYÆ6oEC‡îÏü ùµÂ[Z­Këínµ„GÙFmV²nrö¤×YG»VÿèêPú,žv–Â&¯Â¹˜í›íöéyÈ$Ú† .F5l W† O9…=ŠæPÒë[cõ(ü:I“¦Ó„Z<K³Ë0ëË™-Æ<=<8œB>±žühDàð%wè;”Û"ç“8çCaòü™3lyã
ûà6vCXn 	½+Ó,Tù‹ËQ~T8*óÞ²¹î3Ra/nûÙ¼[~2Ì}æM»Lo˜(«ßˆÂ‘þkåXtÞK…ŠÞ˜K"³N–½uc5g%Ñ¥'Ï{zé@JŸŸÝ$Ô›ƒ­{àJI‘ïÝA®ÝWÐJá²K:T‡Å.ét¿ÐI{¼—t+ÄòŠ7wI§‡Bm—t½õÚF bz‘Ï'*@±¨ysÏM†ÌÎs~LˆÝ¢KÁ¾óž“ÑüÑK©Ö)‚\Ø@{¡üÊÅç ‹ÑwžWÍýB|k¦×‚Ô$êLÓL‘Jê­¬j!°¶â‡UG³9¼:NïyNóùúy®óâç>&9\Ð©Ò³øLÛ•ø~Ç+ùP¶÷Â_Q3`>TU5+øm áÊ÷X(ÔÌÚ‡Ê3¼mÌ*¹}-€ÊÔ»ÂJÎLßtBã7½ÐøMk½Äß‹daîW½U%^W5á,1¼˜ßŸÜƒï°Cž5@©ðmÙ7-$¶0´­5·È?HÛë#T¨Ê«7¡Ì
>~Õ!T#1ÜnIQ§“µ}°4dÒüoáZþvîÖ¯~5n‘Zÿ*Xûù5C¸ñGÝÎ‰~Ù–ª@4¥2…‘”¨Ä¯CÁK¯|ùØqmRšák=€÷´ºƒ­¦´Ô<PÅR~7èÔæ|\_¬ÞûQ±8p©£®¬qã=-—IjEÛßo¼ÅŒ‚·jä}–OÓÿFÙ×üù§@?Ág‰ô"SûTè6•»:ÿû£væ&iâê£wæ×=÷eµ]qe7ê#Dõk¢£•j.-gÊSoÎ0>‹“MM›n±Iù^×hü0ÝîÖ'|{“-ç¸ýê»;ˆ•SßÚ­•G.mIÈ"ª`iU~Xe<uËš«^;–»vÛÑdÜ¹~Êl
°–MªØÜ(E³'>”Á“Ì§³ÁÀV!¤ÊƒówSØ¨~B£½Às .ÙÒr;§ÒPuÉ/™êÜþ>1a
´=w«ô™=ðížUœ¿(ÿbdDkúnZ}?^oóûŸ®TjÉe—¬ãjìý|~åøŽ_]x>zÇÑoæÎáfH<·¹>M;ƒïÜM{rãiÌ°O¦²“Ýò•÷Xsúš,ÔkŽ°Æ5³*|JÏ{ºH‚ç>qGÀl@É­?å|æ÷Ÿúi¯ý™‡Xòþ¿—Åï=ØØØ¸¯ÖÖ×>üúwêáçžþüÿÏwg«»ÜýlcÐ#oæœÿúÚƒ‡ë÷ç¿ñðëo¾¼ÿöKü¨ŠŸçû/Õóî~÷¨³«_>ôP‚"¥ˆ&ùy%o÷jãOê/³$RpØA ÒÂä*‹Ï‡SµºU§Õ³,ŠÔq:˜^b}êgø
$åA5€ÊöZê;©Ø4È­4;o?	T÷"Ê®0¬!Îñ=Æq<EãÞ=ó“+~ú˜:Ÿ¡óÚž<ö&X±›ƒ.¡çˆþR€ò3$õí9>Ã&cXŽFéeÔoó–K?‡YŽA‚ÁV' ßÐ®QTæHÎÎ`4ýÔÂAÐ‹¢ÍxQjþøMëÍÀ¥P¥zõ6Nú†"ÓÛ¼¥‘^¹<†¯›–ûN0}‹ãsg*ÞòøËóã[7˜^†WœÿˆÃŒ”0‡‡-’àÆ3Pêéšûð½i#˜.]qœL£¤Ïçt>³þŽŠ#¥1BAâ'iý!–e9ÏÂq³9MmV‹¢ÇÔèQ*g÷ža hÖ›å 	¦þš²`¢¨7ãšéÁ‚5™-O±tfvþÎ%œLF1JâXiÖ…u˜ù4pû0h)"A—0·þìŠfÒó8ÇïÓÆû$ü¡ÐnÉúsXBš&¼Fÿ;>+<‰Â·8Ü3Ÿ~…ëËðm<
	ÆâÄ¼çøÄé4˜d1&Åª _½Zk”·õ S(¬÷ÕA!ç&ò,ÍO­Êqã»ˆþ aŒ’#€T—q>¬7Ìsa¨È½´ÑË!eíÓ¥¥ŽÁeˆ±ºS§+¶qÐØÝñ´an=žIÐÂÐ<í~sH²€{‹Q4nŸ^	g°r(ßÏ»N1ŠÎÈ^N§‘D¼‡“,º  iÄ1£ƒ´…g„‹`˜Üçæoå+ºdõæ—ˆu«Ñ8éâ¡½(›†,‡5òø,ÅÓ˜ÛÃF•§äîR‡ˆ€ôýx€(¹Y†ÓÂÏpÑ."à¡5ÒÎ<Ã·ÿÞ…ãÉà.šA>ëí‡­rŒÒ9– ¡Û­‘,vŒ©M¨Y¢)ÏxÊÄ 0™æ¼¢p2¯¼„X}¹y¨€âø†]º†n8¨Ç»e°àt ]Ì¤ò! a¶ 
ð­\å4Å«€	~‹5šÐ>É¦ˆ4!JLhw«Ð‹Cï¦—)¾:É7ƒÕõºÂ'N³)ñæ½¸9Þá"f¯nÔaÏD0~!a’ËœÇïFÑ9âº9ñxa»÷\›¨£ Š9u."­Wu—Lòîêåý¥eÂ{@'3 ˜¨Ä=Ð'‘EÌžxfÈK®hÖuiñÀg€~LþiÐÀšÃÛáÐUg‘ì÷Xí´è,¤ÈÞRíè@Bù|Š<­˜è3ˆãœŸŒ–×jÂ©ìMŸ|WI”ÎòÑqž	¢;’ƒ¾0ãÑ¾Óƒ]ðM¯‚
#µàu©ž5Ç¥PÞl–åe.7vˆû„[pÉÂ¾«z>¤&ã0™@|€KBéò”¨òtØlä™(>áÛ; cár¢)‡Q€„1R€@Ÿ/`’œ„Ã'*(3Ó2•_*Óó>@†{“XÒp†W"íõfùìh0Ãx3éÙF@zîÏ€ãžC/$&qÂ†'H!ò¦ÉxÅOÏ"kŸ%¸«“)š¦|Òz1»³‡¢3=dƒ¥ˆÌ§C ‘b÷bi,|Mázé©¶(½‚Vf(Ìð‘¢|v†¬ÝM»,²„<ÃI³Áïû”´A%ý£w(nñ¬ ˜<3K$1%¡—e% 5˜áéäìÜX!y•æVLn
„…*ºáq‚ók¨tM¶q3§CòÀá>ÌHK‘ÌcPp‚_#ÝÃâ»eûh»"Éßºp¸M½©&%d¨ÁÕ6¬ìÇIÙ(Î4'¹¯cj³œÅ}Bš4
ßO‰=£ÐAWó"98W÷I3n¬'Ä¢íKõfáô^U@\mÊ@[{˜'0¢­™+Uóª%’Kx^–ážijèñà
Q¡g‘i?Œ ‡Æpaœ‹ÑÉ…ïÄ…Å‹8v@kMPîpè¸¤,	ý0CâiÌ×…NºG{Çª³¿…†¶wNvö±ñZ“ëâ„G¤þµ‡ÇÔX<¥óÕ·è¾¹Gs¥pd´ÊÜ2oø]s¿Å7.…®³HùºU@šMCH `4Žq“fè J˜¿5óŽ@Ý£v§2¾“ŒÙ$ë‹ŽØ)§çž½RÝ“&¬öûpä9?OP–[ƒV5éå5:’šjj0³+Ä—ÆÁ|AW)ôoÒ³d Âs“ÜÑœ9Úª~8¡k‡PŠœö	0áGÂ|ÈÉ1È0‘¤[éÂ
Ùaª$Àì„XÔã’ DÀK%Bé3ŠÓÆ4¹8çØ	™¸ÃÄj2§ åƒXëU$Òo5íH¨ÑÀn+ÚŒŽªõR€mð³šlEË„áv%fL9l<ADŽ’¯Í&ãíÏ)¢¸Ï}BÒ˜?W§ýœyàîÞ%Ñ@" ,#£—
Pæ‘GˆšÀàÏ»NPwŠ“žeb	Â}êQ{Fp€L¿CÞ¦_Åc›Þù@Ie„8üñø‚³OèÌeˆÀùG3`††ŽY¥Å8ýj»KT@ÁÄ0ŠðLè¶³€
ˆGovÑ‹‘©tXÈO/Xý€+sFæ$`.¢"ºã=Å;/R‚YÑ†(aùE­¡S@‰J4PÖR`öHfH`»BNã|Hâ‹ÈøP–
BÃx€¡Nq2]JMA~Íüúe(Â´ÉéÁùã{m„³‰ç"âèÐ"]ÑˆFgÂüj—äõýEŽ¼ˆNDÒc«»rx!˜Äš£ |c‘Ø5Êhà +7Jêfd6W˜±-º%4¾Ñ3‚)«c²K‹…z¡¤«‚°‚î"¤C,"2I< ¶hÓ&°9KÞU‚Ap-aÖl…gJ*°#ŒŸäƒ1ÆCKÀwG¶ës˜à‹’$˜×Ïh‘˜½§“žY¶¼&àÆÎ¬ìòŽÃÁ $‘TZÔG£ˆ”X$Œ|›BŒõ–×Õªžšç×}´&ª²KŽX,@£¦"cV´KçÉ¾Å×Ò½¬¬aL‘)œýGðön¡ì!/·j ¡GxQT³¾ÚÑ›f»;É÷‘	rLßz£ÆÂ.BÐop(RBÚ9ð<|“K€Ê–ö¯ÐzÑÐ[I	]ÀíÍ@¹ó$o]ûÞlkÛ·aÒß,<GcHÂÓÐzˆ6ºba,§ø@¤ÕÛqÙDY…¼höŒŽI½„:ËB$j5æŽB•­!wÔ°á­á­Ô
Q	Ô˜t¤ëü¬†u¶¾Rï¾Þ„è‚œÐ¹ÞÛðœ‰ü^ølÂ«41fq£,!U²"@Í§9Ýñ³º¢bÁhˆaY‹	«ˆèvÂ¢$ÂV–ÆÅ«¨†f"–ðUqèÀxr Q˜¶Â“òCQÌP˜—X"îZl‚Za5A¼r)únª2C¸Øe5RÌˆÂS§`õ-h©ÑI|ÒÇd;:cÞOãœ1¯§]BbÂÜ8ÀzÍpÖuäÈ¼@&Ü>V€~Ÿ7X.ÁáãQ”iµ@ÔJk´çvp‹ìµåÛD`jû!Lm³!Ýòj2¡ñÈIìÃ$¤’M‚‚aÌQ(u]¨†¶Xòxžv­D¦ë41„æF6ÙT›šìRái?VNHqÈ_‘ŽDå³rý‹ôµÖ²C¬ïœ{7Š×•6µ¨dNÓ”…pùn€EDrOh£²ÆÝL´9Gè„]œÀÍ$“}aÊx+ÛÙ¿–<ÛVÁÒZuŽaýŽ aô4®OjhÚCŽÞçë*§É_ŠÅ^¶]ªv/{’ð9PÙ6öÒ]%á˜_mðV¤Û³3³5¦N™Öôe¡u­`b¶kš¢7.å˜žÈ§t9Æ³D+±¤î2*Ð¶p">ÇæwŽ-”Ê&f{õ©ÚW6ñ»8dÄ~mÊÍr2¨e‘-æ¾c-ÚXylo¸€‡[<ÿªéÛg€ £eÜ®l£…éÿ@™BÂjdôB16Ÿ“¯_!@Rê¯µ‡¶ä6%Cô¡6ð“=¥@XÅEÊJ‹–å¯Ð:ÔÛ=jMµIRïTvAj@£™ÉgÉ(ÇÃ·akÚRÖúD9¥äw>hœ³\’VùûìÊßâ‚’Âê„x¤´9Ñ%byd‹§³©Èâxq}À°“ô”ãóˆWh7Ñ ”ó˜}Z(iáý¸GÌŸs»¥gW¾NHLþ“ÇdÇM€•ZoZŽT[ô%²pmôY×Ì”ãK£¸mrÚçí>ÆNfI´1 ÒORÏF„öÂà©ñ	ŽÑ‹OB‡Ñ”9/øÒÑ&Î—eA£Ír6Ê!˜QtÙ!v%"ÍÊ¨}\¶«'–,‹áÈÁTísžŒve€è•ÅåŠYÑ#³Ò­,fùL8ïp J!‘.sr„lÄœåÆÆâN²ph,•]SdÒ÷v®ÐY4Gƒ†Üoúˆm°wØq*ºÈ´66:ï1_­à³Œý{ìÏ6Ëˆúvá€9Ú%>1ª°ç5Œ'Ì‚ 'áê–Ù71v?{/Îz³±®&åEŠ Ž ÄŽ=Þ‹£D``åhåTê˜ÄE8%â½xGhƒ!v²¾FFÞe‡ô™-»8Áû-¤#Úïñ’ý¬”ñ…}†ÛÓnÕÜ¢)£¡îÊuÜO½ÃCV
(r†|dÝ¾aû(1i3Fo˜¤£ô™	è–!¹1í9F!¸öj07ÞÀ‚ÏåvH{T†@[_×,èõÎáC8¦hÜ˜}Pk9xwcMmÃ6ŒÏ ûúŸþô5Þ© Â‹*b5ŠhT“>Y½m_^Cn#ø‚Uði%û‚/CÜ\¬ø,áÐH£ ä?‹‡‡ñöLéñ”o2!	ÃëŠ: o<T[³^L#$¹‚=Oy¯(³BqŒ÷FèAÃ•PÍTX12­8Tã›ê]5‹ôB–Éáã(AêJJ$t¾]—d“_wö©fŒepkïÊfÊÊÌn–-¨ÞM:½-çÞ¾ÒñY[lPs9œn!„K/LøóÝÜi˜¹ÚL‡! h±†ÍƒËÏÆÕd:É' ð³S–üÃÖŒ…î¤ù1;B{½Ä™-4v=
(5N­Ü!»‚É‡‹$Æ‚¾ÐÄ/¶hAÑâÉ…ñÙôE{Tw‡Eq!AßX§£RÁdÿÂ3Ð\{ÓŽ+cs{DÓ8§Ëê›>QmƒV©¶f­áæ 9º‡¡X#EÕ“äwdFv[ÝCAA"Ðáp|B>›Pü=2Gm(´Á6&„¦ðÐE¶=-Û‰düÊu´°Îµô—U‘6Š†1£sÇ")zÄö¢b.ÖjFDÐGû 
cÅÍ‰›†4wÙ&{èÂ:	¯lõCfßƒ»rŒŒ•Hi¢|ôû±Øu$$¤ ¶±ÂjTâ<û¨±ÈÛNýMP\•:Á7ÃåÔ|¸­ìùF‹Ê¢’íHVÃFO÷TˆôFã"„Úœ‹S“…öê6FHË°Ä"€øeFv,qŽçûëE±Ïm‰ÐeEVÃá^¤yå:’ ´>² Š0™ê &÷>X½¡Œ}ÞJ Ï„tM=hÖ.ûÅL¢(ImÈ‘‡Y„q'(ksÓ›àÉ¤HUžâ‚„å(êïë`î^jmÕ	œ¯Ägo-4Œœ	¨6\c',P	.£H<ÂÇÞ‰žë`/mæRª_×•-i`|,~¾«vŠèÕØ)¤MPæ:^áÞˆ}Éc^Å‘dAÆ2-a	ü¶‰Ô;
ólA«06R|Hçð¶Ã³ÁÐÈ
¾ÅøÃ;¯wN¼pýŸD;§è=¾ŠT_”Úv‘àäÅy‚ÑwLìŒ¬úÚCªÍ:,nŒÑ³‚üÄXç¨0¢²‹®é‹t4ãòµ!Pš4$Äï<w¤sÔÂósDhôÛÆz¦v‹hñÓÜñR[–/3´	•E3b²•ð§´ÿ®„'gÜ’P×LÒ~}QzY‘A×SB*[Õñ‘—þ§Wdmš½Ã+‰tÈ•¬ïÓÊ
áÎ×.OÝaEØé38œ9¼Ô7”TŒdbX˜eÆÍ8—:½1\LÀ&BÍ«´ˆ+Š4ŒOId+‡¥n™ñ
Æt@ínC²9ô†W9ÉÀæE@V­}ÚiQ£õÉ{ãI˜ÄÚ®ÄT¢ÚÔ¿ci%TýYÆö32£lBŽ œ%­„]á€<ËÚÕ5‡LÔ2Ôß–Š¨>K{À‡AtÀû‚ñWWQ˜±éÖiÂœÓ±?iarÂÜ*ãkÞGÈdÃ5ÌR@œ@÷ú0DÉÔ\\X·HîN‰'“rùŒ0½ÈnËÞ=ƒ2#‘£æÕøÀ¡¿9>4´‡”$wáâã”£ÄjW/O	8a¸u)×§!òŒµ~±˜°
C’mX«¨‹°EîPGX°’°#IE±œà³C]}íÒ=:‰èp¬Œ!y!V«Ê	º2\8ÂPV.çÚ¨Ä†â´×s’ÌXE—:z0Ð°À–¨£"mWvCØ«§Ï<Ô\£GòJ¸Å™¿>³rÑœ‹&Ú]g>#Ù~öÌž°t„N¥ÕbÌ>ŸGEKÞAk¥vN}á‹FÅžz˜>3¡Ëô!NÀ•wf[˜Q9I/eà&xWÐ€mj™Šé<Ñ04HŸ”æ%ÜmÌE%¾xùÇ×;Æ=ä*H„ö«lbz@ô·ÝZs®¸®!v¹{ÈåX¾þË
9ªH1k]¨o­Ã7ünj
g•yHP9Ôº˜]†sw·…Å^]5ƒ$#Yä0Í9¯cn÷†Üœ­6n²´Ñ„1Y-ÔqÔÛ0,Ãú­sÄdö6çž6™Ë­‰æÞšÙ'Q”5§iÿåð/ò§w˜ààÌã„íìŒ(¨„÷®Âîû„`¨g„ÎgSÛ19&ñVë	{kÄ|#º¶C&ú¢J°†@ÜÐÈ1>:D=®Ù#.ØØKª¯^ÏùTÐ\Ü3ãÈîûÞ”)tÂÐzòÐMÅáÐ;˜ÏÆ¬dP­è˜H§`Š¹¢´j8R¤Q3‹àn¹3iãòUÝxi8ŽÛÀ4¢a
ßñ5+q^å–jÏ±qysõ%µ¨8ìzÈ¶è„ÂÐû‰aƒ¨$˜G1åÞÑ"C#=Äöç-¶ôÓÙÙt0ãØ¹õ:ÀÑ¤£ÞçAx‘RØ"Iá¹Î¶q#¨tvƒeO«å„X¡ÚÓP5o£¼¸ê`z5!Y1å(:|TP‡aUôQ˜çNÊG£`–Ð~ã™Ém(®xtABJ¯°7…¦æÂèYòEïÐˆOœÐyÂž ˜8¥™p”M#ŒŒY¹í…™ëÃr`ÁÀI	¬\€L½?Ciš·ŠK†Ë <ÝYB IÀO`<	W$IˆcdÔd³Y$Œz‡ôZ(~‡ãvXAÞ!JE¿ëð ÷Š9‚cXVÚÏˆ½¨Ž†äIÄºz]ñö2á‹-lMpûNª8^(ªHÛ*[7t<ž7A¤@AXêÏ9¡ù|‰.ò¦‡V¡ Ÿa¨bTd3âlœÆÉ‰T!Á×”ñŠÑ
4•Ä„Ô”C%U„É ›Šx]šC®Í³ˆÔ|ß„˜s†a.ãP‚Dwž-)‘J×«‰¾h|8»õÜ¨œdÓ²èî®r¤}ÎÜÝÌ81™†z(ç&JÄÈÀµŽÚ¤’¼ÓÄ°‰¬vxœí$¾jMgñôÊÈ¥kÐª²ZiÞôg˜Û÷1ð”Ž£ ’…ñº}û¶ÞT2%žE®Þ°®¯æÝ1LÁŸ‰ÉµhKÙt° N"ŒÏ:IÙìÈX›’’ÁØ)„ÂÞ•{·
8)I×,y{;N{&ÜÌ5¦„wyÇÑÁ^Ý„-¹ówô¨yK/Gè…A„¾e.8­Ò£ìHáèÚ{DÍÑrl„ø~èÎÚkcö!s–"§dðª!¨”¶Ç`s¼(2
£ …Ö	DÜïGd¹FIÉ	…„*L …vgö‘–EEÜŠÈ½u3õÑÁ\.âtD‰x´¸™T£Î´‡ÑaÆ6ª.ìeiž»€$DcÁ]`ª0÷œµ4L9×ïYyy83‰:›Ë²pt™Ø9*8 þUˆž0çDw¥ÑµæDZç
šg°QÀÍ'f	ºEÈñŽJ	~M‹vë›VvÖ~™“HTkÎ§ÖÁé`Yä†Þ ŽK¼tÉ¼©ÓÎg%‡3*8	â“ˆ“~²H³=ërkÕ“à‘Cñ@‰¯I‡M°OL»;HŒjÀ1#œäfÓAlæd7XÝ5dy±&œNlë+å<aTqº°rî[¾u”ºCkü¶’î™Mõ$QÞú“MÐQ½q`³»ªbt¥’sI8}!(…‡`ð3 ½ìêÌˆacUUh.#”ºœŠÐû*ì¡¯Fû³Ã©¤(!™#ƒ:õyÛrK¬ÎÁÙ<m5³q»â/J/eÐ•8©YÁúÇ¥^`!Ò»U·Î2±s¦tBˆbC|Çb!É÷Iùqwä>Ô¥ÈÞ[÷aG“¸­)#e¢èÐ7]Gçcý\TFÁa>®]ž 9EÊÁÙ2#;'Ô(#ª.À·EÃ®/$~˜}eÛDÚ¤¿@ÿú¼(M&ÖB„±Iépfm¨)9äjý!Óõ¯‹sx„2¦vB™tSR[²Ã¾l
c~f—›	{a×(o—©È@£kuÀÆfÚ¶Xò¶ñ¸jŸ,o=»çPòYÙŽ§vö½:^ó˜bt/ÃIžÇ‰Qn-ÎÊômÆíœº8‚Y‹-Z!¶:g‡.)m/w¬‡ÆÃ	Mù%»”~G[Î¤³J<xmÃÀÉà;bô»÷©Ö…{FG×¶Eu#ñf¢³‘­U—2ƒËã8FQ?È0\Ã<‹†mÎÊ¥H‚´?¹wàb:¼Ç‰VgWâ0ÑG&–Y½ùW~ŒRçÜ[®ZÕY¶…c”È›º~Nkm‘õêŒ…mÓt©½ Œô^'Wn;áœ2T	×$ƒ€”R»˜‹ñÊ0ÙLå
AlÅhâÙhž ùéZMLó	%ñ×.7íÚGd"o­]3W? °O±K¢ôhîs¨=k=¡ˆª°$‡A«y1o!+‹ZàUÅB,Á>ËQÖÊ&¥jtf~¨€$Yp  j6F™S[¼˜hWôsøc±Hé¯ÜqÊ»ù´Ní<ß3=ªfzÅ°ç3¸x°3oþ®‚¦ËbniÒtZoÀe¡P:0Ax&€ÍMfjPÈl€Jˆë×à!ÝIutBÏb0*(9;<AÙÈøR@–sÒâjhJBÖÅ1lSn€'-sŒG8ÓÝÂÜQl@uý²\±# Ó ù~Û"%NØáÆ}P>šÉ±µ 
''	Ý4d†9Ó“Êa€TTE×)>õéä°’oFLå)¼‘XÅ…U5Š—ó³¬¦²€È«¢¥SœïF/)¡ppS€±˜
±…[!|7zdkM/œ 0ÞéÅ*yHêw¥ˆ8I8LÍHö»:¦ê¢ ¨ÈFDöV€ëBÙ¡,–a2¨²2ª”#½¬ª¤¸àÝD?±Çæ#Ö†\F ac«x À yÓõÆ4Ÿ%·µÛA5ƒÆ‘+Ã]krÂð×kªORÍ`*'AùE÷@·Mi×½$¤mbàl¢³¦Ò’tZIåÎZ‚åkið‰Ç,'â#[âqdëùæ&´@ÏÅOËòiÝêqAqº6é 7£…jö÷¾»¿D|Àt&FqæI±qÏÒü¶tÇ|CŽ1ëÙ[‰;f.¥"JS¤—™­Ðáf Z(®¦|›[š¯˜Æ‹,rfì¾„^LÝ£v0 á¤½©ÿù‰ôÒÔTÁ72¼­:*!0\Ö‹^Fi÷ìO-²þMä½ ~¤=åg´Ò%tì¤ëáÚe>2P dŸÃUôD`R–Ÿ‘d³;IèfÈ¡Ü¦ZJ9ä¬ù$2‹"Ô..|€K2–8ÀgZ2,ÞDDÞ`‡6„f—œn/È[ê•r‘RóôÃ«8ÇœÒ0#ÉÄfÍ‘î8w_W´äl½ŠCð+É¡1ÎÔØáÔCÞäR‚iCH®†e÷ tï¹Ü„û¢¤ÜÑœOšˆ0½^Fcùb@4øB¨8•¡<sr­|¯ŠÇ]5Ê·¬_e¢!‰¸#-°ÅYN…½Ð˜ùŒ]$yëß©N:"±È¦=q^fÌ¯º¾¢,F†tkŒuUC+*OÖÿSc‰ßõŸÃ©š\ðÊ-ÉÅ"˜WÖù>–êä¨[PuŠPcÁ£ceçŒ9n½/¢oó®k 5ˆ1ŽYGm%ª¼:	sg'Ñ”‹\îZ‘;Gì’Ž4Áà\Ó ãvðŠZz®óØ×ÂÎö«»T‘±OY”l†!''h@¤û¬ `]=²ÄYqËÏ4ˆÏ£ÎK²‹ysuîºÎ™Š3Añ{
êŸ
KÊŸaõÑ`€!W%±Yôm¤<*T®=o’fh|Ÿ…”|dù”÷>OöJCˆR¸ãÛ‹Õu³ô*‰§,uBè8{ËÎ¥8yµ•®Ücµ	¼áfÆøxÁÂäXjr$Ÿ?E¤ÒßäôÁ”ÒšJÐ}v®•øÀÔ¥±%Ø}ëi0W²ÂQ3ÙHåØÃ‘Ô?St“X½Ü¢p8Ž|’¬’õõ–:Ôe-uÉ¹„­ŽiVÓ7‘ï”±èRN@…_`ÒNa:¯ZÌ¡­ÀIilÌx¹o³ÜÖ&´‰:DA¦	·Ñµ)¿grH¼–¶Ž»íâ¥âÇæ`<Qß©ÆáøSÀ´4âú¦aO„8d¤,êëOšS`ñ<r:'N7s	Š»&%<(‡LŠÈAæBÎ‘·XqSZeD Ôži^êÜ)‘ã‰
€%}÷«Rz+Ææ¸†WZ-æÒƒLG5[ðÍVhóªÔE¾cè4Ý1Þ46ÙåÔÄ¼z¦r5¸g—Ó;í¬!,$»†)?€U³Q«jªÓäš9žÊí~	çà 
—´ ¸,<K¹èíN·œ¯¸-ûÂU)ˆ$<º,|b°!Kgb¤7*«ÙYŸjþ"™H$WÚ<@ÓH¬Sì~§l“ü2HE}i°*•ŠÜ‘vKŽÓUSv.ÑK²°T)Ö}x¼‹(	9‘“k˜‰ÝŸ[¸µ'ë\Ö¶Fç\3…Üý¤à–.LL©¹Î±êsV[Z—F7™àVE9ÄW,£³¦¬ÀËàIiªœ¥678Õt‘?Œ˜\ ©•Ne‚1nRçE÷—¦$)Û:¦Á¤ò`˜4E`K
'‰­‰!˜‡*GÐW 6g­°´9budÜª¢3ðœk…²ŽB)²EgQÉØVaJ¸;VS¹lõ¾¡áR¤à©F`êcëÒÓÁÈU›ŒFdS°âá_‹È¢ËŒxRLqÅÕ]‘1h@µ”TAqB–ƒ’y›ežŒå/msá‰qâ`Uneà÷dîcV7Ô#ÆtN`3Â-…¦Å) erîÄî‚’,£Ã(Ž."„!·®nÀ|r@‹Í°Ì$òÊ¤"sùAuÀÇä ™¶9Õ \™t7Œ i]Zˆ&Ü(©Î”¾NþÃ*:Dbå¢¼VÐ1š)-¤£}ÍÜ4ÃŒC×ª«ý¹šRI›N*°„ÞàéÇyÁ„Í¨,&,Îe³Wü!Xð#C8yªMiX;Å¡jX$‹‰¥¤ÙUMÈ,à±ŸŽ‹ýÁêœè!Žo˜Š/yQ}aÙ:·E½l½–¬¢SO2Ò‹AòÃQçk!-_é*2Þ*±äðjÕ`dL=Ð	¨_` ¾¦3” %ˆÔ¦;’L?ÀÁ´!'Ä'áÕ˜âœRëP¼ªRšFÛW¥HàæY)ÔèsÇ+ÂfÙ¬¡KšRm¯LI´®t;´áµAiI.ú	>U'-S?Ï#i&ˆV‚wV9~.¦Ò¾}c^âRÿøq™:!`”âÈ!žI¿jhsEÍû,zè4í\ÓDòÎV\`q¤àÜ"²ô¹¦ƒ ¨%kI,õ÷ä24ÚsÃZÝ7¾U{a§…o¦éø¢a¬KË:f?“©AÅä²™ññ‰:í„ê‚Œy`ª±iÙTc¦ñêŠK`
Ð6#"cè²9iÌî®§S/T
[­o´°¸Õ±yÆÎû !æwée®~:Öò[¡Þ›(úR§L­jýÊÙÍ¨2»3ùÑN¶®$ŠúqÏ„åë!ª\nWº¾l$²[×Ø†æ÷mYñ“ŸmÐ„Ægñy*åtjYg£i¨ß‰áH½Re.Ï$ K¤èL1´TÐÒm7a/%»¼kþ‘	âfTü¤h*Ò4·–xÖ'®³ëøí*”uA£Ç*Z#È¤`‰Ç¹³ÐÌØaùA!S²Tä¹:¶šm£g~’yèÂÛ%£‚“£aá%æèL£æ'¹ÕŒÖï·0¢ÛJ™ø.E5ÈtÑóhÊb‰”ä­P$,‘QòOhnä½<!ñ©•Ïj,œ¾’t2–Ñ[—ÃÖzu‹/pÜ˜êdrÅ»Aú^

Ô1)t%"è¸Zk]÷o°ºF`o÷)¨e¶çó7Z—Q±8ˆÀ™­ì‹ÄsvãËƒ–:Šà„aÞ¯"÷í¥‚y·iÞ[„Ù*È2&l¡‡ÑÓËž÷b!Ý3tçàÄá_*p{ìÁÁõa„¶.×‡’&q›l^‰Z4V/Rnp–Dˆú˜Q2¢7tø9Â<jÄ21n·ãgÒè	{Ã•QIx@lšÁÒñ\t‹d†…MäW`‚Ë%TKƒ&„˜;ø]…½

{U³.&AX«§y×‘jàÛ[JÓàHj²Ý96ž9OîˆÂ­ªô3C~¢8	ÖPêáM`ñ¦gdvÞ'”výÕ¢Þ|²ác½aª½ÙŸÌü‚ªù9x­Y»;ÃÒÆ¼»âáT3ˆ&ð“UÁEä¿g¶ õ„îëx~}7cŠöå;Uí6¹!Ž^³;Þ‚®{hße#»t ZÜ2‹À]=›‰-™f6:7pãþø¡$õz8‚BA\Â¬e	€N+"\H2`*nÔ	Z–à2bƒôâ!%»‡-Î¨ôZ‚Ã™Ä½èuÕÎ±Ú?P¯;GGý“ïÕ³ƒ#üB<?êì5ÔÉýÝýÏ“îþ‰:ìííœœt·ÕÓïƒÎááîÎVçénWív^ãËIÿ¹Õ=<Q¯_t÷Õ‚½sÜUÇ'ì°³¯^íœìì?'€[‡ßí<q¼8ØÝîÑUm:ªÃÎÑÉN÷çñjg»ëÎIÕ:Ç0íšz½sòâàå‰™|pð€|¯þº³¿ÝPÝÔýÏÃ£îñ1L `ïìÁŒ»ðåÎþÖîËm˜KC=û'jwVÍNŽ&m5tœÀßëm½€?;Owvw`¿ðY­g;'û0í]‡g¾õr·s¾<:<8î¶o! ?Ú9þ«‚ÈÆþÇËŽ»0öðÝzËYs Ç„ËUß¼DëÞÝö67ª«¶»Ïº[';¯ºl	Ã¿ÜëÊ~Ÿ Ð ³»«ö»[0ßÎÑ÷ê¸{ôjg‹öá¨{ØÙ9Â]Ú:8:B(ûŒF_·8¸Ü8<vuÔ2SŒ}Ä î+Ä—û»¸GÝÿx	kE,Q>– üÎó£.m´ƒÁë˜žžAÅˆÑ .ð…EŒïÅÔÞÁöÎ3<Aœ­ƒýWÝïwW`Ÿ-ÊvžàÆ<…‰ìÐ|`¸KxnÛ½Îóî±ƒ8f l7Ôñawkïvy«öa­x´ð Q8c„€ÈÉç¼„‹€¸¯ÆÆÏÜÉ®Ú±ËH©vŽƒíÎIGÑŒáß§]l}ÔÝ‡¢;ÖÙÚzy÷[`˜ÍñK¸;û|¸^ºâ;GÛ¾d„·Ï:;»/Šˆ‡#À"HB@ç$¸Åq½àá«g0ÔÖ96å]åïÕ8Š§]hÖÙ~µC×QÆIîÈžÀê‚ì#cß7-~[ŸÄ0x\JRq™Wß#z&#Ž<D¶á÷¦ÈGÚÚýXð¥Xì€“W¸²°Ä7žRº‡(F—l a	ÖÿY@Há¥èìXŽ©7J9[ÞÑ	y€6­³<aþ<Nfñeôø"9s¯°™82˜$õrƒlb¿6Ý™= ¥ð3E·/–u­ø¼¤sžó¡ýyÁï:uh‹8œëD‡–,o„U™@îxä]Ò.í«Ä:œAžœ‰¬ãœòsàÜ©ø_fy!·´!ž‘|Ê5Œ0poHu*~±xøOg³8DÏm¢i”ß“ðâÕ/«ÿ’Öõ#i#ÖÀ êPŒV|Õ©SFò×1;d‡ÎÃ.glzuc¨8Û‚‚ˆœ0{~¯%÷^ÄHþk¦SÕÐ/JL„<J²·®þFêOÍÈ45T–Å,¢&))ul_ÐÕs3SÛ•ž²EÙTë;ÜNê¯k¼9ë¿›S:‘€>Ëâh€”Ð'yë‰T%ÒRÖêV]}‡ÕéžÀ"Õé{OxÜy¯U‡mxÇ½iÞ÷9žj}P\œ7TíQ\(%‡¹§_HÂÏ|¾¡Õ˜’iÁÆQpúÑªŸnZ/k6­ê°ë4oWÑ½ “tHgÉŽ“«Ò¢>ªÅ5ä Zd{dòj±‚ÁÒÆOK¬8íª(yÁæÎ¼”¼Ž#ÖÂ"=\»0XMÖU£Ðáâµ‰lö#ëæ–ºrN-2»—¬²cäC¤¾N§“Ívûòò²užÌZivÞÖáí'0¡†îaÒ[Ú‹ˆ0í$û7?=N5ïÑÎ—¥	VÂ·BÂ	F®ÀÚ\F9qõP‰²¹Æ–†¦rú±•÷#›rGéWZecaØ)Õmäb§nÁ^,\#)«ßÉ¸On|KxÈ¥™iO;Ov_žtw¿w5™Gt¦rœjzúwzñýònË‚+ÞgË:ˆ–G#‡“Þõ&|›MR´±$<r‡ëÝu'›–¥áÕÍä.TæB=?šƒé-ø§_«w3ý‚°sìJH1ŽmK3õÐÁ˜Ž +Yh½ö‘p÷ç/wlõcyÆ&4#[ƒªÀxq–¾«™¸I™2Åšb¨%Á½N¯0¢AìÕöý¢_”Õ)¦õ[ üÜy½°W Óèbe¼šuã›²îXaÅ¼ùñÌøÔý‹Ã/;;ÏJ²„†ˆVm.7¾¼—4XzIÙr¸€Ò“Gº¹ÅÂ€H¸çÃ•Ã&ö]jýEîäJ8t9Ä ±,E?f$Ïz]I²—ý¥¼N¼£´Lž)²ˆg‚†lÎã¶#Š«h*fHy3G€k{ß£K‹p)áøt·Ž[ÁÙÅ0°lžu£„¢°_á­Á’:”qƒÑÃ”Ž…!4•G1Æ J§“áUûrxÕ„mnŽÎ'£Öp:ÁéüîŸñ§ŸöÚGÝÎö^·5î¦1ÖÖÖ¾~ð@á¿ß|ýþ]Ûà¿áçÁÆÃ¯¿Që÷7n|ó`ccã¾Z[¿¿öðþïÔÚgš÷3C–SÉÓha;h6,øž£Ì¿ÿ$?wÔÁËm|ø-
Nð±ç>Š`HD´•[¼ÚnÂ÷Ýäâÿü?ÿQKy”“L¡ôÂ%	UæµP?ú#I5‰’‹ÄöÓ != †=â7úÎBíÄ´d@Ç³oô@ª jÔÙ‚1˜¨–9¾ÃŸ ÖµŸpy8ÈÁÎ¶7RÂ2bÂ` t€‚OgÚuÊzÃ•®pLŠ6®}øÃÆ\ æéIæÉœ¶Ó§)ðº`5þl1M3ï(º[ßø3t½SMJ
UB¯¦ð+ÌÞ6nëmôö™å–ã½†:êl5¨Ñó–•¡êEHóél0°þ¶81¥@½”2
Œ¤ÓœE º§‘æž„šKøÍO3	Æ¼w/õaR­|xïžlKC¿æâó™¢’'Y±š%½!›!b¬Ó"nÇu	R`ÜÐ£'4KÆi 'ŽæÔ»/ž—Ò(¨ÀŠ‹ÔBÎßçêuE,ÂSÐ!7Ï:-Q€u^5t€¯‡ì•Xò©ìÆÉìzµ÷þïÿf…sÜN{oÙŽÂ\ÄÁ(Ga>9‹ðÅ”Ã›ò¹Ñ§1ˆ>†vÕ>žfÑ´7¤ñ]Áó÷R÷µšŽƒpJwî€‚2M
Çeã6@<:}†l2Ú`£¡.Kf·NáiâvœÊWx¬-¬A„É‘•ß²È` k/uw}›EãðyÁDÿþ÷¿ãôƒ”öïßÜæ·Õðïi¯ŸG?ªölm½ÍOŠ¶Ëƒ©æ0ØX[ÿ¦¹¾Þ\¿ºþ`sãÛÍ‡ß*ôlâ+Âl˜¨èº*~ZµÖZ—Âó íì?;P›€ˆ¡µœU6fbÇaÝc¬»º°óËœŸ“.Oä‡æðâGøï™úî ®ín÷ôiç¸ûäGµž‚±é±³+Þß2]hŽÍw/öœÏŸÂç/·áï­¿¾<”´dÍa¥…Ž~hÍj•ä®1JÍçQ}¸‹ùàä]i|#½o¨ø-ƒVØSšó¹ÚÖ”¦¥öÅÑ	³sªxÑb•nÁPË~,!ª÷Æ6_.[KªO®°\‹æ,dµBôî­èoë­eCôytTA®ê!ìfÖe¿ì¢‡ðZà'ì¡­ú„* EôHÙÁ€pyž*ä¸c3Î[RÝ/Pá|ÙFtx#@:ÞÙ/ì8RSgqÄ“QÒèa(Óq¿ÚôE½¶lÄŠ{¹dÄ³°÷v6É«Æä¯–ó >õX8(Ñ-zg³bXóåÒ[^E–¬V˜}5ÒµÇq¿?ŠðÔ—Žý9vúã)ènzN|rSµ§ãI‰ÇÒsd’AàÎ”=§t+È]<S`õ÷éñï"âã7.ýlA¿æÙ½{B˜¸æ½ÄŒ°4çl24³{Ã22ôîW÷¾‡œûžZÕâÇ¦Ê|øá¦:~Bó¦½8$Ñ8@ô¶®0VÑoTÊw (µT•4%ç›0‘µ6HmþXÄž‰0X~¬”0.‹` 1.}Ô'XxØß6×6šë_Ÿ®¯m>|°¹öðÃä‘õÖZkMK$·2úÈ/s;ocv!½O7à"Í¢|a—¹‹²^¦¸Ã&UÊ•6BrYµùy\ÜƒÅ 4‡t>ÄîÁó9 ÖÛxMõížln-¾MNÜ6`óR`ó&²¬¯aãå¾KûylÂÓý¥,?õgM<òçg(¶×›iðM0èðè`ûåÖÉÜý×ûo 
ùÖ¢£PíÁør}£µÑZoÝo­Ýð³½×ðÛ ü—Î«Na¾8ÏÚ?NØþ©ÿv½õmkítýë…Ž·ŽvONŸýÇ~óæÓÐ… …¯!q@†ÕµzìÂn[äl·Í˜bÎav(Æã¹ãÖÈ¸7»ÝÕ½–]Åª^ejð/¿MÕýnpª;ÞŒ ,]ïMnßSš#@/,Ò ‹7éØ9Ï(K‘~kåy³ŽhÕÂñ¤·þóC@´N·»Ï:/wON]H…O—ì¾£Bž”QÂ#ytªÑäæ6ý…~¯¤þ$z‡¶R÷Æç6æ¼Óí ý’\¦ ÊÛXkÿc\	à}›þÃ}O{ ÄÑºœ‹Ÿò³tÞÇp:ú×Â£ø¬À­lXpÄS±¿ŽúñÀý›fdÿìiõÝOZ(6žþánº€Òó,Åp¿y0¹âþçÙñ^kr5,¨<ÿCœñå(?…OóqKj×¾×6Ë'…o ¬‚òÐ+~¬okXÚ8l3‰O±–D?Xˆ‰Gép~é˜
SßøFëŽSìêg@zi¹@æIe[4^ªÂh¢ß±@´Š¤¬þ± H(Y-Lõã 9Âî‡<d/&öTá·O6yòæzøMÉEi
ƒÕ¢6Â}g¢=>–ÜQ[Ã¨÷Ön	ÅFâ`®ë=ð?¨ÚÊ{ÝìºRD­¦~|DikRÔ¢9ÀF(¹\·[º­ÛJ©VUø&ILÔ¦ªÖ=::8DftôtÐœ*{â þ+é³Æƒoåž±s" ÿâGk-å,¡½ò^)ül÷`«³KßœîwpšÖp Ù}øÐ5ßu1û5kççO3ÌIñ]¦ãH_4óÝB¸RÆƒ«ÞRí^Sh¦ÚÆY†„áœ ©R/fëÇ‰NäÎ§ÑDÊ~ÆV€ô½4ë—òï@[µô¯,¸Þk©¿`[9NDs‹bp32bDøû‡©Ý3æU!Ls¸Ê=×@ñ©×$Pö,¼)k/º2t[ôµù¨«ó¡—g•Š$›TMÏÒè\_rK–ugÔ¹s_htLF¸×¬7Œ§ùƒàé•±kÜÓ.-4v¡7Ü¦¹c=×@Å–+1Œê,çGã¦RTl\®Ïo^Äòr{nªTè‡ØÅÂi7EÆUØÀp.çŽSÕ3Ö¶0 †íøÜ,©6‹Ã40x+›ñs¦
ˆ×ÈÞa=C6æµ8¡›k4«…m:…À[¾ÉÏX„èYÜÜ5!b¤ºótîYÙ8[½;Þt‘ 5´·¡XÞ¥‡ðáÄÂNò5”mÄ{Ç`zFÍ‰øžÙRì…K¸¬°t<­ ø™@¨ÂÏÏj;bÒ‚mñhØ,ÿ¨Ÿ‹Ÿ`CK¾]ˆ:Ñ¸ðEI iÒ3ˆ¸+v/ÙÇí
s‚¨§ÞŠm„[ë¯©ïgne‹$jWaåòii¦r™ô„Ð¼í©ThÊøÒœü<úïnwéã†¸dø÷ãã]eê}e‘;!õG&ÄõDÊŠ]•2 …¦ºz"ÌÙ”Í½ðšuE—§Ž;«?“·'¬1TÇ ¥ÕÏ…~¼	•RæbYôßo©ÝÔ–Ž+-Ú¯#$r5Ž¯Šükg'mÂXÂS‹;ÁXí\õ—hâq;kô—ça\A¯,!}u[`aÄÓ'›3ie]Ìÿà˜xxŒà%‚ŽŠÛ0MÔê°n+pc“ÅÀØ;¦ÙÀçÔ~Š8Ë¦-zÓæl“lbån•ÖV„]yj-kgæV?	5öã±AªÁºnyž¢WLógf
ÛŽ½‘êË 2ã²¼jù¡šåhEai,=õõ£—$hjÜR{˜QÃÁÙcÎúM0mŸ©ÎÁ3Pe%éÙ(zG‰H®¸S'¨^Ð1§îþ+õJ3ã¡î™?Ãé‚¨j¶6·a5»«dzjAÓkÄah×‰ÜP+½~zfVàü]n•«®ð S!îbœØ<t•OŠÁ$íÐýóS†vçXÔD‹§\14¤ÂÐÀ¹Ýh™é•\Eóvf½±x’§‡¢›&§Z’ ±ÊbžiÉ•w‘eù2©ˆè ?ƒ«FòÉÝN½Á˜eb=h¥H,rŽN¸W=¡	hYÖâo®>j³³¤ÉÆüõþ,0çêƒ/Kg–ú‹WÆìæîóh-Ào4Ý¶ù´ÔçX"0P§Dù«®ôrïº;#â|ç¯Ú±jÆ`'`ÄÇºñÕ:
ã=EÌ¢sFGúÊ[v¾BüYüŒ»Ø m¢ítÂAæM×=¥yó¥Aµ“EüvÀß<(~áê7¬ÛøCÍÿ©>
®ÇÒ¡ôKQUëû¨Au«úìÒ­ð©J¥r¼»½óŒÑf1Ó&¾8ðñÓs"7™žÛÜeAhP!‚0´ œ?xP'ä©ÒŒÁä÷eÂú…õ·îƒ’Ïú:tØhÝç)Tºˆ+×]å5~ð Ðç/ð=UBeèžD@ËÏh¡±ËQ*bÊÊ3›ÃQ<Õßcµ…ð%çÊ6ƒJ\XÄj%VŒŸ©'ý”f°}°×ÙÙ¯Øã…·½•ÌÿùY‹ÁúÏüh™LUSO¬-†
jèe0†ü
h{óÔDgGóÂ3jÐ<vªæ Íc*ÞWUÓmÃ'AúYÛ‡æÇJ¯dã<øhùà@ÉQ|7½ÙÈ¤´¼²
Š‘ôÏ"Lß“WÂ¬­‰5ò¨2+•¬ Ý Z/àÜŽœÿa2»³1…Ùì‡¶º¯Î*‘yàtwçøÄ°³rå»NÃ· Ì“;Ÿtž2 Ã×Û§Ïvv«dšCý(¸QUõõ4Ð•÷ZÎ¸nû'>¹ì·¦ïÈXà6ÒóøG'¥±y|o$2}9‹ËMÍ âð¬Å€¬Mm9¸£îá²y-qË¢!o	Pcë[LN±jç¤­ëƒ.ž”4‘{ÕaÕoŠ§)àþò7…YÁ©ØšüÙH8Ž“ª£¯·nóËÙ’@•ø²i#œ¥ådúˆ=
ýú}îR`»8§~>G„Tôoº}f˜æS4^5<EÞf/ƒÍª÷ÀºxÆA0ÚÜäò¯“oåç,9ª³"52b•÷œBÛlt+)Q˜c™~©ÕBeP\æIÈÊÅHÐyF^îÆN¦¾Ó”â‰?q¬[Šß
I¶?ªZW9$ÕýtÔâ¹œ†aÕÑ`ø|¡P)Èæ@W«ö)½K@Š­4cÐè†@£,Ã"ÇæPüÝÍ`J®#V°€æÆïnÚECgÒoLú­õÙÑ3áyÔÄ%iÐ^¢x¨á˜xn?›³#~†`Ér.§Õàç%æ¹cø B¼ˆÓ¹ñ»t%"O8Dw.ýÙdôVÜ–)9Y¿:ÏAêna+¡o­Ò¡ÐÏf	ö"7œüQîÿ/KÀ—ë›é’×®L¤´œN´°ðÝnwÿùÉ‹'²|úî²¿=7H™ÆX8$9g2l>b³¾FÏ„=@¼qT‰¸¯Z¹®ª} ðïl2‘ÜT Shÿ"C…ÁCŒ¢ä|:´o'È€RpS¾¼dªŽZ\Äóÿûßÿî-ö[ø@MQßÚá,hÞžé)[OÉkéœÁÿþ_çéPÿú<ÒÕ½Ý¨7Z›h«‹Ï-3 ûËèw>1ˆQyÒñ"ÈÂmJµÒgKz†æO‹„Xó÷kˆRÉŽ_èÕÔs{ïåá=ìpoûàõþ=2íþ”ÆÉ)œSÕ…³óª€‰©²=Õó[)š‘’+©âÐü¦/³ûaçÓÀ<·:>‘‚§m ý<ÚK‚9…ô†«u¤ÆI•ÿ·À÷”	Ú3N;Þ1ÝJ¨  2–¢­›Œ{Y¯Yìé\Ä$±69DE’nÐîl3±ma}³‡4
\ÒEoó<„Jóâ6ÑÇ`€ bpŠ¹H!nBüëÓ^K_iA^‚¹ÍÞð³I›Ê$X|.:òM¤ŠÁdA§¶}Lßmï­?¡64I\ˆ é |ù ñ!,æŒwZšàò’ƒåpÚØlµÌÃêF¹«º«-Õá ´CÚJ$v#g¶Ú	²ÀˆtÖ*ÔNžc†•u¥ˆ½³Ù9ÊÝ‰CA¸†¹QŽŸÒ¿\X¿nfªbèVòŒ‹úá9ü;;»‹nq|åË11nËàä›í6¢dëœÁ·ÿÿö¾u«$ipÿ®Îñ;äÈžÁîARÝKRúØÍ4>v_ÜG§.YBF¨4ª¦½O³±ÿ¾ÛˆÌºd•JH!šîÊ™ñˆ¬ÌÈ[dfDd\¡÷lƒ9hª±ZAãU»Rù†ü²ëåóìŠ À§g¸¶cC‘/ú
«S=¡ÏE–{‡ú¨ôŠM\ì"-.=é„ˆ©¿¼[<*]ªu©ž„Žñm¦®•uÐ–xÓ¹›µ`ž§ÔYÐc»}I*í×#²ê¡Ú¸Ýÿ$i²ùÿ‘MÕÑÿ¢™¥ÿŸu¤JÂàS~Æ\âƒ€B–Øs¯*Ë	!ŠS^=‚“í©ö/ÓiÈJ!^2ç±Q°sÞO8qîÓ	¡;½“Øþf¼œYÑÆ‚ý¯›ÒŒÿ/ÓÐÊý¿Ž¤+5Ks,Çv[šã˜ž®MSÖÜ–$7u×Ð¼–g+ä¿êYû±–¦Ë-Y“Zºfª-ÓP`¡OuÕ2lÍµ5[ñ<Yk‰µS[36Ç³TÉp›ŠD›ªnµ4I¥–-¢¨•e[o*™¶S»4ÃµtEn9®k´äVË–]Å±¼&`4êzÍfÓV,Ù6…Ú‘}„¡+jÓršºmµTÝv¨£Kª-9NKÖUÇ•šª#{-IÃš…FžlKŠíxŠ#)MÏ´›²¥Z²¡zŠAõŒºeZ®ÞjfðºÌ–k›’ÑlRWR×UTÅÖE“-Ú2SrTË’•|ã‚e\«)5ÍTlhZÆù•[®Ù2äfKu=ª80É³šT VtRKµÔf³+Cmú-kŽ¬Ë:¥¦%é®+×2ô¦'TË[Ü5Y–«©CguY5š–)Á0Z0}­VK£*¬µ¸€ Ù“ÙŽ!»†§Qf–Ü2eË¶%]qtE²¤`¥“…Ulw—1…Ë®­¤zŽ#y¶£8®
Ô"aÓ’4Ó0m©iRK–\Ï1ÕYP¢%5Ô¦êºº#9MGr¡†kjšëeÀÊÈ†)Q[ViÁàD\ÑiË¥¬‹Ü4ÜVK•`­u[‡©×›²l´ô–,i®â@lÿî‚qÅ“ó•¸7ì®X8 ®®SÃvlÝÓ@Î-‘­zº©;¦¥É¶J]Ê…ÀfM …-GÓTÇqš-ÙÔ<0Ð¶MXHIÖÝ&õ$Íò¨'˜n*pŽépžÁmfÙppRþÕ$½iº–áQü¯™ÛY»SX\æzgœ	@U›aÀÉæ ì2æf8gY\Td·%îkJË–dCq%ª hKötÉ±›°ÉT¹Mh·ÂY$.*ªé:œ®Ûnº2l×–*ë¦!Ã~’[*5\CŸ\fR+É½Èª6]´³Šw„eÂ·¤¦M=¸=<6ž$¹2,™bx†.¹”ÒbZrâûa"øÁ§õ”¦HgˆnkŽá˜†K[¦'™šk5¡=°£ªÄŽ¸žè‰zª:ºeÀ-«{²a{0hÎYòŒ–§˜ª®k-Ç„»Ð+†©ôÿ9™ñÃ´9-*ÁYÜj®›¶npºt¼	SLUU¦ðõPÙèM<‹5E5ÍA
À3aa<W—mªÁ¥
Kgéö¼¥R{\×C…Èžïy(Ãîº–Ú²TJqÏj¶äÉ›ƒz-Ý R£%YžÛ”L©u°¬¿TSEÅÞÂ$´	¶Œ¡ÂUàépØpY-Ùr5µ°¬ö„™p=|NQ…âÂZŠäxÐ]®OÑZpñ›¦%ã`,ÉRU­e,` Sƒ§ªçZ&ü«JpÍ"ÁÍ©;–­»®	'`rñ,äMË©kH€«´§¹+iºkJ0–	xï¸¶êùä6MÛ-¹R8r…­U³©[i¸–ÓÒ·éÚH[5Õ–ã¨º©µ`ã›€Å€¥÷Ò'ÂG¨–ç‡£À
g6’”J*šÙjÉxÀÐl:ÅÝ-šOvÀuíè²G¥¦"+FËÑ›â?µ¸ï  U›’~—mÀ©hIÇµ( ©Eáð—W–]nsÏ‚yG2vq"µ¿·½{ÐÝ­¨0i0ç–hg›ÒtÓk©@–¸Ð)²
+M]ÙŽë¥N Å`~L8þ= }´–DuWsMS¶ó½Õ¦kØI‹±äæë™W¼WÈN&äût}¾üù%äÿdÍÂÒþHõý¡;†éOÎÿÑÀ«ncÿ¯éŠÎùY7L`÷$†%ÿ¿Žôü/Œ9>gæè«‘¤qqÚsòbÏm“+›¸)ßÂðzq¤õª‰=üt£gŽ—¯wº¯ N×¢}ôU„+(QZ›<…¼…» ´'Ó~“t¯á ëñ•wë<µgÌ2áû‹D}ï†@ËŽÈ!“¶’—>^¡«È«s	ì?ÃhP*µwÝA˜Ô~±oá6—›¾¾æ+°ƒ¤x½  ~àEXÜZ¼¦óEâ¼ØÑt‚±%9$fµYÜŠzr8`îØ¸EÁH˜Yã[]Ÿ†©5_±l¤æÁœÓcYè¸œâbát%yâ}x{´_SëÒßW¾´ï0Ó€ºØ
:* Õ-ä‘{q0öÔ¿0‹¥9AC¸¼;hðWÉ`å­ÅžÖr.g¾ÚkŠLâ±¨Î|¼§6ô3€nu;™gfgÙ0h‘ƒó(6^c…ì¡G‚	åïénäb4zä½Lu˜=yÝ#¸Dâ» Î0ÚuÞæIü#]d¦óAEv]áÑ^h™ÅsaðXø-«Ïõîö÷{Û§Ý“Ãw{?oñˆ—Ïy©£88\ÖJ53'¬à¬ÓËÈ§{+Žì	3V ››³¼Û;sÆâP€‰:ƒ·:” ËÚFÀPV'{niìœ× –u0)t-£^YØ¿YcaÀ¢Ý‡ 52ðX3rŒ'¬Š`Æq€ÙI|‹ ÿ_ë2x³6=<´àa:¬è¬kSÑñFÆv,×fÖw :JDx³JExHy:9£‰[Á¢'ÅçðŽÏÎˆH“Õ]‡,\¸Mã¨JÙ³%Šú^_ùiúÂMþÝSzJÌ‰œ¤ÛéYÖd)¥ÿ5“½ÿiJIÿ¯#=ýÿ`ÀåæqO›ÈºÔz¹Œ½~1uGf8Ï-ÀË¤XnO¸¾g9‰ˆBÃp"Ö`ëýåÝµÄ¡?#ð©d"VÓ]vwüE¦V…wo7çõ(´>óI~¿uÜyþ‘VÞq®z@ŽºrgããôŸÏÚ¯äîZ/&;¿üJ6â’Ž{Ö¯)Iõ%ýbu²õ¸M’PÀî>ûÒìa”Í¾,ÓÒÀÎ7•9pò¸[¾ÔJU({VXV(0œ­NÓ’¾v9×#+ÿ)rG ª£#¨ÐÆÙ ²c24Éf“¸w0¿[v
Kl¼YvBøJ¼]nÈ±³wœ,oÂX|‰x„ ‘C)ÀîÌ‚m€ÈT{ :‹dD-*ñŽéú,y#øœíÁÄGƒJç2Ù´‘™â}·VnÓòÃþóõMgƒý¬±K n¥ÑÆ\¤Ndµ8c…‡LgÌûU˜M3J&“™ú~© äGÁ“±ú‹AÞ‹+ç82jCPªZqý­Dþ+³f•Ç%âÎþö?$8³‚é©9$¯fG”ï.½lŒ¦Ãáo}4«]’j›þPý/³jÐh“7[{û»;/$ïäb˜ê·»;ê·„y¾¬“ì‘/É_HmÀÌªbkUòñ©'ƒQ(ýöÙšôaõ¥¤wã¨o>_z³ýÍ;´æþ©yŠØ­Þ‰/¿ˆzµ)ô£Mjçò¦Õ¿<™™ÆÁÜx¤ Ýc)Kì-ìßÚ	`ê·‘ßÑÈizV4ÑYå:£@r|\v•|«T#éäoD‹‰çyº‚¹3](dÏ-Å[M‹žÅ%…3=ý:(”çzA¡üQ&”?›[^(4¼(xiiæˆU¨ŠÈ[£*–Â}¶äfJá?[
rÅR³%„¯¾ÖÌŒ¹t"±®Õb³HÂ¶3þ™ì ­ˆkµpGëÖp?a\îÎ©:£Nê2å3¸œT£ï±M?£wûã´“ {Q`l\«±[ðt/edÆ×"Úøã:³óóâeüóÕíÃ‰{$¬Mrå&SÚ÷irÖuÉ·1ÿÄ®¤$“#â—Ôˆ/þ°b¦8kXïlMTÿ:çøCÒ±¦¡Ÿèlì£‹¦ýý­“ÝÎ6ÁÂÖüÆhÛ¤Pq);ùžbVrç%cNx†á$É
xVQ‚aTgöf€‹Æ¼#¢Hq?àå»‘z4žŽù‡é8ÍÌç„œ5±0€Õ¥ÛwcƒM§ÕéÝª3óh¡:àÔÝ ¨œB	î#µ§@œw62ÆÌ´eYãÓ‹Çí|„>\X“ë¸[3ˆi{Ì’°6DÔù–üy‰y7üåÀïl\2§`¤”
ÅcËá+«ù®¶úª¬*©üWEý]U¥Rþ»ŽTÊWþ›Q®ÿCŠE“ý[¤ÁyQ°è*«—âà‡/%^|<ñ!Ï¹“	\_æbåq?¶û‡µ×N(—yì›­LË¤Ô2ëáÚXhÿ¯¨9ýoÅDýï’þ{øôœ]°Bp®¡Fdm7uŠ´~P¢,Â
z3ÁLUÈì&¹Z”»Åd]q®åò±ø›!¦¶™q–”E„Ý$‡{øÏNww7ñ`Sy~×“ŽTü$èw[V›­¶l¨F[ƒÔn¶àO€ûçb‹+WÛÆ‚ý¯˜²–òîÍõrÿ¯#•úÿ¢ÿŸ7d~ªœß€bF­´ xlnmÅ¼Úz8µÊŠ™¯ßëÅ¶{øf5@¿æüÇðÙ«¾Sòé+ì?I.í?×‘R{è‡kcÙõWE3%æÿI’ôrý×‘r^z¤»ïÕTµrý×‘²^q¦¯XÝ,Ïÿµ¤7FÐÆÝ×_SÊû=iŽª•¶±@þ#K²™[]ÓKùïZÒó¬Q4r$±'ú$íÈ%^9aà‘_ðèÿp„™8ä×o±ø¨ò¿ëifÅ ¨Ó€««;L]]|ŽE 8óÚîO¬‹ R9Ú:ù¾óÿm¿`¡®ê‰"v”ÁÞâb;(ÇãÏ¨sžZ5óøó°žØó~Wï*éj5é=!ñÈ èJÂª‹¥©•€/tPV€k.ïãÛxlÒÎúTX&‹ÏWl9û°çkj.¡¦^E8?ð¸_â¤WVþsÉ¾Ë”¡ÿŸ}«mcyþOÖUMÂó8Áòþ_Gšñ‡ö m|ýg”ôßZÒrž6ï×ÆúO“ŒDÿÓ”4™HŠ¤¨åûßZÒJåÙÏ’W¿g«”?ûšw¿g_ñð÷ ýÎ<ýî®g÷{þ{¶ðýïÙ€Ï–||–ä1ßÉÍô‚Ð	ôr8¤#âFñ
¹úÈÍ³Ü{à³»¿æ=›÷œ÷ K&>è=[õ‹ÞÊûË FOQ`µîœ—î`Â­Í¤WsœWã¦#kÜ¤ñ{Œ…³NQPÒL°³œA4wóÕ®ÆUfôI»P{1©0³+Ä¹i¹ï»'[ï²åR¼ÞL^r¿dÊdC×Æe07W.†7)ÇR“’;{Çï¶ò­òÜ´ò{;3¥xî¶ŒY3UÜsø¿Z@‘?ÿøxÔZÍ³(ú¯ÊÆÕªÎÓ­ÆÅÑ_/ŠÐ0*í]þkÆ,ª*®E\²Ð2ú6t­ñ3Íâ“.æÂ6ÓñGf}¹íFLãL,Åç9.‡N`2i) •vG!œQ^$¶K‡^wÐQw›NB”€ RG…¸9ÜÉt„*Ÿ./j±Eô=òo}âûÃ`~©‘_Oü‹±q4ñÇØpã-º²7æg¥ˆà•–v‹6Ðÿ¦!%þM
ý_êÿ®)•ôÿzéÿ9»ëi³ ?O‹†7ÃƒA7a`h‚5!Þþqt 
ÈþÎÞ £'LÿÏ9#.äE,Eq bM=XÓ©GGõgy«±×t ÿs­‰GÎ­ÑˆAc-XS€}a¦ê˜’À5I®èÄå€Jžd…ý}€	¨¡Õ7>i0¢s^ÓÀ9ƒÍmO [£!ìõ¡x0 ;š¢äÏ:©f2¨™o°Q±MÐÉ(”c5p¦ t8ƒl@V1ˆÇ”¿»@&Wt~ÕŒÈ0Æl¯í\ú™`ôòŸö±·sjìû8X }	«w2¡á<Wk¥óíÂFwFxº7á÷1nìƒ sµÝgßþ¤óö×6à'ý#:	üQîÛ¸(3ôÇ¹7¨9^Ÿ±5wTÃ-Ÿ+áOúÖ(òìjã¶¦ÿÐ&ÿév¿ßÒeåËÉÑû«¿w/§×9ý÷i`¶ïDœ?´®Þº?öåæø¼qv~uùó›þµ»õã÷‡»g{ïÏ÷­ÿî^Zï‡ÒdûíÍÍÕ£ÁH×Œ÷ÝÑøíëÆÏ»öß?«8£¶€“Aæ¯h0±Ó[Êœ?Ôr3ËŠá, úÖ§i$ø1(r`ˆ'¬œ<µ¡ïŸ‡gÚ?«Áßƒ°MT 7ÒÁà†f¿ô—ttÀà¢ÿj¥Îò”MmÄŒÜÌæº*=àÖÇ—{¿xïçkÂ›iŸ•šsú0QÄÁõ¯ñõ˜Sc¯Ô=6~øñÓ^C>|ûnüîï?|øñ{z5ýá3µûæ¿~úé§ðÆüyd~ºövvÏN.ö¾þøá_[ïÿ{\}úû¿äíïî7¯Þ6¯[¯?·ïÝï‹ÿpÐü·r,ñccšâsýóÖƒ#[nÎž_x\‡Âi`þ(BÃg ;j§Å%øªÖ€Tso-p5}Q\}éQ#÷©w{™	EBg ktIU³œáœ®à–Ö¢øçÅeÐO}-¸9s>ÐÃŠŒP$ŒGq±OŸk#?x×ó¿ÏŸ2üzË|!ÏPãj0·àtnq¤'¯çNTìØg›Î‘fpr²¸—t±U³æu&*œMC×¿*FÄâKq§hkx`^Xù.Aõûßp‘Ú’ïÕÆù®*’ðþ« üG+å?ëI‘ý'jí= áV
ƒrýÎ
ƒ
·ÚÓaý{†kã&Œž‚#Pì¹˜S³§}Šä{¼LGnB³ÏÐ³€œË0BÛó‡}Œ4Š¥DÖÔKž›™SXnßCJy Àr¼«Ð­)^v‘4©|¥~ ‰‹Û½^ÝÛø”¡0[ÄÀ•LlÜ×aÉT8÷'z’>eØS4@™àãìÖt™ÂÂ³¦Á9‹/ÅƒuòaÀØ&Æj¹Èn¢41`H…‚1òUˆ‰	Â%Í@†LP¬™tf„ Ñ‡ãÖ
7I€³8ÏÆˆÎº bE¼•ê«_”ØRêL·Smøã0
U)‚»jÎ·;°îÔ	qÈJ]©Ëu@y±®ð<Œ‚×-þÆ_]=Çç¢ÏPØ½$THßõ¿ýŒ_œ‹=û3©\7Ð.úç`$¯Çt+’ýÐAŸ#¹²Ýî~½ä²w:è’$%`}o(¦^·ïþ-õº{øæäÃÖñn~ùß1ºUã2ÅÆL­Æ©‚ªñß_›ª Ü›w2Å¼‹«‚R'ïw2¥ÂK·=qi³—ž€	®œÐ)ößš”‚ÅÁR×erÕ€N¤m‘hÇÿÜ–"f­’Š?ìþÔ=9<Þ½#ê}:f@Íú1›¡>z°·ýî‡N5þ•¡VáŸdLßûA˜6Ž*2r‡iÊÈÕL®Âs•l®ÊsÕªÈžvß'Kí„»¦¥ƒÍß£Eú¿¦a¤ïÿºÁßÿ’ÿ[G*Y¾õ²|sv×Ófú"NÌûŸÿÇŸW¶¦ü>› M,²¯­¨ó2a?‘ÛjDP‡uÃô!Ÿ9*žF”y’)_ÄLò¦0e!ëZâ õaÁý 	ÿ9 ãçŠ8kDCªõˆ2hzÈ¶S-¦w \Çbi6-%_²–+êï#*@#J2²*à"E5|}Åð±š¢Ís±¬KÒhÃXïYWí½Ñ±šB#nÃ‹Ô³cÄ¾¯†v¢ž ücjh¯Pó:Æl©87-—®¼X.ÍåZÚ¼ì–ëF¤2wÂÙeOU¦Ä=×qõ ù›Ï2ÚÔãMê8´Å¬÷LP‹BííHw»å êò€Ù9É"Zæµ~Ñ0“óýnƒÌë{ßs¨3zÙ—tbÃuÿ™IôËá6Ap±B}~åìÁiIúÿ^ÀèEUSý_IEý_Y1Ê÷Ÿµ¤’þÿÐÿO_˜ßAd7Ò}BÂ?¯ýKÎEºÿÎºÀs§RøIè‘îR¬•ÁDÿÞmÂ‰’¸äJaàiöþW{|CôPªÙ¡ÝK ¸Ðþ_—ùŸ„÷¿,kåý¿ŽTÞÿë¾ÿ‹w×S¿þ ºªâã"CË4@ÒÇ4l«øú ÀÅ5‡ÒaÊ\1!¾àÇàcýÆÜµ×ÿÄÔ 91Q'[#¸~†(¬hœÊš¸‚ÛúÙçjŠ4,Et«ìo)¢[¯ˆî0Ú!xÊði÷xÔ”‡×-+êZìŒ€—ëÂ1pk‰‚ð©¹A
&%™~>,!ž"‰ëg8uéë	t‰‰jâž§²¦¦¾·Ã4ú™õCâŠ`àÅ2£"qWOž{ Dcþãè(—éáÒ²ôÿ}€èÿYÿoŠ¬ÉåûÿZÒÌúËjO÷Ý³\·‡‚sõà"ýÅLý¿É
ãÿT½äÿÖ’Ê Ok
útË¾ºë·ó[‚ñ[’ï›Ãöq×o\òË¹=Ûïœs¨Ÿv¹9»Üß¥9.ðî×<†kåkùÔb<­ŒÕZšÓŠ‚P9ÜñžÃ‰¼is¸ÂšÇÀÜ•YRÛ`Ie¡˜<£kÀr3 ÔÂ2jÚ«[t–VYïÍÂÂÜ¤ØíŠK1q•¨]4Ü©5oâ_|²BŸÿR¡ú‚'~`ÔÆÇ
ë—cpüyþæ'~Ø—¥ù€ªOúrþM@óµâý‹@+… •[A+ …Á	=Æ…B7qÎtB…Ý$ÕQn¯£°:‘»tò#÷w§À©V_pvÞ#–}‹’ƒ ¿ ª:ÌzŸ‹ñ Šù7¸¹pGóù°¢zTš‰Ñ¡Ëágp"ÎV/.¾Cƒp0ŠŽq±3rg&6™ÃìÔ.žX¬¸ôÔÞabà§©Åsè[ÐáU÷x¥‰R ±’´”ÿ¿‡µÿ6SÐÿWõÒþ{©|ÿ{tÿ´Ç¿¬ðIêlêŽ:þs\%~­†¸Õï/ßWØßòýð–÷ÃØá4±ÛRÍêÈRFáõŽ¶ºÝ‡Ç;_âXVÏ*¼8xübøýêÛ~K\Ÿça
:/^uI.½lL'¸Ï.ÈoPÔ\‡T·j?[µ©ÖªB¦ç]R»"²œQXÃÚˆÈ¯R`Ø×_ §ÏàJú”4ÉßþëTI§C¾ù€ýúM6€ç³ 1È"¿f†§ˆæCƒsNTòŽmqŒtæ £¥ÉÀ"ïÀËVµáÔ8O³0Ê×-°]ã}ÍÂß„Ý»Œú°õ„¶¼ÿíú£¨øž{§*ÂÂ_‡Ì²ŸœŽØö3ºÌ	œb>¤Ûm÷£ciÏÀÖ¿ào±
í#O»»Ç_Èœj[YèX-¨®vZÒ•dÎï’rÖ°ˆòx€1GgiSs\ÏÁíý]^p·Œ?†R¬@ë•ÔÃ1¬Ó“3úýš7=ŒýÒŠM{`Ý1‚ÇCž»Ø8•vL÷L¥RÊýÓŒü'b’ »ïêãëU´±@þ£ª¦–ÊdH²)iåûÿZÒªø´¼€foäM¬ Î'ÄÛ—{Ðq…nð˜Ïóy™LãWûŸ©—Â(€éuY©KZNö2GÄä†“„Æê¾#;þ…5•è+}D¯põ7âBDfQÖp;Üª¸lþ{ì^f©µêQÙzŸ†/7vßm¥ÄÙÆ&©ÂŒ=^¯ú*0ÆÛòv H €ÆT’¼ZÐø+Ç%B/^UOÐcˆ!FáË<ÔˆÛŠš’$W_Å•ƒ`×¿­2PAB}%­Ï(ãyÃI¬xEmXâSM:ŽöâºÕ,OV­T*ã	vhƒ#>ÛÆ5ùË_ƒ_7r“ñm®øQ<Í3ÅqÒâœó9Jæ0-žÎn¾4Ò„¼F¾t4i…Ót~
Áãü¥¥¹ÂœÒ8cPP5:>ìwãƒç°³‚ç¼äãÝ÷£‡Ádª…yØÌ7xŠ×)^-Ûj!¦ˆ™™—Û*âL›+ŸEµÒYëÌÌÓîg8Y`–Nûîý=¤YýO¥POMY—þ§*—úŸkL¥þçºô?çï«Rÿ³$]WØÙRÿóéè*…e”?³þ§ò{ÔÿdGuÔ¿RÿóAõ?•ß“þg¼Ø¥þg©ÿù‡L³üŸÔãGªH®>¨ÿg]6…øÏ
ÿ¬ê%ÿ·ŽTòëâÿæì«?ó7@×*®pÄ\µÄq¶'æù K¦ïÊôMîÍô•ÌÞÓeö
·ÂË¤ä«ˆ°f†1|ÉÜ‹ã‹!&<_F&Ãö¥Š0wbü¢~¦¬_qÊ‚òüß0]§»°€·×Ê0¢ÛšéÿNûydFÐˆ8óÁWò5 #8pc\°hyÎ-Ïº¥ÓñûàÞæfn¿K®L·¥¥ìÿPñm,äÿ„ø¯²d2þÏ0Kþo©´ÿ{tû?Ü]OÛËñxª‰ÛïL˜ŸÔð5Mq¶ÑKçŒå]¢õœS%žµÌDÍÌ4s7Þdpõø8ç¬£WðOáÌšO4òãAb-›d$F~£+¿9C8Ëèjç®pMÆDUê,ÈÚ'¨3,µÑxj¦­Öú¶5¬9âdà]>. 	ôaˆñGûCZ‹µ4¡®o‚î885›žY—Ò¶‡ŽÃÒœq…ý}€	¨± ÷0óQPÊç€Óh:ÀÐ´hm‹nqqŠÏðýSÖ˜}n‚åZyj‡˜ÁTÒ0ŽË¬lá3:Óß$SÊvnö×£á†€w0o#²µ½¿ÀŽ³p&~õW>jÄzÄNÀVÀúpâk°pîN¼Gú×%ÑÖ°œA»úîû>£
U¹®Ô›šT—eU×º\×êMIÿXeö//é„áàí·Är€­¨î Q¦öÇî@«dÞqæNpæø¼‘¨Â{ù±ú-²6þÕK¸\o w½@ûØM8b`›ð›ùÝ9ð7ßÙ äUõQ{TâÐ#àP2ñ+A¢Úb,*-rþ¼iÉøO÷â úQSýOIcþ?S*ù¿u¤’ÿûÄzú`6Âë­œàåÀ*ù¼’ÏûÊÝôôø¼wÖ`H¾üà’º\šOk˜ÏÉÏ[4YÄ‹p?ÐAD{è;ÖQŽ·°5s|FÊü--{†ß
á„°§!yO'0i7˜í.mÞq°/cx‚kbE]ºCcƒÑ¥5¸5+ê5´{=
­ÏÅídÆ¼Ã­îIâßåˆõ‚7»•¨ñ®eÚ²¸}~ŠA©Šd„7€ 5ØpÚ¸	ø NrxçN:‘È+Nâ×"réáOrKò3}Ksy÷Ž9´¤woãïI‘KI€jO,'6Újcê¬a»Öûë7âx’â|[´­áøÌjk›£éàŒÓV7ãšÊæì·(‡ú€Ni~îø0öÇ§#Î,Æò¿g‘uZ~}
—æ!Œ¬!g2o[ C&œžö>õÃ³ÚkôŸô1©ü‘¼KÖOÐ°=íÉ„¢‘¯‡t xðÀÙ^cQîh»ÚE—t¿ßªÉ™NÂþ=÷§aÍöB[
Š>{pB  ûf:
Ûê,bÏjâŠãaÆðP,{{(VŸ¶MÓ4€F½µMúy<ˆ6ê`XÓÙ6rur-×&ôßS¸ç€‘žNàúHg†wéîûh>J…Ô9Îù«ê„ÕwJŒú*Œzxdáë%ô£C>{¸ð¶$¾³|¬›õB¸7r7ô3|ˆ„]¡5×†»ôsD9ÕjtH‘•àX"Æïyž^SP¾ÆBWÂ`ÁÃëyß½¤¢æ}¦6\­pÇ&0›_'Éä5XþÚHßñîÃà	Ùy`a€ñœdGG“…(÷™oÑ}Úœj¾©¿®£äïþo,ù;ú ¬F)Iz‚)•ÿ <ñCdÝsS°²6ùQâøß
pæ:ú1T©Ôÿ^KZ)Ãó€ §+*ÁözÚâžýø¬ žŽ;*#î¦ªÂ3r>)¥œae=fN>z‚³˜—öÈÄ=Kâ4ø3R~ß©šQsVäáÀ¹˜;×½çðÊÿá)|dãÈ±Bç\ ùD^l)=^óßƒ å~äÓ•ãqÇŒ>ZŸ £:ºôîYåRF_9CPEçŽÜyœ;ïº»—°mN€ƒ§°×àøk¿Ý}ò˜×Ñº{Ôñ$tèíp`/üQÃµ@?ÛsÇ |\r-n>ùñÜ?öåø'Hsé¿¶±€þS0æ{Dÿ†¤ý§›j©ÿ¹–TÒ%ýWÒ³ëõÔè¿ýÃ·=´bÁ¹êaêé˜ßÊ™ô3n‚ÜÆdö]æ.÷ÅW¹.^å’tÎ.óÇ>çÊTœæÞÿ¸áVÔÆîÿXþ£—ñŸÖ“Êû¿¼ÿËûv½Êû¿¼ÿÿIÔÿ…C`Õ¬?K‹Þ45òÿ¯kŠ¦"ÿ¯™²\ÞÿëH+>ˆ*ãè‰ú šõ»ë~ÿÂ{‰kÉ[?éoÃñÉ·É›9—üì÷+~Þ¿Úu©<%×>¬»«†ÇDˆ7	§ˆï1·“é5RbÝôÕx½ùþƒ.s0 âQoÿp{kŸ9¿˜àŒÔBòætŸÔ.pïüÓŸX€'uçŒ|Ç"Žp Êw“+0I®5€9Œœ	Óš±oª¤MeSÝÔ6õMcÉIÛ;Ø>Þ}·{p²õ˜sÇéÍ5Î—¢°ùúfþ,E$0ÎÒ¢iyì»y)¥ÿ0šÞÕ0è±GÖzÀõ¬¤EôŸ.+éûÆâ?ÉFéÿ-ie[0O ýŽ@a_‘ˆ©qÒ¬MfÐþVm3Kž+$9
m6È“ÔªKfä)/¹.å©¬Ó¢¥û.ŠÎ‚†Lb8¸†~\8á0öˆ†ÃàQ¬Òad(²[¨«4 éCà¿‰Ï†´;VÔ¨K¢x'³ñL3Ðf‚›FöOä%ëé«:Ùr?ÁdÚ¨›¤?ñá~…ÅÎBq(,T’M=¤Â˜@2ë•ç™ÒÌq½Ëƒ%·3ßƒ©ëg<»ì¤1&áÀnDÃŒþ¿‘k ruÇàóš.OËrS°r8z—ZN8.ßŠU_ÔLÎ»P„J.¬ÑÔÞ
<`•ƒöÇw‡ì¬\ò÷îlå<O~­ìP¾ ÑˆâçÊ^D‰U>X£0èŒhxåOÎëÜ¹AeËé$ŸI*¿DGø¯•“ë1í8$hÍ(ÐqEå-î`öëTƒšœ í¡Êîgê0|œýÖ`(÷ÚûÓ	åòÂþ¸ ,wˆHbñ“Áõ§a—:U’*ÐÌÈµ&îá4OÃ  ¬ÊßøÐýøëîdâOòaÌÑ‘ò+›)ä´;Óa8`öÑÔ<öMþu)Kÿq‰oÏ<½¯Ó7!- ÿ4]IýkŒþ3Ì2þÓzÒó¿°ÍsÎQ¯òä)]‹Î3»ìÉJQ Ù¬EœTÌÓŒ¤d_"­Ãk'f†gŠg:I„Ãat=zØÄk~·—ÔÀ
:[Kˆc>ÿbpóÕîº´×°é®Èµ?Rïš0›qÿ‚¦!RQ„öaaŽ ‘0|Èv€AÎüéÐ%#?ŸŒ(ê©[“k¨n0£¨“Œž \ô!­·•á
¸èý28#´_‡™&u@Œ³Þxâ#.Öy›'g4‹tœP"õ¢o°|ðZX[—Ö`ÈZFãI»Z}Â\ûîï÷¶O»'‡ïö~Þ:Ù;< N…—:òƒ` ÂJdæ„<<ÞÚÞßeï±1/Ä#Òb;ã…ýLY¤ÍxK8K©$5¬ñ8Rÿæ0OwD€Y˜0î[
J€íllÍ C@)ß†£”¶6ñßfVw H %N‘Y…®%žíçö/îL##cŒ¼ýÃéQ<nj$Ó]“W…yšŸ™ÁE ³“Ø¸¸î^Y*‚~óîCþ«@3òáýkëý–ØÑ¼O€Ìäv,+?ü§K‰æÆ´:¸¤ìØš×f„PfwŠšdÞîÉö-ðÞŒ.åÀBÆÖÈŽÏÎ~X¿|
Ü6;Œp\Ù³% àx³­ü4ýGá&ÿî)	Ž³ôtØÕ'Áx…m, ÿ%9²ÿ”5 ûe“éÿ—òßõ¤_vÞîìþZ9¦ÁNaÊŸwßs…¹.ñÿT~y»{°{¼·ýk¥»»}z¼wòSïôÎÅÝnïýÞVïÝOüàéž¡÷£ŽgW¦?Z¦‡KEüÿ
Y–ìÓ0å„ÿW5…íÍ(÷ÿ:ÒCñÿ¥*PA·¤ O[ °Ñþe7ÐmiVÀ^3ÄHT†§’sªÇ˜šÓD0J"~á³ØðßŽ\Æaˆ!¿íOCrò~‡yê]–B„Õt—Ñà]`¿å/ò>Y×¯—¹zã“ü~ë¸óÞNéÊ;©£uåÎÆÇé??žµ?^5È/¹Øb¿’¸¤ãžuàkÊR}I¿X\Š'-`G…²‡Q6SKù²LK;ßTäÀÉHã	qK({VXV(0œÉÓ’¾v9×#+ÿ©Á|QÇ€Ö€ï1˜Ôð³¡I6›Ä½ƒùÝ²SÈXbûðàÍ²ÂWâírCä;{ÇÉò&‚…/‘Œ häPJ°û#s: /8 öÂ6cjé„cz§…“î¹>çC{0ñÑ Ò¹L6íË_³Ms›)»iùaÿùú¦³Á~ÖØ% ·Òhã.RîÄî–¨]vö[Î:Å²Ÿ
æPî—Nfo¯{ò¥BˆëW¸@«¿tªu"ìÖHâéŒEBÄƒjÅõG´Â+á	°á¸ù8ƒüØH
Å…„­~²¯UñD¨
_ëÐƒÙØ¯L)ÜN³¥ 7S
w×l)È…RI±ÁYÑ r½çJöŒPÚ¹½4ßiy8V2SÆV$ýlÙs§=_tPX4SH˜ºä8Jf­?îlôiØc[2ÉôÏx.—¨öP|ƒ/¨cxF‡ã8¦jŽ¤ý}à•;Ûd;Ï’ßØÍªw6ðƒKêßÀfqü¡?éXÓÐO
ƒ±“ï`N’¬€gA†Qq83^|	ÑImmD))“bKrˆ$Z€û¼Ž‡Õtévdˆ|Î¤ÕéÝªS|–ªOèøn „xz)”àn0¸g•:Ð”1ˆËßÙ¸dŒÐ²“©‚?§cŽÓ)¦ùèÌygã‚éFÕð\¸Ø©4IüýFñ's¡Û…è}<å<—Ó³)SÓbO‚éÅãv}%N/.¬ÉuÜ-7€}*¸”¹qƒI€½(ŠÎ˜†_ä1<Š/¾ˆ±¤1¾r1t=üŠƒÉ8¿m8«’1çä?Y/¸*œÁÇ´Hþ¹3ò_Y)å?ëHƒ:‚Ðƒ5ïä^9>D*HWõú\½+z(xìÞ—é¾©Xÿ‹q+/Òÿ—…ø/šj þ¿ª–ñ_Ö’JùïãÊÅ½öÇó.”çEÁÈ¼—âàRüðâà¥Ä‹'>#ä9	)ð	¸¾(Y +Ÿˆû1õØ?¬Åÿä¨GÀcßleZ&ÍÐ¡e¯ºEüŸ¦¨9þO3ÍÒÿÇZÒsvÁòœÝÜ\C•È¤¹zí‚”èÃþÎÖ9‚ó3U!³›äjQ.sEœäêQî± D‰¿¤-X²h´¥7Éáþ³ÓÝÝ%±]dåù]O:RA±›ë;çtÒ–Õf«-ªÑÖ µ›-øà>%í½û§™ý_ïíì¾Ù:Ý?é­‹ÿSLYKù?™ÙÿRéÿw-©´ÿyûŸÜ.{²œß bF­´ zlnmÅ¼Úz8µÊŠ™¯ßëÅ¶²˜Y_sþÏÜÿiTâ•¹€Y$ÿ5ÿÿ¦ŽþÿLC)ïÿµ¤Òÿ¿gÐþÖ+ù.`¾ÂÌ]ÀøYG6y0â-ZY‡ã—df\½l&ðØûwåá¾­õÃú})Æ®Ê¸~Y¢¥{xY
úW:€™»¤ùîÝÙ"0¢hça¼¿fçðh÷`§ÛKLQ;U¶áÐú´ñÉ=—ëÍºÔ“¥QÍz„ÉJžcY<÷Ss‘ü÷t Ý=ÃÌ­ãóUŽc´Ü¥*M(ßqõÕ9—ydï2Bü@hF Ž=¤ë˜±’6Éd3õÿbHhÿeJfÿs-©|¤Ïw;/ªÉì‡'+¨Ù‰„4‚?¾„6gÞˆÀI^g„þyê±ôè¼ªîV\X$×éÀ…}ÄôMøÃŸô+®Ó&IfÅ·?Áj9CøpqÒ·F±oÌ¸¦8DgÔa7p°YÛüólõ\KÎpÛ…ÀqÐIùˆúp×Ï…Ì?ß	òc~e*S™ÊT¦2•©Le*S™ÊT¦2•©Le*S™ÊT¦2•©Le*S™ÊT¦2•©Le*S™ÊT¦2=Ñôÿ¤aÉö ˜ 