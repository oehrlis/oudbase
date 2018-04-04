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
‹ 0ËÄZ ì½ÛZY–0X·O±K&ËÈ­`ì¬ÂiWË §©âÔ€:‹¤DZŠPGH`Ê¦¿¹˜—˜»ùæQæQþ'™uÚ§ˆgeu[]F¡kŸÖ^çµöiœ´÷…?+++ß>y¢èß§üïÊÚ:ÿ+µúxíÉ·«ð¿§ßª•UøãÉïÔ“/=0üLóI˜ÁPò4šÛšs~—y˜ÿI>§°ÿé´Ó›LóV~þú˜¿ÿkOŸ¬¬Óþ¯¯®?^ÿvöýñÚÓß©•/0–Òçøþ?ø}Qà4ÌÏƒªy€vœÅa?ÎUçû†z9Íã$Êsµ]DÃt<Š’‰úƒ:šŽÇi6QË/·ŽêðÎQEYç“,ÌóH­ý©¡þ¸údM}?'“ÓlzvÖPG—ñäïQ6“þ½z/E-þl(ïdÀéä<ÍäÇ£I4µgÃX-§Q^W9=k¥ôì_'² ­^:‚·»ýxRý6ü¸Nl¿k+«l­<n­þ~9Œ.â<Nú…Æx0ÍÆiqÛ—°uê¨—Åã‰š¤ê,‚Î#'0ð¤)¿
s•E“i¢zi?Ây¦“(×ýŸÃ.åþ…q2¼RÓ<ê«Aš©(¹ˆ³4¡-ƒ¥?O§uüv«	]ÃO4Älô†ÀÎ'“q¾ÑnŸAËé)Î½Íë‘#¥LÃîwâ^”è)|°Ó|ÜZù—ûÛL€´›öãAõ±øšG‘‚Á"ðj*˜2ìÆMˆ~¦g4ÛQšáòÁŸ£p‚-á½ó09‹ò{`SmñIGñß¹›»BŠ>Ð	Ú³ur¸¿|²µ÷|é£óm£Yl™œáyj¥ÙYíš:ï&}•>sÚTž'êm8œFù'¼ímïï=¯]¬¶ÖZkµ`k¿spÐÝÛz^;>|Ó­©EŸ€¨áé0âŒáp<Ž€F ä—ûGÝçµW£Û ºˆ²S8h€pfŽ6·ŽOö:»ÝçKËˆÇ	Ð
µ´RŽwN¶¶»›Çû‡?>¯µ'£q¾ÚÞn—>z®Ûþë­¥¥ZptÜ9<>yÝíluŸ×è‰vvié£ÓûµZ~e„ÄKeÕ®ëŒÈKjÁng{§³µuØ=:z'î_Ó,„c×êÝÃÃýÃç+Áëý£c˜Ã9 bíE»]´“ép¨>}Šzç©ZÂ6Ø[Wäµ´\äù¼gP¯¦Iqï®xÃ îï`d<êMžEËuõ±Hq·â|<¯¸Á=öŒmP•Pžm¥»ù™ªmï½ÚWÜi£ˆ?5Ï/2ÕŒÕwxð·÷ ö6»/TsK}ü½¿µÿÂ !¸L³þ+8!/ÔÏU(Õ<¯:Ô9°äÀËáËŒ·/ªÞ®8T3^Ïª^ïG½÷D¡³h<Œ{D±f p¦m?[/[7T/y¾gQ¸Àn˜Àl²à*Wî%<QcyDôfÆÛ¥]Á<QÛÂ£«ÞÛIÏˆ„mÀVïì„äšÛÅõ<\½VÍ³‰ZQ??C†Ÿzš›Ã(L:Iÿß¦ÀÔ¨ÝÒÇµkú9óÕí
T±úýEÏqpÜ+÷«<Q»ŒTLÊ&ñˆ¤—ÑøKœnZíåzð‘æ·½wð(âÇÕo6]W!}@¤ßG
Øì
Ar¦N#ø§ÏkÚ’KM ®A€¨† Hr°
U3GBl ÏÏìE¾¨àãíÝî	àÏîÐí>ÈŠªö/ßüØüfÔü¦òÍëov7¾9ªÕŸ=s^=<œýj²àeb@ðöúÝÿkx†ój­æ6xÄ¿{ZýR”‡=‹ù5âyˆ¹×5õ\‰lP<º©–!æµ¥>ç!£6c4ÀÃSSŸ& :6Cçš7½ó4ŒiGIÿ™ŸÇƒ‰ùvyŽçFÝþÆKcí§^·™VááÂÙUÎp>8¯©3Óòlûi•iÒ=nÛ‹Usú­~õ o¾x÷M—yt™ Ê@ªH²©šŽPaŠ>Ä“{–…1º
YIVMHñ*’aÓ|¥nx,RUà¬%ÁÚ%S«Ns ¤Ð¼ST› µè–útâ3ŽÒiBBz˜MQGÎ[êÕ”X’õ^š¡œŠdÔr»X»i°ZFV^¿)ü'á»R‰	€Z È'é„64G6FÊäqçåµ‚®àËags§k¤™“—£ÂÂÁB/ì•^£~òhB€½‡áEQZôæ³ººòf:ö	Â$öÎYÄyyË~0Ã4ì«wK_ïz´[z.¸Çç{”—ï²š>€‰E}÷ýõ…ïw³V‡Ó'éÁ}áløuÚÝlš$(·ˆQ¨—ŽFaâƒ[»¸~îˆäTh!¯/‚<MÞ'ée¢úF,Ÿ\yÿp¦ZVxÞÀ/¿ç9	meÁÝ=47AßÂ¡ÁqÉZx n€hI1Å}K6Œdac9ƒ¤1õU*§Ðœ:ŸŸÜpËà,:Û„”£0¯-µ»µhY™AÚ…×Ûð­íóJ£š7þ…;Çã€G»€]IžÊ©ÖëdÈ…öOªtª¿Ló‰º“$T9hçáp˜zæÏ	æAQÑ	µ‰µõçºÄ¶ü1F£ôU ¦VæU+Ne#¤c¯1MÀF¨tÚ×çÛBíO#´ÃJ³°^NÏ\èh²Ból“ß|ÔÂ®êÆmë`FõÂŽ‘•ÐúbzÜõùf¶m'ñ$‡ŸgCHŒê†ÁYdÒ
ÕÒì*ÐÂŸnÆÂŸ/ø1°Y‘g”0¡UÕª,{
ùÚªÑÈ1PW3vèØŸx÷ìáªOŸà—ß«f¿ð³;@¯×ÕèûÚÁEAªáø‚–r À™ï…Ã¶8¡Y+?/’uh¼wŒ EsG ²0ÚLáOMYs©o÷ØuÄ¼ZÀüÞ
Ó.²$ùg8™ÿ‰r¤úÃp“.UÍ±­x“/˜ž³þª¬º:º}„c‰yÙç?YÔnßÙ[ààü$ÇªæMh}¥†6ˆ «í˜¥ñBÂ †0{Å
VÊHõ¦ •&ä˜0Þ¨š¬Ë®xÊÎ¢I:dõßg):äÖ"MqeÇaH0A;ëkò¶:¿ˆ7¶6~Ùènd(-µxâ*çu1d®8¤ÿ¢^Ð'œßâºÚ½rÑsÿ –æ{oa;¶;Îhñ‹nášg´Íêê°{°³½Ù9&·HqTÝºÕPþ¬'»¦–¹ìŠtHC#üù!¥(Q¶ÂŽ´l,Jó®PqÚàÚ ^(ë“X{ñ‡Õ ±céÏÐÓ9ÉK*BF2F–ŽÃ$ýhÚWéÞÊ=Q¥À64%MWª™ïÂb¹øœsrLÐg0ÿ9DÇŽf6Õ‘e0n§“ãàÜX˜ªÕÿáiÖp®ÊRxs*‡ý\F°)8’"†þÈÑÀÅæ?7šµJ+üµó‚wRô«îC ²ôñà‡-Y¶kË†/Œ¸üÎu™û„ðq%„í"Ï-oäá4ÑBPö‚X]<\ô¾´n6ÙïÞdq}O’´	p4žÐßY:Ž²Iå8rxÄkg'¶µÓáÇîUåÄ¡á$9¸Çê…ÖpÆp`Þ9“=®8l8Gžƒk¬™{èÊË¼ê½¢é4ìÿ‚»=ú9°°ÿ¼0ähôòÒ¢‚²ÔŒÕÃ¼ý·¥v³ýÐ=*òö/)pÏ—aï=¼£¶·Ø×0š'ñ]Ç¤âjï“ÀšÚ$ú0Aef©ýqïYÞ~—´UûÙõœ>€÷À>-ìàoÒrÃ\ù)õVˆÌ9=a}SD}>Š²Ð5kŠ{¸|r=Œ¬§–š‰K:ê{ã¨kúWØkP¼qT[;}R¼R”HÑÓÔ¦gUçsQC´C²ÊÌo¡Ò‹jïÎVç€þsätý•c:Vvécì¨bþz²Î¢åðò½zø²ûýöÞÇÃ£çµwIóèµ¯èÏÚ³íï÷ö^Û{¾úŒõÅçOÐ·ªþKµÿÖé÷3Ø§6²Œ¥5|ôî»‡ØÓÃw/Úê#Lpyé1?îò”ày]à¬<S×è'úHš=ó1CÕÍx½ã¬VœVØÁ'«•6ì›mcy+WiåŠ¦w–;Ì €Š9RÎ\—ÎóÚaÑñûuÿA»è˜Ì‰„.á Ò!d>'Ï1ä³, @]|âí)!UÕû)d—öAÃélínï¹¼q&›û£8¹Ÿ­f®3÷r&õ¦6oë+ÙígìüúZ™9XÚÝ9–cTèä“s¬ð,mÔž	Ò_«¶žv­ÏÉ·ê÷ÿçdM„C<>úœ<Y«<(w;k•Kä£üZ%ÊÃ?Ñp¾P}´;OØ¿¥dýæpçyƒ)7Úm4_o²¢î”ÚUQ#›Žq]RE“)ÀèÂN³iâHr|–Ysžfpò£¼E(¬œ81ÍÚ¯øïhxœŒ§$!‘ùŠB]Ë"åmÐ×ß—Ç2»U
ÒúzyEI!ò[ŒUæs-)Ít÷ç|tü?‘þ#âÿ¯|ûíSÿÿþÆøÿÇ¿ÆÿÿŸ/ÿÿOû_÷oNÄ?GÜ¿D‡@™µWÖžò¯!ÿÿBþÕ=Fð«¯!üÂÿ…âïkµ;Ý;1÷÷r¯~“1÷¿R€}Eh?âÊgÄÜ—‚»^¨æH}ç  <ºyŒ=»j–ïaóðúò˜w€2Š¾`|uùŒ·KÓ3oï†ñP‰Idæë[ê»—Û{[Nh>Òƒ¦m˜Yt™Ÿ-÷ß«Ãõë³ãõ~ØBETwrà†û,èéÝ’ö&Ì‚?PßuÿU±ƒÎñkêÂ`CFV9ä^¤ùÌªìç·’ µ­k&÷t3 êkÀ× õ5àkÀ?oÀ$Ì_8ÎfÂMöóøÑÈoÂú*$9 ›t‚Ká±À&ñÜfˆUõT‘ŠY¿Œ`ÍA¥Q%j‚¶<t\¦'¥;YH’š	¹¬U‹€_8âŽIÂá¢ `69(?t÷Š%ªü8Æ†:Å^‡Vç¶“–ÚKÑÉŽ¢œÊÇQëûšpñ5õaaêÃiØ{?ç¹Ž‡ h	º"yâž¢þ''lêüƒ,B!ÈúpŠk¼þd¨-ï]Ä~™Å“¨Ä¾8cã™y£mX8]Y²Û¥#Ì€%û÷®ºÌaf@‰)Òé°¦RQŽ¿\ÆÃ!Ó±‡µöBÍ§Õ»wê¬]Þçé¥áQ£˜w\@¡'Ð³yC™Ñ
¶´|ÙSÍ¡úÎ<®{ÍŽ‘Q--//É;Múƒ„ñºm‰ÐU“c¤ñk7ùÎúƒjæ0ær°Ö¨Ù‹µ¸@‚ÌÄ%ë_&p_ýOÜ×KKrÆ¯·¯0v¶»÷ðj€TÐ2œ&Y"M,n}v„?w@ ;‰ÞWÿ3Â÷Õ=Æï«{àŸ£}`¨q'“(Sm¢OÉtt
_(¬d(–%6²œGj¨÷yö¡6Õ!b$1I\îÏÛ…O='›ý8G« X•Z­Ãÿê4¬ûûmÄ]
ýlü‘ÿG3‚õGÐÐ1û/-k½T·ý„fÁ¼ý®Ñ~§Úgõ/–50À¶œkzNÎg´ºÜÜÐ#©6&–McÊXe¯%¢Œ‚¯V(‚Û…»D»|¹ˆûQA®ãfKKW¯gr²(X|&…­Œ'ª!d¼€?ŒGhîÐ±Á·­Il˜„§•6âÂ‹ã½ÃÓºÇ›BZ¥\Ã²mèÇÝ¡y…øœ3QÁ°Œ Ëw^>/÷SÑVãdg›üaLY.ÔÃ¿=x¨L®9 "@LêeÆê«µOkBk÷®bê3à¼™e]DßwÌ`·:Çëö#LfµoMIs±±çOÇÏJ“%X%«Ò×Þû}ñikB„–b¢=ßzô®ýnþ[‡£h=Zj¿[m?¬;”Ž]É¬x9·ËT´ëìlk>Í£yX-o0¿)ßÒÐÂ"›e¦6*ø¿ºæÑ’þšD—Ä4â¤°C•Ðm°9=¾&Àï\ˆß#ö?1#@mÎ\	3ã4«éýˆ|#Mð}ShÁyÛ É¡ò³%N'Qr¨”!
(NÁ*•GVEÛ?ÜP??8O§Y/òBDT@7Eµý}<v×‰<š±WïŠø./Óÿ²ê¨8½4™ÄÉÔ`£œ"ÿ~ ¥¥t¿¿I¾SõÙw'j#Žíö°ŽˆL!›xxxŽ¬—çè˜ÊJ3ñtÙ|‚*+lÿ
È¹0TŸ¡	Û¼ŠL6š¬'‚xç|)Ï-Y«³ê_ ÍJFåŸ@õh½MÒU\ó1ð˜h"u\mëºo ¦û›d>¾9˜‰/Cñ£ÔÍp¦cD‡½êÍ•s1QüN=yí‡¹ÂUÁil ûiÏ-@Úm¿…Ýs÷L!%.Ú¶|Ëµ«xºÐ*Í×£÷ E5ÇªÔ¾H”P«-ð^r,Üz,—7‹ýÉèïxeúZ#4üN¶Î†'áªx`úÖ9Ã$(­º[ Ÿ¸””´cø:—Øî>ÎFOTO9á‹q˜ßjÎ\ÝVž4#á e¨˜!£ZF®ÞÔ­?IÂòûì0M'®ØXC–
ˆóð§Ÿ6N‡aò~ãçŸÖK ³|ÙïöÚ…Y÷ÞŒ“ÞpÚ^f°A ï€bí=Q7€¸ÆÚÙÃö»Zã]­]Ñ~xf[´á[Ý÷sÎ^ûœ"ÈFhÉƒg{Ëíú¦`‹hXÄ—îàGosw·ƒf±mï]·TsØ‡sÕlšè4É8¸Q–Ì²N«¦‹yîBc;ˆ *ª{<N,¬“­ðJþË7Ó‡õBºé‚‚’à-Qa'ƒš‘ª½KÊ-Õ‹Šsé|JoT¼àgá§2©eþ$0ÇÁŒ
¤(ƒÑ™;~Ó~Ûä$†Î9Jþ)$¡Òš*DT§#9WÈ^Ý›q±+’šT6¡¤xx¾7—³Õqèw'
eèAÉ}P‚r+/îâM#Ï®Õ§Ä4WÂ9N_÷Sµ™Ž?@¤ú®QÅgVªt¸ŸBxÂI?•Q$³åæXO{h2€4qcJâü<êÏŒB©Ž9¹µd×O/“ˆäú<×éÔøÌŒ£zS™–39V¤Xa³&{þ=f.éüVcþ!ù?kW¾5ù?kñþ—õµõ¯ù?¿Êçkþ¸”ÿcNÄ?GþØ!¾æÿ|Íÿ¹¬¯ù?_<ÿÍ‘0þ7;;‹‡ÏSÐ›ò’Ïö1Ú:ÿÚí<_¿ ²Çž_˜ÅQô>Gbñ>ŠÆœÒ1Ê»ÏkÍ¦þ{ÞÈØ~eÛªWÃðìkjÒýtó+¥&MÔwˆ†ÿ’”LVêììÌÊ×1Ó6çH)<’hwÝÞÛ<ìîv÷Ž;;*þ8ì{õÝÝî_,\{Ö.Ý³¦ÒaßDAÐë³à~f†Õ@}÷²³ù×77ÊN*Kg'1ˆ¯ÙI¿éûIî–ô5ékÒo+æk¾æ üšƒô5ékÒ×¤¯9H_s¾æ }ÍAúšƒô5ékÒ×¤ßfÒdãýF¼1Últ¿DÒ¤®ØuP™£ó¾®È%Pýë¯‘¿DGlOý•2ŽB"A<
‡|•3‰Ã¸ÈóVUtÖ‚ÿ¢ýU_¿]î¬¡E[ýš©ó5Sçk¦ÎßL';ã&™:ï-oQn‰„¸07’ÇMTÞÀUÂ!úT¯÷÷ÕôŠø#Î†9:Ç¦ÃT=Ñî$Åü3Øëþp‚~§½}Çþdøý-ûÃòÒGÛðº)T˜ >çÎQ;=Ná%å½¥¾Aã½ˆ}€}ØÅ¼—í*^ö7i«4gÜ&š¨?ˆ0—¶ãëÅÀ0&Øö4;“ìŽ ûSúÇçl
­;&Ç_!ekV:ÓÝR¶d%þ[$m•¨ë×d¤YÉHÖuLÉHV64ÉH¶…¾°ËÅ”Û¥"¹°n’Šä´¿y*’ó’cè.¥"-Ku*Rô…©H‚Ä:RÊ´­Ì>rz¸}öQYî´gÏP£ëã%Qß¡ÀV·˜¹þí]¿ÓŽ”ÁØ1/JÍqH=,øí‡#šuå´°)ssd¼UI9†<¢:ÞJ²e´ôpGàKq“Q/}ôÇâzsÜÌ—b«rBšŸÇRzcaæ‹Ÿõâ žì 	ÚL“A|VAnK¯ð¦&h¢v# 1Tóàï½‹ÁM¸íæ#q­ÉÙß™Bnîï½š±˜N—•9DÅ¥tÛÏn^½dú.V—³îbªZ³â«÷¿hxK8/™c„‰©&ñíAý³‚ó­@ªpûì\«…yVÎŽI–•À-dYÝ<Ãj¶ô²’ÚÝ*‘êó“¨n@õk$OÝ,qJÖïÎ‰S7OššåE¯X„ÊM•UØËÎt’bÌ{/„f¤,	ö=Ì1h1B6—¬kÒX±“Õl¨ VÝaså>û¡+UÜ¨/­0{Ú^yÏ³‘jfÕäª Ñ{õ–¹l{©;…A:”]F#eyÜåA1üÑî±ÙÆ¶Û$²Éèî?‘måWJdûú¹ÓÇ»Šûõ1?ÿïÛ•§Oèþ¯§««ëëOŸ®ª•ÕÇëë+_óÿ~Ï×ü?p1ÿOÄo:÷mzT+#úµ=§`ãûšøÛÊÔ¹{veß†YŒ1W·O™BHG\ŠŒrœyUÜºÓA¹Të§VJÿÛâmo¾r¯¾ûÚQ‡B«ß2èï§†ö…£×'Gûo7»?­ü|]«×Ô35¾ìƒ*
Âé=ÍÓát±}äBFv7R\5öiû‡øçä s|Ü=Ü{þðo?…Í¿wšÿk¥ù§“æÏ6–‚¿àßúÇõëýå7[ŸðšÕOÛ[Ÿ¶ŽºÝúÒÃ€á²ÙÝÓ×ã~÷|‡¾ñTŠ0<Q«¾”¶Ç7©5~Nw˜Àrâ³ÇöÙ‘y¸Î;xA±yø„:7g›Ÿžn8Q€¤i£T
­jÿƒ³Q¼*G»·Ç“@O·®}\Åå6%”¬kà®æÁV÷UçÍ^,ÌBœ¯YRó~§Š4n+ºž¹V€A¶Óˆ¥]¿•çü•vŽÞiz´{²µ*ž×o?Eâé7Mr³³ã¶¦=ôÎhó@Ê ‹spZ¡œ[E“ÞÌV¨Äê>Ïf¶:îîìtŽ»GÒvÆˆcß88Üßz³yìÎbœ¥ýioâ@eÿ9£I“ÁèrH@kµô½ÔðÕîs³Ýì°KÆ³íïiçœô€>·ÐÀ†jl"Žî¹±fµøæÐâæìÅuáç™?TìÏõµ‡ÐÎä´Ðßšúù#t¾m4žìc€î`è×äOö 8ï:Ëš×½&ÝÐß·íGªój!q·P{`á¾cµ•îuSg’s:ÓÈ/Ý±DNdÞŒ(ª§3âcº3½Zƒ]ËäšìO­…Í¾{œKŠ±´Ö'¡»è±òÜ¯”–¼víÂÅyë%ŒV:à,) öñ»qŒ¿ºZÀ‡x>÷%áÉn°GoŸûF´ÅÀËÔÚïÓhï?›¾‚ÂvCŸýsŒð®ÚKí¡ÇoóV‰ÔzÃ*ÐXw¾>Uµê'ŸÛ©G¯ŽÿÒyÛÑ]š¿oÙÙ/áEèPB”€~ÑxNÁz…ßŠÑ4žj88mƒúl‰<øMÖ/0ÉmvÀ,‹êä™PmJ)ÊÇiÒÇèWtíqü—+—Þ§*¤”G
0Á™¢gOgÛki×ˆ{ú»ÉM@¨L&Ï—;‘370af‘i‡~!$°06Ík³ËOþá¢ƒÕ®‘f>p1öàÆý"ƒœ?À‚‘œ#[ho$®E^8vPˆJÀRC­Qq€—q±¥†²D  ÞÄ“á‘+[¾ý<‹&Ó,Q«E+:+Yö•dyqØ#)h^t…­ƒ	ZÚIš‰zØ&åŒ/²^q6iš$DÊÚöß–Úã‡j‰W×ÔKíçÍÞà¬‰—QBu6%vƒ›ƒµº×k©?é ûzMŽÃûêéäèh§ØÛÑìî°{`Â‹ÍË™ÕX¥©tR„äl 0ª_XÃ*™yÙRB6 ÿF
ƒÀËÝïö0•uø8ÁKN{i	mVÿñOÕmx?ê?±íÓÇOg´¥ú¨ÿ„¶üÃõÉVÅ›™­þy¤»¢:jÍ·\(E¥A|×hÕ[Æ®!7¸ÖìÌ¶GNci‹XÙÞšBüö´…•oí$úXöªö÷µŠÆ™7Ÿ]íVå|Y¬¯Õ*Q¼öíÊÊjåO„ÙøóZõÏˆÌµÚæ‹æ§_q¾Ïù´ÎžÐ[¯”;_ÙæÖûE±ÛÒ›ÐÛÎÛÌÛÊû[­{/gadðéÃõO8·¥,‡óÏ$á`:Î?— mõ‹ÜŠãmPß¶Ï°Ý¼"ˆé„È]µä[èÝW?)$.{Å‘Ô){sµ’+.O%®Cv¨8C@ðÀ’«ZYv~÷®ðhƒzÃšçHl„ßXò³æÎýÎÒ·L/ì÷Ks›¤³æfRïc/^TÍ£*ÈÅÓä(-›wë|E	Rûèe4eèÙŒFãÉUKmêÔ­$º¤Ê­"Ñ€´ï«Fvßú…“hÚ— iJ$Ù%zö–cèKí47)ðéIœœÝ«kUU¦YÔ5a;Ñõvþüg¯’Ïlã€¤yJZ6çÝÏTÿU1]Ãé<}áç&Ý¡®EîºYç}ØìjsÂ]æLî­fýa4¼Y×LJnÍªr:â·l"@L.š	|š…½atBæáw"àù]6-›NÈ9¶Èmºº?¡g†x¨fJˆÅ^ãp——ìÒ×Koò*ïý}ž,½­œ­µ{FGLt¤=wy}Ãc])h—]usYWÝNÜU·•xŒÐ{åéËÌô.j«€ßL“<FJ¹#Á@¢v[® aF‡!Dù¨4¼×ÇÇÊÿÌš	6=ªljg¢å{9V_H‰@Ž;—¹­Ëh…#§|—Û¾›ú|Ïü–—
·›3ÏðœÓÚJÕö"˜i‚'»V\lodªY~VúZõ‘­tÒû«Stñó@Kéyâ$Ë#í­6ùä£¯‚\{:ˆ¶e.}Œ¯Õ'¬i¢š«Na’õ’i÷~àVrïöãºË_=%ñžzx:»‡Ûùô4”Êœ[èÜös{Âåb1û>kÞåëöR<G«Pò¶Ä%=?ã,N&õð›æ“\}Ó\]Ãÿ>¥?×ñ¿9ÖD¨R¹ãkË'Õ;o8µ¥å_Ò899½RmÅ†ækeÓæo:×uÒ9}¦ÎCµåTéL1èlçlg¦èæL·ui¡Ž÷Lµ`‚‚ÓûŠT©,nS ˆd”º ÅF.‹õcÌ(ìhœfg­¯FÈ[y”]DY‹Â£L@ß?|åì {ÜÃÃéøá3ÂRùŽy!ðdû5•I¨¨ÏX’7óa8îßs×tt}9ÌïÖêöœ0Z'íÐ«ˆHî¡¦+üßÐÙîÈ»ÿÜ.÷;	àúýUŸ.Wx·­Þí*DÕTš”)wa¿»)8‡pÏÈ=bÖ 
œC*Y€U<BR»|ÑØå!Î1e¿º²gó9ÚWå¬¼ð&í¿X¸ ®5{Ž·pfÒûsæž¬YÎKsðüµ»ÿµ¨øV+½N—_Î+q%'¦(m½J¢Œ¦¦ß zcÙ‰’³É9£Õžço6È§YÔÀÔÂµØCzAWxÉÏ·t®ê:&mÀâÂƒ\W€cø\nÝìŠôº®#91¶j¾´þ\õo’M#OÈ%¸Ÿ2¦Y˜ôÅ>)ºó¶§jæÿ
›_iþ©1Ê‹…Øñ|R,'jÕ—IqÐr¬09ÍÿðÀ±œëÑO úçGþ#èªøˆ”úyNÝúÜGñS Yï‹ØG’ÝThÏ£a…Jë©‰Ž¥uk*ÝßŒ*Z(‚v'hµ@KÁlwïíÝÓ}|°Jm¾9:ÞßÅM*–@Ÿç€-þó&ˆ+×ö%Ÿ'Û—üç…—tY>Mð%ýüó›S°xEs|^hî©INsïù=¼cZÃ2Ïíu±Ùâ4ôóBs7kÀmî</¾¡+æ:ÐÏ«;Ð±»ÅôóæCxíaù=oæÏ}îT10ÏöãL?/¿â+Ìöÿùœ®
ïÌÛÌ’ÀUõ^ÅÔPíU…ÏsQ‡+šÊÙ¥¦ü¼ê…ÃîAl|^Õ´ñÊæðÜkîçÖÆa~7²cG!ÿ8/²¯¬Gõ¸sÈù\bt”í°ß¸Ö=ãÞ-9øÝ–t(›‘Ë¾™Ý÷3Eµì
-uDêßWö=]o`ý)08mÀœ[ÞÎ « ö÷,|žNÝ·éÒ.ÏöJJ°8™±Ð’ä‚\m¤¦$æˆòÑ÷O8³DÄ¹"7.„µ$öý¹á°j˜þkP±¶Ò^çY­ÈK•m)¥‹2u8©Ë–-öòõ–Ÿ‡¼‘å7RÇš\_šä¸øÛ6£,U#¥²`3b§ŽÅ@72J.ˆiôˆZÔ–$­¢¶³³Ý1%•©=•y…QH¥×|¹õ¨þ|ùaþïS­ÞzDµ^••mé,ËÆÒ§e†R0õ¥ö»µöÃ
(å¯&Ù2¬½Tl‹°ýß€.ÖÄZÁXˆŸ¥4©¢?5þÚó© ÉÊï\,ðÌ‡_NçÑæÎ’ÈùøA…Y¨©ÔÚ}
9nû–â^­=ãK•žiaüQíÙ—šsÔ½Ç3MRÐ œÄ6Y„ÂUVšá¯µ{^¤"Æ\©m?Ça£q¯¹&%LøvßZ:)&ïdBz!L\Sö3£Ì|õòœSØîÍÆSxé~F´™ŽFir ´ëù’?á¤4%é%µ;Œrž×jîs‡@þT5¯K¼Ì±jî?ÿ\ð­%)hñ“ÞyC¢0ÉYïÇˆ)Œ®G@±´¾©Õ*·90ÎR¼ù‰Ç«‡¨å,êO{ÞË‰³«àÔ	pFïÔSz@¬zC±‚F†w· 7D§Á@ß²ÔæÚlhõÐï3ýoþ]-ñšVëØz½½H³¢ÁË6j°’ùGÊ/ÙŽIÑ†´kå<àˆg 7ävÀýÎRXåeØ³~“s»~z 2ŠvéN²<FW
,à—~‹„O(¨ZÌÚf[ò°ÄdŠL“¦Ó„Z¼J³Ë0ëË®ÍÇ=3Ü;C>‰±bìpHððÆUxù\ŒlQâlñ3§ßòÒVÂmì=Ü ¬O²PåC¬ÚBµÏÃa¹ŸÕëŠxƒ÷yÎ=Þƒ3™\Ë·ããã±”§˜¹Äõs¾ð5@ÔÀkÔsknô!êMimIî6oR¼¾hYþü}£ÇoùöÞ9©X¸ý`Æût9ú‚·óxc2ËàÞÍ¸ŽÇg8Pñ
!k0b.åeÌPÍ•<ÒãgX=³|§‘±ïÙ	mÃá•IËçŽñ
d¬ã3ˆ³|â WŠ4â2ÎQèAðñD›Š»ÐVbÅôòÎÛî9¼Æ¼,øçÚ©ðÏp¼Ve/ŠÎa~c‹^Q¬S„ÈM
… ®`5ÐŒŠ1_=AIíMÜ¢ê¹FJ|¯UÍP›¬nV“A—¹vAh!ÿ¶eÌ2V¥ªÀ-‡² „Š¹­BŠ^ä?7Ý¿edk)\ûe%ÝG~œ‡c½v¬…6LÉ)Ÿ_Û‹pÄð¢Sœ TŽ1Áêb­°ÅW ×˜Yà…tfð ‡µNôz¦Êª™®Š†›Áé
è…‹kp¨ešÙ«aƒ_•æ&{Õ–ð3}„ÌréK[†yÊ×òåé`‚Êü{‰äuK–h0Þ
}ÞÜ‡ÀVó*6T~‘‘¸<p}ú9ŠÊ]±<¿T,x2û.¡…7O£×’--å°¿3ˆˆº2°DØ™bOñ„s4èwé U&q$¸/ë-Èü©Ï¸p~Ö=táMá²$Ñ	ÜûiòOE¢íÅ>¿YV’sK’s]â/×róœ–Y7%Ýâº#çf™REfñ~¥Š$†Y­Ë-=uScÐR\év7×£CnÜ!£äÇ  ’ÇÔ–JCi;30ùñP ?b»(õQð7ß´÷Ñ®+”+Z< œ"A<<WÞÏ~†!,Ù{)(¡2ÃÝïq.¢ª«(áxkŸÇÑÇòŠ6¶¸€1æJ)ª$gûÎøRÈ9ùgÞþ{ÜaZÜ{ßc¦ä]þÏ©!ZÞ©bìkñ¬~¥½òGrÏ{Ó(À»õY„…¼çòò=½äÁ3Š‘Ô ÍË—7kÒkL|œÃÜúe"”9±„U7šæ~8@ODNèW†çŽ	…VW÷uŠîWÜÕè^W¤¡ËMG{§ƒ¬¼rŽRò@ìäáx°œl^ºgjºG;”  •ƒª%¶nÞXfn"5K±Z5ÿŠÑÌ™Ÿ
`±¡æÎ•û‚}4Ì*¡Ò‹G½vKÃþ}·÷xÝ­rï&Ö—síg1K}n6ÄíòÔùd xç:€«®úÜÃ×ÎœÞ!5Ã‰NÒ¨Èv£Üku×îå»ü’ä·,h¼fKÒÊ‚;/èÜœ¯¬;¯pÉ¡/<1™Ã~¶Ë‚×žV¿vëgß‘êxÉIvçg]«w‹ðëRÌÍêÕ
ü¼_$ËNx5´­Ž$.¶Ç*«¥þ}@Ž#e~Ï÷Ò«×ã Ös—¤ÇY]ÊªL¸uíÊŸµeÚ«PÁ¯L`vÕºVÁÒUì$°YÖwLƒ>+DíøYÐ~k†GÅ„—–µ/Õ>Åì\¹½µºiCñ;Ò£Ò3š~é)P÷™??Íeï…?œMŠ¶imÔÇPòWtÉÌ‹x<46¹òÓß·t‰s0ü þ Fa2Ñœ>ûŒUcXk¹ªÒÛVäñ³fafU™Ø
ôû\ôUc–Øßv•U"¼•Øôë`þ
0èÊÊEK‘[„s7œ\À/pÃ†+âßE>†—¬	r•—µ³ 8ŠFG¼¹ä;K0
U’ëÊP{Eö®:©-Réíšyq—g`›äþÉ(ñ¦,Œ==àºÂ}ËuØíù>>|Ó­‘»¡)öÃð©¦½sDJW ú(n-§ð³î€UêÄ;¡Æ»0TÑ£{ƒ—Ú<»½‹åêïô"VÃ/½h|87^Ô²Ù¼U@®xã5f¼·è)üðu‡‹‡éõ£âüüs ãUz‘$|.t[)¤º¼ÈVæ&UHÔWæ»ï‹*’ãÌn´àFmÖÁmŽ’ã{‘7ÐÜº°Q±Ýt]î†?Ÿ7Ú Å÷ë£¿Ì~¿cÕc¹±–Ë»Ü÷XEÙºñx5nð•Ž¿”RP9‹(|Á*­0Éxâ†µ/jp Í½¡ÁmÇ$;”¢sûsS€µhLÅæ6<ƒÅðÞ.e>™ÖMÞçÙ«)÷}U_ò„âPÈáò3]Á–´Ün†ŸÒ†4ÉPg¾_ &¡ƒæ£o¥k³¾c¸ŠëxÌ!iM>LªÏÇ[|1ú­Á•ì–(;gÝ˜¦;gõg§>Tn‚#¯ãÃfcx<`7ñl¸Ïl^>ï­ïÜe{qãqÌ®æ¦ò%gÑ—>bäá5RWQmÐ•örBk¹T¯x‰^™
Ï¼þ—€Ùì›ßø5§ý´×¾¨þgþýŸ|_¦ÜÿùdýéŠZY]}òäéïÔ“/=0üü¿ÿ÷g{³»wÔýb}Àz<]_Ÿ±ÿ«+ëOVöíÉÓo¿Þÿúk|TÅçû½7êûî^÷°³£Þ¼ôP‚"AUsø¼•\ÀÇµö'õ—i©5Øì  ù`|•Ågçµ¼Y§‡êUEê(L.1‘L•äÛk MíµÔwRýoZivÖ~¨îE”]¡C4ÎñfêQ<™`¶æ0Œ¯HÜéãµñ)f@ÛS€‡òÝË8ÞòÍ£
P~Š„½¡ =§.b$@lrPÂá0½Ä›1gM—>YŽ@dÁVÇ ÐÐªQÂêPLO¡7}×)×[À´4âaD‘‡üp— ×‹S¡Èdõ>Nú”¡	2Òû¼¥;‘·r¹¯ïy/¿;ÆâÍ/SÔg?Êã3ŒÇÆÙ°°Fx^ñ=)80,Z2å¹†Ä$©ñ”zy…öB¼›wÒ&g'“(éó>MÃ,„ïQ±Ç Ô#frHj)Í?Äª]gY8j6'©­	¢èFWºr‘ÀÙ5Ä•A hÂ›æ 	†þÕ‰æ Þ”Cdƒ9s2Kžb(lfVþŽ%‡hb§øR˜W˜\Énàòa~WD’-a".ýé0¤Û…qŒ?¦SL"HøB¡Õ’ùç0…4%LøR/#ßãppÌxøÎ/ÃËy)[Ã9xÍñ²÷I0Îb¬}£ö|õl}¬QÞÒS®-  N\W…œ“È°4>µ,Û1ú„
Š R]Æùy½aºÀàë3EÌì¥ýˆRBª´E‡–^.CLcž8¯bM÷ð:î6Œ­Ç£C 	3§]oÎÖpï1ÛHÃíS.0áÖ°æó™â«Ì£}#²—Ón$¯á8‹.(1Cìð Ý_áá$&¿ˆãó÷òN²n÷©ÎnÕ"º ;âÆcCÜ” e“ò
±ÂXŸÆÃxóÀØ¨r—ÜUjP|é 1¾%7Êð`Xø'í"š#­Ì+¼øC8î¼äÓÞ¹=ñ°tçœËu†W*ÑŠÐéVƒH&;Â1¨J¢Ê(wMÊÄ 0™ä<#¼FWÆ•—«/' PCæéÐ5tëÀA=^-ƒ• §èb•Ÿºf¢ ßÊUNC¼
™à¯X£	­“\Ž¨A¢Ä„ö`§
½8Kqr™â5äã|#X^­+¼==›¯aÞ‹‹ãm.böòZÖHã&9üÁY|¡ñnq ®›¶ÛpwÀµ‰:
¢˜]ç,=«‡lš`’÷PO‡è/M¦Ø:™ýÃz\HÜ½YÄìˆg†¼äŠPFíQ—w|
èÇäŸ:L§9ì±í.‹þsg‘¬÷Hn·è4¤ÈÞSàU U¼‹<¬˜è3ˆ#Ü
`;’žNdmúä£J¢tšÃ´3ðHÝ‘ÄðƒéÖíˆ®”„_zT©ÏK…=*f	¥tžlšåi7¾÷	·à…C¼Øýìœš Ûw â‚,J—§De§Ãb#ÏDñ	“­ &wÂáDÛ£" 	c¤ Þ_À$Ù	‡OTPf¦e*¿T¦|®  Ã¹I,i8Å#‘özÓŒüsÔÈa¼˜t)1‹F =
÷§ÀŽqÍá-$&q2¬ÇH!ò†ÉxE’±öi‚«:ž -Ê'­—³;»¸ º†,0¢‘ùôH¤ºX‹_S8^z¨-ª<A33Hf˜”–OOÑ¼€‘o´Ê"KÈ%Ó4ü½Oõ,­0Ç4JdT Lîº'’˜’ÐË²€Lqwrvì/D^¥¹“›ag¡ŠNxœàø*B]“m\ÌÉ9yÛp@f¤©Iæ1(8ÆŸ‘îa÷ˆ
¡hK"Éßºp8M½‰&%d–ÁÙ6¬ìÇÅìPœiŽ¹ÀN>Îr÷	iÒ\(|?%öŒBÍ‹4æ,f6ÝG$Í¸±‹z´B,Õ›‰S‚b@\ÍÈ@[{XNaHK2WªæUK$–p¿,9Â=ÕÔ(ÐýÁ)¢2Í¹[G
Ð]c^5ŽÅh
‚äÂw$Â¹s²ð€²)Ç(w8t\ª¹ý0—ãnÌÖ…Ž»‡»Gª³·…WGnmoïïaã•ÖŠî‘Þ¯;<¦Æâ)í¯>EÍ9š)…3 £UÖXàæê†ß5‡ñ{Œ ¾ºÎ"5täëVi6!-€‚Ñ(ÆEš¢3 (aþÞŒ;uÚ6Êø¦O²^“¬/:`§ìRœzôJuCèLš°fØïÃ–çÛ[–[ƒV5y!Êk´%5+ÔÔ`dWˆ.ƒñ‚®&&kÒ³d Âc“2¢9sè*TýpLÇ¿P5Ù|'Àz(jæç\C&’t+]Xá !+Lu™ ‹z\€Øc©D(}FùìØ€ç\ìVBî0±šŒ)@ù ÖzIƒôWM{jÔ±ÛŠ££j½`A|V“¥ˆb0œ®Äô)›í€'èÈQò³Yd<ÝáE<×¹OhBZóGâ
á„ËK¤S8æÎê]$Â22:¦ uay„¨	Ü¾ÙW‚ºSœp7¨P Ñ§µ°{‡Èôäm:šmxæM$•âðWÄã.ÔA{v óDD Î?œ34t$ðèÈ2MÀÉ4•KT@ÁÄ0©å"¼c:í, âQ¦&	  6Æ.ä§¬~À‘¹Œ†C³°FQÝñœâ™)ÁLhC”°ÓŒ@ˆü¢ÖÐ. D%(k)°
»$3$°\!×ÕáRQÄ‘ñ¡,„†ñ Cà`úBL>Iò<E˜6åOpü˜žK8›Ø~."î€€„éº˜@4:cæ/¸U;$¯ï¥(räµ@t"’óXÝ•Í¹Ç$Ö aR=±k”!ÐÀ5 Vn”"Ô/LÏl®0}[tK¨£gØ$VÇd•æõBI—a7ÜIÈ±ˆÈ$ñ€Ø¢MšÀæD,yU	Áµ„Y³)©lÀŽ0ÚŒ7Æ-ß­÷aŒH00ùn4I,s§Y¶¼&àÄN¬ìòŠÃÆ „IAE)±H3ø5„«-%ŽªMT=5Ï¯9úhMTe—±X€F!¬Ò†ã\:Oö->–îaec‚Liÿô—ˆ(8‚·ge)Ö¡†á=BQ5Ìúj[/š}ÝYH>LcúÔÓå0v‚ÎZQ2¤Ú=gÀó0‹I€Ê–ö¯ÐzÑÐKIéïÀíMG¹“OÃ‹DÇ¾7†ÆÚ6Âe‚ô7ÏÐ’ðð´Þ¢¯XG)°z;N›(«ÂîÑ©7€P§YˆD­ÆÜQ¨²#äŒö!¼50¼•Z!*“u•äå°ÎÖWz»¯!º ût®÷><c"¿þ‹°	ä*MŒYÜ(KH•¬H PóÀiNgü´®¨ö>bXÖbÂ*"º°(‰°”¥~ñèª¡™ˆ%|UFÚ0H¦­ð¤¼ÄP3æ%Ö„ˆë€› VEMÐ\
~˜èÚU!lŠ²)fDáé¥`ù=h©ÑI|ÒÇ¢D´Ç¼4 žÇ3*8c^O!º„Ä„¹q€À^×‘#ó™pûXú}Þ`¹»‡Q¦ÕQ+­ÑžÛÁ)²Ç–O‰}aj›aè¦w3œÄ>LB*Y¤á0(Æ…R—Önh‹… Ï€ÇiçJdºNChngd“Mµ©ÉN•žÖhå˜Ç€üéPT>+7ÀÖ¿N/Qkm˜jˆèúÌi°ó x\iQ‹Jæ$MY—àXD$÷„6*kÜÍD›s„NXUÀ	\L2Ù†Œ§2°/ûÇ’GÛ*XZ«ö10¬ß$ŒžÆ¥;QM{ÈÑû|\e7ùG±ØË²KAÓâábORØ˜,{é®’pÄez¬¼t{zj–ÆTy×Ú€>,´ ®LÌv@³Sô¦À¡QE”pB‡c4M´Kê.£Â m§ ’a^%›cÜ18^´PŠ¾šåÕ¤j]ÙÄïâûµ)7ËÉ –E¶Â¼[¸H´±rß^ww7,þQ-Ò=¶Ï FË¸ÙZ%e:0
	«‘ÐÅØ|F^¼~… EH©ÖBÚÛ”ÑÚÀOö`”a)+-Z–c¼BëP?plTÃ&šh“¤îß¹À!©d&Ÿ&Ãx#ß†­iKYëå”ßyW qBÌ2puHRXåûé•¿Äåú†ÔPg Ä#¥Í‰.Ë#ãX<™ND·À‹ó†¤— ŸE<³@»‰ œÇìÓBI“ÏÇE8dþœÛ%=½òuBÚ`ò€˜<"Ó8.Œh¬ÔzÃr<( Ú¢/‘…k£Ïºf&`}C”BÙíóv‹o‘Ym€4ä“Ô£¡½Ðyj|g‚ct{ Ða4ež‡|è€h“
çË² Q§9åŒ‹(º¬»‘æeÔ>®ÛÕK–Åpä`ªö9OF»2@ô	È‹JÕdÒŠ™]ne1ËgÂ!x…Q
‰t™#Ü`#æ476w…Mdªìš"“¾·p$hƒN£óp8hÈù¦Glƒ€µÄ†ˆCiÐA¦¹±iÔ1xøÈhŸmdìßc¶™FÔ·ÌÑ.	ô‰Q!ZØ¯óxÌ,Þ$\Ý4ë&ÆãgïÅYo:Ò…¶½HÄ”Øñ€Çâ(˜9Z9•:"qv‰„x/äÚ`ˆ¬®‘7GÙ–\×¤>n!Ñ~7ì÷`¥üì+\žp«æ&íÀuGŽã^êm²R@*y²nß°}”˜´‰6£wž¤Ãô™	è–!¹1í9F!8öj07§
)LøLN‡´Ge„°ÕUÍ‚~Ø>ØwÇû ³j-Gë®­¨-X*ã¸ú§?=Å3ä@xQ¥"C¬FªbÒ'K¢·âëÑsÈmÄ0¢
>­d_ðeS½©+í³„M#ÿ4RìÆ[3¥ûS¾É„$ïUÔyá™ ‚ØšõbB!Éì‘ØxÊÓ xD™Šc¼7DÎ„‚h&Â²ˆ‘iÅ¤ßTïªY¤²LŽe5¤®¤DIGáÛqI6iðqgŸjÆX§ö¡,¦ÌÌ¬fiÓ‚êÕ¤Ý[o9çö­ŽÏÚdƒšËdw!\zbÂŸæžHÃÌ%Ðf:A‹5,–x:ª&ÓI>…Ÿ²ä¶f,t× ÈÏ³#´×KœÙ\c×³€RaÇÐÊ²+˜|¸HbŒ èM(þ$WZP´xra|6}ÑßÃ•(fQ\HÐ·Ö©Á¨ÔŸ3 Y¿ð4×^Ä´ãÊØÜžÑ0Îèð€úæ„OTÛÀ Uª­ÙEk¸ÙHŽîÁn(ÖHQ¥iù™‘]VwSPôA@8ŸOÇpÌQ
mð€	¡!<q‘mWËv"¿uí¬s-ý%AU¤¢aÌèÜ±HŠÞKb{ÑF1k5‰ˆ#"è­]¯ÂXqsEâ¦¡Í]F¶Áº°NÂ+[ýÙ÷`Á®#c%Rš(X*® !v		)€íC¬°¤‘xOïÔyÛ%V‚âªÔ	>.§æóÀme­Ì·ZT­lG26zº? B¤7!ÔfœšL´W·1BZ†%Ä/3š°c‰s<ø¾žûÑ–íPVd5ÎEšçQ®#	Bë#+  “‰J`ÐpÏcÕjÁ¸Ñç¥òLH×ÐÔƒFí²QÌ$Š’´Ñ†lÙY˜õ‡w‚²61q]Q6)R@•§¸ aA9ŠÞ÷u0w-µ¶êN†Wâ³·FÎT® Ï±¨—Q¤Fa¥$¢ç:ØK›¹”ê×õ¥Ô1VZšíj•"z5r®##(3/ÏpmÄ¾ä1¯bO2!c™–°®Ð%W®Ìì…y6 Y)>$‹søÛáÙ`hd_†büá•×+'^8..ŒvNÑ{|3©¾(µ'ì&"ÁÉ‹;ò¢ï>Ø)Yõµ‡T›uXÜ¡gù‰±Î7PaDe]ÓépÊ7û„TôóÜ‘Zp\ÌIPÏÎ¡Ñoë‘Ú%âR¥¹ã¥¶,_Fh*‹fÄd9*à	Ni	þC	ON# 	¸$¡®ó£ýú¢ô²"ƒ®§„T¶ªí#/=üOÏÈÚ4{!‡:Gé+=Xß§•4 Â§.OÝaEØé+Øœ¼Ô7”TŒdbX˜eÆÅ2“:½LÀ&BÍ«´ˆ:+Š4ŒOId+‡¥nšþ
Æt@ínC²9ôÎ¯r’%Ì‹€,[û´Ó¢Gë’÷Fã0‰µ]‰©Dµ©/þÀÒJ¨úÓŒíg:dFÙƒ=@8K6Z«Ây–µÿCç2QËPOX
l(¢ú,íM°4$i1u…›n&Ì9û“&ÇÌ­2±æ•q„L6,±QÃLÄ	tï C”LÍÅ…u‹¤á®”x2) —7ÁÓóì¶ÌáÝÍ1 #9j¦ñ±Q<Zð›ãCC{HIr.>J9@¬Fpôò4‘€v€ë>Q—r}"ÏXë—‹	«0$Ù†µŠz0ûQäu„{ 	;’TT+Á	>;ÔÕ×.Ý­“ˆgÃÊø(’bµª +Ã…Ceåû•â\•ØPœözaN’«£èRG8ÂuT„¢íÊn{õð™‡šÃcôHž	·8ÕâÓS+Í8ø§¢Ñqæ=’ågÏÙé	K‡èTZ.Æìó~ÔY´ä´Vjg×çn¸hTì¹q™	]¦‡Ü9a AL3¶260£2r’(^ÊÀMð® ;ËÔ2—ÉñHDÃÐ }Rš—p·1•øàqäï×«Ú/³eˆéÑ;\vkÍ¹âJgD<„ØåîH —cùvø/+ä¨"Å¬uQ ¾µcÜð‡‰(œYæ!AåPkª+Ë.Ã™«ÛÂKq\5ƒ$#™ä9˜|îë98ZmÜd!h£	c²Z¨ã¨%¶aX†õ[çˆÉìmÎ=m2—SÍ<5S²Ž£(kNÒ&þËá_&äO¯0ÁÁ‘Ç	ÛØQP	¯]…'Ü÷"ÁPÏ/ŸFLmÄ0d›Ä[­c$ì©óèÚ™è‹*Áq@#ÇøèõtR¸fX<08ac/©>bx8<ç;PAspO#»ï{SJ¤Ð	CBc<êaÈCk4‡CSì`>±’AM´¢c"‚	æŠÒ¬a[H‘FÍ,‚³åÌ`¤ËWucà¥á8nÓˆÎSøý/çUn9 ö—71ça_R€ŠÃª‡l‹N(½Q6ˆJ‚¹GÎM24ÒC,aÞdA?žNS¾*,·^ØštxÁë</R
[$É#<ÓÙ6n•În°ì‰bµœ+T{ªæ-”WL®Æ$+¦EèeÂˆð¹a˜çNÊG£`–Ð~ã©Ém(t®xt@BJ¯°7…¦æÂèQòEÐˆŸëèŸ)J3á(;F1²rÙ#×›åÀ ƒ“X¹ ™zŠÒ4/ß­&ðp§	&Y Ÿ@®H’&ÇÈ¨Éf³Hõ
é¹P$ü6Çí°‚¼M”ŠþÖáAîs"G0­´Ÿ77zQÉÓ…ßGW¼¼Løb[Ü¾“êDFŽŠ*Ò¶ÊÖç)P–ÞçœÐ|¶DyÃC«PO1T1*²q6NâdŠÄ@nkÁ×”ñˆÑ
4•Ä„Ô”C%U„É ›Šx^šC®ÍÓˆÔ|ßdÊ‡B	ÝxN´¤D*]S¬&ú¢ñawìÖs£r’MËj »º66È‘ö9st3ãÄdvê®œ“(#×:j“~HðvÃZ$²ÚáqF´“øªq4™Æ“+#—¬AS¨Êr¥yÓaNÌ¾$üw	8Ž‚JÆóöíÛzQÉ”x¹zoÀº¾šuÆ0*$×¢m,=dÓ	èÖ;fl¸×IÊ`GÄ””ÆN!ö®Ü³UÀIIºfÉÛ[q
Ü3áf®15 ¼€Ì;÷wë&lÉ¿£GÍšz9B/
 ô)sÁi•eG
