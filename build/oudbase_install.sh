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
VERSION="v1.2.2"
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
# - EOF Script ----------------------------------------------------------
__TARFILE_FOLLOWS__
‹ Õ½ÄZ ì½ÙzÛH–0X·ƒ§ˆ¢•eÑÍE’·*9íjZ¢ÓªÒÖ’lwþé,5D‚Ò$ÀHÉ*[ýÍÅ¼ÄÜÍ72ò?Éœ-6 $%YÎÊê6»:-‚XNœ8û9q'íß}åÏÊÊÊÓÇýû„ÿ]Y{ÄÿÊG­>\{ütþ÷ä©ZY…?ÿN=þÚÃÏ4Ÿ„L%O£¹í Ù`0çwY‡ù÷ŸäsûŸNûÇ°¼É4oåg_aŒùû¿öäñÊ#ÚÿG«>zúöÿÑÃµ'¿S+_a.¥Ïÿðý¿÷û6¢ÀI˜Ÿ÷Tóî>ÐÛQŸ‡ý8Wêå4“(ÏÕftÓñ(J&êêp:§ÙD-¿Ü<¬Ã;‡ateQœO²0Ï#µö§†úãêã5õÃ0œLN²ééiC^Ä“¿GÙ0Lúw>éÝpµø³®¼“?v¦“³4“'Ñ LÔ^t–cµœFy]åô¬•Ò³ Z½towûñ¤úmøq3œØq×VVÿØZyØZý#ürÇyœ&ôÍqšÓ<â¶/aëÔa/‹Ç5IÕiÿœE*N`âI/R<æ*‹&ÓDõÒ~„ëL'Q®Ç;:ƒ]Ê¹økÆÉðRMó¨¯i¦¢ä<ÎÒ„¶@–N'êèíf††ŸhŠØ4;;›LÆùz»}
-§'¸ö6Ã#GJ˜†ÃoÇ½(ÑKøa»ù°µò/w·™ÐÓNÚqÔÇàkE
f@`h*X2ìÆ%-ˆ~¦§´ÚQš!øàÏQ8Á–ð¿ÞY˜œFùN°©6€ø¤£øï<Ìm{Š>Ò	Ú{³y|°·wt¼¹û|é“óm½Yl™œâyj¥ÙiíŠï&}•¾puµ	¨<NÔÛp8ò[.$xÛ=8ÜÚÛ}^;_m­µÖjÁæ^g¿»»ù¼vtð¦[S‹>÷ QÃ“aÄ;Ãáx€ž_îvŸ×^u¶oÒÑy”ÀA”€3s¸q°µt¼ÛÙé>_ZF<N€V¨¥•zp´³¼¹uÐÝ8Ú;øñy­=kôðÕÖ6»ôÉkpÕö_o--Õ‚Ã£ÎÁÑñëng³{ð¼FßH„°³°KKŸœÑ¯ÔòÛ(#$^ú$P»ª3"/=¨;­íÎææA÷ðð9œ¸M³Ž]«wtöž¯¯÷`g€4‰µí~tÞN¦Ã¡úü9ê¥j	Ûàhu†Èki¸ÈóeÏ]½š&=Ä½Ûâwuws óQoòð4Z®«OEŠ»çãaxÉîpd´AUByz´™îä§ª¶µûjO­ó "BüÔ<;ÏT3VßãÁßÚüÙÝè¾PÍMõ=ð÷þæ.üýÿ½„à"Íú¯à„¼P?W¢Tó¬ê`ÐàÀ^G /‡/3Þ>¯z»âPÍx=«z½wõ>…Î¢ñ0îÅšÑ³lûÑØzŽØº®zÉóÍ8‹zÄvÂV“Íè®r/á‰Ë#¢73Þ.í
~à‰Ú]õÞvzJ$l¶z{ï$$WÜ.¨Ÿàáê•jžNÔŠúù2ü$ÐËÜFaÒIúÿ6¦Fí–>­]ÑÏÑ˜¯nW ŠÕï¯(z>ˆƒ«àN¹_å‰Úa¤bR6‰G$½ŒÆ_ãt´—ëÁ'ZßÖîþ ˆŸV¿[pU…|ô‘6ü)`³K8É©:‰àŸ>Ã´$@M]] QÝ !ÈÁ*T	H@Î	±>7p<³5ø¢j@‚¶vºÇ€?;û@·û +ªÚ¿|÷có»Qó»þñw¯×¿ÛYÿî°VöÌyõà`ö«É‚—‰ÁÛ·wï¯5âÎ«µšÛàÿî5hU|ôKQö,æ×ˆç!æ^ÕÔs%²Añè¦Z†˜×–Æ@ž‡ŒÚÌ	Ð OM}ž€èØshÞôÎÓünL38JúÏü,LÌ·‹3<ï4kö÷0_šk?õ†¸éÊì´
®®r…ó»óš:+-¯¶Ÿ&Q™&Ýá¶½xQµ¦ßô«'y}àÝ5]6äÑe(©"É¦j:8@…)úOîXZÄè*d%šâU$Ã¦ùJÝðX¤ªÀYK‚µK¦Væ@I¡y–¨6@j¡®[êèÄ§*¥Ó„„ô0;¢Žœ·Ô!ª)±2$ë½4C9É¨å±vÝ!tÇjYyýºý?^Ø¿+…˜ ¨‚|’NhCsdc¤Lu^^)
¾t6¶»Fš9~Ù9,  ½pTzÆÉ£	uì=ÏÃxˆÒ¢·žÕÕE=o¤ÓaŸz˜¤ÓÞk¸.ì7èf˜†}õ~éÓë=@vKOÒíîáÂõ¦Àå»¬¦`aQß}ÿÑÂ÷»YÂéôIzð__¸~v7›&	Ê-bê¥£Q˜øÝ­Ý¢»~îˆäN¯Ø¡íùÑ¢ž§É‡$½HTßˆå“Ë1ï_ÎtB `5€àMüá¢îwâ<'¡­,¸»‡æ:è[848/…×Õ5-I"¦¸¯dÃH Ë$©¯R9…æÔyøüøš[gùÀÙ&¤…¥xCÀìÔîÖ¢ee	h^oÃ·6´Ï+jÞüîÏ:<ÜìJòTNµ†“!n·úS½ SýešOÔE˜$¡ÊAÛ8‡ÃÔ#0^H0ßŠÒŒfH¨Ml¬­?W%¶åÏé ¥ç D¨0µ2¯Zq*y]:öÓälu•Nûú|Û^ûÓ­Ãp†Ò,ìÁƒ—ÓS·w4Y¡y¶Éo>háNWã¶u0£úaÇÈJ~˜÷^}¹Ù‡­G[I<‰Ãá—ÙP¡'FuÃƒà,2é‡…ŠjivháO7cáÏüØ¬È3J˜ÐªjUŠ=…|mÕhäƒ¨«™;l¦O¼{ötÕçÏðËïU³_øÙ 7êê
Œ†cm#Pj8> ¥œ^àÌ÷Âa[‹Ð¬•ŸI‹:4Þ=ÂEsG ²0ÚLáOMYs©o÷‚¾ëˆyµ€ù½¦=\dIòÏp2ÿåHõ‡?à&]¨šc[ñ_0=f?|¨¬º:º}„c‰lŒó_Œ¬ÜÕNßÚ[ààü$Çªæ-èÑJmA 4
 í˜¥1 aCX½±‚•2R½)H¥	9&Œ7ª&ð`ÙOÙi4IÇ€¬þûã,ÅC‡ÜZ¤‰!Bvf€´Ó±¾&o«³óx}sý—õîz†Ò²QÛX€'®"pVCæŠCúÏë}Âù-®«K=÷ö4?xŒxÛ±ÝqF‹_t×”8£mVWÝýí­Î¹EŠ³êÖ}l¬îåÏz±kjéË®H‡44Â_RŠe+€ p¤ecQšw…ŠëÐ¿c¡ê…²>‰µX°;0–þ#‘¼¤"dÄ cdéHqŸ‚¤ŸLû*ýÑƒÜcU ¶¡%iºRÍ|çËÅçœ“#ê}óŸCtìlfSƒq;ý¸/àÆÂRí¬þJ[ ÃI<¸,Ká…ž˜S9ìç"‚M9Ç™1\ðGŽ›ÿ\oÖ*­ðWÎÞIÑ¯º¡“¥Oûï6lW–ÿ^qù«23ö	áÃ2JÛEž[ÞÈƒi¢…. ì±ºx¸è}iÝl²ß½9Èâ0úž$iàh<¡¿÷³te“8Êqæðˆag¶¹ËáÇîUåÂ¡á$9¸Çê…ÖpÆpbÞ9“=®8l¸F^ƒk¬™{èÊ`^õ^Ñ‚öAÝžýØFØ‡ÿ^r´zy	¨ ,5cu?oÿm©ÝlßwŠ¼ýK
