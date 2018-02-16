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
‹ 0ò†Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹¤–—h|ğk†3Ğ.D@îòëJÚ9IËkM G@7¶»AŠ#qÃğ£ıê7‡üSî\øı^üœ™UÕ]Õ H‚”4ƒš‘„î®ÊªÊÊÊÊÊÊÊ<³Ò£{NårykcƒÑ¿›üßruÿ+«¬U×+åÊÚúf••+•µGlã¾†iä¦Mñ]kl>Èv~>æ»èGøï’Î`üİQçºŒ|ÃïİCãÇ¿º¾cã_©n¬­•×7`ü××*[XùÚ’H?óñ_øE	IàÌô{¹Vœ]h‹»m¶8s°'}avlŸÕŸ¯²§#ßv,ßgëÂê»Ãåì—¬5]/`ËO­”i™V×ò,Û<Ó÷-Vız•}UÙ¨²ç}3Î¼Q·»ÊZ—vğ£åõM§3óF˜Ëài›i>ÖGAÏõÄÇV`›;´z^ßfË®å˜Oï—Şı&0Úî J7;v–^Ü3ı`§g:]«óôŠ£¿aQİjüÀ³[¶o»N"‹üÀ³¼¡ë[ÒS Öj{ö0`ËºüÓ³˜í@×œ¶Åx™é3Ï
Fk»1á–/[sÒƒqô9ø50m§ÅF¾Õaç®Ç,çÂö\‡§çvò²Q„ªáµû†jC`½ úÛ¥RrÎ;%1Y¸5óaô°ï€ª\ïjË£üµQ-W6cÀQÛuìÀ6ûìÂò§R5*Ì³%óÔ;? B1Zğ3»sÏ‘R £Æ=LÎ"ÛJİı£@Ãî=g½§Évø¢qz|xxrÚ8¨-~P¶‹y › ‹SÏp½nşšĞt:ØÇ»·#Gà0GFı€½4û#Ë¿C‡r/›Ç­İÃƒŒf®qX?:j4jù“ãÍ<›2- íšg}‹õİ.;·á‡9ZÀX öÓÃV³–VßkİĞÆLA6ÀÙÔÚ9Ş=:9=¨ï7k‹ËHáğ¶X.äNöN»ÇÍ“ÃãïkùR0æéå³İ=¨}ñƒ–áº¤7ó¹ÖIıøäô»f½Ñ<®åé	Ù“	CÃ¶øA©ıš-¿äïú®4gÙâJ>·_ßİ«7ÇÍV«4ı×3aBí^®y||x\+çTŠ¸ûHrpÏFN‰ê.ÄÀÁÍvö‹v±¾Ùµ–ìCœ·6lØ7¯x†×äR!5½j¸û~—åw²m^ñj|_{+Úì[œİ»@;Í'¬Ø`ß‚ÑiÀïøï#˜í—®×yÄÿ„½M«„±b/Ø©r¶àâ0€Å2Š_¤O™)Å½´âíÕ~GËgûv›øR ¥ßQ’ä{ä»ÍÚN­a{V	¶o:Ğ/\*êÂ6¯ˆ—d”N&x‹_’ÓÊí¹]bO°ÀØ;|Üášç³ÏÙkxY¹fÅnÀÊìí7¸¾;9ÙÍ¾e:u§ó#;àù?T¯é³Õ‡µVæ‹q¼ôòeFïÏíÜunæk]êÔÚç„ÅyT`H`ïkªÖ—¹ÔÏİƒ£'°HVo¯\§!%uÍwÉÖ»‚ÉàtÙ™ÿt8nÛÀ¯åêÄ®t@Œ  3“96ÈdQ?‰Àù®2XÜÂ1ÉÃË;ÙİoíÁÂÒ±„åõøûâãAñqçôñwÛ÷··ò…o¾QŠgu&¦ÕJß¢ŞÃßa­Z½ù¼ša…×2)I²|³Í€<-hHÁ×yVcBˆO™UŠãòRí‹ù£6à$Ê³e±¢©ÌÇ°¤6¯Æƒ	³Á”’?ı}„O—=œ÷Ôj¬öĞ^jkÇÕª¸iÏ¢fÅ^Nì]jÇƒÓ²*=Mö¶ã:V’7ÍpØ<IëÓg†ıôFN¼ûàÏ!‹TŠXœuS6îŒñ½Üƒp4iáKöK® ;³—áš‹ÜVÚ„ô¬²«Š’8*doB7ÙH1Ú`¯`KÜeæÀ9$‰›^w„[dß`-˜\#ZÖ½·]å£g¨UT§­BfË¸´¦…¿1¾*•Ø $’¾ã4¨>.g´…<©?½fP<×wöš¡tsú´ŞŠ!=±V*FõøV@€µ—æ…i÷QzÔúS©L‚¼ãú‚¸£vïø°_Úo ¦ïšöfñÃw‡@%C6R·6±¿-Vû&ßœŸCÇ¬Z~}bù¦ç†°9’"ôâ{Ã‹Óèz#ÇAùEè„Úî``::¸ê-Àu|EDO…º6	ê¾íû$Y%¥l•¢§¡­E#ŞDC5PSPãXœ%~ıé[¢×¶˜ ´½²˜"á”ĞˆmcJ|ÂD;VpˆÓ:Ö­
hmT¼£Š#c~–bÅKğT‚ü>U4@&n;ğsÀ7YJû¿şºÛ©ü•d—¦ã˜Ìù½göû®6M=‘í¼pŞ9î¥Ã»!ï1³T”\'˜¿Ş¦ckà^€Xm¡@Íç|X4N¼²ú¤Ô±.JÎ¨ßWd|ÔÎœP>›ƒ+C„&òîú>€Æi äœ@¤œarqcå]å¤è"³qÑE[8ÆÏ1[œÓ%0o¤åJŠtÚ¶²Z	÷•ç6c¹°íPqØ|Zq²›Ë>~„/¿`ÅNì³Ú@­ÖJjÃºö)8EvÎ`‹ËçÈm¢¥§Hz·PÙ[ˆÏ:ÖÂ98Ab?'¶í9!Ë¡B~ÊI§èòt7`şås|Š„A*¹ôk˜Dù‡ıò—8L—,¯è´îÇ´¤¹pDt¼TÔ
•½i›;ç8â8õÏ„d9¸}Ó¾“[¡şÀ3‡,¯ul½œÇ½t.'¸`]Ñ'à…†ô:æbj7‹µG U9¤NSò/\öÂùÖµwd«—z.N?\ĞÄjØGMˆ!@½ßwˆÒ¬wao7¶Ønn{(í…Û.ÈÂUºäš¹²Ât/
1yXùfØş•JÈH¦‡G€šçÚZÕÀ|\–‘ã™CUeäõ
ì¸y´·»S?A%~¢UÍ‚N•éP~-;[e‹+êBA{¡[èıC‘àq1Ä¦¶X”FÕu7ghÌÖÌ¶Ù/‰ÓzÎ%òlQ-¸{ÂÂ™³ú—•fâzöÅ_C]=*˜…‹ ,Ä;¬Gé‡0ÚHÃİK  óP§$‡I_øÆ°˜h3SNzÆÂ;†ıD­ÇÂEâÒt]`8õåB’EğŸÛÅ|ª¶÷:—B½²˜ú ,~8zÕ¹æhú…X"“ùÇ­BëkÉÁ«`Lˆ9R0.“şâ9‹E~l[<÷lèé
Ş8nĞ`Ğï#ÏZ^`[>¶^qEi@óùkµO,µ£1ğ@¬Q?Ñ‰j*
Çnñ¦ßœÊ×+ZvA#¦8¶Ißg6;ğ–“Ÿ‡ã¡gm¶ä—ş°X*––T:„R?¸°8=5Ûï /Ûmp•ô`Ôì! ¢C¢tè™@®°G¬÷ŠÑ‹¥ßø¥7N‰•¾¹Î€ìP?ğD®m`jJÔ£§#¾i“[,ˆÃ•–å]À®	¯¥ÉröĞš6[JdGVG«» ˆ2v°-ÑêN*½tV‹[b€Û’	´£YOlÈLT?ñX·26n¤öõ#ú«.¤:f8[I·øÁû…ú«ßâÙÀ²yù-=m>ß=øpÜªåß8Å7°CzF?óßì>?8<nîÀâP«|Ã74µ<ƒ©°?±ÒêcPB¾ºXÅWo¾]ÂZ–Ş<)±Ğ©åÅ5şºÉ»ïNùvÇhKBïôgj«6ëBq^ŸY0:•„,?yˆ’ÃT!,Iq^_†•?KCj×òÇãÏóæ£3³Ñ!! ÿRfT“†&çË0c5‚Ÿ2"8ûuÏôëBK-;q"}ÙâÑ!ğõÆşîºôd®bfg`;S,cÉµ+u¬2×0­KYÃšª¶¾Å¨®Wõ…OŒ.ç¡õ1b€?*SçÃvşA¸×¬¤Ù]KZßb¿øĞú*‚ú8$­oTS‰ıf^t½QÕHû§M‡ûÑYì‹ŸÚâSOÒş—›p}ûßµõ2ÙÿÂ¯­j¹Lö¿åÊÜş÷!ÒÜş÷Ùÿ†î§bÿ+Œ@MX$åñŒºDû?uÓß¯øÿL+kñ‚¶xng¢ìİBõò‡VÛ>¿Šì°	³>%Ÿ­ùğOÛx¦–À76~PŞŸ‘	ïÚë¦X#)ÜÁ„7a*ÚzÂŠö­2Âğjz“İ»ØëNo¬›lóp6$6õ¤ÄÏ(è^Xzß´ûLìÈÓ‹ÏmdÔF–Ímdç6²ln#;·‘ÛÈ
ùğ†°c¬rCœg.|sÙ	ğç¶ª7´U‘ç§°*œÛõıÄìú kóàem¢_¶ ¯€@msÓ¾;PíŒû àÍ-øøî·ÂîÍDo°mo7ÉLï!lôZfuÈ¨h€—¥œ'ó~DÕ­_z³ZzÃJİÂ½Ù÷ÍÄ~ï'oâ%Ø^llSXµ`R}E—êìCãÀÀ<KÕ‹Ä
Æ”0Ê*Ğ<ÙŒCÛÀÂ[`mÏÂİ¬©Ÿí£ÆbÈöèÎƒÒ¾ºJß'õ§µdE)	§{»-<¼æGléKÑ•£íQ -¯Àâ°]H®E¯êÇh7¢KBØxB
!ïMJß3à<ÙãÌ¢\,†-mÔOê×¥¼6•9ÂZ4êH´—’¶HY2Vb5%îµox£ÑQ›bÑ&Æ€¶oÆÊ›Ò›eø»ğ[a¬,–ŞTJK…¨kê&*ÄxÒDZ;ÛàxVxi^ĞõÈ·Æ‘µ(Afp¹dû#›C´A÷ØÒêƒÿ
‚í{ü&ˆc];·Ø ¥ìÎèõ5Á}ãÀz¿ùŠX’åMpÎ% åùwÈ\4¥ÓOã°8Cbñğ¶R8Ã‚íõ¢,ô6â ‹ ?¼ò¤l—‡ çZçì#³ätËóWéÊè‡ëuG|Ã'û?6P–r[nÈÛJ½}Êâ3,¥õºıPi4\e¾;òÚ–*³‰*ü*Uº“Ÿu)/ª@Ê{‰©×	×”hÍ}/Yq(Z~OFIİc]/¡5+»Çè¡éŒ[™òûWá·|Ê‚–[c/âå©x(Ä í,ã4+ÊÜb|lœ€Ş±ëœ›v¶‘£®V‘ÈAæ^zızû¬o:ï¶ß¾]*$8’ Í½ÚkfAW9í>ÈàO=Ù^m³´7l
ˆU.Ë,•ŞäWßäK	¥¥n”£O]ËÆ§í\€Gç;$÷ÓÅr0®OÃ¦]s^=¼>ê)Ü!¢9n·õ:¦¤µs¸¿_GY_lˆv®Kb±ßÉ\,ö\? NĞ|šÊbn*ï´f¢m–Š{Ì‡M€bÓB46›§óJhÌ—~õx´û%€4-~a!×Ã`â3šúi„Àíıâ3SÂ’-š†Ò+·Lj?C´AIDÅº'$µ{Íi	G¨gø¡%.åF6wùDÜ>PGÅÇ yÏŠ>iU·›¡x–y÷4„mA’<P I`ry™~üªRĞùCªú<{Ø§Ç‹?jãÎî¶ÙW À8¶ß³:qõ{4ğš¶ı+VÇ½tVAü”İ¿´aÖÁÒòğf­Õ1ò¡²D±š^Ì"D|¼“`é´3²ÈÒ‡Æœw,À÷ÅõrYİş'—š.L…bzİØ˜
rFb–˜ª
a6şÏÌó¡“´ÿD"?‰ıçÆÚÆZhÿYYÛBûÏêúÆÜşó!ÒÜşóÙ†î§bÿÉ;ôóµÿÜ4àÿ	öŸ_å--Ï¾ù®}Ä¢uå)BÛuÎI—ÏÆ·¡g?z?7(Í‚öe”–Êë]öAÍJO¾?Â½ØÛ›ºC¼SrÌrÖtr5´r¿k6jë7#€Œg0! {¯,ëMÖw–5Ì¯¢é`-_,ÊßS´“_ùŠ°g}³;· ı’-hö-’êOß–6ìh˜”Æp¢¢µÊîÁÎqs¿ypRß›ÛäŞ‚j?+›Ü¹ßÚ¹M.Õ1·ÉÛäÎmr‹Ÿ“MîT&¹s£Ü¹QîíŒr…l—4ÊÓ77¦Ó~QÆ´³ö“ùÒÛöö`»yf´lHM•jŒúF¶³tk9·Mfœ[Î­F¿`«Qq<7¥Õ(÷÷/¨8—K?²9¾ì«
>]`q€.pu6û¨W•OË$ıëõ"Áš>ê1G}—màˆ\ZÖ;æ*>wĞ|uúªÙüİÁ¡¢sy‘/ä÷ÑØD¯‹‹ğàºP âOë;¿{qtÚjåñJO¡R(Ä´Rì1n%¨ šéaã
GMH)¬Q#Ñg$ê¨ŞÓ/¢Š¯'Ã£YXG^Wœ¬
Èj	²Ş¥¹õ0»«§n¼ùÙZ"§€KX$ãx›0;;èxè(¢¯HtÑm•%‘Qf‚j§@
·fU¸VÔn|z•˜^DEi¶¬éñäÉ›01•Ìè÷0Sôaš‘]ü ·E)”ø4¥¹¨j*ÊÒÆNl×ÑõğëœÛİh§h±@P;V2j7+ıØ>ŸG%Õ—Ã4‚î|›·sxğŒ=Éêõ„®I'ùò Ü¿AßâEgÑ9ŒiB]{£	7ÔQèZÉls—Èá3ºUGÔkÈGáô3–êÓ4|)8šÉÄßíNÓ°,,¶bÇÓ[g[?MÔ70*Ê XÔrkƒâÉÆÄ	6é¥vy
{á˜¸].†Êi›P‚–t1LK>sû´×Ñc(kĞ2Ÿb)ÁÜb‹ÿ$ûñ”.ŠP8ĞUú˜¦.)Öi2IÒŒÜ°¢—>3c'ŸÌdwãÀU»pî@Ö_¶ºFR@Jit!ó`GÆø™‘©·hŞÜÔûéS›Ú~–	ÓPÍz/uŒ·ÿ.—×Ë›hÿ½^ÙØØD‹Äremsmknÿı é/şæ/ıù£Gûf›¶Øï%kÂwş
şTáÏ?Ãxş³7ÈúÉÉ1ÿE%şüù±,ÿF¼ÿëGşäpÃû–Ñ7ı €q/¿pÔ0ş-şõèÑßc¾Ùöp´p‹×çnúÑxVäı÷ïbyÑ†ù¬oí:ëı£Gÿ©øÿsÿ÷ÿúßş=ş[yBû<“Qèê?ÿ7Ö+Õr|ş¯W×çóÿ!ÒüşÇ§¹ÿZâÉw?¸rŠnââ=K<ŠnnÄÃ‰ÎoÜÇ-ròHv—CÕO
!l  à¸iğm–€«A(gÇm¿³¼Ô"´k§Õ§æ5!?Ÿ‚±
¼«#XÄGDğÒôl4¯¹A<BkYÎ˜lë/¸m}œÒ.ÂJĞVÃØ•†@6ØŒ»(ôßÒ¼^_§!ñfòËÎÚïc^?×h>«¿ØÃx,~ŸíøÍ<©šòZ±‹U2ñ¥K;ù”³Z5ëŞáN}OÍGŞ¢<GÇ‡;'j!]7
8üäWD–óÁe¥jTŠ±f”Ÿí¿“™k›¤fÜ}^Ëó¹tJG8qò*†H²<‘#¢¼«…ç¢øDœ"—ëœrHLˆ¨©ßK‹Æ`Š³HÖ‰g¾Øhœ§ømæ~®ÔK‰¬"$½.YA›àqÎLŠR´Eä}gmyÊ¦àA±ƒv„&6+˜‹Y°³ëGyØ|ÒTºçt"½kHû¦ŠBdTµè ›c;Â>"<?°ı6‡+1dÃ|P EÓAÀŒ^„ãÈÏËõqŠM£Ø0+¨¦)¤&ÂO½`mÎÅb…Nœ±:¶$¹÷Ğ®/aÑŒHŸƒ Tœ˜ÛZ«b“Zí®>£
å›»Vª1¥âßÖ_Öe•áïVöƒyarÔâÜÊè¨\–kì7wN¿?å¶Ad!û•i/¨9ép°'R16“¥qÖ¦ApÅÄBĞON¾Gç&¢÷üè±Fo ö6Ù;á;ë½ÕQ3J‚—…_ï4¨?I%ÿ™›[r›¡ şd”¿wcL­Mi†Ío2,›yû<+y«Äæ†
Åy!3…-?¦Jæ-ÊhÒªvˆ½3ägå°
fFG#ı+¹¡\n±£úÉwh‡tn{~ Ğ–‹	/mX;<¡Û+HëšûVÌH1âÕ­úËfãã?×ŠqK‰.Ê•<T°=sDª€€g–HÙ°Îë«ŞàMĞ’›\ÑÑˆº€"™(‹H>­ƒÒJV—/ ~5“´QK
!!&ÒÁñÅk<4é8àÆv("ÉHçŠœOâNª)alT3ìãıÑrrQHääÒ:Ri °!Œ™8ŞÜ¼ñ‹¢V2½ŠÄc·ØòÁÔ´Ãà*¢ù|Âœ,É`y®–®àÑšef8~ÒÉ=ÆZ6•dMn:W:i©DˆN1SsÊ|Š '!İÅšòl’elØ]­*Ê[bÁÚ¹ø#È$Ä3à3[Nü
í$(EÊ8Ê¡|*Á¨„X‘Ğ.R«J!m²‹=	'òL(0ƒúR,zctwcšË¢·›ÓÚmélÖ4Fôuof°ê¢iú>’€gÃ0rq•E&NåiÜ–0¿WÇF¦S·F=”<`sO¼	Øx¤r´YVxu4¦4Ytpíƒ¼‹
wæb£ÀäGW%BLTÒºŸÒ˜1İ‹â’ş­
¶£o$Ğ´UY…X!üÜÃ-™ÏÕ§FxA-FD¸ëqİ=9êoª-RÌ™ dHÆ¹~|Ÿ{Mû äQ	Ãxò/Ê,gÚ/©vÀKğE·˜ãé&¶Á™åÑ^XŸzªÕpZ1’áˆQ-†KßpÓşŒf<ğæÜVV[)	Æ¸8ßÂ«7ŸÿãÒt³»İãS‰9÷"ä$ŒÕ”Œ¿şµn¸$ßKİ7_0:èk nÑD
OòEßî-‰[ÜÈÙa%äßÂæÂ¸”îå© \Ïl÷­SRN¥â9¸ú*GŒ³ß7†fĞÓòEön¤#ŞŠGzüËvÂ°0³ĞwØôåÅù…Di>æ,ãw 0¥âHÃ6¦Şg¢¯:™}¯Q?bGÈI™RzµMÍÚÒóŠ¬§­Ö^"{ì]S³“¦5QàX1rÅdãæQ<û,Æø>|hy4L2c•†2³ØæF·tîsÄ!æ÷ô”ÉÏÕ­ˆ¾TÑ• ibÅä»ÄcZÊë‚læ]ÎÄÖÓí9Ê.äaˆª²÷½ÒEùâûš}ì!s)VàëÜíUu@89nl-×ßäf6È›©¤%±v@ƒ€¥s’ªz¶œ³¥ÇÅŸ=.Vªø÷&ı\Ç¿}”ß“25>d[±å„\Û9=»b%È„X¾ÿ"¶ÃßD×…|ÆNiÑV¶%çï‘)DÂ°z1ÎĞ»)…´^’7ŸÃ˜¹Mƒí<"æ»`dõûrºıÍ‹Ômæ(.³\ßJÚ×&ï$ëİMÒ»•œw)/åDÀ)™êÚ£†*%–8Ğ•‰?t¹âW"ñHŠ ŸƒDO"]m1ºvÂ¥^/1%#±W•îÒ]‘d¨vıÛiÁeİP$ªÌ‹ÚQérÇöÄ@µğ~çu’éİ?Ö? ;ê[¨’‚Í/ˆJvĞ¿"•‡R(ó:B†C®ûo‡Ú†Ä™³Nè:‚&õ°Hox\8ÎŒEîUØ‹öCSN\.k}SVÚÓÜ`£ßåzl‘CIÑä¦1mÃˆIôPéXtØR‰61´ß sOî0Ëubÿ¥ÕÒKÃ%Ù‚P>êøÅöy·ˆ
[Ë¡€&BHB}¢&ÆÉšuŠJ°¾ïèİ,k‚£Vcë«„V¢“ê¾l–X½!GRÕ Ss¤+wäñ¹–®ÇX<	g(ıˆ,ñÔÕOšÒ}E:–ŠÕÄé®B¤Š 
Òô:$EpVò‹œ§²öÕ×éy8A„b.æİ\ÛÌÈK#ùAş„¼_}­Á½=ç½OÊ§ñò¸†eŒzE)×]$±¼ªò"Us¡äk/2TJ‰¸ú"Uw1{,>Äê6âıœS±O¬pü3ÍG<’şôKX´bBçšrú3wØbã`_&¶rVÑOôÕD¬ÕfùR¬`©ıæMìÕ6ÑÏvH§Û
n‡´µ½¨£%¯ömZiÔìt› ÀM;9×ËÍ¨ÅOdµ9yŸ–ıUv=«Ÿ¢´ÓNP(‹´eUİoÌØL\ò‰˜5É­ åsR¹m¼¼›u}„Ä­“Ã}4ÄÄú|Èj@Aúû"ì¯£B:!D…ô÷±B¡’°|÷ìd’ßÇ²k*%%»ö~e"ã8½YáûX~i}ï†|Ë®ZÃ«Ù•÷é%¤Åm¼„|_\‚bKÉrZWjúŞ-^“Âb´Êû1Ed§âER;ßß¤•Ki"²¶8‡¬	-dJV21‘•¿O+ l36¾OË¼75;¼×²«Ü@FŸ¨÷m¤oÅ¢V 'Eíäá_;Û ÑM1Ã¿'..ØHƒ"µ¥¡3|:²MâªR½,1j¦—UoıĞw¥ê^T¼;ŒĞ÷6\œPjÄ‹ÉZ»nO+¦_N(,üd¢_…˜5"]b¡‹üKŠ	- {s·ñCˆÜ‡&íÈaßæ9t³€ßvùIÙì¿&±2±RE5*3…âHSTd6Ê»ÂØÛ·,&yÕ÷vë¡LÊO†EĞ
a[ä/+…ÚòRşû˜/+d]Ä¢=%ºV"3óLËcñã2‡R 0…ÅÒ›ji)Êñ¶O¨¸vOâTFüq±RçùmñâêTüS>­ùæÆã®ÑKÚ‰Å½Šÿò¬%ybñ[øÂLÏƒ¹eõÉ›Ö}œ[òûP»ÏĞ2¤’ÿ†{|ÿFŠ +ğæ;ï@3ƒL½d€Mßº¡…lÆg÷¸Â5ğ«zøÀ«°áá†TÔ˜´Hy]ÍE{' %­Pæ._SÁhEğœVâB+:4Â·¼ğ1¼+ ĞµÖœXs§kP¬ĞŒš´ã®sÌ¬¶¨wy¤|Ç½¤|Ç–ëc½Wæë´~-,FĞEÓúşömìÈÛqÙÀÚ½U6°L9«@‡œM[í6Å»@^–.î]c 3éãMy¶ìYíM)¬°¼	yåp#z­.-Ğúµ¹^‡·ìÒ‚ÿî¼o•¯Òå~‰{³®¶	‡…îG¶ÈQJİOlÁ%ºU¤Ä6ÊTÀšî)ªWéG)Ÿ¬+÷€ë¯hmÏ$/Ã¸„èzúd;D#J!CÏ	p6j· M@4€à60ô€ÛeòÓpPVEôV8
øNÇuŠJÊñÌõ.M¯#Æl<åÉvàÀaüÀÆ“Ü~ŸÀát(Û³EŒ£Œù9çï”j“ˆ‹áAÍ,D#èc!¡f6ğLæ÷Ññ ™›ıd= Û}!„¤‹{	0;ïéª»{yü1å½ y‹¯HY>:íÔ,ƒ­÷ ˆûÈ4•»#3Wtq#lÇºÔ$í,¯Ü‡Â+äiëäx‹­Ò¶¥ KÜø Vr­ÂT?
¤[öL(´+$O¯&‹™#‰“™	…6ÆXM(:s« 4ƒvyë7Å'Å $Š<Z9Ô.m'a¨kaÌ¼BS«„Â8,5Æ UZî+Í›("hJé$¿¨ŸM§›+äqx8òY'AÙ§NYçAñ÷úØ)ìY¹F:~˜J©ê÷íj^Rr¤”»]ŸœhBªà‰DÂV‡¼,ugMY‰³Œ@ª‘u¬	=·–ÛV¬å¶5k¹íH³„¿ãó½Ê
¶œªú„£6äµuaÃ"A}ˆ¬¥ g´µn(Q\Á«¡âD\VˆU­ø¡Ìrü
b ÅeºI­İd¡ëY¾òã*N‘xWG¥@ê"…Ñ³/Òáe¬LÊÏgf}ò‰1C^ıIhö¾È·+0Û›õ“0fšæÅíÁĞ•»²¸7‘ç/Ò”ó”¼”ŸeYáC§òY â~&¦(Tâ¸]YtéŸ((/1Nšät#6ÚR·;5¦8ÍT½”'¯á“›©Õ?Õõşş.Ğ)Òp=¾.İztÇ&ırÎ­03ÍıvkÌ|ÚqŸä?{6%PİÙnÑ†ôÿùÊŞ&Îlg;ÓQ|T²­z!ß¹ÃÈo–êv®	+DŒê´Ÿ0Ÿí@õÆ÷¦¥@ëFKÍ‡~_´¶áµXÑ¤;´&kR£âÙC¿*¨¥AŸ¼‘~0:í’#<›ÂWdºÇ=\0M~h•é¾cJ“ù”‹ÂéöES3ËsW<cÚ“}$—Ú,ıìF:úÉrû\È‚™m˜n`3³ËZ ˆ2u32Ö±ñI-ãCÓ÷/QÇL4$	&Ú…„İ¤*‰Up:¼ìÁû íVúÑ«÷3EùÄôÔÂ23öG¯¡;¬k=l$]ÒµöÔ+øD¶­D4 Q"a—ğ‚€Eéêõø™,¹OíÏxn–„±ş½Ö1Éÿ?úË®¬UË•êúV¹Rağ£º¾öˆmÜk«Dú™ûÿn[;aT/ÿ¾¨àæã¿¶>ÿ‡I·}¿“ÿÑÔã¿^ÙØª”7Ë0ş•ùø?HÂñ?nÖûMcĞ¹§: ›ëëYã¿¶µÆ‘ã¿V^ŸÇy´@:G
ÊÆU E#™% Ü-Üí7‹ù/ÿ‹ön ZvL¯cÿ(¯EÙƒaÈæ/´ğ G®‘¨Êı—%ú|&wj´İFweø•m†1ü¶9´|ƒÕûè÷¿ÛÓnÃwúX‡Ş@³¶ŠW¡û{ìVr¸«Y{ú«ÂäÔD³Sw`ö ÚïÛÁˆß/éû•;b…ş²˜?@	êqrw(—&ó@Â“~,“ŒT©_Ğ½µñÔÄ†}GßzOàÏ<tÁ5ö]r¡çØ ÊŸ[ ±{–†Æ†D£†g²¸©·öWÙq}g•2=Á€ìëÉıúeÏn“­”WVË3û´ÆÃÛã»*“®¥tÂÈåV$Ñ¬`qhw»Ê/Fà0­¬„1.VVZV	ÏBÿ>3yä¢v6rÚd3'öÿ€¬êáÔ¼Qq@(>RÎlÇDÖ«!ö)4AJ-iÂØ}ÓC2¾DS%x5¢ÈĞq*ÂQ=á=«l—2_zvXÀ)Üt™Ü`F>*{¶3zÏ^îÿËşĞ*lcƒ¢*`£Óv,~,plúÃ3ËƒÙ˜•½µM‡ıÖòı«R+ğ¬ İ£úıé+Ì¾ïbœ\çŠ»±åÍQãÄÂŞy*GÃØp…|ÑÜIı˜o¨ñ¬Âçq=ÄùulE?Êëó0¬{…0‘ö•*Š s³`@Ìõ! ‹êáãı§ú'
@Ãz~à¶ÿTb¯qŸÚîøÖ[V•+%¿sµSJVÆŠ½ª(V*ÅÊÚie}»úÕöÆWäŠäø£ª ¶Ê=g)E—_
FR6*ŞÌ,h"LŸp¾N‰®øÒWø…ov­Õ´†¼.ö.ŞÂßgì[åšÅ“·l,<%ì°„vô¡Âoä=|ÿ”‘zGqFÿäíØŠ&´¢º'õ™-ée€~¸»Va¸‹lp–C´ŒèÌ…©;p;Ö$h1œªĞÔ«.¡µœÁöq‰#¦czİÍ'ªfLU“’¢¨å\æ¨;:#šĞW\¬#ŒEÀ”,ËûÊ¡3ï‚1©Š¯]¦UAdÒ«ˆYøŠ:.(y,ò;à0r_™É®ˆöİóàWwŞ‰†é"¶MÄ…ıIˆ¨sDDÇØ:êÎ·åı?~à§#ñÅãıò“jL™—jä[ü´:ù§É•ÚLÓõªÕfTİİI©6ü8q–§q§	½‹}:Ñ•v§Ó·pÔ'Ö}˜¾=İs»´Nn3Š1_ĞQ:,’¹Ü®º4[ïMÍ(`½¹ëP¸í±‹ˆŸã„_Tşi@¹âÙÊŠ`L4¹øL»Òœ‚dÈá†ËÈPº“^zWî¶,Å1îwV´çÂík-àj7áàœq+kÏØNüÃ3uœá«©òJK“&,§»)—@ú(ñ×B¼à-‘—S%Œ\Eb0'^uöWÅrµXÙ<­”·7Ö·Ë7“G*FÙ(K‰d&µß@~É,ÜĞãÈp'cK¼ šŠ`Dûî%>…‡7äóO!é±Òn¥²ZãAÈRM7‘v•–ƒ¨P<ƒqeÓn'«/Ñ'
|0	XVC&•—ñdÙ‰å÷•E‘¯ÊI¢õTo5­‘SŒ_È±µÒœOCA"œO&şEd²i@éw°3A•´àdÓ ÖnRÏpÚqì{Í¨ôCç]ÅøÊ(ŸV6«c!‰ ŞÏşá i,R¬käÄ,%¬ÑØb;ÜŞ*TX(!­Xä¶ŒbŠÜd°ÑÕ¯©fwz©IS1­T’Ü¢âÉ³)½Üó(½àt`b§™}O©Ü/d¡ƒ°ñµ‹‚Âwü—á›ãI"*Ú²ğÒòñ& âÖRìíd€M¼Õ&ğh;AB$äƒ1~s"Ö³8ûÇ))ßpëõ§åX+Î‹sÚ¹aOrÚQBè¾DÅã.*/ãÏªUŒ|MÁwøÏ‚r}û¬”ƒYYÊÂ¼)ÑOô¦>S‹¢Ç60££¾1Pl<ú#Gs
 ·ë¹Òíè ’SŞğ0 _kß^e@‚%[£¿Ä_ö}tµäÈ›©İ¶bß%ƒõüaì ²UØ<´ã_`€ålMKˆÃ<C²ÙyYK‰ÇÒaü0¾¤Õ™~F¶dA™’ÄyòïæY*l!)I`ãªÃI«M»Œ¬¬p[$”,Çšz;hŠ°{3€Âõö#³ÏÌéäÉóFßaäaç¹Éê;JíÛ¨›Y0¾iCñe…á‹™ıİ  _yMDÎ4D•'rÜÅ¼ªå¦taB´×’ÆMóºÉæ=êöPÇ/¿aß…Ÿ6NáHñ¹†—-äD¿…;0ßYÌÇ³ +t F·Zìn/ÈĞq&!5hº/æÚ<r1>¸ n?°†Ì<¬p‰$¨ŸvPs¢s)}”˜!rÁuÅ`¿Å¼z ]ÅS«UJŸYè»…­„êUÁ˜2V•UAq×i’cS­7<¦Œ\9£Ø•SOeŠÕ›,’³œfÉ¤âœtĞ[©¢2B\×½vÏ,:SÌå^…zy¤…Ê.<¿t½w\­ŒWoT×\	ÅXx¢:òGt Ja°=\Ç¥jÑØô0£ğÎx›œôØ˜G–ã3iTËÀ,nKj¸ûö»Ô“ÔUŠªjÊZöp} |ÆÄTµ84cÉgmo„.V¹K<Waaùé°l!Wæì0ª‰}ó_Ú}~¸<âÂ¾ •£¢ò5B&.$¾ªBâ1û0ÅîWå,©œMÇÖ\dh«Rƒ»*¬u}•KÖNFˆFœ°!õ°g$Ğœˆ³g®)ÖÌ%Ô¥01<F.÷‘@°XúÈg-˜_@ÆûZö1ş3Fì[…Hç/t+ğÅ&š9±O}ÅÏ¸v¦/\àÂ–‚+a­ÇQª„´¿6EÚ¢g¥AÛ®XÏ£X’zKÅd’Bõ¶6¦‘Û0>˜xÎ#'09ƒÅ×«âH†ÿFOhdÂ]–Df'´ıâÕDÊ¬ò¥!>ÂøE
s€‹3Áğ^.¤ÑŞƒ£ã¬Îm>4e¨´9@N9.Ñ±‚©Û› Eƒ‹Û3®Õ1Øo=ÑÈ¿*!qUCßÑ0ªøú…7K"LŒCÂÀİ1k˜À™9ñŠÇ¬ú¨wO£¸Ø¾21†ÜOÚŒ:À…µMw6¥ÑzÏšLÓ*JŒõÌBãKGÜæ®î–{âø »É3ÓÒ(æiÿ±5ğòÖû@"-®¡HË@“@b*¶}KÜmI5#Ò3ó\·o e0cöX!A®Á÷ºÉvŠ=pJ3?òE¡¡è­(„õry5ZB®¹:™¬È,M†XÅ÷ÄZy\LâÁÛwy|UÊe‡.I
\çğle…9Ò³¾õŞÆµUw
U3z¢ÅIõgÔäK0z<ÂûÑãSbYËÌ˜¾Ü¥.zlLÖ›eâ¡jõy•-¶;îYØåãGn©½N9AÆ'Š„‡Ø¼ê´3)Æ)™êã]ªVÏö"Oyv\3IèRa„ÍKea¦²:¾‘c›‡¢›d§R’ ±JbW5Õ’*ïâ’¥Ë¤BD‡:îÈ	¸<Cr7ú¹²Û#4´¹L,+M‰…œ	§¡¸7=¡HYx7ˆ!WuˆYÚÉÅõuÌj±Å9}à“ÒYÄıÅ©Lˆ;¹ºg'jƒ£µš[
ß&Ê´„¦bêä0½×©g ¼tŒÜ•±½Ù½Vt…raˆUˆNÿˆjŠğô”¼¹Y]N
ŠôåQ{[Ğ[ñ±¸Jh"t*æ YÍUG)«½T©<d†J‘¾U ğÌ+Åj¥zÆôJ1^UvJª
¦ÇÄª ÙÍ¥õïV•
ÒM+³G³Bç*©›ã½Æî3"~4DÙhL‹ñ}ûæ)"Ó4OÍ®.A¨P!†Ğ‹ (¼RÅä)õ ‚³ßß_Dçmáêƒ’O¥ªÆoBêqj¿ÓN××ce~ß9S•&T!ßÓŒ¨»öuÔVW”›²dË2Vmë¯-µ1ó	ãÊu©´0n©¶b(d	eµ q¸_ß=HÁñØÙ†[¬DÏo×‚ìôQŠÁòqŠ$eÂ”ıqSA	=I!ÅÛ=N=~
	”´vJ¦£ûîĞq²›Ö¨(kQÑ>¥5W‰s%3	ıP¶­d¼òÔeœWŞŸ\9prEßs§«™6-/£J(éŸY¾-µ>®c¡¡¶ƒŒwgî…E{ƒô}oÁläü›Éì
bb­!ß3"®İ\có! 
3« /õîyÌØ50ßÁfÔÀXø¤ş”’·şSğr¤y-P'¨¶Õ|h#.=Ğ=ÿ„OQJÀQ¿VmuBhŞ¨i! x8‚4@‘Nm2¸X°‚4pqMÜd ±i@C]ß8`bÓ0'òªgĞñ‘YÄ¼®öq¦h;åÜ‡Ÿ)?C\côwëYQOÑsı E«=à::ë¥÷‘Àªc*"4ÕÊ»ÃiÔù´Àâ ˆORÈ™í>Îá5-T¾`»›5ËômØìr]Í?m¡"ÂpøÁ¥#nS©5„:)–Êm á/|KÿNz6€—Q%Ö¤nA¬)0Í4Qeø”~„ûÓ>û¹N’±˜mŠLšª2@­)r·vÌ`üÛt0Å½Bw(€ÑËo`ü6h••F¿ÓèwÑù˜‰'Íf×*âkqA/šÄ]p7…JFğ£Œ ø‚õE@~…%ÿ®.TQ|'„xa»™ñ†;k·ÂàÆs«Ğë5IÉø)<<¿Rƒµ$Z#fŠH-aô-{€Ãa*
Õ˜šş\*‰¥Š/$Y°4D§0¶“¦|GÄêjvqnÈ/¨*ªu™K+×Å¢díuì¼T¤r·5Á"¨"ÕóBŒáµ‹}TZE×8İğÈ5Ä5DS†Ûz¶ëûh´/ì„ˆTÈälÔÅé‚;ÔP÷ş¨Â9)¼¥ÉU:6‚³JyÑZæ¢Yˆ|ış-áITÈĞVïZ,÷‚`èo—JØP£K™ ÏƒñCKK q‚"•òK…í\n…½nJSOş:‚¢ p­×·CÛãÏZÀâşèl`sGäôöåKP¨@ˆÛ³Ûx0Ÿƒ	JËûğW6rè¶
T}K”%3¯2y¡£j”ö½;–rÅÜ3:ö7a@‡WrˆEfì[l´îòòÒ0	 ázİ’¨Î/ííî4ZÍ" }²ùíïÿ£İì¼	¤§éıT7«Õ*ùÿØ¬Ìı<DJ3 œuãı”××6+ÒÿGy­¼ã¿¾µ¾1÷ÿñiád<øÌÑ¦[£§J mq·³Íg6tSR¾Ê¢*
¹jãi½ú%k‰5iùi£U€2-Óê¢¯Œî‡­~½Ê¾vÃ÷Í 8óFİî*kÁÂõ£å¡ë‘™7OÛ	³ø^ Îˆï­À:G½4-Gl„Ñš:Â;ƒ/Q¿	pÙ‚ÒÍ„¥÷L?ØávO¯ø4ĞäÜHÉ€x–cëÂÆu*‘E~àÙ´ Wtj',nÔ}2vØ@ê5*FBd„G]+ˆNóÓ`„†œÓ`Ïaq?	©³"è'ûÎF;ö«mx¬|m”·Œj¹²	r'029µ]º™yŠòTÌü¶ĞÂ„¸$Ë=”8P?KşW"{ND¥:Ö@Ğ„ó4á;³"ëT<äÃ?¡¸Ú×…ÏÎÈK§u‡td1NàBûLy=_3“5x'R/	B˜PÅìƒ¹´‹FÇ‘L¬ÔŒz ›˜]¾OßÛ;åÑhwÿ±~²{x`@Êuäú¾­ÂğÊ˜¼*ì]i*Îú5ıªv¿’F0Ö 
LÔ1Œ¨4(¦Ÿİ`H×ó[ÕrÛ»_í‡ĞôËŸJÓ4uLjû’Š|¥Ãê™ŒU¾L†).­)£¢±Ü  DÅŸ€
Z¹›y+ĞX–à%ÏÛxxºF‡W”5yíX5ŠÕÎucuêv}x‰‘<¾&n«ğP*lÇ4Æ‚Å[¸áò t\óe:W¸ìâ4„YÜIŞâ[¤x0fÎM¿MäOæjõ„#M†nÒ`ñê˜ ÿ—«›bÿW…_[¸ÿ[¯ ÿÏ¹üÿ é/şæ/ıù£Gûf›¶Øï%7Àwş
şTáÏŸà>ÿïé@ÖONÅO,ñ?áÏ_Ç²üYôşoAr0Ğ eôAêD{¼˜´pÔÂŒæÿ±şÿmşıÿı»;õsRSì2î½Ô1aşomT·bómk>ÿ&İ×şÿŞ4 _¨ Kğe+ ô+uÏÄµbyëN,Èş(Ë,Ÿ‡‘’<¾ÛU¶IM‚Ø¢;AÓÆë ¡™ZCà‰¢°q‡O÷­DøÔ2-†(T®qG6?7¯§Î•˜ïù¼¬×^âí¥™7\†ĞhUjKoF¿yÓÛ~sYb¯c!,Ş²%™³İéÅ¢E_Ìx¨3¿+ÊpVSnÔF¯ûZp¡ij²ÏRƒæ)ÚñQ|"Œ.ÊÛKÍ«dègC›°(§{59Ö"3şI8‹@&Pã—È× ^Ëhøš†üKÁ¤æÅp³Ó"„Äóéº¬h»Çáğ†ª…k¡%ğ± Íß“ÍK aH™Œ-»Àvh[‹ç¡CëG´ìUìì|¾=Ä‹NE¸'­0"ºëÔŠMZÎŠß_ıX[¢ŸEbÑ°f8K÷ÀE¼¤İªÂÈth¯G1$C<ŒGØqs\%Åí¸®sĞœ@®|‚»‹ƒrà KíxğQÁ–ÂL=™I™ÚÑ×>}Í«!¯|ÅëÉØ.-N§d.x«åÂÙ•Ì…á—ra6»—Ö©X«í~f¦pÎ(¹Ûãsó	å¶¢¡ŒF$úle¢=ÕNÍªeRP²£kİam)û¾t{ü­ST~ƒ/Ò@B¾Tíáõ½=Œr¹Ãú0ó`mşHnÒÃLFm	?t˜±“¥íö]¯f7Ìæ,üîq ıÀ_ùüU4¿/²ÏX\!£$4prXµæ‰¨%d"!bh_EA±òxb(qC±¨¸u³âd¦÷¬áÍ (FZÿf0"2	âÂvkKv"ÚX`…¨"C,N£(FñhıU[ÒLÁŠEiÆˆá¼$>¯šM‹+C½)gè4X¾íÔ¢ûûÖË‹ïÒ`˜„éĞàRm‰?|ÚÆÀGhÃÀô®d³:>ÌÓĞ”ôáíQ±)–§Å"	8/v¥‡fñB(©«O
X+Y\–?ã»³ôåh™Uı¯jô6Ë:¦Ôÿ®UÖÖªë›ë¬Œáæñ_&}æú_GèÿõŸwîÔÏyJMéÎg[Ç„ù_İÚJÌø5Ÿÿ‘æúßO«ÿÕ\ş$ÕÀªÕımp\¬^•›«ƒoß„/]<•zñÓ©Ï[à·8ŞèêÅÌq·M=¶K)—ÁĞÂNòÿÈËòı­1“äÿõŠ8ÿ-¯W×·¶0şïÖVe¾ş?Dâñç†Ü
’Ux´…èê<®]ø¡*>‡½#˜¡ørMyÙ
ß®‹·uÚrË·âí±²M—ß61ÄH¸û®†x‹s¯büFø«Ñj6¿ŞŞÚÏ-Üt.±¿º]YûêëíÊæÚæö:¤í¯¾†G€ùåìÛg•Ò]«Ï¶IòÿÆ†rÿ§ŒñŸ×7¶æûÿIóûŸäşG<”Á—*ùgÜ IÔç7@Æ6`¶’úÃÈé¹‹ŞŸàÍ;Ö<|6 ŸšÏg%Œ¡rßu”§»ÿbÿúV¹R¡û¿ëëóû¿‘0|Î}×q›ñßØšÿC¤(NÅıÕ1åøÃşm«¼¶‰ößåò|ş?HŠE}º—:n>ÿ×¶*Õùø?DÒƒİOÓÿFukÆcc>ÿ$%"ĞİC7Ÿÿè
d>ş‘2âTÍ´òxı_¥Ìõÿk•õÍ*?ˆÿësıßC¤İñîzŸça(
§ÃÎCoq2ĞØŸ8Áxí0ß_ÑKÿë…ÏâÛd¯Ç"PÄ<Æº»9ğs¹£úÉwµEü{{‘\İ¡©·xA§}ò¦äËİ9ŠÚ—l0Å~ú˜‚)…~ç?÷”›v¶uÜ|ı‡U`s¾ş?DJ/¾‡:n´ÿß*£üWEÿoóñ¿ÿ4)xõ,ê˜ ÿ­­­¯áøWèOïÿo•«sûI³:3‰Ìî:çéŞˆ¢‰‹ÖâÁÆıOy&?‡kŸéY¬V:~KŞ–Q©åõØñkü˜•ÇU"âün%5–5(2Hì¬5õ T¸–æšÆ«eö+öühÓÎ·ûn‡œ)‹¶ø–Åº6ºæİc=~ÂJçvxËÙüˆó^GxòK<>5RÊÉaãĞˆz7£–r‡ÑÌõÁ;Õ45Ç°œÒ J5(eˆ¼F×
–—D\ŒÆ½´Êò PûƒS^._ †aÀ¼L ¸9@ KM~)=öóì1SZQÈÑí%ºùÈ$DÛ	–ãPù½K¼£„@·`¯/ÈÂ¾ß—åÇnµö”òÕ¨<EÍê/û¢Õ<Æ‚—ÖH—v;6f|X6/ZYoµ^7`“zØ %Nß<š¦möú±ÿv)†ŒobÙÃ¸„‰ì8 QöÈ,Å²GØçÆ ¼D<·@gTàE„ŸTğˆ¿(w'$#7brG·«_íµäüçoˆ%ğ7Ë¼¿a<ËÕ
Vs,‘ä8E8áÅ"|Œ+…”¢¤†—qSÊäŠğ3©T„µZOÍ÷Àu K'Ÿz‰ı¬Súşø×ë˜ ÿÁ*˜ØÿmÍå¿‡IóK?}éç‹µõÛ“"+3*¶kq@ac÷Ğ7n*F¥ü 7nbn}#Ç«¸û Aw2r%÷ùwÊøÖK “¡sƒ¶N—İwôÄ°¶A¾ı#ü,—ßå®çŠßŸiJœÿÎvé§4Iÿ³Xÿ×77çöÿ’æëÿ|ıŸö–/0ˆÜ3~¿w¾Ş+M˜5¼KËz×¿bç#Œ&ÆİÊ»çĞ£Ç…w$¤ı™Vœøk¶ÿU }\ÜˆÇ)Ğ¥@ã÷X1`Ï^ìí±"Úüäîœ™F»Ç<a¥`0T³ãUìê“_Vr÷€¾‰ám§íQü2óÓ!±¼Z]][]_İXİ¼:wv›ûÍƒ“úç‚Uazñp˜¬V	“+ÓâOˆÍˆ¿› ìS¯ÃŸ*éöŸ—}ÿ”t×†ÏjfRÇ$ùo„ıçz…üo‘ıß\ş»ÿ4³	‹×·oxø	¥3¬å˜¢"€’ Ì§HkFšÌ¶ª‹k¾1&±©™QŞ2 Ã€1"’É<:™S¥0ùåÈ4Šâ;ò0½ğÓzmş´qĞúÌr(,õ4ÖQEz“å4¯,t‰#+3É5¢&˜¢Š yÃ8Ç†ÖRxUZtÏ¿E®¥³?¶L'ƒÕ;Á”X×saGÛ>JÅˆN×Ô8SÌ
J%`Í¹Û˜mí»?ê¸¬=LÒ,:¾WÂËr¢›âßR¬‚&Ç.Áç%S*Hìb¨òÃ€¶Ël@]ÁôµtDñIÕ´ĞS…ŠÑGf,p2âœ´;¼9d7e$x˜¡ÙqãØ¹4=QÌÏò×¸ØÛHâî2ó,ŠK~2Êì8ôlõ|bˆaŒyä"1Î°İ¹×È Şæ”ØÌ5<$F ]vä^™Nà×+¸t½wŒS×
rõóÀòâ/YîµàËos'WC«æÛ0Á­±ÕDt²ç8k®¸{Åa’…³¸ËpÚ¢YñğİÏ²±…â`<×|oµ‰æn^¶Dd÷Ê:ÛÃ£@´\åÀÜá-`<w¨‚ƒv9Óë‚á(¨U¢~ğ$XÈ[Â.î¹kƒQ?°‹X@ç§^Óo’tùO®áùÃÖ1AşÃë>áıŸj¹Lçk›sùï!ÒëæÁóİƒæÛÜ±å]Œ>Mê´ºÿ/÷úyó y¼»ó6×jî¼8Ş=ùşôÅQ£~Òl¾Ü­ŸîÏı·^¡¹HíÜìû³½E2O÷‘ôù,ùŞº˜a“æ?¼æÿùÿÜÜšÇzd;–ƒë÷)Œybí$zr¸8œv5)àS·~îšbóÔ9•Ê¼Ù©€&ê6¶BıÏÆ:ŞÿßÚ\›Ûÿ<HšëTıOıÏU@ 
‘¢ôYá‘ö¨ÒÈà~5@é„wJ )jºƒh*è·TeÂ!OøÉhƒTß­÷«R, j‡GÍƒFë4Œk^ËÓ¬ÁPæ¥:ï*ÆWFù´²¾^ÊëÊŸJdvÇ·¤sg®ê)vĞ³ÜG64RUõL(éã-¼‡}ƒ¢ÅI[I×}©ª¡˜ÿî÷IÛÀ3©c¢ı÷ÚZÌşk«¼1ÿğ in¯ovÜ^K›_¬ñVC8iUNİBÑœ„7‡'®4§ß?W‹®\PØi× }Aép\¯›ë´·Yø2çá™B»@)^×tìÉ$^ÿ+	‡Øvj´vú«i°ÛƒNÕÔîï¸N ¢¾å…,êLÈüó jÖ4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4OS¤ÿ6±Ñ{ à 