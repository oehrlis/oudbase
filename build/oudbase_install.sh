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
    echo '# Check OUD_BASE and load if necessary'             >>"${PROFILE}"
    echo 'if [ "${OUD_BASE}" = "" ]; then'                    >>"${PROFILE}"
    echo '  if [ -f "${HOME}/.OUD_BASE" ]; then'              >>"${PROFILE}"
    echo '    . "${HOME}/.OUD_BASE"'                          >>"${PROFILE}"
    echo '  else'                                             >>"${PROFILE}"
    echo '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"' >>"${PROFILE}"
    echo '  fi'                                               >>"${PROFILE}"
    echo 'fi'                                                 >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# define an oudenv alias'                           >>"${PROFILE}"
    echo 'alias oud=". ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"'      >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'                  >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg '# Check OUD_BASE and load if necessary'
    DoMsg 'if [ "${OUD_BASE}" = "" ]; then'
    DoMsg '  if [ -f "${HOME}/.OUD_BASE" ]; then'
    DoMsg '    . "${HOME}/.OUD_BASE"'
    DoMsg '  else'
    DoMsg '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"'
    DoMsg '  fi'
    DoMsg 'fi'
    DoMsg ''
    DoMsg '# define an oudenv alias'
    DoMsg 'alias oud=". ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"'
    DoMsg ''
    DoMsg '# source oud environment'
    DoMsg '. ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'
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
‹ â¹†Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹â,	.Ñø HÎpÚ…HÃ]~AvNÒòš@èĞínâHÜğƒ#üh¿úÍá_àÿ”û~¿ÿ gfUuWõ ’ %Í f$¡»«²ª²²²²²²2Ïl§ôèS¹\ŞÚØ`ôï&ÿ·\­ñEb•õj­R®¬×6«¬\©ll¬?b÷İ0Lc?0=hŠïZóA¶óó	ßE?Â?“tãï»§Ğ½`ì~ÿê˜<şÕÚŒ9Œ¥º±¾^®mÀø×Ö+[XùÚ’H?óñü‹’À™é÷sYq~	 -ív·ÙÒÜÁxö…Ùµ}Öx¾Æ}Û±|Ÿ5­kà†–°_²öx4r½€­<m¶P¦mZ=Ë³l?ğLß·Xõ«5öee£ÊÌ 8óÆ½Şk_ÚÁ–70îÜ}`-ƒ§m¦M8øØ}×Ûun:ìĞê{›­¸–_`>½3\z÷›@ Àè¸C(İêÚAXziÏôƒ¾éô¬îÓ+ş¦Du«ğÏrl]Ø¾í:‰,òÏv4öF®oqHOfX»ãÙ£€.ëYğOßb¶]s:ã=d¦Ï<+;¬ãv-Ä„X¾lÍIÆÑç0à×Ğ´ÁûV—»³œÛsTœ¾;ØÉwÍ"TŸ¨İç0¬PëÁÈß.•zs|†Ø)qŒùÈâ€Ä­¹+ ‡}TåzWÛğX®å¯Œj¹²ÉÂØ®c¶9`–‡h„<•ªQ©`-™§Ñı¸âˆÑ‚_˜Ùu˜{”5îarÙTêíÍ vè9ëM¶ÃÍÓãÃÃ“ÓæA}é½ò´]ÌÙ=œz†ëõò×Ô€–ÓÅ>Ş½9×„92ì;s0¶ü;t(÷]ë¸½{xP‡ÑÌ5GG­ƒf=rü¢•g3¦Ç@»æÙÀb·ÇÎmøaF0€ıô°İªçŸ5öÚ·€´qSq6µwwNNû­úÒ
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
¸„E2·	³³‹"úŠDİVYPe&¨v¤pkV…kEíÆ§—‰éáET”fË*à‘O¼	SÉŒ®q3CfÙ¥÷z[”B‰O3š‹ª¦¢,mìÄv]ï¸Î¹İ‹†q†ub%£vÃ°°âÑóYpTRíp9L#èıÈ·y;‡ÏØ“¬^Oéšt’/Àıô-^tÃ˜&Ôµ×špC…®•Ìw‰>£»PåqÜE½†|N?3`©>MÃ—‚ã¡™LüİÈîfá9ËÂâX`+fq<»µq¶¥ñÓÔI}£â™ŠE-·6(nLœĞùg“^j—g°‰Ûqàb¨œ	%hIÃ´ì3wĞE{=†²-ó)–âÌ-¶øO³Oé¢…ÍP¥Yê’b&“$ÍÈ½!+zé33qúÉLv7\µçîdı«g$¤”F2vdŒŸ9™z‹æ-L½o>¶©í'™Ğø×8Õ¬÷RÇdûïr¹VŞDûïZec½VŞBûïõÍÚÂÿïÃ¤¿ø›¿|ôçí›vØf¿—¬	ß=ú+øS…?ÿàùÏşİl ''Çü•øğç?Ä²üñş¯=ú[Ãs4XÆÀô4 Æ½üã£¶€ñoñ¯GşóÍ‡+ …[¼wÓŒÆ³"ï_ğ¼Ë‹6Ìgk×éZï=úOÅÿø˜û¿ÿ×ÿöïñßÊƒÚ§™´ˆB÷TÇäù¿Q­•×ãó¿¶^^Ìÿ‡H‹ûçşGh‰ÿ9ßıàÊ)º‰‹÷,ğ(º¹'º¸r·@ÊÉ[ ]Ø]T?t(„°x€à¦Á·qX®¡œ]·óÖòRoˆ Ğœ"TŸš#Ô„ü|
Æ*ğ®æŒ`aÁw¦g£yÍíâZÛ¢pÆd[Ámëã”vV‚¶nÀ®¬0²ÁæÜE¡gøöxäõú‚8‰7“_öppvĞ~óú¹fëYãÅÆciòøtlÇonäIÕ”×òˆ]¬’‰o(õ\Ú È§œÕªY÷w{j>òå9:>l¾Ø9QsŒèºQ Àá'h¼"²œ/+U£jTŒu£œÈølÿå„Ì\ÃxÜ"5ãîózÏ¥S:À‰“W1,@’å‰å]=<Å'òà™¸\ç”CbBD]ı^Zz?Sü˜E²N<óÅFã<Ågh3÷³ èp¥^Jdñ$	ìuÉ
:sfR”¢-"ï;ëÈ»P6Š´#4°YÁ\Ì‚Å˜š]?ÊÃæ“¦Ò=§áè…\@Ú7U"£ªGÙÛöáø¡íw8\‰!æƒ-šfô"G~^®SlÅ†Y™@uM!5n|êÅ ks.+t:ğäŒÕ±%É½v}i‹¦`Dòø”¥âÄÜÖZ›ÔjwõiU(ßÜµRA(ÿ¶ñ]CVş¾ae?˜&G-Îİè ŒÊe¹æîqkçäğøûSnDö¢±oP™ö‚š“{"csYçmúWìI,íèää{tn"zÏëtñjïM°Ş°³ŞY15£$xYXğğÅñN«‰
yñ“TòŸ¸¹%·	
Ò˜áOFù{7ÆÔÚ”fØü:Ã²™·Ï³‚±ç°J<`n8¡Pœ2SØÒğcj dŞ"¡ŒÖà(­ê„Ø;C~XŞ«`ft42¸’kÊå;jœ|‹vHç¶ç
m¹‘ğÒ†µÃ³ºÈĞ°‚´®Yq`ÅŒ#^İn|×j"p cüçZ1n	#ÑE¹’‡*– ¡gˆ@ğÌ)Öy}Õ»\ éZCr“+Z "QP$eÉ§uPZÉêòÔ¯f’6jI!$ÄD:8¾xM†Æó 0ÜØE$Y éâ\1ƒ“âI\ÂI5%Œj†=`¼?ZN.
‰œ¼±3ZG*6„1Ç››7ŞÑbQÔJ¦W‘x¬Câ[>˜šÖp\E4ŸO˜“%,¯!ÀÕÒ<Z³ÌÓÃO:¹ÇXkÂ¦’¬ÉMçJ‡!-•Ñé æjN™Oà$¤»XSM3¢Œ»«U¥BbK,X;™„xÜqfË‰_¡¥HG9”O%uƒ+ÚEjU)¤Mv‘¢'áDfP_ŠEoŒînLsYôvsZ»-Í›Æˆ¾îÍV]4M?ĞGğlF.Î±²èï1‰Sy·%Ìï5°‘éÔ­Ñ_%ØÜSo6©m–^)MV\û /Á¢Â¹Ø(0ùÑU‰•´î§4fB÷b ¸¤k€‚íèÛ	4mUV!V?÷pKæSõ©^E‹îú}\wO‚ºÂ›€jK‡”s& ÒŸsÃB®ßç^Ó> yT‚ãÃ0¼À‹2+™vÀËªğ2|Ñ-æxº‰mpfy´Ö§j5œVŒd8bTËãÑò×Üô‡?£¼9·•ÕVJ‚1.Î÷†ğªÄÍ'Å?ä¸4İìn÷øTbÎ}«9	c5%ã¯­.É÷R÷ÍŒ.úˆ[4†ÂS|Ñ·@Kâ7rvX	ù·0„¹0.¥{y*×3;ë””Sé€x®¾
ÁãŒ‘ôu |‘½éÆÅÄˆ·â‘ÿ²0,Ì,ô-6}e)B~!Qš9KÀ8ä'L©8Ò°M¨·Í™(Ã«Nfßk6ØrR¦T^mS³¶õ¼"ëi»½—ÈŞ {×Ôì¤iM8VŒ\E1Yà¸uÏ>1¾C’ÌXåÃ‚aƒÌ,¶¹Ñ-{`ÇqÈƒù=$=eò3Du;¢¤/Ut%@Z£X1ù.ñ˜–òº ›y—„3±õtûr£9B˜'¢ªì}¯tQ¾ôŞ¾fúÈ\ŠÅx­ »= ª'Çí­GÀâúãÛ‚ÜÌy3•´„"Öh°tNÒQ#Ïv‚s¶üEqÃg_+Uü{“~Öğoå÷¤Œ@ÙVl¹á×vNÏ®X	2!–¯Å¿ˆíğ7QÄu!Ÿ±SZ²•mIDçù{d
†0¬^Œ3ôÄîEJg!­—äÍgÁ0ænÓ`;# È¤ù6[ƒœn?Bó"u›9Ë,×·’öÄµÉ;Ézw“ôn%çİ@ÊK9pJ¦ºöh„¡JC‰e#$teâ\®øUDH<’"À§ Ñ“HW_Š®p©×KLÉHìU¥»t×A$ª]ÿfVpY·#‰*ó"„vTºÒµ=q#P-<ƒßy]d:B·Æ5&¨Áª¤`ó¢’®Hå¡Ê¼áëşÛ¡¶!qæ¬“º ‚I=,Ò³cÑ€{ö¢ıĞŒ—ËZŸÇ”•ö47Ø¨Æw¹[âPRG4¹iLÛ0bÒ=T:¶\¢Mí7ÈÜ“;Ìr‡Øi­ô‡¥ÒhY¶ ”º~±sŞ+¢ÂÖr( ‰’PŸ¨‰q²æD¢¬ï[ºC7ÏÚ„à¨ÕØ¾ç*a£•è¤º/›'VoÈ‘T5ÈÌéÊ{|®¥ë1K„3”~D–€xêê'Mé¾"OKÅjâtW!REiºIœ•ü"'ä©¬ùUzN¡˜‹y7×73òÒH¾—?!ï—_ipoÏyïÆ“òi¼<®a™ ^QJÅu	ÅE,¯ª¼HÕ\(ùãÚ‹Õ…R"®¾HÕ]Ì‹±ºGx?çTìÃ+ÿLó¤?ş­ÆB§˜Ğ¹¦œ¾'EÃÌ¶Ø8Ø—‰­CƒUô}5kµY¾+Xê¼~{µMô³Òé¶BÛ!mm/éhÉ«}›U5»İÄ&(pÓNÎõrsjñ“'YmNŞ§%B¿G•]ß¤(í´Ê"mYU÷s6—|"fMr+hùœTnD`[ßİÍº>Bâ‹öÉá>bâ}>du  ı}ö¿×Q!¢BúûX¡ĞHIXH¾¿{v2ÈNÉïcÙ5•’’]{?‡2‘qœŞ¬ğ},¿´¾ŠwC¾eW­áÕìÊûôÒâ6^B¾/.C±åd9­+u}ï¯Ia1Z	åı„"²Sñ"©ŠïoÒÊ¥4Y[œCÖ…2%«™˜ÈÊß§ ¶™ß§eŞ›šŞkÙUn £O46Ò·âQ+€“G¢vòğ¯mh¦˜á	ˆß—†l¬A‘ÚÒĞ>Y‡Ç&qU©^–5ÓËª·~è»Ru?*ŞEè{› .N(5âEd­=·¯S/§~2Ñ¯BÌ‘.±ĞE~%Å„Ç½¹Ûø!DîC“vä°oGó:yŒßvùIÙì¿&±2±RE5*3…âHSTd6Ê»ÊØ›7,&y5öv¡LÊO†EĞ
a[ä¯«…úÊrşû/«d]Ä¢=%ºV"3óL+ÆÒ‡¥ `
K¥×ÕÒr
”÷âlŸPqíÄ©ŒøÅJYœcäS´ÅKï©SñLùüµæ›#¸Fs"h'÷*şË³–ä‰Åoá3=æ–5 oZ÷qnÉïCí>CËJşkîñık)‚®Â›{ì¼<Í2õz6}è†²aŸİã
×PÀ¯ê=à¯Â†‡RQwbzĞ"åu5í€–´B™»|M£ÁsZ‰i¬èTĞßòÂÇğ®€B×ZsbÍ­A±BsjÒ;ºÎ0³ú’ŞåÇ$å;î%å;¶|XëĞÈè½Â0_¥õëñR]ô1­ïoŞÄ¼—Í Ó_cCËt³štÈéÚ´ÕîP<°äe	áâ^Ñs162“Ş”g+EÑŞ”Â
Ë‹W7¢×ŠáÒcZ¿¡6×ëò–]Zğ¿Ã÷­ñAºÜ/qïb¶ÓÓ6á°ĞıÈ–8J©û‰-¸D·j”ØÂF™JXB3Â½"Eõ*}¢ñ(å“õ?æÊ=à:ä+GÛsÉ+0.!ú‚~„>ÙÑˆRÈĞsœÚ-@ ¸…=àv™üt ”5Q½~§Óq¢’…r<s½KÓëŠ1›Ly²8pØ?°ñ$w0 pxÊöÅlãã(ãC~Îù;¥Ú$âbxP3Ë#ÑúDH¨™<“ùt<@æÂæ YÏ{ÈvE_HÅ!éâ^ÂÌÏ{ºêî^ÌxohE^Æâ+ÒÇ–N;5Ë`ëâ>2MåîÈÜ]ÜÛ±.5I;Ë+÷¡ğ
yÚ>9Å¢Ekƒ´m)hàwŞ«•\+†0•„ÅÏ”é–=S
­Ç
ÉÓ«)ÅbæHâdfJ¡	ÖBSŠÎİ*(Í ]ŞúM±ÅI1(É‚"VµKÛIêZ3¯ĞTÅê¡0KM0@•–ûJ3Ã&ŠšR:É/égÓéæ
ùB|ÖIPö©SÖyPü½>v
{V®‘N¦Rªúı±v5/©‹	9RÊİ®N4!UğD"a«C^–:†ó¦¬ÄYF ÕÈ:Ö„†[Ëm+ÖrÛšµÜv¤YÂßñù^e[NGUcÊQñƒZÏº°a‘ >DÖRĞ3ÚZ7”(®`ÈÕPq".+ÄªVüPf9~1Ğâ‚2İ¤Öî²Ğõ¬N_ùI§H¼«£R u‘ÂˆèÙéğ2Ö&å§3³>úÄ˜#¯ş(4{_dŠÛ˜íÇ­ÆI3MsŠâö`hÊ]YGÜ›ÈóiÊyJ^J‚Ï²‚¬ğ€¡Sù,Pq?3*ñÜ®,ºôOÔï§£´‹Wø¥ËŠèz¿¼ f;Û™æSâ£BtÛªãñûˆ\ı¨ÂÈG”0œÂ@„AGq £cª‰¸ ÒDÏ?j>tU¡µÅoò‰&İ¡51XÓÏº‚À%º©ãôƒñ¹h—T¬NÀ¦po—î$ç¸Éõì™¦ 4™O¹Û˜~ÇX45³<÷2¡=Ù§©ÍÒÕÍÒ7IöÛçbùÊlÃl›™]lÔ-¦õ“™›c´³5&µPŒŒLß¿DµÑ$˜Hd	/ºüU«àttÙ5‚wAÚEÚ£—M¡d†ò‰;³©…efì°·A>×z¤;´£›¸©·†‰lÛ‰ &Ü	~Â|'ÓG?‹ÎşÔ½óĞ´sÛëGMÂX÷^ë˜æÿıåVÖ«åJµ¶U®Tü¨ÖÖ±{m•H?sÿ¿ËC½3Fõñï‹
n>şëµÅø?Lêºûüfòÿ½U«ÂøW66+‹ñˆ„ã;°æ~Ëvï©ÀÇf­–5şë[[Jü>şëå…ÿ÷‡HIç@A9C¿ê¤h cIb…»í–sñ/ÿåÑFä´®éuíåµ{8àá%Ùü„'¼äÈ1’û¸ÿbqO}¾’;%Ú;"[y~e“¡v¿c,ß`úıîõµÛ°Â6Ö¡7Ğ ­ÒUèş»‡•îjÖ^şš093ÑìÌZ=„öûv0¦†À÷Kú~åaGşr˜?Ä#Rêñ rw)&ÚrGæÂ“v,ŒÔ¨_Ğ½µñĞÄ†ĞùîÀzGàÏ<tÁ5\r¡åØ Ÿ[ şz–†Æ¦D£†g:qo´÷×Øqcg2=Ã€ì¡ëÉÍïeßî­„WÖË3´³De$ìĞi‹bòÑµ”N¹Üª$šU,-àn¹a4Óêjèã~uU eğ,ôocq1‹{'*`gc§C63b3Èê«ıÀw„é#áÌvLôa»bŸ\“§Ô‚æí¡=0=$ãK4U€WcŠ§"…ĞÖ³†Áv)ó¥gå`™ÀM¹â3òQÙ³ñ;öİş¿üçÿ­Â66É«:6*0mÇâjÁcÓYtìÈÆ¬|Üè­m:ì·–ï_•Úg>Õï÷ióo|ãdÒğ8WÜ%o'6¢ñ¨b<ŠWèÈ]@4ùîu•>÷ë/îÈF¨c«Bı|*¯ÏÂ°ì%NÀDÚWª(‚ÎÍ}0×G€,ª‡4ôŸşéŸ( WõşÀmÿ©Ä^á¦¯Óõ­7¬4.WJ~æj·”¬Œû9tT_¬TŠ•õÓJm»úåöÆ—äŠàø£* êÇ=g)EW¾Œ¤lT
¼™YĞf;>±0ÅŞ^KkÈ«bÿâü}Æ¾QÌ¬Ÿ¼aá1(a‡%4Mğ„6¿‘#äğıSFºÅõ“7+šÒŠbdèšH<ŞøJ€‘†è‡·g¦»Èg9D»ÀˆÎ\˜ºC·kMƒÃ©
M5u­e¶K1Óëi>ñPªš–­'ç:0ß¥‡İH}>¥/®¹XG‹€)Y‘÷Cg¾cZ]^º L«‚I¤W!³ ğu]ĞñXÄwÀaä¾.#’
\«ë»çÁ%®î¼SEl‹ˆûÓÑàˆˆ±"t<ÕïÊû?ü,DG:â‹Çû,ä§Õ˜2/§ÔÈ7øiuòOÓ+µ™¦8U«Í¨4²İO©6ü8u–§q§)½‹}:Ñ•†v·;°pÔ§Ö}˜¾=İs{´Nn3Š1_ĞQ2,’¹Ü®º4[ïLÍ(`½¹ëP¸í±‹ˆŸã„_Tşi@¹âÙêª`L4¹øL»Òœ‚dÈá†ËÈPº›^zWîU¶"Å1îwR´çÂ k-àj7áàœq+KÏÔN¼ÃãFœák©òJK“&,§·)—@ú(ñ×B¼à-‘—S%Œ\Eb0'^u	ö—ÅrµXÙ<­”·7jÛå›É#£l”¥D2—Úo ¿dnêq$ø%ø‰%^PMHE0¢÷ŸÂ“òù¥ôDHi·ÒX=ƒÉ ä
©¦›H»JÇATÈŸù¤²i·	“Õ—è†9>Ÿ,«!ÓÊ†Ëx²ìÔr‰ûŠ¢ÎÈWİ4Ñzª·šÖÈÆ/äØZiÎƒg¡ Î#ÿ"2Ñ, ô;˜™ JZp¢Y k7)ç8íÎ(ö=ŠfRú¡û¶b|i”O+›Õ‰DPßgÿpƒ4‘‡N)Ö5rb–Ödb±nŠ*,”6,r[D1n2ÇØèêÇL³;½Ô´©˜V*ÉnQñôÙ”^n†y”^p60µ¿³Ì>NöùB:š\»((|W€pÁ¾y1™$¢‚¡a/-o"n*Á!ÅŞNØÂ+B 	¶$DA>ã3'b½Šƒtœ’ò7Pßp*PŞˆ€•â¼8§æğ!§%ä€îKôW<îšò2ş¬š˜È×|ƒÿŒ!(7°ÏJ9˜•¥\` Ì›ıDß@ê3µ(zì ƒ1ºêÅÆS ?r4¥ r{` Í® )9åÿrµ÷ÑU$èP²5úKlñåÀGW+ş¼Ú+ö]2XÏÅ¾  […ÍC'şEÄ“'_II°„8Ì3²!›—¥‰”xlq!ÆãËYİÙgd[ä‘éHœ'ÿN¥É’’6©:œT±Ú´ ™+ÈÊ
·ABÉJ¬©·ƒ¦»7(\_`?6Ìì’N<_iôF¾¶x›¬¾ãÑ¾ƒê¸¹ãš5WV®˜İp…‘—Dä<Ó‘Aép"Ç¯¸Ã«zŞ`J¦D{,iÜ4¯Û¯iŞcnuòòö]øiâ”Ÿkhl-'Zøm"Ü¡ùÖb>Í ]¡!²j·{ı CÇ™„Ô:h¢g­Ô}1×~àq‹ñqû5bæy`…»H$Aı´ƒšKés Äù“®«û-æÕh*E¨bTbXøûÌBßl5T¯
Æ”±ª¬ª
Š»N“›1h°ğ1rİœb×Í<yV(VSl®H—Cr.L™%ÓŠsÒyü½**#ÄuÃëôíÀ¢3Å\îéU¨×X•GZ¨ìÂÓğK×{ËÕÊhz¯*¨¸æJ(ÆÂÕ±?¦Qrëíá:.U‹fÀ¦‡¡…wF;ä¤ÃÄ<²_Ø£Zf©Ğp[RÃ=°ß¦¤®Q„¸èPUSÖè°ƒëá3 ¦ªÅ¡Ë>ëxc¼ò¼Æ¯tã)¸
ûÈO‡e¹2Ï`‡aP=ì{˜ÿÒğÃeàö©•_¨2q!ñU"9€)îp¿
gIål:v´æ"C[“Ü5aúêã¨\ZĞ°N‚4B4â„}R;÷‰I.3—P—ÂÄğ¹Ü/=–>°¦ÅYæÅ1ÅX•}ˆ¿ÁŒûV!ÒùÃŠ#|±I fAìÓÃÀ^ñ3nyÜ.0aKÁ•°Öã¨UÂGÚ_›"í Q„³Ò ‰mW¬çQ,9½¥b2É¡z[ÓÈmL<ç‘˜œAâë5q$Ã£'$²
á."³Úşˆñ†j"e
VùÒaü"…9ÀÅ™à x
/—Òè
ï¡ÑqVwŒ6š2TÚ §…—x±ÚÔíMĞ¢A„Å¤àñ]ƒí)ñ–İ€üK¡W5ô{a£Š¯_xM#ÂÄ$$ÍĞ«†‰ì êÊ}‰yõQïFq±}eb¹Ÿ¤9u€#j›î0lJ£õµ.,<™¦U”ë™…Æ!—¸)È]]­ôÅñv“g¦¥QÌÒşckà=å¬wDZ\C!‘–&ÄTl%ú–¸(’6jF¤gæ¹nß Ê`Æì±B.‚\ƒïu“í{à”f~à‹BSÑ7"ZQ8ëåòj´„\sm:Y‘Yš±ˆï‰µò¸xÄƒ¶ïòøŠ0”CÊ]‘¸Îá3ØÊ
s¤gëk«*îªfôD‹“ê2Î¨É—Xôx„÷#'§Ä²–™1}¹K]ôØ„¬7ËÄ3BÕê!ò[êtİ³°Ê>ÆÜR{r‚Œ3N	±yÕigRŒS2ÕÇ»T­ìE(ò Í¸f’Ğ¥"Â›—8*ÊÂLemr#'6E7ÉN¥$Ab•&Ä®iª%UŞÅ%K—I…ˆu)À8É3$w£Ÿ»3FS@W;¬4U$rN$œ†â^Üô„ eáİ †\9Ô!fi'O7Ğ1«=ÆçôOJg÷§2!îäê¨PŒÖjn)|›(Ó˜Š©“Ãô^§òÒ1rWjÄöf÷ZÑÊ…!j@T!:û#ªp(ÂÓSòædõ8)(Ò—oDílAoÅÄâ¡‰Ğ©˜ƒd5W¥¬öR¥ò*EúVÀ3¯?¨•êÓ+Å<zUÙ)}<¨*˜S«‚<d7—Ö¿[U*H7­ÌÍ
«¤n÷š»ÏˆøÑml£1m,Æïí›§ˆÌÒ<5»º¡B…B? <ğJ“§Ôƒ`Î~_8|·…«J>•
¨ë¼	©GÄ©ıN;5®Õbe~ß9S•&T!ßÓŒ¨»öuÔVW”›²dË2Vmë¯-µ1ó)ãÊu©´0i©¶b(d	eµ y¸ßØ=HÁñÄÙ†[¬DÏo×‚ìôAŠÁòq†$eÂ”ëñqSA	=I!ÅÛ}N}~
	”´vJ¦£GØÔq²›Ö¨(kQÑ>¥5W‰s#3	ıP¶­d¼òÔeœW>˜^9prEßsg«™6-ßE”PÒ?³|[j}\ÇBCm'î>ÎÜ‹öéûŞ‚ùÈù7“ÙÄÄZCCDM5º±Ææõpñ: òRíÇŒ]ó-læy8÷CòÄÉ+ô)x9Ò\ ¨TÛj÷µ—×şéÒ|â‚¾¨?Åá¸¨_«‰Ç¶‰:!4oÔ´PÜy H§6\ÌYy¸¸&n:Ğ˜Kó4 ¡®o01Ši˜yÕ3èøH‰,b^	WÛ8S´rîÃÏ”®Ÿ!®1úÆ;Èõ¬¨§è»~€Š¢5p‰ƒõÒûH`Õ1Ú…jGåİ‰á‹4êüFZ`ñ Ä')äÌN_çğš*_°İ‰Íšeú6lv¹®æŸ¶Pa8üàÒ·©ÔBKå6Ğğ¾¥'=ÀË¨kR· 	Ö˜fŠ¨2üFJ¿.Bıé Ïı\'ÉXÌE	¥MU ÖŒ@¹[«f	0şm6˜â^¡;Àèå30~›´J†J£ßNhôÛè|ÌÄ“f³gñµ¸ Mâ.¸›ˆB¥"øqFüÁú" ¿Â†Vª(¾B¼°İLˆøÃŠµ[ap“¹Uèõ–¤¤ó”
_©Á­3E¤†0ú=Äá0…jLM.•ÄRÅŠ’Î,X¢SÛIS¾#bu5»87äTÕºÌ%†•ëbQ²‚ö†:v^*R¹Ûš`Têy!ÆğZ„Å>*­¢kœnxäb¢…)Âí=Ûõ}4ÚvBD*dr6îátÁj¨ûHÔáœŞÒ¿ä*ÁY¥¼h-sÑ,D¾zÿÏ–ñ¤*dh«ˆw-VúA0ò·K%l¨Ñ£L€ça‰ø!ˆ¥%8ÇA‘Jù¥Âv.·Ê^µ¤©'AQ ¸VßØ¡íq‰g-`q|6´¹#bz{ƒò%(T ÄíÙ<˜ÏÁ¥e
}ø«.;t[ª1‚%Ê’™×˜¼ĞQ5ÊûŞK¹bîû›0 £+9Ä¢3ö6Zwyyi˜Ğp½^ITç—övwZíV€>Ùüö÷ÿÑ€n~ŞÒÓìş?ª›ÕêÂÿÇC¦4Êy×1ÙÿG¹¶YÙã¿µµ±	ã_ÛÚ\_øÿxˆôød<ø–ÌÑf[£gJ mi·»Í–æ6tSÒx¾Æ¢*
¹Mjáh½ú%k‹5iåi³]€2mÓê¡¯Œì‡­~µÆ¾rcÏfœyã^oµaáúÑòĞõÈÜ
	ƒ§í„Y|oŒgÄ÷v`£^š–#¶ÂhMáÁ—¨ß¸lAéV×ÂÒK{¦ìp»‚§W|šhrn¤dÀ<Ë±uaã:•È"?ğlZĞ:µ7ê>;ì u‰#!²Â£ÇD§ùé0BCÎi°ç0„¸ˆ„Ôùô“}k£ûÕ6<V¾2Ê[Fµ\Ù¹˜™œÚ.]ÏÌ½Ey*f~[hOaB\’åJ¨Ÿ%ÿ+‘½ŒL'¢Ò	ë hÂùšğY‘u*r‚ˆ‡á_P\íŠë¿ÂfäòÒ:ÇC:²'p¡}¦¼¯™É¼Î©Ç—!L¨böÁ\ÚE£ãH&VjF= ‡‡M
Ìß§ïíòh”»ÿØ8Ù=<0 å:r}ßVaøŠ‰‰À	eL^Hö®´gıš†~M;_I#˜	k &ê&TÓÏî0¤ë‹ù­j¹mİ¯öChúåO¥iš:&µ}IE¾ÒaõLF*_¦Ã—Ö”QQXn PG¢âO@­ÜÍ¼h,Kğ’çm
<<]£Ã+Êš¼v¬Åjçº±:u»>¼ÄHîS·‡Ux(vbÁâ-ÇÇ¸éò T\óe:W¸ìá4„YÜIŞâóèõÆÜ¹é7©“ü	ÓÓÂİë¹ˆ‘x>[œ¯+Ú ÿáH“¡›4X¼‡:¦Èÿåê¦ØÿUá×îÿj•ÚBş˜ôó—şüÑ£}³ÃÛì÷’à»GªğçOğŸÿ÷l ''Çâ'–øŸğç¯cYş,zÿ· 9èĞ2 u¢½ ^Lz|ÔÆŒæÿ±şÿmııÿı»;õs‘RSì2î½Ô1eşoÁ¶?6ÿ×·óÿaÒ}íÿïMğ™ê ²´ Ÿ·@¿R÷L\+–·şèÄ‚ì²Ìòyé(Éã»]e‹Ô$ˆ] º4m¼Ú˜©á1(
wøtßJ„O@ Qbˆ2åwdósóÊpê\9ùÀwãúwx{iî—ñ(Ú•úòëño^÷·__–Ø«X<ˆ7lYæìtûu=RNôÅŒ‡:âñ{¢guåFmôz Eê™¥&û,5h–’¡ÏûÁ¨¢¼ıÔ¼J†A60´	‹rºgQ“c-2ãŸ„³‘d5ˆ|àáµÜˆ†¯	‰aÈ¯ô€Fj^79+BøH<Ÿ­ËŠ&¡¹{o¨Z¸Z?‹LĞú=Ù¼d †”ÉØ’Å^ÏCGÖhÙ«ØÙ	ø|'z
ˆŠpNZaDt×©›´œ¿»ú±¾L?‹Ä¢aÍp–ïŠ aI»T;…‘ÛèĞ^bF†xLD¿æÅ—ì¸®sĞœ@®|‚;‹ƒrà ËxğAÁ–ÃL}™I™ÚÑ×}Í«!¯|ÅëÉØ.-N§d.x«åÂÙ•Ì…áÆ–sa6»ŸÖ©X«íAf¦pÎ(¹;“só	å¶¢¡ŒF$úle¢=ÕNÍªeRP²£k½Q}9û¾tûü­SP~ƒ/Ò@B¾Tíáõ½=Œr·Ã0ó`mş@nÒÃLF}?t™±
“¥ã\¯n7Ìæ,üîq ƒÀ_ùüU4 ²ÏXZ%£$4prXµæ‰¨%d"!bh_EA±òdb(qC±¨¸u³âd¦÷¬ÑÍ (FZÿf0"2	âÂvëËv"tW`…¨"C,Nã(ÆñhıU_ÖLÁŠEiÆˆá¼$>¯šM‹+Cc )gè6X¾ãÔ£ûûÖË‹ïÒ`˜„éĞàRm‰?~ÜÆÀGhÃĞô®d³º>ÌÓĞ”ô#áíQ±)–§Å"	8/v¥‡fñB(©«O
X+YZ‘?“»³üùÄSõ¿ªÑÛ<ë˜Qÿ»^Y_¯Ö6k¬\ÙØXßZè$}âú_GèÿõŸwß©Ÿ‹”šÒ/Î·)ó¿ºµ•˜ÿğk1ÿ"-ô¿Wÿ«¹<ıIªU«û	Úà¸*X½*·Pß¾	Ÿ»:x&õâÇSŸ1ö˜ßâ@z£«sGÄİ6õØ>,¥\C;Éÿ#/Ë÷·ÆL“ÿkqş[®Uk[[ÿwk«²Xÿ"ñøŠsCnÉ*<ÚBtu×.üPÈÃŞÌP|¹®¼l‡okâmƒ¶Üòí†x{¬lÓå·M1îşƒ«ŞbÃÜk¿şj¶[-Æ¯··÷so:—Xß?İ®¬ùÕves}s»iûË¯à`~>ûöy¥t×êó­cšü¿±¡Üÿ)cüçÚÆÖbÿÿ iqÿã£Üÿˆ‡2ø\%ÿŒ é‚úâÈÄÌWR9=7gÑûÓ¼sŸ½i÷L	c¨ÜwåÙîÿ‚Ø_Û*W*tÿ·V[Üÿ}ˆ„ásî»ÛŒÿÆÖbü"Eq*î¯Çöÿë[åu¼ÿ½^./æÿƒ¤XÔ§{©ãæó}«R]ŒÿC$=0ØıÔ1ûøoT·Öiü76óÿAR"İ=Ôqóù_«,Öÿ‡IqªæZGy²ş¯RæúÿõJmcs£Šãâm¡ÿ{ˆôXw¼€»ŞçÂyCŠÂé²óĞ[œ4ö'N0^'Ä÷WFôRÄÿzásƒøÄ«Ç±1q îgı\î¨qòm}	ÿŞ^"W·Fhê-^ĞiŸ¼)ùÈôşgl0Å~ö˜‚)…~ç?÷”›v¾uÜ|ı‡U`s±ş?DJ/¾‡:n´ÿß*£üW­m,Æÿ!Ò´àÕó¨cŠü·¾^[Çñ¯ĞŸ2Şÿß*Wö’æuf?˜İuÎ=Ó¼1E9º¬ÍƒûóL6~×>×³X­tü–¼-£R5ÊµØñkü˜•ÇU"âün%5–5)2Hì¬5õ T¸–æšÍæ«eö+öühÓÎ·ûn—œ)‹¶ø–Åz6ºæİc}~ÂJçvxËÙüŠó^GxòK<>5RÊÉaóĞˆz7§–r‡ÑÌõÁ;Õ45Ç°œÒ Ju(eˆ¼FÏ
V–E\ŒÆ½¼Æò PûÃS^._ FaÀ¼L ¸9@ KM~)}áçÙLiE!G·—èæ#“m'X‰Cå÷.ñİ‚½v¾ ûş@–ŸT¸İŞSÊW£òA6«;¼ì‹vë^Zg ]Ú|Øp˜ñaÙ¼he£İ~yxÜ„Lnäaƒ–9}óh˜¶Ù«/ü7Ë1d|ËÆ%LdÇˆ²Gfi,–=Ân<7•à%â¹:£/"ü¤‚GüE¹Ã8!¹c;º]ır¯-ç?C,¿YáıãY†¨Vğ°–c‰$Ç)Â	/ácR)¤• 5¼L*ˆ˜:P&W„Ÿi¥"¬Õxj½®X:ùØKì'Ò÷À¿æXÇùVÁÄşok!ÿ=LZ\úyèK?Ÿ­­ßdYA˜ÑP±]‹Û 
»‡¾qS1*å½qsë9^¥ÀuÜºû˜’‘+¹gÈÈï¸SÆ÷´^™Œ<˜ô0´}tºì¾¥'>€õzğíág¹ü6w½PüşLSâüw¾K?¥iúŸZbı¯mn.ìÿ$-ÖÿÅú?ë-_`?¸gü~ïb½Wš0ox—–õvpÅÎÇMŒ»•wÏ1 !FïHHús­8ñWlş« ú¸¸S KÆï³bÀ½ØÛcE
´ùÈİ=3NŸ=yÂJÁp¤fÇ«ØÕ'¿¬äî}]Ã=ÚNÇ£øeæÇCby­º¶¾V[ÛXÛ¼:wv[û­ƒ“Æ§‚Uazñp˜¬V	“«³âOˆÍˆ¿› ìc¯Ã+éöŸ—ÿ”t×†ÏjæRÇ4ùo„ıg­Bş¿·Èşo!ÿİšÛ„ÅëÛ7<üˆÒÖrLQ‘Î@@IĞ?æS¤5#Mf[ÓÅ5ß“ØT‰L‚(o€‹Q@‡€˜GÉd
Ì©R˜üòdEñ‚‡]yÈ^ø€i½6ÿ
Ú8ìf9‰zë¨"½ÉršWºÄ‰‘•™äQLQE—	€¼aœcCk)¼ª-ºçß&×ÒÙ[¡“Œ‚Á]Š`J¬ç¹°‚£mŸ%ŠbD§kjœ)f¥‰’°…æÜmÌ¶öİw]Ö%é ß+áe9ÑMño)VA‹c—àó’)¤†Nv1Tùa@Û®ev ®`öZº¢ø´jÚh©BÅèÇcs08qÎ Úİ²›2<ÌĞü¸Àqì\ˆ(ægù+ÜGl‰m$qw™yÅÎ%?evz¶F—>1Ä0Æ<r‘‚çØîÜ+d orJlæ:#.;r/M'ğë\ºŞ[Æ©g¹Æy`yñ—,÷Jğå7¹“«‘U÷m˜àVÏØê":Ùsœ€uW\ÏÎ½„â0ÉÂY\‹e8mÑ¬øøî‡gÙØBq0k½³:Ds7/["²{iíáQ Z®r`îè°Î;RÁA»œ®éuÇÁhÔ*Q¿
x,äa÷ÜõáxØE¬F óc¯é7Iºü'×ğüÑë˜"ÿáuŸğşOµ\¦ó¿õÍ…ü÷éUëàùîAëMîØòG.FŸ&õZ]	„ÿ—{õ¼uĞ:Şİy“k·v^ï|úâ¨Ù8iµO¿ÛmœîÏı·_¡¹HıÜøó½E²H÷‘ôù,ùŞº˜cÓæ?¼æÿ:ùÿÜÜZÄzd;–ƒë÷)Œybí$zr¸8œö4)àc·~‘îšbóÜ=•Ê¼ù©€¦ê6¶BıÏFïÿom®/ì$-ô?ªş'ş* P…HOQú¬…ğÈûÔ?idp¿ tÂ»%Ğ5İA4ô[ª‚2aÏ‘'üd´AªïÖûU) õÃ£ÖA³}Æ5¯çiÖ`(óÒİ·ãK£|Z©ÕJy]ùS‰‚Â“Òéú–tîÌU=Å.z–ûãØ†Fªª)%İQ¼à±…÷°oPÔ³8iK éš¡ÏU5óÿÃİã"iøb.uLµÿ^_Ùm•7ñ$-ìµâÍÛkióá³5Şj
'­Ê©[(š“ğæ0àÁ•æôûçjÑ•ë
»: /è!®ÁƒëõrİÎ6_æÜ3<Sèà(Åë™ı#™Äë_`%á;NÖN-vrğÏÉâ±š:ƒ×	@Ô·¼ò‘åÂB	™¾äÍši‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘iBúÿ[z à 