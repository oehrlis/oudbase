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
        sed -i "/<INSTALL_CUSTOMIZATION>/a $i=${!variable}" \
        ${ETC_CORE}/${OUD_CORE_CONFIG} && DoMsg "INFO : save customization for $i (${!variable})"
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
‹ ç†Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹â,	.Ñø HÎpÚ…HÃ]~AvNÒòš@èĞínâHÜğƒ#üh¿úÍá_àÿ”û~¿ÿ gfUuWõ ’ %Í f$¡»«²ª²²²²²²2Ïl§ôèS¹\ŞÚØ`ôï&ÿ·\­ñEb•õj­R®¬×6«¬\©ll¬?b÷İ0Lc?0=hŠïZóA¶óó	ßE?Â?“tãï»§Ğ½`ì~ÿê˜<şÕÚŒ9Œ¥º±¾^®mÀø×Ö+[XùÚ’H?óñü‹’À™é÷sYq~	 -ív·ÙÒÜÁxö…Ùµ}Öx¾Æ}Û±|Ÿ5­kà†–°_²öx4r½€­<m¶P¦mZ=Ë³l?ğLß·Xõ«5öee£ÊÌ 8óÆ½Şk_ÚÁ–70îÜ}`-ƒ§m¦M8øØ}×Ûun:ìĞê{›­¸–_`>½3\z÷›@ Àè¸C(İêÚAXziÏôƒ¾éô¬îÓ+ş¦Du«ğÏrl]Ø¾í:‰,òÏv4öF®oqHOfX»ãÙ£€.ëYğOßb¶]s:ã=d¦Ï<+;¬ãv-Ä„X¾lÍIÆÑç0à×Ğ´ÁûV—»³œÛsTœ¾;ØÉwÍ"TŸ¨İç0¬PëÁÈß.•zs|†Ø)qŒùÈâ€Ä­¹+ ‡}TåzWÛğX®å¯Œj¹²ÉÂØ®c¶9`–‡h„<•ªQ©`-™§Ñı¸âˆÑ‚_˜Ùu˜{”5îarÙTêíÍ vè9ëM¶ÃÍÓãÃÃ“ÓæA}é½ò´]ÌÙ=œz†ëõò×Ô€–ÓÅ>Ş½9×„92ì;s0¶ü;t(÷]ë¸½{xP‡ÑÌ5GG­ƒf=rü¢•g3¦Ç@»æÙÀb·ÇÎmøaF0€ıô°İªçŸ5öÚ·€´qSq6µwwNNû­úÒ
R¸|†-•¹“ı£Óæîqkçäğøûz¾Gyzùlwj_z¯e¸.éÅ¥¥|®}Ò8>9ı¶Õh¶ëyzBödÂPÃ°-½Wj¿f+ßq
‡÷}×š³li5ŸÛoìî5šÍãV»]šşë™0!N?×:>><®—s*EÜ}$9¸gc§ƒDubààæ;ûÎE»ØßìY+ö>Î[›¶?˜W<ÃœkGr
©ˆš^5İ}¿Çò»ÏÙ6¯x->È¯ŠımöÎîİ ‰ƒÖVl²o@Œè6à÷ü÷ÌöK×ë>âÂŞ¤UÂX±ŸFìT9[	pqÂâOÅ/ÒŠ§Ì”Œâ^ZñNßê¼¥åÇ³F»C|)€Òï(Iò½@òİf§Ş´=«ƒ‹Û7è—.uOá‰WÄK2J'†¼Eˆ/ÉiåöÜ±'Xàßï>GîpÍóÙçì¼¬\³b/`eöæk\ßœìæÎÀ2†Óı‡±ğ|Kï«×ôÙÀZ+óÅ8^zù2£÷çvî:7÷µ.ujísÂâ<*°‡$°G÷5Õ	ë+…Ü{êçîÁÑ‹X$+_l¯^§!%uÍ·ÉÖ»‚ÉàôØ™ÿt9n;À¯åêÄ®t@Œ  3“96ÈdQ?‰Àù®1XÜÂ1ÉÃË;ÙİoíÁÂÒ±„åõÅ÷Å/†Å/º§_|»ıÅşöí|áë¯•¢ÇÇÙE)…iuÒ·¨÷ğwX«Vo>¯fXåßµFJ’…,ßìD3 ORğuÕ™â“Af•âÂ¤¼TG§ïbş¨M@8‰òìC`Y¬h*ó1,©Í«É`Âl0¥äO¿oŸáÓeç=µ«ı´—ÚÚuµ*nÚ³¨Y±—S{—ÚÃÉà´¬JO“½íº•äMs¶'OÒúô‰a?½‘³#ï>øsÈ"Õ…"gİ”GÀ{c|g÷ M[øR„'=Á’+ÈÃìåB¸æ"w…•6!=«ìª¢d
Ù[ĞM¶R6ØKØ÷˜9tÇIâ¦×ãÙ7X&×˜–5dï×C¹ƒÁèjÕY«€Ù
.í…YáoL…¯J%$6 ‰¤ï¸ªËm!OO¯TÇ½V(İœ>m´cˆDO­•ŠQ=¾`í¥yaÚ”µşT*Ó ï¸ãA— î¸Óç;>ì—†ö€¸f—½^zÿí!GÉTÁ­OíoÛ…Õ¾Å7ççĞ1««–¯M-ßò<À6§KR„^|joxq]oì8(¿PÇMGW½¸®¯ˆè©P×§Aİ·}Ÿ$«¤”­Rô,´£hÄ›h¨j*p‹³Äo¡?KôÚ„¶7°QS$œ±mÌˆO˜hÇ
qZÇº¢U­£í‘ŠwTqdÌÏR¬x	Jß§Š†ÈÄm~ù&KiÿW_b;•ß¢’ìÒt“ù ¿÷ÍÁÀÕ¦é¯§²Î[Ç½tx×3ä½"f–Š’ëó×Ûtlİ«-¨ùœ‹FÂ‰7Ô@VŸ”ºÖEÉêâŒÚ™ê±ÃgóÑ`peˆĞDŞ]ßĞ8„œˆ”3,@ P.n¬¼«œ]d6.ºèbÇø9f‹sºæ´\I‘NÛVV+á¾òÜf,¶*›O+NvsÙ‡ğå¬Ø}V¨ÕZ)CmX×"§“¢ÈÎliå¹M´ôIï*{ñYÇÚ@8'RìçÄ¶='d9TèÁO9é]®ÀAàÌ¿|¯S‘0¨Q%—€~sá(ÿ°_ş‡é’åÖı˜–4ˆ—ŠZ¡²7í`GâG§ş¹,·oÚwÒq+ÔxæˆåµÕÊyÜKçr‚; Öİ)pPhÈ ° c.¦v³XgR•Cêôğ0%/ğÂe/œo=+pG@¶zù‘çâôÃM¬†ÄğÈô€Ô;ñ}‡(Íúövsû‡íÖ¶‡Ò^¸ıà‚,¼QY K®™++L÷¢“‡•oví_©„Œdzx¨y®­UMÌÇõh9~9TÕXF^¯À[G{»;Tâ'ZÕ*èT™å×²³U¶´ª.´
¹…Ş?ä	CAlj‹EiT]ws†Æl`Íì˜ƒ’8­ç\"Ï–tĞ‚K°',œÉ0«YÉa&®g_ú5ÔÕ'¡‚Y¸ÂBì¹CÁz™¾ó§í€4Üm°
0uJr˜ô…o‹‰VĞ	3å„ g,¼ØOÔšIü'\$.-@×æ‰S_.$YDÿ¹]Ì§j{¯s)Ô+‹©/ÀÒû£—MÑ‘k¦_ˆ%2™Ò*T[OXcBÌØ‘‚9pÙ˜ô'ğœÈY,òcÛâ¹g[@OWğÆq‹À€†£€~yîÈòÛò±¥ğŠã(êHó šÏ_«}b©…Œ`ˆú‰NT3Q8v‹7ıæT^«hÙ˜âØ6$A|œÙìÂXrL~‡~x]´Ù²_úÃR©XZVéJıàÂâôÔì¼…¼l·ÉUÒÃñ °Gx‚ˆ!ˆÒ¡g¹Â!°Ş(F/•Ş|í—^;%Vúú:6°s@ıDÀ¹¶€©)QKŒø"¤M6~lñX®´-ïv5HxmuLVz°¯€ÖtØr"‹8z´ºZİÉ@”±ƒm‰VwRé¥ó°r\ÜÜ‘L mÈúbCf¢ú‰oÄr¸•±q#µ×lÑ_íp!Õ1ÃÙJ
¸¥÷¶Ø/4^şîôÏVÌË·lùiëùîÁûãv=ÿÚ)¾†Ò3ú™ÿz÷ùÁáqk‡zåk¾¡©oàL…ı‰•şĞèv=ƒòÕ¥*¾zıÍ2Ö²üúI‰½‡N­,­ó×-Şx_pÊ_³k<xO[z§8+P[µYŠóúÌ‚ÑÙ¨$dùéC”¦
aIŠóú2¬,øYR»?|·¹	ø—2‹ 
˜44q8_†£¨ü”ÁÙ¯ëxf_§ZjÙ©ëéË–A€o4÷wÔ¥'s3»CÛ™aK®]©c•¹†i]ÊÖTµõ-FµVÕ>1ºœ‡6NÄTˆş LœÛù¯á^³’ft-i}‹ıâO@ë¨à´¾QM%ö›xuòÑõFU#]ìŸ~4îGç±,~l‹O=Iû_nÂõQì×ke²ÿ…_[Õr™ìË•…ıïC¤…ıïG²ÿ'ÜOÅşWš°HÊãu‰öê¦¿_ğÿ=™şVÖãm'ğÜîDØ»…ê=ä¬}~Ùaæ}J>_óáŸ¶1ğ\-olü 6¼?#Ş´×M±FR¸ƒ	oÂT´ı„‡ìe„áÕì&»w±×İX7Ùæ=àlHlêI‰ŸQ:Ñ½°ô¾i˜Ø‘§_ØÈ>¨,[ØÈ.ldÙÂFva#»°‘,òáa'Xå†8Ï\ø²Sà/lUoh«:';ÎaU¸°ëû‰ÙõAÖÖÁwõ©V|Ù€¼> µ-Lûî@µs6î€7·àã»ß
»7½á¶½İ"3½‡°Ñkg˜Õ!£¢ZZ‘rÌûU·~éõZé5+õ
÷fß7û½Ÿ¼‰—`{±±MaÕ‚I]J¨³ó,U/+SÂ(«@ëdGp0-lGì1ëxîfMılõ4C¶Gw”ÖğÕUú8i<­'+JÉHè8İÛmãá5·8º`Ëx¼]9úĞĞò
,Û…äZ$Ğğ²q|€v#º$„'¤ò^§ô=Î3=ÎL ÊÀÅbØÒfã¤q]ZÅkQ©±#¬E£D{)i‹”u!ƒ`%¶P3â^û†'1µyÁ!–lbhûf¬¾.½^¿¯±ÆêRéu¥´\ˆº¦n¢BŒ'M¤µ³g…—æ]}kY‹d—K¶?bp±9Dt-¯-3ø¯ Ø¾Ço‚8Ö%±sÛ‰P*ğÈîŒ^_Ü× ¬÷›¯˜%	YŞÔ	ç\Z_ApGÌES:ı4‹ã9$oÛ)…3,Ø^-ÉBo"ºòÃ+OÊ6qer®uÎ>0KN·<õ¡Œ~¸^ÏpñpÄ7|²ÿ3`e!·åF¼P±£Ô[Ğ·¡,>ÃRZ¯Û…Æ£5æ»c¯c©2›‘¨Â¯R¥;ùY—ò¢
¤¼—˜zİpM‰ÖÜ·ğ’GÒ¨å÷d”ÔÜ=ÖõZ³²{ŒšÎ¸•)¿~Ë' <ÖrkìE¼<õ…¤œfE™[ŒĞ;vİ€sÓî6rÔµ*9ÈÜË¯^mŸLçíö›7Ë…GÀ¢™¢W{­Â,èê §3 ü©#Û¯£m–ö†Í ±Êe™åÒëüÚë|)¢´Ü‹r”à© kÙø4¡ğè|gŠä~ºô^ÆõiØ´k.Ğ« ³‡×§S=…;D4'Àí6£^Çô‚‚´v÷÷(ë‹ÑîÁu‰C,º0™‹Å¾ëÔ	º‘€O3YÌÍdàÖL´ÍRqù°)PlZˆÆf`ó´i^	ùò¯¾/Ã~	 ÍŠ_XÈ5$Å0˜øŒ¦~!p{¿øLÃ”°d‹¦¡4äÃÊ­“ÚÏ¥mP’Q±î	‰Cí^kVÂê~(d‰K¹‘Í]>Q'·ÔQña@Ş±¢OZ•ÃãíV(eŞ=Í#áD[$H˜\Y¡¿ªtşª>ÏöÙñâ;¸³;‡mö0í÷­n\ı¼¦m¿ÃŠÕu/5?e÷/m˜ug°£´<¼Yku|¨,Q¬¦—²ÈE'ï$XE:$í-²ô¡1çğ}±V.«ÛÿÄàRÓ…©PL¯SBA.ÂHÌSU!ÌgÃÿ‰Ùc>t’öŸHÄãÑG±ÿÜXßXí?+ë[hÿY­m,ì?"-ì??’ıg8á~*öŸ¼C?_ûÏMşŸbÿù•QŞÒòì›?à)!áÚG,
YW"t\çœtÉğl|zö£÷ƒÒ,hŸ‡AiÙ¨|¶ŞeÔ¬ôäû#ìÑ‹½½™;Ä;%Çì)gM'W#+÷»Vë¨^»	ì`<<ƒ	İ{iYoi²¾µ¬QxÍMëùbQş¡üÊT„=˜½…íçlA°oTú¶´aGÃ¤Ì0†­Uvv[û­ƒ“ÆŞÂ&÷TûIÙä.üÖ.lr©…MîÂ&wa“[ü”lrg2É]å.Œrog”+d»¤QîÂ˜v¸…1íÂ˜ö³2¦·ŸÌOĞ6Ø¶·‡Û­û0£`@jªTcÔ‡0²§[Ë…Õh2ãÂjta5ú[Šã¹­F¹¿Y(@Å¹\ú‘Íñe_Uğé‹t«³9@­¸ò¨¬xZ&éßX¯	ÖôQ9¸lGäÒ²Ş2‡Tñ¹ƒÖËÓ—­ÖïË‹|!w¸×Œ>À Êx]\z' ×…ÚØùİ‹£Óv(Wz
•B!¦•b_àV‚
¢9V1©pÔ„”Âú5}ÆA¢ê0}ñ"ªøz:0<š…UqìõÄÉª€¬¶ ë]ZX³»ÚqêÆ›Ÿ¬%r
¸„E2·	³³‹"úŠDİVYPe&¨v¤pkV…kEíÆ§—‰éáET”fË*à‘O¼	SÉŒ®q3CfÙ¥÷z[”B‰O3š‹ª¦¢,mìÄv]ï¸Î¹İ‹†q†ub%£vÃ°°âÑóYpTRíp9L#èıÈ·y;‡ÏØ“¬^Oéšt’/Àıô-^tÃ˜&Ôµ×špC…®•Ìw‰>£»PåqÜE½†|N?3`©>MÃ—‚ã¡™LüİÈîfá9ËÂâX`+fq<»µq¶¥ñÓÔI}£â™ŠE-·6(nLœĞùg“^j—g°‰Ûqàb¨œ	%hIÃ´ì3wĞE{=†²-ó)–âÌ-¶øO³Oé¢…ÍP¥Yê’b&“$ÍÈ½!+zé33qúÉLv7\µçîdı«g$¤”F2vdŒŸ9™z‹æ-L½o>¶©í'™Ğø×8Õ¬÷RÇdûïr¹VŞDûïZecc-Ë•õÍõ­…ı÷ƒ¤¿ø›¿|ôçí›vØf¿—¬	ß=ú+øS…?ÿàùÏşİl ''Çü•øğç?Ä²üñş¯=ú[Ãs4XÆÀô4 Æ½üã£¶€ñoñ¯GşóÍ‡+ …[¼wÓŒÆ³"ï_ğ¼Ë‹6Ìgk×éZï=úOÅÿø˜û¿ÿ×ÿöïñßÊƒÚ§™´ˆB÷TÇäù¿Q«TËñù_«Öóÿ!ÒâşÇÇ¹ÿZâÎw?¸rŠnââ=K<ŠnnÄÃ‰.nÜÇ-ròHv—#ÕO
!l  à¸iğm–€«A(g×í¼µ¼Ô"´g§Õ§æ5!?Ÿ‚±
¼«9#XÄGDğéÙh^s;ƒx„Ö¶(œ1ÙÖ_pÛú8¥]„• ­†°++l°9wQè¾=¤y½¾ NCâÍä—=œ´ßÇ¼~®ÙzÖx±‡ñXšü>Ûñ›yR5åµ<b«dâJ=—v(ò)gµjÖ½ÃÆš¼Dy›/vNÔ#ºn(pøÉ#¯ˆ,çÃËJÕ¨cİ('2>Û9!3×0·HÍ¸û¼çsé”pâäUdy"GDyWÏEñ‰<8E&.×9å˜QW¿—–ŞOÀ?f‘¬Ï|±Ñ8OñÚÌı,(:\©—YE<I{]²‚Áãœ™¥h‹ÈûÎ:ò.”MÁƒbíMlV0³`1¦f×ò°ù¤©tÏéD8z!×öM…È¨êÑA6Çv„}Dx~hûWbÈ†ù @‹¦ƒ€½Ç‘Ÿ—ëã›F±aV&P]SHM…Ÿz1ÀÚœ‹Å
<9culIrï£]_Â¢)‘<>%A©81·µVÅ&µÚ]}GÊ7w­TcJÅ¿m|×U†¿oXÙæ…ÉQ‹s7:(££rY®¹{ÜÚ99<şş”Û‘=†hDìT¦½ æ¤ÃÁHÅØ\–Æy›>Á{A;:9ù›ˆŞó£Ç:]¼Ú;dì„7ì¬wVgLÍ(	^<|q¼Ój¢B^ü$•ü'nnÉmB„‚4fø“QşŞ1µ6¥6¿Î°læíó¬`ì9¬˜N(ç…Ì¶4ü˜(™·H(£58J«:!öÎŸ–7Ä*˜®ä„r¹Å'ß¢Ò¹íùB[.F$¼´aíğ,„n24¬ ­kVX1#ÅˆW·ßµš§èÿ¹VŒ[ÂHtQ®ä¡Š€%@è™#"P<³DÊ†u^_õ® hú€ÖÜäŠˆˆFÔÉDYDòi”V²º|õ«™¤ZR	1‘/^“¡ñ<LÇ7¶CI@º8WÌà¤x—pRM	c£šaï–“‹B"'oìŒÖ‘J…aÌÄñææw´Xµ’éU$«À¸Å–¦¦5WÍçædIËkpµtÖ,ó4ÃÁğ“Nî1Öš°©$krÓ¹ÒaHK%Bt:ˆ¹šSæS8	é.Ö”gÓŒ(cƒÀîjU©P†ØÖÎÅA&!wœÙrâWh'A)RÆQåS	Fİ ÄŠ„v‘ZU
i“]¤èI8‘çBÔ—bÑ£»Ó\½İœÖnKgó¦1¢¯{3ƒUMÓô‘<†‘‹s¬,ú{L`âTÆm	ó{ld:ukô×GÉ6÷ÔÀ›€G*G›e…WGcJ“ÕA×>ÈK°¨pg.6
L~tU"ÄD%­û)™Ğ½(.éß `;ú¶AM[•UˆÂÏ=Ü’ùT}j„DÑbD„»~×İ“ƒ ®ğ& ÚÒ!åÀœ	@†ôçÜ°ëÇ÷¹×´@•àø0Œ'/ğ¢ÌJ¦ğ²j¼_t‹9nbœYí…õ©§Z§#Õòx´ü57ıáÏhÆoÎmeµ•’`Œ‹ó½!¼*qóIñ9.M7»Û=>•˜sß*BNÂXMÉøë_ë†Kò½Ô}ó£‹¾âM„¡ğT _ôíĞ’¸ÅœVBş-a.ŒKé^
ÂõÌÎÀ:%åT: ƒ«¯BpÄ8cd}(_dïFºq11â­x¤Ç¿l'3}‹M_YŠ_H”æcÎ0yç	S*4lêmsf Êğª“Ù÷š#v„œ”)U WÛÔ¬m=¯ÈzÚnï%²7ÈŞ55;iZ#WQL8nÅ³ÏcŒïÃG€ÆÇ£$3Vù°`Ø 3‹mntKçØ1Gò`~ÏIO™üQİè éK]	Ö(VL¾K<¦¥¼.ÈfŞ%áŒ@l=İ¾£ÜèBæ‰¨*{ß+]”/½·¯Ù‡>2—bEñ ^+hàn¨ªÂÉq{`ë°¸şø¶ 7³AŞL%-¡ˆµ,“tTÅÈ³àœ-QÜğÙÅJÿŞ¤Ÿ5üÛGù=)#PãC¶[nA@øÁµÓ³+V‚Lˆåkñ/b;üMq]Ègì”–le[Ñyş™B„!«ã=±{‘ÒYHë%yóY0Œ¹Û4ØÎÈ#òi¾ÆÖ` §ÛĞ¼Hİfã2Ëõ­¤=qmòN²Şİ$½[Éy7òRNœ’©®=a¨ÒPbÙ‰]™ø#—+~Q ¤ğ)Hô$ÒÕ—¢k'\êõS2{Ué.İuI†j×¿™\ÖíE¢Ê¼¡•®tmOÜTÏàw^W ™Ğ­ñcÉj°£…*)Øü‚¨dƒ+Ry(…2¯#d8äºÿv¨mHœ9ëd®#ˆ`R‹ô†Ç…ãlÁX4à^…½h?4ãÄå²Öç1e¥=Í6ªñ]®Ç–8”ÔMnÓ6Œ˜4A•E‡-—hCû2÷ä³\Ç!ö_Z+ıa©4Z–-å£®_ìœ÷Š¨°µ
h"„$Ô'jbœ¬9Q§¨ëû–îĞÍ³6!8j5¶ï¹JØh%:©îËæ‰Õr$U23GºrÇŸkézŒÇ’'á¥‘% ºúIÓAº¯HÇÓR±š8İUˆTDAš®ARg%¿È	y*ë_~•‡D(æbŞÍõÍŒ¼4’ïåOÈûåWÜÛsŞ»ñ¤|/kX&¨W”RqİEBqË«*/R5Jş¸ö"Cu¡”ˆ«/RuóÇâC¬nãŞÏ9ûğÄ
Ç?Ó|Ä#é¿„E«±Ğ)&t®)§ïIÑ0s‡-6öebëP Ç`ıD_MÄZm–/Å
–:¯_Ç^mıl‡tº­PàvH[ÛK:Zòjßf•FÍn7±	
Ü´“s½ÜœZüäIV›“÷i‰ĞïQe×·)J;í…²H[VÕıÆœÍÄ%ŸˆY“Ü
Z>'•ØÖÁww³®À‚ø¢}r¸†˜xCŸY(H_„ıïuTH'„¨ş>V(´R’ïï²S²ãûXvM¥¤d×ŞÏ¡Ld§7+|Ë/­¯âİïcÙUkx5»ò>½„´¸—ï‹ËPl9YNëJ]ß»ÅkRXŒVBy?¡ˆìT¼Hj§âû›´r)MDÖçu¡…LÉ*B&&²ò÷i€m¦ÁÆ÷iÙ÷¦f‡÷Zv•Èè‚ô­øAÔ
à¤ã‘¨<ükg$Z£)fxâ÷ÅÅ¥!kP¤¶4t†OGÖá±I\Uª—%FÍô²ê­ú®TİŠ÷FúÃ&€‹JxQ#YkÏíkÅÔãË)……ŸLô«³F¤K,t‘ƒ_cI1¡Åäqoî6~‘ûĞ¤9ìÛÑ<‡Îcã·]~RE6;ä¯Iì‡L¬TQÊL¡øÒ™ò®2öæ‹I^½İFè“ò“a´BØù+Æj¡¾²œ‡ÿ>äÆ*Y±hO‰®•ÈÌ<ÆÊc„±ôa…C) ˜ÂRéuµ´œå½øÛ'TÜF»'qª#şE±RçùmñÒ{êTüS>­ùæÆã®ÑœHÚ‰Å½Šÿò¬%ybñ[øÂLÏƒ¹eÈ›Ö}œ[òûP»ÏĞ2¤’ÿš{|ÿZŠ «ğæ;ï@3ƒL½d€Mßº¡…lÆg÷¸Â5ğ«zøÀ«°áá†TÔ˜´Hy]ÍE{' %­Pæ._SÁhEğœVâB+:4Â·¼ğ1¼+ ĞµÖœXsgkP¬Ğœš´ã‡®sÌ¬¾¤wù1Iù{Iù-ÖÇ:42z¯0ÌWiız¼A}Lëû›7±#oÇeC3èô×ØĞ2ä¬f rº6mµ;ìyYB¸¸W`ô\ŒM€Ìd€7åÙŠgQ´7¥°Âò"$ä•Ãèµb¸ô˜Öo¨Íõº¼e—üïpç}k|E.÷KÜ»˜íô´M8,t?²%Rê~b.Ñ­Z %¶°Q¦’ –ĞŒp¯HQ½JŸh<Jùdı¹r¸ùŠÆÑö\@ò
ŒKˆ¾ ¡O¶C4¢2ôœ g£vĞDnaC¸]&?eM”Ao…ã€ßét\§¨d¡Ï\ïÒôºbÌ&Sl6Ál<ÉŞ@‡²}1[Äø8ÊøŸsşN©6‰¸ÔÌòH4‚>jfÏdş ¹°9HÖó^²]ÑR±@Hº¸—ğóó®º»—Ç3ŞZ‘—±øŠôÇ±å£ÓNÍ2Øz‚¸LS¹;2wE7Âv¬KMÒÎòÊ}(¼B¶Og±hÑÚ m[
¸Ä÷j%×Š!L%añ3¥@ºeÏ”Bë±BòôjJ±˜9’8™™Rhc‚µĞ”¢s·
J3h—·~SlqRJ² È£•CíÒv†ºÆÌ+4U±úA(ŒÃRP¥å¾ÒÌ°‰"‚¦”NòKúÙtº¹B¾‡‡#Ÿu”}ê”u¯Â•k¤“‡©”ª~¬]ÍKêbB”r·ë£MC<ÑƒHØê—¥á¼)+q–H5²u ¡¡çÖrÛŠµÜ¶f-·i–ğw|~£WYÁ–ÓQÕ˜r”ÀFü Ö³.lX$¨‘µôŒ¶ÖÂ%Š+r5TœˆË
±ª?”Y_A´¸ L7©µ{,t=«ÓW~AÅ)ïê¨ˆA]¤0"zvãE:¼Œ5‡IùéÌ¬>1æÈ«?
ÍŞ™âvfûq«qÆŒCÓœ¢¸=Ú£rWÖ÷&òüEr’—’à³¬ +<`èT>TÜÏÄ…J¼·+‹.ıå%Æ™Q“¼‘nÄF[êvgÆ§£¹ª—òä5|z3µúgºÃßß:E¡Ç×¥»BîØ¤_Î¹ff¹¿Ãn™;îÓüaÏfª;{À­#úÃş_"_ÒÛÄ™ílgÚ"ŠJC¶U/$â;w¸ùÍRİî‘Ã5a…ˆQ=ƒâsæ³¨ŞXâŞ´Hİh©ùĞï‹Ö#¼+št‡ÖÄ`MkT<{èWµ4èó‘7ÒÆç¢]r„'`SøŠL÷¸‡¦É­2İwLAi2ŸrQ8ıÂ¾hjfyîŠgB{²äR›¥ŸİHG?ÙCnŸY0³³lfv9°Q´ ñOfnFÆ:6¹1©…bœ`dúş%ê˜‰†$ÁDû¯ğ¢›´Q%±
NG—]#x¤İJ?zÙäá~f(Ÿ¸€ZXfÆşã5t‡u­‡D£KºÖzŸÈ¶ˆÄ#J$lá2^°è ]½?—¥#÷±ı/ÒÍ’0Ö¿×:¦ùÿGÙ•õj¹R­m•+?ªµõGlã^[%ÒÏÜÿwÇòğÜ	£zù÷E7ÿõÚbü&uİÎıNşG3­²±¹^[/ÃøW666ãÿ	Çÿ¸Õhî·Œa÷ê |lÖjYã¿¾µÆ‘ã¿^Ş¨,â?<DzL:G
ÊÆU E#™% Ü-Üí·œ‹ù/ÿ‹ön ZvM¯kÿ(¯EÙÃÑ Èæ/´ğ G®‘¨Êı—%ú|&wj´İEweø•m†1ü9²|ƒ5è÷¿××nÃwúX‡Ş@s€¶ŠW¡û{ìVr¸«Y{úkÂäÔD³SwhöÚïÛÁ˜ß/éû•;f…ş²˜?D	êñ rw)—&ó@Â“~,“ŒT©_Ğ½µñÔÄ†}ÇÀzGàÏ<tÁ5\r¡çØ ÊŸ[ ±{–†Æ¦D£†g²¸i´÷×Øqcg2=Ã€ì¡ëÉıúeßî­”WVË3´ÆÃÛã»*“®¥tÂÈåV%Ñ¬bqhw»Ê/Fà0­®†1.VWZÖÏBÿ>3yä¢v6v:d3'öÿ€¬¾êáÔ¼qq@(>RÎlÇDÖk!ö)4AJ-iÂÚÓC2¾DS%x5¦ÈĞq*ÂQ=á=kl—2_zvXÀ)Üt™Ü`F>*{¶3~Ç¾Ûÿ—ÿü? UØÆ&EUÀF¦íXüXàØôGg–;²1+7zk›û­åûW¥vàYA§Oõû}ÒW˜ßÅ8¹4<ÎwcË›£Æ‰…½óc<ªbÃ:òEp'c¾¡Æ³
ŸÇõwä#Ô±Uqüt*¯ÏÃ°ì%NÀDÚWª(‚ÎÍ‚}0×G€,ª‡4ôŸşéŸ( ?êù€ÛşS‰½Â}j§ë[oXi\®”ü>ÌÕn)Y+ös¨¢X©+ë§•ÚvõËí/ÉÉñ	FUAm•{ÎRŠ®|'IÙ¨x3³ ‰0}Âù28%z¸âKoRá¾Ù³ÖÒòªØ¿xŸ±o”kOŞ°‰ğ”°ÃÚIĞ„6¿‘#ôğıSFêÅı“7+šÒŠbdèHÔg¶`¤—!úáîY…ià.²ÁYÑ.0¢3¦îĞíZÓ ÅpªBS¯º„ÖrÛÇ%˜éõÆ4Ÿx¨š	UMKŠ¢–s˜o| îèŒhJ_\9r±0S:²"ï+‡Î¼Æ´*º¼
tAšV’I¯"BfAà+ê4º ä±Èï€ÃÈ}eF$,¸"ÚwÏƒK\İ1x'¦‹Ø6ö§!¢ÁcGèxª;ß–÷ÿøŸtÄ÷[ÈO«1e^N©‘nñÓêäŸ¦Wj3M×«V›Qitw'¥ÚğãÔYÆ¦ôV,öéDWÚİîÀÂQŸZ÷}`úötÏíÑ:¹Í(Æ||}@Gé°Hær»êÒl½3I4£€Qôä®Cá¶Ä."z|>~Qù§åŠg««‚1Ñäâ3íJHs
’![„.#CénzéU\¹WÙŠÇ¸ßYÑw ¬µ€o¨İ„K€sÆ­¬y<cW8ñÏÔq†¯¥Êw (,Mš°œŞ64¤\é£Ä_ñ‚·D
\~L•0.p‰Á@fœxÕ%X8Ø_ËÕbeó´RŞŞ¨m—7n&TŒ²Q–É\j¿ü’Y¸©Ç‘áN0&–xA5!ÁˆÜK|
oÈçŸBÒ!¥İJeõ8&ƒ+¤šn"í*-Q¡x“Ê¦İ&NV_¢Nø`°¬†L+.ãÉ²SË%î+‹:#_•Ó Dë©ŞjZ#g¿ck¥9…‚D8ŸLü‹Èd³€Òï`g‚*iÁÉf¬İ¤à´;ãØ÷(šQé‡îÛŠñ¥Q>­lV'BA½ŸıÃAÒD:¤X×È‰,XJX£‰Åv¸½U¨°PBZ±ÈmÅ¹É`£«_3ÍîôRÓ¦bZ©$7¸EÅÓgSz¹æQzÁÙÀÔşÎ2ûR¹-_ÈBa“k…ï.ø/Ã7/&“DT0´eá¥åãM@Ä­;8¤ØÛé [x%ªC áÑv‚„H ÈcüæD¬gqöSR¾áÖêNÊ°Vœç´sÃ"ä´£„Ğ}‰şŠÇ]T^ÆŸU«ùš‚ïğŸ1åöY)³²”,„yS¢ŸèL}¦E`0FW}c Øx
ôGæ@nÏs¤ÛÕ %§¼áÿ`@¾ö¾1ºÊ€J¶F‰-¾øèjÉ’7S»cÅ¾Këù£Ø  d«°yèÄ¿À ËÙš–‡yF6d³ò²6‘-.¤Ãøa|I«;ûŒlË‚<2%‰óäßÍ³T ÙBR’À&U‡“*V› wYYá¶ H(Y‰5õvĞa÷f …ë;ìÇæ€™]ÒÉ“ç;¾ÃÈ72ÂÏs“Õwœ"ÚwP7·`|³†âË
Ã3û»A ¾0òšˆœi:2ˆ*Nä¸‹xUÏLéÂ”h¯%›æu“;Í{Ôí¡N^~Ã¾?mœ2Â‘âs/[È‰~›wh¾µ˜g3@Wè@ŒnµØ½~¡ãLBj4Ñ":u_Ìµxäb|pAÜ~`˜yXá.IP?í æDçRú(1Cşä‚ëªÁ~‹yõ ºŠ§Vª•ş>³Ğw[Õ«‚1e¬*«ª‚â®Ó$ÇfZ)nxÌ¹rN±+g<+«-
6Y$g!9¦Ì’iÅ9é<~ŒŞJ•âºáuúv`Ñ™b.÷ô*Ôk¬Ê#-Tváiø¥ë½åje¼z£*¨¸æJ(ÆÂÕ±?¦Q
ë€íá:.U‹fÀ¦‡¡…wÆ;ä¤ÇÄ<²_˜I£Zf©Ğp[RÃ=°ß¦¤®Q„ÈèPUSÖè°‡ëá3 ¦ªÅ¡Ë>ëxcty°Æ]:à)¸
ûÈO‡e¹2Ï`‡aPMì{˜ÿÒğÃeàö©•_¨2q!ñU"9€)îp¿*gIål:v´æ"C[“Ü5a­ëã¨\ZĞ°N‚4B4â„}R{FÍ‰8{æšbÍ\B]
Ãcär‹¥¬iqÖ‚yñdL±¯eâo0cÄ¾UˆtşBÇ°â_l¨™cûô0ĞWüŒÛé`êøÂ.l)¸6Ğz¡J8àHûkS¤- ŠpVÔ!±íŠõ<Š%©·TL&Ù Tokc¹ãƒ‰ç<r“3X|½&døoô„FV!ÜeIdvBÛÑ ŞPM¤LÁ*_â#Œ_¤0¸8 OáåÒA]á=8:ÎêÑæCS†J›ä´ã+˜º½	Z4ˆ°¸}ÓéY]ƒí)ñÖİ€üK¡W5ô}a£Š¯_x³$ÂÄ$$ÍĞ³†	œ™S¯xÌ«z÷4Š‹í+cÈı¤Í©\QÛt‡aS­÷¬uaáÉ4­¢ÄXÏ,4¹tÄMaîên¥/°›<3-bŞö[ï)`½$Òâ
‰´4	$¦b+Ñ·Äİ–´Q3"=3ÏuûP3frä|¯›l§Ø§4ó_šŠ¾ÑŠÂAX/—W£õ äškÓÉŠÌÒdˆU|O¬•ÇÅ$l°}—ÇW…¡RvèÒˆ´ ÀuŸÁVV˜#=Xïl\[Uq§@P5£'ZœT/°qFM¾£Ç#¼=9%–µÌŒéË]ê¢Ç&d½Y&ªV‘×ØR§ë…=Pğ1~ä–Úë”dœq¢HxˆÍ«N;“â`œ’©>Ş¥jõğÜ`/Bñ”iÇ5“„.FØ¼ÄQQf*k“9±y(ºIv*%	«4!vMS-©ò..YºL*Dt¨cè€Ë3$w£Ÿ+»3FS@›ËÄ²ÒT‘XÈ9‘pŠ{qÓj€”…wƒråP‡˜¥<QÜ@Ç¬ö[œÓ>)EÜ_œÊ„¸“«{v¢6@1Z¨¹¥ğm¢L[X`*¦NÓ{zÊKÇÈ]©Û›İkEW(†¨Q…èğ¨6À¡OOÉ››Õã¤ H_¾µW°½‹k„&B§b’Õ\u”²ÚK•ÊCf¨é[ Ï¼Rü VªgL¯óèUe§ôñ ª`zL­
òİ\ZÿnU© İ´2{4+t®’º9Şkî>#âGC´±Æ´±ß·or 2KóÔìê„
bı€òÀ+ULR‚q 8û}áğıEtŞ®>(ùT*P j¬ó&¤§ö;íÔ¸V‹•ù-|çLUšP…|O3" îÚgÔQ[]QRlÊ’-ËXQ´­¿¶ÔÆÌ¦Œ+×¤ÒÂ¤¥VØŠ¡%”Ô‚æá~c÷ Çgn±=¿]²Ó)ËÇ’”	SnôÇM%ô$	„o÷9	ôø)$PÒÚ)™î»CÇÉnZ ¢¬EEû”Ö\%Î•Ì$ôCÙ¶’ñÊS—q^ù`zåÀÉQ|Ï­fÚ´|mPBIÿÌòm©õqµdœ¸û8s/,Ú¤ïxæ#çßLfWkùqtÕèæ›P˜Y y©wÏcÆ®ù6ó¤ÆÂ'§¼õŸ‚—#Ík:Aµ¨æk@qé©€îù'|
ˆúSˆúµšxl«¨BóFMÅÃ¤ŠtjÓÁÅ‚¤‹kâ¦…4Hêú&£˜†9‘W=ƒ”È"æ•pµ3EÛ)Çà>üLéúâ£o¼ƒ\ÏŠzŠ¾ë¨(ZÓè×‘ˆĞ9X/½VS¡A¨vTŞ¾H£Îo¤? @|’BÎìôõq¯i¡òÛØ¬Y¦oÃf—ëÚhşi†Ã.q›J­!ÔI±Tná[úwÒ³¼Œ*±&uš`Mi¦¡ˆ*Ão¤ôë"ØŸğÜÏu’ŒÅìP”`Ú(ĞT• jÍ”»µ‹`f ãßfƒ)îºã@Œ^~³ ã·Ù@«d¨4úí„F¿ÎÇL<i6{V_‹zÑô î‚»‰(T2‚g`Á¬/¢ğ+,aøwu¡Šâ;!ÄÛÍ„ˆß0Ü±X»7™[…^¯éHJÆ7H©àáù•¬%Ñ0SDj	£oÙCSQ¨ÆÔôçRI,U¬x!éÌ‚¥!:…±4å;"VW³‹sC~AUQ­Ë\bX¹.%+ho¨cç¥"•»­	a@©b¯EXì£Ò*ºÆé†G®!æ¨!Z˜2Ü^ĞĞ³]ßG£}a'D¤BF gãNÜ) †ºôG-ÎIá-ıK®Ò±œUÊ‹Ö2Í@ä«çğïølOZ B†¶Šx×b¥#»TÂ†=Êx–ˆ‚XZ‰s©”_*lçr«ìUKšzò×€kõ½Ú—xÖ÷ÇgC›;"§·7(_‚BBÜİÁƒùLPZ¦ğØ‡¿ê²±C·U` #X¢,™yÉU£l°ïİ1°”+æÑ±¿	:º’C,Š03`ß`ó u———†I ×ë•Du~iow§uĞnèÍoÿèæçM =Íîÿ£ºY­VÉÿÇfeáÿã!Ršå¼ë˜ìÿ£\[ßŒü¿¬—7`ük[µÍ…ÿ‡HAÆƒoÉm¶5z¦Ğ–v»Ûliî`C7%çkì)Ú ¢ÛÄ 6îˆÖ«_²¶X“V6Û(Ó6­ú*Àxà>pØêWkìK`7ìùÀ‚3oÜë­±6,\?Zº™{£Q!ağ´0Ë€ïq âŒøŞ¬sÔKÓrÄV@- ©#¼3øõ›@à —-(İêÚAXziÏôƒnWğôŠ@MÎ”øg9¶.l\§YäMzE§vÂâFİ'c‡İ ¤.Q£b$D–AxôØ³‚è4?İ F(`È96ğ†÷c ‘:ß!‚~²om´c¿Ú†ÇÊWFyË¨–+› ws` “SÛ¥ë™¹7 (oAÅÌÁoí)LˆK²ÜC‰õ³ä%²7ÑÑéDT:€¡#a½M8A¾3+²NÅCNñ0üŠ«]qıWøìŒ¼tZçxHGã.´Ï”×ó53Yƒ×y"õø’ „	UÌ>˜K»htÉÄJÍ¨àğ°IÙãûô½½Sv÷'»‡d¡\G®ïÛ*_118¡ŒÉ©ÂŞ•v¡â¬_ÓĞ¯içÁñ+i3a ÀDÃ$€JƒB`úÙ½ †€t}1¿U-·Í±ûÕ~M¿ü©4MSÇ¤¶/©ÈW:¬É(PÅáËt˜âÒš2*ÊË êHTü	¨ •»™·e	^ò¼M‡§ktxEY“×U£Xí\7V§n×‡—Éãkâö°
¥ÂNì@c"X¼åø˜ 7]€k¾Lç
7ƒ=œ†0#ƒ;É[|‹ÆÜ¹é7©“üÉÇ–·>µ„#M†nÒ`ñê˜"ÿ—«Rş¯Â¯-ÜÿÕ*èÿs!ÿ?@ú‹¿ùËGşèÑ¾Ùa‡mö{Éğİ£¿‚?Uøó'øƒÏÿ{6““cñKüOøó×±,½ÿ[th:Ñ^ /&=>jcFóÿXÿˆÿ¶şşÿşİú¹H©)v÷^ê˜2ÿ·6ª[±ù¿¾µ˜ÿ“îkÿo€ÏT¥ø¼ ú•ºgâZ±¼õG'd”e–ÏÃÈGIßí*[„¤&AìÑ iãuĞĞÆL­!ğDQØ¸Ã§ûV"|jˆC*×¸#›Ÿ›W†SçÊ	Ìw|¾k×¿ÃÛKso¸¡Ñ®Ô—_óº¿ıú²Ä^ÅBX¼aË2g§ÛEŠ¾˜ñPg<~W”á¬®Ü¨^´àB³ÔdŸ¥ÍS2tâ¢øD"]”·ŸšWÉ0È†6aQN÷,jr¬Efü“p#2€L Æ/‘¯<¼–Ñğ5!1ù—ƒIÍ‹áfgE‰ç³uYÑ$4wÃáU×BKà'b* Z¿'›— Â2[ö1Û¡m-‡¬Ñ²W±³ğùNô/:á2œ´Âˆè®S+6i9+~wõc}™~‰EÃšá,ßQğ’v;¨v
#7Ò¡½Åñ0a×Íq•_²ã>¸ÎAsz ¹ò9
î.Ê,wâÁGX3õe&ejG_ô5¯r„¼ò¯G$s`»´\8’¹à­–gW2†\Î…Ùì~Z§b­¶™™Â9£äîLÎÍ'd”ØŠ†2‘è³y–‰öxV;5«–IA]ÈB¬õFõå0ìgøÒíó·JLQù¾H	ù
Pµ‡×Cöö0ÊåÀÌƒµù¹I3õeüĞeÆ*L–;p½º9Ü0C:˜³ğ»Ç/|åóWiĞüÈ<ci•Œ’ĞÀÉaÕr˜'¢–‰„ˆ	L }iÅ6Ê“‰¡ÄÅ¢âÖÍŠ“I˜RÜ³F7 iEPü›ÁˆlÈ$ˆÛ­/_Ø‰hcy¢Š±8YŒC¢Ç_ õW}Y3+¥#n„Oğ’ø¼j6Y,¬t¤œ¡Û<`ùSîcìX//¾Kƒa¦CƒKµ%şxøq¡CÓ»’Íêú0OCSÒ„´GÅV¤X‹$à¼Ø•šÅ ¤4®>(d`­tfiEş,LîÎòçMÕÿªFoó¬cFıïze}½ZÛ¬±recc}k¡ÿyô‰ë¡ÿı×Şy|§~.RjJw¾8ß:¦ÌÿêÖVbşÃ¯Åüˆ´Ğÿ~\ı¯æòô'©V­î'hƒãª`õªÜB|û&|îêà™Ô‹O}ÆØc~‹é®^ÌwÛÔcû°”r-ì$ÿ¼,ßß3Mş¯UÄùo¹V­mmaüß­­EüÇI<ş£âÜ[A²
¶]Çµ?TÅò°w3_®+/ÛáÛšxÛ -·|»!Ş+ÛtùmCŒ„»ÿàj„·Ø0÷Æo„¿šíV‹ñëííıÜã›Î%–ã÷O·+ë_~µ]Ù\ßÜ®AÚşò+x˜ŸÏ¾}^)İµú|ë˜&ÿol(÷Êÿ¹¶±µØÿ?HZÜÿø(÷?â¡>WÉ?ãHº ¾¸2±ó•ÔFNÏÍYôştoŞ±Öá³ù ıØ|>+a•û®£<Ûı_ûk[åJ…îÿÖj‹û¿‘0|Î}×q›ñßØZŒÿC¤(NÅıÕ1ãøÃş}«¼¾‰ößåòbş?HŠE}º—:n>ÿ×·*ÕÅø?DÒƒİO³ÿFukÆcc1ÿ$%"ĞİC7ŸÿµÊbı˜”§j®u”'ëÿ*e®ÿ_¯Ô667ª8ş ş×ú¿‡HuÇ¸ë}.œ7„¡(œ.;½ÅÉ@câãuÂ@|eD/Eü¯>7ˆïA¼z‹@óêîyæĞÏå'ßÖ—ğïí%ruk„¦ŞâöÉ›"/wç(jŸs°ÁCøÙc
¦şùüÜSzlÚùÖqóõVÍÅúÿ)¼øê¸Ñş«Œò_µ¶±ÿ‡HÓ‚WÏ£)òßúzmÇ¿BÊxÿ«\]Ø<Hš×™Iü`v×9÷L?ğÆmL\äè²66îÌ3Ùøql<\û\ÏbµÒñsXXò¶ŒJÕ(×bÇ¯ñcVW‰<Šó»•ÔXÖ¤È ±³ÖÔƒRáZV˜k6›{¬b”Ù¯Øó£=tL;OÜî»]r¦,Úâ[ëÙè˜wõù	+Ûá-;f;ğs(Î{á9Ê/ñøÔH)'‡ÍC#êİœZÊF3×WïTÓÔÀrJw€(Õ¡”!ò=+XYq]0÷òËƒ@íOy¹|A…ó2àæ `,5ø¥ô…Ÿg_0¥…İ^¢›LB´`%•ß»Ä;JtöÚù‚,ìûY~Ráv{O)_ÊSÙ¬îğ²/Ú­c,xitiwòaÃaÆ‡eó¢•vûåáq60¹‘‡ZæôÍ£y`Úf¯¾ğß,Çñu,{—0‘ Ê™¥±Xö»ñÜT‚—ˆçèŒ
¼ˆğ“
ñåã„däFŒAîèvõË½¶œÿü±şf…÷7Œg¢ZÁÃZ%’§'¼X„I¥RT‚Ôğ2© bê@™\~¦•Š°VOà©õ¸`éäc/±ŸtJßÿÿšcSä?Xû¿­…ü÷0iqéç¡/ı|¶¶~{’AdaFc@Åv-n(lìúÆMÅ¨”ôÆMÌ­oäx•×q4èîcJF®ä!#¿ãNßÓz	d2ò`nĞÃĞöÑé²û–ø Ö7èÁ·„ŸåòÛÜõBñû3M‰óßù.ı”¦éj‰õ¿¶¹¹°ÿ´Xÿëÿ¬·|Aüàñû½‹õ^iÂ¼á]ZÖÛÁ;c41îVŞ=Ç€†=.¼#!]èÏµràÄ_±Uø¯èãâF<N~p,¿ÏŠ{öbo)Ğæo w÷Ì4:}öä	+Ã‘š¯bWŸü²’»ôuM÷h;â—™‰åµêÚúZmmcmóVèÜ=Ø9ní·NŸ
V…éÅÃa²Z%L®ÎŠ?!6#şn‚°½¬¤Û^üSÒ]>?¨™KÓä¿xöŸµ
ùÿŞ"û¿…üwÿin¯oßğğ#JgX;Ê1EE:%Aÿ˜O‘ÖŒ4™mM×0|cLbS%2	¢¼e .FbE$“y*t2§JaòËiÅvåa {á¦õÚü+hã°˜åPX$êi¬£Šô&Ëi^Yè'FVf’kDM0E]& ò†q­¥ğª´è›\7Jgl…N2
kt)‚)°çÂ
¶}”(Š®©q¦˜”&J2Àš7r·1ÛÚwÜuYg”¤Xt|¯„—åD7Å¿¥X-]‚ÏK¦T>:ÙÅPå‡m»–Ù	€º‚ÙkéŠâÓªi£=¦
£ÍÁDàdÄ9hwtsÈnÊHğ0CóãÇ±si z¢0˜Ÿå¯p±%¶ÄİeæY;—üd”ØqèÙ]2øÄÃóÈE
bœc»s¯¼É)±™ëx HŒ@ºìÈ½4À¯;Vpézo§äçåÅ_²Ü+Á—ßäN®FVİ·a‚[9<c«‹èdÏqÖ]q=;÷ŠÃ$gq=.–á´E³âà»ecÅÁx®õÎêÍİ¼l‰Èî¥u¶‡Gh¹Ê¹£[À:#xîHírº¦×=£qPªDı*àI°7„]Üs×‡ãA`±Î½¦ß$éòŸ\ÃóGs¬cŠü‡×}Âû?Õr™ÎÿÖñ_$½j<ß=h½É[şÈÅèÓ¤ŞA«ë ğÿr¯·ZÇ»;oríÖÎ‹ãİ“ïO_5'­öéw»Óıï¹?ğö‹#4©Ÿ›¾·Hé>’>ÿe"Ã[s¬cÚü‡·Ñü_'ÿŸ›[‹øO’lçÂrpı>…1O¬D"C‡Ó&|ìÖ/Ò]Slş»§R™7?ĞTıÏÆV¨ÿÙ¨áıÿ­Íõ…ıÏƒ¤…şGÕÿ¤ÑÿBô * é)JŸµY`?€ú'îW”Nx÷¡š¡¦;èf‚~KUP&ì9ò„ŸŒ6Hõİz¿Š Å ~xÔ:h¶OÃ¸æõ<Íe^ú¡û¶b|i”O+µZ)¯+*QPx’A:]ß’Î¹ª§ØEÏrÛĞHUÕ3¥¤;Š<¶ğöŠz'm	$]3ô¹ª†bş¸{ÜS$m_Ì¥©ößëë1û¯­òÆ"şÃƒ¤…½V¼Ùq{-m>|¶Æ[Má¤U9uEsŞœ ¸Òœ~ÿ\-ºr]@a·Sô=¤Ã5xp½^®ÛÙfáËœ{†g
< ¥x=Ó±$“xı¬$bÇ©ÓÚé¯¥Áî@ş9Y<VSg°ã:ˆú–B>²\X¨3!óÏ7‚ü±YÓ"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"-Ò"Íş?|ôˆ. à 