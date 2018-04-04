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
‹ X×ÄZ ì½ÙzÛX’0X·ƒ§8E+Ë¢›‹$/Y%§]MKtZUÚZ”:K‘ „4	°R²ÊVs1/1wóÍ£Ì£üO2± IÉ–³²ºÍ®N‹àAœ-Nìç4NÚ¿ûÂŸµµµo?Vôïþwmãÿ+µþpãñ·ëð¿'ßªµuøãñïÔã/=0üÌòi˜ÁPò4ZØš‡~—y˜ÿI>§°ÿélpÓ›ÎòV~þúX¼ÿO}Kûÿ¶ýá£Çaÿ=Üxô;µöÆRúüßÿ{¿o#
œ†ùypO5ïîÐŽ³ø"Ä¹ê|ßP/fyœDy®¶£‹h”NÆQ2UP½Ùd’fSµúb»W‡wzateQœO³0Ï#µñ§†úãúãõý(œNO³ÙÙYCõ.ãéß£l&ƒ;ô~8ŽZüÙTÞÉ€;³éyšÉ½i4ug£X­¦Q^W9=k¥ôì_§² ­~:†·»ƒxZý6ü¸Nm¿kël­=l­ÿ~9Š.â<Nú…Æx8Ë&iqÛ°uª×ÏâÉTMSuÁ?ç‘ŠxÒ_…¹Ê¢é,Qýtá<Ói”ëþŽÏa—r†Ã8]©YÔ0ÍT”\ÄYšÐ–ÁÒŸ§³©:~³Ý„®á'â6zC`çÓé$ßl·Ï åìçÞæõÈ‘Ò ¦a÷»q?Jô¾?Üm>l­ýËÝm&@ÚKñ0ŽØ|Í£HÁˆ`x5LvãŠ&D¿ŒÒ3ší8ÍpùàÏq8Å–ð¿þy˜œEù°©¶€ø¤ãøïÜÍ§BŠÞÓ	:x½}rtpp|²½ÿlåƒóm³Yl™žáyj¥ÙYíš:ï&•?sÚTž¦êM8šEù'N$xÓ=êíì?«]¬·6Zµ`û sxØÝß~V;>zÝ­©eŸ{€¨áé(âŒáp2‰€F ä½î³ÚËÎnï6€.¢ì œ™ÞÖÑÎáñÉ~g¯ûleñ8Z¡VÖêÁñÞáÉöÎQwëøàèÇgµöt<©ÑÃ—;»ÐíÊ¯ÁuÛ½µ²RzÇ£ã“WÝÎv÷èY¾!‘aga—V>8½_«Õ7QFH¼òAVíºÎˆ¼ò ìuvv;ÛÛGÝ^ïœ¸M³Ž]«tŽŽž­¯zÇ0‡s@ÄÆóö ºh'³ÑH}üõÏSµ‚m°·:¯È+i¸ÈóyÏ ^Î’>âÞ§âƒº»ƒ9”ñ¨×yx­ÖÕ‡"ÅÝŽóÉ(¼âwØ3.´AUByz´îågª¶³ÿò@mr§"BüÔ<¿ÈT3VßáÁßÙüÙßê>WÍmõð÷Áö>üýÿ}„à2Í/á„<W?Wu¢Tó¼ê`PçÀ^G /‡/sÞ¾¨z»âPÍy=«z½õß…Î¢É(îÅšÀ™¶ýhl½@lÝTýäÙvœE}â{a³Éæ€«\¹ðDMäÑ›9o—v?ðDí®zo7=#¶	[½{ð=’knÕOðpýZ5Ï¦jMýü~èin¢0é$ƒ›S£v+6®éçhÌW·+PÅê÷×=ÆÁup§Ü¯òDí1R1)›Æc’^Æ“/qºiµWëÁšßÎþák ˆÖ¿Ù|p]…|ô‘6|)`³+8É™:àŸ¯iH:,5º¢ !ÈÁ*T	H@Î	±>7p<³5ø¢j@‚wöº'€?{‡@· +ªÚ¿|ócó›qó›ÁÉ7¯6¿ÙÛü¦W«?}ê¼zt4ÿÕdÉËÄ€àíOè÷à¯5âÎ«µšÛàÿî5hU|ôKQö-æ×ˆç!æ^×Ô3%²Añè¦Z†XÔ–ú@ž‡ŒÚŒ	Ð OM}œ‚èØshÞôÎÓb0¦%ýg~§æÛå9žw5vû{/uz]ÜvfvX…‡KgW9ÃÅà¼¦ÎLË³¤IT¦Iw¸mÏŸWÍé7¶úÕƒ¼ùâÝ5]6äÑe(©"É¦j68D…)zOïXZÆè*d%Y5!ÅëH†Móµºá±HU³–k—L­;Í’Bó.LQmÔB [êÐ‰ÏT8Ng		éav6C9o©ª±2$ëý4C9É¨åv±qÓ.4`µŠ¬¼~Sø—Âw¥ µ@OÒ)mhŽlŒ”ÉãÎ‹k]Á—£ÎÖn×H3'/:½ÂÂÁB/í•^£~òhJ€½‡áEPZôæ³¾¾òV:Â4õÏYÄyyË~0£4¨·+^ z´[z.¸‡KçÛKËwYMÂÄ¢ûþ£¥ïw³V‡3 éÁ}éløuÚÝl–$(·ˆQ¨ŸŽÇaâƒÛøpƒÜÉ¨ÐB~´ò,y—¤—‰±|z5áýkÀ™Nh	Xà	x¸ü^œç$´•w÷ÐÜ}‡Ç%káº¢%IÄ÷,Ù(’…å’Æ4P©œBsê<|~|Ã-ƒ³|älRŽÂT¼.`t´ÔîÖ¢ee	h^oÃ·6´Ï+jÞø—î öö »’<•S­×ÉìŸþT/èT™åSu&I¨rÐ6ÎÃÑ(õÌŸ—Ì×‚¢4¢9jkëÏu‰mùc:ŠÆé(ª L­Ì«VœÊÆHÇ^cšÜƒ"Pél Ï·…:˜Eh†3”fa¼˜¹ÐÑd…æÙ&¿ù …;]ÕÛÖÁŒê„#+¡õÄôxðòóÍ>l=ÚIâiŽ>Ï†
Õ‚³È¤6(ª¥ÙU …?ÝŒ…?_ðcb³"Ï(aB«ªUY(öòu£‘c ®fìÐ±>ñîùÃU?Â/¿WÍAágw€^¯ëkÐöµ‹‹‚TÃñ	-å@i‹K´òó"QQ=@àýc%š°:‘‚ÑZ
jšâJ}‹À®#ÎÕæôVŒö°eÈ?Ã™üO” Õþ€Ûs©jŽUÅ›vÁè˜ð×cÝíÐÑêû$“0ÌÆØþÙhÊ öÂø“ý¶O³p¢jÞ„­ÕÐúB`µƒ4P"^HÄfï¯XÁ>©þäÑ„\ÆU“õ`©Ï×Y4M'€¦þû“,Åã†|Zäˆ®ì$Ì 	¦h¡cMMÞVçñæöæ/›ÝÍåd£°±
 O\à¼.&Ì5‡è_Ôš„ó[\W{W.#zÂÒ|ï±àmlÇÇ9-~Ñ-\#âœ¶Y]uww¶:Çä)Žª[÷±±ÊŸõd7ÔÊ—Q‘öh¨ƒ??¤%šVX‚Â‘–E9Þ'S¤Põ\Y?ÄÆó?¬Øˆ+†>ÎIFR2_+²t¬¦ çÓ¾JgôÖì±*MÛÐd4E©f¸HŠåÜNÈ1AŸÃð;šùôF–Á¸šNŽ<„pKaªvTÿ‡?¤XÃi<¼*KÞHÌ–sÁ¦\àHŠ¸-˜#‡›ÿÜlÖ*-ï×ÎÞÑ¯ºÈÊ‡Ã¶eÙ®-ëý½0ßò;×eì“À‡e”V‹|¶¼‘G³DZ@Ó¢tñXÑûÒºÙd_{s˜Å`ô<IÒ&¾ñdJfé$Ê¦q”ãÈá¯Øö>L‡»sT•‡†Ódß«ç>ZÃÃyçLö¸â°áy®fá¡+/óº÷Šf¤Ópð
éötèçÀ0Âü?pÁ#Ð³K‹

R3V÷óößVÚÍö}÷¨ÈÛ¿¤À7_„ýwðŽÚÙfÿÂx6šÆtc`Šª}@B2hgÓèý˜•ö‡ý§yûmÒVí§×ú ®û´´ƒ¿IËMpå§Ô["2Ïôh„õGÝ•¹e _"ÖöŠ{¸z²<Œ¬¯î—š‰:xã¨kúWØkP¼qT[8}R¼V”HÑ×Ô¦oÕåsQ—C´=²šÌo¡¢‹ªîîvçþÓóŒ¸þÊ1« »ò!vÔ¯Î=9@ÑjxùNÝÑý~gÿÃQïYímÒ|ºìKú³ötçûý —Àðž­?eñÙctÀ­«ÿRí¿uƒö©,ce½ýî>ötÿíó¶ú \]yÈ»<%x^8kOÕ5ú†>6EÏ|ÌPu3^ï8ë‡§vðñz¥ÝúfÛXÞÊuZ¹¢¹%3 bŽ|³Ðó¬vTtö~ÝÅÐ.:¦s"¡K8€t™OÀÉsÌù<«Pßhx;FJHUõþRFJFØ•ÃÐm:Û{;û.oœËfÃÁ8NnÀg«™ëÜ½œËc½©-ÚúJvû;ÿh£Ìœ,íîË1*tòÑ9Vx–6kOé¯UÛI»Öçä[õûÿ‚s²fÁ}NoT”O;•Kä£üF%ÊÃ?Ñh±PÝÛ[$ìßR²~}´û¬†”›í6š†zÇ×›„¬¨;åãvU¤È–cG7TÑL
0º°Ól–8’ŸeÖ™g‚¼7”·…•¦rBûÿÓÉŒ$$ ò _QxkY¤¼úúûòPÆb·£JAzô¨¼¢¤ùÁ,Æó¹6”æ?:nû®>:þŸƒHÿñÿ×¾ýö	å<Zôð!üñÿ~ÿÿ5>_$þÿŸ.ö¿*îßœˆŽ¸‰Jk¯¬+Hå_Cþÿ…ü«;ŒàW_Cø1„ÿÅß×jŸtïÄÜß]È½úMÆÜÿJö¡ýˆ+Ÿs_
îî=WÍ±úÎAxtó{vØ¬~R„ýÍÃëËcÞÊ(ºƒñØåsÞ.MÏ¼½Æ#%æ‘¹¯o«ï^ììo;¡ùHZ·a>dÝe~¶:`|¯×¯Ï×?üa•RÝÉ¡î³¤§·+Ú³0þP}×ýwTË;Ç¯¨;4‚YMät{=D 0/¨²ŸßJ€Ö¼®™xÜÑYüÍd ¨¯ _3 Ô×€¯ ÿ¼ _0á8ÿ¹	49ØÏã× D#G¼	ë«ä lÒ	J,…Ç›Äs›= NÔ?P!D*Ndý2‚5•D•¨	ÚòÈqŸb´”îd)Ij&ä^°TE\~|a Ç“„ÂEÀ|r$P~èí#=JTùqŒu
Š½­Îm'-µŸ¢ÃE9•O¢>+Ö%"ö5áâkêÃÒÔ‡Ó°ÿn6É+r.ÐtEòÄEý/ONØÒùY„Bõç×øÑãe ¶½wuûeO£bûòlŽgæ5‰2´aáteÉn—Ž0–ìß?4¸^è2‡œ%¦¨3¤ÃšJE9þrFLÇrD"ÔÚ#µ˜VKß¨³vŸ§—jŒGâ{Üq…žBÏæhF+ØÊêe_5Gê;7ü¸î5;FFµ²ºº"ï4éÆë¶%BWMŽ”Æ7®Ýpä8ë÷ª™ÃT˜ËÁZ£f/Öâ	.0—¬™À}õ?5r_/-É¿bÜ¾Â8ÚîþÀ«!RAËpšd‰4q¹õùþÜ! î$†_ýÏâWwÅ¯î0Œ^¤>öU &iœL£Lµ‰>%³ñ)|¡“‘X–ØÈr©p4 ÞçQ8€6Ø<0T‡ˆ‘Ä&q¹?o>öAœl6á­ƒbITj½ÿ«Ó°î>ø¼ov)`¸ùkÄÿ÷æ„ì¡¡cö_YÕz©nûÍ‚yûm£ýVµÏê_,w`ˆm9×ô0œžÏiu¸¡=©6&–McÊXe¯%¢Œ‚¯V(‚Ûˆ»D»|¹ˆQA®ãfKKW¯	gr²,p|.…­Œ'ª!d¼€?ŒGhîÈ±Á·­Ir˜†§•6âÂ‹ã½ÃÓºÇ[BZ¥\Ã²mèÇà¡y…øœ3QÁ°Œ Ëw^<+÷SÑVãdw‡üaLY.Ôý¿Ý»¯L®9 "@LêeÆê«µOkBk÷¶bêsà¼™e]Dß·Ì`·;ÇëöLfµoÍIv±±çOÇÏK“%X%«Ò×Þû}ñikB„Vb¢=ßzð¶ývþ[‹£h=Xi¿]oß¯;A•Ž]É¬x9ÃËT´ëìlw>Ë£EX-o0¿)ßÒÐÂ"›e¦î7î+ø¿ºæÑ’þšD—Ä4â¤°C•Ðmà9=¾&Ào\ˆå#ö?5#@mÎ\	3ãÝ4¨ƒêýˆ|#Mð}ShÁyÛ É¡ò³N'Tò©”!
(NÁ*•GVE;8ÚT??8OgY?òBD†T@7Eµý]<q×‰<š±WïŠø®®Òÿ²î¨8ý4™ÆÉÌ`£œ"ÿ~0¥¥t¿¿IîSõÙw'j£íö°ŽˆLá›xxxŽ¬—çè˜ÊJ3ñtÙ|Š*+lÿ
È¹0TŸ¡	Û¼ŠL6š(‚øÉ¹S2ž[²VgÕ¿@Ê•ŒÊ?6êÑz›¤«0¸æcà1ÑTê¸ÚÖuß&@Mÿö7É|}8_*†âG¬›áÌ&ˆ{Õ›+çb¢øzòÚ‡r…«‚ÓØ öÓž[€´Û~»çî™BJ\´mù–kWñt¡Uš¯Çï ŠjNT©}‘(¡V[æ-¼äX¸õX.o<úãÐÞñÊ´FhølOÂUðÀô­s†I8(PZ.t·D#>q))iÇðst.;°Ý}œž¨žròã0¿Õœ¹º­<iFÂÊP1CFµŠ\½©[”ä1ä÷ÙQšN]-°±,çþO?mžŽÂäÝæÏ?ß¯— fù²ßíµ³î½'ýÑl½È`ƒ@ßÅÚ{¢n qƒµ³ûí·µÆÛZ»¢}ÿÌ¶hÃ·ºïçœ¿ö9E9ŒÐ’ÎÎ¶ÚõMÁÑ°ˆ.ÝÁ ßÖÁÞ^Í"b=ÚÙ¿n3¨æh çªÙ4Ñi’}p£Œ™e VMs.Ü…Æv8T<6<T÷xœXX'Ûá•(Üÿ—of÷ë-„tÓ%Á[¢ÂN5#U{›”[ªççÒù”Þ¨xÁÏÂOe‚ËâI`>ŽƒHQ£³xü¦ü¶‰Jó•üSHB¥4Õ‰¨NMr:¯½º7=*âb#V$5©lrIñð4|o.g®'âÐ5îNÊÐƒ’û åV^Üå›Fž]«O‰i®„œ¾î§j3€Hõ]£ŠÏ­þTép?…ð„’<~*£Hæ/ÊÍ± ŸõÑd8iâ
Æ”Äùy4˜…RsrkÉn^&Éõy ¯Ó©ñ™G9ô,¦2-g
r.­N±>ÇfMöü;ÌbÒù?¬ÆüCò6®}kò6âý/6}ÍÿùU>_ódÀ¥üs"þ9òÄñ5ÿçkþÏ§ÀúšÿóÅóÐ	ã½»»|ø<½)/øl£­ó¯Ýîá³G7 PöÙó³ø!ŠÞåH,ÞEÑ$€S:Ay÷Y­ÙÔ/Û¯l[õrž}MMº›n~¥Ô¤©úÑð¿Q’’ÉªQÝÝyù:fÚæã)…Gí®;û[GÝ½îþqg×BÅç}§¾û¡ÛýkÏÂµgíÒ=k*L¤ýhÜÏÌ°ªï^t¶þúúðFÙIÅaéì$ñ5;é7}?É§å#}ÍAúšƒôÛÊ‚ùšƒÄŸ¯9HD¿æ }ÍAúšƒô5ékÒ×¤¯9H_s¾æ }ÍAúšƒô5é·™ƒ4Ý|·oŽ7‡›Ý/‘ƒ4­+vTæè¼«+r	Tÿúkä/QÆÛS¥Œ£PHÃ_åLâ0.ò¼uµà¿hÕ×aào×…›khÑÖ¿fê|ÍÔùš©óß7SÇÉÎ¸I¦ŽÄ{Ë[”[¢!.Ò$Áq„·0E•p„>Uç«Ãý½F5½"~Çˆ³aŽÎ±Ù(Uµ;I1ÿö»?œ ßiÿÀ±†¿þ`wÛþ°ºòÁ6¼n
&ˆOÅ¹Óëòq§'Ð)¼¤¼·Ô7h| 1¢°»Xô²BÅËþ&m—æŒÛDõæòÀv|½ÆÄ ÛžegÒ"ÝdJÿøœ­BÑuÇäø+¤lÍKgú´”-Y‰ÿI[%êú5i^2’uS2’•M2’m¡/ïr1åv©H.¬›¤"9íožŠä¼äºK©HKÇRŠT}i*’ ±Ž”2m+³œnŸ}T–;íYÆ3Âèx[I4p(°Õ-æ®»D×?iGÊ`ì˜—¥æ8¤ÀüöC‰Í»~ÈZØ”…‰92Þª¤CQo%Ù2Zz¸Æ#pƒ¥¸É¨W>øcq½9næK±U9!ÍÏc)½±4óÅÏzqOvm¥É0>« K·¥_xÓN4Q»€ªyø÷þÅð&Üvó‘¸‡ÖôìïL!·ö_ÎYL§ËÊ¢âRºíç7¯^2}#«ÆËy÷2U­YñÕ»_4¼%œ—Ì±ÂÄT“øö°þYÁÅ‰V U8‡}~®ÕÒ<+gÇ$ËJà²¬nža5_HzQIín•HõùIT·N ú5’§n–8%ë÷É‰S7OššçE¯X„ÊM—UØËÎlšbÌ{?„f¤,	öÝÏ1h1B6—¬kÒX±“Õl¨ V}ÂæÉ}ö#Wª¸Q_Zaö´½òžgcÕÌªÉU¢÷ê-sÙöSw
Ãt(»ŠFÊò¸Ëƒ.$b:ø£Ýcóm·Id“ÑÝ}"ÛÚ¯”ÈöõóIïZî/ÔÇâü¿o×ž<¦û¿ž¬¯?zôäÉºZ[øèÑÚ×ü¿_ãó5ÿO\Ìÿãñ›Îýc›ÕJÀˆ~mÏ)Øø¾fþ¶² uîž]Ù7acÌÕíS¦R‹B‘Qî‚3¯Š[wa:(’jÝáÔJéb[¼íÍWîÕWbŸB["êPhõ[ýàÔÐ¾Ð{uÒ;x}´ÕýiíçëZ½¦žªÉå TQøNïižŽfÓˆí› 2²ë¸‘âª±O388êÀ?'‡ããîÑþ³ûû)lþ½Óü_kÍ?4~°¹úüÿÖ?<º>X}½ý¯\ý¸³ýq»×íÖWî‡”Íî¾¾*÷»ïä;ô§Rìx€á‰Zßô¥´}¾ùKmðsºÏü–Ÿ=´Ïzæá#~ØÁËŠÍÃÇüÐ¹EÛüôdÓ‰$M¥RhÝP;øœâUéíÝO=Ýºöq—Û”P²®»šÛÝ—×»xÉ0Gq¾fMhHÍû*Ò¸­èªæZIØN#–výVžóWÚ9>z§ioïdû T<¯ßAŠÄÓošäVg×m5JûèœÓæ€”çà´B9·Š¦ý¹­P‰Õ}žÍmuÜÝ;Üíw{Òv'ˆcß8<:Ø~½uìÎb’¥ƒYê@eÿ9£I“áørH@k½ô½ÔðåÞ³Ýì¨KÆ³ïiçœô>·ÐÀ†jl"Žî™±fµøæÐâìÅuáç¹?TìÏõµ‡ÐÎä´Ðßšúù#t¾m6žìc€î`è×äOö 8?u–5¯zMº¡¿oÛTçÕBâ(n¡öÁ*Â}Çj+Ýë¦Î$t¦‘_ºcˆ,œÈ¼QT_gÄÇtz!´;»–ûÈ4+ØŸZK›|÷8=–†bh)lNCwÑ1bå™^)-yíÚ…?Žó>ÖK­tÀYR(@íãwã u$´€ñ|æJ–Â-’Ý`Þ>óhË—©µÞ§ÑÞ¶|…/ì†>ûçá]µ!–"ÚCß¬©õ†U ±î|}ªj;ÔO>·S^;ÿ¥ó¦£»4ß²³_Â‹Ð¡…(ý¢ ðŒ‚ô(
¿£	h<Õpp*ÚõÙyð›¬_`’Û0ì€3X>ÕÉ3¡Ú”R”OÒd€Ñ¯èÚïqü—+—Þ¥*¤”G
0Á™¢gOgÛki7ˆ{ú»ÉM{ T&Óg+È™›˜0³È´C¿X†æµÙå'ÿpÑÁj×¿H3Ÿ¸{pã~‘A.`ÁHÎ‘-´7×"	/;¨D%`i€¡Ö¨Ç8ÀË¸ØR‡£Y"PPoâéèŠˆÈÈŒ¿-ß~žEÓY–¨õ¢•Î,
J²¼8ì‘4/ºÂÖÁ­í$ÍDÝo“rFŠY¯8›4M"eíFûo+íÉ}µÂ«kê¥òfxÖÄÀË(¡:›»ŽAÍáFÝëµÔŸt€}½"Çá]õtÒëí{ë}ÁîŽº‡&¼Ø¼œYUJJ'EHÎ
C úÕø‡5| ’™—-%dòo¤0Ì°Üýþ`¿ Sy'xÉi/-¡ÍúÃ?þ©º¯ñý'¶}òðÉœ¶´@ôŸÐöb¸>Ùª8`s³Õ?tWTG­ù–¥¨4ˆï­zËØ5äñ&×šÛ¶ç4–¶¸€•í­)ÄoO[XùFÑN¢ß€e¯jW«hœy‹ÙUo¯*àËb}­V‰âµo×ÖÖ+"ÌÆŸ7ªFd®Õn0_4?ýŠó}Æ§uþ”è€Þz¥ÜùÊ6ßð°Þ-ŠÝþÞô€ÞæpÞî`ÞæPÞÝjÝy9#ƒÏ&®Â¹-e9œ&	Óqþ¹m«_àVoƒúö8°}†íæ¡@L'DFèªßBï¾úQ‰ qÙ/Ž¤NÙ›ë•\q‰x*q²CÅêD €–d¨XÕÊ²óÛ·…G›„Ô›æÐl:GbÓ üæŠ¿˜5wîŸ,}ËôÂÁ 4·i:on&Eð.fñüyÕ<ª‚\<}AŽÒªy·ÎW” µÞSFS†žÍh<™^µÔ–NÝJ¢KªœÑ*Hûn0°°jdw½ _x1‰¦}	’†¡D’ÍP¢g¿`9†ÔNsÃP‘ÂŸžÆÉÙºVUešE]¶]oçÏö*ùÌ7Hš÷°¤esÞý\õ_Ó5œÎÓw7~nÒýêZä®›u>€Í®6'|ÊœIÀ½Õ¬ßG7ëšIÉ­YUNG\à–MˆÉE3‚O³°?ŠNÈ<|ãN<¿Ë¦eÓ	¹"G£ù±MWw'ôÌÕ\	±øÂ+îêŠ]úzéMÞ@å½À“¥·•Ó¡µvÏé¯ÇDGÚs—×7<Ö•‚vIÐU7—uÕíÄ]u[‰×yÁ½Ÿ¢<}™™~ŠÚ*à·Ò$OG‘RîH0h³Ý–+h˜ÑaQ>.ïÕññ¡ò?óf‚M{•MíL´¼q'Çê)Èqg“2·u­pä”ïr;pSŸï˜ßòRávsæžsZ[©úÃ^ó1Mðd×Š‹íL5ËÏJ_«>²•NzuŠ.~îi	2=Oœdy¤½Õ&_£|ðUkOÑ¶Ì•ñµúˆ5MTsÝ)Lò¨dÚ½¸Õ†Ü»ý°îòWOI¼£žÌïáv>=¥2ç:·ýÜžp¹XÌ¾ÏZ…wùº½/PÇª ”¼-qIÂÏ$‹“éPÝÿ¦ù8Wß4×7ð¿OèÏGøßk"T©Üñµå“ê­7œÚÊê/iœœœ^©¶bCóµ²Æió7‚ë:éœ>Sç¡Úrªt¦¿	t¶s¾3Sts¦Ûº´PÇ;&„Z0AÁi}EªT·Ç)D2J]‡b#WÅú1áöA4N³³VŠW#ä­<Ê.¢¬EáQ& ¯ÇÀF9»À^Æ÷p6¹ÿ”°T¾c^<Æ~Me*ê‹–äÍ|NwÜ5Æ%]_Žò»Ÿõƒº='ŒÖI;ôê"’{¨é
ÿ7t¶;òî?·Ëý“pýþºO—+¼ÛVïv¢j*MÊ”»°ßÝœC¸ä1o Î!,À*¡)È]¾hìr‡ç˜²_]Y³ùí«rV^x“‰Çö_,\ WŠ‹š?Ç[83éý…OÖ¼ ç¥…	xþÚÝÆÿZT|«•^§Ë/ç•8‹’S”¶‚^%QÆFSÓˆoP½Ã±ìFÉÙôœ‰ÑúÏsŒ7ä³,j`jáZì½ +¼äç€[:Wõ&mÀâÂƒ\W€cø\î‘Ùéõ‘ŽäÄdØªùÒúsÕ¿i6‹<"—à~Êh˜ea2 û¨èÎÛ¾ªušÿ+lþ}­ù§<Ä(w,bÇóQ±œ¨u_&ÅAßË±Âxä4ÿÃ ÇrB®?èŸø «â#JTPêçuësÅOd½+bIv_P¡=F*­g@¦&:–Ö­©twC2ªh¡Ú'A«Z
¶`»ûo>=ÝÇ«ÔÖëÞñÁÆhR±ú<lñŸ7A\¹¶/ù<Ù¾ä?/¼¤Ëò¹h‚/éçŸßœ‚Å+šãóBsOMrš{ÏïàÐZ–y^h¯‹Í§¡Ÿš»Ynsçyñ]1·Ð~^ÝŽÝ-v Ÿ7ïÃk÷Ëïy3æs§Šy¶g`úyù_a¶¯øÏtUxïdÑf–®ª÷*¦†j¯*|ž‰:\ÑTnÈ.5åçU/u«`ãóªæ W6‡ç^s—èè<·Î(óO#;vRðó"ÊzT;GœÏ%FGiÑƒˆkÝ£1îíŠƒßmI‡Ò°I¹˜Ù}?WôP«®ÐRw@¤þ}eßÓõÖŸƒÓ†ÌI±åí€‰*`ÏÒWáéÌ}›.íòl¯ ‹“-I.ÈÕÆjæAbŽ(}ÿTó1Kt@œû rã"ñAXëpÑHbß¿«†€é¿¦k+íun‘ÕŠ¼TÙ–Rº(S‡“º<aÙb/_oùyÈ‹Y~#u¬Éõ¥IŽ»‡¿í0ÊR5R*&1c!vêXt#£ä‚˜F/¨EmIÒ*z`;»;SR™ÚS™W…TzÍW[êÏVï×àÿ>Öê­TëUY‰Ðæ‘Îƒ±za¬|\e(u S_i¿Ýhß¯€òAþÚl’-ÃÚKÅ¶ÛÿˆábM¬Œ…øYù@“*ÚñS3à¯=Ÿ
J¬ü.ÄÏ|øåtmî,‰œT˜e€êÑˆJ­Ýµ¡óàv^b)îõÚS¾Té©ÆÔž~©9g@-Ð{<×$Âi|a“¥A(\g¥þÚ¸ãu@*bÌ•Úösf0çñ†kRÂ„o÷­%¡“bð^A&¤ÂÄ9e?ÃÑ(ÊÌW/_À‰ 0UýáÞl<…—îfD[éxœ&‡@»ž­ø¾GJS’^R»£(YàY­æ>wäOUóº·bÁË«æþóÏßZ’‚?íŸ7Ô8
“œõø>pŒ˜ÂèúKë›Z­r«‘ã,Å›¿xŒ°zˆZÍ¢Á¬ï½ì8»
N gôN=¥{Äº 7+hdxwrC”qÌô-Km®Í†Vý>ÓÿæßÕ
¯iµŽ­×Û‹4+¼l£¶ +™¤ü’íØ™mH»VÀ=ŽxrCnÜï,…U^…1ë7=·ë§"£h—î$Ëct¥ÀBÞpé·Hø”‚ªÅ¬m¶¥!ï`K,Á@¦È4i:M¨ÅË4»³ìÚbÜ3Á½Ã1äÓ+ÆŽFo\…—ÏåÀÈ%ÎQp?sú-/]a%ÜÆnÐÃ aÀú4U>Âª-Tû<•ûùà Ù\¿®ˆG0¨q—áÜá=8ÓéU±|k09>þKyŠù—K\?ã_D¼F-1·æFï£þŒÆÐ–änó&ÕøÀë‹VåÏÑ7zü–oßá“ê…Ûæ¼O—ó¨/x;7&Ù¹îíœÛàx|†¯² æR^ÆÕüXÉ#=þèÁq†Õ7Ëwû>ÐÖ0]™´|¾á¯@Æ:>Ã8Ë§z¥H#.ã…Oµ©X°mÅQ!VÜI/ï¼éncÃ+ÌË‚®
ÿÇkUö¢èá7¶hàUÀ:EˆÜÑ´Pà
V]Á¨óÕ”ÔnÑÄ-* žiÔ Ä÷ZÕµÉêf5t©‘k„òo[ÖÁ,cõPªjÜr(K@Ø¡˜Û*¤èõXnñsÓýQF¶–Âµ_VÒ}äÇy8vÑkÇZhÃ”œòÙñµ½G/:ÕÉ	BÅá¬.Ö
[|z™^HgzXëD¯éaª¬šéªhø·œ®€^¸¸‡Z¦™ý‰º6øUin²Wm	o1#ÐGÈ,—¾´e”§|-_ž§¨Ì¿“H^·d‰ã­ÐçÍ}l5ªbCå‰Ë×§Ÿ£¨ÜÑËók@Å‚'óïZz#Pñ4z-yÐÒR‹ñ;ƒˆ¨+K„)öO9Gƒ~á‘ReG‚ëð²þ’ÌŸúœççÝØCÞ.KÀ½Ÿ&ÿX$Ú^<á³›e%9·$ù7×Ø%þy-7Ïi™wSÒ-®;rn&)UÄ`ïWªHb˜×ºÜÒS75­Ä•nwsíÐ(
9äÆ2ªA~ y|ï^m¥4”¶c0ó ƒò¶‹ÒP”óMûàMáºòGy±¢Å=Ê)ôÀÃsåýìgÂR½—‚*Ã1Üýþç"ªºš£ÒŽ¶x,¯hc‹c®”¢Jrf±?_
9'ÿÌÛ‡;L‹{ç{Ì”|¨Ëÿ95DË;UŒ}-žÕ÷ãÑ¯´WþHîx¯`x·>‹°w¼S^¾¡G¢W<xF1’ ¢ yùòfAš`‰ïƒsx‚[¿L„2'–°êñfÓÜçÈá‰È	ý
r£°à<Ã1¡Ðêê¾NÑýŠ»ÝëŠ4” b¹éhïv•WNÀQJî‰<ñ oÖ‚“ÀK÷LAwãh‡ rPu£ÄÖ-ÀËÌM¤f)Ö«æ_1šóó@,6Ô|2Då¾ F³J¨ôâQ¯ÝÒðŸßí^w«Ü»‰µÆå\ûYÌR_˜q»<u>(Þ¹àª«>^óµ3'½ã£OHÍðF¢“4ê²Ý(÷ZFÝßµ{ù.¿$ù-KoØÆ’´²ä…‡Î:7gÉ+œW¸äÐ’›Ìa?ÛeÉkOª_»u
‹³ïHu¼ä$»óó®Õ»Eøu)æfõ¿j~>(’e'¼ÚVGÛc•ÕRÿ> Ç‘²¸ç;éÕëqëù”¤Çy]ÊªL¸uíÊŸµeÚ«PÁ¯L`vÕºVÁÒUì$°YÖŸ˜}VˆÚñ³ üÖŠ	¯¬j_ª5|ŠÙ¹r{kuÒ†âw¤G¥g4ýÒS *î3~šËÞ	8›mÓÚ¨¡ä/é’™1ñddl,rå§¿né5á`øaü^Ãd¢9}þ«Æ°×rT¥·­Èãg#ÌÃÌª2±è÷¹è«
Æ,±¿ã*«Dx+±é×ÁüO(`À ++-EnýÎÜtr7½\ÀM®ˆù^²&ÈU^ÖÎ’â(ñæ{hì,=Âl(TI®+Cýí]Ù»ê¤¶H¥·kîÅ]žmšû'£trÄ›²D0öô€ë
÷,×Q·säûøèu·Fî†¦ØOÃ§šöÎ)]ê£¸µœÂÏºV¨ï„ïÂ<PEî^jó>í],WÿI/b5üÒ‹Æ‡sãE-›Í[DÑáŠ7^cFÁ;‹žÂ_w¸|˜^ÿ7*îÁÏ?ú1^%a IÂçB·•BªË‹|ÒÊÜ¤
‰úä•ùÇîû²Šä8³-8¤QE‡up…£äø^æ4·.lVl7]—»éÏgÓ6@ñ}Óúèo'³ßíXõXîb¬åò.w=VQ¶n<^|%ƒã/eÇŸTÎ"
_°J+L2žºa-Å‹HohpÛ±É¥èÜþœÁ`-S±¹OÁ`1¼·‹G™OgÃ¡õD“÷yþjÊ}_Õ—<¡8r¸ü\Wð’%-·›ã§´!M2Ô¹ïh‡Iè ùèÁ[éÚ,‚ï®âúEsHZÓ÷ÓêóñÃ6_Œ~kp%»¥ÊÎY7¦é.Xýù©•›àÇÈëø°ùÙM<n†Çs›—Ï{ë;wÙžßxs¤«Å£©|ÉYô•yxM†Ô5GTct¥½œÐZ.Õ+^¢W¦Âs¯ÿ%`6ûæ7~Íé í·ïªÿY|ÿ'ß—É÷>~øøášZƒ??üzü¥†Ÿÿá÷âþïîlu÷{Ý/Ö¬Ç“GæìÿúÚ£Çëû¿ñøÉ£¯÷¿þUñù~ÿµú¾»ß=êìªÃ×/ =” HPÕ>o$ðaCmüIýe–Dj6;@>˜\eñÙùT­nÕé¡z™E‘ê¥Ãé%†#’©’|{ ©ý–úNªÿóa+ÍÎÚÏÕ½ˆ²+tˆÆ9ÞL=Ž§SÌ6À†É‰;¼v#>Å,h{
ðP¾›``ç£Â›#¾yTÊÏ°7´çÔEŒˆMJ8¥—x3æ¼éÒç0‹Â1ˆ,ØêZ5JX©ÃÙ)ô¦ï:åz+C˜vƒF<Š(òîäz1p*™¬ÞÅÉ€24AFz—·t'òV.÷•â=ïåw'Xü£¡ùeŠúDy|†ñØx!Ö/Ã+¾'†E+P¦<×8£“$5R/®Ð^ˆwóNÁtéŒãd%Þ§³Y˜…ð=*ö”zÄLI-¥ù‡Xµë,ÇÍæ4µ5AÝèJW.8»†¸2Mx³ ÁÐ "ÑÔ›qˆl°`NfÉS…ÍÌÊ?Å±„“ÉMì_
ó
“+Ù\>ÌïŠH²%LÄ¥?½¢†t»0ŽñÇt†©Q	C(´Z2ÿ¦¦„	?`Bêe„aá;®€OÂùex9/eKc8¯9^ö>&YŒµoÔ€¯ž­5Ê[zÊ•‚¡À‰ëê sù –Æ§Ve»³3F€0FA@ªË8?¯7L|aF¢ˆ™ýtQ*@H•¶èÐÒ‹ÁeˆiÌSçUlã ±é^ÇÝ†±õyt$AcF@ã´ëÍÙÚîfi¸Ê&œÁÖ|>S|uŠÙb´oDörÚ$â5œdÑå#fˆ¤û+Ü#œÃäqœaþN~¢ÓIÖíÕ¹Ñ­ZD`§SÜxlˆ›ô£lR^!VËãÓxOc¾ Uî’»JŠ/"Òâ!¢äfŸá¤]DÀ#Bs¤•y‰÷¿Ç“À]4‚|Ö?·'–îœs¹ÎðJ%Z:ÝjÉdÇX UITå®I@™ &Óœg„×èÊ¸òbää ŠcÈ<º†n8¨Ç«e°àt ]Ì òs@ÂlAà[¹ÊiˆW!ük4¡u’ëÑ5h B”˜ÐîV¡g)N/S¼†|’o«ëu…·§gSâ5Ì{qq¼ÍEÌ^Ý¨Ãš‰`üBÂ$‡?8‹/4Þ¢3 ÄusâñÂvî¸6QGA³ë‚¥guŸMLòîëéý¥iÂû@'3 X‰{ w"‹˜=ñÌ—\*Ð¨=êÒâŽOý˜üS§é4‡=¶ÝeÑÎâ,’õËÍá–F€Ù;
¼
¤ÊAƒw‘‡}1`Œ[lGÒ“Â©¬Í€|TI”Îr˜r	¢;’ƒ~0ýÑºõèJIø¥_A…‘Zð¼TØ§b–ðPJÇáùÈfIPžFápãñ€pY8Â‹ÝÏÎ©	º}‡ >À!È¡tyJTy:,6òLŸ0Ù
 ar'N´Ý0*0F
èýL’pøDefZ¦ò+@eÊç
 2œ›Ä’†S<i¿?ËÈ?GÆ‹I—³hÒ ð`ì×ÞBb÷)Ãz‚"`ø—ŒW$ùkŸ%¸ª“)Ú¢|Òz1»³›¢‹`È#J™OÏDŠ¡‹¥±Hð5…ã¥‡Ú¢Ê43ƒDa†IiùìÍùF«,²„\2M£ÁßTÏÑ
sL£DFÀä®{"‰)	½,+¨áw× G`ÇÞÀðBäUš[1¹)vªè„Ç	Ž¯¡"Ð5ÙÆÅœž“·×	dFšÊˆdƒ‚üéÖq¨Š¶$’ü­‡ÓÔŸjRBfœ=aÃÐÊ~\ÌÅ™æ„èäã,gqŸ&Í…ÂRbÏ(tÐÑ¼HcÎbÖiÓDÒŒë±¨G+ÄR½™8%(ÄEÐŒ´µåF´4 sE j^µDR`I ÷Ë’# Ü3MÝœB!*³œ»u¤ Ý5æUãXŒ¦ H.|G"œ1')›r‚r‡CÇ¥š‹Ðsy1îÆ|]è¸{´×Sým¼:r{çxç`¿‡×ZXw(N¸Gz¿vìð˜‹§´¿ú=4çh®Î€ŒVYc›«~×Åï0‚øRè:‹ÔÐ‘¯[¤Ù4„´ 
Fãi†Î  „ù;3îÔ=ZhwØ(ã›>ÉzM²¾èh€²KqèÑ+Õ¡3iÂšá` [žsloXnZÕä…(¯Ñ–Ô¬PSƒ‘]!6¸4Æºr˜H˜¬HkÌ’MÊ0ˆæÌ¡« PÂ	;üBÕdð ë¡¨a˜Ÿsd˜HÒ­ta…ƒ†¬0ÕadvB,êqI "`Ÿ¥¡ôå³c\œs±X	¸ÃÄj2¦ åƒXëU$Ò_5í9¨QÇn+ZŒŽªõS€mðYM–"ŠeÀpºÓ§l¶ž "GÉÏf‘ñt‡gñP\ç¡	i	Ì‰+„S./‘Îà˜;«wI4ËÈè˜Ô…qä¢&pø:b_	êNq2ÄÝ B5‚pDŸúÔÂî Óï‘·é,h¶yà™4‘TFˆÃ_Q/¸PíÙ¡Ì8ÿhÌÐÐ‘À£#«4Y 'ÓT.QOÃ¤–‹ðLè´³€
ˆG™šT$€Ø»Ÿ^°úGæ2ÌNÀ]DEtÇsŠg^¤3¢QÂN3 ò‹ZC»€•h ¬¥À*ì‘ÌÀr…\W‡KE_DÆ‡²TÆuŠƒièk1ù$É‡\ð aÚ”?Áñcz.álbû¹ˆ¸z Z¤ëbÑèL˜¿àVí’¼¾Ÿ¢È‘×Ñ‰H:`ÌcuW6/ä“XsT „IõÄ®Q†@×X¹QŠP¿0=³¹ÂômÑ-¡þžLa“X“UZ,Ô%]„Üp'!/Ä""“Äb‹6h›±äU%×fÍVx¤¤²;Âh3Þc<´|gp4¶Þ‡	V ÁÀä»Ñ$±ÌIHœvzBdÙòš0€;k°²Ë+ƒv&1iE¤Ä"aÌà×`b¬·”8ª¶PõÔ<¿æè£5Q•]rÄb…°JŒsé<Ù·øXº‡•5Œ)2¥ƒÓ_"¢àÞž-”=¤X‡z„·‡¢j˜ÔŽ^4ûº³|™ Çô¨§1Êa,ì"µ¢dHµ{Î€ça“4 •-\¡õ¢¡—’ÒßÛ›Žr'Ÿ†‰Ž}6
µmŒË0éož¡1$ááh½D]±0ŽS,`õvœ6QV!/„Ý£©7€P§YˆD­ÆÜQ¨²#äŒö!¼50¼•Z!*“Žt•äÕ°ÎÖWz{ !º ût®ÿ.<c"¿þ‹°ä*MŒYÜ(KH•¬H PóÀiNgü´®¨ö>bXÖbÂ*"º°(‰°”¥~ñèª¡™ˆ%|UFÚ0H¦­ð¤¼ÄP3æ%Ö„ˆë€› VEMÐ\
¾ŸêÚU!lŠ²)fDáé¥`õh©ÑI|2À¢D´Ç¼4 žÇ3*8c^_!º„Ä„¹q€À^×‘#ó™pûXú}Þ`¹»GQ¦ÕQ+­ÑžÛÁ)²Ç–O©}aj›aè–w3œÄ>LB*Y¤Ñ((Æ…R—Önh‹… ÏÇiçJdºNChngd“Mµ©ÉN•žÖhå„Ç€üéHT>+7ÀÖ¿J/Qkm˜jˆèúÌi°÷ó x\iQ‹Jæ4MY—àXD$÷„6*kÜÍD›s„NXUÀ	\L2Ù†Œ§2°/ûÇ’GÛ*XZ«ö10¬ß$ŒžÆ¥;QMûÈÑ|\e7ùG±ØË²KAÓâábOÒ Ø˜,{é®’pÌez¬¼t{vj–ÆTy×Ú€>,´ ®LÌv@³Sô¦À¡SE”pJ‡c<K´Kê.£Âm§ ’a^%›cÜ18^´PŠ¾šåÕ¤j]ÙÄïâûµ)7ËÉ –E¶Â¼[¸H´±rß^ww·x,þQ-Ò=¶Ï FË¸ÙF%e:4
	«‘ÐÅØ|F^¼A… EH©ÖBÚÛ”Ñ‡ÚÀOö`”a)+-Z–c¼BëÐ plTÃ&šj“¤îß¹À!©d&Ÿ%£x#ß†­iKYëå”ßyW qBÌ2puHRXåûé•¿Äåú†ÔPg Ä#¥Í‰.Ë#ãX<ME·À‹ó†¤— ŸE<³@»‰† œÇìÓBI“ÏÇE8bþœÛ%=½òuBÚ`ò€˜<&Ó8.Œh¬ÔzÃr<( Ú¢/‘…k£Ïºf&`}#”BÙíóv‹o‘Ym€4ä“Ô£¡½Ðyj|g‚ct{ Ða4ež‡|è€h“
çË² QŒf9åŒ‹(º¬»‘æeÔ>®!ÛÕK–Åpä`ªö9OF»2@ô	È‹JÕdÒŠ™]ne1ËgÂ!x…Q
‰t™#Ü`#æ,76w…Mdªìš"“¾·p$hƒN£óp4lÈù¦Glƒ€µÄ†ˆCiÐA¦¹±iÔ1xùÈhŸmdìßc¶™F4°ÌÑ.	ô‰Q!ZØ¯óxÂ,Þ$\Ý2ë&ÆãgïÇY6Ö…¶½HÄ”Øñ€Çâ(˜9Z9•ê‘¸»DB¼òm0ÄNÖ×ÈÈ›£ì K®kÒ ¶Žh¿Çkö{°R~Äö%.O¸Us‹†Œv`„º+Çq?õ6Y) •¼Yw`Ø>JLÚÄ›Ñ?OÒQz†ÌtËÜ˜v£{5œ€›SŒ&|&§CÚ£2BØúºfA?ì8„cŠÆ}€9 µ–£u7ÖÔ6,•q\ÿÓŸžà™
r ¼¨R‘!V£ˆFU1é“%Ñ[ñõè9ä6âQŸV²/ø2Œ©ÞÔ•öYÂ¦‘FÈ)vã­™Òý)ßdB†÷*ê€¼ðLPAlÍú1!Œä
öHHl<åiP<¢Ì
Å1Þ¡gBA4SaYÄÈ´â@RoªwÕ,ÒY&Ç²š	RWR"¤£ðíŠ¸$›4ø¸³O5c,ƒS{_SffV³´iAõjÒî=j9çöŽÏÚbƒšËdw!\zbÂŸïçžHÃÌ%Ðf:A‹5,–x6®&ÓI>…Ÿ²ä¶f,t× ÈÏ³#´×KœÙBc×Ó€RaÇÐÊ²+˜|¸HbŒ èM(þ$WZP´xra|6ÑßÃ>•(fQ\HÐ·Ö©Á¨4X0 Y¿ð4×~Ä´ãÊØÜžÒ0Îèð€úæ„OTÛÀ Uª­ÙEk¸ÙHŽîÁn(ÖHQ¥iù™‘]VwSPôA@8ŸÏ&pÌQ
mð€	¡!<v‘mOËv"¿qí¬s-ý%AU¤¢aÌèÜ±HŠÞKb{ÑF1k5‰ˆ#"è­}T…±âæŠÄMCš»Œl“=ta„W¶ú!³ïÃ‚]9FÆJ¤4Q>°T\ABì:R Û†XaI#ñž~R_äm—LX	Š«R'ød¸œšÏ·•µ"0ßjQY´B²ÉlØèéþ€
‘^hÜ@„P›spj2Ñ~ÝÆi–X¿ÌhÂŽ%ÎñüáûzRì3D["´CY‘Õp8ižG¹Ž$­¬ €"L¦:(I@Ã=Vo¨ãÆ€—È3!]CSµË>D1“(JÒF²ega6aÜ	ÊÚÄÄuEÙ¤HUžâ‚„å(zß×ÁÜµÔÚª8^‰ÏÞZh9Pm¸‚<ÇNX \F‘y„•’ˆžë`/mæRjP×—~PÇXii¾«VŠèÕØ¹ŽŒ Ìu¼<Åµû’Ç¼Š=É„ŒeZÂ¸B—\¹2·æÙ‚fal¤ø,Îá;l‡gƒ¡‘|Šñ‡W^¯œxá¸¸0Ú9EïñÍP¤ú¢Ôž°›ˆ'/îÈtˆ¾û``§dÕ×RmÖaqcŒžä'Æ:ß@…•]tM_¤£ßìRÑg@BüÍsGjQÀq1'A-<;C„F¿m¬Gj—ˆK•æŽ—Ú²|y M¨,š“å¨,€'8¥%ø÷%<98€$à’„ºÎöë‹ÒËŠºžRÙª¶¼ôð?=#kÓì‡FèI¤C®ô`}ŸVVÐ€wž¸<u„a§/asæðRßPRa06‰Q`9`”ÿñ\Fè8ôÆp0wšE4¯Ò"Vè¬(Ò0>%‘e¬@|–ºeú+ÓI0 µ¸ÉjäÐ;¿ÊI–0/²jíÓN‹
­7HÞOÂ$Öv%¦Õ¦¾ø=K+¡Ì2¶Ÿiè9erô á,Ùhm8 ¬
äYÖþsÈD-Cý=a)°¡ˆê³´7ÅÒ¤Å`üÕUflºuš0çtìOZ˜œ0·Ê8ÄšWÆ2Ù°ÄF3'Ð½ƒ>Q25Ö-’†»RâÉ¤€\Þ#L/²Û2‡w7Ç`€ŒHä¨¹ÆÇF5>ðDhÁoŽí!%É]¸ø8åh ±ÁÑËÓDNØ®ûD]Êõiˆ<c­_F,&¬ÂdÖ*êÁ"ìG‘;Ôì$ìHRQA¬'øìPW_»t·N":œ+ã£DH^ˆÕªr€®Ž0”•ïWŠsmTbCqÚï‡9If¬Ž¢K=hXàKÔQŠ¶+»!ìÕÃgjÑ#y&ÜâTˆON­\4çàŸŠ6FÇ™÷H–Ÿ=3d§',¡Siµ³ÏûQgÑ’WÐZ©]_¸á¢Q±ç"ÄAf&t™rç„e8ËØ:ÈØÀŒÊÈI¢x)7Á»‚ì,SË\&Ç#CƒôIi^ÂÝÆ\TâƒÇ‘|¼c\C®vDh¿Ê–!¦DïpÙ­5çŠ+ñb—»[ \ŽåÛá¿¬£Š³ÖEúÖ:ŒqÃï§F pf™‡•C­©®,»ç®n/ÅqÕ’Œd’ç@`ò…¯7älàhµq“…4 &ŒÉj¡Ž£–Ø†aÖo#&³·9÷´É\NM4÷ÔÌÈ.8‰¢¬9M›ø/‡™?½ÂG'l/`G`DA%¼vžpß7ˆ C=[ ¼|1µÃmoµŽ‘°§FÌ7¢k;db ªkÄ] ã£3@ÔÐIáš=bñÀà„½¤úˆááðœï@ÍÁ=5ŽìïM)‘B'	ñ¨‡!­ÑPM±ƒùlÌJ5ÑŠŽ‰t
¦˜+J³†m!E5³Î–0ƒ‘6._Õ—†cà¸L#:Oá÷s¼\œW¹å€Úsl\ÞÄœGIm *«²-:¡0ôFAbØ *	æn9w4ÉÐH±„ýy“mƒtv:Îøª°Üz`kÒÑ¯ó0¼H)l‘$ðLgÛ¸T:»Á²'ŠÕrB¬Píi¨š·P^\u0½š¬˜r —	#ÂäFaž;)‚YBûg&·¡Ð¹âIÐ	)½ÂÜš˜£GÉ[½G#~®/` o|¦(Í„£ìh`adÄÈÊe/Œ\o–ƒN:H`ådêƒJÓ¼T|·štÀÃ%šd|ýI¸"y Hš@#£&›Í"	`Ô+¤çB‘ð;·Ã
òQ*ú[‡¹GÌ‰Ã´ÒAÞ@ÜèGt4$Lv~]ñò2á‹-lMpNª8^(ªHÛ*[7t<ž7@¤@AXzŸsBóù]ä­BA>ÃPÅ¨ÈfÄÙ8“¹­M_kPÆ#ND+ÐTRS]”T&l*âyqh¹6O#Ró})>%Htgè9Ñ’©tM±šè‹Æ‡Ý±[ÏÊJ6-«îêÚØ GÚçÌ-ÐÍŒ“Ùa¨»rN¢DŒ]ë¨Mú!ÀÛMk‘Èj‡ÇÑNâ«&ÑtO¯Œ\°M¡*«•æM„91Gø’ðß%à8
*YÏÛ·oëE%Sâiäê½ëújÞÃü™8\‹¶±ôM' [ï˜±á^');€9KPR2;…PØ»rÏV'%éš%ooÅ)pÏ„›¹ÆÔ€ðN 2ï8:Ø«›°%wüŽ5oêå½0(€Ð§Ì§Uz”)]{¡ùzŽßY{lÌ:dÎTd—^5•‚ÒòlŽ—EFa 0Ð:ˆûƒˆÌ"—çQRrB!¡ŠFCH¡Ý™¤eC·"ro]ÇL}tG0–‹8Q"Mn&uÄ(‡3íctãP˜±ªûYšç. 	ÑXp˜*ÌÝg-“AÎõ{VÎL¢—M„eY8ºÌ¬ÿˆ*ÄÏŠs¢»RïZs"­sME3X(àf„³Ý"äxÏä.›zG«õmëàj¿Ìq¤ª5ç©up`:X¹¡7ˆã/]2oê´3ÄY‰ÇáŒ
N¤xÃ$â¤Ÿ,ÒlÏºÜZAõ ¸çP<PâkÒaìÓî#pÌ'¹Ùtc›9™ÆVwY^,†Ég‡ÛúJ9OÕFœ.¬{À–o¥îÆÐ¿­¤{fS}I”·þ¤@tToØì®ªX]©äEN_Já!<ÇHO»zsbØXUƒÓ¥n §¢r9«7Yô³p*)JHæÈàƒN}^¶€Ü«s°DO[ÍlÜ®ø‹ÒK¼‡JœÔ¬`ýãRO°éÝª[g™X‚9ÃG:!D±!¾c±‹Æäû¤ü¸;rêRdï­Œû°½IÜÖ·‘2Qtè›.È£ó±‹~.*£ƒà0Žo*Ðì"e	ˆàl™‘j”UàÓ¢a×
?L‰~²Îm	H"mR‡_ }^”&k!ÂØ¤t8³6Ôƒrµþ˜ˆéú“âž¢Œ©G&Ý”Ô–ìÂ°/›Âã˜ŸÙåfÂ^Ø5ÊËe*2PïZ°ñ‡™¶-–¼­D<®Ú'ËKÏî9”<BV¶ã©}¿ŽÇßÄ¼¦ÝËãÁ°“gqb”[‹³2|›q;§F….Ž`æb‹Vˆ­ÎY¡KJÛËë¡1Ãð@BS~ÉNeP‡Í‘ÍÆ–3©†Ä¬7^Û0p0xå:ýÁî}ªuáî„ÑÑõ€mGQÃG¼˜èlAd+DÕe Ìàô8ŽQÔr#Œ×°¢a›³r)’ ­Onûº˜†ïqâ…ÕÙ™8Lô–‰eV/þ•ãÔ9÷¦«Vu–ma%ò¦®ožÇZ[d} º caÛ4Gj/£C½ÖÉ•ÛN8'‡UÂ5ÉÆ  ¥Á.æbüR¹ &;€©\!ˆ­mB<Í ß!]«‰i>0¡ $ÞàÜå$¢ý@ûˆLä­5°kæê (vI”ÍÝcµg­'Q–ä0h5/æ-deQœ¡ª˜ˆ%ØúÂ9Ú€ˆ²ÎP6)U£3ã@å $É‚Pû³1ÊœÚâÅD»¢ŸÃÿ«‹EJæŽSÞÍ§ujçùžy|£jÔ¨·Q{>ƒƒw!;óÆïÚ(h¸,æ–½@7 ù\
¥„gØÜd¦…ŒÀÐˆQ¡„¸~	>ò:©Ž‚NèYìF%g‡'(¿S
ÈrÎOZ<Q-PIÈº8†mÊ­ð¤e®‘ñgúµ0w”€§Û E]¿†LWìÀ4h¼l‘‚'lpã>(ÍdŒØZP…“„n2Ã„iƒIå0@*ª…¢ëï¹uòFXÉ7½¦òžH¬âÂªÅËùYVS™@äUÑÒ©Î‰w£ˆ”P8¸)ÀXL…ŠØÂ‚†­~›œ{dkM¯œ 0Þé~*yHêw¥ˆ8I8LÍHö»:¦ê¢ ¨ÈFDöV€ëBÙ¡,–a2¨²2ª”#½¬ªd¹à]D?±Çæ#Ö†\F ac«x À‡ yÓñÆ4Ÿ%·µËA5ƒÆ‘+Ã]krÂð“55 ©f8• |ƒ¢{ Û¦´ê^Ò1pÑ™SiJúšIåÎ\‚åsiðŽÇ,'ðÅ›ÓxÙz~†¹	­Ðs1FçÓ²|Z·z\P®M:èÏÄÁh¡šõ}è®o 0œ‰QœyPlÜ³ô-1ßcÌzöTâŠ™C†Æ_©ÈÒéef)tø†é€&Š³)Ÿæ–æ+¦1Á"‹œé{ ¡Sw«h8ioê?A~"½45Bð:¯@«ŽJ—õ¢—QšÁ5ûS‹¬¹›€iByÅm…t	;é:G¸v™(9àp=P ˜”åçE$ÙìÇNÒºr(·©–R9$k>‰Ìâ…µ‹Æ¤3–8ÀgX2,ÞDDÞ`‡6„f•œn/È[ê•r‘Ró‰ôÃ«8ÇœÒ0#ÉÄfÍ‘î8g_W´äl½ŠMð+É¡1ÎÔØáÔC^äR‚iCH®†e× tî¹Ü„û¢¤ÜÑœOšˆ0½^Fcùb@4øB/Qq*CyæäZù^»j:•;nY¿4ÊDCqFZ`‹³ì
z¡>ó»"HþòÖ?RtDb‘M{â¼Ì˜ïos}!DYŒéÖë$ª†V<Tž¬ÿ§Æ¿ë2>'î‡S5¹à•[’‹E0¯¬ò},ÕÉQ· 2ê6¡Æ‚GÆ8ÊÎsÜz_Dßæ×@jc³ŽÚJTyvæÎN¢)¹Ü¹"v¶Ø%i‚Á¹¦Æíàµô\ç°¯…íW÷©"ã€²(ÙCNNÐ"€HXAÀºzd‰³â–)ži$.ŸG3—d)ó*æ:êÜ)t3&g‚âïÔ?-&–”?Ãê£áC®Jb³èÛHy*T¨\{Þ$ÍÐø>)ùÈò)ï}ž í•†¥0pû·'«ëféU8OYê„Ðqö–Kqój+]¹3¦;§hV˜Jîià“c©Éi¼ÿ‘JßÉéƒ)¥34• ûìL+ñ#¨KcK°ÖÒ`®d…£f6²‘Ê±‡#©<¦è&±z¹Eá°ø$Y%ëë-u¨ËZê’s	[Ó¬¦o
"#ž)cÑ¥œ€
5¾À¤Ât^µ˜C[“ÒØ˜ñrÞf¹­Mh!tˆ‚N£;jS~Ïäx-m1wÙÅK…ôÍ{ ã‰N5ÇŸê nØ ¥×7û"äÀî #eQ_?mhNÅóÈ-èì8	Ü Ì%(îš”ð 2=,"™9GZÜbÅEih•P{¦yªs‡DŽ'* V”ôÙ¯Jé­è›Otà^iB¶˜KC62ÕlÁ7X¡Í«RgùŽ¡ÓtÆxÑØd—Sðê™
ÈÕPàž]Nï´£v„°ì¦ü V=ÌF¬ªe¨N“kæx*·Cú}$œƒƒ(\\Ò‚â²p/å s´;r>â¶ìW¥X ’pï2ñyˆÁ†,ý‰‘ÞLD¨X¬fWd}ªù“d"‘\ióH M#±N±û=ž²ýMòË08 õ¥ÁªT*rODÚ-9NWMÙ¹DC.ÉÂR¥X¿Ãý]DIÈ‰œtYÃLìþÜÂ­=Yç²¶5Úçš)äîï 7°ta
dJÍuŽUŸ3ÛÒ¼4j¸Éì·*Ê© ¾b5eŽXOJCå,µ¹Á©®À ‹DøaÄäL­t*Œq“:/z°4%IéØö0Ð1N'…”Ã¤)Ê [R8IlMÁÔ8TÑ8ê„¾ê±9s…9 Í«#Kç6Pg¬xDX+”u
H‘%: HÆ¶Z@SÂÝ±Â˜Êe«M—"7 Hå0S[—žF®Úd4"›
€ÿZD]¸ÐXfÄ“bŠó(®îŠŒA› 
¨¥¤
Š²”ÌÛ,ód,i›Œ«r+ÿMæ>FauC=bLç6Ã!ÜRhZœ¢ P&çNì.(É2:Œâè"²ArêèÌg!d±ØÓL"¯L*2×‘T|L6ši›SÀUIwÃÒ™Öµ …hÂ’êLéëä?¬¢C$¸ÑÁQ.ÊkU# ™ÒB:Ú×ŒM3ŒÀ84p®ºÚŸ«)•´é¤Kèâ~œLØŒÊbòÁâ\6{Åï‚?2„“§Ú”6µS\èª†õG²˜XJš]ÕäNÌR ûé¸ØÌÎ‰âÈð†©ø’Õ–­s[ÔËÖ[`ÉÀ*:…ð$#½Ø$?u¾Òò•®"sà¥K	¯VFÆdÑÓ8€Jñâk:E	R‚Hmº#ÙÉô<@rBlp^)Î)µéÁ«J!¥i´}UŠ^q`¾•B>·¿"l–Íº¤¹!ÕÖðÊ”DÛéJ§C^”–ä¢O‘àSuÒ2Uð3ñ<’f‚h%xg•ãçb*í;0æ%.õëÌ<Ð	ã GñLU]›#jî`ÑC§içš&’w¶â ‹#Ç‘`À5A-YLb©¿&—¡ÑžÖê¾ñGµf°[xgšŽ/:uiYÇìg25¨˜\63>>Q§PR1 #L56-;€ê`Ì4^]q	LÚfDd]v#'ÙÝõtê‰Ja«õ·ê™kŒ`¿b~Ÿnæ¤c-¿êý±‰b uÊÔªÖ©œÝŒ*Ã°;Ã‘í`ëJ¢Ø0ða÷MX¾î¢Êåv¥ëÛÁB"»Å~mhþ»-+~òµšÐø,>O¥¼N-Ëãñl4õ=1©WªÌå™t‰)†–
šº}MØKÉ.ïšd€x‡?)šŠ4MÄ¥%žõ‰ëì:¾»
e]Ðè±„ŠÖãH2)˜FâqÎ,¼fì°ü Š)Y*r]ÛÍ²Ñ5?É\tá­’QÁÉÑ0Ìðst¦ŽQó“ÇÜjFë[Ñm¥L¼—¢ƒdºèzŠO
4e±DJòN(–È(ù'47ònžøÔÊk5_I:Ëh­Ëak½ºÅ
8HnLu2¹âÝ }¯ê˜º‘t\­Žµ.‹û7˜]#0Ž·‡Ô2ÛsŠù­Ë¨XDàŒVÖEâÇ9»ŠñåQKE°Ã0î7‘{÷RÁ<‚Ë4ï.BŽl•d™@“¶ÐÃèŒéiÏ»±Îºspàð/8„5öààü0B[—ëÃ
I“8‹M6¯D-«)78J"Ä˜Q2¢;tø:êÂ\jÄ21.·ãgÒè	kÃ•QIx@lšÁÔq_t‹d†…MäW`‚Ë%TKƒ&„˜_ð3º
kÖª&f]L‚°VOs¯#ÕÀ·§”†Á‘Ôd»sl<s®Ü…[Téf„|Dq¬¡ÔÃ›ÀâM90ÎÈì¼N(íú+ªE½ù(dÃÇúç©öRh d2ãªÆçàµfíîKóþŠoX„_PÍ šÀWV‘ŸÙÔG¸¯ãùôý\Œ)~Ø—ïTµËä†|86zÍîxIº~Cëü.Ù¥Õâ–™®ê™ØLÜhÉ4³Ñ¹÷ïÄ%©÷†#(Ä%ÌZ– è´"Â…$¦âF iI .#6H/R2±{Ü2¡áŒJ?Hp8“¸WÝ£®Úé©ýõCçè¨³ü£zyp„?¨Ã£ƒï:{u|@ß»ÿ~ÜÝ?V‡Ý£½ããî¶zñcÐ9<ÜÝÙê¼ØíªÝÎxsÒ¿ouÕ¯ºûê Áÿ°ÓëªÞq_ØÙW?íïìO ·<ÚùþÕqðê`w»{D7Tµ¡wzQvŽŽwº=Ç›í®;&Uëô`Ø5õÃÎñ«ƒ×ÇfðÁÁK ò£úëÎþvCuwP÷ßº½ `ïìÁˆ»ðãÎþÖîëmKC½ ûÇjwfÍŽö&m5tÀßëm½‚¯;»;°^x­ÖËã}è‚Ö®Ã#ßz½Û9
_ôº-ÅK@`ÁvzU0YØ{Ý1€`uÆÞR}9s`›pºêÇƒ×È"`Þ»ÛÞ¢àBuÕv÷ewëxçM·-¡›Þë½®¬wï€Ý]µßÝ‚ñvŽ~T½îÑ›-Z‡£îagçWiëàè¡ì3=iqp¹qxìê¨e¦ûˆAÝ7ˆ¯÷wq%ŽºÿöæŠX¢|,Aøïº´ÐN?ìÀÀp÷b(FŒ½?XÄøPì@ílï¼ÄmÄÙ:ØÓý±¸«ëlQ¶óâ æd‡Æ#ÀUÂ}Ûîìu¾ïöÌÀ>¹d»¡z‡Ý­ü~|Øå¥ÚïÁ\qká QØc„€ÈÉû¼†ƒ€¸¯úÆgî`Wmße¤T»=ÄÀ`»sÜQ4bø÷E[u÷a¡èŒu¶¶^ÁyÃøŒ¦÷NàÎ>ïÎ—ŽøÎÑv áíËÎÎîë£"âaÏ°„’ÐÙ	nÑ«7Ü|µóºÚz%Û¦¼£ü£z[ñ¢Í:Ûovè8J?0ÈY˜Audìû¶Åw‹à•{¥$—y<¢g2b°áÈCd~oŠ|p¤­½ÑŸQŠÅ8y…+K|³Pá)¥Kqˆp€"atÉÐ–paýŸT^ŠÎŽå˜ú£”3A1±å=Ý‘hÓ:ÍÓæÏSád?PF/â‘3ö
›‰#ƒÙ@R/7È&øaÓÙZ
?Sti1pûbY×Šà%íóœíçßëÔ¡%âp®cZþ#²¼}Ve ¹ãA’{}H¸´·ëp¹rZ<$23ÊsÌs§â™å…ÜÒ†xFò)×0ÂÀ½s²¨›0Pñ‹ÅÓÀ¿:›Å!ºnM£|Ÿ„¯¾YÕø—´n¬/I£±U‡b´â«N2’¿Ž	Ü!;tqj8bóöX7‰Š³-(ˆÈ	³çûZrïFÌ€ä/±f:Uý¢Ä‰@Èõ ${ëêo¤þÔŒLSCeYÌ"j’’RÇö]=g83µ]é*[”M¹¾Ãå¤÷u7gþ÷sJ'Ð§YÑƒšâDb o=—ªDZÊZÝª«ï°:Ýsè@¤:}ï9÷{,÷µê°o»7Í}ãÞ&ÇS­ŠËó†ª=Š¥ä0÷ôIø™/Ã7´S2-Ø8
N?ZõÓMëeÍ¦U½ vžæîªst/è$ÒÆY²‡íäª´¨jq9ˆÙžš¼Z¬ A°´ñÓ+N»*J^°¸ó/e¯^Äš BX¤‡k«Éºjú#\¼6‘Í~dÝ|ÀRWÎ©Ef×’ÕA@vŒ|ˆÔwçÓéd³Ý¾¼¼l%³Všµu¸Gû9¨ƒ¡{˜tã–6Á""L;ÉþÍWSÍ{´óei‚U£ð®p‚‘+07—QN\=T¢¬G®±¥¡©œ¾l%ÄõÈ¦œQºÆ•&EÙÀXvJu¹Ø©[°×HÊêwÒïóŸÄrifZÓÎ‹ÞÁîëãîî®&ó”öT¶SM¯ Aÿƒn|¿¼ß²àŠçÙ²¢åÑûaÃ¤w¼	Ÿf“m,	OÝîú÷ÝÀâ£eéüj‚æFr*s¡Á¼-ø§o«w3ý‚°sìJI1ŽmK3u×Á˜¶ +Yh½ö©p÷ï_ïØêÇrhF¶U	ðâ4}_3q“2dŠ5ÅPKê5‚s^aDƒØ«í-úF¿(«SLê·@8øº5òza$® ¦ÑÅÊx5ëÆ7eÝ±ÂŠ¹óã¥ñ©û‡ovv®•d	ˆVm7Þ¼‡4XzHÙr¸€Ò“Gº¹ÅÂ€H¸ûÃ•Ã&ö^jýCîäJ8t9Ä ±,E?f$×z]I²—ý¥¼N<£´Lž)²ˆG‚†lÎã¶=Š«h*fH¹3G€k{Ÿ£K‹p)áxu·Ž[ÁÙÅ0°lžu£„¢pPá­Á’:”qƒÑÃ”Ž…!4•[19A”N'çWíËó«&,sst6µÎ§ãìÎïþ?ƒ´ß>êv¶÷º­ñàõ±¶¶öäÑ#…ÿ~ûä1ý»¶Áßáóhãñ“oÕúÃ'ëë>~¸¦ÖÖ®=^ûZûBãñ>3d)0”<¶ƒfÃá‚ßy2ÊüûOò¹§^oãÅoQpŒ—=PC"¢­ÜêøÍv~ï&ÿûÿú‰ZÊ¥œd
¥.I¨2·-€ú1IªI”\Ä &°Ÿ	é0ìßÑwj'¦%:žm„|£RP£ÎÈŒÁDµÌñE`þ uÈ°®ý„ÓÃNv¶½Ñ–q¡{œx:Ó®SÖ®t½X €cR´qÆ èÃ#sš«'™'sÚÎ€†Àó‚Ùø£Å4ÍP¼£èn}OàOÑõN94))T	ÝšÂ·0{Ë¸­—Ñ[g–[z{uÔÙjP£ïgXV†ª!uÎ§³áÐúÛâÄ”õRÊ(0’v7r&|èFšj.á7¿Ì$óÁƒt6€AµòódYú6ïdŸÍ¤•\8ÉŠÕ,éŸ³"Æ0-âv\— vÁ}ºb@³dzâøbN½úây)õ‚
¬ø¸H-äü}®^WÄ"Ürsð²ÓXçUÃðó9»DA%–†¼+»q2{¯Þìýïÿóÿ†Qá·Óþ;ö€£0q0ÊQ˜ON#¼1å0Æ¦¼oô4Ñç/ÀÐ®Ú½iMûçÔ¿+ø`þ^êÞ–AÃqÐ véÞ=PP¦³Ia»lÜˆGÇ Ï‚MFlt®Ë’Ù¥S¸›¸'ònkkardå¯,2èÚKÁYŸÀbQ?¼_0ÐÿøÿÀá)­ß¿¸Íÿj«Ÿàß“þ ~VíÙÚz›¯m—;SÍó`cmýÛæúzsýáÉú£Í?n>þ£BßÀÑñ&Þ"Ì†‰ŠWWÅO«ÖZëRxc´ý—j“1´–³ÊÆLì8¬{ŒuW¾ü:çë¤Ëù©y~ñ3ü÷T}w Çv·{ò¢Óë>ÿY-„§àØ¼±³3Þß2¯þÔ›ß^ì9Ï_Àó×Ûð}ë¯¯åñÂŽ–Œ¢y^i¡£ÍY­’Ü5F©ù,ª/w1œÜ+w„¡÷¿eÐ
kêBsž«mMiZjY0;£Š-Vétµìc	™P8o¼	Ð·ùqÙ\R½s…‰à\40g"«ƒh¢woEÿZo-ëbÀ]  ªrTwa³.ëe'}ÎO ~ÆÚªO¨P´@Ÿ”—ë©BŽ{06Óè¬Å!ÕƒÎ—-D‡¤ãýÂŠ#5u&G<%Áºò×«M?ÔkËz¬8—Kz<ûïf“¼ªOþiy§1wêS…Ý¢{6+º5?.=åUÔiÉl…ÙW#]{£w}iß_b¥?‚î¦gÄ'7U{:ž”xÜ(=C&^áL	ÑsJ·‚ÜÅ#Vÿ€‘¿qégÞkž>x „‰kÞKÌKsÎ"C3»6,#ÃÛƒê· ç~ Vµ8Æ±©2¾¸©ŽOhÜ´– ‡$Ú!(¾ÁÖÆ*:áJù¥–ª’&¢äl²Öé£ÍE¼à‘hƒåÇJ	ã¹HãÒ£ÁÂÍþcsm£¹þäd}móñ£ÍµÇ·“GÖ[k­5-‘ÜIï·_æ¾¼Ù…tc<€‹p4‹ò…o¼ÎuX”õ2]À6©R®´¹’ËªÍçYqƒÐÒýÜÄîÁ÷s@¬·ñ˜.z·{¼u²up´¤û69qÛ€ÍKÍÈ²w/¿»ô=M8}²¿‚å§þ¨‰GÞ`ÿÅöÞf|:<:Ø~½u<wýuÅþ€B¾µh+T{8¾\ßhm´Ö[[k7ürïø] þKçM§0^œgí_@'lÿ2x·ÞúckídýÉÆBH½­£Ãã“—ÿ¶_Æ¼ù4t!HákHau­»ðµ-r¶[ƒ…fL1ç0;ãÙmÎ¸€52îÍNwõ[ËŽbÕ[ejð	/?MÕïÝàU¿x3°t¾79}/hŒ  q¼°H,ÜäEÀÎixJYŠôW+ÇÈû›½ˆV-ìOÞÖ_o¢u²Ý}Ùy½{|âB*<]°ûž
yRF
äÑ©F›Ûôzøn<’úIôm¥îÆç	ó^év€~I.Såm¬µÎÿ1®„ ð¾MÿáwOú ÄÑ¼œ‡Åï'|-÷vGÿYX `Ÿ¶8•í ËŽx(öÏÑ ºßiDökLkà>i¡Øxø‡«éJÏ²ÃUüæ}ÂäŠ'üÏ	²Þ^kr5L¨<ÿ!Žør”ŸÀÓ|Ü’Úµ…ß5ÍòIá@ $« <ô‹¿ÀëÓZ–ÛLâ¬%ÑÂ1ñ(b!ö/SaêŸÈž~qŠo†ú~šE.ùBRÁu‡‡ªÐ›èw,­")«*JVCý4hŽ°{;€‡ìÅÁž*üÈ&OÞ\¿)¹(AaÐ¡ZÔæ6ÜwV!Úãe	Á=µuõßÙ%¡ØHìÌu£þ'U[ù ›]×@Š¨ÕÔÏO)m-PŠZ4‡Ø%—ëvK·u[)Õªj¿D#	’‰úç©ªuŽŽ€‘=4¦Ê7‡q ÿƒ™XãÁ»rÏØ9ÐñÑ³ZK9Sh¯|ÐD
Ÿíluvé—“ývâQÓv «]ó}ðéP³_3w¾þD0ÃìŸµótéƒf~[WÊxpÕ[ªÝk
ÍTÛ8Ë0œ UêÅlý8ÖÉ€‚Üù4šHÙÏØ
¾·ƒ†cýRþh«–þ“×-õl+›Â‰hnQnFFŒÿ>å0µÆ¼*„iWyà(>÷˜Êž€…'E‚aMãEG†N‹>6Ÿttn{xV©H²Y@Õäð,Îõ%§dÙëŒ:÷îáŽÉ×º“õÏãiD>Å xqeì´K]è·iîXÏÀ5P±åJcÆ£:ËùÒ¸©T —kEÃÀóÂ±ÜÜž›*ú"v±pGÚÂM‘q6°ìË™ãTõŒµ-¨a{ Þ7KªÍâ0ÞÊf|Çœ©âÂÂ9²wXy-NèæÍçŽÕŽÂ6Bà-ßäg,Bt-nîš1RÝ¹:÷´lœ­^o¸HÐÚ‚ÛP,ïÒExqba%ùÊ2â½g°G½$æX|Ïl)öÂ%\VXÚžV|$ªðù¨¶#&-Ø@Ãfù£>Ÿ`CK¾]ˆ:Ñ¸ðEI aÒ5ˆ¸*v-ÙÇí
s‚¨§ÞŒí+Ô	¶Ö_SßÏœÊMHÔ®ÂÌåii¤r˜ô€Ð¼íí©ThÊøÒœü<ú ïnwéqC\2üw¯·«L½¯,²a'¤þÈ€x žHY±ªR °ÃTWO„9›²™£^³²è²áÔqgfr÷„5†ê˜¤´úú¯Ð7¡RÊ\,‹‚þ-µ›ÚÒq¥i@ûc„D®¦ÃñU‘`í¬Ä¢EKxjq%¸ ««>âí¡C<îfŽþô<Œ+è•¥=¤Ÿîj,Œ¸cúŒmsíÏ¬‹ù<¼DÐQq;Fµz^·•¸±Éb`ìÓhà9µŸâÎ²hE…^´9Ë$‹X¹Z¥¹aWîZËÚ™¹Õ§@Býx,CEj°®[§èÀÃüÈLaÛ±7R} C¦_–W-?0T³±­(,¥§¾ô’MMƒ[j3j88{ÌY¿	¦í3Õ9x	ª¬„#½Eï)ÉwêÕz"æÔÝ£Þhf\ ÔÂ!óõ0œ.ˆú¨fksV³»J¦§4½]#n]»Nä†ZéÒS3ç~-ºÜ*g]áA¦B&üŠqbs×U>)“´C÷ëçtí:Ï±¨‰O¹bhH…¡s»Ñ2Ã+¹Šæ­Ìzcñ E7MNµ$Ab•'Ä6<Ó’+ï"ËòeRÑ)@Gä’»zƒ1ËÄºÓJ‘Xä+œq¯zBÐ²0ÌÅ_\½ÕfeI“'Œù+ë}-0çê/Kg–ú‹WÆ¬æîó?4†`Œ7nÛ<-½Ó“L'Ô)Qþ¬+} üvÝq¼ógíØ
5c°°âeÝxkm…ñž"fÑ£‚#}å-;^!þ(>â*6h™h9pyÃuwiÞx©Síd†N¿] ð;ÅÜNý†Õb¿«ùŸêý ®àx,íJßU5¿OêTP·ê]:>U©TŽw·w^òc Ú,Æ`ÚÄ>}xŽCä&Ãs›»,*DÎ- çwê„<U:‚q#˜ü¾NX¿°þ6Ã}PòY_‡6Zy•.âÊyWy=*¼óø‰ª¡2tÏ" éÆ§4ÑØå(1eå‘Íá(žêï±ÚBøÀ’}e›A%.,bµ+Æ×Ô“~J#Ø>ØëììW¬ñÂÓÆ—ÇÞÉæ>j1X½ÁGË„dªšzbm1TPC/£€ÁøøœQàÜ_moœšèìè~^yFÇNÕ £yLÅû©j¸mxâ¤Ú>4?V²Øy%çÎGË;Jîˆâ»éÍz&¥åUPŒ¤aúžÜž`mM¬‘G•Y©déÕzànäüÛÉìÎÂF³Úê¾:c¨Dæ€“ÝÞ±`7fåÊv†ï@™'30¾|ÜyÁ€Ø>y¹³[%ÓêKÁªª¨§®|ÐrÆuÛßñÉå 5}OÆ·‘~Ìý—úæþ½žÈôåLB,o44ˆÃ³²6µåàŽº‡ËÆU´Ä-Š†¼%@­o0ÙÅª•“¶®º¸SÒDÎU‡Uw<)ž¦\€ûëŸf'bkòG#á8NªŽ>6ÜºÍ7gKUâË¤p––“é#ö(ôëø•ÛÅ1ò9"¤¢ßxÑí•0çi>EãUÃÃQämöð1Ø¬zÝ	¬‹g£ÍM.?ñ^ò­üœ%GuVÄ¢FFB¬RâážSh›n%2
s,Ó/µZ¨ŠË<	Y¹	:Ï(ÃËíÁØÉÔwšR<÷ŽuKñwC!ÉöGUë*»¤ºŸŽZ\"—Ó0¬Z"ê£ *ÙêjÕ>å {	Ha •fÝh”eXäØÀœƒŠ»LÉuÄê0 Ð\ÀøÛÍ@»hèúÝ‚A¿³>;º!<‹šøX’íñ Š‡Ž‰ç&ð³9+‚àg–Ü± çrZ^q^bž;†"Ä‹8K'Q"ò„CtçRÐ&£·
à¶ÉÉúÕyRwë\	}sh•6 …~9K¸°¹áäK©»ÿïÿ±|	¹¾)‘.yíÊDHËÉDßív÷¿?~õ\¦O¿]à¯ïR¦1Iþÿö¾u½mYpÿ®¾/ï€£dÆIÆ’x§äõÇvÒžvbËNzºÓŸ‡PV"‹‘rbOgŸeìcì¯=/¶U H‚eù"+N7ÑÄÂ­P¨êÒçd8Íb£*,ÜˆãàŽcžˆýäR+J|€&o ðït<¶©@¦ðþ‹]T¤0xC:êÇ§YìÑ p¸™,F^J½Žf¸ˆëÿÏþ37Ø6dˆ )¤5—æÓŸðÅöj)­Áÿûßýð4ùñM¼{ËZ²¶6£­2>7Óø;â,úõÇ)b”ÃÇ3©wdqÚÌ@N„¾°0ÏHÎ§«˜XÎæ÷^.!
Ov<BorÚ`Ÿ<Ç
Ï·÷ß½yÎ®v?„ƒÑ	¬SÙ†ËúU+2ÏöÌÐ•’¤ì)©âiúS²™…³þø¤áÖéM¤ðÒ$ï<É+	Ú²®ÙCê`Tö~†S)hÏqZzKJ	*(P]Ñ:Ù3¯•½šr²wb2Ê^ØÄ"òV„ÑÞ;g–Ø™cýtYG˜âRBqQ’iž‡PaTœæ"ú¤X#@°$Å)~Šô&Äûzì5“æKoDð,AÛæ\óÓq‹¹IÈð¹øŸjª¤˜,ÐiÓ€oLÝÞ=T¿gÿh	I¼A¤ \i„ÁÈ§ ˆ¯Ââ'#Sƒ;)QM9æÊrØm,ötö{–
we{µI6¹Ú›J$vBG.jIÉ5Ò¹TAv£-¬„R';C™Æž;í#Ðð9ñA0\C[a.û—ûN¢›¥^1’R"Œùåü;u×ðY£|¡b9Æ=E78ÑF«…(Ùì³B°£ÎZŒQ„s¶Å45X­¨õl£V{N~ÙIôòyvEÒÓ	Û‰¡H‹}†Õ£©‹ƒÐç"Ë½AýTzÆ&.q‘–”O:)bæ/ï
JçzSi¦¡cB—©kå´¥Þôbîf-šçÂ)sôµÝ¾¤	•ö›‚­º¯6®öÿ£(†ªeþTýÿh†VùÿYEª¥î!å4æ_tr=÷¬v½KˆòTTàl{¦ýËtò·O™óXìœ÷(Î]:!uçk¯Ä×Ilÿ‹oF§Î}´±`ÿ[º¢ýÙfµÿW’ÏÔ<ÇtMø£Ùívà{Ì?uMM§NÛëøŠï©ŠMþ³Ùšµ³]Ú¡jÇjû¾fºmúºÕÖüÀ0´ŽXŠ­˜®"×ÎlÍÝ¨e8Žnš®a8vÛP­¶ÓV¶k;–âêZÇ7T*×ÎìÒT%h;šcµUÓ±Ú®×Ö=K7µíšn*–Óéx†T[ØGP‡*ZGõ4ìž¦«nu\ß¥0ß³Ý@ñtµí›¬f©QÐ¡ßî8mC<Oo«š¥Á¿†î·µ@uÛ®£¦Ñ¶ò „qu¾ãûm+è8ŽC¡—šm §­y¶J5UÕ‹Ë–qæXA ú«øºgZŠáù¦c˜–éªºÙöÏ4`I ÐŠÎô][ulÓó\ß0ƒ¶¾ë:®£µ-GÓ4_s5Ç¶©ZÑâ®í©ªª9m ï˜*,´c+mêwÝít:ÕU££™ky‘=™«ª.ôÆlû^'èØÔt ¦	ak.L£§8ºaYª™‡Ungjše:€¼z µMÅ¨b´uÇÓÚ
Ìe)ðÙoûö,¬™µUtXR%p=ÍóaEM
Ýl;Ša[¶«´mê¨Šx¶>J¶Ä£	Xa:>L±©Yí( àÚ–ohŠc©š8–;¯C¼/& ŒÄŒ¶üNGWÕ`[UèªÕ1;ªb Ò–@‘lÿLÏ4;žMŒ	¨¸®§;Õ=GSÚ®¥z¶¸†6rn‰{3ÀnŠ…3 ŠøèÂ›Ì,‘îQW§¾m;ãÂfÒ`Gzì°R`³&mC±Wƒ™Ul a€ÕHÿS5<ˆƒãhzàxÅ¾I¦›Z[Sà³ ‡LÍv\ FMøÛPÌ¶íÃÄQüß.ÌNÞîÔ4vLÍPt ÀT‡yA ´ˆ2`QÇÒlÅw
{,oYÕX[Cµê:¶ëvÚ–
O5X&×Æ- 5®„SS –êR@ÁÑhžb«0¤¶¦º
ìÇ6l§ˆ<(È\Ô,@Óp¡yjëNÇðT©¬ð)àµãR@]q‹“ËLjõDXÕf‹v
äÈÖ=@BX×Ul¨»- !ÂÕ`¯¨mÛBK;å ä$ã4ˆà„©ƒG"jÀ‰¨¨:œ,œ'×·5ÛÕ=OSË¡*ŒÄÈžø §fÇqÛ¸šŽ§¶ïVÇvÚSí¨–Ç…ëjANÚr˜ÚIê?'7~J-¥äRÑ4–Äé¸ªë+ŽM=à·`P8ã<Ë¦7€Êf@u:A[ïíXžoéŽßÁVwÇÕÇóÚ¾êPsÎ¼ê'ü"ï"OÂ À»0vÞ<Àc“@ÏOG2¢™ÀöypRËQ5¤ŠY
VSO¸YÉpp‰wÀQ¬2[GO1-`<¨áh`TpµÓ8@T€jƒãSS+ÂÔ¦ïèv›I-×@2DÆhÐj§¶;Šømàkn4|6¯Ôk0^Ûs¨˜pNµmŽÿvøà!l˜$Î¥€UýDz8:‰ˆõXgÁhû &Ž_q¨®S­ÝÖLÛ‡]kX®%4ÅºöF@Kðds=Ð}yC»­tÃwàHU'Ô÷ST†ò™Õ‹3Ëú©êºíxHtß°lG¥°,_³¨âÂíÀ©Ý±ìR˜¢“üä_ÔœÀ2m !š´Có¨ÔÀ÷Õ¶t€	Æ9Øåè¤j¥³ÉÖÀ)N|ÃC&R`kß¦Y°;–[¾­Tå„{(”á#TàÛTÚ–gÚ@Zê°];xÂfÂ4]QãÚkÄN@øH¯c*ŒŽØFv˜‚œwÛéèÀ§R ó£Í#V¥$€sz–f¸ž»ÜtJEñ|UõMà}€oQ«m«Š£0º2äÞîÖÎ›ÞNM÷aH®ï88º 0`mƒ¤Ô‡Ó1ßWÝ¤^æ0qIfÞ|<O“[ŠÛÖMjŽtÓLj&·VPÁ}I	y¡ûnå~Óœÿ‡ò2—ÿEÓuÿa¿™ÿƒ˜÷Ý1Lpù¿LZvî]QqýAn0/aý[×«ûŸU¤Ç×T$[|ú˜¤ä71ð!zÁ‡ìmD‹=Ný™ôÄÔÓÛ½gP§çÐ>z‘Žâ‰E”hu,¢F^ÁI»“i¿¿NzŸñ% SøÚ2;Œj¢Mž6fŒeáû&‹#¾÷b µ »'OC=C×ä÷â‹Åøñ®jïøƒ¸¼6|ÜFá(iÝa4½©¶á Œ<~aÝ<˜N0ž'/Ë,¥„•³¬›ˆÃ	álO`J†Ùœ^à»hfAYntŒpr‰«Ú° Ø7¾˜hañA-}†ã}zu°×Ð›Ê_–ºˆ¯1Ö€úØ:Š U/æ‘“q@0™1~acs‚¶ð÷†h©l$Þí
n~néÅÀ1IL^Ô¹g>õ3Rú™Î·rKœú33¿|ãšp(/bf1mÈ.z€˜P®¿à—®âQý<Óx¤À!.½aM\.ç.6š¼Í£äÍ;A8a_ðù"¢nû¾¤$!µÌâç0x,Ü™ÓçzŽ{{'[Ç½£ý×»?oò£y©ƒ$_Þ*87'¬à¬“QáÃ„½ÍûÍœÕÅzÎÆ¯èfÁœ±ð”`¢ŽæU ¥¥Àòö˜ÊÛ pO¹	__ð™¥Ðò=¥®åÔYKû7kœ!X¶³‘ 
ƒšÅ0…#BiU$³™ ÌO¢ä#Z-ùÛ¼h¬ËàÍÚPIðÐbŠéÔ°¢³®deG'9[½B›y_è˜áÍz„•á!§çŒT®‹ž+3ÀÛ!£BsØ]Ä,<»K“(VyÚñX¡Í¥RÑ¿–nðï+éïn©ðäp/m\Íÿ«ªf&ï¿†©jLÿÃÖŠÿ_EZÚý%€y2ÀCfÿóNÌ^
GŽ‰Ÿ5¦`Ê,>%ËŽ"GŸgÃ]éŸ$“†\œÁ(Qµ,zÈI¢­
·"ð©’nÑ?væö€Ý–qfV›7i·×Å(v>ó¹|»yØ}‹ž§–8™\ƒôÔîÚûéßÞŸn¼ÿÔ"¿pw…	kùåW²–”ôüÓ.|ÍØ¦/Ù§›¯Çí¼¤nWòƒ˜eE63öør–n±©ÈW,À]f–¿RÙÓÒ²Rá|`hÉ›•Ý¬Ë…9ÅOÂÅ·( 'yWRKN²<d'¬fšÍ&q÷Íün¹d,±µÿæåu'„¯Ä«ëY’¶wÓåM…‡/BˆZ”’ìüÄ¬ç æï3 Ð'c\Q1zL/Ñƒd-às~ó&^*›Ët£
ÓÏÛoªÂFå„üóÅewýØ`Î“ÑÚRé '¬?g¬Q˜Ldº³Í`Ué2“é/5nB„«?½áæ¯à{½æ‡#Z@ó†©Ý5Ï'ò>þîß$:u¢éix¤¨¨H´ï[>=o¦Ãáo}4¾kœ“úÙÿ±þžMõ¨µA^nîîíl?iµÒ¼'‹¾_íl·êßæ;´I,¤r@Þ?%ÿAfR—[«“÷ÏHc<Œbå·ÏÎ¤k­¤½‹¼ü|Ìvô7ŽÄ†ÿŸ¤hr76··y'¾ü!¢5¦Ð8ó?ªëª¨¿*3.„)¸H	r'÷&‰'¹¸IG€—ß	Ï­Âí|^“6ÕúåZ·ÀB¼¿ì:ùV©A²É_‹‰Ô;[Á—
¹sKñV³¢§II‰‚g_¥€
 €Š—*.©üéÜòR¡áÕ@‘¼e¥™%V¡^Øu¹’ï™B™+„Ä|¦dÊ…ä|I_C7?§…é’§4÷É w©]v£‘œvU€¿A&#—²}v£O€Àn‡ð#Øß~CêÞ¨›9£yÍLY'uñ=ñ–ÀøÚÔ²;ëÄ$Â^”˜q7ì,<ÞMB°‰Œ<ÀäpDï	ø<Ï<(HƒAwÆ½#æRûêá$=’-=xÓÙî‡€L»ÅôÛ˜bSšÉÍ<ñKf™|X‰iX’5lv×†}j>‡Îyá0œti¦ºk{èüjooóh§»E°°3$¿166-T^ÊM¿g8—ž|é‡Þ…a<I³"žUÖŸh(ŠãÌ>g¦Íh&=()F| |a×2_ÑÓ1ÿ0g™ÅœØ”˜^XS¹z—¶¸9zVÞ¬:3<—ªNÝ€„Ê”èf02Ku	ÄÇîZÎLü+mYÖøôìëv>BÎœÉEÒ­Äº$Eò÷,‘•M¾#\ždÞÁ>»kçƒÚ¾õ5~1½ÿòîLkuÓ{©\Í{¹m,ÐÿÐlÓHõ?,õ?LÝPªûßU¤êþ·LD2xø¯e'	ÕmðbxÐ·Áßæuðµ®¿Æõ!¹Ë\?ægc‰ƒ¿›‚=ÃZ’‹,f´4ªŒþg–Y÷wÆ,²ÿ×+Óÿ…‚ŠªÙV¥ÿ¹’ô˜‘{)¸žêFÞ¥*ž‘˜¯ñ|\™`žžåõÒLƒgn²«˜$Óä™‡ÒíMòÉÚ3¹5È ô:ÙßÅ¿¶{;;©çš›ïØ¯=Ë7•V.·Eü¿!ñÿŠúÿ†¥XÕþ_Eªô¿%Þ¿h^ü0yÿ9àå¬z¥^ñï7êìïŽ)¿_þù[O>û¾Û¸¦ýŸ©Ù†né¨ÿ©ZŠ^Ùÿ­"e6Á÷×ÆÍ×_W4¥ZÿU¤‚—ž{iãëoëVµþ«Hy¯8÷ÓÆ-Öß´+ú¿’4ãÆèÚ¸ùúZuþ¯&ÍñBµÔ6Üÿ¨ŠjÖß4ÐÿCuÿsÿéqÞH¥¥Ä}Švä“ œ0È/ø°ñ¿8ÂL<òëwX|TûŸÍ,³ÔqÄU«=¦Z-?"PœyŒm÷'ÎYT«lýÐ}‚o<a¡®šÜÑŒD{7Jl Sâ>¥ÞÇÌÊ–Ç/p˜‡õÔ¦™÷[Ö›¬“.©×ÓÞ’Œ¬Žj€ø@“†U—KÒ,+_è0¢¬ ×»Ý9<Ü?Ä—ÚÄÄšõ©´&LŸ¯ÄŽ'ñaÏ× Ó+ªW§³“)Y×NN'<î—<éµ…•+›?Z*÷Ù·Ü6®{þª©Ú*úÿEžÕù¿Š4ãìÚ¸þú
üÇø?£òÿ´’t=O›wkcÿ<Ÿž¬?z«#Š¦hº]ñ«Hÿƒq Èµ=ZÞ¥û£Û¼>ºÅsà’ûœ{,Ý	îö(øèÊWÁGóŸÍ¾>*>òèëärzFèú0ÒñEä@®Ìqù¨øJÈáÜðYïÑ¼w½%¯‡ü²÷hYO{Kí#&Ä4¡$çÜJOýÁ„#)Ïæx®'Í
óÍ´á[ŽË+"h.ÂXÁb–ûzÚ¨'Uf”ÚÈF©ª[Za6P.VHr³r‰V¾æJ°f‚Þ2X›/“›”ÁÜB¹\ÜÛ´·_LKnï¾Þ|Sl•çf¥PÀÚž)Ås¿°åË[5â¾Â?ˆ¢@üþ…†Eü˜¬È²ªÏS'¬'ÅÑI,ÊÞh/“õ®ø5g-S—×!)Y°Œû’ä}g|À¬uø„Ëù‘ôÍrò‘äm…£Óó’Kñ9NÊ!ÁÉK',à£ÂÎ(†/ò’ˆ¬=:zƒþˆú[tãu"³(Ä-¤Ž¦#Ôuøp~ÖHÔ'Äwá¤ù(‡ÑüR£°1ž„gc)ã`Ž±9á&Ûr)ÍV#‹_Û-úÚXÀÿÙºžúÿÔtÓBþÏ¶+û•¤ŠåË±|sÿ!s}?O#‡Æ—Ã‡¡Ûh1!Áþòt.ã·íDdo{÷%ðN¦æòYîž<*j‡9Ó –oÐQ“¼ øã;“€|tF#Ž5áLø™3šb ÙÜ_þ )ùD'>@‚"Wz‡>.yÀ´ÅÛdv„cÎy§°iÝ)ðƒds4„=<"7<ÈBŽ„xŠ¹ð¸ó]ÀÄÁ‚®¡{5ÀI¨ñ¶Àù	<a)¿í†æ'Ÿè 4*«˜b8€æÝ‘O?Œ}Ò>vtN½Ç	 Ïa¡Ž&ãJj-mšýÑñFÝd–×áçCÜÍÛo"ü™+m>ª…îàŸ¶†@+7 •h¼?é€¸Ž
ßÆe™q8.äøQÃúŒ'lø£îóB‰pÒwFÂ·£3LÚšJäùw¯÷Ã¦©j_ŽÞ~úKï|:ð½ãGv'
ŽÔÁñÁð]çÓ+ÿû}µ=þØ:ýøéüç—ýó§öwNwß~<Üsþk¸sî¼*“­W——Ÿ~lF¦a½íÆ¯^´~Þqèt°÷öQÍmH¨å~ƒIÜ^RfÞ(Ì,+6ò<@¬m »Aë¤ È‚#Ž°B@\ÎÃ0üŸNÂiÿ´¿â¢Ã	Ÿˆ—4ÿ¥?8§£7.z°Õšl!ÙÔ
qäçöÔ­Ðèžö9ö³ÚèkâËiŸ•‡”wú0GÄÁoð_>‰˜&ôÒˆú°ÛR÷_½¿þËï~ú~šþø™º}ûïÿøÇ?âKûç‘ýá"ØÞ9=:ÛýaøÓ»¿o¾ý¯QôéÃ_þ®Žhg¯ýéÕÁÇÏöáEçÅ›ÖÏãÍÖëVïëì_‡?¾iÿK;T8˜fhå½’JäËÍÙàiƒDŽs ‹tEÊÏÀK4`/ËKðUm 3æ_YàÓöDy	t´EaŒÜáÖÕe&™—y€.Ð/MÃñ†sº‚Û}Øá¥ËË [êFt1òæ| ›!¼$ÀÊ‹}8û8Húó¿ÏŸ2üzÅ|!ÏßàZWà|ky3ä/æNTâÝg›Î‘ep±¼¿Û`«æÌëŒ(NcŒÅ^Z¨üœÅÃ¥7Xž9ÅÓ,EõÛ¼oñöäÛO×`w§6Üÿ˜ª•Úÿ©ŠÆÞÿ»Šÿ»’T½ÿÉ}Î_•î„¯s¤)×¹
Âªöþ‡Êe,^ÿÄPââ”ó¹Çg}Š<}sö:æÕd:òSÎƒð†ñàA8ìcDQrMäLƒô‰qó0™µôª0® A>ï,tlŠ‡!¿ôÉÝPU7@wê#ŠXüýâNv‡%Ù‚Eá8fââþŒ#qc˜:ýN&ôcLú”áLÉ / O™„ÇP„íoö*X}d±eØ­_“¼0ù‰cÊ‰ëxw1”ƒBÑ,Ä;$Á¨´-¨†0&’_ÓBD·nŸ°Z¼N"ôª–Ca•LÇˆÎ¹àóy²{šË]‘Ä5Jæy³[o…ãX„Š©ÏÁw½n½àóäêÅˆñªÖÔšjð[®+½â•‡ï—ãn¥¥‹Ž’ç (í^¦ ä„yÕ”ú™<6–{üfÖ(…n oLôØ)ÁH»¤ü‡®ª·;…²½Þ^Wµt«}¸sÐmwXiÁÍ†ÁwOÂÍnÝ%äSLô¶·ÿòèÝæáNqÙ¢0ˆ1¢Më<Ã‰ÖL­ŒMU“ß¿´0MI¹—¯ßåŠgŸJJ½ÝÎ•ŠÏýV2ìÔuÈnFêRü=º[îÉ1-‹‚¥„è,2ù‹pW<°§ŠÒ›/×WOä«´â;ÿèíîÜå>|Œf@Ìú5š¡9–zÿfwëGÜÝzòS6\„Z‡¿Ò1ýFqÖ8>¿wŸ<Mä%O“ä·ß˜ÖÁ“Dkâž½ ,›ƒ¡v™r…ZÏåj<WËçê<W¯ËrìŒ»át%š=¤tí`ãwhcüg˜™üìýßªô?W’*ùOîs^þ›³²2€Ê‚ÿþ¿üfsÁÏ§ä–eYð…{%ù?æ"âMß To@43t¨g¯üÌ×Lù¬á}élsSfYãf2!IýËÿ²,n¡ 0[m~Ør¨ë#1:¨Û¢ËI˜³"&àfZLO—K:Äêlê„PI¢·ìãWÒEŒdÌTÀ5|}ÆÐ±ÎQà±„»XÎ'YLRÎ=aè›ÝWsa!ÞÕ9$9o9,¡·›`ï]TwS½ÝØïOuw‰*¹	>äK%¹Y¹lµårY.Wßåe7}_0ÃÜ'b½ŠÔ™vï\·§-T’åÏC‹ÔlÇ%*¶‰üYµÞø¥*½B©».r]¹wùü|ä,÷ ¿hˆ)%¿þ ‹JÀwæŒ²î9¸pL&¿¦R¥c82\¢a]\ñßéÓÔ5ùÿ;i /àÿ5Õ03þßDþ_Õ¬Êþ%©âÿå>_ƒÿèêÀü";BE
ÿ¢*0ù(³ù7Vž#UªÁß;.Þ:]Þ œ-Yòq÷°¼*åÒìù¯ŸðMw‚zZ'Â4êN€í¿%;ÿuÔÿPUµºÿ[IªÎ¹ÏÅó¿|'<ìã_º D§A¼×dèøB${rÃfÊŽªñ8Î±Ò•>ð'àUÈÂñ}ÿÄ4&93Ñ$›#8|†x3Ð8—!5ñ	ÎO¡.K}®âHãê>î.}¬îãî÷>n_l	$|š¸âþîæ®{·µØ,—ëÁ¾¿²Ç‹îp4ü(ƒ“’Î	'‹@Èd#5‚÷†SŸ¾˜@—ØMÒóì‡©°ïn3mf‘¦‚ä²¨ìŽ«‡”åŽCbÌßÐ]Ñÿ§©'"\ÀàcÖF±zÏú¿ºÙ«¶¦àû¯^Ù¯&Iüßò™Ûp·`þ–Úáë§j'RdÞÇ÷ÙNÐšl–bPÉ÷Oº}…Ú.ðR,æÒG6˜»wsNj#µÔÕ€Ñ’8§„]Ô µ‰ógìTÌ"d¸w‰/=º6w$bTŒPµ0ëÝÎG9,9Rú¦ã¦<Ç5Ÿ¯ñ(QI‘)a¹¹2Zi-ëÑŠ×~S”îÌÂÂÜ´ØÕ/×bºj¢TvææYÇÌ®"Ÿ®`žñŸµú¢§8žÔÌû—ëq_±˜x“Kò¤	KŠoƒ6	”âáur
…KÉ£OMø:f­þ„ëzÖ'AW=ïÕrAÁ³g¾Yw<µ›L7O§ÉD@CãB0ò’/»Ç+–=ËÿiEþO[)ÿ§êœÿ3*þo©âÿD‡+þ¯âÿXãÿWñœÿÓ$þO]&ÿ§Þ‚ÿÓ~üŸú‡åÿæ¼ÿÞElÿÇø¥\ü Uüß*ÒÌú«z)ë£ßAXäÿA13ý?œ;XÝ¨øÿ•¤ŠÿÎóÿó7ÁÃçÿïh3¬?sÖ€®ÛÎfb<ç]¹½	}úmÈ	ßBèçJ–xp²„^ZFÿÈtvÁòr„$=XŽëõñË¢D*PóòƒZàœ¹5‡
(ÌT/±ãPKøfvé"ú'@k¥ µ+Ak% ¥ÁH=Æ…B‡ñÞtB¥Ý£–ÕÑ®®£•‹>¥rD*]!HÜ@Œ¸…L©?$™R¯dÊoX¦¬Ò·“®ÿá~ßlÅÌâi:óÿ`X•ü¿’TéË}^âÛRþÎG›dNÈoèÒaNTŒÛ:t(ƒ7êîJ½7Ì *uçPiß¡•yAƒ<	BEÉñ'}	*ãõN6{½wû‡Û_’`Òj¼ &a9üþéÛf~GüçaŠºOžŸI˜°éw×ù
’†ï‘úfãg§q©4:uÈÂ¡OŸˆªÀ/§Ö­1"ê³öõèéãä“>%mòç?ÃºDuÒí’ç¿ °_Ÿç³ x1ƒ,òknxé.ä²0P “ä5Û×jÜCWÜ“Cºß€—¯ê­ø˜ea˜í+`û6Üž…¿»(	6õa‹Imþ³ŽDð÷K]†…?í3wäxÄ¶¹dÓcnºRIøm±8ÜÓv‚-dc¦ ¶þ½ŸGhØH1ò¸·sø…Ì©¶™‡ŽÕ¢úr§%[I@æâ.©V`+€(Œ¹ÂÏš
X0;Þnïï‹×w×qÒy¦5è´$‹pkôMy¼y¸Þl–ï®fÉÞ\`½1Šçß-7qiS¹­¹eª¬ø—iVÿW/êÿÞåéŸ¥éÿòøï•þïŠRõþ/:\éÿ>¤wýJÿ·z³ÿC½ÙWoµÕ[íƒÐÿ7ó@ì£³æøb<Æ"þÏ0­”ÿ³t…(ª­+zÅÿ­"-ëÜ,²|»£ ˜8À{/ÆËÝÃglÀ<D_“Û+2{ã.ô^Æ¯–Á³›ªÖTŒƒ7‡»‹CÑYÂ:K¶Ã3gðptZS³ÆMH!	ö)sV#s}çIàŸšÏæü„±t,u¡VS”möiütm{ÿõæîñhmÔ)=áõêÏ c¼°¹ žW 5UÔ¯µþÕÉŸˆÔ‹g5v°$£øiª¸`‡ÚŠ¢ÖŸ%•£h˜Ô¿ªr¯·'Õ×²úìBvÞp²»n¬ø‰º°´¯žv#}%uëùg àjã	vh#;Ûº‚‹úåOÑ¯k…Éø®Pü ™æ™â¸ Yq~Ù~ÎaV<›Ýbi¼’ä5Š¥ÅtfŽ³ù)ó—•NŸ²æ”ÆƒÒ€ª‚¼Ûë%Ä€ç0úÀsžòñî…‚ÓI§Zš‡õÜ{OÉ:esÂ«eóqU-Ä!sórUEœ©7ÒæÊægQ­lÖº3ó´$®êkŸÖËO³ö?ó¯>nÛÆMìT]åö?•ÿÏ•¤êþOtø÷sÿWÙÿ<®²ºK|¨w‰¿o_·²ÿÑ¸ýOâf ²ÿ¹ûŸÊ§Du§¼è<øÚÌj•–žfå?å„Óv™¾ßø¯¶™ÅPAÄø¯zuÿ¿’TÉ¢ÃyùoÎ&ø„¿ÆVp†1ˆqh“ÎQAÄû†”A*!ïJ!oR	y@!¯dÁåŸ¦%Ÿ	†^ÌôÒ¸“¤—@Le½œ&tNÜËÔ o$ð‰~f"_yÚ‚ŠrßÁ/[§›ˆ~W×Ê	r¨ŠËÿoÎóùÊ qæ£[Ê} #8•pc\²hE‰­(²eÓñ0¤¶¹ƒ™ÛïoNt»–ý?ZEÜÇ\Èÿ+RüWMeü¿]ñÿ+I•Éÿ"“Dþ‡lôÏ­ãÀ ‹ôú£á5³þAGSœGÌ6c(ŸZ?ÌŠfÝ@A8ìÓÆ”Ë5¿ó8­dp&zÜ;ÅØm4¾Œ›³æùR`XÙ¬ßg†þŽË¬1áwnÅ?*1ãŸ3†„|#3É)¸|8S‘¥soÔÍì5¹ÚÚèú¨Ÿp°ŸÐ~zg£?]gØðä™A2?žÛ001AþzH‰Ö@ÝÐ'¦áÒSç|N6Ï£ã¸ò`p‡>.yÀ²¹½M`–Ùá9/(Há@ÔÜ)ˆL°91"îBù•`€²óÈ‘â8 oêÆ˜±Û+>Rô
 h~5à;†O^'gSÊ6nö€Þi¨5"›[{kì8÷'PZfàË6åR‡ˆŽ¨¨	ˆOÂaVÊÒIŠêÈùDìÇlÔŸÂaÛ§±¨Ð}_W›Z³m(MUÕMÓjªM£ÙVÌ÷õgXÿ©°î €¤ßÇ&³¾!ä˜þ;1 Ò‰Ç©;Â©“&Z!¼—ïëß!£~z
Þgð‘¾û#èÚ¸ÂÖiÁæO€­ÃÏ,‚Üö›æ›€<«/2ôÁÎTøó5ð'ù¥ P
m1= ËÜYþ¿4¼û$€…þ¿-ãÿmŒÿ¢j¶Uñÿ«Hÿ_ù<ù²N¾†$p>p2y†½GÆÿ!óýsÙþksý·aú+žõ<ÿkg0$?„‘ð‘×ãW}´ùœ#¹rÓE;‹Çðú
Ú†ž3ÄËSÞÂæhÌ±¹µ}¶”ìn3ràNcò–N`¢Ð6¸­›´y3DÁ¾ŒCà/ˆ#ºtƒÆ£sg8ðŽè5´{1ŠÏåíäÆ¼Í±ÔÕ×ëo<ñ0Ôà]Ëµ+²¸Û–_@©Ëd¼€ Ø@kü|´þÒxçŽÇ>ZHi©‹#áÝ)œ:–æçú–åòîrhiï^%ßÓ"ãštž8^œ-´µ©7p†“?=—Ç“ç[aÃŽOc}4=œñ6ôõ¤¦¶>ûMäðA¿¡SZœ;~$Œ#éˆÉuÐ#a5R\ŸÒ¥9@#gÈ«(…Æ	§gcŽúñiãºÒ{ŸV~OÞ&%Jë§h¸1•í<¤¢ÂP6 $6@Ã FÑ3ºQïá“¸Oz?l6Ô\'aÿ~§qÃ{aC‰Ê>@!€)€}3Åú,bÏòŠ#cx(—=ƒ=”«O7lÛ¶€_¼²Múy<u0,‚éÜ°
u
-7&ô_S8Ï@¶šNà¸Èf†wéæûh>JÅ <‚0uk„:bõ½
£n…Q÷,|ýÁ¤ƒ¾ òyâ>À“xŽ"}gùX7ï‡vwä.égø „¡ß…ûô³`—ÁQfàX‚“Á„éä+?¦ |#¾Ó,x|1ï; w„\Ó¼ïÑÔ…£ÎØ´ fócbà¥™¼ëÑ_‘ÃüžpOØ0ÈöLæ$?:š.Déð8¸wÌ~ƒÎpØèëÖå<óeóEoƒþûÿ$·Aï¤Õx—Uzð)»ÿ~|Æ(…ú-f²¼´6Üÿh¶ø7¹ÿ/ÕÒU­ºÿYEªt>“ËÀùªÞ¹—ìL’“Ú¸Wj¡ÑêN¦!X¼¶µ*ÅÎvÑŸHÎZ\æZìý€;FºµøA~¾I-)£áœþ(Œâw(7­*»¦`uÿÍÝ1O	zk ¯÷XŽŽ/€y€…"ãYªˆû(§ôãð‚ýx6ˆð¦"üÈ~ãhÛµù'çs|Q×T^×¾Ôn;O°8bÜt¸Û¯{;ç°AŽ@§°«€òHFŠßn<…Ì—tÓ?‹šHÃ<z%˜¶³pÔòÝpÂî¼dßn·W,_¶ ŒþÏ=ÿ—xÆ,8ÿU[ÕÒóß²m8ÿMÛ4«óiiÔRÐÌŠ¨¸€Îÿçöö_ Â2ÎÉ‰ëx§cFšsùô3âól>W&žÉ§£óä}57%j®(žßnÿÏ¥ÿ¸üK¢1é¿bdòŸŠþÿ,8 *ú¿ŠTÉå¯(yß”Ÿ'YÿpÙ¬?Kè¿®hÌÿ«¥ªºeXxÿgØJåÿk%é[£ÚßÝÞ‚õ!tÉËŠNß+^&$~•E‚épH8É'aÀ$'Ó>&ZK 4¬µCžÃhØÌŽ´Wd‡Z(JPtJ1yy¼·Ggˆü' BÓ;%ß³`€#ì»öýŸÕÚRgÆw01ƒ‘7aï–Îêæ'›e][××usÝºÞ<í¾Ù:Üy½óæhóëLçV2EšÆ¦èùÜ‰œ
NÌ¢™øÚ§R•V•2þƒù}FÂóÄµ/¥EüŸ•Êÿ†aYúÿWíêýw%éÞäÿ  ûŠ<Yƒó‘dí¯d(×ó¼$qbR`'gü+¦b7I‘gT›J‘i<ÿ$Kö½×ÂS7*³F0‰	àèúqæÅÃÄEƒG1È†‘c0¯`³tÜÿ’Ð†¬;ŽhÔ'¢ÞÉ|8Õ´™ØªB·ž<e=}Ö$›þØƒLjô'!p°Øy(~
…¹Íwi€Œ%sHCq³ö8WšÙCÀQ†‘y¬æÜ÷hê‡ÄÏ.;iM£Ik8p[b˜âßV¡á{…Áç5K(]ž–¦*båpô>u¼p*¾~+¾¨¾¨™Ð»X†JÎœÑÔ^	<b•ƒÇ7‡–¬\‰B7î`í¤¿Ö¶)G|h¨‹Á8ÙŒgí3Š£îˆÆŸÂÉÇ&·©¬m13IíA²­]Œi7 Q 5TÕE[ÙÚ+Ü±ì§wP6dºã»3ÛµÏÔcø7û­ÅPìu÷ÐŸ?úZã…ÃqIYdiqäâGƒ3Nãõºº¢Ô ™‘ïLüýi<žÆ]@8X‰¿xá(
¡ûÉ×É$œ?Â˜	ù•Íõ_\tÏ¦ÃxÀtr“©ù]DÈóü‚òÄ\½«Ó)-òÿ¢ÙfÆÿÈÿY¶YÙ®$Uï?Ò=b÷è¥"Þ!
ÛñÄÙ³"¯ÇØ8öEøé^ ZQ‘¸Œé$½Å±`/øyúG9[Sf%¶äKÉ”õ€È„gƒËÛúhäÐ^À6úD.Â)°U„Ù†g4M…—M¨ÿ7¡aaà†L0àA¾ZtN‡>…1°ÓdDQÑ™\@Ýx-‚ÙDM5´óõÑq 6†|]ÒVŽgàÄÓVtJh¿	³LšèRöd<	›¼Í£SšG6Î¤>'â,ü…tÎ¹3²¥–Ñ8†ÃÃ.ÅNŸ0¿n{{'[Ç½£ý×»?oíî¿©€—:£h Ãˆ:äæ„Ü?ÜÜÚÛa—f‰ÜÁ#a;BÈÁ~fâÈz²#œ¥ÖTQZÎx,t9Lq'É2L÷• ¥¥À¶76g€! LFÂÑ:;ëéMãzþå8J¡¥ñX¥®¥®Lçö/éL+w)¼õãñA2n	ª¸1^“”W…¹™ÁE ó“Ø:øþ~r&Týòõ»ü­@3Öáý}óí¦ÜÑ¼€Ìäv,+š¼	gK‰ædÔD=§ŒdÍk3¹ÖevE¨µÃÑ£­+à!o'‹ë…
LkíÑN(A6½ ‚g†ËˆŽ+O[" Ž‡×R)é_K7ø÷Õ5õÝSžÿ¸9‰ÆKlcÿ¯¨:çÿ5ÛÐ-Ýbú¿VÅÿ¯$ý²óæÕî›_k‡4ÃÉ@ùkõ[î8©«6þ_í—W;ovw·~­õv¶Žwþqr| ´z§wòvwóäõ?81ì ¿nà—¦?X¥ûKeòÿE–ìÛTÓø†m)lÿJµÿW‘*ù?/ÿ?dÑ+§ýÉè4pn‚Åt†'borðZÁñP^brÍñvz/•^"!~ÂW¨á>Õø¬¾ÜŠÛá4&Go·™3†Ñùèþ`™7øÈt÷@Þ–ÅÈÛtÙn6ÖóÚÃ'óíæa÷­3œÒ%vV¨·ôÔîÚûéßÞŸn¼ÿÔ"¿"GüJÖ’’žÚ…¯™Üô%ûât^Ú¹³õ¬€+
 œ"eEöÞþÖæÞ—ë´4p‹M@¼bÌc<—£¤²§¥e¥ÃùÀÐ„0+ºY—=rŠŸZÌÇdR oøži= Ù‰¬™f³IÜ}3¿[nKlí¿yyÝ	á+ñêzC–.¶wÓåMo¾ˆ‹€¨U@)ÀÎOÌÃÛ ¼à, Ø[Lr¥é%Ð/Ûg	|.pžÀÄ‹Aes™nÔM¤¼7ÛšWnTNÉ?_\v×ØFáá@­-•ŠØáÎH´È(ºã²Û¤äR§†¹¼ÐË&ðdo·wô¥FˆÖøMV2èÖ›DÚ¡â*A¨Ÿ‰ÛÁ'ƒzÍG´Æ+á®_óübä¾ó×ÒB§I!i;g_‡ìk]¦uékz0[û•+…[h¶äæJáŽš-¹P*-68-T¡×ƒáÜBé>‘J{W—æ›0+¤$7elE²ÏŽ;wÚ‹E¥Es…¤©KIP:kýqw­Oc1>P?<å¹üªôïÅ’oðÕOépœdÁTímÚÛ³»E†°Ûœ!ùÉi¡fw?ø¤ù¶‰ÃI×™ÆaZ Œ›~Ÿp Ãx’fE<«Z4ÅN<y‰Ñ»`c<]Z&Ã–”p¤;€û¼N€ÕLåjdN²êôfÕ)¾uKÕ't|3 R””Jt3ÜŽ¾	œbâ|v×Î9äA‚;n:UðëtÌÑbš"Å´˜ùØ];c
Fü]32K©£FU¨ˆSŠÉÂƒÍ0f(s*÷$šž}ÝÎ “«éÙ™3¹HºåG°O¥0_enüha/ÊbîdAu¸?î²p:O,i?ùŸ¯ŽåÁäü¿^5œµå©p|³WÑ…ûŸ‰ƒ² œrÞÛXtÿ¹3÷¿ªQÝÿ¬"Fè­6ñ	¬y·ð‚ÉñA¨!KxÒçê^â¡àk÷¾JwMåú_L0ZÚ5ð‚ý¯IñÑðõÿu½Úÿ+IÕýoQÿ+Ãýoñ˜w¿º¾.
T·ÁK¿¾Öíâ×¸=#ä1‰)¸~x½@–8ø»ÉôØ3¬ÅåH6*d÷ªc>sþƒØ½ì3fÿ¯™ÿÓÔ™ÿ[­ÎÿU¤ÇŒäó#…%xF¨¹ƒ€“˜¯ñü½íÍ‚Q1OÏòzi¦Á3™³Ä4Óä™Räô“µ!Š1ÇÛ¨E
¥×Éþ.þµÝÛÙ!‰=ÜÍwí×žå‡›föód{çåæñÞÑÉÊøÃÌìM›ùÿZPíÿU¤Šÿ—øÿî?PþŽH9»~¢”ð‡´ù£òð¿?Æü÷a§y_iæüÏÂ.ÍÈ‚ó_·³øŸÀ
àý¿mézuþ¯"Uþ?øÑ?ƒöWþwpr 7tæ™=€È'xmŽ?Ò™-qõ±žÂcO·µûwúQ¶Ö÷ë÷£»j÷àúã-ÝÁûÇµ ßÒÈ\Ø¿yã–ù ‘¯sîÇû‡ÄÜv÷vÞl÷NRsÈnm0´€l}ð?ªMuNTKkÕóAò·¤É]1÷Òð‘ý×t Ý’=ƒÌ­Ž‹UAuükUšPŽóIõå9y`ÞE$ÿï€ÔŒN/obÆRxŒE÷?ª]´ÿ³U¥òÿ¾’ô˜<Ùõ7È“åÑž¾¹ë ´ÛÅK¡Ü~Xî•Ð“=à·Ø D€¯BŽq”à^$Ç>ÊE’¼XŽ¥L*KþØRÞœ1x#” ¾È]ü¹Ç‡é X¬Û·áDt·æÃ"ù^(î#¦¯Ã/á¤_ó½’fÖ¤ß€‹“¾3JüUä¾À±Å!z£.;‘£õ2Ø”àŸg«Zò†[á(‰ƒNRÈ4„³.dþùF¿6ñ«R•ªT¥*U©JUªR•ªT¥*U©JUªR•~çéÿeãÐÙ ˜ 