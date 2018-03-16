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
‹ âÈ«Z ì½ëzÇ•(š¿é§¨@tDhp!)Év(Kˆ„$&¼IIãc9LhmÝ˜n€#s¾óã¼Äù·¿ó(ûQö“œu«[w $Êv2âd,¨Zu[µîkÕYœ´÷™ÖÖÖ¾yøPÑ¿_ó¿kø_ùQë÷7n|óàþ×÷¿Vkëë¿Ùøzø¹'†?³|f0•<¶ƒfƒÁ‚ïeæß’Ÿ38ÿtÖ?…åMgy+~†1ŸÿÆ×ß<xP8ÿ÷¬ýN­}†¹”~þ‡Ÿÿ?´ÎÂ|ÜQÍÛûh+;ýMµrë`O²ø"ìÇ¹ê<o¨§³<N¢<WÛÑE4J'ã(™ª?ªãÙd’fSµútû¸}ŽÃè<Ê¢8ŸfažGjãOõíúÃõ|N§gÙìü¼¡Ž/ãé?¢l&ý[Ÿô~8ŽZü³©¼_vfÓašÉ—ÇÓh&ê f£X­¦Q^W9}ÖJé³ŸÊ´zézwûñÔô^ÙóéÖ0LÎ£þÓ+ÞþípjÇvàÜä(ºˆó8MJMôÜìp–MÒ<bHOgÔq/‹'S5MÕyÿ#'°´¤)^¡
s•EÓY¢zi?ÂH§Q®gs2„sÌü6ãdt¥fyÔWƒ4SQrgiB‡
‡3LgSuòj»	CÃW4ï+Œ†À†Óé$ßl·Ï¡åìw§Í;–#‰Çáwã^”è%<?ÜmÞo­ýÛ­÷^ÚqÔÇQàÏ<ŠÌ
6‚wSÁ²áÌ®hQôÍ(=§Ó·~‡Sl	ÿëÑQäíÙ¤–ßúd›j¨`:ŽÿÁC~
´èÝ»ƒ—Û§G'§ÛûWÞ;m6k€AÓs¼…­4;¯]ÓºI_¥ƒ[˜G@à¶áºÌFSõ*Í¢ü¼êïì?®]¬·6Zµ`û sxØÝß~\;9zÙ­©þÜ\ÏFt¿„“I„xzpÜ}\{ÖÙ=þxQvWn×ñÖÑÎáÉé~g¯ûxe1>º£VÖêÁÉÞáéöÎQwëäàèûÇµöt<©Ñ‡Ïvvaô•÷^ƒë¶ß½µ²RŽO:G'§/ºíîÑãý…ä*„ó†³[yïŒ~­V_E¡úÊ{ÙÃë:£ûÊ½Z°×ÙÙílouÃÝü÷4á‚¶zÃ {ttpôx-pÑâÓ“Á=›%=Ä¬OÁw»Wp óR/óð<Z­«÷EZ»ç“QxÅnytD'ƒ…„ÔôÑvº—Ÿ«ÚÎþ³µÉ7Š‡üCsx‘©f¬¾Ã+¾³8±¿Õ}¢šÛê;+úÛûðûOüû!\ùË4ë?ä¢~¬D©æ°
Ùipµ:Ef1fÍé~QÕ½â¦ÌéžUuï£Þ["ÎY4Å="Ns 8ë¶?}/}7U/y¼gQÀ^˜Àj²9à*·î)|¢&òÑ’9½KÇ‚?ð‰Ú]Õo7='òÿýîÁs¤×Ü.¨àÃõkÕ<Ÿª5õã#ä÷I —¹5ŠÂ¤“ôÿcüŒÚ­¼ß¸¦¯£ð^Ý®@ñªû¯)ú|×Á­3¼Ê«µÇˆÅ4jI€O>×U§]_­ïi;û‡/O€S®µyïº
	édßðm¤@ÒÍ®à2$çê,‚ú¼·= ×°åêdˆj€Œ 0«P% 9ë$âÛPÀÜÌ™ÔàU«+u²³×=<Ú;Æ‚bˆªýÛWß7¿7¿êŸ~õbó«½Í¯ŽkõGœ®GGó»&K:wÞ1îÁ_qToÜZÍmp¿÷´*~t§({öÔˆ¡!_×Ôc%b@ñ2è¦Z\XÔ–ÆèSloçh€—¨¦~ž‚ôØûhzz÷j1Ó®”þ5Æƒ©ùërˆ÷žfÃþæKsí§Þº2;­Â‡KWW¹ÂÅà¼¦ÎJË«í§IT¦M·xlOžT­é7¶ûÕ“¼ùæ}úlH¤ËP(REÒMÔldp€zSô.ž~áhã«žd÷„$¯#96Í×ê†ç"uN[’ž]rµî4Š
Í»°LµRn©× "Ÿ«pœÎ’ÄÃì|†*sÞRÇp¹fÄÖ¼÷ÒåÐ)£–;ÄÆM‡Ð€Õ*²öúMá?\
ß•JHl I?I§t¨9²3Ò#O:O¯u¶v»Fº9}Ú9.llôÒQ©“GSì}^„ñ¥Go=ëëË o¥³QŸ LÓYoÈ®ËÛö 3JÃ¾z³òþÅ G»¥'é‚»¿t½Ç)pû.kèXXÔwû?XÚ¿›e°C8>I~÷¥«áîtºÙ,IP~Q/ÃÄ·ñàú¹#¢;P …ü`äYò6I/Õ7búôjÂç×€;Ð°ZÀð&~ø½8ÏIx+òî¥¹	ú.ÎKöÂuDK’ˆ©îØ²Q$Ë$ª¯R¹…æÖyøüð†GwùÈ9&¤…¥xCÀìh«Ý£E+ÊÐ.toÃ_mhŸWÚ×¼ù/=9ž? <ÞìJòTnµÞ'C.\°úS½ cýe–OÕe˜$¡ÊAó†£Qê˜?/%˜/EiFs$Õ&6Ö&žëÛòçtÓP"T˜Z™®V¬ÊÆÈ'í~tÑNf£‘irŠ@¥³¾¾ßj¡±îPš…=øàéìÜ…Žv)´Ö6¹ç½žtÕ0n[3ª;;FVBûˆÕñàÙíØ„Ø¼´“ÄÓ8}º 1Ê^w’Y ,\TTU³«@ƒºƒ¾ È˜0ÀfEÞQÂˆVU«²ì)êëFSÄ@eÍÜa`3}âáó§«~þ¾ùƒjö_»ôF]_ƒÑp¬]Ü¤Ž« h)
Üý^8j‹£šµòa‘Ä¨c@çý(ú±˜A‘Ñ@
¿j
ãØF}ƒÀ®#ÖæûV¸öp’%Ê?Ãý/”'Õÿˆ‡t©jŽÍÅ[|Áê˜óðweÝÐÑõ{$(“xÌÛÆ¸+ËàöÂø“îO³p¢jÞÂ¬ÕÐ6B³`×[4Ð'ÞP˜ÈvÁß¹‚3R½H©	ù(Œ³ª&ûÂ²,Þ¶óhšN iýþ“,ÅË‡Ü[¤‹îð$Ì ¦hÇc=Nz«áE¼¹½ùÓfw3CéÙ¨s¬À'®b0¬‹¥sÍaõ‚~á|×ÕÞ•‹Èˆ¦‡°5Ï=Æ¼íØ.9§ÅOº…kjœÓ6««£îáîÎVç„<#ÅYuë>VVCù³^ì†Z¹ç²/Ò-­ð×‡£Dá
[P¸Úr°(Ý»BÆMh„Xh„z¢Ì=†;ýÇõ ±×båÏ0Òä'!c™#KÇŠa
’¾7í«ôIoçªÒ`Z’¦/ÕÌx±\}Á=9!ès„ÄÇÎf>õ‘m0¾¦Ó“ï¡,,ÕÎê÷þ”v`§ñàª,• 1ÇrØÐe‡r3)b¸à\Ülþu³Y«´Ò_;¼›¢»º•÷‡¯·eÛ®-;þƒ0ärŸë2Sö	áý2JûEÞ[>È£Y¢…0 ð1»x¹¨¿´n6Ù-ßdq}Ÿ$iàx2¥ß³teÓ8Êqæðï]Øö>,‡?v×¨*§ÈÅ¸VO|´†;†óî™œqÅeÃ5ò\ãÍÂKWÞæu¯‹pdÐ°ÿ
ðövèÏm„}øà‡!C ‡—6”§f¬îæí¿­´›í»îU‘Þ?¥ÀAŸ†½·ÐGíl³b<Mã	º1ÊÅÕ> 4·iônŠÊÍJûýþ£¼ý&i«ö£ëc ïsZ:Àß¤å¦¸ò§4Z"2çôh„õ]Ýuú8Ê.@÷D¬=.žáê9Èù0³žº[j&~è¨ïÍ£®é_á¬AUðæQmõIñZQf, EOS›žU¥‡¢J‡h›dš{¡Œjðîvçþsìzýc:Vvå}ì¨f×==@'ÒjxùVÝ}Ú}¾³ÿþèøqíMÒ|zî3úµöhçùþÐK`{×±þøø!:ëÖÕ«öß:ý~çÔF–±²½ùî.Žt÷Í“¶z\]¹ÏwyIðy]à¬=R×è?zOš}æc†ª›ùz×YXq[á®WÚ¶ovŒå£\§+šäYî0“ *æH9]=kGEÇð—Sü•NÑ1C˜	CÂ¤KÈ|nžc2ÈçYD€ºøÅc¤„TUý—2R2Ð®€†ÓÙÞÛÙwyã\6öÇqr>[Í\çžå\ë-mÑÑW²ÛO8ùeæ,`iwçD®QaŸk…wi³öHþZµ½Hµk}O¾Qøo¸'ûh2áõÑ÷äáFåEù¸Ë±Q¹E>ÊoT¢<üÕÇ{‹„ý”¬_í>®a¬åf»½²:Ló)ZBê›„°¨?åãvUdÉ–c0G7UÑŒ
pea©Ù,q¤9¾Ï¬=Ï2¸ùñ@z+«þ(Í”:³øhŒœNf$%¡‹âeËbå‡ °6÷e.öHª”¤Ê»JJ‘üb,4·aQi.ŠÿÖñÿ·ùkÄÿß_ß¨ˆÿßxø%þÿ—øùÿÿ+Åÿ›÷¯ÿ/‘ß!_íŽu¥¤üKèÿ¿xè¿ºåH~õ[å¿Õ8þâÿLøµš	»¿Ý¨{õ›»ÿcì+"ü>!ì¾Þ}üD5Çê;ç\á£›‡ÙJŒýÍìËsÞr(Ú€ñÆåsz—–gzï…ñH‰Ñcn÷mõÝÓým'8ŸBéA—6\‡l¶ÌÈVûŒÿÕûõùû‡¯·QÕÔƒº>KFz³¢ýóàÔwÝÿDEë°sò‚†°S#ØÀ‰‘¿DÎ ¹7é5Ó}*Çù­ä h]êš	É-ÞÇßT€ú’ð%@}Éø’ðÏ›ð™	ô/é?7í€	çzò$eä7a…’ Ã:E	¦ð±À&ÜæˆÔ
‘šy¿Œ`ïA¯Ñ%j‚Ú<rœ¤¥YJšš	9¬DU}€?¾ppÌ“ÄÂFÀ|²$P^wŽöŠž%êþ8Ç†:_Wçv–ÚOÑ­Ž¢Ê'Qµë1û’rñ%ùaiòÃYØ{;›äÙ÷—Î‡ h‰º"}â–âþ—§'lé„,BaÈzmŠ{üàá2PÛ^_Æ~™ÅÓ¨Æ¾<£ã™‰M¢Y¸\Ù²KH˜KÎïW¯ºÌe@‰)¶é°¦RQŽß\Æ£Ó±‡µö9-¦Õ­wê¬ÜÃôRñªQ;/ ÐSÙôÀ f4y­¬^öTs¤¾sCŽë^³dT+««+Ò§I¿P^·-ºjrt4ö¸vCÆU¿SÍ–Â\ö5}1Hp™¸dýó…î«ÿÉ±ûz‹IÞø#÷FÍv÷_~ZÆÓ$c§‰Â­Ïñç'ñûêF ¿ºÝ~s	n-ˆ Î‹ÔÇ‘°TÔ$“i”©6Ñ¬d6>ƒ?(¸d$Ö'6Â#5B×ÇT£°m°y`((‰LâòxÞ‰üÜ³Ùß„;µJ'Q®õ:ü¯NÓºýàÿñf¼Ù¥€Áæ/ÿ<'d{ÿÊªÖYuÛŸÑt˜·ß4ÚoTû¼þÙrØ–3PÃépN«ÛÈ À=–’dbý4æ^`ŠU6]"Ð(k%#ø°Ðp—€â°€/q?*ÈzœÙléªáô•ÁàLZ–…ŒÏ¥¶•ñâDA„¤ð§‚		ý9vzãÓ5éÓð¬ÒŽ\èX0ð;ü­{²%´™¡UÊ:,ï†~ôº P°Ï9?Õ™ËºÙIçéãò8i7NwwŽ‘¸0e¹Pwÿvç®2èLH€ˆ 1©—™¬¯êôœ<í	íÝ›Š¥ÏóäX”}ß0³Ýîœt®Û÷0ÅÕöš%’ìbbïŸŽ<ž—<K°J§î½÷:ê= þÖÖ„­ÄD{02¾uïMûÍ*ü·þgÑº·Ò~³Þ¾[wÂ)›“Ùñr†—)Ah÷Ù!Ø:â|–G‹°Zz0¿)ÏßÒÐÂ"{f¦î6î*ø¿ºæ×’›D—Ä4â¤pB•ÐmÈ9}|M€ß$¹ÅG¢ÀÔx•tZµ¹s%hÌŒwÓt¢R§÷Ã5°?ª`S~ÁémdŽ€†_ùBÚŠ§S©
™TÊ­`—Ê&«¶mªÈVœ§³¬yñ#ª ›¢*ÿ6ž¸ûD^ÏØ«ŠE|ˆÃWWé—[wÔž^šLãdf°Qn	‘?ŒÒRº?Ü$ë©úî»µqÇöxXoD¦ÀM¼<¼FÖ—ËktÌg¥•xúm>E5Žÿ…å\ªÏÐ„m^E¦.MîAüè¬)™Ï²Vg×?C²•ÌÊ¿6êÙz‡¤k3¸&eà1ÑTÊÁÚÖußN@Mÿö7É|y8_*¦âÇª›éÌ&ˆ{Õ‡+÷b¢øzòÚr…«‚cÙ ö?¦3· é´ýöÌÝ;…”¸hïò­Ù®êB«4ißÕœ¨Rû"QB·Â[èäX½õ\.o<úÃÐÞñÎôµvhøMÂ]ðÀô­ã†I8(PZ/.·D;>u))iÊðt<;°Ýsœž¨žqÚ—è0ßÕœµº­<iF>„”¡b†Œj¹zS·þYÒÆßgGi:uµÀÆ²T@œ»?ü°y6
“·›?þx·^€˜åËþ°×.Ìº×3Nz£Y?zšÁ¾êµ÷‰ºÄÖÎî¶ßÔojíˆöÝsÛ¢Õ}èü½Ï)tÌa„–<Ètv¶íÔ®o
¶ˆ†E¼péþòmìíuÐD"–¤ýë6ƒjŽúp¯šMl (_ÿºQ¶Ì²O«ŒùîVc;œŠ *^ž¬{AN-¬ÓíðJÂîþÛW³»õBºé–‚šàmRá,‡š‘ª½IÊ-Õ“Š›éü”zTtð3…ð§2¹eñ"0ÇÁ
´(ƒÑ<~Ó†Û$%†Î¹Jþ=$±ÒLš*ET§%9ƒWH_Ý›^q±+’ZU6©¤xx¾—³Öqó'(ŠeèWÉ©P‚òA¾Ýå‡Fþ^«Q‰q®„\ÁîOÕa:^‘ë»FŸ[ªÒYàþ‚ÈòøSc2SnŽù¬‡FÃÈW0§$Î‡QnŒJuDÊËvýô2i€P®ïù¢ÎŒ'Í¸Ïad1–iISsieŠõ9l²îßjöÒâü¥/?Ÿö£ó¿XQüUò¿6¾ÙxXÌÿÚxøõ—ü¯_âçKþ×¯”ÿe.Ü¿Jþ—˜š¾ä}ÉÿúÎÿR¿§\>Ú¦a/wwo¼
^‰>­§LNÐþý×n÷ðñƒ#Àö9( Öô:ŠÞæHdÞFÑ$€Û=AEèq­ÙÔ¿ß`žlá´]Ô³Qxþ%áíŸ:ámª¾C\ýJ}3¹Zª³»;/Ì,Ûü8Ná½EKýÎþÖQw¯»ÒÙµPñËy`ßªï^w»=¶pí¼t¯ JG}Kk@?˜÷óöê»§­¿¾<¼QÎ[qZ:çA|Éyûmä¼}y÷æKÎñ%çíKÎÛ—œ7¢‘_rÞ¾ä¼}Éyû’óö%çíKÎÛ—œ·/9o_rÞ¾ä¼}Éyû<9o·ñö%ßóÝ¦›o7ãÍñæ`³û9òÝ¦uÅž‰Ê|°·uE®†êo‰\9ÊncKì/”Ý*âq8âÇÅI<ÆM@¸®¢óü-·úÑüîºðJmÚú—¬°/Ya_²Âþu³ÂœL ›d…Inô¢<&-q)x$	Žƒ© Ä%€(²„#tÒ::R€×¨¦wÄq6ÌÑ­6¥ê¡vD)æŸÁ~÷õ)z¬ö+ùKév·í«+ïmÃë¦PA`‚ø©¸…Ž»€|<è)
”×K}…Æêˆ±£€}8Ä¢Îv
ýCÚ.­‰êO"Ìå;ðõr`œl{–Kl@vgHý%ýúù…²þŽ	òHœ—:÷qé²ÿ	‚%êú%ñm^â›u:Sâ›•Mâ›m¡Ÿˆs1åÃÒÞ\X7I{sÚß<íÍéä¾KioKçRöV}iÚ› ±ŽÇ2m+3Ýœ><Ó­,wÚ»Œw(„ÙõñMœ¨ïP`«[ÌÝÿv‰®Ô‰”ÁØ9/KsH½,ø×ë#š÷È•´p(“Àd¾U	`†<¥:rKò²´ôpWà[q“Y¯¼÷çâzwÜ«b«rò£Ÿ1Uê±4ÇÊÏ¯rOB}m¥É >¯ K¥Wèi—	š¨=@Õ<üGïbp“n»™o<Bkzþ¦[ûÏæl¦3de¶Zq+Ýöó›Wo™~ýWãå¼×¿ªö¬Øõö7ß©ç-sl„°0Õ$¾=¨ÿ:;¸8¥¤
ç²ÏÏê[šÑçœ˜äó	ÜB>ßÍsùæIO+©Ý¥ì}zºÞ§êýiz7KÑ“ýûè½›§çÍóªWlBå¡ÎËÀ+œeg6M1ð¾B3R–ûîæî¡€‡KÖ5
†¬8Éj6TP«>âpØL`£.If½ÉXZaö´½ò™gcÕÌªÉU¢×õ³&÷Sw	ƒt(»ŠFÊò¼Ë“.¤ü:ø£Ýeóm’2)³»ý”Éµ_,eòò¿¼'Ï?SŽÙâü¿¯|ý`½ÿwÿÁƒ_òÿ~‰Ÿ/ù¿Nþ_¸òÜ?6¥Q1Á×f”‚iíKào;PR ìF¿
³#¡>.
¡s)02]p6Uñ4/Ì åòa­ÛŽ¬-¥þ‰©ïÅyUÌ¶:ëíu¨§ emtd²ÕP‡?~qz|ðòh«ûÃÚ×µzM=R“Ë>¨{ð+\æ³<Í¦ÛAöbÌØ¯QÜS¢iÀò%Ž’ÛÝg—»ø|ñ6×³!'Öè‘çš×F¤&§K0~+Ï¡'í¿«Óôxïtû ÄvoÜ~Š7ÓoÚÁVg×mEUyæ¶y
 e‚Å58­ÐïÉ­¢ion+TLô˜çs[t÷w;'Ýci;Æ
®°=¶_n¸«˜diÖ›:PÙ'ŠFÒd0¾\<j­·€x”>Û{½ 1ÛBŽºdÙyþ¸ÆÜà´¿…F“ZPˆ“{l”€œ_\¾à$®ç­áúÚEJgÅ›~××ÄŸ†ó×fÓ	€º¾QóŠ¥9=Öc–†˜×–öØÂZ²1µ °ö~D5<	mÐ‡ƒàÂRŽAMÓMebvÁX‰i“ÅãDÆ'$î|Þª§3¤cz@½õ€ƒ]Ëƒä¶L­¥Íéqic3ÇÕ1SÞ~ 50˜ÐÝaŒ%xlÃ
ØmáGíÚ?ŽóÃÕAs Yz&0íÆ!ÂÑþÖè ŽêaŒ¡€=v)Ü"í, öˆæcßº±x™äúà}BËàýÏ¯ Óþaè»=ÄHÜªó°TÍÞRü«tÆÎÀ%réÍª@'Ýåú”Ñ¨?ùÔA=šëü—Î«ŽÒüþƒý^„¼µH9
Î[ÝÏ÷Û>&Ÿ­žDá»¢“—¦SW¢M·"¢·ù;^•ÊøNNN¾G§…¬žù))FïQþHb‹£wQoFÓh©4IÐÂ¸íUù•ì‚¿ñhc +i!ÊkN
FVÊ®ì¶£‘½9U%Á¼™“ÃóË¢é,KÔº03Gs¡PuÙÝÌÔ|)¾ûª‰yÎƒãÌªgvïéÙ4Â„ÐCkª]iÇà˜"Ž*Ó Îò©ƒ[)Œœ]ÆÀš²¡ÇS)¨…Q‘‘I“´´ºóª»}ŠÀñŸk'Ž‰áx­ÊF^% üÆNDº#ž Fˆ˜r°ÏT¯`/°àær|1‹#.F4q˜H­j:Hü†Ò¾¯]:^ñƒ%$³Õ“©â¬8—% ìTxÿa“Ùµ?–Ü%—yº¡’ž`r­J¢ÇµªðCÛ©œ }/å	Ä×llÆK'áÂÕÅËõ·³bã‘‚#¾RafY8fî ¶NõnÎ¡´BB©û‘ù}ž™)z…µm¤*N¸L7{:ÜaNøêÚMNŒFt7Ô3Ñ6@u”§œ’”§ƒ)o¾•xNWÐP¼º•-ÍªØPùÂ{\š¾&`ìÎ±¤áõˆùÑÓKc ‹ÓkÉs––|onîLPâ¦Í¼L”Ü†tb”¶ŒJ±¦V%váióxÈ¡¢ñdzå…©"hËr0E¡1QÅ‹Fö‚¥¸¦¼*îËãVÂ €0¹òahRE]âVCÈkU4O }JùÙ²ÀñÂ!¨O$w0C,”úqƒÜ±nš}†½c™ƒ‘ßÁ¦hªæ8Ê+ÆUÃ]L(¸7”ƒÚ
.+1ùV0pöUd1ðîƒqn¾}8®},žÝ6Ž~i)ãÖ#ÿ]Ù1Ì§þIÂ>£P¤XóðïŽâª¡TQ[ÚùÝN²»=ü¢ Žx‚Ö{¾*à<‡VÛ3¥Ë
;:sP€©˜ú	än’×ÌN¬W-¿b2–çX¬ñ~4D¡;¾ú¬V±eâúµNp;¹’¿é¢v¦†	†rH4ùû¢¿ò'LïKÅ+7Q.ÍDäÛö«áU„º3YÞÞ9:Õ5PÒ·^u•ù œrû+=Ù›Âvø¨ÍšüÃo”cæÑÿügËÿôgÚÇT˜ÚÐ±hŽÛÇÝîMf)3ìÃáü’ÓC›éLO6ðÝxt{tÅ
Ä®«Qkæ Æ%ÓšfVÐ«¯¤æ2RDRGá3ÝÓ,ì¢S²ðVál6 ˆìŽF-rR€Ìž?ç]Fo)2Æ>ð¬6K!‚•^àtWWì.×K=ù¬”×ÿ€K½•3 5KÏï˜©†´ç!¯ox'‹2ƒÞÝîªC$ÏÊ™
¦ˆepjzì·•¦§ÇÇ»¥æô W7'cD©ÃQ4Åâå‘nºÃQ÷ðîõ/²Ò]aW[tàosJG‘RîT0&d³Ývœü›4$ê®ù¸4Ç''‡Êÿ™·lz\ÙÔ.G‡&ÞÊÝ"óù§ñ~|Ö9›”Ù¦Ë1…µ¦m‘°9¤ŸqòŽáÑsÞyÚb)©‚Ûìl¾i‚·¼VÜsovªYþ¬ôgÕOÍW>ææ;âÏm.H‡‰“yŒtØ´±wv¾­B¿]EÖ¢Ÿ±"„j®;eÔ=phÃ„üñÀî×]Né¹¾>ä×óA~˜7MC©LB„Áí87&DžYÂcP¢2ú¾ÚëöJ¼ f\€¢Šëp¡'YœLêîWÍ‡¹úª¹¾ÿýš~}€ÿÍQU,¯HL‘Â÷Ôo:µ•ÕŸÒ89=»Rmh„Èq-ÿ"’˜ß	‘¯ëT€ÄgÒŽêkïåç¤fÎ‰¾WE’v.²V ÌÝlëz'Bé>QÓ
D¨ªéð#Áž,Ç¼y¬xe•û­N@E‹êg™ËÆñ-»ßøgŒ?ôUš·Rt-å­<Ê.¢¬EQI¦bÚ1}øóœÞÍæ8k¼Vu_îDLœæ~w6¹ûˆ®‚üÑøðÉ ®ª€r»’äÍ|Nú¿¹uWS¡[[÷å(ÿõÎ»äQOÚ¡‘©àžx·ÝU„JBŒ¹ñX62Ÿ¤ì8u´«éÅ|†»ÿ¡wú˜´¹Ç+ë>?jfTW±«æN¤ºKÿî¦à<0N¶“£\ÍMlòBL<­ßùÏ±™¢ ´5•aÅßX-% t$Ábh©ÃQ„æïè*PñttEæU§S9ªÕæüYZÑ®æ—\I9·ŠfPŠóQófk©ÖÕ«õtg|é?£ÀÀæ–Ö>þ9È†3þƒa‰æ¬0”Ê-Û«Š¶*ýãi<è1i&ên›,dÖ ô®G&	‰íFûo+íÉ]=£(ôófopÞDoS”Ð°¢- 3ÄÓgôÈ¥1eï¥ßæh¢Ay#æ!º‡FÃ2 2kÿ‘§re 4ÜR7G¦_ˆ:#Þœ^¥³Œ/së&ðŽ¦ô=þb³X0R+/§½P~…´i/T‘žº—ÂQ¥@} ?ŽÆê´—–Ðfýþ·ªnÃh5lûõý¯ç´%Ìy¯…¶ßþÉƒûñ”þÓh`Å+ÇeÃò«r¡WÑPY2ëÚº–ÊJƒ¬Ó¾h”c‘uz­²%“ìçÙÅ_‚›r–Ú©ÀJ•¿¦ë‰ñ;¿>Ë´Ü_\(îWªT&dsM[š˜^öŠxZ§Zºëeƒ¶þ!î«Z»Ð±Ý{ó¦ð[µ7žn:¸ipksÅß–š»¶å8#cØïWÂu%*Ù~·4ã'OæÍ¹Lµ?³Ø˜œš’ö’cesb|âã-Ïç÷»Qr>²Ai}í:ø}ðû;jŒ/&å³,j`Ý
aYz#êa¢­‡€ýº¾ÅÌ6á>ÈƒßË]â¸pìs~¯G~ü6š†Å*UK§ÓàrÁÓlyÆòü1—„¡4‚YœØ÷ÏÐÄ“žªušÿWØüÇZóO5øS%±Ê˜ÓÏŠ­Å‰Z÷m·8ñ;9>U9ÍÿøG@ÄœøÖ½ ô÷ü`¨âG04|¤~\ðNî#âHÄo‹¸HÐÏëÃF£
/Žü@Mt¶—[ñv§eØV!ô£ Õm4¶`»û¯>-QÙ‚éåñÉÁæQ±%úyHãÞLÚáµíäÓ%ÛÉÿ¼ÐÉÄï:?ÀàOoNÑÌÍñóBsÏ«à4÷>¿…>6¿ÃŸ–ù¼Ð^ÇÄ—¡?/4w³WÝæÎçÕ=tÒX±‡þ¼yºÝ-÷ó–òØ7]Gr8ž×Ãù¼ÜÅwÙ.þç†*ô;]t:%M®ª_ÅÒC«ÂÏcqU4eÆ^nÊŸWu î_?¯j"DesøÜkîRýäkg‡ùÇÑ;© ÌÕúJ§l„XŽ35Äy.-Ú HE}“ÃñfÅAØ¶äÒkØ$k\öÍêžÏ•.Ôª+—Ô©ÿôésJ²²ñA09íÃLh[ïÖ ˜¨ œ—v…OgnozÿÓ‹! “´L¤‰%ÈªÆjæAb6'?úË;c>ç€ú ròãƒ°QE¡í!/*WM“˜T½µtÖ¹EDV0òR²F!§*u±—Ùþ4äEˆ,—‘¯ÉN|v¿Ûa”¥ eª*6u\:º‘QÁ@ü¢N BQ[’ TA„êìîtÌÔž"©aL¯¶îÕ¯Þ­Áÿý\«·îQ8µ²’V1¤ôÒ¹0Vï Œ•ŸWJÀÔWÚo6Úw+ ¼—ß6›äp²ñ­ÃñB¶xÓk^®•÷´¨¢jüµ„’!{bbç>ÿ¬šöø—ÝçoT˜e€îÑˆê¯~G9WaØy†ot¬×ñ+Œ´°}>ùŒ‹Ï€r`dä\_ 4§ñ…­òß:á·Ï°HUŒ^÷OÂfä|¼áD`±·Ó\KgUõº OÒ{¡³žÜ²àáheæO“#ìàµ7Âto6¡B§[šÒV:§É!³Ç+þ’ïj”¤—Ôî(ÊA8x\«9Ÿ;ó‡ªuÝY±ÐeUkÿñÇB¼X’‚Ê>íj…IÎJ{8HLæ²ÅôSÌ]žAt`œ§ø\(“VCS«YÔŸõ¼ÎÉ³›à9rfïäEÝ!V£¡˜A3ÃÇÞ;¢ÌÓ`Ž ŸelsñV4tèþÌšÿP+¼¥Õº´ÞîVkAx”mÔ`%ë&gOÚq5Ñy´kåñï°¨¥Ïâig)lò*œ‹Ù¾éÐnŸž‡L¢mz àb´PÃ6ÒpeØú”QØ£h¥!}°¾5VÂ¯“4i:M¨Å³4»³¾œÙbÌÓóÀƒÃ)äÓëÉF_r‡¾C¹-r>‰s>&ÏŸ9Ã–7®°nc7„åÐ»2ÍB•°¸åG…£ò8ï ›ë>#¡ñâ¶ŸÍ»å'ÃÜgÞ´Ëô†‰²ú}€x é¿fQŽEç½T¨èˆÙ¹$2ëdÙ[7VsÖY]zò÷¼§—¤øéñÉÑMÂA½9èÀÐº®”ùÞäÚ}­.»¤CuXì’N÷´Ç{I·B,¯xs—tz¸ ÔvI×[©-`"¦ùlq¢â‹š7÷Ü`aÈì<áÇ„Ø-¸ì;à9Í½”Š`"È…´úÀ¯lQ0pº}çyÕÜ/Ä·fz-HMÒ¡Î4Í©¤ÞÊªk+~ØPu4›óÈ«ãôžç4Ÿï Ÿç:/~îc’Ã*=‹Ï´]‰ïw¼’e{Ÿ!ü5æàCUU³òßÒ®|…BÍ¬y¨<ÃÛÆ¬’Û×¨L½+, äÌäÐøM'4~Óß´ÖKü½HFñá~Õ[ÕYâuUqÁ³À‹ùýiÁ=øø[0äY”
ßF‘}ÓBr`CÛŠQs‹üƒ´±>B…ª¼zÊ< àãWmB1sÀí–u:YÛKC&Íÿ®åoçnýêWã©õ¯‚µŸQQ3„Ôíœè—m©
DS*SI‰Jü:¼ôÊ—×&¥¾ÖxO«;ØjJKÍU,åwƒNm^ÀÇõÅê½Õ‹—:êÊ7ÞÓr™¤VQ´ýýÆ[Ì(x«&@~Ðgù4½ño”}ÍŸ
ô|–È@/2µO…nS¹«ó¿?jgn’&®>zg~Ýs_VÛWvC ~1BTï±Vað!:Z©æáÒp¦<õæÜã³8Ùô×´é›”ïuÆÓín}Â·7ÙrŽÛ¯¾»ƒX9õ­ÝZyäÒ–T€,¢
–Vå‡UÆS·¬i±êµia¹k·MÆK±Àá§Ì¦ kÙ¤ŠÍMR4{âC<É|:lBª<87åê'P0
Ù<· à’--·s*U—ü’©ÎíïS¦@ËÑs·JŸÙßîYÅù‹ò/FF´¦ï¦Õ÷ãõ6¿ÿùÁàJ¥–PvÉº1®vÁÞÏ÷çWïøÕÕç£w<ýfîn†Äs›ëÓ´3øÎÝ´'7žÆkñd*;Ù-_y5§¯ÉB½æk\3«²À¡ôñ¼Ç ‹$xîwÌ”ÜúS^Ág~ÿ©ŸöÚŸyˆ%ïñ{Yòþ×ƒû6ÔÚúúÃ¯7~§~î‰áÏÿð÷¿ðüww¶ºûÇÝÏ6=òö`Îù¯¯=x¸~¿pþ¿¹ÿåý·_âGUü<ß©žw÷»G]uøò) ‡)E4ÉÏ+	x»ßPR™%‘Ú€Ã&WY|>œªÕ­:}¨žeQ¤ŽÓÁôëS?ÃW )ªT¶×RßIÅ¦A>h¥ÙyûI ºQv…aqŽï1Žã)÷¦è™Ÿ\‘ðÓÇÔÑøçÐöà¡°7ÁŠÝt	=Güð—”Ÿ!©o(hÏñy6›ÀŠp4J/£~+˜·\ú9Ì¢p¶:ù†v¢2Gêpv£é§Æn‚^5hÆ£ˆjPówÀo‚\o.…*Õ«·qÒ§0D™Þæ-=ˆôÊå©0|Ý´Üw‚éXŸ;Sð~”ÇçXžßºÁÔð2¼âüGœf\ „9Ô8l‘7žRO¯ÐÜ‡èMÁtéŠãd%}>§óY˜…ðwT1(ˆ
?Ië±,ËyŽ›Íij³Z=¦FR8»‡ô; A³Þ,H0õ×”-@½×L¬ÉlyŠÅ 3³óp.ád2ŠQÇJã°.¬ÃÌ§Û‡AK	º„‰¸õgW4ÃžÿÃ9~ŸÎ0Þ‡ áw…vKÖŸÃÒ”0á5úßñYáI¾Åéà˜ù4ð+\_†oãQH0'æ=Ç'N§Á$‹1)V øêÕúX£¼­§  ˜Z@a-¸¯
97‘/`i~jUŽŸØEôc”¤ºŒóa½a†À˜£CíDîì¥ýˆ^†)kŸ.-u.CŒÕ:]±ƒÆfxèŽ§sëñìH‚Ž€æi÷›C’Ü[Œ¢ÑpûðJ8ƒ•Cù~¦ØuŠ!PtnDör:$â=œdÑI#fˆ¤ý+<#\ÃäŽ8Ï0+_Ñí$«7¿D¬[µˆ.ÀI§xðØ%èEÙ4¤`9¬YÇgñ(žÆüØ6ª<%w—8|<@¤ïÇDÉÍ2<˜~†‹v¯­‘væ¾ý÷.OF wÑòYoho<lÝc”Î±, íÝn5ˆd±cLmBÍ5HyÆP&€É4ç…ã(yå%ÄêËÍ#@Ç7èÒ5tëÀA=Þ-ƒ• §èb&•]³Q€oå*§)^„Lð[¬Ñ„öIÞ0EÔ 	QbB{¸[…^z7½LñÐI¾¬®×>qšM‰×0ïÅÍñ1{u£{$‚ñ	“\þà<¾Ðx7ŠÎ8×Í‰ÇÛm¸'àÚDQÌ©si½ª»l¨`’wW/‡è/-–Ø:™ýÃD}$î>‰,böÄ3C^rE¨@³ö¨K‹>ôcòOƒfÐÎØ‡®Â8‹d¿Çòh§e@g Eö–jGÊßàSäiÅDŸAçüd´¼VNeoúä»J¢t–®ˆ3ðLÝ‘Äð…öí˜ì‚ozT©¯K…ô¬9~(…zð~d³$(/£p¹±CÜ'Ü‚KŽð]Õó!5‡Él â\‚,J—§De§Ãf#ÏDñ	ßÞ@³—M9ŒŠ $Œ‘ú|“ä$>QA™™–©ü
P™ž÷	 2Ü›Ä’†3¼i¯7ËÈgGƒÆ›IÏ6²hÒ pì÷z!1‰{6<A
‘G0ýKÆ+~zYû,Á]LÑ4å“ÖËˆÙ=Üé!Œ(Ed>‰»Kc‘àk
×KOµEé´2ƒDa†å³348`ínÚe‘%äNš~ß§¤*é½Cq‹gÀä™Y"‰)	½,+¨ÁO× G`çÞÀ
éÈ«4·brS ì,TÑœ_CE( k²›9’÷	dFZÊˆdƒ‚üéß(ÛGÛIþÖ„ÃÀmêM5)!C®ž°a`e?NÊFq¦9áÈ}S›å,îÒ¤¹Pø~Jì…ºšiÌÁ¹:¸Hšqc=!õh‡Xª7§÷ªâ"hSÚÚÃ<mÈ\¨šW-‘XÀó²ä÷LS£@·Pˆ
=‹Lûa¤ =4†ã\Œ¦ H.|‡$.,^ÄA°z\k‚r‡CÇ%eIè‡yOc¾.tÒ=Ú;Vým,4´½s²s°Œ×Z˜\'<"õ¯8<¦Æâ)¯¾E÷Í=š+…3 £UÖXàæyÃïš£ø-¾p)tEjÈ×­ÒlBZ £qŒ›4CÏ PÂü­™wêm´;m”ñÍ˜dÌ&Y_t4ÀN9¥8ôì•ê†0˜4aÍ°ß‡#Ïùy‚°Ü´ªI‡(¯Ñ‘Ô¬PSƒ™]!6¸4æºr˜H¡#Ö˜%ž›äˆæÌÑÆ PõÃ	];üƒRä°O€	?jæCNŽA†‰$ÝJV8hÈS%f'$À¢— öX*JŸQœ66 ÉÅ9gpÀNÈÄ&V“9(ÄZ¯"i~«iGBv[ÑftT­—,hƒŸÕd+¢X&·+1cÊa;à	z r”|m6owxNAÅ}îš–Àü‘¸B8mèçÌw÷.‰a½T€º0<BÔî ŽØu‚ºSœð4(KŽèSZØ3‚Ë dúò6ý*Û<ðÎšH*#Äá·(ˆÇœ}Bgv(ëDD Î?š34t$ðèÈ*-ÀéWÛ]¢
ž †yhP„÷`B·T@<z³‹^ŒÌHE ÃB~zÁê\™Ëh42'{tÑï)Þy‘Ìˆ6D	»Ðt€È/jJT¢²–»°G2CÛrÂçC_DÆ‡²TÆuŠ“ièZPj
òk>à×/C¦MNÎßk#œMì8@€„éŠ@4:æ/xT»$¯ï§(räµ@t"’óXÝ•ÃyÄ$Ö á‹Ä®Q†@× X¹QŠP¿0#³¹ÂŒmÑ-¡ñžLáX“]Z,Ô%]„Üp!b‘Iâ±E›4Í‰Xò®‚k	³f+<SRÙ€aü$Œ1Z¾38²]ŸÃ_”$ÁÀ¼~F‹Äì8œô„È²å5a 7vÖ`e—wí ‰¤Ò¢>E¤Ä"aÌàÛ`b¬·”¸®¶PõÔ<¿æè£5Q•]rÄb…0³¢]:Oö-¾–îeecŠLéàì§ˆ(8‚·wey¹U=Â{Œ¢j˜õÕŽÞ4ÛÝÙH¾LcúÔÓå0v‚~ƒDÉÒÎçá›\Ò T¶´…Ö‹†ÞJJènoÊ'x“èÚ÷f£ÐXÛÆ¸#þfá9Cž^€Ö;@´Ñcá8Å"­ÞŽË&Ê*äEƒ°gtLê ÔY"Q«1wªlÅ¹£†}oo¥VˆJ Æ¤#]çg5¬³õ•z÷õ&$p0@ä|€ÎõÞ†çLä÷ÂŸ`¶€\¥‰1‹e	©’	` j8ÍéŽŸÕFCËZLXED·%¶²4.^}@54±„¯ÊˆCÆ“‰Â´ž”—Šb†Â¼ÄšqÐbÔ
³¨	Úà•KaÐwSÂåÀ¦(«‘bFž:«oAKFHâ“>&ÛÑóÖ€x
Ï¨àŒy=…èæÆÖk†³®#Gæ2áö±ôû¼Ár	¢L«¢VZ£=·ƒ[d¯-ß6 SÛaj›aè–Wë”	GNb&!•lÒhcŽB©ëB5´ÅBgÀó´k%2]§‰!4w0²É¦ÚÔd—ÊOû	´rBŠc@þŠt$*Ÿ•àè_¤—¨µ6š``}ç4Ø»yP¼®´©E%sš¦,„Ëp,"’{B•5îf¢Í9B'ì*àn&™ìSÆ[ØÎþµäÙ¶
–Öªsëw	£§q}
TCÓrô>_W9MþR,ö²íRµ£x¹Ø“„ÏÊ¶±—î*	Çüjs€o°"Ýž™­1uÊ´6 /m¨k³]#Ðì½)p)ÇôDn8¥Ë1ž%Z‰%u—Qa€¶…3Éði86Ç¸sp¼h¡T61Û«/HÕ¾²‰ßÅ!#ökSn–“A-‹ly4÷kÑÆÊc{Ã<Üâ¹øWµH÷Ø>-ãve-LÿÊthV#; Š±ùœ¼xý
ŠR­…8´= ·)¢µŸìÁ(Â*.RVZ´,Çx…Ö¡~àØ.èQãhªM’z|§²kR=ÈL>KFñ8F¾[Ó–²Ö'Ê)(- ¿ó©@ã„˜eàê¤°ÊßgWþv”|†ÔPç Ä#¥Í‰.Ë#ãX<ME·À‹ë†¤— ŸG¼²@»‰ œÇìÓBI“ïÇE8bþœÛ-=»òuB:`ò€˜<&Ó8nŒh¬ÔzÓr<( Ú¢/‘…k£Ïºf¦_Åm“³Ð>o÷1v2K¢†|’z6"´OïLpŒ^|:Œ¦ÌaxÁ—ˆ6©p¾,Åh–³QAÀ¼ˆ¢Ë±+iPFíã°]=±dYG¦jŸ#ðd´+„@ß€¼¨D(.WÌŠ™]ne1ËgÂ!x‡Q
‰t™“#Ü`#æ,76w’…Cd©ìš"“¾·p%è€Î¢a84ä~ÓGlƒ€½Ä†ˆSiÐE¦µ±iÔ1xùÊhŸmdìßc¶YFÔ·ÌÑ.	ô‰Q…8¯a<a=	W·Ì¾‰±ÃøÙ{qÖ›u5)/Rq%vìðæX%+G+§RÇ$.Â)‘ïÅƒ<B±“õ52òæ(;Ì° 7È„hÙÅ	Þo!Ñ~—ì÷`¥üˆ/ì3Üžp«æMíÀuW®ã~ê²R@‘3äÓ ëöÛG‰I›˜á0zÃ$¥çÈL@·Éi÷È1
ÁµWƒÙ¸ùˆð|.·CÚ£2BØúºfA¯wÂ1Eã>ÀìƒZËÁ»kj¶a|Ý×ÿô§¯ñN9^T©È«QD£ª˜ôÉ’èmƒøzôrñÀŒ¨‚O+Ù|âFàbÅg	‡F ÿY<¤8Œ·gJ§|“	I^WÔyã™ ‚ØšõbB!Éì‘ØxÊÓ xE™Šc¼7B®„‚h¦Â²ˆ‘iÅ¤ßTïªY¤²LG	RWR"¤£ðíŠ¸$›4øº³O5c,ƒ[{W6SVfv³thAõnÒé=h9÷ö•ŽÏÚbƒšËät!\zaÂŸïæžHÃÌ%Ðf:A‹5l\–x6®&ÓI>…Ÿ²ä¶f,t× È‡ˆÙÚë%Îl¡±ëQ@©‰pbhåÙL>\$1Fô…&~±=@ŠO.ŒÏ¦/ú{Ø£º;,Š	úÆ:5•ú& ûžæÚ‹˜v\›Û#šÆ9]Pßœð‰j´Jµ5»h7ÉÑ=8Å)ªž$¿#3²Ûê

¾‡ãòÙ„âï‘9jC¡°1!4…‡.²íiÙN$ãW®£½€u®¥¿$¨Š´Q4Œ;IÑë$¶ms±V“ˆ(0"‚>ÚU+n®HÜ4t ¹ËÈ6ÙCÖIxe«2ûlØ•cd¬DJå£ß'ˆÅ®# !°]`ˆV£oàÙGEÞvêo‚âªÔ	¾.§æûÀme¯Ì7ZT­lG²6zº_ B¤7!Ôæ\œš,´W·1BZ†%Ä/3š°c‰s<Ø_/Š}†hK„v(+²÷"Íó(×‘¡õ‘ P„ÉT%0	h¸÷±Àêµ`ÜèóVy&¤khêA³vÙ‡(fEIÚhCŽì<Ìú#Œ;AY›ƒ˜®ØO&E
¨ò$,(GQ_s÷Rk«Nàdx%>{k¡aäL@µá²h;aJpEjä>öNô\{i3—Rýº®lIãcñó]-°SD¯ÆN!m‚2×ñò÷FìKó*Ž$2–i	Kà·M¤®èÜQ˜gZ…±AâC²8‡ï°ž†FVðe(ÆÞy½sâ…ëGø$ Ú9EïñÍP¤ú¢Ôž°›ˆ'/îÈtˆ¾û`bgdÕ×RmÖaqcŒžä'Æ:ß@…•]tM_¤£—¯Ò¤ !~ç¹#µ(à¸˜“ žŸ#B£ß6Ö3µ[D‹ŸæŽ—Ú²|™y M¨,š“å¨,˜€'8¥%øw%<98‹€$à–„ºf’öë‹ÒËŠºžRÙªŽ¼ôð?½"kÓì…Fè\I¤C®ô`}ŸVVÐ€w¾vyê>+ÂNŸÁáÌá¥¾¡¤Â`l8 £ÀrÀ(3nþÃ¹ŒÐqèábî41Šh^¥E¬0XQ¤a|J"ËXø8,uËŒW0¦“` jp’ÕÈ¡7¼ÊI–0/²jíÓN‹
­7HÞOÂ$Öv%¦Õ¦¾øK+¡êÏ2¶Ÿiè9erô á,Ùhm8 ì
äYÖþ«®9d¢–¡þž°ØPDõYÚ>¢ÞŒ¿ºŠÂŒM·NæœŽýI“æV‡XóÎ8B&–Ø¨a–âºwÐ‡!J¦æâÂºEÒpwJ<™Ë‡`„éEv[æðîá‰5×øØ¨Æ^møÍñ¡¡=¤$¹§ V#¸zyšHÀ	;Àõ˜¨K¹>‘g¬õËˆÅ„U’lÃZE=X„ý(r‡:Â‚=„I**ˆ•àŸêêk—îÑID‡s`e|”É±ZUNÐ•áÂ†²ráà8×F%6§½^˜“dÆê(ºÔÑƒ†Ž°D¡h»²Â^=}æ¡æò=’WÂ-Î´€øõ™•‹æ\ü3ÑÆè:óÉö³g†ìô„¥#t*­cöù<ê,ZòZ+µsê\4*ö\ÐÃô™	]¦ypÂ ®¼3ËØ:ÈØÀŒÊÈI¢x)7Á»‚ìlSËTLç™ˆ†¡Aú¤4/ánc.*ñÅãÈ?¾Þ1î!WA"´_eËÓ¢w¸íÖšsÅu•ˆx±ËÝ#@.Çòíð_VÈQEŠYë¢@}kÆ¸áwS#P8«ÌC‚Ê¡Ö(ÐÅì2œ»»-,öêª$É"‡iÎys»7änàlµq“…4 &ŒÉj¡Ž£–Ø†aÖo#&³·9÷´É\nM4÷ÖÌÈ.8‰¢¬9M›ø/‡™?½Ãg'l/`G`DA%¼wžpß7ˆ C=[ t>‹˜ÚˆaÈ1‰·ZÇHØ[#æÑµ2ÑU‚5â.€FŽñÑ™ ê	è¤pÍ±x`pÁÆ^R}ÅðrxÎw ‚æâžGvß÷¦”H¡†„ÆxÔÃ‡Öh*‡¦ØÁ|6f%ƒšhEÇD:SÌ¥UÃ±"šYwË˜ÁH—¯êÆÀKÃ1pÜ¦Sø~ˆ¯Y‰ó*·P{ŽË›˜ó¨/©@Åa×C¶E'†ÞÇ(HD%Á<Š)÷Žé!–°?o± ŸÎÎ¦ƒÀÎ­×Ž&]ð>Â‹”ÂIòÏu¶A¥³,{¢X-'Ä
Õž†ªyåÅUÓ«	ÉŠ)GÑá£‚:Œ«¢Â<wR>³„öÏLnCapÅ‹ Rz…¸)40FÏ’(z‡F|âl„ÎöÀÄ)Í„£ìhbadÄÈÊm/Ì\–ƒN:H`ådêýJÓ¼U\2\àéÎM² ~ãI¸"y Hš@#£&›Í"	`Ô;¤×B‘ð;·Ã
òQ*ú]‡¹WÌ‰Ã²Ò~Þ@ÜèE}t4$L"ÖÕÛèŠ·—	_lak‚ÛwRÈˆÀñBQEÚVÙº¡ãñ¼	"
ÂRÎ	ÍçKt‘7=´
ùC£"›gã4NfH¤
¹¾Ö ŒWœˆV ©$&¤¦º(©"LØTÄëâÐrmžE¤æûþ Äœ3s‡$º3ðœhI‰Tº¦XMôEãÃáØ­çFå$›–Õ@wwml#ísæèfÆ‰Éì0ÔC97Q"F®uÔ&ýà&†µHdµÃãŒh'ñU“h:‹§WF.Xƒ¦P•ÕJó¦?ÃÜ¾ˆ§p•,Œ×íÛ·õ¦’)ñ,rõÞ€u}5ïŽa
þLH®EÛXzÈ¦ƒqalxÖIÊ`GÄÚ””ÆN!ö®Ü»UÀIIºfÉÛÛq
Ü3áf®15 ¼€Ì;Žöê&lÉ¿£GÍ[z9B/
 ô-sÁi•eG
G×Þ#Bh~ˆ–c#Ä÷CwÖ^³™³9%ƒWA¥ ´=›ãe@‘Q(´N â~?"³Èå0JJN($TÑh`)´;³´,â`(âVDî­ë˜©ær§#JÄ£ÅÍ¤ªåp¦=Œn3¶Qua/KóÜ$!îS…¹ç¬¥a2È¹~ÏÊËÃ™IÔÙØDX–…{ Ë|ÀÎQÁñ¨BÌðü€á 8'º+®5G Ò:WÐ8ƒnF81KÐ-BŽw4PJðƒhZ´[ß´°²³öËœDÚ Zs>µLË"7ôq\â¥KæMv†8+ñ8œQÁI€o˜Dœô“EšíY—[+¨žŠJ|M:l‚}bÚÝAb$PŽá$7›nb3'Ó¸Áê®!Ë‹Å0¹àìpb[_)ç	£ÚˆÓ…•sØò­£ÔÝZã·•tÏlªo ‰òÖŸh‚Žê›ÝU» +•œ£HÂéA)<ƒç˜éeW¯`n@«ªBcp¡ÔàT”€ÞWa}õ0ÚŸN%E	É|Ð©ÏÛ[bu–Èæi«™ÛQz)Ó€~¨ÄIÍ
Ö?.õ‘Þ­ºu6‰%˜3}¤Bâ;»iL¾OÊ»#÷¡.õ@öÞÊ¸;šÄmMñ)E‡¾é‚<:»èwà¢2:ãXðqíòÍ)R–€Î–Ù9¡FQu¾-v}!¡ðÃ”è+ëüØ–€$Ò&uøú·ÐçEi2±"ŒMJ‡3kCM1È!Wë‰˜®]œÃ#”1µâÈ¤›’Ú’]öeSxó3»ÜLØ»Fy»LE]«6þ0Ó¶Å’·•€ˆÇUûdyëÙ=‡’GÈÊv<µ³ïÕñú›˜7À£{y<Nò<NŒrkqV¦o3nçÔ¨ÐÅÌZlÑ
±Õ9;tIi{¹c=4fžHhÊ/Ù¥ôëp8rØØr&Õ˜UâÁkNß£_Ø½Oµ.Ü“0:ºž°(ªcáˆ7-ˆl…¨º”\Ç1ŠúAn„±à¶àY4lsV.E¤ýÉí¸ÓÐá=N¼°:»§€‰>2±ÌêÍ¿òc<:çÞrÕªÎ²-£DÞÔõsjXk‹¬T`,l›¦ãHíat ÷:¹rÛ	çä¡J¸&Ù¤”"ØÅ\ŒTn€É`*Wb+F›ÏFóÈwH×jbšL((‰7¸v¹‰h?Ð>"ykìš¹ú€}Š]¥Gs÷˜CíYë	…@T…%9ZÍ‹yYYÔg¨*b	¶ðY>€ˆ²ÎP6)U£3ó@å $É‚Pû³1ÊœÚâÅD»¢ŸÃÿ«‹EJåŽSÞÍ§ujçùžyìQ5kÔÛ(†=ŸÁÅ»€yówm4]sK“^ Ðz.…Ò	Â3ln2SƒBF`èÄ¨PB\¿†_éNª£ z{„QAÉÙá	ÊFÆï”²œû“oTCT².Ža›rë<i™kd<Â™îæŽð(` ¢¨ë×åŠ˜Í÷Û)(qÂö7îƒòÑLÆˆ­U89Iè¦9 3ÌA˜6˜T¤¢Z(ºNñ©O'o„•|3Z`*OáÄ*.¬ªQ¼œŸe5•D^-àÜx7zH	…ƒ›ŒÅT¨ˆ-,hØ
á»ÉÐ#[ëlúxá…‘ðN/öPÉCR¿+EÄ©HÂY`jF²ßÕ1U@E6"²/°\ŒÊe±“A”•Q¥éeU%ý`Àì&ú‰=6±6ä2[%À> Í›®7^ ø,¹­Ýª4Ž\†ìÊXÃ†¿^S}’jS9	ÊÇ0(ººmJ»î%!Ýhg5•–¤{ÐJâ(wÖ,_KƒO<f9agÙ#[ÏÏ07¡5 z.Æè|Z–OëVŠÓµI½™8-T³¿÷Ýý$â¦31Š3OŠ{–>à·¥;ærŒYÏÞJÜ1sÉÐø+9Pš"½Ìl…ß0ÐBq5åÛÜÒ|Å4&Xd‘3c÷%ôbêµƒ'íMýÈO¤—¦¦B¾‘áhÕQ	á²^ô2J3¸gj‘õo"ïµ ð#íñ@(/8£­.¡c']ç×.ó‘%û®¢'
“²ü¼ˆ$›ýØIz@7Cå6ÕRÊ!‡dÍ'‘Y¼¡vqá\’i°Ä8Ó’ù`ñ&"ò;´Ù 4»ä$p£xAÞR¯ô€Œ”šo¤~\ÅA8æ¼†I&6kŽ\pÇ¹ûº¢%gëU‚_Iq¦Æ§ò&—L@r…0,»¥{Ïå†$Ü%åŽæ|ÒD„éíô0Ë¢éÀêDÅ©å™“kå{U<îªéTî¸eýÒ(IÄmi-Îr*\è…ÆÌgìŠ ùËÛXÿ.HuÒ‰E6í‰ó2c~eÐõ…e12¤[c¬“¨ZñPy²þŸKü®GÈøœxNÕä‚WnI.Á¼²~È÷±T'GÝ‚Ê¨ÛP„eã(;gÌqë}}›w]©AŒqÌ:j+QåÕI˜;;‰¦\ä2p×ŠDØ9b—|p¤	çš·ƒWÔÒsoÀ¾v¶_Ý¥ŠŒ}Ê¢d399A‹ "Ýgëê‘%ÎŠ[¦x¦‘¸@|Íp^’¥XÌ«˜ë¨s—`ÐuÎœPœ	ŠßSPÿ´P˜XRþ«¹*‰Í¢o#å©P¡ríy“4Cãû,¤ä#Ë§¼÷y‚´WB”ÂÀßÞX¬®›¥WáH<e©BÇÙ[v.ÅyÌ«­tå®«MàÇ03Æ×À&ÇR“Ó ùü)"•þ&§¦”ÎÐT‚î³s­ÄŽ .-Áî[/Hƒ¹ŽšiØÈF*ÇŽ¤þñ˜¢›Äêå…Ãqlà“d•¬¯·Ô¡.k©KÎ%luL³š¼)ˆŒx§ŒE—r*Ôø“v
ÓyÕbmNJccÆÈ}›å¶6¡M„Ð!
2M¸î¬Mù=“Câµ´ÅpÜm/?6ï| ã‰úN5ÇŸê nØ ¥×7{"äÀé #eQ_ÚÐœ‹ç‘[Ð9q¸A˜KPÜ5)áA9dzPD2rŽ´¸ÅŠ›ÒÐ*#¡öLóRçN‰OT ¬ (é»_•Ò[16ßèÀ5¼Ò‚l1—†d:ªÙ‚o6°B›W¥Î(òC§éŽñ¦±É.§&&àÕ3«¡À=»œÞigía!Ù5Lù¬z˜úXUËP&×ÌñTn‡ôûH8Q¸¸¤ÅeáYÊEçhwºå|ÅmÙ®J±@$áÑeáóƒY:û#½™ˆP±XÍ®ÈúTóÉD"¹Òæ‘ šFbb÷{<eû›ä—ap@*êKƒU©Täžˆ´[rœ®š²s‰†\’…¥J±îÃã]DIÈ‰œôXÃLìþÜÂ­=Yç²¶5:çš)äîŸ 7°ta
dJÍuŽUŸ³ÚÒº4j¸Éì·*Ê© ¾b˜5eŽXOJSå,µ¹Á©®À ‹DøaÄäL­t*Œq“:/º¿4%IéØö0Ð1Î …”Ã¤)Ê [R8IlMÁÔ8TÑ8ê„¾ê±9k…5 Í«#Ëà6Pç¬xDX+”u
H‘-:‹ HÆ¶Z@SÂÝ±Â˜Êe«÷Í—"7 Hå0S[—žF®Úd4"›
€ÿZD]¸ÐXfÄ“bŠó(®îŠŒA› 
¨¥¤
Š²”ÌÛ,ód,i›OŒ«r+¿'s£°º¡1¦s›án)4-NÑ@ (“s'v”dFqtÙ ¹utæ³²Xl†e&‘W&™ëÈª>&Í´Í©à*È¤»aéLëZÐB4áFIu¦ôuòVÑ!Üèà(åµª€ŽÐLi!íkæ¦F`¸V]íÏÕ”JÚtR%ôðO?Î&lFe1ù`q.›½âÁ‚ÂÉSmJˆÀÚ)nUÃú#YL,%Í®jò@f) ýt\ìVçDqdxÃT|É‹êËÖ¹-êeë-°d`Bx’‘^l’Ž:_iùJW‘9ðV‰%‡„W«#c²èiœ€N@¥øñ5¡)A¤6Ý‘ìdúž 9!68	¯Æç”Z‡‚ŒàU¥Ò4Ú¾*E¯80_ÈJ¡FŸ;^6Ëf]ÒÜjkxeJ¢ít¥Û¡¯JKrÑ§Hð©:i™*ø™xI3A´¼³Êñs1•öíó—úÇëÌ<Ð	ó GñLúUC›+jÞ`ÑC§içš&’w¶â‹#ç‘ Ï5A-YLb©¿'—¡ÑžÖê¾ñ­Ú38-|3MÇc]ZÖ1û™L*&—ÍŒOÔi'T‡d€ÄÈSMË :3WW\S€¶C—ÝÈIcvw=z¡RØj}£…Å­ŽÍ3FpÞ1¿K/sõÓ±–ß
õþØDÑ—:ejUë‡TÎnF•aØáÈv²u%QløÐ{&,_Qår»Òõí`#‘Ýâ¸Æ64¿oËŠŸülƒ&4>‹ÏS)o SËòx<MCýNGê•*sy&]"EgŠ¡¥‚–n»	{)Ùå]óLß0£â'ES‘¦‰¸µdÀ³>q]ÇoW¡¬=–PÑz‰@&ÓH<Î…^@`ÆË
¡˜’¥"ÏÕ±-Ðl=ó#ÌCÞ.œƒ/1Ggê5?yÌ­f´~¿…ÝVÊÄw):¨A¦‹ž§ø¨@@#PK¤$o…"a‰Œ’Bs#ïå	‰O­|Vcáô•¤“±ŒØº¶Ö«[|¡ð€ƒäÆT‡ “+ÞÒ÷*PP ŽI¡+Ù@ÇÕêXë²¸ƒÕ5ãx»Oñ@½(ã°=§˜¿ÑºŒŠÅAÎle_$~œ³«_´ÔQ'ó~¹o/Ì#¸MóÞ"äÈV)@–	4y`=ŒnÀ˜^ö¼éž¡;'ÿRCØc®#´u¹>¬4‰³ØdóJÔ¢±z‘rƒ³ä BìÐÇŒ’½¡ÃÏ™ÐæQ#–‰q»?“FOØ®ŒJÂbÓ–Žç¢[$3,,h"¿\.1 Z4!ÄÜÁÏè*ìUPØ«š˜u1	ÂZ=Í»ŽTßÞRšGR“íÎ±ñÌyrGnP¥g˜òsÅhL°†Ro‹7åÀ8#³ó>¡´ëï¨õæ£ëSí¥Ð@ÈþdæTÍÏÁkÍÚÝ–0æÝ¿°ß šA4Ÿ¬
."ÿ=³¨ $p_Çó#è»¹Sü°/ß©j·ÉùplôšÝñ–tÝCëü.Ù¥Õâ–Yîê¹ØLÜhÉ4³Ñ¹÷ïÄ%©×Ã
âf-K tZáB’Sq£NÐ²$ —¤)™Ø=l™ÐpF¥×Î$îE÷¨«vŽÕþzÝ9:êìŸ|¯žáêðèàùQg¯¡Nèïîžt÷OÔa÷hoçä¤»­ž~tww¶:Ow»j·ó_NúÏ­îá‰zý¢»¯üëã®:>é`‡}õúhçdgÿ9Ü:8üþhçù‹“àÅÁîv÷ˆ^¨jÃèÔQvŽNvºÇ8W;Û]wNªÖ9†i×Ôë“/OÌäƒƒg ä{õ×ýí†êî îua {gfÜ…/wö·v_nÃ\ê)@Ø?8Q»;°2hvrÐp4i«¡ãd þ^÷hëüÙyº³»û…Ïj=Û9Ù‡!hï:<ó­—»£àðåÑáÁq·¥xløÑÎñ_¬@6ö?^v Ø]€±‡ïÖãXÎš8&\®úþà%²X÷î¶·)¸Q]µÝ}ÖÝ:ÙyÕm`Kæøå^Wöûø€Ý]µßÝ‚ùvŽ¾WÇÝ£W;[´GÝÃÎÎîÒÖÁÑB9Øg4úºÅÁåÆá±«£–™bì#u_!~¼ÜßÅ8êþÇKX+b‰ò±áwžui£œ^ïÀÄðôb(FŒu/,b|(v ö¶wžá±âlì¿ê~¸»ûlQ¶óô 7æ)Ld‡æ3À]ÂsÛîìužwÌÀ1yd»¡Ž»[;ø|ø°Ë[µkÅ£…ˆêÀ#DN>Çà%\DÀ}806~æNvÕŽ]FJµ{pŒlwN:Šfÿ>íbë£î>lÝ±ÎÖÖË#¸oØ{ÀlŽ_ÂÜÙçÓÀõÒß9Úô%#¼}ÖÙÙ}yTD<ù ¶A:'Á-Žë _í<ƒ¡¶^È±)ï*¯^ÀQ<íB³Îö«ºŽ2LrGöVGdû¾iñÛ"ø$†ÁÀãR’ŠË¼úÑ31Øpä!²¿7E>8ÒÖ¾èÇ‚Ï(Åbœ¼Â•…%¾Y¨ð”Ò¥8D8@‘0ºdèK¸°þÏª@
/EgÇrL½QÊ™ ˜ØòŽÞHÈ´iåéóç©p2‹(£ÇñÈ™{…ÍÄ‘Ál ©—dü°éÎì-…Ÿ)z´¸}±¬kÅà%óœíÏ~×©C[Äá\':´ü{dyû ¬ÊrÇƒ$ïú.pi_%Öáòä´xHdç”ç˜çNÅÿ2Ë¹¥ñŒäS®a„{C²¨›0Pñ‹ÅÓÀ:›Å!znM£üž„ÿ¯~YÕø—´n¬I£±U‡b´â«N2’¿Ž	Ü!;tpi8cÓ{¬ƒDÅÙDä„Ùó{-¹÷"f@ò—X3ª†~Qb‚D äyP’½uõ7RjF¦©¡²,f5II©cû‚®ž3˜™Ú®ô”-Ê¦‚\ßávR]ãÍYÿÝœÒ‰ôYGô „¦8‘È[O¤*‘–²V·êê;¬N÷F ©Nß{ÂãžÈ{­:lÃ;îMóÞ¸wÈñTëƒârà¼¡jâB)9Ì=ýB~æËð­Æ”L6Ž‚ÓVýtÓzY³iUo€]§y»jˆî¤CÚ8Köpœ\•õQ-®!Ñ"Û#“W‹4–6~ZbÅiWEÉ6wžà¥¬àu±&ˆéáÚ…Áj²®…þ¯Md³Y7°Ô•sj‘Ù½du#"õÝp:l¶Û———­ódÖJ³ó¶÷h?	u0t“nÜÒ&XD„i'Ù¿ùéqªyv¾,M°j¾N0rÖæ2Ê‰«‡J”õÈ5¶44•Ó­„¸Ù4;JÏ¸Ò¢(ÃN©n#;uöbáIYýNÆ}rã›XÂC.ÍL{Úyz|°ûò¤»û½«É<¢3•ãTÓ+@Ð¿Ó‹ï—w[\ñ>[ÖA´<á8l˜ô®7AàÛl’¢%á‘;\ï®;Ø|´,¯&hn$w¡2¯êùÑLoÁ?ýZ½›éì„cïTê`@‚ˆql[š©‡ÆtXÉBëµ„»?¹c«Ë34¡ÙT&À‹³ô]ÍÄMÊ”)ÖC-iÔîuz…b¯¶¯ èý¢¬N1]¨ßáàçÖÈë…¸˜F+ãÕ¬ß”uÇ
+æÍgÆ§î_~ÙÙyV’%4ü@´js¹ñåm¸¤ÁÒKÊ–Ã”Æ˜|8ÒÍ-DÂ=®6±ïRë/r'WÂ¡Ë!ˆe)ú1#yÖëJ’í¸ì/åuâ¥Í`òL‘E<4ds·Q\ES1CÊ›9\Û³ø]êX„K	/À§»uÜ
nÈ.†eó¬{%…ý
o–Ô¡ŒŒ¦t,¡©<ŠÉ0Q:¯Ú—Ã«&lsst>µ†ÓñNçwÿŒ?ý´×>êv¶÷º­qÿ3±¶¶öõƒ
ÿýæë‡ôïÚÿ?6~ýZ¿¿ñpã›î?ØPkë÷×~ó;µö™æãýÌ¥ÀTò4ZØš¾çÅ(óï?ÉÏuðr~‹‚|ì¹"måV'¯¶›ð}7¹ø?ÿÏÿGÔRå$S(½pIB•ymÔþHRM¢ä"1ý4HH€aø¾³P;1-Ðñl#ä=*€uF¶`&ªeŽ/Çð'¨C†uí'\r°³íÍ†”°Œƒ˜0Ý# àÄÓ™v²Þp¥ëÅ“¢+E>Â°1¨yz’y2§íôi
¼.X?[LÓÅ;ŠîÖwþ]ï”C“’B•Ð«)ü
³·Ûz½}f¹åx¯¡Ž:[jô|†ee¨zRç|:¬¿-NL)P/¥Œ#ét#gÀ‡îi¤¹'¡æ~óÓL‚1ïÝKg}˜T+Þ»'ÛÒÐ¯y'ƒø|&…¨äÁIV¬fIoÈfˆkÀ´ˆÛq]‚Ø7ôè‰Í’qè‰ã‡9õî‹ç¥4
*°âã"µó÷¹z]‹ðtÈÍÁ³NK`Wàë!»DA%–†|*»q2{§^íýŸÿûÿ…Yá·ÓÞ[ö€£0q0ÊQ˜OÎ"|1å0Æ¦|nôi¢Ï_€¡]µ§Y4íi|WðÁü½Ô}-ƒ¦ã œÒ;  Lg“ÂqÙ¸N@Ÿ!›Œ6Øh¨Ë’Ù­Sxš¸§òkkardå·,2èÚKÁ]ŸÀfÑ8|^0Ñ¿ÿýï8ý ¥ýûw ·ùßmõü{ÚëçÑª=[[oó“¢íò`ª96ÖÖ¿i®¯7×ïŸ®?ØÜøvóá·
}G'›øŠ0&*º®ŠŸV­µÖ¥ðÆ<h;ûÏÔ& bh-g•™ØqX÷ë®.ìü2çç¤Ëù¡9¼øþ{¦¾;€k»Û=}Ú9î>ùQ-„§ GlzììÃŠ÷·L×šcóÝ‹ƒ=çó§ðùËmø{ë¯/åã…-™EsXi¡£Z³Z%¹kŒRóyT_îb>8yWßCï*~Ë öÔ…æ|®¶5¥i©=dqDtÂìœ*^´X¥[0Ô²KÈ„êÀ}ãC€±Í—ËÖ’ê“+,×¢9YíGƒ½{+úÛzkÙ}] UCk z»™uÙ/»è!<ø	{h«>¡
@Ñ=Rv0 \ž§
9îÁØL£ó‡T÷T8_¶ÞŽwö;ŽÔÔYñd”4úcÊßtÜ¯6}Q¯-±â^.ñ,ì½Mòª1ù«åƒÆ<¨O=Jt‹ÞÙ¬Ö|¹ô–WQ§%«f_tíqÜï"<õ¥cŽþx
º›žŸÜTíéxRâq£ô™dx…3%DÏ)Ý
rÏXý=Fzü»ˆøøK?[Ð¯yvïž&®y/1#,Í9›ÍìÞ°Œ½ûÕ½ï!ç¾§Vµ8Æ±©2~¸©ŽŸÐ¼i/I´P }ƒ­+ŒUtÃ•òJ-U%MDÉù&Ld­ÒG›?ñ‚g¢–+%Œä"HŒKõ	ö·Íµæú×§ëk›l®=ü0yd½µÖZÓÉ­ŒþòËÜÎÛ˜]H/ÆÓ¸G³(_Øãe®Ã¢¬—éî°I•r¥Í…\Vm~÷`1Í!ÝŸ±{ð|ˆõ6^ÓE}»'[§[GK†o“·Ø¼Ø¼‰,ëkØx¹ïÒ~›pÆ4d)ËOýY¼ÁùŠíõf|:<:Ø~¹u2wÿuÅþ€B¾µè(T{0¾\ßhm´Ö[÷[k7ülïµü6 ÿ¥óªS˜/Î³öO ¶ê¿]o}ÛZ;]ÿzc!¤ã­£Ã“Ógÿ±_Æ¼ù4t!HákHau­»°Û9Û­ÁB3¦˜s˜ŠñøCî¸€52îÍnwu¯eW±ªW™|ÄÀËoSu¿Ü£êŽ7# K×{“Û÷”æÇ‹4ÀbÀM:vNÃ3ÊR¤ßZ9FÞß¬#Zµp<é­ÿü­Óíî³ÎËÝ“SRáÓå »ï¨'eT ðHjô¹¹MÿA¡‡ßFÁ+©?‰Þ¡­Ôý„±Àù„yït;@¿$—)ˆò6ÖZçÿWB xß¦ÿpßÓq´.çÃâß§ü,÷1œŽþµ°AÁ(>kp+Û–ñTì¯£~<pÿ¦Ù?{@`Z}÷“Š§€¸›. ô<K1\ÅoÞ#L®ø„ÿ9Bv¼×š\Í*ÏÆÿg|9ÊOáÓ|Ü’Úµ…ï5ÍòIá@ $« <ôŠßÀëÛZ–6ÛLâS¬%ÑÂbâQÄB:œ_:¦ÂÔ7¾‘Çºã{†ú^šE.ùBRÁ‡—ª0šèw,­")«,JVSý8hŽ°ûa Ù‹	‚=Uøí“Mž¼¹~SrQ‚Â Cµ¨Í‡pßY…h%wÔÖ0ê½µ[B±‘8˜ë:Güª¶ò^7»®Q«©QÚZ µh°J.×í–në¶RªUÕ¾‰F$õ†©ªuŽŽ€‘=4§Êžƒ8€ÿÁJú¬ñà[9„gìœè¿øÑãZK9Kh¯¼×D
?Û=ØêìÒ7§ûÄ£¦5@v>tÍ÷ÁÇC]Ì~ÍÚùùÁsR|×†é8ÒÍ|·®”ñàª·T»×š©¶q–!a8'@ªÔ‹Ùúq¢“¹ói4‘²Ÿ± }oMÇú¥ü;ÐV-ý+®÷Zê/ØV…ÑÜ¢ÜŒŒþ~Æaj÷ŒyUÓ®rÏ5P|ê5	”½oŠÃšÆ‹®Ý}m>êê|èåY¥"ÉfU“Ã³4:×—Ü’eÝuîÜÁ“îu'ëãiD>Å xzeì÷´K]è·iîXÏÀ5P±åJcÆ£:ËùÑ¸©T —kEÃÀóÂ›±¼Üž›*ú!v±pGÚÂM‘q6°œË¹ãTõŒµ-¨a{ ¾7KªÍâ0ÞÊfüÆœ©âÂÂ5²wXÏy-NèæÍCÇjGa›N!ð–oò3!z7wMˆ©î<{V6ÎVïŽ7]$hmÁm(–wé!|8±°“|eñÂÞ1Ø£ž‘@s"¾g¶{á.+,O+~&ªðó³ÚŽ˜´`[ü 6Ë?êçâ'ØÐ’o¢A4.|Qhšô"îŠÝKöq»…Âœ ê©·bÛ…aÀÖúkêû™[Ù¢‰ÚUX¹|Zš©\&=!4o{g*š2~ƒ4'?¾À»ÛCú¸!.þýøxW™z_YdÃNHý‘	ñD=‘²bW¥@á„©®žs6e3G/¼fdÑeÃ©ãÎêÏäí	kÕ1Hiõó_¡oB¥”¹Xý÷[j7µ¥ãJË€ö+Æ‰\M‡ã«"ÿÁÚÙ‰E›0–ðÔâNpV;W}Å%ÚC‡xÜÎýåyWÐ+KgH_ÝÖXqçô	ÇæLÚ_Yó?x&#x‰ £â6ŒFµ:¬ÛÊÜØd10öŽi6ð9µŸâÎ²iE…Þ´9Û$›X¹[¥µaWžZËÚ™¹ÕÇO@Býx,CEj°®[ž§èÀÓü™™Â¶co¤ú2@†Ì¸,¯Z~`¨fc9ZQXKO}ýè%	šš·ÔfÔppö˜³~LÛgªsðTY	Gz6ŠÞQ"’+îÔ	ªôDÌ©»ÿJ½ÒÌ¸@¨;„CæÏÃpº ê£š­ÍmXÍî*™žZÐôÃqCÚu"7ÔJ¯Ÿž™8àŸE—[åª+<ÈTÈ„»'6]å“b0I;tÿü”¡]ç95Ñâ)W©04pnw#Zfz%WÑ¼Yo,žäÂé¡è¦É©–$H¬ò„Ø†gZrå]dY¾L*":èÏàª‘<Cr·So0f™XZ)‹œc…S#îCOhZ†µø›«Úì,iò„q#g½?Ì¹úàËÒ™¥þâ•1{§¹ûüšC0Æ›M·m>-õ9–L'Ô)Qþª+} Ü»€îÎˆ8ßù«vl…š1Ø	Øñ±n|µŽÂxO³èœQÁ‘¾ò–¯?ã.6h›h;pyÓuOiÞ|iPíd†A¿] ð7Š_¸ƒú«Å6þPóªÏƒ†‚ë±t(ýRTÕú>jPAÝª>»t+|ªR©ïnï<#äÇ@´YŒÁ´‰/|üô‡ÈM¦ç6wYTˆ - çÔ	yªtãA0ù}™°~aým†û ä³¾6Z÷y
•.âÊuWy<(ôù|ÏDU‡PºçÐrã3Zhìr”Š˜²òÌæpOõ÷Xm!|`É¹²Í ±Z‰ãgêI?¥lìuvö+öxámãÇcoeó~Öb°þó?Z&$SÕÔk‹¡‚zÆÇCF¡¿ÚÞ<5ÑÙÑã¼ðŒ4ª9À@ó˜Š÷UÕtÛð‰G~Öö¡ù±’ÅÁ+Ù8>Z>8PrGßMo62)-¯¬‚b$ý³Ó÷ä•ðkkb<ªÌJ%+H7¨Öx·#ç˜ÌîlLa6û¡­î«3†JdÞ 8ÝÝ9>ñìÆ¬\ùÁ®Óð-(ódÆÎ'§èðõöé³Ý*™æP?
nTU}A=tå½–3®Ûþ‰O.û­é;2¸ôÇ<þÁÑIilß‰L_Î"ÄòFS3€8<k1 kS[î¨{¸l^EKÜr hÈ[ÔØú“S¬Ú9iëú ‹'%Mä^uXuÇ›âiÊ¸¿üMaVp*¶&6Žã¤êèkÃ­Ûür¶$P%¾ìAÚgi9™>bB¿~Ÿ»Ø.Î©ŸÏ!}Ç›nŸ„¦ùWG‘·ÙËÇ`³ê}'°.žqŒ67¹üÄëä[ù9KŽê¬ˆEŒ„X¥ÄÃ=§Ð6ÝJ
dæX¦_jµP—y²r1tžQ†—;‚±“©ï4¥xâOë–â÷†B’íªÖUIu?µ¸D.§aXµE4~GßG(T
²9ÐÕª}ÊAï"Â@+Í4º!Ð(Ë°È±9w3˜’ëˆÕ,`@ ¹€ñ»›vÑÐ™ôÛ“~k}vôBx5ñcI´×ƒ(j8&ž›ÀÏæì‚Ÿ!XrÇ‚œËi5øÄy‰yî>ˆ/ât.Dü.D‰ÈÑKA6½U ·eJNÖ¯Îsº[XçJè›C«´A(ô³YÂ…½È'”†ûßÿËð%äú¦Dºäµ+i -§-,|·ÛÝ~òâ‰,Ÿ¾»ìÃoÏR¦1IÎ™›Ø¬¯Ñs#a oU"îk£V®k€j(ü;›L$7ÈÚ¿ÈPa`ð£(9ŸíÛ	2 ÜÔ‡€//™ª£ñüÿþ÷¿{‹ý>GSÔ·v8š·gzÊÅSòZ:gð¿ÿ×y:Ô¿>tuo7jÃÖ&ÚêâsËÀ~Ä2úObTÃGžt¼²p›d­ôYÀ’ž¡ùÓ"!–Åüã=Å¢T²ãzµõ\ÀÞ{yx;ÜÛ>x½L»?¥qr
çTuáì¼*`bGªlOu€ÆüVŠf¤äJª€84¿éË,Å~Øù40Ï­…ŽO¤àih?ö’`N!½áj©qRå?Ã-ð=e‚öŒÓŽwL·*(¨Œ¥hCë&ã^Ök{º1I¬‡M‘G‘¤´;ÛLl[Xßì!M„—4AÆCÑÛ<¡Ò¼¸ÍEô1X# ˆœb.Rˆ›ÿú´×ÒÃWZD—`n³7ülÒ¦2	Ÿ‹Ž|©b0YÐ)ƒm@ÓwÛ;GëOèŸM"¨Fz ÀA#_>@|F‹9#…ÁV„&¸ƒ¼ä`9œ66[-ó°ºQîªîjKu8í¶‰ÄÈ™­v‚,0"µ
µ“ç˜a%AÄC)bïlvŽrBCwâA®a.D”ã§ô/×Ö¯›™ªº•<ã¢~xÿÎÎî¢[_ùÂÀrLŒ[Å28ùf»(Ù:§Fp£ÆmÏ¶©@S“zåÿ{ßºÕFŽ5zþ¯•wÐ8™!éÁv]\.Û=îo4Ó$ðaHú’^^uQSåq•!0ó4ç1Î¿ïÅÎÞR]TcÆ4Ý¥™É•´%mmI{KûÒxÕ­T¾!¿ìFzù<;" ðèéŽíÈP¤Á‹¾ÂêþÌDAès‘å.Q¿•^1ÄE.Ò¢rá“ÎHˆ˜øË»Á£Ò…Z—êqèÏdêZim±7½€»Yóç¹pJœ=¶Û—8¡Ò~=d«ª›ýÿHRSV"ÿ?jKm¡ÿø£ôÿ³ŽT‰Ü#Ê÷˜|PÈ-ÖÜ«Êí.!ŠSV=‚³í‰ö/ÓiHßB¼dÎcÃ`ç¼Ÿ°ãÜ§Bw{&'±õb¼îŸÑÆ‚õ¯éRÎÿ—®Kåú_GÒ”&mYFÓ2,Óî4-Kw4¥ÕÖå¦Ý‘ä¶f·šNÇ1ò_õFÞ~¬ÓÔäŽÜ”:ZSW;zK‰n9ª¥¨FËlÚfÓTGnvÄÚ‰­™FÛ–åªÔ²ÛŠDÛªftš’JSBQ[T–M­­¤ÚNìÒZ¶¡)rÇ²íVGîtLÙV,ÃieA£¶Ón·MÅM]¨ÚG´4EmV[3Žª™µ4I5%ËêÈšjÙR[µd§#5±f¡‘#›’bZŽbIJÛÑÍ¶l¨†ÜR¥EµŒº£¶Öi§ðº-À–mêR«Ý¦¶¤(¶­¨Š©YJS6h§¥è’¥†¬d,ã:m©ÝjêŠ	MËˆ_¹cë–Üî¨¶C† 9F›
 ÐŠNê¨†Únw`f¨©C¿å¦%k²F©nHš-ÃÌuZZÛªe-îÚ–,ËŠÑÖ ³š¬¶Ú†.Á0:€¾N§Ó¤*Ìµ´€ Ù“™VK¶[N“ÂhšfË;ºl˜¦¤)–¦H†Ôªt 1iXÅ&qËÌhÎ.=·’êX–ä˜–bÙjSÕÛ†ÔÔ[º)µujÈ’íXºš%ZâÑ–ÚVm[³$«mI6Ô°as“a¾Z03rK—¨)«´`p"­h´cS	æEn·ìNG•`®5SÔkmYnu´Ž,5mÅ.€"Øþ-CqÅÈ¹#íå€-K…9 Yz´5¶LËÔ­¤£À¾#2UGÓ5K7š²©R»IåB`yH aÃ‚3È²¬vGÖ›Ž
hš:L¤$kv›:RÓp¨™'˜n*°i°ŸÁif˜°qRþmJZ[·–Cñ¿zf}¤íNavpr,Àôö8(€ª0¶Vv6K†ˆ1ƒáŒe©^‘íŽ´ßT:¦$·[¢
€6dG“,³‹L•;ÐDóF8«‚ÌEEÕm«»„mÂÂ6Û¶Ëµ£ÊšÞ’a=É•¶ì––G.3©•äAhU›LÚiE3ÂÐÇ©mRNÇ„…'I¶S¦´œ–&Ù”ÒbÍäÔó‚Dð	v3ê(mˆ
öÍlZ-KoÙ´£;’Þ´6´ç uC•Ø7=ñAOUK3ZpÊjŽÜ2´	û‚,9­Ž£èª¦5;–g¡SSÄþsRã´Y*Á^Üi­ë¦f¶`+´›Ðñ6 ˜ªªLáëP´6îÅMEÕ•¦…€£ÃÄ8¶&›´	‡*L¡™ó¦Jð‹¼*D<ÇÁ»0ì®m¨C¥×lÓ”l`ù`qP§£µ€ÕèH†c·%]ê,–õ—‚Ü¨¨Ø[@B§%Á’i©p8 &ìGFG6ì¦ZXVÂƒÌ $>§¨ŒC±ƒ†"YtWƒ#ÆQš8øuÝq0†d¨j³Óº5Ì&L8UÛÐá_U‚­x	NNÍ2LÍ¶uØ±€’‹±5-§vKZ¥ØÍm©©Ùºh0t {Ë6UØ'»­›vñÈ•Â‘+l®ÚmÍ ÈÃu¬ŽfÙmÛDÞª­v,KÕôf¾TQXp/}"|„j8°X
l¡°g#Û@©¤ØÔ;Ï8Úm«¸»Eød§ ×–&;Tj+²ÒêXZ»…ôOÎ;˜ Õ¶¤-³8·Ó^Ò²
djPØü%Ë–e[ƒÓÜ1 ïÈ&£ÂN”£ö÷¶wß÷w+* pn@6°·)mKÑŽ
l‰m Ÿ"«0ÓÔ–Í¨^â4H¬…Âlÿð>ÍŽD5»iëºlå!y«m»eÆ-F77w^ñ,\¡8Q˜PîÓ´ù÷?(/¥ï`ƒÔþÑºc˜þäò_¼ê6ÈÿMMÑ2óÜvyÿ·–ôü/L8>cæè«¹Iã×iÏÉ‹=»K^¬lì¦|ÃëE‘Öwx¨&öò7ÒŸ9^¾Þé¿‚:}ƒÑW±Lß§Dél`ðòÎ‚ÀœÎ†ÃMÒ¿×tŠ®ÇWÞiTH¬óÔÍ™eÂ÷-‰$üÞ€—uÉ»m%/=ê¿BWWç7°ÿBà­,ÔÞµGA\ûÅ¾áÛüÞôõŸdÅëð/ÂâÖâ1-}àÅgSŒ-É!1«ÐâVÔ“Ã{pÆF-
FÂÌ2ßê†4H¬ùŠ`C5æœ;ÈB‡Àá_NWâ' Þ‡·‡û5µ.ý}åSûc0¨­ £ŠQÝ¹cOŒqð³Xš4„ßwûþ*é¯¼³µÈÓZÆåÌ]¡½¦È$Š‹:àÌÇ{bÓH¿ 8âVW‘“yfv–î ƒ:8cã%1VÈz$˜Rþžn‡.FÃGÞ‹D‡Ùá‘G0Ð=‚‹oü"À)A»ÎÛ<ŽÞ`#¢Í´3>HÂ(Ð¶-<Ú-³x.¿e¹ÞÝþþ`û¤|ðnïç-ñò9/u‡K[©¦pÂ
æ^†>5Ø[qhO˜²ØLÙœeÝÞ1˜9‹C&êÞPèP,mC@itî¹5â±3>\ýZÚÁ¤Ðµ”zeaÿòÆÂ€E»jhà±fèO˜ÁŒc	€i$
>‹EÐ‚ÿÇ;Æº^Þ¦G€‡<LÇƒÍ»6o¤lÇ2m¦} £D„—÷P*ÂCÎÓÊMÜ=)>g€w<¶G„š¬†{°pá&¢*¥÷–0ê{}å»é?
ùwOé)1såü mÜÌÿËrSÎÊªÞ”Kþé¡øÿ“ ž¨0O
xÚ@Ú¥Ö›Ð­`äõ‹©;2ûÃyn9 ^*E
p{Âñ—$BÃ‰#7ÒûËºk‰B†>.àS)D¬¦»ìîû-8ŠL¬
—oç•_8’?lõ> ¤•wœ«Ã¾ÜÛø4ûç§Óî§Ëù…»Ö‹ØÎ¯¿’¨¤eŸöàkÂR}M¾½t=n“$0{‚Ï¾${f3Ã„¯·iidf›Ê€YÙÜ-_b¥*”=-,+Ï†V§IIÏLºœé‘‘ýº£ ×ÑTh£l Ùg3$î½Ÿß-3Œ%¶Þ¿¹-BøL¼½Ý9bgï(žÞX°øÊ~#CR"€Ý™Û ¡©v :‹dL-*ñNè5ú,yCøœ âÃA%¸Œmh¦xß¥•Y´|³ÿruÝÛ`?kì€SÉÝx€ƒÔ
­sVx(tF²_…Ù0C ™ÌÔ÷k„ /žŒÕ_Œ²^\¹Ä‘R‚RÕŠí¹´ú¯L›Uö6,›ˆ+ûÛÿÿÔðgç¤f‘¬šQ¾kØô¢áÎÆãß†h:V» Õ.9ø¡úfU¿Ñ%o¶ööww^4qÞÈÅ0ÕowwÕo	ó|Y'5Ø!Ÿ^’¿Úˆ™1TÅÖªäÓ+R›LGn ýöÅ˜aö¥¸w“°o¾\8ùŽþfÁZ³ÿ‹ÔEìÆÖÎïÄ×ß|$½ÚúÑ%µ3ySëÀ_ŽÌLã ×) ÷è–%òƒ¯Ií(õÛÐïhè4=­ë¬rQ`9>Ýv•|³T#	ò7ÂÉÄý<™ÁÌž.2ç–â­&EO£’Âžž|Ê€€}½ Pv+ÊŸÎ-/ß7¼¤4óÄ*TEâÆ¥QKáŽž/¹©R¸ÁçKA®X*_Bøê™i´¦0fûÐ‰Øz¸V‹Ì"	[Îød²R´"®Õ‚)l­[ã1ü„qÙ;ïIÕr{‰Ë”wÌàrZ¿G6ýŒßí“NL}ìE±q­ÆNÁ“½(PX˜‘‹hãèÌÎ_Ì‹—ÑÏW7'ê‘07ñ‘£tèÑd¬ëâoþ‰Iq&7FÄ/‰_ô`ELQÖ¸ÞÛûš¨þtÎòÆÞ´gÌ/.ÐÛØGMûû[Ç»½m‚…1ùñ¶q¡âRfü=¡¬øÌ‹Ç8žò.Œƒiœåó¬¢þøã°8böf€‹Æ¼.Q¤¨Œçóò‰ÝH<Ï&üÃl’dfsöšÈ@ÀjÒÍ«±Á¦“êt¹êÌ<Z¨4µ ”(þr0{jÄYo#eÌüHK–5>;ÜÎÀGèÃ¹1½Šº•#œPÛ#ÏjÀÜQä[òçe>æð#¯·q1Jí‚¡R*l}÷X©XÍwµm,ÐÿPe5kÿ¥©ªVÞÿ®#•÷¿{ÿ›R®ÿC^‹&û7Üg¯‚EWYåupyüp×Á·º^|¼ë3Bžs'8¿Ì3ÄÊq?±û‡µ×Nx/óØ'[™n“Ë¬‡kc¡ý¿¢fø?E×Kþo-é9;`…à6\CÈ<Únâ:yü „X„ôf‚™ªÙs›aî»ëŠrµ0÷H¸‹¾µ0Ät,63É’²ˆ°›ä`ÿÙéïîÆl*Ï—ÝéHÅ‹ƒ~weµÝéÊ@pÝ&¤n»Ü?—(XlX¹Ú6¬E—›Yýÿ–RÚÿ¯%•úÿ¢ÿŸ5d~ª’ß€bA­´ xlimÅ²Úz$µÊŠ…¯ßèÅ¶{ðf5@ï²ÿcøìUŸ)ÙtûÏ–¤–öŸëH‰=ôÃµ±üü«òåü?|Êxéy6î0ÿºÚ*ç)íçaÚ¸Ãükz¹ÿ¯%åÜ=@ËÏS)Ïÿõ¤9^¨VÚÆ‚ûY’õìûS+ï×’ž§¢Q"‰<ÑÇ¡h]›8qä„‘C~Á¢ÿÃ	fj‘_¿Åânå×“ÌŠ3BP'>WW·˜ººø‹@óÚNs¿R9Ü:þ¾÷ÿí¾`¡®ê±"v˜ÁÞâ";(ÇãO©u–X5óøó°Ûó~Wï*é‘j5î=!ÑÈ èŠÃª‹¥©•€/tìSV€k.ïáÛxdÒÎúTXÅñYNE>ìù$Ú…·PS¯"ß›MyÜ/é•…•ÿ\wßeJñÿ‚Ï¾Õ¶±üù¯)M¥<ÿ×‘rþÐ »ð­’ÿ[Kº§Íûµ±€ÿkJ­Œþ§")Zùþ·–´Òûìgñ«ß³Õ^”?»Ë»ß³;<ü=@¿SO…«ëÙýžÿž-|ÿ{v‹Àg·||–}ä1ßÉõìœÐ)ôr<¦.±Ãx…\}äúYæ=ðÙò¯yÏæ=ç=À”‰zÏVý¢·òþ2€¡ÄGDD­¥¢€óÒM¹µ™ôjŽSãjÔth7~±pÑ)Jš
v–1ˆæn¾ºÕ¨JNO‘tµã
ù˜½X!ÊMÊ}Ð?~¿õ.].±ÀKàåbð2xû5U&º6*ƒ¹™r©0¼q9n—ÜÙ;z·õ>Û*ÏMJ¡¼·“+Ås¿²iL›©âšÃÿÕ|Šòù§g £ÖjìEáÏhV1®Vuž–h5*Žþzñ* £’Þe¿¦Ì¢ªâ\D%M ÃocÛ˜2Ó,Žt1ß>0LG™õå¶çºLãL,Åñ•Ã#-`£rÂ®ÀnæEAbûtìôGC—ÚÛtàuXˆ›ÃÏ\Tyø|q^‹´(Âï¡ëcÏûóK¹^m2õÎ'BÆáÔ›`sÔG<FKteoÌÏÊ+‚?Tºµ[ü{´±€ÿ×[RÆÿ¯"C’ÿ_G*ùÿõòÿsV×Ó~žù®Ç#ƒnÂÀÐkJœücè<) :ä“ý½7ÀGO™þŸuJlÈEŠâ 
Ä˜90§3‡ºõgY«±×tÿ³©CÎ×eÐXÆ`ŸîCó@#8&É%ÚP)“¬°¿€€Z}ã“cÚ0ç5õ­SXÜæ$²åŽa­»„âÆ âhB’.îtZ;Ie*P3_&P’b— “Q(Çj ¦ t#6`«ü€Ä#Êß] ÓK:
€¾ŠêŒ\2Š1€Úk{®M¿Œ^~îÑ!övN} /`öŽ§#œgj­ß6,tËíEèÞ„ßG¸°wÞûø›«í>«xæg`·Ç°¹vÆhp0Ò©ï¹™o“¢ÌÀ›drl¿f9C&Ôl·†K>SÂ›7ôìjŒ£¶f‚üÐ%ÿé÷¿ßÒdåëñá‡Ë¿÷/f#Û:ù÷‰¯w|çXŽ?v.ßÚ?åöä¬qzvyñó›á•½õã÷»§{ÎŽöÿï^ÆÒtûíõõåÃ‘«5[úîäíëÆÏ»ö?<«XnW I?õW8˜Èé-eÎjÌ²bØËGH¾5”iº~ ŠÒ	+;ÏymìygÁéÔ›Okð÷(èø¤€?º¦é/ÃÑuß3¸è¿Z©³‰<a¨¥×N-®{Ò.}ìq¹ö‹×~¶–\Ï†¬ük8Ð¬Ó`4D1çç¿ÆçÿavY4SOtÛøáÇÏ{ùàí»É»¿ÿðñÇïéåì‡/Ôêÿúé§Ÿ‚kýgWÿ|åììžŸï}?þñã¿¶>ü·ë_~þû¿d—w÷Û—oÏ¾èGW×ï?O¶ïýï[çÿ>úá}ûßÊ‘Ä·YBÏ~úÏ7Žt¹9k~áv!l
')€Ù­/¾ ßQ3€=-.Ágµ¬š}cË)¬‹âèKÂ¹O½›ËL)2:ó ]¡Kªšaçt—ü¸Æ?/.ƒ~êkþ•kÍù<Bcxe„Wb xû|þ¥æzÁÈ¹šÿ}>ÊðëøB™¡ÆÕ`n(ÀùÜâçÈO^ÍETäØ±Mç€H28;Y\Šßt±Y3æu&,ãŸÎÛ»,&ÄâC1Šs´5Ü0Ïì“úýO¸?È•Ú-Þ«÷?šªHÙ÷_M*õÿÖ’BûOÔÚ{ Æ­¼Êô;}T¸ÔžöUÖ±Ç`86®ƒð)8¼ Š<snöä|H‘}¯“·Ó™kÇ<{ŽŸâáµc´o<Ä@ntKdÌœø¹™9…àä”s ”ã]…nÍð°o“ÊWêºbq[Â×«{Ÿ2f“è{cà’‰‰ë:ðÃ;Ä˜Î¼é”ždH5ŠFx'xÊ$;F5}¦°€ðŒ™ÆâK±‹Á:ù8bbµl7ñ6ÑgD…ü	ÊUH‰1ÁÅÍ@FLñZ3îŒ‹ Ñ‡ã%Ö
6‰Ó4aÃå³®G¨X-¥úê'%r”8ÓíUÞ$ÃEUsEðq·WÍøvÁžY.Y©+u¹$/Öž‡ñâÃ¶‹¿ñW×BÏñY‡ès v/•2Àwý¯B?£çbÏþÌB*Óô„‹þyñëqÝŠ¤?ôÐçH¦l¿¿ßC/$™ì£ÝÃº$IXÏYÁŠ¸×íû†K †½î¼9þ¸u´›>ßsŒnÕ¸Hh£‘«5À8UP5úûkcS”{óîcª˜s~YPêøÃNªTpa7¢¡Ç.mö’0†À•zÅþ[ãR09X*”šÃL®Ðµ-bíáñŸÛRD¢U\ñ‡ÝŸúÇG»K’Þç3?â0ïÇl>„úDèýû½íp=ôªÑ¯d¸µ
ÿÄcúÞóƒ¤qT‘‘{LSF®¦rž«¤sUž«VEñ¨ûþ4Yj',›nlþm,ÒÿÕ[­òýÿ‘R)ò­Wä›³ºž¶ÐJbÎÿü?þ¼²5óá÷éybQü{mÀÿ
û‰ÒÆ¨P3 „:6¨$ùÌ‰P1ñÎ“Ìø$¦’3”¬kqtˆ€×‡	÷|düç Œž+2àŒ±ªÖCAdÌdHàé!ÛL´˜ÞH×tŒ¥ZBN¾-WÔßGT€F’dlTÀI
køúŠÑc5!›çcY›$Ñ†±Þ³
®Ú{;’c5&FÜ.†ªgG„}_íX=;øÇÔÐ^¡æuDéRQnR.™y±\’Ëµ´yÙ-ÛYeî„³Ïž:ªL‰{®ãêAó7ŸÛhSO
4©£Ðyî\P‹BííPw»æ éò€iœ¤	-õZ¿h˜ñþ¾Ü ³úÞ÷jN/û‚NM8.£?ã€!±~9œ&.R¨ÏÎüƒ=8Ý’ÿ¿—ðþ_QÕœþ/ü,ùÿu¤’ÿÿðÿO_˜ŸAd7Ô}BÆ?«ýKÎD¾i]à9‚S©ü$ôPw)ÒÊà¢ï.áLÉråeà-RþüW|APjÚ¡Ýëp¡ý¿&gÏYi•çÿ:Ryþ¯ûü/^]Oýø. ÑUv¨’<¦a[ÅÇ®É$H±3æ‚Œ]âá~>ÒoÌûçpÜñOL’3u²åÂñ3ÆË:€Æ¹¡‰K8M¡ŸC®¦HƒòŠn•ý-¯èÖ{Ew®Üe8Ú5åá®ën{ÕµØ/×‡màÆ/º
Â}¤fû	D@JŒ¾?,!î"±ëk<³éë)t‰]ÕD=Oîr˜šúÞÓègÖ±+‚‘Ý]wõqç¹çB8æ?ŽŽr™.Ý–ÿ¿Ïàþ?ïÿMAÀ%ÿ¿Ž”›Yá¾†mðâ\½‡¸Hÿ_Ñ³þßdU—Ëù_G*ƒ>­)èÓëê~¢ßBÉï‚ß-å¾9bwýÆo~¹´ÇbûqéõóÑ.÷<c—ûÞ³iF
\^âš'p­|.ŸZŒ§•‰Z·–´Â`F.ê"§‚;Þs8¡7mWXBó˜eå—[jÜRÙ@(&çtXn
”ZXFMzuƒÎÂ­UÄ‚G»‡yX˜»Y±áVB\%,Eó“†K"ñ¢æL½sò‚#+ðø/ª/xâ†m|ªð·~9ÇŸ÷áO?ÑÃ¾$ÍT-xÒ—³oú šÏï_Z)­ÜZ) -æPè1Nº‰³fS*¬&¹¨Žrs…Õ	}Ø%ÈÝß€¤Z}Á5ÚyXöJ‚þ‚¨ê÷>ÑAóot}-àŠæø¨¢º)ÍDäÐçŽðS4å	³ß¡~0rÃíEœìÔ‡LÅbc¦Q»±XñÖ¨]1p
3ŸÔN#D@C“ùtxÕ=^éDy!±’t+ÿkÿ­+zVÿ_ÒJýÿõ¤òýïÑýÿýÑÿÒ^À§‰³©%uüç¸J¼«†¸Õï/ßWØßòýð†÷ÃÈá41ÛRÍêØRÆá·úýG;_£XVÏ*¼Øx¼bøýòÛ~Klçaò{/^wI6½hÌ¦¸ÎÎÉoPÔl‹T·j?µk©Ö©B¦ãmR»$²œR˜ÃšKäW	0ìë/ÐÓç>H%CJÚäoƒùñ«¤×#ßüÀ~ý&À³YÐd‘_SÃ‹R(ó¡Á>;*yÇ–8F:³ÐÑÒtdÞwà¥«š°kœ%YåëØ6‡ñ¾òð7auEîÁGî–žÐ–3â¿mÏà€ï¹vª",üuÀ,ûÉ‰Ë–¿ ˜ÑgN˜`è!Yn98ÜRD-¤›+€­'Àßbº1Ežôw¾’9Õ¶ÒÐ±š_]-Z’™bÎ®’rÖ0Hò¸1GgISs\ÏÁåý]öâî6þH±­WÇ0OOÎê÷kÞô0öK+6íyÇsy–±q*í˜î™J¥”û§ÜýO($ößÕ'W«hcÁýªêÍLü?]ÒJýïµ¤UÉiÙš=×™>ìV€§/÷ c3\ÿ1Ÿç³w2Š_ík|ªvöFJ¯ËJ]jfî^æ\± »aÅ¡±úïÈŽwnŒÜò}¥è®þF<_ˆÈ,Þ5\D·*6Ãÿ€Ë,õ V=,[ÒàåÆÎÁ»-à´‘9ÛØ$UÀ¸>àõª¯" <-o€ÜhÌ$¹Á«ù¿süW"ôâU…É6€âÈ^f¡†ÒpT—$¹ú*ªìûã¨þM•ê+I}ÆÏN"x`ÅKjÂ¬jÜqô°Õ­¦e²j¥R™L±CœðÙ2¹É_þêÿº‘AÆ·™â‡šsÅq’â\ò9Œq˜O°›-<!¯‘-¢3©p’à§<â/)ß+Ì)ƒÒ@ªáÖðq¿m<‡í<ç%ï¾>Æ¨ð°™ºÜà)š§'¼Z‚›j!¥ˆ™ÂËMSï…Å•àgQ­k½žv¿ÀÎX:~ì³÷÷òúŸJ¡žš²fýÏ–^òëH¥þçºô?ç¯«Rÿ³d]WØÙRÿóéè*…e”?³þ§ò{Ôÿd[uØ¿RÿóAõ?•ß“þg4Ù¥þg©ÿù‡LyùOð-UdWÔÿ³&ëYÿo’Þ,ïÿ×’Jùo]òßœuõ‡þFèZÃºÌUKtGa{"‰ºúþ BßôÞB_)ì=]a¯`Òp)¼ŒK¾
û3Là‹1p/‰/‚Ë|)]˜”Ø—(Â,%ø…ýLD¿â”-då¿9`2OËˆ€7×J	¢ÛšëÿÎû}dAÐ ˆˆyÿŽò_ÀNÚ˜LZVrËŠn	:~ÒÛÜÁÌíw)Â•é¦t+û?TE¼Gå¿|üW]/ßÿÖ’Jû¿G·ÿÃÕõ´- ¹±§»ýN…ùIL_Sw†ØF/9Ë»Xë9£Jœ·LEÍL5s7Þdtöä8ç¬£WðOáÌšO4òãAb“dÄF~n•ßœ!œ¦tµ³®pLÆDUê4ÈÚg¨	,µÑx*W†VŽ=Ó×,x–O
@`üÑá˜Ö"-M¨ë™Ÿ¡;¢¡fÒSãbäM»†eÑIPš3®°¿€€p˜ƒR>šö- Ó†¦Ek[t‹‹ËP|†'èŸ²Æìsc*ÇÐÊ33˜kPaLƒ(>.³²…ÏèL“œÏ([-¸Ø_SŒ† ÝÞ\²µ½¿áÃŠ3p}Æ~õW>j¤z¤N V ú`êk0qö˜NcºGþ×&áÒ0¬Q·úÎû!Â
½OU¹®ÔÛM©.Ëª¦µêr½YoKÚ§*³¯xyA§Œ~€n¿%†bEuˆ2µ?v® YÅxGÌ#æ8ÞHØ
á½üTýEïò%œ6ƒ'€íB/Ð¾VS6…Ø&üfþCwÞûø›¯l òªú€$„=*ièh(FüJˆ(†¶˜ŠJ‹œ?oºeü§{I€ý¿¨yýO©Œÿ´–TÊ¿ƒøOO_LGx½Q¼¥œWÊyw\MOOÎ{gŒÆä{ î!©Ïoóió9ûyã„Æ“xLà:ˆèŽ=Ë#Éñ¶Ü	§gäÌØÔ²gø­ vst
H»±ÀlË´¹á`_&ÈWÄ»´Dc#÷ÂìšöÚ½rãKq;©1ïp«{ûw9d½àGn%j¼k©vÃ,nŸŸb‡Pªb'ã h–ì6vÞï¢“Þ¹FN$ôŠûµ]zxÓLÇâüTß’\Þ½#-îÝÛè{ÜA”Rb @ÚSÃ
@Œ¶ºþ„Z#cÜ­þú8ž¸8_]c<95ºÍMwv4cuÕÍ¨¦²™ÿæðA¿§3šÅ?& þxÔåÂbtÿ÷,´NËÎOáÔ"×s!ó¦	Š¡1bBôt÷©;Nk¯ÑÒ§¸ò'ò!*QX?&ÃîL´'Š†¾’àÆ{{E¹£Ýj5blÒÿ~«&§:	ë÷Ì›5;\]É/úìÀ|¬›™tÕ<bÏjâŒãfÆèP,{k(Övu]ozc›ôËd.Ô‘Tèì¶2u2-×¦ôß38ç@žMáøH0Ã»´ü:šORµNAr¾3A³úVIQw¢¨‡'>ÿÀQÒÑ0ÜäÓ›ûOkàA²û;ËÇºi/„{®=º¦_àCH$ì­Ù&tØ¦_BÎ©V£cŠ¢§1~Ïóä˜‚ò5ºF \Íûäí#5ï»?3áh…36.€Ùü˜Yq&¯ÁzôÔFúŽpOØ0ÈÎkŒp’'¢pxÜGf¾Es<6ú:49×|]]Ç›¿ÿù¿ÑÍßáGa6Ê›¤'˜’ûà“§^€¢Ý`n
VÖÆ"ÿ/J6þ·ÜRåòý-i¥ÏÞ =Ý; ‚[ X^Oûºg?Ú+HJ¦ãŽJ£Hƒ»‰ªpî^‡#¥¼gXY™“à,¦Áï
ü{dâž%q÷ü©¿—ª&dÔì‘1t=?Y÷³t]Ñ{¯üîÒò&WÀ6º–Ð(çÙ/?ôbKéÙøŠÿ>ùx¯á…>]9÷ôð£ñÅ>ª§IïžU¾"gtGYÀ…4²ô8wÞõw/`ÙƒOa­Áö% Ö(~[yÌëhÝ>÷ë¸Zôf8€ÀsÏmØføgsî„·œ‹ñÏ‘áþ±Ç?AšËÿ­°üŸ"kýOYÓµ2þÃZRÉÿ•ü_Éÿåçë©ñûohÅ‚¸`êÙ„ŸÊ©ô.‚ÜÆ$ÿº™Ã}ñQ®‰G¹$±Ãü±÷¹2§¹ç?.¸µ±üùßjIZyþ¯#•çyþ—ç~¾Êó¿<ÿÿIÔÿ…M`Õ¢?K‹ÞšjÖÿSWäòü_GZñFTy@OÔPÞ¬®ûüÏý[û·<õ³‡þ6lŸ=“¼™sÈçÏøåøy'üjç¥ò”\û°î®!Îl<&œ[ žÃÜnLg.j¤Dºé«Èzòü]æ`  ¤£ÁþÁöÖ>s~!00þ)©äÍÉþ>©ãÚù§75€NêÖ)ùŽEtq Êw“+€$ÛŽF®5eZ3Æã¡JÚT6ÕÍæ¦¶Ùº%ÒöÞoí¾Û}¼õ˜¸ãüæñ¥(_ßÌÇRÈ#–¡å±Ïæu¤„ÿÃhz—cÀYë>Ô³’6ñš¬dã?Ézùþ³–´²%˜eÐ~Ç °¯ÈÄÔ8kÖ%9²¿‘GÛL³gÄH†CËy’:uI¯“,ç%×¥,—uâ³!Þ£ôß…ÑYÐ°À$F€ý+èÇ¹Œ#h8Å*FŠ#»»JÒ1°>þkhoHºc„Ú$lw2Ï4-Ü4´"/YO_ÕÉ–ýÖ ÓFÝ$Ã©ç+LvŠCa¡’Lê Æ| ’QP¯<O•fÆh°‰cè],¹›úîÏlX“ü´“ÆÌŸ6Æ#³3üÿF¦ÐÕƒÏk4P8=*Ë Êgåpô65¬ h*¸}+vX}Q3}Øï*97Ü™1¾¸Ï*-íM–‡ìÌ\Ê÷îlåÜO~­ìP¾ ÑˆâûÊ^È‰U>nà÷\\zÓ³:wnPÙr:Íf’Ê/áþkåøjB{þ6	ZA3
t\Qy‹+˜ýúÕ`Æ;@/§=TÙýB-FùoFr©¹1ÐQ./ìM
Ê"s‡„$?Soô©ÕS%©Í¸¶1µfÁdô€ aVþny®ïA÷£¯»Ó©7Í~„1‡[Ê¯S(i÷Îgã`Äì%BÔ<öI~·”æÿøïÀ:½¯Ó7!-àÿšš’ÓÿÖ[RÉÿ­#=ÿ[<gÌõ*wžÒ¸Øéì%`j•=ÙA¼ mÖÂ‡@Î*fùNÆR²/¡‹ÖñÓOÂ³Ç3›Æ—ãqx<:ØÄk~¶—ÜÀ
:[‹™c6>ï|t}gwÝÚkXt—äÊ›«wE˜Í¸wN“©x„öaA ‘1zHw€AóO½ÙØ&® ‹O\ŠzêÆô
ê>`u’Ñ„¾£±1ä5£¶RR¾_ú§„ë€iRÂ8L¦Òb·y|JÓDÇ%’Ñ üÓÿ …µqaŒÆ¬A¡e4žäð°K1$Ìµïþþ`û¤|ðnïç­ã½ƒ÷ ©ðR‡žïD>#‰NXÁƒ£­íý]öÉB<"-¶
^ØÏDDÚŒ–¤XjÌ$©aL&¡ú7‡y²#LÃ„qßPèPlgëx+%rŽHÚØŒ¯ÿ6Óº~-vŠÌú(t-öl?·Qg©;ÆpÀÛ?œFã †wº‹aò‚â¬0Oó9.˜Fbã|dÛcziL©úÍ»ø;fì5Âû×Ö‡-±£)xŸ˜É)¬XV4zøO¦Í§hupAÙ¶5¯Í Ìî5É¼Ýãíà!¿·˜XX#;Û#øf	òòl(pv˜l3Âq¥÷€ãÉ¶òÝô…‹ü»§tqœæÿÃÍ®>õ'+lcÿ/É9ûOMo•ñÖ’~Ù}ÿvïýî¯•#êO`¦üy÷÷XØ“ëÿOå—·»ïwö¶­ôw·OŽöŽœÂ¾¸Û|ØÛ¼û‰o<ý“Cô~ÔsŒñÊôGËôp©Hþ_¡èÏÒ‚õ¯·t9oÿSêÿ®%=”ü_ªt»àài_ l§´ÙÉ|[È`ã‘á³×1UJà©dœê1¡æd'¾˜öoB	~á³Øø
ßŽl&aˆ¡¼íÍrüa‡yêq/ÊK„Õt—ñà}¿å/ò!ž×»Œ¿Ï\½q$Ø:ê}0Æ3ºòŽ‡ê(‡}¹·ñiöÏO§ÝO—òK&¶Ø¯d#*iÙ§=øšˆT_“/F/Ã‡‡âI
˜aa„ìq˜ÍÔR¾Þ¦¥‘™m*rde$ñ„¸ˆ%”=-,+Ï††äIIÏLºœé‘‘ýÔ`¾¨£ÀkÀ÷H>ŒëxÈŽÄÐ8›!qïýün™	d,±}ðþÍmÂgâíí†,Ü#ììÅÓ_,|ïüF†¤D »?2÷ s ð‚y °¶™PK§ÄŸÐkØ-¬dÍEð¹: Ä‡ƒJp/Ú-Ü–ï²L3‹)½hùfÿåêº·Á~ÖØ! §’»ñ )wâgKØ.Ûûë”]:Ew?Ìá½_‚ÌÁþ^ÿøk…Û«ð	¬þbÔ«Ö‰°ZÃ‡Pg,¼D|1ªVlÏ¥^	w€ËÎÆä»ÀF\è4*$,íäë˜}­Š;BUøZ‡äK`¿R¥p9åKAnª®®|)È…Rq±ÑiÑ 2½çŠ×ŒPÚº¹4_IyØVR(c3’|6Ì¹hÏMPoG1Ö†“ÞÆ¶$ãLï”çòÕ^ŸEßàêžÒñ$ÊTíoÃ–´¿²ro›Œaåcò;¹ãBõÞ~°IýX,–7ö¦=cxqb0fü}ÊŒƒiœåó¬"hþ8,{Æ‹o 3:©­¹D‘â2	µÄ›HŒ˜À Úçu¬¦I7Cès&©N—«NñY^¨>¥“å ñô(þr0¸g•:ð”ˆ‹‘×Û¸¥ˆ7ŒÀ0cTÁŸ³	'‹YL³ltæ¬·qÎt£jøN\äTšÄþ~Ãø“™ÐíBô>†ržËé|@ÊÄã´Øvþ¸A_‰³ósczuËöa
nÃ7¶?õ±EÑ“ð‹<†GQàÅ•4&—6Æ®_q0)Gâ7gcUwÌ™ûŸ©¢ÖŠàcZtÿ¹¹û¹Œÿ°–4rÑ	¬„Ìy/óZÈé!,PA¾j0äê]áCÁc÷¾L÷MÅú_LÒXÙ5ð"ý9ÿEÖUU-×ÿ:Ryÿû¸÷¿âZûc^ó.¼Î^£ð^^—×Á|«ëÅÇ»>#ä9	(È	8¿x³@VŽˆû	õØ?¬Åÿä¤[ÀcŸleºMÊña®ºEò_SQsþ?ô’ÿ[KzÎX~€³“›k¨™tSG/ã]ðƒ~ØßÙ:$‡°b¦*döãÜf˜Ë\Ç¹Z˜{$\¢DßZ¤+X²htˆ¥7ÉÁþ³ÓßÝ%‘]dåù²;©àµ›íYgtÚ•Õv§+Áu›ºíü	pŸ’öÞýSný×;»o¶Nöë’ÿ]ÎúÿiµäRÿo-©´ÿyûŸÌ*{²’ß bA­´ zlimÅ²Úz$µÊŠ…¯ßèÅ¶²˜YwÙÿsç•xe.`Ýÿ¶rþõ–Z¾ÿ¬%•þ_øœ#ûä{¸€¹ƒ˜%]ÀxiG6Y0â)ZY‡ã—³®^6cxìý»òðN_Šæúaý¾SWå\¿Ü¢¥{x¹ô;:€™»äùîÝÙ"0âÕÎÃxÌÞÁáîûþ 6EíUÙ‚CëÓÆgûL®·ëÒ@n)jÚ#Lúæ9º‹çžaj6²ÿž [¢g˜¹u¼I¶ÊHŒ†}«JSÊ×@T}uÎeÙ»Œÿš1€“Ñ ùß:f¬¤E÷?²žµÿÔå2þÃzRùHŸívöª&µžìEÍNxI#øã‹ysÆà¹v‚à*uéŸåKÎ«ênÅ†I²­LP0DJß„?¼é°b[]gV<ó3Ì–5†?€§CÃ|ƒ¤¾À1Å!ZnÀþflJðÏùê™–¬ñ¶ç qÐiùzpÖÏ…Ì?/ù±7¿2•©Le*S™ÊT¦2•©Le*S™ÊT¦2•©Le*S™ÊT¦2•©Le*S™ÊT¦2•©Le*S™žhúÿy/ç¯ ˜ 