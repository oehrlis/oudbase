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
SCRIPT_NAME=$(basename $0)                             # Basename of the script
SCRIPT_FQN=$(readlink -f $0)                           # Full qualified script name
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
    echo "alias oud=\". \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh\""  >>"${PROFILE}"
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
    DoMsg "alias oud=\". \${OUD_BASE}/{DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh\""
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
‹  Z í½[l$I¶Æšİ½Û]mİÛ»¾Ş×İÑ-²—d/ëÉ×gªwªYÕ=œáK,v÷Ìv÷r³ª’U9•Y›™E6§›«[€-Ë’õã—C¶ØíÃĞµå×mø	Ø€½!†-É6$ÀÀğ‡ìsâ‘‘ª"Y$»g*gšUyâÄëÄ‰'NœÓ0¬üÔ%?…Bauy™ĞÏöY(-±Oşâbii±°²¼\\"…bqy¥4E–/»bøô]Os *®­„°ÃÃïy;üÏ·äiÀøÛıÖ4Ïë»9·s	eÿÒrÆœ?@©X„ñRX"…K¨KäùšÿôOòHÍí¤§Iv|`›Ùh­‘™±£İwŒ#­e¸¤òpÜï»†¥».©êGºi÷ººå‘Ÿ’z¿×³Ìİ¯Öç!O]ÓÛº£®çh®«“Òûä½âr‰<45Ïk8ıv{ÔïKİ15«5öJok]=Ç5¢L8xYé{Ûá/ë~¨YdGï8¦Aælİ'.MËÙ4í#w@®iw!w­ex~î™MÍõÖ;šÕÖ[÷OX÷W5/([ÀdO?2\Ã¶" âÛí;=ÛÕ¦û@3¤ŞtŒG<›´uøèèÄ° iVS'¬…Ds‰£{}‹4í–=a{º+j³ßqtøÖÕË<!}Wo‘CÛ!ºud8¶E§c÷=²ÿ¸š…¢á­÷!+”†È:×s×òù6@öØ;yÖc.²8 q}ìÃ
İC>ª²“5øY(æ
ïçJ…â
!8
!–ášIt»`Š¥\±ˆ0«¦Òú¸ö!£ßØ¶ˆ}ˆ”Í]ÂäÌ’u(Ôî_jTì"ØÓúK:ÙvUövvöªÛå™WÒ¯µlÈÆkãÔËÙN;sJ+P³ZØÆ‹×#MÑUaôM<ÖÌ¾î^ AéÇµ½úÆÎvF3]İ©ìîÖ¶«åÌşŞ£Z†ŒøLíjS'¦İ&‡|Ñz=à¾¿S¯•3*›õsàÚhÀ$]œMõõ½İıƒíÊV­<3‡nŸ!3…ùôşÖîAuc¯¶¾¿³÷y9“÷º½M|°±	¥Ï¼R NójöÜÌL&]ß¯ìí|\«Tk{åı…ìIƒ¡†a›y%•~Jæ3
‡tŞ}§ótÎ’™»™ôVec³R­îÕêõ2ĞôG¶£Á„Ì5;éÚŞŞÎ^¹–)ââ#ÉĞ=è[M$ª‹C7ŞÙwÈëE¹Z[Ÿ›'¯Â¼µj¸=S;a c.ÉÉ§BJÔ4©jo¹m’ÙØ~°CÖXÁáA~ší9$kqvolMl¯×î‘l•|bD«ºß¿`ßwa¶ÛNëÿ=ò<®B²8b§…“9‡.,îğ+!ûQ\ö˜™’İ‰ËŞìèÍtùqôi4)_J@ µ;xù!ù®‘¦U®ŞÄE‚li´ÆI@Ûu÷!…ôxå%	¹#Ã‚¤À"Ä–ä¸|›v›²'Xà_mî<DîpÊàŒCò‹§$ÛöH<ÿ ×w+-š¹nêšU±ZªoxnæUé”¾ÖMXk\ˆãÅç/š~h¤OÓc_ëb§Ö#,Æ£<£K–nï²¦:íõ¹ùô+ÚÎíİGû°Hï¬İ=#Bú€¬«½Ğ	H¶Î	L«M:|´Xß6_C—ST§ vÅc b™hÄ2@&ÚI	˜ïÅÍ“ü ™yBö7¶j@G[»°°´@,!™Ÿİù<{§›½Ó:¸óñÚ­µ;õÌüHY÷ö’³ZC2ÓÕrŸ£ÜO±T¥ÜLF¸ËŞ+ ¹˜GdÒ]­Ì€]Ğ‚O3¤L¸Tˆƒ`iÍğA€peÈkO×IV“æ£ŸS™WƒÑø`0¥ÄW·czş¯ãÎ{Zk,ö'P_Z×–­qÖ–Õ
%m]l£S@¥–F[Û²-=Ê›Æ8l÷îÅµéëıøJŞy—ÁŸ})/(‘0ë¦ ¤ß6ÜãKÃ»áhØÂ#<ñŞã,¹ˆìØ/Ìûk.rWXi#Ò³Ì®Š8pT ¯A3É:H1u<-q›h]»oQI\sÚ}Ü"»9R‡ÉÕ§Ë²÷¦í ÜA`ôrr¥Q‹ˆÉ.íó£â_Š_–J¨Ø $’¾e{tP]\Îèr¿rÿ”@Qğc¯²¾Yó¥›ƒû•z¨ã £‡–J³Ñr\İ£ˆ•DíH3L”•ö‹Ã0¯Û}³E1xv¿Ùa;>l—Òíg@cÚZ‹<›yõñG>'*)£[ÚŞº«}mÎ¡azKÎ¿44Íq ‡°:-*E¨Ù‡¶†e§£ëô-å®jÚİ®f©èJç@×r%=ëâ0¬[†ëRÉ**eË=
m…(ûWTA5X–ÎXâÇĞSç­6ø¡ÛØ(ó)âO	…Ø–GìO˜h{Râ´5E)jG·Gr¿£Š#a~æCÙóğ+ğ.-¨‹LÜ°àk—m²¤ú¿ÿş|h§ò	*É5ËÒˆò{G3M[™¦?ÊvY/,ûØbMO÷²,%§æ¯ÖiOïÚG Vë(P³9ïg„§« ,İË·ô£¼Õ7Mdz”¢²û-1K¬­¾êAXülGkBÂı~[ÆÚÔqfYÎ»9’¸bdXiã3ğE2í¿4WÛí<f…)i¸†ôâzHÀÆhÓçè0y#………>ç$-D*ÆD*Uœb”pˆ`a¡ˆ\TTÔT¶»¥¢¿ß=4Iûu‡‚ıêÓ•0¹ºäõkxó’m…^ËTJ- 4,k;§¹¤`OçÈÌÜ!rÁ`IÌR} ¯„sR‚ŞŞG”|ŸÉÕ	i.c¢¢¾
f éUÅ"GÌ¤Ùú©
U2Éìç0GrùéOq˜IFÒ](ÍioÓşˆ¨ıR””öÌM*pR1“u£ş±,C·¥Ò½KÔï9Zd”†-2¸ÇO§9×‚^—tºÀ¡X‡BELèµçBê@4û íYTÍïòdx¿0™ç[[÷ì­š¿çØ8ıp¡å«´‰=ÜÓ õal?Äs“Î‘±V]ûb­¶æ êo‹˜€)²€tÉ4†i18šÉéÒ;clÈ„Œdº³]óPYC«Çô{	_Ye— ëÌ“½ÚîæÆze"µªÍ«Tåç¢±%2sW^ÀèÍçjûgDx\¨BS›,JÉ²<Î)ÌÖò¦fæ¹ã2£¢æ\‚Ü#şL†YıÓb˜şæçPV‡
;DÇÅÇîrÖÃÉô•·3Sún™Dº ah£‡‰_°˜`e0Sö)ö` û	j3ˆÿø‹Ä±İu„0aêKû$‹]À¾®e3±ZèÓtõŠlr" ˜yµû¤ÊrÊºé'|‰ŒÂZ…–£ƒÃWÁpÕ·„(\6$•†	<Í!³Yvœœ=tèéR,;¨Ûóè÷]Çîégè.Ö’X©nCõY²Ü&ÛP ôL+@Ô÷T¢
Sx:Æ±a¬òg§ó¥¢Î©DãÊ>bğf­ÿ`ÑÑØI=GâI{Ö ³nş—3ùl~V¦DÈõ…ËÓ}­ù`ÉF•)Ë»}Ó3zx¶‰¦>Šü•Ma÷âé/=ğgò¯¶?póÏ¬<Épš€:tş@Ä¿äPkÂØ'RJˆ¢vÙ2¤L7v 2Í}êºsû-$½º<&sm—¡6M2á‡¢zK){^°iì@ÚVÊªãT.V\|€›‚4ƒ­b‡o5TŒ±-b7Ynñ6«•]ú§î/¥jÏ0Æƒnæ•Áw2•'Ÿìà©Åœvü‚ÌŞ¯=ÜØ~µW/gYÙg°w{@¿f>Øx¸½³W[‡å¡\ü€mµÊËx:T$¿!ù_VZ-Æ œu¦„IÏ>œÅRfŸİË“WĞ¨¹™E–\cÍ€ôy§ğ9Å‹WtSBÓÔ'ó´®Ê¼ózufÁè,#Òüğ!ŠS‘ö’èÕ…XZò“t·F9³7ø¤q2:c*àiA0ièÄa|fŒ´;vcFg¿ª}}¥Bl±y‡®TT“7³»"|¥ºµ±-/>‰ë˜ÖêÖYtõŠ«Ä5LiRÒ°Æ*ÔÏ1ªK%uáã£ËxheŸO…â×ÒÔÀù°–ù€î)É+K§‚ÖWÉO~´¾**§€ õåR,±ŸÀKƒÕ—K
ébûÔCsG:döºmQ'ÏÕ?Âş›™ğ]‹ı÷âR¡„ößğmu¹T(0ûïâÄşû*‰ı÷5Ùûî«bÿÍ€5EÄñœ,¹_uÓï÷rğÿ%™~ÃËsìVLØ!ûjTDäöô¦qxØáC'ŒÛJb¼æã_mcğ±Z‚ŸÙüJm¸¿F&ÜWh¯c-¤pîˆ©pıÉvÉ‡ÒCÒè&Û±×İX;ZçMàlHlò‰”›;Ò<?÷–f˜„ë=â³Ol¤¯ÔFšLl¤'6Òdb#=±‘ØHsyõ†Ğ¬²ı>O\ø&ÒCğOl•Ïh«<&;Şë°*ØO~Åì'´¶ı¸<ÔZ2ÙĞ’•H ´‰	å¨vÌF”€ğì–’l÷[$—f
Ù]3ÖjÔò*l!ë	æ‹] ”4@3sBÎ°¯QuëæŸ-äŸ‘|{şÒì(Çb'ù•7¥ãl/4¶1¬š3)SÒ¥ø:{ßÓÓ±z‘PÆFZjûëœƒ1l~ˆ?bÓ¤éè¸›ÕT
ÔÓèÙ½ó"Õ†­®Â÷È~å~9ZP íƒÍ:š0»®#2ûËéÙàÊÙëfßƒšaqX›®E¼Tö¶Ñ:G•„°ò´Shç=‹i{ {44 JÏÆlXÓje¿rš¿‹×f‚\}‹[å	öRÂâ+éBÅÙBØ÷Ê;<‰Q¨]›ábÆ Œ-swŸåŸÍÁßùgX‹Üİ™ü³b~v>hš¼‰ò{<jŠ®œm°~–xi†ÓußÕ‘5ÏAÓÑú.4‡èİ!³³ş›çlŸ_ß±ôcÊÎ+4@±Èë>š|Jñ>³8bµİlÅôtAÈâ¦–?ç"Ø2ìª‡İ#6,ª§q˜Ï!1»ÛRÊœ`'øtFdzpĞ™ ‘ë_y“¶‰s=sõCòšèbºeXÒkú:”Ğ/¶ÓÎÙx8âæ\je™ƒ”ó¹-3½d™²M©ÜyuJÂ3,¦öª•–©ß[ ®İwšº,³å•øU¬t'^«R^P€÷"S¯å¯)ÁšûI¶'L‡>£¦_Õ=U/¡T+¹Åè¡«ÁlyÙı;ÿ]&‚eZVØO<p=…¤9œfYÍÇÇÀ	èìÙ¶Ç¸ik9êB	‰dîÙ§O×¦f½X{ş|v>Â‘8²`¦¨ÅÊ8çUuÕ4A¿ïÀÈvÊh§¤0–˜,3›–Yx–ÉGPägÛD~Í«Z66@hg<½r7Xr?˜y%ãôÀ¯Ú)èeÔÉÃëÒS=‰;4ÇÑmTƒV‡ô‚œ´Öw¶¶*(ëóÑÆöiaÌš-˜ÌÙlÇv=Úzód—8’!}\5ÑNî{„ÃªpD¡iÁ+›Ğ›Uí„kÌgv§?û%À4jÿÂB®tR¨#¯Ñ R!fUiøDìƒi(Œ-Ù°2›Ë¨ösÆÇ@7(Ñƒ¨Pó¸Ä!7¯6*ápõ;Òù¥ìÀ²1)“Yaª]ñºH^’¬Kµ*;{k5_<K¼{œAÂ	¶ QÈ;‰÷äÜıò³â¼ÊbÕçÉÃ>z¿¸ı&îìa›}Œe¸½V¿¯hÛ/°bµìckÄOÑücf]v”ºƒ7«õV.ã+K$Ûô™$rQIÄÅ›z–’òkÈlÌYÃ<LÏ.
òö?2¸´êÜT(¤×)í‚tĞ#!{WY…0ÿ×ÜêUØ"÷{×ãÿwqyÑ·ÿ,.®¢ıgiiâÿ÷J‰ıç5Ùúî«bÿÉôõµÿ\ÉÁÿCì?ßÏV˜-í<%¤}íb/rYWœ"4mëê’áwîCß³#MŸ”&a{;J¹â[ë]øJÍJ÷?ßÅ=ÚÜ¹A¬QbÌî3Ö´ÒÓÓŸÖj»å¥³àáÈ¶ûİLhŞ]A'ë]ï¥×ôĞt°œÉfÅ÷êÉ\+YÈSkO,hßfZ|ˆ¤úÕ·¥õê?Ò#8QÑZec{}¯¶UÛŞ¯lNlrÏAµo”MîÄoñÄ&—–1±ÉØäNlr³o’MîH&¹£Ü‰QîùŒr¹l5ÊÓ@71¦Ó¾UÆ´ãöGúÒzkÆZw­vf´l¨š*Öõ*ŒlÇé>tb5œXN¬Fßb«Q~<7¢Õ(‹÷ 2y¨8K?²9¶ìË
>U`±€.puÖLÔŠK?¥O~¤Õr‘`5õ˜}Ó&Ë8"Çºş‚XTŸŞ®=9xR«}º½#é\eæÓ;›ÕàìÀÓìÌ+<8Ÿ§ÙïWÖ?}´{P¯å±B PÈD”\än%hF4'ÒÃ"eª“Y¢j¤Í8H´¡j%4—'ŸG†G³°*ö6?Yå˜åRÌj“&ÖÃä¢vœªñæk‰ƒ.b‘Œã­Áìl¡{G £€¾ÑEµUæ”D2#T;B§0kV‰kõÆ_O"Ó#è^Pœ-+ÇGõxâä›˜
ftŠ{˜Ú0ÊÈÎ¼Rë"eŠ¼Ñ\T6%qcÇ·ëèàyİ¶v0Œ#Ô˜wP3”3¨7Éî~Ù<¥ò².Ã™óÚ_²mŞúÎör/©ÕCš&‚ˆp÷mgGã0¦mÚ3E¸¡…¦åµ&s<íÿF§¬ÒÏ~õâ'w­š€Köë'r‡f2á´ÑJêç¸^æÇ¼·BÇ£['[ßÔg0*É ˜—rnƒâáÆÄ2éÅ6y{á¸]é{6†Jjjƒ.é|˜f]b›-´×Ñ#(kĞe>ÆR<¹…ÿaöã1Mä¡ ²ô1JYB¬Sd’¨¹Ó%Y'~f†0?™InÆ¶-7áĞîƒ¬?§·sQ)¦Òó‰;"–Ò˜L½yõ&¦Şgx®ÛÔö|Ğø7wà«Y/¥ŒÁöß…ÂRaí¿—Ëø½P\\Y\œØ_Éó­ï}{ê©©-­Ivêä3Áš0mê&ü+Á¿ßÂ?øúÑPVö÷÷Ø7šãÿ‚ß|ƒ§ßšúÈá9­×3õœ©¹ ã^~z·Îq|ÿLMıI„ëjMW@·x&†°‡Æ³ö[öÇ!X´an˜ú†ÕÒ_NMıaöû¿@è¿øÿÓßÁÏâ•Ú›ù(‘›.©ŒÁó¥P,–Âó©¸2™ÿWñLî\Ïıßÿm¾ûÁ”Sô&.ŞĞEX©àæF8œìäÈeÜ)Do´`wÙ“ıDĞC!ÄÄã~7®Ãâ15…lÙÍº{C‘¶uï ±º´:\MÈÎ§`¬<çdÌÌâ"x¬9š×œÏ ±ÕuÎšÚÖ1Ûú0¥ù… ­†í‘İ#cn"×3|¼CxÄõúù´rı"£Ş¿H¼_0MÏ×˜ékÄç–@ûeÄEšh¦1×2
š™)d ç¤wÜ"Ù]Âñsj¸¶Ù÷ğPİë FÛƒ?Eı9¸q/®nùäª=ÀÀ¿îk¦qhà)6›õX~ôv³ÅBV@•ê¦«µ•G›â§Ê¼Ğ3JŞOT¯–Q`ø–]b»gJ9ğäpÒÁ´Zß:¨îÀFV)·e#ëR6wÖ+›2õ™sPò
†Û Aá¹0ƒÒ½f"êÅD™íD¨ıÚÖîfe¿Vç°1ŞrìîíT­ïË­èÑ‹b„•£Ù9ìK¹R®˜[Ì"€¶ fºá½Uo<,g< ‡9Èò2é0B¬\Y&Ä;@ˆFâ4ùµ„ÓS™(¥rç§ø]L^µÒ¯µ¬du:xLÓ¤œW9@K‹H‚¥+ËYC:&#‚¾"ï@RÃ‘ÀeclrJÂÒ‘‚P“rP^1Šv@Y‚ˆi'óC.ªÖGËY6Ş¤)nî4 XÈ,áå%j	Ù[å†‚«ÏØ:ªW^‡7H’ìM5¹‡qY-fÔ»›<™S	}×p›¯è@š„-àggÀ0ûÖj×†ø –ªPŒÏËŠút(Ş0ï!V˜f(‚ğpäQ–«¢W-C¯¦BÃ¦ÕÁs»ƒF®qãpµ`–â¯ÈKGØ¥R«Ÿ”›«rÆ @‘rÑB+üIåqEé?ca_hGëZäÁ©1µù€+×Ö÷wö>?`†rÔ8‰W"ô
Shuâñ`K„–x,râ¸í€=ï„ÜÅ½îíï~xëÙ9|™ŞBƒÒ›Ô@Şò¯›ê/õfŸV#ÏY¥ŸqçÑŞz­Š§Sü+=ŸzÃm™?-YÁ%ä¿tËd¥NqVşÏÌüYıİë;)†£tû
÷¶|á×ÔÕˆŸÌ(x¤Z5ıŞk ?ót§‹E-8'4OÄ‡›TìVö?F£¼CÃq=‰¶l‚zlÀÒäèˆİğD4jNZ§$kê!‹]‰WW×ªˆè?N%K/?øe =aä¸8
8 Y<Á|¤lƒÕEõúí€Ğ4˜ÙÒ" y}F2‘‘L\…ÉøˆÒ¾OeÂóÌ’ßñ•‰[YÏX—!(‚ª£E¾ñïrŸëòâ)›’*‚É)‰ˆ§$FdÀDßö•Hæú¾M™didœş|¹Í_Õ¹İBBmFüN-¾aˆOhÈ_Şˆ\.Ôõ,¢7˜úElB¨P*'ùß=­áWQñéXòÒpÍÑğ·ÂfjM¨ÛµQFŒ–(w¨z:ğš®‹^²µ=4n}Áí]å=€À¢tÔXºÀ„5Ö=$a@¢
ïáÛ+`Ør‘=J¦ÑOxk^bn	6âá‰©@²:sH6oF´˜—*ÈíÊCfïg7y¿ ;/•šã[b6WÂ
¥w{ŞI@™ˆ‰qTÎ`%x(4Ú\TQ¬µcrÿ•ÊõCFÄÎŞ0Ò¬‡`U´£ãQŒÕÄ>Çó8¦‹XØ7†Ö‡\ÔÒ^¢®&åÛp2ñûúÉŒø%Ú‰PŠàj’¡V,ÁÈÛğPßV^)J"mj+Ï[âOä±P`õÅÜòÑİ™i.‰ŞÎNkç¥³qÓ¥¯K»!Ëšë©#	ıŒ2@˜c%Ñß4E¦ò8nK{~³‚•Œ§n…ş:(€k&«àYĞÊ Øõ9]æÕÁ˜ÒÉjaĞ¶°¨0_¨’‡ÿúœßÅ¸æÇTf@óB¨Ø†÷Ü9ÛQwÏiÜª,c,Òş¹„›“oªŸ%ßi Z	x}—¼
ŸçR§q-îaF¶¯FÊ9ã„ì¹b>×«{NévyT„ãÃ0î?ÂË“s‰wCfå»!³ğFµ¢fÏYî‹$æÇ;$êÔ“o’Äe£2eT³ıŞìÌ”ıFÓNH94¤ÕVH‚!.ÎT$”g›şAYÇ›boìˆ³_HBNÄ€YüùÏUcV‘.ÎCÙ‚ÑBÿ3a+WÚCşIq&ëÂ&ÌNæ‘³ÃJÈŞÑeiLÚ®)(lGkšúÕÑÆ#bL‹ë££ŒÓ4sôÜRAÊÙ‹‘nXLx+šy°7kcóÄLcÕçf‚ÎŸäfcN"8vXã)"(š”[gÌ€çaEGÁ7«•]²‹œ”HE §óXĞº
ËAêõÍx…Şˆ§jƒH†=éâÏ&2ìÕvÃàããËğ£0ä~/ÊŒe>Ì6?Ì—–Ë`Ç¬ã³»oHzÒä'ØÕõ€¾dÑ•"R*E²Ñ´ÈÏ¸'£
²‰÷#à[O»cI·|‘#ø0U%ï{EØ
ªyxİAæ’-JQ!–ætçGTRáä8?²Å Yøå¼(W’QídF`ákTX:#é ˆcXŞ!™½“]vÉl±„Wè×%üë¢ü•¸~ˆ³­ĞrÂ¶a4NH€°—Où'ö¶ÿRÄé|&a§4cHÛ’€Î3—È‚ÂP«!ÎĞæ»!ù´Ş08Ã»›aõ€<¿ÀÚ¯¯›¦˜n_Bõu›ÖË,§ç’öøUúÉz“ôÎ%çAÊ‹9³òš¼ö(„!KC‘eÃ'toåölvş!‰x$D€7A¢§"]y&¸ŠÈ¤^'2%±W–îâİÉQÉPnú‡£¢Kº1'IT‰—ã‹ßºNÍ<B,U¤Y\·ÆN÷hìš:ª¤`ó¢’á™'Tå!eJ¼¢–à¤ñòë!×!bz¡’ZR‚‰=3U+“c^Kö‚ıĞˆ—ÉZoÇ”–zgØ¨†w¹™aXbG4ºiŒÛ0â£z¨tÌZd6O71t¿A¯ 0'Š¶eQöŸ_Èÿr&ß›5ğå£–›m¶³¨°Õ-äŠI¨OTÄ8Qr¤L^–÷1½W=ÎÒ¸à¨”X¿ä"a£i¤¼/g¯‘#Éj‘9Ò‰İwØ\‹×cL„3”~	¬ÃÑøÀš“Ó;ìÔJC(V#F‘J‚(HÓKğH‚³Ï!¦¸øŞûñ0Œ |1aWW`éH¾_ö½÷¼çç¼ãI™8^Ö°P¯H¹Âº‹ˆâ"++/b5|X{‘ ºr„Õ±º‹ñ÷âU¬nıŞÙ<àûğÈ
Ç^ÓùˆGÒ×¿„«1×)Ft®1§ïQÑ0q‡Í7Æqdë0OEÕ}ù¡¬Õ ™|(c¾ùìY(iÒÏšO§k®ù´µ6£vKFnÛ¨Ò¨ÖjE6Awr®æSïİKªsÔÇ%ôKTÙut3Fi§œ Pa1.»dóÕ!Á'BÖ$çÂ–IåF€¶¶ıøb7®´ $>ªïïl¡=2¥±!+©éYØÿ™TB2©é¡L¾ô”%ã¢‹ƒS‹¨pL+*%	\ICÀFT­–Ÿ‚vuáfˆô¸|F—ÒãsÃóp‘…l³Ñ|JSÊêŞ-\’Äb”Rú€,¢Qá,±
ïoâòÅTY[˜C–¹2”‡Ñ€²ô¸À6ãpcz8ğŞXpHWÀen "ULésñƒ ÀIû=^:ú¢œmPÑ-’ı·Ã/³vI_Á"´¥~€zdí›„U¥j^Ê¨‰šW¾	JßKEw‚ìí^Ğ}aÀÄ	©D¼--µmw”lòñåÌÜw2úÚ	Y#†,Sã,Éq Y,´‹bd~•éöíhCÏc¦ñİ;©¢6;Ô‡ßiX¨¤@¾øÒÍ2…½KÈóç$$yU67*¾[d
O‹ Ü¶ÈËİ/ÏÍfà¿×™ùÜ]j]D‚=%ºÛ£·-qÌM#™×sË< ™ŸÉ?+ågc°¼âß`û„ŠÛ`÷ÄO5`Äïd‹~‘‰ÑÏ¼¢
Ÿ`à“ñÑŸ*ñğ8‚i4Rrbq©â¿8k‰X|oˆæ80·t“zX¼ŒsKv)qãZ†3°( ô.¤\bãàhf¨× Øô·¨Ax)2|+]Bà%pÿpC(êö5j$%—ÒÁŞ	hIÉ”¸ËWT0J<§}!Œ€%
ŞEÑÿ§eF¢k¥:¡êV¡P¦1Uiİîvmk˜YyFmò4•ò-û˜Âíé.¬e¨d.1Ì§qíš	°ó6ÆµıùóĞ‘·e“®æ5;¤«krVÍƒY-ƒnµ›)ØyâÎ{"áhÛ¯™‰‰ŞSÈœ£Ó Rf‰å ¹j/.MÓõJ³«Ù±ÿ[Ì¡ë[D–<ó8iXmeİ—d†u)m~d.º[¶@Šla <GÑŒ°ËA¹R›èxä3Ñò§™r¸½M‚£íØĞÉs0.~÷y ûD=x%ò>COstj· ›€h C€[ÀĞ=f—ÉNüAYàyĞƒ-zgÀ×–me%
ñÀv5§ÅÇl0å‰zàÀa\ÏÀ“\Ó¤èĞ+	äíğÙÂÇÇ’Æ‡Æ¾`iR±Ñõƒ,Dì1¡fÖs4âšèŒ†škf´œW’µ¢ºòBĞÅ¥„”_D9Š8şñŞĞŠ¸“ÈV¤_÷u9+–ÁúKÄ]~¯GÜ»¢‹a[ú±"i'EjØyÄ<Ô÷÷F±hQê l[æt‘;¯äBN%C˜bÄâgH†xË!™C™ÄéÕl!s$~23$Óò k¡!YÇngĞ..¿ÇØâÄ”$aG+;êÄy-™W(ªbùWû¹ 
Ë}©š~yTe!dfÔ³éxs…Ì||ÒIPò©SÒyP8];‰=K·©S>Vı>­\Í‹êb|s·ëÚ‰ÆÇ!èUÊ¯µÏËbÇpÜ”9ËÄY‡ÑĞ3k¹5ÉZnM±–[4Kø=<¿ÑÓ8gËñ]Ur”@zì ÖÑX$hk)hİZs×Ä(®`n_qÂ/+„Š–|'91Pg‚2u( Ü$¾;r•¾2ƒ*L‘xWÇ¿ÀÊ›ræUÙ¿}5†YøæL¥kŸ	cdÎ×B¤c£KÜÀ|Ş«UöıH¡h|“å÷}‹SÀ àÏâºw”"×ÈˆğxğZÖ¿àŸ„*ìPe„LyÖ€óåEjçÊˆ.Ú"ÅıÆ‘û4zY=¢¡ö¹‹ÅUó”¡A&†WS)¤›3,ı"Øi`z{xÉº(öàúMü½sõÌ(W{È¹{æzÇ}˜‡-lÙˆHU—0¸«D1é³„D<ÏuÄá;	\K´xlÖšÚ¦5Ùå/<å®n}ë’+<¾ÊVëµ0§¹îŞ=4ˆäePöXBÃpkRŒØí5%BĞJÃ“K…}J˜:”áheäº„İÌ\¤6!\Ã*÷İD¡¶ı9³Jº^ÿğ0ğCı¿$÷&÷ïMå >&ºaÒ¥Q8éÂw¼ã^ÕÄüÌ³Ø€ú$­ÆVK=ƒ~Ë’‡Ü8ä"~bFØDp1°A>”§Õ½‘«‘ t®Ll¦Ûîi®{Œg”†ÁûhŸğTgœ¸Şcô[9ï¥Ï”TYh¿3£‹¸PíÀØZÎ5Ñ÷ß©0Mk©ó‚XG”¨ë‘8€,–T„	'†º¢Ès	Ù	ÂX¤€ôuG2˜<çyZv3Ùe‹ÿƒñ2xü•¥¥)‹ËË‹Sdù²+†Ï×<ş?l«[µ\·uIe`—¥¥¤ñ_\]â?ññ_,,­Nâ¿\Å3MÕM4(·W…ê˜è4®Í<ÜFÍ:ú;æ¯Rù˜–æ´Œ/Å£Û£>ı©}—šO}×séÏwµèE›ºÎ¢"a/¸Á®çŒÁâ6µîæHÅÄ¸író™‡ÓÀ2Ô
j&Ú¥øá/°yXÈÎ†bÙç.póBt‰=£õw¯O+ïéû»»JôDÜ.‡Ó› İ¢áø”5™…4à‘4ü`¹Ô ‘¶Z£Ö#kXz–oê/)ú†ƒîv DÓ¦îÒ,ôCÖmGWº±*ºQégj]Q©o-Ø-P ‡}0Š»k;B¦?îMjcàõDKw4“
Ì¨‡†•¼46ººÔˆ\:}WÍ]Ì5`f™<Óİ»~Œ›»wy·,0“LõÚç—ğXäJ¤Ñ·šÔ>Šï ³:²SW×súMìÚÂlõ4ô<ºà÷>MS
Fš1º†©9HÆÇh–I}>LE8
¾×³•Ù ÀÇáyº…0d3Se:{d£²iXı—äñÖßù£j…u¬Ò¨*X)O3,i„÷4·×ĞhØ® lÜhª¡YäİuOòuÏ)´CËw;tOC}u:}‹uÂ<÷²êÈq¢A¾Æc©~/4\¾ïbt÷µ_ÙcB7ª©]×‡ß‡ºÜå'âª4k<Á	=÷–`g& Ğ}0×{ĞY´6^PÑ_ıêW4 ÓòèÖ~“'OQZm¶\ı9É÷Å¼Û¹ÚÊG#ÙNÕd‹Ålqñ ¸´Vzomù=êvbo£*áÖ>$1YçsFRÈçY5“°ñ0ÜÑ28´·aÌN—ü¦ÊüÈÕÚúB\Ef;GÏáoƒ|(™Ôß{Nâ#Ãğs(‡ ÷[×G}¿ûé÷	İJ¾xï=XĞZd£æÈCÛLæ<ŒôÔE×ãm}~º£dtºEiQÃ†©Ûµ[ú0l¡>•±É×|Ë¨ÙÂ%2Íi÷é|b¡ª5ì‘”9ŒëÀ|cƒ eJÿ!m±ÅÈ…BH€LjÈœ¸›êû/ŸÏ+¢ÅŠ@w“qEĞ@RñE9Ïû+h4º¶ÛĞ/Ò‡«Â„HV(X0e:2>ÆÕƒ÷¢2mpawXGTXG'˜AwÜWı‹»^ìGítì/ï{>3¬Ä˜y9¤DËÈ+“½^¨A}\lB¡Á=˜bı—CgywÒZ¾ØÇ]¾k´Z¦£>´ìËèéósĞM»M×É5’÷º½ÈgÚm\$ÓéyiÖ_jT4£ãh:È];ÜE+ˆ]”èñw˜ğñÌ?s/Û¸{—3&:¹ØL;áÒœÔÉ ô“‘!w+>÷]\¹ï’9!1£¼>G¶	¬uSh½i_³¨eñÌm·À?$Å¾+ß ”#qÒ„nµ× "…<Hy–ÌÅV!`0ù1VÂ8ÂU$„™q$©Eqá`¿—-”²Å•ƒbamyi­°|6y¤˜+ä
B"Kég_3WÕĞ9ÌáÁÀhIHE0¢¦}Œ¿|/õï&‘ô@Lq7I9ÜƒQˆR~Î†"îÚ$CQD3yãnF‹ÏÓÛ,¨|Š,©"ÃòúËx4ïĞ|‘»©¼ÌÀ/á0ÁzªÖš®‘#ŒŸÏ±•ÜŒBA<‚Qbÿóøv£ RïÛ&¢Ê+!îFA¬Üšâ¸ûÁ±ëĞ Nù/Z/Š¹÷r…ƒâJi ¦ úc”ò’yè@”|]£Ë`Á’"9ÌÆc~ø
)		\TÑH'g™ãmpÍg¤ÙŸkØTŒËåç(xølŠÏ7Â<ŠÏ8ÚŞQfß}ZGv^É2ßÔàÒyFî§„ö-çjGƒI"ÈèŸw³ÜâçYP„O€¦Pêp„5¼şÒ¤ÀÃÜx‘€“ÆøNóXïü§¤Hag˜r
£)…¬æ¼ÒMİÁ»I¨àtói<EH+G	i<;¥ÂÑ;¥Äğoùä\$Ó@+ìk¨ƒÒ¦ÑÈ§aVæÓ~ÜRù+ú’Ó?›À`r-9%‡bãĞu*&!²Ûía í–Š )9&…}°„¹ŞI&hP´6j"ÖøØtÑ­Û¥+¦z/¬ãöBo€ ­Âæ¡~,fkZÚqÓ3 Ìğ¨G­”¸§3!Æ#vê­Ñgd]dd±>©8O}y9ºÃ)QHŠØ âpR…JSdÏ!+›?/
*”Ì…ªz>l’°{6„ÜÍö}Í$Z‹êä©—3…¾ı('"¨ ƒ9ËêÛí›¨[üÁQ£&E™!æ lÕD¬+v8‘fî ©œÉ©	Ãâ+Ü4£šå(‚Îuğòë·ûäb”á›khg/&šÿn Ş®öB'.Í ]¡³(z¡Áhw¼gSm»Š&®±ûb¦ıÀã Û2Oq»Ş#Ú¡§û»H$Aõ´ƒV'8—Rç@äÄW&¸ŞÍ‘OVI,yåäAËQ‰¡ã÷†~:È]_½ÊSÂªrWVP\tš¤Éˆq:ùm€ƒu)\çÈ“gÆå
âkfYøzAÎóCfÉ°ìŒt¦§Ñ3¥¤2Â¾®8ÍáéôL1¾âë5îŠ#-Tváiø±í¼`je¼u!+¨˜æŠ+ÆüÕ¾Û§¢Ô…?Ö‡é¸d-Z6=Å(‡$tÑÂ“Í#İr¹)%ªe`–r·.4Ü¦ñ"ö$uÅUem³0} ¼ÆÄXµ8TcÖ%M§×ÛØõ}<—qaÙé°¨!SæåÈGÛîÃ&;\qdQ•£¤òó5B.$®¬BâÑL˜âó¡Ñˆ*gã{G©.2´¡Á]à6{.Ê±kFHÃïFœ°Ó>õT ÙçgÏLS¬˜KÈKadxréôkŠ‚„×¤ª3Ö‚°˜ €1Vväu8ö-c¤ç/ô–á‹X˜XÍ>ˆ}jäëvÆm5M˜:.ww
[
¦„õ”Yh!q ı5hT% 
Væhƒø¶+Ôò n ZS>™D…P½­Œià"Š&óˆ	Lbò?’aßÑëµ
aî)³ºıábUDÊ˜^eKCx„ñæ /œà)¼X:¨F—{Š³Z}´ùP”¡Âæ 9-@ã%zMµ7A‹	¸£Ym½•#›RûH3 ~ÆWBâª†~‚t`Táõ­ÏƒÔ	]Íw½«ôÎÌ¡fàãj£Ú<…âÂQ[ÃcÈ|b©L‘ëta“*­¶¬v¤ãÉ4]E)cmèhrlñK¢Ì­Ù\‡`30]ù¼¡Ú¬¤SxOé‰Nk(D§%tïÄØŞŠ´-bÿ7j¹@ÏÌ Î_
 …ì±|.‚\ƒíu£õä{à˜j¾f‹BUÒ7b·¢pà—ËäÕ`=ğ¹æÂp²¢fi"œ&¦SÖÊb Rœ#[6‹¥	CÙ¥àĞ¤Õ‚×Ùy [YnôÀÔ_¸¶ÊâÎ<Åª=ÑÅIöøfÔÔo\ğs¯Æ~"ËZ"`ür»è‘ gb€P´|ˆ¼@fš-»á·@ú?ÃGn±­9AÆÇ³ø‡Ø¬è¸3)†ÆÊkòÏ‹-çÈ#_<eqéqÍ¤B—Ü9¿z‘£¢¤).®äÀê¡è&Ø©$¨X¥±ŠjI–wqÉReR.¢C]»oyL¡r7ú42š}44˜L,
