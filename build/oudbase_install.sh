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
        DoMsg "INFO : save customization for $i (${!variable})"
        #sed -i -e "/$i=/{s/.*/$i=${!variable}/;:a;n;:ba;q}" -e "a$i=${!variable}" ${ETC_CORE}/${OUD_CORE_CONFIG}
        
        grep -q "^$i" ${ETC_CORE}/${OUD_CORE_CONFIG} && \
            sed -i "s/^$i.*/$i={!variable}/" ${ETC_CORE}/${OUD_CORE_CONFIG} || \
            echo "$i={!variable}" >> ${ETC_CORE}/${OUD_CORE_CONFIG}

        #sed -i "/<INSTALL_CUSTOMIZATION>/a $i=${!variable}" \
        #${ETC_CORE}/${OUD_CORE_CONFIG} && DoMsg "INFO : save customization for $i (${!variable})"
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
‹ Úé†Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹â,	.Ñø HÎpÚ…HÃ]~AvNÒòš@èĞínâHÜğƒ#üh¿úÍá_àÿ”û~¿ÿ gfUuWõ ’ %Í f$¡»«²ª²²²²²²2Ïl§ôèS¹\ŞÚØ`ôï&ÿ·\­ñEb•õj­R®¬×6«¬\©ll¬?b÷İ0Lc?0=hŠïZóA¶óó	ßE?Â?“tãï»§Ğ½`ì~ÿê˜<şÕÚŒ9Œ¥º±¾^®mÀø×Ö+[XùÚ’H?óñü‹’À™é÷sYq~	 -ív·ÙÒÜÁxö…Ùµ}Öx¾Æ}Û±|Ÿ5­kà†–°_²öx4r½€­<m¶P¦mZ=Ë³l?ğLß·Xõ«5öee£ÊÌ 8óÆ½Şk_ÚÁ–70îÜ}`-ƒ§m¦M8øØ}×Ûun:ìĞê{›­¸–_`>½3\z÷›@ Àè¸C(İêÚAXziÏôƒ¾éô¬îÓ+ş¦Du«ğÏrl]Ø¾í:‰,òÏv4öF®oqHOfX»ãÙ£€.ëYğOßb¶]s:ã=d¦Ï<+;¬ãv-Ä„X¾lÍIÆÑç0à×Ğ´ÁûV—»³œÛsTœ¾;ØÉwÍ"TŸ¨İç0¬PëÁÈß.•zs|†Ø)qŒùÈâ€Ä­¹+ ‡}TåzWÛğX®å¯Œj¹²ÉÂØ®c¶9`–‡h„<•ªQ©`-™§Ñı¸âˆÑ‚_˜Ùu˜{”5îarÙTêíÍ vè9ëM¶ÃÍÓãÃÃ“ÓæA}é½ò´]ÌÙ=œz†ëõò×Ô€–ÓÅ>Ş½9×„92ì;s0¶ü;t(÷]ë¸½{xP‡ÑÌ5GG­ƒf=rü¢•g3¦Ç@»æÙÀb·ÇÎmøaF0€ıô°İªçŸ5öÚ·€´qSq6µwwNNû­úÒ
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
NG—]#x¤İJ?zÙäá~f(Ÿ¸€ZXfÆşã5t‡u­‡D£KºÖzŸÈ¶ˆÄ#J$lá2^°è ]½?—¥#÷±ı/ÒÍ’0Ö¿×:¦ùÿGÙ•õj¹R­m•+?ªµõGlã^[%ÒÏÜÿwÇòğÜ	£zù÷E7ÿõÚbü&uİÎıNşG3­²±YÛZ¯ÂøÃ¯Åø?HÂñ?n5šû-cØ½§: ›µZÖø¯om…ñ_äø¯—7ñ_$=&#åã*¢‘ÌPîîö[ÎÅ¿ü—ÿE{7-»¦×µ”×¢ìáh€ÆdóZx#×HTåşË…}>“;5Úî¢»2üÊ6Ã~ÇY¾Áôûßëk·á…;}¬Co 9@[Å«Ğı=v+9ÜÕ¬=ı5arj¢Ù©;´{í÷í`Lï—ôıÊ3ÇBYÌ¢‰õx ¹»K“Æy áI?–IFªÔ/èŞZŒxjbCÈ¾c`½#ğgº`‚.¹ĞslåÏ-Ø=KCcS¢QÃ3YÜ4Úûkì¸±³F™aÀöĞõä~ı²owÈVÊÆ+«å™Úãa„íñ]•ÉG×R:aär«’hV±8´€»]å#p˜VWÃ««-k„g¡‹‹™<ò Q;;²™û@V_õpêŞ¸ƒ8 H)g¶c¢ëµûš ¥Œ4aíé!_¢©¼Sdè8á(„ğ5¶K™/=;,`ÈnºÌn0#•=Û¿cßíÿËşĞ*lc“¢*`£Óv,~,plú£3ËƒÙ˜•½µM‡ıÖòı«R;ğ¬ Ó§úı>é+Ìïbœ\çŠ»±åÍQãÄÂŞù1UG±á
ù¢¸“Æ1ßPãY…Ïãzˆ;òêØª8~:•×çaXö'`"í+UAçfÁ€>˜ë#@ÕÃÇúOÿôO€†õüÀmÿ©Ä^á>µÓõ­7¬4.WJ~æj·”¬Œû9TQ¬TŠ•õÓJm»úåöÆ—äŠäø£ª ¶Ê=g)EW¾Œ¤lT
¼™YĞD˜>á|œ=\ñ¥7©ğßìYkiyUì_¼¿ÏØ7Ê5‹'oØDxJØa	í$è	B†ßÈzøş)#õâŒşÉ›‰MiE12tO$ê3[	0ÒËıp÷¬Â4pÙà,‡hÑ™Swèv­iĞb8U¡©W]Bk9ƒíãGLÇôzcšO<TÍ„ª¦%EQË¹Ì7>PwtF4¥/®¹XG‹€)Y‘÷•CgŞcZ]^º M«‚É¤W!³ ğu]PòXäwÀaä¾2#’
\í»çÁ%®î¼ÓEl›ˆûÓÑàˆˆ±#t<ÕoËûüÀOG:â‹Çû-ä§Õ˜2/§ÔÈ·øiuòOÓ+µ™¦ëU«Í¨4º»“Rmøqê,OãNSz+ût¢+ínw`á¨O­û>0}{ºçöhÜfc>¾> £tX$s¹]ui¶Ş™$šQÀ(zr×¡pÛb=>Ç	¿¨üÓ€rÅ³ÕUÁ˜hrñ™v%¤9É-Â—‘¡t7½ô*®Ü«lEŠcÜï¬hÏ…; ÖZÀ7ÔnÂ%À9ãVÖ<±+œø‡gê8Ã×Rå;”–&MXNoR.ôQâ¯…xÁ[".?¦J¸ŠÄ` 3N¼ê,ì/‹åj±²yZ)ooÔ¶Ë7“G*FÙ(K‰d.µß@~É,ÜÔãÈp'K¼ šŠ`Dî%>…‡7äóO!é‰Òn¥²z“AÈRM7‘v•–ƒ¨P<ƒIeÓn'«/Ñ'
|0XVC¦•—ñdÙ©å÷•E‘¯Êi¢õTo5­‘3Œ_È±µÒœÏBA"œO&şEd²Y@éw°3A•´àd³ ÖnRÏpÚqì{Í¨ôC÷mÅøÒ(ŸV6«!‰ ŞÏşá i"R¬käÄ,%¬ÑÄb;ÜŞ*TX(!­Xä¶ŒbŠÜd°ÑÕ¯™fwz©iS1­T’Ü¢âé³)½Üó(½àl`jg™}O©Ü/d¡ƒ°Éµ‹‚Âwü—á›“I"*Ú²ğÒòñ& âÖRìít€-¼Õ!ğh;AB$äƒ1~s"Ö³8ûÇ))ßpëõ§åX+Î‹sÚ¹aOrÚQBè¾DÅã.*/ãÏªUŒ|MÁwøÏ‚rû¬”ƒYYÊÂ¼)ÑOô¦>S‹¢Ç0£«¾1Pl<ú#Gs
 ·ç¹Òíê ’SŞğ0 _{ß]e@‚%[£¿Ä_|tµäÉ›©İ±bß%ƒõüQì ²UØ<tâ_`€ålMKˆÃ<#²ÙyY›H‰ÇÒaü0¾¤Õ}F¶eA™’ÄyòïæY*l!)I`“ªÃI«M»‚¬¬p[$”¬Äšz;hŠ°{3€ÂõöcsÀÌ.éäÉóFßaäaç¹Éê;Ní;¨›[0¾YCñe…á‹™ıİ  _yMDÎ4D•'rÜÅ¼ªç¦taJ´×’ÆMóºÉæ=êöP'/¿aß…Ÿ6NáHñ¹†—-äD¿M„;4ßZÌÇ³ +t F·Zì^?ÈĞq&!µšhº/æÚ<r1>¸ n?°FÌ<¬p‰$¨ŸvPs¢s)}”˜!rÁuÕ`¿Å¼z ]ÅS«UJŸYè»…­†êUÁ˜2V•UUAq×i’c3­7<fŒ\9§Ø•3OŠÕ›,’³œSfÉ´âœt?Fo¥ŠÊqİğ:};°èL1—{zê5Vå‘*»ğ4üÒõŞrµ2^½QT\s%cá‰êØÓ(…uÀöp—ªE3`ÓÃPŒÂ;ãrÒcbY/Ì¤Q-³Th¸-©áØoSOR×(Bdt¨ª)ktØÃõğOSÕâĞŒeŸu¼1º<Xã.ğ\……}ä§Ã²…\™g°Ã0¨&ö=Ìiøá2ğˆû‚TŠÊ/Ô™¸øª
ˆÇÀw¸_•³¤r6;Zs‘¡­Iîš°ÖõqT.-hX'A!qÂ>©‡=#æDœ=sM±f.¡.…‰á1r¹‚ÅÒÖ´8kÁ¼ø2¦Ø×²ñ7˜1bß*D:¡cXq„/6	ÔÌ1ˆ}zè+~Æít0u|á¶\	h=ŠP%p¤ıµ)ÒE8+êØvÅzÅ’Ô[*&“lª·µ1Ü†ñÁÄs9É,¾^G2ü7zB#«î²$2;¡ího¨&R¦`•/ñÆ/R˜\œ	€§ğré ®ğguÇhó¡)C¥ÍrZÈq‰LİŞ-DXÜ¾éô¬®Áö”xë‰n@ş¥P	‰«ú¾°€QÅ×/¼Yab†fèYÃÎÌ©W<æÕG½{ÅÅö•‰1ä~ÒæÔ.Œ¨mºÃ°)Ö{Öº°ğdšVQb¬g‡\:â¦0wu·ÒÇØM™–F1oHû­÷”?°Şiq…DZšS±•è[ânKÚ¨‘™çº}(ƒ³Ç
¹r¾×M¶SìSšù/
MEßˆhEá ¬—Ë«ÑzrÍµédEfi2Ä*¾'ÖÊãb6Ø¾Ëã«ÂP);tiDZPà:‡Ï`++Ì‘¬w6®­ª¸S ¨šÑ-NªØ8£&_‚ÑãŞœËZfÆôå.uÑc²Ş,ÏU«‡Èkl©ÓuÏÂ(ø?rKíuÊ	2Î8Q$<ÄæU§Iq0NÉTïRµzxn°¡xÊƒ´ãšIB—Š#l^â¨(3•µÉœØ<İ$;•’‰Uš»¦©–Ty—,]&":Ô1tÇNÀå’»ÑÏ•İ£) ÍebYiªH,äœH8Å½¸é	5@ÊÂ»A¹r¨CÌÒN(n cV{Œ-ÎéŸ”Î"î/NeBÜÉÕ=;Q ­ÔÜRø6Q¦-,0S'‡é½N=å¥cä®ÔˆíÍîµ¢+”CÔ€¨Bt
øGTàP„§§äÍÍêqRP¤/ßˆÚ+Ø‚ŞŠˆÅ5B¡S1Éj®:JYí¥Jå!3TŠô­€g^)~P+Õ3¦WŠyôª²SúxPU0=¦VyÈn.­·ªTnZ™=š:WIİï5wŸñ£!ÚØFcÚXŒïÛ7O9™¥yjvu	B…
1„~@yà•*&O©Á8œı¾pøş":oW”|*(P5ÖyRˆSûvj\«ÅÊü¾s¦*M¨B¾§Pwí3ê¨­®()6eÉ–e¬(ÚÖ_[jcæSÆ•ëRiaÒR+lÅPÈÊjAóp¿±{‚ã‰³·X‰ß®ÙéƒƒåãIÊ„)7úã¦‚z’BŠ·ûœú
ü(ií”LG÷İ¡ãd7­PQÖ¢¢}Jk®çJfú¡l[Éxå©Ë8¯|0½ràäŠ(¾çÎV3mZ¾‹6(¡¤fù¶Ôú¸…†Ú2NÜ}œ¹íÒ÷¼ó‘óo&³+ˆ‰µ†|Ïˆ8ºjtsÍ‡ (Ì¬€¼Ô»ç1c×À|›yRcá“ÆSHŞúOÁË‘æµ@ ÚTó5 ¸ôT@÷ü>Dı)DıZM<¶UÔ	¡y£¦…€âáÒ E:µéàbÁ
ÒÀÅ5qÓÆB¤u}“€‰QLÃœÈ«AÇGJdóJ¸ÚÇ™¢í”cp~¦tıqÑ7ŞA®gE=EßõT­iô€ëHDè¬—ŞG«©ˆĞ T;*ïN_¤Qç7Ò‹  >I!gvúú8‡×´Pù‚íNlÖ,Ó·a³Ëum4ÿ´…ŠÃá—¸M¥Öê¤X*·†¿ğ-ı;éÙ ^F•X“ºM°¦À4ÓPD•á7Rúu
ìOxîç:IÆbv(J0mhªÊ@ µfÊİÚE03H€ño³Á÷
İq  F/¿Y€ñÛl U2TıvB£ßFçc&4›=«ˆ¯Å½hzwÁİD*Á30‚àÇÖQø–0ü»ºPEñâ…ífBÄoîX¬İ
ƒ›Ì­B¯×t$%ã¤TğğüJÖ’h@˜)"µ„Ñ·ì!‡©(Tcjús©$–*V¼tfÁÒÂØNšò««ÙÅ¹!¿ ª¨Öe.1¬\‹’´7Ô±óR‘ÊİÖ‹0 ŠTÏ1†×",öQi]ãtÃ#×sÔ-Ln/hèÙ®ï£Ñ¾°"R!#³q§îPCİGú£ç¤ğ–ş%WéØÎ*åEk™‹f	 òÕsøw|¶Œ'-P!C[E¼k±Ò‚‘¿]*aCe<KÄA,-Ä9ŠTÊ/¶s¹Uöª%M=ùëŠÀµúŞÀmK<k‹ûã³¡Í‘ÓÛ”/A¡!nÏîàÁ|&(-SxìÃ_uÙØ¡Û*0P,Q–Ì¼Æä…ªQ6Ø÷îXÊsÏèØß„]É!E˜°o°yĞºËËKÃ$€†ëõJ¢:¿´·»Ó:h·Š ô	Èæ·¿ÿtóó&f÷ÿQİ¬V…ÿÊÂÿÇC¤4Êy×1ÙÿG¹¶¾úY_/oÀø×¶j›ÿ‘ÿ‚Œß’9ÚlkôL	 -ív·ÙÒÜÁ†nJÏ×ØS´AE!·‰AmÜ­W¿dm±&­<m¶P¦mZ=ôU€ñÀ}à°Õ¯ÖØ—ÀnØógŞ¸×[cmX¸~´<t=2÷F£BÂài;a–ßã Äñ½Xç¨—¦åˆ­€0Z@SGxgğ%ê7À.[PºÕµƒ°ôÒé;Ü®àé&šœ)ğÏrl]Ø¸N%²È<›ôŠNí„ÅºOÆ»H]¢FÅHˆ,ƒğè±gÑi~ºŒPÀslà9!îÇ "!u¾CıdßÚhÇ~µ•¯Œò–Q-W6AîæÀ@&§¶K×3so@QŞ‚Š™ƒßÚS˜—d¹‡êgÉÿJdo ££Ó‰¨t CGÂzšp>‚&|gVdŠ‡œ âaø'W»âú¯ğÙyé´Îñ,Æ	\hŸ)¯çkf²¯óDêñ%Aª˜}0—vÑè8’‰•šQÀáa“³Ç÷é{{§<íî?6NvÈB¹\ß·U¾bb"pB“R…½+íBÅY¿¦¡_ÓÎƒãWÒfÂ@‰:†I •…Àô³{éúb~«Zn›c÷«ıš~ùSiš¦Im_R‘¯tX=“Q ŠÃ—é0Å¥5eT”#– Ô‘¨øPA+w3oË¼äy›O×èğŠ²&¯«F±Ú¹n¬Nİ®/1’Ç×ÄíaJ…ØÆD°xËñ1nº< ×|™În{8aFw’·ø)Œ¹sÓoR'ù“-o}j	Gšİ¤Áâ=Ô1Eş/W¥ü_…_[¸ÿ«UĞÿçBş€ôó—şüÑ£}³ÃÛì÷’à»GªğçOğŸÿ÷l ''Çâ'–øŸğç¯cYş,zÿ· 9èĞ2 u¢½ ^Lz|ÔÆŒæÿ±şÿmııÿı»;õs‘RSì2î½Ô1eşomT·bó}k1ÿ&İ×şÿŞ4 Ÿ© Kğy+ ô+uÏÄµbyëN,Èş(Ë,Ÿ‡‘’<¾ÛU¶IM‚Ø¢;AÓÆë ¡™ZCà‰¢°q‡O÷­DøÔ2-†(T®qG6?7¯§Î•˜ïø|×8®‡·—æŞpB£]©/¿ÿæuûõe‰½Š…°xÃ–eÎN·‹2}1ã¡Îxü®(ÃY]¹Q½hÁ…f©É>Kš§dèÄ3Dñ‰D0º(o?5¯’amÂ¢œîYÔäX‹Ìø'á,Fd ™@_"_xx-7¢ákBbò/=“šÃÍÎŠ>Ïgë²¢Ihî‡Ãª®…–ÀOÄ"T ´~O6/ „!e2¶ìc¶CÛZ<Y?¢e¯bg'àóè) ^t*Âe8i…Ñ]§VlÒrVüîêÇú2ı,‹†5ÃY¾(¢à%ívPíFn¤C{=Š!âa<Â®›ã*	,¾dÇ},pƒæô råsÜ]”XîÄƒ
.°fêËLÊÔ¾èk^åyå+^HæÀvi¹p:%sÁ[-Î®d.7¸œ³Ùı´NÅZm23…sFÉİ™œ›OÈ(?°e4"Ñgó,íñ¬vjV-“‚º…XëêËaØÏğ¥Ûço•˜¢ò|‘ò j¯‡ìía”Ë6€™kór“f2êËø¡ËŒU˜,wàzus¸a†t0gáw^øÊç¯Ò ù‘xÆÒ*%¡“Ãªå0OD-!	˜@ûÒ(
Šm”'C‰ŠEÅ­›'“0¥¸gn@1ÒŠ ø7ƒÙI¶[_¾°ÑÆó,Dbq²‡D1¿@ë¯ú²f
V,J;0FÜŸà%ñyÕl²X<XèH8C·yÀò§İÇØ'°^^|—Ã$L‡—jKüñğã6>B†¦w%›Õõa†¦¤	7hŠ­H±<-IÀy±+=4‹:@I%h\}
PÈÀZéÌÒŠüY˜ÜåÏ'šªÿUŞæYÇŒúßõÊúzµ¶YcåÊÆÆú"şËÃ¤O\ÿëıï¿şóÎã;õs‘RSºóÅùÖ1eşW·¶ó~-æÿC¤…ş÷ãê5—§?I5°ju?AW«WåêàÛ7ásWÏ¤^üxê3Æó[Hotõbîˆ¸Û¦Û‡¥”Ë`ha'ùäeùşÖ˜iò­"ÎËµjmkãÿnmUëÿC$ÿQqnÈ­ Y…G[ˆ®ÎãÚ…ªâyØ;‚Š/×•—íğmM¼mĞ–[¾İo•mºü¶‰!FÂİp5Â[l˜{ã7Â_Ív«Åøõöö~îñMçËñû§Û•õ/¿Ú®l®on× mù<ÌÏgß>¯”îZ}¾uL“ÿ76”û?eŒÿ\ÛØZìÿ$-î|”ûñPŸ«äŸq$]P_Ü ™Ø€ùJê#§çæ,z:‚7ïXëğÙ|€~l>Ÿ•0†Ê}×Qíş/ˆıµ­r¥B÷kµÅıß‡H>ç¾ë¸Íøol-Æÿ!R§âşê˜qüaÿ¿¾U^ßDûïry1ÿ$Å¢>İK7Ÿÿë[•êbü"éÁî§ÙÇ£ºµNã¿±±˜ÿ’èî¡›ÏÿZe±ş?LÊˆS5×:Ê“õ•2×ÿ¯Wj›UÿkıßC¤ÇºãÜõ>ÎÂPN—‡Şâd ±?q‚ñ:a ¾¿2¢—"ş×ŸÄwÈ ^=E ˆyŒu÷<sèçrG“oëKø÷ö¹º5BSoñ‚NûäMÈ—»sµÏ9Ø`Š!üì1S
ÿüÎ?~î)=6í|ë¸ùú«Àæbıˆ”^|uÜhÿ¿UFù¯ZÛXŒÿC¤iÁ«çQÇùo}½¶ã_¡?e¼ÿ¿U®.ì?$ÍëÌ$~0»ëœ{¦xcŠ6&.rtY›÷?æ™lü86®}®g±Zéø9,,y[F¥j”k±ã×ø1+«DÅùİJj,kRdØYkêA©p-+Ì5›Í=V1ÊìWìùÑ:¦'n÷İ.9Smñ-‹õltÌ»Çúü„•Îíğ–³ø9ç½ğå—x|j¤”“Ãæ¡õnN-å£™ë+‚wªij`9¥;@”êPÊy¬,‹¸.{yåA ö‡§¼\¾ ŒÂ€y™ ps€ 0–šüRúÂÏ³/˜ÒŠBn/ÑÍG&!ÚN°‡Êï]â%º{í|Aöı,?©p»½§”¯Få)‚lVwxÙíÖ1¼´Î@º´;ù°á0ãÃ²yÑÊF»ıòğ¸	˜ÜÈÃ-súæÑ<0m³W_øo–cÈø:–=ŒK˜ÈeÌÒX,{„İxn*ÁKÄstF^DøIø‹r‡qB2r#Æ wt»úå^[Îş†X³ÂûÆ³Q­àa-ÇIS„^,ÂÇ¤RH)*Ajx™T1u L®?ÓJEX«'ğÔz\°tò±—ØO:¥ïÿ€Í±)ò¬‚‰ıßÖBş{˜´¸ôóĞ—~>[[¿=É ²‚0£1 b»·6v}ã¦bTÊzã&æÖ7r¼Jë¸t÷1%#WrÏ‘ßq§Œïi½2y07èahûètÙ}KO| ëôàÛ?ÂÏrùmîz¡øı™¦Äùï|—~JÓô?µÄú_ÛÜ\Øÿ?HZ¬ÿ‹õÖ[¾À ~pÏøıŞÅz¯4aŞğ.-ëíàŠ1šw+ïc@CŒŞ‘.ôçZ9pâ¯Ø*üWôqq#§@?8–ßgÅ€={±·ÇŠhó7»{f>{ò„•‚áHÍW±«O~YÉİúº&†{´GñËÌ‡ÄòZum}­¶¶±¶y+tîì·ö['O«Âôâá0Y­&WgÅŸ›7AØÇ^‡?VÒí?/ş)é®ŸÔÌ¥iòß<ûÏZ…üo‘ıßBş»ÿ4·	‹×·oxø¥3¬å˜¢"€’ Ì§HkFšÌ¶¦‹k¾1&±©™QŞ2 £€1"’É<:™S¥0ùåÈ4Šâ»ò0½ğÓzmş´qØ	Ìr(,õ4ÖQEz“å4¯,t‰#+3É5¢&˜¢Š. yÃ8Ç†ÖRxUZtÏ¿M®¥³?¶B'ƒ5ºÁ”XÏsaGÛ>JÅˆN×Ô8SÌ
J%`Í¹Û˜mí»?îº¬3JÒ,:¾WÂËr¢›âßR¬‚Ç.Áç%S*Hìb¨òÃ€¶]Ëì@]ÁìµtEñiÕ´ÑS…ŠÑÇæ`"p2âœ´;º9d7e$x˜¡ùqãØ¹4=QÌÏòW¸ØÛHâî2ó,ŠK~2Êì8ôl.|bˆaŒyä"1Î±İ¹WÈ Şä”ØÌu<$F ]vä^šNà×+¸t½·ŒSÏ
róÀòâ/Yî•àËor'W#«îÛ0Á­±ÕEt²ç8ë®¸{	Åa’…³¸ËpÚ¢YñğİÏ²±…â`<×zguˆæn^¶Dd÷Ò:ÛÃ£@´\åÀÜÑ-`<w¤‚ƒv9]ÓëƒÑ8¨U¢~ğ$XÈÂ.î¹ëÃñ °‹X@çÇ^Óo’tùO®áù£9Ö1EşÃë>áıŸj¹Lçë‹ø¯’^µï´Şä-äbôiRïˆ Õu@ø¹WÏ[­ãİ7¹vkçÅñîÉ÷§/š“Vûô»İÆéş÷ÜxûÅš‹ÔÏÍ?ß[$‹tIŸÿÀ2‘¿á­‹9Ö1mşÃÛhş¯“ÿÏÍ­Eü§I¶sa9¸~ŸÂ˜'ÖN¢‘!‡‹ÃiO“>vëé®)6ÿÇİS©Ì›Ÿ
hªşgc+ÔÿlÔğşÿÖæúÂşçAÒBÿ£êÒè¡z Pˆô¥ÏZ,°@ı“F÷«J'¼ûPÍPÓô@3A¿¥*(öyÂOF¤ún½_EbP?<j4Û§a\ózf†2/ıĞ}[1¾4Ê§•Z­”×•?•((<É ®oIçÎ\ÕSì¢g¹?mh¤ªê™RÒÅ[xûE=‹“¶’®ú\UC1ÿ?Ü=î)’¶/æRÇTûïõõ˜ı×VycÿáAÒÂ^+Şì¸½–6>[ã­¦pÒªœº…¢9	oN\iN¿®]¹. °Û©ú‚Òá<¸^/×íl³ğeÎ=Ã3…Î €R¼éØ?’I¼şV±ãÔiíô×Ò`w ÿœ,«©3Øq D}Ë!Y.,Ô™ùçAşØ¬i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘i‘fHÿ[v– à 