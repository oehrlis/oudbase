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
‹ óÝ¼Z ì½ézÛXv(š¿§ØM«bÉá ÉSµ\vBK´­nM‘d;uËÕjˆE”I€HÉj[ùîû÷ßùî£œG9Or×´' $%[®ªNÌtÊ"¸±ö´öš×Ú§qÒú§¯üY]]}üð¡¢=¢W×ð¿òQk÷×®?~pÿÑýGjumíáãûÿ¤~íágšOÂ†’§ÑÜvÐ¬ßŸó»ÌÃüûò9…ýO§½˜Þdš7óÁWècþþ¯?z¸ú€öÿÁÚƒû?€ýpýñ?©Õ¯0–ÒçøþßùcQà4ÌÁÕ¸½@;Îâó°çªý²®žOó8‰ò\mEçÑ0¢d¢þYMÇã4›¨åç[G+ðÎQEYç“,ÌóH­ÿ©®¾_{¸®^ÃÉä4›žÕÕÑE<ù{”Ã¤wëƒÞGQ“?Ê;ðc{:¤™üx4‰úa¢ö£A6ŒÕrå+*§gÍ”žýÛD ÙMGðv§Oªß†·Â‰íw}uíûæêýæÚ÷ðËatçqšÐ/4Æƒi6NóˆÛ>‡­SGÝ,OÔ$Ugü3ˆTœÀÀ“n¤xü*ÌUM¦‰ê¦½ç™N¢\÷w<€]Êü5
ãdx©¦yÔSý4SQrgiB[K?H§uüf«]ÃO4Ä>lô†À“É8ßhµÎ åôçÞâõÈ‘Ò ¦a÷;q7Jô^ì4î7Wÿåö6 í¦½¸G=ì¾æQ¤`D°¼š
¦»qI¢_†éÍv”f¸|ðç(œ`Kø_w&gQ~«l¨M >é(þ;wó¹¢t‚ö_oîïŸlí=]úè|ÛhÔ [&gxžšivV»¢Î;IO¥ý/C@ ¶ •§Ã‰z§Qþ™	Þt¶÷÷žÖÎ×šëÍõZ°µß>8èìm=­¾îÔÔ¢Ï@ÔðtñNÆðG8G@# òóý£ÎÓÚ‹öÎÑM GÙ)4@	83G›‡ÛÇ'{íÝÎÓ¥eÄãh…ZZ]	ŽwN¶¶;›Çû‡?>­µ&£q¾ØÞn—>z®ZþëÍ¥¥ZptÜ><>yÕiouŸÖè‰vvié£Óû•Z~e„ÄKeÕ®V‘—îÕ‚ÝööN{kë°stôNÜ¿¥YÇ®ÙÃÃýÃ§«Á«ý£c˜Ã Ð‚±þ¬Õ‹Î[Ét8TŸ>EÝAª–°ö¶Â+òJÚ.ò|ÙÆ3¨Ó¤‹¸÷¹xÃ nï`öe<êužEË+êc‘ânÅùx^rƒ[ìÚ *¡<=ÚJwó3UÛÞ{±¯6¸Óz!~jÎ3ÕˆÕxð·÷ ö6;ÏTcKý ü½·µÿÂ !¸H³Þ8!ÏÔÏU(ÕTêØòàåðeÆÛçUoWª¯gU¯wQ÷=Qè,ã.Q¬ œiÛÆÖsÄÖÕMžnÅYÔ%.°&0›l¸Ê•{OÔX½™ñviWðOÔ¶ðèª÷vÒ3"a°Õ;û/‘\q»¸¯~‚‡kWªq6Q«êç'Èð“@Oss…I;éýû˜µ[ú¸~E?GC`¾º]*V¿¿ªèy?®‚[å~•'j—‘ŠIÙ$‘ô2ÓM«½¼|¤ùmï¼Šøqí»{WUÈGiÃ÷‘6»„Cœ©Óþéñšv¤ÃR¨+ ª! ‚¬B•€äÌ‘ès]Ç3{Qƒ/ª$øx{·sø³{ t»²¢ªýËw?6¾5¾ë|÷jã»ÝïŽj+Ož8¯Î~5Yð21 xû3úÝÿKx†ój­æ6¸Ç¿{šýR”‡]‹ù5âyˆ¹W5õT‰lP<º©–!æµ¥>ç!£6c4ÀÃSSŸ& :6Bçš7½ó4ŒiGIÿ™âþÄ|»ày§Qc·„ñÒX{©×ÅMgf‡Ux¸pv•3œÎkêÌ´<Û^šDešt‹ÛöìYÕœ~g«_=Èë/ÞmÓeC]&€2*’lj ¦c }T˜¢ñä–e¡EŒ®BV’UR¼†dØ4_]1<©*pÖ’`í’©5§9PRhÞ)ªMZtS½øL…£tšfgSÔ‘ó¦:‚C5%V†d½›f(g€"5Ý.Ö¯Û…¬–‘•¯\þÃ…ð])„Ä@-ä“tBš##eò¸ýüJAWðå°½¹Ó1ÒÌÉóöQaá`¡öJ¯Q?y4!ÀÞÃð<Œ‡(-zóY[[y3{a’N»Öq^Þ²ß Ì0{êÝÒÇWû€­¦¤îþÂù¥Àå;¬¦÷abQÏ}ÿÁÂ÷;Y+„Ãé‘ôà¿¾p6ü:ín6M”[Ä(ÔMG£0ñÁ­¸^îˆäTh!?Xyš¼OÒ‹DõŒX>¹óþÕáL'´¬ð¼ß_~7ÎsÚÊ‚»{h®ƒ¾…Cƒã’µð@]Ñ’$bŠû
–lÉÂÆrIcê©TN¡9u>?¼æ–ÁY>t¶	)Ga*^0:ZjwkÑ²2ƒ´
¯·à[Úç•F5oüwŽÇ v»’<•S­×ÉìŸþ´RÐ©þ<Í'ê"L’På mÂá0õÌ¿.$˜¯EiD3$Ô6ÖÖŸ«ÛòÇtÒsP"T˜Z™W­8•<Ž½Æ4¹E ÒiOŸoµ7Ð:g(ÍÂ.<x>=s¡£É
Í³~ó^wºª·­ƒÕ/;FVBëˆéqÿÅ—›}Øz´Ä“8~™ 1ªg‘I?l(PTK³Ë@º¾àÇÐÇfEžQÂ„fU«²Pì)äëkF#ïÇ@]ÍØ¡c3|âÝ³‡«>}‚_þ¨½ÂÏî ½^×V¡7ìk©†ãšÊg¾[âX„fÍ|P$-êÐxïŠ>,æŽ@da´™ÂŸš²8æRßî°Wójó{+L{¸È’ä¿ÂÉüO”#Õ?ÿ3nÒ…ª9¶oòÓs`öÃ_•5·CG·ï’pL"1/ãü#+ƒÚãÏö88?ÉÂ±ªyz°ZCD‚ÕvÌÒ@x!aC˜½¿b+e¤ºSJrLoTMÖƒeW<egÑ$²úï³rk‘&†¸²ã0$˜ Žõ5y[Îã­_6:JËFmcE ž¸ŠÀ`E™«é?_)èÎoñŠÚ½tÑsÿ –æ¥Çˆ·°Ûg´øE·pM‰3Úf+ê°s°³½Ù>&·HqT«¡ü«žìºZºç²+Ò!ðç‡”¢DÙ
KP8Ò²±(Í»BÅuhƒXhƒz¦¬ObýÙ?¯ØˆKÿ
=H^R2b1²t¤¦ éGÓ¾JôVî¡*- ¶¡)iºRÍ|çËÅçœ“c‚>ƒùÏ!:v4³©Ž,ƒq;ÿx /àÆÂTí¨þàiÖp÷/ËRxs*‡ý\D°)ç8’"†þÈÑÀÅæ?7µJ+ü•ó‚wRô«îC ²ôñàí–,Û•eÃF\~çªÌŒ}Bx¿ŒÂv‘ç–7òpšh¡({A¬..z_Z7ìwoô³8Œ¾„'IÚ 8Oèïƒ,GÙ$Žr9<âµ³ÛÚƒéðcwŽªrâÐp’Ü†cõÌGk8c80ïœÉW6œ#ÏÁ5ÖÌ=tåe^ó^Ñ‚tö~AÝžýØFØƒÿ^r´zyiQAYjÄênÞúëR«Ñºëyû—¸çó°ûÞQÛ[ìkM‡“xŒ®cRñ@µöI`Mm}˜ 2³Ôú¸÷$o½KZªõäjNÀ{`ŸvðWi¹á ®ü”z«@Äæœ°¾©;¢>EÙ9èšˆµGÅ=\>¹FÖUwKÍÄ%õ¼q¬húWØkP¼qT[;}R¼Z”HÑÕÔ¦kUç¨Î!Ú!Yeæ·PéEµwg«}@ÿ9òºþÊ1« »ô1vT±öÛ¿œì£³h9¼x¯î>ï¼ÜÞûxxô´ö.i¼½öýY{²ýroè%°½§kOX_|úqkê¿Të¯í^/ƒ}j!ËXZÇGï~¸‹=Ý}÷¬¥>Â——îóãO	ž¯œÕ'ê
ýDI³¢g>f¨3^ï8ë‡§vðáZ¥ûzÛXÞÊ5Z¹¢éå3 bŽ”3×¥ó´vXtü~ÛÅßh³ƒ9‘Ð%@:„Ì'àä9&‚|–¨‹o@¼#%¤ªz!#%ƒìÒÁ>h8í­Ýí=—7Îd³ao'×à³ÕÌuæ^Îä±ÞÔæm}%»ý‚°^fÎ‚–v·å:ùä+<Kµ'‚ôWªå…§]ésòXýñ¿àœì¡‰pˆÇGŸ“‡ë•åóÇzåù(¿^‰òðO4œ/TíÎöo(Y¿>ÜyZÃ`ÊVÍDGÇW„¬¨;å£VUÔÈ¦cG—TÑd
0º°Ólš8’ŸeÖœ§‚ü¨/o
+'NL3ä„ö+þ;'ã)IH@äA¾¢P×²Hyôõ÷å¾ŒÅnG•‚ôàAyEI!ò[ŒUæK-)ß:†ûK>:þŸƒH‹øÿû«?2ñÿ÷?¢øÿû¾ÅÿÿŸ¯ÿÿû_÷oNÄ?FÜ¿D‡@™µWÖžòo!ÿÿBþÕ-Fð«o!üÂÿ•âïkµÏºwbîo/ä^ý.cî¥ ûŠÐ~Ä•/ˆ¹/w=S‘úÁAxtý{vÕ,V„ýõÃëËcÞÊ(ú‚ñÕå3Þ.MÏ¼½ÆC%&‘™¯o©žoïm9¡ùHš¶a>dÑe~¶Üc|¯×_™¯ðvQÝÉî³ §wKÚ›0~_ýÐùTÅÚÇ¯¨;4‚YMät{=æC 0/¨²ŸßK€Ö¶®˜xÜÒYüÝd ¨o ß2 Ô·€o ÿ¸ _‘0å8ÿ™	49ØÏã× D#G¼ë«ä lÒ	J,…Ç›Äs›= VMÔ?P!D*Ndý"‚5•D•¨ÚòÐq™bœ”îd!Ij$äR°TE,~|aàˆ;&	„‹€ÙäH ¼mî!=JTùqŒuu
Š½­Îm'Mµ—¢“E9•£.+Ö%"ö-áâ[êÃÂÔ‡Ó°û~:Î+rî/ÐtEòÄ-Eý/NNØÔùY„Bõá×øÁÃE ¶¼wuûEO¢bûâlŽgæ5Ž2´aáteÉn–Ž0–ìßo\/t™ÃÌ€S¤ÒaM¥¢¹ˆ‡C¦c9"jí…šO«%vïÔY»¼é…áQ£˜w\@¡'Ð³yC™Ñ
¶´|ÑU¡úÁ<^ñš#£ZZ^^’wô	ã+¶%BWŽ‘Æ7®Ü@äO8ëª‘ÃT˜ËÁZ£f/Öâ	.0—¬À}õ?5r_/-É¿bÜ¾ÂØÙÎÞÀ«>RAËpd‰4±¸+³#ü¹C ÝIô¾úŸ¾¯n1~_Ýb ÿ¬}ì«@Ó8™D™j}J¦£SøBa%C±,±‘e©!p4 Þƒ(ìAlªCÄHb“¸ÜŸ·Ÿº N6zpŽÖ@±$*µ¶ÿ[¡aÝ~Øÿh#ÞèPèã×ˆü?š¬?‚†ŽÙiYë¥ºí'4æ­wõÖ;Õ:[ùjY}lË¹¦ád0£Õmäà†Iµ1±lS.0À*{-e|µBÜ,(Ü%šØ-àËyÜ‹
rç0[Zj¸ze8““EÁâ3)le¤8Q!ãü©`<Bs‡ŽÞ¸mMbÃ$<­´^,ïžÖ9ÞzÌÐ*å–mC?îÍû(Äçœ‰ê†e]~ì¸ýüi¹ŸŠ†´';ÛäcÊr®îþõÎ]erÍ™ b²Rf¬¾Z[ÐYpð´&´vï*¦>ÎYQÖEô}Çv«}Ü¾jÝÃdVûÖ4‘4;{þtÌñ¬4Y‚U²*]sí½ßÐïñ—¶&Dh)&Úƒ1ñÍ{ïZï–á¿+ïpÍ{K­wk­»+N ¥cW2+^Îí2Õí:;[ÇšOóhVËÌoÊã·4´p„Èf™©»õ»
þoEóhIM¢bqRØ¡Jè6Øœ_àw‰@.ÄïûŸ‘N 6g®™ñNšŽUŠô~D¾‘&ø¾)´à¼md†P†?ù‚Ù’§“¨
9TÊ§`•ÊÎ#«¢ín¨ŸÈŸœ§Ó¬y!"}ª ›¢Úþ>»ëDÍØ«wE|ˆƒ——éYsTœnšLâdj°QN	‘?€ÒRº?^'ß©úì»µÇv{XGD¦M<<<GÖËstLe¥™xºl>A•¶ÿä\ªÏÐ„m^F¦MÖAüì|)ÏY«³ê_!ÍJFåŸ@õh½MÒU\ó1ð˜h"u\mëß&@MÿúWÉ||}0_*†âG©›áLÇˆ{Õ›+çb¢øzòÚûr…«‚ÓØ öÓž[€´Û~»çî™BJ\´mù–kWñt¡Uš¯GïŠjŒU©}‘(¡V[à-¼äX¸õX.®=úÃ9ÐÞñÊô´FhølOÂUðÀô­s†I8(PZ.t·@#>q))iÇð3t.;°Ý}œž¨žrÂã0¿Õœ¹º­<iFÂÊP1CFµŒ\½¡[’„1ä÷ÙašN\-°¾Ž,çîO?mœÃäýÆÏ?ß])	@Ìòe¿Û+æŠ÷fœt‡Ó^ô<ƒ}kï‰ºÄuÖÎî¶ÞÕêïj­ˆÖÝ3Û¢ßV|?çìµÏ)‚Ìa„–<Èp¶·ìÐ®®¶ˆ†E¼pé~ù6÷wwÛhëÑöÞU‹A5†=8W†‰N“ŒƒkeÉ\+ë´jº˜gá.4¶Ã â±á¡ºÇãÄÂ:Ù
/%@áî¿|7½»ÒDH×]PP¼%*ìaP#RµwI¹¥zVq.OéŠü!üT&µÌŸæà8˜Qe0:sÇoZÀo›œÄÐ9GÉ?…$TšAS…ˆêt$§ó
Ù«sÝ£"Î 6bER“Ê&”O OÃ÷ær¶z"]ãîD¡=!¹JPnäÅ]¼iäÙµú”˜æJø1Çéë~ª6ÓñˆTß1ªøÌêO•n÷SO˜#Éã§2Šdö¢\òiM†}&.aLIœ¢ÞÌ(”ê˜“Kv½ô"©ƒH®ÏyNÏÌ8Ê¡g1•i9SsaEŠµ6k²çßbæ’Îÿa5æ7ÉÿY¿¿úØäÿ¬ßŒù?ë¾åÿü*Ÿoù?2àRþ9ÿù?b‡ø–ÿó-ÿçs`}Ëÿùêù?hŽ„ñ¿ÞÙY<|ž‚Þ”ç|¶ÑÖù—Nçàéƒk({ìù…Y¼¢÷9‹÷Q4à”ŽQÞ}Zk4ôßóFÆö+ÛV½†gßR“n§›_)5i¢~@4üo”¤d²jT{ggV¾Ž™¶ù8GJá‘D»ëöÞæag·³wÜÞ±PñÇY`ß«Þv:9²píY»pÏšJ‡=i@?˜÷3¬úê‡çíÍ¿¼>¸VvRqX:;‰A|ËNú]ßOòyùHßr¾å ý¾²`¾å ñç[QÁo9Hßr¾å }ËAú–ƒô-é[Ò·¤o9Hßr¾å }ËAú}æ M6ÞoÄ£þFçkä MV»*stÞ¯(r	Tÿúkä/QÆÛS¥Œ£PHÂ!_åLâ0.ò¼55á¿hÕW`àoW…;khÑÖ¾eê|ËÔù–©óß7SÇÉÎ¸N¦ŽÄ{Ë[”[¢!.Ì$Áq„·0E•pˆ>Uç«Ãý½F5½"~Çˆ³aŽÎ±é0Uµ;I1ÿö:oOÐï´·ïXÃ_ƒ¿¿³eX^úh^5„
Ä§âÜ9ê òq§'Ð)¼¤¼·Ôwh| 1¢°»˜÷²BÅËþ&m•æŒÛDõæòÀv|µÆÄ ÛžfgÒ"ÝdJ¿}ÎV¡ÐºcrüR¶f¥3}^Ê–¬Ä‹¤­uý–Œ4+ÉºŽ)ÉÊ†&É¶Ðv¹˜r³T$ÖuR‘œö×OEr^rÝ¥T¤…c©NEª‚¾0IXGJ™¶•ÙGN7Ï>*Ëö,ã
at=¼¡$ê9Øê3×¿U¢ëŸµ#e0vÌ‹RsR`~{[bD³®r6enbŽŒ·*)GÀGTÇ[I¶Œ–®ð\c)®3ê¥þX\oŽ›ùRlUNHóóXJo,Ì|ñ³^Ä“€$A›iÒÏ*HÃÂméÞ´ÓMÔn †jü½{Þ¿Î·Ü|$î¡99û;SÈÍý½3Óé²2‡¨¸”nûÙÍ«—LßÅªñrÖ]LUkV|õöo	ç%slƒ01Õ ¾Ý_ùmVp~¢HÎaŸkµ0ÏÊÙ1É²¸…,«ëgXÍ’žWR»%R}yÕ¨~ä©ë%NÉú}vâÔõ“¦fyÑ+¡rSgåEö²=¤óÞ¡)K‚}wsZŒP@†Í%ë…4Vìd5*¨UŸ±¹‡rŸýÐ•*®Õ—V˜=m¯¼çÙH5²jrU€è½zÃ\¶½ÔB?Ê.£‘²<îò ‰˜þh÷ØlcÛMÙdt·ŸÈ¶ú+%²}û|ÖÇ»Šû+õ1?ÿïÑý÷9ÿïñÚÃGïãý_÷<¼ÿ-ÿï×ø|Ëÿ“óÿøDü®sÿØ¦Gµ0¢_Ûs
6¾oY€¿¯,@É˜²û&Ìb¹ºyÆB:âšPd“;çÄ«âÎ›Êu¤š·¶[JÿÛâMo¾r¯¾ûÚQ‡B«ß2èï§†ö…£W'Gû¯7;?­þ|U[©©'j|ÑUþ„Ó{š§Ãé$bû&È…Œìû\Š«fJúôYöÅ^ò`«ó¢ýz/ºÝâ
(ää,Â]\óÚˆDç4béÊoå9¥ãvšížlíƒJáõÛKñ°úAsÙlï¸­†i½O3Ú<2ÀâœVè“åVÑ¤;³*MºÏ³™­Ž;»;íãÎ‘´D£1~Ø7÷·^o»³gioÚ8PÙ_‹ÁOÒ¤?ºX”k®5ž”¾Ø};§1Ûi;d¬Ù~ù´Æäÿ¤ô ‰ZPˆƒ{jŒ§€œßÎ0g'®fÿ¬7áêÊEJ§ÅDœþÖ'Ê†óm£áe]]«yÅÔœ7ÖS–º˜Õ–&öÔ[°0µ °¾D5Ü	íl€P„ÂŽ±O:ÓMe`vN_‰i‘ÅF†1¤ù¼ßª«©cºj»‘]ÉÕÕ¶ÌÍ…Íé*bcÏÇÙ1¯éSì€} yw/œ„î
cœÃSòÀ.g;jWøQœw®^ÀšÍÒ3igGVøK[ ƒØ«‡1†>õ´ë…p‹´³ Ø#šO}ËËbàe’ëƒ÷	-ƒ÷ŸÍ_A¦ýÍÐg{€QÁUûa©š=¥ø­´ÇNÇ%réª@'Ýéú”Ñv¨Ÿ|i§Íu:þsûM[wiþ¾ag¿„ç!/-RŽ‚cY¿çû”Ÿ’?Y¢ð[ÑMÃ©†ƒ3Ñf‹/–â‚[ŒBžL.Kå^ÇÇÇ?¢#EfÍO)ÝzîRKbR–£QwJCh	‰4/’€…±ãËò'Ù*ç‘Ï”$–ÛBäÙŒ÷)0Z);³ÛŽŒöÆT•ˆónF&/‹&Ó,QkÂDÌÍAB-ND{3Ró£ÄTHL†gT]³z§HÇ&&e€’ZóñðR³6Î-ÇäsÔ úq–OÜJ¡çì"–”E=žè0MA-ŒÔŒœHM¤¥Ñí7­xŒÿ\9±UÇkU6<,á7v¢ã±DÄl}fz	kåI0X˜cþˆ1Xqù2¢‰Ã<jUÔë×”j´Ð}åÂÐ1”7–ŒÌ:V¦Š£Þp,@Ø¡ðúÃ"s¸ÁHò§\¦é†ozÉ•*‰WªBTÀ‡&ÞT9É&†Ë	\ˆ¯Ø Ž‡NB „›‹O™ë4'fÆÆK[|©ÂÌL3ÌØAòlžèÕ ]Ciåƒ„Q÷‘ù{žš!z˜mô,¸L7»:cNøjÚuvŒztÔs6hv˜§œ•§ý	”¾—SWö×P¼…º•%ÍûªØPùB{\¾&ôìŽ±$¥áõ‡ÙÝã²‹ÓkÉc––|n®¤îPb¹Í¸LäÞÃÌ¿0r\z¥øW«
»Àp·¹?äPÑh<¹ôBç
Q½e9ƒ{˜ °˜Š¨âEH{ÜN¬U^‹æñN+aPC˜\ú04©¢…®q«aíµ*š'¾$ªýtQ0{aÔ—F·;˜!L]?wŒŸfaíXæ`äwp§„)šª9ÎûJ„qÕïÂ+&<ÝëÊAm
O—™˜ƒ|+8û*2+
xwcœ›…o7ÇµÏÅ³ÛÆ1Â/-eÜz6‚+;†ùÄßIXg”ŠkþÝñÂn5”*jK+¿ÓÆAVc·‡ÀÃ!ð&`½kŽÎqhµÝS:¬°¢ƒ0µ˜Š©á€÷&¡Î¬ÄZÕô+3gz(€ÅïgCºã«Ïh[v!®]¹!_ž·ù»,gj§`H‰Dµ,º+Á´üžÔÐrÃ]à L@,¾MîIE¸=“á­íÃ]w%}ïUt™…Àé¾´Ò’=lG€G-Öä®>_ŽÛwzÿ×µüN?Óî9¦’èÃÔ†ycÜ:êt®3Ja6æ×ÚFo0<YÀ£áíÐ##¸–G­‘ƒÚ–Ljš9Á[=%u>q"‚:
žy=ÍÂî0:!Kn5nÁ¶^ŠÈìpØ$g¤ÈìøËpÞeì–cPj£¦XùÂ+îò’]å•Ò›¼WÊ{Ÿ'Ko+§Ck~žÑßSiÏ]^]óLe4½³Õ>PHŽ•3LS)ÊÜÔôÈo+MOŽŽvJÍÛèé­nNÆ‡Ò‡Ñx‹7G^Ó/vnp®•™^ë»Ú¡R:Œ”r‡‚á ­–\$²AÝ¡žšJã{u|| üÏ¬©`Ó£Ê¦v*:4òVÎ™Ê¿ˆùøìr:.³J—K
;MûÚò`óWo™YòJávsúžsZZ)Ý‚Ëë,ºi‚'»V\kodªQ~VúZõ©ù
ÆÌ<KüÜÑ&t8ÏH{M{NgÛ#ô=Fdú„•(TcÍ)'ñ`Å÷ù€Ö}@ˆ¹ŸìþŠË=·Öç‚|4äÍ<eJeò#tnû¹6ññLSµÐ÷Ã^µ–â9µéª ÕX€€=ÎâdÒWw¿k<ÌÕwµuüï#úóþ7Gu°<#17
¯Sï¼áÔ––IãääôRµ "Ç•ü‹Hbþ&D¾Z¡Â'>cvÔ[{.¿svó£*’²3Ñ€µ°oÎeK×X
wËÄL(ü ¦CbŒèÃh)å‹ÛãTj!9cE‡”þeÆÒå1 °’lš5StåÍ<ÊÎ£¬IqC¦¾Ú?¼åì
 {¡óÜÃÝéøîÂRùŽúð¤ûÅmI0X™?°$oäÃpÜ»å®é0.èúb˜ßþ¬ï­ØsÂh´B¯@ ¹‡š®”^â´=±Žb>NÙ‹çˆ¬Vl×S¸eD½©„{DjÆÓ¥5Ÿh6²9:©«qT“PÒVÜiÿp]p'È‘úgfýx±.& Óù7H™ŒyZšJÿvñã[M¥>‚viÏßÿ¦:FH6¢(ÙÇ“á%Ùùœ—ÊIF…”/çkiF7œÍ¯9“râ ¸ä£æõæR­DV+Î ¨êð×âjl¸&Ñ`ñø÷O.t|ëM,X%Z³ÄP*w²l@)OôÇÇÑdßHÔÝ©´¤gSeN“„8i«ÞúëRk|WÀH±½¼ÑíŸ5ÐÝ%t]¥ˆ²h÷„mÝs©Oéû{E9¸·Ù›ˆ÷^G_¹ËÃÎÿ€Ì$äVOéh´¯K ,»>ºL§Ÿ·æuÔM¢èJküÃ&C`DO^Îž ´
}ÒÞŠ"¹sq×ÇAz GëqÚKKh³vÿû?U·a<1Â>¶}tÿÑŒ¶´ÁõŸÐöû?yp?Ÿ©ª¸7µlœa,¼U4p•LB…¶®…«Òç´/ófXòœ7ŠÖ¼’)ïë¬â×fvÓ1V;J‰áñÏt41Æã·åh–1‹É½Àœ*CYÊl¦YD	½¼èñs…ê¾®• úCÄ=VµVáÅV÷Ý»Â#¶„nüÜp0oÃàÔÆ’¿,5wn‹cFÂ°×+Î„k!T²ïÝÒˆŸ=›5æ2µþŠÒ\rbJ®WtI”q<‚iÄ÷ƒßâXþ°%g“#ÖV¯‚?¸£FxsO>Í¢:ÖX¥Ç0¤7Lî °^×bx€I‰ +Ãƒ<øƒœ!î‹œ>0¨ÿÝóƒà°ÀÔ-V|¨š6í—¶dÓÈ3°æO¹|	…—O3àœÀ®?)ºØ½«jíÆÿ6þ¾ÚøSbêVÄ²cú¤ØÂ˜¨5ßÞ‡¿“ã5‘ÓüŸÿ0'>uï' ýó=ÿtU|]Ã#õóœËYrOAP}_ÄA²š}={ÿ VXü=ç85Ñ™?nÝÀÛ’aO…ÈÀÏ‚V´Ñ‚íì½ùüœV,¨,¯Ž÷w1§„
Ñç) ‹ÿ¼‘´Â+û’O‡ìKþóÂK&žÓù<uE¿¼9E·V4Çç…æžÚiî=¿…wl¼¿?,ó¼Ð^ÇH§¡Ÿš»YŒnsçyõ:y¨ø†~Þ¸¯Ý-¿çMå©oA(öäp8ïçyùß¹`_ñŸÏéªðÞÉ¼Ý)iéUïUL9²*|žŠë ¢)3òrS~^õpû*Øø¼ª9ˆ•Íá¹×Ü¥"ú2Ñö0óÏ£#vR¥–“ù{J‡ð‡XÁŒ#÷ÅÉ*-Z 8E=ÓÿnÉAØ–äTkØ$_\ôÌì^Î”(Ô²+‹¬8 Rÿ’Í—”tcãG`pÚ‰‚±¶&«0V% ,(/|žNÝ·é¦IÏ×LŠ2&í4‰#È¦FjêAb'}ib•1s@|¹		ñAXoxÑ¡dß?—ky«†€5+Lª0ZÚëÜ""+y)x¿šQ•J…ØËw2ò"D–ÇÈ¨ÖàKH.»ƒ¿m3ÊRÐ*Õ²ÛEˆ:ÞÝÈ¨\ vÑK :Q[’œTAtjïl·Í= Ôž"ka\›/7ï­<]¾[ƒÿûT[iÞ£ðZe%<¬´Gé†3a,ßAKŸ–Ê
€YYj½[oÝ­€òQþÚhßÇZ:ÄÛÿ×ây­«øYúH“*ú\ñS3à¯¼”Ù!2<WëWÓd´g¸ìjý3ü¢Â,T†Tô¶ªœ…¿ýïX«=á› Ÿháú<ùJ“Î€Z`´ÜLS<4'ñ¹­ðRÞá¯õ[^¤"Æµ«mëÇa£q¯Ö¾EJÜ—fZà<k©÷
ò ½:ëÅ-U‡Qf¾šQ½á†{½^º¥!m¦£Qš ñzºäOù©AIzAí£„§µšóÜ!?UÍëÎ’….s¬šûÏ?b‰’TóIwPW£(LrVÎ»À1b2…u	(†¯›ãrŸã,Åë*‘x±ä•ZÎ¢Þ´ë½ì8»NqgôN^Ìb]ÐŠ42¼p¹!Ê8uæ újÀEc†~Ÿéãïj‰—´ZgÖËÝlÎ	±Z¬dµäì9Û¯3'ÚV­Üÿ6¼µ¡Üí,…E^†}1Ë7ØåÓãA´\Œ–gX&@®VŸp";óÌ¦Ôå¬¹ŒUƒðç$MNjñ"Í.Â¬'{6óô8pãpù$ÆçÃ!Ã;ÂáÝœÙŸÄÙ
›ægN·å…+¬ƒÛØð¼$ôšL²PåC¬3Fù1á°ÜÏGÈÆšÏ8…1h¼¸Í«Ûnñú*÷ª1í©¼f‚¤®U÷…ýç4Ê± º—} q:—V$yëFhÎ6J¢OÎžuÐ¾”¥>9:>¼Nˆ 7,¸â+%Ã}t;¹roä*…P.x¡:TrÁK÷/iGó‚×
ñâD]ðÒÃ9á—^½õ0ËF bzÑ°'*.ã°¨y}Læ†QÎrùÝ òüZ—@gw<#“õ³§RS9·ö*ïûŠ®¨Qtó¼eîâ33oÍIQÑ™€Î0Í©„ÚÒ²þjK~”Nuð˜sÁ¨ãÄžåŸípŸå
/>÷1Éá~Nu–ù{ÚªÄ÷;^ªÙ®gE®ø|¨ªbUÞðÛ@Ã•ë±~¤µ!•{xÛ˜UrçZ •)X…	”œ”.½á„KoxáÒÖJ‰É(^ Ü¯z©Ú¼©jÌ!+Xix1ß},¸ï°¥BJì£4ø>Šìý
’YèÚV
šYp¤ìˆõ*PäÕP¦˜¿_µyUÄHÌýµKRÔådn7–†Lz÷-ËßÏÙúÍÆ-Rëßk¿¢¢F'þ°Ó>Ö·¬RöC*I‰Jº:¼tã”W&µ~Öx×z;ØjJ
ÍU,áv—Z<Ï{«µ~Ö‹X¶ô¢®¨pí5-—ÇiEÛÙ¯½ÄŒ‚·föÃ_.³x˜^ÿ×ÊÂåç_ý¯È1Ð‹LíK¡Û”Þê<àÏZ™ë¤«Ï^™ßvßÕòÄ™]¨_„Õ{¬QÜDG+Õº[XúË”#Þ˜%~'þœ6Ü"ƒò»®Íw3ÝîÖ|{ƒ-'cÿæ«Û•SÏØ­‘F®k‰ÀÏ"ª\hU~˜e<qËY«;æ–7vÛÑ`Ü±Û}Éh
°ªØÜ¦Ds'Þ•ÀƒÌ'Ó~ßVŸ£Šs³WSîX¨®¬‚QÈÞÞ™…ß,i¹Sa¦ºÔ“uæû>1á4=v«ô™5ðížUœ¿(ÿbDsòaR}>Þnñ]”7W*±ã€²SÖq¶sÖ~¶ß¾r|¯®
;½ã¾è73Çp=$žÙ\ï¦Áî¢=»ö0fXóSù’]ò¥XkøŠ,Ô«Ž°Æµ’*;JÍº˜¸H‚g^·FÀlàÈ­^+üÖ×ó|õO/í¶¾vóïâû’ÌýOî«Õµµ‡ü“zøµ†Ÿÿá÷?áþïlovöŽ:_­¼äëÁƒû¿¶úàáÚýÂþ¯?Z}øíþ¯_ã£*>/÷^«—½Îa{G¼~è¡EJqSòy#au÷ëjýOêÏÓ$Rë°ÙA ²Êø2‹Ïµ¼¹BÕ‹,ŠÔQÚŸ\`Uäx"eUÕÆw›ê©ÔÏûÍ4;k=Tç<Ê.1˜"ÎñfÂQ<AÓâãÆ—$zõ0_4>E—=´=x(jŽ±N4‡vÂ›C¾yJÊO‘ÑÔ´ç(@ÎŒM8G8¦Q¯Ìš.}²(ü„­ŽAº¢U£ØÏ¡:˜žBoú®+„‚˜Euñ0¢ÊÇüp» ×‹S¡úèê}œô(Ø¶÷ySw"oår_ÞóY~wŒÉ!X’_¦âÓ½(Ï°(<Þ¬‚‰'áExÉÙ”80Ìç@ùv !qp$‰<¥ž_¢±ïf›ÔƒÉÂÇÉ$Jz¼OgÓ0á{Tì1(õˆq¥Ió±XÈYŽIjsfÝèEW 8»†t!9 A£â4H0ô·”cÍA½)WêæÌÉ,yŠ%ˆ3³òOp,áx<ŒQÀúÖ0/¬þË»Ë‡¡R‰Ù„‰¸ô§—4Ân—Ã1þ˜N1Êˆ áo…VKæŸÃÒ”0á-zÿñ‚Ýq¾Çáà
˜ñÔñ'œ_†—³Qà1–Äå5ÇË>'Á8‹1ÅVíøêÙúX£¼¥§°#Z@Á4¸®
9'‘`i|jY¶/›Eô#”[¤ºˆóÁJÝt‘N÷‰ÔÛM{ÝGRš>Zz1¸1"xâ¼Šm46ÝÃë¸Û0¶.$h_	hœv½9ðYÀ½ÇØ·Gaµ„3X»’ÏgŠ¯N0ðŠöÈ^N»‘D¼†ã,:§PlÄ1âƒ®q‰{„“`˜ü"Ž3ÌßËOt:ÉæÎwòêVM¢°Ó)n<6ÄM	ºQ6	)D‹äñi<Œ'1ß ‡*wÉ]¥:v÷é{qQr£†…ÏpÒ."à¡9ÒÊ¼Àé>„£ñàÎA>íì‰‡¥pdÔÖ ¡Ó­ú‘Lv„ÉS¨×¢þ*—FÊÄ 0™ä<#¼ENÆ•—«'' P+÷Ó¡«ëÖƒz¼Z+NÐÅ* ºf¢ ßÊUNC¼™à¯X£	­“\‰¨A¢Ä„ö`§
½8àor‘â5”ã|#X^[Qx{f6!^Ã¼ÇÛ\ÄìåõXs Œ_H˜äðgñ¹Æ»atÄ¸nN<^ØnÝÝA ×"ê(ˆbvKëYÝe3	“¼»z:Diš0Å.ÐÉè¦ý#qôNd³g žò’KBµG]šÜñ) “ê40æ°Ç¶;tTÆY$ë=’›#-: )²÷T±8„:ï"+&úbÀ(çË“åŽ”p"kÓ#ÏY¥Ó|xIœG‚èŽä †L´nGt=üÒ­ ÂH-x^*¤¾ñ¡TåÁó‘M“ <ÂáÆâá²pˆ{ž¨É(L¦}àdPº<%*ƒ<y&ŠOxã ÂHI8œhHbT aŒ Ðû˜$;áð‰
ÊÌ´Lå—€Êt©L áÜ$–4œâ‘H»ÝiFCêä0^Lº$E#ž …{S`Ç¸æð“¸KÁÊc¤yÃ¿`¼â»O‘µO\Õñc>i½ˆ˜ÝÙÍÀÑù$²ÀˆRDæÓH±º±4	¾¦p¼ôP›”ÄA33Hfx5N>=EsVŒ¦UYB.}¤Ñàï=J¡BòÑ·xT Lî:%’˜’ÐË²€êOqwrvìu¬Ë¼Js+&7ÂÎBð8ÁñÕU„º&Û¸˜“ùÿp@f¤©Iæ1(8ÆŸ‘îa	ØˆrŠ´U“äoÝ@8œ¦îD“2áì	úVöãtogcÎÐ‘¼YÎâ>!Mš…ï¥ÄžQè £yžÆ¬C{ˆ¤7ÖbQVˆ¥z3qº%) .‚m ­]ÌLÒÒ€ÌªyÙI%Ü/KŽ€pO55
tp
…¨Ð½¼´F
Ð]c2ŽÅh
‚äÂwHâÂjEzÛ§+Æ(w8t\£„~˜kq7fëBÇÃÝ#ÕÞÛÂêB[ÛÇÛû{GØxµ‰)|qÂ=Òûµc‡ÇÔX<¥ýÕ§è¾9G3¥pd´ÊÜ¨oø]c¿ÇÊûB×Y¤†Ž|Ý* Í¦.¤P0Å¸HSôK %Ìß›qG îÑB»ÃFßôI¦t’õEGì”]Šó@^©NIÖ{=Øòœ‹â×€åÖ UM^ˆòmIÍ
55Ù%bƒKã`¼ +‡‰”—7iY2 á±IFƒhÎëU/Ó±Ã/”Ø û€ï˜Z¤úa>àtd˜HÒ­ta…ƒº¬0Õ)`vB,êqI "`—¥¡ôE‡c\œsÞ¬„Üab5S€òA¬õ*’é¯švcÔ¨c·-F[Õº)À‚6ø¬&KÅ2`8]‰éS6ÛOÐ‘£äg³ÈxºÃ3
Á(®sÐ„´æÄÂI]ß§¸«wA4ËÈè#Ô…qä¢&pø:dÇêNqÒÇÝ œ/A8¢O]ja÷éÈÛô]llóÀ3h"©Œ‡¿¢ ŸsÎíÙÌ8ÿp
ÌÐÐ‘À£#Ë4Y §¯w‰
(x‚æz;Þƒ1vPñè¦(º§0#6ùé9«pd.¢áÐì¬ÑyTDw<§xæEJ0S Ú%ìÀ#Ð"¿¨5´(Q‰ÊZ
¬Â.É	,WÈ)jœuI|ÊRAh0Ô	¦®+K©	È¯yŸï\E˜6™D8~¼%Œp6±ýœGÜ= 	-Ò5#€h´ÇÌ_p«vH^ßKQäÈkèD$0æ±º+›rI¬9* Â›ýˆ]£®>°r£¡~azfs…éÛ¢[Bý=#˜À&±:&«4_¨Jº,+¸áNB^ˆED&‰Äm:Ð6'bÉ«J0®%Ìš­ðHIev„Ñ›¼1Æxh	øv?à¸z½c¼ÇsçMs†Bâ4°Óc"Ë–×„œØi•]^qØ´ƒ$’°‹úh‘‹„1ƒ_3€Aˆ±ÖTâ8ÛDÕSóüš£ÖDUvÉ‹hÂ„gÌ½vé<Ù·øXº‡•5Œ	2¥ýÓ_"¢àÞž-”=ä¾P4ôïŠªaÖSÛzÑìëÎBòyd‚Óo žÆ(‡±°‹ôÍO J†”w<o‚’ ²¥½K´^ÔõRRp{ÓQî\DÃ‹DÇ¾;†ÆÚ6Âe‚ô7ÏÐ’ðð´Þ¢/YG)^Khõvœ6QV!/„Ý£#Ro ¡N³‰Z¹£Pe+FÈ5ìCxk`x+µBT5&ê*BËá
[_éíž^„6è‚ìÐ¹îûðŒ‰ünø,Â&«41fq£,!U²"t@Í§9ñÓE%ÑÃ²VÑí€EI„¥,õ‹GPÍD,á«2âÐ†ñà@¢0m…'å%†¢˜¡0/±&D\´ØµÂ(j‚6xäRèôÃD§†p8°)Êj¤˜…§—‚å÷ ¥FC$ñISühyi@<ŽgTpÆ¼®Bt	‰	sã ë(Ã^¯ Gæ	2áö±ôû¼Îr	v£L«¢VZ£=·ƒSd-Ÿ6 ûÂÔ6ÂÐM¯¸)œÄ>LB*Y¤á0(Æ…RWªk‹… OŸÇiçJdz…†ÐÜÎÈ&›jS“*#<­'ÐÊ1)Žù+Ò¡¨|Vn€­•^ ÖZGvhB‘õ™Ó`ïæAñ¸Ò¢•ÌIš².?À	°ˆHî	mTÖ¸›‰6ç°ª€¸˜d²/Oe`_ö%¶Y°´Víc`X¿#H=«` šv‘£÷ø¸Ênòb±—e—Ú ÅÃÅž$¼„R–½t—I8â»‚¼ùéöôÔ,©‚¦µ}XhA]+˜˜íêf§èMC9¢‹YÃ	ŽÑ4ÑJ,©»Œ
}´-œ‚H†’±9ÆƒãE¥~ŠY^}@ªÖ•Mü.±_›r³œjYd‹¯¹·'‹6VîÛë.àîæÅ?ªEºÇö Àh·3[obÑ LF!a5²z¡›ÏÈ‹×« )õÏZˆCÛr›’!ú@øÉŒR Ìâ<e¥EËrŒWhêŽí‚®Ò&Ú$©ûwêÄ† 5 ÑƒÌäÓdb„áÛ°5m)k}¢œ‚Òò;ï
4NˆY®I
«|?½ô—ƒ¸ dÃ0¤º:!)mNt‰XÇâÉt"²¸^œ0ì$½ åø,â™ÚMÔå<fŸJš„@x>ÎÃ!óçÜ.éé¥¯Ò“ÿÄä™ÆqaD`¥Ö–ãAÕ}‰,\}Ö53åx¿%.›ì…öy»W€“Ym€4ä“Ô£¡½Ðyj|g‚ctïÐa4eÂs>t@´I…óeYÐ(†ÓœrÆE]Vˆ]‰Hó€2jWŸíê‰%Ëb8r0Uû'£] úäE%BqñcVôÈì‚t+‹Y>Á+ˆRH¤Ëìá1§¹±±¸ƒ,lZ Se×™ô½•€#AtÂa¿.ç›±Ö."¥N™æÆ¦QÇà=â#£|¶‘±ýÙfQÏN0G»$Ð'F5]`¿ñ˜Y¼I¸ºiÖMŒÆÏÞ³ît¤kVy‘"ˆ#(±ã/ŽÅQ"00s´r*uDâ"ì	ñ^<È´Á;Y[%#oŽ²Ã«xƒLˆ–]àý&Òí÷xÍ~VÊùÀ¾Àåi·jlÒÑŒPwä8î¥Þæ!+9E>²nÏ°}”˜´‰6£;HÒaz†ÌtËÜ˜v£{ÕŸ›	o`Âgr:¤=*C „­­iôvû`ß!4îÌ¨µ:¼¾ª¶`F§ðúÚŸþôÏTáE•Š±E4ªŠIŸ,‰Þ2ˆ¯GÏ!·|Àˆ*ø´’}Á!.NV|–°i¤Q òŸÆÀCŠÝxk¦tÊ7™„á½Š: /<T[³nL#$¹‚=Oy(³BqŒw‡èAÃ™PÍDX12­8Tã›ê]5‹ôB–Éáq” u%%H:
ß®ˆK²I;ûT3Æ28µwe1eff5K›T¯&íÞƒ¦snßèø¬M6¨¹Hv·Â¥'&üùnî‰4Ì\m¦Ã´XÃâÁa‰§£j2äcPøÙ)KþakÆBwR|€˜¡½^âÌæ»ž”	;†Vî]ÁäÃEcA_hâ{Â´ hñäÜølz¢¿‡]ªöÃ¢¸ ÇÖ©Á¨Ô›3 Y¿ð4×nÄ´ãÒØÜžÐ0Îèð€úæ„OTÛÀ Uª­ÙEk¸ÙHŽîÁn(ÖHQÍ&ù™‘]VwSPôA@8ŸOÇýÌQ
mð€	¡!<t‘mWËv"¿qí¬s-ý%AU¤¢aÌèÜ±HŠÞKb{ÑF1k5‰ˆ#"è­}P…±âæŠÄMCš»Œlƒ=tá
	¯lõCfß…»tŒŒ•Hi¢|ôm±Øu$$¤ ¶s±ÂXâ<ý¬¾ÈÛNï› ¸*u‚O†Ë©ù<p[Y+óX‹Ê¢’íHfÃFO÷TˆôBã"„ÚŒƒS“‰vWlŒ–a‰E ñËŒ&ìXâÏ¾¯'Å>C´%B;”Y‡s‘æy”ëH‚ÐúÈ
 (Âd¢ƒ˜ÔÝóX`õ†Z0nôx)<ÒÕ5õ Q»ìC3‰¢$m´.[vf½!Æ ¬ÍAL—l‚'“"TyŠ”£è}_s×Rk«Nàdx)>{k¡aäL@µábl;aJpEjä^1Nô\{i3—R½]?“:Æ+Êg»Z`¥ˆ^œRÝe¦ãå	®Ø—<æUìI&d,Ó–À7¥HõÒ™½0Ï&4cƒ Å‡dqßa;<¬àËPŒ?¼òzåÄ×‹ðz;´sŠÞã›¡HõE©=a7	N^Ü‘'è}÷!ÀÀNÉª¯=¤Ú¬ÃâÆ=+ÈOŒu¾Ž
#*»èš>O‡S.’¥I3@BüÍsGjQÀq1'A-<;C„F¿m¬Gj—ˆ&?É/µeù2ò@›PY4#&ËQY0 OpJKðïJxrpIÀ%	uÅ&í×¥—t=%¤²UmyéázFÖ¦Ù9ŒÐ9’H‡\éÁú>­¬ î<ryê+ÂN_ÀæÌà¥¾¡¤Â`l8 £ÀrÀ(3.þÃ™ŒÐqèà`î40Šh^¥E¬ÐYQ¤a|J"ËXø8,uÓôW0¦“` jp’ÕÈ¡7¸ÌI–0/²líÓN‹
]©“¼7‡I¬íJL%ªM}ñ–VBÕ›fl?ÓÐ s0ÊeäèÂY²ÑÚp@XÈ³¬ý7sÈD-Cý=a)°®ˆê³´|D</u…›n&Ì9û“&ÇÌ­2±æ•q„L6,±QÃLÄ	tï C”LÍÅ…u‹¤á®”x2) —7ÁÓóì¶ÌáÝÍ1 #9j¦ñ±^<ZðëãC]{HIr.>J9@¬Fpôò4‘€v€ë>Q—r}"ÏXë—‹	«0$Ù†µŠz0ûQäu„{ 	;’TT+Á	>;ÔÕ×.Ý­“ˆgÃÊø(’çbµª +Ã…CeåRÅq®Jl(N»Ý0'ÉŒÕQt©£a‰:*BÑve7„½zøÌCÍá1z$Ï„[œjñÑ©•‹füSÑÆè8óÉò³g†ìô„¥Ct*-cöy?VX´ä´Vjg×çn¸hTì¹ kÒ3ºL¹sÂ ®û3ÍØ:ÈØÀŒÊÈI¢x)×Á»‚ì,SÓÔeç‘ˆ†¡Aú¤4/án}&*ñÁãÈ?>Þ1®!×`"´_fËÓ¢w¸ìÖšsÉUˆx±ËÝ-@.Çòíð_VÈQE’’)PßZ‡1nøÃÄÎ,ó r¨5
t1»g®nKÌºjIF2ÉAšs^ÇÌ×ër6p´Ú¸ÉBÐFÆdµPÇQKlÃ°ë·Î“ÙÛœ{Úd.§&šyj¦dGQÖ˜¤ü—Ã¿LÈŸ^a‚ƒ#¶°#0¢ ^»
O¸ïD‚¡ž-^>˜Úö‰aÈ6‰·ZÇHØS#æÑµ2ÑU‚5â.€FŽñÑ ê	è¤pÍ±x`pÂÆ^R}ÄðpxÎw ‚æàžGvÏ÷¦”H¡†„ÆxÔÃ‡Öh(‡¦ØÁ|:b%ƒšhEÇD:Ì¥YÃ¶"šYgË˜ÁH—¯êÆÀKÃpÜ:¦Rø}€we‰ó*·P{ŽË›˜ó°'©@ÅaÕC¶E'†ÞÃ(HD%Á\±)çŽ&é!–°?o²õ —NO'ý)—ÝÎ­×¶&žó:÷Ãó”ÂIòÏt¶A¥³,{¢X-'Ä
ÕžºªyåÅU“Ë1ÉŠ)GÑá5…:Œk±Ã<wR>ê³„öOMnC¡sÅ“ Rz…¸)40F’·(ú€F|âl„ÎcöÀÀ)Í„£ìh`adÄÈÊe/Œ\o–ƒN:H`ådê½)JÓ¼T\¨\:àáNM² >þ$\‘<$M Ž‘Q“Íf‘0êÒs¡HømŽÛay›(ý­ÃƒÜ#æDŽ`Zi/¯#nt£:ê’&ëê}tÉËË„/¶°5Áí9©NdDàx¡¨"m«lÝÐñxÞ ‘aé}Î	ÍgKt‘7<´
ùC£"›gã$N¦H¤ö¹¾Ö ŒGœˆV ©$&¤¦º(©"LØTÄóâÐrmžF¤æûþ ÄœSs…$ºÝ÷œhI‰Tº¦XMôEãÃîØ­çFåô%›–Õ@wuml#ísæèfÆ‰Éì0Ô]9'Q"Fú®uÔ&ýàí&†µHdµÃãŒh'ñUãh2'—F.Xƒ¦P•åJó¦?ÂÜÞ¾ˆ§p•,ŒçíÛ·õ¢’)ñ4rõÞ€u}5ëŒa
þTH®EÛXzÈ¦ƒåxal¸×IÊ`GÄÊ˜”ÆN!ö.Ý³UÀIIºfÉÛ[q
Ü3áf®15 ¼€Ì;÷wWLØ’;~Gš5õr„^@èSæ‚Ó*=ÊŽŽ®½G„Ð|µ-ÇFˆï‡Î¬=6f2g*²K¯ê‚JAiy6Ç‹€"£0
Ph@Äý^Df‘‹A””œPH¨¢aßRhwfiYÄÁPÄ­ˆÜ[×1SÝŒå<N‡”ˆG“›JM3ÊáL»ÝØfl£êÂn–æ¹HB4æœ¦
3÷YKÃdsýž•‡‡3“èecaYÎ.ó+GÄ?¢
1Ã³†ƒbàœè®Ô»ÖHë\AS^
¸áÄ4A·9ÞÑ@)Á¢iÑj=nb]ií—9Ž´Aµæ<µLË"7ôq\â¥KæMv†8+ñ8œQÁI€o˜Dœô“EšíY—[3¨÷ŠJ|M:l‚}bÚÝAb$PŽá$7›nb3'Ó¸Áê®!Ë‹Å0¹àìpb[_)ç	£ÚˆÓ…•cØò­£ÔÝZã·•tÏl¢O ‰òÖŸh‚Žê›ÝU« +•œ¡HÂéA)<ƒç˜éiWÏ`f@«ªBcp¡ÔàT”€nua}u7ÚŸN$E	É|Ð©ÏË[by–Èâi«™ÛQz!Ã€÷P‰“š¬\è	"½›+ÖÙ@&–`Æð‘NQ¬‹ïXì"¤1ù>)?îŽÜ‡ºÔÙ{+ã>lo·5Ám¤Lú¦òè|ì¢ß‹Êè 8ŒcÁ+»Ë4»HY"8[fdÇ„eDÕø´hØ+s	…¦D?YçÇ–$‘6©Ã/Ð¿…>/J“‰µalR:œYjŠA¹Z{HÄtíQqOPÆÔNˆC“nJjKvnØ—MáqÌÏìr3a/ìåå2¨w­ØøÃLÛKÞV"Wí“å¥g÷J!+ÛñÄŽ¾»‚ÇßÄ¼¦ÝËãÁ°“gqb”[‹³2|›q;£F….Ž`æb‹Vˆ­ÎY¡JÛËë¡1Ãð@BS~ÉN¥·›#›-§R‰Y%n¼¶aà`ðö2úƒÝûTëÂÝ	££ëÛŽ¢#òb¢³‘­U—2ƒÓã8FQ?È0\Ã<ŠºmÎÊ¥H‚´>¹í·ïb:¼G‰Vggâ0Ñ[&–Y½ø—~ŒRçÜ›®ZÖY¶…m”È›}‰ÖÚ"ëÕ	Û¦á8R{AíëµN.ÝvÂ99d¨®I6)¥v1ã—Ê0ÙLå
AlÅhâÙhž ùéZMLó	%ñç.'íÚGd"o­]3W? °G±K¢ôhîs¨=k=¡ˆª°$‡A«Y1o!+‹ZàUÅD,Á>ËQÖÊ&¥jtf|¨€$Yp  j6F™S[¼˜hWôsøc±HéÏÜqÊ»ù´Ní<ß3oTõ6ŠaÏ§pðÎ%`gÖø]—ÅÜÒ çè4ß€ËB¡t`‚ðL ››ÌT§XÚ1*”×¯!ÁB^'ÕQÐ	=‹]Â¨ äìðe#ã·KYÎùI‹'ª®*	YÇ°M¹už´Ì54áL¿æŽð$` ¢¨ë×éŠ˜÷û&)(qÂö7îƒòÑLÆˆ­UØ9Iè¦1 3ÌA˜6˜T¤¢Z(ºNð‚Q'o„•|Ó[`*Oá‰Ä*.¬ªQ¼œŸe5‘	D^-àœx7zH	…ƒ›ŒÅT¨ˆ-,hØ
á·ñÀ#[klúxå…‘ðN÷QÉCR¿+EÄ‰HÂY`jF²ßÕ1U@E6"²/°¼!”Êb&ƒ(+ÃJ9ÒËªJzAŸþØEô{l.0bmÈeê6¶J€¼š7o<@}ñYr[»T3h¹2Ù•±†!'?ZU=’júÙ	ÊÇ0(ººmJ«î%!]kg9•¦¤ß ™ÄQîÌ%X<—:ïxÌrB?Î0²%E¶žŸanBk ôLŒÑù´,Ÿ®X=.(×&t§â`´PÍúÞw×7ˆÎØ(Î<(6îYú€¿–Î˜oÈ1f={*qÅÌ!Cã¯Tä@iŠô2³:|Ãt@ÅÙ”OsSóÓ˜`‘EÎôÝ“Ð‹‰»ÕÔ´7õŸ ?‘^šš
!xC‡W UG%†ËzÑË(Íàšý©IÖ¿±ÜÀµÇ¡¼âŒ¶Bº„Žt#\»ÌG
”ìq¸Š(LÊòó"’löc;éÝ9”ÛTK)‡’5ŸDfñB„ÚÅ…×I¦ÁxàKÆƒÅ›ˆÈìÐfƒÐ¬’“ÀâyK½ÒCn 2Rj>‘~øqá˜óBf$™Ø¬9rÁçìëŠ–œ­W±	~%94Æ™;œzÈ‹\J0­K@ ÉÂ°ì”Î=—’p_””ÛšóI¦·ÒÀh,_ˆ¦_è%*Ne(ÏŒ\+ß«âqWM§rGÀ-ë—F™¨K"nÝHlq–]áB/Ôg>eWÉ_ÞÂúgAª“I,²iOœ—ó‡®/„(‹‘!ÝcíDÕÐŠ‡Ê“õÿÔXâw=BÆçÄýpª&¼rKr±æ•õC¾¥:9êTFÝ†"ÔXð(ÃEÙcŽ[ï‹èÛ¬ãHbŒcÖQ[‰*ÏNÂÜÙI4á"—;W$ÂÎ»äƒ#M08×4À¸<¢–žë|öµ°³ýò.UdìQ%›aÈÉ	Zé+XW,qVÜ2Å3ÄâópŠã’,Åb^ÅLG;ƒ®3Æ„âLPü‚ú'…ÂÄ’ògX}ÔïcÈUIl})O…
•kÏ›¤ßg!%Y>å½Ï¤½Ò¢nÿöÄbuÝ,½‡â)K:ÎÞ²c)ŽcVm¥KwÆXmO8†™1¾^°09–œÉûO©ôœ>˜R:ES	ºÏÎ´8‚º4¶»g½ uæJ@V8j¦n#©{8”úÇ#Šn«—[û±O’U²¶ÖTº¬¥.9—°Õ1Íj:ð¦ 2â™2]Ê	¨PãLÚ)LçU‹9°8)O çmšÛÚ„6B‡(È0á4º£6å÷L‰×ÒÃq—]¼T|Å½ó8 ÆõœjŽ?Õ\·AKC®ovEÈÝAFÊ¢¾~Z×œ‹ç‘[ÐÙq¸A˜KPÜ5)áA9dº_D2rŽ´¸ÅŠ‹RÐ*#¡öLóTg‰OT ¬ (é³_•Ò[Ñ7ŸèÀ5¼Ò„l1—ºld:¬Ù‚o6°B›W¥Î(òC§éŒñ¢±É.§&&àÕ3«¡À=;œÞiGía!Ù5Lù¬z˜{XUËP×ÌñTn‡ôûH8Q¸¸¤Åeá^ÊAçhw:å|ÄmÙ®J1G$áÞeâ³ƒY:û#½™ˆP±XÍ®ÈúTó'ÉD"¹Ôæ‘ šFbb÷{<aû›ä—ap@*êKU©Täžˆ´[rœ.›²s‰†\’…¥J±~‡û;’9é²†©Øý¹…[{r…ËÚÖhŸk¦»¿ƒÜÀÒ…))5×9V}ÆlKóÒ¨á&³Üª(§‚øŠeT`Ô”8d<)•³Ôf§ºƒ.á‡“ 0µÒ©L0ÆMê¼èÞÂ”$¥cÛÃ@Ç48R“¦(lIá$±51ãPEã¨úªÄfÌæ€6G¬Ž,Û@Utž±âa­PÖQ( E–è4J€ Ûj!L	wÇ
c*—-ß7=Ô]Š\ƒ"•ÃL}l]z:ºj“Ñˆl* V<üKYtáBc™OŠ)Î£¸º+2m( –’*(NÈrP2o³Ì“±ü¥m.<0N¬Ê­ü7™û…Õõˆ1Ø‡pK¡iqŠ@™œ;±» $Ëè0Œ£óÈaÈ©«£0Ÿ†Åb3L3‰¼2©È\‡~Pð1Ùh¦mN5 WA&Ý#H§Z×‚¢	×Kª3¥¯“ÿ°Š‘XàFG¹(¯UtŒ€fJéh_36Í0ãÐÀ¹êj®¦TÒ¦“
,¡‹7xøq^0a3*‹É‹sÙì¿üÈNžjSÚ@Övqa «ÖÉbb)ivY“ë9Kxì§ãb0;'zˆ#Ãë¦âK^T_X¶ÎmQ/[o%«èÂ“ŒôbCüpÔÙZHÓWºŠÌ—J,9$¼Z5“EOãt*Åˆ¯é%H	"µéŽd'Ópð mÈ	±Áqx9¢8§Ô:¤¯*…”¦ÑöU)xÉùBV
5úÜþŠ°Y6«ë’æ†T[Ã+Sm§+mx­SZ’‹>E‚OÕIËTÁÏÄóHš	¢•àeŽŸ‹©´oÏ˜—¸Ô?>^aæN¥8rˆgÒ«êÚQs‹:M;×4‘¼³X)8¶ˆl=®é jÉZ`Ký5¹ö\·V÷õïÕn˜Ánái:¾hëÒ²ŽÙÏdjP1¹lj||¢N;¡:¤ c $F˜jlZv ÕÁ˜i¼ºâ˜´ÍˆÈºìFN³»ëéÔ•ÂVkëM,nud®1‚ýÞGˆù]º™«—Ž´üV¨÷Ç&ŠžÔ)SËZ?¤rvSªÃîG~´ƒ]QÅ†½¸kÂòuU.·K]ßÙ-öklC³ßmZñ“¯mÐ„Ægñy*åtjY¦ÃI¨ï‰áH½Re.Ï$ K¤èL1´TÐÔíkÂ^Jvy×ü#Ä;Ì¨øIÑT¤i".-ð¬O\g×ñÝU(ë‚F%T´G"IÁ4sfá- 0#‡å…PLÉR‘ëêØh–®ùHæ¢o•Œ
NŽ†~†‡˜£3uŒšŸ<æV3Z»ßÄˆn+eâ½mÔ Óy×S|V  (‹%R’÷B‘°DFÉ?¡¹‘wó„Ä§V^«1wøJÒÉXFl][ëÕ-¾P¸ÀArcªCÉïé{((PÇ¤Ð•ˆl ãju¬uYÜ¿Æìêq¼Ý§x n”qØžSÌßh]FÅâ g´².?ÎÙUŒ/šê0‚†q¿‰Ü»—
æ\¦Ywrd« Ëš\°…F7`LO{Ö…tÎÐƒ‡©À!¬±ç‡Úº\VHÇYl²y%jÑX½H¹ÁQr!¾ÐÃŒ’!Ý¡Ã×™PæR#–‰q¹?“FOX®ŒJÂbÓ¦Žû¢[$S,,h"¿\.1 Z4!Äü‚ŸÑUX« °V51ëb„µzš{©¾=¥4Ž¤&Ûcã™qåŽ(Ü: J00#äë Š#Ð˜`¥ÞoÊqFfçuBi×_Q-êÍF!>Ö¤ÚK¡ýÉŒ/¨Ÿƒ×šµ»#,m `Ì‡K¾a~A5ƒh_YœGþ}fsPAHà¾ŽçGÐws1¦øa_¾SÕ.“òáØè5»ã%!èú­ó»ld‡6T‹[f¸ªgb3q£%ÓÌFçnÜ¿?”¤ÞŽ P—0kY ÓŠ’˜Šu‚¦%¸ŒØ ½xHÉÄîaÓ„†3*½•àp&q¯:‡µ}¤ööÕÛöáa{ïøGõbÿP‡û/Û»uu¼Oß;ÿqÜÙ;VÃÝíããÎ–zþcÐ>8ØÙÞl?ßé¨ö[¼9é?6;Çêí«ÎžÚGðo·:êè¸/lï©·‡ÛÇÛ{/	àæþÁ‡Û/_¯öw¶:‡tCUz§ÕAûðx»s„ãx³½ÕqÇ¤jí#vM½Ý>~µÿúØ>Ø@~TÙÞÛª«Î6êüÇÁaçè °·waÄøq{osçõŒ¥®ž„½ýcµ³3ƒfÇûõ {“¶:àïv7_Á×öóímX/¼VëÅöñtAk×æ‘o¾Þi¯ö:MÅK@`Á·þ¢`²°ÿþºm ÁêŒÝöÞfûræÀ6átÕû¯‘EÀ¼w¶¼EÁ…ê¨­Î‹Îæñö›N[B7G¯w;²ÞGÇ 4hïì¨½Î&Œ·}ø£:ê¾ÙÞ¤u8ì´·q•6÷Êþ£Ñ£&—‡ÇŽŽZfŠ±‡ÔyƒøñzoWâ°óï¯a®ˆ%ÊÇ„ß~yØ¡…vp"x»ÃÝ3ˆ¡1êô
ü`ãG@±}µ»¿µý·EgsïMçÇ£À]Xg‹²íçû¸0Ïa Û4®îÛV{·ý²sä`öÈ%ÛuutÐÙÜÆ?àwÀG@€^ª½#˜+n-< ª{Œ9yƒ×p÷4â@ßøÌì²í»Œ”jgÿ10Øj·þ}ÞÁÖ‡=X(:cíÍÍ×‡pÞ°¾£9z'p{wçKG|ûp+Ð‡ŒðöE{{çõañ°ç}XBIèì·8Z©¸ùjûtµùJ¶MyGùGõ
¶âyšµ·ÞlÓq”~`Û²&0;‚ ëÈØ÷¸Éw‹à•JI*.óêyDÏdÄ`Ã¡‡È6üÞùàH[{£>Ã‹pò
W–øf¡ÂJ—âá EÂè‚ S,áÂú?¨)¼Ë1u‡)g‚bbËº#!Ð¦uš§CÌŸ§ÂÉ,~ ŒŸÇCgì6G³¤^nM,ðÂ¦;³´~¦èÒbàöÅ²®ÀKÚç7ÚÏ+¾×©MKÄá\Ç:´üGdy{ ¬Ê rÇƒ$÷ú.pao%Öárå´xHdg”ç˜çNÅÿ2Í¹¥uñŒä®a„{²¨›0Pñ‹Å“À¿:›Å!ºnM£|Ÿ„¯¾YÕø—´n¬/I£±:U‡b´â«N2’¿Ž	Ü&;töqj8bóöH7‰Š³-(ˆÈ	³çûZrïFÌ€ä/±f:Uý¢Ä‰@Èõ ${ëêo¤þÔŒLSCeYÌ"jœ’RÇö]=§?5µ]é*[”M¹~Àå¤÷u7gþwsJ'Ð§YõÑƒšâDb o>“ªDZÊZÞ\Q?`uºgÐHuúÞ3î÷XîkÕaÞvo˜ûÆ½MŽ'Z—çU{çJÉaîé’ð3[†¯k5¦dZ°qœ~´ì§›®”5›fõØyš»«è^ÐI:¤³dÛÉUiQÕâr-²=1yµXAƒ`iã§%VœvU”¼`qg	^Ê
^Gk‚až®]¬&ëªQèpñÚD6û‘u³K]9§™]KVÙ1ò!R?&“ñF«uqqÑ<K¦Í4;képÖ3PC÷0éÆ-m‚ED˜v’ý›¯§š÷hçËÒ«Fá]!á#W`n.£»z¨DY]cK]S9}ÙJˆë‘M9£t+MŠ²±0ì„ê6r±S·`/®‘”Õ¤ßg×>‰%<äÒÌ´¦íçGû;¯;;?ºšÌÚSÙN5¹ýÝø~q·iÁÏ³eDË£!öÃ†Iïx>Í&)ÚXž¸ÝuïºÅGËÒàrŒæFr*s¡Á¼-ø§o«w3ý‚°3ìJí÷I1ŽmK3u×Áˆ¶ +Yh½ö‰p÷—¯·mõc¹Æ4%[ƒªÀxqš~¨™¸I2Åšb¨%õÁ¹N/1¢AìÕö}£_”­PLê·@8øº5òza$® ¦ÑÅÊx5ëÆ7eÝ±ÂŠ¹óã…ñ©û‡ovv®•d	ˆVm7Þ¼‡4XxHÙr8‡Ò“Gº¹ÅÂ€H¸ûÃ•ÃÆö^jýCîäJ8t9Ä ±,E?f$×z]J²—ý¥¼N<£´Lž)²ˆG‚†lÎã¶=Š«h"fH¹3G€k{Ÿ£‹p!áxu·Ž[ÁÙÁ0°l–u£„¢°Wá­Á’:”qƒÑÃ”Ž…!4•[1Ä J§ãÁeëbpÙ€enÏÆÃæ`2ÂîüÓ?â§—v[‡öÖn§9ê}¥>VWW=x ðßÇÑ¿«ëü>Ö>z¬Öî¯?|¼=º¯V×î¯>^û'µú•Æã}¦ÈR`(yÍmÍúý9¿ód”ù÷äsGí¿ÞÂ‹ß¢à/{î¡†DD[¹Õñ›­üÞIÎÿÏÿóÿµ”K9ÉJ7\’Pen[ õ£7”T“(9AL`?Ò}`ØC¾£ï4ÔNLKt<ÛùF¤
 Fí¡-ƒ‰j™ã‹À>üêa]û	§‡ìooy£!%,ã &B÷(8ñdª]§¬7\êz±@ G¤hãŒAÑ‡G6æ5WO2Oæ´ç³ñG‹iš¡xGÑÝúÀŸ¢ërhRR¨º5…oaö–qK/£·Î,·íÖÕa{³N^N±¬U/BêœO¦ý¾õ·Å‰)ê¥”Q`$ínäLøÐ=4÷$Ô\Âo~™J0æ½{é´ƒjæƒ{÷dYêú6ï¤ŸM¥•\8ÉŠÕ4éØc˜&q;®K»Àà†.]1 Y2=q|1§^}ñ¼”zAV|\¤rþ>W¯+bî‚¹ÙÑnŠ¬óªáøyÀ.QP‰¥!ïÊNœL?¨7»ÿçÿþaT8Æ­´ûž=à(ÌEŒræãÓoL9ˆ±)ï=Aôù30´ËÖÑ$‹&Ýõï
>˜¿—º·eÐp4€]ºs”Ét\Ø.·âÑ1è3¤`“ÑtY2»t
w—ãD~Âmmb"LŽ¬ü•E]{©38ëcX,ê‡÷ú·¿ý‡¤´~ÿà6þ«¥~‚Oº½<úYµ¦«k-¾R´UîL5ÁúêÚãÆÚZcíþÉÚƒõï7~¯Ð7px¼·³a¢âÕeñÓªÕæšÞ˜m{ïÅ¾Ú  D­å¬²;ëaÝÕ¹/¿Îù:éò@~jÎ†ÿžªöáØîtNž·:Ï~Vsá)x#6olïÁŒ÷6Í«?5Fæ·Wû»Îóçðüõ|ßüËëy<·££h*-tô¡9«e’»F(5ŸE+‹ÀÏ'÷Jãaè}CÅo´ÂšºÐœçjKSš¦ÚEGD'ÌÎ¨âE“Uº9]-úXB&TÎoôm~\4—Tï\a"8Ì™Èr/ê‡èÝ[Ò¿®4uÑã.ÐPÕ¹ª»°‹¹"ëe'=à€'Ð¿`mÕ'T(Z KÊ„ËõT!Ç=›itÖäê^
ç‹¢ÍÒñö^aÅ‘š:“#žŒ’Fo]ù‹ŽëÕ¢Vj‹z¬8—z<»ï§ã¼ªOþiq§1wêS¹Ý¢{6+º5?.<åUÔiÁl…ÙW#]k÷zÃw}aß_c¥?Ÿ‚î¤gÄ'7Tk2—xÜ0=C&^áL	ÑsJ·‚ÜÅ#V‘¿qégÞkœÞ»'„‰kÞKÌKsÎ"C3»6,#ÃÛ½ê·ï!ç¾§–µ8Æ±©2¾¸iŸÐ¸i-I´}P }ƒ­+ŒUtÂë•òJMU%MDÉÙdµÒG‹‹xÁ#ÑË•Æ9r‘$Æ¥G=‚…›ý}cu½±öèdmuãáƒÕ‡7“GÖš«ÍU-‘ÜJï7_f¾¼…Ù…tc<€óp8ò¹o¼ÎuX”õ2Ã6©R®´9’ËªÍçiqæƒÐÒýÜÄÎþË ÖZxLç½Û9Þ<ÙÜ?\Ð}‹œ¸-Àæ…ÀfdÑ»†—ß]øžÇ&œ>Ù_ÁòSÔÄ#¯±†b{o3¾îo½Þ<ž¹þºbÿ5@!ßš·•ªÕ]¬­7×›kÍûÍÕë ~±ûÖ~€ÿÜ~Ó.Œ—çYëÐ	[¿ôÞ¯5¿o®ž¬=ZŸéhópûàøäÅ¿ï•1o6RødX«ÇÎ}m“œíÖ`¡SÌ9ÌÅxz“3.`Œ{½Ó]ýÖ¢£XõV™|FÇ‹OSõ{×8GÕ/^ ,œïuNßs#@/,Ò ‹×y°sžR–"ýÕÌ1òþz/¢Uû“·õ×›€hžlu^´_ïŸ¸
Oì| Bž”QÂ#ytªÑäæý…¾¤~}@[©û„±ÀyÂÆ¼€Wº _’ËDyk­óŒ+! ¼oÑøÝ“.q4/çañû	_Kç=†ÝÑ(Æ§­ Ne+Àò€CŠýsØ‹ûîw‘ýÚÓì¹Oš(6ž þájº€Ò³,Åp¿y—0¹â	ÿs„ìh·9¾œ	&TÿG|1ÌOài>jJíÚÂïšÀfù¸ð  ’UPºÅ_`ƒõi­ K‡mÆñ	Ö’hâƒ¹˜x±û—Ž¨0õµOä‘~q‚o†únšE.ÙBRÁæu‡‡ªÐ›èw,-#)[ù\$”,†úyÐa÷f Ø‹	‚=Uøí‘Mž¼¹~SrQ‚Â Cµ¨ÍM¸ï´B´ÇË‚;jsußÛ%¡ØHìÌu£þ'U[ú¨›]Õ@Š¨ÕÔÏO(m-PŠZ4úØ%—«VS·u[)Õ¬j¿DC	’‰ºƒTÕ:‡‡û‡À‚ÈŒŽžSå›ý8€ÿÁLz¬ñà]9„gìœè¿øèi­©œ)´–>j"…Ïvö7Û;ôËÉ^;ñ¨i;Õ‡‡®ù>ø|¨óÙ¯™;_"˜avŠÏÚ Eú ™ßæÂ•2\õ–j÷šB3Õ6Î2$çH•z1[?Žu2  w>‰ÆRö3¶¤ïí áX¿”Zª©ÿdÁõ^SýÛÊ¦p"š[ƒ›‘#Â¿O9Líž1¯
ašÁUî¹Š/=&²'`îI‘`XÓxÞ‘¡Ó¢Íg›že*’lP58<K£óÊ‚S²èuF;wð†FÇd„kÝÎºƒx‘O1ž_»Æ=íÒBczÃmš;Ö3pTl¹Ã˜ñ¨Ns¾4n"@ÅÆåZÑ0ð¼pçE,7·ç¦J…¾ˆ],Ü‘¶pSd\…¬ûræ8U=cmjØˆ7ÁM“j³8ƒ·²)ß1gª€¸°pŽìÖ#dc^“º¹FóÀ±ÚQØ¦S¼é›üŒEˆ®ÅÍ]"Fª;Wçž–³Õ«ã	Z][pëŠå]º/N,¬$CYF<°wö¨$Ð‹ï™-Å^¸„Ë
KÛÓ‚OB>ŸÔVÄ¤ÛâhØ(Ô§âlhÉ·Q‡ ¾(	4LºWÅ®%û¸ÝBaNõÄ›±}…:aÀÖúkêû™SÙ¤	‰ÚU˜¹<-T“š·½=•
MßAš“ŸGà­ö=®‹K†ÿ>:ÚQ¦ÞWÙ°Rd@<PO¤¬XU)PØaª«'ÂœMÙÌÑ¯YYtÙpê¸³zS¹{ÂCuÌRZ}ýWèÇ›P)e.–EAÿ½¦ÚImé¸Ò4 ý’1B"WÓáøªÈ¿@°vVbÞ"Œ$<µ¸\€ÕŽUq‰öÐ!·3GzÆôÊÒÒO·5FÜ1}Á¶9ƒögÖÁü‰‡Ç^"è¨¸¢áX-Vlånl²{G4xNí'x³,ZÑB¡mÆ2É"V®VinEØ•»Ö´vfnõùPc?ËP¤¬ë–Ç):pÅ0?1SØrìT_Èé—åUËÕ¬/F+
Kcé©§/½$ASÓà¦ÚÅŒÎqÖo‚iûLuö_€*+áH/†ÑJDrÅ‚ê=sêì½Qo43.ê6áùzNæD}T³µ™«Ù]%ÓSsšÞ¬7„®]'r]-u{é©™ó¿]n•³®ð S!~Å8±¹ë*ŸƒIZ¡ûõKºvçXÔD‹§\14¤ÂÐÀ¹Ý…hšá•\E³Vf­>s‡‡¢›&§Z’ ±ÊbëžiÉ•w‘eù2©ˆè ?…£FòÉÝN½Á˜ebÝi¥H,rŽN¸W=¡hYæâ/®Þj³²¤ÉÆý•õ¾˜sõÆ—¥3KýÅ+cÖNs÷ÙC0Æ·ež–Þ9’L'Ô)Qþ¬+} üvÝq¼³gíØ
5c°°âeÝxkm…ñž"fÑ£‚#}åM;^!þ(>á*Öi™h9pYÃuwiÖx©Síd†N¿] ð;ÅÜNý†Õb¿«ÙŸêý ®àx,ìJßU5¿ÏêTP·ê:>U©TŽw¶¶_òc Ú4Æ`ÚÄ>xŽCä:Ãs›»,*D€ó…;uBž*Á¸L~_'¬_X›á>(ù¬­ÁëÍû<„Jqå¼«¼ÆÞù3üÎDU‡PºçÐtãSšhìr”Š˜²òÈfpOõ÷Xm!|`Á¾²Í æ±Z‰ãkêI?¥líï¶·÷*ÖxîiãËcoe³?Ÿ´¬¿^ã£eB2UM<±¶*¨¡—QÀ`|<`8ð+P åSmÝÏ+Ï¨AãØ®t4‹©x?U·O<‚ôIÛ‡fÇJ;¯dãÜùpqç@ÉQ|'½^Ï¤´¼±
Š‘ôO#Lß“[Â¬­‰5ò¨2+•¬ Ý Z/àÜŽœ3™ÝY˜ÂhöB[ÝWg•È¼p²³}tìØ‰Y¹òƒ]'á{PæÉŒ/·Ÿ3 ƒ·['/¶wªdš})¸QUõõ4Ð¥ZÎ¸jù;>¾è5'ÈXà6Ò¹ÿýÃãRßÜ¿×™¾œIˆå†f qxÖ|@Ö¦¶Üaç`Ñ¸Š–¸Å@Ñ· ¨±õÍ&»XµrÒÖõAwJšÈ¹j³êŽ'ÅÓ”pý“Â¬àDlMþh$ÇIÕÑÇ†[·øælI J|Ùƒ´ÎÒr2}Ä…~ý¿R`»8¦^>C„Tô/º½fæ4^Õ=EÞfƒÍª×ÀºxÆA0ÚÜäòï%ßÊÏYrTgE,jd$Ä*%î9…¶ÙèVR £0Ç2ýR«…Ê ¸Ì“•‹‘ óŒ2¼ÜŒLý )Å3àX·7’lTµ®²Kªûé¨Å%r9	Ãª%¢Îð7ÚøB¡R¾®VíSº—€ZiÆ Ñ5FY†EŽÌ( ø·ëÁ”\G¬>`ÍŒ¿]´‹†Î ßÏô{ë³£kÂ³¨%iÐ¢x¨á˜xn?±"~Š`Ér.§Õàç%æ¹mø B<Ó™ñ·t%"O8Dw&ýd2z« nÉœ¬_ç u·°Î•Ð7‡Vi‚PèÓ„{‘N¾”ºûßÿËðäúºDºäµ+i -'c-,ü°ÓÙ{yüê™LŸ~»èÁ_/R¦1IÎ˜›‡@lÖVéº‘°H€'Ž*÷´Q+×5@µþŽÇ’›
d
í_d¨00¸‹a”œMöîéP
nêMÀ›—LÕQ‹‹¸ÿûÛß¼É~äÒõ½íÎ‚æå™œ°Eñ„¼–Îüïÿu–ôŸ/#]ÝÛÚp£µ‰¶ºøÜ4°±Œ~gcƒÕð‘'Íƒ,Ü¦Y+}°¤ghþ4Oˆe1ÿhW±†(•ìø†^m@=°÷^ÜÃîmí¿Ý»G¦Ý_Ò89}ª:pv\0ñEªlOu€F|WŠf¤äJª€80éÃ,Å~ØùÔ7×­…ŽO¤àiëk?ö’`N!Ýáj©qRå?Ã%ð=e‚öŒÓŽwL·*(¨Œ¥hCë&ã·¬×,öt.b’X›l"÷"I7hw¶™Ø¶°¾YC.i‚Œ›¢—yB¥yq™‹èc°F@18Å\¤7!þõI·©»¯´ˆ /ÁÜf¯ûé¸Ee,>ù&RÅ`² SË€>¦¶¶×žÑ?ëš$ÎEPô €ƒFÞ|
€xsF
ƒ;©Mp;yÍÁr8ll¶\æa+F¹«:«MÕæ ´ZJ$v#g–Ú	²ÀˆtÖ*Ôvžc†•u¥ˆ½ÓéÊÝ‰A¸†¹QŽOé_®	¬o73U1t+¹ÆEýôþžÞE·8Þò…å˜·Œepòÿ¿½o]oG=¾/ï€U2ã¤Ç’x§¤^õŽc;iO;±×r’žîôçÐV[5"åÄžÎyšóçß¾Ø©@¤(ËY±ÓDïd-(Ü
…* .ÝVQ²yÌ
ÁŽ:k1FÎÙsÐÔ`µ¢Ö‹n­öùu;ÑËçÙ	@HO&pl'†"-^ôV¦.zBŸ‹,÷õ[Pé›¸ÄEZRN<é¤ˆ™¿¼+<*ëM¥™†Ž	]¦®•wÐ–zÓ‹¹›µhž§ÌYÐ×vû’&TÚo
¶ê¾Ú¸Úÿ¢ª–ùÿ1-ôÿ£Y•ÿŸ•¤Z*àPNcÎñAÀ"×Øs/j×»„(OEõÎ¶gÚ¿L§!ñœ9ÁÎy?âÜ¥Rw¾öJ|Äö¿˜ñftâÜGö¿¥+zÑÿ—mëÕþ_Ej+Ô1ayÚžëèTÇ}PUo»¾¢w<[÷}SU}_'ÿÕlÍÚÙ.íPµcµ}_3Ý¶©š:õu«­ùah;°[1]E®ÙšºPËpÝ4]Ãpì¶¡Zm§­m×v,ÅÕµŽo¨T®Ù¥Y†gut-p]ÇrŒŽæ˜mÕ³Ý¶êšÐwªšÖîèvGª-ì#¨C­£zvOÓÕ@·:®ïR„ÅÓÕ¶oX³ÔÀHµ|Õ×Ïl­cÁ MÛõÇs¨a´-¿í«ŠMàs „qu¾ãûm+è8ŽC;O³@o«mÍë´Uª©ª^l\²Œë´•¶eØšØ®ª¡v|»c©0\? šçùŠ8m*@+:ÓwmÕ±MÏƒÎšAÛ&Ïu´¶åhšæk®æØ–"U+ZÜµ=UU5§mªcª°ÐŽ­´©ßQt·ÓéTWa!LÃF‹ìÉ\Uu¡7fÛ÷:AÇ¦¦5M@X[<ÅÑËRÍ<¬r“8SÓ,Ói¾hmS1Xþ¶îxZ[Q ->Ã²Ø³°fÖVÑÏS×Ó<_7t“B7ÛŽbØ–í*m›:ªâ°1fAÉ–x4 lÔLÇ‡)65Ë À\ÛòMq,UÓÇrçuˆ÷Å¤Fb*`U§£+°Ö€l0õ ]µ:fGU@Ú(’íŸé™&leªÀ`L@mØ1žîXT÷Mi»ì3pmþäÜ÷f€Ýg ñÑ…96˜X"Ý£®N}ÛvÇ…Í¤ºïi°ÃJÍš@:ºÓ@ªßÖGµ\Ý3}hB`Ø`i›§˜´°ö’é¦ÖÖS‡-ðLÍvÜÀÕ¨	ÿŠÙ¶}ÇìF/àaÞîÔ4vLÍPtM§TWìÀ%h«ð«£t,ÍVßtœÂË[–Fg5ÖÖPmƒºN§íºÐ{žj®ª»6¶ hõ¨q%œšµTè”j
ŽfÀVaHmMuØŽmØNy
P¹¨Y*yÃ…æ©­;ÃSm¤²:À§€GŽKæÎ-N.3©UÔ#aU›-Ú	#[÷`‘TÃs]Å†*°ÛÝT]öŠÚ¶= ´´SÒH@NÂ0>BƒN˜:&L<"jÀ‰¨¨:š×Ö8%=®ok6 †§©åPFâŽdO|ÐS³ã¸mj›ZÇSÛw«c;íŽ©vTO^×Õ‚Žâ{å0µ£ÔNnü”ZJö¢¢i,‰ÓqU8·›zÀoÁ pÆy–Mo •Í€êt‚¶Þ	,Ú±<ß® £šŽ¥»ŽãêpÎypÂ9Ôœ3¯ú¿È;B…È£0ð.Œ÷ ðØ¤Ð3ÃÓ| Û`©*ä>µUó ³¬¦q³’áàï€£Xe¶Ž°!-`<¨áhÇj«6àj§p€¨ ÕV<Ó1§¦V„©!LßÑ;ÀQ“Z®áÂDÆhÐ1-â~øšŸÍ+õÚŒ×FÁL8§Ú¶Ç»ü†ªY¶áy:çRÀª~$=§Æz¬³`´}Ç¯8T×©ÖnCíÃ®5,×Ššb]{# ¥¿x
²¹è¾åjvÛn+Çð8RUß*äHõ•ò™Õ‹3Ëú©êºíxHtß°lG¥°,_³¨âÂíÀ©Ý±ìR˜¢“üä_ÔœÀ2m !š´Có¨ÅØUµm XhÃŽ[ŽNªV:›lýœâ ñ ®N1<Ø3€­}˜fÁþíXnù¶R•#î¡P†P?
lNOÏ´´(Ô`»vð$„Ì„iº¢:Æµ×ˆ€:ð‘^ÇT±6ì09ï¶ÓÃ!˜m±*%œÓ³4Ãõ|Øå¦ëP(Šçƒ `ï|‹Xm[U…Ñ}”!ww6·ßö·kºCr}ÇÁÑÀ€ktt8x|GW7ù}ÕMêe#Øaí€4âàzmÍ¥Ù#Ç¬NÛzä$5“[«?©à¾¤„¼Ð}·r¿iÎ¿ÿCyå‚tKÇû?Õ´­ÿEÌûî¦?¹ü_&-»÷?†®¨lýÕ0@¾„õ7lÝ¨îV‘ž^S‘lñýéS’:ßÀÀ‡è²·x-ö8õWÒPÏ_nõ_@¾CÑ‹tOœ(¢Dë¬`5òNªØL×IÿÓ ¾¤t
_[f‡QM´ÉSwÆX¾o°ø0â{?¦Z°;pò<¤Ñt@yM~/þ÷XŒïÊ¡ö¶?ˆËkÃÇ-Ž’¦ÑFSÑ›j¾° ÂÈ3àÖÍýéãyò²ÌRJX9Ëº‰8œÎö¦d˜Í±á¾‹f”åFÇ'—¸ª€}cá[€I€?ÔÒg8Þ§×û»½©üm©‹øc`¨- £ŠQõb9óCáf16'hoˆ–ÚÁFâÝ®àæç6^R“ÄäE{æS?³!¥Ÿ‘ép+·Ä©?3óË7Î 	‡ò"aÓ†ì ˆ	åú¾pé*ÕÏ3ñ€GzbàÒÖÄårîb£ÉÛ<LÞ¼„fñŸ/"ê¶ïKJRË,~ƒÇÂ9Ç\Ïqw÷hó]ÿpïÍÎ/<ÂèS^j?	Æ—·
ÎÍ	+8ëdTø0aoóÂ~3gu±ž³ñ+ºd0g,<%˜¨£y@©C)°¼=¦ †€ò6 ÜSnÂ×|æF)´¼CO©k9uÖÒþÍgH–íl$¨Â f1LáˆPZÉlæ ó“(ùˆ–AKþ6oë2x³6T<´˜b:5¬è¬+YÙÑIÎV¯ÐfÞW:¦Dx³aexÈéy#•+Á¢çÊ§ðVÈh„ÐvF1ÏîÒ$ŠUž¶D<Vhs©Tô?K7ø•ôw·Txr¸—6®æÿUUÓµ”ÿ75“½ÿêVÅÿ¯"-m‹>B	`žðÙÿ¼³WÂ‘câg)˜2‹OÉ²£ÈÑçY DçpG:Ág	Á¤ag0JT-‹r’h«Â­|ªd†[ô¹}`·%Gœ™ÕæMZÁíu1ŠÏ|.ßoôÞ£ç©%N&Wç û}µ·öqú÷'ÝŸZäWî®0a-¿üFÖ’’žÒƒ¯Ûô%ûâôòõ¸—TÀíI~³ì¡ÈfÆ_®ÓÒÀ-6U 9ðŠ¸«ÃÌòW*{RZV*0œ-y³’¡›u¹Ð#§øI¸øà$ïIjÉI6€‡ì„ÕL³Ù$î¼ß-7ƒŒ%6÷Þ¾ºî„ð•x}½!K²ÂÖÎAº¼©ððEÈQ«€R2€íŸ™Uà Âü} :àdŒ+*Fé%úc¬£|ÎoÁÄ‹Aes™nTaúyûMUØ¨œ¾¸ì­±?ŒÀÃy2Z[*ô„õçŒ5#
“‰LWc¶Ì *@f2ý¥ÂM(‚Pcõgƒ¢7\.IäÔ¯ T½æ‡#Z~@óæ©½5Ï'ònþþß$:q¢éix¤¨®H´Z>=o¦ÃáÇh‚×8'õ.Ùû©þžPõ¨Õ%¯6vv··žµZiÞ3ÈÅpß¯··Zõï	ó Ú$X9 Ÿ“ÿ 3©Ë­ÕÉÇ¤1žF±òÇggr+®¤½‹¼ú|ÌvôÆ†ÿ_¤hr76¶¶x'¾ü!º5¦Ð8ùOÕuUÔ_ÊLa
.R‚âÉíIâO.>¾$CÀÎï…ÿVá|>¯O›êþrÝ[`$>^v|«Ô Ùä¯‰ÅDž­`ŽK…Ü¹¥x«YÑ“¤¤DÇ³¯ƒR@@ËK
É—Tþdny©Ððj Hä²ÒÌ—«P—‘·F].…T|¶äæJ!QŸ-¹r©ÙÒ×ÐÍOknÆü:‘Za7‰y)aÛA&#Ž²5v£O€œn‡ð'ŒËßzKêÞ¨—¹žyÃW'uñ=ñÀ¸ØÔŽ;ëÄ$Â^”m7ìä{·“\y€ÉQˆ¾ð1žùKƒÎ‹û‡ÌöÕÃIz$­MzÌ¦SzÒ¬Óocþ‰Ci&7êÄ/™1dò`%†`IÖ°Ù[Fâ©ùtÎ‡á¤çLã0-Ð[ÛEWW»»‡Û½M‚…!ùƒ1­i¡òRnú=Ã¬ôœKÇ8œð.ãIšñ¬²þDCQgö;fÈŒFÑ#x’2aÄÊv-ó=óÓq–YÌ‰ 5‰¡5€5•«wc‹ŸgÕéÍª33s©:àÔÍ H¨œA‰n#³K—@œöÖrFá_iË²Æ§g_·3ðúpæL.’nÍ ŽÐ™e5`mˆ¬[ò=ùó2óNøóAØ[;ä¨ Pî­¯ñ{è½WwçQ«‹Ý•¤r5ïå¶±@ÿC³M#½ÿµLÔÿ0u£²ÿ[IªîËt@$ƒ‡Gx,;I¨nƒ£Àƒ¾~œ×Á×º^ü×g„<å.;pý˜Ÿ%þnb	ökI.²˜AÐÒXª2úŸYfÝß³Ðþ_Óú¿šmWï¿+IO¹—‚Ûp)¢òh»™ëT<'ñƒ&>°+èÍ3u)³Ÿæ"wƒÝÑ$¹¦È=îu’o†˜NÅ=&Qvìíà?[ýííÔƒMíéMw ©…iÐï®ª·;]®k@ê¶;ðàþ¹rÃÊå¶±ˆÿ7$þ_1Ðþß°»Úÿ«H•þ·ÄûÍ‹&ï?G¼œU¯4À+þýFýæ˜òûåŸ{ÂðÙ÷ÝÆ-ìÿ,Å¨ìÿV‘2›àûkãæë¯+šZ­ÿ*RÁKÏ½´q‹õ·u»ZÿU¤¼WœûiãëoÚý_IšqctmÜ|ý­:ÿW“æx¡ZjîTEµëofuÿ»’ô4o¤‹ÒRâ‰>E;òIFNäW|Øø?a&ùí{,>ªýïf–Yê]ÄU«=¦Z-?"PœyŒmOœ³¨VÛß8ü±÷ÿí>c¡®š©±È`ïF‰Í”cJÜ'Ô;Í¬lyü‡yXOmšy¿ë’nrôH½žöždduTÄš4¬º\ŠfY	øB‡e¸ÆíöÁÁÞ¾Ô&&Ö¬O¥5a²ø|%v<‰{¾™VÜ5Ô«ë'
§÷KžôÚÂÊ®»ï*åøÉgßrÛ¸îùo¨¦j«
ÒM«øÿ•¤Ÿ`÷ÐÆõ×ßPà?Æÿ•ÿ§•¤ëyÚ¼[ø?àùôdýÑ[Q4ø¬Tüß*ÒÓÿ` rmO–wéþä6¯Onñ¸ä>çKwÂ“»=
>¹òUðÉügÁ'³ï‚OŠƒ<ú:¹œž:>‡tD|9+r\>)¾r87|Ö{2ï]oÉë!¿ì=YÖÓÞRûÈ€	q#G(É97†’Ås0áæIÊ‹9Þ„ëI³Â|3mø–càòŠˆš‹0V°˜å¾žºõ¤ÊŒRé–ªº¥fåb…$7+—fåËa®k&è-ƒ¹ù2ùX±IÌ-”ËÅ½MËqËÅ´äÖÎÁ›·ÅVynV
¬­™R<÷[¾¼=#î+ü_#¢(|Ba£áA&+²¬êóÔ	ëIqt‹²7ZÐd½+~ÍÙÏÔåuHJlå¾$ùCßï3û>ár~$}`³œ|d&z›áhÄÔ»äR|Ž“rH`pòÒ	Ë ø¨…°=ŠaÇ‹¼$"kŸƒþàxDýM:‰ñº‘Yâ6S‡Óê:ü~~ÖHÔ'Äwá¤ù0‡ÑüR£°1ž„gc)cŽ±9á&Ûr)ÍOV#‹_Û-úÚXÀÿÙºžúÿÔtŒÿ¤)¶]Ù¬$U,_Žå›ƒü™ëûe94¾<ŒxÝFkŒ		¦ð? s¿-'"»[;¯€wš0E0ï„ø'¸Èr¯ðäIQ;Ì™°|Ó€Žšä%Àÿ|gSg4bàXÎ€Ÿ9£)šÁýå€’Otâ$(Rq¥wèã’Ü@CQ¼MfG8æ¼¤‘w›Ö?H6FCØÃ#BqÃƒü‘!äH(§Ø˜Ë1ß¬Aìt5åØ«N
@g°Î×Hà	ƒx@ùm74?ùD1 QYèÄÃ4oìŒ|ú™`Ìè³cGçÔØqœ úêpB1®t¡ÖÒ¦Ùu‰7ê%³¼ànÞzáß\ióI-tþis´²¨Dã½Éñ>ˆ{á¨ðm\–‡ãBŽ5¼à˜ñ„ÔÀ}^(NŽ‘ðíè“¶¦Ù%ÿî÷Ü0UíËáþûOëŸO¾÷î_ï"»‡êàÝþðCçÓkÿŸ{Çj{|Ú:9ýtþË«ããç÷¶OvÞŸì:ÿ=Ü>wÞ•ÉæëËËO?µö#Ó°Þ÷Gã×/[¿l;t:Ø}ÿ¤æº*F¹_b0‰ÛKÊÌÄ…™eÅÆ@žˆµäo»¹>@
Š,8â+Äå¬1ÃÓødNOð{w‰'|V \Òü—ãÁ9½epÑƒ­ÖdùŽM­`G~nOÝ
îiŸc?«¾°Ö(¾œ³ò/áòNâÁ1ÌqFpÁ|Á—O"¦É=RñÓÏ¿ï´Ô½×oÆoþöÓ‡Ÿ¤Ÿ¦?}¦î±ýþóŸñ¥ýËÈþý"ØÚ>9<Ûùqøó‡l¼ÿïQôé÷¿ýCÑãíÝö§×û§Ÿíƒ‹ÎË·­_Æ­7­þÖÙ¿~zÛþ—v p1ÍÐ8Êÿ¼’JäËÍÙàiƒDÞå éŠ”Ÿ—h8À^–—à«Ú fÌ¿²À§	ì‰òèb‹Â¹«­«ËL(2/ó ] §š†ãçt·û°!ÂK——A·ÔèbäÍù<@ÇCxI€  4”ûýì3à é_Ìÿ>Êðëó…<ƒk\Q€ó­åÎG¼˜;Q‰¿œm:D–ÁYÄòRünƒ­š3¯3¢Lt21{i¡òp—Þ@byæO³ÕoCòãíÉãO×`w§6Üÿ˜ª•Úÿ©ŠÆÞÿŒ*þïjRõþ'÷9Tº¾ÎU¦\ç*«Øû*—±xý@‰‹SÎç¾;;¦ÈÓ7g¯c^O¦#?åì1øÁ oa„ÃcŒ2J®‰œi>1Î@b¾%³–^Œ«@Ï;›âaÈ/}r7TÕÐúˆ"¿¸“Ý!CI¶`Q8Ž™¸¸?ãHÜ¦.DOÃÉ„žÆä˜2Üƒ)àà	“ðŠ°ýÍ^¥k¢S[†Ýú5É‡“Ÿ8v œ¸Žw‡C9(QÀB¼c@ŒJÛ‚jc"y4!Dtôö	«Åë$B7k9FPÉtŒxàœË>Ÿ'»§¹ÜI\£d7{õV8ŽE¨˜úL|×ëÕ>ŸA^ð§^Œ¯jM­©6¿åºÒË ^yø~ù7þèVêQºè(y€Òî¥`
@Ž˜ŸM©ŸÉcc¹ÇofRèzËDžŒôñ°‡.òzèß¡P¶ßßí¡Ç‡BöÁö~Ý?dÜlÜq÷$Üìæ]B>eÀDoû{¯?ll—-
ƒ#Ú´Î3œhÍÔ:ÂØ4P5ùý¥…ñhJÊ½zó!W,8ûTRêðýV®T|î·’a§nCv2R—BàïÑ½rßŽi)X,%Dg‘É_„{â=U„Þ|¹¾z"_¥Úþgÿpï`û†(÷ûi4bÖ¯Ñ|Í±Ôû·;›?á>èÕ“¿²á"Ô:ü“ŽéÇ0Š³Æñù½÷ìyú /¹ž$üÁ´ž%Z/ðì}Ê `ÙµÇ”+Ôz.Wã¹Z>Wç¹z]–ó`gÜ§+Ñì!¥k¿Cä?ÃÌä?øÇàïÿ•þçJR%ÿÉ}ÎËsvÂCVRYð?ÿ¿ÂlL#øûd‚Ü²,¾tb¯ä1ÿ§\„@¼é”êˆf†õãì•Ÿùš)Ÿ5¼/mnÊ,Ë`ÜL&$©ÇùŸ@6€Å#f«Í[ua$Fu›Bt2	sRÄÜLké)€àrI‡XM*Iô–}üJ²ˆ‘ŒÙƒ
¸ ¢¯/:Ö9
<•pËù$‹IÊ¹'}³óz.,Ä»:‡$Çã-‡%ôvì½‹ênª·›ûöTw—¨’›àC¾T’›•ËV[.—årõ]^vÃ÷3ÌÝ!öÙ«Hi÷Îu{ÚB%Yþ<´HÍv\¢b›8ÆŸUëq‰_ªÒ+”Z±ë"Ñ•»›ÏÏGÁrú‹†˜Ròë°¨|ÇaÎ(ëžÓ‰Çdò35*Ã‘àëâŠ£OS×äÿï¤¼€ÿ×TÃÌøùU³*ûÿ•¤Šÿ—û|þÿ¡«ó3ˆl)dü‹ªÀäTfóo¬<G,ªTƒ	;.ÞúZîÎ–,ù¸{X^•riöü×ø¦;B=­#au§À…öß†’ÿ:ê¨ªVÝÿ­$Uç¿Üçâù_¾öñ/] ¢Ó Þk2t|¡’=¹a3åÇ¿€GÕxçXéÊøð‰*dáø>ƒŽb“œ™h’>C¼™hœËšøç§PÈ¥c®âHãê>î.}¬îãî÷>nOl	$|š°âþîæ®{·µØ,—ëÃ¾¿²Ç‹îp4ü(ƒ“’Î	'‹@Èd#5‚÷†SŸ¾œ@—ØMÒóì‡©°ïl1mf‘¦‚ä²¨ìŽ«”åŽCbÌè®h†ÿÓÔ#.`p‰Ql£X½gý_ÝÎì¿U[SðýW¯ì¿W“$þoy‡Ìm¸¿[0KípŽõSµ#)Vï‘ãûl'hM6K1(ˆäû'Ý¾Bmx)ké”¦ÀîÝœ“šÇH-u5`´äGÎ)a5h@mâ|À™;• ³È™„ò]bãËc®Í‰#T-ÌÅÅºE÷…óQKŽ>‡é¸)ÏqÍçÀk¼JETRdJXn®ŒVZFËztÅ£âµßå‚Ûû³°07-võËãµ˜®š(•¹¹ECÖ1óƒƒ«È§+˜„güo­¾è)N†'5ó±ÆßåúÜW,&Þä’<iÂ’â[ …F¥xgxÜ‡BEáÒGòèSþ€Þ³VÆu=ë‰“ «ž÷j¹0áÙ3ß¬;žÚM&† '“d" ¡q!<yI‡—Ýã•‡Ïžåÿ´"ÿ§­”ÿSuÎÿ™ÿ·ŠTñ¢ÃÿWñ¬ñŠÿ«ø¿Îÿiÿ§.“ÿSoÁÿiß"ÿ§þiù¿9ï¿wQ [Àÿ1~)ÿES­ºÿ[IšYU/e}ô;‹ü?(f¦ÿ‡së¯ÿ¿’Tñÿ¢Ãyþþ&xøüâm†õgÎÐuÛÙLŒç¼+··¡O‡œðB?W²Äƒ“%ôÒ2ú7"KÐÙËË’ô@ba8®×oÄ/‹6©@ÍËjsæÖ* 0P½ÄŽC-á›Ù¥‹èŸ ­•‚Ö®­•€–³/õ
Æ{Ó	•vZVG»ºŽV.ú”Ê©<t… q1â2¥þdJ½’)±LY¥Ç“®ÿá~ßlÅÌâi:óÿ`X•ü¿’TéË}^âq)ç£€M2'ä7té0'*Æm:”Á›uw¥Þf •ºs¨4ÈïÐÇJƒ¼ Až¡"ŽäxŒ‡“¾•ñzGûýþ‡½ƒ­/I0é'5ÞP“°~ÿt‚m³G¿'~Èó0E½gÏÏ$ÌØt‚»ëŒüIÃ÷H}£ñ‹Ó¸T:dáÐ'ODUàÇ	…ukŒˆú"†}ýzú4ùä˜’6ùë_a]¢:éõÈw¿°ß¾Ëgðb4Yä·ÜðÒ]Èea>4 @&É¶¯1Ô¸‡®¸'‡ô~  /_ÕZqšea˜í+`û6Üž…¿»(	6Ã“Ú
üo?‰8à;î—ºÿÚcîÉ»Ûæ’=NŸ¹éJ%áC¶ÅfàpOÛ	¶îLlý	>ÐÐM1ò]ûà™Sm#«EõåNK¶’€ÌÅ]R­À
V Q	s…Ÿ5°`v¼ÜÞ?¯ï®ã¤óLkÐiIá
ÖèQy¼y¸Þl–ï®fÉÞ\`½1Šçß-7qiS¹­¹eª¬ø¿É4«ÿ«õïòôÏÒôyü÷JÿwE©zÿ®ôÒ»~¥ÿ[½Ùÿ©Þì«·Úê­öAèÿŠ›y öÑYs|±cÿg˜VÊÿYºBÕÖ£âÿV‘–unY¾Q Là½ãåîá³6`¢¯Éí™=ñ@úo ãWËàÙMUk*FÁ›ÃÝÅ¡è,a%[á™3x$ÝƒÖÔ¬q“FH‚}ÊœÕÈ\ßyø§æ³9?b,K=¨Õe›Ç4~¾¶µ÷fcç-‹x´¶NêŒ”ñzõ	€1^Ø\ Ï+Ðš*j‹W‹Z‰êä/DêÅ‹;ŽØ ˆƒQü¼U\°Ã‰†@mEQë/’ÊQ4Lê_U¹ßß•êkY}v!;o8Ù]7VüD]XÚWO;Ž‘¾’ºõü3 ðGµñ;´Æ‘m]ÁEýú—è·µÂd|_(¾ŸLóLq\€¬8¿lßOç0+žÍn±4^IòÅÒb:³
ï²ù)ó—•NŸ²æ”ÆƒÒ€ª‚|Øí'Ä€ç0úÀsžóñî†‚ÓI§Zš‡õÜ{OÉ:esÂ«eóqU-Ä!sórUEœ©·ÒæÊægQ­lÖz3ó´$®êkŸÖËO³ö?ó¯>nÛÆMìT]eö?fåÿs%©ºÿþvîÿ*ûŸÂUVw‰õ.ñÛö%p+ûíÛÿ$n*ûŸû±ÿ©|JTwÊ‹Îƒ¯Í¬ViéiVþSŽ8m—9àûÿj›YüdAŒÿªW÷ÿ+I•ü':œ—ÿæl‚G ü0¶‚3ŒAŒCkœäpŽ
Ê Þ#R©„¼+…¼I%äý	…¼’C”ž–|!z13LÐKgàN’^1•õršÐ9q/Sƒ¾‘À'ú™‰|å-hZ(Ê}s¿ln"ú]]+'üÉ¡*r,ÿ¿9Ïÿå+€@Ä™n)÷5 ŒàDÂqÉ¢%¶¢È–MÇÃÚæfn¿èv-û´Š¸¹ÿW¤ø¯šÊø»âÿW’*“ÿE&ÿˆüÙèŸ[Ç#€Aéõ'9Âkfýÿ’Ž¦8˜mÆP>µ~*˜Íº€‚pxLGS.×üæqZÉàLô¸wŠ±Ûh|7gÍó¥À°²Y¿Ïý—YcÂonÅ?*1ãŸ3†„|#3É)¸|8S‘¥soÔËì5¹ÚÚèúïP?á`?£ýô0ÎÆñ0taÃ“gÉüxnÃÀ@Äùë!m$Zs !t‡žx81—ž8çƒpÒu<ŽãÊƒÁú¸ä7ÈÆÖYf‡?æ¼¤ …Qs§ 2ÁæÄ@ˆ¸åwV‚ÊÌ#GŠã€þý©O`Æl¯øtHÑ+  =úÕ€ï>yœM)Û,¸Ù_x'1 LÔˆllî®E°ãÜŸ@i™/Û”K6":¢" & z<	‡X)H')ª#7ä±oÐ­?‡Ãö˜Æ¢Bïc]mjÍ¶¡4UU7M«©6f[1?Ö_`ýçÂºƒ ’~O˜Ìú†cúWìÄ <J'§î§NLšh…ð^~¬Œnøé9PxŸÁGúî hã
[§›?¶³r[o#ü›of ò¢¾LüÉÐ;SáÏ×ÀŸtæ—‚@)´Åô ,sgùÿÒðîw’ úÿ2´Œÿ·1þ‹ªÙvÅÿ¯"Uü!äóäÈ@8ù’ÀùÀÉxä^ôÿ‡Ì÷Ïeû¯Íõß†é¯xþÕóüoœÁüFÂG^Ÿ_õÑæsŽäÊULí,Ãè+¨;=gˆ—§¼…Ñ˜c3rk{l)Ù;ÜFäÀÆä=ÀD¡m6p[7iófˆ‚}‡À'^GtéFçÎpà7Ñkh÷b;ŸËÛÉy‹;c!©«¯}ÖÞxâa¨Á»–kWdq·-(¾€R—;Éx1 A°€Öø)ø¨‹þÒxçÞ}´ÒRGÂ»S8)t,ÍÏõ-ËåÝ;àÐÒÞ½N¾§DÆ5
è<q¼8[h«©7p†ÝÆÑ_¾“Ç“ç[¡ëÇ'N×XMÏ g¼®¾žÔÔÖg¿‰>è·tJ‹sÇ„1pÄ!q"¹z"¬FŠëSº4ûaä¹àqÕ¥Ð2áôtwéè8>i¼DWzÓÊÉû¤Diý»SÙÎC**\ e@b4¼b=£ÝzŸÄ}Òÿq£¡æ:	û÷4œÆ_ì…®•}€B S ûf:Š»ú,bÏòŠ#cx(—=ƒ=”ë˜vmÛ¶€_¼²Múy<u0,‚éìZ…:…–ú¯)œg [M'p\d3Ã»tó}4¥bA˜º5B²ú^…Q·Â¨ûG¾þÀ`ÒÁ± òyâ>À“xŽ"}gùX7ï‡vgä.égø „¡ß…ûô³`—ÁQfàX‚“Á„éä+?¦ |#¾Ó.Œ <¾˜÷Ð;B®iÞ÷hêÂÑ
glZ ³ù11ðÒL^ƒõè?‘ÃüpOØ0ÈÖKLæ$?:š.Déð8¸Ì~ƒÎpØèëÖå<óeóeoƒþçÿ&·Aû¤Õx—Uzð)»ÿ~|Æ(…ú-f²¼´6Üÿh¶ø7¹ÿ/ÕÒU½ºÿYEªt>“ËÀùªÞ¹›ìL’“Ú¸Wj¡Ñêv¦!X¼¶µ*ÅÎvÑIÎZ\æZìý€;FºµøAþ¾I-)£áœãQÅïPnZUvMÁêþ›»cžôÖ@^ì½Ûg9^8¾ ^päŠŒ3d©"î£œÒÓáûóláMExÊ~q´íÙü“ó9¾¨g*oj_j·'XœS7îÖ›þö9lCÆ)ì* <’…Qƒâ·O!ó%ÝôÏ¢&Ò0^	¦í,µ|·œ°;o Ù·Û­Ç‹ÀW€- £ÿsÏÿ%ž1ÎÕVµôü·lÎÓ6­êü_EZµ4³â*.à†óÿÀ¹€Ý½×G¨°Œsrä:ÞétÌHs.Ÿ~F|žÍçÊÄ3ùtt¾€¼/¢æ¦DÍåèùíöÿ\úË¿$³þ+F&ÿ©èÿÏ2íŠþ¯$Uò_Eù+Ê_ÞÁo›òó$ë.›õgiý×•Ìÿ¿¡›ÐÃV*ý¯•¤ÇFµÝÞ„õ{è’W¾W:½LHü*‹Óáp’OÂ€HN¦#|L´—8 hX!j‡|ÿ¡a3;Ð^qwosc—™(J'PtB1yõnw—4ÎûÿNÀ…¦wB~`Ñ GØyí‡¿ªµ¥Nï`f#oÂ.ÕMP6=Êº¶®¯ëæºuÍ‰Úy»y°ýfûíáÆ×™/Î¬dŽ4ÍÑwógF0+83‹¦âkLUZIÊø?æ÷i	ÏÿwÔ¾”6ñV*ÿ†eèÿ_µ«÷ß•¤{“ÿp  ì+òdÎGvÉÚ_ÉP®çyIâÄ¤ÀNÎ:ùW:MÅn’"Ï¨6•"Óønü“,Ù÷ßOÝ¨ÌÁ$&€£èÇ™8Å FŽÁ¼‚YÌÒ!psþÏ!	mÈºãˆF}"ZàÌ‡SÍA›‰­*tëÉsÖÓM²áÿ{i@­“ãI,vŠŸBanó] cÉÒAÜ¬=Í•föpŽaä_«¹›ûMýxãÙe'­i4inKSüÿV¡á{…Áç5K(]ž–¦*båpô>u¼p*¾~+¾¨¾¨™>Ð»X†JÎœÑÔ^	<b•ƒÇ7‡–¬\‰B7î`íW¤¿Õ¶(G|h¨‡Á8Ùlgíƒ3Š£ÞˆÆŸÂÉi“ÛTÖ6‚˜NŠ™¤ö« Ù¿Õ/Æ´€(Ðªê¢­lí5îXö×¨2Ýñ½™‡íÚögê1ü›ýÖb(öº»èÏ}­ñÂá¸¤,ò³ˆ8rñÃÁ§qŸz=]QjÐÌÈw&þÞ4Oã ¬Äß¼p…ÐýäëödNŠaÌ‚„üÆfŠú//zgÓa<`:¹ÉÔ|Qòü¿ <ò WïêôEJ‹ü¿h¶™ñò–mV÷+IÕût˜Ãýz©ˆwˆÂ6A<qö¬Èë16Ž}~º†¨V”Ed.c:Io#†Cq,ØÄK~žþYNàÖ”Y‰-ùR2eD= 2áÙàò¶>9´—°>‘‹p
lÕa6áÍBSáUêÿÇMhX¸!xï ƒ„Ó¡OFaì4QÔ_t&P7^‹`6QSí|}tˆ!_—´•ãÀ8ñ´zÜ„Y&Mt){4ž„ˆƒMÞæá	Í#gRˆ@Ÿ#ñ–þA:çÜYƒRËhÃáa—bç˜0¿n»»G›ïú‡{ov~Ù8ÜÙ{R/µFÑ@†1tÈÍ	+¸w°±¹»Ížê¹ƒGÃv„ƒýÌÄ‘õd+F8K­©¢´œñXèr˜ï¶d€y˜0î+JJmmnÌ C@™Œ„£tvÖÓ{ÆõüËq”BK=â±>J]K]™Îí_Ò™Vî2Sxó§wûÉ¸%¨âÂx1L^P^æbtfÌObëlàûCúÉ™Pô«7ð·ÍX[„÷÷rGsð~d&'°cYÑäM8[J4'› &ê9e$k^›¡ZÌ®µv8#z¸y<äíÄaq=°P‰`²2Á	%È¦@PàÌp1ÂqåiKÀñðZ*%ýÏÒþCuG}÷”çÿnN¢ñÛXÀÿ+ªÎùÍ6tK·˜þ¯Uñÿ+I¿n¿}½óvû·ÚÆp2PþZýž;Nê©M…ÿWûõõöÛíƒÍßjýíÍw;‡ÿ<z·´z»ô~gãèÍ?91ì¿ÛG½À.M°J÷—Êäÿ%Šþ,-Øÿ¶©¦ñÛRØþ7Ôjÿ¯"Uò^þÈ¢ÿfNû“ÑiàÜ‹éNÄÞäàµ‚ã¡¼Ääšw[é½pTz‰ „4ø_¡†øTã³úrK(n‡Ó˜¾ßbÎFç¢ûƒeÞà#ÓÝy[R#ïÓe»ÙXûÌkŸÌ÷½÷ÎpJ—ØY¡Ü²ßW{k§ÿxÒýø©E~-DŽø¬%%=ÿ¤_3¹éKöÅé¼´sgëYW@9EÊŠl¦êòå:-ÜbS¯X óÏå(©ìIiY©Àp>04!ÌJ†nÖåBœâ§ó1™€Ã¾'B`ZÀCv"k¦ÙlwÞÎï–›AÆ›{o_]wBøJ¼¾Þ¥Ë‚­ƒtyÓÛƒ/â" jPJ°ý3óð6 /8 vÁ&“\é„Dcz	4ÁËöYŸœG0ñbPÙ\¦u)ïÍ¶æ••SòÏ—½5ögƒQx8PFkK%„"v¸3-2Šîx'ì6)¹Ô©aî /ô²	<ÚÝé~©â‡5~Ó€ÕŸzõ&‘v¨¸JºgâvðÙ ^óÃ­ñJ¸ë×<¿9†ïüµ´ÐIRHÚÎÙ×!ûZ—©@]úÚ„Ì–À~åJáš-¹¹R¸£fKA.”J‹NÊUèõ`8·PºO¤ÒÞÕ¥ù&ÌÊ)ÉM[‘ì³ãÎöbÑAiÑ\!iêR”ÎÚñ¸·vLc1>ÐqxÂsùUéÞ‹%ßàê*žÐá8É‚©ÚÝ2´»go“a·9Cò;“ÓBÍÞ~ðIó;Ø&^8'=g‡ir0nú}ÂãIšñ¬2hÑP:ñì;èLŒÞ#àéÒ2¶¤„#˜ØÜçu¬f*W#ƒp2U§7«Nñ­[ª>¡ã›¢¤dP¢›ÁàvôMàçƒ°·v>È!ŒØqÓ©‚ŸÓ1G‹iŠÓbtæ´·vÆŒø]32K©£FU¨ˆSŠÉÂƒÍ0f(s*÷$šž}ÝÎ “«éÙ™3¹HºåG°O¥0_enüha/ÊbîdAu¸?î²p:Ï,i?ùŸ¯ŽåÁäü¿^5œµå©p<Ú«èÂýÏÄAYN9o‰m,ºÿ…Ü™û_Õ¬îV‘#ôV›øÖ¼WxÁäø 
Ô%<:æê^â¡àk÷¾JwMåú_L0ZÚ5ð‚ý¯IñÑðõÿu½Úÿ+IÕýoQÿ+ÃýÇxÌ»_Ý_ªÛà¥ß_ëvñkÜžò”Ä„\?¼^ KüÝdzìÖâ?9’„
Ù½ê˜Ïœÿ v/ûŒYÄÿš^àÿ*þçŠÒSFòù‘ÂÎ®5ITÒÍì¬Äšø°»µ±O02fêRf?Í5D.ó™˜æš"W
–œ~³HW²c¸é1–^'{;øÏV{›$vqµ§7Ý¤†7F~èÒIWÕÛ®
×5 uÛø	p­(«4³ÿ›G[Û¯6Þí­Œÿ7ÌÌþ×´™ÿ/KÕªý¿ŠTñÿÿ_ÀýÊÿÏ± )g×oaR”þ”!VþÛcÌ¿;ÍûJ3çöpi.@œÿºÅÿV ùÛÒ+þ%©òÿÁþ´¿òð¿ƒ[ø ¹¡0ïÈ¤èD>Ák«pü‘Îl‰«õ{º­Ý¿Ó²µ¾_¿åØU»××héÞ?®ý–@æÂ®øÍw°Ìˆ|•s?Þ?$æ¶··¿ýv«”šCöêlƒ¡dëwÿTm‚¬s¤ZZ«ž÷’¿%MîŠ¹g†¬è¿¦è–ìdnp\¬r r¨ã_«Ò„rœOª/Ï¹Èó."ù¤fàxp„|y3–Âc,ºÿQí¢ýŸ­*•ÿ÷•¤§äÙŽß%Ï–Gxzt×Ai·‹—B¹ý°Ü+¡g»À!o² ˆ _…ã(À¼HŽ}”‹$x±K™T–ü±¥¼9cðF(A|‘»ô/rÓA±X·ÇáDt·æÃ"ù^(>FL_‡áä¸æ{]’fÖ¤ß€‹“cg”ø«È}c‹CôF=v"Gëe°=(Á?ÏV/´ä7ÃQ¤÷igÿ\Èüó mâW¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©JßPúÿÆÌ¨ ˜ 