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
‹ Ï¿ÄZ ì½ÙzÛH–0X·ƒ§ˆ¢•eÑÍE’·*9íjZ¢ÓªÒÖ’lwþé,5D‚Ò$ÀHÉ*[ýÍÅ¼ÄÜÍ72ò?Éœ-6 $%YÎÊê6»:-‚XNœ8û9q'íß}åÏÊÊÊÓÇýû„ÿ]Y{ÄÿÊG­>\{ütþ÷ä©ZY…?ÿN=þÚÃÏ4Ÿ„L%O£¹í Ù`0çwY‡ù÷ŸäsûŸNûÇ°¼É4oåg_aŒùû¿öäñÊ#ÚÿG«>zúöÿÑÃµ'¿S+_a.¥Ïÿðý¿÷û6¢ÀI˜Ÿ÷Tóî>ÐÛQŸ‡ý8Wêå4“(ÏÕftÓñ(J&êêp:§ÙD-¿Ü<¬Ã;‡ateQœO²0Ï#µö§†úãêã5õÃ0œLN²ééiC^Ä“¿GÙ0Lúw>éÝpµø³®¼“?v¦“³4“'Ñ LÔ^t–cµœFy]åô¬•Ò³ Z½towûñ¤úmøq3œØq×VVÿØZyØZý#ürÇyœ&ôÍqšÓ<â¶/aëÔa/‹Ç5IÕiÿœE*N`âI/R<æ*‹&ÓDõÒ~„ëL'Q®Ç;:ƒ]Ê¹økÆÉðRMó¨¯i¦¢ä<ÎÒ„¶@–N'êèíf††ŸhŠØ4;;›LÆùz»}
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
2×)Æ¡n™ì¾/*Ì+»f§7.j£èæn¢p”ÜÅ‹|hæòõŠí¦[c×ýõ¬»>zß×­gûf2ûÝÎUÏå.æZ®rr×seëÚóÕ¸Á78^Fv—I]á,"§¿UZa‘ñÄ)ÞWàô4÷¢·ìTŠ.á/™L¡¯Es*6·Ab…×Wñ,óÉt0°þ[òÙÎ†¦\{U}×ŠC!™Ït . i¹Ýïž’©Î|¿@;L­GOÞJ×¾;µŠëxÌ¼hM>NªÏÇ»M¾üÆÝ•ì–NWvÍº1-wôg'Tn‚Y®£ªfcx<`çêl¸Ïl^>ï­ï]°½¸ö<fHWógSù’ô¥O¯wE†ÔGTct¥½œÐZî–+Þ%W¦Â3oÁ¥ÎlÎÊ·Û>›Ÿ~Úkí1æßÿÉ÷eÊýŸOŸ®>Q+««Ÿ<üzüµ'†Ÿÿá÷âþoomtw»_m€Ç“GfìÿêÊ£Ç«û¿öøé£o÷¿þUñùa÷ú¡»Û=èl«ý7/=” HPÕ>o%uðaC­ýIýešDj6;@0_fñéÙD-oÔé¡z•E‘:L“Œ^$-95ÀLz-õ½TÿäƒVš¶_ª{e—è	Žs¼™zO&˜œ€)ãK’óúxíF|‚I	ÐöúCÁvŒqhœ¾
oùæQ(?EŽÖPÐž31Î!6)+áp˜^àÍ˜³–KŸý,
G «a«#äj”ß:TûÓMßuÊõV°ìÍxQ "ÿl5È50p)È¬>ÄIŸ:A8ü·ô òV.÷•â=ïåwÇXüƒ§ùe
íGy|ŠáÛx!Ö/ÂK¾''†E+P˜>Ó=q(‰¨<¥^^¢¡ïæ4‚ÉÂÇÉ$Jú¼O§Ó0á{T1(ˆ‰’‰Jë±j×iŽšÍIjk‚(ºÑ•®\¤î,2Ø	Ú.§9ôSG5D¢9¨7åˆÚ`ÎšÈSŒœÍäŸá\Âñxˆ¾
G…u…É¥ì‚ÓÁ"é	ô'—4ÃnÆ9þ˜N1“ŠzÂß°‚–¬?‡%¤)aÂ;Ì_½ˆ0"ü€ÓA˜ù4ð'\_†—óRr5Æ±0Ìñ²÷I0Îb¬}£ö ûêÕúX£<ÐSjL- xO„«ƒBÎIäXšŸZ–íÎNý¡‡JÈÐ¥ºˆó³zÃ±Ú&0Š|ÝKûe„Ti‹-½\„˜õ<q^Å6›ááuÜm˜[g‡$hÅ	hžÞœÜ-Ý}Àä$ÝoŸR‡	g°†5ŸÏ_`rí‘½œv#‰†ã,:§tsÄq@€Zs‰{„‹à>ùEœg˜Ÿèt’Y¿Ount«ÑØé7â¦½(›„”†ˆÆòø$Æ“˜/ ÆF•»äB©Aá¨Ä@@ú~<@”\/÷ÓÂg¸hðˆÐ	2¯ð>âáh<„~çÍ ŸöÎì‰Ðqê×)^©D¡Ó­‘,v„bP‡F]Yîš”‰¡Ãd’óŠð]™W^B¬¾œ<ê¨€âaO‡®¡[ê1´VB?@3©üÐ…0[øV®ršâe@ÈÅMNr=:¢M@ˆÚýí*ôâ¤ÆÉEŠ×óõ`yµ®ðöôlB¼†y/ÇÛ\Äìåµ:ÀHã&9üÁi|®ñnq ®›¶ÛpwºkuD1»Î±gzU÷Ù&Ã$ï¾^Ñ_Z&,±t2ú‡õ¸¸z'²ˆÙ3ÏyÉ%¡ÍÚ£.-øÐÉ?˜AsØc;\ýç4Î"÷Hn·è$¤È>PÄY E¼‹<­˜è3ˆ#Ü
`;’ÍN6}rÎ%Q:ÍaYÈx&ˆîHbøÁŒGp;¤+%á—^FjÁëRaŠYÂC)‡ç#›&Ay…Ã/Ä}Â-8dá/v?=£&èï€ø ‡ „Òå)Qäé lä™(>ant„¹ p8ÑhÅ¨„1R€@ï/`’ì„Ã'*(3Ó2•_*SúW =Ã¹I,i8Á#‘özÓŒ“4ÈaLº”˜E#ž …ûS`Çsx‰IÜ£„ì1Rˆ<‚é_0^‘äG¬}š TÇ4Âù¤õ"bvg7¢kf€¥ˆÌ§g@"ÅÂÇÒX$øšÂñÒSmQ¡
Z™A¢0Ã¶|z‚vù#(‹,!—LÓlð÷>•¿@´Â”Ô(‘YAgr×=‘Ä”„^–• «Áw× G`çÞÀ¸JäUš[1¹)vªè„Ç	Î¯¡"Ð5ÙF`NÎÈÍˆp™‘–2$™Ç àFº‡uÜ#ª›¢M¨$ëÂaà4õ&š”=
WOØ0°²³Cq¦9æz:W9ËYÜ'¤Is¡ðý”Ø3
t4ÏÓ˜“žu–u‘4ãÆzB,ê„Xª7§|Æ€¸ÚÏ¶ö°úÂ@2WªæeK$–p¿,9Â=ÕÔ(ÐãÁ)¢2ÍyXG
ÐCc6ÎÅh
‚äÂw$~»snñ€’/Ç(w8t\Š¿ý0—ãnÌÖ…Žº;‡ª³»‰WGnnmííbã•–)Š‘Þ¯9<¦Æâ)í¯>EÍ9š)…sGF«¬±ÀÍÅ¿kã:}!tEjÈ×­ÒlBZ £QŒ@š¢(aþÁÌ;u íNe|3&™íIÖ°Sv)Î={¥º!&MX3ì÷aËsj®Ë­A«š¼å5Ú’šjj0³KÄ—ÆÁ|AW‰6iY2tÂs“ª¢9sÌ.TýpLÇ¿PñÙ|'Àò)jæg\r&’t+]Xá !¦:ŒÌNH€E=.	@ì±T"”>£ôwl@“‹s®‰;L¬&s
P>ˆµ^EÒ ýUÓ.“ì¶"`tT­—B_ÐŸÕQ,†Ó•˜1e³î©÷@ä(ùÙ OwxJ¡E8÷	MHK`þH\!œp5Št
ÇÜÞÑ@" ,#£GPæ‘GˆšÀàëD¨;ÅÉ wƒêÚÂ}êQ»Gp€LDÞ¦“¦Ùæg>ÐDR!EA<>çº´gû²NDàüÃ)0CCGŽ,Ób¡;Y¦r‰
(x‚&]„÷`L§T@<Jì¤š¹ÇØ…üôœÕ82Ñphv`tÑÏ)žy‘Ìˆ6D	{©ë ‘_ÔÚ”¨De- °C2Cà
¹W–"¾ˆŒe© 4Œê'ÓÐ×bjM’¸>B(Â´©–‚óÇl^ÂÙÄŽsñ ô $´H×Å¢Ñ3Á­Ú&y}7E‘#¯¢‘tÀ˜Çê®l^È#&±æ¨Ðæà»F\`åF)BýÂŒÌæ
3¶E·„Æ7zF0MbuL 4_¨Jº,+¸á.B^ˆED&‰Äm:Ð6'bÉP¥>¨_K˜5[á™’ÊìÃìxcŒñÐð­AÀaèzÆXp€“dG‹Äª(!qØé1‘eËkÂ Nì´ÁÊ.C6í Lb¨§Q‘‹„1ƒ_3èƒcµ¥ÄC·ª§æù5G­‰ªì’#Ð(„EÝ°¾œKçÉ¾ÅÇÒ=¬¬aL)íüÇîíÙBÙCj{èNCð¢¨f}µ¥f_w Éç‘	rL¿z£ÆÂ.ö Óµ@”©ÔÏ)ð<Lß’ ²¥ýK´^44()[¸½(w‰Htì{Óah¬m#Ã¤¿ixŠÆ„§ õmxÉÂX8J±~€ÕÛqÙDY…¼è.ì’zu’…HÔjÌ…*[1BÎ¨aÂ[Ã[©¢¨1éPWI^ël}¥·û	lÐÙ s½á)ùð Â«41fq£,!U²"@Í§9ñ“º¢ÚûhˆaY‹	«ˆèvÂ¢$(KãâÑTC3KøªŒ8´a<9(L[áIy‰¡(f(ÌK¬	á€› V˜EMÐ\
ƒ~œèRW!lŠ²)fDáé¥`ùh©ÑI|ÒÇF´ÇOãœ1¯§]BbÂÜ8À`¯ëÈ‘yL¸}¬ ý>o°\‚ÃÇÃ(Ój¨•ÖhÏíàÙcË§ˆÀÄ¾‡}j›aè†w3œÄ~Ÿ„T¤á0(Æ…R—Önh‹… Ï€çi×JdºNÃÞÜÁÈ&›jS“]*#<Áhå˜Ç€üéPT>+7ÀÖ¿N/Pkm˜âˆèúÌénïçAñ¸P‹Jæ$MY—àXD$÷„6*kÜÍD›s„N€*à“Lö…)ã©ìËþ±äÙ¶
–Öª}ëw	£§q¥OTCÓrô>WÙMþQ,öv©Z<\ìIê°±—î2	G\Õ'ÀBH·§'4¦Ê»Öôa!€ºV01Û5ÍNÑ›‡rDTÂ	ŽÑ4ÑJ,©»Œ
´-œ€H†	¥lŽqçàxÑB©kÀ«H\ÙÄïâûµ)7ËÉ –E¶Â¼[çH´±òØÞp7.þQ-Ò=¶Ï FË¸]ÙZë*eÚ7
	«‘ÐÅØ|J^¼~… EH©ÖBÚÛ”ÑûÚÀOö`”aç)+-Z–c¼BëP?plTò&šh“¤ß¹À!©d&Ÿ&Ãxc¾[Ó–²Ö'Ê)(- ¿ó®@ã„˜eàê¤°Ê÷“KÄåúî©¡NAˆGJ›]"–GÆ±x2ˆ,n;/®v’^€r|ñÊí&€r³O%MB <çáùsnAzréë„´Áäÿ 1yD¦qŒh¬ÔzÓr<( Ú¢/‘…k£Ïºf&`}C”BÙíóvku‘Ym€4ä“Ô³¡½0xj|g‚ct{ Ða4ež…ç|è€h“
çË² Q§9å°˜Qt»‘æeÔ>®ÛÕK–Åpä`ªö9OF»2ôè•*á¤=2» ÝÊb–Ï„C0„Q
‰t™#Ü`#æ476w’…Md©ìš"“¾	8´A'ÑY84ä|Ó#¶A ì±!âTtimluÞ#>2ZÁgû÷ØŸm–õíÂs´K}bT·öë,3‚7	W7ÜÄØaüì½8ëMGº.·)‚8‚;¾0p,Ž•£•S©Ca—Hˆ÷âAž¡†ØÉê
ys” äº$!Mðaéˆö{¼a¿+å|`_!x:À­š4e´c¯ÛrwSoó•ŠP…<uû†í£Ä¤MÌ°½³$¦§ÈL@·Éiaä…àØ«ÁtÜœê{¤°àS9Ò•!ÂVW5z·µ¿çŽ	÷¡Ï>¨µ¦¼¶¢6TõqõOz‚g*Èð¢JE†X"UÅ¤O–DâëÑkÈmÄ0¢
>­d_ðESyªKí³„M#ÿ$RÆƒ™Òã)ßdB†÷*ê€x&¨ ¶f½˜FHr{$$6žò4(Qf…âïÑƒ†+¡ š‰°,bdZq ©Æ7Õ»jé…,“cÎ©+)‘@ÒQøvE\’M|ÜÙ§š1–Á©½/À”•h–6-¨†&íÞ£–snßêø¬6¨¹Hv·Â¥&üù~î‰4Ì\m¦Ã´Xðà°ÄÓQ5™Nò1(üì”%ÿ°5c¡»©@~†˜¡½^âÌæ»ž”{	;†Vî]ÁäÃEcA_hBñ'¹Ð‚¢Å“sã³é‹þö¨¢1‹âB‚žZ§£RÎ~á	h®½ˆiÇ¥±¹=£iœÒáõÍ	Ÿ¨¶A«T[³‹Öp³‘ÝƒÃP¬‘¢ÂÔò72#VwSPôAÀ~8>!ŸŽ)Ó ™£6ÚàBSxì"ÛŽ–íD2~ë:ÚXçZúK‚ªHEÃ˜Ñ¹c‘½—Äö¢b.ÖjFDÐ[û¨
cÅÍ‰›†64wÙ:{èÂ:	¯lõCfß€]:FÆJ¤4Q> *.!v		)€íC¬°x“xOn5yÛ%X‚âªÔ	>.§æóÀmVÔÍS-*‹VH¶#Y=ÝP!Ò€ÆÄj3NMÚ«Û!-Ã‹ â—MØ±Ä9ž?|_/Š}†hK„v(+²ç"Íó(×‘¡õ‘: “‰J`ÐpÏcÕjÁ¸ÑgPy&¤khêA³vÙ‡(fEIÚhC¶ì4ÌúCŒ;AY›ƒ˜¸)›) ÊS\° Eïû:˜K­­:“á¥øì­…†‘3Õ†Îsì„íT‚Ë(R#°DÑsì¥Í\JõëúŽKLÍvµ ¤ˆ^œëÈ¨—™Ž—g±/yÌ«8’,ÈX¦%,K“É-3GažM]Ð*Œ‚’Å9|‡íðl04²‚/C1þ0ä5äÄÇµˆÑÎ)zo†"Õ¥ö„ÝD$8yqGž CôÝï&vBV}í!Õf7FèYA~b¬óTQÙE×ôy:œòE@!Õˆ$Äß<w¤sÔÂÓSDhôÛÆz¦D\Ù4w¼Ô–åËÌmBeÑŒ˜,GeÁ<Á)-õ_Â“ƒ“H‚$ÔŽ´__”^VdÐõ”ÊVµ}ä¥‡ÿéY›f/ä0BçH"r¥ëû´²‚îˆpç‰ËSwAXvú
6g/õ%cÃ™–æ@™øg2BÇ¡7‚ƒ	¸ÓÄ@(¢y•±Â`E‘†ñ)‰,câã°Ô3^Á˜N‚¨=ÀmHV#‡ÞÙeN2°„yQ'ËÖ>í´¨ÀÑzƒä½Ñ8LbmWb*Qmê‹?²´ªþ4cû™î;dFi“=@8K6ZPá€<ËÚÿ¡k™¨e¨¿',6Q}–ö&Xð’´Œ¿ºŒÂŒM·NæœŽýI“cæV‡X3d!“KlÔ0KqÝ;èÃ%SsqaÝ"i¸O&äò&azžÝ–9¼»9dF"GÍ4>6ªñB ¿>>4´‡”$wáâ£”£ÄjG/O	8a¸u)×§!òŒµ~±˜°
C’mX«¨ó°EîPGX°’°#IE±œà³C]}íÒÝ:‰èp6¬Œ!y.V«Ê	º2\8ÄPV¾Ž)ÎµQ‰Åi¯æ$™±:Š.uô` a#,QGÅ^´]Ùa¯ž>óPsxŒÉ+á'Z@|rbå¢ÿD´1:Î¼G~öÌž°tˆN¥åbÌ>ïGEK† µR;»>wÃE£bÏEˆ“ÌLè2=äÁ	¨—Á4cë c3*#'‰bà¥\ï
°¦–¹{Žg"†îÒ'¥y	w3Q‰GþññŽ†\æ‰Ð~™-CLˆÞ!Ø­5ç’K¼ñb—»[ \ŽåÛá¿¬£Š³ÖEúÖ:ŒqÃ'F pV™‡Ô+‡ZSA]vÎ„nïÐqÕ’Œd‘g@`ò¹¯7älàlµq“…4 &ŒÉj¡Ž£–Ø†aÖo#&³·9÷´É\NM4óÔLÉ.8Ž¢¬9I›ø/‡™?aêg'l/`G`DA%»
O¸ïÄ.C=[ ¼|1µÃmoµŽ‘°§FÌ7¢k;d¢/ªkÄ] ã£3AÔÐIáš=bñÀà‚½¤úˆááðœï@ÍÁ=1Žì¾ïM)‘B'	ñ¨‡!­ÑTM±ƒùtÄJ5ÑŠŽ‰t
&˜+J«†m!E5³Î–0ƒ‘6._Õ—†#à¸L#:Ká÷3¼\œW¹å€Úsl\ÞÄœ‡}Im *PÙPz£ 1l•s•Žœ;Zdh¤‡XÂþ¼Å6‚~:=™¦|³Xn½°5éðœá<ÏS
[$É#<ÕÙ6n•În°ì‰bµœ+T{ªæÊ‹«&—c’SŽ¢ô2aDxßÜ0Ìs'å£Q0Kh¿ñÔä6W¼: !¥WØ€›BÓ saô,y‹¢hÄÏõ}ôÏ¥™p”M#ŒŒY	öÂÌõf9}ÁÀI	¬\€L½?EišAÅW±É <ÝiB]“,€O`<	W$IˆcdÔd³Y$ŒBz-	¿Åq;¬ o¥¢¿ux{ÄœÁ,+íçÄ^ÔGÇ@CòÀtEëÑ%ƒ—	_lûÖ·ï¤:‘ã…¢Š´­²uCÇãyD
„¥÷9'4Ÿ-ÑEÞôÐ*äSUŒŠlFœ“8™"1ËÝDðµe<âD´M%1!5åÐEIa2À¦"^‡ækó$"5ß÷™ºé£P‚D·ž-)‘J×«‰¾h|8»õÜ¨œdÓ²èB×Æ9Ò>gnnfœ˜ÌC=”s%bdàZGmÒÉ ÞnbX‹DV;<Îˆv_5Ž&ÓxriäÒ€5h
UY®4oú3Ì‰9Â7„ÿ.ÇQPÉÂxÝ¾}[•L‰'‘«÷¬ë«YgSð§â@r-ÚÆÒC6€.ÉcÆ†{¤ì vä@¬½IÉ`ìBaïÒ=[œ”¤k–¼=ˆSàž	7s©átÈ¼ã`o§nÂ–Üù;zÔ¬¥—#ôÂ Ð…>enwZ¥GÙ‘ÂÑµ÷ˆš/¢àØñýÐ™µÇÆÀ!s–"»dðª!¨”Àc°9^Ô)2
£ …Ö	DÜïGd¹8‹’’
	U4˜@
íÎì#-‹8Š¸‘{ë:fê£‚¹œÇéñhqS) F9œi£ÂŒmT]ØËÒ<w;’9g©ÂÌ}ÖÒ0ä\¿gåááÌ$zÙØDX–…s Ë| ä¨à€øGT!fxvÀpPœÝ•F×š#i+hJ¹ €›NLt‹ã=“ZlêAëi k¿ÌQ¤ª5ç©up`:X¹¡7ˆã/]2oê´3ÄY‰ÇáŒ
N¤xÃ$â¤Ÿ,ÒlÏºÜZAõ$xäP<PâkÒaìÓî#pÌ'¹Ùtc›9™ÆVwY^,†Ég‡ÛúJ9OÕFœ.¬œ{À–o¥îÆÐ¿­¤{f}I”·þ¤@tToœ¾Ù]U]©äEN_Já!<ÇH/»z3bØXUƒË¥n §¢rÍ9«7Yô³p")JHæÈàƒN}[@n‰åX"ÀÓV3·+þ¢ôB¦ï¡'5+Xÿ¸Ð,Dz·êÖÙ@&–`Æô‘NQlˆïXì"¤1ù>)?îŽÜ‡ºÔÙ{+ã>ìh·5Ám¤Lú¦òè|ì¢ß‹Êè 8ŒcÁ{“Ê4»HY"8[fdç„eDÕø´è¾ës	…¦D?YçÇ¦$‘6©Ã/Ð¿…>/J“‰µalR:œYjŠA¹Z}LÄtõIqÏPÆÔNˆ“nJjKvnØ—MáqÌÏìr3a/ìep™Š4ºVlüa¦m‹%o+u"Wí“eÐ³{%•íxbgß«ãñ71o€)F÷òx0ìäiœåÖâ¬LßfÜÎ¨Q¡‹#˜µØ¢b«s tAi{¹c=4fžHhÊ/Ù¥ôë°9²ÙØr*Õ˜UâÆkNoh§?Ø½Oµ.Ü0:ºž°(ªcá‰ÎD¶BT]Ê.ãEý 7ÂHp[ð,¶9+—"	|r;îÀÅ4tx/¬Î®Ä)`¢·L,³ø—~ŒRçÜ[®ZÖY¶…m”È›º¾¨km‘õêŒ„mÓt©½ Œ4¬“K·pNªì×$ƒ€”R»˜‹ñK% Lv S¹B[1Ú„x6š'@¾CºVÓ|`BAI¼ÁµËIDûö™È[k`×ÌÕ ìSì’(=š»ÇjÏZO(¢*,ÉaÐjVÌ[ÈÊ¢8CU±K°õuz´e¡lRªFgæ˜•Ó!I€ÚŸQæÔ/&Úýþ_ÅX,Rú+wœòn>­S;Ï÷ÌãU³F½bØó)¼s	Ø™5×FAÓe1·4é9º­7à²P(˜ <Àæ&35(d@@; F…âú5$ø@Èë¤:
:¡g±G”œž ldüN) Ë9?iñD5´@%!ëâ¶)·NÀ“–¹†Æ#œé×ÂÜQžl@uý²\±# Ó ùþ±E
Jœ°=Âû |4“1bkAvNºiÈs¦&•Ã ©¨Š®¼×Éa%ßŒ˜ÊSx"±Š«j/çgYMd‘WEK§8'Þ^ RBáà¦ c1*b¶Bøm|æ‘­U6}¼v‚ÂHx§‹]¨ä!©ß•"âD$á,05#Ùïê˜ª‹ "ÙX®Fe‡²X†É ÊÊ°RŽô²ª’~0à‚?ˆ~bÍF¬¹Œ@ÃÆVIçt> Í›Ž7 ø,¹­ÕE®Cve¬aÈ	ÃOVTŸ¤šÁDv‚ò1Šî€n›Ô½$¤k1p€è¬©´$ý­$Žrg-Áâµ4xÇc–øÆÑI<Šl=?ÃÜ„Ö@×31FçÓ²|Z·z\Pœ®M:èMÅÁh{5ð}èÂ7ˆ˜ÎØ(Î<)6îYú€¿–Î˜oÈ1f={*bæ¡ñW*r 4Ez™…ß0ÐBq5åÓÜÒ|Å4¦¾È"gÆîKèÅÄÝjNÚ›úOŸH/MM…¼Ä+Ðª£Ãe½èe”ffj‘õo,—Ò@çÚã½¼æŒ¶Bº„Žt#\»ÌG
”ìs¸Šž(LÊòó"’löc'éÝ9”ÛTK)‡’5ŸDfñB„ÚÅsÒ™à3-™o""o°C›B%'Åò–z¥‡Ü d¤Ô|"ýðã*Â1ç…4ÌH2±Ysä‚;ÎÙ×-9[¯büJrhŒ35v8õ\J0mH@ ÉÂ°,JçžËI¸/JÊÍù¤‰Ó›é`4–/DÓ/ô§2”gF®•ïUñ¸«¦S¹#à–õK£L4$·a¤¶8Ë®p¡3Ÿ²+‚ä/°þYê¤C‹lÚçeÆ|që!ÊbdH·ÆX'Q5´â¡òdý?5–ø]ñ9ñ8œªÉ¯Ü’\,‚yeýïc©NŽº•Q·¡5<Ê}Œ¢ì”1Ç­÷EômÖq¤1Æ1ë¨­D•W'aîì$šp‘ËÀ]+ag‹]òÁ‘&œk`ÜQKÏu¾ûZØÙ~yŸ*2ö)‹’Í0ää-ˆtŸ¬«G–8+n™â™Fâñy8ÅyI–b1¯b¦£Î]‚A×sBq&(þNAý“BabIù3¬>0äª$6‹¾”§B…ÊµçMÒï³’,ŸòÞg	Ò^iQ
w|{b±ºn–^†Cñ”¥NgoÙ¹ç1«¶Ò¥»bºÌz‚f…‰äž^°09–šœÉûO©ôœ>˜R:ES	ºÏNµ8‚º4¶»o½ æJ@V8j¦a#©{8”úÇ#Šn«—[Ç±O’U²ºÚRûº¬¥.9—°Õ1Íj:ð¦ 2â™2]Ê	¨PãLÚ)LçU‹Ù·8)O çmšÛÚ„6B‡(È4á4º³6å÷L‰×ÒÃqÁ.^*¤oÞã OÔwªq8þT§ã†Zr}Ó°'Bì2RõõÓ†æX<Ü‚ÎŽ“ÀÂ\‚â®I	Ê!Óƒ"r¹s¤Å-VJ#@«Œ„Ú3ÍK9%r<Q°‚ ¤Ï~UJoÅØ|¢×ðJ²Å\²‘é°f¾ÙÀ
m^•:£Èw¦3Æ@c“]NMLÀ«g* WC{v9½ÓÎÚÂB²k˜òXõ0ö±ª–¡:M®™ã©Üé÷‘p¢ppIŠËÂ½”ƒÎÑîtÊùˆÛ²/\•bŽHÂ£ËÂg!²tö'Fz3¡b±š]‘õ©æ/’‰Dr©Í#4Ä:Åî÷xÂö7É/Ãà€TÔ—«R©È=i·ä8]6eçÝsI–*Åúï<JBNä¤Ë¦b÷çníÉ:—µ­Ñ>×L!w)¸¥S Sj®s¬úŒÕ–Ö¥QÃMf§~«¢œ
â+–QYSVàeð¤4UÎR›œê
ºH„FL.€ÀÔJ§2Á7©ó¢ûS’”ŽmÓàRHy0Lš¢°%…“ÄÖÄLŒC£Nè«N›±VXÚ±:²nUÑxÊŠG„µBYG¡€ÑI” A2¶ÕB˜îŽÆT.[~hFh¸)¸E*‡˜úØºôt0tÕ&£ÙT ¬xø×"²èÂ…Æ2#žSœGquWdÚP@-%UPœå dÞf™'cùKÛ\xbœ8X•[øo2÷1
«êc:'°á–BÓâ¤erîÄî‚’,£Ã0ŽÎ#„!§®nÀ|r@‹Í°Ì$òÊ¤"súAuÀÇd£™¶9Õ \™t7Œ j]Zˆ&Ü(©Î”¾NþÃ*:Dbå¢¼VÐ1š)-¤£}ÍÜ4ÃŒC×ª«ý¹šRI›N*°„.ÞàéÇyÁ„Í¨,&,Îe³Wü!Xð#C8yªMiX;EÀÀP5¬?’ÅÄRÒì²&—–ðØOÇÅþ`uNôG†7LÅ—¼¨¾°lÛ¢^¶ÞKVÑ)„'éÅ† ùá¨³µ–¯t™ƒJ,9$¼Z5“EOãt*Åˆ¯é%H	"µéŽd'ÓpðmÈ	±Áqx9¢8§Ô:d¯*…”¦ÑöU)xÉùBV
5úÜñŠ}³lÖÐ%Í©¶†W¦$ÚNW:ÚðÚ ´$}ŠŸª“–©‚Ÿ‰ç‘4D+Á;Ë?Siß¾1/q©|\gæN˜¥8rˆgÒ¯ÚQs‹:M;×4‘¼³X)8·ˆl}®é jÉZ`K}˜\„F{nX«ûÚÕN˜Ánái:¾è,Ö¥e³ŸÉÔ brÙÔøøDvBuHAÆ HŒ<0ÕØ´ì ªƒ1ÓxuÅ%0h›‘1tÙœ4fw×Ó©*…­V×ZXÜêÐ\cû½‡=æ÷éf®~:Òò[¡Þ›(úR§L-kýÊÙM©2»3ùÑN¶®$ŠúqÏ„åë!ª\n—º¾ Ù-ŽklC³ßmYñ“¯mÐ„Ægñy*åtjY¦ÃI¨ï‰áH½Re.Ï$ K¤èL1´TÐÒíkÂ^Jvy×ü#Ä;Ì¨øIÑT¤i"‚–xÖ'®³ëøî*”uA£Ç*Z#È¤`‰Ç9³ð˜‘ÃòƒB(¦d©Èuul4`£k~¤'sÑ…%£‚“£aá!æèL£æ'¹ÕŒV¶0¢ÛJ™x/E5ÈtÞõ·
4e±DJòA(–È(ù'47ònžøÔÊk5æN_I:Ëh­Ëak½ºÅ
8HnLu2¹âÝ }¯ê˜º‘t\­Žµ.‹û×X]#0Ž·‡Ô‹2ÛsŠù­Ë¨XDàÌVà"ñãœ]Åøò¨¥"Øa˜÷ÛÈ½{©`A0Íº‹#[¥ Y&½É[èatÆô²gÝXHçÝ98qø—
Œ½~p}¡­Ëõa…¤qœÅ&›W¢Õ‹”œ%â}Ì(Ò:|	a.5b™Áíø™4zl¸2*	ˆMSX:î‹n‘L±° ‰ü
Lp¹Ä€jiÐ„ó~FWVAV51ëb„µzš{©¾=¥4Ž¤&Ûcã™qåŽ(Ü: JÏ003äë Š3Ð˜`¥ÞoÊqFfg8¡´ëCT‹z³QÈ†õÎRí¥ÐýÉÌ/¨šŸƒ×šµ»3,m `ÌÇK¾a~A5ƒh_YœGþ}fsP»À}Ï]ßÏÅ˜â‡}ùNU&7äÃ±ÑkvÇ ¡ÞõZçwÙÈ6m¨·Ì"ª§b3q£%ÓÌFçnÜ¿?”¤ÞŽ P—0kY ÓŠ’˜Šu‚–%¸ŒØ ½xHÉÄîqË„†3*½“àp&q¯»]µu¨v÷Ô»ÎÁAg÷èGõjï Pû{?tvêh¾wÿý¨»{¤ö»;[GGÝMõòÇ ³¿¿½µÑy¹ÝUÛwxsÒ¿ot÷Ô»×Ý]µ‡Ý¿Û:ìªÃ£¾°µ«Þlmíþ@nìíÿx°õÃë£àõÞöf÷€n¨jÃèô¢Úïmuqo·6»îœT­sÓ®©w[G¯÷Þ™É{¯ “Õ_·v7ª»Euÿ}ÿ {x€¾·v`Æ]øqkwcûÍ&Ì¥¡^B»{Gj{VÍŽöŽ&muï8è§{°ñ¾v^nmo¼ðZ­W[G»0Á®Ã3ßx³Ý9ößìïv[ŠA À¶ÿª`Ø{Ó1t¡ÎîFÇrÖÀ6árÕ{oEÀº·7=   ºj³ûª»q´õ¶ÛÀ–0Ìá›®Àûð::ÛÛj·»óíü¨»o·6ÝýÎÖBicïà {ÙÛe4zÒâàrãðØÖQËL1vƒºo?Þìn#$ºÿöÖŠX¢|,Áþ;?t	ÐNï¶`b¸{1#Fƒ^,bü(¶§vö6·^á¶âlìí¾íþx¸P8[”í¼ÜCÀ¼„‰lÑ|`%Ü·ÍÎNç‡î¡ƒ8f —l7Ôá~wcÿ€ß¶T»‡°VÜZx ¨ì1ö€ÈÉû¼ƒ€¸«ÆÆgîd—íØe¤TÛ{‡ˆÁfç¨£hÆðïË.¶>èî èŒu66ÞÀyÃøÌæðœÀ­]Þ\/ñ­ƒÍ@2ÂÛW­í7EÄÃ‘÷ „Ø%! ³Üâ°ÞpóÕÖ+jãµl›òŽòê5lÅË.4ël¾Ý¢ã(ãÀ$·&°:êAàÈØ÷´Åw‹à•KI*.óê{DÏdÄ`Ã¡‡È6üÞùàH[{£>Ã‹pò
W–øf¡ÂJ—âá EÂè‚ S,áÂú?¨ÒSx!:;–cêSÎÅÄ–tGB Më$O‡˜?O…“Yü@=>‡ÎÜ+l&ŽfI½Ü ›XàÂ¦;³´~¦èÒbàöÅ²®ÀKÚç7ÚÏk¾×©C âp®#Zþ#²¼]Ve¹ãA’{}H¸°·ëp¹rZ<$²ŽSÊsÌs§â™æ…ÜÒ†xFò	×0ÂÀ½3²¨›0Pñ‹Å“À¿:›Å!ºnM£|Ÿ„¯¾YÕø—´n¬/I£±U‡b´â«N2’¿Ž	Ü";tpi8cóöH7‰Š³-(ˆÈ	³çûZrïFÌ€ä/±f:Uý¢ÄÔu!×ƒ’ì­«¿‘úS32M•e1‹¨qJJÛtõœÁÔÔv¥«lQ6äúÁIïëoÎúïç”N$]Ÿdq4@JhŠ‰¼õBªi)ky£®¾Çêt/`ê"Õé{/xÜ#¹¯U‡mxÛ½nî÷69žh}P\œ7TíQœ+%‡¹§_HÂÏl¾¡Õ˜’iÁÆQpúÑ²ŸnZ/k6­j Øuš»«ÎÐ½ “tHgÉ¶“«Ò¢>ªÅ5ä Zd{fòj±‚õ¥Ÿ–XqÚUQòàÎ¼”¼#Ö±‡yz¸va°š¬«F¡?ÂÅkÙìGÖÍîXêÊ9µÈ,,YdÇÈ‡H}6™Œ×Ûí‹‹‹Öi2m¥Ùi[‡{´_À„:º‡I7ni,"Â´“ìß|õ8Õ¼G;_–&X5
ï
	Ç¹ksåØÕC%Êzè[šÊéËVB„G6	äŒÒ5®´(ÊÆÂ°ªÛÈÅNÝ‚½X¸FRV¿—q_\û$–ðK3L;/÷¶ßu·t5™g´§²jr	útãûÅý–í®xž-ë Zq6LzÇ›zàÓl’¢%á™;\ï¾; >Z–Î.Çhn$w¡2·êùÑÌÛ‚ú¶z7ÓÙ/;ÃÞ©ÔÞ€ãØ¶4SŒh°’…ÖkŸ	wÿáÍ–­~,×8Ð„¦dkP5˜ /NÒ57)S¦XSµ¤Q#8×é%F4ˆ½ÚÞ‚ oô‹²:Åt¡~„ƒ¯[#¯V@â
`]¬ŒW³n|SÖ+¬˜;?^ŸºpøfgçZI–ÐðhÕæpãÍÛpHƒ…‡”-‡s(1ùp¤›[,ˆ„»?\9llï¥Ö?äN®„C—CËRôcFr­×¥$ÛqÙ_ÊëÄ3JÀ`òL‘E<4ds·Q\E1CÊ9Ò¹¶gñ9ºÐ±^€Wwë¸È6†e³¬{%…ý
o–Ô¡ŒŒ¦t,¡©ÜŠñY¢t:>»l_œ]6ÌÍáéxØ:›Œ†°;¿ûgüôÓ^û ÛÙÜé¶Fý¯4ÆÊÊÊ“GþûôÉcúwe¿ÃçÑÚã'OÕêÃµ'««Ÿ>]}¢VV®<YùZùJóñ>Sd)0•<æ¶ƒfƒÁœßy1ÊüûOò¹§öÞlâÅoQp„—=÷QC"¢­Üêèíf~ï&çÿûÿú‰ZÊ¥œd
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
/Ú•ÊKé·íX/Ÿe§P 9žÀ±Š4XÑX=œ:è1}.ÒÜÔo@¥tâbiq9þ¤3b ¦þò®ð¨t¦Õåz:&p¨ºVÖA[âM/bnÖÂy.œRgA_ÛíK’Pi¿ÎÙªûjãjÿ?²¬+jìÿÇ°,ýÿ¨ºQúÿYEª$îa4æŒ½ \cÏ½¨\ï¢8åÕ#ÛžjÿR†ì-Äsê<–;gýŠs—NÝùÚ+ñuÝÿ|Æëá±}m,Øÿ¦f‰þ¿,Üÿ–e–û©)Û€åiºŽ­÷™O­éx²Ör-ÍóEñ<MúÏzcÖ~ÌrH‹(-³éyªá4ÅÐˆ§™MÕóu]mY¾)[²áÈbíÔÖL×\Ÿ˜ºmk†áèºm5uÅlÚMEo:–mÊŽ¦¶<]!bíÔ.Ís_“]Õ'Žk[üfº–!{-E&ž-»®¯úq¡6· 6‘Õ–U¡{ª¦øšÙr<‡À <×r|ÙÕ”¦gèX³ÐÀ¨ElMQ-Û·ÃPä–¦Û-×p=KÑ\˜¯–c6•VËô³ ¸q¾Ò·<¯iú-Û¶I«åª–îkM¥©º­¦BTØ	ùÆË8CöUUÓš„ØŽnø-ß´Y‘UÙ4[:tË6|ßs5G Vt†çXŠm®ëxP­iøºç8¶c«MÓVUÕSÕ¶LY¨–·¸»]ËÀú•¦«(Šj7]±Ä¶ä&ñZ²æ´Z-hŠÞRÝÂº‹lÑEq`$FÓs[~Ë"†5@&KušªïÊ¶¦›¦bda›ÓªjvÓ÷4_m²îYoj¶«6epÙ”á³×ô¬YX3x!k¾ëÊ¾ãª®§éšA ›M[Ö-Órä¦E`²<6Õ,(ÑŠøFSQÛƒå1TS'-À\ËôtU¶MEU}Ûtæuˆ/iy0ÓWš¦×ji²¯è†cÀÔtÅl°Ot@ø(‚Ý á"Ã`Ø¾ã¸šmÍµU¹é˜
l9ßÑÕù“#Ztúªmú¾âùÌ¬k˜²ÛÅÖÓp€õkº¶È¡ÏôM1x@—˜cC‡9€%Ò\âÈ°àÄ³`WÛlDU×<W…ÝYlÖ|²©Ë–ï¨0³²ô°Úmy²o(ºka±mUóm7ß7ÁìSmª²¡Áiè»l%€~ê²Ñ´<˜8‚ÿ³r³“µYu mCÕeMÕÑ G®ïË~S¿ZrËT-Ù†·s{,k•žVlX[]±tâØ­¦ã´š¦OTX&ÇÂd ».Ñ¯„S‘¡–âSt_ÆÑ¨®l)0¤¦ª82ìÛÒ-;<9(È˜TL@Cw ybivKw)´ð	àµí@Mvò“KÍqe¥Ç-rÓE;rdi. !¬ãÈT†Ýæk†â¨°W”¦å‘&­bzrQ)aj0ñ@ˆˆ§! ¢b«nSÓá„ua¸ž¥ZŽæºªRU¦$®'zñƒž-ÛiËP[®¢[ž£›-Ën¶àœQL<µGõ[²çÃT{‰ïÌø	1åKYU]X»å(pæÛqWƒ@à|tM‹Ü *ÅnùMNÒ2]ÏŽ¢¥¶©9¶íÀ9éºMO±‰1g^µ»ì¡2e/ð}¼G£¼À<6ˆôLw5$#ª,£')cHEê!…`U¥ÇLR†ƒK¼?#…ÚIº²aÓBt[mÙpf[pø+­&À¢T[v:ùv1L5S¥\‰­µ€‘"1ÉÇ'~¨ÒlÉ¶ï5'ºÑðé¼·éÃx-×&ŽoÀ9Õ´t`šMàUÕ´tÎ] Î…€­'<:õ€Ë£=ÖèFÐ›ž
ˆ‰ã—m¢iDm6UÃò`×ê¦cEñ}8á¯½ÐK€	x
r½ækžé¨VÓjÊ-[¶LöÏ*äHñfˆ!›Y-?³´ŸŠ¦Y¶‹t@ótÓ²[ÀôT“ÈpÐœÚ-Ó*„É;ÉNþñEÅöM¼j B´Cu‰IY]¥©O¬´a›°%ŠÑIQg“®?€“m œøºkk§ ÐµoSMØ¿-Ó)ÞVŠÜcÞEøø#à5å¦é™¸>l×ž„p€0Í@W[¿öÑPÔm2¥#–Þ„&#×Þ´[ði€Àü¨óˆU!	 p›¦ª;®»ÜplB|Yv="à}€o‘}³i)²-SºòçîÎæö»îvEó`HŽgÛ8:0`‹ý¤ÀÏ«Àk ¿§8q½ÔÙl^8 ÍiÂ•aÒ[pŠÛª-@eÀ88™-`ïÍ¸f|ãõ
ýBB~æ¾Û@¹ß0æßÿ¡¼Œò?|Ò(ƒü¯¦ö?$ã¾;†é—ÿ‹ä˜e·±àþG×d×x]Ö_·4­¼ÿYEzzME²Å÷§O¥Äü>Dï ø½Å‚hÑÇ©¿J]þ õüÕV÷ÔéÚ¤^¤Ãhb‡!‘ÔÖºlž*½Ó&r&Ó~]êž¢K2A§ð•evÕDë,µgŒeáûÃ¿w#â£µ ½—ž$|( ¯ÎîÅÿññã]9ÔÞöQqmø¸…NÜ4ºÃ¨ËZ]iÂ@Ï}üB»¹?`<OV–ZJq+gQ7‡ÀùÃ³35¼ÀwÑÔ‚²ØèádSµ¡°o4|ôÐÂâ‚JòÇúôf·¦Õåï–ºˆo1Ö€xØ:Š U/b‘“q@0©1~¡cs‚¶°÷†p©¬ÅÞírn~néÁÀ1qL^Ô¹§>õSRòÇ³r‹úS3¿lãw(Ïc¦1m¤ô 1!LÁã.]ù£úYª3î³H/€C\rÃ»\Î\NÔY›‡ñ›wŒpÜ,>çó…GÝö<AIBh™ÆÏ¡ðh¸3»Ïôww{›GÝÃ½·;¿n°£OY©ý8_Ö*83'´à¬“QîÃ„¾ÍsûÍŒÕÅzÆÆ/ïfÂœ±ð`¢ŽæU …%À²ö˜ÊÚ 0O¹1ožó™&Ð²=…®eÔYû7kœ!X´³ rƒšÅ0¹#BaU³™ ÌN¢à#Z-øÛ¼h¬KáÍÚP	ðÐbŠêÔÐ¢³®dEG'[½\›Y_è˜áÍz„á!§çæŒT®‹ž+ŸRÀ[¥\sØ]D4<»Câ(VYÚ²X¡õ¥RÑ¿nðJ	în)÷lp/m\Íÿ+Šª)‰þ‡jPýK-ßW’–¶E¡0OxÈìÖ‰ÙkîÈ1ö³FL©Å§`Ù‘çè³,P¬s¸#œà³‚gÒ0‚‹=Åª–y9q´UîV>•2Ã-úGÏÜ.°Û‚#ÎÔjó&­àöºEög6—ï7:ïÑóÔ'“©sHû]¥³öqú÷Çíçé7æ®0f-¿ü.­Å%]ï¸_S¶éKúÅîdë1;/¡€Óü ¦ÙCžM=¾\§¥“o*ràæ0W‡©å¯Pö¸°¬P`8Zò¦%'ír®GvþwñÍÀIÞÔ’ãl Ù1«™dÓIÜy7¿[N
Klî½{}Ý	a+ñæzCd…­ƒdyáá—ÂF¥D Û?S«À9 ¸ùû tÀIWTŒ“KôÇ XGsøŒßìÁÄóA¥s™lTnúyûM•Û¨Œ¾¸ì¬Ñ_k”ÀÃy2Z[*t¹õçŒ5#
“±LW¡¶Ô *™@j2ý¥ÂMÀƒPcõgƒ¼7\&IdÔ¯ Tµâ#Rá~@³æ©5×“ÄÝüý¿¥ðØ§§RÍ•òêŠ’úCÃ#gÑt8ü£&xµ3©Ú–ö~ªþ'T5l´¥×;»Û[Ï$ïäb¸ï7Û[ê÷õ Z—j4°²/}|.ý‡TPsªØZUúøBª'ƒQ$ÿñÙžôaÅå¤wcÞ×ŸÏüÙŽþáÂÁXóþSªùªØ­-Ö‰/„ˆnµ)ôNþe]áuà/_¡&†0—¾T€âñíIìO.ê_JµCÀÎï¹ÿVî|>«O›èþ2Ý[`$>^vUúV©&¥“¿Æixº‚9:.ræ–b­¦Eã’O¿
å@ -/(”'_Bùã¹å…BÃ«"‘KKS_J´BUDnÜU±RñÙR›)…D}¶äŠ¥fK_';­™óBèDb…]«Åæ¥ÝÎødRâ(Zc×jÑÈéÆp¿Â¸¼­wRÕuR×3o©áê¤Ê¿Ç¾(›Øq§˜„Ø‹£íZž|G;qÀ5ž‘…è+Ô©¿a0è¼¸{Hh_=œ¸GÂÚ$Çl2¥ý &g¥˜|³OôJ2™Q'~I!ã +6‹³†õÎÚ0ÄOõ—Ð97“Ž=‚¤@gm]]íînnw6%,l¥?(Óš*.å$ßSÌJÎ¹dŒÃ	ëÂ0š$Y!Ë*êO8äÅqf_RCf4ŠÀ—	B6P¶°k©gèé˜}˜ŽÓÌ|Nd­‰­¬!_½Ìø<­NnVš™Õ§n@@åJx3©]º â¤³–1
ÿJ[–6>=ýºÐ‡S{rwkq¸ö‡@¿)žK#‰ê!ßKß.ï1ï€?µ³A†rýÜê»†Þ{}wµ¼×]M*VÕ^nô?TËÐý“Þÿš.—÷¿«Håýo‘ˆ`´ð¯E'	åmðbxÐ·Áó:øZ×‹_ãúL’ž2—¸~ÔÏÆ7±{†µYÔ¨gi<UýO­«îïŒYdÿoÉZ¬ÿ«˜žÿªe•çÿJÒSJî…à6x>(í¬KU<#1_eù4¸
:2Á<-Íë&™:ËÜ —3q¦Á2„ûœø“ÙSI5È ôº´·ƒ?¶ºÛÛ‰çš›ïX©$Á¾ÛŠÖlµÑÌ¶©ÝlÁŸ ÷E U‚ÁÕ¥v ˆGÈ•…p8jŒÒcoÚ–,+øCm·ÛlØú‚.ãÝûÝ$¥bãÈ%!O‹ø]àÿe]CýoS.õ?V’Jýo÷Ï›?LÞŽx1«^j€—üû:û§cÊï—~ì)ç¥ã^Ú¸>ÿoÀ¹Ïüÿhåù¿’Tòÿß6ÿGáC±ÿ5TK×`ŒhÿkÊ¥ýïJRj×mÜ|ý5Y•Ëõ_EÊyÚº—6n±þôü/×ÿþSÖ³Õý´q‹õ7¬’þ¯$Í¸"»‡6n¾þºZžÿ«Is<É-µòŸ"+VnýÝ(ý?¯$=ÍéãmI‰"	E=ò$?‰œ2ð¥ßðaó1„™¸ÒïßcñQåÖÓÌŠ?@PG!3­p©i…¨€@qæ£éC^ô'öiX©ìoþØy†?ÛÏh¨»zb@À3è»qlså¨Ç1qOR+{¿Ä¦Ÿ¬ßUAÛ¯*u¤j5é½$Å#«¢b0>ÐÖã²b)Iª•€/dZ€iÜoì ¦Fìbö©°&L›¯ØŽ/ŽaÁÖ ÕŠ½†yEá„ÁtÂâþ‰“^YX¹ÔºûÖR±ßÍå¶qÝó_WÅRÐÿúä-ÏÿU¤¿~÷ÐÆõ×_—á?Êÿaü‡rýï?]Ï[îÝÚXÀÿÏ§Åë'%Y•UÍ*ù¿U¤§ÿA9 äÚž,ïÑíÉm´žÜB`É}Î(î„'wS
xr¥VÀ“ùjOfõžäºL-÷rz*‘	ôa8$#Éã‘CÙcÎå“¼– ƒsÃgý'óÞõ—¼âËþ“e=í/µ7’p¤‚œs#`(Y<÷fž(¿˜ã¼7ËÍ·“†o9&¯ðHÀ™ƒ9‹yæë­]«Ì(µJíBU×¤Âl l¬ç¦åbÃÌl9Ì`Í½¦° 7[&+:.ƒ¹¹r™¸×I9f¹œ”ÜÚ9x»ñ.ß*ËMK¡€µ5SŠå~¡Ë—µgÆ}…ÿ¯…âO@(¬Õ\ (ü×xEö1]už:q5.ŽŽžQöFº´wù¯û¹ª¸qÉœ­ì—8èÙã}j¿Ç&\Ì…t–ãÔDw3è;¯XŠÍq\	N^2a) µ¶GìxžGdî’¡ßôGÄÛ$“¯™y!f3y8¡®Ó§³ÓZ¬>Å¿sGë‡A0ç—µñ$8û“`ŒÍ‘ç0Þ–KQ6y²YüÚ¡îÐÆþÏÒ´Äÿ¯ª&ò¥þ÷ŠRÉòeX¾9Èÿ¹¾_§¡M¢ËáÀÅˆ§Ðm´ÆšHþ~x2—ñÛ²Ciwkç5ðNªêKäq.²8²ƒô$¯jO}X¾©OFuéÀÿ={âK'öhDÁÑ&ì) ?µGS4=‚Å¼ !•ÎÉÄHP¤äJïÐÇ%¸†–âx›LpÌyEB÷6­3~PÚa$‚ä!G\,ÁÆLxl†ù`â`[BW£PŽ¾à¤ Ôh[à|9žPˆ„ÝvCó“s2ˆ Šê@'¦€6 ymgä‘ÏÆŒ?H;:§Æn€ãÐg°P‡‚qåsµ–6ÍÞ¨-¹£N<Ëëðûîæ­w!þÎ”¶ŸTçðO›C •m@%íMúû î£Ü·qQfŒs9^Xsý>å	kÞ¨†û<W"˜ôí÷íjã¶¦Ù–þÝíþ¸a(ê—Ãý÷çßuÏ¦Ï=ú×QhµBÿPí?´Îßx¿ìõ•æø¤q|r~öëëþ…·ñó{ÛÇ;ïOvíÿnŸÙï‡òdóÍååùOýÁÈÐÍ÷ÝÑøÍ«Æ¯Û6™vß?©¸£¶€Šaæ/>˜Øí-¡n"j¹™¥ÅÆ@žˆµ5äoÛr}€YpÄZˆËim'Ññ$˜ökð÷ jKœðippI²_úƒ32zGá¢kµNòˆN-gG^fOÝ
îiŸc?Ë¾°Ö(ºœöiùWpH¹ÇÑ sDAœJ¸à5¶àË'Óx)øéçO;eïÍÛñÛï~úðóä|úÓgâô­üòË/Ñ¥õëÈútáomžîü8üùÃ?6Þÿ×(<ÿôÝ?”éoï6ÏßìŸ|¶.Z¯Þ5~o4Þ6º?š§ÿ:øé]ó_êÌhÄ4Eã0ûç•T"[nÎ_H
p”˜§;(R~^¢f{Y\‚­j˜1ïÊçØÅ%ÐÅ12W{W—™d^æº@OU5ÛÎé
n÷a‡—/.ƒnékáÅÈóy€ŽÇð’ /@@h(.öéô3à é_Ìÿ>Êðëó…<i\Q€ñ­ÅN‘G¼˜;Q±¿/œm2DšÁXÄâRìnƒ®š=¯3¼Lx<¼à¼‹OÀPÓ±‡;‰å©?ÍT¿É{Œ·'?]3åÚXpÿc(fbÿ«È*}ÿÓ-µ¼ÿYE*ßÿÄ>g/ƒ
wÂ×¹
Råë\aÕ}ÿƒCå2â¯ü(vqÌøÜ£Ó>Až¾>{óf2y	gÁOxCyp?ö1"Ð(¾&²§~òÄ8‰ú–M[zÓ÷)W€ Ÿu:6ÅÃ]údn¨Ê ;õE,ö~q'»cŠ’tÁÂ`³äàþŒB~c˜¸>	&rI}Bq¦d€€ÇTÂ£(B÷7}•¬	Ohl)zëW—>¨üÄ°åÄu¼;)ÊA¡pŒâcTÒTCÁ£ñ!¢£Çs¬­K!úYÌ 0‚Š§cÄg]ðù<Þ=õå®Hì)u¸Û©6‚qÄCEUgŠà»^§šóùò‚7u#ÄxE­«u¥ø-Ö^ñÊÃóŠ¿±G·BòyGés v/	•Ò£~v…~ÆÅÿ©5J®è-}ø
0’ÇÃÚEf?tÐh2W¶ÛÝí e.û`{¿ƒ6•)7øwÜ=17»y—o)0ÞÛîÞëÃÛùe?ÂˆV³'3µz›
ªÆi`<ª‚r¯ß~ÈóOÏJ¾ßÊ”ŠÎ¼F<ìÄtx'%u	öÝ)öíš”‚EÁR\tæ™ìE¸ÃØEáÍ—é«ÇòURñ§í_º‡{Û7D¹O'áˆýY¿fó!ÔÇBïßílþ„û SK‡‹P«ð#ÓA¥ãó{çÙóäA^ð=+ýñÕ:xkM¼À³÷)€e30”U®Pª™\•åªÙ\åjUQÎƒq7œ.E³‡”®×ûNàùO7Rù~èôýß,õ?W’JùOìsVþ›³²2 —Êüÿþ¿ìfcÂïÇä–EYð•¹ù?e"„âMß Po€73´‰¥¯üÔ×Tñ¬á}élsSjYã¦2¡”Dœø	dXÜ DAa¶Zq¼®=ùè n‹.C*aÎB
©€›j-P=\.É«Ó©ãr@)‰Þ²_IC1’2{P„×àëŠŽU†OÜÅrž”Æ$fÜ†¾Úy3â]•AãqÃâz»1öÞEu7ÑÛM€ýùTw—¨’ãC¶Tœ›–KW[,—æ2õ]VvÃó83Ì|"ué«H•j÷Îu{Ü@%Yö<´HÍv\ bÆ˜Uë	‰Q¨ÒË•Z±ë<Ñ•Å›ÈÎGÁ2ú‹†˜Pòë0¯|ÇaÎ(ëž‘‰Çdügj$Q:†#ÁÅÖùÿ“>M]“ÿ¿“ðþ_Ut#åÿäÿÕ,íÿW’Jþ_ìó5øÿ‡®ÌÎ i›«H!ãŸW–ND6ÿÆŠÁsÄ¢R5ø‘°ã\Ñ)Vá` ÓÅ¶ÄØ’%wëÀ+S&ÍžÿZmºêiõ¸iÔ. Úërzþk¨ÿ¡(Jyÿ·’TžÿbŸóçñNxØÇ¿pˆNƒX¯¥¡íquôÉ›)>þ98ªÆã(Ã:WvøÀƒU!sÇ÷)pìÕ˜dÌD]ÚÁá3Ä›9€Æ¸¡‰s8?¹º@&õ™Š#‰Êû¸»ô±¼»ßû¸=¾%h°iö™ãêû»›»îÝÖb³tV®ûþÊ/ºÿAÂQóÂ"LJ2'Œ ,!’ÄÞN=òj]¢w4qÏÓKªÂ¾³Eµý©eDb˜>ðãË¢¢;®.R–; ð1?¢»¢þOUz<\Èà£X‡‘rÏú¿š•Ú+–*ãû¯VÚ¯&	üßò™Ûp·`þ–Úáë§¨=!VwÏö<ºÔ:¥‡Hðý“l_®¶¼¹pB“c÷nÎIÍc¤–º0ZéGÆ)aUh@©ã|À™;Uf‘2å½ÄÆ—Ç]›;â1jF¨Z˜‰q‹îsç£–€Äó˜Ž›ò×|¼Æk PD‘òL	ÍÍ”QË¨i®xT¼ö›¢Xð`{æ&Å®~y¼ÓUá¥Ò37³hÈ:¦~ppÙtù“à”ý®V=Å‰ð„f>VØ»\—ùŠeÀø›\œ'LX\|¤°Áˆ£ë«“ù«È]ú}*ÜÐ0kÕgL×³;	ºêy¯"¼Ý‰Ï|³îx*7™ØéÑ4”jÇñD@CãÌ8
;¼ì/s¼.ã8Ëÿ©yþO])ÿ§hŒÿÓKþo©äÿx‡Kþ¯äÿhã%ÿWòœÿSþOY&ÿ§Ü‚ÿSÿŒüŸòÍòsÞï¢ ¶€ÿ£üR&þ‹Š€Jþoifý­õÑî ,òÿ ©þÎ¬¿¦—üÿJRÉÿógùÿù›àáóÿ±w´ÖŸ:k@×m§31Þ³®ÜÞyrÂcý^ÊN–Ð
ËhY‚Ì.XVŽ¤)â†ãZõFü2o#–
”¬ü ä8gfÍ¡ 
³Uì8”¾™^ºðþqÐj!hõJÐjha0ûBq¡Ða¼;a÷(EuÔ«ë¨Å¢O¡‘ÈCW7#n!SjI¦ÔJ™òË”ez<éZñî÷ýÇ’4þ—ªQÿºYÊÿ+I¥þ·Øç…Á —òw6
Ø$uB~C—s¢bÜÖ¡C¼P×pçPè½aP¡;‡Rƒü},5Èsäq*É±pÒ—À R^¯·¿Ñí~Ø;Øú“~Ram 5	ŠAà÷ócl˜=ò½ä,SØyöøL‰º›NpwJ@A©æ¹Ru£ö«]»”k­*dúÁÐ“jç’"ÃÇÖ­6’”)0ìëoÐÓ§!È'}"5¥¿þÖ%¬JŽôò7 öûËl ÏgAc%ýž^²™,Ì†ÔÈ¤ô–îk5î¢+îÉÀ–:?H /[ÕZq’fa˜í+`{6Üž…¿»(6õa‹	mùö»Œxð÷KU„…¿íQwÒÑˆnsÁ§KÝt¥ð!Ýb3p˜§í[¤öLlý>‹ÐÐN0ò¨»}ðEšSm#«…ÕåNKº’€Ìù]R®À
V Q	u…Ÿ6åÓ`v¬ÜÞ?ä¯ï®ã¤óLkÐiIá
ÖèQy¼y¸Þl–ï®fÉÞ\`½1Šçß-7qiSº­¹e*­øÿ”iVÿWËëÿÞåéŸ¦éÿ²øï¥þïŠRùþÏ;\êÿ>¤wýRÿ·|³ÿ¦ÞìË·Úò­öAèÿò›y öái}|±cÿ§fÂÿ™š,ÉŠ¥ÉZÉÿ­"-ëÜÌ³|;#˜8À{7ÂËÝÃ£lÀ<„_“ÛË3{ã.tßÆ¯–Á³êŠZ—õƒ7‡»‹ÞY‰vVÚ
NíÁ#áè´¦f…™<HAˆ$Ø#ÔYÈõÅ*óeéhê@­:/[ï“èùÚÖÞÛw4âÑÚºT¥¤´ÇêU_Ä Æxas5 <¯@c*+V-lü%¬J‘„^¼¨Ð¨GCŒ¢çy¨ü‚N4jÉ²R}WÃa\ÿªÊÝî®P_MëÓÙyÃIïº±â9q`in5é8FúŠëV³Ï ÀUÆìÐCvºu9õÛ_Âß×r“ñ}®ø~<Í3ÅqÒâì²}?™Ã´x:»ùÒx%ÉjäKóéL+¥óSç/-<eÍ)3¥U99ø°Û‰Ë¡ôå<gãÝ8§“Lµ0ë™÷4–âuJç„UKçãªZˆ)"BfæåªŠ8Sï„Í•ÎÏ¢Zé¬ufæiI\Õ×>­—Ÿfíæ_}Ü¶›Øÿ(šÂìJÿŸ+IåýïðŸçþ¯´ÿy \ey—øPïÿÜ¾neÿ£>pûŸØÍ@iÿs?ö?¥O‰òNyÑyðµ™Õ2-=ÍÊrÑv‘¾ßø¯–‘ÆP@Äø¯Zyÿ¿’TÊ¼ÃYùoÎ&xÂß c+ØÃÄ8´Æ‰ç0§â>"eRÈ»RÈ›”BÞ7(ä,¢üó¤äÎÐó™¡‚^2w’ôbˆ‰¬—Ñ„Îˆ{©ô>ÞÏTä+nA]ÐB^î›#ø¥ëtÑïêZáOU‘aùÿÍxþ/_Y ´"Î|xK¹¯† `ÇnŒ-/±åE¶t:†Ô6w0sûýèD·kÙÿ£UÄxÌ…ü¿,ÄUÊÿ[%ÿ¿’Tšü/2ùGäÈFÿÌ:ÒH¯?‰^SëÿWd4ÅyÄÀl3†ò‰õSÎ¬hÖ] 4àÃ>aL¹LSð7‹Ó*NyÏ€{'»D—Q}Ö<_+šõ{ÔÐßv¨5&üÍ¬øGfüsÆ“od&ïg*ÒTbîŽ:©½&S[› ]ÿõc¶ö3ÚOÏã¬õ‡ck®83HæÇs"’¿’Z¬5çôÄÅ‰©9äØ>“¶íºd•îÐÇ%¸&mlmI0ËôðÇœW¤p jÎD&Øœw¡øÎ*a€²õÈ‘à8 wêD˜±Ý+ô
 h~5à;†O^—N§„nÜì¯ 	ÜãP&j$mlî®…°ãlÜŸ@i©/Ý”K6":¢" & z4	†5X)oH&	ª#7äI|7Øî ]}‡mŸD¼BçcU©«õ¦.×E3³®ÔõzS6>V_`ýçÜºC$ý^²]`2«[BŽê_Ñð(™xœºCœ:>i¼‰õòcõ{dtƒóç@á=
é»7‚^ +llþØ:üN#Èm½ñw¶™È‹ê2ñ'EìL‰?_’™_
%ÐcÐ°ÌåÿÃ»ßIXèÿKWSþßÂø/Šj™%ÿ¿ŠTòÿ¹Ïsÿ!K qàäkHg;å‘gxÑ{dü2ß?—í¿6×¦¿äùWÏó¿µCéÇ ä>òºìªÔ0Ÿq$W®b²h§Ñ~A_AíaàÚC¼<e-lŒÆ›‘[Û£KIßá6" Î4’Þ“	LÚf·u“6o†(Ø—q |â…dó.Ý ±ÁèÌ¼šÍ{í^Œ"ûsq;™1o1g,RâêkŸö‚5{ª±®eÚåYÌmKŠÇ¡TÅNR^@l 5^>l£¿4Ö¹£±‡ÜAZââˆ{w
&¹Ž%ù™¾¥¹¬{ZÒ»7ñ÷¤ƒÈ¸&@'¶gmµÃ1qö°]ëýå¥8ž¤8Û
m{8>¶Ûúúhz
8ã¶µõ¸¦º>ûç°A¿#S’Ÿ;v$Œ#Èˆ	ñuÐn5’_ŸÂ¥ÙG#{È«(F‘	§§½KFýè¸ö
]é}L*”ÞÇ%
ë'hØžŠvBQî(  á5£È)iW»ø$îIÝ7jJ¦“°O‚iTóø^hËaÑg(0°o¦£¨­Íâ!ö¬&®80Š‡bÙSØCé°ú¤mY–	üâ•m’Ïãß¨ƒ`LgÛÌÕÉµ\›Má<Ùj:ã"Ö¥›ï£ù(ðÂÔ­êÖwKŒºFÝ?²°õ“úœÈg‰û Ojà9òôæcÝ¬Ú‘7¸$ŸáGz„Ö<:ì‘Ïœ]ªÕ@G™a	N¦ã¯ì˜‚òµèbLÚ0XðèbÞw@ï¹¦yßÃ©G+œ±IÌfÇÄÀM2YÚ£¿!‡ùà.^¢Ã¶^!X`<'ÙÑ‘d!
‡ÇÀ} öd†ÃF_·ã™/ë¯êxôßÿ'¾Úÿ ¬ÆÃ¸\(ÓƒOéýðã“ B)ÔkP“å¥µ±àþGµ¬Øÿ»Áü)¦¦¨åýÏ*R©ó_n Î?PõÎÝxgJ©y¥FÝ n§‚ùkîQ«Tì¼a©}OpÆÐ`2Ø ïÌY0ÒÍ°Á^êðûMj	5o`÷GAÜ;@¹iUÑ5­ûoæŽy*¡·éÍÁÞÑ>Íqƒñð‚#°gœ"K2å„œ/è¯§ƒo*‚úCÛŽÅ>ÙŸCà‹:†ü¶ò¥rÛyrÅ9áˆqÓán½ínŸÁ9iœÀ®Ê#XÕ~»ñR_Òuï4¬#sÉ•``ÚNƒQÃsÀ	;ó~»Ýz\±lèPú?÷ü_â³àüW,EMÎÓ²àü7,Ã(ÏÿU¤¥QKN3K. än8ÿœØÝ{ÓC…eœ“žc»'Ó1%Í™|òñy6Ÿ)Ïä“ÑÙò¾ˆš5—å ç·Ûÿsé?.ÿ’hÌBú/ë©ü§ ÿ?€’þ¯"•ò_IùKÊ_ÜÁ?7ågIÔÿ\6ëOÓú¯É*õÿj*Šfê&Þÿé–\úÿZIzlTû1ÑíMØQŸGz]Òé{¥ÓË„Ä®²$:JŒäKO$'Ó>ÆZK 4,KJKz	ÿ¡a3=Ð^‘h¡(@á±T‹¤×G»»Rí‘ÿïÁÄT¨»ÇÒ4àû®þðW¥²Ô™ñìLÌ`äNè»¥½ºùIgG^W×µu}ÝX7¯7O;ï6¶ßn¿;Üø:ÓÅ¸ƒ•L‘ªÒ)z9wb8§‚³h&¾ö©T¦U¥”ÿÃ`~çÃ{þ™£ö¥´±ˆÿ3ù_×MSGÿÿŠU¾ÿ®$Ý›üÿ€ `_‘'«1>²-Í ý•åz–—”ìHÊ±“³NþåV]¶êRžgTêrži<ÿ$JöÝ·ÜS7*³†0‰1àðúqêFÃØEƒE1H‡‘a0¯`ÓtÜœÿ³¥˜6¤Ý±y£žÄ[`Ì†SÍ@›‰­Êuë¥ç´§/êÒ†÷	ö Õ€Z—ú“ 8
Xì,/BÝæ;ÄGÆ’:¤‘Q½ò4SšÚCÀQ†‘Y¬ævæ{8õÉÏ.»Ô˜†“Æpà4ø0ù¿\Ü÷
…Ïj4P¸<9,ËMUHËáè=b»àTtýV<^}Q3] w‘U:µGS{x%ðVZ:ßrP°p)
Ý¸ƒ•ß~ü^Ù"ñ¡¡`td‡3ž•ö(
;#““:³©¬lø™ä3¥Êoœdÿ^9¼“N8 ¢@*¨ª‹¶²•7¸céo lÈdÇwf¶+ÛŸ‰Kñoö[ƒ¢Øâì¢?ôµÆ
ã‚²ÈÒ"âˆÅ§$˜F]âv4Y®@3#Ïžx{Óh<:€p°ß¹Á( ûñ×íÉ$˜ä?Â˜9	ùÎñ^]tN§Ãh@urã©ùSDÈòì‚²ç®ÞÕé‹ùQ-#åÿtäÿLË(í?W’Ê÷á1ƒûôRï¹mbìYž×£lýÂýt/$ Za‘¸Œé$¹ù±äc¯Øyú­œÀ)µ[ò¥dÂˆº@d‚ÓÁåm}42h¯`KÁØª‰Ú§$M…—M¨ÿÕ¡anà†L0àA¶ZxL‡ž4
"`§¥AýE{ru£µf5ÕÐÎ×CÇØòuq[œ‚ãO[á±Dúu˜e©Ž.e{ãI€8Xgm“,²1&EâèÓãß`éàZÐÙgö`HZFã»Ù}‰úuÛÝímu÷Þîüºq¸³÷¤Vj?Ã#¤è™Zpï`csw›^šÅr‹†íp!û™Š#ëñVq–SYnØã1×	d0ù-œ Ë¤0aÜW:” ÛÚ8Ü˜†€R	Gèl¯'7ëÙ—ã0–xÄ£}º–¸2Û¿¸3Ìu&ðæOGûñ¸¨üÆx1LVP\êbtfÌNbãtàyCrnOˆúõÛ1ø[¦¬-ÂûÇÆû±£xŸ ™¥cØ±´hü&œ.%š“MPõŒP’5¯ÍøZ—Ú¡ÖcD7¯€‡¼?,®*P¬&m”F0B	²é83JŒp\YÚp<¼–JIÿV¸Á(¯©ïž²ü?'ÀõI8^bøYÑÿ¯Zºfj&Õÿ5Kþ%é·íwovÞmÿ^9 áNÂ^«ß3ÇI¥.³ÿ*¿½Ù~·}°³ù{¥»½yt°søKïhhõv·÷~g£÷öF»Gûèo£ãÛÃ¥é–éþR‘ü¿DÑŸ¦ûß2”$þƒn™2Ýÿº\îÿU¤RþÏÊÿYôßÌhR:œg1íáÀéÛ| ’s<”¨\s´•Ü‡…—\HƒßðjxO5­/¶„âv0¤Ã÷[ÔÃèìº?Xæ>2Ý]·E1é}²l7k—zía“ù~ã óÞNÉ;ËÕ[ö»JgíãôïÛÏÒo¹È¿KkqI×;îÀ×Tnú’~±;9/íÌÙzZÀáPN²‡<{wosc÷ËuZ8ù¦r n¾@ê1žÉQBÙãÂ²Bá|`hB˜–œ´Ë¹ÙùOêc2. ‡7|…À¤€‡ìXÖL²é$î¼›ß-'…Œ%6÷Þ½¾î„°•xs½!—[;Éò&·_øE@ØÈ¡”`ûgêám Vp ì‚M*¹’‰ŽÉ%Ð7Ýg1|&pö`âù Ò¹L6êRÞ›mÍ+7*£äŸ/.;kô×¥ðp ŒÖ–Jyìp{Ä[¤ÝvémR|©SÁÜ^è¥ØÛÝé~©H’TØMV6èTë’°CùUW?ã·ƒÏÕŠŒH…UÂ]¿æzùÈ1lç¯%…ŽãBÂvN¿é×ªHªÂ×:ô`¶ö+S
·Ðl)ÈÍ”Â5[
r¡TRlp\4¨\¯Ã¹…’}"”v¯.Í6aZHIfÊèŠ¤Ÿmgî´ç‹
‹f
	S— dÖúãÎZŸD4b|2 ~pÌrÙUiïÅâoðÕÉpgÁTínÚÝ³³)a·ÙCéz&'…ê5üàIõ—°MÜ`L:ö4
’Å`œäû„F“$+dYEÐÂ!/tâÙKèL„Þk#àé’2)¶$„#™˜ÈÜgu|¬fÈW#w2V'7«Nð­[¨>!ã›¢¤¤PÂ›Á`vôuàcgƒ ³v6È ŒÈv’©‚?§c†Ó)¦ùèÌIgí”*Õð\8tÍH],%ŽyT¡\ N!&.47ÀL˜¡ÔI¨Ø“pzúu;ƒN®¦§§öä"î–Â>Â<|•¹ñÂIˆ½(Š¹“Õaþ¸‹Âé<‹±¤1>÷0>_=ú‰ƒÉø½j8kËSáx´WÑ¹ûŸ‰² œrîÛXtÿ¹3÷¿Š^Þÿ¬"Fè­6qÖ¼“{ÁdøÀT%ìõ™º(øÚ½/Ó]S±þŒ–v¼`ÿ«Bü_4üDýM+÷ÿJRyÿ›×ÿJqÿ1^³î—·Á×Eò6xé·Á×º]ü·g’ôTŠ¸~x½ -qðw“é±gX‹ýÉlÀUÈîUÇ|æü±{ÙgÌ"þ_ÓSÿ†¡Qÿ–Ržÿ«HO)ÉgG
=KðŒPÚ™ƒ€ž“˜¯²üÝ­}	£ cž–æu“LeRg‰I¦Á2… ÉÉ'³-ŠQÇÛ¨E
¥×¥½ü±ÕÝÞ–b{¸›ïÚ¯=Ë7ÍìÿzokûõÆÑîaoeü¿n¤ö¿†Eý-(÷ÿ*RÉÿü÷(ÿ?Ç¤˜]¿…H^Jø&-B¾UþÏÇ˜ÿ9ì4ï+ÍœÿiØÃ¥¹ YpþkVÿX¼ÿ·LM+ÏÿU¤Òÿ;úgÐþÊÃÿ.@náä†.@‚¬#“¼ñ¯¬ÂñG2³®>Öxôé¶rÿN?ŠÖú~ý~cWå\\£¥;xÿ¸ô[: ™»ä7oÜÁ" âuÎýxÿ˜ÛÎÞþö»­n/1‡ìTéCÈÆ'ïD©ƒ¬ÓSLµQÍzÉÞ’ÆwÅÌ3HÍCVô_ÓtKô2·N0ÎW9 9Ôö®UiBÎÇÕ—ç\äyü¿RSp<è!_^ÇŒ¥ð‹î+oÿg)réÿ}%é©ôlÇkKÏ–GXzt×AI·ó—B™ý°Ü+¡g»À!oÒ ˆ […ã(À¬H†}‹ÄX±KTü±%¼9eðFP‚è"sñŸç¦ƒb¾nÃ/ïnÅƒEòÜ,PÔGL_‡?‚I¿â¹m)É¬!¾'}{û«È|c‹AtGz"‡ëE°](Á>ÏVÏµä7ƒQ™$÷I gÿ\Èìó mâW¦2•©Le*S™ÊT¦2•©Le*Ó7’þ?<òä ˜ 