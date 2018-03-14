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
‹ ¦á¨Z ì½ëzÉ‘(è¿®§HCl‹Ô€ Á›$ª%DBmÞ†¤¤émµéP ªTaP )ZÍùöÇ¾Äþ;ß>Êy”ó$·¼U@J¢ºm0žQÈŠÌŒŒŒ{F¶ã¤þ»¯üYYYy¸±¡èßMþweuÿ•j¬­n4Ön¬7ª•FcãáÊïÔÆ×~¦Ù$ÃP²4šÛšõzs~—y˜ÿI>mXÿtÚ=ƒéM¦Y-ë…>æ¯ÿêÆÊê­ÿjccssmÖ}muíwjå+Œ¥ðù¾þ÷þPGh‡Y?¸§–ïîÐv»[jáÎÁžŽã‹°gªù²ªžO³8‰²LíDÑ £d¢þ¨N¦£Q:ž¨Åç;'KðÎIGã(Î&ã0Ë"µú¸ª56VÕËA8™´ÇÓóóª:¹Œ'Æƒ0éÞù ÂaTãÏ–ò6üØœNúéX~<™D½0Q‡Q<ˆÕbeK*£gµ”žýûDPë¤Cx»Õ'æí…½0›l÷Ãä<ê>¿bôï„Û·Û à&ÇÑEœÅiRh¢àfGÓñ(Í"†ôhFtÆñh¢&©:àŸ~¤â¦–t"Å3Ta¦ÆÑdš¨NÚé$ÊôhNû°ŽÃ€¿†aœ®Ô4‹ºª—ŽU”\Äã4¡E…Åé§Ó‰:}³³]ÃO4î,+ô†Àú“É(Ûª×Ï¡å´Ø©3Æ2dq@âØý^Ü‰=…—G{Ëkµ•»óåÞO»q/ŽºØ|Í¢HÁ¨ ŒMÓ†5»¢IÑ/ƒôœf<LÇˆBøsN°%ü¯CK‘Õ§£.,Xvçƒ]VÛÀÓaüwîòK Ehß¾Þ9;><<=Û9xºðÑù¶µ\
šœã.¬¥ãóÊ5 •tUÚ»ƒqn¶Ët0QoÂÁ4Ê¾`BÁ›ÖñÉîáÁÓFm%Ø9lµvžVN_·*ê–Ÿ{@Æa{ñÇðG8EÀc öóÃ“ÖÓÊ‹æÞÉgÀ»ˆÆmØ@3°±N¶wNÏšû­§‹Hì	°µ°²œîíì·¶OxZ©O†£
=|±»½/|ô\×ý×k•àä´y|zöªÕÜi?­Ð7äT!,5,ÛÂG§÷kµø&•/|ô]/1¥/<¨ûÍÝ½æÎÎqëää)lËOÇ!ìÍZ§´ŽŸ®.E|ùJ2¸Ó¤ƒDõ%ÄÀàîv÷õd\êužG‹KêcžÍîÄÙh^qƒ;îÉÉP!5=ÚI÷³sUÙ=xq¨¶¸ãj~‘\î_ŒÕr¬¾ÇÝ½{ 4q°Ýz¦–wÔ÷ QtwàïŸùï#Øí—é¸ûˆÿ™ú©¬¥–ûeÄN«Å	Ê‰!Èyø6ãõ‹²×KvÊŒ×Çe¯wúQç=ñåq4ÄâK3 8ó¶M¾H¾[ª“<Ý‰ÇQ‡xÿ~˜ÀlÆ3À•¢î9<Q#yD¼dÆÛ…eÁ<Q»"ËÞÛKÏ‰=¬ÿ¸wø¹Ã5·‹{êGxØ¸VËçµ¢~z‚¢>	ô4·Q˜4“îLA”Q»…«×ôs4 ±«Ûå8^ùû+Šž÷âà:¸sYWºµö™°˜GMâ!é.ÃÑ×Úê„õÅ¥à#Ís÷àèõ)ÉÆw[®Ëˆ> ö†ï#Jîø
6Cr®ÚüÓeÜv€_Ê	Ô5¨å€AWV¡J@ræIÌ·ª@¸™5©ÀUYRêtw¿ut´‚5Uù·ï~Xþn¸ü]÷ì»W[ßío}wRYzòÄyõøxö«É/“t·?£ßÃ¿`¯^¿•ŠÛàÿî5¨•|ôKQvì¨@C
¾®¨§JÔ€üfÐMµº0¯-õÑé§ØÞŽ	È 7QEý2Åq9tö£yÓÛWóÁ˜f°¥ôŸY?îMÌ·Ë>î{5vû/µ›z]|êÌì°roœ]éçƒóš:3-Î¶›&Q‘7Ýá²={V6§0ì—òöÈûüÙ°HW  R¤ò¬›¨éØ`M¦èC<ù
ÊÑM‚¯Dyì	Kn ;6ÍW–ŒÌEî
’¶ =»ìªá4Ž
Í[0MµZ®©·`Ÿ«p˜NÒÄÃñù­å¬¦N`sMI¬!{ï¤cÔ;ÀœŒjn«·íBV‹(Ú—nãFø®VBjhúI:¡EÍPœ‘	yÚ|~­ +ørÜÜÞkíæìyó$‡8@ô½ÒkÔOM°÷0¼ãjÞ|› o§ÓA— LÒi§ÏÎËCû'€¤aW½[øøêÈ£^ÓƒtÁ­Ý8ß“¤}‹óL,êºï¯ßø~k<ápº¤Eø¯ß8~Vw<MÔ_Ä=ÔI‡Ã0ñÁ­~¸næ¨è¥P×n‚ºgiVE-Û¥èÛÐVŽ¢o2PÔ-¨ I"f‰¯`>ƒHfË!ó¦«RÙ"fKxÄ¶qK|ÂF;vpˆÛ:7¯™G.ÞÑÅ1cÖs¯×á[Úg¥~/wü/å,•?O³‰º“$Tèïýp0H½mú§ÙÎëä}’^&<õúÞ26ÖŽ’ëó÷ÇtÓP«#T¨yÏ›W­r2z WŸÕ»ÑE=™¦É=À(J§]½K,Ôî4Bo+¿tvàÁóé¹½;èî\æ7ÔpIÊºqÛ:KXþ‚5dÈ„¿@Üv‡/îÆ³ÂNšÝ$žÄáàËý iÓptØ<ÌHaaaG¡Á7¾
´J¥›±Jå«SL	=l–çÀŠ¨•µ*ªšž¹»Ú0ön/V*0c‡ŽÍðIÎ®úåøåj¹›ûÙ ×kczÃ¾ö)¸Í_{PSØ¤pP—H!4«eý</P'@Î§P¬Lq&¢a¢›þÔ¬Àñ0ún%€½„X	XzZÕ£IÖËþ;ô¿P+Sü#.Ò¥ª8žoò9ßm`ÖÃÇJÃíÐ±˜;¤n’’ÉhcÚ¿‚epûaüEžw‡ö'ãp¤*ÞÄÖW*háð,ÀºãÑþÄ… >ærÎÀHu¦ ë%ää7ÑžŠà…5BÜmçÑ$ÑúïÆ)n>³"£ˆáQ8b˜ 7Œ­!y[õ/â­­Ÿ·Z[cÔAQÄê5<qÕëþ’øWQp±”ÓÒßâ%µå2’éá æ¥'Aw°{÷f´øY·pv3ÚŽ—Ôqëhow»yŠ¡…Â¨ZK>U–Cù“žìªZxàŠ/²Ð¯ðç‡£Àár(ÈmmYXÔ‘]mà6<Â,<B=SfÃžþc#ÀFìû_øôÔ'EGE(˜A9§CÅ0…H?šöeV™‡¹U@ ¶¡)iþR.Œç0+Õçì“S‚>C˜Ã|ìhæq# .#@×¶ÉÓ^`QÀn-WJ=Ð×A	íê×Ü‡ `áãÑÛ™È5£é"‹íçI õµââˆÌ)VÓD«AÀcsiž¼i¹¼ÌQååÞ8Ž€ž®àI’.ûŽ&ô÷Ñ8EãIe8RxÄ8²Ù9€áócwNªt¢Ðp2­´	DýÌ'ª<…å4ŽãÁ:¯7¼æB%a÷gÔ“-â3àÌaþDNÈ{EbÀ}9V÷³ú_êËõû.%Â[?§ œž‡÷ÐVíî°£|8LâÆ51Ã€¨’^
–Ë$ú0Aå~¡þñàIV—ÔUýÉõØÀÎùsÿUZm9 K?…^ruÄBÈÛnL¹'!Ÿ“h|¶’Þ‰»&‹ç *Ãh:ê~¡‰D£®×÷’f!ÎÚ¦íõ]tÅù\l%¯nÉw4èX3±/fbˆN164°b4ïövšGôŸ#H}Ì0c)·ð1+¦ùö/g‡±X/ß«ûÏ[/w>Ÿ<­¼K–ßÝö‚þ¬<Ù}ypxÜÚéð´ñ„Í¬§j¨ÿVõ¿6»Ý1¬A9ëÂ*>z÷ý}ìåþ»guõ&µ¸°Æ[<x¾$pVž¨kV|$ƒ„žù+®–h¬Þ¾3Ê¼¿³`u6Mþæ%*.Sƒ°¤•y_;–ß6~Z9žeü¶:w¶:¤àœ]]À¦¡Ã|vŒcg%+‚»ß÷<Ý^R!´Òwo”TäÅ[8:¾¹³¿{à
Ÿ™r,ìãä‚¬(½J×j¦ó¦4kYKéŸ±ªë«¾à“ÕeÚ<•­ü‹³5p?lUžá^«º—­t­iý¡úÃ­ {j€[@ÓúÆj)±¯Î¨o¬z¤‹óóæÆ½ûqù·NIýöù?:ÿ›óö~“üïµ5°|lþ÷*å7¾åÿ*Ÿoùß¿Qþ·Ùpÿ*ùß’ù‚¢cr®”}KýþOýþ×Nä¾Ó,îONáþUó¯ÿ¥_ÿŠ¹Ö%™ÞH
_~]Hó=y¦–‡ê{g…áÑíÓ­¿$×úö‰ÖÅ1ïGDbsãIÙŒ·Ó3oï‡ñ@‰ß¢üõoùÍ¿j~³ú–ßü-¿Y}Ëoþ–ßü-¿YXä¯ŸÄ<'£Úà|¦àû–Ý|üoyÆŸ˜g|G9¸¿EFè·ÜÇ±ÜGhÚ:xºWiÍnÊe²ºMÓÒì$Iî€@oß ¿€jï8 ~zž#[¿õÕ‡[ñV‹’LÆ“É‡Chèx€µž§Ûþ‚Ø¬þ®Z§êçK_-òN²ÿåSá„íåÖ¶„U“8¾ãz7I”“°]êÉ½˜sÂ8R uº-Œ¡™1(³b÷Tg¡5úè§‰²=:¯âŒ†¥«®rÚ|þ´ØQICBÇÙÞî	†ø9/ëBÝÿë½ûö¸Ø/éFÞ á°µT”E‚†·ÍãÌ®ñ5!<!…÷®dî3à¼ Ý£QNR|GºÓ<m^×à‘ûÖ4‘œZ;kKéŒ­Y‡iVÁ„º%î½ß0 âñQ[±cÀÁÚƒwõw‹ðß¥w8ŠÚƒ…ú»Fýþ’škDŒÉM© ‹g‡—V„®§Y4¬åJŠã·.·‡È@«ûÕû
þoIØ¾½I¢Kbçq’[ Rà6;_Üw‰ öçÍsiBÖ§¬Ìž+@«ð1t¤RL8ôƒjø:†ñusRÒyyFžßú¥Ÿ,]°€2s\Í1G çF=õ‹Šôv«ð£_è; TÑéø¼–bp$«e”%Y*ªnË©“üÒrÇéwÉ7CU~‡•ŒÞÏ²2¦£ªÊÒé¸¹:[Í’¨Ã¯Jµ;ý³¯åÙ´¾WØz]#S¬Ì}ÕòH§þü'¥níìû~	oX³gŒ…¶Úœ‹ËgçÌo•”{^k½ÈÃ³l2F%ig·Ù²n-ëã§é„¹iw9ju‰tîû?þ¸Õ„Éû­Ÿ~º¿TàHÌî¿Ûkæ’ïJ:ÐÁŸaeûO1ƒÍ{¢nq•u™ûõw•ê»J½ ¢~ÿÜ¶¨Ã·%ßËÆÛ”vVàé¸Ü|Íýlá£^Œë33´kVè]Ð³—7£¨žÃ,Í	¸Ý;ëœ_PHkûp¿‰º¾D»×u†¸<èÂf^^î§Ù„&A7ðÛ­ò
o•_6LÌ`sqíp((·-d°3°y¶^‰Çüþ¿}7½ö@º-~A{HÊa°ð3&Dz„ÀY‘ù†ŸB¾ŸÝ†:Y’—•s&‹ÞÏ”b *7=Ñ8ÜéµnK8âžá P$ªmfb¥Ð'gQú¨øe@>¨åŒ¼*‡Ç[-£žÍ<7\AÂ±&H‘
’“‹‹ôÇ¿5–|þPê>Ÿ½ì·ÇK6í e×3û
˜$ÎúQ7ï~·ïyÛ¿@buÓË¤
ê§žþe»®e4Æ”¨[«g‰“[¾0‹\|ÉðäF´LAR9BÌkÎ›àóåõ•×ü/,.]2~r~ÝÜš
‹‘\¾ªëB¸ƒÿ[Öêç}tþ'RÿtôÛÔÿm¬;ùŸ«Tÿwu}ã[þç¯ñù–ÿùåš÷¯’ÿÉú–ÿù-ÿó:ÿs¥Öø§-äû«fžþp„3z½·wë	ñ¤ôš=g†pz5Š‚¿´ZGO×?Ž ;˜ÛÑ§÷6ŠÞgÈhÞGÑ(€>ÂL¿§•åeý÷-ÆÉuì+êÅ <ÿ–ðúÏœð:Qß#©þë§¾š‰š³ÃnTL.Ù=Ø>ní·N›{ßRh?ƒjÿ¡Rh¿•þ–BK}|K¡ý–Bû-…vù)…öV´ßrh¿åÐ~^­èvÅÚo¹¯sÀ}Ë}ý–ûúO•ûz×Å?ÿó^'[ñÖp«õ5²^'`›ª4wô×È‰½ËZß’<‹¿%y~Kòü'Nò” Ø-“<ùjýÒçZô#›c±ï:ø|…%º@éÐ+î|u$ž×HmöûE‚3ôcN©ÚÀ¹Œ¢÷*!W|pÐz{ö¶ÕúËÁ¡ãsy]Y
÷vì`Ø†×Ë1p½´D¯?onÿåõÑÙI(;=ƒNá%å½¥¾CS‚^Äì =ìbÞËv%/ûK´S˜3.MÔD˜ÉÛñõÍÀ0 
Rq:>—x¦@vGHý)}KöU_švéçZþÃ&—€+$ãz‡°;»XMèÈÒ—U]üÔb¡$Ê¡,Pí-ÂÉ§×²ãÆooÛÃâE:*K=xäÇÓ‘7ÉÕÌèm˜[Ìá6+»ðÑ‹óRá§[fwº™ªlíÄ\ÇzÊÛiÒ‹Ïí2ÞbÄ‚ NîM;nXµ|ô÷Nï68ª»i³³69ÿ;›yÛ‡/Ô³Y³¾ajºò¿€gŸ0·ü«w19¼>†¦öÎSnh¢0µzØá:Ïæ;Ö@u¾N»è×Ð_¥’éXn¡VóP8&§äŸâî,<—aY„[¹áÛ'ÏN~^º©?!øVù¿ÒËgçÿÞœû[ðùÏ&½Ò)ß"½7§n7§“Sr:!¼A"]–é~¦ÒAÄôVO¡®Ab¾$±{sË	ÿ›Ò½K¦(·Á0\íã6}iµÎÓIŠYßã¡Z—ïÌÄ›#3³§qºSè¥SÐõ£óZQA*ôÒÌÀŽ¾¶èŽ2³exß2³?áó['¸~ûÌýx7¶|¥>æço®?ÜX·ùßëÕJcm}£ñ-ÿû×ø|Ëÿþmò¿yÃý“ç~³™LGø@j‘Û£ï™Í…;$¿eÿãeKú«Eô›pc0ýóÒ_ÚID÷ÄR&ígÒæWóÂt‚‘Ùt¢®"s·lMÝñÅªxuHî\}öuÉËµ®x.¦çÍ“Wg'‡¯·[?®ü*f^—eËXÚ§tyˆÐ±†
Z2í`lvlzjY)€® ì'jtÙþŽÐÎÒÁt‚15  íƒ}ñT}Åv‚ª¸¯ñ•|î©xßÚMÃÑ¥Þs8(qçW‹3ÜÜˆdä`Ó,Øi½h¾ÞÃ›5vø0Å*…d_W¼6¢º;X‹ö[yiç¨œ¦'ûg;‡ ÐzývSd~C0R·›{n+:ê<³Ís )ÌÏÁi…ñ!nM:3[¡}¬û<ŸÙê´µ´×<mH[¼¨k€Ü¾qt|¸ózûÔÅhœv§‰•cG˜~ MzÃËÆjmµÖ¨o+4|±ÿvNcö·ÈQ´ûòi……Õ9uÑ™T	ò qpO]Šü(rÎJ\ÏþY/ÂõµK”N?Š
ý­·µ?çÛÖ²“q}«æ%SsÞXO-XêbV[šØS73ãÄTôM‹ÈMÔp%P¶âw¼˜HØq-jw‰4•Ø9}i"&$‹³›Ü{({x½UGŸà‰éŸ\x;Ó7:;Ô’Ë»¨ÝØÜ@áìXæõ(Žih=ä_èbc®Omø•Š2¹ËQ¹vÀã¬Ãp5c`h4ËÏ¦}ÀM”×GmŽb¯ÅøÔs£Ü7Ï;s€=¦™»¶ófàE–ëƒ÷-ƒ÷ŸÍ_Â¦ýÅÐ{»Éneëa¹šÝ¥ø­°ÆNÇvé*Ç'ÝéúœÑv¨Ÿ|i§Ïu:þsóMSwiþþÄÎ~/BF-r=¢ø±~¸rkûôðø‡3N˜¡$Dî7èÌ{@Ã)‡ƒ3ÑÞ¢;Ñ ï:p2¹RÏr×ÍŽNOÀ2{ŽÇ=¥Ó(x§"%Ê&æØYô!êLiua•æERávÐK-’Ÿú<‘%Äk˜Ë†™ñþWÏPôÆT–íûnFº/oM¦ãD5ò—ãš…–¥˜f¤æÇÒ+‘yDâ¡õà8£êìµ‘ŸM¢ñ»P¡®´ˆCs/RGÍÓWhÑõâq6qh+Å»/cMã¡Ç}	¬ÖµZD¹Ì=‡W7ß´vÎ8Ð1þsíd|˜;çl«b¤A`	¿±%W=Aƒ)ô`_¨^.0 S9‰„¥W>#™8B¤R6A:zKíF+ß×.×õÉ’Ácù`Ê$ë'Žåv(:yIò†R*ÙžnJ™§˜\«‚êq­JT|hrà”“¶krKœŒƒøÚ–á”Ü‘êÉ&F£!âß”ù	K|E7mÊ$jµš;h µ3²9”6BH)u™¿'aÛÑ+Åi3úè–Ôâ­“:wâ&šðÍµÛ¬õè"ÔÙD¾A–‚pÁÃvio‚Inï%ïÍµ4Qw‚‚ÈØ¬§ò•¯¼ç¯¶µ¬€1Ý1"{ì9)’NÞŽ(M3Í1·¹¢ùéµä1KKÞ7·Ìœu(ù¥¹ô×OO}ýÂlVé•Òò¬IìÃÕæþPBEÃÑäÊA¥jXÔ3¸‡	*©¨*^Ö¦—Tj~ò¹~NÃ(äÛÒIƒ0¹òahVEˆ.q§©¶•2ž'¾$Ó¶}S‚mnÔ—fÜ:”!TÑpØ
21xÜ±ÎÁÄïÐNR4Ws6J	Æ5Ãs¯˜œY¯+‡´)gVfb6òPàê+ÉöÎÑÝ'ÓÜ,zûtZû\:»k#úúj)Ò®îf%Ï¨ä9Ö,ú»G`òT^Æm	ó{Md9u{ô×G<ð ?¬[·›ÑD.¯¶kJ›5ÁZå˜ T²QÔa—<<1Çh&eÓ/Ìœéy  [¼ŸQøŽo>k ebÙ…Ø }…#Tÿ¨WÌéaL'’Þ?æÃ©?ã	Î®”šp-‘t`ÓL@E¾ë°®,Ëék<ðtMdpÌ–wvÏäÇJúÞ«ð‘ó E!GÓñþ`µ'»SØ¯ êlÈ?\¸µ YÜÞÿô'+ÿô3.d®‰1Víè˜7Æ“Vë6£”vaq~Íá¡Ïô†'ü0ÜÝ ]µ)7p¦*Ë˜q‰®.²d)ÿF‚‰Ô1øÌëé8ì¢3òð–áì6 ˆí5
€,ž¿Œæ]Ao92¦fð¨¶
©ª¥/¼Âá..X,/ÞäµRÞû‡<Yz[9Z·ôŒþN˜kH{îòú–{2¯³1è½æ‘:Bö¬œ¡`Ùã¼NMOü¶Òôìäd¯Ð¼IÖ¥ÍÉQxáØI«–×ôÇ­£OØ×¿ÊLoµ…óçYþ6§t)åSV¶êu')a‹ºDÛ5ÆøêôôHùŸYÓÁ¦'¥Mítt~ìì­;/õá‰Îé¨(6]‰)¢U21\ÝòkNÆ.=WÂ=O(æÝ©ÍòMÜå•<Î½Ñ©åâ³Â×²OÅ7>fžÃÏ=í.Hû‰sBù°ic÷ìl_…¾!€¼E¿ô‘¥/7œüëK¸Ï´êB
þ|`kK®¤ôB_Ÿrs6ÈO‹¦i(%šunû¹5#òÜž€“ÑÕ^×b‡™äóøË äM\€“?ÇÉ¤§î·¼‘©ï–«øßMúsÿ›¡©Xœ‘¸"EîåŽçTNãä¬}¥êÐ‰ãZþE"1!cW…°X!í˜¾v_~Mnæ¬èG•giçb!kÀìÍº®¼ œî+05­p B„¦šNŸ1êÐuðJÇÂâÌƒ¥÷Ýƒ¥÷áñó)GMg¼‡O?ºs¼v _"!Nc¿?ÝÂ§Hø;ž'½xéK”;ÀJ’-gƒpÔý‡›w9º³y_²ßn½õ¤
ö‰·Û]C¨ Ä˜õ±²QÊSÇ*°–‘žÌWØûŸº§OÈš{ºÐðåÑòxŽéïvåÒ‰ŒBwêßßœÆ9rçW3O×y©F&S×ùwh7£¦4­ ÿñÕa"~|Î$˜O5u4ˆÐý}@*ž®È½ê¼T<Ì—+Ûç|-ÌègókÎ¤xÀFPÈóIóvs)·ÕËítg _£Ò¡ÇBØÝrKæÁÖÇ?ÛÐiÆŸâ0,ðœ†Rº¢EUÞW¥?žÅƒ“åDÝ¯“Ützˆ+A¦IB*G½ZÿëB}t_À
Ýl¹Ó;_ÆhS”ÐÅZb-`0Ä³gtÏ…>¥ìï¿ËÞÄ‚òz<ùÊ]·Ž
“tÝ?w‰Õ¯ËÏb¼=?»J§cÞšµÛð³{š£áþ¦?ì‘Ì»ÊŠglè0%¨é˜Rž;º$îF`”®ÃÇ±?öÒÚ4Ö=.oÃädÌ.l»¹¶9£-ÑÁGý'´}ôØƒûù|ûË8Z¥LäÝÄ3|Ä¹·ònÇ‚“.×Öõ;–ºWöyëÿªóFÞÇZp°~,þ²‘Ä‰;« ùgÚž˜óÛ@+Ë% ’“e¥‰GEF6ÓQ%¦O|ÙÉÓéÕËlÝÓúCŒ9V•zîÅzçÝ»Ü#öQo:Ýr(pËÐÖÖ‚–Š;·›õi&Æ°ÛÍÏ“f ²ïÝÑˆŸ=›5æ"×þÊJ`r6’‹6ËôÀ$s‰iÄ÷¡Þñx~¿%ç“>»‡+×ÁïƒßßSC¼x ›Ž£*–B‘¥Ç1 7Lît¨_—LYÇ£­ jÃƒ,ø½ì%îáš
g¬›-ð{Ýózð{@4u‹…YÊ¦N«ÁeH'ãiä¹¾3PA°’
˜ŽA’‚øþEÑe¶Ui.ÿ_áòßW–c}3<øˆ…eí˜~QìûMTÃ÷ÄâÀïeX<ršÿñ@ˆÉ­?èŸø «ü#è©ŸæÔ“Ï|Blƒ~û>O‹äÏüº™~4(‰Éx©ÔDŸÝr‹¤Ýññ^-¶ryŸ­h°Û:xóe§¢-X°x^ŸœîãÉ LçU{
Dã?_Nêáµ}ÉçKö%ÿyî%“ë|ž:i¾_Þœr“Kšãó\s/Fà4÷žßÁ;ö´†?,ó<×^g¸ç§¡Ÿçš»gQÝæÎóò7ô°üúùò}xí~ñ=o*O}GD¾'Gâyo8Ï‹¯øáûŠÿ|NW¹÷Îæ­NÁÈ/{¯dj(¡UîóT‚;%MåþêBS~^öHÿ2Øø¼¬9¨¥Íá¹×Üå"ún±æ óð³øˆ…”>åÒ]¥`„ê´yÌç.$.-ê HaQ9‘ñnÁ!ØºœŒ×°I×¸ìšÙ½œ©]¨EW/Yr@¤þ%[/éÈ”ÍöÁéžkÖa.ÀH °â|ã«ðtê¾M×[yd@ã‘+“7@j	Šª¡šzXÌÉGß•g,ç}Dfx|6g!î³ï_È-~eCÀú¦N©¸Ö™%D60²ÂÑ‹ÜÁš²ƒpH½|¥ã—/Bd½Œ|rËc*èLúÙ=üm—I–RŽ©©ø4BìÔ	ÐèFÆõ‹^ŠÚ’¥r*Tso·iª»S{Ê‹†QHjt¶X{°ôtñ~þï—ÊRí%G+«éaÕP:,:Æâ=„±ðË"CY0Kõw«õû%P>Ê_[Ë>²‰”ÃòJ¶ÄÆ+%1«…4©|T?þÚKöAÍã*s©À†UËFÇï‹Áð?Ã/*Ü£Šýao®©°ûohTžðeFO´²ý ž|ÅÉs`žãLÏ>4'ñ…­_ƒŽð×êWÀrR×®úÓp#r¯:¹ XÔÆ}i¦§Îóªz¯ LÒ¸Ðg˜7)¥Ææ«9ñëÐµ7œÜpo7 ÜKw4¤ít8L“#`fOü)ß#Ó(I/©Ýq”rð´Rqž;óÇ²yÝ[°ÐeŽesÿé§\öW’‚É>éô«j…IÆF{$HLî²ÅÃm¶ËíMŒó¯ÝBf2ÀÒkjqu§ïe‡åY$8ÅœÑ;§œî‘(ƒÞPÍ ‘]Fð¿„ëRWY"èÛ¤ê\8ú}–ËWŒÒr[Z£»V›“ìdÕXÁ»Ég!m¿Îœh=ê•bÿ÷ØA\‡ÃâjS@ò"¬‹Aß¤oÑ§Ç!ƒ¨†¸=Ô€& @p‹ú„•p|Ð,JUÞÁBÜXe
NÒdÙiB-^¤ãËpÜ•5›Oyz¸p8„lwÞÓUà#â“ÞíËn‘õIœõ¡¤w~æt[D\nc7!å0º2‡*`%;:íŠý|t€l5|A*BÓÅW¹ëî.rorÒÐ[{ZÑ%X"ý×4Ê°½w°)ú jv&Ç’õÑ×;wVó²$ºôôïYÎ¾æ‚çg'§Ç·IîôÆ Ó<—<p…#ŽÝN®œÐ†Ÿ³zóåI®7¼´–{IÇ¯ox-—™+±Ù^Ú˜“8{Ã«wž ›£$L/ÙÒD®"Ž~ïS#7y˜› ;+Dø9	só:.¤îÎîxÆùäÏžJIêMäÜ:
}è×©Èw¸*G.—Î‹ª¹?HlÍ¼5ç ‘>ßéÓ‘
ä-,j%°²à'•ç¦U–òðpƒÍ
šÏÐÏ
çŸû”äHA§æÎü5­—Òû=¯€CÑßgI€ôPV£¬¸àwA4†«ßcUR3jÃJ×ð®)«öµ JÒå&Pfr¢û–“è¾å%ºoYï%þg£x/…H¿rT5oˆºª§¸`=[Å4›3#†²G­ð}Ù;@äDk®k§’ý¬«#@ÛŽØ¡²S^õe.¯ðé«2 ò‰'ºM™™Ê'+?æŒþìÂœ­ô›ï„;dÎ¿	‘Þ]¢Ýûù¸Õ<5÷Jc–ã²T‘0z_wcù³.
T¤Hææø1ü¬;˜u…¸)5T¾ìÞ-^ªó>ï]¬´ûY/b!ßÂ‹º
Æ­qZ,iTËÑ…ö®ßÅLqwêà«Ð•D7ÓëÿV'¥ùù—@?íÜBÏ‹¬/…n]—ŸÕþ,ÌÜæH·úlÌü¶ë~SVœÙ-ú…ÑxÇº‚Á§X`…ú„7–k3¥¤·f¦–·ãdËŸÓ–[R~×õ?Ír»óßÝ`‹çÑ~sìöbåÔ¢vëÚQÀZÒöÇU›´=Ì2ž¸%HóªHsKS»íh0îXòÅ¿d49X7*ßÜE§&Þ¹ÁƒÌ&Ó^ÏV¤*³±)wu”ßÆ€zPÈ1Þ™Åún@i±S¨¼<—uæû>1I4=vkÒø^Í2ÉŸWw1ï¡6ù0)ßowøNÒOW(‹ä€²SÖq¶sp?;Z_º~XWWòMÞqOÌ™™c¸Ïl®WÓŽà{iÏn=Œ
ÖüÁ”¾dQ¾ðëC_“ÿyÅQÖ¸¾Ui1."é“Â±|ï`Ï¼‘€Ùt·NÖè AÙýOÝ´SÿÚwLÍ¿ÿ‹ïËâû¿6W6×7ÕJ£±±ÙøÚøÚÃÏÿðû¿pý÷v·['­¯Ö]ò¶>cý+ëµÜú¯n<\ývÿÛ¯ñQ%Ÿ—¯ÕËÖAë¸¹§Ž^?òPB"…$#ù¼‘´µªZ}¬þ<M"µ
‹ âGWãø¼?Q‹ÛKôP½G‘:I{“K, ýïú¤£IU`šú^J"õ²^-Ÿ×Ÿªu¯0Ó ÎðÒÍa<AÜƒå£+ÒXºx63nc<Ú¶jh#,‰Íyðæ€/þR@òSäÏUí9e3c“ëéeÔ­³¦KŸ£qAíÀV§ ”Ö(Qr Ž¦mèM_5†pCÐÎ¢¨J#DTä™!d8*¯ÞÇI—2AÏyŸÕt'òV&W…áu¶ÅwGx¢«ÏóËTg»eñ9Ö¿ÇËdð´Fx^ñ‘D‚@µ°¯!q&!i[<¥ž_¡K/Ð›TƒÉ3Ž“I”tyÎ§á8„ïQ¾Ç Ð#&HJ#Í?Äº'çãp¸¼<IíAE—©Ñ­OÎâ.M èz›f 	†þ–¦DsHoÊEÉƒ9s2(O±ÚòØ`þ	Ž%1ªÏXÊæ……Žy5}˜G‘vJ”ˆ¨o_ÑCºþÇøC:Å‚„¿!Â–Ì?ƒ)¤)QÂ[‰_F˜E¾Çá ÌxªøÎoŒwãQ–.Vÿeœã=¶“`4Žñœª:ðå³õ©Fy¨§œZ@™&ˆW‡„œÈ°0>µ(Ë)#ù„!ª{ R]ÆY©jºÀ4 ³ßDYì¤Ýˆ®^éX<mZz1¸1}vâ¼Šm26ÝÃë¸Ú0¶$è–hœßœ%,àÞcb‹†Û¥T¢,ÍÉû3ÅW'˜•DëFl/£ÕH"Æáh]PÞ2R†¸ºAE¿Â5ÂI0L~Çfïå'Úä™æû¦u«ñXéâ¢h<	)‹dq;Ä“˜/ÛÃF¥«äb©ŠÝÇ=¤@ únÜC’Ü*Âƒaá3œ´K¸EhŽ„™x÷ß‡p8 Üy#È¦¾Ýñ€º>§ã¹{ÂínÕ‹d²C<m„æ š}rOL “IÆ3Âîd\Y°º²óPŽÄñ’ÚtUÝ:pH±e¨à4\Ì ²>Q¶
È­Le4Ä«€ˆ	þŠ5™žäS$€0%f´G{eäÅÙp“Ëï	e[ÁbcIá§ã	É–½ˆoq‘²W— çÀ"˜¾1ÉæÎãMwƒè˜IÝŒd¼ˆÝª»‚ ®NÜQÅ¬:WiÖ³ºÏÞfy÷õtˆÿÒ4aŠà“càxv™{ Wb±xæ9FYrE¤@£ö¸K;nù1û§NÓikl»Ãp^<ŽßC¹´Ó
 vD1~OÅ™É®¯ò*ò°bâÏ 3¾\®ƒ	'‚›.Å—’(fƒ+’<$wd1ü`ú#¼ÐXðK§„#·ày©î±Ç‡R	÷ÇxšÅiä67¾w‰¶`“…¼Wõ¼OM†a2íú ›`§ËRâ2(ÓÙ(3Q}ÂËm ¦ÂæDÿ“" 	cä ^_ $Y	GN”pfæe*»R¦ûs€û&±¬¡["ít¦cŠ«Qg ‡12é^DV@{îNA#Îá-d&q‡2yGÈ!²†ÉtÅWÏ¢hŸ&ˆÕÑýI>k½ŒXÜÙÅ@„èÃ‚`$)bóiX¤8«X‹„^SØ^z¨5:ñ@33DŽñ lÚF/Ç&,‹.!÷\Òhð÷.£ šùÑT·xT L®™%–˜’ÒËº€êMquqvìU,AŽ²JK+f79ÆÎJíð8ÁñUU„
ºfÛˆÌIŸÂfˆ'Ði*Òy	Žðgä{XÝ6¢8ÚHú·n vSg¢Y	yWpöD=«ûñ9iTg–GœL¯Ó\Ç«ûD4i&¾›’xF¥ƒ¶æEs¾¬ÎÏí"‘Ž¹±«z„!ÖêÍÄéB¨€¤:‚·v0u@¨+Sóª&šk¸^–ãžjnèþ`
S¡k‘	FÐ]c/ŽÅX
Bä"wHãÂê@œ—Ú£Û«F¨w8|\N	ÿ07/âjÌ¶…N[Çû'ªy°ƒ•|vvOwN°ñJÏ»Å	÷HïWNSaõ”ÖWï¢5³fjáÈX•V¸9‹ÝÈ»åAü/¸¾Î*5täÛVY6Ua-@‚Ñ0F$MÑœ0{oÆ¹Gˆv‡:¾é“<Ð¤ë‹Ô)«g½R­:“&lv»°ä×ÿ¯€È­@«Š¼eZ’ŠUj*0²+¤—ÇÁxÁV©¤oÒ
‹d Âc“t±œ9ªn8¢m‡_(ë_Öß	ðŽê…YŸÏ« ÀD–nµ«TÃt¸ŸÅ	)°hÇ%¨€ÖJ„Ó)uÐàâŒU &dàŽ«È˜ÔbmW‘6HU´÷¿B»­MUé¤ Úà³Š "ŠeÀ°»Ó§,¶ž ¢GÉÏÉ¸»ÃsÊ\Èã¹KdBVËG’
á¤ª¯3\ì]$Â:2†–€taY„¤	Ò¾8Þ¶Sœôp5èp”ñ§µ°k›Øô”múÚ9öyàž4“TF‰Ã_Q/ø@­Ù‘Ì	$ÿ`
ÂÐð‘Àã#‹4Y §omw™
xBæ&?QÞƒívVPðèR,º’qL&-ÊÓ6?`Ë\FƒY	ÀÑE”'wÜ§¸çEK0S Þ%÷"Ð¿˜5´
¨Q‰ÊV
`aŸt†Ðò.>¢HrêRAhÔ	¦ªË3©	è¯Y¯—E™6Çlpüx!Ñlbû¹ˆ¸z Z¤‹, ÓhŽX¾àRí‘¾~¢Ê‘U±‰H;`ÊcsW/ä“XKT „—’¸F\=åÆ(BûÂôÌî
Ó·%·„ú7vF0EbsL°4_©Nº(+´áNB^ˆEE&Ôí:Ð6#fÉX%×2f-Vx¤d²8Â”F^ã<´|·p²¹^‡^ÙHŠ¹^Œ&‰jB’4°Ò#bËVÖ„ìØi•]Æ8,úA9ÝŠöh‘‹Œq¿ŽF£¦$Þ´¦§–ùÇ­ˆ©ì²#VÐ)„§ƒñ ²ËçÉ¿ÅÛÒÝ¬laLP(¶Žˆƒ#x»·P÷«Q5ÐÐc¼'¨ª†ã®ÚÕH³¯;ˆäýÈ9¦ßÀ<Qce!èK®@•éŒØ9È<¼ôJ€É–v¯Ð{QÕ¨¤3V íMG™sç#‰¶}g:·mˆh€ö7ÏÑ’ððôÞ¡®X‡)ÞÀhívœ6qVa/„]£2o€ Úã™Z…¥£pe«FÈ5âCdk`d+µBR3&èÒ;‹á{_éí®FB|AÖø\ç}xÎL~?ü°ì*MŒ[ÜKÈ•¬J PóÀiN{¼½¤¨/:bX×bÆ**º°‰€ÊB¿¸õÔÐMÄ¾*-4
ÓVdRV(Š
ËëBD< Ç&¨äFQ²Á-—B§&úŒd››¢®F†qxz)X|Vj4@Ÿtñü­1£ÔSxÆgÊë($—„07° 2¬õJdž 3nŸ*À¾Ïª¬—`÷ñ k³@ÌJë´çv°‹ì¶åÝL`bßC˜ÚgCºíeFã±“Ø‡ID%H‚œcÌ1(u©¦ªöXñôxœv®Ä¦—h`ÍíŒ|²©v5Ù©2Á>WŽÈp(^‘Ää³z,ý«ô­Ö*ŠC“°«÷œ{?òÛ•š72'iÊJ¸ü ;À"…'´SYÓîX¬9Gé¬M 2ÉeŸ2îÊÀ¾ìoKm-çi-[ÇÀˆ~G‘0v—Œ@34í Dïòv•ÕäÅc/h—BùÍÅ‘$¼oSÐÆQº«$òµÈ^rŠ|{Ú6¨1¥Ã´5 7!Ôõ‚‰Û®hqŠÑØ”Cºƒ6œÐæNmÄ’¹Ë¤ÐCßBT2¼{Ý1îœ(Z(ÅFzõ)Ã+»ø]2j¿våŽ3r¨#[±Ì½(Z¬±bß^ww7,þVÍó=öÏ FÏ¸ÙjOäg:2	›‘M°ÅÙ|NQ¼n‰ED©ÖJúPÚÑGÚÁOþ`Ôa)-Z—cºBïP7p|tkp4Ñ.IÝ¿Sl5­ä&Ÿ&ƒx#ß‡­yKÑêãŒÐßyU qBÂ2pmH2Xå{ûÊGIA93Âªê”xä´ñ%yä‹'Ó‰èâx~~ °“ôŒãóˆgè0QŒó˜cZ¨iáþ¸,Ÿ3‹Òö•oÒSüÔä!¹Æ1b	°QëË‰ €i‹±DV®=ëº™2¼ÊÑ&k¡cÞîmçä–DÅ$õhDiÏužšØ™Ð]©$|]™ýð‚70m2á|],ŠÁ4c§‚€qGq(ypFãê±_=±lYG¥ê˜#Èdô+„@ï€,oD(® Ì†¹]ocÖÏDB0†1
‰u™•#Ú`'æ43>w¹Edªš"—¾‡	Ø´@í¨zUÙßôˆ}€»@|ˆ8”*mdš»F‡÷·Œ6ðÙGÆñ=Žg›iD];q ’À˜=õêÇ#Að&Ñê¶Á›8;Lœ½;Ó¡.ðäeŠ  ÆŽoŒK£Ä``æèåTê„ÔEX%Râ½|'èƒ!qÒX!'o†ºÃkVƒNˆž]àZùˆŽ{¼æ¸åÇ¼a_ zš ­–·iÈèF¨{²RoñP”‰´QNƒ®Û5b5&íb†Åèô“tž£0Û2¤0¦Å‘ã‚m¯zÓHóÑLø\v‡´Gc”°FC‹ ·»G‡ã˜ s`vÁ¬åŒÛÕµh¶áõÆãÇ›¸§‚/šTäˆÕ$¢IU\úäIôÐ ±=‡Ìf<ð#®àóJŽ_†ˆœ¬Ä,aÑÈ¢ âoÇ CòÝx8Sº?å»LHÃð^EÏÔÖq'&‚–\"‰ˆM¤<ò[”E¡Æ;Œ áL(‰f""‹™6H«ñ]õ®™Ev!ëäð8J»’	,•oWÅ%Ý¤ÊÛcªc¦2Øµ÷™23ƒÍÂ¢åØ¤Õ[¯9ûöÎÏÚf‡š+dus)\zb"ŸïgžJÃÂ%Ðn:LA5 6K<–³é$ÁÏAYŠ[7†kd}¤ìýõ’g6×Ùõ$ ãƒ°bèå9L1\d1Fô•&¾=@ŠVO.LÌ¦+ö{Ø¡R8¬ŠzhƒLJÝ9ü…m°\;óŽ+ãs{BÃ8§Íæ›“>QîƒV©öfç½áf!9»»¡\#EäoF­î¢ "è€p8?!›Ž(i…£vÚä›BCØp‰m_ëv¢¿qí9ªs=ýEU´¼cÌØÜ±hŠÞKâ{ÑN1—j5‹ˆ£"è¥]/£X	sE¦¡Í\A¶Åºp‰”Wöú¡°ï Â®'c)Qš,}e@,~I	)íS¬°@”DÛŸÕEÛé}“WfNðÎp%5ïn+¸"0µª,V!ùŽd6ìôt@ƒH#!TflœŠL´³ds„´K"˜ßØXÂŽ'Î‰üáûzR3D_"´C]‘ÍpØi–E™Î$mŒ,€2L&:)Y@ÕÝ9Qo¸ÓF—Q	ì™ˆ®ª¹Úb˜I%Y£UY²ópÜ`Þ	êÚœÄtÅ.xr)RB•g¸ cA=ŠÞ÷m0—ÚZu'Ã+‰Ù[g¦W*ãÜ	T’Ë(S#‹ð6uâç:ÙK»¹”ê.éb“Ô1ÞÆ>;Ô˜"~5tj[”™—'ˆñ/yÂ+ß“LÈx¦%-¯‘RŸ3{a™M hÆA†éâœ¾Ã~xv]Á×¡˜~ós…ëFxçú9ÅîñÝPdú¢Öžp˜ˆ'/ïÈStˆ¿û``mòêë©vë°º1ÄÈ
Êã¯¢ÁˆÆ.†¦/ÒÁ”+Ê†ÀiÒ1!þæ…#µ*à„˜“ žŸ#AcÜ6Ö#µ(¢ÉO2'JmE¾Œ<Ð.TVÍHÈrVÀSœÒüû’ž´#`	ˆ’P—1Òq}1zÙÁÐSB&[ÙòQ”þ§gd}šÓ-‰|ÈÕlìÓê
ÑÎ¦+S@Yqúg†,õ%%c#™VfÀ™ù3¡ÐÂÆÚYÆD(ây¥±\gy•†é)‰¬`æãˆÔmÓ_Î™NŠ˜= mHW£€^ÿ*#XÒ¼È¢õO;-Jht©JúÞp&±ö+1—(wõÅX[	Uw:fÿ™†Î Y‚Ñ@Î š%­M¬pBží¿éœCfjc´ßÖ«Š¸>k{ ‡AuÀý‚ùWWQ8f×­Ó„%§ãÒÊäˆ¥Õ˜S¬3Ž’ÉŽ%vj˜©€:áŒaˆ‘©¥¸ˆnÑ4\LI$“ryŒ2=ÏoËÞ]C2"Ñ£f:«åôÀ!„ßžª:BJš»HñaÊÙ â5‚­—¥‰$œp \÷‰¶”Ó}Æz¿ŒZLT…)É6­UÌƒyÔ*w¨3,8IÔ‘¤b‚XNèÙá®¾ué.dt8V¤GÉ¼¯Ué ].`*+×ò3íTbGqÚé„iflŽbH#èXàK´QŠö+»)ìåÃgj6±#y&Ü¢­ÄÍ¶Õ‹flü¶Xc´yý™!?=Qé ƒJ‹ùœ}^%V-ƒÖKí¬úÜ‹Š#tóûØ¤.ÓCîœ(€ËåLÇìdj`Aeô$1¼#·¡»œì ©fŠ˜óHÄÂÐ }Všh·:“”xãqæoïqÈ•ŠˆìÙ3Äü€ø¢Ýzs®¸ö1av™»’Èåx¾ùË9šH1[]”¨o½Ã˜7üab
g–YHP9Õº˜C†3±[Ãú«®™Aš‘L²Ÿf|®cæëUÙ8ZíÜd%x£Ic²V¨¨%±aD†[gHÉmÎ<k2“]ÍÜ5SòŽ¢h¼<I—ñ_Nÿ2)ÃG'ì/à@`DI%Œ»’H¸DB¡ž/^nGÌm{$0d™$Z­s$ì®÷ØÚ›èŠ)ÁI #ÇùèíR¸nX"08aã/)ßb¸9¼à;pA³qÛ&Ýõ£)Vè¤!¡3í0”¡Š#¡)w0›ÙÈ &ÚÐ1™NÁÏŠÒ¬aYÈFË,‚½å&Ì`¦+Wuc¥á$nõSø½LIð*³PGŽMÈ›„ó +G€‹ÖCöE'”†ÞÅ,HLD#ÁÜS)ûŽ&í!–´?o²Õ ›NÛ“Þ”kRg6ê K“.Ï½ð"¥´EÒ<Âs}ÚÆÍ Ò§¬x¢\-'Å
ÍžªªxˆòòªƒÉÕˆtÅ”³èðž?F„…Êa–9G>ª9·„ŽOÍÙ†\çŠ'A$¤ã6á&×4À³0z”¼DÑtâ“d#rq$ NÇL8ËŽ†FF,E{näz±ä0pŽƒV/@¡Þ¢6Í¨â*ÞÒwšhÒð	ô'éŠ miŒœšì6‹$QcHÏ…2áw9o‡ä]âTô·Nr·˜“!8„i¥Ý¬Š´Ñ‰º¨Ê90ÉXWï£+F/3¾ØÂÖ·ëu"'çE%Ç¶ŠÞç9PÞç3¡Ùl.ò†‡^¡ ›bªb”3lœÄÉ™Å×:”q‹Ó
4—Ä©)§.ÊQfì*âyqj…6Û™ù~<)§i.ÃP’Dw{^-)°J×«™¾X|Ø‡õÜ¬œžœ¦e3ÐÅ®Ír´}>¹¶™	b²8uWÎN”Œ‘žëµ‡~HðVÓZ$³Ú‘qFµ“üªQ4™Æ“+£—lASªÊb©{Óaf¯,ÄÄSJ8Ž‚RÆóöýÛ©äJlG®Ý°­¯fí1<‚?• ’ëÑ6žòé`›D®u’r ØÑñ®
:ÆA!Tö®Ü½•£I9tÍš·‡qJÜ3éf®35 º€,;Ž÷—LÚ’;~ÇŽš5õb†^ä@è]æ‚Ó&=êŽ”Ž®£GDÐ|7,çFHì‡ö¬Ý6cg*²J†®ªBJA=†šã›€¢ 0Ph›@ÔýnDn‘Ë~”‚PÈ¨¢AÏ$RèpfyYÄÉP$­ˆÝÛÐ1sÝŒå"Nt&7•R`t†3í`vcO„±Íª;ã4Ë\@’¢1g/0W˜¹ÎZ&‡œ÷,Ý<|2‰^6>Öeaè2€9*8 ñ•Ëž0äçÄv¥ÞµåLZŸ4UÉ Q Íˆ&¦	†E(ðŽJI~K‹°õ°†Å–u\æ4ÒÕŠóÔ8ð8Ø8rSoÆ%_ºàÞÔÇÎf%‡OTð!@Ê7L">ô3Ž´Ø³!·ZP>î9””ÄštÚÇÄt¸ƒÔHàœ3Â‡ÜìqcP›ù0›¬î:²¼\sœNìë+œyÂ¬6’taéØö|ë,u7‡ÖÄmå¸çx¢w ©ò6žh†Žæ›ÃU%XÐ•JÎQ%áãA!=“çX éi—Ï`fB;«ÊRcp¡Ôà£(]yÂúònt<;œÈ%dsäðÁ >£- °Äâ*äi¯™ÍÛ•xQz)Ã€÷Ðˆ“šl\ê	æ2½kK6Ø@.–`Æð‘OS¬JìXü"d1ù1)?ïŽÂ‡ºÔù{Kó>lo’·5Áe¤“(:õMäÑç±óq.*£“à0ï».Ð¬"ÅÙ
#;&´(#ª.À»EÃ^šË(ü4%úÉ?v$!‰¬I~ñ-ŒyÑ1™X+Æ'¥Ó™µ£&Ÿä©Æ1ÓÆf~OPÇÔAˆcsÜ”Ì–ñ…_öã~æ›I{áÐ(£ËTd Þµ9`óÇÚ·Xˆ¶‰¸ê˜,£žÃs¨y„llÇ;úÎn“ó”bl/OÃJžÇ‰1n-ÍÊðí‰Û5*tq3[´B|u†.éØ^æx†šòKv*Ý%XYll9•jH,*qáµƒW{ÑÞ§ZîJ]Øv-aá€‘‰Á$¶\VÝŒœç1ŠùAa„¡Ð¶àQTms6.E$üd¶ßžKið&^Z‰SÀD/™xf5ò¯üäÎ™7]µ¨OÙæ–Q2o–ôgXk‹¼T`(b›†ãhí9e´§q\¹íDrrÊP)\sØ¤”2ØÅ]Œ_J`N0—Ë%±å³MHf£{ô;äkqÍ&”Ôœ»ìDôè‘É¼µv-\ýÀ.å.‰Ñ£¥{Ì©ölõ„Â ÊÒ’­få¼…l,j…3T%±[ä,/@D§ÎP7)T£3ã@å $Í‚Ðú³9Ê|´ÅË‰vU?Gþ—	K”þÌ ¼{žÖ©çGæñ²Q£ÝF9ìÙ6Þ…$ìÌ¿ë£ á²š[ôÛ€æpY(ÔLžI`s3U)eP@+ N…áú5$xCÈëd:
9ad±C‚ž¢ltüf!!ËÙ?i~GUµB%)ë¶Gn„'­sLDx¬_3Çx° IÔkÈtÅ BƒÆû¨FJœ°?ÂÍû óhæÄˆ­•[99ÐMc@a˜2m(©˜HEµPuàí›Î¹6òMo©<…;«¸°©Fùrþ)«‰L òªhé£ÎŽw³ˆ•P:¸)À˜?
±‡[!ü6ê{l«Á®WNR)ït‰•<$ó»TEœˆ&<LÍHŽ»:®ê¼¨ÈGDþ6€—£„r@Y<ÃäPcePªGz§ª’nÐã‚?‰þÁ{©6ä2U›[%ÀÞË›¶7n žÄ,¹­EÕF®C~e¬aÈ†7WT—´šÞDV‚ÎcÝÛ6%¬{‡n…ÄÀA¢3§Â”ô4“8Êœ¹7Ï¥Ê+³žÐ‹Ç˜Ù#[ÏÏ7á5 z&Åèó´¬Ÿ.Y;.È×:èL%Àh¡ü®¹ø$ã†32†3Š{–?à¯…=æ;rŒ[ÏîJÄ˜Ùdèü•Š¨M‘]fP¡Ó7L4QœMq7×´\1	yäLß]I½˜¸KíP@Õ9ö¦þô'²KSS!/¶ð
´ê¬„ÀHY/{µÄÙãyÿFrÉ
 ?Ö„òŠO´åŽKèÜI78ÂµË|b DÉ.§«èÃ¤S~^F’=ýØL:À7CNå6ÕRŠ)‡äÍ'•Y¢¡qá%YrÒà† xàKÆƒÅ›ˆÉêÐnƒÐ`É9ÀêEK½ÒCn2rjÞ‘~úq™áœóÜ1ÌHNb³åÈwœ½¯+Zòi½’Eð+É¡3ÎÔØá£‡ŒäÂÓª$^!Ëâ °ï¹Ü¤û¢¦ÜÔ’Ošˆ2½“^Ecùb 4øB/Qq*Ãyfœµò£*žtÕ|*sÜ¢}iŒ‰ªÄ­m=Î²*\è…úÌ¦Š ýËC¬¿¤:é€Ô"{ì‰ÏeÆ|ñŸ!ÎbtH·ÆX3Qôâ¡ñdã?ÖøÝˆ‰9q?|T“^¹%¹XóÊú¡ÜÇRœu&£nCj¬xa£ñ9SŽ[ï‹øÛ¬íHbÌcÖY[‰*ÎNÒÜ9H4á"—;WdÂÎ»ìƒ3M09×4À¼Ü¢–Ÿëóká`ûÕ}ªÈØ¥S”ì†¡ 'XÀ¤»l `]=òÄYuËÏ4¨Ïƒ)ŽKN)æÏUÌÔ¹S0ä:cL¨Îùß)©’+L,GþŒ¨z=L¹*¨Íbo#ç)1¡2y“c†&ö™;’"ŸÎ½ÏR¤½ÒbnÿvÇbuÝqz$R–:)t|zËŽ%?ŽYµ•®Ücµ	Üá˜fÆôxÉÂXZæc¼þ”‘Jß)èƒGJ§è*ÁðÙ¹6âGQ—Æ–awm¤ÊR	Ø
