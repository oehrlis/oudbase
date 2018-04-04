#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: oudbase_install.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: This script is used as base install script for the OUD 
#              Environment
# Notes......: --
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - Customization -------------------------------------------------------
export LOG_BASE=${LOG_BASE-"/tmp"}
# - End of Customization ------------------------------------------------

# - Default Values ------------------------------------------------------
VERSION="v1.3.5"
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="TRUE"                                  # enable verbose mode
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"     # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"       # Full qualified script name

START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
OUD_CORE_CONFIG="oudenv_core.conf"
CONFIG_FILES="oudtab oud._DEFAULT_.conf"

# a few core default values.
DEFAULT_ORACLE_BASE="/u00/app/oracle"
SYSTEM_JAVA_PATH=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_OUD_DATA="/u01"
DEFAULT_OUD_BASE_NAME="oudbase"
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_PRODUCT_BASE_NAME="product"
DEFAULT_ORACLE_HOME_NAME="oud12.2.1.3.0"
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.3.0"
# - End of Default Values -----------------------------------------------

# - Functions -----------------------------------------------------------

# -----------------------------------------------------------------------
# Purpose....: Display Usage
# -----------------------------------------------------------------------
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

# -----------------------------------------------------------------------
# Purpose....: Display Message with time stamp
# -----------------------------------------------------------------------
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

# -----------------------------------------------------------------------
# Purpose....: Clean up before exit
# -----------------------------------------------------------------------
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
# - EOF Functions -------------------------------------------------------

# - Initialization ------------------------------------------------------
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

# - Main ----------------------------------------------------------------
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
DEFAULT_OUD_BASE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/${DEFAULT_OUD_BASE_NAME}"
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
export ETC_CORE="${OUD_BASE}/etc" 

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE="${OUD_BASE}/log"
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
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${OUD_BASE}

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
    echo "alias oud='. \${OUD_BASE}/bin/oudenv.sh'"                     >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# source oud environment"                                     >>"${PROFILE}"
    echo ". \${OUD_BASE}/bin/oudenv.sh"                                 >>"${PROFILE}"
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
    DoMsg "alias oud='. \${OUD_BASE}/bin/oudenv.sh'"
    DoMsg ""
    DoMsg "# source oud environment"
    DoMsg ". ${OUD_BASE}/bin/oudenv.sh"
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
# - EOF Script ----------------------------------------------------------
__TARFILE_FOLLOWS__
‹ WFÅZ ì½ézÙ‘(è¿“Oq±Z„Œ…¤–²©R¹!*ÑæÖ%uÝR™d–€L42AŠ–x¿ù1/1çÑî“LlgËL ¤D•Ën±Ý%8kœ8±GœÓ8iÿîÿ¬­­}ûø±¢Ÿð¿kø_ùQë7»ÿ{ò­Z[‡_ÿN=þÒÃŸY–‡SXJ–FÛA³ápÁ÷²óï?ÉÏ)œ:œÀöòYÖÊÎ¿À‹ÏãÉ£oéüŸ¬o<zGçÿ~û;µöÖRúù~þ÷~ßF8³óàžjÞÝŒv</ÂAœ©Îõ|–ÅI”ej;ºˆFéd%¹ú7Õ›M&é4W«Ï·{uèÓ£³hÅY>³,Rj¨?®?ÞP?ŒÂ<?ÎÎÎªwç¦£0Üù¢÷ÃqÔâŸMåÝø²3ËÏÓ©|ÙË£a˜¨ƒè|:ŠÕjeu•Ñg­”>û÷\ Ðê§cèÝÄyuoør;Ìí¼kël­=l­ÿ¾9Š.â,Nú†Öx8›NÒ,â¶ÏáèT¯?'¹ÊSuÁ?ç‘ŠXxÒ¯_…™šFù,Qýtá>Ó<Êô|ÇçpJ¿Ã8]©YÔ0ª(¹ˆ§iBG ?Og¹:~½Ý„©á+ZâfÃÁÎó|’m¶ÛgÐrvŠ{o3<2¤4€i8ýnÜ½…w›[k¸»Ã„‘öÒA<Œ£Î fQ¤`E †¦‚-Ãi\Ñ†è›QzF»§Sü:sl	ÿëŸ‡ÉY”Ýé›jˆO:ŽÿÎÓ|êHÑ{ºA¯¶OŽŽO¶÷Ÿ­|pþÚlÖ [ò3¼O­tzV»¦É»É@¥ÃÏ\C@Cm*ÏF¹zŽfQö‰	^wz;ûÏjë­‡­Çµ`û sxØÝß~V;>zÕ­©e?÷ QÃÓQÄ'Ã/ád€‘ŸôºÏj/:»½ÛtMOá¢JÀémíŸìwöºÏVV je­ïžlïu·ŽŽ~|VkçãI>|±³Ó®|ð\·ýî­••ZÐ;îŸ¼ìv¶»GÏjô‰NNiåƒ3ûµZ}M	‰W>Ô®ëŒÈ+jÁ^gg·³½}ÔíõžÁû÷tÂµkõÏƒîÑÑÁÑ³µàåAïöphA‹Øø¾=ˆ.ÚÉl4R?FýóT­`œ­Îy)my>ïày¨³¤¸÷©xÃCÝÝÅÊzÔ«,<‹VëêC‘ânÇÙd^qƒ;œmP•Pž>ÚN÷²3UÛÙq 6yÒF!~jž_LU3VßáÅßÙüÙßê~¯šÛê;àïƒí}øýþýÁe:¼€ò½ú¹j¥šçUƒ&ö‚<x9ü1§÷EUïŠK5§û´ª{ÿ<ê¿#
=&£¸OkÎ Î¶íÆÖÄÖMÕOžmÇÓ¨O\`/L`7Ó9ÃUBî9|¢&òÑ›9½K§‚?ð‰Ú]Õo7=#¶	G½{ð’knÕOðáúµjžåjMýü~èmn¢0é$ƒÿ˜S£v+6®éëhÌW·+PÅêþkŠ>ÆÁup§Ü¯òFí1R1)Ëã1I/ãÉ—¸ÝíÕzðö·³ø
(â‡õo6\W!ý€H¾‹°Ó+¸É™:àŸÃ´$@MC]ƒ Q= !ÈÁ*T	H@Î	±>7p<s5øCÕ€ïìuO ön@VTµ?|ócó›qó›ÁÉ7/7¿ÙÛü¦W«?}êt=:šß5YÒ™ôþ„yþZ#žát­ÕÜø{¯A«âGwŠ²°o1¿F<1÷º¦ž)‘Š—@7Õ2Ä¢¶4ò<dÔfM€xyjêc¢c3tî¡ééÝ§ÅÃ˜fp•ô¯Ùy<ÌÍ_—çxßiÕ8íïa½´ÖAêMqÛÙe>\º»Ê.Îkêì´¼ÛAšDešt‡Çöý÷U{úA¿z‘7Þ]ÓeC]&€2*’lj f CT˜¢÷q~Ç²Ð2FW!+	Ô„¯#6Í×ê†Ç"UÎZ¬]2µî4J
Í»°EµRÝRo@'>Sá8%$¤‡Ó³êÈYKõàRÍˆ•!Yï§S”3@‘ŒZî7B¬V‘•×o:þã¥ã»R‰	€Z È'iNš!#eò¸óüZÁTðÇQgk·k¤™“ç^p è¥³R7š'‹rØû0¼ãJ‹Þ~Ö×—¼•ÎF!OgýsÖq_Øo1Ì(êíÊ‡—€í–^¤;ÜÃ¥ûí¥Àå»¬¦acÑÀíÿhiÿît
ÂåHzð»/Ýw§ÓÎ’å1
õÓñ8Lüá6>a¸AæˆäÎ¨8 ùÑ²‘gÉ»$½LÔÀˆåùÕ„Ï¯w:!°ÀðþpÙð{q–‘ÐVÜÝKsô-\\—ÀÂêˆ–$SÜ— ²Q$€å’Æ4P©ÜBsë<|~|Ã#ƒ»|äRŽÂV¼)`uj÷hÑ²2‡´ÝÛðWÚg•F5oýKOŽ×öö »’,•[­ádÈ…;ìŸþT/èT™e¹º“$Thçáh”zæÏK	æ+AQZÑ	µ‰µõçºÄ¶ü5EãôU ¦V¦«§¦coHÇ^cšÜƒƒ¢¡ÒÙ@ßo;ê`¡uîP:ûðÁóÙ™;:š¬Ð<ÛäžZxÒUÓ¸mÌ¨î ìY	Á/ÓãÁ‹Ï7û°õh'‰ó8}žFbT7<î"“~8P¸ ¨–N¯-üéf,üù‚cÀ›yF	ZU­ÊB±§o¬|u5k‡‰Íò‰wÏ_®úø¾ù½j
_»ôf]_ƒÙp®]
RÇ'´”3J[\ŠÐ •‰ŠêïãP¢	‹¡#)­¥ð«¦)Ž¡Ô·xÁØuÄ¹ZÀœÞŠÑ²ùg¸“ÿ¤ú·Ãã¹T5Çªâm»`tÌIøðXw't´ú>‰Å$3ÀÛ?My¨½0þd?ƒíù4œ¨š·¡Gk5´>P'€¶cJÄ€„EŒ`÷>Ä
öÉHõg &ä’0~¨šÀƒ¥V¼_gQžN Mýþ“iŠ×ù´È#„ì$œäh¡cMMz«ó‹xs{ó—Íîæåd£°±
 Ÿ¸*Ày]L˜kÑ¿¨4	ç»¸®ö®\Fô<8Ðüà±àmlÇÇ9-~Ñ-\#âœ¶Óº:êîîluŽÉ!R\U·îccõ(Ö›ÝP+\FEÚ£¡þþF”hZ…+-‹r¼+N,¦
