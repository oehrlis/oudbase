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
VERSION="v1.3.6"
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
DEFAULT_OUD_BASE_NAME="oudbase"
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
DEFAULT_OUD_BASE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/${DEFAULT_OUD_BASE_NAME}"
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
export ETC_CORE="${OUD_BASE}/etc" 

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE="${OUD_BASE}/log"
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
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${OUD_BASE}

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
    echo "alias oud='. \${OUD_BASE}/bin/oudenv.sh'"                     >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# source oud environment"                                     >>"${PROFILE}"
    echo ". \${OUD_BASE}/bin/oudenv.sh"                                 >>"${PROFILE}"
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
    DoMsg "alias oud='. \${OUD_BASE}/bin/oudenv.sh'"
    DoMsg ""
    DoMsg "# source oud environment"
    DoMsg ". ${OUD_BASE}/bin/oudenv.sh"
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
‹ |NÇZ ì½éZY–(Zo<Å.™l#·ÀCVátvË §©bj„'ER"-E¨#$0es¾ûã¾Äý{í<É]Óž"B`œ5´éê4H{\{í5¯µOã¤ý»/ü³¶¶öíÓ§Šþ}Æÿ®m<áåG­?Þxúí:üïÙ·jm~yú;õôK/fù4Ì`)y-lÍ†ÃßË>Ì¿ÿ ?§pþélpÛ›ÎòV~þæX|þÏž|Kçÿl~[úÎÿÉãÇë¿Sk_`-¥Ÿÿáçÿà÷mDÓ0?¨æýýÀhÇY|â\u~h¨—³<N¢<WÛÑE4J'ã(™ªQ½Ùd’fSµúr»W‡>½0:‹²(Î§Y˜ç‘ÚøcCýaýé†úaN§§Ùìì¬¡z—ñô¯Q6
“Á½/z?G-þÙTÞÍ€/;³éyšÉ—½i4ug£X­¦Q^W9}ÖJé³Ÿ
 Zýt½»ƒxZÝ¾Ü§vÞµõ?´Ö·Öÿ ßEq§	}Ck<œe“4¸íK8:Õëgñdª¦©:‹àŸóHÅ	,<éGŠ×¯Â\eÑt–¨~:ˆpŸé4Êõ|ÇçpJ9¿Ã8]©YÔ0ÍT”\ÄYšÐ‘èÏÓÙT¿ÝnÂÔð-q‡³á`çÓé$ßl·Ï åì÷ÞfxäHi ÓpúÝ¸%z?î6·ÖþõþFÚKñ0Ž8ü™G‘‚š
¶§qE¢oFéívœf>øuN±%ü¯&gQ~¯lª- >é8þ+Os×‘¢tƒÞlŸŸlï¿XùèüµÙ¬¶LÏð>µÒì¬vM“w“J‡Ÿ¹†€†ÚTž¦êm8šEù7¼íõvö_Ô.Ö[[ÏjÁöAçð°»¿ý¢v|ô¦[SË~ ¢†§£ˆO2†_ÂÉ$#¿<èu_Ô^uv{·è"ÊNá¢JÀémíŸìwöº/VV je­ïžlïu·ŽŽ~zQkOÇ“}øjg¦]ùè5¸nûÝ[++µ wÜ9:>yÝílw^Ôè/$!œ,œÒÊGgökµú6Ê‰W>
Ô®ëŒÈ+jÁ^gg·³½}Ôíõ^Àû÷4áÚµúçA÷èèàèÅZðú w{8´ El|ßDíd6©OŸ¢þyªV°ÎVgˆ¼–¶‹<Ÿwð<Ô«YÒGÜ»+ÞðP÷w1‡²õ&Ï¢ÕºúX¤¸Ûq>…WÜàgF@T%”§¶Ó½üLÕvö_¨Mž´QDˆŸ›ç™jÆê;¼ø;û€?û[ÝïUs[}ü}°½¿ÿÊ¿!¸L³Á+¸!ß«_ª&Qªy^u1hr`/È#€—Ãsz_Tõ®¸TsºgUÝûçQÿ=Qè,šŒâ>Q¬98Û¶?[/[7U?y±gQŸ¸À^˜Àn²9ÃUBî%|¢&òÑ›9½K§‚?ð‰Ú]Õo7=#¶	G½{ð’knÕÏðáúµjžMÕšúå92ü$ÐÛÜEaÒIÿ1¦FíV>n\Ó×Ñ˜¯nW ŠÕý×}>Œƒëà^¹_åÚc¤bR6Ç$½Œ'_âv´WëÁGÚßÎþá ˆ×¿Ù|t]…|ô"mø>R ÀfWp	’3uÁ?†iH:€š†º¢z@BƒU¨€œ=b}n(àxæ,jð‡ª	>ÞÙëž þìÝ€¬¨jÿúÍOÍoÆÍo'ß¼Þüfoó›^­þü¹Óõèh~×dIgb@Ðûóü¹F<ÃéZ«¹ñ÷^ƒVÅîåaßb~xbîuM½P"/nªeˆEmiäyÈ¨Íš ðòÔÔ§)ˆŽÍÐ¹‡¦§wŸcšÁUÒ¿æçñpjþº<ÇûN«Æië¥µRoŠÛîÌ.«ðáÒÝUîpñp^Sg§åÝÒ$*Ó¤{<¶ï¿¯ÚÓßô«ysàÝ7]6äÑe(©"É¦j68D…)úOïYZÆè*d%šâu$Ã¦ùZÝðX¤ªÀYK‚µK¦Öæ@I¡y¶¨¶@j¡¡[êGÐ‰ÏT8Ng		éav6C9o©\ª±2$ëý4C9É¨åN±qÓ)ôÀjYyý¦ã?]:¾+…˜ ¨‚|’Né@sdc¤Lw^^+˜
þ8êlív4sò²Ó+  ½tVêFóäÑ”ö>/Âx„Ò¢·Ÿõõe#o¥³Ñ€F˜¦³þ9k¸/ì·f”†õnåãë@vK/ÒîñÒýöRàò]VÓ‡°±hàö²´7Ë B¸œI~÷¥»áîtºÙ,IPn£P?ÃÄnãÃrG$wFÅíÈO–<KÞ'ée¢F,Ÿ^Møüp§«¼oá—¿ç9	meÁÝ½47AßÂ¥Áu	,¼¡n€hI1Å} EØXî iL•Ê-4·ÎÃç§7<2¸ËGÎ1!å(lÅ›VG v-+sH@»Ð½µ¡}^iTóÖ¿ôäxý0`o°+ÉS¹ÕN†\¸Ãþñõ‚Nõ§Y>U—a’„*mã<RÀüÛR‚ùFP”V4GBmbcmý¹.±-MGÑ8½ E B€©•éjÅ©lìéØkL“pP4T:èûmGÌ"´ÃJ³°¼œ¹££É
Í³Mîù¨…']5ÛÖÁŒêÂŽ‘•ü1=¼ú|³[v’x‡£Ï³¡ÂHŒê†Á]dÒ
ÕÒì*ÐÂŸnÆÂŸ/ø1±Y‘g”0¡UÕª,{
ùÆºÑÈ‡1PW³v˜Ø,Ÿx÷üåªOŸà›ß«æ ðµ»@oÖõ5˜çÚE  Õp|AK9£´Å¥Zùy‘¨¨ ðþ1%š°:‘‚ÑZ
¿jšâJ}‹Œ]Gœ«Ìé­ía!Ëÿwò¿Q‚Tÿò/x<—ªæXU¼mŒÎ9	ëî„ŽVß'±˜„acûg£)µÆwö8Ø>ÍÂ‰ªyz²VCëCuh;i DHXÄvïC¬`ŸŒTòhB.	ã‡ª	<XjÅûuMÓ	 ©ß’¥xÝO‹1BÈNÂ`Š:ÖÔ¤·:¿ˆ7·7Ýìnf('…U øÄUÎëbÂ\sˆþE½ I8ßÅuµwå"0¢çÁ!€æoc;¶8Îiñ«náç´Íêê¨{¸»³Õ9&‡HqUÝºÕ£ü›Þì†Zyä2*Òuð÷‡4¢DÓ
 (\i9X”ã]qb1Uð‡ª ¾WÖ±ñý¿¬Øˆ+ÿsœ“Œ¤"d¾ WdéXñ˜‚žMû*ÑƒÙSUÚ:¶¡ÍhŠRÍpË¹Üc}Ã_@nìjæÓƒq5ÿtðHa«vUÿ—¿¤€á4^•%ïÂHÌ–sÁ¡\àJŠ¸-˜#—Í¿n6k•–÷k§ƒwGtW÷CdåãáÛ¶kËz/Ì·ÜçºÌ€}ø¸ŒÂj‘Ï–òh–hAhzA”.^+ê/­›Möµ7‡YF_Á'IÚÒ7žLé÷Ã,DÙ4Žr\9|Ä°³ÛÞ‡íðÇîUåÆ¡á4Ù·×ê{­áŽáÂ¼{&g\qÙp¼×@³ðÒ•Á¼îuÑÂŒL~E!ÝÞý90Œp ÿ\0äôìPAAjÆêaÞþËJ»Ù~è^éýk
