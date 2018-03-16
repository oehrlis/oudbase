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
‹ ØÁ«Z ì½ëzÇ•(š¿é§¨@tDhp!)Év(Kˆ„$&¼IIãc9LhmÝ˜n€#s¾óã¼Äù·¿ó(ûQö“œu«[w $Êv2âd,¨Zu[µîkÕYœ´÷™ÖÖÖ¾yøPÑ¿_ó¿kø_ùQë÷7®?øæáƒõoÔÚúúÃoÖ~§~î‰áÏ,Ÿ†L%O£…í Ù`°à{Y‡ù÷ŸäçÎ?õOayÓYÞÊ‡ŸaŒÅç¿ñõ7Ðùo|³þõƒûàüÜ¿ÿàwjí3Ì¥ôó?üüïü¡(pæÃàŽjÞÞ@[Ùéoª•[{’Åa?ÎUçyC=åqå¹ÚŽ.¢Q:GÉTýQÏ&“4›ªÕ§ÛÇuèsFçQÅù4ó<Rj¨o×n¨ç£p:=Ëfççu|Oÿe£0éßú¤÷ÃqÔâŸMå]8ø²3›ÓL¾<žFƒ0QÑ0Åj5òºÊé³VJŸýûT6 ÕKÇÐ»Û§¦÷Ên˜O·†arõŸ^ñöo‡S;¶Û ¿à&GÑEœÇiRj¢¿àf‡³l’æCz
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
´=w«ô™=ðížUœ¿(ÿbdDkúnZ}?^oóûŸ®TjÉe—¬ãjìý|~åøŽ_]x>zÇÑoæÎáfH<·¹>M;ƒïÜM{rãiÌ°O¦²“Ýò•÷Xsúš,ÔkŽ°Æ5³*|JÏ{ºH‚ç>qGÀl@É­?å|æ÷Ÿúi¯ý™‡Xòþ¿—Åï=XûæþšZ[_øð›ß©‡Ÿ{bøó?üý/<ÿÝ­îþq÷³A¼=˜sþëk®ß/œÿÆÃo¾¼ÿö‹ü¨ŠŸçû/Õóî~÷¨³«_>ôP‚"¥ˆ&ùy%o÷jãOê/³$RpØA ÒÂä*‹Ï‡SµºU§Õ³,ŠÔq:˜^b}êgø
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

{U³.&AX«§y×‘jàÛ[JÓàHj²Ý96ž9OîˆÂ­ªô3C~¢8	ÖPêáM`ñ¦gdvÞ'”výÕ¢Þ|²ác½aª½ÙŸÌü‚ªù9x­Y»;ÃÒÆ¼»âáT3ˆ&ð“UÁEä¿g¶ õ„îëx~}7cŠöå;Uí6¹!Ž^³;Þ‚®{hße#»t ZÜ2‹À]=›‰-™f6:7pãþø¡$õz8‚BA\Â¬e	€N+"\H2`*nÔ	Z–à2bƒôâ!%»‡-Î¨ôZ‚Ã™Ä½èuÕÎ±Ú?P¯;GGý“ïÕ³ƒ#üB<?êì5ÔÉýÝýÏ“îþ‰:ìííœœt·ÕÓïƒÎááîÎVçénWív^ãËIÿ¹Õ=<Q¯_t÷Õ‚½sÜUÇ'ì°³¯^íœìì?'€[‡ßí<q¼8ØÝîÑUm:ªÃÎÑÉN÷çñjg»ëÎIÕ:Ç0íšz½sòâàå‰™|pð€|¯þº³¿ÝPÝÔýÏÃ£îñ1L `ïìÁŒ»ðåÎþÖîËm˜KC=û'jwVÍNŽ&m5tœÀßëm½€?;Owvw`¿ðY­g;'û0í]‡g¾õr·s¾<:<8î¶o! ?Ú9þ«‚ÈÆþÇËŽ»0öðÝzËYs Ç„ËUß¼DëÞÝö67ª«¶»Ïº[';¯ºl	Ã¿ÜëÊ~Ÿ Ð ³»«ö»[0ßÎÑ÷ê¸{ôjg‹öá¨{ØÙ9Â]Ú:8:B(ûŒF_·8¸Ü8<vuÔ2SŒ}Ä î+Ä—û»¸GÝÿx	kE,Q>– üÎó£.m´ƒÁë˜žžAÅˆÑ .ð…EŒïÅÔÞÁöÎ3<Aœ­ƒýWÝïwW`Ÿ-ÊvžàÆ<…‰ìÐ|`¸KxnÛ½Îóî±ƒ8f l7Ôñawkïvy«öa­x´ð Q8c„€ÈÉç¼„‹€¸¯ÆÆÏÜÉ®Ú±ËH©vŽƒíÎIGÑŒáß§]l}ÔÝ‡¢;ÖÙÚzy÷[`˜ÍñK¸;û|¸^ºâ;GÛ¾d„·Ï:;»/Šˆ‡#À"HB@ç$¸Åq½àá«g0ÔÖ96å]åïÕ8Š§]hÖÙ~µC×QÆIîÈžÀê‚ì#cß7-~[ŸÄ0x\JRq™Wß#z&#Ž<D¶á÷¦ÈGÚÚýXð¥Xì€“W¸²°Ä7žRº‡(F—l a	ÖÿY@Há¥èìXŽ©7J9[ÞÑ	y€6­³<aþ<Nfñeôø"9s¯°™82˜$õrƒlb¿6Ý™= ¥ð3E·/–u­ø¼¤sžó¡ýyÁï:uh‹8œëD‡–,o„U™@îxä]Ò.í«Ä:œAžœ‰¬ãœòsàÜ©ø_fy!·´!ž‘|Ê5Œ0poHu*~±xøOg³8DÏm¢i”ß“ðâÕ/«ÿ’Öõ#i#ÖÀ êPŒV|Õ©SFò×1;d‡ÎÃ.glzuc¨8Û‚‚ˆœ0{~¯%÷^ÄHþk¦SÕÐ/JL„<J²·®þFêOÍÈ45T–Å,¢&))ul_ÐÕs3SÛ•ž²EÙTë;ÜNê¯k¼9ë¿›S:‘€>Ëâh€”Ð'yë‰T%ÒRÖêV]}‡ÕéžÀ"Õé{OxÜy¯U‡mxÇ½iÞ÷9žj}P\œ7TíQ\(%‡¹§_HÂÏ|¾¡Õ˜’iÁÆQpúÑªŸnZ/k6­ê°ë4oWÑ½ “tHgÉŽ“«Ò¢>ªÅ5ä Zd{dòj±‚ÁÒÆOK¬8íª(yÁæÎ¼”¼Ž#ÖÂ"=\»0XMÖU£Ðáâµ‰lö#ëæ–ºrN-2»—¬²cäC¤¾N§“Ívûòò²užÌZivÞÖáí'0¡†îaÒ[Ú‹ˆ0í$û7?=N5ïÑÎ—¥	VÂ·BÂ	F®ÀÚ\F9qõP‰²¹Æ–†¦rú±•÷#›rGéWZecaØ)Õmäb§nÁ^,\#)«ßÉ¸On|KxÈ¥™iO;Ov_žtw¿w5™Gt¦rœjzúwzñýònË‚+ÞgË:ˆ–G#‡“Þõ&|›MR´±$<r‡ëÝu'›–¥áÕÍä.TæB=?šƒé-ø§_«w3ý‚°sìJH1ŽmK3õÐÁ˜Ž +Yh½ö‘p÷ç/wlõcyÆ&4#[ƒªÀxq–¾«™¸I™2Åšb¨%Á½N¯0¢AìÕöý¢_”Õ)¦õ[ üÜy½°W Óèbe¼šuã›²îXaÅ¼ùñÌøÔý‹Ã/;;ÏJ²„†ˆVm.7¾¼—4XzIÙr¸€Ò“Gº¹ÅÂ€H¸çÃ•Ã&ö]jýEîäJ8t9Ä ±,E?f$Ïz]I²—ý¥¼N¼£´Lž)²ˆg‚†lÎã¶#Š«h*fHy3G€k{ß£K‹p)áøt·Ž[ÁÙÅ0°lžu£„¢°_á­Á’:”qƒÑÃ”Ž…!4•G1Æ J§“áUûrxÕ„mnŽÎ'£Öp:ÁéüîŸñ§ŸöÚGÝÎö^·5î¦1ÖÖÖ¾~ð@á¿ß|ýþ]Ûà¿áçÁÆÃ¯¿Që÷7n|ó`í›ûkjmýþÚÃ¿SkŸi>ÞÏY
L%O£…í Ù`°à{^Œ2ÿþ“üÜQ/·ñá·(8ÁÇžû(‚!ÑVnuòj»	ßw“‹ÿóÿüD-åQN2…Ò—$T™×@ýè$Õ$J.bØOƒ„ô öˆßè;µÓ’Ï6B¾Ñ©¨QgdÆ`¢Zæø"p‚:dX×~Âåá ;ÛÞlH	Ë8ˆ	ƒÐ=
N<i×)ëWº^,À1)Ú¸bPôá#sš§'™'sÚNŸ¦Àë‚Õø³Å4ÍP¼£èn}GàÏÐõN94))T	½šÂ¯0{Û¸­·ÑÛg–[Ž÷ê¨³Õ FÏgXV†ª!uÎ§³ÁÀúÛâÄ”õRÊ(0’N7r|èžFš{j.á7?Í$óÞ½tÖ‡Iµòá½{²-ýšw2ˆÏgRˆJœdÅj–ô†l†ˆ±L‹¸×%H]`pCžÐ,§ž8~˜Sï¾x^J£ +>.R9Ÿ«×±OA‡Ü<ë´DÖyÕÐ¾²KTbiÈ§²'³wêÕÞÿù¿ÿ_˜Îq;í½e8
s£…ùä,ÂSclÊçFŸÆ úüÚUûxšEÓÞÆwÌßKÝ×2h:À)Ý¹
Êt6)—Û ñèôR°Éhƒ†º,™Ý:…§‰Ûq*_á±¶°&GV~Ë"ƒ®½ÔÜõ	lÃçýûßÿŽÓRÚ¿p›ÿÝV?À¿§½~ý¨Ú³µõ6?)Ú.¦šÃ`cmý›æúzsýþéúƒÍo7~«Ð7pt²‰¯³a¢¢ëªøiÕZk]
oÌƒ¶³ÿì@mR "†ÖrVÙ˜‰‡u±îêÂÎ/s~Nº<‘šÃ‹á¿gê»¸¶»ÝÓ§ãî“ÕBx
zÄ¦ÇÎ>¬xËtý¡96ß½8Øs>
Ÿ¿Ü†¿·þúòP>^8Ð’Y4‡•:ú¡5«U’»Æ(5ŸGõeà.æƒ“w¥ñ0ô¾¡â·ZaO]hÎçj[Sš–ÚCGD'ÌÎ©âE‹UºC-û±„L¨Ü7>Û|¹l-©>¹ÂBp-˜³Õ~4Ñ»·¢¿­·–Ñç!ÐP5¹ª‡°›Y—ý²‹rÀhŸ°‡¶êª -Ð#eÂåyªãŒÍ4:oqHu¿@…óeÑá éxg¿°ãHMÅOFI£?†¡üMÇýjÓõÚ²+îå’ÏÂÞÛÙ$¯“¿Z>hÌƒúÔcá D·èÍŠaÍ—KoyuZ²ZaöÕH×Çýþ(ÂS_:öçØé§ »é9ñÉMÕžŽ'%7JÏ‘IW8SBôœÒ­ wñLÕßc¤Ç¿‹ˆß¸ô³ýšg÷î	aâš÷3ÂÒœ³ÉÐÌîËÈÐ»_Ýûrî{jU‹c›*óá‡›êø	Í›öàD;à Ò7ØºÂXE7¼Q)ß ÔRUÒD”œoÂDÖÚ }´ùc/x&ZÀ`ù±RÂ¸@.R€Ä¸ôQŸ`áaÛ\Ûh®}º¾¶ùðÁæÚÃ“GÖ[k­5-‘ÜÊè ¿Ìí¼Ù…ôb<Ý€‹p4‹ò…=^æ:,Êz™.à›T)WÚ\ÉeÕæçqqƒÐÒýù0»Ïç€Xoã5]Ô·{²uºup´dø69qÛ€ÍKÍ›È²¾†—û.íç±	gLCö—B°üÔŸ5ñÈœŸ¡Ø^o¦Á7Á Ã£ƒí—['s÷_Wì¿(ä[‹ŽR@µãËõÖFk½u¿µvÀÏö^;Àoð_:¯:…ù2à<kÿ:aû§þÛõÖ·­µÓõ¯7B:Þ:Ú9<9}öûeÌ›OC‚¾†ÄV×ê±»m‘³Ý,4cŠ9‡Ù¡?äŽX#ãÞìvW÷Zv«z•©ÁG¼ü6U÷»Á=ªîx3°t½7¹}OiŽ  q¼°H,Ü¤#`ç4<£,Eú­•cäýÍ:¢UÇ“ÞúÏÑ:Ýî>ë¼Ü=9u!>]°ûŽ
yRF
äÑ©F›Ûôzøm¼’ú“èÚJÝOœOØ˜ðN·ôKr™‚(oc­uþq%€÷mú÷=íGër>,þ}ÊÏÒyÃéè_Œâ³v ·²`yÀOÅþ:êÇ÷oš‘ý³¦Õw?i¡Øx
ø‡»éJÏ³ÃUüæ=ÂäŠOøŸS dÇ{­ÉÕH° òlüqÆ—£ü>ÍÇ-©][ø^Ø,Ÿ¾@²
ÊC¯ø°¾­`iã°Í$>ÅZ-ü`!&E,¤Ãù¥c*L}ãy¬;N±g¨Ÿé¥Yä™/$•lÑpx©
£‰~ÇÑ*’²úÇ‚ ¡dµ0Õƒæ»ð½˜ ØS…ß>ÙäÉ›ëá7%¥!(:T‹Ú|÷UˆöøXBpGm£Þ[»%‰ƒ¹®sôÀÿ j+ïu³ëHµšúñ¥­JQ‹æ ¡ärÝné¶n+¥ZU-à›h$A2Qo˜ªZ÷èèàX™ÑÑÓAsªì9ˆø¬¤Ï¾•CxÆÎ‰€þ‹=®µ”³„öÊ{M¤ð³Ýƒ­Î.}sºßÁA<jZÃd÷áC×||<ÔÅì×¬Ÿ?Ì0'Åwm˜Ž#}ÑÌwáJ®zKµ{M¡™jg†s¤J½˜­':P;ŸF)û[Ò÷vÐt¬_Ê¿mÕÒ¿²àz¯¥þ‚måP8Í-ŠÁÍÈˆáïg¦vÏ˜W…0Íá*÷\Å§^“@Ù°ð¦H0¬i¼èÊÐmÑ×æ£®Î‡^žU*’l6P59<K£s}É-YÖQçÎ|¡Ñ1á^w²Þ0žFäS‚§WÆ®qO»´ÐØ…Þp›æŽõ\[®Ä0f<ª³œ›JP±q¹V4</¼yËËí¹©R¡bw¤-ÜWakÀ¹œ;NUÏXÛÂ€¶âKp³¤Ú,ÓÀà­lÆoÌ™* .,\#{‡õÙ˜×â„n®Ñ<t¬v¶éoù&?c¢gqs×„ˆ‘êÎÓ¹geãlõîxÓE‚ÖÐÜ†by—BÀ‡;É×P¶/ìƒ=ê	4'â{fK±.á²ÂÒñ´‚àg¡
??«íˆI¶Å a³ü£~.~‚-ùv!êDãÂ%¦IÏ â®Ø½d·[(Ì	¢žz+¶]hl­¿¦¾Ÿ¹•-Z¨]…•Ë§¥™ÊeÒBó¶w¦R¡)ã7Hsòóè¼»Ý9¤â’áßw•©÷•E6ì„Ô™OÔ)+vUÊ N˜êê‰0gS6sôÂkÖA]6œ:î¬þLÞž°ÆPs€”V?ÿúñ&TJ™‹eQÐ¿¥vS[:®´h¿bŒÈÕt8¾*ò/¬X´	c	O-î`µsÕW\¢=tˆÇí¬Ñ_ž‡q½²t†ôÕm-€…wNŸplÎ¤ý•u1ÿƒg`âá1‚—:*nÃh4Q«Ãº­\ÀMcï˜fŸSû)>à,›V´PèM›³M²‰•»UZ[vå©µ¬™[}ü$ÔØÇ2T©ëºåyŠ\1ÍŸ™)l;öFª/dÈŒËòªå†j6–£…¥±ôÔ×^’ ©ipKíaFg9ë7Á´}¦:Ï@••p¤g£è%"¹âN zAOÄœºû¯Ô+ÍŒ„ºC8dþ<§¢>ªÙÚÜ†Õì®’é©M?¬7„¡]'rC­ôúé™YóþYt¹U®ºÂƒL…L¸‹qbóÐU>)“´C÷ÏOÚužcQ-žrÅÐ
Cçv7¢e¦WrÍÛ™õÆâI.œŠnšœjI‚Ä*Oˆmx¦%WÞE–åË¤"¢S€þ®É3$w;õc–‰õ •"±È9V85â^1ô„& eaX‹¿¹ú¨ÍÎ’&O7òwÖû³Àœ«¾,Yê/^³wš»Ïÿ¡9´ c¼9ÐtÛæÓRŸc‰ÀtBå¯ºÒÊ½èîŒˆó¿jÇV¨ƒ€ëÆWè(Œ÷10‹Îé+oÙù
Yðgñ3îbƒ¶‰¶Ó	™7]÷”æÍ—ÕNfñÛ ó ø…;¨ß°zPlã5ÿ§ú<h(¸K‡Ò/EU­ï£Ô­ê³K·Â§*•ÊñîöÎ3B~D›ÅL›øâÀÇOÏqˆÜdzns—¡A…ÂÐpþàA§JG0“ß—	ëÖßf¸J>ëëÐa£uŸ§Pé"®\w•×øÁƒBŸ¿À÷LTu•¡{^-7>£…Æ.G©ˆ)+ÏlGñTÕÂ–œ+Û*qa«•X1~¦žôSšÁöÁ^gg¿bÞ6~<öVf0ÿçg-ë?oð£eB2UM=±¶*¨¡—QÀ`|<d:ð+P íÍS=ÎÏ¨AóØ©š4©x_UM·Ÿxégmš+Y¼’óà£åƒ%wDñÝôf#“ÒòÊ*(FÒ?‹0}O^	O°¶&ÖÈ£Ê¬T²‚tƒj½€gp;rþ‡ÉìÎÆf³Úê¾:c¨Dæ€ÓÝãÀnÌÊ•ì:ß‚2Of`ì|ÒyÊ€_oŸ>ÛÙ­’iõ£àFUÕÔÓ@WÞk9ãºíŸøä²ßš¾#cÛHÌã”Ææñ½‘Èôå,B,o45ˆÃ³²6µåàŽº‡ËæU´Ä-Š†¼%@­o09Åª“¶®ºxRÒDîU‡Uw¼)ž¦\€ûËßf§bkòg#á8NªŽ¾6ÜºÍ/gKUâË¤p––“é#ö(ôë÷¹KíâœúùRÑw¼éöI˜ašOÑxÕðpy›½|6«ÞwëâÁhs“ËO¼N¾•Ÿ³ä¨ÎŠXÔÈHˆUJ<Üs
m³Ñ­¤@FaŽeú¥V•Aq™'!+#Açex¹#;™úNSŠ'þÄ±n)~o($Ùþ¨j]åT÷ÓQ‹Kär†U[Dƒáwtð}„B¥ ›]­Ú§ô.)"´ÒŒ!@£²‹˜sP@ñw7ƒ)¹ŽX}Àš¿»hI¿]0é·ÖgGÏ „çQ?–¤A{=ˆâ¡†câ¹	ülÎŽ ø‚%w,È¹œVƒOœ—˜çŽáƒñ"NçBÄïÒI”ˆ<áÝ¹ôg“Ñ[p[¦ädýê<©»…u®„¾9´J„B?›%\Ø‹ÜpòGi¸ÿý¿,_B®oJ¤K^»2‘Òr:ÑÂÂw»Ýýç'/žÈòé»Ë>üöÜ ecáäœÉ°ùˆÍú=7ö 	ðÆQ%â¾6jåº¨öÂ¿³ÉDrSL¡ý‹1Š’óéÐ¾ JÁM}øò’©:jqÏÿïÿ»·Øoáy4E}k‡³ y{¦§lQ<%¯¥sÿû§CýëóHW÷v£6Ühm¢­.>·Ì ìG,£ßùÄ F5|äIÇ‹ ·)AÖJŸ,éš?-bYÌ?ÞS¬!J%;~¡WPÏì½—‡÷°Ã½íƒ×û÷È´ûS'§pNUÎÎ«&v¤ÊöThÌo¥hFJ®¤
ˆCó›¾ÌRì‡OóÜZèøD
ž¶öóh/	æÒ®Ö‘'Uþ3ÜßS&hÏ8íxÇt+¡‚‚ÊXŠ6´n2îe½f±§p“ÄzØäyIºA»³ÍÄ¶…õÍÒD(pId<½Íó*Í‹Û\Dƒ5‚ˆÁ)æ"…¸	ñ¯O{-=|¥Ey	æ6{ÃÏ&m*“`ñ¹èÈ7‘*“2Øô1}·½s´þ„þÙÐ$q!‚j¤ 4B`ðåS Äg„°˜3RÜiEh‚;ÈK–Ãic³Õ2«å®ê®¶T‡ƒÐi+‘ØIŒœÙj'È#ÒY«P;yŽVÔI<”"öÎfç(G 4t'áæBD9~JÿrM`ýº™©Š¡[É3.ê‡çðïìì.ºÅñ•/,ÇÄ¸U,ƒ“o¶Ûˆ’­sj7jÜ&Añÿoï[·ÛÆ‘÷ïêœ¼FÉŒ“KâU”Ô£þÆ±´§ÛŸe'}I^ Y±,jDÊŽ=}š}Œý÷½ØV 	R”%Ç²Üî&f&#ƒ@áV ª
u{¶Æ4UX­ öªU*}C~ÙôòyvEàÓ³	\Û‘¡H}…Õƒ©ƒƒÐç"Ë½CýTzÅ&.r‘•O:)bâ/ïJ—zU©Æ¡c|‡©k¥´ÅÞôBîf-˜çÂ)qôØn_â„JûUAV=T·ûÿQCÕ„ÿµnè&úÿÑ«ðÿ³ŽTŠÜcÊÏ˜K|ÐÈ{îUi9!D~ÊªGp²=Ñþe:i)ÄKæ<V;çý„ç>ºóØ+ñ8‰í1ãÕàÌ~ˆ6ìÓRfüA¹bÿ¯#™šAë®m¸¶ëxMÃu­ž©Õ–jxMEm˜^Ýè5{ŽFþ«Z›µk¦ÚT¥i–Þ´ê,t½§»šn×ÃsGëõT£)×NlÍLÚpÝž­+u¯¡)´¡›vÓPtj;* Š^§ªê˜-Õvb—V÷lSS›®çÕ›j³é¨žæÚ½`4êõ†£ÙªcIµ…}DÝÔô†í6LÇnê¦ãR×TtGqÝ¦jê®§4tWí5kæõTGÑ·§¹ŠÖèYNCµu[­ë=­NÍ&ŒºiÙžÙl¤ðºu˜-Ï±”z£A=EÓ<OÓ5Çt5Cµi³®YŠ«Û¶ªe—,ãš¥Q7,Í¦Uœ_µéYÍºÚhê^j.AéÙ*@+:¥©Ûz£Ñ„•¡ŽýVW5U“RËVLO…•kÖÍFOª–µ¸k¸ªªjvÃ„Îšª^oØ–ÃhÂô5›Mƒê°Öà‚XdOæ¸uÕ«÷
£1œº­6-ÕvÅÔ\SSl¥	XÙƒ‰IÃÊ7‰»ËŠÎ˜Â¥×VÑ{®«ôWs=¨DÂ†­VÝr”†EmUñz®¥Ï‚’-ñh]oèžgºŠÛpjx–a¨°^uXµn)ÔQuš38WLÚô¨ë¢6ê^³©+°Ö¦cÂÔ›U­7Í¦ªžæå@‘lÿî‚qù“ó•¸7ì®X8 ‹žiÒºã:fÏ¬êhpnÁˆ½gZ¦kÙ†êèÔ3¨šlÖPØvCw]·ÑT-£§:Ž©¨¦× =Å°{ÔIƒ“L758ÇL8Ï ‡à6³88©	ÿŠÙ°<»Þ£ø_+³?Òv§°:¸8.ÌôÎ80€ê0¶zN6hä cf†3–¥ÁEIõš*à¾¡5E­kžB5 m«=Sql2]mBÆ­pV‰‹’nynN	Ïí4<¶kSWM«®Â~R›:­{usvr™I­¢v…Um²hg%îÛ‚9n*‡öàöè9°ñÅSaÉ´z¯n*¥4¤œø~ØEƒ~0ÁiF{ZC¤‚3Ät·îZu6­žbžÝ€öz€ùPvÄueO|ÐSÝ5í:Ü²fO­;=´ç‚ªôêÍžfé¦i4]îÂ^>L­ûÏI¦ÍmRÎâfpÝrL§G¡g@Ç0ÅT×U
_ï •Í€ÙÀ³ØÐtK3\¤ z,LÏ3U‡p©ÂÒÙ¦3o©ô.äuQ!²ë÷z(Ãîz¶Þ´uJqÏŽâÉ›ƒöšfH¦b÷¼†b)Í»€eý¥†^×tì-LB³®À–©ëpôL¸ 8ì¦j{†žXÕ»ÒƒL8.>§èŒBñ`mMq{Ð]®˜žf4áâ·,[ÅÁØŠ­ëF³¾4‚Lœê=Ï¶à_]£hnNÓµÓó,8± “óg!kZN½º¸J›pš{Šaz–Ó`[€÷®çèO^Ãr¼ü‘k¹#×ØZ5¦M‘†kºMÓõžƒ´UCoº®nZF6¾X‘Xér/}2|„j÷àüp58BáÌF²RE"Ð°šMï¸7¿»yóÉn¸®]SíQ¥¡©Z½éš:â?µ]¸ï\  UŠy—mÀ©:Ð’®gS@S›Âá¯¸žªz&Üæ=æÉd TØÅ‰|ÔþÞöîAg·¤Ã¤ÁœÛ6 œmZÃÕ¬^S²Ä³NQuXiê©NT/qš (VæÇ‚ã¿´ÑT¨éže©`¢·ÞðêNÜb$¹ùzæïÂ²¹	ù>Óœ/ÿA~	ù?Õ°€°´€ÿƒRÿ_Ä|èŽaú“óy4ðªÛXÀÿ¦frþ_5ë°{
C„‚ÿ_GzþÆŸ3sôÕHÒ¸8í9y±çµÈ‹•ƒÝ”oax½(ÒúÕÄž@þF:â™ãåëÎ+¨Ó±i}áÄJ´æ&O#oá.É´ßß$«AxC'èz|åF…Ä*O­³Lø¾Å"‘ˆïhÙ9dÒVòÒ§Á+tu yU.ýg(æ ¥²P{×„qíûvns¹éëk¾;HŠWs
à^„Å­Åk:[$úÀ‹M'[’CbV;ÂâVÖ“ÃûpÇF-JFÂÌ2ßêú4L¬ùò`…šsNd¡Càrˆ‹…Ó¥ø	ˆ÷áíÑ~E¯*_ùÒ¾ÃLêa+è¨€bT·GîÅAÀØcüÂ,–æáòî Æ_%ƒ•w¶yZË¸œùZh¯)2‰bÄ¢8óñžØ4ÒÏH ¸ÕUädž™¥;À 	ç"6^c…ì¡G‚	åïéžp1*y/æ<‚î\,ñ‹\ §í*oó$zƒN˜ig|ˆ(Ðž'=ÚK-³x.¿e÷¹ÞÝþ~wû´srønïç-ñò9/u‡K[©¦æ„œuz)|j°·baO˜²ØLÙœeÝÞ1˜3‡LÔ¼ Ô¡XÚ>P C@itî¹5¢±3>\ƒZÚÁ¤Ôµ”zenÿf¤ËvTaà±¦pŒ'­ŠdÆq€éI”|Ë %ÿ_ë2x³6=<´àa:¬è¬kSÙñFÊv,ÓfÚw :JDx³JexHyº£‰[Á¢'ÅçðŽÏÎ¡Éj®C.Ü¡QT¥ôÙ"¢¾WW~šþ#w“÷”ž3"çiãvú_UUIèÃbï†VÐÿëHEÿ?ðDy€y\ÀÓf Ò.µÞ·‚‘×/¦îÈìç¹å x©)ÀíI×÷,'!(4'bF‘Þ_Ö]KúSø¸€O±šî²;¸ä·ä(2±*¼{c¸9¯G¡ý™Oòû­ãö{ô´òŽsÕrÔQÛ§ÿüxÖúxU#¿p×zÙùåW²•t½³6|MHª/É»®Çm’¤N[òÙ—dE63Lø²LK'ÛTäÀÍànù+U©ìYnY©Àp>0´:MJúNÒåLìì'áŽZ ª£-©ÐFÙ ²#24Îf“¸w0¿[NKl¼YvBøJ¼]nÈ±³w/oÌX|<BPË ”`÷GfÁ6€0Õž€Î"Q‹J¼czƒ¾$K^ŸÓ¡]˜x1¨d.ãM+Ìï»µ2›–öŸ¯oÚìg…]p+6à"u…ÕâŒ2ïWb6Ì(žLfêû¥L/‚'cõƒ¬WÎq¤Ô† T¹äù#Zþ+Óf•í×#òÎþö?$8³ƒé©¸$«fG´ïj½¬¦Ãáo}4«\’r‹þPþ/³rPk‘7[{û»;/jµ8ïäb˜ê·»;µò·„y¾¬’
Ü#_’¿Ê€™1”åÖÊäã+RO£Pùí³=éÃê+qïÆ¢o>_öf;ú›whÅû/Réir7¶vvx'¾ü êU¦Ð©œ«›ª¨õTfSpÓ#9èIY"?haÿ†TN S¿~G…Óô´h¬³ÊuFäø¸ì2ùV©B’Éß‹‰çy²‚™3]*äÌ-Å[MŠžE%¥3=ù:È”çzN¡ìQ&•?›[^*4¼(xIiæˆU(ËÈ[£,—Â}¶ä¦Já?[
råR³%¤¯¾“žÖÔŒyt"¶®T"³HÂ¶3þ™ì ”­ˆ+•pGëÖp?a\ÞÎ)»£vâ2å3¸œ”Å÷È¦ŸÑ»±ýqÒ‰I€½È16®TØ-xº
i€Ñµˆ6þø€Îìü¥Á¼xý|uûp¢Ik_¹ñ”ö}@šŒu]ümÌ?±+)ÎäÆˆø%1â‹>¬È€)ÊVÛÃ CU¿Î¹þÐŸ´íièÇÚûè¢iëd·½M°°=$¿1Ú6.”_Ê‰¿'˜ßyñ‡Þ…a8‰³ž•×Ÿ`(ŠãÌ~ÃpÑ˜wD4%*ã| |a7ÆÓ1ÿ0'™ÙœÐ†³&2°¦rûn¬q£é¤:½[uf-Uœº 	•(ÁÝ`$öÔˆóöFÊ˜ù‘¶,k|zñ¸Ð‡{rukq„¶Ç,©kCd}oÉŸ—ø˜wÃ_üöÆå u

¥T8([÷X)_Íwµm,ÐÿÐU]Kä¿:ê˜º®òßu¤Bþû¸òß”rýR,›ìß"ÎŠ‚eWY…8¸?œ8x)ñâã‰ÏyÎLàú2Ï+Ÿˆû±%Ø?¬%¹vB¹ÌcßlEZ&%–Y×ÆBûMÏèkêôßÃ§çì‚•‚Ûp5¢òh»‰ëT¤]ðƒ&>°+èÍ3u)³ç"w‹Éº¢\SäKò±è[CLÇl3ã,)‹»I÷ðŸÎînìÁ¦ôü®')ùqÐï–ª7š-µ®×[¤V£	Ü?+˜oX¹Ú6ìÍR„ÿSpÿuµ°ÿ_K*ôÿEÿ?kÈüT9¿9 ùŒZaðØÜÚŠyµõpj¥3_¿Ö‹l÷ðÍj€~Íùá³W}§dÓWØÖµ°ÿ\GJì¡®e×_Ó4ÃRtÔÿV³Xÿu¤Œ—žiãîû_·t£Xÿu¤´Wœ‡iã+Öß´Šó-iÆÑ´q÷õ7´âþ_Ošã…j¥m,ÿ¨ŠjeÖß4ÌBþ»–ô<mIä‰>E;òH/Žœ0è‘_ðèÿp„™¸ä×o±ø¨ô¿«If©7@P§WWw™ººü‹@qæ106´ÝŸØA©t´uò}ûþÛzÁB]UcEl‘ÁÞâ";(ÇãÏ¨{žX5óø6ó°Ûó~—%ï2i“r9î=!ÑÈ èŠÃªË¥©æ•€/tPV€k.ïãÛxdÒÎú”[&‹ÏWd9ù°çkh.¡¦^F8?ð¸_ò¤—VþsÉ¾‹”¢ÿ%Ÿ}«mcyþO5uýÿÂÏ‚þ_Kšñ‡ö m|ýW/è¿µ¤å<mÞ¯ôŸ¡ÔcýOK1T¢hŠ¦ïkI+•g?‹_ýž­VPþìkÞýž}ÅÃßô;õô—»»žÝïùïÙÂ÷¿gK< >[òðYö	Ç|'7ÓB'ÐËáŽˆ'ârõ‘›g™÷ÀgwÍ{6ï9ï–L~Ð{¶ê½•÷—OQbµîœ—Þ`Â­Í”Wsœ—£¦…5nÜø=ÆÂY'”4ì,cÍÝ|µÊQ•=EÒÊÕ^Œ+ÌÆìÅ
QnRîûÃÎÉÁÖ»t¹Ä/7ƒ—ÁƒÜ/©2éÐµQÌÍ”K…áËqƒÔ¸äÎÞñ»­ƒl«<7)…üÞÎL)žû…-cÚL÷þ¯PäÏ?>µRqá,?£U9Â¸ZåyZ¢å¨8úëEQ F%½Ë~M™E•åµˆJæš@ŠoCÏ1Ó,>ér~ }`3}dÖ—ÛþhÄ4ÎäR|ž£rx áÆ“– ðP9awÂi ò¢ ±:ìuýõ¶é$D	"µ(ÄÍáN¦#TyøtyQ‰´(ÄwáßúÄ÷‡ÁüR#¿2žøc)ãhâ±9à<F[teoÌÏ
Á*-íÿm, ÿ­ºûÿµT(ô¡ÿ»¦TÐÿë¥ÿçì®§Íü<lÞ.Ý„¡	Ö„ô¦ð7 ó¸ èP@öwöÞ =aúîñ O°ùˆ=íÁšN{tT}–µ{Mð?ÏžôÈ¹=1h¬{
°/ìÑCó@¸&ÉxPÁ“¬°¿0´úÆ'F´aÎk¸g°¹)pdk4„½>"`G”á¹@'•ÓR¦5óíá ö *¶:…r¬Î€gÈª@ ƒxLù»ôarE!àW^ÁˆLclÀöÊÞÈ£Ÿ	F/¿ði{;§Æ¾ƒÐ—°z'ŠÎ3µV:ßltwÔŽ¦{~ãÆÞ9ð7WÛ}VòO@:oápmŽÑðpÒ?¢“Àe¾ó2CœÉñ‚ŠÛë3– â*¸å3%üIß	Ï®ö0jk*ñ-òŸNçû-SÕ¾œ½¿ú{çr:ðÜÓŸV3è¨ƒÓ£á‡æÕ[ï§Ã¾ÚŸ×ÎÎ¯.~Ó¿ö¶~üþp÷lïýùñ¾ýßÃÝKûýP™l¿½¹¹ú¡v4™Fý}g4~ûºöó®M§ƒý÷ÏJî¨%ádúK&rzK™ó‡JffY±1œåDß
ò4-‚? Eñ„‚“ç¢2ôýóðlâOûgø{¶ˆôFR ÜÐô—þà’Ž\ô_­UÙBž²©ÜÁÈKm®{ Òn}ìq±÷ó÷~¶Ö(¼™öYù×p¡¹gá Å@\\ÿ
_ÿ‡95¦ÑJ=Ñcã‡?íÕÔÃ·ïÆïþþÃ‡¿§WÓ>S§oýë§Ÿ~
o¬ŸGÖ§ëÞÎîÙÉÅÞ÷Ã?ükëý‚«Oÿ—:¢ýÝýÆÕÛ£óÏÖñuóõAíçñVí]­ó}ýâßÇ?4þ­+üØ˜&ø¤ÿ¼õàH—›³çÒ¡pš˜=ŠPÀðèŽŠäi~	¾ª Õ¼[\M`_ä—@_zÆÈ}êÝ^fB‘Ð™è]RUlw8§+¸å‡ÿ<¿ú©¯×#wÎçzC‘ŠÄ€ñÈ/öéâseä‡ƒÞõüïó§¿Þ2_È3T¸Ì-8›_àéÉë¹9öÂÙ¦s@$œœÌ/Å%]lÕìye‚³ièùWùˆ˜)Î€âmÌ;{ÁÅ¨~ÿî"R[2€á½ÚX ÿ1uM‘Þ5”ÿ…üg=IØ¢ÖÞn…0(Óï´0(w«=mQÖ°Ç`¸6nBñ,@‘çbNÍž^ô)’ïUòv2y1Í>CÏrP,Ãíž?ìc Q$%²§½ø¹™9…•àö{H)Ï 8PŽwº5ÅËNH“ŠWê’±¸-âõêÞÆ§…Ù"þ¨dâà¾!CŒQáÜŸLèyHú”a#LÑ e‚gŒ³cXÓa
Ïžç,¾VÉ‡c›«å!{¸‰ÒÄ€!!
ÆÈW!&Æ7U2}@±fÜ™DŽWX+Ü$zPLãt4#8ëf€ŠÑVª®~Q"H‰3Ýv¹æC.ª<SwÛåŒow`¼©â&PµªVU«€òr]éyž—ÿ¿ºæzŽÏ:DŸ ·{q0¨.¾ë‘ú½8ç{ögR™n '\ôÏ+Áˆ_ÛèV$ý¡>G2e;ý6z!ÉdïµÑ%IBÀú½l ˆzÝ¾oø· èuçðÍÉ‡­ãÝìò~/ÄèVµË7j3µº§
ªF©alªœroÞ}Hë]\å”:y¿“*^zµhè±K›½äŒ!på„v¾ÿÖ¸,–\³Èäªm¡mkÇHÿÜ–"b­âŠ?ìþÔ99<Þ½#ê}:f@Íú1›¡:–z°·ýî‡v9ú•¡–áŸxLßûA˜4Ž*2j›iÊ¨åT®Æsµt®Îsõ²Ìžvß'í„»¦¥ƒÍß£Eú¿V½ž¼ÿ›uþþ_/ø¿u¤‚å[/Ë7gw=m¦Opb½ÿùüyekÀï³	ÒÄ2û÷Ú:ÿ!ö¹A®f€€:´©&ùÌ‰Pþ4¢Ì“Lù"¦Ro
S²®ÅÑ!~ ZÜðŸ0z®È€³‡
T­
FdÈxH é!ÛI´˜Þp7tˆ¥Ù´J¾`-WÔßGT€F”ddTÀE5|}Åð±œ Ís	±¬G’hÃXïY	Wí½Ñ±œ@“#nçÃêÙbßWC;VÏŽþ15´W¨yáGºT”›”KV^.—är-m^vËó©ÌpvØSG™)qÏu`\C=hþæ³Œ6õ8G“:
m1«Á=Ô"W{[è.c÷E¢.‘ž“4¢¥^ë3>ßï6È¬¾÷=‡:£—}I'\—ÑŸqÀX¿n)ÔgWþÁœ–¤ÿï¥¼€þ×t=ÑÿUtÔÿUµzñþ³–TÐÿ¿úÿék ó;ˆì
Ý'$ü³Ú¿ä\¦ûï¬<‡q*´Ÿ.t—"­Þ ú÷nN”<À%W—H³÷¿Þå¢‹jP]a‡v/àBûS•ä
Þÿªj÷ÿ:Rqÿ¯ûþÏß]Oýú—€èªŠ‹mOh€$iØVþõ/ ÀÅ5‡)ÒaÊ\1!¾àGà#ýÆÌµ×ÿÄÔ 91Q%[#¸~†(¬hœÊš¸‚ÛúÙçjŠ4,Dt«ìo!¢[¯ˆîPì<eø´÷xÔ”‡×-+êZìŒ€—ëÀ1pk‰‚ð©xA&%ž~>,!Ÿ"±ëw8õèë	t‰‰j¢ž'²¦¦¾·Ã4ú™õCìŠ`Ð‹dFyâ®ž<÷2@cþãè(éáÒ²ôÿ}€èÿYÿošj¨ÅûÿZÒÌú«zW
÷Ýµ=¯‹‚sýà"ýÍJü¿©ãÿt³àÿÖ’Š Ok
útË¾ºë·ó[‚ñ[’ï›Ãöq×o\òË¹=Ûïœs¨Ÿv¹»Üß£.ðî×<†kåkùÔb<­ŒÕZšÓÁŒF¨‹œ
îxÏáoÚ®´…æ10wå_–Ô6XRÙ@*¦Îè°Ü(=·Œžôê…¥Uä‚Ç»G³°07.v»bÃRL\I”¢³‹†["ñ¢Ö›øäŸ¬Ðç¿t¨¾à‰_(ÚøXâoýjŽ?ïÃŸÒüDû* 4P9çI_Í¾éh¾V¼´–Z»´–ZÌ‘Ôc\(tçN'TÚMj^íö:«#|Ø%“/Üß§Z~Á5ÚyXö-J’þ‚¬ê0ë}.Âóops.àŽæó+aEù.¨ 5¡C‡;ÂOáD”'­^T|‡á`$Žy±S2g&6žÃôÔ.žX¬¸ôÔÞabà§©œE3è›ÓáU÷x¥‰B ±’´”ÿ¿‡µÿ¶4KÒÿ×ÍÂþ{©xÿ{tÿ´Ç¿´ðIâlêŽ:þs\%~­†¸Õï/ÞWØßâýð–÷ÃÈá4±%ÛRÍêÈRFáu¶:‡Ç;_¢XVÏJ¼8xü|øýêÛ~K<Ÿça
Ú/^uIj½¬M'¸Ï.ÈoPT<—”·*?Û•¥Ò,CfÏz¤rETþ8£°†•Q_%À°¯¿@OŸÀ•ô)i¿ýÖ'(“v›|ó ûõ›t ÏfAcE~M/J‚æCƒsNTòŽmqŒtæ¢£¥ÉÀ&íïÀKWuàÔ8O²0Ê×-°=ã}ÍÂß„Ý¹Œú°õ¤¶zþÛóG¢øž{§,ÃÂ_‡Ì²ŸœŽØö—3:Ì	œb>$Ûm÷£aiÍÀÖ¿“ào±
­#O;»Ç_Èœj[ièX-(¯vZ’•dÎî’bÖ°ˆòx€1GgIS=æ¸ž7‚Ûû»¬àn¤XÖ+‰‡cX§'gõû5ozû¥›öÀºc9†<w±q*ì˜î™
¥”û§ù`’ ;ïªãëU´±@þ£ë–‘ÈTƒ(ª¥ÅûÿZÒªø´¬€foÔ›Øœnˆ·/÷ ã1
Üà1Ÿç³2™Æ¯ö5>U;+…Ñ Ó«ªVUŒŒìeŽˆÈ7ÕyGvü{0*ÑWúˆ^âêoÄ¤ˆÌ²¬á2r¸UòØüwÙ½ÌRjUEÙjŸ†/7vßm¥ÄÙÆ&)ÃŒ]^¯ü*0ÆÛòv H €ÚTQk¼ZPû+Ç%R/^•OÐeˆ FáË,TÁí Å€@-EQË¯¢ÊA0ŒêßV¨ ©¾–Ôg”ñ¼á$ŒV¼¢,ñÀ-ÇG{QÝrš'+—J¥ñ;´ÁŸmcAMþò×à×Ìd|›)~MóLq\€¤8ç|Žâ9LŠ'³›-4!¯‘--¦3©pšÌO.xœ¿¤t,W˜SgJªŠ£áÃ~':x;+xÎK>Þ}_<ÆS-ÍÃfJ¸ÁS´NÉœðjÉ|ÜV1EFÈÔ¼ÜVgê@Ú\Éü,ª•ÌZ{fžv?ÃÉ³tòØwïï!Íêj¹zjÚºô?uµÐÿ\c*ô?×¥ÿ9_úŸéºÂÎúŸOGÿSË-£ý™õ?µß£þ';ªEÿ
ýÏÕÿÔ~OúŸÑbúŸ…þç2ÍòJ—©2¹ú þŸMÕ’â?k<þ³nüß:RÁÿ­‹ÿ›³¯þÌß ]«`¸ÂsÕ]ÄQØžˆ#äƒ.˜¾?(Ó7¹7ÓW0{O—ÙËY4Ü
/ã’¯a/f†1|ñÜ‹ã‹ Æ<_J&Åö%Š0wbüD?Ö/¿mAYþo˜¬Ó]XÀÛk¥˜@ÙmMŠôÿ§ý¿<2#hDœùà+ù¿
€œI¸1ÎY´,ç–eÝ’éø}pos3·ßW¤ÛÒRö¨Šx6òRüWU±ÿW·
þo©°ÿ{tû?Ü]OÛËñxª±ÛïT˜ŸÄð5Mq¶ÑKçŒå]¬õœQ%žµLEÍL5s7Þdp!z|‚sVÑ+xŽ§pfÍ'ùñ ±¶Ã2b#¿QŽ•ßœ!œ¥tµ³W¸¦sc¢*udåÔŒ–Êh<5S†Vé}ÇV\y2ð.ç€ú0Äø£ý!­DZšP×w>Aw\œ†ŠCÏìË?iÙ®KÇaaÎ¸Âþ>ÀTX€{˜y”ò9àtàš04-ZÛ¢[\Ü†ò3<Aÿ”fŸc9†Vž:áf°†4Œâã2+[øŒÎô7ÉÅ”²Ý‚›ý5Åh¸!àÌÛˆlmïo°ãlÜŸ±_ý•±±°°>œøÃ
,œ7¤“ï‘þõˆØ¶;h•_Â}ß§¡¨ÐþXV«Zµa(UUÕM³^U«Fµ¡˜ËÌ¾âå%0ü¼ý–Ø.°åt ÊÔþØ½hÏ;ÎÜ	ÎŸ7"Z!¼—Ëß"kã_½„;ÀcðñðFÐ´oÝTƒC!¶	¿™ÿÐƒ ó@^•…°G=Å¿$Š¡-Æ¢Â"çÏ›–Œÿt/p¡ÿ=ÑÿTæÿS³”‚ÿ[G*ø¿ßAü§§Ï¦#¼ÞÊ	^ì‚Ï+ø¼¯ÜMOÏ{g†ä{Àî!©Ã¥ù´‚ùœü¼uAãE¼ÇðD´†¾kåx[£1Çg¤ÌÙÒ²gø­Ng’÷t“v3`ÙîÒæÝû2ö'¸&¶èÒŒ.íáÀ«Ø¢×Ðîõ(´?ç·“ó·º'±—#ÖÞxäV¢Â»–jWdqûüO@)Ëd„7€ ØpÚx1ø …NrxçN:á'ök!\zø“LÇâüTß’\Þ½c-îÝÛè{ÜAäRb €ÚÛ¶ZÁ˜º{Øªtÿú<ž¸8ß-{8>³[Ææhz8ã¶ôÍ¨¦¶9ûMäðAÐ)ÍÎ¿ÆÀþøtÄ™ÅHþ÷LX§e×'wiŽÂÈr&ó¶Š¡1dÂéiíÓQ?<«¼FÿIãÊÉû¨Dný[SÙžL**|=$ÀƒÎö
‹rG[åjÄx¤óýVEMuöï¹?+žØ-%ÈûÜƒèØ7ÓQØÒgñ{V‘W3†‡rÙØCÉ°ú´eYVhÔ[Û¤ŸÇ±Q#À"˜ÎV=S'ÓreBÿ=…{éé®dfx—î¾æ£THÝ3àœ¿¡NX}·À¨¯Â¨‡G¾þ@QÒA_òéÃ}€·5Ð ÙóåcÝ´Â½‘7¸¡Ÿáƒ@v…V<:ìÑÏ‚rªTè"+Á±DŽßó<¹¦ |……®„À‚‡×ó¾zHEÍûL¸ZáŽ`6¿&nœÉk°ýµ‘¾ãÜ‡Á6²óÁÂ £9IŽÆ‘;<î3ß¢346ú:t8Õ|S}]EÉßÿüßHòwôAZB’ôS"ÿ:yâ‡È z5æ¦`em,òÿ¢Eñ¿5àÌMôÿR×•Bÿ{-i¥ÏJ€ž®(G
Ûëi‹{ö£³‚¤x:î¨4Š4¸›¨
ÏÈuø¤r†•õ˜9ùèJÎbj\VÔØ#÷,‰g|PãÏHUø}§jRFÅØý‘„÷>`î\WöžÃ+ÿ‡;¤týñ5#×i”säW ¼ØRz>¼æ¿/Ê5|áÓ•ãqÛíÏÐQmSy÷¬ô)£¯œ!¨¢s#wçÎ»Îî%l›àà)ì58¾$Ä
ÅowŸ<æu´ê]U<	]z;˜ÀTóœÐÏÎÜ1H—\‹[çŸO~4÷}9þ	Ò\úo…m, ÿ4Œù.è¿z]Ñþ3-½Ðÿ\K*è¿‚þ+è¿ÙõzjôßþáÛ.Z±à\u1õtÌoåÔú·FÎnc2ûŽ.3—ûâ«Ü”¯rE9g—ùcŸsEÊOsïÜp+jã÷$ÿ1‹øOëIÅý_ÜÿÅý?»^Åý_Üÿ†$ëÿÂ!°jÖŸ¥Eï?†.üÿ›†fèÈÿ–ª÷ÿ:ÒŠ¢ÒÃx z¢>€f½ ÁîºßÅ¿ðÞ_âÚ_òÖÏ^úÛp@|òòfÎ%?{ÇßýŠŸwÃ¯v]JOÉµëîªáñÒ›‡„SÄï1·“é5R"ÝôÕx½&ùþƒ.s0 âQwÿp{kŸ9¿˜àŒTBòætŸT.pïüÓŸØ€'U÷Œ|Ç"Žp ÚwSK0Iž=€9ŒÜ	Óš±oª”MmSß46ÍÍú’“¶w°}¼ûn÷àdë1çŽÓ›kœ/McóõÍüY$0ÎÒ¢iyì»y)¡ÿ0šÞÕ0è²GÖjÀõ¬¤EôŸ©jÉûÁâ?©õÂÿÿZÒÊ¶`–@û€Â¾"Sá¤Y‹Ì ý­4Úfš<#vH2Úl'¥YU¬*ÉR^jUÉRY§# 6d9JçˆÎ‚†Lb8¸†~\¸á0òˆ†ÃàQ¬’a¤(²[¨«$ éCà¿6‰Î†¤;¶hÔ#¢ÞÉt<Ó´™à¦Âþ‰¼d=}U%[Þ'ØƒLu“ô'>Ü¯°Øi(^……Jrh©0æÂjéyª43FƒCCïò`É­Ô÷`êùÄÏ.;©MƒIm8pjb˜âÿk™„«;Ÿ×Ìi wy2X–™ª€•ÃÑ{ÔvCÀ©pùV<Q}Q38ïB*¹°GS{x+ð€UZÚß²Ÿ³pÁ;Ü»³¥_ð<ùµ´CùF€FÛ ŠŸ+{‚+}°GaÐÑðÊŸœW¹sƒÒV/¤“l&)ý"Žð_K'×cÚpHÐšQ ãŠÒ[ÜÁì×¨4>Ú3ÚC¥ÝÏÔeø8û­ÆPîuö1¦:Êå…ýqNY$î‘äâ'ƒêOÃuÛº¢” ™‘gO¼Ãi8ž†m@@X•¿»þ(ð¡ûÑ×ÝÉÄŸd?Â˜Å‘ò+›)ä´ÛÓa8`öbjû&ÿº”¦ÿ¸Ä·ëžÞ×é›”Ð†©%þ¿FÿÕ­"þÓzÒó¿°ÍsÎQ¯òä)\ËÎ
S»ìÉJQ (lÖÄC '³t'#)Ùá¢uxMàÄ’ðì@ñL'±p`8×c›xÍïö‚XAg+1qìÂÁç_n¾Ú]7ƒö6Ý¹ö§@ê]f3î_Ð$D*J€Ð>,¬BÃÂ 	sÀ‡t´àÌŸ=2òC ñÉˆ¢žº=¹†ºáF 3Š:Éè	ÂCßÑØÒšQ[)®€ï—Á¡ý*Ì4©bœuÇq±ÊÛ<9£i¤ã„hÔß`ùà´°¶/íÁ5(µŒÆ“v)´û„¹öÝßïnŸvNßíý¼u²wx œ
/uäÁ@†0”HÍ	+xx¼µ½¿ËÞc#^ˆG¤Åvã…ýLX¤ÍhK8Kµ©¢ÔìñX¨s˜§;2À4L÷­ ¥ÅÀv¶N¶f€! „oÃÑJÛ›±øo3­;ÄÐb§È¬R×bÏösûu¦–’1Šoÿpz[‚*dº‹aò‚òª0Oó33¸`zkÏÒ+{BeÐoÞ}ˆÀhF^#¼m½ß’;š‚÷	™œÁŽeE£‡ÿd)ÑÜx‚V—”[óÚUcv§¨IÆàížlßéMqi,*0¶°Bv|vFðÃøåk8PàîpØa„ãJŸ- Ç›må§é?r7ùwOIpœ¦ÿÅaWã¶±€þWTaÿ©@ö«Óÿ/ä¿ëI¿ì¼Ý;ØýµtLƒ1œÂ”?ï¾çÛjUáÿ)ýòv÷`÷xoû×Rgwûôxïä§îéœ‹»îû½­î»ŸøÁÓ9=BïGíž=\™þh‘.åñÿ+dýYZ°ÿ­º¥Æü¿nhlÿõbÿ¯#=ÿ_¨åt;G
ð´ Û)í_vs Ý&L{8°öš!G¢J1<¥ŒS=ÆÔœîÄ‚é W’ 84ø…ÏbÃk|;ò‡!7„ü¶?ÉÉûæ©gtYVÓ]Fƒw€ý–”¿Èûx]¿füæêOòû­ãö{{8¥+ï¸PG9ê¨íÓ~<k}¼ª‘_2±Å~%QI×;kÃ×„¥ú’|±Û™><ORÀ…‘²‡"›©¥|Y¦¥“m*ràf$ñ„8‹%•=Ë-+Î††äIIßIºœé‘ýTc¾¨£@kÀ÷ˆ?ŒëxÈŽØÐ8›MâÞÁün9	d,±}xðfÙ	á+ñv¹!Kr„½ãxycÁÂ!#j”’ìþÈÜƒÎÀÎ€½°Í˜Z:!Á˜ÞÀiá&{.‚ÏùÐ.L¼T2—ñ¦ÝÂcùk¶if3¥7-?ì?_ß´7ØÏ
»àVm<ÀEÊxÁÝ"Úeg¿íž1¡S$û)aî å~Édv÷÷:'_J„x~‰$°ú‹A»\%Òn¡3&„ˆ/å’çh‰WÂ`Ãõ²qù)°:‹
I[;ù:d_Ëò‰P–¾V¡³%°_©R¸fKAnªî®ÙR¥âbƒ³¼Aez=Î-ï©´{{i¾!“òp¬¤¦Œ­HòÙvæN{¶è ·hª4uñqÏZÜÞèÓ°Ë¶dœéŸñ\.Qí¢ø,ú_PÇðŒÇQLÕþ6IûûÀ+··Évž=$¿±›;.TmoàT¿ÍâúCÒ¶§¡ÈãÄß'À0œÄYÏÊƒEq83^|	ÑImeD4%.“`K|ˆÄÚ€û¼N«™ÊíÈ |Î$ÕéÝªS|–—ªOèøn ¤xz	”àn0¸g•*Ð”ˆËßÞ¸¤ŒÐvâ©‚?§cŽÓ)¦ÙèÌy{ã‚éFUð\¸È©4‰ýýŠø“™ÐíRô>†ržËéÙ€”‰Çi¹'Áôâq;ƒ¾§öä:ê–À>•Ü†?ÊÜxÁ$À^äEgLÂ/òy_DXR_yº~åÁ¤‰ß6œUÉ˜3òŸ‰¬\îŠàcZ$ÿ…Üù¯ªòŸu¤Á@ÁNèÂš·3¯…DÒUÝ>WïÝû"Ý7åë1NcebàEúÿªÿÅÐë¨ÿ¯ëEü—µ¤Bþû¸ò_y¯ý1ÅÀ|€¥ÁYQ02ï…8¸?¼8x)ñâã‰ÏyNB
|®/JÈÊ'â~L=ökñ?9*ÂðØ7[‘–I3ô_h;«ncÿghz†ÿ3,«ðÿ±–ôœ]°üg77×P%*i¥®^F»àM|ØßÙ:"Gp~b¦.evâ\Cä2WÄq®)r%!Jô­NZ’Å ‹†AûXz“îá?;Ý]ÙE–žßõ¤#%»y¾{N'-Uo4[j]¯·H­Fþ¸OI{ïþifÿW»;»o¶N÷Oºëâÿ4K5þOeö?u¥ðÿ»–TØÿ<ŠýOf—=YÎoŽP>£VX =6·¶b^m=œZiÅÌ×ï‡õâ[YÌ¬¯9ÿgîÿ$*ñÊ\À,’ÿÖ%ÿÿ–‰þÿ¬ºVÜÿkI…ÿ~!Ï ý­Wò=\À|…˜;º€ñÓŽl²`ä[´´Ç/ñÌæ¸zÙŒá±÷ïÒÃ;}É[ë‡õû’]¥pý²DK÷ðþ²ô¯t 3vAóÝ»³y>`dÑÎÃx‘ÌöáÑîÁN§›¢¶ËlÃ¡õií“w®VU¥«ÖµZ9í&-yŽdñÜ3LÅC2ðßÓtKö3·Ž?ÎV9ŽÑö–ª4¡|DÕWç\æ‘½ËHñ ¡8t‘þ­bÆJÚX$ÿQ­ÄÿK]Aû/K±ŠøŸkIÅ#}¶ÛYQMj?<YAÍŽÒHþøbÚœx#'Axúg©ÇÂ£óªº[ò`‘<·öÓ7áÒ/yn‹Ä™%ßù«åáÀÅIßE¾AR_àšâÝQ›ÝÀÁflJðÏ³Õ3-¹ÃmÇA'1ä#êÃ]?2ÿ|'È}ø©HE*R‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠôDÓÿª†ß ˜ 