gÍTmf#•cRÿxHÙMâõr‹Âa?6ñIN•45u¤ËZê’s	{ÓqE'ÞäTFÜSÆ£KgJÌøœv
ÓyÕbŽlN:ÆÆ‚'ý6ÍlmB{B§(È0a7º£6å÷Ì¯¥-†ã¢]¢T|ÿ»ó8 ÁujN<Õ\µIK®ovDÉÕAAÊª¾~ZÕ’‹çQXÐYqR¸A™KPÝ5GÂƒbÊt/Oä.ä3ÒË#¥ WFB™æ©Îž¨ XNQÒ{¿ìHoIß¼£×ñJ²Å\ª²é b¾ÙÄ
í^•:£(wŸ¦=ÆHc—]FMLÂ«ç* PCNz¶øx§µ£„…ä×0å°êáxÐÅªZ†ë,sÍÏävX¿O„3h•‹€KZP^®¥ltÎv§]Î[Ü–}áªsTî]&>‹0Ø‘¥Ob¦73*«ÅyŸ*þ$™I$WÚ=@ÓH¼S~'ì“óe˜ŠùReS*½'"ë–§‹¦ì\¢!ta©R¬ßáþ.¢$äƒœtYÃTüþÜÂ­=¹Äem+´ÎSÈÝ_AJn`íÂÈ”šëœ«>c¶…yiÒp³Ü²,§œúŠeT`Ôt*pÀ:xR*ŸR›™œê*ºH„ŸFL!€ÀÔJ§2Á˜7©ÏEwo<’¤tn{èœ§“Ü‘#¤)Ë [R:Il]ÁÄTÑ9ê¤¾êb3æ
s@Ÿ#VG–Îm¢*ÏÙðˆ°V(Û(”"(jG	0$ã[Í„)áîxaLå²Å5ÓCÕåHÁ-8R1ÀÔÇÖ¥§ƒk6‹ÈÀŠ‡É‹.\h<3I1ÅyWwEÁ ] 9ÒRRÅIY
îmÖyÆ¬iŸŒ–­ü7YúƒÕMõˆñ8'ˆNá–BÓ€2gîÄï‚š,“Ã Ž."›„!»®ŠaÀlrB«Í0Í$òÊ¤¢pøIu Çd¡™·9Õ \™l7Ì j[Zˆ%\-˜Ît|â‡e|ˆÔ7;8ÊÄx-+ c4SZHgûš±i˜€ÎUWûs-¥‚5”P	]¼ÁÃ³œ›IY\>XœËž^ñ»`Åá©6¥Damæ]U°þÈ8&‘’Ž¯*r«e!ãt\ìfçdqfxÕT|ÉòæëÖ™-êeë-°f`\z’Ñ^l
’ŸŽ:Û
©ùFW^80ªÄ“CÊ«5ƒQ0Yò4A@'¡RbÄšÚ¨AJ©=îH~2}Ð¦œ…WCÊsJm@AzðªRHií_•"Wœ˜/l%W£Ïí/›u³ª.inXµu¼2'Ñ~ºÂîÐŽ×*KrÉ'Ïð©:i‘+ø'ñ<–f’h%yg‘óçb*íÛ5î%.õ—Xx`ÆAG9Å3é–um¶¨¹?‚U}L;Ó<‘¢³%X)8¶ˆ|]®é jÙZ`–ú8¹õ\µ^÷ÕGj?Ãjái:¿¨ëÒ²ŽÛÏœÔ brã©‰ñ‰9í¤êŒ	˜y`ª±iÝLã¦ñêŠKb
ð6£"cê²›9iÜîn¤SOT
[5VkXÜêÄ\cë}ˆ³ût3W7jý-Wï]]©S¦µ}Håì¦T†ÃŽþh»¤$‹ºqÇ¤åë.ÊBnWº¾ Å-ök|C³ß­Yõ“¯mÐŒÆñY*åôÑ²,N“PßÃ™z…Ê\žK@—HÑ'ÅÐSAS·¯‰x)øå]÷ï0£â'yW‘æ‰ˆZràÙ˜¸>]ÇwW¡®=–PÑv©@æ¦Ñxœ=oƒ:"?È¥bÊ)¹®Ž}mtÍ@2]xX2&8zcÜÄœ©sÔüÃcn5£ÆZ3º­–‰÷R4Ñ‚Lç]OñY‰€F¡Ì—HIÞGÂ…ø„–FÞÍ’ŸZz­ÆÜá+9NÆ:Z`ërØZ¯nñ…Ür6¦<™Bñn’¾W‚uÌº“t^­Îµ.ªû·˜]50·5ÊêDcNÛsŠù«Ë˜XœDàŒVð"ùã|ºŠée½¦Ž#Xa÷›È½{)çA4Íº‹3[¥ ÙX É[atÆô´gÝXHûÃ98pø—
Ž=88?ÌÐÖåú°BÒ(Çæ4¯d-¯78JN"Äºx¢d@wèðu&Ô…¹ÔˆubD·gÒä	¸áÊ¨¤< 5Maê¸.ºE2ÅÂ‚&ó+0Éå’ªµA“BÌ/ø'ºr¸
r¸ªˆ[AX¯§¹×‘jàÛ]JÃàLjòÝ9>žWîˆÁ­ªô3B¾"?M	ÖQêÑM`é¦˜gtvÆj»>Fµª7›„lúX§Ÿê(…Bþ'3¾ l|]kÑîŽ°°€@1®ø†EøÍâ	|eUpù÷™Í!}!‰û:ŸAßÏÄ™â§}ùAU‹&7åÃñÑkqÇ(!èúmó»bdT«[fˆÕsñ™¸Ù’éØfçnÞ¿“?”¤ÞŽ¢S—ðÔ²$@§%.¤07æMKp™°A{ñˆ’™ÝFÍ¤†3)½•äpfq¯ZÇ-µ{¢ÕÛæñqóàôõâðPGÇ‡/›ûUuzHß[ÿyÚ:8UG­ãýÝÓÓÖŽzþCÐ<:ÚÛÝn>ßk©½æ[¼9é?·[G§êí«Ö:DðowOZêä´‰/ì¨·Ç»§»/	àöáÑÇ»/_¯÷vZÇtCUz§ÕQóøt·u‚ãx³»ÓrÇ¤*ÍvE½Ý=}uøúÔ>8|@~PÙ=Ø©ªÖ.jýçÑqëä °w÷aÄ-øq÷`{ïõŒ¥ªž„ƒÃSµ·3ƒf§‡Õ {“¶:àï·Ž·_Á×æóÝ½]À^«õb÷ô º Ü5yäÛ¯÷šÇÁÑëã£Ã“VM1
 üx÷ä/
f ˆý×M°0öñ²yìË™s Ë„ÓU?¾FóÞÛñ‚ˆj©Ö‹Ööéî›V[B7'¯÷[‚ï“S 4÷öÔAkÆÛ<þA´ŽßìnŽ[GÍÝcÄÒöáñ1B9<`2Ú¬qr¹	xìé¬eæHA­7H¯öÇ­ÿxsE*Q>• üæËã!Ú¡‰àí.WÏ†bÂ¨Ò+ðƒ%Œ€ÄÕþáÎî\!œíÃƒ7­N+€gK²Íç‡ˆ˜ç0]Œ ±„ë¶ÓÜo¾l8”}rÉvUµ¶wñøè`QupsÅ¥…D5a'¯cð6à&èŸ¹ƒ]´}‰Ríž ;ÍÓ¦¢Ã¿Ï[Øú¸u ˆ¢=ÖÜÞ~}û[à0š“×°wx5p¾´Åww½Éˆn_4w÷^ç	{>"H"@g%¸ÅÉR5ÀÅW»/ «íW²lÊÛÊ?¨W°Ï[Ð¬¹óf—¶£ôƒÜœÀì‚à‘©ïaïÁ+1ž©¸Â«ë1=s"<B¶é÷¦ÈgÚÚýXñ¤Xì€¯peaÉo.<¡ãRœ" J]²tŠ%\ØþgU …—b³c9¦Î å“ x°åÝ‘èÓjgé ÏÏSádV?PG/â3öŸ‰£ƒÙDRïl=Xà#Âwæh!ýLÑ¥Å íóe]K>@—´Î3n ´ŸW|¯S“PÄé\§:µüy ¬Ê 2'‚$÷ú-pio%Öérå´DHdçtÎ1ÉJüešåÎ–V%2’M¸†&îõÉ£nÒ@%.OÿêlV‡èºMtò}þE¼úfU_Ò¶±¾$rÄª˜TŠ3Ðª¯úè”ÑüuNà.ù¡³°‡SÃ›·‡º1hT|Ú‚’ˆœ4{¾¯%ónÄHÿo¦SÕÐ/JL„\Jº·®þFæOÅè44–Å-¢F)uì_ÐÕszSSÛ•®²EÝTˆë{D'½¯k¼9ó¿ŸÑq"ÝÇQ#(¡)N$òÚ3©J¤µ¬Åí%õ=V§{=ˆTß{ÆýžÊ}­:mÃ[î-sß¸·ÈñDÛƒràsCåÅ¹Zr˜yö…ø™­ÃWµSp-Ø<
>~´è7]*Z6µrØyš»«ú^Ð‡tÈgÍ–“«Ò¢=ªÕ5” Ze{bÎÕb‚¥Ÿ–Yñ±«¼æÈ¥x)«xDl	"„yv¸a°™¬«Fa<Â¥k“ÙìgÖÍ,uåœZd—l±cæC¤¾ïO&£­zýòò²vžLkéø¼®Ó=êÏ`@MLÝÃC7ni,"Â¼“üß|õ8Õ¼G?ß8M°jÞŽ0sææ
Ê‘k‡J–õÀu¶T5—Ó—­„ˆñ$=J×¸Ò¤è40†PÝF.vêìÅÂ5rdõ{é÷Ù­wb¹43á´ùüäpïõikï×’yBk*Ë©&W@ £ß/ï×,¸ü~¶¢ƒxy4À~Ø1émo‚À»ÙŠ6ž„'nwûî@ ùèYê_ÐÝHáBen!Ôã£1˜·…þômõîIg¿ ì§R‡=RDL`ÛòLÝu0¤%ÀJÚ®}"Òýåë][ýX®q MÉ× * 0]´Ó“7)C¦\SLµ¤^#Ø×éf4ˆ¿ÚÞ‚ oô‹ÆK”Ó…ö-0¾n¢^X‰+€ir±:^Å†ñMYw¬°bîüxabêþÆá›k%YCÃbU›Í7oÃ&nÜ¤ì9œÃiŒË‡3ÝÜbaÀ$ÜõáÊa#{/µþ!sÎJ8|9Ä±qŠqÌH®õº’Ãv\ö—Îuâ%d0{¦Ì"	:²ù·íQBEqCÊ9\û³x]ê\„KI/À«»uÞ
"dÓÀÆ³¼{˜%…Ý’h–Ô¡7˜=LÇ±0…¦t)FýTétÔ¿ª_ö¯–ÍËƒóÑ ÖŸ°:¿ûgütÓNý¸ÕÜÙoÕ†Ý¯ÔÇÊÊÊæúºÂnnÐ¿+«ü>ë«›Ucmucµ±	7ÕJcmecówjå+ÇûLQ¤ÀP²4šÛšõzs~çÉ(óï?Éçž:|½ƒ¿EÁ)^öÜE™ˆör«Ó7;Ëð{+¹ø?ÿÏÿGÜR.å$W(ÝpIJ•¹mÌî@ŽšDÉEjÇi‘‚Àð}íP1-Ðùl”Ð*€5¶`T;±ìÃ NÖµŸpzØÉáîŽ72ÂÆœÄ„É@'žLuè”í†+]/àmœ1úðÓÆ\ æêI–É|l§KCàyÁlüÑâ1ÍP¢£ný@àÛz§34)T	ÝšÂ·0{hÜÑhôðÌzËÉ~U7·«ÔèåËÊPõ"äÎÙdÚëÙx[œ˜R Þ‘2JŒ¤ÕœI€z ‰æ¤šKúÍÏSIÆ|ð vaPµ¬ÿà ¥ªoóNzñùT
QÉ…“lXM“NŸÝ1Ö€©‘´ãº)ˆLnèÐZ$ã00ÇsjìKä¥Ð°ã"³Ïïsõº<á*è”›ÃÍšÀú\5¼ ?÷9$
&±4äUÙ‹“éõfÿÿüßÿ/Œ
Ç¸“vÞs•¹ˆ“QŽÃlÔŽðÆ”£›òºÑÓTŸ?ƒ@»ªŸLÆÑ¤Ó§þ]ÅÏï¥îm4‡`•îÝe2å–Ëæm€zt
öØä´ÁF}]–Ì¢Náj":Îä'\ÖÖ ÂÃ‘¥¿²Ê` ë(õöúEýðzÁ@ÿö·¿áðƒ”ð÷ï në¿ëêGø÷¬ÓÍ¢ŸT}ºÒ¨ó•¢õbgj¹¬®4.7Ëµ³ÆúÖê£­G
cÇ§[x‹0;&J^]”8­Z©5¤ðÆ,h»/Õ% bj-Ÿ*2³ã´î!Ö]ûòëŒ¯“.äÇåþÅOðß¶úþ¶í^ëìyó¤õì'5ž‚7bóÆîÌø`Û¼úãòÐüöêpßyþž¿ÞïÛy}$çvtÃ(–û¥:úÐœÕ"é]CÔšÏ£¥›À]Ì'÷Jãa}CÃï&h9œºÐœçjGsššÚGGL'ŸSÅ‹›tsººéc™pØo¼Ð·ùñ¦¹¤zårÁ¹h`ÎD»Q/ÄèÞ‚þu©vS]îC e]Ph ¼‹Ì%Á—tŸžÀ
üÚªOhP¶@‡ŒL—ë©BÎ{0>Óè¼Æ)ÕÝÎnBD“ÚñîAãÈMÉ‘LFM£;„®|¤#¾êôÃRå¦Köå=¶ÃÎûé(+ë“º¹Ó˜;õ¹ÇÜN‰oÑ=›%ÝšoÜåeÜé†ÙŠ°/'ºú0îv®ú}L>ÝKÏINn©úd8*È¸AzŽB2¼Â™’¢ç”n½‹G
¢þ=~Ï>þâòÏ¼·Ü~ð@×¼—œÖæ$C3‹Ö‘áínùÛPr?P‹ZãÜT_Ü´„OhÜ„K€CmÈÞ`ï
Síðj©~ŠRM•iQr¾Y©ƒöQçÇ¢^ðH´‚Áúc©†qR$™qáQ—`áb?Z^Y]nlž5V¶6Ö·V6>MiÔVj+Z#¹“Þ?A™ùòž.¤ãi\„ƒi”Í}ãu¦Ó¢l”éö°9*åj›s!¹¢Ú|žæq0„–îçÓ@ì¾œ¢QÇm:ïÝÖéöÙöáñÝ×)ˆ[j¾Ø¬Üô®ãÅwo|ÏNŸ†íßÁÊSÔ$#o±~†c{o3¾î¼Þ>‰]±ÿ PnÍ[JUï/«µÕZ£¶V[¹àûoàwøÏÍ7ÍÜxp6®ÿ6aýçîûFíQmå¬±¹:ÒÉöñîÑéÙ‹ÿ8(RÞl:¤È5d(°ZÖŽûÚ6Û­ÃB¦˜Ï0;ãé§ìqktÜÛíîò·nÚŠeo¹Ágt|ón*ïû¨üÅÛ1€ç{›Ý÷œÆ
ç‹6ÀjÀm^êœ„m:¥HÕ2Ì¼¿Ý‹èÕÂþämýõS@ÔÎvZ/š¯÷NÏ\H¹§7l} Bžt¢•GŠè”“èÍuú*=|7
nIý$ú€¾R÷	Só„ycº`\’ËDYk­óL(! º¯ÓøÝ³(q4/çaþû_Kç=†ÕÑæâv=€]Y°<à€‡bÿtãžûFd¿v€ÁÔºî“ªg@ˆMPz>N1]ÅoÞ!J.yÂÿœ#;Ù¯®f@‚	Gã?Ä_²3xškR»6÷»f°ãl”û Ù*ü/°Àz·–€%Äa›Q|†µ$jø`.%G¬¤Ãú¥C*L}ëy¢_œà›¡¾¤“Ž#Èl%©H`óºÃM•ëMì;Vˆ‘•-}.RJsCý<hŽ²ûi 8Š	Š=Uøí’Ož¢¹}Óá¢4ƒA§jQ›O‘¾ÓÕ/Kî©í~ÔyoQB¹‘Ø™:Çüª²ðQ7»®€Q©¨ŸžÐ±µ@)j±ÜÃF¨¹\×kº­ÛJ©ZYø%H’LÔé§ªÒ:>><DntŒtÐ˜JßìÅüfÒe‹ïÊ!:ãàD@ÿÅGO+5åL¡¾ðQ3)|¶w¸ÝÜ£_ÎšØ‰ÇM+Ø`ºîûàó¡Î¿fî|ý‰P†Y)Þkýtéf~›WÊxpÕ[ªÝk
Í”û8‹0 •ÚÅìý8Õ‡…¸³I4’²Ÿ±U ýhÇÆ¥ü=PW5ý'+®jêÏØV…¢¹E1¸91"ü»ÍijŒ{UÓ©òÀuP|é6	”ÝswŠ$ÃšÆó¶í½m>kë|êæY¤"Éj™Ó³49/Ý°KnzIçÞ=¼¡Ñq!®›ãN?žDS‚çWÆ¯ñ@‡´ÐÙ…Ñp{Ìë¸*ö\‰cÌDT§_7‘
 âãr½h˜xž»ó"–›Û3S¥B_Ä.îH{¸)3®ÄV…u9w‚ªž³¶†	5ìÄ›à¦I¹[†É[ã)ß1gª€¸°pŽÖ#dg^tsæ¾ãµ£´M§xÍwù]‹›¹.DÌTw®Îm³åØñ†‹­ª=¸UÅú.]„€'æ0ÉÛPÐˆöž¡õ‚šS‰=³§ØK—pEaayjAðP¹Ï/j'bÖ‚mñ4\.~Ô/ù'ØÐ²o¢NA4!|1h˜t"bÅâ’cÜn¡0'‰zâÍØ¾B0`ëý5õýÌ®¬Ñ„ÄìÊÍ\žF*›IÝÛÞšJ…¦1ßAšQœGoà½æ=®JH†ÿ>9ÙS¦Þ×8²i'dþÈ€x žJY‚U)[aª«'Êœ=²™a^‹òè²ãÔ	gu§r÷„u†êœä´úú¯ÐÏ7¡RÊ\,‹’þ»5µ—ÚÒq…i@ûã„D©¦ÓñU^~bí`b†’žšÇ`µcÕ[\²=tŠÇÝÌÑŸžGq9»²°†ôÓ]M€•wL_°lÎ ý™µðüÀäÃc/1t4ÜúÑ`¤ûK¶r76§˜z‡4xNí'x³ -ï¡ÐH›&Ab)¶
