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
# ---------------------------------------------------------------------------
# Rev History:
# 11.10.2016   soe  Initial version
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
CONFIG_FILES="oudtab oudenv.conf oud._DEFAULT_.conf ${OUD_CORE_CONFIG}"

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
‹ Ç¡ŸZ í½ÛrI¶*ûœ}O>~ğ‰p8|r öÔ&.…+Énj!5gx3AuïÙ-w• «Taª
¤Ø'üà?óê7‡¿ÀşÃï~ñx­¼TeÖ IRwWJ$ªÌ•·•+W®\—¾íT<pªV«íf“°¿-ş·Zkğ¿"£^kÔ«­fÓhªa4[µ'¤ùĞÃ4õÓƒ¦ø.™²‡3Ş‹~„&©óïN­3è^0õËşÅÔ1{şkÍ*Ì9›@€šaÀü*4Ÿê´%‘~åóÿô7D¾é_’Òò@[Ù³¶ÉÊÒÁzö¥iÙ>é¼Ş /¦¾íPß'»ô’ÜÉ˜:ù-éM'×ÈÚ‹İŞ:”é™ôœzÔöÏô}Jj[dÓhÖÈë‘}oz~¾AzWvğõF¦c-½Ñ‡æ˜–yÚ&Ú‚ƒ—ipázâe/ CÓ!GôÂÙdÍ¥ş:ñÙ³²Ëı>P¸c(İµì ,½²oúÁËÓ9§Ö‹k>ü»fÕ­fÀ<Ë	½´}ÛuYäíxêM\ŸrH/ gHoàÙ“€.9§ğç‚Û®9Jx‰éS‡\‹âH¸õekN/`}>MÛ]“©O-2t=BKÛs6©09î4 §ßí– jxÅÚ=„i…ÚØELüíJårNû8:>b>’8@qºôi…á!ßV¹Şõ6|­åêV¹V5Z„ („ì9v`›#rI=FÈcÔÊ†yÚ2OÇú¨! #…O˜Ùuˆ;DL–`q–ÈK¨ÔÛ?™4ì>Ğô[lGovÏNNÏvwV>*ß¶KE@›à—^ÙõÎ‹7¬]ÇÂ>Ş¿nÖÈtïÌÑ”ú÷èPá»îIoïèpf³°{Ô9>îîîOOŞt‹dÁôp×ì(¹çdhÃs2¡@X ö‹£^w§øª³ß»<À>,A2ÆÕÔ{y²w|zvØ9èî¬¬!†;@gÈJu½pzp|¶»wÒ}yztò§b%OŠìá«½}¨}å£–á¦¢/¯¬½ÓÎÉéÙ·İÎn÷d§È¾!y2aªaÚV>*µßµï8†Ãs1|7ëlÍ’•gÅÂAgo¿³»{Òíõv §ïz&,Èòà¢Ğ=99:Ù©TŒ¸ÿLrp¯¦Î ‘ê>ÈÀÁ-wõE»Èß<§këäcœ¶îÚşdd^óK®Ñ)ÄB†ÔìÑ®{àŸ“âŞá«#²Í+ŞˆOò¥‹K”lò®î½CÀ‰Ã—İç¤´K¾6ÂÚ=„Ï?òÏÇ°Ú¯\ÏzÈÿœ¼K«„ÒE²³ÊÉZ€›Ã6wø–Qü2­xÊJÉ(î¥\ĞÁ{¶ıxt2²Œ.e Pú%‰¾—ˆ¾ÛdàììÚà&ALzãe€Kºğ„LÄ#FK2J'¦<MˆoÉiåöİsF`ƒÿ¸ô©ÃÏgÉğĞ¸!¥ó€TÉ»¯qw
²›/GÔt:õo§vÀó­|¬İ°×t{­Ì£xéå«„=Ú…›ÂÒ÷ºÔ¥uÀ‹Ó¨À3†e<y¨¥ÎF}m½ğ‘õsïğøÍ)l’ÆWÛÏnÒ%àuÍ÷” gë]ÃbpÎIŸÂ‹í è59ulW:@F`‰Ix²¨ŸÁønØÜÂ9)ÂR\'ätï {xtp‹l	)şİW*}5.}e}õíöWÛ_õŠë_­=9É.êÌ)Ìv(}‡zşˆµjõ‹j†gü½–¡œ’d!ê›ƒhÙ††|S$;D°ñÅ ³JvaV^VÇàÂÅüQ› pÉ§€RR2•õ–ÔÖÕl0a6XRò£aƒğÛÕ®{Öj¬ö7Ğ^ÖVËÕª¸mÏ¢fÅÎí]jgƒÓ²*=MöÖrš¤MKœ¶çÏÓúô…~z#¼‡ Ï!‰T7dŠHœt³d:2Ôã;x æhŞÆ—Â<‰Ñ$Ù@rf¯®‡{.RWØiÜ³J®%;PTÈŞ…n’—ÀÅ0Ğeò=‰Ï‰9v§ãÄMï|ŠGd¿Lz°¸¦l[Cò>p=ä;Ì^Y­¢¶h0YÃ­}}QøÍ¹ğU®„±€bÀé;nÀ&ÕÇíŒ!O;/nT_N:/÷»!wsö¢Ó‹ôÜZY1VOX{h^šö¹G­?†1òKw:²„À.ø‰û¥û-ÀŒ\Ó"oW>~{èQ)ËFªàêsûÛsa·ïòÃù:F-µ|cnù®çÁas,ÆEèÅçö†g³ëMù!¸ã±éèàjw gù
‹
µ>êíûŒ³JrÙ*F/‚[1ŒÆqÕ@-€C9Iüú3¢¢×¶X ìxe±DÂ%¡![sÁñ„…v¢Œ!.ëXW´* uìx¤;Š82Ög%V¼ß*ßg‘ˆÛ|óC–Òş­­õØIå($»2Ç$>ğïæhäjËôwsÉÎç½ã^9¼ëü^	3KAÉM‚øëm:¡c÷ØjŠ5_óaÑˆ9ñÆÈÚóŠE/+Ît4
³<…e Ü©%WIÕšRÂæçzæ ¼˜«ĞQºƒ2Î/ù¬ŒS’VšW™ÂôbSC‚ÌÆ¯ ÄvG¯–#YáB!!½¿ qÜ):,NHabaEáÏ».H–Jfã,•ÎNqLb¶8N`D9-W’ÕÔ»5#<ïmB
aÛ¡â°ùl'Ìn.ùô	Şü†”¬ØkµZ­FjÃºöqPp™+öB™¬¬‘
F[b‰ÉC!ôzœ ôá)‚çL!N(ğQEÆ¨–8â`±À÷ÏˆIÕ°’sf¿ƒ5úäËÈo‹ÓtEŠŠìBë~Lz[gDC­P93ÃÉØL>pû—‚²ÜißKö®`à™RÔ:Ö¨ñŒ_(ª£®ÈtBñ…†Œ`ô‘‹‰)LÛs˜˜?¼ä)Šqá<!®·s¸@[½üÄsqùáF+véğÄô ”‡ñó(M..ííİí·»Ûr¡á±ˆ3ØğDe°/¹Ä°ªl—ë1>]yg¯“ƒk‘Mah^k{è.æãò½Œ?ÊªÈ.#¯·NNºÇû{/;§x¹hUw]ÇÊt(¿“­‘•gêÆÎh!µĞû‡4#AãbC[Úbb‘KVùBY#6°—ÌQEhp*Q$+:hA%Ès®dXÕ¿5
˜‰ËÿW~u]0f‡PÜœAğÜ± =M?†ùÓNfÚØ5Ib0ë”¤0éòíì3VÊ)ƒÁÌ ?QkfÑŸp“¸¢0\—˜'}…eqøÇíR1U
}SHÁ^YL} V>¿+:rÃ‡é7b‹LæŸµ5êÉÉ»`Œ¹š:’*ãJã^9K%~\z6|º†'[4ìó±çN¨ØÔÇ–Â#>FQGv¡ùü±Ú'’ÚQÈxÀ™v ©ŸëHÇğB:cÇxãoçCË.°ÄÊ!â3 Í¦?°é˜ü¦¯#ñ¦½d“U¿òç•J©²ªb"”úÑ…íé…9xyÉŞ.–§£Ààİ&ª^„ *GŒ7…ÓK@?Èà¯T>~íWŞ:Rùú&6tü™€ÿ,rm+ SS¢–FómH[nüBå©¸öéQïÎ[ˆz=uNÖÎ]†ÖÈj"‹¸¥–V÷º$!ÊÜ·­ÕÇéT¬g¸Ä$DGÅqT4Q0Æˆ<dÙxÄÛßí³_½p+ÕG†–p+mq’é|ÿÇ³#¼µX3¯Ş“Õİ×{‡Oz;Å·Né-œİ^±Å¯÷^t_Âö°c|ÍZ;M¼2È_IåÏËò`*HYWjøèí7«XËêÛçò:µ¶Rç»¼ğ|]À©~MnğÂâ#;”°gúŒ“uÖVmİ…½¾²`všF‚›Ÿ?EÉi2Ø(I†^ßˆ•-?KvkïOfß4æ³³´Ùal şRVT‹†-N—aÅ(§c?eFpõëÒ§Åw*„–ZvîNÅ$y+ÇGÀÂwvöÕÍ's3­±í,°‘%w¯Ô¹ÊÜÃ´.eMkª@ı³Ú¨éŸ˜]NC;§b)Ä R–®‡íâ×qoHEÓXº‘¸Ş&¿ù+àú!Š¨F¸$®7k©È~;¯Í¾ToÖ4ÔÅşé—æá‰t'ÈÒçÖEÍÓã'©ÿÍUø>‹şw½Q­¡ş7|j7kÕ*×ÿ6rıïÇH¹ş÷gÒÿÜ/Eÿ[(›ÀŠÈë9•òéªß›eøÿ@ªßF=^ĞvÏµ¦À`Â	9£" Böğ:ÒÃ‡AX¶–ÄrÕÇÙÊàKÕ¿µø£êpÿŠT¸Q_;E[Qá*Ü	UáŞsR“o”†G‹«lßG_{qeíd›÷²!²©7R~FéD÷ÂÒ¦="Bî‘^<×‘~Ti’ëHç:Ò$×‘Îu¤siA"_z†Vv8æ™_®!=~®«|K]å%éñ~­Ò\ò¦?	Y»‡ßíÌÕ–ÌV´äõ¨-W¡¼Ö.Y‰ Ş^S’Ÿ~ò`ªãm{»ËÔ!C²—¡¾8†ŒŠheMòy2ï'İú•·•·¤r¾ş`z”KÑ“üÅ«Ò	²›ÛR-ˆÔH‘¥„2ûP	30û©r‘XÁ˜FÙº§/ãĞÂ6pÆ’Gñ4kê(§¡É³yQZÃwWé{ä´ób'YQJF6gû{=Tàz]—dõÏOW#“³Oƒi -7`sØ^OîEb¾ïœ¢vÎ	aãÙ °Á{›Ò÷8¯€÷è›€”‹Å°¥»ÓÎMåšÍD¥¦ĞÊ:¥¤ÆW–Aƒ•8B-8öÚ;¼‰Ñ€èC[bÅf„5ËÏŞVŞ®Áïõ·ØŠò³•Ê[£²ºuM=D…#TE×î6ø8+´´(ğzêÓYh-J0eÃB²ı‹­!v@÷ÈêÆ*ë‚ìó‡^1rn;±	Ji÷±Ç7î[G ÖûÍwÌ€JD––ZášK@+rSwB\TXÔoã°8ŞCbñĞÚR)œ¡'øÃŠ,ô.¢ + ?4yS‰kàsé|"T.·"ô‰}‡%ìƒë—]¼ñË>Ó²,ÃŠ–CjËU/y¡Ò@©w]?†’ø
Ki½®¥BšN6ˆïN½Uy¶r„¢
½JåîäkË‹*ü^béYáí¹ïá!)M¤êĞß3Õ¯İ½].¡5+»Çè¡«Ïuy¹ı]ø®˜€òTË­‘ñğÌ<dbwÖp™•dn1?6.@ïÄuNM­m¤¨5Drà¹Wøa»?2÷ÛïŞ­®'(’ ­½Úæº.r#àÁ_x0³;¨§=!@¬q^fµò¶¸ñ¶XI€¨¬G9*ğm]—²ñeL;gà™ÉİlÎılå£œŒ›³°i7œ¡WAgO¯Ïnõêáœ ··õ:&¨õòèà ƒ¼¾8íŞT8ÄÒÈ‚Å\*]¸~À:Á,?ğÛBz‰)Ò§55àÔ±Ç|Ø(¶,Dc3Fól×¼óÕ¿ûjº
ç%€´èøÂF®Rl¯Q¡RC®U_i˜ú‚Ñ2”Ê–|Z¹ÎeRú¹B`”äET¬{‚ãP»×]q„x†_
Qa”i6ur-L}(>ÈRò™Tåèd»²g™¶ÇEDœè’¤bÄH®­±g¬ëô!U|=í‹‹?àÉnÇìk``Û¿ V\üM¼&m¿Çe¹WÎ°Ÿ²ûW6¬º>œ(©‡–ÕÔ*Ca‰¢›¾’….:ŠøhùAKì’T˜!ó9çğy©Q­ªÇÿÄä²¦U¡˜\76§l
ÑˆÄô]UÂrü¿r­W©ÿ‰H<|ÿ¿õf=Ôÿ4êmÔÿ¬5rÿ¿’rıÏÏ¤ÿ.¸_Šş'ïĞ¯Wÿ³U†ÿsô?·ÊÕ¶–çÀüo	ÙXû8Š‚×•·×2Y2|/zvdÏs…Ò,h?…ÒjÙøÙz~TµÒÓ?cŞìï/Ü!Ş)9g/8i:½ĞÂ»İãÆmà`‡Óqtï{Jß³ÅúÒIhÍUwŠ¥’ü¼@;¹k…¨y52ÏsÚŸ³m@¾ATıåëÒ†“²Â.TÔVÙ;|yÒ=èvösÜ;`í¥“›û-ÎurY¹Nn®“›ëä–¾$Ü…Trs¥Ü\)÷nJ¹‚·K*åæÊ´3ÀåÊ´¹2íÏJ™vÙşH¿@EÚ`ÛŞowB6€# S¥*£>†’í2İ‡æZ£ÉŒ¹Öh®5ú3Ö×sjòx²P€‚s¹õ#™ãÛ¾*àÓğwgs„Rqå«²ãi™¤i½^DXÓG9ætä’&ÎÈ¥ï‰ÃDñ…Ãî÷gßw»<<Rd.oŠë…£ıİèœ¢Œ7¥•xp³¾ÎŠ¿è¼üã›ã³^0Wz•B!¢•"_áQ‚Du"@=¬bVá¨	)…õ)ÚMô'‰uTo„é‹QÅ7óáÕ,ìŠSï\Ü¬
Èjd½K¹ö0¹¯§®¼ùÅj"§€Kh$ã|›°:-tïxáWÄºèºÊ“˜Rfk®ÍªP­¨İøíûÄòˆÆET”¦Ë*à19¼y*¦’İàf>,2³+õ¶(…¯TUUEIÚÜ‰ã::x~é:Cû<šÆZ,h+µ¦…”£Šª‡Ëa–ƒóŸø1ïåÑá+ò<«×sº&ƒÈpÿ}‹]Fç0¦ëÚ[¹a…®UÌw<~G§¬Ê×©…rùU¸VÍ€¥z
Š‡j2ñgÛÊç´QÇb´bÇ‹kgk¿H]Ô·P*^H¡XÔrg…âùÊÄ	™6ê¥vy}á»İ™.†J˜P‚mébšV}â,Ô×Ù#Èk°m>ES<ƒ¸Å6ÿyúã)]¡ *÷±H]’­Óx’¤¹7&%/}eÆ Î¿™ÉîÆ¡«vaèN×_£çå$ƒ”ÒèõÌ‹KiIªŞ¢y¹ª÷-ÒçVµı"*ÿ–ÏB1ëƒÔ1[ÿ»ZmT[¨ÿİh·Vµ†úßõV£‘ë?Jú›ùÏüÓ'OÌ9ê‘¿—¤	Ÿ=ù[ø©ÁÏƒøşOş¯Å@vNOOø'VâÁÏ¿ˆeù?ÄóşäÉ¿>¼lN&#Z™~€
Àx–zÜ0şOüõäÉ¿Á|csàáHñˆ7âÁNPyVäı÷_Çò¢sD÷‹~xòäÿ-ı?ÿ€¹ÿÿÿğÿıßø×xDû2“¹éê˜½ş[u£]¯ÿF#÷ÿı()·ÿø<ö¡&şÏÙöƒ§˜%.Ú	PV*²Üˆ‡“Í­@Â
¤š´±àt9QıD°K!„È ü ¾Óp1Ëi¹ƒ÷ÔKµA ç48C¨>kòû)˜«À»^ò …ø	¾3=Õkî¦Ğz”…³fºõ—\·>i—a%¨«áäš†!°ËdÉ]r†oØ4¯_×¬/ŠšĞùE§÷íYïèÍÉËîÕwpèŒŸn¹¬LäwY|#±Æ$T87#Ğjk¬Y¶Çr ‹ ûk2¹²Hé>µêûîhà-{p u°¯ş-sğU‚‡sı˜’’Wò/Ssdm¼ßæô %.…â³Åm^$LìYıÂn÷UçÍ>ÿÙå~Øí¥B&q+jyÄa^ÉÄÏÕz.í*TäS®¬•¬½ƒ³İ#8âjõZ.5=ãÙşÑËÎ¾š‹ySÈÌó@ŠÆû äÂc‹ƒÌ\(1“ugæ:íïwN»=‘c	2‹²¨ÄñÉÑî›—§j/&Ì„,P òÛdTHY†ã+£V®•r½\Md|uğıŒÌ\j|Òe¢ã½×;ENÏØ5Ãb!·£bäW€‘3fâ&ûµœ„›)•zˆ ´øY.k½Ê·í’¢&u³Pö”®)%¬,«"+/ëØª«5g`Š2,RD5œ	ÜPğ;F-g(¬\6HªÈ*ÆÀÎ¨K"1dqıÅş¨SËç›¤MŸÍBÅF°2x^Á–˜&VynvıJ{Ç$î@ôG$§VSaÜpw"…æ÷Mâ~lûW MÑ33zÀ!‡zúĞÆè ÖªaLHw4Áê\¸qÚ¬ÍXláùÀ“$W¯Z^6|
™Ö'C®íTM›ˆªE«¿%æX©8A.µVÅè¤Ú]2FÊ'÷­T£¹JÅè|×‘U†ŸoYÙæ¥É‡)GtŸÌ4Jd9 Êİ—§G':ã*tLmI4"ö*Ó°æ¤ÃÁHùñR8ÈekÁ5y‹ˆ=9=ıú ½ç7ô;Ì>j0Õy'4D¥è`ÊšQ¤2,ÈX¸]¼·ÙÍÕ®•ÌU§Ä=BL?.£üƒë,kmJÓÿ›a ÀÛçÑ`ê9ÄˆÇïzÅÑ"liø25n;o‘¸³Ñà(­„£×GzPoŒU3ºA]Ë-¯”wN¿Eu½¡íù‚[.†G½²akò(B·§Z Ö)hL—W¡Õïº»gğÿÜ(:`aXÌ(WòîQÀ ôÌ¨ì	^í#f¬oª×0¨!„JÃ\3‘m¨û3¢‰²‰Ó:(•Éän$ó}£Âš·æÂqLoLÚÎzË¶Ì5Eª3
‘ÀXxcW7OUÉTcLnH‚õ¸!),>µb‰¢Èj›):HöMäéWh3‰]]è¶°#$´FBÄÏL¦øš(—ËQÛQs&Gƒfä!„1¥ê£ğs`öÃ&jŞ~#_È9WjSÍÃ	ı¸¶ÈŒ±ÕÕï#ÕŞ‘ïÂæ‚æ·î0@µ×÷BV=H(Ú@-eF°ÇúCÏHtæ=};"\5[m#’Ç¡¢4-áÄÏ©Šç1â–¡=_˜ZNŞf‘“¯›ué•
ó˜Büí•áï©ß.jeŠºÑ‘X†³-„°CÑñ$¸ ˜P>Nò¼† ™FW°*š·¦f¾Ò©~ŒÃHhà3Û#Ó¹ÖaHRÅ:ÄR•ï‹i4O@ºî}Ê}lÈ}uğÌTÁáğS€@“pœaì8ÏÁ‘_Á¦Hª¦¨p¥"Œz	µèµªÔfZô¢'áB^
f`_ŠıGïnsYøv{\»+-Ç~=˜Ñ„Ê;š~ Ï$Œ3ò qŠ•…O˜8–§Q[6òûld:vkøw¸9â¼X54 7¬£*­æ”-VÃ!øpl€M…»şB‘<<	ëÂ‘0ÒºŸÒ˜İ‹âŞ;dG?=K i»²
Ñ`ãó 6•_ª¦Ğ ê
SŸ|Œßô2wr–ğ=£j^#æÀš	€Cö—Ü0œ#˜–Ó7h‰W¼qœ*ïîœ‰—E÷½æò'& bgg$hÒ2÷7ó-.V€G~0¸kèÄÆ¢Öş»ßEÛŸ|&o9Ñ´Ğ;‹sÌjãn¯Û]¤•¢…LÎc6E¦·hÀãÑò¨rÑ%t±äÃ)Î‘şëqk€­”¿cû("©rŞ‹»9Ñ3&àMÂsppŠQİÑ¨Ìn?C€|w¾Î«û|DQk„·j;¡»Zà[lîÚJ4Êë‰’|®ˆVşˆw–•&J…‘T:£¾§"?¯òfÁ5gÙ8èıİÎ19FòL”¦ cõ8Î²öô¼"ëY¯·ŸÈŞa&©Ù™,"QàD±³Åd“îñ-Öõ£ôt¡%7pğ_Âæä(!jSP›f»RQt¶Y•xtõÇ‰6~{zzLô”ÕÌÚKÍuG*Ì/em-İ÷¶uN'ÉmSİ1ÅÖ*1TÖò!6N>b8õÜ~×<b¾:	³2øa\åÅø˜k­#¥ä³Ä×´TÔÏ™Æ¢˜Ji{á(&ÛH‡Ã<ÑšÍUÈ$LXôéIzÉPB|4Ö5pwTÓ!ßX}]İ)µ›¯»‚leƒ¼İeš„’Â™±Ê£z&DšTBÛ Ä‰Q¿ª½©¬Ø
1‰ö¤ˆŸpU ŠyÎÄ³`HV¿*5}òUÉ¨áïûØÀß>“=’H±ïÅìõŠ+k?º¶sÖ¿&È„Èq#ş"’„Ÿ"£W‘Û´E›´ròÖåCR3eF?’8I;dy ×fEºb”îˆšd8!Â£šÔ	Ù¡›Â=˜•µLKóUÕÒ|ŞèsŒé6¶ç¥Ñı£ÚÇÕ&=Yˆmâ¬í«ÓÉê×Ü¬ŒG1x2´×ïË ,aT¿äÌ‰õÅõ;
-­ßW#ÿóÍwâBİ©˜!OëD[íêA(ÁÄ„+æù—ß›*§‚èd$;ó kÿ¶kºÇNs;+†¾•¼Gõ`—¾;±C¡Úõo§Qlp•ÃU¦¹­¦i*êê…ˆn¤MGÈä¹VÀì	-“ãEQ6ı€§!;]3Q©R(Óè5ÃíëÃ·CmCBeKGTWf“ªk¡7<~NN?#+x·£Úòå¢.çüKVjøŞFX—Xï+JêŒ&eEq9‘LÚi/+JY­°Ó;)0£"î–Õu¶İW6*^©LVeB&İòKƒáy	/z¨ÃÂæ	Nï!´³„¬9Q§¨ëû–yjXfmâô¢ÕØ{à*OºÇ‰Nª¢—eê-)’‚]‹S¤kwêñµVN¥HO%MÂÊ>Dö&¨´ä'T˜W¦İ%/dâôMERåXGº$åô¦ä9!QßÜJÏÃ"<´`ŞV½•‘—ÍäGùònnipïNyïG“Ši´<.dÍ°ÆJÅ…v	W,¯*µKN*ùãÊé¤R".¡Lˆ'fcw›NĞ
üLƒ;ÍÖ#ª²|ş-,ÚÅuBl7JÕÚI²†™bqp°¯q<]gîg¤pW&FZmR¬Ä
VoßÆq	ïvˆ§Û
n‡¸µ½¢KQíÛ¢Ü¨iYñàM{ ¨Ü’ZüüyV›“^[¢?  ù‚RDÈÚÍ+Ë"-MT'oK6F”t"¦…v'hÅ‚”XE`»‡ßİÏ†3Lâ›ŞéÑÚ1 2+Ÿ²À ıy	Î¿7Q!¢BúóX¡PwPI;ŠRâı³3MÊ”ìø<–]i*ÙµçK(é–ëÍ
ŸÇòK}Üx7äóXvÕrNÍ®<O/!Vâ%äóÒ*[M–Óº²£Ÿİâ5)$F+¡<OÑ¥ÕQıùŒªbåÎfÍNâ\”V.¥kHã”uGÈ¢S²Š€Ş‰¬üyZ ·i°ñyZv Ù©Ùá¹–]¥"26Zgd~':µâÜ¢p½fÖÑÍ¿;Åİhâ(EŞJá	Ñ
s`n1x:•%YÌ+íVĞê"¼;ô/„)ÿ˜L5(|ï€$ÃCÅö¾q(Å/ôâ¾V<º¯Œ‹ú£²Â‰WfçáKæ#€û’å\r¦ÈOèZÇ4éÓ,_xTÇûÍ?Bäâ™$ ä1ŸÎì2ò)¾Ûã÷µLÇy#ç0+UD²2SÈ6Ç
¯Èò>#äİ;ãø:û{ĞÁ;ËÏ!¡BÒ_+?[ßY[-Â¿OÅõò3¦I¢³,:eÖa™0Ö"Œ•OkÊ:€Y_©¼­UVS |ŸàØ†ãèÔ&îÆ`Ò¿*UqVL‘R¯|dŠßƒa*†ào´ë}¼Ûâ’Ô™X ]=è±CŞØ%¯¿ş oˆéy€ètÄ|Å>ÄE7¢Ş{…Œâ×<Ñ×’õ}O°óĞ
ÔlÊ”'B8l^Fî€i2¸d>Õ`<„—hR@xjzĞ"åqM¹ıC/j¡Lé‚&úÑŠ ’‚i´ ÈrĞvzá×ĞÄOÁk­9±æ.Ö X¡%5é¥;»Î1³½ËOÙéÂq¯X¾êÃşºS,*Ï‚ùCZ¿®DĞEÓúşî]LßÃqÉØdLM)«@‡ËfGüŠÚÇ´qœç.FŞBb2B?PdÍ£,–±RX!yÑ (ŞO”Ö+fOÙ&µ¹Å[vEá¿Ã]SoğA”ªpß¹¶s®şa£û‰¬ğ!eİOıåp—Ë3Ô¢L,!‘áÆOQ½JŸØ|TŠÉúŸr¡"Pfı†³í¹0Èk0/áğÑğÉvˆFTB‚^àl”ªÁ0ÒÀ€ µ° \œßJ„“²!Ê /nt+ƒ¯×))YXW®wez–˜³Ù˜'Û‡Mğ{ğÅ%Ÿ°M<p¡ì…X-b~e~˜š+¦T›¸Ø8¨™Õ+è ¡D8ğLâĞ­3o0GÉz>*@¶}#„Ä‹	µ¼Ø@j0'yí² àŠ´¡æ;Ò_¦ÔG—ôš%ı Lµ/ì¥­ÛÒlÜhÄ¡WÇsæè÷y~Ö;=YDKkƒTìZ×À%lš>ª•Ü(Z`FBİmNtµ¶9…ê±BòÖlN±˜.¸šS¨9CUnNÑ¥«ÄÅ0SÓ\Œp"æC–»­´9 3UŞ²®5î¢"3«â„²^vÅ‰wîJÊ…äÌòæìH7LWXPY˜öŒv ¾÷a©¦Ò KifØDækeM2Å]õ ]¥¸‡‡,ë¢/ûR1ëº/ş\Ç$eTœlÌÓJ*¾?Õ,¶“"³ğ§˜üfàCšS¢ä„/iB*nÃV‡ä!u—Y‰«ª@ªéL¬‰®Úº­¨¶nkª­Û‘ ?ÇÉ(†¦»_úPuæÜ‘	¿‡÷è¥{1ëC¤=cáË¹Â÷”Fa@„[¬jÅ™}Vôà¶)?0?3š¹8	ãWèøUœ…PqŒDÎĞ¯èÊ­™ŸĞ(w	«ğËYJŸ}%,‘8$]^â¹ÖóI·s†–Fİª’0ù ñ&¢ÏÒH#9Õáµ¬ +Šxè÷%TÜÏÖ…*¼w+‹®5ïT=w&
J³÷…Ç4éÃ¤Ã)]_xˆ9Æ-UÀWdQ‰æ7S«!ÛHşü>ĞO; Ç·¬ûB-Ó­3ï42‹q’;Ìç÷y±gÕ=…áá‰nsK8$›ëŸ)ô»©ĞÚ·m½OÛª'8ñ^:P»İÉmé^^c“(Ÿ}t‡6QœÏª¬˜Ï0¡,ìQæ^.:ĞC/í@õ9wI«@šé‹VÍÇ£¶%î}ì>­‰Áš×¨xöĞ{ 
51  o¤L‡ÃÈEs–=š"p@ºûuäƒL~Ç›ékÎ&ó)~@Òıñˆ¦f–ç'g´'û;µYúU§tg™=åöP°ø™mXlb3³Ë‰Zğº¬/ÜŒ¦cvcRÅÈöÄôı+¼’a8$&:G‡ˆ§‹’ÓØ­øãlre•ƒA:Qú~—Ç‚½5¸„÷TÔ™{+¨&º„½aèªÂ®qŸ6©şwR÷cyğÁÎŒÈ€E*"ªoœ¥p…Ïú&O,wPyè:æÅÃxI<şS­Ú®bü'£Ùj>!Í‡n¦_yü'œ8÷ítËcëêÀ _FÖü×Ûí0şŸœÿzµ•Çÿz”ô4ÔÚ+„qµ˜Èˆ]ÜãV+Â-uËÿşïÿ3c×`¿°LÏ²’KöxÂ"·0­¸P‚y(ö¸ER1VsÈ8¼IdÅÂí¦	Æàòæ„úeÒaÜ§óÍù€T1„:ôš#Ôæ»Ãa÷°’£=M/Òß
–èèİÛöÚïÛÁ”5Ş_±÷×î‰èøcT"`=An‹…cÕ¶X¸FDR
ƒ¥3JÖ/èŞZŒxobC˜Äˆ~`àû:UƒG.sŠéØ°?)lÃÕ†qW£6ÎL'¥Ó;Ø pÜÙ`™^OaÂì±ëIıêÂ0m"Iê™#Æÿ¢XÎŒ‘2ùìR¥åBá™DšgXZÀı‰s“œ¦gÏÂgÏ‰aÙàn„¹$u*L&yä)†¤?uL«L°ü0Xªën?ğ¦6Ò—œÜLô/½>S;M©#Ùc{dzˆÆW¨ÌĞ"@‹pBß–¯:e²Ç2_yvP`È<®¨ËEğ˜‘ÏÊ¾íL?ïşû¿ûĞ*lã.‹ª…
Lš•;1ıIŸzĞ±c³òycOmÓ! ¾]é0•¬~ÿ‚Q˜Gfoê°éq®¹vŞ`–>Å[¦é$6]¡‡ztêxÚ9á<4J}×MX¯GCG‰‹„3iØÓZ&ßã‘H{Ë*Š sÅY>Xë,VŸ/hè?şã?² „\hÿ{ ·ı×
ù™ÏåÓw¤2­ÿÖªUIVFJTV2Œ’Q?3ÛµÍíæ&óTsrŠQõğ€êIJÑµï!©–uŞÌ,h"L³ğu‚µ”8±£ŠwÌY…ßøæ9İHkÈ¥‹Ëwğ»O¾Q ¿#3á(a‡%4™şs„6ß±áó„èëÏßÍ¬hN+J‘
}"±>“µ #ı1ÀÄ9]Ÿî2uî!ê»°tÇ®EçA‹©
M5B	õÉÊä ·8FtLï|ÊÖU8£ªyI‘ÍpªëOÔÉğçôÅ•3ë!0¥#kÒ’8ŒR±^W…Å«@§ÂiU°@‚éUDƒ¹.Æ+ê4:•²Û§÷ÃÈ!mF$Cd,¸ì	İÕ_áîÁÛQu[Ä6Œ¨°?o :| ¢Éh8^èQ%¤e¿ÑÇ«Â^¬çÕ˜².çÔÈ#ÖùiuòWó+µ‰&ŞQ«Í¨4²TI©6|9w•§Q§9½›}:ÒUÆ¶e(ÎúÜºb¤ïNA÷İs¶On“J0$ö¸‘{›d¡°§nÍôƒÉX30”=¾ëH8â¶‹!=~#>¾QégÊ•úÏ	ÂÄ_i×‚›S²EcÃyd(m¥—~†;÷3²&Ù1îIZ´çÒi]Ç'¬İl,NŸë!³Àì¼,kxç‰+|#•¿F©LÒ¸	êœoCCªà>*ü±`/xK$ƒÁùÇTãw‘$Æ‰Gƒ…“½YªÖJFëÌ¨n7ÛÕæíø£\-W%G²”ÚoÁ¿dŞÕ¤q÷3K¼a5!ÁŒÜ+üÊk™KH¥gBJ³%;ñ1˜Bîjºˆ4#WÂÀ[ÿ™eÓì|“ÕW˜Ê’çËjÈ¼²á6,;·\Â’XÔù4!ÚOõV³=rù)¶VšÓàE0HÄ©ËÅtPºut&¨ŠÈtÀšóR §Ys3À¾ÇÂôU~´ŞåÍrõÌhÕfBŠ‚ı&1/›†Î)ö5æ^6,%^ßÌb"²S(°PÂM‘È¡‹gu›5.ÀFÆQ­îôRó–bZ©$5¸CÅóWSz¹ÖQzÁÅÀÜş.²ú^°6òëG¾‘…®»f×.

¯2À\ğOeß¼œQÁğúš—–_o"~¡Ë!ÅÎØE£¡ Ì,H°}€o®°_Ñ….Iù„_IªO8(O¸0¯ Ü®ÔC‹.pú•Ş"´«„^…²_ñÍÊÃøwõ"\>fá´øÇØ Fv¿R€UY)„Ñ©ÕèµKıÎZ} )[ê“2²g€ÌœÈ=÷\3ªgçÊx)Oøi¶<¹Î€J¶Fˆ-¾ùgÌá:ó+khì½$°?‰½@²
‡‡AüL°\­)`ÙÀa‰Ùì€ù?›‰‰'”3é0—™Z‹¯È,È#:3vy^ó¨©/“IJ"Ø¬êpQÅjç;Î­!)[¿+Æ”¬Åšz7h
³{;€Â)0öSsDL‹Éä™O:¿ÃXV2t,Ïs›İwšÂÚP·´(³‹Æ˜ÍŠ/Óô¹EdÙ0¤¨	mÊˆ†ür¢À@À£b™(]˜]^£¦E]ËFóëtw¨³·ß°ïÂƒÇŒp¦øZCµy¹ĞÂw3áÍ÷”øx7x…®½˜}‚}~dÈ8“º‡»¨±šz.æÒ¼rÑµDn? b"õÛÖœè^J_R–9ãú¬Lş€yõÀóŠU	1(~îStïB…âUA˜2v•gª€â¾Ë¤@ŒÆ,”ûÉ¼¤ Ì/5}1Š¢\bæø!:¯ÏY%óŠsÔyúıˆ*"#ë7¸°Êî…×¡\ã™¼ÒBaŞ†_¹Ş{.VF#
U@Å%WB0Ş¨Nı)»eá?°=\Æ¥JÑÊpè!ÈF™"ğ¬
›|QÇš‘(–U*$ÜTJ¸GöûÔ›Ôú8ºTÕ„µetiÃåğoSÅâĞŒUŸ¼):ØàNğ\……}ä·Ã²…\˜W&Ga´hÍ
öÊñËe —ö%9*"¿P"dâFâ«"D@sKÜáGúIálúèhÍE‚¶!%¸BÏÇY¹¢Ğ°A5ÂaÄû4ÄòŠ14§âî™KŠ5u	u+LLO¹PøÄ@XúDv)'-Â©Ò'È˜¢4G>ÅŸ`Æˆ|«Ùı»†Wø2â16s
l·²¢›¼ãv#X:¾pNG
.„´GEX%p$ıµYì<@ŠpU–Y‡Ä±+Öó(:¬ŞR±˜dƒP¼­Íiä$‹O&ŞóÈÌÜ´âãq%Ã?£¯1¦ÂzDj'ìø#Äª±”)£Ê·†øãÉÌÁXôÀ[x¹u0‰®ğë]gYSÔùĞ„¡Rç )-ä¸B×¦®o‚"Ş;w³U&û®è’;Lvò¯„BHÜÕĞ«ó%Bß¿P™<‰Yƒ06CGÉÚHàÊœ«Õ½¬>êİÓ0.›;>‡Ü“Ø’:À™µM÷˜6¥ÑzÏº—o¦Ù.ÊkŸ¢rÈ•#l>¹S¸µq}€İä™ÙÖ(Ö“şckà9ËĞ´¸„BZÆ0‰AL­Dßêìi³VäÌ<×İÀ2˜1}¬Š Õàgİd;Å8¥™Ÿø¦°«ÈqX‘9ëåüj´„Tsc>Z1µ44Ÿ3ÒÊ#İ2\&.˜S9fÙ¡K&ªsô
²BéÕˆ~°qoUÙuUSzb›“êŸ5N¨™·½èë1ZºÎN‰m-3cúv—ºé‘Yo—‰g„ªÕKä²2°Ü~Øå~_¹¥ö:åWœ(^bóªÓî¤8§bª_ïSµzy^&oBöU4øÉ˜.u ÊaóWEY#clÌnäÌæ!ë&É©ä$[¥1±šhIåwqËÒyRÁ¢CcwêœŸa|7z‚²ST´9O,+Me‰Ÿ1§!»W=a¼ğ^\9ÕáÈ²“<Ã¸‘>²Ú×Øæœ>ñIî,¢şâV&;¹»g'Ö†2`ŒÖÖÜJø4Q¦'40U'‡è½N½å¥cè®ÔˆíÍîµ"+”CÔ€¨Bt›÷àT„·§Ìß=ç¨ p_~9j¯ z+>á(n°abÃ©¨ƒd5W¥¬ö²Jå%3TŠø­€ï¼R|¡VªgL¯óèUe§ôù`UÁò˜[äazsiı»S¥uÓÊì³U¡S•ÔÃñşîŞ+†ü¨ˆ6µQ™ÖÑÙ»7O¹Y¤yjvuB
# å¯TQyJ½Æ‰àä÷ÃÏÑ}[¸û çcP V®ó&¤^§ö;íÖ¸Ñˆ•ù¼çDUªP…tOS"`İµû¬£¶º£¤è”%[–±£hGm«©Ì™W.3HÅ…Y[­ĞC&KX„¬äÏ\mxÄJôün-ÈNŸ$,¿.$O˜bÄW”Ğ“(b¼}ÁQàBŸ‚­’èè¾ô1ÙKkT”µ©h¯Òš«D ’™„|([W2^yê6Î+Í¯(¹ÂŠï»‹ÕÌ-ßE”ÓïSß–R×¡¨¨í áÄÓGß½¤ìl~.à-XŸ;]˜Xk˜ooYZ%È|€E!Ö0Ÿìî0¦ì˜ïá0ÏÄÀXø´ó‚’¦¼)ãr¬*«T;ª6ÀúŒ‹`îP*a(,êOqé/ê×jâQ§¢NÉkZ(îğ?P$S›. \\7h,h@ĞPÖ7˜˜Å´‘yÕ;èøL‰,b]	gô¸R´“rîã¯ËÏ`×{Ç;Èå¬(§áŞ74|À}$BtÖKï#«Î©( D;*íNL_$Qçiå 8L g.ôyÍ´Pø‚íNÖ¨éÛpØå²6¶ş´Š!†Ã/.aM¥ÖÊ¤H*µ†¿ñ©şÉÙ ^F•X“zM¦À4Ó†ˆU†ï˜ĞÏB(p>á½Ÿë$	‹9`A™ÙAM tA ÜAY3·LaWèN0úÁÍÌbì.ZEC¥Ñïg4ú}t?fâM³yNKøXèEËƒQ<M„ºÓü4cDüÁú"ü7aa¡3âUy	!^Ún&D|‡§ÅŞ­¸ÙÔ*ôÍ®¤d€”
Ÿ^©aM­fŠ˜&a\,{ŒÓa*Õ˜˜~(…ÄRÄŠI}
[Ctc;iÂwX]Ì.î¹ª"Z—¹Ä´rY,rVĞŞPÆÎKE"w[c,Â#R</Ø^‹ĞØG¡UdÆé†W®áÈ±†hÄğxÁ¦ìù>*í=!†*L	¤?=Çå‚'”P_ ş±7“ğ”ıeÎÄ±œTJCk™‹­È^ÃßioZ B‚ºŠhk±v»RÁ†–ÏY&çq…ÑC`K+ÀqNƒ+åWÖ·…gä‡®Tõä#(
 —^x#;Ô=®ğ¬ëXÜŸöÇ6wÕÍŞ¢|
­³Û·x1_€Ê¶)¼öá,2u˜µ
LTg[•™7ˆ4è¨•«eò'w
$åš¸}víoÂ„N®å‹"ÄÈ7Ø<hİÕÕUÙd Ë®w^Õù•ı½—İÃ^·@Ÿo~wûTÚ,cúåyĞÓlÿÕj¾DşôÿPk4sÿ‘
!ÓuB9A¸DË£:Y`¬#êé)~=Æ…ø‘ö»Ó’Ñ£ÖĞ=š+Æn¯ğY›FÜ§%ñ†}î9yÌÄÖ¿ñ²a>DsÖRÜÿK»ÕÈ×ÿc¤Íú¦Y3«›[´5ÜlÒF½Yí7û«º9¬7i­Ş4ZÖ°İ ¿+W’ö†iÕLZoÔ·†õöf­=¨ía½N‡Vµan66ût‹Ö‡}¥t\±³_kXm£^¯6kV£mÒÖ`«Õ¨W­­M£Ñ´·úpŠi6M„b®0ÖZız³UZµ-³Ú¶Œa‹V[ƒf»mXFË´6ÍºÕª5ÕÒ‘iCÃ‚.Ó¶µ	Í®5«[fs«_­€áf¿e7­æĞ¶•ÒRÅ¶U£Íáæf»O¡½Æf­ºYß¢msP¯õ·¶š›´fíF{€%SuÔtX¯m¶Ãz«mBÏ«&Qoö‡F³V£[«?Ü¬u ¢l“nn6ÍFßÜ¤ôŠÒÍv½Ö2†ı*ü³ÌÍ­–ÙŠW®WlmV7[v­?l÷áĞh[V;²U·†´6XÕê + Ğc³Ù²ZCcØnmÒ­á°eö«ƒÍaZ-:¬¶Úí­F}hT©Z,n´Ñ }£¹Ùn²¶VÛ[[[V½iZF¿_ßjµkõv½Ú†¬!ˆy&	ÖĞ ´NÍ¶EkÍ–9hÔŒÚV¿Ñ  q¿µÙné°Ò­*n3£	k
}n«õá`Pöµk£I£¿iVíV»_İlSÓ¨ZÃA»¥sĞ–UkµÖÖ°QßÜ4MXLĞ´ZµUTûõMZ5ív³–Õ Ş–&İ²hµ“¶Ù²¶¶êU˜ëf¿i6a£µÕÜ2ª«f¥@QÌGnƒqéƒsGÜK »-& ÄñÑju«¿µ¹…ôn«ßö·,c³AaÂûvc804ú)8”jESn–Öj5è ¿Õ0µªÕ¬Õ°ËYÍj»fhköCœbıSÌkÖ«@ÑÍZÛìû€—ğ»Q…Uc™­!Åÿí¶@7]jVi“š³	XØªoÖi«^7ŒêÖ ş×Ú4«ÍÁV£[c1ã¤Z½ÕjºUmRÀÙz«eÁ"e05™­- Ôñ®¤Ú@µú­jÕhl6Ú´n4Ó€I„5Ö¬6ú-–Y³„›ï1C²ú&¬é&ŒÊĞ€á°úZs¶…­Ú'ÑÍV½¿5KÊÓÌ¯Š»sBD~è:õÿ_«V«qÿFîÿñ1RÚ¶ì:æğÿzËóß®ó„7?ÿ?JzúÆÙ¾gæHË<D?%+{Ö6YY:ØĞMeçõy6ˆxÉ±‹a?İ	“Wş–ô„LríÅnoÊôLz¾êüÀ3}Ÿ’ÚÖÙrC^Ã¦ô½éùùé]ÙÁOÔC×“Ko4^H—yÚN¨åÃûÎ4¸p=ñ¾Ğ!ê%1iYs©¿¦nğ¬Ì%0¿Ä TJw-;K¯ì›~ğ’ËM^\óØÅ]½œ’_ğ,'ôÒÆm3‘E¾àÙ´°ÀLkSX\¨÷¤Øa˜Y£b$Â,CPõôœ‘6wº„¸€gÎI±C˜Bäµ "ÔåNô“|k£óõ6|5¶ÊÕv¹V5Z„ „ìñ¶K×£Ko@IzÁˆ™ßÚXWÌr%Î¨ŸÃüoFúæpŒÙ›kÄJ L%Xo ƒ&œO¢	WŸFÖ‰¨äºê³ ¹x]a	÷OÂM{ä˜QI“Y3páQZºgÓ8Ø2¯óTêqI„&411¿í@£ÓèND©Œ6)0Ïù=íşşÙË7½Ó£ƒ½èœî–!Ëuìú¾­Âğ1&,cÒ!‘°wd·B×[ÓĞÚĞôã.IÌ„6¸ï˜gTÓu·0¤ëq¯Zò8ó¯å‡Ğtç?JÓ´ëøÔö%¹”«:y
T¡|7¦pZ¢ÌŠ¢bw€ú *şäTĞŠo;fÑ(^RßR‡Ú•Ly‘eMºR"5½ŞXº]:±anüŞ£TxÈb
m3Á¢—›§ğ®ËCtsÍÓ¹ÆËÀs\†°
#ƒ+I[|Ê.ËK§¦ß¤.òçù©PO8ÓÌĞIJŒ y÷µ–ôÿç¾Zùøóÿ’şæ_ş³'ÿôÉ“s@zäï%5ÀgOş~jğóWøÁïÿe1ÓÓñKü'øùç±,ÿ$zş¯€s(£xZ×‰úâè˜âéq3šÿ•şşíş›ÿñ¯ïÕÏ<¥¦˜¼øAê˜³şÛíj#¶şëíf=_ÿ‘êüÿ`€Ÿ© K
ğó è.U^	·RÒëÓXcö'YfÙ OKR}sO9"$%	âˆîäMİ…6FjE¨††¥ÂÆ^=´á# Zrá]\qãÙ|Ü¾2\:×N`~à3ğ]çdç;ô^±ô†Ë¸h=cgõíô÷o/¶ß^UÈ±¸dïÈªÌ9°.bQ@£7fz„¶(CGñ¨=i!'©Éî§†¿V2â¢°”"¬t”÷"5¯’a”m‚¢œn?jr¬Efü•p*2 O ¥“<<–Ñğ1Ä0xwzèM5ïË£ÃW‹Ÿ‰×‹uY‘$ìî„ÓŠn„”ÀODW tÿÙ<d †t	 èÊ‹kQvBBËNÅÎJÀç'Ñ3xÑ©h,ÃE+ŒHî»´b‹–“â×?í¬²%F¢aÏpV€Š(ÕI»;…1Ø™Ò¶œbadqË-p‘_±ã>ö¸ÌAÓÈ\Å‚å:´ IèJXXñ Ëœ¬F™ú™¹xuQÖ™S!Ñ[;Pƒ”LqüWò_dæW2fÅUåffı¬@Q¯O‹j.$É\ \Í…T!™ãŸ+¹’9”·n_VmÄ,)•JÒú‚0Àoğ­.ÕX©T
<XÑ>B¿¬İCR8;‘ô³ëğŠâ½4Óc,Lhæ5Âó±)6M¥#oödìñ@(i)šífº§tfeM~\ŸİÙ"enB:é¹HsNƒ3.W>C!bønÂ_1:&Bvi9 Ê;«#
”ŸAıwäz;æ4pÃ;«ûèXa¿sÚİyI03p5ŸX€±0Sz®~ø>B†İy¼	£ÀùüQZ{ü‘Èƒ÷Œ™ò YCjÕÕÈãàtÂû:{˜@&¤	doVg/¤
7«ŠŠÓÛgTJq@‡ÛP°0‚âßFdq¥€x¿³ª™;}¦ÕÆ*Ÿ?ocà%´alz×²YÓ8â^!½œ´}sCTM¤¯ı€‘Ò€ÄÕ­?£)[é’·ÉÑ‹_¨y^±èeÅ™FËıÒvwV/íD¬äÀìÃr¹Ïù_•ÿªZzË’/`ZPş[7êõZ£Õ U£Ù¬·sùÏ£¤/\şëùïÿüo/ŸŞ«ŸyJMé:ºË­cÎú¯µÛ‰õŸòõÿ)—ÿ~^ù¯¦ÿ‹«V×3¤ÁqQ°ê*%ß½	?wqğBâÅÏ'>#ä)·âG|c¦÷KˆûS±}XJq‚v’şGf5·ÇÌãÿ5nÿY¯¶Ü;«F­İÈùÿGIOUœÛs-Hbğh{‘ë4Ü»ğEM¼`Öa…âÃºò°>mˆ§&“O›âé‰"L“ïZb2<¨×ôb‚¹7ÈÑşÚíu»„»7ëŞv-‘BôsÛ¨onm­zk»i{s¾Ü_—†XºUÜrë˜Çÿ7›ŠıóÿĞh¶óõÿ()·ÿø,öq+ÔŸ+çŸa’Î¨ç 3°\NıqøôÂ’Yï/‡ñæë½ZĞÏMç³†Ï|è:ª‹ÙÿÛßhWƒÙÿ6Û¹ıïc¤ÈpÿáêXpşQÿ·ÖdößuÀ…|ş#Å\¬<H·_ÿõv>ÿ“t—&SÇ¢ë¿^m¶«U¦ÿßl6óùŒ”ğAó uÜ~ı£+ˆ|ş#e¸Zjsä?FÕhóûßF³Õ¬áü7Üÿß£¤§ºá=z^ãı0c‘aè-Zş+GoâşÛrôPÄÿ}ãs…èSˆV¯ã(<Æ„ºÏ=sì
ÇÓowVğ÷ö
uQU}ÅvÛ#- _áŞQ”ÎÁÆS¡)Rø×%ûÎ“Æÿ+îß–[Çí÷ØZùşÿ)á¸ïêX”ÿ7ªõvµ÷¿æÿ;Ÿÿ‡Oó7.£9ü_½Ş`÷ÿû©¢ü§]­9ÿ÷iY2óøÅÜ3ôL?ğ¦,Ú°Ğ¹·H»Iõ?ç\ü:.îªt©wqZéø=lyí²Q+W±ë·ø5«Ê"
qÛ:ÖX²Ë"ÆîÚR/ÊDh	¡®·»»OŒr•üy}¼)–9¶®Å‚©ˆ¶ø”’sÃƒğî‘~ÃÆîmĞVˆØ|‹û>Gxò+Ó	ª#¦œí•£Ş-©¥<`q}…ñNUM,ğ ŒgÌö„¥(UyËç4X[q;İÕRd®¥Ïx¹âº0	fgÀÃÀXÊ2ğcå+¿H¾"J+ÖÌÆŒq	Ñv‚µ8TnÅˆÖ1´gíâº,ìû#Y~Vá^o_)_‹ÊOñl—Õ^öM¯{‚¯h¸K{P+>,[­ìôzßìÂ¦0ñ°A«¿y4?LÛä‡¯üw«±Áø:–=ŒKÈeÔ’H,{4ºñÜT—ˆçÃxO*x¿(w'0#7ä¬k¿ßïÉõÏŸ0’ÀŸ¬ñş†ñìÃ¡VÆa£@IÎS4&¼X4³J!¦¨©Ë¬‚8R‡ÊâŠÆg^©hÔvãÔı TFéôso±_tÊtÿ½Ä:æğ°&Îíœÿ{œ”}<¶ÑÇÏV×k_ˆ”ØêaÌaEw)®&t¬ÛâÂ(ÕGµ¸ˆ¹uoªÑgĞçìŒ"ÈÍüŒ"füÈöKŒ•åÁÚ`_Æ¶Nwİ÷ìŸÀ&ûâÛ?ÁÇjõ}á&üşJSZ’e×1OşÓHìÿV+×ÿ~””ïÿùş¿¨•'ˆİ>·ïÌ÷{¥	Ë†wEéûÑ5N1š0w+î1 9Fuä¥õ¥V”x‹<ƒg7â~êõ‹ã(œ)äÕ›ı}R#ÿr[}³<¸ ÏŸ“J0¨ÙÑ·öü·Fá†Ï21Ü»í<¿Øü|ƒXİ¨mÔ7ÍÖ†sïğåI÷ {xÚùRFU¨^<ŞHÖjl$Ÿ-:~alÈÛØçŞ‡?Wšq)uÌãÿš<ş3ğÍ†Ñf÷Lÿ/çÿ>-mÁ¢ùî-o ?#w†µ#SR¸3`P’aA!ŸÂ­•Óx¶]Ãğí1MåÈ$ˆj»c1	Ø% æQX2™Ç`7s*&ß¼F¼àe %/ÉFZ¯Í¿†6ÁˆP‡…Åa=uTáŞd9Í+3âƒÿ&‘T#j‚)ª°ˆ ÈÆ)6´ouh‘w9£“~ÙÈ»ÉX/“õ#¬NÂ.È¹çÂº}”(Š»]Sã;(³ $Q’–P½‘»ÙÖŞûSË%ƒI`Óñ½ÊÈîWD7ÅßJ¬‚.]Ÿ—L© }2t´‹•Ïòaï-jÀ®`ñZ,Q|^5=ÔÇT¡’±éLÍÑLàL‰sĞîäöİ”™àaf–GNb÷Ò€ôÃ`}V·ğÑÇHÂvU†g~ªe8qèÙ:Sø¤>¹À˜7.b0 ãÛ]ø	À»Â.åXŒnñBé²¡ğ½éşCƒ+×{_†y:§A¡3¨H
?ºü®pz=¡;¾œğmGD§zpÇæ¹…ï¡8,²pïÄÙ2\¶¨Vü#¼÷Ã»ll¡¸/t?ĞÃ¹Û—­0´ûö÷ñ*5W90wrX}Ï¨à ]ezÖÑ4˜LƒÀJ”¯Â8	ò.¹wÆÓQ`—°1œŸ{O¿MšÊz9uÌáÿRâ¶Ú<şÇ£¤ÜÿCÿ3ÿùxÈãæñ?óøŸyüÏ<şçr¨iÿs¡¤óÿ‚ –=²Ä:æğÿhî/å¿µóÿØl×óøŸ’~è¾Ş;ì¾+œP”òëİïDl£\åÿ
?¼îvOö^¾+ôº/ßœìşéìÍ1ĞŞnïì»½ÎÙÁŸ8që½9Fuñ¡9ò—kE§‡Hiçÿe»€œ³şÛÍZ›ŸÿkµV•İÿ4Û\ÿ÷QRîÿ=ÿ™Çÿ\âçßïÚğ<şgÿ3ÿ™Çÿ¼güÏ[ÿœÑsvÜÊÇ‹£ùÑ@otf´Î[ES] ^êì0—i¡,gÅ¾Ls¹PË¹±0ç…¹\z$Ë™3óˆ–Mœ4é19'6f¥7¥÷sëN1ùgâÑ½î-±yò_xÉë,ş_«ë<J²K8ÂZ;ƒ9OèN1|
È¹kZ`Ÿ»õyºoJ×ÿZn$Ğyş’ñ?Ûõz5_ÿ‘rùoÿ3ÿ™‹ƒoÓ§<şç/'şgbÿ€H óø=şgı?´›9ÿÿ()ÿùëÿ™Xÿ	tÿŸŒÿÙj¶›ùúŒ”Ûäñ?óøŸ¥/€WÏã–¾$ÆûWÿ3±ÿŸÉúå¹ ™³ÿ×›Ívèÿ£Ù@ş¿İªçúŸ’rÿªÿ4ü/ä.@¢ôP.@ÂAOqú±Âc·°„‡qÿ‘†ë$ñbƒµ' Ôt? A¿£+LØK¤	¿o ªìæa(ÜêÎÑq÷p·wÚ5îÙªASÆÊÖ{£¼Y®F¥¨;ÿ0"£PÆƒ,ŸJá.wõQ²³üËÔ†Fª®>æ”t'ñ‚'ãğİ¢¨G9jK éA~®®AbñŸq&ö¢v,¥yòŸj½óÿÛ®6k9ÿ÷)¿¤7;.ªÑÖÃÏVP³+„4Š×µ5gÌ›C€×šĞ?.Åùµxô-X0„Ö`†/8G<Ü€/®w^°Û$|XpûèSj0‚/€)Ş¹éHïÚØI8Ä³ÃöN#ö rğ×Éâ±š£—® «O½ò1ua£Î„Ì_ß
òç&MyÊSò”§<å)OyÊSò”§<å)OyÊSò”§<å)OyÊSò”§<å)OyÊSò”§<å)#ıoÖZj# 0 