|óeØ}ÔÎ6ûÆ³Ñ4ž »S¼¡Ú$$ƒv6>LQYiÜž·ß%mÕ~~½`à:pNK'ø‹´Üt®ü)ÍVˆ‡Ì3=aýQDeîEÙè—ˆµ½â®ž,+ë«‡¥fâ†ŽÞ:êšþÎÔoÕNŸ¯¥ÄRô5µé[uù\Ôåm¬&s/TtQÕÝÝîÒzž×‡Ó±ŠaW>ÆŽúÕùñÏ'è Z/ß«‡/»?ìì<ê½¨½Kšï@—}E¿Öžïü° ôÞ‹õç¬#¾xŠ¸uõ¿Uû/Á ƒsj#ËXÙÀÞ}÷gzøîû¶ú\]yÌwyKðy]ÆY{®®Ñ7ô‘´)úÌÇU7ëõ®³þ°â¶Â	>]¯´[ßìËG¹N+šÛYâ0‹ *æÈ7Ý8/jGEgï×Sü¢cj07¦„H—ùÜ<Ç,Ï³z uñ†·c¤„TUý—2R2Â®€nÓÙÞÛÙwyã\6Æqr>[Í\çžå\ëmmÑÑW²ÛÏ8ù'eæ,`iwçX®Qa’OÎµÂ»´Y{.H­Ú^HÚµ¾'ßªßÿo¸'ûháõÑ÷äéFåE¹ÛåØ¨‘ò•(ÿD£ÅBuoo‘°KÉúÍÑî‹Pn¶Ûhê_o²¢î”ÛU‘"[ŽAÝPE3)Œ)£;Íf‰#Éñ]fy–Á%È{CéE(¬œØ0Í:¯ø¯hlœNf$!‘ùŠÂ[Ë"åmÐ×?—Ç²{U
Ò“'eˆ’Bä³{ÌçÚPšë¸íûúÑñÿDú·ˆÿ¼öí·ÏÊñÿ¿Æÿÿ?_$þÿ.ö¿*îßÜˆŒ¸‰Jk¯¬+Hå_Cþÿ‰BþÕ=Fð«¯!üÂÿ…âïkµ;Ý;1÷÷r¯þ.cî£ ûŠÐ~Ä•Ïˆ¹/w÷¾WÍ±úÎAøèæ1öì°Y½S„ýÍÃëËkÞÊ(ºƒñØåsz—¶gzï…ñH‰ydn÷mõÝËým'4ŸéAë6Ì‡¬»ÌÏVŒïÕáúõùñú‡?n£Rª'9tÃ}–ÌônE{æ?TßuÿÕ²ÃÎñkšÂ.Æ†Œ¬&r&È½H¢!0/¨rž¿— ­y]3ñ¸§»øw“ ¾f |Í P_3 ¾f üãf |AÂü…ãüç&Ðæà<ß€ñ&¬¯B’ƒAàNPb)|,c“xn³ÄÂ‰ú*„HÅ‰¬_F sP)AT‰š -÷)FKéI–’¤fBî+AUÄ%à/ôxb’°@¸(0ŸÉ(?vŽöq½JTùqu
Š½­Îí$-µŸ¢ÃE9•O¢>+Ö%"ö5áâkêÃÒÔ‡Ó°ÿ~6É+r/] %èŠä‰{Šú_žœ°¥ó²… ëÏ)ÂøÉÓeCm{}uûeO£bûòlŽgæ5‰2´aávd·KG˜3–œßß4¸^è2‡œ%¦¨3¤ÃšJE9~sFLÇrD"ÔÚ#µ˜VKß¨³vŸ§—jŒWâ{Üu…žÂÌ¦4£leõ²¯š#õ~\÷š#£ZY]]‘>Mú…„ñºm‰£«&GJck7ùîúƒjæ°ær kÔìÅZ\ Áfâ’õ/¸¯þ§FîkÐ’œñÆí+Œ£íî¿¼"´§I–H—[ŸáÏÂ 0Äð«ÿAüê£øÕ=†ñÏ‹ÔÇ9°
Ô$“i”©6Ñ§d6>…?(Äd$–%6²œGj¨÷y 6Õ!b$ñI\žÏ;…O}'›ƒM¸Gë X•Z¯Ãÿê´¬ûþoÆ›]J nþñÿ½9!ûchè˜ýWVµ^ªÛ~B³`Þ~×h¿Sí³úËb[Î5=§çsZÝGhOª‰eÓ˜rVÙk‰(£à«Šàvâ.ÑÄi_.âATë8‡ÙÒRÃÕ+CÂ™œ,ŸKa+£Æ‰j/àOãš;rlðÆmk’¦ái¥¸Ð±`¼wxZ÷xKè1V)×°lú1xhÞG!>çLTg1,#èòcÇ—/ÊóT4$hœìî?Œ)Ë…zø—•É5gBDˆI½ÌX}µ¶ ³àâ	&»w[Ÿ3Î+YQÖEô}Çv»sÜ¹n?ÂdVÛk–H²‹Ýˆ½:þx^š,U²*ÝöÞwè‹÷ñA["´íÁøøÖ£wíw«ðßú;\EëÑJûÝzûaÝ	ªtìJâå/S]ÐÂÙ!Ø:î|–G‹°Zz0¿)¯ßÒÐÂ"›e¦6*ø¿ºæÑ’þšD—Ä4â¤pB•£ÛÀsúøš~—ÈÈ…X>bÿSã1Ò	ÔæÎ•Fcf¼›¦•bP½‘ý1Òû›BNoƒ$s„2üÊÌVÌp:¡ªO¥Q@q
 TvYíàhSýl†üÅhÀy:Ëú‘"2¤Š º)ªíïã‰'òhÆ^½+âC ¸ºJ¿üëº£âôÓd'3ƒrKˆüûÁ”–Òýþ&¹OÕwßÝ¨>¶ÇÃ:: 2…oâåá=²n\Þ£c*+íÄÓeó)ª¬püg( çÂP}†&ló*2 Øh2 hÄ;çNÉznÉZ¨”+Y•=lÔ«õIWapÍÇÀc¢©Ôqµ­ë¾M€šþå/’ÿøæp.¾T,ÅX7Ë™M	öªWîÅ$Dñ;õä5´6ä
W§±Øÿ˜ÎÜH§í·°gîÞ)¤ÄEÛ–o¹vOw´Jóõø=Œ¢šUj_$J¨Õ–ƒy·^Ëå×âþtÁèï2­~'GgÃ“j0<0}ëœa
”Ö…Ó-ÑˆO\JJÚ±ø{t.;c»ç8=Q<åä7.Æa¾«9{u[yÒŒ|(CÅÕ*rõ¦nýI’ÇßgGi:uµÀÆ²T@œ‡?ÿ¼y:
“÷›¿üò°^€d0Ë—ýi¯Ý1ë^Ï8éfƒèeú(ÖÞ'ê#n°vö°ý®ÖxWk—†h?<³-ÚðWÝ÷sÎ‡}Nd#´äA–³³m—v}Óa‹hXÄ—îà ßÖÁÞ^Í"b=ÚÙ¿nóPÍÑ îU³i¢Ó$ûàF37Ê@­Ú.æ\¸€Æv¸¨xmx©îõ8±cl‡W ðð_¿™=¬·p¤›”D…“ jFªö.)·TßWÜKç§Ô£¢ƒŸ-„?•	.‹7ù8fT EyÅã7-à·MTâÑ9_É¿…$TšESˆêÔ$gò
Ù«{Ó«"Î 6bER“Ê&—o oÃ÷æræz"]ãîD¡=!¹J£ÜÊ‹»üÐÈ³kõ)1Í•ðcÓ×ý©:LÇ R}×¨âs«?UºÜŸBxÂI*£HæåæXÏúh2‚4qkJâü<ÌB©Ž9¹µd7H/“ˆäú>×éÔøÌŒ£fS™–39—V§XŸc³&{þ=f1éüVcþ&ù?×¾-æÿl<ùökþÏoñó5ÿG\Êÿ17â#ÿGì_ó¾æÿÜe¬¯ù?_<ÿÍ‘°þ7»»Ë—Ï[Ð‡ò’ïö1Ú:ÿÜí¾xr£d”}öüÂ.~Œ¢÷9‹÷Q4	à–NPÞ}Qk6õï‹VÆö+ÛV½…g_S“îgšß(5iª¾C4ü'JR2Y5ª³»;/_ÇlÛü8WJá•D»ëÎþÖQw¯»ÜÙµ£â—ó†}¯¾û±ÛýsÏŽkïÚ¥{×T:˜(H3ô“yã~f†ÕP}÷²³õç7‡7ÊN*.Kg'ñ_³“þ®ß'¹[>Ò×¤¯9H_Y0_søçkQÁ¯9H_s¾æ }ÍAúšƒô5ékÒ×¤¯9H_s¾æ }ÍAúûÌAšn¾ßŒ7Ç›ÃÍî—ÈAšÖ»*stÞ×¹ª¿ý-ò—(ãˆí©¿QÆQ¨@$ˆÇáˆŸr&q€<o]Eg-ø/Ú_õsøÝuáåÚú×L¯™:_3uþy3uœìŒ›dêH¼·ô¢Ü-q‘n$	Ž›¨ ¼%€(ª„#ô©::ÜßkTÓñ'FœstŽÍF©zªÝIŠùg°ßýñýNûŽ5üÈð»Ûö‹Õ•¶áuS¨ 0AüTœ;½. Oz“B'åõRß ñ:bD`N±¨³]BEgÿ¶K{Æc¢ú‹sùÀN|½|0Œ‰¶=ËÎ$¤EFvWH#û[úÛçlŠ®;&Çß ek^:ÓÝR¶ÿI[%êú5i^2’uS2’•M2’m¡ïr1åv©HîX7IErÚß<ÉéäºK©HK×RŠT5úÒT$Ab)eÚVf93Ü>û¨,wÚ»Œw(„Õðµ’hàP`«[Ì…»D×ït"åaìš—¥æ8¤À^üëÇ#š÷ü;háP&æÈz«’rdòˆêx+É–ÑÒÃ5^€â&«^ùè¯Åõæ¸™/ÅVå„4?¥Ôciæ‹Ÿõâ žì 	ÚJ“a|VA–K¿ÐÓn4Q{€ªyø×þÅð& n»ùH<CkzöW¦[û¯æ Ó™²2‡¨J·ýüæÕ Ó/²j¼œ÷.SÌŠ]ïhøJ8ƒÌ±ÂÆT“øö°þ·àâD+*œË>?×již•sb’e%ã²¬nža5_HzYIín•HõùIT·N ú-’§n–8%ð»sâÔÍ“¦æyÑ+€Py¨óò¢
gÙ™MSŒyï‡ÐŒ”%Á¾‡9-F( Ãá’uB+N²šÔª;î‘¼g?r¥ŠÍ¥fOÛ+Ÿy6VÍ¬š\FôºÞ2—m?u·0Lg€²«h¤,¯»¼èB"¦ƒ?Ú=6ßØv›D6YÝý'²­ýF‰l_îôã=Ëý…æX˜ÿ·¾¶öìÙF!ÿïñ“¯ïý6?_óÿdÁÅü?¾×¹lÓ£Z	Ñ¯í9ß×,À¿¯,@»g!û6ÌbŒ¹º}Ê”ÄÄ¼Ú¡1Î]pVñ/ôD]QJW“‚‘¢Ó(KB[€/j’ÅI_/o VÁm4U~n¼x *0„ü*;àE^ÿ *žnr¢ô<È{åL	`o!:™d)‰ð°ò€4¾Š WgQ•ëV9Éô&]µÄ¸ßÌ'(ëWµÔå9Ü84ê_¦ˆ²bú¼ÕÃ\HNót4›Fl3°Ë²	6îŸˆmí ¨ÿ¡ÅrÑ$5´ô^ŸôÞmu^ûåºV¯©çjr9 5º^£Ë¥=øü°csCûè#‚†(óGÝ­£nçØCgöÎ*)Ú+EPÛôŸ(Ìú í%ð5ô?8ê@ã“ÃÎñq÷hÿÅÃ¿ü6ÿÚiþ¯µæOš¿<Ú\ý~ƒëŸ\¬¾Ùþ„OÌ~ÚÙþ´Ýëvë+í|¾ð_¤lw÷õSÁß}'ssmÇAŸ¨õM_JÝç—ÏÔNï¹Âyágíg=óáþ°CÐÒ>åWÄÍWÏ6(H²4 T­ê`ÿƒ»SLB{{·'Þn]‡)/§)!5d]1#¶»¯:ovñ‘eŽâ|ÕšÐÐš÷=Uäq[®Ô
c†á4bißoå9¿¥£à4ííl€ŠëÍ;H‘yøA“Þêìº­Fi½¡sÚ¼„!eÅ=8­0F€[EÓþÜV¨Äë9Ïæ¶:îîîÂÅéIÛi4žP ’íqxt°ýfëØÝ©Á¬?uFåøÆ“&ÃñåúFk£…$j­ÔðÕÞ³Ýð¨KÆÃèä=H\£“I¡t†ü	EBUœ¾ÐþG‡D}ó¨½ïºðõÜ/*ôú:`'wiÅ|»èwMŽë´m6‰ìÇ0¸°b·'}jÞ»x“5oê&ÓÐï·Gªk¡q\{ÙàÄé0ž"³ë–ÎÌ¥ïŠÌÆ#„QÖa¼òytPDÂ¹®åõv)ÖºÖÒæô·qc! Z¬%ÔA8] c4ÏØS¯ÀO†Çyß‡r5g8K&ePûñIr ‘Êy-`CX_xF¤¥ãIra`¿ðŒË/SrxŸ~óðþg‹†¯ þ…ÓÐ÷ü£ß«ÄRK{Áñ¯E—¨D†½eè¯»_ŸâÚ	õ'Ÿ;©GË‰ÿÔyÛÑSšßo9Ù¯áEèPŠB…îèO¼ À	½ŠÂwÅHZOõ8¸mŸûlm%¸ÇÚ_"óc2´°sB÷è„÷cQñ>zMÉWù$M(]cD#å\	ö>•Fs¹pv³l”ìåáÝÇ\qä—žk‚ÍØ%”Ø Æê>7í|šL_¬<–@é¦,¨BD¥tó`ïýŒ‡‰VÆ˜ÄPµ‰;Ä‡iAïô}bÍL‡_8ÛÇ¡Úì •¸Dd¥kÂ”«]¾Ë7žÈÍ‡¼Ý*‹Î[OÒ¾o0Í]WøåW· Ó•£·èÒHì–$uq|¬‚– ¼Þ\ÔUÅ–©HKŽ"m€¢ƒ
OGWÄ®@˜cÊÓò}DY4ª¿^ö-¾Ÿ½½yÙÂs}Ö¿öÆ£; î’9þ9††eÀ¿!Ù «úò4ã	ôútBK%`w×_J°`Žù÷#K(õÏ)NÌAnŽ¸­î
Û©˜Ê µËør2‹ÅÅ31m ºÕHÿ ×˜§7Ð8Ã™)dCö`m©r8{4ˆ5õ°Möc²“ƒ‘~¤IB‡Ôn´ÿ²Òž<T+RSÒ~7ûÃ³&æÆD	•B—ôBÌ;i7êÞ¬¥ùdœë5ÅvÝ×L'½Þnq¶Þœî¨{h2ÀLçÌÕ¥J¼LRÉ9@ÑKé‰üÅº•Ðžó'®œÜtþ£ay,÷¼?Ú?@·}?N|¹Ó^ZB›õÇøcu†ñGý+¶}öøÙœ¶ úWhû‡?šq+(]oO±ÅüÎ¢Ù™	êW¬{€´ÇÐwü<áov
µZ%Èkß®­­W~EÆ¯7ª¿FàÖjÕ°$'ÍaY-iÝ
–4á—‡åÆÌùà"d¼õ)¸°4¯*¤¾]]â‚§ ˆäæ­>Î¥Ê‰-X¾\Á)
@e¦ñyÂJ!ð·æ{•¢òƒó¤Tîa]|Tì‘z-]Å>Æ×(oòû•ízNCi‡çSjkÝ’~[:¬Rë¢¿R·†Ó+¶½S¯/!ÿÎ&˜ xÂÙ¼e˜¿&ÿY…\MrI9‹|A×*	·IíUdg»Ü+KÅˆo^¿Ý•ÃDyªFÑôa®O ÛÆL‹ÉVšïwÕŠ(àNûI‰ppÙ/î¢NE3Ö+%ØzY§¿üY"˜JÐ­ŒT„¡ÎÒ¤ezÃ’ô«ZY—~÷®ðÑ&]¿Ms½7Ë»i®ææŠ\5Bóåî|"¿Ÿ	¨€i: U:ñ·úý÷U›­
SF1^B[œcGniáàÀS@„˜¬šÙêŒÚÈ­½QãŠÕÇ“éUKmét}«¥µŠT¤ãU0™¤j/÷}_ü_Œ¨cø¸d°–(:‰OZžpSÆkÙâž	}Ejm]“í]cñßþ­V¢ø_ÄJ°Ôl!µƒ†·¶ ¨b°³½ô½®ýtñ÷+˜oO¼ýì¢ÈÜ~ÿ•¦äªù1È ÿ½GeÉÖ!M¾…ñ¶heÀáÓ,ì¢›âˆL"Ãs_¶™I÷F£Eš©x—É˜œËÃæç]£š3RIÆVe1»™´ÃëêN¯qS«+ötê¥ÞtÆå!*4€ræµÎýÓö˜IžÙi~[[âE@†G*ì^èÐó{èHÌ«;U·ÑýênEÁí,ÂÖtâ/»X=d’­4ÉÓQ¤”»*Œ?ßl·ååBæ•yžK‹|}||¨üŸÅ»Â½ê…]yî†Ï½•÷[VÙcà³I™y»¤F|:Ô2š­žsÏì›A…GÏÅD„¥p$»DÌi‚¡V¶·2Õ,Vú³êGÛšFXfzž¥³³sT-‰ÏÛ)#U]
†‡Òz 6%	Ùq­Úpmt®¾Òuíi]Ú"»ò1¾VŸ0úZ5×
xOJêû·Ú}?c?®»<ÞÓ»ïi†góg¸]€TùxZ­Î&mÌ²l…°³VƒÅÚ·'îÝXèQ¨¢U”üÂqI½ÃÌ™ÕÃošOsõMs}ÿûŒ~}‚ÿÍ±XW•ô_Ž}­ÞyË©­¬þšÆÉÉé•j¹½vÈîµÇ%¯ë¤o{[¢lëü¥øb„Õ9Îùþ^Qˆ¦´uÍI-ÕÝ/yÕ"Js‹L\ÚNŠfÒÒ=à6¤ »ã±üpû!ËõÅQ¼Æ4†”i÷z%Ûµ‡U^¡'ÀP&SØ?¯*"Ex‚B\]pšvVÅt5aZöAÝH³³VŠÏ‰å­<Ê.¢¬E!õf)=þðQqu?Ë™gx8›<|NHþÆ[Ÿcÿ’®ê‹–äÍ|N÷<5Ñ‰%S_Žòûßõ£º½Â|ã C¼ZÚxÿ¼[ãªS7•pƒÿA$wn8Öþ¬œSmÅÓô€î“•põwÒ”ô×}Öµ8ÀÁ]k5'#=ÙÝçw7Ï7qVÄœ›$<O¹¼^P|ãŽ‘1t^d„Ó©’Ï>0ÏQPá¦vÊ¢¢]P²]ëáb’É‰y¡â®'QÆ[Óˆ³ïùJïFÉÙôœ/êúÚu WcŒjå³Œ_CñÝè…Œ¨.,˜Ÿã’)O0 äîEâi¸üð“ªË"žxÖ+.ËR	úšëOO³YTP1Ðk=ËÂd€Áë/
u\3)ÝUwü#ƒ˜ÜWµNó…Í¿®5ÿXƒ1CÝÙ}R,X'j½2<ÊÜ8Ò•Eÿ=‹¹†™_Úaõ Ç7u"g@ÚÚJNHüègXÐ/ü`Å(UU©_¼Ô”û4âˆÍûâU#‘ñêßçÑ¨B÷ÌçÔD‡Æ¹UD¿„þJÿÞiDW!/(çª»ÿöîÉîåá•ÚzÓ;>ØÃL*F?/ {üÏËVÃ¶ýÏ+:êÕ.ú`Gýùýu¡tÀŠ.øyEOGsºxŸßc?“ÒTX¢ù¼¢~Ž¡¸-ýyE7WÔíâ|^ÕK2#‹éÏçO¤£þ‹éÏ›¤ëT÷õ ñB-±\{âbq‘óíìå>ÛÍÿ|É”…¾'Ë¼dÀ¯ê;g«¨£«ÂÏ‹²½ÕmÎ*}¹yÉ îu:êVÍQ4‡»]z½ÝÊ.[u%AÓ9ØQæw#iþŠ¤œ¶®©a}×Ç#® öXiÑƒˆ_’Bä»ç^´%ÙÞŸD¯ËÙís…-µêŠiõÂ0©ÿ*ðôˆ˜õiÁ"µ•3™ý"Òf‰*Â~·u‡ofîôD®g¦¦ˆ VfŒq$°!G«Yi4æÈò£Eìçe–ìs^&7ž(kP/Z€ü1.ämñª¥`áÓ€Ê$—ð /#,+dyém	**@Éß\V`~Ÿ<2ÿùˆŽ?,¿’‚×ä—^
rìã8=@Uz%f2ÄÙc„nT”#©#È‚ÔžDÁ¢ç:»;óÒ	õ¡×`Iò C¾ÚzT±ú°ÿ÷©Vo=¢'TÝÅ–8™7ÎêgåÓ*T‡¡ê+íwí‡sFú(¿m6Élâ++àÉ7 µˆ]µV0›âÏÊGÚ`Ñ¢Š?53Eõ‹°â¥žšú=®5‹I˜åQÛ‹òHÇ¾HO~¾[ŠrTûÒª§6&—äî?Á*Ì2ØN4íä~¥l¢Æjç¾À³^{Îo©>×É£Úó/µçHš„æZÕ A8/l=#‚×Ù^¿mü,iHæŒUV›–ŽÃVì|¼!‰:Ùëµ$,Y,6^ä X&|Ìy d}øãå©ðåñVSXîÍÖSèt?+Ú‚»™&‡@G_¬øfC`’^R»£(aæ¬ÑùÜ±8ü\µ¯+vxÙcÕÞù¥@ã“TÃiÿ¼¡ÆQ˜älkéK‹)ˆ³Oƒ"Z˜gäÁS×ç–â£ÀHhFXXP­fÑ`Ö÷:[ë@Á)Ãå¬Þ)µú€x+Ì†ò­ŸuD–Zƒ¹‘~€µÍe›]Ã
ó¡æ_Õ
Ã´Ú¡áí$-¶Q[+‘l©Ìj'v6EÒ®•ð€³€$‘CÏ;KÊ«p0~Ós?½YEÛF;ÈµÎctf  o¸*tä~J	†GÈ±4¤Ö¶ŸIh’&M§	µx•f—a6S[Œ{f!xv¸†|ãc£(–Bçs¹0rD‰sD—ÆŸ9ó–AW€„ÛØl¹ÁHTu/U>Â‚Žô,R8*ÏóÑds½*ÎÄ Æ}¾‘yOdN§WÅ—‚ÉññOXå_,ôüúºC˜öé…ey2˜Rô!êÏhm)ddzR	=|ÙtU~ýWýØßßóÃœ|rRX¼ð0Úœþôn§ú‚wzk2#;ïD¿›óP4¯Ïp âë¢ÖZÄ\ŠNš¥š/+y¤Ç½qœeõÝŠ”Úý‚E)myóÑ•ymëFê°sük¥ã,Ÿ:è•"¸ŒsŒpøxªßìB[~TÈgpª+uÞv·1,å5æÂ?×Îã_<Ž×ª\ýLLœâóïñè4þi‘G2ºx@‹*^1,sŠ šje]ÄÐ+ŽZ?¿\GuŸ,*¹u·Ô>Tªø>"NfÌ|8›±~ÂF4ê¸ÓoVÏLWõ»v‡ÐSÜ¶$š9–,› 2ÙUe¸n¹ì%CØe›Gô$…b,‹»•¶
Ai¶ŒÙµ_íÞýÈòqÔ×Ž‰ÖFµ9¯úÄ×ö}N±Xé”GWq„å°ê7$ u®@ï2»Àw²ÍâA_lhxp½Ó²
©‹5ãïfqúa¦Â{š¸Ô2½îOÔ0Ç/y“³jKp“Y¾š\ºÂë(Oùµð<NÑ¨ñ^BÝÊ€zBŸ·÷°ô|¨Š•_Í/./\SIÞqVW|5LT¬,8ÿ‰Ó¥•š›[Õ’--å²§$ˆ§úÁI#25Xã)§Ñ÷º2ne‚'0è`Äþ’Ì¸zÅ	ó¥78ï·Š.â>™™*ì¾âÖÅÙzÎ£­þCš´÷™råÚ$o’m5ïÝÖ[<¾ê¼“&;2·F©J’Ç¾V¤ÞTZ×*ûß´o±ÄÔíf.÷®èYÐ·Å!ïÕê@Ì—|Pˆ§5à„&¢ŽìiµxVâ9©œ‚¤£(äø,÷¨­Û<†ë?xP[)²]0yšAUŠG2ò#6Óv•þæ›öÁ#Úæuå—Ò±¢'c
Â—Ó0ý„f ™ömr¼þ©º›ÿê¼ô[Wsôxåa¹y”—ªh.ÇñÅª³ºª‘DûÏŽ!÷ˆt<÷Ä¶lûŽCù¬‹aÞE¢ða<ZHàûçÍ6~«Óö÷rÏ§-ŒwëGqg-2JáI·pˆœ««üN·ÃÝÚÉ"•:±¨Uo6Í»ÝÞP®p€"ÁõÆÖ®+WZÜ
ü®ÍÂyG­d
xàÕdñJ(TOÞí 8T¹>OùchØ´ÀÛk‡“3ÄKcÊœ»
n‚Âg®N£(±µ_ðjëýÐ X¯ÚÅjìÏ
ÆbÛGTn1Öé1«r/úÚ}íë³MŠl™ÜC‚t7{¤3?ö-/ukm/Q Š0æÝ®ß.v`#ŠÒ?ç‹Q+lôŽîå-HgEÕÍÈö¼„`}tç»vÒ§¤“$”-i¼aK–Ø’:nI—'N®T¶¤ÃSSÀO/[ÒMòÆœ aã2ï3Âê£¸ìX,X[Mœ¸¹Ÿ—ƒæà’—€F‘8›æ½¾~×úŠw©ªšËó¸®NãD¿{K2¿Á‚Ïó„½”ˆ×Ò´ÊgEécPä¢¡:…ˆ,¯‚JµÛ_b½¬…9ºÅ3ßË¬ÞŒÃX‰'÷nuâ O)Þ,Åp½Jé¯©Õ#÷Jôz®ŽÏÂíèª`Å&ë¡êK]°` -N¢ïÉ­qâØª
øuúŒ2g…ˆ9¿
DAü0[¢çbVVuH€µÍ‹÷¤™juw,¤‘Å¿‘.—>#•>êê~æï/˜7ªÏ·À]«a©·•¥ü‡¿çáEÕ³åÃÿ\ä¡þ®¥¬»ãªå„?•çòÛàÐJ¡x5ý(E;ž[·ˆÓs7ôÜM/=wÓãâïEN†r‹ÔRkgIQ%5á\*|å*Z{Mãã½ˆogÓ¢ËÏõ•¾"f5¹ßÌÓæc~“yA=2½ìaüdŠdŽäMzû¢Û«Î.º­<_Ô’^pvå|§é~êë"W‘ã¸EÃ­¨œ­¹SÃ
pä¡<Žºöû(²¯ÃKe§J'òÜ§²=2àš™äÄ¹DoñÔ´ë’WšgMc^bÁËél8ô"ì+Ç¬ÑãzšeG3ü¡ð\Ÿç”)SF¾e¾mükó:ÈO1¬â†ýÛ¼êÚûã³jŸ3?>Þ6¯¿M„»%xËÎ¥VçF:ßW¤#Vc»É:JÓû¥—ÊÅMåÈ?sp*„ZUõ>§¬ÒÊŠO×w‹Ÿ°ZÊWUŸ–¿é‘/{7w‹9êÃ±¹¡uGn£ì•‚K–yÆÍ;›ÇŽßÒÎ®6Ý¨Ôv6m¬ÌíTœû]«^Ë}¬µ\Vë¾×*ºé×+¨TÒ™ŸdþçØ· öHÕý,¢8"«W²‰Ã‰A+>!èŒ´ðí@·[íRŠÑ Ÿ³˜ÂXËÖTlncÉB“Â5æCSÞí®|¤™¢rÂÍÜØ‰% -·›ãà·ñ‡²Ô¹ýQe&mŒö£o5?’¢J(*W˜©Öš~˜V_¢·O^íì–Ä¾åÃ•ŒÕÎPvÏº±ÜJ9fÑÁÌÏ­ª<?/ã<â~<OÝÜ%ÜÃç6÷·Ž¾sáùý—±\«XLe'Z’Ð\¾&«úšŽÈÁªä°A¯ôùï«Õ&)[TR›z¼c÷R²W$óóôÖQl. ëüølAãw÷ú3Hûíû±ü³¶¶öíÓ§Šþ}Æÿ®m<áåG­?Þx¶þìÉ·ëß>QkëëOŸ}û;õôK/fHÀa)y-lÍ†ÃßË>Ì¿ÿ ?xþ»;[Ýý^÷‹ÍðxöäÉœó__{òtýqáü7ž­­ýN­}±9?ÿÃÏ_Uüü°ÿFýÐÝïuvÕá›—€JP¤Œ&?o%#ùqCmüQýi–Dj”ø­tr•ÅgçSµºU§Õ«,ŠT/N/1î—gän =í·ÔwRÆu˜[ivÖþ>PÝ‹(»Bïyœ«	†öO§˜R„‰J“+“ø¦S|Š©DÐöÆC.=ÁNÎ˜‡ž£¸%èŸOû3$êí9š\r&Ñ,ÒËhÐ
æm—~³(ƒ¨ƒ­ŽA"¨Q:ýHÎNa6µ+3¢{DÂ(jÐŠG…øòwÀY‚\·Béê}œ(W]ayKO"½Ø°8N±²W¹ï«aÊw¦ðêA”Çg˜tŒ£ó2¼¯ø.\˜TÊÏõHœWN¯@©—W(øL³0Ÿ6‚éÒÇÉ4J|Ng³0áï¨8cPšÓµ$ÁöbÀ³,7›ÓÔñ»ÂqeÆ$å4œ…!B‰9†)Ã¥ÿHÅœ¢¨'þöd@žbÌyf ÿ×N&#4øR 7ì+L®ä4|˜Ä‘DL˜ˆ ?½¢†³éyJkü)aþ#tÅ‘WAKöŸÃÒ”0áGÌ€¿Œ0†$|ËA˜õ4ð+Ü_£Œj9`ØÃ¼AOÑM²ë©¾z·>Ö(ôäò†¥)Mi¼…œ›È°´>µ*Ç1úÃc”#aHuççõ†™³"LMÖx: ‹5ŠÂ§Ò1¸± ÂÔéŠm46ÓCw<mX[ŸW‡ƒ$h)	hÞ\?B†{)…zÜ œÁ÷ø~¦ØuŠ)¡tnDör:$bN2˜2fˆoDÿ+<#ÜÉqaþ^¾¢ÛI¶öAÄ/Èp«Ñ8éâ¡ý(›†”<ŒÕóø4ÅS<så)¹PjP@÷1~%7ËãÁ²ð3Ü´‹xEh™WX½óC8žŒ`ÜE+Ègýs{ãtçœ°y†ïõDèv«a$›c¹,TAQÕœ¦ÊÕaÀdšóŽ0dQÖ•—k 7* 8æ¦Ð¥kèÖƒz-ƒ•0NÐÅ,*?t!ÌD¾EÏîà¨!ük4!8mcs:AÔ èWÈˆ(îV¡§"O/;¦Ñ$ßV×ë€6@÷¦Äk˜÷"p¼ÃEÌ^Ý¨ÌD0~!a’ËœÅïFÑâº9ñxa»÷a¸6QGAsê¯§wõMLòêíý¥mÂû@'3 X‰{ O"‹˜=ñÌ—\ÉSJqîS—O|
èÇäŸ&Ì¤9œ±NªÑ	¼iý’gÐiH‘½§(½@j­4øyY1ÑgÆxÀv$1œ
lä1K¢t–Ã¶3ðJÝ‘Äð…™àÖ£×Dá›~FjÁûRaŸJãR‚ U¿Äû‘Í’ ¼ÂåÆñ€p.Y8‚a}sl‚NÈ!ˆp	²@(]ž•AžžcÅ†AˆâfTÂ@˜Á—m>ŒŠ0H#ôù&ÉI8|¢‚23-Sù 2%m02Ü›Ä’†S¼i¿?ËÈ[H“ÆÀL³¾<±Ò ð`ìa½u„"$Rˆ<‚å_2^qh²öY‚PLÑ†å“ÖËˆÙ=ˆ.Å# F”"2Ÿž‰Kc‘àk
×K/fØ‘$
3Ì<Íg§hZÀ0I‚²È…M<%ÀïT¨Ñ
É£DVƒ]Äú²Ò”º'5œáéäìÚ‹Š¼Js+&7ÂÎBÝð8Áõ50È-»Òd9='§Â	dFÚÊˆdƒ‚üé>ÜQi&m$ù[7·©?Õ¤„L2¸{Â†¡•ý¸¸(Š3Í	W:Ñ²œÅ}Bš4
?H‰=£ÐAWó"¹T®0@$Í¸±^‹z!–êÍÆ)9 .‚æg ­}¬«2"Ð€ÌªyÕI%</KŽ€pÏ45
ô|p…¨ÌržÖ‘ôÔX<×b4Ará;?ˆ¹"ÀR¦'(w8t\jJ	ý‡E†)žÆ|]è¸{´×Sým|Œx{çxç`¿‡×ZXS—a«;<¦Æâ)¯¾EÍ=š+…ó@F«¬±ÀÍ%D¿kŽâ÷n~)tEj˜È×­ÒlBZ £qŒ@š¡(aþÞ¬;u í.e|3'Y½IÖ°SN)Î½z¥ºXÅ\š°f8À‘ç^–[ƒV5éå5:’šjj°²+Ä—ÆÁzAW‰©6iY2Âk“Z+¢9sœ3TƒpB×ÿ ’+rØ'ÀÂHjæç\L&’t+]Xá !¦‚¸ÌNH€E=.	@ì³T"”>£¢Ø€ç\ÑŸ€«™XMÖ |k½Š¤Aú­¦=5šØmEÀè¨Z?…± ~VPD±,nWbæ”Ãv†§Ñ‘£äkd¼ÝáESá< 4!-ù#q…pÊ5dÒ\sz—D‰€°ŒŒ­½ žGˆšÀàÏûXPwŠ“!žU¬„#úÔ§öŒà2 ™þ€¼M—:`›Þù@Ie„8üñø‚«ñÐ™Ê>€ófÀ	<:²J›…ád›Ê%* à	bØ0$Þƒ	ÝvPñ(%š*P8còÓV?àÊ\F£‘9	€ÑETDw¼§xçEJ0[ Ú%ìl£¡D~QkèP¢”µ€ÂÉ	€+äÚU\›Žø¢’·b‚Ð0`¨S\LC¿û‹iKI>äª&¡Ó¦Æ®óà	g;ÏEÄÐ ¡EºJ0Î„ùÕ.Éëû)Šy-ˆ¤Æ<VwåðBž1‰5G…°r±k”!ÐÀ5Vn”"Ô/ÌÌl®0s[tKh~£gS8$VÇJ‹…z¡¤«‚°‚î&¤C,"2I< ¶hÓ&°9K†*AãZÂ¬Ù
¯”T6`GAÈcŒ‡–€ï³×ç0Áj$˜lMÚ$Ö2
‰ÓÀIOˆ,[^pcgVvâp0haC#aÑìœçïgðmcb¬·”8©¶PõÔ<¿æè£5Q•]rÄb…°V$–¯té<Ù·øZº—•5Œ)2¥ƒÓ_#¢à8¼½[({HE=hèÞŠªa6P;h¶»H¾LcúÔÓå0vq¢dHºÎ€ça¶œ4 •-\¡õ¢¡AIu&€Û›‰r'ùŠD×¾?…ÆÚ6F0Œ@ú›…ghIxyZï ÑFW,Œ…ã+oX½·-	Œˆ2„=£©7€P§YˆD­ÆÜQ¨²#äŽö!¼50¼•Z!*“Žt¹úÕ°ÎÖWê=Ð@Hà`€.Èù ë¿Ï˜Èï…¿¶€\¥‰1‹e	©’	`j8ÍéŽŸÖ½#‚†–µ˜°Šˆn,J"€²4/^}@54±„¯ÊˆCÆ‹‰Â´ž”—Šb†Â¼Äšh±	j…UÔmðÊ¥0é‡©.PÂåÀ¦(«‘bFž:«ïAKFHâ“V£3fÐ€x
Ï¨àŒy}…èæÆ>Îg]GŽÌdÂícè÷yƒåœ>E™VD­´F{n·È^[¾m@¦¶Ž©m6„¡[Þ++Lh<rûcR	F£ `sJý AC[,y†¼N»W"ÓuZŽæNF6ÙT›šìVá	ž@+'¤8ä¯HG¢òY¹Žþuz‰ZkÃ”ý@D×wNû0Š×•€ZT2§iÊB¸|7À""¹'´QYãn&Úœ#tT'˜d²/,oe`;û×’WÛ*XZ«Î10¬ß$ŒžÆ„QMûÈÑ|]å4ùK±ØØ¥Ärñr±'i lLÀÆ^º«$s-® KÜ ÝžÐ˜ç6´6 /Ôµ‚‰Ù®hvŠÞ¸”c*=NérŒg‰VbIÝeT¢máD2LÂesŒ»Ç‹J)j^}AªàÊ&~‡ŒØ¯M¹YNµ,²ïr¸ÕÉD+ÏíMðt‹×â_Õ"Ýcû`´ŒÛm´°*P¦C£°Ù½PŒÍgäÅTP„”úk-Ä¡í¹MÉ}¨üdF)vq‘²Ò¢e9Æ+´ÇvAÅ¢¢©6IêùGtBÐèAfòY2ŠÇ1ŽáÛ°5m)k}¢œ‚Òò;Ÿ
4NˆY®I
«ü}zåƒƒ¸ Xà‘ê,¦\ÐiNt‰XÇâél*²¸¼¸?`ØIz	ÊñYÄ;´›hÊyÌ>-”4	ð~\„#æÏ¹éé•¯Ò“ÿÄä1™Æ0¢	°Rë-Ëñ €j‹¾D®>ëš™€õP>
å,´ÏÛ­°GfÉ€RA3òIêÕˆÐ^˜<5¾3Á1zVè0š2ÏÃ¾t@´I…óeYÐ(F³œr8¬‹(º@ˆ]‰Hó€2j×íê‰%Ëb8r0Uû'£]FôÈ‹J?ÓŠ™]ne1ËgÂ!Â(…DºÌÉn°s–‹»ÈÂ¡²UvM‘Ißƒ\	: Óè<r¿é#¶A ì±!âRt‘ioluÞc¾2ZÁgû÷ØŸm¶ìÆs´K}bT‘Îë<ž0‚ž„«[nbì0~ö~œõgc]úß‹AA‰{‹£D``çhåTªGâ"œ	ñ^<Ès´Á;Y_##oŽ²€\§Ñ·Žh¿Çö{°R~Äö‚§Üª¹EKF;0Žº+×q?õY) ÕµYw`Ø>JLÚÄ‡Ñ?OÒQz†ÌtËÜ˜FŽQ®½ÎFÀÍ©vJ
>“Û!íQ!l}]³ wÂ1Eã>Œ9 µ–£|7ÖÔ6€jµ®ÿñÏðN9^T©È«QD£ª˜ôÉ’èA|=z¹xàFTÁ§•ì¾c*ìv¥}–ph¤Q òŸÆÀCŠÓx0Sz>å›LHÂðº¢È€g‚
bkÖ	a„$W°GBbã)OƒâeV(Žñþ=h¸
¢™
Ë"F¦’j|S½«f‘^È29ÖÎMº’	$…oWÄ%Ù¤Á×}ªcÜÚ‡LÙ™féÐ‚jhÒé=i9÷ö­ŽÏÚbƒšËät!\zcÂŸæžHÃÌ%Ðf:A‹5 .K<W“é$Ÿ€ÂÏNYò[3ºk
äçˆÙôê¨Ä™-4v=(!N­Ü!»‚É‡‹$Æ‚¾Ð„âOr E‹'Æg3ý=ìSrÅ…}kŒJƒø…§ ¹ö#¦WÆæöœ–qF—Ô7'|¢Ú­RmÍ.ZÃÍArtNC±FŠÊÉËïæ1WÝ=$}pŽO×+Éœ¬…6xÀÆ„ÐžºÈ¶§e;‘ŒßºŽöÖ¹–þ’ *ÒFÑ0ftîxjâ4Äö¢b.ÖjFDÐGû¤
cÅÍ‰›†4wÙ&{èÂ:	¯lõCfß€]9FÆJ¤4Q>±¼‹]GAB
`»À+,†%ÞÀÓ;ÍEÞvÉË• ¸*u‚o†Ë©ù>p[ó­•§õnØèé~
‘4 ŽP›sqj²Ñ~ÝÆi–X¿ÌhÂŽ%Îñüa½)ö¢-Ú¡¬Èj8Ü‹4Ï£\G„ÖGV€"L¦:(I@Ã½Vo¨ãÆ€A	ä™®¡©­Úe¢˜I%i£9²³0Œ0îembâ¾lR¤€*OqAÂ‚rõ÷u0–Z[u'Ã+ñÙ[#gª?Á±vP	.£H<Â²ZDÏu°—6s)5¨ëW†hb,Ë5ßÕ"z5vg¤Qæ:^ž#lÄ¾ä1¯âL²!c™–°®'ïëÌ…y6A»06R|Hçð¶Ã³ÁÐÈ
¾ÅøÃ×/WG;§è=¾ŠT_”Úv‘àäÅy‚ÑwXØ)Yõµ‡T›uXÜ£gù‰±Î7PaDe]ÓéhÆoŽ…TÙŠ¸îH-
8.æ$¨…ggˆÐè·5µ-ˆ¸&pîx©-Ë—•Ú„Ê¢1YŽÊ‚x‚SZÿ¡„'§I¨8i¿¾(½¬È ë)!•­êøÈKÿÓ;²6Í~Èa„Î•D:äJÖ÷ie=áÎ3—§îƒ°"ìôÎ^êJ*Æ†21
,Ì2#ðŸÎe„ŽCop§‰PDó*-b…ÉŠ"ãSYÆ
ÄÇa©[f¾‚1P{€Û¬F½ó«œd`	ó¢AV­}ÚiQ£õÉ{ãI˜ÄÚ®ÄT¢ÚÔ`i%TƒYÆö3=:ÈŒR9z€p–l´6 Ây–µÿM÷2QËPOX
l(¢ú,íM±¨(i1u…›n&Ì9û“&'Ì­2±fÈ8B&–Ø¨a¶âºwÐ‡!J¦æâÂºEÒp!%žL
ÈåC0Âô"»-sx÷pÈŠDŽšk|lTão„ ~s|hh)IîÂÅÇ)GˆÕ®^ž&pÂp='êR®OCäký2b1a†$Û°VQa?ŠÜ¡Ž°`$aG’Š
b%8Ág‡ºúÚ¥{tÑáX%BòB¬V•te¸p„¡¬üÐZœk£ŠÓ~?ÌI2cu]êô¢^Ö9ÂuTEÛ•Ýöêå35—Çè‘¼nqªÄg§V.šsñOE£ëÌg$àgÏÙé	KGèTZ-ÆìóyÔY´dZ+µsê\4*ö\ÐÓƒ™	]¦yrÂ .ˆ1ËØ:ÈØÀŒÊÈI¢x)7Á»‚ì€‰CzÉñL+Cé“Ò¼„»¹¨Ä#ÿøz›¢}‚ö«lbz@ôÁn­9W\Žˆ‡»Ü=	är,ßÿe…U¤˜µ.
Ô·ÖaŒþ05…³Ë<¤Q9Ôšê³Ëp.t[øò•«fd$›<OsÎë˜Û½!wƒêU‹q“…4 &ŒÉj¡Ž£–Ø†aÖo#&³·9÷_°—[Í½53²N¢(kNÓ&þËá_&äOC˜ÆÁ•Ç	ÛØQP	Ã®ÂîûqÁPÏO#¦¶CbrLâ­Ö1öÖˆùFtm‡LD•`¸ ‘c|tˆz:)\³G,Ü°±—T_1¼žó¨ ¹¸§Æ‘=ð½)%Rè„!¡1õ0ä¡5ZŠÃ¡)v0ŸYÉ &ZÑ1‘NÁsEi×p,¤H£fÁÝrf0ÒÆå«º1ðÒp·iDç)|z÷@;¯rËµçØ¸¼‰9’Ú T ²-:¡0ôFAbØ *	æ,¹w´ÉÐH±„ýy›mƒtv:Îø=ÀÜzàhÒÑÃy^¤¶H’Gx¦³mÜ*Ý`ÙÅj9!V¨ö4TÍ”WL¯&$+¦EèeÂˆð•ÈQ˜çNÊG£`–Ð~ã™Ém(L®xtABJ¯°7…¦æÂèUòEÐˆŸëOè/¾S”fÂQv´0Œ02bd%Ø+×‡åŒA'$°r2õÁ¥i? (ðrg	M² ~óI¸"y Hš@#£&›Í"	`ÔÒ{¡HøŽÛay‡(ý®ÃƒÜ+æDŽa[é o nô£:’¦«€¿®¼Løb;¶&¸'Õ‰Œ/U¤m•­:Ï[ R  ,õçœÐ|¾DyËC«PÏ0T1*²q6Nãd†Ä@ždÁ×”ñŠÑ
4•Ä„Ô”C%U„É ›Šx_šC®ÍÓˆÔ|ßdjÍC	ÝzN´¤D*]S¬&ú¢ñátìÖs£r†’MËj ]äHûœ¹º™qb2;õTÎM”ˆ‘¡kµI?$x§‰a-Yíð8#ÚI|Õ$šÎâé•‘KÖ )TeµÒ¼é¯0'æ$üW	8Ž‚JÆûöíÛ¨dJ<\½7`]_Í»c˜‚?’kÑ6–²éTÈ’žu’²Ø‘± &%ƒ±S…½+÷npR’®Yòö N{&ÜÌ5¦„w2 óŽ£ƒ½º	[r×ïèQó¶^ŽÐƒÂú–¹Ãi•eG
G×Þ#Bh~Øƒc#Ä÷CwÖ^‡ÌÙŠœ’Á«† RPÁæxÙ È(ŒZ'q‘Yäò<JJN($TÑhh)´;s€´,â`(âVDî­ë˜©žÖr§#JÄ£ÍÍ¤þåp¦}Œn
3¶Qua?KóÜHB4Ü¦
sÏYKÃdsýž•—‡3“¨³±‰°,÷@—ù ÈQÁñ¨BÌðü€á 8'º+Í®5G Ò:WÐTB@7#œ˜%è!Ç{&¯àØÔ;‚Ö·-¬m¬ý2Ç‘6¨ÖœO­ƒÓÁ²È½A—xé’yS§!ÎJ<gTp Å&'ýd‘f{ÖåÖ
ªÁ3‡â_“›`Ÿ˜vw	Ô€cF8ÉÍ¦ƒØÌÉ4n°ºkÈòb1L.8;œØÖWÊyÂ¨6âtaåÚ¶|ë(u7†Öøm%Ý3›êH¢¼õ'š £zãŒÍîª
(èJ%g(’púBP
Áà9f@zÛÕ;˜ÃÆªªÐÜF(u8%'”ÈaX}È¢Ÿ…SIQB2Gtê3ØrK¬ÎÁž¶šÙ¸]ñ¥—²è‡JœÔ¬`ýãRo°éÝª[g™X‚9ËG:!D±!¾c±‹Æäû¤ü¸;rêRdï­Œû°³IÜÖ‘2Qtè›.È£ó±‹~.*£ƒà0Žß¢*/Ðœ"e	ˆàl™‘]Ó9=•AÁv\Ò@Æ®/$~˜}eÛDÚ¤¿@ÿú¼(M&ÖB„±Iépfm¨)9äjý)ÓõgÅ5<GS;!ŽLº)©-Ù…a_6…Ç1?³ËÍ„½°k”Áe*2ÐìZ°ñ‡™¶-–¼­4ˆx\µO–AÏî9”<BV¶ã©]}¿Ž×ßÄ¼¦ÝËãÁp’gqb”[‹³²|›q;§F….Ž`öb‹Vˆ­ÎÐ%¥íåŽõÐ˜ax!¡)¿d·2¨ÃáÈacË™TCbV‰¯m¸|#Ž~a÷>ÕºpOÂèèzÁv¢¨Ža„#&:[Ù
Qu(3¸=ŽcõƒÜò*µàU4lsV.E$øävÞ¡‹ièð'^XÝ‰SÀD™Xf5ð¯ü¤Î¹·]µª³lÇ(‘7u¾…\k‹¬T`,l›–ãHíat¨a\¹í„srÈPå¸&Ù¤”"ØÅ\ŒTÀd0•+±£Mˆg£yä;¤k51Í&”ÄÜ»ÜD´h‘‰¼µvÍ\ý ÀÅ.‰Ò£¹{Ì¡ö¬õ„B ªÂ’­æÅ¼…¬,j3T±[?UHQÖÊ&¥jtf}P9’dÁ ¨ýÙeNmñb¢]ÑÏáÿUŒÅ"¥¿sÇ)ïæÓ:µó|Ï<ö¨Z5êmÃžÏàâ]HÀÎ¼õ»6
Z.‹¹¥E/Ðh¿—…BéÀá™ 67™©A!# :1*”×¯!ÁBº“ê(è„žÅ>aTPrvx‚²‘ñ;¥€,çþ¤ÅÕÐ•„¬‹cØ¦Ü:OZæp¦»…¹£<Ø€(êú5d»bG ¦AëýC‹”8a{„÷Aùh&cÄÖ‚*œœ$tÓæ LL*‡RQ-]§ø°´“7ÂJ¾™-0•§ðFbVÕ(^ÎÏ²šÊ"¯Š–Npn¼½@¤„ÂÁMÆb*TÄ4l…ðÝäÜ#[ëlúxí…‘ðN¿PÉCR¿+EÄ©HÂY`jF²ßÕ1U@E6"²/°\ŒÊe±“A”•Q¥éeU%ƒ`È,ýÄ›ŒXr†­’Á|š7]o¼@CñYr[ª4Ž\†ìÊXÃ†Ÿ­©I5Ã©œåcÝÝ6%¨{IH7bà ÑÙSiKºí$Žrg/Áò½4øÄc–ø×i<Žl=?ÃÜ„ÖÀÐs1FçÓ²|Z·z\P\®M:èÏÄÁhG5ð}ìÂ7ˆXÎÄ(Î¼(6îYú€ß–î˜oÈ1f={+bæ’¡ñW*r 4Ez™…ß0ÐFq7åÛÜÒ|Å4¦±È"gæHèÅÔ=jNÚ›úoŸH/MM…|kÃ+Ðª£Ãe½èe”ffl‘õo"/¿ÀàGÚã£¼æŒ¶Bº„Žt#\»ÌG
”p¸Š^(LÊòó"’löc'éÝ9”ÛTK)‡’5ŸDfñB„ÚÅkÒ™Kà³,Yo""o°C›B%'Åò–z¥‡Ü d¤Ô|#ýðã*Â1ç…4ÌH2±Ysä‚;ÎÝ×-9[¯âüJrhŒ35v8õ\J0mH@ ÉÂ°,J÷žËI¸/JÊÍù¤‰ÓÛé%`4–/DÓ/Ô‰ŠSÊ3'×Ê÷ªxÜUÓ©ÜpËú¥Q&’ˆÛ0Ò[œåT¸ÐÍ™ÏØAò—Xÿ.HuÒ‰E6í‰ó2c~“Ïõ…e12¤[c¬“¨ZñPy²þŸKü®GÈøœxNÕä‚WnI.Á¼²~È÷±T'GÝ‚Ê¨ÛP„å1ÆQvÆ˜ãÖû"ú6ïºRƒã˜uÔV¢Ê»“0wvM¹Èeàî‰°sÄ.ùàHÎ50n¯¨¥ç:ß€}-ìl¿zH”EÉfrr‚DzÀ
ÖÕ#Kœ·LñL#qø<šáº$K±˜W1×QçnÁ ëœ5¡8¿§ þi¡0±¤üV‡rU›EßFÊS¡BåÚó&i†Æ÷YHÉG–Oyïói¯4„(…;¿½±X]7K¯Â‘xÊR'„Ž³·ìZŠë˜W[éÊÝ1= >E³ÂTrO/X˜KMNƒäó§ˆTú›œ>˜R:CS	ºÏÎ´8‚º4¶{`½ æJ@V8j¦a#©{8’úÇcŠn«—[ç±O’U²¾ÞR‡º¬¥.9—°Õ1Íj:ð¦ 2â2]Ê	¨PãLÚ)LçU‹9´8)O ÷m–ÛÚ„6B‡(È2á6º«6å÷L‰×ÒÃqÁ.^*¤oÞÇ0žhàTãpü©ÎÀ´4âú¦a_„8d¤,êëOšS`ñ<r:'N7s	Š»&%<(‡L‹ÈAæBÎ‘·X( ­2"jÏ4ouî’ÈñDÀ
‚’¾ûU)½só\Ã+mÈsiÈA¦£š-øf+´yUêŒ"ß1tšîMv951¯ž©€\îÙåôN»jGÉ®aÊ`ÕÃl4ÀªZ†ê4¹fŽ§r;¤ßGÂ98ˆÂEÀ%-(.ÏR.:G»Ó-ç+nË¾pUŠ"	Ï.Ÿ‡lÈÒÙŸéÍD„ŠÅjvEÖ§š¿I&É•6Ð4ë»ßã)Ûß$¿ƒRQ_¬J¥"÷D¤Ý’ãtÕ”KôÈ%YXªë><ßE”„œÈI5ÌÄîÏ-ÜÚ“u.k[£s®™Bîþ	RpK¦@¦Ô\çXõ9»-íK£†›ÌNãVE9ÄW,£«¦¬ÀËàIi©œ¥678Õt‘?Œ˜\ ©•Ne‚1nRçE–¦$)Û:¦Á™¤ò`˜4E`K
'‰­‰!˜‡*GÐW 6g¯°´9bud™Üª¢3ðŒk…²ŽB)¢Ó(‚dl«„0%Ü+Œ©\¶úØÌÐp)RpŠT#0õ±uéé`äªMF#²© XñðÏEdÑ…eF<)¦8âê®È´	 €ZJª 8!ËAÉ¼Í2OÆò—¶¹ðÂ8q°*·2ð{2÷1
«êc:'°á–BÓâd erîÄî‚’,£Ã(Ž."„!·®nÀ|r@‹Í°Í$òÊ¤"sùAuÀÇä ™¶9Õ \™t7Œ i]Zˆ&Ü(©Î”¾NþÃ*:Dbå¢¼VÐ1š)-¤£}ÍÚ4ÃŒC÷ª«ý¹šRI›N*°„ÞàåÇyÁ„Í¨,&,Îe³Wü)Xð#C8yªMiX;EÀÀT5¬?’ÅÄRÒìª&oi–ðØOÇÅþ`wNôG†7LÅ—¼¨¾°lÛ¢^¶ÞKVÑ)„'éÅ† ùá¨óµ–¯t™ƒJ,9$¼Z5“EOãt*Åˆ¯é%H	"µéŽd'ÓpðmÈ	±ÁIx5¦8§Ô:d¯*…”¦ÑöU)xÅùBV
5úÜùŠc³lÖÐ%Í©¶†W¦$ÚNWºÚðÚ ´$}ŠŸª“–©‚Ÿ‰ç‘4D+Á;«?Siß1/q©ü¸ÎÌ°JqäÏdP5µ¹¢æý=tšv®i"yg+.°8RpmÙ\ÓAÔ’µÀ$–ú0¹öÜ°V÷?¨½0ƒÓÂ7Ót|Ñy¬KË:f?“©AÅä²™ññ‰:í„ê‚Œy`ª±iÙTc¦ñêŠK`
Ð6#"cè²9iÌî®§SoT
[­o´°¸UÏ<cç}€#æée®A:Öò[¡Þ›(R§L­jýÊÙÍ¨2»3ùÑ.¶®$Šqß„åë)ª\nWº¾ Ù-ÎklCóû¶¬øÉÏ6hBã³ø<•ò:µ,Ç³Ñ4ÔïÄp¤^©2—gÐ%Rt¦Z*hë¶›°—’]Þ5ÿÈñ3*~R4išˆ %žõ‰ëì:~»
e]Ðè±„ŠÖãH2)˜Fâqî,ô3vX~PÅ”,y®ŽmlôÌŒdºð dTpr43¼Ä©cÔüä1·šÑúãFt[)ß¥è ™.zžâN€F ,–HIÞEÂ%ÿ„æFÞËŸZù¬ÆÂå+I'c-°u9l­W·øBáÉ©A&W¼¤ïU  @“BW"²Ž«Õ±Öeqÿ»kÆñö˜âúQÆa{N1£u‹ƒœÕ
\$~œ³«_ž´ÔQ'ë~¹o/Ì#¦yord« Ëd4y`=ŒnÀ˜Þö¼éž¡;ÿRC€±7î#´u¹>¬4‰³ØdóJÔ¢±z‘rƒ«ä Bì0ÀŒ’½¡ÃÏ™ÐæQ#–‰ÜŽŸI£'À†+£’ð€Ø4ƒ­ã¹èÉšÈ¯À—K¨–M1wð3º
°

°ª‰Y“ ¬ÕÓ¼ëH5ðí-¥ep$5ÙîÏœ'wDáÖUz…Y!?Q\Æk(õð&°xSŒ32;Ã	¥]¢ZÔ›B6|¬žj/…„ìOf}AÕú¼Ö¬Ý]aé c>\ñ‹ðªDøÉªà"òß3[€ú8„îëx~úa.Æ?ìËwªZ0¹!Ž^³;	®{hße#»t ZÜ2›@¨ž‰ÍÄ–L3¸qÿNüP’z=A¡ .aÖ²@§.$07êmKp±Azñ’‰ÝÓ–	gTúQ‚Ã™Ä½îuÕNOí¨;GGýãŸÔ«ƒ#üBüpÔÙk¨ãú»ûŸÇÝýcuØ=ÚÛ9>în«—?ÃÃÝ­ÎËÝ®Úíüˆ/'ýçV÷ðXýøº»¯pøwz]Õ;î`‡}õãÑÎñÎþ4àÖÁáOG;?¼>^ìnwè…ª6ÌNÕaçèx§ÛÃu¼ÝÙîºkRµN–]S?î¿>xsl¼‚A~RÞÙßn¨îÔýÏÃ£n¯€±wö`Å]ørgk÷Í6¬¥¡^ÂûÇjwvÍŽÎ&mõè¸¯{´õþì¼ÜÙÝxá³Z¯vŽ÷a
‚]‡W¾õf·s¾9:<èu[ŠAƒ ÀvzV°ì¼é˜ º0Æ¾Ps9{à˜p»ê§ƒ7È"`ß»ÛPP]µÝ}ÕÝ:ÞyÛm`K˜¦÷f¯+ðîÃ AgwWíw·`½£ŸT¯{ôvg‹àpÔ=ìì!”¶ŽŽp”ƒ}F£g-.7]µÌc1¨ûñãÍþ.Bâ¨ûo`¯ˆ%ÊÇ¿óÃQ— íàDðã,OÏ †bÄhPøÂ"ÆO€bjï`{ç‹ ÎÖÁþÛîO½À…
ÀÙ¢lçåæ%,d‡Ö+@(á¹mwö:?t{fàœ<²ÝP½ÃîÖþß>ì2¨ö{°W<Zø@Q8c‘“Ï1xp_#ÌŸ¹‹]µs—‘RíôƒíÎqGÑŠáß—]l}ÔÝ@Ñëlm½9‚û†-°¬¦÷nàÎ>Ÿî—®øÎÑv /áí«ÎÎî›£"âáÌ B’Ð9	nÑ«7<|µó
¦Úz-Ç¦¼«ü“zGñ²Í:Ûowè:Ê<°È	ìŽF82ö}Ûâ·EðIƒ½R’ŠË¼Ñ31Øpä!²¿7E>8ÒÖ¾èÇ‚Ï(Åbœ¼Â•…%¾Y¨ð”Ò¥8D8@‘0ºdèK¸°þÏªŒ^ŠÎŽå˜ú£”3A1±å½‘hÓ:ÍÓæÏSád?PF/â‘³ö
›‰#ƒÙ@R/7È&ø€°éÎì-…Ÿ)z´¸}±¬kÅà%óœíÏk~×©C âp®cZþ²¼}Ve¹ãA’w}H¸´¯ëpyrZ<$²3ÊsÌs§â™å…ÜÒ†xFò)×0ÂÀ½s²¨›0Pñ‹ÅÓÀ:›Å!znM£üž„ÿ¯~YÕø—´n¬I£±U‡b´â«N2’¿Ž	Ü!;tqk¸bÓ{¬ƒDÅÙDä„Ùó{-¹÷"f@ò—X3ª†~Qb‰†çAIöÖÕßHý©™¦†Ê²˜EÔ$%¥ŽíºzÎpfj»ÒS¶(›
r}‡à¤þºÆ›³ÿ‡9¥ÉÐ§YÑƒšâDb o}/U‰´”µºUWßauºïa"Õé{ßó¼Çò^«ÛðŽ{Ó¼7îr<Õú ¸8o¨Ú£¸PJsO¿„Ÿù2|C«1%Ó‚£àô£U?Ý´^ÖlZÕ °û4oW£{A'é6Î’='W¥E}T‹kÈA´ÈöÜäÕbK?-±â´«¢äÀ'x)+xõ"Öq„Ez¸va°š¬«F¡?ÂÅkÙìGÖÍXêÊ9µÈ,,YdÇÈ‡H}w>N6ÛíËËËÖY2k¥ÙY[‡{´¿‡u0t“nÜÒ&XD„i'Ù¿ùéqªyv¾,M°j¾N0röæ2Ê‰«‡J”õÈ5¶44•Ó­„lÈ¥g\iS”Œ…a§T·‘‹º{±p¤¬~'ó~ã›XÂC.ÍL0í¼ìì¾9îîþäj2ÏéLå8Õô
ô¿èÅ÷Ë‡-;\ñ>[ÖA´<á<l˜ô®7À·Ù$EKÂswºþCw! |´,_MÐÜHîBe^!Ôë£5˜Þ‚úµz7ÓÙ/;ÇÞ©ÔÁãØ¶4SOŒé°’…ÖkŸwÿáÍŽ­~,Ï8Ð‚fdkP5˜ /NÓ57)K¦XSµ¤Y#¸×éF4ˆ½Ú¾‚ _ô‹²:Åt¡~„ƒŸ[#¯V@â
`]¬ŒW³n|SÖ+¬˜7?^ŸºqøegçYI–ÐðÑªÍåÆ—·á’K/)[PcòáH7·X	÷|¸rØÄ¾K­¿È\	‡.‡ –¥èÇŒäY¯+I¶ã²¿”×‰w”€Áä™"‹x%hÈæ<n;£¸Š¦b†”7sdpmÏâ{t©c.%¼ ŸîÖq+]ËæY÷0J(
Þ,©C7=LéXBSy“óDétr~Õ¾<¿j˜›£³É¨u>àt~÷ø3Hûí£ng{¯Û¾ÐkkkÏž<Qøï·ÏžÒ¿kü7ü<Ùxúì[µþxãÙú³'ß®ûD­­?†¿Sk_h=ÞÏY
,%O£…í Ùp¸à{ÞŒ2ÿþƒü<Po¶ñá·(8ÆÇž(‚!ÑVnuüv»	ßw“‹ÿóÿüD-åQN2…Ò—$T™×@ýŒ$Õ$J.bØOƒ„ô öˆßè;µÓ’Ï6B¾Ñ©¨QgdÆ`¢Zæø"p:dX×~Âíá$;ÛÞjH	Ë8ˆ	ƒÐ=
N<i×)ëWº^,À1)Ú¸cPôá#s5OO2Oæ´-÷»ñW‹iš¡xGÑÝú†?E×;åÐ¤¤P%ôj
¿Âìq[ƒÑƒ3Ë-½½†:êl5¨Ñ3,+CÕ‹:çÓÙphýmqbJz)eI§9› >ôH#Í#	5—ð›_gŒùèQ:À¢Zùù£G–†~Í;Æg3)D%N²b5Kúçl†ˆ±L‹¸×%H]`pCŸžÐ,—ž8~˜SC_</¥YP©…œ¿ÏÕëŠX„§ Cn^uZ¢ ë¼jè _Ÿ³KTbiÈ§²'³êíÞÿù¿ÿ_X®q;í¿g8
s£…ùä4ÂSclÊçFŸÆ úü	ÚU»7Í¢iÿœæwÌßKÝ×2h9À)=x 
Êt6)—Û ñèôR°ÉhƒÎuY2:…§‰à8‘¯ðX[Xƒ“#+¿e‘ÁŒ®½ÔÜõ	 ‹æáó‚…þ×ý.?H	~ÿÃmþï¶úþ=éòèÕž­­·ùIÑvy2Õ<6ÖÖ¿m®¯7×Ÿ¬?ÙÜøÃæÓ?(ôoâ+Âl˜¨èº*~ZµÖZ—ÂóFÛÙu 6) Ck9«lÌÄŽÃºÇXwuaç79?']^ÈÏÍó‹_à¿§ê»¸¶»Ý“—^÷û_ÔÂñôˆM}Øñþ–éússl¾{}°ç|þ>³oýùÍ¡|¼p¢%«hžWZèè‡ö¬VIî£Ô|Õ—w18yWßCï*~ËF+ÀÔÍù\mkJÓR{Èâˆè„ÙU¼h±J·`ªe?–	ÕûÆ‡ s›/—í%Õ'WØîEælduCôî­èoë­eSx
tTMA®ê),0ë/»ésx-ð3`h«>¡
@Ñ}Rv0 \ž§
9îÁØL£³‡T
T8_ˆ¤ãýÄ‘š:›#žŒ’Æ`Sù@Gxµé‹zmÙŒ÷rÉŒ§aÿýl’WÍÉ_-Ÿ4æI}ê±pR¢[ôÎfÅ´æË¥·¼Š:-Ù­0ûj¤kãÁ`á©/ûK@úît7=#>¹©ÚÓñ¤ÄãFé2É ð
gJˆžSºä.^)°úGŒôøwññ—~¶ _óôÑ#!L\ó^bFXšs€Í,lXF†ÞƒêÞs?R«ZãØTY?ÜTÇOhÝK‡$Ú!(¾ÁÖÆ*ºáJù¥–ª’&¢äl²Öé£Í‹xÁ+ÑË•Ær‘ÂHŒKh,<ì?4×6šëÏNÖ×6Ÿ>Ù\{z;yd½µÖZÓÉ½Ì~ùençmÌ.¤ãé\„£Y”/ìñ&×aQÖËtwØ¤J¹ÒæÂ‘\Vm~^a°xÍ!ÝŸÛ±{ðÃœ!ÖÛxMõíol-™¾MNÜ6`óÒÁæ-dY_ÃÆË}—öóØ„3§!ûKG°üÔ_5ñÈœŸ¡Ø^o¦Á7Á Ã£ƒí7[Çsá¯+öß`(ä[‹ŽR†jÇ—ë­Özëqkí&¿ÚûÑü>þSçm§°^8ÏÚ¿‚NØþuð~½õ‡ÖÚÉú³…#õ¶ŽvO^ýÇ~óæÓÐ…C
_Câ€«kõØ…Ý¶ÈÙnš1ÅœÃìPŒ·¹ã2¬‘qov»«{-»ŠU½ÊÔà/¿MÕýnpª;ÞŒ ,ÝïMnßKZ#@/,Ò ‹7éØ9O)K‘~kåy³ŽhÕÂù¤·þó6C´N¶»¯:ovOÜ‘
Ÿ.°û
yRF
äÑ©F›Ûôzøm¼’ú“èÚJÝOœOØ˜0¤Ûú%¹LA”·±Ö:ÿÇ¸Àû6ý‡ûžôAˆ£}9ÿ>ágé¼átô¯ £ø´À­lXpÄK±¿ŽñÐý›VdÿìiÜOZ(6ž þ!4ÝÒ³,Åp¿yŸ0¹âþçYo¯5¹š3l¨¼ÿC\ñå(?OóqKj×¾×6Ë'…o ¬‚òÐ/~¬okÅ°8l3‰O°–D?Xˆ‰Gép~é˜
SßøFötÇ)öõ3 ý4‹ÜAæIe[4^ªÂl¢ß±@´Š¤¬~×!H(Y-,õn£9Âîí<d/&öTáw@6yòæzøMÉEi
ƒÕ¢6·á¾³
ÑK¨­ó¨ÿÞ‚„b#q2×uŽøŸUmå£nv])¢VS¿<§´µ@)jÑb#”\®Û-ÝÖm¥T«ª|$H&êŸ§ªÖ=::8DftôtÐš*{ã þ;°Æƒoåž±s" ÿâG/j-ål¡½òQ)ül÷`«³KßœìwpšÖp>|èšïƒ»º˜ýš½óó'‚æ¤ø®§ãH_4óÝÂq¥ŒW½¥Ú½¦ÐLµ³<†sÂH•z1[?Žu2  w>&Rö3¶¤ïí åX¿”Úª¥eÁõQKý	ÛÊ¡p"š[ƒ›‘#ÂßO9Lí‘1¯
ašÃU¹ŠÏ½&²7`áM‘`XÓxÑ•¡Û¢¯Í®Îm/Ï*I6 TMÏÒè\_rK–ugÔyð _htLFëNÖ?§ùƒàå•±k<Ò.-4v¡7Ü¦¹c=×@Å–+1Œê,çGã¦RTl\®Ïo^Äòr{nªTè‡ØÅÂi7EÆUØÀp.gŽSÕ3Ö¶0 †íøÜ,©6‹Ã20x+›ñs¦
ˆ;î‘½Ãz…lÌkqB7×h>w¬v¶éoù&?c¢gqs×„ˆ‘êÎÓ¹§eãl5t¼å"AkhnC±¼K!àÃ‰Hò50â…}`°G½"æX|Ïl)öÂ%\VX:žV|¢!Táç“ÚŽ˜´`[ü 6Ë?êSñlhÉ·;¢A4.|Qh™ô"BÅÂ’}Ün¡0'ˆzêíØv¡Ix`ký5õýÌ­lÑ†Dí*ì\>-­T.“^š·½3•
M¿Aš“ŸG_àÝíÎ!}Ü—ÿÞëí*Sï+‹lØ	©?² ^¨'RV@UÊ N˜êê‰0gS6sôÂkÖA]6œ:î¬ÁLÞž°ÆPs€”V?ÿúñ&TJ™‹eQÐÿ ¥vS[:®´h¿bŒÈÕt8¾*ò/¬H,ÂXÂS‹à¬v­úŠK´‡ñ¸Ÿ=úÛó0® W–Î¾º¯°0â®é3ŽÍY´¿³.æð
L<<FðAGÅí<MÔêyÝV.àÆ&‹±wL«Ï©ýp -hsÀ$@¬„VioÅ±+O­eíÌÜêîPc?ËP¤¬ë–×):pÅ2?1SØvìT_È™—åUËÕl,G+
Kcéi ½$ASÓà–ÚÃŒÎsÖo‚iûLu^*+áH¯FÑJDrÅ:ê=sêî¿Uo53.êáùó0œ.ˆú¨fksV³»J¦§4½]#nS»Nä†ZéÒS³çü³èr«Üu…™
™pãÄæ©«|R<LÒÝ??gj×yŽEM´xÊCC*œÛDË,¯ä*š™õÆâE.\ŠnšœjI‚Ä*Oˆmx¦%WÞE–åË¤"¢S€þ®É3$w;õc–‰õ¤•"±È9V85â^1ô„ eaØ‹\}Ô²¤ÉÆ|Èz˜sõÁ—¥3KýÅ+c`§¹ûüZC0Æ[-·m>-õéI¦ê”(×•>Pî]@wgF\ïü];¶BÍìì„øX7¾Ú@Ga¼§ˆYtÆ¨àH_yË®WÈ‚¿ŠOÅ‰Àé„ƒÌ[®{JóÖK“j'3LŠøí ó¤ø…;©ß°zRlãO5ÿ§ú<h*¸K§Ò/EUíïN“
êVõÙ¥[áS•Jåxw{ç!?¢Íb¦M|qàîËs"7YžÛÜeAhP!‚pnpþàI§JG0“ß7	ëÖßf¸J>ëëÐa£õ˜—Pé"®Üw•×øÉ“BŸ?Á÷LTu•¡{^m7>¥Æ.G©ˆ)+¯lGñTÕþÿí}ëzÛ8’èù{ô}y®’'Kâ’{Ô;Ží¤=íØ^ËIú’^/ ¬X5"eÇ™ä<Ëþ8q~í¾Ø©@¼ÈòEVœnbvÓ2n…BP—œúÀ‚uew¥¸pÕQËuÅX˜z*ŸÒl¼ÞÜÝ/™ã+w»”ÌOŸc68þó)æ	éUU”akóª‚1ô"
$?<a(p"À/AV¦Ÿ1ÑÙÛù!s©Aû±[ÖhhÞ¡’ùTÖÝädÒçø~h¾®d¾ñÒcœ5>ZÜ8Prß®×2ZÞ¦JÂé;Í÷x”ð1úÖDyÔ3+uYAeƒr¹€õ`9|þÍxvabr½Ù·Sï¾±ÅPÌ' ú{»½ã,€½!®²Ê®‘}
Â<½ÆÊÇ›/ ÃwÛý—»{e<Ía<Uãš‘@Ÿü+æ3¾´²+>¹ðšÑGzY Š³YûGÇ…¶Yû™–èÕ—0~óF»– bêYWJïÔƒ;Ú9\Ô¯üMÜb x‘· hr×w0¾Še3ÇËŠoÐù•âEø¾Úd¢;î”Œ¤œƒ»úÂŽ‚>¿kÊö†«ã¦:ñ¶a¥[,r67 gy*0+-ÁÒ‡ßGá»¾ÇªäŽ]ì“Îa!%úMzæ$#¼¼ZÏà(žméæc`§åóNÁŠxÆ”`âë&ñ<ÉTÊÞò3+9êg…ß¨ÑKBôR’Á=ÁÑ6»t+ÄÑM?÷ÕBÝ ˆ‡'EVæŒÏ¨…—ØBrO&ý5¦ßg;Ž~Kñ{B!éÝõZWÚ$õû)ˆÅrÙvÙÑÆð]x¡PW?öV¥4.DÐÒk”\(™NÑÉqs
HìÛõ`r[Gô>š¿]´ˆ†B§O¯èôiúfGÃ ØÒÀln4˜nJñPÂIô¹)øÙœAð3KŸcÏef5â¼pxî&ç B<s!â·`BÆœŸˆî\
ú9±è-¸Í»$XýÆvÜïú¹âôM Uñ§Ð/gcæØ‹>Ãñ?
Íý÷¥|¹¾.‘.¼Ú‰4–þ$fþº·³ÿêø‡ïùðé·~½J”FÇ!ã#ÃI&E¦áFl wõDìÅ—Zaì4~…ÿÎ&n›
d
ï¿èEEƒ51"ãAt’ÆNàr‡›ñ"`ä¥ÄëhŠ‹¸þÿøÇ?2ƒmCš"µÓæRÐlz¢>»QìÓWKaþû¿ÁIüó‰½{‹Z¢¶6¥­">7“Ø;bý“1Êáã™Ô»
2?m
c¡/ÌÍ3âóé*&–±ù½×“¹';¡7¾@p°Ïß>Ç
Ï·Þí?§W»‚á¸ëT¶áÒ~•ÀÄŠÔ³=õtÆb¥Ä)}J*x’üŠ73wöÃŸü$Üš-¼‰ä^Úüø'~%A›BÃ5}HŽËÞÏp
²/eíN¯cq)N9*£+Z;}&cµÒW³aF6`NLÆé_DÖ
7ºÁ{çÔ;u¬ŸÌ!íU\Š	2.J<Íó*óÓœGŸk8z€$8ÅN‘œÞ_ÜfÜ|éž%hÛœi~6iQ7	)>çòM•“9:Maðé¯Û»GÊ÷ô?jL¯DÐé S¡`0ò) bk„°ØÉHÕàú%ª	b#o˜²v‹=-žaÏá®l¯6¥M¦„vH§‰×‘K¦ZP²@t&UH»aˆV\©“ž¡TcÏ™@høœx‚ (®¡-	1—þ—ùŽ£›%^1âR<Œ‹ôë+øïÌYÃgqŒò…Šåh÷Ýà„­¢ds@ÁŽ:kQFÎÙuÐÔ µÂÖ³Zí¹ôëN¬—Ï²S(€€œLáØŽEZ¬è3¬Îô„>iîê· Ò3:q±‹´¸Ò
1SyWxT:×šr3	8T]+ë -ñ¦17ká<N©³ ¯íö%I¨´ßälÕ}µqµÿYÖ5õÿchèÿGÕ­ÊÿÏ*R-p£1çø‚`J×ØsÏj×»„(OyõÆ¶§Ú¿T§!{ñ”:åÁÎY?âÜ¥Bw¾öJ|D÷?ŸñfxbßGö¿©ÉZÞÿ—ešÕþ_ER±³M´¶iWñÛº£)JÛl·Û†ÓV]Û%¦§¶]éß›­¢ý±<ÕÓÛj›tlËÔmHXOò¼N»£Ø2ñ\Ù³ÄÚ©­™­ù¾J(iCâ© å‘64}ÙÐô¶Û bíÔ.Íó‰!»–«z¦éµ;mM3lb´uY×\…˜¾ï¨VÛSÄ¶¹}±‰¬vWõMÙR5Å×ÌŽã9ÄƒÁ¸–ãË®¦´=CÇšåF:”išlØ¦Gdh³£¨Š#vlÕ0\¯m:¦ãÉY ¼.±e¾ãA)¿3F:Wµt_k+0á¶B ––o\´ŒóUÆ§x¾#{šk˜²îz†­¦á(šÑ†E3tØC´¢3<ÇRlËp]ÇÓ¿møºç86t¹mÚªªzª£Â*Š½Î[Üµ]EQT»àmCÑÌ¶mÉmâudÍét::Ñ½£:my‘=™£(ôÆh{nÇïXÄ€©ƒnÓRñ|W¶5Ý4#«Ü$ÎPUÓ°Û¾§ùjÛuŸÈz[³]µ-Ã™¦Ÿ½¶gaÖVÖ|×•}ÇU]OÓ5ƒ@7?uË´¹m[‘=ßµ´"(ÑøF[QÛƒ)6TS'À\ö†*Û¦¢ª¾m:ó:Äúb —nú°!½NG“}E7¦ +fÇè(²H[E°ý3\Ãè¸‘a0 ¶ï8®f›DsmUn;¦âZ†ïèêüÉ¹%î€Ý òøèÀ°ã=X"Í%ŽN<Ë²}ÛÍ¤êšçª°ÃJM a#[@6`fe(`µÛñdßPt×â`ÛªæÛn¾o‚é¦ÚVlô]Cµl€þÕe£my0qÿÏÊÍNÖîÔ4¶U—5U#Dƒ¹¾/ûmþêÈSµdfÜÎí±¬eixV³amu8N‰cwÚŽÓi›
,<Qa™[UŸ¸D¿NM†ZŠtJš‡£Q]ÙR`HmUq€Ô¶¥[vyrP¹¨™€†î@óÄÒìŽî*RYàÀkÛ!€:šìä'—šÔÊJŸ[Õ¦‹väÈÒ\@BXÇ‘-¨»Í×ÅQa¯(mËBK:å õä4¢>D0ÂÔ1`âÝiÃðLÅVÝ¶¦²éÂp=KµÍuU¥ªLI\_ôÄ=5:¶Ó†“Ví¸ŠnyŽnv,»Ý1”ŽbºŽ­9ŽêwdÏ-‡©öÿ9™ñbÊ —²ªº°$vÇQàÔ±á ~v 3Î…sýPé(vÇokß$ÓõLÍö:
ušcÛŽ¦Û®ç*œµsæUë³‹¼>*DößÇ»0ì®ð ¢=Ó]Éˆj˜ŠâÂiHL[AvÃR°ªÒgf%£á'¼#…Ú:º2°/†Bt[íØf[±à ‡“à Qª-»@|»¦š‡©RÎÂÖ:6ì6ƒ˜ŽŽdˆŒã¿ÔNiwdÛ÷Ú²%ßhøt^‰Ûöa¼–kÇ7àœj[:ÿí6ðŠjZºëjHœK+Z_x8êƒDD{¬Ñ ü–
ˆ‰ã—m¢iDm·UÃò`×êÀ‹ EVK6¯½ÐÒß<Ù\ó5ÏD^ÊjË[÷l8RÏ*äHñ
ÄÍ¬–ŸYÚOEÓ,ÛE: yºiÙ
- ü¥Id8hNíŽi•Âäd'ÿä²fû¦aQ= *ð©@<Oië~ÇÖÚ°MØåè¤¨¥³I×ÀÉ6N|Ýµ=S èÚ{ì¨&ìßŽé”o+Eî3…"|„
ü‘orÛtH‹L\¶kOB8À˜f +Š­_{è	¨év™ÒKFÜ—uµcµíŽ| 0?ê<bUJ§gªºãz°ËÇ&Ä—e×SÏ ÞøÙ7ÛÀ£Û2¥û(Cîíníì÷vjšCr<ÛÆÑùÀ€këwà %œžpˆ€üžâÄõR‡º
{8sƒÀáëÙÀÿµàøÂ©’Ž¥x¦
3×Œo­þ ‚û’òB÷ÝÊý†1ÿþåe*ÿ+º¬jxÿûÍø_’qßÃô—ÿËd e·±àþG×d×ä]ùÖ_·4­ºÿYEz|ME²Å÷§¥Äü&>Dï ø½Í‚hÑÇ©?K=þ õôÅvïÔéÙd€^¤Ãhj‡!‘ÔÎº,¢*½‚“*r¦³Á`]ê]£OdŠNákËì0ª‰6YÚ(ËÂ÷M†ïEÄGkz.=HøP@^“Ý‹ÿ-âãÇ»r¨½ã£òÚðq…£¸it‡Ñ”µ¦Ò†/4€0òø…vóp6Åxž¬,µ”âVÎ¢n"'€³=†)f3Flt‰ï¢©e¹Ñ1ÂÉ$¦jC`ßhø` …ÅµäŽõéÕá^CkÊYê"¾ÆXCâaè(‚`T½ˆENÆÁ<¤ÆPø…ZŒÍ	ÚÂÞÂ¥v°{·Ë¹ù¹¤ÇÄ1yQçžúÔOmHÉGd:‡ÌÊ-vêOÍü²ShÜ¡<E˜Æ´‘vÑÄ”0ý»tåêç©Î¸Ï"½ QpÉkìr9s±ÑdmÇoÞ1Âq³øœÏuÛó%	¡e?‡Â£áÎìÓsÜÛëo½é¼Þýe“E}ÌJÆÁø²VÁ™9¡‹NF¹ú6Ïí73Vë¿¼›A
³`á)ÀDÍ« 
J€eí190”µ`žrc¾>ç37L ez
]Ë¨³–ö¯hœ!X´³ rƒšÅ0¹#BaU³™ ÌN¢à#Z-øÛ¼h¬Kám¨xh1EujhÑ¢+YÑÑIÆV/×fÖW:¦DxE°"<äôÜœ‘Ê•`Ñsåc
x; 4‚kÛãËˆ†gwHÅ*K[B+´¹T*ú×Òþ}%ýÝ-åžî¥«ùEÑLþþ«XTúþk¨ÿ¿Š´´-úJ ód€‡Ìþg˜½äŽc?kTÁ”Z|
–yŽ>ËÅ:‡»Â	^$8“†\ìá8VµÌ{È‰£­r·"ð©’nÑ?zæö€Ýq¦V›7i·×å8²?²¹|»yÔ}‹ž§–8™LC:ì)Ýµ÷³¿½?ÙxÑ’~eî
cÖòËoÒZ\ÒõNºð5e›¾¤_ìn¶³ó
8]Ábš=âÙÔØãËuZ:ù¦r ‡n¾ su˜Zþ
eOJË
Fó¡%oZ2pÒ.çzdç?qß¼ œä]A-9Îð³šI6ÄÝýùÝrRÈXbë`ÿåu'„­Ä«ëY¶w’åM„‡/\[9”ìüD­ç àæï è€“2®¨=!ŸÐƒ`Íá3~³Ï•Îe²Q¹éçí7Un£2BþñòSwþlPçÉxm©tÐåÖŸkF&c™®Fm3¨AU2ÔdúK„›€¡ÆêO†yo¸Å+ø^¯yÁ˜Ô¸Ð¬ajwÍõ$q÷/)<±ÃÙ™Ôp¥¼¢¢¤~ßòÈyk<>Ðø®q.Õ7¤ƒëŸñlª‡­éåæîÞÎö“V+É{¹èûÕÎv«þD}‡6¥©ìKïŸJÿ&5†Ô¤.¶V—Þ?““épÉŸ?ÚÓ¬µœônÂ;ðòã¹_ìègŽÄ†÷ïRÃWÅnlno³N|ù"¢5fÐ8óO•u…×¿|…Â|ò¥äŽïMbOrÑà“Ô8¼üŽ{nånç³š´‰Ö/Óºâýõ`×¥ï`•R:ùk|1‘z§+˜£àB!gn)ÖjZô$.)Pðôë°PPñ’ByÂ%”?™[^(4º(’·´4õ¢D+Ôs;£.Bò](™™BHÌ… S,$`ûHø8Ù9ÍM—8¥™Oæ}öBè|b¶ÝhÄö¨½IÀ¿ “RSÑ|»Ñˆ¦@7G#ø	óámïKuwÜM}Õ¼¦–®Ó:ÿ;S lobøvbb/J¬¼zT¾Ù#´ñŒ,ÀøìDç
øzO,ƒAoÇ½cêqûêáÄ=Ö49—“Å€k9³ÆäÛ„}¢çV’É¬@ñKj=X±åXœ5jv×F!Æ„j>‡Î¹Á(˜víY$ºk{èkooóx§»%aa{$}¦\nR¨¼”“|OQ29“1Ž¦¬£hšd…,«¬?áˆÇ™}N-ŸÑŠzR‚ˆ!([X=göa6I3ó9‘$*¶Ì°†|õ&n1kõ´:¹Yuj—.Tœº •S(áÍ`¤†ìˆÓîZÆŠü+mYÚøììëv>BÎìéeÜ­âpU“<ùû–FuQ¾“Ë’æ?Ç“cå</÷Ÿï›­÷©Ãú<â|t×Î‡jÉµ†ëkì‚ûàåÝ™ßêÆXLåjÞËmcþ‡jz¢ÿa¨ÿahº\Ýÿ®"U÷¿e: ‚ÁÃ7x,:I¨nƒ£Àƒ¾þ6¯ƒ¯u½ø5®Ï$é1sÙëGýl,qðw“2°gXKp‘E‚–Æù”ÑÿÔ2ëþÎ˜Eöÿšn¦ú¿:Úÿª–Yé®$=¦ä^nƒçƒ²‘u©Šg$æ«,ŸWAG&˜§¥y½$Sg™›ô®%Î4Xæ‘p=27ÅT°A2(½.ìâ?Û½ÄsÍÍwì×žå‡›Ê+—ÛÆ"þ_øYGýÝ”+ûÿ•¤Jÿ[àýóæÅ“÷Ÿ£^ÎªWàÿ~£Îþî˜òûåŸ¿õ„á³ï»kÚÿª¥k¦f¢ýŸ)k•ýß*Rj|mÜ|ý5Y•«õ_EÊyé¹—6n±þ–fVë¿Š”õŠs?mÜbý«¢ÿ+I7F÷ÐÆÍ×_W«ó5iŽª¥¶±àþG‘+·þ†ŽþªûŸûO³Fº(-Åžè“P´cOò“È	C_ú6þC˜©+ýö×þw3Í¬ùCõ&dªÕ.U­(Î<Æ†¶Sû,¬Õ7è>Á7žÐPWMfŠèÇ<ƒ¾Å6PŽ*qŸ÷4µ²eñlêa=±ifýõ&ëRWª×“ÞKR<²:êùáMV],%IÍ²ð…ŒBB0½Û££ƒ#|©M¬iŸJkÂd±ùŠíxbölR%·¼zu2;©’uá„ÁlÊâ~‰“^[X¹Òù£¥rŸ}Ëmãºç¿®Š¥ÈHÿUµâÿW’
>Áî¡ë¯¿.Ãÿ(ÿ§WþŸV’®çiónm,àÿ€çÓâõGou’¬ÊªVùÿ_Izüo”@®íÑò.ÝÝæ5ðÑ-ž—ÜçÌƒ`éNxt·GÁGW¾
>šÿ,ø¨ø.ø(ÿ0È¢¯KŸfg™BF#2–<9)s|z”%dpnø¬÷hÞ»Þ’×C|Ù{´¬§½¥ö‘ãâFŽPsn%‹§ÞpÊ¬ägs¼	×ãf¹ùfÒð-ÇÀä	4a,g1Ë|=mÔã*¥6i£TÕ-©P”‹âÜ´\lg•-‡¹¬BÐ[
r³e²±bã2˜›+—‰{›”cö‹IÉíÝ£×›ûùVYnZ
¬íB)–û…._Öª÷þ#$(¿Ba£áAá?ã9Ä@Võyê„õ¸8:‰EÙbÒÞå¿fÌaêâ:Ä%s¦o_âü‘gO©9›p1?>ÐYŽ?R‹»­`<¦z^b)6Çq9$08yÉ„¥ <ÔBØG°ãy^‘µGF~o8o‹L#¼n@dæ…˜	ÔñlŒºÎÏ±úÿÎ4Á(œ_j4&Óàl"dNƒ	6GBœÃx[.å±ùÑjdñk»E¿Cø?KÓÿŸªf˜ÈÿYVeÿ±’T±|–oò?d®ï—Yh“èÓhèbÄCè6ZcL%ÿxC2—ñÛ¶Cio{÷%ðNSªæžHäq.²Ü+¼ô(¯fÏ|X¾™OÆMéÂÿ{öÔ—Níñ˜‚£MØ3 ~fgh¶ ‚ùË!•.ÈÔHP¤âJïÐÇ%¸vžx›LpÌyAB÷6­3~PÚ`%‚ä!Ç\<ÁÆLx\†ù`âà†„®¡}5ÀI¨Q[à|9žPˆG„ÝvCóÓ2Œ Êê@'f€6 ycwì‘ÆŒ>È ;:§Æ^€ãÐç°PÇS‚q¥sµ–6ÍÞxCrÇÝx–×á÷îæíý3¥ÍGµÀù üÓÖhå ‰¦ƒC÷‚qîÛ¤,3
&¹/l¸þ€ò„oÜÀ}ž+Lö˜ûv´Gq[3ÜþÕëý°i(ê—ãÃ·éÏ†žûæŸoB«úÇÊðÍáè]çâ•÷óÁ@iON['§ç¿¼\z›?ýp°s²ûöôhÏþÑÎ¹ýv$O·^}útñcëp86tómo<yõ¢õËŽMfÃ½·jîxC@Å0óLìö’P«ïFnfi±	ç!bmùÛ	¹>@
‚,8â-Äå¬1
‚ÓèdÌ'ø{mHœðipø‰d¿†çd¼Oá¢[µIòZÎ"Ž½ÌžºÝÓ>Ç~V}a­qôi6 å_À!åžDÃÌq&á‚7Ø‚/ŸDÌâúFiÄ?}Øm)¯^O^ÿåÇw?ý@.f?~$ÎÀúûÏ?ÿ}²~[.ýí“ã³ÝF?½ûûæÛÿ‡þòweL;{í‹W‡§­£ËÎ‹ýÖ/“ÍÖëVïóìŸG?î·ÿ©ÉŒFÌR4³^I%²åælð…´A  o2 ótEÊÀK4l`/ËK°Um 3æ]Yàb
{¢¼:Ú"0Fæpëê2S‚ÌË<@—èx¦a»£9]Áí>jððÒåeÐ-u#¼»s>Ñ^àåÅ>œ}$ýËùßçO~½b¾ço0-ƒ+
0¾µ¼Àòˆ—s'*vßƒ³Mæ€H3‹X^ŠÝmÐU³çu†—	OfÆb/-T~@±pé$–gvþ4KPý6$ï[¼=ùöÓ5ØÝ©÷?†b&öŠ¬Ò÷?Ýªü?¯$UïbŸ³—A¥;áë\©òu®‚°ê¾ÿÁ¡ò)â¯ü(vqÊøÜ7g‚<}³xój:{	gÁ†xCyp?0"È8¾&²g~òÄX€D=L¦-½ø”«@Ï:›áaÈ.}27TÕÐúˆ"{¿¸“Ý!EIº`a0ŽYrpF!¿1L‰žÓ)9¤¡¸S2ÄÀ*áQ¡û›¾JÖ„§4¶½õkJï†T~bØrâ:Þ†å P8AñŽ‰1*iª!Œ©à×tŒÑoÛV‹Ö¥Ý¦ePAÅÓ1fs>ñù<Þ=Íå®Hì%õ¼Ù­·‚IÄCÅÔEð]¯[Ïù|yÁ›¹b¼¢6Õ¦Òüë
/ƒxåáyåßØ£[©Gé¼£ä9 J»—‚ÉéS·™B?ãÇÆrßÔ%×t~‰.9ÉãaW‡”ýÐU´v'W¶×Ûë*¦fæ²v»í-Í¹ÙÀ¿ãî‰¹Ù­»„|JñÞö^¿Û<ÚÉ/[øF´i§8Ñ*Ôêcl¨ÿý¥…ñhJÊ½|ý.SÌ?»()uüv;S*:÷Zñ°×!»)©K °÷èn¹«Æ¤,
–â¢3Ïd/Â]þÀž(Bo¾L_=–¯’Š?îüÜ;>8Ú¹!Ê}8 ‹~æChN„Þïïnýˆû [¥ÃE¨uø'ÓA¥ãó{÷ÉÓäA^p%)}þLµžÄZÏðì}L`Ù¥K•+”z&We¹j6Wc¹Z]”ó`gÜ§+Ñì!¥k¿Cä?ÝHå?øG§ïÿf¥ÿ¹’TÉbŸ³òßœð•¸TæÿÏÿc¯0›³~ŸL‘[eÁvä–<æÿ˜‰ˆ7}ÃR½ÞÌÈ&^”¾òS_3å³†÷¥ÅæfÔ²ÆMeB)q ÿ#È°¸Aˆ‚B±Úü°åP×…|tP·ÉE—•0‹B*à¦ZTO—Od„ÕéÔq9 ’DoÙÇ¯¤!‹I™=¨€ÂkHðõEÇ:CÇîb9OJc’2î	Cßì¾šñ®Î ‰ñxËaq½Ý{ï¢º›èí&À~ª»KTÉñ![*ÎMË¥«-–Ks™ú.+»éyœf>{ôU¤Nµ{çº=m¡’,{Z¤f;)Q±ýÜÕzîKUz¹R+vç º27ñÙùÈ"XæAÑJ~ýæ•€ï8Ì‚²î9™:pLÆ&‘¥c82\¬a_ñßéÓÔ5ùÿ;i /àÿUE7Rþß@þ_QÍÊþ%©âÿÅ>_ƒÿèêÀì’v¸Š2þyU`éTdóo¬<G,ªTƒ¿vœ+:Å*¬tº¼!1¶dÉÇÝÃ:ðª”IÅó_ë³M×G=­>7ºÓàBûo]NÏõ?E©îÿV’ªó_ìsþü/ß	ûø. Ñiëµ4²=®’>¹a3åÇ?‡GÕdeXáÊøcð±*dîø>ƒŽ}¢“Œ™hJ›c8|Fx3Ð—!4qç'WÈ¤Sq$Quw—>V÷q÷{wÀ·6Í>\qws×½ÛZl–ÎÊõ`ß_ÙãE÷?H8^˜B„IIæ„„E D²‘Á»£™G^L¡KôŽ&îyz‰CUØw·©¶?µŒHÓ‡~|YTvÇÕCÊrÇ!>æoè®¨Àÿ©JŸ‡~Â ´a¤Ü³þ¯f¥ößŠ¥Êøþ«Uöß«Iÿ·¼Cæ6Üß-˜¿¥v8Ãú)j_½Û·=îµIgé!|ÿ$Û—«í/Ec.ÒÁäØ½›sRó©¥®ŒVúqJØEPš8pfÁN•€Y¤ƒŒ#ó.±ñå±G×æŽxŒŠ1ªfâcÝ¢ûÜù(ƒ%†BŸÃtÜ”ç¸æsà5^…"Š”gJhn¦ŒZZFM{tÅ£âµßÅ‚G;‡EX˜›»úåñZLW—JÏÜÌ¢!ë˜úÁÁUdÓåOƒ3ö[­/zŠá	Í¼¯±w¹óË€ñ7¹8O˜°¸ø6HaÃ1G)ÖV'ó!W‘»ô<úÔ¸? 7À¬ÕŸ0]Ïzì$èªç½Z&êwúÌWtÇS»ÉÄ°xòRã$žhh’‹6^Òáe÷xåQ®‹üŸšçÿÔ•òŠÆø?½âÿV‘*þw¸âÿ*þ6^ñÿ÷Àù?Uàÿ”eòÊ-ø?õ÷Èÿ)XþoÎûï]Àð”_ÊÄQ1 PÅÿ­"Ö_ÑJYíBÀ"ÿ²‘êÿáÜÁúkzÅÿ¯$Uü?ïp–ÿŸ¿	>ÿ{G+°þÔYºn;+ÄxÎºrÛ<òmÈ	ßBèçJ–xp²„VZFûÈ¤¸`Y9B¤ˆŽkõñË¼X*P²òƒ’ãœ™5‡(ÌT/±ãPJøfzéÂûÇA«¥ Õ+A«% …Á
=Æ…B‡ñîlJ„Ý£”ÕQ¯®£–‹>¥rD"]!HÜ@Œ¸…L©=$™R«dÊoX¦¬Ò·“®ÿá~ß,ÙHã©õÿ ›•ü¿’Té‹}^âÛRþÎF›¦NÈoèÒaNTŒÛ:t(ƒW uw¥Þ
€JÝ9Täwèc¥AžÓ ƒPI¶àxŒ…“þ*åõú‡›½Þ»ƒ£í/q0éG5ÖP“ ~¿8Á¶Ù#ßI^Àò0…Ý'OÏ”¨°Ùw×™ô
JÏ•ê›_ìÆ'¹Ñ©C¦Œ<©q!)2üqB`ÝcIy–Ã¾þ
=}‚|2 R[úóŸa]ÂºÔíJÏ`¿=Ïfð|4YÒo™á%»ÉÂlh@€LJ¯é¾ÆPã.ºâžm©û½ð²U §i†Ù¾¶Ç`cÀí"üuØEqÈ°áx [LhË²ß^0æ0ÀwÜ/uþ: î¥7cºÍ{œuÓ”JÀ‡t‹à0OÛ1¶H…Øú÷|¡a#ÁÈ7½£/Òœj›YèX-¬/wZÒ•dÎï’jV°ˆòHÀ¨+ü´)Ÿ³càöþ>}w'÷`ZƒNKÒW°Fß”Ç›‡ëÍfùîj–ìÍÖ£xÎñÝr—6•Ûš[¦ÊŠÿw™Šú¿Z^ÿ÷.Oÿ4ÝHÿ—Å¯ôW”ª÷ÞáJÿ÷!½ëWú¿Õ›ýêÍ¾z«­Þj„þ/¿™bž5'—Ëà1ñºa&üŸ©É’¬Xš¬Uüß*Ò²ÎÍ<Ë·;ö‰¼w#¼üaÑ=<zÁÌCø5¹½<³Ç1èBï5`üj<«©¨MYÏ1xs¸»(à•hg¥íàÌ~#ÝƒÖÔ¬1“)‘{„:«¹¾ó8ðOÍ£sÞ§,M]¨Õäe›=]Û>x½¹»O#­­KuJJû¬^ýY`‚6WÀó
´f²ÒbÕÂÖŸÂºô'IèÅ³=út 1Äá8zš‡Ê/ØáDC –,+õgqå0Åõ¯ªÜëí	õÕ´>½7œô®+^–vèÖ“Žc¤¯¸n=û üQm2Å­1d§[—sQ¿þ)üm-7ßåŠÆÓ\(Žg—í‡É¦ÅÓÙÍ—Æ+IV#_šOgZáM:?¥àqþÒÒÉSÖœÒ8cPP•“ƒw{½˜°JXÎS6Þ½€s:ÉTó°žyOc)^§tNXµt>®ª…˜""df^®ªˆ3µ/l®t~ÕJg­[˜§%qU_û´^~*ÚÿÌ¿ú¸m7±ÿQ4…ÙÿTþ?W’ªû?ÞáßÏý_eÿó@¸Êê.ñ¡Þ%þ¾}	ÜÊþG}àö?±›Êþç~ì*ŸÕò¢óàk3«UZz*ÊrŸÑv‘¾ßø¯–‘ÆP@Äø¯Zuÿ¿’TÉ¼ÃYùoÎ&ø„¿!ÆV°GˆqhÎaNÄý†”A*!ïJ!oZ	y@!¯dÁåŸ&%Ÿq†žÏô’¸“¤CLd½Œ&tFÜKÕ o$ðñ~¦"_yê‚òrßÁ/]§›ˆ~W×Êb¨ŠËÿ/ÆóùÊ qæÃ[Ê} #8pcR²hy‰-/²¥Óñ0¤¶¹ƒ™ÛïoNt»–ý?ZEÜÇ\ÈÿËBüWU¡ü¿Uñÿ+I•Éÿ"“Dþ‡lôÏ¬ãÀ0ôú£á5µþAÆ3œGÌV0”O¬ŸrfEEwÐ€ŒdŒ1å2MÁß,N«4<ã=î`ì6}ŠšEó|!0¬hÖïQCÛ¡Ö˜ð7³â—˜ñÏCL¾‘™d\¼?,T¤©ÄÜwS{M¦¶6ºþêÇlã'´ŸžÆÙŒÇ5\qfÌOæ6D$!="Xk Îè‰‹ÓpÈ‰}>¦¶ë’ITy0¸C—<à†´¹½-Á,ÓÃs^Â¨93™`sb DÜ…â;«„ÊÔ#G‚ã€þ½™MaÆt¯xdDÐ+  =úÕ€ï>y]:›ºYp³¿ $pO"@5˜¨±´¹µ·ÂŽ³q¥¥¾tS.uØˆèˆŠ€š€èÑ45`¥¼™&¨ŽÜ'ñÝ`»ÃúS8l$âºïëJSm¶u¹©(ša˜M¥©7Û²ñ¾þë?åÖ éw’í“YßÆrTÿŠž€GÉÄãÔãÔñIã­H¬—ïëß!£\<
ïQøHß½1ôm\aë´`óÇÀÖá7 ·½âo¶™È³ú2ñ'EìL…?_’™_
%ÐcÐ°Ì-òÿ¥áÝï$,ôÿ¥«)ÿoaüEµÌŠÿ_Eªøÿ\Èç9Èÿ%€8pò5$ó¡òÈ^ôÿ‡Ì÷Ïeû¯Íõß†é¯xþÕóü¯íáHú!¹¼»ê#ÌgÉ•«˜,ÚY4è+hc¸ö/OY›ã	ÃfäÖèRÒw¸ÍÈ3‹¤·d
…¶ÙÀmÝ¤Í›!
öe Ÿx)Ù¼K7hl8>·GC¯aó^C»—ãÈþXÞNfÌÛÌ‹”¸ú:¤½`Ç†¬k™vysÛ’ƒâq(u±“”¤Ûh—€7Ð_ëÜ›‰‡ÜAZââˆ{w
¦¹Ž%ù™¾¥¹¬{GZÒ»Wñ÷¤ƒÈ¸&@§¶gmm„âíÑF£ÿ§çâx’âl+lØ£É‰½¡¯gg€3î†¶×T×‹ßxô>™‘üÜ±#aq@ÆL€ˆ¯ƒq«‘üú”.Í!BÛ#&x\µ@	4ŠL8={d<ˆN/Ð•Þû¤ò{ém\¢´~‚†3ÑÎC(Ê] ¥@b4¼b9#õ>‰{Rï‡Í†’é$ìßÓ`5<¾6ä°ì³˜Ø7³q´¡ñ{ÖW	ÅC±ìì¡tX²aY–	üâ•m’“!ß¨Ã1`Lç†™«“k¹1%ÿœÁy²Õl
ÇE:3¬K7ßGóQ*á„©[#Ô1­ïVu+Œºdaë&8‘Ï÷!žÔÀsäé;ÍÇºY?´»coø‰|„IèÚðè°G>rv©Ñ e†%8T˜Ž¿²c
Ê7¢Ë	Ù€À‚G—ó¾z‡È5ÍûÎ8ZáŒM
`6;&†n’ÉjÐý9ÌïÙ ÷`ð†´ýÁÂ ã9ÉŽŽ$Q:<îµß }Ý:ŒgþÔ|ÑÄÛ ÿù¿ñmÐá;a5ÆåB•|Jï€ŸJ¡^‹š,/­÷?ªeÅþßæÿK15E­îV‘*ÏørpþªwîÅ;SÊHmÌ+5ŠÐèu'ÕÌ_ÛpZ•bç;Hèû‚3†“ùÃ}?`Î‚‘n†-öBÐ„ß7©%d4¼¡=a4tï å¦UE×´î¿˜;æ™„Þ¤WGoiŽL.»€…<ãYªù('ättIžC¼©Né_m»ûd/êòëÚ—ÚmçÉç”#ÆM‡»ýº·sä¤q»
(`aÔ øíÆSH}I7½³°‰4Ì%W‚i;Æ-Ïi'ìÌ@úívëqÅ"° @éÿÜó‰gÌ‚ó_±59ÿMË‚óß°£:ÿW‘–F-9Í¬¸€Š¸áü?p.`ïàU–qNúŽížÎ&”4gòÉGÄçb>S&.ä“ñùò¾ˆš5—åS ç·Ûÿsé?.ÿ’hÌBú/ë©ü§ ÿ?€Šþ¯"Uò_Eù+Ê_ÞÁß7ågIÔÿ\6ëOÓú¯É*õÿj*Šfê&Þÿé–\ùÿZIúÖ¨ö·D··`G}éeE§ï•N/»Ê’üÙh$1’/>5œÎÆø<k.q Ð°,)é9ü›é‘€öŠôÐ@Eá 
O¤F$½|³·'5ÎùÿLm@…¦{"}OƒŽ±ïê÷VjKÏÂÄÇî”¾[Ú«›Ÿtväuu][××uózó´»¿u´ózgÿxóëLãV2EªJ§èùÜ‰áœ
NÌ¢™øÚ§R•V•Rþƒù]ŒBîù?dŽÚ—ÒÆ"þÏLä]7Mýÿ+Võþ»’toòÿ €}Ež¬ÁøÈ©€öW2”ëY^R²#)ÇNüË¦l5¥<Ï¨4å<Óøfü“(Ù÷^sOÝ¨ÌÂ$Æ€ÃKèÇ™b8Å F†Á¼‚YLÓ1psüŸ-Å´!íŽÍõ$Þëd6œjZ!¶*×­—žÒž>kJ›ÞØƒTj]Là(`±³P¼
u›ïKêFFÍÚãLijGFþe±š72ßÃ™Hî¤¸ìRkN[£¡ÓâÃäÿmåà¾W(|V³¤ÒåÉaYnªBZGïÛ §¢ë·âñê‹šé½‹D¨Ò™=žÙ£+‡´ÒbÐÁäæƒ’• €+QèÆ¬ýŠôã·Ú6aˆu18 £#»œñ¬½³ÇQØ“è"˜ž6™MemÓÈ4Ÿ)Õ~å$û·Úñå„tÃ!RCU]´•­½ÂK½ƒj°!“ß-<l×v>—â_ñ[‹¢Ø;âì¡?ôµÆ
“’²ÈÒ"âˆÅ‡g$˜E=âv5Y®A3cÏžz³h2‹º€p°qƒq@÷ã¯;Ói0Í„1sò)â½¸ìžÍFÑêäÆSó»ˆ*åÿØeß\½«Ó!-òÿ¢ZFÊÿéÈÿ™–QÙ®$Uï?Â=b÷è¥"Þ!rÛþÄØ³<¯GÙ8ú…ûé]J@µÂ4";p³ir1ñcÉÇ&^°óôr·fÔJlÉ—’	#ê‘	Î†Ÿnë£‘A{ÛèBºfÀV]JÔ&08#ih*¼lBýÿ¨	s7d‚² ÐÂ“`6ò¤q;-	ê/ÚÓK¨­…0›¨©†v¾:ÄÆ¯‹ÛÊpàÚ
O$2hÂ,KMt)ÛŸLÄÁ&kóø„d‘1)GŸ>ÿKÿ }nG´A¡e4Žað°K‘=¨_·½½þÖ›ÞñÁëÝ_6wöA*`¥ƒ0Š0BŠ™9¡Ž6·övè¥Y,w°H`Ør°Ÿ©8²oÅg©5“å–=™p@“ßÂ	²L
Æ}%@¡C	°íÍãÍ0”ÊH8:@g{=¹i\Ï¾‡	´Ä#í£ÐµÄ•éÜþÅie®3ù€·~|s[€ÊoŒÃdÅU¡.F3¸`v[gCÏ‘{JDÐ/_¿‹Áß
4emÞß7ßnŠÍÀû È,ÀŽ¥Eã7át)ÑœlŠš¨ç„’¬ymÆ×ºÔ®µv#z¼u<äíøaq=°PŠ`i; 4‚JM/ À™áPb„ãÊÒ–€ãáµTJú×Òþ}uM}÷”åÿ9nNÃÉÛXÀÿËŠÆøÕÒ5S3©þ¯Yñÿ+I¿îì¿ÚÝßù­vDÂ	œ„½V¿eŽ“ºJSfÿ«ýújgçhwë·ZogëÍÑîñÏý7‡@«wzý·»›ý×?3bØ{sˆþ6º¾=Zšþ`•î/•ÉÿKýiZ°ÿ-CIâ?è–)Óý¯ËÕþ_Eªäÿ¬üÿEÿ­Œö'¥ÓÀ¹qÓí¾ˆÁj9ÇCYˆÊ5o¶“{á°ôið_¡F—øTãÑúbK(n³H:~»M1ŒÏÿ@÷Ë¼ÁG¦»ò¶ (&½M–ífcíQ¯=l2ßnußÚ£Ybg¹zËaOé®½ŸýíýÉÆû‹–ôk.rÄoÒZ\ÒõNºð5•›¾¤_ìnÎK;s¶žpx”S„ìÏÞ;ØÚÜûr–†N¾©È¡›/zŒgr”Pö¤´¬P`4š¦%'ír®GvþS‹ú˜ŒÀáßc!0©à!;–5“l:‰»ûó»å¤±ÄÖÁþËëN[‰W×²pY°½{”,or{ð…_„­J‰ v~¢Þæ `‹ `lQÉ•L¥pB>MpÓ}Ãgg&ž*Ëd£n"å½ÙÖ¼r£2JþñòSwþlP
Êxm©„Ç·Ç¼EJÑm÷„Þ&Å—:5Ìâ…^:ý½ÝÞñ—š$yAÝ4`õ'Ãn½)	;”_%põ3~;ødX¯yÁ˜ÔX%Üõk®—ÃvþZRè$.$lçôëˆ~­‹T .|mBŠ%°_™R¸…Š¥ 7S
wT±äB©¤Øð¤lP¹^Gs%ûD(í^]šmÂ´<’Ì”ÑI?ÛÎÜiÏ–Í¦.!AÉ¬&Ýµ‰hÄød@ƒà„å²«Ò>Þ‹Åßàª+žÑ$Î‚©ÚÛ2´·gwKÁn³GÒgz&'…šÝ5üàIÍç°MÜ`L»ö,
’å`œäû”EÓ$+dYeÐÂ/tâÉsèL„Þcàé’2)¶$„#™˜ÈÜgu|¬fÈW#w2V'7«Nð­[¨>%“›¢¤¤PÂ›Á`vôMàcçÃ »v>Ì ŒÈv’©‚?g†³)fùèÌiwíŒ*5ð\8tÍH],%ŽyT¡\ N!&.47@!ÌPê$TìI8;ûºA'W³³3{zwËaŸ
a¾ÊÜxá4Ä^”ÅÜIƒê0ÜeátžÄXÒš\xŸ¯}ŒÄÁdü¿^5œµå©p|³WÑ¹ûŸ©² œrîÛXtÿ¹…û_E¯îV‘†côV›¸kÞÍ½`2|àjÈöLÝ‹?|íÞWé®©\ÿ‹
FK»^°ÿU!þ/~¢þ¿¦Uû%©ºÿÍë¥¸ÿ-^³îW·Á×Eê6xé·Á×º]ü·g’ôXŠ¸~x½ -qðw“é±gX‹ýÉlÈUÈîUÇ¼pþƒØ½ì3fÿ¯é©ÿÃÐ¨ÿK©ÎÿU¤Ç”ä³#…ž%xF(™ƒ€ž“˜¯²ü½íÍC	£ cž–æõ’LeRg‰I¦Á2… ÉÉ'sC0£Ž·Q‹J¯K»øÏvogGŠíán¾k¿ö,?ÜTØÿÍþöÎËÍ7{Çý•ñÿº‘Úÿõÿ´ Úÿ«Hÿ/ðÿ9Ü üÿrvý y)áiòGåáŒùïÃNó¾RáüOÃ.ÍÈ‚ó_³ÒøŸÀ
àý¿ejZuþ¯"Uþ?ØÑ_@û+ÿ;¸ ¹…º 	²ŽLò@Ä¼¶
ÇÉÌ–¸úXOàÑ§ÛÚý;ý([ëûõûQŽ]µ{pýq–îàýãZÐoé d.ìŠß¼qË|€ˆ×9÷ãýC`n»‡;ûÛ½~bÙ­Ó†­Þ©ÒY§¯˜j«žõ’½%ïŠ™g†‡¬è?gCè–èdn`’¯rr¨í]«Ò”0œ«/Ï¹Èó."ø¤¦àdØG¾¼‰Ká1Ýÿ(VÞþÏRäÊÿûJÒcéÉ®·!=Yýaé›»Jº¿Êì‡å^	=Ùy‹ @Ø*dG± ~`E2ì£X$þÀŠeXÊ8 ²à-áÍ)ƒ7–€D—™‹ÿ<÷ø0óuû6ü‚ðîÖ<X$ÏíÂEÄôuø#˜jž»!%™5!Ä7àât`c™/pl1ˆî¸KOäp½¶%Øçbõ\Kîh+G qiùpöÏ…Ì>ßò×&~UªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©JUªÒ7–þ?ñ|º À 