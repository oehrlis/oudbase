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
# License....: GPL-3.0+
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes/updates
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
CONFIG_FILES="oudtab oud._DEFAULT_.conf"

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
‹ §#©Z ì½ëzÇ•(š¿é§¨@tDh@€ H](Ëˆ„,&¼IÉãc;LhmÝ˜n€#s¾óã¼Äù·¿ó(ûQö“œu«[w¤$ÊN2Âd,¢Q½ªjÕªu¯UgqÒúÝgþ¬®®>ÞØPôï#þwumÿ•j?\Ûh¯?ÞXo?V«íöÆãÕß©Ï=0üÌòi˜ÁPò4ZØš~—y˜ÿI>g°þé¬
Ó›Îòf>ü},^ÿµG>¦õ_[[k?Z_ƒõ_¸öèwjõ3Œ¥ôù¾þ÷þÐB8óapO­ÜÝ -íô7ÕÒƒ=Éâ‹°çªómC½˜åqå¹ÚŽ.¢Q:GÉTýQÏ&“4›ªåÛÇuxç8ŒÎ£,Šóiæy¤Öž6Ô“öÆšúvN§gÙìü¼¡Ž/ãéß£l&ý;ô~8ŽšüÙTÞ†ƒ;³é0ÍäÇãi4u³Q¬–Ó(¯«œž5SzöïSA@³—Žáín?žš·—vÃ|º5“ó¨ÿâŠÑ¿Nmßnü›Eq§I©‰þ›Î²IšGéÐŒ:îeñdª¦©:àŸa¤â¦–ô"Å3Ta®²h:KT/íGˆ‰tåz4'CXÇœaÀ_ã0NFWj–G}5H3%q–&´¨°8Ãt6U'o¶W kø‰Æ=€e…ÞØp:ä›­Ö9´œ!vZŒ±Y8v¿÷¢DOáÛÃÝ•‡ÍÕ»óåÞKûñ ŽúØ|Í£HÁ¨ ŒMÓ†5»¢IÑ/£ôœf<N3D!ü9§Øþ×£¥È[³I,¿óÁ®¨-à‚é8þ;wù)Ð¢w´ï^oŸœœnï?_zï|Û\©MÏq6Óì¼vMè&}•î`Û†í2MÕ›p4‹òO˜Pð¦{t¼s°ÿ¼Ý\¶:‡‡Ýýíçµ“£×Ýšºåçqx6Šxcø#œL"à1 ûÅÁq÷yíeg÷ø#à]DÙìF ØXÇ[G;‡'§û½îó¥e$öXŽZZ­'{‡§Û;GÝ­“ƒ£ïŸ×ZÓñ¤F_îìBïKï½×-ÿõæÒR-8>éœ¾êv¶»GÏkô9UKË¶ôÞéýZ-¿‰2¢ò¥÷‚¾ë:SúÒƒZ°×ÙÙílouŸÃ¶ü÷4ao6{Ã {ttpô|5p)âÓW’Á½œ%=$ªO!w·»o ãR¯óð<Z®«÷E6»ç“QxÅî¸w$'C…DÔôh;ÝËÏUmgÿåÚäŽÅEþaex‘©•X}»{ghb«ûZÙV_ƒFÑßÞ‡¿æ¿a·_¦Yÿ%ÿ7ê§ªN”ZV;u®–§('Æ çáÛœ×/ª^¯Ø)s^Ïª^ï£Þ[âËY4Å=âKs 8ó¶M¾H¾›ª—<ßŽ³¨G¼/L`6Ùp•¨{OÔD/™óviYðOÔŽHçª÷vÓsbO ëßï|‹ÜášÛÅõ<l_«•ó©ZU?=CQŸzš[£(L:Iÿ?f Ê¨ÝÒûµkú9ØÕí
¯úýUEÏqpÜ¹¬«ÜZ{LXÌ£¦ñ˜t—ñäsmuÂúr=xOóÜÙ?|}B²ýÕæƒë*"¤¨½áÛH’›]ÁfHÎÕYÿô·=à×€ruêC5 FÐ•U¨Ðœyóm(nfMjðEÕêJììuOŽöA° ¢jÿöÕ÷+_W¾êŸ~õjó«½Í¯ŽkõgÏœWŽæ¿šÜð2Ixû#ú=øöêõ[«¹ðï^ƒfÅG¿åaÏî€	4¤àëšz®D(nÝT«‹ÚR½aŠíí˜€pÕÔ/SPWBg?š7½}µŒi[Jÿ™ãÁÔ|»â¾§Qc·€ñÒXû©×Å‡ÎÌ«ððÆÙUÎp18¯©3Óòlûi•yÓ.Û7ßTÍéûÕƒ¼=ò>6,Ò¨©"ë¦j668@“)zO?ƒrt“à«Pž{Â’ÛÈŽMóÕº‘¹È]AÒ–´g—]µæÀQ¡y¦©¶@‹!ÐMõXÇç*§³„4ñ0;Ÿ¡µœ7Õ1l®‰5dï½4C½ÌÉ¨év±vÛ.4`µŒ¢½~[ø7ÂwµR€Ä@ÓOÒ)-jŽâŒLÈ“Î‹k]Á—£ÎÖn×h7§/:ÇÄ¢oì•^£~òhJ€½‡áEP{ôæÓnßy+úašÎzC¶øp^Ú? Ì(ûêÇ¥÷¯€<ZM=HÜÃç{œ‚´ï²q>€‰E}÷ýõßïf`‡Ó'-ÂýÆÙðë´ºÙ,IP÷P/ÃÄ·öàú¹£¢;P …¼~äYò6I/Õ7júôjÂë×€=
Ø,à	xxø½8ÏIy++òî¦¹ù6ŽKpáº¡%IÄ\÷ l	bcÙƒdAõU*»Ðì:ž7n¹d°—œeBÎQ˜Š×ŒŽPí.-zQæ°€Váõ|kAû¼ÒµæÿÆ•ãñÀã= ®$OeWk<vá‚}ú´^°±þ<Ë§ê2L’På`yÃÑ(õÌŸnd˜¯…DiDs4Õl¬]<×%±åé(§`Dh
0·2¯Zµ*{ ×¾iõ£‹V2L“{°P*õõþ¶Pû³ýÄ°‡Ò,ìÁƒ³s:ú¥ÐQ»Âo>hâJWuã¶u(£úÇ(J8^ÞOˆÝK;I<ÃÑ§{P“¼‘E°'YÀÂÂFES5»
´2¨›±2è+‚L	lV”%ŠhVµ*+Éž¡¾Ö6–ú .kÆ›á“Ÿ?\õË/ðËÔJ¿ð³;@¯×ö*ô†}í"R{8Q‚ ©(°÷{á¨%1NhÖÌ‡E£Žœ÷O ØÇâ	D7F)ü©9Œãõb »ŽXXî[åÚ£IÖ(ÿ;ô¿PŸTü#.Ò¥ª9>oò¯s`ÖÃÇJÛíÐ±õ{¤(“zÌhcÚ¿‚ep{aüI1‡ö§Y8Q5obë«5ôMð,Àºã‹þÄ…Œ >æ
nÌHõf ¥&ž0qªšà…uYÜmçÑ4 ÑúïO²7JoÑ.FˆáI˜1LÑÇvœ¼­†ñæöæÏ›ÝÍµgcÎ±a O\Ã`XOçª#
.êûÂù-®«½+—‘L5ßz‚yÛ±_rN‹Ÿu×Õ8§mVWGÝÃÝ­Î	EJ£êÖ}ª¬†ò'=Ù5µôÀ_d[^áÏ9F‰ÃPPØÚ²°¨Ý»JÆmx„Xx„úF™}{úí qÔbéOÐÓô'¡`#KÇŠa
‘¾7í«ìIsª„ lCSÒü¥Z/`0Vª/Ø''}Ž2°€ùØÑÌç>‚k:=ùþ^À……©ÚQýÞÒàp®ÊZyK,G]F°(8’"…ýÈÖ@dóŸ›+µJ/ýµó‚·Sô«îC ²ôþð»mAÛµÇ\~çº,”}Fø°L"~Qö–òh–h%8|AÍ.n.z_Z¯¬pD~eÅPô<IÒ`€ãÉ”þ>ÌÒI”Mã(Ç‘Ã#ÆØö>L‡»sT•‡†Óôâl«o|²†=†óö™¬qÅfÃ9ò\çÍÂMWFsÛ{E+8ÒiØÿx»;ôsaþäaÈyá%¤‚ñ´«ûyë¯K­•Ö}w«ÈÛ?§ A_„½·ðŽÚÙæ8Äx6šÆc‚‹ªu@
4XnÓèÝ›¥ÖûýgyëÇ¤¥ZÏ®ô²ÖéÆþ*-7À•ŸRo„xÈ’Óã6vuOÌéã(» Û©ö¸¸†Ëç çÃÈzê~©™Ä¡£¾7Žºæ…µSÁGµÔgÅ«E±@=ÍmzÖ”Š)¢o’Mh~`4ƒw·;‡ôŸcÏÑëcŽùXØ¥÷±cšu¾ûËé‘–ÃË·êþ‹î·;ûïŽŸ×~LV~;÷%ýY{¶óíþðK{ÏÛÏØ~|¾Áº¶úoÕúk§ßÏ`Z(2–ÖðÑ_ßÇžîÿøMK½‡	./=äÇ]ž<¯œÕgêãGïÉÒ¢g>e¨º¯·õÃŠÝ
+¸Ñ®ômßnËKÙ&Ì]ò¬w˜A s´œ…¡žçµ£b`øË*þF«è¸!ÌŽ„.aÒ&d9;Ïqäó<"À]|‡â‡	R"ªª÷o¤ä ]:< §³½·³ïÊÆ¹b6ìãär¶Z¸Î]Ë¹2Ö›Ú¢¥¯·Ÿ°òëkeá,`ywçD¶Q¡“_œm…{i³öLˆþZµ¼$µk½O«?ü7ì“}tŽpûè}²±V¹Q>ns¬U¢È'ùµJ’‡¢Ñb¥úxo‘²ÿšõë£Ýç5L³Ülµ––‡i>EOH}“í§|ÜªÊ,Ùræ¦*ºQ®ô "5›%Ž6Çû™­çY!?È[DÆÊš?Jå„Ö,þ;:#§“iIÀèAÇ¢TÙ²Zù!$ì¯ÍC‹]’*#i}½ŒU2Šüäã¡¹ÊÊùß:ÿŸó6“üÿuøUòÿÛíõG”ÿß~ü%ÿÿ×ø|ÉÿÿòÿÍ†ûWÉÿ—Ìïx°ŽÉºªRþ%õÿ_<õÿ_;‘ÿN³ø?8…ÿWÍ¿ÿ”~ÿ+æÚWdú#)|Bú})Íûøµ2V_;+nŸnÿ)¹ö·O´/y8¢X&*—Ïy»4=óö^”8?ª_ÿ’ßþ«æ·«/ùí_òÛÕ—üö/ùí_òÛ…EþúIì2êÎç
¾/Ùí7Àÿ’gþyæw” ý[äÕ~É ýË …¦Ýý7 {Öì¦\!«Û$ƒÕç§šr zû’Fú	T{Ç‰¤ ðÃ³EÙúm«Ï–:ÞŒ7»”úkäƒÏIáCCÇ´´¬õ<ÝöôÀæ­­Uë¼þÙrIï$Wôv©~”æ÷±)~–Þwsj3Da{…µ­`ÕÂ¤FŽ/Å¸ÞM*ê4<«ô‹^,8a)Ð=ÙÆÐÌ¼ì‹,Bk6ôS%ÐO)d{t˜ÈKW]7æ¤óây¹£Š†„ŽÓÝcŒõs‚Ø…ºÿ×{÷íqÁ_z³)Œ¼Âa³^–E‚†ï:Gû¤ö5!<!…÷cÅÜçÀy	ºÇYD9Mñ5évç¤sÝz€ç‘ì[³D2“íD¬-¥ÓÄæt"X%ê–¸÷~Ã€ŠÄGmM8ÄRLŒÓ›~lý¸ÿ­ÿˆ£h>XjýØnÝ¯;¹/Že0^NÇ7¥¢,ž^ªÓgy´ˆ¬åÊbÊã·®°‡È@ÏÔýÆ}ÿW¶/˜’è’Øyœ¨¸M¤Ç×÷ÇD 2.HbN#MÈúœÙs%h5>ì’NTŠ™~P_Çp"¾nNÊ:/™£ÄàO¾"³dÀIÖ{!ÃÂ±Aý •Ý¥VÏ>8ÚT?ˆ?©-9A™§³¬yA¾èÔMÑ”xƒeiÆ<òKÇ^ýüôÒd'³Èh’2]ÎóóZìØÿp›4ôêýíÎÇ&‚ÙEàó€@¬”IƒdñTšå¹¸¦vÅÞñ0ªåŸ7}”^‚?y¢t©;g[×=÷7ýë_å´ÅëÃ22˜¶@“e­–Nâ-VgOÝe%Õ¶€ØŠiùYvfj³	`«,jì*[=ç-<T+ÎóŸ”SKîû‚†‹Ûq‚6&5¿ÕJPîy­=–.a2Tq¿.#k[Ñ­‘DgdzÙQšNY‚õ7QŠ5Ö±€sÿ‡6ÏFaòvó§Ÿî×KR@€Yîäw{íÂ¬{oÆIovÏ‹Ð>|Ž©…Þuˆk¬?ÞoýXküXk•@´îŸÛ-øV÷=›ŸF^§fhJ[¼¼9ERŽl)NÀílÛY|±BZ[{{´¯ÄÝÙ¿n1Ä•Qö×ÊŠÎ—Stä¿Ý*áóV(ª†‰)ƒ.î±E ¶…v6O·Ã+‰RÜÿ·¯f÷ÁFH·Å/(O’
,ýŒ™ª!Hž_a§á§2Ñ’·¡Î^åeå$Ö²ÇyÉ@ £°:_Õ™^…èÞ–pÄ%Æ¸HŠØlÃZ©ONaõQñË€¼S+¹–°]£Ï=H_CÂ±f_™
’“ËËôÇ¿µë>¨YÌ_öÛã%ŸõÐš€~q‚/‰óaÔ/†<ìÂ{ŽÛðï9â¤Ÿ^&×zú—1ìº3°â£Óp¢~³fÔ
çpâÒ<rñI$Çã<Ñ
¦åð;¯9OlŠÏWÖWW]—Kiqiè’eUð¥Ö”PXŒòJ]·ÍÝ8YnÎ.ýòùGÿèü_VN›úßíGmÿ»þø1åÿ®m´¿äÿþŸ/ù¿¿Qþ¯Ùpÿ*ù¿bÞ~Éÿý’ÿûœÿ»ÚlÿÓòþU³€Ñ'3z½»{ë	ñ¤ôš½`†p‚~·¿t»‡Ï×?Ž ÛŸÏ¢§÷]½Í‘Ñ¼¢I ;|‚™žÏk++úï[Œ“«ØWÔËQxþ%áùŸ9áyª¾FRýJ}VË}¡ÂÎîn},3móqö›Âm‹©F;û[GÝ½îþIg×BÅç}«¾þ®ÛýË±…kwà¥»U:ê‹Ìw¼>î—¼íE[å*oûK]ò/yÛÔÇ—¼í/yÛ_ò¶Wþ‘ò¶o•¶ý%qûKâöÇ%n‹
YNÜþ’p½ Ü—„ë/	×ÿT	×w]·÷0Ùzºùv3Þov?G²õŒ òŽU¦,¿­+rwUÿúk$jßQjõ1H½Pã$‡#¾ÂŒ„*ÎÝ m7á¿èÐ¥]ñ·ëÂ‚ÿþ÷„6.öï¿d4Éhþ’Ñü/™Ñì$¸Þ"£™ï‘Ñ/Qv®V9¸ârÇYP” Ô
Â† œ¯Ž¤õé:ï~¿H°aŽNÛÙ(UÚÍ©òzûÝïNÑºàøz^×êÁÁî¶ýlÛðzE¸`½N¯¿èlýåõáéq(;=…Ná%å½¥¾B†^Ä´+ =ìbÑËv/ûK´]š3.MÔD˜ËÛñõÍÀ0úÒx–KðV »#$Èþ”¾d¶ÿÏÎlÿ’Ôî$µë·ËZ‡]hDp¬¥W£¾³­Öè§½Ëf£üÞÒÆ¾Åˆ91ÚY_;jüö]‰ƒØ‰HGUiÑ\¬:+ÙÊš__£yy‹9ÜíKïý±8/•~ºeæ±›u¬ªÖN<)X~+Mñ¹]Æ[ŒXÔ+¼iÇË¢VÿÞÜG-7¥›a6§çg|ë`ÿ¥úfÞ¬o˜š¾OE'DÌ«§\5·â«w19¼ë‹¦ö£§ÿÑDaj­°Ç…èÍw,œì|õÑå¤¿JÙã9°ÜêÎæaNÕé›˜¬T|6‰ûóð\…eI^l’×oŸ¸>ŸÁ¿¨ÜÔŸ~«Ütéå£sÓoÎK/…cæ“^å”o‘z^°H:³iŠ)Z½Þ ­G–é~ŽQñ¥ hd&SÌ¼.™ÃÜ
úÑMG*¦(w¹Ùà<)h·éKk¾žÚV>‘ÕJV½3ošÍŸÆ~êNaÎÀZFoCyÜåA×çÆÜôepU§*¶ÈM§dx_N|Àç·Nxþòñ>Þ½WŸ©ÅùÿÖ7>Òùÿ«í¶Zm?\_[ÿ’ÿÿk|¾äÿÿ6ùÿ¼áþÉsÿÙÕAÇIAJ‘'hXv}|9ð}
@ÒŸ-¢ß„YŒy—þŒÐ0r¤SB/8“º¸š¦’§Su™»Å›êŽ§(VÄ«òp›{Kt®=è¯èa@{¬mòùÔÐ7püêôøàõÑV÷‡ÕŸ®kõšz¦&—}°NáOØ»gy:šM1	«
4²x™‹³ç	6	ØKlw_v^ïâ•5Û| œÂ!œþ_#û´æµÕ×iÄZ¨ßÊ‹­H;'æ4=Þ;Ý> …Ðë·ŸâFô‚‘·ÕÙu[Ñ1ö¹m^ H`qN+Aq«hÚ›Û
íKÝçùÜV'Ý½ÃÝÎI÷XÚâ-}#Ü0öÃ£ƒí×['î,&YÚŸõ¦TOaf…4Œ/ÛkÍµf»	¼¢ÔðåÞw³å¨KŽ–oŸ×˜ùŸö`Ÿ7ÑSŠ qpÏÖÄùWVâzþÏz®¯]¢túQÌ éo½Müa8ß6Wœ|ë[5¯˜šó¦ÀznÁRóÚÒÄž»I'7 ¦¦ïE¹„¤†+²
¿ã%åDÂŽkN»¤©ŒÀ.èK1!Y äC^Îë­zúDTL—f"ÐØ™¾¾Þ¡–BJIóÆæ~ŒgÇ2d@¡Rû@Ëe'¡‹aë>·^*ræ.GíÚ?ŽóÃÕŒ¡9Ð,?˜öC6dµ>ˆ½zc8àsÏq#Ü"ï, ö˜fá2á›—Y®Þg´Þ¶|›öCïí!æñU­‡åjv—â·Ò;—Ø¥7ªŸt§ësFÛ¡~ò©z<×éøÏ7Ý¥ùû;û9¼µÈ9
a6ýža{NÑ5=ˆÂoÅp§ÎD{[îD#»ëTÇéôÊ½lœ×“““ï±øŠÌžc«Ïé ôÞ£àÄ"ŠÞE½£%¬Ò¼HŠÖ6zyåOòóþƒ§Wr.†xÝ
	7sÞÿìÉ—Þ˜ª™œ“ÉÌãË¢é,KT[„‰£ÙPh©‰ªnFj~¬¼¨G$NŽ3ªžÁÞò³i”±ZûèJ‹84Ÿ"uØ9y…Ò Îò©C[)^üyƒhÊ"„Ou‚šæ¨E…¤D‡WwÞt·O8Ð1þsí$•˜;m«²§^`	¿±%W=A)ô`_¨^.ð˜1f?rª	K#®|F2q„H­j‚:+ö–ÚV¾¯]:uìƒ5$ƒÇêÁTIÖË ìPt~”ÄÙÇRzÜžnÖš§˜\«’êq­*T|hÒì”“‘lÒWœˆ}|mËÚJì_¤ºD‚É„„Ñhˆø7¥´Â_Ñ5·2‰f³iÇhóTcƒl¥RJÝGæïixf†è•¶µIƒt}qù†m{pMøæÚmVŒztêGYl®à(OA¸à9Ât0Å<º·’ZçÚ Š‡¨;AÁdl>PÅ†ÊWÞãÒð5+à\OwŒÈN¦†S´#*3YÌmN:jqcz-yÌÒ’÷Í-“sJ
k!ÃöÃ³k?1aVz¥Ì?k»Àpµ¹?”PÑx2½òŠ
ÙŒe=ƒ{˜¢Ò˜Šªâ%†zy«æ'Ÿë4ŒRJ/¢“+†fU„èjwšÍ[«âyéS’yÏnÊá-,‚úÔ¤^‡2Ä!)[B&Ï€;Ö9˜øÚ)QŠæjNÂC%Á¸fxá“–ëuå6¥åÊLÌF¾
œC}	åºû`š›GoNkKgwMcD_Ÿ-ÛÕÃ|ê¯$àu€"ÇšG÷L‘Ê«¸-a~·ƒƒ¬¦nþ†¨€‡#à‡€uëàó	¡ÈåÕvMi³&Xû?³„J>‰zzÁ”csBÈ`¢]5ýŠÁ,˜ž
`±ÅûÑ…ïøæ³Z%–]ˆmBÐg8öZÀÆŒÆtÉû}_OþŒ‡SûREÃMTDÒM3ù®Ãh¸FIÉÌ–·wŽNåÇZúÖ+^2?W›ÏþÁjOv§°_µØ2¸(o9ËÛéýO²òO?Óá7æš³ÔŽŽEcÜ>îvo3Jaç×úL?`x‚ÀwãÑÝÐU+"pçª¶’ƒ—èÊá(@–òo$H‘HƒÏ¼žfao’‡··`°Elw4jRÒ dñüi4ï
zË‘1ÕGµYJõ¬|áwyÉb¹^z“×JyïðdémåthÝÒsú;f®!í¹Ëë[îÉ¢ÎÆ w·;‡êÙ³r†‚%­‹:85=öÛJÓÓããÝRóe(W6'gDé…#'-Y^Ó/u?`_ÿ*3½Õ.žÇø[ œÒQ¤”;LÙlµœ ÿ&u‰¶k>.ñÕÉÉ¡ò?ó¦ƒM+›ÚéèüÒ;Ù[w^ÅÄ³IYlºSD+öa„=Ï÷'c—žÏâàž'óîTˆfù¦	îòZçÞèÔJùYékÕ§æsŸáçžv¤ÃÄ9Š|Ø´±{v¾¯Bßþ@Þ¢_†ÈÒWÚÎå
ëuÜÇZó!<°‡uWRz¡¯ùh>È‹¦i(•ÇÅ sÛÏ­‘ç–ð”˜Œ~¬öºµ;Ì¤˜_ hâº œlöI'ÓºÿÕÊF®¾Zi¯áÑŸëøßMÅòŒÄ)r¯p¼¥¶´üs'§gWª8®å_$ó7òu½†J•/¤Ó×îËÏÉÍœ}¯Š,í\,dm ˜½ÙÒE%„Ó}¦¦TˆÐTÓé3Fº>AéXZæ÷–'`¢Eõ‹ŠÌfãG¼ËîÃ/þã‡~J³ófŠ¡¥¼)‡”(+ÉÜŠwL™óöJÿ8s¼Vu[ªü	qûýÙäþ3>…ÁßñD<ÄõOUPî +I¾’ÂIÿnÞÕ\èÎæ}9Ê»õ.EÔ“Vht*Ø'Þnw¡’cv<–þÊ')N«ÀZFz2Ÿaïèž>&kîùRÛ—G+ÙÓß5ìª¥…îÔ¿¾-8ŒsdÍ1®æžNóRL>­ÿò-î•1Ç·	5•iÅï¬–ù:“`14Õá(B÷wô¨x:º"÷ªóRù0\¡"¡óµ4£œÍ¯9“ò9A)oÌ'ÍÛÍ¥ÚV¯¶Ó|Ž"ŽawË-™[ÿlC§ˆÃ°Äs–JåŠ–ýUE_•þxFLVu¿ErkÐi.r™&	©­Fë¯K­É}=c(ôó•Þà|£MQB—¦‰µ€ÁÏžÑ=—ú”N°¿Wt¸ú.{Êëñø3wyÔ=,MÒuÿÜ%V?/?sˆñöüì*e¼5›·ág÷4GÃýMØ#(˜w•—Ï¬ÐáJPÓ1¥"wtIÜ1ŒÀ(]‡c:í¥%´i?|ò´º““1»°í£‡æ´%:x¯ÿ„¶Ožzp?žoG«UI‚¢›xŽ¸ðVÑíXrÒÚº~ÇJ÷ªÓ¾èbã_uÞ(úXKÖÏƒÅ_C6ò³Sqg•ä#ÿLÛ³q~{he¹D
²¬2ñ¨ÌÈæ:ªÄô‰/{E:­S)ÐvÙ=­?Ä˜cUk^lõ~ü±ðˆ}Ô›†N7
Ü4´µ¹ä£¥æÎíf}š‰1ì÷‹3Ád9€ì{w4âo¾™7æ2×þÌJ`r:‘KT«ôÀ$Ê8ƒÄ4â»nïx<¿ß’óéÝCíÕëà÷Áïï©1Þ©Ï²¨¥DDdéqŒè“;=ê×%GÖñ¨(¨Úð ~/{‰{à¢œëNQNéy=ø=Õåü=6©š:­WXf³Ès}ç ‚`%:0Ë@’‚øþEÑEÅ=Uë¬ü_áÊßWWžÖà!|Äš¹vL¿(öý&ªí{bqà÷r¬o9ÍÿøG ÄœäÖƒ ôOüGÐUñtÔOJåç>!ž~û¶H‹äÏü¼™a4ªˆÉx©ÔDŸÝr‹ÝÝñqY-¶
y­h°ÛÝói§Œ-X°x^ŸìáÉ LçU{Dã?_IZáµ}ÉçKö%ÿyá%“ë|ž;i¾ŸÞœr“+šãóBs/Fà4÷žßÁ;ö´†?,ó¼Ð^g¸§¡Ÿš»gQÝæÎóê7ô°âúùÊ}xí~ù=o*Ï}GD±'Gâyo8ÏË¯øáûŠÿ|AW…÷N­NÉÈ¯z¯bj(¡Uáó\‚;MånòRS~^õHÿ*Øø¼ª9¨•Íá¹×Üå"ú®¶Î(óð£øˆ…TWåR}¥`„ê¤sÄç.$.-Z Ha‘
9‘ñã’C°-9¯a“®qÙ7³ûv®v¡–]½¤î€HýKË¾¥#S6Û§C\x®Ù5 &ª€ç_…§3÷mº¹ËË \™¼RKPTÕÌƒÄbN>ú¢«‚8c9ç€ú r“Àãƒ°9ÅpŸ}ÿBnE¬V1pJåµÎ-!²‘—Ž^ÖT„Cêå+2?x"ëeä“[É¨f4ég÷ð·&YJ9¦RžâÓ±S'@£Ô/z	T(jK”*¨PÝŽ)LOí)/F!©ÑùróAýùòýüß/µzó%G+«éaÕM:,:Æò=„±ôË2C©˜úRëÇµÖý
(ïå¯Í
YˆDÊaù¿%[bãµŠ˜ÕÒ{šT1*ŽŸší%û fÈq•…TàÃ?«e£ã÷å`øŸáf{4¢B«Ÿ#ìÍ5v^âÅíÚ3¾§é™V¶À“Ï8ù8æ9ÎõìCƒp_Øš- ñµÙé­}| W1!uíª?	3‘óxÍÉÀÒ3îKs=užWÕ{e’Æ…>Ãä–cG£(3_Í‰_‡®½á†{»^º£!m¥ãqš3{¾äOù™FIzIíŽ¢”ƒçµšóÜa˜?TÍëÞ’….s¬šûO?²¿’LöioØPã(Lr6Ú{ Abr—õ(F0E´åb*ÆyŠ7Š!3a)3µœEýYÏ{Ùay	NÉ"gôÎ)§{$Ê 7T3hd—ü/áºÎ–ú¢¬žEG‡~ŸåÁÊßÕ£´Ú–Öèn6$;ÙF-VònòYHÛ¯3'ZV­Üÿ=vÐ×¡Ã°¸ÚY
H^†u1è›-úô8d-ÃÐ£‡ÐDnCŸò±ŽšEiÈ;XÈkAáÏIš¬8M¨ÅË4»³¾¬ÙbÊÓãÀ…Ã!äÓ¸÷–®VŸŸ¦ðîPv‹¬Oâ¬%½ó3§Û2â
xp»	)·€„Ñ•iª|„•áè´S8*÷óÞ²Ùö©MŸåÒ¯»»óÈ½¤J@oyìUWð"‘þkåXÏÝ;Ø½5;—cÉúèë;«ùY]zú÷¼;m^sÁðÓã“£Û$wzcÐižu\éˆã{·“k''´íç¬ÞüBu’ë/=,¼¤ã×7¼VÈÌ•Øì/m,Hœ½áÕ;O-P¦—Çli¢ââ	Kš·Ü	`aì¼áÇ$Ì-ê¸”º;¿ã9ç“?z*©7Eè(ô_§¢Øaàª…\:/ªæþ ±5óÖ‚ƒFú|§3L3D*·´¬•ÀÚ’ŸT›V«áá›4Ÿ Ÿ:/>÷)É‘‚NÍÅkÚª¤÷{^‡²¿Ï0þŠ
 sè¡ªFYyÁï‚hW¿Ç*ŸfÔ†=T®á]SV)ìkT¤+L ÌäD÷M'Ñ}ÓKtß´ÞKü»ÈFñ^‘~Õ¨êÜuUNqÁú° ‹i65fF)ZáÛ(²whÈ‰ÖB×N%øyW/€¶±=Be§¼êÊ\þàÓWmA)Ot[”m:™ÛkCæÐþlËœ½õ›o;äÖ¿	Õ~>BEËvüQ·sb.ÕÆ<È©3a4%¾PÆrp]6¨L¢ÌWÌeøYw0ïþtS(j¨ba¾[¼Ôâ	|Ü»X‹÷£^ÄR¿¥uŒ[ã´\ô¨Y í¿5Š™ïÔX£Kn¦×ÿ­ÎRóóO~‚×¸èE¡ö©ÐíÁìêÓÜ…™ÛúV™ßvÝoªÔŠ3»%P¿´ š÷Xy0ø­TÁðÆ‚n¦ØôæÜäó³8Ùôç´é–Ž”ßuÅÅ³íî|Àw7Øò‰µß»ƒX9ÕªÝÊwÒ–Äþ,¢z”Öä‡YÆS·Hi±†µiañj·ÆK±\á§Œ¦ ë¦A››r£èöÄ[.xùt6Øš‚TGp>6åvŒêûP1
9
<·œß(-·sêUð’¡Î}ßç &M¦£Çn>ƒßïY%ù‹ú/fF4§ï¦Õûã»m¾’óƒÁ•
'9 ì”ucœíÜÏçW.øÕµ~ç“w<ûfînGÄs›ëÕ´#øÚEÚ7·Ækñ`*_²(_z¤¯ÉC½ê(k\«²\‘ôñ¼›v‹,xîÅƒÌ&”¸•´îD~ëÛnþôÓ^ës÷±øþ/¾/‹ïÿZk?Z¬VÛíG«¿SŸ{`øù~ÿ®ÿîÎVwÿ¸ûÙú KÞÖç¬{u}£ý°°þkÛ_îû5>ªâóíþkõmw¿{ÔÙU‡¯_ y(!‘RR”|ÞHÎÜÃ†Z{ªþ<K"µ‹ pL®²ø|8UË[uz¨^fQ¤ŽÓÁôV¿Ä»=é(Uu¯©¾–Nƒ|ÐL³óÖ7ê^DÙfFÄ9^²9Ž§èœbprEúSÏ’Æg‡¶g õÅ	–ðæ¼MxsÄ) ùJ‹†‚öœâ‡™—±ÉÍG£ô2ê7ƒyÓ¥Ïa…cP‚°Õ	¨H„5Jì©ÃÙô¦¯C¸!èŠQÔ "*JÍ¿È
rœ
•®Woã¤O™Œ u½Í›ºy+—«ÂðúÚò»<‚ÕòùeªÞòøëõãå7xº$¼¯ø%m ’:Ô8ó‘t?R/®è÷,Ì§`zãŒãd%}^§óY˜…ð=*ö”zÄ$IÁ¤ù‡X§å<Ç++ÓÔŒQt™ÝREà,é’t ‚žÁY`èßÑAšhéÍ¸ˆz°`Nå)V‡ÎæŸáXÂÉd£2¥Ça^X˜™WÑ‡yOéÊD‰ˆú³+aH×ÿá¿Og˜2Dð7„BØ’ùç0…4%JøCø—f½„oq8ˆ3žþ„óËðn<Ê*ÆjÅŒs¼·vL²ÏÕª _=[Ÿj”‡zÊ!‚¡”ƒxuHÈÙ‰¼KãSË²Üxq2’?@£ò	 ÕeœëÓ¦-E˜­'ªk/íGtUDHÇøiÓÒ‹Áeˆé¾SçUlã±é^ÇÕ†±õxt$A'I@ã´øæ¬f÷q4Ü>åÌÍ`)QÞŸ)¾:Å,*Z7b{9­F1'YtAyÖHâ‰ƒá
×'Á0ùEg˜¿•Ÿhw’ãœï—Ö­šÄ`¥S\xlˆ‹ô¢lR¾1Èã³xOc¾lU®’‹¥vèûñ Ir³†…ÏpÒ.!à¡9f^âÝïÂñdp Ÿõ†vÇê†œætŽu#´»Õ ’ÉŽñt§h„Ê½^@21 L¦9Ï(GŒ+/V_v*8^ª@›®¡[é1¶Uœ‹T>r!ÊB¹•«œ†x1Á_±&Â“ÜaŠ¤A¦ÄŒöp·Š¼8{oz™â=¡“|3Xn×^qšMIÖ°ìEäx‹‹”½¼Vœ‹`úBÆ$›?8/4Ý¢s`$us’ñ"vî
¸qG!³ê\UZÏê>û:˜åÝ×Ó!þKÓ„)ö€OfÀÿð¬?2÷@¯D±xæ™¡,¹"R Q{Ü¥ÉŸù1û§NÓikl»ÃhcœE‚ï±\ÚiÐYD‘½¥bÒœhð*ò°bâÏ Œs¾\®¯	§‚›>…¿’(å£+’<$wd1ü`ú#¼Ó^ðK¯‚#·ày©î­Ç‡R¹÷G6K‚ò4
›_ˆûD[°ÉÂÞ«z>¤&ã0™@}€MÂéò”¸Êt@6ÊLTŸð2 „i°9ÑÄ¤@Â9@ ×(IVÂ‘œ™y™Ê¯€”é¾Ÿ  Ã¾I,k8Ã-‘öz³ŒÂ~ÔèaŒLºÇ‘U#Ðž€„û3Çˆsx™IÜ£Ìã	rˆ<‚á_2]ñÕ³(Úg	bu2Eï–ÏZ/#wv1!ú°ˆ IŠØ|:)®3ÖÆ"¡×¶—j“NhÐÌ…ÞZ”ÏÎÐgÅ¼	Ë¢KÈ½œ4ü½Oç>¨ÆôÕ- “kf‰%¦¤ô²® 3\]C{K¦£¬ÒÒŠÙM±³RE;<Np|¡‚®Ù6"s:¤ â	tFšÊˆtC‚üùVãèÀvM’þ­ˆ„ÝÔ›jVB¾œ=QÃÀê~|®Õ™•	'ÿë´Ü,guŸˆ&Í…Ã÷SÏ¨tÐÖ¼HcÎïÕùÄ}$ÒŒë±ªGb­ÞLœ.°
HŠ [xkŒ5 sE`j^5ES`M ×Ë²#`Ü3ÍÝìBa*t-2áÃhºkÌ8Æ±KAˆ\äi\XÍˆóhtÛÖõ‡Ë©'áæ¦H\ù¶ÐI÷hïXuö·±òÐöÎÉÎÁþ16^mâù¼8áéýÚ‰#cj¬žÒúê]ôÐì£¹Z82VenÎº7òne¿ÅK.…¯³Jù¶U@–MCX`4ŽI3. 'ÌßšqG`î¢Ýa£Žoú$8éúb£uÊ*Åy G¯T7„Î¤	[†ý>,yÎ÷Ô@äÖ UM^ˆò-IÍ*55ÙRƒËã`¼`+‡‰Tþ7
iE2 á±Éñ±œ9aª~8¡m‡_è”‚¬¾à™!5ó!Ÿ¯A‰,ÝjV9h†©‹R`ÑŽKP{¬•§Ï(ÕÐàâœ &dàŽ«É˜ÔbmW‘6HÕt,¢F»­Uë¥ Úà³š "ŠeÀ°»Ó§,¶ž ¢GÉÏÉ¸»ÃsÊ£(â¹OdBVËG’
á´¡¯3\ì]$Â:2º€tay„¤	Ò¾Ž8ú‚¶Sœp5è0—ñ§µ°k›Øô;”múš<öyàž4“TF‰Ã_Q/ø ­Ù¡Ì	$ÿhÂÐð‘Àã#Ë4Y §omw™
xBææAQÞƒ	ívVPðè/ºB2#åé›°e.£ÑÈ¬àè"*’;îSÜó¢%˜)oˆŽÂè ‰_ÌZÔ¨Äe+°°G:Cè
ùÌ©$¹ˆ‚u© 4‚êÓÐå¤Ôô×|À×a†¢L›cA8~¼Àh6±ý\DÜ= -ÒE!€it&,_p©vI_ßOQåÈkØD¤0å±¹+‹rI¬%* ÂKI\£®ˆrc¡}azfw…éÛ’[Bý;#˜Â"±9&XZ¬Ô']‚Úp'!/Ä¢"“Æj‹vh›³d¬‚k³+<R2Ù@a
&/ŒqZ¾389^¯Ã¯˜$ÅÀ\‡F“Ä@!IXé	±e+kÂ vì¬ÁÆ.cý ‰œÆE{4ŠÈˆEÆ˜Á¯À Âh7•D¿¶ÐôÔ2¿æØ£51•]vÄj:…ð43¬vù<ù·x[º›•-Œ)
¥ƒ³Ÿ#âàÞî-Ô=ä*W4ôï1ªªaÖW;iöu‘¼™!Çô˜§1êa¬ì"})¨’!i;™‡—tI0ÙÒþz/•t&¤½é(wîb$Ñ¶ïÍF¡ñ¶#Ðþfá9:C^€Þ; ´Ñ+cá8Å#­ÝŽÓ&Î*ìEƒ°ktLæÔY"S«±t®lÕÙ£F|ˆlŒl¥VHJ`Æ¤#]*h9¬³÷•Þîk$$°0Àd}€ÏõÞ†çÌä÷ÂŸ	[À®ÒÄ¸Å±„\ÉªÐ5œæ´ÇÏêŠª£#†u-f¬¢¢Û‹‘¨,õ‹[HÝD¬á«2áÐ‚ñà@£0mE&å%¢X °,±.DÄzl‚Za5!Ür)túnªÏt†°9°)êjd˜‡§—‚å·`¥F#dñIÏëÑ3j@=‰gLp¦¼žBr	Isã 8ÃZ×Q"ó™qûTö}Þ`½»GQ¦Í1+­ÓžÛÁ.²Û–w0©}ajŸQè–Wü”ÇNb&• i4

Ž1Ç Ô¥¥Úc!Ä3àqÚ¹›®ÓÀšÛùdSíj²Se‚'|¯œáP¼"‰ÉgõXúWé%Z­‡&ŸXï9ö~·+!µhdNÓ”•pùv€%D
Oh§²¦ÝL¬9Gé¬M 2Ée_2îÊÀ¾ìoKm³ài­ZÇÀˆ~G‘0v—¸@34í¡Dïóv•ÕäÅc/h—ÂÅÍÅ‘$¼TÐÆQº«$ó5Î^ÊŠ|{vfPcJik@oB¨ë·]#Ðâ£)°)Çtgn8¥Í1ž%Úˆ%s—Ia€¾…3PÉð®8vÇ¸cp¢h¡G1èÕ¤
¯ìâwiÈ¨ýÚ•›åäPË"[aÍ½ØZ¬±rß^ww·x,þV-ò=öÏ FÏ¸ÙZ+ g:4	›‘°ÅÙ|NQ¼~…ED©ÖJúPÚ”Ñ‡ÚÁOþ`Ôa)-Z—cºBïP?p|tËq4Õ.IÝ¿S6­ä&Ÿ%£x#ß‡­yKÙêãŒÐßyU qBÂ2pmH2XåûÙ•’‚r¤…!5Ô9(ñÈisâK$òÈ9OgSÑÅ-ðâü@`'é%ÇçÏ,Ða¢ç1Ç´PÓ$ÂýqŽX>ç¥gW¾MHLñP“ÇäGÄˆ%ÀF­7,'‚¦-ÆY¹6ö¬ëfÊñêQD›¬…Žy»·³“[}@4“Ô£¥½ÐyjbgBct”ðateÃÞtÀ´É„óuY°(F³œrÆE]0Ä¡DäyÀuŒkÀ~õÄ²eq9”ªcŽ “Ñ¯½ò¢¡¸â1zävA¾•Å¬Ÿ‰„`bë2+G´ÁNÌYn|,î ‹ÈT94E.}°%hÎ¢a84dÓ#öA îñ!âP´‘inìuÞcÞ2ÚÀgÇ÷8žm¦õíÄrtHcbT¤ÖkOXÁ›D«[oâì0qö^œõfc]ÊËAAß9–F‰ÁÀÌÑË©Ô1©‹°J¤Ä{ù ÏÐCâ¤½JNÞu‡ÖØ=»8À‡Mä#:îñšãl”ñ†}‰èé€´ZÙ¢!£¡îÊvÜO½ÅCQ
$r†rtÝ¾û¨1i3,Fo˜¤£ô…	Ø–!…1-Ž§l{5˜@šˆn`Âç²;¤=C „µÛZ}·sxà0Ž):÷fÌZÎÿ][UÛ€†ñ¼Þ~úôî© Æ‹&9b5‰hR—>y=4H¬GÏ!·¼Áˆ+ø¼’cÁ—!"'+1KX4²(€øÏb!Ån<œ)ÝŸò]&¤ax¯¢Èˆg†
jkÖ‹‰`„%WˆG"b)OƒâeQ(ñÞ#h8J¢™ŠÈ"A¦Òj|W½kf‘]È:9<Žä®dDKGåÛUqI7iðvç˜jÆT»ö¾ Sff°YZ´ ›´zëMgß¾ÑùY[ìPs%¬n!…KOLäóýÜSiX¸ÚM‡) è±äÁf‰gãj6ä0ø9(KñaëÆÂpr|ˆ”¡¿^òÌ:»žtºV½Ü!‡‚)†‹,Æ(‚¾ÒÄW¸èAÑêÉ…‰ÙôÅ~{Tº‡UqaAmPƒI©¿` ‚¿ð,×^Ä¼ãÊøÜžÑ0Îió€ùæ¤OTûÀ Uª½ÙEo¸YHÎîÁn(×HQ&ù…‘E«»(¨Hz# ÎOÈgJáGá¨…6yÀæ„Ð6\bÛÓºhÆoÜ@{ê\OIQm£è36w,š¢÷’ø^´SÌ¥ZÍ"¢À¨zi×«(VÂ\‘„ihAsWmr„.¬“òÊ^?ö=@Ø•ãd¬$J“å£¯8ˆÅ¯#‰ !%°]`Š´’hàÙGõEÑvzß$ÅU™¼3\IÍûÛ
®Ìc­*‹UH¾#™;=ÝÐ ÒˆÆDµ9§&íÕmŽÖaID óËŒ%ìxâœÈ¾¯'Å1Cô%B;ÔÙ‡}‘æy”ëL‚ÐÆÈ
 (Ãdª“˜4ÜýXõ†[0mô•Àž‰èš{Ð¨]ñ!†™dQ’5Ú%;³þóNP×æ$¦+vÁ“K‘ª<ÃêQô¾oƒ¹¸ÔÖª“8^IÌÞzh˜80m¸²çNX ’\F™y„·¿?×É^ÚÍ¥T¿®‹cRÇx{üüP`ŠøÕØ©ÅMPæ^ž!nÄ¿ä	¯bO2!ã™–´¾EJ“Îí…e6 Y>¤‹súûáÙaht_‡búaÌkÌI®áèç»ÇwC‘é‹Z{Âa"Rœ¼¼#OÑ!þîC€‘W_GHµ[‡Õ1FVPžï|F4v14}‘Žf\7N“f@„ø›ŽÔª€bN‚Zx~ŽqÛXÔ¢ˆ&?Í(µù2ò@»PY5#!ËYY0 OqJKðïKzrpK@”„ºì’Žë‹ÑË††ž2Ùª–¢ôð?=#ëÓì…œFèlIäC®ö`cŸVWÐ€ˆv¹2u”§/aqæÈRßQRá06™Q`%`œ‘¿1W:½1lL L„"žWé+tVTi˜ž’È
V`>ŽHÝ2ýœé¤€ÙÒ†t5
è¯rÒ%Í‹€,[ÿ´Ó¢‚FëÒ÷Æ“0‰µ_‰¹Dµ«/~ÇÚJ¨ú³Œýg:d	F9{€h–|´6°Â	yV´ÿ¦s™©eh¿'¬6q}Öö@ƒê€ûó¯®¢0c×­Ó„%§ãÒÊä„¥UÆ)ÖŒGÉdÇ;5ÌT@ÀðÆ0ÄÈÔR\D·h.¦$’I	¹¼F™^ä·e	ï.Ž¡ ‘èQsjzà‰ÂoO!%Í]¤ø8ål ñÁÖËÓDN8 ®ûD[Êiˆ>c½_F-&ªÂ”d›Ö*æÁ"êG•;Ô$êHR1A¬'ôìpWßºt—N2:œ+Ó£dH^ˆ×ªr€®Ž0••kÇ¹v*±£8íõÂœ436G1¤Žt,p†%Ú¨Eû•Ýöêá³5›ÇØ‘<nq¦ÄGgV/š³ñÏÄ£íÌk$èçÈùé‰JGTZ.æìózÔYµdZ/µ³ê\,*Ž\ÐMõ™I]¦‡Ü9Q ï™eìdj`Aeô$1¼#·¡»‚ì ©iŠ®óHÄÂÐ }Vš—h·1—”xãqæoïqÈ…”ˆì—Ù3Äü€ø¢Ýzs®¸41av¹»’Èåx¾ùË9šH1[]”¨o½Ã˜7ünj
g–yHP9Õº˜C†s±ÛÄz±®™Aš‘Lr˜æ|®cîëÙ8ZíÜd%x£Ic²V¨¨%±aD†[çHÉmÎ=k2—]ÍÝ53òN¢([™¦+ø/§™”?a‚ƒ#öp 0¢¤Æ]E$Ü"¡PÏ/ŸEÌm$0d™$Z­s$ì®÷ØÚ›è‹)ÁI #ÇùèíR¸nX"08aã/©Þb¸9¼à;pA³qÏL »ïGSJ¬ÐICBg<Úa(Ck4GBSî`>³‘AM´¡c2‚)ž¥YÃ²!–Y{ËM˜ÁLW®êÆ KÃ1HÜ#¦ðû/Ä’àUn% Ž›7	çQ_Ž6 ¬‡ì‹N(½Y˜6ˆF‚¹WSöM24ÚC,iÞdA?M3®¡Û¨,M:º`<Â‹”ÒIóÏõi7ƒJŸn°â‰rµœ+4{ªæ!ÊË«¦WÒSÎ¢Ã{	uV…yîùhÜ:n<3g
+žmŽWØ„›BÓ ÏÂèQòEïÐ‰O’ÈyÂ‘ 83á,;f5²í…‘ëÅr`ÃÀ9X½ …z†Ú4£Š«ŽK<ÜYB IÀ'ÐŸ¤+R‚´	¤1rj²Û,’F!=Ê„ßá¼6wˆSÑß:=ÈÝbN†à¦•öóÒF/êc` !çÀ$c]½®½Ìøb[3Ü¾sÔ‰œœ/UÛ*{7t>ž7@ä@AXzŸÏ„æó5ºÈz…‚|†©ŠQQÌH°q'3dRÈ\_ëPÆ-NL+Ð\¤¦œº(GE˜°«ˆçÅ©9Ú<‹ÈÌ÷ãAH9g˜æ2%ItgàÑ’«t]±šé‹Å‡ÝqXÏÍÊÈiZ6]ìÚÜ GÛç“[`›™ &‹ÃPwåìDÉ¸ÞQ{è‡t o51­E2«gT;É¯šDÓY<½2ziÀ4¥ª,Wº7ýæöŠEL<¥„ã(¨a<oß¿­‘J®Ä³Èµ{¶õÕ¼=†Gðg@r=ÚÆÓC>¬©“ˆ`ÃµNR ;z –·¤Ã`BeïÊÝ[š”C×¬y{§Ä=“næ:S¢;È²ãè`¯nÒ–Üñ;vÔ¼©—3ôÂ  Bï2œ6éQw¤tt="‚æ»l97Bb?´gí¶1xÈœ©È*ºj)%ôjŽoŠ‚Â@a mQ÷û¹E.‡QR
B!£ŠF“H¡Ã™}äe'C‘´"voCÇÌ}tG0–‹8ÑA<šÜL
“ÑÎ´‡ÙÆ6«.ìeiž»€$EcÁ^`®0wµ6L97îY¹yød½l|"¬ËÂ>Ðe> sTp@â#ª3<?a8(&Î‰íJ½kË˜´>+hj¤¢@šMÌ‹Pà”’ü –aëq‹Cë¸ÌI¤ª5ç©pàq°,rSoÆ%_ºäÞÔÇÎf%‡OTð!@Ê7L">ô“EZìÙ[3¨÷JJbM:m‚cb:ÜAj$pÎáCnö¸1¨Í|˜ÆMVwY^.†9Î'öõ•Î<aVIº°rì{¾u–º›Ckâ¶rÜ3›êHª¼'š¡£yãÀæpUt¥’sTIøøBPJÁä9@zÚÕ3˜›ÃÎªªÔœF(uø(J@W´p„¾ºÏ§rD	Ù9|0¨Ïh(,±<‡JyÚkfóv%^”^Ê0à=4â¤fÛ—z‚…LïfÝÈÅÌ>ò	aŠ‰‹_„,&?&åçÝQøP—z oeÞ‡íMò¶¦¸ŒtE§¾é‚<ú<v1îÀEetæ±àýÜåšU¤S¢8[adÇ„eDÕx·hØõ…ŒÂOS¢Ÿlðc[’ÈšÔéßÂ˜“‰µa|R:Y;jŠI¹jo3m?*Žáê˜:qdŽ›’Ù’]ñeð8îg¹™´2ºLEê]›6ÿ0Ó¾ÅR´•€HÄUÇdõžCÍ#dc;žÚÑ÷ê¸ýMÎPŠ±½<+y'Æ¸µ4+Ã·'nçÔ¨ÐÅÌ\lÑ
ñÕ9º¤c{¹ã=4nHhÊ/Ù©ôë°8²ØØr&ÕXTâÂk¯"£?8¼Oµ.Ü•06º°í(ªcáˆ‘‰Á$¶BV]ÆNóÅü 0ÂXh[ð(¶9—¢	~rÛïÀ¥4x/­ÎÎÄ)`¢—L<³ùW~ŽrçÜ›®ZÖ§lË(™7u}#ÖÚ"ïÕ‹Ø¦á8Z{Ah\'Wn;‘œœ2T	×6)¥vqã—J˜ÓÌå
IlÅl’Ùèž ýùZM\óI%õç.;ý:Fd2o­ƒ]W?°O¹Kbôhésª=[=¡0ˆª´$G@«y9o!‹ZáUÅD,Ã9ËÑ©3ÔMJÕèÌøP9 I³àD ´þlŽ2mñr¢]ÕÏ‘ÿU‚Å¥?s'(ïž§ujçù‘y|£jÔh·Q{>ƒw!	;óÆïú(h¸¬æ–½À6 ù\
µ“„gØÜÃLJÐ
ˆS¡D¸~	Þò:™ŽBNYìE¥`‡§(¿SJÈröOZÜQ­PIÊº†í‘['áIë\#ÎôkaîÏö ‰ºq™®ø@hÐxŸ4É@‰öG¸ytÍœ±µ 
+'ºi(sP¦%•Ó ©¨ª®S¼-Ô97ÂF¾é-0•§pGb6Õ(_Î?e5•	D^-}4ÀÙñnö±J7‹G¡"ö° c+„ß&CmµÙõñÊI
#å.ý¡’‡d~WªˆSÑ„³ÀÔŒä¸«ãª.*€Š|Dä_`¸%”Êâ&‡+£J=Ò;U•ôƒü±HôöØ³ÀHµ!—hØÜ*ðXÞ´½q$fÉm-:¨fÐ8ruò+cC>0ühUõI«Le%è<†!Ñ=°mSÂºwéVH$:s*MI¿A3‰£Ü™Kpó\¼â1ë	ƒ8ÃÌ–xÙz~F¸	¯Ðs)FŸ§eý´ní¸ 8\{è 7“ £…jðûÐÅo 0œ‰1œyPìÜ³ü-í1ß‘cÜzvW"ÆÌ&Cç¯Tä@mŠì2ƒ
¾a: ‰âlÊ»¹©åŠiL°È#gúîKêÅÔ]j‡Î±7õ_ ?‘]šš
!xÍ†W Ug%FÊzÙË¨Í Îž6Éû7‘+_ ø‘Žx ”W|¢­p\BçNºÁ®]æ%Jö9]E&òó2’ìéÇNÒ¾r*·©–RN9$o>©Ì…uˆïð’“7ÀgX2,ÞDLÞP‡v„KÎnT/(Zê•r‘SóŽôÓ«$çœŽaFr›-G.¸ãì}]Ñ’OëU,‚_Iq¦Æ=d$—˜6$!€ô
X¥}Ïå†$Ý5åŽ–|ÒD”éíô(Ë¡éÄz‰ŠSÎ3ç¬•Uñ¤«æS¹£à–íKcL4ä nÃhìq–UáB/Ôg>ãPé_bý½ ÕIG¤ÙcO|.3æ‹
ÝXq£Cº5Æ:‰ª¡'ÿ©±ÆïF„LÌ‰ûá£š\ðÊ-ÉÅ*˜WÖå>–êä¬[0uÊPcÅ£ceçL9n½/âoó¶k 5ˆ1Ygm%ª<;Isç Ñ”‹\î\‘	;Kì²Î4Áä\Ó óvp‹Z~®Ïp¬…ƒíW÷©"cŸNQ²†‚œ`E “î³€uõÈgÕ-S<Óh\ >f8.9¥X<W17PçNÁëœ1¡:§¤þi¡0±ù3¢>0åª¤6‹½œ§Â„ÊuäMŽšØgáH>Š|:÷>O‘öJCˆQ¸ýÛ‹Õu³ô*I¤,uRèøô–Kqój+]¹3Æj¸Ã1ÍŒé5ð’…)°´ÂÇ yý)#•¾SÐ”ÎÐU‚á³smÄŽ¢.-ÃîÛ(Hƒ¥°ÎšiØÌF*ÇŽ¤þñ˜²›Äëå…Ã~lâ“œ*i·›êP—µÔ%çö:¦YM'ÞTFÜSÆ£Kg*Ìø‚v
ÓyÕbmN:ÆÆ‚'ý6ËmmB{B§(È0a7º£6å÷Ì¯¥-†ã¢]¢T|_½ó8 ÁõjN<ÕÜ°IK#®oöDÉÕAAÊª¾~ÚÐ’‹çQXÐYqR¸A™KPÝ5GÂƒrÊô Hä.ä3Ò+"¥ WFB™æ©Îž¨ XAQÒ{¿êHoEß¼£×ñJ²Å\²é¨f¾ÙÄ
í^•:£(wŸ¦=ÆHc—]NMLÂ«ç* PCAzvùx§µ£„…ä×0å°êa6êcU-ÃuV¸fŽgr;¬ß'Â94ˆÊEÀ%-(/×R6:g»Ó.ç-nË¾pUŠ*	÷.ŸGìÈÒ§?1Ó›™‹ÕâŠ¼O5’Ì$’+í	 i$Þ)¿ÇSö¿Éù2LHÅ|i°)•ŠÞ‘uKÓeSv.ÑKº°T)ÖïpQòANº¬a&~náÖž¬sYÛ­sÍr÷W’X»02¥æ:çªÏ™mi^š4ÜÃì·*Ë© ¾b5
±ž”†Ê§Ôæ&§º
ƒ.á§S 0µÒ©L0æMêsÑý$)Û:§Áé¤päÁiÊ2À–”N[C05UtŽ:©¯ú€Øœ¹ÂÐçˆÕ‘¥s›¨ŠÁÀs6<"¬Ê6
%¤ŠÎ¢’ñ­Â”pw¼0¦rÙòCÓCÃåHÁ-8R9ÀÔÇÖ¥§ƒ‘k6‹ÈÀŠ‡)‹.\h<3I1ÅyWwEÁ ] ÒRRÅIYJîmÖy2Ö¿´Ï…Æ«ÎVþ›,}ŒÁê¦zÄxœÄ§pK¡i	Š@™3wâwAM–ÉaG‘MÂ]×À0`>9!‹Õf˜fyeRQ¸Žü¤:c²ÐÌÛœj ®L¶fÎ´­-Än”Lg:¾NñÃ*>Dj›åb¼VÐ1
š)-¤³}ÍØ´ÀL@çª«ý¹–RÉšN*¨„.ÞàáÇyÁ…Í¤,.,ÎeO¯ø]°âGŽpŠT›Ò¢°vŠˆ®jX$‹I¤¤ÙUMîØ,%àqœŽ‹ýÁìœì!Îo˜Š/yÑ|aÝ:·E½l½Ö¬¡SHO2Ú‹MAòÓQç[!Mßè*
F•xrHyµf0
&Kž&è$TJ,0XÓj’Dj;’ŸL_ÀÁ´)'$'áÕ˜òœRP¼ªRšFûW¥Hà'æ[)Ôèsû+ÂfÝ¬¡KšVm¯ÌI´Ÿ®´;´ãµAÇ’\ò)2|ªNZæ
þI<¥™$ZIÞYæü¹˜Jûö{‰Kýãã:BÀ8èˆ#§x&ýª®Í5÷G°ê¡içš'Rt¶bK Ç‘ Ï5„@-[ÌÁR'—¡±žÖë¾öDí…¬Þ™¦ó‹†±.-ë¸ýÌI*&—ÍLŒOÌi'U‡dL€ÄÌSMë`:7WW\S€·S—ÝÌIãvw#z¢RØª½ÖÄâVÇæ#Xï„˜ß§›¹úéXëo…zì¢èK2µ¬íC*g7£Ê0ÎpôG;Øº’,6L|èÇ=“–¯»¨
¹]éúv€H·Ø¯ñÍ·iÕO¾¶A3_Äç©”7ÐGËòx<MC}Ogê•*sy.]"EŸCOMÝ¾&â¥ä—wÝ?2@¼ÃŒŠŸ]Eš'"jÉgcâútß]…º.XôXBEÛq¤™#˜Fãqö,¼fìˆü Š)§Täº:ö´Ñ5?É\táaÉ˜àhd¸‰9;Sç¨ù‡ÇÜjFí‡MÌè¶Z&ÞKÑA2]t=ÅG%…²X"%y+	Kd”âZy7OH~jåµ‡¯ä8ëh­Ëak½ºÅ
8ÈÙ˜êd
Å»Iú^
JÔ1GèJL6Ðyµ:×º¬îßbvÀÞR>P/Ê8mÏ)æo¬.cbq3ZÁ‹äóé*¦—õ¦:Š`…aÜo"÷î¥‚{Ñ4ï.BÎl•d™@“¶0Âè&ŒéiÏ»±ö†spàð/8{pp~˜¡­Ëõa…¤IœÅæ4¯d-¯78JN"Äúx¢dDwèðu&Ô…¹ÔˆubD·gÒä	¸áÊ¨¤< 5Í`ê¸.ºE2ÃÂ‚&ó+0Éå’ªµA“BÌ/ø'º
¸

¸ª‰[AX¯§¹×‘jàÛ]JÃàLjòÝ9>ž9WîˆÁ­ªô3B¾¢8M	ÖQêÑM`é¦œgtvÆj»>Fµª7Ÿ„lúXo˜ê(…Bþ'3¾ j|]kÑîŽ°´€@1ï®ø†EøÍâ	|eUpù÷™- }!‰û:ŸAßÏÅ™â§}ùAU‹&7åÃñÑkqÇ(!èúmó»bd—T«[fˆÕsñ™¸Ù’if³s7ïßÉJRïGQ(¨KxjY ÓŠÒ˜‹s‚¦%	¸LØ ½xDÉÌn£iRÃ™”¾“äpfq¯ºG]µs¬öÔw££ÎþÉ÷êåÁþ ¾=êì5ÔÉ}ïþçIwÿDvövNNºÛêÅ÷Açðpwg«ób·«v;ßáÍIÿ¹Õ=<Qß½êî«ÿÝÎqWŸtð…}õÝÑÎÉÎþ·pëàðû£o_¯v·»GtCUz§Õaçèd§{Œãx³³ÝuÇ¤jcvM}·sòêàõ‰|pð€|¯þ²³¿ÝPÝÔýÏÃ£îñ1 `ïìÁˆ»ðãÎþÖîëmKC½ û'jwfÍNö&m5tÀßëm½‚¯;»;€/¼VëåÎÉ>tA¸ëðÈ·^ïvŽ‚Ã×G‡ÇÝ¦b@øÑÎñ_Ì@û¯;``ìuö·ºØ—3ç –	§«¾?x"æ½»í!ÕUÛÝ—Ý­“7Ý¶„nŽ_ïußÇ' 4èìîªýîŒ·sô½:î½ÙÙ"<u;;Gˆ¥­ƒ£#„r°Ïdô¨ÉÉå&à±«³–™cì#uß }¼ÞßELuÿã5Ì©DùT‚ð;ßu	ÑMßíÀÀpõa(&Œ½?XÂøHì@ílï¼ÄeÂÙ:ØÓýþ8p±x¶$Ûyq€ˆyÙ¡ñÀK¸nÛ½Î·Ýc‡2°Ï@.Ùn¨ãÃîÖþ¿=ì2ªöa®¸´ð@€¨¬1B@âäu^ÃF@Ü×„}ã3w°Ë¶ï2QªÝƒc¤À`»sÒQ4bø÷E[u÷Q´Ç:[[¯`¿a|FsüvàÎ>¯Î—¶øÎÑv 7ÑíËÎÎîë£"áaÏ€BIè¬·8®7\|µóºÚz%Ë¦¼­ü½zKñ¢Í:Ûovh;J?0ÈÁ	ÌŽ ™ú7ùn¼ÃPàqéŠ+¼úÓ3'b°áÈ#d›~oŠ|p¦­½ÑŸQŠÅøð
W–üfáÂS:.Å)Âª„Ñ%;@gXÂ…íVPRx)6;–cêR>	Š[ÞÑ	y€>­³<áùy*œÌêêèñE<rÆ^á3qt0›Hê²|DØãÎ-¥Ÿ)º´¤}±¬kÅè’ÖyÎ„öóŠïuêŠ8ëD§–"o”U@îDä^².í­Ä:A®œ–‰ÌãœÎ9æ ¹S‰¿ÌòÂÙÒ†DFò)×0ÂÄ½!yÔM¨ÄÅâià_Íê]·‰®Q¾OÂ¿ˆWß¬jâKÚ6Ö—¤QŽX“ªCqZõU2š¿Î	Ü!?tpj8bóöX7ŠO[P‘“fÏ÷µäÞ˜é_âÍtªúE‰	ëAI÷ÖÕßÈü©¦†Æ²¸EÔ$%£ŽýºzÎ`fj»ÒU¶¨›
q}è¤÷u7gþ÷s:N$ Ï²8`%4Å‰ÄAÞüFªi-ky«®¾Æêtß@"ÕÇ÷¾á~Oä¾V¶á-÷¦¹oÜ[äxªíA	9ð¹¡êˆâB-9Ì=ûBüÌ×áÚŒ)¹l?Zö›ÖË–M³vžæîª!†ô!²ÆY³‡åäª´hju%ˆVÙž™sµXAƒ`iç§eV|ìª¨yrç)^Ê*^Ç[‚a‘®Cl&ëªQpéÚd6û™uóK]9§™Å%›ƒ@ì˜ù©¯‡Óéd³Õº¼¼lž'³fš·tºGëPS÷ðÐ[Ú‹ˆ0ï$ÿ7_=N5ïÑÏ—¥	VÂ»BÂ	f®ÀÜ\A9qíPÉ²¹Î–†ærú²•ñ‘MÙ£t+MŠNcaØ)Õmäb§nÁ^,\#GV¿–~¿¹õN,Ñ!—f&œv^ì¾>éî~ïZ2ÏhMe9Õô
ôotãûåý¦WÜÏVt/FØ;&½íMx7›CÑÆ“ðÌí®wß =KÃ«	º)\¨Ì-„z|4ó¶ÐŸ¾­Þ=éì„ãïTê`@Šˆ	l[ž©»Æ´XÉBÛµÏDºûzÇV?–kh@3ò5¨(L@gé»šÉ›”!S®)¦ZR¯ìëô
3Ä_moAÐ7úEYrºÐ¾ÆÁ×­QÔ+ q0M.VÇ«Ù0¾)ëŽVÌ/MLÝß8|³³s­$khø@¬j³¹ñæmØ¤Á›”=‡8qùp¦›[,˜„»>\9lbï¥Ö?äÎY	‡/‡˜ –¥ÇŒäZ¯+9lÇeé\'îQB³gÊ,â‘ #›ÏqÛ%T47¤Ü™#Àµ?‹÷Ñ¥ÎE¸”ô¼º[ç­ Bv1,›çÝÃ,¡(ìWDk°¤¸Áìa:Ž…)4•K1Æ J§“áUërxµh^OFÍát<‚ÕùÝ?ã§ŸöZGÝÎö^·9î¦>VWW­¯+ü÷ñ£úwu¿Ãg}mãÑcÕ~¸¶±¶¶Ö~´þX­¶®nlüN­~¦ñxŸŠJžFÛA³Á`Áï<eþý'ùÜS¯·ñâ·(8ÁËžû¨‚!Ñ^nuòf{~ï&ÿçÿùÿˆ[Ê¥œä
¥.I©2·-€ùÑÉQ“(¹ˆAMà82ÒØ#¾£ï,ÔALËt>ÛåF´
àF‘-ƒÕ2'}øÔ)ÃºöN;9ØÙöFCFXÆIL˜„á0pâéL‡NÙn¸ÒõbŽÉÐÆƒ¡0mÌj®žd™ÌÇvú4žÌÆ-Ó%:ŠáÖwþCït†&%ƒ*¡[SøfÛžYo9Þk¨£ÎVƒ};Ã²2T½¹s>6Þ'¦¨w¤Œ#iu#g ‡h¢y ©æ’~óóL’1<Hg}T3>x hièÛ¼“A|>“BTrá$V³¤7d7DŒ5`š$í¸.A
â“ztÅ€É8ŒÄñÅœûy)õ‚¬Ä¸È,äóû\½®HE¸
:åæàe§)°>W/ÀÏC‰‚I,yUvãdöN½Ùû?ÿ÷ÿ£Â1n§½·Ge.âd”£0ŸœExcÊaŒMyÝèiªÏŸA ]µŽ§Y4í©WñÁó{©{[Ç!X¥{÷À@™Î&…å²y €=C69m°ÑP—%³¨S¸šˆŽSù	—µ‰5ˆðpdå¯¬2è:JÁ^Ÿ ²¨^/èßþö7~þþÀmþwKý ÿžöúyô“jÍVÛ-¾R´UîL­ƒµÕöã•v{¥ýð´½¾¹ödsã‰ÂØÀÑÉ&Þ"ÌŽ‰ŠW—%N«V›m)¼1ÚÎþËµI	ˆ˜ZË§ÊÆÌì8­{ŒuW¾ü:çë¤Ëùaexñü÷L}} Ûv·{ú¢sÜýæ'µž‚7bóÆÎ>ÌxË¼úÃÊØüöê`Ïyþž¿Þ†ï[y}(vtÃ(V†•:úÐœÕ2é]cÔšÏ£úMà.æƒ“{¥ñŽ0Œ¾¡áw´N]hÎsµ­9MSí¡ˆ#¦fçTñ¢É&Ý‚®núXF&\ö/ôm~¼i.©^¹ÂDp.˜3‘å~41º·¤­7oê¢Ï]` ª
Twa‘Y|ÙI9á	¬ÀOÀ¡­ú„& eôÈØÁ„p¹ž*ä¼ã3Î›œRÝ/páü&Dt ïì0ŽÜÔ™ÉdÔ4úcèÊG:â«E?Ôk7õX±/oèñ,ì½Mòª>ù§›;¹SŸ{,ì”øÝ³YÑ­ùñÆ]^Ån˜­ûj¢kã~áªßØ÷çÀôÇsÐÝôœää¦jMÇ“’Œ¥ç($ƒÀ+œ))zNéVÐ»x¤ ê0Ñã÷"áã/.ÿlÂ{+gcâš÷’3ÂÚœƒdhfqÃ:2¼Ý¯~ûJîjY«cœ›*ãá‹›êø„ÆM¸8¤Ñ8Aìö®0UÑoTêw (5U•6%ç›0Õh-~,êD+¬?Vj(E
0—õ	.ö“•Õµ•ö£ÓöêæÆúæêÆ‡é#íæjsUk$wÒûè/s_ÞÆÓ…tc<í€‹p4‹ò…o¼ÎuZ”2]À6G¥\ms!$WT›Ïó"ƒÐÒý|ˆÝƒoç€h·p›.z·{²uºuptC÷-
â¶€šo6o 7½kÄxùÝßóÄ„Ó§aû7B°òÔ5ÉÈ[¬ŸáØÞÛÌƒoCA‡GÛ¯·Næâ_Wì¿(”[‹–R@µãËöZs­Ùn>l®ÞðË½ïàwøÏ7Âxpžµ~›°õsÿm»ù¤¹zÚ~´¶ÒñÖÑÎáÉéËÿØ/SÞ|º¤È5d(°ºÖŽ]øÚÛ­ÃB¦˜Ï0;ãù‡ìqktÜÛíîê·nÚŠUo•¹ÁGt|ónª~ïû¨úÅÛ1€ç{›Ý÷‚Æ
ç‹6ÀjÀm^êœ†gtJ‘þjæ˜y»Ñ«…ýÉÛúë‡€hžnw_v^ïžœº
OoØ}G…<éD*Ñ©&Ð›[ôTzønÜ’úIô}¥î¦ç	;óÆt+À¸$—)ˆòÖZçÿ˜PB tß¢ÿð»§=Pâh^ÎÃâ÷S¾–Î{«£ÿ, (Åg­ ve+Àò€#ŠýsÔîw‘ýÚÓì»Oš¨6žý!6]@éy–bºŠß¼G”\ñ„ÿ9Fv¼×œ\Í*Æˆ#¾å§ð47¥vmáwÍ`³|Rø Ù*½â/°Àz·V€%Äa›I|Šµ$šø`!%E¬¤Ãú¥c*L}ëy¬_œâ›¡¾¤—f‘d¾’T&°EÝá¦*ô&ö+DËÈÊê‚”’åÂP?š£ì~ÀCŽb‚bO~ûä“§h®Gßt¸(Á`Ð©ZÔæC¤ï¬BµÇË‚{jkõÞZ”Pn$væ†Î1ÿƒª-½×Í®k EÔjê§gtl-PŠZ¬°j.×­¦në¶RªYÕ~‰F’$õ†©ªuŽŽ@‘#4¦Ê7q ÿƒ™ôÙâÁ»rˆÎ88ÐñÑóZS9Sh-½×L
Ÿíluvé—ÓývâqÓv Ø‡‡®û>øx¨‹Å¯™;_"”aVŠ÷Ú0Gz£™ßÂ•2\õ–j÷šB3Õ>Î2$LçH•v1{?Nôa@!î|M¤ìglH?ÚAÃ±q)´TSÿÉŠëƒ¦ú3¶•EáƒhnQnFNŒÿ>ã4µÆ½*ŒiŽTyà:(>u›Êî€…;E’aMãE[†v‹Þ6µu>tó,S‘dƒ@µÂéYšœë7ì’›^gÒ¹woht\FˆëNÖÆÓˆbŠAðâÊø5è:»0n¹c=×AÅž+qŒ™ˆê,çKã¦RT|\®Ïw^Ärs{nªTè‹ØÅÃi7eÆUøÀ°.çNPÕsÖ61¡†ýxÜ,©v‹Ã00y+›ñs¦
ˆçÈÑa=Bvæ5ù@7×h:^;JÛt
7}—ŸñÑµ¸¹ëBÄLuçêÜ³²s¶;Þp‘¡5´·¡Xß¥‹ðâÄ&y
qÃÞ3Ô£^’Bs"±gö{é®(,-O3~!ªðùEmGÌZ°->€†+åú¥øZöíBÔ)ˆ&„/F“®AD¬X\rŒÛ-æ$QO½ÛW¨l½¿¦¾ŸÙ•Mš˜]…™ËÓÒHe3é¡{Û[S©Ð”ñ¤9ÅyôÞÝîÒã†„døïãã]eê}e‘M;!óGÄõTÊ
¬J€Â
S]=Qæì‘Í£ðZtG—§N8«?“»'¬3Tç §Õ×…~¾	•RæbY”ôßoªÝÔ–Ž+MÚ/'$J5Ž¯Šòk‹0–ôÔ"&¸ ««Þâ’í¡S<îfŽþô<Š+Ø•¥5¤Ÿîj¬Œ¸cú„esíÏ¬‹ç?x&3x‰¡£á6ŒFµ<¬ÛÊÜØœb`êÓhà9µŸâÎ‚´¢‡B#mš‰•Ø*Í­»rÕšÖÏÌ­>~ ’jìçc.‚\ƒmÝò8Å®æ/,¶#Õ—6dúe}ÕÊÃ57“¥¥±öÔ×—^’¢©ypSíá‰NÎó©ßí3×9x	¦¬¤#½Eïè ’«îÔ	ª—ôDÂ©»ÿF½ÑÂ¸À¨;DCæëa8]õQ-Öæ6¬w•BO-húa¸!tí‘j©×OÏÌœ/øµr«œuE™
™ð+&ˆÍ]WÅ¤LÒ
Ý¯ŸÒµ<Ç¢&Z=åŠ¡!†Éí"¢i†W
ÍÃL»±x‡‡ª›f§Z“ µÊSbžkÉÕwQdù:©¨è” ?ƒ­FúéÝN½Á˜ubÝi¥J,zŽUNºWL=¡h]æâ#W/µÁ,YòDq#³Þ×‚p®^ø²vf¹¿Deî´tŸÿ¡14b¼1Ðp[æiécÉÀtRåÏº2ÊoÈÝéÇ;ÖŽ¯P; Û!^Ö·6ÐR˜è)R`3)8ÚWÞ´ã¶àâÄbƒÐDètÒAæ×]¥yã¥Nu:EúvÀwîp;õVwŠmü®æª×ƒº‚íqcWú¦¨ªù}T§BºUïìÒ®ð¹J¥q¼»½ó’ˆÑf1&Ó&¾:ðñÃs"·žÛÜAèP!†0´ œ/Ü©“òTÆ…`öû:aûÂÆÛŒôAÍ§Ý†Öšy•!âÊyWE××ïü~g¦ªS¨ßó’hºñM4v%JENYyds$Šgú{¢¶>pÃº²Ï ’‰ZÉãkêÉ>¥lìuvö+p¼p·ñå±w2‚ùŸ_´¬¿Þâ£uBrUM=µ¶˜*¨¡—IÀP|<d:ð+H åS3ÝÏ+Ï©AãØ©t4O¨x?U·O<†ô‹öÍÏ•,v^)Æ¹óÑÍ'wTñÝôv=“ÑòÆ(FÓ?‹ðøžÜž`mM¬‘G•Y©dÙÕvànôüÓÙÄF³Úê¾úÄP‰Í §»;Ç'>€Ý˜+?Ùu¾cžÜÀøòIç:ünûôåÎn•Ns¨/7¦ªÞ žºô^ë×-Å'—ýæô9ÜFú1÷ptRê›û÷z"×—3	ñ¼ÑÐ NÏZÈúÔnwÔ=¼i\EOÜÍ@Ñ‘wPãë[LV±
sÒÖAWJšÈ¾ê°éŽ;Å³”pýÂ¢àT|Mþh$Ç9ª£··nñÍÙr€*ñu²Fø”–sÒGüQ×ïó+±‹cêçsTHE¿1Òí•0Ã4Ÿ¢óªáÑ(Ê6»ùlVwëÒ'Áhw“+O¼—|/?Ÿ’£:+âQ#'!V)ñhÏ)´ÍN·’…9–é—Z-TÅžD¬\ŒƒgtÂËíÁøÉÔ×šS|ãë–âï†C’ïªÖUvIu?³¸Ä.§aX…"ê£…ï#*¹2ÐÕª}ÎA÷!Â@+Ý4º%Ð(Ë°È±9‡ÿv;˜rÖ«XÀ@@são·í’¡3è·ýÖÆìè„ð<ZÁÇrhÐnâxhá˜|n?›ƒ?C°Ž=—Õàç%á¹cä B¼ˆÓ¹ñ·t%¢O8Lw.ýÅœè­¸-CrNýêsRwë\	sx•v ‡~9K¸°…áäK©»ÿý¿,¿]ß–I—¢ve&¬åt¢•…¯w»ûßž¼úF¦O¿]öá¯oR¦1IÎ™›‡ÀlÚ«tÝHØ"ÀG•ˆûÚ©•ë :
ÿÎ&9›
l
ý_ä¨00¸‹Q”œO‡öîéP
nêEÀ›—LÕQK‹¸þûÛß¼É>riŠzb»³ =ÓSö(žRÔÒYƒÿý¿ÎÓ¡þóÛHW÷v³6Ülmâ­.=7MG,“ßùÄF5|”IÇ‹ ‹´)AÖFŸ,Ç3´|Z¤Ä²š¼§ØB”Jv|C¯v žØ¯à¶¾Û@®ÝŸÓ89…uªÚpv\0ñEªlOu€Æ|WŠ¤Jª€84éÍ,Å~8ø40×­…NL¤iè8Ž’à™BºÃÕRã¤*~†(ð#eBöLÓNtL·.(¤Œ¥hC&ã·lÔ,öl.b’Ø›,"÷"‡nÐïlObÛÂú‡4J\ÒE£yA¥yÍEò1T# H€šb)RÈ›øú´×ÔÝWzDP–àÙf¯ûÙ¤Ee,=ù&SÅP²ShÀÓ×Û;GíoèŸ5Í¨&z ÀI#o>@¼F‹%#¥ÁV¤&¸¼æd966[.Ë°º1îªöjSu8	íP‰ÌNräª$ÌHg«Bíä9ž°’¤N’¡”±w6;G=¡a8qˆ ˆÖð,D”ãSú—këÛÍLUÝJ®qQ?|ÿÎÎîcXoùÂÄr<·ŒepòÍVI²yN`G[¤(‚œmQ¦z+oÕ7ƒàú¡«óòù±…â H£ab[iqÓ:¾žÏÎ°bÖ\¤§ð~^ªât‰4ÝNB:±s¢­—· ¢ÒÅÃæjÓ\“žQº–_ ÍTÓ›r™µ|^	'[,è·.ûb>˜´ßµêsõ±¸þÏêêz{ÍÔÿÙØx„õÖÖ×¾Ôÿù5>1p"æ1h«[ì¹zp;'Dõ§˜Áj»Íþ¥œß±LÅcå²s'pœO„3œßz%~›íÁx3†Ÿ£öÿÆãÕRý¯Ç}Ùÿ¿Æ§ÿ$j÷‡ÑàQ/œ=>´{íöúÆê ê¯®­>~º¶º:X¸ÑSj¶ÊçÇo<z|®>yüäq{ãi;zõŸ† iõi´=zü°ÿx}Ð¢ÇîÛö¬Ùz®õWWŸ¬>~µ×ÖÂÕuü£½úpõa°=‰ÎÎÖŸ®VÝ·í¹´ðÉ zÜ~üðÑYµ½±öWž=y¸Ö~Ü´ºöd¦ó4\¬œ·å|Ä£µ‡OÂÞ“³ðéÃ³^ÔÛ€wW{½§í‡½þê“‡½öàéê:¾YyÀhÐ>[];ëÖzÐÓàñÙ“vø0l?z8X{m<=[?{ú8ìo<}âàw­¯>íŸ=^}ôä	¢x­ß_{¸v¶Ñ[[o‡ÑÓGkW{Ã$b¡sçdÜÓÿ¿½om$IçÖgoÆ§³/ñÙc{û8³§™=‘ìn¾Díq=I3«ÍH¥™ÙYÓÍî¦Ô£›ÛÝ”FÚÃNÄAb8ø‘Ÿ‚ÄH€vˆÿ]äa|±‘ ‚ü	‚ Až@’ï«ªî®n6I=(j´Ûµ;"Y¯^_U}_Õ÷˜çaÈ-¨Zj·¥¢TÕ*Õ²4_…qÓeº ¶•yZtbµ æç«åVQoU ÝRQ•JR	æGKšT,·«åÒ|›+Õ¸›äde¾-I…ò¼R¡U¾jµZÔR±*—Šd¾Gé“µÔ²¤•qžÅùb«¬HÕŠ¤´ZbIVK²¨ˆUU)¶[óF©ÄdFûTáÂs+Úª*¶[ª¬jÀ|@ÈÖ<¢&`: º®H¢ÖV+…~P¼&ž^.Ì4­¤Šê¼*jP–BQ‚ù*ÃÌHåŠ¨·¤‚Ó9WJzUÓE˜i¾¬U«æºÔ*ÁÐ—æ%©\…%'5Y‹Âéþãâç”¸×ì¤XØ ŠZ©¤—[j«Ô.•udØ† G­B»T)Á®V”Z]+êR,°~H@æv«(ËÕv±ª¶dØHJ¬éª„Û ^©Ê•¶(i‘¹çT7aßKvÀáŠÒj·d½‹bi¾¢)å¶ŽÿW"ë#¬w
³ƒ“£ÂØªp ôô­\nÉmŽÈ6 cd„#š¥Î^ZÒªà~Q®¶D©­.hEj—Dµûc© U¡ŠâP8ã‚ÄEºPÑÔ2ìZvk^“`¹VR©R–`=IÕ‚^ÖÊ%½\¢R+JM¦ULÚNZ.”u¥c\ç[z[Ã¢O5	Öž\n—K"?z<È¢Ò¶,·‰
tc‚ÝLoËó ì!¥VQ-«•²¦Waò+EM™‡úÚR¥U$[\“·Ä--¨%¥¬ÕR[*Ã[ª´`_Äv¹Ú–+…R	ð­¢ªív<L¹éÛÏ	õ†M­ê"ìÅÕyÀõJ«Ô*ÃV¨¡áó0Äz¡ éz¨dJó¸åBE.ªà[»ÓÖJRK/ÊŠS§”Zƒ¦ªÐ¤yMˆlZí6Þ…as5¥PU
ºŽk¶Ø5 ù`qÀ9]*‹°ˆJ[Z@¬ž,i¯^,”å¶¡
Ç?lv8
Ú%8 Z°)UIÑŠ}ë– –
MîA¦	œFŸS
Øâ’#¨È¢Ú†æ–àˆiËÅ*ü•Š"agQ)ŠÕò±©˜p½ÐÖ”
üRGnÍ¥'gIUZ%Mª˜?
QÕrö(ÀU½
»¹&KZE„aP*€÷ªÖ*h¥yY›¯´´øžË±=—É\ÍÏ—½UÔZUµZRµy­Õ†vÎªªZ(UŠUXøÀŠxÀb“Zéãáš­û‡*·uÜ³‘lÐu±0¯ªÅJµ*á9gÀü¼ßÜ¸ñ$§ ×jIjëâ¼,Án­–æËˆÿº¢Ây§1 ¨:/–N²(µS–‹-USt@SE×Û¢¨j’¤Á™ ¶÷27@¨ƒù¨Õ•ÅåÇåtÆ\Q m`o“çU¹Ò®€,Ñ S$ §]“Z^¹ÀhÂ¼Z„5]„%!‹ó- }ª¬Z- ªªGÅÄSúŠ¿¹9=óŠgáÙ‰Ø€|_©4øþù%äÿ¤bKäÿ`ƒ,L	¥ón†/8ÿG»Žü±$—(ÿ/;)Ë0ÿˆ	ÿ?‰pó›„9Þ%êèã¹I£×i7…[+Ú‚pkì`}3åut¯çyZ_¢®šÈÈ·„{æ¸}o©qÊ4}m;®­8Ž.ÈÕ9<Yx gÛ²{ÛÛsBãÀptM½Ñ(˜£a¡O-ÒëÄ	Ko¸@Ëv„5rÛ*Ü¶tçš:€¸½½ë²1À[Y(½¬®_úÖªâ¸‹ôÞôÞ!%$Ås10f!~kñ˜Žfñh¶õž¾%)$¢µÃ4ny99ì°g¬W#§$L4ƒñ­n[wm¾xX&æAŒÓc‰ë8œâèËé´ÿDÛð`}5[È‰ßûÔ>BL†®a-h¨@G¯n.õÜ‹€¾Ê8˜B4–8¡÷ÝNž¾J:colÖ³´19sZh÷ttdâùˆEpbã=ÐiÔ_!hP­+ÏÈ<Q;7€@cÎ™o¼ÀÇŠ°‚	l¾§kÌÄ({äÝd˜ÛÔó:ºGpþŸg8Ähçh›Þ¬‡tLM;bƒ„yÖ4îÑž«™øs!ðˆû-e›ÊÝ­®6·›kV>ªS—7i®uÏ9\XK54&$c¿ÑKfSƒ¼3}ÂÀ\Hç,jöŽÀìÓ8ä`¢Ìà0€\ƒ|`aý@…eÒ©åVÆŽØpu|ha“\ÓBâ•±íëWà:Ìë}pP™‚Çh˜Ì07+œÇ	 †‘³YÌƒæì?ž
4–%ðúuz8x¨ÁCd<HÖ~Ó¦¼áîX¤Î°í 4”ˆðú-”òðòT#JCÁ¢%Å›ð’Eö&Éªt]â.¼¥{^•Â{óúžûnúØEþþezJŒ\9ŸKÃéI*Jb@ÿ³÷¿äý2á¼èÿsã .)0ˆ¸Ü@Ø¤Ö}fVÐ³úEÄ‰þá ³ /<¸îøîç$…†îD£ãÉýEÍµx®?™HJ˜ˆñ4—œÁ ¿9C‘VáÉ+ÃÅyØq•WtŸÔ7jOÐ>ÒØNE„õ†T›}Ñ»ûbgáÅA^xNMëydçë…Y/§ªíÔ 5 ©^)J-\Žê$qZ5Îf_m²h¢˜ðú85­hU†Í@ÍòZª\ÞØ¼\s00Ô:rZ­ É‘)Ñ$fŽše ª£Æ‰ÐzÑ ¢=2Ô&ƒ¸òxp³ZdÌ±¸öøþq„ÎÄƒãu™ã#–V6üéõ‹×ŒGpò”â,?#l 0Uí> h,’µ(ÄÛÕÐv §ÉËàS:´	Ï:Œ¥¿h™šâY—VdÑÒÍþÕáQm–|Í’C N¥Îì9¤*ÓZìÓÂC¦ÓãýÒD§€(ùƒIT}_§	²˜ód,~ËˆZq¥GHlreÒšÕÑÓÌ~eX­²6«j¿²ßûTpv§·'dU!*f'Èïç5}?ßé™ægÛ¨:–Ý2ÂÚÃÌgx˜eœü‚p¿¾²º¼t+Ÿ÷ãnA,º©~°¼”Ï¼'Ë—9!K·…·…o
Yƒ¨1døÚ2Â‹;B¶kWüì•boÃì‹~ëº¬÷_í·ûú™
ghVûi!Û–ùfÔ—–h#^æ êe{ÐŽ!»+ÍI¬üjKD5†à¨-Ä »wËâÙAs·„ì&`ê{Ìî(3š–õeV©Ì(/Ž;#¼³”‚ÁŸe“‰ûy0ƒ‘=ËÔ˜‹ÖdÝñrr{zjÄŠ€€}=&St+ãòïÌÏe2‡Å/ÈMl ‘¹qidø\¸£÷ç‚ØP.ÜàûsA,Ÿ«?—jµÂÃ1ÍFøÚÃÙ¬§)åŒ¿ ’l”¼q6ëÚ°µÖM¾B¿´¥ÇBFíÔ“)ˆÂ¥aéžN?¡w}ýã ¶ƒ­ˆQ6ÎfÉ)¸µâ9
ca€Þ±ˆ:þø€Nôü¹ÎÜºí}½3¼;^‹¸¹ñ\H·-@šˆvŸÖ¥IäHò#©2"¦J|^"Àò˜¼(3W›5tM”{§Z¦e×”žkùj³«h¢iuµ¾¹\[0³b
ŸÚÖÏŸ«å§˜åŸy~M›6Átm?Ê¡QqíqL–Gö]¢€‹Ê¼A½<–C;J'v6°hÜëÒ„^7ˆŒÆ¸
ì5ž‚0€-‰ÃWcž*MÅõ“'êÑ\qÀ©“àP9€âœF OÍØ­Í†”™/hÉ’Ê{{ÛH„6ì)ö¡×¬>ÄaÒý¤ÌÀËƒ¼'|q‰A'ü¾aÕf÷Ð.È„Ra£¸è{¸‹
ñb¾ã­c„üGA*ÈÁýoå?J…‚˜ÜÿN"$÷¿{ÿ®ÿ\^ó*ûCnƒ£WÁ¼©¬ä:8¹>¿ëàc]/^Üõ™ Ü¤F&p~‰eˆ±ÄÙØl–âL;á½ÌEŸlI8N4³Î¯Ž‘úÿr!"ÿ-WPþ;¡ÿÎ?Ü$,çÜ†J¨	õ¶˜NEÚd–@<¬ 5Œ,p‘?¶Èbëä®Ë‹-±Øî~ÌK+£‹iŸm&œ¥N<ÂÎ	k+øg©±¼ì[°Iß<éN'¤-ßé÷‚T˜¯.HåBy¡aa¾
?î‹ŒW¬o#Ö¿\‘Šÿ'âú/–¥R²þ'ùÿ‘ÿ*2_VÎo€@<£–h \4·6f^m2œZzÌÌ×›ÃzÑŽ-¯ÝÐÓìÿè>{ÜgJ4œBÿ³,J‰þç$B }~uwþÑü[A*¡ü70…ÉüO"D¬ôœK'_ÿ…J!™ÿ‰Î
ÍR£Ù@£ýc¯c8ÿ'a±GÖ±X®$üß„Bê^O“¦¦ø:=E?g®ÅgfÿúÂöù„å±¦ts[j ÅÆq78	IHB’„$Œ%¤èÇôW.¶IHBÞÀ€ûƒÀ>ï²Ï_ Ÿ)–~…}¾Å•™aŸû¼Ë>~¦X¾+ìó-ö9Í>gØ§À>ï²Ï_ ŸlÓJ1æ#ÅjN1%5Ã>öy÷D]NB¾Py÷/O©Sö”>¥ôóï¿Ô—¾g--i=WšúÃßûö¯üéÿÚŸ®Mïîððÿå”ŸnMu¦rSZ¸þ|M×ÿ‹ÿ»?]š®Ÿì_‚¶¹Sj¸æÒÿR"}þ.Ÿ¢H	×ó—ðÏ[Sæ”6eLµÃ5½õšO×õ§ªá4m`ZL¿¾iÖÔ6é»KGG uàt[¦…²_ÿ¬ÕE/z¢øG©+_zë¾üƒÓÓÓ_™¾>ýqcÇ:h5§{Šý­+îN‹}ß´,Óÿ®´žúAsæë‹ÔÇœn“Â†¦C–OŽfÜ³zÍyÎ%\½zuújsæŸ~*‰…9A.T_Ï	ŸV*âœP,”_¿¾:ý£ïHµ•ŸÛ;<úô³×?ÿk´[Þî?õÕÿúàî†ûë7†ätöéÀ\ù}o`þ70WÓ_¹výÚÃÕ‡®­5g~xú¼F:O¨úMsæ«èdlEµ:ëø
¬<U-³·×qš3_S=lºzÝ4Æ‘î`nÕ¶LsÝróá3|tÄ´¾¤g¡¾Ë"Öœ™é9úóq…ïøÎ3ªÄ‚3©«¿õC?úö­ÛY¹òúýïuæk?ü#_¿ví#ò:ž×í­Csw>TU'NìžâkuËÔ7Q…çkW¾qõê÷¿ñc?þÕ?qã§¼¤h‘é™›ÓÏz-ã“žá’:„oÞ¸ö®½7ñ™ß™¾JRÞùæÏ1…zœÕ¦§¿ÿÃ3_ûêµwoÌ]Q¦7h5É_“®Î8W7w_HÌâµòôŒvuËTZºI£ª×Þ›žyxõ)Sx¢‘ï_»;ýµÔÜÕgÌñšCj¾·xãÆÏbÍ(Ò°ÖÕ;Ðª
ÕõÇ~ü UbZ‹§§¯ÞôÐèæÝÛô«7ïz·ÑÓS?9%O-M­Ný`Í§S¿<õ«S¿5õÛSoêïO}oê÷¦þhê§þýÔ™úoSÿcêNý¯Ô•T:5“úñÔÔO¦~*5›SµÔO§î¦ê©ï¦ž¤ž¦ž¥”T+¥¥ôÔË”“rSû©ƒÔg©?“ú³©_JýùÔ¯¤~5õk©ßHýÕÔo¦þVêo§þNêï¦þQê§þ õ¯R˜ú£Ô¿Mý‡ÔLý§ÔNý÷Ôÿ»òÖ• ¼â­Žõðâ¸òCCqžmWþò œðÁƒ•kß\œÿ×?DýOüÉÞ¹CpßÇ…
„°”GL‚‰Õ
z(Fð —ÄŸøÉkooAŠþjÐšùADÃéïß {;óö­i@¸úóÚìÛ_¹
«‚¦Í¾=7==s…€Íåß¾6ó%XdáÝ(¯½=ó€öÓäç|õÚµ™·`]ÐÔÚûúeXêâµå«¸hg¦ÎˆÂÿ|ê¦þ ïÿòüË©¯¤~$õÔ7m³©
 m=µ”ZNÝO­¥ÖS©Fj+õ³©&AàÝ”™ÚKY©W©#@ß×©ŸOý9@ß¿ú‹©_Ný@â_'Hü×R=õ7R3õ[©ßNýNê¤þ! óï¦þIê÷¡¿AÝÕ0ê¦þx0êr'åïÿ‹êo<–S;fÎð)zwÈ)ºß°;è^uÊ¿GIB’„$$áR„/Ñïÿ—¿ÿ'!	Iø‡Ô[K¥{Sƒ	Y¼kàßÏy¦†?\¡C·Yœ/ÒõÆ<$üÂÿÑùÿ$|aCØ+æùÔq
ùïR%Ñÿ˜Hèsczuœ|þ‹r¢ÿ3™0ÀíXë.ÿ/J¢T‰Ì©XJì?L$Ü;EBÄÌ±’Â”-ÑfS»×Q©—£-<G1?OÆV…ßÃìôÕ\™njË¡æªUb®š7Ç„@qäÝ^W€º·meÏI§×ë›Ônáß…[hl&Ÿó1³b‹Ç³ãùˆaì]Ý¼!hÓR4šêû¢íÎp6ž3BMÈdüÖ‚×3ÈDÝä¼¼|.AÈÅå€Ýtt’Z.^ÞØXÛ@ÛXžK+Ò¦Ø’0Xt¼<Ï	fŒÎA`]ôfª3Ç±z¶J]0qƒžYø‹eû"	!ý?Îg÷xë8‘þgQÄý_–ý¿‰„>ÈçPÇiè¿rBÿM$ôûÃ–</Ûœ§ù³Õ1‚þ+ŠeßþkE,J‚(‹r!±ÿ3‘0V{×}«?×Çk(ãúiìþ\?…áŸshwÈôOìêº~6ó?×GÚÿ¹~@×ièzÔPƒš_=êí	º­4M½„¬Í™;º±týäÖ|®2çsSÆô¹>n‹>co/È8ÏZÏj 28·5Ã¦Þ&Ä;yQl¢Eœ&9¯jæÇ¯ü}¡¬½‰'ä8D¢n~2^‘>;¥ÂB¬õR¿€ovßXÀ‹ò}°ÖØ|\Îxàà­ml†-xû:”§Ùh¬öçÁØH>ê\ š:¤ñs.­l<ª?ŽÖJcƒ\Èï-õå¢±¯É4†ÝÔàšÃYGGþüÅuàQ³Yö"öÕ›”÷˜ê~+±/»mY.^ c„ uÑÔ[„?^ÎX(,ÍÔ”î:qÍ@w¸2Ò^"ñ¾²hu:Äâ$Ÿ‹Ž³—7 @Ð '[î¸°°8êåÚÕºÙnÛ][Ôm”¹V©Y&êc³×A“g/÷÷²ž5–nµÛ&œp(^ïÎÕ±²]ÛÚërë¶ÕÅêtÇÑ[¢c³1u=¹"ø\…~ú¿èQ(¸.›=@Ôš:C#èÿJY,ùô¿þOìÿN($ôÿdéÿ«ër³ õEwLCÝÑìº`°…vþh†>ˆ€9ÂêÒÊ} £mbÿSÝ4ˆc,EÜ`9;‚ÒkÃœöÚz'w=ê5âžnÀ?M±ÛÂ®Òéh¤¥°÷”NøÁØC,1à˜t[£€ždŒí=‡È¢×'|Ò DÆÜÓuw«œ€Pï˜°Ö;‚Ž°£Jvp_ÐíìV)yëæ9º<Z€=ˆŠ@JÁÎbÓ÷+) íö!UC qC§ï.Ðû@7\À¯¸2FGèÆ(€íÙ”"`æ`–ômlí€«v@ïÃìmÚ:t1Zj¬ã­ÁBW;5o¸çàû.ì¥Ç~§f{¯§­ÖK MØ\ ÇtwÍÞ^×mÇêDÒºq‘®ÕÄhNVmo– «u²¸ä#9,{[éG“Ó««ÇñÂ§Æõ’$¿Þ\rðíÆ~ÏÐÔ­O¶œJÕioJÆÖºù´zð@ûpm[šïîæwvö?º¿}¨ÕŸ}°¶¼³òdwcUùsy_ybŠöâƒ££ƒ‡ùu£S*–Ÿ4:Ý÷ò-+zÏX}r=­v8œtB¿Xg0¡ËŒ8ËFF–dëÂ^n úf‘§YàÄÐ‘C<!™`çÙËš–µëîØVo{'¿wA( ½d@éµpÊ¶±¯w¸À®rŽLäZÆt´Ðâ:*ãÒÇ'k?~íGKuÜ£Þ6É4uÇ5¶a ˆ=ç?Kçÿ|vž7S—tÛxøìåJ^Z{ð¨ûèÛŸ>û@?è=|¥·¶+ßýðÃÝ£ÊGÊËÃöÒòÎæÞÊæ³§ß­?ù™ŽsðòÛß•:úöòêüÁƒõÝW•Ãê½Çùºõü£|ãƒòÞ'Ï"oˆtÛèøì„Ý8Âù¬ù‘Û·)l… F·"¼`xtGVò4>Õ,jÚÐ6¬‹øèK[‡>RŸÚÃóØ::ƒ ¢KÚ¬¢šš‚KÞŸô L| ‰”¬sØQ$èa¯ŒðJøl/÷^e;–k´§2L2^È3d©Ì”ÎÏ°‡ôäáÀòûâhë@”œŒÏEoºÈ¬)ƒÃò8;=W³â1þPìE)Ú,n˜{Jô€óQýì'ÜçäJ­ÿþ'ö®ÿLuŒ¸ÿ)d‘{ÿ•ñþ§˜ÜÿL&0ÿ/(µw„[riwø2(v©]î« ,oÇ`86Ž\öÌ.€PôÈh”šÝÚÛÖ‘|Ï	l´	äÑì}ô, §×2„Ðn[&Ð±Hv³["¥×öŸ›ñ-†‡»ÝFJ¹ À|´©Ð¬vì6)y¥>§¡›„­¢¯Wgv>CP˜L¢c™@%-\×®Ãî}TØµl[ßu…m`#‘w‚;„³#XÓ Oé9»TU/sÂSƒ°M„ÕÒ=œÃÛD‡ !ê“u‘¯BLôÎ¯ŠdzŠ×š~c:}¸`)wNpÐƒz§½Ñ 6òU×4Ž¬ð–Rnü“â¹@¥¿ø¸YËä­®›·l õL_|Ü­eüçb*I,‚ÖS]\’œ“sRPž/Ë=ãÅ‡¦Å§ÑW×Z:!Øò‘÷ÿ b›ç½V; M|×ÍµÓ{qŽº‚¥ÁDC*ÒŒf÷@Ë¹¯\†ÿz\C·‚á„úŒäm4Vkè…0½±¼^C—„kµÇ°€<êu‘xefñYêº'ßX»¿ù´¾±>Çj»Š­ç÷ÜÈ÷•j]‡¢Þï×ù—Ê¾“ïþ£§¡lí½ƒ˜\›O–B¹Ü}-ïuÝwi¹ì€>*œPË £8¢|¤t 2~.˜ÌÅ¸fIEjLÚÂ—Žáÿ©.…ÇZù.ØØ\ÛX>!ê½Üuú@¬÷û1!×åZÿxeñ!®‡ZÆût¡fàß§,Ç*G©F$e¤L(V¦±r8¶@cž=ì>;N&Ò	'ýüŸÜô}òIx”üo¥\ÞÿKeúþ_Nø¿I„„å›,Ë7`u]n¦qbíïý.}^©÷ø¾c#MÌ³÷¨ó‡l È6ï ·aÄJ0¨¦¢knðOœˆÆ#Þy
=:‰¡ÐîÁ¹¤išÃÜ”>Z&Ürð Ð{®ˆ€SL‡uŠæ#bhzˆnRDî ¸Ž#ÝÄÜdX%Ÿ°–cjï
@#J²
à$±¤Þ!ø˜	Ðæ&‡À˜WÃ±q(’c¹ëéÅµÇ÷W„‡è˜	 qþvÀcâÙbŸUBÛÏö~>%´Ç(yíáG8—äfžÏÄR)mš·®iŒT„ª¯Ã>‰O"Ä+‡MnxQš¾ùGšº#IñÜ˜2Zz›É.cóY¢.iA&<&aD½Öê¦¿¿Ÿ¬“Qyï3vµO.{_·[p\z?]æ¯nš|9œ&Î¨Îü¹=8“þ?“ðú_.ù_±€ò¿’\NÞ&úÿ ÿ/¿0=ƒ„e&û„„TúWØåéþË`œiàKA 3Ù%O*ƒVèvé(Qr‡\rxŒÐþštA4QªÉôÐÎt8Rÿ¿$q÷"žÿ’TLÎÿI„äüŸôù¿º.ûñÏ] ¢©*Ú/ÁT4&<¦a]ñÇ?ƒW·ë†H‡1AF.ñðßïÉ7FŽý=8îhƒ¤ÄDN¨wàø1ñ² Q*ƒ«â NShç6SÔÝäŠnœíM®è&{E·ÆVî2tØqæÏõºî¸W]£Ð|Ø†¶xÔUî#YÍ	 Â øcB÷‡Q ø]Ä7} š=M¿gC“ÈU×òà.‡ˆ©¯,‰~¢ýà›"0ÚÞQÜuWwž3v °>~d”“p~á¸ôÿY. GÐÿýößd©(%ïÿ	}ó/š¶Þ5Q^	­ú+šÖÄ‹óÂ8ÀQòÿr%°ÿ&É„ÿ+”þo"a¬tžÏþ—|<ów
Þoìq~CÖÕÙX¿‘œß1¿cò}Ø>júÞüRno{ºK¹”ÏG½Ü½ˆ^îcKÓ#\àÉ9®A×Øç’g·ÆÍm¹±ãeµŽÍi¥™('Ê"SPÏ,\Œõ3kÚ.·„10'å_Ž)mpLa.›Ô'k@bC 
±y
A«†È,[dÏ¸±¼ÞcýlÃŽÅÄ¥Y.½ÒpIVÔÚ¶µ'Ü¢ƒåZô[Šxâç²:^¤é[¿ä£Ïûð“ïa_”¦ÊÄ<éKÑ7} MçŠ¶–cAËCAË1 ¹Î¬s-Æ‰B3qjÏÖ¹Õ$Å•‘‡—‘IfÃ.|fþn8ÕÌ-*ÑN[D¢‡9pò¼¨C¿õ9p»0Ó8†¸¢éørX‘9	*pÕxèÐ †ðC8áÅq³çe_Ò×è°í…ŸìPB¤`ßÀúcÚÑ‹=´'8Üž#dw¼€Šºôið¸[<Ö‰äBb,áXöÿÎWÿ»"W8ùÿB)Ñÿž`HÞÿ.Üþßçíñ/lÜŒMPÆ€©ÄÓJøÇ€;WùþäýpŒíMÞ‡¼z§…Ó-¥Þ¬Ž€,%^s½Þh<]ÛXzíù²ºž¦uÀÆcÅƒÀôƒ¬H<ý=A³h§vë6P—B^Ó÷ó=×Ùžðd²š*dêÙ”ì‘˜­f ²m™š=$~ìè0‡ÙŽ Ý	€a[ŸCKo:À•lëÂ¼ð­oÁü8¡VÞ}À>~7À£QPD	‡ºçÆÓ®Á>;ªðˆ,qôt¦¢¡%ÛP„ÚûÀmÁ®±D¡—¯!°5
ý}õÃŸƒÕå™7:Û°ô¸ºÚý®YV|Æµ“áaá·5¢Ù/luÈòç3Äìb>Ë­µ£äa‹°Ð—kŸƒ_'|ŒÜj,o¼«‡¡c1'3Þa	f9ºJ’˜À ÊãFUµ‰ázZ	.ï÷£wÇ±ÇpN‚¨½X8†yºt*Po®zÓùè/Yµæ=xPä9‰ŽS¢ÇtÆ¥œ=ôÝÿ0&	ð°ñ(×=G#î
…J1¸ÿ‘Š‚(UÄbòþ?‘0.>-zA³ÒiÛŠûƒêâéK-èh„Â×¹ÈçùèLãÇû*½…‘Ós’œ‹‘»—W,@n¨¾k¬Æ#aÉÚSŒNòˆ>ÖGô4,‡óÈÌß5ì{·Òÿ&9—I¨A©Ë›ÛÖÝÛ³Kkê@i#q6;'d`Ä½&-—¹ãèâi9 R ß¥<-æäßâøkÅ4á	š¤D£ãÞŽBeÜP´"ŠRæŽWØqL¯ü°Â@qåå <¡Œu'`<°àÞ‚)6ÔŒßp´°ç•Í„y²L:îÚØ YŠød3jòù;ÎÇ³‘Áx/’}Ýæ¾ì8AvÊù¬ûcdF7šiBZ"š›gP`+ŸXð8~Anÿ^a@n1È¨Ê¶†§«oc 1d¯ 1·iW-ö0è57s¡Ë¼y
Æ„ÆcX)Ä!Cã2¬ ŽÔcnqã3ªT0jµ¾qZ~;ŒÒæEŸ½oBè—ÿ”cåÔäIÉ¤Dþs‚!‘ÿœ”üçàu•È&¤ë›È^ùO96üE–ÿ”ßDùO²U³ö%òŸç*ÿ)¿IòŸÞd'òŸ‰üçç2ôób“n©<¹z®öŸKR…óÿ,SÿÏ…RÂÿM"$üß¤ø¿ëêsÁühZÝvˆ©ï öÜöx!ítÂô}N™>ûÌL_Âì]^f/fÒp)ÜösÞa„=Âðù#p&ŽÏƒèó|!Y˜ÛÂœˆñcíX¿øä5Dù¿`0O'a‡—
1¼Ùšéÿ)¥ý__0#¨ Dyç”ü_@v8ÜèÆLZ”s‹²nÁp¼ÜÛÀÎlwÂÂ%aX8–þŠ"ž¡Ž‘üçÿU+„ÿ+Wþo!Ñÿ»pý?\]—[*ËQª¾Ùï›Ÿ@ðžÞéáh£•Î>Í;_ê9"JÜ¯;òšª
~S3Þ‚±ÇZ|œî9çÌ¡UðKáD›Wò£Nb•QÈð•ü:1Z~º°’ÕŽ^¸Â1ëcE©Ã ³/¡¤Ç°dŸ¡òT_èZvÛ´ZŠ™UùÁÀ³¼èCýn›zÖ“Ò„²Vë%4GÅaÈ¶ôeß°ìEUõ®›¨3Ž±½ç0 YâàFž9¥¼	8í¨€¦º¦Em[4‹‹Ë†Ð>e–èçúXŽ®•{-×†ÌBSw=ÿ¸DË’Ñ˜þœ°×ÓÉjÁÅ~OGo¸.àŒ[G¨/®Î:°â\Ÿ¾]ý±÷±±°°Þµ-3§™ºíã=Ò¿šÀ–†¢™ÛpÞoë.+P{‘‘rrn¾(æ$©P*•sR®˜›K/2D¿âö¾nü¼}OPT`+2Kh@”ˆý‘sÐÊw¹M9:n«E ­|‘yYëà6œ'€ÖV ~¬¦<l
°9øNì‡.=vð;]Ù äNæQ[”àÐà?ðcA"Úh,J4r¾¸á˜þŸÎÄŽ´ÿRä?Å"±ÿ)WÄ„ÿ›DHø¿7ÀÿÓåç Ã^‡r‚û†’ðy	ŸwÊÕtùø¼GŠa
 ~PIz›¯g1ž’ŸC'ÔŸÄ=·_Ð@Ä‚i©Š‰(Gk¨wºŸ‘2_#SKžáë.ì­ž+<Ñm´#ƒ8f;I'ClK×žàPPX“NP™ÑÙWLCË*¬ÕPïaÇU^Å×êóÕº|û.ë¤´rÏ¬D–6-T/‹¢úù(ƒ’áIo ¡gayÀn£ùà4’C·EÐI`Vq|»Ì¤‡eGæÇ‡ÚÄÒæmPh~ëxé~‘KñjÛŠêu-8]]5s!Û|ç]¾?~vº,³»£,ç:½=Àu¡0ç•”çúÓXíôc½§GÇŽž]`,½C™Eïþï:ÓN‹ÎOìÔ¬#„ŽbR&sØùÐ2áð,¬êmw'{í'½ð¿žx9bËûh¸ÐãõÉ¸¬ÌÖCÐÜx`oÏ/wúB¦1šÐø ž•B„õ»kõÜ¬ÆÖÂ‚èÄ%·a‡ :ÖM¯ã.úñ[–åg73‚‡|Þ=XCA·¶õ…J¥Ruhú«®ÁªÑ,‚á\(GÊDjÎÚú'=8ç€‘îÙp|#C›tòu4¥\]ÝÎùÔµIÊ«	F
£ÎYèüE©Ûl“oîžÖ@ƒD÷weÃVW:šq¤¿‚†$äÍj-h°¦¿b”S6«›:²Kxÿ=7ƒc
òg‰ëJèL¸{8(ÐÛA*jPºÓkÁÑ
g¬Ÿ£é1a¨~$-AZô”FzŸvp:/nK÷,tÐ“pït"b»GÁ=%ê[z¶[”j>ÊÝËáÍß÷~Ó»ù[ÊÍFr“t	Cpÿt²m¹È jyb¦`luŒ²ÿ"{þ¿eàÌKhÿ¥\ùï‰„±2<çxtyï€bn`y]îëžUo¯B<5Têy\D…ûîuè $÷ck11òÑäŒÅäé]“'LÔ²$îñNž>#åàû‰ŠqYÍP¶;–ãêYÀœ¸,o=‡þ”¤T­î!Uqu/fÉ/‡Y±Õõ]ó~ß3¼×°˜MWŠÇµ
KT^9@GÕJâ£ëé×Hr„T ŠvŽœ¸ŸKËû°l6ƒ×a­ÁöÅ) fuL;ùà«£9mÏÉáN¨êÃáÀ îY¼ÖÊýÜØ.ñ˜s1tüéà{cÑ‡ã ¤ÿÆXÇúOFŸïŒþ+—ÅÐ¥J!‘ÿœHHè¿„þKè¿þùºlôßêÚƒ&j±àX5Ñu¯KOåP‚þ
—FLÕ1éOÐ;û‘Ã}ôQ^ârQÜ%‡ùEïsIˆÏ\pcªãç¿wÿSJü?M&$çrþ'çÿ|%çrþ/ÿ›À¸YF½ÿ”Jœý×Šç±"%ö_'Æ¼¥ÏÇÐ%µÔoV×Ùþ‘çþ1ŽýcžúÑC6ˆ—VK¸?àï?ãO~Ä:áÇ;/éËdÚ‡4wÜðèƒˆÐî™¦@©Áj³v¯ƒ)žlúø;¼^UxþC“9ôQBÈ÷D1¯t»ì‘"OäWˆ)Žœqv„¬+ÜßZ]²{¸’îBnÀšœº#¼ÿ¾w÷º|v«ç
òûß’Òç0|šbÀèÕ&ò4ÊÅ¢8'ÏæŠs¥¹ò©†såñâÆò£åÇ›õ7eT):Á‘”e2’ïwüãw’»è“>>ôzÓ;0&ydÍ9ÔQÏXêIÿIrðþS$þŸ¤rBÿM$Œm9E	´7Ø¶‰˜,%Í„>´J£Í…É3Aq……ÖïäI¬æÄJNˆR^RNŒRY[ 6ø{”Æ#æD°síØS]Ó³ˆ†Ý ^¬‚n„(²!ÔU6ôàEðö† 9
«TX´‘a¦!h}ÎM™þ“p›´ôNN¨k/aiÔ9aÛ¶à…ÉCÑ|(ÄURKo#Fl 
†›Kßå&Êhpv ë]ê,y!”îô4KP»ýÓ¿cçM£•gÝdŸùHÌÔOKÆT;=,‹•Còaï5]Q]À)÷øµh¬ø¨j°ß¹<TaOéôs(p‡Úêž²3pÂ;œ¹±éç¸Ÿ|œ^ÒéB€Jkè Šî++ŒªJ?U:®Sëèîeïæ¨qƒt½íêv4RH?g[øÇéÍÃ®^sØ$ô4ªQ áŠô\ÁäÛS(Ôßj}ÒCéåWºJð±?-OPî©ÞZEŸNh(—f¶º1y‘4CDâ³o{:_]­D1Õt4ÅÖÖzn·çÖ aV¾­ZÇ‚æ{©Ë¶mÙÑDè3ÛR>&#…œvm¯gºÑ—`CsÑ'ùéB˜þ£7¾Mðô¬Fß¸0‚þ+–äÀþw‘ÐåJâÿi2áæ7ÉâÙ%†¨Ç¹ó$¦ÀùFG/C«ìÒÞâ ÓYc”TŒÒ„¤$)ÌD+°ù°c:{v xz¶Ïè›&;ÛXÅ=z¶'ÔÀ›õ‰c6>kÏ8:µ¹ní,ºáÐê©w(qkO\¤âmê‡¹9¨˜)@#aøn æìX=S:–$¾ÐÑQN]±¡¬;ëÀˆ¢L2Z‚ÐÐv4V†´¦WWˆ+ àØû¥³#èÛ9i!ˆ±ÓìÚâbŽÖ¹¹£‡‘ŽJC£&Kƒéƒ?¨a­ì+†I*äjFåI
›ä*Û1í»ºÚ\Üjl®=Zù¨¾¹²ö8škÝrƒ‡á”	É¸¶Q_\]&ï±/D=Òb=ŒñÂv,Òœ·$¥ÈU…¹µÄÃ„~È5È¶Tß¬÷C@ß†½”Væü«¼¹°ì€ãCó"“6rMó-ÛlŸ×˜|è¾uxñáÖº×o*»¹“fäg…XšïÁQ Ãƒ˜ß34ÍÔ[çAßôÔ*Ð„¼Fxß­?©óÁ{	È,ìÀŠ%Y½‡ÿ`*QÝØF­ƒ}l[ƒêdÅ.J!'·¼¹8Ò›ìÐ8X(@ØÂ¬°d‘=‚n–À/Â†gG‹lFØ¯ðÞâ p<ÙÆ¾›~'v‘¿ÿ†^õÆ†0ýÏ6»œítÇXÇú_”˜þ§T²_ªùÿäþw2áùòã+—?NoèNva>ï>¡kRN¤ÿ¥Ÿ?X~¼¼±²øqº±¼¸µ±²ùasköÅåFóÉJ½ùèCºñ4¶ÖÑúQ­­˜c“MÂù…8þŒ¬?	#Ö¥\‘|þ¿P”Éú/–“õ?‰p^ü"
Óì˜[€Ë}°’þ%'ÐmŒÀTLCqÈkï‰*Äð¤#FõS³µä_L;±7	ŒCƒoø,fâÛ‘F8¾"ä·ññ}óÉ±ÔÓÙO.ÆÓ\Bƒ7€ýæ„¿„'þ¼ž¦ÿbêò“úFí‰böô±7œ‰–¬7¤Úì‹ÞÝ;/òÂóˆo±…Y/§ªíÔ 5`©^)J-âÃ‡ºâ	2´Xda¸h“E¯®-ÖW_§&£­*ÒP£B”ÅâòîÄæå2˜ƒ¡"yÓjMŽ´H‰&å‰-j/Ðîñ‡~9 ÑêG“A\y<¸Y­ 2æX\{|ÿ¸BgâÁñºÌÝ#,­løÓë_,¼fwN>‚R<€ågÄ<è  4c? X‹„©ÕmÁéêG°[¨ÁšóàS>´	Ï:Œ¥¿hë¸-Ÿf™FSxÑÒÍþÕáQm–|Í’C N¥Îì9¤Ôˆœ-¬^²÷+ê¹tòî~Òkà½_0˜ÍÕ•Ææë´ hVš^H`ñ[F-“¸Õ–øb—ˆ·ŒLZ³:zšÂ`VÕ¢~é.0ëgÚñ2qK;H5Ij†ß2\jZÐŸÛÊ…Ë©?Ä†ráêêÏ±ËÏfìÄu*ÒjÃ˜É_3\nuxnº ƒü°­„†ŒÌH¬´{4«›5”‰:;òGm»[›ÝÖÝ&Y’~¤µCcéj¯Ï¼4HAÑ¿ÝìzQ0T«‹°%­®¯\[LXyŠ)|FNn?S®6‹	š{‹j™–]Sz®ågˆÓòÓm
Àtm?Ê¡QqÐ“e‡=ãÖ»ÐÔf;‚,úylñ7`\pŸ–ic±’8˜Í™ ¸~²â:>ËsÅm½{2 œ?½ Šs2Ô²

tz ö«6»o„7WiùC?{]Š=)zÑhÌnmvÈFeñNœgTZðíý2ÿ“×íœ÷>ê†rÉé~‡”Åi¾%Noïbƒ¶{{{Š}è5Ks`rfÃ/dl4Çv°qÞ÷‹Ô‡GœãÅ[–ä»úÎ¹¯\¾3!CâÃº3;®;æÈý­ ëG…:&øFÝÿBlßý¯$'÷?“F@ÁJhÂœ×¢‚ïX†4ÒUÍm*ÞÅ
.ºõI8kˆ—ÿ"œÆØ®GÉÿKœÿ—b¡Œòÿ…Bâÿe"!¹ÿ½Øû_~­}>¯iGÞG¯‚‘yO®ƒ“ëàó¿>ÖõâÅ]Ÿ	ÂMÁÕOÀùÅ›aìq6¦Û‡¥èOŠŠ°\ôÉ–„ã„>úÏUZã®cÿW”þ¯X©H	ý7‰p“°ô ''7•P$a!tôÚd–°ºT_ÖaÿÄÈÙðc‹,–˜"öcK,vƒ»DñÒÊÂ§1H¼aèÛ˜{NX[Á?KåeÁÓ‹Lß<éN'¤ñÚM³Ô]Ý^
óÕ©\(/!,ÌWá'À½LÒ{g}ë?×\Z¾_ßZÝlNŠÿ“+R1àÿ$¢ÿSû¿	‰þÏ…èÿDVÙ¥åüh Å3j‰ÐEskcæÕ&Ã©¥ÇÌ|½9¬íØØ|ffÿï;ÿ¯Äc33êþ·ÌÙÿ¯”Ðþ¥,'çÿDBbÿ…È}h?ôH>ƒ	˜SØ€9¡	+lÈ&j†?EÓ“0üâlŒ©—9yÿNŸ¿Ñ—¸¹>_»/ñØ•>Ó/Ç¨éÖ_Žý”`ÂNh¾376Îµs>Ö_8³¶¶¾üx©ÑôUQk²àPû4ÿRÛ•ró9±)•å|&l&|óìÝÅSË0YÉÀOz4‹·3°ŒÕÙ ŽQÑŽUÈÖéðŠÏ¸Ì[—áü? B°k4‘þÍaÄXêuÿ#Uû/eõ¿*b%ñÿ9‘<ÒG›½ª	­‡K{Q³Ä.i8{|>mN¼Ž ;{ºôR‰Eçq57­Á$ij&ÈÝFLŸƒ–½ÖÔÁL[­—0[ª	? ím¥ãÙ	¥À1E!ª9¹8Ø*ä ÉýÅ#5©æ¢ÕqãÐmòºnÁY?2M>ä‹Þü’„$$!	IHB’„$$áþ?U91t ˜ 