sËÃ.]µšõ3s«Ï€¤ûùX†‹ ×`[·8N±K†ù…ÇßHõe€™~Y_µòÀpÍêÍdEii¬=uõ¥—¤hj\Sûx¢†“³‡|ê7ÁcûÌu_€)+éH/Ñ:ˆäª;KÕKz"áÔ:x£ÞhaœcÔM¢!óõ(œÌÉú(k3–‹»R¡§æ4ý´FÜºvƒÈUµÐé¦m3ç~Í‡ÜJg]A¦B&üŠ	bs×e1)“ÔC÷ë—tíÏ±¨‰VO¹bhH…¡Ar»ˆ¨™áBE³0Ó¨ÎäÜá¡ê¦Ù©Ö$H­ò”ØªçZrõ]Y¾N**:%èOa«‘>Cz·So0fXwZª‹žc•S£îåSOh Z†¹øÈÕKm0K–<QÜÀÇ¬÷5'œË¾¨Yî/Qƒ;-Ýgh5 o4ÜºyZxçD20T§Dù³.òÛ9rwzÄñÎžµã+Ô‚ÁÀvˆ—uã­´&zŠ8ŽÎ™í+«Ùñ
[ðGñb±Jh"t:é ³†ë®Ò¬ñR§:È"}» à;wŠ?¸úË;Å6~W³?åëA]Áö¸±+}STÙü>«S!Ý²wöhWø\¥Ô8ÞÛÙ}AÄ‰hÓ“i_øüá9‘ÛÏmîŠ t¨Cè[ ÎîÔIy*ãB0û}°}aãmFú æÓhÀ«µ5Biˆ¸tÞeQãõõÜ;†ß™©ê*Ã÷¼$šnÜ¦‰Æ®D)É)+Žl†DñLOÔæÒnXWö”ÒÂ<Q+¹b|M=Ù§4‚ÃýæîA	Žçî6¾<öNF0ûó‹Vƒõ×[|´NH®ª‰§ÖæS5ô"	ŠûL}~		Ô½qj¦³«ûyå95h»ec€Žf	ï§²áÖá‰Ç~Ñþ¡Ù¹’ùÎKÅ8w>¸¹sàäŽ*¾—Þ®g2ZÞXÅhúíïÉ-á	ÖÖÄyT™•JVmPnðîFÏÿ4ÝALn4¡­î«OØ¼p¶·{rêØ‹Ù¸ò“]'á{0æÉŒ/Ÿ6Ÿ3 £·;g/v÷Êtš#})¸1Uõõ,Ð…ZÏ¸®û+>ºìÖ&ÈYà6Ò¹ÿÃãÓBßÜ¿×¹¾œIˆç†f qzÖ|@Ö§v3¸ãÖÑMãÊ{ânŠŽ¼€_ß<`²Še˜“¶n:¿RÒDöU“MwÜ)ž¥œƒûëïgâkòG#é8ÎQ½m¸uoÎ–T‰¯{5Â§´œ“>âÂ¸~—_É‰]S7›¡B*ú‘n¯„é§ÙWUFQ¶ÙÍÇ`Çåx'°.qŒv7¹òÄ{É÷òó)9ª³"5rb•öœBÛìt+Q˜a™~©ÕBeP\áIÄÊÅH0xF'¼ÜŒŸL}¯9Å3àX·7’|Tµ®´Kªûé˜Åv9	Ã2Qgø-|¡P)Èåž®Vísº—€ZêÆ Ñ-Fã1960g€âßnSÎ:bõh&`üív ]2tý~Î ßÛ˜]ƒžGËøXÚíA-“ÏMà§30‚à§–Â± çò±¼â¼ <wDˆq:"þ–Ž¢Dô	‡éÎä ¿˜½e wdHÎ©_}ÎAêna+áo¯ÒáÐ/¦	ö¢0œ|)t÷¿ÿ—eà7°ëÛ2éBÔ®È¤µœ´²ðý^ëàåé«g2}úí²½4H™ÆX8$9g6l³i¬Ðu#aˆ wU"îj§V¦k€ê(ü;äl*°)ô‘£ÂÀà.Qr>éÛ»¤C)¸©o^2UG--âúÿíoó&ûÈ¥)ê‘íÎ‚fôLÎØ£xFQKgþ÷ÿ:OûúÏ—‘®îífm¸ÙÚÄ[]z®™8ŽX$¿ó‘!Œrø(“NæAiS€¬>XŽghù4O‰e5ÿd_±…(•ìø†^í@=°^=Àì¾=x@®ÝŸÓ89ƒu*Ûpv\%0ñEªlOu€†|WŠ¤J*Ø7éÍ,Å~8øÔ3×­…NL$iëé8Ž’à™BºÃÕRã¤,~†(ð#eBöLÓNtL·.(¤Œ¥hC&ã·lÔ,öl.b’Ø›,"÷"‡nÐïlObÛÂú‡4J\ÒE£yA¥YÍyò1T# H€šb)’Ë›øú¤SÓÝ—zDP–àÙf¯ûé¨Ne,=çù&SÅP²ÓÐ€1¦ïwvÏèŸUÍç¨&z ÀI#o>@¼F‹%#¥Á•¤&¸¼æd966[,Ê°%cÜ•íÕšjrÚ¡™äÈT;I˜‘ÎV…ÚÍ2<a%I$C)c¯==G=¡a8± ˆÖð,D”áSú—këÛÍLUÝJ®qQ?¾„§íûÇ[¾0±Æ-bœl«^G’¬S#ØQÃ:)Š gëT i™ÞÊêK[Að@ýØÒyùüØBq ¤Qb[©sÓ%|=›¶±bÖ\¤§Ÿð~^Z"Äéiº„tbçD[/oNE¥‹µÚJÍ\“¶)]Ë/ÐfªéM¸ÌZ6«„“-ô[—}1LÚ¯‰Zõµú˜_ÿgee½±*õ6ÖWV6°þÏêÚú·ú?¿Æ'0îqÄ<æC+ê{n)¸¢ü“O`µÝfÿRNƒï…X¤â±rÙ98Î—ÂÎo½¿Í‡ö¿`¼–õÃ¯ÑÇûcæê=|¸òmÿÿŸÇí‡½µGÝÕhce³ýh5êtÖ7+áãîÃ‡ë®„íÕ‡a¸¢þT«ÏmF0zÜí<Šº½•µnÔë…½ÇÝÇÝ Û›í•ÎãÐ}Ûž5kllnö¢Íöz/‚æG×£ÞÃµ(z´ºÖh<Ž6ÖÖ7W»oÛsië«a§ÑhôVÖ×Ö{›{W»ÑÃÕ|cýQ»ÝXë=Œ:ÎÛr>bscuíQØy´Ñ¯m´;Qgce­½Òé<nl¬uº+Ö:Þã•u|³ô€Q¯Ñ^Ymwz«•ÕG½‡íGp-ll®õV!ÛëíÇC@Â# ¿»¹¾ò¸Û~¸²ùp¶²ºÚí®®­¶7:«ëˆÉÍÕ‡+µ0‰˜ëÜ9÷øÑÊ£Íõ‡«mèºÑë5`úÝ‡[×º½hµSXé…"ž¢[y¼®=zôµÂ¸ëÆFc#Š†+ÝÆúfïñæÆ£žóZþÄÝ#Äøjøh»ÑXÛ|>\i<ô=~üx=Zk¬?^ÝXˆ n:OÖÙÜh¬¶õ¢ÇQûq¸¶ÙxÜy®­†«ÑZ·ÛZìõ`q|XåGâ>eEGáüµ]Yëu:+Ðñj§»¶¾¶5íGáÊúÃÍ‡í•G£°±Òíu®A¹'ñ¢ÍµG0‰ÎJçQg¥oüÿí}ëvÛ8Òàþ]ãwÀ(™qÒcJ$u³Õ£þF±´'ŽíÏ²“¾$G‡"!™±DjHÊŽ=}š}Œý÷½ØV 	R”å‹$Çibf2X(Ü
@P«Q­j0_u˜­ÞP)''Î¬ñ¶Ô`iQæEÛ¬[[[æºÖ«ÁÐ×65­¾UÛÒÔª¥[X$Û¿»P\öàÜ“ö¦Ý•
§¤é±^×˜i«R«V{FÏªÂÒR¢zUí×ú°»˜0`F-Ù´	$s¿WÕõ­~uËìéVkzKÛÒU•6¶*õF_Õ¬ÔÜK¦›ú¦®Ö**ìf¶Í^¿Û*ü[Uk›ËÀÝþÛH­¤Ý)l\•z]íW½†fmö4ØÐ€C®ÖêŠÚkÐ­^_335éiËÒJÃ2ë°&­žiT{›–‹c«¢Õu¨WÛªÐºU¯Ñ^º+Ì€UÕºÂ†5¢³‚^©S£=ÚR7{´olUû= sUµ4 t½Þ¯×T‹Rš²¢ô\7è¢ùß`ï }}S«ÁÑSk½ªY7u‹nÁP7ª–'ÒVF «Ê6”®ì÷ZZ1kFÝ¨šµ¾V‡Ñª5z°
5Ï½Q©Õ`v¦ÙïgãÔ»‘·šDÿaØÌ-ªÂÎ·µYÕz^­W‡ÇªBÃ7aˆi¥¢Q-Ml7be# '_C3ªz¥¡WM«^í÷01}«¦õ(rLQëÍšªJ—_›uQý°ëöûxó„ÍµŒ
®ZÃ¶§ZÀ`)ÒþV­®ÂrU¾µ©6Ô­» eí¥ÕJ]¯`ka¶ê*l õ
l¼ýl·=XýÆ–fXÕ©UÂk•®ôüÑ¾¾‹lqÍ‚4tÕìCs'1úzuŽÙFÃÐ°3†jT*Õ­ú­	Œq	ÀPTú–Ñ€+*l|›ª®Â9U3=±¬µª@ÉÙ£6ä¦°# ­Ò-Ø;-µZ³*ƒÑ º7­^ÅªmêÖf£ge÷\Ïì¹Îæjs³fÐ^Õêm™[5ÓÚ´z}hçfeË4+µFu«V®¦–½´4µË}âÉø«ÑWaGÖû´gBWq¡Qµ²	ü]ckKÃ]vÜÍÍôNrÃx²=G³¦õ©º©k°7šµÍ:Ò?5L8]L8zT7ÕÚ]–ç-êzµgZ25(í«ªiiš;°Ù7`Üë›`KUvL¡Ô²¿·½{ÐÙ-T`Ð`ÌaKìÃ‰dê›¦ÞèoU€	°à
´
Ì4µ´^X.vQ ÖÔFQ–Bµ¢Ãn5:²¯pä×ûx„%Ã{’ïITÄ³pÙu ÜW«Í¾ÿAy	å?­Ú Æ²òlÙ•ÿEjËn¦?¹ü—Å/ºŽ9òµ¦‡ò?ð8ºó„Ëÿ«HÏþÂ„ãsfŽ¾˜›4~öŒ<ß³šäùÂÑFnÊÛ^/Œ´¾ÃC5±'¿‘Žxæxñj§óÊt:@_Å~à¾O‰¾µA€åÔÉ8‚ž76HçÒ®©‡®ÇÞhTH,ñÔœ2Ë„ïm‰D|ïÀ];äÝ¶’.õ_¢«È+ñØbðVJïZv•~¾oøÁ6¿7}uÅg`ƒR ~à ,n-2ið;šx[’cbV;ÂâVÖ“Ã»pê‡5JFÂÌ2ßê4ˆ­ù²`…šsNd¡C€] Œó/§ÑoÃ›£}¥RRÿ¾ð©}‡1˜lja-è¨€bT·€GîÅN@ßccüÂ,–fá÷Ý~™¿Júo¬zZK¹œ¹/¶W™„1bQœùxmédImnu:™gfgÉ0lÂÁ¹ˆÇX!{è‘À£ü=Ý.FÅ#ïE¬ÃÜç‘G0Ð=¢‹nüBÀ	A»Äë<	ß`C¢fÚ)$"
´eIöRÍ,žÃÇÂo®w·¿ßÝ>íœ¾Ûû­Í#^>ãPGap¸¤•jbLà´ÓKáSƒ½{Â„ÀFÂæ,íöŽáœ²8”p¢ÎàM¥EÈ’ö"Jê¤sÏ­!×ŸòáêGØ’&¥¦%Ô+3Û7m, uX¶û°
ù8…c<iV$3Ž; L¢ä³XF-ù¼j,ËðMÛôHøÐ‚‡éx0Ði×¦²ã„íXªÎ¤ï t”ˆø¦=”Êøó4SF7¢EOŠÏâ—íB“Õp®.¼GÃ¨JÉ½ED}/-|7ýGæ"ÿé)É‡©+ç¥Ôq3ÿ¯iUMùÿjƒ½ÿUõœÿ_EZÿ¿4	à‰Ê ³¤€§- $]j½nC¯_LÝ‘ÙÎrËø)T€Û“ŽïiIBphNÄ°Pï/í®%ý)|\À§\ˆXLsÙÜö[r[Þ½2\œWN`|áƒü¾}Üzþ‘Þp®z@Ž:ZkýãäŸÏš/ËäwîZ/d;¿~"ë!¤iµàkÌR}¿­d9n“$ôZ’Ï¾8{(²™aÂ×ÛÔd÷ÒU¥PÚf€»å‹­T%Ø³LX	`8ZÆn/nrªEFú“pG- €ëhI*´a6 ‡ì²Ù îÌnV/ÆŒÛ‡¯o; |&ÞÜ®Ë’±³wMo$X|2‚_N‘”Œ`÷fÁ60ÕžB€Î"S‹J¼cz¾$K^Ÿó¡]xÑ©x,£E+Ìº´R‹–oö_®®[ëìO…p*9ëK8HMaµ8e…‡Bg(û˜M3Š“™ú~-€äŠàÉXü¹öâÊ%Ž„Ú@–ëÐ‚ð_™4«l­›‘Wöÿ!þ™áOFD1IZÍŽè?•-zQv&Ãá4S.H±IßÿÀÃ¬è—›äu{owçy¹å=‡\Sýfw§\ü‘0Ï—%¢°€À}òñùQlfÆP”k+’/‰2öl'Pÿøbx˜}5jÝX4àõ—‹þtCÿ0áU¬ÿ"J_—›ÑÞÙáøú‡¤§L M¢œkš(¿ú3ƒ!¸î“roYB?hÁàš('@©?
¿£ÂizR4ÒYå:£Àr|¼î"ùfI!ñà¯‹ÉÄý<žÁÔž.õfBñZcÐ³RÚÓã¯v&¢
Ø×3€Ò[™6^ÞŒ7¼šù bŠ2qãÒ(ÊP¸£OCAn
7øi(È•¡¦!¤¯n/9¬‰³|hDd=¬(¡Y$aËA&Û(e+bE	<ØZÛÃ!ü	ý²vHÑtZ±Ë”wÌàÒ+Šï¡M?ãw#ûã¸ž­È06Vv
žî…ÂDFax,¢?>é3;©3Ï_„¾¼¹;a‹¤¹‰ŽÜhH.MÊº.ú6æŸØ‘ercDüñ…WhÀfK­õ¡¡‰J?@ãLwèz-c¸@k}]4íï·Ov[Û!ùƒñ¶P6T/úSVtæE}z¼	ÃÀ‹²|ž•Õ(Àqd`¸hÌë]a\Ÿw”OìzìÑx2æ&ã83°×„Â€¶¦Þ¼ËÜh:.NïVœ™GKÅ¦î†@"å‹7±=µ„â¼µž0f~¤%Ë*ŸŒ·1ðÚ02¼«°YS„#ôO¦Y˜"k¨üHþ¼ÌÇ¬þÂv[ëvbJ©°Q<ö=Üc¥l5ßÅÖ1Gÿ£¢Uôøþ·‚úµJ%·ÿXIÊï÷þ7¡\ÿ]^Ë&û7Ü§¯‚eWYùup~¼¼ëà[]/>Þõ!Ï¸“	œ_æbáñ0±Û‡¥$×Nx/óØ'[žn“bË¬åÕ1×þ_¯¤ô¿õêçüßòÓ3vÀJÁm¸†Ñx´ÝØu*ò.øAX„ôf‚™)³åVEn›Ýu…¹5‘{,Ý…ßêb:›™dIYDØr¸‡ÿìtvw#6…gwÝéHÁ‚~7µÊæVS«WêÍ*¤ææü¼.Q0Û°r±uÌYÿzC«ÆòŸŠë¿Z×jùú_EÊõÿEÿ?mÈüT%¿ Ù‚ZnðØÒÚ‚eµÕHj…_ßŽèÅ;¶{øz1Hï³ÿcøìEŸ)étûÏºªåöŸ«H±…öòê¸ûüWT­žÏÿ*RÊKÏRê¸Çü7Ðÿ_>ÿËOI¯8Ë©ãó_käûÿJÒ”£%Ôq÷ù¯êùù¿š4ÃÕBë˜sÿ£©0çÉù¯UkùýïJÒ³¤Q4J$¡'ú(­c‘~9Áî“ßñèÿp‚ñLòéGw
ÿ»gú6¢:õ¹ººÉÔÕåçXDŠ#±¡îgŒüBá¨}òsë9þÛ|ÎB]•"El‘ÁÞâB;€cŠñgÔ<­šyüƒyXlÈy»‹’Žw‘´H±µž°g Äº¢°ê2!¥,øB‡>e \sy÷øøðßÆC“vÖ¦Ì’0X|¼BË©Ð‡=ŸƒX»ðjêEÄã»Çý’½0·ðŸëî;O	þ_ò ¸Ø:î~þ×ôªšŸÿ«HSÚ–PÇ}ø¿zÎÿ­$ÝÎ÷çÃê˜ÃÿUÕz¤ÿÙP«QuU¯äï+I½Ï^‹^ýÖ{Q¾vŸw¿µ{<ü-¡Ý‰§¿ÌÕµö°ç¿µ¹ïk·x \»åàZú	Ç|'×“¡´r8¤±D¼B®>r½–z\»ûkÞÚ¬ç¼%L™ü ·¶è½…·—!OQµîŒœ–íqk3õå7ËÅ°jaUþ€¾pÑI%M;KDs7_ÍbXdJO‘43µ£Ó1{±@˜Ãý|Ø99h¿KÂÅx1¾©¼ä~MÀ$C×†0˜›‚K„áà¸Aj¹³wü®}®•çÆP(ïíLAñÜ¯l“fª¸æðŠOQ>ÿ¸2ª¢˜°‰?ÃY9Â¸ZÅYZ¢Å=ãU FÅ­KM˜Eå¹!3M Å·¡eŒ˜it9ß—>°‘?2ëËm×q˜Æ™ÅÇ9„Ã0´…Ê	»N »ÈƒÄvè°ß±µ¶©àµ âæp'U>_Œ”P‹B|·O\wèÏ†r\eì¹£±”qä¹c¬Žú8Žá]ØóZ~Eð]¥[;ê@søÿF]üÿ64 þ?×ÿ]QÊùÿÕòÿ3V×Ó~›ø®‡¶‰A7¡ch‚å‘þþ±l:K
€ùdgï5ðÑÓÿ3ÏˆyB¤Èé@ŒIætÒ§Ni-m5öŠÚð?ËðúäÜp†Õ`L ÷Èp&ê˜‡¶°á˜$—Ô³8¢\&Y`{—0 
Z}ã“cÚ0çõÍ3XÜ½	H¤ía­;„âÆ âhL’îÔSND™ÔÌ—G¨I±IÐÉ(À±8R€:˜"6`«|A@ã1åï.Ðï’ÚÐWVÛ! ¨]Ùs,ú…`ôò‘KØÚ%ö]ì, ¾€Ù;ñ(F8O•Zèx[°ÐM§÷ü}Œ{çÀÇ¿¹ÚîZÁí}Öy{›khŒ‡Þàˆz¾ë¤¾³2wœÊ±|Åì˜H XŽ‚K>ázÃž]aX×D’šä?ÎÏíš¦=9zù÷ÎÅÄ¶ÌÓŸú-¿¢Ù§GÃ[—o¬_Úæø¼|v~yñÛëÁ•ÕþåçÃÝ³½÷çÇûÆw/Œ÷CÕÛ~s}}ù¶|d;µjý}Ç¿yUþm× {ÿýZÁtšMú‰_¢3¡Ó[Êœ?(©‘e`cØËm$_eš&A†ƒ¢†tÂ€`ç)C×=Î<w28Sà·4IøÀ·¯iòËÀ¾ ÎÃ‹þ«õ›ÈS6´B:p¬Äâz )-qéc‹óµŸ½öÓ¥œàz2`ð¯à@3Ï{ ÅPŒÎ¿Âç9»Æ$œ©'ºm¼ýåó^Y;|ónüîïo?üò3½œ¼ýB{ƒÆ¿~ýõ×àºñ›Óø|ÕßÙ=;íý<üåÃ¿ÚïÿÛñ/?ÿý_šC»û›—oŽÎ¿4Ž¯¶^”·ËïÊŸë£¿=Øü·~¬òmcÓ³ŸüyãÆ‘„›±æçnÒ¦pš@˜ÞŠð‚áðŠìi6ŸUX5ëF€KÖE6úÒ£ÐGîSïf"£3Ñº¤Rs8£)¸ä‡Šˆžƒ~êÿÊ1g|¶ÑÃ^á•Ù`ŸG_ÇìþÕìï³‡¿Þ0^(3(\æ ÎçfŒŸ¼š9P¡c/m:EœÁÙÉl(~ÓÅfÍ˜ÕãŸMË½Ì&ÄìCq
çhÜ0GFú€‹Hýá'Üwr¥vËŠªcÎýO­¢«Òû¯Ž÷?Õüþg5IØ¢ÖÞ·ü2(ÕîäePæR{ÚWAXÞfÁpl\â)X\ …ž‹97{:PdßKä7q¬ˆgŸâg8m¼–aŒvß0Þ“~ôÜÌœÂJx}ä”§€ãM…fMð°·Iù+õ’n„XÜñzõ`ãSFÂl}w\2éáº|q‡‘Â¹ëyô< Ê¨†ÈÆ;Á3&Ù1ªé0…ÄgLüs_Š]–È›‰MLÔ²P<ÜÀÛDŸ! ùc”«#‚‹ª"Œ˜>àµfÔ¢ÇK,l=(&i:‡Îº¶Q±"\J¥ÅOJè)v¦Û*–Ýq ÂE§@ðq·ULùvÁš˜.M/é%­$/—•ž‡ñâÃ²²¿ñW×LÏñi‡è3d6/
•BÒÅwý¯R;ÃçlÏþÌB*Õô„‹þy%ÑëqÝŠ$?´ÐçH
¶ÓÙo¡’TöñîQ]’Ä¬Û_À
¹×í‡†‹ŠVw_Ÿ|hï¦§ÏwûF·*_Ä´Qž*ÕÅ8UP4üýµŒ±©2à^¿û ë.3 NÞï$ ‚«v=ri³ï€®œÐÊößAÁä ”šE&Wh	m‹H;Fzüç¶¡h|»ûkçäðx÷Ž¤÷ùÜŸBq4íÇl6†ÒXjýÁÞö[\­bøWÜ]ÄZ„¢>ýìúA\9ªÈh-¦)£¹:ÏÕ“¹ž[)ÊâP÷Ãi2×N¸kºe„îI€óôõzüþ_«ó÷ÿz.ÿ­"å"ßjE¾«ëi}BëÿÏÿãÏ+í‰ŸyÈËâß+# îüm"ì'Jv¦f€À:4¨ÄùÌ‰Pö0â'™ðIL¤þ†,`M‹¢C¼^&Üõ‘ñŸ0|®H¡3†¾è
-	AdÈdHàé!»k!0½:®é¡Ù°N>-ÔÞGT€F’dlÀI%|}Éè±“Í3‰€Ö"q´a,·VÀÀU{ofâCr,ÆØäˆÛÙø„zvHØÕÐŽÔ³#„ß§†ö5¯CúHB…¹1\<ó2\œËµ´9lÛ²«ÌpvØSG‘)qÏt`\F=hþæsmêq†&uÚbZƒ{*¨E¦ö¶Ð]Ææ‹$]0"9&IBK¼ÖÏëf´¿ß­“i}ïvuJ/û‚z=8.ÃŸQÀH¿ND*Ô§g~iN·äÿ¤<‡ÿ×+•XÿW­ þ¯¦×ó÷Ÿ•¤œÿÿøÿ§¯ÌÏ ²+tŸñOkÿ’s™ï¿³.ðÁ)×~ºÐ]
µ2x…èß»I8S²„C.¿¼Eš>ÿ+]¾ º¨Õvhº œkÿ_Ó¤û?ÏM«æçÿ*R~þ¯úüÏ^]Oýø—. ÑUï–Ð ‰Ó°®ìã_`ƒk<¬Ã„¹ c—xø‚¢õSÇþŽ;þ‰©Arf¢DÚ?C¼¬lœËª¸„ÓÚ9àjŠ4È¯èÙÞüŠnµWt‡b…à.Ã‡½Ï£¦,ïºî¶W]óp¸l7¶xÞUî#ŠåÇaP¢1áûÃ<ò.¹>0‡‹¾ò Iìª&ly|—ÃÔÔ÷v˜F?³~ˆ\ØýðÎ(ëº«ƒ;Ï»DŸ¿å<-/Ý–ÿÈàþÚÿ›®Uµüý%ijþµJW
÷Ý5,«‹ç•H€óôÿõFìÿMÓ™üW©åòßJRôiEAŸnXWýæJ~·ün)÷Íû¸ë7~óË¥=ÛïœK¨Ÿv¹£”]îkÑ”xw‰k–Àµð¹|j1ž&jÝZÒÁŒÔENw|`w„7mŽWZB³˜»Ê/·Ô6¸¥²¦Mé°ÜªJ&L%nÕ:·VYw¦qanv³bÃ­„¸‚€¢Ó“†K"ö¢Ö÷ÜyÎ+pù_(>ç‰_F(êøXàoýZˆŽ?ïÃOi|Â‡}Hšw¨˜ñ¤¯¥ßô5Ÿ+Þ>ZÏD­ßˆZÏ@-uæHj1Nº‰3'•V“–UF¿¹ŒÎÊvñà÷w§ ©ŸsvÞ"–}ƒ’ƒ¤¿ «:L{Ÿé@Äü³¯o¢\Ñ||%ª(Þ…¤jBrèpGø	šó¤ÙÁw¨ØŽØ^äÉN|HœØh“C;`±à­‡ö§@0ñ‰rT4N‘oFƒÝâ…ÞHäI·òÿ·\ûï†Þôÿ+µÜþ{…)ÿ{tÿßÛã_Ò¸;›º£ŽÿW‰÷ÕðÏ@·TýþüýpíÍßox?NC²-åÑ¬®-e^÷¨Ýé|8<ÞùÆ²Z+ð:`ãq³Qà÷Ë3¬X<ú#±\ž‡Éo=Ü%)[ô¢<ñpÈ HË$Å¶ò›¡\«ÊV2ûîÐ"Ê%ÑTøqFa‡h/cdØÖß¡¥Ï|J”l’¿ýæÇ/’V‹üð; ûôC2§³ 2È"ŸÝ“€y×`Ÿ€•¼cK#™èhÉ³Òú‰ ¾dÑìçqFùº·Åqc¼¯iü°ºB÷à¶3€¥'ÕÕ·ùß–ëˆ
8â®¢Œÿ:d–ýäÔaË_RÌè0'L°‹Iô/·)<ÜRH-¤9€µÿ$áo³Íˆ"O;»Ç_ÉŒbí$v,æ;,ñL1§WI>+˜$yÜÀ˜£³¸ª>s\Ï+ÁåýSúâî6þ–¤XÖ+±‡c˜§'gõíš7-Ç~iÁ¦=0ïÁc†!Ï]lœr;¦¦\)åáiêþGI@‡w¥ñÕ"ê˜sÿS©4ªñýV%ªÖP«ùûÿJÒ¢ä´ôÍžÓ÷ö3ÀÓ—{Ð±‡®ÿ˜Ïóé;™Å/ö5>Q:}£¥—4½¤VSw/3®X€Ý0£ÐXwdÇ¶“?¢/ô½ÀÕßˆëK™å»†‹ÐáVÁbãßeç2K-(U°¥^¬ï¾k§ÌÙú)Âˆû£./W|"ãiy3äAy¢je^Ì/ÿ˜ã¿©/L&è²„m'x‘Æ*¤àiCUµâË°°ïÃò7.H*¯Çåg<«;±à/i¦Ø6‹QÃÑÃ^X¶˜”ÉŠ…BaìaƒÖ9á³e,¸ÉßÿêZOÆ)ð£p˜§Àqbp.ùEcƒÇ£›†Fž—HC‹áŒœÆã“‰Ç/†Žîf@ãˆ4ªØ>ìwÂç°½‚ç¼àýÝwÅÃ`4ÔÒ8l$.7x
ç)^,›J!¥È™—›
âHH‹+Ÿy¥âQkMÓîØY`”NûìýÒ´þ§ž©§¦¯Jÿ³¢åúŸ+L¹þçªô?g¯«\ÿ3g]ØØ\ÿóéèê™0úŸYÿSÿõ?ÙV-Ú—ë.UÿSÿ–ô?ÃÉÎõ?sýÏï2MËj—o©2»ºTÿÏ5­!ÅÖyüçJ-—ÿV‘rùoUòßŒuõ]6ºVÁp…sÕÄaØžP"äÎ…¾ïTèó,ôåÂÞÓö2&—Â‹ò¥`ìÅÈ0/I|!ÆHæKèÂ$Ä¾XæN‚Ÿhg,úe× Ï©!-ÿÍ ãyº‹xs©„(»­I°þÿá¼ÿ×GÀˆ#ïßSþSôàL¢qÆ¤¥%·´èÇ·!½ÍìÌÌvç"\žnJ·²ÿCUÄÔ1Wþ“â¿jjƒÉõF.ÿ­"åönÿ‡«ëi[ rc9O5rûó›¾¢ÎG½tNYÞEZÏ)UâiÛÁDÔÌDUð›»ñ&öH´ä8ç,¡WðOáÌšO6òãAb3ÈˆŒüœ+¿]8Kèj§/\á˜ÎŒ1ˆªÔI”Êg(
,Ê/h<5]SC·gS<ËÇ(?0þè`H•PKÊº½ÏÐ‡AéÑ3ãÂv½¦aštäæŒlï@aîaäEPÊg@Ó¾	djchZ´¶E·¸¸ågx‚þ)fŸQ9†VžôFPC„ñq™•-|Fgúd4¡lµàbE1n tãæööþº+ÎÀõùÕ_x¯‘ê‘:ZêÏ*0qÖzÝ#ÿk±4Ón_Ày? (ÐúXÔJzi³ª–4­R«ÕKZ©ZÚTk‹Ì¾âÅõý ÝþHÄŠâ:ejì\²ŠÆGîGŽµÞÊÅQ´q/_À`1üxX´í[`5•aS‘mÀßÌèÎó•H^—HBØ¢œ††¢_EØæSQn‘óçM·Œÿô 	p®ÿ—J¬ÿ©V™ÿO½¡æòß*R.ÿ}ñŸž¾˜Œðz£$xa¹œ—Ëy÷\MOOÎ{gØCò3Ð÷Ôá·ùTÁ|Î~Þ8¡Ñ$Ž‚1ü"šC×4†Hr¼†¶3æôŒœù!›Zöß`‡èMòžz0h×6Ìv—:ïF8Ø–±2Á1D“îP™í\CÛRÑj¨÷Ê	Œ/Ùõ$ú¼Ã­îIäßåˆµ‚Wº•PxÓõŠ,nŸŸÂb	,E¹‘ŒñTå»¡÷›è$‡7î”‘^q"¿Â¥‡ë¥å'ÚçòæslQëÞ„ß£¢”!Òö3 1êjúcjÚÆ°©tÿúƒÜŸœ/‹¦1ŸÍê†3Í˜ÍÊFXRß˜þ&rx§è„¦ÇŽŸc\êpa1¼ÿ[ÖiéùÉœš#ÄàC.dÞ4A6FL8<Í}ê‚3åúOúþHÞ‡™å#2lNd{2	Tøzˆ;€ìí
‹rG›ÅjÄX¤ós[Ñ„õ{îNÅk¡©úYŸû°C Ÿ ëfâÍÊ4bËyÆq3ct(ÃŽ`ÅÝÐf£Ñ¨zcôËØÕv€Š`8›õT™TÍŠGÿ=sé‰ÇG<2¼Iw_G³I* æHÎ÷&¨VÞÌ)ê^µ|báó%µb“Onî6žÖÀƒ¤÷w–e“^÷Ë¾¦_àƒ v„*VlÑ/‚sR:¤(Jp*‘ã÷<‹)€WXèJèLxp5ë;·\Ô¬ïþ¤G+œ± fócÂ6£L^‚µè¨ôïà>tž°nWˆ:ŽI²w4šˆÌîqt˜ùâ±Ñ×asÍ×¥W%¼ùûŸÿÞü}f#¿Iz‚)¾ÿ>Ùs-dìXÇœûåñðþ§Vk•ý~ÿ³Š´PgiàOT|ZÖ“UøÞ7’ä¸wÒ0¼àn¬œ¾Ëa£‘«z/ ¹å‰ª–ñ¸ì2O’evÜãŽÃÖÅ „“q	~Î¶ÖÊ- ¹"üs¼3…ÌÏ~Œl/
Üsö‹“H«ÆkOÒª©êyák~ž“I~ÿí`ÑG?Kóü¿Õ¤ó_kèpþWyüïÕ¤üüÏÏÿ[žÿÛ°A|v{äu~Þ¯ø¼_<¾KJÏ‡x—6Î/·ÏÌ.¼‰ƒ7áÛäâ;£m‹ü ÿA“)ÎnlöM!$†Æ?#J@^Ÿîïe„+éŸ TS2ÏÈO?‘r0Ëàî$ úOÓ
K>Ë°aôlÇôØ}Šñxƒ¨nè•êFm£~¯áÜ;Ø>Þ}·{pÒþVF•s¥+I]g#ùÃmÇO°Í8~w°Ç>é³SÌÿ¡7õË¡ße.*K>wÔº:æñõj#âÿ*º†þá?9ÿ·Š´°å”fÐ¾aÀØVdbÎš5ÉÙßÈ£m$Ù3b$Å¡M;ùU·Jj£DÒœ—VRÓ\Ö©ÌF|¥‚n~­ÐÍï©câõ¯ #3†±¬ÉN$ø±x«8 ãCà¿	w†¸1†¨Ó"¢ÞÄd4‹¶©ÐBû…¼`NI_–HÛú+½ElçÂ
SÄbEX˜£Üí#Æ,À‰”
ÏÐL	N¼ÂCå4ßý‰ås<=é°íû^yh÷Ê¢›âÿË©
„¡3ÃÏKfT=;IK•Ïà°÷5Ì (*¸}-–(>¯šìvŒ•ŒgboDî³BóQ»ã»cv3f‚!Î%‡7¶ð;î&Ÿ
;”/¨´…îÙ®²'XªÂÃ	ü–CƒK×;/qÍöB»P/I
¿‹ýûSáäjL[¾{-à:Z-Þàf}€b°>£ •æ©pÅwÇž‹úD~äÑ[&Ücv¿P“‘ëÝË–Å~ ½}tŒ^V82w|\=†ÏËèNìÎ®CÍVEUÐLÇ2<ëpŒ'Aè&ýï¦ëø.Oøu×ó\/ýÆTìXŸØL ßM†ÍãÅÐ/íüOò0sÔ¹èš@©5ú•Òþ¯ZÓcÿOÕ*Æ¨7rÿ¿«IÏþÂèûœ9"ZäÞ“»‚’¾L¬²'{#ˆ€Bg)ª0Íy2¦’}.:@Ì‡MÍÃsÏ3ñ"A8d«xÅO÷œX@c•ˆ=6aãsGöõ½Ý51l¯`Ñ]’+wÌÞa:ÃîˆÆ!2ð6õƒ‚T,`‘5zH6€aóÏÜÉÐbÁ{”8ÍÝï
Êë>Œ(Ló-,ô„•!·Ö•:¾Îð¢†J0Ò¤„q†‡=Òb‰×yrF“D'Âk
2êŠo0}ðjØ†=dJ5£òÇ‡M
Œa®]ö÷»Û§“Ãw{¿µOö@VáPG®ïÛ2Ÿ‘DbLàáq{{·‹jBiˆG$Áz„è…íŒ…¤pIú8J)v‡ã<Ý‘&qB¿oD(5(B¶Ó>iO!CD±ä†½’66¢«¼¤a‹œâ°6JM‹<›Íl_Ø˜râ¾PtxûíéQØo	«¸¹“Ê³Â<Mà<„ÉA,lËÒKÃ£2ê×ï>„èï…Ë2|ÿj¿oËMàûÄLÎ`Å2ÐýÃ7)º@uSÝÞ^P¶mÍªST¬6À•O¶oÀ‡ü¦84n‡
0ÁP!;.Û#øf	ól(pvôØfÄ®&öãÉ¶ðÝô™‹ü§oôª73%ù±Ù•<¼À:æðÿªVáü¿V¶_ãúõœÿ_Iú}÷àÍÞÁî§Â1õÇ°Sþ¼ûž[¬·´’ÊÿSøýÍîÁîñÞö§Bgwûôxïä×îéì‹»îû½v÷Ý¯|ãéœ¡õ[«oýÅ¼äi™)Kþ_ èÏÒ<ûïzC‹ßª:[ÿÕz¾þW‘–%ÿçª@ÍÎ¸xÚ Û	E`vr ß&Lch>{ÏÈŒžˆ"A!eTÍ„šÓènÚÏ¼Iü…÷³Ã+|=²˜„!W„ò6>¾Ÿ¼ßa–ZÎE~‰°˜æ2¼â·¤üEÞGózŸþw˜©/ä÷íãÖ{c8¡o¸P-9êh­õ“~<k~¼,“ßS¾¥?‘õÒ´ÎZð5©¾Æ_ŒVfTú ' P„‘²‡"{ÿp»½ÿõ65Ù½tU)”¶™ˆýÉrK‚=Ë„• †³‘Õù1¤Û‹›œj‘‘þTf¾ˆB à5à{(Få =d‡bh”Íqï`v³z1f„À ã·>on×eéagï8šÞèbá«¸#ðË)’’ìþÂÜCÌ@À§ÀZØfB-õˆ?¦×°[˜ñšñs9´/:e´hÛ¸-ßg™¦SrÑòÍþËÕuký©°C N%g}	©uj8¢^¶÷æ»t
ï~
˜kã½_<˜Ýý½ÎÉ×!–[àXü¹Ý*–ˆ´Z“_âñ¹],X®C¼î ë¦•ö3Ïwõè,’–vüuÈ¾å¡(}-A¦!°]	(\NÓP›€ÂÕ5¹ ÙgYJµÚÎŠÖŒmÞÍdÛJbÈØŒÄŸÞÌaOƒÚ™ 	 iè¢í(µÁ¸µ> puhàžñ\~£ÚÅë³ð|AÕ¿3:‡Y0TûÛ°%íïƒ¬ÜÚ&CXyÆüÁNî¨ÔZÇ)ý ‹Åt‡®×2&d£éEß=Ž`xQ–Ï³²°ùC{Æó 1:)Q¢«LL-Ñ&L` íó2},VSo&†2w]§w+Nñå\*îÑñÝHþÔc,þÝppç+¨Ð¢¸°ÝÖú… Ü0£üœŒ9YL"¢˜¤3 1ç­õÓŽRðN\èTˆDþ^DüTè.É{;C0ËåÐt@‚ØãÜ2zÜÆ ­üd42¼«°Y–ëTrõ(ccùž­ÈòÎ»ßç>³ï?©¤<¾´0P)øÈI8’º©;ë‹ºcNÝÿxŠ^pT˜ÂiÞý/äNÝÿjz~ÿ³Šd; ½ÁJèÂœO)G1z ä«º®á%
»õyzhÊÖÿb’ÆÂ®çéÿk’ÿÏj¥Žúÿ•Jîÿs%)¿ÿ}Üû_y­}Ÿ×À¼ƒsoƒÓWÁ(¼ç×Áùuðò¯ƒou½øx×g„<#9çoÈÂâaB=¶KñŸœaxì“-O·ISü_`ô]Ç<ù¯ªWRò_µ‘Û®&=c,?ÀÙÉÍ5T‰Fš‰£—ñ.øAöwÚG#ObfEÊìD¹U‘ËÂ\D¹5‘+Å¦Œ¾ÕIS²dÞé ¡7Èáþ³ÓÙÝ%ÜõDç]áÙ]w:RÀk7Ë5Ï©×Ô*›[M­^©7«š›[ðð>%í½‡§©õ_êîì¾nŸîŸtW%ÿé­Ë³ÿ©«yü¿•¤ÜþçQìR«ìÉJ~3,€²µÜè±¥µËj«‘Ô
¾¾ÑkÁñ”ï³ÿOÿqTš…¹€™wÿ[oHþ+5¼ÿ­Wrÿ¿+I¹ÿ~ O‘ýGò\À<ºù-¬ÂõK4²Î^6"|ìý»°|·/Ys½\Ï/ÙÔUX‚ó—[Ôô ÿ/·Â~O03qç<ßƒ›åF¾ÚYŽ‰Álíìtº‘)j«ÈZŸ–?[çZi³¤vµjµ\L:}Ñb;^Æš˜–OÃyîâE±ü÷Ä†ÆÉ.^æ”tÇé‚Ç =ÖŠz”¯ŠÉâ<Â¬Ô%Œÿšuxlw‘ÿ-aÆBê˜wÿ£5bÿ/uí¿j#çÿV’òGút³ÓW5‰õðd/jÂàv’G¾ˆ7gžC`'®—þiî1÷è¼¨æ,˜$ËlÁ¤ôøázƒ‚e6I”YÂ--zÃ	}ƒ$¾À¡Ä1šN‹ÀþFn øçéâ©šÌá¶ë qP/Â|D]8ëgbæŸï„ù±7¿<å)OyÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§'˜þ?jz.— p 