G×Þ#Bh¾žc#Ä÷CgÖ³™3Ù%ƒWA¥ ´<›ãE@‘Q(´N â~?"³Èåy””œPH¨¢áÀRhwfiYÄÁPÄ­ˆÜ[×1SÝŒå"N‡”ˆG“›J1ÊáL{Ý8fl£êÂ^–æ¹HB4æœ¦
3÷YKÃdsýž•‡‡3“èecaYÎ.ó+GÄ?¢
1Ã³†ƒbàœè®Ô»ÖHë\ASÑ
¸áÄ4A·9Þ3¹ËÄ¦ÞÑj}ÛÂ:¸Ú/siƒjÍyj˜–Enèâ¸ÄK—Ì›:íqVâq8£‚“ )Þ0‰8é'‹4Û³.·VP=î9”øštØûÄ´»ƒÄH 3ÂIn6ÝÄfN¦qƒÕ]C–‹arÁÙáÄ¶¾RÎFµ§+Ç°å[G©»1´Æo+éžÙDŸ@å­?)ÐÕ6»«*VAW*9C‘„Ó‚RxÏ1ÒÓ®žÁÌ€6VU…Æà4B©À©(\„CÃêMý,œHŠ’92ø SŸ—- ·Äò,‘ÅÓV3·+þ¢ôR†ï¡'5+Xÿ¸Ô,Dz·êÖÙ@&–`Æð‘NQlˆïXì"¤1ù>)?îŽÜ‡ºÔÙ{+ã>lo·5Ám¤Lú¦òè|ì¢ß‹Êè 8ŒcÁ…Ê4»HY"8[fdÇ„eDÕø´hØõ¹„ÂS¢Ÿ¬ócK’H›ÔáèßBŸ¥ÉÄZˆ06)Î¬5Å ‡\­>!bºú´8†g(cj'Ä¡I7%µ%»0ìË¦ð8ægv¹™°vòr™ŠÔ»Vlüa¦m‹%o+«öÉòÒ³{%•íxbGß«ãñ71o€)F÷òx0ìäYœåÖâ¬ßfÜÎ¨Q¡‹#˜¹Ø¢b«sVè’ÒörÇzhÌ0<Ð”_²Sé×asd³±åTª!1«Ä×6^¹N°{Ÿj]¸;att=`ÛQTÇ0Â!/&:[Ù
Qu(38=ŽcõƒÜ#Á5lÁ£hØæ¬\Š$Hë“Û~.¦¡Ã{”xauv&N½eb™Õ‹åÇx uÎ½éªee[ØF‰¼©ë›ç±ÖY¨.ÀHØ6Ç‘ÚÂè@¯urå¶ÎÉ!C•pM²1H)E°‹¹¿T.€É`*Wb+F›ÏFóÈwH×jbšL((‰78w9‰h?Ð>"ykìš¹ú€}Š]¥Gs÷˜CíYë	…@T…%9ZÍŠyYYÔg¨*&b	¶¾pŽ6 ¢¬3”MJÕèÌøP9 I²à@ ÔþlŒ2§¶x1Ñ®èçðÿ*Æb‘ÒŸ¹ã”wóiÚy¾gß¨5êmÃžOáà]HÀÎ¬ñ»6
.‹¹¥AÏÑh¾—…BéÀá™ 67™©A!#°´bT(!®_C‚„¼Nª£ z{„QAÉÙá	ÊFÆï”²œó“OTCT².Ža›rë<i™kh<Â™~-Ì%àYÀ6 DQ×¯!Ó;0ï[¤ Ä	Û#Ü¸ÊG3#¶Taç$¡›Æ€Ì0aÚ`R9Šj¡è:Á{n¼VòMo©<…'«¸°ªFñr~–ÕD&yU´tj€sâÝè"%n
0S¡"¶° a+„ßÆçÙZeÓÇk'(Œ„wºß„J’ú])"NDÎS3’ý®Ž©º( *²‘}àz`„Pv(‹e˜j ¬+åH/«*é.øcÑOì±¹Àˆµ!—hØØ*ðhÞt¼ñ ÄgÉmírPÍ QäÊ0dWÆ†œ0ütEõIªLd'(Ã è.è¶)­º—„t£EœEtæTš’~ƒfG¹3—`ñ\¼ã1Ë	|ñæ$E¶žŸanBk ôLŒÑù´,ŸÖ­‡k“zSq0Z¨f}»ëHÄglg÷,}À_KgÌ7ä³ž=•¸bæ¡ñW*r 4Ez™Y
¾a: ‰âlÊ§¹¥ùŠiL°È"gúîKèÅÄÝjNÚ›úOŸH/MM…¼Ã+Ðª£Ãe½èe”fpÍþÔ"ëßXîfà‡ÚãP^sF[!]BÇNºÎ®]æ#Jö9\E&eùyI6û±“ô€n†Êmª¥”CÉšO"³x!Bíâ‚1éLƒðÀ–Œ‹7‘7Ø¡Í¡Y%'Åò–z¥‡Ü d¤Ô|"ýðã*Â1ç…4ÌH2±Ysä‚;ÎÙ×-9[¯büJrhŒ35v8õ¹”`Ú€ ’+„aÙ5({.7$á¾()w4ç“&"Lo¥—€ÑX¾M¾ÐKTœÊPž¹V¾WÅã®šNåŽ€[Ö/2ÑDÜ†‘Øâ,»Â…^¨Ï|Ê®’¿¼…õÏ‚T'’XdÓž8/3æûÛ\_Q#Cº5Æ:‰ª¡•'ëÿ©±Äïz„ŒÏ‰ûáTM.xå–äbÌ+ë‡|KurÔ-¨ŒºE¨±àQ†1Š²3Æ·ÞÑ·YÇ5ÄÇ¬£¶Už„¹³“hÂE.w®H„-vÉGš`p®i€q;xD-=×ùìkagûÕCªÈØ§,J6Ã“´ Ò}V°®Yâ¬¸eŠg‰ÄçáÇ%YŠÅ¼Š™Ž:w
]gŒ	Å™ ø;õO
…‰%åÏ°úh0À«’Ø,ú6Rž
*×ž7I34¾ÏBJ>²|Ê{Ÿ%H{¥!D)Üþí‰ÅêºYzÅS–:!tœ½eÇRÇ¬ÚJWîŒéNç	š&’{xÁÂäXjr$ï?E¤Òwrú`JéM%è>;ÓJ|àêÒØì¾õ‚4˜+Yá¨™†l¤rìáPê(ºI¬^nQ8ìÇ>IVÉêjKè²–ºä\ÂVÇ4«éÀ›‚ÈˆgÊXt)' B/0i§0W-æÀVà¤46f<œ·inkÚD¢ Ã„ÓèŽÚ”ß39$^K[Ç]vñR!}óÀx¢¾SÃñ§:€6hiÈõMÃž9°;ÈHYÔ×OšS`ñ<r:;N7s	Š»&%<(‡LŠÈAæBÎ‘·XqQZeD ÔžižêÌ!‘ã‰
€%}ö«Rz+úæ¸†Wš-æÒL‡5[ðÍVhóªÔE¾cè41^46ÙåÔÄ¼z¦r5¸g—Ó;í¨!,$»†)?€U³a«jªÓäš9žÊí~	gà 
—´ ¸,ÜK9èíN§œ¸-ûÂU)æˆ$Ü»L|b°!Kgb¤7*«ÙYŸjþ$™H$WÚ<@ÓH¬Sì~'l“ü2HE}i°*•ŠÜ‘vKŽÓeSv.ÑK²°T)ÖïpQr"']Ö0»?·pkOÖ¹¬mö¹f
¹û;HÁ,]˜™RscÕgÌ¶4/n2;Á­Šr*ˆ¯XFFMYC–Á“ÒP9Kmfpª+0è"~1¹ S+ÊcÜ¤Î‹î/LIR:¶=tLƒÓI!åÁ0iŠ2À–N[C01U4Ž:¡¯:AlÆ\ahsÄêÈÒ¹TEgà+Ö
e…Rd‰N£’±­Â”pw¬0¦rÙòcÓCÃ¥HÁ(R9ŒÀÔÇÖ¥§ƒ¡«6È¦`ÅÃ¿‘E.4–ñ¤˜â<Š«»"cÐ&€j)©‚â„,%ó6Ë<Ë_ÚæÂãÄÁªÜÊÀ“¹QXÝPÓ9Íp·š§h  ”É¹»J²ŒÃ8ºˆl†œººóiÈY,6Ã4“È+“ŠÌuèÕ“fÚæTpdÒÝ0‚tªu-h!šp£¤:Sú:ù«è‰ntp”‹òZU@Çh¦´Žö5cÓ#0œ«®öçjJ%m:©Àºxƒ‡ç6£²˜|°8—Í^ñ»`Ááä©6¥D`íºªaý‘,&–’fW5¹³€Ç~:.ö³s¢‡82¼a*¾äEõ…eëÜõ²õX2°ŠN!<ÉH/6ÉG­…´|¥«Èx©Ä’CÂ«Uƒ‘1Yô4N@' R|øšNQ‚” R›îHv2}Ð†œ‡W#ŠsJ­CAzðªRHim_•"W˜/d¥P£Ïí¯›e³†.inHµ5¼2%ÑvºÒéÐ†×¥%¹èS$øT´LüL<¤™ Z	ÞYæø¹˜Jûöy‰Kýãã:3tBÀ8(Å‘C<“~U×æˆšû#XôÐiÚ¹¦‰ä­8ÀâHÁ±Ed#èsMAPKÖ“Xê¯Éeh´ç†µº¯ýQí†ìÞ™¦ã‹Îc]ZÖ1û™L*&—MOÔi'T‡d€ÄÈSMË :3WW\S€¶C—ÝÈIcvw=z¢RØju­…Å­ŽÌ5F°ßû1H7sõÓ‘–ß
õþØDÑ—:ejYë‡TÎnJ•aØáÈv°u%QløÐ{&,_wQår»Òõí`!‘Ýb¿Æ64ûÝ–?ùÚMh|Ÿ§RÞ@§–åñh:œ„úžŽÔ+UæòLºDŠÎCKMÝ¾&ì¥d—wÍ?2@¼ÃŒŠŸMEš&âÒ’ÏúÄuvß]…².hôXBEëq$™L#ñ8gÞ3rX~PÅ”,¹®ŽmfÙèšd.ºðVÉ¨àähdxˆ9:SÇ¨ùÉcn5£ÕÇ-Œè¶R&ÞKÑA2w=Å@Y,‘’¼Š„%2Jþ	Í¼›'$>µòZ¹ÃW’NÆ2Z`ërØZ¯nñ…Â’S‚L®x7Hß«@A:&…®DdW«c­Ëâþf×Œãí1Åõ¢ŒÃöœbþFë2*8£•u‘øqÎ®b|Yo©ÃvÆý6rï^*˜Gp™fÝEÈ‘­R€,hrÁzÝ€1=íY7Ò9Cwþ¥‡°ÆœFhër}X!ig±Éæ•¨Ecõ"åGÉA„øB3J†t‡_gB]˜KX&ÆåvüL=am¸2*	ˆMS˜:î‹n‘L±° ‰ü
Lp¹Ä€jiÐ„ó~FWa­‚ÂZÕÄ¬‹IÖêiîu¤øö”Ò08’šlwŽgÆ•;¢pë€*=ÂÀŒ¯ƒ(Ž@c‚5”zxX¼)Æ™×	¥]Eµ¨7…løXï<Õ^
„ìOf|AÕø¼Ö¬Ýaic>\ñ‹ðªDøÊªà"òï3›ƒúB÷u<?‚~˜‹1Åûòªv™ÜÇF¯Ù/	A×ohße#;´¡ZÜ2“ÀU=›‰-™f6:7pãþø¡$õÞp…‚¸„YË VD¸dÀTÜ¨4-	ÀeÄéÅCJ&vOZ&4œQé	g÷º{ØUÛGjo_ýÐ9<ììÿ¨^íâêàpÿûÃÎnCïÓ÷î¿w÷ŽÕA÷pwûø¸»¥^þtv¶7;/wºj§óÞœôï›ÝƒcõÃëîžÚGð?luÕÑq_ØÞS?noï}O 7÷~<Üþþõqðzg«{H7Tµ¡wzQt·»G8Ž·Û[]wLªÖ9‚a×ÔÛÇ¯÷ß›Áû¯ Èê¯Û{[ÕÝ&@Ý?8ìÁ  öö.Œ¸?nïmî¼Ù‚±4ÔK€°·¬v¶afÐìx¿`oÒVCÇÁ üÝîáækøÚy¹½³ë…×j½Ú>Þƒ.hí:<òÍ7;ÃààÍáÁþQ·¥x	,øáöÑ_Ì@ößÞt X]€±‹·Ôc_ÎœØ&œ®úqÿ²˜÷Î–·(¸P]µÕ}ÕÝ<Þ~Ûm`KèæèÍnWÖûè€µ×Ý„ñvTGÝÃ·Û›´‡ÝƒÎö!®Òæþá!BÙßc4zÚâàrãðØÑQËL1öƒºo?ÞìíàJvÿíÌ±DùX‚ð;ßvi¡œ~Ø†áîÄPŒz~°ˆñ# Ø¾ÚÝßÚ~…Û"ˆ³¹¿÷¶ûãQà®
¬³EÙÎË}\˜—0mŒ W	÷m«³Ûù¾{ä`öÈ%ÛutÐÝÜÆ?àwÀG@€^ª½#˜+n-< ª{Œ9yƒ7p÷4â@ßøÌì²í»Œ”jgÿ10Øêwþ}ÙÅÖ‡Ý=X(:cÍÍ7‡pÞ°¾£9z'p{wçKG|ûp+Ð‡ŒðöUg{çÍañ°ç}XBIèì·8ª7Ü|µý
ºÚ|-Û¦¼£ü£z[ñ²Í:[o·é8J?0ÈmY˜Audìû¶Åw‹à•JI*.óê{DÏdÄ`Ã¡‡È6üÞùàH[{£>Ã‹pò
W–øf¡ÂJ—âá EÂè’ S,áÂú?¨)¼Ë1õ†)g‚bbËº#!Ð¦uš§CÌŸ§ÂÉ,~ Œ_ÄCgì6G³¤^nM,ðÂ¦;³´~¦èÒbàöÅ²®ÀKÚç7ÚÏk¾×©CKÄá\Ç:´üGdy{ ¬Ê rÇƒ$÷ú.pio%Öárå´xHdg”ç˜çNÅÿ2Í¹¥ñŒä®a„{çdQ7a â‹'u6‹CtÝ&šFù>	ÿ"^}³ªñ/iÝX_’F1bªÅhÅW:e$¸Mvè<àÔpÄæí‘ng[P‘fÏ÷µäÞ˜É_bÍtªúE‰	ëAIöÖÕßHý©™¦†Ê²˜EÔ8%¥ŽíºzÎ`jj»ÒU¶(›
r}‡ËIïëoÎüæ”N$ O³8 %4Å‰Ä@Þz!U‰´”µ¼YWßauºÐHuúÞî÷XîkÕaÞvo˜ûÆ½MŽ'Z—çU{çJÉaîé’ð3[†oh5¦dZ°qœ~´ì§›ÖËšM«zì<ÍÝUçè^ÐI:¤³dÛÉUiQÕâr-²=3yµXAƒ`iã§%VœvU”¼`qg	^Ê
^Gk‚až®]¬&ëªQèpñÚD6û‘u³K]9§™]KVÙ1ò!RßO&ãvûòò²u–L[ivÖÖáí0 †îaÒ[Ú‹ˆ0í$û7_=N5ïÑÎ—¥	VÂ»BÂ1F®ÀÜ\F9võP‰²ºÆ–†¦rú²•×#›rFéWšecaØ	Õmäb§nÁ^,\#)«ßI¿/n|KxÈ¥™iM;/öwÞww~t5™g´§²jrútãûåÃ–W<Ï–u-†Ø&½ãMø4›¤hcIxæv×{è-KçWc47’»P™[õøhæmÁ?}[½›éì„aïTj@‚ˆql[š©»F´XÉBëµÏ„»ÿfÛV?–kh@S²5¨L€§é‡š‰›”!S¬)†ZR¯œëô
#Ä^moAÐ7úEYbºP¿ÂÁ×­‘×+ q0.VÆ«Y7¾)ëŽVÌ¯ŒOÝ?8|³³s­$Khø@´js¸ñæm8¤ÁÂCÊ–Ã9”Æ˜|8ÒÍ-DÂÝ®6¶÷Rër'WÂ¡Ë!ˆe)ú1#¹ÖëJ’í¸ì/åuâ¥Å`òL‘E<4ds·íQ\E1CÊ9\Û³ø]êX„K	/À«»uÜ
.È†e³¬{%…ý
o–Ô¡ŒŒ¦t,¡©ÜŠñy¢t:>¿j_ž_5a™›Ã³ñ°u>aw~÷Ïøé§½öa·³µÛmú_¨•••§ëë
ÿýöéúwe¿Ãg}íÉÓoÕêãµ§««ëOÖŸ®¨•ÕÇ+OÿN­|¡ñxŸ)²JžFsÛA³Á`Îï<eþý'ù<Pûo¶ðâ·(8ÆËžû(‚!ÑVnuüv«	¿w“‹ÿýý¿D-åRN2…Ò—$T™Û@ýè%Õ$J.bØOƒ„töïè;µÓ’Ï6D¾Ñ©¨QghÆ`¢Zæø"°€:dX×~Âéa'ûÛ[ÞhH	Ë8ˆ	ƒÐ=
N<™j×)ëWº^,À)Ú8cPôá†¹@ÍÕ“Ì“9m§OCàyÁlüÑbšf(ÞQt·~ ð§èz§š”ª„nMá[˜½eÜÒËè­3Ë-G»uØÙlP£ï§XV†ª!uÎ'ÓÁÀúÛâÄ”õRÊ(0’v7r&|è‘FšGj.á7¿L%óÑ£tÚ‡AµòóGdYú6ïdŸM¥•\8ÉŠÕ4é³"Æ0-âv\— vÁ=ºb@³dzâøbN½úây)õ‚
¬ø¸H-äü}®^WÄ"Ür³ÿªÓXçUÃðó9»DA%–†¼+;q2ý Þîþïÿóÿ†Qá·ÒÞ{ö€£0q0Êa˜O#¼1å Æ¦¼oô4Ñç/ÀÐ®ÚG“,šôÎ©WðÁü½Ô½-ƒ†ã ìÒƒ  L¦ãÂvÙ¸ŽAŸ!›Œ6Øè\—%³K§p7q9Nä'ÜÖÖ ÂäÈÊ_Yd0Ðµ—:ƒ³>†Å¢~x¿` ÿñÿÃRZ¿pÿÕV?Á¿'½~ý¬ÚÓ•Õ6_)Ú.w¦šçÁÚÊê·ÍÕÕæêã“Õõµ?n<ù£BßÀáñÞ"Ì†‰ŠW—ÅO«VZ«Rxc´í½Wûjƒ1´–³ÊFLì8¬{„uWç¾ü&çë¤Ëù©y~ñ3ü÷T}·Çv§{ò²sÔ}ñ³šOÁ±yc{f¼·i^ý©92¿½Þßuž¿„ço¶àûæ_ßÈã¹-Eó¼ÒBGš³Z&¹k„RóYT_îb68¹WïCï*~‹ ÖÔ…æ<W[šÒ´Ô.²8":avF/Z¬ÒÍéjÑÇ2¡:pÞx oóã¢¹¤zç
Á¹h`ÎD–ûÑ DïÞ’þµÞZÔEŸ»@@Uä¨îÂ.f]ÖËNúœž@üŒ5´UŸP h);.×S…÷`l¦ÑY‹Cªû*œ/Zˆ/HÇÛ{…GjêLŽx2Jýtå/:®W›~¨×õXq.ôxöÞOÇyUŸüÓâNcîÔ§s;%ºE÷lVtk~\xÊ«¨Ó‚Ù
³¯Fºö(î÷‡îúÂ¾¿ÄJß‚î¤gÄ'7T{2—xÜ0=C&^áL	ÑsJ·‚ÜÅ#Vÿˆ‘¿qégÞkž>z$„‰kÞKÌKsÎ"C3»6,#ÃÛýê·!ç~¤–µ8Æ±©2¾¸©ŽOhÜ´– ‡$Ú(¾ÁÖÆ*:áJù¥–ª’&¢äl²Òé£ÍE¼à‘hƒåÇJ	ã¹HãÒ£>ÁÂÍþcse­¹úôdueãÉúÆÊ“ÛÉ#«­•ÖŠ–Hî¥÷[È/3_ÞÂìBº1žNÀE8œFùÜ7Þä:,Êz™.à›T)WÚœÉeÕæó¼¸óAhé~nbgÿû VÛxLç½Û=Þ<ÙÜ?\Ð}›œ¸mÀæ…ÀfdÑ»†—ß]øžÇ&œ>Ù_ÁòSÔÄ#o°†b{o3¾	îo½Ù<ž¹þºbÿ@!ßš·•ª=]®®µÖZ«­Ç­•› ~µûƒü> ÿ¥ó¶S/Î³ö/ ¶é¿_mý±µr²útm.¤£ÍÃíƒã“Wÿ¶WÆ¼Ù4t.HákHau­;÷µMr¶[ƒ…fL1ç0;ãùmÎ¸€52îÍNwõ[‹ŽbÕ[ejp‡ŽŸ¦ê÷npŽª_¼X8ß›œ¾—4F€8^X¤nò"`ç$<¥,Eú«•cäýÍ^D«ö'oë¯·Ñ:Ùê¾ê¼Ù9>q!ž.Øý@…<)£…GòèT£ÈÍmú
=|7
Iý$ú€¶R÷	có„y¯t;@¿$—)ˆò6ÖZçÿWB xß¦ÿð»'=âh^ÎÃâ÷¾–Î{»£ÿ,,P0ŒOÛœÊv€å‡<ûç°Üï4"ûµ¦ÕwŸ´Pl<üÃÕt¥gYŠá*~óarÅþçÙÑnk|5L¨<ÿ!Žør˜ŸÀÓ|Ô’Úµ…ß5Íòqá@ $« <ôŠ¿ÀëÓZ–ÛŒã¬%ÑÂs1ñ0b!ö/QaêŸÈ#ýâßõ5 ½4‹\ ³…¤2‚ÍëU¡7ÑïX ZFRV¿+J–C½4GØ½Àöb‚`O~ûd“'o®‡ß”\”† 0èP-jsî;­íñ²„àÚ<zïí’Pl$væºÎÑÿ“ª-}ÔÍ®k EÔjêçg”¶(E-šl„’Ëu»¥Ûº­”jUµ€_¢¡ÉD½óTÕº‡‡û‡À‚ÈŒŽžSå›ƒ8€ÿÁLú¬ñà]9„gìœè¿øèy­¥œ)´—>j"…Ïvö7;;ôËÉ^;ñ¨i;Õ‡‡®ù>¸;Ôùì×Ì¯?Ì0;Ågí<Eú ™ßæÂ•2\õ–j÷šB3Õ6Î2$çH•z1[?Žu2  w>‰ÆRö3¶¤ïí áX¿”Úª¥ÿdÁõQKýÛÊ¦p"š[ƒ›‘#Â¿O9Lí‘1¯
ašÁU¹ŠÏ=&²'`îI‘`XÓxÞ‘¡Ó¢ÍŽÎmÏ2I6¨šž¥Ñ¹¾à”,zQçÁ¼¡Ñ1áZw²Þy<‰È§/¯Œ]ã‘vi¡±½á6Íë¸*¶\‰aÌxT§9_7‘
 bãr­hx^¸ó"–›ÛsS¥B_Ä.îH[¸)2®ÂÖ€}9sœªž±¶…5lÄ›à¦IµY†Á[Ù”ï˜3U@\X8Göë²1¯Å	Ý\£ùÜ±ÚQØ¦S¼å›üŒEˆ®ÅÍ]"Fª;Wçž–³Õ«ã	ZC[pŠå]º/N,¬$CYF<°ö¨W$Ð‹ï™-Å^¸„Ë
KÛÓ
‚OB>ŸÔVÄ¤ÛâhØ,Ô§âlhÉ·Q‡ ¾(	4LºWÅ®%û¸ÝBaNõÄ›±}…:aÀÖúkêû™SÙ¢	‰ÚU˜¹<-T“š·½=•
MßAš“ŸGà­Î=nˆK†ÿ>:ÚQ¦ÞWÙ°Rd@<PO¤¬XU)PØaª«'ÂœMÙÌÑ¯YYtÙpê¸³úS¹{ÂCuÌRZ}ýWèÇ›P)e.–EAÿý–ÚImé¸Ò4 ý’1B"WÓáøªÈ¿@°vVbÞ"Œ$<µ¸\€ÕŽUq‰öÐ!÷3GzÆôÊÒÒO÷5FÜ1}Æ¶9ƒögÖÅü‰‡Ç^"è¨¸GÃ±Z>¯ÛÊÜØd10öŽh4ðœÚOðgY´¢…B/ÚŒe’E¬\­ÒÜŠ°+w­eíÌÜêîPc?ËP¤¬ë–Ç):pÅ0?1SØrìT_Èé—åUËÕl,F+
Kcé©¯/½$ASÓà–ÚÅŒÎqÖo‚iûLuö_*+áH¯†ÑJDrÅ:Aõ‚žˆ9u÷Þª·šu‡pÈ|='s¢>ªÙÚÌ†Õì®’é©9Mo×ˆB×®¹¡–zýôÔÌÀù‚_‹.·ÊYWx©	¿bœØÜu•OŠÁ$íÐýú9]»Îs,j¢ÅS®RahàÜîB´ÌðJ®¢Y+³Ú˜?È¹ÃCÑM“S-IXå	±Ï´äÊ»È²|™TDt
ÐŸÂQ#y†än§Þ`Ì2±î´R$9Ç
§FÜ+†žÐ ´,sñWoµYYÒä	ã†þÊz_Ì¹zãËÒ™¥þâ•1k§¹ûì¡ã†Û6OKïI¦ê”(Ö•>P~»€îN8ÞÙ³vl…š1ØØñ²n¼µ¶ÂxO³èŒQÁ‘¾ò–¯Ÿp´L´œN8È¬áº»4k¼Ô©v2C§ˆß. øÎân§~ÃêN±ßÕìOõ~PWp<v¥oŠªšß:Ô­zg‡N…OU*•ã­íW„üˆ61˜6ñÅ»ÏqˆÜdxns—¡A…Â¹à|áN§JG0n“ß7	ëÖßf¸J>««ðÂZë1¡ÒE\9ï*¯ñúzá¿ÀïLTu•¡{^M7>¥‰Æ.G©ˆ)+lGñTÕÂì+Û*qa«•X1¾¦žôSÁÖþng{¯bçž6¾<ö^F0ûóI‹Áúë>Z&$SÕÄk‹¡‚zÆÇçŒçü
h{ãÔDg[÷óÚ3jÐ8¶«Æ Íb*ÞOUÃmÃ }Òö¡Ù±’ÅÎ+Ù8w>\Ü9PrGßIoÖ3)-o­‚b$ýÓÓ÷ä–ðkkb<ªÌJ%+H7¨Öx÷#çßNfw¦0š½ÐV÷ÕC%2o œìlû vbV®ü`×Iø”y2ãËÇ—èà‡­“WÛ;U2Í¾Ü¨ªú€zèÒG-g\·ý_ö[“d,péÇÜÿþáq©oîßë‰L_Î$ÄòFC3€8<k> kS[î°{°h\EKÜb hÈ[ ÔØúæ“]¬Z9iëú ‹;%Mä\uXuÇ“âiÊ¸¿þIaVp"¶&4Žã¤êècÃ­Û|s¶$P%¾ìAÚgi9™>bB¿~Ÿ_)°]S?Ÿ!B*úÝ^	sžæ4^5<EÞfƒÍª×ÀºxÆA0ÚÜäòï%ßÊÏYrTgE,jd$Ä*%î9…¶ÙèVR £0Ç2ýR«…Ê ¸Ì“•‹‘ óŒ2¼ÜŒL}§)ÅàX·7’lTµ®²Kªûé¨Å%r9	Ãª%¢Îð7Úø>B¡RÍ®VíSº—€ZiÆ ÑFY†EŽÌ( ø·›Á”\G¬>`ÍŒ¿Ý´‹†Î ßÏô{ë³£kÂ³¨‰%iÐ¢x¨á˜xn?±"~Š`Ér.§Õàç%æ¹mø B¼ˆÓ™ñ·t%"O8Dw&ýd2z« nÉœ¬_ç u·°Î•Ð7‡Vi‚PèWÓ„{‘N¾”ºûÿþKÀë›é’×®L¤´œŒµ°ðÝNwïûã×/dúôÛeþúÞ õÿ·÷­ëmãÈ‚¿Wß—wÀQ2ã$cI¼SrúŒc;iO;±×²“¾¤?^@Y‰,jDÊ‰=}–ý±±¿ö¼ØV 	R”å‹¬8ÝDÏ86n…BP—´0:õ9N3Ø¨
7âx€¸ã˜'b?¹ÔŠ É(ü;…m*)¼ÿb)ÞÄŽúñi;A4(n&‹€‘—R¯£.âúÿ×ýWn°mÈASH;k.Í§'>á7Š'ìÕRZƒÿ÷¿ûáiòë+šx÷–µ6dmmF[e|n¦ðwÄYôëSÄ(‡gRï*Èâ´™œ}`až‘œOW1±œÍï½&\Bžìx„Þäµ/À>?>xŽžoï¿{óœ]í~£X§²—õ«&Vdží™ 3+%9HÙSR	ÄÓô·d3g?üñ)HÃ­9Ò›Há¥-HÞy’W´)d1\³‡ÔÁ¨ìý§ ÿR&Ðžã´ô:–”TP 2º¢u²g2^+{5ädîÄd”½°‰Eä­£¼wÎ,±3Çúé²Ž0Å¥„ ã¢$Ó<¡Â¨8ÍEôI±F€`HŠSü)èMˆ÷õØk&Í—ÞˆàY‚¶Í¹æ§ãs“ásñ!?ÕTI1Y Ó¦ß˜þ¾½{¨~ÏþÑ’x%‚&H ¸Òƒ‘O_#„ÅOF¦wR¢š 7rÌ•å°ÛXìéìö,îÊöj“lr%´6•Hì„Ž\:Õ’’j¤s©‚ìFZX	¥Nv†2=wÚG>¡ásâ)‚`¸†¶4Â\ö/÷	œD7K½b$¥Dòë+øwê®á³8FùBÅr4Œ{Šnp¢VQ²Ùg…`Gµ£çl‹9hj°ZQëÙF­öœüº“èåóìŠ ¤§8¶C‘/ú«GS=¡ÏE–{ƒú-¨ôŒM\â"-)'žtRÄÌ_Þ•Îõ¦ÒLCÇ„.S×Ê;hK½éÅÜÍZ4Ï…Sæ,èk»}I*í7[u_m\íÿGQUKüÿ¦m¢ÿÍ°+ÿ?«HµTÀ=¤œÆœã‚F®±çžÕ®w	QžŠêœmÏ´™NCþâ)s+‚ó~Å¹K'¤î|í•ø:‰í1ãÍèÔ¹6ìKWô¢ÿ/Û4«ý¿ŠÔV¨cÂò´=×Ñ©Žû, ªÞv}Eïx¶îû¦ªú¾Nþ³Ùšµ³]Ú¡jÇjû¾fºmS5uêëV[óÃÐ:v`)¶bºŠ\;³53t/ –á8ºiº†áØmCµÚN[5Ú®íXŠ«kßP©\;³KS• íhŽihÔVMÇj»^[÷,ÝÔ¶h:ŒÊét<Cª-ì#¨C­£zvOÓÕ@·:®ïR„ïÙn xºÚöMV³ÔÀ(èÐŽowœ¶¡ž§·UÍÒà_C÷ÛZ ºm˜ÊÀ4ÚV€0N¢ŽâÒw|¿mÇq(ôR³ à´5¯ÓV©¦ªz±qÙ2.Ð+T?p_÷LK1<ßtÓ2]U7Ûžã™ì!	ZÑ™¾k«ŽmzžëfÐ6Ãw]Çu´¶åhšæk®æØ–"U+ZÜµ=UU5§àS……vl¥MýŽ¢»NÇ ºjt4Ó`-/²'sUÕ…Þ˜mßë›šÔ4!lÍ…iôG7,K5ó°ÊMâLM³L§øz µMÅ¨b´uÇÓÚ
Ìe)ðÙoûö,¬™µUtXR%p=ÍóaEM
Ýl;Ša[¶«´mê¨ŠÀÆ˜%[âÑÀ¬0¦ØÔ,ƒv pmË74Å±TMË×!ÞÐFbF[~§£+PH×„©èªÕ1;ªb Ò–@‘lÿLÏ4a+Scj®ëéŽEuÏÑ”¶k©žm®¡ÍŸœ[âÞ°›bá€">º0Ç¦s K¤{ÔU`Á©oÛNà¸°™4Ø‘ž;¬Ø¬	dÛPìÀÕ`fh`µ×ñ•ÀTÏâà8š8^±o’é¦ÖÖS‡-ðLÍv\ FMøi(fÛöaâ(þÏ.ÌNÞîÔ4vLÍPtM§T‡yA ´N…¿:JÇÒlÅw
{,oYÕX[Cµê:¶ëvÚ–
O5X&×Æ- 5®„SS –êR@ÁÑhžb«0¤¶¦º
ìÇ6l§ˆ<(È\Ô,@Óp¡yjëNÇðT©¬ð)àµãR@]q‹“ËLjõDXÕf‹v
äÈÖ=@BX×Ul¨»-ÐMÕÕ`¯¨mÛBK;å ä$ã4ˆà„©cÂÄ!¢œh€Šª£ÁÉbÀyâÁp}[³]Ýó4µªÂHÜ‰ì‰zjv·MmSëxªaû®aul§Ý1ÕŽjáÉëºZÐQ|¯¦v’úÏÉŸRKé ¹T4Íƒ%q:®
ç¶cSø-ØÎ8Ï²é ²PNÐÖ;E;–ç[Àtð„Õ]ÇquÃñ¼¶¯:Ôœ3¯ú	¿È;A…È“0ð.Œ÷ ðØ¤Ð3ÃÓ‘Œh&°}œ†ÔrT©‡b–‚ÕÔnV2\âp«ÌÖÑSLj8Z˜ Õ†\í´ ÚŠÔ)pÊajE˜Âô½Ì5©åHæ€È¸:@íÔvGq¿|Í†Ïæ•zí Æk{uÎ©¶mÀñßn¿<„m Ä¹°ªŸHG'À©±ël#m_ÄÄñ+ÕuªµÛšiû°kËµ€¢¦X×Þhéož‚l®ºo¹šÝ¶ÛJÇ1|ŽTÕ÷€Š 9RýbÈgV/Î,ë§ªë¶ã!Ð}Ã²•Â°|Í¢Š´§vÇ²KaŠNò“|QsË´†h>ÐÍ£cWÕ¶t€	Æ9Øåè¤j¥³ÉÖÀ)N|ÃC&R`kß¦Y°;–[¾­Tå„{(”á#TàÛTÚ–gÚ@Zê°];xÂfÂ4]QãÚkÄN@øH¯c*ŒŽØFv˜‚œwÛéèÀ§R ó£Í#V¥$€sz–f¸ž»ÜtJEñ|Là}€oQ«m«Š£0º2äÞîÖÎ›ÞNM÷aH®ï88º 0`mƒ¤Ô‡Ó1ßWÝ¤žä0(05€"ÈKzmêÁã°ÝàÈ€ã‚ÄÐNj&·VRÁ}I	y¡ûnå~Óœÿ‡ò²ÿM×Aþ‡ýò¿yßÃô'—ÿËd e·±àþÇÐ×äÃ ùÖß°õÊÿûJÒãk*’-¾?}LRò›ø½ƒàCö6¢Å§þJzâêé‹íÞ3¨Ósh½HGñÄ‰"J´Î:Q#¯à¤ŠÝÉ´ß_'½Oƒø’NÐ)|m™F5Ñ&O3Æ²ð}“Å‡ß{1ÐZ€Ý“§!ž¡
Èkò{ñÄbüxWµwüA\^>n£p”4î0šŠÞTÛð…Fž¿°nL'Ï“—e–RÂÊYÖMÄá„p¶'0%ÃlÎˆ/ð]4³ ,7:F8¹ÄUmX€ ìßL´°ø –>Ãñ>½:ØkèMåoK]Ä×k@}lEPŒªóÈÉ8 ˜‡Ì
¿0‹±9A[ø{C´Ô6ïv7?·ô‚bà˜$&/êÜ3Ÿú™)ýŒLç€[¹%Ný™™_¾qM8”±³˜6d=@L(×_ð…KWñ¨~žéŒ<Òà—Þ°&.—sMÞæQòæ œ0‹/ø|Q·}_R’Zfñs<îÌés=Ç½½“­ãÞÑþëÝ_6y„ÑÇ¼ÔAŒ/oœ›VpÖÉ¨ðaÂÞæ…ýfÎêb=gãWt3È`ÎXxJ0QGó*€R‡R`y{Låm ¸§Ü„¯/øÌRhy‡žR×rê¬¥ý›5Î,ÛÙHP…AÍb˜Â¡´*’ÙÌ æ'Qò-ƒ–ümÞ
4Öeðfm¨$xh1ÅtjXÑYW²²£“œ­^¡Í¼¯tL‰ðf=ÂÊðÓó
F*W‚EÏ•àíÑ¡9ìŒ.bžÝ¥I«<m‰x¬ÐæR©èßK7ø÷•ôw·Txr¸—6®æÿUU3³÷_U³Øû¯nTüÿ*ÒÒ¶è7(Ì“2ûŸwböR8rLü¬1Sfñ)Yv9ú<”èîJ'ø¬ !˜4ŒàâF‰ªeÑCNmU¸O•Ìp‹þ±3·ì¶äˆ3³Ú¼I+¸½.F±ó™ÏåÛÍÃî[ô<µÄÉäêä §v×ÞOÿñþtãý§ù•»+LXË/¿‘µ¤¤çŸvákÆ6}É¾8Ý|=nç%p»’Ä,{(²™±Ç—ë´4p‹M@¼bîê0³ü•Êž––•
çCKÞ¬dèf].ôÈ)~.¾E8É»’Zr’à!;a5Ól6‰»oæwËÍ c‰­ý7/¯;!|%^]oÈ’¬°½{˜.o*<|r@Ô* ”`ç'f8€0Ÿ€8ãŠŠÑcz‰þ$ëhŸó›'0ñbPÙ\¦U˜~Þ~S6*'äŸ/.»kì×#ðpžŒÖ–J=aý9cÍˆÂd"ÓÕ˜m3¨J'™L©pŠ ÔXýÉ è7§xßë5?Ñšð š7Lí®y>‘÷ñwÿ&Ñ©MÏHÃ#EEE¢}ßòéyk4ï£ñ]ãœÔ7ÈþõßñlªG­òrswogûI«•æ=\ôýjg»UÿŽ0ß¡MÒ`!•òþ)ùÒ0CºÜZ¼FãÉ`+¿v&}Xk%íÝXtàåçó`¶£¿{p$6üÿ$@“»±¹½Í;ñå÷­1…~À™ÿQ]WEø+P™q!LÁe@J;¹7I<ÉÅýKÒ8¼üNxnnçóš´©Ö/×ºâýõ`×Éw°J’MþšXL¤ÞÙ
(¸TÈ[Š·š=MJJ<û:(T T¼¤P‘pIåOç–—
¯Šä-+Í¼(±
õÂÎ¨Ë…|Ï‚Ì\!$æ3… S.$àûHúºù9-L—<¥¹O~½Kí²Äà”°«ü2¹”í³xvs8„_aÀþöR÷FÝÌÍkfÊ:©‹ï‰·Æ×¦–ÝY'&ö¢ÄŒ»Ñ`gáñn‚Mdä&‡#zOÀçyæAAº3î1—ÚW'é‘´héÁ›Îv?d*Ø-¦ßÆü;˜ÒLnæ‰_2óÈä#ÀJLÃ’¬a³»6Œ0èSó9tÎ‡á¤ëLã0-Ð]ÛCçW{{›G;Ý-‚…!ù±±i¡òRnú=Ã¹ôäKÇ8œð.ãIšñ¬²þDCQgö93mF3éˆ@I™0âå»–ùŠžŽù‡é8Ë,æÄÐ ÄôÀšÊÕ»´ÅÍÑ³êôfÕ™á¹Tpêf $TÎ D7ƒ‘YªK >v×rfâ_iË²Æ§g_·3ðúpæL.’nÍ ŽÐ%)’¿ï`iˆ¬lòùóò$óþóAØ];äˆ Ðö­¯ñ‹éý—wgZ«›ÞûHåjÞËmcþ‡f›Fªÿa™¨ÿaê†RÝÿ®"U÷¿e: ’ÁÃ7x,;I¨nƒ£Àƒ¾þ6¯ƒ¯u½ø5®ÏyÌ]vàú1?KüÝ„ìÖ’\d1ƒ ¥qPeô?³Ìº¿3f‘ý¿nX™þ/TTÍ¶*ýÏ•¤ÇŒÜKÁmð|P7ò.UñŒÄ|ç³à*èÈóô,¯—f<s“]Å$™&Ï<”no’OÖ†ä ˜É=¨A¥×Éþ.þØîíì¤žkn¾c¿ö,?ÜTnX¹Ü6ñÿ†Äÿ+êÿ–bUû©Òÿ–xÿ¢yñÃäýçh€—³ê•xÅ¿ß¨³8¦ü~ùço=aøìûnãšö¦fº¥£þ§j)zeÿ·Š”Ùß_7_]Ñ”jýW‘
^zî¥[¬¿­[Õú¯"å½âÜO·XÓ®èÿJÒŒ£{hãæëohÕù¿š4ÇÕRÛXpÿ£*ª]XÓ¨ü?®&=Îé¢´”x¢OCÑŽ|¤‘ù6þG˜‰G~û‹jÿ£™eÖ‚‚:Ž¸jµÇT«åÇAŠ3±¡íþÄ9‹jµƒÍ£ºOðçÆêªÉMÝÁHd°w£Äæ Ê1%îSê}Ì¬lyü‡yXOmšy¿e½É:é’z=í=!ÉÈê¨ˆ4iXu¹!Í²ð…#Ê
p½ÛÃÃýC|©ML¬YŸJkÂdñùJìxö|2¸¢zu:;™’uáDátÂã~É“^[X¹Ò±ù³¥rŸ}Ëmãºç¿¡šª­¢ÿ_ôçYÿ«H3>Áî¡ë¯¿¡ÀŒÿ3*ÿO+I×ó´y·6ðÀóéÉú£·:¢hŠ¦WþÿW’ÿã k{´¼K÷G·y|t‹çÀ%÷9÷ XºÝíQðÑ•¯‚æ?>š}|T|äÑ×ÉåôŒÐ	ôa8¤#â‹È\™ãòQñ•Ã¹á³Þ£yïzK^ùeïÑ²žö–ÚGLˆi8BIÎ¹0”,žúƒ	7FRžÍñ&\Ošæ›iÃ·—WD$Ð\„±‚Å,÷õ´QOªÌ(µ‘RU·´Âl \¬äfå3¬|9Ì•`Í½e° 7_&+6)ƒ¹…r¹¸·i9n¿˜–ÜÞ=|½ù¦Ø*ÏÍJ¡€µ=SŠç~aË—·jÄ}…ÿoDâ÷@(l4< (â×dE0U}ž:a=)ŽNbQöF{™¬wÅ¯9k™º¼IÉ‚eÜ—$è;ãf­Ã'\Î¤l–“Ì o+˜ž—\ŠÏqR	N^:a µvF1ìx‘—DdíÑaÐôGÔß¢“¯™E!n!u4¡®Ã‡ó³F¢>!¾'ÍGa8Œæ—…ñ$<K“pŒÍÑç0Ù–Kyl~´YüÚnÑïÐÆþÏÖõÔÿ§¦›ò¶]Ù¬$U,_Žå›ƒü™ëûe94¾<ŒxÝFkŒ		¦ðÃÐ¹Œß¶‘½íÝ—À;M˜"˜wJ|È\d¹Wxò¨¨æLX¾i@GMò‚àÿ¾3	ÈGg4bàXÎ€Ÿ9£)šÁýå€’Otâ$(Rq¥wèã’Ü@»P¼MfG8æ¼ ‘w
›Ö?H6GCØÃ#BqÃƒü‘!äHè€§Ø˜Ë1ß¬AÜ èjÊ±Wœ€Ï`œ¯‘ÀñòÛnh~ò‰b@£²:Ð‰) †hÞØùô3Á˜Ñg!ícGçÔØqœ úêhB1®t¡ÖÒ¦ÙmoÔMfy~?ÄÝ¼ý&Âß¹Òæ£Zè~ þik´rP‰Æû“þˆ{á¨ðm\–‡ãBŽ5¼ ÏxÂ†?jà>/”'}g$|;:Ã¤­©Ä@n÷z?lšªöåèàí§¿õÎ§ß;þ×qdw¢àHßu>½òÞï«íñÇÖéÇOç¿¼ì_ø›?ý°¿sºûöãážó?‡;çÎÛ¡2ÙzuyùéÇÖÁ`dÖÛÞhüêEë—‡N{oÕ¼Ñ†„ŠQî/1˜Äí%eFáÂÌ²bc ÏÄÚò·¹>@
Š,8â+Äå¬1Ãñé$œöOð÷ Þ :œðYhpIó_úƒs:zÃà¢[­Éò˜M­`G~nOÝ
îiŸc?«¾°Ö(¾œöYùpHy§ñ sÄ@œ\ð_ðå“ˆi²@ß(øñ§»-uÿÕëñë¿ýøî§è§éŸ©Û·ÿùóÏ?Ç—ö/#ûÃE°½szt¶ûÃð§wÿÜ|û?GÑ§û§:¢ý½ö§W?Û‡oZ¿Œ7[¯[½¬³þø¦ý/íPá4bš¡q”ÿóJ*‘/7gƒ/¤8Î,Ò)?/Ñp€½,/ÁWµÌ˜eOØå%ÐÑ…1r‡[W—™Pd^æº@¿4ÇÎé
n÷aC„—./ƒn©ÑÅÈ›óy€n†ð’ /@@h(/öáì3à é_Ìÿ>Êðëó…<ƒk\Q€ó­åÎG¼˜;Q‰wœm:D–ÁYÄòRünƒ­š3¯3¢Lt:1{i¡òp—Þ@byæO³ÕoCò¾ÅÛ“o?]3€ÝÚXpÿcªVjÿ§*{ÿ3l­ºÿYEªÞÿä>ç/ƒJwÂ×¹
Ò”ë\aÕ{ÿƒCå2¯â(qqÊùÜã³>Ež¾9{ój2ù)gÁxÃxð ö1"È(¹&r¦AúÄ8‰y˜ÌZzÕW€ Ÿw:6ÅÃ_úän¨ª ;õE,þ~q'»C†’lÁ¢p3qqÆ‘¸1L‰~'ú1&}Êp¦d€€§LÂc(Âö7{•¬‰>²Ø2ìÖ¯IÞ˜üÄ±åÄu¼;ŒÊA¡hŒâ’`TÚTCÉ¯é!¢[·OX-^'zUË¡0‚J¦cÄç\ðù<Ù=Íå®Hâ%ó¼Ù­·Âq,BÅÔgŠà»^·^ðùò‚?õbÄxUkjMµ	ø-×•^ñÊÃ÷Ë¿ñG·RÒEGÉs ”v/S rÂ¼jJýLË=~3k”B7Ð7&zì”`¤‡]RþCWÕÛBÙ^o¯«ZºUÈ>Ü9è¶;¬´àfÃàŽ»'áf·îò)&zÛÛyônóp§¸lQÄÑ¦užáDk¦Ö	Æ¦ªÉß_Z¦¤ÜË×ïrÅ‚³O%¥ŽÞnçJÅç~+vê:d7#u)þÝ-÷ä˜–‚EÁRBt™üE¸+ØSEéÍ—ë«'òUZñÇŸ{Gû‡;7D¹£³~æChŽ¥Þ¿ÙÝú÷A·žü–¡ÖáG:¦Â(ÎÇç÷î“§éƒ¼äi’üþ;Ó:x’hM<Ã³÷1€es0Ô.S®Pë¹\çjù\çêuYÎƒq7œ®D³‡”®lüm,ÿ3“ÿà‡ÁÞÿ­Jÿs%©’ÿä>çå¿9;á!+©,øïÿË_a6§ü~:AnY–_8±Wò˜ÿc.B ÞôJõD3C‡úqöÊÏ|Í”ÏÞ—Î67e–e0n&’Ô¿ü Àâ†

³Õæ‡-‡ºÎ0£ƒºM!º™„9)bn¦µÀô@p¹¤C¬Î¦NÈ•$zË>~%YÄHÆìA\QƒÀ×gëK¸‹å|’Å$åÜ†¾Ù}5â]C’ãñ–Ãz»	öÞEu7ÕÛMýñTw—¨’›àC¾T’›•ËV[.—årõ]^vÓ÷3Ì}"öØ«Hi÷Îu{ÚB%Yþ<´HÍv\¢b›¸ÁŸUëq€_ªÒ+”Z±ë"Ñ•{—ÏÏGÁrú‹†˜Ròë°¨|ÇaÎ(ëžÓ‰ÇdògX U:†#Á%ÖÅÿƒ>M]“ÿ¿“ðþ_S3ãÿMäÿUÍªìÿW’*þ_îó5øÿ‡®ÌÏ ²#T¤ñ/ª“2›cÅà9bQ¥ü°ãBÑ)Qáà ÓåÂÙ’%wëÀ«R.Ížÿú	ßt'¨§u"L£ît¸ÐþÛP²ó_GýUU«û¿•¤êü—û\<ÿËwÂÃ>þ¥@tÄ{M†Ž/ÔA²'7l¦üøPà¨ãë ]Ùá>Q…,ßgpÀñOLc’3M²9‚Ãgˆ7s sRŸàüê¹Ôç*Ž4®îãîÒÇê>î~ïãöÅ–@¢Á§9à+îïnîºw[‹ÍÒy¹ìû+{¼èþ	GÃ2ˆ0)éœp‚°„L6R#xo8õé‹	t‰ÝÑ$=Ï.q˜
ûî6Óög–©aú H.‹Êî¸zHYî8d€ ÆüÝÍðšz"Â.1fm«÷¬ÿ«Û™ý·jk
¾ÿê•ý÷j’Äÿ-ï¹÷wæo©Î±~ªv"Eæ=q|Ÿí­Éfé!‘|ÿ¤ÛW¨í/Åb.}dƒ)°{7ç¤æ1RK]-ùsJØEP›8pfÁN%À,²A&{—ØøòØ£ksG"FÅUsñ±nÑ}á|”Ã’#¥Ïa:nÊs\ó9ð¯R•™–›+£•–Ñ²]ñ¨xí7E¹àáÎÁ,,ÌM‹]ýòx-¦«&JegnnÑuÌüàà*òé
&áÿ]«/zŠ“áIÍ¼¯ñw¹÷Ë‰7¹$Oš°¤ø6Haƒ‘@)Þ^'÷¡PQ¸ô‘<úÔ„? c`ÖêO¸®g=qtÕó^-<{æ›uÇS»ÉÄðpó¤qšL44.#/éð²{¼òhÙ³üŸVäÿ´•òªÎù?£âÿV‘*þOt¸âÿ*þ5^ñÿ÷Àù?MâÿÔeòê-ø?íÈÿ©ZþoÎûï]ÀðŒ_ÊÅÑ0 PÅÿ­"Í¬¿ª—²>ú„€Eþ3ÓÿÃ¹ƒõ×Šÿ_IªøÑá<ÿ?<|þ?ñŽ6Ãú3gèºíl&ÆsÞ•Û›Ð§ß†œð-„~®d‰'Kè¥eô?ˆ,Ag,/GHÒ‰…á¸^¿¿,ÚH¤5/?¨Î™[s¨€Â|@õ;µ„of—.¢´V
Z»´VZÌÔc\(tïM'TÚ=jYíê:Z¹èS*G¤òÐ‚ÄÄˆ[È”úC’)õJ¦ü†eÊ*};éZñî÷ýÇVÌ,þ—¦3ÿ†UÉÿ+I•þ·Üç…Á ¾-åï|°Iæ„ü†.æDÅ¸­C‡2x3 ®áÎ¡Ô{Ã Rw•ùúXi4È“ TÄ‘ñpÒ—À 2^ïä`³×{·¸ý%	&ý¨ÆÛ j–ƒÀïŸN±m`öèwÄy¦¨ûä)ð™„¹›Npw‘ß¡ iø©o6~q—J£S‡Ì ú¤ñ‰¨
üqJaÝ#¢>Ë€a_…ž>Ž@>éSÒ&ý+¬KT'Ý.yþ+ ûíy>€³ 1È"¿å†—îB.ó¡u 2I^³}¡Æ=tÅ=8¤û=xùª.ÐŠY†Ù¾¶ÏacÀíYøë°‹’aƒQ¶˜ÔV0à¿ûáH4Àßq¿ÔeXøÛ>s÷HŽGl›Kö8=æ¦(•„Ù›Ã=m'ØB6f
`ëßKðy„†#{;‡_Èœj›yèX-ª/wZ²•d.î’jV°ˆòHÀ˜+ü¬©€³ãàöþ¾x}w'÷`ZƒNK²W°Fß”Ç›‡ëÍfùîj–ìÍÖ£xÎñÝr—6•Ûš[¦ÊŠÿ™fõõ¢þï]žþYº‘þ/ÿ^éÿ®(Uïÿ¢Ã•þïCz×¯ô«7û?Õ›}õV[½Õ>ý_q3Ä>:kŽ/–Ác,âÿÓJù?KWˆ¢Úº¢Wüß*Ò²ÎÍ"Ë·;
€‰¼÷b¼üáÑ=|vÁÌCô5¹½"³'0èBï5`üj<»©jMÅ(0xs¸»8%¬³d;<sßG÷ 55kÜä„’`Ÿ2g52×wžþ©ùlÎOKÇRj5EÙfŸÆO×¶÷_oî¾aÖÖI‘Ò^¯þ,0Æ›«ày… ZSEmñjQë/Qü…H½xVc'Ð	@q0ŠŸ¡Šv8Ñ¨­(jýYR9Š†Iý«*÷z{R}-«Ï.dç'»ëÆŠŸ¨K;ðêiÇ1ÒWR·ž þ¨6ž`‡Ö8²³­+¸¨_ÿý¶V˜Œï
Å’iž)Žç—íéfÅ³Ù-–Æ+I^£XZLgVá8›ŸRð8Yéô)kNiœ1(¨*ÈÁ»½^Bx£<ç)ï^(8tª¥yXÏ½§ñ”¬S6'¼Z6WÕBL‘27/WUÄ™z#m®l~ÕÊf­;3OKâª¾öi½ü4kÿ3ÿêã¶mÜÄþGÕUnÿSùÿ\IªîÿD‡ÿ8÷•ýÏá*«»Ä‡z—øÇö%p+ûíÛÿ$n*ûŸû±ÿ©|JTwÊ‹Îƒ¯Í¬ViéiVþSN8m—9àûÿj›YüdAŒÿªW÷ÿ+I•ü':œ—ÿæl‚o@ø`lgƒ‡Ö8Éá”A¼oH¤ò®ò&•÷'òJQþiZò™`èÅÌ0A/;Iz	ÄTÖËiBçÄ½LúFŸèg&ò•· -h¡(÷Íü²uº‰èwu­œð'‡ªÈ±üÿæ<ÿ—¯, : g>º¥Ü×@ 0‚S	7Æ%‹V”ØŠ"[6Cj›;˜¹ýþæD·kÙÿ£UÄxÌ…ü¿"ÅÕTÆÿÛÿ¿’T™ü/2ùGäÈFÿÜ:²H¯?Ê^3ëÿt4ÅyÄÀl3†ò©õSÁ¬hÖ] 4„Ã>aL¹\Sð7ÓJg¢gÀ½SŒÝFãË¸9kž/†•Íú}fèï¸ÌþæVü£3þ9cHÈ72“œ‚Ë÷‡3Yj 1÷FÝÌ^“«­M€®€ú	Ûø	í§çÀ€q6úÃÐu†Ož$óã¹ä¯‡´‘hÍ„Ðý =ñpb.=uÎádÃñ<:Ž+wèã’Ü ›ÛÛf™þ˜ó‚‚DÍ‚È›!â.”ßY	(k0)Žú÷¦n<k°½âÓ!E¯ €öèW¾cøäur6¥l³àfHàÆ€j0Q#²¹µ·ÁŽsp¥e¾lS.uØˆèˆŠ€š€èñ$6`¥ü!¤¨ŽÜOÄnp¼ÁFý)¶}‹
Ý÷uµ©5Û†ÒTUÝ4­¦Ú4šmÅ|_†õŸ
ëHúq<`2ëÛBŽé_±ð(xœº#œ:1i¢Â{ù¾þ2ºá§§@á}é»?‚^ +llþØ:üÎ"Èm¿‰ðw¾™È³ú2ñ'CìL…?_Ò™_
¥ÐcÐ°ÌåÿKÃ»ßIXèÿËÐ2þßÆø/ªf[ÿ¿ŠTñÿ…Ïsÿ!K IàäkHç'ã‘gxÑ{dü2ß?—í¿6×¦¿âùWÏó¿vCòC	y=~ÕG˜Ï9’+W1]´³x¿ ¯ aè9C¼<å-lŽÆ›‘[ÛgKÉÞá6c î4&oé&
m³ÛºI›7CìË8>ñ‚8¢K7hl0:w†¿áˆ^C»£Øù\ÞNnÌÛÜI]}°^ðÆCÞµ\»"‹»m)@ñ”ºÜIÆ‹Ú€í ´ÆOÁGè/wîxì£…„p–º8ÞÂI¡ci~®oY.ïÞ!‡–öîUò=í 2®)P@ç‰ãÅÀÙB[Ñ˜zg¸Ñ8ùËsy<iq¾6œáøÔÙ0ÖGÓ3ÀoC_Ojjë³ßDô:¥Å¹ãGÂ8âŽ¸ ‘\=V#Åõ)]š„0r†\ð¸jRh™pz6öè¨Ÿ6^ +½÷iå÷ämR¢´~Š†SÙÎC**\ e@b4¼b=£õ>‰û¤÷ÃfCÍuöïÇp7|±6”¨ìs ˜Ø7ÓQ¼¡Ïâ!ö¬!¯80†‡rÙ3ØCÙ°útÃ¶møÅ+Û¤ŸÇ±Q#À"˜Î«P§ÐrcBÿ5…ód«éŽ‹lfx—n¾æ£TÂ#S·F¨#Vß«0êVuÿÈÂ×L:è"Ÿ'î<©ç(Òw–uó~hwGþà’~†IØÚð]è°O?v©Ñ eŽ%8L˜N¾òc
Ê7â‹1Ý€À‚Çó¾zGÈ5ÍûM]8ZáŒM`6?&^šÉk°ý9Ìïù ÷`ð„ƒl¿@°0ÀdNò££éB”ƒ{Çì7è‡¾n]Î3_6_4ñ6è¿ÿOrtðNZ‡q¹P¥Ÿ²ûàÇ'aŒR¨ßb&ËKkcÁýfÛ‰ÿw“ûÿR-]ÕªûŸU¤Jç3¹Ü œ ê{ÉÎ$9©{¥FÝ îd‚ÅkáQ«Rì¼a™ý‰äŒ¡Åeþ¨ÅÞ¸³`¤›Q‹¿4á÷›Ô’2þÀéÂ(xw€rÓª²k
V÷ßÜó” ·òêpÿø€åxáøxÁ‘X(2Î¥Š¸rJ?/Ø¯gƒo*Âì/Ž¶]›r>GÀuMåuíKí¶óä‹óQ ÆM‡»ýº·sä¤q
»
(daÔ øíÆSÈ|I7ý³¨‰4Ì£W‚i;G-ßm'ìÎ@öívëqÅ"ð`ÀèÿÜó‰gÌ‚ó_µU-=ÿ-Û†óß´M³:ÿW‘–F-Í¬¸€Š¸áü?p.`oÿÕ	*,ãœœ¸Ž÷q:f¤9—O?#>Ïæseâ™|::_@ÞQsS¢æŠòèùíöÿ\úË¿$³þ+F&ÿ©èÿÏ‚ ¢ÿ«H•üWQþŠò—wðMùy’õ¿ —Íú³´€þëŠÆü¿Zªª[†…÷†­Tþ¿V’¾5ªý-Ñí-ØQB—¼¬èô½ÒéeBâWY$˜‡„“|Ì@r2áó`¢¸Ä@Ã
Q;ä9ü‡†ÍìH@{Evh …¢t E§¤“—Ç{{¤q†Èÿpâ *4½Sò=8Â¾kßÿU­-uf|g 3yöné¬n~²ÙQÖµu}ÝX7×­ëÍÓî›­Ã×;oŽ6¿Îtqî`%S¤ilŠžÏÁ©àÄ,š‰¯}*UiU)ãÿ0˜ß§a$<ÿGÜQûRÚXÄÿY©üo–e ÿÕ®ÞW’îMþÀ °¯È“58¹AfÐþJ†r=ÏK'&vrÖÉ¿Òi*v“yFµ©™ÆãðO²dß{-<u£2k“˜ Ž. g^<L\tà0xƒl9ó
f1KGÀÍøŸCÚuÇúD´À;™§šƒ6[UèÖ“§¬§ÏšdÓÿ {i@­“þ$Ž;ÅO¡0·ù.±diÈ nÖçJ3{8Ê0ò/Õ¼‘ûMýxãÙe'­i4inKSüÛ*4 |¯0ø¼fI¥ËSÀ²ÂTE¬ŽÞ§ŽNÅ×oÅÕ5ÓzËPÉ™3š:Ã+G¬ÒbÐáøæÃ’•`€+QèÆ¬ýŠôã·Ú6åˆu18 §#»‚ñ¬½sFqÔÑøS8ùØä6•µÍ ¦“b&©ý*Höoµ£‹1íF 
´†ªºh+[{…;–ýöªÁ†Lw|wæa»¶ó™zÿf¿µŠ½£îúóG_k¼p8.)‹,-"Ž\ühpFÃiÜ£^WW”43ò‰¿?ÇÓ¸+ñ7/E!t?ùº3™„“âG³ !¿±™¢þ‹‹îÙt˜Nn25ˆ¨yþ_Pžx€«wuú"¥Eþ_4ÛÌø?ù?Ë6+ûÏ•¤êýGºGÌáþ½TÄ;Da› žƒ8{VäõÇ¾?]ÃT+Ê"²—1¤÷Ã¡8–lâ?Oÿ,'pkÊ¬Ä–|)™2¢™ðlpy[ÚØFŸÈE8¶ê‚0›ÀðŒf¡©ð²	õÿã&4,Ü	<Èw€A‹NÃéÐ'£0všŒ(ê/:“¨¯E0›¨©†v¾>:ÄÆ¯KÚÊqàœxÚŠN	í7a–I]ÊžŒ'!â`“·ytJóÈÆ™"ÐçD|ƒ¥ƒhAçœ;ƒ!kPjc8<ìRìô	óë¶·w²uÜ;Ú½ûËæÑîþ
x©ƒ0Š2Œˆ¡CnNXÁýÃÍ­½vi–È<¶#„ìg&Ž¬'[1ÂYjM¥åŒÇB'Ã·p’,“Á„q_	PêP
l{óhsÊd$ ³³žÞ4®ç_Ž£ZêõQêZêÊtnÿ’Î´r×™bÀ[?$ã– ŠãÅ0yAyU˜‹Ñ™\0?‰­³ïé'gBeÐ/_¿KÀß
4cmÞ?7ßnÊÍÁû ÈLNaÇ²¢É›p¶”hN6AMÔsÊHÖ¼6“k]fW„Z;œ=Úºòvâ°¸X¨ÀD°Ùà„dÓ (pf¸Œá¸ò´%àxx-•’þ½tƒ_]Sß=åùA€›“h¼Ä6ðÿŠªsþ_³ÝÒ-¦ÿkUüÿJÒ¯;o^í¾Ùù­vH£1œ”¿V¿åŽ“ºjSáÿÕ~}µófçpwë·Zogëøp÷èç“ã Õ;½“·»›'¯æÄ°w|€þ6º3\šþ`•î/•ÉÿKýYZ°ÿmSMã?¶¥°ýo(Õþ_Eªäÿ¼üÿEÿ­œö'£ÓÀ¹	Óœˆ½ÈÁjÇCyˆÉ5ÇÛé½pTz‰ „4ø_¡†øTã³úrK(n‡Ó˜½ÝfÎFç¢ûƒeÞà#ÓÝy[R#oÓe»ÙX{ÌkŸÌ·›‡Ý·ÎpJ—ØY¡ÞrÐS»kï§ÿxºñþS‹üZˆñYKJzþi¾frÓ—ì‹Ó-xiçÎÖ³®(€rŠ”=Ù{û[›{_®ÓÒÀ-6U 9ðŠ2ñ\Ž’Êž––•
çCÂ¬dèf].ôÈ)~j1“I8¼á{"¦õ <d'²fšÍ&q÷Íün¹d,±µÿæåu'„¯Ä«ëYº,ØÞ=L—7½=ø".¢V¥d ;?1os ð‚³ `l1É•NH4¦—@¼lŸ%ð¹Ày/•ÍeºQ7‘òÞlk^¹Q9%ÿ|qÙ]c¿6…‡e´¶TB(b‡;#Ñ"£èŽwÊn“’KæðB/›À“½ÝÞÑ—!~Xã7XýÉ [oi‡Š«¡~&nŸê5?Ñ¯„»~Íó‹‘cøÎ_K&…¤íœ}²¯u™
Ô¥¯MèÁl	ìW®n¡ÙR›+…;j¶äB©´Øà´lP…^†s¥ûD*í]]šoÂ¬<’Ü”±É>;îÜi/”Í’¦.%Aé¬õÇÝµ>YÄøt@ýð”çò«Ò¼K¾ÁTW<¥Ãq’Sµ·dhoÎîÂns†äwv&§…šÝ5üà“æsØ&^8']g‡ir0nú}ÂãIšñ¬2hÑP:ñä9t&Fï‚ðti™[RÂ‘NLì îó:V3•«‘A8ÈªÓ›U§øÖ-UŸÐñÍ HQR2(ÑÍ`p;ú&pŠ	ˆóAØ];ä	Fì¸éTÁŸÓ1G‹iŠÓbtæcwíŒ)5ð\8tÍÈ\,¥ŽET¡B N)&.47ÀL˜¡ÌI¨Ü“hzöu;ƒN®¦ggÎä"é–Á>•Â<|•¹ñ£I„½(‹¹“Õáþ¸ËÂé<I°¤5þäc|¾fü9–“óÿzÕpÖ–§ÂñÍ^Eî&Ê‚pÊyKlcÑý/äÎÜÿªFuÿ³Š4¡·ØÄ'°æÝÂ&ÇQ †,áIŸ«{‰‡‚¯Ýû*Ý5•ë1Áhi×Àö¿&ÅÿEÃOÔÿ×õjÿ¯$U÷¿Eý¯÷¿Åk`Þýê6øº(PÝ/ý6øZ·‹_ãöŒÇ$¦ ,àúáõYâàï&ÓcÏ°ÿ“#Ù@¨Ý«ŽùÌùb÷²Ï˜Eü¿ndþLSgþlµ:ÿW‘3’Ïv–à¡nävNb¾Æó÷¶7FAÆ<=Ëë¥™ÏdÎÓL“gJA’ÓOÖ†d(Æo£)”^'û»øc»·³C{¸›ïÚ¯=Ë7ÍìÿæÉöÎËÍã½£“•ñÿ†™Ùÿš6óÿ´ Úÿ«Hÿ/ñÿÜ üÿrvý E)áOiògåáÿxŒùÃNó¾ÒÌùŸ…=\šç¿ngñ?ÀûÛÒõêü_Eªüð£í¯<üïàä>@nè$Ì;2)z ‘OðÚ*¤3[âêc=…Çžnk÷ïô£l­ï×ïG9vÕîÁõÇ5Zºƒ÷kA¿¥¹°+~óÆ,ó"_çÜ÷‰¹íîì¼Ùî¤æÝ:Û`hÙúàT› ëœ¨–Öªç=‚äoI“»bî¤á#+ú¯é º%{™['«‚êø×ª4¡ç“êËs.òÀ¼‹Hþß©8œ _ÞÄŒ¥ð‹îT»hÿg«Jåÿ}%é1y²ëo'Ë£?<}s×Ai·‹—B¹ý°Ü+¡'{À!o± ˆ _…ã(À¼HŽ}”‹$x±K™T–ü±¥¼9cðF(A|‘»ø/rÓA±X·oÃ/ˆènÍ‡Eò½.,PÜGL_‡?ÂI¿æ{$Í¬I!¾'}g”ø«È}c‹CôF]v"Gëe°=(Á?ÏV/´ä·ÂQ¤hgÿ\Èüó mâW¥*U©JUªR•ªT¥*U©JUªR•ªT¥*ýÁÓÿø¶X ˜ 