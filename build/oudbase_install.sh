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
‹ Ü†Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹â,	.Ñø HÎpÚ…HÃ]~AvNÒòš@èĞínâHÜğƒ#üh¿úÍá_àÿ”û~¿ÿ gfUuWõ ’ %Í f$¡»«²ª²²²²²²2Ïl§ôèS¹\ŞÚØ`ôï&ÿ·\­ñEb•õj­R®¬×6«¬\©ll¬?b÷İ0Lc?0=hŠïZóA¶óó	ßE?Â?“tãï»§Ğ½`ì~ÿê˜<şÕÚŒ9Œ¥º±¾^®mÀø×Ö+[XùÚ’H?óñü‹’À™é÷sYq~	 -ív·ÙÒÜÁxö…Ùµ}Öx¾Æ}Û±|Ÿ5­kà†–°_²öx4r½€­<m¶P¦mZ=Ë³l?ğLß·Xõ«5öee£ÊÌ 8óÆ½Şk_ÚÁ–70îÜ}`-ƒ§m¦M8øØ}×Ûun:ìĞê{›­¸–_`>½3\z÷›@ Àè¸C(İêÚAXziÏôƒ¾éô¬îÓ+ş¦Du«ğÏrl]Ø¾í:‰,òÏv4öF®oqHOfX»ãÙ£€.ëYğOßb¶]s:ã=d¦Ï<+;¬ãv-Ä„X¾lÍIÆÑç0à×Ğ´ÁûV—»³œÛsTœ¾;ØÉwÍ"TŸ¨İç0¬PëÁÈß.•zs|†Ø)qŒùÈâ€Ä­¹+ ‡}TåzWÛğX®å¯Œj¹²ÉÂØ®c¶9`–‡h„<•ªQ©`-™§Ñı¸âˆÑ‚_˜Ùu˜{”5îarÙTêíÍ vè9ëM¶ÃÍÓãÃÃ“ÓæA}é½ò´]ÌÙ=œz†ëõò×Ô€–ÓÅ>Ş½9×„92ì;s0¶ü;t(÷]ë¸½{xP‡ÑÌ5GG­ƒf=rü¢•g3¦Ç@»æÙÀb·ÇÎmøaF0€ıô°İªçŸ5öÚ·€´qSq6µwwNNû­úÒ
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
NG—]#x¤İJ?zÙäá~f(Ÿ¸€ZXfÆşã5t‡u­‡D£KºÖzŸÈ¶ˆÄ#J$lá2^°è ]½?—¥#÷±ı/ÒÍ’0Ö¿×:¦ùÿGÙ•õj¹R­m•+?ªµõGlã^[%ÒÏÜÿwÇòğÜ	£zù÷E7ÿõÚbü&uİÎıNşG3?÷ÿ_Åñ‡_‹ñ„ãÜj4÷[Æ°{Ou >6kµ¬ñ_ßÚRã¿Ğø¯—k‹ø/’“Î‘‚ò†qHÑHf	(wwû-çâ_şËÿ¢½ˆ–]ÓëÚ?ÊkQöp4@ã²ù-<È‘k$ªrÿåB	‚>ŸÉm÷FÑ]~e›a¿c,ß`úıïõµÛğÂ>Ö¡7Ğ ­âUèş»‡•îjÖşš095ÑìÔZ=„öûv0¦†À÷Kú~å™c¡¿,æÑD‚z<€Ü]
Ç¥Iã<ğ¤Ë$#UêôFo-F<5±!dß1°Şø3]0A—\è96ˆòçHì¥¡±)Ñ¨á™,níı5vÜØY£LÏÇ0`{èzr¿~Ù·;d+eã•UÇòÌm†ñ0Âöø®Êä£k)0r¹UI4«XZÀİ®ò‹8L««aŒ‹ÕU–5Â³Ğ¿ÅÅLy€¨€ÙÌ‰ı? «¯z8õoÜA
¤”3Û1Ñ‡õZˆ}
MRFš°‡öÀôŒ/ÑT	^)2tœŠpBOxÏÛ¥Ì—–ƒ0d
7]æ7˜‘ÊíŒß±ïöÿå?ÿh¶±IQ°Qi;?86ıÑ™åAÇlÌÊÇŞÚ¦Ã~kùşU©xVĞéSı~ŸôæÀw1N.sÅİØòæ¨qbaïü*Ç£Øp…|ÑÜIã˜o¨ñ¬Âçq=ÄùulU?Êëó0¬{‰0‘ö•*Š s³`@Ìõ ‹êáãı§ú'
@Ãz~à¶ÿTb¯pŸÚéúÖV—+%¿sµ[JVÆŠıª(V*ÅÊúi¥¶]ır{ãKrEr|‚QUP[å³”¢+ß	FR6*ŞÌ,h"LŸp¾N‰®øÒ›Tø…oö¬µ´†¼*ö/ŞÀßgìåšÅ“7l"<%ì°„vô¡Ãoä=|ÿ”‘zGqFÿäÍÄŠ¦´¢º'õ™­éeˆ~¸{Va¸‹lp–C´ŒèÌ…©;t»Ö4h1œªĞÔ«.¡µœÁöq‰#¦cz½1Í'ªfBUÓ’¢¨å\æ¨;:#šÒW\¬#ŒEÀ”¬ÈûÊ¡3ï‚1­Š.¯]¦UAdÒ«ˆYøŠ:.(y,ò;à0r_™É®ˆöİóàWwŞ‰†é"¶MÄ…ıiˆhpDDÇØ:êÎ·åı?~à§#ñÅãıòÓjL™—Sjä[ü´:ù§é•ÚLÓõªÕfTİİI©6ü8u–§q§)½‹}:Ñ•†v·;°pÔ§Ö}˜¾=İs{´Nn3Š1_ĞQ:,’¹Ü®º4[ïLÍ(`½¹ëP¸í±‹ˆŸã„_Tşi@¹âÙêª`L4¹øL»Òœ‚dÈá†ËÈPº›^zWîU¶"Å1îwV´çÂ k-àj7áàœq+kÏØNüÃ3uœák©òJK“&,§·)—@ú(ñ×B¼à-‘—S%Œ\Eb0'^u	ö—ÅrµXÙ<­”·7jÛå›É#£l”¥D2—Úo ¿dnêqd¸Œ‰%^PMHE0¢÷ŸÂÃòù§ôDHi·RY=ƒÉ ä
©¦›H»JËAT(Á¤²i·‰“Õ—è†>˜,«!ÓÊ†Ëx²ìÔr‰ûÊ¢ÎÈWå4Ñzª·šÖÈÆ/äØZiÎƒg¡ Î'ÿ"2Ù, ô;Ø™ JZp²Y k7©ç8íÎ8ö=ŠfTú¡û¶b|i”O+›Õ‰DPïgÿpƒ4‘‡N)Ö5rb–Öhb±no*,”V,r[F1En2ÇØèê×L³;½Ô´©˜V*ÉnQñôÙ”^n†y”^p60µ¿³Ì¾§ÔFn‹À²ĞAØäÚEAá»„şËğÍ‹É$mYxiùxqë)öv:À^‰êHx´ !òÁ¿9ëYœıã””o¸õ‚ú†SòF¬çÅ9íÜ0‡§9í(!t_¢¿âq•—ñgÕ*F¾¦à;ügA¹}VÊÁ¬,åaŞ”è'úSŸ©EÑcŒÑUß(6ı‘£9ÛóÜ évu HÉ)oø?¯½oŒ®2 A‡’­Ñ_b‹/>ºZò‡äÍÔîX±ï’Ázş(ö Ù*l:ñ/0Àr¶¦€%Äa‘Ùì€¼¬M¤Äc‹é0~_ÒêÎ>#Û² LIâ<ùwó,H¶”$°IÕá¤ŠÕ¦È]AVV¸-JVbM½4EØ½@áúû±9`f—tòäùN£ï0òŒ°ÇóÜdõ§ˆöTÇÍ-ß¬¡ø²ÂğÅÌşn€/Œ¼&"gš¢J‡9îâ^ÕóSº0%ÚkIã¦yİäNóu{¨“—ß°ïÂO§Œp¤ø\ÃËr¢…ß&Âšo-æãÙĞ:£[-v¯dè8“ZM´ˆNİsí¹\·X#fV¸‹DÔO;¨9Ñ¹”>JÌ?¹àºj°ßb^=€®â©U„*G%†…¿Ï,ôİÂVCõª`L«Êªª ¸ë4É±ƒVŠ3F®œSìÊ™'Ï
Åj‹‚MÉÙ@HÎ…)³dZqN:£·REe„¸nx¾Xt¦˜Ë=½
õ«òH•]x~ézo¹Z¯Ş¨
*®¹Š±ğDuìé@”Â:`{¸KÕ¢°éa(Fáñ9é±1,ÇfÒ¨–Y*4Ü–Ôpì·©'©k!2:TÕ”µ:ìáú@øŒ'ˆ©jqhÆ²Ï:Ş]¬q—x
®ÂÂ>òÓaÙB®Ì3ØaTûæ¿´üpxÄ…}A*GEåj„L\H|U…Äc`Š;Ü¯ÊYR9›­¹ÈĞÖ¤wMXëú8*—4¬“ 8a‡ÔÃ‘@s"Î¹¦X3—P—ÂÄğ¹ÜÁbékZœµ`^|SìkÙ‡øÌ±o"¿Ğ1¬8Â›jæÄ>=ô?ãv:˜:¾p[
®„´GE¨8ÒşÚiˆ"œ•uHl»b=bIê-“I6ÕÛÚ˜FnÃø`â9œÀä_¯‰#ş=¡‘UwY™ĞöG4ˆ7T)S°Ê—†øã)Ì.ÎÀSx¹tFWx³ºc´ùĞ”¡Òæ 9-ä¸DÇ
¦no‚",nßtzV×`{J¼õD7 ÿR¨„ÄU}G_XÀ¨âëŞ,‰01		C3tÇ¬agæÔ+óê£Ş=âbûÊÄr?isê FÔ6İaØ”Fë=k]Xx2M«(1Ö3C.qS˜»º[é‹ãì&ÏLK£˜7¤ıÇÖÀ{ÊXï‰´¸†B"-M‰©ØJô-q·%mÔŒHÏÌsİ¾”ÁŒÙc…\¹ßë&Û)öÀ)ÍüÀ…¦¢oD´¢pÖËåÕh=¹æÚt²"³4bßkåq1‰lßåñUa(‡”º4"-(pÃg°•æHÏÖ;×VUÜ)TÍè‰'ÕlœQ“/ÁèñïGON‰e-3cúr—ºè±	Yo–‰g„ªÕCä5¶Ôéºga”|Œ¹¥ö:ågœ(bóªÓÎ¤8§dªw©Z=<7Ø‹P<åAÚqÍ$¡KE„6/qT”…™ÊÚäFNlŠn’JI‚Ä*Mˆ]ÓTKª¼‹K–.“
êºc'àòÉİèçÊîŒÑĞæ2±¬4U$rN$œ†â^Üô„ eáİ †\9Ô!fi'O7Ğ1«=ÆçôOJg÷§2!îäê¨PŒÖjn)|›(Ó˜Š©“Ãô^§òÒ1rWjÄöf÷ZÑÊ…!j@T!:ü#ªp(ÂÓSòæfõ8)(Ò—oDílAoÅÄâ¡‰Ğ©˜ƒd5W¥¬öR¥ò*EúVÀ3¯?¨•êÓ+Å<zUÙ)}<¨*˜S«‚<d7—Ö¿[U*H7­ÌÍ
«¤n÷š»ÏˆøÑml£1m,Æ÷í›§ˆÌÒ<5»º¡B…B? <ğJ“§Ôƒ`Î~_8|·…«J>•
¨ë¼	©GÄ©ıN;5®Õbe~ß9S•&T!ßÓŒ¨»öuÔVW”›²dË2Vmë¯-µ1ó)ãÊu©´0i©¶b(d	eµ y¸ßØ=HÁñÄÙ†[¬DÏo×‚ìôAŠÁòq†$eÂ”ıqSA	=I!ÅÛ}N}~
	”´vJ¦£ûîĞq²›Ö¨(kQÑ>¥5W‰s%3	ıP¶­d¼òÔeœW>˜^9prEßsg«™6-ßE”PÒ?³|[j}\ÇBCm'î>ÎÜ‹öéûŞ‚ùÈù7“ÙÄÄZC¾gD]5º¹ÆæC fV@^êİó˜±k`¾…Í<©±ğIã)$oı§àåHóZ NPmªùĞF\z* {ş	Ÿ¢ş”€¢~­&Û*ê„Ğ¼QÓB@ñpi€"Útp±`iàâš¸é@c!Ò€†º¾IÀÄ(¦aNäUÏ ã#%²ˆy%\íãLÑvÊ1¸?Sº~†¸Æèï ×³¢¢ïú*ŠÖ4zÀu$"tÖKï#UÇTDhª•w'†/Ò¨óiÅ Ÿ¤3;}}œÃkZ¨|Áv'6k–éÛ°Ùåº6šÚBE„áğƒKGÜ¦RkuR,•Û@Ã_ø–şôl /£J¬Iİ‚&XS`ši(¢Êğ)ıºö§<÷s$c1;%˜6
4Ue €Z3åní"˜$Àø·Ù`Š{…î8P £—ß,Àøm6Ğ**~;¡Ño£ó1OšÍUÄ×â‚^4=ˆ»àn"
•ŒàÇAğcë‹€(ü
Kş]]¨¢øNñÂv3!â7w,Ön…ÁMæV¡×k:’’ñR*xx~¥kI´F Ì‘ZÂè[ö‡ÃTª15ı¹TK+^H:³`iˆNal'MùˆÕÕìâÜ_PUTë2—V®‹EÉ
ÚêØy©Hånk‚EPEªç…Ãkû¨´Š®qºá‘kˆ9jˆ¦·4ôl×÷Ñh_Ø	©ÈÙ¸‡Ów
¨¡î#ıQ„sRxKÿ’«tlg•ò¢µÌE³ùê9ü;>[Æ“¨¡­"ŞµXéÁÈß.•°¡F2‡%â‡ ––@âE*å—
Û¹Ü*{Õ’¦üuEàZ}o`‡¶Ç%µ€ÅıñÙĞæÈéíÊ— P·gwğ`>”–)<öá¯ºlìĞm¨Æ–(Kf^còBGÕ(ì{w,åŠ¹gtìoÂ€®ä‹"ÌØ7Ø<hİåå¥a@Ãõz%Q_ÚÛİi´[E údóÛßÿGºùyHO³ûÿ¨nV«Uòÿ±YYøÿxˆ”f@9ï:&ûÿ(×6+rü·¶66aük[›ëÿ‘ÿ‚Œß’9ÚlkôL	 -ív·ÙÒÜÁ†nJÏ×ØS´AE!·‰AmÜ­W¿dm±&­<m¶P¦mZ=ôU€ñÀ}à°Õ¯ÖØ—@nìùÀ‚3oÜë­±6,\?Zº™{£Q!ağ´0Ë€ïq âŒøŞ¬sÔKÓrÄV@- ©#¼3øõ›@à —-(İêÚAXziÏôƒnWğôŠ@MÎ”øg9¶.l\§YäMzE§vÂâFİ'c‡İ ¤.Q£b$D–AxôØ³‚è4?İ F(`È96ğ†÷c ‘:ß!‚~²om´c¿Ú†ÇÊWFyË¨–+› ws` “SÛ¥ë™¹7 (oAÅÌÁoí)LˆK²ÜC‰õ³ä%²7ÑÑéDT:€¡#a½M8A¾3+²NÅCNñ0üŠ«]qıWøìŒ¼tZçxHGã.´Ï”×ó53Yƒ×y"õø’ „	UÌ>˜K»htÉÄJÍ¨àğ°IÙãûô½½Sv÷'»‡d¡\G®ïÛ*_118¡ŒÉ©ÂŞ•v¡â¬_ÓĞ¯içÁñ+i3a ÀDÃ$€JƒB`úÙ½ †€t}1¿U-·Í±ûÕ~M¿ü©4MSÇ¤¶/©ÈW:¬É(PÅáËt˜âÒš2*ÊË êHTü	¨ •»™·e	^ò¼M‡§ktxEY“×U£Xí\7V§n×‡—Éãkâö°
¥ÂNì@c"X¼åø˜ 7]€k¾Lç
7ƒ=œ†0#ƒ;É[|‹ÆÜ¹é7©“ü	ÓÕÂİë¹ˆ‘z>[œ¯÷Ü ÿáH“¡›4X¼‡:¦Èÿåê¦ØÿUá×îÿj•ÚBş˜ôó—şüÑ£}³ÃÛì÷’à»GªğçOğŸÿ÷l ''Çâ'–øŸğç¯cYş,zÿ· 9èĞ2 u¢½ ^Lz|ÔÆŒæÿ±şÿmııÿı»;õs‘RSì2î½Ô1eşoÁ¶?6ÿ×·óÿaÒ}íÿïMğ™ê ²´ Ÿ·@¿R÷L\+–·şèÄ‚ì²Ìòyù(Éã»]e‹Ô$ˆ] º4m¼Ú˜©á1(
wøtßJ„O@ ÑbˆBåwdósóÊpê\9ùÀwãúwx{iî—!4Ú•úòëño^÷·__–Ø«X‹7lYæìtû±(CÑ3êŒÇïŠ2œÕ•µÑë\h–šì³Ô yJ†N<CŸH£‹òöSó*ÙÀĞ&,ÊéEMµÈŒÎbD	Ôø%ò5€‡×r#¾&$†!ÿÒc0©y1Üì¬á#ñ|¶.+š„æîq8¼¡jáZh	üD,B@ë÷dó’@R&cË>{I<Y?¢e¯bg'àóè) ^t*Âe8i…Ñ]§VlÒrVüîêÇú2ı,‹†5ÃY¾(¢à%ívPíFn¤C{=Š!âa<Â®›ã*	,¾dÇ},pƒæô råsÜ]”XîÄƒ
.°fêËLÊÔ¾èk^åyå+^HæÀvi¹p:%sÁ[-Î®d.7¸œ³Ùı´NÅZm23…sFÉİ™œ›OÈ(?°e4"Ñgó,íñ¬vjV-“‚º…XëêËaØÏğ¥Ûço•˜¢ò|‘ò j¯‡ìía”Ë6€™kór“f2êËø¡ËŒU˜,wàzus¸a†t0gáw^øÊç¯Ò ù‘xÆÒ*%¡“Ãªå0OD-!	˜@ûÒ(
Šm”'C‰ŠEÅ­›'“0¥¸gn@1ÒŠ ø7ƒÙI¶[_¾°ÑÆó,Dbq²‡D1¿@ë¯ú²f
V,J;0FÜŸà%ñyÕl²X<XèH8C·yÀò§İÇØ'°^^|—Ã$L‡—jKüñğã6>B†¦w%›Õõa†¦¤	7hŠ­H±<-IÀy±+=4‹:@I%h\}
PÈÀZéÌÒŠüY˜ÜåÏ'šªÿUŞæYÇŒúßõÊúzµ¶Yceÿ³ˆÿò0é×ÿ:Bÿû¯ÿ¼óøNı\¤Ô”î|q¾uL™ÿÕ­­Äü‡_‹ùÿi¡ÿı¸ú_ÍåéOR¬ZİOĞÇUÁêU¹…:øöMøÜÕÁ3©?úŒ±ÇüÒ]½˜;"î¶©Çöa)å2ZØIşyY¾¿5fšü_«ˆóßr­ZÛÚÂø¿[[•Åúÿ‰ÇTœr+HVáÑ¢«ó¸vá‡ªø@ö`†âËuåe;|[o´å–o7ÄÛce›.¿mbˆ‘p÷\ğæ^ÃøğW³İj1~½½½Ÿ{|Ó¹ÄrüşéveıË¯¶+›ë›Û5HÛ_~ óóÙ·Ï+¥»VŸoÓäÿåşOã¿Ö6¶ûÿI‹ûåşG<”Áç*ùgÜ IÔ7@&6`¾’úÃÈé¹9‹ŞŸàûìM»gJCå¾ë(ÏvÿÄşÚV¹R¡û¿µÚâşïC$ŸsßuÜfü7¶ãÿ)ŠSquÌ8ş°ÿ_ß*¯ãıïõry1ÿ$Å¢>İK7Ÿÿë[•êbü"éÁî§ÙÇ£ºµNã¿±±˜ÿ’èî¡›ÏÿZe±ş?LÊˆS5×:Ê“õ•2×ÿ¯Wj›UÿkıßC¤ÇºãÜõ>ÎÂPN—‡Şâd ±?q‚ñ:a ¾¿2¢—"ş×ŸÄwÈ ^=E ˆyŒu÷<sèçrG“oëKø÷ö¹º5BSoñ‚NûäMÈG¦÷?Û`ƒ)†ğ³ÇL)üó;ÿø¹§ôØ´ó­ãæë?¬›‹õÿ!R"xñ=Ôq£ıÿVå¿jmc1ş‘¦¯GSä¿õõÚ:…ş”ñşÿV¹º°ÿx4¯3“øÁì®sî™~à)Ú˜¸ÈÑemlÜÿ˜g²ñãØx¸ö¹Åj¥ãç°°äm•ªQ®Å_ãÇ¬<®yçw+©±¬I‘Abg­©¥Âµ¬0×l6÷XÅ(³_±çG{è˜v¸İw»äLY´Å·,Ö³Ñ=0ïëóV:·Ã[vÌvàçPœ÷:Âs”_âñ©‘RN›‡FÔ»9µ”;Œf®¯Ş©¦©9€å”î QªC)Cä5zV°²,âº`4îå5–Úòrù‚0
æeÀÍÀXj2ğKé?Ï¾`J+
9º½D7™„h;ÁJ*¿w‰w”èìµóYØ÷²ü¤ÂíöR¾•§²Yİáe_´[ÇXğÒ:éÒîäÃ†ÃŒËæE+íöËÃã&l`r#´Ìé›GóÀ´Í^}á¿Y!ãëXö0.a";@”=2Kc±ìvã¹1¨/Ï-Ğxá'<â/ÊÆ	ÉÈƒÜÑíê—{m9ÿùb	üÍ
ïoÏ2Dµ‚‡µK$9NNx±“J!¥¨©áeRAÄÔ2¹"üL+a­ÀSëpÀÒÉÇ^b?é”¾ÿş5Ç:¦È°
&ö[ùïaÒâÒÏC_úùlmıö$ƒÈ
ÂŒÆ€ŠíZÜPØØ=ô›ŠQ)?è›˜[ßÈñ*®ã>hĞİÇ”Œ\É=CF~Ç2¾§õÈdäÁÜ ‡¡í£Óe÷-=ñ¬oĞƒoÿ?Ëå·¹ë…â÷gšç¿ó]ú)MÓÿÔëmssaÿÿ i±ş/ÖÿYoùƒøÁ=ã÷{ë½Ò„yÃ»´¬·ƒ+v>ÆhbÜ­¼{1z\xGBºĞŸkåÀ‰¿b«ğ_ĞÇÅxœıàX
4~ŸöìÅŞ+R Íß@îî™itúìÉV
†#5;^Å®>ùe%wèëšîÑv:Å/3?ËkÕµõµÚÚÆÚæ­Ğ¹{°sÜÚoœ4>¬
Ó‹‡ÃdµJ˜\BlFüİa{şXI·ÿ¼ø§¤»6|~P3—:¦Éğ ì?kòÿ½EöùïşÓÜ&,^ß¾á	àG”Î°v”cŠŠtJ‚ş1Ÿ"­i2Ûš.®aøÆ˜Ä¦JdDyË \Œ:Ä<ŠH&óTèdN•Âä— Ó(Š<ìÊÃ@öÂLëµùWĞÆa'0Ë¡°HÔÓXGéM–Ó¼²Ğ%NŒ¬Ì$×ˆš`Š*ºL äãZKáU5hÑ=ÿ6¹n”ÎşØ
dÖèRS:`=Ï…mû4(Q#:]SãL1;0((M”d€-4oänc¶µïş¸ë²Î(I°èø^	/Ë‰nŠK±
Z»Ÿ—L© }0t²‹¡ÊÚv-³ u³×ÒÅ§UÓF{L*F?›ƒ‰ÀÉˆsĞîèæİ”‘àa†æÇcçÒ@ôDa0?Ë_á>bKl# ‰»ËÌ³(v.ùÉ(°ãĞ³5ºdğ‰!†1æ‘‹Ä8Çvç^!x“Sb3×ñ@tÙ‘{i:_w¬àÒõŞ0N=+È5ÎË‹¿d¹W‚/¿É\¬ºoÃ·rxÆVÑÉã¬»âzvî%‡IÎâz\,Ãi‹fÅ?Àw?<ËÆŠƒñ\ëÕ!š»yÙ‘İKëlÑr•sG·€uFğÜ‘
ÚåtM¯{8Fã T‰úUÀ“`!o»¸ç®ÇƒÀ.b5{M¿IÒå?1¸†çæXÇù¯û„÷ªå2ÿ­o.ä¿‡H¯ZÏwZorÇ–?r1ú4©wDĞê:H ü¿Ü«ç­ƒÖñîÎ›\»µóâx÷äûÓGÍÆI«}úİnãtÿ{î¼ıâÍEêçæÀŸï-’Eº¤Ï`™ÈßğÖÅë˜6ÿám4ÿ×ÉÿçæÖ"şÓƒ$Û¹°\¿OaÌk'ÑƒÈÃÅá´§I»õ‹t×›ÿãî©TæÍO4Uÿ³±ê6jxÿks}aÿó i¡ÿQõ?iô¿P=€
(DzŠÒg-„GØ şI#ƒûÕ ¥Ş}(f¨éz ™ ßR”	{<á'£R}·Ş¯"H± ¨µšíÓ0®y=O³C™—~è¾­_åÓJ­VÊëÊŸJdN×·¤sg®ê)vÑ³ÜÇ64RUõL)éâ-¼‡}ƒ¢ÅI[I×}®ª¡˜ÿî÷IÛÀs©cªı÷úzÌşk«¼±ˆÿğ ia¯ovÜ^K›Ÿ­ñVS8iUNİBÑœ„7‡'®4§ß?W‹®\PØíÔ}Aép\¯—ëv¶Yø2çá™Bg @)^ÏtìÉ$^ÿ+	‡Øqê´vúki°;ƒNÕÔì¸N ¢¾å…,êLÈüó lÖ´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H3¤ÿNŠ	| à 