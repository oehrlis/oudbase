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
‹ ¥ŸZ í½ÛrI¶*ûœ}O>~ğ‰p8|r@öÔ&.…+I55š3¼™ º÷lIÃ]@ÀjU˜ª)¶Ä	?8Âç¼úÍá/ğƒ?Å_àğ»_ü^+/U™u@$Õİ•I *såmåÊ•+×¥gÙ¥gœÊår³^'ôoƒı-Wjì/OD«VjÕr£^×j¤¬iõFå©?tÃ0M=_w¡)cÎÌÙƒïy?‚¿?“Ôƒùw¦Æ9tÏŸzEïâê˜=ÿ•zæœÎ? @EÓ`şêÏHùÚK¿òù_ùM	Q §{¹RX^h«ûÆY]:Ø3×ºÔË#­7›äÕÔ³lÓóHÛ¼4GÎdlÚ>ù-éN'ÇõÉú«vwÊtushº¦åù®îy&©lo’-­^!oFºï÷Üép¸IºW–ÿ“étÛXz£ô±Ydi‡(^¶¦ş…ãò—]ßè696/Ü‘EÖÓÛ }Vtè³ßû| Š}g¥;†å¥WtÏß»Ğí¡i¼ºfÃßÖı°n9¾`YNÍKË³;–E¼`ÙN¦îÄñLéàéö]kâß!Cş\˜Ä²¡kvß$¬‡D÷ˆkúS›ôÃÄ‘p|Ó­9»€yôø4Ö-{tM¦iãÓ¾´\Ç¦“
“sáL}rö}» UÃ+ÚîL+Ô†À.|âí”JCÈ9íáè”ØˆyHâ ÅÍ¥O+ù°Êq¯wàkY+–·‹•²Ö „ E!dß¶|K‘KÓÅa„<Z¥¨i˜§)ò´Œ
á2šğ	3;6qˆ)ĞÑâ,ÎÙƒJ±õ“îCÃî=g~¢‹íømûüôøøì¼}´»úYú¶SÈÚøC\zEÇæoh:¶}¼;r\ÖÈtä“ïõÑÔôîÑ¡Ü÷ÓîşñÑ.Ìf®}Ü:9éµwóg§o;y²`ZÜÕ{#“Œœ!XğAŸLL , ûÕq·³›İ:èŞàF– ãjêîîŸœµ;»«ëˆá6Ğ²ZŞÈœ·÷O;{gÇ§ÚÍ—üñ$O¾Ş?€ÚW?+nJjñâêj>×=k×iµ;§»yúÉ“SÓ¶úYªı†¬Ï0óá»Ù k–¬>Ïç[û­vû´ÓíîNÿŞquXÅşE®szz|º[ÎÉqÿ™dà^Oí>"Õ}[îêğv‘·>4×7Èç(mm[Şd¤_³K®Ñ)ÀBŠÔôQÛ9ô†$¿ôú˜ì°Š7£“ü®pqé’‚E¾ÅÕ½8q´×yI
mò-°Fû>ÿÈ>ŸÀj¿r\ã5 ÿKò!©B
IÈN+'ë>ncØÜá[JñË¤â	+%¥¸›T¼aö?ÒíÇ5'#«OéR
 ©ßaè{‰è»CúönÛrÍ>näP·¡7n
¸Ä¡{OÈ„?¢´$¥tlZ0ÁØ„Ø–œTîÀRòüçƒã7HnX>k@ŞÁCí††>)“/p·s¢›{#S·[¶ño§–Ïò­~®ÜĞ×æöZ‘/Bñ’Ë—	}>°r7¹¥ïu‰Kë!£Q¾5¦ËxòPKúúFî3íçşÑÉÛ3Ø$µovß$!!MÀëêMœ­{‹Á’	6¶} ×0äÔ°]É A&:±-àÉÂ~Râ»I`sæ$_H~ƒ³ıÃÎ9àÑá	l,°%$ÿwßü©ğÍ¸ğqşÍw;ßî|ÓÍo¼x!==M/jÏ)Lw(}‡zÿˆµ*õæór†çì½’¡˜D!ÓÓûá
ÈÓ1ø&Ov	g¢‹AdìÂ¬¼´ş…ƒùÃ6à"Ê“/¾i’‚.­Ç ¤²®fƒ	²Á’½kàß®.pİÓVcµ¿öÒ¶RÅm{6+òpnï{8œ’Uêi¼·†c›qÚ´Äi{ù2©O_Ùè'7rñÁ{úHyC@¦ˆDI7Í@¦ ƒ@½€0~²ü`æm|	Ì=N’5$ÇAöòF°ç"u…6Æ=ËäJ“²E…ìè&Ù.†‚.’àH<$úØ™Ú”×İáÈ^‘taqMé¶†ä½ï¸Èw˜½¢\EeÑ*`²[ûÆ¢ğësáË\	e Å€Ó·ŸNª‡Û=Bµ^İ¨
¾œ¶ö:wsşªÕôÜZi1Zgú°òP¿Ô­rJ4mä=g:2(ß™ö/Ø‰û¥û-ÀŒİ ïW?wèQ*ŠFÊàªsûÛu`·ï°Ãù :frùÚÜò×…Âæ”‹P‹Ïí+Ng×Ú6ò/\&ÔwÆcİVÁUî Îğ$=juÔCËó(gç²eŒ^·"ãÆª€Z lÛd$ñ;èÏÈä½¶ø¡Ç8(ó%,	Ùê',´SiqYGº¢T­£Ç#yÜQÄ‘²>K‘â%øV‚ü­hŒDÜ²áã˜²¤öoooDN*@!Ù•nÛ:ñ€¿ĞG#GY¦¿›KvŞÚmçÊf]Oá÷
˜YJnbÄ_mÓ©9v.­6‘¡fk>(2'îXYyY2ÌË’=‚,+0¢”35Ä*	¡SÅƒ°ù9®Ş‡¯¦C:JwPÆY`%ŸqJ’ª‘óJS˜\€ojHéøå¸Øîøõr$+LHÃ%¤÷—C4†›E‡ÅÃ)L,¬(<ğ¹×9ÁR‰lŒ¥RÙ)†	Ì¥À1Œ(&åŠ³šÊq·¢çİEH.h;T4Ÿî„éÍ%_¾À›ß‚y-7P©U+CmX×
.sIÀ+’ÕõRÁpK,Py` „ŞˆRÒ„>:CüœÉÅ	9Îc¢ >
b ÉUÁGÌçØş2©
V2Îìw°Fÿ‚|ùíoqš®H^’](İHosÁŒ¨ã¢ÉJgæ>e8)›ÉaÿRP–;Ô­{ÉŞ%ì÷]}BòJÇjå<ñs9Nµ`Ô%™.P(6 ĞŒ‚:rq IúSàöl*æ.yò|\OˆëmhúÎĞV-?q\~¸Ñò]z„#<Ñ]@åaì<ÄK“‹Kk§½óãNgÇE.481È6à%“–¥Íàr#Â§Kï¬rx-#2¢éñ	Íemc>&ßKÉñ£È!‹ìRòºä´sr°¿×:ÃË…X«:*V&Cùèl…¬>—70zF¨…Ú?¤1‚ÈÒæ‹\²ÌäŠ
±½¼¯J\‹€Q‰<YUAs*A^’`%Ãªş­–ÃLLş¿ú;¨ë‚2;ÄÄÍ×sÒÃÑôs?éd¦Œ]Ä† óĞN	
“¼!Ï 1áÎ>c¥œQè)Áò¶fı	6‰+†ëóD±/ ,û¸SÈ'J¡or	Ø+ŠÉÀêç“Ú¼#7l˜~Ã·ÈxşY»P­Ÿ¾F˜«©-X! ²®4Šà9³P`×É…k™€O×ğÄv
@€ÆŸ~>q‰éú–éaKá£°#í#h>{,÷‰$v2ú.p¦-@ê—*RE1<—ŒãØ1ÖøÛãyMS²s,Ñù…r€„øh³nÀl::»©ÇëH¼i/XdÍ+ıyµT(­É˜¥~t`{z¥÷?B^²ßfÂòñtä[¼ÛDÕ‹ Dé˜ò¦pzñÍO>2ø«¥ÏG/¼Ò{»DJ/nR`A‡ÁŸ	øÏ<×01Åj‰`Ô	Û†”åÆ.TVøµO×t/á¼…¨×•çd}ì2´¦OÖbYø¥¨i(uo"ÍpÛJİqqœJÅÊQ†‹Op_~xT¼àGEcìˆ˜ÃC–…G¼ƒvë„şê[©:2Œ°$€[ılñ“Lë‡?ã­Åº~õ‘¬½ê¼Ù?ú|ÚİÍ¿·ïáìöš~Ì¿Øst|ÚÙƒíaW{ÁZ»u¼ÒÈ_IéÏ-ÃpaJHYW+øèı·kXËÚû—%ò:µ¾Ze;¬ğ|ƒÃ)¿ 7xañ™Jè3uÆÉm«²î†^]Y0;u-ÆÍÏŸ¢ø4it”C¯nÄÒ–Ÿ&»µvó§³o³ÙYÚìP6 I«ª€EC£Ë°b¤Ó±—0#¸úUéÓâ;BK,;w§¢’¼Õ“c`á[íÃı#yóIİÇtclÙldñİ+q®R÷0¥KiÓš(P¿Ã¬Ö*êÆÇg—ÑĞÖ_
À_¤¥ëa'ÿ‚#î))K7×›ä7\?BÕ—€Àõz%Ùo‡à•Ù—êõŠ‚ºØ?õÒ<8‘.ãYxj]Ô,=~úßL…ïIô¿«µrõ¿áS³^)—™ş·–é?FÊô¿ŸHÿ;Xp¿ıo®¬+"®çdFÈû¥«~oáÿ©~kÕhAËö]Ç˜ƒ	'ä@ŒŠ€¼‰Ù·×¡>Â²µ$–«>şËV_ª&ø­ÕÀU‡ûW¤ÂıˆúÚ	Úâˆ
÷Pá©
w_’Â˜|+Í0<Z\eû>úÚ‹+kÇÛ| ”‘M¾‘òRJÇº”>Ô­áräâ™ô£êH“LG:Ó‘&™t¦#éHsùøŠĞ3´²ƒ1Oİø2é9ğ3]å[ê*/I÷)´J3ıÉ_˜ş$dí}¿;W[2]Ñ’Õ@ ¶L…òX»d%J x{MIvúÕÈƒ©Bw¬U‡|]ÈnŠúâ2J ÕuÁç‰¼_Ptë•Şo–Ş“ÒpãÁô(—¢'ù‹W¥ãd/2·	¤š©‘$K	dö¦¯÷å"‘‚!Œ´tÎö8cĞ‚6`ÆVHß5ñ4««(§1	’=jó"µ†í®Â÷ÈYëÕn¼¢„Œt8Îö»¨"Àôº.ÉÚŸWÖB“³/ı©-×`sØÙˆïE|~h¡vÊ	aãé ĞÁ{ŸĞ÷8¯÷èé€”¾ƒÅ°¥íÖYë¦ôÍfÂRS›kå†	ÏRBã+Í ‡ÂŠ¡{åŞÄ(@Ô¡Ís
±jQÂ€†ÅçïKï×á÷Æ{lEñùjé½VZÛ»&¢‚«¢+wlœ%Zšçx=õÌYhÍKPeÃ\¼ı!‹¬!z@wÉÚæœìsóÛ¼¢äÜ²#”<Ôî£o(Ü÷6¬ö›í˜¾)YXjk.-ÏL=œ	qPaQ½Ãâx‰ÅkK©pŠà»UQèCHAWC@^`ò&×'Àçšò…˜b¹åÙ£/ô;(¡wXtğrÄ+zTË²(³P[¦zÉ
úR½ê1”DWXBëU-­ Òt²I<gêöM™g+†(*Ñ«DîN¼V¹¼°ÁïÅ–ì)áû’ÂD¨ı=UıjïŸªr	¥Yé=F]=¦ËËìï‚wù”%·B^øÃsÏw‘‰AÜYÇeV¹ùüX¸ İSÇñ55v¢nVÉç^{÷n§7Òí;>¬mÄ(®µÚæ†*²û#àÁ_¹0³»¨§<!@¬0^f­ô>¿ù>_Š(­Ã%ø¶¡JÙØ2¦1ğÔän6ç~¾úYLÆÍyĞ´ÆĞË Ó§×£·zuqƒÛo‡½È9jí¶×ç¢ı£›ƒX°˜…Çói'¨å~[H/q!Eú¤f¢œ<ö˜›ÂE–olÊh·õk.1_û»o¦kp^H‹/läÊ EF0ö*D`Z•Ñ•†)¦/.C¡lÉ¦•é\Æ¥Ÿ«z@‰_DEºÇ9¹{E‡‹gØ¥É²CÍÆ|¬N¦…©Å—1 ùD
•ªŸîtö,Õö8ˆAâ4Éõuúáï´•>$ŠÏÓ§}ñqñ¦}<Ùà˜}Œmy¦¿‡¯HÛï±cÎ•½	ì§èş•«®'JÓEËjÓ(æa‰¤›¾š†.*Šxhùaè%)7CfsÎ:æãóB­\–ÿ±É¥MçªB¹ndNéäÂ‰è»Ê"„åøåZ¯Bÿ‘x:yÿ¿Õz5ĞÿÔªMÔÿ¬Ô2ÿ¿’2ıÏ'ÒÿÜ/Eÿ“uè×«ÿÙ(Âÿ9úŸÛÅrSÉs¨ÿˆ·„t¬=EÎëŠ[„¾c¨,¾¿<;Òç™Bi´Ÿ‡Bi¹¨ıl½?ªZéÙŸN°Goîë”˜³WŒ4]OÌÜ;“İÚmàp`GÓqtïÓüHëGÓœä€ÖLPup7_(ˆÏ´“¹V‹×#}˜iĞşœ5h}ò-¢ê/_—6èh¤Fp¡¢¶ÊşÑŞiç°stÖ:Ètrï€µ_•Nnæ·8ÓÉ¥ud:¹™Nn¦“[øštrRÉÍ”r3¥Ü»)årŞ.®”›)ÓÎ —)ÓfÊ´?+eÚeû#ı
iıkg¼Óy5Z TL•¨ŒúJ¶ËtšiÆ3fZ£™ÖèÏXk”_Ï-¨5Êâ=ˆB>
ÎÅÖdmû²€OeXlÀÜõJÅ¥¯Ò§d~¤Õzauå˜Ó‘Cê8#W¦ù‘ØTŸ;êüpşC§óÇ£cIæò6¿‘;>h‡/àf¼)¬~Æ€›ZüUkïoOÎ»À<Vé9T
…ˆRŠ|ƒG	ZÕ‰ õ°ŠY…Ã&$V§¨ë3Ní¨ÚİãÂŠoæÃ«YØ§îß¬rÈr)dµK™ö0¹¯§ª¼ùÕj"'€‹i$ã|ë°:tïxâWÈº¨ºÊ“¨Rfk¦Í*Q­°İøí‡ØòÇ…W”¤ËÊáQ9¸yã*¦‚İàf>,2³«ŸÕ¶H…b¯T•UEIÒÜñã::xŞsì5§qóêGJ†í†i!…“ŸúƒEÆ¨$ëá2˜Eø;æí½&/Óz=§k"¸ ÷nÑ·hÑetcÚĞ®½W˜ÚQèZIï3ÇÓÁwtÊ*}(×_¹kÕX²çØà!§x¨&}6±Œ´qNe®qÌG+¢q¼¸¶qº¦ñ«ÄE}¥â…Šy-wV(¯L“ù§£^b—Ğ°Û­©ï`¨¤¾%è–Î§iÍ#ÎÈ@}˜=‚¼İæ4ÅSˆ[dóŸ§?ĞE
	š!s‹Ô%Ø:…'‰«‘»cRp“Wfâü›™ôn9rÎxıusXŒ3H	ŞH½Ø±”–¤êÍ›—©zß"=µªíW™Pù·xˆY¤Ùúßår­Ü@ıïZ³©5ÊÔÿ®6jµLÿûQÒßüËöìŸ>{v¨÷Éq—ü½ MøìÙßÂO~şüÀ÷ò-²uvvÊ>Ñÿ~şE$ËÿÁŸÿógÏşğáE}2™Å‘îù¨ Œgù•“.‡ñâ¯gÏşæë}w@x#á•gyŞ¿ayÿu$/ê0÷Fæ¾m˜Ÿ=ûÿÏ?`îÿÿ?üÿ7şÕÑ¾Î¤Dnz :f¯ÿFUkV£ë¿VËü?JÊì?Æş#ĞÄÿ9Û~0áµÄE;S„•
-7¢ád3+‡°)Ç­@8]Nd?ôRaòø ßÇCƒgá´øLBsNÿ£é&Zˆ Ğ¡éŸ#T6‡‹	ÙıÌ•ï^/y€¹B|ˆßë®…ê5wSˆGh]“†³¦ºõ—L·>Ši—A%¨«áøäÚB`É’»ÈåßÓa^¿¡X_ä¡ó«V÷»óîñÛÓ½Î»ò8tFO·LVÆó;4¾_c*œ›hµ5ÖË¥9ó1Ğy€ı‚L®R8@­z3šúxËî_ hìëK<…•àá\=&¤òCBşeª¬…÷ÛŒ`£ø¥Pt¶˜Í‹D‚Š=0«—kw^·Ş`ğŸ6óC@o/ùR‰[^ÉÃóR&v®Vs)W¡<Ÿte-eí·áˆ«Ôk8HÔÔŒçÇ{­9õ¦šç€äŒöAÊ…7Æ,—é÷Ss¡ÄLÔ9LÍuÖ9<9huº</Æ¤ea‰“ÓãöÛ½3¹jBæKPÙm2*$ñ,ƒñ•V)VŠZ±Z,Ç2¾>üaFf&5>íPÑñş›İ<£çôš‰a>ˆÛ•1òÀÈ3q“şZLÂÍŒ”R=„SZü,–µÚéÛNAR“ºY({B×¤’Ön–V‘–—vlWÖÕš30y©	¢În(ø£–S–.„ •gå£`gÔ%˜2¿ş¢Ô©eóMúÂ¦Ï¢¡Æ"
#X™</aKD«87»z%½£w zH‹Ã‚ÇS«.0n¸»¡Bõû&OGşF?¶¼>ƒ+Ğ‚&Aé‡>`½uh#tkU0& €»Š`u.Ü(íŒ Vˆf$¶ğ|àq’«‚W	-¯>›>L«“!Ööª¿&ÍGHÕÂUŠßbs,U#—J«"tRî®JÃ
Å“ûVªĞ\©â?´¾o‰*ƒÏ·¬ìGıRgC‹”#¼O¦%¢PåÎŞÙñéŸÎ™
U[âˆ¼ƒÊ”´9Ép°'B~¼rÙÂ¾M^F"bOÎÎş„>€xïÙı.µOƒÚûTuŞQÍOfJ›Qâ¤2(HY¸6Ş[ñôæê+×JfªSü!¢—RşÁu–•6%éÿ¿O1 `ísMêÚD‹ÆïzùÑ"hiğ21n;k¿³QàH­ê£×Czæ›î« zxƒ8º[_MrÒ:ûÕõ–ëùn9õÊ‚­É5ºå‹8ÕµnHadFty%Zİú¾Ó>Gà€ÇøçFÒÂb†¹âw¡f‘@fOğj1ø`uS½†±@!Tfš‰tƒqDŞŸM¤M$ŸÔA¡L¾ w#˜ï†Ğô¼5‡Œcrc’vÖ[¶eˆ°)B‘‹ÆÜ»¼yÊJ¦
crCb¬ÇI`ğa K$Eş@ÛLÒA²nBO¿\›‰ïê\·…!¡5"~¦ºà0Å×40ïD±XÛ˜s1L0#!”)•Ÿ}½4QñöêøÒ@ÎñÀ¸B›jN¨ÇµEfŒÖ(¨zoªö<64¿u>ª½~äš°ò@@Qj)C0‚=ÖhF¢2ïÑèÛ!)`ªÙr‘<$¥i'zHT<·íñèÂTr²6óœlİ,¨K/5kœGâo¯Oıv^+UÔÄ20œm. „ÊOüë	ò1åã8ŸÁjğ‘it8«¢èq+jæÁ+•êG8Œ˜>µ=Òík† Ut “A,Uù>ŸDó8¤ûèŞ÷æ©ÜG&ÜW_Â.@å;p4	ÆÆñù%Ü‰aŠ j’
W"ÂÈÇğH‘@‹^©JBmªEÏ{,ä¥``
ö%ØDğîÖ8—†o·Çµ»âÙ²qŒâ×ƒMÈ¼£îùêLÂ8#¥Xiø·BÁD±<‰ÚÒ‘?ha#“±[Á¿dÀõkàmÀÊ¡˜a)ÓêpNébµ1‚ÇØT˜ë/ÉÃ“À°.	-©û	™Ñ½(và½3@NvÔÓ³ š´+Ë5:>`Sùµz`
Ü	 ~! €?õÈçèM/u'gpß3²æ5b¬8doÉÃ9‚i9{‹xåÈÇ¨r{ÿôœ¿Ì;—?=;#A–¹¿	™§p¡0±<*±ƒÿÃ\CÇ6¹ößı.ÜşÄ3q[Èˆ¦ŞY¸œcVÛİNg‘Vò09Ù<™Ş¢y| ?GËk ÌU„—Ğù‚§8[ø¯Ç­¶Röî£ˆ¤Òy/(î¸zdSo2–ƒ‰€P”êFEzû d»óıp^ŞçC‚ŒZ#¬U;1İõÄßas×WÃQŞˆ•dsE”òÇ¬³´4‘*¥Ò)õuÕàùY•7®É(ËÆ@´['äÉ3‘š‚Õ£,8ÍÚUóò¬çİîA,{‹š\$f§²ˆXSÉÎ‚N;'·X×ÒÓ…–pÔÀÃßƒÍÉ™„ÈMAmšRIÒIØ¡UâÑÕÇÚøİÙÙ	QSZw0k71kØ¡0¿”µµtß?ÊÖ9Ä·MyÇä[+WÄYË‡Ø8ÙˆáÔ3ûE\ótˆÙê$8ÌÒàYp•ç£c®´âÏb_“R^={¤‹bZÒçÂ–L¶‘yÂ5›.ª1H¨°èË’ô‚&…ø¨m(àî¨¢B¾;°ê†¼S*7_wÙHy»Ë4%3£•‡õ,Lˆ©„²Añ£zU{SZµ$b5ìI=áÊ $óœ‰kÙş€¬}S¨{ä›‚VÁßú±†¿=<)Æ{Ä%‘|ß‹ØëåW×t,û¼wMJ	‘ã†ÿE$	>SDF-®<³i7iéä®Ë‡¤fÒŒ~&Q’6ädq ÖfI¸bá”îˆš`8!Â£šĞ	Ø¡›Ü=˜ÕõTKó5ÙÒ|Ş¨sŒé6¶ç)¥Ñı³ÜÇÙ&=^ˆnâ´íkÓÉÚfVÆ¾£‰<X÷eP–0*¶WğFúÄøêúL…–Öï«‘÷tó»P·KzÀSÁ:QV»|Š11ÁŠG‡yŞÄa÷¦Ò© <‰Î<ÀÚ¿íšîÒÓÜîª¦îGwÆÑ_>Ø%ïNôP(wıÛEÁ)`$\ép•jn«hŠºjá¢©‚gİæ2y¦0{B‹ädd¢(Ûü„§!Ë]SQ©T(Õè5ÅíëÃ·CnCLeKETW¦“¨k¡6<zNN>#Kx·£Êòe¢.ãüKVhøŞFX[ï«JâŒÆeEQ9‘HÊi/+
6Y+ÑÓ;)P£"æ–Õ±mºİ—6K^-MÖD&İğ
ıÁ°€=¦MÃæqNï!”³„¨9V'¯ëûzjXfmüô¢ÔØ}à*O;'±NÊ¢—eê-)’„]‹S¤kgê²µVL¤H+‚&á
¥B{TZòâ*Ô+Õî2Qú&#©t¬€#]’tz“òóœG«nm'çaZ0o£ÚHÉKgò³øy·¶¸w§¼÷£Iù$Z²¦HX#¥¢B»˜ˆ+’W–Ú%
'¥üQeŠtR*•PÆÄ“3Š±»M'h~Î…A±½¦ëUY~wc~Ùµvâ¬aª˜‡¬«~O7¨ûY-.Ü‰’V‹äK‘‚¥şû÷‘GLÂ»àé„;ní¬ªÃ’—û¶(7ªF´'xÓ(,·¤¿|™Öæ¸×Šè(@¾0G	"dåæ•f–&²“·%#
:ÑB»´|NH¬B°£ïïgÃ‚&ñm÷ìøíP™•MÙ.`ú¼ çß›°Ša!õy¤P ;(¥]I)ñşÙ©&eBv|É®ˆ4¥ìÊó%”	uËÕfÏ#ù…>n´ây$»l9'g—'—+ÑâyaŠ­ÅË)]ÙUÏnÑš$£”Ç‹¨Òê°ˆú|FU‘rç³f'v.J*—Ğ5$‰QÊºËeÑ	Yy@ïXVö<© Û$Øø<);ĞìÄìğ\É.S­5²€¿	[1tÂ(\o¨õDxóïq7š8
‘·TxB”ÂŒ˜[NEIóJ¹¤Ç ´ºî½nÊ?&S
Û; ‰ğP‘ımRñµ8‡¯ï+£¢ş°,wg@¢U£Ùyğ’ú`¾$„§E1—Œ)òbºÖMú$ËD Õñ~ó™‡x*	(¸Ô§3½Œ\Áwûì¾–êRo¤ü¦c¥’HVd
ØFàâh!àiŞç„|ø@"_ë`¿8x§ù©"$´‚ëBzëÅç»ëkyø÷%¿Q|Nµ!Ix–EÇ¡Ô:,Æú
ÂXı²Î l ˜ÕÒûJi-Êgş	m(0Omün&ı›‚Væ·aù)õêgÚ©è=¦| şF¹ŞÇ»-&I‰Êõ×ƒ;Ä]üúëğ†è®ˆn¨¯Ø‡¸èbFÔû¯1@€–Áâ½¬ïsxò€wV fSª<2Àaó2tÿ L“Æ$#ğ©ò ãô$¸DÂ3İ…I+Òíz±¥JÑR•ÄX£I–ƒ¶s¦|Lü$¼VšiîbŠZR“öœñØ±O€˜í®ª]^¡§Û¹¢ùNMö×İ|^z.ÌwIıZY¡ó>&õıÃ‡ˆ¾‡í±î÷/6ÉØÔm¤¬º²‹ñû(jûÂÆ‘p’`Œ¼…Äd„~ ÈºkÒXÆRa‰ä…ƒ y?‘Z/™5¬ĞMjs\ƒµìÊ„ÿ6sM½ÉvPªÄ|çZöP9üÃF÷YeCJ»;ú‹á.g¨7„™JXL"ÃŒŸÂz¥>Ñù(åãõ¯0¡"Pjı†³í:0Èë0/Áğùáğ‰vğF”‚ãà,”ªÁ0ÒÀ€ µ°€ ûLœİJ“²ÉË /nt+ƒ¯mÇ.HYh×{¥»Ÿ³Ù˜'Ú‡Mğ|«ÿ‘Æ%ŸĞMÜw ì_-|~li~¨š+{&U¸È8È™å+è ¡DØwuâĞ­5oĞGñz>K@v4u#å„À‹	µ¼Ø@r0'qí² àŠ°¡f;Ò_¦¦‡.éKó0Õ·C¶nK°1£Û¼R8î´˜3Ço™ÏóóîÙé"ê\J„b×†.fÓôY®äFÒÓbêns
$«µÍ)T·fsŠEtñøĞœBõªrsŠ.]%.‚ˆ˜Šæbˆ¢Üm¥ÍQ˜©ò–v­q™YÇ”õÒ+N1H¼sW.ü£ gf7gÇªaz´ÂœÌrD´g”› ù¿JÍ0-]R3ƒ&RX«ë‚	Ì¯ªªÉÚ(ù(<\`i}é—Ši×}Ñç*&I» ädcöœ–ñ}E±Ø‹ÌÂŸ`ò›‚IN‰â¾¤	`Èü=º!Z‡Ä9\6fÅ®ªB ‰¦3‘Ä.`˜jë¤Úº£¨¶î„@ü%£š‚ï~ÉCÕšsSD&ìŞ5/-Ø‹iBe8è•`p_öÈ~4Í0·a‹T-9³O‹Ü¶ÉÎ#ÔÏŒb.N‚ø*~åg!T#Ñ„3ğkÀ»rkæ'0Ê]Â*üz–Ò“¯„%ç'AÒ¥á%û`=ŸvZgAhiÔ­*p³ñ€boBú,¼€Ä1’QÀà^‹
Ò¢ˆ~_Ò@Eıl-P¨Ä:p·²èZóNÑsg¬ 0{_xLã>LŠ¼Òõ…‡˜aÜR|y•h~3•ú²dÏïı¸óztËº/ôĞĞ2Ù:óN#³ˆ'¹óÈ<í¼Ïs¼ˆ=[¨ê)ïèH,w›XÌ!Ù\ÿLïØT…Öeï¨}Ú‘=Áñ÷ÂÚíNnKoğò·@yòÑXDr>+;²¢>Ã¸²°kR÷ráziù²ÏÁ¨KZ	ÒL_´r>Ú¹-Qïc÷iMÖ¼FE³ŞQ¨‰ X#=:„.Â¨[°ôÑä’İ¯#¤³;ŞTï\s†4Oò’ì‡75µ<s89£=é7Ø‰ÍR¯:…;Ëô)·œÅOmÃb›š]LlØ‚oåeõráf¤0³“X(B¶'ºç]á•Å!0á9:@<U”œÄnEÏç“+£èò“‰ÒmöÖàbŞg$PaÿEfì-§šèö†J Ë»Æ|Ú$úß¡HİeÁcD856"ªˆÈ¾q–Âä:ôM– N¿ôĞuÌ‹ÿ†ñ’Xü§J¥¦•IYÓêõÆ3Rè†aú•ÇÂù‡s_û°STùªÕÒæ¿ÚlñÿÄüWËõJÿë1ÒJ µ—âjQ‘½¸Ç­–‡[êØ—ÿıßÿgÊ®Á~aè®aı$–¬ñ„Fn¡ZqõPî?,p?¤b¬ê ‘rx“ĞŠ…ÙMŒÁåõõ‰éIk„qŸ†Šó¡bu¨ÔG¨Íw„?Âîa%ÇûŠ^¤·É,ÑÑ/º·õ­1´ß³ü)m¼¿¢ï¯)ÑñÆ¨D@{<‚ÜÇªl±,p¤K§:•´_Ğµµñ^Ç†Pˆ‘ù‰‚ï¹èTj9Ô)¦mÁş<0avMeÛb•q¦:)­îá&ãÎ&Íôf
FaW°èWVŸjYhLj›®>¢ü/Š•áA)Í®)u¢˜Ë=Hó‹C˜?qf²€Óôüyãìùs>,›Ì0“¤N¹É$‹<E±€ô¦vŸj•q–ëBvİíùî´c@‡@øÒ“›ş¥7ƒÑ§j§	µ`¤1kltÑø
•yàzC„ˆ`ÎBàÛòu«Höiæ+×ò}ÓÆ2)ê2<fd³r`ÙÓOäûÃÿşïş#´
ÛØ¦Qµ°Q¾nÁ@Ór§º7é™.tìÄÂ¬lŞèSK·ÉLÏ».u}˜ÊZ¿wA(Ô#³;µéôØ×Ì?;k„0K++xË4D¦+ğPNÏZ§Œ‡F©³ÇâºqëõpèÈs~‘p.ÛaZ‹ä\ 0IoiE!t¦8Ãk}ƒEëaóıÇüG€	íàvşZ"ïùìù”¦e­ä]ÀZ5JñÊHá"‡Ê
šVĞªçZm§²µSß¢jNÏ0ªPI(ºş='$å¢¶Áš™‡iæ¾NÀ¡–#v¦äsVá·>47“ò®pqù~÷È·’ÄËd&<%¬ „"Ó‰ĞÆÁ;á#xşŠĞäqıå‡™ÍiE!T¡%Úg²îc¤¿1˜šóÀ]¦ƒ3mŠ»@ˆz,İ±c˜ó EÆT†&¡údErˆ[%:º;œÒõÄBÎ¨j^’d3ŒêÀzc“ u‡2ü9}qÄÌE:BHLêÈº°$¢TlçUa°*Ğ©pR4`rá`nğñ
;NeìöÌûŒaè6%’!2Lö„îê¯pwÇàí¨ºÍc†TØ›7-6á…d8¯Ô¨Â2]È¨ƒãU¢/6òójLX—sjdë¼¤:Ù«ù•ZDïÈÕ¦TZª$T¼œ»Ê“¨ÓœŞòÍ>éJcË0F&ÎúÜºb¤ïNAœ!İ'wHÉOb{ÜÈâ&™ËíË[³ùI§¬JŸßuÌqÛE‘¿GßÈô³å
½çÏ9a¢‹‹­´kÎÍIƒÙÂ±a<2”6’K?Çû9Yìó$ÍÛséŒ€´nàÚn:– §Çôi`GzŞ@–5¸óÄ¾™Èß£T$IÜ„iw !åp%ö˜³¬%‚Á`üc"‡q‰»HãØ#ƒÂÂÉŞ*”+­q®•wêµrıvüˆV,Ë‚#YJí·à_R·Õ iÌ=ÅÌoiMˆE0£#ç
¿òZêRBé™’ìEÉntfƒ;¤œn"ÉÈ•ĞğÖfÙ$;ßxõ%j„²ä¹ÀÒ2¯l°ÇËÎ-³$æu†>MçA÷SµÕt\`şŠ­”f4xâqêRÇŸG1]”j
ª¤2]°bã¼ÀIÖÜ°çÒ0}¥Zq«X>×•™Â`¿qÌK§¡3Aò}º—ƒKŠ×7³ì,¤pS$t(FãYİfs°¡qÔB«;¹Ô¼¥˜T*NîPñüÕ”\nu”\p10·¿‹¬¾W´ìú‘mdë®Ùµó‚Ü«0ìSÑÓ/g£DX0¸¾f¥Å×Û€ˆ^è2H‘§óvĞh¨O€3óc,Gà›KôWx¡‡KR<aW’ò†Ò&ÌËq·k¹¾é¢E
8½RorÊUB¯Bé¯hŒféaô»|.ÓpZìcd€r#«WÊÁª,å‚èÔòGôÚ%§-
¿öÀùIÙÆsÀ?êNä]ÆÌT³3e¼„'ì‹4[œ\§@‚Å[£>Ä_¼sêpú•µúfä½ °®7‰¼@²
‡‡~ôL°X­	`éÀa‰Ù,Ÿú?›‰‰§&cÒaş0.³i,¾"»¢ ‹èLÙyêyÍ5•H}©LRÁfU‡‹*R?ß1†hIÙÆ]AP¦d=ÒÔ»A“˜İÛäNé€±Ÿê#¢T&O}Ò)øÄ²¡cYÛì¾ÓÖ¾â¸¥E™]4ÆlZ|Ùˆ¦Ï-"Ë!EyHh]D4d—9æíæ‹DêÂ¼èò
5Í«Z6Š_§»C½ı}çÔf3ÅÖªÍ‹…¼›	w¬4‰‡w3€WèÚ‹Ú'XÃ?EÆ‡Ô9j£Æjâ¹˜I?ğ:È±G×¹=ßœ}à›Á)QP½í Í	ï¥Ô5P"Eñ‘1®Ï‹ä˜W</ùPeÙ¨ÃÄÏ=İ»çx•¦”]å¹, ¸ï2É‘£1såşC2/)(óÂ‹gF_£(¨9~€ÎsVÉ¼âuVVĞ¨$2Â±n¹ıË7éb.÷ê:k<WZ(ìÂÛğ+ÇıÈÄÊhD!¨˜äŠÆ‚Õ©7¥¢4ü¶‡É¸d)Z=Ù(õPa“­#Óö¸f$Še`•r	·)$Ü#ëcâMê&}^ª*ÂÚ"º´aò@x7ˆ‰bqhÆšGúîl2§x.ÃÂ>²ÛaÑB&Ì+’ã Z´b{eØå2ĞˆKë’Š%‘_ Òq#ñd" >‚%n3Ï#½¸p6yt”æ"AÛÜM®‚çá¬\™Ğ°~5‚aÄ»`yMš3~÷Ì$ÅŠº„¼Æ¦§˜Ë}¡ H$}!m“‘îTédLPš#_¢O0cH¾eˆôş…^Ãò+|ñ›9¶YGáMŞqÛı,;§…#ÂúJÃ"´8”şZ4v E°*‹´CüØéyVm)_L¢A(ŞVæ4t’Å&ïyÄ¦nZññ&¿’aŸÑ×Õ
aN=BµzüábUXÊ„Qe[Ct†ñ`æ`,zœà-¼Ø:¨D—ûõ¯³Œ)ê|(ÂP¡s€”r\¡ë]Õ7Aï¹Ù*’‡wÉÄ»ùW!$îjèÕùÒBİ¿P™<‰Yƒ0ÖGÉÊHàÊœ«Õ½¬>ªİS0.›;:‡Ì“Ø’:À˜¹M÷˜6©ÑjÏ:—&ŞLÓ]”Ö‰Ê!W6·ùdNáÖ/øõv“e¦[#_7Tú­ç4¿o~òÅ E%bĞR†‰bâhÅúSgOšµb(gf¹îŞ šAècT©;ëÆÛÉÏÀ	ÍüÂ6…¶$oÄaEæ ¨—ñ«á~PÍÍùhEÕÒDĞd|NI+‹tKip‘:,b2Lå˜f‡.M¨¨Îñk8Êru¤×#ó“…{«ÌîlP¨ŠÒİœdÿ¬QBM½í…_OĞÒuvŠmk©“·»ÄMÌÈz»L,#T-_"o’Õ¾áô‚H_ğkôÊ-±×	7È¸âx‘à›Ut'ÅÀØ%]şzŸªåËó"y°§¨¢ÁöLÊtÉQš»*Jmsv#g6Y7AN'AÙ*…‰İTDK2¿‹[–Ê“rê;SÛgüå»Ñ”ÕŸ¢* ÅxbQi"KÌùœ9Ø½¨ê	m€à…÷ıÈàŠ©F–ä)ÆÔ‘U¾F6çä‰sg!õç·2ÁØ‰İ==Ñ6c”6Ğæ–‚§±2]®)©:ÙDíuâ(+Aw©Floz¯%Y¡ØÂ„¢Û¼¿ Ø §"¸=¥şÎÌ!C‰ûòŠa{9YP[ñGq“NI$­¹ò,¥µ—V*.™¡RÄo |g•â¹R5cr¥˜G­*=%Ï­
–ÇÜª Õ›Kêß*å¨›Tæ€®
•ª$Úû¯)ò£"ÚÔBeZ[eîŞ<éBd‘æÉÙå-*” \„ ¤/¬RIå)ñ"'‚‘ß·6;_„÷mÁîƒœ¦AJ±ÊšxEœØï¤[ãZ-RæğU¡BĞ=E‰€v×êÑZò’ SoYÊ¢ı•­6¢>0g^™Ì fmµ\W™,.l -àş±âc<sµá+Öó»µ =}l°øº@<a‚oTUP@£@€ñÖC	~
””v
¢£úVPÇd?©PQÚ¦¢¼Jj®Jdâò¡t]Éhå‰Û8«|4¿r ä+~à,V3=´|PN¿gz–ú8¶‰ŠÚ6N<}ôœK“’Ï¬ËáóoÇ³KiõÂã-‹¡™ Ğ(Ä* ê“İD”]}ı#æ©Ÿµ^1@Â”7a\NCey*'PÙXqnÌJÅ…yı	.ıyıJM,êTØ	.y£M Eş'
ejóÁEÂ$‹JâæHÈúfã³˜4r<¯|)…¯+îŒWŠrRÀ}ü•bx)ì¡ïX™œå"Üû¦‚¸„ˆÎÀºÉ}¤`å9å¸hG¦İ±é%êÌ"Í7Ù 'Èéıu3-¾`»c‡5S÷,8ì2Y]ÊFEÃf—6·¦’kdR$‘Ú@Ãßz¦úÊÙ ^J•X“|‘&_×“†ˆV†ï¨ĞÏ@(p>á½ŸcÇ	‹Ş§A™éAMp æ‚@™ƒ²f

