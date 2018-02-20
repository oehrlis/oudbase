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
‹ lƒŒZ í½kl#YÖ&Î¾ºÙñ÷õn¾ìëÛñw‡Ò¬¤^ñ)JšÑ{‡-²{4£—Eu÷Ìv÷r‹d‰¬i²Š[U”ZÓ­õ‡Ä@â8~üqb'Û@'ùşçõ'	 Y8p€ ±	l  È'çÜGÕ½õ )‰’ºgxgZ$«Î=÷uî¹ç{î9ÃÌÎ\rÊårk++„~®²Ï\¡È>y"ùåBq9·º²’/’\>¿²Z˜!+—]1LÇÕl¨ŠcéCá ìğpÈ{ŞïóIkĞªCóÜ“q:—PÆğñ/a°qüó…•åå\qÆ¿¸œ_›!¹K¨K(}ÍÇö,’@Cs:ÉY’\ls›­u27q´¶q¤µ‡”,‘{Ç0uÇ!ıHïZınºä§¤6è÷-Û%÷*µEÈSÓô¶në†ãÚšãè¤ğşy/¿R ºšë6ìA»½DjÇ†û¥nw5³5ñJïh==ÃÒ:Q&¼,Üeó—5W?ÔL²«wì®A,İY$}–±è³\Ş™¦ÕƒÜÕ–áz¹ç¶4Çİèhf[oİ;aİ_Ñ\¿l _0}ıÈpËˆlo`÷-Gg˜îÍZÓ6ú.q-ÒÖá££Ã„¦™M°Í!¶îLÒ´Z:ö„åê¨ÍAÆÑa8à[O3Ìî	8z‹Z6ÑÍ#Ã¶L:¨08kà’ƒG•4¯h½aX¡4DÖqİ¾³Í¶rĞÀŞÉ²sÅ‰ëVèò1P•eŸ¬ÃÏ\>“{?SÈåW	!ÀQÙ4×ĞºäH·±&_Èäó³&`Ê­/€a1êğ-“X‡H)ĞĞÌ%LÎ4Ù€B­ñ¥æBÅ.‚=©¿ “m÷a¥¾¿»{P¯ì”æ^J¿ÖÓ) ·S/cÙíÔ)­@Õla/^$EW92èºä‘ÖèÎ”|Tİ¯mîî”`4“•İòŞ^u§RJì?¬¦È˜ihWktuÒµÚäĞ€/Z¿¯cÜ÷vkÕRê~y«v|@˜‚¤‡³©¶±¿¹wPß)oWKsHá&ğ2—[LlïÕ+›ûÕƒİıÏK©¬Ûë§èÃû›[PúÜKà4«fÏÌÍ¥’µƒòşAıãj¹Rİ/¥è/dO5ÛÜK©ôS²ğˆQ8<çİwºHç,™»“Jn—7·Ê•Ê~µV+MdÙLÈL³“¬îïïî—rI™".>’İıÙD¢º10t“}‡¼^ä¡£µõ…Eò2È[+†Óïj'`Â¥#9yTH‰š>ªXÛN›¤6wîï’uVğRpŸ¤;G6IäCœİ›;@;Õ»$]!‚ÑªìÀ÷/Ø÷=˜íÇ–İºÄ—<‹*„t'ŠØiádÁÅÅ¡‹;üŠÉ~•=b¦Äd·£²7;zó9]~l½ß5š”/Å Úí'A¾GH¾ë¤i–*†­7q‘ Ûš	­±cĞEvİ=xBúüå%1¹CÃ‚	À"Ä–ä¨|[V›²'Xà_ní>@îpÊàŒCòæOIºí’yö®ïfR4s£«kfÙlı‰á2¸¹—…SúZïÂZ+à/:Ğç‡Fò49ñµ.rjm3Âb<Ê5zT`éõ/kªÓ^_XL¾¤íÜÜÙ{x ‹dşİõ;§QDHÈºÚs€dkŸÀd0Û¤¡ÃG‹õmø5t9Eu
bW4 F‰FLd2¿”Àù.XÜ¼1IÁ’Z$ä`s»Z:ÚŞƒ…¥b	IıìİÏÓïöÒï¶êï~¼şîöú»µÔâHY÷÷ã³š#2ÓÕrŸ£ÜİO±T¥ÜTJ¸ÃŞ+ ™ˆ$2éÖôg@Š.hHÁ§)R"\N*Ä…a°´ŒfÇBx¿N@8‰Rä•«ë$­IóÑË©Ì«áh<0˜Râ«Ó1]ï×qç=­5ûÔ—Öµe)Eœµe~µG¶.²…ÃÑ) RKÃ­mY¦æM¶»w£Úôšõ~t%Çï¼ËàÏ‹”ŠHuS 2èîŒñ…á^‚p4já‹xïq–œGvìç½5¹+¬´!éYfWy	8*€W¡™d¤Š:CÃ–¸M´50©$®Ùín‘©ÁäĞeÙ{Ó²Qî 0z¹ˆÂ¸EÄd—öÅqñ¯ŒÄ/K%Tl Iß´\:¨.gtyP¾wJ (ø±_ŞØªzÒMı^¹è8èè‘¥Òl´Gw)bå¡v¤]”•öäó£0oXƒn‹bp­A³Ãv|Ø.¥ÛÏ€¦ki-òtîåÇ»@ÙŒ¨¤Œnyd{k¬öU¶9?„†é-9qdşªmCauZTŠP³lËNG×˜&Ê/\'Ô´z=ÍTÑÎ®åH"z$ÖåQX·Ç¡’UXÊ–)zÚ
P4ö¯¨‚j*0M±Ä¡=]·Úà„no`£Ì§ˆ7%b[³?a¢íK}ˆÓ:Ğ¥¨İÉı*˜ù™dÏÂ¯,À;´ 2qÃ„¯=¶É’êÿşû‹Ê'¨$;ÖLS#Èï­Ûµ”iúó‘lç¡ùÜ´MÖôy/ÀBQrbşjöõubµ5›ó^V_8±{
ÊÂİlK?ÊšƒnW^<ñÑz&¹zl÷şd4LÂ5‘×÷6Fç"e:(7VöIRˆ.Œ‰.ªØÂzüÁ‚œ.Ôó™(¨°H§l+yo_yh’ôê{Õ§+N|uÉ«Wğæ’n^ËTJÍç 4,k;§“¤ÈNfÈÜÂ!réIS½›§ì]Î:RÂÙ9@”|?Ç·íI.Ë¡B¾ŠI'éòT"ÏÀüK%Ù:åƒ
U2	èç0~òùéOq˜IJÒ(ÍhI“Şˆ¨ı’—”ö¦M*ØQqu£ş‰,C·­ÒqKÔïÚZŸ¤”†s)ÜK'“œ;@¯KºSà¬C¡"]èµçj74 U™Tî¦¤x¿0Ùç[[w­>­š¿o[8ıpAã«a{¸¯Ù@.êØ¾ƒç&#c½²şÅzuİFiÏÛ~0AÈ‚,Ğ%ÓÌå$¦{´‡¥wÆ"Ù>‘	Étwºæ²VUéÑb ¾²j,Ö^$ûÕ½­Íò*ñCµª.ªTåç¢±2wG^(è^Èãjûg„x\ S›,J£òº›Ì(ÌÖÌ¦ÖÍòÓzÆ%RdNEÍ¹¹K¼™³ú§ù$1=ûÜÏ¡¬*ˆ‹ ,Ä¶Õã¬‡“éK>j¤ôİ
	uÂĞF	½ğa1ş
