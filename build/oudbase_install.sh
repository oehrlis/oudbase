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
VERSION="v1.2.1"
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
‹ kªZ ì½ézÉ‘(ê¿®§HCl‹Ð`!©¥mª%DBmnCRÒômµé"P ªTaª R´šóÝ÷%î¿óÝG9ržäÆ–[U $ªÛöˆãi‘@fä{DžÅIû7_øgmmíÛ‡ýûˆÿ]ÛxÀÿÊZ¿¿ñpýÁ·¬«ÖÖ×~»öõðKOfù4Ì`*y-lÍƒßË:Ì¿ÿ$?gpþé¬
Ë›ÎòV>üc,>ÿGß>x@ç¿ñàÑÚú£GpþîßßøZûs)ýü?ÿ;¿k#
œ…ù0¸£š·÷ÐVvú›jåÖÁždñEØsÕyÑPÏfyœDy®¶£‹h”NÆQ2U¿WÇ³É$Í¦jõÙöqú‡Ñy”Eq>ÍÂ<ÔÆêë7Ô‹Q8že³óó†:¾Œ§²Q˜ôo}Òûá8jñÏ¦ò.|Ù™M‡i&_O£A˜¨ƒh˜bµšFy]åôY+¥Ïþ}*Ðê¥cèÝíÇSÓ{e7Ì§[Ã09úÏ®xû·Ã©Ûm€_p“£è"Îã4)5Ñ_p³ÃY6Ióˆ!=œQÇ½,žLÕ4Uçü3ŒTœÀÒ’^¤x…*ÌUMg‰ê¥ýw"F¹žÍÉÎ1gðÛ8Œ“Ñ•šåQ_ÒLEÉEœ¥	*Î0MÕÉëí&_Ñ¼p¬0N§“|³Ý>‡–³3Ü6ïXŽ$P‡ß{Q¢—ðâp·y¿µöo·~Ü{i?ÄQG?ó(R0+ØÞMË†3»¢EÑ7£ôœV<N3ÜBøuN±%ü¯GG‘·g“>X~ë“mª- ‚é8þ;ù9Ð¢÷tï^mŸœœnï?YùàüµÙ¬MÏñ¶Òì¼vMè&}•naÛ†ë2MÕëp4‹òÏXPðº{t¼s°ÿ¤v±ÞÚh­×‚íƒÎáawûIíäèU·¦nøsp9<E|Ð1üN&àÙÁq÷Iíyg÷øà]DÙ\I@¸]Ç[G;‡'§û½î“•UÄøèŽZY«'{‡§Û;GÝ­“ƒ£ïŸÔÚÓñ¤F>ßÙ…ÑW>x®Û~÷ÖÊJ-8>éœ¾ìv¶»GOjô’«ÎÎnåƒ3úµZ}e„ê+d¯ëŒî+÷jÁ^gg·³½}Ô=>~wóßÓ,„ÚêƒîÑÑÁÑ“µÀE‹Ï?N÷|–ô³>#Üí^ÁÌK½ÊÃóhµ®>iívœOFá7¸åÑRÓGÛé^~®j;ûÏÔ&Ü(òÍáE¦š±ú¯øÎ>àÄþV÷©jn«ï@¬èoïÃï?ñï‡på/Ó¬ÿÿ©ú±j¥šÃ*d§ÁÕê™Å˜=ü5§ûEU÷Š›2§{VÕ½7Œzïˆ8gÑd÷ˆ8Íà¬Ûþhô½@ôÝT½äÉvœE=b {a«Éæ€«Üºgð‰šÈGDKæô.þÀ'jGXtU¿ÝôœÈ0ü»/:\s»x ~€×¯Uó|ªÖÔ‘ß'^æÖ(
“NÒÿð3j·òaãš¾ŽFÀ{u»Å«î¿¦èóA\·Îð*¯Ö#Ó¨i<&f<ùRWv}µ| uîì¾:N¹þÍæ½ë*$¤}Ãw‘I7»‚Ëœ«³þéóÞö€^Ã–¨k!ª! 2‚À¬B•€ ä¬“ˆoCs3gRƒ?T­®ÔÉÎ^÷ðhïŠ!ªöoß|ßüfÜü¦úÍËÍoö6¿9®Õ?vºÍïš,éLÜzÂ¸ÁQ½qk5·Á=þÞkÐªøÑ¢<ìÙP#††|]SO”ˆÅË ›jqaQ[£7L±½ ^¢šúy
Òc3tî£ééÝ«Å`L3¸Rú×|¦æ¯Ë!Þ{š5û;˜/ÍµŸzC|ìÊì´
.]]å
ƒóš:+-¯¶Ÿ&Q™6Ýâ±=}Zµ¦°Ý¯žäÍ7ïKÐgC"]†€B‘*’nj f ƒÔ›¢÷ñôGË_…ð$»'$yÉ±i¾V7<©+pÚ’ôì’«u§9PThÞ…eª-btK½ù\…ãt–$fç3T™ó–:†Ë5#¶†ä½—f(w€NµÜ!6n:„¬V‘µ×o
ÿáRø®TBb HúI:¥CÍ‘‘yÒyv­`(øã¨³µÛ5ÒÍé³Îqaã`£—ŽJÝhœ<š`ïÃð"ŒG(=zëY__y+úašÎzCÖøp]Þ¶˜QöÕÛ•/ =Ú-=IÜý¥ë=NÛwYCÀÂ¢¾ÛÿÁÒþÝ,ƒÂéôIŠð»/]w§ÓÍfI‚ò‹Øˆzéx&>¸O ×ÏÝŠ -äË Ï’wIz™¨¾Ó§W>¿Üé„¶€Õ^€7ñûËÀïÅyNÂ[Yw/ÍMÐ·pip^²¨ Z’DLu_Â–"ÙØXî iP}•Ê-4·ÎÃç‡7<2¸ËGÎ1!å(,ÅfG[í-ZQæ€v¡{þjCû¼Ò¾æÍéÉñüàñ`W’§r«õ>rá‚ýãëëÏ³|ª.Ã$	UšÇ0RÀüi)Á|%(J3š#©6±±6ñ\—Ø–?§£hœ^€B¡*ÀÔÊtµbU6ö@n<m÷£‹v2L“;pP*õõý¶Pû³Åp‡Ò,ìÁÏfç.t´K¡µ¶É=ïµð¤«†qÛ:˜QÝAØ1²Ú¿@¬ŽÏoÇ&Äæ¥$žÆáèóÍ¨ QÞð"¸“Ìà`á¢¢ªš]ZÔÍXôAÆ„6+òŽF´ªZ•…dOQßX7šú *kæ›éŸ?]õóÏðÍïT³_øÚ 7êúŒ†cíâ¦ õp\AK9Pàî÷ÂQ[Ð¬•‹$F:ïŸ @ÑÅˆlŒRøUSÇ6êÄ v1°0ß·Âµ‡“,Qþ	nè¡<©~ÿ{<¤KUsl.ÞâVçÀœ‡¿+ëî€Ž®ß#A™ÄcÞ6Æý[AX·ÆŸå8ppš…Uóö`­†¶‰ š»îØ¢>ñ†ÂDF°þÎÌ˜‘êÍ@JMÈGaœU5Ù–eñ¶GÓtHë÷Ÿd)^>äÞ"]Œp‡'aÈ0E;ëqÒ[/âÍíÍŸ6»›JÏFcÅ >qƒa],k+¸¨ôç»¸®ö®\DF4=8„­yá1æmlÇvÉ9-~Ò-\Sãœ¶Y]uww¶:'ä)Îª[÷±²ÊŸôb7ÔÊ=—}‘nih…¿>¤%
WØ‚ÂÕ–ƒEéÞ2nB#|ÀB#ÔSeî1Üéß¯Øˆ½+‚‘†$?©3ÈY:VSôƒi_¥Oz;÷P•6 ÛÐ’4}©fÆŒåêîÉ	AŸ#, >v6ó©lƒñ5ž|ð`a©vV¿õ§´{8We©¼ ‰9–Ã†.#8”œIÃäjàfó¯›ÍZ¥•þÚéàÝÝÕý€¬|8|³-ÛvmÙñï„!—û\—™²Oï—QBØ/òÞòAÍ-„…/ˆÙÅËEý¥u³Énùæ ‹#Àè+ø$I›@ Ç“)ý~˜¥“(›ÆQŽ3‡xïìÂ¶÷a9ü±»FU¹ph8Í@.îÀµzê£5Ü1œ˜wÏäŒ+.®‘×ào^ºò6¯{]´€#ƒ†ýŸP€··Cl#ìÃÿ?9=¼´© <5cu7oÿu¥Ýlßu¯Šôþ)ú,ì½ƒ>jg›ýãÙhOÐmŒQ.¨ö	Ð ¹M£÷STnVÚöçí·I[µ_/xœÓÒþ*-7À•?¥Ñ*ñ9§G#¬ïêŽ¨ÓÇQvº'bíqñWÏAÎ‡™õÔÝR3ñCG}ouMÿ
gª‚7j+¨OŠ×Š2c)zšÚô¬*=U:DÛ$«ÐÜ•`Tƒw·;‡ôŸcÏÐëïÓ±
°+bG5ë¼ùËé:‘VÃËwêî³î‹ýGÇOjo“æ[ÐsŸÓ¯µÇ;/ö€^Û{²þ˜õÇ'ÑY·®þ[µÿÚé÷38§6²Œ•üèíwwq¤»oŸ¶ÕXàêÊ}þ¸ËK‚Ïëgí±ºFÿÑÒ´è33TÝÌ×»ÎúÃŠÛ
'øp½Ò¶}³c,å:í\Ñ$Ïr‡™P1GÊYèêyR;*:†¿žâ¯tŠŽÂÜH. ]Bæpó“A>Ï"ÔÅ7(~#%¤ªê¿”‘’våð 4œÎöÞÎ¾Ëç²Ù°?Ž“ðÙjæ:÷,çòXoi‹Ž¾’Ý~ÆÉ?Ø(3gÁ K»;'r
ƒüì\+¼K›µÇ‚ô×ªíEª]ë{ò­úÝÃ=ÙG“á¯¾'7*/Ê§]ŽÊ-òQ~£åáŸh´X¨>Þ[$ì¤dýêh÷Ic-7Ûí•ÕašOÑRß$„Eý)·«"K¶ƒ9º©ŠfT€+#KÍf‰#Íñ}fíy–ÁEÈÒ‹ÐXYõGi¦œÐ™ÅGcät2#)	=ÈX/[+?…ý³¹/s±GR¥$=xPÞURŠüàc¡¹‹JsQü·Žÿç¸Í_#þÿþú†ÿøpcâÿ×}ÿÿ%~¾ÆÿÿJñÿæÂý«ÄÿKäwäW»c]))ÿúÿ/ú¯n9’_ý#†òßjÿGñ¡üZÍ„ÝßnÔ½ú‡»ÿcì+"ü>#ì¾Þ}üT5Çê;ç\á£›‡ÙNŒýÍìËsÞr(Ú€ñÆåsz—–gzï…ñH‰Ñcn÷mõÝ³ým'8ŸBéA—6\‡l¶ÌÈVûŒÿÕûõùû‡o¶QÕÔƒº>KFz»¢ýóàÔwÝÿDEë°sò’†°S#ØÀ‰‘¿DÎ ¹7é5Ó}*ÇùGÉÐºÔ5’[¼ÿP9 êkÀ× õ5àkÀ?oÀ&Ð¿@¤ÿÜ´Z$œëÉ+”‘CÞ„VHv ë%˜ÂÇ›dp›? 6LT4P+DjNäý2‚½½D—¨	jóÈq’bd”d)ij&äD°UEôþøÂÁ1L óÉ’@yÓ9ÚG(z–¨ûãê4|\ÛAZj?E·:Šv*ŸD=Ö®KÄìkÊÅ×ä‡¥ÉgaïÝl’Wd?Ü_: %êŠô‰[Šû_žž°¥3²…!ëµ)îñƒ‡Ë@m{}uûeO£bûò|ŽŽg&6‰24dáreË>.!a,9¿_5¼^è2–%¦Ø2¤ÃšJE9~sFLÇrD"ÔÚç´˜VK´Þ¨³vrÓK5Æ«FQ<î¼€BOadÓƒ˜Ñäµ²zÙSÍ‘úÎ9®{ÍNQ­¬®®HŸ&ýBByÝ¶DèªÉÑÑØãÚAþWý^5sX
s9ØkÔôÅl\ Áfâ’õ/º¯þ'Çîë-&yãŒÜW5ÛÝø5@jhO“Œ&
·>?ÆŸ 0œÄï«ÿüêv#øÍ%¸µ ~€8/RGÂRQ“4N¦Q¦ÚD³’Ùøþ à’‘XŸØ3ŒÔ]S5ŒÂ>´Áæ¡DD $20‰Ëãy'òsDÌfîÔ:(D¹Öëð¿:MëöƒÿÇ›ñf— ›¿Düÿñœý14tìý+«ZgÕmFÓaÞ~Ûh¿UíóúË`[Î@=§Ã9­n#ƒ ôXJ’‰õÓ˜{)VÙt‰@£0¬•ŒàãBÃ]ŠÃ¾\Äý¨ ëqf³¥«†ÓWƒ3iY2>—ÚVÆ‹’^ÀŸ
&$ôwäØéO×¤7LÃ³J;r¡cÁÀïð·îÉ–Ðf†V)ë°¼úÑwè@Á>çüTg2,7èzd'gOÊãT4¤Ý8ÝÝ9FâÂ”åBÝýë»Êd 3!"Ä¤^f²¾ª[Ðcpò´'´wo+–>ÎscQþEô}ËÌv»sÒ¹nßÃWÛk–H²‹]ˆ½:òx^ò,Á*Yœn¸÷Þwè¨÷€ø[["´íÁÈøÖ½·í·«ðßú[œEëÞJûízûnÝ	§tlNfÇË^¦¡Ýg‡`ëˆóY-ÂjéÁü¦<KCWˆì™™ºÛ¸«àÿêš_KRl]Óˆ“Â	UB·!çôñ5~›äB‰SãUÒiÕæÎ• 13ÞMÓ‰J1œÞ×Àþ¨‚ýMù§·A’9~åi+œN¥*dR)CP´‚]*;˜¬Úvp´©~0 4ZqžÎ²^äÅ¨N€nŠªü»xâîy=c¯*ñ!\]¥_þmÝQ{zi2“™ÁF¹%Dþý0JKé~w“¬§ê»ï.ÔÆÛãa½™7ñòðY_.¯Ñ1Ÿ•Vâé·ùÕX8þs–sa¨>C¶y™ºl4¹Oñ“³¦d>ÉZ]ÿÉV2+ÿzØ¨gë’®Íàš”ÇDS)k[×};5ýë_%ÿñÕá\|©˜Š«n¦3› 8ìU®Ü‹IˆâwêÉkh#8lÈ®
ŽeØÿ˜ÎÜ¤Óö[Ø3wïRâ¢½Ë·f»J¨­Ò¤=~PTs¢Jí‹D	5Üro¡“cõÖs¹¼ñ\|è@7xÇ;Ó×Ú¡áwrt66	wÀÓ·Ž&á @i½¸0ÜíøÔ¥¤¤)kÀOÑñìÀvÏq>z¢2xÆio\¢Ã|WsÖê¶ò¤ù.P†Š2ªUäêMÝúgIC~Ÿ¥éÔÕÈRqîþðÃæÙ(LÞmþøãÝzI `–/ûÃ^»0ë^Ï8éfýèYú¨×Þ'ê7X;»Û~[k¼­µK ÚwÏm‹6üU÷} ó÷>§Ð1‡Zò ÓÙÙ¶S»¾)Ø"ñÂ¥;ø#È·u°·×A‰X’vö¯Ûª9êÃ½j6u²¢|müëFÙ27Ê>­Z0æ[¸[íp*¨xqx²î9µ°N·Ã+	_¸ûoßÌîÖ[é¦[
j‚·I…³ jFªö6)·TO+n¦óSêQÑÁÏÂŸÊä–Å‹À\7*Ð¢FgðøMn“”:ç*ù÷ÄJ3iªQ–ä^!}uozYÄEÄf¬HjUÙ¤’âàeø>^ÎZOÄÍkœ (–¡_!$§B	ÊGùv—ù{­F%Æ¹~,p»?U‡éx	D®ïe|nU¨JgûS^X ËãOeŒÉüM¹9ä³ O\Áœ’8Fý¹1*Õ)-ÛõÓË¤B¹¾ä‹:3ž4ã>‡‘ÅX¦%MAÎ¥•)ÖçX°Éº«ÙK‹ó—¾þ|ÞÎÿbEñWÉÿÚøvã¡ÍÿZ§÷_6>øšÿõKü|Íÿú•ò¿Ì…ûWÉÿSÓ×ü¯¯ù_ÿÂù_êà)—/Ÿ†¶iXÆ«ÝÝ¯‚W¢Oëƒ´ÿ¥Û=|òàcà°}
€5½‰¢w9™wQ4	àvOPzRk6õï7˜'[8mõ|žMxû§Nx›ªïWÿ…RßL®–êìîÎË3Ë6?Î…SxoÑR¿³¿uÔÝëîŸtv-TürØwê»7Ýî_Ž-\{/Ý+¨ÒQßÄÒÐæÁýÌ¼½úîYgë/¯o”óVœ–Îyc_sÞþ1rÞ¾¾{ó5çÆøšóö5çíkÎÑÈ¯9o_sÞ¾æ¼}Íyûšóö5çíkÎÛ×œ·¯9o_sÞ¾æ¼}™œ·ÛÎxûšï†ùnÓÍw›ñæxs°ÙýùnÓºbÏDe>Ø»º"WCõ·¿D®e·±%öÊnˆñ8ñãâ$ã& \WÑyþ‹–[ýè
~w]x%‰6mýkVØ×¬°¯YaÿºYaN&ÐM²Â$·@zQ“ˆ¸<’ÇÁTâÀYÂ:i?)ÀkTÓ;âŒ8æèV›RõP;¢óÏ`¿ûæ=VûŽ•üÈô»Ûö‹Õ•¶áuS¨ 0AüTÜBÇ]@>ô…NÊë¥¾AcuÄØQÀ>bQg;…ŠÎþ!m—ÖŒÇDõ'æòøz90Î¶=ËÎ%¶F »3$Èþ’~ýüÀBYÇù¤ÎKû´ô@Ù‰‰Áuýšø6/ñÍ:)ñÍÊ†&ñÍ¶ÐOÄ¹˜òqio.¬›¤½9íožöætrß¥´·¥s©N{«‚¾4íMXÇc™¶•™nÎŸéV–;í]Æ;Âìúø&NÔw(°Õ-æî»D×?éDÊ`ìœ—¥9¤À^üëM‰Í{äÊZ8”…I`2ßª0CžR¹%yYZz¸Æ+pƒ­¸É¬W>øsq½;nŽU±U9ùÑÏ˜*õXšcåçW9ˆ'¡>H‚¶ÒdŸW†¥ÇÒ+ô´ËMÔ †jþ½w1¸É·ÝÌ7¡5=ÿ;SÈ­ƒýçs6Ó²2[­¸•nûùÍ«·L¿þ«ñrÞë_U{Vìzû›†ïÔó–96BX˜jßÔ\œÒR…sÙçgõ-ÍèsNLòùn!Ÿïæ¹|ó…¤g•Ôî£Rö>?]ï£Sõ~‰4½›¥èÉþ}rŠÞÍÓóæyÕ+6¡òPçeàÎ²3›¦xß¡)K‚}wswŒP@†Ã%ëCVœd5*¨UŸp¸Gl&°Q—$³Þd,­0{Ú^ùÌ³±jfÕäª Ñëú‘Y“û©»„A:”]E#eyÞåIR~üÑî²ùÆ¶I™”ÙÝ~ÊäÚ/–2ùù_Þ“ç_(Çlqþß£~«óÿÖ6î¯«µõûî?üšÿ÷Kü|ÍÿûuòÿøÂý“çþ±)Ša`¾6£Lk_³ ÿ±³ %Ênôë0‹1êÓR Ú1—#óØgSOóÂR.ÖºíÈÚRêŸ˜ú^WÅ¼a«³îÐ^‡z
ZÖVAG&Quøã—§Ç¯Ž¶º?¬ýx]«×Ôc5¹ìƒº¿Âe>ËÓÑl±d/Æì€ýÅí0%š,_â(y°Ý}Þyµ‹Ïos=òÁq"`y®ymDjr±ã·òzÒÎñ»:M÷N·@l÷Æí§x3ý† luvÝVT•gn›g R&X\ƒÓ
ýžÜ*šöæ¶BÅDy>·ÕIwïp·sÒ=–¶Óh<¡à
Ûãðè`ûÕÖ‰»ŠI–ög½©•}¢h$MãËõÄ¤RÃç{o4f[ÈQ—";/žÔ˜œöàâ·ÐhRŠ qrOŒóËœÄõü¯õ!\_»HéŒ£˜bÓïúšøÓpþÚl:P×7j^±4§§ÀzbÁÒóÚÒÂž¸QXK6¦ÖÞ¨†'¡úp\XÊ1¨É`º©LŒÀ.K#1m²xœÈø„ÄÏ[õt†tL¨¢p°kyÜÁ–‚i µ´9=.mlæ¸:f*òÏÛ4£º;Œ±OlX»-œã¨];àÇqÞc¸zc h4KÏ¦ýÀ8D8zÁßÚÄQ=Œ1ð‰§Á.…[¤ÀÑ|â[7–/“\¼Oh¼ÿÙ"ðdÚ?}·‡‰[u–ªÙ[Š•ÎØ¸D.½Yè¤»\Ÿ2Úõ'Ÿ;¨GsÿÜyÝÑCšß?r°ŸÂ‹·)GÁy«ûù~Û'ä³Õ“(|WtòÒtªáàJ´iàVD´à–#§Ó«RßÉÉÉ÷è´Õ³3ÿ	%ÅÂè=ÊILbqô>êÍhm!•¦#	Z·½*¿’]ð<Ú˜€ÄJZˆòšÓŸ‚‘•²+»íhdoNUI0oçdÁðü²h:Ëµ.ÌÄÌÑ\(TÝDv735_Šï¾jFbžóà8³ê™Ý;Cz60!4ÃÐšjGWšÅq8¦ˆ£Ê4ˆ³|êàV
#g—1°¦,BèñT‡D
jaTdäDEÒ$-­î¼înŸ"pÀcüçÚ‰cb8^«²‘W`	¿±‘îˆ'¨"fƒì3Õ+Ø,8‚¹_GÂâˆËŸM&R«Z ¿¡t£…ïk†ŽWüh	Éìcõdª8ëGÎe	;ÞØdví%wÉežn¨¤'˜\«’èq­*DüÐÄv*'@ßÄK9Añ5›ñÒI¸puñßrýíÄ¬Øx¤àˆ¯T˜™E`Ž™;H ­S½¤s(­„Pê~d~Ÿ†gfŠ^am©Š.ÓÍžwX†¾ºv“£ÝõLôPå)§$åé`ŠÁ›ï$žÓÕ4o£neFÀcó*6T¾ð—¦¯I»s,$i8E=b~ôôÒèâÅôZòœ¥%ß›„;”¸i3/%÷‘!ÝŸ¥-£R¬©U‰]`xÚ<r¨h<™^yaj…Ú²œÁ#LQhLETñ¢‘½`i'®)¯Šûòx§•0(` L®|šTÑFWƒ¸ÕòZÍHŸA~¶,p¼pês#ÉÌ¥~Ü w¬›fŸaïXæ`äwp§„)šª9ŽòJ„qÕðB
îå 6…‚ËJÌE¾œƒ}Y¼ûhœ›‡okŸŠg·c„_ZÊ¸õÈWvó©’°Ï()Ö<ü»ã…¸j(UÔ–v~·ƒ“¬Ænÿ†(€‡#žàÇ€õž¯
8OÃ¡ÕöLé²ÂŽÃÔ`*¦~¹›ä5³ëUË¯˜Ì‚åy  k¼ŸQèŽ¯>k UlÙ…¸~í†ÜN®ä?tQ;SÃC9$šüCÑ_ù¦Ç÷¥â•ˆ¨—f
"òmûÕðŒ*BÝ™,oïê(é;¯ºÊü N¹ý•žìMa»|ÔfÍ@þá7Ê1óÎèú“åú3ícª‰NLmèX4Çíãn÷&³”öáp~Éé¡Íô#¦'ø~<º½	ºbb×Õ¨5sPã’iM3+èÕWRs)"©£ð™îiöFÑ)Yx«p¶PDvG£9)@fÏŸ‡ó.£·cxV›¥ÁÊ/qº«+v—ë¥ž|VÊëÀ‹¥ÞÊÐš¥çŒwÌTCÚó×7¼“E™AïnwÕ!’gåLSDŠ285=öÛJÓÓããÝRóz€«›“1¢Ôá(šŒbñòH7Ýá¨{ø÷úYé®°«-:ð·€9¥£H)w*²Ùn;NþMu×|\šãË““CåÿÌ[6=®lj—£Coån‘ùüó€x?>ëœMÊlÓå˜ÂZÓ¶HØÒ/À8yÇðè9ï<m±”TÁmv6ß4Á[^+î¹7;Õ,Vú³ê§æ+sóñçŽ6¤ÃÄÉ<F:lÚØ;;ßV¡ß®"kÑÏXB5×²ê¸O´áBþt`÷ë.§ô\_Ÿ
òÑ|çMÓP*“ap;Î	‘g–ð”¨Œ¾¯öº½/¨W ¨âº œ@èI'ÓºûMóa®¾i®oàÑ¯ð¿9ªŠå‰)RøžzëM§¶²úS'§gWª9®å_Dó;!òu
øLÚQ}í½ü’ÔÌ9ÑªHÒÎECÖ
€¹›m]ïD(Ý jZà@U5>cÄ!Ø“å˜7¯¬r¿Õ	¨hÑ@ý¬"sÙø#¾ewáÿŒñ‡¾J³óVŠ®¥¼•GÙE”µ(*ÉTL;¦žÓ»ÙÃ¼g×ªn£âËˆ‰ÓÜïÎ&wÓU¿1>ÄõÏPnaW’¼™ÂIÿnÝÕTèÖÖ}9Ê½ó.yÔ“vhd*¸'Þmw¡’cn<–Ì');N­ÀjFz1_àîì>&mîÉÊºÏšÙÕßUìª¹)…îÒ¿»)8Œ“íä(Ws›¼P#Oëw¾Ásl¦( mMeXAñÇ7VK	I°Zêp¡ù;z
T<]‘yÕéTÎ£*dµ9–Vô‘«ù%WRÎ­¢”âÆ|Ô¼ÙZªuõj=Ý™ _ú/(0°¹å†Äƒµ²¡ÃŒ?Æ`X¢9+¥òDËöª¢­JÿxzLš‰ºÛ&™5(=‡ëQ§IB"G»ÑþëJ{rWÏÀ(
ý¼Ùœ7ÑÛ%ô¬hèñô=riLÇ{IéÆ·9šhPÞˆÇ_xÈ£îai‘®ùç6wõËÒ3oNÏ®ÒYÆW³uzvGS4zP±9)w•—“X([‡Ô´O©H]w#PJÀ£:í¥%´Y¿ÿ‡?V·at2j¶}tÿÑœ¶„ô¯Ðöôà~:Ýþ<ŠVñfqÙL<ÇF\èU4;–Œt…¶®Ý±Ò¼ê´/šXçØWEkÉÀúevñ—àœsv*æ¬ä¯ézb4Î¯Ï -/‡H—U•	Ù\C•¨>ñe¯ˆ§uªŒ»^6Oë"Ì±ªµÛ½·o±zÓàé¦ƒ›·6Wüm©¹k[.O32†ý~q%\%¢íwK3~útÞœËTûÉ©)P_!&QÆ$¦H+ Þò|~»%çÓ!›‡Ö×®ƒß¿½£ÆøþQ>Ë¢V¡–¥ç1¢&vzØ¯«U<ÀÜQµáƒ<ø­Ü%ËÀ>0Wà·zäÁoa£iX¬‰Qµt:.þ;Íf‘gúÎŸpJ
˜eÀI}ÿí@Šè©Z§ù…Í¿¯5ÿXƒ1ñk†Ù9ý¬Øö›¨uß‹¿“ãÃ#‘Óü÷¿DÌ‰oÝû@ÿxÏÿ†*~CÃGêÇÏÚä>"ž|û®ˆ‹dÏü²™a4ªðÉx¡ÔDçn¹ÕowZ†mâ:?	Z-Ð&`¶»ÿúóÒŽ-XÐx^Ÿìaf•N¢Ÿ'€4þçÍ¤^ÛN>]²üÏL4®óóÄ	óýüæ›\Ñ?/4÷|Nsïó[èc³5üi™Ïíu„{qúóBs7Õmî|^ÝC§€{èÏ›w¡ÛÝr?o)O|CDq$‡ãy=œÏË]|÷íâ¾`¨B¿ÓE§SRò«úU,9´*ü<çNESfìå¦üyUàþU°ñóªæ BT6‡Ï½æ.Ñ¸vFq˜±³z¾\{¡¯tFˆµÞ8ïB\áÒ¢‚TÔ7oW„mKf¼†M²Æeß¬îÅ\éB­ºrIÝ‘ú™¾ ”)í“Ó..Ìk¶Õk€‰*`ÁyiWøtæö¦×<½ˆ R 1åÊÄX‚¬j¬f$fsò£¥,°3æsˆ¡"7<>³Pt÷Ùþò>rÕ°Ìˆi@µXKg[Dd#/¥^kªá{ùÉìÏC^„ÈrÙäšü|Égwð»FY
9¦ªŸbÓqPÇA£Ä/ê"µ%	JD¨ÎîNÇ¼˜@í).f!¡Ñùjë^ýÉêÝüßÏµzëG++éaMBJcõÂXùy•¡ÔL}¥ýv£}·Êùm³Iî#kO9ÿ7 d‹o¼Vá³Zù@‹*zÅñ§fÀ_{Á>(²_e!xÎð/ªÙhÿ}ÙþgøF…Yè¨šê—p{sM…çøâÆzí1¿©øXÛ÷à“/¸ø(Æ9ÎµìCƒp_Øš- ñ­³Ñ~ÛøûTÅ¸Ôµ©þ$Ì`FÎÇN, –žq;ÍµÔyVU¯ò$½:‡É-òŽFQfþ4¿^{Ó)L÷f*tº¥)m¥ãqš1{²â/ù©FIzIíŽ¢„ƒ'µšó¹C0¨Z×]ÖXµö,D%)¨ìÓÞ°¡ÆQ˜ä¬´÷€ƒÄd.ëPLF0¥ÙåQCÆyŠ"1am3µšEýYÏëì<»	NÉ"göN–Óbe0Š43|º¹#Ê<æú‘Å6—bEC‡îÏü ùwµÂ[Z­Këínµ;ÙFmV²nr.¤×YG»VÿèêP2,žv–Â&¯Â¹˜í›íöéyÈ$Ú† .F5l ×y O9­„ýƒæPÒ«Uc-(ü:I“¦Ó„Z<O³Ë0ëË™-Æ<=<8œB>±:ühDàð]vè;”Û"ç“8çCAïü™3lyã
ûà6vRn 	½+Ó,TùKÅQ¶S8*óÁ²¹î3Ra/nû¼[~ Ì}´M;@o˜öª«ýÇáHÿ5‹r,!ï%6EïAÌÎ%-Y§¾Þº±šsÈ’èÒ“¿ç=¤t …½OOŽnÜéÍA‡yÖ=p¥Çî ×î›f¥à×%ªƒ\—tº_è¤ý×Kº"sÅ7»¤ÓÃ³KºÞz€l#1½8f‹Ï™XÔ¼¹ç¦ˆ `ç¹?%`nÑÀ¥ÐÝùÏÉOþä¥T„ÞA.l ½Ð~Šâ€+rbé<¯šû…øÖL¯‰F:¿Ó™¦™"È[YÕB`mÅªŽMsžluœÞóœæóôó\çÅÏ}Lr¸ Ssgñ™¶+ñýŽWÀ¡lï3„¿¢À|¨ªQV>ðÛ@Ã•ï±ì§™µ!•gxÛ˜UrûZ •‰t…”œ™è¾éºozî›Öz‰¿É(>© Ü¯z«:K¼®jÂ!.X0x1¿&-¸ßa†<R€Rá»(²/THFkah[ÿinÉ~¶#ÖG¨ì”W=B™ç|üª-B¨"FbF·Ý’¢N'kûhiÈ$íßÂµüÇ¹[¿úÕ¸Ejý«`í—CTÔáÆu;'úZªéÐ”:FR¢‚½/½ÙåcÇµIP†¯õ ÞCé¶šBQó@óÝ S›ði}±ï'uÄR¿¥ŽºNÆ÷´\ô¨U@m¿ñ3
Þª	ŸçY>MoüåRóçŸý2Ð‹Lís¡ÛÄìêlîOÚ™›$}«OÞ™_÷Ü—UjÅ•Ý¨_ZÕ{¬<|ŒŽVª`¸´ ›)6½97øü,N6ý5mº¥#å{]qñãt»[ŸðíM¶œ±ö«ïî VNµj·ò¹´%°?‹¨¥Uùa•ñÔ-RZ¬aí@ZX¼ÚmG“qçR,Wø9³)ÀZ6©bsSnÍžøìO2ŸÎ[SêÎßMy.£úAŒBöÏ-ç·dKËíœºAÕ¼dªsûûÄ„)ÐrôÜ­ÒgöÀ·{Vqþ¢ü‹‘­éûiõýx³Í¯y~4¸Rá$”]²nŒ«]°÷óýù•Gà;~u­ßùèD¿™;‡›!ñÜæú4í¾s7íé§1GÀZ<™ÊNvËW>`ék²P¯9ÂWÀª,×E(}<ïiç"	žû`³%·þ0Wðk?÷Túé§½ö—cñû_ü^–¼ÿõðá·ßªµõõ‡ß>øzø¥'†?ÿÃßÿÂóßÝÙêîw¿ØôÈÛƒ9ç¿¾öàáúýÂùo<ZûúþÛ/ò£*~^ì¿R/ºûÝ£Î®:|õÐC	Š”b äçµ„ÈÝo¨?ª?Ï’HmÀaÈ“«,>NÕêV>TÏ³(RÇé`z‰õ©Ÿã+”9Õ ºÜk©ï¤bÓ ´Òì¼ý4PÝ‹(»Â@ˆ8Ç÷ÇñÍSôåO®H\êcêh|†îvh{ðP<œ`ÅnÓ„ž#~øKÊÏ94´çˆ>´ŒM(F8¥—Q¿Ì[.ýfQ8™[€DD»Fqœ#u8;ƒÑôSc7Ñ0Š4ãQD5¨ù;àPA®7—B•êÕ»8éSà"Yïò–DzåòT¾nZî;Á„,ŽÏ©x?Êãs,ÏoÝ`2Ix^qÆ$Ns4P&jHèH¢Ï@©gWh Äô¦`ºtÅq2’>ŸÓù,ÌBø;*Ž”FÄ˜‰¸¤õ‡X–å<ÇÍæ4µy0ŠS£G©œÝCz†€ !p–$˜úÊ›‰ ÞŒk¦Öd¶<ÅbÐ™ÙùÇ8—p2Å(»c¥qXÖaæÓÀíÃ0§ˆDcÂDÜú³+šaHÏÿá¿Og!Dð;„B»%ëÏa	iJ˜ð=öø¬ð$
ßátpÌ|ø®/Ã·ñ(ˆ‹óžã§Ó`’Å˜F« |õj}¬QÞÖSÈL- @ÜW…œ›È°4?µ*ÇOì"ú„1Êš R]Æù°Þ0C`”R„Áy"©öÒ~D/C„”µO—–:—!F÷N®ØÆAc3<tÇÓ†¹õxv$A›H@ó´ûÍAÌîÆÝh¸}
‘%œÁÊ¡|?Sì:Å ):7"{9FñN²è‚Âª3ÄðúÁž.‚arGœg˜¿“¯èv’œ_"Ö­ZDà¤S<xlˆ‡ô¢lRxÖ,Èã³xOc~lUž’»K> Ò÷ã¢äfL?ÃE»ˆ€W„ÖH;óßþ{Ž'#€»hù¬7´7¶nÈQMçX€v„n·D²Ø1&C¡.Š:§<ã(ÀdšóŠÂqÈ¼òbõåæ Šã
téºuà ï–ÁJ€Ót1“Ê‡€.„Ù‚(À·r•Ó¯B&ø-ÖhBû$o˜"jÐ„(1¡=Ü­B/Ö›^¦øNè$ßV×ë
Ÿ8Í¦Äk˜÷âæx‡‹˜½ºQ‡=Áø…„I.p_h¼Eç@ˆëæÄã…í6Üpm¢Ž‚(æÔ¹ˆ´^Õ]6m0É»«—Cô—–	KìÌ€þaj?÷@ŸD1{â™!/¹"T Y{Ô¥ÅŸú1ù§A3hgl‡CçbœE²ßcy´Ó2 ³"{Gµ£	þoð)ò´b¢Ï Œs~2Z^«	§²7}òv%Q:ËGWÄx&ˆîHbøÂŒGûvLvÁ7½
*ŒÔ‚×¥BzÖ?”B=x?²Y”—Q¸ÜØ!înÁ%Gø®êùšŒÃd6 ñ.A¥ËS¢2ÈÓa³‘g¢ø„oï  Œr„Ë‰ÆFE ÆH}¾€IrŸ¨ ÌLËT~¨LÏû îMbIÃ^‰´×›eäå£Á@ãÍ¤gY4é	P¸?vŒ{½˜Ä=
4ž …È#˜þ%ã?=‹¬}–à®N¦hÌòIëeÄìÎnˆÎ‘F”"2ŸDŠ¥Œ¥±Hð5…ë¥§Ú¢„Z™A¢0ÃGŠòÙš(°v7í²Èò'Í¿ïSš•ôÞ£¸Å³`òÌ,‘Ä”„^–• Ô`†§k#°so`…täUš[1¹)vªè†Ç	Î¯¡"Ð5ÙÆÍœÉg‡û2#-eD2AÁ	~t‹ïF”¤-‘$ëÂaà6õ¦š”iWOØ0°²§q£8Óœp¬¿ŽÂÍr÷	iÒ\(|?%öŒB]Í‹4æp^>ÜG$Í¸±ž‹z´C,Õ›…Ó{Uq´BmíafÁˆ¶d®TÍ«–H
,	àyYr„{¦©Q Çƒ[(D…žE¦ý0R€Œq.FS$¾C/â°Ù=®5A¹Ã¡ã’ä$ôÃ<‰§1_:éí«Îþ6ÚÞ9Ù9Ø?ÆÆk-LÇ‹‘ú×NScñ”ÎWß¢ûæÍ•ÂÑ*k,ps½áwÍQüß@¸ºÎ"5äëVi6!-€‚Ñ8ÆMš¡/(aþÎÌ;u6Ú6ÊøfL2“¬/:`§œRœzöJuCLš°fØïÃ‘çü<AXnZÕ¤C”×èHjV¨©ÁÌ®\ó]9L¤Ð¿HkÌ’ÏM²Dsæød¨úá„®þAI	rØ'À!5ó!§Ó ÃD’n¥+4d‡©ö ³`QK{,•¥Ï(²Ðäâœs>`'dâ«Éœ”b­W‘4H¿Õ´ë¡F»­h3:ªÖK´ÁÏj²Q,†Û•˜1å°ð=9J¾6›Œ·;<§°‰â>÷	MHK`þH\!œ6ôsæ»{—D‰€°ŒŒ~-@]˜G!jw€?GìlAÝ)Nx”»%Gô©G-ìÁe 2ýy›~mxçM$•âð[ÄãÎW¡3;”u"" çÍ€:xtd•àô«í.QOÃ<4(Â{0¡ÛÎ* ½ÙE/Ff¤"Ða!?½`õ®Ìe4™“€=ºˆŠèŽ÷ï¼H	f	D¢„n:@äµ†N%*Ñ@YK]Ø#™!í
9ÅŒ3(‰/"ãCY*ã†:ÅÉ4tõ(5ù5ðë—¡Ó&çïµÎ&vœ‹ˆ @B‹t 	ó<ª]’×÷S9òZ :IŒy¬îÊá…<bkŽ
€ðEb×(C k ¬Ü(E¨_˜‘Ù\aÆ¶è–ÐøFÏ¦pH¬ŽÉ.-ê…’®
Â
n¸‹±ˆÈ$ñ€Ø¢MšÀæD,yW	Áµ„Y³ž)©lÀŽ0â’Æ-ß¯Ïa‚/J’``^?£Eb¾OHœNzBdÙòš0€;k°²Ë;ƒvD’oQ"Rb‘0fðm01Ö[Jœ][¨zjž_sôÑš¨Ê.9b± B˜¼ŒyÔ.'û_K÷²²†1E¦tpöSDÁÛ»…²‡¼Üª†á=FQ5ÌújGošíîl$ßG&È1}êiŒr»A¿Á¢dH)lçÀóðM.i *[Ú¿BëECo%¥€·7åÎ“@¼Ití{³Qh¬mcÜ†H³ð!	O/@ë ÚèŠ…±pœâ‘VoÇeeò¢AØ3:&õê,‘¨Õ˜;
U¶b„ÜQÃ>„·†·R+D%PcÒ‘®´ÖÙúJ½ûz8 r>@çzïÂs&ò{áO°	[@®ÒÄ˜Å²„TÉŠ0 5œætÇÏêŠŠ£!†e-&¬"¢Û	‹’[Y¯> š‰XÂWeÄ¡ãÉDaÚ
OÊKE1Ca^bMˆ¸h±	j…YÔmðÊ¥0èû©Náár`S”ÕH1#
O‚Õw ¥F#$ñIÓóèŒyk@<ŽgTpÆ¼žBt	‰	sã ë5ÃY×‘#ó™pûXú}Þ`¹‡GQ¦ÕQ+­ÑžÛÁ-²×–o©í‡0µÍ†0tË«uÊ„Æ#'±“J6i4

†1G¡Ô•¤Úb!È3àyÚµ™®ÓÄš;ÙdSmj²Ke„§ýZ9!Å1 E:•ÏÊpô/ÓKÔZÈMø°¾sìÝ<(^WÚÔ¢’9MSÂå¸É=¡Êw3Ñæ¡vp7“Lö…)ã­lgÿZòl[KkÕ9†õ;‚„ÑÓ¸¢ª¡i9zŸ¯«œ&){Ùv©óQ¼\ìIÂç@eÛØKw•„c~µ9À7X‘nÏÎÌÖ˜ÊfZÐ—…6Ôµ‚‰Ù®hvŠÞ¸”cz"7œÒåÏ­Ä’ºË¨0@ÛÂˆdø4›cÜ98^´Pj¡˜íÕ¤j_ÙÄïâûµ)7ËÉ –E¶ šûŽµhcå±½ánñ\ü«Z¤{lŸŒ–q»² ÊthV#; Š±ùœ¼xý
ŠR­…8´= ·)¢µŸìÁ(Â*.RVZ´,Çx…Ö¡~àØ.èQãhªM’z|§lR=ÈL>KFñ8F¾[Ó–²Ö'Ê)(- ¿ó©@ã„˜eàê¤°ÊßgWþv”†ÔPç Ä#¥Í‰.Ë#ãX<ME·À‹ë†¤— ŸG¼²@»‰ œÇìÓBI“ïÇE8bþœÛ-=»òuB:`ò€˜<&Ó8nŒh¬ÔzÓr<( Ú¢/‘…k£Ïºf¦_Åm“³Ð>o÷1v2K¢†|’z6"´OïLpŒ^|:Œ¦ÌaxÁ—ˆ6©p¾,Åh–³QAÀ¼ˆ¢Ë±+iPFíã°]=±dYG¦jŸ#ðd´+„@ß€¼¨D(.pÌŠ™]ne1ËgÂ!x‡Q
‰t™“#Ü`#æ,76w’…Cd©ìš"“¾·p%è€Î¢a84ä~ÓGlƒ€½Ä†ˆSiÐE¦µ±iÔ1xùÊhŸmdìßc¶YFÔ·ÌÑ.	ô‰QM8¯a<a=	W·Ì¾‰±ÃøÙ{qÖ›uý)/Rq%vìðæX%+G+§RÇ$.Â)‘ïÅƒ<F±“õ52òæ(;Ì°¤6È„hÙÅ	Þo!Ñ~Wì÷`¥üˆ/ìsÜžp«æMíÀuW®ã~ê²R@‘3äÓ ëöÛG‰I›˜á0zÃ$¥çÈL@·Éi÷È1
ÁµWƒÙ¸ùˆð|.·CÚ£2BØúºfAovÂ1Eã>ÀìƒZËá¾kj¶a|Ý×ÿøÇGx§‚/ªTdˆÕ(¢QULúdIô¶A|=z¹xàFTÁ§•ì¾q#p±â³„C#ÿ,RÆÛ3¥ÇS¾É„$¯+ê€¼ñLPAlÍz1!Œä
öHHl<åiP¼¢Ì
Å1Þ¡WBA4SaYÄÈ´â@RoªwÕ,ÒY&‡£©+)‘@ÒQøvE\’M|ÝÙ§š1–Á­½+›)+3»Y:´ z7éô´œ{ûZÇgm±AÍå@rº….½0áÏwsO¤aæh3†€ Å6.K<W“é$Ÿ€ÂÏNYò[3ºk
äCÄìíõg¶ÐØõ8 dF81´r‡ì
&.’#úB¿Ø E‹'ÆgÓý=ìQ¥Å…}kŒJýýÏ@síEL;®ŒÍí1Mãœ.¨oNøDµZ¥Úš]´†›ƒäè†bÕ[’ß‘Ùmu‰@_„Ãñ	ùlBûÈµ¡ÐØ˜šÂCÙö´l'’ñk×Ñ^À:×Ò_TEÚ(ÆŒÎ‹¤èuÛ‹6Š¹X«IDAíƒ*Œ7W$n:ÐÜed›ì¡ë$¼²Õ™}6ìÊ12V"¥‰òÑ/Äb×‘@Ø.0Ä
ëW‰7ðì“Æ"o;õ7AqUêß—Só}à¶²Wæ[-*‹VH¶#Y=Ý/P!Òˆjs.NMÚ«Û!-Ã‹ â—MØ±Ä9ž?ì¯Å>C´%B;”Y‡{‘æy”ëH‚ÐúÈ
 (Âdªƒ˜4ÜûX`õ†Z0nôy+<Ò54õ Y»ìC3‰¢$m´!GvfýÆ ¬ÍALWl‚'“"TyŠ”£¨¿¯ƒ¹{©µU'p2¼Ÿ½µÐ0r& Úp!5Ž°@%¸Œ"5ò{'z®ƒ½´™K©~]×Â¤ñ±øù®Ø)¢Wc§ô6A™ëxyŒ{#ö%yG’Ë´„%ðk(R‰tî(Ì³	­ÂØ Hñ!YœÃwØÏC#+ø2ãï¼Þ9ñÂõ#|íœ¢÷øf(R}QjOØMD‚“wä	:Dß}0±3²êk©6ë°¸1FÏ
òco ÂˆÊ.º¦/ÒÑŒÞ†@iÒ¿óÜ‘Zp\ÌIPÏÏ¡Ñoë™Ú-¢ÅOsÇKmY¾Ì<Ð&TÍˆÉrTLÀœÒü»žœE@pKB]eIûõEéeE]O	©lUÇG^zøŸ^‘µiöB#t®$Ò!Wz°¾O++h@„;\žºÂŠ°Óçp8sx©o(©0ÈÄ(°0ÊŒ›ÿp.#tzc¸˜€;M„"šWi+ViŸ’È2V >KÝ2ãŒé$€ÚÜ†d5rè¯r’%Ì‹€¬Zû´Ó¢Gë’÷Æ“0‰µ]‰©Dµ©/~ÏÒJ¨ú³Œíg:dFù‡=@8K6Z»Ây–µÿªk™¨e¨¿',6Q}–ö€ƒè€÷ã¯®¢0cÓ­Ó„9§cÒÂä„¹UÆ!Ö¼3ŽÉ†%6j˜¥€8îôaˆ’©¹¸°n‘4ÜO&äò!az‘Ý–9¼{8dF"GÍ5>6ªñB~s|hh)IîÂÅÇ)GˆÕ®^ž&pÂp=&êR®OCäký2b1a†$Û°VQa?ŠÜ¡Ž°`$aG’Š
b%8Ág‡ºúÚ¥{tÑáX%BòB¬V•te¸p„¡¬\j8ÎµQ‰Åi¯æ$™±:Š.uô` a#,QGE(Ú®ì†°WOŸy¨¹<Fä•p‹3- >:³rÑœ‹&Ú]g>#Ù~öÌž°t„N¥ÕbÌ>ŸGEKÞAk¥vN}á‹FÅžz˜>3¡Ëô!NÀµzf[˜Q9I/eà&xWÐ€mj™ë<Ñ04HŸ”æ%ÜmÌE%¾xùÇ×;Æ=äºI„ö«lbz@ô·ÝZs®¸!v¹{ÈåX¾þË
9ªH1k]¨o­Ã7ü~j
g•yHP9Ôº˜]†sw·…åa]5ƒ$#Yä0Í9¯cn÷†Üœ­6n²´Ñ„1Y-ÔqÔÛ0,Ãú­sÄdö6çž6™Ë­‰æÞšÙ'Q”5§iÿåð/ò§w˜ààÌã„íìŒ(¨„÷®Âîû„`¨g„ÎgSÛ19&ñVë	{kÄ|#º¶C&ú¢J°†@ÜÐÈ1>:D=®Ù#.ØØKª¯^ÏùTÐ\Ü3ãÈîûÞ”)tÂÐzòÐMÅáÐ;˜ÏÆ¬dP­è˜H§`Š¹¢´j8R¤Q3‹àn¹3iãòUÝxi8ŽÛÀ4¢a
ßñý+q^å–jÏ±qysõ%µ¨8ìzÈ¶è„ÂÐû‰aƒ¨$˜g4åÞÑ"C#=Äöç-¶ôÓÙÙt0ã’Ù¹õ:ÀÑ¤£ÞçAx‘RØ"Iá¹Î¶q#¨tvƒeO«å„X¡ÚÓP5o£¼¸ê`z5!Y1å(:|†P‡aõQ˜çNÊG£`–Ð~ã™Ém(®xtABJ¯°7…¦æÂèYòEïÑˆOœÐyÂž ˜8¥™p”M#ŒŒY¹í…™ëÃr`ÁÀI	¬\€L½?Ciš·Š‹ŒË <ÝYB IÀO`<	W$IˆcdÔd³Y$Œz‡ôZ(~‡ãvXAÞ!JE¿ëð ÷Š9‚cXVÚÏˆ½¨Ž†äIÄºz]ñö2á‹-lMpûNª8^(ªHÛ*[7t<ž7A¤@AXêÏ9¡ù|‰.ò¦‡V¡ Ÿa¨bTd3âlœÆÉ‰Ô-Á×”ñŠÑ
4•Ä„Ô”C%U„É ›Šx]šC®Í³ˆÔ|ß„˜s†a.ãP‚Dwž-)‘J×«‰¾h|8»õÜ¨œdÓ²èî®r¤}ÎÜÝÌ81™†z(ç&JÄÈÀµŽÚ¤’¼ÓÄ°‰¬vxœí$¾jMgñôÊÈ¥kÐª²ZiÞôg˜Û1ð”Ž£ ’…ñº}û¶ÞT2%žE®Þ°®¯æÝ1LÁŸ‰ÉµhKÙt°„N"ŒÏ:IÙìÈXÍ’’ÁØ)„ÂÞ•{·
8)I×,y{;N{&ÜÌ5¦„wyÇÑÁ^Ý„-¹ówô¨yK/Gè…A„¾e.8­Ò£ìHáèÚ{DÍO×rl„ø~èÎÚkcö!s–"§dðª!¨”¶Ç`s¼(2
£ …Ö	DÜïGd¹FIÉ	…„*L …vgö‘–EEÜŠÈ½u3õÑÁ\.âtD‰x´¸™Ô!£Î´‡ÑaÆ6ª.ìeiž»€$DcÁ]`ª0÷œµ4L9×ïYyy83‰:›Ë²pt™Ø9*8 þUˆž0çDw¥ÑµæDZç
š’h°QÀÍ'f	ºEÈñŽJ	~M‹vëÛÖ‚Ö~™“HTkÎ§ÖÁé`Yä†Þ ŽK¼tÉ¼©ÓÎg%‡3*8	â“ˆ“~²H³=ërkÕ“à‘Cñ@‰¯I‡M°OL»;HŒjÀ1#œäfÓAlæd7XÝ5dy±&œNlë+å<aTqº°rî[¾u”ºCkü¶’î™Mõ$QÞú“MÐQ½q`³»ªbt¥’sI8}!(…‡`ð3 ½ìêÌˆacUUh.#”ºœŠÐ‹,ì¡¯Fû³Ã©¤(!™#ƒ:õyÛrK¬ÎÁÙ<m5³q»â/J/eÐ•8©YÁúÇ¥^`!Ò»U·Î2±s¦tBˆbC|Çb!É÷Iùqwä>Ô¥ÈÞ[÷aG“¸­)#e¢èÐ7]Gçcý\TFÁa>Ç]ž 9EÊÁÙ2#;'Ô(#ª.À·EÃ®/$~˜}eÛDÚ¤¿@ÿú¼(M&ÖB„±Iépfm¨)9äjý!ÓõGÅ9<FS;!ŽLº)©-Ù…a_6…Ç1?³ËÍ„½°k”·ËTd Ñµ:`ã3m[,y[	ˆx\µO–·žÝs(y„¬lÇS;û^¯¿‰yL1º—Çƒá$ÏãÄ(·geú6ãvN
]Á¬Å­[³C—”¶—;ÖCc†á‰„¦ü’]J¿‡#‡-gR‰Y%¼¶aàdðå1ú…ÝûTëÂ=	££ë	Û¢:†Žx3ÑÙ‚ÈVˆªË@™Áåq£¨äF®ažEÃ6gåR$AÚŸÜŽ;p1ÞãÄ«³+q
˜è#Ë¬Þü+?Æ©sî-W­ê,ÛÂ1JäM]?À†µ¶Èú@uÆÂ¶i:ŽÔ^Fz¯“+·pNª„k’A@J)‚]ÌÅøGå˜ì ¦r… ¶b´	ñl4O€|‡t­&¦ùÀ„‚’xƒk—›ˆöí#2‘·ÖÀ®™« Ø§Ø%Qz4w9ÔžµžPDUX’Ã Õ¼˜·•E-p†ªb!–`Ÿåˆ(ëe“R5:3¿À T@’,8 µ?£Ì©-^L´+ú9ü¿Š±X¤ôWî8åÝ|Z§vžï™ÇU³F½bØó\¼	Ø™7×FAÓe1·4éº­7à²P(˜ <Àæ&35(d¶€N@Œ
%ÄõkHð…î¤:
:¡g±G”œž ldüN) Ë¹?iñF5´@%!ëâ¶)·NÀ“–¹FÆ#œénaî(¶ Šº~Y®Ø€iÐ|ÿÐ"%NØáÆ}P>šÉ±µ 
''	Ý4d†9Ó“Êa€TTE×)>êä°’oFLå)¼‘XÅ…U5Š—ó³¬¦²€È«¢¥SœïF/)¡ppS€±˜
±…[!|7zdkM/ 0Þé*yHêw¥ˆ8I8LÍHö»:¦ê¢ ¨ÈFDöV€ëBÙ¡,–a2¨²2ª”#½¬ª¤¸àÝD?±Çæ#Ö†\F ac«x À yÓõÆ4Ÿ%·µÛA5ƒÆ‘+Ã]krÂð£5Õ'©f0•“ |ƒ¢{ Û¦´ë^Ò61p6ÑYSiIº­$Žrg-Áòµ4øÄc–q†‘-ñ8²õüsZ çbŒÎ§eù´nõ¸ 8]›tÐ›‰ƒÑB5û{ßÝß@">`:£8ó¤Ø¸gé~[ºc¾!Ç˜õì­Ä3—¿R‘¥)ÒËÌVèð3 -WS¾Í-ÍWLc‚E93v_B/¦îQ;ÐpÒÞÔüDzij*„à«^V•.ëE/£4ƒ{öÇYÿ&òÂ ?Ò„ò’3Ú
é:vÒuŽpí2(P²Ïá*z¢@0)ËÏ‹H²Ù¤t3äPnS-¥rHÖ|™Åj>Ù%™Kà3-™o""o°C›B³KN7Šä-õJ¹ÈH©ùFúáÇU„cÎi˜‘db³æÈwœ»¯+Zr¶^Å!ø•äÐgjìpê!or)Á´!$WÃ²{Pº÷\nHÂ}QRîhÎ'MD˜ÞN/£±|1 š|¡NTœÊPž9¹V¾WÅã®šNåŽ€[Ö/2ÑDÜ†‘Øâ,§Â…^hÌ|Æ®’¿¼õï‚T'‘XdÓž8/3æw	]_Q#Cº5Æ:‰ª¡•'ëÿ©±Äïz„ŒÏ‰ÇáTM.xå–äbÌ+ë‡|KurÔ-¨ŒºE¨±àQ†1Ž²sÆ·ÞÑ·y×5ÄÇ¬£¶U^„¹³“hÊE.w­H„#vÉGš`p®i€q;xE-=×ùìkagûÕ]ªÈØ§,J6Ã“´ Ò}V°®Yâ¬¸eŠg‰ÄçÑç%YŠÅ¼Š¹Ž:w	]çÌ	Å™ ø=õO…‰%åÏ°úh0À«’Ø,ú6Rž
*×ž7I34¾ÏBJ>²|Ê{Ÿ'H{¥!D)ÜñíÅêºYzŽÄS–:!tœ½eçRœÇ¼ÚJWîŠ±ÚÞp3c|¼`ar,59’ÏŸ"Réorú`JéM%è>;×J|àêÒØì¾õ‚4˜+Yá¨™†l¤rìáHê)ºI¬^nQ8Ç>IVÉúzKê²–ºä\ÂVÇ4«éÀ›‚ÈˆwÊXt)' B/0i§0W-æÐVà¤46f<Ü·YnkÚD¢ Ó„ÛèÎÚ”ß39$^K[ÇÝvñRñóôÎÇ0ž¨ïTãpü©à†Zq}Ó°'Bœ2Rõõ§Í)°x¹'„¹Å]“”C¦Eä s!çH‹[¬¸) ­2"jÏ4/uî”ÈñDÀ
‚’¾ûU)½có\Ã+-ÈsiÈA¦£š-øf+´yUêŒ"ß1tšîo›ìrjb^=S¹
Ü³ËévÖŽ’]Ã”Àª‡Ù¨UµÕirÍOåvH¿„sp…‹€KZP\ž¥\tŽv§[ÎWÜ–}áªD]>1Ø¥³?1Ò›‰‹ÕìŠ¬O5‘L$’+m	 i$Ö)v¿ÇS¶¿I~¤¢¾4X•JEî‰H»%Çéª);—hÈ%YXªë><ÞE”„œÈI5ÌÄîÏ-ÜÚ“u.k[£s®™Bîþ	RpK¦@¦Ô\çXõ9«-­K£†›ÌNp«¢œ
â+–QYSVàˆeð¤4UÎR›œê
ºH„FL.€ÀÔJ§2Á7©ó¢ûKS’”ŽmÓàRHy0Lš¢°%…“ÄÖÄLC£Nè«N›³VXÚ±:²nUÑxÎŠG„µBYG¡€Ù¢³(‚dl«„0%Ü+Œ©\¶zßŒÐp)RpŠT#0õ±uéé`äªMF#²© Xñð/EdÑ…eF<)¦8âê®È´	 €ZJª 8!ËAÉ¼Í2OÆò—¶¹ðÄ8q°*·2ð{2÷1
«êc:'°á–BÓâ€29wbwAI–ÑaG‘Â[×@7`>9 ‹ÅfXfyeR‘¹Žü :àcrÐLÛœj ®‚LºFÎ´®-Dn”TgJ_'ÿa"±ÀŽrQ^«
èÍ”ÒÑ¾fnšaÆ¡kÕÕþ\M©¤M'XBoðôã¼`ÂfT“ç²Ù+þ,ø‘!œ<Õ¦´¬âÆÀP5¬?’ÅÄRÒìª&Oj–ðØOÇÅþ`uNôG†7LÅ—¼¨¾°lÛ¢^¶ÞKVÑ)„'éÅ† ùá¨óµ–¯t™o•XrHxµj02&‹žÆ	èTŠ/0_ÓJDjÓÉN¦àà	Úbƒ“ðjLqN©u(È^U
)M£í«R$ðŠó…¬jô¹ãa³lÖÐ%Í©¶†W¦$ÚNWºÚðÚ ´$}ŠŸª“–©‚Ÿ‰ç‘4D+Á;«?Siß¾1/q©ü¸ÎÌ0JqäÏ¤_5´¹¢æý=tšv®i"yg+.°8RpnÙú\ÓAÔ’µÀ$–ú{rí¹a­îP{a§…o¦éø¢a¬KË:f?“©AÅä²™ññ‰:í„ê‚Œy`ª±iÙTc¦ñêŠK`
Ð6#"cè²9iÌî®§S/T
[­o´°¸Õ±yÆÎû !æwée®~:Öò[¡Þ›(úR§L­jýÊÙÍ¨2»3ùÑN¶®$ŠúqÏ„åë!ª\nWº¾l$²[×Ø†æ÷mYñ“ŸmÐ„Ægñy*åtjYg£i¨ß‰áH½Re.Ï$ K¤èL1´TÐÒm7a/%»¼kþ‘	âfTü¤h*Ò4·–xÖ'®³ëøí*”uA£Ç*Z#È¤`‰Ç¹³ÐÌØaùA!S²Tä¹:¶šm£g~’yèÂÛ%£‚“£aá%æèL£æ'¹ÕŒÖï·0¢ÛJ™ø.E5ÈtÑóŸhÊb‰”äP$,‘QòOhnä½<!ñ©•Ïj,œ¾’t2–Ñ[—ÃÖzu‹/pÜ˜êdrÅ»Aú^

Ô1)t%"è¸Zk]÷o°ºF`o÷)¨e¶çó7Z—Q±8ˆÀ™­ì‹ÄsvãËƒ–:Šà„aÞ¯#÷í¥‚y·iÞ[„Ù*È2&l¡‡ÑÓËž÷b!Ý3tçàÄá_*p{ìÁÁõa„¶.×‡’&q›l^‰Z4V/Rnp–Dˆú˜Q2¢7tø9Â<jÄ21n·ãgÒè	{Ã•QIx@lšÁÒñ\t‹d†…MäW`‚Ë%TKƒ&„˜;ø]…½

{U³.&AX«§y×‘jàÛ[JÓàHj²Ý96ž9OîˆÂ­ªô3C~¢8	ÖPêáM`ñ¦gdvÞ'”výÕ¢Þ|²ác½aª½ÙŸÌü‚ªù9x­Y»;ÃÒÆ¼¿âáT3ˆ&ð“UÁEä¿g¶ õ„îëx~}7cŠöå;Uí6¹!Ž^³;Þ‚®{hße#»t ZÜ2‹À]=›‰-™f6:7pãþø¡$õz8‚BA\Â¬e	€N+"\H2`*nÔ	Z–à2bƒôâ!%»‡-Î¨ôF‚Ã™Ä½ìuÕÎ±Ú?Po:GGý“ïÕóƒ#üB¼8êì5ÔÉýÝýÏ“îþ‰:ìííœœt·Õ³ïƒÎááîÎVçÙnWívÞàËIÿ¹Õ=<Qo^v÷Õ‚³sÜUÇ'ì°³¯Þíœìì¿ €[‡ßí¼xy¼<ØÝîÑUm:ªÃÎÑÉN÷çñzg»ëÎIÕ:Ç0íšz³sòòàÕ‰™|pð€|¯þ²³¿ÝPÝÔýÏÃ£îñ1L `ïìÁŒ»ðåÎþÖî«m˜KC=û'jwVÍNŽ&m5tœÀßëm½„?;Ïvvw`¿ðY­ç;'û0í]‡g¾õj·s¾::<8î¶o! ?Ú9þ‹‚ÈÆþÇ«Ž»0öð¥{ËYs Ç„ËUß¼BëÞÝö67ª«¶»Ï»[';¯»l	Ã¿ÚëÊ~Ÿ Ð ³»«ö»[0ßÎÑ÷ê¸{ôzg‹öá¨{ØÙ9Â]Ú:8:B(ûŒFZ\n»:j™)Æ>bP÷5âÇ«ý]Ü‰£î¼‚µ"–(K~çÅQ—6ÚÁ‰àÍLOÏ †bÄhPøÂ"Æ÷€bjï`{ç9‹ ÎÖÁþëî÷Ç»+°Ïe;ÏpcžÁDvh>0Ü%<·íÎ^çE÷ØÁ3G¶êø°»µƒ¿À÷€€ »¼UûÇ°V<Zø@€¨œ1B@ääs^ÁE@Ü×ˆcãgîdWíØe¤T»ÇˆÁvç¤£hÆðï³.¶>êîÃFÑëlm½:‚û†-°ÌæøÜÀ}>\/]ñ£í@_2ÂÛçÝWGEÄÃ‘`$! sÜâ¸ÞððÕÎsjë¥›ò®ò÷ê%Å³.4ël¿Þ¡ë(ãÀ$wdO`uAö‘±ïÛ¿-‚Ob<.%©¸Ì«ï=“ƒG"Ûð{Säƒ#mí‹~,øŒR,vÀÉ+\YXâ›…
O)]ŠC„	£K6€Î°„ëÿ, 
¤ðRtv,ÇÔ¥œ	Š‰-ïé„<@›ÖYžŽ0ž
'³ø2z|œ¹WØLÌ’z¹A6±Àß›îÌÐRø™¢G‹ÛËºVü ^Ò9ÏyÐþ¼äw:´EÎu¢CË¿G–·ÂªL w<Hò®é—öUbÎ ON‹‡DÖqNyŽ9pîTü/³¼[ÚÏH>åF¸7$‹º	¿X<ü§³Y¢ç6Ñ4ÊïIøñê—UIëÆú‘4Šk`Pu(Æ@+¾êÔ)#ùë˜À²Cçá —†36½Çº1HTœmAADN˜=¿×’{/b$‰5Ó©jè%&HBž%Ù[W#õ§fdš*ËbQ“””:¶/èê9ƒ™©íJOÙ¢l*Èõn'õ×5ÞœõßÍ)H@Ÿeq4@JhŠ‰¼õTªi)ku«®¾ÃêtOa‘êô½§<î‰¼×ªÃ6¼ãÞ4ï{‡Oµ>(.Îªö(.”’ÃÜÓ/$ág¾ßÐjLÉ´`ã(8ýhÕO7­—5›VõØuš·«†è^ÐI:¤³dÇÉUiQÕâr-²=6yµXAƒ`iã§%VœvU”¼`sç	^Ê
^Çk‚a‘®]¬&ëªQèpñÚD6û‘uóK]9§™ÝKVÙ1ò!Rß§ÓÉf»}yyÙ:Of­4;oëpöS˜PC÷0éÆ-m‚ED˜v’ý›Ÿ§š÷hçËÒ«Fá[!á#W`m.£œ¸z¨DY\cKCS9ýØJˆû‘M¹£ôŒ+-Š²±0ì”ê6r±S·`/®‘”ÕïdÜ§7¾‰%<äÒÌ´§gÇ»¯Nº»ß»šÌc:S9N5½ý½ø~y·eÁï³eDË£ŽÃ†Iïz¾Í&)ÚX»ÃõîºÍGËÒðj‚æFr*ó
¡žÍÁôüÓ¯Õ»™Î~AØ9öN¥$ˆÇ¶¥™zè`LG€•,´^ûX¸û‹W;¶ú±<ã@š‘­AÕ@`¼8Kß×LÜ¤L™bM1Ô’Fà^§WÑ öjû
‚~Ñ/ÊêÓ…ú-~n¼^X‰+€it±2^ÍºñMYw¬°bÞüxn|êþÅá—g%YBÃD«6—_Þ†K,½¤l9\@iŒÉ‡#ÝÜba@$ÜóáÊaû.µþ"wr%ºb€X–¢3’g½®$ÙŽËþR^'ÞQÚ&ÏYÄ3AC6çqÛÅU43¤¼™#Àµ=‹ïÑ¥ŽE¸”ð|º[Ç­à†ìbX6Ïº‡QBQØ¯ðÖ`IÊ¸ÁèaJÇÂšÊ£˜c¥ÓÉðª}9¼jÂ67Gç“Qk8àt~óÏøÓO{í£ng{¯Û÷¿Ðkkk<Pøï·Ò¿kü7ü<Øxøè[µ~ãáÆƒG~û­Z[¿¿öíúoÔÚš÷3C–SÉÓha;h6,øž£Ì¿ÿ$?wÔÁ«m|ø-
Nð±ç>Š`HD´•[¼ÞnÂ÷Ýäâÿü?ÿQKy”“L¡ôÂ%	UæµP?ú#I5‰’‹ÄöÓ != †=â7úÎBíÄ´d@Ç³oô@ª jÔÙ‚1˜¨–9¾ÃŸ ÖµŸpy8ÈÁÎ¶7RÂ2bÂ` t€‚OgÚuÊzÃ•®pLŠ6®}øÃÆ\ æéIæÉœ¶Ó§)ðº`5þl1M3ï(º[ßø3t½SMJ
UB¯¦ð+ÌÞ6nëmôö™å–ã½†:êl5¨Ñ‹–•¡êEHóél0°þ¶81¥@½”2
Œ¤ÓœE º§‘æž„šKøÍO3	Æ¼w/õaR­|xïžlKC¿æâó™¢’'Y±š%½!›!b¬Ó"nÇu	R`ÜÐ£'4KÆi 'ŽæÔ»/ž—Ò(¨ÀŠ‹ÔBÎßçêuE,ÂSÐ!7Ï;-Q€u^5t€¯‡ì•Xò©ìÆÉì½z½÷þïÿf…sÜN{ïØŽÂ\ÄÁ(Ga>9‹ðÅ”Ã›ò¹Ñ§1ˆ>†vÕ>žfÑ´7¤ñ]Áó÷R÷µšŽƒpJwî€‚2M
Çeã6@<:}†l2Ú`£¡.Kf·NáiâvœÊWx¬-¬A„É‘•ß²È` k/uw}›EãðyÁDÿö·¿áôƒ”öïßÜæ·Õðïi¯ŸG?ªölm½ÍOŠ¶Ëƒ©æ0ØX[ÿ¶¹¾Þ\¿ºþ`sã›ÿ Ð7pt²‰¯³a¢¢ëªøiÕZk]
oÌƒ¶³ÿü@mR "†ÖrVÙ˜‰‡u±îêÂÎ¯r~Nº<‘šÃ‹á¿gê»¸¶»ÝÓgãîÓÕBx
zÄ¦ÇÎ>¬xËtý¡96ß½<Øs>Ÿ¿Ú†¿·þòêP>^8Ð’Y4‡•:ú¡5«U’»Æ(5ŸGõeà.æƒ“w¥ñ0ô¾¡â·ZaO]hÎçj[Sš–ÚCGD'ÌÎ©âE‹UºC-û±„L¨Ü7>Û|¹l-©>¹ÂBp-˜³Õ~4Ñ»·¢¿­·–Ñç!ÐP5¹ª‡°›Y—ý²‹rÀhŸ±‡¶êª -Ð#eÂåyªãŒÍ4:oqHu¿@…óeÑá éxg¿°ãHMÅOFI£?†¡üMÇýjÓõÚ²+îå’ÏÂÞ»Ù$¯“¿Z>hÌƒúÔcá D·èÍŠaÍ—KoyuZ²ZaöÕH×Çýþ(ÂS_:ö—ØéO§ »é9ñÉMÕžŽ'%7JÏ‘IW8SBôœÒ­ wñLÕßc¤Ç¿‹ˆß¸ô³ýšg÷î	aâš÷3ÂÒœ³ÉÐÌîËÈÐ»_Ýûrî{jU‹c›*óá‡›êø	Í›öàD;à Ò7ØºÂXE7¼Q)ß ÔRUÒD”œoÂDÖÚ }´ùc/x&ZÀ`ù±RÂ¸@.R€Ä¸ôQŸ`áaÿ¡¹¶Ñ\tº¾¶ùðÁæÚÃ“GÖ[k­5-‘ÜÊè!¿Ìí¼Ù…ôb<Ý€‹p4‹ò…=^å:,Êz™.à›T)WÚ\ÉeÕæçIqƒÐÒýù8»/æ€Xoã5]Ô·{²uºup´dø69qÛ€ÍKÍ›È²¾†—û.íç±	gLCö—B°üÔŸ5ñÈœŸ¡Ø^o¦Á7Á Ã£ƒíW['s÷_Wì¿(ä[‹ŽR@µãËõÖFk½u¿µvÀÏ÷Þ8ÀoðŸ;¯;…ù2à<kÿ:aû§þ»õÖZk§ë6B:Þ:Ú9<9}þûeÌ›OC‚¾†ÄV×ê±»m‘³Ý,4cŠ9‡Ù¡O>æŽX#ãÞìvW÷Zv«z•©Á'¼ü6U÷»Á=ªîx3°t½7¹}ÏhŽ  q¼°H,Ü¤#`ç4<£,Eú­•cäýÍ:¢UÇ“ÞúÏÑ:Ýî>ï¼Ú=9u!>]°ûž
yRF
äÑ©F›Ûôzøm¼’ú“è=ÚJÝOœOØ˜ðN·ôKr™‚(oc­uþq%€÷mú÷=íGër>,þ}ÊÏÒyÃéè_Œâ³v ·²`yÀOÅþ:êÇ÷oš‘ý³¦Õw?i¡Øx
ø‡»éJÏ³ÃUüæ=ÂäŠOøŸS dÇ{­ÉÕH° òlüqÆ—£ü>ÍÇ-©][ø^Ø,Ÿ¾@²
ÊC¯ø°¾­`iã°Í$>ÅZ-ü`!&E,¤Ãù¥c*L}ãy¬;N±g¨Ÿé¥Yä™/$•lÑpx©
£‰~ÇÑ*’²ú§‚ ¡dµ0ÕOƒæ»ð½˜ ØS…ß>ÙäÉ›ëá7%¥!(:T‹Ú|÷UˆöøXBpGm£Þ;»%‰ƒ¹®sôÀÿ j+t³ëHµšúñ1¥­JQ‹æ ¡ärÝné¶n+¥ZU-à›h$A2Qo˜ªZ÷èèàX™ÑÑÓAsªì9ˆø¬¤Ï¾•CxÆÎ‰€þ‹=©µ”³„öÊM¤ð³Ýƒ­Î.}sºßÁA<jZÃd÷áC×||:ÔÅì×¬Ÿ?Ì0'Åwm˜Ž#}ÑÌwáJ®zKµ{M¡™jg†s¤J½˜­':P;ŸF)û[Ò÷vÐt¬_Ê¿mÕÒ¿²àz¯¥þŒmåP8Í-ŠÁÍÈˆáïg¦vÏ˜W…0Íá*÷\Åç^“@Ù°ð¦H0¬i¼èÊÐmÑ×æ“®ÎÇ^žU*’l6P59<K£s}É-YÖQçÎ|¡Ñ1á^w²Þ0žFäS‚gWÆ®qO»´ÐØ…Þp›æŽõ\[®Ä0f<ª³œ›JP±q¹V4</¼yËËí¹©R¡bw¤-ÜWakÀ¹œ;NUÏXÛÂ€¶âKp³¤Ú,ÓÀà­lÆoÌ™* .,\#{‡õÙ˜×â„n®Ñ<t¬v¶éoù&?c¢gqs×„ˆ‘êÎÓ¹geãlõîxÓE‚ÖÐÜ†by—BÀ‡;É×P¶/ìƒ=ê9	4'â{fK±.á²ÂÒñ´‚àg¡
??«íˆI¶Å a³ü£~.~‚-ùv!êDãÂ%¦IÏ â®Ø½d·[(Ì	¢žz+¶]hl­¿¦¾Ÿ¹•-Z¨]…•Ë§¥™ÊeÒBó¶w¦R¡)ã7Hsòóè¼»Ý9¤â’áßw•©÷•E6ì„Ô™OÔ)+vUÊ N˜êê‰0gS6sôÂkÖA]6œ:î¬þLÞž°ÆPs€”V?ÿúñ&TJ™‹eQÐ¿¥vS[:®´h¿bŒÈÕt8¾*ò/¬X´	c	O-î`µsÕW\¢=tˆÇí¬Ñ_ž‡q½²t†ôÕm-€…wNŸqlÎ¤ý•u1ÿƒg`âá1‚—:*nÃh4Q«Ãº­\ÀMcï˜fŸSû)>à,›V´PèM›³M²‰•»UZ[vå©µ¬™[}ú$ÔØÇ2T©ëºåyŠ\1ÍŸ™)l;öFª/dÈŒËòªå†j6–£…¥±ôÔ×^’ ©ipKíaFg9ë7Á´}¦:ÏA••p¤ç£è=%"¹âN zAOÄœºû¯ÕkÍŒ„ºC8dþ<§¢>ªÙÚÜ†Õì®’é©M?®7„¡]'rC­ôúé™YóþYt¹U®ºÂƒL…L¸‹qbóÐU>)“´C÷ÏÏÚužcQ-žrÅÐ
Cçv7¢e¦WrÍÛ™õÆâI.œŠnšœjI‚Ä*Oˆmx¦%WÞE–åË¤"¢S€þ®É3$w;õc–‰õ •"±È9V85â^1ô„& eaX‹¿¹ú¨ÍÎ’&O7òwÖû³Àœ«¾,Yê/^³wš»Ïÿ¡9´ c¼9ÐtÛæÓRŸc‰ÀtBå¯ºÒÊ½èîŒˆó¿jÇV¨ƒ€ëÆWè(Œ÷10‹Îé+oÙù
Yðgñ3îbƒ¶‰¶Ó	™7]÷”æÍ—ÕNfñÛ ó ø…;¨ß°zPlã5ÿ§ú<h(¸K‡Ò/EU­ï“Ô­ê³K·Â§*•ÊñîöÎsB~D›ÅL›øâÀ§OÏqˆÜdzns—¡A…ÂÐpþàA§JG0“ßW	ëÖßf¸J>ëëÐa£uŸ§Pé"®\w•×øÁƒBŸ?Ã÷LTu•¡{^-7>£…Æ.G©ˆ)+ÏlGñTÕÂ–œ+Û*qa«•X1~¦žôSšÁöÁ^gg¿bÞ6~<öVf0ÿçg-ë?oð£eB2UM=±¶*¨¡—QÀ`|<d:ð+P íÍS=ÎKÏ¨AóØ©š4©x_UM·Ÿxégmš+Y¼’óà£åƒ%wDñÝôf#“ÒòÚ*(FÒ?‹0}O^	O°¶&ÖÈ£Ê¬T²‚tƒj½€gp;rþÇÉìÎÆf³Úê¾:c¨Dæ€ÓÝãÀnÌÊ•ì:ß2Of`ì|ÒyÆ€ßlŸ>ßÙ­’iõ£àFUÕÔÓ@W>h9ãºíŸøä²ßš¾'cÛHÌã”Ææñ½‘Èôå,B,o45ˆÃ³²6µåàŽº‡ËæU´Ä-Š†¼%@­o09Åª“¶®ºxRÒDîU‡Uw¼)ž¦\€ûËßf§bkòg#á8NªŽ¾6ÜºÍ/gKUâË¤p––“é#ö(ôë÷¹KíâœúùRÑw¼éöI˜ašOÑxÕðpy›½|6«ÞwëâÁhs“ËO¼N¾•Ÿ³ä¨ÎŠXÔÈHˆUJ<Üs
m³Ñ­¤@FaŽeú¥V•Aq™'!+#Açex¹#;™úNSŠ§þÄ±n)~o($Ùþ¨j]åT÷ÓQ‹Kär†U[Dƒáwtð}„B¥ ›]­Ú§ô.)"´ÒŒ!@£²‹˜sP@ñw7ƒ)¹ŽX}Àš¿»hI¿[0éwÖgGÏ „çQ?–¤A{=ˆâ¡†câ¹	ülÎŽ ø‚%w,È¹œVƒOœ—˜çŽáƒñ"NçBÄïÒI”ˆ<áÝ¹ôg“Ñ[p[¦ädýê<©»…u®„¾9´J„B?Ÿ%\Ø‹ÜpòGi¸ÿý¿,_B®oJ¤K^»2‘Òr:ÑÂÂw»Ýý'/ŸÊòé»Ë>üöÂ ecáäœÉ°ùˆÍú=7ö 	ðÆQ%â¾6jåº¨öÂ¿³ÉDrSL¡ý‹1Š’óéÐ¾ JÁM}øò’©:jqÏÿoû›·Ø?ÀòhŠúƒÎ‚æí™ž²Eñ”¼–Îüïÿužõ¯/"]ÝÛÚp£µ‰¶ºøÜ2°±Œ~çƒÕð‘'/‚,Ü¦Y+}°¤ghþ´Hˆe1ÿxO±†(•ìø…^m@=°÷^ÞÃ÷¶Þìß#ÓîOiœœÂ9U]8;¯
˜Ø‘*ÛS 1¿•¢)¹’* Íoú2K±v>Ìsk¡ã)xÚÚÏ£½$˜SHo¸ZGjœTùÏp|O™ =ã´ãÓ­„

*c)ÚÐºÉ¸—õšÅžnÀELëa“CäQ$éíÎ6ÛÖ7{H¡À%MñPô6ÏC¨4/ns}Öb §˜‹â&Ä¿>íµôð•ä%˜Ûì?›´©L‚Åç¢#ßDªLtÊ`ÐÇôÝöÎÑúSúgC“Ä…ª‘ pÐÁ—OŸÂbÎHap§¡	î ¯8X§ÍVË<¬n”»ª»ÚRB;¤­Db'1rf« ŒHg­Bíä9fXIP'ñPŠØ;›£ÐÐ8D„k˜åø)ýË5õëf¦*†n%Ï¸¨^À¿³³»èÇW¾0°ãV±N¾ÙþÿÛûÖ­6’¤Áý»:Çï#{»IuUIêQƒ»™ÆÀ‡Àî‹}tê’%d$•FUÃ´÷iö1öß÷b‘Y—¬R		ÂtWÎŒGdEFÞ"3#2ãRC’¬ö¬¨a1ŠpÎÖ˜ƒ¦
+å×^µJ¥ïÈo»‘^>ÏN°<z6c;2©qÐWXÜŸZè1}.²Ü[”¯A¡Wlà"i\ø¤Ób &þònð¨t¡V¥j:Æ³˜ºVÚA[ìM/ànÖüy.œgAíö%N¨´_Ùª‡ªãfÿ?’¤ÉJäÿò%ôÿ£¨záÿg©¸Ç”ï1ø  “%ÖÜ«Òr—ù)«ÁÙöDû—é4¤o!^2ç±a°sÞNØqîÓ¡9=“ØúG¼êŸ™QÇ‚õ¯RÖÿ— Åú_G²u·Þ°åºM†ÛlHu×1¤†ê6MÓmÍRízS“üWµ6k?F5Ù°K“šÔ6ê¶¥À0ÙŽ®9ºì˜ª­¸:mÊbéÄÖŒ:’©7%Å0¬z½éh®â6›uE“5U3ŽjiuY²œ¦X:±K“ê*’£¨&0$µÞh˜Š®Ù¦%©Š[×MªÕM£ÞJ‡öu]Q¦ÝÐ-³©ê–Mm]R-É¶›²®Útß–Ý¦¤aÉ\#W¶$Å²]Å–”†kXÙTM¹®ºJêMK³š†éèÍF/[‡Ár,C‚æBÿÅ(–nC·M
½7$[5M83•–q0Mºf(T-»®¬ÉMÇhÖåFSu\ªØÐÉ5T@VtRS5ÕF£Y·4jÐnY³e]Ö)5LIwd­î6ëzÃŠe-î€RdY1:4V—aÈM ê4aøšÍ¦FUYkÂˆb‘=™e×e§îjz£YuSn²iY’®Øº"™RÓ65&+ß$î63:c
—ž[Ium[r-[±USu*ËVÃ”4£nXRÃ ¦,9®m¨³¨DK<ZWªãè¶d7lÉŽ¡Áb±ä:ÌŒ\7$jÉ*ÍéœH+°t*Á¼ÈºÓlªÌµné0ôzC–ëM½)Kš£89XÛ¿ÛP\þàÜ‘öfÝ–
gdéÑÑuZ·lKwõ:ŽÒ0dè‘¥ºº¡Ûl–JÊ¹ÈfM ˜]KS”¦«5a'sêÐ XÓM¹©H5šjÝp%ÙÉÌ½`º©4IW%Ø	€†Ór-…êð¯&éÃ1ë.Åÿ™õ‘¶;…ÙÁÉ±al4Õ6P U¡oõº¥¸°Wk.cf„3–¥þ°$;Mh_Sš–$×G¢
n–²«K¶Õ€E¦ÊM¨B»Ïj° sQRÎ’&",l«áÈ°\›ª¬uÖ“ÜTiÝ©ëÔÊ.3©•änhU›LÚYIQëÔ4`Œ›RÃ¢®Ù„ž$92¬=¥§€äPJóQjÊ‰ç]4ˆàìfp²4d *ØCtK³ë¶Qwh&ßÐ³õ¹²¡åc•Ø×=ñAKU[7ë¦§­\·\è´û‚,¹õ¦«ª®½¶íºù8•nì?'Õ6»I%Ø‹› uÃÒá ÕGƒ†7`ˆ©ªÊ¾Þ+½{±¦¨†¢ÙÐ›kÀÄ¸p¤[TSL¦ÎÔ­yS¥vùE^"»žëâ]6ø¦©RŠkV³$X>XÔmêu	6Ét†dHÍÛ eí¥šZWTl-B„HØìT8
\ ö#³)›Ž6³nbYí
2]4ºøœ¢b‹uFÐT$Û…æêpÄ¸ŠÖ„ƒß0L;cJ¦ªjÍúÒ85˜pªºŽiÀ¿*ð*VCR$89u`]tÇ1`ÇJÎ…¬i9…=
h•6a7w$Mæ†Á4€î/S½¡8Ãrò{®äö\asÕh eiŽÕ´›ºí4Ë…v6Ô¦m«º¡5aá@ùˆ¥.÷Ò'âG¬¦ûð„÷ld(•Ô†mkF³)ã9g@£aç77o<Ù) Çµ­Ë.•Š»µ­7êHÿÔ´á¼³ RmHúm–çv€µlÇ¤@¦&¥®$ÙŽ¼0œæ®	ã^‡ãvp¢µ¿·½{ÐÙ-©0h0æ¦	d{›Ò°à­U`KøY…™¦ŽlEå§	š¦J´	t!Õ©!á6aÁ K@rM¹.ª+¼a7´¨dtsswáÏÂŠ¹	å>]ŸÿƒòÊÀÆc‰òô\ý_Dè†aú“Ëy<ðªëX ÿkº¢sù_Öë†¢ ü„PÈÿëHÏÿÂ„ãsfŽ¾š›4~öœ¼ØsZäÅÊÑÆnÊ·0¼^i}‡‡jbO #ð™ãåëÎ+(Ó1i}ûÁÄô}J”æ&O!oá,¬É´×Û$Ë~pM'èz|åF…Ä*O­³Lø¾Å"‘„ß;ð²#rÈn[ÉKú¯ÐÕäUùì?ƒpðVJï:ý .ýbßôƒm~oúúŠÏÀ²âÕ üÀAXÜZ<¦³ Ñv4`lIŽ‰Yí„·¢žvØƒ36ªQ0f–ÁøV×£AbÍ—o ªy0çôØ@:gÀ¸ørº?ñ6¼=Ú¯¨Uéï+ŸÚwƒ©O¬PŒêðÈ½Ø	è{bŒƒ_˜ÅÒœ !ü¾Û¯ñWIå­DžÖ2.gîŠí5Å@&QŒXÔg>Þ›FúÀ>·ºŠœÌ3³³t¶ÐÁy/‰±BöÐ#Á„ò÷t't1>ò^$:Ì.<‚î]|ã¹ N	ÚU^çIô]h¦ñAFváÑ^¨™ÅsaøXø-³Çõîö÷»Û§“Ãw{¿nñˆ—Ï9ÔQ.m¥š8ëô2ô©ÁÞŠC{Â”ÀfÊæ,ëöŽáœ±8p¢ÎàM…ÅÈÒö!2D”ÖIçž[#;ãÃÕ±¥L
MK©Wæ¶oÖX@è°h÷!`<ãã	³"˜qÜazŸÅ"jÁÿãPcY†oÖ¦GÀ‡<LÇƒÎº6o¤lÇ2u¦} £DÄ7ë¡TÄ‡œ§1š¸-zR|Îïxl5YÍÑUÀÂ…[4Šª”Þ[Â¨ïÕ•ï¦ÿÈ]ä?<¥§ÄÌ•óƒÔq3ÿ/Ëš,%ü¿ÆâÿZñþ·–ôPüÿƒI OT˜'<m íRëMèV0òúÅÔ™ýá<·€/•"¸=áøž•$BÃ‰˜ýQ¤÷—u×…þ}\À§BˆXMsÙÜö[p™XÞ¾2\œW£ÀüÂùýÖqû=úGZyÃ¹ê9êÈíÓ~<k}¼¬‘ß¸k½ˆíüú‰lD¶sÖ†¯	Kõ5ùb¶Óå¸M’ `µŸ}Iö Ìf†	_—©©oe«Ê ìÛY î–/±R`Ïra€Á|dhuš@zVÒäL‹Ìì§Ðu \G[P¡²=dGlhœÍqï`~³¬3Bl¼Yv@øL¼]®Ë‚±³wOo,X|e¿–!)ÁîÏÌ‚m‚ÐT{:‹dL-*ñŽé5ú,yCüœíÂÀ‡JÆ2^´¡™â}—VfÑòÍþËÕu{ƒý¬°C N¥ÑÆ¤vhµ8c…‡Bg$û•˜M3Š“™ú~-ä…Á“±ø‹~Ö‹+—8RjC U.9Þˆ–Bÿ•i³Êö†íqeÿâŸ™þtH*6ÉªÙå‡šC/j£é`ð{MÇ*¤Ü"‡?•ÇÃ¬ì×ZäÍÖÞþîÎ‹Z-Î{¹¦úíîN­ü=až/«¤Â»äãKòRé33†²X[™||E*ãIH¿1'=˜})nÝ8lÀ›/îlC·á­8ÿE*®"6ckg‡7âëï>’^e
íh‘Ê¹¼)‡eà/Wf¦q0×.É!÷è–%òƒô®Iå(õûÐïhè4=­ë¬rQ`9>.‡»L¾‡Yªdð7ÂÉÄý<™ÁÌž. Ys¡x­	èY)ìéÉ×~.¢
Ø×s€²[™ 6^ ÜŒ7¼šù bÊ"qãÒ(‹P¸£ÏBAn

7øY(È¡f!„¯ž•ÖÔˆ9>4"¶®T"³HÂ–3þ™l£­ˆ+•`[ëÖ` ?¡_ÎÎ)Û£vâ2å3¸œ”Ãï‘M?ãwcûã¤[‘cl\©°Sðt/
f¤FÇ"Úøã:³ó:óâeôóÕÍÝ‰Z$ÌM|äÆCÚó€h2Öuñ·1ÿÄŽ¤8“#â—Äˆ/ú¸"¦(kPmo|MTýg{oÒ6§´7öÑEÓþþÖÉn{› °9 ¿3Þ6Ê‡²âï	eÅg^ÜÇÁ„7aLâ,ŸgåµÇ„à8²ß1\4æEŠ`<Ÿw”OìFâÑx:æ¦ã$3›˜°×DÂ€V—n^5n4§·+ÎÌ£…â@S·C r‚Å¿ŽÄžZ@qÞÞH3?Ò’e•O‡Ûømš“«¨Y3„j{Ì²07DÔùžüy™y'üEßko\ôS»`¨”
ÅcßÃ=VÊWó]mô?TYU’û_õ?tU•Šûßu¤âþ÷qïSÊõÈk`Ñdÿ†ÛàìU°è*«¸.®ƒî:x©ëÅÇ»>#ä9w2óË<C¬| î'–`û°”àÚ	ïeûd+Ò2)±Ìz¸:Úÿ+jFÿ[1Pÿ»àÿ>=g¬Ü†k¨™GÛM\§"ï‚”ð‹°‚ÞL0S2;q®æn±»®(Ws…û±è[CLÇb3“,)‹»I÷ðŸÎînìÁ¦ôü¶;)yqÐï–¬6š-¹®Ö[¤V£	Þ?—(˜oX¹Ú:¬ÅµDþ“˜ý].ü¬%úÿ¢ÿŸ5d~ª’ß€|A­° xlimÅ²Úz$µÒŠ…¯oGôâÛ=|³¤wÙÿ1|öªÏ”lºƒýg]’ûÏu¤ÄúáêXvþEAG>¨ÿ-Iz1ÿëH/=RÇí×¿j¨Z1ÿëHi¯8SÇæ_7Šý-iÆÑÔqûù×”âü_Ošã…j¥u,¸ÿ‘%ÙÈÌ¿®éÅýïZÒó´Q4J$‘'ú8íÈ!n9¡ï’ßðèÿp‚™ØäÓ÷>*ýïj’YrûˆêÔçêê6SWŸc)Ž<Æ†º{sè—JG['?¶_à¿­,ÔU5VÄ3Ø[\dÇpL1þŒÚç‰U3_`2ë±9owYÐñ.“6)—ãÖõ€øCWV]„"¤š_èÀ§€k.ïãÛxdÒÎÚ”[‹Wd9ù°çsh.¡¦^F<¾7ð¸_â —þsÝ})Åÿ>ûV[ÇòòŸ¬«Ìÿ7ü,øÿµ¤hPÇ]ø¿zÁÿ­%-çió~u,àÿ4©ë’&I‘
ÿÿkJ+½Ï~¿ú=[íEù³»¼û=»ÃÃß´;õô—»ºžÝïùïÙÂ÷¿gK< >[òðYö	Ç|'×Ó!¡hå`@GÄ	ãrõ‘ëg™÷Àg·Í{6ï9ï¦L|Ð{¶ê½•·—!%ž8"¢ jÝ!
8/þ„[›I¯æ85.GU‡Ö¸qå÷èÂ ¤©`gƒhîæ«UŽŠÌè)’V®öb\`6f/ˆr¸;'[ïÒp‰^‚o&/Ã¹_S0éÐµæfàRaxc8nCîì¿Û:ÈÖÊs(”÷vf xîW6i3U\sø¿ŠOQ>ÿødÔJÅ†½(üÍÊÆÕ*ÏÓ-Gàè¯¯Ð0*i]ökÊ,ª,ÎE™k~8æøˆ™fñAó}áéè#³¾ÜöF#¦q&BñqŽàpÂŒ-Aà rÂî(€Ý Ì‹‚ÄvèÀíô{#êlÓI€7 HÔ!7‡;™ŽPåáóÅ°iQ„ßCÿÖ'ž7ðçC¼ÊxâÇBÆÑÄcuÔÇqŒ–èÊÞ˜ŸW¨´´[ü{Ô±€ÿ7êRìÿ×øÿBÿwM©àÿ×ËÿÏY]O[øuê›4¸ômº	C¬	q§ðÓ§ó¤ hOöwöÞ =aúöq /)ò(sêÂœN]:ª>ËZ½¦}øŸcN\rnŽF«Áœî¡9šb¨cH¢Ç$¹¤‡#*d’¶÷ ‚Vßø¤Á˜6ÌyM}û·5I€l°ÖG„âÆ âhB’#Üè¤rš"ÊT f¾<, $ÅA'£ ÇJàHê`†Ø€­òCb)w6L.i? úÊ+Ó‘)PŒ	Ô^Ù9ôÁèåCö°µsJì{ØY@}³w2¡á<Sj¥ãíÀB·Gíh¸7á÷1.ìsµÝg%Ïú¬óö 6×Ð'½#:ñ½QæÛ8/3ðÆ™Ç¯Øn‰gTÁ%Ÿð&=szv5Q]SA~h‘ÿt:?né²òõäèýåß;Ó¾cŸþûÔ7š¾{"÷Oš—o_{rc|^;;¿¼øõMïÊÙúùÇÃÝ³½÷çÇûæv/Ì÷i²ýöúúò§ÚQ¤kõ÷ÑøíëÚ¯»&ö÷ß?+Ù£–@“~ê¯°3‘Ó[Êœ?T2#ËÀÆ°—÷‘|+(Ó´2ü@%0¤;Ï°2ð¼óàlâM{gø»´ˆ
üFà÷¯iúK¯AG/ú¯Vªl"OÙÐ†ÒÁÈI-®{Ò.}lq±öó×~¶Ô(¸žöük8Ðì³ ßƒb(†ç¿Âçÿavi4SOtÛøéçÏ{5ùðí»ñ»¿ÿôáçéåô§/Ôêÿúå—_‚kã×‘ñùÊÝÙ=;îý8øùÃ¿¶Þÿ÷È¿üü÷É#ÚÛÝo\¾=:ÿb_5_Ô~oÕÞÕ:?Ö‡ÿ>þé ñoåXâÛÆ4¡g?ýçGnÎš_¸]›Âi
av+Â†/ÀwTL`Oó!ø¬V€Usn¸œÀºÈ‡@_zúÈ}êÝ3¡ÈèÌCt….©*¦=˜Ó\òƒJÿ<ýÔWü«‘=çs=Œá•^‰à‘öyø¥2ò‚¾{5ÿûü!Ã¯7ŒÊ®s çsó†ÈO^Í¨È±Ž6ƒ"Éàìd>¿éb³fÎkLãŸMÇ»Ì'ÄüCqçh+¸aÍì“úýO¸?È•Ú’ïUÇ‚û]U$áýWÁû­¸ÿYO
í?Qkï·â2(ÓîôePîR{ÚWAX¾ÏƒáØ¸Â§àð(ò\Ì¹ÙÓa"û^%o'Ó‘óì3ü,g¯e£ízƒÆ E·DæÔŸ›™SXoÏENy!à8ÞThÖ»ð6©x¥~ !·%|½º·ñ)#a6‰¾7 .™X¸®?¼CŒIáÜ›Lèy@z”Q#QïÏ˜dÇ¨¦ÃŸ9õÏY|)v1X%úLlb¢–ƒâá&Þ&úŒÈ£\…”\\aÄô¯5ãÆŒ!úp¼ÄRÁ&ñÑƒbš¦£ÑñÀY×}T¬ˆ–Ruõ“¹@Jœé¶Ë5o„á¢Ê3 ø¸Û.g|»ƒˆàLí ¬T•ª\’Ë
ÏÃxñá8ùßø«k®çø¬Cô9r›ƒÊ éâ»þW¡Ñ‹s¾gf!•izÂEÿ¼Žøõ¸nEÒÚès$Ûéì·ÑI&ûx÷¨.IÖsW°€"îuû¾áß„a«;‡oN>lïf§Ï÷Ü £[Õ.Ú¨Í”êbœ*(ýýµ†±©ràÞ¼ûs‡—9P'ïwRPÁ…S‹º»´ÙKvÀWNhçûo¡`r*”šÃL®Ðµ-bíáñŸÛRD¢U\ð§Ý_:'‡Ç»·$½ÏçþŠ£Y?fó1TÇBëö¶ÂõÐ.G¿’î"Ö2ü÷éGÏ’ÊQEFn3M¹œÊUx®’ÎUy®ZÅ3 îûÓd¡pÛ´t°ù{Ô±Hÿ×¨×“÷½Îßÿë…ü·ŽTˆ|ëùæ¬®§-ô…’˜û?ÿ?¯lM}ø}6AžXÿ^›pç?¥Â~¢´ÑÏÕ±LêÉC>s"”?ŒxçI¦|SÉÂ¬iqtˆŸ€×‡	÷|düç Œž+2èÌvŠVCAdÀdHàé!ÛJ´˜ÞH×t€ÐlXBN¾-WÔÞGT€F’dlÀI
KøúŠÑc9!›ç#¬C’hÃXîY	Wí½‹É±œ`#nçãÕ³#Â¾¯†v¬ž#ücjh¯Pó:¢4T”›À%3/Â%¹\K›Ãn9NÈ*s'œöÔQfJÜs×Pš¿ù,£M=ÎÑ¤ŽB[ÌjpÏµÈÕÞu—±ùa’.‘“4¡¥^ëu3Þßo×É¬¾÷=»:£—}A'—ÑŸqÀX¿ND)ÔggþÁœ–äÿï¥¼€ÿWT5Ñÿ•TÔÿ••zñþ³–Tðÿß ÿÿô5€ùDvCÝ'dü³Ú¿ä\äûo­<Gp*´Ÿƒê.EZ¼BôïÝ"œ)y€C®¸\"Ížÿj—/ˆ.ªAuC;´{] .´ÿ×eáþOÂó_–µâü_G*ÎÿuŸÿù«ë©ÿÂ ºªâý"Ó	5@’Ç4¬+ÿø±ÀÁ5)ÖaÊ\±K<|ÁÐGú™cÇÿÄÔ 93Q%[#8~xYØ8—!Tq	§)´³ÇÕiP\Ñ­²½ÅÝz¯èÃ‚»v—GMy¸ëºe¯º;#àpØnlñ¢« ÜG*ŽŸ`„A‰Ç„ï‹Pˆ»HìúÀLúzMbW5QË“»¦¦¾·Ã4ú™õCìŠ ïFwFy×]ÜyîÙeÀöù££\¤‡KËòÿ÷¹ \ÀÿÏúSdM.Þÿ×’fæ_V»B¸ï®é8]¼8Wï!.ÒÿWŒÄÿ›¬0ùOÕùo-©ú´¦ O7¬«û‰~%¿%¿%å¾9bwýÆo~¹´ÇbûséõóÑ.w˜±Ë=ðš‘o/qÍ¸V>—O-ÆÓÊD­¥%­0˜Ñu‘SÁïÙÐ›6Ç+,¡yÌmå—%µ–T6Àä]–›B¥æÂ¨I«nÐYXZeA<Þ=šÅ…¹1ØÍŠK	q¥ŠÎN.‰Ä‹š;ñ†ä¬Àã¿T(¾à‰_DÖñ±ÄßúåÞ‡?…ñ‰öe iÞ¡rÎ“¾œ}ÓÔ|®xûBÔJ.jåFÔJj¡3GB‹q¢ÐMœ=Pa5Éye”›Ë(¬LèÃ.üÐýÝ)Hªå\£·ˆeß ä è/ˆª³Þç":cþõ¯o¢\Ñ||ª(ß†„j"rèpGø)šˆò„Ù‹Àw¨ôGáö"NvêC¦àÌÀÆc˜ÚÅ‹—Ú[œÁÔ'•³h  ¢q†|s¼ê¯ôF¢¸XIZÊÿßÃÚŠ!èÿ«zaÿ½ÆT¼ÿ=ºÿ¿?Úã_Úø$q6uKÿ9®ïªáŸƒîAõû‹÷Ã¶·x?¼áý0r8MLÁ¶”G³º¶”qxÝ£­NçÃáñÎ×(–Õ³¯6/~¿<ÃºÅ£ßÇãy˜üö‹—À]’šC/jÓ	®³!ù IÅ±Iy«ò«Y¹–*Í2dºÞÀ!•K"KðÇ…9¬Œˆü*A†mýZúÜ©¤GIƒüío0?~™´Ûä»ß Ù§ïÒY€<›•Aù”ê^”B	˜wö	ØQÉ;¶Ä1Ò™Ž–&}“´ €/]Ô‚]ã<ÉÂ(_7àv8nŒ÷5‹VWä¼?êÁÒêrûü·ãÂ
8â{®²ˆ2Ë~r:bË_PÌè0'L°‹	ô,·<ÜRD-¤5€µÿ àßbZ1Ežvv¿’9Å¶ÒØ±˜_^í°$3	Äœ]%Å¬aäqcŽÎ’ª\æ¸žW‚Ëû‡ìÅÝ2þH±­WÇ0OOÎêÛ5ozû¥›öÀ¼c9†<·±q*ì˜î™
¥”û§™ûŸPH:ì¼«Ž¯VQÇ‚ûU5´äþGÖˆ$’V¼ÿ¯%­JNË^ÐìÜ‰éÃþ`xúr:ãp@Àõóy>{'“¡øÕ¾Æ§Jgoa ôª¬T%-s÷2çŠØ;ÕyGv¼¡Ùè+}D/qõ7âùBDfñ®á"r¸UrØøwÙ¹ÌRJUCØj/7vßm§ÌÙÆ&)ÃˆûÃ./W~!ãiy3äAm*É5^Ì¯ý˜ã¿¡¯JL&è²Dû£àek(í Ç€HI’Ë¯¢Â¾?ˆÊßT¸ ¡¼’”gœñ¼î$‚¼¤Lqß.ÇG{QÙrZ&+—J¥ñ´Á	Ÿ-ã›üí¯þ§Ì`|Ÿ?Š†y' ç’ÏQ<†	x2ºYhä	y‰,t8œIÓd|rÑãø%Ðñ½Âh1€R·†ûhcà9l¯à9/y÷½ða0ja6S—<Eó”Œ	/–ŒÇM¥RD‚LËMq¤„Å•ŒÏ¢RÉ¨µgÆi÷ì,0J'}ö~iVÿSÉÕSSÖ¥ÿ©Ê…þçS¡ÿ¹.ýÏùëªÐÿ,X×6¶Ðÿ|:úŸJ.ŒògÖÿT¾EýO¶U‡í+ô?TÿSù–ô?£É.ô?ýÏ?dš•ÿ¤.ßREvõAý?ë²!ÄVxügU/ä¿u¤Bþ[—ü7g]ý!„¿>ºVÁp…#æª%:ˆ£°=‘DÈ;]}P¡oro¡¯öž®°—3i¸^Æ¯BÆ>&ðÅ#p/‰/ÂË|)]˜”Ø—(ÂÜJðÛ™ˆ~ù5(jÈÊsÀdžn#Þ\*%ŠnkR¬ÿ8ïÿõ‘A0âÈûw”ÿ*ˆ zp&ÐÆ8gÒ²’[VtK†ãÛÞævfn»®H7¥¥ìÿPñu,”ÿ„ø¯²d0ù¯nòß:Raÿ÷èö¸ºž¶ 7–ãñTc·ß©0?‰)àk:šâh£—ÎË»Xë9£J<k;˜Šš™ª
þæn¼I¶ä8ç¬¢WðOáÌšO4òãAbM‹dÄF~£+¿9]8Kéjg/\á˜Î1ˆªÔi”•ÏP2X*?£ñÔt­Òx–9¨Øâ`àY>ÎA	üa€ñG{Z‰´4¡¬g}†æØ8‹ž™}oÒ2m›ŽƒÂœq…í}€¨° ÷0òaPÊç@Ó¾dÚÇÐ´hm‹nqqŠÏðýSV˜}nLåZyjÁ
Ð ŠË¬lá3:Óß$Ã)e«ûkŠÑp ;·ÙÚÞßðaÅ™¸>c¿ú+ï5R=R'P+P}0ñ˜8g@'1Ý#ÿëpi˜v¿U~	ç}aöÇ²\UªMªÊ²ªëõª\ÕªIÿXfö//è„ÑÐí÷Ä´A¬(ï Q¦öÇÎ «xÜqäNpäø¸‘°Â[ù±ü=Š6ÞåK8†O g­@ûXM5Ø"d›ð›ùÝ9ðñ7_Ù€äUùI[TÐÐ#ÐP<ð+!¢Ûb**,rþ¼iÉøO÷’ úQýOIcþ?C*ä¿u¤Bþûâ?=}	0áõFIð¢or^!çÝq5==9ïÙ>¸‡¤¿Í§ÌçìçOâ0ÃtÑx¶9@’ã5lÆœž‘3?dSËžá·Ø!¬i@ÞÓ	ÚuŸf»M·#lËØ™àŠ˜a“nQYtaúNÅ[õ^óK~=©>ïp«{ûw9b­à•Gn%*¼i©zÃ,nŸŸÁâ„XÊb#ã(h–ì6NŒÞo¡“Þ¸SFN$ôŠûµ]zx“LÃâüTÛ’\Þ¼cŽ-nÝÛè{Ü@”Rb¤@ÚÓ@ŒºZþ˜Ú}sÐªtÿúØŸœ/‹–9Ÿ™-ms4ÍØ-u3*©lÎ~sx§è”fÇŽŸc<:âÂbtÿ÷,´NËÎOîÔ!†‘9àBæMccÄ„ÃÓÚ§£^pVyþ“>Æ…?’÷Dnù˜[SÑžL }=$Àöö
‹rG[åjÄ8¤óãVEN5Öï¹7*N¸Z’Ÿ÷Ù…øX7ÓQÐRgé[Vg73F‡"ìÖPÒ­m†QõÆ:é—q?\¨ýPg«ž)“©¹2¡ÿžÂ9‚ôtÇG22¼I·_GóI* öHÎw&¨VÞ.(êNõðÄÂç8JÚï…›|zsïãi<HvgùX6í…poäô¯éø	;B+Žvè—sªTè€¢(Á©DŒßó<9¦ ¾ÂBWB`Âƒ«yß¼}ä¢æ}÷§­pÆÆ ˜Í‰¾gò¬Eÿ@m¤x÷¡ó„uƒì¼F´ÐÁhLÒ½£ñDäv£ûÀÌ·è¾-Î5_W_WñæïþotówôA˜â&é	¦äþøä‰ €èÔ˜›‚•Õ±Èÿ‹ÅÿV@2×ÑÿK]•
ýïµ¤•
<xôtï€rn`y=íëžýh¯ )™Ž;*"î&ªÂ3÷:|PŠ{†•µ˜9ùè
Îbjü®À¯±G&îY÷x¿ÆŸ‘ªðûVÅ„ŒŠÓ7{#Ïúö}ÐÜº¬è=‡þwHi{ã+`G¶Ð(gˆì—z±¥ô|pÅû>Þkx¡OWNÇm#üh~ñjëÒ»g¥¯ÈÝq„làŠÎC¹u?wÞuv/`Ùœ€Oa­Áö% V(~»ýà1¯£UgèWq'´éÍx` ‡Þ¨æX5àŸ­¹}>.97Ž?ühìûpü¤¹üß
ëXÀÿ)ó=äÿêuIþO7ÔBÿs-©àÿ
þ¯àÿfçë©ñû‡o»hÅ‚cÕÅÔÓ1?•Sè\9¸Éì:ºÈî‹r]<Ê%éœæ½Ï)?Í=ÿqÁ­¨Ž[œÿÑý^ÄZO*Îÿâü/ÎÿÙù*Îÿâüÿ3$Qÿ6U‹þ,-zÿÑuÁÿ«¡Àù¯ráÿu-iÅQéa< =Q@³^€`uÝïà_xî/qì/yêgýmØ >{y3çŸ=ãoÄÏ;áW;/¥§äÚ‡5wÕøøƒq§ƒáÜñ\ævc2¡FJ¤›¾úÎ€¬×$ßÁÐe” µ©$ÕÌñ8|¤¨1ýæ
C`gü3R	È›Óý}RâJú'@ÕTí3òÃ¤Ç"¸7ˆòÃßäÒŸcöaôú#{ÂôiÌÇDiSÙT7µM}³~§áÜ;Ø>Þ}·{p²õ­Œ*çQ×8’ŠÂFò»eÇ/d¢qün3`}Òç§„ÿÃhz—¿ËY«>Ô³’:ò²’¼ÿh,þ“\/ø¿µ¤•-§,ƒö€Â¶"Sá¬Y‹Ìý<Úfš=#f@2Úl'©Y•Œ*Ér^rUÊrY§#`6Ä{”Î»0:ø0ˆbÿ
Ú1´ƒAä»Á£X%ÝHqd7pWI:Ö‡ÀMíIsÌ°R‡„5ðF¦ã™¦°Í7íŸÈKÖÒWU²å|†5È´Q7IoâÁ)
“ÆâÄXX¨$‹ºÈ…1€¤TKÏSÐÌÎ½Ëƒ%·Rßý©ã{<;í°ñû“Ú oÕÂn†ÿ_ËTººcøyÉœ
r§'Ce™¡òöÞ¡¦ MË×â„ÅUÓý.±’¡9ššƒ‘û¬ÐbÔÞøö˜½œ™`ˆÙáÞ-ý†ûÉ§Òå*mc€(¾¯ì…\Uéƒ9
üöˆ—Þä¼Ê”¶Ü€N²™¤ô[¸…*\iÛïÃ&AKhFŽ+Joq³_ ,ÐxhÏh•v¿P›Ñãì·#¹ÔÚÇ˜Nè(—{ãXdÍDð“þóÕ¡v[•¤T3rÌ‰s8ÆÓ ³òwÛù4?úº;™x“ìGès¸¥|b#…’v{8}f/ÍcŸäwKiþßøvm Óû:}ÒþOÓ•Äÿ·Æø¿ºQÄZOzþ¶xÎ™#êUî<…+p±ÑÙKÀÔ*{²7‚xÚ¬…œUÌòŒ¥d_B­ æÃŽé'áÙã™NbA0G«xÍÏö‚XAc+1slÃÆçû×wv×Í°½†EwI®¼)°zW„ÙŒ{Cš„HÅÛ´ªPqh Œ9ÐCº›æMy°ødDQOÝœ\AÙ`Ã‡Edôá ïh¬yÍ¨®”TÀÐ…ï—þ¡½*Œ4©aœuÇi±Êë<9£i¢ãŒ	É¨~ƒéƒÐÂÚ¼0ûV¡P3Or|Ø¤ÀìæÚw¿»}Ú99|·÷ëÖÉÞáH*êÈóý¾ˆÃg$‘xx¼µ½¿ËÞc#YˆG¤ÅzBÁÛ™ˆH›Ñ’ôq”2WYçéŽˆ0ú}#B¡A1²­“­dˆ(‘Û°w@Òæf|•·™Öðcl±SdÖF¡i±gû¹í‹SKÝ†Þþéô(ê·€5¼¹]Œ“Š³Â<ÍÏŒà"„éA¬ûŽ3 —æ„Š¨ß¼û¡¿jÆ^#¾m½ßšÂ÷ˆ™œÁŠe ÑÃ2•hn<A«ƒÊ¶­yu†^”$Ã·{²}>ä7ÃCc9´P€‰…²ã±=‚o– /_Á†g‡Å6#ìWzoñ9žl+ßMÿ‘»ÈøF¯zsSšÿ7»êÄ¯°Žü¿$‡öŸ²l¿l0ýÿâþw=é·Ýƒ·{»ŸJÇÔÃ.Lùóî{î±°-W%þŸÒoowv÷¶?•:»Û§Ç{'¿tO`_ÜítßïmußýÂ7žÎéz?j»æ`eú£Ez¸”'ÿ¯PôgiÁú7ê†Ëÿª¦°õ¯Õ‹õ¿ŽôPò¡
”Óìœ[€§}°Òþe'ðm!ƒiú¦Ï^3ÄHT)§”qªÇ„šÓøbÚÏ½I%4ø…Ïbƒ+|;r˜„!V„ò6>¾Ÿ¼ßažzFÅ%ÂjšËxðˆß‚òyÏë]úßa®Þø ¿ß:n¿7Sºò†‡ª%G¹½ñqúÏg­—5ò[&¶Ø'²AÚÎY¾&"Õ×ä‹ÙÎÄðá¡x +@FÈ„Ùû‡Û[û_—©©oe«Ê ìÛY€$ž±Ø³\X`0’'ž•49Ó"3û©Æ|QG ÀkÀ÷H>ŒËzÈŽÄÐ8›âÞÁüfY	f„Ø><x³ì€ð™x»\—…{„½ãxzã‹…¯á_Ë”ˆ`÷gæt8‹ ÖÂ6jé„øcz»…¬¹?—C»0ða§’±ŒínËwY¦™Å”^´|³ÿruÝÞ`?+ì€Si´ñ )wâgKX/ÛûMûŒ]:Ew?%Ìíã½_2˜Ýý½ÎÉ×!ŽWâXüE¿]®aµ¦5¾ÂKÄýrÉñF´Äá°a;Ù8ƒ|ØˆÎ" ai'_ìkYÜÊÂ×*´`Û•‚Âå4¹)(\]³PP1Xÿ,¯S™V÷sâ5#@Û7Có™ÀÃ¶’26#ÉgÓš;ìYÐ~.h
Hºx;ŠG­7noôhÐeK2ÎôÎx.¿QíâõYô¾ êßŒ£,ªýmØ’ö÷AVno“¬<s@~g'wTmoà‡T¿ƒÅb{oÒ6§ä£±âïŽ`Lâ,Ÿgåaó!8ì/¾ƒÆè¤¶2"ŠÃ$Ôo"ñÀ&Ð>/ãb1]º™BŸ3Iqz»âŸå…â:¾!ž^‚Å¿îY:#}¯½qÑOniÅCNÇœ,¦1QL³Ð˜óöÆéFUðœ¸È©4‰ýý†ñ'3¡Û…è}<å<—Ó³)ÓbKüéðqƒ¾§Ã¡9¹Ššåø°N·á26Ž?ñ±yÑ“ð‹<†G^àÅ•ÔÆ—Æ®_±3)Gâ7ugcUwÌ™ûŸ‰‰¢öŠðcZtÿ¹3÷¿²RÜÿ¬#õGè
VBæ¼U|gô”¯êö¸zWøPðØ­/Ò}S¾þ“4Vv¼Hÿ_â¿hjõÿUµˆÿ²–TÜÿ>îý¯¸Öþ˜×À¼ƒoƒ³WÁ(¼×ÁÅuðÃ_/u½øx×g„<'9çoÈÊâ~B=¶Kñ?9)ÂðØ'[‘–I3ü_`Z«®c‘ü§)jFþÓC.ø¿u¤çì€å8;¹¹†*‘I+uô2Þ?(á‡ý­#rû'fªBf'ÎÕÂ\æŠ8ÎÕÃÜcá%úV'-ÁbEÃ =„Þ$‡{øÏNgw—Dv‘¥ç·ÝéH	¯ÝÏ>§“–¬6š-¹®Ö[¤V£	Þ§¤½wÿ4³þ«ÝÝ7[§û'ÝuÉŠ!k‰ü'3ûŸºTøÿ]K*ìÅþ'³Êž¬ä7Ç(_P+,€[Z[±¬¶I­´báëÛ½xÇV3ë.ûÿÌùŸD%^™˜E÷¿uÁÿ¿¡£ÿ£®çÿZRáÿ…È3dã‘|0wðsK0^Ú‘MÖŒxŠ–Öáø%ÙW/›1>öþ]zx§/ysý°~_ò©«ô ®_–¨éÞ_–Â~G0sq<ß½›çF¼Úyï/ƒÙ><Ú=ØétcSÔv™-8´>­}vÎåj£*uåºR+§=Â¤ož£»xî¦â øïiš%z†™[Æg‹ƒÄh:KšP¾¢â«s.óÈÞe„ø@ÐŒ÷»ÈÿV1c%u,ºÿ‘ÄÿK]Bû/C2ŠøŸkIÅ#}¶ÙÙ«šÔzx²5;á%à/æÍƒ7"°W©Kÿ,÷Xxt^UsKL’c·a‚‚Rú&üáMz%Çn‘8³äYŸa¶ìü´8é™£È7HêS£=j³ØßÌÃmÿ<[<S“=ØöFHtc>¢œõs1óÏ·ÂüØ›_‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠT¤"©HE*R‘ŠT¤"©HO4ýH÷> ˜ 