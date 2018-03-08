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
‹ –£¡Z í½]sÛH¶ è™İ;—O³ó0111›M©Z’[$~JrÉİ´E»Ô­¯åªÛ×vë‚ H¡Ll ”¬²Õ1±3¯û¶±¿`æ§Ì/˜˜÷yÙ°çä	€’(ÙUTÙ&ÁÌ“'3O<yò|ô·òäMÓZ¡ÿ6Ù¿ZµÎşåÑkÕzMk6zhºŞhVŸÆC#†Ï$P	<{f9(ÖïÏø÷#ú÷gòô`ş½‰uİ'A9¸x€6fÏµ¡ÁœÓù¨ê:Ì?Bã	Ñ —Ôó+Ÿÿ•ßTzFpQX!¥å= mußÚ!«K{æ;—†å¤ız“¼˜kÙ³/í¡7ÙnH~Kº“ñØóC²şb¯»uº†=°}Û	Bß›T·7É–Ş¨’×C#{şd0Ø$İ+'üÉö‡†k-é#cd—Ù³C”?¶'á…çó»¡İ7\rl_øC‡¬{v°Aú®ìÑwù ”Moµ;–FµWŒ |ya¸ÛzqÍ†Ïã¶åø+rj_:ã¹©"âVìdâ½Àf^ Í®é;ã„ØğÏ…Mºæš6a=$F@|;œ¸Äô,GÂí@`svó0ğid8îğšLÛ"}Ï'¶{éøK'&çÂ›„äìû½4?Q¼û0­Ğ»Ãq°S© ä¤‡£Sa# ‹·—>­0<ä; *Ï¿Ş¯š^Ö¶ËUMoB€£²ï:¡cÉ¥íã0B½ZÖu,ÓeÚÖÀ…pmø„…=—x}¤èhùg‰¼„F½‘ó“b÷^°?ÒÅvüfïüôøøì|ïhwõ“ôm§T²	¸ôÊ?(ŞP:®…}¼?
nÖÈd’ïáÄîÑ¡Â÷ÓîşñÑ.Ìfaï¸}rÒ9ÚÛ-¾éÉ‚Ï
Ğ®ÑÚdèHßÆxlcØ/»İâ«öA÷ğ€6z°ÉWS÷åéşÉÙùQû°³»ºîŸ!«ÚFáìğä|oÿ´óòìøôÏ»ÅJ8éËWûĞúê'¥ÀME­^^]-ºgíÓ³óï:í½Îén‘~CödÀTÃ´­~’Z¿!ëß3
‡÷|øn6èš%«O‹…ÃöşA{oï´ÓíîMÿÁóXeó¢Ğ9==>İÕ
2EÜ&¸W×D¢º10pË]}}y{}ƒ|JòÖ='kV`É­#9ETH‰š¾Úóƒ)î½:&;¬áÍä$¿-]\ú¤äoquïM½ì<'¥=ò-ˆÖŞ|ş‘}>Õ~åùÖ+ şçä}V#„”.²ˆ6NÖCÜF°¹Ã·)Õ/³ªg¬”)Õı¬êæ…m~ Ûo‡IùÒ R¿ãGï%’ï1İİ=Ç·MÜ$È¡áBoü)à2‡î¼!cşŠò’)µSÓ‚¼MˆmÉYõ¼eO°Á:8~Üá†•súä-¼ÔoHi¼†û»[İ|9´·íZÿqâ„¬Üê§êıÙÂ^+Ê%8^v}Ğ÷}§pSXú^—¹´a1:#*°ŒÆµÔé¨¯o>Ñ~î¼9ƒMRÿfçéMÒd]ãƒM@²õ¯a1¸Ò³á‹­	ü†œ‚º±+#ÈÄ ®2YÜOJàÀ|7	lnÑœá)nr¶Ø9::<Å±„÷ÍŸKßŒJßXçß|·óÍáÎ7İâÆ³gRÕÓÓéUİ9•éîµïĞîñŸ°U¥İbQ.ğ”ı®(g<¢’f¼ŠtCC
¾)’]ÂÅ€äbE…¸0«,mÃ¼ğ°|Œ.¢"ùÚ6)ÒzŒj*ëj6˜¨,)ñ1¸púaôíê×=Å›ıàKqµ<¥‰Ûö,F+ñrnï2{8œRTêiº·–çÚiŞ´Äi{ş<«O_Ùèg#¹øà=X¤¼! PD’¬› “1°Aà^À?:áGó6¾á‰gÉ:²ã¨¸¶í¹È]a§MIÏ2»Ò¥âÀQ¡xºI^‚CA—Ép$cäM\*‰ş`‚Gä Lº°¸&t[Cönz>Êf¯,7Q]´	˜¬ãÖ¾±(üÆ\ø²TBÅ 1ô]/¤“àvFgí7š‚/§í—Hº9Ñî&zn«´m'°C
Xyi\Î¥G¥?º>òKo2´(„Ğ›˜ìÄ‡ıR†ı`†a‘w«Ÿ¾;ò¨”’2¸ÚÜşv=Øí;ìpŞ‡Ù–\¿>·~Ç÷a„‹Jjõ¹½aÕéìú×Eù…ë„Lo42\\õà¬@Ñ3¡ÖæA=t‚€JVi)[¦èEh+AÑ8nQÔTàº6c‰ßA†6ïµÃ=ŞÀA™/‘hI(ÄÖXp<a¡JcˆË:Ñ¥	ÀäqGÇ”õYIT¯À·
”hC#dâGì%á¿½½‘8©ü•dW†ë$ ùıÂ=e™ş~.Ûyã~p½+—u}Š¼WÂÂBQr“bş*N§öÈ»±ÚFš­ù¨j,œø#dõyÅ²/+îd8ŒŠ¬ÀˆRPŞÄ«$†jMlTÂæçù†	/^L2tÔî ³Äj>-ã”d5#—•¦0»ßÔ!Óñ+pµİñ«åhV˜’†kHï¯‡hŒ6#‹‡1R˜XXQxàó¯B¤Å˜H¥ŠSŒúX,ÉSQÎ*•5•ãnUÎ»}‡B„;4¡OwÂéè’ÏŸá—ß’•øYFPiU× 5lë —¹¤`/”Éêz¹`¼%–¨>0RBo$¹éA!H~Îäê„—1QÑ3tŒªb	#lÿŒ…T…*™dö{X£E¹Œüö·8MW¤(é.”î'´·…hFÔqÑå¥3³IN*f²cÔ¿’eàç^ºw‰úCß“¢Ò±ºVÄ3~¡À¹Œº¤ÓÅÂ(¨#—PÚÄœ€´çR5tÉSäãÂdB\o;ôÆ@¶jı±ïáòÃ–ïÒCá±á1„¨cç!^›\\:;{;?îtv|”B£c°á,`]2¡&m—	9]úÍÙ ‡×2!#™ŸÀĞ¼VöĞ=,Çô{SJü(JÈ*»)eırÚ99ØÙ>ÃË…V•*³¡ü^t¶JVŸÊ=£EÜBíòŒKAbió‰E)Y–
e…ÙÀ^nÃ
·"`\¢HVUĞœKç$ZÉ°ª«°Óÿ¯şÚº Â±qsÁ÷Fœõp2ı•Ï:™)c× ©!À2´S‚ÃdoÈ3XL¼³ÏX)gú`û‰±™Å¢MâÊ†áºÄ2Iê+D$‹CÀ>î”Š™Zè›BõŠjòK °úéä‡=Ş‘6L¿á[dºü¬]¨^KOßÂÕÄ¢pÙ„Tš$ğ/Y*±ëäRßwl §kxãz%`@£qH?ŸøŞØöCÇSxÅÆ(îÈŞ Ï^Ë}"™…‚¡’iˆú¹JTI
/dÓ8vŒ!{:¯ëJqN%¿Pˆßo6,ø›Ánêñ:oÚKY*Y­”*k2%B­=Ø^æ(Kö÷˜²|4†Îï6Ñô"Q9¦²)œ^BûcˆşjåÓÑ³ òÎ­Ê³›)°¡ÃàÏü^jG˜ù¤ZIPÔ	Û†”åÆ.TVøµO×ö/á¼…¤×•çd} â2`c’µT~)j[JÛ‚…HsÒ¶ÒvZ§r1-)pñ	60ã£â?*¨cGÄ²<âìµOè_İh+UG†1–p«Ÿ~’iÿğ§óc¼µX7®>µ×ûGŸN»»Åwnéœİ^ÑÅgû¯O;/a{ØÕŸ±£Öno‡tò7RùKÛ²|˜ƒ
rÖÕ*¾z÷í¶²öîy…|‚N­¯ÖØëë¼ßàp´gä/,>ÑC	}§Î8Ù ¸*ë.èÕ•³ÓĞSÒüü)JO“NGIôêF,mùÓt·ÎnñtöMc>;K›*à_Ò*‚&`ÑĞ…Ãø2¬étdÌ®~Uû´øN…Ğ2ëÎİ©¨&oõäDøöŞáş‘¼ùLİÇkä¸ldéİ+s®¦îaJ—¦Mk¦Bı³Z¯ªŸ]ÆCÛg|)$ ––®‡â3N¸7¤¢X,İZo‘ßühıUTC\‚ÖÕLb¿Wg_ª7ª
ébÿÔKóèDºŒdéKÛ¢æÏã?Âş›™ğ}ûïZ]«¢ı7|j5ªšÆì¿õÜşû1ÜşûÙGî—bÿÍ€EÄõœ,¿tÓï­2üÿ@¦ßz-YÑqCß³& `Â	9R£" `l›Nÿ:¶Ã‡AX¶•ÄrÍÇÙÆàKµ¿µø£ÚpÿŠL¸Ñ^;ÃZIá&Ü)SáîsR‘o¥†W‹›lßÇ^{qcí4ÎÀÙØä©`JíT÷¢Ú‡†3$\ï‘]=·‘~Ti’ÛHç6Ò$·‘Îm¤siÎ"ßz†Uv4æS7¾ÜBzüÜVù–¶ÊK²ãıV¥¹ıä/Ì~Šv¾ßk-9İĞ’µ@ µÜ„òT»d#J x{KIvúÕÉƒ™Bvœ5‡|[ÈîóÅ”4@«ëBÎe?£ê6¨¼Û¬¼#•ÁÆƒÙQ.ÅNòoJÇÙ^bn3X5gRCI—éì##ÌĞèeêEJièœ½äŒA‹p ÑŒ­Ó·ñ4k¨¨§±	²=êó"aÃvW{ä¬ıb7İPFA:çû]4`v]—dí/+k±ËÙgsæ:l;é½ˆÃíÓ#´ÎQ%!D
¼w}ŸçÈ=ˆ2ô°bº×>kßT¢ÛL\kâr«Ü¸#ñYJX|MsÈ¡°RG¨Ç^ùob êĞ9‡Xu(c@ÃòÓw•wëğ÷Æ;Ä¢ütµòN¯¬mÄ]“QÑˆ§MÑ•»6Î/-rºö,²æ5¨±a!ÌàkˆĞ}²¶¹Fà¿Îö¹ûk_Qvî¸‰	Ê[÷Ñ×7î;—VûÍvÌĞ„,<µ¢5—‚Vd®Ş˜xh°¨ŞÆau¼‡Äê‘·¥TyŠàÛUQé}ÌAWc@Aäò&×Ç çÚ}ò™Øb¹Ù«Ïô;(¡<Pöğr$(ÔÊ²(»q[fzÉ*•L©İõJ’+,{ÕJ+‚4o’À›ø¦-Ëlå˜D%~•)İ‰ŸU)/n@È{©¥gE{J¼ç~€—¤4¦Cÿ@M¿ööOU½„‚Öôc„®³åeşwÑoÅ”¥´Â^øËó ôQˆAÚYÇeV¥ùü8¸ ıSÏ7µv£nV‘ÈAæ^{ûv§74Ü;ïß¯m¤8¯µÙæ†ªrÍ!Èà/|˜Ù‹]´€SŞ V™,³VyWÜ|W¬¤@TÖq‰
|ÛPµllĞÎxêr7[r?_ı$&ãæ<Bí†	ô2èéÓĞ[=‰;Ä4ÇÁíïÅ½Nè9i½<><l£¬ÏDûG7±4´`1—J^ÒNPÏü¶]âB†ôYh¢œ<öXQá€Ë‚#;e4Ï÷Œk®1_ûİ7“58/¤EÇ6re#˜ú*B`V•É•†OÊ^0^†ÂØ’M+³¹Lk?W#ô€’¾ˆJtKr÷:‹WÏ°K!›;eÇ–ÅT›Ì
SŠÏ# ò‘”ªU9>İéDâÙTßã"N|Ió@>H|$××é‡ßé*ÈTŸOŸöÅÇ%˜˜x²ëÃ1û×	.l+©~'^Ñ¶ßcÇ²¼+wÄOÑı+V]N”¶Õ¶U.FÊÉ6}u¹¨$ ç‡]¢—¤Ü™Í9ëXˆïKuM“ÿ©É¥¨sS¡„^71§t
ñˆ$ì]eÂrü¿r«Waÿ‰D<™ø¿µF-²ÿÔk-´ÿ¬Öóø¿òäöŸ_Èş3Zp¿ûOÖ¡_¯ıg³ÿÏ±ÿÜ.k-¥Ì¡ñ#ŞÒ±p¹¬+nLÏíS]2|/Ev¤ïsƒÒiĞ~¥ZYÿÙF~T³Ò³?Ÿ`Ş,Ü!Ö)1g/k:»Û…?u:'»õÛÀáÀ&£,èŞ¶ı.Ö¶=. ¯£éàn±TŸÀ“…Vˆ«WCc[Ğşœ-hCò-’ê/ß–6êhôH+ŒàBEk•ı£—§ÃÎÑYû ·É½Õ~U6¹yÜâÜ&—¶‘Ûäæ6¹¹Mnék²É]È$77ÊÍrïf”Ëe»´QnnL;\nL›Óş¬Œi—ô+4¤wœÑNç!ÌhC8P5U¦1êcÙ.3|hn5š.˜[æV£?c«Q~=· Õ(Ë÷ *…¨8[?²9¶íË
>U`q.pw6†¨—¾J;RHÄ‘VÛE‚5ÔcN†iàŒ\ÙöâRU|á¨óÃùÎŸ%Ë›âFáø`/şÎ qÁ›Òê'¼¸ÙØ Õ_´_şéÍÉy·”Ç=‡F¡Qj‘oğ(A+¢961«rŒBFeuŠöR}ÆI¢U‘0ş"nøf>0¼š…]qâøÍ*‡,cH!«]Ê­‡É}í8UãÍ¯Ö9\Ê"çÛ€ÕiaxG £˜¾bÑEµUæ”D2ST»À 0kV‰kÅxã·RË#ŞP–-+‡Gõxâæ›˜
ftƒg˜ú°ÈÌ®~Rq‘*¥~ZĞ\T6%YsÇëàù¥çöA<`ÌÈLÔŒñ†i!¥“ŸÌş"cT‘ípÌr8ø‰ó^½"Ï§õzN×D2qÜ¢oÉªËèæ´¡]{§7´£ĞµŠa²ÀÓÑwÊ*}X¨×_yhÕ)°äÈ±ÑKÎñĞL&ùnìXÓÆ9k”¹Å1­„ÅñâÖÆÓ-_d.ê[/dPÌ[¹³Añ|câ”Î:éevy{á„¸İ„¦J2¨A·t>Mkñ†ÚëÀì”5è6Ÿa)>…¹%6ÿyöã]ä© YúX¤-!Ö)2IÚŒÜ‘’Ÿ½2çßÌLïÆ‘'w¡ïM@Ö_·å´€”ôÆÔ‹‘KiI¦Ş½ÜÔûÏ—6µı*4ş-ŸGjÖic¶ı·¦Õµ&Ú7´ªŞª6ªDÓkÍZ5·ÿ~”çïşÍ¿|òÏŸ<94LrÜ%ÿ X¾{ò÷ğ§
şüïÿì_,²}vvÊ>Ñÿüù×‰"ÿÿ¯<ùw ‡—ñxh—‡F¢0åWNºÆÿŠ=yò°ÜÈ0}Üm<âY2„S4åeÿ•ı÷‰²hÃÜÚû®e|òä/ıÛÄÒÿåÿüÏÿş«?
¡}’¹éÚ˜½ş›µfKK®ÿz-ÿı(Oîÿñeü?"KüŸ³ïSNQO\ô°EZ©Øs#™N6÷y/-íbÁér,Ç‰ —Bˆ'ø!§%djZÒòÌ¶Ÿé!‚@vxPŠW²û)˜«Ğ¿^ò sƒø˜¾7|ÍkîfĞº6MgMmë/™m}’Ò.£FĞVÃÉµ¥À.“%w‘ë¾;¦<Â½~Cñ¾(*Jçíîwçİã7§/;oµ÷pèLn™®Œ—÷h~#¾ÆT87#P­5Ö-Ç§%‹)ĞE€ıŒŒ¯,R:À­z7œ„xË^ hì«ÿH<Åàá\=f<+ä¦„üëÄ:}ï·?@¤ø¥Pr¶˜Ï‹‹L‚ª=°hPØë¼j¿9Àä?{,½½äCH5nE¥?ÌK…Ø¹Z-¥\…òrÒ•µT´{x¾wG\¥]ËC¦¦<?8~Ù>KÑh
SË¼ Ád¤RxcÌJÙ¡9µjÌD›ƒ©¥Î:‡'í³N——Å\‚Ô£,®qrz¼÷æå™Ü‹1u!%¨ì6’x‘şèJ¯–«e½\+k©‚¯˜Q˜iO;Tu¼ÿz·Èøã9½æAfX,$"r»2E~9c&n¦ÿ,&áæF&J©Â9-~ËZECú¶S’Ì¤n*Ñ5©&‡µƒ¥ML+K;¶+ÛjÍ˜¢H‹ÜIg7üYË)	K—BÊ‹rÄ(Øm	"¦ƒÌ¯¿¨ÂmjÙ|Søô94ÕXÂ`‰ç%jIXb•çW¯¤±wTãLyqüBÈ8pj5äÆw76È qßäé(ŞHàGN`2¸b `h´˜Ÿq˜ñ9²ûP‡6Á±U…b"¸«(VçÂMòÎ`…i&rÏf¹*x•Ñ2ğê»Yà3Ø´:bm_ ùkÖ|Ä\-^¥ø-5ÇRÃ)v©`•à“rwUÎ7(ŞÜ·Q…çJÿ±ı}[4}¾ec?—Zäñ}2µ(õ€+w^Ÿşùœ™ĞQ³%Dâ7hLyAÑÉ†ƒ=úã¥HË¶Ãkò<‘{|vögŒÄ{Ïnèw©´nRÓy7rDµ?Úæ„¢Qá¬2ªHE¸=¼·âéÍÕWn•ÌL§ø=BÂ>nJı·YVpÊ²ÿ7Å€áçÛáÄw‰Ìß-(<õò£E„iôcfŞv†¿³QàHX™ÑèõŸ…¶?Â&ˆß ¯Å‡ÇW›œ´Ï¾Cs½¾ã¡D[¦G½r`kòm„î„"O5'­RÚ	[^‰W·¿ïì#p cüçF²‹ÒbÆ¥Òw¡‰@Oğj)ä`uS½†±@!4f–‰tƒˆiDŞŸ‘L¤M¤˜ÕAaL¾ t#„ï†°ô¼µ„c62Y;ë-q™"FE˜3r•ÀˆGc—7OÙÈTLnHJô¸!"¾Œ¬b‰dÈY›I6HÎMé—[3ñ]Û¶Ğ#$`# âgjS|M“óN”ËåwÔÀœ‹Ñ`Šq¡B©ü*ú½E%ÚolãK9§ã
kªy4¡×™1Ú¢< ê½qlÚ;<Ø\ĞıÖë‡höú[ÂÊg E¨¥ÁöØ O’‰*¼'³oÇ¬€™fË8"{ìKFÓNò‘ix`nS¬Ç“S)Épæ%ÙºYĞ–^B[œ'âooOûvŞ*5ÔÄ20œm® „ÊÃë˜Š)ãã´œÁZQhô¸¨¢Øq+fæÑO*×OH)|ê{d¸×*Áªè@gƒXªñ}1‹çqH÷±½ïÍ3¹OL¹¯¾D\Ê%v
àd3Œ“9ñK´“¢ÁÕ$®L‚‘á‰*‘½Ò”DÚÔŠ÷$ZÈK¡À)Ô—áÿ‘ »[ÓÜ4z»=­İ•Î–Mc”¾ÌiB– TgÆe€$ÇšF+L’Ê³¸-ùƒ6"™Mİ
ı]  n‚·+§`u¶Ì«ã9¥‹ÕÅt`Sa¡¿P%o"Çºh$ô¬îg 3£{
(€ÅN¼w†Èùz|@³¶e¢Nèœ*¿ÖLQ<40'ù”¼ê¥ñä,|F6½FÒE‚ˆ,1œ#˜–³7è‰w9Æ–÷öOÏùEïƒó'¡¢…M¸æş&–â•Âô
ğªÂNü:µ³È­ÿş÷ñş'Ş‰ëBÆ5-ÏÂ³pÜëv:‹`É1´`r=Ô™Ş=>€GÃå!(‹ñ-t±À1Îìqo€½”ıF7R$RéÀU÷|ÃÚçTÃ›„•`:àe»Ãa™^F Ùö|?š—7ú˜#£ÙÃj'e¼Yá;Dw}5åTM6WD©Ì:Kk©ÁX-=¥½.ã¼<kòfÁ5™”Ùèƒ½ö	9AöL$T0²zR§E»jY^ô¼Û=HoSŸ‹ÌâT‘ªp*9Zğj¢ÂiçäëúQzºĞNz¸qø/asò†6!2*hN³S©HF	;´I<»£ßõ™Ö,ÚÍ,wGXÌ/em-=ø²uNÆémSŞ1ùÖÊ-1dÙò!6N6b8õÌ×<b¶:	³4øQ\åÅä˜+Ø‘Rú]êkÖSTS½EñYêïÂ•|¶‘Geâ5;]W!’PmÑçdé%]ÊñQßPÀİPU„|w`µy§T®¾î
²9äínÓ”ÉŒ6·³0#RÔÊÅŒê]íMeÕ‘˜IÒ³'@òˆ+üsÆ¾ã†}²öM©oJzÿnÒuü;À£bºG\É÷½„Ã^quıGÏqÏ{×¤…8nø¿H$ÑgJÈhÆUdNmñ&-}ãuùÜLšÑO$ÉÒü„, ÑÚ¬ˆX,œÓ= S
DxTæ3‘8tS¸‡Ğ±º>ÕÕ|Mv5_ƒ_Ô9Æç6ÎçSj£;ú'¹7²SzºİÄ)îk“ñÚ3æWÆ¾£¼é;÷P–0*nP
†ÆØúêúÍ…–Öï«ağåæ;u£îVŒH¦‚u¢¬vù ”b¢ó‚±Ç.N¥SA|2y€µÛ5İ¥§¹İU]İJşŒ£¿|°ËŞè¡Pîú·‹‚SÀHN¸Òájª¿­bjYêª•Ho$Ôllh2Í
’ª¬6\®Çg–³i LN†6ª¿íx€rÂá5U¯J•Òî½‰@Ò×TnÙ›ÇìIÚå—b²SIs±¾dŸÕ³ÏéûTa!Lİ² ó`§ŸÛfÆ·Q¦xÎ*ƒ’9£i}URW%åÄƒ7&%—¬U¨ª5¨g‹ë¹.9*›•¿¬VÆkƒè `%³?(ám“íÒÜ}ü´€—!ÊyF´œj“7‚í}GÃE,³5~‚RZì>p“§“T'eõÏ2Gõaù™DŒ‹ó³koâ³¥Y^„Ÿ­†ë›~ˆ]fĞî*HûØĞÀÔ@MÜ)%¹£LâÒÁ¥ux¤ó§T—„2zmk;»#§èØ…e›µæ”²”>‰Pvk[{w¾}?VÌÚ	’jâ):âD­¤Ú1¥¤K”•õ™êU©|RÅ:E¿*ÕHêXS
Ö‡ÅÇØ'ctd?çê¬ÔşÈ~¦Ë­q¾üïåüB$±—e¥ÙTE?ú8Wf’N7h]=­eÌ)V+æ»w‰WLG½ÑéD;mí¬ªÃR”û6_fÄhXV²'h,0P\oI?>ç4×¦„ş€*ğ{˜¡Wîiá,#Ç©[²?¥à	Cº;A+„Î-Û9úş~n¨1X1ßtÏÑíqÙ”í©ïKp‚¿‰+©„WRß'*EæÒ³+ÙUŞ¿85Í(ïÅ¥¬T\y¿„:±y¼ŠVô>Q^˜'»!Ş'ŠËÎrqé}vás“¬!Ş—Ö ÚZºÒ•]õä—lIb1Jé}ºŠªo«¨ïg4•¨w>kvR§ª¬z]C–˜ä¬»\›Q”ç$Oeï³* »Í‚ï³ŠÏÎ,ï•â2éİÚCäñ;ñ‘}–E°ˆ°x7ÈYû”ºó»G^¢;FXà&ğïV%‚­pWd{à©IÊ^S“Ø6 ‹ô—€1I`bÆÜªğv"×¦éÁ”ûSzÜ@•è–5¸àQFd¢@b{D6­Ä^Ä6)	Ä…
"ˆÌTñoòr$®Ï#@,Ğ[?*@C+¤&*ˆ©ˆ‰cAÊP=á†å6„¤ÇRbŞò"¯O5%ŸÄ¦¹+øÛ>£7j IC¹ò JêlQ(XA~¤•@J¥eŸòş=IÈšíƒıvŸ–§V¤€7$ÖËO7v××ŠğßçâFù)5%%ñ£®R×º©0ÖWÆêçueÀl¬VŞU+kP>ñOp`De{|^ä÷Š0ıß”tß$34ü«Ÿh§’wˆø#ğ7ŠiŞ2-ôL*P®ôÀ#n;ÓW‡„_ˆáû@îöÚ}ˆKBæ¾ÿ
³+èÅg,Ô3!t?…7Øy8Z…MÕƒB8æ^Æ±3@\Ó™Š>U`<«DB±yfø€‘ôº*İœb¹ÒT½†¢ƒRªà†"ÆBx|HJ%t<´ıèkä)Ñµ‚NİÅJTZJ/½ÑÈsO€™í®ª]^¡ç×»¢åNí vöİbQz/1Ì·YıZY¡ó>fõııû„­Œë‘‘š›dd.rV#„¹–C•&Š¦Û¡påÙ¯$Ó–!3b-²îÛ4´TYbyñ H¡c$ì%Ÿº•Ako1Ì®løßeq½7Ù ²qUXàaÇ(jØè~"«lHi÷SJ1ÜåòÓ¸P…Ké‚˜çXÜ®Ô':•bºı¦Î®C]q¶}yæ%¾ğ">G¢1ôç >†	ˆ¸…=dFøì6%š”M^™cLüÙõÜ’T„–xåùW†oñ9›Myœ8D!óMê>¦›xèAİ¾Zøü¸ÒüPaöNj6=p‰qË×÷@B]tè$bL2êbÓí|’€ìèêFÊ7A’Yly‰•äLXâºhA'A á€Îv¤¿Nì ãù+n öG³îÄ)—®Úc7®}¥ÈßÓö¿aãÏ»g§‹˜Â)8£¸\Ê!ì“ÜÈdA§§LçTÈ6	œS©–¨$nûæTKØ1ò›¬9•3ÌçT]º9a‚"0«Ï˜&ñCD½Ûê¹“0Ó\pÚ…Ê]Ì‹f5œ2tœŞğoÎ;w%ÃP!	rfqgw¬zõ',È"GÂòH¹ƒà7Q­nÂNB3B‘†[]B`qU5™È¶ä)n$áá›vÅ8ı:sÚEcò½JIÒ.(E(™=§•Lz_QÜİÓÊºˆñgøKO¡‡¬ˆNé	_ÑD0dùc8FXGì!s—MY©K²@¦ÛQ¢©«f¼#™ï(fÁ;±ê?'Ù(æõà»_öPµçÜQ‘13ğíKöbÚ‡ØzF5< J…l;Î¡ÂıÿMK™ ¦¥Ş iÛfç¤Gñµ'Qò•¾Š³*I‘èÿ…à]¹µğy4/a~=Ké‹¯„%2ç/B¤K£K<÷Áz>í´Ï¢¼ÜhVâ>÷‘ÄÒÅüY„PIS$ã‘³&ü,˜–‚=
š3T2HÙ•*¬w«‹qIïTÃ¦*Š˜i: L9AB»¾ğ3Š[ª‚¯HS:ÍGSi!¿Röş>ĞÏ@:¡'·¬ûBT³=[ï42‹8À’;Ì—÷yQ+±gUÃ¬áá£°nsKEs›Ü*
¼»3Õ·ç¸;jŸvä0züw}îv'·¥#¼<dÓŞ;_|tû‘"÷ÊQÀèm37röm›/>ĞC/PØ˜Œç+AšÈW.G‘‘qI†n»6	XóJB/¢R³'0$ƒpÒïÇñÕhLµé£É³.dÇ®G9È`w¼SC›ÍÒt9)†Jv0#êÔú,Zç|¦ß`g¢¥^uŠX Ó§Üés*‹MìÔâbbc¾•—Õó…Ñ˜"tÌF&³R‚m ¸Â+JC‚`âstDxª*9KÜJ1ÎÇWV9üf3¥öX"İ[ƒKEî‘@Åı…±·œkb<İªÖ$qÅÊ^D‰º›ÊºË27¦˜ğÔÄ’Xl0"ÇZŠPXVşË3+Ë‚5í™—ÿó%ÑüOµªŞ¬6‰¦ëFı	i<4bøüÊó?áüÃÑeï°SYÔ&ùª×§Í­Õùÿ¢ù¯i-ÏÿõÏJd~VˆòjQ­½{Æİ‚§[ê¸—ÿıÿø¨Ä,Ï2|ËùIxû8£1ÍÜB»¢k|¡<f¡,q?ga® ‘
)ãØ„¹MÌÁ˜ÆØÊ¤=Ä¼Oƒ%ö€°•ƒ6T!¤]Gé°{ØÈñ¾bèlr«Aô‹ámCgøN8¡ˆÀïWô÷koçŒ€G‚ŞƒÓ¡´EÓ±*»K\Ã3)EÉÒ© íôFÅ3Şˆ½ÄÚ)ø1Õ Å¡Gƒbºl1}vßV†qO£2ÎÔ¬¢İ=Ü$ ±oÒB¯'0aöÈó…”yuá˜Ô ÆA?N×ö!áP3
¢0•6»¶Ô‰r¡ğTÍS¬°xâÌŞ§ééÓ(ÇÙÓ§|X6Ya¦œpoE–yŠRéM\“Fq©ëBİ„şÄÄ1 C BéÀáÃÀøÒ›ÑèSûÉŒV0Ó˜3r††d|…ö(ğ
£!Â $¨g!Šmùª]&û´ğ•ï„¡íbL™Ç¬O™²Y9pÜÉGòıáÿOÿ`…8îÑ¬ZˆTh80Ğ´Ş©Œ{¶;q°(›7úÖ1\òG;®+İĞ¹è‚¶\P)›Fdö'.÷šÅggèHd ³´²‚%“qbº¢õÔ16öñ+ÍëÆ×ã¡#O¹.ü\øµÃ´–É¸@`$²~¥ÅĞ™í'¬õ1m‡Í úOÿôO4!Ó;ÿÀíü­BŞ¢üdZıT&š^	.`­Z•tc¤tQÀDe%]/éµs½¾SİÚilÑ@5§g˜UÏX^ŸdT]ÿ3­¬o04§Aãišy¨dphhÃ˜-EÇœUùM`ìÍ,DŞ–..ßÃß=ò­dŒıü=™	@'ª¡¨¥Ÿ#´QôÍğ½Aè¡DŠ¸şüıÌ†æ`QRmÄ•‡ö™¬‡˜éo„	&öÆ<p—ÓÁÙ.¥]`D=–îÈ³ìyĞc*C“=8"“¨29Ä-2ÃLèzb©
g45ï‘ÔŒëÀzc“ mÇjè9}ñÄÌ%:BHLêÈºpÃ²Tl”ç5a±&0¨pV4‘`vñ`nğñŠ;AeíöìûŒavJ&C,˜úÃÕ_áîÉÛÑú˜ç6Œ¹p0o Úl â;µx8^¨Y%„[»SPÇ«BØ(Îk1c]Îi‘¹~Ym²Ÿæ7êEC!7;¥ÑØı"£ÙèÇ¹«<‹;Íé-ßì³‰®2r,khã¬Ïmû!FúîôÀĞ}r‡TÂÑ8µÇ½n’…Â¾¼5Û*šÑ„¡ô=È]Ç<7ˆ]”èñ{’ğñ™–¡^©÷ô)gLtq±•vÍ¥9i¡X<6LF†ÚVví§¸s?%ëBc‘¤9>—ŞXë¾¡xÓ±8=fJK;ÒóŠ¬Ñµ®ğÍLù¥2É’&lw°ˆh>*ì5/&BÀ`òc¦„q‰»H2ãÔ+‹ÂÂÉŞ*iÕ’Ş<×µF}GkÜNÑËZYÉRZ¿…ü2µòš Åv˜Yãm	©ftè]á·HåH#BJ$=R–³%ÙMÁlb‡”ŸÛÈòe t¼¸Y7ËI6İ<sÀCuè\`Ó™W7ÚÆÓuçÖK¹áò6ã¦ó Äû©Š5İ#˜¿ˆc+µ^„‚xº©ãÏ³˜.Ju-
ª¢$2]°â ¼ÀY®ĞpàÓ4}•­zy«¬ëÍêLHq²ß4åMç¡3Aò}F—ƒKÊ×7³÷sRº)‡ö¢ù¬n³Æ9ØØ¿g¡Õ]kŞRÌª•æwhxşjÊ®·À:Ê®¸˜ÛßEVßŠ#»AcY5kvë¼"ÉÂûTŒËÙ$WŒn`Ymñõ6 ’w’Râí|€ô{1é pOî0%pò¹¹BÿŠï¤pIŠ7ìVM~Ã¨@zÃ”yñ¬`Ú>:%¡‚3¨ğ¡ \%ğ6ş•ÌÑ,½L~—ïrÅkšN‹}LPaèô*X••B”Zşˆ°äï£ø«	¦lÉoÊ(6ıÑèk oà{0f¶ZœÙ“e¼aÿ°L³åñõHĞ¡46êKÄøjœÓxë4¬¬cÚ‰ßƒõƒqâ  d«px0“¿À‹Õš––;PÌ	i,±™”xj3!æó2ÛÖâ+²+*²ŒÎTœ§QÌ|[ÉÔ7UHJØ¬æpQ%Zãç;&­#+Û¸+*”¬'P½4IØ½@àû‰1$†Euò4¾›BßQ.+‘:–•¹Íî;ÉíMTÇ--Ëì¢9f§å—M«Ü"³l”R”§„6DFCv9Q`qàÕn±L¤.ÌË.¯pÓ¢j(¢Eº;ÔÙÛoÔw~ŒQF4Sl­¡å·XhÑo3áŒ6	ğnè
ãbQ{gpNÑq¦!uöĞè2ó\Ì´xä¹ÃkAÜAh‰Ñíè‰$¨ŞvPtâ{)uTHY|d‚ëÓ2ù#–UÏKáKY1ªÄ°ñsÏÆ¸%äi¤^åŒiÊ®òTVPÜw™È‚Ù˜¹}ú‚)™—””yáÅ³N³/ÆY”KÔ£<"ç9«d^uF:++ÂSRáX·}óÂ	mz§X(¼¸ôOÅ•*»ğ6üÊó?0µ2úÈ
*¦¹âŠ±èFuLè…(Íşø0—¬E+Ã¡‡ eğÄ³Ú²ud»7îCµ¬R®á¶…†{è|È¼Iİ¤©ãKUEY[Æ¨,L?ãb¦ZĞXˆéOĞ¯}“ùíã-¸ûÈn‡†L™W&ÇQ¶hÅ‘óÊ²Ëeà—Î%U9J*¿H#dàFÈ*D cKÜeÁ3ziålöè(è"CÛÜMnEà¬\Ù€˜™"hqÁ®DÔC^QæŒß=3M±b.!o…©é)
Ÿ)’x>“=›±!è3Ì°û"Ÿ“o°`Ì¾eˆôş…^Ãò+|î	Ñœ€ØÇ|¬ø&ï¸]sK'à‘]áHÁ”°¡Òã¸
m„µ¿MD­Ê2í?v%zg‡U1å‹I „êmeNãÈOl2ñG,`ã_oò+öuQ«—"6;¡ÇCT)3F•mÉÆ_„0cÑã oáÅÖA5º<(n|eMĞæCQ†
›ä´Pâ
½çÕŞ-x¾w/ªL<Ş%¯Ÿî”_”¸«a@åKUrÿB{èx$fÂÈˆ‚+#+s®aò²ú¨vO¡¸dnîä²`XKê Fdœî1mÒjÏ:—6ŞLÓ]”2ÖÆ!W.w[d‘ÎÖ/øõv“¦[#_7TûØÀ{Z>´?†bĞ’
1hS†‰bæh¥ú–²ÈÎšµr¬gf¥î -`$ì±".‚\ƒuÓxò3pšŸÙ¦°'éqXQ8ˆÚeòj¼D\ss>YQ³4‘4ßSÖÊ2İR\&‡Ë˜S9¢Å¡Kcª®sü
²ÜéÕĞşèàŞ*‹;ªbôD7'9¸i’QÓ€qñ×tÖœı¤¶µ©³·»ÌMÌ(z»B¬ 4-_"o’UÓòzQ¤/ø5yå–ÙëŒd\q¼Jt‰ÍšÎº“b`ÜŠ!½OÓòåy™¼‰ÄS4Ñ`{&ºä(Gè¥®Š¦Œ¾9É™è¡è&Ø©$¨X¥±›ŠjI–wqËReR.¢C#oâ†L¡r73rÌ	š:L&fŠÄ\Î‰…ÓHÜKšP„,¼&WLu4²ô$O)n¨¬ò5±9gO|Z:‹¹?¿•‰ÆNìîÓŠC(FÁ¢[‰Ş¦êt¹¦dêäµ×™w ¬v‚Ü¥ßé½–t…bcˆˆÄÈoEµNEt{JCvÙF
’ô”c|9[P±øŒ£¸I‡‰§d2]y–¦áK—ÌĞ(Ò· ¾³Fñ¹Qµ`v£XFmjú“=´)Xs›‚2Ôn.«wj”“nVº*T®’y8>ØÛE‰Ñ&Óºª8pwô¤‘EĞ“‹Ë[*T(C¸ˆH_X£’ÉSæE0Nc¿o\v¾ˆïÛ¢İ%]‡
Õr¡yEœÙï¬[ãz=Qçğ;cªÂ„*â{Ší®Ó£uä%Ã¦,Ù”E9ú+[mÂ|`Î¼2A&-ÌÚj¹­
Y\Ù@1à!Òc<sµá+Õó»a0ıù,Ä`ñuGÈ„~¨ISA=MÅ;Œ.$ø$PQğLG É~ĞĞ´MEù)])ù“(ÄõCÓm%“gnã¬ñáüÆ“K¢ø·XËôĞò}|@‰$ı8Bëã¹6j»È8ñôÑó.mz6È>0–#çßNf—&o!Bs¡› Ğ$Ä* hÜë'Œ]Cãæ©+Ÿµ_0@Â5c\N_[y*'PÙUqîÔÊb"¥|]yûñğyûJK,eSÜ	®y£¨E€’Ñò³ Å:µùà±ô³À%5qó&"îgt}³€ñYÌ9^V¾ƒNÎ/Â×§+E9)'à>şJ±‚)â¡¿±2=+ê)D¶÷M…p‰	õ³ûHÁÊsÊ£ãsÕÌ»SÓkÔ™GZh³ Oª3Ìu#7-T¾ Ş©Ãšmv™®®?e£¢„á²‹K—{SÉ-D:)’Ém ñ7­şNõl oJ“Ø’|M±¦Ğ0²†ˆ6†¿Q¥Ÿ…Pà|:Ä{?ÏM3Ã¤9™éAÍTp ö‚@YŒ­æ ì·Å`r¿BoJ€1”ë4À4ÅîB e2”ş0éñı˜7ÍÆÀ.ákî /Ê]ğ4ÙNSğ“)#‚à'6ày-˜Í‘Ü¨â´EñÒñ¦BÄß0ï4ß»%7›[E¡é•”bŸÑÀãó«d®>`OÒ%•rF8†¤PM¨éûBI,T¬èÔ³akˆoa7Kù«ªÙù½!sP•Të¢ŸV¦‹EÉ
ğtì¬V¬rwÁ"Êš!Ôó\Œa­p‹}TZÅnœ^tåEDÉ¾…Ç:õd?ĞhŸÛ	QR¡F ½É —PC}ôG1à‘á-ı—ÆÃF$«Ö¢]%0o_Ã¿“ŞŞ´@ƒmÑ×bı"ÇÁN¥‚ˆ–´Œó¨Bù!ˆ¥8'a‰Ö
*;…ÂSò¶#L=ÙëŠÀ³/ü¡ÙWXÑ¬Lz#‡E›¦ooQ¿•6èÀ8&^Ì`Òm
¯}Ø+‹L\ê­ÕÃe‹Â›D8tTËZ™üÙ› K¹&^^û0¡ãk1Å¼
1Bò-¢Ø]]]•
°ìùƒ
o.¨ì¿ìu;% údó»ûÿ£Ñf™;Ó//ª€úÌÿ iu½Êã?è-­ÕÀøÕz5ÿğO!ºNmÆ.Ñóh‹,°@6
‹1õì'y=Æ”ø±õ½ÓRÓ ­ctÇ­“á	ìá>HHè|é™ø2]ÿ|ÄËÁ…ñmÌYÿµj-ÿ§Öª·òõÿÏVmË¨ÚÖ¶İìo5ìz­¡õ½º¥mõk»Zë™õ¦ÕoÕÉïË•ÿjİjéµšÖ¨Zõ–a7Ííf½¦YÛ[z½g¶¶{pi4@è”jÇ¾f¿ÚìÕÍZßªnZËÒûM[kšVK·ô¦am5«YmÈµc¿„f«Ú3k–ÔÓß,ÀİêWÍm£n5L@Gë· M©¶°mVíFk«Õ³_}«ªmÕ¶í–aÖª½ííÆ–]µt @kf˜­ªµÕom×ôÔl¶4­Ñ4ªuİ2úz£×¬[f¯ÖÚÚê« X]³aomÕëzÏØ²uè­¡·ì­V­ÚÔû=ş³Œ­í¦ÑL6.yFloi[Í:t¿ßêéı¾^×·­vd»fõíªiZšÖèô¢Øj4­f_ï·š[öv¿ß4zš¹Õ¯ÚVÓîkÍVk»^ëëš-WKz\Ôít¹Õ ¸j­íím«Ö0,½×Ãa¨ÖZ5­YEóü	ÌííZÏªU·õ-£Ù³Ì-K³m³ª×Œ-ÆokËhX	XÙ.·™Ñ”+„:·Z­ošZ¿gVM«$eëzoËĞê­f«§mµlC×¬¾Ùª¥AÉvÓª¶úõjs»_¯A?Œ-8i˜ÛU­Y5µ^mËÖt³ÕjdtN¦•†½mÙZ&m«iÁpi0×^ÃhÀ$èzs»±­ku«je@‘|?nCqÙƒsGÚK»-¦ $é±¡ÕfmÛè›úV_Û2mÍ2Ms»oWÑô¾]3û­­Zö0§]`ªZ½jW«º­Ûfo»®›UÍjTku­V³Z«ª›vs63œäºSÊkÔ4àhf£Ú2zıĞ%ü]×`ÕXF³oãÿ­–
@õ;jhvoË6êF¨°YÛªÙÍZM×µmş¯évÃĞæv½Xc	Ï¢j­Ùnº­5l ÙZ³iôëu³o÷zÖ€©š†½½Œ:Ù•L¦f¯©iz}«Ş²åÕë†“k†¿×4`™5êÀ¸û”Í«^`zÓÔ¶¬h×ë°4»ß4›õí>2o«ŞÓ[Ö¶aõuQSE~¥ÒØã?¸ºã?Öõğñj•ÆlêyüÇÇx²öÀe·1Gş¯×š:Ÿÿ–‚Ì½Uoäòÿc<+¿¡Âñê´œ“4;N¯Õ}k‡¬.l¦²ız“¼@D¼äØÃÌ•Ş˜ê+Kº\'¹şb¯»uº†=ÀXuAèA`“êö&ÙvC^Ã¾öüÉ`°IºWNø“ícèÉ¥#Òeöì¤Ìòá÷ö$¼ğ|ş{7´ûh—Dµ-dİ³ƒtuƒwe¦ùCÈÇ µ2P»c9aT{õÀÂ—LoòâšÍÀ
åŒø+rj_:¸ó¦ŠˆX1%³-µÚäò=)vØyB´(9‰PÏ4=ØalÍí Á/àipRD°Sˆâ@¤ƒºÜ)‚~’ïôc¾Ş¯úvYk•«šŞ$„ s dŸá.B.’ˆ‚‘p¾+´° ®¨çjœÑ>‡ÆßŒíÍá$>tL‡YÄŠ  Ô$XE€BãÁ'Ñ…«gÇŞ‰häºĞ¯x]añğO<Òx[Üî£‘&õ¦à¢Ó¸Ï¦ÁeÖæ™°ãÁ]hş¡ì¶Nã;©eT02xˆRhØ=íÁÁùË7İ³ãÃılŸí•¡-uâ#Ã$>&´`: ÷w¤·ÜÖ[±ĞÚTì“!I(Ì”5¸ï˜g”Š€©¶ÛRí…XT-q"JÄ×
"hjğ	5å:>¿´!—ÔaÙ&O‚ÊïæÃäAK¤Y‘LìnPD)œZŠÍs'Ğ4¡"ÂKÛ[JğĞº’/Ò¢é°S²S¤b×›hSõëÂ 64}*z”¥B3aĞ6,F¹Y¡€÷<–ešY>î5^pÂ*Œ®o	lzñ\^:7ı6s‘?Ï–êƒ3M„ÒéÚ˜wÿWmÆúêÿëz-×ÿ?Îówÿæ_>ùçO&9î’Ü ß=ù{øS…?ƒ?øıÿ]dûìì”Äÿ7üùW‰"ÿ,~ÿï@r(cx»<©íÅ10ÅÊIÿÕşGü·óşÇ¿¿W?ó'óI¨œ¤Ùë_×õf3±şk­š¯ÿÇxêüÿ`€Ÿ©`šàç­ PCª¼âa¥DÔj±FıO¦¹e<åæ›ûÒ!­Ià§@'o8(ò1’B34´(å>ÎğÓC+¾5šÕ 	²¥0^±ÏÇíÃ¥sí†ÆG6ß·Ow¿ÇèKG\¤öêê»kï&xw±óîªBŞ&Rk½'k¢¤i]$YÆ¿ÙIÆâ½])¢Rüz¨dM\¤%§—™ÁY*`&Ä™yfä¸ìEfY©Àp:0ô	ŠKz½åFFò',” ™@Î«&^xx-¢Ñk:ˆQşéìì‘rÙ—ÇG¯6¯ë²¤IØÛ?¦7R-Üp-AJŒ-èüõy˜€;Ò¥ `(/z¬E{Ø±ızvJ~V>;‰ÃÀóNÅc-ZîDrß¥•X´Œ¼şiw~,Q{†»ö ,'ZNûm Ú)J#N¶Õ”ÚÔ“c[^©$°úª“Œ±ÇtŠQ”*,Ïµ<º›ësn@¸»fZD^ÙÏ>‘àÂ&#R2IÒTã$ÒŸèlPº$Årü§âgÜjŠAe‡¼jïtöV+•èİ*¼}ù]ûèug¯R|Fh\²2)…˜¹OŞ­cri‡Ú‰åÖŠäİ)ÑæÚç†?€Ù×"ìÆW/ûiD?›°Ã•¬ß“R¿*£ÑŞÛcHÜ|ôJÀv¼ú¦ÎëÀ·¾N)`~ê“rzV¥&üDJg@©ÏxT8ÒVµÒŒ,J™E'ïƒ]$Ï`–JRï5nõì<ÀK_+D…zSK±Fã¢¢¤ÄÒã_L@	ÀÖ3
%9™Tşbjy©Ğp6Päwqi V(*¹~ámQ.…=]
³¥Ë¥¿§Ka2v©Tº„ô«×S‡U1+ $"w³RIøÑºšñ¼¤|Rv;+•B8k{8„Ğ/kïˆMw7ög?¤:~‘ÿ..©09¬ÅHøb‘áV*ÑMğÍ¾ÈâÂ_¨ Å®ˆ˜ç …:aJY]7fwG`$ÍM´ãFC:ğ€hvxÎnÎQı6f?ÑI¼„âÂD¼–w×†¦†(?…öMoèù»Æ$ô¢»k"ãà }ÖÙ}I°0È§Ÿiª¸¨Pv©^ô{L<Ñ®ucè3†¡½
Ø«,|‚!/ƒ÷”:e¡ƒ—Kªš(ã¬£lîÖâˆ’“1ûaõ?4€y1 ÒĞf/¯
s›‹«Û·«Nä¤ê@$· Ñf%¸ŒØ£NñawMqgûBk6>}YdàGÀadø×­I’pø--:ÀÜÙXíùõ
©[ãí®]:©Õ¡Ñ¶ğ¥µ^ù#ùşG6ô]fŞÿÔôZ­ZoÖ‰¦7ùıÏ#=_ùıËïşç{¹r¯~æOæ“mæ¿Ü6æ¬ÿj«•Zÿğ)_ÿñä÷?_öşGq®ùE^ÉQfÜ%¯‚äPIùuĞİQø¹_-t½ğåÔç„¬°(Ho4ôÆÒâ~jÄkIÁ€P/+øì™÷p{Ì<ù¿^­QÿšÖÔqïÔôjîÿıHÏ
e°RrfMt–m3ˆ{şPå?Ğ'°BñeMzÙŞÖùÛ6U§Š·şöTRÁŠßš˜b6RäP]‡M3Bn’ã}ük¯ÛéŞ°{XX¹íZ"…8éï^ÛÚŞÑ›µæN­mø
p]Ê‰lÇÚå¶1Oşo4$ÿ?MGûÏF+_ÿòäş__Äÿ+éÈşs•ü§x€eê¹ØL–+©?œ^X²èıõŞ¬cãWËú¥ùü´Óç>tÚbşÿ ö×[š®SÿÿF+÷ÿŒ'ıñpm,8ÿõVK¯6hü‡ĞB>ÿñ$¢4=H·_ÿµV>ÿó¨Q‘¦E×Mk´4­†óßh4òùŒ'ÆêÚ¸ıúÇP0ùü?Æ3%
ÙRÛ˜£ÿÑ5½Åîëf£Šóß¨×ë¹şç15ğz^óàQ*J×"ı(Z¼H4ş7F0¾IŞ?c™Åÿ¾¿äù¿ßÌ!Â¤òuÅ‘ÇÄ¸ĞöÀ7FA¡pÒ>ûnwÿŞY¥©nÊ‘©?Ao{„§”+Ü;‹ú3‘}f
õ¨ÔôÌéQÖô[gL¿]¾ôÙs²¥Ï®üëÒ}ç"ÿK$—ÛÆí÷ØšùşÿO*öç´±¨ü¯kµ–ÖÂûßzµËÿòÌ‹ıºŒ6æÈµZŞÿëô†úŸ–VÍã?<Ê³,yòbnßíûFúšmœûdX¤Ë"-_òN.y—Œv¼Ô»8¥vò¶¼VY¯–µzâú-yÍÆò*ÓŒbÌ·–"KöhfĞÄ][æEO-ÃÍõööˆ^ÖÈïÈë“LL³Ì±=ô,šL‰ãØ68˜ˆu\°6zoƒfÄqáãˆß÷¹Ü™4¨LÆh”rv¼w\{·$LYÂ(â’àišX`	XÏ©³}v¡V™—-ìp}çu=jvÖ6I‘F§?gõŠÀØ/æ ÀÃÀ\ê"ñkå› H¾!ê™H]ÿˆ€è¸áz*ó}Eï)Ú‚³vqCT‚¡¨?«r·{ Õ¯Æõ'x¶›ÖV÷M·sŠ¯ìH—YŒ‡Õ-r,ÛİîÇ§{p€)Pÿ%Úe–ÍŸòö›àıZb0%ŠŸˆaNÇ	ˆ‹ÇfI$Q<İdiL*Éj$KóáŒ+¼‰Ç'<_\:Ê:¥4”½ë8èŠõÏŞP–ÀŞ¬³şbŞi9mÛ®<›’zÄ<ÅcÂªÅã1«RŠLÊ¸Ìªˆ#u$-®x|æÕŠGm75NÀu`”Î¾ôûU?S3,±9òì‚©ó_+—ÿçÉ>Ûéãgkëu „8ÎlÆ`’íRÒŒÛX=¶Ç…^ÖµGõ¸H„uïÊ	¬0ïì‚<OÖü‚<üD÷KÌ’çÃÚ _FN€A·½ô›Àİı8?ÁGMûP¸É¿¿Ò'+Ñ²Û˜§ÿ©§öÿz³™Û?Ê“ïÿùş¿¨—'0ˆ½óïÌ÷{	…eÃ»²íÃkÒŸ`6qbÍëÌtáOÜÈF^¤PXjãÀ‰·ÉSøO‡ácâF2O…zqgä$¥¼zsp@J#¤ó?@i«g”Íòü9©„£±\]q«Ï«`ø,ÃÑs\Ó§ùË/7ˆÚfu³¶Yßll6ï4œûG/O;‡£³ö×2ªÜôâñF²Z¥#ùtÑñ‹ÒËŞnÀ¾ô>ü¥9™U—ÒÆ<ù¯Ù£ø‡ñ?Zz³–Ëñ,mÁ¢ûî-o ¿ t†­£S’¤3PÒ™…¡œ$­•³d¶MU\#FH›,‘	Z«c1é% –‘D2QF§7s²&~y2¤xÁË@K\’7Œ´ÚZp8ÌpHl—¦Å¢=MtT’ŞD=%*uâƒÿ"¸FŒ‚Á›°Èc°ÅAZìçİ¥Á
EÜ>²No26Ê¤mı«“Ğ‹ 2ğ=ØÁÑ¶Og±¢·kr1â„eš”(~D‚54odaCv”ßƒ‰åsœ¦Øt¿2tzŞMşo%Ñ@‡.…Ïjf4=*Ù%†* å°÷–m˜!PW¸x+¯>¯™.ÚcÊPÉÈp'Æp&pjÄ¹ ho|{È^ÆL°4SËã§‰{i zJa°>µm<G´ø1î»J|{h3—Tg8q¨ÅÚ5ø´r9¯<¤` Æ%â]x‹à}aÏfTŒa*ñB2²¡ğƒá†Á®k‡Wÿ¡ó4°ÃB»Ú~ò%)¼å|ù}áìzlï,p»€wl»xf}«~úªÁâŠVïnRÃåŠæÄ?ÂïAt‡˜ññBç£mRZ»}İ
%·ìŞ^¢Å*æï «GáycÜ™3²A(ìÚænMÓ
€¦k¾u<	Ç“pˆsè~gznàÁğˆ_;ò5ù#Œ)g7ïéLàù|w4†N	QãCÿ¥÷ÿì„ïËÍ<GşËÈÿÛlÕsùïQ<şCÿ7ÏÿûDÈóÿæùóü¿yşß<ÿïr¸iÿw¡G•ÿ9C-ûÁx‰mÌ‘ÿÑİŸßÿ7ªUÿ±Ñª5sùÿ1·£×ûG÷…S;§·Ùõî÷<÷…^ÖØ…·¯;GÓı—ïİÎË7§ûg>s¼·Ó=ÿ~¿}~øgÆÜºoNĞ\|·oƒåz‘çÏC<Yçÿe‡€œ³ş[j‹ÿ«Õ¦ÖªÒõ_ÏíåÉã¿çùóü¿Kœã<àû]Ïóÿæùóü¿yşß{æÿ½UÊØÙy`gg;}¼ì«™Cö¶ilgæx½UŞ²ìÎNš• uVÆÔ¬ä¨å>›Au^rÔ¥ç?™n5Ïxº@
ÊcS™@óÜ©sr§æ¹¹¿ô±~á'¡ÿñ<zaÔ½%¶1Oÿocıoæÿk¶rûGy÷Î‡°ÖÎaÎS6T”xJnçfÆ/
¾4öùsß'Ûşk¹™@çÅHçÿlÕjZ¾şãÉõ¿yşÏ<ÿg®¾MŸòüŸ¿œüŸ©ıÿ2Î“ÿÕüŸMŒÿĞjäòÿ£<yşÏ_wşÏÔú€L óäÿtşÏf£ÕÈ×ÿc<¹ÿGÿ3ÏÿYú
dõ<ÿgék¼%ù?Sûÿ¹¸ _^9û­Y«Åñ?ªèÿÙjÖªùşÿOÿCÿ‘Eÿ…<Hü<ThĞ3‚~lFğè-¬áaÂd‘ÁÃF É&¼Ä`-%È-İ#ÈBĞï
d*ì%ò„_L4Ywó0@$)u÷ø¤s´×=üw‹tµ cåGëƒ^Ş*kçz½^)ªÁ?ôØ”Ê¦ØB©ËB}”,”(ÿ:q 99ÔÇœšŞ8YñÔÆü{·¨êÛŒ¤åEùšBƒ$ò?ãxŒs$í2¾XJóô?“ÿ¤ø¿-­‘Ëòä—´I´“ªe=ül5{\I#E]‹Ds*¼¹8Ax­(ı“Zœ_KDß‚Ch™»0|á ép¾xş `™;$zYğz[ÊÂ `¸":„òì(¢éîÒí3ØÌ‚mB	ösºz¢%søÒsCõm?‚|b{°QO…Ì~¾ä/Íšò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ò'ògÎóÿ Ñvµ 0 