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
‹ vnŒZ í½klcIÖ&Î¾ºÙñ÷õn¾ìëÛñWCiVR¯ø%Íh†½ÃÙ=šÑË¢º{f»{¹—äy§É{¹÷^J­éÖúCb q?ş8±m “ü‰óú“‰ƒ 	,8@ØÎ¿6ä‡“sêqoÕ}”DIİ3¬™É{«NU:uêÔ©Sç43;sÉ)—Ë­­¬ú¹Ê>s…"ûä‰ä—ÅåÜêÊJ¾HrùüÊja†¬\vÃ0W³¡)¥ÍÙ‡¼çığ>ßÔ€ñ·­:tÏ8§s	uÿBÇ?_XY^ÎW`ü‹Ëùµ’»„¶„Ò×|ügßÉ"	44§“œ%éÉ%€6·ÙZ's{`GZËpHùÁ¹7pSwRÑô®Õïé¦K~Jjƒ~ß²]²p¯R[„25Moë¶n8®­9N
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
Hä sÏ?y²ŞèjæóõgÏæC‰ógŠZí©sQU™Í.Èà÷lÙN	m³”'dˆ&ËÌgŸ¦–¦²!Ùù¶Ÿ#¿U-›F ´3ïŒÜës/Å`œÖ½¦2^?¼=Õ“¸ƒOsÜfÅïu@/ÈIkcw{»Œ²>ßmîœfÄt·“9îXK;Ao$à¯±,æÆ2ğj&ÚfÉ¸Ç|Ø(0-xcc°Y¯h'\c>ÿ³wó°_HãârI†^£©ŸBÌŞ/8Ó0…,Ùüi(Ì Ù°2kÀ°ösÎƒ@7(áƒ¨@÷¸Ä!w¯:.ápõ;Òù¥\ßæ.ª“Ùª¨xÕ /HÚ¡Z•İıõª'ÅŞ=M!áø[0äHâ˜\X _~–_TùC¤ú<~ØÇÇ‹3hâÎî¶Ù' À˜†ÓÑ[Aõ»?ğŠ¶ı+VË:6—@üİ?6`Ö5`G©Ûx³VoeR²D²š‹#•D¼“ §é!ik SK:æ¬c.>Os9yû\Útn*ĞëÆ”¢ éc$`‰)«&³áÍì1¯:	ûO$âAÿZì?W–W–=ûÏüòÚŠ+SûÏ«HSûÏk²ÿô&ÜWÅş“uèëkÿ¹šÿGØ¾ŸÉ­)y¶µ/ğ”âÚA,rYWœ"4-óê’áwæCÏ³}>5(ƒöf”æ2ù7Ö»ì•š•|¾‡=z¸µ5v‡X§Ä˜İc¬éà¤¯'?­V÷JÅ³ÀáÀv½LèŞc]N'ës]ï'×ôÑt°”J§Å÷1ÚÉ®üûEÈı®ÖZĞ¾É´.ùIõ«oKëuÔKÒ#8QÑZesgc¿º]İ9(oMmrÏAµ¯•MîÔoíÔ&—Ö1µÉÚäNmrÓ¯“MîX&¹S£Ü©QîùŒr¹l6ÊÓ75¦Ó¾QÆ´“ö“ùÒºëÆzo½zf´.l¨š*Òõ*Œl'éÖrj5Î8µZ¾ÁV£üxnL«Qæï_rQq.–~dslÙ—|ªÀb]àê¬uQ+.ı”V<%“ğo¬Ö‹«9¨Çt-²‚#r¬ëÏ‰IUñÉêãúãjõÓ]Içò0µ˜Üİªø/`àg<MÏ½Ä€ÓÅEZü^yãÓ‡{õZ(UZ‡J¡QJ‘wq+A¢9V1¬°ß„ˆÂêUB}ÆA¢U¡9ü_ñéh`x4«âÀnó“UYn!…¬vij=L.jÇ©o¾¶–ÈàBÉ8ŞÌÎ::òéË]T[eNIÔ(3Dµc …Y³J\Ëo7şzš>^xEQ¶¬Õã‰“7nb*˜Ñ)îaÆèÃ8#;÷Rm‹T(ôjLsQÙT”Dß®£ëáË<4Úş0Ñb f ¤ßn’Şû²y8²².ƒ™qÛ_²mŞÆîÎ}r7®×#º&œä‹pç}Dç0¦	íÚSE¸¡…®eµ&s‰ìıFw¡ÒÏAõâ'wúKöiê=äÍd‚ÏúF+ÏQXæÇ[‹ãñ­ã-ïENê3ePÌk9·AñhcâÎ?ô"»<†½p@Ü.\Cå45(A—t>Ló±º-´×Ñ#(kĞe>ÂR<†¹ÿQöã]ä¡p ²ô1N]B¬Sd’°¹İ#i;zf >™‰ïÆ%wáĞ€¬¿ ·3a)¢Ñ‹±;"ÆÏ„L½yó¦¦ŞgH×mjûZ&4şÍÔ=5ë¥Ô1Üş;—+æVÑş»¸œ[]Ëç—I.¿¼º¼<µÿ¾’ô­ïgæ­™™m­Ivkä3ÁšğÙÌMøW€¿…ğ;ñíñ@–öÙ7Zâÿ‚ßdù~{fæÇ ‡g´~¿«gºšã¢0îåg÷jÆ7ñÏÌÌÇ|=­iã
¨ã¯ËÜôï£ñ,Ïû-–÷'¼hÃÜèê›fK13óéüsÿ…öÏ?óWBh¯gR"
]RÃçÿÊj._Îÿb¡0ÿW‘¦÷?®çş‡g‰ÿ&ßı`Ê)zï	è"à‘s#Ntzä2näÂ·@Z°»ìË~"è¡Ââq¾‹›ÇÀaq™„ælYÍçºyC¶u·PÚ®&dçS0V®}2asƒxŸi¶æ5ç3ˆGh5†3¦¶õGÌ¶>HiG^%h«a¹äD÷B gÈ„»ÈõïÒq½~‘Ÿ†›É.{˜8;è~ó:ÉJõ~ùáÆc©°øôØİÜHQUSJÉÃw±R&¶¡Ts)g€<ŸtV+e­m×+»°·SêmY8›ÕŒõ­İò–œ‹ºğóìíïVnÈ9úô^’+ÁaG”håÂ³öó…L!“Ï,gr¡Œ÷·ÉÌT‘ûUªÜ|PJ±IW§g8ÃRòPpÔDEô¬ä â/êêÉ·…9MJ§É%ù}vîåL±óÁcñpC›™CIÙ+X<+<IÁfu·Iá1N5ªh´ÈúNšâÒ”A£Näšˆì,a.`ê’™]=óÃæS•¦uHıbm&£9ZÉ?ñfØö±÷Á÷§Éà
0q$hş¼á0ıŞ8²ƒuuœó-0ÌÒL+)š«‘pƒs4 X™œ ¢£‡§¶Š-Aî4 ŒB˜?}’Ç_¡A*Ím¥UI-wWÆ~…âÉE+U„Tñ'åGeQ¥÷ıŒ•}¡iµ8wı5z¦.ÊU6÷«»ûŸ×™5Üà¼ƒÊ”´9Ñp°'Bƒ6‘5tÒ6’®{BîbÕö>G/(¼÷ìŒ²Doè@íMj<lzWñôzs@›‘å¼Ì+¸ûp£ZAÍ=ÿJu÷¯¹]&3ášÔ€…PLùK·ÚTÚeı4ÆšµÏÖİm’|0²®7¡PîçÂ•×RïedDeÖ"®µVàH­jzØk ?su»‡UÍ?Céˆ5xì•>Fƒ¥CÃv\‰¶,]xlÀÚaëİpEYNZ§$İÕÖŒ>¯®•U+utŒ§’Œ²ÎÏ>}á°85³O²€€‡›HÙ°Î««Ş	àm$Ğl’ÙfÑÂ§yE2‘‘TT…9­*_@ır&aÌB<LDƒc‹×ph,FU|cÒã>¡åL6uSVïSZŸOIÄºŠ=Û<ÏÎE²~0N}£Ü‚¯¦üTÊğĞ¿S+T@í	É;d¿½¸÷«FÏ¶„BR¥ÒšüÈûû2¯‰ŠŸQßº7‹v|¨0Ê1õ(€x¦ed4¨gN¾Y`×±€-ãÕ=ëĞE“¹çÜŠN–_¥«éDV'ç3U.Æ”õ'3ë”ÛˆŒåP2¸p‚"r¤Ñj€-ÄX'„’“µ™çdÔ>¦®Ô@n­0¦=»!ímcy­ÔÈÏß_ÉÀp´¹rx;P {âA*d¸^¡Y.Š[_äPÅDÕ{¥òËÀÚ²Ş¥÷4óD…!Et4ˆ‰î¦¢8‡t»İÆ(sİÀ ‹ÚïJ”Á•/\6`ò3'Ï€;¶Z3â—h'D)‚wJæ‘#ï0E<\¥*‰´©.ï‰7‘'B1Ôa; »3Ó\½ÖÎKg“¦1J_—fp-K]šãª#	xÆU<È±âèo–‚	Ry·¥˜ß*c#£©[¡¿Š®Z—5ğ,`e·âìR.ójLéd5Ñ•º7,*Ìm·ã_Êñ0‘ê~Dc†t/ ŠmÏ³uß)€F­Ê2Ä<ÅÏ%ÜÇz]½·xW‘Ñ6‰V<%¢®¨ZÜo…lµ‰”sÆ×™pÃ<®T”œÒ$ò¨Ç‡a<xˆW²b-Îçe‹óyx£Úf²t+ôØòh™®N=Ù>=ª•á(£šôç?`Ffì7ŒÁ“CCZm…$àâL¹ ²l›Â?¨‹ÜhÏÍıºÀœõ\rBf‘RÆŸÿ\5‘ÏÅ)[0ZèÕ"h;G1ä?¥Òl£Láº9;¬„ì]‘Æ¤—Â²µfW¯Síf4 –ƒé?=p”qv»™¾ævT l‘½éÅDŸ·âá1{³2a-ô16}aÎGşb¨4s‚±Ë:O!©b_E;¤Şc¼«:œ}«RŞ#{ÈI‰TúOÌZSóò¬õZm+”½L-«#³ÓÍ~¨À¾dNÍ‹‰ûÕ½`öIŒñex£Pò fÆ2ædf¾Íõïƒ];fˆCÌnÔ éI“Ÿ ªk> }É¢+¤4Š¤ÃÏB?£RJdco-1FÀ·VÇ”î"GğòøT¿ïÎğ©æáU™K:/ùš/.*àÎ¨ ÂÉq~`Ë>°àÄyA®Æƒ<Û™†€Â×h°tFÒ~}Û0İC2ÿnzÅ!ï¦óü»J¿ñ¯ƒò{XFàú!Î¶Ë-_X†Yoœ,dB,ŸòOÄ¶÷RÄéb*f§4gHÛŸÎS—È|a Ç ghóİ‹Î<ZÏŠ;öœaLÜzÆ0û@¾·Qí¹;Ğ»]1İ¾„æùê6m”YNÏ%íñº’õ.&éKÎ;ƒ”q¤df5yíQC–†BË†Gè4Çé[ìä@|ñHˆ ¯ƒDOEºÒœÁ‰I½vhJúb¯,İE;©¢’¡ÜõÇwG’¨b¯Ü(gí-ÃæwOåÂcD8PHšÉukì\lø€fÈ^WG•l~AT2Üî	UyH…b/¾Ä¸~»üvÈm-¨dNJ(ÁD6ª
Çñ‚1oÀ¥
{ş~hÌ‰Ëd­7cÊ
ƒ¬3lTƒ»\›Ì1(‘#Ş4Fm1)‚*Ó&™ÏÒMİoPÃbæšÍ2MÊş³KÙ_Îeûó¢|ÔrÒÍÃv¶ºICçp!	õ‰Š'jÕÉ+Áú>¦·5'Y•k—\%l´B”÷e“Äê9’¬›#X›Íµh=Æ¬àI8Céßæí°‘*½Kí„b5d ©$ˆ‚4]„$	ÎR~òä—ß{?:#OÌÅ¼«Ë«1yéH¾_!ï{ï+pÏÏy/Æ“RQ¼<¨a¢^‘Ju!ÅE ¯¬¼ˆÔ\HùƒÚ‹Õ…T"¨¾ˆÔ]L‹W±ºúx¬Î÷á¡½¦ó¤¯	óWc®Sé\#NßÃ¢aì›oŒãĞÖa‘º Ë«'úr¢¬Õ ©l `¶ùôiàÑ:¥ŸuN×%
\÷hk}NEKJîÛ¸Ò¨Öj…6A®ur®–›P‹ïŞksøæ6%ôKTÙuôn„ÒN9A¡Y„1´ìèeÂŸX“œZ*)”>ØêÎ£‹İãğÁ‚ø°v°»–¼è‚Y	(H}†ıï©_H%¿ú<PÈ³’RI2.ºxvj‘Ÿ²+*%)»ò|e|ëJµYŞó@~a¾ì†xÈ._§³KÏ£K“í`	ñ<=ÅæÃå”®”Ô½[°&‰Å(%¤çCŠˆN‹Dv*¸¿‰*ÑDdmAYâZÈˆ¬<8g(+{U Øfl|•xodvx®d—¹ˆsRî HŸ‹ø­ N:èóÚi,	ålƒŠÖhËë€8~E®G
¡-õÂ.Ğ#kïØ$¨*UËRFMÔ²òı2ú^ªºão÷}ô=€M '¤ñ¦O¸Ö¶ÕQŠÉÇ—#
s¬èÁ#`°-²ÁÆd–.6~‘yk¥;rØ·£y=™Åw›ì¤ŠÚìPÏ`|?¤a¥’jTdòÄ7¦h!ÙhŞ;„<{F’Wyk³ì9[¥ù©a´‚Û9™;‹¥…ùü÷*µ˜¹C­‹ˆ¿§D'^ôB,Œ…Y„1÷jAY0‹sÙ§…ì|”—ülŸPqëïø©Œø»é|Ÿc¤"´Ås/i§‚'˜RøSÅ<G0æP*PN,.Uüg-á‹OàÑlæ–Ş¥~Û.ãÜ’]¨Û¼–!ùÔ,¶ÀB½O.±ó6ğ43ˆÕëAØô¡ÃcÈ†£6÷óLCß
—€¼tínEİfC‹¤Ç…¤¿wZR
ÅîòŒRÏi.„°¤SÁ[ºíıô.›Ht­4'ĞÜñ(4¡&mX½eî3+Í©]¥R¾iÓ|ûºëc	é?—æ“¨~ÍÎùĞy£úşìYàÈÛ´HOs›%ÒÓ59«æB‡Ì–A·ÚM
ì\qÛ†S`´-Œ‚Ì¤‹>È‚­Ó¸‚Ra‰åùHHI‡şcÉpi–®ßP›e·XËuøßdn"—ØŠ ‚;d™;Ãl+›pXè¾$s¥´û¡-¸@·lÚÂú™²XH3Â.øõJ}¢ã‘M…ëŸeÊ=à:ô>¶m’`\<ô¹}¢¼Y¡'98µ[€& @pºËì2Ùé€7(K¼úÅ¸ìR°i™i)Íqß²5»ÅÇl8å‰vàÀa×À“Ün—‚C_P¶ÃgSêQŸ=“ª#.€9³8õ¡…„šY×ÖˆÓEÔ\Xë†ëy)YÏ«)_ ]\J ŠÉùé—+ˆã1ï ­ˆÛ|lEúõ@wĞ=¬b¬¿ AÜá÷zÄİ‘‰+º˜¶©+’vœÿ÷]î´^;ØÇ¢Eiƒ°mYTÀ…î¼”+9•aò!‹Ÿ¢-{FZ§W#ŠÌ‘øÉÌˆB+C¬…F¸UP”A»¸6a‹aPE­ìª÷C0äµ0`^¡¨Šå\aì•b€*,÷¥fzMä±Z…t’šSÏ¦£ÍR‹Ax8òq'Añ§NqçAÁçêØIìYº‡<|˜²‘ê÷Yåj^Xãq¤ˆ»]×N4YğD_5^«=^9†“¦¬ĞY† ÒÈ:Ğ†YË­KÖrëŠµÜº¯YÂïÁùş‹9[FUyÄQé³ƒZ[?2`‘ }ğ­¥ gtkÍ¢¸‚Á}=Å	¿¬¨ZòxçbÄ@	Êô*¾r/xNUúJ#¨ Eâ]™1|FxÏÎ¼H{—±&0)_Ÿ™uíc‚¼úZhö²È·+0Û÷«å/:!šæ¤ùíAÏ•9M÷¹·¸&PÆSR"$¼Ä¢ô.ğÇ
:*£P–uà|e1xD¨ ¸Ä86jÂ7Ò3Ñºİ±1Åèh¢ê¥õO?º™Jıc]aÏ/Æ´ö ×¥‹B÷ïØD_Î9fÆ¹¿CÎ™ë÷Q¨°gcU=¦àÖª$ÏbõrÌ"üe4s=Ön‘¿”½.»¼áï…§˜áí©m_´E“kM¥VòŠKÇÏ¡A$Gv²çêf…[ub<^·)9Án®ì)èŞN‚4Ô¯œ6FnKĞaËEZ€5ªQÁì£#Ôz¡·VÖHÇú>Y¨–xlr/¯Ñ¾2Q ÑØ!`¬;”(ç“.^G;@àM-Ï|ciOügd³Ô³0áy+~ÈC.[Ç¶a¼Í.ÖoÁ‡ò´º;v3bä‚á‰,à¬}ÍqQgOiHŒ¿ŸõÏ¿™,;ìQ*¨÷[÷…ÉeWX ®1Ê‡.ôG™±?œñ¡ºS5à+±R7‘.(ÙÖBq¼X,˜UCù†	²»‰,ÅÉëöD>M×‘øŠK­cTüô—Ÿ_.äò…âZ.Ÿ'ğ¥P\!+—Ú*¾æşÿ›º§MêÚí’ê8ûø/§ã5©e5/wòÏŒ=ş,şÇê*Œ~eµ8ÿ«H8şûÕre»šéµ.©ÀÇj±7şËkkrü':şğ-7ÿri–j‚iPn/®
UÿRc”Şy¸ªyô÷ÿÔ_£;@P[šİ2¾—ÕŒ^¿‹&%ÔÓ³»¡ş™}—Å/àª)tåNÜÑMcß¿ÁÄ.ÒŒÁâ4µ¾îdH¹‹q?ÚÅG§u¨ÔºhAzâ…¿Àîa%»›Š®³ÄÑİ*º(u´ß1Üm¼?¦ïO¬1uôbFœ®Ğw!w‹†ãSdzÈ„GÒğ‚åRÓaÚ/èÚZŒx¬aC¨ÕMWAÁ7ltŒ5v-êØĞ4`Cp¨ƒÜoë
+
©T¹¶½DöËK4Óƒ…İ³l±ë?îMjÁfàEbS·µ.İRã‘a³½™ÆFW—:‘I&ï¢¹ƒÅ¡Ì›2»®‚ÃtçãæÎ–%æ
–Iœ~]–E¡T@³I-¹Õ‘;®=h"(
„çš†ajèÙwÉÃ>MQFš1zFW³‘ŒÑ€hdø á(xş	ï—3d“f>¶×ÕM,€!“˜A9;NÃŒlT¶sğ‚<Úşûø—¡UØÆ
ª‚r5ÃÔÙaÍ¾æôºÛ30+7úÔĞLò‰î8'Ùškën³Cëw:TëA½êÚ“yÂ¼S³æÈq¢a>‹Èƒ~`¸<ÿÜè˜ï ¼Ï¶åx‚ä°¸>Üs:r‡
Ö…SÖyŒ0õ–VäCgÆÚ€>˜ë}@­‡4ôW¿ú@Åà>pë¿É’'¸Ûm¶ıÉrù¬Ó¹ÚÊ†+#éNÕ¤óùt~¹/®Ş[_y:ˆÙ?À¨J¨ó²IDÑ…Gœ‘ä2ùEÖÌ8h<L'w‰‚-ã³Ó%‡Ã
?t´¶¾Õ'éÎÑ3øÛ J—_î>#Cá(ax%”ó¹»­ç½£ñ¼ç÷UI¾®ï>ZÑˆV¤ıë¡DûL\ŒôÔC÷úm}q¸£xpºIiQÃ‚©Û³Zú(hœÊĞäHc†lãG™f·t>±PUCª•$u/ã:0ßØ @İşÉİˆ¾Xbä!Ä&udAÜ"÷|ô/fFUÑbU cØ¨*h ©è*|d.r|ùFÇ ÀvúEpè;‰d…‚Sg£Ëñc\İ1x/^à±­|.ìŒBD™!Â7.ğÑqOõ©/ne²cXéˆ/ï{15ªÆˆy9¢F¸É‰ª“½]©A±\mL¥şªˆj½—#gywÑ[¾ØG]¶g´Z]G}dİ—éósĞ-«M×Éu’u{ıĞ‡ñ`‘L&7å¥Y¡QÑŒŒ£ÏAîÚåÎ”Aì¢D¿ƒ„odş™réÆ;œ1ÑÉÅfÚ	—æ$$C67LF†Ò­èÒwpå¾C„8Æ¼óöY]`­‹ø„¶›âà4˜í;‹gnñØ¥Îğ¥Hù¥‰’&t³½ÉeAúÈ²Ç\¼`-“#%Œ#\E0‡µ(,ì÷Ò¹B:¿ZÏçÖWŠë¹•³É#ùL.“ÉDj?ƒü[¸¢†‡b®I†–xHkB*‚íZÇøË;¢%’
)ê®0)q0„X!åt6Qœˆ<S2¬lÔïpõYzïŒÆ3,®!£ÊzËx¸ìÈr¡[ä¼Nßƒè(şzª¶š®‘cŒŸÇ±•ÒŒCA<JW,şyÀÁq@©7ãcAe•˜ƒã Vî·OpÔM~
Ø±i²ì­çùÌ{™\=¿Z
©¶±¿¹wP¿ÿ'v†òĞ¡ ùºF]Â‚%E+ZŒÇ×ñR â;“£¡‚Î2Ç9XÿBŞX³;ºÔ¨©U*ÌÎQñèÙ]nŒy]p<0²¿ãÌ¾{´Ì¢-dÛ¶áµó‚Ü£ì[ÆÑ†“„_Ğ³ˆa¥ÅÏ³€Úˆ0H§£Vñ¢Z“"€‡”rC"'Œñä±Ş¹NIñ„Ù@ÈOHOxÀj~^œTÎ“xŠT’&Šş	†S•Ë¶5â1‰Ä¾”ìlfe6éG§’¾¢Ç6ù7m‘ÿ³	&Ó’ŸdPl¬ıQ÷ «m[.Òn© ’#°7Ó?‰
·F}ˆ->î:è ËéQ³FS¼Övú7@ ÈVaóĞ¾³5,EæéÍp©ï»¡”¸¯3!ÆÃÆê­ñgdMdg©8O½îÙº/-VH
Ø°êpRjSd/ +[</*”,šz>h’°{6€Ü!!ö­K´ÕÉS„
}{ñˆDàL–ç,«ï B´o¢:nb16Ç°]3`<x†¸š^@EWQéØáD’9G¥T†H]Ä9«pÓ”j¸§øô:?ÔáË¯×wî=Q†7Rl®á1Ñ¼wCáö´ç:qğlè
İºÑ»FF»ãÆè8Ãª;´SÜ3íYf÷D·ãê}¢ºº·‹DTO;hsüs)udIF|e‚ëùóªq±%ÿ¹,Ubèø½¡£GrÇS¯rÆ³ªÜ‘&I2f,Z~ïfÌ€´
I;öäY ôü²iêÂ#çÅ³dTqF:³³èCVR!®Ëv³c¸:=SL&ïxz;âH•]x~lÙÏ™Z/DÉ
*¦¹âŠ1ïDuàè(¶ía:.Y‹–MA1Jãá?´góH7nlj˜¥\Ã­w×xy’ºD¿ú‡ªŠ²6ƒn”˜>^ã	b¤Zš1ï¦=@GKÌÑ‚Ë°°ìtX´)ó2d×‹•‹}÷ò]v¸<âÈ8¢*GIåçi„4\HY…Ä£uaŠ›ÌÛM#¬œÆÒ\dhKBƒ»Äm~•cÖ‘†‡Fœ°³õûT 9àgÏLS¬˜KÈKahx2Éä+
‚Ò+RÑkÁ¼ø 2FXé’WÁ'˜Ñgß2DzşBaù¾ˆ;‹Í€Ø§Fw?agÜf³SÇá‰aKÁ”°®Òc¿­„öµ¿DáÍÊíßvzîGøT[Ê'“hª·•1õ¹±ÁÄs1©‹^|¼ÄdØwôOG­B˜#ßì„nxƒXC‘2«li0¾Âà¢Á9 Â‹¥ƒjt¹Ogÿ8«5@›E*lÓBctw¡©ö&hÑÀ£]w4³­·2dËâ]²Ãİ€üsW5ôè}¤£
®_x?ÅÇÄ0$ô4ÏI¶‚	œ™#/ŠLªj÷ŠFH!ó^7¡0aDnÓ†Mj´Ú³ê‘'Ót¥Œµ¡£qÈ±Éïo3„~|€İd™éÒÈçÕşckà9Íïê/\´ †B -M‰‘Ø
õ-tC&jÔ2¾™å:h-`åqäl¯n'ßG4ó[*’¾ÑŠÂW/“WıõÀãšK£ÉŠš¥‰À·øœ²V­”òàÙ¶XÔ[ÊÍ]êS-(pİû°•åæH÷»ú×VYÜY¤P£'º8É¾yƒŒšzxôîá­õá)´¬ÅfŒ^î"=2$ëÙ2±ŒPµ|ˆ¼Dæš-«áõ@ú?ƒGn‘½8AÆÇ‹x‡Ø¬ê¨3)ÆÌjòÏ‹T-gÈCO<E¶fR¡KFDÆk^è¨(3ù¥áÚ<İ;’«!vIQ-Éò..YªLÊEt¨£gL—É3TîFïcFs€¦€“‰E¥‘"1—s|áÔ÷‚¦'´BŞtÈCía–îä)ÅuUÌ*?‹sôÀ‡¥3ŸûóSwbuO´ ¥´¹Yïi¨L[`J¦N&Q{yÊJÈ]ªÛßkIW(¿~…èªñ×¨6À¡ğNO©=½ÍHA’¾œŒß^ÎÔV¼B,.Q4QtJæ qÍ•G)®½´RqÈ•"}Ë à7«_È•ª£+Å<jUñ)z<hU0=FVy¨İ\TÿÎU)'İ¨2[tV¨\%rs¼UÙ¼O‰ÑÓ"¯Ÿ¿yÒÈ8Í“³ËK*T(Cèø ¤¬RÉä)ò ‚±ß‡&Û_øçmŞêƒ’O>
™eÖ„È#âÈ~G‹2ŸÀ{ÆT…	•Ç÷#Ú]£A;jÈ+J„MY¸e1+Š²õW–Ú€ùÀˆqe:ƒHZ¶Ôr[1²¸²¶ ²»]ŞÜ‰ÀñĞÙ†[¬PÏÏ×‚øôJˆÁâçIÈ„~‚¦‚z˜<Š7:Œ:üÈ*íLGõ¨¢âd3ªPQÜ¢¢¼Šj®}Ldâú¡x[É`å‘Ë8«¼;ºràä’(¾eW3İ´<ò7(¤ßĞCh},SGCm'î>Ö‘N÷ÑûÖ‚ÉÈùg“Ù%ÄZC=ñèÆrÌy…Í{ hğ_ `Œ]]í9læ©”ï1@Âw@^ößòUv ŠÇeÄ…¿ê- ä™€×‚×¯ÔÄ"ùàš7Ú4P0HD _§6\ „D¸ &n4Ğ@ ‰( ®o0>ŠQ˜ãyå3èàHñ,|^ñ 8S”r îÕÏ”–#®úuéYQOÑ±EK
=à:â:kG÷‘‚•Ç”ÇÍàª™w‡†Ï×¨³i®Î ŸT!§5;ê8{×´Pù‚ímÖtÍ1`³Ëtmtş)%“\šü6•\ƒ§“"‘ÜşĞÑÕ÷TÏğbªÄšä-hˆ5¹š…"Z¾£J¿BıiÏı,3ÌX´&İL7
h¤Ê€ÕÇÊœú0cH€°wãÁä÷
­+FßËq€ñİx e2”ı|H£Ÿûçc4km=ù=zPî‚»	?€5‚Ä`Á¬ÃÃÔ°+,4BLp¡ò£n!Ä#ÃŠ…ˆï05_»%7œ[y¾Èé‘”ˆ:QÁÕó+9„N¨5aŸãÅD3z8š¤P¨é…’X¨XñBRC‡¥Á?…1Ì(å;"VU³ósCvAUR­‹\|X™.%+h¯§cg¥|•»¡^˜¡çb«…[ì£ÒÊ¿ÆiyG®æhC”àq¸½ CO6ö¹%jÒ´qºàN5Ô¤?Úî2ÒOêÀÁX¥¸h-rÑYˆ|ò >y<i
	Ú*â]‹…ëöõlšiÓL€ç^–òCK³ qÜ4-åd×“É;äIU˜z²Ç>	€¥wì®áÙgYÖE,î=ƒ¹‡§OÏP>…)â¶Œ&Ì'a‚Òe
}Ø£˜ô¶
T¹K”.2/q¡£ÉeÈçÖ XÊ	±ôØ_ƒíŸˆ!æEˆæ’±yĞºãããŒFf,»åÕ9Ù­ÍêN­š wA6?ÿı4 ›œ7è4®ÿüJaµP(0ÿù©ÿ«HQ”“®c¸ÿ\qy5ÏÇ-·œ[ñ/®W¦ş?®"Í¾CŸSs´ñÖè±@›Ûl­“¹‰ƒõÜ””,‘{hƒŠBnCY}º^ı”Ôøš´p¯R[„25Mo£¯ŒÒî ‡-¼¿DŞvCt5×mØƒv{‰Ô`áúR·ÑõÈÄ
‰Kë!³x_¸ Îğ÷5W?D½4]È£‹hêÏ2l‰úÈå8ÀeJW[†ë•ÛÒwƒÙÜ;a#PA“óLD|Á²ìëG®S¡,âË¦„"£§vÜâFŞ'c‡-¤.^£d$D-ƒğè±­»şi~´WÀPç4ØÀCBÜDŠÔÉô“|l ûÉ:üÌ¿ŸÉ­e
¹ü*ÈÀÈä´íÂõÌÄ· æàç…v&Ä1µÜC‰õ³ÔÿŠoo bÖÓQá †	« Ğ¸ó4ákè¾u*r‚ˆ‡A¹P\mñë¿Üó§ïëS?ÄC:j1NÁyö™âz¾b&›au=¾ nB°fÒ.û2±T3ê<l’«µÙ>}k«Îboş¢|°¹»“,4×å8†Ã‘LL8NhÆğ…TnïJw¡ü¬_ÑĞ/)çÁÁ+ifÈ@‚‰:†a ¥yÀÔ³{©úbv«Zl›÷«šzùSjš¢‰l_X‘/uX>“‘ òÃ—Ñ0ù¥5iT¤#–3 T‘(ùAKw3ÏËRxáó6	®ÑÃ+š5|íX6ŠUÎuuªv}x‰‘úİ–á¡TØh‹·g)àŠÅÂ2Í—fàf°Óf¡op'x‹£SÅCfâÜôÃÈI~wêæVM8ÒÔĞM,^B#äÿ\a•ïÿ
ğm÷Å<úÿœÊÿW¾õıïÌ¼53³­5Én|&¸>›¹	ÿ
ğï7ğÿ;ã,ìó¯Xâ_ƒ·YşóƒäA€z¦R'ÚàÅ¤Ù½fÔş¦şü¬şñÿõ'êç4E¦ÀeÜK©cÄü_[)¬æÿòÚtş_Mº¬ıÿ¥i ŞP@œàÍV ¨WêîókÅâÖ=± öGqfù OIâønSÚ"„5	|ˆî5¯ƒz6frEx'ŠÜÆ^]¶á5P#ˆğÀ8RºÆíÛüœ½2œ:'¦«½`#ğ¨¼_z„·—&Şpˆ£–/Í?|ô´³şô8Ka<#ó"g³Õ	Ä~òßhÁ t,ªšŸ¡Q’nÔú»J˜¢qj2‘¡¥Í`?ÒèçíDæ•2tã¡M˜ŸÓjøM´H¾âÎbx	ä((â1€‡Çb#ê=¦Hô1FGs’óbàqÂFâÁx]–4	•Í}ox=ÕÂ)×8¡‘€êgÔæ% 7¤Gü%t[‹ç¡}ıK´ì•ìì8|¶­ây§|\z“–]tj&-cÅ/N¾,ÍÓ¯iÊ¢aÍ0ç/òØ„a»T;yñ4é¡½[’âa”È–•d*	,>g},0ƒâô r¥’-ËÔùårä óÍ`HXÎæ½L‘IšÚşÛ.}›’9BJz‹×#Â9°]J.œNá\ğTÉ…³+œƒ@Î'½lF'ªSVİØLŞœ‘r7‡çfÒÏlEAÿµÖˆE{0«™UÉ$¡ÎcGÖÚıÒ¼ŒÕ{huØS)Ò«xo„„x¨ÚÂë![[{tƒtaæÁÚüŠºI÷2eJóø¢E2w`²4­®e—´ky¢Á4¼÷6Ğumï‘ÃEAsº<;ğŒ¹;Ô(	œLRÈyy|jñ˜ˆ‡WÚFQPl%7œ²ÌPÌ/®Ÿ­85	“ŠÛzÿl $#-Šs6¾™ qdX¥ù##³ÌÕª¨!#‹Gƒà´ş*Í+¦`é´°#”á/xHù¼l6™N»6¬å.t$œ¡UÙ!©¦YòïclS°vŠ¿ÃT˜ö.å–8ƒŞõ6^Bzš}"šÕr`z¦¤×„´GÅVDX¦ÓTÀy¸)<4ó*@A%h\](ÔÀZêÌÜ‚øº8¼;óo–YÖÿÊFo“¬cLıïr~y¹P\-’\~eeymªÿ¹’ôšëM®ÿıG¿İ˜½P?§)2E;_œl#æam-4ÿáÛtş_Ešê¯Wÿ«¸<ıJªe«û!Úà *X¾*7UŸ¿	oº:x,õâõ©Ï™e·8ŞèÕ‹‰#âb›zl–’.ƒ¡…àÿ¾—åË[cFÉÿÅÂ²ˆÿ˜Çµ3—/¬§òÿ•$ÿQrnÈ¬ IE[ğ¯ÎãÚ…/
üõ°·3.KkŞÓ"Z¦[nñt…?İ—¶éâİ*†ñvÿîIo±aî%Œß*µj•°ëíµíäìYçIúA_ÖóËï½¿_]^]/BZï}ø	pßœ½û$R´kõÉÖ1Jş_Y‘îÿä0şsqem:ÿ¯$Mï\Ëı`(ƒ7Uò¹-¨Oo€mÀd%õ«‘Ó“½_Á›u¬º{2@¯›ÏÇ%Œ¡rÙuäÆ»ÿbq-—ÏÓû¿ÅâôşïU$ŸsÙuœgüWÖ¦ãÉSqyuŒ9ş¸ÿ/Â_´ÿ†Ãtü¯"¢>]JgŸÿËkùÂtü¯"Iqjê™J­NÃqM¸Qú¿üZpş§ûÿ+IãœÿßŸaçÿ/°€ÈñQğLßKÒùÿQjš^Ï$ÍÿKšı£æ¡˜Ëƒó¿¸–ŸÎÿ+J‰{ƒVæ5|½1Ã>oÿÑYoğ¡ôÿüáµíÖàÎèİv¾Ö´zıI7xš¦iš¦iš¦iš&’ìãÆ­ëmÆ4MÓ4½†	ùáŸñÏ?dŸ	şş-şùM©ÌmşIøçGüóÙg‚ç{‹~“ŞàŸ·ù'áŸñÏ?dŸœi%øæ#ÁkNğJ‚+(„~t¦.OÓ4}­îİ¿=Óœ±gô-¼ÿö?¾ïY•Jkà6gfşÎßø‡«ê„ß·†¾ïwdøt¶²÷ÖŒ9“™i©õçFğ½Tÿü§gBå¥ú#ßGÔÿh›;Ól;ıF×B›Ø¿İèwÇÍåş‡Ä[ßøæ·¾ı7nÜºñÇn<«u¬ã½^xO³Ÿà/ˆÙàß,«ë}×ı¸~û÷6D@AZØhéåécÃlYÇ÷¬ÙrH/nŞ¼yãfıö^¾Ì—Èû…Ó%ò2ŸË½¿DVWŠ§§7oüàİ|ióW½“/_¾:ıÍ_b½Lqæw£û—ıŞ©x-şHzãm°~¿õßˆ~ÿ¢ß7“·nı±[Ÿn}º½³[¿}{àèûz—úD"§~ûwÑ9şfÓ2÷lı:ü¸‰qMxóİ¦ÖÅP®^îvkÆ—,wÓ¶ºİ=Ë1ĞÔçóÏĞšß…^}öÇ²İ
ì3à³\ßÃ:vi`‡;Y¿yóßúüÁÜBº°öaùşo÷öw¿wë÷n}ÿ1Ú/5ºúÃc£åv>×œ¦nb¨“_ ¢MÃ¦Û7¿ûÖoàİÎß~ï‡?úñïÿäí·ƒ¹”Ïã×Ã=¹={ã«ã·goŞş£OñâÚ¶Õ¢Áè›·ßy{şÆ'ø|ƒzEhıö{·¿û»‹wŞ¾uà@/nk7nÒ'™ì­[Ïn;7Ù“åâ­·vµ†Ş½İºyƒ>zïı[o?æÆG·?åKwo½ıà|7±t“µéí·«7nÿí¿ÄºÑ˜k·¯›Pıø#lÕæŸã›r«¥·nzWëf?Z`_(*f?â*ØÛ¸&¿=“›¹7óÉÌ/gú3'3fæ_œù+3sæfş½™ÿtæ¿ùïgşîÌ?˜ù‡3ÿhæÿ˜ù?gşŸD"ñÄw?J¤s‰w?Md¹D!±œø(±™ø$ñiâqâW	=ÑNtFÂN'N_&^&şTâŸOü‰?›øs‰)ñW5ñ×=ño'ş(ñ·ÿAâ?Lüg‰ÿ<ñ_$şËÄßIüÏ‰ÿ%ñ÷ÿ[âOüß‰üÖ7ŞâúÊ·õï©ÄÿÖï(4Îçö[1†Æ?Şüø“OúÚÒøßıàò÷ş©ïÿ€¼{'³ü^éG áV(R&CJ}Œ¼(Ù	²bS€Í€[7qB	ıÅ¤¶ÛßùíïÿèÇ?|'õ“ŸÜFz»Aştş'·n'`JÜ¤?6oß‚wøVî'…›@ø·¿ÁêY¹µvHüö·ØÛõ[Ş„Ipû›ìíÏo•o ­ßş6´Q¹uëöÎÕ›#‰v(ÉşW3ÿİÌßrıgş¿Ä·ÉÄ÷?HÄB"“x/q7ñóÄ½ÄF¢šØIì%öµÄAâY¢ĞD3ÑM˜	+Ñ§û*qšø“‰.ñ§È‰ö/%şåÄ¿’øWÿzâßHüÄ¿I‰÷ßÒıÿqâ?âıo¿ê–Jª‰ÿÉ'UiûwçŸùş?-¿iÅ¼Qµ¿ -jG5ÛìZf{†ÉìßœéÎ´fŒ™Cu9øæïËï"–Xé]hyõŞE,­·à5Ó¦Ë¯Ë€ğ"ÿÍñ9#Ú›3Ô²˜œíœ¦iš¦iš¦iúÚ¤o°‚úÿjüùÿ4MÓ4}…Sâ›•ZåŞŒw J¨k'ğïW¢ÀÌğƒ€·˜ÁĞæ™t½6‡Óıÿtÿÿ5ßÿÏLÓ×6ùö¿—	tüû?+k¹½ÿ³²²2½ÿqÉXÌLë2Hàì÷0ètü¯"Iöÿr ¾‰Ö1âşO>—_cşÿŠ+«+ÿ•bqzÿçJÒ¬xo½?àÁEœtôÙvèE‹7ÉtAõF0v“<û ³›É›ÿaòĞ@Pæ¿IâËîØ(bŞô	Ôİ¶µ“Lî•>.Íáßõ9tg•Íx®ŞùêíKDŠ€|Ôõ~Go>÷#'"è®¥Ñ é^œJÖî”äE>EJ$•òZOˆèdb®´2"¯œ‹LTx£wfĞ›‹¤ªûû»ûèO„Í¤mŠ,	Èbø‘SDz6¾¯ê1á§cì&ó(!=9²ğ×Ë÷Ñ4)÷aZ.º‰™´pöõVéıï+I²ü‡Šk”ÿŠùÜòZnıÿÅ©ü%)4şì£Nìeú'“¨c„ü·¼\¤şóô_ãÿ­å
ÓûŸW’&å3)è˜mÓ<´5ÇµMw`ë<C‹ÔtûÈ`|¯Í'[Ğ[€â'ë‹M)ôÃKŞZ&_ÈäŠ÷kA7k5æâØµDl%ÚXR±ĞãqÀ×Z¤£´-@ºé¹k®T¶H>“#?#ö¶Ô?IÜ
m3o‹£ë¤m¸Äæİ#æaúíÂ(;Ä0ákû{3yäh';è£º)å`·²›ñ{7¡–=º‰°IğtMlQ4×išJP*ÃófÚº»0_Ùİ.oîÔwÊÛÕù%’ÚéÕY¹Ô¢ Ğ×ÜÎ ¸9@ ÙA.ŸeÅœì»NŠ¼K¤V,&iôùˆˆ†é.¡²¸K£®Á^;µ(
;NW”V¸VÛ’ÊüòÜÛÅu‡•}X«îcÁc½Ò¥ÑLy‡ï•MñV–kµÇ»ûØÀ$û66hÑ7­4ï:yò®ól>€ŒÙ÷šCÙq üì¾[ZÈîc7˜°ÁKsstúúø‰øós‹H4q¹cÛ®öx«&æ?{BY{²Àú»eq÷ºª%<,%I(‰qòqÂŠùøV
)E&H/Ã
"¦v¤ÉåãgT)k¥ª/€ë –®{‰}­Sôşø×ë!ÿÁ*Úÿ­Må¿«IÓ Wôãõõ»%„ç´—­.Ô­ï!sÊ.û®ú æ>v¯:âF>“Ï]iÄİrY­ßÏ²”\ÏŠ6Ñù<‹A‹á>GddJî12²w4ãKº^âñ¿sƒşèÌ”¶õœşbXZ¡?Ğ¤´’Ë=ON¿_Ó:ÿìÒOÓ(ıO1´şWW§şÿ¯$M×ÿéú?n”/`_XßkºŞKM˜4¼c]Ş=!‡ƒn—0y!hğË˜^Œm²•'~ŸÜÿò€>&nhñƒÆé´Kî?ÜÚ"éÒùG»ÕĞ2Í¹{—dİ^_Î¡Ø
wšO^úZšØ3Ì¦­#]j×‡ÄÜRaiy©¸´²´z.tnîlìW·«;å×«Üôâê0Y(PLŞ\lFüa×½_WRí?»Nê®3;¨™H£ä¿•B‘Ë+Åü=ÿ£öSùïòÓÄ&,†o;ã	à5JgX;Ê1iI:%Dÿ˜O’Ö2Q2Û’*®Í%‰M–ÈˆÜZpÑwé! æ‘D2‘'OOæd)L¼y2¤xÁÃÀ–8$À´Z›smì5İ.ÑM<Ôb=tT’ŞD9%*+âÿkDp¿	¯¢E8@Ö0Æ±¡µx"¨Bóãü!Iè6§›,Ğ“ŒÅ)·¾€ÙIèA iÛ¬àhÛ§@iyPèéZC?Ä#EÜÀ²äf’³JîM[Šš7²°±ëÊ{gĞ²H³¦Xt;‹Árx7ùg6PA•a—Âg%#*ˆ•ì¨rh>ì}K×š.P—;~--^|T55´Ç”¡’f´îPàÔˆsĞVÿì­ˆ‘ €'ÈöçÒ@ô”Â`~æŞÇ}ÄßF@â±Ëˆ­wu’ŒÀ^vj¶r‹|êéXÇxhÄ8Áv'Ÿ x–¬èŒŠ¡ı%<¤Œ@„ìL>ÖL×)™º{lÙÏ30NmİM–]İ>$É'œ/?Kœôõ’cÀ×“xÆVbbVòNÀ’ÅÃ³%Cq˜dŞ,.Å2œ¶hVü¼w¼³ll!?OV_èMJsg/›¥d÷XoláQ Z®2`Vÿ°Õ—ÁA»Ì–f·vnà–€*Q¿
xâ,äÅ.î¹K½A×5ÒXGçu¯égIªü'b’`Ğò_qy5Ïã®å–s+ ÿ­®—§òßU¤iüÏk‰ÿ©Ì²7V#ı“L£§iO<mS²zÆ—ç…v&Ä19± l€àåB7zºo×†ºœ®Ñ)*†ñ0u[CÑÆJm …æt¼‹,İ¿Weİy$"v½#	Ã¯‰º¹œ‚ó®œ½QW¯!eX]%&í`aÈ­×ù;rlÀ¤.íH3º´B©æ.¢ÂÃ&¹Z›lîÔÊ[[õ‡µƒİíÍ_”6ww`¯ÀríY½ô.a
÷2
NhÆİıòÆV•]:â»fFˆõğ­¶Óß¤,‰éâ –’
ƒ)n1ù;&ŞçPj¬R>(‡€! ç„½ki®¶ä)ò–Ô#~ÇƒF1·³Á;-5M”ŒoŸhLVÑòo|úpOô[‚Êõ¶£a²Œò¨ %eƒ£ ªHÌöŒV««k¶.ƒ¾¿ıX€?h,Ká}R~T–ªÀûˆ6=VõÖîƒ ]h]äMê›‚€l[''(ßh€Â«l‡² gèã…lcF*åÌŠv¬'ÀP€¯7(3Â~©¼ÅÑé½ÂÌÄ¹é‡‘“üî×VÑ“TùŸ3ÔŒíL2hÓù¯ûıo¡ËQû¿åÕ©üéIuçÁæNõYr_wúÀéuv¼Ë}Í”ò™û/ùäAu§º¿¹ñ,Y«n<Üß<ø¼şpxoµV´Y®oÎ˜[íáš‹—µ®3ùHrÓ4éµÿŸàÖŸ¦óm¥°Æöÿ…Âjÿ¬¬§ö¿W’.kÿ?5Šhv„àÍV l(†Àtå ÙPx1 ^ğÌ"òZn;õ?$ºqzXñTØN¤&ïáªo»'¨_oÑ]Œ\Œd÷UÒ¨B0®ÅéjÕx6€Rx6à’iyäaı<}ª˜®ö‚À£ò~é‘Öèo¸ğêQË—æŸ>zÚYzœ%O˜Ë
±ñ<}FæEÎf«S‚·ş¦êÔ£•ÔruzÉLÊĞ(I¾0üÇ]şxkw£¼u:NMF#XU ¤Ñf`.@àßdIy;‘y¥İx`°·süœVÃor EZğU–^@€÷b‡è•ğğXlD½Ç‰›;ñÍjø1ÇÆîÎıqÂFâÁx]–4	•Í}ox=ÕÂ)×8Ù IÉ ªŸ¡ø€e€¹°A·µÌİÍ—Ôİ7ç|¶­ây§|\z“¶Ìî\t2©“–±â'_–æé×4eÑ°f˜ó—ÀùEXÁX½”3kÍU;	íOŸ¨ùó‘YßÚ¬œ&	iYI¦’ÀâsÆno W*Ù²L;ËA0ßl‘H.0ïeêˆLÒÔößvéÛ”ÌRÒÛ´ œÛ¥äÂéÎO•\8»Â¹à)äò²¨NZmtc3ysFÊİ›MH??°etDü×Z#íÁ¬FdV%“„:yXk÷Kómİ¥÷R½µ­{ÊtªuT ‰wğMÿ:z·/ª¶6€%mmÁN¶´Aº0ó`m~Eo¦{™2¥y|Ñ"™;0YšV×²KÚÀµ¼Ñ`Ş{›èº¶÷Èa¢ 9]xÆÜhŒ«]’6I!çåñ©Åc"b\hŸ•9Äb+¹áÄÕš¨Í÷‹ëg+®Û¶eKÅm½6 P k°»Ê>çl0jD„Ä‘a•æ…xa¸ZÃCüôY<¢@c—æ{Ô>)?pà:–ãR— ”á/xHùü]B(ÍÃ#×†•¡Ü…¤3´*;$Õ4K¾õ7{Jñ÷âJ3¦çöWê÷7·ªrKœAïz/¡=Í>Íj90OáS_nZí`+$j"ìn§ÎÃÍ
»&.¨ •dûÇ­:@É¸/\¹3sâëâğîÌ¿9Zæ€şÇÖpë…^÷&XÇ(ı/<õõ¿ËEÔÿ¬®Mí?®$æìa®ÕaÌC¶S”x†$Jnõ¶bvİ­Ÿ¦‹¦hû/º—™˜x”ÿ‡µµóÿº¼\(®âü_[^ÎMçÿU¤©ş÷zõ¿ò\ûjªYGjƒƒª`TLÕÁoÂ›®K½x}ê3Bf	u¡ô†š2qD\lSíÃRì'µ’¼‡ÖØOz%ÿË<şÃj²¢ÿ‡µ•©ü%i–2XÆÀ)çfV$OÖÖK×.|Qà/¶*å=ê
.KkŞÓ"ê;ÚÃ§+üé¾´MïVá¿ûwOú:ÑÛ˜{‰ìnâŸJ­Z%Ìõ@m;9{Ö¹D’¨ØiYÍçº½_~ïıõüêòêzÒú{ïÃO€ûæìİ'‘Bó?S¯Tï—nÔ¯Lş_YáşŸW
«°4âı•µ•éü¿Š4½ÿq-÷?³ì•ücn€DêÓ C0YIıjäôä„Eï×Gğf«îŞŸĞëæóq)´ş×Åıä\€ŒXÿ—WVÖ<ÿ+E”ÿ×V—§öŸW’¦ş?dÿQôŸœº ñÓe¹ ñáôcÉƒGOa—ãş#Š.×H4á5' cÔt? cA?§+XØä	_o ²îærHÒjiw¯ºS©Õ½{¥5x•1ûEëy>ó^&WÏ‹Ù”êü#ï_
¥2H³åèB¹Ë\}¤[(Yşz`@#eW#JZı`Á}ãğ¡¨­3Ò@¢=ƒ¼©®A$ÿÿ-ãâ¡oÔ‘´3ø`"uŒÒÿä–—ş×r+…©üwizHlvPU£Ì‡7VQSáJÉëš'šSáÍ$À	ÜEéÔâ|]<ú&[€ÂV³èsÛH‡KğÃ²ÛÉVsx“V}J5»ğ(Ånk¦ğ¡¼•„Alš%ºv:KQ°›ƒ½ÔÔìnX¦¢¾n{÷têXÈìõ™ _7kš¦iš¦iš¦iš¦iš¦iš¦	§ÿ-¼AŠ 0 