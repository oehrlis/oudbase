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
‹ mX¡Z í½]sÛH¶ è™İ»—O³û0111›M©Z’[$~JrÉİ´E»Ô­¯åªÛ×vë‚ H¡Ll ”¬²Õ11»û´oóöaÊü‚ó¾/ûöœü 2ğC%»ª€*Û$˜yòdæÉ“'OãV<ğ£iZ«Ñ ôß&ûW«ÖÙ¿ü!z­Z¯iÍFC¯M×ÍêÒxhÄğ™¡á*gÏ,Åúı¿ó~DÿşLÌ¿7±Î¡{á$(ĞÆìù¯64˜s:ÿ@ U]‡ùRh<!Úà’z~åó¿ò›
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
co9×Äxº7T­Iâ‹”¼ˆu7•u—enL1á©‰%)°Ø`D+´) °¬ü?–gV–kÚ3/ÿæKbùŸu
j:üİ|B>¿òüO8ÿptÙ;ì”GÖµI¾êõió_kµ¢übşkZ#Ïÿ÷(ÏJd~VˆòjQ­½{Æİ‚§[ê¸—ÿüŸş+•8€åY†o9?	og4¦™[¨aWtO#”Ç,”%náç,Ì•@$R!e»€0·i‚9¸ÓÛA™´‡˜÷ip¡Ä¶rĞ†Š 1Dƒ´ë(ıv9ŞWı‚Mn5ˆ~1¼mèŒ ÿÀ	'øıŠş~íMàœƒğH0Â{pÚã!”¶h:Ve—`‰kx&¥(Y:5¤ı‚Ş¨ØbÆ{¡—øCû#ßó1¦´8ôhPL×-¦oÃNâÛÊ0î‰aTÆ™šU´»‡›$öMZèõ&ŒÂy¾2¯.“Ä8èÇéÚ¾1¤"jFA¦²€Áf×–:Q.
¢yŠÕOœÙûã4=}å8{ú”Ë&#Ì”î­È2OQ* ½‰kRÃ(.µÂ`]È¡»ƒĞŸ˜8tD(8|_z3}j?™Ñ
fsFÎĞğ‘Œ¯Ğ^a4D€á,D±-_µËdŸ¾ò0´]¬€)ó˜õ)Ó"cA6+;ùH¾?üçÿøVˆãÍª…H…†MëÁ¸gûĞ±‹²y£oÃ%´ƒàºÒ}‹.hûÁ•²iDfâÒéq¯Y|v†D0K++xQ2'¦+ŠPAca¿Ò¼nÜy=:ò”ëÂÏ…_;Lk™ü€F"ëWÚPÙ~ÂğÁZÃ`ÑvØ|¢ÿôOÿD2½ó ÜÎß*ä-ÊO¦ØïIe¢é•àÖªUI7FJLTVÒõ’^;×ë;Õ­ÆTsz†YõğŒåõIFÕõï9#ÑÊúCs4¦™‡:A‡†6ŒÙÙRtÌY•ßÆÀŞÌBäméâò=üİ#ßJÆØÏß“™ğÔp¢ŠZú9BE¿ÑÑû„J¤ˆëÏßÏlh%ÕF\yhŸÉzˆ™şF˜`b`oÌw9œíRÚFÔó`é<Ë-1¦24Ùƒ#2‰*“CÜâ(Ó1üÁ„®'–ªpFSóI½À¸¬76	Ğv¬†ÓOÌ\¢#„ÄÀ¤¬7Ü(KÅFy^kƒ
g5A	f7æ¯¸ÓTØnÏ¾ÏÆi§d2DÁ‚©O0\ıîî˜¼­ynÃ˜ó¢Í"¾S‹‡ã…šUB¸µ±;uĞq¼*ô‡â¼3Öåœ™ëGÕ&ûi~£Q4r³Sİ/2š~œ»Ê³¸ÓœŞòÍ>›è*#Ç²†6ÎúÜ¶b¤ïÎA¼İ'wH%S{ÜĞà&Y(ìË[³ıÑ ¢MJßƒÜuÌqƒØE‰¿'	‘ùgê•zOŸrÆD[i×\š“ŠÅcÃdd¨me×~Š;÷S².Ä1IšãséµnàŠ7K€Óc¦´4±#=o È]Ûá
ßÌ”ï@P*“,iÂv;€ˆVé£Â^sñ‚a"&?fJ—¸‹$` 3N½²(,œì­’V-éÍs]ÛiÔw´Æíä½¬•5!‘,¥õ[È/S+ï©	ÒXl‡™5ŞĞ–Š`F‡Ş~‹T4"¤DÒ3!e9[’İäÌ!vHù¹ˆ,QBÇ‹ë™u³œdÓÍ3<T‡Î6‘yu£m<]wn½”.o3i:B¼ŸªXÓ=rù‹8¶R›ñàE(ˆç©›:ş<‹é" T×â© *J"ÓE +ÂKœå
M>MÓWùÑú —·ÊÚ¹Ş¬Î„'ûMSŞt:$ß×ht9Ø°¤|}3«q?×Ha!¥›"qh/šÏê6kœƒı{ZİÙµæ-Å¬Zinp‡†ç¯¦ìz¬£ìŠ‹1€¹ı]dõ½ 8²4¶‘EQ³f·Î+ò, \°OåÀ¸œMqÅè–Õ_o"y'É %ŞÎØA¿“ ÷äS"'›+ô¯øN
—¤xÃnÕä7Œ
¤7L™WàÏ
¦í£S*8ƒJo
ÊUBoóè_ÉÍÒËäwù.W¼¦é´ØÇÄ †N¯R€UY)DÙ©åKşN1Š¿šÀ`Ê–ü¦Œbã9Ğ¾&ò¾cf«Å™=YÆöË4[_OJc£¾DŒ¯†Á9·NÃÊ:¦ø]0X?'~@¶
‡3ùL°X­`éÀa™±ÅœÆ›I‰§6Òaş0/³m-¾"»¢"ËèLÅyÅÌ·•L}S…¤4ÍjU¢5~¾cÑ:²²»‚ BÉzÕ»A“„İÛäŞ@°ŸCbXT'Oã»)ôå²©cY™Ûì¾“ÑŞDuÜÒ²Ì.šcvZ~Ù„±Ê-2ËF)EyJhCd4d—Ç ^íËDêÂ¼ìò
7-ª†"JP¤»C½ıF}çáÇeD3ÅÖZ~‹…ı6îÈø`“ ïf€®0.5±wágRçh.3ÏÅLû×A;¼Ä„ö˜ıĞN‘H‚êmE'¾—R×@…”ÅG&¸>-“?bY5ñ¼¾”£J?÷lŒ[BFêUÎ˜¦ì*OeÅ}—I,˜™Û§/˜’yII™^<ë4ûbœE¹D=Ê#rŞ˜³JæUg¤³²‚!<%•uÛ7/œĞ¦wŠ…Â‹ëH¯ñT\i¡²oÃ¯<ÿS+£€¬ bš+®‹nT'Á„^ˆÒìˆÓqÉZ´2zŠQO< Í![G¶pã>TËÀ*ån[h¸‡Î‡Ì›ÔMšú8¾TU”µeŒÊÂôğ3Ş fªÅµ€˜şıÚ7™ß>Ş‚Ë°°ìvX`È”yere‹V9¯œ!»\qé\R•£¤ò‹4Bn$¬Bâ1†°Ä]<£—VÎf‚.2´M¡ÁİäVdÎÊ•ˆ™)Òˆ†ìJD=ähÎøİ3Ó+æòV˜šr¡ğ™‚ ‰ç3Ù³ká‚>CÁ»/ò9ùÆì[†Hï_è5,¿ÂáÍ	ˆ}ÌÁÇŠorğÛ5‡°tÙL	*=«ĞFàXûëĞÔy@Ñª,ÓñcW¢çqvXS¾˜B¨ŞVæ4üÄ&ïyÄ¦1Nñõ&¿’aŸ1Pµ
aq)b³züá1D‘2cTÙÖœaüEs0=Îğ^lT£ËƒâÆ×YÖm>e¨°9@N%®Ğ{ŞPíMĞ¢ç{gñ¢ÊäÀã]òúén@ùÕH	‰»T¾´Q%÷/´‡GbÖ ŒŒ(è°2¸2ç&/«j÷ŠKææNÎ!†µ¤0aDÆéÓ&!­ö¬siãÍ4İE)cíÙhrår·Eélı‚_`7Yaº5òuCµÿˆ¼§åCûc(-©¡ƒ6e˜ø fVªo)‹ì¬Y+ÇzfVêîĞFÂ+â"È5ØY7'?g ù™m
{’¾‡…ƒ¨]&¯ÆûAÄ57ç“5KI“ñ=e­,Ó-åÁerè±ŒÉ0•#Zº4¦ZPà:Ç¯à(ËÍ‘^íî­²¸³A¡*FOts’ƒ›&5=AgÍÙOj[›Z0{»ËÜôÈŒ¢·+Ä
BÓò%ò&Y5-¯õ@ú‚_“Wn™½Î¸AÆÇ«D—Ø¬é¬;)Æ­ò×û4-_—É›H<E¶gR¡Kˆr„^êªhÚÈè›³‘œ‰Šn‚
I‚ŠUŠ»©¨–dy·,U&å":´1ò&nÈä*wc0#Çœ ) ÃdbÑh¦HÌåœX8Ä½¤é	E@ÈÂûabpÅTG#KOò”â†êÈ*_›söÄ§¥³˜ûó[™hìÄî>ı¡8”b(º•èmªN—[`J¦N.Q{yÊj'È]jñŞkIW(6†¸AŒüöWTàTD·§4d—=`¤ I_A9Æ—³‹Ï8Š›t˜èpJæ ÓĞ•gi¾´QqÉ"}Ë à;kUf7ŠeÔ¦¦?ÙóA›‚å1·)(Cíæ²úw§F9éfÕ9 «Bå*™‡ãƒ½ıW”øÑmâ 1­«ŠwGOºY=¹¸¼¡B…2„‹€ô…5*™<e^ãD0öûÆeç‹ø¾-Ú}PòÑu¨P-×
™WÄ™ıÎº5®×uş¿3¦*L¨"¾§Ğî:=ÚQGŞQ2lÊÒ˜MÙQ”£¿²Õ&ÌæÌ+ÓdÒÂ¬­–ÛŠ¡Å•â)=Æ3W±R=¿ÓŸÏB_x„L˜á‡š4ĞÓ$Q¼sÁHàB‚ŸAOÁtÔğ ê˜ìgá MÛT”Ÿ²Ğ•’?‰B\?4İV2Ùxæ6ÎÎo8¹$Šx‹µL-ßÇ”HÒïÙ#´>k£¡¶‹ŒO=ïÒ¦gƒìsÃ`9rşídvi`ØĞğ"ä9÷J±ù MB¬ Æ½~ÂØ54>Àaª±òYû$¼Q3ÆåDñµ•¨r•İXÕçN­,&RÊ×•·ŸŸ·¯´ÄR6Åàš7ŠZ(-?P¬S›.K?\R7h"â~ĞH×7ŸÅ¬‘ãeå;èäLñ"|]ñxê¸R”“rîã¯+˜"®úë Ó³¢Bd{ßTè÷‘˜ĞX?»¬<§<:>WíÈ¼;5}±Fy¤…6» Àñ¤
9Ã¼Pç9rÓBåâ:¬ÙFàÀa—éÚèúS6*J.»¸t¹7•ÜB¤“"™ÜØêïTÏğ¦4‰-ÉGĞk
#kˆhcøUúYÎ§C¼÷óÜ4c1Lš“™(ĞL•j/”ÅØŠaN!Â~[&÷+ô&¡C¹NLSì.Z&C	é3şßxÓlì¾æzñò ÜO‘í4?™2"~‚`×‚¹°ĞÉ*N[„/o*DüóNó½[bp³¹UÚ˜^I‰ ö<>¿JæêP°áfğ$QR)g„ÓaH
Õ„š¾/”ÄBÅŠI=¶†øÆq³”ï8°ªšß2UIµ.JñieºX”¬ ßHÇÎjÅ*wG,¢¬B=ÏÅÖ
·ØG¥UìÆéEW®ÑÈQD”ì[x¼ SOöƒ ö¹%jÒ›p¹àI5ÔH)ŞÒi<lD‚±Jáh-JÑUùö5ü;é­áM4HĞV}-Ö/ÂpìT*ˆhy@Á8*”‚XZ‰s–h­ ²±S(<%o;ÂÔ“½¡H <ûÂ:‘íq…İÀêÁ¤7rX´iúöõ+PiƒÜcâÅ|(İ¦ğÚ‡½²ÈÄ¥Ş*0Qí1lQ¶(¼I„CGµ¬•ÉŸ½	°”kâõèµ¿:¾SÌ«#$ß"z€İÕÕUÙ  Ë?¨ğæ‚ÊÁşËÎQ·S ÏA6¿»ÿ?m–¹3ıò¢
¨ÏìøšV×«<şƒŞª¶hü‡j½–ÇxŒ§	]§6c—èyÔ$,ÂbL=ûI^1%~lıEï´Ô4Hë$Àqëdx{¸:_z&¾ÌC×?ñrpa<DsÖ­ZKÆÿ©µz¾şãÙªmUCÛÚ¶›ı­†]¯5´^£W·´­~­aWk=³Ş´ú­:ù}¹’á?P­[-½†áz¬zË°›æv³^Ó¬í-½Ş3[Û=8‚4 tJµc_³_möjf­oU·­eéı¦­5ÍF«¥[zÓ°¶ŒšÕ¬6äÚ±_B³Uí™5Kêéoànõ«æ¶Q·& £õ[Ğƒ¦T[ØÇ6«v£¿µÕêÙ€¯¾UÕ¶jÛvË0kÕŞövcË®Zz«Ş2±f¶ÃvÛ1{[Õ~½×¬jV¿¾½e˜F½ÙlÙfµfo×›=»¥`uÍ†½µU¯7ê=cËÖ¡·†Ş²·ZµjSï÷4øÏ2¶¶›F3Ù¸ä±½¥m5ëĞı~«§÷ûz]ß¶ZØ‘íšÕ·«¦iiZ K Ğ‹b«Ñ´š}½ßjnÙÛı~ÓèiæV¿j[M»¯5[­íz­¯k¶\-éqQ·{zc«Õ ¸j­íím«Ö0,½×«mÃ|ÔZ5­YEóü	ÌííZÏªU·õ-£Ù³Ì-K³m³ª×Œ-­µÑ°°²]"n3£)WunµZß4µ~Ï¬šVHÊÖõŞ–¡Õ[ÍVOÛjÙ†³m¶jiP²'†İ´ª­~½ÚÜî×kĞcNævUkVM­WÛ²5İlµ“i¥ao[¶V‡IÛjZ0\Ìu£×00	ºŞÜnlëZİªZP$ßÛP\öàÜ‘öRÀnK…) Izlhu£YÛ6úf£¾Õ×¶L[³LÓÜîÛÀU4½o×Ì~k«–=Ìi˜ªV¯ÚÕªnë¶ÙÛ®ë&¬ìFµV×j5«¡µªºi7·a3SÁI®;U ¼FMf6ª-£×ï]ÂßuVe4û6şßj© T¿£†f÷¶l£n4€
›µ­šİ¬Õt]Û6áÿšn7­an×ë‰5–ğ,ªÖš=à¦ÛZÃš­5›F¿^7ûv¯gm˜ªiØÛÛÀ¨“]Ét`jöšš¦×·ê-»¦7êuC‡I„5Ãßk°Ìu`Ü}ÊæU/°©×ÍFÏj5›ÕíêV¯fê:¥oÕû°âíşVux¥.jŠ£È¯T{ü×ÂC·±`üGı€W«4şcSÏã?>Æ“µ.»9ò½ëŸÍKAæ¿Şª7rùÿ1•ßPáøuGZÎIš§WÈê¾µCV—6
SÙ~½I^ "^rìaæJoLõ•¿%]®“\±×İ€:]Ã`¬º ô °Iu{“l»!¯aß{şd0Ø$İ+'üÉö1ôäÒ‘Æé2{vRfùğ{{^x>ÿ½Ú}´K¢Ú²îÙÁººÁ»2ÓÀü!äc€Z¨İ±œ0ª½z`áK¦7yqÍf`ƒrFü9µ/ÜySEÄ¬˜’Ù–Zmrù;ì<!Z”œD¨gšì0¶æÎv€àğ48)"Ø‡)Dq ÒA]îA?Éwú1_ïÀW}»¬µÊUMoB€9²Ïp¡G—@IDÁH¸ßÚXWÔs5ÎhŸCãoÆöæp:¦Ã,bE Pj¬"@¡ñà“èÂÕ³cïD4r]hW¼®°xø'i<-n÷ÑH“zSpÑi\„gS„à2kóLØq	‚à.4	ÿPvÛN§ñˆÔ2*<D)4ìöààüå›îÙñáş?¶ÏöÊP„–:ñ‚À‘a’‹Z0ˆû;Ò[Hnë­Xhm*öÀÉ$fÊ\‚‰wÌ³ JEÀTÛm©öB,ª–8%âk45ø„šrŸ‰_ÚKê°l“'AåÆwóaò %Ò¬H&v· ¨¢ON-Åæ¹hšPá¥í-%xh]IiÑtØ)Ù)R±ëM´©úua‰>=J†‡R¡™0h›	£Ü¬PÀ{Ë2Í,÷/¸aÆW‚·6½x./›~›¹ÈŸçKõÁ™¦NBéô mÌ»ÿ«6…ş_×šÊÿz.ÿ?Òówÿæ_=ù—O&9î’Ü ß=ù{øS…?ƒ?øıÿ^dûìì”ÄÿşüëD‘¿ÿ· 9”1¼]‚Ô‰öâ˜bå¤‹ÿÇşGü·óïÿû¿»W?ó'óI¨œ¤Ùë_×ZÕVbı×ZõüşïQ‡:ÿ?˜àgª˜¦øy+ Ô*¯xX)õ…Z¬Qÿ“inÙ Oy„ùæ¾tDHkø)ÃÉ†Š|Œä†Ğ-J¹3üôĞJ„¯@€f5(…c‚l)ŒWìóqûÆpé\»¡ñ‘ÍÀ÷íÓİï1zÅÒ©½ºúîÚ»ÉŞ]ì¼»ª·‰ÔZïÉš(iZ‰D–ñ/Fv’±¸@oWŠ¨¿*YiÉéefp–
˜ÉqfE9.{‘YV*0œ}‚â’^/F9‘‘ü‰å@&óª‰× ^‹ƒhôšb”:;{¤\öåñÑ«E„ÍÄëÅº,iööO£éT7\K¤cK :ÿ@}¦ àt) Ê‹kÑvlÿ„’Ÿ‡ÏN¢ç0ğ¼SñXF‹–;‘Üwi%-cÅ¯Ú]£K”EÃá®= ä‰–Ó~¨vŠÒˆS£m5¥6uÄÂäØ–W`*	¬¾ê$cì1ƒbÔ¥ŠËsíB‡c“}Î-w×>‘àÂ&#R2IÒêTã¬ÑŸè]Pº$Årü§âgÜ[ŠAe‡¼jïtöV+•èİ*¼}ù]ûèug¯R|Fh ²2)…˜ş¸OŞ­c6i‡†åÖŠäİ)Ñ”åÚç†?€éÖ"ìÆW/ûiD?›°¥•¬ß“R¿*£ÑŞÛcHÜ|ÖJÀ¶¸ú¦ÎëÀ·¾ş¤]bştÙ!hÂÁO¤tFşù?şŸk|‘‹®™V2É2ã¤R¡ŞÔRl¾â¢¢¤ÄIã_L@	ÀM3
%ˆTşbjy©Ğp6Pd3qiV(*)vámQ.…|4]
“”Ë¥­¦Kat©Tº„ô«×S‡U1+ $"/¯RI¸¯ºˆğ¼¤ìIöö*•BZ{8„Ğ/kïˆMw7v#?¤1~‘ÿ.ü©ù‰ÅHøb‘áV*Ñ½çÍ¾HÂ_¨ Åf„~ç …ú>JY]7fwG`$ÍM´ÑEC:ğ€hvxÎóç¨…~³ŸèF ^Bqáz!^Ë»kÃ 32”ŸBû¦7ôü]czQİµŒLqpĞ>ëì¾$XÄÂÏ4C[T(»T/ú=&h3‰º1ô
ÃĞ^ìU>ÁÇÁ{J}¡Ğ¯Ê%Um-Ù8³¾N¢†°	áƒÅÚì…Ta~iquûvÕ©šTÈáv $*Œ¡·ƒ»¬I >ì®)şb_hµÑÆ'£/‹ü8ŒÿZ 5I?I¬—±¶g07D¶{F~½›÷3œ‰{ãí®]:©Ğ¡Ñ°°şGÖÿË†ËÔ1-¨ÿ¯éµZµŞ¬Mo4j­\ÿ÷(ÏW®ÿw¹şÿÿıo/WîÕÏüÉ|²Í¼—ÛÆœõ_mµRë>åëÿ1\ÿÿeõÿŠsÅ/ò@öºŸq¼
Cåä×wGáç~°zùË©O	YaQŞhè…¥ÄıNÙˆÖ’‚Á …¥àÿ±gÖÃí1óäÿzµFíÿkZSÇ½SÓ«­z.ÿ?Ê³B¬”Ü€YÁe[ŒCçáŞ…?Tù4Âş	¬P|Y“^v£·uş¶Mõzâmƒ¿=•tâ·&¦ôô(nÓŒ€›äxÿÚëv:„…·ëVn»–H!Núº£×¶¶wôf­¹S‡ggk¾Ü_—…`¶cårÛ˜'ÿ7’ÿ—¦£ı_£•¯ÿGyrÿŸ/âÿ“tdş¹JşS<€²õÜh&Ë•ÔGN/,YôşzoÖ±Îñ«å ıÒ|~ÚƒéSºm1ÿoûë-M×©ÿw£•û?ÆÇ~x¸6œÿz«¥WÔÿ¿´Ïÿc<‰(=ÒÆí×­•Ïÿã<jTœ‡icÑõ_Ó-M«áü7|şãI…1z€6n¿ş1H>ÿñL‰BµÔ6æètMo±ûßz£Ù¨âü7êõz®ÿyŒgE¼€§×<xC”ŠĞµH?Š.MÿŒoF‰Øÿ¾¿äùŸßÌ Ş¤ñòuÅ‘ÇÄ¨ĞöÀ7FA¡pÒ>ûnwÿŞY¥©NÊ‘©7Ao{„§”+Ü;‹öÏ9Ù|†!üâ9å3*ÿºtßù£ÈÿRÁå¶qûıvf¾ÿ?Æ“Šıø m,*ÿëZ­¥µğş·^­çòÿ£<ób.£9ò_­V§÷ÿ:ı£¡ş§¥UsÿÿGy–¥3O^Ìí»}ßBB³Ms—‹tY¤İàKŞÉ%¯ã’Ñn—z§ÔNŞÃÁ–×*ëÕ²VO\¿%¯ÙX^]šQŠùVRdÉÍ™¸kË¼(ã©E¸¹ŞŞŞÑËùy}r€‰I–9¶‡E“ép\Û&ÓÃ°î‘vÃFïmĞÕ‰8.|ñû>—G
*“1š#¥œï—ãŞ-	S–0ˆx$xgš&XÎsêBŸ]¨UæeË;\_ãy=Ú‡µMR¤ÑÉÏY½â† 0¦O€‡€¹´EâÏÊ7A‘|C$,6
ÔEú ÑqÃõ$Tæ„‰Î=´gíâ†¨CQVån÷@ª_ëOğl7­;¬î›nç+^Ù=.³!+>ª[äX¶»İO÷à S î50(´Ë,›#>;äí7ÁûµÄ`<KòÒ§ŠãÄÅc³$’(n²4&d5’¥ùpÆŞÄã“	Ç/.å‰œRGJÇŞÕ?tÅúgo(K`oÖY1ï°œ¶kW‡ÍI=bâ1aÕâñ˜U)E&He\fUÄ‘:’W<>ójÅ£¶›§ÎGà:0Jg_z‹ıªŸ©ä—ØÆùvÁÔù¯•ËóäNíôñ³µõ:Bg6Fc0Év)iÆm¬ÛãB/ëÚ£z\$ÂúÆWåF‡uvA'i~A	~¢û%fIóamĞ/#'À ËŞúMànƒ~	œŸà£¦}(ÜäŠß_é“•ÆfÙmÌÓÿÔSû?æÑÊ÷ÿÇxòı?ßÿõòñ£×cşù~/¡°lxW¶ıaxMúÌ&ÍÂÊ{}LhÙÃ#yB©'Ş&Oá?†‰É<êÅqœ‘‘”BòêÍÁ)Îÿ ¥­Q6/Èóç¤ÆrqtÅ­>ÿ­^x€á³FÏqMŸæ¯6¾Ü j›ÕÍÚf}³±Ù¼Ópî½<ívÎÚ_Ë¨rÓ‹ÇÉj•äÓEÇ/J/z»ûÒûğ—zædÖ\Jóä¿fdÿâÆÿhéÍ<ÿ÷£<K[°è¾{ËÀ/(aë(Ç”$é”tfY('Ikå,™mS×ˆ’„Ä&Kd„Ö*ÃXŒCz	ˆe$‘L”ÑéÍœ,…‰_Ş€L#)^ğ2Ğ—äM #­¶\#3Û¥i‘hO•¤7QO‰ÊAøàƒ®£`ğ&,Â2ÄÇlñFP…ûywi,=V¬Ó›Œ2i[?Âê$ô"€|vp´íS ÄYŒèíšœgŠ8a™&¥‰‘`ÍYØå÷`byÄ§é 6À¯^…w“ÿ[I4Ğa£Ká³šdO†Jv‰¡
h9ì½efÔ.ŞŠÅ«Ïk¦‹ö˜2T22Ü‰1œ	œq. Úß²—1,ÍĞò¸Àiâ^ˆR¬OmÏ-~Œ€‡û®ßÚÌ%•ÀYNj±¶E>í€\`Î#)ˆq‰xŞ"x_Ø³cE¼¤Œ@„l(ü`¸a°ëÚá•ç(Ã<ì°Ğî‡¶Ÿ|I
o9_~_8»Û»Ü.àÛ.Y_ãê£Ÿ~€j°¸¢Õ»›Çp¹¢9ñğ{İa#füB¼Ğùh›”Ön_·BÉí»w€W€h±Ê€yã;ÀêQxŞXwæŒl
»¶¹[Ó´ éZ†oOÂñ$Üâzƒß™x0<â×F$MşcÊÙÍ{:x>ßM†¡SBÔøĞéıv6ôå´1GşËÈÿÚlÕsùïQ<şCÿ5ÏÿúDÈó¿æù_óü¯yş×<ÿër¸iÿu¡G•ÿ9C-ûÁx‰mÌ‘ÿÑİŸßÿ7ªUÿ±Ñª5sùÿ1·£×ûG÷…S;§·Ùõî÷<5ƒ^ÖØ…·¯;GÓı—ïİÎË7§ûg>s¼·Ó=ÿ~¿}~øgÆÜºoNĞ\|·oƒåz‘çÏC<Yçÿe‡€œ³ş[–ÿµ®W«M­U¥ë?Ïÿú8Oÿ=Ïÿšç]âçßïŠxÿ5ÏÿšçÍó¿Ş3ÿë­r—ÎNH:;íæã¥}Èd¦·Í§:3Ùè­’Á.îuv–Î¬Lœ³Rwfeé\(	çÜTó²t.=çÌ¼ŸyBÎ2$ÎHhšJT™§öœ“Ú3O2œH2ü¥õ?	ıoàÑ£î-±yú_xëk4ÿ_³•Û<Êã¸—p>„µvs²¡¢ôÀPr;0C0~Qğ¥±ÏŸû>Ùö_ËÍ:/şC:ÿg«VÓòõÿO®ÿÍóæù?suğmú”çÿüåäÿLíÿ	tü¯æÿlbü‡V#—ÿåÉóşºó¦Öÿd'ÿ§ó6­F¾şãÉı?òüŸyşÏÒW «çù?K_“àı+Éÿ™ÚÿÏÅıòB€ÌÙÿkÍZ-ÿQEÿÏV³VÍ÷ÿÇxòørü,ú/ä!@âç¡B€Dƒôc3‚Goaş#‹6H6á%k)A@héq@‚~ÇP Sa/‘'üb¢Èº›‡	"I©»Ç'£½îyäÏ¸[¤«]+?ZôòVY;×ëõJQş¡ÇÎ Tö0­ÀJ]ê£d¡Dù×‰ÈÉ¡>æÔôÆÉŠ§6æß»EUßf$-€,/2È×$‘ÿÇcìœ#i—ñÅRÚ˜§ÿÑ˜ü'Åÿmi\ş{”'¿¤M¢TÕ(ëág«¨ÙãJ)êZ$šSáÍ%À	ÂkEéŸÔâüZ"ú,BËÜ…áH‡›ğÅóËÜ!ÑË‚×ÃØRæ¾ ¥øÃÑ!”_`GaMw—nŸÁflJ°ŸÓÕ-™Ã—‚¨oûäÛƒz*döó­ iÖ”?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?ù“?3ÿÙ?¨û 0 