ön1˜Ü®Ğ™ú`ôƒ›˜ÆØ]´Œ†R£?ÎhôÇğ~LÇ›f}hğ17Ğ—¥.xšt§)øiÊˆ ø)‚õxøfÂBCgD7ª0òB¼´œTˆøOó½["p³©Uàš^I‰ 	<>½’ÃšÄZÃLç1M‚¸XÖ§C—ª1ı@‰…ˆ’z&lá-Œe'	ßq`U1;¿7dª’h]äâÓÊd±ÈYA{;+ŠÜ-…±Bñ<gcX-\c…V¡§\¹#G¢Ããz²ïy¨´Ïõ„(ªP%ŞtˆËO
(¡¾@ü£-àn&á)ıK‰c#©†Ö"]%0ïŞÀßiooZ B‚ºŠhk±~áûo§TÂ†‡4Œó¸Dé!°¥%à8§~–òJ;¹Üsò®#T=ÙãŠÀ1/Ü‘è—XÖ,îM{c‹¹ê¦OoQ¾…6èÀX}¼˜ÏÁ¥Û^û°G™ÚÔZ&ª5-Ê™7‰0è¨ËEò'g
$åš8=zí¯Ã„N®Åó"D÷É·Ø<hİÕÕUQ§ ‹;,ñê¼ÒÁş^ç¨Û) Ğ—À›ßİş•6‹Ü˜~y^Ô4ÛÿC¹\ƒ/ÂÿCµ¡¡ÿ‡J]Ëü?<FÊL×©ÉÂ%ZÕÈd#·QONÑë1&Äµ¿è–ˆµîĞü[2v3ñ
Ÿ¶hÄ}ZmØSÏÉc&ºşùˆ½ı!ê˜³ş«•jÔÿOµ™­ÿÇI[Õ-½¢—·¶ÍÆ`«nÖªõr¯Ş«å­AµnVª½~­aš5ò»b)Á~ R3šZİõµ¦n6úÛZµlloiµ^¿¹İƒ#H½L§T:´5è*^µŞ¨ŒÊ¶^nÚ a–ız³©ZC7¶ôªÑ¨ÔåÒ¡]BÍ€öšMc«ª5+õòv­^ßî•« `°ÕëAÙ-£>ĞM©´ĞmTÌú`k«Ù3¡½ÚV¥¼Uİ6›z¿Zémo×·ÌŠ¡5kÍ>–LV07Lèk³í®mUL­ÑƒTÙÒÊUİhô{zu+nVT ¬l¿nnmÕjõZOß25è­®5Í­fµÒĞ½2ü3ô­í†ŞˆV.YFlo•·µf¥7hö´Á@«iÛF;²]5f¥ß7Êå@—@ ÅV½a4Ú ÙØ2·ƒ†Ş+÷·Óh˜ƒr£ÙÜ®UZÙ”‹E-.jfO«o5ë´­åæöö¶Q­ë†ÖëU·ÍJµY-7a iÇçÙÍ4«¦Ş4LÅ†Ş¯U´Êv¯V3ÀÀ^c«7ØVa%›DÜfFc¦êÜ–«ƒ~¿<èõ+}£
ËÁÔ´Ş–^®5Í^y«iêZÙô›Õ8(ÙÃl•æ ViljÕ­-]ß‚“F»RnTúå^uË,kıf³^IkkKİÜ6Ìr&m«aloWË0×õ^]¯Ã$hZc»¾­•kFÅH€"Ù~Üã’ç¸v[,Œˆâ£Q×ªFo{k‰Õv¯>èmÚVÍ„	ïÕšµA_rPë%àP¢	LXQ³RÑLÍì÷¶kZ¿R6ê•j­\­õr³¢õÍÆ6lf*8Ét§˜W¯–¢õë•¦Şô /áw­«ÆĞÿ7›* Õî¨^6{[¦^Óë€…êVÕlT«šVŞîÃÿªfÖõr½¿]«EÖXÄ²éPÓírİœ­6ú VëL¤Œ ¦#³½„:Ú•D¦F¯Q.kµ­ZÓ¬jõZM×`aÕËµ^C‡eV¯áP2¯Z]¢¨UêÛFS×z¥Ş¬ÂĞlÕ=:Q6šõí>ğü¼¤8Šüªx°§L¸ºEı?ju ã•
õÿØĞ2ÿ‘’öÀe×1‡ÿ¯á™ŸÍ³¬$Ì?ĞîzÆÿ?FZùe?Rs¤e¢WÈê¾±CV—6pSÙz³I^¡"^r´1ì§3¡òÊß’.—I®¿jw7 LW7‡è«Îó]İóLRÙŞ$[@nÈØ÷ü;7I÷Êò2]t=¹ôFã…t‘¥˜Z>¼oMıÇåï»¾9@½$*m!ëém ©<+2	Ìï}>(•ÒÃòƒÒ«ºçï1¹É«k6mdŠ	ğËrj^Z¸óÆ²ˆ,›˜jmr‹ù;ì ?!j”ŒD¨eªM?ÔæN6€àğÔ9)6p Sˆì@¤ƒºÜ)‚~’ï,´c¾Ş¯Úv±Ü,VÊZƒÄ}Övázté(/sà»B{âŠZn¡Äõs¨ÿÍPßNâ#«o1Xá ”ª« Ğ¸óI4áê™¡u"*¹®y4@.^WÜıwÓ:f7¨¤I-†)¸à4.Ü³)Lp‘Õy&ô¸Bpšˆ}(»í@£ÓğNDªŒ6É×‡ìöàà|ïm÷ìøpÿZgûÇGEÈBs8gÉ0<ÉÄ€	ÍwHÄíé-$×õV4´6}à¨K
3¦.ÁÄ;æY ¥ÀTİm©úBÌ«–8Eüky4ÕùÔ4å:>±}qE.©Ã²N•+ßÍ‡É–H³"©Øİ :ˆ’?9´ä›çN i4J„×·”à¡v%U^¤Yãn§d£HE¯7R§j×…Nl¨ÿ˜÷(r…ıˆBÛL°èåf…n;,D7Ó|Ğík¼â2„U\	Úâ™ôâ¹¸tjúmâ"™,Õ„3M„Ğéê˜wÿWi„òÿj­ü¿†şÿ3şÿÒßüËöìŸ>{v¨÷Éq—ü½ øìÙßÂO~ş
?øı¿,²uvvÊ?b‰ÿ?ÿ<’åŸ„ÏÿpEtoGÀu¢¾8:¦X9ébFı¿šÿ€;ÿæüë{õ3K‰)"r~:æ¬ÿf³ÖŒ¬ÿj³‘Åx”ôPçÿ“ üLe iR€Ÿ· @u©òš»•^_¨Æµ?I3ËxJê›ûÒ!.Ià§@t'¯[è(°1’+B54Ô(å6Îğê¡…_ÕjÇèâ’¯Ğæãö•áÒ¹¶}ı›ï[§»ß£÷Š¥7\ÄEëj»kï§¿±óşªDŞEâ’} k"gß¸ˆDßèÉÚÂ½]É£Røx¤„œ\¤&«—şZÊĞfÃRò°ÒaŞ‹Ä¼R†Q:0´	
s:½°É‘éÑWÜY(Ï <”N<ğğXDƒÇtƒàİÉ¡7å¼{ÇG¯6oë²$IhïŸÓˆn¸”À‹E— tşÚ<¤ à†t1 èÊ‹kQvbş„–’‡ÏN¢ç0ğ¼SáX‹–‘ÜwiE-#ÅŸ®Ú]£”DÃa¯= 	äQªãv(v
b°S¥m595ÄÂÈâ†“c"	,¾jE}ì1™ƒ¢Ô¹ò9Ã±Í$®+D`­oD,3B°fê¥æbÕ…Y/DN‰„o­D@@2Eñ_Ê‘š_Ê4šWI˜›šõÓy%¼.<ÍË¹Äsa€r9R…x.Œ.åŠçŞ:=uX•3<hD`¤T(ëBq ¿ÁCººdc¥BÁwa=¶F#øı2ÚG$ß·wC+èCj×áæù{a¦GY˜ÀÌ)l„ëa+lš
J:ßî‹Øü
PĞR4Û;(ÔtOêÌêºø¸1»;¢EÒÜt:Ò¡H34ıs&W>G!bğnÂ^Q:&Bva9 Š»k#
ŸCı}gä¸»úÔw‚»kèXáà uÖÙİ#˜¸š/4ÀX)9W/x"O@ƒnŒ\Ö„‘ï<ö(©=ŞˆgÇÁ{NMyĞ,È&•òZèqp:a}=õu Â„²×Ë³R‰™U…ÅÍÛ§TRq@‡Û°0„âİFhq%ø¸»¦˜;=Ñj£•OÇOÛx	mëîµhÖ4Š8œ—H/#m/`nˆ¬ÌôÂ»Ğ)ôITİšT^–ó²dOG£/C4k+\’ü9şcşj¼Òë´¦½ZÚû®uô¦Ó.½€Ú
$,´Ærv×.­X8e_ïÁŠJ=ÿËò_YÑo™2†å¿U­Z­Ô5RÖêõj3“ÿ<JúÊå¿6—ÿşÏÿ¶·r¯~f)1%«ù.·9ë¿ÒlÆÖ?|ÊÖÿc¤Lşû´ò_E¹ş)–­®gHƒ£¢`ÙUJ&¾{~îâà…Ä‹O'>#d…Yñ#¾QÓû¥Äı©Ø>,%9A;AÿCËœ‡ÛcæñÿµJ•ŞÿVË÷Î²ViÖ2şÿQÒ
%°’s{¦I4m/t†{¾¨ğÔÃú	¬P|X•vƒ§5ş´Ecâi?=•„iâ]CLuÿz‚^L0÷&9ŞÇ_ín§C˜{³îanå¶k‰äÂ Ÿ;Zuk{GkT;5H;[Ûğàşº4Ä’ë–[Ç<ş¿^—ìÊèÿ¡VofëÿQRfÿñ$öQCÖŸ+çŸb’Ì¨g 3°\NıqøôÜ’Yï¯‡ñfë¿^Ğ§¦ói	Ãg>tåÅìí¯5ËšFíëÍÌş÷1Rhûÿpu,8ÿµfS«Ô©ıwp!›ÿÇH/-RÇí×µ™Íÿã$Õ+ÊÃÔ±èú¯–ëÍr¹Šó_¯×³ùŒscó uÜ~ı£+ˆlş#¥x!Zjsä?ZYk²ûßZ½Q¯àü×kµZ&ÿyŒ´¢Şã©ç7ŞBÑÙŞ¢E á¿2„qûA î¿-†yüß·SˆîS…hù:âÈc`L¨{èêc/—;i}·»Š¿wVi¨‹b êËĞÛa) ùr÷¢üs6 ½xLñ„Â¿.Ùw–ş_ò ·Ü:n¿ÿÃ.ĞÈöÿÇH1ßPÇ¢ü¿V®6ËM¼ÿ­Ujÿÿ(iïÇeÔ1‡ÿ«Vkôş_£?e”ÿ4Ë•Ìÿó£¤eÉÌ£sûöÀÕ=ßÒhÃ\çŞ ]æiÕ{Ê;¹èu\ÔÛéRïâ”ÒÑ{8ØòšE­R,×"×oÑk6W•Fb¶u´±¤M#FîÚ/Êxh	®®×n­X&GŞœ``Šeí¡cĞ`*¼-i’¡…áAX÷È»a£÷6h+D,>ù}ŸÍ=y¥éÕÀSÎÛÇÅ°wKj)COb¼Us, ã9µ=¡iJyŞâĞô××x\Ç£Öagm“ä©wêsV.¿! L‚€Ù© ğp€ 0–²üXúÆË“oˆÔŠµ1£F\D@´l=
•Y1¢umÂY;¿!
{ŞH”ŸU¸Û=ÊWÂòS<Û¥u‡•}ÛíœbÁ+³Ü¥ÕÏ‡”ÍóV¶ºİOÛp€ÉM\lĞÃoÍÓy÷÷a-2/"Ùƒ¸ä±ì8aöP-‰D²‡£ÍAåX‰hn>œa·áø$‚ÇñsqSrãˆAîĞºö‡ƒ®Xÿì	%	ìÉ:ëoÏ>ji6s$–Ä<…cÂŠ…ã1«bŠŒÊ¸Ì*ˆ#u$-®p|æ•
Gm76NO@u`”Îz‹ıªSªñ%Ö1‡ÿƒ]0vşkfüßã¤Ìèã±>~¶º^‚@$ÄVbKºKQ0®cõØZQ+?ªÅEÄ­kèxS`ƒ~8ggäqrægäáx0ãgº_b¬,Öı2¶<tºë|¤ßØîÖéÏú	>–Ës7™à÷Wš’Â˜,»yòŸZlÿ¯5™ş÷£¤lÿÏöÿE­<@üèô˜}g¶ßKMX6¼+Óü8º&ƒ)FfnÅ4ÇèÑ¼p¡¾ÔÊo“çğOƒácìFÔO½zqFä#Ÿ¼~{p@
cÄóßCn£§ûäåKRòÇ9;šâV^şVË=Àğ:†{·ì¾KãëO7ˆåÍÊfu³¶YßlÜi8÷öN;‡£³Ö×2ª\õâñF²R¡#ù|ÑñÂKŞnÀz~ª4'²âRê˜ÇÿÕYügàÿê5­Iïÿ¨ş_Æÿ=|ZÚ‚Eóİ[Ş >!w†µ#S¸3`Pâ‘E!ŸÄ­“x¶M•]ÃğíMæÈˆr³c1ñé% æ‘X2‘G£7s2&Ş¼F¼àe !.É[FZ­Í»†6ûşˆ˜6‹C{é¨Ä½‰rŠWjÄÿu"¨FØWa5ŒQlh-ŞªĞB;ï.uF'ü²‘uz“±Q$-ãGX„^¡ëÀº}
”0Š½]“ãË/Ò $a–P½‘¹ÙQŞ{SÃ!ıI`ÓñÜÒÈê•x7ùßR¤‚]
Ÿ•L¨ y2T´‹•GóaïSïû€]şâµ¼ø¼jº¨)C%cİê£™À©ç Éí!;	3ÁÂÌ,
œFî¥é)†Áú,oã9¢É¸íª;Oı$”‹pâP³µªğizäcŞ8ˆÁ€ŒKlwî€¹¶É°İâ… %ÂeCîİö½]Ûô¯÷cæihú¹ÖÀ7İèC’{Çéò‡ÜÙõÄÜõ,XàfïØvytª7¸ wn›ûŠÃ"Vñn”-Ãe‹jÅ?Â{/¸ËÆò‹ñ\ç“Ù§8wû²%Šv?˜½¼
DÍUÌ™ÜVÂs&28h—mè®q<õ'S°å«0Nœ„| £‹gîİñtä[¬†çSïé·I³£a/§9ü_BüÏF³VÍø¿ÇH™ÿ‡,şgÿó+ğşÅÿÌâfñ?³øŸYüÏåPÓ,şçBIåÿ9A-ºŞd‰uÌáÿÑÜ_È+êÿ±Ş¬fñ?%½ë½Ù?ê|ÈšŞ(½É®w¿ç±´b™ıË½{Ó9êœîï}Èu;{oO÷Ïştşöho§{şı~ëüğOŒ¸uß ºøî@yËµ"ÏÒC¤¤óÿ²]@ÎYÿÍz…ÅÿÔ*•F™ŞÿÔ›µLÿ÷QRæÿ=‹ÿ™Åÿ\âgßïÚğ,şgÿ3‹ÿ™Åÿ¼güÏ[ÿœÑsvÜÊÇ‹£ùÑ@otf´Î[ES] ^êì0—I¡,gÅ¾L
s¹PË¹±0ç…¹\z$Ë™3³ˆ–DDœ4é1‹9'6f¥7¥÷©õ§ˆüÇÕñè…^÷–XÇ<ù/<å¿Uÿ¯ÑÌô?%Yö%œa­ÃœÇt§(>ğ9äÜÎ‡ŠØS·>K÷MÉú_Ë:ÏÿC<şg³Z-gëÿ1R&ÿÍâfñ?3qğmú”ÅÿüåÄÿŒíÿ	tÿ¯Æÿl ÿ‡f=ãÿ%eñ?İñ?cëÿ"Îãÿãñ?õf=[ÿ‘2û,şgÿ³ğğêYüÏÂ×ÄxÿJâÆöÿsqA¿< söÿj½ŞüÔkÈÿ7ÕLÿóQRæÿCöÿ‘„ÿ¹ÌH˜ÊH0è	N?6xôVğ0î?’Ğàa=€$#^d°–âdšîád!èwt’
{‰4áãD–İ<¬#‰[İ=>éµ»ç]ãn®4e,ıh|ÔŠ[Åò¹V«•òªó-4
¥<HßğL!Üe®>
r–™ZĞHÙÕÇœ’Î$ZğÔÄ8|·(êšµdÏ ?W× ‘øÏ8ëQ»ˆ–RÇ<ùO¹Zøÿm–ë•Œÿ{Œ”]ÒF›Õ(ëág+¨is!äu-`Í)óf şµ"ôJq~-}s¡Ñß…áó‡ˆ‡›ğÅq‡9£¿C‚‡9§‡>¥ú#ø˜âu[x‡PŞÀNÂ öí]ºwz›I°ûƒ½ÔÔí9¶¬¾éOL6êTÈìõ­ ?5iÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)K)ékQc 0 