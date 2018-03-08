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
‹ Ïe¡Z í½]sÛH¶ è™İ»—O³û0111›M©Z’[$~JrÉİ´E»Ô­¯åªÛ×vë‚ H¡Ll ”¬²Õ11»û´oóöaÊü‚ó¾/ûöœü 2ğC%»ª€*Û$˜yòdæÉ“'OãV<ğ£iZ«Ñ ôß&ûW«ÖÙ¿ü!z­Z¯iÍFC¯M×ÍêÒxhÄğ™¡á*gÏ,Åúı¿ó~DÿşLÌ¿7±Î¡{á$(ĞÆìù¯64˜s:ÿ@ U]‡ùRh<!Úà’z~åó¿ò›
’@Ï.
+¤´¼ ­î[;dué`Ï|çÒ°œ€´_o’“Àqí  {ö¥=ôÆ#ÛÉoIw2{~HÖ_ìu7 N×°¶o;AèA`“êö&ÙÒUòzh„aÏŸ›¤{å„?ÙşĞp­¥#}dŒì2{vˆ²ààÇö$¼ğ|şc7´û†KíèuÏ6H@ß•=úî!€²é vÇrÂ¨öê„//w`[/®ÙğïaÜ¶\ `ENíK'p<7UDüÀŠLü±ØÒ Ò5}g’Ğ#ş¹°‰ãB×\Ó&¬‡Äˆo‡—˜eãHx¡lÎ.`>Ç^“I`[¤ïùÄv/ßsé¤Âä\x“œ}¿W‚¦á'Šw¦ZC`a8v*•”œôpt*lÄdq@âöÒ§†‡|Tåù×;ğUÓËÚv¹ªéMBpBö]'tŒ!¹´}F(£WËºeZ¢LÛú¸!£Ÿ°°ç¯”-?Àâ,‘—Ğ¨7r~2B@ì>ĞöGºØßìŸŸïí®~’¾í”Š@6á —^ÙóÅŠ@Çµ°÷Ç£@ÁíÁ™Cò½1œØÁ=:Tø¾sÚİ?>Ú…Ù,ì·ON:G{»Å³Ó7"YğYÚ5zC›½é;ğÁm`, ûÅq·³[|Õ>èŞĞF– ájê¾<İ?9;?jvvW×‘Â]à3dUÛ(œœïíŸv^Ÿşy·X	Gã"}ùjÿ Z_ı¤¸©¨ÕË««ÅB÷¬}zvş]§½×9İ-ÒoÈ˜j˜¶ÕORë7dı{FáğßÍ]³dõi±pØŞ?hïívºİ] é?x¾²l^:§§Ç§»ZA¦ˆûÏ$÷jâšHT÷!n¹«¯Ïñ"oc`¯oOIŞºçã¡qÍ
,¹u$§ˆ
)QÓW{Şa0 Åı£WÇd‡5¼™œä·¥‹KŸ”ò-®îı# ‰£—ç¤´G¾1ÂÚ;‚Ï?²Ï'°Ú¯<ßzÄÿœ¼Ïj„ÒE±ÓÆÉzˆ›Ã6wø6¥úeVõŒ•2¥ºŸUİ¼°ÍtûñíñĞ1)_š@êwüò½Dòİ!¦»»çø¶‰›94\è?\æĞ½€7dÌ_Q^2¥vjZğ7°	±-9«Ş7 ì	6øOÇ¯‘;Ü°rNŸ¼…—ú)B¢‘÷Ïpw¢›/‡¶á¶]ë?Lœ•[ıT½¡?ÛCØkE¹ÇË®¯ú¾ïn
Kßë2—Ö!#,Æ£BgD–Ñø¡–:õõÂ'ÚÏı£“7g°Iêßì<½É"Bú€¬k|°	H¶ş5,w@z6üc±±5_ÃSP7 veC b™Äu@&‹ûI	˜ï&Í-š“"|!ÅBÎö;ç@G‡'°±X –âï¾ùsé›Qéëü›ïv¾9Üù¦[ÜxöLªzz:½ª;§2İ] öÚ=ş¶ª´[,Ê²ß•åŒGT²ÃŒW@‘nhHÁ7E²K¸\¢¨f•¥m˜–q2ÀET$ŸCÛ&%CZQMe]Íƒ%%>N?Œ¾]]àº§Xc³¿|)®–§4qÛÅh%^Îí]fgƒSŠJ=M÷Öò\;Í›–8mÏŸgõé+ıl$¼‡àÏ‹”7ŠH’uÓd26ÜãG'| áhŞÆ—!<ñÑã,YGv×6¢=¹+ì´)éYfWºT8*ï@7ÉKb(è2ùÄbŒ¼‰K%qÃLğˆ”I×„nkÈŞMÏG¹ƒÀì•å&ª‹6! “uÜÚ7…ß˜_–J¨Ø $’¾ë…tRÜÎèò¬ıâ†@Sğå´ıò I7ç/ÚİÄÀÁ@Ïm•V£ívH+/KÃ¢ô¨ôG×çA~éM†…zó‚ø°_Ê°ßÌĞ3,ònõÓwÇ@•²@RW›Ûß®»}‡ÎûĞ1Û’ë×çÖïø>Œ¢cQ)B­>·7¬:]âº(¿péF†«‚«ŞœH"z&ÔÚ<¨‡NPÉ*-eË½m%(Ç#ª€Z€
\×f,ñ;èÏĞæ½vø¡Ç8(ó%-	…Ø',´SiqY'º¢4ØÑã‘<î¨â˜²>+‰êøVòmh„LÜqáãˆ²$ü··7'•?¢’ìÊp]ƒ ¿_Ã¡§,ÓßÏe;oÜ®wå²®O‘÷JXX(JnRÌ_ÅéÔy— VÛ(P³5U…¤€¬>¯XöeÅ‡Q‘Q
Ê›Xb•ÄP­‰êAØü<ß0áÅ‹É@†ÚÔq–XÍ§eœ’¬fä²ÒfWà›2d:~®¶;~µÍ
SÒpéıõ ÑfÄÑañ0F
+
|şuAˆT¢©TqŠQB‹%9pŠ"ÊY¥Ò¢¦rÜ­êÑy·ïRˆp‡†#ôéN8]òù3üòR²?Ë*­ê´†mà à2—ì…2Y]ï#Œ·ÄÕFJè$7 ] è£3ÉÏ™\Pà2&*á£`’QU,!p¤ÁbíŸ±ªP%“Ì~kô¯(—‘ßş§éŠ%İ…Òı„ö¶Íˆ:.ºÜ tf6©ÀIÅL6pŒú—B²Ü¡áÜK÷.QècRT:V×ŠxÆ/8×‚Q—tºÀ¡Ø€"Cuäê@›˜ö\ªæ.yŠ|\˜Lˆëm`‡ŞÈV­?ö=\~¸Ñò]zˆ#<6| †õaì<Äk“‹KggoçÇÎRht,b6¼‘l K¦1Ô¤Íàr#!§K¿9äğZ&d$Óãš×Êº‡å˜~oJ‰E	Ye7¥¬¿AN;'û/Ûgx¹Âª³¡Re6”ß‹ÎVÉêSy£g´ˆ[¨ıC‘âq‰!H,m>±(%Ëò@¡¬0ØËMcXáVŒKÉª
šs	òœD+VõoõbúÿÕßC[TØ!6nÎ  øŞˆ³N¦Ÿ¢òY'3eì$5X†vJp˜ìy‹‰wö+åŒBŸ"Ì`?16³øO´I\Ù0\—X&I}…ˆdqØÇR1S}SÈ ^QM~	 V?ü°Ç;rÃ†é7|‹L—ŸµÕkéÉá»`B¸š¸B.›J“^à%K%v\êûôto\¯h4éçßÛ~èØb
¯ØÅÙ;ôÙk¹O$³£P0ôA2mQ?W‰*Iá…lÇ1äoOçu])Î©ÄàÊâ;àÍ†`Ó1ØM=^GâM{É!kAå/«•ReM¦D¨õ£ÛÓÃü eÉşS–&ÃĞãİ&š^D *ÇT6…ÓKhQÀ_­|:zTŞ¹Ryv360tü™€ÿÂKíH 3ŸT+	Š:aÛ²ÜØ…Ê
¿öéÚş%œ·ôºòœ¬@\lL²–*Â/EmKi{C°iî@ÚVÚN«ãT.¦%.>Á¦`f|T¼àGEcìˆXÀC–ƒG¼ƒ½ö	ı«m¥êÈ0Æ’nõ“ÃO2íşt~Œ·ëÆÕ²ö¢ózÿèÓiw·øÎ-½ƒ³Û+ú±ølÿõÑñiç%l»ú3vÔÚmàíNşF*i[–sPAÎºZÅWï¾]ÃVÖŞ=¯OĞ©õÕ{İaİ€÷öŒÜà…Å'z(¡ïÔ'WeİE½º²`vzJšŸ?EéiÒé(	^İˆ¥-šîÖÙ-Î¾iÌggi³CÅ üKZEĞ,ºp_†#ƒŒÁÕ¯jŸß©Zfİ¹;Õä­ƒßŞ;Ü?’7Ÿ©û˜aw,½{eÎÕÔ=LéÒ´iÍT¨ßaVëUuãã³ËxhûŒ/…àÏÒÒÀõ°S|Æ	÷†T‹¥Aë-ò›¿­¡ŠjˆK@Ğz£šIì·#ğêìKõFU!]ìŸziH—q‚,}i[ÔüyüGØ3¾/bÿ]«kU´ÿ†O­FUÓ˜ı·Û?Æ“Û!ûïhÁıRì¿¹°¢ˆ¸“¡à—nú½U†ÿÈô[¯%+:nè{ÖL8!GjTŒmÓé_Çvø0Ë¶’X®ùø/Û|©–à·6Tî_‘	÷#ÚkgX‹#)ÜÃ„;e*Ü}NJ#ò­4Ãğjq“íûØk/n¬Æù 8›|#L©ê^TûĞp†„ë=²«ç6Òj#MréÜFšä6Ò¹tn#ÍYäãBÏ°ÊÆ|êÆ—[HÏŸÛ*ßÒVyIv¼_Âª4·Ÿü…ÙOBÑÎÑ÷»s­%§Z²ö ´–›PŞƒj—lD	 oo)ÉN¿:y0SÈÑ³Ó¡æaÙb¾8‚‚’hu]Èy¢ìgTİ•w›•w¤2Øx0;Ê¥ØIşâMé8ÛKÌm«æLj(éR"}d„½L½H¢bB	#í³—œƒ1h$š±bú6fÕ‚õ46A¶G}^$lØî*bœµ_ì¦Ê(H‡ãü`¿‹&Ì®ë’¬ıee-v9ûlNBÀ\‡Íag#½ñaø¡}z„Ö9ª$„ÈÓA¡ƒ÷.£ïSà¼Ù£g Q†VCL÷Úgí›ÊSt›‰kM\n•w$>K	‹¯i9VêµàØ+¿áMŒDÚ"ç«ehaX~ú®ònşŞx‡X”Ÿ®VŞé•µ¸kò!*ñ´)ºr·ÁÆYâ¥EN×“ÀEÖ¼56,¤ñ\bÑºOÖ6×ü·ÁÙ>wßqí+ÊÎ71A™Àcë>úú†Â}çrÀj¿ÙÚ‚…§V´æRĞŠÌÕÃÕÛ8¬÷X=ò¶”*O±|»**½9èj(ˆ\Ş¤câúä\»O>[,·"{õ™~‡%ôƒçÊ^å€ZY–á e—#nËL/Y¥’)µ»¡CIr…e`¯ZiE&ãMxß´e™­“¨Ä¯2¥;ñ³*åÅy/µô¬hO‰÷Üğ’”ÆÂtè¨é×Şş©ª—PĞšŞcŒĞÕc¶¼Ìÿ.ú­˜‚²¢”VØy„>
1H;ë¸ÌJ¢4Ÿ êy!ã¦ÖrÔÍ*9ÈÜkoßîô††ûaçıûµGâÀâ•¢6{#ÃÜPÕA®9ü…3{±‹pÊ² Ä*“eÖ*ïŠ›ïŠ•ˆÊÚ .Qoª–-#Ú™ O]îfKîç«ŸÄdÜœG¨İ0^=}zz«'q‡˜æ8¸ı½¸×	½ '­—Ç‡‡m”õùhÿè¦Â –†,æRéÂBÚ	êùß²K\È>M´€“ÇË!*PbYpd§ŒæùqÍ5æk¿ûf²ç%€´èøÂF®RbS?£A¥BÌª2¹ÒğIÙÆËP[²ie6—iíçjPÒQ‰îq‰Cî^gQÂáêv)ds§ìØ²±˜j“YaªCñy@>’R@µ*Ç§;H<›ê{\DÂ‰ iÈ‰äú:ığ;}Cå™êóéÓ¾ø¸Ov}8f_ƒ ã:Á…m%ÕïñÄ+Úö{ìX–wån‚ø)ºåÀªëÁ‰ÒöÑ³Ú¶ÊÅHY"Ù¦¯N#•Dôü°Kô’”»!³9gñ}©®iòñ?5¹un*”Ğë&æ”A!‘„½«¬BXÎÿWnõ*ì?‘ˆ'ã/ÿ·Ö¨EöŸz­…öŸÕzÿ÷QÜşóÙFî—bÿÉ:ôëµÿl–áÿ9öŸÛe­¥”94~Ä[B:Ö"—uÅ-‚é¹}ªK†ïåo£Èô}nP:ÚÏÃ T+ë?ÛèÂjVzöçìÑ›ƒƒ…;Ä:%æìcMg×c»ğ§Nçd·~8ØÑdÔƒİûÁ¶?ĞÅúÁ¶Çà5c4Ü-–Jâóx²Ğ
qòjhrÚŸ³mH¾ERıåÛÒFi…\¨h­²ôò´sØ9:kä6¹w Ú¯Ê&7[œÛäÒ6r›ÜÜ&7·É-}M6¹™äæF¹¹QîİŒr¹l—6ÊÍig€ËiscÚŸ•1í²ã‘~…†´á³3Úé<„mG ª¦Ê4F}#Ûe†Í­FÓs«ÑÜjôgl5Ê¯ç´eùD¥çbëG6Ç¶}YÁ§
,.ĞîÎÆµâÒWiÇS
‰8Òj»H°F€zÌÉĞ#œ‘+Ûş@\ªŠ/u~8ÿ¡ÓùÓÑ±¤sySÜ(ìÅ?À .xSZı„7 7´ú‹öË?½99ïv€òX£çĞ(T"J-ò%hE4'ÒÃ&fUQÈ¨¬NÑ^ªÏ8I´£*FÀ_ÄßÌ†W³°+Nü¿Yåe)dµK¹õ0¹¯§j¼ùÕZ"g€KY$ã|°:-ïtÓW,º¨¶Êœ’¨QfŠjfÍ*q­oüöCjyÄãÂÊ²eåğ¨OÜ¼qSÁŒnğ³@™ÙÕO*.R¥ÔOš‹Ê¦¢$kîøq<¿ôÜ¾3ˆ§qŒù ™‰š1Ş0-¤tò“Ù_dŒ*².ƒY?±cŞËã£Wäù´^ÏéšHF .Àƒ[ô-YuÃœ6´kïá†vºV1Lx:úAY¥¯õâ+­:–96zÉ9šÉ$ßkÚ8g2·8æ£•°8^ÜÚxº¥ñ‹ÌE}£â…Šy+w6(oLœÒùO'½Ì./`/œ·Û“ĞÃTI¦5è–Î§i- ŞĞB{˜=‚²İæ3,Å§0·Äæ?Ï~<£‹< !K‹´%Ä:E&I›‘û#Rò³Wfâü›™éİ8òä.ô½	Èúëö œ2Ş˜z±#r)-ÉÔ›£—›zßâùÒ¦¶_åƒÆ¿åóHÍú mÌ¶ÿÖ´ºÖDûï†VÕ[ÕF•hz­Y«æößòüİ¿ùWOşå“'‡†I»äkÂwOşşTáÏƒ?ğı_üO‹lŸ²O´Æÿş—D‘ÿ¿ÿ×Oü[ÃËÆx<´ËC#Ñ Ïò+']ãÄ¿<ù÷Xnd˜>î€6ñ†,Â)Ïò²ÇÊş»DY´aîí}×²?>yò¿•ş×ÄÒÿÇşßÿgüWBû:%sÓµ1{ı7kÍ––\ÿõZÿûQÜÿãËøD–ø?gß¦œ¢¸è'`‹´R±çF2lîò^ ZÚÄ‚ÓåXA/…6OğC<4NKÈÔ ´¤å™l?ÓCìğ¡®&d÷S0W¡½äæñ1|oøš×ÜÍ ¡umšÎšÚÖ_2Ûú$¥]F ­†’k;J]&Kî"×3|wL/x„{ı†â}QT”Î/ÚİïÎ»ÇoN_vŞjïáĞ™<İ2]/ïÑüF|	¨pnF &Zk¬[OKS ‹ û_Y¤t[õo8	ñ–=¼@Ğ*ØWÿxŠÁÃ¹zÌxVÈ+L	ù×‰1túŞo3~€HñK¡äl1Ÿ™U{`Ñ °×yÕ~s€ÉöXz{É‡jÜŠJ~˜—
±sµZJ¹
åå¤+k©h÷ğ|ï¸J»–‡LM-x~pü²} —¢Ñ¦–y 9‚É>H¥ğÆ˜•²Csj)Ô˜‰6SKuOÚg./‹¹©GY\ãäôxïÍË3¹cêBJPÙm2$ñ"ıÑ•^-WËz¹VÖR_ş0£0ÓŸv¨êxÿõn‘ñÇszÍƒÌ°XHDäveŠü(rÆLÜLÿYLÂÍL”R;„sZü,–µŠ†ôm§$™Iİ,T<£kRMk7K›˜V–vlW¶Õš30E‘¹	’În(ø³–S–.„•åˆQ°3ÚDL™_Q…?ÚÔ²ù&¦ğéshª±„Á6&ÏKÔ’°Ä*Ï-®^Icï¨Æ˜òâø…qàÔjÈ#ŒînlAã¾ÉÓQ¼‘ÀœÀdpÅ :ÀĞ$h1?ã0ãrd÷¡m‚b«
ÅDpWQ¬Î…›ä	À
ÓLä<ÍrUğ*£eàÕw³Àg°iu2ÄÚ¾@ó×¬ùˆ¹Z¼Jñ[j¥†SìRÁ*Á'åîªœ1nP¼¹o£
Ï•şcûû¶h2ú|ËÆ~4.6´È9âûdjQ"êWî¼<;>ıó93¡£fK‰ÄoĞ˜ò‚¢“{"ôÇK‘ —m!†×äy"#öøììÏˆ÷İĞïRÿ4hİ¤¦ónäˆj´Í	E£ÂYeT‘Šp{xoÅ?Ò›«¯Ü*™™Nñ{„„}Ü”ún³¬à”eÿÿnŠ ÃÏ·Ã‰ï=™¿;ZPxêåG‹ÓèÇÌ¼í#~g£À‘°2£Ñë!?m„M#¾A^‹-¯69iŸ}‡æz}ÇB‰¶<LzåÀÖäÛİ	EjNZ7¤4´¶¼¯nßÙ;Gà@ÇøÏd¥ÅŒK¥ï9,B-,àÕ>R6ÈÁê¦zcBh4Ì,éÓˆ¼?#™H›H1«ƒÂ˜|AéFß72aéyk	)Çld²vÖ[â2DŒŠ0gä*Æ.o²‘©"˜Ü”èqC2D|YÅÉ?²6“lœ›8Ò/·fâ»:·m¡GHÀF@ÄÏÔ¦øš&æ(—Ë1î¨9£Á3âB…RùUô94zŠJ´ßØÆ—&rN'ÆÖTóhB=®-2c´Ey@Õ{ãØ´wx°¹ û­×Ñìõ·„•Ï Š2PK‚!ì±AŸ$UxOfßY3Í–qDöØ—Œ¦œä9"Óğ<ÁÜ¦X'¦R’áÌK²u³ -½„ ·8OÄßŞşöí¼Uj¨‰e`8Û\A;”=‡×1SÆÇi9ƒµ¢ĞèqQE±ãVÌÌ£ŸT®Ÿ0RøÔ÷Èp¯U‚UÑÎ±TãûbÏãîc{ß›grŸ˜r_|‰2¸•K8ìÀÉ$g;&s0â—h'E)‚«I&\™#ÃU"+z¥)‰´©=ïI´—BS¨/Ãÿ#Aw·¦¹iôv{Z»+-›Æ(}=˜Ó„,;A¨Î$Œ3Ê I5şV(˜$•gq[:òmD2›ºú»@Ü2oVNÀël™WÇsJ«‹é86À¦ÂB¡JŞDuÑHèYİÏ@fF÷P ‹xï‘óõø,€fmË2DĞ8U~­!˜¢xh`4Nò)yÕKãÉY<øŒlz¤‹&9X2b8G0-goĞïrŒ-ïíŸó‹Ş%æOBD)
9špÍıM,=Å+…éàU…ø?,6tjg‘[ÿıïãıO¼×…ŒkZ…+:fá¸×ítÁ’chÁä<&z¨3½z| ?†ËCP+â[èb)€cœ+ØãŞ {)ûn¤H¤Ò/ªîù†9´Ï©†7+ÁtÀ(Êv‡Ã2½şŒ ²íù~4/oô1GF³†ÕNÊx=³Âwˆîúj<Ê©šl®ˆRÿ˜u–Ö&Rƒ±ZzJ{]Æ5xyÖäÍ‚k2)³1Ğ{ír‚ì™H¨`dõ¤N‹vÕ²¼èy·{*Ş¦>™Å©2"UáTr´àÕD…ÓÎÉ-Öõ£ôt¡%œôpãğ_ÂæämBdTĞœf§R‘Œvh“xvF)¿;;;!ê3­;X´›Y4î°˜_ÊÚZzğeëœŒÓÛ¦¼cò­•[bÈ²åClœlÄpê™#®y:Älufiğ£"¸Ê‹É1W°#¥ô»Ô×¬§¨>¦z‹â³"ÔŞ…+ùl#ÊÄkvº®B$!¡Ú¢ÏÈÒKº”ã£¾¡€»; ª
)øîÀjòN©\}İds:ÈÛİ¦	(’m<ngaF¤¨%”ŠÕ»Ú›Êª#1“¤gO€äW ùçŒ}Çûdí›R# ß”ô*şİ¤ëøw€GÅt¸*’ï{	‡½âêúã÷®I
!qÜğ‘H¢Ï”ÑŒ«ÈœÚâMZ:úÆëò!¹™4£ŸH’¥ø	Y ¢µY±X8§{ ¦&ˆğ¨&Ìg"qè¦p¡cu}ª«ùšìj¾¿¨sŒÏmœÏ§ÔFwôOrod§ôt%º‰SÜ×&ãµgÌ¯Œ}G1xÓw6î+ ,aTÜ ±õÕõ;›-­ßWÃàËÍwêFİ­‘LëDYíòA(%ÄD+#æc]œJ§‚ød$:ó kÿ¶kºKOs»«ºº•üGù`—½;ÑC¡Üõo§€‘œp¥ÃÕT[ÅÔ(²ÔU+/ŞH¨ÙØĞdš$UYm¸\Ï,	fÓ@™œmTÛñ å„Ãkª^•*¥İ{<¥¯©İ²7Ù“´Ë/Å e7¦’æb}É>«gŸÓ%"ö©ÂB˜ºeAæÁN?¶!ÌŒo£0LñœU%sFÓúª¤®J<Ê‰oLJ.Y«PUkPÏ&Ös]*rT6+Y­Œ×ÑAÁ
JfPÂÛ&Û¥¹ûøi/C”óŒh9Õ&oÛû†‹Xfkü¥´Ø}à&O;'©NÊêŸeêÃò3‰çg×ŞÄgK³¼?[×7ı»Ì İUö±¡=¨š¸SJrG™Ä¥ƒJëğHçO©</	eôÚÖvvFNÑ±Ë6kÍ)e)|¡ìÖ¶÷î|û~­˜µ$ÕÄStÄ‰ZIµcJI—(+ë3Õ«Rù¤ŠuŠ~Uª‘Ô±¦¬3Š±7NÆèÈ~ÎÕY©ı‘ıL—'Zã|ù0ŞËù…Hb/Ë4<J3²©Š*~ôq®Ì$nĞºzZ=-Ê˜R¬$*VÌwï¯˜z'¢Ó‰w"ÚÚYU‡¥(÷m¾<ÍˆÑ°¬dOĞX`
 ¸Ş’0~ş|Îi®M	ıUàö0C	®ÜÓ"ÂYFS·dJÁ'†tw‚V,[¶sôııÜPc° b¾é¢+Úã²)Û
Rß—àWR	!®¤¾OTŠÌ¥gW²«¼qjšQß'Š+JY©¸ò~	ubóx­è}¢¼0)NvC¼O—ÿäâÒûìÂç&YC¼/­Aµµt=¥+»êÉ/Ù’Äb”ÒûtUßWQßÏh*Qï|Öì¤NUYõ2º†,1ÉYw¹6=£(ÏI*ÊŞgU v›ßgYŞ+Åe."Ò»µ‡Èãwâ#1<ú,‹ `añn³ö)3tçw¼Dv.Œ°ÀMàß­J[á®ÈöÀS“”½¦&±m@è*.$ c’ÀÄŒ¹UáíD®MÓƒ)÷§ô¸*Ñ-kpÁ£ŒÈDÄö(şˆlZ‰½ˆmRˆD™;¨ âŞäåH\ŸG€ Y( ·~T€†VHMTSÇ‚”¡zÂ!ËmI¥Ä¼å!D^Ÿj0J>ˆM/rWğ·}FoÔ@“†rå'@•ÔÙ¢P$°‚üH+”JË>%äı{’5Ûûí(:>-O­HnH¬—Ÿnì®¯á¿ÏÅòSjJJâ38F]¥®uSa¬¯ ŒÕÏëÊ€ÙX­¼«VÖ2 |âŸàÀˆÊöø¼Èïaú¿)é¿I,fhøW?ÑN%ïñ)FàoÓ¼dZè™T \>èGÜv¦¯ÿ¿Ã÷Üí!´û—„Ì}ÿfWĞ‹ÏX2¨gBè~
o°ó>p´
›ª…pÌ½Œcg€¸¦3|ª>Àx W‰. …bóÌğ#éuUº9Å r¥©zE¥TÁEŒ…ğø”JèxhûÑ×È?R¢kº‹!”¨´$”^z£‘ç 3Û]U»¼BÏ5®wEËÚìì»Å¢ô^b˜o³úµ²Cç}Ìêûû÷	[×###4/6ÉÈ6\ä¬Fr-‡*L
M·Cá Ê³_I0¦-Cf2Ä Zdİ·i"h©²ÄòâABÇHØK>!+t+ƒÖ<ßb˜]Ùğ¿Ëâzo²Adãª°ÀÃ;PÔ°ÑıDVÙÒî§”b¸Ëå¦!q¡
–Ò1Ï±¸]©Ot>*Åtû+L	\‡ºâlûò:ÌK4|áE<|D%bèÎA}pzÈŒğÙmJ4)›¼2Ç˜<ø³ë¹%©-ñÊó¯ßâs6›ò8qˆB:æšÔ}L7ñĞƒº|µğùq¥ù¡&ÂìÔlzàã –¯ï€„ºèĞ7H0Ä˜dÔ7Ä¦Ûù$ÙÑÕ”o‚.$³Øò+É™°ÄuÑ‚N‚@+ÂíHØÆóWÜ@ì fÜ‰S8
.]µÇ<n\ûJ‘¿§%ì9~ÃÆŸwÏN1…SpFq
¸”CØ'¹‘É‚NO™
Î©m8§R-QIÜöÍ©–°cä7Ys*5f˜Î©ºtsÂE a*VŸ1M$â‡ˆz·Õs'	`¦¹à´•»˜Íj8eè8½á)ŞœwîJ†¡BäÌâÎîXõêO6XE„å‘r!ÿÀo"¢Z3Ü2„7œ„f„"'¶º.„Àâªj2‘mÉSÜHÂÃ6íŠqúuæ´‹Æä{•’¤]PŠP2{N+™ô¾¢¸»§•uãÏğ—BYÒ¾¢‰`Èò=ÆpŒ°ØCæ.›²R—d1€L·£DRW?Ì,xG2ŞQÌ‚wbÕ#~N²QÌëÁw¿ì¡jÏ¹£"cfàÛ—ìÅ´±!!ôŒj0x" ”
?ØvœC…ûÿ%š–2LK½Ò¶ÍÎ#4HâkO¢ä*}gT’"Ñÿ5

Á»rká'òh^Â*üz–Ò_	KdÎ_„H—F—xîƒõ|ÚiŸEy¹Ñ&¬Ä}î#9ˆ¥Šù³¡’¦HÆ5"gMøY40-{4g¨d²*UXîVã’Ş©"†=MU1Ót ˜r‚.„v}á!f·T_‘¦tš¦ÒşB~¥ìı} ŸtCOnY÷…;©f{¶Şidq€%w™/;ïó¢VbÏª†YÃÃ;Fa+Üæ–Šæ67¸Uxwgª!nÏqwÔ>íÈaôøï"úÜíNnKGxyÈ¦½w¾øèö"Eî•£€ÑÛfnäìÛ46_| ‡^:¡°1ÏW‚43¯\"#ã’İvl°æ!•,…^D¥&fO`Há¤ßã«Ñ˜jÓG“g]È]rÁîx§†6›3¤érR•ì`FÕ©õY´ÎøL¿ÁÎDK½ê±@§O¹Óç"şT›Ø©ÅÅÄÆ|+/«ç£1Eè˜Lf¥ÛAp…W2”†ÁÄçèˆğTUr–¸•<cœ¯¬rø1ÌfJ?ì±Dº·—ŠÜ#Šû/
co9×Äxº7T­Iâ‹”¼ˆu7•u—enL1á©‰%)°Ø`D+´) °¬ü?–gV–kÚ3/ÿæKbùŸšÕ–Ş"š®7šúÒxhÄğù•çÂù‡£ËŞa§<²¨LòU¯O›ÿZ«åÿó_Ó<ÿ×c<+‘ùY!Ê«Eµôîwn©ã^şóú¯Tâ –g¾åü$¼}œÑ˜fn¡†]Ñ5>P³P–¸…Ÿ³0WH…”qìÂÜ¦	æà
LcleÒbŞ§Á…{@ØÊA*‚ÆÒ®£ôGØ=läx_1ô6¹Õ úÅğ¶¡3ü'œPDà÷+úûµ7sFÀ#ÁïÁi‡PÚ¢éX•]‚%®á™”¢déÔ@öz£b‹ïD„^âí|ÏÇ˜jĞâĞ£A1]¶˜¾;‰o+Ã¸'†QgjVÑînØ7i¡×˜0
{äùBÊ¼ºpLjã §kûÆŠp¨Q˜Ê›][êD¹Px*ˆæ)VX<qfïÓôôi”ãìéS>,›,Œ0SN¸·"Ë<E©€ô&®I£¸Ô
ƒu!‡îBbâĞ!¡tàğa`|éÍhô©ıdF+˜iÌ9CÃG2¾B{x…Ña T„³Å¶|Õ.“}ZøÊwÂĞv±¦ÌcÖ§L‹ŒÙ¬8îä#ùşğŸÿãÿX!{4«"4­wjãíCÇN,Êæ¾u—üÑ‚ëJ7ôA.º íTÊ¦™ı‰K§Ç½fñÙ:À,­¬àEÉdœ˜®(B=uŒ„}üJóºqçõxèÈS®?~í0­eò.‰¬_iC1tfû	Ãk}ƒEÛaóˆşÓ?ıM@ÈôÎ p;«·(?™V`¿'•‰¦W‚X«V%İ)]0QYI×Kzí\¯ïT·v[4PÍéfÕÃ3–×'U×¿çŒD+ëÍiĞxšfêÚ0fgKÑ1gU~{3‘·¥‹Ë÷ğw|+c?OfÂ#PÃ‰j(jéçmıF3|Dï_z(‘"®??³¡9X”Tqå¡}&ë!fúa‚‰½1Üåtp¶KiQÏƒ¥;ò,{´Ä˜ÊĞdÈ$ªLq‹£LÇğºXªÂMÍ{$õã:°ŞØ$@Û±zN_<1s‰“:².Üp£,åyMX¬	*œÕM$˜İD<˜|¼âNcPY`»=û>c¤’É¦>ÁpõW¸»còv´>æ¹c.Ìˆ6ˆøN-jV	áÖÆîÔAÇñªĞ6ŠóZÌX—sZd®AV›ì§ù:DÑPÈÍNi4v¿Èh6úqî*ÏâNszË7ûl¢«ŒËÚ8ësÛ~ˆ‘¾;=ğtŸÜ!•p4NíqCo€›d¡°/oÍöGƒŠf4a(}r×1Äb%zü$|üEæŸe¨Wê=}Ê]\l¥]siNd(“‘¡¶•]û)îÜOÉºÇX$iÏ¥7Öºo(Şt,N™ÒÒÄô¼"ktm‡+|3S¾A©L²¤	Ûì "Z¤
{ÍÅ†‰0˜ü˜)a\â.’€Ì8õÊ¢°p²·JZµ¤7Ïum§QßÑ·“Gô²VÖ„D²”Öo!¿L­¼§&Hc±fÖxC[B*‚zWø-R9ÒˆIÏ„”ålIv“c0„Ø!åçv ²<D/®gÖÍr’M7ÏğP:Ø4DæÕ¶ñtİ¹õRn¸¼Í8¤é<ñ~ªbM÷Èæ/âØJmÆƒ¡ §nêøó,¦‹€R]‹§‚ª(‰L¬8/p–+4ø4M_åGëƒ^Ş*kçz³:Rœì7MyÓyèL|_£Ñå`Ã’òõÍ¬Æı\#……”nŠÄ¡½h>«Û¬q6öïYhug×š·³j¥¹Á¿š²ë-°²+.Æ æöw‘Õ÷‚âÈnĞØFEÍšİ:¯ÈC²€pÁ>•ãr6IÄ£XV[|½ˆä$ƒ”x;`ı^L: Ü“;L‰œ|@n®Ğ¿â;)\’â»U“ß0*Ş0e^G<+˜¶NI¨à*¼E((W	¼Í£%s4K/“ßå»\ñš¦ÓbT:½JVe¥e§–?b,ù;Å(şjƒ)[ò›2Šç@4úšÈøŒ™­gödoØ?,Óly|=t(ú1¾ç4Ş:+ë˜vâwÁ`ı`œø Ù*Ìä/0Ábµf€¥‡eÆsBKl&%ÚLH‡ùÃ¼Ì¶µøŠìŠŠ,£3çi3ßV2õM’Ò6«9\T‰Öøù	DëÈÊ6î
‚
%ë	TïMvoxÁ~b‰aQ<ï¦Ğw”ËJ¤een³ûN2D{ÕqKË2»hÙiùeÆ*·È,¥å)¡‘Ñ]NXxµ[,©ó²Ë+Ü´¨Š(A‘îuööõ‡c”Í[khù-ZôÛL¸#ãƒM¼›ºÂ¸XÔÄŞ\„StœiH£=4ºÌ<3í^yîğZwÚcbôC;:E"	ª·ø^J]R™àú´LşˆeÕÄóRøRVŒ*1lüÜ³1n	y©W9cš²«<•÷]&²`6fnŸ¾`Jæ%%e^xñ¬Óì‹qåõ(ÈycÎ*™W‘ÎÊ
†ğ”TF8Ömß¼pB›Ş)
/®#½ÆSq¥…Ê.¼¿òüL­Œ~ ²‚Ši®¸b,ºQz!J³ >LÇ%kÑÊpè!(F<ñl€6‡lÙnÀûP-«”k¸m¡á:2oR7iêãøRUQÖ–1*ÓÂÏxƒ˜©4Öbúôkßd~ûx.ÃÂ>²Ûa!Sæ•Éq”-Zqä¼r†ìrxÄ¥sIU’Ê/Ò¸‘²
ˆÇÂwYğŒ^Z9›=:
ºÈĞ6…w“[‘8+W6 f¦H#F\°+õWT 9ãwÏLS¬˜KÈ[ajzÊ…Âg
‚$ÏdÏf¬…Gú3ì¾Èçä,³o"½¡×°ü
_„{B4' ö1+¾ÉÁ;n×ÂÒ	xdW8R0%l¨ô8®Ba€cí¯CSçQD«²L;Ä]‰ÇÙaULùb¡z[™Ó8ò›L¼ç˜Æ8Å×›üJ†}Æ@]Ô*„Å¥ˆÍNèñ‡#ÄUDÊŒQe[Cr†ñ!ÌÁXô8À[x±uP.Š_gY´ùP”¡Âæ 9-”¸BïyCµ7A‹ïÅ‹*“wÉë§»åW#%$îjPùÒF•Ü¿Ğ:‰Yƒ02¢ ÃÊHàÊœk˜¼¬>ªİS(.™›;9‡,Ö’:À„§{L›„´Ú³Î¥7Ót¥Œµg£qÈ•ËİY¤³õ~}€İd…éÖÈ×Õş#6ğ–í¡´¤†BÚ”aâƒ˜9Z©¾¥,²³f­ë™Y©»#@	{¬ˆ‹ ×`gİ4üœæg¶)ìIúFV¢v™¼ï×ÜœOVÔ,M$MÆ÷”µ²L·”—É¡Ç2&ÃThqèÒ˜jAë¿‚£,7Gz5´?:¸·ÊâÎ…ª=ÑÍInšdÔ4`\üõ5g?©mmjÁìí.sÓ#3ŠŞ®+MË—È›dÕ´¼^Ôé~M^¹eö:ãW¯]b³¦³î¤·bÈ_ïÓ´|y^&o"ñM4ØI….y Êz©«¢i#£oÎFr&z(º	v*$	*V)Bì¦¢Z’å]Ü²T™”‹èĞÆÈ›¸!“g¨ÜÁŒs‚¦€“‰E£™"1—sbá4÷’¦'!ï‡‰ÁS,=ÉSŠª#«|MlÎÙŸ–ÎbîÏoe¢±»ûô‡âPŠQp èV¢·©:]n)™:¹Díuæ(« w©EÄwz¯%]¡Øbâ1òÛ_Qm€SİÒ]ö€‘‚$}å_ÎT,>ã(nÒa¢Ã)™ƒLCW¥iøÒFÅ%34Šô-€ï¬QüAnT-˜İ(–Q›šşdÏm
–ÇÜ¦ µ›Ëêßå¤›Uç€®
•«döö_QâGC´‰ƒÆ´®*Ü=éBdôäâò„
Ê.b ÒÖ¨dò”yŒÁØï—/âû¶h÷AÉG×¡Bµ\c(d^gö;ëÖ¸^OÔù#üÎ˜ª0¡ŠøbD@»ëôhGyGÉ°)Kc6eGQşÊV›0˜3¯LgI³¶Zn+†BW6Pxˆ§ôÏ\mxÄJõünL>1X|]à2a†jÒTP@O“@DñÎ#	~	T<ÓQÃ¨c²Ÿ…44mSQ~ÊBWJş$
qıĞt[Édã™Û8k|8¿qàä’(~à-Ö2=´|P"I¿gĞúx®†Ú.2N<}ô¼K›²ÏƒåÈù·“Ù¥I`CÃ[ˆçÜc(Åæ# 4	±
€÷ú	c×Ğø ‡yªÆÊgíğFÍ—Å×V^ Ê	TvcUgœ;µ²˜H)_WŞ~F<|Ş¾ÒKÙw‚kŞ(j d´ü,@±Nm>¸D,ı,pIMÜ| ‰ˆûY@#]ß,`|³F—•ï “3Å‹ğuÅã©ãJQNÊ	¸¿R¬`Š¸Fèo¬ƒLÏŠz
‘í}S¡ÜGbBg`ıì>R°òœòèø\µ#óîÔôÅuæ‘Úì Ç“*äóBçÈM•/ˆwê°f‡]¦k£ëOÙ¨(a¸ìâÒåŞTr‘NŠdr@üM`«¿S=À›Ò$¶$AS¬)4Œ¬!¢áoTég!8ŸñŞÏsÓŒÅ0iNfzP @3U¨½ Pc+†9…ûm1˜Ü¯Ğ›„`å:0M±»h™%¤?Ì@úC|?fàM³1°Køš;èÅËƒr<MD¶ÓüdÊˆ ø	‚x^æÂBs@$7ª8mB¼t¼©ñ7Ì;Í÷n‰ÁÍæVQhcz%%‚Øg4ğøü*™«CÁ†˜Á“tDI¥œN‡!)Tjú¾P+:$õlØâ[ÇÍR¾ãÀªjv~oÈT%Õº(Å§•ébQ²|#;««ÜE°ˆ²fõ<cX+Üb•V±§]¹F#GQ²oáñ‚N=Ù4ÚçvB”T¨Ho2Àå‚'ÔP_ ıQx¤DxKÿ¥ñ°	Æ*…£µ(EW	äÛ×ğï¤·†7-Ğ A[EôµX¿Ãq°S© ¢å-ã<ªP~bi$ÎIX¢µ‚ÊÆN¡ğ”¼íSOö:†"ğìèD¶ÇVt«“ŞÈaÑ¦éÛ[Ô¯@¥:p‰óX t›ÂköÊ"—z«ÀDµÇ°EÙ¢ğ&Õ²V&ö&ÀR®‰×£×şLèøZL1¯BŒ|‹èvWWWeƒ,{ş Â›*û/;GİN	€>Ùüîşÿh´YæÎôË‹* >³ã?hZ]¯FñšUã?TkÍ<şÃc<…Hè:µC¸DÏ£Y`lcêÙOòzŒ)ñcë/z§¥¦AZÇ 	è['ÃØÃ}ĞùÒ3ñeºşùˆ—ƒã!Ú˜³şa±'ãÿÔZz¾şãÙªmUCÛÚ¶›ı­†]¯5´^£W·´­~­aWk=³Ş´ú­:ù}¹’á?P­[-½VÓU«Ş2ì¦¹İ¬×4k{K¯÷ÌÖv RíØ×ÀìW›½Z£Yë[ÕmCkYz¿ikM³Ñjé–Ş4¬-£f5«¹vì—ĞlU{fÍÒzú[€¸[ıª¹mÔ­†	èhıô )Õö±Íªİèomµz6à«oUµ­Ú¶İ2ÌZµ·½İØ²«–Şª·L¬™i`nÕm£ß4ZÖ¶e´zºÑß¶ûÛ}­_3­ÖV«Ùo4ëv£¦µT ¬®Ù°·¶êõF½glÙ:ôÖĞ[öV«VmêıÿYÆÖvÓh&—<#¶·´­fºß‡Æû}½®o[-ìÈvÍêÛUÓ´4­Ğ%èE±ÕhZÍ¾Şo5·ìí>àßÓÌ­~Õ¶šv_k¶ZÛõZ_×l¹ZÒã¢n÷ôÆV«AqÕZÛÛÛV­aXz¯WÛ†ù¨µ Ó0U1ÏŸÀÜŞ®õ¬Zu[ß2š=ËÜ²4ĞÙ6«zÍØÒZ[ğ++Û%â63šr…PçV«õMSë÷ÌªiÕ€¤l]ïmZ½Õlõ´­–mèšÕ7[µ4(ÙÃnZÕV¿^mn÷ë5è‡±'s»ª5«¦Ö«mÙšn¶ZŒÎÉ´Ò°·-[«Ã¤m5-.æºÑk˜]on7¶u­nU­(’ïÇm(.{pîH{)`·¥Â€$=6´ºÑ¬m}³Qßêk[¦­Y¦in÷mà*šŞ·kf¿µUËæ´LU«WíjU·uÛìm×u³ªYj­®ÕjVCkUuÓnnÃf¦‚“\wª@y°ğ£™jËèõ{@—ğw]ƒUcÍ¾ÿ·Z* Õï¨¡Ù½-Û¨ Âfm«f7k5]×¶Mø¿¦ÛCk˜Ûõzb%<‹@€î7İÖ6Ğl­Ù4úõºÙ·{=kÀTMÃŞŞFìJ¦S³×Ô4½¾UoÙ5½Q¯:L"¬1ş°AFwŸ²yÕ¬ãeÕô©ë­†fØÖv–voÛ4ê°:z°Jà—š)jŠ£È¯T{ü×ÂC·±`üÇºŞ >^­æññÉÚ—İÆù¿^kê|ş[r0ÿõV=ÿø(ÏÊo¨püº#-ç$ÍÓ+dußÚ!«K…©l¿Ş$/Ğ/9ö0s¥7¦úÊß’.×I®¿Øën@®a0V]úFØ¤º½I¶€İ×°ï…=2l’î•şdûzréHã…t™=;)³|ø½=	/<ŸÿŞí>Ú%QmY÷ì`]İà]™i`şò1@­ÔîXNÕ^=0‚ğ%Ó›¼¸f3°‡‚A9£ şÀŠœÚ—î¼©"âVLÉlK­6¹Ç…|OŠö@-JN"Ô3MOv[sg;@ğxœìÃ¢¸é .wŠ Ÿä;ı˜¯wà«¾]ÖZåª¦7	!ÀÙg¸‹Ğ£KG $¢`$Üï
í,ˆ+ê¹…g´Ï¡ñ7c{s8‰Óa±" (5	V ĞxğItáêÙ±w"¹®4Ç+^WX<ü4Ç·ûh¤I=†)¸è4.Â³)Bp™µy&ì¸Apš„(»í@§ÓøNDjŒ¢vO{ppşòM÷ìøpÿÛgûÇGe(BKxAàÈ0ÉÅ€	-˜HÄıé-$·õV,´6{àdH
3e.ÁÄ;æY %„"`ªí6†€T{!UKœˆñµ‚šüGBM¹ÏÄ/mÈ%uX¶É“ rã»ù0yĞiV$»[ TQŠ''ƒ–bóÜ	4M¨ˆğÒö–<´®¤Æ‹´h:ì”ì©Øõ&ÚTıº0ˆDŸŠ%ÃC©ĞL´Í‹QnV(à=e™f–†{—\†°
c‡+Á[›^<——ÎM¿Í\äÏóƒ¥úàLSG'¡tz€6æİÿU›’ş_Cı?´\ş”çïşÍ¿zò/Ÿ<94LrÜ%ÿ ¸¾{ò÷ğ§
şğûÿ½ÈöÙÙ)ÿˆ5şüù×‰"ÿ"~ÿoAr(cx»<©íÅ10ÅÊIÿıøoçßÿ÷w¯~æOæ“P9?H³×¿/[‰õ_kåëÿq‡:ÿ?˜àgª˜¦øy+ Ô*¯xX)õ…Z¬Qÿ“inÙ Oy„ùæ¾tDHkø)ÃÉ†Š|Œä†Ğ-J¹3üôĞJ„¯@€f5(…c‚l)ŒWìóqûÆpé\»¡ñ‘ÍÀ÷íÓİï1zÅÒ©½ºúîÚ»ÉŞ]ì¼»ª·‰ÔZïÉš(iZ‰D–ñ/Fv’±¸@oWŠ¨¿*YiÉéefp–
˜ÉqfE9.{‘YV*0œ}‚â’^/F9‘‘ü‰å@&óª‰× ^‹ƒhôšb”:;{¤\öåñÑ«E„ÍÄëÅº,iööO£éT7\K¤cK :ÿ@}¦ àt) Ê‹kÑvlÿ„’Ÿ‡ÏN¢ç0ğ¼SñXF‹–;‘Üwi%-cÅ¯Ú]£K”EÃá®= ä‰–Ó~¨vŠÒˆS£m5¥6uÄÂäØ–W`*	¬¾ê$cì1ƒbÔ¥ŠËsíB‡c“}Î-w×L‹ÈKûÙ'\ÁdDJ&IZÁ‘jœEúó ½J—¤¸CÿTüŒ{M1¨ìWíıƒÎŞj¥½[…·/¿k½îìUŠÏLV&¥Ó!÷É»uÌ.íPCñ¢ÜZ‘¼Û %šÂ\ûüÑğ0ıZ„İ˜#ğêãe?èg¶¸’õ{RêWe4Ú{{‰›ÏÒ^ixÀ–÷AßÔyøÖ×?ƒôKÌŸ.ã {"$M8ø‰”ÎÈ?ÿÇÿó]IÊ«½ÆG¹l<¬	N+êM-Åæ3.z!JJœ6şÕÉ” Ü6£P’ÁHå/¦–—
gE6—¦qh…¢’‚ŞåRÈgÓ¥0‰¹\
ÙnºæH—J¥KH¿z=uX•³@"ò+•„{¡‹¿ÁKÊ¾do°R)ôáµ‡Cøı²öHÑtwc7óCê8ãùïÂ’Êˆ‘YŒ„ Nc¥İ›Şì‹ä*ü…
PlVèyP¨o¤Ô™ÕuñqcvwFÒÜDa4¤ˆf`‡çLqZÚè·1û‰nâ%®âÕ°¼»60cCù)´ozCÏß5&¡Ø];ÀÈí³ÎîK‚…AlüL3¸E…²Kõ¢ßcâ‰6›¨CŸ¡0ıèUÀ^eáyq¼§ÔW
ı®\RÕÖâ“1ëë$êih ›>ZP¼¡Í^Hæ·W·oWz¨IÕn@¢ÂJp;±K›âÃîšâOö…Vm|2ú²ÈÀ€ÃÈğ¯Z“$áğRzë†¹!²µØ3òëİÌ§mÎ—·»vé¤2D‡F@¤ÿ‘õÿ²¡ç2uLêÿkz­V­7ëDÓZ+×ÿ=Êó•ëÿ]®ÿÿÿÛË•{õ32Ÿl3ïå¶1gıW[­Ôú‡OùúŒ'×ÿYı¿â\ñ‹¼½îgÜ$¯äP9ùuÀİQø¹_,¤^şrêSBVX¤7zaéq¿S4â‡µ¤`0ha)øì™õp{Ì<ù¿^­QûÿšÖÔqïÔôj«Ëÿò¬P+%7`V°DgÙãĞy¸wáUş°+_Ö¤—İèm¿mS½xÛàoO%]Ÿø­‰)F#==jÛ4#à&9ŞÇ¿öºaáíº‡…•Û®%Rˆ“¾îèµ­í½YkîÔáÙÙÚ†¯ ÷×e!˜íX¹Ü6æÉÿ†äÿ¥aüz£•¯ÿGyrÿŸ/âÿ“tdş¹JşS<€²õÜh&Ë•ÔGN/,YôşzoÖ±Îñ«å ıÒ|~ÚƒéSºm1ÿoûë-M×©ÿw£•û?ÆÇ~x¸6œÿz«¥WÔÿ¿´Ïÿc<‰(=ÒÆí×­•Ïÿã<jTœ‡icÑõ_Ó-M«áü7|şãI…1z€6n¿ş1H>ÿñL‰BµÔ6æètMo±ûßz£Ù ñ_õzÿñQ5ğz^óàQ*B×"ı(Z¸H4ı7F0¾%bÿûrü’ç~0ƒx“ÄË×qG£BÛß…ÂIûì»İUü{g•¦:)G¦Şü½í"P®pï,Ú?çdó†ğ‹ç”Ï¨üëÒ}ç"ÿK—ÛÆí÷ØšùşÿO*öã´±¨ü¯kµ–ÖÂûßzµËÿòÌ‹ı¹Œ6æÈµZŞÿëô†úŸ–VÕsùï1eéÌ“sûnß7‚ĞŸĞlÓÜ%À"]i7ø’wrÉë¸d´Û¥ŞÅ)µ“÷p°åµÊzµ¬Õ×oÉk6–W—f”b¾•Y²G3C&îÚ2/Êxjn®··w@ô²F~G^Ÿ`b’eí¡gÑd:—À¶ÉÀÁô0¬{ä‚İ°Ñ{te"Gü¾Ïå‘£‚ÊdŒfàH)gÇ{Çå¸wKÂ”%"^ 	Ş™¦‰–€óœúzĞgj•yÙòÀ××x^Ï£öagm“itòsV¯¸! Œ£„éSàá `.m‘ø³òMP$ß	‹u£>fD@tÜp=	•9Y¢ómÁY»¸!*ÁPÔŸU¹Û=êWãú<ÛMë«û¦Û9ÅŠWv¤KÇ,FˆÃŠê9–ín÷‡ãÓ=8À¨û
í2ËæˆÏyûMğ~-1ÏÅ£¼ô©â8qñØ,‰$ŠÇ£›,IYdi>œq…7ñød‚Çñ‹KGy"§”ÆƒÒ±wõ]±şÙÊØ›uÖ_Ì;,§íÚ•Ça³@R˜§xLXµx<fÕBJ‘	R—Yq¤¤ÅÏ¼Zñ¨í¦Æ©ó¸ŒÒÙ—Şb¿êgjù%¶1Gşƒ]0uşkåòßã<¹ÓÇc;}ülm½ƒPƒÃÆ™ÑL²]JÚ€q«Çö¸ĞËºö¨‰°¾qàU9Æa]çIš_§cÂ‚Ÿè~‰YÒ|XôËÈ	0è²÷~c¸Û _ç'ø¨i
7¹â÷Wúd¥±Yvóô?õÔş_o6sûïGyòı?ßÿõòñ£×cşù~/¡°lxW¶ıaxMúÌ&ÍÂÊ{}LhÙÃ#yB©'Ş&Oá?†‰É<êÅqœ‘‘”BòêÍÁ)Îÿ ¥­Q6/Èóç¤ÆrqtÅ­>ÿ­^x€á³FÏqMŸæ¯6¾Ü j›ÕÍÚf}³±Ù¼Ópî½<ívÎÚ_Ë¨rÓ‹ÇÉj•äÓEÇ/J/z»ûÒûğ—zædÖ\Jóä¿fdÿâÆÿhéÍZ.ÿ=Æ³´‹î»·¼ü‚Ò¶rLI’Î@@Ig–…r’´VÎ’Ù6Uq!IHl²D&@h­2ŒÅ8¤—€XFÉDŞÌÉR˜øåÈ4’â/-qHŞ0ÒjkÁ5à82Ã!±]š‰ö4ÑQIzõ”¨Ô‰ş7ˆà1
oÂ" CŒqlÀoUh±Ÿw—ÆÊaãÈ:½ÉØ(“¶õ#¬NB/ÈÀ÷`GÛ>JœÅˆŞ®Éy¦ˆ–iRšø	¶Ğ¼‘…ÙQ~&–GÌqš`Ó	üÊĞéUx7ù¿•D6º>«™Ñ@öd¨d—ª€–ÃŞ[¶a†@]áâ­X¼ú¼fºh)C%#ÃÃ™À©ç ½ñí!{3ÁÒ-œ&î¥è)…ÁúÔ¶ñÑâÇx¸ï*ñí¡Í\R	œ5àÄ¡k[ÔàÓÈæ<ò‚—ˆwá-2€÷…=›Q1FIÄAÊDÈ†Â†»®^yş‡2ÌÓÀí~hûÉ—¤ğ–óå÷…³ë±½8°ÀíŞ±íâ™õ5®>úé¨‹+Z½»Iq—+šÿ¿Ñ6bÆ/Ä¶Iiíöu+”Ü~°{xˆ«˜7¾¬…çepgÎÈ¡°k›»5M+ š®eøÖñ$OÂ] Î¡7øé¹Ã#~í`ÄÑä0¦œİ¼§3çóİÑd:%Dı—ŞÿggC_Nsä¿Œü¯ÍV=—ÿåÉã?äù_óü¯_Aô‡<ÿkÿ5ÏÿšçÍó¿.‡›æù_zTùŸ3Ô²Œ—ØÆùİıùı£Z¥ñ­Z3—ÿãyÛ9z½Ôy_8µƒ1pz›]ï~ÏS/èeıWxûºsÔ9İù¾Ğí¼|sºöçó7'À{;İóï÷Ûç‡fÌ­ûæÍÅwûÆ0X®yş<Ä“uş_vÈ9ë¿Õ¨¶Øù¿Zmj­*]ÿõÜş÷Q<ş{ÿ5ÏÿºÄ9Î¾ßñ<ÿkÿ5Ïÿšç½gş×[å&ptvZÍÇKóùÉJo›/uf2Ñ[%{] ëì,œY™6g¥æÌÊÂ¹P’Í¹©:çeá\z¢Í™y=ó„›d@œ‘°4•ˆ2Oİ9'ugD8‘DøKë~úßÀ£Fİ[bóô¿ğ6ÖÿÖhş¿f+·ÿx”Çq/á|kíæ<eCEé( äv>`†`ü¢àKcŸ?÷}²í¿–›	t^ü‡tşÏV­¦åëÿ1\ÿ›çÿÌóæêàÛô)ÏÿùËÉÿ™Úÿ è<ù_ÍÿÙÄø­F.ÿ?Ê“çÿüuçÿL­ÿÈ:OşOçÿl6Z|ı?Æ“ûäù?óüŸ¥¯@VÏó–¾&ÁûW’ÿ3µÿŸ‹úå… ™³ÿ×šµZÿ£ŠşŸ­f­šïÿñäñ?äøYô_ÈC€ÄÏC… ‰=#èÇfŞÂ*&üG<llÂKÖR‚€,ĞÒ=â€,ı¡@¦Â^"OøÅD‘u7D’RwO:G{İóÈŸq·HWº0V~´>èå­²v®×ë•¢üCA©ìaZ-”º,ÔGÉB‰ò¯“C}Ì©é“OmÌ¿w‹ª¾ÍHZ Y^d¯)4H"ÿ3ÇØ9GÒ.ã‹¥´1Oÿ£1ùOŠÿÛÒ¹ü÷(O~I›D;©ªQÖÃÏVQ³Ç•4RÔµH4§Â›K€„×ŠÒ?©ÅùµDô-X0„–¹Ã7á‹ç
–¹C¢—¯‡±¥Ì!|Jñ†+¢C(¿ÀÂ šî.İ>ƒÍ,Ø&”`?§«'Z2‡/=7Qßö#È'¶õTÈìç[AşÒ¬)ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'f<ÿ?Z2Ä 0 