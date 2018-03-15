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
‹  5ªZ ì½ëzI–(Ú;Ÿ"Z¸‹‘%ËªÚô[€»}ÛÀÔ)ªÝi)ee!ej2%7x¾óã¼Äù·¿ó(ûQö“œu‹[fJ6`ªª{ðô¶±â¶bÝ×ŠÓ8iýîÿ¬®®~ûà¢ò¿«këü¯ü¨öýµíõo¬·¿U«íöƒoW§|é‰áÏ,Ÿ†L%O£…í Ù`°à{Y‡ù÷ŸäçÎ?õO`yÓYÞÌ‡_`ŒÅç¿öðÛûßÒù¯­­µ®¯Áù¯ß_{ø;µúæRúù~þwþÐB8óapG­ÜÞ@[Úîo¨¥[{œÅça?ÎUçyC=åqå¹ÚŠÎ£Q:GÉTýQÍ&“4›ªå§[GuèsFgQÅù4ó<Rkj¨ïÚÖÔóQ8žf³³³†:ºˆ§ÿˆ²Q˜ôo}Ò{á8jòÏ†ò.|Ù™M‡i&_M£A˜¨ýh˜bµœFy]åôY3¥Ïþ}*Ðì¥cèÝíÇSÓ{i'Ì§›Ã09‹úO/yû·Â©Ûm€_p“Ãè<Îã4)5Ñ_p³ƒY6Ióˆ!=œQG½,žLÕ4Ugü3ŒTœÀÒ’^¤x…*ÌUMg‰ê¥ýw"F¹žÍñÎ1gðÛ8Œ“Ñ¥šåQ_ÒLEÉyœ¥	*Î0MÕñ«­¾¢yàXa46œN'ùF«u-g§¸;-Þ±I 8¿÷¢D/áùÁÎÊýæê¿Ýúqï¦ýxG}þÌ£HÁ¬`#x7,Îì’EßŒÒ3Zñ8Ípá×q8Å–ð¿EÞšMúp`ù­OvEmLÇñ?xÈÏ½£{·ÿrëäpÿødkïñÒ{ç¯•`Ðôoa3ÍÎjW4nÒWéàæ¸-¸.³ÑT½
G³(ÿŒ¯º‡GÛû{ÛÍÕ`k¿spÐÝÛz\;>|Ù­©þÜ4OGŸq¿„“I4`?Ý?ê>®=ëì}¼ó(;…Û8ëhópûàød¯³Û}¼´ŒÈž ÉQK«õàx÷àdkû°»y¼øÃãZk:žÔèÃgÛ;0úÒ{¯ÁUËïÞ\ZªGÇÃã“ÝÎV÷ðqþBJÂQÃ±-½wF¿RË¯¢Œ°|é½lßU1}é^-Øílït¶¶»GGáZþ{š…p7›½aÐ=<Ü?|¼¸ñù'ÉàžÍ’"Õç ƒ»ÝÛ7y©—yx-×Õû"™ÝŠóÉ(¼ä·<:¢“ÁBBjúh+ÝÍÏTm{ïÙ¾ÚàÅCþqexž©•X}·{{pbo³ûD­l©ïA¢èoíÁï?óïpÛ/Ò¬ÿÿ‰ú©j¥V†UÈNƒ«å)ò‰1ðyøkN÷óªî7eN÷¬ª{oõÞ]Î¢É(î]šÀY·ýÑè{Žè»¡zÉã­8‹zDûwÃV“ÍW¹uOá5‘ˆ–Ìé]:üOÔ¶pçª~;é‘'àõïwöŸ#u¸âvñ@ý¶¯ÔÊÙT­ªŸ!«O½ÌÍQ&¤ÿ3`eÔnéýÚ}€íêvŠWÝUÑçƒ8¸
n×U^­]F,¦QÓxL²Ëxò¥®:íúr=xOëÜÞ;xyL²ýÍÆ½«*$¤{Ã·‘!7»„Ëœ©ÓþéóÞö€^Ã–¨+ª! 2‚¬¬B•€ä¬“ˆoCs3gRƒ?T­®Ôñön÷ðh÷ J ªöoßü°òÍxå›þÉ7/6¾ÙÝøæ¨VôÈézx8¿krMgâ.ÐûÆÝÿ+Žê[«¹îñ÷^ƒfÅîåaÏÞ€14Äà«šz¬D(^ÝT‹‹ÚÒ½aŠííœ ðÕÔ‡)Ž+¡sMOï^-cšÁ•Ò¿æÃx05]ñÞÓ¬qØ?À|i®ýÔâcWf§UøðÚÕU®p18¯©³Òòjûi•iÓ-Û“'Ukúí~õ$o¾y_‚>é2ŠT‘tS5›  Ê½‹§_@8ºŽñUO²{B’ÛHŽMóÕºá¹H]Ó–¤g—\µæ@Q¡y–©6AŠ!ÐMõ´ã3ŽÓYB’x˜ÍP[Î›ê.×ŒØ’÷^š¡ÜêdÔt‡X»é°ZFÖ^¿)ü×Âw¥ Å@ÒOÒ)jŽìŒTÈãÎÓ+CÁ‡Í®‘nNžvŽ
}í¨ÔÆÉ£)ö>ÏÃx„Ò£·žvû:È›élÔ'ÓtÖ²Æ‡ëò¶ý#ÀŒÒ°¯Þ,½±èÑjêIºàî_»Þ£¸}—•ó,,ê»ý×¯íßÍ2Ø!œNŸ¤¿ûµ«áîtºÙ,IP~óP/ÃÄ·ö	àú¹#¢;P …¼~äYò6I/Õ7búôrÂç×€;Ð°ZÀð&~ÿ:ð»qž“ðVäÝKsô-\œ—ì…êˆ–$SÝ°e£H66–;HT_¥rÍ­óðùÁîò¡sLH9
Kñ†€ÙÑV»G‹V”9$ UèÞ‚¿ZÐ>¯4­yó¿öäxþ ðh°+ÉS¹ÕzŸ¹pÁþéOõ‚Žõ—Y>Ua’„*ÍcŽF©G`þ|-Á|)(J3š#©®`cmâ¹*±-N‡Ñ8=… BU€©•éjÅªlì\{ÒêGç­d6™&wà T:ëëûm¡ögÚ‰á¥YØƒžÎÎ\èh—BCí
÷¼×Ä“®Æmë`FuaÇÈJhÿ18î?»››—¶“x‡£Ï· 4FyÃ‹àN2€ƒ…‹ŠªjvhaP7caÐØ¬È;JÑ¬jU’=E}­m4õATÖÌ6Ó'>ºêÃøæj¥_øÚ 7j{FÃ±vpSz8^‚ ©(p÷{á¨%>NhÖÌ‡E£Ž ÷Ž èÇb	D6F)üª)Œcõb »ŽX˜ï[áÚÃI–(ÿ7ô¿PžTü#Ò…ª96oñ«s`ÎÃß•¶; £ë÷HP&ñ˜·qÿV–Áí†ñgùÜŸfáDÕ¼…­¯ÖÐ6B³`×[4Ð'ÞP˜ÈvÁß¹‚3R½H©	¹'ŒŸª&ûÂ²,Þ¶³hšN iýþ“,ÅË‡Ü[¤‹îð$Ì ¦hÇc=Nz«áy¼±µñóFw#CéÙ¨s¬À'®b0¬‹¥sÕaçõ‚~á|×Õî¥‹Èˆ¦û°5Ï=Æ¼…íØ.9§ÅÏº…kjœÓ6««ÃîÁÎöfç"¥Yuë>VVCù³^ìšZºç²/Ò-­ð×‡£Dá
[P¸Úr°(Ý»BÆMh„Xh„z¢Ì=†;ýÇv€Øk±ôgiHò“Š1ƒÌ‘¥cÅ0Iß›öUú¤·sTi°-IÓ—jf¼€ÀX®¾àžô9ÂÀâcg3ŸúÈ6_ÓÉñÐ–jgõ{JÛ°‡ÓxpY–Ê˜c9lè"‚C9Ç™1\ðG®n6ÿº±R«´Ò_9¼›¢»º¥÷¯·dÛ®,;þƒ0ärŸ«2Sö	áý2JûEÞ[>ÈÃY¢…0 ð1»x¹¨¿´^YaüÊ ‹#ÀèKø$IW€ Ž'Súý K'Q6£gñÞÙ…míÁrøcwªráÐpš\ÜkõÄGk¸c81ïžÉW\6\#¯Á5Þ,¼tåmn{]´€#ƒ†ýŸQ€··Cl#ìÃÿ?9=¼´© <­ÄênÞúÛRk¥u×½*Òûç8èÓ°÷ú¨í-öCŒg£i<A·1¸x Zû$@ƒæ6ÞMQ¹Yj½ß{”·Þ$-Õztµ`à=pN×ð7i¹á ®ü)VˆÌ9=a}WwD>Š²sÐ=kŠg¸|r>Ì¬§î–š‰:ê{ó¨kúW8kP¼yT[A}R¼Z”HÑÓÔ¦gUé¡¨Ò!Ú&Y…æ^¨£¼³Õ9 ÿy†^ç˜ŽU€]z;ªYçõ_OöÑ‰´^¼UwŸvŸoï½?<z\{“¬¼=÷ýZ{´ý|oè%°½ÇíG¬?>~€Îº¶úoÕú[§ßÏàœZÈ2–Öð£7ßßÅ‘î¾yÒRïaËK÷ùã./	>¯œÕGê
ýGïIÓ¢Ï|ÌPu3_ï:ë+n+œàƒv¥mûfÇX>Ê6í\Ñ$Ïr‡™P1GÊYèêy\;,:†¿žâ¯tŠŽÂÜH. ]Bæpó“A>Ï"ÔÅ7(~#%¤ªê-#%íÒÁ>h8­Ýí=—7Îe³a'7à³ÕÌuîYÎå±ÞÒ}%»ýŒ“__+3gÁ K»;Çr
ƒ|p®Þ¥Ú#Aú+Õò‚Ô®ô=ùVýá¿ážì¡Ép„×Gß“k•åÓ.ÇZåù(¿V‰òðO4Z,Tí.ö?R²~y¸ó¸†a–­ÖÒò0Í§h	©oÂ¢þ”[U‘%›ŽÁÝTE3*À•„¥f³Ä‘æø>³ö<Ëà"äGéEh¬¬ú£4SNèÌâ 1r:™‘”„d,
•-‹•ƒÂþÙÜ—¹Ø#©R’Ö×Ë»JJ‘üb,4·aQY¹6þ[ÇÿsÜæ¯ÿÿðÛ5Žÿ_¿¿¶öð[Šÿ¿ßþÿÿKü|ÿÿ•âÿÍ…ûW‰ÿ—Èïh°öÉº¢Rþ5ôÿ_<ô_Ýr$¿ú…òßjÿGñÿ¢ø·€¯~Óø¿`¸}E°?âÂgDà—"½ž¨•±úÞ9bøèæ÷ŸnóXûòœw€(Šb`sùœÞ¥å™Þ»a<Rbÿ˜Û}K}ÿt{oË‰Ó§¨zP«ï!ó-³³å>ãuì~}~ðþÁë-Ô:õ n¬Ï5#½YÒ®ƒyðêûî¢ÎuÐ9~ACØ©làÇÈe"g€ÜT™?•ãüVÒ´ZuÅ„äïão*@}Møš ¾¦|MøçMøÂúúŸ›pÆ÷5àø_Ãò?2,ÿ–âÉ¯{ßÔ‘íY„œÕzŠ;´þà:P[^_}‘ÅÓè·ýåÕÿäH`Míàý’qÀ
cðº{¯@&à°Äb…L'&¦¯>?b˜ 0œD«ÿáÀêvãÍ%¸µ`€8/îW}‘˜ÝñF¼Ñ¥¸ÝÁÆ/¶{4'Òv3ÝÒ²–/uÛ¨æç­7ÖÕ:«±ß¶euN‡sZÝFà/è‘K…1ÍLÓJûQB”&QŒîÁÇEtº”
‡|9ûQ•rB¢%`pA“ù1œ|‡¯‹ôœKÖ*Ã<éª
í,àOµB7rljÆc¢’§ái¥Í§Ð±`ŒsI÷xSˆ C+s’;Zœý 4×E
	'¥•9“a­+wž>.SÑvãdgû£>8Tð\ÝýÛ»6qôCo6…‰·ÁlÔËÜLváuçpÃ|!'O{B{÷¦bésà<ñå4ôô}Ã\m«sÜ¹jÝÃÌ4Ûk–HŒº]ˆ½:`p^ÎÁ*i‡7Ü{ï;t­y@ü­­	ZŠ‰ö`@kóÞ›Ö›eøoýÎ¢yo©õ¦Ýº[w¢ ýÐìx91Ã³ûìl(:Ë£EX-=(ž5(ÏßÒÐÂ"ÛC¦î6î*ø¿ºfŒ’Ë–DÄ4â¤pB•Ðm¤(}|E€ß$¹|C<wj,À:ÒÜ¹4æz;i:Q)FÁúVì®eìo²¦ÞIæHBø•/-p:¢ ahŠ0°Ie[°Ö÷7ÔâOFçÈÓYÖ‹<‡ï€²{uSÔ“ÞÆ õÃUšMÄnçN¬—&Ó8™ŒÓáDèÇ8Ù¹ÿá&)	Õ7Ü]
´‡ÀÊ +EUáY¼”æõká¬†|ÃÀ!Ÿ¡ì™ÛôÙ–0ÇËÈ$m#!râ'§4È|>’:»þ2!dVþ=óNÏÖ;$8MâñK¹@*”2¶uÝ3ÿrÓ¿ýM’“^ÌÅ—Š©ø¤f:³	"ÃDõá
•˜„è•H=©Í$‡Ù¸"TÁÕc ûÓ™[€tÚ~{æîBz[4ø6TW§s¡U)ÇoŠZ™¨Rû"éA…±_Wèä˜Çõ\.n<úƒÐÞñÎôµ²e¸šÀ]ðÀÚ­)•	5¨–ZÍ,w²yâLR<5à'è
r`»ç8=±žç)ç¤pþ¼ù®æ¬ÕmåÉ,ò!\ Õ/dGËÈ»Wtë’Ó\=;LÓ)‹hýÓkÈ8qîþøãÆé(LÞnüôÓÝzIÌ`–ûúÃ^¹0ë^Ï8éfýèiZh«Þ'ê×X»ÛzSk¼©µJ ZwÏl‹üU÷½ó÷>§¸G,°äA¦³½e§vuS°E4,â…KwðGosw·ƒ1Ìlï]µÔÊ¨÷jeEG+J¦Ä¿nÊ~£Ô°ªc0´»ÕØ§"€Š‡'ë^ëd+¼‡âÝûfv·ÞDH7ÝRP¼M*œáÐJ¤jo’rKõ¤âf:?¥ü0~ü©Œ<_¼”wp£-Ê`tx½ß´€á6ƒ€¡s"AÙµd&MiÜÕ9ÎàÒW÷¦—EìììÝ¤Œø®•Æ¬Zç‡1 y§Vr-Ùv2:·˜IQÜÚt®JÉ&Éá-/Ó/ÿÖ®û„«Ò:ÿlo¾/ù¬‡Æ²pØK Iœ£þ\?jµ×ô£¥~z‘4@LÕ‹¿@±öÉ(Ã@È¨ß4Ž411ÂÌCArL¨ŒV(.HÊð‰3Ð)~¾²¾ºêKKGKS—8×‚{®x¢ÕÆØUßÔz;vÑëCûoô£ãÿY!ù5âÿï¯®=\µñÿëÿ¿vÿÛ¯ñÿ¿ÄÏ×øÿ_)þß\¸•ø1i|ÿÿÿÿÛŽÿ_m¶ÿiKùÿ¢Y h	…½ÜÙ¹ñ‚xQúÌž2I8Fkë_»ÝƒÇëG€íÍÆ§Q†Ë{Eos$5o£hÀŸ` ÷ãÚÊŠþýód{ší¢žÂ³¯	ÿÔ	Sõ=âê¿Pêƒ‰ÕWyY fÙæÇ¹p
ï-Ú…·÷6»»Ý½ãÎŽ…Š_ÎûV}ÿºÛýë‘…k¯à…{U:êÛw&¼>îgæmÔ÷O;›}yp£œ‡â´tÎƒøšóðÛÈyøúÂ×œãkÎÃ×œ‡¯9D#397Iyøšôð5éáÓ’DT­Hzøš¬ð5Yák²Â×d…/œ¬pÛ©
¿p¢ÂtãíF¼1Þlt¿D¢Â”2ÿUò¿­+²çUûK$9PZó_(-!Tã8‰Çáˆs$ž›€v‡¶ŠÎšð_4è"×øÝU¡*=mZûk8ÿ×pþ¯áüÿºáüNp÷MÂù%\TzQhº–<¸ô&’ÇŠ[–À”ÂzBœ?vë5ªéñFœs´]ÏF©z ­½*!ão°×}}‚fá½}Çõ²Vöw¶ì Ù†W+Bëuê.¶×£. zƒB'åõRß †E1ø	°‡XÔÙN¡¢³H[¥5ã1ÑBýI„¹|`¾ºúÁmÏ²3qcdw†Ù_Ò¯ŸØQ(£ê¨þ_;¾tbG‰„~MX˜—°`Ý7”°`@“°`[èw7\Lù¸tÖMÒœö7OWp:9–íRºÂµs©NW¨‚~mº‚ ±r0m+3œ>>C¡,\Ú»Œw(„Ùõ±ÐxÔwÈ¬U æî«D¼?éDÊ`n”;Áñû-°·ÿz]b7óžpNeaô¾L¸*r_ÀÓAAH@½–®ðÜ`/n2ë¥÷þ\œN^p|±U9kÅu/õ¸68ÞŒw0OL‘Hƒ6ÓdŸUÐ†k¥Wèi—	ú¦=@µrðÞùà&ÜrSx„æôìL"7÷÷žÍÙLgÈÊ4ƒâVºíç7¯Þ2ý¦šÆËyo*TíY±ëío¾þÉ[æ˜Ü`aj…÷ þëìàâ\+œË>?ãÚTçÄ$Cà1nž„1_JzZIí>"×âFy2Ê'çY\ŸcQò¹Î?«Ê%ÏK£(èóÙ4Å8Ï^ÍHa³¹›c\M„ò#ÈÑda¢¨›²#t‘.¨×åÒT¬K„µá=$ÒÝd,­4zO9¥&«•¬ú2 ú‡÷q©/{©»„A:ƒû¿Œ†ºò¼Ë“®Ïõ¦ëeçœ>&ïEf÷5ïåf?¿v¾Ä¿Ú÷îåcqþÏÃõ÷rþÏZ{µý ­VÛ÷××Ö¿æÿü?_ó~ü¾pÿä¹?lß£¤k¾ÕfŸ‚½ïkÐo;H’ìF¿
³£_>-ù¡qÉ2çsEñ4ÏÍ å25ÍÛŽ©©ÿÅ>yvÌ»e:ÓÍ‰¨E¡áo4x2`ÕÐÂpôâähÿåáf÷ÇÕŸ®jõšz¤&}PFáW¸»§y:šM#6q‚ìËˆ°o¥¸zSùcÀò=Ž’[Ýg—;ødÝ—I ? 'ÿÔèa¿š×F¤V§K~+Ï©(íß¯Óôh÷dk„9oÜ~ŠÑoJÙfgÇmEÅæ¶y
 e‚Å58­Ð÷Ê­¢ion+Ôõ˜gs[wwv:ÇÝ#i‹¯ôŽðÂØ‡û[/7ÝUL²´?ëM¨ì—Å¨"i2_´×škÍvhE©á³Ý×³¥æ°KæšíçkLüOzpÏ›hÒ©E€8¹ÇFâäüô¢'q5ÿk}WW.R:ã(&Ðô»¾&þ4œ¿6Vœh§«5¯XšÓS`=¶`iˆymiaÝ«k6¦¦ßG¾„¨†'¡ýp\¯Ä1÷ió€4•‰Øci$¦M¯™Æ–óy«žNˆŒéÑÌBäv%P:ØR0õ7¯m.OÞ‹IWÇ<d@1öÍ—Ÿ„îc<ÃcÚÀ^ç8jWøqœ÷®ÞÀšÍÒ3i?0þŽ ð·¶@qTc|ìY®…[¤ÀÑ|ì[•®^&¹>xŸÐ2xÿ³Eà+È´ún1¸¶ê<,U³·ÿ*±3p‰\z³*ÐIw¹>e´êO>wPæ:ÿ¥óª£‡4¿ä`?‡ç!o-RŽ‚oY÷óÝÊÉ¥¬'Qø®èƒ¦éTÃÁ•hsÉ­HdÁ-‡ùN§—¥“ããÐ¥"«ç€‚Ç”ý£÷(0?1„Ñ»¨7£i´„TšŽ$hm¡UV~%»ìo<´˜ƒÄbVˆ4›ÓŸ"•²+»íÐcoNUÙoæ¤ðü²h:ËÕfbæh.jj"ª›™š/%´ jFbôà8³ê™Ý;Ez6²1­­©|t©Y§zb.(jHƒ8Ë§n¥øð÷E¬)‹z<Õa™‚Z™)ÿYr‡Vw^u·N8à1þã˜8íÁ¶UÙÈ.°„ßØ	?wÄT ³Aö™ê%ìÀà`Žñ#aqÄåÏˆ&©U-PG„ßPºÑÂ÷•CÇL~´„dö±z2Uœõ#çr;ÞØdŽ<Ë[.ótÃ5=ÁäJ•D+U!2à‡&¾T9Ñø&fË‰aˆ¯ØØ—N¢!„«‹w™Ëº&fÅø;Å{Ã_Ò3÷²ˆf³içhóDïéJ+!$”º™ß§á©™¢W¯ÕFËâ„Ët³§£1®Ã	_]»É‰Ñˆî†z.’ÀÉŽò˜&÷¦ƒ)¾•˜RWÐP¼º•-ÍªØPùÂ{\š¾&äìÎ±/¥áõˆùÜ×Æa/¦×’ç,-ùÞÜ0(Ý™ C´ûe‚ø>2¬ü3#ÅeTŠwµ*±O›ÇC'ÓK/Š®Å[–3x„)
©ˆ*^D´°í„]åUaiï´…3„É¥C“*Úèj·Æ^«¢yés¢ØO¯^/‚úÜhv3Ä ©kfçŽ1Óì3ìËŒüî”0ES5'@¡a\5¼ÐÅ„£{C9¨Máè²s‘oç`_E&Eï>çæáÛÇãÚ§âÙmãá—–2n=ûÀ•Ã|êŸ$ì3Ê EŠ5ÿîx¸Jµ¥ßéà$«±ÛÃ¿!
àáˆ'ø1`½·OÎqhµ=Sº¬°£Ã0µ˜ŠyíMÙ‰vÕò+&³`y(€Åï'Cºã«Ïh[v!¶iƒn71ò7]½Ê+ÀP	v_tOþŒ™Ù})mã)"êÀ¥™‚ˆ|Ûn4<£ŠH|&Ë[Û‡'òe-}ëUšŸ Àùµ°Ò“½)lW€Z¬È?\ººÒïŒþç?[þ§?Óî7¦šè³Ô†ŽEsÜ:êvo2K™aç—œÚL?bz²ïÆ£Û› +V Fð3Üµ•Ô¸dZÓÌ
zõGŒ‘ÔQøL÷4{£è„,¼Õ@¸Û€("»£Q“œ” ³çÏÃy—Ñ[ŠŒ¡<«Rhfe‡8Ýå%»ËõRO>+åõßçÅRoåhÍÒsÆ;bª!íyÈ«ÞÉ¢ÌÆ w¶:ê É³r¦‚,Eœšùm¥éÉÑÑN©y=ÀÕÍÉQêpMF±xy¤›îpØ=øˆ{ý‹¬ôFWØÕø›ÀœÒQ¤”;Ùhµ'ÿ‰ºk>.ÍñÅññòæ-›U6µËÑ¡¡·r·È|þy@¼ŸuÎ&e¶érLa­é@[$lë`œ¼cxôœe„wž¶˜o§Âmv6ß4Á[^+î¹7;µRþ¬ôgÕOÍW>ææ\âÏm.H‡‰“ýŒtØ´±wv¾­B?‰BÖ¢C$é+mçÅ‘õºîÓ­ù€ƒ?ØýºË)=××§‚|8äÇyÓ4”ÊIÜŽscBä™%<%*£ï«½j-Å1)†°W(ª¸. '}’ÅÉt î~³ò Wß¬´×ð¿é×uüoŽªbyEbŠ¾§ÞxÓ©--ÿœÆÉÉé¥jA#DŽ+ù‘ÄüNˆ|U¯¡På3iGõµ÷òKR3çDß«"I;Y+ æn¶tÍ¡t_€¨i"TÕtøŒ‡`O®Ç¼y¬xi™û-O@E‹êƒŠÌeãø–Ý…oü3Æú*ÍÎš)º–òfeçQÖ¤¨$Sëˆ>ü0§÷JÓuœ5^©º-WîDLœæ~w6¹ûˆ®‚üÙðÉ ®®€r»’ä+ù(œôsë®¦B·¶î‹QþëwÉ£ž´B#SÁ=ñn»«•„sã±_>IÙqêhV3Ò‹ùwÿcïôis—Ú>?ZÉ¨þ®bWÍH)t—þýMÁy`œl3G¹š›Xæ…™xZ¿óÞ425hk*Ã
Š?¾±ZÊPèH‚Å8ÐT£ÍßÑ;T âéè’Ì«N§r[¡L¨ógiE¹š_r%åÜ6šA)nÌGÍ›­¥ZW¯ÖÓ	ð¥ÿ‚›[nH<Xûøç :Ìøc†%š³ÄP*O´l¯*Úªô§ñ Çd%Qw[dA ³eãpáÙ4IHäh5Z[jMîêE¡Ÿ¯ôg+èmŠzZP´t†xúŒ¹4¦‚ã½ dèÛM4(oÄ£/<äa÷ ´H×üs›»úeé™ƒŒ7§g—é,ã«Ù¼	=»£)½SŒ¿ØŒ»ÊË9+”œCjÚ§T¤Ž.Š;Š(¥ëðãèŸN{i	mÚ÷¿ûSuF'£vaÛ‡÷ÎiKxð^ÿ
m¿û“÷ÓéöçQ´Š§0Ëfâ96âB¯¢Ù±d¤+´uíŽ•æU§}ÑÄ:Ç¾êô(ÚXKÖ/³‹¿oä³1g•ø#M×£q~}hy¹8D
¼¬2ð¨LÈæªDõ‰/zE<­SÜvÙ<­ˆ0ÇªÖ*tlõÞ¼)|Ä6êƒ§nÜÚXò·¥æ®ízyš‘1ì÷‹+áWá+Ù~·4ã'OæÍ¹Lµ¿°˜œ˜Gê+äÀ$Ê8‚Ä4â oy>¿ß‰’³éÍCíÕ«à÷Áïï¨1>t’Ï²¨U@„eéyŒ¨‡‰öëj!ë˜*
¢6|¿—»Ä#p)Úus~¯G^~MÃbM’ª¥Óipâi6‹<Ówþ˜ËÏPRÀ,N
ìûƒ¢×»{ªÖYù¿Â•¬®ü©bâ#–4³sú Øö›¨¶o‰Å‰ßÉñÑÈiþÇ?"æÄ·îý ºçC?‚¡á#õÓ‚÷+rOA¾}[ÄE²g~YÌ0Uød¼Pj¢s·Ü
·œ.«ÙV!®ó“ Õm¶`»{¯>/ËØ‚çåÑñþ.fQa'úyHã¾’´Â+ÛÉ§K¶“ÿy¡“‰Æu~;a¾Ÿßœb“+šãç…æžÀiî}~}l¶†?-óy¡½Žp/.C^hîæ¢ºÍÏ«{è°býùÊ]èv·ÜÏ[ÊcßQÉáx^çórßýc»øŸ/ªÐïdÑé””üª~KC­
?Å¹SÑ”{¹)^Õ¸lü¼ª9ˆ•Íás¯¹KEôKQêá'Ñ;©)Ì¥úJ'`„X‰Žó.Ä.-Z Ha‘
ÉÈx³ä lK2ã5l’5.úfuÏçJjÙ•KêˆÔ±ð9¥LÙh˜œvqa^³­ k LT	 Î×v…Ognoz¶Ï‹ S®LÜ ‰%ÈªÆjæAb6'?úõ¹;c>ç€ú rÀãƒ°1EwŸí.o¢VM«Š˜T*¶tÖ¹EDV0òRêE!±¦*±—_Èý<äEˆ,—‘Mn%£bé$ŸÝÁï¶e)ä˜j’ŠM#ÄAndT0¿¨ˆPÔ–$(U¡:;Ûójµ§¸h˜…„FçËÍ{õÇËwkðjõæ=
ŽVVÒÃŠ‰”,:Æò„±ôa™¡ÔL}©õf­u·Ê{ùmc…ÜGÖ"žr8þo@Èßx­ÂgµôžUôŠãOÍ€¿ò‚}P2d¿ÊB,ðœá_T³Ñþû²3ü/ð
³Ð=Q­×/áöæš
ÛÏðÕví?žöHÛ÷à“/¸ø(Æ9ÎµìCƒpŸÛš- ñµÙè¿­}ý@ªb\êÚTf0#çã5' KÏ¸æZê<«ª×y’ÞÃäÖ G£(3šŒ_¯½é¦{³	:ÝÒ”6Óñ8M€˜=^ò—|‡T£$½ v‡QÂÁãZÍùÜ!˜?V­ëÎ’….k¬ZûO?¢¿’TöioØPã(LrVÚ{ÀAb2—õ(&#˜ÊñòZœã,ÅWþ˜Œ°”™ZÎ¢þ¬çuvHžÝ§d‘3{'Ëé±2ÅšÙEÿK¸@uƒ9‚~½®Å…bÑÐ¡û3?Xù‡Zâ-­Ö¥õv7›‚l£– +Y79ÒŽë¬‰Î£U+‡ô@u(O;Ka“—á\ÌöM‡vûô<d-CÐ£…¶	6¨E}Êi%ì4‡Ò>XKkAá×Iš¬8M¨Å³4»³¾œÙbÌÓóÀƒÃ)äÓ‹×F`†¾C¹-r>‰s>ôÎŸ9Ã–7®°nc7 åÐ»2ÍB•°2e;…£ò8ï mŸ‘
ƒÐxqÛ/ÞÝòk_îmÚzÃ´WýA<Žô_³(Ç
÷^bSôÄì\Ò’uêë­«9‡,‰.<ù{ÞcNûRvüäèøð&ÁÞt˜gÝWJq|ïråÄ„¶ý˜Õë;T¹^Óé~¡“ö__Ó­™+¾Ùk:=X8{M×[-`"¦Çlq¢âµ‹š7÷Ü`a ì<á§Ì-¸º;à9ùÉŸ¼”ŠÐ›"È…´zß¯SQ0pEŽB,çUs¿ßšéµ ÑHçw:Ó4S¤yKËZ¬-ùA@Õ±iµz^°yNóùúy®óâç>&9\Ð©¹³øL[•ø~Ç+àP¶÷Â_Q`>TÕ(+øm áÊ÷XåÓÌÚ‡Ê3¼mÌ*¹}-€ÊDºÂJÎLtßpÝ7¼@÷k½Äß‹d|îW½Uk¼®jÂ!.Xx1­Á†ÆÂÊÈ‚!EÜQ*|EöýÉh-íTqŸ÷THÛë#TvÊ«¡Ìc>~Õ!T#1£ÛnIQ§“µ}´4d’öoáZþvîÖ¯~5n‘Zÿ*Xûå5C¸ñ‡ÝÎ±yéã W¤Î„‘”¨`¯CÁKOŠùØqe”ák= ( A<l5…¢æ*æ»A§/àÓúb-ÞOêˆ¥~KuŒïi¹èQ³€(Úþ~ã-f¼U ?tý4½ño”KÍŸôc|É@/2µÏ…n³«³¹?ign’ô­>yg~Ýs¿®R+®ì†@ýÒ‚¨ÞcåÁàct´RÃkº™bÓsƒÏOãdÃ_Ó†[:R¾×?N·»õ	ßÞdËk¿úîbåT«v+ß‘K[û³ˆêQZ•VOÝ"¥ÅÖ¤…Å«Ýv4w.År…Ÿ3›¬ë&UlnÊ¢Ù_¹àIæÓÙ``k
RÁù»)¯cT¿€‚QÈ^à¹åü®ÙÒr;§nPu/™êÜþ>1a
´=w«ô™=ðížUœ¿(ÿbdDsúnZ}?^oñc£®T8Ée—¬ãjìý|~åøŽ_]ëw>zÇÑoæÎáfH<·¹>M;ƒïÝM{rãiÌ°O¦²“Ýò¥÷XAúŠ,Ô«Ž°Æ°*ËuJÍ{^ºH‚ç>HÀl@‰[IëVd€à×~ÝéúŸ~Úk}é1¿ÿÅïeÑû_ë÷×Ö×WÕj»ýàÁýß©_zbøó?üý/<ÿíÍîÞQ÷‹A¼­Ï9ÿöêúƒöýÂù¯=xøõý·_äGUü<ß{©žw÷º‡uðò) ‡)EÉÏ+‰™»ßPkR™%‘ZƒÃ8&—Y|6œªåÍ:}¨žeQ¤ŽÒÁôV?Ãg9)•ª„º×TßK	§A>h¦ÙYëI ºçQv‰‘qŽdŽã)Ú§èÜŸ\’üÔÇ\ÒøýïÐöà¡¼8ÁÞ·	=Güð—”Ÿ!·h(hÏ!~y›ØŒp4J/¢~3˜·\ú9È¢pB¶:‰v;Gê`v
£é§Æn²b5hÆ£ˆŠRówÀ²‚\o.…J×«·qÒ§HFºÞæM=ˆôÊå©0|n¶Üw‚ X-Ÿ;S]ð~”ÇgX¯¿Áì’ð"¼äJœ&m :Ô8ò‘d?žRO/ÑbˆèMÁôÚÇÉ4Jú|Ng³0áï¨8bPƒ$“Öb–³,¯¬LS›£è15z¥ŠÀÙ=¤gãZg9@‚©¿¦DšhêÍ¸ˆz°`MfËS¬™„s	'“QŒÂ<–‡uaaf>Ü>Œ{ŠHV&LÄ­?½¤†ôüÎñ‡t†!C	¿C(´[²þ–¦„	¯Ñ…aÔKø§ƒ;`æÓÀ¯p}¾GQÅX­˜÷ßœ“,Æ¼Zµà«Wëcò¶žbˆ`jEÆà¾:(äÜD¾€¥ù©e9n|óÑ ŒQøê"Î‡õ†Ã–"ŒÖÑµ—ö#z*"¤4~º´Ô1¸1ÜwêtÅ6›á¡;ž6Ì­Ç³C 	Iš§ÝoŽjpo1GÃíSÌ,á–åû™b×)FQÑ¹ÙËé4’ˆ÷p’Eçg˜!–xP.ñŒp“;â<Ãü­|E·“çü4´nÕ$º 'âÁcC<” eÓâí°ˆAŸÆ£xóc{Ø¨ò”Ü]jàðñ 1¾%7Êð`Zø.ÚE¼"´FÚ™gøöß»p<ÜE3Èg½¡½ñ°uCs:Ã:´#t»Õ ’ÅŽ1;
•STBå]/@™ &ÓœWŽ£@æ•—«/7 PU K×Ð­õx·Vœ ‹™T>t!ÌD¾•«œ¦x2Áo±FÚ'yÃQƒ& D‰	íÁNzqôÞô"ÅwB'ùF°Ü®+|â4›¯aÞ‹›ã.böòZöHã&¹üÁY|®ñnq ®›¶ÛpOÀµˆ:
¢˜SçªÒzUwÙÖÁ$ï®^Ñ_Z&,±t2ú‡¹þHÜ}YÄìˆg†¼ä’PfíQ—&|
èÇäŸÌ 9œ±½qÉ~åÑNË€N#@Šì-“$ Á§ÈÓŠ‰>ƒ0Îùoy¾&œÊÞôÉý•Dé,]gà™ º#9ˆá3íÛ½àßô*¨0R^—
éyüP*÷àýÈfIP^Fárc‡¸O¸—,á»ªgCj2“Ù Ä¸Y ”.O‰Ê O‡ÍFž‰â>Æ€0ì.'ZƒH#ôù&ÉI8|¢‚23-Sù% 2½÷ d¸7‰%§x%Ò^o–‘Û9Œ7“ÞqdÑ¤'@áþØ1î9ôBb÷(òx‚"`úŒWüô,²öY‚»:™¢uË'­³;{¸!:YD6QŠÈ|:)¦3–Æ"Á×®—žj“24he‰Â_-Êg§h³ÀbÞ´Ë"KÈ»œ4ü¾OyTã?z‡âÏ
€É3³DSzYVPƒž®AŽÀÎ½%Ó‘WinÅä¦@ØY¨¢'8¿†ŠP@×d7s:$'îÈŒ´”É<'ø5Ò=¬ÆQÂ6M’ü­‡ÛÔ›jRB¶\=aÃÀÊ~œ×âÌÊ„ƒÿuXn–³¸OH“æBáû)±g:èjž§1Ç÷êxâ>"iÆõ„XÔ£b©Þ,œ°
ˆ‹ YhkSF´5 sE j^6ER`I ÏË’# Ü3M=ÜB!*ô,2í‡‘ôÐqŒs1š‚ ¹ð’¸°šÇÑèµ­	Ê—¬'¡æ¥H<ùºÐq÷p÷Huö¶°òÐÖöñöþÞ6^mb~^œðˆÔ¿vìð˜‹§t¾úÝ7÷h®Î€ŒVYc›£î¿[ÅoñQ„¡ë,RÃ@¾nfÓÒ(cÜ¤:€æoÍ¼#P÷h£Ýi£ŒoÆ${8Éú¢£vÊ)Åy g¯T7„Á¤	k†ý>yÎïÔ€åÖ UM:DyŽ¤f…šÌì±Á¥q0_Ð•ÃD*ÿ´Æ,€ðÜ$=A4gXªNèÚá”¥ ç€}ÌRƒ0r~2L$éVº°ÂACv˜Š0;!õ¸$ °ÇR‰PúŒB½±M.Î9	vB&î0±šÌ)@ù ÖzIƒô[Mû"j4°ÛŠ6££j½`Aü¬&[Å2a¸]‰SÛOÐ‘£äk³Éx»Ã3Š£(îsŸÐ„´æÄÂiC?g¸»wA4ËÈèèÔ…yä¢&pøsÄÞÔâd€§AÉ\‚pDŸzÔÂž\ Óï·égòØæw>ÐDR!¿EA<>ç:³Y'"pþÑ˜¡¡#GG–i± N¿ÚîPð1ÌËƒ"¼ºí, âÑ#^ô„dF*òÓsV?àÊ\D£‘9	Ø£ó¨ˆîxOñÎ‹”`–@´!JØG D~QkèP¢”µØ…]’Ø®sÎ8¥’ø"2>”¥‚Ð0`¨SœLC—“RS_ó?‡Š0mÒ‚pþø€álbÇ9x ú $´H… ¢Ñ™0Á£Ú!y}/E‘#¯¢‘tÀ˜Çê®^È#&±æ¨ ]$v2¸ÀÊR„ú…™Ífl‹n	oôŒ`
‡Äê˜ìÒb¡^(é² ¬à†»é‹ˆLˆ-Út 	lNÄ’w•`\K˜5[á™’ÊìC0ù`ŒñÐðíAÀÁñú&øÄ$	æ94Z$& …Äià¤'D–-¯	¸±³+»¼ãp0hI$õÑ("%	cßf ƒ£ÝTâýÚDÕSóüš£ÖDUvÉ‹hÂlfL¬vé<Ù·øZº—•5Œ)2¥ýÓŸ#¢àÞÞ-”=ä)W4ôïŠªaÖWÛzÓlwg#ù>2AŽé;POc”ÃXØEúQ.%CÊi;ž‡tIPÙÒþ%Z/z+)'¸½(wÞâM¢kß›Bcmã6Œ@ú›…ghIxzZï ÑF—,Œ…ã_Œ´z;.›(«ÂžÑ©7€P§YˆD­ÆÜQ¨²#äŽö!¼50¼•Z!*“Žt© å°ÎÖWêÝ×›ÀÁ ]ó:×{ž1‘ß†MØr•&Æ,n”%¤JV$€¨yà4§;~ZWT=1,k1aÝNX”DØÊÒ¸xõÕÐLÄ¾*#O$
ÓVxR^b(Š
ókBÄ}@‹MP+Ì¢&hƒW.…AßMuNg—›¢¬FŠQxê,¿-5!‰Oú˜¯GgÌ[â)p<£‚3æõ¢KHL˜XÀÎºŽ™È„ÛÇ
ÐïóË%8|<Š2­ˆZiöÜn‘½¶|Û€Lm?„©m6„¡›^ñS&49‰}˜„T²I£QP0Œ9
¥.-ÕÐAžÏÓ®•Èt&†ÐÜÁÈ&›jS“]*#<í'ÐÊ	)Žù+Ò‘¨|Vn€£‘^ ÖÚ@vhâ‰õÓ`ïæAñºÒ¦•Ìiš²._À°ˆHî	mTÖ¸›‰6ç°«€¸™d²/Loe`;û×’gÛ,XZ«Î10¬ß$ŒžÆ%.PM{ÈÑû|]å4ùK±ØË¶KáâåbO¾*ÛÆ^ºË$ó3Î>ÊŠt{vj¶Æ”:ÓÚ€¾,´¡®LÌv@³Sô¦À¥Ó›¹á”.Çx–h%–Ô]F…ÚNA$Ã·âØãÎÁñ¢…RÅl¯¾ UûÊ&~‡ŒØ¯M¹YNµ,²ÖÜ‡­E+íðp‹çâ_Õ"Ýcû`´ŒÛ•­5±‚ P¦£°Ù½PŒÍgäÅëWP„”úk-Ä¡í¹MÉ} üdF)Vqž²Ò¢e9Æ+´õÇvA¯GSm’Ôã;ÅaCÐèAfòY2ŠÇ1ÂðmØš¶”µ>QNAiùO'Ä,W‡$…Uþ>½ô·ƒ¸ ¤´0¤†:!)mNt‰XÇâél*²¸^\0ì$½ åø,â•ÚM4 å<fŸJš„@x?ÎÃóçÜnéé¥¯Ò“ÿÄä1™ÆqcD`¥Ö›–ãAÕ}‰,\}Ö53åøô(n›œ…öy»¯³“Ym€4ä“Ô³¡½0xj|g‚cô”Ða4eÃs¾t@´I…óeYÐ(F³œræE]vˆ]‰Hó€2j×€íê‰%Ëb8r0Uû'£] úäE%BqÅcVôÈì‚t+‹Y>Á;ˆRH¤Ëœá1g¹±±¸“,Z Ke×™ô½€+AtÃÑ !÷›>bì] 6DœJƒ.2­M£ŽÁ{ÌWF+øl#cÿû³Í2¢¾]8`ŽvI OŒŠ´Àyã	³ èI¸ºiöMŒÆÏÞ‹³Þl¬Ry‘"ˆ#(±c€7Çâ(X9Z9•:"qN‰„x/äÚ`ˆ´WÉÈ›£ì0ÃÛ ¢e'x¿‰tDû=^²ßƒ•òC¾°Ïp{:À­V6iÊhF¨;r÷Rïð•Šœ"ŸY·oØ>JLÚÄ‡Ñ&é(=CfºeHnL»GŽQ®½ÌFÀÍG„7°à3¹Ò•!ÂÚmÍ‚^oì;„cŠÆ}€Ùµ–ã×VÕlÃøº·ÿô§‡x§‚/ªTdˆÕ(¢QULúdIô¶A|=z¹xàFTÁ§•ì¾q#p±â³„C#ÿ4RÆÛ3¥ÇS¾É„$¯+ê€¼ñLPAlÍz1!Œä
öHHl<åiP¼¢Ì
Å1Þ¡WBA4SaYÄÈ´â@RoªwÕ,ÒY&‡£©+)‘@ÒQøvE\’M|ÝÙ§š1–Á­½+›)+3»Y:´ z7éôÖ›Î½}¥ã³6Ù ær 9ÝB—^˜ðç»¹'Ò0s	´™C@Ðb›—%ž«Ét’O@ág§,ù‡­Ý5Hò!bv„öz‰3[hìzPv#œZ¹Cv“IŒ}¡‰ŸpÐ‚¢Å“sã³é‹þö¨t‹âB‚¾µNF¥þ‚	Èþ…§ ¹ö"¦—Ææöˆ¦qF—Ô7'|¢Ú­RmÍ.ZÃÍArtC±FŠ
0ÉïÈŒì¶º‡‚‚D /Âáø„|6¡~dŽÚPhƒlLMá‹l»Z¶Éø•ëh/`ké/	ª"mcFçŽERô:‰íEÅ\¬Õ$"
Œˆ v½
cÅÍ‰›†4wÙ{èÂ:	¯lõCfßƒ»tŒŒ•Hi¢|ô±Øu$$¤ ¶s±Â‚Vâ<ý¤±ÈÛNýMP\•:Á7ÃåÔ|¸­ìùV‹Ê¢’íHVÃFO÷TˆôFã"„Úœ‹S“…öê6FHË°Ä"€øeFv,qŽçûëE±Ïm‰ÐeEVÃá^¤yå:’ ´>² Š0™ê &÷>X½¡Œ}ÞJ Ï„tM=hÖ.ûÅL¢(ImÈ‘…Y„q'(ksÓ%›àÉ¤HUžâ‚„å(êïë`î^jmÕ	œ/Ågo-4Œœ	¨6\Yc',P	.£H<Â×ß‰žë`/mæRª_×Å1i`|=~¾«vŠèÕØ©ÅMPæ:^áÞˆ}Éc^Å‘dAÆ2-a	ü<Š”&;
ólA«06R|Hçð¶Ã³ÁÐÈ
¾ÅøÃ;¯wN¼pýßD;§è=¾ŠT_”Úv‘àäÅy‚ÑwLì”¬úÚCªÍ:,nŒÑ³‚üÄXç¨0¢²‹®éót4ã
¸!Pš4$Äï<w¤sÔÂ³3DhôÛÆz¦v‹hñÓÜñR[–/3´	•E3b²•ð§´ÿ®„'§Ü’P—]Ò~}QzY‘A×SB*[Õñ‘—þ§Wdmš½Ã+‰tÈ•¬ïÓÊ
áÎC—§î°"ìôÎ^êJ*Æ†21
,Ì2ãæ?˜Ë‡Þ.&àÎ
BÍ«´ˆ+Š4ŒOId+‡¥nšñ
Æt@ínC²9ô†—9ÉÀæE@–­}ÚiQ£õÉ{ãI˜ÄÚ®ÄT¢ÚÔ¿ci%TýYÆö32£„DŽ œ%­„]á€<ËÚÕ5‡LÔ2Ôß–Š¨>K{À‡AtÀû‚ñW—Q˜±éÖiÂœÓ±?iarÂÜ*ãkÞGÈdÃ5ÌR@œ@÷ú0DÉÔ\\X·HîN‰'“rùŒ0½ÈnËÞ=ƒ2#‘£æÕøÀ¡¿9>4´‡”$wáâã”£ÄjW/O	8a¸u)×§!òŒµ~±˜°
C’mX«¨‹°EîPGX°’°#IE±œà³C]}íÒ=:‰èp¬Œ!y.V«Ê	º2\8ÂPV®=çÚ¨Ä†â´×s’ÌXE—:z0Ð°À–¨£"mWvCØ«§Ï<Ô\£GòJ¸Å©žZ¹hÎÅ?mŒ®3Ÿ‘l?{fÈNOX:B§Òr1fŸÏ£Î¢%ï µR;§¾ðÀE£bÏ½TŸ™Ðeú'àâ=³Œ­ƒŒÌ¨Œœ$Š—2p¼+hÀÎ65MÑuž‰h¤OJóî6æ¢_<Žüãëãr!%Bûe¶1= z‡Ûn­9—\š‰ˆ‡»Ü=	är,ßÿe…U¤˜µ.
Ô·ÖaŒ~75…³Ê<$¨j]Ì.Ã¹»ÛÄz±®šA’‘,r˜æœ×1·{CîÎV7YHÚhÂ˜¬ê8j‰m–aýÖ9b2{›sO›ÌåÖDsoÍŒì‚“(ÊV¦é
þËá_&äOï0ÁÁ™Ç	ÛØQP	ï]…'Ü÷"ÁPÏO#¦¶brLâ­Ö1öÖˆùFtm‡LôE•`¸ ‘c|t&ˆz:)\³G,\°±—T_1¼žó¨ ¹¸§Æ‘Ý÷½)%Rè„!¡1õ0ä¡5šŠÃ¡)v0ŸYÉ &ZÑ1‘NÁsEiÕp,¤H£fÁÝrf0ÒÆå«º1ðÒp·iDÃ¾âƒXâ¼Ê-Ôžcãò&æ<êKjPqØõmÑ	…¡÷1
ÃQI0ïjÊ½£E†Fzˆ%ìÏ[l#è§³Óé`Æ5´sëu€£IGç¼Ïƒð<¥°E’<Â3mãFPéìËž(VË	±Bµ§¡jÞFyqÕÁôrB²bÊQtø.¡#ÂÂê£0Ï”FÁ,¡ýÆ3“ÛP\ñ"è‚„”^an
MÌ…Ñ³ä#ŠÞ¡Ÿ8¡ó„=0qJ3á(;šF1²rÛ3×‡åÀ ƒ“X¹ ™z†Ò4oW—xº³„@“,€ŸÀx®H’&ÇÈ¨Éf³HõéµP$ü6Çí°‚¼M”Š~×áAîs"Ç°¬´Ÿ77zQÉ“ˆuõ6ºäíeÂ[ØšàöT'2"p¼PT‘¶U¶nèx<o‚H‚°ÔŸsBóù]äM­BA>ÃPÅ¨ÈfÄÙ8“)d.‚¯5(ã'¢h*‰	©)‡.Jª“6ñº84‡\›§©ù¾?1çÃ\Æ¡‰n<'ZR"•®)V}Ñøp8vë¹Q9É¦e5ÐÝ]äHûœ¹º™qb2;õPÎM”ˆ‘kµI?$x§‰a-Yíð8#ÚI|Õ$šÎâé¥‘KÖ )Te¹Ò¼éÏ0·O,bà)GA%ãuûöm½©dJ<\½7`]_Í»c˜‚?’kÑ6–²é`MDžu’²Ø‘±¼%%ƒ±S…½K÷npR’®Yòövœ÷L¸™kLï óŽÃýÝº	[rçïèQó–^ŽÐƒ}Ë\pZ¥GÙ‘ÂÑµ÷ˆšß²åØñýÐµ×ÆìCæ,ENÉàUCP)(mÁæø: È(ŒZ'q¿‘Yäb%%'ªh40ÚÙGZq0q+"÷ÖuÌÔGs9Ó%âÑâfR˜Œr8ÓF7„Û¨º°—¥yî’w©ÂÜsÖÒ0ä\¿gååáÌ$êll",ËÂ=Ðe>`ç¨à€øGT!fx~ÀpPœÝ•F×š#i+hj¤ÁF7#œ˜%è!Ç;(%øA4-Ú­o›XZûeŽ#mP­9ŸZ¦ƒe‘zƒ8.ñÒ%ó¦N;Cœ•xÎ¨à$@Š7L"NúÉ"Íö¬Ë­TO‚GÅ%¾&6Á>1íî 1¨ÇŒp’›M7±™“iÜ`u×åÅb˜\pv8±­¯”ó„QmÄéÂÊ¹lùÖQên­ñÛJºg6Õ7DyëO
4AGõÆÍîªŠ]Ð•JÎP$áô… ‚ÁsÌ€ô²«W07 †UU¡1¸ŒPêp*J@O´°‡¾zíÏ§’¢„dŽ>èÔçmÈ-±<Kdó´ÕÌÆíŠ¿(½i@?Tâ¤fëz…HïfÝ:ÈÄÌ™>Ò	!Šñ‹]„4&ß'åÇÝ‘ûP—z {oeÜ‡Mâ¶¦xŒ”‰¢CßtA]ô;pQ‡q,ø>wy‚æ)K@gËŒìœP£Œ¨º ß»¾PøaJô•u~lI@i“:üý[èó¢4™XÆ&¥Ã™µ¡¦ä«ö"¦í‡Å9<BS;!Mº)©-Ù¹a_6…Ç1?³ËÍ„½°k”·ËTd Ñµ:`ã3m[,y[	ˆx\µO–·žÝs(y„¬lÇS;û^¯¿‰yL1º—Çƒá$ÏâÄ(·geú6ãvN
]Á¬Å­[³C”¶—;ÖCc†á‰„¦ü’]J¿‡#‡-gR‰Y%¼¶aàdð)2ú…ÝûTëÂ=	££ë	Û¢:†Žx3ÑÙ‚ÈVˆªË@™Áåq£¨äF®ažEÃ6gåR$AÚŸÜŽ;p1ÞãÄ«³+q
˜è#Ë¬ÞüK?Æ©sî-W-ë,ÛÂ1JäM]¿È†µ¶Èú@uÆÂ¶i:ŽÔ^Fz¯“K·pNª„k’A@J)‚]ÌÅøGå˜ì ¦r… ¶b´	ñl4O€|‡t­&¦ùÀ„‚’xƒk—›ˆöí#2‘·ÖÀ®™« Ø§Ø%Qz4w9ÔžµžPDUX’Ã Õ¼˜·•E-p†ªb!–`Ÿåˆ(ëe“R5:3¿À T@’,8 µ?£Ì©-^L´+ú9ü¿Š±X¤ôWî8åÝ|Z§vžï™ÇU³F½bØó\¼s	Ø™7×FAÓe1·4éº­7à²P(˜ <Àæ&35(d¶€N@Œ
%ÄõkHð…î¤:
:¡g±G”œž ldüN) Ë¹?iñF5´@%!ëâ¶)·NÀ“–¹FÆ#œénaî(¶ Šº~Y®Ø€iÐ|¿k’‚'lpã>(ÍdŒØZP…““„nš2Ã„iƒIå0@*ª…¢ë_uòFXÉ7£¦òÞH¬âÂªÅËùYVSY@äUÑÒ©Îw£ˆ”P8¸)ÀXL…ŠØÂ‚†­¾›=²ÕfÓÇ'(Œ„wzô‡J’ú])"NEÎS3’ý®Ž©º( *²‘}àz`„Pv(‹e˜j ¬Œ*åH/«*é.øc7ÑOì±¹Àˆµ!—hØØ*ðhÞt½ñÄgÉmívPÍ qäÊ0dWÆ†œ0üpUõIªLå$(Ã è.è¶)íº—„t£MœMtÖTZ’îA+‰£ÜYKpýZ|â1Ë	ƒ8ÃÈ–xÙz~†¹	­Ðs1FçÓ²|Z·z\Pœ®M:èÍÄÁh¡šý½ïîo 0‰QœyRlÜ³ô¿-Ý1ßcÌzöVâŽ™K†Æ_©ÈÒéef+tø†€Š«)ßæ¦æ+¦1Á"‹œ»/¡S÷¨h8ioê¿@~"½45Bð™¯@«ŽJ—õ¢—QšÁ=ûS“¬yò€jByÁm…t	;é:G¸v™(Ùçp=Q ˜”åçE$ÙìÇNÒºr(·©–R9$k>‰Ìâ…µ‹ßð’Lƒkà3-™o""o°C›B³KN7Šä-õJ¹ÈH©ùFúáÇU„cÎi˜‘db³æÈwœ»¯+Zr¶^Å!ø•äÐgjìpê!or)Á´!$WÃ²{Pº÷\nHÂ}QRîhÎ'MD˜ÞJ/ £±|1 š|¡NTœÊPž9¹V¾WÅã®šNåŽ€[Ö/2ÑDÜ†‘Øâ,§Â…^hÌ|Æ®’¿¼õï‚T'‘XdÓž8/3æ‡
]_Q#Cº5Æ:‰ª¡•'ëÿ©±Äïz„ŒÏ‰ÇáTM.xå–äbÌ+ë‡|KurÔ-¨ŒºE¨±àQ†1Ž²3Æ·ÞÑ·y×5ÄÇ¬£¶U^„¹³“hÊE.w­H„#vÉGš`p®i€q;xE-=×ùìkagûå]ªÈØ§,J6Ã“´ Ò}V°®Yâ¬¸eŠg‰ÄçÑç%YŠÅ¼Š¹Ž:w	]çÌ	Å™ ø=õO…‰%åÏ°úh0À«’Ø,ú6Rž
*×ž7I34¾ÏBJ>²|Ê{Ÿ'H{¥!D)ÜñíÅêºYzŽÄS–:!tœ½eçRœÇ¼ÚJ—îŠ±ÚÞp3c|¼`ar,­p$Ÿ?E¤ÒßäôÁ”ÒšJÐ}v¦•øÀÔ¥±%Ø}ëi0W²ÂQ3ÙHåØÃ‘Ô?St“X½Ü¢p8Ž|’¬’v»©tYK]r.a«cšÕtàMAdÄ;e,º”P¡Æ˜´S˜Î«s`+pR3ž@îÛ,·µ	m"„QiÂmtgmÊï™¯¥-†ãn»x©ø½zçã OÔwªq8þTpÃ-¸¾iØ!N)‹úúÓ†æX<Ü‚Î‰“ÀÂ\‚â®I	Ê!Óƒ"r¹s¤Å-VÜ”F€Vµgš—:wJäx¢`AIßýª”ÞŠ±ùF®á•d‹¹4ä ÓQÍ|³Ú¼*uF‘ï:MwŒ7Mv951¯ž©€\îÙåôN;kGÉ®aÊ`ÕÃlÔÇªZ†ê¬pÍOåvH¿„sp…‹€KZP\ž¥\tŽv§[ÎWÜ–}áªD]>1Ø¥³?1Ò›‰‹ÕìŠ¬O5‘L$’Km	 i$Ö)v¿ÇS¶¿I~¤¢¾4X•JEî‰H»%Çé²);—hÈ%YXªë><Þy”„œÈI5ÌÄîÏ-ÜÚ“u.k[£s®™Bîþ	RpK¦@¦Ô\çXõ9«-­K£†›ÌNp«¢œ
â+–QYSVàˆeð¤4UÎR›œê
ºH„FL.€ÀÔJ§2Á7©ó¢û×¦$)Û:¦Á¤ò`˜4E`K
'‰­‰!˜‡*GÐW 6g­°´9budÜª¢3ðŒk…²ŽB)²E§QÉØVaJ¸;VS¹lù¾¡áR¤à©F`êcëÒÓÁÈU›ŒFdS°âá_‹È¢ËŒxRLqÅÕ]‘1h@µ”TAqB–ƒ’y›ežŒå/msá‰qâ`Uneà÷dîcV7Ô#ÆtN`3Â-…¦Å) erîÄî‚’,£Ã(ŽÎ#„!·®nÀ|r@‹Í°Ì$òÊ¤"sùAuÀÇä ™¶9Õ \™t7Œ i]Zˆ&Ü(©Î”¾NþÃ*:Dbå¢¼VÐ1š)-¤£}ÍÜ4ÃŒC×ª«ý¹šRI›N*°„ÞàéÇyÁ„Í¨,&,Îe³Wü!Xð#C8yªMiX;Å¡jX$‹‰¥¤ÙeMÞØ,à±ŸŽ‹ýÁêœè!Žo˜Š/yQ}aÙ:·E½l½–¬¢SO2Ò‹AòÃQçk!M_é*2Þ*±äðjÕ`dL=Ð	¨_` ¾¦S” %ˆÔ¦;’L?ÀÁ´!'Ä'áå˜âœRëP¼ªRšFÛW¥Hà%æY)ÔèsÇ+ÂfÙ¬¡KšRm¯LI´®t;´áµAiI.ú	>U'-S?Ï#i&ˆV‚w–9~.¦Ò¾}c^âRÿøq™:!`”âÈ!žI¿jhsEÍû,zè4í\ÓDòÎV\`q¤àÜ"²ô¹¦ƒ ¨%kI,õ÷ä"4ÚsÃZÝ×¾S»a§…o¦éø¢a¬KË:f?“©AÅä²™ññ‰:í„ê‚Œy`ª±iÙTc¦ñêŠK`
Ð6#"cè²9iÌî®§S/T
[µ×šXÜêÈ<cç½ó»ô2W?kù­PïM}©S¦–µ~HåìfT†ÝŽüh'[WÅ†ý¸gÂòõU.·K]ß6Ù-ŽklCóû6­øÉÏ6hBã³ø<•ò:µ,Ç³Ñ4ÔïÄp¤^©2—gÐ%Rt¦Z*hé¶›°—’]Þ5ÿÈñ3*~R4išˆ[K<ë×ÙuüvÊº Ñc	­Ç‘dR0ÄãÜYèfì°ü Š)Y*ò\ÛÍ¶Ñ3?É<táí’QÁÉÑ0Èðst¦ŽQó“ÇÜjFíûMŒè¶R&¾KÑA2]ô<Å'²X"%y+	Kd”üšy/OH|jå³§¯$Œe´ÀÖå°µ^Ýâ…$7¦:™\ñn¾W‚uL
]‰È:®VÇZ—Åý¬®ÇÛ}ŠêE‡í9ÅüÖeT,"pf+û"ñãœ]Åø²ÞT‡œ0ÌûUä¾½T0à6Í{‹#[¥ Y&Ðä-ô0ºczÙó^,¤{†îœ8üKa=8¸>ŒÐÖåú°BÒ$Îb“Í+Q‹ÆêEÊÎ’ƒ±C3JFô†?gBC˜GX&ÆívüL=ao¸2*	ˆM3X:ž‹n‘Ì°° ‰ü
Lp¹Ä€jiÐ„s?£«°WAa¯jbÖÅ$kõ4ï:R|{KiIM¶;ÇÆ3çÉQ¸u@•ža`fÈÏAg 1ÁJ=¼	,Þ”ãŒÌÎû„Ò®¿£ZÔ›B6|¬7Lµ—B!û“™_P5?¯5kwgX:@À˜w—üÂ"|ƒjÑ~²*8ü÷Ì >‚À}Ï ïæbLñÃ¾|§ªÝ&7äÃ±ÑkvÇ[BÐu­ó»ld‡T‹[f¸«gb3q£%ÓÌFçnÜ¿?”¤^GP(ˆK˜µ,ÐiE„ILÅ:AË’ \Fl^<¤db÷ iBÃ•^Kp8“¸ÝÃ®Ú>R{ûêuçð°³wüƒz¶ˆ_¨ƒÃýç‡Ý†:Þ§¿»ÿyÜÝ;VÝÃÝíããî–zúCÐ98ØÙÞì<ÝéªÎk|9é?7»Çêõ‹îžÚGð¯·ºêè¸ƒ¶÷ÔëÃíãí½çpsÿà‡Ãíç/Žƒû;[ÝCz¡ª£SGuÐ9<Þîá<^mouÝ9©Zç¦]S¯·_ì¿<6“öŸÔ_·÷¶ª»M€ºÿypØ=:‚	 ìí]˜q¾ÜÞÛÜy¹si¨§ aoÿXílÃÊ Ùñ~#ÀÑ¤­†Ž“ø»ÝÃÍðgçéöÎ6ì>«õlûx† ½ëðÌ7_îtƒƒ—‡ûGÝ¦â- °á‡ÛGU°ÙØÿxÙ1€`wÆngo³‹c9kà˜p¹ê‡ý—È"`Ý;[Þ¦àFuÕV÷YwóxûU·-a˜£—»]Ùï£c tvvÔ^wæÛ9üAu_moÒ>v:Û‡¸K›û‡‡eÑèa“ƒËÃcGG-3ÅØCê¾Büx¹·ƒ;qØý—°VÄåc	Âï<?ìÒF;8¼Þ†‰áéÄPŒê_XÄøPl_íîom?ÃcÄÙÜß{Õýá(pwöÙ¢lçé>nÌS˜È6Íf€»„ç¶ÕÙí<ï9˜còÈvCt7·ñøð`‡·jïÖŠGÕ3Fˆœ|ŽÁK¸ˆ€{q`lüÌì²»Œ”jgÿ10ØêwÍþ}ÚÅÖ‡Ý=Ø(ºcÍÍ—‡pß°ö€Ù½„¸½Ç§ë¥+¾}¸èKFxû¬³½óò°ˆx8ò>l!‚$tN‚[Õ¾Ú~Cm¾cSÞUþA½€£xÚ…f­WÛte˜ä¶ì	¬Ž È>2ö}Ûä·EðIƒG¥$—yõ=¢g2b°áÈCd~oŠ|p¤­}ÑŸQŠÅ8y…+K|³Pá)¥Kqˆp€"atÁÐ–paýŸT^ˆÎŽå˜z£”3A1±å½‘hÓ:ÍÓæÏSád?PFÏã‘3÷
›‰#ƒÙ@R/7È&øaÓÙZ
?Sôh1pûbY×ŠÀK:ç9/ÚŸü®S‡¶ˆÃ¹ŽuhùÈòö@X•	äŽIÞõ!]àÂ¾J¬ÃäÉiñÈ:Î(Ï1ÎŠÿe–rKâÉ§\Ã÷†dQ7a â‹§ÿt6‹CôÜ&šFù=	ÿ!^ý²ªñ/iÝX?’F1bªÅhÅW:e$¸Mvè<àÒpÆ¦÷X7‰Š³-(ˆÈ	³ç÷ZrïEÌ€ä/±f:Uý¢Ä‰@Èó ${ëêo¤þÔŒLSCeYÌ"j’’RÇö]=g03µ]é)[”M¹¾Çí¤þºÆ›³þ»9¥	èÓ,ŽèA	Mq"17ŸHU"-e-oÖÕ÷Xî	Œ@ R¾÷„Ç=–÷ZuØ†wÜæ½qïã©ÖÅåÀyCÕÅ…Rr˜{ú…$üÌ—áZ)™l§-ûé¦õ²fÓ¬Þ »NóvÕÝ:I‡´q–ìá8¹*-ê£Z\C¢E¶G&¯+h,mü´ÄŠÓ®Š’lî<ÁKYÁë(bM!,ÒÃµƒÕd]5
ý.^›Èf?²n>`©+çÔ"³{Éê  ;F>Dêûát:Ùhµ...šgÉ¬™fg-îÑzê`è&Ý¸¥M°ˆÓN²óÓãTóí|Yš`Õ(|+$œ`ä
¬Íe”W•(ë‘klih*§[	q?²i w”žq¥EQ60†RÝF.vêìÅÂ5’²ú½ŒûäÆ7±„‡\š™ö´óôhçåqwçW“yDg*Ç©¦—€ §ß/î6-¸â}¶¬ƒhy4ÂqØ0é]o‚À·Ù$EKÂ#w¸Þ]w"°ùhY^NÐÜHîBe^!Ôó£9˜Þ‚úµz7ÓÙ/;ÇÞ©Ôþ€ãØ¶4SŒé°’…Ök	wþrÛV?–ghB3²5¨L€§é»š‰›”)S¬)†ZÒ¨Üëô#Ä^m_AÐ/úEYbºP¿ÂÁÏ­‘×+ q0.VÆ«Y7¾)ëŽVÌ›ÏŒOÝ¿8ü²³ó¬$KhøhÕærãËÛpIƒk/)[PcòáH7·X	÷|¸rØÄ¾K­¿È\	‡.‡ –¥èÇŒäY¯KI¶ã²¿”×‰w”6ƒÉ3EñLÐÍyÜvDqMÅ)oæpmÏâ{t¡c.$¼ ŸîÖq+¸!;–Í³îa”Pö+¼5XR‡2n0z˜Ò±0„¦ò(&ÃDét2¼l]/W`›WFg“Qs8àt~÷ÏøÓO{­Ãngk·Û÷¿Ð«««××þûíÃôïêÿ?ëk~«Ú÷×¬­ß_[__U«íû«V§V¿Ð|¼Ÿ²˜JžFÛA³Á`Á÷¼eþý'ù¹£ö_náÃoQpŒ=÷QC"¢­ÜêøÕÖ
|ßMÎÿÏÿóÿµ”G9ÉJ/\’Pe^[ õ£?’T“(9AL`?Ò}`Ø#~£ï4ÔNLKt<ÛùF¤
 F‘-ƒ‰j™ã‹À1ü	êa]û	—‡ƒìooy³!%,ã &B÷(8ñt¦]§¬7\êz±@ Ç¤hãŠAÑ‡0lÌjžždžÌi;}š¯VãÏÓ4CñŽ¢»õ?E×;åÐ¤¤P%ôj
¿Âìmã–ÞFoŸYn9Úm¨ÃÎfƒ=ŸaYª^„Ô9ŸÎëo‹S
ÔK)£ÀH:ÝÈYð¡{iîI¨¹„ßü<“`Ì{÷ÒY&ÕÌ‡÷îÉ¶4ôkÞÉ >›I!*yp’«YÒ²"Æ0Mâv\— vÁ=zb@³dœzâøaN½ûây)‚
¬ø¸H-äü}®^WÄ"<r³ÿ¬ÓXçUCøzÈ.QP‰¥!ŸÊNœÌÞ©W»ÿçÿþaV8Ç­´÷–=à(ÌEŒræ“Ó_L9ˆ±)Ÿ}ƒèó`h—­£iM{Cß|0/u_Ë é8h §tç((ÓÙ¤p\6nÄ£cÐgHÁ&£6ê²dvëž&nÇ‰|…ÇÚÄD˜Yù-‹ºöRgp×'°Y4ŸLôïÿ;N?HiÿþÀmüwKýÿžôúyô“jÍVÛ-~R´UL­ƒµÕö·+íöJûþI{}cí»ß)ôoà+Âl˜¨èº,~ZµÚlKáyÐ¶÷ží«
@ÄÐZÎ*3±ã°î1Ö]]ØùeÎÏI—'òãÊðü'øï©ú~®íN÷äiç¨ûä'µž‚±é±½+ÞÛ4]\›ï^ìï:Ÿ?…Ï_nÁß›}y /èšY¬+-tôCkVË$wQj>‹ê×;ŸNÞ•Æ7ÂÐû†ŠßuÐ
{êBs>W[šÒ4Õ.²8":avF/š¬Ò-êºKÈ„êÀ}ãC€±Í—×­%Õ'WX®Es²Ü!z÷–ô·õæuCôytTA®ê!ìfÖe¿ì¢‡ðZàgì¡­ú„* EôHÙÁ€pyž*ä¸c3ÎšRÝ/PáüºèðF€t¼½WØq¤¦Îâˆ'£¤ÑÃPþ¦ã~µè‹zíº+îå5#ž†½·³I^5&uý 1êS…ƒÝ¢w6+†5_^{Ë«¨Ó5«f_t­qÜï"<õkÇþ;ýét'=#>¹¡ZÓñ¤ÄãFé2É ð
gJˆžSºä.ž)°ú{Œôøwññ—~6¡ßÊé½{B˜¸æ½ÄŒ°4çl24³{Ã22ôîW÷¾‡œûžZÖâÇ¦Ê|øá¦:~Bó¦½8$Ñ8@ô¶®0VÑoTÊw (5U•4%g0‘ÕH-þXÄž‰0X~¬”0Î‘‹` 1.}Ô'XxØß­¬®­´ž´W7¬o¬>ø8y¤Ý\m®j‰äVFÿùenç-Ì.¤ãéœ‡£Y”/ìñ2×aQÖËtwØ¤J¹ÒæBH.«6?‹{°„æîÏÇØÙ>D»…×tQßîñæÉæþá5Ã·È‰Ûl¾Ø¼‰\××°ñrßkûylÂÓýk!X~êÏšxäÎÏPl¯7Óà›`ÐÁáþÖËÍã¹û¯+öß ò­EG) ZƒñE{­¹Öl7ï7WoøÙîkøm þKçU§0_œg­ŸA'lýÜÛn~×\=i?\[éhópûàøäÙì•1o>]RødX]«Ç.ì¶IÎvk°ÐŒ)æf‡b<þ˜;.`Œ{³Û]Ýëº«XÕ«L>aàëoSu¿Ü£êŽ7# ×®÷&·ï)Í Ži€Å€›tìœ†§”¥H¿5sŒ¼¿YG´jáxÒ[ÿù1 š'[Ýg—;Ç'.¤Â§×ì¾£Bž”QÂ#ytªÑäæý…~¯¤þ$z‡¶R÷Æç6æ¼Ó­ ý’\¦ Ê[Xkÿc\	à}‹þÃ}Oz ÄÑºœ‹Ÿð³tÞÇp:ú×Â£ø´À­lXpÄS±¿ŽúñÀý›fdÿìiöÝOš(6ž þánº€Ò³,Åp¿y0¹âþçÙÑnsr9,¨<ÿCœñÅ(?OóqSj×¾×6Ë'…o ¬‚òÐ+~¬okXÚ8l3‰O°–D?Xˆ‰‡ép~é˜
SßøFéŽSìêg@zi¹@æIe[4^ªÂh¢ß±@´Œ¤¬þ© H(Y.LõÓ 9ÂîÇ<`/&öTá·O6yòæzøMÉEi
ƒÕ¢6Ã}g¢=>–ÜQ›Ã¨÷Ön	ÅFâ`®ë=ð?ªÚÒ{ÝìªRD­¦~zDikRÔbe€Pr¹j5u[·•RÍªðM4’ ™¨7LU­{x¸,ˆÌèèé 9UöÄüVÒgßÊ!<cçD@ÿÅ×šÊYBké½&RøÙÎþfg‡¾9Ùëà 5­á ²ûð¡k¾>êbökÖÎÏŸf˜“â»6LÇ‘¾hæ»…p¥ŒW½¥Ú½¦ÐLµ³	Ã9R¥^ÌÖc(ÈO£‰”ýŒ­ é{;h:Ö/åß–jê_Yp½×TÁ¶r(œˆæÅàfdÄˆð÷SS»gÌ«B˜æp•{®âs¯I ìXxS$Ö4^teè¶èkóIWçc/Ï2I6¨V8<K£sýš[r]wF;wð…FÇd„{ÝÉzÃx‘O1ž^»Æ=íÒBczÃmš;Ö3pTl¹Ã˜ñ¨Îr~4n*@ÅÆåZÑ0ð¼ðæE,/·ç¦J…~ˆ],Ü‘¶pSd\…¬çræ8U=cmjØˆ/ÁÍ’j³8Lƒ·²¿1gª€¸°pìÖ3dc^“º¹FóÐ±ÚQØ¦S¼é›üŒEˆžÅÍ]"Fª;Oçž–³Õ»ãM	ZC[pŠå]zN,ì$_CÙF¼°wö¨g$Ð‹ï™-Å^¸„Ë
KÇÓ‚B~>¨­ˆI¶Å áJùG}(~‚-ùv!êDãÂ%¦IÏ â®Ø½d·[(Ì	¢žz+¶]hl­¿¦¾Ÿ¹•MZ¨]…•Ë§¥™ÊeÒBó¶w¦R¡)ã7Hsòóè¼³Õ9 â’áßŽv”©÷•E6ì„Ô™OÔ)+vUÊ N˜êê‰0gS6sôÂkÖA]6œ:î¬þLÞž°ÆPs€”V?ÿúñ&TJ™‹eQÐ¿©vR[:®´h¿dŒÈÕt8¾*ò/¬X´	c	O-î`µsÕW\¢=tˆÇí¬Ñ_ž‡q½²t†ôÕm-€…wNŸqlÎ¤ý•u1ÿƒg`âá1‚—:*nÃh4QËÃº­\ÀMcï˜fŸSû)>à,›V´PèM›³M²‰•»UZ[vå©5­™[}ú$ÔØÇ2T©ëºåyŠ\1ÍÌ¶{#Õ—2dÆeyÕòC5×£…¥±ôÔ×^’ ©ipSíbFg9ë7Á´}¦:ûÏ@••p¤g£è%"¹âN zAOÄœº{¯Ô+ÍŒ„ºC8dþ<§¢>ªÙÚÜ†Õì®’é©M?®7„¡]'rC-õúé©YóþYt¹U®ºÂƒL…L¸‹qbóÐU>)“´B÷ÏÏÚužcQ-žrÅÐ
Cçv7¢i¦WrÍÛ™vcñ$NE7MNµ$Ab•'Ä6<Ó’+ï"ËòeRÑ)@Wä’»zƒ1ËÄzÐJ‘Xä+œq¯zBÐ²0¬Åß\}ÔfgI“'Œù;ëýY`ÎÕ_–Î,õ¯ŒÙ;ÍÝçÿÐš€1Þhº-ói©Ï‘D`:¡N‰òW]éåÞtwFÄùÎ_µc+ÔŒÁNÀˆuã«tÆ{Š˜EgŒ
Žô•7í|…,ø³ø€»Ø m¢ítÂAæM×=¥yó¥Aµ“EüvÀß<(~áê7¬ÛøCÍÿ©>
®ÇµCé—¢ªÖ÷Iƒ
êVõÙ¡[áS•Jåxgkû!?¢Íb¦M|qàÓ§ç8Dn2=·¹Ë‚Ð Bah8ð NÈS¥#‚ÉïË„õëo3Ü%Ÿv:¬5ïó*]Ä•ë®ò¯¯úü¾g¢ªC¨Ýó‚h¹ñ)-4v9JELYyfs8Š§ú{¬¶>pÍ¹²Í ±Z‰ãgêI?¥líïv¶÷*öxámãÇcoeó>h1Xÿyƒ-’©jê‰µÅPA½Œãã!£ÀÐ_-ožšèlëq^xFšÇvÕ` yLÅûªjº-øÄ#H´}h~¬dqðJ6Îƒ®(¹#Šï¤7™”–WVA1’þi„é{òJx‚µ5±FUf¥’¤Të<ƒÛ‘ó?Nfw6¦0›½ÐV÷ÕC%2o œìlû vbV®ü`×iø”y2cçãÎStðzëäÙöN•Ls 7ªª¾ žºô^ËW-ÿÄ'ýæôÜFúcÿð¸46ïD¦/gby£©@žµµ©]î°{pÝ¼Š–¸ë¢!ï ÆÖ·˜œbÕÎI[×]<)i"÷ªÃª;ÞOS.Àýåo
³‚±5ù³‘p'UG_nÝâ—³%*ñeÒF8KËÉô{úõûÜ¥ÀvqNý|Ž©è;Þtû$Ì0Í§h¼jx8Š¼Í^>›Uï;uñŒƒ`´¹Éå'^'ßÊÏYrTgE,jd$Ä*%î9…¶ÙèVR £0Ç2ýR«…Ê ¸Ì“•‹‘ óŒ2¼ÜŒL}¯)ÅâX·¿7’lTµ®rHªûé¨Å%r9Ãª-¢Áð;:ø>B¡R+]­Ú§ô.)"´ÒŒ!@£²‹˜sP@ñw7ƒ)¹ŽX}Àš¿»hI¿]0é·ÖgGÏ „gÑ
~,IƒözÅCÇÄsøÙœAð3KîXs9­Ÿ8/1ÏmÃâyœÎ…ˆß¥“(yÂ!ºs)è“Ñ[pK¦ädýê<©»…u®„¾9´J„B?›%\Ø‹ÜpòGi¸ÿý¿,¿†\ß”H—¼ve"¤åd¢……ïwº{Ï_<‘åÓw}øí¹!@Ê4ÆÂ!É“aó!›ö*=7ö 	ðÆQ%â¾6jåº¨öÂ¿³ÉDrSL¡ý‹1Š’³éÐ¾ JÁM}øò’©:jqÏÿïÿ»·Øïày4E}g‡³ y{¦'lQ<!¯¥sÿû¥CýëóHW÷v£6Ühm¢­.>7Í ìG,£ßÙÄ F5|äIG‹ ·)AÖJŸ,éš?-bYÌ?ÚU¬!J%;~¡WPÏì½—÷°Ã½­ý×{÷È´ûs''pNUÎÎ«&v¤ÊöThÌo¥hFJ®¤
ˆCó›¾ÌRì‡OóÜZèøD
ž¶öóh/	æÒ®Ö‘'Uþ3ÜßS&hÏ8íxÇt+¡‚‚ÊXŠ6´n2îe½f±§p“ÄzØäyIºA»³ÍÄ¶…õÍÒD(pId<½Íó*Í‹Û\Dƒ5‚ˆÁ)æ"…¸	ñ¯O{M=|¥Ey	æ6{ÃÏ&-*“`ñ¹èÈ7‘*“2Øô1}¿µ}Ø~Bÿ¬i’¸A5Ò !0øò) â3BXÌ)î¤"4Áä%Ëá´±Ùr™‡ÕrWuW›ªÃAh´•Hì$FÎlµdé¬U¨í<Ç+	ê$J{§³3”#º‡‚ps!¢?¥¹&°~ÝÌTÅÐ­äõãsøwvzÝâøÊ–cbÜ2–ÁÉ7Z-DÉæ5‚5n‘ |¶EšV¨WÞªoÁ=õcWÇåóÇŠ †°m(Òâ¦uìžÏN±bÖ\¤O?¢:Õiãt‰4ÝN\:±ó¢­—· ¢ÒùýæjÓ<“žR¸–_ ÍTÓ›r™µ|^	'[,è×.ûb~0h¿)bÕ—cqýŸÕÕõöšÔÿY]_{xëÿÀ¯_ëÿü?Qp#¦1çèXU7¸sõàfFˆêŸbx‹í6ú—b|+Ä2•ÇÎyž@q>gÎt~í“øu~èþËŽ7óaø%Æ¸æþ?øvµTÿëÛ‡í¯÷ÿ—øéµ{ß†Ñàa/œ~{:h÷Úíõ«ƒ¨¿º¶úíŸÖVWë÷ôÔŸ›­rþØ·úÿÛûÖí¶q¤Áý»:'ï€Q2ã¤Ç’xEI=êoÛI{Ú±ýYvÒ—äèðÊŠ%R#RvìéìÓìcì¿ïÅ¶
à¤(K¶e9î&f&#ƒ…Â­ TuÑªâ8¦S,k¶Ü­†iQ½ÞTM¹¥˜Ž£­fªtbkÖ0m½N¥E$K²[rÝ”Í–N5S©·²Ñ”›²"‹¥»4£éP]ÖUÀ"ÉZÝ°%ÕlªŠ¬ÛIi*Ð–!9Š#”í#š¢6«©™FKÕ ¹–e%ËjÉšjÙRSµd§%Õ±d®‘#›’bZŽbAMŽn6eC5ä†ê(ªµÌ:tÁ°µV3€—mÔ¥–mêR£ÙÄ!Vl[QS³”ºlÐVCÑ%K583•–q­¦ÔlÔu]Ý”G®Ë-[‡áj¶TÛ¡Š]£IhE'µTCm6[³NMÚ-×-Y“5JuC‚¹«7œVCk:B±¬Å]ˆCVŒ¦ÕdµÑ4t	ºÑ‚ákµZuªÊõ–¢ÕuD±ÈžÌ´²ÝpêzS7†ÜÒeÃ4%M±4E2¤–eÔ“SÞ"“¸ÛÌèŒ)\zn%Õ±,É1-Å²U |*ËfÓêzC7¥¦NY²KWgQ‰–x´¡6UÛÖ,ÉjaC	 õºóÕ€™‘ºDMY¥9iE£-›J0/r³a·Zªs­™½Ö”åFKkÉRÝVì,‚íßm(.pîH{3ÈnK…3²ôhk…ýÆÔ­¤£4uzdªŽ¦k°«ÕeS¥vÊ¹ÈfM ˜³®(-§Þ²L6Í†5Ý’q¤zKmèŽ$Û™¹L7aß‘4U‚ hX7LÇT`/œ’ÖÔm£áPü¯žYi»S˜œÆ¦®Zà
 *ô­Ñ0Ç’uˆ13ÂËRT’a;Ú¯+-S’Š-QP²£I–	û£¦Ê-¨¢~#žÕ`Aæ¢¤ê¶Õ€]Â6aa›M[†åÚReŽzXOrK¥»¡Q3;¸Ì¤V’{¡Um2ig%EmPC‡1nIM“:F6Xx’dË°ö”†ÓÐ$›Rš²¡œx^ÐCƒ¾1Án‡RS¢‚=D3ëVÃÒ6mÁäëuÛhB}Ž¬×ó±Jl‹ë‰žø ¥ª¥£niŽÜ€3VÓMØdÉi´EW5èM·,ÇÉÇ©ôbÿ9©þÃ°YpxÂ^Üj­ë¦f6`+´ëÐð&1UU™Â×[`e# 5q/®+ª®Ô-èÍÑab[“MZW¦ÎÐÌyS¥öøE^"{žãà]6×6Ô–¡RŠk¶nJ6°|°8àœÖl ’áØMI—Z·AËÚKëjCQ±µ0-8þa³Sá(p48 LØŒ–lØõ™uËËjOxé¤ÑÃç[¬Ù0‚ð&4Wƒ#Æ¾~]7dìŒ!ª
œÊÒ8ë0áTulC‡U	¶â&p?prj–aj¶­ÃŽ”œ?
YÓr
{Ð*mÁnnKuÍÖ%Cº·lSµµ¦b7uÓÎï¹’Ûs…ÍU³©Ô¬ÛfËji–Ý´MÚÙT[–¥jz½_ªÈG,õ¸—>?ãÙØ?,Å¡¸g#Û@©¤6-«®·Z2ž#p4›V~sóÆ“p\[šìP©©È°[[Z³ôOÎ;˜ Õ¦¤Ýfpn§¡ÔMË6(©A)ð¸–-Ë6œ	–cÀ¸7à¸F…œ(GíïmïtwK*Œ¹a ÙÀÞ¦4-EwZ*°%¶|Šì´AmÙŒÊ%NCqZÔ‘¥©A«uKW¨aÓ&,<Ö`cLSQ5'*ÝÜÜ]xÅ³p…âDnB¹OÓæßÿ ¼„òŸ\×±ÔAþƒRý_D{è†aú“Ëy<ðªëX ÿ×5Eãò¿¬5tEùGB(äÿu¤çaÂñ93G_ÍM¿N{N^ìÙmòbåhc7å[^/Š´¾ÃC5±'¿‘nøÌñòõN÷”é´¾Šý`bø>%Jk“ ƒ§·pædÚïo’îå ¸¦t=¾òF£Bb•§öŒY&|ßb‘HÂïÝ xY—²ÛVòÒ£þ+tu yU~ûÏ ¼•…Ò»ö ˆK¿Ø7ü`›ß›¾¾â3°ƒ¬x5 ?p·é,HôƒM'[’cbV;¡Å­¨'‡öàŒjŒ„™e0¾ÕõiXóåÀ†jÌ9=6…Ã0.¾œ.ÅO@¼oö+jUúûÊ§öÆ`PkAG£º<r/vúžãàf±4'h¿ïöküUÒ_yc+‘§µŒË™»b{M1I#uÀ™÷Ä¦‘~ApÀ­®"'óÌì,Ý †-tpÆÆKb¬=ôH0¡ü=Ý]Œ†¼‰³Ã#` {DßøE.€S‚v•×y½ÁFDšig|„Q m[x´jfñ\>~Ëès½»ýýÞöi÷äðÝÞ¯[<âåsu‡K[©¦Æ„Î:½}j°·âÐž0e°™²9Ëº½c8g,œ¨3xB¡A1²´}`ˆ¥uÒ¹çÖˆÇÎøpõcli“BÓRê•¹í›5:,Ú}XCÅ8CÇxÂ¬f·@˜DÁg±ˆZðÿx'ÔX–á›µéð¡Óñ` ³®MEÇ)Û±Lißè(ñÍz(ñ!çieŒ&nD‹žŸ3Ä;Û#BMVÃ½
X¸p“FQ•Ò{Kõ½ºòÝô¹‹ü‡§ô”˜¹r~:næÿe¹.K	ÿ_×Ùû_])øÿu¤‡âÿLx¢2À<)ài i—ZoB·‚‘×/¦îÈìç¹å |©)Àí	Ç÷¬$rhNÄ¸‘Þ_Ö]Kú3ôqŸ
!b5ÍegpØoÁQdbUxûÊpq^¹ñ…òû­ãÎ{ô´ò†sÕrÔ•;§ÿüxÖþxY#¿q×zÛùõÙˆ -û¬_–êkòÅè¤Ëq›$Àì>û’ìa˜Í¾.SÓÀÌV•A9°² Ü-_b¥*ÀžåÂ
 ÃùÈÐê4ôÌ¤É™ÙO¡;ê ¸ŽŽ BezÈŽØÐ8›âÞÁüf™	f„Ø><x³ì€ð™x»\—9bgï8žÞX°øÊ~-CR"‚ÝŸ™Û¡©ötÉ˜ZTâÓkô Xò†ø9Úƒ;•Œe¼hC3Åû.­Ì¢å›ý—«ëÎûYa‡ œJîÆ¤Vhµ8c…‡Bg$û•˜M3Š“™ú~-ä…Á“±ø‹AÖ‹+—8RjC U.ÙžKK¡ÿÊ´YegÃ²‰¸²¿ÿñÏ:"‹dÕìˆòCÍ¦5w:þÞGÓ±Ê)·ÉáOåßñ0+ûµ6y³µ·¿»ó¢V‹ó^@.†©~»»S+O˜çË*©°€Àùø’ü…TÌŒ¡,ÖV&_‘Êx2pé÷/Æ¤³/Å­‡xóåÂ™mèïœ¡û¿HÅQÄflíìðF|ýÝGÒ«L¡mR9—7å°üåÈÌ4†àÚ!9äÝ²D~Ð‚þ5©œ ¥~ú¦§õ@cU®3
,ÇÇåp—É÷0K’þF8™¸Ÿ'3˜ÙÓ s.¯5=‹ …==ù:ÈE”AûzPv+àÏæÂ@Ã›‘â†—@3@¬@Y$n\e
wôY(ÈMAá?¹"Ô,„ðÕ3ÓÃš1Û‡FÄÖÃ•JdIØrÆ¿ “m”¢q¥L`kÝá'ôËÞ9 eËí$.SÞ1ƒËI9üÙô3~7¶?N1ñ±9ÆÆ•
;O÷¢@aaFat,¢?> 3;¡3/^F?_ÝÜ¨EÂÜÄGn<¤}ˆ&c]óOìHŠ3¹1"~IŒø¢€+2`Š²†ÕÎÆÐÇÐDÕï q–7ô&cx1@gc]4íïoìv¶	Cò;ãmc |(3þžPV|æÅ}Nx†Á$ÎòyV^{üaŽ#û3ÀEc^—(Rãù¼£|b7ÆÓ1ÿ0'™ÙœÀ€½&2´štój¬q£é¤8½]qf-šº”,þíp$öÔŠóÎFÊ˜ù‘–,«|:zÜÆÀGhÃÈ˜\EÍš!œPÛc–Õ€¹!¢>È÷äÏË|Ì;á/^gãbÚC¥TØ(ûî±R¾šïjëX ÿ¡Êª’Üÿª¨ÿ¡©jaÿµ–TÜÿ>îýoJ¹þy,šìßpœ½
]e×ÁÅuðÃ]/u½øx×g„<çN&p~™gˆ•ÄýÄl–\;á½ÌcŸlEZ&%–YWÇBûEÍè+:êüßÃ§çì€‚Ûp5"óh»‰ëTä]ðƒ~`VÐ›	fªBf7Î­‡¹[ì®+ÊÕÂÜcá~,úÖÀÓ±ØÌ$KÊ"Ân’Ã=üg§»»{°)=¿íNGJ^ô»-«ÍV[n¨vR»Ù‚?ïŸKÌ7¬\mÖ¿¢ËõDþ“pý×²V¬ÿu¤BÿÿQôÿ³†ÌOUò›c/¨ -­­XV[¤VZ±ðõíˆ^¼c»‡oVƒô.û?†Ï^õ™’Mw°ÿlHraÿ¹Ž”ØC?\ËÎ¿¢(u]bþß$I+æ)ã¥çAê¸ýúWuµ^Ìÿ:RÚ+ÎÃÔq‡ù×ôbÿ_Kšqcô uÜ~þëJqþ¯'ÍñBµÒ:ÜÿÈ’¬gæ_«kÅýïZÒó´Q4J$‘'ú8­k'Žœ0pÈoø@ô8ÁL,òé{wKÿ»šd–œ¢:õ¹ººÅÔÕÅçXDŠ#±¡îþÄù¥ÒÑÖÉøoûuU±ÃöÙq SŒ?£ÖybÕÌãÌÃzlCÎÛ]t¼Ë¤CÊå¸õ„D= þÐ‡U¡©æAÀ:ô)àšË»ÇÇ‡Çø6™´³6å–„ÁâãYNE>ìù$Ú…K¨©—ïM'<î—8è¥……ÿ\wßEJñÿ‚Ï¾ÕÖ±¼ü'k*óÿ?þ-iÆÚÔqþ¯QðkIËyÚ¼_ø¿ºÔˆõ?u©.I‘µxÿ[KZé}ö³øÕïÙj/ÊŸÝåÝïÙþ Ý©§¿ÜÕõì~ÏÏ¾ÿ=[âðÙ’/€Ï²O€<æ;¹žŽ@+‡Cê;ŒWÈÕG®ŸeÞŸÝþ5ïÙ¼ç¼˜2ñAïÙª_ôVÞ^†0”xâˆˆ‚¨uk„(à¼´nm&½šãÔ¸UZãÆ•ß£/\t
ƒ’¦‚e¢¹›¯v9*2£§HÚ¹Ú‹qÙ˜½X ÊMà~<ìžl½KÃ%x	¾™¼ä~MÁ¤C×F0˜›K…áá¸Aj¹³wünë [+ÏM PÞÛ™â¹_Ù4¦ÍTqÍáÿ*>Eùüã3Q+ö¢ðg4+GW«<OK´£¿^¼
@Ã¨¤uÙ¯)³¨²8d®	dømhã#fšÅ]Ì÷…l¤£ÌúrÛs]¦q&BñqŽàpÂŒ-A`£rÂ®ÀnæEAb»tèt}—ÚÛtàuÄÍáN¦.ª<|¾U"-Šð{èßúÄó†þ|(×«Œ'Þh,dM¼1VG}Çh‰®ìùYqEð‡JK»Å¿Gø½!Åþu 1ðL¡ÿ»žTðÿëåÿç¬®§-ü:õ\Ý„Ž¡	Ö„8SøÇÐyR 4È'û;{o€ž0ý?ëŒØŠùˆ1u`N§u«Ï²Vc¯é þg‡œ®Ë°±Œ)àîCó@8&É%ØQ!“¬°½0 ´úÆ'Æ´aÎkê[g°¸Í)HdËÂZw	ÅÄÑ„$]Üè¤rš"ÊT f¾<L $Å6A'£ ÇJàHê`†Ø€­òCb)w6L.é  úÊ+3pÉ(Æ j¯ì¹6ýB0zùÈ£}líœûvP_ÀìL(F8Ï”ZéxÛ°Ð-·÷&ü>Æ…½sàão®¶û¬ä™ŸuÞÂæÚ£Áá¤D'¾çf¾ó2oœÉ±ýŠåô™HP±Ý
.ù„7énèÙÕFuMù¡MþÓíþ¸¥ÉÊ×“£÷—ï^L¶uúïS_oùÎ‰<8=~h]¾µ9ìËÍñyíìüòâ×7ý+{ëçwÏöÞŸïÿ=Ü½0Þ¥ÉöÛëëËŸjGW«7ÞwÝñÛ×µ_w:ì¿V²Ü¶@“~ê¯°3‘Ó[Êœ?T2#ËÀÆ°—|+(Ó´	2ü@%0¤;Ï¨2ô¼óàlâMûgø{´‰
üFà®iúKpAÝ†ýW+U6‘§lhCéÀµS‹ë¤ô€K[\¬ýüµŸ-å×Ó>ƒšuú0PÅˆàüWøü?Ì®1fê‰n?ýüy¯&¾}7~÷÷Ÿ>üü#½œþô…š}ý_¿üòKp­ÿêêŸ¯œÝ³“ÑÞÃŸ?ükëý»þåç¿ÿKviw¿yùöèü‹~|Õz}Pûu¼U{WëþØýûø§ƒæ¿•c‰oÓ„žýôŸ7ni¸9k~áv!l
§)„Ù­/¾ ßQ1€=Í‡à³ZVÍ¾àrë"}éQè#÷©w3Ì„"£3Ñº¤ªÖpNSpÉ+aüó|ôS_ñ¯\kÎçzÃ+#¼Á#ìóèKÅõ‚s5ÿûü!Ã¯7ŒÊ®s çsóFÈO^Í¨È±Ž6ƒ"Éàìd>¿éb³fÌkLãŸMÛ»Ì'ÄüCqçh+¸aŽŒì“úýO¸?È•Ú’ïUÇ‚ûMU$áýWÁûŸzqÿ³žÚ¢ÖÞ0nÅeP¦ÝéË Ü¥ö´¯‚°ü€=Ã±q„OÁáPä¹˜s³§£>Eö½JÞN¦®óì3ü,ç ¯e£íxÃ>Æ r£["cêÄÏÍÌ)¬€·ï §<ƒð o*4kŠ‡]x›T¼R?Ð‹Û¾^ÝÛø”‘0›Dß—LL\×Þ!Æ¤pîM&ô< }Ê¨†h€w‚gL²cTÓe
ˆÏ˜úç,¾»¬’&61QËFñpo}F„ äQ®BJŒ	.®Š0bú€×šqc\Dˆ>/±T°I|ô ˜¦éh4\8ëz€ŠÑRª®~R"H‰3ÝN¹æƒ0\Tyw;åŒowì©à"•ªR•«@òbYáy/>l;ÿuÍõŸuˆ>Anóâ`P$=|×ÿ*´3zqÎ÷ìÏ,¤2Í@O¸èŸWÀ¿wÐ­HúC}Žd`»Ýýz!ÉdïuÐ%IÂÀzÎ
PÄ½nß7ü[‚0lu÷ðÍÉ‡­ãÝìôùž`t«ÚEBµ™R=ŒSE£¿¿Ö06UÜ›wR`Îè2êäýN
*¸°kQ×c—6{ÉcàÊ	|ÿ­1LB…Rs˜ÉU:¡¶E¬#<þs[ŠH´Šþ´ûK÷äðx÷–¤÷ùÜŸAq4ëÇl>†êXhýÁÞöO¸:åèWÒ]ÄZ†â>ýèùAR9ªÈÈ¦)#—S¹
ÏUÒ¹*ÏUË¢xÔ}š,´n›–6:éÿêFòþ¯5øû£ÿÖ‘
‘o½"ßœÕõ´…¾Psþçÿñç•­©¿Ï&È‹âßk# îü§TØO”6¹š!Ö¡Aí yÈgN„ò‡ï<É”Ob*9S²€5-Žñðú0ážŒÿ„ÑsE1ôÃ®@Ñj(ˆ™	<=d›‰Ó; ©ãššKÈÉ¢åŠÚûˆ
ÐH’Œmƒ8Ia	__1z,'dó\ `„µImË=+aàª½·sñ!9–lbÄí||¡zvDØ÷ÕÐŽÕ³c„Líj^Gô‘†Šr¸dæE¸$—kisØ-ÛYeî„³Ëž:ÊL‰{®ãêAó7Ÿe´©Ç9šÔQh‹Yî™ ¹ÚÛ¡î26?ÌAÒå#Òc’&´Ôký¢nÆûûí:™Õ÷¾gWgô²/èÄ„ã2ú3ë—Ãi‚è"…úìÌ?ØƒÓ’üÿ½4€ðÿŠª&ú¿’Šú¿²Ò(ÞÖ’
þÿàÿŸ¾0?ƒÈn¨û„ŒVû—œ‹|ÿ­uçN…6ð“`ÐCÝ¥H+ƒWˆþ½Û„3%pÈ—K¤Ùó_íñÑC5¨^h‡v¯À…öÿš,ÜÿIxþËr½8ÿ×‘ŠóÝçþêzêÇ¿pˆ®ªx¿ÈÐ°Cä1ëÊ?þC,ppÇAŠu˜2dì_ð#ô‘~cæØÁqÇ?15HÎLTÉ–ÇÏ/ë ç2„*.á4…vö¹š"Š+ºU¶·¸¢[ïÝa¸Bp—áÃîð¨)w]·ìU×bg®ÛÀ-^t„ûHÅöŒ0(ñ˜ðýa
q‰]XÃ©M_O Iìª&jyr—ÃÔÔ÷v˜F?³~ˆ]œèÎ(ïº«‹;Ï=»Â>ÿqt”‹ôpiYþÿ>€øÿYÿoŠ\—‹÷ÿµ¤™ù—Õžî»gØv/ÎÕ{H€‹ôÿ=ñÿ&+LþSµBþ[K*‚>­)èÓëê~¢ßBÉo	ÁoI¹oŽØÇ]¿ñ›_.í±Ø~ç\º@ý|´Ëeìr<›f¤ÀÛK\ó®•ÏåS‹ñ´2QkiI+fä¢.r*¸ã=»zÓæx…%4O€¹­ü²¤¶Á’Ê˜<£kÀrS¨Ô\5iÕ:K«,ˆ€Ç»G³¸07»Y±a)!®BÑÙIÃ%‘xQs&Þˆ¼àƒxü—
Å<ñ‹Ã:>–ø[¿¡ãÏûð§0>ÑÃ¾$Í;TÎyÒ—³oú€šÏo_ˆZÉE­ÜˆZÉA-tæHh1Nº‰³¦*¬&9¯Œrs…•	}Ø%ƒº¿;Iµü‚k´ó±ì”ýQÕaÖû\DaÌ¿ÁõM´€+š¯@åÛ‚PMD]î?EQž0{øõƒn/âd§>d
Îl<†é¡]<°Xpé¡½ÅÀÀ)L}R9‹*gÈ7§Á«nñJo$Š‰•¤¥üÿ=¬ý·®è‚þ¿ªößkLÅûß£ûÿû£=þ¥½€OgS·ÔñŸã*ñ®þ9èT¿¿x?\a{‹÷ÃÞ#‡ÓÄlKy4«k`K‡×;Úêv?ï|bY=+ñ:`ãñòQà÷Ë3¬X<ú=±=ž‡Éï¼x	Ü%©Ùô¢6à:‘ßTl‹”·*¿•k©Ò*C¦ãmR¹$²œQ˜ÃŠKäW	2lëoÐÒç>H%}JšäoƒùñË¤Ó!ßýÈ>}—ÎäÙ,¨²È§T÷¢JÀ¼k°OÀŽJÞ±%Ž‘Î,t´4¤ó|é¢&ìçIFùº·Íqc¼¯Yü›°º"÷à·KO¨Ëðß¶ç†pÄ÷\;eþ:d–ýäÔeË_PÌè2'L°‹	ô,·<ÜRD-¤=€µÿ àßbÚ1Ežvw¿’9Å¶ÒØ±˜_^í°$3	Äœ]%Å¬aäqcŽÎ’ªæ¸žW‚Ëû‡ìÅÝ2þH±­WÇ0OOÎêÛ5ozû¥›öÀ¼c9†<·±q*ì˜î™
¥”û§™ûŸPH:ì¾«Ž¯VQÇ‚ûUÕëÉý\'’¬Kõâý-iUrZö‚fÏu&†ûƒàéË=èØŒÃ×ÌçùìL†âWûŸ*½…Q€Ò«²R•ê™»—9W,ÀnXqh¬î;²ãŒ[<¢¯ô½ÄÕßˆç™Å»†‹ÈáVÉfãßcç2K(Ua«}¼ÜØ9|·œ62g›¤#îz¼\ùU„`Œ§åÍ;@µ©$×x1¿öW`ŽÿJ„V¼*1™ Ç:a¸ÁË,ÖPÚŽ‘ê’$—_E…}•¿©0pABy%)Ï8ãyÝI,xIM˜âUŽŽö¢²å´LV.•Jã	6hƒ>[Æ!7ùÛ_ýO™Áø>~ó8N@Î%Ÿ£xðdt³ÐÈòYèp8“§Éøä¢ÇñK ã{…9Ð8b ¤nö»ÑÆÀsØ^Ás^òþî{áÃ`<ÔÂ8l¦.7xŠæ)^,›J!¥ˆ™—›
âH‹+ŸE¥’QëÌŒÓîØY`”NûìýÒ¬þ§’«§¦¬KÿS•ýÏ5¦Bÿs]úŸó×U¡ÿY°®+ll¡ÿùtô?•\åÏ¬ÿ©|‹úŸl«ÛWè>¨þ§ò-éF“]èúŸÈ4+ÿI=¾¥ŠìêƒúÖd]ˆÿ¬ðøÏªVÈëH…ü·.ùoÎºúCt­‚á
]æª%:ˆ£°=‘DÈ;]}P¡oro¡¯öž®°—3i¸^Æ¯BÆ>&ðÅ#p/‰/ÂË|)]˜”Ø—(ÂÜJðÛ™ˆ~ù5(jÈÊsÀdžn#Þ\*%ŠnkR¬ÿ8ïÿõ‘A0âÈûw”ÿ*ˆ zp&ÐÆ8gÒ²’[VtK†ãÛÞævfn»®H7¥¥ìÿPñu,”ÿ„ø¯²¤3ù¯¡òß:Raÿ÷èö¸ºž¶ 7–ãñTc·ß©0?‰)àkêNq´ÑKçŒå]¬õœQ%žµLEÍLUs7Þd0
[r‚sVÑ+xŽ§pfÍ'ùñ ±†É2b#?7ÇÊoNÎRºÚÙW8¦sc¢*ueå3”Œ–ÊÏh<5]«ô‡ži+–8x–sP`üÑþV"-M(ë™Ÿ¡9CÅ¤gÆÅÀ›´Ë¢ã 0g\a{` *,À=Œ|”ò9Ð´o™04-ZÛ¢[\\†â3<Aÿ”fŸS9†VžšÁF°†4ˆâã2+[øŒÎô7ÉhJÙjÁÅþšb4Ü èÆÍ%[Ûû>¬8×gìWå½FªGêjª&Þ°gé$¦{äm.Ã´Ë/á¼ïÓ ,ÐùX–«JµY—ª²¬jZ£*WëÕ¦¤},3ûŠ—tÂèèö{bX V”wÐ(Sûcç
U<î8r'8r|ÜHXá­üXþEïò%œ6Ã'€íB+Ð¾VS6…Ù&üfþCw|üÍW6 yU~@Â4ô4üJˆ(Æ¶˜Š
‹œ?oZ2þÓ½$À…þ_ÔDÿSª3ÿŸŠ.òß:R!ÿ}ñŸž¾˜Žðz£$x10
9¯óî¸šžžœ÷ÎÉ@ÜCR—ßæÓ
æsöóÆ	'qŒá:ˆh=Ë"Éñ¶Ü1§gäÌÙÔ²gø­ vs÷tƒv=`ÙnSçíÛ2ö@&¸"FØ¤[T6p/ŒáÀ®a«¡Þ+70¾ä×“êó·º'±—#Ö
^yäV¢Â›–ª7Ìâöù,vˆ¥,6’1Þ€‚V`yÀncÇèý6:Éá;eäDB¯8±_‹Ð¥‡7É4,ÎOµ-ÉåÍ;æØâÖ½¾ÇD)%F
¤=1¬ Ä¨«í©50†íJï¯ß‰ý‰Áù²hÃñ™Ñ®oºÓÐŒÕV7£’Êæì·0‡wú€Nivìø0ñÇ£.£û¿g¡uZv~r§æ1¸Æ™7MPŒO{Ÿºýà¬òý'}Œ$ï#ˆÜò1¶§¢=™ úzH:€ìíåŽ¶Ë]Ôˆ±I÷Ç­Šœj$¬ßsoTìp-´%?ï³;ð	°n¦nÐVgé[Vg73F‡"ìÖPÒ­>mëºÞ õÆ:é—ñ \¨¨†³ÝÈ”ÉÔ\™ÐOáœAz:ã#Þ¤Û¯£ù$Pë$ç;Ô	+ou'Šzxbáó%ôÃM>½¹ð´$»¿³|,›öB¸çÚƒkú>„DÂŽÐŠmBƒmú%äœ*:¤(Jp*ã÷<OŽ)€¯°Ð•Ð˜ðàjÞw o¹¨yßý©	G+œ±1 fócb`Å™¼kÑ?PéÞÁ}è<aÝ ;¯-t0“tïh<¹Ýãè>0ó-:Ãc£¯C“sÍ×Õ×U¼ùûŸÿÝü}f£¸Iz‚)¹ÿ>yâ( Ú5æ¦`eu,òÿ¢Dñ¿Ì5ôÿÒP¥Bÿ{-i¥ÏÞ =Ý; œ[ X^Oûºg?Ú+HJ¦ãŽJ£Hƒ»‰ªðÌ½”âžae-fN>z‚³˜¿+ðkì‘‰{–Ä=Þ¯ñg¤*ü¾U1!£bŒ¾ëùÁÀºš[—½çðÂÿá)-o|l£krFÈ~ù¡[JÏ‡Wü÷hàã½†útåtÜÑÃÆø¨Ž&½{VúŠœÑGÈ®è<¤‘[÷sç]w÷–Í	HðÖl_‚b…â·Ûó:ZµG~wB‹ÞŒpä¹5Û¬ÿlÎíƒðqÉ¹¸qüùàGcÿØ‡ãŸ ÍåÿVXÇþOÁ˜ï!ÿ×hH*ðš®úŸkIÿWðÿ7;_OÿÛ?|ÛC+«† žŽù©œú@¿àÒÈùÀmLf?P÷"s¸/>Ê5ñ(—¤sv˜?ö>W¤ü4÷üÇ·¢:nqþG÷?Zÿi=©8ÿ‹ó¿8ÿgç«8ÿ‹óÿÏDý_ØV-ú³´èýGÓÿ¯ºç]—ÿ¯kI+ÞˆJãè‰ú šõ«ë~ÿÂs‰cÉS?{èoÃñÙ3É›9‡üìû#~Þ	¿Úy)=%×>¬¹«ÆÇDˆ3	çˆç0·“©‹)‘núê;²^‹|ÿA—9üQ‚Ô¦’T3Æãð‘¢ÆôW˜+ñÏH% oN÷÷Ie„+éŸ TSµÎÈ?Z0‹àÞ4 Ê“K0|¶1€Ñ¸Ö„éÓ7ˆÒ¦²©nÖ7µÍÆ†sï`ûx÷ÝîÁÉÖ·2ªœG]ãH*
Éï–¿‰Æñ»Í€=öIŸŸþ£é]ý{d­ú<PÏJêXÈÿÉJòþSgñŸäFÁÿ­%­l9e´o8 ¶™˜
gÍÚd†ìoäÑ6Óì1’áÐfƒ<I­ª¤WI–ó’«R–Ë:uÙïQºïÂè,hXàÃ Fˆý+hÇÈ
†‘G4ìb•t#Å‘ÝÀ]%éXÿ5H´7$Í1ÂJmÖÀ™ŽgšÂ6Ü4´"/YK_UÉ–ýÖ ÓFÝ$ý‰§(Lv‹ca¡’Lê Æ| ’AP-=OA3c48;0ô.–ÜN}÷§¶G¬ñì´ÃÆïOjÃY»þ-SAèêŽáç%s*Èž•e†ÊgpØ{›V 4,_‹_TMö»@ÄJF†;5†7"÷Y¡Å¨½ñí1{93Á²Ã½[ú÷“O¥ÊTÚÁ Q|_Ù¹ªÒÃüŽKƒKor^åÎJ[N@'ÙLRú-ÜÂ?•N®Æ´ã`“ %4£@Ç¥·¸‚Ù¯Ph¼tf´‡J»_¨Åèqö[‘ÜjîcL't”Ë½q,²fHH"øÉ`DùêR«£JR	ªqmcbNƒñ4è Â¬üÝò\ßƒæG_w'o’ý}·”Ol¤PÒîŒ¦Ã`Àì%Â¡yì“ün)Íÿñßžtz_§oBZÀÿÕ5%ñÿ]gü_C/â?­'=ÿ[<çÌõ*wžÂ¸Øèì%`j•=ÙA¼ mÖÂ‡@Î*fùNÆR²/¡‹VóaÇô“ðìÀñL'± ?†Ç£ƒU¼æg{Á¬ ±•˜9¶`ãóFƒë;»ëfØ^Ã¢»$WÞX½+ÂlÆ½MB¤âmÚ‡U¨84€FÆè!Ý †Í?ó¦C›¸^ ,>q)ê©“+(lø0¢¨“Œž lô•!¯Õ•’
ºðýÒ?#´_…‘&U Œ³Þxâ!-Vy'g4MtœQ"!õÂo0}ðZXÆ`È*jFãIŽ›}Â\ûîï÷¶O»'‡ïö~Ý:Ù;< I…Cy¾?qøŒ$RcÂ ·¶÷wÙ{l$ñˆ´XO(xa;i3Z’>ŽRæ*‹ã<Ý¦qB¿oD(4(F¶³u²5ƒ%röHÚØŒ¯ò6Óº~Œ-vŠÌÚ(4-öl?·}Qcj©ûÂ°ÃÛ?Eý°†7·‹qr@qV˜§ù™\„0=ˆµÑÀ¶‡ôÒ˜Põ›w"ôwBÍØkÄ÷¯­÷[bCSø>1“3X±4zøO¦Í'hupAÙ¶5¯Î Â‹R€døvO¶oÀ‡üfxh,‡
0±°Bv<¶GðÍäå+ØPàì0Ùf„ýJï-> Ç“må»é?rùßèUonJóÿáfWøãÖ±€ÿ—äÐþS®Û/ëLÿ¿¸ÿ]Oúm÷àíÞÁî§Ò1õÇ°Sþ¼ûž{,ìÈU‰ÿ§ôÛÛÝƒÝã½íO¥îîöéñÞÉ/½Ó#Øw»½÷{[½w¿ð§{z„Þ:Ž1\™þh‘.åÉÿ+ýYZ°þõ†.Çò¿ZWØú¯7Šõ¿ŽôPò¡
”Óìœ[€§}°Òþe'ðm!ƒi†Ï^3ÄHT)§”qªÇ„šÓøbÚÏ½I%4ø…ÏbÃ+|;²™„!V„ò6>¾Ÿ¼ßažzÜ‹âa5Íe<xÄoAù‹¼çõ.ýï2Wo|ßowÞÃ)]yÃCÕ’£®ÜÙø8ýçÇ³öÇËù-[ìÙˆ -û¬_‘êkòÅèdbøðP<	€ #dÃìýÃí­ý¯ËÔ40³UeP¬,@Oˆ‹XìY.¬ 0œÉHÏLšœi‘‘ýTc¾¨# à5à{$Æå =dGbhœÍqï`~³Ì3Bl¼Yv@øL¼]®ËÂ=ÂÎÞq<½ñÅÂ×ðŽÀ¯eHJD°û3s:œE ka›	µtBü1½†ÝÂJÖ\„ŸË¡=ø°SÉXÆ‹v·å»,ÓÌbJ/Z¾Ù¹ºîl°ŸvÀ©än<ÀAÊxÁÙÖËö~Ã:c—NÑÝO	sxï—fo¯{òµDˆí•ø…1è”«DX­i¯ðñÅ \²=—–x!Ü6,;gï1ÐY$,íäë}-‹;BYøZ…ÌB`»RP¸œf¡ 7…«k
r*œåu*ÓêÁp.P¼fhëfh¾ xØVRCÆf$ùl˜s‡=:ÈM	CoGñ¨õÇ>zlIÆ™ÞÏå7ª=¼>‹¾ÁTý;£Ãq”Cµ¿[Òþ>ÈÊm2„•gÉïìäŽªü`“êw°X,oèM:Æ4ðb€|4fü}ÂƒIœåó¬<lþ0‡=ãÅwÐ˜ ÔV\¢H1LB-ñ&L` íó2Ó¤›‰!ô9“§·+NñY^(>¡ãÛ!âé%XüÛáàžUP¡3Bq1ð:ƒñà†f<TðçtÌÉbÅ4›9ïlŒ˜nTÿÀ‰‹œJ“Øßo2º]ˆÞÇÃPÎs9=2ñ8-¶ÄŸŽ·1è+q:“«¨Y¶ëTpþ(ccû[‘1	¿Ècxä^|QIm|icèjð%;“r$~Sw6VuÇœ¹ÿ™(zÁQa­?¦E÷¿;sÿ++ÅýÏ:ÒÀE'P°z0ç¬â;£‡ „|U¯ÏÕ»Â‡‚Çn}‘î›òõ¿˜¤±²kàEúÿ²ÿ¥®6Pÿ_U‹ø/kIÅýïãÞÿŠkíyÌ;¸ð68{ŒÂ{q\\?üuðR×‹w}FÈsPp~ñf¬| î'Ôcû°ÿ““"l}²i™4Ãÿ†¹ê:ÉuEÍÈu]—þoé9;`ùÎNn®¡JdÒN½ŒwÁJøagëˆÁþ‰™ªÙsëa.sEçjaî±p‰}k¶`1È¢aÐ>Bo’Ã=üg§»»K"»ÈÒóÛît¤„×n¶gÓI[V›­¶ÜPí:¤v³Þ§¤½wÿ4³þ«½Ý7[§û'½uÉŠ.×ùOfö?©ðÿ»–TØÿ<ŠýOf•=YÉoŽP¾ VX =¶´¶bYm=’ZiÅÂ×·#zñŽ­,fÖ]öÿ™ó?‰J¼20‹î‚ÿ]CÿÿzC)Îÿµ¤Âÿ?gÈþÆ#ù.`îàæ–.`¼´#›¬ñ-­ÃñK<²9®^6c|ìý»ôðN_òæúaý¾äSWé\¿,QÓ=¼¿,…ýŽ`æâ.x¾{76ÏŒxµó0Þ_³sx´{°ÓíÅ¦¨2[ph}ZûlŸËÕfUêÉ¥VN{„Iß<GwñÜ3LÅF6ðßÓ4Kô3·Œ7Î9‰Ñ°—*4¡|DÅWç\æ‘½Ëñ€ 8ôÿ­bÆJêXtÿ#ë‰ÿ—†„ö_º¤ñ?×’ŠGúl³³W5©õðd/jvÂKÁ_Ì›3Ï%°W©Kÿ,÷Xxt^UsK6L’mu`‚‚>Rú&üáMú%Ûj“8³ä™Ÿa¶¬!ü´8énä$õŽ)ŽÑr;ìö7óp[ Á?ÏÏÔd·=7 ‰ƒNbÌGÔƒ³~.fþùV˜{ó+R‘ŠT¤"©HEú¦ÿCŸ¿F p 