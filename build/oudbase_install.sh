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
‹ ÖÃZ í½[Œ#I¶Vœİíf[÷ö®¯÷uwtcXÕS->ë5S3ìv‘İS3õR±ª{f»{¹I2‹Ìi2“›™¬êšîZ]ØlYÖãG~H0dI€Ùş0][~ıØ†Ÿ€Ø2`Ø’ügCü È>'™ù YÕ¬ªîæLÉÈ'NDœ8qâÄ‰uÃÌN]ò“ËåÖVVı\eŸ¹Â2ûäÉ/–—r«++ùe’ËçWVSdå²	Ã§ï¸š¤8–>À¼çõğ>ß§ıoõ›5¨Ûw2NûÊÜÿ…•ô9í`€B>ı¬°2Er—@Kèù†÷ÿô»Ydºæ´“Ó$=¾°Íl6×ÉÌØÑØÆ±Ö4Rz°HîõÃÔ‡”õc½cõººé’÷HµßëY¶Kæî•«ó§ªé-İÖÇµ5ÇÑIáƒEò~~¥@t4×­ÛıVk‘TO÷+İîhfsìDïh]=Ãu¢8xYê»mËæ/«®~¤™dWoÛƒÌYº3Oš–±hÚÇ.o€LÃêBîJÓp½Ü3[šãn´5³¥7ï²æ/k®_¶€/È¾~l8†e†@Ä¶×·{–£3L÷€gHµa=—¸iéğÑÖ‰aBÕÌ†NX‰æ[wû&iXM[ÂruGPsĞ†~tøÖÕ³sJúŞ$G–MtóØ°-“v*tNÛê»äàa9EÃ+J÷t+”†ÈÚ®ÛsÖ³Ù@öëØ:YÖbŠ8`q}ìİ
ÍC>®²ìÓuø™Ëgrd
¹ü*!$
!›¦áZ‡ë66#Àä™|aÖL©ù%H!lC`F¾!°eë9*š¹„Á™&P¨Õ5¾Ò\ ìU°'õçt°í–kû»»µòNqæ…ôk=¶q[8ô2–İJQ*fëøêt$)º2Œ‘~Ç%µN_w^¡BÉ‡•ıêæîNz3YŞ-ííUvÊÅÔÁşa%EF|¦wµzG'«Eø¢õz:À}o·Z)¦î—¶ªÀ¼Q‡!Hº8šªû›{µÒv¥83‡n‚œ!3¹ùäÁö^­¼¹_Ù8Øİÿ¢˜Êºİ^Š&ŞßÜ‚Òg^( gY5{ff&•¬”öjŸTJåÊ~1E¡xÒ «¡Ûf^H¥Ÿ‘¹‡ŒÃ!7ßÙ<³df!•Ü.mn•ÊåıJµZşØ²5™F;YÙßßİ/æ’2G¼zO2t÷ûf™êU˜¡ïè;ât‘CGkésóäEP¶–§×ÑNÀ˜KGvò¸25M*[ÛN‹¤6wîï’uVğb°“§ÛÇ6Iä#İ›;À;•»$]&Ñ,ïÀ÷/Ù÷=í'–İ¼Ì—<*„t;ŠÙiádÎÅÉ¡“;üŠÉ~•=b¤Äd·£²7Úzã~l½×1T.Å êí?‚}‘}×IÃ,–[oà$A¶5jcÇ ‹lº{Bz<‰Ê’˜Ü¡nÁR`bSrT¾-«EÅLğ/¶v t8cpÆy‰ù3’n¹$G~ˆó»™ÕÜèèšY2›¢o¸næEáŒ¾Ö;0×
¸€Ä‹ÎŸ#4ıÈH%Ç>×E­mÆXLF¹F—*,İŞeuÚêsóÉ´›;{‡0Iæï¬/œE1!}@×Õé4[ûƒÙ"u>š¬m ¯¡É)ª3P»¢1 3‚‚L4b “ùõ¤Âw‘ÀäæõI
~Ô<!›Û•ğÑöL,MPKHêgw¾Hßé¦ï4kw>Y¿³½~§ššÿğC)ëş~|VsHf:»@î”»û–ª”›JÉ ì½‰xD&İÑşHÑ	9ø,EŠ„«ÁÁ @…º0––Ñh[ïÓl€ƒ(E^ººNÒš4½œÊ¸ŒÆƒ!%¾:mãÈõ~´qÜSª±Øw^JkÓRŠ8oÍ|²‰CkYÃÁèP©¦áÚ6-SË¦1vÛİ»QuzÍZ?šÈÑï2ä³'"å	•"İ€ô{ Az`|n¸— ›ø"”'Şz\$çQ{à¹yoÎEé
3mH{–ÅU^‰
à¨&Ù -†¢ÎG°$n­kõMª‰kv«Kd'Cª0¸útZCñŞ°lÔ;ô^F.¢0j1™Ã©}~Tü+CñËZ	U€Å@Ó7-—vªƒÓ]B”î(
~ì—6¶*vS»Wªzh©4-ÇÑ]ŠXIÔ5£ƒÚ£RŸ|~æ«ßiR®Õo´ÙŠë¥4û9Ğt,­IÌ¼ødØ#›DÊè–†Ö·jÁl_a‹ó#¨˜Ş”ó/Í_±mh!$§Iµ5ûĞÚ°ì´wí¾i¢şÂmB«ÛÕL]áèš¤¢Gb]†uÛpªY…µl™£Gá­ Gc»qBT#piêL$~õéè¼Ö tye>D¼!¡0ÛÊˆí	m_jCÖª(E uty$·;š8bÆg6=¿² ïĞ‚º(Ä¾vÙ"K¢ÿƒæ+•OÑHv¢™¦FĞßÛZ§c)ÃôçCÅÎ¡ùÌ´NLVõ}/ÀÂPrş*Mûz×:µZG…šy/«¯œØ]eán¶©gÍ~§ãLC‹RTV¿)F‰µÙ×Ñ<“ŸekH¸×oÉØÑºƒ6Î4Ë¹Á.‰*F†•º0:ŸÔP ÓöKr³İîıñXV˜‘†[H_İ	Øoz¤Ğ±0¢pÁgŸ&…J%À˜J¥ªSŒ,(C‘‰‚
«šÊr·÷Ö»G!Iv(Ø#ŸÎ„ñä’—/áÍ»$İ¼–	TJÍç 4,k‡¹d`OfÈÌÜJAJLS{ g„JR†Ş9@”|ÉÍ	I®c¢¡¾
a ÙUÃ"GL%Ùüé+©
W2Íìç0Fzyï=ì¦’’lJõÖÛ¤×#j»äå¥5sƒ*œTÍdÇ¸,,ËĞmkÆ+ÙŞ%îwm­GRJÅ–s)\ã'“\jA«K6]P¬A´‚Úrs N}ĞöLjæ÷6yR¼]˜Nˆã­¥»VØVÍß³-~8ÑòYºƒ-ÜÓl`íal=Äs“ö±±^^ÿr½²n£ê-‹˜‚)²‚|É,†9i28èéÒ;clŸÊŒŒlº»Mó@™CËÇì{1_
ÙdkÏ“ıÊŞÖæFé 7BTUæU®ŒÆòsQÙ™Y'0ºFó¤…Z?”!h‚ÀĞæ‹Z²¬$3Š°¹¼¡u²Ü‹€I‰™QQs)Aîo$Ã¨~/ŸD fÿŸù9”Õ¦ÊÑqrÁ¶º\ôp6}áÁG­Ì”¶[!¡&@Z)!a¢'ä"ÆŸÙŒ”Š=F! ~|jÉo’8Ñ¡¹&È}Ie±	Ø×õt*Ò
}–Œà^‘MN3/ö•yEÎX3½Ë§È0ü Yhy)Ü9|(W}S¨B eZiÁ“2fÛÉé#ÛĞŸN!Å´Ò €º=—~ß³­n»†î ¥ÄÚÈ¯HyÈgÉrHdEĞµA3-SßU™*ÈáÉhÇŠ1âÏÏçËyœs‰Æ7”=&Ä4ÍZşÁ¤£±zÜÄö´Afì/g²éì¬Ì‰ëK¦§{ZãÀ’Í23–wû×èáŞ&º^x(²»T7…Õ‹«?wQÁŸÉ¾ØùĞÉ>1³$ûáYnèĞøÿ’C­K#ŸP)ÚcÓ2ÜØ†Ê4ßö©êö1¬·õªrŸÌµ@]jd6Â7Eõ¦Rö¼!Rß¶­”6Ç©R,T¸x7„høKÅ6_*jhcKÄ$.²\âm•K{ôOÕ›JÕ–a‚%İÌƒ¯dJ>«íâ®ÅœvòŒÌŞ«<ØÜy±_-¦˜é'°v»O¿¦>Ü|°³»_Ù€é¡˜ÿ-µŠ+¸;”'¿!Ù_–šMú ‹’u¦€IO>šÅRfŸÜÍ’P©¹™%–\aÕ€ôy'÷!9Ã‹tQBÓÔ'ó”VeÜy
½:² wVò!m~x…»)O[I(ôêD,Mùq¶[£˜Ú¼Ó8é±õUğ4Š 4tà0¹#FZ;=‚£_µ>>S!¶È¼Cg*jÉ›ÙÛ¾TŞŞÜ‘'ŸØyLkvs„‰,<{EöUì¦T)®[#êèÕå‚:ññŞe2´tÀ‡B ñKihàxXO}È÷Œd¥3Áëkäİß ¯ï ‰ªƒC@ğúJ!’ÙÏÇà…Á›ê+…u±~ê¦¹·"Ç
2}İ¾¨“çêáÿÍ\ø®Åÿ{i9W@ÿoø¶¶RÈå˜ÿw~âÿ}ÏÄÿûšü¿½÷uñÿæNÀ¨"b{NV„œ¯»ë÷ûøÿ’\¿óKÁŒ†éÚV³
&¬=3*"rzzÃ8:õığ¡Æí%1^÷ñ¯·3øX=ÁÏí~¥>Üß î+ô×ğGVxî«põ.IwÉGRCÒè.Û¯â¯=º³v˜æ-lÈlò”“;T=/÷¶ft·{DgŸøH_©4™øHO|¤ÉÄGzâ#=ñ‘æ"òê¡xe{m;ñM<¤‡àŸø*ŸÓWyL~¼×áU:ñŸüšùOheçaq¨·d¼£%+@iÊWàÚ1;QÂó{J²Õo\š+dwİX¯PwÈ«ğ…¬Æ¸/vP² ÍÌ	=OÀ¾DÓ­“}²˜}B²­ùKó£‹Ÿä×Ş•‹½@ßFˆj.¤:’-Å³Ù{N˜®V´‹2Œ0Ò,P9ØàŒaóh ^M“†­ãjVS=(ĞN£{ôÌ‹D›]Eì‘ƒÒ½b¸ @Úµ­Í*º0¿®c2ûËéYÿÈÙËFßÊó09¬Ï‡ç"ŞJû;è£jBH<mÚxO"êƒç>èu˜Òµ0RZ.”Î²xlÆÏÕ7¹W®_-%<¾âäP\¡%Ôˆm¯¼Ã‰Ú´).!f*ĞÃ0³ğ$ûdşÎ?A*23Ù'ùìì¼_5yåµxØ]ÙÛ`í,ÉÒçë¾£bkƒ:&Ãôû.0†èİ&³‹³ş›çbŸß1õ*Î3ĞA‘È}ï>š|Fñ>19bµŞlÆtuÁÈâ¤–7æBØRì¨‡Õ#:,ª»q˜÷!1»wÚRÊã'øxFdzêKĞ‘ãy“–‰s=Ğsõ#ò’èb¸¥XÒKú”Ğ/–İÊX¸9âdêe™”ñ¤-s½d™Ò©ÜyuJ‚#,‚zÕKËÃÔï-ÇêÛ]ÖÙ2>‹Jò*R»¯U-Ï/@è{¡¡×ôæÎ}‰$İ®CŸS×¯òæ¾j—PÈŠ¯1Fèª3_^vşÎ{—
a™V ñÂkk£ƒ¼3‡Ã,- yÿ8 í}Ër™4m®£D], “ƒÎ=ûøñz½£™ÏÖŸ>I$Ì)j±g2ÎyÕd6: ƒß³¡gÛEô€SRÈL—™Í>I->IeC(²³-"¿æU+F ´3¹¬¹×f^ˆÎ8«y¤1…^Fß½İÕ“¤ƒÏsİfÙ¯uÀ.ÈYkcw{»„º>_mîœeÆt§	ƒ9n[K+AO~à¯‘üGr¤"=àä¶G8$…#
NlLkÖÊÚ)·˜ÏşìNÖK€iÔö…‰\i¤@†^£C¥ÂÌ«28Òğ	ùúÃP8[²ne>—aëçŒ‡.PÂQêqC®^eTÆáæ¶)¤óCÙ¾gc*T&óÂT›âe<'i‡ZUv÷×+z{ö8…Œã/AÂ27oÉ¹9úågùyU>DšÏã»}ôvqú\ÙÁ2ûÓpÚz3h~÷;^±¶¿ÂŒÕ´NÌEP?EõOuuXQê6¬Ö›™”g,‘|ÓgâØEeO~èiºIÊ!³>gs1=½œËÉËÿPçRÒ¹«PÀ®èSÚI¿Eş®²	a<şo¸×«ğÿD&î÷®'şïÒÊ’çÿ™_ZCÿÏÂò$şï•<ÿÏkòÿôÜ×Åÿ“Uè›ëÿ¹šÿ‡ø~É­)0ÛÚ—¸KHÛÚÁVäº®ØEhXæµ%ÃïÌG^dGš>q(Ãöf8”æ2ù76ºğ•º•|±‡5:ÜÚ¹B¬R¢Ïî1ÑtpÚÓ“ŸU*{ÅåóàáÈvúİ:¨Ş#]Fë3]ï%AÖôĞu°˜J§Å÷èd¡ü,ä~GkM<hßdZ—|„¬úõ÷¥õ*ê=Ò#8PÑ[esgc¿²]Ù9(mM|r/Àµ¯•Oî$nñÄ'—–1ñÉøäN|rÓ¯“OîH.¹§Ü‰SîÅœr¹nvÊ8Ó@7q¦8Ó¾QÎ´ãGú:ÒºëÆzw½rn´.,¨™*Òõ*œlÇ>tâ5œxN¼Fß`¯Q¾=7¢×(»ïAdrÑp.¦~slÚ—|ªÂb_àì¬uĞ*.ı”f<HÄ‘VËE†Õ´cö;YÁ9ÑõgÄ¤¦øäNåQíQ¥òÙÎ®ds9LÍ'w·ÊşXø€gé™¸p6?O³ß+m|v¸W«V€óX¡5(2%¹ƒK	šİ‰€õ°ˆA™}"2«]TÕ;‰VT%Bsx‚_ğÙpd¸5³bßnñUY¦bV«4ñ&¯êÇ©:o¾¶ÈèBÉØßŒÎ&†w>òùËW]T_eÎIÔ)3Äµ#4
óf•¤–O7şz~»ğ‚¢|Y9>jÇ;oÜÅT£3\ÃŒP‡Qzvæ…J‹”)ôjDwQÙU”Dõ_®c€çË<2Z~7@1o F §O7tIï}Õ8¥²².Ã™q[_±eŞÆîÎ}r7®ÖCª&.#àÎ9êÌ:Êá6´jOå†Vª–Õ,ğ´÷ƒ²J?ûM´kˆŸ<´j.9r¬—È%ºÉÓzF3®£Z™{óÖ
xîmïi|/rPŸÃ©x$‡b^Ê…Š‡;‡lşñ¬Yåü…êv©ïZxURCƒtJçİ4ë«ÓDè=‚ºæ#<Åc„[`òæ?QE~!k£”%Ô:E'	»‘Û]’¶£Gf ãğ™øjìXr¬>èúsz+V"ˆİØw)ÉÕ›“7qõ>Çsİ®¶¯åƒÎ¿™šgf½”2ûçrË¹Uôÿ^^ZYÎ/VI.¿´º´6ñÿ¾’çÛ?øîÔ[SSÛZƒìVÉçB4aÚÔMøW€¿…ğ;ñÑP–öÙ7šãÿ‚ß€|‹§ßšú	èá­×ëè™æ¸è Œkùé½*Çñ6ş™šúã×Õ6Î€:.ñ:ì2„}tå°ßf°?À¢s½£ošMıùÔÔ¤ø„şÿôŸÿ~æ¯„Ñ^ÏG¹¹é’Ê<şW«¹åàø_^*LÆÿU<“ó×sşÃóÄ“Ï~0ã=‰‹çtq­”r#xìäÈeœÉ…O4auÙ“ãDĞM!ÄÌã~İâ23…lZgºyB‘¶t·†XJ7²ı)è+×>ss‡xŸ	j¶î5sˆGlU^gM}ë™o}Ó½BĞWÃrÉ©î]!c®"·3|²K7xÄñúyåôEJ1:ß+U?©Uw÷7*sOaÑ\İ2[‡·èıF|Œ	¬°nF¤ôÖ˜k6…L…P§ ÷‡¤wÒ$é=ø
ÒªîX¾‹»ìnQ«hïÿ	àÉ/çê0â™&÷ñJÈ_÷µqdàş6“Hß
ö;ób¢ fu’åÊıÒá^şSfqèî%oBjqK)0|1/±uµ
¥l…r8iËZ­n×Ê»°ÄUÊmZ(ÔTÀÚÖîFiK†¢ÑbaîJN`°î3(İmÄB¡ÅL”ÙŠ…:¨lïm•*U‹w	Òe~½ıİòáÆ\‹=BæJXÙn2:$q£îI¾)dò™¥L.xûÑ `f5Ş¯PÓñæƒbŠÉÇİæAa˜J"qE™#ï Gè‰³ø×¢ÎÎd¦”Ê!\Òâw1¬U2¤_ëiÉMêl$ğˆªI99®¢–K+V”}µ†4LJ\‹ÒY{'ü·–S–6„•ƒrÂ(Úe	&¦Ì·¿¨Á}jY“†8ÓgĞ«Æ#X˜¸x^â–€'Vf(¸º%µ£wz(‹ı¡ãÀªU“['Ü¢ïAã¾Éİ‘:“Ğw§ÁğŠ4@ IØ|yÆqú	³ç÷¡6m@b©
Çx°¨V‡âÊÎ bEhî<,rUôª eèÕ´Aè#Ä´Úbl·Ñı5ª?|©æRüêc©à¸T¨
ÈI¹ºªdô)¯Z¨"s¥‚?-=,‰"½ïç,ìKíXcM‹’ÃßO¦%"HåÊÆÁîş5æBGİ–8wP˜’@É‰Æƒ5öã±hãövİSr7p#vïààŒÄkÏvè‹ô|”Ş ®ó¦wU®7ú”Œ,•^FªÂ•qßŠ¥;W¯¹W2sâûÿ¸˜ü—î³¬Ğåÿÿ$æ  £ÏÖİ¾m’|ğşno@áª—/-<J½—‘÷¶3Šø‚G¢ªáµ^å™«Û],‚hşbçTLq¸|ÕÉ^éàt×;2lÇ•xËÂëQO˜šl±®¸§š³ÖIwô€/¯$«K+å">Æ3ÉÌ»Ó‡
ï=r\…
ì3¬àÖ>r6èÁê¤z
mBè4Ì<éáóˆ<?#›H“H*ª‚Â™|DíF(ßg2áéynÉkÇhb¢fÖsÒ2…OŠpgä&.Æ.O²“©¢˜œ‘êqF"TLô¼b‰äÈïy›I>HÆ™é—{3ñYû¶Ğ%$P#0âwê]|J/æ•Èd2>íh©‰Ö`†±¡J©œä}wµºG¢í×÷ñ¥9‡/ÆŞTÃxB]®Òc´D¹AÕ}cßµ·ãX0¹àñ[ëÈE·×gÜV^,JC¥	:0Ç:G$HTå=xû¶/
˜k¶L#ŠÇ#ÉiZà	®#"ÏÂ-Æ{<80HF3‡dãfD_z‰@îqpˆ?¿3ü+ú·óR©£®¿$–‘aos!ÌPz·çúL
9‡õV‚‹J£ÅUÅ[q3÷^©R? a„<ğéÙ#Í<UqQE:ÅXïSQ2czßûú0—û@'WõÁ—8ƒP¹†ÃVœM¼v†¶c:c~‰wBœ"¤šäÂÉ0ò2<Åó¢WŠ’X›zÑóšxy,Ã}ç?|wn‹ã·óóÚEùlÜ<FùëÒMÈº£æ¸jOB;£”Xqü7MÑ¹<JÚÒ–ß*!‘ÑÜ­ğ_p­Ã<Zùj v°N—eµß§t°šx‚Ë˜TXè/4ÉCŠw°Îk‰|Tõ#ˆP½ *¶à½0B.vÔÕ³@5+Ëó´}.áLåëÉ'€ş…Ànß!/‚;½4œ\“Ç‘=¯‘s`Ì¸ !;c&ûºåàO@â–##Iåòæ~¿LYÏ”?];£@'sßõ•' 0³$eÙÂ€°ĞĞ¡‰E.ıç?÷§?‘&v™ĞlbtnçDc¹Z©ŒB%§°	s•ä¡Éôäñ|ŞíŒ@Y«ğ7¡SiVq¦ˆ_SL¥ìG‘I¥õ—İ²µFG¯Qo4ÁLÀ**u;İıô²ÙùÕx^ç}Œ^#Œªõïzd†OÜ¹¿•çC9Y_%ÿ.«,ÍM¤}«tLyU&58<+òl”1I*¨´1ä )­GC®ëÙ¬´A¾NãÍã:ÊéµsòÉÁÁQŸu >´	Z«V·|+%	fÜ*—öÈN$CË@Ğª
*Cxˆ³%z>$25œ(İ±/áYğ~e/5F&{eê÷Âó<õğ9Š{4È:ÚeÌ@¬ÅkÙA@<´#›l_‰q<.¡6W¨#épZègÔ“R•øØS—øL‹e·Õ6¥³Ï(Ğ<ŸŸâ×üâ2juyÙFÙ˜ÎKwe,Ï+è.¨ "Â‘qqdKóò”£l!]åj<ÊóíJ	,*-Ü/çü2TæD¶y—ŠØ=ËÎ’
‰B\*Ê¤s.=Û0İ#2{'½â;é|ÿ®Ò¯Ëø×Á%W¸FÜ¤Ç'ÀÁ·ÔÌÜ—–aÖê§$@Ègü™ÄûNİ¡Rìp˜?ÛIKH\^¦4“zô	Š´_i
MÚ›YÓ„KºKjbæFÍ×<ÂÅÓ+Î’£iÔ‘s÷Ì\ì‘íYùÈö,¼QûŸóâÉÇº_Èu<“w‡3QÓ)¥}¶ß›ıMôì7µ‚”#cşüeµŠé¤Ök¾võ¤É¡Ş'çúú;´3mf5OWƒq¢ŒvyERb¼‘çœÅ6 %õÚ_bˆÊ\ÂØ?ï˜®ÒeQq&¯ÎGi{ÀZ^!EÏNtu%Wı£QÑ)h¤Ã¬Ò*%öÜªâ²ãy¼ª™G¸&Hµàj&7n³íõÁš!{mÂúsÔÖ·sJmR¦ØÓ£1ñS/Ÿ™†ï“Êè÷K&ÒiA%<¸àŒ^lJ\FüNeø2›Áˆ—işoÆ®²ç±z…ÆûÃÙ£a£KĞà"eµVÿ´If³tM—»ôt‹oj™&î³‹Ù_Îd{³‚OIo:éÆQ+;&ºIïŸãš:ô•µ„(9T&/Ëû„†<gi|õ¢”X½ä"a­ª¤lg«S"IÜ5ºD:µú6k™H‰4-dPúÅ?¸Ş?Nø¤/Aİ¤ÄÎFP¾ÉL*-+`I·´z“à9$Àä—Şÿ †1„·hAØÕ¥ÕXÚ“/ÄW€}ÿïÅ%ï«É¤T”,Z+cL•\AëYÈt€•Íg!ÛY >h<‹°œr-h!óÙå´âUÌnı§®qcPh†c¯éxDŸëŸÂüÙ˜Ûå³Q¤ûKX5Œ5óğ…ƒqÒòé<ãšW]jä‡ŠVƒ¤²ŒÙÆ“'$f^÷øt]âÀu·ÖgÔfIÉuUÕšÍ`MpË:‘ŸoLß½Gs8ü	eôK4 ·õN„	YÙÂ¤ âÈ†-mÌ§ú„œ¸s][*),V>ÚÊÎÃW;é£%ñ°z°»Ğ+”uY8HMOÃú÷ÌÏ¤2‚ŸIMdòœğ¤§(y÷½:8uIŒ Çô ¸bÒ”À•ô1äñ´U²¼ô ¼plVC¤Àå#h2¸”CœüæééYÈ6Î§T¥¨®İ‚%I"FÉ!¥‡³¨Öj?‹š> ¨@¾Ú Ş	­‹¢òETEbP²¹-:”ßŒeéQ@ÜFáÆô(pÙ‘à®€ËRD\2Vê €_HøT€î÷xéô"'e‡ªäx”ÀÛÇsÚü|z—ô,ÂtîİyD}M¼Í¿ İ\ÍK<QóÊ‡»é{©è¶Ÿ½Õó›ï,˜"•ˆÇÃ¥¶¬¶’Mv’™‡CÇğY7â€KyÔì@v½á«õbd¡ÒéJÖûèWG7§ñİ&Ûo¥Îv4,'_GiX¨dR@ÚZÍº…] äéSĞØJ[›%/Ò9…§@w
tæ2óÅ¹Ùü÷25ŸY nÄ_‹bMzL*ÇÜ4â˜y9Ç°Ìšù™ì“Bv6Ëş–]hğõW]|ozüN:Ÿã»Y©+óÌZ©à>>)ı™²í{SÌ:”í«K]6ˆ·ğöÕ§ğ†h¶cKïĞ ©—±QÅNoŞÇHùùÔ‡ìbŸ…êº )—XydºøÄÚ ‹Ç~PzòÌ²ß
—ĞÏÁÛ¾ÍŠ¤ä‚´{‡áäL±ÖÅt£dA'ÑÂ{_²Åà!2İö~zgİ$¾VÈ	;ALc"iÃêv-s„YqF­ò4]˜Ö	…Û×˜‹©””.	ÌÇQõšñ±ó:FÕıéÓ€¿†i‘®æ6Ú‹¤«k&JVÍ…
™Mƒ.Ñ)ºáºâ°¿ÉHÂÑ²ğ
*&ˆDæl^ê+e–DßR‰zÉ¿šÎßPše7e':üo²Í‹lF7+eYYÃl)‹w˜è¾"3¬IiõCKwÑÜ™Ì ÷(Ë‘…,*ì_®T'ÚÙT¸üif©CaoÛ4òô‹×|nÛo>A'"ë	ô$Gg Uš	˜¤…İeÕlWÁë”EƒRc||mZfZ¡÷-ûD³›¼Ïs ;Ip\£ñŒ^Ğİ£“¸kAŞ6-¼L©¨¿'K“Š7\ d`yyLhÑum8Œ/EıüµN¸œ’õ¼:‘ò	BğÅ¥Ü5¾Krä[Ä¶Éˆ¾€WÄab6#ıº¯;›]qé×Ÿƒ"îğyâĞ×Ødìô„©Ÿ(švÜå+»‡,øw­z°?Š;–BƒpÌšWĞ…÷¼9“¼¸ò!wµ!¢İÒ†dZ
d»^C²|éøÎL+\İ†d»K[€#1ÏCŸ'± D¾óZ‹ƒ0Ğe-n[â"..ƒ
9ÛÅs2ïÂU‰Ø°¢ v¾vÕÚÁ“²Êğ~Q,ùònÏ÷rğ±'›$2=ù}ôB	LÍ¨®ÑŞ$©ù >`quñ›‚qÛuÁt•“¤YPŠ61¸O³‘ü>­]›¼<Áqö5†¢¢ó„;|Lãáõ{ŒÇçQí‰‡È>7g…¶š|‘gHm 0×ÔuÉ5u]qM]÷xø=(Fñ>ûE7UiÈNé±}t[?6`.¦u0L3êZá3]÷ïÃà‡¹EKQİã®Q m[gëpE97M¼‹TşJb¨ GâYFï€?¯Ê¹•ïtêFáë3”®}$ŒQ8_“/qİãy¿R:ğîXFß¨4??íéAìê_>‹padRÃ;y¯Eq×i{PâPN)Ë*p±¼còB1„e(£8ÿ=r›†ƒyd|!¬ë#71ã¸±øRôzád*åtH¥¿
öĞÎ}ìÁ)ëU±û'£)^¨eF9ÍH.Ü2×ÛïÃ"bÍFDª†ÌÂÅ;FÔJgŠÌ54P‘Du=Ö!µn˜ëjÖåhü½ˆ$v¾•ÛØ	±á$×ŞºG‘¢°Êhğ,îìkë4Îš¿ ‡Z®|/›UÂ40(«G‰‘i	†ázj¸†÷Âè¡Q#á3"·täÇÊ¢ñ±â[“GĞCzÆöxcÃTiÒ0œ#:0'56?‹¼8€øìH²Ô­N×1¾Ë#®âÇÒ0ZÇÆ‚‹õ)øHVwG&#FéLLd¦€Øîis‚[2”‡ÃøëhñTSr”º\cÔz'ÍŒûÜJÊìRÔs£…a‘PùõÀX[.516êµ@ç$uw‰DC™ººA•İÂÂ±—Rd¾WŠ$f,Z@ò:ïiZìe—1ìş/¼/GÜÿ³FïÿÉ¯¬.M‘•Ë&Ÿoøı?Øÿ°Ü)oW2İæ%•—<-/ÇõÿÒÚštÿëÿ¥ÜÊäş·+y¦©Ñ= ’Ş½JÔRB÷«q†á×íTÌã¿÷§şÕR@L65»i|%ÎÙİ½¹ƒ:ƒy[ÿ4Bµ/vÙÅ|m†±òi€<ªØôüÃì¸/Á;˜œ†ÖÓ)uğŞŸV[93Ï¯ÓÁ2Tµ:±z×ß`õ°İMÅĞYä¾ˆèÃ›ºFèw·O	÷'ôı©Õ‡µF@#N÷Îi; İ¤×q*3»¸„ß¤ã]–M½i½ 6*µxã¹†„Ğÿşœ¢¯ÛTJìX4(¢iÀ´t¤ÃìcëJ3–E3*íL]1JÕíEZş"zĞ‡£¸»–-4Ó“¶Ñ N44u[ëPµ­© >SıAc½«K•È$“‚i0;PÀâI3O{ì¦…ï«…Ş,‹,Œ,3 öùI?vóåRï›êLÅ5]h¬¶ºÙqí~Û€6ã/z­O¯&Š(oš2ºFG³‘OĞ‡’04@€‹°¼Ø†÷K²IOlÃuu3à•iÌ§•YõÊ–aöŸ“‡Ûïÿ% 
i,Ó[•(W3 ¡i¾}ÍéÕu*¶g (ë7šjh&ùTwœÓlÕµA—jÓò6ÕÌiD^»oÒî1OY|nF|O<h‰Ó¸¹ÒïºË‹PAıJûLuDc«Ãîõâ‡®ı¦#Ü~^ç±¡[3äh‰¨·´ ;ó…æƒ±ŞƒÆ¢å°şBõ«_Ñè˜­úc@·ş›,yŒ:W£éèOI¶ŸËg6ŒÕf6\I·“xQU:ŸOç—jùåõÂûë+ïÓ +ûx«®Ë¬#‘uî!$¹L~‘‡_ÓËCt €Cç&ìt):â Ì‡ÖÒ£yœn?…¿uò‘ä·÷)ˆ@ÃË¡˜²ï"¶®÷Şğà¥ß#t!#EÜ¾ût`AC¨HûĞ¡‡Ö™Ì¹xÓ[/héóÃĞÇ£ÓMÊ» ˆêİ®ÕÔ‡a´©ŒM>;á¹QeÈ6NqTèhv«OÇ»ªn@QÃÉ$Á¤Œ7Ö	P¶oºRKô\ "„øÈ¤ŠÌ‰°Ş-ó™aE4YT6ªz‘\t~cÎóöò+AEAìÖõWiC? iÌMv¨X0“†+?ÁÙ/ïFe~·/…aQbáïÃùÍqO½U@(cûj£c{eé‹ùÔ°#ÆåÙeNT™ìÕğB¢X5äbc
õuDë½:Ê£¤ÓÚòÉ>šé²]£ÙìèØëCË¾Œ–¾¸İ²Zt\'Y·ÛÍq«…“d2¹)OÍúsªfôÂHšz×.Äjezüd||#ËÏäK×¸`¢ƒ‹´S®ÍI`~Û0r7£s/àÌ½@æ„:Æ"	sz­ˆÖyL¡tÓ¶<uæ~K/ö£ëTY½­>á‹‘ú(J¥MèfkÉeAûÈ²d®^0J„‚ÁôÇHãg‘ Æ¡¤&Å…ı~:WHçWkùÜúÊòznå|úH>“Ëä„F2–ÒÏ¡¿Äf.«d±¨
sÒ’‹ G;Ö	şòÌ”4’¡ÄÒ1Es$Å`F!fHù9Š¨³™E7»æ:.>K¾ 	u(²8B†åõ¦ñpŞ¡ùB`y™~(ÎaüùT¥šÎ‘#ôŸ'±•ÜLÂAü²Øöç·X‚J=Ô‹*«\d9
båhîXGB¦ˆ›^Ó–ı²ù,Ÿy?“«åW1ù—½†9/^†DÉç5&,é¾¶ÙøÍ>ÁBºnˆøq°è}Fçã­&h¤ÑkØPŒÊ–(xøhŠÎ7Â8ŠÎ8š ZßQFß=J#Ûuc™qjpé<#†Êû–q´ãÁ,ágôvmYnñó<(‚û˜S u8Â
•iĞà—Y¹!•€³èÍYúÇßÇÂ!)RØNœœÂ¸@JáÖóhaÉ†nãA&4p:Ù$î"$•­„$î Ò?Á;z¥ÄàoyÿW$Óë”Ø×@%;F=›„Q™Mz·Ë_1Ø”ü›Räÿl€€É4å”ª5à?¹LBdµlÚLWÁ™ZD
û`7fz§1˜ BajÔD¤ø¤ãÔhŒsÕhè÷BÀÚN/ğ Å*,Á7ĞÁb´F ¥‡0=À—†íÈ‰û:SÒ¡ÿğ^^½9úˆ¬ŠŒìF_ªÎÓ€a¶®ÜÔ«$…lPq8¨¥ñõSˆæP”Í_UJæ¤^›¤ì!¥Š}_ë­Imò4”šÂßŞ]FâêPsÙ·¡Ú7Ğ7¶[FG½c4î~Ñ€ƒË9nõ®”äWkâF;¶9‘d± ©˜Ê©
ÃnW¤iJu.QÂ]ëàé×«;üÅ8Ãë)6ÖĞ[\4ïİ@¼]í™NÜ›¾ÂˆTÔ-ßhµİgSe§Œš‘ëbfıÀí Ëìœ
æv\½G´#W÷V‘È‚ên%Çß—RÇ@–dÄW¦¸.dÈ§«^<.…şd`Ôˆ¡ã÷ºA=È‚g^å‚)fVY¯:L’dÄÛx¹OûˆWòéRŞ‘Ï½}Ï¿E7MO¡{ì<?d”ËÎXgzÃ_J&#lë’İh®N÷“É{§]cAli¡±wÃO,û3+ãÙÙ@Å,WÜ0æí¨ö>İ¥·V =ÌÆ%[Ñ2°è!¨FiüâQıÙ8ÒM‡;¢YF)·pëÂÂİ1Eî¤.Ò«oıMUÅX›ÁH.Ì¯q1Ò,dÌ:¤a÷ñ,ü";ë»à2.¬#Û2c^†ìz·+‡?OŒÛ\qlS“£dòó,BN$lBæÑ:0ÄMp£6ÎF·B.
´EaÁ]ägöÊ‰„5B¬á5#Øi{È}ªĞğ½gf)VÜ%ä©0Ô=™dò%EAÏKRÖ™hAXL À_1ò2˜‚€¾ø–1ÒıºË·ğÅ·HfÔ>õ~ûS¶Çm6:0tS–Ìë*5ö³ĞBbßúkĞ»Ó€)¼Q™¡âË®@ÍıÛAUJù`¡y[éS?ëLÜç˜FÅäE¾%Ã¾cˆ,êÂbYøn'tùÃ	b„**eD«²©!ØÃøF(sĞu.p^LÔ¢ËÃÑúÛYÍ>ú|(ÆPás€’ NğÄ½¦ú› G¿ï»­™-½™![¯’u®ÀÏxFHœÕ0ñ±‚*8¡µßƒ¡«yñ}•–À‘9Ô™y\uT«§p\ğnæ`² Zcª SFdš^¡Û$¢ÕšUuÜ™¦³(¬uCNL~Ô‘Å@›kóí¬&¦S#7ÔúÔ@:…wõç®h´ …B4ZL3ñFŒl­PİB^ÜQ½–ñíÌêâP -àåI”l­¦“¯#È|É&…²doÄfEåÀ+—é«ş|àIÍÅálEİÒÄ¥¹˜NE+»é”ÊàÙ¶Ø¹Ğ•]
UêQ+(Hİû°”åîH÷;úsçVYİ™§X§':9ÉaEƒ‚š™óîáÏÁOhZ‹Œî"'=2 ô|@Š–7‘ÉL£iÕ½H?ğgpË-²Ö;È8âxo›µ'ÅĞ˜YMşù*EË›çrè©§è¢ÁæLªtÉ‘ñÈmÅµL~q0‘ÉCÕMˆS¡IPµJQbÓ’¬ïâ”¥ê¤\E‡2ºVßt™>Cõn€d4úè
h0X©s=ÇWN=u/èzB	ºğ¦h\ÑÕ^ËÒ•<å¸Ú²ÊÏÀäİñaíÌ—ş|WÆk;1»Ç?”†pŒB%7ë¥†òT¹¦äêdµÖ‘{ ,w€İ¥‘ŞøZK¶B11øøb´¸_£Ù »ÂÛ=¥a¾ôcIûr2>½\,¨T¼ÄV\¤ÍD›Sr‰#Wî¥8zi¡b“
Eş–ÀoV(¾U£Eµ¨ø'º?hQ0<†0Ôo.ª~*”³nT-:*T©¹8Ş*oŞ§Ìh}i·¶_œ<iCdòdpy
Bƒ
môƒ*¹<EncG0ñ{h²õ…¿ßæÍ>¨ùäó¡Yb$DnGÖ;j×xy9çSxÏ„ªp¡òäâD@«kÔiEyF‰ğ)S3£(Keª¸éWf3ˆä…AS-÷C%‹(<,T¸6\b…j~1
âŸ—B?Gx„Nqv5è*(°‡YÀãx£ÍX -á`¬B§:jHµM6£h€‚â&åU¹ÒÅIˆÛ‡â}%ƒ…GNã¬ğÎğÂA’Kªø–5ZÉtÑòĞ_ xš~]waõ±LµMœ¸ú¨[Ç:]D¯ãÑóÏ§³K ††Äà×Ë÷Õ+bŞC@/ÏUĞğåÖQÀÙÕÕÁbš1óAéC$N°F´Ër>W Ê
T>úªö8?Ëâ(…ÎÇòò#"Ñóò•’ØeI~%¸å’æ!
Æ©BäÛÔ†£D±B´ÄGˆu…Ô³õBÆ{1ªå8¬¼ì)ÂÇÁ#EY)ğ^ıHi:1ê¡ïX™íâ†õE…pñ¡µ£ëHÑÊ}ÊC÷sÓ,»Cİç[ÔÙ‰4Wg ØÔ §5Új?{Ç´Ğø‚t‡kºæ°Øe¶6:ş”‰Š2†É6.M~šJ.Á³I‘Hi„:ºúÚÙ _L‘X’¼‰&WÓ¢šˆ†ï¨Ñ¯‰X`}ÚÁ}?Ë­Aï¦Š4ÒdÀ‘ê#"eq¹|œ1,@Ø»Ñpòs…Vß•cø×8ÄôjØ‘PËl(ıl ÑÏüı1wšµ–Æd~@ÏTºàjÂó¦èû1-‚èûˆÖá7e°#,ŞíöòDå_„+#¾Ãû’ùÜ-	¸ÁÒÊ‡L·¤Dàûˆ®^^É·x„¨á¦ñ+<¼ëœŒ.v‡&Tfú#a$&V<T×ajğwa3Êø«šÙù¾!; *™ÖïVf‹EÍ
èõlì,—or7ÅÂ»iC˜ç¹ÃJáûh´òqZŞ–«×r”åŞ+\^Ğ®'›ƒNûÜOˆ²
u©÷[8\p¥€ê6ò¥€GW„TúIch#LTŠƒÖŠhÈÇà³_ŸÅ( ¯"µ˜k»nÏYÏf‘ĞL‹A;w³T‚Zš³ï¦i.';¿L.ÇáêÉ’},KoÛÃó=Î2ĞyÌîôë]ƒE¨¦©çÈŸ…Ló´á¶ŒnÌ'a€Òi
·}XR“ôMzZ:ªÔƒ)JÀ‹Dè(drò…Õ‘rJ¬:İö× C{§¢‹y¢¹ä#$¨;99ÉhaÆ²[Y^œ“İÚÜ¨ìT+i@ztó‹ŸÿGºñEˆ~Fÿ‘_)¬
ÿ#?‰ÿqO”å¸Ëÿ#·¼´šçı¿–[Ê­@ÿ/¯-¯Lâ\Å3ı.u|FİÑF›£Gz ÛÌfsÌŒ­¦¤ô`‘ÜCTTrËxÛ‰Õ£óÕ{¤Êç¤¹{åê<ä©jzcàÓHØÂ‹ä}7äAGsİºİoµI&®¯tCŒh4HdØ³rË€÷¥¾ê_uõ#´KÓéˆÌ2:®–aSÔÇ.oœ¶ w¥i¸^î™-Íq7˜_Á½SÖet9ÏD à²¯8O…@Ä¦Ü†Dwí¸Ç¼NÆ
[.h]¼DÉIˆzáÖcKwıİühn€¡ÁiÀ#èB\FÚ¨ãí"¨'ùÄ@?öÓuø™ÿ “[ËrùUĞ;A8ĞÉ)í"ôÌØ	H‹SPwğ‹b»â„zî¡ÆöYÅ÷7×mÓQ †n	«Pl<øºğÕuß;79AÅÃ{P]mòã¿<:N?ÂM:ê1NÑyş™âx¾â&›ae;¾`îBğfÚ.:û:±T2Ú>$ÉÕZl¾µUc×›nş¢t°¹»“
µg9!ãp$Ş&0| •û»ÒU(ßëW,ô‹Ê~pğHÅòp¢aB‰ ™ºwÏ‘!"Õ^ÌNU‹esà|µãaSJ¤)æ˜HúÂ†|©ÂòŒ„•o¾ÇÉ­I½"m±œ¡ÚˆR<µt6óB¨é%ˆ/¼ß&áÃİ5ºyEAÃÇe§Xe_7P¦ê×‡‡iôÂĞéaj…À†Æ@´xÊqš".[ìf2fùÒÌS\¶pÂ(ôî„lqtjxÈŒ]š~9Èï^k°Å×ğÁ¦nÂañÊ¢ÿç
«|ıW€ok¸ş[Î//Môÿ+y¾ıƒïN½55µ­5Èn•|.¤¦Mİ„ø÷ø‡¿ÿ­ÑP–öùWÌñ¯À¿Û„ŸşĞ2PÏt@ëD<˜4½WE@íoê¿ÀÏÊÿ_úJõœ<‘Oà0î¥”1dü¯­Öãim2ş¯æ¹¬õÿ¥Y ŞP@œàÍ6 ¨GêîócÅâÔİ± şGqnùì~qÿÛw›Ò!lIà«@'¨xÔó1“ÂmÜQä>îğê²¯AÜPŠ—ªIÇ¸}ŸŸó†CçÔtµç¬–ö‹ñôÒØ	áà«ùâì“şÇOÚëON²äq ûS2+ Ívàòÿ˜Ş¨¥µ~rG¹ic”’Œzä­_@#àßÆÁoÓòaÛ‘°@'ú„ùVİ'9@‘|ÅƒÅp Ğ	äXü"ĞC²XˆzÉ´½;Ë¢o‘añÒQ„õÄƒÑª,YÊ›û^÷z¦…3n%pB—©I*ŸSŸ—Ü‘2|æ4Ù ËZÜíé_¡g¯ägÇñ³•hWÊoKoĞr'¢WZAËDñóÓ¯Š³ôkšŠh˜3ÌÙKür®°ßš¼«çè¦½zuÄÃÕøµè,ûŒŒ±ÀlJĞ€J%é­ß|£$Àl#x]"—³P[ ICÛÛ¡oS²DHIoñxDéR p8…¡ğ~3
GW
¯O›Mz`F;ªRªN,7f$èÆ`h6 }x+J“Ññ_kõØf‚‘ 
Ôt8òZ­Õ+Îz÷z‰V›¥J—"ŠwğF8Hˆ$hª-<²µ…·ömŒ<˜›_Ò0éP¦8‹/š$³ ƒ¥au,»¨õ]ËˆFS÷ŞÛAÇµ½$‡%Eas:dÆÌuJB'“rŒÏ-ñÆÕ€÷…Sd[Éf†,só³ëçËN]Â¤ì¶Ş;ÉIËÇâœ‡ïC&PVqöØİ«ãju¯©¨#c‹¾Çı`zgW°tZø*ğ$R9/»M¦Ó®3C©Iƒdh–wHªaıóÛ­âï…Ã0U¦=‡K™§ß½^bà%ĞĞÕìSAVÓqê¹’^SÛ ?*RáyšNSçpSDhæ	*BÁ%è\],ÔÁZªÌÌœø:?¸:³o•Y¶ÿÊNoã,cDûïR~i©°¼ºLrù••¥Éı/Wó¼æö_“Ûÿáo7¦_©“'ò‰¾8Ş2†ŒÿÂÚZhüÃ·Éø¿Šgbÿ½^û¯òôki–½îXƒƒ¦`ù¨ÜÄ|qŞtsğHæÅë3Ÿ2ÍNq ¿Ñ£coˆW[Ô#}˜K:†vBşûQ–/o¦ÿ/–Øı¹Õ<Î¹|amy¢ÿ_ÉÃî”‚2/H’g·-øGçqîÂş‚FØÛƒŠ‰KRbÕK]æ©%ºä©+<u_Z¦‹w«xÅˆ·úwO{xŠ¡ñşFøƒ—¤v¼½ºœ>ïX"IÿÒ—õüÒû¬çW—V×—áYÿø	xßœµû8èĞêã-c˜ş¿²"ÿÉåÑÿkem2ş¯ä™œÿ¸–óÁ«ŞTÍ?æH´¢>92€ñjêW£§'Ç¬z¿>Š7«Xe÷şx^·œ{ğú”Ë.#7Úù_Pû—×rù<=ÿ‹÷¿OÎÿ^şãßSpyeŒØÿ¸ş[†¿èÿã¤ÿ¯â	Üús)eœü/­å“ş¿ŠGº§¤–)Wkô:¦1—1Ìş“_ãã¿°²¶²¶JÏÿò“õß•<£ìÿŞŸbû¿Ï1ƒ€ø8¸§ë=Òşïs‘kò¼4ş/iôÿ…å\n98şWpşŸŒÿ+y÷úÍ<ŒkøzcŠ}ŞşÇ¢Aoğ¡ç-şù£)êÛ¢ÁÒ;­|µau{ã&xòLÉ3y&Ïä™<cyìãÆ­ë%còLÉó>(ÿü˜ş!ûLğ÷oñÏ·¥<·ù'áŸóÏ?dŸ	÷ÿ|›ŞàŸ·ù'áŸóÏ?dŸ\h%øâ#ÁKNğJ‚(„~|®*OÉózpíş©Æ”=¥Oiáõûwş~ğ}×*—›}·15õ·ÿÆ?ø['ü¾9ğ}¯-ã§£•½·¦Ì©ÌTS-ÿ»7‚ï¥òşÑŸ
å—Ê|Qş·€6wªQ?qzõ…>‘ÿU½×17—ûo}ëíoç»7nÜ¸uãİxZm['Uz¼ìf?Æ_x!b?°¬÷]«?4ô“ÚíßÛÊÑÌFS'³iÜ³úfÓy,½¸yóæ›µÛ?~ñbùƒåE²´š;[$/ò¹Ü‹dueùììæŞÉ7Õ=ıêÅË³ßü%V!§~7Ğ¿Ù¯ŸÚ²Ë?–Ş8Ç¬æoı7¢æÿ£¨ùÍä­[ìÖg[ŸmïìÖnßî;ú¾Ş¡ãĞ‹Ä©İş]¾Ù°Ì=[?†*?jàMx&¼ù^Cëàe®^êtªÆWºa[ÎåèìñÅç¸ŸïB¯>ÿ…cÙîEö¹øÔ÷±Œ]šŞáa¶oŞü7~ç‡03—.¬}TºÿÛß½ı½ïßú½[?x„,õ~xb4İöšÓĞé}î¿€¦6ñ".İ¾ù½·~tó O÷ıöû?úñO~ÿ§ï¼„X>ï×_÷÷ôöô¬Œwß™¾yûn<Á£KÛV“†“§oŞy÷Ù7cú=ßüí÷oïwçŞ¹uà@-nk7nÒ”LöÖ­ƒgÀ·›,eiùÖ;‡­®wn7oŞ IïpëGÜıäög<±x÷Ö;ŸópñÎ÷‹7Mïl¼S¹qû¿¸ñK,İyv{º	ÅÿäG?Fª6oÜøß”šM½yÓ;\5ıñûB›búcn„½³ò;S¹©{SŸNırª7u:õg¦şù©¿2õ7§şhêß™ú§şë©ÿ~êïLıı©0õ§ş©ÿsêÿI$ßM|/ñãD*1“¸“x/‘Mä…ÄRâãÄfâÓÄg‰G‰_%ôD+ÑN	;q’8M|•x‘øS‰6ñÏ%şlâÏ%ş…Ä_IüÕÄ_KüõÄ¿™ø£ÄßJü{‰?ñŸ$şÓÄ–øÏ;ñ?'ş—ÄßMüo‰ÿ=ñ'şÑ[ßz‹[,ßÜ¿§2ÿ[¿£ğ8İoıÅÿdó“O?{ïµåñ¿ó;ØÁÿøïı?ø!¹³Yz¿xÏc€@w+)³!å>Æ^”í[±!ÀFÀ­?ˆ8‡C~¹íöwûû?şÉŞMıô§·‘ßnĞŸïÍşôÖí‰›ôçÏfáí[ğßÊı´pÿö·X9+·Ön ‹ßş6{»~ë£›0n¿ÍŞşüVéğúíïPDå[·nOáX½9”i²ì9õßMı]`×ÿwêÿK|;‘L|?ñÃIÌ%2‰÷w?OÜKl$*‰Ä^b?QM$&j	-QO4„™°=Ê°/g‰?™øg:ñg€m‘iÿÅÄ_JüåÄ¿œøWÿZâo$şuÊ¼ÿ.°îøÿ0ï›øm€U·TVMüO>«JSÜ¿ı;ÿÔşIùM3æ:­ıiZ;®ÚfÇ2[SLk{ª3Õœ2¦Ôéàíß—ßEL²Ò»Ğë½‹˜\oÁ;kªE'`—© áişíñ´ÄB†(‹Œ sòLÉ3y&Ïäù†<ßbíÿ•øıÿÉ3y&Ï×øI¼]®–ïMy‚¡míşıJd˜¼ğsšãiK×k³0YÿOÖÿßğõÿäùæ>¾ÿïåİ9úùŸ•µ\ÿYYY™œÿ¸ŠÇï˜ŒÌLó2Xàüçğ*ÈIÿ_Å#ùÿË°µŒ!çò¹ü‹ÿ¶¼²ºRÀş_Y^^øÿ_Å3­^¼‡§ğËûÄ=Ù³ëÈ»-Ü8"1ÑoÃØòôC7“73~bòÈ@T‡ˆŞ Ñåp\ˆ[Şí÷”İ²µ®“Lî•>)Îàßõg”Íx¡¾yö$n
 8z½­7ù7ç!ê¥ÑK²½{
İ))ŠxŠI*åQOˆ¨ ±PJ+C’‰‚€7zÇÑ)€Şh[$UÙßßİÇØhâÚDJSdNh,Ö^âæq9ë?VñĞSˆÇ±úvƒ]ó'5zrhæoVì›É£œÿ…Ah¹&dÜJÀùç˜&ç¿¯ä‘õ?4\£ş·œÏ-­åÖ0şÛray¢ÿ_ÉêöQ£Ö2½Óq”1Dÿ[ZZ¦ñÿòô_ï[ËMÎ_Í3®˜9ÁÀ\›æ‘­9®İo¸}[çü›¤ªÛÇäzm1¹‚á¸?ŞX\Jî`.˜òÖ2ùB&·¿³Ue!n]KÜ­C‰%e#ŞbmEÊÚ‚F7½p½åòÉgrägäÁŞòÇÙ¶ÂÖÌiqt´—Ø¼z¤Í"lÑ¸MxË
1LøÚåñ¾L~s°“í÷ĞXœr°[ŞÍøµ¥F—.",GR¼#C'›´™kôú!W†ÃfZº;7[Şİ.mîÔvJÛ•ÙE’…ÚéÖX¾Ô¼@ĞÓÜö¸8@Ù~.ŸeÙœì'Eî‰Šù$½½‚Ş|CFÃtç‚XÙ½;xG"]ƒµvj^dvœÈ?(sµº%å/øùû¸¶‹«Ë{X­ìcÆ½Ú¥ÑHy„Ãˆ÷ò¦8•¥jõÑî~0ÉÍ2ş¦£•Â®“Çwœ§³Æø0 ¾'š9àƒûaII Üoİ 4´Ï„æÍég8ôÛ'=¶Ÿ-n"‰ƒÆhÿv­G[U1şY
	,eÕwËâáU½¦–Úa1IBè'¿MX6¿=åBN‘Ri—A±¥v¤Áå·Ï°\~«CíTyRZéàº§Ø×ú‰^ÿücCô?˜Cë¿IüŸ+z&—>\õ¥ol¬×-! ¼ ­lv¡a]XPn9vi0,±zÕ7.ä3ùÜ•Ş¸ º[.«õzYv!·³b M>Îî Åë‡ 2#÷€ì3
ø‚Î—¸ùoÃØ ?º†#¥e=£¿XWèt )®ärÏ’gÃï7ô	íÿwê§Ï0ûÏrhş_^]Ä¿’g2ÿOæÿQoyñ¥Ug÷;Mæ{‰„qã;ÑõgSrÔïtÓ0¾¿ì¾éÅÈçb·pÄø/ÍÇÔ­~ğc¡Ğ8m’vÉıÃ­-’î"ŸĞÍº–i´Éİ»$ëv{28^ÅU¸û^>y	Í×Ôh=ÃlØ:ò¥v}˜[,,.-./®,®^¨97w6ö+Û•ƒÒëÒªÜõâêZ²P -¹0jûqµÛï<vİóğu=ªÿçIÇ©QÛuÆa5c)c˜ş·RXæúßÊr~îÿQÿ¿‰şwùÏØ,^ßuÎÀkÔÎ°tÔcÒ’v
JˆÿNÒÖ2Q:Û¢ª®Í%MÖÈŠÜZÚ¢çÒM@„‘T2“§;s²&Ş‚N#^p3°)6É¡-­–æœİ†Û!º‰›Z¬¦ŠJÚ›È§ÜÊI/ñÿ5"¤†O‚Æ‹hÆ$6P‹;‚*6ÿ7d	İ—½“9º“1Ÿ!¥æ—0:	İ -Û‚}û,Mİ]«ëG¸¥ˆ‹˜–ÜLrZŞdwQ÷FvmèºòŞé7-Òè…ù &ÇÎvŒz–W“fTXëRü,gDÑ¡²] ©
‡µoêZÃîrG/¥É³+¦Šş˜2VÒÕÌ¾Öˆœ:q€Úê³Ññ¥À~`_˜rŒÏÜ¸XãËxøİUÄÖ;:»’ŠÀZV*X©I>u‡´­Ü´f#İÉÇ( &Ë:ãb ¿ˆ‚Tˆ+“4ÓuŠ¦îXö³ôSKw“¥#W·ƒ‰$ù˜Ëå§ÉƒÓ^tàz÷ØŠLÍJ>ÀX´øõ\ÉG™7Š‹Aµ‡-º	ïo/)äãÉÊs½Ayîüy³”íéõ-Ü
DÏU†Ìê] Wâ³z2: Ëljvs·ïöún¸í«ĞN\„<¥­‹kîb·ßq4Ã›óºçôó<ªş'î¤:Æ{ ‡èËK«y~ÿãZn)·úßêÚòÒDÿ»ŠgrÿãµÜÿ¨Œ²7Ö"sû#™ÜşxÒzÚ ¡du¯X+\Û='äÔêƒ²u
Š—Õèê¾_Úr:F´d(úÃÔmUcè+• ŠÍi{Yêº®òº³hDìøyz‡!e)z9Eç9!z+½®CÊ°2ÚºÊLÛÁÌ ­×ø;rbÀ´.íX3:´@©ä6Å‡$¹Z‹Ğ+Ó·¶j‡ÕƒİíÍ_”6ww`­À ö,‡y—Z
×2J›PÀİıÒÆV…:â«æFˆåğ¥Òé/RÅpq°•š
Ã)N1ù+'ç„P"ÈCV.”BÈ‘¿rÂÚ55W[ôy‹ê¿ãaó.›§4J¤‰œñô	b²ŠµWxã³Ã=Qo	+·ÛÇÉ å^AOÊpC¨6b¶k4›ıD³uõıíGı…Pc^ŠïÓÒÃ’L¨‚ïK`fX@tYÑ[»|¡u@‘7id
ºil™œ¡|§Š¯r°1 ê‚\ †2°…)[TF0/^X±‚@¹^§Âë¥ÊG§ç
3c—¦Eò»ßXCoÌ£êÿ\ flgœ—6Ñÿñ¸¿°ÿ
¹õÿ[šÜÿu%ÏãÊÎƒÍÊÓä¾îô@Òël{—Gš)æ39ö_òñƒÊNesãi²ZÙ8Üß<ø¢v¸²·R­=Ü,Õ¶¿`Â­z¸‡îâÅ#­ãŒÿ&¹É3î'jı?Æ¥?}†Œÿµ•Â[ÿ
«9ºÿ³²¶<ñÿ½’ç²ÖÿW ²#¬ o¶`Cq¦3è†"ŠZ€{‘ÇªpÙ¡˜ÿá¡§Ã²gÂv"-	|ßĞ|Û9Eûz“®bä‚ 'Û¸½ğ°œF‚y|-îHWkFÀ½ÔÂ«° —\³ÈC¯Õ/R§ê©éjÏY<,íj¾>vÂETj¾8û¤ÿñ“öú““,yÌBVˆ…çÙS2+ ÍvŞú‹ª3ÿVTóÕè!3	 ^”baøÉ¼µ»QÚ:¥$£,*€ÒhXHâ‹,	¶	+tâ‘ÁÚÎñ!­ºOr€"-ø*KO	 Ğà½X!zù =$‹…¨—Lqs'¬º!6vwîÚ ¬'ŒVeÉ’PŞÜ÷º×3-œq+“°”Œ ò9ª¯q`Œ…º¬eán¾¢án¼1'ğ³•hWÊoKoĞ–xĞWLê e¢øùéWÅYú5ME4Ìæì%ˆ@~Bf0V.•ÌZ£MÍNÂú“ÄT-~cÖ¶6«gIBšV’™$0ûŒ1BØ€J%›–©ó`9(fM)f= ¶ ’†¶ÿ¶Cß¦d‰’Şf€‚0Ò¥@áp
CAª…£+© åí¨J¨6:±@Ş˜‘ ƒ¡Ù€ôáA¬(MF{Ä­Õc›=jD‚*@RÓyâÈkµV¯8ÛÒ]z.Õ«PËj³TfS­¡M¼ƒ7èú×Ö;=‘Mµµ"ikV²ÅÒ‘sóKz2İÊgñE“d`°4¬eµ¾ky ÑhêŞ{›!è¸¶—ä°¤(lN‡ƒƒÌ˜Y b\Íè´I
9ÆçOˆxãjÀû,Ïf[Éf†¬Ö@k¾Ÿ]?_vİ¶-[Ênë½ó!€ƒUö±8çÃáP'"tè(«8{l(ÌƒÃÕê^SÁÏ~±EßcŠ~0ˆyVœíRÿ¤4şÀk[KCPi„¿ ‘Êù:…P‡$×†™¡ÔŠ¤A24Ë;$Õ0‹¾÷w{Jñ÷âH3U¦gö•k÷7·*2%N¿{½ÄÀK ¡«Ù§‚¬¦ãş0“ñ5µMÓ±¤Bâ&ÂÎÆAvªàn–Ù1q‘ "\’í4k€%ã>wåÊÌÌ‰¯óƒ«3ûæX™ö[Ã¥FİcÃì¿êÛ—–Ñş³º6ñÿ¸’Ç0a}c­}ò¢üÀ’¨¹ÕZŠØuS?y^õ‰öÿ¢k™±™‡ÅX[Ë±ø¯KK…åUÿkKK¹Éø¿Šgbÿ½^û¯<Ö¾f`VÁ¡Öà )Ísğ«“ğ¦›ƒG2/^ŸùŒi‚WºP~CË{C¼Ú¢éÃ\ì'õ’¼‡æX{¦ÿ/–øı«y Åøk+ıÿJi*`™ §’›yA’<YWD/»ğE¿Ø*—öh(<L\’«^ê2Oõíaê
Oİ—–éâİ*¼óWÿîiO'z¡Éî&ş)W+ÂBT·“ÓçK$‰†¦Õx¦Ûëù¥÷?XÏ¯.­®/Ã³şşğğ¾9k÷q<¡ñŸ©•+÷K‡[µ+ÓÿWVxüç•Â*Lxşceme2ş¯â™œÿ¸–óQöÆjş1'@¢õÉ	ŒWS¿==9fÕûõQ¼YÅ*»÷Çƒôºå|Üšÿkbƒ~|!@†ÌÿK++k^ü•eÔÿ×V—&şŸWòLâÈñ?¢ø?9	â?—Äkôˆ ‹>º«`¸œğQlp¹@¢/ĞXc	2BI¯d$ì‹{Œ2ákD¶İ\n I[-îîUvÊÕšw®±˜¢£2f¿l>ËgŞÏäjùåålJş‘÷…R¤ÑttaÜe¡>ÒMÔ,İ7€H9ÔÇœV/˜q_Ç{øÎ‘ÕÖk$Ñ‘AŞÔĞ Rüÿ¦qDÛ¡gÔµ3˜0–2†ÙrKKø¿k¹•ÂDÿ»Šg²I$;hªQÆÃk¨)s#uÍSÍ©òfî©bôZq¾)}“MhÂf£Íç¶á‡e·’ÍÆ:ñ“VcJ5:ğ8Åni¦ˆ¡¼™„al˜E:w:‹Q¸ Á^‡³Jjt6,ÓU_·=Ì{ºu,föú\˜¯[4MÉ3y&Ïä™<“ç’ÿpá> 0 