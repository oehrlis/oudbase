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
‹ _¡Z í½]sÛH¶ è™İ»—O³û0111›M©Z’[$~JrÉİ´E»Ô­¯åªÛ×vë‚ H¡Ll ”¬²Õ11»û´oóöaÊü‚ó¾/ûöœü 2ğC%»ª€*Û$˜yòdæÉ“'OãV<ğ£iZ«Ñ ôß&ûW«ÖÙ¿ü!z­Z¯iÍFC¯M×ÍêÒxhÄğ™¡á*gÏ,Åúı¿ó~DÿşLÌ¿7±Î¡{á$(ĞÆìù¯64˜s:ÿ@ U]‡ùRh<!Úà’z~åó¿ò›
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
‰8Òj»H°F€zÌÉĞ#œ‘+Ûş@\ªŠ/u~8ÿ¡ÓùÓÑ±¤sySÜ(ìÅ?À .xSZı„7 7´ú‹öË?½99ïv€òX£çĞ(T"J-ò%hE4'ÒÃ&fUQÈ¨¬NÑ^ªÏ8I´£*FÀ_ÄßÌ†W³°+Nü¿Yåe)dµK¹õ0¹¯§j¼ùÕZ"g€KY$ã|°:-ïtÓW,º¨¶Êœ’¨QfŠjfÍ*q­oüöCjyÄãÂÊ²eåğ¨OÜ¼qSÁŒnğ³@™ÙÕO*.R¥ÔOš‹Ê¦¢$kîøq<¿ôÜ¾3ˆ§qŒù ™‰š1Ş0-¤tò“Ù_dŒ*².ƒY?±cŞËã£Wäù´^ÏéšHF .Àƒ[ô-YuÃœ6´kïá†vºV1Lx:úAY¥¯õâ+­:–96zÉ9šÉ$ßkÚ8g2·8æ£•°8^ÜÚxº¥ñ‹ÌE}£â…Šy+w6(oLœÒùO'½Ì./`/œ·Û“ĞÃTI¦5è–Î§i- ŞĞB{˜=‚²İæ3,Å§0·Äæ?Ï~<£‹< !K‹´%Ä:E&I›‘û#Rò³Wfâü›™éİ8òä.ô½	Èúëö œ2Ş˜z±#r)-ÉÔ›£—›zßâùÒ¦¶_åƒÆ¿åóHÍú mÌ¶ÿÖ´ºÖDûï†VÕuÆÿ­5õZnÿı(Ïßı›õä_>yrh˜ä¸KşA°&|÷äïáOşü7øßÿÅÿ´ÈöÙÙ)ûDküğçIùøûıäÉ¿9¼lŒÇC»<4‚€ñ,¿rÒå0şGüëÉ“åF†éãhãoÈ’!œ¢ñ,/ûw¬ì¿K”EæŞĞŞw-ûã“'ÿ[éıG,ıüçÿıÆõG!´¯óQ27=P³×³Vƒ—‰õ_Ï×ÿã<¹ÿÇ—ñÿˆ,ñÎ¾L9E=qÑOÀi¥bÏd:ÙÜä!¼@´´ˆ§Ë±'‚^
!l à‡xhœ–©AhIË3?Ø~¦‡Øá9B(:\MÈî§`®BÿzÉÌâc"øŞğ4¯¹›A<BëÚ45µ­¿d¶õIJ»ŒA[/$×v”»L–ÜE®gøî˜^ğ÷úÅû¢¨(_´»ßwßœ¾ì¼ÕŞÃ¡3yºeº2^Ş£ùøPáÜŒ@M´ÖX·Ÿ–,¦@ö32¾²Hé>·êŞpâ-{x U°¯şğ7‚‡sõ˜ñ¬W˜ò¯cèô¼ßfü ‘â—BÉÙb>/.2	ªöÀ¢Aa¯óªıæ “ÿì±8ôö’!Õ¸•2ü0/bçjµ”rÊËIWÖRÑîáùŞ1q•v-™šZğüàøeû@.E£)L-ó@r“}Já1+e‡æÔR¨1m¦–:ë´Ï:]^s	R²¸ÆÉéñŞ›—gr/ÆÔ…,” ²Ûd4HâEú£+½Z®–õr­¬¥
¾:üaFa¦5>íPÕñşëİ"ãçôš™a±ˆÈíÊùPäŒ™¸™ş³˜„›™(¥vç´øY,kéÛNI2“ºY¨xF×¤šÖn–61­,íØ®l«5g`Š",r$5œ	ÜPğ;f-§$,]6*/Ê£`g´%ˆ˜2¿ş¢
´©eóMLáÓçĞTc	ƒlL$—¨%a‰U[\½’ÆŞQ;0=äÅñ!ãÀ©ÕG7ÜİØ ƒÆ}“§£x#9ÉàŠt€¡IĞb~ÆaÆ/äÈîCÚÄVŠ‰8à®¢X7É;€¦™È-<xšåªàUFËÀ«ïfÏ`Óêdˆµ}æ¯Yósµx•â·ÔK§Ø¥‚U‚OÊİU9cÜ xsßF+5üÇö÷mÑdôù–ıh\lh‘sÄ÷ÉÔ¢DÔ®Üyyv|úçsfBGÍ–8‰ß 1åE'öDè—"A.ÛB8¯ÉóDFìñÙÙŸ1ï=»¡ß¥şiĞºIMçİÈÕşh›ŠF…³Ê¨"áöğŞŠ¤7W_¹U23â÷	û¸)õÜfYÁ)Ëşÿİ †Ÿo‡ß%z2w´ ğÔË¦Ñ™yÛFüÎF#aeF£×C~Úş› F|ƒ8¼[_mrÒ>ûÍõú„my˜õÊ­É·ºŠ<Õœ´nHih'ly%^İş¾³wÀñŸÉ,J‹—Jß=rX„Z8&Y<Á«}¤lƒÕMõÆ-„Ğh˜Y&Ò"¦yF2‘6‘bV…1ù‚Ò¾odÂÒóÖR4ÙÈdí¬·ÄeˆaÎÈU#]Ş<e#SE0¹!)Ñã†dˆø2²Š%’!dm&Ù 97q¤_nÍÄwunÛB€€ˆŸ©-8Lñ5MÌ;Q.—cÜQs.Fƒ)fÄ!„
¥ò«èshô"•h¿±/MäœNŒ+¬©æÑ„z\[dÆh‹ò€ª÷Æ±iï0ğ`sA÷[¯¢Ùën	+Ÿe –2CØcƒ>I$ªğÌ¾³fš-ãˆì±/M8ÉsD¦áy‚¹M±O.L¥$Ã™—dëfA[z	Anq0ˆ¿½1ü=íÛy«ÔP7>ËÀp¶¹‚v({4¯c"(¦ŒÓrk!D¡Ñã¢ŠbÇ­˜™G?©\?!a¤,ğ©ï‘á^«0«¢b©Æ÷Å,Ç!İÇö¾7Ïä>1	ä¾6øep*—pØ)€“I4Î0vLæ`Ä/ÑNŠRW“L¸2	F>†'ªDVôJSiS+zŞ“h!/…§P_†ÿG‚înMsÓèíö´vW:[6Qúz0§	Yv4‚PIg”’kı­P0I*Ïâ¶täÚˆd6u+ôw¸1dŞ¬œ€9ÖÙ2¯ç”.VÓ!pl€M……şB•<¼‰ë¢‘Ğ³ºŸÌŒî%@±ïr¶£Ğ¬]Y†¨Óñy ŸÊ¯5SN íÂI@>%ozi89‹Ç‘-¯‘r`Í„ !KFç¦åìz@â•#Cqå½ıÓsşcÑû „üI(€èÙšğÌıM,<Å…©àU…ø?,4tjc‘[ÿıïãíO¼·…ŒiZ…ë9fá¸×ítÁ’chÁä<&z¨2½z| ?†ËCP–*âKèb)€Sœ+â×ãÖ [)ûî£H¤Òy/ªîù†9´Ï©‚7+ÁTÀ(Êu‡Ã2½ıŒ ²İù~4/ïó1CF«†ÕNÊv=³Âwˆîúj<Ê©šl®ˆRÿ˜u–Ö&Rƒ±VzJ{]Æ5xyÖäÍ‚k2)²1Ğ{ír‚ì™H¨``õ¤N‹vÕ²¼èy·{*Ş¦.™Å©."UáTò³àÕD…ÓÎÉ-Öõ£ôt¡%œtpãğ_ÂæämBdTĞšf§R‘lvh“xtF)¿;;;!ê3­;X´›Y4î0˜_ÊÚZzìeëœŒÓÛ¦¼cò­•bÈ¢åClœlÄpê™ÿ"®y:Älufiğ£"¸Ê‹É1W°#¥ô»Ô×¬§¨=¦:‹â³"´Ş…+¹l#ÊÄkvºªBä ¡Ê¢ÏÈÒKº”â£¾¡€»; ª
)øîÀjòN©Ü|İds:ÈÛ]¦	(’m<ngaF¤h%”ŠŸÕ«Ú›Êª#1“¤cO€ä	W ¹çŒ}Çûdí›R# ß”ô*şİ¤ëøw€'Åt¸&’ï{	½âêúã÷®I
!qÜğ‘H¢Ï”ÑŠ«È|ÚâMZ:ùÆëò!¹™4£ŸH’¥øY ¢µY¡X8§{ ¦&ˆğ¨&¬g"qè¦p¡cu}ª§ùšìi¾¿¨sŒÏm|Ï§ÔFoôOrodŸôt%º‰SÜ×&ãµgÌ­Œ}G1xÓw6î+ ,aTÜ ±õÕõ;›-­ßWÃàËÍwêBİ­‘LëDYíòA(%ÄD+æcİ›J§‚ød$:ó kÿ¶kºKOs»«ºº•üGù`—½;ÑC¡Üõo§€‘|p¥ÃÕTw[ÅÒ(2ÔU+/İHU<.×É3«€ÙZ&'CUÙöG<9áğšªJ¥JS^§„}}x<dR&[*Y ¹2%˜L[ñä99ûŒ,!ğaG•åËT.\&ùÿ<–¬°ğ½².µŞW”ÌMëŠ’z"ñ(§¼¬(¹d­BOïT¥@ŠXXVÏuév_Ù¬üeµ2^DBº”Ìş „=¶KÓæqIï!”³„h9Õ&oÛûFjXfküô¢´Ø}à&O;'©NÊª—eê-9’D]‹s¤koâ³µVÎäH+‚'á
¥b4Z
Ò*4*µî2Iş&©t¬€#]éô&•ç%¡Œ^ÛÚÎ.Ã":´`Ùf­9¥,ÉOâ#”İÚVàŞóŞ'³xyRÉ:EÃš¨•TÚ¥T\‰²²Ö.S9)•O*(§h'¥IeJ=ù0£ø»ÛdŒ^àç\”ÚáØÏt=¢)Ë—ßÂâİ˜_'$v£L«´h8UÍÃÎ•™¤Ó~VO+wÅCY«CŠ•DÅŠùî]âÓğîDtº#QàND[;«ê°å¾-*–•ì	Ş´O×[ÆÏŸOÃ9µ…ú*/ìa†
Y¹y¥E„§‰ämÉÎˆ‚O$¬Ğî­X«lçèûûùpÆ`AH|Ó=;>D?4feS¶¤¾/Áù÷&®¤B\I}Ÿ¨ÙJÏ®d”xÿâÔ’2£8¾OWTšRqåıêÄ¶å*ZÑûDya›ì†xŸ(.{ÎÉÅ¥÷Ù5„ÃJ²†x_ZƒjkézJWvÕ³[²%‰Å(5¤÷é*ª¶:®¢¾ŸÑT¢Şù¬ÙI‹²êetYb’³îr]tFQĞ;U”½Ïª ì66¾Ï*<;³8¼WŠË\DäFkÀïÄGb,xèVæ~oa.n³ö)³ç7w¼Dv.OÀíÇß­J[á~¼öÀS3|½¦Ş±e@êtt¡*u	À˜¤ 01cnUx;‘kÓÜZÊí#=n wGtG\ğ#2Q ±=Š?"Ub/b›”âBDÆ*ˆø~4yµ×çáH
èê q	RÄTÄÄ± eå°áÏò¹AÒcù$ïGy‘Å¦§:ˆ’O£IÓkĞümŸÑµn¤qPù	ĞÀF%e°(	¬ ?ÒJ ¥Ò²O	yÿ$dÍöÁ~;
-OËSLÀ‚[aëå§»ëkEøïsq£ü”Úa’ø!K©_ÚTë+cõó:ƒ²`6V+ïª•µ(Ÿø'80¢ª:>/ò[9˜şoJºÆïáŠúñÕO´SÉ8|ŠøÅ° oÕ˜w&(ozàw…é‹·?Â/Äğ} w{H£Ô>ÄsßŞ…©	ôâ3–Ié™ºŸÂ›ì¼œmª¦j2¡ s/ãÀ ®éL'Ÿª0ÈU¢ë;¡š<3|ÀHz]•î1~†\iª^CQ:)UpCc!Ü%$-zíÙ~ô5r.”èZA'îb%*-	¥—Şhä¹'ÀÌvWÕ.¯Ğsë]Ñr§v ;ûn±(½—æÛ¬~­¬ÆĞy³úşş}ÂÒÄõÈÈÍ‹M2²9«B‡\Ë¡Ê“E»çPxWòÔQŒ‡9¿™1Y÷mšEYª,±¼x¤¸+ö’CÅ
İÊ 5Ï·fW6üï² Ø›lG©¬*,j¯ãµlt?‘U6¤´û)¥ƒîry†aE\¨Â¥tAÌí*nWêJ1İş
Sg×¡~w8Û¾ƒ¼ó_xŸÀƒ#Q‰zƒsPŸÃDÜÂ†2vvMÊ&¯ƒQÀ1 şìznI*BK¼òü+Ã·øœÍ¦<N¢„ùfDÓM<ô î_-|~\i~¨-{'5›¸Ä8È…åËï ¡.:ô1 u¬0†év>I@vtu#å„ ‹IËµ¼¬Dr)qá³ ‡ĞŠğŞf;Ò_'v€Áğ
û#ˆÙ÷€^vKWí1w×¾RäïiÙnß°hëçİ³ÓEÉ„IÙ†.åMõInäF²?ÓS†vs*dÔÍ©TKT÷usª%¬ ù]ÔœJFzsª.İ/AH˜ŠÍdL‰à¢ŞmõÜI˜il7íBå.Æ9³N™	NoxŠ+ä»’aj9³€¸³;V]â“d‘#a·£ÜAÈ?ğ›ˆ¨Ö§áJ&¡¡Hcq­®!°¸ª=dÛÁ7’ğpM»bœ~9í¢1ù^¥$i”Â{ÌÓJ&½¯(¾âie]Äø3œ§ĞCV8¤ô„/ƒh"²|#¬#ö9‡Ë¦¬Ô%Y Ói'ÑÔÕ3ªİ‘Œjw£ÚXõˆŸ“l“bğİ/{¨Úsî¨È˜Y øö¥{1íCl†=£E¥Â¶' áŞs‰¦¥0úÓòV€´m³óp£8ª“(s†J_ÅY•¤Ht"*ğ®ÜZø‰Ü—°
¿¥ôÅWÂ™ó!Ò¥Ñ%û`=ŸvÚgQRk´ê*q‡õHb¹vbş,â¤)’qÈÕ~LË_Eœ™*ákJÖ»ÕÅ wªˆ1CS…ÃıÂcšRNĞ…Ğ®/<ÄŒâ–ªà+Ò|HóÑTÚ_È+“½¿ô3ÎcèÉ-ë¾ĞcÏl¿Ğ;Ì"î£äÎ#óeç}^ÈGìÙ‚@ÕexxÇf…ÛœÀR¡ĞæF†Š¢ÖîL5¥í9îÚ§9ÿ]„n»İÉmé/Ù´ïËİ¾C¤°·r-zÛÌÍ”}›¶‹ôĞK'”£&ƒáJfFÁ•ËQdd\’qÏîƒMÖ<¤’Å£¸…¨ÔÄÔÉ œôûqp2lúhò”ÙßQ2ØïÔ¸`s†4]NŠ@’	ˆ£:µ>u9Ÿé7Ø™h©W"æô)wú\ÄŸŠÃb;µ¸˜Øƒoåeõ|a4¦³‘É¬”`Ûc#®ğJ†Ò ˜øªJÎ·’gŒóñ•U?†ÙLé‡=–…öÖàRqo$PqÿEaì-çšŒö†j 5I\cÑt2#ÿP¢î¦RÖ²´‡)&<5+#ŒÈQy–"¾tÒ¯è±<³òĞmÌËÿ†ù’Dş'½Ö"š®7ê­'¤ñĞˆáó+Ïÿ„ó§¯½ÃNyd=P˜ä«^Ÿ6ÿµVKÊÿÇæ¿¦Õóü_ò¬Dt…(¯UÜĞësÜğxº¥{ùÏÿé¿R¡	¸¶eø–ó“pXrFcš¹…Ú¦E–4By¼°Ä-ü¨ˆ¹h€D*gc/æ7M0W`c;(“öó>.”àÂÜÚP4†hSw¥?Âîa#ÇûŠ­b°É1Ğ/†·à8á„"¿_Ñß¯½	Õ0	Fx•O{<„ÒMÇªlt,qÏ¤%K§6´_Ğ[Ìxo "Ôah¤à{>Uƒ‡Šé:°KömØ}[Æ=1ŒÊ8SËv÷p“À¡c“z=	£°G/å«Ç¤6=:“º¶o©ŠÊ]æ©8c°Ùµ¥N”…§‚hbuÀ€Åg.8MOŸF9Î>åÃ²ÉÂ3}æ„»L²ÌS”
HoâšÔ¶‹Ş0Xrèî ô'&KÎOÆ—ŞŒFŸš€f´‚™Æœ‘34|$ã+4©W AE8QlËWí2Ù§…¯|'m+`Ê<f@ËáXÍÊãN>’ïÿù?ş_€â¸G³j!R¡áÀ@Óz§F0îÙ>tìÄÁ¢lŞè[ÇpÉí ¸®tCD»Ú~pA
4"³?qéô¸×,>;CG"˜¥•¼ë™ŒÓE¨Ç ±³_i^7î½yÊÕùçÂ±¦µL~À#‘õ+m(†ÎÌWaø`­a°h;l¾ Ñú§¢	™êü nçoòE@Ó
ì÷¤2ÑôJpkÕª¤#¥‹&*+ézI¯ëõêÖNc‹Fª9=Ã¬zxLôú$£êú÷œ‘he}ƒ¡9OÓÌc ƒC[!Æìl):æ¬Êoc`of!ò¶tqùşî‘o%{òçïÉLxj8QE³ş¡¢ßh†èıBÏURÄõçïg64‹’jæ®<´Ïd=ÄL#L01°7æ»œÎv)í#êy°tGeÏƒ–Sšì„Yu•É!nq”éş`B×KU8£©y¤!a\Ö›h;Ö¤Ïé‹'f.ÑBb`RGÖ…'q”¥b£<¯	‹5A…³š ‰³›ˆsƒWÜi*l·gßgã€´S2¢`Á4@®ş
wwLŞÔ<·aÌ…ƒyÑf_ÆÃñBÍ*!<óØµˆ:è8^úÃFq^‹ërN‹Ì{%Èj“ı4¿Q‡(J¹Ù)Æ$ÍF?Î]åYÜiNoùfŸMt•‘cYCg}nÛ1Òwç Ş€î“;¤Æ©=nèp“,öå­ÙşhPÑŒ&¥ïAî:æ¸Aì¢Dß“„¿Èü³õJ½§O9c¢‹‹­´k.ÍIƒÅâ±a22Ô¶²k?Åû)Yâ‹$Íñ¹ô†ÀZ7ğÅ›%Àé1k`šØ‘7Pdnq…ofÊw (•I–4a»ƒ@D«€ôQa¯¹xÁ0“3%ŒKÜE0§^YNöVI«–ôæ¹®í4ê;Zãvòˆ^ÖÊšH–Òú-ä—©•÷Ôi,<ÅÌohKHE0£Cï
¿EZSR"é™²üEÉnrfƒ;¤üÜD–“+¡ãİûÌºY~¾éæ™!jtç›†È¼ºÑ6®;·^Ê“˜·Ç4!ŞOU¬é¹ÀüE[©Íxğ"ÄóÔMÅtPªwôTP%‘é"€ç¥ Îòæ¦€Ÿ¦é«üh}ĞË[eí\oVgBŠ“ı¦)o:	’ïk4¼lXR¾¾™Õ¸«n¤°ÒM‘8 Ígu›5ÎÁÆ.J­îìZó–bV­47¸CÃóWSv½ÖQvÅÅÀÜş.²ú^PÙ% ÛÈ¢Ğ]³[çyT.Ø§r`\Î&‰¸bt‰Ìj‹¯·‘¼Veoçì ëI€;£‡)‘€“ÈÍúW|­†KR¼aƒòFÒ¦Ì+ğ°kÓöÑ¯
œA¥€·å*¡€’ô¯dféeò»|-^ÓtZìcb€
C§W)Àª¬¢ìÔòGŒÚ%§Å_M`0eK~SF±ñè†€“ yßƒ1³ÕâÌ$.ãû‡eš-¯§@‚¥±Q_"ÆWÃàœ\§qeÓNü.¬Œ¿  […Ãƒ™ü&X¬Ö°tà°ÌØbNHãŸÍ¤ÄS›	é0˜—Ù¶_‘]Q‘et¦â<¼æÛJ¦¾©BRšÀf5‡‹*Ñ?ß1hYÙÆ]AP¡d=êİ IÂîí ò t ØOŒ!1,ª“§1éúrY‰Ô±¬ÌmvßI†ho¢:niYfÍ1;-¿lÂŞæ™e£”¢<%´!2²Ë‰Å ¯v‹e"ua^vy…›U[%®Óİ¡ÎŞ~£¾ójŒ2¢™bk×ÅB‹~›	wd|°I€w3@WÚ‹z	8ƒ‹pŠ3©s´‡v£™çb¦ıÀë Ï^âB{LŒ~hG§H$Aõ¶ƒ¢ßK©k BÊâ#\Ÿ–É±¬šx^Š¡ÊŠQ%†Ÿ{6†^!O#õ*gLSv•§²‚â¾Ë¤@ÌÆÌMìLÉ¼¤¤Ì/uš}1Î¢\¢Nñ9oÌY%óª3ÒYYÁ8¢’ÊÇºí›NhÓ;ÅBáÅu¤×x*®´PÙ…·áWÿ©•Ñ•AVP1ÍWŒE7ª“`B/DiúÄ‡é¸d-Z=Å(ƒ'Ğl’­#Û¸}"ªe`•r·-4ÜCçCæMê&M}_ª*ÊÚ2–aú@øo3Õâ€ÆZ@L‚®ù›,ô Ş‚Ë°°ìvX`È”yere‹V|Q¯œ!»\qé\R•£¤ò‹4Bn$¬Bâ1†°Ä]ÿ£—VÎf‚.2´M¡Áİä†pÎÊ•ˆ™)Òˆ†ìJD=ähÎøİ3Ó+æòV˜šr¡ğ™‚ ‰ç3Ù³káA>CÁÓ5ò9ùÆì[†Hï_è5,¿Â«Í	ˆ}ÌGÉŠorğÛ5‡°tœL	*=«ĞFàXûëĞÜy@Ñª,ÓñcW¢çqvXS¾˜B¨ŞVæ4^Å&ïyÄ¦aZñõ&¿’aŸ1Öµ
a¡5b³züá1D‘2cTÙÖœaüEs0=Îğ^lT£ËãúÆ×YÖm>e¨°9@N%®0 €¡Ú› EÏ÷ÎB^•ÉÇ»äõÓİ€ò«‘w5Œê|i£Jî_hÒÄ¬AQ de$peÎµ­^VÕî)—ÌÍœCÏkI`ÂˆŒÓ=¦MBZíYçÒÆ›iº‹RÆÚ³Ñ8äÊå—,XÛú¿>Àn²Âtkäë†jÿxOË‡öÇPZRC!mÊ0ñAÌ­TßRFåY³VõÌ¬Ôİ Œ„=VÄEk°³nO~Î@ó3Ûö$}#+
Q»L^÷ƒˆknÎ'+j–&’&ã{ÊZY¦[ÊƒËäĞc“a*G´8tiLµ Àu_ÁQ–›#½ÚÜ[eqgƒBUŒèæ$ÇgM2jó.şz‚ş¦³ŸÔ¶6µ`öv—¹é‘EoWˆ„¦åKäM²jZ^/êô¿&¯Ü2{qƒŒ+W‰.±YÓYwRŒ[1ä¯÷iZ¾</“7‘xŠ&lÏ¤B—<å½ÔUÑ´‘Ñ7g#9=İ;’«!vSQ-Éò.nYªLÊEthcäMÜÉ3TîÆxL9AS@‡ÉÄ¢ÑL‘˜Ë9±p‰{IÓŠ€…÷ÃÄàŠ©F–ä)ÅÕ‘U¾&6çì‰OKg1÷ç·2ÑØ‰İ}úCq(Å(8Pt+ÑÛT.·À”L\¢ö:ó”ÕN»Ô"â;½×’®Pl1qƒ¼î¯¨6À©ˆnOiÔ1{ÀHA’¾‚rŒ/g*Ÿq7é0Ñá”ÌA¦¡+ÏÒ4|i£â’Eú–ÀwÖ(ş 7ªÌnË¨MM²çƒ6ËcnSP†ÚÍeõïNrÒÍªs@W…ÊU2Ç{û¯(ñ£!ÚÄAcZWît!²zrqyB…
e1 ékT2yÊ¼Æ‰`ì÷ËÎñ}[´û ä£ëP¡Z®12¯ˆ3ûuk\¯'êü~gLU˜PE|O1" İuz´£¼£dØ”¥1›²£(Ge«M˜Ì™W¦3È¤…Y[-·C!‹+(<JUzŒg®6<b¥z~7¦?Ÿ…,¾.ğ™0Ã•6i*( §I ¢xç‚‘À…?ƒ*
‚é¨Ô1ÙÏÂš¶©(?e¡+e …¸~hº­d²ñÌmœ5>œß8prI?ğk™Z¾(‘¤ß³Gh}<×FCm'>zŞ¥MÏÙç†ÁräüÛÉìÒÀ$°¡:DÔvî1”bó š…X@c¥{ı„±kh|€Ã<Ucå³öH8ÔfŒË‰â.,/På*{âª3ÎırYX§”».o?#¤?o_i‰eŠ;Á5oµP2à X§6\"@¸¤&n>ĞDÒ€, ‘®o0>‹Y#ÇËÊwĞÉ™âEøºâ!áq¥('åÜÇ_)V0E\#ô7ÖA¦gE=…H÷¾©Ğî#1¡3°~v)XyNy€®Ú‘ywjúb:óHmv€ãIr†y¡Îsä¦…ÊÄ;uX³ÀÃ.ÓµÑõ§lT”0\vqéro*¹…H'E2¹ ş&°Õß©àMi[’ )ÖFÖÑÆğ7ªô³
œO‡xïç¹iÆb˜4)3=(P ™*Ô^(ÃœB„ı¶LîWèMB	0F£˜æØ]´L†Òf ı!¾3ğ¦ÙØ%|ÍôâåA¹&"Ûi
~2eDüÁ<5sa¡i,’Uœy	!^:ŞTˆø&æ{·Äàfs«(:3½’qø3x|~•L7¢`ÃÌàyF¢¼XÎ§Ãª	5}_(‰…Š’z6lñ-Œãf)ßq`U5;¿7dª’j]”âÓÊt±(Y¾‘ÕŠUî"XD‰?„z‹1¬n±J«ØÓ‹®\£‘£ˆ(	ÄğxA§ìís;!J*Ô¤7àrÁ“j¨/ş(<Ø#¼¥ÿÒŞˆc•ÂÑZ”¢«òíkøwÒ[Ã›h ­"úZ¬_„á8Ø©TÑò€‚qU(?±´ç$,ÑZAec§PxJŞv„©'{C‘ xö…?t"Ûã
+ºÕƒIoä°€Ùôí-êW Ò¸ÇÄ‹ù,PºMáµ{e‘‰K½U`¢ÚcØ¢lQx“‡jY+“?{`)×ÄëÑk&t|-¦˜W!FH¾Eô »«««²A–=PáÍ•ƒı—£n§@Ÿƒl~wÿ4Ú,sgúåEPŸÙñ4­®WEü­Q¯aü‡j­šÇxŒ§	]§6c—èyÔ ,ÂbL=ûI^1%~lıEï´ÔLNë$Àqëdx{¸:_z&¾ÌC×?ñrpa<DsÖ?,ödüŸZ«¯ÿGy¶j[FÕĞ¶¶íf«a×k­×èÕ-m«_kØÕZÏ¬7­~«N~_®døTëVK¯Õ´FÕª·»in7ë5ÍÚŞÒë=³µİƒ#H£B§T;ö50ûÕf¯ÖhÖúVuÛĞZ–ŞoÚZÓl´Zº¥7kË¨YÍjC®û%4¬f½WoêšešuÓÚêU·šVÕ¬™ÕVm[·{ÛÜnõKª-ìc›U»ÑßÚjõ HSßªj[µm»e˜µjo{»±eW-½Uo™X3Ûƒa»U5·³·Uí×{ÍªfõëÛ[†iÔ›Í–mVköv½Ù³[* V×lØ[[õz£Ş3¶lzkè-{«U«6õ~Oƒÿ,ck»i4“KÛ[ÚV³Şªöú­Şïëu}ÛjaG¶kVß®š¦¥i}€.@/Š­FÓjöõ~«¹eo÷ûM£§™[ıªm5í¾Ölµ¶ëµ¾®Ùrµ¤ÇEİîé­Vƒâªµ¶··­ZÃ°ô^¯¶İlUk­šÖ‚¬"ˆyşæöv­gÕªÛú–ÑìYæ–¥Ù€Î¶YÕkÆ–ÖÚ‚ÇhX	XÙ.·™Ñ”+„:·Z­ošZ¿gVM«ËÁÖõŞ–¡Õ[ÍVOÛjÙ\ßlÕÒ dOH±Õ¯W›ÛızúalÁIÃÜ®jÍª©õj[¶¦›­V#£s2­4ìmËÖê0i@Ú0\Ìu£×00	ºŞÜnlëZİªZP$ßÛP\öàÜ‘öRÀnK…) Izlhu£YÛ6úf£¾Õ×¶L¹¹İ·«hzß®™ıÖV-{˜Ó.0U­^µ«UİÖm³·]×MXÙj­®ÕjVCkUuÓnnÃf¦‚“\wª@yšÍlT[F¯ßº„¿ë¬Ëhömü¿ÕR¨~GÍîmÙFİh 6k[5»Y«éº¶mÂÿ5İnZÃÜ®×k,áYT­5{ÀM·µ†4[k6~½nöí^ÏÚ0UÓ°··Q'»’éÀÔì55M¯oÕ[vMoÔë†“k†¿×4`™5êÀ¸û”Í«^`š¾mö·«Àt£Ú¬Ûµf–DÏÜÖ[ 
4¶ú–Ş3j}QSE~¥ÒØã?¸ºã?Öõğñj•ÆlêyüÇÇx²öÀe·1Gş¯×š:Ÿÿ–¢$Ì½Uoäòÿc<+¿¡Âñê´œ“4;N¯Õ}k‡¬.l¦²ız“¼@D¼äØÃä›Ş˜ê+Kº\'¹şb¯»uº†=ÀXuAèA`“êö&ÙvC^Ã¾öüÉ`°IºWNø“ícèÉ¥#Òeöì¤Ìòá÷ö$¼ğ|ş{7´ûh—Dµ-dİ³ƒtuƒwe¦ùCÈÇ µ2P»c9aT{õÀÂ—LoòâšÍÀ
åŒø+rj_:¸ó¦ŠˆX1%9/µÚäò=)vØyB´(9‰PÏ4=ØalÍí Á/àipRD°Sˆâ@¤ƒºÜ)‚~’ïôc¾Ş¯úvYk•«šŞ$„ s dŸá.B.’ˆ‚‘p¾+´° ®¨çjœÑ>‡ÆßŒíÍá$>tL‡YÄŠ  Ô$XE€BãÁ'Ñ…«gÇŞ‰häºĞ4µx]añğO<Xzİî£‘&õ¦à¢Ó¸Ï¦ÁeÖæ™°ãÁ]hş¡ì¶Nã;©eT02xˆRhØ=íÁÁùË7İ³ãÃılŸí•¡-uâ#Ã$>&´`: ÷w¤·ÜÖ[±ĞÚTì“!I(Ì”5¸ï˜g”Š€©¶ÛRí…XT-q"JÄ×
"hjğ	5å:>¿´!—ÔaÙ&O‚ÊïæÃäAK¤Y‘LìnPD)œZŠÍs'Ğ4'$ÂKÛ[JğĞº’/Ò¢é°S²S¤b×›hSõëÂ 64˜~*z”¥B3aĞ6,F¹Y¡€÷<–(›Y>î5^pÂ*Œ®o	lzñ\^:7ı6s‘?Ï–êƒ3M„ÒéÚ˜wÿWmFú­Ù@ı]ÏåÿGzşîßü«'ÿòÉ“CÃ$Ç]ò‚à»'ªğçoğ¿ÿß‹lŸòXã¿ÀŸ(ò/â÷ÿ$‡2†€·ËC:Ñ^S¬œt± ñÿØÿˆÿvşıÿw÷êgşd>	•óƒ´1{ıëZ«ÚJ¬ÿZ«®çëÿ1‡:ÿ?˜àgª˜¦øy+ Ô*¯xX)õ…Z¬Qÿ“inÙ Oy„ùæ¾tDHkø)ÃÉ†Š|Œä†Ğ-J¹3üôĞJ„¯@€f5(…co)ŒWìóqûÆpé\»¡ñ‘ÍÀ÷íÓİï1zÅÒÙÉºúîÚ»ÉŞ]ì¼»ª·‰ì`ïÉš(iZ‰\œñ/Fv´¸@oWŠ¨¿*‰iÉée&¡–
˜ÉqrHÜ9.{‘YV*0œ}‚â’^/F9‘‘ü‰å@&SÃ‰× ^‹ƒhôšb”B;;¦\öåñÑ«E„ÍÄëÅº,iööO£éT7\K¤r{K :ÿ@}¦ àt) Ê‹kÑvlÿ„’Ÿ‡ÏN¢ç0ğ¼SñXF‹–;‘Üwi%-cÅ¯Ú]£K”EÃá®= ä¹¢Ó~¨vŠ2¡S£m5+8uÄÂüŞ–W`*	¬¾ê$cì1ƒbÔ¥ŠËsíB‡c“}Î-w×>‘àÂ&#R2IÒêTãÄ×Ÿè]Pº$Årü§âgÜ[ŠAe‡¼jïtöV+•èİ*¼}ù]ûèug¯R|Fh ²2)…˜Á¹OŞ­cBl‡†åÖŠäİ)Ñ¬ëÚç†?€éÖ"ìÆW/ûiD?›°¥•¬ß“R¿*£ÑŞÛcHÜ|ÖJÀ¶¸ú¦ÎëÀ·¾ş¤]bştÙ!hÂÁO¤tFşù?şŸk|‘‹®™V2O4ã¤R¡ŞÔRl¾â¢¢¤ÄIã_L@	ÀM3
%ˆTşbjy©Ğp6Pd3qiV(*Y‚ámQ.…|4]
ó¬Ë¥­¦Kaw©Tº„ô«×S‡U1+ $"/¯RI¸¯ºˆğ¼¤ìIöö*•BZ{8„Ğ/kïˆMw7v#?¤1~‘ÿ.ü©ù‰ÅHøb‘áV*Ñ½çÍ¾HÂ_¨ Åf„~ç …ú>JY]7fwG`$ÍM´ÑEC:ğ€hvxÎóç¨…~³ŸèF ^Bqáz!^Ë»kÃ 32”ŸBû¦7ôü]czQİµŒLqpĞ>ëì¾$XÄÂÏ4C[T(»T/ú=&h3‰º1ô
ÃĞ^ìU>ÁÇÁ{J}¡Ğ¯Ê%Um-Ù8³¾N¢†°	áƒÅÚì…Ta~iquûvÕ©šTÈáv $*Œ¡·ƒ»¬I >ì®)şb_hµÑÆ'£/‹ü8ŒÿZ 5I?I¬—±¶g07D¶{F~½›÷3œ‰{ãí®]:©$Ö¡Ñ°°şGÖÿË†ËÔ1-¨ÿ¯éµZµŞ¬Mo4j­\ÿ÷(ÏW®ÿw¹şÿÿıo/WîÕÏüÉ|²Í¼—ÛÆœõ_mµRë¿–ûÿ=Î“ëÿ¿¬ş_q®øE^È^÷3n’Wr¨œü:àî(üÜ¯R/9õ)!+,ŠÒ½°ô¸ß)ñÃZR0´°ü?öÌz¸=fü_¯Ö¨ıMkê¸wjzµUÏåÿGyV(ƒ•’0+X¢³l‹qè<Ü»ğ‡*ÿFØ?Š/kÒËnô¶Îß¶©^O¼mğ·§’.PüÖÄ£‘Åmšp“ïã_{İN‡°ğvİÃÂÊm×)ÄI_wôÚÖöŞ¬5wêğìlmÃW€ûë²Ìv¬\nóäÿFCòÿÒt´ÿk´òõÿ(OîÿóEü’Ì?WÉŠP¶ { ÍD`¹’úãÈé…%‹Ş_àÍ:Ö9~µ _šÏO{0}êC·¡-æÿb½¥é:õÿn´rÿïÇxâØ×Æ‚ó_oµôjƒúÿ×€òùŒ'¥çAÚ¸ıú¯µòùœGŠó0m,ºşkZ£¥i4şc£ÑÈçÿ1T£hãöëCäóÿÏ”(TKmcşG×ô»ÿ­7š*Î£^¯çúŸÇxVÔÀxêyÍƒ7D©]‹ô£há"ÑôßÁøf”ˆıïËñKÿùMÀâMj/_Ç!PyLŒ
m|c
'í³ïvWñïUšê¤™zóô¶GxŠ@¹Â½³hÿœ“ÍgÂ/S>£ò¯K÷?Šü/E\n·ßÿahæûÿc<©ØĞÆ¢ò¿®ÕZZïëÕz.ÿ?Ê3/öç2Ú˜#ÿÕjuzÿ¯Ó?êZZ5÷ÿ”gY:óäÅÜ¾Û÷ ô'4Û4w°H—EÚ¾ä\ò:.ív©wqJíä=ly­²^-kõÄõ[òšåÕ¥¥˜o%E–ìÑÌ‰»¶Ì‹2Z„›ëíí½¬‘ß‘×'˜˜d™c{èY4™Ç%°m2p0=ë¹`7lôŞ]ˆãÂÇ¿ïsyä¨ 2£8RÊÙñŞq9îİ’0e	ƒˆH‚w¦ib%à<§¾ ôÙ…Ze^¶<°Ãõ5×ó¨}ØYÛ$EüœÕ+n ã(aúT x8@ ˜K[$ş¬|É7DÂb£@]ä¨7\OBeN˜èÜƒ@[pÖ.nˆÊA0õgUîv¤úÕ¸şÏvÓºÃê¾évN±â•İéÒ1‹â°â£ºEe»Ûıáøt0ê^ƒB»Ì²9â³CŞ~¼_KÆ³Dñ(/}ª8N@\<6K"‰âñè&KcRAV#Yšg\áM<>™àqüâÒQÈ)¥qÄ tì]ıÃAW¬ö†²öfõóËi»våqØ,Ô#æ)V-YµRd‚TÆeVE©#iqÅã3¯V<j»©qê|®£tö¥·Ø¯ú™A~‰mÌ‘ÿ`LÿZ¹ü÷8OîôñØN?[[¯Á Ôà°qfc4“l—’6`ÜÆê±=.ô²®=ªÇE"¬oxUN`„qXgäy’æäé˜°à'º_b–4Öı2rºì} ßØî6è—Àù	>jÚ‡ÂM®øı•>Yil–İÆ<ıO=µÿc­|ÿŒ'ßÿóıQ/O`?z=æß™ï÷
Ë†weÛ†×¤?ÁlÒ,¬¼×Ç„ö˜=<²‘!ô—Ú8pâmòşÓaø˜¸‘ÌS ^ÇI)$¯ŞÒéüPÚêeó‚<N*áh,GWÜêóßê…>Ëp`ô×ôişjãË¢¶Yİ¬mÖ7›Í;çşÑËÓÎaçè¬ıµŒ*7½x¼‘¬VéH>]tü¢ô¢·°/½©gNfÍ¥´1OşkFöß(şaü–Ş¬åòßc<K[°è¾{ËÀ/(aë(Ç”$é”tfY('Ikå,™mS×ˆ’„Ä&Kd„Ö*ÃXŒCz	ˆe$‘L”ÑéÍœ,…‰_Ş€L#)^ğ2Ğ—äM #­¶\#3Û¥i‘hO•¤7QO‰ÊAøàƒ®£`ğ&,Â2ÄÇlñFP…ûywi,=V¬Ó›Œ2i[?Âê$ô"€|vp´íS ÄYŒèíšœgŠ8a™&¥‰‘`ÍYØå÷`byÄ§é 6À¯^…w“ÿ[I4Ğa£Ká³šdO†Jv‰¡
h9ì½efÔ.ŞŠÅ«Ïk¦‹ö˜2T22Ü‰1œ	œq. Úß²—1,ÍĞò¸Àiâ^ˆR¬OmÏ-~Œ€‡û®ßÚÌ%•ÀYNj±¶E>í€\`Î#)ˆq‰xŞ"x_Ø³cE¼¤Œ@„l(ü`¸a°ëÚá•ç(Ã<ì°Ğî‡¶Ÿ|I
o9_~_8»Û»Ü.àÛ.Y_ãê£Ÿ~€j°¸¢Õ»›Çp¹¢9ñğ{İa#füB¼Ğùh›”Ön_·BÉí»w€W€h±Ê€yã;ÀêQxŞXwæŒl
»¶¹[Ó´ éZ†oOÂñ$Üâzƒß™x0<â×F$MşcÊÙÍ{:x>ßM†¡SBÔøĞéıv6ôå´1GşËÈÿÚlÕsùïQ<şCÿ5ÏÿúDÈó¿æù_óü¯yş×<ÿër¸iÿu¡G•ÿ9C-ûÁx‰mÌ‘ÿÑİŸßÿ7ªUÿ±Ñª5sùÿ1·£×ûG÷…S;§·Ùõî÷<5ƒ^ÖØ…·¯;GÓı—ïİÎË7§ûg>s¼·Ó=ÿ~¿}~øgÆÜºoNĞ\|·oƒåz‘çÏC<Yçÿe‡€œ³ş[–ÿµ®W«M­U¥ë?Ïÿú8Oÿ=Ïÿšç]âçßïŠxÿ5ÏÿšçÍó¿Ş3ÿë­r—ÎNH:;íæã¥}Èd¦·Í§:3Ùè­’Á.îuv–Î¬Lœ³Rwfeé\(	çÜTó²t.=çÌ¼ŸyBÎ2$ÎHhšJT™§öœ“Ú3O2œH2ü¥õ?	ıoàÑ£î-±yú_xëk4ÿ_³•Û<Êã¸—p>„µvs²¡¢ôÀPr;0C0~Qğ¥±ÏŸû>Ùö_ËÍ:/şC:ÿg«VÓòõÿO®ÿÍóæù?suğmú”çÿüåäÿLíÿ	tü¯æÿlbü‡V#—ÿåÉóşºó¦Öÿd'ÿ§ó6­F¾şãÉı?òüŸyşÏÒW «çù?K_“àı+Éÿ™ÚÿÏÅıòB€ÌÙÿkÍZ-ÿQEÿÏV³VÍ÷ÿÇxòørü,ú/ä!@âç¡B€Dƒôc3‚Goaş#‹6H6á%k)A@héq@‚~ÇP Sa/‘'üb¢Èº›‡	"I©»Ç'£½îyäÏ¸[¤«]+?ZôòVY;×ëõJQş¡ÇÎ Tö0­ÀJ]ê£d¡Dù×‰ÈÉ¡>æÔôÆÉŠ§6æß»EUßf$-€,/2È×$‘ÿÇcìœ#i—ñÅRÚ˜§ÿÑ˜ü'Åÿmi\ş{”'¿¤M¢TÕ(ëág«¨ÙãJ)êZ$šSáÍ%À	ÂkEéŸÔâüZ"ú,BËÜ…áH‡›ğÅóËÜ!ÑË‚×ÃØRæ¾ ¥øÃÑ!”_`GaMw—nŸÁflJ°ŸÓÕ-™Ã—‚¨oûäÛƒz*döó­ iÖ”?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?3ÿõN„á 0 