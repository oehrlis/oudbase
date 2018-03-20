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
# - EOF Script ----------------------------------------------------------
__TARFILE_FOLLOWS__
‹ ªÏ°Z ì½ézÛV–(ÚO±‹VÚ’›ƒ$IÉ±»i‰ŽU¥©EÙîÜ8¥‚HPDLl€”¬²Õßýq_âþ;ß}”ó(çIîšö€¤lËIªÛìêX7ÖžÖ^óZû,NZÿô…?ëëëß>|¨èßGüïúæþW>jãþæÃÍoÜtÿ‘ZßØxøíæ?©‡_z`ø™åÓ0ƒ¡äi´°4ü.ó0ÿþƒ|Î`ÿÓYÿ¦7åÍ|øúX¼ÿ›®? ý°ñàþƒoÀþ?¸¿ùèŸÔúKéó?|ÿïü±…(pæÃàŽjÜÞ dñEØsÕþ¡®žÍò8‰ò\íDÑ(Œ£dªþYug“IšMÕê³î¼Ó£ó(‹â|š…y©Í?ÕÕw7Õ£p:=ËfççuÕ½Œ§²Q˜ôo}Ðá8jògKy'~lÏ¦Ã4“»Óh&ê0f£X­¦Q¾¦rzÖLéÙ¿Meš½towúñ´úmøq'œÚ~7×7¾k®ßon|¿Gq§	ýBc<še“4¸í3Ø:Õíeñdª¦©:àŸa¤âžô"ÅãWa®²h:KT/íG8Ïtåº¿“!ìRÎ0à¯q'£+5Ë£¾¤™Š’‹8KÚ2Xúa:›ª“W;è~¢!`Ó 76œN'ùV«u-gg8÷¯GŽ”0»ß‹{Q¢§ðÃÑ^ã~sý_no3Ò~ÚqÔÇàkE
F‹À«©`Ê°W4!úe”žÓlÇi†ËŽÃ)¶„ÿõ†arå·:À†Úâ“Žã¿s7Ÿ
)zG'èðåÎéñááÉéÎÁ“•÷Î·­F°ezŽç©™fçµkê¼“ôU:øÌ1jPy6šªWáhåŸ8‘àUç¸»{xð¤v±ÑÜlnÖ‚ÃöÑQç`çIíäøe§¦–}î ¢†g£ˆw2†?ÂÉ$Ÿv;OjÏÛ{ÝtegpÐ %àÌt·wNNÚû'+«ˆÇ	Ð
µ²¾œìîìw¶O|RkMÇ“=|¾»Ý®¼÷\·ü×›++µ {Ò>>9}ÑiïtŽŸÔè‰vviå½ÓûµZ}e„Ä+ïeÕ®×‘WîÕ‚ýöî^{gç¸Óí>÷oiÂ±kö†AçøøðøÉzðâ°{sZÐ 6Ÿ¶úÑE+™FêÃ‡¨7LÕ
¶ÁÞÖxE^HÛÀEžÏÛxõ|–ô÷>oÔíÌŒG½ÌÃóhuM½/RÜ8ŸŒÂ+np‹=ãBT%”§G;é~~®j»ÏÕwZ/"ÄOáE¦±úþîàÏÁvç©jì¨ï¿÷wàï_øï# —iÖ'ä©ú¹ª¥ÃªƒA{A¼¾Ìyû¢êíŠC5çõ¬êõÞ0ê½%
E“QÜ#Š5€3mûÑØzØº¥zÉ“8‹zÄöÃf“ÍW¹rÏà‰šÈ#¢7sÞ.í
~à‰Ú]õÞ^zN$l¶zïð$$×Ü.¨ŸàáÆµjœOÕºúù12ü$ÐÓÜEaÒNúÿ>¦FíVÞo^ÓÏÑ˜¯nW ŠÕï¯+z>ˆƒëàV¹_å‰Úg¤bR6Ç$½Œ'_âtÓj¯®ïi~»G/"¾ßøfëÞuòÑDÚðm¤@€Í®à$çê,‚ú¼¦= é°Ôêˆj€„ «P% 9s$Äú\WÀñÌ^Ôà‹ª	>ÙÝïœþìÝîƒ¬¨jÿòÍoÆoú§ß¼Øúfë›nmíñcçÕããù¯&K^&oB¿‡©Ïp^­ÕÜ÷øw¯A³â£_Šò°g1¿F<1÷º¦ž(‘Š‡@7Õ2Ä¢¶Ôò<dÔfL€xxjêÃDÇFèœCó¦wžƒ1Íà(é?óa<˜šo—C<ï4jìö0^k?õºøØ™Ùa.]åƒóš:3-Ï¶Ÿ&Q™&Ýâ¶=}Z5§ßÙêWòæ‹wÛtÙG—	 ¤Š$›¨ÙHà ¦è]<½eYh£«•dÕ„o 6Í××Eª
œµ$X»djÃi”šw`Šj¤ÝT¯A'>Wá8%$¤‡Ùùuä¼©ºp¨fÄÊ¬÷ÒåP$£¦ÛÅæM»Ð€Õ*²òµ›Â¸¾+…˜ ¨‚|’NiCsdc¤Lž´Ÿ]+è
¾··÷:Fš9}Öîzi¯ôõ“GSì=/Âx„Ò¢7Ÿe·ÓÙ¨O¦é¬7d-çå-ûG€¥a_½YyÿâÐ£ÕÔƒtÁÝ_:ßn
\¾Ãjú &õÝ÷,}¿“e°B8œ>IþëKgÃ¯Óîf³$A¹EŒB½t<Üæ'€ëçŽHî@E€òƒegÉÛ$½LTßˆåÓ«	ï_ÎtBKÀj OÀøýeà÷ã<'¡­,¸»‡æ&è[848.YÔ-I"¦¸/`ÉF‘,l,g4¦¾JåšSçáóÃnœåcg›r¦âu££¥v·-+sH@«ðz¾µ }^iTóÆ¿tçxü °»Ø•ä©œj½N†\¸`ÿô§µ‚NõçY>U—a’„*mcŽF©G`þu)Á|)(J#š#¡6°±¶þ\—Ø–?¦ãhœ^€"¡
ÀÔÊ¼jÅ©lìtì5¦ÉØ(•Îúú|[¨ýY„Öa8CiöàÁ³Ù¹MVhžmð›÷š¸ÓUÝ¸mÌ¨~AØ1²Z¿@L‡Ï?ßìÃÖ£Ý$žÆáèól¨ ‰QÝð 8‹LúaCá€¢Zš]ZøÓÍXøó?Æ€6+òŒ&4«Z•…bO!ßÜ0ù êjÆ›áïž?\õáüòGÕè~vèõº±½a_{¸(H5Ÿ@ÐT8ó½pÔÇ"4kæÃ"iQ]@ãƒ(ú°˜;‘…Ñf
jÊâ˜K}»À^CÌ«Ìï­0íá"K’ÿ
'ó?QŽTÿüÏ¸I—ªæØV¼ÉLÏÙU6ÜÝ¾GÂ1‰Ä¼lŒóŸ¬j?Œ?Ù[ààü4'ªæMèÁzmA 4
VÛ1K=â…„AŒ`öþŠ¬”‘êÍ@*MÈ1a¼Q5Y–]ñ”GÓtÈê¿?ÉR<tÈ­EšáÊNÂ`Šv:Ö×äm5¼ˆ·v¶~Ùêle(-µxâ*Ã51d®;¤ÿb­ O8¿ÅkjÿÊE`DÏÃ#Xš<F¼ƒíØî8§Å/º…kJœÓ6[SÇ£½Ýíö	¹EŠ£ê¬ùØXå_õd7ÕÊ=—]‘ih„??¤%ÊVX‚Â‘–EiÞ*nB|ÀBÔSe}›Oÿy#ÀFìÀXùWèiHò’ŠƒŒ‘¥cÅ0Iß›öUú£·rUi°MIÓ•jæ»€°X.¾àœœô9ÌÑ±£™OudŒÛéôäÇ#x7¦jGõH»°†ÓxpU–Â˜S9ìç2‚M¹À‘1\ðGŽ.6ÿ¹Õ¨UZá¯¼“¢_u•÷G¯wdÙ®-þ£0âò;×efìÂûe”¶‹<·¼‘Ç³D]@ÙbuñpÑûÒºÑ`¿{cÅ`ô<IÒÀñdJeé$Ê¦q”ãÈá¯ØÎL‡»sT•‡†Óäà6«§>ZÃÃyçLö¸â°áy®±fá¡+/ó†÷Šl¤Ó°ÿ
ìötèçÀ6Â>ü?ðÂ£ÐËK‹
ÊR#VwóÖ_WZÖ]÷¨ÈÛ¿¤À=Ÿ…½·ðŽÚÝa_Ãx6šÆtcŠªuH3hjÓèÝ•™•ÖûƒÇyëMÒR­Ç×ú Þû´´ƒ¿JË-på§Ô["1çôh„õMÝõ¹e k"Öv‹{¸zr=Œ¬§î–š‰K:ê{ãXÓô¯°× xã¨¶vú¤x½(+¢§©MÏªÎCQC´C²ÊÌo¡Ò‹jïÞNûˆþÓõºþÊ1« »ò>vT±öë¿œ¢³h5¼|«î>ëü°{ðþ¸û¤ö&i¼½ö9ýY{¼ûÃÁ!ÐK`{O6³¾øä!:ã6Ô©Ö_Ûý~ûÔB–±²‰Þ|{ºûæiK½‡	®®ÜçÇž<_8ëÕ5ú‰Þ“fEÏ|ÌPkf¼ÞqÖ+N+ìàÃJöÍ¶±¼•´rEÓ;Ëf@Å)g¡KçIí¸èøýº‹¿Ñ.:fs"¡K8€t™OÀÉsLù<Pß€øqŒ”ªêý¥Œ”²+G‡ á´wöw\Þ8—Í†ýqœÜ€ÏV3×¹{9—ÇzS[´õ•ìö3vþÁf™9XÚÝ>‘cTèäƒs¬ð,mÕÒ_«–žv­ÏÉ·êÿçä M„#<>úœ<Ü¬<(Ÿv86+—ÈGùÍJ”‡¢Ñb¡º»¿HØÿHÉúåñÞ“SnµZh&êž\o²¢î”[UQ#ÛŽq]RE“)ÀèÂN³YâHr|–Ysžepòî@Þ"VNœ˜fÈ	íWüw4<N'3’€Èƒ|E¡®e‘òcÐ×ß—û2»U
Òƒå%…Èl1V™Ïµ¤4~ëîÏùèø"ý-âÿï¯ûí#ÿÿÛGÿÿþ×øÿ_ãóEâÿÿábÿ«âþÍ‰øÇˆû—(ð(³öÊºÂSþ5äÿ¿QÈ¿ºÅ~õ5„Cø¿Pü}­öÉA÷NÌýí…Ü«ßeÌý¯`_Ú¸ò1÷¥àîîSÕ«ï€G7±gWÍê'EØß<¼¾<æ= Œ¢/_]>çíÒôÌÛûa<Rb™ûúŽúþÙîÁŽšOô iæC]æg«}Æ÷êpýµùñúG¯wPÕ¹á>Kzz³¢½	óàÔ÷ÿ@Uì¨}ò‚º°C#ØÀ‘ÕDN¹×i>ó‚*ûù½d hmëš‰Ç-ÅßM€úšð5@}Í øšð›ð	óŽóŸ›p@“ƒý<y	B4rÄ›°¾
I€À&¢ÄRx,°I<·ÙbÕDýB¤âDÖ/#XsP)AT‰ -—)ÆIéN–’¤FB.+AUÄ"àÇºÜ1IX \ Ì'Gåuûø ¡èQ¢Êc¬«3Pìuhun;iªƒì(Ê©|õX±.±¯	_S–¦>œ…½·³I^‘ûpéx€– +’'n)êyrÂ¶Î?È"‚¬§¸Æ.µã½«ƒØ/³xƒØ—g#pl<3¯I”¡§+Köqés`Éþý¦ÁõB—9Ì(1Eš!ÖT*Êñ—Ëx4b:–#â¡Ö^¨Å´Zb÷n@µË{˜^ª15ŠéqÇz
=›70”­`+«—=Õ©ïÝÀã5¯Ù	2ª•ÕÕy§A0¾f["tÕài|ãÚDþ€³~§9L…¹¬5jöb-.à3qÉú—	ÜWÿS#÷õÒ’œñ+Æí+Œí¼¼ ´§A–H‹»6?ÂŸ; ÐDï«ÿáûêã÷Õ-ðÏ‹ÑÇ>°
Ô$“i”©Ñ§d6>ƒ/V2ËY†‘Gê=ŒÂ>´Áæ¡:DŒ$&0‰Ëýy»ð¡âd£¿çhK¢Rkð¿5Öí‡ý·â­…þ¶~Èÿîœ`ý14tÌþ+«Z/Õm? Y0o½©·Þ¨ÖùÚË`[Î5=
§Ã9­n#w 7´+ÕÆÄ²iL¹À «ìµD”QðÕ
EðqAá.ÑÄn_.â~Të8‡ÙÒRÃÕ+ÃÀ™œ,ŸKa+#Å‰j/àOãš;rlðÆmk¦áY¥¸ðbÁxïð´ÎÉ¶Ðc†V)×°lúqwhÞG!>çLTg0,#èòc'ígOÊýT4¤Õ8ÝÛ%S–u÷¯wî*“kÎ„ˆ“µ2cõÕÚ‚Î‚ƒ§5¡µ{S1õ9pžƒÌŠ².¢ïf°;í“öuë&³Ú·f‰¤¹Ø‰Øó§cŽç¥É¬’Ué†kïý†¾xˆ¿´5!B+1ÑŒ‰oÞ{Óz³
ÿ]{ƒ£hÞ[i½ÙhÝ]s)»’Yñrn—©.h×Ù!Ø:Ö|–G‹°ZÞ`~S¿¥¡…#D6ËLÝ­ßUðkšGKúk]Óˆ“ÂUB·Áæôøš ¿Ir!~ØÿÔxŒtµ9s%hÌŒ÷Òt¢R¤÷#2ð}Œ4Á÷M¡çmƒ$s„2üÉÌV8DUÈ¡R†( 8«TvYíðxKýd@þl4à<e½ÈPE ÝÕö·ñÄ]'òhÆ^½+âC¸ºJüË†£âôÒd'3ƒrJˆüû”–Òýñ&ùNÕgß¨8¶ÛÃ:: 2…lâáá9²n\ž£c*+ÍÄÓeó)ª¬°ýç( çÂP}†&ló*2 Øh²žâ'çKÉx>’µ:«þÒ¬dTþ	ô°QÖÛ$]…Á5‰¦RÇÕ¶^ómÔô¯•ÌÇ—Gsñ¥b(~”ºÎl‚Hà°W½¹r.&!Šß©'¯¡=pà°!W¸*8`ÿ1í¹H»í·°{îž)¤ÄEÛ–o¹vOZ¥ùzü ¨ÆD•Ú‰jµå ÞÂKŽ…[åòÆcñ¡?\ Ýà¯L_k„†ßÉÖÙð$\5 Lß:g˜„ƒ¥uáBwK4âS—’’v¬?Eç²ÛÝÇùè‰Êà'¼q1ó[Í™«ÛÊ“fä! 3dT«ÈÕºõIC~Ÿ§éÔÕë›ÈRqîþôÓÖÙ(LÞnýüóÝµ’ $À,_ö»½va®yoÆIo4ëGÏ2Ø Ðw@±öž¨@ÜdíìnëM­þ¦Ö*hÝ=·-ZðmÍ÷sÎ_ûœ"ÈFhÉƒgwÇíú¦`‹hXÄ—îàGoûp¿f±í\·TcÔ‡sÕh˜è4É8¸Q–Ì²N«¦‹yîBc;ˆ *ª{<N-¬ÓðJîþË7³»kM„tÓ%Á[¢ÂN5"U{“”[ª§çÒù”Þ¨xÁÏÂOeRËâI`ŽƒHQ£3wü¦ü¶ÉIs”üSHB¥4Uˆ¨NGr:¯½:7=*âb#V$5©lBIñð4|o.g«'âÐ5îNÊÐƒ’û å£¼¸Ë7<»VŸÓ\	?8}ÝOÕf:þ ‘ê;FŸ[ý©Ò-à~
á	$yüTF‘Ì_”›cA>ë¡Ép ÒÄŒ)‰óaÔŸ…RsòÑ’]?½Lê ’ëó@^§3ã33ŽrèYLeZÎä\Z‘bcŽÍšìù·˜¹¤óXùMò6ï¯kò6ï‹ù?›¾æÿü*Ÿ¯ù?2àRþ9ÿù?b‡øšÿó5ÿçS`}Íÿùâù?hŽ„ñ¿ÜÛ[>|ž‚Þ”g|¶OÐÖù—NçèÉƒ(ìù…Y¼Ž¢·9‹·Q4	à”NPÞ}Rk4ôß‹FÆö+ÛV=…ç_S“n§›_)5iª¾G4üo”¤d²jT{oo^¾Ž™¶ù8GJá‘D»ëîÁöqg¿spÒÞ³PñÇy`ßªï_w:éZ¸ö¬]ºgM¥£¾‰‚4 Ìƒû™Võý³öö_^Ý(;©8,Ä ¾f'ý®ï'ù´|¤¯9H_s~_Y0_søó5‰¨à×¤¯9H_s¾æ }ÍAúšƒô5ékÒ×¤¯9H_s¾æ ý>s¦[o·â­ñÖ`«ó%r¦kŠ]•9:o×¹ªý5ò—(ãˆí©¿RÆQ¨@$ˆÇáˆ¯r&qyÞ†ŠÎ›ð_´¿ê+0ð·ëÂ5´h_3u¾fê|ÍÔùï›©ãdgÜ$SGâ½å-Ê-Ñ‚æF’à¸‰
Â[˜¢J8BŸªóÕáþ^£š^¿cÄÙ0GçØl”ª‡Ú¤˜×§èw:8t¬á/A†?ÜÛ±?¬®¼·¯B	âSqît;€|Üé)t
/)ï-õèEŒèìÃ.½l‡Pñ²¿I;¥9ã6ÑDýA„¹<°_/†11À¶gÙ¹„´dw„ÙŸÒoŸ³U(´î˜…”­yéLŸ–²%+ñß"i«D]¿&#ÍKF²®cJF²²¡IF²-ô…].¦|\*’ë&©HNû›§"9/9†îR*ÒÒ±T§"UA_šŠ$H¬#¥LÛÊì#§‡Ï>*Ëö,ã
at}¼¡$ê;Øês×¿U¢ëŸ´#e0vÌËRsR`~{]bDó®r6eabŽŒ·*)GÀGTÇ[I¶Œ–®ñÜ`)n2ê•÷þX\oŽ›ùRlUNHóóXJo,Í|ñ³^Ä“€$AÛi2ˆÏ+HÃÒméÞ´ÓMÔn †jý½w1¸É·Ü|$î¡9=ÿ;SÈíÃƒçsÓé²2‡¨¸”nûùÍ«—LßÅªñrÞ]LUkV|õöo	ç%slƒ01Õ ¾=XûmVpq¢HÎaŸŸkµ4ÏÊÙ1É²¸…,«›gXÍ’žUR»J¤úü$ªN ú5’§n–8%ë÷É‰S7OššçE¯X„ÊM—UØËölšbÌ{/„f¤,	öÝÍ1h1B6—¬kÒX±“Õl¨ V}ÂæË}ö#Wª¸Q_Zaö´½òžgcÕÈªÉU¢÷êGæ²¤îéPv”åq—]HÄtðG»ÇæÛ>&‘MFwû‰lë¿R"Û×Ï'}¼«¸¿P‹óÿ=ØxhîÿúöÝÿuÿÁƒo¿æÿýŸ¯ù2àbþŸˆßuîÛô¨VFôk{NÁÆ÷5ð÷•(Sva_…YŒ!WŸ1…º\ŠlrœxUÜ¹ÓA¹ŽTó6ÃvKéb[üØ›¯Ü«¯Ä>…¶DÔ¡Ðê·
ú;Á©¡}¡ûâ´{øòx»óÓúÏ×µµšz¬&—}PEáO8½gy:šM#¶o‚\ÈÈ°Ï¥¸j¦¤Ï€e_ì%v:ÏÛ/÷ð¢Û®€BþAÎ"¬ÑuÀ5¯HtN#–®üVž³QÚ9>a§iwÿtçT
¯ß~Š‡ÕošËv{Ïm5J{è}šÓæ€”çà´BŸ,·Š¦½¹­PiÒ}žÏmuÒÙ?ÚkŸtºÒv'øaß8:>Üy¹}âÎb’¥ýYoê@e-?I“ÁørP®¹ÑzRjø|ÿõ‚Æl§9î±f÷‡'5&ÿ§= M4èÔ‚"@Üc<äüt†;q=ÿg½	××.R:ý(&âô·>Qþ0œo['(ëúFÍ+¦æ¼)°žX°ÔÅ¼¶4±'ndØ’…©õE ªáNhgl„"vŒ}Ò™n*#°úÒHL‹,Þ02Œ!ÍçýV=HÓUÛ…ˆììZ®®v°¥`¶h.mNW{>ÎŽyÍ€bìÍ»ûá4tWãžØv©8ÛQ»vÀã¼ÇpõÆ@Ðh–ž	LûÀ8k8²Â_ÚÄ^=Œ1ð‰§]/…[¤ÀÑ|â[^–/“\¼Oh¼ÿlø
2ío†>ÛCŒ
®ÚKÕì)Åo¥=v:.‘KoT:éN×§Œ¶Cýäs;õh®ÓñŸÛ¯ÚºKó÷GvöKxòÒ"å(8–õ{¾Où	ù“õ 
¿Ð4œj88m¶øl).¸Å(äéôªTîurrò#:RdÖ`ð„Òm¡çå°$&e9zõf4„–Hó"	X;¾*’­òwùÌAIb¹-DžÍyŸ£•²3»íÈhoLU‰8oædâðø²h:Ëµ!LÄŒÑ$ÔâD´7#5?J<AÕˆÄdèÁqFÕ3«w†tlaR(‰¡5®4kãÜrL>GjgùÔÁ­zÎ.c`IY„Ðã©ÓÔÂHÍÈ‰Ô¤AZÝ~ÕÙ9Eà€ÇøÏµ[Åp¼VeÃ³À~c':ÞKPADÌù×g¦W°Xžƒ…9æƒÅ—/#š8Ì£V5A°~C©FÝ×.CùÑ’‘YÇêÁTqÔËv(¼þ°Èn0–ü)—iºá›ž@r­J"Çµªð¡‰7UN²€‰árâk6€ã¡“áæâSæ:Í‰™±ñ’Á_©03“ÀL 3v<›§z5H×PZù aÔ}dþž†gfˆ^f=‹.ÓÍžÁX†¾šv“£ÝõÜšå)§Eåé`Š¥o%ÆÔ•ý5o¡ne	FÀ_ó*6T¾Ð—†¯I=»c,Ii8Eýa~D÷Ò¸ìâÁôZò˜¥%Ÿ›©;”Xn3.¹÷‘aæŸ9.½Rü«U…]`¸ÛÜr¨h<™^y¡s…¨Þ²œÁ=LQXLETñ"¤½ n'Ö*¯ŠEóx§•0(ˆ!L®|šTÑBWƒ¸Õ°öZÍHŸÕ~¶,˜½°	ês£ÛÌ¦.‚Ÿ;ÆO³Î°v,s0ò;¸SÂMÕç}%Â¸êwážîuå 6…§ËLÌA¾œƒ}™¼ûhœ›‡okŸŠg·c„_ZÊ¸õlWvó©¿“°Î()Ö<ü»ã…Ýj(UÔ–V~¯ƒ¬Ænÿ†(€‡#àÇ€õ®9
8wÄ¡ÕvOé°ÂŠÃÔ`*¦†Þ›„:³UÓ¯Ì‚éy  k¼ŸQèŽ¯>k UlÙ…¸qí†8|~Þæï²<ž©‚!%Õþ¾è®üÓòûRCËGDtƒ2±ø6]l¸'áöL†wvOuÝ•ô­WÑe~§ûþÑJKöd°µX¸ú|9nßéý_ÿÕò;ýL»ç˜J¢S6q§ÛéÜd”2Â>lÌ¯9<´~ÄðdßG·7@WŒ@ŒàZµFj[2­iæoõ•Ôù@Æ‰ê(xæõ4{£è”,¹Õ@¸Ûz("³£Q“œ‘ ³ãÏÃy—±[
ŒA<ª­R˜bå/p¸«+v•×Joò^)ïýCž,½­œ­ùyN]¦Òž»¼¾á™,Êhzo§}¤Ž+g(˜¦R”¹©i×o+MO»Ý½Ró6zz«›“ñ¡ôÂq4ÅâÍ‘×ôÇ£8×¿ÊLot„]íÐ¿)EJ¹CÁp­VK.Ù¢îPOÍÇ¥ñ½899RþgÞT°i·²©Š¼•sE¦òÏb>>»œMÊ¬Òå’ÂNÓ¶<ØüÕ[f–¼R¸Ýœ>„çœ–VJ·àò:‹nšàÉ®×Ú™j”Ÿ•¾V}j¾‚17Ï?w´I &NÆ3Ò^ÓÆžÓùö}Y„>`%
ÕØpÊI<XóÀ}: Mbî§»¿ærGÏ­õ© Íùqž2¥2ù:·ýÜ˜øx¦)‰Zèûa¯[+ñ‚ÚtU Šj¬À	Àždq2¨»ß4æê›ÆÆ&þ÷ýù ÿ›£:Xž‘˜…×©7Þpj+«¿¤qrzv¥ZÐ‘ãZþE$1"_¯QáŸ1;ê­=—_ŠŠ9»ù^IÙ¹hÀZØ7ç²¥k¬…»eb¦…~PÓ!1FôµXŽqóØîÊ*¿·:,¨*2‡Œñéº¿ø{‹ú)ÍÎ›)ºòfeQÖ¤H#S‘­K?Ìy»ÑÃ<gŽ×jÍFá—_"†Mc¿;›Ü}LG@¾cô?<ÄkŸ+ŒÜÂª$y#…“þïnÞÕÔçÖæ}9Ê»ý.yË“Vhd(8'ÞIw•ž’àbN;–¥Ì');EÀjAz2·|î?ö<wIk{²²áó F¶@Åw¸jŽDÊŸ;íïo
ÎãdV9JÔÜ$*/tÈÄÇú/ßàB.S€€–¦2\ øñÐRnBG,Þÿ¦:EhÖŽÞ¡¢OGWd6u^*çl2èœ¯¥}äl~Í™”ó¸h¥805o6—j¼ZwÀþ		lR¹!Ñ`mã÷O.t¸ðÇK´f…¡TîdÙU´Eé§Ý ¤‘¨»-²Ù‚rj¸Æuš$$f´ê­¿®´&wõŒRÐÏ½Áy½GQB·Šf€ÎOwÑ=—ú”N°¿”Ò|›½‰¶äõØýÂ]wŽŒ6e dÖ¾#—¤JGs }Yå`ÙÍ	ÔU:Ëø¼5oB îhE7„ã6·¤òr2
eÙP$™vþÉ‹»Žvšåø8J¤Ó^ZB›ûßý©ºã‰Ñ°í£ûæ´¥~¯ÿ„¶ßýÉƒûé„øóHUÅ5´eûîãná­¢½°da+´u†•vQ§}Ñ6:Ç0ê¼Q4Ž–,£_f¿4³›M° Û©Ø£J¦£‰!3¿-G³ŒY<æTT&`s­L¢¿Ä—½"~®QÝ²=Yˆ¸ÇªÖ*¼Øê½ySxÄ†å-ƒŸ[æmœÚZñ—¥æÎm¹`ÌHöûÅ™pi‰J@ö½[ñÓ§óÆ\¦Ö_PšKNMû
.‰2ï0øºõ[Ëö¢ä|:dÛÎÆúuð‡àwÔ/BÊgYTÇ’Â¢ôFô†	jÖëÒ0Çdex3Ä=pÍØõÿ {~ü˜ºÅUÓ¦]àJÁÓlyöêü	Wƒ¡hýYœØõhRCOÕÚÿ+lü}½ñ§<ÄLD,0fÇôA±Á6Q¾ù~'Ç[I"§ù?ÿ3 `N|êÞO úç{þ#èªøº†GêçwÝä>ž ú¶ˆƒd„ürî“a4ªp x±ÔD'R¹eooH†=-?	Z-ÐöZ¶sðêÓS„}° ²¼ìžîcŠÕW¢Ï@ÿy#i…×ö%ŸÙ—üç…—Lx¬óyâÄÝ~~s
®hŽÏÍ=ƒ¾ÓÜ{~ïØô	Xæy¡½9/NC?/4w“BÝæÎóê7t.Vñý¼q^»[~Ï›Êß‚PìÉápÞÎóò+¾¯Æ¾â?_ÐUá½ÓE»SÒÒ«Þ«˜rdUø<OLESfäå¦ü¼êàöU°ñyUs*›Ãs¯¹KEôÝ¬íQæŸFGì(¤è/×Fè+bA8N„Ÿµ´hàõMŠÄ›a[’¢®a“|qÙ7³ûa®D¡V]YdÍ‘úw–þ@9L6§}R˜`lKÜ UÀ‚òÒWáéÌ}›.îô\÷¤(c”qð“8‚lj¬f$fqòÑwPXó8ÄÐ‘›„.(úçìûrËqÕ°ˆi@[K{[Dd…"/åB2]ª2Ó{ùŠëÏC^„ÈòÕ|ÇÉewð·]FYŠ¦Ò b»±SÇ«¢•Ä.z	D'jK’“*ˆNí½Ý¶¹VÚS 2ŒBb•óÕæ½µ'«wkðjkÍ{­¬¬„‡…){s.ŒÕ;cåÃ*CY0k+­7›­»PÞË_[òùXK‡¸µaû¿áZÙµ
GÓÊ{šTÑ…ŸšíEä DÈ‘…Xày®¿˜&£íeÏõŸáf z4¢r«·í£æ¢»Ïñ:ŽÚc¾Xñ±®ïÁ“/4é¨Î5ÅCƒp_Ø‚) åm°AþÚ¼åu@*büÞÚ¶~f0çñ¦ã°Çš/îKs-pžµÔ{y^DäVþG£(3_MÊ­ƒÇÞp
Ã½Ù€
/ÝÒ¶Óñ8MŽ€x=Yñ§|‡Ô $½¤vÇQÂÀ“ZÍyîÈŸªæugÅB—9VÍýçŸ¡YI
ªù´7¬«q&9+ç=à1™Âz³L½v¹ÙÐqžâíŸH<FXAL­fQÖó^vHœ]§V3z'Íè±.èÅ
Þß†Üeœ:s }Ób‹ë³¢1C¿Ïô¿ñwµÂKZ­3ëån6D"ÙF-V²Zr2¢í×™íG«VîÿÞÚP6*îv–Â"¯Â¾˜å›íòéqÈ Z†€.FË3, €O9¯ƒyfSêò–°Æ"Løs’&§	µxžf—aÖ—=[Œyz¸q8„|cÉøÑˆÀá•ëðîPN‹ìOâìE¡ó3§ÛòÂÖÁmìFÜ zM¦Y¨ò–m£t£pTîç½dkÃgœÂ4^ÜæMx·x˜{s›öTÞ0ßT—þÂ…þsåXOÞË(ŠÞ8K>°Î9½u#4'o%Ñ¥'gÏ»UéPª|ŸvOŽoqéAÇ^®yàJ¹…ïÝN®ÝÎJ©K^¨Ž<]òÒýÂKÚÑ¼äµB¸¬8Q—¼ôpA4ë’Wo=jµ€ˆ˜^p±Å‰Š»M,jÞÜ#SD€…Q©ó\~ŸÍ¶¨ãR<íüŽç$òT*bcŠ 6Ð^åC¿@D±ÃÀ5
nž·ÌýA|fæ­?:±Ò¦"U¤[YÕÂ_mÅÒ©sîkuœØóœàóîó\áÅç>&9ÜÏ)v³xO[•ø~Ç«œP¶ëÂ_‘z?ªŠ‚•7ü6ÆÀpåz,ÇiFmÈCåÞ6f•Ü¹@eF[a%'%GŸo9Ñç[^ôù–µRâßE2Š÷+÷«^ªöoªšpÈ
n^ÌWIîÁã;l©P|Eöº
I+-tm/Í­ßRvÄzÕ{òÊ6(s7‚_µEUÄHL¥¶KRÔådn-™lù[8–¿Ÿ³õ›[¤Ö¿	Ö~9DENüq§}¢/­¥b
)ð`$%ªëPðÒ^>v\›LaøYwàÝ’î`«©Ð4T±"Þ^jñ>í],~ûI/bmÝÒ‹º@Å×´\m¨Y@mg¿ñ3
ÞšÙ?|WÏòazýß(©™Ÿô¼qÈ@/2µÏ…n3¤«Óª?ien’}­>ye~Û}_VgvC ~M?Tï±ä_ð1:Z©tàÒJj¦ºóÖÜ(ñ³8Ùòç´åÖl”ßu©ÃÓín}À·7Ør:Ùo¾ºƒX9å¡Ý’säº–ü,¢BVå‡YÆS·:h±h´iaµh·ÆK±NàçŒ¦ kÙ ŠÍMO4wâÕ<È|:l1?*à75åÊŠê‹
P0
ÙÛ;·ŽÞ’%-·s
öTWÎ’¡Î}ß§ &¦£Çn•>³¾Ý³Šóå_Œ€hNßM«ÏÇë¾Úó£Á•*9 ì”ucœí‚µŸï·¯ÜßÁ«‹ìÎGïx úÍÜ1Ü‰ç6×»iGð½»hOo<Œ9ÖâÁT¾d—|å=–n¾&õº#¬qé©Ê:Y„ÒÝy÷<IðÜÛë˜¹Õ[º‚ßú¶£¯Ÿâ§ŸöZ_ºÅ÷ñ}Yúþ¯G7ÕúÆÆÃGÿI=üÒÃÏÿðû¿pÿ÷v·;ÝÎëƒ.y{0gÿ7Ö<Ü¸_ØÿÍ‡ß>úzÿÛ¯ñQŸ^ª:ãöž:zùÐC	Š”½äóJâ ï×ÕæŸÔŸgI¤6a³ƒ „«ÉUŸ§ju{ªçY©n:˜^bUìçx&¥Õ)õšê{©5ÈÍ4;o=Tç"Ê®0ú#ÎñfÊq<E[è&W$+ö1Á5>Ãh{ðP6ž`pŽE…7G|ó˜”Ÿ!g¬+hÏa‹M›ø“p4J/£~3˜7]úeQ8[€8H«FÁª#u4;ƒÞô]g7¹8Šê4âQD•¯ù7`ÏA®§BõñÕÛ8éSt&H˜oó¦îDÞÊå¾2¼çµüî³Y°$?¿LÅÇûQŸã¥ x³fÊ„—á§âÀ0ò¡†ÄÑœ$çò”zv…ÖQ¼›oZ¦Kg'Ó(éó>ÏÂ,„ïQ±Ç Ô#rHX)Í?Äb1çY8n4¦©MòQt£]EàìÒ…ô ­ ³ ÁÐ_SRP´ õf\©=X0'³ä)– ÎÌÊ?Æ±„“É(FÅë›Ã¼°ú3ï.ÆvE¤&âÒŸ]ÑCº]Çøc:Ã°(‚„¿!Z-™SHSÂ„×®€,O¢ð-WÀŒ§Ž?áü2¼œ"¥±$2¯9^ö:&YŒ9ÁêÀWÏÖÇå-=ÅIÁÐŠþÁuuPÈ9‰| KãS«²ÝxÙ0¢?@£  Õeœ×ê¦ÍŠ0QÄô^Úè>Šê
Ð¡¥ƒËC˜§Î«ØÆAcÓ=¼Ž»cëñèH‚¡€Æi×›#µÜ[6ÒpûL8ƒµKù|¦øê#Åhßˆìå´IÄk8É¢ŠGÌ¯(GW¸G8	†É/â8Ãü­üD§“œ|'³nÕ$º ;âÆcCÜ” eÓb
±ªBŸÅ£xó€Ø¨r—ÜUªc÷ñ 1¾%·Êð`Xø'í"š#­Ìs¼ð]8žŒ î¢ä³ÞÐžxXº!‡rcñZ:ÝjÉdÇ˜í…Š8*Üri L “iÎ3Â[e\y	±úròPÅñæ:tuÝ:pPWË`%Àiº˜AåC@ÂlAà[¹ÊiˆW!ük4¡u’ëQ5h B”˜ÐíU¡G(N/S¼†t’o«k
oOÍ¦Äk˜÷ââx›‹˜½º¹k$‚ñ	“þà<¾Ðx7ŠÎ8×Í‰ÇÛ­»;àZDQÌ®séj=«»l×a’wWO‡è/M¦Ø:™ýÃ:HÜ½YÄìˆg†¼äŠPFíQ—&w|èÇäŸ:L§9ì±í=«qÉzåæPË€Î"@Šì-U¬$Ã¡Î»ÈÃŠ‰>ƒ0Îùòl¹#'œÊÚôÉÕ—Dé,]gà‘ º#9ˆáÓ­[—®ƒ_zT©ÏK…tÁ;>”2Bx>²Y”§Q8ÜøBÜ'Ü‚CŽðb×ó!5‡Él â‚,J—§De§Ãb#ÏDñ	oü@Ú	‡-_ŒŠ $Œ‘z“d'>QA™™–©ü
P™.
 2œ›Ä’†3<i¯7ËÈÅIÆ‹I—D²hÒ pì×ÞBb÷(ºz‚"`ø—ŒW|÷-²öY‚«:™¢%Ï'­—³;»¸ :FQŠÈ|:)fB–Æ"Á×Ž—j“²Nhf‰Â¯FÊgghŸÁŠá´Ê"KÈ¥Ÿ4ü½O¹,t‘@ôÅ- “»n‰$¦$ô²¬ 3Ü]ƒ{ë²#¯ÒÜŠÉM°³PE'<Np|u¡€®É6.ætHK\'i*#’y
Nðg¤{X8¢$(m†%ù[7§©7Õ¤„ìZ8{Â†•ý8?Å™Æ„“tèq–³¸OH“æBáû)±g:èh^¤1Ç0ë˜é>"iÆõ€XÔ£b©ÞLœnÉ
ˆ‹ 	hkS)F´4 sE j^5ER`I ÷Ë’# Ü3MÝœB!*t/3­‡‘t×Uc1š‚ ¹ð’¸°¼Ç
èJ¯	Ê—L.¡æJÜùºÐIçx¿«Ú;Xig÷d÷ð ‹×›˜s'Ü#½_;qxLÅSÚ_}Šî›s4W
g@F«¬±ÀÍ™†ß5Fñ[¼yáRè:‹ÔÐ‘¯[¤ÙÔ…´ 
Fãi†Ž „ù[3îÔ=ZhwØ(ã›>ÉöO²¾èh€²KqèÑ+Õ	¡3iÂša¿[žó¥5`¹5hU“¢¼F[R³BMFv…ØàÒ8/èÊa"×´Æ,€ðØ$C4gÎªNèØáÊÄ}ÀwÌ…Rƒ0rþ2L$éVº°ÂA]V˜
+0;!õ¸$ °ÇR‰PúŒÂÙ±.Î9ÑVBî0±šŒ)@ù ÖzIƒôWMû]jÔ±ÛŠ£­j½`A|V“¥ˆb0œ®Äô)›í€'èÈQò³Yd<Ýá9ÅŒ×¹OhBZóGâ
á´®ïSÜÕ»$H„edtêêÂ8òQ¸|±§	u§8ànP’š Ñ§µ°{‡Èô;ämú.>¶yà™4‘TFˆÃ_Q/8I‡öìHæ‰ˆ œ4fhèHàÑ‘Uš,€Ó×Æ»D<As½¡ïÁ„N;¨€xtSÝS™‘Š@›…üô‚Õ82—ÑhdvÖè"*¢;žS<ó"%˜)mˆö8è ‘_ÔÚ”¨De-VaŸd†–+äœ:N%¾ˆŒe© 4ŒêS×¥°Ôä×|Àwn†"L›Ô'?ÞG8›Ø~."î€€„é"@4Úæ/¸U{$¯¤(räµ@t"’óXÝ•Í¹Ç$Ö áÍŽÄ®Q†@× X¹QŠP¿0=³¹ÂômÑ-¡þžLa“X“UZ,Ô%]„Üp'!/Ä""“Äb‹6h›±äU%×fÍVx¤¤²;ÂpSÞc<´|wp"€Þ‡	ÞcI‚¹s&‰IN!qØé	‘eËkÂ Nì¬ÎÊ.¯8lÚAÉ0F}4ŠH‰EÂ˜Á¯À ÄØh*ñôm£ê©y~ÍÑGk¢*»äˆÅ4
a†6&‹»tžì[|,ÝÃÊÆ™ÒáÙ/QpoÏÊr_¬z„·‹¢j˜õÕ®^4ûº³|™ Çô¨§1Êa,ì"}óˆ’!åíÏÃ›À¤¨liÿ
­u½””÷ÜÞt”;ñ"Ñ±ïÍF¡±¶qF ýÍÂs4†$<¼ ­w€h£+ÆÂqŠ×RZ½§M”UÈ‹a÷¨Kê ÔY"Q«1wªlÅ9£†}oo¥VˆJ Æ¤#]öh5\cë+½Ý×‹ÀÆ ]ý:×{ž3‘ßEØr•&Æ,n”%¤JV$€¨yà4§3~¶¦¨Œ1bXÖbÂ*"º°(‰°”¥~ñèª¡™ˆ%|UFÚ0H¦­ð¤¼ÄP3æ%Ö„ˆë€› VEMÐ\
¾›ê¼Õ6EY3¢ðôR°ú´Ôh„$>écN"í1/ˆ§ÀñŒ
Î˜×Sˆ.!1an`%iØë5äÈ<A&Ü>V€~Ÿ×Y.ÁîãQ”iµ@ÔJk´çvpŠì±åÓD`jßC˜ÚfCºíUceBã‘“Ø‡IH%‹4Ã˜£Pê2Yum±äð8í\‰L¯ÑÀšÛÙdSmj²Se„§õZ9!Å1 E:•ÏÊ°õ/ÒKÔZëÈMì´>sìÝ<(WZÔ¢’9MSÂå8É=¡Êw3Ñæ¡Vp“Lö…!ã©ìËþ±äÑ6–Öª}ëw	£§qÙTCÓrô>WÙMþQ,ö²ìRÌ¤x¸Ø“„—Ê²±—î*	Ç|Wt€7¿"Ýž™¥1eÛ´6 -¨k³]=Ðì½)p(Çt1o8¥Ã1ž%Z‰%u—Qa€¶…3ÉðB:6Ç¸cp¼h¡|1Ë«HÕº²‰ßÅ!#ökSn–“A-‹lµ8÷ölÑÆÊ}{ÝÜÝâ±øGµH÷Ø>-ãvf›M¬’ ”éÈ($¬F¶A/có9yñú!¥þYqh{@nS2Di?ÙƒQ
„Y\¤¬´hYŽñ
­CýÀ±]ÐUÊÑT›$uÿNaÛ¤4z™|–ŒâqŒ0|¶¦-e­O”SPZ@~ç]Æ	1ËÀÕ!Ia•ïgWþr”ô†TWç Ä#¥Í‰.Ë#ãX<ME·À‹ó†¤— ŸG<³@»‰ œÇìÓBI“ÏÇE8bþœÛ%=»òuBÚ`ò€˜<&Ó8.Œh¬ÔzÃr<( Ú¢/‘…k£Ïºf¦ï7Åe“½Ð>o÷
x2K¢†|’z4"´:OïLpŒî:Œ¦ÌaxÁ‡ˆ6©p¾,Åh–³QAÀ¸ˆ¢Ë
±+iPFíã°]=±dYG¦jŸ#ðd´+„@Ÿ€¼¨D(®ÖÌŠ™]ne1ËgÂ!x…Q
‰t™#Ü`#æ,76w…Mdªìš"“¾·p$hƒÎ¢a8Ôå|Ó#¶AÀÚbCÄ¡Ôé ÓÜØ4ê¼Ç|d´‚Ï62öï±?ÛL#êÛ‰æh—úÄ¨ì×0ž0‚7	W·Íº‰±ÃøÙ{qÖ›u‘-/Rq%v|#àÅ±8JfŽVN¥º$.Â.‘ïÅƒ<F±“u2òæ(;Ì°ì8È„hÙÅÞo"Ñ~—ì÷`¥ü˜ìs\ž6p«Æ6íÀuOŽãAêm²R@‘3äÓ ëöÛG‰I›˜a3zÃ$¥çÈL@·Éi×È1
Á±WƒÙ¸ùˆð&|.§CÚ£2BØÆ†fA¯wÂ1Eã>ÀìƒZË±Î›ëj–a|¯oüéOðL9^T©È«QD£ª˜ôÉ’è-ƒøzôrñÀŒ¨‚O+Ù|âBàdÅg	›F ÿY<¤Ø·fJ÷§|“	IÞ«¨òÂ3A±5ëÅ„0B’+Ø#!±ñ”§Añˆ2+Çxo„4œ	ÑL…e#ÓŠI5¾©ÞU³H/d™G	RWR"¤£ðíŠ¸$›Ôù¸³O5c,ƒS{WSffV³´iAõjÒî=h:çö•ŽÏÚfƒšËdw!\zbÂŸïæžHÃÌ%Ðf:A‹5,–x6®&ÓI>…Ÿ²ä¶f,t× È‡ˆÙÚë%Îl¡±ëq@™œ°chåÙL>\$1Fô…&¾'>@ŠO.ŒÏ¦/ú{Ø£òD,Š	úÖ:5•ú ëžæÚ‹˜v\›ÛcÆ9Pßœð‰j´Jµ5»h7ÉÑ=ØÅ)*2%#3²Ëên

>‡ãòÙ„Ò9jC¡°1!4„‡.²íkÙN$ãW®£½€u®¥¿$¨Š´Q4Œ;IÑ{Il/Ú(æb­&Q`D½µª0VÜ\‘¸ihCs—‘m±‡.\#á•­~Èì{°`WŽ‘±)M”¾ž!»Ž‚„Àv!VX´K¼gŸÔyÛé}W¥NðÉp95Ÿn+kE`¾Õ¢²h…d;’Ù°ÑÓý"½Ð¸¡6çàÔd¢½5#¤eXb@ü2£	;–8Çó‡ïëI±Ïm‰ÐeEVÃá\¤yå:’ ´>² Š0™ê &u÷<X½¡Œ}^J Ï„tuM=hÔ.ûÅL¢(I­Ë–‡Y„q'(ksÓ›àÉ¤HUžâ‚„å(zß×ÁÜµÔÚª8^‰ÏÞZh9Pm¸zÇNX \F‘y„WÌ=×Á^ÚÌ¥TMü¤ŽñŠúù®X)¢Wc§¶8A™ëxyŒk#ö%y{’	Ë´„%ðÕ.Rnun/Ì³	ÍÂØ Hñ!YœÃwØÏC#+ø2ã¯¼^9ñÂõ#¼¬íœ¢÷øf(R}QjOØMD‚“wä	:Dß}0°3²êk©6ë°¸1FÏ
òc¯£ÂˆÊ.º¦/ÒÑŒ«ú†@iÒóÜ‘Zp\ÌIPÏÏ¡Ñoë‘Ú%¢ÉOsÇKmY¾Œ<Ð&TÍˆÉrTÀœÒü»žœE@pIB]bJûõEéeE]O	©lUÛG^zøŸž‘µiöB#tŽ$Ò!Wz°¾O++h@„;\žz ÂŠ°Óç°9sx©o(©0ÈÄ(°0ÊŒ‹ÿp.#tzc8˜€;„"šWi+tViŸ’È2V >KÝ6ýŒé$€ÚÜ†d5rè¯r’%Ì‹€¬Zû´Ó¢G×ê$ï'ak»S‰jS_üŽ¥•PõgÛÏ4tÈŒ’/9z€p–l´6V…ò,kÿMç2QËPOX
¬+¢ú,íÑÏÆ_]EaÆ¦[§	sNÇþ¤…É	s«ŒC¬ye!“KlÔ0SqÝ;èÃ%SsqaÝ"i¸+%žL
ÈåM0Âô"»-sxwsÈˆDŽšk|¬WãO„üæøP×R’Ü…‹SŽ«½<M$à„àºOÔ¥\Ÿ†È3ÖúeÄbÂ*I¶a­¢,Â~¹CaÁHÂŽ$ÄJp‚ÏuõµKwë$¢ÃÙ°2>J„ä…X­*èÊpáCY¹¶rœk£ŠÓ^/ÌI2cu]êèÁ@ÃGX¢ŽŠP´]Ùa¯>óPsxŒÉ3ágZ@|tfå¢9ÿL´1:Î¼G²üì™!;=aéJ«Å˜}Þ5-y­•ÚÙõ….{.BdfB—é!wNÀ…Šf[˜Q9I/eà&xWÐ€ejšBò<Ñ04HŸ”æ%Ü­ÏE%>xùÇÇ;Æ5ä¢Q„ö«lbz@ô—ÝZs®¸!v¹»ÈåX¾þË
9ªH1k]¨o­Ã7ünj
g–yHP9Ôº˜]†sW·‰5q]5ƒ$#™ä0Í9¯cîëu98ZmÜd!h£	c²Z¨ã¨%¶aX†õ[çˆÉìmÎ=m2—SÍ=53²N¢(kLÓþËá_&äO¯0ÁÁ‘Ç	ÛØQP	¯]…'Ü÷"ÁPÏ/ŸELmÄ0d›Ä[­c$ì©óèÚ™è‹*Áq@#ÇøèõtR¸fX<08ac/©>bx8<ç;PAspÏŒ#»ï{SJ¤Ð	CBc<êaÈCk4‡CSì`>³’AM´¢c"‚)æŠÒ¬a[H‘FÍ,‚³åÌ`¤ËWucà¥á8nÓˆ†)ü>ÄË½Äy•[¨=ÇÆåMÌyÔ—Ô â°ê!Û¢
Cïc$†¢’`î•sG“ôKØŸ7ÙzÐOggÓÁŒë„çÖë [“Ž.xáEJa‹$y„ç:ÛÆ ÒÙ–=Q¬–b…jO]Õ¼…òâªƒéÕ„dÅ”£èð^EF„ÅãGaž;)õ‚YBûg&·¡Ð¹âIÐ	)½ÂÜš˜£GÉ[½C#>q6Bç	{`à”fÂQv40Œ02bdå²F®7ËA'$°r2õþ¥i^*®¬.ðpg	&Y Ÿ@®H’&ÇÈ¨Éf³Hõ
é¹P$ü.Çí°‚¼K”ŠþÖáAîs"Ç0­´Ÿ×7zQuÉ“ˆuõ6ºâåeÂ[ØšàöT'2"p¼PT‘¶U¶nèx<o€H‚°ô>ç„æó%ºÈZ…‚|†¡ŠQ‘Íˆ³q'3$R¬]_kPÆ#ND+ÐTRS]”T&l*âyqh¹6Ï"Ró}bÎ†¹ŒC	ÝxN´¤D*]S¬&ú¢ñawìÖs£r’MËj »º66È‘ö9st3ãÄdvê®œ“(#×:j“~HðvÃZ$²ÚáqF´“øªI4ÅÓ+#—¬AS¨Êj¥yÓan¯‹ÄÀS
8Ž‚JÆóöíÛzQÉ”x¹zoÀº¾šwÆ0&$×¢m,=dÓÁúA‰06Üë$e°#b)OJc§
{WîÙ*à¤$]³äí­8î™p3×˜Þ	@æÇ‡ûk&lÉ¿£GÍ›z9B/
 ô)sÁi•eG
G×Þ#Bh¾‹—c#Ä÷CgÖ³™3Ù%ƒWuA¥ ´<›ãe@‘Q(´N â~?"³Èå0JJN($TÑh`)´;³´,â`(âVDî­ë˜©îÆr§#JÄ£ÉÍ¤åp¦=Œn3¶Qua/KóÜ$!ÎS…¹û¬¥a2È¹~ÏÊÃÃ™Iô²±‰°,ç@—ù€•£‚âQ…˜áùÃA1pNtWê]kŽ@¤u® ©ÜŒpb– [„ïh ”àÑ´hµ¾mb!lí—9‰´Aµæ<µLË"7ôq\â¥KæMv†8+ñ8œQÁI€o˜Dœô“EšíY—[3¨÷ŠJ|M:l‚}bÚÝAb$PŽá$7›nb3'Ó¸Áê®!Ë‹Å0¹àìpb[_)ç	£ÚˆÓ…•cØò­£ÔÝZã·•tÏlªO ‰òÖŸh‚Žê›ÝU« +•œ£HÂéA)<ƒç˜éiWÏ`n@«ªBcp¡ÔàT”€®¡a}u7ÚŸN%E	É|Ð©ÏË[bu–Èâi«™ÛQz)Ã€÷P‰“š¬\ê	"½›kÖÙ@&–`Îð‘NQ¬‹ïXì"¤1ù>)?îŽÜ‡ºÔÙ{+ã>lo·5Åm¤Lú¦òè|ì¢ß‹Êè 8ŒcÁ;ÆË4»HY"8[fdÇ„eDÕø´hØk	…¦D?YçÇŽ$‘6©Ã/Ð¿…>/J“‰µalR:œYjŠA¹ÚxHÄtãQqQÆÔNˆc“nJjKvaØ—MáqÌÏìr3a/ìåå2¨w­ØøÃLÛKÞV"Wí“å¥g÷J!+ÛñÔŽ¾·†ÇßÄ¼¦ÝËãÁ°“çqb”[‹³2|›q;§F….Ž`æb‹Vˆ­ÎY¡KJÛËë¡1Ãð@BS~ÉN¥¿›#›-gR‰Y%n¼¶aà`ðº5úƒÝûTëÂÝ	££ëÛŽ¢5#ñb¢³‘­U—2ƒÓã8FQ?È0\Ã<ŠºmÎÊ¥H‚´>¹íwàb:¼Ç‰Vggâ0Ñ[&–Y½øW~ŒRçÜ›®ZÕY¶…m”È›5}ëÖÚ"ëÕÛ¦á8R{AèµN®ÜvÂ99d¨®I6)¥v1ã—Ê0ÙLå
AlÅhâÙhž ùéZMLó	%ñç.'íÚGd"o­]3W? °O±K¢ôhîs¨=k=¡ˆª°$‡A«y1o!+‹ZàUÅD,Á>ËQÖÊ&¥jtf|¨€$Yp  j6F™S[¼˜hWôsøc±HéÏÜqÊ»ù´Ní<ß3oTõ6ŠaÏgpð.$`gÞø]—ÅÜÒ è4ß€ËB¡t`‚ðL ››ÌT§XÚ1*”×¯!ÁB^'ÕQÐ	=‹=Â¨ äìðe#ã·KYÎùI‹'ª®*	YÇ°M¹už´Ì52áL¿æŽð8` ¢¨ë×éŠ˜÷»&)(qÂö7îƒòÑLÆˆ­UØ9Iè¦1 3ÌA˜6˜T¤¢Z(ºNñFT'o„•|Ó[`*Oá‰Ä*.¬ªQ¼œŸe5•	D^-àœx7zH	…ƒ›ŒÅT¨ˆ-,hØ
á·ÉÐ#[lúxá…‘ðNQÉCR¿+EÄ©HÂY`jF²ßÕ1U@E6"²/°¼!”Êb&ƒ(+£J9ÒËªJúÁ€þØEô{l.0bmÈeê6¶J€| š7o<@ñYr[»T3h¹2Ù•±†!'?ZW}’jSÙ	ÊÇ0(ººmJ«î%!Ýhg9•¦¤ß ™ÄQîÌ%X>—:ïxÌrÂ Î0²%G¶žŸanBk ô\ŒÑù´,Ÿ®Y=.(×&ôfâ`´PÍúÞw×7ˆÎÄ(Î<(6îYú€¿–Î˜oÈ1f={*qÅÌ!Cã¯Tä@iŠô2³:|Ãt@ÅÙ”OsSóÓ˜`‘EÎôÝ—Ð‹©»ÕÔ´7õŸ ?‘^šš
!x¥ˆW UG%†ËzÑË(Íàšý©IÖ¿‰\oÀµÇ¡¼àŒ¶Bº„Žt#\»ÌG
”ìs¸Š(LÊòó"’löc;éÝ9”ÛTK)‡’5ŸDfñB„ÚÅ…÷•I¦ÁxàKÆƒÅ›ˆÈìÐfƒÐ¬’“ÀâyK½ÒCn 2Rj>‘~øqá˜óBf$™Ø¬9rÁçìëŠ–œ­W±	~%94Æ™;œzÈ‹\J0­K@ ÉÂ°ì”Î=—’p_””ÛšóI¦wÒKÀh,_ˆ¦_è%*Ne(Ïœ\+ß«âqWM§rGÀ-ë—F™¨K"nÝHlq–]áB/Ôg>cWÉ_ÞÂúgAª“ŽH,²iOœ—ó¥Œ®/„(‹‘!ÝcíDÕÐŠ‡Ê“õÿÔXâw=BÆçÄýpª&¼rKr±æ•õC¾¥:9êTFÝ†"ÔXð(ÃGÙ9cŽ[ï‹èÛ¼ãHbŒcÖQ[‰*ÏNÂÜÙI4å"—;W$ÂÎ»äƒ#M08×4À¸<¢–žë|öµ°³ýê.UdìS%›aÈÉ	Zé>+XW,qVÜ2Å3Äâóh†ã’,Åb^Å\G;ƒ®sÆ„âLPü‚ú§…ÂÄ’ògX}4`ÈUIl})O…
•kÏ›¤ßg!%Y>å½Ï¤½Ò¢nÿöÄbuÝ,½
Gâ)K:ÎÞ²c)Žc^m¥+wÆXmO8†™1¾^°09–œÉûO©ôœ>˜R:CS	ºÏÎµ8‚º4¶»o½ uæJ@V8j¦n#©{8’úÇcŠn«—[û±O’U²±ÑTGº¬¥.9—°Õ1Íj:ð¦ 2â™2]Ê	¨PãLÚ)LçU‹9²8)O çm–ÛÚ„6B‡(È0á4º£6å÷L‰×ÒÃq—]¼THß¼Ç0ž¨ïTãpü©àºZq}Ó°'Bì2RõõÓºæX<Ü‚ÎŽ“ÀÂ\‚â®I	Ê!Óƒ"r¹s¤Å-V\”z€Vµgš§:wHäx¢`AIŸýª”ÞŠ¾ùD®á•&d‹¹Ôe#ÓQÍ|³Ú¼*uF‘ï:MgŒMv951¯ž©€\îÙáôN;jGÉ®aÊ`ÕÃlÔÇªZ†ê4¸fŽ§r;¤ßGÂ98ˆÂEÀ%-(.÷R:G»Ó)ç#nË¾pUŠ"	÷.Ÿ‡lÈÒÙŸéÍD„ŠÅjvEÖ§š?I&É•6Ð4ë»ßã)Ûß$¿ƒRQ_ê¬J¥"÷D¤Ý’ãtÕ”K4ä’,,UŠõ;ÜßE”„œÈI—5ÌÄîÏ-ÜÚ“k\Ö¶Fû\3…Üý¤à–.LL©¹Î±êsf[š—F7™àVE9ÄW,££¦¬ÀËàIi¨œ¥678Õt‘?Œ˜\ ©•Ne‚1nRçE÷—¦$)Û:¦Áé¤ò`˜4E`K
'‰­‰!˜‡*GÐW 6g®0´9budéÜª¢3ðœk…²ŽB)²DgQÉØVaJ¸;VS¹lõ¾é¡îR¤à©F`êcëÒÓÁÈU›ŒFdS°âá_ŠÈ¢ËŒxRLqÅÕ]‘1h@µ”TAqB–ƒ’y›ežŒå/msáqâ`Uneà¿ÉÜÇ(¬n¨GŒéœÀf8„[
M‹S4 ÊäÜ‰Ý%YF‡Q]D6CN]Ý€ù,ä€,›ašIä•IEæ:òƒê€ÉF3msª¸
2énA:Óº´M¸^R)}ü‡UtˆÄ7:8ÊEy­* c4SZHGûš±i†‡ÎUWûs5¥’6T`	]¼ÁÃó‚	›QYL>XœËf¯ø]°àG†pòT›Ò"°¶‹]Õ°þHKI³«šÜ'Z
Àc?ûƒÙ9ÑC^7_ò¢úÂ²un‹zÙz,XE§žd¤‚ä‡£Î×Bš¾ÒUd¼TbÉ!áÕªÁÈ˜,z' P)¾À@|Mg(AJ©Mw$;™¾€ƒhCNˆNÂ«1Å9¥Ö¡ =xU)¤4¶¯J‘À+Ì²R¨ÑçöW„Í²Y]—47¤Ú^™’h;]éthÃkÒ’\ô)|ªNZ¦
~&žGÒL­ï¬rü\L¥}ûÆ¼Ä¥þññ3tBÀ8(Å‘C<“~U×æˆšû#XôÐiÚ¹¦‰ä­8ÀâHÁ±Ed#èsMAPKÖ“Xê¯Éeh´çºµºo~§öÃvïLÓñEÃX—–uÌ~&SƒŠÉe3ããuÚ	Õ! 1òÀTcÓ²¨ÆLãÕ—À mFDÆÐe7rÒ˜Ý]O§ž¨¶ÚØlbq«®¹Æöû!æwéf®~:Öò[¡Þ›(úR§L­jýÊÙÍ¨2»3ùÑvMI>ôãž	Ë×]T¹Ü®t};XHd·Ø¯±Í·iÅO¾¶AŸÅç©”7Ð©ey<ž¦¡¾'†#õJ•¹<“€.‘¢3ÅÐRAS·¯	{)Ùå]óï0£â'ES‘¦‰¸´dÀ³>q]ÇwW¡¬=–PÑz‰@&ÓH<Î™…·€ÀŒ–B1%KE®«c[ Y6ºæG ™‹.¼U2*89bŽÎÔ1j~ò˜[Íhã~#º­”‰÷R´QƒL]OñI€F ,–HIÞ
EÂ%ÿ„æFÞÍŸZy­ÆÂá+I'c-°u9l­W·øBáÉ©A&W¼¤ïU  @“BW"²Ž«Õ±Öeqÿ³«ÆñvŸâzQÆa{N1£u‹ƒœÑÊºHü8gW1¾<hªãvÆý*rï^*˜Gp™æÝEÈ‘­R€,hrÁzÝ€1=íy7Ò9Cwþ¥‡°ÆœFhër}X!ig±Éæ•¨Ecõ"åGÉA„øB3JFt‡_gB]˜KX&ÆåvüL=am¸2*	ˆM3˜:î‹n‘Ì°° ‰ü
Lp¹Ä€jiÐ„ó~FWa­‚ÂZÕÄ¬‹IÖêiîu¤øö”Ò08’šlwŽgÎ•;¢pë€*=ÂÀŒ¯ƒ(Ž@c‚5”zxX¼)Æ™×	¥]Eµ¨7…løXo˜j/…Bö'3¾ j|^kÖîŽ°´€1ï®ø†EøÕ¢	|eUpù÷™-@}!û:žAßÍÅ˜â‡}ùNU»LnÈ‡c£×ìŽ—„ ë7´Îï²‘=ÚP-n™Iàªž‹ÍÄ–L3¸qÿNüP’zo8‚BA\Â¬e	€N+"\H2`*nÔ	š–à2bƒôâ!%»‡MÎ¨ôZ‚Ã™Ä½èwÔnWª×íããöÁÉêùá1þ ŽŽ8nï×ÕÉ!}ïüÇIçàDuŽ÷wON:;êÙAûèhow»ýl¯£öÚ¯ñæ¤ÿØî¨×/:êÁ¿ÞívT÷¤/ì¨×Ç»'»?ÀíÃ£wxq¼8ÜÛéÓU-è^TGíã“ÝNÇñjw§ãŽIÕÚ]vM½Þ=yqøòÄ>8|@~TÙ=Ø©«Î.êüÇÑq§Û… ìÝ}q~Ü=ØÞ{¹c©«g áàðDííÂÌ ÙÉa=ÀÞ¤­†ŽƒøûãíðµýlwoÖ¯Õz¾{r ]ÐÚµyäÛ/÷ÚÇÁÑËã£Ãn§©x	,øñn÷/
f ûï/Û¬.ÀØolw°/gÎlNWýxøYÌ{oÇ[\¨ŽÚé<ïlŸì¾êÔ±%tÓ}¹ß‘õîž Ð ½·§:Û0ÞöñªÛ9~µ»MëpÜ9jïã*m#”ÃF£GM.7=µÌã 1¨ó
ñãåÁ®Äqçß_Â\K”%¿ýÃq‡ÚÁ‰àõ.wÏ †bÄ¨Ó+ðƒEŒÅÕþáÎîsÜAœíÃƒW»»*°ÎeÛÏqažÁ@vi<0\%Ü·ö~û‡N×Áì3K¶ëª{ÔÙÞÅ?àwÀG@€=^ªƒ.Ì·Õ†=Fˆœ¼ÁK8ˆ€q o|ævÕö]FJµwØEvÚ'mE#†Ÿu°õqç ŠÎX{{ûå1œ7loÀhº/áîðnà|éˆïïúÞ>oïî½<."ö|Kˆ 	àÝµz€›¯vŸCWÛ/dÛ”w”T/`+žu Y{çÕ.Gé¹+k³#²ŽŒ}ß6ùn¼Ã``·”¤â2¯¾GôLF6yˆlÃïM‘Ž´µ7ú±à3J±Ø'¯pea‰o*<¥t)P$Œ.Ù :Ã.¬ÿ³€*ÂKÑÙ±So”r&(&¶¼£;ò mZgy:Âüy*œÌâÊèñE<rÆ^a3qd0HêåÙÄ!lº3{@KágŠ.-n_,ëZñ¼¤}žs¡ý¼à{Ú´DÎu¢CËD–w Âª w<Hr¯é—öVbÎ WN‹‡DæqNyŽ9pîTü/³¼[ZÏH>åF¸7$‹º	¿X<ü«³Y¢ë6Ñ4Ê÷Iøñê›UIëÆú’4Š«cPu(Æ@+¾êÔ)#ùë˜À]²Cçá §†#6ouc¨8Û‚‚ˆœ0{¾¯%÷nÄHþk¦SÕÐ/JL„\J²·®þFêOÍÈ45T–Å,¢&))ul_ÐÕs3SÛ•®²EÙTë{\Nz_×xsæ7§t"}–ÅÑ =(¡)N$òæS©J¤¥¬Õí5õ=V§{
=ˆT§ï=å~Oä¾V¶ám÷–¹oÜÛäxªõAq9pÞPµGq¡”æž~!	?óeøºVcJ¦GÁéG«~ºéZY³iV/€§¹»jˆî¤CÚ8Kö°\•õQ-®!Ñ"Ûc“W‹4–6~ZbÅiWEÉwžà¥¬àÕXD‹ôpíÂ`5YWB„‹×&²Ù¬›XêÊ9µÈìZ²:ÈŽ‘‘ú~8N¶Z­ËËËæy2k¦ÙyK‡{´žÂ€Úº‡I7ni,"Â´“ìß|õ8Õ¼G;_–&X5
ï
	'¹ssåÄÕC%Êzä[êšÊéËVB\lÈ¥k\iR”Œ…a§T·‘‹º{±p¤¬~/ý>½ñI,á!—f¦5m?ëî½<éìýèj2iOe;Õô
ôotãûåÝ¦W<Ï–u-FØ&½ãMø4›¤hcIxìv×»ë-KÃ«	šÉ]¨Ì-„z|4ó¶àŸ¾­ÞÍtöÂÎ±w*u8 AÄ8¶-ÍÔ]cÚ¬d¡õÚÇÂÝx¹k«Ë54 ÙT&À‹³ô]ÍÄMÊ)ÖC-©×Îuz…b¯¶· èý¢lbºP¿ÂÁ×­‘×+ q0.VÆ«Y7¾)ëŽVÌÏOÝ?8|³³s­$Khø@´js¸ñæm8¤ÁÒCÊ–Ã”Æ˜|8ÒÍ-DÂÝ®6±÷Rër'WÂ¡Ë!ˆe)ú1#¹ÖëJ’í¸ì/åuâ¥Å`òL‘E<4ds·íQ\ES1CÊ9\Û³ø]êX„K	/À«»uÜ
.È†eó¬{%…ý
o–Ô¡ŒŒ¦t,¡©ÜŠÉ0Q:¯Z—Ã«,sct>5‡ÓñvçŸþ?ý´×:î´wö;Íqÿõ±¾¾þèÁ…ÿ~ûè!ý»¾Éßáó`óá£oÕÆýÍ‡6Àï›j}ãþú£ÍRë_h<Þg†,†’§ÑÂvÐl0Xð;OF™ÿA>wÔáË¼ø-
Nð²ç>Š`HD´•[¼ÚiÀïäâÿü?ÿQK¹”“L¡tÃ%	Uæ¶P?ú#I5‰’‹ÄöÓ !=†=â;úÎBíÄ´d@Ç³oô@ª jÔÙ‚1˜¨–9¾ìÃ ÖµŸpzØÉáîŽ7RÂ2bÂ` t€‚OgÚuÊzÃ•®pLŠ6Î}x„ac.Psõ$ódNÛéÓx^0´˜¦ŠwÝ­ïüºÞ)‡&%…*¡[Søfowô2zëÌrKw¿®ŽÛÛujôÃËÊPõ"¤Îùt6X[œ˜R ^JFÒîFÎ$€ÝÓHsOBÍ%üæ—™cÞ»—Îú0¨f>¼wO–¥®oóNñùL
QÉ…“¬XÍ’ÞÍ1Ö€i·ãº)°nèÑš%ã0ÐÇsêÕÏK©T`ÅÇEj!çïsõº"á.è›Ãçí¦(À:¯^€Ÿ‡ì•Xò®ìÅÉìzµÿþïÿF…cÜI{oÙŽÂ\ÄÁ(Ça>9‹ðÆ”£›ò¾ÑÓDŸ?C»ju§Y4í©WðÁü½Ô½-ƒ†ã ìÒ;  Lg“ÂvÙ¸N@Ÿ!›Œ6Øh¨Ë’Ù¥S¸›¸§ònkkardå¯,2èÚKÁYŸÀbQ?¼_0Ð¿ýío8ü ¥õû7 ·õ_-õü{ÚëçÑÏª5[ßhñ•¢­rgª16×7¾mll46îŸn<ØÚünëáw
}Ç'[x‹0&*^]?­ZonHáyÐvžª-
@ÄÐZÎ*3±ã°î1Ö]]øòËœ¯“.ä§Æðâgøï™úþŽí^çôY»Ûyú³ZOÁ±yc÷ f|°m^ý©16¿½8Üwž?ƒç/wàûö_^Éã…-EcXi¡£ÍY­’Ü5F©ù<Z[îb>8¹WïCï*~Ë ÖÔ…æ<W;šÒ4Õ>²8":avN/š¬Ò-èjÙÇ2¡:pÞx oóã²¹¤zç
Á¹h`ÎDVûÑ DïÞŠþu­¹¬‹>w.€ª.È5PÝ…]Ì5Y/;é!<økh«>¡
@Ñ=Rv0 \®§
9îÁØL£ó&‡T÷T8_¶m^Žw
+ŽÔÔ™ñd”4úcèÊ_t\¯ý°V[ÖcÅ¹\ÒãYØ{;›äU}òOË;¹SŸz,ì”èÝ³YÑ­ùqé)¯¢NKf+Ì¾éZã¸ßE¸ëKûþ+ýét/='>¹¥ZÓñ¤ÄãFé92É ð
gJˆžSºä.)°ú{Œôø½ˆøø‹K?›ð^ãìÞ=!L\ó^bFXšsšÙµaÞîW¿}9÷=µªÅ1ŽM•ñðÅMkø„ÆMk	pH¢p€él]a¬¢^¯”ï@Pjª*i"JÎ·` ë->ZüXÄ‰0X~¬”0.‹` 1.=ê,Üìïë›G§ë[l­?ü8yd£¹Þ\×É­ôþòËÜ—w0»nŒ§pŽfQ¾ð—¹‹²^¦8Ã&UÊ•6BrYµù<)®ÁbšCºŸ±wøÃ-<¦‹ÞíœlŸn/é¾ENÜ`óR`ó²ì]ÃÆËï.}ÏcNŸ†ì/…`ù©?jâ‘7Ø?C±½·™ßƒŽŽw^nŸÌ]]±ÿ o-ÚJÕŒ/76››ÍæýæúM ?ßí ¿Àn¿jÆË€ó¬õè„­_úo7šß5×O7m.„ÔÝ>Þ=:9}þïeÌ›OC‚¾†ÄVÇê±_Û&g»5XhÆs³C1ž|Ì°FÆ½Ùé®~kÙQ¬z«L>¡ãå§©ú½œ£êoF –Î÷&§ï Ži€Å€›¼Ø9Ï(K‘þjæy³Ñª…ýÉÛúëÇ€hžîtž·_îœº
O—ì¼£Bž”QÂ#ytªÑäæý…¾¤~½C[©û„±ÀyÂÆ¼€Wº _’ËDyk­óŒ+! ¼oÑøÝÓq4/çañû)_Kç=†ÝÑ(Åg­ Ne+Àò€#ŠýsÔîw‘ýÚÓì»Oš(6žþájº€Òó,Åp¿y0¹â	ÿs
„¬»ßœ\Í*Æˆ#¾å§ð47¥vmáwM`³|Rø É*(½â/°Áú´V€¥…Ã6“økI4ñÁBL<ŽXH‡ýKÇT˜úÆ'²«_œâ›¡¾¤—f‘d¾TF°EÝá¡*ô&úD«HÊÖ>	%«…¡~4GØý8€GìÅÁž*üöÉ&OÞ\¿)¹(AaÐ¡ZÔæc¸ï¬B´ÇË‚;j{õÞÚ%¡ØHìÌu£þ'U[y¯›]×@Š¨ÕÔÏ)m-PŠZ4Ø%—ëVS·u[)Õ¬j¿D#	’‰zÃTÕ:ÇÇ‡ÇÀ‚ÈŒŽžSå›ƒ8€ÿÁLú¬ñà]9„gìœè¿øèI­©œ)´VÞk"…Ïö·Û{ôËéA;ñ¨i;Õ‡‡®ù>øt¨‹Ù¯™;_"˜avŠÏÚ0Gú ™ßÂ•2\õ–j÷šB3Õ6Î2$çH•z1[?Nt2  w>&Rö3¶¤ïí áX¿”Zª©ÿdÁõ^SýÛÊ¦p"š[ƒ›‘#Â¿Ï8Líž1¯
ašÃUî¹ŠÏ=&²'`áI‘`XÓxÑ‘¡Ó¢Í'=<«T$Ù, jpx–Fçµ%§dÙëŒ:wîàŽÉ×ºõ†ñ4"Ÿb<»2v{Ú¥…Æ.ô†Û4w¬gà¨Ør%†1ãQå|iÜT*€ŠËµ¢aàyáÎ‹XnnÏM•
}»X¸#má¦È¸
XöåÜqªzÆÚ&Ô°=o‚›%Õfqoe3¾cÎTqaáÙ;¬GÈÆ¼&'tsæ¡cµ£°M§xÓ7ù‹]‹›»&DŒTw®Î=+g«WÇ.´º¶àÖË»t^œXXI>†²Œx`ïìQÏI 9ß3[Š½p	—–¶§„*|>¨ˆI¶ÅÐ°Qþ¨Å'ØÐ’o¢A4.|Qh˜t"®Š]Köq»…Âœ ê©7cû
uÂ€­õ×Ô÷3§²Iµ«0syZ©&= 4o{{*š2¾ƒ4'?>À{;í#z\—ÿÝíî)Sï+‹lØ	©?2 ¨'RV¬ª”(ì0ÕÕaÎ¦læè…×¬ƒ,ºl8uÜYý™Ü=a¡:æ )­¾þ+ôãM¨”2Ë¢ ÿ~Sí¥¶t\iÐ~Å!‘«ép|Uä_ X;+±hÆžZ\	.ÀjÇª¸D{èÛ™£?=ã
zeié§Ûš #î˜>cÛœAû3ë`þÀÄÃc/tTÜ†Ñh¢V‡k¶r76YŒ½c<§öS¼ÀY­h¡Ð‹6g™d+W«4·"ìÊ]kZ;3·úôH¨±e¨RÖuËã¸b˜˜)ì8öFª/dÈôËòªå†jÖ—£…¥±ôÔ×—^’ ©ipSícFg9ë7Á´}¦:‡ÏA••p¤ç£è%"¹âÎAõ‚žˆ9u^©Wšu›pÈ|=
§¢>ªÙÚÜ†Õì®’é©M?®7„®]'r]­ôúé™™ó¿]n•³®ð S!~Å8±¹ë*ŸƒIZ¡ûõsºvçXÔD‹§\14¤ÂÐÀ¹Ý…hšá•\EóVf£¾x‡‡¢›&§Z’ ±ÊbëžiÉ•w‘eù2©ˆè ?ƒ£FòÉÝN½Á˜ebÝi¥H,rŽN¸W=¡hYæâ/®Þj³²¤ÉÆü•õ¾˜sõÆ—¥3KýÅ+cÖNs÷ùC0Æ·ež–ÞéJ¦ê”(Ö•>P~»€îN8Þù³vl…š1ØØñ²n¼µ¶ÂxO³èœQÁ‘¾ò¦¯pë´L´œN8È¼áº»4o¼Ô©v2C§ˆß. øÎân§~ÃêN±ßÕüOõ~PWp<–v¥oŠªšß'u*¨[õÎ
ŸªT*Ç{;»Ï	ù1mc0mâ‹Ÿ><Ç!r“á¹Í]„"CÀùÂ:!O•Ž`Ü&¿/Ö/¬¿Íp”|66à…Íæ}B¥‹¸rÞU^ã
ïü~g¢ªC¨Ýó‚hºñM4v9JELYyds8Š§ú{¬¶>°d_ÙfP‰‹X­ÄŠñ5õ¤ŸÒv÷Û»k¼ð´ñå±·2‚ùŸZÖ_oðÑ2!™ª¦žX[ÔÐË(`0>2
ø(ÐòÆ©‰Î®îç…gÔ qìV:šÇT¼Ÿª†Û‚'Aú íCóc%‹W²qî|´¼s äŽ(¾—Þ¬gRZ^YÅHúg¦ïÉ-á	ÖÖÄyT™•JVnP­ðnGÎÿ8™ÝY˜ÂhB[ÝWg•È¼pº·Û=ñìÅ¬\ùÁ®Óð-(ódÆ—OÚÏÐÑëÓç»{U2Í‘¾Ü¨ªú€zèÊ{-g\·üŸ\ö›Ówd,péÇÜÿáñI©oîßë‰L_Î$ÄòFC3€8<k1 kS[î¸s´l\EKÜr hÈ[ÔØú“]¬Z9iëú ‹;%Mä\µYuÇ“âiÊ¸¿þIaVp*¶&4Žã¤êècÃ­[|s¶$P%¾ìAÚgi9™>bB¿~Ÿ_)°]S?Ÿ#B*úÝ^	3Ló)¯êŽ"o³‡ÁfÕëN`]<ã mnrù‰÷’oåç,9ª³"52b•÷œBÛlt+)Q˜c™~©ÕBeP\æIÈÊÅHÐyF^nÆN¦¾×”â©?p¬[Š¿
I¶?ªZWÙ%ÕýtÔâ¹œ†aÕQgøm|¡P)ÈÆ@W«ö)ÝK@Š­4cÐè†@£,Ã"ÇæPüÛÍ`J®#V°€æÆßnÚECgÐoú­õÙÑ5áyÔÀÇ’4hQ<ÔpL<7ŸÍY?C°äŽ9—ÓjðŠóóÜ5|!^Äé\ˆø[:‰‘'¢;—‚~0½U wdHNÖ¯Îsº[XçJè›C«´A(ôóYÂ…½È'_JÝýïÿe	ør}S"]òÚ•‰4–Ó‰¾ßëüpòâ©LŸ~»ìÃ_?¤Lc,’œ36Øl¬Óu#a OU"îk£V®k€j(ü;›L$7ÈÚ¿ÈPa`p£(9ŸíÝ	Ò¡ÜÔ›€7/™ª£qÿÿö·¿y“ýÈ¥)ê;ÛÍË3=e‹â)y-=øßÿë<ê?ˆtuo7jÃÖ&ÚêâsÓtÀ~Ä2úObTÃGžÔ]Y¸M	²Vú,`IÏÐüi‘Ëb~w_±†(•ìø†^m@=°÷^ÝÃîí¾>¸G¦Ý_Ò89…}ª:pv\0ñEªlOu€Æ|WŠf¤äJª€84éÃ,Å~Øù40×­…ŽO¤àih?ö’`N!Ýáj©qRå?Ã%ð=e‚öŒÓŽwL·*(¨Œ¥hCë&ã·¬×,öt.b’X›l"÷"I7hw¶™Ø¶°¾YC.i‚Œ›¢—yB¥yq™‹èc°F@18Å\¤7!þõi¯©»¯´ˆ /ÁÜf¯ûÙ¤Ee,>ù&RÅ`² SË€>¦ïwv7žÒ?›š$.DPô €ƒFÞ|
€xsF
ƒ;­Mp;yÉÁr8ll¶ZæakF¹«:«MÕæ ´#ZJ$v#g–Ú	²ÀˆtÖ*Ônžc†•u¥ˆ½³Ù9ÊÝ‰CA¸†¹QŽOé_®	¬o73U1t+¹ÆEýôü;;»‹nq¼åëÿoï[×ÛÆ‘DÏß£ïË;`•Ì8é±$Þ)©G½ãØNÚÓNìµœ¤/éÏ/ ­X5"åÄžÎyš}Œý·/vª )ÊòEVœ4Ñ;Y
·B¡
¨*–£aÜStƒu[-DÉæ1+;ê¬ÅE8g[ÌASƒÕŠZÏºµÚwä·íD/ŸggP$ !=™À±Š´xÑgX=šºè1}.²ÜÔoA¥glâiI9ñ¤3b fþò®ð¨t®7•f:&t™ºVÞA[êM/ænÖ¢y.œ2gA_ÚíKšPi¿)Øªûjãjÿ?Šb¨ZêÿÇÔUôÿ£Fåÿg©–
¸”Ó˜s|0É5öÜ³Úõ.!ÊSQ=‚³í™ö/ÓiÈßB<eÎcE°sÞO 8wé„Ô/½_&±ý/f¼8÷ÑÆ‚ýoéŠ^ôÿe[Õþ_Ij+Ô1ayÚžëèTÇ}PUo»¾¢w<[÷}SU}_'ÿÙlÍÚÙ.íPµcµ}_3Ý¶©š:õu«­ùah;°[1]E®ÙšºPËpÝ4]Ãpì¶¡Zm§­m×v,ÅÕµŽo¨T®Ù¥YŠa+ªëYijŽîYF@}JUÃQ×¢mŸ:~G×5©¶° U´ŽêiØ=MWÝê¸¾Ka¾g»âéjÛ7¬Yj`¤Z¾êkŽg¶Ö±`€¦íú†ã9Ô0Ú–ßöUÅ¦
ð‰9 Â8‰:ŠHßñý¶tÇ¡Ž§ÙF ·Õ¶æuÚ*ÕTU/6.YÆuÚJÛ2lÍlWÕP;¾Ý±ÔvG÷ªyž¯(Ó¦´¢3}×VÛô<è¬´ÍÀð]×q­m9š¦ùš«9¶¥HÕŠwmOUUÍiÃVuLÚ±•6õ;Šîv:ƒêªÑ}l#ˆEöd®ªºÐ³í{ cSÓš& ¬­žâè†e©fV¹Iœ©i–é´_´¶© &(F[w<­­(€–ŸaYìYX3k«èç)ëiž¯ºI¡›mpÍ²]¥mSGUü 6Æ,(Ùf[ÕLÇ‡)65Ë À\ÛòMq,UÓÇrçuˆ÷Å¤Fb*`U§£+°Ö€l0õ ]µ:fGU@Ú(’íŸé™&leªÀ`L@íÀu=Ý±¨î9šÒv-Õ³ÍÀ5´ù“sKÜ›vS,œPÄGæØ4``‰tº
,8õmÛ	6“fè¾§Á+6kéèN ©~[*b¹ºgú:Ð„À°ÀÒ66O1iaí%ÓM­­)¦'Zà™ší¸«Qþ5³mûŽØ^ÀÃ¼Ý©hì˜š¡èšN©®ØJÐVá¯ŽÒ±4[q|Óq
{,oYÕX[Cµê:¶ëBïUXxª¹ªîÚØ‚¢Ô£Æ•pj
ÔR= Sª(8˜[…!µ5ÕU`8¶a;Eä)@Aæ¢f©@æš§¶îtOµ‘Êê Ÿ9.u<˜;·8¹Ì¤VQ„Um¶h'@ŽlÝƒERÏuªÀntSu5Ø+jÛö€ÐÒN9H#9	Ãø"8aê˜0ñ@ˆ¨' ¢êh^[7à”ô`¸¾­Ù€ž¦–CU‰;’=ñAOÍŽã¶©mj˜ß5¬Ží´;¦ÚQ-<y]W:Šï•ÃÔŽRÿ9¹ñSj)Ø‹Š¦y°$NÇUáÜvl
‡!L¨JáŒó,›Þ *›Õém½X´cy¾\AG5KwÇÕáœóà„s¨9g^õ#~‘w„
‘Gaà];ïà±I g†§ù ¶ÁRUNCj9ªæ
(f)XM=âf%ÃÁ%ÞG±ÊlaCZÀxPÃÑ:ŽÕVm8ÀÕNà Qª­x¦cN9L­SC˜¾£w€¢&µ\Ã…ˆŒÐ cZ
:Å	ü6ð57>›Wêµ¯Œ‚\œQ¶Ç»ü†ªY¶áy:çRÀª~$=§Æz¬³`´}Ç¯8T×©Önk¦íÃ®5,×Ššb]{# ¥¿x
²¹è¾åjvÛn+Çð8RUß*äHõ•ò™Õ‹3Ëú©êºíxHtß°lG¥°,_³¨âÂíÀ©Ý±ìR˜¢“üä_ÔœÀ2m !š´Có¨ÅØUµm XhÃ±`K”£“ª•Î&[ §8@<€«SÏöL`kß¦Y°;–[¾­Tåˆ{(”á#TàÛ„ÓÓ3m -
õØ®<	á 3aš®¨Žqí5b' |¤×1FGl£;LAÎ»ítà0ƒCHæG›G¬JI çô,Íp=v¹é:”Šâù ˜Àû ß¢VÛVGateÈÝÍí×ýíšîÃ\ßqpt0`ÀÚßÑ€ÃÕM@~_u“z’Ã¯Cþ;¾«¹–xÖn[ŠÓ¾¸iµX8&5“[«?©à¾¤„¼Ð}·r¿iÎ¿ÿCyå‚tK·@þWMÛü?Ä¼ïŽaú“Ëÿe2Ð²ÛXpÿcèŠšÜÿ _Âú¶®W÷?«H¯©H¶øþô1IÈo`àCô‚Ù[<ˆ{œú+é‹¨§Ï·úÏ Nß¡ÇèE:Š'NQ¢uÖ	°ˆy	'UìN¦ÇÇë¤ÿq_Ò	:…¯-³Ã¨&Úä©;c,ß7X|ñ½Ó ­Ø8yÒè: €¼&¿ÿG,ÆwåP{ÛÄåµáã
GIÓè£©èMµ_X aäðëæþt‚ñ<yYf)%¬œeÝDNg{S2ÌæŒØðßE3Êr£c„“K\Õ†À¾±ð-À$@‹jé3ïÓËýÝ†ÞTþ¶ÔE|…1°ÔÇÐQÅ¨z1œŒ‚yÈŒ¡ð³›´…¿7DKí`#ñnWpósHÏ)ŽIbò¢Î=ó©ŸÙÒOÈt¸•[âÔŸ™ùågÐ„Cy‹0‹iCvÐÄ„rý_¸têç™ÎxÀ#½ 1pékâr9w±Ñäm&oÞ	Â	³ø‚ÏuÛ÷%%	©e?‡ÁcáÎœc®ç¸»{´ù¦¸÷jç×aô1/µŸãË[çæ„œu2*|˜°·ya¿™³ºXÏÙøÝ2˜3žLÔÑ¼
 Ô¡XÞS C@y î)7áë>s£ZÞ¡§Ôµœ:kiÿf3¤Ëv6TaP³¦pD(­Šd6s€ùI”|DË %›·u¼Y*	ZL1VtÖ•¬ìè$g«Wh3ï«S"¼Y°2<äô¼‚‘Ê•`Ñsåcx+d4Bh;£‹˜…gwiÅ*O["+´¹T*ú÷ÒþC%ýÝ-žî¥«ùUÕôTÿÃ05“½ÿêfÅÿ¯"-m‹~…À<à!³ÿy'f/„#ÇÄÏS0eŸ’eG‘£Ï³@‰ÎáŽt‚Ï
‚IÃ.Î`”¨Z=ä$ÑV…[øTÉ·è;sûÀnKŽ83«Í›´‚Ûëb;Ÿø\¾Ý8è½EÏSKœL®ÎAöûjoíýôïOºï?¶ÈoÜ]aÂZ~þ¬%%=ÿ¤_3¶ésöÅéåëq;/©€Û“ü fÙC‘ÍŒ=>_§¥[lª ràpW‡™å¯Tö¤´¬T`8Zòf%C7ër¡GNñ“pñ-
ÀIÞ“Ô’“l Ù	«™f³IÜy=¿[nKlî½~qÝ	á+ñòzC–d…­ƒtySáá³¢V¥d Û?3«À9 „ùû tÀÉWTŒÓKôÇ YGøœß<‚‰ƒÊæ2Ý¨Âôóö›ª°Q9!ÿtqÙ[c?ŒÀÃy2Z[*ô„õçŒ5#
“‰LWc¶Ì *@f2ý¹ÂM(‚Pcõ'ƒ¢7\.IäÔ¯ T½æ‡#Z~@óæ©½5Ï'ònþþß$:q¢éix¤¨®H´Z>=o¦ÃáÇh‚×8'õ.Ùû©þžPõ¨Õ%/6vv··ž´ZiÞÈÅpß/··Zõï	ó Ú$X9 ïŸ’ÿ 3©Ë­ÕÉûg¤1žF±òÇ'gr+®¤½‹¼øtÌvôÆ†ÿŸ¤hr76¶¶x'>ÿ!º5¦Ð8ùOÕuUÔ¿•™Â\¤Å“Û“ÄŸ\||I‡€ßÿ­Âù|^Ÿ6Õýåº·ÀH¼¿ì:ùV©A²É_‹‰4<[Á—
¹sKñV³¢'II‰Žg_¥€
 €–—*’/©üÉÜòR¡áÕ@‘Èe¥™/%V¡.#7nº\
©øl)ÈÍ•B¢>[
råR³%¤¯¡›ŸÖÜŒùt"µÂn4óRÂ¶3þ™Œ8ÊÖØF<rº1ÂO—¿õšÔ½Q/s=óŠ®Nêâ{âq±©wÖ‰I„½(1Ún4ØÉ÷f'	¸&2ò “£}%àc<ó— ÷™í«‡“ôHZ›ô˜M§ô8¤)X)¦ßÆü;†ÒLnÔ‰_2cÈä#ÀJÁ’¬a³·6Œ0ÄSó;èœÃIÏ™ÆaZ ·¶‹®®vw7·{›;CòcZÓBå¥Üô{†Yé9—Žq8á]Æ“4+âYeý‰†¢8ÎìwÌ¢G ð$eÂˆ”/ìZæz:æ¦ã,³˜;@kCk k*WïÆ7>ÏªÓ›UgfæRuÀ©›P9ƒÝFf—.8í­åŒÂ¿Ð–eOÏ¾lgà#ôáÌ™\$ÝšA¡92ËjÀÚY·ä{òçe>æðçƒ°·v>ÈQA¡Ü[_ã÷Ð{/îÎ£V»+IåjÞËmcþ‡f›Fzÿk™¨ÿaê†RÝÿ®"U÷¿e: ’ÁÃWx,;I¨nƒ£Àƒ¾þ:¯ƒ¯u½ø%®ÏyÌ]vàú1?KüÝÄìÖ’\d1ƒ ¥±Teô?³Ìº¿3f¡ý¿¦ô5Û®ÞW’3r/·áSDåÑv3×©xNâM|`VÐ›	fêRf?Í5Dî»£IrM‘{ Ýë$ß,1Š{L"¢,"ì:ÙÛÁ¶úÛÛ©›Úã›î RÓ ß]Uowº* \×€ÔmwàO€ûç<Ê+—ÛÆ"þßøÅÐQÿÛR¬jÿ¯"Uúßï_4/~˜¼ÿðrV½Ò ¯ø÷uö›cÊï—þÚ†Ï¾ï6naÿg)zeÿ·Š”Ùß_7_]Ñ”jýW‘
^zî¥[¬¿­[Õú¯"å½âÜO·XÓ®èÿJÒŒ£{hãæëohÕù¿š4ÇÕRÛXpÿ£*ª]XÓ0«ûß•¤Çy#]”–Oôi(Ú‘O‚4rÂ  ¿áÃÆÿã3ñÈïßcñQíÿ6³ÌZ0@Po"®Zí1ÕjùqâÌc`lhûxâœEµÚþÆá½'øo÷	uÕLˆE{7Jl Sâ>¡ÞifeËã8ÌÃzjÓÌû]—t“ë¤Gêõ´÷„$#«£b >Ð¤aÕåR„4ËJÀ:Œ(+À5n·öð¥61±f}*­	“Åç+±ãI|Øó5È´â®¡^]G8Q8ð¸_ò¤×VþsÝ}W)ÇÿK>û–ÛÆÍÏS3´êü_Ešñ	vm\wýÕPà?Æÿ•ÿ§•¤ëyÚ¼[ø?Øó©ÿoôVGMÑt»âÿV‘ÿã k{´¼K÷G·y|t‹çÀ%÷9÷ XºÝíQðÑ•¯‚æ?>š}|T|äÑ×ÉåôŒÐ	ôa8¤#â‹È\‘ãòQñ•Ã¹á³Þ£yïzK^ùeïÑ²žö–ÚGLˆi8BIÎ¹0”,žúƒ	7ORžÍñ&\Ošæ›iÃ·—WD$Ð\„±‚Å,÷õÔ­'Uf”ÚH·TÕ-­0(+$¹Y¹Ä0+_s%X3Ao,ÈÍ—ÉÇŠMÊ`n¡\.îmZŽ[.¦%·v^m¼.¶Ês³R(`mÍ”â¹ŸÙòåíq_áÿEøý#
Šø™¬È>²ªÏS'¬'ÅÑI,ÊÞhA“õ®ø5g?S—×!)Y°•ûœä}g¼Ïìwø„Ëù‘ôÍrò‘™èm†£Sï’Kñ9NÊ!ÁÉK',à£Âö(†/ò’ˆ¬}:úƒãõ7é$ÆëDfQˆÛLNG¨ëðáü¬‘¨OˆïÂIóa£ù¥Fac<	ÏÆRÆþ$cs4Â9L¶åR›­F¿¶[ô;´±€ÿ³u=õÿ©é¦…üŸmWö+IË—cùæ ÿCæú~F/‡#B·ÑcB‚)üãè\ÆoË‰ÈîÖÎà&LÌ;!>ä	.²Ü+<yTÔs¦,ß4 £&yNð?ß™äÔ8Ö„3àgÎhŠfg@pù ¤ä#ø 	ŠT\éú¸ä7ÐPo“ÙŽ9ÏiäÀ¦u§À’ÑöðˆPÜð d9Êß)6æÂãrÌwk»]B9öj€“Pãló5xÂ P~ÛÍO>ÒAhTV:1Äp Í;#Ÿ~"3ú,¤ÇØÑ95vC'€>‡…:œPŒ+]¨µ´iöG]âzÉ,¯ÃïÜÍ[¯#üÍ•6ÕB÷ðO›C •]@%ïMŽ÷AÜG…oã²Ì8rü¨áÇŒ'lø£îóB‰prìŒ„oGg˜´5•È.ùw¿ÿã†©jŸ÷ß~ü[ÿ|:ð½7ÿzÙ(8Toö‡ï:_ú¿ì«íñiëäôãù¯/Ž/üŸÜÛ>Ùy{z°ëü×pûÜy;T&›///?þÔÚŒLÃzÛ_>oýºíÐé`÷í£š7êJ¨åþƒIÜ^Rf&Þ(Ì,+6ò<@¬m Û%ÈõRPdÁGX! .gažÆ'“pz|Ò€¿q—èpÂg¢Á%Í9œÓÑk=ØjM¶oØÔ
qäçöÔ­Ðèžö9ö³ÚèkâËé1+ÿ)ï$Ã1g¼Á|ù$bš,ÐWJ#~úùÃNKÝ{ùjüêo?½ûùGúqúÓ'êÛÿüå—_âKû×‘ýá"ØÚ>9<Ûùqøó»n¼ý¯QôñÃßþ©ŽèñönûãËýÓOöÁEçùëÖ¯ãÖ«VÿGëì_?½nÿK;P8˜fhåÿ¼’JäËÍÙàiƒDÞä éŠ”Ÿ€—h8À^–—à«Ú fÌ¿²ÀÇ	ì‰òèb‹Â¹«­«ËL(2/ó ] §š†ãçt·û°!ÂK——A·ÔèbäÍù<@ÇCxI€  4”ûpö	pô/æŸ?eøõŠùBž¿Áµ®(ÀùÖògÈ#^Ì¨ÄßÎ6"Ëà,by)~·ÁVÍ™×Q&:™Æ‹½´Pù	8Š‡Ko ±<sŠ§YŠê·!y_ãíÉ×Ÿ®ÀîNm,¸ÿ1U+µÿS½ÿ¶VÝÿ¬"UïrŸó—A¥;áË\iÊu®‚°ê€½ÿÁ¡r‹×?q”¸8å|î›³cŠ<}sö:æåd:òSÎƒð†ñàA8<Æˆ £äšÈ™éã$æ[2kéåqÀ¸j ù¼³Ð±)†üÒ'wCUÝ Ý©(bñ÷‹;Ù2”d…Cà˜‰‹û3ŽÄaêBô4œLèiLŽ)Ã=˜’^ ž0	¡ÛßìU°&:e±eØ­_“¼0ù‰cÊ‰ëxw1”ƒBÑ,Ä;$Á¨´-¨†0&’GÓBDGo±Z¼N"t³–Ca•LÇˆÎ¹àóy²{šË]‘Ä5Jæp³Wo…ãX„Š©ÏÁw½^½àóäêÅˆñªÖÔšjð[®+½â•‡ï—ãn¥¥‹Ž’ç (í^¦ äˆùÙ”ú™<6–{üfÖ(…n ·Lôá)ÁH{èÂ!ÿ¡‡þ
eûýÝz|(dlï÷ÐýCÆÍ†ÁwOÂÍnÞ%äSLô¶¿÷âðÝÆÁvqÙ¢0ˆ1¢Më<Ã‰ÖL­#ŒMU“¿?·0MI¹¯ÞåŠgKJ¾ÝÊ•ŠÏýV2ìÔmÈNFêRü=ºWîÛ1-‹‚¥„è,2ù‹pO<°§ŠÒ›/×WOä«´âOÛ¿ô÷¶oˆrN£û³~æChŽ¥Þ¿ÞÙü	÷A¯žüÊ†‹PëðO:¦Ã(ÎÇç÷Þ“§éƒ¼äz’üñÓ:x’hM<Ã³÷1€es0ÔS®Pë¹\çjù\çêuYÎƒq7œ®D³‡”®lüm,ÿ3“ÿàƒ½ÿ[•þçJR%ÿÉ}ÎËsvÂCVRYð¿ÿÃ_a6¦ü>™ ·,Ë‚ÏØ+yÌÿ)!oú¥z¢™¡Cý8{åg¾fÊgïKg››2Ë27“	Iêqþ'`qÃ…ÙjóÃ–C]g‰ÑAÝ¦]†LÂœ…17ÓZ`z
 ¸\Ò!VgS'ä€J½e¿†,b$cö .ˆ¨Aàë3†ŽuŽ%ÜÅr>Éb’rî	Cßì¼œñ®Î!ÉñxËa	½Ý{ï¢º›êí¦À¾=ÕÝ%ªä&ø/•äfå²Õ–Ëe¹\}——Ýð}Áswˆ}ö*RgÚ½sÝž¶PI–?-R³—¨Ø&ŽñgÕzg\â—ªô
¥VìºÈAtåîæóó‘G°Üƒþ¢!¦”üú,*ßq˜3ÊºçtâÂ1™ü™†H•ŽáÈ@p‰†uqÅ¿Ñ§©kòÿwÒ ^Àÿkªafü¿‰ü¿ªY•ýÿJRÅÿË}¾ÿÿÐÕùD¶…Š2þEU`r*³ù7Vž#UªÁ_	;.ÞúZîÎ–,ù¸{X^•riöü×ø¦;B=­#au§À…öß†’ÿ:ê¨ªZÝÿ­$Uç¿Üçâù_¾öñ/] ¢Ó Þk2t|¡’=¹a3åÇ¿€GÕxçXéÊøð‰*dáø>ƒŽb“œ™h’>C¼™hœËšøç§PÈ¥c®âHãê>î.}¬îãî÷>nOl	$|š°âþîæ®{·µØ,—ëÃ¾¿²Ç‹îp4ü(ƒ“’Î	'‹@Èd#5‚÷†SŸ>Ÿ@—ØMÒóì‡©°ïl1mf‘¦‚ä²¨ìŽ«”åŽCbÌ_Ñ]Ñÿ§©G"\Àà£ØF±zÏú¿ºÙ«¶¦àû¯^Ù¯&Iüßò™Ûp·`þ–Úáë§jGR¬Þ#Ç÷ÙNÐšl–bPÉ÷Oº}…Ú.ðR,ÖÒ)LÝ»9'5‘ZêjÀhÉœSÂ.jÐ€ÚÄù€3v*f‘2	å»ÄÆ—Ç]›;1*F¨Z˜‹‹u‹îç£–;}ÓqSžãšÏ×x”Š¨¤È”°Ü\­´Œ–õèŠGÅk¿)Ê¶÷gaanZìê—Çk1]5Q*;ss‹†¬cæW‘OW0	Ïøo­¾è)N†'5ó¾ÆßåúÜW,&Þä’<iÂ’â[ …F¥xgxÜ‡BEáÒGòèSþ€Þ ³VÂu=ë‰“ «ž÷j¹0áÙ3ß¬;žÚM&† '“d" ¡q!<yI‡—Ýã•‡Ïžåÿ´"ÿ§­”ÿSuÎÿÿ·ŠTñ¢ÃÿWñ¬ñŠÿ«ø¿Îÿiÿ§.“ÿSoÁÿiß"ÿ§þiù¿9ï¿wQ [Àÿ1~)çÿ_Ã @ÿ·Š4³þª^ÊúèwùPÌLÿçÖ_7*þ%©âÿE‡óüÿüMððùÿÄ;ÚëÏœ5 ë¶³™ÏyWn¯CŸ~rÂ×ú¹’%œ,¡—–Ñ¿Y‚Î.X^Ž¤Ãq½~#~Y´‘Hj^~Pœ3·æP…ù€ê%vj	ßÌ.]Dÿh­´v%h­´4˜}©Ç¸Pè0Þ›N¨´{Ô²:ÚÕu´rÑ§TŽHå¡+‰ˆ·)õ‡$Sê•LùË”UúzÒµâ?Üïû­˜Yü/Mgþ«’ÿW’*ýo¹ÏƒA|]Êßù(`“Ì	ù]:Ì‰Šq[‡eðf@]ÃC©÷†@¥î*ò;ô±Ò /h'A¨ˆ#9ãá¤/Ae¼ÞÑþF¿ÿnï`ësLúQ·Ô$,ß?ž`ÛÀìÑï‰ò<LQïÉSà3	s6àî:#@AÒð=Rßhüê4.•F§™A8ôIã#Qøã„Âº5FD}–Ã¾þ=}|rLI›üõ¯°.Qôzä»ß Øïßå³ x1ƒ,ò{nxé.ä²0P “äÛ×jÜCWÜ“Cz?€—¯ê­8Í²0Ìö°}nÏÂ_‡]”„ŒŽa‹ImþÛG¢øŽû¥.ÃÂ_{ÌÝ#y3bÛ\²Çé37Ý@©$|È¶Øîi;ÁÒ)€­ÿ Áçº)F¾éo|&sªmä¡cµ¨¾ÜiÉV¹¸KªXÁ
 Ê#c®ð³¦ÌŽ7‚Ûû‡âõÝuœtÞƒi:-É"\Á}Uo®7›å»«Y²7XoŒâ9ÇwËM\ÚTnkn™*+þo2ÍêÿêEýß»<ý³t#ý_ÿ½Òÿ]QªÞÿE‡+ýß‡ô®_éÿVoöª7ûê­¶z«}ú¿âfˆ}tÖ_,ƒÇXÄÿ¦•ò–®EµuE¯ø¿U¤e›E–og xïÅxùÃ£{øì‚˜‡èKr{EfO`<Ð…þ+ÀøÕ2xvSÕšŠQ`ðæpwq(:KXgÉVxæ¾ŽîAkjÖ¸É	#$Á>eÎjd®ï<	üSóÙœ1–Ž¥ÔjŠ²Íc?]ÛÚ{µ±óšE<Z['uFJx½ú³À/l®€çhMµÅ«E­¿Duò"õâY@Gl 	ÄÁ(~Z„*.ØáDC ¶¢¨õgIå(&õ¯ªÜïïJõµ¬>»7œì®+~¤.,íÀ«§ÇH_IÝzþ ø£Úx‚ZãÈÎ¶®à¢~ûKôûZa2¾/ßO¦y¦8.@Vœ_¶ï§s˜Ïf·X¯$ybi1Y…7Ùü”‚ÇùËJ§OYsJãŒAi@UAÞíöbÀs}à9OùxwCÁé¤S-ÍÃzî=§d²9áÕ²ù¸ªbŠŒ¹y¹ª"ÎÔkiseó³¨V6k½™yZWõ¥Oëå§YûŸùW·mã&ö?ª®rûŸÊÿçJRuÿ':üíÜÿUö?„«¬îê]â·íKàVö?Ú·ÿIÜTö?÷cÿSù”¨î”_šY­ÒÒÓ¬ü§qÚ.sÀ÷ÿÕ6³ø*È‚ÿU¯îÿW’*ùOt8/ÿÍÙ_ð7ÀØ
Î01­q’Ã9*(ƒx_‘2H%ä])äM*!ïO(ä•,¢üÓ´ä3ÁÐ‹™a‚^:w’ôˆ©¬—Ó„Î‰{™ô>ÑÏLä+oA[ÐBQî›#øeëtÑïêZ9áOU‘cùÿÍyþÏ_X t "Î|tK¹¯ `'nŒK­(±E¶l:†Ô6w0sûýÕ‰n×²ÿG«ˆ;ð˜ùEŠÿª©Œÿ·+þ%©2ù_dòÈÿþ¹u<d‘^’#¼fÖÿÏéhŠóˆÙfåSë§‚YÑ¬» h ‡Çt„1årMÁß<N+œ‰ž÷N1v/ãæ¬y¾V6ë÷™¡¿ã2kLø›[ñJÌøçŒ!!ßÈLr
.ßÎTd©ÄÜõ2{M®¶6ºþê'lãg´ŸžÆÙ8†®3lxòÌ ™Ïmˆ˜ =¤Dk „îè‰‡Ópé‰s>']Çóè8®<Ü¡Kpƒllm˜evøcÎs
R85w
"lN„ˆ»P~g% ¬Á<r¤8èßŸºñf¬ÁöŠO‡½ Ú£_øŽá“×ÉÙ”²Í‚›ý9 wªÁDÈÆæîZ;ÎÁý	”–ø²M¹Ôa#¢#*j¢Ç“pØ€•ò‡t’¢:rC>»ÁñÝúS8li,*ôÞ×Õ¦ÖlJSUuÓ´šjÓh¶ó}ýÖ*¬; é÷Äñ€É¬oa9¦ÅNÀ£tâqêqêÄ¤‰Vïåûú÷Èè†Ÿ…÷|¤ïþz6®°uZ°ù`ëð›EÛzáo¾™È³ú2ñ'CìL…?_Ò™_
¥ÐcÐ°ÌåÿKÃ»ßIXèÿËÐ2þßÆø/ªf[ÿ¿ŠTñÿ…Ïsÿ!K IàäkHç'ã‘gxÑ{dü2ß?—í¿6×¦¿âùWÏó¿rCòc	y}~ÕG˜Ï9’+W1]´³x?ÐWPwzÎ/Oy£1ÇfäÖöØR²w¸È;É[:‰BÛlà¶nÒæÍû2O¼ ŽèÒŒÎáÀo8¢×ÐîÅ(v>•·“ówÆBRW_û¬¼ñÄÃPƒw-×®Èân[
P|¥.w’ñb ‚6`; ­ñSðQý¥ñÎ½ûh!!¤¥.Ž„w§pRèXšŸë[–Ë»wÀ¡¥½{™|O;ˆŒk
Ðyâx1p¶ÐV7Soà»£¿|''-Î·B×ŽOœ®±>šžÎx]}=©©­Ï~9|Ð¯é”çŽ	càˆC:âDrôHX×§tiöÂÈrÁãªJ¡1dÂééîÒÑq|ÒxŽ®ôÞ§•ß“·I‰Òú)v§²‡TT¸ Ê€ÄhxÄ(zF»õ>>‰û¤ÿãFCÍuöïi8¾Ø]%*û … ¦ öÍtwõY<Äž5äGÆðP.{{(Ö1íÚ¶m¿xe›ôÓx 6ê`XÓÙµ
u
-7&ô_S8Ï@¶šNà¸Èf†wéæûh>JÅ <‚0uk„:dõ½
£n…Q÷,|ýÁ¤ƒcAäóÄ}€'5ðEúÎò±nÞíÎÈ\ÒOðA 	;B¾öé'Á.5 ƒ£ÌÀ±'ƒ	ÓÉW~LAùF|1¦],x|1ï; w„\Ó¼ïÑÔ…£ÎØ´ fócbà¥™¼ëÑß‘ÃüpOØ0ÈÖsLæ$?:š.Déð8¸wÌ~ƒÎpØèëÖå<óeóyoƒþ÷¿“Û ýwÒj<ŒË…*=ø”Ýÿ ?>	c”Bý3Y^Z‹ü?(’þ§­¡ÿK³+û¿•¤êþG¾ÿ¼È=»É%9ñ»§FYý¡ngª‚38fu…pË>2«ú#É;C‹_D-ö À½#!ZüÉ 	¿oTMÊhøçxFñÀ»˜×•ÝUðÊÿNš§}8—{oöy–Ž/€Ey€“IÎ²Z‘p^Nééð‚ÿ>Dx‡
WÞ‘{¶øè|Š€gê™Ê«GµÏÈÝrÒ<à€N¢Üxè[¯úÛç°oAZ§°Ù€.IHŠßn>ŸÌÙtÓ?‹šHâ<z5˜À³pÔòÝðÊîÜ1Ho¿<W.	_d9¾ô9U¥ûIsù¿%¶±€ÿSm#õÿ¥aAE5m³zÿ[IZÚé˜œ‘XqwY‰‡Ïîî½<Bvœ™#×ñN§c~ç>ÐOˆà%¸~ùì::_|ž/>½MùôV”Sv~Ïßÿsé?®ù’hÌbúŸÉÿ–ôß²”Šþ¯$UòEù+ÊÍ>~S”Ÿ'YÿoÙ¬?Kï³ø†nZ@ÿ»¢ÿ«I_›¥þ¬­> ìÝHö•{>Áž¥×Er½	;êCè’sÈó,u¾9qžG›—7ãµo€¿LHüÆ’Óáp
OÂ€ÈN¦#|N´B—8 hàùþCÃvFüÑ^uwosc—™¨JNtB1yñfw—4ÎûÿNÀ…¦wB~`Ñ GØyí‡¿ªµ¥Nï`f#oÂ®ÕMP6=Êº¶®¯ëæºuÍ‰Úy½y°ýjûõáÆ—™/Î¬dŽ4ÍÑwógF°&83‹¦âKLUZIÊø?æøq‰ÈwÔ¿”6ñ–b¤üŸe¡üo«¶Vñ«H÷æóé€À¾"OÖà|d—Ì ý•åzž—$NL
ìäl¥ÓTì&)òŒjS)2oFÀ?É}ÿ•ðÔŽÊÌLb8º€~œyñ0qÑ‚ÃàQ,²aäÌ+˜Å,7Gàÿ’Ð†¬;ŽhÔ'¢ÞÉ|8Ý´™ØºÂ¶‚<e=}Ö$þØƒLnOB`(`±óPü
›àÒ Kæˆâfíq®4³‡s#?óXÝÝÜ÷hê‡ÄÏ.;iM£Ik8p[b˜âÿ·
ß;>¯YÒ@éò°¬0U+‡£÷©ãÅ€Sñõ[ñEõEÍôÞÅ2TræŒ¦ÎðJà«´t8¾9ä°d%àJºqk¿!ýø½¶E9âCC=ÁéÈŽ`;kïœQõF4þNN›Ü¦¶¶ÄtRÌ$µßÉþ½vx1¦½h DÖPUm¥k/qÇ²_ï lÈtÇ÷f´jÛŸ¨Çðoö[‹¡Ø;êîb<ôµÇ‡ã’²ÈÏ"âÈÅg4œÆ}êõtE©A3#ß™ø{Óx<{€p°óÂQB÷“¯Û“I8)~„1ò;›)ê?¿èM‡ñ€éd'SóMD•Èóü2òÈ\½«Ó)-òÿ£ÙfÆÿ±÷«zÿ_Qª|~J÷ˆ9Ü —Šx‡(lSÄ+gÏŠ¼cãØá§mxA€jEéÓpjþt’ÞF‡âX
°‰çü<ý³œÀ­)³\ò¥dÊˆz@dÂ³Áåm}trhÏa}$áØªÂlBÃ3š…&Ã«&´ÿˆ›Ð°0pD&ð ß-:	§CŸŒÂØi2¢¨®êL. n¼Ál¢"Úyûè8C¾.i+Ç3pâ+:!ô¸	³LšèRøh<	›¼ÍÃšG6Î¤>Gâ,üƒ”Î¹3²¥–Ñ8ŠÃÃ.ÅÎ1a~ývw6ßô÷^íüºq¸³÷¤^j?Œ¢#bè›Vpï`csw›=Ë%r‡í!û™‰#ëÉVŒp–ZSEi9ã±Pùä0ßlÉ ó0aÜW”:”ÛÚ8Ü˜†€2	Gèì¬§÷Œëùã(…–zDd}”º–º²Û¿¤3­Üe¦ðæOoö“qKPÅ…ñb˜¼ ¼*ÌÅìÌ.˜ŸÄÖÙÀ÷‡ô£3¡2è¯Þ%àoš±¶ïŸo7äŽæà} d&'°cYÑäý7[J4'œ ¦ñ9e$k^›¡ZÌ®µv8#z¸y<äíÄaq=°P‰`²2Á	%È¦@PàÌp1ÂqåiKÀñðZ*%ý{éÿ¡º£¾{Êóÿ‚ 7'Ñx‰m,àÿUçü¿fº¥[Lÿ×ªøÿ•¤ß¶_¿Üy½ý{í€Fc8(­~ËgõÔ¦Âÿ«ýörûõöÁÎæïµþöæ›ƒÃ_ŽÞì­Þî½ÝÙ8zõ'†ý7ûèo¥8Ã¥éVéþR™ü¿DÑŸ¥ûß6ÕTÿÓ°-…íC©öÿ*R%ÿçåÿ‡,úoæ”>ÎM°˜ÎpàDìí@>Q+8žÊ‹@L®y³•ÞG¥—BHƒ_ø
5¼À§ŸÕ—[Bq;œÆäðísÆ1:ÿÝ,ó™î>ÈÛ’¢y›.ÛÍÆÚg^›ød¾Ý8è½u†SºÄÎ
å–ý¾Ú[{?ýÇû“îû-ò[!rÈïd-)éù'=øšÉMŸ³/N¯à¥Ÿ;ÛÏ
¸¢ Ê)RöPd3U—Ï×iià›*€xÅYÄ .GIeOJËJ†ó¡…hV2t³.zä?µ˜Ñ¤ Þð=Óz ²Y3Íf“¸óz~·Ü2–ØÜ{ýâºÂWâåõ†,]lí¤Ë›Þ|Q«€R2€íŸ™‡¿9 xÁY °6™äJ'$ÓK 	^¶Ïø\à<‚‰ƒÊæ2Ý¨Hyo¶5¯Ü¨œ’º¸ì­±ŸFáá@­-•ŠØñÎH´È(ºã°Û¤äR§†¹¼ÐË&ðhw§ø¹FˆÖøMV2èÕ›DÚ¡â*Aèž‰ÛÁ'ƒzÍG´Æ+á®_óübä ¾ó×ÒB'I!i;g_‡ìk]¦uékz0[û•+…[h¶äæJáŽš-¹P*-68)T¡×ƒáÜBé>‘J{W—æ›0+¤$7elE²ÏŽ;wÚ‹E¥Es…¤©KIP:kÇãÞÚ1Ø6L3ÃžË¯Jð^,ù_PWñ„ÇILÕî&¡Ý]8{›d»Í’?Ø™œjöÖðƒOšßÁ6ñÂa8é9Ó8L”ƒqÓï`OÒ¬ˆg•A‹†¢8Ð‰'ßAgbô.ÙO—–É°%%éÄÄà>¯`5S¹„O‰¬:½YuŠoÝRõ	ß€%'ƒÝw“ÐN1q>{kçƒò Áˆ7*øs:æh1M‘bZÌ€ÎœöÖÎ˜‚QÿÀ…C×œÌÅVê¨SD•*b•bòðàRsCAÌ„™ÊœÄÊ=‰¦g_¶3èälzvæL.’nùìS)ÌÇ™?šDØ‹²˜KYP%î½,œÒ“KZã>ÆglÆŸby09ÿ¿Wgmy*_íUtáþgâ ,§œ·Ä6ÝÿBîÌý¯jT÷?«Hƒ:£M|kÞ+¼`r|jÈsu/ñPð¥{_¥»¦rý/&-íxÁþ×¤øÏ†­Ø¨ÿ¯ëÕþ_Iªî‹ú_î×À¼ûÕmðuQ º^úmðµn¿Äí!ILAXÀõÃë²ÄÁßM¦Çža-þ'G²P!»Wó™óÄîeŸ1‹øCÓü¿QÅ]QzÌH>?RØYÂµ&‰Jº¹Ã€•øAv·6ö	†ÂÆL]Êì§¹†Èe.1Ó\SäJÁ²ÓoéJcÌ;=ÆÒëdoÿÙêoo“Ä.®öø¦»€ÔðÆÈ½S:éªz»ÓUáº¤n»Ü¯V”¿UšÙÿÍ£­íovVÆÿffÿkÚÌÿ·¥ªÕþ_Eªø‰ÿ/àþåÿçX€”³ë·° )J	J‹?+ÿí1æß†æ}¥™ó?{¹4 ÎÝÎâ¿+€ü¿méÿ¿’TùÿàGÿÚ_yøßÁÈ-|€ÜÐH˜wdRô "ŸàµU8þHg¶ÄÕÇz
=ÝÖîßéGÙZß¯ßrìªÝƒëk´tï×‚~K saWüæ;XæD¾Ê¹ïsÛÛÛß~½Õ?JÍ!{u¶ÁÐ²õÁ?U› ë©–Öªç=‚äoI“»bî¤á#+ú¯é º%{™['«€êø×ª4¡ç“êËs.òÀ¼‹Hþß©8!_ÞÄŒ¥ð‹îT»hÿg«ŠYñ«HÉ“¿Kž,þðôÕ]¥Ý.^
åöÃr¯„žì‡¼É  |rŒ£\ ?ð"9öQ.’|àÅr,eP[òÇ–òæŒÁ ñEîÒ¿È=>LÅbÝ¾¿ ¢»5É÷z°@ñ1bú:üNŽk¾×%ifM
ñ¸89vF‰¿ŠÜ8¶8DoÔc'r´^ÛƒüólõBKÞp3Å qÐI
yŸ†pöÏ…Ì?ßò—&~UªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©Jß`úÿŸ‹[ ˜ 