:d¦Pì1ïöã×fÿñ‰cºëa‚Ô—ôH»€}]O§"µ½§ÉêÙä‡€`îåŞã
oÈ)ë¦wø†¶
—ÃƒÃWÁ€30…`\6 ı	<É!Óivl›>´èé˜VP¯ïÒï{¶Õ×m×Ğ¬)<b}ä7¤²Õgå6‘È† kƒX¢¾«ÕXÍbU?;•ó
8§Ûz$ˆÏ€3k-øKÆÎÃñĞÏ³Ó™w²¿œË¦³ó2B®/,XœîiÍç K6+L%İt]£'ˆhàà¡ÈîÚ+ì\ı…‹bô\öåÎNö©™%ÙNcp;‡®Šø—j]B™B¥èi-BÊdcÇ³üp¥¦ÛG°«AÂ«Éc²Ğ†}Ô¦IæC üèQo)e/
"lK”²ÃJ/•‡å‚âà¦`MCÖá2ÕOl#–Ä­Œ©­Jyş©y©Ú3Œ­D ›{iğıBùñ§õ]<XĞŸ“ù{Õ›;/÷k¥ÔS3ıvH÷é×Ô›vv÷«°8”ò°MiÏ`òä7$ûËr«eÃd‘¯ÎğÑÓç±”ù§w³ä%4jan™=®²fÀóE'÷9Åc—tKBŸ©#Ni]•Yç‰óêÌ‚ÑYÉ‡dùÑC¦<í%!Î«Ë°´àÇiHRjøyŞtt&6:TÀ?Ò,‚"`ÒĞ‰Ãø2ÌIàDŒÎ~UÇ3ş:…Ø"ó\§¨¾lnoøre{sG^zbW1­Õ3Ì1–±ğÚ9V±k˜Ò¤¸aT[ŸcT‹uáã£Ëxhù€O… âWÒÔÀù°ú€î)É*vA§‚Ö×È;¿ZßAEP§€ õ•B$±ŸÀÃ®W

