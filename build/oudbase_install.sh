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
‹ ØtŒZ í½klcIÖ&Î¾ºÙñ÷õn¾ìëÛñWCiVR¯ø%Íh†½ÃÙ=šÑË¢º{f»{¹—äy§É{¹÷^J­éÖúCb q?ş8±m “ü‰óú“‰ƒ 	,8@ØÎ¿6ä‡“sêqoÕ}”DIİ3¬™É{«NU:uêÔ©Sç43;sÉ)—Ë­­¬ú¹Ê>s…"ûä‰ä—ÅåÜêÊJ¾HrùüÊja†¬\vÃ0W³¡)¥ÍÙ‡¼çığ>ßÔ€ñ·­:tÏ8§s	uÿBÇ?_XY^ÎW`ü‹Ëùµ’»„¶„Ò×|ügßÉ"	44§“œ%éÉ%€6·ÙZ's{`GZËpHùÁ¹7pSwRÑô®Õïé¦K~Jjƒ~ß²]²p¯R[„25Moë¶n8®­9N
ï/‘÷ò+ò «¹nÃ´ÛK¤vl¸_êvW3[oôÖÓ3,­eÂÁËòÀíX6YsõCÍ$»zÇîdÁÒEâĞg‹>ûÈåÈ4­”®¶×+=·¥9îFG3ÛzëŞ	CEsıºåø‚eÙ×Ç°ÌPñ‚eÛØ}ËÑ¤{@3¤Ö´¾K\‹´uøèèÄ0¡kfS'¬‡Dsˆ­»“4­–˜°\İ­9èÀ8:|ëi†Ù=!Go‘CË&ºydØ–I§c\rğ¨’†ªám÷!+Ô†À:®ÛwÖ³Ù6ä4;Y†1Y¸>ñaôª,ûd~æò™Üû™B.¿JBÈ¦i¸†Ö%Gºh„<ùB&ŸÇ<k"O¹õp!Ä!£ß0³eë):š¹„É™&P©Õ3¾Ô\hØE 'õt²í>¬Ô÷wwê•ÒÜKé×z:dã¶qêe,»:¥¨š-ìãÅÛ‘¤à*0G]—<Òºİ¹@‡’ªûµÍİŒf²²[ŞÛ«îTJ©ƒı‡Õ3Ííj®NºV›ğEë÷u`, ûŞn­ZJİ/oÕÎh£Sôp6Õ6ö7÷ê;åíjin)Ü>Cær‹Éƒí½zes¿ºq°»ÿy)•u{ı}xsjŸ{©d8ÍªÅ3ss©dí ¼Pÿ¸Z®T÷K)úÙ“CÃ6÷Rªı”,<bÏ9úNéœ%swRÉíòæV¹RÙ¯Öj% é,[ƒ	™iv’ÕııİıR.)SÄÅG’»?0›HT!n²³ï·‹<t´¶¾°H^ykÅpú]í„e˜píHNR¢¦*Ö¶Ó&©Íû»dU¼ä'éÎ‘MÒùg÷æĞÄÎFõ.IWÈ‡ F´*;ğıö}fû±e·îñß%Ï¢*!$İ‰"vZ9YpqqèÁâ¿bŠE˜)1Åí¨âÍŞ|N—[ïw&åK1 ¤~ûIï’ï:iš¥ŠaëM\$È¶fBoìp‘¨»OHŸ?¢¼$¦thX0ÁX„Ø’UnËjSöüË­İÈNY>ã<‡ùS’n»$G}€ë»™İÜèêšY6[b`¸,ßÜËÂ)}­wa­ù/º|Ğç‡Fò49ñµ.rjm3Âb<Ê5zT`éõ/kªS¬/,&_Ò~nîì=<€E2ÿîúÓ("¤	d]í¹N@²µO`2˜mÒĞá£ÅpÛ~(§ NAìŠ† Ä2Ñˆi€Læ÷“80ß%‹›7&)øAR‹„lnWë@GÛ{°°´@,!©Ÿ½ûyúİ^úİVıİ×ßİ^·–Züà©èş~|QsDaºº@ésÔ»û)ÖªÔ›JÉî°÷J†LD…tGkú3 E4¤àÓ).'ƒÈ*Ä…ayiÍ…ùı6à$J‘W®®“´&ÍG¯¤2¯†ƒñ²Á”_qèz¿;8ïi«±Úw ½´­-K©â¬=ó›x8²w‘=NÉ*õ4ÜÛ–eêaŞ4Áa»{7ªO¯ö£9>ò.ƒ?{,R^P("AÖM3AØ p/`Œ/÷„£Q_„ğÄ±ÇYrÙ±—=·è­¹È]a¥IÏ2»ÊKÙ£Bö*t“l€CAgÈcØ·‰Ö³&•Ä5»=À-²“!5˜\º¬!{oZ6ÊF/#WQ·
˜,àÒ¾8.ü•‘ğe©„Š@b é›–KÕÁåŒn!Ê÷N	T?öË[UOº©ß+×ˆD¬•£õ8ºK+µ#Íè¢ô¨ô'ŸyÃt[‚kš¶ãÃ~)h?˜®¥µÈÓ¹—ïyd3¢‘2¸å‘ı­Y°ÚWÙæü:¦·äòÅ‘å«¶Âæ´¨¡ÙVœ®=0M”_¸N¨iõzš©‚+œ\Ë‘DôH¨Ë£ nC%«°”-Sô8´ hÄo¨j*0M±Ä¡?]÷Úà„no`£Ì§ˆ7%b[Ÿ0Ñö%â´tE©ZG·G2ŞQÅ3?³âYø•…ü­¨‡LÜ0ákm²¤ö¿ÿşb`§ò	*É5ÓÔˆò{Gëv-ešş|$Ûyh>7­c“u=FŞKcf¡(91µMûzÏ:±ZGšÍy¯¨/œØ=dán¶¥eÍA·+/Èøh;“\=¶{2¦ášÈ‹ëû £s‘2†ÊÅ•}’¢‹ÈÆDUla?ÄlANÂ|&*WX¤S¶•…¼·¯<4Izm‡Š½æÓ'¾¹äÕ+xóI·¯å*µæsPÖµ…HÁé$)²“2·pˆÜÆ_zÒTïæ){ƒ³Ô€pv$ßÏñm{’Ër¨Ğƒ¯bÒIº<UƒÀ30ÿRI¶NùÂ B•Lú9Ì…_£üC~úS¦c’’tJ÷ZÒ¤7"*^òr…ÒŞ´I;*Î1Ä1êŸÉ2pÛšq!·Dı®­õIJéX1—Â½t2É¹`]Ò'`…†t*æj74 U™Tî¦¤8^˜ì…ó­­»VÈV-ß·-œ~¸ ñÕ°‹îk6ƒ‹z'¶ïà¥IçÈX¯¬±^]·QÚó¶L…'² tÉ4s9‰é-äaé±H¶OdBF2İİÔ<PÖª
æcz´˜_ˆ²j,&¯½Hö«{[›åTâ‡ZU]T©2ÊÏEgdî¼PĞ½Ç-Ôş!Ïñ¸ 
S›,J£òº›Ì(ÌÖÌ¦ÖÍòÓzÆ%RdNÍ¹¹K¼™³ú§ù$fbzö¹ŸC]*TAXˆm«ÇY'Ó—^ş¨‚»Bæ¡&záÂbütÈL9 ĞcŞ!ìÇoÍ0şã-Ç: ëó©/é‘,¢€}]O§"µ½§ÉêÅä‡ `îåŞã
ïÈ)CÓ;|‰ç¶
—ÃƒÃWÁ€30…`\6 ı	<És¦ÓìØ6}h:ĞÓ	<1­40 ^ß¥ß÷l«¯Û®¡;ØRxÄpäw¤²Ígå>‘ÈBF×	°D}W%ª±(»Åš~v*/æ•ìœF4~lë‘ >Î¬µà,9;ÇC?<ÏNdŞÉşr.›ÎÎËt¥¾°`qº§5ŸC^²Ya*éŞ ë}<ADDv×Ö€\aàê/\£ç²/w>p²OÍ,É~pØ9 ~(à_ò\ëÀÈª%@O{lR&;¶˜å‡+5İ>‚]^M“…6ì+ 5M2ÊÂõ–R÷¢` ÒØÁ¶D©;¬ôRyX.(nñn
&Ğô7d¾!ÓPıÄ6bIÜÊ¸‘Úª”÷èŸš·ª˜al%ÜÜKƒïÊ?­ïâÙÀ‚vüœÌß«>ØÜy¹_+¥šé§°CºO¿¦>Ø|°³»_İ€Å¡”ÿ€mhJ+x“'¿!Ù_–[-Æ ‹|u®€~8µÌ?½›%/¡SsËìq•u/r8¹È)¼¤[úLq²HÛªÌ:OœWgŒÎJ>$Ë¢ğ0å)–„8¯.ÃÒ‚§!5J©ıáçyÓÑ™ØèP! ÿH³ª€IC'ãË0c$5‚1"8ûUÏøëB‹,;r¢ú²¹½]àË•íÍyé‰]Å´VÏ0ÇXÆÂkWäXÅ®aJ—â†5Rm}Q-Ô….ã¡å>€_ISçÃzêN¸§$«Ø
Z_#ïüh}A]œ‚ÖW
‘Ä~6/?º^)(¤‹ıS¦½ıè$öéë¶øT“°ÿe&\×bÿ»\ÌQû_ø¶¶RÈå¨ıo.?µÿ½Š4µÿ½&û_oÂ}Uì¹¨‹¤8‘—hç«núû^ş¿$Óßür° aº¶Õ€è{7O½‡€œ¾Ş4O|;l@Â¤OÉ'k>üÕ6¨%ğ™Í€¯Ô†÷kdÂ{…öºÖÂH
0á™ŠÖî’t|(0<ßd÷"öºãë†Û¼œ‰M>)qbJ‡ºç•ŞÖŒ.á;òèâSÙ+µ‘%SÙ©,™ÚÈNmd§6²œE^½!ì«\ç±ßÔBvü©­êmU'dÇyV…S»¾¯˜]d­î<*´â‹7 dõ¨mjÚwª°q <»ÛıæÉ¥™èõÖõ*5Ó»
½ZŒY]2J ¹!ç‰¼¯PuëdŸ.eŸ’l{ñÒìû&b¿÷•7ñâl/0¶¬š3©®¤Kñtöq «5"õ"‚%Œ´
T68cĞ¼6oÄfIÓÖq7«©gû¨§Ñ	²=zçAj[]…ï‰ƒò½R¸¢ˆŒõ­Í^3‹£#2ÿËÙyÿÊÑ«æÀ…–çaqX_¯EËû;h7¢JBØxŠŠ¼§}sd†DéZX[Z)”O³wğÚ„_j`rkQ¿#ş^JØ"Å]È °B[¨1q¯¼Ã“ˆŠÚçsehû–¹ó4ûtş.>ÅVdîÌeŸæ³ó‹~×äM”‡ñ°‰´r¶Áğ,ñÒ§ë£#k^‚šÁ%Ãí÷\`ÑºMæ—æ	ü·ÈÙ¾Ín‚˜ú1eç† Hà¾İ}|Já>59`µßlÅtuAÈâ¦7çBĞRì
‚Õ'šÒ©§qXÏ!±¸wÛN*cÁödNzæsĞ9ã]y’¶‰}sõCòŠèbº¥Ø£Wô7 ”Ğ/–İÎXx8âdjÿ—”ñ¸-3
d…ÒM©ŞEuJ‚3,¢õªıiĞ_"5°›º,³e|•øU¤t'^«R_÷BS¯å­)şšû’t_µ|F’*›ûª^BiV|ÑCSƒY™²ûWŞ»TÊ¬’[a/üaİqmbvpš¥En>>N@{ß²\ÆM[ëÈQ—
Hä sÏ?y²ŞèjæóõgÏæC‰ógŠZí©sQU™Í.Èà÷lÙN	m³”'dˆ&ËÌgŸ¦–¦²!Ùù¶Ÿ#¿U-›F ´3ïŒÜës/Å`œÖ½¦2^?¼=Õ“¸ƒOsÜfÅïu@/ÈIkcw{»Œ²>ßmîœfÄt·“9îXK;Ao$à¯±,æÆ2ğj&ÚfÉ¸Ç|Ø(0-xcc°Y¯h'\c>ÿ³wó°_HãârI†^£©ŸBÌŞ/8Ó0…,Ùüi(Ì Ù°2kÀ°ösÎƒ@7(áƒ¨@÷¸Ä!w¯:.ápõ;Òù¥\ßæ.ª“Ùª¨xÕ /HÚ¡Z•İıõª'ÅŞ=M!áø[0äHâ˜\X _~–_TùC¤ú<~ØÇÇ‹3hâÎî¶Ù' À˜†ÓÑ[Aõ»?ğŠ¶ı+VË:6—@üİ?6`Ö5`G©Ûx³VoeR²D²š‹#•D¼“ §é!ik SK:æ¬c.>Os9yû\Útn*ĞëÆ”¢ éc$`‰)«&³áÍì1¯:	ûO$âAÿZì?W–W–=ûÏüòÚŠ+SûÏ«HSûÏk²ÿô&ÜWÅş“uèëkÿ¹šÿGØ¾ŸÉ­)y¶µ/ğ”âÚA,rYWœ"4-óê’áwæCÏ³}>5(ƒöf”æ2ù7Ö»ì•š•|¾‡=z¸µ5v‡X§Ä˜İc¬éà¤¯'?­V÷JÅ³ÀáÀv½LèŞc]N'ës]ï'×ôÑt°”J§Å÷1ÚÉ®üûEÈı®ÖZĞ¾É´.ùIõ«oKëuÔKÒ#8QÑZesgc¿º]İ9(oMmrÏAµ¯•MîÔoíÔ&—Ö1µÉÚäNmrÓ¯“MîX&¹S£Ü©QîùŒr¹l6ÊÓ75¦Ó¾QÆ´“ö“ùÒºëÆzo½zf´.l¨š*Òõ*Œl'éÖrj5Î8µZ¾ÁV£üxnL«Qæï_rQq.–~dslÙ—|ªÀb]àê¬uQ+.ı”V<%“ğo¬Ö‹«9¨Çt-²‚#r¬ëÏ‰IUñÉêãúãjõÓ]Içò0µ˜Üİªø/`àg<MÏ½Ä€ÓÅEZü^yãÓ‡{õZ(UZ‡J¡QJ‘wq+A¢9V1¬°ß„ˆÂêUB}ÆA¢U¡9ü_ñéh`x4«âÀnó“UYn!…¬vij=L.jÇ©o¾¶–ÈàBÉ8ŞÌÎ::òéË]T[eNIÔ(3Dµc …Y³J\Ëo7şzš>^xEQ¶¬Õã‰“7nb*˜Ñ)îaÆèÃ8#;÷Rm‹T(ôjLsQÙT”Dß®£ëáË<4Úş0Ñb f ¤ßn’Şû²y8²².ƒ™qÛ_²mŞÆîÎ}r7®×#º&œä‹pç}Dç0¦	íÚSE¸¡…®eµ&s‰ìıFw¡ÒÏAõâ'wúKöiê=äÍd‚ÏúF+ÏQXæÇ[‹ãñ­ã-ïENê3ePÌk9·AñhcâÎ?ô"»<†½p@Ü.\Cå45(A—t>Ló±º-´×Ñ#(kĞe>ÂR<†¹ÿQöã]ä¡p ²ô1N]B¬Sd’°¹İ#i;zf >™‰ïÆ%wáĞ€¬¿ ·3a)¢Ñ‹±;"ÆÏ„L½yó¦¦ŞgH×mjûZ&4şÍÔ=5ë¥Ô1Üş;—+æVÑş»¸œ[+,çŠ$—_^]úÿ½šô­ïgæ­™™m­Ivkä3ÁšğÙÌMøW€¿…ğ;ñíñ@–öÙ7Zâÿ‚ßdù~{fæÇ ‡g´~¿«gºšã¢0îåg÷jÆ7ñÏÌÌÇ|=­iã
¨ã¯ËÜôï£ñ,Ïû-–÷'¼hÃÜèê›fK13óéüsÿ…öÏ?óWBh¯gR"
]RÃçÿÊj®šÿÅÂôşÇ•¤éıë¹ÿáYâ¿Éw?˜rŠŞÄÅ{ºxäßÜ†Ş¹Œ[ ¹ğ-ì.û²Ÿz(„°x\€ïâ¦Á1pX\¦¡9[Vó¹nGŞA mİ­#T‡6‡«	ÙùŒ•kŸLÁÜ Ş'‚Gšm yÍùâZM§áŒ©mı³­RÚ‘W	ÚjX.9Ñ½È2á.r=ÃÇ»ô€G\¯_ä§!Áf²Ë&ÎºßÇ¼N²R½_~¸…ñX*ì>=¶c77RTÕ”Ròğ]¬”‰m(Õ\Ê Ï'ÕJYkÛõÊ.ìí”z[Îf5c}kw£¼%ç¢nü<{û»•‡r>½—äJpØ%Z¹ğ,‡½ã|!SÈä3Ë™\(ãıíÇC23Uä~•ê#7”RlÒÕéÙÎ°”<$5QC'=+y¨ø‹ºzòmaN“Òi2EDI~Ÿ{9Sì<FğX<ÆFã„ÆßĞfæARö
ÏÊOR°§YİmRxŒ…S*-²¾“¦¸4eĞ(Cy„&";K˜˜ºdFfWÏü°ùT¥iÒ£cÿXD`[ É(DVòO¼¶}ì#Â}ğ=Ãi2¸CL	š?o8Lÿ7ì`]§À|³4ÓJŠæj$Üà V&g ¨èhàá©­bK{ £æOAŸäñWh¤ŠCs[iU`RËİU§±_¡xrÑJ!UüIùQYTé}?ce_hGC-Î]ÿD©‹r•ÍıêÆÁîşçufDD7x#ï 2åmN4ì‰Ğ Md´¤ë»XµıƒƒÏÑ
ï=;£,Ñ:P{“›ŞU<ı…ŞĞfd9/ó
î>Üß¨VPsÏ¿Rİıkn—ÉŒG¸&5`!SşÒ­6•6EY@?1fí³uw`›$Œ¬ëM(”û¹påµÔ{Q™µˆk­8R«šöÈÏ\İîaDóÏPº'bB^'{åƒÑ`éĞ°W¢-C°vØ:B7\C–“Ö)Iwõ€5£Ï«kåGÕJãÇ©dã…¬ós…O_8,BÍì, àá&R6¬óêªw¸@	4›d¶YtğiD^@‘L¤E$ÕAaN«ÊP¿œI³……ÑàØâ5ËƒÀ„Qß˜ô¸Ohy“Mİ”Õû”„ÖçS±®âCÏ6HæÄÍ‹d	aœúşF¹M_Yù	;•ç¡5"~§©€æ,“wvË~ÛqXLŸm…ÔJ%7ù‘÷öh^Ÿ£¾¥!t)l:ø°aÄcê] qNËÈ(QÏŸ|Á®c‹Æk|Ö¡‹æsÏ¹E,Ë
(JW'Ò‰.¬TÎ!	f$ªŒŒ/ëO(fâ)·™Ì¡d|)àÅåHÖ ‹ˆ±BN%'k3ÏÉ(L›\©Ür5`X{v£ÚÚÉòZ©ÁŸ¿×’áhsEğy @÷Ä'‚TÈˆ1¼Z³\½,¾à+ö Š¹ª÷Jåu:dÉKï0hæ‰
C0Šèh5âMEq-é"6¼Q¦»A µå•(ƒ+b¸œÀdiN&wlåfÄ/ÑNˆRï”LA"	FŞmŠxÖ¸JUiSk\Şo"O„c¨/Â<@wg¦¹8z;;­—Î&Mc”¾.ÍøZ–À4ÇUGğŒ«xcÅÑß,¤ò(nK1¿UÆFFS·Bcµ.kàYÀÊ.ÆÙ]æÕş˜ÒÉj¢[u„oXT˜!¥oÇ¿ ãa"ÕıˆÆé^ Û6 g;êT Z•eˆyŠŸK¸›õºzrñ®%£²ş2xbDİRµ¸Ù‚)æŒ2®3á†y\?¨49¥›JäQ!Ãxğ¯g-ÄZŸÏËÖçóğFµÓdé,é±åÑJ]z²­zT1*ÃQF5?èÏÀÎØo4ƒ'‡†´Ú
I0ÀÅ™¢eÙ6…Pw¹ÑÆ›ûu9ë¹$ä„L$¥Œ?ÿ¹j.'‹¶`´ĞÃEĞbÈ;‹J¥ØF™Â5rvX	Ù;º"I.„ekÍ®^§šÎh@,Ó…zà(ãìv3}Íí¨@Ù"{1ÒŠ‰>oÅƒdöf=dÎ[èclúÂœüÅPi6æ$c—uB RÅ¾ºvH½5ÆxVu8ûV¥¼Gö“©
ô¥™µ¦æåYëµÚV({™ZYGf§ÿP}É´šö«{Áì“ãËğL¡0äA?ÌŒe>Ì6ÈÌ|›ëß»vÌ‡<˜İ®AÒ“&?AT×|:@ú’EW
HiI‡Ÿ…~F¥”*ÈÆŞ`bŒ€o=­)İ#Dàåñ©*~ß+ãSÍÃ«2—t^ò;_\TÀPA„“ãüÀ–}`ÁÃˆó‚\y¶ó…¯Ğ `éŒ¤ı*ú¶aº‡dşİôŠCŞMçøw•~-â_å÷°ŒÀõCœm–[¾°³Ş8!YÈ„X>åŸˆmï;¥ˆÓÅTÌNiÎ¶%>§.‘)øÂ`ÎĞæ»!y´÷í9Ã˜¸%aö<|Ï£Úsw w»bº}	ÍóÕmÚ (³œKÚã—u/$ë]LÒ;—œw)/âxÉÌjòÚ£†,…–8ĞÓ·Ø)‚$
øâ‘^‰Št¥9ÿ²“zíĞ”ôÅ^Yº‹vXE%C¹ë.îN$QÅ^¿QÎİZ†Íï¡Ê…Çˆv *4“ëÖØÙğÍ½®*)Øü‚¨d¸İªò
Å^‚‰qwùíÛ2`PÉ–P‚‰<yTãcŞ€KöüıĞ˜—ÉZoÆ”ÆYgØ¨w¹6™cP"G4¼iŒÚ0bR=T:¦M2Ÿ¥›ºß FÆÌM›eš”ıg—²¿œËöçE<ù¨å¤›‡í4*lu“†ÑáBê1NÔª“W‚õ}LonN²6.8*5Ö.¹JØh…:)ïË&‰Õ3r$Y26G:±6›kÑzŒYÁ“p†Ò/¾ı)á;aƒUzK–Ú:ÅjÈT@"RIiºIœ¥ü<'äÉ/¿÷~tF˜‹yW—WcòÒ‘|)¾BŞ÷ŞWàŸó^Œ'¥¢xyPÃ2D½"•
ê.BŠ‹@^Yy©¹òµ1ª©DP}©»˜<¯buôñVXïÃC+{Mç#I_ÿæ¯Æ\§Ò¹Fœ¾‡EÃØ6ß8Ç¡­Ã"uG—WOôåDY«ARÙ@ÁlóéÓÀ£uJ?ë®K¸îÑÖúœŠ–”Ü·q¥Q­Õ
m‚\+êä\-7¡ß½×æğ-nJè—¨²ëèİ¥r‚B³ÃhÙéË„/'>°&9´TR(7|°ÕG»Óáƒ!ñaí`w­zÑ/²Pú<ûßS¿J~!õy g$¥’d\tñìÔ"*";>dWTJRvåùÊø––j³¼çüÂ2.Øñ<]¾Z!g—G—æÛÁâyzŠÍ‡Ë)])©{·`M‹QJHÏ‡
‰ìTpU.¢‰ÈÚ‚²ÄµYy ÎPVö<ª °Í(Øø<*;ğŞÈìğ\É.só¤Ü5@>?ğ[œtĞçµÓ¸ÊÙ­Ñ®×;q:üº\(B[ê…` GÖŞ±IPUª–¥Œš¨eå»fô½TuÇ/Şîûè{ › &NH5â­Ÿp­m«£“/GæŞYÑ›GÀ1`[eÈ¢-]lü"óÜJwä°oGóz3‹ï6ÙIµÙ¡^Âø~HÃJ%Õ¨Èä‰o MÑB ³Ñ¼wyöŒ$¯òÖfÙs¼JóSÃ"h·-r2wKó)øïUj1s‡ZO‰½è…X³cîÕƒ²`ç²OÙù(/ù7Ø>¡âÖß=ñSñwÓù?ÇHEh‹ç^ÒNO00¥<ğ§ŠGx<`Í¡T œX\ªø/ÎZÂ'ŸÀ¢Ù6Ì-½K}¸]Æ¹%»\·y-Cò©Xœ„z\bçmàhf«×ƒ°é;BçÇƒGmîç™†¾.xÛ;ÜŠºÍ†IIï´¤Šİå+*¥Ó
\#`I§‚7:tÛûé]<‘èZiN ¹ã5(PhBMÚ°z=ËÜfVšS»<K¥|Ó:¦ùöuÖÇ4Ò.1Ì'Qıšó¡ó>FõıÙ³À‘·i‘æ6;K¤§k&rVÍ…™-ƒnµ›(Ø¹âæ¬ Áh[™Iı3[§1¥ÂËó‘’7üÇ’áÒ,]¿¡6Ën±–ëğ¿É\F.±AzÈ2Ÿv†ÙV6á°Ğ}IæJi÷C[pnÙ)´…õ3e9°f„]&ğë•úDÇ#›
×?Ë”{Àuè}mÛ$/À¸xès;>úD;x#²COrpj· M@4€à0t—Ùe²ÓoP–xô‘9pÙaÓ2ÓRšã¾ekv‹ÙpÊíÀÃ&8®'¹İ.‡~ l‡Ï>>¦4>Ô»>{&UF\ rfq$êC
	5³®­§‹î.¨¹°Ö×óR²WR¾@º¸” “óÙ/YÇcŞZ7ûØŠôëî «XÅ2X‚¸Ãïõˆ»#Wt1#lS?V$í8_ğ»Üi½v°?E‹ÒaÛ²¨€İx)Wr*ÂäC?#
D[öŒ(´($N¯F˜#ñ“™…V†X(:q« (ƒvq…<Â'Â $Š8ZÙUï†`ÈkaÀ¼BQË/¸ÂØ+5Ä UXîKÍôšÈã¶
é$5§MG›+¤ƒğpäãN‚âOâÎƒ‚ÏÕ±“Ø³t'yø0e#Õï³ÊÕ¼°.ÆãHw»®h<²à‰~k¼V{¼,r'MY¡³@¤‘u !=³–[—¬åÖk¹u_³„ßƒó}s¶ªòˆ£Ògµ¶~dÀ"Aûà[KAÏèÖš;?EqızŠ~Y!Pµäı4Îİ0ˆ:”éµ|å^ ñ«ô•FPAŠÄ»:2b(!!Œğy‘ö.cM`R¾>3ëÚ'ÆyõµĞìe‘)nW`¶ïWË^¤B4ÍIóÛƒ=*s îsoq<L Œ§¤Dx.x-*ˆJé]àtZ2F¡,ëÀùÊb ‰PAq‰qlÔ„o¤g£-t»ccŠÑÑDÕK)ê«~t3•úÇºÃ_:oíA®K…îß±‰¾œs.ÌŒs‡œ3×;î£œQaÏÆªzOÁ­#:WIÅê#ä¤EøËhæz¬İ")5z]vÃß¯1ÃÛSÛ¾h‹&×šJ­ä—ŸCƒHNídÏ!ÔÍ
·êÄØ¼nSrˆİ0\ÙURĞÕi¨;9mŒÜ– Ã–‹´& kT£‚Ù=§G¨õBÏ­¬‘;8<ô}²P?,ñØä_£ıf¢ ¢±CÀXw(#PÎ']¼v€À›[ùÉÒø#ÎÈf©gaÂWü‡\¶mÃx›]¬ß‚åiuwìfÄÈÃY(ÀYûšã£ÎÒ ?ë3YvØ£TPï·2î7’Ë<®° ]c”]è,,2c8ãC_u§jğW4b¥n"]P²­…bz±¸0!>¶†ódwYŠ“×í•|š®*ñk—ZÇ¨øè/?¿\ÈåÅµ\>OàK¡¸<CV.µU<}Íıÿ7uO ›ÔÛ%Õqöñ_.NÇÿjRËj^îäŸ{üYüåŒ~e%?ÿ«H8şûÕre»šéµ.©ÀÇj±7şËkkrü':şË¹â4şË•¤Yªı¥A¹½¸*TåKDPbçá6ªæÑßÿSîú@(mivËøR\P3zı.š‘PëKÏÖ†úgö…\¿€«£Ğ•;ulG7Š}ÿÖ»<O0‹ÓÔúº“!å.Æıhw¿<œÖ¡6Pë¢Õè‰ş»‡•ìn*v·Î7şE«è–Ô5zĞ~Çp´!ğş˜¾?±ÄÔÑsqzh¬B{Ü…Ü-O‘ãY IÃ–KÍ…i¿ 7jk1â±†¡–6]ıß°ÑÔØµ¨3CÓ€MÀ¡²¾­+h¬4*x¦¶OåÚöÙ/o,ÑL0`vÏ²ÅNÿ¸c4©Õš—‡MİÖºtÇB†Íöc]]êD&™¼#ˆæ‡0oÊìŠ
Ó;^Œ›;w8Z–˜ûW&qøYy„RiÌ&µ^äš@VGv\ì¸ö ‰8 (Şj†©¡gß%û44ID-iÆè]ÍF2>F£1x4 ‘áƒT„£àù$¼_ÎMšùØ6\W7± †LbFäì3²QÙ2ÌÁòhûïÿá_†Va+4ª
6ÊÕSg4ûšÓoè6tlÏÀ¬lÜèSC3É'ºãœdk®­»Í­ßéPMõ¤kL:<æ	óNÍš#Ç‰†]÷,úáòüs£3¾ƒò>ÛŠã©‘Ãâúpo>êÈ~X`X3ä1NÀDÔ[Z‘hú`®÷Y´6^ĞĞ_ıêW4 ;tûÀ­ÿ&Kà·Ùrôg$;Èå³Næj+®Œ¤;IT“ÎçÓùåz¾¸^xo}å=êfÿ £*¡Ë:$EqF’ËäY3ã ñ0Ü
28´†cÌN—¼+üĞÑÚúRTC¤;GÏàoƒ|(]x¹ûŒ…G „á•PÎäî"´÷Æ7ğß#T1$ùº¾ûlhE#Z‘ö¯„í3Yp1ÒSİë·õÅQàâÁé&¥]`D¦nÏjé£ p*C“/yv‹²Ke:šİĞùÄBU©jT’T¼ŒëÀ|cƒ uû§u#úb‰‘t„˜Ô‘qsÜóÑ¿˜UE‹UÎ`£ª ¤¢«ğ‘¹ÈñåwÛmèÁ¡ïH4&’
L…nÆquÇà½xE€Ç¶ò¹°3
e†ß ÀGÇ=Õ§¾¸‰É^U¤#¾X¼ïÅÔ¨#æåˆYà&'ªNöjt¥Q´Ärµ1•ú·¨"ªõ^œåQÜiDoùbMtÙÑjuuõ‘u_¦ÏÏA·¬6]'×IÖíõCkÆ?€E2™Ü”—fı…FE30>¹k—;P±‹=ş>¾‘ùgÊ¥wîpÆD'›i'\š“Ù|Ü0J·¢KßÁ•ûYâó ÌÛsduµ.âÚnŠK€Ó`öî,¹ÅcsxÖ8Ã—"å;”2$JšĞÍö:4$—é#Ësñ‚µDL~Œ”0p	À@fzÔ¢°p°ßKç
éüj=Ÿ[_)®çVÎ&ä3¹LNH$©ıòKláŠŠ¹#Zâ!­	©F´kã/ïØ‡z_”Hz(¤¨ûÁ¤ÄÁpb…”ÓÙ@D]jf ò4LÉ°²Q÷ºÃÕgé]3Ïd°¸†Œ*ë-ãá²#Ë…nó:}¯¡£ øë©ÚjºF1~ÇVJ3<ñ(]±øçÇ¥Ş†•UbX¹Ó>ÀQ·÷)`Ç¦AÊ²_´ç3ïerõüja(¤ÚÆşæŞAışŸØ	@ÊC‡‚äëu'–­lh1SÇSXH~ˆï@†
:Ëç`ıKxcÍîèR£¦bT©078GÅ£gSt¹1æQtÁñÀÈş3ûîÑ62+¶y®Ú†×Îr/B \°oG;N~AÏ
†•?Ï"hÂ XÅËiMŠ FÊ‰œ|0Æw’ÇzçV8%Åf÷ ?aT =á«ùyqR97Lâ)BR9JHbh(ú'NUzü-ÛÓˆÇ4û@P²k4²I˜•Ù¤‘JúŠ^Úäß´EşÏ&0˜LK~’A±±ôG]şI€¬¶m¹H»¥@JxÂ>X\ÜLÿ$t(Üõ!¶ø¸ë Ó+§GıÊM=ğ^0XÛéŞ  […ÍC3øXÌÖ°q˜§o@6Ã¥şî†Râ¾Î„t?«·ÆŸ‘5Qœ¥â<õ´gëJŒ´X!)L`ÃªÃI¨M	½€¬lñ¼ ¨P²hêù IÂîÙ r'„ Ø´.ÑZT'O}*ôíÅ 3Y³¬¾ƒÑ¾‰ê¸‰ÅØ7Âf\tÍ€Áàâjzy@\MD¢c‡Iæl•R"uaDç¬ÂMSª±âÇëüP‡/¿^ß¹Ç<FŞH±¹†×^ÄDóŞ…ÛÓëÄÁ³ +tåFïí£ãCªîTĞ6=r_Ì´xd™İAÜ«÷‰vèêŞ.IP=í ÍñÏ¥Ô9%ñ•	®w2äÌ«ÆÅ–|æ²lT‰¡ã÷†^tÈO½ÊSÌªrGVP\tš$É˜±hù]›1ÒN($íØ“gFÍócÈ¦©ÛœGÌ’QÅéÌÎ¢ßXIe„¸.ÛÍáêôL1™¼wâé5îˆ#-Tváiø±e?gje¼%+¨˜æŠ+Æ¼Õ3 ¢4À¶‡é¸d-Z6=Å(‡ütĞî›Í#İt¸5ªe`–r·.4Ü]ãyäIêüêª*ÊÚºNbú@x'ˆ‘jqhÆ¼Cšö O,1çx
.ÃÂ>²ÓaÑB¦ÌË]/V.öİËltÙá2ğˆ#ãˆª%•Ÿ§Òp!qd"Ö…)n27°r6;Js‘¡-	î·óupTuhX3DqÂÎzÔCîSæ€Ÿ=3M±b.!/…¡áÉ$“¯(H¯HEg¬óâÈa™K^Ÿ`FŸ}Ëéù=†åGø"Ö,6s bŸİı„q›Í.L‡;#†-SÂºJı"´Ø×ş4æ…7+3´C|Ûè¹ÕSm)ŸL¢A¨ŞVÆÔwàÆÏyÄ¦nyññ?’aßÑ'µ
aÎc|³ºıábUDÊ¬²¥!8ÂøFs€‹ç x
/–ªÑå~œıã¬Ö m>e¨°9@N9ÑÅ…¦Ú› EvİÑÌ¶ŞÊ-‹wÉ:wòÏyJH\ÕĞ‹÷‘Œ*¸~áÃĞÓ<ÇØ
&pf¼2©>ªİS(.98†Ìcİ„:À„¹M6©ÑjÏªG:LÓU”2Ö†Æ!Ç&¿³Íœ.tøñv“e¦K#Ÿ7Tû­ç4¿«¿pÒ‚
´4q$Fb+Ô·Ğ­˜¨QËøzf–ëü ´€=–ÇEk°½n¸|ÑÌWlQ¨HúFD+
^½L^õ×k.&+j–&‚İâsÊZY„RÊƒ3dÛb‘na({4;t©Oµ ÀuvïÃV–›#İïê/\[eqg‘BUŒèâ$ûã2jêÕÑÿ¹‡7Õ‡§Ğ²›1z¹‹\ôÈ¬gËÄ2BÕò!ò™k¶¬†×éş¹Eö:âg/âb³ª£Î¤3«É?/Rµ|x!=ñM4ØšI….¯y¡£¢8Ìä—†7rhóPtìTHT¬R„Ø%Eµ$Ë»¸d©2)Ñ¡50]&ÏP¹=ÍšL&•FŠÄ\Îñ…SOÜšĞYxÓ Wµ‡Yº“§×U1«ü,ÎÑ–Î|îÏOe<Ü‰Õ=>Ñ6d€b”6Ğæf½§¡25n)™:™Díuä(+ w©Flo|¯%]¡Xüø¢{Æ_£Ú ‡Â;=¥~õô6#Iúr2~{9[P[ñ
±¸DÑDÑ)™ƒÄ5W¥¸öÒJÅ!3TŠô-€ß¬R|!WªfŒ®ó¨UÅ§èñ UÁôYä¡vsQı;W¥œt£ÊlÑY¡r•ÈÍñVeó>%~4DhLˆ¶~şæI"ã4OÎ./A¨P¡¡ã~°J%“§Èƒ`Æ~šláŸ·y«J>ù<(d–Y"ˆ#ûuj\,Ê|ïS&TßSŒhwí¨!¯(6eá–Å¬(ÊÖ_Yjæ#Æ•é"iaØRËmÅPÈâÊÚ‚Êîvys'ÇCgn±B=?_âÓ+!‹Ÿc$!Føš

èağ(Şè0èHğ#H «´S0Õ‹ŠŠ“Í¨6@Eq‹Šò*ª¹RÄ1‘‰ë‡âm%ƒ•G.ã¬òîèÊ“K¢ø–5^ÍtÓòÈß x’~Cw¡õ±LµMdœ¸ûhXG:İDïX&#çŸMf—hõÄ#Ëqæ6ï U 4^€u0vuµç°™§j`,|P¾Ç 	xÙSüÈTÙ*^
”>¨‡€7^Dè^¿R‹2æw‚kŞhÓ<@ÁÀQ€|Úhp°Qà‚š¸Ñ@Á%¢€zº¾aÀø(Faç•Ï ƒ#Å³ğyÅƒàLQvÊ¸W?SZNŒ¸Fè;ÖA¦gE=EÇr\T-)ô€ëˆOè¬İG
VS+ƒ«vdŞ>_£În¤¹:; @|R…œÖì¨ãì]ÓBå¶;´YÓ5Ç€Í.ÓµÑù§,T”0LvpiòÛTrNŠDrhøCGWßS=À‹©k’· !ÖäjZŠheø*ıZö§]<÷³Ì0cÑš4^3İ(P ‘*T(s0èÃŒ!ÂŞ“ß+´®ı-ÇÆwã–ÉPjôó!~îŸixÒ¬µõ4>æôüéA¹î&ü Õ~ƒ?@°MÃ®°Ğ¨0Á…Ê´…+"¾ÃÀÓ|í–Üpnåù§GR"ÒDDWÏ¯ä°9¡Öp„i<fÍèáph’B5 ¦?Jb¡bÅI–ÿÆ0£”ïˆXUÍÎÏÙUIµ.rñaeºX”¬ ½•òUî†"Xx¡m„z‹1¬n±J+ÿ§å¹z˜£QÆáö‚=Ùt4ÚçvB”T¨HcĞÆé‚;ÔPwşh¸›XxJ?©Ózlc•â¢µÈEg	 òÉø4æñ¤*$h«ˆw-:®ÛwÖ³Ylh¦M3{YÊA,Í‚Ä9pÓ´”“]\O&ï'UaêÉûP$ –Ş±»†g{œeY±¸3hôæ>=Cù,Z¤ˆÛ2šx0Ÿ„	J—)<öaZd`ÒÛ*0På>,QºÈ¼DÄ…B&—!Ÿ[`)'ÄjĞc´"†˜!šK>ÄæAë3˜±ìv–Wçd·67ª;µj€ŞÙüü÷ÿÑ€nrŞ¢Ó¸ş?ò+…ÕB¡@ı¬Nı\IŠ2 œtÃıäŠË«y>şk¹åÜ
ŒqmêÿãjÒì;Ôxğ95Go+´¹ÍÖ:™›8XÏMIùÁ¹‡6¨(äV0¼Õ§ëÕOI¯I÷*µE(SÓô6ú*ÀÈìpØÂûKä=`7äAWsİ†=h·—H®/u]L¼Ñ¨È°´2Ë€÷åâ_sõCÔKÓåˆ,€0ºˆ¦ğ,Ã–¨\\¶ tµe¸^é¹-Íq7˜]Á½649ÏDdÀ,Ë¾~dà:Ê"^°lJø1zjÇ-nä}2vØrAêâ5JFBÔ2ÛºëŸæGÀpuNƒ<„!Äı@¤HìA?ÉÇÚ±Ÿ¬ÃÏüû™ÜZ¦Ë¯‚Ü	Ì€LNÛ.\ÏL¼iq*`~^h÷`BSË=”8P?Kı¯øö"N==`è‘°Ú 
;A¾†î[§â!'ˆxˆÅÕ¿şË½}úş=õC<¤£ãœgŸ)®ç+f²VçĞã‚à&Tû`&í¢Ñ±/K5£€ÁÃ&¹Z›íÓ·¶ê,.ğæ/Ê›»;ÈBsíYcÈ0ÉÄ„ã„f_Håö®tÊÏúı’r¼’Fa†¬$˜¨cPjL=»çÀª/f·ªÅ¶9p¿Úñ ©—?¥¦)ê˜Èö…ùR‡å3	*?|“_Z“FE:b9@‰’?´t7ó\ ±,…>o“àáé=¼¢YÃ×e£Xå\7P§j×‡—©¯ØĞíaJ…ÍÀÆP°xËq–®X, Ó|iæ	nÛ8aúw‚·8:U<d&ÎM?Œœäw§®mÕ„#Mİ„Áâ%Ô1BşÏVùş¯ ßÖpÿWÌ£ÿÏ©üé[ßÿÎÌ[33ÛZ“ìÖÈg‚à³™›ğ¯ ÿ~ÿğ÷¿3ÈòÁÁ>ÿŠ%ş5øw;%á?ÿ1Ht¨gº u¢½ ^Lšİ«aFíoê¿ÀÏêÿ_r¡~NSd
\Æ½”:FÌÿµ•ÂZ`ş/¯MçÿÕ¤ËÚÿ_šàÕÄiŞl€z¥î>¿V,nıÑjg–ğ”$ï6¥-BX“ÀwèNP3ğ:¨gc&W„Çx¢ÈmÜáÕe+^5‚	ŒÁ"¥kÜ¾ÍÏÙ+Ã©sbºÚ6Êû¥Gx{iâÁ7jùÒüÓÁGO;ëO³äI øÅ32/r6[@¼'ÿ:Ç"©ù%éF­ÿ¸«„&§&£¾PÊĞfğ£ñ°€~ŞNd^)C7Ú„ù9­†ßä@‹´à+î,†g ™@|"xx,6¢ŞcŠD/øbt'9/ş!l$Œ×eI“PÙÜ÷†×S-œr-Š
)¨~Fm^b pCÊp”ßY²A·µxÚ×¿DË^ÉÎÃg;Ñ: wÊÇ¥7i¹ÑE§V`Ò2VüâäËÒ<ıš¦,ÖsşX G¶ÛAµ“C“Ú«ñ$©!F†lYI¦’ÀâsFĞÇÓ9(N W*Ù²L_.G0ß†å\`ŞËÔ™¤©í¿íÒ·)™#¤¤·x="œÛ¥äÂéÎO•\8»Â¹0ğã|ÒËft¢:hµÑÍäÍ)wsxn6!ıüÀV”Ññ_kX´³‘Y•Lê<väa­İ/Í{X½‡V‡=•¢»ŠwğFHˆG€ª-¼²µ…ñF7Hf¬Í¯¨›t/S¦4/Z$s&KÓêZvI¸–—!LÃ{o3 ]×ö9ìQ4§Ë³Ï˜»C’ĞÀÉ$…œ—Ç§‰xˆq5 }aÅVrÃ‰!ËÅüâúÙŠS“0©¸­÷Ï@2Òò¡8gƒáÛ	G†Uš?2BqÊ\­á¡Šb1²xD1>@ë¯Ò¼b
–N;0B¹ş‚‡”ÏËf“é´kÃÊPîBGÒÀZ•’jš%ÿ>Æ6k§ø{a0L…iÏàRn‰3è]ocà%´¡§Ù'¢Y-æ©gJzM¸A{TlE„åi:Mœ‡›ÂC3 T‚ÆÕu€B¬¥ÎÌ-ˆ¯‹Ã»3ÿæh™eı¯lô6É:ÆÔÿ.ç——ÅÕ"ÉåWV–×¦úŸ+I¯¹ş×äúßôÛÙõsš"S´óÅÉÖ1bşÖÖBó¾MçÿU¤©ş÷zõ¿ŠËÓ¯¤X¶º¢ª‚å«rSuğù›ğ¦«ƒÇR/^ŸúŒYv‹é^½˜8".¶©Çöa)é2ZØ	şï{Y¾¼5f”ü_,,óø«y\;sùÂZq*ÿ_Ibñ%ç†Ì
’äY´ÿê<®]ø¢À_P{{0Cñá²ô°æ=-ò§eºåOWøÓ}i›.Ş­bˆo÷ïôñæ^Âøğ§R«V	»Ş^ÛNÎu.‘¤ôe=¿üŞûëùÕåÕõ"¤õ÷Ş‡Ÿ ÷ÍÙ»O"E»VŸl£äÿ•éşOã?WÖ¦óÿJÒôşÇµÜÿ†2xS%ÿ˜ Ñ‚úôÈĞLVR¿9=9aÑûõ¼YÇª»÷'ôºù|\Â*—]Gn¼û¿ ö×rù<½ÿ[,Nïÿ^EÂğ9—]ÇyÆem:şW‘ü8—WÇ˜ãûÿ"üEûoØ1LÇÿ*R êÓ¥Ôqöù¿¼–/LÇÿ*’§¦©Ôê4×„ë¥ÿË¯ç?ĞAqºÿ¿’4ÎùÿıvşÿˆÏô½$ÿ¿¥¦éõLÒü¿¤Ù?jşŠ¹\18ÿ‹kùéü¿¢”¸7håa^Ã×3ìóö?õÿJoñÏÎPÛ`îŒŞmçkM«×Ÿtƒ§iš¦iš¦iš¦i")Á>nÜºŞfLÓ4MÓk˜?şùÿüCö™àïßâŸß”ÊÜæŸ„~Ä?ÿ}&x¾·øç7ùçşy›şùÿüCöÉ™V‚o>¼æß¡$¸‚"AøçGgêò4MÓ×*áŞıÛ3Í{FŸÑÂû÷oÿƒàûU©´nsfæïüø·ªNø}kèû~G†Og+{oÍ˜3™™–ZÿwnßKõßùÇz&T^ª?ò}Dıß€¶¹3ÍÆ±Óot-´‰ıÛ~×pÜ\îH¼õo~ëÛß¹qãÆ­ìÆ³ZÇ:®Ñë…÷4û	şÂ€˜şıÀ²ºŞw­ñÈĞë·oC¤…–Y>6Ì–u|Ï˜-ç‰ôâæÍ›7nÖoÿàåË|q‰¼_8]"/ó¹ÜûKdu¥xzzóÆŞÍ—6Õ;ùòå«Óßü%ÖÁg~70ºÙïŠ×â¤7ÎÑë÷[ÿè÷ÿ(ú}3yëÖ»õéÖ§Û;»õÛ·¾¯w©¿@´!rê·ão6-sÏÖ Ã›Ñ„7ßmj]uáêån·f|Ér7m«Ûİ³M}>ÿ­9ğ]èÕg¿p,Ûİ À>3 >Ëõ=¬c—&p¸“õ›7ÿ­ßùÁÌ-¤k–ïÿöwo÷{·~ïÖ÷£ıR£«?<6ZnçsÍiê&†:ù ÚÄ0lº}ó»oığæŞíüí÷~ø£ÿşOŞ~;˜[@ùlĞ0~=0Ü“Û³7n°:Şy{öæí?ºñ/®m[-L€¾yû·çoÜx‚Ï7¨W„Öo¿wû»¿»xçí[ôâ¶vã&}’ÉŞºuğ(á¶s“=Y.ŞzûaWkèİÛ­›7è£÷Ş¿õöcn|tûSş°t÷ÖÛŸñ`ÎwK7Y›ŞŞx»zãöß¾ñK¬¹vûº	Õÿø‡?ÂVmŞ¸ñ9¾)·Zzë¦wµnö£ö…¢bö#®‚½kòÛ3¹™{3ŸÌür¦?s2ógfşÅ™¿2ó7gşhæß›ùOgşë™ÿ~æïÎüƒ™8ófş™ÿsæÿI$ßI|7ñ£D*1—x7ñÓD6‘KË‰›‰OŸ&'~•ĞíD'a$ìÄqâ$ñeâeâO%şùÄ¿ø³‰?—ø—%ñW-ñ×ÿvâ+ñ$şÃÄ–øÏÿEâ¿LüÄÿœø_/ñ¿%ş÷ÄÿøÇo}ã-®¯|KPÿJüoıBã|n¿õchüãÍ?ùô§¯-ÿİßÁş'ïŸúşÈ»w2Ëï•îyn…"e2¤ÔÇÈ‹’ +6Ø¸õqç!”Ğ_Ü@j»ıßşş~üÃwR?ùÉm¤·ôçOçrëv¦ÄMúógóğö-x‡€oå~R¸	„û¬•[k7€Äo‹½]¿õáM˜·¿ÉŞşüVùĞúíoS@•[·nÏà\½9’h‡’ì5óßÍü= ×ÿwæÿK|+‘L|/ñƒI,$2‰÷w?OÜKl$ª‰Ä^b?QK$%ê	-ÑH4İ„™°}J°¯§‰?™øç:ñg€l‘hÿRâ_Nü+‰5ñ¯'şÄßHü›”xÿ} İÿ(ñ'ş Şÿ6ñÛ ©n©¤šøŸ|R•¸÷wş™ïÿÓò›VÌuQûÒ¢vT³Í®e¶g˜ÌşÍ™îLkÆ˜9T—ƒoş¾ü.b‰•Ş…–Wï]ÄÒzŞY3mºüºL /òß¼Ÿ3¢-±9C-‹ÉÑÎiš¦iš¦iš¦¯Múû ¨ÿ¯ÆŸÿOÓ4MÓW8%¾Y©UîÍx‚¡„ºvÿ~%
Ì?x‹-ğgI×ks0İÿO÷ÿ_óıÿÌ4}m“oÿ{y‘@Ç¿ÿ³²–ËÑû?+++ÓûW‘üñ‡åÈÌ´.ƒÎ~ÿCNÇÿ*’dÿ/à›h#îÿäsù5æÿ¯¸²ºRÀñ_)§÷®$ÍªñÖû¼QÄIGŸm‡^´xã<AT¿ac7É³0»™¼™ñ&õĞañ›Ô!¾ì"æİAŸ@İm[ë9Éä^ùàãÒş]ŸCwVÙŒçê? Ş¾D¤ÈG]ïwôæs?r"‚îZ’îÅ©díNI^äS¤DR)¯õ„ˆA&æJ+#òÊ¹ÉDå€7z×Ñi½Ù±Hªº¿¿»¾ñDØLÚ¦È’€,†/9E„¡gcàûªÃ~
á8ÖÀn²0Ò“#½|M“rÿ&¡å¢›˜Ig_ÿa˜Şÿ¾’$Ë¨¸Fù¯˜Ï-¯åÖĞÿ_±PœÊÿW’BãÏ>êÔÁ^¦2‰:FÈËËEêÿ1Oÿå0şßZ®0½ÿy%iR>“‚Ù6ÍC[s\{Ğt¶Î9´HM·æÈ÷Ú|²İ±(~²¾Ø”ÒA?l°ä­eò…L®p¿t³Vc.]KÄV¢%=|­E:JÛ¤›»æJe‹ä39ò3ò`o‹@ı“Ä­Ğ6ó¶8ºNÚ†KlŞ=ÒaÖ¨ß.Œ²C¾ö¸¿7“Gv²ƒ>ª«‘Rv+»¿wj©Ñ£›Ë‘ïH×ÔÉEsÆ ¡©¥2<o¦­»ó•İíòæN}§¼]_")¨^•K-
 }ÍíŒ €›äòYVÌÉ¾ë¤È»DjÅb’F/¡‘ˆ€h˜îB*‹»„1JèìµS‹¢°ãtEùa…kµ-©|Á/?À½]\wXÙ‡µê><Ö ]Í”×p˜ñ^Ùoe¹V{¼»_L²ocƒæ}ÓÙJó®“'ï:ÏæÈø }O 9”ÀÏî»¥%ì>vƒ¹¼D07G§_à¡ŸHğˆ??·ˆD—1¹ıèj·jbş³'”%°'¬¿[w¯ë¡ZÂÃR’„’''¬˜a¥Rd‚Tğ2¬ bjGš\>~F•ò±V
á©ú¸`éàº—Ø×:Eïÿ€M°ò¬‚¡ıßÚTş»š4úqÕA?ŞX_¿[‚AxN{ÙêBİú2§ì²ïÚ `îc÷ª#nä3ùÜ•FÜ Ù-—Õúı,AÉõ¬èhÏ³´îsDF¦ä##‹qG3¾¤ë%ÿÛ07èáÀLi[Ïé/6€¥úM@J+¹ÜóäéTñû5M¡óßÉ.ı4ÒÿCëquuêÿÿJÒtıŸ®ÿãFùñ…Õ`ñ½¦ë½Ô„IÃ;Öõçİr8èv	“0‚¿ìéÅHàÑ&[9pâ÷Éø/ècâ‰?øÁ±hœI»äşÃ­-’î!¹[-Óì»wIÖíõåìŠ­p÷§ùä% ¯¥€=ÃlÚ:Ò¥v}HÌ-––—ŠK+K«çBçæÎÆ~u»ºsP~]°ÊM/®“…ÅäqñÇÅfÄßYvİëğu%Õşó¸ëÔ©î:ã°ƒš‰Ô1Jş[)¹ü·RÌ¯Ñó?jÿ7•ÿ.?MlÂbø¶3 ^£t†µ£“–¤3PBôù$i-%³-©âÑ\Ød‰L€È­e }—bI$yòôdN–ÂÄ›‡ ÓHŠ<l‰Ã@òĞL«µ9'ĞÆ^ÓíİÄC-ÖÓ@G%éM”S¢²Ò Nğ¿F×ğ› ñ*Z„dcZ‹'‚*4?Î’„ns
±É=ÉXÌrë˜„¶mÁ
¶}
”–…®5ôC<RÄÍ,Kn&9«äŞd±¥¨y#»®¼w-‹4ûa:€EÇ±³,‡w“fTv)|V2¢‚èÁPÉ.€*‡æÃŞ·t­éu¹ã×ÒâÅGUSC{L*éiæ@ëN8Ç mõÏÙŠ	
x‚\`?p.DO)ægî}ÜG¬ñm$»ŒØzWg!Éì5`Ç¡f+·¨Á§îuŒ‡ö@Á@Œlwò	2€gÉŠÎ¨Ú_ÂAÊDÈÎäcÍt’©»Ç–ı<ãÔÖİdùĞÕíàC’|Âùò³äÁI_/9Lp=‰gl%&f%à,Y<<[ò1‡IæÍâRP,Ãi‹fÅ_À{Ç;ËÆòƒñdõ…Ş¤4wö²YJvõÆ¢å*fõÏ«AáY}´Ëlivkwàön	¨õ«€'ÎBQìâ»Ôt]#Õpt^÷š~–¤Ê"&9ğĞ	Æ!ÿ—Wó<şçZn9·òßêZqy*ÿ]EšÆÿ¼–øŸÊ,{c5‚1Ñ?É4úçyöÄÓ&0%«g|É°p^h÷`B“k ÂÖ	^.t£§ûvm¨ËéM’¡bS·5a¬ÔPhNÇ»ÈÒĞı{5PÖw@"bĞ[0’ ğ8ü
‘¨K‘Ë)8ïÊ	ÑÛuõR†ÕyĞÑU‚`Ò†Üz¿#ÇüÑ@êÒ4£K+”jî"(<l’«µÉæNí ¼µUßxX;ØİŞüEù`swö
,×åĞKï¦p/£à„fÜİ/olUÙ¥#¾af„Xßú`;ıMÊ’˜.b) ©0˜â“¿Ãñaâ}a ¥yÀ*åƒròwNØ»–æjK"oI=âw<hs;¼ÓRÓDÉøö‰Ædm!ïğÆ§÷D¿%¨\o;&Ë(
ZR†18
 ŠÄlÏhµºú±fë2èûÛøsÆ²Ş'åGe¹¡
¼/€˜aÑcUoí>Ğ…ÖAŞ¤¾)È¦±ur‚ò(¼êÁÆx(r†>X(À6f¤bQÁ¬xaÇzøzƒ2#ì—Ê[Ş+ÌLœ›~9Éï~m½1I•ÿ9CÍØÎ$ƒ6ÿñº¿Ğÿ
¹µÿ[^ÊÿW‘TwlîTŸ%÷u§œ^gÇ»Ü×L)ŸÉ±ÿ’OTwªû›Ï’µêÆÃıÍƒÏë÷€÷VkõG›åúöçŒ¹Õî¡¹xéPë:“$7M“NQûÿ	nıi1ÿ×V
klÿ_(¬æèùÏÊZqjÿ{%é²öÿSS ˆfGhŞlÀ†bLW…êµ Ï,"¯Uá¶CQÿC¢§‡O…íDjø.¾¡ú¶{‚úõİÅÈÁHvğxÿàQ%*óèZÌ‘®V€g(…×`.™f‘GÖÏÓ§Ú‰éj/Ø<*ï—iİ>ñ†¯µ|işéà£§õ§ÇYò„¹¬ÏÓgd^äl¶:%xëoªNı7ZI-W§—Ì¤’äÃÜå·v7Ê[§ãÔd4‚U@Í`æñM–”·™WÊĞ{;ÇÏi5ü&Z¤_eéå)‘$x/vˆ^9 ÅFÔ{L‘¸¹ß¬†slìîÜ!l$Œ×eI“PÙÜ÷†×S-œr-“” úŠ¯q XÆ0 ˜t[ËÜİ|IİİxsNÀg;Ñ: wÊÇ¥7iËÜéÎE'“:i+~qòei~MSk†9	,ßP„ŒÕK9³ÖìPµ“Ğş$ñ©š?™õ­ÍÚÁi’–•d*	,>gŒáör¥’-ËÔ¹³ä óÍ‰äó^¦È$Mmÿm—¾MÉ!%½Í@Â9°]J.œNá\ğTÉ…³+œB./›Ñ‰êT ÕF76“7g¤ÜÍá¹Ù„ôó[QPFGÄ­5bÑÌjDfU2I¨óØ‘‡µv¿4ßÖ]z/ÕëPÛê°§L§ZGšxoĞô¯£wûâ jkXÒÖìdK¤3ÖæWôfº—)SšÇ-’¹“¥iu-»¤\ËË¦á½·€®k{ö(
šÓåÙgÌİÆ¸šÑ%i“r^ŸZ<&â!ÆÕ€öY™C,¶’NY­‰Ú|¿¸~¶âºm[¶TÜÖûg º»«ìCqÎÃ¡FDhĞ)@VişÈPˆ†«5<TÁÏAŸ‘ÅÀ#ŠAğ4æyi¾Gí“Òø®c9.u	@¹ş‚‡”ÏÏÑ%„Ò<<rmXÊ]èH8C«²CRM³ä[?q³§/®4Saznïq¥~s«*·Äô®·1ğÚĞÓìÑ¬–óş0•ñ5á¦åØ¶B¢&ÂîÆAq*à<Ü¬°kââ
PPI¶Üª”ŒûÂ•;3· ¾.ïÎü›£eèl·^èuo‚uŒÒÿÂS_ÿ»\DıÏêÚÔşãJ’aÁşæZÆ<d;EégH¢äVo+V`×İúiºhŠ¶ÿ¢{™‰©GùX[Ë1ÿ¯ËË…â*ÎÿµååÜtş_Ešê¯Wÿ+Ïµ¯¦˜up¤68¨
FõÀT|ñ&¼éêà±Ô‹×§>#d–`PJo¨Y GÄÅ6õØ>,Å~RK!ÙÁ{hı‡İñ¤×˜Qò±°Ìã?¬æ!+úX[™ÊÿW’f)ƒeœrnfIòd]a½tíÂşb«RŞ£®ğğá²ô°æ=-ò§¾£=|ºÂŸîKÛtñnŞù»÷¤¯½¹—Èî&ş©ÔªUÂ\Ô¶“³gK$‰Š–Õ|®Ûëùå÷Ş_Ï¯.¯®!­¿÷>ü¸oÎŞ})4ÿ3õJõ~ùáÖAıÊäÿ•îÿy¥°
K#ŞÿXY[™Îÿ«HÓû×rÿ#0ËŞXÉ?æH´ >½2´“•Ô¯FNONXô~}oÖ±êîıÉ ½n>—Bë]ĞOÎÈˆõyeeÍóÿ±RDùmuyjÿy%iêÿCöÿEÿÉ©?]–éN?–<xôVp9î?¢Èàr=€D^ Yq2FMğ2ôsº‰…=Ağ•ñ"ën.×ˆ$­–v÷ª;•Zİ»×XJÑYƒW³_´ç3ïerõ|±˜M©Î?òş¥P*ƒ4[.”»ÌÕGº…’å¯4Rvõ1¢¤ÕÜ×1ßŠÚ:#m$Ú3È›êDòÿß2)úFI;ƒ&RÇ(ıOny9àÿw-·R˜ÊW‘¦‡´ÁfU5Ê|xc5®¤‘¼®y¢9ŞLœÀ=Q”şA-Î×Å£o²(l5K€>·t¸?,»l5×‰÷0i5Ğ§T³?€Rì¶f
ïÊXIÄ¦Y¢k§³»	9Øëpñ@MÍî†eº êë¶yO·`¡…Ì^Ÿ	òu³¦iš¦iš¦iš¦iš¦iš¦išpúÿ€ÇT 0 