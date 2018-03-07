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
‹ gœŸZ í½ÛrI¶*ûœ}O>~ğ‰p8|r öÔ&.…+Énj!5gx3AuïÙ-w¡*AV¨Â 
¤Ø'üà?óê7‡¿ÀşÃï~ñx­¼TeÖ IRwWvKBUe®¼­\¹råºô·òäSµZm7›„ıÛâÿVkş¯HÄ¨×õj«Ù4¤jÍVí	i>tÃ0MıÀœ@S|ÎÌÙƒßE?Â&©óïMí3è^0õËşÅÔ1{şkÍ*Ì9›@€šaÀü*4Ÿê´%‘~åóÿô7D¾é_’Òò@[Ù³·ÉÊÒÁNœKÓv|Òy½A^L}Ç¥¾Ové%zãuò[Ò›ÇŞ$ k/v{ëP¦gÒs:¡LLß§¤¶µA6f¼šAĞŸLÏÏ7HïÊ	~¢“¡éÚKoô¡9¢e¶‰¶ààcg\xñ±Ğé’#z1:dÍ£ş:ñÙ»²ÇŞı>P¶¼”îÚN–^Ù7ıàå…éSûÅ5ş]3ˆêV3àå„^:¾ã¹‰,òÏv<Œ=ŸrH/ gHÏš8ã€9§ğÏ%]s-Jx‰é“	¦.±<›âHxõekN/`}~LÇ^“©Om2ğ&„º—ÎÄsÙ¤Âä\xÓ€œ~·[‚ªák÷ ¦jC`A0ö·+•sÈ9íãèTøˆùHâ ÅéÒ§†‡|XåM®·á±j”«[åZÕhB€¢²ç:cÉ%à0B£V6ÌÓ–y:ö@…p)üÂÌK¼b
t´ü ‹³D^B¥ŞÈùÉ a÷^ Øb;z³{vrttz¶{¸³òQyÚ.m‚s\zeor^¼aèº6öñşí(0p»°F¦Ã€|g§Ô¿G‡
ßuOz{G‡;0›…İ£Îñq÷pw§xzò¦[$¦§€»fHÉĞ;'~˜ã1Â°_õº;ÅWıŞànôa	’®¦ŞË“½ãÓ³ÃÎAwge1Ü:CVªë…Óƒã³İ½“îËÓ£“?í+Áh\d/_ííCí+µ7½xye¥XèvNNÏ¾ívv»';Eö„äÉ„©†i[ù¨Ô~CÖ¾ãïÅğİ¬³5KV½ıÎîîI·×Ûœş½71aA–­‹B÷ääèd§ZP1âş3ÉÁ½šº"Õ}ƒ[îêˆv‘7¾yN×ÖÉÇ8mİuüñĞ¼æ–\;¢Sˆ…©Ù«]ïÀ?'Å½ÃWGd›W¼ŸäJ—RrÈ7¸º÷'_vŸ“Ò.ùØ{÷~ÿÈÃj¿ò&ö+@şçä]Z%„”.ÒUNÖÜF°¹ÃSFñË´â)+%£ø$­¸uA­÷lû™ĞñĞ±]Ê  ô;J}/}·‰åîì:já&ALz3É —:t/à‹WŒ–d”NL&x›ß’ÓÊí{çŒ<Áÿqÿè5R‡Ïà¥qCJç©’w_ãşîd7_©év\ûßN€ç[ùX»aŸéöZ™/FñÒËW	{?p
7…¥ïu©Kë€#§Q3bËhüPKúÚzá#ëçŞáñ›SØ$¯¶Ÿİ¤!!KÀëšï)Îvr‹Á='}
ÿØ|l- ×0äÔ°]é A&&qàÉ¢~2â»A`sç¤¤¸NÈéŞA÷ğèà6ØRü»¯şTújTúÊ>ûêÛí¯¶¿ê×¿şZ)zr’]ÔS˜í.PúõıkÕê-ÕÏøw-C9%ÉBÔ7­hÙ††|S$;D°ñÅ ³JvaV^V‡uáaş¨M€¸ˆŠäS@))™ÊzKjëj6˜0,)ùÓ¿pAøtuëµ«ı´—µÕö´*nÛ³¨Y±—s{—ÚÃÙà´¬JO“½µ=—&iÓ§íùó´>}a£ŸŞÈÅï!èsH"Õ™"'İ,™õÂøÁ	€9š·ñ¥0ObôI6‡Ù«ëá‹ÔvÚ÷¬’+CÉ²w¡›ä%p1t™|Gâsb¼©Ë8qsr>Å#²_&=X\S¶­!y·¼	òf¯¬VQ[´
	˜¬áÖ¾¾(üæ\ø*WÂØ@1àô]/`“êãvÆ§7ª‚‡“ÎËınÈİœ½èôb=·VVŒÕãÓ€Ö^š—¦3DîQëaÌƒüÒ›m!ğ¦Ö?ña¿´a¿˜¡gÚäíÊÇo =*eÙH\}n{ìö]~8@Ç¨­–oÌ-ßL`„°96ã"ôâs{Ã‹³ÙL]ù!²¼ÑÈtupµ;€³}…EO…ZŸõÀñ}ÆY%¹l£Á­Fã¸‰†j À×¥œ$~ıRÑkG,v¼ƒ²X"á’Ğ­¹àxÂB;QÆ—u¬+ZĞ:v<RÇEë³+^§
ä÷YE#$â?Gü¥´kk=vRù
É®L×5‰üû…9zÚ2ıİ\²óÆ}ïzW.ïz¿WÂÌRPr“ şz›NèÈ»¶š"CÍ×|X4bN&#díyÅ¦—w:†YÂˆ2PŞÔ–«$‚jO)Šaóó&¦/^LÏUè(İAg‰—|VÆ)I«FÍ«Laz±©!AfãWb»£WË‘¬p!Ş_	Ğ8n†'¤0±°¢ğÀ7¹.H–Jfã,•ÎNqL`¶8N`D9-W’ÕÔ»5#<ïB
aÛ¡â°ùl'Ìn.ùô	¾ü†”ìØgµZ­FjÃºöqPp™+öB™¬¬
F[b‰ÉC!ôzœ ôá)‚çL!N(ğSEÆ¨–8â`±À÷ÏˆIÕ°’sf¿ƒ5úäËÈo‹ÓtEŠŠìBë~Lz[gDC­P93[Œádl&8ıKAYîÀtî%{W°?˜˜cRÔ:Ö¨ñŒ_(ª£®ÈtBñ…†aô‘‹‰)±¦Àí¹LÌ^òÅ¸p×Û9¼1 ­^~<ñpùáF+vé!ğØœ 2(ãç!Qš\\:Û»Û?nw·'È…†Ç"Î`Ã•Á¼äÃª²\®Çøtå›³N®UDF4=:†¡y­í¡»˜Ë÷2rü(s¨"»Œ¼“urÒ=Şß{Ù9ÅË…D«ºë:V¦Cùìl¬<S70vF©…Ş?¤	‚ØÒ‹\²ÊÊ±½Ü2‡¡EÀ©D‘¬è • ÏI¸’aUÿÖ(`&.ÿ_ùÔuÁ˜Bqsaâéhú1ÌŸv2ÓÆ®IC€yX§$…Ißg˜hgŸ±RNô†`ù‰Z3‹ş„›Ä…áºÄ<qì+„(‹CÀn—Š©Rè›B
öÊbêK °òñøû]Ñ‘>L¿[d2ÿ¬]¨QONØcÌÕÔ•¬PÙWGğ‚ÈY*ñëäÒ`âPÀ§kxãz% @£qÀ~O¼1õ±¥ğŠQÔ‘İCh>­ö‰¤v2àL;€ÔÏu¤Šcx!Ç±c¼ñ·Çó†¡eXbŠå	ñĞfÓ†?°é˜ü¦¯#ñ¦½äU¿òç•J©²ªb"”úÑƒíé…i½‡¼do—ËGÓaàŒñnU/B•#Æ›Âé% dğW*¿ö+oİ
©|}“:şLÀ¹¶€©)QK£ù6¤-7~¡òT\ûôèäÎ[ˆz=uNÖÎ]†ÖXd5‘E\ŠR[«{]’eî€ÛÖêNŠãt*V3\b‚-I¬è¨x!Š&
Æø±€‡,xû»cöW/ÜJõ‘á„%ÜÊGGœd:ßÿñìo-ÖÌ«÷dõE÷õŞáÇ“ŞNñ­[zg·Wìgñë½×‡G'İ—°=ì_ó£ÖNo‡òWRùsÇ¶'0¤¬+5|õö›U¬eõíó
ùZ[©ó×]Şx¿.àT¿&7xañ‘JØ;}ÆÉ:k«¶îB†^_Y0;M#ÁÍÏŸ¢ä4l”$C¯oÄÊ–Ÿ%»uvŠ'³oóÙYÚì06 ÿRVT‹†-N—aÅ(§c?eFpõëÒ§Åw*„–ZvîNÅ$y+ÇGÀÂwvöÕÍ's3í‘ã.°‘%w¯Ô¹ÊÜÃ´.eMkª@ı³Ú¨éŸ˜]NC;§b)Ä R–®‡íâ×qoHEÓXº‘¸Ş&¿ù+àú!Š¨†¸$®7k©È~;¯Í¾ToÖ4ÔÅşé—æá‰t'ÈÒçÖEÍÓã'©ÿÍUø>‹şw½Q­¡ş7üj7kÕ*×ÿ6rıïÇH¹ş÷gÒÿÜ/Eÿ[(›ÀŠÈë9•òéªß›eøÿT¿z¼ ãÏƒ	'äPŒŠ€ü1µœÁu¤‡ƒ°l-‰åªÿ²•Á—ª	~k5ğGÕáş©p?¢¾vŠ¶8¢Â=T¸ªÂ½ç¤4"ß(3¯WÙ¾¾öâÊÚÉ6ïeCdSo¤üŒÒ‰î…¥LgH„Ü#½x®#ı¨:Ò$×‘Îu¤I®#ëHç:Ò‚D>¾"ô­ìpÌ37¾\Czü\Wù–ºÊKÒãıZ¥¹şä/L²v¿Û™«-™­hÉë P[®By¬]²% ¼½¦$?ıäÁT!GÛÎv—©C>†.d/C}q	ĞÊšäódŞO(ºõ+o7*oIå|ıÁô(—¢'ù‹W¥d/6·)¤Z©¡"K	eö¡f`öSå"±‚1!Œ²tO_

Æ¡…m áŒ=%Ö„âiÖÔ5(PNC	’=fó¢´†ï®Ò÷ÈiçÅN²¢”Œl8Îö÷z¨"Àõº.ÉêŸŸ®F&gŸ¬i -7`sØ^OîEb¾ïœ¢vÎ	aãÙ °Á{›Ò÷8¯€÷è›€”‡Å°¥»ÓÎMåšÍD¥¦®ĞÊ:¥¤ÆW–Aƒ•8B-8öÚ7¼‰Ñ€èC[bÅa„5ËÏŞVŞ®Áßëo±åg+•·Feu=êšzˆ
G<©Š®İmğqVhiQàõÔ§³ĞZ”`Ê†…dû#[Cì€>!««ş[d_˜ï¸ôŠ‘sÇMP*ğH»½¾apßº°Şo¾cT"²´Ô
×\Z‘›zxcâ¡Â¢~‡Åñ‹‡Ö–Já=ÁVd¡w]‰ ù¡É›rL\ŸKä¡r¹ù«Oì”°Şä¼ìáåˆ_ö™–eP´R[®zÉ•,¥ŞuıJâ+,¥õº–Vi:Ş ¾7XTåÙÊŠ*ô*•»“Ÿu./ª@ò{‰¥g‡{J´ç¾‡—¤4–ªCÏT¿v÷Nt¹„Ö¬ì£‡®>×ååöwá·bÊS-·F^ÄË3?˜ ƒ¸³†Ë¬$s‹ùqpNN</àÔÔŞFŠºQC${õ‡¶ûCÓ}¿ıîİêz‚"	`ÑJÑ«½Qa®ëâ ×şb3{±ƒpÚ² ÄçeV+o‹o‹•ˆÊêy”£Oëº”/#`Ú9ÏLîfsîg+ådÜœ…M»á½
:{z}v«§P‡ç¸½İ¨×1¹ @­—GäõÅhïğ¦Â!–†6,æRéÂóÖ	fùOé%.¤HŸÖLÔ€SÇóaS Ø²ÍÍ³]óZHÌWÿî«é*œ— Ò¢ã¹6H±L|F…J¸Ve|¥aJèFËP*[òiå:—IéçJP’Q±î	Cí^wQÄâ~)D…Qv¤ÙXLÔÉµ0õ¡ø4 HÉgR•£“ínÈeÚq¢#H’ŠA#¹¶Æ~ü±®Ó‡Tñyö´/>.şÔÂ“İ Ù×ÀÀ¸Aí¸ø=šxMÚ~Ëö®Ü`?e÷¯Xu}8QÒ	ZVS»\…%ŠnúJºè(â£å-±KRa†Ìçœw,À÷¥Fµªÿ“Ëš.T…brİØœ²!(D#ÓwUEË9ğÿÊµ^¥ş'"ñtüyüÿÖ›õPÿÓ¨·Qÿ³ÖÈıÿ>JÊõ??“şg¸à~)úŸ¼C¿^ıÏVşŸ£ÿ¹U®¶µ<æxKÈÆÚÇQ¼®¼E°<wÀdÉğ\ş&ôìÈŞç
¥YĞ~
¥Õ²ñ³õ.ü¨j¥§:Æ½Ùß_¸C¼SrÎ^pÒtz=¦…?v»Ç;ÛÀÀ§£>,èŞ÷”¾g‹õ=¥ãĞš1ªîK%ù{vr×
Qòjhç´?gÚ€|ƒ¨úË×¥;&e…\¨¨­²wøò¤{Ğ=<íìç:¹wÀÚ/J'7÷[œëä²:rÜ\'7×É-}I:¹©äæJ¹¹Rîİ”ro—TÊÍ•ig€Ë•iseÚŸ•2í²ı‘~Š´Á¶³=Úî>„m G &¦JUF}%ÛeºÍµF“s­Ñ\kôg¬5*®çÔåñd¡ çrëG2Ç·}UÀ§3,.àîÎæ¥âÊ£²ãi™¤i½^DXÓG9ætè‘&ÎÈ¥ï‰ËDñ…Ãî÷gßw»<<Rd.oŠë…£ıİèœ¢Œ7¥•xp³¾ÎŠ¿è¼üã›ã³^0Wz•B!¢•"_áQ‚Du"@=¬bVá¨	)…õ)ÚMô'‰uTo„é‹QÅ7óáÕ,ìŠÓÉ¹¸YÕ2Èz—ríar_=N]yó‹ÕDN—ĞHÆù6auÚèŞğ(Â¯ˆuÑu•&1¥ÌÖ.0(\›U¡ZQ»ñéûÄòˆÆET”¦Ë*à19¼y*¦’İàf>,2³+õ¶(…ŸTUUEIÚÜ‰ã::x~é¹ç<šÆZ,ÈŠ•ŒÚÓBJÇ?YƒEÆ¨¢êár˜åàü'~Ì{ytøŠ<Ïêõœ®É`òÜ¿EßâE—Ñ9ŒiÃºöVcnXG¡kÓâ§ÃgtÊª<Nm”kÈGáZ5–ê96|)(ªÉÄß;kœÓFYh‹ÑŠi/®mœ­iü"uQßB©x!…bQËŠç+'dşÙ¨—Úåô…cìvgx*É2¡ÛÒÅ4­úÄÚ¨¯³G×`Û|Š¦xq‹mşóôÇSº(B!A3Tîc‘º$[§ñ$I5òÉˆ”&é+3qşÍLv7=µo
¼ş=/'¤”F¯g^ìÈXJKRõÍËU½o‘>·ªí™Pù·|ŠY¤ÙúßÕj£ÚBıïF»m´ª5Ôÿ®·\ÿûQÒßüËöäŸ>yr`Zä¨Gş^’&|÷äoáOşü7øÏÿäÿZdçôô„ÿb%şüù±,ÿ‡xÿÏŸ<ùWÀ‡—ÍñxHËCÓPÏòO{Æÿ‰=yòo0ßÈ´&¸R<ây0„Tyÿ†çı×±¼¨ÃÜÒ=×¦<ùKÿÏ?`îÿÿ?üÿ7şk<
¢}™I‹Üô@uÌ^ÿ­ºÑ®Ç×£‘ûÿ~””Û|ûPÿçlûÁ…SÌí¨+YnÄÃÉæV aRMZØpº«~"Ø¥Âä	 ~€‡ßÁi	¸„å´=ë=¤Zˆ Ğsœ!TŸ5Gˆ	ùıÌU0¹^ò …ø	¾3'ª×ÜM!¡õ(gÍtë/¹n}Ó.ÃJPWÃÈ5C`—É’»(äß±i^¿®Y_5¡ó‹NïÛ³ŞÑ›“—İªïàĞ?İrY™Èï±øFbI¨pnF jk¬ÙÎ„å,&@ö×d|e“Ò1üjÕ÷½á4À[öàAë`_ı[æà)ªçú0%=%¯0$ä_¦æĞ8x¿Íé6J\
Åg‹Û¼¸H$˜Ø³ú…İî«Î›}ş³Ëı°ÛK1„LâVÔòˆÃ¼’‰Ÿ«õ\ÚU¨È§\Y+Y{g»GpÄÕêµ=$jzÆ³ı£—}5ó¦™ç€Œ÷AÉ…7Æ<¬Ì\(1“ugæ:íïwN»=‘c	2‹²¨ÄñÉÑî›—§j/ÆÌ„,P òÛdTHY£+£V®•r½\Md|uğıŒÌ\j|Òe¢ã½×;ENÏØ5Ãb!·£bäW€‘3fâ&û³œ„›)•zˆ ´ø[.k½ÊÓvIQ“ºY({J×”’ÖN–U‘•—ulGÕÕš30E©	¢În(øŒQË
+—R€*²Š†1°3ê’HÌY\1?êÔòù&–´ésX¨±˜ÂV&Ï+ØÓÄ*ÏÍ®_Icï˜ÄˆÒâè…äqàÔjª#ŒîN¤Áü¾©ÓQ¼QÀßâpå :@Ğh=0£r¨÷¡mŒb­Æ„pG¬Î…§1ÀÑŒÅ<Iruğ:¡åàõw³À§i}2äÚ¾@õ×´ùˆ¨Z´Jñ)1ÇJÅ	r©µ*F'Õîê”1ªP¾¹o¥ÍU*şCç»¬2ü}ËÊ~4/M>´H9¢ûd¦Q"ËUî¾<=:ùÓW¡cjK¢±oP™ö‚5'öDÊ—ÂA.[C8®ÉóXDìñééŸĞè=¿¡ßaöiP»ÅTçİĞ•~ Ö”5£"HeX±p»xo%~²›«/\+™«N‰{„˜~\Fù×YÖÚ”¦ÿÿ6Ã €·oBƒéÄ%F<~w¸ ğÔ+aKÃ©qÛy‹ÄGi•^éY@'#¬‚˜ÑâğZnqx|¥ä¸sú-ªëœ‰(¸åaxÔ+¶¦	EèN ãTÔº!¥!éò*´ºó]w÷ã?7ŠX3Ê•¼{°=s„*{‚WûˆÙÀë›ê5Œj¡Ò0×LdD„#êşŒh¢l"Å´Jeò¹É|ß¨0¤¦ç­9¤pÓ“¶³Ş²-s@DM‘êŒB$0ŞØÕÍSU2Õ“’`=nH
Ë€/C­X¢(ò‡ÚfŠ’syúÚLbWº-ì	­‘ñ7Ó‡)¾fÁ€E'ÊårÔv”ÀœÉÑà‚yaL©ú*ü˜ı°‰š·ßHÇ—rNÆ•ÚTópB?®-2c¬Fu@õ{ãHµwè{°¹ ù­7Píõ½Ğ„UÏ Š6PK‚!ì±ş€Ä3yGßHWÍVÛˆäq (MK8ñsDªâyŒ¸ehÇ¦–“·YääëfA]z¥Bã<¦{eø{ê·‹Z™¢nt$Vál!ìPt4®#$(&”“|¯!@¦Ñ¬Š¦Ç­©™‡Ÿtªã0øÌöÈt¯u’T±N±TåûbÍî£{ßŸ§r›r_|3„ Up8ü Ğ$g;ÎspäWp')’ª)*\©£ÃcEB-z­*µ™½èI¸—‚Ø—bÿÃ»[ã\¾İ×îŠgËÆ1†_f4¡ò¦è3	ãŒ<@œbeáßS&åiÔ–ü~™İş] nyoVÀë¨J«£9e‹ÕÅp>`Sá®¿P$oBÃºp$Œ´î§4fF÷b ø÷Î ÙÑOÏhÚ®¬B4Øø<€Må—ê)t'€ú…€ÁÔ'ã7½Ìœ-|Ï¨š×ˆ9°fàı%7ç¦åôZ@â•#o§Ê»{'gâcÑ{¯¹ü‰	€ØÙ	š´ÌıMÄ<E…‹àU…Ä?Ü5tbcQkÿİï¢íO¾“·…œhÚèEÈ9fµq·×í.ÒJÑB&ç1›‡"Ó[4Oà‡ÑpyT¹ŠèºXòáçJÿõ¸5ÀVÊ¿±}‘T9ï…Å½‰iéğ¦á9¸8Å¨îpXf·Ÿ!@¾;ßçÕ}>"È¨5Â[µĞ]O-ğ-6wm%åõDI>WD+Ä;ËJ¥ÂH*Q_S‘ŸWy³àšŒ³lôşnç˜#y&JSĞ±zœgY{z^‘õ¬×ÛOdï0“‹ÔìL‘(p¢ØYˆb²ÀI÷øëúQzºĞ¸	ø/asò†”µ)¨M³]©(:	Û¬J<ºú£D¿===&zÊêfí¥fº#æ—²¶–îûGÛ:§ãä¶©î˜bkŠ*kù'1œzn¿ˆk1_‡Yü0®òb|ÌµÖ‘Rò]â1-õ³G¦±(¦§RZà]¸ŠÉ6Òá0O´f³E2	}º@’^2”uÜİÕt@ˆÁwV_WwJíæë® [Ù ow™&¡¤pf¬ò¨…	‘&•Ğ6(qbÔ¯jo*+BLâ†=i â'\€b38n0 «_•š>ùªdÔğïûÙÀ¿}<)&{$$‘bß‹ÙëWÖ~ô÷¬M*	‘ãFü‹HşfˆŒZ\EnÓmÒÊÉ7Z—IÍ”ıHâ$í\å \›éŠEPº j’á@†jR{&d‡n
÷`:VÖ2-ÍWUKóUø¢Ï1¦ÛØg”FkôjoT›ôd!¶‰³¶¯NÇ«_s³2şŒ&bğfà¬ß—AYÂ¨¸~Éšcû‹ëw:ZZ¿¯†şç›ïÄ…º[1C
Ö‰¶ÚÕƒP‚‰	W<:ÌóÇ¿7UNÑÉHvæÖşm×tævV}?*MfıÕƒ]úîÄ…j×¿YœF±ÁUW™æ¶š¦Q¨¨«^ º‘.x6]!“çZ³'´L‡EÙô†œ`xÍD¥J¡L£×·¯ßµ	•--P]™!Lª®…Şğø99ıŒ¬4à!ÜjË—‹:\¸œóÿy,Y©á{a]b½¯p(©3š”ÅåD2i§¼¬(¹dµÂNïL¤ÀŒŠ¸[VÏuÙv_Ù¨üy¥2^•-™tÛ/Yƒó^ôP—…Íœ:ŞChg	Ys¢NQ	Ö÷-óÔ°ÌÚÄéE«±÷ÀUtTE/ËÕ[R$»§H×ŞtÂ×Z9•"=•4	W(ûÙ› Ò’Ÿ4Pa^1˜v—¼‰Ó7I•cé”Ó›’_ä„<F}s+=GˆğĞ‚y[õVF^6“åOÈ»¹¥Á½;å½M*¦Ñò¸5CÂ+Ú%D\±¼ªÔ.U8©ä(3¤“J‰¸„2!|˜Q|Œİm:F+ğ3!Jìpü3[¨Êòù·°h7×	±İ(Uk'ÉfŠyÄÁÁ¹²âxºÎÜÏIá®LŒ´:¤X‰¬XoßÆ^q	ïvˆ§Û
n‡¸µ½¢KQíÛ¢Ü¨iÛñàM{ ¨Ü’ZüüyV›“^[¢?  ù‚SDÈÚÍ+Ë"-MT'oK6F”t"¦…v'hÅ‚”XE`»‡ßİÏ†3Lâ›ŞéÑÚ1 2+Ÿ²À ı}	Î¿7Q!¢BúûX¡PwPI;ŠRâı³3MÊ”ìø>–]i*Ùµ÷K(é–ëÍ
ßÇòK}Üx7äûXvÕrNÍ®¼O/!Vâ%äûÒ*[M–Óº²£Ÿİâ5)$F+¡¼OÑ¥ÕQııŒªbåÎfÍNâ\”V.¥kHã”uGÈ¢S²Š€Ş‰¬ü}Z ·i°ñ}Zv Ù©Ùá½–]¥"26Zgè ~':µâÜ‹¢p½fÖÑÍ¿7Åİhâ(EŞJá1Ñ
s`n1x;•%YÌ+íVĞê"¼;ô/„)ÿˆL5(|ï€$ÃCÅö¾q(Å/ôâ¾V<º¯Œ‹ú£²Â‰WfçáGæ#€û’å\r¦ÈOèZÇ4éÓ,_xTÇûÍ?Bäâ™$ 4a>ÙeäSü¶Çïk™!óF*Îa&Vªˆde¦m.^‘å}FÈ»w$Æñuö÷:¡ƒw–Ÿ)BB+„.¤¿V~¶¾³¶Z„ÿ>×ËÏ˜6$‰Î²è8”Y‡eÂX{Š0V>­q(ë f}¥ò¶VYMòQü‚c
Œ£S›¸ƒIÿªdTÅmX1EJ½ò‘u*~†©‚¿Ñ®÷ñn‹KRgbvıõ Çyc—¼şú|!ædˆN‡ÌWìC\tq#ê½W À(~Íã}-Yßgğæ;?ZšM™òDÈ ‡ÍËÈı0M—ŒÀ¯ÚŒÒ“ğM
OÍ	´Hy]SnÿĞ‹…Z(Sº ‰~´"¨¤ ÇB-(²´£“ğ14ñSğZkN¬¹‹5(VhIMzéF{ÄlgEïòSvºp½+–ï„ú°¿î‹Ê{…`şÖ¯§+tÑÇ´¾¿{Ó÷p=22ëbƒŒ¨é"e5èk;ìˆo1 ¨}HGÀIqîaä-$&CôEÖ&”Å2V
+$/Åû‰ÒzÅ¬á)ÛÄ 6obó–]Qøßå®©7ø JU¸ï\Ç=×ÿ°ÑıDVø²î'şr¸ËåêQ¦Š –Èpã§¨^¥Ol>*ÅdıO¹P¨³~ÃÙx0Èk0/áğÑğÉvˆFTB‚^à”ªÁ0ÒÀ€ µp€ \œßJ„“²!Ê /nt+ƒŸ]Ï-)YXWŞäÊœØbÎfclN6Áë=‹K>f›xàAÙ±ZÄü¸Êü05WşN©69p±qP3«WĞ@B‰p01‰?D·ZÌ¼Á&ëù¨ Ù6ôTl/$8Öòb©ÁœäµË‚vn€+Ò†šïH™R]Òk–ô0Õ¾°C”¶nK°q£—^iwVÌ™£7ÜçùYïôdu.­R±k]—°iú¨Vr£h	u·9ÒÕÚæªÇ
É[³9ÅbºxâFhN¡æU¹9E—®ÃDLMs1Â‰˜Yî¶Òæ8ÌTyËºÖ¸‹ŠÌ¬ŠÊzÙg$Ş¹+)şq33È›³#İ0=^aAe9bÚ3ÚM€úAÜ„¥f˜Hƒ.¥™a™G¬•5ÉWtÕƒtm”âz.°¬‹¾ìKÅ¬ë¾ø{“”]Pq²1{N+©øşT³ØNŠÌBÂŸbò›iN‰’¾¤	a¨ü=º![’‡Ô9\6f%®ª" ©¦3±$.`¸jë¶¢Úº­©¶nG@ü'£šBì~éCÕ™sSDÆü~B/Ø‹Y"e8è“`_öÈ¾§4
"lØbU+Îì³¢G ·Mùy„ù™ÑÌÅI¿BÇ¯â,„Šc$šp†~DWnÍü„F¹KX…_ÎRúì+a‰Äù³ éÒğÏ}°OºÓ0´4êV•„ÙxÈñˆ7}–^@’É©FhpŸeYQÄC¿/Y â~¶(Tá¸[Yt­y§‚è¹3QPš½/<¦I&å^HéúÂCÌ1n©¾"‹J4¿™ZıÙFò÷÷~
Üy=¾eİzdh™ny§‘YÄˆ“Üyd>ï¼Ïs¼ˆ=[¨î)ïèH¬p›XÂ!Ù\ÿL¡ïØíL…Ö¾ãnë}ÚV=Á‰ïÒÚíNnKoğò›´@ùì£;pˆâ|VudÅ|†	eá	eîå¢=ôÒ	TŸƒq—´
¤™¾hÕ|¬1j[âŞÇîÓš¬yŠg½¢P ğFúÁt0ˆ\„1·`Ù£)¤»_G>Èäw¼™Ş¹æi2Ÿâ$İhjfyîprF{²o°S›¥_uJw–ÙSî‹ŸÙ†Å&63»œØ¨ß¨ËêùÂÍÈ`:f7&µPŒlMß¿Â+†Ca¢stˆxº(9İŠŸ1ÎÆWv9ø¤¥ïwy,Ø[ƒKxŸQ@Eı—™±·‚j¢KØ&®*ì÷i“ê‡!u/8–LáÌØˆX¤"¢úÆY
PøÜ¡oòÉö¬ÊC×1/şÆK’ñŸŒÆ2šíêÒ|è†aú•ÇÂù‡sßîA·<²¨òÕhdÍ½İVâÿñù¯C<ş×c¤§¡Ö^!Œ«ÅDFìâ·Zn©ë^ş÷ÿŸ»û…mNlç'i°äŒÆ,rÓŠu ˜‡òhÿá[Ä!c%0‰ŒÃGV,Ünš`.ß2ÇÔ/“Îã>_hÎ¤Š!Ô¡7Ğ¢6ßuş»‡•íiz‘ş†P°DG¿èŞ6pFĞ~ß	¦¬!ğıŠ}¿ö¦pHDxÄ¡ëñrÛ,«¶ÅòÀ5"’R,éT²~AoôÖbÄ{Â4 †ôßŸ S5¨qè1§˜®ûó€Â6<¡Ú0îÊaÔÆ™é¤tz;,Óë)Lƒ=ò&’E¿ºp,¦Mä 1©K'æñ¿(V†sc¤L>»TéD¹Px&‘æ‡pâÜd§éÙ³0ÆÙ³gbX6¸a.I
“IyŠaéO]‹i•	–ëBuİí“©…cÀ†@úÒ“›‰ş¥7ÂÑgj§)µ`¤1gäÍ	¢ñ*óÀ+ô†Ã"œ…Ğ·å«N™ì±ÌW'¨‹0dWÔå"xÌÈgeßq§ÈwÿıßıGh¶q—EÕÂF¦ÍÊ˜ş¸O'Ğ±c³òycoÓ% ¾]é`*/Xış;¢0Ì“©Ë¦Ç½æşÙys4€Yzúo™¦ãØt…êÑ©ãiç„óĞ(uöy\7a½y&.Î¤a;Lk™|F"í+«(‚Îgaø`­a°X=|¾ ¡ÿøÿÈr¡ıïÜö_+äd>-Û§ïHeZ5*ş¬U»’¬Œ”.
¨¬d%£~f4¶k›ÛÍMæ©æä£êáÕ”¢kß	BR-ë¼™YĞD˜fáë	j)qbGï˜³
¿ñÍsº‘ÖJ—ïàï>ùF1€xşÌ„G „–ĞdúÏÚ(üÆ"|„ï_v¢S<®?7³¢9­(E*ô‰ÄúLÖŒô7Â çt}¸ËlpÔe¸„¨ïÁÒy6-6¦*4Õ%Ô'+“ÜâÑ1'çS¶x¨ÂUÍKŠl†SXo| îH†?§/œ¹XG‰€)Y“–Äa”Šõò¼*l^:N«‚L¯"Ìu1^Q§Ñ©,İ>½ÏFi3""cÁeOè®ş
wwŞªÛ"¶aD…ıyÑá]HFÃñB*!-óø…Œ>è8^öa½8¯Æ”u9§F±ÎO«“š_©C4ñZmF¥‘¥JJµáÇ¹«<:Íé­ØìÓ‘®2rl{HqÖçÖı#}w
ºï³}r›T‚Ñ8±Ç½sÜ$…=uk¦LÆš±€¡ì=ğ]GÂ7°]éñ9øøE¥Ÿe(Wê?{&[\|¥]nNdÈç‘¡´^úîÜÏÈšdÇ¸'iÑKo¤uß°v³±8}®‡Ì;²ó²¬á'®ğTş¥2Iã&¨{¾©V€û¨ğ×‚½à-‘çS9ŒKÜEb0'^ÙNöf©Z+­3£ºİllW›·ãGŒrµ\•ÉRj¿ÿ’YxWÆİSÌ,ñ†Õ„X3:ô®ğ)”×2—
JÏ„”f/Jvâc0„Ü!Õt;iF®„·ş3Ë¦Ùù&«¯0 ”%Ï–ÕyeÃm<Yvn¹„%±¨3òi:B´Ÿê­f{äóRl­4§Á‹`ˆS—9ş"Šé" tëèLP-é"€5ç¥ N³æf€ı	ÓWùÑ~o”7ËÕ3£U›	)
ö›Ä¼l:¤Ø×˜{9Ø°”x}3‹‰ÈN¡ÀB	7E"‡b,ÕmÖ¸ G-´ºÓKÍ[Ši¥’ÔàÏ_MéåXGé# sû»Èê{ÁÚÈ¯ùFºîš]»((¼Ê sÁ•}ór6JDÃëk^Z>ŞDüB—CŠ½°‹FC Ì,H°}€o®°¿¢=\’ò¿’Tßp,PŞpa^A¸]+Xt‚](àô+¼E(hW	¼
eÅc4+/ãÏêE¸|ÍÂiñŸ±*~¥ «²R£S«?Ñk—úÌZ=Z@`Ê¶ú¦Œlãàs§ òÎ'ŒÕ³se¼”7üi¶<¾Î€J¶F‰-¾úgÌá:ó+ëX4ö]Ø‰?}@²
‡+ş&X®Ö°là0ÏØlNÀüŸÍÄÄÊ™t˜?ŒËLíÅWdOä;Ï<¯M¨©/“IJ"Ø¬êpQÅjç;Î­!)[¿+Æ”¬Åšz7h
³{;€Â)0öSsHL›Éä™O:¿ÃXV2t,Ïs›İwšÂÚ[([Z”ÙEcÌfÅ—iúÜ"²lRT„„6eDC~9QàN àÕN±L”.Ì‹.¯QÓ¢®e£ùuº;ÔÙÛoØwáAcF8S|­¡Ú¼\há·™pGæ{J|¼›¼B×^Ì>Á9¿2dœIHİÃ]ÔXM=sé^yîğZ"·Ğ11O‘ˆ‚úmkNt/¥¯
)ËŸœq}V&À¼zàyÅ‡*ÏÆ„÷)ºw!ÏBñª L»Ê3U@qßeR FcÊı†d^RPæ…Ï‹¾EQ.1sü×ç¬’yÅ9ê<}Š~D‘ugb]8ewŠ…Â‹ëP®ñL^i¡°oÃ¯¼É{.VF#
U@Å%WB0Ş¨Nı)»eá?°=\Æ¥JÑÊpè!ÈF™"ğ¬
›|Q×š‘(–U*$ÜTJ¸‡ÎûÔ›Ôú8ºTÕ„µetiÃåğoSÅâĞŒUŸX“):ØàNğ\……}ä·Ã²…\˜W&Ga´hÍ
öÊòËe —Î%9*"¿P"dâFâ«"D@sKÜåGúIálúèhÍE‚¶!%¸BÏÇY¹¢Ğ0+á0â‚}byÅšSq÷Ì%Åšº„º&¦§\(|b H,}"»”“áTédLQš#Ÿâo0cD¾Uˆìş…]ÃŠ+|ñ›9¶[GÙÑMŞq»Ö–/œÓÂ‘‚a­ÇQV	I;"\•eÖ!qìŠõ<Š«·T,&Ù oks9Éâ“‰÷<r37­øzC\ÉğßèkŒi…p§‘Ú	;şˆñ†j,eÊ¨ò­!>ÃøE2s0}Ağ^nL¢+üúF×Yöu>4a¨Ô9@J9®Ğõ€©ë› Fƒˆ÷Îİl•É¾'ºä’İ€ü+¡w5ôê|IPÅ÷/T&FbÖ ŒÌĞQ²6¸2çju/«z÷4Œ‹ÇæÏ!÷$¶¤pfDmÓ=¦Mi´Ş³î%Å›i¶‹2ÂÚ§¨rå
›OîníB\`7yf¶5ŠuÃ¤ÿØxÏòôC -.¡ƒ–1LbSG+Ñ·„:{Ú¬•#93Ïu÷°fL+¤"H5øY7ÙNqNiæ'¾)ì*òFVdÂz9¿í!ÕÜ˜VL-MMÆ÷Œ´òH·Œ—ÉÇ#&ÃTXvèÒ˜IAê½‚£¬PGz5¤Ü[UvgAÕ”Øæ¤úgjæm/z<FK×Ù)±­efLßîR7=2#ëí2ñŒPµz‰¼AV,Ûë‡=Pğ1~å–Úë”d\q¢Hx‰Í«N»“â`ÜŠ©>Ş§jõò¼LŞ„ì)ªhğ=“1]ê@”Ãæ%®Š²FÆØ˜İÈ™ÍCÖM’SÉI0¶Jcb74Ñ’Êïâ–¥ó¤‚E‡:FŞÔ8?ÃønôåXSTt8O,+Me‰Ÿ1§!»W=a¼ğ^\9ÕáÈ²“<Ã¸¡>²ÚclsNŸø$wQq+Üİ³kC0Fkkn%|›(Ó˜Šª“Kô^§ŞòÒ1tWjÄöf÷Z‘Ê!j@T!ºÍûŠp*ÂÛSæïŒsTP¸/¿µW½Ÿp7Ø0±áTÔA²š«ÎRV{Y¥ò’*EüVÀ3¯?¨•êÓ+Å<zUÙ)}>XU°<æVy˜Ş\ZÿîT©@İ´2ûlUèT%õp¼¿»÷Š!?*¢MT¦uuvàîÍS.Diš]İ‚P ÂÂE@yà•**O©Á8œü¾qùù"ºowä|
ÔÊuŞ„Ô+âÔ~§İ7±2€ïœ¨JªîiJ¬»NŸuÔQw”²dË2víè¯mµ1õ9óÊe©¸0k«ºbÈd	akğ•ã™«X‰ß­Ùé“dƒåãIò„)F¼qUA	=‰!Æ;.ø)(PÑÚ)‰î[A“½´6@EY›Šö)­¹J*™IÈ‡²u%ã•§nã¼òáüÊ’+¬ø¾·XÍìĞò]t@	9ı>õ)õñ\ŠŠÚ.N<}ô½KÊÎéçŞ‚åğù·ãÙ•‰µ†ùñ–¥ÅP‚Ì‡ Xb óÉîbÊ®ùóLŒ…O;/8 iÊ›2.Çš¡²º@µ¨j¬Ï¸°æ¥†Â¢ş—ş¢~­&u*ê„¼±¦…€âÿÓ E2µùàbá ÒÀÅ%qóÆ‚¤e}³€‰YL9‘W½ƒÏ”È"Ö•pF+E;)Çà>şJ±ıv°o¼ƒ\ÎŠr
î}CÃÜG"Dç`'é}d`Õ9„hG¥İ‰é‹$êÜ"- ü Ç“	äLëBŸçĞL…/ØîÄaš¾‡].kcëOÛ¨b¸üâÒÖTj¡LŠ¤RhøŸêß™œàeT‰5©GĞi
L3mˆXeø	ıl„çÓ!Şûyn’°˜ÊÌ
hªÈ@ ¥åÊ"˜(@ø·Å`
»Bo(€Ñn`cw!Ğ**~?£Ñï£û1ošÍsZÂ×Â@/ZŒºài"Ôfà§#‚à§Öá?¸	ß¨¢ÈKñÒñ2!â7<-ön…ÀÍ¦V¡_hv%%# ¤TğøôJk’h0SÄ4	ãb9#œS¨ÆÄô)$–"V4HêSØ¢[ÇM¾ãÀêbvqoÈTÑºÌ%¦•Ëb‘³‚ö†2v^*¹;c†‘âyÁÆğZ„Æ>
­"3N/¼rG5D †Ç6õdÏ÷Qi_è	1TaJ ıé9.<) „úñµ@¸™„·ì_æLÁI¥4´–¹Ø*üá5ü;í¯âMTHPWm-Ö.‚`ìoW*ØĞò9Ëã<ª0zli8ÎiPb¥üÊúv¡ğŒüĞ•ªüuEàÑ‹ÉĞ	u+<ë:÷§ı‘Ã]u³··(_Bëlàö/æ°@Ù6…×>ü•M¦.³V‰êŒa‹¢2ó‘µrµLşäM¤\¯Ï®ıM˜ĞñµœbQ„˜ù›­»ºº*›`Ù›œWDu~eïe÷°×-ĞçÀ›ßİş•6ËÂ˜~y^ô4ÛÿCµÚ€‡ĞÿƒQGÿğûxŒT™®Ê	Â%ZÕÈd½°QOOñë1.Ä´¿Ø–Œµ†îĞü[1v£x…ÏÚ4â>-‰7ìsÏÉc&¶şÅˆ—ıó!ê˜³şëíz#îÿ¥İÎı¿<JÚ¬oš5³º¹E[ƒÍ&mÔ›Õ~³ß°«›ƒz“Öê}«Ñ²íù]¹’´0L»fÒz£¾5¨·7km«n´õ:4ZÕ†¹ÙØìÓ-Zô•ÒqÅÎ~­a·z½Ú¬Ù¶I[ÖV«Q¯Ú[›F£oµ·úpŠi6M„b®`j­~½ÙªìÚ–YmÛÆ E«-«	¸d-ÓŞ4ëv«ÖTKG¦ºLÛö&4»Ö¬n5šÍ­~µ ›ı>”İ´›sĞVJKÛV6››í>…ö›µêf}‹¶M«^ëom57iÍ6Ú¶…%SuÔ-:¨×¶¬-kPoµMèyÕ„¡3êÍşÀhÖjt«a÷›Õ@”mÒÍÍF£Ùè››Ô€ŞBQºÙ®×ZÆ _…ÿlss«e¶â•+Æ[›ÕÍV£]ëÚ}c00Æ–İÆlÕí­Y–]­ º16›-»50íÖ&İZf¿jmjÔnÑAµÕno5ê£JÕbq£íÍÍv“µµÚŞÚÚ²ëMÓ6úıúV«]bPmÃ@ÖÄ<“{`PZ§fÛ¦µÆfË´5£¶Õo4¨c HÜomö[:¬t«ŠÛÌhÂšBŸÛj}`YÕAßªY6¬&5Œş¦Ym´[í~u³MM£j¬v=	J5æ -»Ö4j­­A£¾¹iš°˜ iµj«fUûõMZ5¬v»YËjoK“nÙ´Ú€IÛlÙ[[õ*Ìu³ß4›0	†ÑÚjnÕ†]³S (æ#·Á¸ôÁ¹#î%€İ âøh7ºİßÚÜBz·Õoú[¶±Ù 0áıF»1°L ~
¥ZÑÔ€›¥µšAjõ·†U«ÚÍZ½Q­×ífµ]3,ÚÚ‚ıP§XÿÔ óšõ*P4«Yk›ıAğşnTaÕØfk@ñÿv[ ›.5«´¿IÍ†Ù,lÕ7ë´U¯FuË‚ÿëmšÕ¦µÕhÄÖXÌ8©VoõšnU›p¶Şj™ƒFÃP¤Œ ¦#³µ„:Ş•T(ƒÖ«µ~½]ÚĞêæfmP…²Ğ°ÆfÛ ŒlôëF­a 04éRÈ<Ú]n¶­MŞl,ºi´ë 1pÕ*İ²úf³f !/jqAç±¸1¨Ã†fZF}«Yk©7¬–e „Úæ j4¶`Í†ªÅÅ.‡Å›æ&šÙL³U³aLl˜Ú:ì0­:”¬×aEÀ®O¸ohõ[U¨i³Ñ¦u£Ùh˜`1™fµÑo™@gšØ¹øV©[Ò5'ª5ë&4Ô4û›ı-
{£T	zÒÀ¦mÕZ°"dIyœ[ˆED~hcQÿ°ñµjµóÿØ2rÿ‘Ò6°e×1‡ÿoÔ[†˜ÿvø@˜ ¼ÍœÿŒôô7Œ³}ÏÌ‘–yˆ~JVöìm²²t°¡›ÊÎëòmñ’cÃ~zc&¯ü-é	™äÚ‹İŞ:”é™ô}ÕùÁÄô}Jj[dÈy›VĞŸLÏÏ7HïÊ	~¢t=¹ôFã…t™§í„Z>|ïLƒo"¾÷Øj\rÄ¤-dÍ£ş:šºÁ»2—Àü>c€R(İµ ,½²oúÁK.7yqÍg`wõrJüÀ³œĞKwDùgÓÂ3­Maq¡Ş“b‡=`dŠ‘³AÕÓsDÚÜéâ9'Å`
‘×ˆlP—;EĞOò­ƒvÌ×Ûğhl•«ír­j´!@Ùãm—®G—Ş€’ô‚3¾+´° ®˜åJœQ?‡ùßŒôÍ¿:–Ã5b¥P¦¬7€AÎ'Ñ„«O#ëDTr]õY€\¼®°…û'á¦=rÌN¨¤É,†¸ğ(-İ³il™×y*õ¸$BšÅo;Ğè4ºQjF#‡‡M
Ìs~O»¿öòMïôè`ï:§{G‡eÈÂr{¾ï¨0|ÅÄ@Œ	Ë˜tH$ìÙ-¤ĞõÖ4´64}à¸K3¡®ÀÄ;æY •…ÀtİméúBÜ«–<ÎÄükù!4İùÒ4í:>µ}IE.¥ÃªNU(ßÍ‡)œ–(³¢¨Øİ >ˆŠ?9´â›çN Y4J„—Ô·Tà¡v%S^dY“n§T£HM¯7V§n×…GæÆ?á=J…‡\¡Sh›	½Ü<e€w=¢›k>˜î5^ã2„U\IÚâSvñ\^:5ı&u‘?ÿU	÷H8ÓÌĞIJŒ y÷µVèÿ¿ÙªáıZ9ÿÿ(éoşå?{òOŸ<90-rÔ#/©¾{ò·ğ§ş
ğù¿,²szz"~b‰ÿşy,Ë?‰Şÿ+àÊè–‡Àu¢¾8:¦xzÜÃŒæ¥ÿ€ÿvÿÍÿø×÷êgRSL^ü uÌYÿívµ[ÿõv³¯ÿÇHuş0	ÀÏT%øy t—*¯„[)éõ…i¬1û“,³l€§%©¾¹§’’q
Dwò¦ƒî€B#µ"TCCRaãŸZˆğˆP­¹pŒ.®¸ñŠl>n_.k70?ğø®s²óz¯XzÃe\´±³úvúû·Ûo¯*ä‡X\²wdUæ´ì‹XĞè‹™¡-ÊĞßQ<*E¯‡ZÈÉEjrú©á¯•V<C–R„•ò^¤æU2³¡MP”ÓëGMµÈŒÎBEà	Ô tò5€‡×ò ¾fƒïN½©æ}ytøjÑá3ñz±.+’„İ½“pzCÑÂø‰¨â
€îß3›‡ Â. ]y±c-êÃéOhÙ©ØY	øü$z/:e¸h…É}—VlÑrRüáú§Uö³ÄH4ìîê@¥:i·b§0;SÚÖã‘3C,Œ,n{.’Àâ+NÜÇ—9h9«X°=— 	]i «–°Ì	Áj”©Ÿ™‹We½9B}uRÅ@ 1HÉÇ%ÿEf~%Óp6P\%QnfÖÏ
µğºğ¶¨æB2Ì…ÊÕ\H’¹0ş¹’+™CùêõõaÕFÌö¡¡‘R©$­/Ã|‚—lu©ÆJ¥R0õØá'ôËŞ=$EËİ‰¬ ˜]Ç¤(¾K3=ÆÂ„fNQ#&>¶"Å¦©Tb¤óÍŒı!^è %-E³½3€ÂL÷”Î¬¬ÉŸë³»#[¤ÌMH§Ã!=÷ iÎipÆåÊg(D¿ù'FÇäKÈ.-ä«ayguèc@ò3¨ßò†ŞdÇœ^˜agu+ìïwN»;/	f®æ0fJÏÕ¿GÈÒÂ°Ã	oÂ0˜„¯|ş*­=şPdÇÁ{ÆLyĞ,È%µêjäqp:æ}†=L Ò„²7«³R…›UEÅéíŠ3*¥8 Ãí (XAño#²¸R@¼ßYÕÌ>Ójc•OGŸ·1ğÚ02'×²YÓ8â^!½œ´}sCTEœ¯ı€‘’EâêÖŸÎÑ”­tIŠÛäèÅ¯T‰<¯Øô²âN£å~éx;«—N"Vr`öa¹Üçü¯ÊU-½eÉ0-(ÿ­õz­ÑjªÑlÖsûÇI_¸ü×òßÿùß^>½W?ó”šÒut—[Çœõ_k·ë~åëÿ1R.ÿı¼ò_M3ş)V­®gHƒã¢`ÕUJ.¾{~îâà…Ä‹ŸO|FÈSnÅøÆLï—>÷;¦bû°”â5ì$ıÌjn™Çÿ7juvÿ[¯¢AGöÿZ;·ÿ~œô”XÅ¹=×‚$¶¹NÃ½?ÔÄæaıV(¾¬+/{áÛ†xÛa‚1ù¶)Ş(Â4ù­…!&Ãƒzp=F/&˜{ƒíá_»½n—p÷f½ƒÂÓÛ®%Rˆ‚~nõÍ­m£Uom7 monÁ#Àıuiˆ¥[Å-·yü³©ØÿTÔÿj¶óõÿ()·ÿø,öq+ÔŸ+çŸa’Î¨ç 3°\NıqøôÂ’Yï/‡ñæë½ZĞÏMç³š+?tÕÅìío´«†Áì›íÜş÷1Rd¸ÿpu,8ÿ¨ÿ[k2ûï:àB>ÿ‘b.V¤Û¯ÿz;ŸÿÇIºK“‡©cÑõ_¯6ÛÕ*Óÿo6›ùü?FJø y€:n¿şÑD>ÿ‘2\-µ9ò£j´ùıo£ÙjÖpş›FîÿïQÒSİğO=¯…ñ~ŠÎµÉ ô-ÿ•#ÌÄ
qÿm9z)âÿ¾ñ¹B´Å¢Õë8Š#1¡îó‰9ò…ãÎé·;+ø÷ö
uQU}ÅvÛ#- _áŞQ”ÎÁÆS¡)Rø×%ûÎ“Æÿ+îß–[Çí÷ØZùşÿ)á¸ïêX”ÿ7ªõvµ÷¿Z#çÿ%ÍsÜ¸Œ:æğõzƒİÿìOå?íjÍÈù¿ÇHË’™Ç/æöÜÁÄôƒÉ”E:÷6éq7©şç¼“‹_ÇÅ]•.õ.N+¿‡ƒ-¯]6jåj#vı¿fãqUYD!n[ÇKvYdÀØ][êE™-!Ôõvw÷‰Q®’¿#¯÷10Å2ÇöÀ³Y0ÑŸRrî`xŞ=rÁoØØ½Ú
Ç…Ÿ#qßç
ÏA~e:F5pÄ”Ó£İ£rÔ»%µ”Œ!¯0Ş©ª‰€ñŒÙ°´¥Ê"oùœk«"®ãaç »ºAŠÌµô/W\— ÆaÀìL x8@ KY~¬|åÉWDiÅzÙ˜1#."!:n°‡Ê­Ñ:¶á¬]\—…}(ËÏ*Üëí+åkQù)í²ºÃË¾éuO°àíwéXÅ°á°âÃ²EÑÊN¯÷ıÑÉ.`
ã	6h•ã7æ‡i›üğ•ÿn56_Ç²‡qÉÙq¢ì‘Z‰eF7ƒÊññÜb8£o¢ñIãåãfäÆƒÜ‘uí÷û=¹şùFø›5Şß0}8ÔÊ8lH"ÉyŠÆ„‹ÆcV)Ä!µq™UGêPY\ÑøÌ+ÚNbœº€êÀ(~î-ö‹N™î¿—XÇşvÁÄù¯ó“r£Ç6úøÙêzíK‘[=Œ9¬è.ÅuÀ„Õc[\e£ú¨1·®‘ãÍxT‚Ù•è³3*
>²ıceM`m°‡‘ã£Ó]ï={â¸Ód¾óü¬VßnrÁï¯4¥Å Yvóä?ÄşßhµrıïGIùşŸïÿ‹ZyøÑësûÎ|¿Wš°lxW”¾^“Á£	s·âŞ šcôèPG^ºP_jå@‰·È3øÏ€áãìFÜO½~q…Ó#¥€¼z³¿OJ#ÄóßCn»o–­òü9©£±šMqkÏk`ølÃ½;®5añ‹ÍÏ7ˆÕÚF}£±ÑÜhİi8÷_tº‡§/eT…êÅãd­ÆFòÙ¢ãÆ†¼İ€}î}øs¥9a—RÇ<ş¯Éã?ÿ×lmvÿÇôÿrşïáÓÒ,šïŞòğ3rgX;ò1%…;%ò)ÜZ9gÛĞÙ5ßãØTL‚¨¶Ë0ã€]b…%“yv3§raòËàiÁ^Úò2¼ña¤õÚükhãÈ
†„º,,ëi¬£
÷&Ëi^9˜üoI5¢&˜¢
›€¼aœbCkñFP‡Ùy÷˜3:é—¬±›Œõ2éØ?Âê$ì"€œO<ØÁQ·OƒE±a·kjœ!âe”$J2Àª7r·!ÛÚwj{Ä'ñ 6R:ıŠè¦ø·« ËG—Áç%S*HŸíbCå³|Ø{›šV Ø,^‹-ŠÏ«¦‡ú˜*T22İ©9œ	œ)q. Úß²—2<ÌÌò¨ÀIì^a¬Ïê#ÚâIØ®Ê°óÌOBµ'=[Çf
ŸÔ'óÆCd\b»? xWØ¥‹Ñ!^2B ]6¾7İÀßqipåMŞ—aÎiPè:‰¿$…]~W8½ÓßNxÇ¶#¢S½Æ¸ã	óÜÂ÷PY¸Šwâl.[T+ş¾ûá]6¶P\Œº¨Åpîöe+í¾§ı}¼
DÍUÌßVŸÁóÆ*8h—k›ûhŒ§Á`%ÊWaœ	yÇFÏÜ;£é0pJXÎÏ½§ß&Íe½œ:æğ)ñ?[íFÿãQRîÿ!ÿ™Çÿü¼?äñ?óøŸyüÏ<şgÿs9Ô4ÿ¹PÒùAPË¼Ä:æğÿhî/å¿µóÿØl×óøŸ’~è¾Ş;ì¾+œP”òëİïDl£\åÿ~xİ=ìì½|Wèu_¾9Ù;ıÓÙ›c ½İŞÙw{³ƒ?qâÖ{sŒêâ;sè/×Š<O‘ÒÎÿËv9gı·›µ6?ÿ×j­*»ÿi¶¹şï£¤Üÿ{ÿ3ÿ¹Ä9Î¾ßµáyüÏ<şgÿ3ÿyÏøŸ·
ş9;¢çì¸•Gó!£Ş6 éÌh·Š¦º@¼ÔÙa.ÓBYÎŠ}™ær¡(–scaÎs¹ôH–3gæ-š8#"h"ÒcsNlÌ<Jo,Jïç>Ö/œbòŸ‰‰G/ôº·Ä:æÉám$ÿ­³ø­v®ÿñ(Éq/á|kíæ<¡;ÅğAd( çvv®i}îÖçé¾)]ÿk¹‘@çùHÆÿl×ëÕ|ı?FÊå¿yüÏ<şg.¾MŸòøŸ¿œøŸ‰ıÿ"ÎãÿõøŸ-ôÿĞnæüÿ£¤<şç¯;şgbı?@$Ğyü2şg«Ùnæëÿ1Rnÿ‘ÇÿÌã–¾ ^=ÿYú’ï_IüÏÄş&/è—çdÎş_o6Û¡ÿfùÿv«ë>JÊı¨ş?Òğ¿» ‰ÒC¹ 	=ÅéÇFİÂjÆıG<¬tÄ‹ÖRœ€,PÓ=ü€,ı®@2a/‘&üb¼¨²›‡u¢p«;GÇİÃİŞYh×¸Sd«M+?Úïòf¹zf4•¢îüÃˆŒBbÙ>•Â]îê£d#gù—©T]}Ì)éãO(Æá»EÑ	å¨-¤{ù¹º‰ÅÆq;gˆÚe|±”:æÉªõzÌÿo»Ú¬åüßc¤ü’6Şì¸¨F[?[AÍ®Ò(^×BÖœ1o.J\kBÿ¸ç×âÑ·`ÃÚÖ_px¸Şä¼`[Û$|YğúèSÊÂ`ÊäÜt¥wíì$¢åî°½ÓßHƒmAş9Y<V“5|é¹°útB>¦lÔ™ùç[AşÜ¤)OyÊSò”§<å)OyÊSò”§<å)OyÊSò”§<å)OyÊSò”§<å)OyÊSò”§<e¤ÿ¶ 0 