ébûÔ£io?:‰ıcúº->Õ$ì™	×µØÿ.sÔş¾­­r9jÿ›ËOí¯"Mí¯Éş×›p_û_nªÁ")gä%Úùª›ş¾—ÿ/Éô7¿Ìh˜®mµ úÀŞÍSï!"§¯7Ãß:aÒ§ä“5şjOÔøÌfÀWjÃû52á½B{İka$…˜ğ†LEkwIºG>”Fo²{{İñuÃuŞÎ†Ä&Ÿ”81¹CÍórokF—ğytö©ì•ÚÈ’©ìÔF–Lmd§6²SYÎ"¯ŞvˆU®×ç±ßÔBvş©­êmU'dÇyV…S»¾¯˜]€Vw•FZñÅ ²ò 	”65í» ÕNØ¸İ‚í~óäÒLôzëÆz•šé]…^-Æ¬®€’hnAÈyöªnìÓ¥ìS’m/^š}ßDì÷¾ò&^œíÆ6‚Us&Õ•t)ÎŞ3tµF¤^$1 „‘VêÁç`›WâØ,iÚ:îf5õlõ4:A¶Gï<Hµa««ğ=qP¾W
H»£¾µYÃÃkfqtDæ9;ï_9zÕ¸Pó<,ë‹áµˆwÃãòşÚ¨’Vv
í¼§mÁsd†DéZ˜kZ)”O³wğÚ„Ÿk`rkQ¿!ş^JØ"Å]È ¸B[¨1û^y‡'1
µkSœCÌ”1 í[æÎÓìÓø»øk‘¹3—}šÏÎ/úM“7Q^‡M¤•³ÖÏ/Mqº8ú0²æ9¨\2\ŸÁæİ Ûd~iÀ‹œíÛì&ˆ©Svn˜ŠDîÛÑÇ§ïS“#VÛÍVLW„,nêxs.„-Å® X}b¡)z‡Ùñ³{·í¤Ì1lOæD¦g>ó9Ş•'i›¸Ğ9W?$¯ˆ.¦[Š=zEC‡úÅ²ÛGœŒCíÿ2°Ò3·eF,Sº)•»¨nCIp†EÔ^µò0úKÄ±vS—e¶ŒO¢¿Š”îÄkUÊóò^hêµ¼5Å_sŸÃC’î£–Ï¨QRes_ÕK(ÕŠo1zhj0+SvÿÊ{—
a™U öÂÖ×F!ig§YZ@óñ1pÚû–å2nÚZGºT@"™{şÉ“õFW3Ÿ¯?{6¿âH™?SÔbOeœ‹ª:ÈlvA¿gÃÈvJh›¥<!c`,0Yf>û4µô4•¡ÈÎ·}ˆ,üZTµllĞÎxt¾3Br¯Ï½ƒqZ÷ªvÊzuüğ:ôTOâ>Íqt›¿Õ½ '­İíí2Êú|C´¹sšeÓİLætºc9.m½‘€¿Æ²˜ËÀ;ªšh›%÷=ÂaU8¢À´à•éÍzE;áóùŸ½;˜‡ı`·a!W:)Ğƒ¡×hê§³÷Î4L!K6
3@6¬Ì0¬ıœó0ĞJø *Ğ<.qÈÍ«K8\=Ã…t~)×·¹K…ÊdöjW¼ê’$íP­ÊîşzÕÏbï¦pü-H˜òNâ=¹°@¿ü,¿¨ò‡Hõyü°ß/Î ‰;»CØfŸ€ cNGoÕïşÀ+Úö¬X-ëØ\ñS4ÿØ€Y×€¥nãÍZ½•IyÊÉjz.\TqğN‚¦‡¤­N-}è˜³†¹ø<]ÌåäíhpiÕ¹©P@¯SÚI¿G–˜²
a2ş×Ìóª“°ÿD"ô¯ÅşseyeÙ³ÿÌ/¯¡ıg¡¸2µÿ¼Š4µÿ¼&ûOoÂ}Uì?Yƒ¾¾öŸ«ø„ıçû™Üš³­}§„´¯ìE.ëŠS„¦eR]2üÎ|èyö£Ï§¥qØŞƒÒ\&ÿÆz—½R³ÒƒÏ÷°E·¶Ænk”³{Œ5œôõä§Õê^©x<ÙÎ ×€	Í{¬ëÏéd}®ëı$ğš>š–Ré´ø>F=Ù•?¹ßÕÚSÚ7Ù‚Ö%"©~õmi½†zIša'*Z«lîlìW·«;å­©Mî9¨öµ²Éú­ÚäÒ2¦6¹S›Ü©Mnúu²ÉË$wj”;5Ê=ŸQ.—íÂF¹ScÚ!è¦Æ´ScÚ7Ê˜vÒ~2_CCZwİXï­W/ÃŒÖ…- USE£^…‘í$İZN­FÃ€S«Ñ©Õèl5ÊçÆ´eşşE&çbéG6Ç–}YÁ§
,&Ğ®ÎZµâÒOiÅS€„cµ\$XÍA=æ k‘‘c]NLªŠOîT×W«ŸîìJ:—‡©ÅäîVÅ{ ğ4=÷O Niö{åOîÕkU <Vh
…LDÉEŞÅ­ÍˆæD@zXÄ°Ì~"2«CT	µ‰6T­„æğ~Á§£‘áÑ,¬Š»ÍOV9f¹†³Ú¤©õ0¹¨§j¼ùÚZ"G Y$ãxk0;[èxèÈ§/_tQm•9%Q£ÌÕÑ)ÌšUâZ~½ñ×ãĞôğû…eËÊñQ=8yã&¦‚âfŒ6Œ3²s/ÕºH™B¯Æ4•MEIÔØñí:ºŞ°ÌC£íã5æÔäôëÃBÒ{_6Çé£¬l‡ËpfÜö—l›·±»sŸÜkõˆ¦	'ùâ Ü9CÛ‚Y'Ñ8ŒiB›öTnhC¡iY­É\"{¿Ñ]¨ôsĞB½†øÉ~Æà’}šz9ÇC3™à³¾ÑŠëç¨^æÇ¼·Çã[Ç[ß‹œÔg0*Ë ˜—rnƒâÑÆÄ!<éE6y{á€¸]¸†Êijƒ.é|˜æbu[h¯£GPÖ Ë|„¥xs,ş£ìÇ#šÈCá@5décœ²„X§È$a3r»GÒvôÌ`}2ßŒKnÂ¡5 YAogÂRD¥cvDŒŸ	™zóêMM½Ï®ÛÔöµLhü›©{jÖK)c¸ıw.WÌ­¢ıwq9ŸË­ä–I.¿¼Z(Lí¿¯$}ëûß™ykff[k’İùL°&|6sşàßoáüN|{<”åƒƒ}öæø¿àß÷ ßàÏoÏÌüäğŒÖïwõLWs\4 Æ½üì^ãø&ş™™ùã×Óš6®€:nñºÌMÿ>ÏrØo1ØŸ`Ñ†¹ÑÕ7Í–şbfæÒ?øBÿ…öÏ?óWBh¯gR"
]RÃçÿÊja94ÿ‹…©ÿï+IÓû×sÿÃ³Ä“ï~0å½‰‹÷tğÈ¿¹':½r·@rá[ -Ø]öe?ôPqñ¸€ßÅMƒcà°¸LB![Vó¹nGŞA¤mİ­#V‡V‡«	ÙùŒ•kŸL¸ƒ¹A¼O4Û@óšóÄ#¶šNÃSÛú#f[¤´#¯´Õ°\r¢{!3dÂMäz†wé¸^¿ÈOC‚Õd—=Lœt¿°N²R½_~¸…ñX*ì>=¶c77RTÕ”R`ø.VbJJ9äpÒY­ZÛ®Wvao§”Û²p6«€õ­İò–Eİø0{û»•‡2DŸŞKr%<ìˆ­\8Èaï8_È2ùÌr&¼¿ıx0SEîW©>róA)Å&]àKÉCÁQR1tÒ³’w€Š¿¨«'ßæ4)&Ó(Éï³s/‡ô;<‡±Ò8¡ñ7Ô™9d”½BÅAyàIŠö4«»MŠ±pªQE£EÖvÒ—¦e(p"ØDdg©ç¦.™‘àê™VŸª4­Cztì?‹l4¹‘£•üoÖÛ~ïc‡ûè{†ÓdxE0q$lş¼á8ıŞ8²ƒuuœó-0ÌÒL+)š«‘xƒs4€X™œ ¢£‘‡§¶Š^Ğ½úlúv †˜M´/Œ†û3
…ÆX*8Ä:”Zx†Ü\•KøŠ'-Tá?RÁŸ”•E‘Ş÷3ö…v¤±®EÖàØÑ#{‘¯²¹_İ8Øİÿ¼Îl”¨]¯Dà¦< Õ‰Æƒ-
º‰,Ñ“6Átİr7
·pğ9:Yá­gG %zJoRÛdÓ»é§¿Ğ›Z,g•^Æİ‡ûÕ
ğ¯ôhà57ûd¶)\Q0@ŠÉéF¡J¢¬ŸÆXX³úÙº;°M’îõ&n+¸ìæÕÔ{°™Õˆ+Å<R­š^ï5Ÿ¹ºİÃ"ˆæÑtOÄ‡ûì•>F{¨CÃv\‰¶,ŒŒxlÀÒdëˆİpEˆZNZ§$İÕÆ’¯.?ªVêˆè?N%#/">Üá¸8
Ø'YşÀ³S¤l#ÔEõúM0Ğ*“™~ÑÂ§y}F2‘‘TT…µ®*¾@ù2°•Ë8^OD£c‹×pl‘	›-¾ïéq—Óò&[Ò)ÂÁ)	-ÿ§$bÙÆ‡é‘¬•=“ÉĞÂ8õİ™r“¾²ò|º]€ÚŒø¼B7ŸĞXœ¼°÷ëÛÌº`úl÷)„b*Ê¼ï°ôª¨¸4õiÕp\Ja2Â‡*SçØç4Ü%êñ–oØu,`ÑxKĞ:tÑ:ï97Ø“EeEiêDÑ…•Ê9$A@¢ŠÀÁğµş„b¤r‘ÉJ¶OP´°ˆ#×àäP Y9$£ü1M~¥
rÃØ€İîÙmv/h†ËK¥ö„şVNF†£ÍõÀçİŸR!ÉğjÍJpQô²ø‚¯˜›*Ö°Ş+•wÖé¡0½"¡™'*ÁlhGG£˜¨p*ŠkqL1nŒ²¹¨©°D\ÏÃå&Ks2ñúú­ÜŒø%Ú	QŠà’¥I$ÁÈ›Ù@ÏØW)J"mjìË[âMä‰P`õE˜©èîÌ4Gog§µóÒÙ¤iŒÒ×¥ÙvË˜æ¸êHB?ã*äXqô7KÑ©<ŠÛÒß*c%£©[¡¿Š±Z—Uğ,heæìş.ójLéd5Ñk»Â7,*ÌC‘Ò·ãßÿñz"ÕüˆÊi^ Û6!g;êT Z•eŒyÚ?—põëuuãİzF3(Ãıeğ@Šz½jq²(RÌd\gÂó¸~PirJ7•È£B†ñà!ŞşZˆ5nŸ—ÛçájÊÒYŞcó£¼:õdSø¨lT†£Œj~ĞŸÿ€Ù³±ßh›Oiµ’`€‹3E<Ê²m
ÿ Şx£mI7÷ë¢ç¬ç’²À” şsÕO<:lÁh¡ ™í!ï¨+•v`e
/ÙÈÙa%dïè2ˆ4&m¸–­5»zj:£1¦õĞQÆÙífúšÛQ‘²Eöb¤}ŞŠçÔìÍzÈZ66ÓÇXõ…9¿óC¹Ù˜“]ÖxŠHûêÚ!åÖ3àyXÑağ­Jyì!'%Rèª9´¦ÂrĞz­¶/S#îHpºñeØ—,·y6‘a¿ºŸÄ_†ã…!úaf,óaÎ°AfæÛ\ÿêÙ%°cÖqÈƒÙå$=iòìêšOH_²èJ)•"éğ³ĞÏ¨”RÙØRŒğ­§Õ1¥kŠÈ<Ÿªâ÷½Âï>Õ<¼ê sIç%·öÅEİùTD89ÎlÙG<Œ8/ÊÕx”g;ßXøÚ–ÎHÚ/¢o¦{HæßM¯8äİt¾€Wé×"şuP~Ë\?ÄÙV`¹áË0ë’ ìåSş‰½í}§qº˜ŠÙ)ÍÒ¶Ä§óÔ%2¿‡0Vd€3´ùîEHg­gÅu~Î0&n¨c˜} ß±©öÜèİ®˜n_Bõ|u›6Ê,§ç’öø]àÉz“ôÎ%çAÊ‹8^2³š¼ö(„!KC¡eÃ#ôÏãô-vŠ ‰¾x$D€×A¢§"]iÎ¿KÅ¤^;4%}±W–î¢ıaQÉPnú‡ã¢‹»ò#IT±·{”s÷…–aók®ræ1‚)¨
$Íäº5vF6|@3d¯«£J
6¿ *n÷„ª<¤L±wlb¼Ì]~=ä:„T²@(”`"OÕŠ…ãxÁ˜WàR…=?4æÄe²Ö›1e…í×6ªÁ]®Mæ–Èo£6Œ˜A•i“Ìgé&†î7¨3óg™&eÿÙ¥ì/ç²ıyQO>j9éæa;
[İ¤Qz¸„úDEŒ%‡Êä…`yÓ‹¡“,J‰µK.6Z¡FÊû²Iöê9’¬›#X›Íµh=Æ¬àI8Céß¼ğ°=,½„Km„b5d* ©$ˆ‚4]„$	Î<‡˜üò{ïGÃ0‚ğÄ\„]]^¥#ùR|Ø÷ŞWğŸó^Œ'¥¢xyPÃ2D½"å
ê.BŠ‹ ¬¬¼ˆÔ\HğAíEŒêBÊT_Dê.&ß‹W±ºúxé¬Î÷á¡½¦ó¤¯	óWc®Sé\#NßÃ¢aì›oŒãĞÖa‘z»Ë«'úr¢¬Õ ©l c¶ùôiàÑ:¥ŸuN×%
\÷hk}Ní–”Ü¶q¥Q­Õ
m‚\+êä\Í7¡ß½Wçğ%qJè—¨²ëèİ¥r‚BA„İµìSfÂwŸX“œ[*)”>ÚêÎ£‹]ñÑ‚ø°v°»V½èv‚Y	(H}†ıï©ŸI%?“ú<É³’RI2.º88µˆŠ ÇçpE¥$+Ï'Ç·´T«å=ÀË¸`3Äó ¸|sC—GçæÛÁâyz²Í‡ó)M)©{·`I‹QrHÏ‡d
f‰lTp•/¢ŠÈÚ‚²Äµ <h”=Ê l3
7>Ş	Ïp™ˆ*å®‚ô¹ø_à¤ƒ>/†­PÎ6¨hv½Ş	ˆÓá·ñzd `ÚR/Â=²öM‚ªR5/eÔDÍ+_e£ï¥¢;~övßï¾°	`â„T"^*
—Ú¶:J6ùørDfîü…¬¶¥QöØ8€,˜ÓÅÆ12Ç°tGûv4Ï¡ç1³øn“TQ›ê„Œï‡4,TR
 O|iŠf™ÂŞ!äÙ3¼Ê[›eÏ¯+…§†EPn[ä,dî,–æSğß«Ôbæµ."şı…Ñ;±8fÇÜ«†eĞ,ÎeŸ²óX^òo°}BÅ­¿{â§0âï¦ó9~‘ŠĞÏ½¤
``JyèO‡óxÁ4šC©@9±¸Tñ_œµ„O,>7D³m˜[z—ºˆ»ŒsKvwoó>Z†äS°0ô<¹ÄÆÛÀ#ĞÌ V¯ °é;BßÊ †±©6÷óLCß
—Ğx¿Û;ÜŠºÍ†IIï´¤dŠİå+*%ÓŠ¾FÀ’Notè¶÷Ó»x"ÑµR@uÇ«P Ó„ª´aõz–¹Ì¬4§6y–Jù¦uLáöuÖÇTÒ.1Ì'Qíšó±ó6FµıÙ³À‘·i‘æ6;K¤§k&rVÍ…™-ƒnµ›)Ø¹âæÛ áh[p™Iİ?[§!¥ÌËó;!%nø%Ã¥Yº~Ci–İb5;Öá“y¤\b+‚ˆ#‘e.ó³­lÂa¡û’Ì±.¥ÍmÁEwËH¡-¬”åÈBšv™À/Wjl*\ş,Sî×¡÷Ap´m:yÆÅë>·ãwŸ¨¯DÖcèIÎ@íttpºËì2Ùé€7(K<ºà¸ìş±i™i	„BÜ·ìcÍnñ1Ny¢8pXÇ5ğ$·Û¥èĞ­äíğÙÂÇÇ”Æ‡:ïgÏ¤bÃèX‰úØ‡bBÍ¬kkÄé¢7j.¬uÃå¼”¬çÕ…”/‚..%&ÆäBÈ1ÄñÇ˜÷F€VÄÍ>¶"ız ;è‰V±Ö_€ îğ{=âîÈÄ]ÌÛÔI;ÎÕü.wuZ¯ìcÑ¢ÔAØ¶,*èBw^Ê…œJ†0ùÅÏˆÑ–=#2-2‰Ó«ÙæHüdfD¦•!ÖB#²NÜ*(Ê ]\!°Å‰0(‰Ã"VvÕ;„!òZ0¯PTÅò®0ör1@–ûR5½*ò°°B:IÍ©gÓÑæ
©Å >ù¸“ øS§¸ó àsuì$ö,İI>LÙHõû¬r5/¬‹ñ8RÄİ®k'‡,x¢[¯Ö/‹ÃISVè,ÃGidh@HCÏ¬åÖ%k¹uÅZnİ×,á÷àüFWÉœ-GwUyÄQé³ƒZ[?2`‘ mğ­¥ etkÍ}«¢¸‚q„=Å	¿¬(Zr®çÍÄ@	ÊôZ¾r/xş”UúJ#¨ Eâ]ï+oÊ™WeïöÕfáë3•®}&L9_‘NŒ.qCóy¿Z>ğB¢ñMšßô,N™vŸ?‹ëŞaŠd\#%â{ÁkQ@\TKïŠ~ª [’12eYÎ—#Qœ+£î6ÃÅıÆ±û4|Y= ¡ö»‹ÅMTó”¢^òGWS)¬›3ìùE°ÓÈÚöà’uQìşõ›è{;çê™q®ös÷Ìõû(?UØ²1‘ªUpW‰~W’g1	ùo®4†¹kÒÈ_J•^—=ãğ÷Â¡ÌğúÔ¶/Z£ÉÕ¦R«yÅ¥÷Ï¡A$wz²Sê…|bT`·)ùÊf®ìE)èdOÂ4Ô»G+#×%èËå"µ	àU© ¸ç	bè3–UÒq‡‡¾»ê¢%¾7¹¯Ùh(ªhì|0ÖSÊˆ.ÃIw²£}#ğªÆæg.´†Ô'şô3²Zê1™pĞ?äÆ!—Âcë0ŞÀÆ‚‹õkğ¡<­î]¹`xe"38k_sœcTçSãou=Âó/-Ë¾|”êıãVÆ}áFr™Ç.,V ŠÃºù/¡ò«"€±uœ¢S»S5-Z»R‘¾(×B±ÅX|šWŸC‘ù²_‚‰,ÌÉëöşÕOü^Ã¥–1*şúËÏ/rùBq-—ÏøR(.Ï•K­O_sÿÿMİÆ#º&õ·vIeœ}ü—‹Óñ¿šÔ²š—;ùgÆŒÿ‘_Y)ÂøÃGa:şW‘pü÷« ›T3½Ö%•ı±Z,ÆÿòÚšÿ‰ÿr®¸:ÿri–jkiPn/®
UÑR”›y¸ªyô÷ÿÔ_£{/[šİ2¾7ÈŒ^¿‹vÔ<Ò3†¡”}á’Å/àJ!tåN=ÏÑíZß¿VÄn·ŒÁâ4µ¾îdH¹‹q?ÚÅq §e¨ÔºhÖyâ…¿Àæa!»›Ša¬³Ä­sÑ*úuÔß1Ü­¼?¦ïO¬1ut-FœZ“ĞwºEÃñ)ò3dÂ#ixÁr©=/m´F­-F<Ö°"Ô¦«¿ è6z«‚»õ6h |ê cÛºÒÑJ?Sã¤rm{‰ì—7–(ĞƒÅİ³l±ß>îMjVfàí^S·µ.İÌâ1a³]‘ÆFW—‘I&ï¢¹ƒÙ¡Ìİ1»C‚ÃtçãæÎŞ-KÌ?+“8ü+‹<B©€4f“šòı;tVGö,ì¸ö ‰}@»@¸“i¦†®w—¼Ş§¡I"JÁH3FÏèj6’ñ1ZuÁ£¤"Ïiàır†lRàcÛp]İÄ2‰Yy³#/d£²e˜ƒäÑößÿÃ¿µÂ:VhT¬”«¦ÎTö5§ßĞmhØ lÜèSC3É'ºãœdk®;Æ-ßéP}uukL:<æ	sÍª#Ç‰†½ï,êúáòh£·¼ƒò>Ûã)Ãâúpw~×‘;üà®.<À°fÈcœ ĞQoiA>vfAİs½EËaãıÕ¯~EP±C² İúo²ä	î,›-GF²ƒ\>ët`®¶²áÂHº“Ä@5é|>_®ç‹ë…÷ÖWŞ£^[ö0ªj›¬C‘uág$¹L~‘U3ÓÉı” ƒCs5ÆìtÉíà°Ì­­/EUäIºsôş6È‡Ò”»ÏÈP|r^åí.bëyïh ïù=BÕ3’3ê»Ï†4¢iÿN@(Ñ6“#=õĞÿ}[_…î(nRÚFÔ°`êö¬–>
[ Oelò­ Ï°0C¶q‰£LG³Û:ŸX¨ª!EJ’¢•q˜ol lÿÌlD[,1r†â#“² ®v{Nô3£Šh±"Ğ[kT4Tt~g.òşòŞ:í6ô‹ô¡ïé3&’
L‘Œ~ÀquÇà½hÃÏc[ù\ØÕeÖ¾€ß÷T§÷âª$; U;û‹Åû^L*1b^(‘nr¢Êd¯FjEW+S¨Í)¢XïåÈYÅF´–/öÑD—í­VWÇQYöeôôù9è–Õ¦ëä:Éº½~hÃ °H&“›òÒ¬¿Ğ¨hFÆÑç wírÇ vQ¢ÇßAÂÇ72ÿÌ@¾tãÎÎ˜èäb3í„KsR'˜ß7LF†Ü­èÜwpå¾C„8Æ\ôòúY]`­‹ø„Ö›ö%ài0ƒtÏÜâÁ3<œáK‘òJ%Mèf{*’Ë‚ô‘e¹xÁj"&?FJG¸Šp 3=jQ\8Øï¥s…t~µÏ­¯×s+g“Gò™\&'$’‰”~ù%6sEßÄü…Íñ–„T#Úµñ—wøBİ#J$=SÔ^R
öÁpb…”ÓÙPDİ:f(ò4È°¼Q¯ÃÅgée0pd²¸ŠŒÊë-ãá¼#ó…®vó2}·£0øë©ZkºF1~ÇVr3<ñ0Z±ıÏƒJ½®‹*«Ä±ré|"ˆ£®×SÄM£ˆe¿h=ÏgŞËäêùÕÂPLµıÍ½ƒúı?±À4”‡EÉ×5êï,)œØĞl<è§°"ñßÃås–9ÎÑú·äÆšİÑ¹FMÅ¨\anp‚GÏ¦è|cÌ£èŒã1€‘ígöİ£ud¶l!ó|©/gän~@¸`ß2v4œ$üŒ-
Ë-~EĞ:ƒa
<°Š·Çš´xœ'7$pòÁßIëŸÖã”O˜½ü„Qô„¬æçÅIåÜ0‰§Iå(!‰vôO0œªô0ø[¶jiœ"ö5ĞAÉ®ÑÈ&aVf“~È(é+ºQ“Óù?›À`2-ùIÅÆ:ĞõÉ'!²Ú¶åb í–Š )9â	û`03ı“LĞ pmÔ‡Xãã®ƒ^©œuüj4õÀ{Á`m§x€l6Íà`1[#ĞÒC˜¾`†KÒ¥Ä}	é0~6Vo?#k"#8KÅyê
ÏÖ• f±BR˜À†‡“*Pš {YÙâyQP¡d!PÕóa“„İ³!ä^A°h]¢µ¨N:	TèÛ$"[2˜³¬¾ƒÑ¾‰ê¸‰Á7f\øË€ÙŞ_zyÄZM„Šc‡Iæ•R"5aDç¬ÂMSªÉœâhëüX‡/¿^Û¹K;FŞH±¹†×TÄDóŞÅÛÓëÄÁ³ +ôµFïí£ãcªîTĞB<r_Ì´xd™İAÜ«÷‰vèêŞ.IP=í ÕñÏ¥Ô9%ñ•	®w2ä„UãbKNmUbèø½¡£›rÇS¯rÆ³ªÜ‘&I2f°X~™fÌˆ±Š;öäY aíü ¯iê—Á#çÅ³dTvF:³³èØURa_—ífÇpuz¦˜LŞ;ñôwÄ‘*»ğ4üØ²Ÿ3µ2^Z’TLsÅcŞ‰êÀĞQëÃt\²-›‚b”Æcr:h}Íæ‘n:ÜÌÕ20K¹†[î®ñ<ò$u‰FfõUem}1} ¼ÆÄHµ8TcŞ!M{€Ş!–˜÷<—qaÙé°¨!SæeÈ®ÌÛîÁ]v¸<âÈ8¢*GIåçi„4\HY…Ä£uaŠ›ÌM#¬œî¥ºÈĞ–„w‰Û×:8*Ç:T¬"¯qÂÎzÔCîSæ€Ÿ=3M±b.!/…¡áÉ$“¯(
H¯HEg¬añ FXÄ’WÁ'è³o#=¡Ç°ü_ƒÅj@ìSÃ¯Ÿ°3n³Ù…©ãpoÁ°¥`JXWi±Ÿ…ÂûÚ_ƒ%¢ğfe†6ˆo»-÷Ãnª5å“ITÕÛÊ˜úÖØ`â9˜ÀÔo.>^âG2ì;:£V!Ì»‹ovB·?¼B¬¢ŠHÑ«li0¾ÂôEƒs <…KÕèrGËşqVk€6Š2TØ §ˆcôA¡©ö&hÑÀÃQw4³­·2dËâM²ÃÍ ø9O	‰«ºÙ>ÒQ×/¼â÷Ä°Nèiçj¥'pf¼¢1©6ªÍS(.¶88†Ì¥Ü„À„¹N6©ÒjËªG:LÓU”2Ö†Æ!Ç&¿cÍ¼.tøñ6“Ó¥‘ÏªıÇÚÀs
ïê/\ÑiA…è´˜nâÙ[¡¶…î¦DZÆ×33¨óW€h{,‹ ×`{İp=ù8¢š¯Ø¢P‘ôØ­(xå2yÕ_<®¹4š¬¨YšˆF‹Ï)ke!D)Îm‹…¢…¡ìQphRŸjAëìŞ‡­,7GºßÕ_¸¶ÊâÎ"Åª=ÑÅIv˜dÔÔí¢ÿso–O¡e-0z¹‹\ôÈĞ³1@(Z>D^"sÍ–ÕğZ ıÀŸÁ#·ÈVGœ ãŒãY¼ClVtÔ™Ccf5ùçEŠ–Ï3ä¡'¢‰[3©Ğ%wDÆ«^è¨(®gòKÃ+9´z(º	v*$	*V)Bì’¢Z’å]\²T™”‹èPFÏ˜.“g¨Ü.ÁŒæ M&‹B#Eb.çøÂ©'îMOh„,¼é:Wµ×³t'O)®«ö¬ò3°8G|X:ó¹??•ñúN¬îñ‰Ö!£ÔV7ë=å©qLÉÔÉ$j«#Ï@Yî ¹K%b}ã[-é
ÅÂàWÀ/ı'şÕ8Şé)u|§·)HÒ—“ñëËÙ‚Z‹WØ‹K´›hwJæ qÕ•G)®¾´PqÈ…"}Ëà7+_È…ª€Ñ…"ŒZT|ŠZL‘Eµ›‹jß¹
å¤•g‹Î
•«Dn·*›÷)ñ£!ÚÀ@cÚ@8ôóWO:§z2¸¼¡B…2„@úÁ
•L"‚q û}h²ı…Şæ­>(ùäó¡YfUˆ<"lwÔ©q±Èó	¼gLU˜Py|O1" Í5´¡†¼¢DØ”…k³¢([e©˜ŒW¦3ˆ¤…aK-·C!‹+h*»ÛåÍˆ>:Ûp‹jùùjŸ^	1Xü#	™0âF~ĞTP`“€GñF‡‘@GÂAY¥‚é¨¾LÔ>ÙŒª·¨(¯¢ª+…@\?o+,<rg…wGœ\Å·¬ñJ¦›–GşÅ“ôºc­eêh¨m"ãÄİGÃ:ÒéŞ z_Àj09ÿl2»Ô1ÚP_<<ä°^aó‘WE@ú[‡cWW{›yªÆÌå{‘¸§Ñ/{Š×y‚*;PÅ×€2âÂÓ ½™òÀËˆÍÀËWJbaÀüFpÍ­š‡(¹!
‘¯S.×!
]P7i úCRO×7Å¨ã°òtp¤8ŸW<*Îe§À{õ3¥åÄˆk„¾cdzVÔSt,ÇEEÑ’B¸ø„ÎĞÚÑm¤hå1åÁ,¸jGæİ¡áó5êìFš«³ ìOªÓšuœ½kZ¨|Áz‡6kºæ°Ùeº6:ÿ”…Š†É.M~›J.ÁÓI‘Hnèèê{ªg|1EbIò4Äš\M‹ê"Z¾£J¿bıiÏı,3ÌX´&¨L7
i¤Ê€#ÕÇDÊú8cH€°wãáä÷
­+!F‡Èqˆñİx¨e2”*ı|H¥Ÿûçc4km=ù=zPî‚»	?ª4¢Äô¢ Z‡ÇaWXhØ–àBå‡ÂBŒG†‹ßadh¾vKn8·ò„Ó#)
"¢€«çWr\›Pmx‡i<¨¨Ìèáph’B5 ¦?Jb¡bÅI–ÿÆ0£”ïØ±ªšŸ²ª’j]@ñaeºX”¬ ¾åòUî†"Xx±g„z‹1¬n±J+ÿ§å¹z=G+¢DtÃíz²é8h´Ïí„(©P#Æ Ów
¨¡î ıÑp·®ğ”~R¯òX	Æ*ÅEkEg	tä“ğ9hÌãIHĞVïZ,t\·ï¬g³XÑL›A?÷²”‚Xš‰sà¦i.'»¸LŞ!OªÂÔ“=ö±H,½cwÏö8Ë@1»3hôæ³>=Cş,dZ¤·e4ñ`>	”.SxìÃµÈÀ¤·U` Ê}X¢t¼DÄ…B&—!Ÿ[`)'ÄjĞc´"†˜g!šK>ÄêAí3E˜±ìv–çd·67ª;µjŞÙüü÷ÿÑ€nrŞ¢Ó¸ş?ò+…ÕB¡@ı¬æ§ş?®"EPNºŒáş?rÅåÕ<ÿµÜrnÆ¿¸V\™úÿ¸Š4û5|NÍÑÆ[£ÇJ€mn³µNæ&ÖsSR~°Dî¡*
¹ŒÿcõézõSRãkÒÂ½JmòÔ4½¾
0tº¶ğşyØyĞÕ\·aÚí%Rƒ…ëKİF×#¯4*$2,­‡Ì2à}yà‚8Ãß×\ıõÒt9" Œ.¢©#<Ë°%ê#—÷.[»Ú2\/÷Ü–æ¸Ì®àŞ	
šœg" ğÙ×\§B âSâƒÑS;nq#ï“±Á–R/Q2¢–AxôØÖ]ÿ4?Ú †+`¨s¬à!!îÇ #íÔÉ´“|l ûÉ:üÌ¿ŸÉ­e
¹ü*ÈÀÈä´îÂõÌÄ+· æàçÅv&Ä1µÜC‰õ³ÔÿŠoo ÉÓQá †	« Ø¸ó4ákè¾u*r‚ˆ‡‘²P\mñë¿Üç¦ïeS?ÄC:j1NÑyö™âz¾b&›ae=¾ nB°fÒ.û2±T2ê>¬’«µÙ>}k«Î÷nş¢|°¹»“
µg9!ãp$Ş'0|!•Û»Ò](?ëW4ôKÊypğJÅ²p¢aB©B2õì#CDª¾˜İªÛæÀıjÇÃ¦^ş”ª¦¨c"ëVäK–Ïd$¬üğe4N~iMéˆåÕN”ü	È¨¥»™çBy)¾ğy›„O×èá_;–b•sİ@™ª]^b¤>ZC·‡e|(6CÑâ-ÇYŠ¸b±X}Ló¥™'¸lã4„YèÜ	ŞâèTñ™87ı0r’ßº”U45t‹—PÆù?WXåû¿|[Ãı_1ş?§òÿ¤o}ÿ;3oÍÌlkM²[#Ÿ	n€ÏfnÂ¿üûüÃßÿÎx(Ëûü+æø×àßí HÂşc2èPÏtAêD{¼˜4»WC@íoê¿ÀÏêÿ_r¡vNSd
\Æ½”2FÌÿµ•ÂZ`ş/¯MçÿÕ¤ËÚÿ_šàÕÄiŞl€z¥î>¿V,nıÑjg–ø”$ï6¥-BX“ÀwèNP3ğ:¨gc&„Çx¢ÈmÜáÕe+^5‚ˆÙ‹Ñ¥kÜ¾ÍÏÙÃ©sbºÚ6Êû¥Gx{iâA/jùÒüÓÁGO;ëO³äI èÄ32/ ›­N ê’ÿF‹¿á4JÒZÿqW	4NIF#2Ü Ğø1†x?¶	+tã‘¡M˜i5ü*j¤_qg1 d9âˆxèá±Øˆzi'zÁ£ã(É°™wÜa#ñ`¼&Kš„Êæ¾7¼já”k	œPG	Aõ3jóƒ€R†ÃğÎ’º­ÅóĞ¾ş%ZöJvv?Û‰Ö¡ãy£ü¾ô&-7"ºèÔ
LZÆŠ_œ|Yš§_Ó”EÃšaÎ_äQÃv;¨vòb^ÒC{5ş#5ÄÃH-+ÉT˜}ÎúX`:Åé@¥’-ËÔùårä óÍ`œVÎæ=  ’¦¶ÿ¶Kß¦d’Şâõˆ0ÖKÂé†ÂÀŠ2Î®0ÆmœOz`F'ªQZİX oÎHĞÍáĞlBúğÀV”.£#â¿Ö±İ5"A ©ë<väõZ»_š÷¦z­{*Ecïà0 «¶ğzÈÖ†İ ]˜y°6¿¢nÒ= Li_´HæL–¦Õµì’6p- MÃ{o3]×ö9ìQ6§ËÁgÌİ¡FIhàd’BÎƒñ©Åc"^Ç¸Ğ¾0Š‚l+¹áÄe†b~vılÙ©I˜”İÖûgC iùXœ³áğmÈŠ#Ã*Í¡ha®ÖğºŠb1²xD1>@ë¯Ò¼b
–N;0B¹ş‚‡”ÏËf“é´kÃÊPîBCÒÀZ•’jš%ÿ>Æ6Ek§ø{a0L…iÏàR®‰3è]oeà%Ô¡§Ù'¢Z-æ©gJzM}ƒö¨X‹ËÓtš
87…‡fş@E(¨«ë€…XK™[_‡7gşÍÑ2Ëú_Ùèm’eŒ©ÿ]Î//Š«ÿeeeymªÿ¹’ôšëM®ÿıG¿İ˜½P;§)2E;_œl#æam-4ÿáÛtş_Ešê¯Wÿ«¸<ıJªe«û!Úà *X¾*7UŸ¿
oº:x,õâõ©Ï™e·8ŞèÕ‹‰wÄÅ6õX?Ì%]C;Áÿ}/Ë—·ÆŒ’ÿ‹…eÿ1·šÇµ3—/¬§òÿ•$ÿQrnÈ¬ IE[ğ¯ÎãÚ…/
üõ°·3.KkŞÓ"Z¦[nñt…?İ—¶éâİ*†ñvÿîIo±!ôÆo„?•ZµJØõöÚvrö¬s‰$ı /ëùå÷Ş_Ï¯.¯®!­¿÷>ü¼oÎŞ})ÚµúdË%ÿ¯¬H÷rÿ¹¸²6ÿW’¦÷?®åşG0”Á›*ùÇÜ ‰Ô§7@†V`²’úÕÈéÉ	‹Ş¯àÍVİ½?¤×ÍçãÆP¹ì2rãİÿ±¿¸–Ëçéıßbqzÿ÷*†Ï¹ì2Î3ş+kÓñ¿ŠäÇ©¸¼2ÆÜÿá/ÚÃa:şW‘QŸ.¥Œ³Ïÿåµ|a:şW‘¤85õL¥V§á¸&\Æ(ı_~-8ÿŠÓıÿ•¤qÎÿïÏ°óÿ˜A@|<Ó÷’tşÿBäš¦×3Ióÿ’fÿ¨ù_(ærÅàü/®å§óÿŠRâŞ •‡y_oÌ°ÏÛÿD4èş/”ŞâŸ?œ¡¶=ÀÜ½ÛÎ×šV¯?é
OÓ4MÓ4MÓ4MÓDR‚}Ü¸u½Õ˜¦iš¦×0! üó#şù‡ì3Áß¿Å?¿)å¹Í?	ÿüˆş!ûLp¸·øç7ùçşy›şùÿüCöÉ™V‚o>¼äß¡$¸‚"AøçGgjò4MÓ×*áŞıÛ3Í{FŸÑÂû÷oÿƒàûU©´nsfæïüø·ªNø}kèû~GÆOg+{oÍ˜3™™–ZşwnßKåßùÇz&”_*?ò}Dùß€º¹3ÍÆ±Óot-´‰ıÛ~×pÜ\îH¼õo~ëÛß¹qãÆ­ìÆ³ZÇ:®Ñë…÷4û	şÂ€˜şıÀ²ºŞw­ñÈĞë·oC¤™– OfË:¾gÌ–óDzqóæÍ7ë·ğòe¾¸DŞ/œ.‘—ù\îı%²ºR<=½yãïæK›¿ê|ùòÕéoşk…`Š3¿İ¿ì·Ní×â¤7ÎÑk÷[ÿh÷ÿ(Ú}3yëÖ»õéÖ§Û;»õÛ·¾¯w©¿@´!rê·ão6-sÏÖ Á›Ñ„7ßmj]uáêån·f|É ›¶ÕíîY¦>Ÿ†Öø.ôê³_8–ínPdŸ€ŸA}ËØ¥	îdıæÍëw~ğséÂÚ‡åû¿ıİÛßıŞ­ß»õıÇh¿Ôèê–Ûù\sšº‰¡N~mb6İ¾ùİ·~xó ïvşö{?üÑÿ'o¿„X>4Œ_÷äöì¬ŒwŞ½yûn<Å‹kÛV‹ oŞ~çíù7àóê¡õÛïİşîï.ŞyûÖ­¸­İ¸IŸd²·n<J¸íÜdO–‹·Ş~ØÕz÷vëæúè½÷o½ı˜İş”?,İ½õög<X€óİÄÒMV§·7Ş®Ş¸ı·oüËFc®İ¾nBñ?şá°V›7n|oÊ­–Şºé]­›ıh}¡]1ûWÁŞÆ5ùí™ÜÌ½™Of~9ÓŸ9™ù33ÿâÌ_™ù›34óïÍü§3ÿõÌ?ówgşÁÌ?œùG3ÿÇÌÿ9óÿ$‰ï$¾›øQ"•˜K¼›øi"›È%
‰åÄG‰ÍÄ'‰O¿Jè‰v¢“0vâ8q’ø2ñ2ñ§ÿ|â_HüÙÄŸKüK‰¿’ø«‰¿–øë‰;ñG‰¿•øÿaâ?Küç‰ÿ"ñ_&şNâNü/‰¿—øßÿ{âÿNüã·¾ñ×W¾%¨O%ş·~G¡q>·ßú‹14şñæÇŸ|úÓ×–Æÿîïà ÿ“¿÷O}ÿäİ;™å÷J÷<·B‘2RêcäEÉN›lÜúƒ¸‰órè/n µİşÎoÿG?şá;©Ÿüä6ÒÛúó§ó?¹u;Sâ&ıù³yxû¼CÄ·r?)ÜÂ¿ıVÎÊ­µ@â·¿ÅŞ®ßúğ&L‚Ûßdo~«|hıö·)¢Ê­[·gp®ŞI´CIö¿šùïfşëÿ;óÿ%¾•H&¾—øA‚$™Ä{‰»‰Ÿ'î%6ÕÄNb/±Ÿ¨%Ïõ„–h$š‰nÂLX‰>%ØW‰ÓÄŸLüs‰?ø3@¶H´)ñ/'ş•Ä¿šø×ÿFâo$şMJ¼ÿ>î”øÿ	ï›øm€T·TRMüO>©JÜ¿û;ÿÌ÷ÿiùM+æº¨ıiQ;ªÙf×2Û3LfÿæLw¦5cÌªËÁ7_~±ÄJïBË«÷.bi½ï¬™6]~]& „ùoŞˆ‡Œ¨K,d¨f1õœ¦iš¦iš¦iúÚ¤o°‚úÿjüùÿ4MÓ4}…Sâ›•ZåŞŒw J¨k'ğïW"ÃÌğƒ€·˜ÁĞæ™t½6‡Óıÿtÿÿ5ßÿÏLÓ×6ùö¿—	tüû?+k¹½ÿ³²²2½ÿqÉXÌLë2Hàì÷0ètü¯"Iöÿr ¾‰–1âşO>—_cşÿŠ+«+ÿ•bqzÿçJÒ¬xo½?àÁEœtôÙvèE‹7ÉtAõF0v“<û ÁÍäÍŒÿ0yh ª‡sˆß¤ñewlˆ{Şô	”İ¶µ“Lî•>.Íáßõ9tg•Íx®ŞùêíKDŠ 8êz¿£7Ÿû‘u×Òht/N%«wJò"Ÿ"%’Jyµ'D´€˜+­Œ€•¡ÉDAÀ½ëè@ov,’ªîïïî£o<6“Ö)2'të/9E„¡gcàûªÃ~
ñ8ÖÀn²0R§'Gfşzù>š&åş/LBËE71“Î¾şÃ*0½ÿ}%I–ÿP1pò_1Ÿ[^Ë­¡ÿ¿b¡8•ÿ¯$…ÆŸ}Ô©ƒ½LÿdeŒÿ–—‹ÔÿcşËaü¿µ\azÿóJÒ¤|&³mš‡¶æ¸ö élrh‘šnÌ‘ïµùdºcPüd}±)¹ƒ~Ø`É[Ëä™\1à~-èf­Æ\»–ˆ­D+K*z<øZ‹t”¶nzîš+•-’ÏäÈÏÈƒ½-åO²o…¶™×ÅÑuÒ6\bóæ‘ó°Fıva”b˜ğµÇı½™<r´“ôQ]”r°[ÙÍø­›PMİDX$xGº¦N¶h7×išJ+Ãa3mİ]˜¯ìn—7wê;åíêüI@íôê,_jQ èkngÜ ‚ì —Ï²lNö]'EŞ%R-“4z	|DFÃt‚XYÜ%ŒQ‚H×`¯Z™§+òË\«mIù~şîíâšÃò>¬U÷1ã±Ş éÒh¦¼ŠÃŒ÷ò¦x-ËµÚãİı
l`’}+4Ïè›ÎV
»N¼ë<›tÆğ=ÑÍ!p ÜwKKà~ï¡¡7x 4ïN?ÃC¿"ÑcÿùĞ"M4ö@ûÑÕoÕÄügO(K`OX{·,î^×ëj©–’$”Ä8ù}Â²ùı1,RŠLJ¿Ëˆ=µ#M.¿Fåò{­ê§êà:ĞK×½Ä¾Ö)zÿük‚eŒÿ`íÿÖ¦òßÕ¤iĞ«úñÆúúİÂsÚËVêÖ÷9e—}×} s»Wq#ŸÉç®4âÈn¹¬ÖïgYJ®gEG›è|Å ÅpŸ# ™’{@ã¾¤ë%ÿÛ07èáÀLi[Ïé/6€¥úM@J+¹ÜóäéTñû5M¡óßÉ.ı4ÒÿCëquuêÿÿJÒtıŸ®ÿãFùñ…Õ`ñ½¦ë½T…Iã;Öõçİr8èv	“0‚¿ìéÅHàÑ&[8pâ÷Éø/İÇÄ-~ğƒc!Ğ8’vÉı‡[[$İC:ÿ [-Óì»wIÖíõepÅV¸ûÓ|òº¯¥Ğ{†Ù´u¤Kíú:1·TXZ^*.­,­«;7w6ö«ÛÕƒòëÒ«Üôâêz²P =ygÜşãb3ößY:ìº×áëJªıçq×©SİuÆa5)c”ü·R(rùo¥˜_£çÔşo*ÿ]~šØ„Åğmg<¼FéKG9&-Ig  „èá$i-%³-©âÑ\Ød‰L È­e /ú.=DI$0yz2'KaâÍCi$Å¶Äa yè@O«¥9'PÇ^ÓíİÄC-ÖÒ@C%éMäS¢²Ò Nğ¿F×ğ« ñ"Z„#dcj‹'‚*6?Î’„ns
±É=ÉXÌrë˜„¶mÁ
¶}
––‡…®5ôC<RÄÍ,Kn&9«@o²ØRÔ¼‘…]WŞ;ƒ–Ešı0À¢ãØY–Ã›É?³ª¬w)~–3¢€èÁPÉ.ĞU…ÃÖ·t­éu¹ã—ÒâÙGSC{L+éiæ@ëEN8Ç@mõÏÙŠ	Šx‚\`?p.DO)ægî}ÜG¬ñm$»ŒØzWg!Éì5`Ç¡‚•[ÔàSwHÇ:ÆC{ ` Æ	Ö;ùÀ³dEgTõ/á e"dgò±fºNÉÔİcË~qjën²|èêvğ!I>á|ùYòà¤¯—&¸Ä3¶³’p–,-ù²Ã$ófq)(–á´E³â/à½ãecùÁx²úBoRš;{Ş,%»ÇzcÑr•!³úçÀÕ ø¬¾Œêe¶4»µ;pû·T‰úUè'ÎBÑŞÅ=w©7èºF‹áİyİkúY’*ÿ‰˜äÀC't„üW\^ÍóøŸk¹åÜ
È«kÅå©üwiÿóZâ*³ìÕÆDÿ$ÓèŸç©@ÚO›À”¬ñ%ë…ób»â˜œX¶N@ğr¡=İ·kC]N×h‚”Ãx˜º­¡hc¥V€bs:ŞE–†îß«¼î¼»€Ş‚‘ÇáWˆDYŠ\NÑyWNˆŞÎÀ¨«×2¬Ìƒ®“v03@ëuşğG©K;ÒŒ.-P*¹‹İ@ña•\­M6wjå­­úÆÃÚÁîöæ/Ê›»;°W`P{–C/½K=…{¥O(àî~yc«Ê.ñİ3#ÄrøÖëéoR–Ätq°—’
Ã)n1ù;'Şç†Pª‡¬R>(‡!"ç„­ki®¶ä)ò–Ô#~ÇÃF{ngƒ7ZªšÈ_?Q™¬¢-äŞøôáh·„•ëmGãd€ò¨ %e¸G!T;1Û3Z­®~¬ÙºŒúşöcş\¨1/Å÷IùQY®¨‚ï fØ@ôXÑ[»t¡uA7©o
²il™œ |£Š¯z°1Ê‚œ¡‡2°©X”G0+^Ø± C¾Ş ÌÛ¥òG§÷
3ç¦FNò»_[EoLRåÎP3¶3É M#ä¼î/ô¿…B.Gíÿ–W§òÿU¤'Õ›;ÕgÉ}İé§×Ùñ.÷5SÊgrì¿ä“ÕêşæÆ³d­ºñpóàóúÃ=à½ÕZıÑf¹¾ı9cnµ‡{h.^:ÔºÎä#ÉMÓ¤SÔş‚[šFÌÿµ•ÂÛÿ
«9zş³²VœÚÿ^Iº¬ıÿÔ(¢ÚZ€7[°¡Ó•dCáÅ€z-À3‹ÈkU¸íPÔÿèÆéaÅSa;‘š¾„o¨¾í ~½Ew1rA0’<Ş?xTI£
Á<ºs¤«U#àÙ Já5Ø€K¦Yä‘×ëçiSíÄtµl•÷K´î@ŸxÅ…WZ¾4ÿtğÑÓÎúÓã,yÂ\Vˆçé32/ ›­N	Şú›ªSÿVRóÕé%3	 Q’|aø»üñÖîFyëtœ’ŒF°¨ J£`.@àßdI°HX	 övi5ü*j¤_eéå) ’ ¼;D/ ‡Çb#ê=¦¸¹_­†!6vwîÛ!l$Œ×dI“PÙÜ÷†×S-œr-“”Œ úŠ¯q`Ì…º­eîn¾¤în¼9'ğ³h:7ÊïKoÒ–¹Ó‹N&uÒ2VüâäËÒ<ıš¦,ÖsşX ¿¡++—rf­Ù¡j'¡ıIâS5~gÖ·6k§IBZV’©$0ûœ1†Û€J%[–©sg9Èæ›-Éæ=  ’¦¶ÿ¶Kß¦d’Şf a¬—…Ó)O(œ]a(x
P˜Ñ‰jT ÖF7È›3ts84›><°¥Ëèˆø¯µFl·AHPHê:y½Öî—æÛºKï¥zj[ö”éTë¨@ïàšşuôn_<‚®ÚÚ –´µ;ÙÒéÂÌƒµù½™îeJóø¢E2w`²4­®e—´ky ÑhŞ{›!èº¶÷Èa¢°9]<cîTÆÕŒ.I›¤ó`|jñ˜ˆ×1®´Ïòb¶•ÜpbÈjMÔæûÙõ³e×mÛ²¥ì¶Ş?ÈĞ5Ø]e‹s65"BƒNâÈ°JóG†B<È0\­áuüôY<¢@e—æ{Ô>)?pà:–ãR— ”á/xHùü]B(ÍÃ#×†•¡Ü…†¤3´*;$Õ4K¾õ7{Jñ÷âJ3¦çöWê÷7·ªrMœAïz+/¡=Í>Õj90OáS_Sß´ÛÁZHÔDØİ8ÈNœ‡›vM\<P
*Éö[uÀ’q_¸rcæÄ×ÅáÍ™s´Ìı­áÖ½îM°ŒQú_xêë—‹¨ÿY]›Ú\I2Ì#ØÂ\«Ã˜‡l§(=p€$Jnõ¶bvİµŸ¦‹¦hû/º—™˜x”ÿ‡µµóÿº¼\(®âü_[^ÎMçÿU¤©ş÷zõ¿ò\ûjªYGjƒƒª`TLÕÁ¯Â›®K½x}ê3Bf	u¡ô†š2ñ¸Ø¦ë‡¹ØOj)$;x­ÿ°;ô3Jş/–yü‡Õ<€¢ÿ‡µ•©ü%i–2XÆÀ)çfV$OÖÖK×.|Qà/¶*å=ê
.KkŞÓ"ê;ÚÃ§+üé¾´MïVá¿ûwOú:ÑÛ½Dv7ñO¥V­æz ¶œ=ë\"ITì´¬æsİ^Ï/¿÷şz~uyu½iı½÷á'à}söî“H¡ùŸ©Wª÷Ë·êW&ÿ¯¬pÿÏ+…UXñşÇÊÚÊtş_EšŞÿ¸–ûYöÆJş17@¢õé¡˜¬¤~5rzrÂ¢÷ë#x³†UwïOéuóù¸Zÿëâ€~r.@F¬ÿË++kÿ•"Êÿk«ËSûÏ+ISÿ²ÿ(úON]€øé²\€xáôcÉÃGOa—ãş#Š.×H4á:k"N@Æ(é~@ÆÂ~NW ±¸'È¾2Ş@dİÍå:‘¤ÕÒî^u§R«{÷K):kğ*cö‹Öó|æ½L®/³)ÕùGŞ¿JefËÑ…r—¹úH·P²üõÀ€JÊ®>Fä´úÁŒû:Æá;CV[g¤-D{yS]ƒHşÿ[Æ!í‡¾QGÒÎàƒ‰”1Jÿ“[^øÿ]Ë­¦òßU¤é!m°ÚAU2ŞXEM…+i$¯khN…7“ 'pO¥P‹óuñè›lA¶š%è>·t¸?,»l5×‰÷0i5Ğ§T³?€Rì¶f
ïÊXIÆ¦Y¢k§³…»	ìu8{ ¤fwÃ2]õuÛÃ¼§[°PÇbf¯Ï„ùºYÓ4MÓ4MÓ4MÓ4MÓ4MÓ4M8ıÿæ³¦ 0 