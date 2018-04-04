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
‹ /ÁÄZ ì½ÙzÛH–0X·ƒ§ˆ¢•eÑÍE’·*9íjZ¢ÓªÒÖ’lwþé,5D‚Ò$ÀHÉ*[ýÍÅ¼ÄÜÍ72ò?Éœ-6 $%YÎÊê6»:-‚XNœ8û9q'íß}åÏÊÊÊÓÇýû„ÿ]Y{ÄÿÊG­>\{ütþ÷ä©ZY…?ÿN=þÚÃÏ4Ÿ„L%O£¹í Ù`0çwY‡ù÷ŸäsûŸNûÇ°¼É4oåg_aŒùû¿öäñÊ#ÚÿG«>zúöÿÑÃµ'¿S+_a.¥Ïÿðý¿÷û6¢ÀI˜Ÿ÷Tóî>ÐÛQŸ‡ý8Wêå4“(ÏÕftÓñ(J&êêp:§ÙD-¿Ü<¬Ã;‡ateQœO²0Ï#µö§†úãêã5õÃ0œLN²ééiC^Ä“¿GÙ0Lúw>éÝpµø³®¼“?v¦“³4“'Ñ LÔ^t–cµœFy]åô¬•Ò³ Z½towûñ¤úmøq3œØq×VVÿØZyØZý#ürÇyœ&ôÍqšÓ<â¶/aëÔa/‹Ç5IÕiÿœE*N`âI/R<æ*‹&ÓDõÒ~„ëL'Q®Ç;:ƒ]Ê¹økÆÉðRMó¨¯i¦¢ä<ÎÒ„¶@–N'êèíf††ŸhŠØ4;;›LÆùz»}
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
2×)Æ¡n™ì¾/*Ì+»f§7.j£èæn¢p”ÜÅ‹|hæòõŠí¦[c×ýõ¬»>zß×­gûf2ûÝÎUÏå.æZ®rr×seëÚóÕ¸Á78^Fv—I]á,"§¿UZa‘ñÄ)ÞWàô4÷¢·ìTŠ.á/™L¡¯Es*6·Ab…×Wñ,óÉt0°þ[òÙÎ†¦\{U}×ŠC!™Ït . i¹Ýïž’©Î|¿@;L­GOÞJ×¾;µŠëxÌ¼hM>NªÏÇ»M¾üÆÝ•ì–NWvÍº1-wôg'Tn‚Y®£ªfcx<`çêl¸Ïl^>ï­ï]°½¸ö<fHWógSù’ô¥O¯wE†ÔGTct¥½œÐZî–+Þ%W¦Â3oÁ¥ÎlÎÊ·Û>›Ÿ~Úkí1æßÿÉ÷eòýŸV=~ªVVW?~ú;õøkO?ÿÃïÿÄýßÞÚèîv¿Ú 'ÍØÿUØòÕ‡…ý_{ütåÛý¯¿ÆGU|~Ø}£~èîv:ÛjÿÍK@%(T5‡Ï[I|ØPkR™&‘ZƒÍŒÆ—Y|z6QËuz¨^eQ¤ÓÁä£ÉFKNÍ0“^K}/Õÿù •f§íêžGÙ%z‚ão¦Å“	&'`ÊÃø’ä¼>^»Ÿ`R´=þP°c§¯Â›C¾yTÊO‘£5´çLGŒsˆMÊJ8¦x3æ¬åÒg?‹ÂÈjØê$9‚å·ÕþôFÓwr½•,»A3F¨È¿[r\
2«qÒ§„N?ä-=ˆ¼•Ë}¥xÏ{ùÝ1¿Àài~™‚DûQŸbø6^È†…5Â‹ð’ïIÁ‰aÑ
¦ÏtOœ J"*Ï@©——h(Å»y'`²pÅq2‰’>ïÓé4ÌBøGJ#bâ‡d¢ÒúC¬Úuš…£fs’Úš Šnt¥+©;C„v‚¶Ëi=ÁÔßQ‘hêM9¢6˜³&ò#g3ùg8—p<¢oÂQa]ar)»àÃt°ˆDzÂDýÉ%Í0¤Û…qŽ?¦SÌ¤¢žð7ì… %ëÏa	iJ˜ðóW/"Œ‡?àtf>ü	×—áå¼”\q,s¼ì}Œ³kß¨=è¾zµ>Ö(ô”ZS(Þáê sù –æ§–e»³SFèa„2t©.âü¬Þ0C`¬v„	Œ"_÷Ò~D™!UÚ¢CK/!f=OœW±ƒÆfxxwæÖãÙa'	Zqš§…7'wKw09I÷Û§ÔaÂ¬aÍç3ÅW'˜\FûFd/§ÝH"†á8‹Î)Ý1C Ö\âá"¸O~çæä':dÖïSÝªEtv:ÅÇ†¸)A/Ê&!¥!b…±<>‰‡ñ$æ€±Qå.¹PjP8ê 1¾%×ËýÁ´ð.ÚE<"´F‚Ì+¼øc8¡ßy3È§½3{âtgœúuŠW*Dèt«A$‹aÔ¡QW–»&ebè0™ä¼"¼FWæ•—«/':* 8FØÓ¡kèÖƒz-ƒ•ÐOÐÅL*?t!ÌD¾•«œ¦x2Á_±F‚“\Ž¨A¢Ä„v»
½8©qr‘â5äã|=X^­+¼==›¯aÞ‹Àñ61{y­0Áø…„IpŸk¼F§@ˆëæÄã…í6Ü„îÚDQÌ®sì™^Õ}¶É0É»¯—Cô—–	KìÌ€þa=.$îÞ‰,böÄ3C^rI¨@³ö¨K‹>ôcòOƒfÐöØ—Eÿ9³Hà=’›Ã-:‰ )²qHQ„ï"O+&úbÀ·ØŽd3…MŸœsI”NsXrž	¢;’ƒ~0ãÜéJIø¥WA…‘ZðºTØ£b–ðPJÇáùÈ¦IP^FápãqŸpY8Ä‹ÝOÏ¨	ú» >À!È¡tyJTy: y&ŠO˜›a.(N4Z1*B'aŒ Ðû˜$;áð‰
ÊÌ´Lå—€Ê”þ@ÏpnKNðH¤½Þ4#Ç$r“.%fÑ¤'@áþØ1ÂÞBb÷(!{Œ"`úŒW$ùkŸ&Õñp>i½ˆ˜ÝÙÍ@€èš`D)"óéH±ð±4	¾¦p¼ôT[T¨‚Vf(Ì0‡-Ÿž ]CþÊ"KÈ%Ó4ü½Oå/­0%5JdVÐ™ÜuO$1%¡—e%èj0ÅÝ5ÈØ¹70®y•æVLn
„…*:áq‚ók¨tM¶˜“3r3"œ@f¤¥Iæ1(8ÆŸ‘îa÷ˆê¦h*Éßºp8M½‰&%dÂÕ6¬ìÇÅìPœiŽ¹‚ÎUÎr÷	iÒ\(|?%öŒBÍó4æ¤geÝG$Í¸±ž‹z!–êÍÂ)Ÿ1 .‚ös ­=¬¾0$Ð€ÌªyÙI%Ü/KŽ€pO55
ôxp
…¨LsÖ‘ôÐ˜†s1š‚ ¹ð‰ßîÇœ[< äË1Ê—â/B?ÌåÅ¸³u¡£îÁÎ¡êìnâÕ‘›[G[{»‡Øx¥…eŠâ„G¤÷kG©±xJû«OÑCsŽfJáÜ‘Ñ*k,ps1ÃïšÃø†N_]g‘òu«€4›†@Áh#¦èJ˜0óŽ@Ý#@»ÓFßŒIf{’õEGì”]Šó@Ï^©nƒIÖû}ØòœƒškÀrkÐª&/Dy¶¤f…šÌì±Á¥q0_Ð•ÃDâƒ@Zc–ðÜ¤jƒhÎ³U?Ó±Ã/T¼Aöß	°|Š„ù—A†‰$ÝJV8h„©#³`QK{,•¥Ï(ýÐäâœkc $dâ«Éœ”b­W‘4HÕ´Ë¤F»­Uë¥Ð´Ág5EË„át%fLÙl§{ê=9J~6@ÆÓžR¨GÎ}BÒ˜?W'\"Â1w wA4ËÈè‘Ô…yä¢&pø:d'êNq2ÀÝ º6‚pDŸzÔÂî Ó‘·é¤i¶yà™4‘TFˆÃ_QÏ¹®íÙ¾¬8ÿp
ÌÐÐ‘À£#Ë´XèN–©\¢
ž †ÉDá=Óig;©¦ Eî1v!?=gõŽÌE4š GEtÇsŠg^¤³¢QÂÞBê:@äµ†v%*Ñ@YK(ìÌ ¸B.ÃÃ•¥ˆ/"ãCY*ã†:ÁÉ4ô5„˜Z“ä®Š0mª¥àü1›—p6±ãœG< = 	-Òu1htÆÌ_p«¶I^ßMQäÈkèD$0æ±º+›òˆI¬9*t„9øÄ®Q†@× X¹QŠP¿0#³¹ÂŒmÑ-¡ñžL`“X(Íê…’.Â
n¸‹b‘Iâ±E›4Í‰X2T©ê×fÍVx¦¤²;Â0;Þc<´|kpºÞ‡1 ÁÀ$ÙÑ"±*JHœvzLdÙòš0€;m°²Ë‡A;“êiE¤Ä"aÌà×ú ÄXm)ñÐm ê©y~ÍÑGk¢*»äˆÅ4
aQ7¬/çÒy²oñ±t+kdJ{'¿DDÁ±{{¶PöÚºÓÐ#¼‡(ª†Y_mi Ù×@òyd‚Óo žÆ(‡±°‹=èt-%C*õs
<Ó·¤¨liÿ­JÊ–noÊD"ûÞtkÛÁ0éož¢1$áéh½D^²0ŽR¬`õv\6QV!/º»G‡¤Þ Bd!µsG¡ÊVŒ3jØ‡ðÖÀðVj…¨jL:ÔU’—Ã:[_éí¾BtAöè\ïCxÊD~'ü€°ä*MŒYÜ(KH•¬H PóÀiNgü¤®¨ö>bXÖbÂ*"º°(‰ ÊÒ¸xôÕÐLÄ¾*#mO$
ÓVxR^b(Š
ókBD8 Å&¨fQ´Á#—Â 'ºÔU‡›¢¬FŠQxz)Xþ Zj4DŸô±†í1ƒÄSàxFgÌë)D—˜07ðBØë:rd^ n+@¿Ï,—àðñ0Ê´Z j¥5Ús;8EöØòi"0±ïaŸÚfCºáÝLÀ„Æ#'±ß'!• i8
†1G¡Ô¥µÚb!È3àyÚµ™®ÓÄ°7w0²É¦ÚÔd—ÊOðZ9&Å1 E:•ÏÊ°õ¯ÓÔZ¦x"º>sºÛûyP<®Ô¢’9ISÂå8É=¡Êw3Ñæ¡ 
8À$“}aÊx*û²,y¶­‚¥µjÃúAÂèi\éÕÐ´‡½ÏÇUv“‹½€]êŸ{’úÀÆlì¥»LÂWõ	°PÒíé‰©ò®µ}X ®LÌv@³Sô¦À¡Q•pB‡c4M´Kê.£Â m' ’aB)›cÜ98^´PjÄðêRW6ñ»8dÄ~mÊÍr2¨e‘­0ïÖ9m¬<¶7\ÀÃÍŸ‹T‹tí3@€Ñ2nW¶ÖÂºŠ@™öBÂjdôB16Ÿ’¯_!@RêŸµ‡¶ä6%Cô¾6ð“=¥@XÅyÊJ‹–å¯Ð:ÔÛ•¼‰&Ú$©Çw.pAj@£™É§É0ÅØ‡oÃÖ´¥¬õ‰r
JÈï¼+Ð8!f¸:$)¬òýäÒqA¹~ƒ{j¨Sâ‘ÒæD—ˆå‘q,žL'"‹ÛÎ‹ë†¤ ŸF¼²@»‰ œÇìÓBI“ÏÇy8dþœ[ž\ú:!m0ù?@L‘i#š +µÞ´
¨¶èKdáÚè³®™	Xßå£PöBû¼ÝZ]d–D ù$õlDh/žß™àÝ(tM™gá9: Ú¤Âù²,hÃiÎF9ìæE] Ä®D¤y@µkÀvõÄ’e19˜ª}ŽÀ“Ñ®=úäE%‚J8iEÌ.H·²˜å3áá@”B"]fç7Øˆ9ÍÅdaÓY*»¦È¤ïAŽmÐIt9ßôˆm »@lˆ8•dZ›Fƒ÷ˆŒVðÙFÆþ=ög›eD}»pÀí’@ŸÕ­…ý:‹ÇÌ‚àMÂÕ71v?{/ÎzÓ‘®ËíEŠ Ž ÄŽo‹£D``åhåTêÄEØ%â½xghƒ!v²ºBFÞe ¹.IH|ØB:¢ýoØïÁJùØWžp«æMíÀØë¶ÇÝÔÛ<d¥€"T!dÝ¾aû(1i3lFï,I‡é)2Ð-CrcZ9F!8öj07§ú),øTN‡´Ge„°ÕUÍ‚Þmíï9„c‚Æ}è³j-‡)¯­¨M U}\ýÓŸžà™
r ¼¨R‘!V£ˆFU1é“%ÑƒøzôrñÀŒ¨‚O+Ù|ÆTžêRû,aÓH£ ä?‰‡‡ñ`¦ôxÊ7™„á½Š: ž	*ˆ­Y/&„’\Á	‰§<ŠG”Y¡8Æ{Cô áJ(ˆf",‹™VHªñMõ®šEz!ËäX…3AêJJ$t¾]—d“wö©fŒepjï0eeš¥Mª¡I»÷¨åœÛ·:>kƒj.’Ý-„pé…	¾Ÿ{"3—@›é0-Ö <8,ñtTM¦“|
?;eÉ?lÍXè®A*Ÿ!fGh¯—8³¹Æ®gå^ÂŽ¡•;dW0ùp‘ÄAÐšPüI.´ hñäÜølú¢¿‡=ªhÌ¢¸ §Ö©Á¨ÔŸ3_xšk/bÚqilnÏh§tx@}sÂ'ªm`Ð*ÕÖì¢5Ül$G÷à0k¤¨0µüÌÈ‚ÕÝ$}°ŽOÈ§cÊ4@æ¨…6xÀÆ„Ð»È¶£e;‘ŒßºŽöÖ¹–þ’ *ÒFÑ0ftîX$Eï%±½h£˜‹µšDDôÖ>ªÂXqsEâ¦¡Í]F¶Îº°NÂ+[ýÙ÷ `—Ž‘±)M”€ŠKgˆ]GAB
`;Ç+,Þ$ÞÀ“[EÞvI– ¸*u‚O†Ë©ù<p[uóT‹Ê¢’íHVÃFO÷Tˆ4 q±‡ÚŒƒS“…öê6FHË°Ä"€øeFv,qŽçß×‹bŸ!Ú¡ÊŠ¬†Ã¹Hó<Êu$Ah}d…(Âd¢ƒ˜4ÜóX`õ†Z0nô”@ž	éšzÐ¬]ö!Š™DQ’6Ú-;³þãNPÖæ &.CÊ&E
¨ò$,(GÑû¾æÂRk«Nàdx)>{k¡aäL@µá‚ó;a;•à2ŠÔÈ#,Eô\{i3—Rýº¾#„ÆS³]- )¢W#ç:2êe¦ãåÂFìKó*Ž$2–i	KàÒdrCËÌQ˜gS´
cƒ Å‡dqßa;<¬àËPŒ?y9ñÂq-b´sŠÞã›¡HõE©=a7	N^Ü‘'è}÷{€‰U_{HµY‡ÅzVŸë|FTvÑ5}ž§|PH5¢	ñ7Ï©EÇÅœµðôý¶±ž©W6Í/µeù2ó@›PY4#&ËQY0OpJKýß—ðäà$’€ 	u#í×¥—t=%¤²UmyéázEÖ¦Ù9ŒÐ9’H‡\éÁú>­¬ ;"ÜyâòÔ]V„¾‚Í™ÁK}CI…ÁØp@&Få€9Pfþã™ŒÐqèà`î41Šh^¥E¬0XQ¤a|J"ËXø8,uÃŒW0¦“` jp’ÕÈ¡wv™“,a^ÔÉ²µO;-*p´Þ yo4“XÛ•˜JT›úâ,­„ª?ÍØ~¦{ç™ƒQÚ$GÎ’Ö†T8 Ï²öèšC&jêï	KETŸ¥½	¼$-ã¯.£0cÓ­Ó„9§cÒÂä˜¹UÆ!ÖGÈdÃ5ÌR@œ@÷ú0DÉÔ\\X·H.¤Ä“I¹¼	F˜žg·eïnŽÁ ™‘ÈQ3j|à…À¯í!%É]¸ø(åh ±ÁÑËÓDNØ®ÇD]Êõiˆ<c­_F,&¬ÂdÖ*êÁ<ìG‘;Ôì$ìHRQA¬'øìPW_»t·N":œ+ã£DHž‹Õªr‚®1”•¯cŠsmTbCqÚë…9If¬Ž¢K=hXàKÔQ±mWvCØ«§Ï<Ô£GòJ¸Å‰ŸœX¹hÆÁ?mŒŽ3ï‘€Ÿ=3d§',¢Si¹³ÏûQgÑ’!h­ÔÎ®ÏÝpÑ¨Øsâ$3ºLypÂ êe0ÍØ:ÈØÀŒÊÈI¢x)×Á»‚ì€©eîžã™ˆ†¡»ôIi^ÂÝÆLTâƒÇ‘|¼c„!—y"´_fËÓ¢wvkÍ¹äoD<„ØåîH —cùvø/+ä¨"Å¬uQ ¾µcÜðÇ‰(œUæ!õÊ¡ÖTP—]†3¡ÛÂ;t\5ƒ$#Yä˜|îë98[mÜd!h£	c²Z¨ã¨%¶aX†õ[çˆÉìmÎ=m2—SÍ<5S²Ž£(kNÒ&þËá_&äOC˜úÁ™Ç	ÛØQP	Ã®Âîû±ÁPÏ/ŸDLmÄ0d›Ä[­c$ì©óèÚ™è‹*Áq@#ÇøèLõtR¸fX<0¸`c/©>bx8<ç;PAspOŒ#»ï{SJ¤Ð	CBc<êaÈCk4‡CSì`>±’AM´¢c"‚	æŠÒªa[H‘FÍ,‚³åÌ`¤ËWucà¥á8nÓˆÎRøý/çUn9 ö—71ça_R€ŠÔC¶E'†ÞÇ(HD%Á\¥#çŽé!–°?o± ŸNO&ƒ)ß,–[¯lM:<g8Âó”ÂIòOu¶A¥³,{¢X-'Ä
Õž†ªy€òâªƒÉå˜dÅ”£è ½LÞ77óÜIùhÌÚo<5¹…Á/‚HHé6à¦Ð4À\=KÞ¢è#ñs}_}ã3Ei&eGÃ##FV‚½0s½YNd0pÒA+ SïOQšfPñUl2 OwšP×$àOÂÉAÒâ5ÙlI £†^EÂoqÜ+È[D©èoä1'BpËJûyq£õÑ1Ð<0]ÑúCtÉàeÂÛ¾5Áí;©NdDàx¡¨"m«lÝÐñxÞ‘aé}Î	ÍgKt‘7=´
ùC£"›gã$N¦Här7|­A8­@SILHM9tQRE˜°©ˆ×Å¡9äÚ<‰HÍ÷ýA¦nú(” Ñ­çDKJ¤Ò5Åj¢/Çn=7*g Ù´¬ºÐµ±AŽ´Ï™[ ›'&³ÃPåœD‰¸ÖQ›ôC2€·›Ö"‘Õ3¢ÄW£É4ž\¹4`šBU–+Í›þsbŽð$á¿KÀqT²0^·oßÖ@%SâIäê½ëújÖÃü©8\‹¶±ôM' Kò˜±á^');€9koR2;…PØ»tÏV'%éš%oâ¸gÂÍ\cj@x'2ï8ØÛ©›°%wþŽ5kéå½0(t¡O™ÛVéQv¤ptí="„æ‹(86B|?tfí±1pÈœ¥È.¼j*%ðlŽuŠŒÂ(@a u÷û™E.Î¢¤ä„BB&B»3ûHË"†"nEäÞºŽ™úè`.çq:¤D<ZÜT
¨QgÚÃèÆ0cUö²4ÏÝŽ$DcÎY`ª0sŸµ4L9×ïYyx83‰^66–eáè2 9*8 þUˆž0çDw¥ÑµæDZç
šRn (àf„ÓÝ"äxÏä†›zGÐzÚÂÀÚ/siƒjÍyj˜–Enèâ¸ÄK—Ì›:íqVâq8£‚“ )Þ0‰8é'‹4Û³.·VP=	9”øštØûÄ´»ƒÄH 3ÂIn6ÝÄfN¦qƒÕ]C–‹arÁÙáÄ¶¾RÎFµ§+ç°å[G©»1´Æo+éžÙDŸ@å­?)ÐÕ§ovWU@AW*9E‘„Ó‚RxÏ1ÒË®^ÁÌ€6VU…Æà2B©À©(\óCÃêMý,œHŠ’92ø SŸÁ[by–ð´ÕÌÆíŠ¿(½iÀ{¨ÄIÍ
Ö?.ô‘Þ­ºu6‰%˜1}¤Bâ;»iL¾OÊ»#÷¡.õ@öÞÊ¸;šÄmMp)E‡¾é‚<:»èwà¢2:ãXðÞ¤òÍ.R–€Î–Ù9¡FQu>-ºïú\Bá‡)ÑOÖù±)I¤Mêðôo¡Ï‹Òdb-D›”gÖ†šbC®V1]}RœÃ3”1µâÀ¤›’Ú’öeSxó3»ÜLØ»F\¦"®Õ˜iÛbÉÛJˆÇUûdôìžCÉ#de;žØÙ÷êxüMÌ`ŠÑ½<;y'F¹µ8+Ó··3jTèâf-¶h…Øê]PÚ^îX†'šòKv)ý:lŽl6¶œJ5$f•¸ñÚ†“ÁÚévïS­w'ŒŽ®'lŠêF8d`¢³‘­U—2ƒËã8FQ?È0\Ã<‹†mÎÊ¥H‚ŸÜŽ;p1Þ£Ä«³+q
˜è-Ë¬þ¥ãÔ9÷–«–u–ma%ò¦®/ªÇZ[d} º #aÛ4Gj/£ëäÒm'œ“C†*û5ÉÆ  ¥Á.æbüR	 “ÀT®ÄVŒ6!žæ	ï®ÕÄ4˜PPopírÑ~ }D&òÖØ5sõ û»$Jæî1‡Ú³Ö
¨
Kr´šó²²¨ÎPU,Äl}m@DYg(›”ªÑ™ù¦CåtH’ ögc”9µÅ‹‰vE?‡ÿW1‹”þÊ§¼›OëÔÎó=óøFÕ¬Qo£ö|
ï\vfÍßµQÐtYÌ-MzŽn@ë¸,J&Ï°¹ÉL
ÐˆQ¡„¸~	>ò:©Ž‚NèYìF%g‡'(¿S
ÈrÎOZ<Q-PIÈº8†mÊ­ð¤e®¡ñgúµ0w”€gÛ E]¿†,WìÀ4h¾l‘‚'lpã>(ÍdŒØZP…“„nš2Ã„iƒIå0@*ª…¢ë¯ÅuòFXÉ7£¦òžH¬âÂªÅËùYVY@äUÑÒ©Î‰w£ˆ”P8¸)ÀXL…ŠØÂ‚†­~Ÿydk•M¯ 0Þéb*yHêw¥ˆ8I8LÍHö»:¦ê¢ ¨ÈFDöV€ëBÙ¡,–a2¨²2¬”#½¬ª¤¸à¢ŸØcskC.#Ð°±UÒy @ó¦ãh >KnkÁA5ƒF‘+Ã]krÂð“Õ'©f0‘ |ƒ¢; Û¦u/	éZ@ :k*-I¿A+‰£ÜYK°x-Þñ˜å¾qt"[ÏÏ07¡5ÐõLŒÑù´,ŸÖ­§k“zSq0Ú^|ºð$â¦36Š3OŠ{–>à¯¥3ærŒYÏžJ„˜9dhü•Š(M‘^f@¡Ã7Ì ´P\Mù4·4_1©/²È™±ûz1q·ÚÁ€†“ö¦þä'ÒKSS!ïñ
´ê¨„ÀpY/z¥„ÙŸZdýË¥4Ðùöx`/¯9£­.¡c']ç×.ó‘%û®¢'
“²ü¼ˆ$›ýØIz@7Cå6ÕRÊ!‡dÍ'‘Y¼¡vqÁœt¦ÁxàLKæƒÅ›ˆÈìÐfƒÐ@ÉIàFñ‚¼¥^é!7 )5ŸH?ü¸ŠƒpÌy!3’LlÖ¹àŽsöuEKÎÖ«Ø¿’ãLN=d —L@r…0,ƒÒ¹çrCî‹’rGs>i"Âôfzå‹Ñtà½DÅ©å™‘kå{U<îªéTî¸eýÒ(IÄmi-Î²+\è…ÆÌ§ìŠ ùË¬¤:éÄ"›öÄy™1_\çúBˆ²Ò­1ÖIT­x¨<YÿO%~×#d|N<§jrÁ+·$‹`^Y?äûXª“£nAeÔm(Br£(;eÌqë}}›u\©AŒqÌ:j+QåÕI˜;;‰&\ä2p×ŠDØÙb—|p¤	çš·ƒGÔÒsoÀ¾v¶_Þ§ŠŒ}Ê¢d399A‹ "Ýgëê‘%ÎŠ[¦x¦‘¸@|Nq^’¥XÌ«˜é¨s—`ÐuÆœPœ	Š¿SPÿ¤P˜XRþ«¹*‰Í¢o#å©P¡ríy“4Cãû,¤ä#Ë§¼÷Y‚´WB”ÂÀßžX¬®›¥—áP<e©BÇÙ[v.ÅyÌª­té®˜.³ž Ya"¹§,LŽ¥&§AòþSD*}'§¦”NÑT‚î³S­ÄŽ .-Áî[/Hƒ¹ŽšiØÈF*Ç¥þñˆ¢›Äêå…Ãqlà“d•¬®¶Ô¾.k©KÎ%luL³š¼)ˆŒx¦ŒE—r*Ôø“v
ÓyÕbömNJccÆÈy›æ¶6¡M„Ð!
2M8î¬Mù=“Câµ´Åp\°‹—
é›÷8 ÆõjŽ?Õé¸aƒ–†\ß4ì‰»ƒŒ”E}ý´¡9Ï#· ³ã$pƒ0— ¸kRÂƒrÈô ˆd.äiq‹ÒÐ*#¡öLóRgN‰OT ¬ (é³_•Ò[16ŸèÀ5¼Ò‚l1—†ld:¬Ù‚o6°B›W¥Î(òC§éŒ1ÐØd—Sðê™
ÈÕPàž]Nï´³v„°ì¦ü V=Ì†}¬ªe¨N“kæx*·Cú}$œƒ(\\Ò‚â²p/å s´;r>â¶ìW¥˜#’ðè²ðYˆÁ†,ý‰‘ÞLD¨X¬fWd}ªù‹d"‘\jóH M#±N±û=ž°ýMòË08 õ¥ÁªT*rODÚ-9N—MÙ¹D÷\’…¥J±~‡Ç;’9é²†©Øý¹…[{²Îemk´Ï5SÈÝßA
n`éÂÈ”šë«>cµ¥uiÔp“Ù©ßª(§‚øŠeT`Ö”8d<)M•³Ôf§ºƒ.á‡“ 0µÒ©L0ÆMê¼èþÂ”$¥cÛÃ@Ç48ƒR“¦(lIá$±51ãPEã¨úªÄf¬Ö€6G¬Ž,ƒÛ@Utž²âa­PÖQ( E@t%@Œmµ€¦„»c…1•Ë–š.E
®A‘Êa¦>¶.=]µÉhD6 +þµˆ,ºp¡±Ìˆ'ÅçQ\Ýƒ6PKI'd9(™·YæÉXþÒ6ž'VåVþ›Ì}ŒÂê†zÄ˜Î	l†C¸¥Ð´8Eé@™œ;±» $Ëè0Œ£óÈaÈ©k 0Ÿ†Åb3,3‰¼2©È\‡~Pð1Ùh¦mN5 WA&Ý#H§Z×‚¢	7Jª3¥¯“ÿ°Š‘XàFG¹(¯UtŒ€fJéh_37Í0ãÐÀµêj®¦TÒ¦“
,¡‹7xúq^0a3*‹É‹sÙìüÈNžjSÚ@ÖN00Tëd1±”4»¬Ée ¥ <öÓq±?X=Ä‘áSñ%/ª/,[ç¶¨—­·À’Ut
áIFz±!H~8êl-¤å+]EæÀ K	¯VFÆdÑÓ8€Jñâk:A	R‚Hmº#ÙÉô<ArBlp^Ž(Î)µÁ«J!¥i´}UŠ^r`¾•B>w¼bß,›5tIsCª­á•)‰¶Ó•N‡6¼6(-ÉEŸ"Á§ê¤eªàgây$ÍÑJðÎ2ÇÏÅTÚ·oÌK\ê×™y æA)Žâ™ô«†6GÔÜÁ¢‡NÓÎ5M$ïlÅG
Î-"AŸk:‚Z²˜ÄR&¡ÑžÖê¾öGµf°[xgšŽ/:‹uiYÇìg25¨˜\65>>Q§PR1 #L56-;€ê`Ì4^]q	LÚfDd]v#'ÙÝõtê…Ja«Õµ·:4×Á~ïaù}º™«ŸŽ´üV¨÷Ç&Š¾Ô)SËZ?¤rvSªÃîG~´“­+‰bÃÀ‡~Ü3aùzˆ*—Û¥®o€Dv‹ãÛÐìw[Vüäk4¡ñY|žJyZ–Ç£épê{b8R¯T™Ë3	è):S-´tûš°—’]Þ5ÿÈñ3*~R4išˆ %žõ‰ëì:¾»
e]Ðè±„ŠÖãH2)˜FâqÎ,¼fä°ü Š)Y*r]ÛØèšéÉ\táAÉ¨àähdxˆ9:SÇ¨ùÉcn5£Õ‡-Œè¶R&ÞKÑA2w=Å­@Y,‘’|Š„%2Jþ	Í¼›'$>µòZ¹ÓW’NÆ2Z`ërØZ¯nñ…Â’S‚L®x7Hß«@A:&…®DdW«c­Ëâþ5V×Œãí!Åõ¢ŒÃöœbþFë2*8³¸Hü8gW1¾<j©ƒvæý6rï^*˜GL³î"äÈV)@–IorÁzÝ€1½ìY7Ò9CwNþ¥‡ c¯\Fhër}X!ig±Éæ•¨Ecõ"ågÉA„øB3J†t‡_gBC˜KX&Fp;~&ž ®ŒJÂbÓ–Žû¢[$S,,h"¿\.1 Z4!Äü‚ŸÑU€UP€UMÌº˜a­žæ^GªoO)Mƒ#©ÉvçØxf\¹#
·¨Ò3Ìù:ˆâ4&XC©‡7Å›r`œ‘ÙN(íúÕ¢Þl²ác½³T{)t'd2óªæçàµfíîKóñ’oX„_PÍ šÀWVç‘ŸÙÔÇ.$p_Çóc×÷s1¦øa_¾SÕ‚ÉùplôšÝ1H¨wý†Öù]6²MªÅ-³„ê©ØLÜhÉ4³Ñ¹÷ïÄ%©÷†#(Ä%ÌZ– è´"Â…$¦âF eI .#6H/R2±{Ü2¡áŒJï$8œIÜëîAWmªÝ=õ®spÐÙ=úQ½Ú;ÀÔþÁÞ†:Ú£ïÝ?êî©ýîÁÎÖÑQwS½ü1èìïoomt^nwÕvçÞœôïÝý#õîuwWía÷ï¶»êð¨ƒ/líªw[G[»?P‡{û?lýðú(x½·½Ù= ªÚ0:½¨ö;G[ÝCœÇÛ­Í®;'UëÂ´kêÝÖÑë½7GfòÁÞ+èäGõ×­ÝÍ†ênQGÝß?èÂ ï­˜q~ÜÚÝØ~³	si¨—ÐÃîÞ‘ÚÞ‚•A³£½F€£I[Ý;Núßél¼†¯—[Û[ /¼VëÕÖÑ.A°ëðÌ7Þlw‚ý7û{‡Ý–bB' ðƒ­Ã¿*X ößÞtLG ]èc§³»ÑÅ±œ5°M¸\õãÞd°îíM(¨®Úì¾ênm½í6°%søf§+ð><‚NƒÎö¶ÚínÀ|;?ªÃîÁÛ­‚ÃAw¿³u€PÚØ;8À^övž´8¸Ü8<¶uÔ2SŒ]Ä î[Ä7»Û‰ƒî¿½µ"–(K°ÿÎ]´ƒÁ»-˜îžAÅˆÑ Wà‹?Ší©½Í­W¸-‚8{»o»?.T Îe;/÷0/a"[4˜B	÷m³³Óù¡{è`ŽÈ%Ûu¸ßÝØÂ?àwÀG@€mÕî!¬·H'ª{Œ= rò>oà  îjÄ±ñ™;Ùe;v)ÕöÞ!b`°Ù9ê(š1üû²‹­º» (:c7pÞ°¾³9|'pk—w×KG|ë`3Ð‡ŒðöUgkûÍAñpä= !vIèì·8¬7Ü|µõ
†Úx-Û¦¼£ü£z[ñ²Í:›o·è8Ê80É-	¬Žz82ö=mñÝ"x%†ÁÀÃR’ŠË¼úÑ31Øpè!²¿7E>8ÒÖÞèÇ‚Ï0Åbœ¼Â•…%¾Y¨ð„Ò¥8D8@‘0º`èK¸°þÏªô^ˆÎŽå˜zÃ”3A1±å#Ý‘hÓ:ÉÓ!æÏSád?PFÏã¡3÷
›‰#ƒÙ@R/7È&ø€°éÎì-…Ÿ)º´¸}±¬kÅð’öyÆ„öóšïuêˆ8œëH‡–ÿˆ,o„U™@îxä^Ò.ì­Ä:œA®œ‰¬ã”òsàÜ©ø_¦y!·´!ž‘|Â5Œ0pïŒ,ê&Tübñ$ð¯Îfqˆ®ÛDÓ(ß'á_Ä«oV5þ%­ëKÒ(F¬AÕ¡­øªS§Œä¯c·È‡\ÎØ¼=ÒA¢âl
"rÂìù¾–Ü»3 ùK¬™NUC¿(1õD]Èõ ${ëêo¤þÔŒLSCeYÌ"jœ’RÇö]=g05µ]é*[”M¹¾GpÒûºÆ›³þû9¥I×'YÐƒšâDb o½ªDZÊZÞ¨«ï±:ÝºHuúÞ÷HîkÕaÞv¯›ûÆ½MŽ'Z—çU{çJÉaîé’ð3[†oh5¦dZ°qœ~´ì§›ÖËšM« væîª3t/è$ÒÆY²‡íäª´¨jq9ˆÙž™¼Z¬ A}iã§%VœvU”¼ ¸³/e¯Ãˆ5Aìaž®]¬&ëªQèpñÚD6û‘u³;–ºrN-2KVÙ1ò!RßŸM&ãõvûââ¢ušL[ivÚÖáí0¡†îaÒ[Ú‹ˆ0í$û7_=N5ïÑÎ—¥	VÂ»BÂ1F®ÀÚ\F9võP‰²ºÆ–†¦rú²•á‘M9£t+-Š²±0ì„ê6r±S·`/®‘”ÕïeÜ×>‰%<äÒÌÓÎËÃ½í7GÝí]Mæí©l§š\‚þÝø~q¿e»+žgË:ˆ–GC‡“Þñ¦ø4›¤hcIxæ×»ïN€–¥³Ë1šÉ]¨Ì-„z~4ó¶àŸ¾­ÞÍtöÂÎ°w*µ7 AÄ8¶-ÍÔC#Ú¬d¡õÚgÂÝx³e«Ë54¡)ÙT&À‹“ôcÍÄMÊ”)ÖC-iÔÎuz‰b¯¶· èý¢¬N1]¨ßáàëÖÈë…¸˜F+ãÕ¬ß”uÇ
+æÎWÆ§î¾ÙÙ¹V’%4| Zµ9Üxó6Ò`á!eËáJcL>éæ"áîWÛ{©õ¹“+áÐåÄ²ý˜‘\ëu)Év\ö—ò:ñŒ0˜<SdÏÙœÇmGWÑDÌrgŽt®íY|Ž.t,Â…„àÕÝ:n²a`Ù,ëF	Ea¿Â[ƒ%u(ã£‡)Ch*·b|ƒ(ŽÏ.Ûg—M ssx:¶Î&£!ìÎïþ?ý´×>èv6wº­Qÿ+±²²òäÑ#…ÿ>}ò˜þ]Yãïðy´öøÉSµúpíÉêê£•GŸª•Õ‡+ýN­|¥ùxŸ)²˜JžFsÛA³Á`Îï¼eþý'ùÜS{o6ñâ·(8ÂËžû(‚!ÑVnuôv³	¿w“óÿýý¿D-åRN2…Ò—$T™Û@ýè%Õ$JÎcØOƒ„töïè;	µÓ’Ï6D¾Ñ©¨QghÆ`¢Zæø"p‚:dX×~Âåá {[›ÞlH	Ë8ˆ	ƒÐ=
N<™j×)ë—º^,À)Ú¸bPôá†¹š«'™'sÚNŸ¦Àë‚Õø³Å4ÍP¼£ènýHÝŸ ërhRR¨º5…oaöÀ¸©ÁèÁ™å–Ã†:èl4¨ÑS,+CÕ‹:ç“é``ýmqbJz)eI»9‹ >ô@#Í	5—ð›_¦ŒùàA:íÃ¤ZùÙƒ–†¾Í;Ä§S)D%N²b5Mzgl†ˆ±L‹¸×%H]`pC®Ð,§ž8¾˜SC_</¥QP©…œ¿ÏÕëŠX„» Cnö^uZ¢ ë¼jx~>c—(¨ÄÒwe;N¦ÕÛÿýþß0+œãfÚûÀpæ"F9óñI„7¦ìÇØ”÷žÆ úüÚeûp’E“Þï
>˜¿—º·eÐt4€]ºw”Ét\Ø.·âÑè3¤`“Ñé²dt
wÁq,?á¶¶°&GVþÊ"ƒé]{©38ëc Ãûýÿøœ~üþº[ÿ¯¶ú	þ=îõóègÕž®¬¶ùJÑvy0Õ<ÖVVŸ6WW›«W­¯ýqýñúŽÖña6LT¼º,~ZµÒZ•Â³zÛÚ}µ§Ö) Ck9«lÄÄŽÃºGXwuîËor¾Nº<‘Ÿšgç?ÃOÔ÷{pl·»Ç/;‡Ý?«¹ý)x#6olíÂŠw7Ì«?5Gæ·×{;Îó—ðüÍ&|ßøë›}y<w ³hžUZèèCkVË$wPj>ê‹º;ŸÝÜ+w„¡÷¿E½`êöæ<W›šÒ´Ô²8":avJ/Z¬ÒÍjÑÇ2¡:pÞx`lóã¢µ¤zç
ÁµèÎœ…,÷£AˆÞ½%ýk½µhˆ>.€ª!È5P=„f]àe}ÆO ~mÕ'T(Z GÊ„ËõT!Ç=›itÚâê~
ç‹ Ña@€t¼µ[€8RSgqÄ“QÒè`(è¯6ýP¯-±â\.ñ$ì}˜Žóª1ù§ÅƒÆ<¨O=æJt‹îÙ¬Öü¸ð”WQ§«f_tíQÜï#Üõ…cHßž‚n§§Ä'×U{2—xÜ0=E&^áL	ÑsJ·‚ÜÅ3Vÿ€‘¿qégÞkž<x „‰kÞKÌKs¡™…ËÈðv¿úíÈ¹¨e-ŽqlªÌ‡/nªãš7Áú!‰vÀ
¤o°u…±ŠNx£R¾A©¥ª¤‰(9]‡‰¬´Aúhóc/x&ZÀ`ù±RÂ8G.Rè‰qéQŸúÂÍþcse­¹úäxueýñ£õ•Ç7“GV[+­-‘ÜÉè7_f¾¼‰Ù…tc<€óp8ò¹o¼ÉuX”õ2Ã6©R®´9·'—U›Ïó"æw¡9¤û¹YÛ{?ÌèbµÇtÞ»Ý£ã½ƒÃ·É‰Ûl^ØÙ¬‰,z×°ñò»ßóØ„3¦!û{°üÔŸ5ñÈkìŸ¡ØÞÛLƒ¯ƒAû{›o6ŽfÂ_Wì¿FWÈ·æm¥tÕŒ.V×Zk­ÕÖÃÖÊu:~µóÎéü.:þKçm§0_î8ÏÚ¿€NØþ¥ÿaµõÇÖÊñê“µ¹=nlí¿ú·Ý2æÍ¦¡s»¾†ÄV×ê±s_Û g»5XhÆs³C1žßäŒK·FÆ½Þé®~kÑQ¬z«Ln1ðâÓTýÞ5ÎQõ‹×# ×{Ó÷’æÇ‹4ÀbÀu^ìœ„'”¥HµrŒ¼¿Þ‹hÕÂñämýõ&]´Ž7»¯:o¶ŽÝž
OwØýH…<)£…GòèT£ÈÍmú
=|7
Iý$úˆ¶R÷	có„yCº _’ËDyk­óŒ+! ¼oÓøÝãq´.çañû1_Kç=†ÝÑ ã“v §²`yÀ!OÅþ9ìÇ÷;ÍÈ~íiõÝ'-ÿšnGéi–b¸Šß¼G˜\ñ„ÿ9Bv¸Ó_Îè	Tžÿg|1Ìái>jIíÚÂïšÀfù¸ð  ’UPzÅ_`ƒõi­è– ‡mÆñ1Ö’háƒ¹˜x±û—Ž¨0õµOä¡~q‚o†ú^šEn'³…¤2‚ÍUa4ÑïX ZFRV¿m$”,¦z»Þa÷fî³{ªðÛ'›<ys=ü¦ä¢4…A‡jQ››pßi…h—%÷ÔÆYÔû`AB±‘8˜ë:GüOª¶ôI7»ªQ«©ŸŸQÚZ µh°J.Wí–në¶RªUÕ~‰†$õÎRUëì "3:z:hN•oâ þ+é³Æƒwåž±s" ÿâ£çµ–r–Ð^ú¤‰>ÛÞÛèlÓ/Ç»Ä£¦5@ ]ó}pû^ç³_³v¾þD0ÃìŸµ³téƒf~›Û¯”ñàª·T»×š©¶q–{ÂpNè©R/fëÇ‘NäÎ'ÑXÊ~ÆV€ô½4ë—òÏ@[µôŸ,¸>h©¿`[ÙNDs‹bp32bDø÷	‡©=0æU!L3¸Ê×@ñ¥Ç$PöÌ=)kÏ;2tZô±¹ÕÑ¹éáY¦"É€ªÉáYëNÉ¢×uîÝÃ“Âº“õÎâID>Å xyiì´K]è·iîXÏÀ5P±åJcÆ£:ÍùÒ¸‰T —kEÃÀóÂ±ÜÜž›*ú"v±pGÚÂM‘q6°ìË©ãTõŒµ-¨a{ Þ7MªÍâ0ÞÊ¦|Çœ©âö…kdï°ž!óZœÐÍ5šÏ«…m:…À[¾ÉÏX„èZÜÜ5!b¤ºsuîIÙ8[oºHÐÚ‚ÛP,ïÒExqb’|Œx`ïìQ¯H 9ß3[Š½p	—–¶§Ÿ©Uø|V›“l‹ a³üQŸ‹O°¡%ßn:Ñ¸ðEI iÒ5ˆKöq»…Âœ ê‰·bû
Â[ë¯©ïgNe‹$jWaåò´4S9LzBhÞööT*4e|iN~}€·7;ûô¸!.þûðp[™z_YdÃNHý‘	ñD=‘²ªR °ÃTWO„9›²™£^³²è²áÔqgõ§r÷„5†ê˜¤´úú¯Ð7¡RÊ\,‹‚þû-µÚÒq¥e@û%c„D®¦ÃñU‘`í@bFžZ„`µsÕG\¢=tˆÇÝ¬Ñ_ž‡q½²´‡ôÓ]-€…wN_°mÎ¤ý•u1ÿƒg`âá1‚—:*ngÑp¬–Ïê¶r76YŒ½#š<§ö¼ÀY€V´Ph Í “ ±Z¥µû®Üµ–µ3s«ÛO@Býx,CEj°®[ž§èÀÓüÌLaÓ±7R} Cf\–W-?0T³±­(,¥§¾¾ô’MMƒ[j3j88{ÄY¿	¦í3ÕÙ{ª¬„#½F)ÉwêÔ«ôDÌ©»ûV½ÕÌ¸@¨;„Cæë~8™õQÍÖf6¬fw•LOÍiz³FÜ†vÈµÔë§'fÎüZt¹U®ºÂƒL…LøãÄæ¡«|RÜMÒÝ¯_2´ë<Ç¢&Z<åŠ¡!†Îí¢e¦WrÍ‚Ìjcþ$çNE7MNµ$Ab•'Ä6<Ó’+ï"ËòeRÑ)@
Gä’»zƒ1ËÄzÐJ‘Xä+œq¯zBÐ²0¬Å®ÞjYÒä	ã†>d½¯æ\½ñeéÌRñÊØiî>ûCshÆxs é¶ÍÓÒ;‡é„:%Ê_u¥”ß. »3"Îwöª[¡fvv@¼¬om ­0ÞSÄÀ,:eTp¤¯¼eç+dÁŸÅg„bƒÀDàtÂAfM×Ý¥Yó¥Aµ“Eüv;€ï<(þàê7¬ÛøCÍþTïÇcáPú¦¨ªõÝjPAÝªw¶éTøT¥R9ÞÞÜzEÈhÓƒi_¸ýô‡Èu¦ç6wYTˆ œÙœ/<¨òTéÆ`òû&aýÂúÛ÷AÉgu^Xk=ä)Tºˆ+×]å5~ô¨ðÎ_àw&ª:„ÊÐ=/ˆ€–ŸÐBc—£TÄ”•g6ƒ£xª¿Çjáö•m•¸0ÕJ¬_SOú)Í`so§³µ[ã¹§/½“Ìþ|Öb°þz–	ÉT5ñÄÚb¨ î½Œãã3F3§ÿ
h{óÔDgKóÚ3jÐ<¶ªæ Íb*ÞOUÓmÃ }Öö¡Ù±’ÅÁ+Ù8>\<8PrGßN¯72)-o­‚b$ý“Ó÷ä–ðkkb<ªÌJ%+H7¨Öxw#çßLfw S˜Ính«ûêŒ¡™7ooùlÇ¬\ùÁ®“ð(ódÆ—:/¹£ýw›Ç¯¶¶«dš}})¸QUõõ4Ð¥OZÎ¸jû;>¾è·&ÉXà6Òyü½ƒ£ÒØ<¾7™¾œEˆå¦f:âð¬ùY›Úâîºû‹æU´Ä-îy:5¶¾yÉ.VANÚº>èâNI9WVÝñ¤xšr¡ß_ÿ¤0+8[“?	ÇqRuô±áÖm¾9[¨_ö m„³´œL±G¡_¿Ï¯Ø.Î©ŸÏ!ýÆ@·WÂœ¥ùWG‘·ÙÃÇÝfÕp§n]<ã mnrù‰÷’oåç,9ª³"52b•÷œBÛlt+)Q˜c™~©ÕBeP\æIÈÊÅHÐyF^îÆN¦¾×”â…?q¬[Š¿
I¶?ªZW9$ÕýtÔâ¹œ„aˆh0ü6¾½P)Èæ@W«ö)ÝK@ŠwZiÆN£kve96}Î@Å¿]¯OÉuÄê¶c@ ™ão×ëÚECgÒæLúƒõÙÑ5áiÔÄÇ’4hQ<ÔpL<7u?ì~ŠÝ’;ä\N«Á+ÎKÌsËðAìñ<Ngöˆ¿¥ã(yÂ!º3)èg“Ñ[Õá¦LÉÉúÕyRwë\	}sh•6 …~5M¸°¹áäKi¸ÿïÿ±|¹¾.‘.yíÊDHËñXßoww8zýB–O¿]ôá¯R¦1IN™›‡@lþÿö¾u½mYpÿ®¾/ï€£dÆIÆ’x§äõÇvÒžvbËNzºÓŸ‡PV"‹‘rbOgŸeìcì¯=/¶U H‚eù"+N71ç¤e(Ü
…* .ªÂÂ8 î8æ‰ØO.µ¢Ähò
ÿŽÇÂ6ÈÞ±‹ŠobHGýø4‹ 7“EÀÈK©×ÑqýÿùÏæÛ†4…´³æ2Ð|zâ~£xÂ^-¥5øÿ»ž&?_ÑÄ»·¬µ!kk3Ú*ãs3m€¿#Î¢_œ"F9|<“zWA§ÍäDèË óŒä|ºŠ‰ål~ï5á¢ðdÇ#ô&¨}öùñÁs¬ð|{ÿÝ›çìj÷C8À:•m¸¬_%0±"ólÏü ñX)ÉAÊž’J ž¦¿’Í,œýðÇ§ ·æHo"…—¶ yçI^IÐ¦ÅpÍR£²÷3œ‚üK™@{ŽÓÒëXRJPAÊèŠÖÉžÉx­ìÕl“¸“QöÂ&‘·"ŒnðÞ9³ÄÎë§sÈ:Â—‚Œ‹’Ló<„
£â4Ñ'Å‚ )NñS¤ 7!Þ×c¯™4_z#‚g	Ú6çšŸŽ[ÌMB†ÏÅ‡üTS%ÅdN˜|cúëöî¡ú=û–Ä+4Az À•FŒ|
€ø!,~225¸“Õ¹‘c®,‡ÝÆbOgÏ°g©pW¶W›d“+¡°©Db'täÒ©–”,P#Kd7ŠÐÂJ(u²3”iì¹Ó>òŸOÃ5´… æ²ÿrŸÀIt³Ô+FRJ„q!¿¼‚ÿNÝ5|Ç(_¨XŽ†qOÑN´Ñj!J6û¬ì¨³cáœm1MV+j=Û¨Õž“_v½|žA‘ „ôtÇvb(ÒâEŸaõhê¢Ç ô¹ÈroP¿•ž±‰K\¤%åÄ“Î@Š˜ùË»Â£Ò¹ÞTšiè˜ÐeêZym©7½˜»Y‹æ¹pÊœ}m·/iB¥ý¦`«î««ýÿ(Š¡jÂÿnÚ¶Šþ4Ã¬üÿ¬"ÕR÷rsÎ_®±çžÕ®w	QžŠêœmÏ´™NCþâ)s+‚ó~Å¹K'¤î|í•ø:‰í1ãÍèÔ¹6ìKWô¢ÿ/Û´ªý¿ŠÔV¨cÂò´=×Ñ©Žû, ªÞv}Eïx¶îû¦ªú¾Nþ³Ùšµ³]Ú¡jÇjû¾fºmS5uêëV[óÃÐ:v`)¶bºŠ\;³53t/ –á8ºiº†áØmCµÚN[5Ú®íXŠ«kßP©\;³Kó=3ÐO¨ë9¶¿,Ï6¿£*ÔwÏ´À¦®+ÕöÔ¡ŠÖQ¡*tOÓÕ@·:®ïR„ïÙn xºÚöMk–u¨£«ší¶išªÒÑ§ã™žo«ºóÕq­¶ÚéXA€0N¢Ð7@úŽï·­ ã8ít<Í6½­¶5¯ÓV©'a±qÙ2.Ð+T?p_÷LK1 YÇ0-Ó…#´í9žiÀ’@ é»¶êØ¦ç¹¾am30|×u\Gk[Ž¦i¾æjŽm)Rµ¢Å]ÛSUUsÚ Þ1UXhÇVÚÔï(ºÛétª«FG3Öò"{2WU]èÙö½NÐ±©é@MÂÖÜ¶xŠ£–¥šyXå&q¦¦Y¦Ó|=ÐÚ¦bT1ÚºãimfÈ²øì·}{ÖÌÚ*zàyJàzšçë†nRèfÛQÛ²]¥mSGUü 6Æ,(Ùf[ÕLÇ‡)65Ë À\ÛòMq,UÓÇrçuˆ÷Å¤FbjÛò;]	TÃtM˜z€®ZpÝ ¤-"Ùþ™žiÂV¦
ÆÔ\×Ó‹êž£)m×RaÛ®¡ÍŸœ[âÞ°›bá€">º0Ç&>,‘îQW§¾;Óqa3i†î{ì°R`³&mC±Wƒ™Ul a€Õ^ÇWS5<ˆƒãhzàxÅ¾I¦›Z[SLN´À3>¸ Œšð¯¡˜mÛ‡‰£øvavòv§. ±cj†¢k:¥:ôÈ%h«ðWGéXš­80ãNaå-K£³škk¨¶A]§ÓvÝNÛRaá©ËäÚØ‚¤Ó£Æ•pj
ÔR= Sª(8ÍSl†ÔÖTWýáØ†í‘§ ™‹šèa.4OmÝéžj#•Õ>¼v\
¨£+nqr™I­¢ž«ÚlÑNÙºHëãºŠU`·º©ºìµm{@hi§¤‘€œ„a|‚œ0uL˜x DÔ€PQu4¯­pJz0\ßÖlW÷<M-‡ª0w"{âƒžšÇmSÛÔ:žjØ¾kXÛiwà¬P-<y]W:Šï•ÃÔNRÿ9¹ñSj) —Š¦y°$NÇUáÜvlê¿;€ÂçY6½T6ªÓ	Úz'°hÇò|¸‚Žj:–î:Žgçµ}Õ¡æœyÕOøEÞ	*Dž„A€waì¼x€Ç&5€žžŽdD3íóà4¤–£jH=³¬¦žp³’áàï€£Xe¶ŽžbZÀxPÃÑ:œ»6àj§p€¨ ÕV< NSS+ÂÔgáè`†¨I-×@2DÆhÐj§¶;Šømàkn4|6¯Ôk0^Ûs¨˜pNµmŽÿvøU³lÃót$Î¥€UýDz8:NõXgÁhû &Ž_q¨®S­ÝÖLÛ‡]kX®%4ÅºöF@Kðds=Ð}ËÕì¶ÝV:Ž¬•â«¾TÈ‘êÏC>³zqfY?U]·é€î–í¨¶€åkU\8à 8µ;–]
St’Ÿüã‹šXx] „h‡æQ‹±«jÛ:°Ð†cÁ–(G'U+M¶þ Nq€x˜pâžì™
ÀÖ¾L³`ÿv,·|[©Ê	÷P(ÃG¨À¿¨´-Ï´´(Ô`»vð$„Ì„iº¢:Æµ×ˆ€:ð‘^ÇT±6ì09ï¶ÓÑO¤ æG›G¬JI çô,Íp=v¹é:”Šâù ˜Àû ß¢VÛVGateÈ½Ý­7½šîÃ\ßqpt0`ÀÚ8H'×€ÃÕM@~_u“z™ÃØ¼p º§À¤wàw4G¡€Ê€qp2ÛÀ¢[IÍäÖê*¸/)!/tßm ÜošóïÿP^NäM×Aþ‡ýfþbÞwÇ0ýÁåÿ2hÙm,¸ÿ1tEÅõ¹Á0@¾„õ7l]¯îV‘_S‘lñýéc’:ßÄÀ‡è²·y-ö8õgÒPO_l÷žAžCûèE:Š'NQ¢uÖ	°ˆy'UìN¦ýþ:é}Ä—t‚NákËì0ª‰6yÚ˜1–…ï›,>ŒøÞ‹i€Öìœ<iôP@^“ß‹ÿ-ãÇ»r¨½ãâòÚðq…£¤it‡ÑTô¦Ú†/,€0òø…uó`:Áxž¼,³”VÎ²n"'„³=)fsFlxï¢™e¹Ñ1ÂÉ%®jÃ`ßXø` …ÅµôŽ÷éÕÁ^Co*Yê"¾ÆXêcè(‚bT½˜GNÆÁ<dÆPø…YŒÍ	ÚÂß¢¥v°‘x·+¸ù¹¤Ç$1yQçžùÔÏlHégd:ÜÊ-qêÏÌüò3hÂ¡¼ˆE˜Å´!»èbB¹þ‚/\ºŠGõóLg<à‘^ ‡¸ô†5q¹œ»Øhò6’7ïá„Y|Áç‹ˆºíû’’„Ô2‹ŸÃà±pgNŸë9îíl÷Žö_ïþ¼É#Œ>æ¥’`|y«àÜœ°‚³NF…ö6/ì7sVë9¿¢›AsÆÂS‚‰:šW”:”ËÛc
`(oÀ=å&|}Ágn”BË;ô”º–Sg-íß¬q†4`ÙÎF‚*jÃŽ¥U‘Ìfn 0?‰’h´äoóV ±.ƒ7kC%ÁC‹)¦SÃŠÎº’•älõ
mæ}5 cJ„7ëV†‡œžW0R¹,z®|Ì o‡ŒFÍagt³ðì.M¢XåiKÄc…6—JEÿZºÁ¿¯¤¿»¥Â“Ã½´q5ÿ¯ªš®¦úšÉô?l­zÿ]IZÚý%€y2ÀCfÿóNÌ^
GŽ‰Ÿ5¦`Ê,>%ËŽ"GŸgÃ]éŸ$“†\œÁ(Qµ,zÈI¢­
·"ð©’nÑ?væö€Ý–qfV›7i·×Å(v>ó¹|»yØ}‹ž§–8™\ƒôÔîÚûéßÞŸn¼ÿÔ"¿pw…	kùåW²–”ôüÓ.|ÍØ¦/Ù§›¯Çí¼¤nWòƒ˜eE63öør–n±©ÈW,À]f–¿RÙÓÒ²Rá|`hÉ›•Ý¬Ë…9ÅOÂÅ·( 'yWRKN²<d'¬fšÍ&q÷Íün¹d,±µÿæåu'„¯Ä«ëY’¶wÓåM…‡/BˆZ”’ìüÄ¬ç æï3 Ð'c\Q1zL/Ñƒd-às~ó&^*›Ët£
ÓÏÛoªÂFå„üóÅewýl0çÉhm©tÐÖŸ3ÖŒ(L&2]Ùf0ƒªt™Éô—7¡BÕŸŠÞp¹$‘S¿‚RõšŽhMøÍ›§v×<ŸÈ»ù»“èÔ‰¦g¤á‘¢º"Ñ¾oùô¼5š‡¿õÑ¯qNêdÿÇúoxBÕ£Öy¹¹»·³ý¤ÕJóž@.†û~µ³ÝªG˜Ñ&i°ÀÊyÿ”üi˜9H]n­NÞ?#ñd0Š•ß>;“>¬¸’ön,:ðòóy0ÛÑß<8þ’F ÉÝØÜÞæøò[„èÖ˜B?àäÿ¨®«¢ü¨ÌÄ¦à2 %(žÜž$þäâþ%iv~'ü·
çóy}ÚT÷—ëÞ#ñþz°ëä;X¥É&M,&Òðlt\*äÎ-Å[ÍŠž&%%:ž}”*€ Z^R¨H¾¤ò§sËK…†WE"—•f¾”X…ºŒÜ¸5êr)¤â³¥ 7W
‰úl)È•KÍ–¾†n~Zs3æGÐ‰Ô
»ÑHÌK	ÛÎød2â([c7ñÈéæp?a\þöR÷FÝÌõÌkf¸:©‹ï‰oÆÅ¦vÜY'&ö¢Äh»Ñ`'ßñnpMdä&G!úJÀÇxæ/A:/î1ÚW'é‘´6é1›Ni?¤)X)¦ßÆü;†ÒLnÔ‰_2cÈä#ÀJÁ’¬a³»6Œ0ÄSó9tÎ‡á¤ëLã0-Ð]ÛCWW{{›G;Ý-‚…!ù1­i¡òRnú=Ã¬ôœKÇ8œð.ãIšñ¬²þDCQgö93dF£è<I™0âå»–y†žŽù‡é8Ë,æÄÐšÄÐÀšÊÕ»±ÅÏ³êôfÕ™™¹Tpêf $TÎ D7ƒ‘Ù¥K >v×rFá_iË²Æ§g_·3ðúpæL.’nÍ ŽÐ‘è7Ãóï`iˆ¬ZòùãòóøóAØ];äˆ Ðí­¯ñkèý—wgQ«{ÝÕ¤r5ïå¶±@ÿC³M#Õÿ°Øý¯©Juÿ»ŠTÝÿ–é€Hßà5°ì$¡º^Œú6øÛ¼¾Öõâ×¸>#ä1wÙëÇül,qðwK°gXKr‘Å‚–ÆS•ÑÿÌ2ëþÎ˜Eöÿºaeú¿PPQ5Ûªô?W’3r/·ÁóAÝÈ»TÅ3ó5žÏ‚« #ÌÓ³¼^šiðÌMv9“dš<óPºÏI>Y’ƒb&	¡”^'û»øÏvog'õ\sóûµgùá¦rÃÊå¶±ˆÿ7$þ_1Pÿß°”Jÿc%©Òÿ–xÿ¢yñÃäýçh€—³ê•xÅ¿ß¨³¿;¦ü~ùço=aøìûnãšö¦fº¥[hÿg)zeÿ·Š”Ùß_7_]Ñ”jýW‘
^zî¥[¬¿­[Õú¯"å½âÜO·XÓ®èÿJÒŒ£{hãæëohÕù¿š4ÇÕRÛXpÿ£*ª]XÓ0+ÿ¯+IóFº(-%žèÓP´#Ÿiä„A@~Á‡ÿÅfâ‘_¿Ãâ£Úÿlf™µ`€ Ž#®Zí1ÕjùqâÌc`lh»?qÎ¢Zí`óè‡îüwã	uÕLˆE{7Jl Sâ>¥ÞÇÌÊ–Ç/p˜‡õÔ¦™÷».iûÔI—Ôëiï	IFVGÅ@| IÃªË¥i–•€/tQV€kÜîîâKmbbÍúTZ&‹ÏWbÇ“ø°çkiÅ]C½ºŽp¢p:áq¿äI¯-¬\iÝüÑR¹Ï¾å¶qÝóßPMÕV¤ÿšVñÿ+I3>Áî¡ë¯¿¡ÀÿÿgTþŸV’®çiónm,àÿ€çÓ“õGouDÑM·+þoéñ0 ¹¶GË»tt›×ÀG·x\rŸs‚¥;áÑÝ]ù*øhþ³à£ÙwÁGÅ‡A}\NÏ@†C:"¾ˆÈ•9._	9œ>ë=š÷®·äõ_ö-ëio©}dÀ„¸‘†#”äœCÉâ©?˜pó$åÙoÂõ¤Ya¾™6|Ë1pyEDÍE+XÌr_Oõ¤ÊŒRÙ(UuK+ÌÊÅ
InV.1ÌÊ—Ã\	ÖLÐ[róeò±b“2˜[(—‹{›–ã–‹iÉíÝÃ×›oŠ­òÜ¬
XÛ3¥xî¶|y{FÜWøÿˆ¢@üþ…†EüLVä YÕç©Ö“âè$eo´ ÉzWüš³Ÿ©Ëë”,ØÊ}Iò‡¾3>`ö;|ÂåüHúÀf9ùÈLô¶ÂÑˆéyÉ¥ø'åÀàä¥–ðQagÃŽyIDÖ½ADý-:‰ñº‘Yâ6SGÓê:|8?k$êâ»pÒ|†Ãh~©QØOÂ³±”q0	ÇØp“m¹”ÇæG«‘Å¯íým,àÿl]Oýjºi!ÿgÛ•ýÇJRÅòåX¾9Èÿ¹¾Ÿ§‘CãËáÀÃˆ‡Ðm´Æ˜`
ÿø:—ñÛv"²·½ûx§	SóN‰y‚‹,÷
OµÃœi Ë7è¨I^Ðü¿ïLòÑ8Ö„3àgÎhŠfg@pù ¤äø 	ŠT\éú¸ä7ÐRo“ÙŽ9/häÂ¦u§À’ÍÑöðˆPÜð d9:à)6æÂãrÌwk7º„rìÕ ' Æ3Øçk$ð„A<¤ü¶šŸ|¢ƒÐ¨¬tb
ˆá š7vG>ýL0fôYHûØÑ95öB'€>‡…:šPŒ+]¨µ´iöGÄu“Y^‡ß‡¸›·ßDø›+m>ª…îàŸ¶†@+7 •h¼?é€¸Ž
ßÆe™q8.äøQÃúŒ'lø£îóB‰pÒwFÂ·£3LÚšJäùw¯÷Ã¦©j_ŽÞ~úKï|:ð½ãGv'
ŽÔÁñÁð]çÓ+ÿû}µ=þØ:ýøéüç—ýó§öwNwß~<Üsþk¸sî¼*“­W——Ÿ~lF¦a½íÆ¯^´~Þqèt°÷öQÍmH¨åþƒIÜ^Rf&Þ(Ì,+6ò<@¬m »Aë¤ È‚#Ž°B@\ÎÃ0üŸNÂiÿ´â¢Ã	Ÿˆ—4ÿ¥?8§£7.z°Õšl!ÙÔ
qäçöÔ­Ðèžö9ö³ÚèkâËiŸ•‡”wú0GÄÁoð_>‰˜&ôÒˆú°ÛR÷_½¿þËï~ú~šþø™º}ûïÿøÇ?âKûç‘ýá"ØÞ9=:ÛýaøÓ»¿o¾ý¯QôéÃ_þ®Žhg¯ýéÕÁÇÏöáEçÅ›ÖÏãÍÖëVïëì_‡?¾iÿK;T8˜fhåÿ¼’JäËÍÙàiƒDŽs ‹tEÊÏÀK4`/ËKðUm 3æ_YàÓöDy	t±EaŒÜÕÖÕe&™—y€.ÐSMÃñ†sº‚Û}Øá¥ËË [êFt1òæ| ã!¼$ÀÊ‹}8û8Húó¿ÏŸ2üzÅ|!ÏßàZWà|ky3ä/æNTâïg›Î‘ep±¼¿Û`«æÌëŒ(NcŒÅ^Z¨üœÅÃ¥7Xž9ÅÓ,EõÛ¼oñöäÛO×`w§6Üÿ˜ª•Úÿ©ŠÆÞÿ[«îV‘ª÷?¹ÏùË Òðu®‚4å:WAXuÀÞÿàP¹ŒÅëŸ¸ J\œr>÷ø¬O‘§oÎ^Ç¼šLG~ÊÙcðƒÞÂ0<‡}Œ2J®‰œi>1Î@b¾%³–^õÆU Èç…ŽMñ0ä—>¹ªêèN}D‹¿_ÜÉî¡$[°(ÇL\ÜŸq$nS¢ÃÉ„~ŒIŸ2Üƒ)àà)“ðŠ°ýÍ^¥k¢,¶»õk’w&?qì@9qï#†rP(£€…xÇ€$•¶ÕÆDòh:BˆèèíV‹×I„~Ör(Œ ’éñÀ9—|>OvOs¹+’¸FÉnvë­p‹P1õ™"ø®×­|>ƒ¼àO½1^ÕšZSm~Ëu¥—A¼òðýòoüÑ­Ô£tÑQò ¥ÝKÁ€œ0?›R?“ÇÆrßÌ¥Ðô–‰><%éãa×€”ÿÐUõv§P¶×Ûëª–n²wºí+-¸Ù0¸ãîI¸Ù­»„|Ê€‰Þöö_½Û<Ü).[1F´ig8Ñš©u‚±i jò÷—Æ£))÷òõ»\±àìSI©£·Û¹Rñ¹ßJ†ºÙÍH]
¿GwË};¦¥`Q°”E&îŠöTBzóåúê‰|•Vüqç½£ýÃ¢Ü‡ÑˆƒY¿Fó!4ÇRïßìnýˆû [O~eÃE¨uø'Óagãó{÷ÉÓôA^ò=I~ûi<I´&žáÙû˜À²9j—)W¨õ\®Æsµ|®Îsõº,çÁÎ¸NW¢ÙCJ×6~‡6È†™ÉðÁÞÿ­Jÿs%©’ÿä>çå¿9;á!+©,øïÿË_a6§ü> ·,Ë‚/œØ+yÌÿ1!oú¥z¢™¡Cý8{åg¾fÊgïKg››2Ë27“	IêqþG`qÃ…ÙjóÃ–C]g‰ÑAÝ¦]†LÂœ…17ÓZ`z
 ¸\Ò!VgS'ä€J½e¿’†,b$cö .ˆ¨Aàë3†ŽuŽ%ÜÅr>Éb’rî	Cßì¾šñ®Î!ÉñxËa	½Ý{ï¢º›êí¦À~ª»KTÉMð!_*ÉÍÊe«-—Ër¹ú./»éû‚æ>{ìU¤Î´{çº=m¡’,Z¤f;.Q±MãÏªõÎ¸Ä/UéJ­Øu‘ƒèÊýÍçç#`¹ýECL)ùõXT¾ã0g”uÏéÄ…c2ù35*Ã‘àëâŠÿNŸ¦®ÉÿßIxÿ¯©†™ñÿ&òÿªfUöÿ+Iÿ/÷ùüÿCWægÙ*RÈøUÉG™Í¿±bð±¨RþFØq¡è”¨pðFÐéòálÉ’»‡uàU)—fÏý„oºÔÓ:¦Qwº \hÿm(Ùù¯£þ‡ªªÕýßJRuþË}.žÿå;áaÿÒ :â½&CÇê Ù“6S~ü(pTÇqŽu®ìð?Ÿ¨BŽï38àø'¦1É™‰&ÙÁá3Ä›9€Æ¹©‰Op~
u\êsGW÷qwécuw¿÷qûbK ÑàÓðÀ÷w7wÝ»­Åfé¼\öý•=^tÿƒ„£áGD˜”tN8AXB&©¼7œúôÅºÄîh’žg—8L…}w›iû3ËˆÔ0}$—Eew\=¤,w2@cþ†îŠfø?M=á—Å6ŠÕ{ÖÿÕíÌþ[µ5ßõÊþ{5Iâÿ–wÈÜ†û»ó·ÔçX?U;‘bõž8¾Ïv‚Öd³ôƒ‚H¾Òí+Ôv—b1—>²ÁØ½›sRó©¥®Œ–üÀ9%ì¢¨Mœ8³`§`Ù “P¾Kl|yìÑµ¹#£b„ª…¹øX·è¾p>ÊaÉ±Óç07å9®ùx×@©ˆJŠL	ËÍ•ÑJËhY®xT¼ö›¢\ðpç`æ¦Å®~y¼ÓU¥²37·hÈ:f~ppùt“ðŒÿÖê‹žâdxR3ïkü]®Ç}År`âM.É“&,)¾RØ`$PŠw†×É}(T.}$>5áè˜µú®ëYOœ]õ¼WË…	ÏžùfÝñÔn21< =iœ&áÉK:¼ì¯<~ö,ÿ§ù?m¥üŸªsþÏ¨ø¿U¤Šÿ®ø¿ŠÿcWü_Åÿ=pþO“ø?u™üŸzþOû=òê–ÿ›óþ{°üã—rñ_4 Tñ«H3ë¯ê¥¬~!`‘ÿÅÌôÿpî`ýu£âÿW’*þ_t8ÏÿÏßŸÿO¼£Í°þÌYºn;›‰ñœwåö&ôé·!'|¡Ÿ+YâÁÉziýw"KÐÙËË’ô@ba8®×oÄ/‹6©@ÍËjsæÖ* 0P½ÄŽC-á›Ù¥‹èŸ ­•‚Ö®­•€–s õ
Æ{Ó	•vZVG»ºŽV.ú”Ê©<t… q1â2¥þdJ½’)¿a™²JßNºVü‡û}ÿ±3‹ÿ¥éÌÿƒaUòÿJR¥ÿ-÷ya0ˆoKù;l’9!¿¡K‡9Q1nëÐ¡Þ¨k¸s(õÞ0¨ÔC¥A~‡>Väò$q$Çc<œô%0¨Œ×;9ØìõÞínI‚I?ªñ6€š„å ðû§Sl˜=úñCž‡)ê>y
|&anÀ¦Ü]gä7(H¾Gê›ŸÆ¥ÒèÔ!3‡>i|"ªœRX·Æˆ¨Ï2`Ø×_ §#Oú”´ÉŸÿëÕI·KžÿÀ~}žÏàÅ,h²È¯¹á¥»ËÂ|h@€L’×l_c¨q]qOé~O ^¾ª´âc–…a¶¯€ísØp{þ:ì¢$dØ`Ô‡-&µøo?‰8à;î—ºí3wäxÄ¶¹dÓcnºRIøm±8ÜÓv‚-dc¦ ¶þ½ŸGhØH1ò¸·sø…Ì©¶™‡ŽÕ¢úr§%[I@æâ.©V`+€(Œ¹ÂÏš
X0;Þnïï‹×w×qÒy¦5è´$‹pkôMy¼y¸Þl–ï®fÉÞ\`½1Šçß-7qiS¹­¹eª¬ø—iVÿW/êÿÞåéŸ¥éÿòøï•þïŠRõþ/:\éÿ>¤wýJÿ·z³ÿC½ÙWoµÕ[íƒÐÿ7ó@ì£³æøb<Æ"þÏ0­”ÿ³t…(ª­+zÅÿ­"-ëÜ,²|»£ ˜8À{/ÆËÝÃglÀ<D_“Û+2{ã.ô^Æ¯–Á³›ªÖTŒƒ7‡»‹CÑYÂ:K¶Ã3gðptZS³ÆMH!	ö)sV#s}çIàŸšÏæü„±t,u¡VS”möiütm{ÿõæîñhmÔ)=áõêÏ c¼°¹ žW 5UÔ¯µþÕÉŸˆÔ‹g5v°$£øiª¸`‡ÚŠ¢ÖŸ%•£h˜Ô¿ªr¯·'Õ×²úìBvÞp²»n¬ø‰º°´¯žv#}%uëùg àjã	vh#;Ûº‚‹úåOÑ¯k…Éø®Pü ™æ™â¸ Yq~Ù~ÎaV<›Ýbi¼’ä5Š¥ÅtfŽ³ù)ó—•NŸ²æ”ÆƒÒ€ª‚¼Ûë%Ä€ç0úÀsžòñî…‚ÓI§Zš‡õÜ{OÉ:esÂ«eóqU-Ä!sórUEœ©7ÒæÊægQ­lÖº3ó´$®êkŸÖËO³ö?ó¯>nÛÆMìT]åö?•ÿÏ•¤êþOtø÷sÿWÙÿ<®²ºK|¨w‰¿o_·²ÿÑ¸ýOâf ²ÿ¹ûŸÊ§Du§¼è<øÚÌj•–žfå?å„Óv™¾ßø¯¶™ÅPAÄø¯zuÿ¿’TÉ¢ÃyùoÎ&ø„¿ÆVp†1ˆqh“ÎQAÄû†”A*!ïJ!oR	y@!¯dÁåŸ¦%Ÿ	†^ÌôÒ¸“¤—@Le½œ&tNÜËÔ o$ð‰~f"_yÚ‚ŠrßÁ/[§›ˆ~W×Ê	r¨ŠËÿoÎóùÊ qæ£[Ê} #8•pc\²hE‰­(²eÓñ0¤¶¹ƒ™ÛïoNt»–ý?ZEÜÇ\Èÿ+RüWMeü¿]ñÿ+I•Éÿ"“Dþ‡lôÏ­ãÀ ‹ôú£á5³þAGSœGÌ6c(ŸZ?ÌŠfÝ@A8ìÓÆ”Ë5ó8­dp&zÜ;ÅØm4¾Œ›³æùR`XÙ¬ßg†þŽË¬1áonÅ?*1ãŸ3†„|#3É)¸|8S‘¥soÔÍì5¹ÚÚèú¨Ÿp°ŸÐ~zg£?]gØðä™A2?žÛ001AþzH‰Ö@ÝÐ'¦áÒSç|N6Ï£ã¸ò`p‡>.yÀ²¹½M`–Ùá9/(Há@ÔÜ)ˆL°91"îBù•`€²óÈ‘â8 oêÆ˜±Û+>Rô
 h~5à;†O^'gSÊ6nö€Þi¨5"›[{kì8÷'PZfàË6åR‡ˆŽ¨¨	ˆOÂaVÊÒIŠêÈùDìÇlÔŸÂaÛ§±¨Ð}_W›Z³m(MUÕMÓjªM£ÙVÌ÷õgXÿ©°î €¤ßÇ&³¾!ä˜þ;1 Ò‰Ç©;Â©“&Z!¼—ïëß!£~z
Þgð‘¾û#èÚ¸ÂÖiÁæO€­ÃoAnûM„¿ùf ÏêËÄŸ}°3þ|üIg~)”B[ŒAÀ2w–ÿ/ï~'	`¡ÿ/CËøã¿¨šmUüÿ*RÅÿB>ÏAþ‡,$“¯!	œœŒGžáEï‘ñÈ|ÿ\¶ÿÚ\ÿm˜þŠç_=ÏÿÚÉa$|äõøUm`>çH®\ÅtÑÎâ1ü@_AÃÐs†xyÊ[Ø96#·¶Ï–’½ÃmÆ@ÜiLÞÒ	LÚf·u“6o†(Ø—q|âqD—nÐØ`tî~Ã½†v/F±ó¹¼Ü˜·¹3’ºú:`½à'†¼k¹vEwÛR€â(u¹“Œ´ÛhŸ‚6Ð_ïÜñØG	á -uq$¼;…“BÇÒü\ß²\Þ½C-íÝ«ä{ÚAd\S €ÎÇ‹³…¶6¢1õÎp£qò§çòxÒâ|+l8Ãñ©³a¬¦g€3Þ†¾žÔÔÖg¿‰>è7tJ‹sÇ„1pÄ!q"¹z$¬FŠëSº4aä¹àqÕ¥Ð2áôlìÑQ?>m¼@WzïÓÊïÉÛ¤Diý7¦²‡TT¸ Ê€ÄhxÄ(zF7ê=|÷Iï‡Í†šë$ìßá4nøb/l(QÙç (0°o¦£xCŸÅCìYC^q$`å²g°‡²aõé†mÛð‹W¶I?b£F€E0V¡N¡åÆ„þk
çÈVÓ	ÙÌð.Ý|ÍG©„G¦nPG¬¾WaÔ­0êþ‘…¯?0˜tÐD>OÜxRÏQ¤ï,ëæýÐîŽüÁ%ý’°#´á»ÐaŸ~ìR£28ÊKp2˜0|åÇ”oÄcº#€/æ}ôŽkš÷=šºp´Â›Àl~L¼4“×`=ú+r˜ßóîÁà	Ù~`a€ÉœäGGÓ…(÷ŽÙoÐ}Ýºœg¾l¾hâmÐÿŸä6èà´ãr¡J>e÷?ÀOÂ¥P¿ÅL–—ÖÆ‚ûÍ¶ÿï&÷ÿ¥ZºªU÷?«H•Îgr¹8ÿ@Õ;÷’IrR÷J"4ºAÝÉ4‹×6Â£V¥ØyÃ2#úÉC‹ËüQ‹½pgÁH7£!hÂï›Ô’2þÀéÂ(xw€rÓª²k
V÷ßÜó” ·òêpÿø€åxáøxÁ‘X(2Î¥Š¸rJ?/ØÏ³A„7áGöGÛ®Í?9Ÿ#à‹º¦òºö¥vÛyò€Åù(ã¦ÃÝ~ÝÛ9‡rÒ8…]”G²0jPüvã)d¾¤›þYÔDæÑ+ÁÀ´…£–ï¶€vç ûv»õ¸bø
°`ôîù¿Ä3fÁù¯Úª–žÿ–mÃùoÚ¦Yÿ«HK£–‚fV\@ÅÜpþ8°·ÿê–qNN\Çû83ÒœË§ŸŸgó¹2ñL>/ ï‹¨¹)QsEùôüvû.ýÇå_YHÿ#“ÿTôÿgÁPÑÿU¤Jþ«(EùË;øû¦ü<Éú_€€ËfýYZ@ÿuEcþ_-UÕ-ÃÂû?ÃV*ÿ_+IßÕþ–èöì¨¡K^Vtú^éô2!ñ«,L‡CÂI>	f 9™Žðy0Ñ
\â  a…¨òþ‡†ÍìH@{Evh …¢t E§¤“—Ç{{¤q†Èÿ·pâ *4½Sò=8Â¾kßÿY­-uf|g 3yöné¬n~²ÙQÖµu}ÝX7×­ëÍÓî›­Ã×;oŽ6¿Îtqî`%S¤ilŠžÏÁ©àÄ,š‰¯}*UiU)ãÿ0˜ß§a$<ÿGÜQûRÚXÄÿY©üo–e ÿÕ®ÞW’îMþÀ °¯È“58¹AfÐþJ†r=ÏK'&vrÖÉ¿Òi*v“yFµ©™ÆãðO²dß{-<u£2k“˜ Ž. g^<L\tà0xƒl9ó
f1KGÀÍø?‡$´!ëŽ#õ‰hw2N5m&¶ªÐ­'OYOŸ5É¦ÿö Ó€Z'ýI,vŠŸBanó] cÉÒAÜ¬=Î•föp”aä_«y#÷=šú!ñÆ³ËNZÓhÒÜ–¦øo«Ð€ð½Âàóš%”.OË
S±r8zŸ:^8_¿_T_ÔLè],C%gÎhê¯±J‹A‡ã›CKV‚®D¡w°öÒ_kÛ”#>4ÔÅà œŽì
Æ³öÎÅQwDãOáäc“ÛTÖ6ƒ˜NŠ™¤ö‹ Ù¿ÖŽ.Æ´€(Ðªê¢­líîXöëTƒ™îøîÌÃvmç3õþÍ~k1{GÝ=ôç¾Öxáp\RYZD¹øÑàŒ†Ó¸G½®®(5hfä;§qVâ/^8ŠBè~òug2	'Å0fAB~e3EýÝ³é00Üdj~Qòü¿ <ñ WïêôEJ‹ü¿h¶™ñò–mVöŸ+IÕût˜Ãýz©ˆwˆÂ6A<qö¬Èë16Ž}~º†¨V”Ed.c:Iï#†Cq,ØÄ~žþQNàÖ”Y‰-ùR2eD= 2áÙàò¶>9´°>‘‹p
lÕa6áÍBSáeêÿÇMhX¸!xï ƒ†Ó¡OFaì4QÔ_t&P7^‹`6QSí|}tˆ!_—´•ãÀ8ñ´ÚoÂ,“&º”=OBÄÁ&oóè”æ‘3)D Ï‰øKÿ sî†¬A©e4Žáð°K±Ó'Ì¯ÛÞÞÉÖqïhÿõîÏ›G»ûo@*à¥Â(È0"†¹9a÷7·övØ¥Y"wðH`ØŽr°Ÿ™8²žlÅg©5U”–3@SÜÂI²LÆ}%@©C)°íÍ£Í`(“‘pt€ÎÎzzÓ¸ž9ŽRh©G<ÖG©k©+Ó¹ýK:ÓÊ]gŠoýx|Œ[‚*nŒÃäåUa.FgfpÀü$¶Î¾?¤Ÿœ	•A¿|ý.+ÐŒµExß|»)w4ï 39…ËŠ&oÂÙR¢9Ù5QÏ)#YóÚL®u™]jípFôhë
xÈÛ‰Ãâz`¡Ád;d4‚JM/€ À™á2b„ãÊÓ–€ãáµTJú×Òþ}uM}÷”çÿnN¢ñÛXÀÿ+ªÎùÍ6tK·˜þ¯Uñÿ+I¿ì¼yµûfç×Ú!Æp2PþZý–;NêªM…ÿ¯öË«7;‡»[¿Öz;[Ç‡»Gÿ89> Z½Ó;y»»yòúœöŽÐßF7p†KÓ¬Òý¥2ù‰¢?Kö¿mªiüÃ¶¶ÿ¥Úÿ«H•üŸ—ÿ²è¿•Óþdt87Áb:Ã±·9ø@­àx(/1¹æx;½ŽJ/„¿ðjxO5>«/·„âv8ÉÑÛmæŒatþº?Xæ>2Ý=·%E1ò6]¶›µÇ¼öðÉ|»yØ}ë§t‰ê-=µ»ö~ú·÷§ï?µÈ/…È¿’µ¤¤çŸvák&7}É¾8Ý‚—vîl=+àŠ(§HÙC‘½·¿µ¹÷å:-ÜbS¯X óÏå(©ìiiY©Àp>04!ÌJ†nÖåBœâ§ó1™€Ã¾'B`ZÀCv"k¦ÙlwßÌï–›AÆ[ûo^^wBøJ¼ºÞ¥Ë‚íÝÃtyÓÛƒ/â" jPJ°óóð6 /8 vÁ“\é„Dcz	4ÁËöYŸœ'0ñbPÙ\¦u)ïÍ¶æ••SòÏ—Ý5ö³Á(<(£µ¥B;Ü‰Ew¼Sv›”\êÔ0w€zÙžìíöŽ¾ÔñÃ¿iÀêOÝz“H;T\%õ3q;ødP¯ùáˆÖx%Üõkž_ŒÃwþZZè4)$mçìë}­ËT .}mBfK`¿r¥pÍ–‚Ü\)ÜQ³¥ J¥Å§eƒ*ôz0œ[(Ý'RiïêÒ|få”ä¦Œ­HöÙqçN{±è ´h®4u)	Jg­?î®õiÌ"Æ§ê‡§<—_•žà½Xò¾ ºâ)Ž“,˜ª½- C{{ pv·Èv›3$¿±39-Ôì®áŸ4ŸÃ6ñÂa8é:Ó8L”ƒqÓï`OÒ¬ˆg•A‹†¢8Ð‰'Ï¡31zlŒ€§KËdØ’ŽtbbpŸ×	°š©\ÂÉ@VÞ¬:Å·n©ú„Žo@Š’’A‰nƒÛÑ7SL@œÂîÚù ‡<H0bÇM§
þœŽ9ZLS¤˜3 3»kgLÁ¨àÂ¡kFæb)uÔ(¢
qJ1Yxp¡¹¡ fÂeNBåžDÓ³¯Ûtr5=;s&I·üö©æá«ÌM"ìEYÌ,¨÷Ç]NçI‚%­ñ'ãó5ãÏ±<˜œÿ×«†³¶<Žoö*ºpÿ3qP„SÎ[b‹î!wæþW5ªûŸU¤Á½•À&>5ï^09>ˆ5d	Oú\ÝK<|íÞWé®©\ÿ‹	FK»^°ÿ5)þ/~¢þ¿®Wû%©ºÿ-êe¸ÿ-^óîW·Á×Eê6xé·Á×º]ü·g„<&1a×¯È7™{†µøŸÉB…ì^uÌgÎ»—}Æ,âÿu#óÿ`š:óÿ`«Õù¿Šô˜‘|~¤°³Ïu#w°só5ž¿·½y@0
2æéY^/Í4x&s–˜fš<S
’œ~²6$C1æxµH¡ô:ÙßÅ¶{;;$±‡»ù®ýÚ³üpÓÌþožlï¼Ü<Þ;:Yÿo˜™ý¯i3ÿ_@ªý¿ŠTñÿÿ_ÀýÊÿÏ± )g×oaR”þ!Tþ÷Ç˜ÿ>ì4ï+ÍœÿYØÃ¥¹ YpþëvÿX¼ÿ·-]¯ÎÿU¤Êÿ?úgÐþÊÃÿ.@náä†.@Â¼#“¢ù¯­ÂñG:³%®>ÖSxìé¶vÿN?ÊÖú~ý~”cWí\\£¥;xÿ¸ô[: ™»â7oÜÁ2 òuÎýxÿ˜ÛîþÁÎ›íÞIjÙ­³†­þGµ	²Î‰ji­zÞ#Hþ–4¹+æžA>²¢ÿš [²g¹uÂq±Ê!È¡Ž­JÊq>©¾<ç"Ì»ˆäÿš1€ãÁ	òåMÌX
±èþGµ‹ö¶ªTþßW’“'»þy²<úÃÓ7w”v»x)”ÛË½z²ò; €ðUÈ1ŽrüÀ‹äØG¹HòË±”I@eÉ[Ê›3oD€Ä¹‹ÿ"÷ø0‹uû6ü‚ˆîÖ|X$ßëÂÅ}Äôuø#œôk¾·AÒÌšâpqÒwF‰¿ŠÜ8¶8DoÔe'r´^ÛƒüólõBKÞp+Å qÐI
ù€†pöÏ…Ì?ßò×&~UªR•ªT¥*U©JUªR•ªT¥*U©JUªÒï<ýy¶W_ ˜ 