ÜóeØû ï¨­Mö5Œ¦ÃI<F×1©x]µ÷H`Mm}œ 2³Ôþ´û,o¿OÚªýìjÎÀ{`Ÿð7i¹ît\ù)VˆûÌ9=a}S÷D}>Œ²sÐ5k‹{¸|
r=Ì¬§î—š‰K:ê{ó¨kúWØkP¼yT[;}R¼R”HÑÓÔ¦gUç3QC´C²ÊÌo¡Ò‹jïöfgŸþsèt}È1«èvéSì¨bw=ÞCgÑrxñAÝÙýak÷ÓÁáóÚû¤ùôÚWôgíÙÖ»{@/í=_}ÆúâóÇèŒ[Uÿ¥ÚëôûìSYÆÒ>zÿý}éþûmõ	¸¼ôwyIð¼.ý¬<SWè'úDš=ó1CÕÍ|½ã¬VœVØÁÇ«•6ìëmcy+W	rEÓ;Ëf@Å)g®Kçyí èøý¶‹ÿ ]tÌæDÂp é2Ÿ€“ç˜òY .¾ñfŒ”ªêý…Œ”²Kû{ át6w¶v]Þ8“Í†ýQœ\ƒÏV3×™{9“ÇzK›·õ•ìövþÑZ™9XÚÝ9’cTä³s¬ð,­×ž	Ò_©¶žv¥ÏÉSõûÿ‚s²‹&Â!}N¯U”ÛŽµJù(¿V‰òðO4œ/TîÌöo(Y¿9Ø~^Ã`ÊõvÍD‡GWë„¬¨;å£vUÔÈ†cG—TÑd
}JïÂN³iâHr|–YsžfpòÃ¼E(¬œ81ÍÚ¯øïhxœŒ§$!‘ùŠB]Ë"åMÐ×ß—‡2»U
Ò£Geˆ’Bä¶«Ì—ZRšÿèî/ùèø"ýGÄÿ?\yúô‰‰ÿcüÿÃ‡ßâÿÏW‰ÿÿ§‹ý¯Šû7'âŸ#î_¢ÀC ÌÚ+ë
Où·ÿÿF!ÿê#øÕ·~áÿJñ÷µÚ­ƒî˜û»¹W¿É˜û_)À¾"´qåbîKÁÝ‡/Ts¤¾wP ]?Æž]5Ë·Š°¿~x}yÎÛ@E_0¾º|ÆÛ¥å™·wÂx¨Ä$2óõMõýË­ÝM'4ŸéAÓ6Ì‡,ºÌÏ–ûŒïÕáúõÙñúûï6QÕƒì»á>Fz¿¤½	³ú¨ï»ÿŽªØ~çè5a§F}CFV9äÞ¤ùP˜T9Îo%@k[WL<îè,þf2 Ô·€o ê[À·€Þ€¯H˜¿rœÿÌ„ZìçÑ¢‘#^‡õUHrÐ	lÒ1J,…ÇÒ7‰ç6{@¬š¨ BˆTœÈúE0•D•¨	ÚòÐq™bœ”d!Ij&äR°TE,~|aà&	„‹B³É‘ôò®s°‹½èY¢Êsl¨Pìuhuni©Ýì(Ê©|õX±.±o	ßR¦>œ„½Óq^‘ûðpá|¨-AW$OÜQÔÿâä„E(YNÆ/êjÓ{W±_dñ$*±/ÎFàØxf^ã(C.W@v³t„}ÉþýCƒë….s˜PbŠ4C:¬©T”ã/ñpÈt,GÄ!B­½PóiµÄî]ƒ:k—÷Yz¡FxÔ(¦ÇPè	ŒlÞÀPf´‚--_ôTs¨¾wë^³#dTKËËKòN“þ a¼n[bïªÉ1ÒøÆ•ˆüWýQ5sX
s9€5jöb-.à3qÉú×	ÜWÿS#÷5hIÎøãöÆÎvwß^
Z†Ó$K¤‰Å­ÏŽðç¡N¢÷ÕÿŒð}u‡ñûêøgÅèãXjœÆÉ$ÊT›èS2À
+Še‰,g‘Gê}…}hƒÍCuˆIL`—ÇóvásÄÉfÎÑ*(–D¥Vëð¿:MëîÃþGëñz—Bÿë¿FäÿáŒ`ý4tÌþKËZ/Õm?£Y0o¿o´ß«öiý«e°-çšî‡“³­î"w 7ôPª‰eÓ˜rVÙk‰(£à«ŠàfAá.ÑÄa_Îã~Të8‡ÙÒRÃÕ+ÃÀ™œ,
ŸIa+#Å‰j/àOãš;tlðÆmk&áI¥¸ðbÁxïð´îÑ†Ðcî­R®aÙ6ôãîÐ¼B|Î™¨ÎdXFÐåÇŽ:/Ÿ—Ç©hHÐ8ÞÞ"S–suÿo÷î+“kÎ„ˆ“z™±újmAgÁÉLvï+–>£ŸW ³¢¬‹èûžìfç¨sÕ~€É¬ö­i"i.v!öüé˜ãYi²ÔWÉªtMØ{¿¡/ÞëÄmMˆÐRL´câ[Þ·ß/Ãëïq­Kí÷«íûu'Ò±+ˆ—s»LuAg‡`ëXóiÍÃjyƒùMyþ–†ŽÙ,3u¿q_ÁÿÕ5–ô×$º ¦'…ªìÝ›Óã+êø}"=â÷ˆýOŒÇH'P›3Wê™ñvšŽUŠô~D¾‘&ø¾)´à¼md†P†?ù‚Ù’éN'Qr¨”!
(N”ÊÎ#«¢í¬«ŸL—?8O§Y/òBDT@7EµýC<váDÍØ«wE|ˆƒ——éYuTœ^šLâdj°QN	‘?€ÒRºß_'ß©úì»µÇv{XGD¦M<<¼FÖËktLe¥•xºl>A•¶ÿä\ªÏÐ„m^F¦MÖõxë|)™ÏY«õ¯f%³òO ‡z¶Þ&é*®ùxL4‘:®¶uÝ·	PÓ¿ýM2ßìÏÄ—Š©øQêf:Ó1"Ã^õæÊ¹‡(~§ž¼†öÀÃ†\áªà46ûiÏm‡´Û~»çî™BJ\´mù–kWñt{«4_>@/ª9V¥öE¢„Zm9€·ð’cáÖs¹¸ö\üÞÏéÝàC¦¯5BÃïdëlxBº¦o3LÂAÒºpa¸ñ±KII;Ö¿@ç²Ó·»³Ñ•ÁNxãbæ·š³V·•'ÍÈC8@*fÈ¨–‘«7uëÏ’0†ü>;HÓ‰«6Ö¥âÜÿé§õ“a˜|Xÿùçûõ’ $Y¾ì{åöY÷ÞŒ“ÞpÚ^f°A ï€bí=Q×èqµ³ûí÷µÆûZ»ÔEûþ©mÑ†oußÏ9ö9E9ŒÐ’™ÎÖ¦ÚÕu»-¢a/\ºƒA¾½šEÄz´µ{Õæ®šÃ>œ«fÓD§IÆÁµ²d®•uZµ\Ì³píp"ÒQñØðTÝãqlû:Þ/%@áþ¿|7½_oaO×((	ˆ
;AÔŒTí}Rn©^TœKçSz£â?C?•I-ó98fT E¹¹ã7-à·MNâÞ9GÉ?…$TšIS…ˆêt$gð
Ù«{Ý£"Î 6bER“Ê&”O /Ã÷ær¶z"]ãîD¡=!¹J½ÜÈ‹»xÓÈ³kõ)1Í•ðcŽÓ×ýTm¦ã©¾kTñ™ÕŸ*Ýî§ž0G’ÇOeÉl \òiM†&.aNIœŸEý™Q(Õ1'7–ìúéEÒ ‘\Ÿò:Ÿ™q”ÃÈb*Ór¦ çÂŠ«3lÖdÏ¿ÃÌ%ÿÃjÌ?$ÿgíáÊS“ÿ³öïy´öè[þÏ¯òù–ÿ#.åÿ˜ñÏ‘ÿ#vˆoù?ßònÓ×·üŸ¯žÿƒæH˜ÿ›ííÅÓç%èMyÉgûmív÷Ÿ?ºVÒË.{~aï¢èCŽÄâC8¥c”wŸ×šMý÷¼™±ýÊ¶U¯†áé·Ô¤»æWJMš¨ïÿ%)™¬ÕÙÞž•¯c–m>Î‘Rx$Ñîºµ»qÐÝéîu¶m¯øã¬n?¨ïßu»=´ýÚ³váž5•û&
ÒtýhV¿_˜a5Pß¿ìlüõÍþµ²“ŠÓÒÙIÜÅ·ì¤ßôý$·ËGú–ƒô-é·•ó-‰?ßrˆ
~ËAú–ƒô-é[Ò·¤o9Hßr¾å }ËAú–ƒô-é[Òo3i²þa=^­Ö»_#iRWì:¨ÌÑùPWä¨þõ×È_¢Œ#¶§þJG¡‘ …C¾Ê™Äaò¼U¶à¿hÕW`àoW…;kh«ß2u¾eê|ËÔùï›©ãdg\'SGâ½å-Ê-Ñ‚æF’à¸‰
Â[˜¢J8DŸªóÕáþ^£š†ˆ?0âl˜£sl:LÕcíNRÌ?ƒÝî»cô;íî9Öð7 ÃïmoÚ–—>Ù†WM¡‚Àñ©8w»€|<è1
/)ï-õèEŒèìÃ!æ½l§Pñ²¿I›¥5ã6ÑBýI„¹<°_-îcb€mO³S	i‘žÝRÏþ’þñ9[…BëŽÉñWHÙš•Ît»”-Ä‹¤­uý–Œ4+ÉºŽ)ÉÊ†&É¶Ðv¹˜r³T$·¯ë¤"9í¯ŸŠä¼äºK©HçRŠTÕûÂT$Ab)eÚVf9#Ü<û¨,wÚ³Œg(„Ùõñ†’¨ïP`«[Ì„»D×oµ#ånìœ¥æ8¤Àüö®Äˆf]9ävZØ”¹‰92ßª¤é†<¢:ÞJ²e´ôp…Gà ¸Î¬—>ùsq½9næK±U9!ÍÏc)½±0óÅÏzqOvm¤É >­ ·¥WxÓ.4Q»€ª¹ÿ÷Þùà: n»ùH<Bkrúw¦{»¯f Ó²2‡¨J·ýìæÕ Ów±j¼œuSÌŠ¯Þ=Ðð–p™c„…©&ñíAýÁù‰V U8‡}v®ÕÂ<+gÇ$ËJú-dY]?Ãj¶ô²’ÚÝ(‘êË“¨nœ@õk$O]/qJàwëÄ©ë'MÍò¢W ¡rSgåEö²3¤óÞ¡)K‚}÷sZŒP@†Í%ë…4Vìd5*¨U·ØÜ¹Ï~èJ×K+Ìž¶WÞól¤šY5¹*ôè½zÃ\¶ÝÔ]Â Ê.£‘²<ïò¤‰˜þh÷ØlcÛMÙdvwŸÈ¶ò+%²}ûÜêã]Åý•Æ˜Ÿÿ÷te®>\{²ºúðñÓ•Uµ²úðÑÚÓoù¿Æç[þŸL¸˜ÿÇ'â7ûÇ6=ª•€ýÚžS°ñ}ËümeêÜ=Ù·acÌÕÍS¦°§C.
EF¹sÎ¼*nÝ¹ \Hªu‡K+¥ÿ‰mñ¦7_¹W_‰}
m‰¨C¡Õoôwê§†ö…Ã×Ç‡{o6º?­ü|U«×Ô35¾èƒ*
Âé=ÉÓát±}äBFv7R„û4ƒ½ƒüs¼ß9:êì>¿ÿ·ŸÂæß;ÍÿµÒüÓqóçëË?Á_ðoýÓ£«½å7›ŸñšÕÏ[›Ÿ7»ÝúÒý€û!e³»«¯Çýþ{ùcã©;`x¢V×})m—oþRküœî0ßpâ³‡öÙ¡yøˆvð‚bóð1?tnÎ6?=Yw¢ IÓF©Z7ÔÞþW£*‡;7Ç“@/·®}\Ep›JÖ5pWó`³ûªóf/æ!Î×¬	©y¿SE·]Ï\+ôA¶Óˆ¥]¿•çü•vŽÞiz¸s¼¹*ž7n?Eâé7Mr£³í¶¦=ôÎhóº”	×à´B9·Š&½™­P‰ÕcžÎluÔÝÙßîu¥í$)Ç¾±°·ùfãÈ]Å8KûÓÞÄé•ýçŒ&M£‹U ­ÕÐ÷RÃW;ïæ4f»ÙA—Œg[?ÐÎ9;î}n¡ÕØB8»çÆšÔâ»ï@‹›³W…ŸgþP±?WWB;SÓBkêçÏÐù¶ÞtF²¡w' C¿&²Åi|ÛUÖ¼Qè5†þ¾é8RW!ˆ£¸…Úk;¨÷«­¯›:‹œ3˜F~ŽE ²p"ófDQ=Óé…ÐìJî wÐ¬`j-l^ðÝãòXjPˆ} ¥°~8	] cÄÊs¼RyíÊíç=îXƒ0ZétgI¡tj¿ÉøÐ-Ðf8Äó¹g(YØo‘ì:öèísßˆ¶¸ó2µö»÷i4wï?›×}…/ì†>ûgá]µ!–"ÚCßæ¬©õ¦U ±îz}ªjÔO¾tP^;ÿ¥ó¶£‡4ßp°_ÂóÐ¡…(ý¢ ðœ‚ô,
¿£	h>ÕýàR´ê‹%òà7Y¿À$·aØg°|*ª“§Bµ)¥(§I£_ÑµÈñ_®\z—ªR)ÀgdŠž=m¯¥=^#îéï&7=¡2™<_zèDÎ\?À„™E¦ú…ÀÂÜ04¯Í.?ù‡‹V»þEšù’Ž‹±×žèW™äü	ŒäÙB{#q-’ðÂ±ƒ:@T–újzŒÓy[j!KJ êM<^¹¹€ñ·åÛÏ³h2ÍµZ´¢³Ò™Ea_I–‡=’‚æEWØ:˜ Õ¡¤™¨ûmRÎHñ"ëg“¦IB¤¬Ýhÿm©=¾¯–º¦^j?oö§M¼Œª³)±ëÔØ¬Õ½QKãÉ 8ÖkrÞÕHÇ‡‡ÛÅÑ¿âpÝ}^l^Î¬Æ*%HebOÎ
C úÕø‡5| ’™—-%dòo¤0Ì}¹ûýÉ~¦ò>Nð’Ó^ZB›Õ‡üSu†ñ'ý'¶}òðÉŒ¶ OúOhûÇ?q¿>Ùª8`3³Õ¿ŒtWTG­ù–¥¨4ˆï­zËØ5äñ:×šÙöÐi,m€•í­)ÄoO[XùFÑN¢ß °Wµ¿+(gÞ|vu¸S•ðu±¾V«DñÚÓ••ÕÊŸ³ñçµêŸ™kµk¬ÍO¿âzŸói½$: 7†”»^ÙækÖ»E±›ÒëÐ›Î›Ì›Ê»ƒÖ—³02øtŒáúÇœÛR–Ãùg’p0çŸKÐ¶úE¡ßŠãmPß¶Ï°Ý¼"ˆé„È]µä[èÝW?+$.zÅ™Ô){sµ’+.O%®Cv¨¸B@ðº%*Vµ²ìüþ}áÑ:!õº94ëÎ‘X7¿¾ä³æ®ýÖÒ·,/ì÷Kk›¤³ÖfRïb/^T­£*ÈÅÓä(-›wë|E	Rûè#e4eèÙŒFãÉeKmèÔ­$º Ê­"ÑißVÍì®ú•I4ík4%’l†=ûË1ô¥vš†Šøô$NNïÔµª*Ó,êš°ëz;þ³WÉg¶q@Ò¼%-›óîgªÿª˜®áž~¸Žðsá¿ÒÐ"w]oð>lvµ9á6k&÷F«þ8^oh&%7fU9qé·l"@L.š	°û4{Ãè˜ÌÃ×DºçwÙ´l!WäpØ"?¶êî„žâ¡š)!_xÓ]^² ¯—ÞäTÞû{¼Xz[9Zk÷Œñ™èH{òêšÇºRÐ.	ºêú²®º™¸«n*ñ:/¡÷6ÊÓ×YémÔVé~#Mòt)åÎ‰ÖÛm¹‚††å£Òô^í+ÿ3k%Øô°²©]‰–7îäX}%%9ît\æ¶.£Žœò]n{nêóó[n7gžá9'ØJÕö"˜i‚'»V¶73Õ,?+}­úÈV:éýÕ)ºø¹§%Èô,q’å‘öV›|òÉWA®<DÛ2—>ÅWê3Ö4QÍU§0É£’i÷nú­6äÞMßë.õ”Ä;áÉìnæÓÓ½TæÜÂàvœ›.‹Ù÷Y«ð._µ—â9êXU%oK\Òƒð3Îâd2P÷¿k>ÎÕwÍÕ5üïúóþ7ÇšU*w|eù¤zïM§¶´üK'Ç'—ª­ØÐ|¥¬qÚüM‡àªN:§ÏÔyª¶œ*é¯FíœíÌ]Ãœé¶.í#ÔñŽ	¡LPpšc_‘*•Åíq
‘ŒRÄ¡ØÈe±~Œù …=Óì´•âÕy+²ó(kQx”	è;ä‡`£œ‰]AÇ^Æp:¾ÿŒ°T¾c^<Ä~Me*êó'–äÍ|Žûw<4ÆC_ó»_õƒº='ŒÖI;ôê"’{¨é
ÿ×t¶;òî?·ËýV¸~Õ§ËÞm«w»
Q5•&eÊì÷×íÎ!Üó'r‡“˜5çŠF¶Ã*¡)È]¾hìr§ç˜²_]Y³ùí«rU^x“‰Çö_,\ WŠ‹š½Æ83éý¹sOÖ¬ ç¥¹	x>ìnâ-*¾ÕJ¯3ä×óJœFÉ±)J[A¯’(c£©iÄ7¨Þá\¶£ätrÆÄhu…×9Â›òi50µp-ö^Ð^ò3À-«ú“6 ¸ð ×à¸®÷ÈìŠŒúHGrb2lÕz	þ\õo’M#OÈ%¸Ÿ2¦Y˜ôÅ>+ºó¶§jæÿ
›_iþ©1Ê‹…Øù|V,'jÕ—IqÒ÷r¬09ÍÿðÀ±œëÁOÐõÏüG0Tñ%*(õóœºõ¹â'@²>±$»¯¨ÐžEÃ
•Ö3 SKëÖTº»)U´PíV½Õ-Ûn»»ooŸîãw«ÔÆ›Ã£½ŒÑ¤b	ôyØâ?o‚¸re_òy²}É^xI—åsÑ_ÒÏ¿¼9‹W4Çç…æžšä4÷žßÁ;& µ0-ó¼Ð^›-.C?/4w³ÜæÎóê7t0nñý¼y^»_~Ï[ÊsŸÝGrÄïçyù_¶¯øÏçUxïxÞî”$¨ª÷*–†z¬*|ž‹~[ÑT®¼.5åçU/t÷«úÆçUÍA½®lÏ½æ.Ñ‰kaæ·£#vRÁûÊºH:œ %VDiÑûýˆ‹×£uíý’ƒ°mÉoÒ}“dqÑ7«ûa¦,¡–])¤ît‘úý@÷X	LNkú˜dbëÕ™ÆªÔ;p¾
O§îÛt—gL¥ˆ# NfL®$Š ›©©×³8ùè¥
¬ŒyœÓÅ™ßEn|~ÖÜ[´zØ÷ÏåÊÂª)`>¯i@Õ×J{[Dd=!/•ª¥-J½á,-OúµØË÷U~òb,‘~Õä‚Ñ$˜ÝÃß¶e©¼(Õù’ °uL º‘ÑZAî¢—@v¢¶$:]ªí­Ž©‘Lí©n+ÌBJ·æË­õçË÷kðŸkõÖ*Þª¬ˆgCgõ±|ûXú¼Ì½Ô¡›úRûýZû~E/Ÿä¯õ&'¬TŒ…°ýß\-æÁZÁú‡Ÿ¥O´¨¢a?5Óý•ç$A‘µÙ¹XàÙ¿ž£í—%ò/ðƒ
³P=Rí´»¶üqbÛÖ+¬­½Z{Æ·$=ÓÒõƒÚ³¯µæ¨ºƒgÚ˜ A8‰Ïmö3Hy«¬Ã_kw¤"Æþ¨9Ga³q¯¹6"ÌàvßZ):¾÷
2!èãÔñ‡Ã(3_½ '$À”ùõ§{½ù^º›m¤£Qšìíz¾ä/øiAIzAí¢dçµšûÜ!?U­ëÞ’í^ÖXµöŸ.8Ë’ÔòIï¬¡FQ˜ä¬˜÷€cÄ×£N±V¾)¾*×9}œ¦x•!–QËYÔŸö¼—g¡à$þ;³w
$Ý#Ö£¡XA3ÃËX¢ŒÓ` ¯Mjs±54cè÷™þ7ÿ®–¦ÕJ³†·:V´`ÙFmé¬dÏ‘zJv`gQ´!íZy÷8„Èùp¿³ ¼cà79³ðÓ‘Y´K—Œå1úF P€7\Ë->¡(i±S›miÈ;X‘k*m1MšNjñ*Í.Â¬/»6÷ÌDpïpù$Æ°Ã!õ‡W¨ÂËgr`d‹g‹(ZˆŸ9ã–AW€„ÛØb¸FO>ÉB•±3‡åq>9¬¯^UÔ¸Ë›mîðb›Éä²X5ýˆµ9ÅžË5«Ÿó®¢Þ‹–˜kp£QoJshK¶¶y“Švà}DËòç¿è+:~Ë×éðÎI9ÀÂu3Þ§ÛvÔW¼nÇ›“éÙ¹ÝíýŒëÝx~†ï² æR/ÆLÕüXÉ#=þèõãL«gÀwƒ=Ð%^š<{¾²ï4ÆÂ<ƒ8Ë'z¥H#.â…ì>žhÛ¯`£Bð·“/ÞyÛÝÄ¨…×˜hÿ\9%û¹¯UÙ-¢S>¸¿±E¯JBäŽ&…ÌþK€úvQ1æ»$(KÝ¢‰[%@=×¨A™ìµªjÔõŠ,èÚ!WnZÈ¿iÆê©T%÷ßp*º°S1×OHë‘\ËçæïÂ†lq„+¿N¤ûÈÜpWŽùÏÆ9õ°ã+{³^tî’UŠÓ16U]}¶øô³
¼aÎLô°Ö±†éaª¬šé2gø·™œ.i^¸‰§Z¦™=[Ó{.6øef®³Wm‰W13ÐGÈ€KßÂ2ÌS¾g/OTæ?Hh®[ƒDwãAèËÖ>¶šT±¡ò«†Äå‰ëÓÏaQîìŠõöuGÅ
&³/ZxÅOñ4z-yÒÒR‹q$ƒˆ¨KýJÈœ©ÞO8é‚~á‘ReV‡vëx±Þ‚TžúŒäg]ÁC7Øn?À½p&ÿ\$Ú^€àóë¥9×ùWÑX…D•ë'©Ìºúè÷9WÈ’*‚*‹&Ud%Ìj]nYP7eß†QÈA2îœPÏ±ª`p|ï^m©4NÛ»_B:é=JØàIsxàwøÝwí½4¯«ÒòBá×{”ñ#{'ÁFWø¹K1n)\`.:þ‹s=T]âìî©£½Í=´•m˜oa¯ÍíNTÔÍ@ñÖ;]HÿøÍmÜìAêËwˆ)è@×ÑsŠq–á\"-ž‘£á]@ÚæŽ ssú¹Ñ9 ¨|)œ½´;°-yuBJaŠZã¥ f=ƒ¯Es(©[ÆKD'¤®êñzÓ\“æOÈá$È?üBjÃ°àrÂ9¡¨çjŒNíùŠ+Ý[{t/AŒéämwV.Àåï‰u9òoÒ­íN6ïž3¥ôÜ£JPìÈAAŒ›¾w™9(V«Ö_1›9ëóº‚¾Ø¼që•û‚˜JtŸU¢˜–yåVHÿòk_ïðÖWå^Ñ«õçöËb²öÜ¤€›¥kóÉ@¡Èu›VÝx¹÷†o_9><:¸E†‚7«P7=Ûro'Ôã]¹wÐòK’æ± ñšm,¹^xè¼ ST¼òÈy…+ï,xá±I õ“>¼ö¤úµgr8ûŽTÇËÑ±;?ëv¹D!—BG®WËZöu íì(c¬ëZP[lÅFKãû9î‡ù#ßÉ¨ÞˆƒXoÌmrÿfº”BS™wêZc¿hËÌóe~eâ“«~ÔÕ 
ö¡â M6¾e6ði!ÖÅO.ð[3=ª©»´¬=Ö\(ÆÚÊí­ÕÝ¾6¿#=*=£å—žUqŸùëÓ\öNøÃé¤hÑÕ¦pŒ¨~Ew­Œ@°ˆÇCc™›/ý]p+x¨1Ç„âj&ÓÐ³ÏX5†¸–kÖ)½mE?(fVUK­@¿/E_U0a`¥ù-WQ$Â[‰M¿æß"__K_‘À_´¯¸e88%nÝI‰[÷RâÖmþ]äcx×˜ W¬5B4:â ÷ÐÜYz„ÕP€ÜÚ…JÚ‡(²W¶I‰JÑÌû«<³Ô$÷OFéäˆb`ìéWN' ×A·säûèàM·FFú¦Ø.Ã§ÒîÎ)Ýê£¸µ7ÂÏz Vhï„›ü¬®Š~Ðk¼ÔæÜî]¬Ú~«±(|éEãù¸6PËÆæVQtßµaÌ(xg1Gøá[ÿOÓÿZ5.øù—ô~„7*˜Þ‹$áK{·3ª«lÜ
2×)Æ¡n™ì¾/*Ì+»f§7.j£èæn¢p”ÜÅ‹|hæòõŠí¦[c×ýõ¬»>zß×­gûf2ûÝÎUÏå.æZ®rr×seëÚóÕ¸Á78^Fv—I]á,"§¿UZa‘ñÄ)ÞWàô4÷¢·ìTŠ.á/™L¡¯Es*6·Ab…×Wñ,óÉt0°þ[òÙÎ†¦\{U}×ŠC!™Ït . i¹Ýïž’©Î|¿@;L­GOÞJ×¾;µŠëxÌ¼hM>NªÏÇ»M¾üÆÝ•ì–NWvÍº1-wôg'Tn‚Y®£ªfcx<`çêl¸Ïl^>ï­ï]°½¸ö<fHWógSù’ô¥O¯wE†ÔGTct¥½œÐZî–+Þ%W¦Â3oÁ¥ÎlÎÊ·Û>›Ÿ~Úkí1æßÿÉ÷eÊýŸOž®=V+««Ÿ¬ýN=þÚÃÏÿðû?qÿ··6º»‡Ý¯6ÀãÉ£G3öuåÑãÕ‡…ý_{üôá·û_ªøü°ûFýÐÝít¶Õþ›—€JP$¨jŸ·’:ø°¡Öþ¤þ2M"µ› /³øôl¢–7êôP½Ê¢H¦ƒÉF/’–œš`&½–ú^ªÿòA+ÍNÛ/Õ=²KôÇ9ÞL=Š'LNÀ”‡ñ%Éy}¼v#>Á¤h{ý¡`;Æ84N_…7‡|ó¨”Ÿ"Gk(hÏ™Žç›”•p8L/ðfÌYË¥Ï~…#Õ°ÕHr5Êoªýé	Œ¦ï:åz+Xvƒf<Œ(P‘¶ä¸
dVâ¤O	 ~È[zy+—ûJñž÷ò»c,~ÁÓü2‰ö£<>Åðm¼k„á%ß“‚Ã¢(LŸéž8”DTžR//ÑPŠwóNÁdáŠãd%}Þ§Ói˜…ð=*Ž”FÄÄÉD¥õ‡Xµë4GÍæ$µ5AÝèJW.Rw†ìm—Óz‚©¿£"ÑÔ›rDm0gMä)FÎfòÏp.áx<Dß…£ÂºÂäRvÁ‡é`‰ô„‰ú“KšaH·ãL§˜IE=áoØAKÖŸÃÒ”0áæ¯^D~Àé Ì|ø®/ÃËy)¹ãXæxÙû$g1Ö¾Q{Ð}õj}¬Qè)µ
¦P¼'ÂÕA!ç$ò,ÍO-Ëvg§ŒþÐÃ%dèR]ÄùY½a†ÀXíE¾î¥ýˆ2Bª´E‡–^.BÌzž8¯bÍðð:î6Ì­Ç³ÃN´â4OoNî–î>`r’î·O©Ã„3XÃšÏgŠ¯N0¹ŒöÈ^N»‘DÃqSº9b†8 @­¹Ä=ÂEpŸü"Î3Ì?ÈOt:É¬ß§:7ºU‹èìtŠqS‚^”MBJCÄ
cy|ãIÌ c£Ê]r¡Ô pÔb  }? J®—ûƒiá3\´‹xDh™WxñÇp4B¿ófO{göÄèÎ8õë¯T"ˆÐéVƒH;Â1¨C£®,wMÊÄÐa2ÉyEx®Ì+/!V_NuT@qŒ°§C×Ð­õZ+¡Ÿ ‹™T~èB˜-ˆ|+W9Mñ2 d‚¿b&'¹Qƒ& D‰	íþvzqRãä"ÅkÈÇùz°¼ZWx{z6!^Ã¼ãm.böòZ`$‚ñ	“þà4>×x7ŒN8×Í‰ÇÛm¸;Ýµ‰:
¢˜]çØ3½ªûl“a’w_/‡è/-–Ø:™ýÃz\HÜ½YÄìˆg†¼ä’PfíQ—|èÇäŸÌ 9ì±.‹þsg‘À{$7‡[tRd(â,¢ÞEžVLôÄ€n°Éf
'›>9ç’(æ°,ä<Dw$1ü`Æ#¸Ò•’ðK¯‚
#µàu©°GÅ,á¡”ŽÃó‘M“ ¼ŒÂáÆâ>á²pˆ»ŸžQôw@|€CBéò”¨òt 6òLŸ07:Â\P8œh´bT„NÂ)@ ÷0IvÂá”™i™Ê/•)ý+€žáÜ$–4œà‘H{½iFŽIä0&]JÌ¢HO€Âý)°c„9¼…Ä$îQBö)DÁô/¯Hò#Ö>Mªã	á|Òz1»³› Ñ53ÀˆRDæÓ3 ‘báci,|Máxé©¶¨P­Ì Q˜a[>=A»
†ü”E–K¦i6ø{ŸÊ_ ZaJj”È¬ 3¹ëžHbJB/ËJÐÕ`Š»k#°so`\%ò*Í­˜Ü;UtÂãç×P
èšl#0'gäfD8ÌHK’ÌcPpŒ?#ÝÃ:îÕMÑ&T’¿uá0pšzMJÈ…«'lXÙ‹Ù¡8Ós=«œå,îÒ¤¹Pø~Jì…:šçiÌIÏ:ËºHšqc=!õB,Õ›…S>c@\íç@[{X}aH ™+Uó²%’K¸_–ážjjèñà
Q™æ<¬#è¡1çb4Ará;¿Ý9·x@É—c”;:.Å_„~˜Ë‹q7fëBGÝƒCÕÙÝÄ«#7·Ž¶öv±ñJËÅ	Hï×ŽScñ”öWŸ¢‡æÍ”Â¹#£UÖXàæb†ß5‡ñ¾ºÎ"5äëVi6!-€‚Ñ(F MÑ”0ÿ`æºG€v§2¾“Ìö$ë‹ŽØ)»çž½RÝ“&¬öû°å95×€åÖ UM^ˆòmIÍ
55˜Ù%bƒKã`¾ +‡‰Ä´Æ,:á¹IÕÑœ9fª~8¦c‡_¨xƒì¾`ù5ó3.9‚Iº•.¬pÐSFf'$À¢— öX*JŸQú;6 ÉÅ9×Æ HÈÄ&V“9(ÄZ¯"iþªi—Iv[0:ªÖK¡/hƒÏjŠ(–	ÃéJÌ˜²ÙN÷Ô{ r”ül€Œ§;<¥P"œû„&¤%0$®N¸E:…cî@ï‚h –‘Ñ#¨óÈ#DMàðuÈN"Ôâd€»Aumáˆ>õ¨…Ý#8@¦?"oÓIÓlóÀ3h"©Œ‡¿¢ Ÿs]Ú³}Y'"pþá˜¡¡#GG–i±Ð,S¹D<A“‰.Â{0¦ÓÎ* %vRMŠÜcìB~zÎê™‹h84;0:ŠèŽçÏ¼H	f	D¢„½…Ôu€È/jíJT¢²–PØ!™!p…\†‡+K_DÆ‡²TÆu‚“ièk1µ&É\!aÚTKÁùc6/álbÇ9x z Z¤ëbÑèŒ™¿àVm“¼¾›¢È‘×Ñ‰H:`ÌcuW6/ä“XsTèsð‰]£®°r£¡~aFfs…Û¢[Bã=#˜À&±:&Pš/Ô%]„Üp!/Ä""“Äb‹6h›±d¨RÔ¯%Ìš­ðLIev„av¼1Æxh	øÖ à0t½c,8@‚I²£EbU”8ìô˜È²å5a 'vÚ`e—!ƒv&1ÔÓ(ŠH‰EÂ˜Á¯ôAˆ±ÚRâ¡Û@ÕSóüš£ÖDUvÉ‹hÂ¢nX_Î¥ódßâcéVÖ0&È”öN~‰ˆ‚c÷öl¡ì!µ=t§¡GxQT³¾ÚÒ@³¯;€äóÈ9¦ß@=Qca{ÐéZ J†Têçx¦oIPÙÒþ%Z/””-ÜÞ”;‰D$:ö½é04Ö¶‚aÒß4<EcHÂÓÐzˆ6¼da,¥X?Àêí¸l¢¬B^tvI½„:ÉB$j5æŽB•­!gÔ°á­á­Ô
Q	Ô˜t¨«$/‡u¶¾ÒÛ}„6è‚ìÐ¹Þ‡ð”‰üNø aÈUš³¸Q–*Y‘  æÓœÎøI]Qí}4Ä°¬Å„UDt;aQ”¥qñèª¡™ˆ%|UFÚ0žH¦­ð¤¼ÄP3æ%Ö„ˆp@‹MP+Ì¢&hƒG.…A?Nt©«6EY3¢ðôR°ü´Ôhˆ$>éc#Úcˆ§ÀñŒ
Î˜×Sˆ.!1anà…°×uäÈ¼@&Ü>V€~Ÿ7X.Ááãa”iµ@ÔJk´çvpŠì±åÓD`bßÃ>µÍ†0tÃ»™€	GNb¿OB*ÒpcŽB©Kk7´ÅBgÀó´k%2]§‰aoî`d“Mµ©É.•žà	´rLŠc@þŠt(*Ÿ•`ë_§¨µ6LñDt}æt·÷ó x\	¨E%s’¦,„Ëp,"’{B•5îf¢Í9B'@pI&ûÂ”ñTöeÿXòl[KkÕ>†õ;‚„ÑÓ¸Ò'ª¡i9zŸ«ì&ÿ({»Ô?-.ö$õ	ØØKw™„#®ê`¡¤ÛÓSå]kú°@]+˜˜íf§èMC9¢*á„Çhšh%–Ô]F…ÚN@$Ã„R6Ç¸sp¼h¡Ôˆ5àÕ¤
®lâwqÈˆýÚ”›ådPË"[aÞ­s$ÚXylo¸€‡›?ÿ¨éÛg€ £eÜ®l­…u2í…„ÕÈè…bl>%/^¿B€"¤Ô?k!mÈmJ†è}mà'{0J°Šó”•-Ë1^¡u¨8¶*yM´IRï\à‚Ô€F2“O“a<Š±ß†­iKYëå”ßyW qBÌ2puHRXåûÉ¥â‚rý÷ÔP§ Ä#¥Í‰.Ë#ãX<™ND·×;I/@9>xev@9Ù§…’&!žópÈü9· =¹ôuBÚ`ò€˜<"Ó8F4Vj½i9PmÑ—ÈÂµÑg]3°¾!ÊG¡ì…öy»µºÈ,‰6@òIêÙˆÐ^<5¾3Á1º=Pè0š2ÏÂs>t@´I…óeYÐ(†ÓœrØÌ‹(º@ˆ]‰Hó€2j×€íê‰%Ëb8r0Uû'£]zô	È‹J•pÒŠ™]ne1ËgÂ!Â(…DºÌÎn°sš‹;ÉÂ¦²TvM‘Ißƒ	Ú “è,r¾éÛ  vØq*:È´66:ï­à³Œý{ìÏ6Ëˆúvá€9Ú%>1ª[ûu™Á›„«nbì0~ö^œõ¦#]—Û‹AA‰ß8G‰ÀÀÊÑÊ©Ô!‰‹°K$Ä{ñ ÏÐCìdu…Œ¼9Ê r]’&ø°…tDû=Þ°ßƒ•ò>°¯<àVÍš2Ú±×m9Ž»©·yÈJE¨BÈº}ÃöQbÒ&fØŒÞY’ÓSd& [†äÆ´0rŒBpìÕ`:nNõ=RXð©œiÊa««š½ÛÚßsÇûÐgÔZS^[Q› ªú¸ú§?=Á3ä@xQ¥"C¬FªbÒ'K¢ñõè5ä6âQŸV²/ø"Œ©<Õ¥öYÂ¦‘FÈ)ãÁLéñ”o2!	Ã{u@<T[³^L#$¹‚=Oy(³BqŒ÷†èAÃ•PÍDX12­8Tã›ê]5‹ôB–É±
g‚Ô•”H é(|»".É&>îìSÍËàÔÞ`ÊÊ4K›TC“vïQË9·ou|ÖÔ\$»[áÒþ|?÷Df.6ÓaZ¬xpXâé¨šL'ù~vÊ’Øš±Ð]ƒT ?CÌŽÐ^/qfs]ÏÊ½„C+wÈ®`òá"‰1‚ /4¡ø“\hAÑâÉ¹ñÙôE{TÑ˜Eq!AO­SƒQ©?g¿ð4×^Ä´ãÒØÜžÑ4Néð€úæ„OTÛÀ Uª­ÙEk¸ÙHŽîÁa(ÖHQajù™‘«»)(Hú `?ŸOÇ”i€ÌQ
mð€	¡)<v‘mGËv"¿uí¬s-ý%AU¤¢aÌèÜ±HŠÞKb{ÑF1k5‰ˆ#"è­}T…±âæŠÄMCš»Œl=ta„W¶ú!³ïÀ.#c%Rš( —Î»Ž‚„ÀvŽ!VX¼I¼'·‹¼í’,AqUêŸ—Sóyà¶+êæ©•E+$Û‘¬†žî¨i@ãbµ§&íÕmŒ–a‰E ñËŒ&ìXâÏ¾¯Å>C´%B;”Y‡s‘æy”ëH‚ÐúÈ
P„ÉD%0	h¸ç±Àêµ`Üè3(<Ò54õ Y»ìC3‰¢$m´![vfý!Æ ¬ÍAL\†”MŠPå).HXPŽ¢÷}Ì…¥ÖVÀÉðR|öÖBÃÈ™€jÃç9vÂv*Áe©‘GX"Šè¹öÒf.¥úu}GŒ%¦f»Z RD¯FÎudÔËLÇË3„Ø—<æUId,Ó–À¥Éä†–™£0Ï¦.hÆAŠÉâ¾Ãvx6YÁ—¡òrâ…ãZÄhç½Ç7C‘ê‹R{Ân"œ¼¸#OÐ!úî÷ ;!«¾öj³‹#ô¬ ?1Öù*Œ¨ì¢kú<Nù" jDâož;R‹Ž‹9	jáé)"4úmc=S"®lš;^jËòeæ6¡²hFL–£²`žà”–ú¿/áÉÁI$AêGÚ¯/J/+2èzJHe«Ú>òÒÃÿôŠ¬M³r¡s$‘¹Òƒõ}ZYAwD¸óÄå©» ¬;}›3ƒ—ú†’
ƒ±á€LŒËs ÌüÇ3¡ãÐÁÁÜib Ñ¼J‹Xa°¢HÃø”D–±ñqXê†¯`L'Á Ôà6$«‘Cïì2'XÂ¼¨“ekŸvZTàh½AòÞh&±¶+1•¨6õÅYZ	Uš±ýL÷Î2£´IŽ œ%­¨p@žeíÿÐ5‡LÔ2Ôß–Š¨>K{,xIZÆ_]FaÆ¦[§	sNÇþ¤…É1s«ŒC¬2ŽÉ†%6j˜¥€8îôaˆ’©¹¸°n‘4\H‰'“ryŒ0=ÏnËÞÝƒ2#‘£fÕøÀ!€_ÚCJ’»pñQÊÑ b5‚£—§‰œ°\‰º”ëÓyÆZ¿ŒXLX…!É6¬UÔƒyØ"w¨#,ØIØ‘¤¢‚X	NðÙ¡®¾vénDt8VÆG‰<«Uå].b(+_ÇçÚ¨Ä†â´×s’ÌXE—:z0Ð°À–¨£b/Ú®ì†°WOŸy¨9<Fä•p‹- >9±rÑŒƒ"ÚgÞ#?{fÈNOX:D§Òr1fŸ÷£Î¢%CÐZ©]Ÿ»á¢Q±ç"ÄIf&t™òà„ÔË`š±u±•‘“D1ðR®ƒwØSËÜ=Ç3Cwé“Ò¼„»™¨Ä#ÿøxÇC.óDh¿Ì–!¦DïìÖšsÉ%Þˆx±ËÝ-@.Çòíð_VÈQEŠYë¢@}kÆ¸á#P8«ÌCê•C­© .»gB·…wè¸jIF²È3 0ùÜ×r6p¶Ú¸ÉBÐFÆdµPÇQKlÃ°ë·Î“ÙÛœ{Úd.§&šyj¦dGQÖœ¤Mü—Ã¿LÈŸ†0õƒ3¶°#0¢ †]…'Ü÷b‚¡ž-^>‰˜ÚˆaÈ6‰·ZÇHØS#æÑµ2ÑU‚5â.€FŽñÑ™ ê	è¤pÍ±x`pÁÆ^R}ÄðpxÎw ‚æàžGvß÷¦”H¡†„ÆxÔÃ‡Öh*‡¦ØÁ|:b%ƒšhEÇD:Ì¥UÃ¶"šYgË˜ÁH—¯êÆÀKÃpÜ¦¥ðû^.Î«Ür@í96.obÎÃ¾¤6 ¨‡l‹N(½Q6ˆJ‚¹JGÎ-24ÒC,aÞbA?žLS¾Y,·^ØštxÎp„ç)…-’äžêl7‚Jg7XöD±ZNˆª=Uó åÅU“Ë1ÉŠ)GÑz™0"¼onæ¹“òÑ(˜%´ßxjr
ƒ+^Ò+lÀM¡i€¹0z–¼EÑG4âçú¾úÆgŠÒL8ÊŽ&†FFŒ¬{aæz³œ>È`à¤ƒV.@¦ÞŸ¢4Í â«Ød žî4¡®IÀ'0ž„+’‚¤	Ä12j²Ù,’ F!½Š„ßâ¸V·ˆRÑß:<È=bN„à–•öóâF/ê£c !y`º¢õ‡è’ÁË„/¶}k‚ÛwRÈˆÀñBQEÚVÙº¡ãñ¼	"
ÂÒûœšÏ–è"ozh
ò)†*FE6#ÎÆIœL‘Èån"øZƒ2q"Z¦’˜šrè¢¤Š0`S¯‹CsÈµy‘šïûƒLÝôQ(A¢[Ï‰–”H¥kŠÕD_4>ŽÝznTÎ@²iYt¡kcƒiŸ3·@73NLf‡¡Ê9‰12p­£6é‡d o71¬E"«gD;‰¯G“i<¹4riÀ4…ª,Wš7ýæÄáHÂ—€ã(¨da¼nß¾­J¦Ä“ÈÕ{ÖõÕ¬3†)øSq ¹mcé!›N@—ä1cÃ½NRv ;r ÖÞ¤d0v
¡°wéž­NJÒ5KÞÄ)pÏ„›¹ÆÔ€ðN:dÞq°·S7aKîü=jÖÒËzaPèBŸ2·;­Ò£ìHáèÚ{DÍQpl„ø~èÌÚccà9K‘]2xÕT
Jà1Ø/ê…Q€Â@ë"î÷#2‹\œEIÉ	…„*L …vgö‘–EEÜŠÈ½u3õÑÁ\ÎãtH‰x´¸©P£Î´‡ÑaÆ6ª.ìeiž»IˆÆœ³ÀTaæ>ki˜r®ß³òðpf½ll",ËÂ9Ðe> rTp@ü#ª3<;`8(Î‰îJ£kÍˆ´Î4¥Ü PÀÍ'¦	ºEÈñžÉ-6õŽ õ´…€µ_æ(ÒÕšóÔ:80,‹ÜÐÄq‰—.™7uÚâ¬ÄãpF'R¼aqÒOi¶g]n­ z<r((ñ5é°	ö‰iw‰‘@8f„“Ülº1ˆÍœLã«»†,/Ãä‚³Ã‰m}¥œ'Œj#NVÎ=`Ë·ŽRwchßVÒ=³‰>$Ê[R 	:ª7Nßì®ª€‚®TrŠ"	§/¥ðžc¤—]½‚™1l¬ª
Áe„R7€SQ¹æ‡†Õ›,úY8‘%$sdðA§>ƒ- ·Äò,ài«™ÛQz!Ó€÷P‰“š¬\è"½[uël K0cúH'„(6Äw,vÒ˜|Ÿ”wGîC]êì½•qv4‰Ûšà6R&Š}Óyt>vÑïÀEetÆ±à½Iå	š]¤,œ-3²sB2¢ê|Ztßõ¹„ÂS¢Ÿ¬ócS’H›ÔáèßBŸ¥ÉÄZˆ06)Î¬5Å ‡\­>&bºú¤8‡g(cj'ÄI7%µ%;7ìË¦ð8ægv¹™°v2¸LE]«6þ0Ó¶Å’·•:«öÉ2èÙ=‡’GÈÊv<±³ïÕñø›˜7À£{y<vò4NŒrkqV¦o3ngÔ¨ÐÅÌZlÑ
±Õ9º ´½Ü±3O$4å—ìRúuØÙll9•jHÌ*qãµ'ƒ7´ÓìÞ§ZîN]OØÕ1ŒpÈÀDg"[!ª.e—ÇqŒ¢~a$¸†-xÛœ•K‘	>¹wàb:¼G‰VgWâ0Ñ[&–YüK?Æ©sî-W-ë,ÛÂ6JäM]_Tµ¶Èú@uFÂ¶i:ŽÔ^FÖÉ¥ÛN8'‡Uök’A@J)‚]ÌÅø¥ &;€©\!ˆ­mB<Í ß!]«‰i>0¡ $ÞàÚå$¢ý@ûˆLä­5°kæê ö)vI”ÍÝcµg­'Q–ä0h5+æ-deQœ¡ªXˆ%Øú:=Ú€ˆ²ÎP6)U£3óL‡Êé$@íÏÆ(sj‹íŠ~ÿ¯b,)ý•;Ny7ŸÖ©ç{æñªY£ÞF1ìùÞ¹ìÌš¿k£ é²˜[šôÝ€ÖpY(”Lž	`s“™2  £B	qý| äuRÐ³Ø#Œ
JÎOP62~§åœŸ´x¢Z ’uqÛ”['àIË\CãÎôkaî(Ï¶ Šº~Y®Ø€iÐ|ÿØ"%NØáÆ}P>šÉ±µ 
;'	Ý4d†9Ó“Êa€TTE×	^‹ëä°’oFLå)<‘XÅ…U5Š—ó³¬&²€È«¢¥SœïF/)¡ppS€±˜
±…[!ü6>óÈÖ*›>^;Aa$¼ÓÅ.TòÔïJq"’p˜š‘ìwuLÕEP‘ˆì¬ ×#„²CY,ÃdPeeX)GzYUI?pÁD?±Çæ#Ö†\F ac«¤ó@:€æMÇÐ@|–ÜÖ‚ƒj"W†!»2Ö0ä„á'+ªORÍ`";AùEw@·M	ê^Òµ€8@tÖTZ’~ƒVG¹³–`ñZ¼ã1Ë	|ãè$E¶žŸanBk ë™£óiY>­[=.(N×&ô¦â`´½ø>táHÄLglgž÷,}À_KgÌ7ä³ž=•1sÈÐø+9Pš"½Ì€B‡o˜h¡¸šòini¾bS_d‘3c÷%ôbânµƒ'íMý'ÈO¤—¦¦BÞâhÕQ	á²^ô2J3³?µÈú7–Ki óíñÀ^^sF[!]BÇNºÎ®]æ#Jö9\EO&eùyI6û±“ô€n†Êmª¥”CÉšO"³x!Bíâ‚9éLƒðÀ™–Ì‹7‘7Ø¡Í¡’“ÀâyK½ÒCn 2Rj>‘~øqá˜óBf$™Ø¬9rÁçìëŠ–œ­W±	~%94Æ™;œzÈ@.%˜6$ €ä
aX¥sÏå†$Ü%åŽæ|ÒD„éÍô0Ë¢éÀz‰ŠSÊ3#×Ê÷ªxÜUÓ©ÜpËú¥Q&’ˆÛ0Ò[œeW¸Ð™OÙAò—Xÿ,HuÒ!‰E6í‰ó2c¾¸Îõ…e12¤[c¬“¨ZñPy²þŸKü®GÈøœxNÕä‚WnI.Á¼²~È÷±T'GÝ‚Ê¨ÛP„å>FQvÊ˜ãÖû"ú6ë¸Rƒã˜uÔV¢Ê«“0wvM¸Èeà®‰°³Å.ùàHÎ50n¨¥ç:ß€}-ìl¿¼Oû”EÉfrr‚DºÏ
ÖÕ#Kœ·LñL#qø<œâ¼$K±˜W1ÓQç.Á ëŒ9¡8§ þI¡0±¤üVrU›EßFÊS¡BåÚó&i†Æ÷YHÉG–Oyï³i¯4„(…;¾=±X]7K/Ã¡xÊR'„Ž³·ì\Šó˜U[éÒ]1]f=A³ÂDrO/X˜KMNƒäý§ˆTúNNL)¢©Ýg§Z‰A][‚Ý·^s% +5Ó°‘TŽ=JýãE7‰ÕË-
‡ãØÀ'É*Y]m©}]ÖR—œKØê˜f5xSñL‹.åT¨ñ&í¦óªÅìÛ
œ”ÆÆŒ'ó6ÍmmB›¡CdšpÝY›ò{&‡Äki‹á¸`/Ò7ïq Œ'ê;Õ8ªÓqÃ-¹¾iØ!v)‹úúiCs
,žGnAgÇIàa.Aq×¤„åéA9È\È9Òâ+¥ UFBí™æ¥Îœ9ž¨ XAPÒg¿*¥·bl>Ñkx¥Ùb.ÙÈtX³ßl`…6¯JQä;†NÓc ±É.§&&àÕ3«¡À=»œÞigía!Ù5Lù¬z˜ûXUËP&×ÌñTn‡ôûH8Q¸¸¤Åeá^ÊAçhw:å|ÄmÙ®J1G$áÑeá³ƒY:û#½™ˆP±XÍ®ÈúTóÉD"¹Ôæ‘ šFbb÷{<aû›ä—ap@*êKƒU©Täžˆ´[rœ.›²s‰î¹$K•býw%!'rÒeS±ûs·ödËÚÖhŸk¦»¿ƒÜÀÒ…))5×9V}ÆjKëÒ¨á&³S¿UQNñË¨À¬)+pÈ2xRš*g©ÍNu]$Â#&@`j¥S™`Œ›ÔyÑý…)IJÇ¶‡Žip)¤<&MQØ’ÂIbkb&Æ¡ŠÆQ'ôU'ˆÍX+¬mŽXY·ªè<eÅ#ÂZ¡¬£P@Š€è$J€ Ûj!L	wÇ
c*—-?4#4\Š\ƒ"•ÃL}l]z:ºj“Ñˆl* V<ükYtáBc™OŠ)Î£¸º+2m( –’*(NÈrP2o³Ì“±ü¥m.<1N¬Ê­ü7™û…Õõˆ1Ø‡pK¡iqŠÒ29wbwAI–ÑaGç‘ÂS×@7`>9 ‹ÅfXfyeR‘¹ý :àc²ÑLÛœj ®‚LºFNµ®-Dn”TgJ_'ÿa"±ÀŽrQ^«
èÍ”ÒÑ¾fnšaÆ¡kÕÕþ\M©¤M'XBoðôã¼`ÂfT“ç²Ù+þ,ø‘!œ<Õ¦´¬"``¨ÖÉbb)ivY“Ë@Kxì§ãb°:'zˆ#Ã¦âK^T_X¶ÎmQ/[o%«èÂ“ŒôbCüpÔÙZHËWºŠÌA%–^­ŒŒÉ¢§q:•âÄ×t‚¤‘ÚtG²“é8x‚6ä„Øà8¼QœSj
2‚W•BJÓhûª	¼äÀ|!+…}îxÅ¾Y6kè’æ†T[Ã+Sm§+mxmPZ’‹>E‚OÕIËTÁÏÄóHš	¢•àeŽŸ‹©´oß˜—¸Ô?>®3ó@'ÌƒR9Ä3éWmŽ¨¹?‚E¦kšHÞÙŠ,Žœ[D6‚>×tµd-0‰¥>L.B£=7¬Õ}íj'Ì`·ðÎ4_tëÒ²ŽÙÏdjP1¹lj||¢N;¡:¤ c $F˜jlZv ÕÁ˜i¼ºâ˜´ÍˆÈºìFN³»ëéÔ•ÂV«k-,nuh®1‚ýÞÃóût3W?iù­PïM}©S¦–µ~Håì¦T†ÝŽüh'[WÅ†ý¸gÂòõU.·K]ß ‰ìÇ5¶¡Ùï¶¬øÉ×6hBã³ø<•ò:µ,GÓá$Ô÷Äp¤^©2—gÐ%Rt¦Z*héö5a/%»¼kþ‘	âfTü¤h*Ò4AK<ë×Ùu|wÊº Ñc	­Ç‘dR0ÄãœYxÌÈaùA!S²Täº:¶°Ñ5?Ò“¹èÂƒ’QÁÉÑ0Èðst¦ŽQó“ÇÜjF«[Ñm¥L¼—¢ƒd:ïzŠ[²X"%ù 	Kd”üšy7OH|jåµs§¯$Œe´ÀÖå°µ^Ýâ…$7¦:™\ñn¾W‚uL
]‰È:®VÇZ—Åýk¬®ÇÛCŠêE‡í9ÅüÖeT,"pf+p‘øqÎ®b|yÔRì0ÌûmäÞ½T0 ˜fÝEÈ‘­R€,“Þä‚-ô0ºczÙ³n,¤s†îœ8üKÆ^?¸>ŒÐÖåú°BÒ8Îb“Í+Q‹ÆêEÊÎ’ƒñ…>f”é¾Î„†0—±LŒàvüL=6\•„Ä¦),÷E·H¦XXÐD~&¸\b@µ4hBˆù?£« «  «š˜u1	ÂZ=Í½ŽTßžRšGR“íÎ±ñÌ¸rGnP¥g˜òuÅhL°†Ro‹7åÀ8#³3œPÚõ!ªE½Ù(dÃÇzg©öRèNÈþdæTÍÏÁkÍÚÝ–60æã%ß°¿ šA4¯¬
Î#ÿ>³9¨]Hà¾ŽçÇ®ïçbLñÃ¾|§ª“òáØè5»cPïú­ó»ld›6T‹[fÕS±™¸Ñ’if£s7îß‰JRïGP(ˆK˜µ,ÐiE„ILÅ:AË’ \Fl^<¤db÷¸eBÃ•ÞIp8“¸×Ýƒ®Ú:T»{ê]çà ³{ô£zµw€?¨ýƒ½:;u´Gß»ÿ~ÔÝ=RûÝƒ­££î¦zùcÐÙßßÞÚè¼ÜîªíÎ;¼9éß7ºûGêÝëî®ÚÃîßmvÕáQ_ØÚUï¶Ž¶v 7öö<ØúáõQðzo{³{@7TµatzQíwŽ¶º‡8·[›]wNªÖ9„i×Ô»­£×{oŽÌäƒ½WÐÉê¯[»›ÕÝ¢Žºÿ¾Ð=<„	@ß[;0ã.ü¸µ»±ýfæÒP/¡‡Ý½#µ½+ƒfG{ G“¶ºwœô¿Ó=Øx_;/·¶· ^x­Ö«­£]‚`×á™o¼Ùîûoö÷»-Å „N à[‡U°ì¿½é˜Ž ºÐÇNgw£‹c9k`›p¹êÇ½7È"`ÝÛ›PP]µÙ}ÕÝ8ÚzÛm`KæðÍNWà}xímµÛÝ€ùv~T‡Ýƒ·[‡ƒî~gë ¡´±wp€½ìí2=iqp¹qxlë¨e¦»ˆAÝ·ˆov·Ý{kE,Q>–`ÿºh'‚w[01Ü=ƒŠ£A¯À1~ÛS;{›[¯p[q6övßv<\¨ œ-Êv^î!`^ÂD¶h>0„îÛfg§óC÷ÐÁ3K¶êp¿»±…Àï€€ ÛªÝCX+n-<NTö{@ää}ÞÀA@ÜÕˆcã3w²Ëvì2Rªí½CÄÀ`³sÔQ4cø÷e[twPtÆ:oà¼a|fsøNàÖ.ï®—ŽøÖÁf áí«ÎÖö›ƒ"âáÈ{ Bì’ÐÙ	nqXo¸ùjëµñZ¶MyGùGõ¶âešu6ßnÑq”q`’[Xõ pdì{Úâ»EðJƒ‡¥$—yõ=¢g2b°áÐCd~oŠ|p¤­½ÑŸaŠÅ8y…+K|³Pá	¥Kqˆp€"atÁÐ)–paýŸTé)¼Ë1õ†)g‚bbËGº#!Ð¦u’§CÌŸ§ÂÉ,~ ŒŸÇCgî6G³¤^nM,ðaÓÙZ
?Sti1pûbY×Šà%íóŒíç5ßëÔ!q8×‘-ÿYÞ.«2Üñ É½>¤\Ø[‰u8ƒ\9-YÇ)å9æÀ¹Sñ¿LóBniC<#ù„kaàÞYÔM¨øÅâIà_Íâ]·‰¦Q¾OÂ¿ˆWß¬jüKZ7Ö—¤QŒXƒªC1ZñU§NÉ_Çn‘:¸4œ±y{¤ƒDÅÙDä„Ùó}-¹w#f@ò—X3ª†~Qbê‰ºëAIöÖÕßHý©™¦†Ê²˜EÔ8%¥ŽíºzÎ`jj»ÒU¶(›
r}à¤÷u7gý÷sJ'’®O²8 %4Å‰Ä@Þz!U‰´”µ¼QWßcuº0u‘êô½<î‘Ü×ªÃ6¼í^7÷{›O´>(.Îªö(Î•’ÃÜÓ/$ág¶ßÐjLÉ´`ã(8ýhÙO7­—5›V5 ì:ÍÝUgè^ÐI:¤³dÛÉUiQÕâr-²=3yµXAƒúÒÆOK¬8íª(ypg	^Ê
^‡k‚ØÃ<=\»0XMÖU£Ðáâµ‰lö#ëfw,uåœZd–¬²cäC¤¾?›LÆëíöÅÅEë4™¶Òì´­Ã=Ú/`BÝÃ¤·´	aÚIöo¾zœjÞ£/K¬…w…„cŒ\µ¹Œrìê¡e=t-Måôe+!Â#›rFéWZecaØ	Õmäb§nÁ^,\#)«ßË¸/®}KxÈ¥™	¦—‡{ÛoŽºÛ?ºšÌ3ÚSÙN5¹ýºñýâ~ËvW<Ï–u-†8&½ãM=ði6IÑÆ’ðÌ®wß -Kg—c47’»P™[õühæmÁ?}[½›éì„aïTjo@‚ˆql[š©‡F´XÉBëµÏ„»ÿðfËV?–khBS²5¨L€'éÇš‰›”)S¬)†ZÒ¨œëô#Ä^moAÐ7úEYbºP¿ÂÁ×­‘×+ q0.VÆ«Y7¾)ëŽVÌ¯ŒOÝ?8|³³s­$Khø@´js¸ñæm8¤ÁÂCÊ–Ã9”Æ˜|8ÒÍ-DÂÝ®6¶÷Rër'WÂ¡Ë!ˆe)ú1#¹ÖëR’í¸ì/åuâ%`0y¦È"ž	²9ÛŽ(®¢‰˜!åÎé\Û³ø]èX„	/À«»uÜ
dÃÀ²YÖ=ŒŠÂ~…·KêPÆFS:†ÐTnÅø,Q:Ÿ]¶/Î.› ææðt<lMFCØßý3~úi¯}Ðílît[£þWceeåÉ£G
ÿ}úä1ý»²Æßáóhíñ“§jõáÚ“ÕÕ‡Ož®=V+«W?ýZùJóñ>Sd)0•<æ¶ƒfƒÁœßy1ÊüûOò¹§öÞlâÅoQp„—=÷QC"¢­Üêèíf~ï&çÿûÿú‰ZÊ¥œd
¥.I¨2·-€úÑJªI”œÇ &°Ÿ	é0ì!ßÑwj'¦%:žmˆ|£RP£ÎÐŒÁDµÌñEàþuÈ°®ý„ËÃAö¶6½Ù–q¡{œx2Õ®SÖ.u½X €#R´qÅ èÃ#s;5WO2Oæ´>M×«ñg‹iš¡xGÑÝú‘º?A×;åÐ¤¤P%tk
ßÂìqSƒÑƒ3Ë-‡;uÐÙhP£¦XV†ª!uÎ'ÓÁÀúÛâÄ”õRÊ(0’v7r|èFšj.á7¿L%óÁƒtÚ‡Iµò³,}›w2ˆO§RˆJ.œdÅjšôÎØc˜q;®K»Àà†]1 Y2N=q|1§†¾x^J£ +>.R9Ÿ«×±wA‡Üì½ê´DÖyÕðü|Æ.QP‰¥!ïÊvœL?ª·;ÿûÿü¿aV8ÇÍ´÷=à(ÌEŒræã“oLÙ±)ï=Aôù0´Ëöá$‹&½3ß|0/uoË é8h »tï((“é¸°]6nÄ£#ÐgHÁ&£6:ÓeÉ,èî&‚ãX~Âmma"LŽ¬ü•EÓ»öRgpÖÇ ,‡÷&úÿñ8ý %øý+t·þ_mõü{ÜëçÑÏª=]Ymó•¢íò`ªy¬­¬>m®®6W¯>Z_ûãúã?*ô­ã-Âl˜¨xuYü´j¥µ*…7fõ¶µûjO­S "†ÖrVÙˆ‰‡u°îêÜ—ßä|ty"?5ÏÎ†ÿž¨ï÷àØnw_v»/~VsûSðFlÞØÚ…ïn˜WjŽÌo¯÷vœç/áù›Mø¾ñ×7ûòxî@fÑ<«´ÐÑ‡Ö¬–Iî¡Ô|Õuw>»;¹WïCï*~‹z+ÀÔíÍy®65¥i©dqDtÂì”*^´X¥›3Ô¢%dBuà¼ñ&ÀØæÇEkIõÎ‚kÑ9YîGƒ½{Kú×zkÑ}] UCk zÌºÀË.úŒž@üÚªO¨P´@”—ë©BŽ{06Óè´Å!ÕýÎ¢Ã€ éxk· q¤¦Îâˆ'£¤ÑÁP>Ð^mú¡^[4bÅ¹\0âIØû0çUcòO‹yPŸzÌ”èÝ³Y1¬ùqá)¯¢NV+Ì¾éÚ£¸ßF¸ëÇþ¾=ÝNO‰O®«öd4.ñ¸azŠL2¼Â™¢ç”n¹‹g
¬þ#=~/">þâÒÏ¼×<yð@×¼—˜–æ C3–‘áí~õÛs?PËZãØT™_ÜTÇ'4o‚%ôCí€Hß`ë
cðF¥|‚RKUIQrºYiƒôÑæÇ"^ðL´€Áòc¥„qŽ\¤ÐãÒ£>õ…›ýÇæÊZsõÉñêÊúãGë+o&¬¶VZ+Z"¹“Ño ¿Ì|y³éÆx:çápåsßx“ë°(ëe:‡3lR¥\isnO.«6ŸçEÌïBsH÷s³.¶÷~˜ÑÅjé¼w»GÇ{†o“·Ø¼°³YYô®aãåw¾ç±	gLCöö`ù©?kâ‘×Ø?C±½·™_ƒöö6ßlÍ„¿®Ø®oÍÛJéª=]¬®µÖZ«­‡­•ëtüjçÓù]tü—ÎÛNa¾Üqžµ°ýKÿÃjë­•ãÕ'ks{:Ü8ØÚ?:~õo»eÌ›MCçv)|‰2¬®Õcç¾¶AÎvk°ÐŒ)æf‡b<¿É—nŒ{½Ó]ýÖ¢£XõV™ÜbàÅ§©ú½kœ£ê¯G ®÷:§ï%Í Ži€Å€ë¼Ø9	O(K‘þjåy½Ñª…ãÉÛúëMºhov_uÞl»=ž.î°û‘
yRF
äÑ©F›Ûôzøn<’úIôm¥îÆç	ó†t;@¿$—)ˆò6ÖZçÿWB xß¦ÿð»Ç=âh]ÎÃâ÷c¾–Î{»£ÿ, (Æ'í Ne;Àò€CžŠýsØîwš‘ýÚÓê»OZ(6þ!4ÝŽÒÓ,Åp¿y0¹â	ÿs„ìp§5¾œÑ,¨<ÿ!Îøb˜ÃÓ|Ô’Úµ…ß5Íòqá@ $« <ôŠ¿ÀëÓZÑ-ÛŒãc¬%ÑÂs1ñ b!ö/QaêkŸÈCýâßõ5 ½4‹ÜNfIe›7ªÂh¢ß±@´Œ¤¬~Û.H(Y.Lõv½9ÂîÍ:Üg/&öTá·O6yòæzøMÉEi
ƒÕ¢67á¾Ó
Ñ/Kî©³¨÷Á‚„b#q0×uŽøŸTmé“nvU)¢VS??£´µ@)jÑ`#”\®Ú-ÝÖm¥T«ªü%H&ê¥ªÖ=8Ø; DftôtÐœ*ßÄüVÒgïÊ!<cçD@ÿÅGÏk-å,¡½ôI)|¶½·ÑÙ¦_Žw;8ˆGMk8€@ºæûàö½Îg¿fí|ý‰`†Ù)>kgé(ÒÍü6·_)ãÁUo©v¯)4Smã,÷„áœÐS¥^ÌÖ#(ÈO¢±”ýŒ­ é{;h:Ö/åŸ¶jé?Yp}ÐRÁ¶²)œˆæÅàfdÄˆðïS{`Ì«B˜fp•®âKI ì	˜{R$Ö4žwdè´ècs«£sÓÃ³LE’ U“Ã³4:×œ’E¯3êÜ»‡74:&#„u'ëÅ“ˆ|ŠAðòÒØ5h—»ÐnÓÜ±žk bË•ÆŒGušó¥q© *6.×Š†ç…;/b¹¹=7U*ôEìbáŽ´…›"ã*l`Ø—SÇ©êk[PÃö@¼	nšT›Åa¼•MùŽ9SÄí×ÈÞa=C6æµ8¡›k4Ÿ9V;
Ût
·|“Ÿ±Ñµ¸¹kBÄHuçêÜ“²q¶:Þt‘ 5´·¡XÞ¥‹ðâÄ$ù
ñÀÞ3Ø£^‘@s$¾g¶{á.+,mO+>Sªðù¬6#&-Ø@Ãfù£>Ÿ`CK¾Ýu¢qá‹’@Ó¤k*–ìãv…9AÔoÅö„;¶Ö_SßÏœÊ-HÔ®ÂÊåii¦r˜ô„Ð¼íí©ThÊøÒœü<ú oovöéqC\2ü÷áá¶2õ¾²È†ú#â‰z"eT¥@a‡©®žs6e3G/¼fdÑeÃ©ãÎêOåî	kÕ1Hiõõ_¡oB¥”¹Xý÷[j;µ¥ãJË€öKÆ‰\M‡ã«"ÿÁÚÄ< Œ$<µ	.Àjçª¸D{è»Y£¿<ã
zeié§»Z #îœ¾`ÛœIû+ëbþÏÀÄÃc/tTÜÎ¢áX-ŸÕmånl²{G4xNí'x³ ­h¡Ð@›&b%´Jk+ö]¹k-kgæV·Ÿ€„ûñX†Š Õ`]·<OÑ+¦ù™™Â¦co¤ú2@†Ì¸,¯Z~`¨fc1ZQXKO}}é%	šš·ÔfÔppöˆ³~LÛgª³÷
TY	Gz5Œ>R"’+îÔ©W/è‰˜Sw÷­z«™qPw‡Ì×ýp2'ê£š­ÍlXÍî*™žšÓôf¸!í:‘j©×OOÌ
œ/øµèr«\u…™
™ð+Æ‰ÍCWù¤¸›¤º_¿dh×yŽEM´xÊCC*œÛDËL¯ä*š™ÕÆüIÎŠnšœjI‚Ä*Oˆmx¦%WÞE–åË¤"¢S€þŽÉ3$w;õc–‰õ •"±È9V85â^1ô„& eaX‹\½Õ²¤ÉÆ}Èz_Ì¹zãËÒ™¥þâ•1°ÓÜ}ö‡æÐŒñæ@Óm›§¥w%Ó	uJ”¿êJ(¿]@wgDœïìU;¶BÍìì€xY7ÞÚ@[a¼§ˆYtÊ¨àH_yËÎWÈ‚?‹ÏÅ‰Àé„ƒÌš®»K³æKƒj'3Šøív ßyPüÁÔoX=(¶ñ‡šý©Þ
ŽÇÂ¡ôMQUë»Õ ‚ºUïlÓ©ð©J¥r¼½¹õŠÑ¦1Ó&¾8pûé9‘ëLÏmî² 4¨A8³8_xP'ä©ÒŒÁä÷MÂú…õ·îƒ’Ïê*¼°ÖzÈS¨tW®»ÊküèQá¿ÀïLTu•¡{^-7>¡…Æ.G©ˆ)+ÏlGñTÕÂì+Û*qa«•X1¾¦žôSšÁæÞNgk·ÆsO_{'3˜ýù¬Å`ýõ-’©jâ‰µÅPAÝ{ÆÇgŒgNÿ(Ðöæ©‰Î–çµgÔ ylUÍšÅT¼Ÿª¦Û†'Aú¬íC³c%‹ƒW²q|¸xp äŽ(¾^odRZÞZÅHú'¦ïÉ-á	ÖÖÄyT™•JVnP­ðîFÎ¿™Ìî ¦0›ÝÐV÷ÕC%2o:8ÞÞ:<ò;ØŽY¹òƒ]'áPæÉŒ/u^rGûï6_mmWÉ4ûúRp£ªêêi KŸ´œqÕöw||ÑoM>’±Àm¤óø{G¥±y|o$2}9‹ËMÍtÄáYó;²6µÅÝt÷Í«h‰[Ü)òtjl}ó:“]¬‚œ´u}ÐÅ’&r®:¬ºãIñ4åB¿¿þIaVp,¶&6Žã¤êècÃ­Û|s¶$P%¾ìAÚgi9™>bB¿~Ÿ_)°]œS?Ÿ!B*ún¯„9Kó	¯Ž"o³‡»ÍªáNÝºxÆA0ÚÜäòï%ßÊÏYrTgE,jd$Ä*%î9…¶ÙèVR £0Ç2ýR«…Ê ¸Ì“•‹‘ óŒ2¼ÜŒL}¯)ÅâX·7’lTµ®rHªûé¨Å%r9	Ã*Ñ`øm|{¡RÍ®VíSº—€î´ÒŒ!F×ì4Ê2,rlúœŠ»^Ÿ’ëˆÕlÇ€@3;Æß®×µ‹†Î¤?Ì™ôë³£kÂÓ¨‰%iÐ¢x¨á˜xnê~:"Øý»%w,È¹œVƒWœ—˜ç–áƒØãyœÎìKÇQ"ò„CtgRÐÏ&£·ªÃM™’“õ«ó¤îÖ¹úæÐ*m@
ýjšpa/rÃÉ—Òpÿßÿc	ør}]"]òÚ•‰4–ã±¾ßîîþpôú…,Ÿ~»èÃ_?¤Lc,’œ26ÿÿö¾u½mYpÿ®¾/ïÀ£dÆIÚ’x§¤õÇvÒžvbËNú’þ4¼€²bYÔˆ”{:û,ûccíy±­@¤(ËY±;DÏ86n…BP 6ŠLÃØ. î8ê‰Ø‹/µÂØhü
ÿNÇcn›
d
ï¿èEEƒ51$£~tœÆNàr‡›ñ"`ä¥ÄëhŠ‹¸þÿüç?3ƒmBš"5ÓæRÐlz¢»QìÑWKaþßÿîÇñ¯oHìÝ[ÔÚµµ)mñ¹ž4ÀÞgÑ¯?N£>žIÝ« óÓfr,ô¥€¹yF|>]ÅÄ26¿ûVb"÷dÇ"ôÆ¨}öåÑþK¬ðrkïÃ»—ôj÷S0õ`Š6\Ú¯˜X‘z¶§~€NY¬”ø ¥OI“ßâÍÌý°Ç'?	·fo"¹—6?~ç‰_IÐ¦ÆpMR£¢÷3œ‚ìKG{†ÓÂëX\ŠSAŽÊèŠÖNŸÉX­ôÕl‘˜“QúÂÆ‘µÂnðÞ9µÄNë'sH;B—b‚Œ‹Oó<„
Âü4çÑ'Á‚ 	N±S$§7Áß×#·7_x#‚g	Ú6gšŸŽÔMBŠÏù‡üDS%ÁdŽN˜|cúÛÖÎòýGIâ•#= `J#F>@l;©\¯@5Aläˆ)Ëa·±ØóÙ3ìE"ÜíÕº´Á”ÐöéT"±ã:rÉTJ¨‘Î¤
i'ÑÂŠ+uÒ3”jì9Ó>òŸÅ5´… !æÒ™Oà8ºYâ#.ÅÃ¸H¿½§Î>‹c”/T,GÃ¸çè'l7ˆ’õ>-;ê´AE8gÔASÖ
/Ú•ÊKé·íX/Ÿe§P 9žÀ±Š4XÑX=œ:è1}.ÒÜÔo@¥tâbiq9þ¤3b ¦þò®ð¨t¦Õåz:&p¨ºVÖA[âM/bnÖÂy.œRgA_ÛíK’Pi¿ÎÙªûjãjÿ?²¬+jìÿÇ°,ýÿ¨ºQúÿYEª$îa4æŒ½ \cÏ½¨\ï¢8åÕ#ÛžjÿR†ì-Äsê<–;gýŠs—NÝùÚ+ñuÝÿ|Æëá±}m,Øÿ¦fÍøÿ²,½Üÿ«HM™Ø,OÓulh¸Ï|¢hMÇ“µ–kižg(ŠçiÒÖ³öc–CZDi™MÏS§i(†F<Ílªž¯ëjËòMÙ’Gk§¶fºæúÄÔm[3G×m«©+fÓn*zÓ±lSv4µåé
k§vižkøšìª>q\Ûòà7ÓµÙk)2ñlÙu}Õ·ˆãµ¹}±‰¬¶¨
ÝS5Å×Ì–ã9á¹–ãË®¦4=CÇš…F-bkŠjÙ¾e†"·4Ýn¹†ëYŠæÂ|µ³©´Z¦ŸÀ“ô¾åyMÓoÙ¶MZ-Wµt_k*MÕm5¢ÂNÈ7.XÆ²¯ªšÖ$ÄvtÃoù¦­ÈŠ¬Ê¦ÙÒ¡[¶áûž«9´¢3<ÇRlËp]ÇƒjMÃ×=Ç±[mš¶ªªžê¨¶eÊBµ¼ÅÝíZ&hÐ¯4]EQT»ièŠmÀNoÚ–Ü$^KÖœV«¥MÑ[ª¡[Xw‘-š£(ŒÄhznËoYÄ°¡¦Èd©NSõ]ÙÖtÓTŒ,¬bs:CUMÃnúžæ«MCÖ}"ëMÍvÕ¦,.›2|öšž5k/dÍw]Ùw\Õõ4]3t³iËºeZŽÜ´L–çÃ¦š%Zñßh*ªa{°<†jê¤%X€k™ž®Ê¶©¨ªo›Î¼ñ¥"-FbúJÓôZ-MöÝp˜z€®˜-ö‰_ E°4\Ã 2@dŒÛÂwW³M¢¹¶*7S-ç;º:rD‹N_µMßW<ß™uSÖa»Øºa°~M×v9´â™¾)Ï Èã²slè0°DšKœxìjÛ¨êšçª°;ÍšO6uÙòfV¶€þV»-OöEw- ,¶­j¾íæû&˜}ªMU648}×€­ä 0bÀO]6š–GðVnv²6« ±m¨º¬©!ôÈõ}Ùo*ðWKn™ª%Û0ãvne­RÃÓŠk«+–N»ÕtœVÓT`á‰
ËäXØ‚d×%ú•p*2ÔR\ qŠîË8Õ•-†ÔTG†ýa[ºeç‘'“Š	èaè4O,Íné®b!…Ö >¼¶¨£ÉN~r©9®¬ô¸EnºhÇ@Ž,Í$„õqÙ‚Ê°Û|ÍPöŠÒ´\ Ò¤URAN‚ ê¡1#L-&Ñá4TTlÕmj:œ°.×³TËÑ\WUŠ¡Ê”ÄõD/~ÐS£e;MbjËUtËst³eÙÍœ3Š‰§¶ã¨~KöÜb˜j/ñ½“?!¦Ür)«ªKb·Î|Û".ðj°œ®i‘@¥3 Ø-¿©ÁÉ@Z¦ë™ÀQ´Ã65Ç¶8']·é)61æÌ«Öc—€=T¦ì¾÷h”W x€ÇÑžé®†dD5€etá$%p©H=d£¬ªô˜IÊpp‰÷Ça¤P;IW6L`Zˆn«-Îl¥Õ8@T€jË.P'ß.†©æaª”+±µ0RÄ ¦£#™"ãøÄoµSš-Ùö½&ðD7>Wâ6}¯åÚÄñ8§š–¬C³	¼Š¢š–îÂ¹Ä¹°¢õ„G§py´ÇÝzÓS1qü²M4¨Í¦jXìZÝtL (¾'üµ7z	0OA®×|Í3ÕjZM¹eëÀ–Éžâ¹@E€)Þ1d3«åg–öSÑ4Ëv‘hžnZ¶B`˜žjÙÚS»eZ…0y'ÙÉ?¾¨Ø¾‰W@¨v¨.1)««4uài€µ€6l¶D1:)jálÒõp²ÄÃ€_wm`í@ ºöM `ª	û·e:ÅÛJ‘{Ì»¡¡¼¦Ü4]ÃÒ"×‡íÚÂ“0¦èŠbë×^#zjÀƒº-C¦tÄÒ›°ÃdäÚ›vK>˜u±*$nÓTuÇõ`—ŽMˆ/Ë®B„¼ð-²o6-E¶eJ÷QþÜÝÙÜ~×Ý®hÉñlGçl±ß‚ƒøy¸cÍ ä÷'®—:›€Ík Y M¸2LzNq[µe¨'³ì½×Œo¼¾Q¡_HÈÏÜw(÷Æüû?”—Qþ‡¯@eÿÃÔþ‡dÜwÇ0}ãò‘³ì6Üÿèš¬àúï¯ë #Âúë–¦•÷?«HO¯©H¶øþô©”8ßÀÀ‡è²·X-ú8õW©Ë ž¿Úê¾€:]›ôÑ‹tMì0$’ÚZ—€ÍS¥7pÚDÎdÚï¯KÝóAtI&è¾²Ì£šh¥öŒ±,|ß ñaø÷nD|´ wàÒó€„/ÐäÕÙ½øß#>~¼+‡ÚÛÞ *®·PÀ‰›FwuY«+MøBã¹_h7÷§ŒçÉÊRK)nå,ê&âp8Ÿc˜‚a6c¦†ø.šZP#œLbª64@ ö†oƒZXü@PIžáXŸÞìïÖ´ºüÝRñ-ÆÀ[@G£êE,r2æ!5†Â/ÔblNÐöÞ.µƒµØ»]ÎÍÏm ½"8&ŽÉ‹:÷Ô§~jCJ>#ã8`Vn±Sjæ—mœBãåy,Â4¦´ƒ &„é/xÜ¥+T?KuÆ}épˆ‚KnXc—Ë™Ë‰:kó0~óŽŽ›Åç|¾ð¨Ûž'(I-Óø9wf÷™žãînoó¨{¸÷vç×aô)+µãËZgæ„œu2Ê}˜Ð·yn¿™±ºXÏØøåÝR˜3žLÔÑ¼
 Ð¡XÖ“C@Y æ)7æÍs>sÃZÖ¡§ÐµŒ:kaÿf3„‹v6TnP³&wD(¬Š`6s€ÙI|D‹ ›·u)¼Y*ZLQZtÖ•¬èè$c«—k3ë«S"¼Y°"<äôÜœ‘Ê•`ÑsåS
x+ 4‚kÛ£‹ˆ†gwHÅ*K[B+´¾T*ú·ÂþC)ÁÝ-åžî¥«ùEQ5%ÑÿPªÿa©fÉÿ¯"-m‹>B	`žðÙÿ¬³×Ü‘cìg*˜R‹OÁ²#ÏÑgY XçpG8Ág	Î¤a{0ŠU-órâh«Ü­|*e†[ôž¹]`·Gœ©ÕæMZÁíu1ŠìÏl.ßotÞ£ç©%N&Sçö»JgíãôïÛÏÒoÌ]aÌZ~ù]Z‹KºÞq¾¦lÓ—ô‹ÝÉÖcv^B§#øAL³‡<›{|¹NK'ßTäÀÍ`®SË_¡ìqaY¡Àp>0´äMKNÚå\ìü'îâ›€“¼#¨%ÇÙ ²cV3É¦“¸ón~·œ2–ØÜ{÷úºÂVâÍõ†,È
[;Éò&ÂÃ.„J‰ ¶¦Vs pó÷ è€“2®¨=&—èA°Žæð¿Ùƒ‰çƒJç2Ù¨Üôóö›*·Q!ÿ|qÙY£¿Ö(‡ód´¶T:èrëÏkF&c™®Bm3¨AU2ÔdúK„›€¡ÆêÏyo¸L’È¨_A©jÅF¤Âý€fÍS;k®'‰»ùûKá±NO¥š+åÕ%õ‡†GÎ£épøGMðjgRµ-íýTýO¨jØhK¯7vv··ž5IÞ3ÈÅpßo¶·Õï%êA´.Õh`e_úø\ú©6 æ U±µªôñ…TO£Hþã³=éÃŠËIïÆ¼¯?Ÿù³ýÃ…ƒ±æý§TóU±[[¬_þÝjSèœü'ÊºÂëÀ_¾BMa
.}© ÅãÛ“ØŸ\Ô¿”j‡€ßsÿ­Üù|VŸ6Ñýeº·ÀH|¼ìªô=¬RMJ'/&Òðtst\(äÌ-ÅZM‹Ç%:ž~Ê Z^P(O¾„òÇsË…†WE"—–¦¾”h…ªˆÜ¸5ªb)¤â³¥ 7S
‰úl)ÈKÍ–¾NvZ33æ…Ð‰Ä
»V‹ÍK%ºñ/È¤ÄQ´Æ®Õ¢	Óá~…qy[ï¤ª;ê¤®gÞRÃÕI•}#P.6±ãN;1	±FÛµ=ùŽvâ€k<#0>
ÑW>¨S	Â`Ðyq÷:Ð¾z8q„µIŽÙdJû MÎJ1ù6fŸè1”d2£Nü’CÆVlgëµaˆ!žê/¡sn0&{IÎÚ.ººÚÝÝ8ÜîlJXØJP¦5)T\ÊI¾§˜•œsÉ‡Ö…a4I²B–UÔŸpÈ‹ãÌ¾¤†Ìh='.„l la×RÏÐÓ1û0§™ùœÈZZXC¾z76˜ñyZÜ¬:53ªNÝ€€Ê)”ðf0R»tÄIg-cþ•¶,m|zúu;¡§öä"îÖâpí~S<ÿ–FÕC¾—¾]ÞcÞ6:kgƒäú¹Õ5v½÷úî,jy¯»šT¬ª½Ü6è¨–¡'ú&½ÿ54].ïW‘Êûß"Áhá^‹NÊÛàÅ(ð oƒçuðµ®¿Æõ™$=e.;pý¨Ÿ%þnb	ök	.²¨QÏÒxª"úŸZWÝß³Èþß’µXÿW15<ÿUË*Ïÿ•¤§”ÜÁmð|PÚY—ªxFb¾Êòiptd‚yZš×M2u–¹A/gâLƒe÷9ñ'³-8(¦’jAéuiolu··Ï57ß±R%H‚}·­Ùj¢™mR»Ù‚?î5Š@ªƒ«Kí@Ž+áp*Ô¥Ç<Þ´-YVð‡Ún·Ù ±;õ]Æ»÷»IJÅÆ‘KB.žñÿºÀÿËº†úß¦\ê¬$•úßïŸ7~˜¼ÿðbV½Ô /ù÷uöOÇ”ß/ÿüØSÎKÇ½´q}þß€sß¢úŸZyþ¯$•üÿ·ÍÿÃQøPìÕÒ5#Úÿšriÿ»’”Úõß_7_MVårýW‘rž¶î¥[¬?=ÿËõ¿ÿ”õlu?mÜbý«¤ÿ+I3®Èî¡›¯¿®–çÿjÒOrKmcü§ÈŠ•[C7JÿÏ+IO³Fúx[G¢HBQ<ÉO"§|é7|Øü_a&®ôû÷X|TùŸõ4³âÔQÈL+\jZ!* Pœùh:Æý‰}V*û‡?vžáÏö3ê®žðúnÛA9jÄqLÜ“ÔÊžÅ/±i„…Ä§ëwUÐö«J©ZMz/IñÈª¨Œ´õ¸¬XJ’êE%à†„`÷Û{¨©»X }*¬	“Åæ+¶ã‹cX°5Hµb¯a^QE8a0°¸â¤WV.µî¾µTìws¹m\÷ü×C±ôÿ…>yËóiÆ¯ß=´qýõ×eøòÿ¡\ÿûO×ó–{·6ðÀóiñú£ÇIIVeU³JþoééP ¹¶'Ë{t{rm€'·PXrŸ3
…;áÉÝ”ž\©ðd¾ZÀ“Y½€'yÅ€.SË½œžJd}ÉHòxäPö˜sù$¯%ÀàÜðYÿÉ¼wý%¯‡ø²ÿdYOûKí#ÆÅ$© çÜJÏ½Á„™'Ê/æx¯ÆÍróí¤á[ŽÉ+<p&Â`ÎbžùzkWã*3J­R»PÕ5©0(+Ä¹i¹Ø03[sX3A¯),ÈÍ–ÉÆŠŽË`n®\&îuRŽY.'%·vÞn¼Ë·ÊrÓR(`mÍ”b¹_èòeí™q_áÿk!Aøã
k5
ÿ5^‘}dW§N\‹££g”½Ñ‚.í]þkÆ~®*®C\2g+û%ÎzöxŸÚï±	óCáåø#5ÑÝF#úÎ+–bs—Cƒ“—LX
ÀC-¤íQ;žçÅ™»dèwýñ6É$ÂëDf^ˆÙLNG¨ëôéì´«OñïÜÑúaÃù¥FAm<	NÇBÆþ$cs$Ä9Œ·åR”Mž¬F¿vhƒ;´±€ÿ³4-ñÿ«j†‰ü_©ÿ½¢T²|–oò?d®ï×ih“èr8p1â)t­±&’?…Þ€Ìeü¶ìPÚÝÚy¼Ó„*‚ºÇ’yœ‹,Žì =Ék‡ÚS–oê“Q]zEðÏžøÒ‰=Qp´	{
ÀOíÑMÏ€`1/@H¥s2ñ )¹Ò;ôqÉ®¡¥8Þ&Ó#s^‘Ð=†MëL”6FCØÃ#‰à†ù#EÈ×K°1›a¾Xƒ8Ø–ÐÕ(”£¯8) 5šÁ8_CŽ'âa·ÝÐüäœ"@£¢:Ð‰) †h^Ûyä³„1ãOÒÇŽÎ©±à8ô,Ôá„`\ù\­¥M³7jKî¨Ïò:ü~€»yë]ˆ¿3¥í'•ÀùüÓæheP‰D{“þ>ˆ{Á(÷m\”ã\ŽÖ\¿OyÂš7ªá>Ï•&}{Ä}»ÚÃ¸­©À@¶¥w»?nŠúåpÿýùwÝ³éÀsþuZ­Ð?TGûÃ­ó7Þ/{}¥9>iŸœŸýúºámüüãÞöñÎû“ƒ]û¿†Ûgöû¡<Ù|syyþSc02tó}w4~óªñë¶M¦ƒÝ÷O*î¨- b˜ù‹&v{K¨›ˆZnfi±1çbmùÛ¶„\ Aq„ârZÁIt<	¦ýãü=ˆÚ’'|Z \’ì—þàŒŒÞQ¸èÁZ­Ó…<¢SËYÄ‘—ÙS·B£{ÚçØÏr£/¬5Š.§}ZþRîq4èÃQ§.x-øòIÄ4^ GJ#~úùÓNCÙ{óvüö»Ÿ>üü#9Ÿþô™8}ë¿üòKtiý:²>]ø[ÛÇ‡§;?þð÷ÿ5
Ï?}÷eDúÛ»Íó7û'Ÿ­ƒ‹Ö«w_Ç·îæé¿~z×ü—z 31MÑ8Ìþy%•È–›³ÁÒe æéŠ”Ÿ—¨ÙÀ^—`«ZfÌ»²ÀùöDq	t±G`ŒÌÕÞÕe&™—y€.ÐSUÍv‡sº‚Û}Xãáå‹Ë [úZx1rç| ã1¼$ÀŠ‹}:ý8Húó¿ÏŸ2üzÅ|!Ï_cZW`|kqSä/æNTìïg›Ì‘f0±¸»Û «fÏë/O#/8/FÄâpÔtìáŽAbyjçO³ÕoCòãíÉãO×By§6ÜÿŠ™Øÿ*²JßÿtK-ïV‘Ê÷?±ÏÙË Âðu®‚Tù:WAXu@ßÿàP¹Œøë¿ Š]3>÷è´O§¯Ï^Ç¼™LG^ÂÙcð“ÞÂPÜ†}Œ4Š¯‰ì©Ÿ<1Î@¢¾eÓ–Þô}ÊU Èg…ŽMñ0d—>™ªòèN}D‹½_ÜÉî˜¢$]°0Ç,9¸?£ß&.„O‚É„œDRŸPÜƒ)àà1•ð(ŠÐýM_¥kÂ[ŠÞúÕ¥*?1ì@9qïCŠrP(£€…xGÄ•´ÕÆDðh<Bˆèèñ«EëRˆ~3(Œ âé±ÀY—|>wO}¹+»FJîvª`ñPQÕ™"ø®×©æ|¾ƒ¼àMÝ1^Qëj]©~‹u…—A¼òð¼âoìÑ­Ð£|ÞQú …ÝKAå€ô¨Ÿ]¡Ÿñcc±Çj’ëzËE¾Œäñ°ƒv‘Ù4šÌ•ívw;hF™Ë>ØÞï MeÊÍþwOÌÍnÞ%ä[
Œ÷¶»÷úðÃÆÁv~ÙÂÀ0¢Uã,Å‰ÆL­Æ¦‚ªñß_ª Üë·2ÅüÓó‚R‡ï·2¥¢3¯;1ÞII]½GwŠ}»&¥`Q°y&{îðöDBxóeúê±|•Tüiû—îáÞÁöQîÓI8bÖ¯Ù|õ±Ðûw;›?á>èTãßÒá"Ô*üHÆôcFiãøüÞyö<y|ÏJüAµžÅZ/ðì}J`Ù¥C•+”j&We¹j6Wc¹ZU”ó`gÜ§KÑì!¥kÆõ¾“¸@þÓTþƒ:}ÿ7KýÏ•¤Rþûœ•ÿæì„‡¬À¥2ÿ¿ÿ/{…Ù˜†ðûñ¹eQ|eGnÁcþO™¡xÓ7(ÔàÍmâEé+?õ5U<kx_:ÛÜ”Z–Á¸©L(%'~Ù 7QP˜­VÜ¯kC>:¨[ç¢ËJ˜³B*à¦ZTO—K2Äêtê¸PJ¢·ìãWÒEŒ¤ÌTÀá5$øú‚¢c•¡ÀSw±œ'¥1‰÷„¡¯vÞÌ……xWeÄxÜÅ°¸ÞnŒ½wQÝMôv`>ÕÝ%ªäÆø-ç¦åÒÕË¥¹L}—•Ýð<Î3ŸH]ú*R¥Ú½sÝ7PI–=-R³¨ØÆ1fÕzgBbªôr¥Vì:ÏAteñ&²ó‘E°Ìƒþ¢!&”üúÌ+ßq˜3ÊºgdâÀ1ÿ™„I”ŽáÈ@p±†u~Åÿ¤OS×äÿï¤¼€ÿWÝHùùE5Kûÿ•¤’ÿû|þÿ¡«³3HÚæ*RÈøçU¥‘Í¿±bð±¨T~$ì8WtŠU8X#èt±-1¶dÉÇÝÃ:ðÊ”I³ç¿Öc›®‡zZ=nu§À…ößºœžÿê(ŠRÞÿ­$•ç¿Øçüù_¼öñ/\ ¢Ó Ökih{\$}rÃfŠŽªñ8Ê°Â•>ðÇàcUÈÜñ}
ûD5&3Q—6Fpøñf 1.ChâÎO®.I}¦âH¢ò>î.},ïãî÷>no	$lš}æ¸úþîæ®{·µØ,•ëÂ¾¿²Ç‹îpÔ¼0…“’Ì	#‹@ˆd#1‚w‡S¼š@—èMÜóô‡ª°ïlQmj‘¦üø²¨èŽ«‹”åŽC|Ìè®h†ÿS•2¸Ä(Öa¤Ü³þ¯f¥ößŠ¥Êøþ«•öß«Iÿ·¼Cæ6Üß-˜¿¥v8Ãú)jOˆÕÝ³=îµNgé!|ÿ$Û—«í/Ec.œÐÁäØ½›sRó©¥®ŒVú‘qJØEPê8pfÁN•€Y¤ƒŒCy/±ñå±G×æŽxŒšªfâcÜ¢ûÜù(ƒ% ñ<¦ã¦<Ç5Ÿ¯ñ(Q¤<SBs3eÔÂ2jÚ£+¯ý¦(<ØÞŸ……¹I±«_¯ÅtUx©ôÌÍ,²Ž©\E6]þ$8e¿«ÕEOq"<¡™ö.×e¾b0þ&ç	ß)l0â(Å:Ãêd>ä*r—>‚GŸ
÷tÌZõÓõ¬ÆN‚®zÞ«owâ3ß¬;žÊM&vz4¥Úq<ÐÐ83ŽÂ/»ÇKã¯Ë8ÎòjžÿSWÊÿ)ãÿô’ÿ[E*ù?Þá’ÿ+ù?ÚxÉÿ•üßçÿTÿS–Éÿ)·àÿÔ?#ÿ§|³üßœ÷ß»(€-àÿ(¿”‰ÿ¢b  ’ÿ[EšYE+d}´;‹ü?ÈFªÿ‡së¯é%ÿ¿’Tòÿ¼ÃYþþ&xøüìm†õ§ÎÐuÛéLŒ÷¬+·wG‡œðB¿—²Äƒ“%´Â2ÚŸD– ³–•#éAŠ¸á¸V½¿ÌÛˆ¥%+?(9Î™Ys(€Âl@Õ;¥€o¦—.¼´ZZ½´Z ZÌ¾Ðc\(tïN'DØ=JQõê:j±èS(G$òÐ‚ÄÄˆ[È”ÚC’)µR¦|Ä2e™OºVü‡û}ÿ±d#ÿ¥jÔÿƒn–òÿJR©ÿ-öya0ˆÇ¥ü6IßÐ¥Ãœ¨·uèPoÔ5Ü9zo˜TèÎ¡Ô ¿CKòœy„J²Çc,œô%0¨”×ëíot»ö¶¾ÄÁ¤ŸTX@M‚bøýüÛf|/yËÃvž=>S¢nÀ¦Ü]§ÒPPªy®TÝ¨ýj×.åZ«
™~0ô¤Ú¹¤ÈðÇ1u«$åE
ûúôôiòIŸHMé¯…u	«R§#½ü€ýþ2›ÀóYÐdI¿g†—ìB&³¡u 2)½¥ûC»èŠ{2°¥ÎÀËVu€Vœ¤Yfû
Øƒ·gá¯Ã.ŠC†F}ØbB[þ€ýî#Þ |ÇýRaáo{ÔÝ£t4¢Û\°ÇéR7Ý@©|H·Øæi;Æ©=S [ÿA€Ï"4´Œ<ên|‘æTÛÈBÇjau¹Ó’®$ s~—”+°‚@”GF]á§Mù4˜k·÷ùë»ë8é¼ÓtZ’F¸‚5zTo®7›å»«Y²7XoŒâ9ÇwËM\Ú”nkn™J+þ?ešÕÿÕòú¿wyú§éFú¿,þ{©ÿ»¢T¾ÿó—ú¿é]¿Ôÿ-ßì¿©7ûò­¶|«}ú¿üfˆ}xZ_,ƒÇXÄÿé†™ð¦&K²bi²Vò«HË:7ó,ßÎÈ&ðÞðò‡E÷ðè0á×äöòÌÇx Ý·€ñ«eð¬º¢Öe=ÇàÍáî¢€wV¢•¶‚S{ðH8º­©Ya&R"	öuV#r}gqàŸŠGç¼GY:š:P«ÎËÖû$z¾¶µ÷vcçx´¶.U))í±zÕ1€1^Ø\ Ï+Ð˜ÊJƒU	«Ò_$¡/*ôêÑÄ£èy*¿`‡Z²¬T_Ä•Ãp×¿ªr·»+ÔWÓúôBvÞpÒ»n¬xNXÚ[M:Ž‘¾âºÕì3 ðG•ñ;´Æn]ÎEýö—ð÷µÜd|Ÿ+¾OóLq\€´8»lßOæ0-žÎn¾4^I²ùÒ|:Ó
Géü‚ÇùKK'OYsJãŒAi@UN>ìvcbÀr(}`9ÏÙxwÎé$S-ÌÃzæ=¥xÒ9aÕÒù¸ªbŠˆ™y¹ª"ÎÔ;as¥ó³¨V:k™yZWõµOëå§YûŸùW·mã&ö?Š¦0ûŸÒÿçJRyÿÇ;üç¹ÿ+íWYÞ%>Ô»Ä?·/[Ùÿ¨Üþ'v3PÚÿÜýOéS¢¼S^t|mfµLKO³òŸÜc´]ä€ï7þ«e¤ñ1þ«VÞÿ¯$•òïpVþ›³	ð7ÀØ
ö01­qâÃ9Ì)ƒ¸H¤ò®ò&¥÷
y†(ÿ<)ù‚3ô|f¨ —ÌÀ$½b"ëe4¡3â^ª}#÷3ùŠ[P´—ûæ~é:ÝDô»ºVFøCUdXþ3žÿËW m€ˆ3ÞRî«! Á±€ã‚EËKly‘-Ž‡!µÍÌÜ~?:ÑíZöÿhqs!ÿ/ñ_U…òÿVÉÿ¯$•&ÿ‹Lþù²Ñ?³ŽG ƒ4ÒëOb„×ÔúÿMq10ÛŒ¡|bý”3+šu øÁ°OFS.ÓüÍâ´JƒSÞ3àÞ	Æn#ÑeTŸ5ÏÃŠfý5ô·j	3+þQÿœ1Ää™IFÁÅûÃ™Š4Õ€˜»£Nj¯ÉÔÖ&@×?Aý˜ƒ­ýŒöÓs`À8kýaàØÃš+Î’ùñÜ†ˆ$ä¯‡¤kÍ„Àù=qqbj9¶ÏÁ¤m».G¥ƒ;ôqÉ®I[[Ì2=ü1ç)ˆš3‘	6'BÄ](¾³J ¬F=r$8èß:Ñf¬F÷ŠG†½ Ú£_øŽá“×¥Ó)¡›7û+@÷8Tƒ‰I›»k!ì8÷'PZjàK7åR‡ˆŽ¨¨	ˆM‚aVÊ’I‚êÈyß¶;hWŸÃaÛ'¯ÐùXUêj½©ËuEÑÃ¬+u½Þ”ÕXÿ9·î I¿—l˜Ìê†£úWôÄ <J&§î§ŽOoEb½üXýÝàü9PxÂGúî hã
[§›?¶¿Ór[ïBümf ò¢ºLüIÑ;SâÏ×ÀŸdæ—‚@	´Åô ,sgùÿÂðîw’ úÿÒÕ”ÿ·0þ‹¢ZfÉÿ¯"•ü.äóäÈ@8ù’ÀÙÀNyä^ôÿ‡Ì÷Ïeû¯Íõß†é/yþÕóüoíÁPú1¹¼.»ê#5ÌgÉ•«˜,Úi4†_ÐWP{¸ö/OY£1ÃfäÖöèRÒw¸È3¤÷d…¶ÙÀmÝ¤Í›!
öe Ÿx!Ù¼K7hl0:³‡¯fó^C»£Èþ\ÜNfÌ[Ì‹”¸úÚ§½`Ç†j¬k™vysÛ’ƒâq(U±“”¤Ûh—€Ûè/uîhì¡…w–¸8âÞ‚I®cI~¦oi.ëÞƒ–ôîMü=é 2®	P@ç‰íFÀÙB[ípLÜ=l×zy)Ž')Î¶BÛŽí¶¾>šžÎ¸mm=®©®Ï~ã9lÐïÈ”äçŽ	càˆ2bD|ô„[ä×§piöÂÈ2ÁãªJ QdÂéiï’Q?:®½BWz“Ê¥÷q‰Âú	¶§¢‡P”» J€ÄhxÄ(rJÚÕ.>‰{R÷Çš’é$ìß“`Õ<¾ÚrXôÙ
Lì›é(jk³xˆ=«‰+ŽŒâ¡XööP:¬>i[–e¿xe›äóxÀ7ê`XÓÙ6sur-×&ä_S8Ï@¶šNà¸Hg†uéæûh>JE <‚0uk„:¤õÝ£n…Q÷,lýÁ$ƒ>'òYâ>À“xŽ<}§ùX7ë‡vgä.ÉgøÀ‘„¡5Ï{ä3g—j5ÁQf`X‚“A…éø+;¦ |-º“6Œ <º˜÷Ð;D®iÞ÷pêÀÑ
glR ³Ù11p“LVƒöèoÈaþÀ¸ƒ—è0¤­WÏIvt$YˆÂá1p¨ý™á°Ñ×­ÃxæËú«:Þý÷ÿ‰oƒö?«ñ0.ÊôàSzÿüø$ˆP
õÔdyim,¸ÿQ-+öÿn0ÿ_Š©)jyÿ³ŠTê|Æ—€óT½s7Þ™RFjc^©Q„F7¨Û©†`þÚ†{Ô*;oØAjDßœ14˜Ì6èûsŒt3l°‚:ü~“ZBFÍØýQF÷PnZUtMAëþ›¹cžJè­Azs°w´OsÜ`|¼àÈ,ä§ÈR…ÌG9!'Ãúëé Ä›Šà„þÅÐ¶c±Oöçø¢Ž!¿­|©Üvž\`qN8bÜt¸[o»Ûg°AA'°«€òF5‚ßn<…Ô—tÝ;ëHÃ\r%˜¶Ó`ÔðœpÂÎ¼¤ßn·W,[º ”þÏ=ÿ—xÆ,8ÿKQ“óß´,8ÿË0ÊóiiÔ’ÓÌ’(¹€Îÿçv÷ÞôPaç¤çØîÉtLIs&Ÿ|F|žÍgÊÄ3ùdt¶€¼/¢æ†@Íeùèùíöÿ\úË¿$³þËz*ÿ)èÿÏ„ ¤ÿ«H¥üWRþ’òwðÏMùYõ¿ —ÍúÓ´€þk²Jý¿šŠ¢™º‰÷º%—þ¿V’Õ~Lt{vÔ§À‘^—tú^éô2!±«,ÉŸ‡#ùRàSÉÉt„Ïƒ±Và Ë’Ò’^ÂhØL´W¤‡Z(
Px,Õ"éõÑî®T;Eäÿ{0±êî±ô8Â¾«?üU©,uf<{ 3¹úni¯n~ÒÙ‘×Õum]_7ÖÍëÍÓÎ»Íƒí·Ûï7¾Ît1î`%S¤ªtŠ^ÎÎ©àÄ,š‰¯}*•iU)åÿ0˜ßù0äžÿCæ¨})m,âÿÌDþ×uÓÔÑÿ¿b•ï¿+I÷&ÿ?à  ØWäÉjŒlK3h%C¹žå%%;’rìä¬“¹U—­º”ç•ºœgFÀ?‰’}÷-÷ÔÊ¬!Lb8¼€~œºÑ0vÑÃ`QÒadÌ+˜Å47'Áÿl)¦iwlÞ¨'ñX'³áT3Ðfb«rÝzé9íé‹º´á}‚=H5 Ö¥þ$ Ž;ÅK P·ùñ‘±¤i¤AT¯<Í”¦öp”aä_«¹ùN½@rÇ³Ë.5¦á¤18>Lþo#× ÷½Bá³š.OËrSÒr8zØn8]¿W_ÔLè]$B•NíÑÔ^	<¤•ƒÆ7‡¬\ŠB7î`å7¤¿W¶C|h¨ƒÁÙáŒgåƒ=ŠÂÎˆDçÁä¤Îl*+~D&ùL©ò'Ù¿W/Æ¤€(
ªê¢­låîXúÛ¨2Ùñ™‡íÊögâRü›ýÖ (ö8»èÏ}­±ÂÁ¸ ,²´ˆ8bñÃÁ)	¦Q—¸M–+ÐÌÈ³'ÞÞ4O£ ¬Äwn0
è~üu{2	&ù0fNB~§3E¼WÓé0PÜxjþQ²ü» ì¹€«wuú"¤Eþ_TËHù?ù?Ó2JûÏ•¤òýG¸GÌàþ½TÄ;Dn›ÀŸƒ{–çõ(G¿p?]Ã	¨V˜Fd.c:Iî#†C~,ùØÄ+vž~+'pcJ­Ä–|)™0¢.™àtpy[Ú+ØFçÒE0¶êB¢6Á)ICSáeêÿGuh˜¸!xí …Ó¡'‚ØiiDPÑž\@Ýh-„ÙDM5´óõÐq 6†|]ÜV†§àøÓVx,‘~fYª£KÙÞx ÖY›‡Ç$‹lŒI‘8úôø7X:øtö™=Ò…–Ñ8†ÁÃ.Ev_¢~Ývw{›GÝÃ½·;¿nîì½©€•ÚÂp Â):dæ„Ü;ØØÜÝ¦—f±ÜÁ"a;\ÈÁ~¦âÈz¼Cœ¥ÆT–öxÌuL~'È2)L÷• …%À¶67f€! TFÂÑ:ÛëÉMãzöå8L %ñh…®%®Lçö/îL#sÉ¼ùÓÑ~<n*¿1^“W…º™ÁE ³“Ø8xÞœÛ"‚~ýöCþV )k‹ðþ±ñ~CìhÞ'@fév,-¿	§K‰ædÔD=#”dÍk3¾Ö¥vE¨µÃÑÃÍ+à!oÇ‹ë…
T«I[¥ŒP‚lzÎ‡#W–¶„ ¯¥RÒ¿nðÊkê»§,ÿÏ	p}Ž—ØÆþ_V4Æÿ«–®™šIõÍ’ÿ_IúmûÝ›wÛ¿WH8†“°×ê÷ÌqRG©Ëì¿Êoo¶ßmìlþ^énoìþÒ;ÚZ½Ýí½ßÙè½ý…ÃîÑ>úÛèøöpiúƒeº¿T$ÿ/Qô§iÁþ·%‰ÿ [¦L÷¿.—û©”ÿ³òÿCý73ÚŸ”NçÆYL{8°Cúv ¨äeE *×m%÷Âaá%Òà7|…^àSGë‹-¡¸L#éðýuÆ0:û†î–yƒLwämAQLzŸ,ÛÍÆÚ¥^{Ød¾ß8è¼·‡S²ÄÎrõ–ý®ÒYû8ýûÇãöÇó†ô[.rÄïÒZ\ÒõŽ;ð5•›¾¤_ìNÎK;s¶žpx”S„ì!ÏÞÝÛÜØýr–N¾©È›/zŒgr”Pö¸°¬P`8š¦%'ír®GvþSƒú˜ŒÀáßc!0©à!;–5“l:‰;ïæwËI!c‰Í½w¯¯;!l%Þ\oÈÂeÁÖÎA²¼ÉíÁ~6r(%Øþ™zx›€œ »`“J®d"…cr	4ÁM÷YŸ	œ=˜x>¨t.“º”÷f[óÊÊ(ùç‹ËÎýµF)<(£µ¥B;Üñ)E·Ýcz›_êT0w€zéövwº‡_*’ävÓ€ÕŸ:Õº$ìP~•ÀÕÏøíà³Aµâ#Ra•p×¯¹^>rÛùkI¡ã¸°Ó¯Cúµ*Rªðµ=˜-ýÊ”Â-4[
r3¥pGÍ–‚\(•*×ëÁpn¡dŸ¥Ý«K³M˜–R’™2º"égÛ™;íù¢ƒÂ¢™BÂÔ%$(™µþ¸³Ö'Ÿ¨³\vUÚÃ{±ø|AuÅc2ÇY0U»›@†vwAàìlJCØmöPúƒžÉI¡zg?xRý%l7“Ž=‚¤@1'ù>a †Ñ$É
YV´pÈ‹xö:¡wÁÚxº¤LŠ-	áH&&²÷Y«òÕÈÀ¤ÕÉÍª|ëªOÈøf „())”ðf0˜}8ÅÄÙ è¬2Èƒ#²dªàÏé˜¡Å4AŠi>:sÒY;¥
F5ü]3RK‰£FU(ˆSˆÉÂ‚Í0f(u*ö$œž~ÝÎ “«éé©=¹ˆ»å…°O…0_en¼pb/Šbî¤Au˜?î¢p:Ïb,iŒÏ=ŒÏW>Gâ`2þ_¯ÎÚòT8íUtîþgb£,§œ»Ä6ÝÿBîÌý¯¢—÷?«Hƒz+MÜƒ5ïä^0>ðd	{}¦îÅ
¾vïËt×T¬ÿE£¥]/Øÿªÿ?Qÿ_ÓÊý¿’TÞÿæõ¿RÜŒ×À¬ûåmðuQ ¼^úmðµn¿Æí™$=•"Â®^/HKüÝdzìÖb2$p²{Õ1Ÿ9ÿAì^ö³ˆÿ×ôÔÿƒahÔÿƒ¥”çÿ*ÒSJòÙ‘BÏ<#”væ  ç$æ«,wkc_Â(È˜§¥yÝ$Sg™ÔYb’i°L!HròÉl†bÔñ6j‘Béuiolu··¥Øîæ»ökÏòÃM3û¿ÞÛÚ~½q´{Ø[ÿ¯©ý¯aQÿ_@Êý¿ŠTòÿÿŸÃýÊÿÏ± )f×oa’—¾I‹o•‡ÿó1æ;ÍûJ3çöpi.@œÿš•ÆÿV ïÿ-SÓÊó©ôÿÁŽþ´¿òð¿ƒ[ø ¹¡ ëÈ$ïD<Á+«pü‘Ìl«õ}º­Ü¿Ó¢µ¾_¿ÅØU¹××héÞ?®ý–@æÂ.ùÍw°Èˆxs?Þ?æ¶³·¿ýn«ÛKÌ!;UºÁÐ²ñÉ;Qê ëôSmT³A²·¤ñ]1óRóý×t Ý=ƒÌ­ŒóU@µ½kUš†óqõå9y`ÞEÿï€Ô”zÈ—×1c)<Æ¢ûÅÊÛÿYŠ\ú_Iz*=ÛñÚÒ³åÑ–ÝuPÒíü¥Pf?,÷JèÙ.pÈ›ô  "ÀV!Ã8Šð+’aÅ"ñV,ÃRÆ•l	oN¼‘” ºÈ\üç¹Ç‡é ˜¯ÛãðÂ»[ñ`‘<·õÓ×á`Ò¯xn[J2+BˆoÀÅIßÅþ*2_àØbÝQ‡žÈázlJ°Ï³Õs-¹ÃÍ`ÄA&	ä}ÀÙ?2û|#È_›ø•©Le*S™ÊT¦2•©Le*S™Êô¤ÿï·Pñ ˜ 