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
VERSION="v1.3.4"
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
‹ !:ÅZ ì½ézÙ‘(è¿“Oq±,B…¤–²©R¹!*ÑæÖ%uÝR™d–€L42AŠ–x¿ù1/1çÑî“LlgËL ¤D•Ën±Ý%8kœ8±GœÓ8iÿîÿ¬­­}ûø±¢Ÿð¿kø_ùQë7»ÿ{ò­Z[‡_ÿN=þÒÃŸY–‡SXJ–FÛA³ápÁ÷²óï?ÉÏ)œ:œÀöòYÖÊÎ¿À‹ÏãÉ£oéüŸ¬ol|»ñxÎÿÑÃ‡¿Sk_`-¥Ÿÿáçï÷mDÓ0;î©æÝýÀhÇÓø"Ä™êüÐPÏgYœDY¦¶£‹h”NÆQ’«?¨Þl2I§¹Z}¾Ý«CŸ^EÓ(Îòi˜e‘ÚøSCýqâ‡Q˜ç§ÓÙÙYCõ.ãüïÑt&ƒ;_ô~8ŽZü³©¼›_vfùy:•/{y4uOG±ZM£¬®2ú¬•Ògÿž Zýt½»ƒ8¯î_n‡¹wcmý­µ‡­õ?Â7GÑEœÅiBßÐgÓIšEÜö9êõ§ñ$WyªÎ"øç<RqOú‘âõ«0SÓ(Ÿ%ªŸ"ÜgšG™žïøN)ã1à·q'£+5Ë¢¦S%ñ4MèÈ ôçé,WÇ¯·›05|EKÂ¡Ál8ØyžO²ÍvûZÎNqïm†G†”0§ßûQ¢·ðÃánóakíßîî0a¤½tãh€3ÀŸY)X ¡©`ËpW´!úf”žÑnÇéÁ¿ŽÃ[ÂÿúçarewºÀ¦Úâ“Žã¿ó4Ÿ:RôžnÐÁ«í“£ƒƒã“íýg+œ¿6›5À–üïS+žÕ®iòn2Péð3×ÐPÛ€Ê³Q®^‡£Y”}âF‚×Ý£ÞÎÁþ³ÚÅzëaëQ-Ø>èv÷·ŸÕŽ^ukjÙÏ=@ÔðtñIÆðK8™D@#`äç½î³Ú‹Înï6]DÓS¸h€pgz[G;‡Ç'û½î³•UÄãh…ZY«Ç{‡'Û;GÝ­ãƒ£ŸÕÚùxR£_ììÂ´+¼×m¿{ke¥ôŽ;GÇ'/»íîÑ³ý…D"„“…SZùàÌ~­V_GSBâ•µë:#òÊƒZ°×ÙÙílou{½gpãþ=†píZýó {ttpôl-xyÐ;†=œZÐ"6¾o¢‹v2ÔÇQÿ<U+Øg«3D^JÛÀEžÏ;xêÅ,é#î}*ÞðPww1‡²õ*Ï¢ÕºúP¤¸Ûq6…WÜàgF@T%”§¶Ó½ìLÕvö_¨Mž´QDˆŸšçSÕŒÕwxñwöö·ºß«æ¶úøû`{~ÿ…?Bp™N/à†|¯~®šD©æyÕÅ É½  ^Ìé}QÕ»âRÍé>­êÞ?úïˆBO£É(îÅš3€³mû£±õ±uSõ“gÛñ4êØØÍtÎp•{Ÿ¨‰|DôfNïÒ©à|¢v„GWõÛMÏˆ„mÂQïü€„äšÛÅCõ|¸~­šg¹ZS??E†Ÿz›[£(L:Éà?fÀÔ¨ÝÊ‡kú:óÕí
T±ºÿš¢Ï‡qpÜ)÷«¼Q{ŒTLÊòxLÒËxò%n7A{µ| ýíì¾Šøaý›Í×UÈG? Ò†ï"ìô
.Ar¦N#øgÀ0íIPÓP× @T Hr°
U³GBl ÏÏœEþP5 ÁÇ;{ÝÀŸ½C ÛUíß¾ù±ùÍ¸ùÍàä›—›ßìm~Ó«ÕŸ>uºÍïš,éLzÂ¼­ÏpºÖjnƒü½× Uñ£;EYØ·˜_#ž‡˜{]SÏ”ÈÅK ›jbQ[šy2j³&@¼<5õ1Ñ±:÷ÐôôîÓâaL3¸Jú×ì<ææ¯Ës¼ï´jœö÷°^Zë õ¦¸íÎì²
.Ý]åç5uvZÞí M¢2MºÃcûþûª=ýÆ _½È›ï®é²!.@HI65P³	À!*LÑû8¿cYh£«•jBŠ×‘›ækuÃc‘ªg-	Ö.™Zwš%…æ]Ø¢Ú©…†n©7 Ÿ©pœÎÒÃéÙuä¬¥zp©fÄÊ¬÷Ó)Ê HF-wŠ›N¡V«ÈÊë7ÿñÒñ])„Ä@-ä“4§Í‘2yÜy~­`*øã¨³µÛ5ÒÌÉóN¯ 8 ôÒY©Í“E9ì}^„ñ¥Eo?ëëËFÞJg£§³þ9k¸/ì·f”†õvåÃË@vK/ÒîáÒýöRàò]VÓ‡°±hàö´´w:ár$=øÝ—î†»ÓéNgI‚r‹…úéx&þpŸ0Ü sDrgTÐŽühÙÈ³ä]’^&j`ÄòüjÂç×€;Xàx¸lø½8ËHh+îî¥¹	ú.®K`áuDK’ˆ)îK Ù(ÀÆrIc¨Tn¡¹u>?¾á‘Á]>rŽ	)Ga+Þ°:µ{´hY™CÚ…îmø«í³J£š·þ¥'Çë‡{{€]I–Ê­Öp2äÂöOªtª¿Ì²\]†Iª´óp4J=óç¥ó• (­hŽ„ÚÄÆÚús]b[þšŽ¢qzŠ@„* S+ÓÕŠSÓ±7¤c¯1MîÁAÑPél ï·u0‹Ð:w(†}øàùìÌMVhžmrÏ-<éªiÜ¶fTwvŒ¬„àˆéñàÅç›}Øz´“ÄyŽ>Ï†
#1ªw‘I?(\PTK§Wþt3þ|Á1`ˆÍŠ<£„	­ªVe¡ØSÈ7ÖF>ŒºšµÃÄfùÄ»ç/W}üßü^5…¯Ýz³®¯Ál8×.©†ãZÊ¥-.EhÐÊÎ‹DEõ ÷q(Ñ„ÅÐˆŒÖRøUÓÇPê[¼`ì:â\-`NoÅhY†ü3ÜÉÿF	Rýáx<—ªæXU¼mŒÎ9	ëî„ŽVß'±˜„acûg£)µÆŸì'p°=Ÿ†Uó6ôh­†Ö‡ êÐvÒ@‰°ˆìÞ‡XÁ>©þäÑ„\ÆUx°ÔŠ÷ë,ÊÓ	 ©ß2Mñº!Ÿ9b„„S@‚-t¬©Iou~onoþ²ÙÝœ¢œl6VàW8¯‹	sÍ!úõ‚&á|×ÕÞ•‹Àˆž‡ š<¼íØâ8§Å/º…kDœÓvZWGÝÃÝ­Î19DŠ«êÖ}l¬åÏz³jåË¨H{4ÔÁßÒˆM+€ p¥å`QŽwÅ‰ÅTÁR¨‚ú^Y?ÄÆ÷X°;-Vþsœ“Œ¤"d¾ WLÓ±â1=?˜öU:£³Çª´ulC›Ñ¥šá. )–s/¸!Ç4ú†¿€ÜØÕÌ§7ãj:9þñ:à‘ÂVíªþ/I; Ã<^•%ïÂHÌ–sÁ¡\àJŠ¸-˜#—Í¿n6k•–÷k§ƒwGtW÷CdåÃá›mÛµe½¿æ[îs]fÀ>	|XF	aµÈgËy4K´ 4½ J¯õ—ÖÍ&ûÚ›ÃiF_Á'IÚÒ7žäôûá4DÓ<Ž2\9|Ä°³ÛÞ‡íðÇîUåÆ¡a>Ù·×ê{­áŽáÂ¼{&g\qÙp¼×@³ðÒ•Á¼îuÑÂŒL~A!ÝÞý90Œp ÿ\0äôìPAAjÆê~ÖþÛJ»Ù¾ï^éýK
|óyØ}ÔÎ6ûÆ³QOÐ]Œ)ÞPí’A;Ë£÷9*0+íûO³öÛ¤­ÚO¯Ì\Îié“–›ÎÀ•?¥Ù*ñy¦G#¬?êž¨Ì½hzú%bm¯x†«g ËÃÊúê~©™¸¡£·Žº¦…³uÀ[Gµ…Ó'ÅkE)±€}MmúV]>u9DÛ#«ÉÜ]Tuw·;‡ôŸžgÄõ!Çt¬bØ•±£~uÞüõä D«áå;uÿy÷‡ýG½gµ·Ió-è²/è×ÚÓö€^Ã{¶þ”uÄgÑ·®þ·jÿ­3LáœÚÈ2V6ð£·ßÝÇ™î¿ý¾­>ÀWWòÇ]Þ|^—qÖžªkô} mŠ>ó1CÕÍz½ë¬?¬¸­p‚×+íÖ7;ÆòQ®äŠæv–8Ì"€Š9òÍB7Î³ÚQÑÙûõÿA§è˜Ì„)áÒ%d>7Ï1dó¬@]|£áí)!UUÿ¥Œ”Œ°+‡ Ût¶÷vö]Þ8—Í†ƒqœÜ€ÏV3×¹g9—Çz[[tô•ìö3NþÑF™9XÚÝ9–kT˜ä£s­ð.mÖž
Ò_«¶’v­ïÉ·ê÷ÿîÉ>šGx}ô=y¼QyQ>írlT‚ÈGùJ”‡¢Ñb¡º··HØ¿¥dýêh÷Y(7Ûm4õŽ¯7	YQwÊÆíªH‘-Ç Žn¨¢™Æ”Ñ…Ng‰#Éñ]fy6…Kõ†Ò‹PX9±aš!'t^ñßÑØ˜Of$!‘ùŠÂ[Ë"åmÐ×?—‡²{U
Ò£Geˆ’Bä³{ÌçÚPšÿè¸í»úÑñÿDúˆÿ¸öí·OÊñÿ¿Æÿÿ?_$þÿŸ.ö¿*îßÜˆŽ¸‰Jk¯¬+He_Cþÿ…BþÕFð«¯!üÂÿ…âïkµOºwbîï.ä^ý&cî¥ ûŠÐ~Ä•Ïˆ¹/w÷¾WÍ±úÎAøèæ1öì°Yý¤û›‡×—×¼”Qtã±Ëæô.mÏôÞã‘óÈÜîÛê»ç;ûÛNh>ÒƒÖm˜Yw™Ÿ­ß«Ãõëóãõßl£Rª'9tÃ}–ÌôvE{æ?TßuÿÕ²ÃÎñKšÂ.Æ†Œ¬&r&È¼H¢!0/¨ržßJ€Ö¼®™xÜÑ]üÍd ¨¯ _3 Ô×€¯ ÿ¼ _0á8ÿ¹	´98ÏãW D#G¼	ë«ä`8¤”X
ËØ$žÛì±p¢þ
!Rq"ë—ÀTJU¢&hË#Ç}ŠÑRz’¥$©™{ÁJPq	øã=ž˜$,.
Ì'G2Ê›ÎÑ>Ž¢W‰*?®±¡NA±×¡Õ™¤¥öSt¸£(§²IÔgÅºDÄ¾&\|M}XšúpößÍ&YEîÃÃ¥ë¡´]‘<qGQÿË“¶tþÁ4B!ÈúsŠ0~ôxÙPÛ^_Ä~9ó¨Ä¾<cã™yM¢)Ú°p»²Û¥#ÌKÎï\/t™CÎ€SÔÒaM¥¢¿¹ŒG#¦c"jí‘ZL«%ŽïÔY»¿ÏÓK5Æ«Fñ=îº€Bç0³éÍh[Y½ì«æH}ç†×½fÇÈ¨VVWW¤O“~!a¼n[âèªÉ‘ÒØãÚGþˆ»~¯šl…¹À5{±Hp™¸dýËî«ÿ©‘û´$güŠqû
ãh»û¯¯†H-Ãi’%ÒÄåÖçGøó„0L'1üêF¿ºÃ(~u‡aüó"õq¬5Iã$¦ªMô)™Oá
1‰e‰,ç‘Gê}…hƒÍCuˆI|`—çóNácÄÉæ`îÑ:(–D¥Öëð¿:-ëîƒÿÇ›ñf— †›¿FüoNÈþ:fÿ•U­—ê¶Ñ,˜µß6ÚoUû¬þÅr†Ø–sMÃü|N«»È ÀíIµ1±lS.0À*{-e|µBÜ.@Ü%š8-àËE<ˆ
rç0[Zj¸zeH8““eãs)leÔ8Q!ãü©`<BsGŽÞ¸mM’CžVÚˆÆ{‡§u·„óh•rË¶¡ƒ‡æ}â3ÎDuÃ2‚.?vÜyþ¬<OEC‚ÆÉîùÃ˜²\¨û»w_™\s&$@D€˜ÔËŒÕWk:.ž`B°{[±õ9ã¼ ™e]Dß·Ì`·;ÇëöLfµ½f‰$»ØØû§ãç¥ÉÒX%«Òaï}‡¾xo´5!B+1ÑŒo=xÛ~»
ÿ­¿ÅU´¬´ß®·ï× JÇ®d ^Îð2Õ-œ‚­ãÎgY´«¥ó›òú--\!²YNÕýÆ}ÿW×<ZÒ_“è’˜FœN¨rtxN_ÓÀo¹ËGì?7#@mî\i4fÆ»i:Q)ÕûØ#M°¿)´àô6H2G(Ã¯|ÁlÅ§ª
ùTÊ§ Jeç‘UÑŽ6ÕOfÈŸœ¥³i?òBD†T@7Eµý]<qáDÍØ«wE|ˆWWé—[wTœ~šäq23Ø(·„È¿Li)Ýïo’ûT}÷ÝÚèc{<¬£"Sø&^Þ#ëÆå=:¦²ÒN<]6ËQe…ã?C9†ê34a›W‘© ÁF@“E#~rî”¬ç–¬ÕúH¹’Uù7ÐÃF½Zït×|<&Ê¥Ž«m]÷mÔôo“üÇW‡sñ¥b)~ÄºYÎl‚Hà°W}¸r/&!Šß©'¯¡=pè°!W¸*8ÍÀþÇtæv@:m¿…=s÷N!%.Ú¶|Ëµ«xº£Uš¯Çï`Õœ¨Rû"QB­¶Ì[èäX¸õZ.o¼ôÇF7xÇhÐð;9:ž„Pƒáé[ç“pP ´.\˜n‰F|âRRÒŽõÀß£sÙÛ=Çùè‰Êà)'¿q1ó]ÍÙ«ÛÊ“fäC¸@STÌQ­"WoêÖ%yùýô(MsWll KÄ¹ÿÓO›§£0y·ùóÏ÷ë%H³|ÙŸöÚ³îõŒ“þh6ˆžOá€@ßÅÚûDÝ`ÄÖÎî·ßÖokíÒíûg¶Eþªû~Îù°Ï(‚Ìa„–<Èrv¶íÒ®o:l‹xáÒüäÛ:ØÛë YD¬G;û×mª9À½j6MtšdÜ(cæF¨UÛÅœÐØ"¯/Õ½'v¬“íðJîÿÛ7³ûõŽtS€‚’à¨p„AÍHÕÞ&å–êûŠ{éü”zTtð³…ð§2Áeñ&0ÇÁŒ
¤(£³xü¦ü¶‰J<:ç+ù·„J³hªQšäL^!{uozUÄÄF¬HjRÙä’âàmøÞ\Î\OÄ¡kÜ(”¡!$÷Ai”[yq—yv­>%¦¹~,púº?U‡éøDªïU|nõ§J·€ûSOX ÉãOeÉ| Ü²YM†C&®`MIœGƒ¹Q(Õ1'·–ìéeÒ ‘\ßò:Ÿ™q”ÃÌb*Ór¦ çÒêëslÖdÏ¿Ã,&ÿÃjÌ?$ÿgãáÚ·ÅüŸGë_ó~Ÿ¯ù?²àRþ¹ÿù?b‡øšÿó5ÿçSÆúšÿóÅóÐ	ëµ»»|ù¼}(Ïùn£­ó¯Ýîá³G7@FÙgÏ/ìâM½ËX¼‹¢I ·t‚òî³Z³©_´2¶_Ù¶êÅ(<ûššt7ÓüJ©I¹úÑð_(IÉdÕ¨Îîî¼|³móã\)…Wí®;û[GÝ½îþqg×ŽŠ_ÎöúîM·û×ž×ÞµK÷®©t40QfèGóÆýÌ«¡úîygë¯¯o”T\–ÎNâ!¾f'ý¦ß'ù´|¤¯9H_s~[Y0_søçkQÁ¯9H_s¾æ }ÍAúšƒô5ékÒ×¤¯9H_s¾æ }ÍAúmæ å›ï6ãÍñæp³û%ròºb×AeŽÎ»º"—@õ·¿Fþe±=õWÊ8
ˆñ8ñSÎ$#ç­«è¬ÿEû«~¿».¼\C@[ÿš©ó5Sçk¦Î¿n¦Ž“q“L‰÷–^”[¢!.Ò$Áq„·0E•p„>UçO‡û{j"þÄˆ³a†Î±Ù(Uµ;I1ÿö»oNÐï´àXÃ_°»m¿X]ù`^7…
ÄOÅ¹Óëòñ¤'0)tR^/õ¨#Fôöá‹:Û%Ttöi»´g<&Ú¨¿ˆ0“ìÄ×ËÃ˜`Û³é™„´ÈÈî
idKÿøœ­BÑuÇäø+¤lÍKgú´”-Ä¿DÒV‰º~MFš—Œd]Ç”ŒdeC“Œd[èÇ»\L¹]*’;ÖMR‘œö7OEr:9†îR*ÒÒµT§"U¾4IXGJ™¶•ÙGÎ·Ï>*Ëö.ã
au|­$8Øêsáß.ÑõO:‘ò0vÍËRsR`/þõ¦Äˆæ=?äZ8”…‰9²Þª¤†<¢:ÞJ²e´ôpWà ¸ÉªW>økq½9næK±U9!ÍÏc)õXšùâg½8ˆ';H‚¶ÒdŸU†¥ÇÒ/ô´ÛMÔ †jþ½1¼	€Ûn>ÏÐÊÏþÎrë`ÿÅ`:SVæAé¶Ÿß¼dúEV—óÞeª‚Y±ëÝ_	g9¶AØ˜jßÖÿ1\œhR…sÙççZ-Í³rNL²¬dÜB–ÕÍ3¬æIÏ+©Ý­©>?‰êÖ	T¿FòÔÍ§~Ÿœ8uó¤©y^ô
 Tê¼¼¨ÂYvfyŠ1ïýš‘²$Øw?Ã Åd8\²®QHcÅIV³¡‚Zõ	‡{$ïÙ\©âFsi…ÙÓöÊg>«æ´š\FôºÞ2—m?u·0Lg€²«h¤,¯»¼èB"¦ƒ?Ú=6ßØv›D6YÝÝ'²­ýJ‰l_>éÇ{–ûÍ±8ÿïÛGß®­KþßÃÇkðûÚúÃGk_óÿ~Ÿ¯ù²àbþßˆßtîÛô¨VFôk{NÁÆ÷5ð·•¨s÷,d_‡Óc®nŸ2%ñ1¯vhŒsœU<Â=QCW”ÒÕ¤`¤è}M“ÄÅà‹šLã¤¯—7«à6šÎ*;7^<B~•p†"¯O79QzžFä½r¦°·L¦)‰ð°ò€4¾Š WO£*×­r’!èMºj‰q¿™OP(Ö¯j©Ës¸qhÔ¿L§ ÊŠéóVs!E8ÍÒÑ,Øf
`—dlÜ?ÛÚAQÿC‹å*4¢Ijhé½<é¼:Úêþ´öóu­^SOÕär jt½F—K{ñùaÇæ†öÑQæº[GÝÎ±	:†ÎìUR´VŠ ¶é?Q8íƒ¶—À×Ðÿà¨O;ÇÇÝ£ýg÷ÿöSØü{§ù¿Öš:iþü`sõ'øþ­xt}°újû#>1ûqgûãv¯Û­¯Ü·óqøFÀ‘²ÝÝ×O÷üÍÍµ	|¢Ö7})uŸ_>Sü9½ç~ç…Ÿ=´ŸõÌ‡øÃAKø˜?t^7_=Ùt¢ ÉÒ€R9´n¨ƒüîN1	ííÝžz»u¦T¼œ¦„Ôu-ÄŒ,Øî¾è¼ÚÅG–9BŠóUkBCkÞ÷T‘ÇmE¸R+ŒA†Óˆ¥}¿•çü–vNŒ‚Ó´·w²} *®7ï Eæá7Mz«³ë¶¥}ô†Îió†”÷à´Ânåý¹­P‰×sžÍmuÜÝ;Ü…‹Ó“¶y4žP ’íqxt°ýjëØÝ©Á¬Ÿ;£rü ãI“áør}£µÑBµVjøbïÍ‚Æl7<ê’ñpç:yÒ×è$CR(!B‘@çÆ†Ï´ÿÑ!Qß|jï‚Ã».|=÷‹Š½¾ØÉ]Z1ß.ú]“ãÂ:í_›Mg"û1î¬ØíIŸš7Æ‚Å.ÞdÍ›…ºÉ4ôûmç‘jÆZhCœÆ#×^68q:L‡§Èìº¥³Çsé»"³±ÄHa”u¯|‘p®ky½ÝAÊ‚µ®µ´9½ÆmÜXHˆk	uæ¡`Œæyf{JàøÉpã8ëûðB®ægÉ¤j?0>I òAY ¯,pë3Ïˆ´tÜ"I.ìÑâg¾qùàeJîïÓoÞÿlÑðÔ¿púžŸcô{ÕXji/8þµè•È°·¬ýu÷ëS\;¡þäs'õh¹3ñ_:¯;zJóû-'û%¼JQˆ Ðýà‰g8¡WQø®iAë©·¢ísŸ­­¿ÉÚ&ñC28»çCQÕ>
MéVÙ$M(OcØCcã\™õ.ÕDåxýqf±&Ù‹ÄÃ	âÈ$=Û®Kx°AÜÔ?qnÚ¡4ÉŸ­<”5p7¥>ÂèœÐ¤›Gðè èg7L)°´0"†ªM,Á`;LÊ¦ïkNuÌE!j³°}ªÍ^Yù‡ëBVGgˆÀõ9ÃCn¼Ð/²ÈÅ,ø18øˆŽ_B$'‰Ã;u¯Ä”QÕr/_‰–:EÈ™ ç ì#-»Y„¯QËwqL£|šêzÑÑÁ¸
ñ@c#G¦’éÀØR¥ x¢@ÜLÔý6é¤’‘~Ó$!k7Ú[iOî«†®)i;ÈšýáYcc£„J¡JzÆ6‡uoÖÒ|2Îõ’|»w5ÓI¯·[œ­÷§;êšpÓyj•j©+“GrPø•Ç_¬Y	õàŒ+œ»z2™éüGCóXîy° o{?N|™Ó^ZB›õ‡üSu†ñý+¶}òðÉœ¶ úWhûÇ?™q+hhoO±Æ8¤b.ííUÒQŽÌ€õæ="ét#ô;Oø«B­V	òÚ·kkë•_¤ñëê¯¸µZ5,ÉHscXbëÏ„%MøåaùŒ1s>¸o}
.,Í«
©o“D—¸àDœÌ¼ÕÃ±Ô±?LµÀ)
@e¦ñybP!ð§æ[•¢òC~øE±‡5ñQ±'êQ”t‹}Œ­Q>Þäú×•ízNCi‡çSjkÍ’~[:¬Rë¢½R·†Ó+¶½S/!YÏ&˜ pÂÙ<eéš¿&þUÅgM2	9|Úª…É+¨˜¹vö*²±†Mî•©âb›×owd0Q–ªQ”ßÏô	´1p‹Â¸’¼l­ù~W­øŽwÚJ„ƒË~quJš]¯fïé Pdþðg‰`*A72R†:Kƒ–éKÒS¬je©ùíÛÂG›tý6ÍõÞt.ï¦¹š›+þqÕ\Í—»ï1ð‰ü~&p " òt L’ç]lõûï«6[¦„b¼¸¶œcGniáàÀS@„˜¬šÙêŒÚÈ­½QaŒÕÇ“üª¥¶tº‹ÕRZE
ªÒþ*&­ÚË]Áÿ#ê>&,%ŠNâ“–'ÜÐc¤ñZ¶¸cB_‘ZS×dûD×XúóŸ½êMóí’Ú?,©í\ka®=AStœÉÓwº2ÃçNÿ…¦¹øf“à°«íŸ²gRnnµë÷ãÑÍ¦FŸþ{Ë‚®C©|ƒ¢qÑè€Ã§Ó°?ŠNÈ’uãIdxîËV03	I£Q‹‚ÌT÷¼»ehŒô%*Ÿw«jÎH%‘[Í•º‹^â†VWìÉÔK=ù|•×ÿ€ÁA½•3¡5òÏ™¯Ç4IÚó”×7¼õ•ÊKIP7×ÔíÔu[Àé`”‚OÑ}¿ÌN?Å¢!Ão¥I–Ž"¥Ü•`lÙf»-¯1Ä¨²l\ZÞËããCåÿÌÛ	6íU6µ;ÑÌ\«»-“è1äÙ¤ÌŒ]Z!;j™ËfÃß1;fPáqs2"Þs‚­‚bç‰ù1Mðf×ŠÀöV¦šåÏJVýhÛÑÓºóói:;;÷`@Õø¼²Õ©Ý<”Öë´iHè6ˆ_Õ†h£C}ð•¨kO‹ÒÖ•ñµúˆÑTª¹îT´yT28ßÍ¸Õæå»ûaÝeÒž}G3<™?Ãížåã-°Xµ:›´1k¢´C;ker7,Ö¶¸=9tï;’k®úëöJ¼@µ¬ ä3ŠKêþ`h>T÷¿i>ÎÔ7Íõüïúõþ7ÃâUŠøÚr_õÖ[Nmeõ—4NNN¯T[±¹üZY»ù.Íuôg_Tà¥Úº½D)¾auŽs¾gXƒ)m]CJ‹ewK^µ¸ƒâØ“•”C-O\öÄÊs¯´b
ûçUÕè QZª²QdìªØˆ&|IÃ>Èðéô¬•â»Y+‹¦Ñ´E±kÆÛãÀá:›¹†½t"žáþlrÿ)a¶ü×>Æ~Áooê‹–dÍlNw<5]à%S_Ž²»ßõƒº½[|€,yE+ñbxèì**7Œvp$ïÿA1$&wnX‚ÖÌ
Ž£ŒsZÄ¥sî“•põŸ¤’è5®û<¥"¾À*Ü¥VsR@Ým~wÓá¦³x!w¸ˆy(p=)ûe¬âoN 
ž*_%ÄÖµ¨.?Â)¯Ž>Z¹+/ÎÍþû¯$–äæïñ†^8ÓaÇÂ>/„Ãé´,K•á½í¨#U{¼Å–ªMÕfgw^©Þ!­É‰©ì\AW“hÊVhÓˆS3î˜|îFÉY~ÎDq}í:24ÆWB²Ù”²yÂÂó#ê£«%eçH¿$ïû¦÷ ŒáƒÌ%Z<×T|T: YÄ#ÏÇ¹æU ¯¹¨f>E=]ñ³i˜úzýåC£î‘I¶	åðèŽ=BÝWµNó…Í¿¯5ÿTƒ1í«÷Ø}T¬]$Êyeº@)àÆ‘°‰iôß³˜³øõV÷2|( r&ùÃ Ë3Bï?Á‚~~à,~Dù7Jý¼àù‰Ì¿„§@TßñŸäæ/h„8FfÏ'@Mt$¡[íK!à¯B=ÃOÑµJ,ª»ÿúÓ3øÊÃ+µõªw|°‡áÅT…~žöøŸ7AÐóÍ yÇvô?¯è¨«nºèƒõçw×…r*ºàç]<EÕéâ}~‡ýLœva‰æóŠ>ºÆtq[úóŠ.nŒÛÅù¼ª—.˜]˜H>"¢^œHÞ¼]ïW÷õ ñÌç¯séÙüœEêÏ«»ùfÛÍÿ|É”…¾'Ë¼$bVõ³U4T¨ÂÏ31`ÌiÎvrsþ|^§£îaÕøù¼.½Þneø¼Ô¥HÐtbYg‡Ù§‘4ER#T'
[‡üqçˆS Å(--Úá`ñóh‡}»âÜ‹¶dºã“èu90»ýa®°¥V]1­^&õŸ:ü^F±ž9X¤6õ`z–_Ó2Q¥AØ{x£îðÍÌÞýólõ&Àš‹$	lÈQÇjV9²ühù»Ày™%;Ãœ—‡ÉŒkÍÆzŠf0Œy0µj)XMÀ4 Ú%<ÈÊËŠXV*˜M™’”ÑÆ¹’óãååÜÏGtüaù•Ù&—¯/È±;ŒãTñ˜JJ hˆ³;†Ý¨(GRG©=‰‚E¯?þtvw:¦|;õ¡’Ò°$©*­¶ÔŸ­Þ¯Áÿ}¬Õ[¨®´òõP›·=oœÕ{8ÎÊÇU©CÕWÚo7Ú÷çŒôA~Ûl’‰Ê¯¨$¦fÀ“o@kãr­`;ÆŸ•´Á¢YjfŠêgîÄ×ž›¢®5‹I8Í¢¶º’Ž}‘žª|·å
¨æDã|Á[[ÔKr÷_àN§°h$ÚÉÝJÙDÕÎ|V`½ö”ˆ{ª5’µ§_jÏS Yh~›kÁ„a_Ø" ¯³m~ÛøX-‘Ì¸6ã‡SX±óñ†dKh[ˆ×kI¬µXw¼.ÈA5°LLœSæ8d}øã%ßðåñVSXîÍÖSèt7+Ú‚»™&‡@GŸ­øf£k’^R»£(aæ¬ÑùÜ±8üTµ¯{+vxÙcÕÞþ¹@ã“TÃ¼ÞPã(L2¶µô¥Å™Ú§A-LmjyÅÍã,Å—‘ÐŒ°Z’ZFƒYßëlI¬§¶ˆ³z§~Ü=â­0ÊC´2|«
Y6
hæFúU¹6×¢t+Ì‡šW+Ójc„†·eY´]ÚFm¬D²¥ÜœØÙH»V^À=N© ’DÞ/<ïi
P^…ƒ1ðËÏ-üôBdmò!×:‹Ñ£€¼áR—1ûœ²6ciH,Ø;“ØÖ$MšNjñ"^†ÓœÚbÜ3Á³Ã5dyŒ²G#_˜†Îçraäˆçˆ(°Ž?sæ-ƒ® 	·±Ñsƒ‘¨”Ð4TÙ«TÑ[á¨<ÏgÍu²Js1ÿÐ¨q—Ýá»_y~U,WLŽÄÒÅbÉç’þÏøë QŸLÌ+áÑû¨?£5´¥:ƒéIuð¹¶UùõßôF¿å×Æøä¤Zjáµ—9ýé12õ_#óÖdFv¿|;çõK^Ÿá@Å'Ó¬µˆ¹TÒ2K5_VòH?zã8Ëê»e¶´«+mÙš­£+ó„¿èŽO¾c˜a<Ír½R¤—q†‚çúq$Á.´åG…$§dDçuwcs^b’#üsí¼hÂãx­Ê±{21-0Ç7mãè4þi‘GÒÔx@‹*^á¬Ý† Ê@® b€Z??ÇCÅ,,*¹ÅDÔ3>Tð¢øèNfÌ|8›±~ÂF4ê¸ÓoV¤E—*ºv‡ÐSÜ¶Î‹9–,› 2ÙUµEn¹ì%CØe›—$/d,/¦ºåC
‘y¶6Ëµ_Â×ýÈurÔ×Ž‰Ö†ö9OÄ×öÑ1±Xé<NWq„å°êÂØ€:W w™]àãŸfñ /¶N4<¸ˆ[Y…Ô(ñw³8ýÚDá‘0\j™^÷'êF˜ãWÀºÉYµ%ÂË¬@_M.]¶n”¥üj–s4j¼“8I·Ü‘ÆƒÐçí},=ªbCå—(ŠË×TE2’œÕŸBÑË%Í·méëkææVµäEKK¹,Æ)	â©®Â.¹Q¦°\œsn}¯ËýUfr†ŽÈì/I÷«W~ž÷2=,Vx”Nt÷°ìca÷Ï-NAt^¢ó_³ ½Ë<2×&y“²yÑÝâE9çñÙQE¸rñ	»Šœ¡y­Ë-®¸À½’ˆk’VŠÎú8g?½‰Z©§G"ö­Äs2B-FQÈÑgî¾©¢Û<†ß»W[)í§]02šA9‰G2ò68Óv”þæ›öÁÚæuå—Ò±¢çt
Š•³9ý¼h ÓmŽ½þ©ºÿæ<XWs4g¯ÌÛ~T¼À@ó“±ªV$úÛu¹C$ ã¹{4 FaØrÐå³.F—iÂûñh!I€ïœ7×éøµNÛßËŸ6l´0Þ­/<ÅžµH…ÊÎný58Vù¹O‡¹%Et"m«>Þlšç?½¡\vŒLØ/x9
ŽM\ÊÉ®ªï¼©Rñ¯[ŸÅ+§PUHq·ƒRDå<‰] ˜Òo3¬N1ß”<uù:P‚2[š}”Ø:0ø ¥uhP¬Wí¿b5öçc±]ê“GTn±qé1«äX/ZûÚ}ùãóŸ3¿Ã×Ì•ûô¼VòœW‹Õ0æ,Ý®ß.|`óE¡™sÍ¨ÃÁ+~\ì¤w|ô	yTÞ‚tFUÝŒlÏË}|WÏwí>±Î$mIãÛX2Ì–txètÐ‰tKº<rºpÕ²%›Z~jÚ’n’sæÄÖ§Šy«±ù]ÀeÇº‡üØ‚˜8øùc7øyùk.yÉkÀb°iÞK¬·HF(HÝ¬¡ëb©äò<îŸ«Ó8Ñ5Ð1îž°\Kõ‡Sz5	¯¥i•ÍŠ"Ä È7œÌ,(^¤_lE«K›ñr[‹g¾“Y½‡±è§ÕŒƒ>¤x³(Â¥7A†¥'=r«,:ïR2be]€ÑFºæhÿP+6™U_êê€»aq}LúþU­‡ãWÔé3j@œÍüñÃl‰JÇ¯¬jOº5i‹Ó¡™juw,¤‘Å¿‘.—>#•>êê~æï/˜7ªÏ·À]c[©·•¥üyxQUB»|øŸ‹<Ôß50õà`w\Ýšð§ò\~ú„:(^½E¿ JÑüåÖ0âÔÞM'µwÓKíÝ´1¬ø{‘“áãœ"µ”ÁÚYR`IM8]	_üŠÖ^Óøx'âÛY^ô”¹.ÆÄ¬Æ ÷ãû9Úê*®ûËvk“éeã÷ S$³p$ïÓÚ×]^tvÑkjåù¢–ôŒ@º?ç¾\éY?óÌ_\iñâ:›·BØÈ=Žë“7EQ¯~EöAY)õk­q¾zãis×%Ÿ/¹¥šÆ”6Ä™ùl8ôüíöaDVÚè=ži³£6RxáÇsy”	(_¡2{7Þ«yä§´pÃþm^uí“ûãK,Ÿ3?¾÷2¯¿M3»%xË®›VçÆßU!¿_¼|¥éýòLåÊLräŸ98ÕN­*zƒSúfue¨O‹ŸZJUŸ–è‘/{E7w‹9¦Â1Í¡‚Â2n£–B7–ùÍÓ@›ÇŽßÒÎ®6Ý˜TŠ6m$Êí4¡»]«^Ë]¬µ\¡ë®×**ì×+¨ù
Tš_bþç¹òíóBŽûž=R¨Q”ŽU?ÙâDx_rFZøÜÛŽ‹v)ÅX‹ÏYLa¬ek*6·‘Z¡IÁó¡)O}V¾ëÈ5T9endÂ–ÛÍqŸÛè>YêÜþ…˜-“”EûÑ‹·
’‚§P%u0ÌkåïóêKôf›Þu/Š}Ë‡+Ù´¡ìžuc¹3”r®É¢ƒ™Ÿ¹Ty>~Ö	FQ.Äýx(^¹¹K¸†Ïmîo|çÂóû/c¹V±˜ÊN´$¡¹œ{MÆ÷5ï‚Õ&ÈoQéc!t—wv‹ïê–Iø<…õ›E÷[zù|öÛwòô‚ŸÅïó{ÙæýïGøþ÷úãÇë¿S¿ôÂðçøûßxþ»;[Ýý^÷‹ÍðxòèÑœó__{ôxýaáü7?Ùøúþû¯ñ£*~~Ø¥~èîw:»êðÕs@%(T5‡Ÿ×’¼û°¡6þ¤þ2K"µ‡ùV:¹šÆgç¹ZÝªÓ‡êÅ4ŠT/æ—"KÆ2rþ6€€ö[ê;)õ:Ì†­tzÖþ>PÝ‹hz…ó8SŒ‚Ïs~Æ¸£“Ì3À7âSÌº¶§0²Ü	;rr9ôñËã
P~†T¼¡ =ç“Îäd…£QzZÁ¼íÒÏá4
Ç ·`«cjj”y>R‡³S˜M¿uÎ¥¤†°í­xQ4,¬$È40p+©¯ÞÅÉ€Òªé¥ê–žDzeò^9+÷`ÁÌàÎ‰<ˆ²øóðQtX†—á?Â…“â:Ù¹‰S°I\ã(õü
¥˜|fy#È—î8Nò(ð9ÍÂiGÅƒÒŒ˜Ù$¹à´ÿKžMÃq³™§Ž¯•^t§'‡i8C„sðÑ—þ†_1_€zòàO°`Oä)†gOäŸâZÂÉd„F^Šy†}…É•œ‚ó#o	ô§W´Âp–Ÿ§´ÆÓ¦
ÒHW2´dÿl!M	Þ`²øe„q#á;\BÀ¬§_áþ¦Ñ0šRÙŒ÷a˜7è%½É4Æ²^ê †¯Þ­5Ê=¹¹aiSÆ«E!ç&ò,­O­ÊqOÏýa„1
…0¤ºŒ³ózÃL	fñji:Ð“î(ŠÌ¥cpbíÜéŠm46ÓCw<mX[ŸW‡ƒ$höhÞ\jA†{‡ÙwzÜåéÎà{|?Sìšcö$‘½ŒN#‰†“)† äŒâO9þ
Ï7ÁcrG\g˜½“¯èv’á|ñ2ÜªEtN:ÅƒÇ†x(A?šæ!åÙbÇ,>GqŽ‡!`®<%JŠ}"Òâ!¢äfy<X~†›v¯í‘ ó‹Š¾Ç“Œ»hÙ¬no<€îœsÏð½>‚Ýn5Œd³c¬,…ú$êòv2 L&yÆ;ÂXCYWVB¬Ü<¨€â˜ÆA—®¡[ê1´VÂ8@³¨ìÐ…0[ø=»ƒ£„Lð[¬Ñ„à´	¿éQƒ _!#¢t¸[…^œµ›_väÑ$ÛV×ë€6@÷râ5Ì{8Þá"f¯nÔæ@"¿0ÉåÎâw£èˆqÝŒx¼°Ý†{‚0\›¨£ Š9uŽÑÓ»ºÏö	&y÷õvˆþÒ6a‹} “S Xj‰{ Ob1{â9E^r%O)Å™O]Z<ñ) “š40“fpÆv:)Ü&ð¦õcža@§ ÅôEæR–¤Á§ÈËŠ‰>ƒ0Æ£ ¶#éza.°û+‰ÒYÛBÎÀ+AtGrÃf>‚[C…oúT©ïK…}ªØK¹tTïÇt–åm.7vˆ„[pÉÂ,ë¡ct<A|€K0„Òe)Qäé7„(>aò!„ÉÎp9Ñ€Ã¨ƒ„1R€@Ÿ/`’œ„Ã'*(3Ó2•]*S~c #Ã½I,i8Å+‘öû³)¹þh2Ã˜é`Ö—'¶@zÌ€#Ì¡WC"P„D
‘E°üKÆ+ÇBÖ>Kª“R>i½Œ˜ÝÙÃ@€èª5`D)"óé9H±v±4	¾¦p½ôRa†Ù™A¢pŠIšÙìm	IPY‚Ã§‰§øý€jš ZaÎu”Èª`°‹X_VšR÷Ä¡†3<]ƒ]{ãO‘WinÅä¦@ØY¨¢'¸¾¶M¯4ÙF`æçäC8ÌH[‘ÌcPp‚_#ÝÃG;"ªb¤Í‰$ëÂaà6õsMJÈƒ»'lZÙëp¢8ÓœpQŒ?ÍXÜ'¤I3¡ðƒ”Ø3
t5/Ò˜³úu"é”ë±¨Gb©Þlœvâ"hKÚÚÇ$#È\¨šW-‘XÀó²ä÷LS£@Ï·PˆÊ,ãi)@Oup-FS$¾#Aíƒ˜“ç‡”]<A¹Ã¡ãR~Iè‡<52Lñ4æëBÇÝ£½žêìoã»ÄÛ;Ç;û=l¼ÖÂBb˜åk[íØá15Oé|õ-zhîÑ\)œ2Zen®¶aø]s¿ÃóK¡ë,RÃD¾nfÓÒ(cÒ=@	³wfÝ¨{hwÙ(ã›9É„M²¾èh€rJqèÕ+ÕÅâêÒ„5ÃÁ Ž<ãàï°Ü´ªI‡(«Ñ‘Ô¬PSƒ•]!6¸4Öºr˜HµHkÌ’a^›”%Í™c›A „ºvøU'‘sÀ>ÖRÃ0;çº;È0‘¤[éÂ
0ÕŽevB,êqI "`Ÿ¥¡ôSªï€hqqÆÅ_ð	¸Z‘‰ÕdMÊ±Ö«H¤ßjÚ}P£‰ÝVŒŽªõSÚàg5EË‚áv%fN9lgx=9J¾6@ÆÛžQhDÎBÒ˜?Ws.·’Îàš;Ð»$H„edôNèô,BÔî ŽØa‚ºSœñ4¨¸“ Ñ§>µ°g—Èô{ämº* Û<ðÎšH*#Äá·(ˆÇ\¸†ÎìPö‰ˆ œ4fhèHàÑ‘UÚ,'ÛT.QOÃ”Zá=˜Ðmg²‡©h…P1v!?½`õ®Ìe4™“ ]DEtÇ{Šw^¤³¢QÂž3:@äµ†N%*Ñ@YK(ì‘Ì ¸B.óÄeÜˆ/*y[&ã†šãbúÝ_Ì7J²! 	E˜6å€pý˜2N8›Øy."ž€> 	-Òuht&Ì_ð¨vI^ßOQäÈjèD$0æ±º+‡òŒI¬9*„E&ˆ]£®!°r£¡~affs…™Û¢[Bó=#ÈáX(-ê…’®
Â
n¸›±ˆÈ$ñ€Ø¢MšÀfD,ª4k	³f+¼RRÙ€aÔ Œ1Z¾38´^ŸÃ[``Ò,i“Xö'$N'=!²lyMÀ5XÙeˆÃÁ „I„õ¥3ž¿?…o§0!ÆzK‰WjUOÍókŽ>ZUÙ%G, QË*b¥G—Î“}‹¯¥{YYÃÈ‘)œþÇáíÝBÙCŠ×èACðöPT§µ£f»;€äûÈ9¦ï@=QcaGÐim J†TËêx¦¹IPÙÒÁZ/”T’¸½™(s®Htíû³Qh¬mcÃ¤¿Yx†Æ„— õmtÅÂX8N±H…ÕÛqÛ’ÔÁˆ(CØ3ê‘zu:‘¨Õ˜;
U¶b„ÜQÃ>„·†·R+D%PcÒ‘®ì¾ÖÙúJ½	Ð9 sýwáù½ð Â«41fq£,!U²"L@Í§9ÝñÓº¢çMÐÃ²VÑí‚EIP–æÅ«¨†f"–ðUqèÀxq Q˜¶Â“²CQÌP˜—X"Â-6A­°Šš ^¹&}ŸëZn!\lŠ²)fDá©S°ú´Ôh„$>`‘.:cˆ§ÀñŒ
Î˜×Wˆ.!1anà›1pÖuäÈ¼A&Ü>V€~Ÿ5X.ÁéãQ4Õj¨•ÖhÏíàÙkË·ˆ@nûá˜ÚfCºå=þÂ„Æ#'±?&!• i4

†1G¡ÔµûÚb!È3äuÚ½™®ÓÂp4w2²É¦ÚÔd·ÊOðZ9!Å1 E:•ÏÊpô/ÓKÔZ¦B"º¾szØûYP¼®Ô¢’™§)áòÜ ‹ˆäžÐFe»SÑæ¡ 
8À$“}aÉx+ÛÙ¿–¼ÚVÁÒZuŽaýŽ aô4®µ‹jhÚGŽ>àë*§É_ŠÅ^À.Õˆ‹—‹=I`c6öÒ]%á˜ËVXéöìÔ€Æ¼L¡µ}Y ®LÌv@³Sô¦À¥S•ž0§Ë1ž%Z‰%u—Qaˆ¶…SÉ0ñ–Í1î/Z(U›xõ©‚+›ø]2b¿6åN32¨M#û„…[ÈK´±òÜÞtO·x-þU-Ò=¶Ï FË¸ÝÙF‡e:4
	«‘ÐÅØ|F^¼A… EH©¿ÖBÚÛ”Ñ‡ÚÀOö`”a)+-Z–c¼BëÐ plTW)ÊµIRÏï¼M‚Ô€F2“Ï’Q<Žqß†­iKYëå”ßùT qBÌ2puHRXåïÓ+Ä¥2ÔPg1åæÑ%byd‹óY.²¸¼¸?`ØIz	ÊñYÄ;´›hÊyÌ>-”4	ð~\„#æÏ™éé•¯Ò“ÿÄä1™Æ0¢	°Rë-Ëñ €j‹¾D®>ëš™€õP>
å,´ÏÛ-FGfÉ€Ò?§ä“Ô«¡½0yj|g‚côT¬Ða4ež‡|é€h“
çË² QŒfåpXQt»‘æeÔ>®!ÛÕK–Åpä`ªö9OF»2Œè•ª¦=2» ÝšÆ,Ÿ	‡`¢é2'G¸ÁFÌYfl,î"‡ÈVÙ5E&}p%è€N£óp4lÈý¦Ø°Ä†ˆKiÐE¦½±iÔ1xùÊhŸmdìßc¶ÙF4°ÌÑ.	ô‰Qñf8¯óxÂ,z®n¸‰±ÃøÙûñ´?ë*ù^¤âJìØ#`àX%;G+§R=á”Hˆ÷âAž¢†ØÉúy3” ä:ˆø°…tDû=^±ßƒ•ò#¾°/<àVÍ-Z2ÚqÔ]¹Žû©wxÈJE¨$ÈºÃöQbÒ&f8Œþy’ŽÒ3d& [†äÆ´0rŒBpíÕp6nNEORØð™ÜiÊaëëš½Ù9<pGŽÆ}s j-‡ìn¬©m •5]ÿÓŸžà
2 ¼¨R‘!V£ˆFU1é“%Ñƒøzô2ñÀŒ¨‚O+Ù|ÆTíJû,áÐH£ ä?‡§ñ`¦ô|Ê7™„áuEÏÄÖi?&„’\Á	‰§<ŠW”Y¡8Æû#ô áN(ˆ&–EŒL+$Õø¦zWÍ"½er,3› u%%H:
ß®ˆK²Iƒ¯;ûT§Œepkï0egš¥Cª¡I§÷¨åÜÛ×:>k‹j.’Ó-„pé	¾Ÿy"3—@›é0-Ö <¸,ñl\M¦“l
?;eÉ?lÍXè®A*#fÓc¨g¶ÐØõ4 ìF81´r‡ì
&.’#úBŠ?ÉU€-ž\ŸÍ@ô÷°O%»Yô­uj0*,@àž‚æÚ˜v\›ÛSZÆ]Pßœð‰j´Jµ5»h7ÉÑ=8Å)ª¼.¿›7fit÷PPôEÀq8>AÕ$s²6ÚàBKxì"Ûž–íD2~í:ÚXçZúK‚ªHEÃ˜Ñ¹ãÜ¾j:‰íEÅ\¬Õ$"
Œˆ öQÆŠ›+7hæ2²MöÐ…u^Ùê‡Ì¾ »rŒŒ•Hi¢|by¸4»Ž‚„Àv!VXÅJ¼§Ÿ4yÛ%ÉV‚âªÔ	¾.§æûÀmV4Ì·ZTv^áÓ»a£§û*DÐx€8BmÎÅ©ÉFûu#¤eXb@ü¦Fv,qŽçûëM±Ïm‰ÐeEVÃá^¤Ye:’ ´>²Â a’ë &÷>X½¡Œ%gBº†¦´j—}ˆb&Q”¤6äÈÎÂé`„q'(ks×ºe“"TyŠ”£¨¿¯ƒ¹°ÔÚª8^‰ÏÞZh9PmøEŽ°ƒJpEjd–Ò"z®ƒ½´™K©A]?ÈCc)®ù®€Ñ«±óŽ!2×ñòa#ö%yg’Ë´„%p	7yŠfî,Ì³iÚ…±AâC²8‡ï°ž†FVðe(Æ†¼†œxá¸6Ú9EïñÍP¤ú¢Ôž°›ˆ'/îÈtˆ¾û#ÀÂNÉª¯=¤Ú¬ÃâÆ=+ÈOŒu¾
#*»èš¾HG3~ž+¤"è€„Š^]vÜ‘Zp\ÌIPÏÎ¡ÑokŠZqùÜÌñR[–/+´	•E3b²•ð§´4þ}	ON# 	’PmÒ~}QzY‘A×SB*[Õñ‘—þ§wdmšýÃ+‰tÈ•¬ïÓÊ
z Â'.OÝaEØé8œ9¼Ô7”TŒdbX˜eFà?žË‡Þ.&àN¡ˆæUZÄ
“EÆ§$²ŒˆÃR·Ì|c:	 ö ·!YzçWÉÀæEƒ¬Zû´Ó¢Gë’÷Æ“0‰µ]‰©Dµ©/~ÏÒJ¨³)ÛÏôè< s0ÊäèÂY²ÑÚp@€
äYÖþÝsÈDmŠú{ÂR`CÕgi/Çj ¤Å`üÕUNÙtë4aÎéØŸ´09an5åk†Œ#d²a‰f+ N {}¢dj..¬[$RâÉ¤€\>#L/²Û2‡wÇ`€¬Hä¨¹ÆÇF5>ðFà7Ç‡†ö’ä.\|œr4€Xàêei"'ì ×s¢.åú4Dž±Ö/#VaH²kõ`ö£Èêö@v$©¨ V‚|v¨«¯]ºG'Î•ñQ"$/ÄjU¹@W†GÊÊo’Å™6*±¡8í÷ÃŒ$3VGÑ¥NÏMû1GX¢ŽŠ£h»²Â^½|æ¡æò=’wÂ-Nµ€øäÔÊEs.þ©hctùŒüì™!;=aéJ«Å˜}>:‹–Ak¥vN}á‹FÅžz¥ojB—éCžœ0€«[Ì¦ldl`Feä$Q¼”›à]AvÀÄ!½äx¦•ˆ†¡‡ôIiVÂÝÆ\Tâ‹Ç‘|½M¡>AûU¶1= z‡`·Öœ+®ýFÄCˆ]ær9–o‡ÿ²BŽ*RÌZê[ë0Æ¿Ï@áì2iTµ¦ÂÃì2œÝ>åª$É&ÏÓŒó:ævoÈÝ BÓbÜd!h£	c²Z¨ã¨%¶aX†õ[gˆÉìmÎüÇÞåÖDsoÍŒì‚“(š6ó´‰ÿrø—	ùÓ¦qpåqÂövFTÂ°«ð„û¾AB0Ô³BçÓˆ©í†“x«uŒ„½5b¾]Û!Q%XC îhä¢ž€N
×ì‹7lì%ÕW/‡ç|*h.î©qd|oJ‰:aHhŒG=yh–âphŠÌfcV2¨‰VtL¤Sc®(íŽ…iÔÌ"¸[nÀFÚ¸|U7^Žã60è<…ïAïhçUf9 ö—71çÑ@R€ŠÔC¶E'†>À(HD%Á¼%÷Ž6é!–°?o³`ÎNóáŒŸÎË¬×Ž&]0œ‡áEJa‹$y„g:ÛÆ ÒÙ–=Q¬–b…jOCÕ<@yqÕA~5!Y1å(:@/F„*ŽÂ,sR>³„öÏLnCarÅ› Rz…¸)40F¯’(zFüL?Bñ¢4Ž²£…a„‘#+Á^X¹>,g28é •©f(M3¨ø­A™€—;Khh’ð˜OÂÉAÒâ5ÙlI £†ÞEÂïpÜ+È;D©èwä^1'BpÛJYq£Ð1Ð<0]ùû]tÅàeÂÛ±5Á8©NdDàx¡¨"m«lÝÐñxÞ‘a©?ç„fó%ºÈ[Z…‚l†¡ŠQ‘Íˆ³1“y½P_kPÆ+ND+ÐTRS]”T&l*â}qh¹6O#Ró}©/?%Htgè9Ñ’©tM±šè‹Æ‡Ó±[ÏÊJ6-«.tml#ísæèfÆ‰Éì0ÔS97Q"F†®uÔ&ýà&†µHdµÃãŒh'ñU“(ŸÅù•‘KÖ )TeµÒ¼é¯0#æ$üw	8Ž‚JÆûöíÛ¨dJ<\½7`]_Í»c˜‚?’kÑ6–²éT•’žu’²Ø‘±º%%ƒ±S…½+÷npR’®Yòö N{&ÜÌ5¦„w2 óŽ£ƒ½º	[r×ïèQó¶^ŽÐƒÂú–¹Ãi•eG
G×Þ#Bh~‘ƒc#Ä÷CwÖ^‡©³9%ƒWA¥ ƒÍñ²A‘Q(´N âþ "³Èåy””œPH¨¢ÑÐRhwæ iYÄÁPÄ­ˆÜ[×1S=¬å"NG”ˆG››I11ÊáLûÝ8fl£êÂþ4Í2w 	ÑXp˜*Ì=g-“AÎõ{V^ÎL¢ÎÆ&Â²,Ü]æ GÄ?¢
1Ãó†ƒbàœè®4»ÖHë\ASÖ ÜŒpb– [„ïSy¾Æ¦Þ´¾ma=cí—9Ž´Aµæ|j˜6ÜÐÄq‰—.™7uÚâ¬ÄãpF'R¼aqÒÏ4ÒlÏºÜZAõ"xæP<PâkÒaìÓî#pÌ'¹Ùtc›9™ÆVwY^,†Ég‡ÛúJ9OÕFœ.¬\{À–o¥îÆÐ¿­¤{Ns}I”·þ¤@tToœ±Ù]U]©äEN_Já!<ÇHo»zsbØXUƒÛ¥n §¢òö9«Yô³0—%$sdðA§>ƒ- ·Äê,ài«™ÛQz)Ë€~¨ÄIÍ
Ö?.õ‘Þ­ºu6‰%˜³|¤Bâ;»iL¾OÊ»#÷¡.õ@öÞÊ¸;›ÄmåxŒ”‰¢CßtA]ô;pQ‡q,øˆTyæ)K@gËŒìšÎéy
¶ã’2v}!¡ðÃ”è+ëüØ–€$Ò&uøú·ÐçEi2±"ŒMJ‡3kCM1È!Së‰˜®?)®á)Ê˜Ú	qdÒMIm™^öeSxó3»ÜLØ»F\¦"Í®Õ8Õ¶Å’·•«öÉ2èÙ=‡’GÈÊvœÛÕ÷ëxýMÌ`ŠÑ½<'y'F¹µ8+Ë··sjTèâf/¶h…Øê]RÚ^æX†šòKv+ƒ:Ž6¶œI5$f•xðÚ†‹ÁÇÝèvïS­÷$ŒŽ®l'ŠêF8b`¢³‘­U7e·ÇqŒ¢~A^â ¼Š†mÎÊ¥H‚ŸÌÎ;t1ÞãÄ«³;q
˜è#Ë¬þ•ãÔ9ó¶«Vu–má%ò¦Î·km‘õêŒ…mÓr©½ Œ5¬“+·pNª×$ƒ€”R»˜‹ñJ ˜ì ¦r… ¶b´	ñl4O€|‡t­&¦ùÀ„‚’xƒ{—›ˆöí#2‘·ÖÀ®™« 8 Ø%Qz4w9ÔžµžPDUX’Ã Õ¼˜·•E-p†ªb#–`ë7é "Ê:CÙ¤TÎ¬/0*g@’,8 µ?£Ì©-^L´+ú9ü¿Š±X¤ôwî8åÝ|Z§vžï™ÇU«F½bØ³\¼	Ø™·~×FAËe1·´èºí7à²P(˜ <Àæ&35(d@@' F…âú5$øBHwRÐ³Ø'Œ
JÎOP62~§åÜŸ´x£Z ’uqÛ”['àIË\#ãžênaæ(O¶ Šº~Ù®Ø€iÐzÿØ"%NØáÆ}P>šÉ±µ 
''	Ý´d†Ó“Êa€TTE×ß`vòFXÉ7³¦òÞH¬âÂªÅËùYV¹l òªhéÔ çÆ»ÑDJ(Ü`,¦BElaAÃVßMÎ=²µÎ¦—NP	ïôà•<$õ»RDÌEž¦f$û]SuQ Td#"û+ÀõÀ¡ìPË0Ô@YUÊ‘^VU2†\ðÇÑOì±¹Àˆµ!—hØØ*<Á‡ yÓõÆ4Ÿ%·µà šAãÈ•aÈ®Œ59aøÉšT3Ìå$(Ã èè¶)AÝKBºˆÎžJ[Ò=h'q”9{	–ï¥Á'³œÀ/³æñ8²õüsZCÏÅOËòiÝêqAq¹6é ?£ÕÀ÷¡ß@">`9£8ó¢Ø¸gé~[ºc¾!Ç˜õì­Dˆ™K†Æ_©ÈÒée:|ÃL@ÅÝ”osKóÓ˜Æ"‹œ™{ ¡¹{Ô4œ´7õß ?‘^šš
!øp†W UG%†ËzÑË(Í ÌþÔ"ëßDžqÁ´ÇGyÉm…t	;é:G¸v™(9àp½P ˜”åçE$ÙìÇNÒºr(·©–R9$k>‰Ìâ…µ‹Ö¤3–8ÀgY²,ÞDDÞ`‡6„JN7Šä-õJ¹ÈH©ùFúáÇU„cÎi˜‘db³æÈwœ»¯+Zr¶^Å!ø•äÐgjìpê!¹”`Ú€ ’+„aY”î=—’p_””;šóI¦·ÓKÀh,_ˆ¦_¨§2”gN®•ïUñ¸«¦S™#à–õK£L4$·a¤¶8Ë©p¡š3›±+‚ä/°þ]ê¤#‹lÚçeÆüŸë!ÊbdH·ÆX'Q5´â¡òdý?5–ø]ñ9ñ<œªÉ¯Ü’\,‚yeýïc©NŽº•Q·¡5<ÊcŒ£écŽ[ï‹èÛ¼ëHbŒcÖQ[‰*ïNÂÜÙI”s‘ËÀÝ+açˆ]òÁ‘&œk`Ü^QKÏu¾ûZØÙ~uŸ*2(‹’Í0ää-ˆô€¬«G–8+n™â™Fâñy4ÃuI–b1¯b®£ÎÝ‚A×9kBq&(~OAýy¡0±¤üV‡rU›EßFÊS¡BeÚó&i†Æ÷YHÉG–Oyïói¯4„(…;¿½±X]wš^…#ñ”¥NgoÙµ×1¯¶Ò•»czô;G³B.¹§,LŽ¥&§AòùSD*ýMNL)¡©ÝggZ‰A][‚=°^s% +5Ó°‘TŽ=Iýã1E7‰ÕË-
‡óØÀ'É*Y_o©C]ÖR—œKØê˜Nk:ð¦ 2â2]Ê	¨PãLÚ)LçU‹9´8)O ÷m–ÙÚ„6B‡(È2á6º«6å÷L‰×ÒÃqÁ.^*¤oÞÇ0žhàTãpü©ÎÀ´4âú¦a_„8d¤,êëOšS`ñ<r:'N7s	Š»&%<(‡L‹ÈAæBÎ‘·X( ­2"jÏ4ouî’ÈñDÀ
‚’¾ûU)½só\Ã+mÈsiÈA¦£š-øf+´yUêŒ"ß1tšîMv51¯ž©€\îÙåôN»jGÉ®aÊ`ÕÃéh€UµÕirÍOåvH¿„sp…‹€KZP\ž¥\tŽv§[ÎWÜ–}áªDž]6>1Ø¥³?1Ò›‰‹ÕìŠ¬O5“L$’+m	 i$Ö)v¿Ç9Ûß$¿ƒRQ_¬J¥"÷D¤Ý’ãtÕ”KôÈ%YXªë><ßE”„œÈI5ÌÄîÏ-ÜÚ“u.k[£s®™Bîþ	RpK¦@¦Ô\çXõ9»-íK£†›ÌNãVE9ÄW,£«¦¬ÀËàIi©œ¥678Õt‘?Œ˜\ ©•Ne‚1nRçE–¦$)Û:¦Á™¤ò`˜4E`K
'‰­‰!ÈC£Nè«N›³WØÚ±:²LnUÑxÆŠG„µBYG¡€Ñi” A2¶ÕB˜îŽÆT.[}hfh¸)¸E*‡˜úØºôt0rÕ&£ÙT ¬xø×"²èÂ…Æ2#žSœGquWdÚP@-%UPœå dÞf™gÊò—¶¹ðÂ8q°*·2ð{2÷1
«êc:'°á–BÓâd erîÄî‚’,£Ã(Ž."„!·®nÀlr@‹Í°Í$òÊ¤"sùAuÀÇä ™¶9Õ \™t7Œ i]Zˆ&Ü(©Î”¾NþÃ*:Dbe¢¼VÐ1š)-¤£}ÍÚ4ÃŒC÷ª«ý¹šRI›N*°„ÞàåÇYÁ„Í¨,&,Îe³Wü)Xð#C8yªMiX;EÀÀT5¬?2‰¥¤Ó«š<ŒY
Àc?ûƒÝ9ÑCÞ0_²¢úÂ²uf‹zÙz,XE§žd¤‚ä‡£Î×BZ¾ÒUd*±äðjÕ`dL=Ð	¨_` ¾¦S” %ˆÔ¦;’L?ÀÁ´!'Ä'áÕ˜âœRëP¼ªRšFÛW¥HàæY)Ôèsç+ŽÍ²YC—47¤Ú^™’h;]évhÃkƒÒ’\ô)|ªNZ¦
~&žGÒL­ï¬rü\L¥}Æ¼Ä¥þñã:3tBÀ:(Å‘C<“AÕÔæŠš÷#XôÐiÚ™¦‰ä­¸ÀâHÁµEd#pMAPKÖ“XêÃä24ÚsÃZÝ7þ¨öÂ)œ¾™¦ã‹Îc]ZÖ1û™L*&7Ÿ¨ÓN¨)È ‰‘¦›–@u0f¯®¸¦ m3"2†.»‘“Æìîz:õF¥°ÕúF‹[õÌ3FpÞ8bvŸ^æ¤c-¿êý±‰b uÊÔªÖ©œÝŒ*Ã°;Ã‘íbëJ¢Ø0ða÷MX¾ž¢Êåv¥ëÛ ‘Ýâ¼Æ64¿oËŠŸülƒ&4>‹ÏR)o SË²x<å¡~'†#õJ•¹<“€.‘¢3ÅÐRA[·Ý„½”ìò®ùGˆo˜Qñ“¢©HÓD-ð¬O\g×ñÛU(ë‚F%T´G"IÁ4sg¡˜±ÃòƒB(¦d©Èsul4`£g~d$óÐ…%£‚“£a8ÅKÌÑ™:FÍOs«­?laD·•2ñ]Šjé¢ç)>)Ð”Å)É;¡HX"£äŸÐÜÈ{yBâS+ŸÕX¸|%éd,£¶.‡­õê_(<à ¹1Õ!ÈäŠwƒô½
¨cRèJD6Ðqµ:Öº,îß`wÀ8ÞR<P?šrØžSÌßh]FÅâ gµ‰çì*Æ—G-uÁ	Ãº_GîÛKó‚iÞ[„Ù*È¦2š<°…F7`Lo{Þ‹…tÏÐƒ‡©À!ÀØ÷‡Úº\VHšÄÓØdóJÔ¢±z‘rƒ«ä Bì0ÀŒ’½¡ÃÏ™ÐæQ#–‰ÜŽŸI£'À†+£’ð€Ø4ƒ­ã¹èÉšÈ¯À—K¨–M1wð3º
°

°ª‰Y“ ¬ÕÓ¼ëH5ðí-¥ep$5ÙîÏœ'wDáÖUz…Y!?Q\Æk(õð&°xSŒ32;Ã	¥]¢ZÔ›B6|¬žj/…„ìOf}AÕú¼Ö¬Ý]aé cÞ_ñ‹ðªDøÉªà"òß3[€ú8„îëx~ú~&Æ?ìËwªZ0¹!Ž^³;	®{hße#»t ZÜ2›@¨ž‰ÍÄ–L§6:7pãþø¡$õz8‚BA\Â¬e	€N+"\H2`*nÔ	Ú–à2bƒôâ!%»Ç-Î¨ôF‚Ã™Ä½ìuÕNOí¨7££ÎþñêÅÁ~¡~8êì5ÔñýÝýÏãîþ±:ìííw·ÕóƒÎááîÎVçùnWívÞàËIÿ¹Õ=<Vo^v÷Õÿf§×U½ãvØÙWoŽvŽwö ·<Úùáåqðò`w»{D/Tµavê¨;GÇ;Ý®ãõÎv×]“ªuz°ìšz³süòàÕ±Y|pðùQýug»¡º;4P÷?º½, ÆÞÙƒwáËý­ÝWÛ°–†z#ì«ÝØ4;>h8›´Õ£ãb`ü½îÑÖKø³ó|gwà…Ïj½Ø9Þ‡)v^ùÖ«ÝÎQpøêèð ×m)! ?ÚéýUÁ°ÿñªcèÂ{ø$=Îåì9€cÂíª^!‹€}ïn{@A@uÕv÷Ewëxçu·-ašÞ«½®À»wƒÝ]µßÝ‚õvŽ~T½îÑë-‚ÃQ÷°³s„PÚ:8:ÂQöž´8¸Ü8<vuÔ2SŒ}Ä îkÄWû»‰£î¼‚½"–(KpüÎG]´ƒÁ›XžžAÅˆÑ .ð…EŒÅÔÞÁöÎ<Aœ­ƒý×Ý{€³EÙÎóÌsXÈ­V€PÂsÛîìu~èöÌÀ9yd»¡z‡Ý­ü¾|ØePí÷`¯x´ð¢:pÆ8"'Ÿcð
."à¾F˜?s»jç.#¥Ú=è!ÛãŽ¢Ã¿Ï»Øú¨»€¢;ÖÙÚzu÷[`XMïÜÀ}>Ü/]ñ£í@_2ÂÛÝWGEÄÃ™ „8$! sÜ¢WoxøjçLµõRŽMyWùGõŽâyšu¶_ïÐu”y`‘;Ø pdìû¶Åo‹à“{¥$—y<¢g2b°áÈCd~oŠ|p¤­}ÑŸQŠÅ8y…+K|³PáœÒ¥8D8@‘0ºdèK¸°þÏªŒ^ŠÎŽå˜ú£”3A1±å=½‘hÓ:ÍÒæÏSád?PF/â‘³ö
›‰#ƒÙ@R/7È&ø€°éÎì-…Ÿ)z´¸}±¬kÅà%óœíÏK~×©C âp®cZþ#²¼}Ve™ãA’w}H¸´¯ëpyrZ<$²3ÊsÌ€s§â™e…ÜÒ†xF²œkaàÞ9YÔM¨øÅâ<ðŸÎfqˆžÛDÓ(¿'á?Ä«_V5þ%­ëGÒ(F¬AÕ¡­øªS§Œä¯cwÈ…CÜ®ØôëÆ Qq¶9aöü^Kæ½ˆü%ÖL§ª¡_”˜F¢!äyP’½uõ7RjF¦©¡²,f5II©cû‚®ž3œ™Ú®ô”-Ê¦‚\ß!8©¿®ñæìÿ~FéD2ôé4Ž†èA	Mq"1·¾—ªDZÊZÝª«ï°:Ý÷0‘êô½ïyÞcy¯U‡mxÇ½iÞ÷9Îµ>(.Îªö(.”’ÃÌÓ/$ág¾ßÐjLÉ´`ã(8ýhÕO7­—5›V5 ì>ÍÛUçè^ÐI:¤³dÇÉUiQÕâr-²=5yµXAƒÆÒÆOK¬8íª(ypç	^Ê
^½ˆ5Aa‘®]¬&ëªQèpñÚD6û‘uó–ºrN-2KVÙ1ò!Rßçùd³Ý¾¼¼l%³V:=këpö÷° †îaÒ[Ú‹ˆ0í$û7?=N5ïÑÎ7M¬…o…„Œ\½¹Œrâê¡e=r-Måôc+!ÂcšrGéWÚecaØœê6r±S·`/®‘”ÕïdÞïo|KxÈ¥™	¦ç½ƒÝWÇÝÝ]Mæ)©§Ê¯ Aÿ‹^|¿¼ß²Ãï³eDË£ÎÃ†IïzÓ|›MR´±$<u§ëßwÀGËÒùÕÍä.TæB½>Zƒé-ø§_«w3ý‚°sìJI1ŽmK3õÔÁ˜Ž +Yh½ö©p÷^íØêÇòŒ-hF¶U	ðâ4}_3q“²dŠ5ÅPKš5‚{^aDƒØ«í+úE¿hZ§˜.ÔopðskäõÂ
H\L£‹•ñjÖoÊºc…óæÇãS÷/¿ìì<+É~ Zµ¹Üøò6\Ò`é%eËáJcL>éæ"ážW›Øw©õ™“+áÐåÄ¦)ú1#yÖëJ’í¸ì/åuâ%`0y¦È"^	²9ÛÎ(®¢\ÌòfŽ®íY|.u,Â¥„àÓÝ:n²‹a`ÓyÖ=ŒŠÂA…·KêPÆFS:†ÐTÅä<Q:œ_µ/Ï¯š ææèl2jçãœÎïþi¿}Ôílïu[ãÁšcmmíÉ£G
ÿýöÉcúwmƒÿ†ŸGŸ|«Ön<YßxøxíÑºZ[¸öèÉïÔÚZ÷3C–KÉÒha;h6.øž7£Ì¿ÿ$?÷ÔÁ«m|ø-
Žñ±çŠ`HD´•[¿ÞnÂ÷Ýäâÿü?ÿQKy”“L¡ôÂ%	UæµP?#I5‰’‹ÄöÓ != †=â7úNCíÄ´d@Ç³oôAª jÔÙ‚1˜¨6u|8‡¿@2¬k?áöp’ƒmo5¤„M9ˆ	ƒÐ=
NœÏ´ë”õ†+]/à˜mÜ1(úð†¹ƒš§'™'sÚÎ€–Àû‚Ýø«Å4ÍP¼£èn}OÃŸ¢ërhRR¨z5…_aöÀ¸­ÁèÁ™å–Þ^Cu¶Ôè‡–•¡êEH³|6Z[œ˜R ^JFÒéFÎ&€=ÐHó@BÍ%üæ—™c>xÎ°¨Vvþà€¥¡_óN†ñÙL
QÉƒ“¬XÍ’þ9›!b¬Ó"nÇu	R`ÜÐ§'4KÆe 'ŽæÔÐÏKiT`ÅÇEj!çïsõº"á)è›ƒ–(À:¯:À×çì•Xò©ìÆÉì½z½÷þïÿV…kÜNûïØŽÂ\ÄÁ(Ga69ðÅ”Ã›ò¹Ñ§1ˆ>†vÕîåÓ(ïŸÓü®àƒù{©ûZ-ÇA8¥{÷@AÉg“ÂqÙ¸ŽAŸ!›Œ6Øè\—%³ SxšŽù
µ…5ˆ09²ò[ÌèÚK=…»>`Ñ<|^°Ðÿú¯ÿÂå)Áïßa¸ÍÿÝV?Á¿'ýAý¬Ú³µõ6?)Ú.O¦šçÁÆÚú·ÍõõæúÃ“õG›Ü|üG…¾£ãM|E˜]WÅO«ÖZëRxcÞh;û/Ô& bh-g•™ØqX÷ë®.ìü*ãç¤Ëù©y~ñ3ü÷T}w ×v·{ò¼Óë~ÿ³Z8ž‚±é±³;Þß2]jŽÍw/öœÏŸÃç¯¶áï­¿¾:”N´dÍóJýÐžÕ*É]c”šÏ¢ú²á.æ'ïJãaè}CÅoÙh˜º£9Ÿ«mMiZjYpzF/Z¬Ò-˜jÙ%dBuà¾ñ!ÀÜæËe{IõÉ6‚{Ñƒ9YDÃ½{+úÛzkÙž] USk z
ÌºÀËnúœž@üÚªO¨P´@Ÿ”—ç©BŽ{06Óè¬Å!ÕƒÎ–¢Ã€ éxg¿ q¤¦Îæˆ'£¤1ÃT>Ð^mú¢^[6cÅ½\2ãiØ7›dUsòWË'yRŸz,œ”è½³Y1­ùré-¯¢NKv+Ì¾éÚãx0ExêKçþþt
º›žŸÜTí|<)ñ¸Qz†L2¼Â™¢ç”n¹‹W
¬þ#=þ]D|üÆ¥Ÿ-è×<}ð@×¼—˜–æ C3–‘¡÷ º÷äÜÔªÇ86UÖÃ7ÕñZ7ÁÆ!‰vÈ
¤o°u…±Šnx£R¾A©¥ª¤‰(9Û„…¬µAúhóÇ"^ðJ´€Áòc¥„q\¤0ãÒGûÍµæú““õµÍÇ6×ßNYo­µÖ´Dr'³ßB~™Ûy³éÅxºáhe{¼ÊtX”õ2]À6©R®´¹p$—U›ŸgE,BsH÷çvCìü0gˆõ6^ÓE}»Ç['[GK¦o“·Ø¼t°yYÖ×°ñrß¥ý<6áÌiÈþÒ,?õWM<òçg(¶×›iðM0èðè`ûÕÖñ\øëŠý7
ùÖ¢£”¡ÚÃñåúFk£µÞzØZ»ÉÀ/öÞ8ƒßÅÀé¼îÖËgÓö/ ¶¼[oý±µv²þdcáH½­£Ãã“ÿ±_Æ¼ù4táÂ×8 ÃêZ=va·-r¶[ƒ…fL1ç0;ãÙmî¸kdÜ›Ýîê^Ë®bU¯25ø„‰—ß¦ê~7¸GÕoF –î÷&·ï9­ Ži€Å€›tìÌÃSÊR¤ßZFÞß¬#Zµp>é­ÿ¼Í­“íî‹Î«Ýãw¤Â§Ëì¾§Bž”QÂ#ytªÑäæ6ý…~¯¤þ$z¶R÷Æç6æév€~I.Sem¬µÎÿ1®„ ð¾Mÿá¾'}âh_Î‡Å¿OøY:ïc8ýk@Á(>mp+Û–ñRì¯£A<tÿ¦Ù?û@`Z÷“Š'€Mw ôlšb¸Šß¼O˜\ñ	ÿs„¬·×š\Í	6T^ÿ!®ør”À§Ù¸%µkßk;Í&…o ¬‚òÐ/~¬okÅ°8l3‰O°–D?Xˆ‰Gép~é˜
SßøFötÇ{†ú~:ÜAæIe[4^ªÂl¢ß±@´Š¤¬þ©CP²ZXê§æ»·ð½˜ ØS…ßÙäÉ›ëá7%¥!(:T‹ÚÜ†ûÎ*D{|,!¸§¶Î£þ;ŠÄÉ\×9zàRµ•ºÙu¤ˆZMýü”ÒÖ¥¨EsˆPr¹n·t[·•R­ªðM4’ ™¨žªZ÷èèàX™ÑÑÓAkªì9ŒøìdÀ¾•CxÆÎ‰€þ‹=«µ”³…öÊM¤ð³Ýƒ­Î.}s²ßÁI<jZÃ	úð¡k¾>}ÔÅì×ìŸ?Ì0'Åwí<Gú¢™ïŽ+e<¸ê-Õî5…fªmœå‘0œFªÔ‹Ùúq¬“¹³<šHÙÏØ
¾·ƒ–cýRþh«–þ•×-õl+‡Â‰hnQnFFŒ?å0µÆ¼*„iWyà(>÷šÊÞ€…7E‚aMãEW†n‹¾6Ÿtun{yV©H² jrx–Fçú’[²¬;£Î½{øB£c2BXw¦ýó8È§Ï¯Œ]ãvi¡±½á6Íë¸*¶\‰aÌxTg?—KP±q¹V4</¼yËËí™©R¡bw¤-ÜWakÀ¹œ9NUÏXÛÂ€¶âKp³¤Ú,ËÀà­éŒß˜3U@Ü±pìÖ+dc^‹º¹Fó¹cµ£°M§xË7ù‹=‹›¹&DŒTwžÎ=-g«¡ã-	ZC[pŠå]zN,@’¯¡€/ì=ƒ=ê	4Çâ{fK±.á²ÂÒñ´‚à#¡
?ÕvÄ¤ÛâÐ°YþQ‹Ÿ`CK¾Ýu¢qá‹’@Ë¤g*–ìãv…9AÔ¹·cÛ…&á­õ×Ô÷3·²Eµ«°sù´´R¹LzAhÞöÎT*4MùÒŒü<úïnwéã†¸dø÷^oW™z_ÓÈ†ú#â…z"eT¥@á„©®žs6e3C/¼fdÑeÃ©ãÎÌäí	kÕ1Hiõó_¡oB¥”¹XýZj7µ¥ãJÛ€ö+Æ‰\M‡ã«"ÿÁÚÄ" Œ%<µ	.Àj×ª¯¸D{è»Ù£¿=ã
zeéé«»Ú #îš>ãØœEû;ëbþ¯ÀÄÃc/tTÜÎ£ÑD­ž×månl²{Ç´øœÚçø€³ ­h¡Ð@›&b%´J{+Ž]yj-kgæVŸ¾ 	5öã±AªÁºny¢W,ó#3…mÇÞHõe€™yY^µüÀPÍÆr´¢°4–žúÑK45n©=Ì¨áàì1gý&˜¶ÏTçà¨²Žôb½§D$WÜ©Ó¨^Ð1§îþkõZ3ã¡î™?Ã|AÔG5[›Û°šÝU2=µ éíqC˜Úu"7ÔJžš8àŸE—[å®+<ÈTÈ„»'6O]å“âa’vèþù9S»Îs,j¢ÅS®RahàÜ. Zfy%WÑ<È¬7/ráòPtÓäTK$VyBlÃ3-¹ò.²,_&ôgpÕHž!¹Û©7³L¬'­‰EÎ±Â©÷Š¡'´ -Ã^|àê£6%Mž0näCÖû³Àœ«¾,Yê/^;ÍÝçÿÐZ€1Þh¹mói©OO"0P§Dù»®ôrïº;3âzçïÚ±jÆ``'ÄÇºñÕ:
ã=EœFgŒ
Žô•µìz…,ø«øˆPl˜œN8È¼åº§4o½4©v2Ã¤ˆßî ð7OŠ_¸“ú«'Å6þTóªÏƒ¦‚ë±t*ýRTÕþ>iRAÝª>»t+|ªR©ïnï¼ äÇ@´YŒÁ´‰/|úò‡ÈM–ç6wYTˆ œÛœ?xR'ä©ÒŒÁä÷UÂú…õ·îƒ’Ïú:tØh=ä%Tºˆ+÷]å5~ô¨Ðç/ð=UBeèžD@ÛOi£±ËQ*bÊÊ+›ÃQ<Õßcµ…ð%çÊ6ƒJ\XÄj%VŒŸ©'ý”V°}°×ÙÙ¯€ñÂÛÆÇÞÉ
æÿ|Ôb°þó?Z&$SUî‰µÅPA=zÆÇçŒçÎø(ÐöÖ©‰ÎŽžç¥gÔ uìT­&šÇT¼¯ª–Û†O<‚ôQÛ‡æÇJ'¯dã<ùhùä@ÉQ|7½ÙÌ¤´¼¶
Š‘ôO#Lß“WÂ¬­‰5ò¨2+•¬ Ý Z/àÜœ;™ÝLa5û¡­î«3†JdÞp²»Ó;öØY¹òƒ]óð(ódÆÎÇç<Ðá›íÿ¿½o]oÇÜ¿«ïË;p•t;I[ï”\­švl'å.ÇöXNR]•Z/ ¬X&Õ"eÇîÊ>ËüØÇØ_3/¶ç  	R”å‹¬8UDÏ¤d8¸œœKÿõî^Os˜OEÕdƒæ$ÐgÿJøŒ/­üŠ/¼fü™^ˆ…’lÖþÁÑñLÛ¬ý\KôêK¿y£]K1õ¬ëewj‹Áí.êWñ&n1P¼È[ 4½ë»_Å²™ãeÅ7èâJñ"|_m2ÑwJNR.À]ýNaGAŸß5å{ÃÕqSdÛ°Ò-9›PyÞƒJ#ÌJK°ôá÷Qø®ï±*…cûäEsXH‰~c“ž…„9	£/¯Ös8Šg[¶ùØIù¼S°"ž1%˜äºI<Or•ò·üÌJŽúYá7jô’½”äpOp´Í.ÝfHbGè¦Ÿûj¡nPÄÃ“"+sF‚gÔÂKl!½'“þšPŠïóG¿¥ø=¥ôîz­+m’úýÄârÛvÙÑÆð]x¡PW?ñV§4.DÐÒk”Ü(™LÐÉq
s
HìÛÍ`r[Gô>š¿Ý´ˆ†B§O¯éôiöfGÃ ØÒÀln4˜mJñPÂIõ¹)øéœAðSKŸcÏef5â|æðÜMÏA„x>çBÄoá˜œŸˆî\
ú[jÑ[p›wI°úMì¸ß-ôsÅé›@«’N¡_OæØ‹>Ãñ?fšû¯ÿÌør}S"=ój7K¤´ôÇ	³ð×½ý7Ç?|Ï‡O¿]xðëMJ€¤´0:	Œ§™@l™†±]@ÜqÔ±—\jE‰Ðäþ;¹m*)¼ÿ¢)ÖÄˆƒø$‹Àä7“EÀÈK©×Ñqýÿã?þ#7Ø6dð )R;k.Í¦'î³Å>}µÖà¿þsž$?ßÄ»·¨µ!jkSÚ*âs3m€½#Î¢ß`œ"F9|<“z×Aæ§ÍäDèË sóŒä|ºŽ‰el~ï­Ä$DîÉŽEèM.PìËw‡/±ÂËíƒû/éÕî§pôaÊ6\Ö¯˜X‘z¶§~€ÎX¬”ä ¥OI%OÒ_ÉfæÎ~Øã“Ÿ†[³…7‘ÂK›Ÿ¼ó$¯$hSHc¸f©Ã ìý§ ÿRÆÑžá´ð:–”âT£2º¢µ³g2V+{5ædæÄ$È^Øø"²V¸ÑÞ;g–Ø™cýtiG¨âRBqQ’iž‡PaTœæ"ú¤XÃAÐ$Å)vŠô&øûzì6“æKoDð,AÛæ\óÓq‹ºIÈð¹øŸjª¤˜ÌÑiÓ€oLÝÞ=R¾§ÿQ’x-‚&H ˜Òƒ‘O[#„ÅNFª×/QMyÇ”å°ÛXìùìö"îÊöjSÚdJh‡t*‘Øq¹tª%ÔHgR…´EhaÅ•:éJ5öœé ù„†Ï‰'‚âÚBsé™Oà$ºYê#)ÅÃ¸H¿¼ÿN5|Ç(_¨XŽ†qÏÑN´Ñj!J6´ì¨³eáœmQMZ+j½Ø¨Õ^J¿ì$zù,;ƒ" ÉÉŽíÄP¤ÅŠ¾ÀêÑÔAAès‘æÞ¢~*½ —¸HKÊñ'¡1ó—wG¥s­)7ÓÐ1¡CÕµòÚRoz1s³Ísá”9úÚn_Ò„JûMÎV=T×ûÿ‘e]Q™ÿÅ2CFÿ?ª®TþV‘j©€{D9Ç]ºÁž{Q»Ù%Dy*ªG0¶=Óþ¥:ù[ˆçÔy,vÎú	ç>ºóµWâë$ºÿùŒ7£û!ÚX°ÿMMÖŠþ¿,C®öÿ*’«:fÛ²TÇÒ•Žlz¶íºmÓTUÍµ}Çí¾«¶¥HÿÖlÍÚiše)¾ãYJGWÚªgª¦Þ6eU³=¢y²kY–Ýö}W¬ÙšÙ®a:ºÛÖ:qœN[6:zGÕ;š.kŸtl¹íù:QÅÚ™]š¯Š{PÊVMC—]¥ãµ‰â²«u\³£ZÛ"BmnAl"«ÅU}S¶TMñ5³ãxñ<Õs-Ç‡êJÛ3t¬Yn`¤C™¶¡É†mzDnërGQ¥Óî8¶j®×6Óñä< ^—Ø²Hßñ ”ß±m›t:®jé¾Ö†)t;m… ,­Ø¸hç«¶éûŠç;²§Á$Êºë¶n˜†£hFÛ…‰Õa	 ÐŠÎðK±-ÃuO7ü¶áëžãØÐå¶i«ªê©Žj[¦Øë¢Å]ÛUEµÛ Þ6ÍlÛ–Ü&^GÖœN§£M4tÚò"{2GQèÑöÜŽß±ˆSÝ"& c[õ]ÙÖtø<¬r“8C Ló4_mñ‰¬·5ÛUÛ2Ì	i^Û³faÍ¬­¬ù®+ê«®§éšA ›m[Ö-Órd@'[‘=ßµ´YP¢%ñ¶¢¶SlÀ¦ À\ËôtU¶Ö©¾m:ó:ÄúbØ²núJÛô:MöÝp˜z€®˜££È: m	ÁöÏp£ãZD†Á€Ú¾ã¸šmØáªÜvLÅµßÑÕù“sGÜ›v[,œPÄGæ6>@hÛšKœx@t|ÛÍ¤êšçª°ÃJÍš@ÂF¶|G…™•- f€ÕnÇ“}CÑ]ˆƒm«šo»Å¾	¦›j[•,˜€C†jÙ #ü«ËFÛò`âþŸU˜¼Ý©hl*Ð@U#Dƒ¹¾/ûmþêÈSµdfÜ.ì±¼eitVêéèŠ¥Çî´‘¼š
,<Qa™[UŸ¸D¿NM†ZŠtJš‡£Q]ÙR`HmUqdÏÝ²‹ÈS€‚ÌEÍô0tš'–fwtW±Êj Ÿ ^ÛÔÑd§8¹Ô¤VVúÜª6[´ G–æÂú8ŽlÁ@eØm¾f(Ž
{Ei[.ZÒ)©' 'a÷Ñ ‚¦Ž„ˆèN†g*¶
g”nÈ&…ž¥ZŽæºªRU¦$®/zâƒžÛiËP;®¢[ž£›8;†ÒQL×±5ÇQýŽì¹å0Õ~ê?'7~BL¹äRVU–Äî8
œ:¶E\à·`8ã\Ó"·€Jg@±;>œÊ¾I:¦ë™pšÃYj›šcÛŽ¦#‡à)61æÌ«Ögy}Tˆì‡¾waØ]àxSw5$#ªbœÕ1mEEê!¥`U¥ÏÌJFÃ+¼Žb…Ú:º²a¶…è¶Ú±Í¶bÁ'1À¢T[v:ùv9LµSE˜ž­ulØmöÉÇ'~¨ÒîÈ¶ïµeK¾Õðé¼·íÃx-×&ŽoÀ9Õ¶t8þÛmà7Õ´t×Õ8—V´¾ðpÔ‰ˆöX£Ao{* &Ž_¶‰¦µÝVËƒ]«/Å÷UÙ¼ñF@KðØqÍ×<ÓQ­¶Õ–;¶îÙp¤*žTÈ‘âÍC6³Zqfi?`mé€æé¦e+¶€é©&‘8à 8µ;¦U
“w’üãËší›°Ÿ@¨v¨.1xžÒÖýŽ¬´a›°%ÊÑIQKg“®?€“m œøºk{¦ ÐµoSMØ¿Ó)ßVŠÜg
Eøø#Äš¶é™¸>l×ž„p€0Í@W[¿ñÑxgàŸ™ÒKoÃ“uµcµíŽ| 0?ê<bUJ§gªºãz°ËÇ&Ä—e×SÏ ÞøÙ¡A‘m™Ò}”!÷v·vö{;5Íƒ!9(FÀè|`À€µõ;p`ÒÃÕ@~Oq’z™Ãˆ¶®™ÀŒÃñ/ËmØ`‚)W¼Ž!¶a)n›¤-&·VPÁ}I	y¡‡nå~Ã˜ÿ‡ò2»ÿÓAtÔ@þ‡ýfüÉxèŽaúƒËÿe2Ð²ÛXpÿ£k²‚ërƒ›ïtKÓªûŸU¤§7T$[|úTJÈobàCô‚ÙÛ,ˆ}œú³ÔãPÏ_m÷^@žMèE:Š'vIí¬KÀ"ªÒ8©bg2Ö¥ÞÅ0¾"t
_[f‡QM´ÉÒÆŒ±,|ß¤ñaø÷^L|´ wàÒóD/Ðä5Ù½øßb>~¼+‡Ú;Þ0.¯·Q8JšFwMYk*møB#Ï€_h7§ŒçÉÊRK)nå,ê&âpB8Û˜‚a6cÄF—ø.šYP–#œ\bª64@ ö†o&ZXü@PKŸáXŸÞî5´¦ü—¥.â[Œ5$¶€Ž"FÕ‹YädÌCf…_¨ÅØœ -ì½!Zj‰w»‚›Ÿ»@zE0pL“uî©OýÌ†”|F¦sÈ¬Ü§þÔÌ/ß8…ÆÊóX„YLi=@LÓ_ð¸KWþ¨~žéŒû,Òà—Þ°&.—sMÖæqòæ 7‹/ø|áQ·=OP’Z¦ñs(<îÌ0=Ç½½þÖ»ÞñÁÛÝŸ7Y„Ñ§¬ÔaŒ/oœ›ZpÖÉ(÷aBßæ¹ýfÎêb=gãWt3HaÎXx
0QGó:€B‡R`y{Låm ˜§Ü„¯/øÌRhy‡žB×rê¬¥ý›5Î,ÚÙP¹AÍb˜Ü¡°*‚ÙÌ- æ'Qð-‚ümÞ	4Ö¥ðfm¨xh1EujhÑYW²¢£“œ­^¡Í¼¯tL‰ðf=ÂŠðÓsF*×‚EÏ•O)àíÒ®9l—1Ïî$ŠUž¶D,Vhs©Tô¯¥üûJú»_*<9<H×óÿ æ›Z¢ÿIeï¿jÅÿ¯"-m‹~ƒÀ<à1³ÿy'f¯¹#ÇÄÏU0¥Ÿ‚eG‘£Ï³@‰Îá®p‚Ï
œIÃ.ö0HT-‹r’h«Ü­|ªd†;ôž¹=`·Gœ™ÕæmZÁíuÄög6—ï7ºïÑóÔ'“©sH‡=¥»öqú·'/ZÒ/Ì]aÂZ~ùUZKJºÞI¾flÓ—ì‹ÝÍ×cv^B§+øAÌ²G<›{|¹IKC§ØTäÐ-`®3Ë_¡ìIiY¡Àh>0´äÍJ†NÖåBìâ'îâ›€“¼+¨%'Ù ²V3Í¦“¸»?¿[NKlì¿¾é„°•xs³!²ÂöîQº¼©ðð…ËQ«€R"€Ÿ¨Uà Üü} :à¤Œ+*FÉúc¬£9|Æoöaâù ²¹L7*7ý¼û¦*lTFÈ?_^u×èÏ%ðpžkK¥ƒ.·þœ±fDa2‘éjÔ6ƒT¥HM¦¿Ô@¸	yj¬þlXô†›S¼‚ïõš¤Æ=€æS»k®'‰ûø»IÑ‰MÏ¤†+%õû–GÎ[Át4úm€Æws©¾!üXÿÏ¦zÔÚ^oîîíl?kµÒ¼g‹¾ßìl·êßIÔwhSjÐÊ¾ôñ¹ô¿¤Æ‚ÔÅÖêÒÇRc<±üÛg{2€µ–ÓÞy^>÷g;ú›GbÃû7©á«b76··Y'¾ü!¢5¦Ð8óO•u…×¿|…Â\ùR	r'÷&‰'¹xp%5Ž/¿ãž[¹Ûù¼&mªõË´n…øx3Øué;X¥†”Mþ_L¤ÞÙ
(¸PÈ™[Šµš=IJ
<û:,T T¼¤P‘p	åOæ–
®Šä-+M½(Ñ
õÂÎ¨‹…|Ï‚Ì\!$æ3… S,$`ûHø:ù9-L—8¥¹Oæ}ö"è|j¶Ýh$ö¨½IÀ¿ “RSÑ|»Ñˆ'@7G#ø	óámïKu7èf¾jÞRK×IOœ)P¶75üÎ:1‰°%VÞ=*ßí&ÚxF`rv¢s|½§„Á ·ãÞ1õ¸}ýp’	kšžËébBÀµ‚YcúmÌ>Ñs+ÍdV ø%³žL>¬Är,É5»k£cB5_BçÜpNºö4ÓÝµ=ôµ··y¼ÓÝ’°°=’~£\nZ¨¼”“~ÏP2=Ó1Ž&¬£x’fE,«¬?ÑˆÇ™}I-ŸÑŠ: 	)EÄˆ”-¬€žÓ1û0g™ÅœØ•XfXC¾~·˜µzVÜ®:µKªNÝ€€Ê”èv02CvÄiw-gEþ•¶,m|zöu;¡göä2éÖâpU“"ùû–FuQ¾“Ë’å¿Ä“cå</÷¿?6[3†õyÄù0ì®sÔ’k××Ø÷Áëû3¿Õ±˜ÊÕ¼—ÛÆýÕ2ôTÿÃ4PÿÃÐôÊþg%©ºÿ-Ó¾Ák`ÑIBu¼õmð·y|£ëÅ¯q}&IO™Ë\?êgc‰ƒ¿Ÿ”=ÃZ‚‹,j´4Î§Œþg–YwÆ,²ÿ×t3Óÿ…‚²¢Zf¥ÿ¹’ô”’{!¸žÊFÞ¥*ž‘˜¯²|\™`ž–åõÒLenÒ»–$Ó`™GÂõLòÉÜSÁ5È ôºt°‹ÿl÷vvRÏ5·ß±_{–o*7¬\n‹ø]àÿeõÿuS6«ý¿ŠTé¼Ñ¼øqòþs4ÀËYõJ¼âßoÕÙßSþ°üó·ž0|öC·qCû?CµtÍÔL´ÿ3e­²ÿ[EÊl‚®Û¯¿&«rµþ«H/=ÒÆÖßÒÌjýW‘ò^q¦;¬¿aUô%iÆÑ´qûõ×Õêü_Mšã…j©m,¸ÿQdÅ*¬¿¡£ÿ‡êþçáÓÓ¼‘.JK‰'ú4màI~9aèK¿àÃÆÿa3q¥_¿ÃâAí6³Ìš?DPï"¦ZíRÕjñqâÌc`lh{0±Ï¢Zípóø‡î3üwãuÕd¦ˆÎ0àôÝ(±9€rT‰û„¸§™•-‹_`Së©M3ë·¨7Y—ºR½žö^’’‘ÕQÏhÒ°êb)Ij–•€/dZ€éÝîáKmbbMûTZ&‹ÍWbÇ“ø°gk)¹Õ«ÓÙÉ”¬ë'
§÷KœôÚÂÊ•nÌ-•ûì[n7=ÿuÅP,ý£?Ïêü_Ešñ	ö mÜ|ýuþGù?½òÿ´’t3O›÷kcÿ<Ÿ–¬?z«“dUV5«âÿV‘žþ/Ê ×ödy—îOîòøäÏKîsîA°t'<¹ß£à“k_ŸÌ|2û.ø¤ø0È¢¯KWÓ3‰L £	$GdÊWOŠ¯„Î-ŸõžÌ{×[òzˆ/{O–õ´·Ô>R`\ÜHÃ
rÎ­€¡dñÜN˜µ‘übŽ7ázÒ,7ßL¾ã˜¼Â#æ"Œ,f™¯§zReF©MÚ(UuK+ÌÊÅ
InV.±³Ê—Ã\ÖLÐ[
róeò±b“2˜[(—‹{›–cö‹iÉíÝ£·›ûÅVYnV
¬í™R,÷]¾¼U#î+üÿFDP þø„ÂFÃ‚Â&+rˆ¬êóÔ	ëIqt‹²7Äd½+~Í™ÃÔÅuHJLß¾$ù#ÏRs6áb~$| ³œ|¤w[aP=/±›ã¤œ¼tÂ2 j!ì1ìxž—Ddí‘‘ßâm‘IŒ×ˆÌ¼3:ž¨ëðéü¬‘¨OðïÜIóqŽ¢ù¥‚°1ž„gc!ãpŽ±9á&Ûr)ÍOV#‹ßØ-ú=ÚXÀÿYš–úÿT5ÃDþÏ²*û•¤ŠåË±|sÿ1s}?O#›ÄW£¡‹¡Ûh1‘ü)üãÉ\ÆoÛŽ¤½íÝ×À;M¨"˜{"yÇ¹Èr¯ðÒ“¢v˜=õaù¦>	šÒ+2„ÿ÷ì‰/ÚA@ÁÑ&ì) ?³ƒ)šÁüåJdâ$(Rq¥÷èã’Ü@;O¼M¦G8æ¼"‘{›Ö™?(m#ØÃDpÃƒü‘!dÀuÀSlÌ…Çe˜ï Ö nHèjÊÑWœ€Ï`œ¯Ç
ñˆ°Ûnh~rA†1 QYèÄÃ4oìù,aÌè³°£sjì…8N }u<!WºPkiÓì’t“Y^‡ßG¸›·÷#üÍ”6ŸÔBçðO[# •€J$>˜AÜƒÂ·qYfŽ9^Ôpýå	^ÐÀ}^(NvÀ};Ú£¤­©À@nHÿêõ~Ø4õËñáû‹¿ôÎ§CÏ}÷Ïw‘Õ‰üceøîpô¡sñÆûÇÁ@iO['§ç?¿\z›?ýp°s²ûþôhÏþ÷ÑÎ¹ý~$O¶Þ\]]üØ:†n¾ïã7¯Z?ïØd:Ü{ÿ¤æ*F¹¿ø`·—„Z}7
3K‹<kÈßnHÈõRdÁGh! .gQžÆ'“p:8iÀßÃxCÒà„Ï
DÃ+’ÿ2ž“`ŸÂE¶j“.ä;:µœE¼Üžº=Ð>Ç~V}a­ ¾šhùWpH¹'ñp sDAœI¸à¶àË'Ód¾QñãOŸv[ÊÁ›·ã·ùñÃO?‹éŸ‰3°þþü#¾²~¬O—þöÎÉñÙî£Ÿ>ü}óý¿ÑÅ§¿ü]	È`g¯}ñæðô³utÙyµßúy¼ÙzÛêý`žýóèÇýö?Õ#™Ñˆi†ÆQþÏk©D¾Üœ¾6à]`‘î Hùx‰†ìey	¶ª`Æ¼k\L`O”—@G[ÆÈn]_fBy™èÏ4lw4§+¸ÝG^º¼º¥nD—;çóýá%^€€ÐP^ìÓÙgÀAÒ¿œÿ}þ”á×kæyþÓ2¸¦ ã[Ëœ!x9w¢÷=8Ûdˆ,ƒ±ˆå¥ØÝ]5{^gx™èdc,öÒBå'à(.½ÄòÌ.žf)ªß…ä}‹·'ß~ºa »{µ±àþÇPÌÔþO‘Uúþ§[•ÿç•¤êýOìsþ2¨t'|« U¾ÉUVÒ÷?8T®bþúÇ/€§ŒÏ}w6 ÈÓ7g¯cÞL¦—röü`ˆ·0”÷ÃÑ #‚É5‘=õÓ'ÆHÔÃdÖÒ›O¹j ù¬³Ð±)†ìÒ'wCUÝ Ý«(b±÷‹{ÙR”¤…#à˜%÷gñÃÔ‘èi8™ÓXŠ{0%C¼ <¡Eº¿é«4`MtJcËÐ[¿¦ôaHå'†('®ãÝaDQ
Ec°ï(£Ò¶ Â˜~M„ˆ~Û.°Z¼.Eè6-‡Â*™Ž€Î¹âóy²{šË]‘Ä5Jæy³[o…ã˜‡Š©ÏÁw½n½àóäoêÆˆñŠÚT›Jð[¬+¼â•‡ç•cn¥¥‹Ž’ç (í^¦ ¤OÝf
ýLË=~Sk”B7Ðù%ºä`¤‡]RþCWÑÚBÙ^o¯«˜šYÈ>Ú9ì¶;´4çfCÿž»'áf·îò)Æ{Û;x}üaóh§¸lQèÇÑ¦užáDk¦VcÓ@Õäï/-ŒGSRîõÛ¹bþÙEI©ã÷Û¹Rñ¹×J†ºÙÍH]
½GwË]5¦¥`Q°y&{îòöTBxóeúê‰|•Vüqç½ãƒ£[¢Ü§ÓhÄá¬_£ùšc¡÷û»[?â>èÖ“_ÙpjþIÇôCÅYãøüÞ}ö<}\IJ¿ýFµž%Z/ðì}J`Ù¥K•+”z.We¹j>Wc¹Z]”ó`gÜ§+Ñì1¥¿Gä?ÝÈä?øG§ïÿf¥ÿ¹’TÉbŸóòßœð˜•¸Tæÿ÷ÿc¯0›Ó~ŸL[eÁWvì–<æÿ˜‹ˆ7}ÃR½ÞÌÈ&^œ½òS_3å³†÷¥³ÍM©eŒ›Ê„Rê@þG`qÃ…ÙjóÃ–C]{ñÑAÝ&]FTÂœ…Q7ÓZ z
 ¸\‘V§SÇå€J½c¿’†,b$eö .¯!Á×ëž
¸‹å<)‹IÊ¸'}³ûf.,Ä»:ƒ$Æã-‡Åõvì½ênª·›ûý©î.Q%7Á‡|©$7+—­¶X.Ëeê»¬ì¦çqf˜ùDìÑW‘:Õîëö´…J²ìyh‘ší¸DÅ6ñs?«Ö;ãá¾T¥—+µb×y¢+sŸŸ<‚åô1¥ä7`Q	øžÃœQÖ='ŽÉäÏ4r@ªtG‚K4¬‹+þ;}šº!ÿ/àü¿ªèFÆÿÈÿ+ªYÙÿ¯$Uü¿Øçðÿ]˜AÒW‘BÆ¿¨
,Šlþ­ƒçˆE•jð7ÂŽsE§D…ƒ5‚N—7$Æ–,ù¸{\^•riöü×úlÓõQO«ÏM£îu¸Ðþ[—³ó_CýEQªû¿•¤êüû\<ÿËwÂã>þ…@tÄz-l«ƒdOnØLùñÏ¡ÀQ5Ç9ÖA¸²Ãþ|¢
Y8¾Ïà€cŸ¨Æ$c&šÒf ‡Ïoæ ã2„&.àüäê¹4`*Ž$®îãîÓÇê>îaïãø–@¢Á¦Ùg+înî¦w[‹ÍÒY¹ìûk{¼èþ	GÃ‹2ˆ0)éœ0‚°„H6R#xw4õÈ«	t‰ÞÑ$=Ï.q¨
ûî6Õö§–©aúÐO.‹Êî¸zHYî9d€ÀÇüÝÍðªÒçá†W”6Š•ÖÿÕ¬Ìþ[±TßµÊþ{5Iàÿ–wÈÜ…û»ó·ÔçX?Eí¡wû¶çÑ 6é,=Æ  ‚ïŸtûrµ]à¥hÌ¥S:˜»w{Nj#µÔÕ€ÑJ?0N	»¨BJçÎ,Ø©0‹tIdÞ%6¾<öèÆÜQ ja.>ÖºÏ2Xb(ô9LÇmyŽ>Þà5P(¢HE¦„ææÊ¨¥eÔ¬G×<*ÞøMQ,x´s8sÓb×¿<ÞˆéªñRÙ™›[4d3?8¸ŠlºüIxÆ~«õEOq"<¡™5ö.×c¾b0þ&—ä	–ß)lp”baur
¹KÁ£OûzÌZýÓõ¬'N‚®{Þ«å¢~gÏ|³îxj·™O^jœ$ÑÆK:¼ì¯<Êõ,ÿ§ù?u¥üŸ¢1þO¯ø¿U¤Šÿã®ø¿Šÿ£Wü_Åÿ=rþOø?e™üŸrþOý=òÊ–ÿ›óþ{°üå—rñ_T Tñ«H3ë¯h¥¬v!`‘ÿÙÈôÿpî`ý5½âÿW’*þŸw8ÏÿÏßŸÿO¼£Í°þÔYºn;›‰ñœwå¶zäÛ¾…ÐÏ•,ñèd	­´Œö;‘%Èì‚ååAzbn8®ÕoÅ/ó6©@ÉËJsfÖ
 0P½ÄŽC)á›é¥ï­–‚V¯­–€s(ô
Æ»Ó	vRVG½¾ŽZ.ú”Ê©<t q1â2¥ö˜dJ­’)¿a™²JßNºQü‡‡}ÿ±d#‹ÿ¥jÔÿƒnVòÿJR¥ÿ-öya0ˆoKù;l’9!¿¥K‡9Q1îêÐ¡Þ¨¸s(õÞ0¨ÔC¥A~>Väò$•dŽÇX8é+`P)¯×?Üìõ>mI‚I?©±6€š„å ðûÅ	¶ÌùNòB–‡)ê>{|¦DÝ€M'¸»Î¤ß  Ôð\©¾ÙøÙn\ÉN2ýpäII‘áëÖ$åEûúôôiòÉ€HméÏ†u‰êR·+½ü€ýú2ŸÀ‹YÐdI¿æ†—îB&³¡u 2)½¥ûC»èŠ{2´¥î÷ÀËWu€VœfYfûØƒ·gá¯Ã.JB†ƒl1¡-È~{aÀ`€ï¹_ê",üu@Ý=JïºÍ{œuÓ”JÀ‡l‹ÍÀaž¶l‘6f
`ëßðY„†#ßõvŽ¾Hsªmæ¡cµ¨¾ÜiÉV¹¸KªXÁ
 Ê#£®ð³¦|ÌŽ5‚ÛûûâõÝMœt>€i:-É"\Á}So¯7›å»«Y²7XoŒâ9ÇwËm\ÚTnkî˜*+þßešÕÿÕŠú¿÷yú§éVú¿,þ{¥ÿ»¢T½ÿóWú¿é]¿Òÿ­ÞìÿPoöÕ[mõVû(ôùÍ<ûè¬9¾\±ˆÿÓ3åÿLM–dÅÒd­âÿV‘–unY¾ÝÀ&ðÞñò‡E÷ðè0Ñ×äöŠÌÇx ½·€ñ«eð¬¦¢6e½ÀàÍáîâwV¢•¶Ã3{øptZS³ÆL¤0Bìê¬FäúÎ“À?5ÎyŸ²t4u¡V“—mHü|mûàíæî>x´¶.Õ))í³zõ	€1^Ø\ Ï+ÐšÊJ‹U‹ZŠêÒŸ$¡/jôêÓ$‡Aü¼•_°Ã‰†@-YVê/’ÊQ4Jê_W¹×Ûê«Y}z!;o8Ù]7V¼ ,íÐ­§ÇH_IÝzþ ø£Úx‚ZcÈN·.ç¢~ùSôëZa2¾+?L¦y¦8.@Vœ]¶¦s˜Ïf·X¯$Ybi>Y…wÙü”‚ÇùËJ§OYsJãŒAi@UN>ìõbÀr(}`9ÏÙx÷BÎé¤S-ÌÃzî=¥d²9aÕ²ù¸®bŠˆ¹y¹®"ÎÔ¾°¹²ùYT+›µîÌ<-‰«úÚ§õòÓ¬ýÏü«»¶qûES˜ýOåÿs%©ºÿãþýÜÿUö?„«¬îë]âïÛ—ÀìÔGnÿ“¸¨ìÆþ§ò)QÝ)/:¾6³Z¥¥§YùOî3Ú.rÀÿÕ2²ø
È‚ÿU«îÿW’*ùw8/ÿÍÙß€ð7ÄØ
ö(1­q’Ã9*(ƒ¸ß2H%ä]+äM*!ï(ä•,¢üó´äÎÐó™¡‚^:÷’ôˆ©¬—Ó„Î‰{™ô­>ÞÏLä+oA]ÐBQî›#øeëtÑïúZ9áOU‘cùÿÅxþ/_Y ´"Î|tG¹¯ `'nŒK­(±E¶l:‡Ô6w0sûýÍ‰n7²ÿG«ˆ{ð˜ùYˆÿª*”ÿ·*þ%©2ù_dòÈÿ˜þ™u<f‘^#¼fÖÿ¯H0ÅyÄÀl3†ò©õSÁ¬hÖ] 4à‡£	0¦\®)ø›Åi•†g¼gÀ½ŒÝFâ«¸9kž/†Íú=jèo;ÔþfVüA‰ÿœ1$ä™IFÁÅûÃ™Š45€˜»A7³×djk ëŸ ~ÂÁ6~Bûé90`œÁ(tìQÃgÉüxnÃÀ@Äò×#ÒH´æ Bè|‚ž¸81‡œØçÃp²a».Ç•ƒ{ôqÉnH›ÛÛÌ2=ü1ç)ˆš3‘	6'BÄ](¾³J ¬A=r¤8èß›:ñf¬A÷ŠGF½ Ú£_øŽá“×¥³)¡›7û+@÷$Tƒ‰
¤Í­½µvœû(-5ð¥›r©ÃFDGTÔD'á¨+åÈ$Euä†<‰ïÛnÔŸÃa; 1¯ÐýXWšj³­ËMEÑÃl*M½Ù–õXÿ9·î I¿“l˜Ìú6†£úWôÄ <J'§î§ŽOoEb½üXÿÝðâ9PxÂGúîÐ´q…­Ó‚ÍŸ [‡ß4‚Üö~„¿Ùf /êËÄŸ}°3þ|üIg~)”B[ŒAÀ2w–ÿ/ï~/	`¡ÿ/]Íøã¿(ªeVüÿ*RÅÿB>ÏAþÇ,$“o 	œíŒGžáEñÌ|ÿ\¶ÿÆ\ÿ]˜þŠç_=ÏÿÖŽ¤ÂˆûÈë±«>ÒÀ|Æ‘\»Šé¢Åcø¾‚6F¡kðò”µ°Œ6#·v@—’¾ÃmÆ@œi,½'˜(´Ínë6mÞQ°/ãøÄKÉæ]ºEcÃàÜ½†Í{í^±ý¹¼Ü˜·™3)uõuH{ÁO<5X×ríò,æ¶¥ ÅãPêb')/ H¶Ð/m ¿4Ö¹wc-$¸ƒ´ÔÅ÷îN
Kós}ËrY÷Ž´´wo’ïi‘qM:Ol7ÎÚÚˆÆÄÚ£FÿO/Åñ¤ÅÙVØ°Gã{C_¦g€3î†¶žÔT×g¿ñ6è}2%Å¹cGÂ8âL€H®ƒžp«‘âú”.Í!Bì<®[ E&œž=â“Æ+t¥÷1­üQzŸ”(­Ÿ¢áÆT´óŠr@Ù Ø o€EÎÈF½‡OâžÔûa³¡ä:	û÷4œÆï…9*ûì… ¦ öÍ4ˆ7´Y<Äž5ÄGFñP,{{(Ö€lX–e¿xm›äóxÈ7ê0 ,‚éÜ0u
-7&äŸS8Ï@¶šNà¸Èf†uéöûh>JÅ <‚0ug„:¦õÝ
£î„Q,lýÁ$Ã'òyâ>Ä“xŽ"}§ùX7ï‡v7ð†Wä3|àHBÐ†ç@‡=ò™³KÈà(30,ÁÉ Âtò•SP¾_ŽÉŒ <¾œ÷Ð;B®iÞ÷hêÀÑ
glZ ³Ù11tÓLVƒöè¯Èa~Ï¸ƒ—è0¤íW˜ÌI~t$]ˆÒá1p¨ý™á°Ñ×­Ãxæ«æ«&Þý÷ÿMnƒ?«ñ8.ªôèSvÿüø$ŒQ
õZÔdyim,¸ÿQ-+ñÿn0ÿ_Š©)juÿ³ŠTé|&—€óT½s/Ù™RNjc^©Q„F7¨;™†`ñÚ†{Ôª;oÙAjDßœ1´˜ÌµèûsŒt3j±‚&ü¾M-!£áíAFñÐ½”ÛV]SÐºÿbî˜§zkÞ¼;¤9n8¾^0pyÆ²TóQNÈéè’þ<FxSžÒ¿Úv-öÉþ_Ô5ä·µ/µ»Î“,Î)GŒÛwûmoç6È1HãvPÁÂ¨AðÛ­§ú’nzgQi˜K®Óv-Ïi'ìÌ@öínëqÍ"° @éÿÜó‰gÌ‚ó_±5=ÿMË‚óß°£:ÿW‘–F-9Í¬¸€Š¸åü?r.`ïàM–qNúŽížNÇ”4çòÉgÄçÙ|¦L<“O‚óä}57j.Ë§@Ïï¶ÿçÒ\þ%Ñ˜…ô_Ö3ùOAÿ& ý_Eªä¿ŠòW”¿¼ƒ¿oÊÏ’¨ÿ¸lÖŸ¦ô_“UêÿÕTÍÔM¼ÿÓ-¹òÿµ’ô­Qío‰noÁŽú:ÒëŠN?(^&$v•%ùÓÑHb$_
}j 9™ø<˜h.q Ð°,)é%ü›é‘€öŠôÐ@Eá ŠN¤F,½~··'5ÎùÿNl@…¦{"}OƒØwõû?+µ¥ÎŒgab†;¡ï–öêæ'›y]]×ÖõucÝ¼Ù<íîoí¼ÝÙ?Þü:ÓÅ¸ƒ•L‘ªÒ)z9wb8§‚³h&¾ö©T¥U¥ŒÿÃ`~£ˆ{þ˜£ö¥´±ˆÿ3Sù_×MSGÿÿŠU½ÿ®$=˜üÿˆ `_‘'k0>rCšAûkÊõ</)Ù±T`'güË¦l5¥"Ï¨4å"Óø. þI”ì{o¹§nTf`ÀÑ%ôãÌG‰‹‹b#Ç`^Ã,fé¸9	þÏ–ÚuÇæzou2N5m&¶*×­—žÓž¾hJ›Þ'ØƒTj]LBà(`±óP¼
u›ïKêFÆÍÚÓ\ijGFþe±š7rß£©JîxvÙ¥Ö4š´FC§Å‡ÉÿÛ*4À}¯Pø¬fI¥ËSÀ²ÂTE´ŽÞ#¶NÅ7oÅãÕ5Óz‹P¥3;˜Ú£kG´ÒbÐáøöÃ’• €+QèÖ¬ý‚ôã×Ú6aˆu18 £#»œñ¬}°ƒ8ê$¾'§MfSYÛôc2)fJµ_8Éþµv|9&ÝhDÔPUmekopÇÒ_ lÈtÇwg¶k;Ÿ‰Kñoö[‹¢Øâì¡?ôµÆ
‡ã’²ÈÒ"âˆÅ‡g$œÆ=âv5Y®A3gO¼ƒi<žÆ]@8X‰¿¸a…ÐýäëÎdNŠaÌœ„üJgŠx¯.»gÓQ<¤:¹ÉÔü.¢
äù?vAÙwWïëôEH‹ü¿¨–‘ñ:ò¦eTöŸ+IÕûp˜ÃýGz©ˆwˆÜ6?1ö¬ÈëQ6Ž~á~ºF—P­(‹È\Æt’ÞGŒFüXò±‰Wì<ý£œÀ­)µ[ò¥dÊˆº@dÂ³áÕ]}42h¯`]H—áØªK‰Ú†g$M…—M¨ÿ7¡anà†L0àA¾ZtNGž„1°ÓR@PÑž\BÝx-‚ÙDM5´óõÐq 6†|]ÒVŽ§àøÓVt"‘AfYj¢KÙþx"6Y›Ç'$lŒI‘8úôù7X:ø-èìs{8¢
-£qƒ‡]ŠíDýºííõ·ÞõŽÞîþ¼y¼{°R+uFÑP„QtÈÍ	-xp´¹µ·C/Í¹ƒEÃv¸ƒýÌÄ‘õd+F8K­©,·ìñ˜ë2˜üNe2˜0îk
JmooÎ C@™Œ„£t¶×Ó›ÆõüËq”BK=âÑ>
]K]™Îí_Ò™Vî:“xëÇw‡É¸¨üÆx1LVP\êbtfÌObëlèy#raOˆúõÛ	ø;¦¬-ÂûûæûM±£9xŸ ™¥Ø±´hò&œ-%š“MPõœP’5¯ÍäZ—Ú¡ÖcD·®‡¼?,n*P¬!m‡”F0B	²é%83JŒp\yÚp<¼–JIÿZºÁ¿¯®©ïŸòü?'ÀÍI4^bøYÑÿ¯Zºfj&Õÿ5+þ%é—ý7»û;¿ÖŽH4†“°×ê÷ÌqRWiÊìµ_ÞììïínýZëíl½;Ú=þGÿÝ!Ðê^ÿýîfÿí?1ì½;D]ß-M°J—Êäÿ%Šþ4-Øÿ–¡¤ñtË”éþ×åjÿ¯"Uò^þÌ¢ÿVNû“ÒiàÜ8‹i†vDßÄàµ‚ã¡¼DåšwÛé½pTz‰À…4ø…¯P£K|ªñh}±%·Ãi,¿ß¦Î‚ó?ÐýÁ2oð‘éî¼-(ŠIïÓe»ÝX{Ôk›Ì÷›GÝ÷öhJ–ØY®ÞrØSºk§ûx²ññ¢%ýRˆñ«´–”t½“.|Íä¦/Ù»[ðÒÎœ­g^ å!{Ä³÷¶6÷¾Ü¤¥¡Slª rèdã™%”=)-+Í†&„YÉÐÉº\è‘]üÔ¢>&“pxÃ÷DLëxÈNdÍ4›Nâîþün9d,±u°ÿú¦ÂVâÍÍ†,\lï¥Ë›Þ|áQ«€R"€Ÿ¨‡·9 XÁY °¶¨äJ&R4&W@ÜlŸ%ð™ÀÙ‡‰çƒÊæ2Ý¨›Hyo·5¯Ý¨Œ’¾¼ê®ÑŸJáá@	Ö–Jyìp;à-RŠn»'ô6)¹Ô©aî/ô²	ìïíöŽ¿Ô$Ékì¦«?vëMIØ¡ü*«ŸñÛÁgÃzÍRc•p×¯¹^1rÛùki¡“¤°³¯#úµ.Rºðµ	=˜-ýÊ•Â-4[
rs¥pGÍ–‚\(•ž”ªÐëáhn¡tŸ¥ÝëK³M˜•R’›2º"ÙgÛ™;íÅ¢ÃÒ¢¹BÂÔ¥$(µÁ¸»6 1Ÿhž°\vUÚÇ{±ä|AuÅ2'Y0U{[@†öö@àìnI#ØmöHúžÉi¡fw?xRó%l7…“®=Ã´@9'ý>a Fñ$ÍŠXV´hÄ‹xö:£wÁF <]Z&Ã–”p¤Û€û¬ŽÕùzdàN²êävÕ	¾uÕ'd|; B””Jt;ÌŽ¾	œbâ|v×Î‡9äA‚ÛN:UðçtÌÐbš"Å´˜9í®Q£þ‡®©‹¥ÔQ#*TÄ)ÄdaÁ…æ†˜	3”9	{MÏ¾ngÐÉÕôìÌž\&Ýò"Ø§B˜‡¯27^4‰°e1w² :ÌwY8g	–´ÆÆçkÆŸcq09ÿ¯×gmy*ßìUtáþgb£,§œ»Ä6ÝÿBîÌý¯¢W÷?«HÃ ½•À&îÃšw/˜x²„ýS÷â_»÷Uºo*×ÿ¢‚ÑÒ®ìUˆÿ‹†Ÿ¨ÿ¯iÕþ_Iªî‹ú_î‹×À¬ûÕmðMQ º^úmðn¿Æí™$=•bÂ®^/HKüýdzìÖb2$r²Õ1Ÿ9ÿAì^ö³ˆÿ×ôÌÿƒahÔÿƒ¥Tçÿ*ÒSJòÙ‘BÏ<#”ÜA@ÏIÌWYþÞöæ¡„Q1OËòzi¦Î2©³Ä4Ó`™Bäô“¹!ŠQÇÛ¨E
¥×¥ƒ]üg»·³#%öp·ßµ_{–ošÙÿÍþöÎëÍw{Çý•ñÿº‘Ùÿõÿ´ Úÿ«Hÿ/ðÿÜ¤üÿrvý E)áiòGåáŒùïÃNó¡ÒÌùŸ…=\šç¿feñ?ÀûËÔ´êü_Eªü°£í¯=üïáä>@né$Ì;2)z OðÚ*¤3[âêc=…GŸnkïô£l­ÖïG9vÕÀõÇZº‡÷A¿£¹°+~óÖ,ó"^ç<Œ÷¹íîìo÷ú©9d·N7Z@¶>y§Jd¾bª­zÞ#Hþ–4¹+fžA²¢ÿœ¡[¢g¹uÂq±ÊÈ¡¶w£JÂp>©¾<ç"Ì»ˆàÿš2€ãaùò&f,…ÇXtÿ£XEû?K‘+ÿï+IO¥g»Þ†ôlyô‡¥oî:(ívñR(·–{%ôl8ä-z  `«cÅøÉ±b‘ä+–c)“€Ê‚?¶”7§^ %ˆ/sÿEîñq:(æëömøáÝ­y°HžÛ…ŠˆéëðG8Ô<wCJ3kBˆoÀÅÉÀ¹/pl1ˆnÐ¥'r´^Û…ìólõBKîh+b8È$…|HB8ûçBfŸoùk¿*U©JUªR•ªT¥*Ué–þ?ð¯Æ² ˜ 