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
VERSION=1.0.0
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
‹ à¨Z ì½ézIr(ê¿SO‘†Ø#RÆBpÑBµ4†HHâ7“”ä¾ÝmN(Õª`@ŠVÓßýq_âþ;ß}”ó(çInl¹U@J¢ºgÆ‚Ç-¢™{Fvâ¤ñO_ù³ººúhsSÑ¿ùßÕµþW>ª¹¾¶ÙÜx´¹Ñ|¤V›ÍÍG«ÿ¤6¿öÀð3Ë¦á†’¥ÑÂvÐ¬ß_ð»ÌÃüûwòéÀú§³ÞLo:ËêÙà+ô±xý×6W×Öiý×š›®?„õßX_[ÿ'µúÆRøü_ÿ{ÿÜ@è„Ù ¸§jw÷hK»½-µtç`O'ñEØ‹3ÕzUU/fYœDY¦v¢‹h˜ŽGQ2UT'³ñ8LÕò‹“xç$ŒÎ£IgÓI˜e‘Z{RU››kêÕ0œN;“ÙùyU\ÆÓÿŠ&Ã0éÝù ÂQTçÏ–ò6üØšMéD~<™Fý0Q‡Ñ`2ŒÕre+*£gõ”žýëTPï¦#x»Ý‹§æí¥½0›nÂä<ê½¸bôï„SÛ·Û à&ÇÑEœÅiRh¢àfG³É8Í"†ôhFt'ñxª¦©:àŸA¤â¦–t#Å3Ta¦&Ñt–¨nÚ‹é4ÊôhN°ŽÃ€¿Faœ¯Ô,‹zªŸNT”\Ä“4¡E…Å¤³©:}»Sƒ®á'w–zC`ƒétœm5çÐrÖAì4c²8 qì~/îF‰žÂ«£½Úz}õ_î|¹÷Ó^Ü£ö_³(R0*@cSÁ´aÍ®hRôË0=§Ò	¢þ…Sl	ÿëÒRdÙ¸–Ýù`kj¸`:Šÿ‹»ühÑÚw‡ovÎŽOÏvž-}t¾mÕ*@AÓsÜ…õtr^¹¦´“žJûw0Ž€ÀíÀv™§êm8œEÙL(xÛ>>Ù=<xÖ¬¯;‡­££öÁÎ³Êéñ›vEÝòsÈ8ì#^ãþÇãxÀ~qxÒ~VyÙÚ;ùxÑ¤»h6ÖÉöñîÑéÙAk¿ýli‰=–£–VW‚Óý£³ÝãööéáñÏ*éh\¡‡/w÷ ÷¥^ƒë†ÿz}i©œœ¶ŽOÏ^·[;íãgú†œ*„¥†e[úèô~­–ßF¢ò¥‚¾ë¦ô¥•`¿µ»×ÚÙ9nŸœ<ƒmù¯é$„½Yï‚öññáñ³ÕÀ¥ˆ/_I÷r–t‘¨¾„ÜÝî¾¾ŒK½ÉÂóhyE}Ì³Ù8Ã+npÇ½#9*$¢¦G;é~v®*»/Õw\Í/òµÁÅDÕbõ=îîÝ ‰ƒíösUÛQßƒFÑÛ9€¿á¿`·_¦“ÞK þçêç²N”ªÊˆ:WËS”#óðmÎëe¯—ì”9¯OÊ^ï¢î{âË“h<Œ»Ä—æ pæm?š|/|·T7y¶O¢.ñþý0ÙLæ€+EÝx¢ÆòˆxÉœ·Ë‚x¢vE:—½·—ž{Yÿqïðr‡kn÷Õð°y­jçSµª~~Š¢>	ô4·‡Q˜´’Þ¿Í@”Q»¥k×ôs4±«Ûå8^ùû«Šž÷ãà:¸sYWºµö™°˜GMãé.£ñ×Úê„õå•à#Ís÷àèÍ)Éæw[®Ëˆ> ö†ï#Jîä
6Cr®:üÓcÜv_Ê	Ô5¨å€AWV¡J@ræIÌ·ª@¸™5©ÀUYQêtw¿}t´‚5Uù—ï~¨}7ª}×;ûîõÖwû[ßTVž>u^=>žÿjrÃË$]àíÏè÷ð/Ø«×o¥â6xÀ¿{ê%ýR”…]»*$Ð‚¯+ê™5 ¿tS­.,jK}t)¶·c2ÀMTQ¿NAq¬…Î~4ozûj1Ó¶”þ3Äý©ùv9À}O£ÆnÿÆKcí¥^Ÿ:3;¬ÜÃgW:ÃÅà¼¦ÎL‹³í¥ITäMw¸lÏŸ—Íéoûåƒ¼=ò¾6,Ò¨©<ë¦j66ØG“)úO¿‚rt“à+Qž{Â’›ÈŽMóÕ#s‘»‚¤-hÏ.»j:Í£Bó6LSmƒC ëêXÇç*¥³„4ñpr>Ck9««Ø\3kÈÞ»éõ0'£ºÛÅÚm»Ð€Õ2Šö•ÛÂß¼¾«•Ú $š~’NiQ3gdBž¶^\+è
¾·¶÷ÚF»9{Ñ:É!}c¯ôõ“ESì=/ÂxˆÚ£7Ÿfó&ÈÛélØ#ÓtÖ°Å‡óòÐþ	`†iØS?-}|}äÑ¨ëAºàÖoœïI
Ò¾ÍÆy&õÜ÷7n|¿=™ †p8=Ò"ü×oœ¿N«;™%	ê/âê¦£Q˜øàÖ>\/sTôR¨ë7AÝ³Œ4«¢–íRômh+GÑˆ7¨êT$³Ä×0Ÿa$³ŽeƒyÓS©l³%<bÛ¼%>a£;8Äm›Š×ŒŽÌ#ïèâ˜³?¹×ð­í³R¿—;þ'OVr–ÊŸgÙT]†Iªô÷A8¦Þ6ýÓlçMò>I/žú}¯†µ£äºÀüý1G£ôÔêjÞóæU«œLFÈµç^tÑHfÃ¡ir0J ÒYOïµ7‹ÐÛ
Â/„]xðbvîBGïº;küæƒ:.IY7n[g	Ë_¡†™ðˆÛîðåÝxVØI³›ÄÓ8~¹ 1mŽ›‡),,ì(4ø&WV©t3V©|uŠ)¡Íò¸@õ²VEUÓ3w×šÆÞíÇJfìÐ±>IÂùÃU¿þ
¿ü³ªõr?»ôzm®BoØ×"·¹ãkêÊ›´)„fõlçêÈùàŠ•)Î„@4Lt3ÂŸš8Fß­°W+KO«¢z4ÉzÙŸ`‡þ'jeêÄEºTÇsáM>ç»ÌzøXiº:s—ÔMR2mLûwB°n?Œ¿ÈóîÐþtŽUÅ›ØÆj-ü žXw<ºÀŸ¡0!`ÁÇ\Î©ît½„œü&ÚS¼°Fˆ»í<š¦c Zÿýñ$ÅÍ‡bVdô1<'@Sô†±5$o«ÁE¼µ³õËV{k‚:¨1ŠX½†'®z=Xáª#
.VrZºó[¼¢ö¯\BF2=<Ô¼ò$è¶cïÞœ¿è®ÃnNÛÉŠ:níín·N1´PU{Å§Êr(Ò“]SK\ñEšáþüc8\¹­-‹:²«Ü†Gø€…G¨çÊìcØÓlØˆ}ÿK‚ž¤è¨3(“t¤¦éGÓ¾Ì*ó0·©
À64%Í_Ê…ñc¥ú‚}rJÐç(˜Í"îcÄeèºÀ6yÚÁ"
øÏ­Z¥Ô}”Ð®~Í} –>½Û‘‰\3šþYÄc±ý"	´±^\‘€9Åj–h5xlN#Í“w -k5Ž*×ú“8zº‚'IZö3Oéï£I:Ž&Ó8Êp¤ðˆqd'²s ÃçÇîœTéD¡átZiˆú¹OTy
Êi'Æƒÿt:ßhzÍ…JÂÞ/¨'["ÄgÀ™Ãü?ˆœöŠÄ€{-V÷³Æ,5jû.%Â[¿¤ œ^„Ý÷ÐVíî°£|4Nã1Æ51Ã€h’^
–Ë4ú0Eå~©ññàiÖø)i¨ÆÓë9°òþiµå ,ýzÉQÔ!o»q0åž„|N¢ÉØZHz'îš,Ÿƒª£éªû…&z^ß+š…8kš¶×wÑçs±Õ¼º%ÜÕl kÍÄ˜‰!:ÅØ<ÐÀŠÑ¼ÛÛiÑNŒ õ1ÃŒ¥ÜÒÇX¬˜Ö»¿œbÄb9¼|¯î¿h¿Ú=øx|ò¬òSRû	ì¶—ôgåéî«ƒÃãö6H‡gÍ§lf=ÛÄÈPSý·jüG«×›À4³.­á£Ÿ¾¿½ÜÿéyC}„I-/­óã6Ož¯œÕ§êƒÉ ¡gþŠ««·ïŒ2ïï,XÍfA“¿y‰ŠËÔ$,ieÞÃŽÀŸç·ŸUŽG¿­Î­©øgA°ihã0_†ãXÆYÉŠàî÷=O·—T­ôÝ%yñ–ŽAoíìï¸Âg®{£8¹… +J¯Òµš+Ã¼)Í[ÖRgúg¬êÆš/ødu™‡¶Ne+ä ÿêlÜ[•§B¸×ªáe+]kZ¤þù¿ÖÐ=5Ä- i}s­”Ø?À×Ô7×<ÒÅùùscÞ…ýXû½SR¿}~ÃÎÿæ¼½ß%ÿ{},›ÿ½FùßÍoùß¿Éç[þ÷ï”ÿm6Ü?Jþ·dþ† ƒè˜œ«eßR¿ÿÁS¿ÿ±¹ï4‹û“S¸ÓüëÿAé×¿a®uI¦7’Â¤_Ò|Ož«ÚH}ï¬0<º}ºõ—äZß>Ñº8æ=àˆHln<)›óvazæíý0*ñ[”¿þ-¿ù7ÍoVßò›¿å7«oùÍßò›¿å7‹üí“˜dTœÏ|ß²›o€ÿ-ÏøóŒï(÷÷Èý–ûø–ûMÛoA÷ê#­ÙMY#«Û¤1­ÌO’äþ ôö-ò¨öŽS à§ç9²õÛT_-‘q´oµ)™ñ·Èd<™“|8‚†ŽhiYëyºí¯èÍ?U?©ÆùÊWË‚¼“,ÇøT8a{¹µ-aÕÂ¤†Ž/Å¸ÞMå4ì”úEr/æœ0ŽhŸnchfÊ¬Ø=ÕDhÍ†~úi"…lÎ«8£aéªë†œ¶^<+vTÒÐq¶·{‚!~ÎËºP÷ÿãÞ}{\ì×îl
#o‚pØZ)Ê"AÃ»Öñf×øšžBÈû©dîsà¼Ý£QNS|GºÓ:m]7à‘ûÖ,‘œZ;kKéŒ­y‡iVÁ„º%î½ß0 âñQ[±cÀÁúƒŸ?-ÃW~ÂQÔ,5~j6î¯Ø©¹F”Áx1‘Ü”
²xvxiEèz–E‹ÈZÞ dÁ 8~Ëàr{ˆô‰º_½¯àÿV„íËÑ›$º$v'¹*n³óèñ5Áý)Àþ¼YbN#MÈú”•Ùsh>¦‘ŽUŠ	‡~P_Çp"¾nNJ:/ÏÉóûqI¿ô³å KPfŽ«9fâòôÜ¨¯~U‘Þn~ô+}„*ú#œ×SŽdõŒ²$ë`@EuÃm9u’_ªu~W|3TåwXÉèý,+i6®ª,Mº‘«³Õ-‰:üªT»Ó?ûZží@ë{…­×32ÅÊÜ÷ðPÕÆ:õçß)ukg÷Ø÷KxÃš?c,´Õá\\>;g~« ÜóZ{ìEžeÓ	*1H;Ë¸Íjºµ¬OŒprœ¦Sæ¦½-ä¨Õ5$rÐ¹ïÿøãVg&ï·~þùþJ#	0»Sün¯]˜+¾;(éA1•<Ã6ï‰ºÄ5Öeî7~ªTª4
 ÷Ïm‹|[ñ½l¼@igžŽË-ÖÜÏ–>êÅ¸>3C»f…Þ=y3Šê9ÜÁÒœ€ÛÝ±³Îù…´¶÷÷[¨ë‹A´{pÝ`ˆµa6s­6H³)M‚nà·[åÞ*¾l˜˜ÁæâÛáPPn[È`ç`ól'¼ùýùnvì%€t[ü‚ ÷”Ã`ágLˆô³"ó;?…|?»u²$/+çL½ŸK(Å@Tnz¢q¸Ókß–pÄ=ÃA¡HTÛÌÄJ¡OÎ¢ôQñë€|PµŒ¼*‡Ç[m£žÍ=7\AÂ±&H‘
’“ËËôÇ¿4W|þPê>Ÿ¿ì·ÇK6ë¢e×3û
˜$ÎQ/ï~·ïyÛ¿@bõÒË¤
ê§žþe»®e4Á”¨W¯g‰“[¾4\|ÉðäFT£ ©!æ5ç‰MñymcuÕ5ÿ‹KC—ŒŸœ_7·¦„‚Àb$—¯êºîÆàÿ–µúyÿ‰Ô?ÿ>õ›NþçÕÿ]ÛØü–ÿù[|¾åþNùŸfÃý£äò„¾å~Ëÿü›Îÿ\­7ÿnùþ¦Y §?áŒÞìíÝzB<)½f/˜!œ^£à/íöÑ³O#Àf£N4Áé½‹¢÷2š÷Q4`‡1ÓïY¥VÓßbœ\ÇÀ¾¢^Ãóo	¯Ï	¯Sõ=’ê?~ê«™¨ù8;LáFÅä’Ýƒíãö~ûà´µ÷-…ö3¨öo*…ö[‰ào)´ÔÇ·Úo)´ßRhkK)´·Ê ý–Cû-‡öórhE·+æÐ~Ë}] î[îë·Ü×¿«Ü×».þù7˜÷:ÝŠ·F[í¯‘õ:€ÜT¥¹£¿ENì]Öêü–äYlø-Éó[’çßq’§Ån™äÉW+è—¦è8×¢Ù‹}×Áç+,	ÐJçpˆ^qç«#ñ¼Fºh³ß/l˜¡s6LÕ&®Èe½W	¹âƒƒö»³wíö_ŸË›ÊJp¸·c À6¼®-}ÄÀõÊ
½þ¢µý—7Gg'm <îô:…—”÷–úM	z³€ô°‹E/Û!”¼ì/ÑNaÎ¸H4Qa&lÇ×7Ã€(HÅÙä\â™Ù!Aö§ô-ÙW}iÚ¥Ÿkù7›8\®@ŒëÂîìa5E #K_VuñS‹…’(‡²@µ·@
'Ÿ:\ËŽ¿½+l‹é¨,õTà‘OGÞ$#T3£k´an1‡Û¬ìÒG,ÎK…Ÿn™Ýéfvª²µsë)o§I?>·Ëx‹‚º¹7í¸aYTíè¿ºýÛà¨á¦Í2Ìúôü¿ØÌÛ><x©žÏ›õSÓ•ÿu <û„¹å_½‹Éáõ14µŸ<å†&
Sk„]®ól¾cTçë¬‡~ýU*™Îåj5…ãarJþÙ8îÍÃs–%AX°•K¾}rðüÄà¥›úr€o•ÿ+½|vþïÍ¹¿Ÿÿ|Ò+ò-Ò{sêvk6M1%§Â$Òe™îg*ö@LOaõê$æK»ç0·œð¿)Ý»dŠrëÃÕ>nÓ—Vë<¤˜õ=©Ú¤|gæ Þ™™?ƒÔB?®¿×‹
RÉ WævôµEw”™-Ãû–™ý	Ÿß;ÁõÛgáÇ»±å+õ±8ÿûáÆ£Í›ÿ½ñH­6×76›ßò¿‹Ï·üïß'ÿ›7Üßyî7›Ét„¤¹=žÙ\¸Cò[øß^¸¤¿ZD¿'1Ó?/ý¡DtO,eÒ^p&m~5/L'™M§ê*2wËÖÕOQ¬Š×‡äÎÕg_W¼\ëŠçbzÑ:y}vrøæx»ýãêÏ bæuY¶Œ¥}J—‡k¨ %#Ð.Æf—Á¦§–•è
À~ªÆ—=°áOà,Î¦SÚ Ð>Ø—ÿFÕWl'¨Šû_Éçžz‰÷­ýç,]ê=‡ƒp~µ8Ã=ÁHF6Í‚öËÖ›=¼Yc‡	S¬BPHöuÅk#ª»Óˆµh¿•øvN€Êiz²¶s
­×o/EÆá7#u»µç¶¢£ÎsÛ¼ 2ÀüœVâVÑ´;·ÚÇºÏó¹­NÛûG{­Óö‰´Å‹º†¸ÁíGÇ‡;o¶OÝYŒ'ioÖ:P9v„éÒ¤?ºl®Õ×êÍ:ð¶BÃ—ûï4fÑq›E»¯žUXX‘SI• ÷Ì¥Èï€"¬ÄõüŸõ"\_»Déô£X Ðßz[ûÃp¾mÕœ¤ˆë[5/™šó¦ÀzfÁRóÚÒÄž¹™7 ¦¢oZDn‚¤†+²¿ãuÀDÂŽkQ»K¤©ŒÀ.èK1!YœÝäÞCÙÃë­ºúOL÷øäÂÃØ™¾ÑÙ¡–\ÞEýÆæ~ 
gÇ2¯OqLû@ë ÿBÃs}fÃ¯T”É]ŽÊµ~g]†«Cs Y~&0í†l¢¼>js|{õ(ÆpÀgžåF¸yÞ™ì1ÍÜµ7/²\¼Ïh¼ÿlø6í/†ÞÛLv+[ËÕì.Åo…5v:.°KoT9>éN×çŒ¶CýäK;õx®ÓñŸ[o[ºKó÷'vöKx2j‘sØèÅõ{À•ÛÛ§‡Ç?œqÂ%)È r¿AgÞN9œ‰öÝ‰y×ù€Óé•zž»nv|zúèÙs<îFÁ;)Q61ÇÎ¢QwFÃh«4/’
·ƒ^jù“üÔã9ˆœ(!^Ã\6Ìœ÷¿z†¢7¦²lßŸæ¤ûòø&Ñt6IT39®ÙPhYŠiaFj~,½™G$ZŽ3ª®Á^ùÙ4šŒ°ÚxÁðJ‹84÷"uÔ:}]?ždS‡¶R¼{ð2Ñ4‰z<Õ—À
i]«Ú0Êeî9¼ºõ¶½s†ÀŽñŸk'ãÃÜ9g[#K@ø-¸ê	¬HÙ ûBõ
pù ˜"ÈyH$ ,¸òÉÄ"•²	êÔÑ[j7Zù¾vaè¼®OÖËS&Y?q,7€°CÑÉK’'0’RÉ®ðtSÊ<ÅäZTkU¢2àC“§œ´]“[âdÄ×¶§ä.ˆT—H6™0ÿ¦ÌOXâ+ºiS&Q¯×íØA­ŸilÍ¡´BJ©ûÈü=;fˆ^)N›ÑG·¤oÔ¹7Ñ„o®ÝfÅ¨G¡~”È&ò³„¶KûSLr{/yo® ¡xˆºAÆf}•o¨|å=µ­eœˆéŽÙcßI‘ÔpòvDišiŽ¹ÍÉÍoL¯%YZò¾¹eæ¬3@É/Í¥¿~zêëf³J¯”–gMb®6÷‡*§W–*…TÃ¢žÁ=LQiLEUñ²6½¤Ró“ÏõsF!ß–N„É•C³*Bt9ˆ;Mµ­”ñ<ô%™¶›ls‹ ¾4ãÖ¡q Š†ÃV€‰Á3àŽu&~‡v
”¢¹š“°QJ0®ž{ÅäÌz]9¤M9³2³‘ï„çP_I¶wŽî>™ææÑÛ§ÓÚçÒÙ]ÓÑ×WK‘vuÇ0›ú+	xF Ï±æÑß=“§ò2nK˜ßká Ë©Û£¿*àáø)`ÝºÝ|Œ&ryµ]SÚ¬	Ö*ÏÀl ¡’£.»äá‰9Fc0Ñ,›~É`LÏ°ØâýlˆÂw|óY-Ë.Ä&!è+¡ú[-¸bNc:‘\ðþ1NýOpö¤Ô„›h‰¤›f
*ò]‡ýp`YNßà§óh*ƒc¶¼³{|&?VÒ÷^…œˆ(
9š>ˆ÷ÏV{²;…ý
ð¨Á–üÃ…[’ÅíýO²òO?ÓáBæšcÕŽŽEcÜ9i·o3Jaç·úL?ax‚À£áÝÐU+"pgªRËÀŒKtui” Kù7¤H¤ŽÁg^O'aw‘‡··`°Elw8¬SøÓ dñüe4ï
zË‘15ƒGµUHU-}á5wyÉby¥ð&¯•òÞ?äÉÒÛÊéÐº¥çôwÂ\CÚs—×·Ü“yAïí´ŽÔ²gåËçupjzâ·•¦g''{…æ-Ê°.mNÎˆÂÇNZµ¼¦_8n}Â¾þMfz«-œ?Ï"ð·A8¥ÃH)w(˜²²Õh8I	[Ô%Ú®Ù¨0Æ×§§GÊÿÌ›6=)mj§£ócïdoÝy©OtÎÆE±éJL­’‰áê–_Cp2Æpéù¸îyB1ïN…hvošà.¯äqîNÕŠÏ
_Ë>ßø˜{6?÷´» $Î	MäÃ¦Ý³ó}ú† òý:@–^k:ø7V<pŸhÍ„üùÀÖW\Ié…¾>äÃù ?-š¦¡”hfÔ¹íçÖŒÈsKxJLF?V{ÝXŠf’Ïã/7q] N6þx'Ó¾ºÿ]m3SßÕškøß‡ôçþ7CS±8#qEŠÜËÏ©,-ÿ’ÆÉYçJ5 Çµü‹Dbþ&BÆ4®
a±BÚ1}í¾üšÜÌYÑ*ÏÒÎÅBÖ€Ù›]yA8ÝW`jZá@…M5>cÔ¡ëà”Ž¥å¹Kï»KïÃ/þãçSŽšÎyŸ~tçxíA-¾DBœÆ~6¾ÿ”O‘ðw<OúñÊ—*(w€•$«eÃpÜû››w9º³y_³ßo½õ¤
ö‰·Û]C¨ Ä˜õ±²qÊSÇ*°–‘žÌWØûŸº§OÈš{¶ÔôåQm²Àôw»réDF¡;õïoÎã¹sŒ«¹§ë¼T#“©ë¿|‹»G´›QSšVÿøÎê0?>g,¦º:FèþŽ> O‡Wä^u^*æË•ís¾fô‰³ù-gR<àG#(äù¤y»¹”Ûêåvº3€¯QéÐc!ìn¹%ó`ëãïƒmè4ãOqxÎC)]Ñ¢¿*ï«ÒÏâÁˆI-Q÷äA ·âJi’ÊÑ¨6þc©1¾¯G`…^VëöÏkmŠºXK¬†xöŒî¹Ð§t‚ý½¦ÃáwÙ›XP^'_¹ËãöQa’®ûç.±úuù™CŒ·çgWélÂ[³~~vOs4Üßô‡=2ƒyWYñŒ&¢5SÊsG—ÄÃŒÒø8ö§Ó^ZB›æúã'åm˜œŒÙ…m®?œÓ–èà£þÚ>~âÁý|¾ýe­R&	ònâ9>âÜ[y·cÁI—këúKÝ«Nû¼‹uŽÕy#ïc-8X¿ÙÈGâÎÄUü3mOÌÆùý •åÉÉ²ÒÄ£"#›ë¨Ó'¾ìæét…êe6‹îiý!Æ«J#÷b£ûÓO¹Gì£Þ2tºåPà–¡­­%-wn7ëÓLŒa¯—Ÿ	&Ìdß»£?>oÌE®ý••Àäl,m–éI4áÓˆïC½ãñüa/JÎ§v5W¯ƒ?¸§Fxñ@6›DU,…""KcHo˜ÜéP¿.™²G[AÕ†YðÙKÜÃ5ÎØ0[àºçà€hê³”MVƒËN'³Ès}g ‚`%:0›€$ñý«¢Ël»ªÒªý_aí¿VkO°¾|ÄÂ²vL¿*öý&ªé{bqà÷2,9ÍÿøG ÄŒäÖƒôÏüGÐUþtÔÏêÉg>!v@¿}Ÿ§Eòg~ÝˆÌ –Äd¼Tj¢Ïn¹EÒîøx¯[¹¼ÎÏ‚V	´Ø‚m¼ý²SÑ,X<oNN÷ñd¦‡óª=¢ñŸ×’Fxm_òù’}Éž{Édã:ŸgNšï—7§Üä’æø<×Ü‹8Í½çwðŽ=­áË<Ïµ×îùièç¹æîYT·¹ó¼ü},ÿ†~^»¯Ý/¾çMå™ïˆÈ÷äH<ïçyñ?üc_ñŸ/è*÷ÞÙ¢Õ)ùeï•L%´Ê}žIp§¤©Ü_]hÊÏË^ é_Ÿ—5¢´9<÷š»\Dß-ÖÆ`~±£Ò§\¢§ôŒP¶ŽùÜ…„Â¥E),ª!'2~Zr¶!'ã5lÒ5.{fv¯æjjÙÕKV©ÉÖ+:2e³}`p:Ä…çšu˜Ë0V ¬8ßø*<¹oÓõV^F ÐxäÊäZ‚¢j¤f$sòÑ·AåÄË9ÄÀ‘™„ÍYÈ‡ûìûr‹_Ù°þ„i€S*®uf	‘Œ¬pô"w°¦ì R/_éøeÄ‹Y/#Ÿ\mBI?»‡¿í2ÉRÊ1•"ŸFˆ:ÝÈ˜` ~ÑK BQ[Ò TN…jíí¶LuwjOyÑ0
IÎ–ëVž-ß¯ÀÿýZY©? ähe5=¬J‡EçÂX¾‡0–~]f(+ fe©ñÓZã~	”ò×VÂGÖ"‘rXþï@É–Øx¥$fµô‘&•Šã§bÀ_{É>¨r\e!xÁð¯jÙèø}1þgøE…“	{4¤B±_#ìÍ5v_âí ÍÊS¾Ìè©V¶À“¯8ù	pÌsœëÙ‡á4¾°Õ`@ãk²ÓþZû
ø@®bBêÚUN`DÎã5' ‹Ú¸/ÍõÔy^Uï”Iú“ã&Å£´ÑÄ|5'~ºö†“îí”{éŽ†´ŽFirÌìÙ’?å{d%é%µ;Ž2PžU*Îs‡aþX6¯{KºÌ±lî?ÿœËþJR0Ù§ÝAU¢0ÉØhï‚‰É]Ö% xaªÍv¹½Éqžâµ[ÈL†XzM-O¢Þ¬ë½ì°<‹§’3zç”Ó=eÐª4²Ëþ—p]ê*K}›Tƒç¢£C¿Ïò ö_j‰QZnKkt×ë’l£† +x7ù,¤í×™­G£Rìÿ;èëÐaX\íI
H^†u1è›,úô8dÃÐ£‡ÐDnCŸò±ŽšE©Ê;Xˆ«LáÏIšÔœ&Ôâe:¹'=Y³Å”§Ç‡CÈ¦q÷=]>&!>MáÝìYŸÄYJzçgN·EÄåðà6vRn	£+ÓI¨²!V²£ÓNá°ØÏGÈVÓ¤" 4]|•›±îîb ÷&' ½å±W ]R%ÒÎ¢ëÑ{›¢ fgr,Y}½sg5Ÿ!K¢KOÿžwáÌá.x~vrz|›äNo:ÍsÅW8âøÑíäÚÉ	mú9«7¿PžäzÃKë¹—tüú†×r™¹›½á¥Í‰³7¼zç	²9Š@Âôò˜-Mä*âè÷>5r“'€…	°óB„Ÿ“0·¨ãBêîüŽçœOþì©”¤ÞäA.l £Ð‡~Š|‡«räré¼¨šûƒÄÖÌ[éóÎ0Í©@ÞÒ²V+K~PynZe%7Ø¼ ùü ý¼Ðyþ¹OIŽtjî,^ÓF)½ßó
8ý}†ñ—T ˜Ce5ÊŠ~Dc`¸ú=V%5£6ì¡tïš²
a_ ô ]n…`&'ºo9‰î[^¢û–õ^âßy6Š÷Rˆô+GUë†¨«sŠÖ³YLs°©±03ò`H!{Ô
ßG‘½DN´æºv*ÙÏ»:´íˆí*;åUPæò
Ÿ¾*‹*O‘x¢Û”9‘©|²òcÎèßÁ.üÛÙJ¿ûN¸Cæü»éÑ%Ú}°ŸÛ­Ss¯4f9Ö¤Š„ÑƒøºËŸuQ "E2×0ÇágÝÁ¼+ÄM¨y òe÷nñRƒ'ðyïb¥ÝÏzù^ÔU0nÓbI£zŽ.´wýÖ(fŠ»S_…®$ºy˜^ÿ·:)ÍÏ¿ú)hçz^d})t{ìºü¬ögaæ6GºÕgcæ÷]÷›ê°âÌn	Ô/ˆÆ;Ö>Å+Ô'¼±\›)%½57µ¼'[þœ¶ÜÂò»®§øi–Ûøî[<ö»c·+§µ[×ŽÖ’¶?‰¨Ú¤5èa–ñÔ-Aš¯Pí@ZXšÚmGƒqÇ’/Fø%£ÉÁºiPùæ¦˜(:5ñÎd6õû¶b U	œM¹«£ü6ÔƒBŽñÎ-ÖwJ‹íœª@åå¹d¨sß÷9ˆIB éè±[“ÎàÀ÷j–Iþ¼º‹yõé‡iùþx·Ãw’~2¸BY$”²nŒ³]€ûùÑúÒ%ðÃºº’ï|òŽûbÎÌÃíˆxns½švß»H{~ëaÌQ°¦ô%‹ò¥XúšüÏ«Ž²Æõ­J‹qIŸîŒå{,xîµˆÌ¦‹¸u²îDÊîê¥ÝÆ×¾cjñý_|_ßÿõQ«ÍææÆú?©Í¯=0üü¿ÿ×ow»}pÒþj}Ð%osÖ¿¹º±Ù\Ï­ÿÚææÆ·ûß~‹*ù¼:x£^µÚÇ­=uôæ‡)$Éç­ä ­WÕÚõçY©5Xì  ?¾šÄçƒ©ZÞ^¡‡êå$ŠÔIÚŸ^bè—x×'MªkìÖÕ÷R©Ÿõëéä¼ñ<Pí‹hr…™q†—nŽâ):à¦,_‘ÆÒÃ³™qãÙÐ¶ðPCcIlÎƒ„7‡|ñ—’Ÿ!®*hÏ)s˜É›\‡p8L/£^=˜7]úM¢pj¶:¥„°F‰’Cu4ë@oúª1„‚vEUñ0¢"Ïü‰ ÓÈÀ©P)xõ>Nz”zÎû¬®;‘·2¹*¯³-¾;ÆX}ž_¦:Û½(‹Ï±þ=^&ƒ§5ÂËðŠ$âÀðª…‰3	IÛâ(õâ
]rxÞ´LoœqœL£¤Çët>'!|ò=…1i@Riþ!Ö=9Ÿ„£ZmšÚƒ&Š.S£[ŸœÅ!]š@Ðõ6Ë ýL‰ÞŒ‹’ædPžbµå‰ÁüSK8cTŸ±”7Ìój ú0("í”(Qß¹¢†týŽñ‡t†)8	C(„-™SHS¢„w¿Œ0‹$|ÃA˜ñTñ'œßïÆ£,]¬þË8Ç{l§Áxã9UuàËgëSòPO990´€2M¯	9;‘7`a|jY–/RFò#T÷ ¤ºŒ³ÁJÕti@f¿‰²ØM{]½Ò±xÚ´ôbpbúìÔyÛ8dlº‡×qµal]IÐ-Ð8-¾9KXÀ½ÇÄ·G9¨D3Xš“÷gŠ¯N1+‰ÖØ^F«‘DŒÃñ$º ¼e¤quƒŠ~…k„“`˜ü"Ž3ÌÞËO´;É3Í÷MëVuâ°Ò).<6ÄE	ºÑdRþÈâN<Œ§1_¶‡JWÉÅR»ûH@ô½¸$¹U„ÃÂg8i—p‹Ð	3/ñî¿áh<¸‹FÍº»ãuN:Çs÷„ÚÝªÉdGxÚÍA4ûäž, ™ &ÓŒg„7ÜÉ¸²aõdç ‰ã%´éªºuàcËP%Ài¹˜Ae ¢l![™ÊhˆWük2!<É¦H4 aJÌhöÊÈ‹³á¦—)Þ:Î¶‚åæŠÂ+N'S’5,{9Þâ"e/¯­ ÎE0}!c’ÍœÇšî†Ñ90’ºÉx»Uw\ƒ¸£ŠYu®Ò¬guŸ½Ìòîëéÿ¥iÂ»À''Àÿðì<2÷@¯Ä$bñÌs‚²äŠHFíq—:wÜòcöO¦ÓÖØv‡á¼x	¾Gri§@ˆbòžŠ3’]_åUäaÅÄŸAe|/¸\N7=Š/%Q:Ë†W$x$HîÈbøÁôGx;¡±à—n	FnÁóR!Ýc¥îÉ,	ŠÓÈmn|!îmÁ&‡x¯êù€šŒÂdÖõ6Á$N—¥ÄeP¦²Qf¢ú„—Û  L#„Í‰þ&E ÆÈ½¾@I²Žœ(áÌÌËTv¤L÷ç öMbYC·DÚíÎ&W£Î@cdÒ½ˆ¬ö$Ü›8FœÃ[ÈLâ.eòŽ‘Cdÿ’éŠ¯žEÑ>K«ã)ú“|Öz±¸³‹Ñ‡/ÁHRÄæÓ°HqV±6	½¦°½ôPëtâffˆ(œà-@Ù¬ƒ^,ŽMX]Bî¹¤Ñàï=:GA5ó£¨nñ¨ ˜\3K,1%¥—u% ÕŸáêâìØ«X‚e•–VÌnrŒ•*Úáq‚ã«ªtÍ¶™Ó…ÍO 3ÒT†¤óãÏÈ÷°ºmDp´3ôoÝ@$ì¦îT³ò®àì‰úV÷ãsÒ¨ÎÔÆœL¯Ó\'«ûD4i&¾—’xF¥ƒ¶æEs¾¬ÎÏí!‘N¸±«z„!ÖêÍÄéB¨€¤:‚·v1uH¨+Sóª.šk¸^–ãžinèþ`
S¡k‘	FÐ]c/ŽÅX
Bä"wHãÂê@œ—Ú§Û«Æ¨w8|\N	ÿ07/âjÌ·…NÛÇû'ªu°ƒ•|vvOwN°ñjÏ»Å	÷HïWNSaõ”ÖWï¢u³æjáÈX•V¸9‹ÝÈ»Ú0~—\
_g•:òm«€,›ª° Áh#’fèÎN˜½7ãŽÀÜ#D»ÃFßôIhÒõÅFê”UŠ³@^©vI¶{=XòŒëÿW@äV UE^ˆ²
-IÅ*5ÙRƒËã`¼`+‡‰TÒ7
i…E2 á±Iº¿XÎœ 
U/Ó¶Ã/”õ/ë€ïxGõÃlÀçUP`"K·Ú…Uª‚a:ÜÏâ„X´ã’ TÀ.k%Âé'”:hpqÆ‡* 2pGˆUdLê±¶«H¤¿*Úû_¡ŽÝV„Œ–ªtS€mðYEPÅ2`Ø]‰éSÛOÐÑ£ägƒdÜÝá9e.äñÜ#2!+å#I…pZÕ×™.ö.‰aCK@º0Ž,BÒé _‡ï@Û)Nú¸t8JŽøS—ZØ5‚Í lúÊ6}íû<pÏšI*£Äá¯¨ˆÇ| „ÖìHæ‰„ ’8ahøHàñ‘eš,€Ó·¶»L<!s“Ÿ(ïÁ˜v;+¨@xt)]É8!åé›°e.£áÐ¬àè"Ê“;îSÜó¢%˜)oˆŽ{è ‰_ÌZÔ¨Äe+°°O:Cè
ùQ$¹ˆ‚u© 4‚êSÕå™Ôô×¬Ï×K†¢L›c68~¼h6±ý\DÜ= -ÒE€i´Æ,_p©öH_?HQåÈ*ØD¤0å±¹+‹rI¬%* ÂKI\£®>ˆrc¡}azfw…éÛ’[Bý;#˜Â"±9&XZ¬Ô']‚Úp'!/Ä¢"“Æj‹vh›³d¬‚k³+<R2Ù@aJ#/ŒqZ¾Û8Ù\¯Ã¯l$ÅÀ\/F“Ä5!IXé1±e+kÂ vì¬ÊÆ.cý ‰œnE{4ŠÈˆEÆ8_' ƒ£YWoÚFÓSËüŠcVÄTvÙ«èÂÓÁxPÙåóäßâménV¶0¦(”;¿DÄÁ¼Ý[¨{ÈÕ¨hè1ÞTUÃIOíj¤Ù×Dò~d†Óo`žÆ¨‡±²‹ô%W J†tFìd^z%ÀdK{Wè½¨jTÒ+ö¦£Ì¹s‡‘DÛ¾;†ÆÛ6B4Aû›…çèIxxzï€Ð†W¬Œ…£o`´v;N›8«°Â®Ñ	™7@PIˆL­ÂÒQ¸²U#dñ!²50²•Z!)“uéåp…½¯ôvO#!…¾ ë|®û><g&¿þHØv•&Æ-nŒ%äJV%€¨yà4§=ÞYQT1¬k1cÝXŒD@e¡_Üú@jè&b_	‡Œ…i+2)+Å…e‰u!"ÐcTr£¨Ùà–K¡ÓS}F2„ÍMQW#ÃŒ8<½,¿+5"‹OzxþÖ˜Qê)H<c‚3åu’KHB˜XÖz%2O·O`ßgUÖK°ûxM´Y f¥uÚs;ØEvÛòn&0µï!Lí³!
ÝöŠ‰2£ñØIìÃ$¢$‡AÎ1æ”ºTSU{,„xú<N;WbÓ+40„ævF>ÙT»šìT™à	ŸÀ+Çd8¯H‡bòY½–þuz‰VkÅ¡IØÕ{Nƒ½ŸùíJHÍ™Ó4e%\~€`	‘ÂÚ©¬iw"Öœ£tV&™ä²Ïwe`_ö·%¶žó´–­c`D¿£H;KF švQ¢÷x»Êjòâ±´K!üæâHÞ·)hã(ÝUŽøZä /9E¾=ëÔ˜ÒaÚÐ›…êzÁÄmW´8Åh
lÊÝANisŒf‰6bÉÜeRè£o¡*Þ½ÆîwN-”b#½zƒ”á•]ü.µ_»r'9Ô&‘­Xæ^-ÖX±o¯»€»[<«æùûg€£gÜÎl­Ž'ò3ƒ„ÍÈØ…âl>§(^¯D"¢Ô?k%}(m
Žè#íà'0j0‹‹”­Ë1]¡w¨8¾º58šj—¤îß)¶‚Ö€Nr“Ï’a<Š†ïÃÖ¼¥hõ‰q
Fèï¼*Ð8!a¸6$¬ò½så£ƒ¤ œaHUuJ<rÚŒø‰<rŽÅÓÙTtq<??ØIz	ÆñyÄ3t˜¨ÆyÌ1-Ô4‰€p\„C–Ï™EiçÊ·	i)þjòˆ\ãˆ±Ø¨õ†åDPÀ´ÅX"+×ÆžuÝL^å‰h“µÐ1o÷¶srK¢ˆ†b’z4¢´ç:OMìLhŒ®T>Œ®ÌAxÁ›˜6™p¾.Åp–±SAÀ¸ˆ£†8”ˆ<8£ŽqõÙ¯žX¶,Ž#‡RuÌd2ú•B w@–7"WfCÜ.È·&1ëg"!Ã…ÄºÌÊm°s–‹;ÈÜ¢2UM‘KßÃl	Z N4‡ýªìozÄ>À] >DJ•62Í]£ŽÃ{Ä[Føì#ãøÇ³Í4¢ž8PŽI`LŒŠžÀzâ1‹ x“huÛàMœ&ÎÞ'ÝÙHxò2EFPcÇ7FŽ¥Qb00sôr*uBê"¬)ñ^>ÈSôÁ8i®’“7CÝa†5«A'DÏ.p½Ž|DÇ=ÞpÜƒòcÞ°/=-Vµm2úêžlÇƒÔ[<¥@"”Ó ëöŒØGI»˜a1ºƒ$¦ç(LÀ¶)Œiqä8…`Û«þlÒ|Ht>—Ý!íÑ%¬ÙÔ"èÝîÑ¡Ã8¦èÜ˜=0k9ãvmUí Fx½ùäÉCÜSAŒM*rÄjÑ¤*.}ò$zhXžCf3xƒWðy%Ç‚/CDNVb–°hdQ ñwb!ùn<œ)ÝŸò]&¤ax¯¢Èˆg†
jë¤ÁK.DÄ&Ržù-Ê¢PãÝ!FÐp&”D3‘E‚L¤Õø®z×Ì"»urx%È]Éˆ–ŽÊ·«â’nRåíÎ1Õ	SìÚû‚L™™ÁfaÑ‚rlÒêmÔ}ûVçgm³CÍ•@²º¹.=1‘Ï÷3O¥aáh7¦€ Ç›%žÊÙt’Áàç ,Å‡­Ã5È²Rv„þzÉ3[èìzÐñAX1ôr‡
¦.²£úJ_‰ E«'&fÓû=ìR)VÅ…=²A&¥Þ‚þÂX®ÝˆyÇ•ñ¹=¥aœÓæóÍIŸ(÷A«T{³óÞp³œÝƒÝP®‘¢‚Fò7
#‹VwQP‘ôF@8œŸÍÆ”4ÂQ;
mò€Í	¡!lºÄ¶¯u;ÑŒßºöÕ¹žþ‚¢*ÚFÞ1flîX4Eï%ñ½h§˜KµšEDQôÒn”Q¬„¹"	ÓÐ‚f® Ûâ]¸BÊ+{ýPØwaWŽ“±”(M–¾2 ¿Ž$‚„”Àv)VX J¢Ïê‹¢íô¾IŠ+3'xg¸’š÷·\˜GZU«|G2vzº? A¤ˆ*s6NE&Ú]±9BZ‡%Ìob,aÇçDþð}=)Ž¢/Ú¡®Èf8ì‹4Ë¢Lg„6F–@&S”À, êîÇœ¨7Ü‚i£Ç¨öLDWÕÜƒFíŠ1Ì$‹’¬Ñª,Ùy8é1ïumNbºb<¹)¡Ê3\± Eïû6˜‹Km­:‰“á•Äì­‡†‰3Ó†+•qî„*Ée”©‘Ex›:ñsì¥Ý\JõVt±IêocŸjL¿9µ­	ÊÜÀËSÄø—<á•ïI&d<Ó’–À×H©Ï¹½°Ì&4ãƒ Ã‡tqNßa?<;®àëPL?Œy9‰Âõ"¼sýœb÷øn(2}QkO8LDŠ“—wä):Äß}0°yõu„T»uXÝadå‰ñÎWÑ`DcCÓépÆeCà4éˆóÂ‘ZpBÌIP	ÏÏ‘ 1në‘ZÑä§™¥¶"_Fh*«f$d9+à)Niþ}IO:°DI¨Ëé¸¾½lÈ`è)!“­lù(JÿÓ3²>ÍnÈi„Î–D>äj6öiuˆhç¡+S@YqúgŽ,õ%%c#™VfÀ™ù›s¡ÐÁÆÚ©a"ñ¼RX®³¼JÃô”DV°óqDê¶é/çL'Å Ì6¤«Q@op•‘,i^dÙú§%4ºR%}o4“Xû•˜K”»úâ¬­„ª7›°ÿLCg€,Áè gÍ’Ö¦V8!ÏŠößuÎ!3µ	Úï	kUE\Ÿµ=Ã :à~Áü««(œ°ëÖiÂ’Óñ?ierÌÒjÂ)ÖŒGÉdÇ;5ÌT@ÀðÆ0ÄÈÔR\D·h.¦$’I	¹¼F™^ä·e	ï.Ž¡ ‘èQsÕrzà‰ÂoOU!%Í]¤ø(ål ñÁÖËÒDN8 ®ûD[Êiˆ>c½_F-&ªÂ”d›Ö*æÁ"êG•;Ô$êHR1A¬'ôìpWßºt—N2:œ+Ò£dH^ˆ×ªt€®1••kùÆ™v*±£8ívÃŒ436G1¤Žt,p†%Ú¨Eû•Ýöòá³5›ÇØ‘<nÑÑ
âÃŽÕ‹ælüŽXc´yý™!?=QéƒJËùœ}^V-ƒÖKí¬úÂ‹Š#tóûÄ¤.ÓCîœ(€ËåÌ&ìdj`Aeô$1¼#·¡»œì ©nŠ˜óHÄÂÐ }Všh·:—”xãqæoïqÈ•Šˆì—Ù3Äü€ø¢Ýzs®¸ö1av™»’Èåx¾ùË9šH1[]”¨o½Ã˜7üaj
g–YHP9Õº˜C†s±[Çú«®™Aš‘Lrf|®cîëUÙ8ZíÜd%x£Ic²V¨¨%±aD†[gHÉmÎ<k2“]ÍÝ53òŽ£hR›¦5ü—Ó¿LÊŸÆ0ÁÁ‘Ç	û8QR	ã®$îÇ„P¨ç„—;sÛ>	Y&‰Vë	»kÄ}#¶¶Ã&zbJ°…@ÒÈÈq>:D;ƒ®Û#–NØøKÊ·n/ø\ÐlÜŽ	d÷ühJ:iHèŒG;eh…†âHhÊÌf#62¨‰6tL¦S0Å³¢4kX2¤Ñ2‹`o¹	3˜iãÊUÝdi8‰[ÅcDƒ~àS¼Ê¬Ô‘cò&á<ìÉÑàâ€õ}Ñ	¥¡÷0ÓÑH0÷TÊ¾£I†F{ˆ%íÏ›l5è¥³Î´?ãšÔ™:ÀÒ¤ÃÆs?¼H)m‘4ð\Ÿ¶q3¨ôé+ž(WËI±B³§ª*¢¼¼ê`z5&]1å,:¼çO§a¡òa˜eÎ‘jÎ-¡ãÆ3s¶!×¹âIÐ	éx…M¸É5ð,Œ%/Qôø$ÙˆœÇ	€Ó1Î²£a†‘Q#KÑž¹^,9œã ÕP¨÷f¨M3ª¸Š·tÀÃ%št|ýIº"E H›@#§&»Í"I`ÔÒs¡Lø]ÎÛay—8ý­ÓƒÜ-ædŽ`Zi/«"mt£ªrL2ÖÕûèŠÑËŒ/¶°5Ãí9GÈ‰ÀùBQÉ±­¢wCçãyD„…÷ùLh6_£‹¼á¡W(Èf˜ªåÅŒ§q2Cf …ÁEñµeÜâÄ´Í%ñ@jÊ©‹rT„Ù »Šx^œšC¡ÍNDf¾BÊé`šË(”$ÑÝ¾DK
¬ÒuÅj¦/vÇa=7+§/§iÙt±ksƒmŸOnmf‚˜,CÝ•³%c¤ïzGí¡Ò¼ÕÄ´É¬vdœQí$¿jMgñôÊè¥[Ð”ª²\êÞôG˜Ù+1ñ”Ž£ T„ñ¼}ÿ¶F*¹;‘k÷lë«y{àÏ$€äz´§‡|:XÅ&Á†k¤ vô@¼«‚ƒqP•½+woåhR]³æíaœ÷Lº™ëLˆî ËŽãÃý“¶äŽß±£æM½˜¡9z—¹à´Iº#¥£ëè4ßË¹û¡=k·ÁÃÄ™Š¬’¡«ªRP@¡æø& ((ŒÚ&u¿‘[är%… 2ªhØ7‰:œÙC^q2I+b÷6tÌÜGwc¹ˆÓ!Ä£ÉÍ¤áL»˜ÝØal³êÂî$Í2¤h,ØÌæ®³Ö†É!çÆ=K7ŸL¢—O„uYØºÌ`Ž
H|Dår†ç'ùÄ9±]©wm9“ÖgMU2@H3¢‰Y‚a
¼£ƒR’ÄÒ"l=ªc±e—9´Cµâ<µ<6‰ÜÔ¤qÉ—.¸7õ±3¤YÉÇá|ò“ˆýL"-ölÈ­”‚{%%±&6Á11î 5¸çŒð!7{ÜÔf>Lã&«»Ž,/Ãœç€ûú
gž0«$]X:ö€=ß:KÝÍ¡5q[9î9™êHª¼'š¡£yãÀæpU	t¥’sTIøøBPHÁä9@zÚå3˜›ÃÎª²ÔœF(uø(J@Wžp„¾¼Ï§rD	Ù9|0¨Ïh(,±<‡JyÚkfóv%^”^Ê0à=4â¤fÛ—z‚¹LïúŠ6‹%˜3|äÂ«;¿YL~LÊÏ»£ð¡.õ@þÞÒ¼Û›ämMqé$ŠN}Óyôyì|Ü‹Êè$8ÌcÁû®‹4«H§Dq¶ÂÈŽ	-ÊˆªðnÑ°W2
?M‰~²ÁIH"kR§_`|c^tL&ÖJ„ñIétfí¨É'9dª¹IÌ´ù0?†§¨cê Ä±9nJfËäÂˆ/{„Çq?sÈÍ¤½ph”Ñe*2PïÚ°ù‡í[,D[	ˆD\uL–QÏá9Ô<B6¶ã©}w·¿ÉyJ1¶—'ƒa%ÏãÄ·–feøöÄíœº8‚™‹-Z!¾:C—tl/s¼‡ÆÃ	Mù%;•Þ
,Ž,6¶œI5$•¸ðÚ‡ƒÁ«½èïS­w%Œ®l;ŠV0pÈÈÄ`[.«nÆNóÅü 0ÂHh[ð(ª¶9—¢	~2Ûoß¥4x/­ÎÎÄ)`¢—L<³ùW~ŽrçÌ›®ZÖ§lsË(™7+ú†3¬µEÞª0±MÃq´öœ2Ú×¸N®Üv"99e¨®9l
RJìâ.Æ/¥0§˜Ëå’ØòÙ&$³Ñ=úòµŠ¸æ“
JêÎ]v"útŒÈdÞZ»®~`r—ÄèÑÒ=æT{¶zBaeiIŽ€VórÞB6µÂª’‰X†-r– ¢Sg¨›ªÑ™ñ r ’fÁ‰ hýÙe>ÚâåD»ªŸ#ÿË‹%JæNPÞ=OëÔÎó#óøFÙ¨Ñn£ölïBvæßõQÐpYÍ-zm@ó¸,j&	Ï$°¹‡™ª”2( §Bpý¼!äu2…œ0²Ø%Š

ÁOQ6:~«åìŸ4¿£ªZ¡’”u	Û#·NÂ“Ö¹†&"<Ñ¯…™c<Ø€$êÆ5dºâG ¡Aã}\'%NØáæ}Ðy4sbÄÖ‚Ê­œè¦1 0Ì@™6”TL¤¢Z¨ºNñöMçÜù¦·ÀTžÂ‰U\ØT£|9ÿ”ÕT&yU´ôÑ gÇ»ÙÄJ(Ü`Ì…ŠØÃ‚Ž­~<¶Õd×Çk')Œ”wºD‡J’ù]ª"NEž¦f$Ç]Wu^Tä#"ÿÀ+QB9 ,žar¨±2,Õ#½SUI/èsÁ‹Dÿ`=ŒTrªÍ­à ïƒåMÛ7P_b–ÜÖ¢ƒj"W‡!¿2Ö0äÃWU´šþTV‚ÎcÝÛ6%¬{‡n…ÄÀA¢3§Â”ô4“8Êœ¹7Ï¥Ê+³žÐ'˜Ù"[ÏÏ7á5 z.Åèó´¬Ÿ®X;.È×:èÎ$Àh¡ü®»ø$ã†36†3Š{–?à¯…=æ;rŒ[ÏîJÄ˜Ùdèü•Š¨M‘]fP¡Ó7L4QœMq7×µ\1	yäLß=I½˜ºKíP@Õ9ö¦þô'²KSS!/¶ð
´ê¬„ÀHY/{µÄÙ“:yÿÆrÉ
 ?Ö„òšO´åŽKèÜI78ÂµË|b DÉ§«èÃ¤S~^F’=ýØJºÀ7CNå6ÕRŠ)‡äÍ'•Y¢¡qá%YrÒà† xàKÆƒÅ›ˆÉêÐnƒÐ`É9ÀêEK½ÒCn2rjÞ‘~úq™áœóÜ1ÌHNb³åÈwœ½¯+Zòi½’Eð+É¡3ÎÔØá£‡ŒäÂÓª$^!Ëâ °ï¹Ü¤û¢¦ÜÒ’Ošˆ2½“^Ecùb 4øB/Qq*Ãyæœµò£*žtÕ|*sÜ¢}iŒ‰ªÄ­m=Î²*\è…úÌfŠ ýËC¬¿¤:éÔ"{ì‰ÏeÆ|ñŸ!ÎbtH·ÆX+Qôâ¡ñdã?ÖøÝˆ‰9q?|T“^¹%¹XóÊú¡ÜÇRœu&£nCj¬xaŒ¢É9SŽ[ï‹øÛ¼íHbÌcÖY[‰*ÎNÒÜ9H4å"—;WdÂÎ»ìƒ3M09×4À¼Ü¢–Ÿëóká`ûÕ}ªÈØ£S”ì†¡ 'XÀ¤{l `]=òÄYuËÏ4¨ÏÃŽKN)æÏUÌÔ¹S0ä:gL¨Îùß)©š+L,GþŒ¨ú}L¹*¨Íbo#ç)1¡2y“c†&ö™;’"ŸÎ½ÏS¤½ÒbnÿvÇbuÝIz%R–:)t|zËŽ%?Žyµ•®Ücµ	Üá˜fÆôxÉÂXªñ1H^ÊH¥ïôÁ#¥3t•`øì\ñ£¨KcË°{6
Re©l…³fª6³‘Ê±‡C©<¢ì&ñz¹Eá°›ø$§JšÍº:Òe-uÉ¹„½Žé¤¢or*#î)ãÑ¥3%f|NH;…é¼j1G¶'ccÁÈ~›e¶6¡=¡Sd˜°ÝQ›ò{æ‰×ÒÃqÑ.Q*¾ÿÝy€à‰zN5'žê ®Ú¤¥!×7»¢äÀê  eU_?­jIÅó(,è¬8)Ü Ì%¨îš#áA1eºŸ'ròi	‹å‘RÐ+#
¡ŽLóTç‰OT ,§(é½_v¤·¤oÞÑëx¥	Ùb.UYÈtX±ßlb…v¯JQ”;†OÓc¤±Ë.£&&áÕsP¨!'=Û|¼ÓŽÚQÂBòk˜òXõp2ìaU-Ãuj\3Ç3¹ÖïáDå"à’”—…k)³Ýi—ó·e_¸*Å•„{—‰Ï#vdéÓŸ˜éÍL„ŠÅjqEÞ§Š?IfÉ•vÐ4ï‡ßã)ûßä|&¤b¾TÙ”JEï‰Èº¥Àé²);—hÈ]Xªëw¸¿‹(	ù ']Ö0¿?·pkO®pYÛ
­sÅr÷W’X»02¥æ:çªÏ™ma^š4ÜÃì·,Ë)§¾b5
²ž†Ê§Ôæ&§º
ƒ.á§S 0µÒ©L0æMêsÑ½$)Û:§Áé$wäÁiÊ2À–”N[C05UtŽ:©¯ú€Øœ¹ÂÐçˆÕ‘¥s›¨ŠÁÀs6<"¬Ê6
%¤Š:QÉøVsaJ¸;^S¹lyÝôPu9RpŽTL#0õ±uéé`èšMÆ"²G°âá_òÄ¢ÏŒDRLqÅÕ]Q0h@Ž´”TAqR–ƒ‚{›už	ë_ÚçÂãƒƒeg+ÿM–>Æ`uS=b<Î	b†S¸¥Ð´E Ì™;ñ» &Ëä0Œ£‹È&aÈ®«b0›…œÅj3L3‰¼2©(\‡~RÈ1YhæmN5 ×@&Û3HgÚÖ‚b	W¦3_§øa"µÀÍŽ21^Ë
èÍ”ÒÙ¾flZ`& sÕÕþ\K©`M'%TBoððã,çÂfR—ç²§Wü.Xñ#G8EªMiQX[yÄ@W¬?2‰I¤¤“«ŠÜjYHÀã8ûƒÙ9ÙCœ^5_²¼ùÂºuf‹zÙz¬XC'—žd´›‚ä§£Î·Bê¾Ñ•Œ*ñäòjÍ`L–<MÐI¨”X` ±¦j’Dj;’ŸL_ÀÁ´)'$ÇáÕˆòœRP¼ªRšFûW¥Hà'æ[ÉÕèsûËÃfÝ¬ªKšVm¯ÌI´Ÿ®°;´ãµJÇ’\òÉ3|ªNZä
þI<¥™$ZIÞYæü¹˜JûöŒ{‰Kýãã„€qÐGNñLze]›-jî`ÕCÓÎ4O¤èlÉ–@
Ž-"Ak:Z¶˜ƒ¥>N.Cc=W­×}í±Ú'°ZxgšÎ/Äº´¬ãö3'5¨˜Üdfb|bN;©:d c$f˜jlZw ÓÁ¸i¼ºâ’˜¼Í¨È˜ºìfN·»éÔ•ÂVÍµ:·:1×Áz"Äì>ÝÌÕKGZËÕûcEOê”©emR9»U†áp†£?ÚÁ®(ÉbÃÄ‡^Ü5iùº‹²Û•®oˆDq‹ýßÐüwëVýäk4£ñE|–Jy}´,‹G³á4Ô÷Äp¦^¡2—çÐ%RôI1ôTÐÔík"^
~y×ý#Ä;Ì¨øIÞU¤y"¢–x6&®O×ñÝU¨ë‚E%T´G*9‚i4gÏÂ[À`FŽÈr©˜rJE®«c_ A]ó#ÌE–Œ	N†þ71ggê5ÿð˜[Í¨¹^ÇŒn«eâ½-´ ÓE×S|V" Q(ó%R’÷Â‘°DF!>¡¥‘wó„ä§–^«±pøJŽ“±ŽØº¶Ö«[|!wƒœ)OA¦P¼›¤ïU  Ds„®ÀdW«s­‹êþ-fWLàmòºÑ„ÓöœbþÆê2&'8£¼Hþ8Ÿ®bzÙ¨«ãVÆý6rï^Ê¹GMóî"äÌV)@6hrÁFÝ„1=íy7Ò>Ãpþ¥‡€cÎ3´u¹>¬4Ž'±9Í+Y‹ÆëEÆŽ’“ñ…ž(Ò:|	ua.5bÑíÄ™4yn¸2*)HM3˜:®‹n‘Ì°° Éü
Lr¹ä€jmÐ¤óþ‰®®‚®*âÖÅCÖëiîu¤øv—Ò08“š|wŽgÎ•;bpë„*=ÂÀŒ¯ƒÈ@S‚u”ztXº)&Æñ„Ú®Q­êÍ'!›>Ö¤:J¡ÿÉŒ/(ŸC×Z´»#,, PÌ‡+¾a~A3ƒx_Y\Dþ}fHAHâ¾ÎçGÐ÷3q¦øi_~PÕ¢ÉMùp|ôZÜ1Jº~CÛü®Ù£Õê–™bõ\|&n¶d:±Ù¹›÷ïä%©÷†£(äÔ%<µ,	ÐiI†iÌÅ9AÓ’\&lÐ^<¢df·Y7©áLJï$9œYÜëöq[íž¨ƒCõ®u|Ü:8ýA½<<ÆÔÑñá«ãÖ~UÒ÷ö¿Ÿ¶NÕQûx÷ô´½£^ü´ŽŽöv·[/öÚj¯õoNú÷íöÑ©z÷º} ü»Ý“¶:9má»êÝñîéîÁ+¸}xôÃñî«×§ÁëÃ½ö1ÝPÕ€ÞéEuÔ:>ÝmŸà8Þîî´Ý1©Jë†]QïvO_¾95ƒ_Ô_vvªª½K€Úÿ~tÜ>9 ìÝ}q~Ü=ØÞ{³c©ª áàðTííÂÌ Ùéa5ÀÞ¤­†Žƒøûíãí×ðµõbwoð…×j½Ü==€.w-ùö›½Öqpôæøèð¤]WŒB ?Þ=ù‹‚bÿíMË ìŒ}¼lûræÀ2átÕ‡oPDÀ¼÷v<¤ ¢Új§ý²½}ºû¶]Å–ÐÍÉ›ý¶àûä€­½=uÐÞ†ñ¶ŽP'íã·»Û„‡ãöQk÷±´}x|ŒP˜ŒÖ9¹Ü<ötÖ2sŒ¤ ö[¤7{ˆ‰ãö¿½¹"•(ŸJ~ëÕq›íÐDðn†«gC1aTéøÁÆ@b‡jÿpg÷%.‹ÎöáÁÛö'‹À³%ÙÖ‹CDÌÈ.F€XÂuÛií·^µOÊÀ>¹d»ªNŽÚÛ»øüô°Ç¨:8¹âÒÂ¢Z°Æ‰“×1x	ð@ôÏÜÁ.Û¾‹D©öOƒÖiKÑˆáßml}Ü> DÑkmo¿9†ý†-ðÍÉØ»¼8_Úâ»Ç;ÞdD·/[»{oŽó„‡=
$ ³Üâd¥àâ«Ý—ÐÕökY6åmåÔkXŠmhÖÚy»KÛQúAî
N`vAðÈÔ÷¨Îw‹à•†O
‡T\áÕó˜ž9ƒ‡!Ûô{Säƒ3mí~¬øS,vÀ‡W¸²°ä7žÒq)NP%Œ.Ù:Ã.lÿ³‚*ÂK±Ù±Sw˜òIP<ØòîHÈôiu²tˆçç©p2«¨£ÇñÐ{‰ÏÄÑÁl"©w6È,ða;s´~¦èÒböù²®% KZç97ÚÏk¾×©E(ât®SZþŠ¼PVe ™A’{}È¸´·ët¹rZ"$2s:ç˜äN%þ2ËrgK«É¦\Ã÷äQ7i ‹§u6«CtÝ&ºFù>	ÿ"^}³ª‰/iÛX_’F9bULªÅhÕW}tÊhþ:'p—üÐYØÇ©áˆÍÛ#Ý4*>mAIDNš=ß×’y7b¤‰7Ó©jè%&HB®%Ý[W#ó§btš
ËâQã”Œ:ö/èê9ý™©íJWÙ¢n*Äõ=¢“Þ×5ÞœùßÏè8‘€îLâ¨”Ð'yý¹T%ÒZÖòöŠú«Ó=‡Dªï=ç~Oå¾V¶á-÷–¹oÜ[äxªíA	9ð¹¡òˆâB-9Ì<ûBüÌ×á«ÚŒ)¸l?Zö›®-›z9ì<ÍÝU/èC:d³fËÉUiÑÕêJ­²=5çj±‚ÁÒÎOË¬øØU^óäÎS¼”U¼N"¶Â";\‡0ØLÖU£0áÒµÉlö3ëæ–ºrN-2‹K6Ø1ó!Rß¦ÓñV£qyyY?OfõtrÞÐéç0 ¦îá¡·´	aÞIþo¾zœjÞ£Ÿo’&X5
ï
	Ç˜¹ssåØµC%Ëzè:[ªšËéËVBÄÇdÈ¥k\iRtÃN©n#;uöbá9²ú½ôûüÖ;±@‡\š™pÚzqr¸÷æ´½÷ƒkÉ<¥5•åTÓ+ Ð¿Òï—÷ë\~?[ÑA¼<b?ì˜ô¶7AàÝlEOÂS·»î}w €|ô,®Æèn¤p¡2·êñÑÌÛBú¶z÷¤³_vŽ¿S©Ã>)"&°my¦î:Ñ`%m×>éþêÍ®­~,×8Ð€fäkPP˜€.:é‡ŠÉ›”!S®)¦ZR¯ìëô
3Ä_moAÐ7úE“ÊéBû_·FQ/¬€ÄÀ4¹X¯bÃø¦¬;VX1w~¼41uãðÍÎÎµ’¬¡á±ªÍæÆ›·a“7nRö.à4ÆåÃ™nn±0`îúpå°±½—Zÿ9g%¾b‚Ø$Å8f$×z]Éa;.ûKç:q2˜=SfÙ|ŽÛö(¡¢©¸!åÎ®ýY¼.u.Â¥¤àÕÝ:o²‡i`“yÞ=ÌŠÂ^I´KêÐ‰Ì¦ãX˜BSºãAªt:\5.W5@smx>ÖÓÑVçŸþ?½´Û8n·vöÛõQï+õ±ººúpcCá¿nÒ¿«kü>k›×Us}ms­ùQ«ÍõÕõR«_i<Þg†"†’¥ÑÂvÐ¬ß_ð;OF™ÿN>÷Ôá›¼ø-
Nñ²çª`ÈD´—[¾Ý©Áïíäâÿü?ÿqK¹”“\¡tÃ%)Uæ¶0?zC9j%1¨	§AFz{ÈwôuBÄ´l@ç³QntA« nÔÚ‚1xPmâÄ"°€:eX×~Âéa'‡»;ÞhÈ›p&axœx:Ó¡S¶®t½X`€#2´qÆ`èÃ#Lsš«'Y&ó±ç³ñG‹Ç4C‰Žb¸õï`èÎÐ¤dP%tk
ßÂì¡qG£ÑÃ3ë-'ûUuÜÚ®R£W3,+CÕ‹;gÓY¿oãmqbJzGÊ(1’V7r&rè&š’j.é7¿Ì$óÁƒtÖƒAÕ³Áƒ‚–ª¾Í;éÇç3)D%N²a5KºvCÄX¦NÒŽë¤ .0¹¡KWh‘ŒÃÀH_Ì©±/‘—B/hÀJŒ‹ÌB>¿ÏÕëòT„« Sn_¶êb ësÕðü<à(˜ÄÒWe/NfÔÛýÿóÿ¿0*ãNÚ}ÏpTæ"NF9³q'ÂSŽblÊëFOcP}þíªq2DÓî€úw<¿—º·eÐp2€Uºw”élœ[.›·êÑ)Ø3d`“ÓtY2‹:…«‰è8“ŸpYëXƒG–þÊ*ƒ®£ÔØëc@õÃëýë_ÿŠÃRÂß¿¸­ÿn¨áß³n/‹~VÙj³ÁWŠ6Š©Ú X[m>ª5›µæúYsckíñÖæc…±ãÓ-¼E˜%¯.KœV­Ö›Rxc´Ýƒ—‡j‹1µ–O•˜ÙqZ÷ë®.|ùMÆ×Iòcmpñ3ü·£¾?„m»×>{Ñ:i?ÿY-„§àØ¼±{ 3>Ø6¯þX™ß^î;Ï_Àó7;ð}û/oŽäñÂŽnEmPê¡£ÍY-“Þ5B­ù<Z¹	ÜÅ|pr¯4Þ†Ñ74ün‚–Ã©Íy®v4§©«}qÄtÂÉ9U¼¨³I· «›>–‘	×ýÆ‹ }›ošKªW.7œ‹æLd¹õCŒî-é_Wê7uÑã.0PÖ…Ê»°È\|ÙI8á	¬À/À¡­ú„& etÉØÁ„p¹ž*ä¼ã3ÎëœRÝËqáì&D´ ïä0ŽÜÔ™ÉdÔ4z#èÊG:â«A?¬Tnê±d_ÞÐc'ì¾Ÿ³²>ù§›;¹SŸ{,ì”øÝ³YÒ­ùñÆ]^Æn˜­ûr¢kŒâ^oáªßØ÷×ÀôçsÐ½ôœää–jLGã‚Œ¦ç($ƒÀ+œ))zNéVÐ»x¤ ê0Ñã÷<áã/.ÿ¬Ã{µÎƒÂ˜¸æ½äŒ°6ç šYÜ°Žo÷Êß~€’ûZÖêç¦Êxøâ¦|Bã&\Òhûœ @ö{W˜ªh‡WKõ;P”êªL›ˆ’ó-Èj´?õ‚G¢ÖK5Œ”"9ÈŒzûqmu­Ö|xÖ\ÝÚÜØZÝü4}¤Y_­¯jäNzÿýeîË;xºnŒ§pgQ¶ð7™N‹²Q¦ØÃæ¨”«m.„äŠjóy–ÇÁbZBºŸO±wøjˆf·é¢wÛ§ÛgÛ‡Ç7tß  n¨ùF`órÓ»FŒß½ñ=OL8}¶#+OýQ“Œ¼ÅúŽí½Í<ø6tt|¸ófût.þuÅþ[€B¹µh)T£?ºl®Õ×êÍúz}õ6€_î¿s€ßà?·Þ¶rãeÀÙ¤ñØ„_zï›õÇõÕ³æÃµ…N¶wNÏ^þÛA‘òæóÐ… E®!s@Õ¶vìÂ×¶)ØnZ0Å|†ÙáÏ>eX£ãÞnw—¿uÓV,{«È>£ã›wSù{·ØGå/ÞŽÜ8ßÛì¾4FP€8_X´Vnó"Pç4ìÐ)Eú«žaæýí^D¯ö'oë¯Ÿ¢~¶Ó~Ùz³wzæBÊ=½`ûò¤¨<RD§œ|@onÐPéá»QpKê'Ñô•ºO˜
œ'ìÌÓ ã’\¦ ÊXkÿcB	Ð}ƒþÃïžuA‰£y9óßÏøZ:ï1¬Žþ3‡ `wìÊF€å‡<ûç°÷Ýï4"ûµ¦ÞsŸÔQm<úClº€ÒóIŠé*~ó.QrÉþçÙÉ~}|5L¨8ÿ!Žør˜ÁÓlT—Úµ¹ß5ƒdãÜ/@ ÈVÁxèæÖ»µ,!ÛŒã3¬%QÇ)ñ8b%Ö/Qaê[ïÈýâßõ5 Ýt¹@æ+IE[Ônª\obß±B´Œ¬låsAR²œêçAs”ÝOxÄQLPì©Âo|òÍõè›¥!:U‹Ú|Šô•¨öxYBpOm¢î{‹ÊÄÎÜÐ9FàT•¥ºÙu´ˆJEýü”Ž­JQ‹Z¡ærÝ¨ë¶n+¥êe-à—h(I2QwªJûøøðD¹Ñ1ÒAc*}³ð?˜I-¼+‡èŒƒý=«Ô•3…ÆÒGÍ¤ðÙÞávk~9;ha'7­`‚}xèºïƒÏ‡ºXüš¹óõ'Bf¥x¯ÒQ¤7šùm!\)ãÁUo©v¯)4Sîã,BÂtN€Tj³÷ãTâÎ¦ÑXÊ~ÆVô£4—ò÷@CÕõŸ¬¸>¨«?c[Y>ˆæÅàfäÄˆðï§©=0îUaLs¤Ê×Añ¥Û$Pv,Ü)’k/Ú2´[ô¶ù¬­ó©›g™Š$ª§gir^¹a—Üô:“Î½{xC£ã2B\·&ÝA<(¦/®Œ_ãi¡³£áö˜;Ö3pTì¹Ç˜‰¨Î2¾4n*@ÅÇåzÑ0ñ<wçE,7·g¦J…¾ˆ]<Ü‘öpSf\‰¬
ërîU=gmjØˆ7ÁÍ’r·8“·&3¾cÎTqaá9:¬GÈÎ¼:èæÍÇkGi›N!ðºïò3!º7s]ˆ˜©î\Û):gË±ãZU{p«Šõ]º/NÌa’·¡ 7ì=C=ê%)4§{fO±—.áŠÂÂòÔƒàW¡rŸ_ÕNÄ¬ÛâhX+~Ô¯ù'ØÐ²o¢NA4!|1h˜t"bÅâ’cÜn¡0'‰zêÍØ¾B0`ëý5õýÌ®¬Ó„ÄìÊÍ\žF*›IÝÛÞšJ…¦	ßAšQœGoà½Ö=®JH†ÿ>9ÙS¦Þ×$²i'dþÈ€x žJY‚U)[aª«'Êœ=²™a^‹òè²ãÔ	gõfr÷„u†êœä´úú¯ÐÏ7¡RÊ\,‹’þ{uµ—ÚÒq…i@û%ã„D©¦ÓñU^~bí`bF’žšÇ`µcÕ[\²=tŠÇÝÌÑŸžGq9»²°†ôÓ]M€•wL_°lÎ ý™µñüÀäÃc/1t4ÜÑp¬–+¶r76§˜zG4xNí§x³ -ï¡ÐH›ƒ&Ab)¶
sËÃ.]µºõ3s«Ï€¤ûùX†‹ ×`[·8N±K†ù+…ÇßHõe€™~Y_µòÀpÍêÍdEii¬=õô¥—¤hj\Wûx¢†“³G|ê7ÁcûÌu_‚)+éH/‡Ñ:ˆäª;+ÕKz"áÔ>x«ÞjaœcÔ-¢!óõ(œ.Èú(ks–‹»R¡§4ý´FÜºvƒÈUµÔí¥3ç~Í‡ÜJg]A¦B&üŠ	bs×e1)“4B÷ë—tíÏ±¨‰VO¹bhH…¡Ar»ˆ¨›áBEó0Ó¬.äÂá¡ê¦Ù©Ö$H­ò”ØªçZrõ]Y¾N**:%èÏ`«‘>Cz·So0fXwZª‹žc•S£îåSOh Z†¹øÈÕKm0K–<QÜÐÇ¬÷5'œË¾¨Yî/Qƒ;-Ýçhu o4Ü†yZxçD20T§Dù³.òÛ9rwzÄñÎŸµã+Ô‚ÁÀvˆ—uã­´&zŠ8‰Î™í+«Ûñ
[ðGñ+b±Jh"t:é ó†ë®Ò¼ñR§:È"}» à;wŠ?¸úË;Å6~Wó?åëA]Áö¸±+}STÙü>«S!Ý²wöhWø\¥Ô8ÞÛÙ}IÄ‰h³“i_øüá9‘ÛÏmîŠ t¨CX ÎîÔIy*ãB0û}“°}aãmFú æÓlÂkõuBiˆ¸tÞeQãÜ;†ß™©ê*Ã÷¼$šnÜ¡‰Æ®D)É)+ŽlŽDñLOÔæÒnXWö”ÒÂ"Q+¹b|M=Ù§4‚ÃýÖîA	Žî6¾<öNF0ÿó«Vƒõ×[|´NH®ª©§ÖæS5ô"	ŠL~		4¼qj¦³«ûyí95h»ec€Žæ	ï§²á6à‰Ç~Õþ¡ù¹’ùÎKÅ8w>¼¹sàäŽ*¾—Þ®g2ZÞZÅhúïÉ-á	ÖÖÄyT™•JVmPnðîFÏÿ4ÝALn4¡­î«OØ¼p¶·{rêØ‹Ù¸ò“]§á{0æÉŒ/Ÿ¶^0 £w;g/w÷Êtš#})¸1Uõõ,Ð¥ZÏ¸nø+>¾ìÕ§ÈYà6Ò¹ÿÃãÓBßÜ¿×¹¾œIˆç†f qzÖb@Ö§v3¸ãöÑMãÊ{ânŠŽ¼€_ß"`²Še˜“¶n:¿RÒDöU‹MwÜ)ž¥œƒûÛïgâkòG#é8ÎQ½m¸uƒoÎ–T‰¯{5Â§´œ“>âÂ¸~_É‰]S/›£B*ú‘n¯„¤ÙWUFQ¶ÙÍÇ`'åx'°.qŒv7¹òÄ{É÷òó)9ª³"5rb•öœBÛìt+Q˜a™~©ÕBeP\áIÄÊÅH0xF'¼ÜŒŸL}¯9ÅsàX·7’|Tµ®´Kªûé˜Åv9Ã2Qgø-|¡P)ÈZ_W«ö9ÝK@†-ucÐè–@£É‹˜sH@ño·ƒ)g±ú€40þv;Ð.:ƒ~¿`ÐïmÌŽ®AÏ£>–Cƒv{ÇCÇäsøÙŒ ø‚¥p,è¹|¬¯8/Ï]#âEœÎ…ˆ¿¥ã(}Âaºs9è¯æDoÀ’sêWŸsº[XçJø›Ã«´A8ôËYÂ…½('_
Ýýïÿeøìú™4°–³±V¾ßk¼:}ý\¦O¿]öà¯W†)Ó‡$çÌ†ÍC`6ÍUºn$ìàŽ£JÄ=íÔÊtP…gã±œM6…þ/rTÜÅ0JÎ§{w‚t(7õ"àÍK¦ê¨¥E\ÿ¿þõ¯ÞdÃ¹4E=¶ÝYÐŒžé{Ï(jé¬Áÿþ_çé@ÿù*ÒÕ½Ý¬7[›x«KÏuÓÇ‹äw>6„QeÒÉ"È"m
µÑgËñ-Ÿ)±¬æŸì+¶¥’ßÐ«¨çöÁ›£øÂƒÃwÈµûK'g°NeÎŽ«&¾H•í©ÐˆïJÑ‚”BI%æ/½™¥ØŸúæºµÐ‰‰ä"m}çÑQ<SHw¸Ú@jœ”ÅÏ~¤LÈžiÚ‰ŽéVÂ…”±mhÃdü–šÅžmÀELa“Eä^äÐúíIl[XßàB‰Kš!ã¢h4Ï#¨4Ë£9O>†j	CS,Ery_ŸvëºûRÊ<Ûìu?7¨L‚¥ç| ßdªJrš 0ÆôýÎîqó9ý³¦YâBÕD 8i„ÀàÍ§ ˆ×a±d¤4¸³’Ô·“7œ,‡ÃÆfËE¶bŒ»²½ZW-NB;"T"³“9ƒj'É3ÒÙªP»Y†'¬$©“d(eìufç¨G 4'Ñž…ˆ2|JÿrM`}»™©Š¡[É5.êÇWðï¬sÃâxË&–ãÁ¸e,ƒ“m5H’õsj;jÔ Eälƒ
4Õè­¬±²Ôm—Ï-@& ¶õA‘7]Á×³Y+aÍEzú	ï7à¥Bœ.‘ø$ý=v.?´…òZcÐÝêuúôÝZ}µnî‹I;”£åWe3%ô¦^mµ ú•›öv·Û'í Å"N¿wÉïƒIûuQ«¾V‹ëÿ¬®n4×¤þÏæÆêê&ÖÿYûVÿç·ùÆÀ=Ž˜Ç\`H`UÝbÏ­·ÓoË?ùôVÛmö/å4ø^ˆe*+—ó8ã|É œáüÞ+ñû|hÿÆëÙ ü}Ü°ÿ77àa®þ×£Íµoûÿ·ø<él>êo®?î­E›«;×¢nwãas5|Ò{ôhãñ£Õ°³ö(WÕŸêâù±‡Ñf3Œžôº£^u½õûaÿIoóI¯	@ÃÎæÃÎæj÷Iè¾mÏš57>ìG;ýš?~=ÚˆúÖ£èñÚz³ù$zØ|¼¾ñpí‰û¶=—¶±v›Ífuc}£ù¤ÿðIÿÉZo3z´Ö„on<îtšëýGQ×y[ÎG<Ü\[vovÂ'ë›nÔÝ\]ï¬v»Oš›ëÝÞêãõn³ÿduß,=`ÔovV×:ÝþZwuíqÿQçq3\›×ûk€'Î“G! á±€ß}¸±ú¤×y´úð1àlum­×[[_ëlv×6“×­v×Ã$b®sçdÜ“Ç«n<Zë@×Í~¿	Óï=zØz²ÞëGk]˜Âj?|9 ðÝê“õpýñã'€ð¨óÆÝÜè67››Qô(\Ýì57öŸ<Ü|Üw^ËŸ¸{Œ_oÂ`7›ë‡VaO }Ož<ÙˆÖ›OÖ67!ˆ›Î“un6×:ûÑ“ÇÍ¨ó$\Ø|Ò}®¯…kÑz¯×Zì÷aq|XåGâ>eEGáüµ]]ïw»«ÐñZ··¾±¾5›ÇáêÆ£‡:«Easµ×ï>Z/‚rOâE×Ã$6»«Ýÿ¿½oÝnGÜ¿«sü%3NzL‰¤n¶zÔß(¶“öÄ±ýYvÒ—äèP$$3–HIÙ±§³O³±ÿ¾Û* $AŠ²|‘ä8MÌLÆ…[¨*T6MÕ‚V£ZÕ`¾ê03Z½¡R ONœYâm©ÁÒ¢*Ì‹¶Y·¶¶**Ìu­Wƒ¡¯mjZ}«¶¥©UK·2°H¾w¡¸ìÁ¹'íM!»+N!HÓc½®0ÓV¥V­öŒžU…#¤¤DõªÚ¯õaw1aÀŒZ&²iH æ~¯ªë[ýê–ÙÓ­:4Öô–¶¥«*mlUê¾ªY©¹—\7õM]­UTØ	Ìl›½~¶Uø·ªÖ6–»ü·‘ZI¿SØ¸*õºÚ¯6zÍÚìi°¡‡\­Õµ× [½¾ffjÒÓž¥•†eÖaMZ=Ó¨ö6-ÇVE«5êP¯¶U¡u«^£½tW˜«ªu…k<Dg½R§Fz´¥nöhßØªö{@æªji@éz½_¯©¥4e5Dé¹nÐE÷¾ÀÞAûú¦Vƒ£§ÖzU³n6êÝ‚¡nT-N¤­>Œ@6V•m(]9î´´bÖŒºQ5k}­£Ukô`j*žz£R«Áì6L³ßÏÆ©w£h5‰þÃ°™[T…ok³ªõ½Z¯U…†oÂÓJE£ZšØnÄÊF N¾†fTõJC¯šV½Úï7`búVMëQ8ä4˜:£Ö›5U•.W›uÑü°ëöû¨yÂæZFW­á	ÛS-`°€i«VWa¹ªFßÚTêÖ]Ð²öÒj¥®W°µ0[u6z6Þ~¶Û¬~cK3¬êÔ*aˆµJWºþè_ßÅË‹
¶¸fÁºjö¡¹À“}½ºÇl£ahØC5*•êVýÖÆ¸`(*}ËhÀ¿6¾MUWáœª™ÀžXVƒZU äìQH;rSØ€Véì–Z­Y†Áh Ý›V¯bÕ6uk³Ñ³²{®gö\gsµ¹Y3h¯jõ¶Ì­šimZ½>´s³²eš•Z£ºU« WSË^ZšÚå1ñdüˆÕè«°#ë}Ú3¡«¸Ð¨ZÙþ®±µ¥á®;îæfz'¹a<Ùž‡£YÓúTÝÔ5ØÍÚféŸ&œ.&½@ª›jí.Ë€óu½Ú3-ƒ™”öUÕ´4Í‚Øì0îõÍ°¥*;¦PjZ•Bx½¡á1PE¯öaFð¬Ö´*'5µ×¯ÁøUÃrqˆh´¦6*xŒš°ªv¬ÉÐ‘}…#¿ÞÇC ,êI¾'QÏÂe×r_­6[ÿƒòÊZµŒeä?Ø²+ÿ‹Ô–Ý0Lrù/‹^tsäÿjMåXÈ:ÊÿH¹ü¿Šôì/L8>gîè‹Ñ¤quÚ3ò|Ïj’çG…)oãózáKë;ü©&vò7Ò×/^ít^B™ŽA«Ø<Ã÷)Ñ·6°œ:y§SÐó&ƒÁé\ÚÁ5õ0ôøÂ‰%žšSn™ð½Í^"ß;p×9dÚVòÂ¥þKu y%®ýg Æ µ²Pz×²ƒ¨ôó}Ã¶¹ÞôÕŸJ øƒ°wk‘qHƒ„8ØÑÄÃ·%9&æµ#<ne;9ì°§~X£ä$Ì<ƒñ®n@ƒØ›/ÛV˜y°àôØ@öt°€q¾rº]ñ6¼9ÚW*%õïŸÚwø“M-¬P|Õ-à/÷b' ï±3~aK3áún¿Ìo%ý…7V	#­¥BÎÜÛ+Š™„oÄ¢8‹ñû4Ò/È’ÚÜë*2ÏÜÎ’`ØD€sñ6^üÆ
ÙÃˆå÷é–1*.y/bæ>yºGt‘Æ/œ´K¼Î“ð6$:á¦ŠA"^¶,éÒ^ª™½çÂð±ç·Œ·»ÛßïnŸvNßíýÖæ/^>ãPGáãpI/ÕÄ˜0Àé —"¦»+þ„	/€„ÏY:ìÃ9åq(áD›Á›JŠ%ý2D”´Iç‘[C®?ÃÕ°%LJMK˜Wf¶oÚY@ê°ì÷!aóqŠÀxÒ¬Hnw@˜D)f±ŒZŠÿx/ÔX–á›öé‘ð¡³ñ` Ó¡MåÀ	ß±TÉØ(ñMG(•ñ!çi¦œ&nD‹‘Ÿ1Ä;.Û#„%«á\ì¹ð_UJî-âÕ÷ÒÂwÓd.òŸž’|˜R9/¥Ž›ùÓ55æÿ«vÿWÍïÿV’–Åÿ/Mx¢2À,)ài ÉZ¯EXÁ0ê3wdþ‡³Âr ¾D
àö¤ã{Z’>'bØNh÷—×>ý)b\À§\ˆXLsÙÜö[
{Þ½2\œWN`|áƒü¾}Üzñ‘Þpnz@Ž:ZkýãäŸÏš/ËäwZ/d;¿~"ë!¤iµàkÌR}¿­d9î“$ôZRÌ¾8{(²™cÂ×ÛÔd÷ÒU¥PÚf€‡å‹½T%Ø³LX	`8zÆn/nrªEFú“G- €ëhI&´a6 ‡ì²Ù îÌnV/ÆŒÛ‡¯o; |&ÞÜ®Ë’±³wMo$X|2‚_N‘”Œ`÷æÁ6pÕžB€Á"S‹F¼cz±$O^Ÿó¡]xÑ©x,£E+Üº´R‹–oö_®®[ëìO…p*9ëK8HMáµ8å…‡Bg(û˜OsŠ“¹ú~-€äŠÇ“±øs;Å•K	³!€*,×¡¿2éVÙZ7-"¯ìÿCü3ÃŸŒˆb’´™Ñ*[ô¢ìL†Ã?è:¦\b“¾-þ‡YÑ/7ÉëöÞþîÎór9Ê{¹øLõ›ÝrñGÂ"_–ˆÂî“/È_ˆb37†¢\[‘||I”±g;úÇÃÀì«QëÆ¢¯¿\ô§ú‡	g¨býQúºÜŒöÎoÄ×?|$=eíhå\ÛÐDøÕ×˜kÁuŸd{¨e	ã ƒk¢œ ¥þ(âŽŠ éI;ÐÈf•ÛŒËññv¸‹äG˜%…Äƒ¿.&÷óxS{ºÔ›	ÅkAÏBHiO¿Ú™ˆR(`_Ï JoeüÙLx	hx3RÜðbhˆ(ÊÄK£(CáŽ>¹	(Üà§¡ W†š†¾º½ä°&FÌò¡‘÷°¢„n‘„-gü™l£”½ˆ%ð`km‡ð'ôËÚ9 EÓiÅ!SÞ1‡K¯(¾‡>ýŒßüãFx>¶"ÃÙXQØ)xº>&2’Ãc}üñJŸùùKyþ"üóåÍÝ	[$ÍMtäFC:phRÞuÑ·1ÿÄŽ¤(“;#â—Ø‰/ü¸B¦0kXj­}|š¨ô4Ît‡®×2&´Ö÷1DÓþ~ûd·µMØ’?oeCõ¢ï1eEg^ÔÇ¡Ç›0¼(ËçYYíñ‡Göæ€‹Î¼ÑÕÆõyGùÄ®Ç'cþa2Ž3Ó9{Mè hkêÍ«±Ì¦ãâônÅ™{´Thên$RŽ±øwÃûSK(Î[ë	gæGZ²¬òÉèq¡#Ã»
›5E8ÂþdšÕ€¹!²…ÊäÏË|Ì:á/l·µ~a'vAa”
Åcëá+e›ù.¶Ž9ö­¢Çúß
ÚÔ*5×ÿ®"åúßÇÕÿ&Œë¿K5°ì²ƒ68­
–Ceåêà\¼<uð­Ô‹§>#ä2óË"C,| &–`û°”Ú	õ2}²åé6)öÌZ^sýÿõJÊþ[o ýwÎÿ-?=c¬ô¸·P#m7Š¼~ÐÅöÂ
F3ÁÌŠ”Ù‰r«"·Ít]anMäKú±ð[Ÿ˜ŽÄf&YRö"ì9ÜÃv:»»Q›Â³»ît¤àF~7µÊæVS«WêÍ*¤ææü¼.Q0Û±r±uÌYÿzC«ÆòŸŠë¿Z×jùú_EÊíÿÅþ?íÈüT%¿ Ù‚ZîðØÒÚ‚eµÕHj…_ßŽèÅ;¶{øz1Hï³ÿãóÙ‹>SÒéþŸuUËý?W‘bíåÕq÷ù¯¨Z=ŸÿU¤T”ž¥Ôqùo`ü¿|þ—Ÿ’Qq–SÇ=æ¿ÖÈ÷ÿ•¤©0FK¨ãîó_Õóó5iFª…Ö1Gÿ£©0çÉù¯Uk¹þw%éYÒ)%’0}ô­c‘~ôr‚Ý'¿ãÑÿáã™äÓîþw)Î,ômDuêssu“™«Ë×±ˆGÆ†ºž1ò…£öÉÏ­çøoó9{êªb‹vúq 3Œ?£æyìÕÌß/0X„õÈ‡œ·»(ÙxI‹‹Që		{@ü¢+zV]†"¤”_èÐ§€[.ïãÝxèÒÎÚ”Y‹Wè9Æ°çs[ÞÂL½ˆx|wâñw¿äA/Ì-üçÒ}ç)ÁÿK[ÇÝÏÿš^Uóói*BÛê¸ÿWÏù¿•¤ÛÅþ|Xsø¿ªZì?jU#ª®ê•üþo%i¡úìµèÖom±ŠòµûÜû­Ýãâo	íN\ýe®®µ‡]ÿ­Í½ÿ[»ÅàÚ-o ×ÒW€üÍwr=êA+‡CêK¼WÈÍG®×R÷kw¿Í[›u·„)“/ôÖ}£·ðö2„Bâ‰^D”D­;#Dç…e{ÜÛL}9#Ìr1¬ZxãF•? /\t’&;K9Dó0_ÍbXdÊN‘43­£Óoöb07†ûù°srÐ~—„‹=ðb|Soð2|û5“|º6„ÁÜ\âÞŽ;¤F;{ÇïÚéZyn…òÞÎÏýÊ¦1é¦Škÿ§øåók £*Š	{‘ø3œ•#|W«8ËJ´‚caT cTÜºô×„[TQž‹2ÓR|ZÆøˆ¹fñA—ó}ééð#ó¾Üv‡YœÉP|œC8Ü€p £A‹Xhœ°ë°ˆ¼ð‘Øö;öÀ¡Ö6õÔ€ Q îw2qÐäáóÅH	­(ÄwqûÄu‡þl(ÇUÆž;KGž;Æê¨ã.Ñ…Ý1¯å*‚ï*Ý:Pÿê˜Ãÿ7êjÿ·¡ ðÿ¹ýïŠRÎÿ¯–ÿŸ±ºž¶ðÛÄ7hp=´ñ-Eìº`y¤?,›Î’ A>ÙßÙ{|´ÇìÿÌ3bAž)²Ÿt Æ¤s:éS§´–ö{EmøŸex}rn8ÃÆj0&€{d8|ê˜?maÃ1I.©gqD¹L²Àö.a ôúÆ+Æ´aÎ+ê›g°¸{HÛÂZwÅÄÑ˜$Ü¨§œ&ˆ2ñP3_= $Å&Á £ ÇJàHê`ŠØ€­ò1ŒÇ”ß»@¼Kj@_Yel‡L€b veÏ±è‚¯—\:ÀÖÎ(±ïbgõÌÞ‰Gñ…óT©…Ž·ÝtZápoÀßÇ¸°w|ü››í®ÜÞg`·‡°¹6ÆhpèŽ¨ç»NêÛ8+3pÇ©ËWÌþ€‰Šå(¸äS®70ÙÕ†uM$ù¡IþÓéüÜ®iú×“£÷—ï\LlË<ý÷©ßØòû'š}z4ü°uùÆúõp mŽÏËgç—¿½\Yí_~>Ü=Û{~¼oü÷p÷Âx?T½í7××—oËG¶S«Ößwœñ›Wåßv:±÷ß¯L§)Ñ¤Ÿø%:½¥,øƒ’Y6†½ÜFòUP¦idø0(J`H'vž‘2tÝóàÌs'ƒ3~ÛA“T€ßˆ|ûš&¿ìê0¼¿Z/±‰<eC+¤ÇJ,®Ò—>¶8_ûÙk?]Ê	®'ÿ
4ó,°0PÅˆàü+|þ—³kLÂ™z¢ÛÆÛ_>ï•µÃ7ïÆïþþöÃ/?ÓËÉÛ/´7hüë×_®¿9ÏWýÝ³“ÑÞÏÃ_>ü«ýþ¿ÿòóßÿ¥9t°»¿yùæèüKãøjëÕAù·q»ü®Üù¹>ú÷ñÛƒÍëÇ*ß6&1=ûÉŸ7nI¸k~îv!m
§	„é­_€ïP`O³!ø¬*ÀªY7\z°.²!0–…>ò˜z7ÃxYˆ®0$•b˜ÃMÁ%?TÄûçÙ0§^ñ¯sÆg#Œ¡ÊUb xdƒ}}Q7°ûW³¿Ï2üzÃx¡Ì p3˜ 8Ÿ›0B~òjæ@…½p´éqg'³¡¸¦‹Íš1«1Æ?›–{™MˆÙ‡â*ÎÑ*¸aŽŒô‘úÃO¸ïD¥vË'TÇýO­¢«Òý¯ŽúŸj®ÿYMþŸhµ·Æ-W¥ÚTe.µ§­
Âò6»†cã:WÁBF.æÜìéh@‘}/‘7ÞÄ±"ž}ŠŸâ´Q-Ãí¾;à@N¨%2&ýèº™…•ðúÈ)O!< Ç›
Íšàa'´Iù-õ’4BìÝq{õ`çSFÂl}w\2éáº|¡CŒHáÜõ<zeÔCd£NðŒIvŒj:Ì`ñÿœ½/Åƒ%òÁfbµ,7P›è3" ŒrRbDpQ5P„ÓTkFq!Æp¼ÄRÁñ1‚b’¦ÃÑpøÃY×6V„K©´øI	C ÅÁt[Å²;ÄsQÅ)¼ÜmS±ÝAD°&f€‹@ÓKzI+ÉËe¥ëaT|XVö7~ëš9>}‚ÌæEA¥tñ^ÿ«ÔÎðÆ9;²?óJ5#áb|^	Gt{ÜÂ°"É-Œ9’‚ítö[…$•}¼{ÔÂ$1ëö°€Bîuû¡Ï¿ÅE«;‡¯O>´wÓÓç»ý _·*_Ä´Qž*ÕÅwª høûkß¦Ê€{ýîC¬?ºÌ€:y¿“€
.¬rØõ(¤Í^¼F¸qB+;~k“ƒPBj™Ü4 %¬-"ëéòŸûR„¢UTðíî¯“ÃãÝ;’Þçs
ÅÑt³ÙJc©õ{Ûoq=´Šá_qwkþ‰úô³ëqåh"£µ˜¥ŒVLäê<WOæVxn¥(‹g@Ý§ÉÜ:á®é–/t?HœgÿÛ¨×ãûÿZßÿ×sùo)ùV+òÍX]O[è’Xÿþ¿^iO|øûÌCžXÿ^pçoÏ~¢´agZ¬CƒZA|‘Ï‚e#ê<É„Ob"õ'0dkZô:Ä[àõaÂ]ÿÃëŠ:cè‹®@Ñ’D†L†ž²{±³; ©ãšš‹àäsÑrAí}Dh$IÆ¶Aœ$Q‚À×—Œ‹1Ù<“a-¿6ŒåÖ
øpÕÞ›™ø‹16ùÅíl|Â<;$ì‡ZhGæÙÂïÓB{–×!}$¡ÂÜ.žy.ÎåVÚ¶mY‚UæA8;ìª£ÈŒ¸g0.£4¿ó¹5õ8Ã’:|ÚbÚ‚{êQ‹Lëma»ŒÍ9HºüÁˆä˜$	-q[?¯›Ñþ~·N¦í½ØÕ)»ìêõà¸F†Döåpš ºÐ >=óK»pº%ÿÿ à9ü¿^©Äö¿jí5½žßÿ¬$åüÿ7Àÿ?}`~‘]aû„ŒÚú—œË|ÿmgN¹5ð“`Ð…íRh•Á+ÄøÞMÂ™’%r¹2ðiúü¯tù‚è¢TWø¡=H8×ÿ¿¦Iú?ÏM«æçÿ*R~þ¯úüÏ^]Oýø—€ªŠ÷‹KX€Ä—iXWöñ/°ÀÁ5	ÖaÂB1%Þà‡èCûÆÔ±?‚ãŽbfœ™(‘¶ÇÏ•u€sR—pšB;ÜL‘¹Šn‘íÍUt«UÑŠ‚»ö>5eyêºÛªºæ#àpØnlñ<Uî#ŠåÇaP¢1áûÃ<ò.…>0‡‹¾ò ILU¶<Öå03õ½fÑÏ¼¢Pv?Ôe©»:¸ó<°Ë€Aôùû±QÎÓòÒmùÿ‡( çðÿÓñßt­ªå÷ÿ+ISó¯UºÒsß]Ã²º¨8¯<@œgÿ¯7âøošÎä¿J-—ÿV’òGŸVôèÓëêa¢ß\Éï‚ß-å¾býÆ5¿\ÚcoûséíóÑ/w”òË=p-š’ï.qÍ¸>—Oí§…‰Z·–´ÄcFÚ"'w|`wD4mŽWZB³˜»Ê/·´6¸¥±¦MÙ°ÜªJ&L%nÕ6·6Yw¦qanv³aÃ­„¸‚€¢Ó“†K"Ž¢Ö÷ÜyÎ+pù_(>çŠ_F(êøXàwýZˆŽ_ïÃOi|Â‹}Hšw¨˜q¥¯¥ïô5Ÿ+Þ>ZÏD­ßˆZÏ@-uæHj1N†‰3'•V“–UF¿¹ŒÎÊˆvñà‹ðw§ ©Ÿs‹vÞ"–}ƒ‘ƒd¿ ›:LGŸé@¼ùg_ßD¸¢ùøJTQ¼)HÕ„äÐáð4æI³‚ïP?°±½È“ø*85°Ñ&‡vþÀbÁ[íN`âå,¨hœ"ßŒ/ºÅÕHä
‰…¤[Åÿ[®ÿwCoHöÿ•Zîÿ½Â”ßÿ=zü¿ïíò/Ü‹ƒMÝÑÆF¨ÄûZøg [ª}~¸Àöæ÷‡7Ü†§‰!ù–ò×¬®-e^÷¨Ýé|8<Þù¾eµVàuÀÆãf£Àï—gX7°xôGb¹<“ßzþ¸KR¶èEyâá:‘? (–IŠmå7C¹V•­"döÝ¡E”K¢©ðãŒÂ*Ñ^ÆÈ°­¿CKŸù •(Ù$ûÌ_$­ùáw@öé‡d OgAeE>%º&!ó®Á>;*yÇ–8¾tfb %Ï6Hë'ø’E{°kœÇYøÊ×¸-ŽßûšÆ¿«+n;XzR]}›ÿm¹Ž¨€#~àÚ)Ê¸ð¯CæÙON¶ü%ÃŒÂ»˜Dñr›ÂÃã(…ÔBšS XûOþ6+ÐŒ(ò´³{ü•Ì(ÖNbÇb~q±ÃÏ$sz•ä3°‚@’ÇŒ:‹«ê³Àõ¼\Þ?¥w·‰Ç°$Ã
ô^‰#Ã<=9¨o×½i9þKvíyÇ<f8òÜÅÇ)÷cz`ÊRž¦ô?BH:ì¼+¯QÇýO¥Ò¨Æú­JT­¡Vóûÿ•¤EÉiiÍžÓ÷ö3ÀÓ—GÐ±‡®ÿ˜×óiLŠâ{Ÿ(ÖÂè@é%M/©Õ”îe†ŠØ3z«óŽì¸#ÃvòKô…^¢¸ùq}éEfY×pÜ*Xlü»ì\f©¥J¶4 Á‹õÃwmà´‘9[ß EqÔååŠ/Cc<-oF€Ü"(OT­Ì‹ùå¿süW"µâeÉ]Ö£í/ÒX…´"m¨ªV|öýaXþ¦ÂÀIåõ¸<ãŒgu'<°à%íÁÛf1j8FØË“2Y±P(Œ=lÐ:'|¶Œ7ùû_ýOë©Áø1~ó8N@Î%Ÿ£hcðxtÓÐÈòih1œqÓx|2ÑãøÅÐ‘^a4Ž@©Š­áÃ~'ÜxÛ+xÎÞß}W\FC-ÃFB¹ÁS8Oñ˜ðbñxÜT
)E&ÈÄ¸ÜTGê@Z\ñøÌ+Zkjœv¿ÀÎ£tòØgï·¦í?õL;5}UöŸ-·ÿ\aÊí?Weÿ9{]åöŸ9ëºÀÆæöŸOÇþSÏ„ÑÿÌöŸú·hÿÉ¶jÑ¾Üþs©öŸú·dÿNvnÿ™Û~—iZþS»|K•ÙÕ¥Æ®iéýg¿ÿ\©åòß*R.ÿ­Jþ›±®¾áÏÆÐ*ø\¡ÃBµ„qølO(òNçBßw*ôyúraïé
{“†KáEùR0öbd˜ÀÀƒ$¾c$ó%lab_ls'ÁO´3ý²kÐçÔ–ÿf€ñ<ÝE¼¹TB”ÃÖ$XÿÿpÞÿë#‚`Ä‘÷ï)ÿ)ˆ zp&ÑÆ8cÒÒ’[Zt‹‡ãÛÞfvff»s.O7¥[ùÿ¡)âê˜+ÿIï¿jjƒÉõF.ÿ­"åþîÿ‡«ëi{ rg9þžjö;ñÌOì
øŠ:mŒÒ9åyY=§L‰§}¯f&ª‚ß<Œ7±G¢e ÇÑðqÎFÏˆÎ¼ùd'?þH¬Ñc‘“Ÿ“áå7£g	[í´ÂŽéÌ7Ñ”:‰Rù%CEù§¦` kÊ`èöŒ¡bÊƒgù8%ð‡¾?:R%´Ò„²nï34ÇÄaPzôÌ¸°]¯i˜&¹;ãÛ»„PØ÷0òâQÊg@Ó¾	djãÓ´èm‹aqqÊ×ðãS*Ì?7¢r|ZyÒ<A
i¾Ë¼lá3Óß £	e«û+Š¯á@w0nioï¯û°â\ŸQ\ý…÷©©¨¨>ðÜ¡g©Ñ=ò¿KÃ0ífñœ÷ˆ­E­¤—6«jIÓ*µZ½¤•ª¥Mµö±Èü+^\PÑÐíÄ0A¬(î` QföÇÎ «hÜqäNpäø¸Qá­üXüE÷òœÃ'€å@+Ð¿VS6…ÙüÍâ‡îøø7_Ù€äeq‰$„-Êièh(ø…Q„m>å9ÞtË÷Ÿ$ÎÿR‰í?Õ*‹ÿ©7Ô\þ[EÊå¿oàý§§/&_x½Q¼°\ÎËå¼{®¦§'ç½3ì!ùèƒGHêpm>U0Ÿ³Ÿ7Nh4‰£``€ˆæÐ5!’¯¡íŒ9=#g~È¦–]Ã·Ø!z“€¼§ÚµÍf»Kw#lËØ™àŠ¢Iw¨Ìv.Œ¡m)†h5Ô{åÆ—ìz}Þá^÷$ŠïrÄZÁ+ÃJ(¼i‰zE÷ÏOa±–¢ÜHÆx
ªÀò€ÝÆŠÐûM’ÃwÊÈ‰ˆ¨8Q\ÒÃõR‹òm‹syóŽ9¶¨uoÂïQQJ‰i{†€u5ý15mcØTºýAîOÎ—EÓŽÏŒfuÃ™Œ€fÌfe#,©oL9¼ÓtBÓcÇÏ€1ˆ?.u¸°êÿÖ„wZz~2§æ18Æ™7MP„OsŸ:ƒàLy…ñ“>F…?’÷!Dfùˆ›ÙŸL±âàÆ{»Â^¹£Íb-b,Òù¹­h‰FÂú=w'b‰µÐTý¬Ï}Ø!€O€u3q‚feš±eŠ<ã¸™1:”aG°†ânh³ÑhÔG½±Núel‹…j;@E0œÍzªLªfÅ£ÿžÀ9‚ôÄƒã#Þ¤»¯£Ù$Pó$ç{Ô	+oæu/ŠZ>±ðùŽ’Ú±É'7wOkàAÒû;ËÇ²É(„{Že_Ó/ðA	;B«¶èÁ9)
R%8•Èï÷<‹)€WØÓ•Ð˜ðàjÖw o¹¨YßýIŽV8c# ÌæÇ„mF™¼kÑ?Ðé'ÞÁ}è<aÝ ;¯-t0“dïh4™Ýãè>0÷-:Åcc¬Ãçš¯K¯J¨ùûŸÿjþŽ>H³‘k’ž`Šõ?À'{n€¢…Œýë˜£ÿÑQõ?µZƒ¨ìÿsýÏ*ÒBž¥Y€?Qði+pXXOÖà{?Ü HBãÑIÃçwcûà´.‡Fnê½€æ–'ªZ6Æã²Ë"I–Ùq8[ œŒKðs °m°VnÈ-àXà˜)dn|öcdû¨(pÏÙ/N"­¬	<I«¦ªç…¯ùyþM&ùþ¶ƒEý,Í‹ÿV“Î­¡Ãù_mäï¯&åç~þßòüß†â³Û#¯óó~Åçýâñ]Rz>D]ÚpH8¿@Ü>s»ð&j$Â»ÉÅwF%Úùþƒ.SœÝ ÙìºBHF”€¼>Ýß'ÊWÒ?¨¦dž‘Ÿ~"å`4–ÁÝI@ôŸþ¦–0|–aÃèÙŽé1}Šñxƒ¨nè•êFm£~¯áÜ;Ø>Þ}·{pÒþVF•s¥+I]g#ùÃmÇO°Í8~w°Ç>é³SÌÿa4õË¡ße!*K>Ôº:æñõj#âÿ*º†ñá?9ÿ·Š´°å”fÐ¾á ÀØVdbÎš5ÉÙßÈ£m$Ù3b$Å¡MùU·Jj£DÒœ—VRÓ\Ö©ÌF¬RÁ0¿Væ÷Ô‡1ñúWÐŒ‘C‡XÖ‹d'üØ¼UœN€ñ!ð_ƒ„;CÜCÔiQobò5‹¶©§-„õyÁ‚’¾,‘¶õV »‹Ø Ï…3¦:‰ÅŠ°°@¹=ÚGŒy€;(ž% ™)œøð
*§™øîO,—˜ãéI‡mß÷ÊC»WÝÿ_NU ~^2£‚ìÙIÒXj¨|‡½·¨a@QÁík±DñyÕt`·d¬dd8cx#rŸšÚß³›1q.9<¸±…ßq7ùTØ¡|!@¥-Ìv•=ÁR>Nà·\ºÞy‰[¶Úý€zéLRø]ìßŸ
'WcÚòmØ#hïÐÑk¡ð0ûëƒõm ­4O…+¾;ö\´'ò£ˆÖØ2»°û…šŒ\ï^¶Ì(öííc@`Œ²Â‘¹ã{àê1|îXFwb(pvj¶*ªZ€f:–áY‡“`<	Z@ß0é7]ÇwaxÂ¯»žçzé0¦bÇúÄfÅøÖh2lv/†~iç’ÿƒ™£ÎE×J}¨Ó¯”æðÕšÇªVñý‡z#ÿ»šôì/Œ¾ÏY ¢Eî=y((¹Ñi%`b•=Y * …ÍRâ©Â4çÉ˜JöE„è 165?~žxž‰	úÃ¡8 ûXÅ+~ºçüÀ«Dì±	Ÿ;²¯ï®‰a{‹î’\¹`ö®³vG4~"µ9h” ba ‹¬9ÐC²›æN†{<±G‰CÑÝÍð® l°îÃˆÂ4ÐÀÂØAXr›a]	¹€¡ãë5tP‚‘&% Œ3<ì‘K¼Î“3š$:ñ¼¦ £®øÓÿ …­qaØCV¡T3Ïq|Ø¤ÀÚe¿»}Ú99|·÷[ûdïð duäú¾-ãðI$Æ„··÷w» &”†ø‹$X½°±´.IG)Åîpœ§;2Â$Nè÷¥EÈvÚ'í)dˆ(–Ü°w@ÒÆF¤ÊÛHšø¶((k£Ô´(²ÙÌö…)'ô…¢ÃÛoOÂ~KX…æv>N(Ï
‹465‚ó&±<²-kH/Ê¨_¿û¢¿j,Ëðý«ý¾-74ï339ƒË@÷ß¤èÍM={{AÙ¶5«NAP±Ù 7<Ù¾ò›âÐ¸Z(ÀC…ì¸là›%HÌW°¡ÀÙÑc›{p5±·ø€O¶…ï¦ÿÈ\ä?}£ªÞÌ”äÿÅfWòüñë˜Ãÿ«Z…óÿZØ~ÛÿÕsþ%é÷Ýƒ7{»Ÿ
ÇÔÃ.Lùõî{î±ÞÒJ*ÿOá÷7»»Ç{ÛŸ
ÝíÓã½“_»§G°/îvºï÷ÚÝw¿ò§sz„Þo­¾1ôs{§e¦,ù¢?Kóü¿ë-¾ÿ©êlýWëùú_EZ–üŸ›e4;Cð´ Û	C`vr ß&Lch>»ÏÈ|=E‚BÊ©š	5§;‘nÚÏÔ$	þBýìð
o,&aÈ¡¼—ï'ïw˜§–s‘+Ó\Æƒw@ü–Œ¿Èûh^ïÓÿsõåƒü¾}Üzo'tá¦%G­µþqòÏgÍ—eò{*¶ô'²BšÖY¾Æ"Õ×ø‹ÑÊ|•>è	 a¤ì¡ÈÞ?Ünï½MMv/]U
¥m¦âx²\Ä’`Ï2a%€áld@u~éöâ&§Zd¤?•Y,¢ xøÊ‡Q9@Ù¡e³AÜ;˜Ý¬^Œ!ðÑñÛŸ‰7·ë²¤GØÙ;Ž¦7R,|:¿œ")Áî/,<Äp¬…m&ÔRøcz»…¯¹?—C»0ð¢SñXF‹¶Ûò}–ij1%-ßì¿\]·ÖÙŸ
;àTrÖ—pŠ§NGÔËö~Ã<cJ§P÷SÀ\õ~ñ`v÷÷:'_„Xn+$°øs»U,iµ&-¾„ñ¹],X®C¼î ë¦•Ž3Ïwõè,’–vüuÈ¾å¡(}-A¦!°]	(\NÓP›€ÂÕ5¹ ÙgYJµÚÎŠÖŒmÞÍdÛJbÈØŒÄŸÞÌaOƒÚ™ 	 iè¢í(µÁ¸µ> {à6êÐÀ=ã¹\£ÚEõYø¾ éßŽÃ,ªýmØ’ö÷AVnm“!¬<cHþ`'wTj­ã‹”~€ÅbºC×k“À ²Ñô¢ïG0¼(ËçYYØü¡ ‡=ãùÐ˜ ƒ”(ÑÕ&¦–h‰&0€öy™>«©7C™‡®‹‹Ó»§xs.÷èøn¤xê1ÿn8xð4èQ\ØnkýÂNnÑ‹†
~NÆœ,&QLÒÐ˜óÖúˆYG)ø'.*D¢x/âýÔÓ]RôvþÁ¬CÓÄ‡ä–ø“Ñã6}å'£‘á]…Í²|X§RØ¨GË÷|lEVtþ8ü>á˜xÿyH%åñ¥…ï •‚/Ü™D ©›º³¾(sJÿã(zÁQa.?¦yú_ÈÒÿjz®ÿYE²Þ`%taÎ§Œ£=€òUÝ·ðÝú<=4eÛ1Icajàyöÿšÿ³Z©£ý¥’Çÿ\IÊõ¿«ÿ•×Ú÷©æœ«N«‚QxÏÕÁ¹:xùêà[©O}FÈ3Pp~Q³@>ê±}XŠÿä¤[ÀcŸlyºMšâÿ£·è:æÉU½’’ÿªÜÿs5é;`ùÎNnn¡J4ÒL½ŒwÁºø°¿Ó>"øò$fV¤ÌN”[¹ì™‹(·&r¥·)£ouÒ”|Y4D:@èr¸‡ÿìtvw	=ÑyWxv×ŽPíf¹æ9õšZes«©Õ+õfRss~Þ§d½÷ð4µþKÝÝ×íÓý“îªä?½¡UcùOcþ?u5ÿo%)÷ÿyÿŸÔ*{²’ß lA-÷ zlimÁ²Új$µÂ‚…¯oGôZð{Ê÷Ùÿ§ÎÿøUš……€™§ÿ­7¤ø¿•êë•<þïJRÿ…ÈSdã‘ü€0F>E«ýlF°—»ÿ.,?ìKÖ\/7òK6u–üå5= þË­°ß3ÌLÜ9Ï÷àÆfE‘U;Ë	 #1˜­Ã£ÝƒN7rEmÙ‚CïÓògë\+m–Ô®V­–‹É /ZìÇËXÓòi¨‘ç!^™ÁOlhœâeNIwœ.xÒ£aÝ¡¨Gùª‘,."ÌJCÂHï? A³í.ò¿%ÌXHóô?Z#ŽÿRWÑÿ«¡6rþo%)¿¤O7;­ªI¬‡'«¨	·“"òE¼9cð;Ap•Pú§¹Ç<¢ó¢š[°`’,³Ò7à‡ë
–Ù$QfAznhÑN$ñ%ŽÑtZìö7²p› Á?OOÕd·]' ‰ƒzæ#êÂY?3ÿ|'Ì½ùå)OyÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§<=Áôÿ`8Ls p 