‰¹œ§¾¸6=¡²ğ†ê\1Ô~ÏÒ<¥8SíYåghqø¨tp~*ã÷Xİ“Z‡PŒRZİ¼ŸÉSç˜’©“EÔVÇ²Ü!r—JÄú&·ZÒŠ…!¨@P :€û5ªp(üÓSê¹Ko3R¤/7Ô—³µ¯±h7Ñî”ÌA’ª+RR}i¡â
Eú–ÀoV(¾UãEµ¨ä'~<hQ0=†0Ôn.®}ç*”“n\M:+T®»9Ş¬n< Ä†h}iCñœÏ_=é@d”êÉàò„
Ê:é+T2yŠ=Æ`ì÷‘ÅöÁy›¿ú äS,B†Rn‘U!öˆ8¶İq§ÆKK¡<ŸÀ{ÆT…	•Ï÷#Ú\£AjÈ+JŒMY´f	+Š²õW–ÚùÀqe:ƒXZ´Ôr[1²¸²Ö º³UÙØéã³·X‘–Ÿ¯ÉÏk!‹Ÿ#<B&Œ¹õ6Ø£$àS¼Ña$Ğ‘ğÇ@^©§`:ª3µO6âê %-*Ê«¸êJ1×%ÛJ†]ÆYáæğÂ“K¢ø¦=ZÉtÓò8Ø ø’~Cw¡õ±-µ-dœ¸ûhØG:İÄïXÆ#çŸMf—:&TêL„ÇL•#Y+lŞG@CŠª¨Grû0dìêi/`3OÕÀ˜y¿rŸ!wcúeW¹Ù,OPe*_VGœ_!f¨"7‹yù1ÎåyùJI,QĞ®y£Uó…]ÏÇ!
tjÃÑ…ÓÇ¡kâ†#¹¯Cêëú!ã£×sV>ƒáóŠ»UÇ™¢ì”Cx¯~¦´ÜqĞw¬LÏŠzŠíz¨(ZPè×‘€ĞZ'¾­<¦Ü?WíÈ¼;2|FİHótv €ıIrZ³£³M•/XïÈfM×\6»L×FçŸ²PQÂ°ØÁ¥ÅoSÉ%ø:)Ëm â\]}Oõl€/¡H,IŞ‚FX“§iq]DÃwTé×B,°?5ñÜÏ¶¢ŒEkÒˆ°t£@‘Æª8R}D¤Ì£Y€3{7N~¯Ğî{bôèš„ß†Z&C©Ò/TúEp>¦áI³ÖÖ³˜Ì/èÓƒrÜMaq}?¡G}Ñº<ø»Ââ‡ú–ª –b<2ìDŒøCÛòµ[bpƒ¹•ïá˜I	_ö1\=¿’sDjÃ;LãQ9üHKF‡C“ª!5ı¡P+^Hjè°4§0†§|ÇUÕìüÜ]P•TëŠ+ÓÅ¢dõõuì,W r7ÁÂ!Ôó\Œa¥p‹}TZ×8mÿÈÕï9Z%$n/èĞ“×E£}n'DI…4úmœ.¸S@uéÖ€û¥„TúIİbc%«­%Ğ‘OÂg¿1‹'-P A[E¼k1×ñ¼»–ÏcEsm
ıÜÍS~bi$Î¾—¥¹ÜüüZ:}—<­	SO–`‘ØzÇ1ßö8Ï@ç1»Ûotætš¦!2ÍÓÛ4šx0Ÿ†	J—)<öaI-Ò·èm¨J–(] /q¡£”+äÈçvXÊ	±ôØ_ƒíˆ!æYˆæ‘±zP»ãããœFæl§çÅ¹ùÍõÚv½–¤÷@6?ÿı4 Ÿ7øgTÿÅåÒJ©T¢ş?VŠÿWñÄP»ŒÁş?
K‹+E>ş«…ÅÂ2ŒÿÒêÒòÄÿÇU<Ó?¡Æƒ/¨9ÚhkôH`›Ùh­‘™±£õİ”T.ûhƒŠBn˜Ø=º^ı”Ôùš4w¿ZŸ‡<uMo£¯Œıì‡-½¿@ŞvCššç5œ~»½@ê°p}©;èzdì•F…D=k³x_é{ Îğ÷uO?D½4]È£óhêi9¶D}äñ>Àer×Z†ççÙÔ\oÙÜ?a#PE“ó\ ¾` {ú‘ëTD¼``J€#zjÇ-nä}26Øö@êâ%JFBÔ2ÛºœæÇÀpuNƒ<„!Äı`¤:Ş!‚v’´c?YƒŸÅ÷s…Õ\©P\¹˜™œÖ]¸{²âTÈü¼ØîÃ„8¦–{(q ~–ú_	ìD$lz"*ÀĞ#aµw>‚&|=°NÅCNñ0ÔŠ«-~ı—ûõ<ùé‡xHG-Æ):ß>S\ÏWÌds¬Ì}¡ÇÁM¨BöÁLÚE£ã@&–JF= Ã‡Uò´6Û§on°È£¿¨ìoìlç „BíÚ®kÈ8\ÉÄ„÷	Œ^Håö®tÊÏúı‚r¾’FqF¬$œ¨c„PªL=»çÈ‘ª/f·ªÅ¶9t¿Úõ±©—?¥ª)ê˜ØúEùRƒå3	+?|“_Z“FE:b9Bµ%2jénæ¹Pc^Š/zŞ&áÃÓ5zxEA£×e£Xå\7T¦j×‡—©ßÇÈíaJ…ÍĞÆ@´xËqš"®Ú,ØÓ|iÖ	nÛ8aw‚·¸:U<äÆÎM?Œä÷&n*ÕGšº	ƒÅK(cˆü_(­ğı_	¾­âşo©¸´8‘ÿ¯äùÖ÷¾=õÎÔÔ–Ö$;uò™à˜6uş•àßoàşş·FCYÙßßã_1Ç¿ÿn‡@RAú@rÈ¡@=g‚Ô‰öx1iz·€Ú_×Ÿµ?ù¿şøBíœ<±Oè2î¥”1dş¯.—VCóqu2ÿ¯æ¹¬ıÿ¥i ŞR@’àíV ¨WêğkÅâÖ=± öGIfù,dxğˆã»i‹Õ$ğ] ºÔ¼êÛ˜Éá1(rwxuÙJ„7@ ‚b8:éw`ósöÂpêœXö’ÀãÊ^ù1Ş^{Å…#ız±<û¬ÿÑ³ÎÚ³ã<yrdÿœÌ
Èf«
¼Ñâ]ú ²t£6H6•%£”d4bã¥I Í0@Ç„Ç!`;±°€™ŒmÂH»T9T#-üŠ;‹á  ÈQD2 ‡d±õ“i'úÑŞâcµÈ°ZtÔa#ñp´&Kš„êÆ?¼¾já”k	ÜH:	Aí3jó’€€RFãˆN“uº­ÅóĞş%ZöJvv?Û‰@ÇóF}éOZnDtÑ©š´Œ¿<ù²<K¿f)‹†5Ãš½ÈÃšEívPíäí£‡öj ;jˆ‡¡èx¤s–}ÆûX`:Åé@eÒ47?(0Ûšä\`Öê ijoMú6#s„Œô¯GD!°^
N§(F†“¡pvE¡0ğÜlÚ3:q
ÕÚ0ü9#A7C³	À[QºŒHğZk$v{ÔˆU€¤®óÙ‘ßkí^yÖøè'Ú–*…“ïà0IĞU›x=dsã®f¬Í¯©›t(WÅ-’»“¥i›¶SÖúíÄ£iøï†Àô?ÉeIqØ\“ƒÏ˜¹K’ĞÀÉ"¥‚P‹ÏDüñ4 }aÙ–ƒ‰!ÏÅ‚ìúÙ²S“0)»£÷Î†@2Ò
°¸gÃØ	G†]=2"‰<­áw5ÄbdÑ÷‰¢N@ë¯ò¬b
–Í
;0B¹ş‚DÊçe³ÉlÖs`e¨˜Ğ,p†Vu›dšV9¸±EÑ:ş^SaÚ7¸”kâö»×[x	uèjÎ‰¨VË…yê›’^Sß =*Ö"Æò4›¥Î£á¡™'¨• qõ`¡ÖRcfæÄ×ùÁÍ™}{´Ì²şW6zg#ê‹‹‹¥¥•%RÀğ?“ø/Wó¼áú_‹ëÿşo×§/ÔÎÉûÄ;_oCæiu52ÿáÛdş_Å3Ñÿ^¯şWqyú•TËV÷´ÁaU°|Un¢>ŞvuğHêÅëSŸ2Ínq ½Ñ«cïˆ‹mê±~˜Kº†v‚ÿ^–/o&ÿ/•YüÇÂJ×ÎB±´:‰ÿx5‹ÿ(97dV¤È¢-WçqíÂ%ş‚zØÛ…Š‰‹RbİO]â©ºå©Ë<uOÚ¦‹w+bÄßı{'=¼Å†Ğ¿ş`xyÂ®·×·ÒÓgK$}Y+.¾÷şZqeqem	µ÷Ş‡Ÿ€÷íÙ»ã‰w­>Ş2†ÉÿËËÒıŸBí¿–W'óÿJÉık¹ÿeğ¶Jş	7@âõÉ¯¤~5rzzÌ¢÷›#x³†ÕvŒéuóù¤Ã§\v…Ñîÿ‚Ø¿´Z(éıßåÕÉıß«x‚8—WÆˆãû¿%ø‹ö¿ 1NÆÿ*PÔŸK)ãìóqµXšŒÿU<Rœ’ƒ\µ~@Ã1¹ŒaúŸâ*Ÿÿ¥åÕåÕzÿ¿Tœìÿ®äåü÷Á;ÿ}‰ÄGá3]ÿ‘Î_Š\“çÍ|¤ùI³Øü/-
Káù¿Œëÿdş_É“ºßoa^Ã×Sìóö?zƒÿ‹<ïğÏLQÛ`Ş”n¶‹õ¦İí»Â“gòLÉ3y&ÏäË“b7n]o5&Ïä™<oàƒüğÏøç±Ïÿÿü¦”ç6ÿ$üó#şùGì3ÅáŞáŸßäŸ7øçmşIøçGüóØ'gZ)¾ùHñ’S|‡’â
ŠáŸ©É“gò|­Ü»ÿÎTsÊ™Ò§´èşıwşnø}×®V[}¯95õ7ÿÚßû57ú¾5ğ}¯#ã§³•½·§¬©ÜTK-ÿÛ7Âï¥òïşƒ?;É/•û>¦üo@İ¼©fãØí5Lm"ÿ«FÏ4\¯PøRï|ã›ßúoß¸qãÖ?qãy½c×éõ²ûšóa@Äÿ¾oÛ¦ÿ]k<6ôãƒÛ¿¿.ÊÑÌFKgO«eß·ûVË}*½¸yóæ›·øêÕÒûKdq¥pº@^…÷ÈÊòÒééÍß¿S,oüª{òå«×§¿ùK¬‚-Nı^h|ÿrĞ>µg—~(½qÖYËßùoDËÿGÑò›é[·şÄ­O7?İÚŞ9¸}»ïê{ºI=Æ¡‰{pû÷Ğ=úFÓ¶vıšü¤‰‘ğ,xó¦fb°O¯˜fİø’A7Û4wm×@cÏ?Ãó||yõÙ/\ÛñÖ)²ÏÀÏ ¾‹eìP×ô.w³}óæ¿ñ»ßÿÃ™¹liõÃÊƒßşŞíï|÷ÖïßúŞ´`i˜ú£c£åu>×Ü¦Nã¹ÿºÚÂ@\ºsó;ïüàæ>ŞîûíwğÃıÁß}7-°|Öo¿îŞÉíé7X?ywúæí?¾ñ¯.mÙ-êN¾y÷'ïÎŞ¸ñÓ×é½øÖo¿{û;¿7÷İ[û.´â¶vã&MÉåoİÚ´pÛ½ÉR—n½ûÈÔºy»uóMzïı[ï>áæ'·?å‰å{·ŞıŒ»‹w¿“Z¸Éêôîú»µ·ÿ‹¿Ä²Ñœg§§[Pü~ğC¬ÕÆŸã›J«¥·nú—«¦?šc_hWLÄ•°·qU~wª0uê“©_Nõ¦N¦şÜÔ?;õW¦şúÔOı;SÿñÔ=õßOı­©¿;õ÷¦şşÔÿ1õNı?©TêÛ©ï¤~˜Ê¤fRwR?MåS…T)µ˜ú(µ‘ú$õiêIêW)=ÕNuRFÊI§NR_¦^¥şLêŸLıS©?Ÿú©.õWRÿrê¯¦ş•Ô¿™úãÔßHı{©?õŸ¤şÓÔ–úÏS3õ?§ş—ÔßNıo©ÿ=õ§şÁ;ßx‡k,ßÔ¿«ÿ;¿«Ğ8Ÿİïü3	4şñÆÇŸ|úÓ7–ÆÿÖïâ ÿÃ¿ÿ|ïûäÎİÜâ{åû>„†[¡H™)õ1ò¢d'ÈŠM6nıaÒÄy9ô—7Únû·ğÃıà'™ÿø6ÒÛúó§³?¾u;Sâ&ıù³Yxû¼CÄ·
?.İÂ¿ıVÎò­Õ@â·¿ÅŞ®İúğ&L‚Ûßdo~«rhıöïPDëÕ[·nOá\½9”h’ì9õßMım ×ÿwêÿK}+•N}7õıIÍ¥r©÷R÷R?OİO­§j©íÔnj/UOí§§RZª‘j¦Ì”•²S=J°¯S§©?ú'R6õç€l‘hÿùÔ_JıåÔ¿˜úWSÿZê¯¥şuJ¼ÿ.îúSÿï›úmˆT7URMıO©JKÜ¿ı»ÿØ÷şQùM+áº¬ıEiY;ª;–i[í)&µsÊœjMS‡êrğÍ?ßÅ,²Ò»Èë¿‹Y\oÁ;{ªM`‰ Ñeş›7’!cê’©YdL='Ïä™<“gòL¯ÉóöAPÿ_K>ÿŸ<“gò|…ŸÔ7«õêı)ÿ@0ò ®À¿_‰SƒŞaCs<Í7ézc&ûÿÉşÿk¾ÿŸ<_ß'°ÿ½¼H£ßÿY^-èıŸåååÉı«x‚ñ‡ÅÈÊµ.ƒÎ~ÿCANÆÿ*Éş_À6Ö2†Üÿ)Š«ÌÿÛÒòÊr	ÇyiiibÿÏ´xo=?äÁûDœlôÙuèG7ÉStAôF0N“<ÿ Á­ôÍ\˜>4Õ#—9DoR‡è²;.DŠ=ïõ{Ên;Z×M§w+û—gğïÚº3Êç|Wß<z{‘ º^ïèÍAä<DmÚ’íÇ)dõÎH^Ä3¤L2¿ö„ˆ–s¥”°2!¹8x£›®NôfÇ&™ÚŞŞÎúFaibsBg±ş‘3Dr6¯â¡gk÷&ó'uzzhæ¯—ï›É£Üÿ…Ih{è&dÜBÀÙ×X&÷¿¯ä‘å?T\£ü·T,,®VÑÿÛRii"ÿ_Éöq@¬åz'ã(cˆü·¸¸Dıÿé¿Æ[-Lî_Í3.Ÿ9aÇ\Ö¡£¹Óoz}Gçü[¤®;Gsäzm>¹Âî¸B?^_\Jî°.XòVsÅR®°r¿v³Ug.n=[ÄÖ¡•%U=Ş†|mÅ:ÊÚ„N·|w½Õê&)æ
ägäáî&òÇÙ·B×Ìëâê:iqxóH‡yØ¢~›0Ê
1,øÚåş¾,9ØÍ÷{¨¬FJÙß©îä‚Ö©¦F—n"lW¼c]§[´›hú”!WÃæÚº77[İÙªlllW¶j³$µÛ=`ù2óAOó:Càæ äû…besówÜ¹C¤ZÌ§iô
ù†Œ†åÍ…±²¸;£‘®Â^;3/2»®)òÊ\¯oJùKAş>îí’šÃò>ª×ö0ã±Ş éÒhfüŠÃŒ÷ófx-+õú“½*l`Ò=+4Ëè›ÎV
»FŞqŸÏ†:ãƒø®èæ8@ ¸%%!ğ wÃĞĞ<GšwgáQĞ?±è±ÿh‰$	{ ƒèZO6ëbş³ÊXÊkï¦Íİ«ú]-õÃBšD1NAŸ°lAÊ…”"¤Ò/ƒ2bOmK“+èŸa¹‚^+Gú©ö¸ôÒşu/±oô¿ÿş5Æ2†È°
Föÿ?WôL‚>\uĞ‡·Ö×ë¦`¾ÓV¶ºP·®‡Ì)·ì»4ì–ûX½êˆÅ\±p¥@v+äµ^/ÏBr=+:ÚDçã,)†{È”Ü# ²gğ]/ñğß¹AtfJÛ~A±,/Óh R^.^¤O'Šß¯é9ÿïÒOŸaúŸ¥Èú¿´²2ñÿ~%ÏdıŸ¬ÿ£Fyñ…İ`ñ&ë½T…qã;Öõæ	9ì›&aò:Â×à—Ó·|ù< ÖxNü>¹ÿ¡û˜¸AâÅ~p,·C²yğhs“d»Hçt«¡åšrïÉ{İ¡¸J÷~ZL_B÷µ4zÏ°št©]_'J‹KË+çêÎíõ½ÚVm{¿ò¦ô*7½¸º,•hOŞµÿ¸ØŒıw–»îuøºÕşóØt¨î:ç²ƒš±”1Lş[.-qùoy©¸JÏÿ¨ıßDş»üglÃwñğ¥3,å˜¬$€¡„“¤µ\œÌ¶ ŠkDóHHb“%2¢°šƒ¾èyôa$‘LÀéÉœ,…‰7@¦‘/xØ‡ä‘=­–æ@»MÏ$º…‡Z¬¥¡†JÒ›È§Då¤A|à®TAãE´GÈ*Æ86ÔOUlAœ7$	İÁŞÉ=É˜Ï‘Jë˜„¶cÃ
¶}
––…®5ôC<RÄÍ,K^.=­@o°ØBÔ¼‘…]SŞ»ı–Mš½(À¢ã:yÓhäy3ùg>T@õ.ÅÏrÆ?*Ù…ºÊ¥pØú–®5= .oôRZ<û°bêh)c%]Íêkæ@äÔˆsÔvïì˜í˜‘ ˆÇÈöBçÒ@ô”Â`~ŞÇ}Ä*ßFÀÃcWG7u’ŠÀ^v*X¥E>u—tìc<´
bc½ÓO‘<OWuFÅPÿ2RF B6¦Ÿh–ç–-İ;¶9§¶î¥+‡î„Iú)çËÏÓû'=½ì0Áõ4±•™˜•~ˆ°lóğ\é'&™?‹Ëa±§-šï]ÿ,kÈÆÓµ—z“ÒÜÙóæ)Ù=Ñ›xˆ–«™İ;®Åg÷dtP/«¥9­¾×ë{e JÔ¯B?qòœö.î¹Ëİ¾éY,†wçu¯égyTùOÄ¤:Æ8Cä¿¥Å•"ÿ¸ZX,,ƒü·²º´8‘ÿ®â™Ä¼–øÊ,{k5‚	ÑÉ$úãy*õÅÓ&0%»k|Ézá¼ØîÃ„8&'v„­¼<hFWìÚP—cM’¡`Kw4a¬Ô
PlnÇ¿ÈÒĞƒ{5×›uA"b×Ï[0’ ğ¸ü
‘(K‘Ë):ÿÊ	ÑÛ9uõR•¹ßÑU‚`Òfhı€¿#ÇüÑ@êÒ4Ã¤J%›ØVÉÓÚ„†LßÜ<XTßßÙÚøEecgö
j×vé•w©§p/£ô	ÜÙ«¬oÖØ¥#¾af„Xßú`=ƒMÊ‚˜..öRHRa8Å-¦`‡àÄû<ƒJò‘U+û•2Dìœ°u-ÍÓ|EŞ‚zÄïúØü`ó´RÕDÎäú‰Êäm!oğú§vE»%¬\o;'”G-)£=8¡Ú‰ù®Ñj™ú±æè2ê[Oús¡Æ¼ß'•Ç¹¢
¾/€˜aÑeEoî<Ñ…f‚ oQÏdÓÄ29AF_m} >”9C-d`3Rµ)`V¼°c=†|½A™¶Kå-®NïæÆÎM?Œä÷¾¶ŠŞ„G•ÿ9CÍ9î8ƒ6‘ÿñº¿Ğÿ–J…µÿ[œÄÿº’çimûáÆvíyzOw{Àéuv¼Ë=Í”‹¹û/ıôam»¶·±ş<]¯­?ÚÛØÿüàÑ.ğŞZıàñFå`ësÆÜêvÑ\¼|¨™îø#ÉMq?qûÿ1nıé3dş¯.—VÙş¿TZ)ĞóŸåÕ¥‰ıï•<—µÿŸ˜ÅT;Fğv+ ÖC`ºr€l(¼P¯xf{­
·ŠúºqzTõUØn¬&ïáªoÍÔ¯·è.F.F²ƒÇûû«YT!XG×btµj<@)¼pÉ4‹<ö{ı<mªŸXö’ÀãÊ^ù±föõ±W\xõ¨Ë³Ïú=ë¬=;Î“§Ìe…Øx>'³²Ùê”ám°©:Şhe5ß½d&4Ê’/Œ ÙäÉ›;ë•ÍÓQJ2á¢B(f€¹ $¾É’`;±°€™Œövn i7‚*‡j¤…_åéå) ’ ¼;D? ‡d±õ“i'nl'W«`Fˆõí£v‰‡£5YÒ$T7öüáõU§\KàæC$%#¨}†âkE sank™»›/©»Î	ül'z Ïô¥?i+ÜéÎE'“:i+~yòey–~ÍRk†5{	,ßP„Œ•K9³ÖìPµ“Ğş¤1Õ@Í_Ğ™›õıÓ4!-;ÍT˜}ÆÁí@eÒ-ÛÒ¹³ä ³Í‰å³>PG IS;xkÒ·™#d¤·9¨Aë¥@átŠBAª…³+
© åƒ¸F…jm˜‰@şœ‘ ›ƒ¡Ù„à­(]FG$x­5»=jÄ‚*@R×ùìÈïµv¯<ÛÖ=z/ÕoPÛî°T¦S=@šxoĞô¯£›=‘]µ¹,isv²åubÂÌƒµù5½™îåÊ³ø¢Erwa²4mÓvÊZß³}€x4ÿ½Ã˜ã'¹,)›krpà3w¡2f˜$k‘RÁ‡	¨Åg"~ÇxĞ>ËsˆÙ–ƒ‰!¯5Q›d×Ï–]wÛ‘²;zïl ƒi°»Ê÷l8\jD„Å‘a—g…xaxZÃï*øÙï1²èûDÑ'@e^”g»Ô>)‹?pà:¶ëQ— ”á/H¤|~†.!”æ!És`e¨˜Ğ,p†Vu›dšV9°~âfOş^\i¦ÂôÌî“êÁƒÍš\·ß½ŞÊÀK¨CWsNDµZ.ÌSøÃTÆ×Ô7-×q±5v7²SçÑF•]	*BA%ùŞqë °ä¼—Ü˜™9ñu~psfß-sHÿãh¸õB¯{c,c˜şRıïâêVV'öWòÖìa®À˜Gl§(=p€4JnmÅ
ìºk?y.úÄÛÑ½ÌØÔÀÃü?¬®˜ÿ×ÅÅÒÒ
ÎÿÕÅÅÂdş_Å3Ñÿ^¯şWk_M50kàPmpXŒê‰:øâUxÛÕÁ#©¯O}FÈ4Á.”ŞP³@ÆŞÛÔcı0ûI-…dï‘õvÇã^c†ÉÿK¥Eÿa¥ èÿauy"ÿ_É3M,cà”s3+HR$k
ë¥k¾(ñ›ÕÊ.u…‡‰‹RbİO]â©£=L]æ©{Ò6]¼[wÁîß;ééDo#ôÙÙÀ?Õz­F˜ëúVzú¬s‰¤Q±Ó²›/tg­¸øŞûkÅ•Å•µ%xÖŞ{~Ş·gï>'2ÿsÕÚƒÊ£Íıƒ+“ÿ——¹ÿçåÒ
,xÿcyuy2ÿ¯â™Üÿ¸–û¡YöÖJş	7@âõÉ¯¤~5rzzÌ¢÷›#x³†ÕvŒéuóù¤'²şˆúñ¹ ²ş/./¯úş?–—Pş_]YœØ^É3ñÿ!ûÿˆ£ÿôÄHğ\–¿Ócœ~,øøè)¬‚árÜÄ‘Áåz ‰'¼PgÅ	È%]ÀÈHØÏé
$÷yÂWÆˆ¬»¹\G ’´ZŞÙ­mWëş½Ær†Î¼Ê˜ÿ¢õ¢˜{/W8(.-å3ªóbp)”Ê Í–«å.sõ‘m¡dùë¾•”]}Éi÷Â÷tŒÃw†¬ÎH[ ‰÷ò¶º‘üÿ·ŒCÚ=ã I;‡	c)c˜ş§°¸òÿ»ZX.Mä¿«x&‡´áj‡U5Ê|xk5U®¤‘¼®ù¢9Ş,œÀ;Q”şa-Î×Å£oº]Øj–¡û¼6Òáü°vºÕ\#~bÚn O©¦	?€Rœ¶f	ïÊXIÆ¦U¦k§»‡»	ìu4{¨¤¦¹n[ˆúºãcŞÕmX¨1³×gÂ|İ¬iòLÉ3y&Ïä™<“gòLÉ3æçÿè‚¢Æ 0 