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
‹ ¾à¨Z ì½ëzI–(:;Ÿ"F¸›ÑÅò0=Âànc{lS§ªÆ’RVR¦F)Ùx(Ïw~œ—8ÿöwe?Ê~’³nqËLÉLUwšžÂJE®ˆX±bÝcE'Nÿô•?«««77ý»Åÿ®®mð¿òQÍõµÍæÆÃÍæCµÚln>\ý'µùµ†ŸY6'0”,¶ƒfýþ‚ßeæß¿“OÖ?õÎ`zÓYVÏ_¡Åë¿¶¹º¶Në¿ÖÜÜÚZß‚õßX_[ÿ'µúÆRøü_ÿ{ÿÜ@è„Ù ¸§jw÷hK{½mµtç`O'ñEØ‹3ÕzYUÏgYœDY¦v£‹h˜ŽGQ2UT'³ñ8LÕòóÝ“xç$ŒÎ£IgÓI˜e‘Z{\Uš›kêå0œN;“ÙùyU\ÆÓÿŠ&Ã0éÝù ÂQTçÏ¶ò6üØšMéD~<™Fý0Q‡Ñ`2ŒÕre+*£gõ”žýëTPï¦#x»Ý‹§æí¥ý0›îÂä<ê=¿bôï†SÛ·Û à&ÇÑEœÅiRh¢àfG³É8Í"†ôhFt'ñxª¦©:àŸA¤â¦–t#Å3Ta¦&Ñt–¨nÚ‹é4ÊôhN°ŽÃ€¿Faœ¯Ô,‹zªŸNT”\Ä“4¡E…Å¤³©:}»[ƒ®á'w–zC`ƒétœm7çÐrÖAì4c²8 qì~?îF‰žÂË£ýÚz}õ_î|¹_§½¸G=ì¾fQ¤`T€Æ¦‚iÃš]Ñ¤è—azN3¥D!ü9
§Øþ×¥¥È³q,»óÁÖÔpÁtÿwù%Ð¢´ïßìžžží<]úè|Û®U€‚¦ç¸ëéä¼rMh'=•öï`Û…í2NÕÛp8‹²/˜Pð¶}|²wxð´Y_v[GGíƒÝ§•Óã7íŠºåçqØF¼Æ1üŽÇð€ýüð¤ý´ò¢µòð.¢Iv#Ðl¬“ã½£Ó³ƒÖëöÓ¥e$öXŽZZ]	N_íî·wNxZiLGã
=|±·½/}ô\7ü×ëKK•àä´u|zöªÝÚm?­Ð7äT!,5,ÛÒG§÷kµü6š•/}ô]¯0¥/=¨¯[{û­ÝÝãöÉÉSØ–ÿšNBØ›õî h?]\Šøò•dp/fI‰êKˆÁÝíîëË¸Ô›,<–WÔÇ<›Ý³ñ0¼âwÜ;’“¡B"jz´›¾ÎÎUeïàÅ¡ÚæŽ«ùEþ±6¸˜¨Z¬¾ÇÝ½w 4q°Ó~¦j»ê{Ð(z»ð÷/ü÷ìöËtÒ{ÄÿLý\Ö‰RµA±SçjyŠrbr¾Íyý¢ìõ’2çõIÙëÝAÔ}O|y‡q—øÒ Î¼íG“ï’ï¶ê&OwãIÔ%Þÿ:L`6“9àJQ÷ž¨±<"^2çíÂ²àž¨=‘Îeïí§çÄž@ÖÜ?|‰ÜášÛÅ}õ#<l^«ÚùT­ªŸŸ ¨O=Ía&­¤÷o3eÔnéãÚ5ýAìêv9ŽWþþª¢çý8¸î\Ö•n­×LXÌ£¦ñˆt—ÑøkmuÂúòJð‘æ¹wpôæ„dó»í×eDHP{Ã÷‘%wr›!9Wþé1n»À¯åêÔ‡r@Œ +«P% 9ó$æ[U ÜÌšTà‹ª¬(uº÷º}tôúj ªò/ßýPûnTû®wöÝ«íï^owRYyòÄyõøxþ«É/“t·?£ßÃ¿`¯^¿•ŠÛàÿî5¨—|ôKQví¨@C
¾®¨§JÔ€üfÐMµº°¨-õÑ¤ØÞŽ	È 7QEý:Å±:ûÑ¼éí«Å`L3ØRúÏl÷§æÛå ÷=»ýg/µ—z]|êÌì°roœ]éƒóš:3-Î¶—&Q‘7Ýá²={V6§¿1ì—òöÈûüÙ°HW  R¤ò¬›¨ÙØ`M¦èC<ý
ÊÑM‚¯Dyì	Kn";6ÍWWŒÌEî
’¶ =»ìªé4Ž
ÍÛ0MµZ®«w`Ÿ«p”ÎÒÄÃÉù­å¬®N`sÍH¬!{ï¦Ô;ÀœŒênk·íBVË(ÚWnóFø®VBjhúI:¥EÍPœ‘	yÚz~­ +ørÜÚÙoíæìyë$‡8@ô½ÒkÔOM	°÷0¼ã!jÞ|šÍ› ï¤³a LÓYwÀÎËCû'€¦aOý´ôñÕ!G£®é‚[¿q¾')Hû6ç}˜XÔsßß¸ñýödÂáôH‹ð_¿q6ü:­îd–$¨¿ˆ{¨›ŽFaâƒ[ûp½ÌQÑK¡®ßõuœe¤Yµl—¢oC[9ŠF¼É@=P· ‚$‰˜%¾‚ù#™u,„Ì›žJe‹˜-áÛæ-ñ	íØÁ!nëÜT¼.`td¹xGÇœýÙÈ½Þ€ohŸ•ú½Üñ?~¼’³Tþ<Ë¦ê2L’Pe ¿Âá0õ¶éŸnd;o’÷Iz™ðÔçè{5l¬%×æïé8¥ VG¨Póž7¯Zåd2ò@®=kô¢‹F2M“{€Q•Îzz—X¨½Y„ÞV~é$ìÂƒç³s:zwÐÝYã7ÔqIÊºqÛ:KXþ‚5dÈ„¿@Üv‡/îÆ³ÂNš½$žÆáðËý iÓptØ<ÌHaaaG¡Á7¹
´J¥›±Jå«SL	}l–çÀŠ¨—µ*ªšž¹»Ö4ön?V*0c‡ŽÍðIÎ®úõWøåŸU­—ûÙ ×kszÃ¾ö)¸Í_{PWØ¤ÝpØH!4«gƒ</P'@Î§P¬Lq&¢a¢›þÔ¬Àñ0ún%€½‚X	XzZÕ£IÖËþ;ô?Q+Sü#.Ò¥ª8žoò9ßm`ÖÃÇJÓíÐ±˜»¤n’’ÉhcÚ¿‚ep¯Ãø‹<ïíO'áXU¼‰m¬VÐÂáY€uÇ£ü‰
|Ìåœ‘êÎ@×KÈÉo¢=Ák„¸ÛÎ£i:¢õßORÜ|(fEFÃãpÄ0Eo[Cò¶\ÄÛ»Û¿l··'¨ƒ£ˆÕkxâª×ƒñ®:¢àb%§¥;¿Å+êõ•KÈH¦‡G€š—žÝÅvìÝ›ÓâÝÂuØÍi;YQÇí£ý½Ö)†
£j¯øTYåOz²kjé+¾ÈB3¼ÂŸrŒ‡Ë¡ ·µeaQGvµÛð°ðõL™}{úÍ ±ïéOÐÓ€¡`å`’ŽÃ"ýhÚ—Yeæ6UØ†¦¤ùK¹0^À`¬T_°ON	úe`ó±£YÄ}Œ€¸Œ ]Ø&O{!XDÿ¹]«”z ¯ƒÚÕ¯¹ÀÒÇ£w»2‘kFÓ?‹x,¶_$6Ö‹‹#0§XÍ­Íi¤yò¤e­ÆQåZG@OWð$IkÀ~Fã)ý}4IÇÑdGŽ1ŽìDv`øüØ“*(4œN@+mQ?ó‰*OáA9ãÄxðŸNçM¯¹PIØûõdK„ø8sØƒÿ‘rÀC‘p¯Åê~Öø¥F­qß¥Dxë—„Óó°ûÚª½]v”fÃi<Æ¸&f`CÒKÁr™F¦¨Ü/5><É?%Õxr=6°s@þBÀÿ!­¶€¥ŸB/9Š:b!äm7¦Ü“ÏI4¹ [IïÄ]“åsP•a4]u¿ÐD¢QÏë{E³gí@Óöú.ºâ|.¶šW·d»št­™831D§›‡X1šwû»­#úÏ‰¤>f˜±”€[ú‹Óz÷—³CŒX,‡—ïÕýçí—{OžV~Jj?Ýö‚þ¬<Ù{ypxÜÞéð´ù„Í¬§›jªÿVÿhõzXƒrÖ¥5|ôÓ÷÷±—û?=k¨0©å¥u~ÜæiÀó³úD]c°â#$ôÌ_qµBcõöQæý«³Ù,hò7/Qq™š„%­ÌûbØøóü¶ñÓÊñâ(ã·Õ¹³Õ!5 ÿãì"è6mæË°cË8+YÜý¾çéö’
¡•¾{£¤"/ÞÒÑ!(ð­Ý×{®ð™+ÇÂÞ(Nn!ÈŠÒ«t­æÊ0oJó–µÔ™þ«º±æ>Y]æ¡­SÙ
9À¿:[÷Ãvå‰îµjxÙJ×šÖªþo õtOqhZß\+%öO#ðµÅõÍ5tq~~ÀÜØ£wa?Ö~ï”ÔoŸßð£ó¿9oïwÉÿ^_ËÇæ¯Qþwó[þ÷oòù–ÿý;å›÷’ÿ-™¿!è :&çj@Ù·ÔïðÔïìDî;Íâþäîß4ÿúPúõo˜k]’é¤ðé×…4ß“gª6Rß;+nŸný%¹Ö·O´.Žy8"›OÊæ¼]˜žyûu•ø-Ê_ÿ–ßü›æ7«oùÍßò›Õ·üæoùÍßò›…EþöIÌ2ªÎç
¾oÙÍ7Àÿ–gü‰yÆw”ƒû{d„~Ë}üË}„¦íƒ· {õ‘Öì¦¬‘ÕmÒ˜Væ'Ir zû– ùT{Ç) ðÓóÙúmª¯–È8ÚŽ·Û”Ìø[d2žÌI>ACÇ´´¬õ<ÝöWôÀfŸªŸTã|å«eAÞI–ã?|*œ°½ÜÚ–°jaRCÇ—b\ï&‰rvJý"¹sNG
´Ow„ƒ143eVìžêN"´fC?ý4‘B¶GçUœÑ°tÕuCN[ÏŸ;*iHè8Ûß;Á?çe]¨ûÿqï¾=.ökw6…‘7A8l¯e‘ á]ëø ³k|MOH!äýT2÷9p^€îÑ	(§)¾†#Ým¶®ðÈ‹}k–HN­ˆµ¥tÆÖ¼Ã4«`BÝ÷ÞoPñ€ø¨­‡XŠ‰1`†`ýÁOŸ–á¿+?á(ê–?5÷WìÔ\#Ê`¼˜HnJY<;¼´"t=Ë¢Ed-oP²`P¿ep¹=DúDÝ¯ÞWð+ÂöåèM];“Ü•·Ùyôøšàþ”`Þ,1§‘&d}ÊÊì¹´
ÓHÇ*Å„C?¨†¯c8_7'%—çäùý¸¤_úÙrÐ%(3ÇÕ3qyznÔW¿ªHo·
?ú•¾Bý‘NÎë)G²zFY’u0 ¢ºá¶œ:É/ÕºN¿+¾ªò;¬dô~–•4WU–Î&ÝÈÕÙê–D~UªÝéŸ}-Ïv õ½ÂÖë™beî{x¨jcúóï”ºµ»wìû%¼aÍŸ1Úêp..Ÿ3¿U
Pîy­=ö"Ï²é•¤eÜf5ÝZÖ'Æ89NÓ)sÓÞ6rÔê9èÜ÷üq»3“÷Û?ÿ|¥À‘˜Ý)~·×.Ìß”t‡ ƒ?ŸÀÊžb›÷DÝâë2÷?Uª?Uûç¶E¾­ø^6ÞF ´³OÇåkîgKõb\Ÿ™¡]³Bï‚ž¿¼Eõî`iNÀííÚYçü‚BZ;‡¯_·P×ƒhïàºÁkÃlæZmfSšÜÀo·Ê+¼U"|Ù01ƒÍÅ=¶Ã¡ Ü¶ÁÎÁæÙnx%óûÿòÝì>ØK é¶øAî!)‡ÁÂÏ˜égEæw~
ù~vêdI^VÎ™,z?—2PŠ¨ÜôDãp§×¾-áˆ{†ƒB‘¨¶™‰•BŸœEé£â× ù jyU·ÛF=›{n¸‚„cM"$	&——éi®øü¡Ô}>Ùo—lÖEË®fö(0Iœ¢^ÞýnÞó¶Äê¥—IÔO=ýËv],Êh‚)!Q¯^1Î'·|i¹ø$’áÉ¨FAR9BÌkÎ›âóÚÆêªkþ—†.?9¿nnM	ÅH._Õu!ÜÁÿ-kõó>:ÿ©6þ}êÿ67œüÏ5ªÿ»¶±ù-ÿó·ø|Ëÿüò?Í†ûGÉÿä	}Ëÿü–ÿù7ÿ¹ZoþÝòýM³@O8Â½Ùß¿õ„xRzÍž3C8½GÁ_Úí£§ŸG€ÌFh‚Ó{Eï3d4ï£hÀc¦ßÓJ­¦ÿ¾Å8¹Ž}E½†çß^ÿž^§ê{$ÕüÔW3Qóqv˜ÂŠÉ%{;Çí×íƒÓÖþ·ÚÏ Ú¿©Úo%‚¿¥ÐRßRh¿¥Ð~K¡­ý-¥ÐÞ*ƒö[í·ÚÏË¡Ý®˜Cû-÷u¸o¹¯ßr_ÿ®r_ïºøçß`Þët;Þm·¿FÖëL rS•æŽþ9±wY«ó[’g±á·$ÏoIžÇIž»e’'_­ _š¢ã\‹~ds,ö]Ÿ¯°$@(Ã!zÅ¯ŽÄóé¢Í~¿H°a†~ÌÙ0U›¸"—Qô^%äŠÚïÎÞµÛ98t|.o*+Ááþ®ýl Ûðº¶ô# ×++ôúóÖÎ_Þ´ò¸Ó3è^RÞ[ê;4%èEÌþÒÃ.½l‡Pò²¿D»…9ã"ÑDýA„™<°_ß¢ g“s‰g
dw„ÙŸÒ·d_õ¥i—~®åßlâp	¸B1®w»³‡ÕŽ,}YÕÅO-J¢ÊÕÞ)œ|êp-;nüö®°=,^¤£²ÔSG~<y“ŒPÍŒ®Ñ†¹Ån³²Ký±8/~ºev§›Ù©ÊÖNÌu¬§¼“&ýøÜ.ã-F,êæÞ´ã†eQµ£ÿêöoƒ£†›6Ë0ëÓóÿb3oçðà…z6oÖ7LMWþ×ðìæ–õ.&‡×ÇÐÔ~ò”š(L­v¹Î³ùŽ5P¯³ú5ôW©d:–[¨Õ<Ž‡É)ùgã¸7ÏeX–aÁV.AøöÉÁóƒŸ—nêOÈ¾Uþ¯ôòÙù¿7çþ|þóI¯tÊ·HïÍ©Û­Ù4Å”œnoH—eºŸ©tØ1=…ÕS¨k˜/IìžÃÜrÂÿ¦tï’)Ê­C0Wû¸M_Z­ót’bÖ÷d¤j“ò™ƒxsdfþ4Rw
ýtºþrt^/*H%ƒ^™ØÑ×ÝQf¶ï[fö'|~ï×oŸ…ïÆ–¯ÔÇâüï­‡›6ÿ{ã¡Zm®ol6¿åÿŸoùß¿Oþ7o¸¿óÜo6“éH-r{<³¹p‡ä·,ð¿½,pIµˆ~Nb¦^ú+B;‰èžXÊ¤½àLÚüj^˜N02›NÕUdî–­«;ž¢X¯É«Ï¾®x¹ÖÏÅô¼uòêìäðÍñNûÇÕŸAÅÌë²lKû”.:ÖPAKF ]ŒÍ.ƒMO-+Ð€ýD/{`ÃŸÀ:Y:œM1¦´ }°/þª¯ØNP÷5¾’Ï=õï[ûÏY8$ºÔ{%.àüjq†{‚‘Œlš»í­7ûx³Æ.¦X… ìëŠ×FTw§kÑ~+/ð!íœ •ÓôäõÙî!(´^¿½‡ßŒÔÖ¾ÛŠŽ:Ïmó@Ê óspZa|ˆ[EÓîÜVhë>Ïç¶:m¿>Úo¶O¤-^Ô5Änß8:>Ü}³sêÎb<I{³îÔÊ±#L?&ýÑes­¾VoÖ·¾xýnAcö·ÉQ´÷òi……Õ9uÑ™T	ò qpO]Šü(rÁJ\ÏÿY/ÂõµK”N?Š
ý­·µ?çÛvÍIŠ¸¾Uó’©9o
¬§,u1¯-Mì©›™qb*ú¦Eä&Hj¸([ñ;^L$ì¸µ»DšÊÀì‚¾4’ÅÙMî=”=¼Þª«OðÄtO.<ŒéjÉå]Ôolî pv,óúÇ´´ò/t1Œ1×§6üJE™Üå¨\;àGqÖe¸104šågÓ>`È&Êë£6Ç±Wb|ê¹Qn„›ç9ÀÓÌ]Ûy3ð"ËõÁûŒ–ÁûÏ/aÓþbè½=Àd·²õ°\ÍîRüVXc§ã»ôF•ã“ît}Îh;ÔO¾´Sç:ÿ¹õ¶¥»4bg¿„!£9‡QüX¿\¹½szxüÃ'ÌP’‚"÷tæ= á”ÃÁ™hoÑhw8^©g¹ëfÇ§§?`™=ÇãžÒi¼S‘esì,úug4Œ†°Jó"©p»è¥–?ÉOý7žƒÈ‰â5ÌeÃÌyÿ«g(zc*ËöýiNº/oMg“D5ó—ãš…–¥˜f¤æÇÒ+‘yDâ¡õà8£êìuŸM£É»P¡¯´ˆCs/RG­ÓWhÑõãI6uh+Å»/cM“¡ÇS}	¬Öµª£\æžÃ«[oÛ»gèÿ¹v2>Ìs¶U1Ò °„ßØ«ž ÁŠ”z°/T¯ ˜€)‚œ‡DÂÒˆ+Ÿ‘L!R)› N½¥v£•ïk†ÎëúdÉà±|0e’õÇr;¼$y#)•ì
O7¥ÌSL®UAõ¸V%*>49pÊIÛ5¹%NÆA|mËpJî‚Hu‰d“		£ÑñoÊü„%¾¢›6eõzÝŽ4Ðú™ÆÙJ!¤”ºÌßÓ°c†è•â´}tKjñÖI;qMøæÚmVŒztêG‰l"ß0KA¸àa»´?Å$·÷’÷æÚ Š‡¨;AÁdlÖWù†ÊWÞóWÛZVÀ‰˜î‘=öI'oG”¦™æ˜Ûœ\ÑüÆôZò˜¥%ï›[fÎ:”üÒ\úë§§¾~a6«ôJiyÖ$vájs(¡¢Ñxze‰ RH5,êÜÃ•ÆTT/kÓK*5?ù\?§aòmé¤A˜\ù04«"D—ƒ¸ÓTÛJÏH_’iÛ¹)Á6·êK3nÊªh8l™<îXç`âwh§@)š«9	¥ãšá¹WLÎ¬×•CÚ”3+31ùN(põ•d{çèî“in½}:­}.Ý5}}µiWw³©¿’€gÔòkýÝ#0y*/ã¶„ùý²œº=ú y€ŸÖ­ÛÍÇh"—WÛ5¥Íš`­òÌ*Ù8ê²Kž˜c4Í²é—fÁô<P ‹-ÞÏ†(|Ç7Ÿ5Ð2±ìBl‚¾Âª¿Õ‚+æô0¦ÉïóáÔ_ðgOJM¸‰–H:°i¦ "ßuØ×–åôx:¦28fË»{Çgòc%}ïUøÈy€ˆ¢£éƒxÿlµ'»SØ¯ lÈ?\¸µ YÜÞÿô'+ÿô3.d®‰1VíèX4ÆÝ“vû6£”ö`q~Ëá¡Ïô†'ü0ÞÝ ]µ)7p¦*µÌ¸DW—FÙ ²”#AŠDê|æõtv‡ÑyxËpöPÄv‡Ã:…?@Ï_Fó® ·S3xTÛ…TÕÒ^áp——,–W
oòZ)ïýCž,½­œ­[zN'Ì5¤=wy}Ë=™×ÙôþnëH!{VÎP°ìq^§¦'~[izvr²_hÞ¢ëÒæäŒ(¼pì¤UËkú…ãöÑ'ìëßd¦·ÚÂùó,„S:Œ”r‡‚)+Û†“”°M]¢íš
c|uzz¤üÏ¼é`Ó“Ò¦v::?öNöÖ—úðDçl\›®ÄÑ*™®nù5'c—ž+áž'óîTˆfù¦	îòJçÞèT­ø¬ðµìSñ¹gÃðsO»ÒAâœÐD>lÚØ=;ßW¡o oÑ¯déµ¦S€cÅ÷ù€Ö|@HÁŸl}Å•”^èësAnÍùiÑ4¥D3£Îm?·fDž[ÂPb2ú±ÚëÆRì0“|€¼‰ëp²ñÇ“8™öÕýïj›™ú®Ö\ÃÿnÑŸøßMÅâŒÄ)r/w<§²´üK'g+Õ€FH×ò/‰ù›Ó¸*|„Å
iÇôµûòkr3gE?ª<K;Y fo6tåát_©i…"4ÕtúŒQ‡®ƒ/P:––ç,½ï,½¿økŒŸO9j:çm<|úÑãµ{µø	qûýÙøþ>EÂßñD<éÇ+_ª ÜV’¬–ÃqïonÞå\èÎæ}9Ì~¿õ.DÔ“Fht*Ø'Þnw¡‚cv<ÖÇÊÆ)N«ÀZFz2_aïêž>!kîéRÓ—GµÉÓß5ìÊ¥…îÔ¿¿-8ŒsäÎ1®æž®óRL¦®ÿò-îÑn6FMiZAþã;«ÃDüøœI°˜êêh¡û;ú€T<^‘{Õy©x˜/W¶ÏùZ˜Ñ'Îæ·œIñ€ 7æ“æíæRn«—ÛéÎ ¾F¥C…°»å–Ìƒ­¿¶¡ÓŒ?ÅaXà9K¥tE‹þª¼¯J<‹#&µDÝoÜtzˆ+A¦IB*G£Úø¥Æø¾1zY­Û?¯a´)Jèb-±0âÙ3ºçBŸÒ	ö÷Š‡ßeobAy=ž|å.ÛG…IºîŸ»Äê×åg1ÞžŸ]¥³	oÍúmøÙ=ÍÑpÓöÈæ]eÅ36t˜ˆÔtL)Ï]w#0J7àãØŸN{i	mšë—·ar2f¶ÝZßšÓ–èà£þÚ>zìÁý|¾ýe­R&	ònâ9>âÜ[y·cÁI—këúKÝ«Nû¼‹uŽÕy#ïc-8X¿ÙÈGâÎÄUü3mOÌÆùý •åÉÉ²ÒÄ£"#›ë¨Ó'¾ìæét…êe6‹îiý!Æ«J#÷b£ûÓO¹Gì£Þ6tºíPà¶¡­í%-wn7ëÓLŒa¯—Ÿ	&Ìdß»£?{6oÌE®ý••Àäl,m–éI4áÓˆïC½ãñüa?JÎ§v5W¯ƒ?¸§Fxñ@6›DU,…""KcHo˜ÜéP¿.™²G[AÕ†YðÙKÜÃ5ÎØ0[àºçà€hê³”MVƒËN'³Ès}g ‚`%:0›€$ñý«¢Ël»ªÒªý_aí¿Vk±¾|ÄÂ²vL¿*öý&ªé{bqà÷2,9ÍÿøG ÄŒäÖƒôÏüGÐUþtÔÏêÉg>!v@¿}Ÿ§Eòg~ÝˆÌ –Äd¼Tj¢Ïn¹EÒîøx¯[¹¼ÎÏ‚V	´Ø‚m¼ý²SÑ,X<oNN_ãÉ LçU{
Dã?¯%ðÚ¾äó%û’ÿ<÷’ÉÆu>O4ß/oN¹É%Íñy®¹#pš{Ïïà{ZÃ–yžk¯3ÜóÓÐÏsÍÝ³¨nsçyùúXþý¼v^»_|Ï›ÊSß‘ïÉ‘xÞÎóâ+~øÇ¾â?_ÐUî½³E«S0òËÞ+™Jh•û<•àNIS¹¿ºÐ”Ÿ—½ Ò¿6>/k*Disxî5w¹ˆ¾[¬5ŒÁ<ü,>bG!¥O¹4DOé¡:mó¹	…K‹(RXTCNdü´älCNÆkØ¤k\öÌì^ÎÕ.Ô²«—¬8 Rÿ’­—tdÊfûÀàtˆÏ5ë0—`¬
 Xq¾ñUx:sß¦ë­¼Œ 2 ñÈ•É µEÕHÍ<H,æä£oƒÊ‰3–sˆ"3	<>›³÷Ù÷/ä¿²!`ý	Ó §T\ëÌ"YáèEî`MÙA8¤^¾ÒñËˆ!²^F>¹Ú„
:“~vÛc’¥”c*E*>;u4º‘1Á@ý¢—@…¢¶¤A©œ
ÕÚßk™êîÔžò¢a’-×¬<]¾_ÿûµ²R@ÉÑÊjzX5”‹Î…±|a,ýºÌPV ÌÊRã§µÆý(å¯í…¬D"å°üß’-±ñJIÌjé#M*ÇOÅ€¿ö’}P3ä¸ÊB*ð‚á_Õ²Ññûb0üÏð‹
' ÷hH…b¿FØ›k*ì½ÀÛš•'|™Ñ­l?€'_qòà˜ç8×³Âi|a«Á€Æ×d§#üµöð\Å„Ôµ«þ4œÀˆœÇkN. µq_šë©ó¼ªÞ+(“4.ô&ÇMŠGi£‰ùjNü:tí'7ÜÛ(÷Òi'Òä˜ÙÓ%Ê÷È4JÒKjwe <­TœçÃü±l^÷–,t™cÙÜþ9—ý•¤`²O»ƒªEa’±ÑÞ	“»¬K@ñ0ÂT›ír{“ã<Åk·™±ôšZžD½Y×{Ùay	N1$gôÎ)§{$Ê 7T3hd—ü/áºÔU–ú6©ÎEG‡~ŸåAí¿Ô£´Ü–Öè®×$;ÙFVðnòYHÛ¯3'ZF¥Øÿ=vÐ×¡Ã°¸Ú“¼ëbÐ7XôéqÈ †¡.F5 	ˆÜ"†>åc%4‹R•w°7V™ÂŸ“4©9M¨Å‹trNz²f‹)O‡Mãî{º
|LB|šÂ»Ù-²>‰³>”ôÎÏœn‹ˆËáÁmì&¤ÜFW¦“PeC¬dG§Âa±Ÿí¦/HE@hºø*7cÝÝÅ@îMN: zËc¯@+º¤K¤ÿœEÖ£÷6E@ÍÎäX²>úzçÎj>C–D—žþ=ïÂ™Ã7\ðüìäôø6ÉÞtšçŠ®pÄñ£ÛÉµ“ÚôsVo~¡<Éõ†—Ös/éøõ¯å2s%6{ÃK›goxõÎds„éå1[šÈUÄÑï}jä&O `ç…?'anQÇ…ÔÝùÏ9ŸüÙS)I½Éƒ\Ø@G¡ý:ùWåÈåÒyQ5÷‰­™·4Òç;aš!R¼¥e­V–ü$ òÜ´ÊJn°yAóùúy¡óüsŸ’)èÔÜY¼¦Rz¿çp(úûã/© 0‡Êj”ü.ˆÆÀpõ{¬JjFmØCéÞ5eÂ¾@éAºÜ
ÁLNtßvÝ·½D÷më½Ä¿ólï¥éWŽªÖQW5æ¬g²˜æ`ScafäÁBö¨¾"{ˆœhÍuíT²ŸwuhÛÛ#TvÊ«¡Ìå>}UTž"ñD·)s"SùdåÇœÑ¿ƒ]ø·³•~÷p‡Ìùw!Ò;£K´û`?·[§æ^iÌr¬I	£ñu7–?ë¢@EŠd®aŽÃÏºƒyWˆ›2Pó@åËîÝâ¥OàóÞÅJ»Ÿõ"ò-¼¨«`Ü§Å’Fõ]hïú­QÌw§¾
]Itó0½þouRšŸ	ôSÐÎ-ô¼ÈúRèöØuùYíÏÂÌmŽt«ÏÆÌï»î7ÕaÅ™Ý¨_8w¬+|ŠV¨Oxc¹6SJz{njy'N¶ý9m»…!åw]OñÓ,·;ðÝ¶xíwÇn?VN-j·®¬%mQµIkÐÃ,ã©[‚4_¡Ú´°4µÛŽãŽ%_ŒðKF“ƒuÓ òÍM1Qtjâ<Èl:ë÷mÅ@ª8›rWGùm¨…ã[¬ï”Û9UÊËsÉPç¾ïs“„@ÓÑc·&ÁïÕ,“üyuóêÓÓòýñn—ï$ýdp…²H(;eÝg» ÷ó£õ¥Kà‡uu%ßùä÷Åœ™;†ÛñÜæz5í¾w‘öìÖÃ˜£`-LéKåK±>ô5ùŸWeë[•ã"’>)ÜË÷XðÜk	˜MqëdÝ‰”ÝÿÔK»¯}ÇÔâû¿ø¾,¾ÿkkuíá–Zm67·VÿIm~íáçøý_¸þû{;íƒ“öWëƒ.yÛ˜³þÍÕÍæzný×6~»ÿí7ù¨’ÏËƒ7êeû }ÜÚWGožy(!‘B’‘|ÞJÚzU­=Vž%‘ZƒÅñã«I|>˜ªåz¨^L¢H¤ýé%€~w}ÒÑ¤*°Æn]}/%‘úY¿žNÎÏÕ¾ˆ&W˜igxéæ(ž¢nŠÁòñi,=<›w0žm; 5´1–Äæ<HxsÈ) ùòçª‚öœ2‡™Œ±Éu‡Ãô2êÕƒyÓ¥ÏÑ$
G v`«SPJk”(9TG³ô¦¯C¸!hgQT¥#*òÌ¿2œ
•‚Wïã¤G™ ç¼Ïêºy+“«Âð:Ûâ»c<QÕçùeª³Ý‹²øëßãe2xZ#¼¯øH"A Z8Ð8“´-RÏ¯Ð%‡èM«ÁôÆÇÉ4Jz¼Nç³pÂ÷(ßcPè“$¥‘æbÝ“óI8ªÕ¦©=h¢è25ºõ‰ÀYÒ¥é ]o³ ÁÐßÑÁ”héÍ¸(y°`Nå)V[žÌ?Á±„ãñ0FõKyÃ¼°Ð1¯¢óˆ"ÒN‰õ+aH×ÿáHg˜‚Cð7„BØ’ùg0…4%Jx‡!ñË³HÂ÷8Ä€OÂùMðn<ÊÒÅê¿Œs¼ÇvŒ'1žSU‡ ¾|¶>Õ(õ”“C(Óñê³yÆ§–e¹ñ"e$€0Bu@ªË8¬TM˜aö›(‹Ý´ÑÕ!‹§MK/—!¦ÏNW±CÆ¦{xWÆÖåÑ!ÝÓâ›³„Ü{LlÑp{”ƒJ4ƒ¥9y¦øê³’hÝˆíe´IÄ8O¢Ê[FÊW7¨èW¸F8	†É/â8Ãì½üD»“<Ó|ß´nU'¾ +âÂcC\” M¦!å¯aQ€,îÄÃxóe{Ø¨t•\,U±û¸Dß‹ûH’ÛEx0,|†“v	·Í‘0óïþûŽÆC€»hÙ¬;°;P7à´¡s<wO¡Ý­ú‘Lv„§ÐD³OîÉ’‰`2ÍxFxÃŒ++VOvÊ‘8^R@›®ª[é1¶Uœ‹T6 r!ÊB¹•©Œ†x1Á_±&Â“ÜaŠ¤A¦ÄŒöh¿Œ¼8nz™â=¡ãl;Xn®(¼ât2%YÃ²‘ã-.RöòÚ
àXÓ2&ÙüÁy|¡éns ©›‘Œ±[uWÀ5ˆ;
¡˜Uç*ÍzV÷Ù»À,ï¾žñ_š&L±|rüÏÎ#sôJL"ÏÀ<'(K®ˆhÔw©sÇ ?fÿÔi`:Í`mwÎ‹'‘à{$—vZÔ‰€(&ï©8s ÙõU^EVLüÔ€QÆ÷‚Ëu0áTpÓ£øR¥³lxE’G‚äŽì †L„·º~é–paä</Ò=öøP*áàþ˜Ì’ 8ÜæÆâÑl²pˆ÷ªž¨É(Lf}P`LátYJ\e: e&ªOx¹ Â4BØœèaR aŒ Ðë”$+áÈ‰ÎÌ¼LeW@ÊtN aß$–5tpK¤ÝîlBq5êô0F&Ý‹ÈªhO@Â½ˆcÄ9¼…Ì$îR&ï9DÁð/™®øêYí³±:ž¢?Ég­—‹;»ˆ}øBŒ$El> ‹gkc‘Ðk
ÛKµN'hf†ˆÂ	Þ”Í:è%ÀâØ„eÑ%äžKþÞ£sT3?ú€ê
€É5³ÄSRzYWPý®®!ŽÀŽ½Š%ÈQViiÅì&ÇØY©¢'8¾ªŠPA×l‘9PØñ:#MeH:!Á1þŒ|«ÛFt G;IÿÖDÂÀnêN5+!ï
Îž¨¡ou?>'êLmÌÉô:Íu’±ºOD“fÂá{)‰gT:hk^¤1çËêüÜé„ë±ªGb­ÞLœ.„
HŠ #xkS÷‡„Ð¹"05¯ê¢)°&€ëeÙ0î™æFîv¡0º™ða´ Ý5fðâXŒ¥ D.r‡4.¬Äy©}º½jŒz‡ÃÇå‘ðsó"®Æ|[è´}üúDµv±’ÏîÞéÞáÁ	6^­ãy·8áéýÊ©#c*¬žÒúê]´nöÑ\-œ«²Â
7g±yWÆïñ’Káë¬RCG¾meSÖ$bDÒÝùÀ	³÷fÜ˜{„hwØ¨ã›>ÉMº¾Øh@²JqèÑ+Õ¡3iÂ–a¯Kžqýÿ
ˆÜ
´ªÈQV¡%©X¥¦#»BjpyŒlå0‘JúF!­°H <6I÷Ë™€A¡ê…cÚvø…²þeð Ïà¨~˜ø¼

LdéV»°ÊAU0L‡ûYœ‹v\€
Øe­D8ý„R§±.ÎøP`Bî±ŠŒ)@ý ÖviƒôWE{ÿ+Ô±ÛŠÑR•n
° >«*¢X»+1}Êb;à	z z”ülŒ»;<§Ì…<ž{D&d%°|$©N«ú:óÀÅÞ%ñ@b ¬#ch	HÆ‘EHš àëãh;ÅIWƒG	ÁêR»F°€M@Ù¦¯cŸîù@3Ie”8üñø‚„ÐšÉ<‘@òg 	<>²L“púÖv—©€'„anòå=Óng.Å¢+'d"Ðb¡<½`ó¶Ìe4š• ]DyrÇ}Š{^´3âQÂq/ ñ‹YC«€•X l¥ ^“Î ºB>ÃÅGI.¢àC]*à:ÅÁTuy&5ý5ëóõ’¡(Óæ˜Ž/D#šMl?w@@C‹t‘`­1Ë\ª}Ò×RT9²J 6iLylîÊâ…Ück‰
€ðC×¨C ƒ«¢ÜEh_˜žÙ]aú¶ä–PÿÆÎ¦°HlŽ	–+õÂI—…`…6ÜIÈ±¨È¤ñ€Ú¢]šÁfÄ,«ƒàZÆ¬Å
”L6G˜ÒÈcœ‡–ïõN6×ë0Æ+I10×‹Ñ$ñ@MH’VzLlÙÊš0€;«²±Ë‡…A?H"§[Ñ"2b‘1Nà×	À ÂhÖ•Ä›vÐôÔ2¿âØ£1•]vÄj:…ðt0Tvù<ù·x[º›•-Œ)
¥ÃÎ/qpo÷êr5ªzŒ÷UÕpÒS{iöu‘¼™!Çô˜§1êa¬ì"}É¨’!;™‡—^I0ÙÒÞz/ª•tÆ
¤½é(sîÜa$Ñ¶ïÎ†¡ñ¶CÐþfá9:C^€Þ; ´á+cá(Å­ÝŽÓ&Î*ìEƒ°ktBæTg"S«°t®lÕÙ£F|ˆlŒl¥VHJ`Æ¤C]zg9\aï+½ÝÓHH`a€/Èú Ÿë¾Ï™É¿$ì »Jã7Ær%«@Ô<pšÓï¬(ªÆ‹ŽÖµ˜±ŠŠn,F" ²Ð/n} 5t±†¯Š„CÆƒÂ´™”ŠbÂ²Äºè±	*¹QT„lpË¥Ðé‡©>#ÂæÀ¦¨«‘aFž^
–ßƒ•‘Å'=<ÿFkÌ¨õ$ž1Á™òº
É%$!Ì,ˆk½‚™'ÈŒÛ§
°ï³*ë%Ø}<Œ&Ú,³Ò:í¹ì"»my·˜Ú÷¦öÙ…îxÅD™Ñxì$öaQ	’†Ã çsJ]ª©ª=B<}§+±éBs;#Ÿlª]MvªLð„Oà•c2ŠW¤C1ù¬Þ Kÿ*½D«µŠâÐ$ìê=§ÁÞÏ‚üv%¤æÌiš².?À°„Há	íTÖ´;kÎQ:«@ˆLrÙç†Œ»2°/ûÛ’G[ÏyZËÖ10¢ßQ$ŒÆ%#ÐM»(Ñ{¼]e5ùGñØÚ¥F~sq$	ïÛ´q”î*	G|-r€—œ"ßžujLé0mèÍBu½`â¶«Zœb46åˆî §´9F³D±dî2)ôÑ·Ð•ï^cwŒ;'ŠJ±ƒ^½AÊðÊ.~—†ŒÚ¯]¹“Œj“ÈV,s/Šk¬Ø·×]ÀÝ-‹¿Uó|ý3À€Ñ3ng¶VÇùÀ™ŽŒAÂfdìBq6ŸS¯W¢@QêŸµ‡¾”6Gô‘vð“?µ@˜ÅEÊF‹Öå˜®Ð;ÔßÝMµKR÷ï[Ak@§¹ÉgÉ0ÅÃ÷akÞR´úÄ8£ôw^hœ°\’VùÞ¹òÑARPÎŒ0¤ª:%9mF|‰D9Çâél*º¸žŸì$½ãø<â™:LÔã<æ˜jšD@¸?.Â!ËçÌ¢´såÛ„´Àÿ 5yD®qDŒXlÔzÃr"(`Úb,‘•kcÏºn¦¯òD´ÉZè˜·{Û9¹%ÑÇ DC1I=QÚs§&v&4FW*	FWæ ¼àML›L8_—‹b8ËØ)‡ `\ÄÑCJDžœQÇ¸úìWO,[Ç‘C©:æ2ýÊ !Ð; ËŠ+³¡Gnä[“˜õ3‘Œá@ŒBb]fåˆ6Ø‰9ËŒÅdnÑ™*‡¦È¥ïa¶-P'„Ã~Uö7=bà."¥J™æÆ®QÇá=â-£|ö‘q|ãÙfQÏN(G‡$0&FEO`½ñ˜E¼I´ºcð&ÎgïÆ“îl¤<y™"H#¨±ã#ÇÒ(1˜9z9•:!uV‰”x/ä	ú`Hœ4WÉÉ›¡î0ÃšÕ ¢g¸^G>¢ão8îÁFù1oØˆžH«ÚýÀu_¶ãAê-ŠR ‘ÊiÐu{Fì£Æ¤]Ì°ÝA’Ós&`[†Æ´8rœB°íU6i>$º	ŸËîöhÖljônïèÐaStîÌ˜µœq»¶ªv£¼Þ|üx÷TãE“Š±šD4©ŠKŸ<‰$Ö£çÙŒÞ`Ä|^É±àË“•˜%,Y@üdH¾gJ÷§|—	iÞ«h2â™¡‚Ú:éÆD0Â’KÄ#±‰”§A~‹²(”Àxwˆ4œ	%ÑLEd‘ Ó†i5¾«Þ5³È.dG	rW2"¥£òíª¸¤›Ty»sLuÂT»ö¾ Sff°YX´ ›´zugß¾ÕùY;ìPs%¬n.…KOLäóýÌSiX¸ÚM‡) è±äÁf‰g£r6dc0ø9(KñaëÆÂprl€”¡¿^òÌ:»žt|V½Ü!‡‚)†‹,Æ(‚¾ÒÄW¢èAÑêÉ…‰ÙôÄ~»T
‡UqaAmPƒI©·` ‚¿°–k7bÞqe|nOhç´yÀ|sÒ'Ê}`Ð*ÕÞì¼7Ü,$g÷`7”k¤¨ ‘üÂÈ¢Õ]T$½ç'd³1%Í£pÔŽB›<`sBh›.±½ÖºhÆoÝ@{Žê\OAQm#ï36w,š¢÷’ø^´SÌ¥ZÍ"¢À¨zi7Ê(VÂ\‘„ihA3Wms„.\!å•½~(ì»€°+ÇÉXJ”&ËG_‹_GABJ`»À+,%ÑÀÎgõEÑvzß$Å•™¼3\IÍûÛ
®ÌC­*‹UH¾#™;=ÝÐ ÒˆÆD•9§"í®Ø!­Ã’ˆ æ71–°ã‰s"ø¾žÇÑ—íPWd3öEšeQ¦3	B#Ë “©NJ`Pu÷cNÔnÁ´ÑcT{&¢«jîA£vÅ‡f’EIÖhU–ì<œô†˜w‚º6'1]±ž\Š”På.ÈXP¢÷}ÌÅ¥¶VÄÉðJböÖCÃÄ™€iÃ•Ê8wÂ•ä2ÊÔÈ"¼Mø¹NöÒn.¥z+ºØ$uŒ·±Ïµ ¦ˆ_œÚÖenàå	âFüKžðÊ÷$2žiIKàëF¤ÔçÜ^Xfš…ñAáCº8§ï°ž†FWðu(¦Æ¼ÆœDázÞ¹‡~N±{|7™¾¨µ'&"ÅÉË;òâï>X‡¼ú:BªÝ:¬nŒ0²‚òÄxç«h0¢±‹¡é‹t8ãŠ²!pštDˆ¿yáH­
8!æ$¨„ççHÐ·õH-ŠhòÓÌ‰R[‘/#´•U3²œ•ð§´ ÿ¾¤'X¢$ÔeŒt\_Œ^6d0ô”ÉV¶|¥‡ÿéYŸf7ä4BgK"rµû´º‚D´³åÊÔPVDœ¾€Å™#K}GI‰ÃØH@fF•€pfDþæ\AèôF°1vj˜E<¯Ô#–ë,¯Ò0=%‘¬À|‘ºcúË9ÓI1 ³¤éjÐ\e¤KšY¶þi§E	®TIßÃ$Ö~%æå®¾øk+¡êÍ&ì?ÓÐ K0:ÈÙD³ä£µé€€NÈ³¢ýwsÈLm‚ö{ÂZ`U×gmä0¨¸_0ÿê*
'ìºuš°ätüOZ™³´špŠ5cÆQ2Ù±ÄN3P'0¼ƒ112µÑ-š†‹)‰dRB./‚Q¦ùmYÂ»‹c(@F$zÔ\çcµœx"„ðÛÓCUGHIs)>J9@¼F°õ²4‘„€ë>Ñ–rc¢ÏXï—Q‹‰ª0%Ù¦µŠy°ˆúQåu†G ‰:’TL«Á	=;ÜÕ·.Ý¥“ŒgÁŠô(’âµ* «Ã…CLeåZ¾q¦Jì(N»Ý0#ÍŒÍQ©cœa‰6*BÑ~e7…½|ø,CÍæ1v$Ï„[t´‚¸Õ±zÑœßkŒ¶3¯‘ Ÿ#3ä§'*bPi9Ÿ³Ïë±Âª%cÐz©U_¸àbQqä‚n~Ÿ˜ÔezÈp¹œÙ„½ƒL,¨Œž$†wdà6t—³€4ÕMs‰X¤ÏJ³íVç’o<Îüãí#¹R‘ý2{†˜¿C´[oÎ×>"æ!Ì.s—@¹Ï·#Ù G)f«‹õ­wó†?LBáÌ2	*§Z£BsÈp.vëXÕ53H3’IÒŒÏuÌ}½*{G«›¬¤o4iLÖ
uµ$6ŒÈ°që)™£Í™gMf²k¢¹»fF~ÁqMjÓ´†ÿrú—IùÓ&88ò8a#J*aÜ•DÂýØ ‚
õ|ðr'bnÛ'!Ë$Ñj#aw¸oÄÖvØDOL	¶Hº 9ÎGg€h'`Âu{ÄÁ	IùÃÍáßšÛ1ìžM)°B'	ñh‡¡­ÐP	M¹ƒÙlÄF5Ñ†ŽÉt
¦xV”fËB†4Zfì-7a3m\¹ªƒ,G q«xŒhÂï¼`J‚W™•€:rlBÞ$œ‡=9Ú \°²/:¡4ôfAbÚ 	æžJÙw4ÉÐh±¤ýy“­½tÖ™ög\“:³QXštxÁxî‡)¥-’æžëÓ6n•>Ý`Ååj9)VhöTUÅC”—WL¯Æ¤+¦œE‡÷üé4",T>³Ì9òQÍ¹%tÜxfÎ6ä:W<	Ú !¯°	7¹¦ž…Ñ£ä%Š> Ÿ$‘ó˜#0p:fÂYv40Ì02jd)Ús#×‹åÀ ‡s$°z
õÞµiFWñ–x¸³„@“.€O ?IW¤iHcäÔd·Y$	ŒCz.”	¿Çy;l ï§¢¿uz»ÅœÁL+íeU¤nÔÃÀ@UÎIÆºz]1z™ñÅ¶f¸=ç¨98_(*9¶Uônè|<o€È‚°ð>Ÿ	Íækt‘7<ô
ÙS£¼˜‘`ã4NfÈ¤0¸(¾Ö¡Œ[œ˜V ¹$HM9uQŽŠ0`WÏ‹Ss(´Ù‰ÈÌ÷ãAH9Ls…’$º×÷‚hIUº®XÍôÅâÃî8¬çfåôå4-›.vmn£íóÉ-°ÍL“Åa¨»rv¢dŒô]ï¨=ôC:€·š˜Ö"™ÕŽŒ3ªäW£é,ž^½4`šRU–KÝ›þ3{e!&žRÂq”Š0ž·ïßÖH%Wb'ríÞ€m}5oáü™\¶ñôO«Ø$"Øp­“”ÀŽˆwUÐa0
¡²wåî­MÊ¡kÖ¼=ŒSâžI7s©Ñ dÙq|øzÅ¤-¹ãwì¨yS/fè…A„Þe.8mÒ£îHéè:zDÍwÃrn„Ä~hÏÚmcð0q¦"«dèª*¤Ðc¨9¾	(

c …¶	DÝïEä¹DI!…Œ*öM"…gö—EœEÒŠØ½3÷ÑÁX.âtHñhr3)Fg8Ó.f7öEÛ¬º°;I³Ì$)ös…¹ë¬µarÈ¹qÏÒÍÃ'“èeãa]ö.ó˜£‚Q¹œáù	ÃA>qNlWê][ŽÀ¤õYAS•ÒŒhb–`X„ïè ”ä±´[ëXlYÇeN#íP­8Om€ƒM"7õi\ò¥îM}ìiVòqøD¤|Ã$âC?“H‹=r«åƒàžC‰@I¬I§MpLL‡;HnÀ9#|ÈÍ7µ™Ó¸Éê®#ËËÅ0gÁ9àÄ¾¾Â™'Ìj#I–Ž=`Ï·ÎRwshMÜVŽ{N¦z’*oãIfèhÞ8°9\U‚]©äU>¾ÒC0yŽžvùæ&Ä°³ª,5§JÝ >ŠÐ•'¡/ïFÇ³Ã©QB6Gê3Ú
K,Ï¡AžöšÙ¼]‰¥—2x8©YÁöÇ¥ž`.Ó»¾bƒäb	æù„0ÅªÄŽÅ/B““òóî(|¨K=¿·4ïÃö&y[S\F:‰¢SßtA};wà¢2:	óXð¾ëâ Í*Ò)Qœ­0²cB‹2¢ê¼[4ì•…ŒÂOS¢ŸlðcW’ÈšÔéßÂ˜“‰µa|R:Y;jòI™jn3mnåÇðuL„86ÇMÉl™\ñeð8îg¹™´2ºLEê]›6ÿp¢}‹…h+‘ˆ«ŽÉ2ê9<‡šGÈÆv<µ£ï®àö79o@)Æöòd0¬äyœãÖÒ¬ßž¸S£BG0s±E+ÄWç`è’ŽíeŽ÷Ð¸ax ¡)¿d§Ò[Å‘ÅÆ–3©†Ä¢^û0p0xµýÁá}ªuá®„±Ñõ€mGÑ
¦™lAbËeÕMÀ˜Áéq£˜F	­aEÕ6gãR4AÂOfûí»”†ïQâ¥ÕÙ™8Lô’‰gV#ÿÊÏñ@îœyÓUËú”mn%ófEßp†µ¶Èû@uF"¶i8ŽÖžSFû×É•ÛN$'§•Â5‡AAJ)ƒ]ÜÅø¥æt s¹\[>Û„d6º'@¿C¾V×|`RAI½Á¹ËNDÿŽ™Ì[ë`×ÂÕO ìQî’=ZºÇœjÏVO(¢,-ÉÐj^Î[ÈÆ¢V8CU2Ë°EÎòDtêu“B5:3¾À T@Ò,8 ­?›£ÌG[¼œhWõsä™`±DéÏÜ	Ê»çiÚy~dß(5Úm”ÃžÍ`ã]HÂÎ¼ñ»>
.«¹…A/°h¾—…BíÀ$á™6÷0S•RF ´âT(®_C‚7„¼N¦£F»DQA!Øá)ÊFÇo²œý“æwTU+T’².a{äÖIxÒ:×ÐD„'úµ0sŒ€'û DÝ¸†LWü 4h¼êd Ä	û#Ü¼:fNŒØZP¹•“Ý4†(Ó†’Ši€TTU×)Þ¾éœa#ßô˜ÊS¸#±Š›j”/çŸ²šÊ"¯Š–>àìx7{X	¥ƒ›Œù£P{XÐ±ÂoãÇ¶šìúxå$…‘òN—èPÉC2¿KUÄ©hÂ“ÀÔŒä¸«ãªÎ+€Š|Dä_`x%0J(”Å3L50V†¥z¤wª*é}.øc‘èì±g‘jC.#Pµ¹U<à}°¼i{ãêKÌ’ÛZtPÍ Qäê0äWÆ†|`xkUõH«éOe%è<†!Ñ×`Û¦„uïÒ­8HtæT˜’~ƒfG™3—àæ¹TyÅcÖúñ3[âQdëùá&¼@Ï¥}ž–õÓkÇùáÚCÝ™-Tƒßu¿d|ÀpÆÆpæA±sÏòüµ°Ç|GŽqëÙ]‰3›¿R‘µ)²Ë*tú†é€&Š³)îæº–+¦1Á"œé»'©Sw©
¨:ÇÞÔ‚þDvij*„àÅ^V•)ëe/£6ƒ8{\'ïßX.YàÇ:âP^ñ‰¶Üq	;éG¸v™O”(Ùãt=P`˜tÊÏËH²§[IøfÈ©Ü¦ZJ1å¼ù¤2K"Ô!.¼$KNÜ œaÉx°x1yCÚm,9¸Q½ h©WzÈM@FNÍ;ÒO?.“ œsž;†ÉIl¶¹àŽ³÷uEK>­W²~%9tÆ™;|ô‘\8`Z•„ Ò+D`Yö=—’t_Ô”[ZòIQ¦wÓK h,_„¦_è%*Ne8Ïœ³V~TÅ“®šOeŽ‚[´/1Q•ƒ¸U£-°ÇYV…½PŸÙŒC¤yˆõ÷‚T'’Zd=ñ¹Ì˜/þsc!ÄYŒéÖk%ª‚^<4žlü§Â¿21'î‡jrÁ+·$«`^Y?”ûXª“³nÁdÔm(C"ŒQ49gÊqë}›·]©AŒyÌ:k+QÅÙIš;‰¦\ä2pçŠLØYb—}p¦	&çš˜·ƒ[Ôòs}Þ€c-l¿ºO{tŠ’Ý0ä+˜t¬«Gž8«n™â™Fãõy8ÃqÉ)Åü¹Š¹:w
†\çŒ	Õ™ ÿ;%õOs…‰åÈŸõQ¿)WµYìmä<%&T¦#orÌÐÄ>sGòQäÓ¹÷yŠ´WBŒÂÀíßîX¬®;I¯Â¡DÊR'…ŽOoÙ±äÇ1¯¶Ò•;c¬6;ÓÌ˜^/Y˜K5>ÉëO©ô‚>x¤t†®Ÿk#>puilvÏFAª,•€­pÖLÕf6R9öp(õG”Ý$^/·(öcŸäTI³YWGº¬¥.9—°×1TtâMNeÄ=e<ºt& ÄŒÏ	i§0W-æÈVà¤cl,xÙo³ÌÖ&´!tŠ‚v£;jS~Ïœ!ñZÚb8.Ú%JÅ÷¿;<QÏ©ÆáÄSÀU›´4äú¦aW”X¤¬êë§U-)°x…'…”¹Õ]s$<(¦L÷óÄAîB>#-a±<RªzeD!Ô‘ižêÜ!Qà‰
€å%½÷ËŽô–ôÍ;:p¯4![Ì¥*™+¶à›M¬ÐîU©3ŠrÇðiÚcŒ4vÙeÔÄ$¼z®
5ä¤g›wÚQ;JXH~S~ «N†=¬ªe¸Nkæx&·Ãú}"œCƒ¨\\Ò‚ò²p-e£s¶;írÞâ¶ìW¥X ’pï2ñy„ÁŽ,}ú3½™‰P±X-®ÈûTñ'ÉL"¹Òî‘ šFââð{<eÿ›œ/Ãä€TÌ—*›R©è=Y·8]6eç¹ K•bý÷w%!ä¤Ëfâ÷çníÉ.k[¡u®˜Bîþ
Rrk¦@¦Ô\ç\õ9³-ÌK“†{˜à–e9åÔW,££¦SCÖÁ“ÂPù”ÚÜäTWaÐE"ü4b
¦V:•	Æ¼I}.ºwã‘$¥sÛÃ@ç48äŽ<!MYØ’ÒIbëb¦& ŠÎQ'õU›3W˜ú±:²tnU1xÎ†G„µBÙF¡„AQ'J€!ßjŽ L	wÇc*—-¯›ª.G
nÁ‘Ši¦>¶.=]³ÉXDö( V<üKžXtáBã™‘HŠ)Î£¸º+
íÈ‘–’*(NÊrPpo³Î3aýKû\x`|p°ìleà¿ÉÒÇ¬nªGŒÇ9AÌp
·š– h  ”9s'~Ôd™†qtÙ$ÙuUf³²Xm†i&‘W&…ëÐOª9&Í¼Í©àÈd»aéLÛZÐB,ájÁt¦ãë?,ãC¤¸ÙÁQ&ÆkY£ ™ÒB:Û×ŒMŒÀ4p®ºÚŸk)¬é¤„Jèâ~œå\ØLÊâòÁâ\öôŠß+~ä§Hµ)m 
k+èª‚õG&1‰”trU‘[-	x§ãb0;'{ˆ3Ã«¦âK–7_X·ÎlQ/[o5kèäÒ“ŒöbSütÔùVHÝ7ºòÂQ%žR^­Œ‚É’§	:	•$ÖÔAR’HíqGò“é8x€6å„Äà8¼QžSj
ÒƒW•BJÓhÿª	¼âÄ|a+¹}nyØ¬›UuIsÃª­ã•9‰öÓv‡v¼VéX’K>y†OÕI‹\Á?‰ç±4“D+É;Ëœ?Sißžq/q©|¼ÂÂƒ0:âÈ)žI¯¬k³EÍý¬zècÚ™æ‰-ÙÀHÁ±Eä#èqM!PËÖs°ÔÇÉeh¬çªõº¯=R¯Ã	¬Þ™¦ó‹±.-ë¸ýÌI*&7™™Ÿ˜ÓNªÈ˜ ‰™¦›ÖÀt0n¯®¸$¦ o3*2¦.»™“ÆíîF:õD¥°Us­ŽÅ­NÌ5F°Þ‡1»O7sõÒ‘ÖßrõþØEÑ“:ejYÛ‡TÎnF•a8œáèv°+J²Ø0ñ¡wMZ¾î¢,äv¥ëÛ"QÜb¿Æ74ÿÝºU?ùÚÍh|Ÿ¥RÞ@-ËâÑl8õ=1œ©W¨Ìå¹t‰}R=4uûšˆ—‚_ÞuÿÈ ñ3*~’wižˆ¨%ž‰ëÓu|wêº`Ñc	mÇ‘
dŽ`ÇÙ³ð0˜‘#òƒ\*¦œR‘ëêØhÐF×ü$sÑ…‡%c‚S ¡?ÁMÌÙ™:GÍ?<æV3j®×1£Ûj™x/E-ÈtÑõŸ•hÊ|‰”ä½p$,‘QˆOhiäÝ<!ù©¥×j,¾’ãd¬£¶.‡­õê_È]à gcÊS)ï&é{((QÇ¡+0Ù@çÕê\ë¢º‹ÙUx[§| n4á´=§˜¿±ºŒ‰ÅIÎh/’?Î§«˜^6êê8‚†q¿Ü»—rîDÓ¼»9³U
Mš\°…F7aLO{Þ…´Ï0œƒ‡©À!àØƒƒóÃm]®+$ãIlNóJÖ¢ñz‘qƒ£ä$B|¡‡'J†t‡_gB]˜KX'Ft;q&Mž€®ŒJÊRÓ¦Žë¢[$3,,h2¿“\.9 Z4)Äü‚¢+‡« ‡«Š¸uñ„õzš{©¾Ý¥4Î¤&ßãã™såŽÜ:¡J00#äë ò#Ð”`¥Ý–nŠ‰qFgg<¡¶ëcT«zóIÈ¦u©ŽRh ä2ãÊÆçÐµíîóáŠoX„_ÐÌ žÀWV‘ŸÙÒG’¸¯óùôýLœ)~Ú—TµhrS>½wŒ‚®ßÐ6¿+FöiAµºe&X=Ÿ‰›-™Nlvnàæý;ùCIê½á(
9u	O-KtZ’áBšsqcNÐ´$—	´(™ÙmÖMj8“Ò;Ig÷ª}ÜV{'êàP½k·NP/ñut|øò¸õºªNé{ûßOÛ§ê¨}üzïô´½«žÿ´ŽŽö÷vZÏ÷Ûj¿õoNú÷öÑ©z÷ª} ü»½“¶:9má{êÝñÞéÞÁK¸sxôÃñÞËW§Á«ÃýÝö1ÝPÕ€ÞéEuÔ:>ÝkŸà8Þîí¶Ý1©Jë†]QïöN_¾95ƒ_ Ô_öv«ª½G€Úÿ~tÜ>9 ì½×0â6ü¸w°³ÿfÆRUÏÂÁá©Úßƒ™A³ÓÃj€½I[ð_·w^Á×Öó½ý=À^«õbïô º Üµxä;oö[ÇÁÑ›ã£Ã“v]1
 üxïä/
f ˆý·7-°0^ãeóØ—3ç –	§«~8|ƒ"æ½¿ë!ÕV»ííÓ½·í*¶„nNÞ¼n¾ONhÐÚßWíoëøuÒ>~»·Cx8nµöŽK;‡ÇÇåð€Éh«ÎÉå&à±¯³–™c µß"}¼9ØGL·ÿíÌ©DùT‚ð[/Û„h‡&‚w{00\=CŠ	£J¯À–0~ ;T¯w÷^à²áì¼mÿp¸X<[’m=?DÄ<‡ìÑx`ˆ%\·ÝÖëÖËö‰CØg —lWÕÉQ{gÿ€ß öU'0W\Zx @TÖ! qò:o`# hÂ¾ñ™;ØeÛw‘(Õþá	R`°Û:m)1üû¼­Û€(Úc­7Ç°ß°¾£9y;pï€WçK[|ïx7Ð›ŒèöEkoÿÍqžð°çC@!‚$tV‚[œ¬T\|µ÷ºÚy%Ë¦¼­üƒzKñ¼ÍZ»o÷h;J?0È=Á	ÌŽ ™úÖùn¼ÃPàIáŠ+¼zÓ3'b°áÐ#d›~oŠ|p¦­½ÑŸaŠÅøð
W–üfáÂS:.Å)Âª„Ñ%;@gXÂ…íVPRx)6;–cêS>	Š[>Ð	Y€>­N–ñü<Nfõuôø":c/ñ™8:˜M$õÎÙƒ>"ìqgŽ€ÒÏ]ZÒ>_ÖµätIë<çBûyÅ÷:µEœÎuªSË@‘w Êª s"Hr¯Ù—öVbÎ WNK„DæqNç3Ü©Ä_fYîliU"#Ù”kaâÞ€<ê&Tâbñ4ð¯Îfuˆ®ÛD×(ß'á_Ä«oV5ñ%mëKÒ(G¬ŠIÕ¡8­úªNÍ_çî‘:û85±y{¤ƒFÅ§-(‰ÈI³çûZ2ïFÌ€ô/ñf:Uý¢Ä‰@Èõ ¤{ëêodþTŒNSAcYÜ"jœ’QÇþ]=§?3µ]é*[ÔM…¸¾GtÒûºÆ›3ÿû'ÐIõ1‚šâDâ ¯?“ªDZËZÞYQßcuºgÐHõñ½gÜï©Ü×ªÓ6¼åÞ6÷{‹Oµ=(!>7TQ\¨%‡™g_ÈŸù:|U›1×‚Í£àãGËþqÓ•¢eS/G€§¹»j€á}H‡¬qÖìa9¹*-Ú£Z]C	¢U¶'æ\-VÐ XÚùi™»Êk^€ÜyŠ—²Š×IÄ– BXd‡ë›ÉºjÆ#\º6™Í~fÝ|ÀRWÎ©EfqÉæ ;f>DêûÁt:Þn4.//ëçÉ¬žNÎ:Ý£ñÔÂÔ=<tã–6Á""Ì;ÉÿÍWSÍ{ôóMÒ«Fá]!á3W`n® »v¨dY]gKUs9}ÙJˆø˜LÙ£t+MŠNcaØ)Õmäb§nÁ^,\#GV¿—~ŸÝz'èK3N[ÏO÷ßœ¶÷p-™'´¦²œjzúWºñýò~Ý‚Ëïg+:ˆ—GCì‡“Þö&¼›Í¡hãIxâv×½ïž¥ÁÕÝ.TæB=>ƒy[èOßVïžtöÂÎñw*uØ'EÄ¶-ÏÔ]#Z¬d¡íÚ'"Ý_¾Ù³ÕåÐŒ|ª
ÐE'ýP1y“2dÊ5ÅTKê5‚}^aFƒø«í-úF¿h²B9]hßãàëÖ(ê…¸˜&«ãUlß”uÇ
+æÎ&¦îo¾ÙÙ¹V’54| VµÙÜxó6lÒàÆMÊžÃœÆ¸|8ÓÍ-LÂ]®6¶÷Rë2ç¬„Ã—CL›¤ÇŒäZ¯+9lÇeé\'îQB³gÊ,â‘ #›ÏqÛ%T47¤Ü™#Àµ?‹÷Ñ¥ÎE¸”ô¼º[ç­ Bö1l2Ï»‡YBQØ+‰Ö`I:qƒÙÃtShJ—b<ˆA•NÇƒ«Æåàªh®ÏÇÃú`:ÂêüÓßã§—vÇíÖîëv}ÔûJ}¬®®nml(ü÷áÖ&ý»ºÆßá³±¶¹µ®šëk›kÍ­Õµ‡[jµ¹¾ºÙü'µú•Æã}f(R`(Y-lÍúý¿ód”ù÷ïäsO¾ÙÅ‹ß¢à/{î¡
†LD{¹ÕéÛÝüÞN.þÏÿóÿ·”K9ÉJ7\’Ren[ ó£7”£&QrƒšÀqd¤‡ °‡|G_'ÔALËt>ÛåF´
àF­¡-ƒÕ&N,ûð¨S†uí'œvr¸·ë†Œ°	'1a2†GÀÀ‰§3:e»áJ×‹8"Cg†><Â´1¨¹z’e2ÛéÑx^0´xL3”è(†[?ø†ÞéMJUB·¦ð-Ìw5=<³ÞròºªŽ[;Ujôr†ee¨zrçl:ë÷m¼-NL)PïH%FÒêFÎ$@=ÐDó@RÍ%ýæ—™$c>xÎz0¨z6xð@ÐRÕ·y'ýø|&…¨äÂI6¬fIwÀnˆkÀÔIÚq]‚Ä&7téŠ-’q‰ã‹95ö%òRèX‰q‘YÈç÷¹z]žŠptÊÍá‹V]`}®^€Ÿ“XòªìÇÉìƒzûúÿüßÿ/Œ
Ç¸›vßs•¹ˆ“QŽÃlÜ‰ðÆ”£›òºÑÓTŸ?ƒ@»jœL'Ñ´; þ]ÅÏï¥îm4‡`•îÝe:ç–Ëæm€zt
öØä´ÁF]–Ì¢Náj":Îä'\Ö:Ö ÂÃ‘¥¿²Ê` ë(õöúEýðzÁ@ÿú×¿âðƒ”ð÷¯ nû¿êGø÷¬ÛË¢ŸUc¶Úlð•¢bgª6ÖV›kÍf­¹~ÖÜØ^{´½ùHalàøtofÇDÉ«Ë§U«õ¦Þ˜mïàÅ¡Ú¦DL­åSe#fvœÖ=Âº«_~“ñuÒÅüX\üÿí¨ïaÛî·Ïž·NÚÏ~Vá)x#6oìÀŒvÌ«?ÖFæ·W‡¯çÏáù›]ø¾ó—7GòxaG7Œ¢6(õÐÑ‡æ¬–Iï¡Ö|­Üîb>8¹WïÃè~7AËáÔ…æ<W»šÓÔÕkqÄtÂÉ9U¼¨³I· «›>–‘	×ýÆ‹ }›ošKªW.7œ‹æLd¹õCŒî-é_Wê7uÑã.0PÖ…Ê»°È\|ÙI8á	¬À/À¡­ú„& etÉØÁ„p¹ž*ä¼ã3ÎëœRÝËqáì&D´ ïä0ŽÜÔ™ÉdÔ4z#èÊG:â«A?¬Tnê±d_ÞÐc'ì¾Ÿ³²>ù§›;¹SŸ{,ì”øÝ³YÒ­ùñÆ]^Æn˜­ûr¢kŒâ^oáªßØ÷×ÀôçsÐýôœää¶jLGã‚Œ¦ç($ƒÀ+œ))zNéVÐ»x¤ ê0Ñã÷<áã/.ÿ¬Ã{µÎƒÂ˜¸æ½äŒ°6ç šYÜ°Žo÷Êß~€’ûZÖêç¦Êxøâ¦|Bã&\Òhûœ @ö{W˜ªh‡WKõ;P”êªL›ˆ’ómÈj´?õ‚G¢ÖK5Œ”"9ÈŒzûQmu­ÖÜ:k®nonl¯n~š>Ò¬¯ÖWµFr'½‚þ2÷å]<]H7ÆÓ¸‡³([øÆ›L§EÙ(ÓìasTÊÕ6BrEµù<Íã`1-!ÝÏ§Ø?|9D³ÛtÑ»íÓ³ÃãºoP·Ô|#°y¹é]#Æ‹ïÞøž'&œ>Û¿‚•§þ¨IFÞbýÇöÞf|
::>Ü}³s:ÿºbÿ-@¡ÜZ´”ªÑ]6×êkõf}½¾zÀ/^¿s€ßà?·Þ¶rãeÀÙ¤ñØ„_zï›õGõÕ³æÖÚBH';Ç{G§g/þí HyóyèB"×9 Àj[;vák;l·-˜b>ÃìpŒ§Ÿ²Ç¬Ñqo·»Ëßºi+–½UäŸÑñÍ»©ü½[ì£òoÇ nœïmvßs#(@œ/,Ú «·y¨svè”"ýUÏ0óþv/¢Wû“·õ×OQ?Ûm¿h½Ù?=s!åžÞ°ý
yÒ‰
T)¢SN> 77è?¨ôðÝ(¸%õ“èúJÝ'LÎvæŒéF€qI.Se¬µÎÿ1¡„ è¾AÿáwÏº ÄÑ¼œ‡ùïg|-÷VGÿ™CP0Œ; ve#Àò€CŠýsØ‹ûîw‘ýÚSï¹Oê¨6žý!6]@éù$Åt¿y—(¹ä	ÿsŒìäu}|5L¨8ÿ!Žør˜ÁÓlT—Úµ¹ß5ƒdãÜ/@ ÈVÁxèæÖ»µ,!ÛŒã3¬%QÇ)ñ8b%Ö/Qaê[ïÈýâßõ5 Ýt¹@æ+IE[Ônª\obß±B´Œ¬låsAR²œêçAs”ÝOxÄQLPì©Âo|òÍõè›¥!:U‹Ú|Šô•¨öxYBpOí¢î{‹ÊÄÎÜÐ9FàT•¥ºÙu´ˆJEýü„Ž­JQ‹Z¡ærÝ¨ë¶n+¥êe-à—h(I2QwªJûøøðD¹Ñ1ÒAc*}³ð?˜I-¼+‡èŒƒý=­Ô•3…ÆÒGÍ¤ðÙþáNkŸ~9;ha'7­`‚}xèºïƒÏ‡ºXüš¹óõ'Bf¥x¯ÒQ¤7šùm!\)ãÁUo©v¯)4Sîã,BÂtN€Tj³÷ãTâÎ¦ÑXÊ~ÆVô£4—ò÷@CÕõŸ¬¸>¨«?c[Y>ˆæÅàfäÄˆðï§©=0îUaLs¤Ê×Añ¥Û$Pv,Ü)’k/Ú2´[ô¶ù¬­ó©›g™Š$ª§gir^¹a—Üô:“Î½{xC£ã2B\·&ÝA<(¦Ï¯Œ_ãi¡³£áö˜;Ö3pTì¹Ç˜‰¨Î2¾4n*@ÅÇåzÑ0ñ<wçE,7·g¦J…¾ˆ]<Ü‘öpSf\‰¬
ërîU=gmjØˆ7ÁÍ’r·8“·&3¾cÎTqaá9:¬GÈÎ¼:èæÍÇkGi›N!ðºïò3!º7s]ˆ˜©î\Û):gË±ãZU{p«Šõ]º/NÌa’·¡ 7ì=C=ê)4§{fO±—.áŠÂÂòÔƒàW¡rŸ_ÕnÄ¬ÛâhX+~Ô¯ù'ØÐ²o¢NA4!|1h˜t"bÅâ’cÜn¡0'‰zêÍØ¾B0`ëý5õýÌ®¬Ó„ÄìÊÍ\žF*›IÝÛÞšJ…¦	ßAšQœGoàýÝÖ=®JH†ÿ>9ÙW¦Þ×$²i'dþÈ€x žJY‚U)[aª«'Êœ=²™a^‹òè²ãÔ	gõfr÷„u†êœä´úú¯ÐÏ7¡RÊ\,‹’þ{uµŸÚÒq…i@û%ã„D©¦ÓñU^~bí`bF’žšÇ`µcÕ[\²=tŠÇÝÌÑŸžGq9»²°†ôÓ]M€•wL_°lÎ ý™µñüÀäÃc/1t4ÜÑp¬–+¶r76§˜zG4xNí§x³ -ï¡ÐH›ƒ&Ab)¶
sËÃ.]µºõ3s«Ï€¤ûùX†‹ ×`[·8N±K†ù+…]ÇßHõe€™~Y_µòÀpÍêÍdEii¬=õô¥—¤hj\W¯ñD'gøÔo‚Çö™ë¾ SVÒ‘^£tÉUwVª—ôDÂ©}ðV½ÕÂ8Ç¨[DCæëQ8]õQ.Öæ6,w¥BO-húi¸!tí‘«j©ÛK;fÎüš¹•Îº$‚L…LøÄæ®ËbR&i„î×/éÚžcQ­žrÅÐ
CƒävQ7Ã+„Šæa¦Y]<È…ÃCÕM³S­IZå)±UÏµäê»(²|TTtJÐŸÁV#}†ôn§Þ`Ì:±î´T%=Ç*§FÝË§žÐ ´.sñ‘«—Ú`–,y¢¸¡YïkN8—/|Q;³Ü_¢2wZºÏÿÐê@1Þh¸ó´ðÎ‰d`:©N‰òg]å·säîôˆã?kÇW¨ƒ€í/ëÆ[h)Lô)p3)8ÚWV·ã¶àâWÄb•ÐDètÒAæ×]¥yã¥Nu:EúvÀwîp;õ–wŠmü®æÊ×ƒº‚íqcWú¦¨²ù}V§BºeïìÓ®ð¹J©q¼¿»÷‚ˆÑf1&Ó&¾:ðùÃs"·žÛÜAèP!†0° œ/Ü©“òTÆ…`öû&aûÂÆÛŒôAÍ§Ù„Öêë<„Òqé¼Ë¢Æ¹wþ¿3SÕ)T†ïyI4Ý¸C]‰R’SVÙ‰â™þž¨Í¥Ü°®ì3(¥…E¢VrÅøšz²Oi»‡¯[{%8^¸ÛøòØ;ÁüÏ¯ZÖ_oñÑ:!¹ª¦žZ›OÔÐ‹$`(>0	ø%$ÐðÆ©™Îžîç•çÔ qì•:š'T¼ŸÊ†Û€'CúUû‡æçJæ;/ãÜùðæÎ“;ªø~z»žÉhyk£éw"<¾'·„'X[käQeV*YA¶A¹]À#¸=ÿÓtv1¹Ñ„¶º¯>1T`óÀÙþÞÉ©`?fãÊOv†ïÁ˜'70¾|ÚzÎ€ŽÞíž½ØÛ/ÓiŽô¥àÆTÕÔ³@—>j=ãºá¯øø²WŸ~ gÛH?æþO}sÿ^Oäúr&!ž7šÄéY‹YŸÚÍàŽÛG7+ï‰»(:òn j|}‹€É*–aNÚº1èüJIÙW-6Ýq§x–rîo¿SXœ‰¯É¤ã8Guô¶áÖ¾9[P%¾îAÖŸÒrNúˆ?
ãú=~%'vqL½lŽ
©è7Fº½ffSt^U=EÙf7ƒ”ãÀºtÆI0ÚÝäÊï%ßËÏ§ä¨ÎŠxÔÈIˆUJ<Ús
m³Ó­`@Fa†eú¥V•Aq…'+#Áàðr{0~2õ½æÏücÝRüÝpHòýQÕºÒ.©î§cØå4ËPDáo´ð=„B¥ k}]­Úçt/"´Ô!@£[&,rl`Î!Å¿Ý¦œuÄê0Ð\ÀøÛí@»dèúý‚A¿·1;º!<jøXÚíA-“ÏMàgs0‚àg–Â± çò±¼â¼ <÷ŒDˆq:"þ–Ž£Dô	‡éÎå ¿š½e weHÎ©_}ÎAêna+áo¯ÒáÐ/f	ö¢0œ|)t÷¿ÿ—eà7°ëÛ2éBÔ®È¤µœµ²ðý~ûàåé«g2}úí²½4H™ÆX8$9g6l³i®Òu#aˆ wU"îi§V¦k€ê(ü;ål*°)ô‘£ÂÀà.†Qr>Ø»¤C)¸©o^2UG--âúÿõ¯õ&ûÈ¥)ê‘íÎ‚fôLÏØ£xFQKgþ÷ÿ:OúÏ—‘®îífm¸ÙÚÄ[]z®›8ŽX$¿ó±!Œrø(“NAiS€¬>XŽghù´H‰e5ÿäµbQ*Ùñ½Úz.`¼9z€/<Ø=|wð€\»¿¤qrëT¶áì¸J`â‹TÙžê ø®-H)”Tq`þÒ›YŠýpð©o®[˜H.ÒÖ×q%Á3…t‡«¤ÆIYüQàGÊ„ì™¦è˜n%\PHKÑ†6LÆoÙ¨YìÙ\Ä$±6YDîEÝ ßÙžÄ¶…õi ”¸¤2.ŠFó<‚J³<šóäc¨F@ 14ÅR$—7!ñõi·®»/õˆ ,Á³Í^÷³qƒÊ$XzÎòM¦Š¡d!§	 cLßïî7ŸÑ?kš%.$PMô €“FÞ|
€xKFJƒ;+IMp;yÃÉr8ll¶\”a+Æ¸+Û«uÕâ$´#B%2;É‘3¨v’,0#­
µ—exÂJ’:I†RÆ^gvŽzBÃpâ A­áYˆ(Ã§ô/×Ö·›™ªº•\ã¢~|	ÿÎ:÷1,Ž·|ab9Œ[Æ28Ùv£$Y?§F°£FRAÎ6¨@SÞÊ+ÛAð@ýØÖyùüØBq ¤Ñ`b[ipÓ|=›u°bÖ\¤§Ÿð~^Z!Äéi€OÒßcçòC[(¯5ÝÝ©^§Oß­ÕWëæ¾˜´C9Z~U6SBoêÕV	 _¹io§}pÒ®P,âô{—|ñ>˜´_µêkõ±¸þÏêêFsMêÿln¬®nbýŸµõoõ~‹O`ÜãˆyÌ†VÕ-öÜJp;'Dù'ŸÁj»Íþ¥œß±LÅcå²s'pœ/„3œß{%~ŸíÁx=„_£öÿæ<ÌÕÿz¸õðÛþÿ->;›û›ëzkÑæêVçÑZÔínl5WÃÇ½‡7=\;kÃpUý©Þ(žÛŠ6›aô¸×}õú«ë½¨ßû{›{M v6·:›«ÝÇ¡û¶=kÖÜÜÚêG[~Í=ŽnDý‡ëQôhm½Ù|m5­ol­=vß¶çÒ6ÖÂn³Ùì¯n¬o4÷·÷¯õ6£‡kMøæÆ£N§¹Þu·å|ÄÖæÚú£°ûh³>^ßìt£îæêzgµÛ}ÜÜ\ïöV­w›ýÇ«øfé£~³³ºÖéö×º«kú;šázØÜZï¯Bw6:†€„G> ~wkcõq¯ópuëàlum­×[[_ëlv×6“[kW»ëa1×¹s2îñ£ÕG[×:Ðu³ßoÂô{¶¯÷úÑZ¦°ÚE<E·úx=\ôè1 <ê<„q77ºÍÍæf=W7{Í­þã­ÍG}çµü‰»GˆñµðÑ&v³¹¾õ(|¸
Óxè{üøñF´ÞÜx¼¶¹ñAÜtž¬»µÙ\ë<êG5£Îãp}«ù¸û0\_×¢õ^¯´ØïÃâø°ÊÄ}ÊŠŽÂùk»ºÞïvW¡ãµno}c}3j6;ÂÕàHÕG£°¹Úëw®A¹'ñ¢­ÿ¿½oÝnGÜ¿«sü%3NzL‰¤n¶zÔß(¶“öÄ±ýYvÒ—äèP$$3–HIÙ±§³O³±ÿ¾Û* $AŠ²|‘ä8MÌLÆ…[¨*T*›Ð‰š©š›¦jA	«Q­j0_u˜­ÞP)''Î¬ñ¶Ô`iQæEÛ¬[[[æºÖ«ÁÐ×65­¾UÛÒÔª¥[X$ß¿»P\öàÜ“ö¦Ý•
§¤é±^×˜i«R«V{FÏªÂÒR¢zUí×ú°»˜0`F-Ù´$s¿WÕõ­~uËìéVkzKÛÒU•6¶*õF_Õ¬ÔÜK®›ú¦®Ö**ìf¶Í^¿Û*ü[Uk›ËÀÝþÛH­¤ß)l\•z]íW½†fmö4ØÐ€C®ÖêŠÚkÐ­^_335éiÏÒJÃ2ë°&­žiT{›–‹c«¢Õu¨WÛªÐºU¯Ñ^º+ÌUÕºÂ‡5¢³‚^©S£=ÚR7{´olUû= sUµ4 t½Þ¯×T‹Rš²¢ô\7è¢ûß`ï }}S«ÁÑSk½ªY7u‹nÁP7ª–'ÒVF «Ê6”®÷ZZ1kFÝ¨šµ¾V‡Ñª5z°
5Ï½Q©Õ`v¦ÙïgãÔ»Q´šDÿaØÌ-ªÂÎ·µYÕz^­W‡ÇªBÃ7aˆi¥¢Q-Ml7be# '_C3ªz¥¡WM«^í÷01}«¦õ(rLQëÍšªJ—«Íºh~Øuû}Ô<as-£‚+Öð„í©0X@Š´¿U««°\U£omªuë.hY{iµR×+ØZ„-dÙ€àaãí×`»íÁê7¶4ÃªN­†X«t¥ë.ðõ]¼¼¨`‹kŒ ¡«fš<‰Ñ×«[pÌ6††1T£R©nÕoM`ŒK †¢Ò·Œü[QaãÛTuÎ©š	ì‰e5¨UJÎ…´#7…h•nÁÞi©ÕšÕPaŒÐ½iõ*VmS·6=+»çzfÏu6W››5ƒöªVoËÜª™Ö¦ÕëC;7+[¦Y©5ª[µ
p5µì¥¥©]OÆX¾
;²Þ§=ºŠª•Màï[[îÚ°ãnn¦w’Æ“í¹p8š5­OÕM]ƒ½Ñ¬mÖ‘þ©aÂébÂÑ¤º©Öî²8oQ×«=Ó2(©Ai_UMKÓ,ØÍ¾ã^ßl [ª²c
¥¡U)TûÀ2=ØgUbª5ª×k}à9U­·…ƒ$e-,‡(€Fkj£‚Ç¨	K¡ZÑa·ÀšÙW8òë}<Â’¡žä{ñ,\v(÷Õj³õ?(/¡ü§UÀX6@þƒ-»ò¿HmÙÃô'—ÿ²xàE×1Gþ¯ÖôPþG×aþ‘rùéÙ_˜p|ÎÜÑ£Iãê´gäùžÕ$ÏŽ6
SÞÆçõÂ—ÖwøSMì
äo¤#®9^¼Úé¼„2ƒ0V±x†ïS¢om`9uòN§ çMƒÒ¹´ƒkêaèñ…7K<5§Ü2á{›½D"¾wà®rÈ´­ä…Ký—ê òJ\ûÏ@Œje¡ô®eQéçû†ls½é«+>;(”2 ðaïÖ"ã	?p°£‰‡oKrLÌkGxÜÊvrØaNý°FÉI˜yã]Ý€±7_¶¬0ó`Áé±ìé` ã|åt!ºâmxs´¯TJêß>µïð&›ZX* øª[À_îÅN@ßcgüÂ<–f<ÂõÝ~™ßJúo¬FZK…œ¹/¶W2	ßˆEpã=öi¤_%µ¹×Udž¹%À°‰ çâm¼ø²‡	<ÊïÓ-bT\ò^Ä6Ì}þò>tè"_8!h—x'álHtÂM;ƒD¼mYÒ¥½T3{Ï…ácÏonw·¿ßÝ>íœ¾Ûû­Í_¼|Æ¡ŽÂÇá’^ª‰1a€ÓA/ELvW,ü	^ 	Ÿ³tØ;†sÊãPÂ‰6ƒ7!”!Kú
dˆ(i“Î#·†\*†«aK˜”š–0¯Ìlß´³€ÔaÙïCÂ*<æãñ¤Y‘Ü8î€09ˆRÌbµÿñ^¨±,Ã7íÓ#áCfãÁ@§C›Ê7¾c©:“±0P"â›ŽP*ãCÎÓL9MÜˆ#)>cˆw\¶GKVÃ¹
Øsá=¾ª”Ü[Ä«ï¥…ï¦ÿÈ\ä?=%ù0¥r^J7óÿšVÕÔ˜ÿ¯6Øý_UÏùÿU¤eñÿK“ ž¨0K
xÚ@2¤ÖkV0ŒúÅÌ™ÿá¬°€/‘B¸=éøž–$‡†Ï‰¶Úý¥Ãµ„OŠð)"Ó\vw€ý–EÆ^…w¯ç•_ø ¿o·Þc|¤…7œ›£ŽÖZÿ8ùçÇ³æÇË2ù‡ÖÙÎ¯ŸÈziZg-ø³T_ã/F+YŽû$I ½–³/ÎŠlæ˜ðõ65Ù½tU)”¶™àaùb/U	ö,VÎF†^§1¤Û‹›œj‘‘þ$ÂQ à:Z’	m˜è!;dC£l6ˆ{³›Õ‹1#ÄöáÁëÛŸ‰7·ë²$GììGÓ	_…Œà—S$%#Øý…y°Í@ \µ§`°HÆÔ¢ï˜^cì É“Wàç|h^t*ËhÑ
7Å‡.­Ô¢å›ý—«ëÖ:ûSa‡ œJÎúRSx-Nyá¡ÐÊ~æSÀ¢Ád®¾_ ¹âñd,þÜNGqåGÂl ŠËuhAÄ¯LºU¶ÖM‹È+ûÇÿÿÌð'#¢˜$mfGôŸÊ½(;“áðºŽ)¤Ø$‡o‹àaVôËMòº½·¿»ó¼\ŽòžC.>Sýfw§\ü‘°È—%¢°ûäãò¢ØÌ¡(×V$_eìÙN þñÅð0ûjÔº±hÀë/ýé†þaÂªXÿE”¾.7£½³ÃñõIO™@;šD9×64Q~õ5æCpÝ'äjYÂ8hÁàš('@©?Š¸£"hzÒ4²Yå6£Àr|¼î"ùfI!ñà¯‹ÉÄý<žÁÔž.õfBñZcÐ³RÚÓã¯v&¢
Ø×3€Ò[™6^ÞŒ7¼šÅ bŠ2qãÒ(ÊP¸£OCAn
7øi(È•¡¦!¤¯n/9¬‰³|hDä=¬(¡[$aËA&Û(e/bE	<ØZÛÃ!ü	ý²vHÑtZqÈ”wÌáÒ+Šï¡O?ãw#ÿã¸ž­Èp6Vv
žî……‰Œ$ÂðXD¼Òg~þRgž¿ÿ|yswÂIs¹Ñ\ š”w]ômÌ?±#)ÊäÎˆø%vâ?®Ð)Ì–ZëCŸ&*ý 3Ý¡ëµŒIàF ­õ}Ñ´¿ß>Ùmm6†äÆÛF@ÙP½è{LYÑ™õqèñ&/ÊòyVV{ü¡ Ç‘ý9à¢3¯Ct5„q}ÞQ>±ëqDãÉ˜˜ŒãÌtN`À^:Úšzój,s§é¸8½[qæ-šº‰”c,þÝpÄþÔŠóÖzÂ™ù‘–,«|2zÜÆÀGhÃÈð®ÂfMŽ°?™f5`nˆl¡ò#ùó2³NøÛm­_Ø‰]P¥ÂFñØz¸ÇJÙf¾‹­cŽýGE«è±þ·‚öµJEÍõ¿«H¹þ÷qõ¿	ãúïR,»ìß N«‚åPY¹:8W/O|+õâã©ÏyÆƒLàü²Èˆ‡‰%Ø>,%…vB½ÌcŸlyºMŠ=³–WÇ\ÿ½’²ÿÖhÿóËOÏØ+=nÃ-ÔˆÆ_ÛC§"ï‚tñ½°‚ÑL0³"ev¢ÜªÈm3]W˜[¹Ç’~,üVÇ'¦#±™I–”½»A÷ðŸÎînÁ¦ðì®;)¸Ñ£ßM­²¹ÕÔê•z³
©¹¹?ïŸKÌv¬\lsÖ¿ÞÐª±ü§âú¯ÖµZ¾þW‘rûÿG±ÿO;2?UÉo†@¶ –{ <¶´¶`Ym5’ZaÁÂ×·#zñŽí¾^Òûìÿø|ö¢Ï”tº‡ÿg]ÕrÿÏU¤ØC{yuÜ}þ+ªVÏç)¥g)uÜcþÿ/Ÿÿå§dTœåÔqù¯5òý%i*ŒÑê¸ûüWõüü_Mš…j¡uÌÑÿh*ÌyrþkÕZ®ÿ]Iz–tŠF‰$ŒD=EëX¤½œ`÷ÉïxAô8Áx&ùô#‚;…ÿ]Š3}QúÜ\Ýdæêòu,"Å‘Ç‡±¡îgŒüBá¨}òsë9þÛ|Îžº*E†Ø"ƒÝÅ…~ ÇãÏ¨y{5ó÷a=ò!çí.J6ÞEÒ"ÅbÔzBÂž¿èŠžU—¡)eAÀ:ô)à–Ë»ÇÇ‡Çx7º´³6e–„ÁâãzN…1ìùÄÖ…·0S/"ßxüÝ/yÐsÿ¹tßyJðÿRÁÅÖq÷ó¿¦WÕüü_EšŠÐ¶„:îÃÿÕsþo%év±?VÇþ¯ªÖ#ûÏ†ZÕˆª«z%¿ÿ[IZ¨>{-ºõ[[¬¢|í>÷~k÷¸ø[B»W™«kía×ksïÿÖnq¸vËÀµô ó\OF„zÐÊá:Äïró‘ëµÔ}àÚÝoóÖf]ç-aÊä½µEßè-¼½¡x¢%QëÎQÀyaÙ÷6S_Î³\«Þ¸QåèÄ£¤‰ÇÎRÑ<ÌW³™²S$ÍLëÅ¨Àô›½X Ìá~>ìœ´ß%áb¼ßÔ¼ä~MÀ$Ÿ®a07—x†7‚ã©äÎÞñ»öAºVžC¡¼·3Ås¿²iLº©âšÃÿ)>EùüãÈ¨ŠbÂ^$þgåßÕ*Î²-†àAUè·.ý5áU”ç"„Ìtß†–1>b®Y|Ðå|_úÀF:üÈ¼/·]Çag2ç7 ÀhÐb'ì:ì"/|$¶C‡ýŽ=p¨µM½ 5 HÔˆ»ÃL4yø|1RB+
ñ]DÜ>qÝ¡?Êq•±çŽÆRÆ‘çŽ±:êã8†KtawÌk¹Šà»J·Ôÿ€:æðÿºÅÿmh ünÿ»¢”óÿ«åÿg¬®§-ü6ñ\m|K;†.XéOàË¦³¤ hOöwö^í1û?óŒX'DŠì'ˆ1éÃœNúÔ)­¥½Æ^Qþg^ŸœŽÃ°±Œ	àÎŸ:æO[ØpL’KêYQ.“,°½K ½¾ñJƒ1m˜óŠúæ,îÞ$Òv†°ÖBqc q4&I÷ê)§	¢L<ÔÌ—G¨I±I0È(À±8R€:˜"6`«|A@ã1å÷.Ðï’ÚÐWVÛ! ¨]Ùs,ú…àëå#—°µ3Jì»ØY@}³wâQ|á<Uj¡ãmÁB7V8Üð÷1.ìÿæf»k·÷Xçí!l®M 1zƒ#êù®“ú6ÎÊÜq*Çò³?`"b9
.ù„ëGDv5†a]I~h’ÿt:?·kšþõäèýåß;Û2Oÿ}ê7¶üþ‰fŸ?l]¾±~=h›ãóòÙùåÅo¯WVû—ŸwÏöÞŸïÿ=Ü½0ÞUoûÍõõåÛò‘íÔªõ÷güæUù·]ƒNìý÷kÓiJ4é'~‰Î„Ao)þ ¤F–a/·‘|”iš~ ŠÒ	‚g¤]÷<8óÜÉàLßvÐ$à7b ß¾¦É/û‚:/Æ¯ÖKl"OÙÐ
éÀ±‹ë¤´Ä¥-Î×~öÚO—r‚ëÉ€Á¿‚Í<ìC1"8ÿ
Ÿÿåì“p¦žè¶ñö—Ï{eíðÍ»ñ»¿¿ýðËÏôròöíÿúõ×_ƒëÆoNãóUg÷ìd´÷óð—ÿj¿ÿoÇ¿üü÷iìîo^¾9:ÿÒ8¾ÚzuPþmÜ.¿+w~®þ}üö`óßú±Ê·ILÏ~òçGnÆšŸ»]H›Âiaz+BÃà;ØÓl>«
°jÖ —¬‹lŒ¥G¡<¦ÞÍ0EFg¢+I¥æpFSpÉñþy6Æ©Wü+ÇœñÙÆc¨2B•Ù`ŸG_ÇìþÕìï³‡¿Þ0^(3(Üæ ÎçfŒŸ¼š9Pa`/m:EœÁÙÉl(®éb³fÌjŒ€ñÏ&å^fbö¡8…Šs´
n˜##}ÀE¤þðî;Q©ÝòIÅÕ1GÿS«èªtÿ«£þ§šëV“„ÿ'Zí-qË•A©v'•A™Kíi«‚°¼Í.ƒáØ¸ÄU°P …‘‹97{:PdßKä7q¬ˆgŸâg8mTË0F»ïøj‰ŒI?ºnfAa%¼ƒ>rÊSÀñ¦B³&xØ	mR~K½${·EÜ^=Øù”‘0›Dß—Lz¸®_è#R8w=žd@5ÂÙ¨<c’£š3X@|ÆÄ?gïK1Å`‰|°™ØÄD-ÅÃÔ&úŒÈ£\…”\TaÄôÕšQcDˆ1/±T°A|Œ ˜¤ép4þpÖµ†áR*-~RÂHq0ÝV±ìŽñ\Tq
/w[ÅTlw¬‰à"Ðô’^ÒJ@òrYéz–•ýßºfFŽODŸ ³yÑcP)$]¼×ÿ*µ3¼qÎŽìÏ<¤RÍÀH¸ŸWÂÝ·0¬HòCcŽ¤`;ýF!Ieïµ0$IÌÀºý, {Ý~èóo1BÑêÎáë“íãÝôôùn?À×­Ê1m”§Juñ*(þþZÆ·©2à^¿û ë.3 NÞï$ ‚«v=
i³ï€nœÐÊŽßAÁä ”šE&7h	k‹È:Fºüç¾¡h|»ûkçäðx÷Ž¤÷ùÜŸBq4Çl6†ÒXjýÁÞö[\­bøWÜ]ÄZ„¢>ýìúA\9šÈh-f)£¹:ÏÕ“¹ž[)ÊâP÷Ãi2·N¸kºåÝ’ çÙÿ6êõøþ¿Vç÷ÿõ\þ[EÊE¾ÕŠ|3V×Óú„$ÖÿŸÿÇ¯WÚþ>ó'–Å¿WF ÜùÛÄ³Ÿ(mØ™–ëÐ V_ä³ BÙÃˆ:O2á“˜Hý	YÀš½ñx}˜p×GÆÂðº"…Îú¢+P´$‘!“!§‡ì^l…Àì@ê¸¦C„fÃ"8ù\´\P{Ñ I’±mP 'I” ðõ%£ÇbL6Ï$FX‹Ä¯c¹µ>\µ÷f&>$ÇbŒM~q;Ÿ0Ï	û¡Ú‘yv„ðû´Ð^ åuHI¨07†‹g^†‹s¹•6‡m[–`•yÎ»ê(2#î™ŒËhÍï|ncM=Î°¤Ÿ¶˜¶àžzÔ"Óz[Ø.cóE’.0"9&IBKÜÖÏëf´¿ß­“i{ïvuÊ.û‚z=8.ÃŸÑƒ!‘}9œ&ˆ.4¨OÏüÒ.œnÉÿ?Èxÿ¯W*±ý¯ZAû_M¯ç÷?+I9ÿÿðÿOß˜ŸAdWØ>!ãŸ¶þ%ç2ßg[à‚Snü$ta»Zeð
1¾w“p¦d	‡\®¼Eš>ÿ+]¾ ºhÕ~hR Îõÿ¯i’þOÅó_Óªùù¿Š”Ÿÿ«>ÿ³W×S?þ% †ªâý"CÃ ñeÖ•}ü,ppÇA‚u˜°dL‰‡7ø!úÐ¾1uìà¸ãŸ˜$g&J¤íÀñ3De`ã\†TÅ%œ¦ÐÎ7S¤A®¢[d{sÝjUt‡b…à.Ã‡½Ï_MYžºî¶ª®ùÁ8\¶[<O„ûˆbù1F”hLøþ0…¼‹D¡ÌáÄ¢¯<hSÕ„-u9ÌL}o‡Yô3ï‡(ÝuFYê®î<ì2`}þ~l”ó´¼t[þÿ!
À9üÿtü7]«jùýÿJÒÔük•®ôÜw×°¬.*Î+ çÙÿë8þ›¦3ù¯RËå¿•¤üÑ§=útÃºz˜è7Wò»…àwK¹o†ØÇC¿qÍ/—öØÛ~ç\º@û|ôË¥ür\‹¦¤À»K\³®…ÏåS{ãia¢Ö­%-ñ˜‘ƒ¶È‰ÇØM›ã•–Ð,æ®òË-­nil iS¶,7ª’	S‰[uƒÍÂ­MdÀãÝ£i\˜ÝlØp+!®  èô¤á’ˆ£¨õ=wDžóÁ
\þWŠÏ¹â—Š:>ø]¿¢ã×ûðSŸðb_’æ*f\éké;}@ÍçŠ·O Ö3Që7¢Ö3PK9’ZŒ…aâÌ‰G¥Õ¤e•Ño.£³2"†]<ø"üÝ)HªÅçÜ¢·ˆeß`ä Ù/È¦ÓÑçB:oþÙ×7Ñ®h>¾UïB
R5!9tx üM„yÒì…à;ÔlGl/òd'>¤
Nl4†É¡?°XðÖC{‡S ˜øD9*§È7£Á‹nñB5¹Bb!éVñÿ–ëÿÝÐ’ý¥–û¯0å÷ÿï{»üKF÷â`Sw´ñŸ*ñ¾þè–jßŸß.°½ùýá÷‡aÀibH¾¥ü5«k`K‡×=jw:w¾†oY­x°ñ¸Ù(ðûåÖ,ý‘X.ÏÃä·ž¿ î’”-zQžx¸ÎFä $Še’b[ùÍP®Ue«™}whå’h*ü8£0‡ŠC´—12lëïÐÒg>H%J6ÉßþóãI«E~ø}ú!™ÈÓYPd‘O‰î…IHÀ¼k°OÀŽJÞ±%Ž/™hÉ³Òú‰ ¾dÑìçq¾òun‹ãÆ÷¾¦ñoÀê
ÃƒÛÎ –žTWßæ[®#*àˆ¸vŠ2.üëyö“S‡-É0£Ã‚0Á.&ÑC¼Ü¦ðð8J!µæ Öþ“„¿Í
4#Š<íì%3Šµ“Ø±˜_\ì°Ä3	Äœ^%ù¬`äqcÎâªú,p=¯—÷OiÅÝmâ1,É°½WâÇ0OOÎêÛuoZŽÿÒ‚]{`ÞñŽ<wñqÊý˜˜r£”‡§)ý’€;ïJã«EÔ1GÿS©4ª±þG«Uk¨Õüþ%iQrZZA³çô=Ã‡ýÁðôåt,Æá€€ë?æõ|Z'“¢øÅÞÆ'J§µ0:PzIÓKj5¥{™¡bvÃŒžÆê¼#;îÈ°ü}¡—ènþF\_z‘YÖ5\„·
ÿ.;—YjA©’€-hðb}çð]8mdÎÖ7HFÜuy¹âËÁOË› w€ÊU+ób~ù¯Àÿ•H­xY`2A—u Äh;Á‹4V!í Ç€Hªª_†…}–¿©0pARy=.Ï8ãYÝ‰,xI{0Å¶YŒŽöÂ²Å¤LV,
c´Î	Ÿ-cÁMþþWÿÓzj0~L…Ã<ŽƒsÉç(Ã<Ý44ò„¼DZg\à4ŸLô8~1t¤W˜#Ð@ªbkø°ß	7žÃö
žó‚÷wßƒÑPKã°‘PnðÎS<&¼X<7•BJ‘	21.7Ä‘:W<>óJÅ£Öš§Ý/°³À(<öÙû-¤iûO=ÓNM_•ýgEËí?W˜rûÏUÙÎ^W¹ýgÎº.°±¹ýçÓ±ÿÔ3aô?³ý§þ-Ú²­Z´/·ÿ\ªý§þ-Ù†“ÛæöŸßeš–ÿÔ.ßRevu©ñŸkZCzÿYçï?Wj¹ü·Š”Ë«’ÿf¬«ïBø³1´
>Wè°P-áA>ÛJ„¼Ó¹Ð÷
}Þƒ…¾\Ø{ºÂ^Æ¤áRxA¾Œ½&ðE#ð ‰/ÄÉ|	[˜„ØÂÜIðíŒE¿ìô95¤å¿`<Owo.•å°5	Öÿ?œ÷ÿúÈ‚ qäý{Ê
"€œI´1Î˜´´ä–Ýâáø6¤·™™Ùî\„ËÓMéVþhŠø€:æÊÒû¯šÚ`ò_½‘Ë«H¹ÿß£ûÿáêzÚ€ÜYŽ¿§…ýN<ó»¾¢ÎG£tNyÞEVÏ)SâißÁÄ«™‰ªà7ãMì‘hÈq4|œ³„QÁ3"…3o>ÙÉ?kô˜CFääçdxùÍèÂYÂV;­p…c:óA4¥N¢T>CÉP`Q~Aç©)èš2º=c¨˜ò`àY>Î@	üa€ï†T	­4¡¬ÛûÍ1q”=3.l×k¦IÇAîÎ¸Àö.a öÀ=Œ¼x”òÐ´o™Úø4-zÛbX\\†ò5<Áø”
óÏ¨ŸVžôFPC„ïã2/[øŒÁô7ÈhBÙjÁÅþŠâk¸ÐŒ›CÚÛûë>¬8×gWá½FªGêjª<w¨ÀÄYCêEtü¯EÄÒ0L»Y|çý€¢@ëcQ+é¥ÍªZÒ´J­V/i¥jiS­},2ÿŠÔcôtû#1L+Š;@”™ý±sÈ*w¹9>nDÔBx+?DÑÆ½|g€Åðã	`9Ð
ôoÕT†M!D¶³ø¡;>þÍW6 yY\"	a‹rzŠ~!Da›OE¹GÎŸ7Ýòý§I€sã¿TbûOµÊâê5—ÿV‘rùïxÿééK€É^o”/l#—ór9ïž«ééÉyï{H~úà’:\›OÌçìçMâ(Ã ¢9tMcˆ$Çkh;cNÏÈ™²©e×ðí vˆÞ$ ï©ƒvm³‡ÙîRçÝÛ2vA&¸"†hÒ*³ch[Š!Zõ^9ñ%»žDŸw¸×=‰â»±VðÊÃ°
oZ¢^‘ÅýóSX,¥(7’1Þ€‚*°<`·±"ô~ƒäðÆ2r""*N×B„ôp½TÃ¢üDÛâ\Þ¼cŽ-jÝ›ð{Ô@”R"¤@Úža Æ@]MLMÛ6•î_ûóeÑ4†ã3£YÝp&# ³YÙKêÓßDïôÐôØñ3`âK.,†ú¿5á–žŸÌ©9BŽ1äBæMacÄ„ÃÓÜ§Î 8S^aü¤Qáä}‘Y>"ÃæDö'“@E¬‡¸¸ñÀÞ®°Wîh³ØA‹‹t~n+Z¢‘°~ÏÝI Xb-4U?ësvà`ÝLœ Y™¦Cl™"Ï8nfŒeØ¬¡¸[Úl4uàQo¬“~Ûb¡ÚPg³ž*“ªYñè¿'pÎ =ñàøˆG†7éîëh6IÔ<ÉùÞuÂÊ›9EÝ‹¢–O,|þ£¤ö@lòÉÍÝÆÓxôþÎò±l2
ážcÙ×ô|DÂŽPÅêAƒ-úEpNŠB‡E	N%òû=Ïâc
àöt%ô &<¸šõÈÛG.jÖwÒƒ£ÎØ ³ù1a›Q&/ÁZô´Fú‰wp:OX7ÈÎ+DÇ$Ù;MDf÷8ºÌ}‹NñØë°Ç¹æëÒ«jþþçÿ†š¿£Òläš¤'˜býðÉž €h!c¿À:æèt”ÇCýO­Ö *ûÿ\ÿ³Š´PgiàOÔ|Ú
Ö“5øÞ7’äxtÒðyÁÝØ>8­Ëa£‘›z/ ¹å‰ª–ñ¸ì²H’evÜãŽÃÖÅ'ãüœl¬•[ rDøxf
™ŸýÙ>*
Üsö‹“H«ÆkOÒª©êyák~ž“I¾ÿí`ÑG?Kóâ¿Õ¤ó_kèpþWùûß«IùùŸŸÿ·<ÿ·aƒøìöÈëü¼_ñy¿x|—”žQ—6Î/·ÏÜ.¼‰ƒ‰ðnrñQ‰¶E~€ÿ Ëg7H6û®CãŸ% ¯O÷÷‰2Â•ôO€ª)™gä§ŸH9epwý§¿i…%ŸeØ0z¶czLŸb<Þ ªúFe£ºQÛ¨ßk8÷¶wßíœ´¿•Qå\é
GR×ÙHþpÛñl3Žß]ì±OúìóMýrèwYˆÊ’Ïµ.¤Žyü_½Úˆø¿Š®aü_øOÎÿ­"-l9¥´o8 0¶™…³fM2Eö7òhIöŒIqhÓA~Õ­’Ú(‘4ç¥•Ô4—uê ³«T0Ì¯†ù=õaC¼þ4cdÃÐ!–õ"Ù‰?vo§`|ü× áÎ7ÆuZDÔÀ›˜|Í"mêiaýB^° ¤/K¤m}†Èî"6ÈÀsá…©Nb±",,Pnö‘càÄJ…g	hfŠ'>¼ÂŸÊi&¾ûË%æxzÒaÛ÷½òÐî•E7Åÿ—SGg†Ÿ—Ì¨ {v’4–*ŸÁaï-j˜PTpûZ,Q|^5Øí+ÎÄÞˆÜg…æ£vÇwÇìfÌCœKnláwÜM>v(_PiÃ³]eO°T…†ø-‡—®w^â–í…v? ^:“~û÷§ÂÉÕ˜¶|öZÀ;tôZ(¼ÁÌþú Å`}F@+ÍSáŠïŽ=í‰ü(¢5¶L„Ç.ì~¡&#×»—-3Šý@{û£¬pdîø¸zŸ;–ÑØ#
œ]‡š­Šª ™ŽexÖá$O‚Ð7LúßM×ñ]žðë®ç¹^ú#Œ©Ø±>±™@1¾5š›]Æ‹¡_ÚùŸäÿ`æ¨sÑ5Rêô+¥9ü_µ¦ÇñŸªU|ÿ¡ÞÈãÿ®&=û£ïsˆh‘{O
JntZ	˜XeOV#ˆ
@a³”xª0Íy2¦’}!:@Ì‡MÍŸçžgâE‚þp(È>VñŠŸî9?°€Æ*{lÂÆçŽìë{‡kbØ^Á¢»$Wî˜½+Âl†ÝŸÈ@mÚ%¨XÀ"kôl ÃæŸ¹“¡ÅOìQâPtw3¼+(¬û0¢0Í#ô°0vV†ÜfXWB.`èø:CE”`¤I	ã{¤Å¯óäŒ&‰N<¯)È¨+¾ÁôÁ?hak\öU(ÕŒÆs6)0„…vÙßïnŸvNßíýÖ>Ù;< Y…C¹¾oË8|F‰1a€‡ÇííýÝ.¨	¥!þ"	Ö#D/lg,$m„KÒÇQJ±;çéŽŒ0‰ú}#B©A²öI{
"Š%7ì´±©ò6’f~„-
ŠÃÚ(5-Šl6³}acÊ	}¡èðöÛÓ£°ßV¡¹“Ê³Â"Mà<„ÉA,lËÒKÃ£2ê×ï>„èï…Ë2|ÿj¿oËMàûÄLÎ`Å2ÐýÃ7)º@sSÃÞ^P¶mÍªSTl6ÀO¶oÀ‡ü¦84n‡
0ÁP!;.Û#øf	ól(pvôØfÄ\Mì-> Ç“má»é?2ùOß¨ª73%ù±Ù•<¼À:æðÿªVáü¿V¶_ãöõœÿ_Iú}÷àÍÞÁî§Â1õÇ°S~½ûž{¬·´’ÊÿSøýÍîÁîñÞö§Bgwûôxïä×îéì‹»îû½v÷Ý¯|ãéœ¡÷[«oýÅÜäi™)Kþ_ èÏÒ<ÿïzC‹ïª:[ÿÕz¾þW‘–%ÿç¦@ÍÎÐ<mÀvÂ˜À·	ÓÚ†Ïî32_OD‘ rªfBÍéN¤›ö35	BBƒ¿P?;¼ÂÛ#‹IrE(oãåûÉûæ©å\äJ„Å4—ñà¿%ã/ò>š×ûô¿Ã\}ù ¿o·ÞÃ	]xÃ…iÉQGk­œüóãYóãe™üžŠ-ý‰¬‡¦uÖ‚¯±Hõ5þb´2_¥z E){(²÷·Ûû_oS“ÝKW•Bi›i€8ž,±$Ø³LX	`8PCº½¸É©éOe‹( ^¾‡òaTÐCv(†FÙl÷f7«cF|tü¶ÂgâÍíº,évöŽ£é_…ŽÀ/§HJF°û1œF ka›	µÔ#þ˜^ÃnaÆk.ÄÏåÐ.¼èT<–Ñ¢mã¶|ŸešZLÉEË7û/W×­uö§Â8•œõ%¤â©SÃõ²½ß0Ï˜Ò)Ôý0×F½_<˜Ýý½ÎÉ×!–[à
	,þÜnKDZ­I‹/¡D|n–ëÐ/„;Àºi¥ãÌó]`=:¤¥²¯EyG(J_KÐ‚ilW
—Ó4ä& puMCA.@E`öYV§R­¶‡3¢5#A›7CóÃÃ¶’26#ñg£7sØÓ v&hHºh;ŠFm0n­hÀ¸:4pÏx.×¨vQ}~ƒ/húwF‡ã0†j¶¤ý}•[Ûd+Ï’?ØÉ•ZëøÁ"¥`±˜îÐõZÆ$p#€l4½è»Ç/ÊòyV6(ÀaÏxþ4&À %ŠCt5‚‰©%ÚD¢	 }^¦ÅjêÍÄPæ¡ëââônÅ)ÞœKÅ=:¾)žzŒÅ¿|:C¶ÛZ¿°ÄƒF`ô¢¡‚Ÿ“1'‹ID“t4æ¼µ>bÖQ
þÀ‰ƒ
‘(Þ‹x õt—½?C0+äÐôƒqÄ!¹%þdô¸A_ùÉhdxWa³,Ö©6êQÆÆò=[‘?¿Ïc8fÞRIy|iá;@¥àK w&Hê¦î¬/JÇœÒÿxŠ^pT˜Âižþr§ô¿šžëV‘lç¤7X	]˜ó)ã(F €|UwÀ-¼ÄEÁc·>OMÙö_LÒX˜xžý¿&Åÿ¬Vêhÿ_©äñ?W’rýïãêåµö}ªyçjƒÓª`Þsup®^¾:øVêÅÇSŸòŒäœ_Ô,…ÄÃ„zl–â?9)ÂðØ'[žn“¦ø¿Àè-ºŽyò_U¯¤ä¿j#÷ÿ\MzÆX~€³“›[¨4G/ã]ðƒ.>ìï´¾<‰™)³åVE.{æ"Ê­‰\émÊè[4%ŸA‘zƒîá?;Ý]ÂCOtÞžÝu§#T»Y®yN½¦VÙÜjjõJ½Y…ÔÜÜ‚Ÿ€÷)Yï=<M­ÿRwg÷uûtÿ¤»*ùOohÕXþÓ˜ÿO]Íßÿ[IÊýÅÿ'µÊž¬ä7Ã([PË=€[Z[°¬¶I­°`áëÛ½üžò}öÿ©ó?~•fa!`æéë)þo¥†úßz%ÿ»’”ÇáòÙßx$? Ì£Ç€‘OÑÂ*B¿D#›ìe#ÂÇî¿Ëû’5×Ëü’M]…%¹EMˆÿr+ì÷3wÎó=¸±YQ`dÕÎrÀHfëðh÷`§Ó\Q[E¶àÐû´üÙ:×J›%µ«U«åb2è‹ûñ2ÖÄ´|jäyˆÅBfðß'‡x™SÒ§ƒôhXw(êQ¾*B$‹‹³Ò0Òû@Ð¬Ãc»‹üo	3RÇ<ýÖˆã¿ÔUôÿj¨œÿ[IÊ/éÓÍN«jëáÉ*jÂÇí¤ˆ|oÎ<‡ÀN\%”þiî1è¼¨æ,˜$ËlÁ¤ôøázƒ‚e6I”Yž[Zô†ÆI|C‰c4;ý,Ü&@ðÏÓÅS5™Ãm×	@â ^„ùˆºpÖÏÄÌ?ß	óco~yÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§<å)OyÊSžò”§<å)OO0ý|ê™{ p 