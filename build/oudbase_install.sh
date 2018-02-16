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
        if [ ! $(grep -q "^$i" ${ETC_CORE}/${OUD_CORE_CONFIG}) ]; then
            DoMsg "INFO : update customization for $i (${!variable})"
            sed -i "s/^$i.*/$i=${!variable}/" ${ETC_CORE}/${OUD_CORE_CONFIG}
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
‹ Œì†Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹â,	.Ñø HÎpÚ…HÃ]~AvNÒòš@èĞínâHÜğƒ#üh¿úÍá_àÿ”û~¿ÿ gfUuWõ ’ %Í f$¡»«²ª²²²²²²2Ïl§ôèS¹\ŞÚØ`ôï&ÿ·\­ñEb•õj­R®¬×6«¬\©ll¬?b÷İ0Lc?0=hŠïZóA¶óó	ßE?Â?“tãï»§Ğ½`ì~ÿê˜<şÕÚŒ9Œ¥º±¾^®mÀø×Ö+[XùÚ’H?óñü‹’À™é÷sYq~	 -ív·ÙÒÜÁxö…Ùµ}Öx¾Æ}Û±|Ÿ5­kà†–°_²öx4r½€­<m¶P¦mZ=Ë³l?ğLß·Xõ«5öee£ÊÌ 8óÆ½Şk_ÚÁ–70îÜ}`-ƒ§m¦M8øØ}×Ûun:ìĞê{›­¸–_`>½3\z÷›@ Àè¸C(İêÚAXziÏôƒ¾éô¬îÓ+ş¦Du«ğÏrl]Ø¾í:‰,òÏv4öF®oqHOfX»ãÙ£€.ëYğOßb¶]s:ã=d¦Ï<+;¬ãv-Ä„X¾lÍIÆÑç0à×Ğ´ÁûV—»³œÛsTœ¾;ØÉwÍ"TŸ¨İç0¬PëÁÈß.•zs|†Ø)qŒùÈâ€Ä­¹+ ‡}TåzWÛğX®å¯Œj¹²ÉÂØ®c¶9`–‡h„<•ªQ©`-™§Ñı¸âˆÑ‚_˜Ùu˜{”5îarÙTêíÍ vè9ëM¶ÃÍÓãÃÃ“ÓæA}é½ò´]ÌÙ=œz†ëõò×Ô€–ÓÅ>Ş½9×„92ì;s0¶ü;t(÷]ë¸½{xP‡ÑÌ5GG­ƒf=rü¢•g3¦Ç@»æÙÀb·ÇÎmøaF0€ıô°İªçŸ5öÚ·€´qSq6µwwNNû­úÒ
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
NG—]#x¤İJ?zÙäá~f(Ÿ¸€ZXfÆşã5t‡u­‡D£KºÖzŸÈ¶ˆÄ#J$lá2^°è ]½?—¥#÷±ı/ÒÍ’0Ö¿×:¦ùÿGÙ•õj¹R­m•+?ªµõGlã^[%ÒÏÜÿwÇòğÜ	£zù÷E7ÿõÚbü&uİÎıNşG3­²±¹Y­Ô`üáWy1ş‘pü[æ~Ëvï©ÀÇf­–5şë[[aü9şëåEü‡IIçHAyÃ¸
¤h$³”»…»ı–sñ/ÿåÑŞDË®éuíåµ({8 ñÙü…äÈ5U¹ÿr¡AŸÏäN¶{£è®¿²Í0ƒß1G–o°Æ ış÷úÚmxáNëĞhĞVñ*tİÃJw5kOM˜œšhvê­ÀBû};SCàû%}¿rÇÌ±Ğ_ó‡h"A=@î.…ãÒ¤qÈ@xÒƒe’‘*õz£·#šØ²ïXïü™‡.˜ ÆK.ôDùs$vÏÒĞØ”hÔğL7öş;nì¬Q¦çc0‚=t=¹_¿ìÛ²•²ñÊªcyæ€6Ãxa{|WeòÑµ”N¹Üª$šU,-ànWùÅ¦ÕÕ0ÆÅêª@ËáYèßÇâb&<@TÀÎÆN‡læÄşÕW=œú7î ÒGÊ™í˜èÃz-Ä>…&H©#MØC{`zHÆ—hª¯Æ:NE8
¡'¼gƒíRæKÏËÁ2…›.óƒÌÈGeÏvÆïØwûÿòŸÿ´
ÛØ¤¨
Ø¨À´‹›şèÌò cG6fåãFomÓa¿µ|ÿªÔ<+èô©~¿Oú
sà»'—†Ç¹ânlysÔ8±°w~ŒG•ãQl¸BG¾èî¤qÌ7ÔxVáó¸â|„:¶*ŸNåõyVƒ½Ä	˜HûJEĞ¹Y0 æúEõğñ‚†şÓ?ı áG=¿pÛ*±W¸Oít}ë+Ë•’ß‡¹Ú-%+cÅ~U+•beı´RÛ®~¹½ñ%¹"9>Á¨*¨­rÏYJÑ•ï#)•of4¦O8ß@§DW|éM*üÂ7{ÖZZC^ûoàï3örÍâÉ6ƒvXB;	z‚Ğ†á7r„¾ÊH½£8£òfbESZQŒİ‰úÌVŒô2D?Ü=«0ÜE68Ë!ÚFtæÂÔº]k´NUhêU—ĞZÎ`û¸ÄÓ1½Ş˜æU3¡ªiIQÔr®óÔMé‹+G.ÖÆ"`JGVä}åĞ™wÁ˜VE—W.HÓª @2éUDÈ,|EF”<ùp¹¯Ìˆdƒ‚WDûîyp‰«;ïDÃtÛ&âÂş4D48"¢cìOuçÛòş?ğÓ‘øâñ~ùi5¦ÌË)5òÀ-~ZüÓôJm¦ézÕj3*îî¤T~œ:ËÓ¸Ó”ŞŠÅ>èJC»ÛX8êSë¾Lßƒî¹=Z'·Å˜¯è(É\nW]š­w&‰f0ŠŞƒÜu(Üö‚ØEDÏqÂÇ/*ÿ4 \ñluU0&š\|¦]	iNA2d‹pÃed(İM/½Š+÷*[‘â÷;+Úsá€µğµ›p	pÎ¸•5gì
'şá™:ÎğµTù%ƒ¥I–ÓÛ††”K }”øk!^ğ–HƒË©Æ®"1ÈŒ¯ºûËb¹Z¬lVÊÛµíòÆÍä‘ŠQ6ÊR"™Kí7_27õ82Ü	ÆÄ/¨&¤"Ñ{‰OááùüSHz"¤´[©¬ÇÁdr…TÓÍ@¤]¥å *Ï`RÙ´ÛÄÉêKtÃ‰L–ÕieÃe<Yvj¹Ä}eQgä«r„h=Õ[Mkäãrl­4çÁ³Pç“‰™lPúìLP%-8Ù,€µ›Ôsœvgœ ûE3*ıĞ}[1¾4Ê§•ÍêDH"¨÷³8ˆAšÈC'‚ë9±ƒK	k4±Ø··
JH+¹-£˜"7™ãltõk¦Ù^jÚTL+•ä·¨xúlJ/7Ã<J/8˜ÚßYfßSj#·EàYè lrí¢ ğ]ÂÿeøæÅd’ˆ
†¶,¼´|¼	ˆ¸u‡{;`¯Du$<ÚN	ù`Œßœˆõ,ÎşqJÊ7ÜzA}Ã©@y#ÖŠóâœvn˜ÃS„œv”º/Ñ_ñ¸‹ÊËø³j#_Sğş3† ÜÀ>+å`V–r‚0oJô}ƒ©ÏÔ¢è±ÆèªoOşÈÑœÈíyn€t»: ¤ä”7üÈ×Ş7FW CÉÖè/±Å—]-ùCòfjw¬ØwÉ`=û€l6ø`9[SÀâ0ÏÈ†lv@^Ö&Râ±Å…t?Œ/iugŸ‘mYG¦$qü»y–
$[HJØ¤êpRÅjÓä® ++Ü	%+±¦Şš"ìŞ p}‚ıØ0³K:yò|§ÑwùFFØãyn²úSDûªãæŒoÖP|Yaøbf7ÀF^‘3MGQ¥Ã‰wq¯êyƒ)]˜íµ¤qÓ¼nr§yº=ÔÉËoØwá§SF8R|®áe9ÑÂoáÍ·óñlè
ˆÑ­»×2tœIH­ƒ&ZD§î‹¹öƒ\Œ.ˆÛ¬3Ï+ÜE"	ê§Ôœè\JŸ%fÈŸ\p]5Øo1¯@WñÔ*B•£ÃÂßgúna«¡zU0¦ŒUeUUPÜušäØŒA+Å#WÎ)våÌ“g…bµEÁ&‹äl $çÂ”Y2­8'ÇÑ[©¢2B\7¼Nß,:SÌå^…zUy¤…Ê.<¿t½·\­ŒWoT×\	ÅXx¢:öÇt Ja°=\Ç¥jÑØô0£ğÎx‡œôØ˜G–ã3iTËÀ,nKj¸öÛÔ“Ô5ŠªjÊZöp} |ÆÄTµ84cÙgoŒ.Ö¸K<Waaùé°l!Wæì0ª‰}ó_Ú~¸<âÂ¾ •£¢ò5B&.$¾ªBâ10ÅîWå,©œMÇÖ\dhkRƒ»&¬u}•KÖIFˆFœ°CêaÏH 9gÏ\S¬™K¨KabxŒ\î`±ô5-ÎZ0/¾€Œ)öµìCüfŒØ·
‘Î_èVá‹M5sbŸúŠŸq;L_¸À…-WÂZ£"T	imŠ´DÎJƒ:$¶]±G±$õ–ŠÉ$„êmmL#·a|0ñœGN`r‹¯×Ä‘ÿĞÈ*„»,‰ÌNhû#Äª‰”)XåKC|„ñ‹æ g‚à)¼\:H£+¼GÇYİ1Ú|hÊPis€œr\¢cS·7A‹·o:=«k°=%Şz¢)TBâª†¾£/,`Tñõo–D˜˜„„¡ºcÖ03sêyõQïFq±}eb¹Ÿ´9u€#j›î0lJ£õµ.,<™¦U”ë™…Æ!—¸)Ì]İ­ôÅñv“g¦¥QÌÒşckà=å¬wDZ\C!‘–&ÄTl%ú–¸Û’6jF¤gæ¹nß Ê`Æì±B.‚\ƒïu“í{à”f~à‹BSÑ7"ZQ8ëåòj´„\sm:Y‘Yš±Šï‰µò¸˜Äƒ¶ïòøª0”CÊ]‘¸Îá3ØÊ
s¤gëk«*îªfôD‹“ê6Î¨É—`ôx„÷£'§Ä²–™1}¹K]ôØ„¬7ËÄ3BÕê!ò[êtİ³°Ê>ÆÜR{r‚Œ3N	±yÕigRŒS2ÕÇ»T­ìE(ò í¸f’Ğ¥"Â›—8*ÊÂLemr#'6E7ÉN¥$Ab•&Ä®iª%UŞÅ%K—I…ˆuİ±py†änôsewÆh
hs™XVš*9'NCq/nzB²ğnC®ê³´“'Šè˜Õc‹súÀ'¥³ˆû‹S™wruÏNÔ(Fk5·¾M”iLÅÔÉaz¯SÏ@yé¹+5b{³{­è
åÂ5 ªşÕ8áé)ys³zœéË7¢ö
¶ ·âbqĞDèTÌA²š«RV{©RyÈ•"}« à™WŠÔJõŒé•b½ªì”>TL©UA²›Këß­*¤›Vff…ÎUR7Ç{ÍİgDühˆ6¶Ñ˜6ãûöÍSDfiš]]‚P¡B¡Px¥ŠÉSêA0g¿/¾¿ˆÎÛÂÕ%ŸJ
TuŞ„Ô#âÔ~§×j±2¿…ïœ©JªïiFÔ]ûŒ:j«+JŠMY²e+Š¶õ×–Ú˜ùÀ”qå:ƒTZ˜´Ô
[1²„²ZĞ<Üoì¤àxâlÃ-V¢ç·kAvú Å`ù8C’2aÊş¸© „$âí>'¾?…JZ;%ÓÑ}wè8ÙMkT”µ¨hŸÒš«Ä¹’™„~(ÛV2^yê2Î+L¯8¹"Šï¹³ÕL›–ï¢J(éŸY¾-µ>®c¡¡¶ƒŒwgî…E{ƒô}oÁ|äü›Éì
bb­!ß3"®İ\có! 
3« /õîyÌØ50ßÂfÔÀXø¤ñ”’·şSğr¤y-P'¨¶Õ|h#.=Ğ=ÿ„OQJÀQ¿VmuBhŞ¨i! x8‚4@‘Nm:¸X°‚4pqMÜt ±i@C]ß$`bÓ0'òªgĞñ‘YÄ¼®öq¦h;åÜ‡Ÿ)]?C\côwëYQOÑwı Ek=à::ë¥÷‘Àªc*"4ÕÊ»ÃiÔù´Àâ ˆORÈ™¾>Îá5-T¾`»›5ËômØìr]Í?m¡"ÂpøÁ¥#nS©5„:)–Êm á/|KÿNz6€—Q%Ö¤nA¬)0Í4Qeø”~]„ûÓû¹N’±˜ŠLšª2@­r·vÌ`üÛl0Å½Bw(€ÑËo`ü6h••F¿Ğè·Ñù˜‰'ÍfÏ*âkqA/šÄ]p7…JFğãŒ ø1‚õE@~…%ÿ®.TQ|'„xa»™ñ†;k·Âà&s«Ğë5IÉø)<<¿Rƒµ$Z#fŠH-aô-{ˆÃa*
Õ˜šş\*‰¥Š/$Y°4D§0¶“¦|GÄêjvqnÈ/¨*ªu™K+×Å¢díuì¼T¤r·5Á"¨"ÕóBŒáµ‹}TZE×8İğÈ5Ä5DS†Ûz¶ëûh´/ì„ˆTÈälÜÃé‚;ÔP÷‘ş¨Â9)¼¥ÉU:6‚³JyÑZæ¢Yˆ|õşŸ-ãITÈĞVïZ¬ôƒ`äo—JØP£G™ ÏÃñCKK qƒ"•òK…í\n•½jISOş:‚¢ p­¾7°CÛãÏZÀâşølhsGäôöåKP¨@ˆÛ³;x0Ÿƒ	JËûğW]6vè¶
TcK”%3¯1y¡£j”ö½;–rÅÜ3:ö7a@GWrˆEfìl´îòòÒ0	 áz½’¨Î/ííî´Ú­" }²ùíïÿ£İü¼	¤§ÙıT7«Õ*÷ÿQYøÿxˆ”f@9ï:&ûÿ(×Ö7Cÿ/ëëåÿÚVmsáÿã!Òã_ñà[2G›m)´¥İî6[š;ØĞMIãù{Š6¨(ä61¨;¢õê—¬-Ö¤•§ÍvÊ´M«‡¾
0¸¶úÕûØ{>0ƒàÌ÷zk¬×–‡®GæŞhTH<m'Ì2à{c€8#¾·ëõÒ´±Fhêï¾Dı&8ÀeJ·ºv–^Ú3ı`‡Û<½â#ĞD“s#%~àY­×©DùgÓ‚^Ñ©°¸Q÷ÉØa7 ©KÔ¨	‘e=ö¬ :ÍO7€
rNƒ<‡!Äı@$¤Îwˆ Ÿì[íØ¯¶á±ò•QŞ2ªåÊ&ÈÀÈäÔvézfî(Ê[P1sğÛB{
â’,÷Pâ@ı,ù_‰ìdtt:•`èHXo AÎGĞ„ïÌŠ¬SñD<ÿ„âjW\ÿ>;#/Ö9Ò‘Å8í3åõ|ÍLÖàuH=¾$aB³æÒ.G2±R3ê8<lR`öø>}oï”G£İıÇÆÉîáY(×‘ëû¶
ÃWLLN(còBª°w¥]¨8ë×4ôkÚypüJÁLX(0QÇ0	 Ò ˜~v/€! ]_ÌoUËmsì~µBÓ/*MÓÔ1©íK*ò•«g2
Tqø2¦¸´¦ŒŠrÄr€:*hånæ­@cY‚—<oSàáé^QÖäµcÕ(V;×Õ©Ûõá%Fòøš¸=¬ÂC©°;Ğ˜o9>&ÀM— ãš/Ó¹ÂÍ`§!ÌÂÈàNòß"Åƒ1wnúMê$ò±å­O-áH“¡›4X¼‡:¦Èÿåª”ÿ«ğk÷µ
úÿ\ÈÿşâoşòÑŸ?z´ovØa›ı^r|÷è¯àOşü	şàóÿdãääXüÄÿşüu,ËŸEïÿ$] ZÆ ¤N´À‹IÚ˜Ñü?Ö?â¿­¿ÿ¿w§~.RjŠ]Æ½—:¦Ìÿ­êVlş¯o-æÿÃ¤ûÚÿß›à3Õdi>o€~¥î™¸V,oıÑ‰Ùe™åó0òQ’Çw»Ê!©I»@t'hÚx4´1S+Âc<Q6îğé¾•Ÿ€A¢Å…Ê5îÈæçæ•áÔ¹róïÇõïğöÒÜ.Ch´+õå×ãß¼îo¿¾,±W±oØ²ÌÙéöcQ†¢/f<Ôße8«+7j£×-¸Ğ,5Ùg©Aó”x†(>‘Fåí§æU2²¡MX”Ó=‹šk‘ÿ$œÅˆ ¨ñKäk ¯åF4|MHCş¥Ç`Rób¸ÙYÂGâùl]V4	ÍİãpxCÕÂµĞø‰X„
€ÖïÉæ%€0¤LÆ–}Ìvh[‹ç¡#ëG´ìUìì|¾=Ä‹NE¸'­0"ºëÔŠMZÎŠß]ıX_¦ŸEbÑ°f8Ë÷ÀE¼¤İªÂÈth¯G1$C<ŒGØus\%Å—ì¸®sĞœ@®|‚»‹ƒrà ËxğQÁ–ÃL}™I™ÚÑ×}Í«!¯|ÅëÉØ.-N§d.x«åÂÙ•Ì…á—sa6»ŸÖ©X«íAf¦pÎ(¹;“só	å¶¢¡ŒF$úle¢=ÕNÍªeRP²£k½Q}9û¾tûü­ST~ƒ/Ò@B¾Tíáõ½=Œr¹Ã0ó`mş@nÒÃLF}?t™±
“¥ã\¯n7Ìæ,üîq ƒÀ_ùüU4 ²ÏXZ%£$4prXµæ‰¨%d"!bh_EA±òdb(qC±¨¸u³âd¦÷¬ÑÍ (FZÿf0"2	âÂvëËv"ÚX`…¨"C,Nã(ÆñhıU_ÖLÁŠEiÆˆá¼$>¯šM‹+Cc )gè6X¾ãÔ£ûûÖË‹ïÒ`˜„éĞàRm‰?~ÜÆÀGhÃĞô®d³º>ÌÓĞ”ô#áíQ±)–§Å"	8/v¥‡fñB(©«O
X+YZ‘?“»³üù„ASõ¿ªÑÛ<ë˜Qÿ»^Y_¯Ö61şËÆÆúÖBÿó é×ÿ:Bÿû¯ÿ¼óøNı\¤Ô”î|q¾uL™ÿÕ­­Äü‡_‹ùÿi¡ÿı¸ú_ÍåéOR¬ZİOĞÇUÁêU¹…:øöMøÜÕÁ3©?úŒ±ÇüÒ]½˜;"î¶©Çöa)å2ZØIşyY¾¿5fšü_«ˆóßr­ZÛÚÂø¿[[•Åúÿ‰ÇTœr+HVáÑ¢«ó¸vá‡ªø@ö`†âËuåe;|[o´å–o7ÄÛce›.¿mbˆ‘p÷\ğæ^ÃøğW³İj1~½½½Ÿ{|Ó¹ÄrüşéveıË¯¶+›ë›Û5HÛ_~ óóÙ·Ï+¥»VŸoÓäÿåşOã?×6¶ûÿI‹ûåşG<”Áç*ùgÜ IÔ7@&6`¾’úÃÈé¹9‹ŞŸàÍ;Ö:|6 ›Ïg%Œ¡rßu”g»ÿbm«\©ĞıßZmqÿ÷!†Ï¹ï:n3ş[‹ñˆÅ©¸¿:fØÿ¯o•×7Ñş»\^ÌÿI±¨O÷RÇÍçÿúV¥ºÿ‡Hz`°û©cöñß¨n­Óøol,æÿƒ¤Dº{¨ãæó¿VY¬ÿ“2âTÍµòdı_¥Ìõÿë•ÚÆæFÇÄÿÚBÿ÷é±îxw½Ï…ó†0…Óeç¡·8hìOœ`¼Nˆï¯Œè¥ˆÿõÂçñ2ˆWc(bã@İ=Ïú¹ÜQãäÛúş½½D®nĞÔ[¼ Ó>ySòåîEís6˜b?{LÁ”Â?¿óŸ{JM;ß:n¾şÃ*°¹Xÿ"%‚ßC7Úÿo•Qş«Ö6ãÿiZğêyÔ1Eş[_¯­ãøWèOïÿo•«ûIó:3‰Ìî:çéŞ˜¢‰‹]ÖæÁÆıy&?‡kŸëY¬V:~KŞ–Q©åZìø5~ÌÊã*‘Gq~·’Ëš$vÖšzP*\Ë
sÍfsUŒ2û{~´‡iç‰Û}·KÎ”E[|Ëb=İóî±>?a¥s;¼eÇl~Åy¯#<Gù%Ÿ)åä°yhD½›SK¹ÃhæúŠàjššãXNé¥:”2D^£g+Ë"®Fã^^cy¨ıá)/—/H £0`^& Ü  Œ¥&¿”¾ğóì¦´¢£ÛKtó‘Iˆ¶¬Ä¡ò{—xG	nÁ^;_…} ËO*Ünï)å«QyŠ ›Õ^öE»uŒ/­3.íN>l8Ìø°l^´²Ñn¿<<nÂ&7ò°AËœ¾y4LÛìÕş›å2¾eã&²ã DÙ#³4Ëa7ƒJğñÜQ~RÁ#ş¢ÜaœŒÜˆ1Èİ®~¹×–óŸ¿!–Àß¬ğş†ñ,CT+xXË±D’ãá„‹ğ1©RŠJ^&DL(“+ÂÏ´RÖê	<µŞ×,|ì%ö“Néû?à_s¬cŠü«`bÿ·µÿ&-.ı<ô¥ŸÏÖÖoO2ˆ¬ Ìh¨Ø®Åm …İCß¸©•òƒŞ¸‰¹õ¯Rà:îƒİ}LÉÈ•Ü3däwÜ)ã{Z/LFÌzÚ>:]vßÒÀú=øöğ³\~›»^(~¦)qş;ß¥ŸÒ4ıO-±ş×67öÿ’ëÿbıŸõ–/0ˆÜ3~¿w±Ş+M˜7¼KËz;¸bçcŒ&ÆİÊ»çĞ£Ç…w$¤ı¹Vœø+¶
ÿU }\ÜˆÇ)Ğ¥@ã÷Y1`Ï^ìí±"Úüäî™F§Ï<a¥`8R³ãUìê“_Vr÷€¾®‰ám§ãQü2óã!±¼V][_«­m¬mŞ
»;Ç­ıÖÁIãSÁª0½x8LV«„ÉÕYñ'ÄfÄßMö±×á•tûÏËJºkÃç5s©cšü·Âş³V!ÿß[dÿ·ÿî?ÍmÂâõí ~DékG9¦¨Hg  $èó)Òš‘&³­éâ†oŒIlªD&A”·ÀÅ( C@Ì£ˆd2O…NæT)L~y2¢xÁÃÀ®<d/|À´^›mv‚³
‹D=uT‘Şd9Í+]âÄÈÊLr¨	¦¨¢Ë@Ş0Î±¡µ^Uƒİóo“ëFéì­ĞIFÁ`.E0¥ƒ Öó\XÁÑ¶OƒE1¢Ó55Î³ƒ‚ÒDIØBóFî6f[ûî».ëŒ’t ‹ï•ğ²œè¦ø·« Å±KğyÉ”
ÒC'»ªü0 m×2;PW0{-]Q|Z5m´ÇT¡bôã±9˜œŒ8g ínÙM	fh~\à8v.DOó³üî#¶Ä6’¸»Ì<‹bç’ŸŒ²;=[£KŸbc¹HÁ@Œslwî2€79%6s‰H—¹—¦øuÇ
.]ï­ãÔ³‚\ã<°¼øK–{%øò›ÜÉÕÈªû6Lp+‡gluì9NÀº+®gç^Bq˜dá,®ÇÅ2œ¶hVü|÷Ã³ll¡8ÏµŞY¢¹›—-Ù½´Îöğ(-W90wtXgÏ©à ]N×ôº‡ã`4ê@•¨_<	ò†°‹{îúp<ì"V#Ğù±×ô›$]şƒkxşhuL‘ÿğºOxÿ§Z.Óùßú"şëƒ¤W­ƒç»­7¹cË¹}šÔ;"hu$ş_îÕóÖAëxwçM®İÚyq¼{òıé‹£fã¤Õ>ın·qºÿ=÷Ş~q„æ"õssàÏ÷É"İGÒç?°LäoxëbuL›ÿğ6šÿëäÿsskÿéA’í\X®ß§0æ‰µ“èAdÈáâpÚÓ¤€İúEºkŠÍÿq÷T*óæ§šªÿÙØ
õ?5¼ÿ¿µ¹¾°ÿy´Ğÿ¨úŸ4ú_¨€@"=Eé³Â#ìPÿ¤‘Áıj€Ò	ï>”@3Ôt=ĞLĞo©
Ê„=Gğ“Ñ©¾[ïW¤X ÔZÍöi×¼§Yƒ¡ÌK?tßVŒ/òi¥V+åuåO%

O2H§ë[Ò¹3Wõ»èYîc©ªz¦”tGñ‚ÇŞÃ¾AQÏâ¤-¤k†>WÕPÌÿw{Š¤mà‹¹Ô1Õş{}=fÿµUŞXÄx´°×Š7;n¯¥Í‡ÏÖx«)œ´*§n¡hNÂ›Ã€WšÓïŸ«EW®(ìvê€¾ ‡t¸®×Ëu;Û,|™sÏğL¡3€ ¯g:öd¯•„Cì8uZ;ıµ4ØÈÁ?'‹Çjêv\' QßòBÈG–u&dşùF?6kZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤Òÿo‚”ë à 