þBÔ÷Êú!6¾ÿ·õ ±ÓbåÏ0Ç9ÉH*BærÅ4+SÐóƒi_¥3z0{¬J[Ç6´MQªî’b9÷‚rL£ÏaøÈ]Í|z#`0®¦“ã¡)lÕ®êÿò—´0ÌãáUYò.ŒÄÜÉa9—Ê®¤ˆÛ‚9r)Øüëf³Viy¿v:xwDwu?„AV>¾Ù°][Öû{a¾å>×eì“À‡e”V‹|¶|G³DZ@Ó¢tñZQiÝl²¯½9œÆ`ô|’¤M }ãIN¿NÓI4Íã(Ã•ÃG;»±í}ØìîQUnæS};p­¾÷Ñî.Ì»grÆ—÷È{p4/]Ìë^-ÌÈ¤áàÒííÐŸÃðÿÀCŽp@Ï.¤f¬îgí¿­´›íûîU‘Þ¿¤À7Ÿ‡ýwÐGíl³a<åñÝÅ˜âÕ> !´³<zŸ£³Òþ°ÿ4k¿MÚªýôzÁÀuàœ–Nð7i¹é\ùSš­™gz4Âú£î‰ÊÜ‹¦ _"ÖöŠg¸z²<¬¬¯î—š‰:xë¨kúW8kP¼uT[8}R¼V”HÑ×Ô¦oÕåsQ—C´=²šÌ½PÑEUww»sHÿéyF\rLÇ*†]ù;êWçÍ_OÐA´^¾S÷ŸwØÙÿpÔ{V{›4ß‚.û‚~­=Ýùaÿ è%0¼gëOYG|öpëê«öß:ƒÁÎ©,ce?zûÝ}œéþÛïÛêlpuå!Üå-Áçugí©ºFßÐÒ¦è33TÝ¬×»ÎúÃŠÛ
'øx½Òn}³c,å:A®hng‰Ã,¨˜#ß,tã<«½_OñtŠŽ©ÁÜH˜. ]Bæpó³@6ÏêÔÅ7ÞŽ‘RUõ_ÊHÉ»rx ºMg{ogßåsÙl8ÇÉøl5s{–sy¬·µEG_Én?ãäm”™³`€¥Ýc¹F…I>:×
ïÒfí© ýµj{!i×úž|«~ÿ¿ážì£Yp„×Gß“Ç•åÓ.ÇF%ˆ|”ß¨Dyø'-ª{{‹„ý[JÖ¯ŽvŸÕ0€r³ÝFÓPïøz“u§lÜ®ŠÙrâè†*šIaL]Øét–8’ßeÖ™gS¸Yo(½…•¦rBçÿùdFy¯(¼µ,RÞ}ýsy(k±ÇQ¥ =zT†()D~0‹±Ç|®¥ùŽÛ¾«ÿÏA¤ÿˆøÿ‡kß~û¤ÿ¿±þ5þÿ×øù"ñÿÿt±ÿUqÿæFüsÄýKxTZ{e]A*ûòÿ/ò¯î0‚_}áÇþ/_«}rÐ½sw!÷ê7sÿ+ØW„ö#®|FÌ})¸»÷½jŽÕw
ÀG7±g‡Íê'EØß<¼¾¼æ] Œ¢;]6§wi{¦÷^”˜GævßVß=ßÙßvBó)´nÃ|ÈºËüluÀø^®_Ÿ¯øf•R=É¡î³d¦·+Ú³0oü¡ú®ûŸ¨–vŽ_Òvi460dd5‘3AæÍ@ZyA•óüV2 ´æuÍÄãŽîâo&@}Í øš ¾f |Í øçÍ ø‚„ùÇùÏM8 ÍÁy¿!9âMX_…$ƒÀ! ÄRøXÆ&ñÜfˆ…õT‘ŠY¿Œ æ R‚¨5A[9îSŒ–Ò“,%IÍ„ÜV‚ªˆKÀ_èñÄ$apQ`>9’QÞtŽöq½JTùqu
Š½­Îì$-µŸ¢ÃE9•M¢>+Ö%"ö5áâkêÃÒÔ‡Ó°ÿn6É*r.] %èŠä‰;Šú_žœ°¥ó¦
AÖŸS„ñ£ÇË†Úöúê öËiœGÅ öåÙÏÌkMÑ†…ÛÝ.aÎXr~ÿÐàz¡Ër”˜¢Îk*eøÍe<1ËqˆPkÔbZ-q|7 ÎÚý}ž^ª1^5Šïq×:‡™MhF+ØÊêe_5Gê;7ü¸î5;FFµ²ºº"}šô	ãuÛGWMŽ”Æ×n8òGÜõ{ÕÌ`+Ìå Ö¨Ù‹µ¸@‚ÌÄ%ë_&p_ýOÜ× %9ãWŒÛWGÛÝx5D*hN“,‘&.·>?ÂŸ'„A`:‰áWÿ3‚øÕFñ«;ãŸ©s`¨I'y4Um¢OÉl|
PˆÉH,Kld9Ô8Pïó(@lªCÄHâ“¸<Ÿw
û N6›pÖA±$*µ^‡ÿÕiYwü?ÞŒ7»” 0Üü5âÿ{sBöÇÐÐ1û¯¬j½T·ýˆfÁ¬ý¶Ñ~«Úgõ/–;0Ä¶œkzæçsZÝEhOª‰eÓ˜rVÙk‰(£à«Šàvâ.ÑÄi_.âATë8‡ÙÒRÃÕ+CÂ™œ,ŸKa+£Æ‰j/àOãš;rlðÆmk’òð´ÒF\èX0Þ;<­{¼%ô˜G«”kX¶ý<4ï£Ÿq&ª³–tù±ãÎógåy*4NvwÈÆ”åBÝÿÛ½ûÊäš3!"Ä¤^f¬¾Z[ÐYpñ‚ÝÛŠ­ÏçÈ¬(ë"ú¾e»Ý9î\·`2«í5K$ÙÅnÄÞ?</M–Æ*Y•n{ï;ôÅ{ƒø ­	Z‰‰ö`||ëÁÛöÛUøoý-®¢õ`¥ýv½}¿îU:v%ñr†—©.háìlw>Ë¢EX-=˜ß”×oihá
‘Írªî7î+ø¿ºæÑ’þšD—Ä4â¤pB•£ÛÀsúøš~›ÈÈ…X>bÿ¹ñéjsçJ£13ÞMÓ‰J1¨ÞÈÀþi‚ýM¡§·A’9B~åf+f8PUÈ§R†( 8P*;¬Švp´©~2Cþl4à,Mû‘"2¤Š º)ªíïâ‰'òhÆ^½+âC ¸ºJ¿üaÝQqúi’ÇÉÌ`£Ü"ÿ~0¥¥t¿¿IîSõÝw7j£íñ°ŽˆLá›xyx¬—÷è˜ÊJ;ñtÙ,G•ŽÿäLªÏÐ„m^E¦MøÉ¹S²ž[²Vê_ åJVåß@õj½CÒU\ó1ð˜(—:®¶uÝ·	PÓ¿ýMò_ÎÅ—Š¥øëf9³	"Ã^õáÊ½˜„(~§ž¼†öÀ¡Ã†\áªà46ûÓ™Ûé´ýöÌÝ;…”¸hÛò-×®âéŽVi¾¿ƒQTs¢Jí‹D	µÚr0o¡“cáÖk¹¼ñZüÑ/ÝàCf 5BÃïäèlxB†¦o3LÂAÒºpaº%ñ‰KII;ÖÎegl÷ç£'*ƒ§œüÆÅ8Ìw5g¯n+Oš‘áMQ1CFµŠ\½©[”ä1ä÷Ó£4Í]-°±,çþO?mžŽÂäÝæÏ?ß¯— ÌòeÚkwÌº×3Nú£Ù z>…}kïuƒ7X;»ß~[k¼­µKC´ïŸÙmø«îû9çÃ>£2‡Zò ËÙÙ¶K»¾é°E4,â…KwðGoë`o¯ƒf±íì_·y¨æh ÷ªÙ4Ñi’}p£Œ™e Vms.\@c;\ˆT¼6¼T÷zœØ±N¶Ã+	P¸ÿ‡of÷ë-é¦ %ÁQá$ƒš‘ª½MÊ-Õ÷÷Òù)õ¨èàgáOe‚ËâM`>ŽƒHQFgñøMøm•xtÎWòo!	•fÑT'¢:5É™¼BöêÞôªˆ3ˆX‘Ô¤²É%ÅÀÛð½¹œ¹žˆC×¸;Q(CBHîƒÒ(·òâ.?4òìZ}JLs%üXàôuªÓñˆTß5ªøÜêO•n÷§ž°@’ÇŸÊ(’ù@¹9d³>š‡ M\Áš’8;s£PªcNn-ÙÒË¤"¹¾äu:5>3ã(‡™ÅT¦åLAÎ¥Õ)ÖçØ¬Éž‡YL:ÿ‡Õ˜HþÏÆÃµo‹ù?Íÿù5~¾æÿÈ‚Kù?æFüsäÿˆâkþÏ×üŸOëkþÏÏÿAs$¬ÿÕîîòåóô¡<ç»}Œ¶Î¿v»‡ÏÝh eŸ=¿°‹7Qô.Cbñ.Š&ÜÒ	Ê»ÏjÍ¦þ}ÑÊØ~eÛª£ðìkjÒÝLó+¥&åê;DÃ¡$%“U£:»»óòuÌ¶Ís¥^I´»îìou÷ºûÇ];*~9oØwê»7Ýî_{v\{×.Ý»¦ÒÑÀDAš¡Í÷33¬†ê»ç­¿¾:¼QvRqY:;‰‡øšô›~ŸäÓò‘¾æ }ÍAúmeÁ|ÍAâŸ¯9HD¿æ }ÍAúšƒô5ékÒ×¤¯9H_s¾æ }ÍAúšƒô5é·™ƒ”o¾ÛŒ7Ç›ÃÍî—ÈAÊëŠ]•9:ïêŠ\ÕßþùK”qÄöÔ_)ã(T ÄãpÄO9“8Œ@@ž·®¢³üí¯ú9üîºðrmýk¦Î×L¯™:ÿº™:NvÆM2u$Þ[zQn‰„¸H7’ÇMTÞÀUÂúT?îï5ªiˆø#Î†:Çf£T=Öî$Åü3Øï¾9A¿Óþc2üÁî¶ýbuåƒmxÝ*L?çN¯ÈÇ“žÀ¤ÐIy½Ô7h| ŽÑØ‡S,êl—PÑÙ?¤íÒžñ˜h£þ"ÂL>°_/cb€mÏ¦gÒ"#»+¤‘ý-ýãs¶
E×“ã¯²5/éÓR¶ÿI[%êú5i^2’uS2’•M2’m¡ïr1åv©HîX7IErÚß<ÉéäºK©HK×RŠT5úÒT$Ab)eÚVf93Ü>û¨,wÚ»Œw(„Õðµ’hàP`«[Ì…»D×?éDÊÃØ5/KÍqH½,ø×›#š÷ü;háP&æÈz«’rdòˆêx+É–ÑÒÃ5^€â&«^ùà¯Åõæ¸™/ÅVå„4?¥Ôciæ‹Ÿõâ žì 	ÚJ“a|VA–K¿ÐÓn4Q{€ªyø÷þÅð& n»ùH<C+?û;SÈ­ƒýs€éLY™CT¥Û~~ójéY5^Î{—©
fÅ®w4|%œAæØacªI|{XÿÇ@pq¢HÎeŸŸkµ4ÏÊ91É²’qYV7Ï°š/$=¯¤v·J¤úü$ª['PýÉS7Kœø}râÔÍ“¦æyÑ+€Py¨óò¢
gÙ™å)Æ¼÷ChFÊ’`ßýƒ#ápÉºF!'YÍ†
jÕ'î‘¼g?r¥ŠÍ¥fOÛ+Ÿùt¬šÓjrUÑëzË\¶ýÔÝÂ0Ê®¢‘²¼îò¢‰˜þh÷Ø|cÛmÙduwŸÈ¶ö+%²}ýù¤ïYî/4Çâü¿o}ûøQ!ÿïá£¯ù¿ÎÏ×ü?Yp1ÿoÄo:÷mzT+#úµ=§`ãûšøÛÊÔ¹{²¯ÃiŒ1W·O™’x˜W;4Æ¹ÎÀ*á…ž¨¡+JéjR0Rô>¦IâbðEM¦qÒÇ×ËˆUpMg•/ˆ
¡¿Ê8C‘×¿È…Š§›œ(=O#ò^9SØ[HƒN&Ó”DxXy@š_EÐ«§Q•ëV9Éô&]µÄ¸ßÌ'(ëWµÔå9Ü84ê_¦SeÅôy«‡¹"œféh–Gl3°Ë²	6îŸˆmí ¨ÿ¡ÅrÑ$5´ô^žô^muZûùºV¯©§jr9 5º^£Ë¥=øü°csCûè‚†(óGÝ­£nçØCgöÎ*)Ú+EPÛôŸ(œöAÛKàkèpÔÆ'‡ããîÑþ³ûû)lþ½Óü_kÍ?4~°¹úüÿÖ?<º>X}µýŸ˜ý¸³ýq»×íÖWîÛù8|#à¿HÙîîë§‚¿ûNþææÚŽƒ>Që›¾”ºÏ/Ÿ©þœÞs?„óÂÏÚÏzæÃGüa‡ ¥?|Ì:¯ˆ›¯žl:Qdi@©Z7ÔÁþw§˜„öönO½ÝºS*^NSBjÈºbFlw_t^íâ#Ë!Åùª5¡¡5ï{ªÈã¶"\©Æ ÃiÄÒ¾ßÊs~K;'FÁiÚÛ;Ù> ×›w"óð‚&½ÕÙu[Ò>zCç´yCÊ‹{pZaŒ ·ŠòþÜV¨Äë9Ïæ¶:îîîÂÅéIÛ<O(Éö8<:Ø~µuìîˆÔ`ÖÏQ9~ ƒñ¤Ép|¹¾ÑÚh!‰Z+5|±÷fAc¶uÉx¸ó¼Gé‚kt’!)”Î?¡HH ŠscÃgÚÿè¨o¾µwÁá]¾žûEÅ^_ìä.­˜oý®Éqaö¯Í¦3‘ýwVìö¤OÍcÁbo²æÍBÝdúý¶óH5c-´!Nã‘k/œ8¦ÃSdvÝÒÙã‚¹ô]‘ÙXb$ƒ0Ê:ŒW>
H8×µ¼Þî eÁZ×ZÚœ^ã6n,¤D‹µ„:óÐ0Fó<³=%ð
üd¸qœõ}x!Ws†³dRµŸ$ù ,×8„õ™gDZ:n‘$öhñ3ßÀ¸|ð2%÷‡÷é7ï¶hø
ê_8}ÏÏ1ú½ê@,µ´ÿZt‰JdØ[Vþºûõ)®Pò¹“z´Ü™ø/×=¥ùý–“ý^„¥(DPèŽ~ðÄ3
œÐ«(|WŒ´ õTƒ[Ñö¹ÏÖV‚ßdm“ø‡!œÝó¡¨jŸ	…¦t«l’&”§1ì¡Ç±q®Ìz—j¢r¼þ¸ ³X‰ìEâá…Çqd’ž?‚m×%<Ø nêŸ87íPšäÏVÊ8Ž›RŸ
atNhÒÍ#xtô3Ž¦XZCÕ&–`°¦eÓw„5§:æ¢µYØ>Õf¯¬üÃu!«£3Dàúœ‹á!7^èYäâü|DÇ/¡G’“Äá:†WbÊˆƒ¨j9ƒ—¯DKŽ"äÌ@@‹sPö‘–],Â×¨å»8¦Q>Mu½èè`Ü…x ±‘#SI‡ô`l©RP<Q n&ê~›ôGÒÉÀÈ	¿i’Žµí¿­´'÷Õ
C×”´dÍþð¬‰±±QB¥P%½ ãN›Ãº7ki>™ çzI¾Ý»šé¤×Û-ÎÖû‚ÓuM¸é<µJµT‰•IŠ#9(|‰JŒã/Ö¬„zpÆÎ]=™Ìtþ£!y,÷¼?Ø?€·=‚'¾Ìi/-¡ÍúÃ?þ©ºÃøƒþÛ>yødN[Ðý+´ýãŸÌ¸4´·§XcR1—Šöö*é(GfÀ…úó‘tºzŽ'üÕN¡V«yíÛµµõÊ¯ÒøõFõ×ÜZ­–d¤¹1,±õgÂ’&üò°|Æ˜9\„Œ·>–æU…Ô·I¢K\p"NfÞêáXêŒØ‚¦Zà 2Óø<1¨øSó­ƒJQù!?ü¢ØÃšø¨Øõ(JºÅ>ÆÖ(orýëÊv=§¡´Ãó)µµfI¿-V©uÑ^©[ÃéÛÞ„©‚Ç—¬gLP8álž²tÍ_“À€	Hÿªâ³¦™„œG¾mÕÂäTÌ\;{ÙXÃ&÷ÊTq±Íë·;2˜(KÕ(ÊïgúÚ¸Ea\I^¶Ö|¿«V|G;íG%ÂÁe¿¸‹:%Í®W
³÷ô(²N	ø³D0• ©C¥AËô†%é)Vµ²Ôüömá£Mº~›æzo:—wÓ\ÍÍÿ¸j.„æËÝ÷øD~?8P y: &Éó.¶úý÷U›­
SB1^\[Î±#·´pðà) BLVÍluFmäV„Þ¨0Æ€êãI~ÕR[:]‡Åj)­"Õi“Víå®àƒÿ‹u“–E'ñIËnè1Òx-[Ü1¡¯H­©k²}¢k,ýùÏ^õ¦ùö
Ií–Ôv®µ0×ž Š):Îäé;]™ás§ÿBS‹\|³ÉpØÕö‰OÙ3)7·ÚõûñèfS£Ïÿ½ƒeA×¡T¾ÁÑ¸htÀáÓiØE'dÉºñ$2<÷e+˜™„$„Ñ¨EAfª{ÞÝ24FúÀ•Ï»U5g¤’È­ÊRw3i‡×Õ^â¦VWìéÔK½éŒËC0Th åÌkmý¦í1y’><³Óü¶FË9zDÙ¼Ð¡ç÷Ð¶Ww*j
n'bÕÝŠ*ƒÛ8†¬OP‘¿<>Å"“l¥I–Ž"¥ÜUa8Úf»-1ëÄ@´l\ZäËããCåÿ,ÞvèUw(ìJË?wr+ï¶Ê¢ÇÏg“2/wIðût¨E6›LÇÜœA…GÏ¹ŒH"ÂRGŠ}/æÇ4AŠP+Û[™j–?+ýYõ£MO#Ì
ÏÏ§éììÜƒOàóvªJTg†óPZ-Ô–%!û ½UÛ±
öÁ×Á®=%LhW>Ä×ê#c©æºSçQÉ^}7ãV[§ïfì‡u—Ç{jøÍðdþ·ó—–·À¡ÕêlÒÆ¤‹6P;ken8,Ö¶¸=itïû¡kžþëöJ¼@3­ ärŠKÚþ` i>T÷¿i>ÎÔ7Íõüïúõþ7ÃÚUöøÚpìkõÖ[Nmeõ—4NNN¯T[ÈíµCv¯=.y]'õÛ—$y©¶ì/QŠ/FXãœïXýÈ`J[— ÒRÝÝ’W-"¡4·Èâ¥Í¦h5-ÝnCú°;kÅ÷·ï³H_ÅkLcHÕV¯¡WÁUû‹åQZ6‡ýóªš„'(ÄÕ§)~wU,Y¦a4tzÖJñu‘¬•EÓ‹hÚ¢;³”ø ¸ÇºŸôÄ3ÜŸMî?¥$ã-‡O†±_–œ¤«úâ…%Y3…“ÁOMtbÉÔ—£ìîwý n¯0ß8À¯´&Þ?ïÖ¸êÔc2ÅàPdIcÅÎ£õÇ‚{+ãÌq<Ý£ûä_%\ý'iJzë>ëªˆ‚°æw©ÕŒŒÔdw›ßÝt8ßÞY€f"ò=ÕòÚÍÄ]¼ƒ;\ý¯ün<Þ¬yN'O>pû¶£_8Íojo-Z
Ö×
ú…¸{rbŠ9W©$š²áÙ4âlŒ;¦E»Qr–Ÿ3…Y_»äNñal6¥ž°ðªüˆúèIÙ9Iõ~„= Xø s) OÃe•Ð\ñÈ3»qzy$èk®£™OgQA7Bïûl&$e^ùPà¨{d’`Bi;ºãGEïN÷U­Óü_aóïkÍ?ÕàCÌ´À‚=vCk‰r–v¢Ô<À#¡¹Óè¿g1×bñK4 ¬îeø6@äLH[[É‰üúùÿ,°ø¥Ü(õó‚'2ŸHœ¡yW”ÅIÖý‚†ƒóhTa:ðÜ ÔDºÕÐ¾„á þ*”0ü¤]KBÁª ºû¯?=i¯<¼R[¯zÇ{QLeOèç`ÿyÙÜYlGÿóŠŽºÐ¦‹>ØQ~w](­¡¢~^ÑÅS..ÞçwØÏ„f–h>¯è£ËJ·¥?¯èâæ¼¸]œÏ«zéÙ…‰ôçó'ÒQéÅ‰ôçMRÒªûzÐx¦–˜Ü=9·¸Èù‚r"‚íæ¾dÊBß“e^»ªúÎÙ*TáçYÙPì6g[D¹yÉ’ïu:êVÍQ´ã»]z½ÝÊ.#{%AÓ¹dQfŸFÒüIYPl}ðÇ#ÎzC²´h‡ƒAÄ/b íôíŠs/Ú’4èŽO¢×åÀìö‡¹Â–ZuÅ´za˜ÔÝðzÅ:ã`‘Ú<ƒY~1L3ÈD•a‡áºÃ73wzêÏ³¯Sd kj¬ˆ$°!G«Yi4æÈò£Eìçe–ìs^&3.4ë	(š®ü1.äÔª¥`Ó€Ê=–ð +#,ëaY©F6%GR§GÎE”Çr?Ññ‡åWRîš\±¾ Çî0ŽS‘cª6(±Ÿ!ÎîXQt£¢IA¤ö$
ýøÓÙÝé˜ŠíÔ‡ªHÃ’¤t¶ÚzP¶z¿ÿ÷±Vo= RÒªîbSµç³zÇYù¸Ê#Õa¨úJûíFûþœ‘>Èo›M²÷øE”Ä<xòh-b®ì½ø³ò6X4ãOÍLQý²¸×sS‡ÀõÜ£f1	§YÔö¢UÒ±/ÒS¡‚ï–¢\Õ¾´ê©­à%¹û/ð…
§SØN4íän¥l¢Æjç¾$°^{ÊoÂ=ÕÉƒÚÓ/µç),´eÍ5Bƒ0/l]‚×Ù`¿müL€HæŒ9YÛÄŽÃ)¬ØùxC$t\µ×kIxµ˜l¼.ÈA5°LœSÙ8d}øãåÛðåñVSXîÍÖSèt7+Ú‚»™&‡@GŸ­øff’^R»£(aæ¬ÑùÜ±8üTµ¯{+vxÙcÕÞþ¹@ã“TÃ¼ÞPã(L2¶µô¥ÅŒÚ§A-L9jy¸Íã,ÅÇ‘ÐŒ°@’ZFƒYßëlI¬§œˆ³z§dÜ=â­0ÊC´2|ž
Y6
hæFú!¹6—Ÿt+Ì‡šW+Ójc„†·XY4=ÚFm¬D²¥ÂœØÙH»V^À=Î¢ ’Dž$<ïi
P^…ƒ1ðËÏ-üôBdm¦!×:‹Ñ€¼áê–1ûœ5ciH¬Ñ;“pÖ$MšNjñ"^†ÓœÚbÜ3Á³Ã5dyŒE±G#•†Îçraäˆçˆ(–Ž?sæ-ƒ® 	·±‘sƒ‘¨zÐ4TÙSÑóá¨<ÏgÍõª ƒwùÖ×>õ•çWÅ
ÕÁäøøG¬V,&z®âÿŒß´5ð¥ÈÄ<½ú3ZC[
2˜žT
_h[•_ÿ -ú-?0Æ''R¼ÌéOï©/ø ™·&3²óÞåÛ9^òú*¾’f­E@Ì¥x–Yªù²’GzüÑÇYVß­¬¥ý/X\Ë–i]™WCøw|åk¾ãi–;è•"¸Œ3Œpø8×ï!	v¡-?*äe8U":¯»ÛOóóáŸkçÇkU®ðzO&¦æøŒmœÆ?-òHfOãhQÅ«•‚åÚðDy¡æÇ@Ýù¨õó<T¿Â¢’[?D=ÓèC5.Šï<ádÆÌ‡³ë'lD£Ž1ÝøfuYtu¢kw=ÅmK»˜c¹Á²	 ó—]UNä–Ë^2„]¶yHRAÆòHª[1¤MgË±\ûU{Ýüð$Ç@}í˜hm8žó:A|mß‹•NÝtGXŽ«®…¨sz—Ù¾÷iúbëDÃƒë¶•UH]t7‹ÓLÞÃ¥–éu¢n„9~Ñ«›œU[¢²Ì
ôÕ4àÒ•êFYÊ¯žfé0G£Æ;‰mt+éa<}ÞÞGÀÒ³¡*6T~U¢¸¼pMU$	ÉY]ñõ=P±BÒü§Ú–>¸fnnUK^´´”Ëbœ’ žêÂë’ejÉÅ9§CÑ÷ºÂ_e¢ ']è(Êþ’¿zE­çy¡Ñ[b…wèDqŸþÊ>v_ñÞÜâ¬Cçñ9ÿA0Ú»Lsm’7É›÷þÜ-‘sÞ{‘U„_­«Hš×ºÜ² áŠÜ«ò¸&™¤è¬söÓ;QŒ¨•zz$bßJ<'	TÐb…Êåî›ŠØ¹Íc¸ ñ½{µ•Ò~Ú#£”“x$#?`ƒ3mçAyào¾i< m^W~)+Zp§ X9ÓO…P1Ý¦ÕëŸªÛðçÀºš£9ûxežó£zšŸŒU…Ü¯j$Ñßþ«cÈ"ÏÝ£1
[ûÃV€.Ÿu1"¼HÞGI|¿à¼¹4Ç¯uÚþ^îø´a£…ñn}áá(îð¬E*(svKŽ¨Ái°‚È/|:üÈ­º(r ¶ZõñfÓ¼øéå²cdÂ×Ÿ4¶v¹*_Xð‰âvPÄv­Î,÷ºÕ\¼âUew;(€T®ÏS·Øë :--ð6ÃÚáäñÒ˜©®H@‡› ¸—©Ó(JlÕ|¾Òú4(Ö«ö_±šûó†‚±Ø¤õÉ#*·ƒ˜Çô˜U"°5}í¾òùŸßáÛçÊ}¨^ë‡ÎÐÅÚS”nW=ƒo—I°>ý¢¼Í©eÔáà?EvÒ;>ú„´)oA:ªnF¶çå>Õ«ç»vdçN’{¶¤ñ†m,	eK:<t:è¼¹%]9]¸ÆÙ’Me?mI7I1sÂr?Æ¼ìXˆÀ.à²c•D~šA¬#üX²Nü¼t5—¼\5Š}1Ø4ïÝÖ[$”b«nV½Ðud±@sy÷ÏÕiœèŠé ±Ýrõv,ìNé%¼–¦U6+Jƒ"ßp2°üx¥dRj%®K›ñr|b‹g¾“Y½‡±ßé§U˜ƒ>¤x³Ã…:Aü¥@r«G,:ïRîaÕy{Î…ÏÂíZª`Å&Ï êK]K°`r,N¢ïIÃq"ÇªUxüŠ:}FÅˆ³BŒš_0¢ ~˜-Q¡ù•Uí„·ÖpñWT"S­îŽ…4²ø7ÒåÒg²Ò§@]ÝÏüýóïFõùØ¡k§+õ¶²”ÿdè<¼¨*¸]>üÏEêïÚ¦zp°;®ZNøSy.¿}BÕ¯:£_.¥h9s+q&ï¦“É»éeònÚðWü½ÈÉð)O‘ZÊ`í,)Ç¤&œ¾„ï@Ek¯i|¼ñí,/:Ù\ïäbVcûñµm°•çÙýe»•Ìô²‡ñ{)’Y8’×lí[0/:»èpµò|QKzÆ‰˜óÝ”û©¯‹\EŽ«M¥¢r¶æN+¼Ç±~ò´(êÚï¢È¾++5¡*Ý¶sÙô¬¶yæC¦9qù-Ñ[<5íºä&WUÓ˜×†X*3Ÿ‡žÞ¾¨aÁÚ=ËS Yv4Ã
ýxn2eä»QæÛÆ£5¯ƒünØ¿Í«®}r|åsæÇg_æõ·©g·oÙÓ*àÜÂØâ»Š-ägŒ—¯£4½_¥©\UŽü3§ªUTïbpÊã¬,uýÉ`ñSDK¢ê³Àò=òeiàæn10ÇY867´.P¨Æm”½R8Ç2_´y!h³âØñ[úÂÙÕ¦gƒÚÎ¦N¹Šs·kÕk¹‹µ–+pÝõZE7½ñz50‡ŠAóCBÌÿ<÷¾}eÈqé³w@êõO#ŠÜ±z%›8œ¨¯âãCÎH_rÛ±ÕÐ.¥ñ9‹)ŒµlMÅæ6zk!4)@b>4åÅÏÊç¹”*§¸ÌVXÒr»9.uñ'KÛ¿Çeµh?zñVó1@ðcªÄ¢r…¹a­ü}^}‰ÞlÓóîE±oùp%cµ3”Ý³n,w†RÎ?Yt0ó³™*ÏÇÏDÁÈÊ…¸ÅS7w	7Ãð¹Íý­cƒï\x~ãe,—À*SÙ‰–$4v¯Éª¾¦c`°Î9$l˜)}þûjµI*•Ô&y’·øo™ÌÏÓkXG±Ùw_ü‘ôAÚoé7¦¿ÿÍïe›÷¿7¾Ukëë?þzü¥†?ÿÃßÿÆóßÝÙêî÷º_l€Ç“GæœÿúÚ£Çëç¿ñøÉ“¯ï¿ÿ?ªâç‡ýWê‡î~÷¨³«_=ôP‚"AUsøy-™¼jãOê/³$RpØ Šo¥“«i|vž«Õ­:}¨^L£HõÒa~‰ñ²dþ"wn¨b¿¥¾“º­ÃlØJ§gíïÕ½ˆ¦Wè35Áø<çgŒû0:	;|Ó)>Åh{
ã!¯`ä#gšCÏ¿<® ågHš
Úsâ19ÖL‚V8¥—Ñ ÌÛ.ýN£p¶:q† Fiè#u8;…Ùô[çä¤Á.Š´âQD¡±üð‡ ÓÀÀ­PØ¾z'Ê±¦—ª[zé•É{åXÊ«Üw‚Õ{0U€;SXò Êâ3LVÀFÑ^†Wü.L*ídçz$ÎÇ&9W Ôó+_òi˜å _ºã8É£dÀçt6§!ügJ3bš“$†ÓþC,úw6ÇÍfž:ÞSzÑž¦á,28HÌ‘HS\ú~Å|êÉƒ?Á‚=§«=5Šk	'“šm) ö&Wr>L~ŒH®%LDÐŸ^Ñ
ÃY~žÒLg˜7H#]qüT@Ð’ýg°…4%Lxƒ™ã—F‚„ïp9³ž~…û›FÃhJ50ø‡aÞ —ô&Ów©¾z·>Ö(ôä¸†¥aLé¯…œ›È°´>µ*Ç==cô‡Æ(Âê2ÎÎë3fD˜Ò«Åèt@vgæÒ1¸±AîtÅ6›é¡;ž6¬­Ï«ÃA´w´No®» Ã½ÃT<=î€’ö	gð=¾Ÿ)vÍ1•’ÎÈ^F§‘DÃÉú9c†xH@€¿Â3ÂMð˜Ü×fïä+ºd1Dü‚·j]€“Nñà±!JÐ¦yHI·X1‹OãQœãa˜+OÉ…Rƒ¡‡ˆ€ôƒxˆ(¹Y–…Ÿá¦]DÀ+B{$È¼ÀrïÃñdã.ZA6ëŸÛ ;çDÇ3|¯ B·[#ÙìËL¡"‰
£¼(Ã€IžñŽ0ðPÖ••k 7* 8ætÐ¥kèÖƒz-ƒ•0NÐÅ,*;t!ÌD¾EÏîà¨!ük4!8mcöo:AÔ èWÈˆ(îV¡§ðæ—€y4É6ƒÕõ: Ð½œxó^Žw¸ˆÙ«u€9Æ/$Lrùƒ³øBãÝ(:â@\7#/l·áž ×&ê(ˆbN£îô®î³a‚IÞ}½¢¿´MØbèäèDâè“˜FÌžxN‘—\ÉSJqæS—O|
èÇäŸ&Ì¤œ±Nª¸	¼iýXgÐiH1}G±vÔ(ið)ò²b¢Ï Œñ(€íHî^˜lä÷J¢t–Á¶3ðJÝ‘Äð…™àÖ£ÇPá›~FjÁûRaŸjáRb•Äû1%Ay…Ëâá\²pÂ‚æØ]‰CàL¡tYJTyz†•!ŠO˜‰aæ3\N´Ü0*Â aŒ Ðç˜$'áð‰
ÊÌ´LeW€Ê”ìÀÈpoKNñJ¤ýþlJ>?šä0f:˜õå‰-ž …3`ÇsèÕØ!!‘Bd,ÿ’ñŠ¬µÏ„ê$GK”OZ/#fwö0 º„ QŠÈ|z$RÌ\,E‚¯)\/½T˜aGvf(œbÆf6;E;”E–àXjâ)~? 'ˆV˜€%²*ì"Ö—•¦Ô=q¨áO× G`×ÞÀˆRäUš[1¹)vªè†Ç	®¯¡jÓ+M¶˜ù9¹ÞN 3ÒVF$óœà×H÷ð¥ŽˆJi;"Éßºp¸Mý\“2¬àî	†Vöã¢œ(Î4'\!DgæO3÷	iÒL(ü %öŒB]Í‹4æ]S`€H:åÆzA,ê„Xª7§ìÝ€¸‘¶ö±Éˆ@2WªæUK$–ð¼,9Â=ÓÔ(ÐóÁ-¢2ËxZG
ÐScÑ\‹ÑÉ…ïH„û æLú!¥OPîpè¸Ôbú!/‰S<ùºÐq÷h¯§:ûÛø.ñöÎñÎÁ~¯µ°ª¦üÂV;vxLÅS:_}‹š{4W
çŒVYc›Ko~×Åï0hüRè:‹Ô0‘¯[¤Ù4„´ 
Fã4CW PÂìYwêÚ]6ÊøfN²]“¬/:`§œRœzõJu±l¹4aÍp0€#Ï8œ»,·­jÒ!Êjt$5+ÔÔ`eWˆ.ƒõ‚®&mÒ³d„×&5JDsæhe¨á„®þA¥Jä°O€…Ô0ÌÎ¹2L$éVº°ÂAC L…d™ ‹z\€Øg©D(ý”Š=`Z\œq%|®Vdb5YS€òA¬õ*’é·šöÔhb·££jýÆ‚6øYM@Å²`¸]‰™SÛžFDŽ’¯ñv‡gQ„ó€Ð„´æÄÂœk¯¤3¸æô.‰aÝR#z =‹5;ÀŸ#ö” î'C<ªô$Gô©O-ìÁe 2ýy›.À6¼ó&’Êqø-
âñW±¡3;”}"" çÍ€:xtd•6ÃÉ6•KT@ÁÄ°ÁD,¼ºí, âQ*1UÐ  (Æ.ä§¬~À•¹ŒF#s £‹¨ˆîxOñÎ‹”`¶@´!JØeFCˆü¢ÖÐ) D%(k) …=’ WÈ5Ÿ¸¦ñE%Ã¡a<ÀPs\LC¿û‹ÉGI6äj ¡Ó¦6®óÇ	g;ÏEÄÐ ¡Eºº.Î„ùÕ.Éëû)ŠY-ˆ¤Æ<VwåðBž1‰5G…°â±k”!ÐÀ5Vn”"Ô/ÌÌl®0s[tKh~£g9«c¥ÅB½PÒUAXÁwÒ!™$[´é@ØŒˆ%C•Æ q-aÖl…WJ*°#Œäƒ1ÆCKÀw†Ëës˜`•LÎ%mk …Äià¤'D–-¯	¸±³+»q8´ƒ0‰¡‘°ØtÆó÷§ðíÆ ÄXo)q5m¡ê©y~ÍÑGk¢*»äˆÅ4
aE,ûèÒy²oñµt/+k92¥ƒÓ_"¢à8¼½[({H%=hèÞŠªát v4Ðlw|™ Çô¨§1Êa,ìâ:ÇDÉ
[ÏÃœ7i *[:¸BëECƒ’ê3 ·7eN
‰®}6
µmŒ`ô7ÏÐ’ðò´Þ¢®XÇ)V¬°z;n[Ò4e{F=Ro ¡N§!µsG¡ÊVŒ;jØ‡ðÖÀðVj…¨jL:ÒeÞWÃ:[_©÷@!ƒº çt®ÿ.<c"¿þ@Ør•&Æ,n”%¤JV$€	¨yà4§;~ZWôpbXÖbÂ*"º]°(‰ ÊÒ¼xõÕÐLÄ¾*#/$
ÓVxRVb(Š
ókBD8 Å&¨VQ´Á+—Â¤ïs]Ø-„ËMQV#ÅŒ(<u
Vß–Ä'¬ØEgÌ ñ8žQÁóú
Ñ%$&Ì|ÎºŽ™7È„ÛÇ
Ðï³Ë%8}<Š¦Z-µÒí¹Ü"{mù¶Èm?SÛlC·¼gU˜Ðxä$öÇ$¤ FAÁ0æ(”ºC[,y†¼N»W"ÓuZŽæNF6ÙT›šìVá	ž@+'¤8ä¯HG¢òY¹Žþez‰ZkÃ”Ë@D×wN{?Š×•€ZT2ó4e!\¾€`‘ÜÚ¨¬qw*Úœ#tT'˜d²/,oe`;û×’WÛ*XZ«Î10¬ß$ŒžÆ…wQMûÈÑ|]å4ùK±ØØ¥4qñr±'i lLÀÆ^º«$s« KÃ ÝžÐ˜g*´6 /Ôµ‚‰Ù®hvŠÞ¸”c*Ùæt9Æ³D+±¤î2*Ñ¶p
"¦Ò²9Æ]ƒãE¥„³¯¾ Upe¿‹CFì×¦ÜiFµidß³p«z‰6VžÛ›.àé¯Å¿ªEºÇö Àh·;ÛhaQ L‡F!a5²z¡›ÏÈ‹7¨ )õ×ZˆCÛr›’!úPøÉŒR ìâ"e¥EËrŒWhŽí‚Š,E¹6Iêù×gBÐèAfòY2ŠÇ1ŽáÛ°5m)k}¢œ‚Òò;Ÿ
4NˆY®I
«ü}zåƒƒ¸ ”Ià‘ê,¦ŒÎ<#ºD,Œcq>ËE·ƒ÷;I/A9>‹xgvA9Ù§…’&!Þ‹pÄü9³ =½òuB:`ò€˜<&Ó8F4Vj½e9PmÑ—ÈÂµÑg]3°¾ÊG¡œ…öy»•éÈ,PBç”|’z5"´&OïLpŒÞ}:Œ¦Ìóð‚/mRá|Y4ŠÑ,c£ë"Š.bW"Ò< ŒÚÇ5d»zbÉ²ŽLÕ>GàÉhW†}²¢AEÃ´¢Gf¤[Ó˜å3áá@”B"]æä7Øˆ9ËŒÅ]dáÐÙ*»¦È¤ïA®ÐitŽ†¹ßôÛ  vØq)ºÈ´76:ï1_­à³Œý{ìÏ6Ûˆvã€9Ú%>1ªäçuO˜AOÂÕ-71v?{?žögc]2ß‹AA‰{‹£D``çhåTªGâ"œ	ñ^<ÈS´Á;Y_##o†²€\'ÿÐ¶Žh¿Ç+ö{°R~Äö‚§Üª¹EKF;0Žº+×q?õY) ÕƒYw`Ø>JLÚÄ‡Ñ?OÒQz†ÌtËÜ˜FŽQ®½ÎFÀÍ©J
>“Û!íQ!l}]³ 7;‡áÈÑ¸c@­åXÝ5µ` §ëúÓ¼SA„U*2ÄjÑ¨*&}²$z`_ÞCf#ø‚Uði%û‚/Ã˜
¢]iŸ%i€ü§1ðâ4Ì”žOù&’0¼®¨2à™ ‚Ø:íÇ„0B’+Ø#!±ñ”§AñŠ2+Çx„4Ü	ÑäÂ²ˆ‘iÅ¤ßTïªY¤²LŽ5g¤®¤DIGáÛqI6iðugŸê”±ní}¦ìÌ@³thA54éôµœ{ûZÇgm±AÍå@rº….½1áÏ÷3O¤aæh3†€ Å€—%ž«Ét’M@ág§,ù‡­Ý5H²sÄlzfTâÌ»ž”Ö'†Vî]ÁäÃEcA_hBñ'¹
Ð‚¢Å“ã³ˆþö©~7‹âB‚¾µNF¥Á‚üÂSÐ\ûÓŽ+cs{JË8£Ëê›>QmƒV©¶f­áæ 9º§¡X#EeØåwóz+î

¾8Ç'Ès•dNÖ†B<`cBh	]dÛÓ²HÆ¯]G{ë\KIPi£h3:wœÛ—7M'±½h£˜‹µšDDôÑ>ªÂXqsEâ¦¡Í\F¶Éº°NÂ+[ýÙ÷`WŽ‘±)M”O,O‚Æb×‘@Ø.0Ä
KZ‰7ðô“æ"o»d×JP\•:Á7ÃåÔ|¸­ÀŠ†ùV‹ÊÎ“|z7lôt¿@…HG¨Í¹85Ùh¿nc„´K,ˆßÔhÂŽ%Îñüa½)ö¢-Ú¡¬Èj8Ü‹4Ë¢LG„ÖGV€"Lr”À$ áÞÇ«7Ô‚qcÀ òLH×ÐÔƒVí²QÌ$Š’´Ñ†ÙY8Œ0îembâÂ·lR¤€*OqAÂ‚rõ÷u0–Z[u'Ã+ñÙ[#gª?¯À±vP	.£H,ÂâXDÏu°—6s)5¨ë×yhb,®5ßÕ"z5v5¤Qæ:^ž"lÄ¾ä1¯âL²!c™–°®ç&ïÒÌ…y6A»06R|Hçð¶Ã³ÁÐÈ
¾ÅøÃ×/WÕF;§è=¾ŠT_”Úv‘àäÅy‚ÑwXØ)Yõµ‡T›uXÜ£gù‰±Î7PaDe]ÓéhÆou…TJ¸îH-
8.æ$¨…ggˆÐè·5-ˆ¸–næx©-Ë—•Ú„Ê¢1YŽÊ‚x‚SZÿ¾„'§I¨Ë0i¿¾(½¬È ë)!•­êøÈKÿÓ;²6Í~Èa„Î•D:äJÖ÷ie=áÎ—§îƒ°"ìôÎ^êJ*Æ†21
,Ì€2#ðÏe„ŽCop§‰PDó*-b…ÉŠ"ãSYÆ
ÄÇa©[f¾‚1P{€Û¬F½ó«Œd`	ó¢AV­}ÚiQ£õÉ{ãI˜ÄÚ®ÄT¢ÚÔ¿gi%TƒÙ”ígzt9%rô á,Ùhm8 @…ò,kÿ‡î9d¢6Eý=a)°¡ˆê³´—ciPÒb0þê*
§lºuš0çtìOZ˜œ0·šrˆ5CÆ2Ù°ÄF³'Ð½ƒ>Q25Ö-’†)ñdR@.‚¦Ùm™Ã»‡c0@V$rÔ\ãc£x#ð›ãCC{HIr.>N9@¬Fpõ²4‘€v€ë9Q—r}"ÏXë—‹	«0$Ù†µŠz°ûQäu„{ 	;’TT+Á	>;ÔÕ×.Ý£“ˆçÀÊø(’bµª\ +Ã…#eåÊâL•ØPœöûaF’«£èR§—è¦ý˜#,QGÅQ´]Ùa¯^>óPsyŒÉ;á§Z@|rjå¢9ÿT´1ºÎ|F~öÌž°t„N¥ÕbÌ>ŸGEK† µR;§¾ðÀE£bÏ=Ù75¡Ëô!ONÀe-fS¶260£2r’(^ÊÀMð® ;`â^r<ÓJDÃÐCú¤4+ánc.*ñÅãÈ?¾Þ¦ôž ý*[†˜½C°[kÎWs#â!Ä.s@¹Ë·ÃY!G)f­‹õ­uã†ßçF pv™…4*‡ZSbvÎ…n_ŒrÕ’Œd“çiÆys»7änPÕi1n²´Ñ„1Y-ÔqÔÛ0,Ãú­3Ädö6gþËïrk¢¹·fFvÁIM›yÚÄ9üË„üiÓ8¸ò8a{;#
*aØUxÂ}ß !êÙ¡óiÄÔvHCŽI¼Õ:FÂÞ1ßˆ®í‰¨¬!w4rŒÎQO@'…köˆÅƒ6ö’ê+†—Ãs¾4÷Ô8²¾7¥D
0$4Æ£†<´FKq84Åf³1+ÔD+:&Ò)È1W”vÇBŠ4jfÜ-7`#m\¾ª/ÇÀq˜FtžÂ÷ w´ó*³P{ŽË›˜óh ©@Åê!Û¢
C`$†¢’`Ž’{G›ôKØŸ·ÙF0Hg§ùpÆïèeÖë G“Ž.ÎÃð"¥°E’<Â3mãFPéìËž(VË	±Bµ§¡j ¼¸ê ¿š¬˜r —	#Â×Ga–9)‚YBûg&·¡0¹âMÐ	)½ÂÜš˜£WÉG½G#~¦_
¡¿øNQš	GÙÑÂ0ÂÈˆ‘•`/¬\–3œtÀÊÈÔ3”¦Tüð LÀË%44Éø	Ì'áŠä iqŒŒšl6‹$€QCHï…"áw8n‡ä¢Tô»r¯˜!8†m¥ƒ¬¸ÑèhH˜®åý.ºbð2á‹íØšàœT'2"p¼PT‘¶U¶nèx<oH‚°ÔŸsB³ù]ä-­BA6ÃPÅ¨ÈfÄÙ˜ÇÉ‰<e(‚¯5(ã'¢h*‰	©)‡.Jª“6ñ¾84‡\›§©ù¾?ÈTŒ‡$º3ôœhI‰Tº¦XMôEãÃéØ­çFå%›–Õ@º66È‘ö9st3ãÄdvê©œ›(#C×:j“~HðNÃZ$²ÚáqF´“øªI”ÏâüÊÈ¥kÐª²ZiÞôW˜s„¿@þ»GA%ã}ûömT2%žF®Þ°®¯æÝ1LÁŸ‰ÉµhKÙt*GÉŒÏ:IÙìÈXÖ’’ÁØ)„ÂÞ•{·
8)I×,y{§À=næSÂ;yÇÑÁ^Ý„-¹ëwô¨y[/Gè…Aa}ËÜá´J²#…£kï!4?ÏÁ±âû¡;k¯ÃÔÙŠœ’Á«† RPÁæxÙ È(ŒZ'q‘Yäò<JJN($TÑhh)´;s€´,â`(âVDî­ë˜©žÖr§#JÄ£ÍÍ¤Šåp¦}Œn
3¶Quašf™;„h,¸Læž³–†É çú=+/g&QgcaYî.ó£‚âQ…˜áùÃA1pNtWš]kŽ@¤u® ©g€nF81KÐ-BŽ÷©¼ecSïZß¶°B±öËGÚ Zs>µL›Fnèâ¸ÄK—Ì›:íqVâq8£‚“ )Þ0‰8égi¶g]n­ z<s((ñ5é°	ö‰iw‰‘@8f„“Ülº1ˆÍœLã«»†,/Ãä‚³Ã‰m}¥œ'Œj#NV®=`Ë·ŽRwchßVÒ=§¹¾$Ê[R 	:ª7ÎØì®ª€‚®Tr†"	§/¥ðžc¤·]½ƒ¹1l¬ª
Ám„R7€SQy‰†Õ‡,úY˜KŠ’92ø SŸÁ[bu–ð´ÕÌÆíŠ¿(½”e@?Tâ¤fë—zƒ…HïVÝ:ÈÄÌY>Ò	!Šñ‹]„4&ß'åÇÝ‘ûP—z {oeÜ‡Mâ¶r<FÊDÑ¡oº ÎÇ.ú¸¨Œ‚Ã8|Qª¼@sŠ”% ‚³eFvMçôàÛqI»¾PøaJô•u~lK@i“:üý[èó¢4™XÆ&¥Ã™µ¡¦ä©õÇDL×Ÿ×ðeLí„82é¦¤¶L/û²)<Žù™]n&ì…]£.S‘f×ê€?œjÛbÉÛJƒˆÇUûdôìžCÉ#de;Îíêûu¼þ&æ0Åè^†“<‹£ÜZœ•åÛŒÛ95*tq³[´Blu„.)m/s¬‡ÆÃ	Mù%»•AG[Î¤³J<xmÃÀÅàKoô»÷©Ö…{FG×¶Eu#10ÑÙ‚ÈVˆª›‚2ƒÛã8FQ?È okP^EÃ6gåR$A‚Ofçº˜†ïqâ…ÕÙ8Lô‘‰eVÿÊñ@êœyÛU«:Ë¶pŒySç[Èµ¶Èú@uÆÂ¶i9ŽÔ^F‡ÖÉ•ÛN8'‡UŽk’A@J)‚]ÌÅøG% Lv S¹B[1Ú„x6š'@¾CºVÓ|`BAI¼Á½ËMDûö™È[k`×ÌÕ Pì’(=š»ÇjÏZO(¢*,ÉaÐj^Ì[ÈÊ¢8CU±K°õƒƒt e¡lRªFgÖ˜•3 I€ÚŸQæÔ/&Úýþ_ÅX,Rú;wœòn>­S;Ï÷ÌcªU£ÞF1ìÙ.Þ…ìÌ[¿k£ å²˜[ZôÝ€öpY(”Lž	`s“™2  £B	qý|!¤;©Ž‚NèYìF%g‡'(¿S
ÈrîOZ¼Q-PIÈº8†mÊ­ð¤e®‘ñOu·0s”€§Û E]¿†lWìÀ4h½l‘‚'lpã>(ÍdŒØZP…““„nZ2Ã„iƒIå0@*ª…¢kŽ2;y#¬ä›ÙSy
o$VqaUâåü,«\6yU´tj€sãÝè"%n
0S¡"¶° a+„ï&çÙZgÓÇK'(Œ„wzÂ…J’ú])"æ"	OS3’ý®Ž©º( *²‘}àz`„Pv(‹e˜j ¬Œ*åH/«*C.øcè'öØ\`ÄÚË4ll•ÈàCÐ¼ézãŠÏ’ÛZpPÍ qäÊ0dWÆ†œ0üdMHªær”aPttÛ” î%!ÝˆDgO¥-é´“8Êœ½Ë÷ÒàYNàgZóxÙz~†¹	­¡çbŒÎ§eù´nõ¸ ¸\›tÐŸ‰ƒÑŽjàûÐ…o °œ‰QœyQlÜ³ô¿-Ý1ßcÌzöV"ÄÌ%Cã¯Tä@iŠô2
¾a& ânÊ·¹¥ùŠiLc‘EÎÌ=Ð‹Ü=jNÚ›úoŸH/MM…|1Ã+Ðª£Ãe½èe”ffj‘õo"ï·ÀàGÚã£¼äŒ¶Bº„Žt#\»ÌG
”p¸Š^(LÊòó"’löc'éÝ9”ÛTK)‡’5ŸDfñB„ÚÅkÒ™Kà³,Yo""o°C›B%'Åò–z¥‡Ü d¤Ô|#ýðã*Â1ç…4ÌH2±Ysä‚;ÎÝ×-9[¯âüJrhŒ35v8õ\J0mH@ ÉÂ°,J÷žËI¸/JÊÍù¤‰ÓÛé%`4–/DÓ/Ô‰ŠSÊ3'×Ê÷ªxÜUÓ©ÌpËú¥Q&’ˆÛ0Ò[œåT¸ÐÍ™ÍØAò—Xÿ.HuÒ‰E6í‰ó2c~YÏõ…e12¤[c¬“¨ZñPy²þŸKü®GÈøœxNÕä‚WnI.Á¼²~È÷±T'GÝ‚Ê¨ÛP„å1ÆÑôŒ1Ç­÷EômÞu¤1Æ1ë¨­D•w'aîì$Ê¹Èeàî‰°sÄ.ùàHÎ50n¯¨¥ç:ß€}-ìl¿ºO”EÉfrr‚DzÀ
ÖÕ#Kœ·LñL#qø<šáº$K±˜W1×QçnÁ ëœ5¡8¿§ þ¼P˜XRþ«†C¹*‰Í¢o#å©P¡2íy“4Cãû,¤ä#Ë§¼÷y‚´WB”ÂÀßÞX¬®;M¯Â‘xÊR'„Ž³·ìZŠë˜W[éÊÝ1=ã£Y!—ÜÓÀ&ÇR“Ó ùü)"•þ&§¦”ÎÐT‚î³3­ÄŽ .-ÁX/Hƒ¹ŽšiØÈF*ÇŽ¤þñ˜¢›Äêå…Ãylà“d•¬¯·Ô¡.k©KÎ%luL§5xSñN‹.åT¨ñ&í¦óªÅÚ
œ”ÆÆŒ'û6ËlmB›¡Cd™pÝU›ò{&‡Äki‹á¸`/Ò7ïã O4pªq8þTgà†Zq}Ó°/Bœ2Rõõ§Í)°x¹'„¹Å]“”C¦‡Eä s!çH‹[¬”F€Vµgš·:wIäx¢`AIßýª”ÞŠ¹ùF®á•6d‹¹4ä ÓQÍ|³Ú¼*uF‘ï:MwŒÆ&»Œš˜€WÏT@®†÷ìrz§]µ#„…d×0å°êát4ÀªZ†ê4¹fŽ§r;¤ßGÂ98ˆÂEÀ%-(.ÏR.:G»Ó-ç+nË¾pUŠ"	Ï.Ÿ‡lÈÒÙŸéÍD„ŠÅjvEÖ§š¿I&É•6Ð4ë»ßãœío’_†Á©¨/V¥R‘{"ÒnÉqºjÊÎ%zä’,,UŠužï"JBNä¤Çfb÷çníÉ:—µ­Ñ9×L!wÿ)¸¥S Sj®s¬úœÝ–ö¥QÃMf§q«¢œ
â+–QUSVàˆeð¤´TÎR›œê
ºH„FL.€ÀÔJ§2Á7©ó¢KS’”ŽmÓàLRHy0Lš¢°%…“ÄÖÄäÆ¡ŠÆQ'ôU'ˆÍÙ+ìmŽXY&·ªè<cÅ#ÂZ¡¬£P@Š€è4J€ Ûj!L	wÇ
c*—­>434\ŠÜ€"•ÃL}l]z:¹j“Ñˆl* V<ükYtáBc™OŠ)Î£¸º+2m( –’*(NÈrP2o³Ì3eùKÛ\xaœ8X•[ø=™û…Õõˆ1Ø‡pK¡iqŠ2€29wbwAI–ÑaG‘Â[×@7`69 ‹ÅfØfyeR‘¹Žü :àcrÐLÛœj ®‚LºFÎ´®-Dn”TgJ_'ÿa"±ÀŽ2Q^«
èÍ”ÒÑ¾fmšaÆ¡{ÕÕþ\M©¤M'XBoðòã¬`ÂfT“ç²Ù+þ,ø‘!œ<Õ¦´¬"``ªÖ™ÆÄRÒéUM^Ä,à±ŸŽ‹ýÁîœè!Žo˜Š/YQ}aÙ:³E½l½–¬¢SO2Ò‹AòÃQçk!-_é*2•XrHxµj02&‹žÆ	èTŠ/0_Ó)JDjÓÉN¦ààÚbƒ“ðjLqN©u(È^U
)M£í«R$ðŠó…¬jô¹óÇfÙ¬¡KšRm¯LI´®t;´áµAiI.ú	>U'-S?Ï#i&ˆV‚wV9~.¦Ò¾c^âRÿøq™:!`”âÈ!žÉ jjsEÍû,zè4íLÓDòÎV\`q¤àÚ"²¸¦ƒ ¨%kI,õarí¹a­îT{áNßLÓñEç±.-ë˜ýL¦“›ÎŒOÔi'T‡d€ÄÈSMË :3WW\S€¶C—ÝÈIcvw=z£RØj}£…Å­zæ#8ï1»O/sÒ±–ß
õþØD1:ejUë‡TÎnF•aØáÈv±u%Qlø0ˆû&,_OQår»Òõí Ènq^cšß·eÅO~¶AŸÅg©”7Ð©eY<žòP¿Ã‘z¥Ê\žI@—HÑ™bh© ­ÛnÂ^Jvy×ü#Ä7Ì¨øIÑT¤i"‚–xÖ'®³ëøí*”uA£Ç*Z#È¤`‰Ç¹³ÐÌØaùA!S²Tä¹:¶°Ñ3?2’yèÂƒ’QÁÉÑ0œâ%æèL£æ'¹ÕŒÖ¶0¢ÛJ™ø.E5ÈtÑóŸhÊb‰”äP$,‘QòOhnä½<!ñ©•Ïj,\¾’t2–Ñ[—ÃÖzu‹/pÜ˜êdrÅ»Aú^

Ô1)t%"è¸Zk]÷o°»F`o)¨M9lÏ)æo´.£bq³Z‹ÄsvãË£–:Šà„aÝ¯#÷í¥‚yÁ4ï-BŽl•dSMØB£0¦·=ïÅBºgèÎÁ…Ã¿Tà`ìƒûÃm]®+$Mâil²y%jÑX½H¹ÁUr!v`FÉˆÞÐáçLh
ó¨ËÄnÇÏ¤Ñ`Ã•QIx@lšÁÖñ\t‹d†…MäW`‚Ë%TKƒ&„˜;ø]XXÕÄ¬‹IÖêiÞu¤øö–Ò28’šlwŽgÎ“;¢pë€*½ÂÀ¬Ÿƒ(®@c‚5”zxX¼)Æ™á„Ò®Q-êÍG!>Ö?Oµ—BBö'³¾ j}^kÖî®°t€€1ï¯ø…EøÕ¢	üdUpùï™-@}B÷u<?}?cŠöå;U-˜ÜÇF¯Ùƒ„F×=´Îï²‘]:P-n™M TÏÄfâFK¦S¸qÿNüP’z=A¡ .aÖ²@§.$07êmKp±Azñ’‰Ýã–	gTz#ÁáLâ^vºj§§öÔ›ÎÑQgÿøGõâà¿P‡G?uöêø€þîþçqwÿXvövŽ»ÛêùAçðpwg«ó|·«v;oðå¤ÿÜê«7/»ûê ‡³ÓëªÞq;ìì«7G;Ç;û?Ð€[‡?íüðò8xy°»Ý=¢ªÚ0;uT‡£ãn×ñzg»ë®IÕ:=XvM½Ù9~yðêØ,>8xƒü¨þº³¿ÝPÝ¨ûŸ‡GÝ^ cïìÁŠ»ðåÎþÖî«mXKC=‡öŽÕîìš4œMÚêÑq10þ^÷hë%üÙy¾³»ðÂgµ^ìïÃ»¯|ëÕnç(8|utxÐë¶ƒ€íôþª`ØÿxÕ1taŒ=|gçröÀ1ávÕ¯EÀ¾w·=   ºj»û¢»u¼óºÛÀ–0MïÕ^WàÝ;†AƒÎî®ÚïnÁz;G?ª^÷èõÎÁá¨{ØÙ9B(má(ûŒFOZ\n»:j™)Æ>bP÷5âÇ«ý]„ÄQ÷?^Á^K”%8~ç‡£.ÚÁ‰àÍ,OÏ †bÄhPøÂ"Æ€bjï`{ç‹ ÎÖÁþëî½À…
ÀÙ¢lçùæ9,d‡Ö+@(á¹mwö:?t{fàœ<²ÝP½ÃîÖþß>ì2¨ö{°W<Zø@Q8c‘“Ï1xp_#ÌŸ¹‹]µs—‘RíôƒíÎqGÑŠáßç]l}ÔÝ@Ñëlm½:‚û†-°¬¦÷
nàÎ>Ÿî—®øÎÑv /áí‹ÎÎî«£"âáÌ B’Ð9	nÑ«7<|µó¦Úz)Ç¦¼«ü£z	Gñ¼Í:Û¯wè:Ê<°È	ìŽF82ö}Ûâ·EðIƒ½R’ŠË¼Ñ31Øpä!²¿7E>8ÒÖ¾èÇ‚Ï(Åbœ¼Â•…%¾Y¨pNéR" H]²t†%\XÿgUF
/EgÇrLýQÊ™ ˜ØòžÞHÈ´iféóç©p2‹(£ÇñÈY{…ÍÄ‘Ál ©—d|@Øtgö€–ÂÏ=ZÜ¾XÖµâð’ÎyÎ„öç%¿ëÔ!q8×±-ÿYÞ>«²€Ìñ É»>¤\ÚW‰u8ƒ<9-ÙÇå9fÀ¹Sñ¿Ì²BniC<#YÎ5Œ0pïœ,ê&TübqøOg³8DÏm¢i”ß“ðâÕ/«ÿ’Öõ#i#ÖÀ êPŒV|Õ©SFò×1;d‡ÎÂ!nWlzuc¨8Û‚‚ˆœ0{~¯%ó^ÄHþk¦SÕÐ/JL#Ñò<(ÉÞºú©?5#ÓÔPY³ˆš¤¤Ô±}AWÏÎLmWzÊeSA®ïœÔ_×xsö?£t"útGCô „¦8‘È[ßKU"-e­nÕÕwXî{˜†HuúÞ÷<ï±¼×ªÃ6¼ãÞ4ï{‡çZ—çU{JÉaæé’ð3_†oh5¦dZ°qœ~´ê§›ÖËšM« vŸæíªst/è$ÒÆY²‡ãäª´¨jq9ˆÙžš¼Z¬ Aciã§%VœvU”¼ ¸ó/e¯^Äš Ž°H×.V“uÕ(ôG¸xm"›ýÈºùK]9§™…%«ƒ€ìù©ïÎó|²Ùn_^^¶Î’Y+žµu¸Gû{XPC÷0éÆ-m‚ED˜v’ý›Ÿ§š÷hç›¦	VÂ·BÂ	F®ÀÞ\F9qõP‰²¹Æ–†¦rú±•á1Í¹£ôŒ+mŠ²±0lNu¹Ø©[°×HÊêw2ï÷7¾‰%<äÒÌÓÎóÞÁî«ãîî®&ó”ÎTŽSåW€ ÿE/¾_ÞoÙáŠ÷Ù²¢åÑçaÃ¤w½i¾Í&)ÚXžºÓõï»à£eéüj‚æFr*ó
¡^­ÁôüÓ¯Õ»™Î~AØ9öN¥†$ˆÇ¶¥™zê`LG€•,´^ûT¸û¯vlõcyÆ4#[ƒªÀxqš¾¯™¸IY2Åšb¨%ÍÁ½N¯0¢AìÕöý¢_4­SLê·@8ø¹5òza$® ¦ÑÅÊx5ëÆ7eÝ±ÂŠyóã…ñ©û‡_vvž•d	?­Ú\n|y.i°ô’²åp¥1&Žts‹…‘pÏ‡+‡Mì»Ôú‹ÌÉ•pèrˆbÓý˜‘<ëu%Év\ö—ò:ñŽ0˜<Sd¯ÙœÇmgWQ.fHy3G×ö,¾G—:áRÂðén·‚ ÙÅ0°é<ëF	Eá Â[ƒ%u(ã£‡)Ch*brƒ(NÎ¯Ú—çWM sst6µÎóñNçwÿŒ?ƒ´ß>êv¶÷º­ñàÍ±¶¶öäÑ#…ÿ~ûä1ý»¶ÁÃÏ£ÇO¾Uë7ž¬o<z¸¾ñ­Z[¸öxãwjí­Çû™!K¥di´°4|Ï›Qæß’Ÿ{êàÕ6>üÇøØó E0$"ÚÊ­Ž_o7áûnrñþŸÿ¨¥<ÊI¦Pzá’„*óÚ¨ƒ‘¤šDÉEbûi Ãñ}§¡vbZ2 ãÙFÈ7ú U 5êŒlÁLT›:¾œÃ_ ÖµŸp{8ÉÁÎ¶·RÂ¦Ä„Á@è'ÎgÚuÊzÃ•®pLŠ6î}øÃÆÜAÍÓ“Ì“9mg@Kà}ÁnüÕbšf(ÞQt·¾§áOÑõN94))T	½šÂ¯0{`ÜÖ`ôàÌrKo¯¡Ž:[jôÃËÊPõ"¤ÎY>­¿-NL)P/¥Œ#ét#gÀ‡h¤y ¡æ~óËL‚1<HgXT+;ð@ÀÒÐ¯y'Ãøl&…¨äÁIV¬fIÿœÍ1Ö€i·ãº)°nèÓš%ã2ÐÇsjè‹ç¥4*°âã"µó÷¹z]‹ðtÈÍÁ‹NK`Wàësv‰‚J,ùTvãdö^½Þû?ÿ÷ÿ«Â5n§ýwìGa.â`”£0›œFøbÊaŒMùÜèÓDŸ¿ C»j÷òi”÷Ïi~WðÁü½Ô}-ƒ–ã œÒ½{  ä³Iá¸lÜˆGÇ Ï‚MFlt®Ë’YÐ)<MÇ‰|…ÇÚÂD˜Yù-‹ftí¥žÂ]Ÿ °h>/Xèý×áòƒ”à÷ï0Üæÿn«Ÿàß“þ ‹~VíÙÚz›Ÿm—'SÍó`cmýÛæúzsýáÉú£Í?n>þ£BßÀÑñ&¾"Ì†‰Š®«â§Uk­u)¼1o´ýj“1´–³ÊÆLì8¬{ŒuWv~•ñsÒå…üÔ<¿øþ{ª¾;€k»Û=yÞéu¿ÿY-OAØôØÙ‡ïo™®?5Çæ»—{ÎçÏáóWÛð÷Ö__ÊÇ'Z²Šæy¥…Ž~hÏj•ä®1JÍgQ}Ùpó‡“w¥ñ0ô¾¡â·l´LÝÑœÏÕ¶¦4-µ‡,ŽˆN8=£Š-VéLµìÇ2¡:pßø`nóå²½¤úä
Á½èÁœ¬¢aˆÞ½ým½µlŠO.€ª)È5P=…f]àe7}ÎO ~mÕ'T(Z OÊ„ËóT!Ç=›itÖâêA
gË Ña@€t¼³_€8RSgsÄ“QÒŒa*è¯6}Q¯-›±â^.™ñ4ì¿›M²ª9ù«å“Æ<©O=NJt‹ÞÙ¬˜Ö|¹ô–WQ§%»f_tíq<Œ"<õ¥s	H:ÝMÏˆOnªv>ž”xÜ(=C&^áL	ÑsJ·‚ÜÅ+Vÿ€‘ÿ.">~ãÒÏôkž>x „‰kÞKÌKs¡™…ËÈÐ{PÝûrîjU‹c›*ëá‡›êø	­›`	ãD;ä Ò7ØºÂXE7¼Q)ß ÔRUÒD”œmÂBÖÚ }´ùc/x%ZÀ`ù±RÂ¸@.R‰qé£…‡ýÇæÚFsýÉÉúÚæãG›ko'¬·ÖZkZ"¹“Ùo!¿Ìí¼Ù…ôb<Ý€‹p4‹²…=^e:,Êz™.à›T)WÚ\8’ËªÍÏ³"¡9¤ûs»!v~˜3Äz¯é¢¾Ýã­“­ƒ£%Ó·É‰Ûl^:Ø¼…,ëkØx¹ïÒ~›pæ4dé–Ÿú«&yƒó3ÛëÍ4ø&txt°ýjëx.üuÅþ…|kÑQÊPíáør}£µÑZo=l­Ýdà{oœÁïbà¿t^w
ëå³iûÐ	Û¿Þ­·þØZ;Y²±p¤ÞÖÑÎáñÉ‹ÿØ/cÞ|ºpHákHau­»°Û9Û­ÁB3¦˜s˜Šñì6w\†52îÍnwu¯eW±ªW™|ÂÄËoSu¿Ü£êŽ7# K÷{“Û÷œÖÇ‹4ÀbÀM:væá)e)Òo­#ïoÖ­Z8ŸôÖÞfˆÖÉv÷EçÕîñ‰;RáÓåvßS!OÊ¨@á‘<:Õèrs›þƒB¿‚WR½G[©û	có	ó†t;@¿$—)ˆ²6ÖZçÿWB xß¦ÿpß“>q´/çÃâß'ü,÷1œŽþµ  `Ÿ¶¸•í ËŽx)ö×Ñ ºÓŠìŸ} 0­ûIÅÆÀ?„¦;Pz6M1\ÅoÞ'L®ø„ÿ9BÖÛkM®æŒ*¯ÆÿW|9ÊNàÓlÜ’Úµ…ï5f“Â7€ HVAyè¿Ö·µbX¶™Ä'XK¢…,ÄÄ£ˆ…t8¿tL…©o|#{ºcŽ=CýH?Fî ó…¤2‚-š/Ua6ÑïX ZERVÿÔ!H(Y-,õÓFs„ÝÛxÈ^Lì©Âï€lòäÍõð›’‹ÒªEmnÃ}g¢=>–ÜS[çQÿ	ÅFâd®ë=ð?©ÚÊÝìºRD­¦~~JikRÔ¢9ÄF(¹\·[º­ÛJ©VUø&ILÔ?OU­{ttp,ˆÌèèé 5UöÆüv2`ßÊ!<cçD@ÿÅžÕZÊÙB{åƒ&RøÙîÁVg—¾9Ùïà$5­á}øÐ5ßŸ>êbököÎÏŸf˜“â»vžŽ#}ÑÌwÇ•2\õ–j÷šB3Õ6ÎòHÎ	#UêÅlý8ÖÉ€‚ÜYM¤ìglHßÛAË±~)ÿ´UKÿÊ‚ëƒ–ú¶•CáD4·(7##F„¿Ÿr˜Úc^Â4‡«<pŸ{MeoÀÂ›"Á°¦ñ¢+C·E_›Oº:·½<«T$Ù P59<K£s}É-YÖQçÞ=|¡Ñ1!¬;ÓþyœGäS‚çWÆ®ñ@»´ÐØ…Þp›æŽõ\[®Ä0f<ª³ŒË¥¨Ø¸\+žÞ¼ˆååöÌT©Ð±‹…;ÒnŠŒ«°5à\Î§ªg¬ma@Ûñ%¸YRm‡e`ðÖtÆoÌ™* îX¸Göë²1¯Å	Ý\£ùÜ±ÚQØ¦S¼å›üŒEˆžÅÍ\"Fª;Oçž–³ÕÐñ–‹­¡-¸Åò.=„€' É×PÀˆöžÁõ‚šcñ=³¥Ø—pYaéxZAð‘†P…Ÿj;bÒ‚mñhØ,ÿ¨ÅO°¡%ßîˆ:Ñ¸ðEI eÒ3ˆKöq»…Âœ êÜÛ±íB“ðÀÖúkêû™[Ù¢‰ÚUØ¹|ZZ©\&½ 4o{g*š¦üiF~}w·;‡ôqC\2ü{¯·«L½¯idÃNHý‘ñB=‘²ªR pÂTWO„9›²™¡^³²è²áÔqgfòö„5†ê˜¤´úù¯Ð7¡RÊ\,‹‚þ-µ›ÚÒq¥m@ûc„D®¦ÃñU‘`í@bÆžZ„`µkÕW\¢=tˆÇÝìÑßž‡q½²t†ôÕ]m€…wMŸqlÎ¢ýu1ÿƒW`âá1‚—:*nçÑh¢VÏë¶r76YŒ½cZ|Nís|ÀY€V´Ph Í“ ±Z¥½Ç®<µ–µ3s«O_€„ûñX†Š Õ`]·¼NÑ+–ù‘™Â¶co¤ú2@†Ì¼,¯Z~`¨fc9ZQXKOýè%	šš·ÔfÔppö˜³~LÛgªsðTY	Gz1ŠÞS"’+îÔiT/è‰˜Swÿµz­™qPw‡ÌŸ‡a¾ ê£š­ÍmXÍî*™žZÐôv¸!Lí:‘j¥?HOÍœ?ðÏ¢Ë­r×d*dÂ]Œ›§®òIñ0I;tÿüœ©]ç95Ñâ)W©04pn-³¼’«hdÖ‹¹py(ºirª%	«<!¶á™–\yY–/“ŠˆNú3¸j$ÏÜíÔŒY&Ö“VŠÄ"çXáÔˆ{ÅÐZ€–…a/>põQÈ’&O7ò!ëýY`ÎÕ_–Î,õ¯Œæîóh-Ào´Ü¶ù´Ô§'˜N¨S¢ü]Wú@¹wÝq½ówíØ
5c°°âcÝøj…ñž"N£3FGúÊZv½BüU|D(6LN'dÞrÝSš·^šT;™aRÄow ø›'Å/ÜIý†Õ“bªù?ÕçASÁõX:•~)ªjŸ4© nUŸ]º>U©TŽw·w^òc Ú,Æ`ÚÄ>}yŽCä&Ës›»,*DÎí Î<©òTéÆƒ`òû*aýÂúÛ÷AÉg}:l´ò*]Ä•û®ò?zTèóøž‰ª¡2tÏ" íÆ§´ÑØå(1eå•Íá(žêï±ÚBøÀ’se›A%.,bµ+ÆÏÔ“~J+Ø>ØëììWÀxámãÇcïdó>j1Xÿyƒ-’©*÷ÄÚb¨ ½ŒããsFsgü
h{ëÔDgGÏóÒ3jÐ:vªÖ Íc*ÞWUËmÃ'Aú¨íCóc%‹“W²qž|´|r äŽ(¾›ÞlfRZ^[ÅHú§¦ïÉ+á	ÖÖÄyT™•JVnP­ð
îFÎ¿Ìî ¦°šýÐV÷ÕC%2o8ÙÝéûìÆ¬\ùÁ®yø”y2cçãÎóÿ¿½o]oÇÜ¿«ïË;p•t;I[ï”\­švl'å.ÇöXNR]•Z/ ¬X&Õ"eÇîÊ>ËüØÇØ_3/¶ç  	R”å‹¬8UDÏ¤d8¸œœtøa»ÿzw¯Œ§9L‚‚§¢j²Asè³%|Æ—V~ÅÇ^3þL/ÄBI6kÿàèx¦mÖ~®%zõ%‚ß¼Ñ®¥€˜zÖõ€²;µÅàŽvõ«x·(^ä- šÞõ]Œ¯bÙÌñ²âtq¥x¾¯6™èŽ;%')à®~§°£ Ïïšò½áê8‚©N²mXé‹œÍ¨‚<ïA¥f¥%Xúðû(|×÷X•Â±‹}ò¢9,¤D¿±IÏBÂœ„QŒ—Wë9Å³-Û|ì¤|Þ)XÏ˜LrÝ$ž'¹Jù[~f%Gý¬ð5zIˆ^Jr¸'8Úf—n3$±#tÓÏ}µP7(âáI‘•9#ÁÇ3já%¶Þ“IM(Å÷ùŽ£ßRüžRHz÷G½Ö•6Iý~
bñ¹Œm»lŠhcø.¼‡P¨+È†Ÿx«ÎS—€
"hé5Jn”L&èä8…9$öíf0¹­#zÈ ÍŒßnZDC¡Ó§×tú4{³£aìi`67Ì¶¥x(á¤úÜütÎŒ ø)‚¥Ï±Àç2³q>sxî¦ç B<†s!â·pLÎODw.ý-µè-¸Í»$Xý&vÜïú¹âôM UÉ§Ð¯§sìEŸáø3Íý×f|¹¾)‘žyµ›%Ò@Zúã„YøëÞÎþ›ã¾çÃ§ß.<øõ&%@RZ‡F†ÓL 6ŠLÃØ. î8ê‰ØK.µ¢Ähò
ÿŽÇÜ6ÈÞÑ‹ŠkbD‚A|’ÅNàr‡›É"`ä¥Ôëh†‹¸þÿñÿ‘l2xÐ©5—fÓ÷ÙbŸ¾Z
kð_ÿ9O’ŸoHâÝ[ÔÚµµ)mñ¹™6ÀÞgÑo0N£>žI½ë óÓfr"ôe€¹yFr>]ÇÄ26¿÷Vb"÷dÇ"ô&¨öå»Ã—XáåöÁ‡ý—ôj÷S8ú°Ne.ëW	L¬H=ÛS?@g,VJrÒ§¤ˆ'é¯d3sg?ìñÉOÃ­ÙÂ›Há¥ÍOÞy’W´)¤1\³‡ÔaPö~†S)ãhÏpZxKJq*ÈQ]ÑÚÙ3«•½šs²sbd/l|Y+Üèï3KìÌ±~:‡´#Tq)!È¸(É4ÏC¨0*Ns}R¬á è’â;E
zü}=v›Ió¥7"x– ms®ùé¸EÝ$dø\|ÈO5URLæè4iÀ7¦¿nï)ßÓÿ¨	I¼A¤ Li„‚ÁÈ§ ˆ­Âb'#Uƒë—¨&ˆ¼cÊrØm,ö|ö{‘
we{µ)m2%´C:•Hì¸Ž\:Õ‚’j¤3©BÚ"´°âJô¥{Ît€|BÃçÄAqm!H„¹ô¿Ì'pÝ,õŠ‘”âa\¤_ÞÀ§Î>‹c”/T,GÃ¸çè'Úhµ%›ZvÔY‹2ŠpÎ¶¨ƒ¦­µ^lÔj/¥_v½|–A „ädÇvb(ÒbE_`õhê Ç ô¹HsoQ¿•^Ð‰K\¤%åø“ÎPˆ˜ùË»Æ£Ò¹Ö”›iè˜Ð¡êZym©7½˜¹Y‹æ¹pÊœ}m·/iB¥ý&g«ªëýÿÈ²®¨™ÿÅ@ÿ?ªfTþV‘j©€{D9ÇCºÁž{Q»Ù%Dy*ªG0¶=Óþ¥:ù[ˆçÔy,vÎú	ç>ºóµWâë$ºÿùŒ7£û!ÚX°ÿMMÖŠþ¿,C¯öÿ*’ï«mÙVeÛí˜†æ»žacÀ)Ÿ¾«»–.«¶OLÕ—þ­Ùšµ³\UW-OÓ;m¹m·5SÓÛ®×vˆkª.‘uK“}³£9bíÌÖÌw5KÕÓw\ÛëøPEéÈ²ë[¶mkºá9¾âúº¯ˆµ3»4b+f»ãÊÐQÕ×,Ç$mMsÝ–;Ðy]w]ÃèÈíŽP›ÛG›ÈjGj¦l©šâkfÇñâyªçZŽ/»šÒök–éP¦mh²a›‘ÛºÜQTEé´;Ž­Ì€é˜Ž'çðºÄ–]@úŽ¥ü•t:®jé¾ÖVÚªÛi+`iÅÆEË8_µMßW<ß‘=Í5LYÇuƒ™4E3Ú®í:ì!ZÑÁ„ZŠm®ëxºá·a’<Ç±¡ËmÓVUÕSÕ¶L±×E‹»¶«(Šj·¼m(šÙ¶-¹M¼Ž¬9NG'š¢wTC§-/²'sÅÞmÏíø‹ âÐ-bZªÓV}W0M`r°ÊMâU5»í{ ³!ë>à^[³]Àm˜!Ó”á³×ö¬YX3k+Ã&pe@IÕ¼ÖÝlÛ€Ê¦åÈm°Nö|×ÒfA‰–xÄ7ÚŠjØL±¡š:éÈ àZ¦§ÃnZ§ú¶éÌëë‹A:€^ºé+mÓët`3)ºá0õ ]1;FG‘u@Ú(‚íŸÁµˆƒ1 µ}Çq5Û$š[½í˜Šk¾£«ó'çŽ¸7ì¶X8 ˆÌ±¡ÃÀi.qdXpâY–íÛl&8O<W…V
lÖ6²å;*Ì¬lµU°Úíx²o(@	8Ø¶ªù¶[ì›`º©¶UÈ‚	8d¨–í 0bÀ¿ºl´-&ŽàÿY…ÙÉÛ:€Æ¶¡ê20Á„hÐ#×÷e¿­À_¹cª–lÃŒÛ…=–·,Îj6¬­®X:qìNÛq:mS…'*,“ca²ê—è×Â©ÉP¨pÇV€æáhTW¶R[Uö‡mé–]Džd.j& ‡¡;Ð<±4»£»Š…TVøðÚv Ž&;ÅÉ¥&µ²ÒçVµÙ¢ 9²4ÖÇqd*Ãnó5CqTØ+JÛrÐ’N9H=9	Ã¸Œ0u˜x DDwÚ0<S±U·ç‘lº0\ÏR-Gs]U)‡*S×=ñAOŽí´‰e¨WÑ-ÏÑÍŽe·;†ÒQL×±áÜRýŽì¹å0Õ~ê?'7~BL¹äRVU–Äî8
œ:¶Ç¯ª8ã\Ó"·€Jg@±;~[ƒ™tL×3588ê4Ç¶M·]·í)61æÌ«Ögy}Tˆì‡¾waØ]àDz¦»’Õ0Å…Ó˜¶¢"õR°ªÒgf%£áÞG±Bm0Û†Bt[íØf[±à ‡“à Qª-»@|»¦Z„©"LÏÖ:6ì6ƒ˜ŽŽdˆŒã¿ÔNiwdÛ÷Ú²%ßjøt^‰Ûöa¼–kÇ7àœj[:ÿí6ðŠjZÀ³hHœK+Z_x8êƒDD{¬Ñ ·=Ç/ÛDÓˆÚn«†åÁ®ÕŠŒžlÞx# ¥¿	x
²¹ækžé¨VÛjË[÷l8RÏ*äHñfˆ!›Y­8³´ŸŠ¦Y¶‹t@ótÓ²[ÀôT“ÈpÐœÚÓ*…É;ÉNþñeÍöMÃ¢z@;€Ý4xžÒÖýŽ¬´a›°%ÊÑIQKg“®?€“m œøºk{¦ ÐµoSMØ¿Ó)ßVŠÜg
Eøø#ß2ä¶é™¸>l×ž„p€ï<¬¦Øú×ˆž€ð‘nÇ)±ô6ì0YW;VÛîhÀ§R ó£Î#V¥$€qz¦ª;®»ÜplB|àË=Eñà}€o®¾m)²-Sº2äÞîÖÎ~o§¦y0$Ç³mpæm`m} \âÁé	‡˜Èï)NR/sµêµ²ø†¦IæÆõeÒQ€©¶;D6€3‰ë%5“[«?¨à¾¤„¼ÐC·r¿aÌ¿ÿCy™Êÿ
ˆ›šò?ì7ãHÆCwÓ\þ/“–ÝÆ‚û]“\täKXÝÒ´êþgééÉßŸ>•Rò›ø½ƒàCö6¢E§þ,õøÔóWÛ½P§g“z‘Žâ‰EDR;ë°ˆªôNªØ™Lƒu©w1Œ¯ÈÂ×–ÙaTm²´1c,ß7i|þ½­è¸ô<$Ñt@yMv/þ·˜ïÊ¡öŽ7ŒËkÃÇmŽ’¦ÑFSÖšJ¾Ð ÂÈ3àÚÍÃéãy²²ÔRŠ[9‹º‰8œÎö¦`˜Í±Ñ%¾‹f”åFÇ'—˜ª€}£á[€I€?ÔÒg8Ö§7‡{­)ÿe©‹øc`‰‡- £‚Qõb9óCáj16'h{oˆ–ÚÁFâÝ®àæç.^“ÄäE{êS?³!%Ÿ‘é2+·Ä©?5óË7N¡q‡ò<aÓFÚEÂô<îÒ•?ªŸg:ã>‹ô8DÁ¥7¬‰ËåÜÅF“µyœ¼y'ÇÍâ>_xÔmÏ”$„–iü
†;³LÏqo¯¿õ®w|ðv÷çMaô)+u˜ãË[çæ„œu2Ê}˜Ð·yn¿™³ºXÏÙøÝR˜3žLÔÑ¼ Ð¡XÞ“C@y æ)7áë>s£ZÞ¡§Ðµœ:kiÿf3„‹v6TnP³&wD(¬Š`6s€ùI|D‹ ›wu)¼Y*ZLQZtÖ•¬èè$g«Wh3ï«S"¼Y°"<äôÜ‚‘Êµ`ÑsåS
x;¤4‚kÛÁeLÃ³;$‰b•§-‹Ú\*ýkéÿ¾’þî—
OÒÆõü¿¢h&ÿU,H*{ÿ­â?­$-m‹~ƒÀ<à1³ÿy'f¯¹#ÇÄÏU0¥Ÿ‚eG‘£Ï³@‰Îá®p‚Ï
œIÃ.ö0HT-‹r’h«Ü­|ªd†;ôž¹=`·Gœ™ÕæmZÁíuÄög6—ï7ºïÑóÔ'“©sH‡=¥»öqú·'/ZÒ/Ì]aÂZ~ùUZKJºÞI¾flÓ—ì‹ÝÍ×cv^B§+øAÌ²G<›{|¹IKC§ØTäÐ-`®3Ë_¡ìIiY¡Àh>0´äÍJ†NÖåBìâ'îâ›€“¼+¨%'Ù ²V3Í¦“¸»?¿[NKlì¿¾é„°•xs³!²ÂöîQº¼©ðð…ËQ«€R"€Ÿ¨Uà Üü} :à¤Œ+*FÉúc¬£9|Æoöaâù ²¹L7*7ý¼û¦*lTFÈ?_^u×èÏ%ðpžkK¥ƒ.·þœ±fDa2‘éjÔ6ƒT¥HM¦¿Ô@¸	yj¬þlXô†›S¼‚ïõš¤Æ=€æS»k®'‰ûø»IÑ‰MÏ¤†+%õû–GÎ[Át4úm€Æws©¾!üXÿÏ¦zÔÚ^oîîíl?kµÒ¼g‹¾ßìl·êßIÔwhSjÐÊ¾ôñ¹ô¿¤Æ‚ÔÅÖêÒÇRc<±üÛg{2€µ–ÓÞy^>÷g;ú›GbÃû7©á«b76··Y'¾ü!¢5¦Ð8óO•u…×¿|…Â\ùR	r'÷&‰'¹xp%5Ž/¿ãž[¹Ûù¼&mªõË´n…øx3Øué;X¥†”Mþ_L¤ÞÙ
(¸PÈ™[Šµš=IJ
<û:,T T¼¤P‘p	åOæ–
®Šä-+M½(Ñ
õÂÎ¨‹…|Ï‚Ì\!$æ3… S,$`ûHø:ù9-L—8¥¹Oæ}ö"è|j¶Ýh$ö¨½IÀ¿ “RSÑ|»Ñˆ'@7G#ø	óámïKu7èf¾jÞRK×IOœ)P¶75üÎ:1‰°%VÞ=*ßí&ÚxF`rv¢s|½§„Á ·ãÞ1õ¸}ýp’	kšžËébBÀµ‚YcúmÌ>Ñs+ÍdV ø%³žL>¬Är,É5»k£cB5_BçÜpNºö4ÓÝµ=ôµ··y¼ÓÝ’°°=’~£\nZ¨¼”“~ÏP2=Ó1Ž&¬£x’fE,«¬?ÑˆÇ™}I-ŸÑŠ: 	)EÄˆ”-¬€žÓ1û0g™ÅœØ•XfXC¾~·˜µzVÜ®:µKªNÝ€€Ê”èv02CvÄiw-gEþ•¶,m|zöu;¡göä2éÖâpU“"ùû–FuQ¾“Ë’å¿Ä“cå</÷¿?6[3†õyÄù0ì®sÔ’k××Ø÷Áëû3¿Õ±˜ÊÕ¼—ÛÆýÕ2ôTÿÃ4PÿÃÐt¹ºÿ]EªîËt@ƒ‡oðXt’PÝ/FG}üm^ßèzñk\ŸIÒSæ²×úÙXâàï'e`Ï°–à"‹-ó)£ÿ™eÖÃ1‹ìÿ5ÝÌô¡ ¬¨–Yé®$=¥ä^nƒçƒ²‘w©Šg$æ«,ŸWAG&˜§ey½4Sg™›ô®%É4Xæ‘p=“|27ÅT°A2(½.ìâ?Û½ÔsÍíwì×žåÇ›Ê+—ÛÆ"þ_øYGýÝ”Íjÿ¯"Uúßï_4/~œ¼ÿðrV½Ò ¯ø÷[uöwÇ”?,ÿü­'ŸýÐmÜÐþÏP-]35íÿLY«ìÿV‘2›à‡kãöë¯Éª\­ÿ*RÁKÏƒ´q‡õ·4³ZÿU¤¼Wœ‡iãëoXý_Išqcô mÜ~ýuµ:ÿW“æx¡ZjîY±
ëoèFåÿu%éiÞH¥¥Ä}Š6ð$?œ0ô¥_ðaãÿ0„™¸Ò¯ßañ ö?›YfÍ"¨wS­v©jµø8ˆ@qæ106´=˜ØgQ­v¸yüC÷þ»ñŒ†ºj2SDgðún”Ø@9ªÄ}BÜÓÌÊ–Å/°©‡õÔ¦™õ[Ô›¬K]©^O{/IÉÈê¨ç‡4iXu±”$5ËJÀ2Š-ÀônwŽŽŽð¥61±¦}*­	“Åæ+±ãI|Ø³5È”ÜŠêÕéìdJÖu„…Ó	‹û%NzmaåJ7æ–Ê}ö-·›žÿºb(–"#ýWÕŠÿ_Išñ	ö mÜ|ýuþGù?½òÿ´’t3O›÷kcÿ<Ÿ–¬?z«“dUV5«âÿV‘žþ/Ê ×ödy—îOîòøäÏKîsîA°t'<¹ß£à“k_ŸÌ|2û.ø¤ø0È¢¯KWÓ3‰L £	$GdÊWOŠ¯„Î-ŸõžÌ{×[òzˆ/{O–õ´·Ô>R`\ÜHÃ
rÎ­€¡dñÜN˜µ‘übŽ7ázÒ,7ßL¾ã˜¼Â#æ"Œ,f™¯§zReF©MÚ(UuK+ÌÊÅ
InV.±³Ê—Ã\ÖLÐ[
róeò±b“2˜[(—‹{›–cö‹iÉíÝ£·›ûÅVYnV
¬í™R,÷]¾¼U#î+üÿFDP þø„ÂFÃ‚Â&+rˆ¬êóÔ	ëIqt‹²7Äd½+~Í™ÃÔÅuHJLß¾$ù#ÏRs6áb~$| ³œ|¤w[aP=/±›ã¤œ¼tÂ2 j!ì1ìxž—Ddí‘‘ßâm‘IŒ×ˆÌ¼3:ž¨ëðéü¬‘¨OðïÜIóqŽ¢ù¥‚°1ž„gc!ãpŽ±9á&Ûr)ÍOV#‹ßØ-ú=ÚXÀÿYš–úÿT5ÃDþÏ²*û•¤ŠåË±|sÿ1s}?O#›ÄW£¡‹¡Ûh1‘ü)üãÉ\ÆoÛŽ¤½íÝ×À;M¨"˜{"yÇ¹Èr¯ðÒ“¢v˜=õaù¦>	šÒ+2„ÿ÷ì‰/ÚA@ÁÑ&ì) ?³ƒ)šÁüåJdâ$(Rq¥÷èã’Ü@;O¼M¦G8æ¼"‘{›Ö™?(m#ØÃDpÃƒü‘!dÀuÀSlÌ…Çe˜ï Ö nHèjÊÑWœ€Ï`œ¯Ç
ñˆ°Ûnh~rA†1 QYèÄÃ4oìù,aÌè³°£sjì…8N }u<!WºPkiÓì’t“Y^‡ßG¸›·÷#üÍ”6ŸÔBçðO[# •€J$>˜AÜƒÂ·qYfŽ9^Ôpýå	^ÐÀ}^(NvÀ};Ú£¤­©À@nHÿêõ~Ø4õËñáû‹¿ôÎ§CÏ}÷Ïw‘Õ‰üceøîpô¡sñÆûÇÁ@iO['§ç?¿\z›?ýp°s²ûþôhÏþ÷ÑÎ¹ý~$O¶Þ\]]üØ:†n¾ïã7¯Z?ïØd:Ü{ÿ¤æ*F¹¿ø`·—„Z}7
3K‹<kÈßnHÈõRdÁGh! .gQžÆ'“p:8iÀßÃxCÒà„Ï
DÃ+’ÿ2ž“`ŸÂE¶j“.ä;:µœE¼Üžº=Ð>Ç~V}a­ ¾šhùWpH¹'ñp sDAœI¸à¶àË'Ód¾QñãOŸv[ÊÁ›·ã·ùñÃO?‹éŸ‰3°þþü#¾²~¬O—þöÎÉñÙî£Ÿ>ü}óý¿ÑÅ§¿ü]	È`g¯}ñæðô³utÙyµßúy¼ÙzÛêý`žýóèÇýö?Õ#™Ñˆi†ÆQþÏk©D¾Üœ¾6à]`‘î Hùx‰†ìey	¶ª`Æ¼k\L`O”—@G[ÆÈn]_fBy™èÏ4lw4§+¸ÝG^º¼º¥nD—;çóýá%^€€ÐP^ìÓÙgÀAÒ¿œÿ}þ”á×kæyþÓ2¸¦ ã[Ëœ!x9w¢÷=8Ûdˆ,ƒ±ˆå¥ØÝ]5{^gx™èdc,öÒBå'à(.½ÄòÌ.žf)ªß…ä}‹·'ß~ºa »{µ±àþÇPÌÔþO‘Uúþ§[•ÿç•¤êýOìsþ2¨t'|« U¾ÉUVÒ÷?8T®bþúÇ/€§ŒÏ}w6 ÈÓ7g¯cÞL¦—röü`ˆ·0”÷ÃÑ #‚É5‘=õÓ'ÆHÔÃdÖÒ›O¹j ù¬³Ð±)†ìÒ'wCUÝ Ý«(b±÷‹{ÙR”¤…#à˜%÷gñÃÔ‘èi8™ÓXŠ{0%C¼ <¡Eº¿é«4`MtJcËÐ[¿¦ôaHå'†('®ãÝaDQ
Ec°ï(£Ò¶ Â˜~M„ˆ~Û.°Z¼.Eè6-‡Â*™Ž€Î¹âóy²{šË]‘Ä5Jæy³[o…ã˜‡Š©ÏÁw½n½àóäoêÆˆñŠÚT›Jð[¬+¼â•‡ç•cn¥¥‹Ž’ç (í^¦ ¤OÝf
ýLË=~Sk”B7Ðù%ºä`¤‡]RþCWÑÚBÙ^o¯«˜šYÈ>Ú9ì¶;´4çfCÿž»'áf·îò)Æ{Û;x}üaóh§¸lQèÇÑ¦užáDk¦VcÓ@Õäï/-ŒGSRîõÛ¹bþÙEI©ã÷Û¹Rñ¹×J†ºÙÍH]
½GwË]5¦¥`Q°y&{îòöTBxóeúê‰|•Vüqç½ãƒ£[¢Ü§ÓhÄá¬_£ùšc¡÷û»[?â>èÖ“_ÙpjþIÇôCÅYãøüÞ}ö<}\IJ¿ýFµž%Z/ðì}J`Ù¥K•+”z.We¹j>Wc¹Z]”ó`gÜ§+Ñì1¥¿Gä?ÝÈä?øG§ïÿf¥ÿ¹’TÉbŸóòßœð˜•¸Tæÿ÷ÿc¯0›Ó~ŸL[eÁWvì–<æÿ˜‹ˆ7}ÃR½ÞÌÈ&^œ½òS_3å³†÷¥³ÍM©eŒ›Ê„Rê@þG`qÃ…ÙjóÃ–C]{ñÑAÝ&]FTÂœ…Q7ÓZ z
 ¸\‘V§SÇå€J½c¿’†,b$eö .¯!Á×ëž
¸‹å<)‹IÊ¸'}³ûf.,Ä»:ƒ$Æã-‡Åõvì½ênª·›ûý©î.Q%7Á‡|©$7+—­¶X.Ëeê»¬ì¦çqf˜ùDìÑW‘:Õîëö´…J²ìyh‘ší¸DÅ6ñs?«Ö;ãá¾T¥—+µb×y¢+sŸŸ<‚åô1¥ä7`Q	øžÃœQÖ='ŽÉäÏ4r@ªtG‚K4¬‹+þ;}šº!ÿ/àü¿ªèFÆÿÈÿ+ªYÙÿ¯$Uü¿Øçðÿ]˜AÒW‘BÆ¿¨
,Šlþ­ƒçˆE•jð7ÂŽsE§D…ƒ5‚N—7$Æ–,ù¸{\^•riöü×úlÓõQO«ÏM£îu¸Ðþ[—³ó_CýEQªû¿•¤êüû\<ÿËwÂã>þ…@tÄz-l«ƒdOnØLùñÏ¡ÀQ5Ç9ÖA¸²Ãþ|¢
Y8¾Ïà€cŸ¨Æ$c&šÒf ‡Ïoæ ã2„&.àüäê¹4`*Ž$®îãîÓÇê>îaïãø–@¢Á¦Ùg+înî¦w[‹ÍÒY¹ìûk{¼èþ	GÃ‹2ˆ0)éœ0‚°„H6R#xw4õÈ«	t‰ÞÑ$=Ï.q¨
ûî6Õö§–©aúÐO.‹Êî¸zHYî9d€ÀÇüÝÍðªÒçá†W”6Š•ÖÿÕ¬Ìþ[±TßµÊþ{5Iàÿ–wÈÜ…û»ó·ÔçX?Eí¡wû¶çÑ 6é,=Æ  ‚ïŸtûrµ]à¥hÌ¥S:˜»w{Nj#µÔÕ€ÑJ?0N	»¨BJçÎ,Ø©0‹tIdÞ%6¾<öèÆÜQ ja.>ÖºÏ2Xb(ô9LÇmyŽ>Þà5P(¢HE¦„ææÊ¨¥eÔ¬G×<*ÞøMQ,x´s8sÓb×¿<ÞˆéªñRÙ™›[4d3?8¸ŠlºüIxÆ~«õEOq"<¡™5ö.×c¾b0þ&—ä	–ß)lp”baur
¹KÁ£OûzÌZýÓõ¬'N‚®{Þ«å¢~gÏ|³îxj·™O^jœ$ÑÆK:¼ì¯<Êõ,ÿ§ù?u¥üŸ¢1þO¯ø¿U¤Šÿã®ø¿Šÿ£Wü_Åÿ=rþOø?e™üŸrþOý=òÊ–ÿ›óþ{°üå—rñ_T Tñ«H3ë¯h¥¬v!`‘ÿÙÈôÿpî`ý5½âÿW’*þŸw8ÏÿÏßŸÿO¼£Í°þÔYºn;›‰ñœwå¶zäÛ¾…ÐÏ•,ñèd	­´Œö;‘%Èì‚ååAzbn8®ÕoÅ/ó6©@ÉËJsfÖ
 0P½ÄŽC)á›é¥ï­–‚V¯­–€s(ô
Æ»Ó	vRVG½¾ŽZ.ú”Ê©<t q1â2¥ö˜dJ­’)¿a™²JßNºQü‡‡}ÿ±d#‹ÿ¥jÔÿƒnVòÿJR¥ÿ-öya0ˆoKù;l’9!¿¥K‡9Q1îêÐ¡Þ¨¸s(õÞ0¨ÔC¥A~>Väò$•dŽÇX8é+`P)¯×?Üìõ>mI‚I?©±6€š„å ðûÅ	¶ÌùNòB–‡)ê>{|¦DÝ€M'¸»Î¤ß  Ôð\©¾ÙøÙn\ÉN2ýpäII‘áëÖ$åEûúôôiòÉ€HméÏ†u‰êR·+½ü€ýú2ŸÀ‹YÐdI¿æ†—îB&³¡u 2)½¥ûC»èŠ{2´¥î÷ÀËWu€VœfYfûØƒ·gá¯Ã.JB†ƒl1¡-È~{aÀ`€ï¹_ê",üu@Ý=JïºÍ{œuÓ”JÀ‡l‹ÍÀaž¶l‘6f
`ëßðY„†#ßõvŽ¾Hsªmæ¡cµ¨¾ÜiÉV¹¸KªXÁ
 Ê#£®ð³¦|ÌŽ5‚ÛûûâõÝMœt>€i:-É"\Á}So¯7›å»«Y²7XoŒâ9ÇwËm\ÚTnkî˜*+þßešÕÿÕŠú¿÷yú§éVú¿,þ{¥ÿ»¢T½ÿóWú¿é]¿Òÿ­ÞìÿPoöÕ[mõVû(ôùÍ<ûè¬9¾\±ˆÿÓ3åÿLM–dÅÒd­âÿV‘–unY¾ÝÀ&ðÞñò‡E÷ðè0Ñ×äöŠÌÇx ½·€ñ«eð¬¦¢6e½ÀàÍáîâwV¢•¶Ã3{øptZS³ÆL¤0Bìê¬FäúÎ“À?5ÎyŸ²t4u¡V“—mHü|mûàíæî>x´¶.Õ))í³zõ	€1^Ø\ Ï+ÐšÊJ‹U‹ZŠêÒŸ$¡/jôêÓ$‡Aü¼•_°Ã‰†@-YVê/’ÊQ4Jê_W¹×Ûê«Y}z!;o8Ù]7V¼ ,íÐ­§ÇH_IÝzþ ø£Úx‚ZcÈN·.ç¢~ùSôëZa2¾+?L¦y¦8.@Vœ]¶¦s˜Ïf·X¯$Ybi>Y…wÙü”‚ÇùËJ§OYsJãŒAi@UN>ìõbÀr(}`9ÏÙx÷BÎé¤S-ÌÃzî=¥d²9aÕ²ù¸®bŠˆ¹y¹®"ÎÔ¾°¹²ùYT+›µîÌ<-‰«úÚ§õòÓ¬ýÏü«»¶qûES˜ýOåÿs%©ºÿãþýÜÿUö?„«¬îë]âïÛ—ÀìÔGnÿ“¸¨ìÆþ§ò)QÝ)/:¾6³Z¥¥§YùOî3Ú.rÀÿÕ2²ø
È‚ÿU«îÿW’*ùw8/ÿÍÙß€ð7ÄØ
ö(1­q’Ã9*(ƒ¸ß2H%ä]+äM*!ï(ä•,¢üó´äÎÐó™¡‚^:÷’ôˆ©¬—Ó„Î‰{™ô­>ÞÏLä+oA]ÐBQî›#øeëtÑïúZ9áOU‘cùÿÅxþ/_Y ´"Î|tG¹¯ `'nŒK­(±E¶l:‡Ô6w0sûýÍ‰n7²ÿG«ˆ{ð˜ùYˆÿª*”ÿ·*þ%©2ù_dòÈÿ˜þ™u<f‘^#¼fÖÿ¯H0ÅyÄÀl3†ò©õSÁ¬hÖ] 4à‡£	0¦\®)ø›Åi•†g¼gÀ½ŒÝFâ«¸9kž/†Íú=jèo;ÔþfVüA‰ÿœ1$ä™IFÁÅûÃ™Š45€˜»A7³×djk ëŸ ~ÂÁ6~Bûé90`œÁ(tìQÃgÉüxnÃÀ@Äò×#ÒH´æ Bè|‚ž¸81‡œØçÃp²a».Ç•ƒ{ôqÉnH›ÛÛÌ2=ü1ç)ˆš3‘	6'BÄ](¾³J ¬A=r¤8èß›:ñf¬A÷ŠGF½ Ú£_øŽá“×¥³)¡›7û+@÷$Tƒ‰
¤Í­½µvœû(-5ð¥›r©ÃFDGTÔD'á¨+åÈ$Euä†<‰ïÛnÔŸÃa; 1¯ÐýXWšj³­ËMEÑÃl*M½Ù–õXÿ9·î I¿“l˜Ìú6†£úWôÄ <J'§î§ŽOoEb½üXÿÝðâ9PxÂGúîÐ´q…­Ó‚ÍŸ [‡ß4‚Üö~„¿Ùf /êËÄŸ}°3þ|üIg~)”B[ŒAÀ2w–ÿ/ï~/	`¡ÿ/]Íøã¿(ªeVüÿ*RÅÿB>ÏAþÇ,$“o 	œíŒGžáEñÌ|ÿ\¶ÿÆ\ÿ]˜þŠç_=ÏÿÖŽ¤ÂˆûÈë±«>ÒÀ|Æ‘\»Šé¢Åcø¾‚6F¡kðò”µ°Œ6#·v@—’¾ÃmÆ@œi,½'˜(´Ínë6mÞQ°/ãøÄKÉæ]ºEcÃàÜ½†Í{í^±ý¹¼Ü˜·™3)uõuH{ÁO<5X×ríò,æ¶¥ ÅãPêb')/ H¶Ð/m ¿4Ö¹wc-$¸ƒ´ÔÅ÷îN
Kós}ËrY÷Ž´´wo’ïi‘qM:Ol7ÎÚÚˆÆÄÚ£FÿO/Åñ¤ÅÙVØ°Gã{C_¦g€3î†¶žÔT×g¿ñ6è}2%Å¹cGÂ8âL€H®ƒžp«‘âú”.Í!Bì<®[ E&œž=â“Æ+t¥÷1­üQzŸ”(­Ÿ¢áÆT´óŠr@Ù Ø o€EÎÈF½‡OâžÔûa³¡ä:	û÷4œÆï…9*ûì… ¦ öÍ4ˆ7´Y<Äž5ÄGFñP,{{(Ö€lX–e¿xm›äóxÈ7ê0 ,‚éÜ0u
-7&äŸS8Ï@¶šNà¸Èf†uéöûh>JÅ <‚0ug„:¦õÝ
£î„Q,lýÁ$Ã'òyâ>Ä“xŽ"}§ùX7ï‡v7ð†Wä3|àHBÐ†ç@‡=ò™³KÈà(30,ÁÉ Âtò•SP¾_ŽÉŒ <¾œ÷Ð;B®iÞ÷hêÀÑ
glZ ³Ù11tÓLVƒöè¯Èa~Ï¸ƒ—è0¤íW˜ÌI~t$]ˆÒá1p¨ý™á°Ñ×­Ãxæ«æ«&Þý÷ÿMnƒ?«ñ8.ªôèSvÿüø$ŒQ
õZÔdyim,¸ÿQ-+ñÿn0ÿ_Š©)juÿ³ŠTé|&—€óT½s/Ù™RNjc^©Q„F7¨;™†`ñÚ†{Ôª;oÙAjDßœ1´˜ÌµèûsŒt3j±‚&ü¾M-!£áíAFñÐ½”ÛV]SÐºÿbî˜§zkÞ¼;¤9n8¾^0pyÆ²TóQNÈéè’þ<FxSžÒ¿Úv-öÉþ_Ô5ä·µ/µ»Î“,Î)GŒÛwûmoç6È1HãvPÁÂ¨AðÛ­§ú’nzgQi˜K®Óv-Ïi'ìÌ@öínëqÍ"° @éÿÜó‰gÌ‚ó_±5=ÿMË‚óß°£:ÿW‘–F-9Í¬¸€Š¸åü?r.`ïàM–qNúŽížNÇ”4çòÉgÄçÙ|¦L<“O‚óä}57j.Ë§@Ïï¶ÿçÒ\þ%Ñ˜…ô_Ö3ùOAÿ& ý_Eªä¿ŠòW”¿¼ƒ¿oÊÏ’¨ÿ¸lÖŸ¦ô_“UêÿÕTÍÔM¼ÿÓ-¹òÿµ’ô­Qío‰noÁŽú:ÒëŠN?(^&$v•%ùÓÑHb$_
}j 9™ø<˜h.q Ð°,)é%ü›é‘€öŠôÐ@Eá ŠN¤F,½~··'5ÎùÿNl@…¦{"}OƒØwõû?+µ¥ÎŒgab†;¡ï–öêæ'›y]]×ÖõucÝ¼Ù<íîoí¼ÝÙ?Þü:ÓÅ¸ƒ•L‘ªÒ)z9wb8§‚³h&¾ö©T¥U¥ŒÿÃ`~£ˆ{þ˜£ö¥´±ˆÿ3Sù_×MSGÿÿŠU½ÿ®$=˜üÿˆ `_‘'k0>rCšAûkÊõ</)Ù±T`'güË¦l5¥"Ï¨4å"Óø. þI”ì{o¹§nTf`ÀÑ%ôãÌG‰‹‹b#Ç`^Ã,fé¸9	þÏ–ÚuÇæzou2N5m&¶*×­—žÓž¾hJ›Þ'ØƒTj]LBà(`±óP¼
u›ïKêFÆÍÚÓ\ijGFþe±š7rß£©JîxvÙ¥Ö4š´FC§Å‡ÉÿÛ*4À}¯Pø¬fI¥ËSÀ²ÂTE´ŽÞ#¶NÅ7oÅãÕ5Óz‹P¥3;˜Ú£kG´ÒbÐáøöÃ’• €+QèÖ¬ý‚ôã×Ú6aˆu18 £#»œñ¬}°ƒ8ê$¾'§MfSYÛôc2)fJµ_8Éþµv|9&ÝhDÔPUmekopÇÒ_ lÈtÇwg¶k;Ÿ‰Kñoö[‹¢Øâì¡?ôµÆ
‡ã’²ÈÒ"âˆÅ‡g$œÆ=âv5Y®A3gO¼ƒi<žÆ]@8X‰¿¸a…ÐýäëÎdNŠaÌœ„üJgŠx¯.»gÓQ<¤:¹ÉÔü.¢
äù?vAÙwWïëôEH‹ü¿¨–‘ñ:ò¦eTöŸ+IÕûp˜ÃýGz©ˆwˆÜ6?1ö¬ÈëQ6Ž~á~ºF—P­(‹È\Æt’ÞGŒFüXò±‰Wì<ý£œÀ­)µ[ò¥dÊˆº@dÂ³áÕ]}42h¯`]H—áØªK‰Ú†g$M…—M¨ÿ7¡anà†L0àA¾ZtNGž„1°ÓR@PÑž\BÝx-‚ÙDM5´óõÐq 6†|]ÒVŽ§àøÓVt"‘AfYj¢KÙþx"6Y›Ç'$lŒI‘8úôù7X:ø-èìs{8¢
-£qƒ‡]ŠíDýºííõ·ÞõŽÞîþ¼y¼{°R+uFÑP„QtÈÍ	-xp´¹µ·C/Í¹ƒEÃv¸ƒýÌÄ‘õd+F8K­©,·ìñ˜ë2˜üNe2˜0îk
JmooÎ C@™Œ„£t¶×Ó›ÆõüËq”BK=âÑ>
]K]™Îí_Ò™Vî:“xëÇw‡É¸¨üÆx1LVP\êbtfÌObëlèy#raOˆúõÛ	ø;¦¬-ÂûûæûM±£9xŸ ™¥Ø±´hò&œ-%š“MPõœP’5¯ÍäZ—Ú¡ÖcD·®‡¼?,n*P¬!m‡”F0B	²é%83JŒp\yÚp<¼–JIÿZºÁ¿¯®©ïŸòü?'ÀÍI4^bøYÑÿ¯Zºfj&Õÿ5+þ%é—ý7»û;¿ÖŽH4†“°×ê÷ÌqRWiÊìµ_ÞììïínýZëíl½;Ú=þGÿÝ!Ðê^ÿýîfÿí?1ì½;D]ß-M°J—Êäÿ%Šþ4-Øÿ–¡¤ñtË”éþ×åjÿ¯"Uò^þÌ¢ÿVNû“ÒiàÜ8‹i†vDßÄàµ‚ã¡¼DåšwÛé½pTz‰À…4ø…¯P£K|ªñh}±%·Ãi,¿ß¦Î‚ó?ÐýÁ2oð‘éî¼-(ŠIïÓe»ÝX{Ôk›Ì÷›GÝ÷öhJ–ØY®ÞrØSºk§ûx²ññ¢%ýRˆñ«´–”t½“.|Íä¦/Ù»[ðÒÎœ­g^ å!{Ä³÷¶6÷¾Ü¤¥¡Slª rèdã™%”=)-+Í†&„YÉÐÉº\è‘]üÔ¢>&“pxÃ÷DLëxÈNdÍ4›Nâîþün9d,±u°ÿú¦ÂVâÍÍ†,\lï¥Ë›Þ|áQ«€R"€Ÿ¨‡·9 XÁY °¶¨äJ&R4&W@ÜlŸ%ð™ÀÙ‡‰çƒÊæ2Ý¨›Hyo·5¯Ý¨Œ’¾¼ê®ÑŸJáá@	Ö–Jyìp;à-RŠn»'ô6)¹Ô©aî/ô²	ìïíöŽ¿Ô$Ékì¦«?vëMIØ¡ü*«ŸñÛÁgÃzÍRc•p×¯¹^1rÛùki¡“¤°³¯#úµ.Rºðµ	=˜-ýÊ•Â-4[
rs¥pGÍ–‚\(•ž”ªÐëáhn¡tŸ¥ÝëK³M˜•R’›2º"ÙgÛ™;íÅ¢ÃÒ¢¹BÂÔ¥$(µÁ¸»6 1Ÿhž°\vUÚÇ{±ä|AuÅ2'Y0U{[@†öö@àìnI#ØmöHúžÉi¡fw?xRó%l7…“®=Ã´@9'ý>a Fñ$ÍŠXV´hÄ‹xö:£wÁF <]Z&Ã–”p¤Û€û¬ŽÕùzdàN²êävÕ	¾uÕ'd|; B””Jt;ÌŽ¾	œbâ|v×Î‡9äA‚ÛN:UðçtÌÐbš"Å´˜9í®Q£þ‡®©‹¥ÔQ#*TÄ)ÄdaÁ…æ†˜	3”9	{MÏ¾ngÐÉÕôìÌž\&Ýò"Ø§B˜‡¯27^4‰°e1w² :ÌwY8g	–´ÆÆçkÆŸcq09ÿ¯×gmy*ßìUtáþgb£,§œ»Ä6ÝÿBîÌý¯¢W÷?«HÃ ½•À&îÃšw/˜x²„ýS÷â_»÷Uºo*×ÿ¢‚ÑÒ®ìUˆÿ‹†Ÿ¨ÿ¯iÕþ_Iªî‹ú_î‹×À¬ûÕmðMQ º^úmðn¿Æí™$=•bÂ®^/HKüýdzìÖb2$r²Õ1Ÿ9ÿAì^ö³ˆÿ×ôÌÿƒahÔÿƒ¥Tçÿ*ÒSJòÙ‘BÏ<#”ÜA@ÏIÌWYþÞöæ¡„Q1OËòzi¦Î2©³Ä4Ó`™Bäô“¹!ŠQÇÛ¨E
¥×¥ƒ]üg»·³#%öp·ßµ_{–ošÙÿÍþöÎëÍw{Çý•ñÿº‘Ùÿõÿ´ Úÿ«Hÿ/ðÿÜ¤üÿrvý E)áiòGåáŒùïÃNó¡ÒÌùŸ…=\šç¿feñ?ÀûËÔ´êü_Eªü°£í¯=üïáä>@né$Ì;2)z OðÚ*¤3[âêc=…GŸnkïô£l­ÖïG9vÕÀõÇZº‡÷A¿£¹°+~óÖ,ó"^ç<Œ÷¹íîìo÷ú©9d·N7Z@¶>y§Jd¾bª­zÞ#Hþ–4¹+fžA²¢ÿœ¡[¢g¹uÂq±ÊÈ¡¶w£JÂp>©¾<ç"Ì»ˆàÿš2€ãaùò&f,…ÇXtÿ£XEû?K‘+ÿï+IO¥g»Þ†ôlyô‡¥oî:(ívñR(·–{%ôl8ä-z  `«cÅøÉ±b‘ä+–c)“€Ê‚?¶”7§^ %ˆ/sÿEîñq:(æëömøáÝ­y°HžÛ…ŠˆéëðG8Ô<wCJ3kBˆoÀÅÉÀ¹/pl1ˆnÐ¥'r´^Û…ìólõBKîh+b8È$…|HB8ûçBfŸoùk¿*U©JUªR•ªT¥*Ué–þ?™¹’ ˜ 