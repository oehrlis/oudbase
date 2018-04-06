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
VERSION="v1.3.6"
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
‹ 'OÇZ ì½éZY–(Zo<Å.™l#·ÀSNg·rš*¦F8³ó¤³è@
A¤¥u„¦lÎwÜ—¸ï£'¹kÚSDHŒ³†6]ik¯½æµöiœ´÷…ÖÖÖž?}ªèßgüïÚÆþW~Ôúã§Ï×áÏž«µuøåéïÔÓ/½0ü™åÓ0ƒ¥äi´°4|/û0ÿþƒüœÂù§³Á	lo:Ë[ùù˜cñùo<{òœÎÿÙ:ü¶þô1œÿ“Ç×§Ö¾ÀZJ?ÿÃÏÿÁïÛˆ§a~<PÍûûÑŽ³ø"Ä¹ê|ßP¯fyœDy®¶£‹h”NÆQ2Uÿ¢z³É$Í¦jõÕv¯}zateQœO³0Ï#µñÇ†úÃúÓõý(œNO³ÙÙYCõ.ãé_£l&ƒ{_ô~8ŽZü³©¼›_vfÓó4“/{Óh&ê :ÏF±ZM£¼®rú¬•Ògÿ> ´úézwñ´º7|¹Ní¼këh­=n­ÿ¾9Š.â<Nú†Öx8Ë&iqÛWptª×ÏâÉTMSuÁ?ç‘ŠXxÒ¯_…¹Ê¢é,Qýtá>Ói”ëùŽÏá”r~‡q2ºR³<¨aš©(¹ˆ³4¡#ÐŸ§³©:þa»	SÃW´Ä!Ì†ƒO§“|³Ý>ƒ–³SÜ{›á‘#¥LÃéwã~”è-|¸Û|ÜZû×û;Li/ÄÃ8àðgE
V@`h*Ø2œÆmˆ¾¥g´Ûqš!øà×q8Å–ð¿þy˜œEù½.°©¶€ø¤ãø¯<Í]GŠ>Ð:x»}rtpp|²½ÿrå£ó×f³Ø2=ÃûÔJ³³Ú5MÞM*~æjPy6šªÂÑ,Êï¸‘à‡îQoç`ÿeíb½õ¸õ¬lt»ûÛ/kÇGo»5µìç jx:Šø$cø%œL" 0ò«ƒ^÷eíug·w›.¢ì. Ü™ÞÖÑÎáñÉ~g¯ûreñ8Z¡VÖêÁñÞáÉöÎQwëøàè§—µöt<©Ñ‡¯wvaÚ•^ƒë¶ß½µ²RzÇ£ã“7ÝÎv÷èeþB"ÂÉÂ)­|tf¿V«?D!ñÊGÚuyåQ-Øëììv¶·º½ÞK¸qÿžf!\»Vÿ<è½\ÞôŽaç€´ˆïÚƒè¢ÌF#õéSÔ?OÕ
¶ÁÙê‘7Ò6p‘çóž‡z=Kúˆ{wÅêþ.æPÖ£ÞæáY´ZW‹w;Î'£ðŠÜãÌhƒª„òôÑvº—Ÿ©ÚÎþëµÉ“6Šñsóü"SÍX}‹gðg«ûjn«o¿¶÷á÷_ù÷C —i6x7ä;õKÕ$J5Ï«.MìyðrøcNï‹ªÞ—jN÷¬ª{ÿ<ê¿'
E“QÜ'Š5g gÛöGcëbë¦ê'/·ã,êØØM6g¸JÈ½‚OÔD>"z3§wéTð>Q;Â£«úí¦gDÂ6á¨w¾GBrÍíâ¡ú>\¿VÍ³©ZS¿¼@†Ÿz›[£(L:Éà?fÀÔ¨ÝÊÇkú:óÕí
T±ºÿš¢Ï‡qpÜ+÷«¼Q{ŒTLÊ¦ñ˜¤—ñäKÜn‚öj=øHûÛÙ?|ñãú7›®«~@¤ßG
Øì
.Ar¦N#øgÀ0íIPÓP× @T Hr°
U³GBl ÏÏœEþP5 ÁÇ;{ÝÀŸ½C ÛUí_¿ù©ùÍ¸ùÍàä›7›ßìm~Ó«Õ_¼pºÍïš,éLzßaÞƒ?×ˆg8]k5·Á#þÞkÐªøÑ¢<ì[Ì¯ÏCÌ½®©—Jdƒâ%ÐMµ±¨-Í<µY ^žšú4Ñ±:÷ÐôôîÓâaL3¸Jú×ü<NÍ_—çxßiÕ8íïa½´ÖAêMqÛÙe>\º»Ê.Îkêì´¼ÛAšDeštÇöÝwU{ú;ƒ~õ"o¼û¦Ë†<ºL e U$ÙÔ@Í&@‡¨0Eâé=ËBË]…¬$PR¼ŽdØ4_«‹T8kI°vÉÔºÓ()4ïÂÕH-4tKý:ñ™
Çé,!!=ÌÎf¨#ç-ÕƒK5#V†d½Ÿf(g€"µÜ)6n:…X­"+¯ßtü§KÇw¥ µ@OÒ)hŽlŒ”ÉãÎ«kSÁG­Ý®‘fN^uzÀ —ÎJÝhž<šÒÀÞ‡áEPZôö³¾¾lä­t6ÐÓtÖ?g-÷åýÃŒÒp Þ­||s èÑnéEºÃ=^ºß^
\¾Ëjú6ÜþO–öïf@—3 éÁï¾t7ÜN7›%	Ê-bê§ãq˜øÃmÜa¸AîˆäÎ¨8 ùÉ²‘gÉû$½LÔÀˆåÓ«	Ÿ_îtB `5€7à-üñ²á÷â<'¡­,¸»—æ&è[¸4¸.…7Ô-I"¦¸o d£H Ë$i R¹…æÖyøüô†GwùÈ9&¤…­xSÀêÔîÑ¢ee	hº·á¯6´Ï+jÞú—ž¯ìív%y*·ZÃÉwØ?þ±^Ð©þ4Ë§ê2L’På mœ‡£Qê˜[J0ß
ŠÒŠæH¨Ml¬­?×%¶å¯é(§ D¨0µ2]­8•½!{iò Š†Jg}¿í¨ƒY„Öa¸CiöáƒW³3wt4Y¡y¶É=µð¤«¦qÛ:˜QÝAØ1²‚_ ¦Çƒ×ŸoöaëÑNOãpôy6T‰QÝð ¸‹Lúá@á‚¢Zš]ZøÓÍXøó?Æ€!6+òŒ&´ªZ•…bO!ßX7ù0êjÖ›åïž¿\õé|ó{Õ¾vèÍº¾³á\»¤ŽO h)g”¶¸¡A+?/ÕÞ?Æ¡DCG R0ZKáWMSC©oñ‚±ëˆsµ€9½£=,dòßàNþ7Jê_þçRÕ«Š·í‚Ñ90'áÃcÝÐÑêû$“0Ì clÿl4å¡öÂøÎ~Û§Y8Q5oCOÖjh}¡N mÇ ”ˆ	‹Áî}ˆì“‘êÏ@MÈ%aüP5K­x¿Î¢i:4õûO²¯òi‘#FÙI˜LÑBÇššôVçñæöæ¯›ÝÍåd£°±
 Ÿ¸*Ày]L˜kÑ¿¨4	ç»¸®ö®\Fô<8Ð|ï±àmlÇÇ9-~Õ-\#âœ¶Y]uww¶:Çä)®ª[÷±±z”Ó›ÝP+\FEÚ£¡þþF”hZ…+-‹r¼+N,¦
þBÔwÊú!6¾û—õ ±Óbåß`Žs’‘T„ÌäŠ,+SÐó£i_¥3z0{ªJ[Ç6´MQªî’b9÷‚rL£ÏaøÈ]Í|z#`0®¦“ãŸ¡)lÕ®êÿò—´0œÆÃ«²ä]‰¹“Ãr.#8”\I·säR °ù×Íf­Òò~ítðîˆîê~ƒ¬|<üq[ÀvmYïï…ù–û\—°O—QBX-òÙòAÍ-hM/ˆÒÅkEý¥u³É¾öæ0‹#Àè+ø$I›@úÆ“)ý~˜¥“(›ÆQŽ+‡vvcÛû°þØÝ£ªÜ84œf ûvàZ}ç£5Ü1\˜wÏäŒ+.î‘÷àh^º2˜×½.Z˜‘IÃÁ¯(¤ÛÛ¡?†àÿ†á€ž]*(HÍX=ÌÛYi7ÛÝ«"½Mo¾
ûï¡ÚÙfÿÂx6šÆtc`Š7Tû€„dÐÎ¦Ñ‡)*0+íû/òö»¤­Ú/®Ì\Îié‘–›ÎÀ•?¥Ù*ñy¦G#¬?ê¨Ì½(» ý±¶W<ÃÕ3åae}õ°ÔLÜÐÑÀ[G]Ó¿ÂYƒ:à­£ÚÂé“âµ¢”X@Š¾¦6}«.Ÿ‹º¢í‘Õdî…Š.ªº»ÛCúOÏ3âúc:V1ìÊÇØQ¿:?þùä D«áå{õðU÷ûýG½—µwIóè²¯é×Ú‹ï÷€^Ã{¹þ‚uÄ—OÑ·®þ·jÿ¥3dpNmd+øÑ»oâLß}×Vaƒ«+ùã.o	>¯Ë8k/Ô5ú†>’6EŸù˜¡êf½ÞuÖVÜV8Á§ë•vë›cù(×	rEs;Kf@Åùf¡çeí¨èìýzŠ£StLæFÂ”pé2Ÿ€›ç˜òyV .¾ÑðvŒ”ªªÿRFJFØ•ÃÐm:Û{;û.oœËfÃÁ8NnÀg«™ëÜ³œËc½­-:úJvû'ÿd£Ìœ,íîË5*LòÉ¹Vx—6k/é¯UÛI»Ö÷ä¹úýÿ†{²fÁ^}OžnT^”»]ŽJù(¿Q‰òðO4Z,T÷ö	û·”¬ßí¾¬a åf»¦¡Þñõ&!+êNù¸])²åÄÑU4“Â˜2º°Ól–8’ßeÖ™g\‚¼7”^„ÂÊ‰Ó9¡óŠÿŠÆÆédFy¯(¼µ,RÞ}ýsy,k±ÇQ¥ =yR†()D~0‹±Ç|®¥ù·ŽÛ¾¯ÿÏA¤‹øÿÇkÏŸ?+Çÿ?þÿÿ[ü|‘øÿ¸Øÿª¸s#þ1âþ%
<*­½²® •ùÿ'
ùW÷Á¯¾†ðcÿŠ¿¯ÕîtïÄÜß_È½ú»Œ¹ÿì+BûW>#æ¾ÜÝûN5Çê[à£›ÇØ³ÃfõNö7¯/¯y(£èÆc—Ïé]Úžé½Æ#%æ‘¹Ý·Õ·¯vö·Ð|
¤­Û0²î2?[0¾W‡ë×çÇëþ¸J©žäÐ÷Y2Ó»íY˜7þP}ÛýOTË;Çoh
»42²šÈ™ ÷f -ˆ†À¼ Êyþ^2 ´æuÍÄãžîâßM€úšð5@}Í øšð›ð	óŽóŸ›p@›ƒó<~B4rÄ›°¾
IC:A‰¥ð±ŒMâ¹Í'ê¨"'²~ÌA¥Q%j‚¶<rÜ§-¥'YJ’š	¹¬U—€?¾0Ðã‰IÂá¢0À|r$£üØ9ÚÇQô*QåÇ56Ô)(ö:´:·“´Ô~ŠwåT>‰ú¬X—ˆØ×„‹¯©KSNÃþûÙ$¯È}x¼t=4€– +’'î)êyrÂ–Î?È"‚¬?§ã'O—µíõÕAì—Y<ŠAìË³86ž™×$ÊÐ†…ÛÝ.aÎXr~Óàz¡Ër”˜¢Îk*åøÍe<1ËqˆPkÔbZ-q|7 ÎÚý}ž^ª1^5Šïq×z
3›ÐŒV°•ÕË¾jŽÔ·nøqÝkvŒŒjeuuEú4éÆë¶%Ž®š)=®ÝpäO¸ëª™ÃV˜Ë¬Q³kq˜‰KÖ¿Là¾úŸ¹¯AKrÆo·¯0Ž¶»ÿàÕ© e8M²Dš¸Üúüžé$†_ýÏâW÷Å¯î1Œ^¤>ÎU &iœL£Lµ‰>%³ñ)üA!&#±,±‘å<R#àh@½Ï£p m°y`¨#‰Lâò|Þ)|êƒ8ÙlÂ=ZÅ’¨ÔzþW§eÝðÿx3ÞìRÀpó·ˆÿïÍ	ÙCCÇì¿²ªõRÝöšóö»FûjŸÕ¿XîÀÛr®éa8=ŸÓê>2ð@{RmL,›Æ”°Ê^KD_­P·w‰&Nør¢‚\Ç9Ì––®^ÎädYàø\
[5NTCÈx*ÐÜ‘cƒ7n[“ä0O+mÄ…Žã½ÃÓºÇ[By´J¹†eÛÐÁCó>
ñ9g¢:‹aA—;î¼zYž§¢!Aãdw‡üaLY.ÔÃ¿<x¨L®9 "@LêeÆê«µO0!Ø½«Øúœq^ƒÌŠ².¢ï;f°ÛãÎuû&³Ú^³D’]ìFìýÓñÇóÒdi¬’Ué†°÷¾C_¼7ˆÚš¡•˜hÆÇ·½k¿[…ÿÖßá*ZVÚïÖÛëNP¥cW2/gx™ê‚ÎÁÖqç³<Z„ÕÒƒùMyý–†®Ù,3õ°ñPÁÿÕ5–ô×$º$¦'…ªÝžÓÇ×4ð»DF.ÄòûŸ‘N 6w®43ãÝ4¨ƒêýˆì‘&ØßZpz$™#”áW¾`¶b†Ó	U…|*eˆŠS ¥²óÈªhG›êg3ä/FÎÓYÖ¼‘!UÐMQmO\8‘G3öê]â ÁÕUúå_×§Ÿ&Ó8™l”[Bäß¦´”î÷7É}ª¾ûîFmô±=ÖÑ‘)|/ï‘uãòSYi'ž.›OQe…ã?C9†ê34a›W‘© ÁF@“E#Þ9wJÖsKÖê@ý¤\Éªüèa£^­wHº
ƒk>M¥Ž«m]÷mÔô/‘üÇ·‡sñ¥b)~ÄºYÎl‚Hà°W}¸r/&!Šß©'¯¡=pè°!W¸*8ÍÀþÇtæv@:m¿…=s÷N!%.Ú¶|Ëµ«xº£Uš¯ÇïaÕœ¨Rû"QB­¶Ì[èäX¸õZ.o¼ô§F7xÇhÐð;9:ž„Pƒáé[ç“pP ´.\˜n‰F|âRRÒŽõÀß¡sÙÛ=Çùè‰Êà)'¿q1ó]ÍÙ«ÛÊ“fäC¸@*fÈ¨V‘«7uëO’<†ü>;JÓ©«66¥â<üùçÍÓQ˜¼ßüå—‡õ’ $ƒY¾ìO{íŽY÷zÆI4D¯28 Ðw@±ö>Q7qƒµ³‡íwµÆ»Z»4Dûá™mÑ†¿ê¾Ÿs>ìsŠ s¡%²œm»´ë›[DÃ"^¸tù¶öö:hëÑÎþu›‡jŽp¯šM&Ù7Ê˜¹QjÕv1çÂ4¶Ã…È@ÅkÃKu¯Ç‰ëd;¼’ …‡ÿúÍìa½…#Ý  $x *œaP3RµwI¹¥ú®â^:?¥ül!ü©LpY¼	ÌÇq0£)ÊÃè,¿i¿m¢ÎùJþ-$¡Ò,šêDT§&9“WÈ^Ý›^q±+’šT6¹¤xx¾7—3×qèw'
eèAÉ}PåV^Üå‡Fž]«O‰i®„œ¾îOÕa:þ ‘ê»FŸ[ý©Ò-àþÂHòøSE2(7Ç‚|ÖG“á¤‰+XSççÑ`nJuÌÉ­%»Az™4@$×÷¼N§Ægfå0³˜Ê´œ)È¹´:Åú›5Ùóï1‹Içÿ°ó7ÉÿÙx¼ö¼˜ÿ³ñäù×üŸßâçkþ,¸”ÿcnÄ?FþØ!¾æÿ|Íÿ¹ËX_ó¾xþš#aýoww—/Ÿ· åßíc´uþ¹Û=|ùäFÈ(ûìù…]üEïs$ï£hÀ- ¼û²Ölêß­ŒíW¶­z=
Ï¾¦&ÝÏ4¿QjÒT}‹høO”¤d²jTgww^¾ŽÙ¶ùq®”Â+‰v×ý­£î^wÿ¸³kGÅ/çû^}ûc·ûçž×ÞµK÷®©t40Qfè'óÆýÌ«¡úöUgëÏoo”T\–ÎNâ!¾f'ý]¿Or·|¤¯9H_sþ¾²`¾æ ñÏ×$¢‚_s¾æ }ÍAúšƒô5ékÒ×¤¯9H_s¾æ }ÍAúšƒô÷™ƒ4Ý|¿oŽ7‡›Ý/‘ƒ4­+vTæè¼¯+r	Tû[ä/QÆÛS£Œ£PHÃ?åLâ0yÞºŠÎZð_´¿êç0ð»ëÂË5´õ¯™:_3u¾fêüófê8Ù7ÉÔ‘xoéE¹%Zâ"ÝH7QAxK 3PT	GèSuþt¸¿×¨¦!âOŒ8æè›RõT»“óÏ`¿ûã	úökø[áv·í«+mÃë¦PA`‚ø©8wz]@>žô&…NÊë¥¾AãuÄˆ>À>œbQg»„ŠÎþ!m—öŒÇDõæòøzù`l{–IH‹Œì®Fö·ô·ÏÙ*]wLŽ¿AÊÖ¼t¦»¥l	$þ)’¶JÔõk2Ò¼d$ë:¦d$+šd$ÛB?ÞåbÊíR‘Ü±n’Šä´¿y*’ÓÉ1t—R‘–®¥:©jô¥©H‚Ä:RÊ´­Ì>rf¸}öQYî´wïP«àk%ÑÀ¡ÀV·˜ÿv‰®ßéDÊÃØ5/KÍqH½,ø×%F4ïù!wÐÂ¡,LÌ‘õV%åÈ0äÕñV’-£¥‡k¼7 ÅMV½òÑ_‹ëÍq3_Š­Ê	i~K©ÇÒÌ?ëÅA<	ØA´•&Ãø¬‚4,=–~¡§Ý&h¢ö  1Tóð¯ý‹áM Üvó‘x†Öôì¯L!·ö_Ï¦3eeQ”nûùÍ«A¦_dÕx9ï]¦*˜»Þ?Ðð•p™c„©&ñíaýoÁÅ‰V U8—}~®ÕÒ<+çÄ$ËJÆ-dYÝ<Ãj¾ôª’ÚÝ*‘êó“¨n@õ[$OÝ,qJàwçÄ©›'MÍó¢W ¡òPçåEÎ²3›¦óÞ¡)K‚}sZŒP@†Ã%ë…4Vœd5*¨Uw8Ü#yÏ~äJ7šK+Ìž¶W>ól¬šY5¹*Œèu½e.Û~êna˜Î eWÑHY^wyÑ…DL´{l¾±í6‰l²ºûOd[ûÙ¾þÜéÇ{–ûÍ±0ÿo}míÙ³Bþßã'_ßÿúm~¾æÿÉ‚‹ù|#þ®sÿØ¦Gµ0¢_Ûs
6¾¯Y€_Y€:wÏBö‡0‹1æêö)S/ój‡Æ8wÁXÅ#¼Ð5tE)]M
FŠ>L£,	A\l¾¨I'}|½¼X·ÑtVù¹ñâ¨Àð«ì€C0yý[€\¨xºÉ‰Òó4"ï•3%€½…4èd’¥$ÂÃÊÒ4ø*‚^E-T®[å$CÐ›tÕã~3Ÿ P¬_ÕR—çpãÐ¨™f ÊŠéóVs!E8ÍÓÑl±ÍÀ.È$Ø¸"¶5´ƒ¢þ‡ËUhD“ÔÐ6Ò{sÒ;x{´Õýyí—ëZ½¦^¨Éå Ôèz.—ö4âóÃŽÍí£¢Ìu·ŽºctÙ;«¤h¬AmÓ¢0ëƒ¶—À×Ðÿà¨O;ÇÇÝ£ý—ÿòsØük§ù¿Öš<iþòhsõgøþ­|r}°úvû>1ûigûÓv¯Û­¯<´óqøFÀ‘²ÝÝ×Oû­üÍÍµ	|¢Ö7})uŸ_>Sü9½ç~ç…Ÿ=¶ŸõÌ‡OøÃAKø”?t^7_=Ût¢ ÉÒ€R9´n¨ƒüîN1	ííÝžz»u¦T¼œ¦„Ôu-ÄŒ<Øî¾î¼ÝÅG–9BŠóUkBCkÞ÷T‘ÇmE¸R+ŒA†Óˆ¥}¿•çü–vNŒ‚Ó´·w²} *®7ï Eæá7Mz«³ë¶¥}ô†Îió
†”÷à´ÂnMûs[¡¯ç<›Ûê¸»w¸§'m§ÑxBH¶ÇáÑÁöÛ­cw@¤³þÔ•ã0OšÇ—ë­’¨µRÃ×{?.hÌvÃ£.w¾§“÷h ]pN2$…Òò'		TqnløRûõÍ7 ö.8¼ëÂ×s¿¨8Ðëë€Ü¥óí¢ß59.¬ÓþµÙt&²ÃàNÀŠÝžô©yc,XìâMÖ¼Y¨›LC¿ßv©f¬…6Äi<ríeƒ§ÃtxŠÌ®[:{\0—¾+2KŒdFY‡ñÊçÑA!	çº–×Û¤,XëZK›ÓkÜÆ…t€h±–Pá4tŒÑ</m`O	¼?nç}^ÈÕœá,™”AíÆ'ÉD>(äµ€a}é‘–Ž[$É…=ZüÒ70.¼LÉýá}úÍÃûŸ-¾‚úNCßósŒ~¯:K-íÇ¿]¢ö–U ¿î~}Šk'ÔŸ|î¤-w&þSç‡ŽžÒü~ËÉ~/B‡R"(tG?xâ%NèU¾+FZÐzªÇÁ­hûÜgk+Á=Övø™“¡…ºG'„¼‹Š÷™ÐkJ¾Ê'i2@éƒ z)çJ°÷©4šË…³›e› d/(ï>æŠ#¿ô\lÆ.¡Ä1Vÿð¹iäÓdúrå±òpH7eA"êœ(¥›óèxèg|8L4°Ê0Æ$†ªMÜÁ >Lz§ïkf:ü¢ÀYØ>Õf­üÃ%"+]Þp \íò]¾ñDn>äíVù[¬pÞê|’öÅ xƒiîºÂ/¿º™®½E—Fb·$©‹ãcu´åðæ¢®ê,¶LEZêp¡hTØx:º"fpÂSž–ï#Ê¢éTýõ²§hñýìíÍËÖ˜ë³þe°ÿ0Ýq—ÌñÏ	|44,þÉÆ XÕ—§ÿH ×' Z*A »»þR‚sÌ¿YB©NqbrsÄm…tWØNÅT©m\Æ—“Y,.Þ˜‰iÑ­Fú½Æ|8½ÆÎL!² kK•ÃÙ£A¬™¨‡m²“m˜Œ\ð#M:¤v£ý—•öä¡Zaš’öƒ¼Ùž517&J¨º¤bÞIs¸Q÷f-Í'à\o(¶ë¾f:éõv‹³õ¾àtGÝC“f:gÖ¨.Uâe’âHÎŠ^JOŒà/Ö­„vðœ_8qíää¦ó3Ìc¹çýÑþºíøqâËöÒÚ¬?þÃ«Û0Œ?ê_±í³ÇÏæ´% }Ô¿BÛ?üÑŒ[Aéz{Š-æwÍèÈL¸P¿bÝ¤=n„¾ãgà	³S¨Õ*A^{¾¶¶^ùA¿Þ¨þ[«UÃ’œ47†eµ¤u+XÒ„_–/3çƒ‹ñÖ§àÂÒ¼ª4úvIt‰ž‚ ’›·ú8—*'¶`ùr§( •™Æç	+…ÀßšïTŠÊÎ“R¹‡uñQ±GêQ´tû_£|¼Éï_T¶ë9¥žO©­uKúmé°J­‹þJÝN¯Øö> L¼¾„ü;›`‚â	gó–e`þšL@þgr5mÈ%å,ò]«$ÜB$µW‘5ìr¯,#¾yývWå©EÓ‡¹>6nSw2-&[i¾ßU+~ €;í'%ÂÁe¿¸‹:ÍX¯”`è Pdþðg‰`*A·2R†:K“–éKÒS¬je]úÝ»ÂG›tý6ÍõÞt.ï¦¹š›+þqÕ\Í—»0ð‰ü~&p " ¦é< TéÄwÞêwßUm¶*LÅx	mqŽ¹¥…ƒ Ob²jf«3j#·"ôF+TO¦W-µ¥ÓõqX¬–Ö*RP=ŽWÁd’ª½Ü÷|að1¢Žáã’ÁZ¢è$>iyÂM=B¯e‹{&ô©µuM¶OtÅû·Z‰â+ÁR³…ÔÞÚ ŠIÀÎöÒ÷ºöÓÄß[¬`¾=ñö³‹"sûýWš’«æÇ ü÷6•%[‡4ùÄÛ¢•‡O³°?ŠnŠ#2‰Ï}Ùnd&!ÜZUh¦zà]&crb,w›ŸwjÎH%[•ÅìfÒ¯«;½ÁM­®ØÓ©—zÓ—‡8`¨Ð Ê™×:÷LÛcz$}xf§ùmm‰s©°3x¡CÏï¡; 1¯îTTÜND÷«»u·°XwÐ‰¿<îbõI¶Ò$OG‘Rîª0þ|³Ý–—™Wbäy>.-òÍññ¡òï
;ôª;vå¹>÷VÞoYeÏ&eæí’aðéPËh¶zÎ=³o=/@A–Â‘ì1?¦	R„ZØÞÊT³üYéÏªmka˜éy–ÎÎÎ=Pµ$>o§ŒTu)JëÚ”$dÄµjÃµÑ¹>úJ×µ§ui‹ìÊÇøZ}ÂèkÕ\w*à=)¨ïgÜjsôýŒý¸îòxOï¾§žÍŸávRåã-phµ:›´1Ë²ÂÎZYk[Üž4ºwc¡G=^ ŠVPòÇ%õ0cd:T¿i>ÍÕ7Íõüï3úõ	þ7Çb]UÒs|m8öµzç-§¶²úk''§Wª-äöÚ!»×—¼®“¾ímAˆ²­óO”â‹Vç8çû{E!2˜ÒÖ5'µTw¿äU‹H(Í-2qi;)šIK÷€ÛìŽÇjðCÀí‡,×GñÓR¦Ýkè•l×Vy…ž C™Laÿ¼ªˆá	
quÁiJØYÓÕ„iAØu#ÍÎZ)>'–·ò(»ˆ²…Ô›¥ôøÃGÅ=Öý,gžáálòð] ùo9|2ŒýwHHºª/^X’7óQ8ÜóÔD'–L}9Êï×êö
óñjiãýón«NÝ0TÂQþL4VÜ¹á<Z,ø³rNµOÓºOþUÂÕßISÒk\÷Y×â w­ÕœŒôdwŸßÞx<ßÄYsn’ð<åòzAñ;FF,ÄÐy‘N§J>ûÀ<GU@…›Ú)‹ŠvAÉv­‡_ˆI&'æ„Š»žDlM#Îb¼ç+½%gÓs¾¨ëk×\1>¨•Ï2J|Åw£2¢>º°`~ŽwJJ¤<ÁLX ,|»‰§áòÃOJ¨.‹xâY¯¸,K$èk®?=ÍfQAÅ@¯õ,“R¯¿|(pÔ=rIÌ¤tWÝñŒbr_Õ:Íÿ6ÿºÖüc>ÄE,tg7ôI±`¨õÊð(pãHHWý÷,æf~i#„ÕƒßÔ‰œI ik+9!ñ£ŸaA¿<ò?‚?¢TU¥~YðRSîÓˆS 6ï‹WDÆ/¨ŸG£
Ü3ŸSçVýú7üU(ý{§]…¼ œ«îþwOv/¯ÔÖÛÞñÁfâP¹0úy	Øã^¶x°íè^ÑQ¨vÑ;êÏï¯¥VtÁÏ+ºx:šÓÅûüû™”¦ÂÍç}ôsÅméÏ+º¸¹¢nçóª^’YœH>"õ_œHÞ$]§º¯—j‰åÚ‹‹œog/'ðÙnþçK¦,ô=Yvà%~Uß9[E]~^–í­nsVéËÍKq¯ÓQ÷°jŽ¢9ÜíÒëíVv)Øª+	šÎÁîŒâ0¿IóW$å´uMë»>îqµ ±ÇJ‹v8Dü’š ß­8÷¢-Éöîø$z]Ìn¿Ÿ+l©UWL«†IýW¿§GÄ¬O©­˜Éì‘6ƒLTiö»Ý¨;|3sG 'r=35E °2cŒ#9êXÍJ£1G–-b8/³dg˜óò0¹ñDùÃXƒzÑäq!o‹W-ï˜T&¹„yaY!ËKoKPQJþæ²óCøä‘ùÏGtüaù•¼&¿ôRcwÇéq ªÒ+1“!Îî#t£¢IA¤ö$
=çøÓÙÝé˜—N¨½¾ K’òÕÖ£úËÕ‡5ø¿Oµzë=Á êÞ(¶ÄÉ¼qVà8+ŸVy¤:U_i¿Ûh?œ3ÒGùm³If¿ø XYO¾­Eìªµ‚ÙV>Ò‹Uü©™)ª_„/õÔÔïqà¨YLÂ,Ú^”G:öEz*ðóíR”+ Ú—V=µ1¹$wÿ	¾Pa–Áv¢‘h'÷+e5V;¯ñžõÚ~Kõ…ÖHÕ^|©=g@²Ð$4×ªÂi|aë¼Îö
ømão`IC2g¬²Ú´tf°bçãI,ÐñÈ^¯%aÉb±ñº ÕÀ2ácÎ‹ áh$ëÃ/O…/·šÂro¶žB§ûYÑÜÍ49:úrÅß0“ô’ÚE93/aÎçŽÅáçª}=X±ÃË«öþË/Ÿ¤jNûç5ŽÂ$g[KXZLAœ}ÑÂ<ã žº>·FB3ÂÂ‚j5‹³¾×Ù’X
N.gõN©ÕÄ[a6”‡heø¬#²lÐÌô¬m.ÛìV˜5ÿªV¦ÕÆo/ ±hy´Ú2X‰dKeV;±³):v­¼€œ} $‰2xÞY
P^…ƒ1ð›ž[øé…È*Ú6ÚA®u£3 xÃU¡c ÷SJp0<BŽ¥!}°¶ýLÂ@“4i:M¨Åë4»³œÚbÜ3Á³Ã5äÓ“h<@±:ŸË…‘#Jœ#¢¸4þÌ™·º$ÜÆn`ËF¢ª{Y¨òt¤g‘ÂQyžÎ ›ëUq&5îóÌ{|"s:½*¾ìLŽÂ*ÿb¡ç×oÐÂ|°O/,Ë“À”¢QFkhK!#Ó“JèáË¦«òë¿êÇþþžæä““Ââ…‡Ñæô§w;Õ|¸Ó[“Ùy'úÝœ‡¢y}†_µÖ" æRtÒ,Õ|YÉ#=þèã,«ïV¤Ôî,JiË›®Ìk[Xÿ3R‡ã7X+mgùÔA¯iÄeœ£`„ÃÇSýŽ `Úò£B>ƒS]©óCwÃRÞ`> üsí<þÅãx­Ê•ÑÈÄ´À)>ÿONãŸy$£‹§ñ´¨âÕÃ2§x¢i¡VÖ@½â¨õóËuT÷É¢’[wK½ÔèCµ¡Šï#âdÆÌ‡³ë'lD£Ž1ÝøfõÌtU¿kw=ÅmK¢™c¹Á²	 ó—]U†ë–Ë^2„]¶yDOR(Æò¸¸[i«”fË˜]ûÕîÝü(Ç@}í˜hmT›óªO|mßç‹•NytGXŽ«~CPç
ô.³|'Û,ôÅÖ‰†×;-«ºX3þn§f*¼§‰K-ÓëþDÝsüb‘79«¶7™è«iÀ¥+¼Žò”_ÏÓáï%DÐ­¨‡ñ ôy{KÏ‡ªØPùÕüâòÂ5U‘äguÅWÃô@ÅÊ‚óŸ8]úP©¹¹U-yÑÒR.‹qJ‚xª,‘4"Sƒ5žr}¯+ãV&ØqƒFì/ÉŒ«W¼‘0ïQzƒ³ð~«è"î“™ù§Âî+Þi]œ­ç<Úê?¤iA{Ÿ)W®Mò&ÙVóÞm½Åã«Î;i²#sk”ª$yüàkEêM¥u­²ÿMûKLÝnærïŠž}[ò^­Ä|ÉÅÐxÊQNh"êÈžV‹wa%ž“Ê)H:ŠBŽÏrOJÑºÍc¸®ñƒµ• Û“§T¥x$#?bó7mçQyào¾i<¢m^W~)+Zp2¦ |9ÓOhPiß&ÇëŸª»ù¯ÎK¿u5GW–›Gy©ê€ær_Œ :««Iô·ÿìrH@Çsÿh@lËVð°ï8”Ïºæ]$
Æ£…$¾_pÞ\`ã·:m/÷|Ú°ÑÂx·¾ðp÷xÖ"£ždp‡¨Ái°ºÊït;ÜÑ­,R©‹ZõñfÓ¼Ûíå
(\ßilíºrÐ°à¡Åí ÀïÚ,œwÔJ¦€^M¯„BUñäÝŠC•ëó”?ö€†M¼Í°v89C¼4¦Ì¹+ Ðá&(|æê4Š[û¡¶ÞŠõªýW¬fÁþ¼¡`,6°ÝyDåvc³J ÷B¡¯Ý×¾>Û¤È–É=$Hw³G:CñcßòR·ÖVQñ¢XcaÞÑíj`ðÍàb6Â (ýs¾uÀ±ÂÖIïøè¹PÞ‚tVTÝŒlÏKÖGw¾k'}J:IBÙ’Æ¶±d‰-éðØé “á–tyâtáJeK:<5õüô²%Ý$oÌ	6Þ!ó>s!¬>º€ËŽÅù%±ÕÄ‰›û÷y9h.y	h‰c°iÞëëw­¯x—º¡Z ¹<ûçê4Nô»' ±$ó,ø<O˜ÑK‰x-M«|V”>E¾!*ªSøˆÈò*¨T»ýÖËZ8ã¡[<ó½ÌêÍ8Œ•xrïV'úàÍR×«ñ—žñšZ=bÑyß¨D¯çêø,ÌÑŽ®
Vl²ª¾ÔÐâ$úþ˜Ü'Ž­Ú €_Q§Ï(qVˆ˜ó«@Ä³%z.feU‡XÛ¼xO*‘©VwÇBYüéré3YéS ®îgþþ‚ùw£ú|ìÐµ–z[YÊø{^T=›Q>üÏEêïZÊzp°;®ZNøSy.¿Ý¡ŠWcÑ¯R´ã¹u‹8=wÓIÏÝôÒs7m0.þ^ädø ·H-e°v–URÎ¥ÂWþ@ ¢µ×4>Þ‹øv6-ºü\_ékbVcûñÍ<m>æ7™Ô#ÓËÆ@¦HfáHÞ¤·/º½îì¢û×ÊóE-é%gWÎwšî§¾.r9Ž[4ÜŠÊÙš;5¬ðGÊá¨k¿"û:¼Tvªt"Ï}*Û³!®y)ANKôOM».y¥ÉqÖ4æµ!¼œÎ†C/"À¾r¬aÁÚ=®W Yv4Ã
ÏõyN™2eä»QæÛÆ¿6¯ƒüÃ*nØ¿Í«®Ý¹?>«ö9óããmóúÛD¸[‚·ì\jpna¤ó}E:b5¶›¬£4½_z©\ÜTŽü3§B¨UuPïcpÊ*­¬øt}g°ø	«¥|UõY`ù›ù²'±ps·˜£>›Z(pä6Ê^)¸d™gÜ¼ó·Yqìø-}áìjÓúAmgÓÆÊÜNÅ¹ßµêµÜÇZËeµî{­¢›Þx½‚˜QA%ù9@æ^°}+Ð	0`ï€TÝÏ"Š#²z%›8œ´â‚ÎHßtÛ±ÕÐ.¥ò9‹)ŒµlMÅæ6–l!4)\c>4åÝîÊGš¹ *'ÜÌXÒr»9~(KÛ¿UfÒÆh?zñVó1@ð#)ªÄ¢r…™j­é‡iõ%úqûäõÎnIì[>\ÉXíe÷¬Ëa ”³aÌüÜªÊóñób0Îs!îÇCñÔÍ]ÂÍ0|nsëØà[žßÝxË%°ŠÅTv¢%	ÍÅðák²ª¯éˆ¬zA	ôJŸÿ¾Zm’²E%µ©Ç;v/%ëqE2?O¯aÅæºÎÏ4~w¯?ƒ´ß¾ßË?kkkÏŸ>Uôï3þwmã	ÿ+?jýñÆ³õgOž?yò\­­¯?}¾ñ;õôK/fHÀa)y-lÍ†ÃßË>Ì¿ÿ ?xþ»;[Ýý^÷‹ÍðxöäÉœó__{òtýqáü7ž­=þZûb+r~þ‡Ÿ¿ªøù~ÿ­ú¾»ß=êìªÃ·¯ =” H)M~~ŒäÇµñGõ§Y©8lPâ·ÒÉUŸOÕêV>T¯³(R½t8½Ä¸_2œ‘#¸ô´ßRßJ×a>l¥ÙYû»@u/¢ì
½çq®&Ú?bJ&*M®HLà›Nñ)¦AÛS¹ô#89czŽâ~” >íÏ¨7´çjrÉ™D³p4J/£A+˜·]ú9Ì¢p¢¶:Aˆ Féô#u8;…ÙÔ®Ìˆî-	£¨A+EâËßg	rÜ
¥¨÷q2 \qt…å-=‰ôbÃâ8ÅÊ^å¾¬B„)Ü™Â«QŸaÒ>0ŽÎËð2¼âG¸paR1(?×#q^9Ix¼¥^]¡à3ÍÂ|Ú¦Kw'Ó(ð9ÍÂ,„¿£âŒAiFL×’wÚˆ5 Ï²pÜlNSÇï
Ç•E“”Óp†$æ¦—þ#sŠ ž<ø,Ø“yŠ1ç™ü\K8™ŒÐàKÜ°¯0¹’Ó@ðagD1a"‚þôŠVÎ¦ç)­ñ§t†ù4ÒG^-Ù[HSÂ„1þ2Â’ð=.!`ÖÓÀ¯pY4Œ2ªå€aCó=E7Éb¬?¦`øêÝúX£<Ð“Ë–P¤4¥ñZrn"_ÀÒúÔªwvÆè#ŒQŽ„!ÕeœŸ×f
Ìrˆ05Yàé€,Ö(
CœJÇà2Ä‚
S§+¶qÐØLÝñ´am}^’ ¥$ uZxsýî=¦êqT|€pß3àû™b×)¦„Ò¹ÙËé4’ˆa8É0`Ê˜!¾ý¯ðŒp<&wÄu†ù{ùŠn'ÙÚ¿ Ã­ZDà¤S<xlˆ‡ô£lRò0VKÌãÓxOñ0Ì•§äB©AÝCÄ@@úA<D”Ü,ËÂÏpÓ."à¡=d^cõÎáx2‚q­ ŸõÏíÐsÂæ¾×G¡Û­†‘lvŒå²PEUsšJ(W?†“iÎ;ÂEYW^B¬Ü<¨€â˜›B—®¡[ê1´VÂ8@³¨üÐ…0[ø=»ƒ£„Lð[¬Ñ„à´YÌéQƒ _!#¢t¸[…^œŠ<½ì˜F“|3X]¯Ú Ý›¯aÞ‹Àñ1{u£0Áø…„I.p_h¼Eg@ˆëæÄã…í6Ü„áÚDQÌ©s¼žÞÕC6i0É{¨·Cô—¶	[ìÌ€þaMD$î>‰,böÄ3C^r%O)Å¹O]Z<ñ) “š40“æpÆv:©F'ð¦õcHža@§ Eöž¢ô©µÒàSäeÅDŸAãQ Û‘Äp*°Ç,‰ÒYÛBÎÀ+AtGrÃf>‚[^…oúT©ïK…}*K	‚TýïG6K‚ò6
—;ÄÂ-¸dá„õÍ±	:!‡ >À%È¡tyJTyzŽ!ŠO˜Q	a7\N´ù0*Â aŒ Ðç˜$'áð‰
ÊÌ´LåW€Ê”´ÀÈpoKNñJ¤ýþ,#o!Mr3ÌúòÄHO€Âƒ°c„9ôjHÔŠH!ò–ÉxÅ¡YÈÚg	Bu2E–OZ/#fwö0 º QŠÈ|z$Rd,E‚¯)\/½T˜aGvf(Ì0ó4Ÿ¢iÃ$	Ê"Kp6ñ” ¿P¡D+L$YvëËJSêž8Ôp†§k#°ko`,*ò*Í­˜Ü;UtÃã××À ·ìJ“mæôœœv'i+#’y
Nðk¤{øpGD¥™´’äoÝ@8Ü¦þT“2Éàî	†Vöãâ¢(Î4'\éDWÈr÷	iÒ\(ü %öŒB]Í‹4æRº6Â ‘4ãÆzA,ê„Xª7§,ä€¸šŸ¶ö±®Êˆ@2WªæUK$–ð¼,9Â=ÓÔ(ÐóÁ-¢2ËyZG
ÐScñ\‹ÑÉ…ïHlü æŠ CJ™ž ÜáÐq©)%ôC¦xóu¡ãîÑ^Ouö·ñ1âíãƒý6^kau4L]6„­vìð˜‹§t¾ú=6÷h®Î­²Æ7—1ü®9Šßc¸ù¥Ðu©a"_·
H³iiŒÆ1i†N „ù{³îÔ=´»l”ñÍœdõ&Y_t4ÀN9¥8ôê•êbsiÂšá` Gžs xXnZÕ¤C”×èHjV¨©ÁÊ®\ë]9L$¦Ú¤5fÉ0¯Mj­ˆæÌqÎ PÂ	];üƒJ®È9`Ÿ #©a˜Ÿs1!d˜HÒ­ta…ƒ†@˜
â2;!õ¸$ °ÏR‰PúŒŠV`Z\œsE|®Vdb5YS€òA¬õ*’é·šö8Ôhb·££jýÆ‚6øYM@Å²`¸]‰™SÛžFDŽ’¯ñv‡gMQ„ó€Ð„´æÄÂ)×IgpÍè]$Â22:´Fô‚x!jw€?GìcAÝ)N†xT±JŽèSŸZØ3‚Ë dúò6]ê€mxçM$•âð[Äã®ÆCgv(ûDD Î?š34t$ðèÈ*m†“m*—¨€‚'ˆaÃXx&tÛY@Ä£”hªBáTŒ]ÈO/Xý€+sFæ$ FQÝñžâ)ÁlhC”°³†ùE­¡S@‰J4PÖR 
{$3$ ®kWqm:â‹JÞŠ	BÃx€¡Nq1ýî/¦-%ù«š„"L›G¸~Ìƒ'œMì<O@€„é*Á@4:æ/xT»$¯ï§(räµ@t"’óXÝ•ÃyÆ$ÖÂÊÄ®Q†@×X¹QŠP¿03³¹ÂÌmÑ-¡ùžLáX(-ê…’®
Â
n¸›±ˆÈ$ñ€Ø¢MšÀæD,ª4k	³f+¼RRÙ€a!Œ1Z¾38Ì^ŸÃ«u``²5i“XË($N'=!²lyMÀ5XÙeˆÃÁ „I„E³sž¿ŸÁ·ŒAˆ±ÞRâ¤ÚBÕSóüš£ÖDUvÉ‹hÂZ‘X¾Ò¥ódßâké^VÖ0¦È”Nˆ‚ãðön¡ì!yô ¡Gx{(ª†Ù@íh Ùî ù>2AŽé;POc”ÃXØÅtvˆ’!è:ž‡ÙrÒ T¶tp…Ö‹†%Õ™ no&Êä+]ûþlkÛÁ0éož¡1$áåh½D]±0ŽS¬¼aõvÜ¶$x0"ÊöŒz¤Þ Bf!µsG¡ÊVŒ;jØ‡ðÖÀðVj…¨jL:ÒåêWÃ:[_©÷@!ƒº çt®ÿ><c"¿þ
@Ør•&Æ,n”%¤JV$€	¨yà4§;~ZWôŽbXÖbÂ*"º]°(‰ ÊÒ¼xõÕÐLÄ¾*#/$
ÓVxR^b(Š
ókBD8 Å&¨VQ´Á+—Â¤¦º@]—›¢¬FŠQxê¬¾-5!‰OXyŒÎ˜Aâ)p<£‚3æõ¢KHL˜ø8œu92o	· ßç–KpúxeZ-µÒí¹Ü"{mù¶˜Ú~8¦¶Ù†ny¯¬0¡ñÈIìIH%@‚‚aÌQ(õƒm±äò:í^‰L×ia8š;ÙdSmj²[e„'x­œâ¿"‰Êgå8ú7é%j­Sö]ß9=ìÃ<(^WjQÉœ¦)áòÜ ‹ˆäžÐFe»™hsŽÐ	Pœ@`’É¾°d¼•íì_K^m«`i­:ÇÀ°~G0zF54í#Gðu•Óä/Åb/`—ËÅËÅž¤°1{é®’pÌµ¸,qƒt{vj@cžÛÐÚ€¾,P×
&f»F Ù)zSàRŽ©ôP8¥Ë1ž%Z‰%u—Qaˆ¶…SÉ0	—Í1î/Z(¥¨xõ©‚+›ø]2b¿6åf9Ô²È¾ËáV'm¬<·7]ÀÓ-^‹U‹tí3@€Ñ2nw¶ÑÂj¨@™BÂjdôB16Ÿ‘oP!@Rê¯µ‡¶ä6%Cô¡6ð“=¥@ØÅEÊJ‹–å¯Ð:4Û‹Š¦Ú$©çwÑ	Aj@£™ÉgÉ(Ç8†oÃÖ´¥¬õ‰r
JÈï|*Ð8!f¸:$)¬ò÷é•â‚R`Gj¨³˜rA§9Ñ%byd‹§³©Èâvðâþ€a'é%(Çgï,Ðn¢!(ç1û´PÒ$ÂûqŽ˜?ç¤§W¾NHLþ“ÇdGÀˆ&ÀJ­·,Çƒª-úY¸6ú¬kfÖ7Bù(”³Ð>o·Â™%JÍÈ'©W#B{aòÔøÎÇèX¡ÃhÊ</øÒÑ&Î—eA£Ír6Êá°.¢è!v%"ÍÊ¨}\C¶«'–,‹áÈÁTísžŒve!Ð7 /*TüL+zdvAº•Å,Ÿ	‡`¢é2'G¸ÁFÌYnl,î"‡ÈVÙ5E&}p%è€N£óp4lÈý¦Ø°Ä†ˆKiÐE¦½±iÔ1xùÊhŸmdìßc¶ÙF4°ÌÑ.	ô‰QEj8¯óxÂ,z®n¸‰±ÃøÙûqÖŸué/Rq%vì0p,Ž£•S©‰‹pJ$Ä{ñ /ÐCìd}Œ¼9Ê r6D|ÜB:¢ýoÙïÁJù_Ø×žp«æ-íÀ8ê®\ÇýÔ;<d¥€"T×dÝaû(1i3Fÿ<IGé2Ð-CrcZ9F!¸öj87§Ú))løLn‡´Ge„°õuÍ‚~Ü9<pÇû0æ ÔZŽòÝXSÛ ªÕºþÇ?>Ã;ä@xQ¥"C¬FªbÒ'K¢ñõè=ä6â/QŸV²/ø2Œ©°Û•öYÂ¡‘FÈ)NãÁLéù”o2!	ÃëŠ: ž	*ˆ­Y?&„’\Á	‰§<ŠW”Y¡8Æû#ô áN(ˆf*,‹™VHªñMõ®šEz!ËäX;7AêJJ$t¾]—d“_wö©fŒepk
0egš¥Cª¡I§÷¤åÜÛt|ÖÔ\$§[áÒþü0÷Df.6ÓaZ¬xpYâÙ¸šL'ù~vÊ’Øš±Ð]ƒT ?GÌ¦WG%Îl¡±ëE@	‘pbhåÙL>\$1Fô…&’« -(Z<¹0>›èïaŸê³(.$è¹uj0*,@àž‚æÚ˜v\›ÛZÆ]Pßœð‰j´Jµ5»h7ÉÑ=8Å)*'/¿›Ç\it÷PPôEÀq8>A^¯$s²6ÚàBKxê"Ûž–íD2þÁu´°Îµô—U‘6Š†1£sÇSû§é$¶ms±V“ˆ(0"‚>Ú'U+n®HÜ4t ¹ËÈ6ÙCÖIxe«2û> ìÊ12V"¥‰ò‰å…ÐXì:R Û†Xa1,ñžÞi.ò¶K^®ÅU©|3\NÍ÷Û
¬h˜çZTvžÔ»a£§û*DÐx€8BmÎÅ©ÉFûu#¤eXb@ü2£	;–8Çó‡ýõ¦Øgˆ¶Dh‡²"«áp/Ò<rIZYa Š0™ê &÷>X½¡Œ%gBº†¦´j—}ˆb&Q”¤6äÈÎÂl0Â¸”µ9ˆ‰ø²I‘ª<Å	ÊQÔß×Á\XjmÕ	œ¯Ägo-4Œœ	¨6üLÇNØA%¸Œ"5òËj=×Á^ÚÌ¥Ô ®_¢‰±,×|W@ŠèÕØyœ‘F™ëxy°û’Ç¼Š3É†ŒeZÂ¸œ¼¯3wæÙ4íÂØ Hñ!YœÃwØÏC#+ø2ãC^CN¼p\íœ¢÷øf(R}QjOØMD‚“wä	:Dßý`a§dÕ×RmÖaqcŒžä'Æ:ß@…•]tM_¤£¿9Rew@B*jàº#µ(à¸˜“ ž!B£ßÖÔB´ âšÀ¹ã¥¶,_Vh*‹fÄd9*à	Niiü‡žœF@$¡.à¤ýú¢ô²"ƒ®§„T¶ªã#/=üOïÈÚ4û!‡:Wé+=Xß§•ô@„;Ï\žºÂŠ°Ó×p8sx©o(©0ÈÄ(°0ÊŒÀ:—:½1\LÀ&BÍ«´ˆ&+Š4ŒOId+‡¥n™ù
Æt@ínC²9ôÎ¯r’%Ì‹Yµöi§EŽÖ$ï'ak»S‰jS_ü¥•PfÛÏôè< s0J-äèÂY²ÑÚp@€
äYÖþ7ÝsÈD-Cý=a)°¡ˆê³´7Å¢¢¤Å`üÕUflºuš0çtìOZ˜œ0·Ê8Äš!ã™lXb£†Ù
ˆèÞA†(™š‹ëIÃ…”x2) —ÁÓ‹ì¶ÌáÝÃ1 +9j®ñ±Q¼øÍñ¡¡=¤$¹§ V#¸zyšHÀ	;Àõœ¨K¹>‘g¬õËˆÅ„U’lÃZE=X„ý(r‡:Â‚=„I**ˆ•àŸêêk—îÑID‡s`e|”É±ZU.Ð•áÂ†²òCkq®Jl(Nûý0'ÉŒÕQt©Ó‹zY?æKÔQqmWvCØ«—Ï<Ô\£GòN¸Å©ŸZ¹hÎÅ?mŒ®3Ÿ‘€Ÿ=3d§',¡Siµ³ÏçQgÑ’!h­ÔÎ©/<pÑ¨ØsAOf&t™>äÉ	¸ Æ,cë c3*#'‰bà¥Üï
°&é%Ç3­D4=¤OJóî6æ¢_<ŽüãëmŠö	Ú¯²eˆéÑ;»µæ\q8"Bìr÷$Ë±|;ü—rT‘bÖº(PßZ‡1nøÃÔÎ.óFåPkª_Ì.Ã¹ÐmáËW®šA’‘lò<Í9¯cn÷†ÜªW-ÆMÒ€6š0&«…:ŽZb†eX¿uŽ˜ÌÞæÜÁ^nM4÷ÖÌÈ.8‰¢¬9M›ø/‡™?aW'l/`G`DA%»
O¸ïÄ!C=[ t>˜Ú‰aÈ1‰·ZÇHØ[#æÑµ21U‚5â.€FŽñÑY ê	è¤pÍ±x`pÃÆ^R}ÅðrxÎw ‚æâžGöÀ÷¦”H¡†„ÆxÔÃ‡Öh)‡¦ØÁ|6f%ƒšhEÇD:SÌ¥]Ã±"šYwË˜ÁH—¯êÆÀKÃ1pÜ¦§ð=èÝí¼Ê-Ôžcãò&æ<HjPq€zÈ¶è„ÂÐ‰aƒ¨$˜°äÞÑ&C#=Äöçm¶ÒÙét8ã÷ sëu€£IGçax‘RØ"Iá™Î¶q#¨tvƒeO«å„X¡ÚÓP5P^\u0½š¬˜r —	#ÂW"Gaž;)‚YBûg&·¡0¹âMÐ	)½ÂÜš˜£WÉG}@#~®_<¡¿øNQš	GÙÑÂ0ÂÈˆ‘•`/¬\–3œtÀÊÈÔ3”¦Tü€¢LÀË%44Éø	Ì'áŠä iqŒŒšl6‹$€QCHï…"áw8n‡ä¢Tô»r¯˜!8†m¥ƒ¼¸ÑèhH˜®þ>ºbð2á‹íØšàœT'2"p¼PT‘¶U¶nèx<oH‚°ÔŸsBóù]ä-­BA>ÃPÅ¨ÈfÄÙ8“y’Q_kPÆ+ND+ÐTRS]”T&l*â}qh¹6O#Ró}©5?%Htgè9Ñ’©tM±šè‹Æ‡Ó±[ÏÊJ6-«.tml#ísæèfÆ‰Éì0ÔS97Q"F†®uÔ&ýà&†µHdµÃãŒh'ñU“h:‹§WF.Xƒ¦P•ÕJó¦¿Âœ˜#ü’ð_%à8
*YïÛ·ok ’)ñ4rõÞ€u}5ïŽa
þLH®EÛXzÈ¦P!KflxÖIÊ`GÄ‚˜”ÆN!ö®Ü»UÀIIºfÉÛƒ8î™p3×˜ÞÉ€Ì;Žöê&lÉ]¿£GÍÛz9B/
Cè[æ§Uz”)]{¡ùaŽßÝY{m2g+rJ¯‚JA	<›ãeƒ"£0
Ph@ÄýADf‘Ëó()9¡PE£¡	¤ÐîÌÒ²ˆƒ¡ˆ[¹·®c¦>z"XËEœŽ(67“úc”Ã™ö1ºq(ÌØFÕ…ý,Ísw 	ÑXp˜*Ì=g-“AÎõ{V^ÎL¢ÎÆ&Â²,Ü]æ GÄ?¢
1Ãó†ƒbàœè®4»ÖHë\AS	 ÜŒpb– [„ï™¼‚cSïZÏ[XÛXûeŽ#mP­9ŸZ¦ƒe‘zƒ8.ñÒ%ó¦N;Cœ•xÎ¨à$@Š7L"NúÉ"Íö¬Ë­T/‚gÅ%¾&6Á>1íî 1¨ÇŒp’›M7±™“iÜ`u×åÅb˜\pv8±­¯”ó„QmÄéÂÊµlùÖQên­ñÛJºg6Õ7DyëO
4AGõÆ›ÝUPÐ•JÎP$áô… ‚ÁsÌ€ô¶«w07 †UU¡1¸Pêp*J O(‘Ã°úE?§’¢„dŽ>èÔg°ä–Xƒ%<m5³q»â/J/eÐ•8©YÁúÇ¥Þ`!Ò»U·Î2±s–tBˆbC|Çb!É÷Iùqwä>Ô¥ÈÞ[÷ag“¸­)#e¢èÐ7]Gçcý\TFÁa¾EU^ 9EÊÁÙ2#»¦sz*ƒ‚í¸¤Œ]_H(ü0%úÊ:?¶% ‰´I~þ-ôyQšL¬…c“ÒáÌÚPSrÈÕúS"¦ëÏŠkx2¦vB™tSR[²Ã¾l
c~f—›	{a×(ƒËTd Ùµ:`ã3m[,y[iñ¸jŸ,ƒžÝs(y„¬lÇS»ú~¯¿‰yL1º—Çƒá$ÏâÄ(·geù6ãvN
]ÁìÅ­[¡KJÛËë¡1ÃðBBS~ÉneP‡Ã‘ÃÆ–3©†Ä¬^Û0p1øFýÂî}ªuáž„ÑÑõ‚íDQÃGLt¶ ²¢ê2Pfp{Ç(ê¹äUjÁ«hØæ¬\Š$HðÉí¼CÓÐá=N¼°:»§€‰>2±Ìjà_ù1Hso»jUgÙŽQ"oê|¹ÖY¨.ÀXØ6-Ç‘ÚÂèPÃ:¹rÛ	çä¡ÊqM²1H)E°‹¹ÿ¨€É`*Wb+F›ÏFóÈwH×jbšL((‰7¸w¹‰h?Ð>"ykìš¹ú€Š]¥Gs÷˜CíYë	…@T…%9ZÍ‹yYYÔg¨*6b	¶~ª ¢¬3”MJÕèÌú3 r$É‚Pû³1ÊœÚâÅD»¢ŸÃÿ«‹EJçŽSÞÍ§ujçùžyìQµjÔÛ(†=ŸÁÅ»€yëwm´\sK‹^ Ð~.…Ò	Â3ln2SƒBF tbT(!®_C‚/„t'ÕQÐ	=‹}Â¨ äìðe#ãwJYÎýI‹7ª¡*	YÇ°M¹už´Ì52áLwsG	x° QÔõkÈvÅŽ LƒÖû‡)(qÂö7îƒòÑLÆˆ­U89Iè¦5 3ÌA˜6˜T¤¢Z(ºNñai'o„•|3[`*OáÄ*.¬ªQ¼œŸe5•D^-àÜx7zH	…ƒ›ŒÅT¨ˆ-,hØ
á»É¹G¶ÖÙôñÆ	
#á¡’‡¤~WŠˆS‘„³ÀÔŒd¿«cª.
€ŠlDd_`¸!”Êb&ƒ(+£J9ÒËªJÁþX ú‰=6±6ä2[%ƒ2ø4oºÞx†â³ä¶T3h¹2Ù•±†!'?[S’j†S9	ÊÇ0(ººmJP÷’nÄÀ¢³§Ò–tÚIåÎ^‚å{ið‰Ç,'ð¯ÓxÙz~†¹	­¡çbŒÎ§eù´nõ¸ ¸\›tÐŸ‰ƒÑŽjàûØ…o °œ‰QœyQlÜ³ô¿-Ý1ßcÌzöV"ÄÌ%Cã¯Tä@iŠô2
¾a& ânÊ·¹¥ùŠiLc‘EÎÌ=Ð‹©{Ô4œ´7õß ?‘^šš
!øÖ†W UG%†ËzÑË(Í ÌþØ"ëßD^~Á´ÇGyÃm…t	;é:G¸v™(9àp½P ˜”åçE$ÙìÇNÒºr(·©–R9$k>‰Ìâ…µ‹Ö¤3–8ÀgY²,ÞDDÞ`‡6„JN7Šä-õJ¹ÈH©ùFúáÇU„cÎi˜‘db³æÈwœ»¯+Zr¶^Å!ø•äÐgjìpê!¹”`Ú€ ’+„aY”î=—’p_””;šóI¦·ÓKÀh,_ˆ¦_¨§2”gN®•ïUñ¸«¦S¹#à–õK£L4$·a¤¶8Ë©p¡š3Ÿ±+‚ä/°þ]ê¤#‹lÚçeÆü&Ÿë!ÊbdH·ÆX'Q5´â¡òdý?5–ø]ñ9ñ<œªÉ¯Ü’\,‚yeýïc©NŽº•Q·¡5<ÊcŒ£ìŒ1Ç­÷EômÞu¤1Æ1ë¨­D•w'aîì$šr‘ËÀÝ+açˆ]òÁ‘&œk`Ü^QKÏu¾ûZØÙ~õ*2(‹’Í0ää-ˆô€¬«G–8+n™â™Fâñy4ÃuI–b1¯b®£ÎÝ‚A×9kBq&(~OAýÓBabIù3¬>1äª$6‹¾”§B…ÊµçMÒï³’,ŸòÞç	Ò^iQ
w~{c±ºn–^…#ñ”¥NgoÙµ×1¯¶Ò•»cz |Šf…©äž^°09–šœÉçO©ô79}0¥t†¦tŸi%>puil	öÀzAÌ•€¬pÔLÃF6R9öp$õÇÝ$V/·(ÎcŸ$«d}½¥uYK]r.a«cšÕtàMAdÄ;e,º”P¡Æ˜´S˜Î«sh+pR3ž@îÛ,·µ	m"„QeÂmtWmÊï™¯¥-†ã‚]¼THß¼`<ÑÀ©ÆáøS6hiÄõMÃ¾9p:ÈHYÔ×Ÿ64§ÀâyätNœnæwMJxP™‘ƒÌ…œ#-n±"PZeD ÔžiÞêÜ%‘ã‰
€%}÷«Rz+ææ¸†WÚ-æÒƒLG5[ðÍVhóªÔE¾cè4Ý1›ìrjb^=S¹
Ü³ËévÕŽ’]Ã”Àª‡Ùh€UµÕirÍOåvH¿„sp…‹€KZP\ž¥\tŽv§[ÎWÜ–}áªDž]6>1Ø¥³?1Ò›‰‹ÕìŠ¬O5“L$’+m	 i$Ö)v¿ÇS¶¿I~¤¢¾4X•JEî‰H»%Çéª);—è‘K²°T)Ö}x¾‹(	9‘“k˜‰ÝŸ[¸µ'ë\Ö¶Fç\3…Üý¤à–.LL©¹Î±êsv[Ú—F7™Æ­Šr*ˆ¯XFVMY#–Á“ÒR9Kmnpª+0è"~1¹ S+ÊcÜ¤Î‹,MIR:¶=tLƒ3I!åÁ0iŠ2À–N[C05U4Ž:¡¯:AlÎ^ahsÄêÈ2¹TEgà+Ö
e…RD§QÉØVaJ¸;VS¹lõ±™¡áR¤à©F`êcëÒÓÁÈU›ŒFdS°âáŸ‹È¢ËŒxRLqÅÕ]‘1h@µ”TAqB–ƒ’y›ežŒå/msá…qâ`Uneà÷dîcV7Ô#ÆtN`3Â-…¦Å)È ÊäÜ‰Ý%YF‡Q]D6Cn]Ý€ù,ä€,›a›Iä•IEæ:òƒê€ÉA3msª¸
2énA:Óº´M¸QR)}ü‡UtˆÄ7:8ÊEy­* c4SZHGûšµi†‡îUWûs5¥’6T`	=¼ÁËó‚	›QYL>XœËf¯øS°àG†pòT›Ò"°vŠ€©jX$‹‰¥¤ÙUMÞÒ,à±ŸŽ‹ýÁîœè!Žo˜Š/yQ}aÙ:·E½l½–¬¢SO2Ò‹AòÃQçk!-_é*2•XrHxµj02&‹žÆ	èTŠ/0_Ó)JDjÓÉN¦ààÚbƒ“ðjLqN©u(È^U
)M£í«R$ðŠó…¬jô¹óÇfÙ¬¡KšRm¯LI´®t;´áµAiI.ú	>U'-S?Ï#i&ˆV‚wV9~.¦Ò¾c^âRÿøq™:!`”âÈ!žÉ jjsEÍû,zè4í\ÓDòÎV\`q¤àÚ"²¸¦ƒ ¨%kI,õarí¹a­îP{a§…o¦éø¢óX—–uÌ~&SƒŠÉe3ããuÚ	Õ! 1òÀTcÓ²¨ÆLãÕ—À mFDÆÐe7rÒ˜Ý]O§Þ¨¶Zßhaq«žyÆÎû GÌÒË\ƒt¬å·B½?6Q¤N™ZÕú!•³›Qevg8ò£]l]I>â¾	Ë×ST¹Ü®t}; $²[œ×Ø†æ÷mYñ“ŸmÐ„Ægñy*åtjYg£i¨ß‰áH½Re.Ï$ K¤èL1´TÐÖm7a/%»¼kþ‘âfTü¤h*Ò4AK<ë×ÙuüvÊº Ñc	­Ç‘dR0ÄãÜYèfì°ü Š)Y*ò\ÛØè™É<táAÉ¨àähfx‰9:SÇ¨ùÉcn5£õÇ-Œè¶R&¾KÑA2]ô<Å@Y,‘’¼Š„%2Jþ	Í¼—'$>µòY…ËW’NÆ2Z`ërØZ¯nñ…Â’S‚L®x7Hß«@A:&…®DdW«c­Ëâþv×Œãí1Åõ£ŒÃöœbþFë2*8«¸Hü8gW1¾<i©£NÖýCä¾½T0 ˜æ½EÈ‘­R€,“Ñä-ô0ºczÛó^,¤{†î\8üKÆÞ8¸?ŒÐÖåú°BÒ$Îb“Í+Q‹ÆêEÊ®’ƒ±Ã 3JFô†?gBS˜GX&Fp;~&ž ®ŒJÂbÓ¶Žç¢[$3,,h"¿\.1 Z4!ÄÜÁÏè*À*(Àª&f]L‚°VOó®#ÕÀ··”–Á‘Ôd»sl<sžÜ…[Téf…üDq¬¡ÔÃ›ÀâM90ÎÈì'”v}ˆjQo>
Ùð±þyª½z²?™õUësðZ³vw…¥ŒùpÅ/,Â7¨fMà'«‚‹ÈÏlêã¸¯ãùqè‡¹Sü°/ß©jÁä†|86zÍî$4ºî¡u~—ìÒjqËl¡z&67Z2ÍltnàÆý;ñCIêõp…‚¸„YË VD¸dÀTÜ¨´-	ÀeÄéÅCJ&vO[&4œQéG	g÷¦{ÔU;=µ ~ìuöR¯ŽðuxtðýQg¯¡Žèïîw÷Õa÷hoçø¸»­^ýtww¶:¯v»j·ó#¾œôŸ[ÝÃcõã›î¾:ÀáÜéuUï¸ƒvöÕG;Ç;ûßÓ€[‡?í|ÿæ8xs°»Ý=¢ªÚ0;uT‡£ãn×ñÃÎv×]“ªuz°ìšúqçøÍÁÛc³øàà5ò“úóÎþvCuwh îu{=X Œ½³+îÂ—;û[»o·a-õ
FØ?8V»;°3hv|Ðp6i«GÇÅÀø{Ý£­7ðgçÕÎîÀŸÕz½s¼Sì:¼ò­·»£àðíÑáA¯ÛRB ~´Óû³‚`ÿãmÇÐ…1öð…zœËÙs Ç„ÛU?¼EûÞÝö€‚€êªíîëîÖñÎÝ¶„izo÷ºïÞ1tvwÕ~wÖÛ9úIõºG?ìlŽº‡#„ÒÖÁÑŽr°Ïhô¬ÅÁåÆá±«£–™bì#u@üx»¿‹8êþÇ[Ø+b‰ò±Çï|Ô%@;8ü¸ÃÓ3ˆ¡1Ô¾°ˆñ ØÚ;ØÞyÇ"ˆ³u°ÿC÷§^àBàlQ¶óê ó
²Cë ”ðÜ¶;{ï»=3pÎ@Ùn¨ÞawkïvTû=Ø+-| ƒ¨œ1Ž€ÈÉç¼…‹€¸¯æÆÏÜÅ®Ú¹ËH©vzˆÁvç¸£hÅðï«.¶>êî èŽu¶¶ÞÁ}ÃØVÓ{7pgŸO÷KW|çh;Ð—Œðöugg÷íQñpæ !Ièœ·èÕ¾ÚySm½‘cSÞUþI½£xÕ…fívè:Ê<°È	ìŽF82ö=oñÛ"ø$†ÁÀ^)IÅe^è™Œl8òÙ†ß›"ik_ôcÁg”b±N^áÊÂß,TxJéR" H]²t†%\XÿgUF
/EgÇrLýQÊ™ ˜ØòÞHÈ´iæéóç©p2‹(£ÇñÈY{…ÍÄ‘Ál ©—d|@Øtgö€–ÂÏ=ZÜ¾XÖµâð’ÎyÎ„öç¿ëÔ!q8×±-ÿ	YÞ>«²€Üñ É»>¤\ÚW‰u8ƒ<9-ÙÇå9æÀ¹Sñ¿ÌòBniC<#ù”kaàÞ9YÔM¨øÅâià?Íâ=·‰¦Q~OÂˆW¿¬jüKZ7Ö¤QŒXƒªC1ZñU§NÉ_Çî:‡¸5\±é=ÖA¢âl
"rÂìù½–Ü{3 ùK¬™NUC¿(1DCÈó ${ëêo¤þÔŒLSCeYÌ"j’’RÇö]=g83µ]é)[”M¹¾EpR]ãÍÙÿÃœÒ‰dèÓ,Ž†èA	Mq"1·¾“ªDZÊZÝª«o±:Ýw0‘êô½ïxÞcy¯U‡mxÇ½iÞ÷9žj}P\œ7TíQ\(%‡¹§_HÂÏ|¾¡Õ˜’iÁÆQpúÑªŸnZ/k6­j Ø}š·«ÎÑ½ “tHgÉŽ“«Ò¢>ªÅ5ä Zd{aòj±‚¥Ÿ–XqÚUQòàÎ¼”¼zk‚8Â"=\»0XMÖU£Ðáâµ‰lö#ëæ,uåœZd–¬²cäC¤¾=ŸN'›íöååeë,™µÒì¬­Ã=ÚßÁ‚:º‡I7ni,"Â´“ìßüô8Õ¼G;_–&X5
ß
	'¹{såÄÕC%Êzä[šÊéÇVB„G6äŽÒ3®´)ÊÆÂ°SªÛÈÅNÝ‚½X¸FRV¿•y¿»ñM,á!—f&˜v^õvßwwr5™t¦rœjzú_ôâûåÃ–®xŸ-ë Zp6Lz×›FàÛl’¢%á…;]ÿ¡» >Z–Î¯&hn$w¡2¯êõÑLoÁ?ýZ½›éì„cïTê`H‚ˆql[š©§ÆtXÉBëµ/„»ÿvÇV?–ghA3²5¨L€§é‡š‰›”%S¬)†ZÒ¬Üëô
#Ä^m_AÐ/úEYbºP¿ÂÁÏ­‘×+ q0.VÆ«Y7¾)ëŽVÌ›¯OÝ¿8ü²³ó¬$KhøhÕærãËÛpIƒ¥—”-‡(1ùp¤›[,ˆ„{>\9lbß¥Ö_äN®„C—CËRôcFò¬×•$ÛqÙ_ÊëÄ;JÀ`òL‘E¼4ds·Q\ES1CÊ›92¸¶gñ=ºÔ±—^€Owë¸È.†eó¬{%…ƒ
o–Ô¡ŒŒ¦t,¡©<ŠÉy¢t:9¿j_ž_5ÌÍÑÙdÔ:ŸŽGp:¿ûGü¤ýöQ·³½×m_hŽµµµgOž(ü÷ù³§ôïÚÿ?O6ž>{®Öo<[öäù“'ÏÕÚúãµgÏ§Ö¾Ðz¼Ÿ²XJžFÛA³ápÁ÷¼eþýùy ÞnãÃoQpŒ=PC"¢­Üêø‡í&|ßM.þÏÿóÿµ”G9ÉJ/\’Pe^[ õc0’T“(¹ˆAL`?Ò`Ø#~£ï4ÔNLKt<ÛùF¤
 F‘-ƒ‰j™ã‹À9üêa]û	·‡“ìl{«!%,ã &B÷(8ñt¦]§¬7\éz±@ Ç¤hãŽAÑ‡0lÌÔ<=É<™Óv´ÞìÆ_-¦i†âEwëþ]ï”C“’B•Ð«)ü
³ÆmFÎ,·ôöê¨³Õ FßÏ°¬U/BêœOgÃ¡õ·Å‰)ê¥”Q`$näløÐ#4$Ô\Âo~I0æ£Gél ‹jåç	Xú5ïdŸÍ¤•<8ÉŠÕ,éŸ³"Æ0-âv\— vÁ}zb@³d\zâøaN}ñ¼”fAV|\¤rþ>W¯+bž‚¹9xÝi‰¬óª¡|}Î.QP‰¥!ŸÊnœÌ>¨öþÏÿýÿÂªpÛiÿ={ÀQ˜‹8å(Ì'§¾˜rcS>7ú4ÑçOÀÐ®Ú½iMûç4¿+ø`þ^ê¾–AËqÐ NéÁPP¦³Iá¸lÜˆGÇ Ï‚MFlt®Ë’YÐ)<MÇ‰|…ÇÚÂD˜Yù-‹ftí¥Îà®O X4Ÿ,ô¿þë¿pùAJðûwnó·ÕÏðïIG¿¨ölm½ÍOŠ¶Ë“©æy°±¶þ¼¹¾Þ\|²þdsã›Oÿ Ð7pt¼‰¯³a¢¢ëªøiÕZk]
oÌmgÿõÚ¤ D­å¬²1;ëcÝÕ…ßæüœty!?7Ï/~ÿžªoàÚîvO^uzÝï~QÇSÐ#6=vöaÇû[¦ëÏÍ±ùîÍÁžóù+øüí6ü½õç·‡òñÂ‰–¬¢y^i¡£Ú³Z%¹kŒRóYT_6ÜÅüáä]i|#½o¨ø-­ Sw4çsµ­)MKí!‹#¢fgTñ¢Å*Ý‚©–ýXB&TîÌm¾\¶—TŸ\a#¸=˜³‘ÕA4Ñ»·¢¿­·–M1à)ÐP5¹ª§°À¬¼ì¦Ï9à	´ÀÏ€¡­ú„* EôIÙÁ€pyž*ä¸c3ÎZR=(Pá| :ŽwöGjêlŽx2Jƒ1LåáÕ¦/êµe3VÜË%3ž†ý÷³I^5'µ|Ò˜'õ©ÇÂI‰nÑ;›Óš/—Þò*ê´d·Âì«‘®=ŽƒQ„§¾tî/é»SÐÝôŒøä¦jOÇ“¥gÈ$ƒÀ+œ)!zNéV»x¥Àê1ÒãßEÄÇo\úÙ‚~ÍÓG„0qÍ{‰aiÎ24³°azª{?BÎýH­jqŒcSe=üpS?¡u,a’h‡ @ú[W«è†7*å;”ZªJšˆ’³MXÈZ¤6,â¯D,?VJÈE
c 1.}4 ±ð°ÿÐ\Ûh®?;Y_Û|údsíéíä‘õÖZkMK$÷2û-ä—¹·1»^Œ§pŽfQ¾°ÇÛ\‡EY/ÓÜa“*åJ›GrYµùyY„Áâ!4‡tn7ÄîÁ÷s†Xoã5]Ô·{¼u²up´dú69qÛ€ÍK›·e}/÷]ÚÏcÎœ†ì/ÁòSÕÄ#op~†b{½™ßƒ¶ßnÏ…¿®Øƒ¡o-:Jª=_®o´6Zë­Ç­µ›üzïGgðûøO:…õòÀyÖþtÂö¯ƒ÷ë­?´ÖNÖŸm,©·u´sx|òú?öË˜7Ÿ†.RødX]«Ç.ì¶EÎvk°ÐŒ)æf‡b¼¼Í—aŒ{³Û]ÝkÙU¬êU¦w˜xùmªîwƒ{TÝñf`é~orû^ÑA âxa‘X¸IGÀÎixJYŠô[+ÇÈû›uD«Î'½õŸ·¢u²Ý}Ýy»{|âŽTøtù€ÝTÈ“2*Px$N5ú€ÜÜ¦ÿ ÐÃo£à•ÔŸDÐVê~ÂXà|ÂÆ¼€!ÝÐ/Ée
¢¼µÖù?Æ• Þ·é?Ü÷¤BíËù°ø÷	?Kç}§£- (Å§í ne;Àò€#^Šýu4ˆ‡îß´"ûgLkà~ÒB±ñð¡é”že)†«øÍû„ÉŸð?'@Èz{­ÉÕœ‘`CåÕøâŠ/Gù	|š[R»¶ð½&°Y>)|€d”‡~ñ8`}[+†%Àa›I|‚µ$ZøÁBL<ŠXH‡óKÇT˜úÆ7²§;N±g¨Ÿé§Yä2_H*#Ø¢éðRfýŽ¢U$eõ»ABÉja©wÍvo7à!{1A°§
¿²É“7×ÃoJ.JCPt¨µ¹÷UˆöøXBð@mGý÷$‰“¹®sôÀÿ¬j+u³ëHµšúå¥­JQ‹æ¡ärÝné¶n+¥ZU-à›h$A2Qÿ<UµîÑÑÁ° 2££§ƒÖTÙsð?ØÉ€5|+‡ðŒý?zYk)gí•šHág»[]úæd¿ƒ“xÔ´†ôáC×|Ü}ÔÅì×ìŸ?Ì0'Åwí<Gú¢™ïŽ+e<¸ê-Õî5…fªmœå‘0œFªÔ‹Ùúq¬“¹ói4‘²Ÿ± }o-Çú¥ü;ÐV-ý+®ZêOØV…ÑÜ¢ÜŒŒþ~ÊajŒyUÓ®òÈ5P|î5	”½oŠÃšÆ‹®Ý}mîtun{yV©H² jrx–Fçú’[²¬;£ÎƒøB£c2BXw²þy<È§¯®Œ]ã‘vi¡±½á6Íë¸*¶\‰aÌxTg9?7•
 bãr­hx^xó"–—ÛsS¥B?Ä.îH[¸)2®ÂÖ€s9sœªž±¶…5lÄ—àfIµY–Á[ÙŒß˜3U@Ü±pìÖ+dc^‹º¹Fó¹cµ£°M§xË7ù‹=‹›»&DŒTwžÎ=-g«¡ã-	ZC[pŠå]zN,@’¯¡€/ìƒ=ê5	4Çâ{fK±.á²ÂÒñ´‚à¡
?ŸÔvÄ¤ÛâÐ°YþQŸŠŸ`CK¾Ýu¢qá‹’@Ë¤g*–ìãv…9AÔSoÇ¶MÂ[ë¯©ïgne‹6$jWaçòii¥r™ô‚Ð¼í©ThÊøÒœü<úïnwéã†¸dø÷^oW™z_YdÃNHý‘ñB=‘²ªR pÂTWO„9›²™£^³²è²áÔqgfòö„5†ê˜¤´úù¯Ð7¡RÊ\,‹‚þ-µ›ÚÒq¥m@ûc„D®¦ÃñU‘`í@bÆžZ„`µkÕW\¢=tˆÇýìÑßž‡q½²t†ôÕ}m€…wMŸqlÎ¢ýu1ÿƒW`âá1‚—:*nçÑh¢VÏë¶r76YŒ½cZ|Ní§ø€³ ­h¡Ð@›&b%´J{+Ž]yj-kgæVw_€„ûñX†Š Õ`]·¼NÑ+–ù‰™Â¶co¤ú2@†Ì¼,¯Z~`¨fc9ZQXKOýè%	šš·ÔfÔppö˜³~LÛgªsðTY	Gz=Š>P"’+îÔiT/è‰˜SwÿõƒfÆBÝ!2†ÓQÕlmnÃjvWÉôÔ‚¦·kÄaj×‰ÜP+ýAzjvàü]n•»®ð S!îbœØ<u•OŠ‡IÚ¡ûççLí:Ï±¨‰O¹bhH…¡s»€h™å•\Eó ³ÞX¼È…ËCÑM“S-IXå	±Ï´äÊ»È²|™TDt
ÐŸÁU#y†än§Þ`Ì2±ž´R$9Ç
§FÜ+†žÐ´,{ñ«Ú@–4yÂ¸‘YïÏs®>ø²tf©¿xeì4wŸÿCkhÆxk å¶Í§¥>=‰ÀtBåïºÒÊ½èîÌˆë¿kÇV¨ƒ]€ëÆWè(Œ÷10‹Îé+oÙõ
YðWñ	¡Ø 08pyËuOiÞziRíd†I¿Ýàož¿p'õVOŠmü©æÿTŸM×céTú¥¨ªýÝiRAÝª>»t+|ªR©ïnï¼&äÇ@´YŒÁ´‰/Ü}yŽCä&Ës›»,*DÎí Î<©òTéÆƒ`òû6aýÂúÛ÷AÉg}:l´ó*]Ä•û®ò?yRèó'øž‰ª¡2tÏ" íÆ§´ÑØå(1eå•Íá(ÿ{ßºÞ6Ž$zþ}_Þ«dÆIÆ’x§äõŽc;iO;¶×r’¾¤WÃ(+–EHÙq&9Ï²?Îcœ_»/vª /²|‘§›˜Ý´…[¡PÔ%#úgŽÚœúÀ‚uew¥¸pÕQËuÅX˜z*ŸÒl¼ÞÜÝ/™ã+w»”ÌOŸc68þó)æ	éUU”akóª‚1ô"
$?<a(p"À/AV¦Ÿ1ÑÙÛù!s©Aû±[ÖhhÞ¡’ùTÖÝädÒçø~h¾®d¾ñÒcœ5>ZÜ8Prß®×2ZÞ¦JÂé;Í÷x”ð1úÖDyÔ3+uYAeƒr¹€õ`9|þÍxvabr½Ù·Sï¾±ÅPÌ' ú{»½ã,€½!®²Ê®‘}
Â<½ÆÊÇ›/ ÃwÛý—»{e<Ía<Uãš‘@Ÿü+æ3¾´²+>¹ðšÑGzY Š³YûGÇ…¶Yû™–èÕ—0~óF»– bêYWJïÔƒ;Ú9\Ô¯üMÜb x‘· hr×w0¾Še3ÇËŠoÐù•âEø¾Úd¢;î”Œ¤œƒ»úÂŽ‚>¿kÊö†«ã¦:ñ¶a¥[,r67 gy*0+-ÁÒ‡ßGá»¾ÇªäŽ]ì“Îa!%úMzæ$#¼¼ZÏà(žméæc`§åóNÁŠxÆ”`âë&ñ<ÉTÊÞò3+9êg…ß¨ÑKBôR’Á=ÁÑ6»t+ÄÑM?÷ÕBÝ ˆ‡'EVæŒÏ¨…—ØBrO&ý5¦ßg;Ž~Kñ{B!éÝõZWÚ$õû)ˆÅrÙvÙÑÆð]x¡PW?öV¥4.DÐÒk”\(™NÑÉqs
HìÛõ`r[Gô>š¿]´ˆ†B§O¯èôiúfGÃ ØÒÀln4˜nJñPÂIô¹)øÙœAð3KŸcÏef5â¼pxî&ç B<s!â·`BÆœŸˆî\
ú9±è-¸Í»$XýÆvÜïú¹âôM Uñ§Ð/gcæØ‹>Ãñ?
Íý÷¥|¹¾.‘.¼Ú‰4–þ$fþº·³ÿêø‡ïùðé·~½J”FÇ!ã#ÃI&E¦áFl wõDìÅ—Zaì4~…ÿÎ&n›
d
ï¿èEEƒ51"ãAt’ÆNàr‡›ñ"`ä¥ÄëhŠ‹¸þÿøÇ?2ƒmCš"µÓæRÐlz¢>»QìÓWKaþû¿ÁIüó‰½{‹Z¢¶6¥­">7“Ø;bý“1Êáã™Ô»
2?m
c¡/ÌÍ3âóé*&–±ù½×“¹';¡7¾@p°Ïß>Ç
Ï·Þí?§W»‚á¸ëT¶áÒ~•ÀÄŠÔ³=õtÆb¥Ä)}J*x’üŠ73wöÃŸü$Üš-¼‰ä^Úüø'~%A›BÃ5}HŽËÞÏp
²/eíN¯cq)N9*£+Z;}&cµÒW³aF6`NLÆé_DÖ
7ºÁ{çÔ;u¬ŸÌ!íU\Š	2.J<Íó*óÓœGŸk8z€$8ÅN‘œÞ_ÜfÜ|éž%hÛœi~6iQ7	)>çòM•“9:Maðé¯Û»GÊ÷ô?jL¯DÐé S¡`0ò) bk„°ØÉHÕàú%ª	b#o˜²v‹=-žaÏá®l¯6¥M¦„vH§‰×‘K¦ZP²@t&UH»aˆV\©“ž¡TcÏ™@høœx‚ (®¡-	1—þ—ùŽ£›%^1âR<Œ‹ôë+øïÌYÃgqŒò…Šåh÷Ýà„­¢ds@ÁŽ:kQFÎÙuÐÔ µÂÖ³Zí¹ôëN¬—Ï²S(€€œLáØŽEZ¬è3¬Îô„>iîê· Ò3:q±‹´¸Ò
1SyWxT:×šr3	8T]+ë -ñ¦17ká<N©³ ¯íö%I¨´ßälÕ}µqµÿYÖ5ñÿ£úÿQõÊÿÏJR-p£1çø‚`J×ØsÏj×»„(OyõÆ¶§Ú¿T§!{ñ”:åÁÎY?âÜ¥Bw¾öJ|D÷?ŸñfxbßGö¿©ÉZÞÿ—e)Õþ_ER±³M´¶iWñÛº£)JÛl·Û†ÓV]Û%¦§¶]éß›­¢ý±<ÕÓÛj›tlËÔmHXOò¼N»£Ø2ñ\Ù³ÄÚ©­™­ù¾J(iCâ© å‘6c@öeCÓÛn€ŠµS»4Ï'†ìZ®ê™¦×î´5Í°‰ÑÖe]sbú¾£ZmOÛæöÄ&²ÚQ\Õ7eKÕ_3;ŽçãZŽ/»šÒök–éP¦mh²a›‘¡ÍŽ¢*
ŒØ±UÃp½¶é˜Ž'gðºÄ–]@úŽ¥üÌét\ÕÒ}­­À„wÚ
XZ¾qÑ2ÎWmŸâùŽìi®aÊºë¶n˜†£hFÍÐa	 ÐŠÎðK±-ÃuO7ü¶áëžãØÐå¶i«ªê©Ž
«(ö:oq×vEQí6€·E3Û¶%·‰×‘5§ÓéèDSôŽjè´åEödŽ¢8Ð£í¹¿c¦ºELKÄó]ÙÖtÓTŒ,¬r“8CUMÃnûžæ«mCÖ}"ëmÍvÕ¶3dš2|öÚžU„UX[Yó]WöWu=M×ÝüÔ-Órä¶ElEö|×ÒŠ DK<âmE5l¦ØPMtd p-Øªl›Šªú¶éÌëë‹A:€^ºéÃ†ô:MöÝp˜z€®˜££È: m	ÁöÏp£ãZD†Á€Ú¾ã¸šmÍµU¹í˜Šk¾£«ó'ç–¸W vS,, Èã£slÀŽ÷`‰4—82,8ñ,Ëöm6“ªkž«Â+V4„lÙ€™•- D€ÕnÇ“}CÑ]ˆƒm«šo»ù¾	¦›j[²ÐwÕ² FøW—¶åÁÄü?+7;Y»SÐØ6T]ÖTzäú¾ì·ø«#wLÕ’m˜q;·Ç²–¥áYÍ†µÕK'ŽÝi;N§m*°ðD…er,lAV}âýJ85j).Ð)hŽFueK!µUÅRkØ–nÙyäÉAAæ¢fzºÍK³;º«XHe5€O ¯m‡ êh²“Ÿ\jR++}nU›.Ú	#Ks	a}G¶` 2ì6_3G…½¢´--é”ƒÔcÓ ˆúhÁSÇ€‰BDt§Ã3[uÛšnÈ¦Ãõ,Õr4×U•r¨2%q}ÑôÔèØNNZµã*ºå9ºÙ±ìvÇP:Šé:¶æ8ªß‘=·¦ÚOüçdÆOˆ)w€\ÊªêÂ’ØGSÇ†ƒø-ØÎ8Îõ@¥3 Ø¿­u|“tL×35Ûë(pÔiŽm;šn».œ«pÖÎ™W­Ï.òú¨Ù|ïÂ°»:À<6ˆôLw5$#ªa*Š§!1mÙC6JÁªJŸ™•Œ†Ÿð8ŒjëèÊÀ¾
Ñmµc›mÅ‚Nb€D¨¶ìuòír˜j¦J9[ëØ°Ûb::’9 2ŽOüP;¥Ý‘mßkË–|£áÓy%nÛ‡ñZ®Mß€sªmépü·ÛÀo(ªié®«!q.¬h}áá¨í±F7ð[* &Ž_¶‰¦µÝVËƒ]«/X-Ù¼öF@KðdsÍ×<y)«-wlÝ³áHU<¨#Å+C6³Z~fi?M³lé€æé¦e+¶ ð—&‘8à 8µ;¦U
“w’ü“Ëší›È	@¨v¨À§5ð<¥­ûXhÃ6aK”£“¢–Î&] 'Û@<8ñu×öL kì±£š°;¦S¾­¹Ï<Šð*ðG¾eÈmÓ5, -2q}Ø®<	á 3`š®(¶~í5¢' |¤Û1dJG,q_ÖÕŽÕ¶;ði€Àü¨óˆU)	`œž©êŽëÁ.7›_–]OQ<xà[dßlnË”î£¹·»µ³ßÛ©iÉñlGç¬­ßƒ”xpzÂ!f ò{Š×KFè*ìàÌ‡¯gÿ×6@€ã§J:–â™*Ì|\3¾µúƒ
îKJÈÝw(÷Æüû?”—©ü¯è²ªáýì7ãIÆ}wÓ\þ/“–ÝÆ‚û]“\täKXÝÒ´êþgéñ5ÉßŸ>–ò›ø½ƒàCö6¢E§þ,õøÔÓÛ½gP§g“z‘£©†DR;ë°ˆªô
NªÈ™Îƒu©w1Œ>‘):…¯-³Ã¨&Údi£`,ß7i|þ½­è¸ô4 á3t@yMv/þ·ˆïÊ¡öŽ7ŒÊkÃÇmŽâ¦ÑFSÖšJ¾Ð ÂÈ3àÚÍÃÙãy²²ÔRŠ[9‹º‰8œ Îö¦`˜Í±Ñ%¾‹¦”åFÇ'“˜ª€}£á[€I€?Ô’g8Ö§W‡{­)ÿe©‹øc`‰‡- £‚Qõ"9óCáj16'h{o—ÚÁFìÝ.çæç6^ÇäE{êS?µ!%‘é2+·Ø©?5óË6N¡q‡ò<aÓFÚESÂô<îÒ•?ªŸ§:ã>‹ô8DÁ%7¬±ËåÌÅF“µy¿yÇÇÍâs>_xÔmÏ”$„–iü
†;³LÏqo¯¿õ¦w|ðz÷—Maô1+uãËZgæ„,:å>LèÛ<·ßÌX]¬glüòn)Ì‚…§ u4¯(t(–µÇäÀPÖ€yÊùúœÏÜ0–uè)t-£ÎZÚ¿¢q†0`ÑÎF€ÊjÃäŽ…UÌfn 0;‰‚h´àoóV ±.…W´¡à¡ÅÕ©¡E‹®dEG'[½\›Y_è˜á=ÂŠðÓssF*W‚EÏ•)àí€Ò®9l/#žÝ!q«,m	Y¬ÐæR©è_K7ø÷•ôw·”{r¸—6®æÿE3ùû¯bARéû¯¡Vüÿ*ÒÒ¶è7(Ì“2ûŸubö’;rŒý¬QSjñ)Xvä9ú,ëî
'xQàLFp±‡ãXÕ2ï!'Ž¶ÊÝŠÀ§Jf¸Eÿè™Ûv[pÄ™ZmÞ¤Ü^—ãÈþÈæòíæQ÷-zžZâd2ué°§t×ÞÏþöþdãýEKú•¹+ŒYË/¿IkqI×;éÂ×”mú’~±»ÙzÌÎK(àt?ˆiöˆgSc/×iièä›ÊºùÌÕajù+”=)-+Í†–¼iÉÀI»œë‘ÿÄ]|óp’wµä8ÀCvÌj&Ùtw÷çwËI!c‰­ƒý—×¶¯®7dAVØÞ=J–7¾p9 låPJ°óµ
œ€›¿  NÊ¸¢bô„|B‚u4‡ÏøÍ>L<T:—ÉFå¦Ÿ·ßT¹ÊùÇËOÝ5ú³A	<œ'ãµ¥ÒA—[¬Q˜ŒeºµÍ UÉR“é/5n„«?æ½áf¯à{½æcRã@³†©Ý5×“Ä}üÝ¿¤ðÄggRÃ•òŠŠ’ú}Ë#ç­ñl4ú<@ã»Æ¹Tß~¬Æ³©¶6¤—›»{;ÛOZ­$ï	äb ïW;Û­úwõÚ”4¤²/½*ý›ÔRCºØZ]zÿLjL¦Ãq$þhO°ÖrÒ»	ïÀËç~±£Ÿ]8Þ¿K_»±¹½Í:ñåsˆˆÖ˜A?àÌ?UÖ^þòj\SðÉ—J;¾7‰=ÉEƒORãðò;î¹•»ÏjÒ&Z¿LëXˆ÷×ƒ]—¾ƒUjHéä¯ñÅDê®`Ž‚…œ¹¥X«iÑ“¸¤@ÁÓ¯ÃR@9@ÅK
å	—Pþdny¡Ðèj HÞÒÒÔ‹­PÏíŒºXÉw¡df
!1/‚L±X€í#ákàdç47]â”f>qL˜÷Ù¡ó‰Ùv£Û£Jô&ÿ‚LJMEóíF#šýÝà'Ì‡·½/ÕÝq7õUóšZºNëü{ìL²½‰áwÚ‰iˆ½(±òn4èQùf7ŽÐÆ3² ã³+àë=u° ½÷Ž©Çí«‡÷HXÓä\Nc ®åÌ“oö‰ž[I&³Å/©õdü`Å–cqÖ¨Ù]…ªù:ç£`ÚµgQè®í¡o¬½½Íãî–„…í‘ô™r¹I¡òRNò=EÉä`LÆ8š².Œ¢i’²¬²þ„#^gö9µ|F+ê1HH	"†l laôœMØ‡Ù$ÍÌçD6¨Ø2ÀòÕ›¸Å¬ÕÓêäfÕ©]ºPpêf TN¡„7ƒ‘² N»k+ò¯´eiã³³¯Ûø}8³§—q·
ˆÃUMòäï;XIÔEùNzH,KšÿOŽ•ó0¼Ü¾o¶Þ§.ëóˆóaÐ];f¨%×®¯±îƒ—wg~«c1•«y/·úªeè‰þ‡i þ‡¡éruÿ»ŠTÝÿ–é€ßà5°è$¡º^Œú6øÛ¼¾Öõâ×¸>“¤ÇÌe®õ³±ÄÁßMÊÀža-ÁE5ZçSFÿSË¬û;cÙÿkº™êÿBAYQ-³Òÿ\IzLÉ½ÜÏe#ëRÏHÌWY>®‚ŽL0OKózI¦Î27é]Kœi°Ì#áz&þdnŠ©`ƒdPz]:ØÅ¶{;;‰çš›ïØ¯=Ë7•V.·Eü¿.ðÿ²Žúÿº)›Õþ_Eªô¿Þ?o^ü0yÿ9àå¬z¥^ñï7êìïŽ)¿_þù[O>û¾Û¸¦ýŸ¡Zºfj&Úÿ™²VÙÿ­"¥6Á÷×ÆÍ×_“U¹ZÿU¤œ—ž{iãëoifµþ«HY¯8÷ÓÆ-Öß°*ú¿’TpctmÜ|ýuµ:ÿW“æx¡ZjîY±rëoèèÿ¡ºÿ¹ÿô8k¤‹ÒRì‰>	E;ö$?‰œ0ô¥_ñaãÿ0„™ºÒoßañqí7ÓÌš?DPoB¦ZíRÕjñqâÌc`lh{0µÏÂZípóø‡îüwã	uÕd¦ˆÎpÌ3è»Qls å¨÷	qOS+[¿À¦Ö›fÖoQo².u¥z=é½$Å#«£ž>Ð$aÕÅR’Ô,+_È($´ Ó»Ý9::8Â—ÚØÄšö©´&L›¯ØŽ'öaÏÖ UrË«W'³“*Y×NÌ¦,î—8éµ…•+Ý˜?Z*÷Ù·Ü6®{þëŠ¡XŠŒô_U+þ%©àìÚ¸þúë2üòzåÿi%ézž6ïÖÆþx>-^ôV'Éª¬j•ÿÿ•¤ÇÿF9 äÚ-ïÒýÑm^Ýâ9pÉ}Î<–î„Gw{|tå«à£ùÏ‚Šï‚òƒ,úºôiv&‘)ôa4"cÉã‘™2Ç§GùWBç†Ïzæ½ë-y=Ä—½GËzÚ[j)0.n$á9çFÀP²xê§ÌÚH~6Ç›p=n–›o&ßrL^á‘@3Ær³Ì×ÓF=®RPj“6JUÝ’
Å@¹X!ÎMËÅvVÙr˜+À*½¥° 7[&+6.ƒ¹¹r™¸·I9f¿˜”ÜÞ=z½¹Ÿo•å¦¥PÀÚ.”b¹_èòe­q_áÿ7B‚ñûG 6.þ3^‘CdUŸ§NX‹£“X”½Ñ &í]þkÆ¦.®C\2gúö%Îyöäšã°	óCáåø#µ¸Û
Æcªç%–bs—Cƒ“—LX
ÀC-„q;žçÅY{dä÷†ƒ1ñ¶È4ÂëDf^ˆ™@ÏÆ¨ëðáü¬«OðïÜIóqŒÂù¥ÆAc2Î&BÆá4˜`s$Ä9Œ·åR›­F¿¶[ô;´±€ÿ³4-ñÿ©j†‰üŸeUö+IË—aùæ ÿCæú~™…6‰>†.F<„n£5ÆTògð7$s¿m;”ö¶w_ï4¥Š`î‰äAç"Ë½ÂKòÚaöÌ‡å›ùdÜ”^!ü¿gO}éÔ)8Ú„=àgöx†f ˜¿ü!Ré‚L=€E*®ô}\ò€hç‰·ÉôÇœ$tO`Ó:3à¥ÍñöðX"¸áAþHrÌuÀlÌ„Çe˜ï Ö nHèjÊÑWœ€°Î×ã	…xDØm74?½ ÃÐ¨¬tbˆaš7vÇù(aÌè³€°£sjì8N }u<%W:WkiÓì7$wÜgy~ánÞÞñ7SÚ|TœÀ?m€Vn *‘è`:8q/ç¾MÊ2£`’ËñÂ†ë(OØðÆÜç¹Át`¹oG{·5Èé_½Þ›†¢~9>|{ñ—Þùlè¹oþù&´:¡¬ßŽÞu.^y?”öä´urzqþËËÁ¥·ùÓ;'»oOöìÿíœÛoGòtëÕ§O?¶‡cC7ßöÆ“W/Z¿ìØd6Ü{û¨æŽ7T3ñÁÄn/	µúnäf–› y"Ö6¿Ýë¤ È‚#ŽÐB@\Î£ 8N¦ÁlpÒ€¿‡Ñ†¤Á	Ÿ‡ŸHöË`xNÆû.z°U›t!ßÐ©å,âØËì©[¡Ñ=ísìgµÑÖGŸfZþRîI4ÀQg.xƒ-øòIÄ,^ o”FüøÓ‡Ý–rðêõäõ_~|÷ÓäböãGâ¬¿ÿüóÏÑ'ë—±õáÒßÞ99>ÛýaôÓ»¿o¾ýqxñá/WÆd°³×¾xuxúÑ:ºì¼Øoý2Ùl½nõ~0Ïþyôã~ûŸê‘ÌhÄ,Eã0ûç•T"[nÎ_H
ð&0OwP¤ü¼DÃö²¼[Õ0cÞ•.¦°'ÊK £-cd·®.3%È¼Ìt‰Žg¶;šÓÜî£/]^ÝR7ÂË±;çóýá%^€€ÐP^ìÃÙGÀAÒ¿œÿ}þ”á×+æyþÓ2¸¢ ã[Ëœ!x9w¢b÷=8Ûdˆ4ƒ±ˆå¥ØÝ]5{^gx™ðda,öÒBå'`—Þ@byfçO³ÕoCò¾ÅÛ“o?]3€ÝÚXpÿc(fbÿ§È*}ÿÓ­ÊÿóJRõþ'ö9{Tº¾ÎU*_ç*«éû*Ÿ"þúÇ/€b§ŒÏ}s6 ÈÓ7‹×1¯¦³±—pöü`ˆ·0”÷ƒÑ #‚Œãk"{æ'OŒHÔÃdÚÒ«O¹j ù¬³Ð±†ìÒ'sCUÝ Ý©(b±÷‹;ÙR”¤#à˜%÷gòÃÄ‘èi0’ÓHŠ{0%C¼ <¡Eº¿é«4`MxJcËÐ[¿¦ônHå'†('®ãÝaHQ
…°ï(£’¶ Â˜
~MÇý¶]`µh]
ÑmZ…T<c8çÓŸÏãÝÓ\îŠÄ®QRÏ›Ýz+˜D<TL½PßõºõœÏg¼™!Æ+jSm*MÀo±®ð2ˆWžWþ=º•z”Î;Jž ´{I ˜>u›)ô3~l,÷øM­QrÝ@ç—è’S€‘<vuHÙ]Ekwre{½½®bjf.ûhç°ÛîÐÒœ›ü;îž˜›ÝºKÈ§ïmïàåñ»Í£ü²…aD›ÖyŠ­B­>Æ¦ªñß_Z¦¤ÜË×ï2Åü³‹’RÇo·3¥¢s¯;q²›’º{î–»jLJÁ¢`).:óLö"Üåì‰"„ðæËôÕcù*©øãÎÏ½ãƒ£¢Ü‡Ó° â°è×h>„æDèýþîÖ¸ºõøW:\„Z‡’1ý„QÚ8>¿wŸ<MäW’ÒçÏTëàI¬5ñÏÞÇ –ÍÀPºT¹B©grU–«fs5–«ÕE9vÆÝpºÍRºv°ñ;´±@þÓTþƒtúþoVúŸ+I•ü'ö9+ÿÍÙ	Y€Keþÿü?ö
³9á÷É¹eQ|aGnÉcþ™xÓ7,ÕàÍŒlâEé+?õ5S>kx_ZlnF-Ë`ÜT&”ò?‚l ‹„((«Í[uíQÈGu›\tQ	³)¤nªµ@õ@pùDFXN—*Iô–}üJ²ˆ‘”Ùƒ
¸ ¼†_ŸQt¬3x,à.–ó¤4&)ãž0ôÍî«¹°ïê’·×Û±÷.ª»‰Þnì÷§º»D•Ü²¥âÜ´\ºÚb¹4—©ï²²›žÇ™aæ±G_EêT»w®ÛÓ*É²ç¡Ej¶“ÛØÏ}Q­·àá¾T¥—+µb×y¢+sŸ,‚eô1¡ä×`^	øŽÃ,(ëž“©Çdüg9 Q:†#ÁÅÖùÿ>M]“ÿ¿“ðþ_Ut#åÿäÿÕ¬ìÿW’*þ_ìó5øÿ‡®ÌÎ i‡«H!ãŸW–NE6ÿÆŠÁsÄ¢J5øaÇ¹¢S¬ÂÁA§ËcK–|Ü=¬¯J™T<ÿµ>Ût}ÔÓêsÓ¨;] .´ÿÖåôü×PÿCQ”êþo%©:ÿÅ>çÏÿòð°á±^K#Ûãê é“6S~üs(pTM&Q†u®ìð?«BæŽï38àØ'ª1É˜‰¦´9†Ãg„7s qBp~ruL0GU÷qwécuw¿÷q|K Ñ`Óì³À÷w7wÝ»­Åfé¬\öý•=^tÿƒ„£á…)D˜”dNAXB$‰¼;šyäÅºDïhâž§—8T…}w›jûSËˆÄ0}èÇ—Eew\=¤,w2@àcþ†îŠ
üŸªôy¸€á'JFÊ=ëÿjVjÿ­XªŒï¿Zeÿ½š$ðË;dnÃýÝ‚ù[j‡3¬Ÿ¢ö…Ð»}ÛóèNP›t–bPÁ÷O²}¹Ú.ðR4æÒ)LŽÝ»9'5‘ZêjÀh¥§„]T¡¥‰ógìT	˜E:È82ï_{tmîˆÇ¨£ja&>Ö-ºÏ2Xb(ô9LÇMyŽk>^ã5P(¢Hy¦„æfÊ¨¥eÔ´GW<*^ûMQ,x´sX„…¹I±«_¯ÅtÕx©ôÌÍ,²Ž©\E6]þ48c¿Õú¢§8žÐÌû{—ë1_±“‹ó„	‹‹oƒ6s”bau2r¹KÁ£OûzÌZý	Óõ¬ÇN‚®zÞ«e¢~§Ï|Ew<µ›L‹'/5Nâ‰€†&¹hã%^vWåºÈÿ©yþO])ÿ§hŒÿÓ+þo©âÿx‡+þ¯âÿhãÿWñœÿSþOY&ÿ§Ü‚ÿSüŸò‡åÿæ¼ÿÞElÿGù¥Lü Uüß*Raý­”õÑî ,òÿ ©þÎ¬¿¦WüÿJRÅÿógùÿù›àáóÿ±w´ëO5 ë¶³BŒç¬+·ýÀ#ß†œð-„~®d‰'Kh¥e´ß‰,AŠ–•#éAŠ¸á¸V¿¿ÌÛˆ¥%+?(9Î™Ys(€Âl@õ;¥„o¦—.¼´Z
Z½´ZZÌ¡Ðc\(tïÎ¦DØ=JYõê:j¹èS*G$òÐ‚ÄÄˆ[È”ÚC’)µJ¦ü†eÊ*};éZñî÷ýÇ’4þ—ªQÿºYÉÿ+I•þ·Øç…Á ¾-åïl°iê„ü†.æDÅ¸­C‡2xP×pçPê½¡ ¨ÔC¥A~‡>Vä9ò8•dŽÇX8éOÀ R^¯¸Ùë½;8Úþ“~Tcm 5	ÊAà÷‹l˜=òä,SØ}òøL‰º›MqwIŸ¡ Ôð\©¾ÙøÅn|’:dúÁÈ“’"Ã'Ö­1–”g)0ìë¯ÐÓÇ!È'"µ¥?ÿÖ%¬KÝ®ôüW öÛól ÏgAc%ý–^²™,Ì†ÔÈ¤ôšîk5î¢+îéÐ–ºßK /[ÕZqšfa˜í+`{6Ü.Â_‡]‡Ž°Å„¶ü!ûícÞ |ÇýRaá¯êîQz3¦Û\°ÇéQ7Ý@©|H·Xó´c‹´Q(€­/Àg6Œ|ÓÛ9ú"Í©¶™…ŽÕÂúr§%]I@æü.©V`+€(ŒºÂO›òi0;Önïïó×w×qÒy¦5è´$pkôMy¼y¸Þl–ï®fÉÞ\`½1Šçß-7qiS¹­¹eª¬ø—©¨ÿ«åõïòôOÓôYü÷JÿwE©zÿç®ôÒ»~¥ÿ[½Ùÿ¡Þì«·Úê­öAèÿò›y öáYsr¹cÿ§fÂÿ™š,ÉŠ¥ÉZÅÿ­"-ëÜÌ³|»c˜8À{7ÂËÝÃ£lÀ<„_“ÛË3{ã.ô^Æ¯–Á³šŠÚ”õƒ7‡»‹ÞY‰vVÚÎìá7ÂÑ=hMÍ3y‚I°G¨³‘ë;ÿÔ<:ç}ÊÒÑÔ…ZM^¶9 ÑÓµíƒ×›»û4âÑÚºT§¤´ÏêÕŸÅ &xas5 <¯@k&+-V-lý)¬K’„^<«Ñ¨OCŽ£§y¨ü‚N4jÉ²RWÃQ\ÿªÊ½ÞžP_MëÓÙyÃIïº±âq`i‡n=é8FúŠëÖ³Ï ÀÕ&SìÐCvºu9õëŸÂßÖr“ñ]®øa<Í…â¸ iqvÙ~˜ÌaZ<Ý|i¼’d5ò¥ùt¦Þ¤óS
ç/-<eÍ)3¥U99x·×‹‰Ë¡ôå<eãÝ8§“Lµ0ë™÷4–âuJç„UKçãªZˆ)"BfæåªŠ8SûÂæJçgQ­tÖº…yZWõµOëå§¢ýÏü«Û¶qûES˜ýOåÿs%©ºÿãþýÜÿUö?„«¬îê]âïÛ—À­ìÔnÿ»¨ìîÇþ§ò)QÝ)/:¾6³Z¥¥§¢ü'÷m9àûÿjiüdAŒÿªU÷ÿ+I•üÇ;œ•ÿæl‚o@øbl{‡Ö8ñáæ”AÜoH¤ò®ò¦•÷òJQþiRògèùÌPA/™;Iz1ÄDÖËhBgÄ½TúFïg*ò•· .h!/÷ÍüÒuº‰èwu­Œð'†ªÈ°üÿb<ÿ—¯, Ú g>¼¥Ü×@ 0‚7&%‹–—Øò"[:Cj›;˜¹ýþæD·kÙÿ£UÄxÌ…ü¿,ÄUÊÿ[ÿ¿’T™ü/2ùGäÈFÿÌ:ÓH¯?Š^Sëÿd<ÃyÄÀlCùÄú)gVTt øÁh@ÆS.ÓüÍâ´JÃ3Þ3àÞ	Æn#Ñ§¨Y4ÏÃŠfý5ô·j	3+þq‰ÿœ1Ää™IFÁÅûÃBEš@ÌÝq7µ×djkS ë ~ÌÁ6~Bûé90`œÁ(pìQÃgÉüdnÃÀ@Dò×#Òˆµæ Bà|€ž¸81‡œØçÃ`ºa».™D•ƒ;ôqÉnH›ÛÛÌ2=ü1ç)ˆš3‘	6'BÄ](¾³J ¬A=r$8èß›9Ñf¬A÷ŠGF½ Ú£_øŽá“×¥³¡›7û@÷$Tƒ‰K›[{k!ì8÷'PZjàK7åR‡ˆŽ¨¨	ˆMƒQVÊ‘i‚êÈyß¶;Ü¨?…Ãv@"^¡û¾®4Õf[—›Š¢†ÙTšz³-ïëÏ°þSnÝ!’~'Ù.0™õm!Gõ¯è‰x”L<NÝ1NŸ4ÞŠÄzù¾þ2ºÁÅS ð…ôÝC/ÐÆ¶N6l~ÓrÛû!þf›€<«/RôÁÎTøó5ð'™ù¥ Pm1= ËÜ"ÿ_ÞýNÀBÿ_ºšòÿÆQTË¬øÿU¤ŠÿÏ…|žƒüYˆ'_C8Ú)\àEï‘ñÈ|ÿ\¶ÿÚ\ÿm˜þŠç_=ÏÿÚŽ¤‚ûÈë±«>ÒÀ|Æ‘\¹ŠÉ¢Eø¾‚6Fkðò”µ°9ž0lFní€.%}‡ÛŒ€8³HzK¦0Qh›ÜÖMÚ¼¢`_&ð‰—’Í»tƒÆ†ãs{4ô6ï5´{9ŽìåídÆ¼Íœ±H‰«¯CÚÖxìa¨Áº–i—g1·-9(‡R;Iy1 A°€Öx	øpý¥±Î½™xh!Á¤%.Ž¸w§`šëX’Ÿé[šËºwÄ %½{O:ˆŒkÐyj»p¶ÐÖF8!îÐm4úz.Ž')Î¶Â†=šœØúúxv8ãnhëqMu½øç°Aï“ÉÏ;&ÀdÌˆø:è·É¯OéÒ"„±=b‚ÇU”@£È„Ó³±GÆƒè¤ñ]é½O*¿—ÞÆ%Jë'h¸1í<„¢ÜP: $6@Ã F‘3²Qïá“¸'õ~Øl(™NÂþ=fQÃã{aCË>û@!€)€}3GZ±gqÅ‘€Q<ËžÁJ‡5 –e™À/^Ù&ù8ò:Átn˜¹:¹–SòÏœg [Í¦p\¤3Ãºtó}4¥"A˜º5BÓún…Q·Â¨ûG¶þÀ`’á€ù,qâI<Gž¾Ó|¬›õC»;ö†ŸÈGøÀ‘„¡Ï{ä#g—ÁQf`X‚“A…éø+;¦ |#ºœ,xt9ï; wˆ\Ó¼ïáÌ£ÎØ¤ f³cbè&™¬íÑ_‘Ãüžp/ÑaHÛ/,0ž“ìèH²¥ÃcàÞQûRà°Ñ×­ÃxæOÍM¼úŸÿß¾Vãa\.TéÁ§ôþøñi¡êµ¨ÉòÒÚXpÿ£ZVìÿÝ`þ¿SSÔêþg©ÒùŒ/7 ç¨zç^¼3¥ŒÔÆ¼R£nPwRÁüµ÷¨U)vÞ°ƒÔˆ¾/8ch1™?lÑ÷æ,éfØb/Mø}“ZBFÃÚƒqFC÷PnZUtMAëþ‹¹cžIè­Azutðææ¸ÁäxÁ±XÈ3Î¥
™rBNG—ôçÙ0Ä›Šà”þÅÐ¶k±OöÇø¢®!¿®}©Ývž\`qN9bÜt¸Û¯{;ç°AŽA'°«€òF‚ßn<…Ô—tÓ;›HÃ\r%˜¶³`ÜòœpÂÎ¼¤ßn·W,[º ”þÏ=ÿ—xÆ,8ÿKQ“óß´,8ÿË0ªóiiÔ’ÓÌŠ¨¸€Îÿçö^õQaç¤ïØîélBIs&Ÿ|D|.æ3eâB>Ÿ/ ï‹¨¹!PsY>z~»ý?—þãò/‰Æ,¤ÿ²žÊ
úÿ3á ¨èÿ*R%ÿU”¿¢üåü}S~–Dý/@Àe³þ4- ÿš¬Rÿ¯¦¢h¦nâýŸnÉ•ÿ¯•¤ojKt{vÔ‡À‘^Vtú^éô2!±«,ÉŸF#ùRàSÉélŒÏƒ±Và Ë’Ò‘žÃÿÐ°™	h¯H´P ðDjDÒË7{{Rã‘ÿoÁÔThº'Ò÷4àû®~ÿg¥¶Ô™ñì!LÌpìNé»¥½ºùIgG^W×µu}ÝX7¯7O»û[G;¯wö7¿Ît1î`%S¤ªtŠžÏÎ©àÄ,š‰¯}*UiU)åÿ0˜ßÅ(äžÿCæ¨})m,âÿÌDþ×uÓÔÑÿ¿bUï¿+I÷&ÿ?à  ØWäÉŒÜ
h%C¹žå%%;’rìdÑÉ¿ÜiÊVSÊóŒJSÎ3oÆÀ?‰’}ï5÷ÔÊ¬!Lb8¼„~œ¹Ñ(vÑÃ`QÒadÌ+˜Å47'ÁÿÙRLÒîØ¼QOâ-°NfÃ©f b«rÝzé)íé³¦´é}€=H5 Ö¥Á4 Ž;ÅK P·ùñ‘±¤i¤aÔ¬=Î”¦öp”aä_«y#ó=œyäNŠË.µfá´5:->LþßV®î{…Âg5K(]ž–å¦*¤åpô±Ýp*º~+¯¾¨™Ð»H„*Ùã™=ºxH+-Ln9(Y	
¸…nÜÁÚ¯H?~«m†øÐPƒ0:²ËÏÚ;{…Ý1‰.‚éi“ÙTÖ6ýˆLó™RíWN²«_NH7Q 5TÕE[ÙÚ+Ü±ô×;¨2ÙñÝÂÃvmç#q)þ¿µ(Š½#ÎúóG_k¬p0))‹,-"ŽXüxxF‚YÔ#nW“å43öì©w0‹&³¨+ñ7‡t?þº3ÓüG3'!¿Ñ™"Þ‹ËîÙl©Nn<5¿‹¨Yþ]Pö]ÀÕ»:}Ò"ÿ/ªe¤üŸŽüŸi•ýçJRõþ#Ü#fpÿ^*â"·MàÏAŒ=Ëóz”£_¸Ÿ®Ñ¥T+L#²—1›&÷£?–|lâ;Oÿ('pkF­Ä–|)™0¢.™àløé¶>´°.¤Ë`lÕ¥Dmƒ3’†¦ÂË&ÔÿšÐ07pC&ð Û
-<	f#O°ÓÒ˜ þ¢=½„ºÑZ³‰šjhçë¡ã@lùº¸­NÁñ§­ðD"ƒ&Ì²ÔD—²ýÉ4@l²6OHÙ“"qôéóo°tðZÐÙçöpDZFã»Ù‰úuÛÛëo½é¼Þýeóx÷`¤Vê0Ã¡#¤è™Zðàhsko‡^šÅr‹†íp!û™Š#ëñVq–Z3YnÙ“	×	d0ù-œ Ë¤0aÜW:” ÛÞ<Þ, C@©Œ„£t¶×“›ÆõìËq˜@K<âÑ>
]K\™Îí_Ü™Væ:“xëÇ7‡ñ¸¨üÆx1LVP\êb´0ƒ‹ f'±u6ô¼¹°§Dýòõ»ü­@SÖáý}óí¦ØÑ¼€ÌÒ	ìXZ4~N—ÍÉ¦¨‰zN(Éš×f|­KíŠPk‡1¢Ç[WÀCÞŽ×¨Ö¶J#¡Ùô
œ%F8®,m	8^K¥¤-ÝàßW×ÔwOYþŸàæ4œ,±ü¿¬hŒÿW-]35“êÿšÿ¿’ôëÎþ«ÝýßjG$œÀÉ@Økõ[æ8©«4eö¿Ú¯¯vöwŽv·~«õv¶ÞíÿÜs´z§×»»Ùý3#†½7‡èo£ëÛ£¥éVéþR™ü¿DÑŸ¦ûß2”$þƒn™2Ýÿº\íÿU¤JþÏÊÿYôßÊhR:œg1íÑÐéÛ| –s<”¨\óf;¹K/¸¿ðjt‰O5­/¶„âv0‹¤ã·ÛÔÃøüt°Ì|dº{ oŠbÒÛdÙn6ÖõÚÃ&óíæQ÷­=š‘%v–«·ö”îÚûÙßÞŸl¼¿hI¿æ"Gü&­Å%]ï¤_S¹éKúÅîæ¼´3gëi‡@9EÈñì½ƒ­Í½/×iièä›Êºù©Çx&G	eOJË
Fó¡	aZ2pÒ.çzdç?µ¨É¸ Þð=“z ²cY3É¦“¸»?¿[N
Klì¿¼î„°•xu½!—Û»GÉò&·_øE@ØÊ¡”`ç'êám V° vÁ•\ÉT
'äÐ7Ýg1|&pöaâù Ò¹L6ê&RÞ›mÍ+7*£ä/?u×èÏ¥ðp Œ×–Jyìp{Ì[¤ÝvOèmR|©SÃÜ!^è¥ØßÛí©I’ÔØMV2ìÖ›’°CùUW?ã·ƒO†õšŒIUÂ]¿æzùÈ1lç¯%…NâBÂvN¿Žè×ºHêÂ×&ô Xû•)…[¨X
r3¥pGKA.”JŠOÊ•ëõp4·P²O„ÒîÕ¥Ù&LË)ÉL]‘ô³íÌö|ÑaiÑL!aê”ÌÚ`Ò]ˆFŒO4NX.»*íã½Xü¾ ºâ	Mâ,˜ª½- C{{ pv·¤ì6{$}¦grR¨Ù]ÃžÔ|ÛÄFÁ´kÏ¢ )PÆI¾O€Q4M²B–U-ñâ@'ž<‡ÎDè]°1ž.)“bKB8’‰‰lÀ}VÇÇj†|52p'iur³êßº…êS2¹ !JJ
%¼fGßN1q>ºkçÃò Áˆl'™*øs6ah1Kb–Ï€Îœv×Î¨‚QÿÀ…C×ŒÔÅRâ¨‘GÊâb²°àBsCÂ¥NBÅž„³³¯Ûtr5;;³§—q·¼ö©æá«ÌNCìEYÌ4¨óÇ]NçIŒ%­É…‡ñùšÑÇHLÆÿëUÃY[ž
Ç7{»ÿ™Ú(Â)ç.±E÷¿[¸ÿUôêþgi8Fo%°‰û°æÝÜ&Ã^ †,aÀÔ½øCÁ×î}•îšÊõ¿¨`´´kàû_âÿ¢á'êÿkZµÿW’ªûß¼þWŠûßâ50ë~u|]¨nƒ—~|­ÛÅ¯q{&I¥ˆ€°€ë‡×Ò7™{†µØŸÉ†\…ì^uÌç?ˆÝË>cñÿšžú0ú°”êü_EzLI>;RèY‚g„²‘9è9‰ù*ËßÛÞ<”0
2æii^/ÉÔY&u–˜d,S’œ|27C1êxµH¡ôºt°‹ÿl÷vv¤Øîæ»ökÏòÃM…ýßìoï¼Ü|³wÜ_ÿ¯©ý¯aQÿ_@ªý¿ŠTñÿÿŸÃýÊÿÏ± )g×oa’—þ!Tþ÷Ç˜ÿ>ì4ï+Îÿ4ìáÒ\€,8ÿ5+ÿ	¬ Þÿ[¦¦Uçÿ*Råÿƒý´¿òð¿ƒ[ø ¹¡ ëÈ$ïD<Ák«pü‘Ìl‰«õ}º­Ý¿Ó²µ¾_¿åØU»××héÞ?®ý–@æÂ®øÍw°Ìˆxs?Þ?æ¶{p¸³¿Ýë'æÝ:Ý`hÙúà*MuúŠ©¶êY Ù[Òø®˜yixÈŠþs6„n‰žAæÖ	&ù*G ‡ÚÞµ*M	Ãù¸úòœ‹<0ï"‚ÿw@jÊ N†}äË›˜±cÑýbåíÿ,E®ü¿¯$=–žìzÒ“åÑ–¾¹ë ¤ÛùK¡Ì~Xî•Ð“=à·è D€­B†qàV$Ã>ŠEâ¬X†¥Œ*þØÞœ2xc	(At™¹øÏsÓA1_·oÃ/ïnÍƒEòÜ.,P4@L_‡?‚é æ¹R’YB|.Nö8öW‘ùÇƒèŽ»ôD×Ë`»P‚}.VÏµäŽ¶‚q™&I gÿ\Èìó mâW¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*}céÿN}H‹ À 