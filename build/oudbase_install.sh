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
VERSION="v1.2.2"
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
# - EOF Script ----------------------------------------------------------
__TARFILE_FOLLOWS__
‹ -Ê°Z ì½ëzY’(:;Ÿbµp6£‹m ªÚÌ[€»}ËÀÔ)ªÝi)ee!ej2%7x¾óã¼Äù·¿ó(ûQö“œ¸­[fJ2`ªªgÐôVje¬[¬¸G¬³8iýÓþ¬¯¯÷ð¡¢¿å×7ð¿òQ÷7n~÷àþ·÷¿Uë¿Ûü'õðK?³|f0”<¶ƒfƒÁ‚ßeæßÏì:ëŸÂô¦³¼™¿@‹÷óÛ‡ëhÿl<¸ÿà»°ÿîo~ûOjýŒ¥ôù¾ÿwþØB8óapG5nïÐN²ø"ìÇ¹j?¯«§³<N¢<W;ÑE4J'ã(™ªVÝÙd’fSµút§»ïtÃè<Ê¢8ŸfažGjóOuõýÆÃMõ|N§gÙìü¼®º—ñôïQ6
“þ­ú GMþl)ïdÀíÙt˜fòcwÂDFÃl«Õ4Ê×TNÏš)=û·©,@³—ŽáíN?žV¿?î„SÛïæúÆ÷ÍõûÍïá—ãè"Îã4¡_hŒG³l’æ·}
[§º½,žLÕ4Uçü3ŒTœÀÀ“^¤xü*ÌUMg‰ê¥ýç™N£\÷w2„]Êü5ãdt¥fyÔWƒ4SQrgiB[K?LgSuòj§]ÃO4Älô†À†Óé$ßjµÎ¡åìçÞâõÈ‘Ò ¦a÷{q/Jôží5î7×ÿåö6 í§ýxG}ì¾æQ¤`D°¼š
¦»qE¢_Fé9Ívœf¸|ðç8œbKø_o&çQ~«l¨m >é8þ;wó©¢wt‚_îœžœî<^yï|ÛjÔ [¦çxžšiv^»¦Î;I_¥ƒÏC@ v •g£©zŽfQþ‰	^uŽ»»‡kÍÍæf-Ø9luv×NŽ_vjjÙç jx6Šx'cø#œL"  ùéa·ó¸ö¬½×ý@QvPÎLwûx÷èäô ½ßy¼²Šxœ ­P+ëkÁÉþÑéÎîqgûäðøÇÇµÖt<©ÑÃg»{ÐíÊ{¯ÁuË½¹²Rº'íã“ÓöNçøq¾!‘aga—VÞ;½_«ÕWQFH¼ò^Vízyå^-ØoïîµwvŽ;Ýîc8qÿ–f!»fotŽ¯/»'0‡! bóI«]´’Ùh¤>|ˆzÃT­`ìmWä…´\äù¼gPÏfIqïSñ†AÝÞÁÈxÔË<<V×Ôû"ÅÝ‰óÉ(¼â·Ø3.´AUByz´“îççª¶{ðìPmq§õ"BüÔ^dª«ðàï þlwž¨ÆŽúø{ç þþ…ÿ>Bp™fýgpBž¨Ÿ«:Qª1¬:Ô9°äÀËáËœ·/ªÞ®8Ts^Ïª^ï£Þ[¢ÐY4Å=¢Xs 8Ó¶­ˆ­[ª—<Þ‰³¨G\`?L`6Ùp•+÷ž¨‰<"z3çíÒ®àž¨]áÑUïí¥çDÂ¶`«÷Ÿ#!¹ævñ@ý7®Uã|ªÖÕÏá'žæö(
“vÒÿ÷05j·ò~óš~ŽFÀ|u»U¬~]ÑóA\·Êý*OÔ>#“²i<&ée<ù§›V{u-xOóÛ=8z	ñýÆ7[÷®«> Ò†o#lv‡ 9WgüÓç5íI‡¥&P× @TC $9X…*	È™#!6ÐçºŽgö¢_THðÉî~çðgÿèvdEUû—o~l|3n|Ó?ýæÅÖ7û[ßtkk9¯Ï5Yò21 xûú=üKx†ój­æ6¸Ç¿{šýR”‡=‹ù5âyˆ¹×5õX‰lP<º©–!µ¥>ç!£6c4ÀÃSS¦ :6Bçš7½ó´ŒiGIÿ™ãÁÔ|»ây§Qc·„ñÒXû©×ÅÇÎÌ«ðpéì*g¸œ×Ô™iy¶ý4‰Ê4é·íÉ“ª9ýÎV¿z7_¼Û¦Ë†<ºL e U$ÙÔ@Í&@¨0Eïâé-ËBË]…¬$«&¤xÉ°i¾¾fx,RUà¬%ÁÚ%SNs ¤Ð¼STÛ µè¦z:ñ¹
Çé,!!=ÌÎg¨#çMÕ…C5#V†d½—f(g€"5Ý.6oÚ…¬V‘•¯ÝþÃ¥ð])„Ä@-ä“tJš##eò¤ýôZAWðå¸½½×1ÒÌéÓv·°p°ÐK{¥×¨Ÿ<š`ïaxÆ#”½ùll,ƒ¼ÎF}‚0Mg½!k8/oÙ?Ì(ûêÍÊû‡€­¦¤îþÒùvSàòVÓ0±¨ï¾ÿ`éû,ƒÂáôIzð__:~v7›%	Ê-bê¥ãq˜øà6?\?wDr*´,ƒ<KÞ&ée¢úF,Ÿ^Mxÿêp¦ZVxÞÀï/¿ç9	meÁÝ=47AßÂ¡ÁqÉZx n€hI1Å}K6Šdac9ƒ¤1õU*§Ðœ:ŸÞpËà,;Û„”£0¯-µ»µhY™CZ…×[ð­íóJ£š7þ¥;Çã€Ý}À®$OåTëu2äÂû§?­tª?Ïò©º“$T9hÃp4J=ó¯K	æKAQÑ	µµõçºÄ¶ü1GãôU ¦VæU+Nec¤c¯1MîÀF¨tÖ×çÛBíÏ"´ÃJ³°žÎÎ]èh²Bólƒß¼×Ä®êÆmë`FõÂŽ‘•Ðúbz<|öùf¶í&ñ4GŸgCHŒê†ÁYdÒ
ÕÒì*ÐÂŸnÆÂŸ/ø1°Y‘g”0¡YÕª,{
ùæ†ÑÈ1PW3vèØŸx÷üáªà—?ªF¿ð³;@¯×uèûÚÃEAªáø‚¦r À™ï…£–8¡Y3I‹êœ @Ñ‡ÅÜˆ,Œ6SøSSÇ\êÛ½ öb^-`~o…iY’üW8™ÿ‰r¤úçÆMºT5Ç¶âM¾`zÌ~ø«²ávèèö=ŽI$æecœÿldePûaüÉÞç§Y8Q5oBÖkhƒ¡Q°ÚŽYè/$b³÷W¬`¥ŒToRiBŽ	ãªÉz°ìŠ§ì<š¦@VÿýI–â¡Cn-ÒÄWvf€S´Ó±¾&o«áE¼µ³õËVg+CiÙ¨m¬ÀW®‰!sÝ!ýk}Âù-^SûW.#zÁÒ<÷ñ¶c»ãœ¿è®)qNÛlMwŽöv·Û'ä)Žª³æcc5”Õ“ÝT+÷\vE:¤¡þüR”([a	
GZ6¥yW¨¸	mðmPO”õIl>ùç ±cå_¡§!ÉK*BF2F–ŽÃ$}oÚWéÞÊ=T¥À64%MWª™ïÂb¹ø‚srBÐç0ÿDÇŽf>Õ‘e0n§Ó“àÜX˜ªÕü!íÂNãÁUY
/@bNå°ŸË6åGRÄpÁ9¸ØüçV£Vi…¿v^ðNŠ~Õ}@VÞ½Þ‘e»¶løÂˆËï\—™±Oï—QBØ.òÜòFÏ-te/ˆÕÅÃEïKëFƒýîAG€ÑWð$I@ Ç“)ý}”¥“(›ÆQŽ#‡G¼vvb;0~ìÎQUNN3ƒÛp¬žøhgæ3ÙãŠÃ†sä9¸Æš…‡®¼ÌÞ+Z°‘NÃþ/(°ÛÓ¡ŸÛûðÿÀCŽv@//-*(KXÝÍ[]i5ZwÝ£"oÿ’÷|öÞÂ;jw‡}ãÙhOÐuŒA*¨Ö!	Ì ©M£wSTfVZïå­7IKµ]/èxìÓÒþ*-·À•ŸRoˆxÄœÓ£Ö7uGÔçn”]€®‰XÛ-îáê9Èõ0²žº[j&.é¨ïcMÓ¿Â^ƒjà£ÚÚé“âõ¢¬X@Šž¦6=«:EuÑÉ*3¿…J/ª½{;í#úO×3èú+Çt¬ìÊûØQÅÚ¯ÿrzˆÎ¢Õðò­ºû´ó|÷àýq÷qíMÒxzí3ú³öh÷ùÁ!ÐK`{7±¾øø!:ã6Ô©Ö_Ûý~ûÔB–±²‰Þüp{ºûæIK½‡	®®ÜçÇž<_8ëÔ5ú‰Þ“fEÏ|ÌPkf¼ÞqÖ+N+ìàÃJöÍ¶±¼•´rEÓ;Ëf@Å)g¡Kçqí¸èøýº‹¿Ñ.:fs"¡K8€t™OÀÉsLù<Pß€øqŒ”ªêý¥Œ”²+G‡ á´wöw\Þ8—Í†ýqœÜ€ÏV3×¹{9—ÇzS[´õ•ìö3vþÁf™9XÚÝ>‘cTèäƒs¬ð,mÕ	Ò_«–žv­ÏÉwêÿçä M„#<>úœ<Ü¬<(Ÿv86+—ÈGùÍJ”‡¢Ñb¡º»¿HØÿHÉúåñÞãSnµZh&êž\o²¢î”[UQ#ÛŽq]RE“)ÀèÂN³YâHr|–Ysžepòî@Þ"VNœ˜fÈ	íWüw4<N'3’€Èƒ|E¡®e‘òcÐ×ß—û2»U
Òƒå%…Èl1V™Ïµ¤4~ëîÏùèø"ý-âÿï¯÷Ý·&þÿþwßRüÿýû_ãÿÏ‰ÿÿ‡‹ý¯Šû7'â#î_¢ÀC ÌÚ+ë
Où×ÿÿF!ÿê#øÕ×~áÿBñ÷µÚ'Ý;1÷·r¯~—1÷¿R€}Eh?âÊgÄÜ—‚»»OTc¬~pP Ý<Æž]5«Ÿaóðúò˜÷€2Š¾`|uùœ·KÓ3oï‡ñH‰Idîë;ê‡§»;Nh>Òƒ¦m˜Yt™Ÿ­öß«Ãõ×æÇë½ÞAETwrä†û,ééÍŠö&Ìƒ?P?tþU±£öÉêÂ`CFV9ä^¤ùÌªìç÷’ µ­k&·t7 êkÀ× õ5àkÀ?nÀ$Ì_8ÎnÂMöóä%ÑÈoÂú*$9 ›tŠKá±À&ñÜfˆUõT‘ŠY¿Œ`ÍA¥Q%j€¶<r\¦'¥;YJ’	¹¬U‹€_èrÇ$apQ 0Ÿ	”×íã„¢G‰*?Ž±®Î@±×¡Õ¹í¤©Rt²£(§òIÔcÅºDÄ¾&\|M}XšúpöÞÎ&yEîÃý¥ã! Z‚®Hž¸¥¨ÿåÉ	Û:ÿ ‹P²>œâ?x¸ÔŽ÷®b¿ÌâiTb_žÀ±ñÌ¼&Q†6,œ®,ÙÇ¥#Ì%û÷›×]æ03 Äi†tXS©(Ç_.ãÑˆéXŽˆC„Z{¡Ój‰Ý»uÖ.ïaz©ÆxÔ(¦ÇPè)ôlÞÀPf´‚­¬^öTc¤~p×¼f'È¨VVWWäýAÂøšm‰ÐUƒc¤ñk7ùÎújä0ær°Ö¨Ù‹µ¸@‚ÌÄ%ë_&p_ýOÜ×KKrÆ¯·¯0v¶sð
ðj€TÐ2œY"M,îÚüî€@w½¯þg„ï«[ŒßW·À?/FûÀ*P“4N¦Q¦ZDŸ’Ùø¾PXÉH,KldFj¨÷0
ûÐ›†ê1’˜À$.÷çíÂ‡ˆ“þœ£P,‰Jm¬ÁÿÖhX·ö?ÞŠ·:ú?Øú5"ÿ»s‚õÇÐÐ1û¯¬j½T·ý€fÁ¼õ¦Þz£Zçk_,k`€m9×ô(œç´ºÜÜÐ®TË¦1å¬²×QFÁW+ÁÇ…»D»|¹ˆûQA®ãfKKW¯gr²,X|.…­Œ'ª!d¼€?ŒGhîÈ±Á·­Il˜†g•6âÂ‹ã½ÃÓ:'ÛBZ¥\Ã²mèÇÝ¡y…øœ3QÁ°Œ Ë´Ÿ>.÷SÑVãto—üaLY.ÔÝ¿Þ¹«L®9 "@LÖÊŒÕWk:žÖ„ÖîMÅÔçÀy2+Êºˆ¾o˜Áî´OÚ×­{˜Ìjßš%’æb'bÏŸŽ9ž—&K°JV¥®½÷úâ= þÒÖ„­ÄD{0&¾yïMëÍ*üwíŽ¢yo¥õf£uwÍ	¤tìJfÅË¹]¦º ]g‡`ëXóY-ÂjyƒùMyü–†ŽÙ,3u·~WÁÿ­i-é¯ItIL#N
;T	Ý›Óãkü&È…ø=bÿSã1Ò	ÔæÌ• 13ÞKÓ‰J1ÞÈÀ÷1Òß7…œ·’ÌÊð'_0[1àtU!‡J¢€â¬RÙydU´Ãã-õ“ù³Ñ€ót–õ"/Dd@tSTÛßÆwÈ£{õ®ˆqPàê*ýñ/ŽŠÓK“iœÌ6Ê)!òïPZJ÷Ç›ä;UŸ}w¢6âØnëè€È²‰‡‡çÈºqyŽŽ©¬4O—Í§¨²ÂöŸ£€œCõš°Í«ÈT€`# Éz"ˆŸœ/%ãùHÖê¬úH³’Qù'ÐÃF=Zo“t×|<&šJWÛzÍ·	PÓ¿þU2_ÍÅ—Š¡øQêf8³	"Ã^õæÊ¹˜„(~§ž¼†öÀÃ†\áªà46€ýÇ´ç í¶ßÂî¹{¦m[¾åÚU<]h•æëñ[€¢Uj_$J¨Õ–x/9n=–ËÅ‡þptƒw¼2}­~'[gÃ“pÕ <0}ëœa
”Ö…Ý-ÑˆO]JJÚ±üËlwç£'*ƒgœðÆÅ8Ìo5g®n+Oš‘‡p€2TÌQ­"WoèÖ$aù}vœ¦SW¬o"KÄ¹ûÓO[g£0y»õóÏw×J ³|ÙïöÚ…¹æ½'½Ñ¬=Í`ƒ@ßÅÚ{¢n q“µ³»­7µú›Z«¢u÷Ü¶hÁ·5ßÏ9ísŠ s¡%2œÝ;´ë›‚-¢a/\ºƒA¾íÃýý6šEÄz´{pÝbPQÎU£a¢Ó$ãàFY27Ê:­š.æY¸íp ¨xlx¨îñ8µ°NwÂ+	P¸û/ßÌî®5ÒM”o‰
;AÔˆTíMRn©žTœKçSz£â?C?•I-‹'98fT EŒÎÜñ›ðÛ&'1tÎQòO!	•fÐT!¢:Éé¼BöêÜô¨ˆ3ˆX‘Ô¤²	%ÅÀÓð½¹œ­žˆC×¸;Q(CBHîƒ”òâ.ß4òìZ}JLs%üXàôu?U›éøDªïU|nõ§J·€û)„',äñSE2QnŽù¬‡&ÃHW0¦$Î‡QnJuÌÉGKvýô2©ƒH®ÏyÎŒÏÌ8Ê¡g1•i9SsiEŠ96k²çßbæ’Îÿa5æ7ÉÿÙ¼¿þÉÿÙ¼ÿæÿl>øšÿó«|¾æÿÈ€Kù?æDücäÿˆâkþÏ×üŸOõ5ÿç‹çÿ 9Æÿrooùðy
zSžòÙ>A[ç_:£Çn@ °çfñ:ŠÞæH,ÞFÑ$€S:Ay÷q­ÑÐ/Û¯l[õlžMMºn~¥Ô¤©úÑð¿Q’’ÉªQí½½yù:fÚæã)…Gí®»ÛÇýÎÁI{ÏBÅç}«~xÝéü¥káÚ³véž5•Žú&
Ò€~0îgfXÔOÛÛyyt£ì¤â°tvƒøšô»¾ŸäÓò‘¾æ }ÍAú}eÁ|ÍAâÏ×$¢‚_s¾æ }ÍAúšƒô5ékÒ×¤¯9H_s¾æ }ÍAúšƒôûÌAšn½ÝŠ·Æ[ƒ­Î—ÈAš®)vTæè¼]Sä¨þõ×È_¢Œ#¶§þJG¡‘ ‡#¾Ê™Äa\äy*:oÂÑþª¯ÀÀß®wÖÐ¢m|ÍÔùš©ó5Sç¿o¦Ž“q“L‰÷–·(·DB\˜I‚ã&*o	`Š*á}ªÎW‡û{jzEüŽgÃc³Qªjw’bþt^Ÿ¢ßéàÐ±†¿þpoÇþ°ºòÞ6¼n&ˆOÅ¹Óí òq§§Ð)¼¤¼·Ô7h| 1¢°»Xô²BÅËþ&í”æŒÛDõæòÀv|½ÆÄ ÛžeçÒ"ÝdJ¿}ÎV¡ÐºcrüR¶æ¥3}ZÊ–¬Ä‹¤­uýšŒ4/ÉºŽ)ÉÊ†&É¶Ðv¹˜òq©H.¬›¤"9íožŠä¼äºK©HKÇRŠT}i*’ ±Ž”2m+³œ>>û¨,wÚ³Œg(„Ñõñ†’¨ïP`«[Ì]ÿV‰®ÒŽ”ÁØ1/KÍqH=,øíu‰Í»rÈZØ”…‰92Þª¤CQo%Ù2Zz¸Æ#pƒ¥¸É¨WÞûcq½9næK±U9!ÍÏc)½±4óÅÏzqOvm§É >¯ K·¥WxÓN4Q»€ªqô÷ÞÅà&Üró‘¸‡æôüïL!·žÍYL§ËÊ¢âRºíç7¯^2}«ÆËyw1U­YñÕÛ_4¼%œ—Ì±ÂÄTƒøö`í·YÁÅ‰V U8‡}~®ÕÒ<+gÇ$ËJà²¬nža5_HzZIí>*‘êó“¨>:ê×HžºYâ”¬ß''NÝ<ijž½b*7u^^Ta/Û³iŠ1ï½š‘²$Øw7Ç ÅdØ\²®QHcÅNV³¡‚Zõ	›{,÷Ù\©âF}i…ÙÓöÊ{žU#«&WˆÞ«™ËvºS¤3@ÙU4R–Ç]t!ÓÁí›olû˜D6Ýí'²­ÿJ‰l_?Ÿôñ®âþB},Îÿûö›ÿ÷ÝÌÿ»ÿàÁæ×ü¿_ãó5ÿO\Ìÿãñ»Îýc›ÕJÀˆ~mÏ)Øø¾fþ¾² %cÊ.ì«0‹1äêã3¦R—kB‘Mî‚¯Š;wa:(×‘jÞfØn)ýOl‹{ó•{õ•Ø§Ð–ˆ:ZýVA'85´/t_œv_ow~Zÿùº¶VSÔä²ª(ü	§÷,OG³iÄöMÙö¹WÍ”ô°ì‹½äÁNçYûå^t»ÃPÈ?ÈY„5º¸æµ‰ÎiÄÒ•ßÊs6J;Ç'ì4íîŸî‚JáõÛOñ°úAsÙnï¹­Fi½OsÚ<2ÀâœVè“åVÑ´7·*MºÏó¹­N:ûG{í“NWÚN£ñ„?ìGÇ‡;/·OÜYL²´?ëM¨ì¯Åà'i2_n Ê57š@OJŸí¿^Ð˜í4Ç2Öì>\còÚzÐDƒN-(ÄÁ=6ÆS@Îo@gX°×óÖ›p}í"¥Ób"NëåÃù¶Õp‚²®oÔ¼bjÎ›ë±K]ÌkK{ìF†-Y˜ZX_¢î„v6ÀF(BaÇØ'é¦20» /Ä´Èâ#ÃÒ|ÞoÕÓ‰Ô1]µ]ˆÈÀÎ®åêj[
f‹æÒæt±±çãì˜×(vÀ>Ð¼»NCw…1Îá±y`—Š³µkü8Î{W/`Ífé™À´Œ³†#+ü¥-ÐAìÕÃC{ÚõR¸EÚY ìÍÇ¾åe9ð2ÉõÁû„–ÁûÏ¯ Óþfè³=Ä¨àªý°TÍžRüVÚc§ã¹ôFU “ît}Êh;ÔO>·Sæ:ÿ¹ýª­»4dg¿„!/-RŽ‚cY¿çû”“?Y¢ð[ÑMÃ©†ƒ3Ñf‹Ï–â‚[ŒBžN¯Jå^'''?¢#EfÍ)ÝzîQKbR–£wQoFCh	‰4/’€…±ã«ò'Ù*ç‘Ï”$–ÛBäÙœ÷)0Z);³ÛŽŒöÆT•ˆófN&/‹¦³,QÂDÌÍAB-ND{3Ró£ÄTHL†gT=³zgHÇ¦&e€’ZóñèJ³6Î-ÇäsÔ q–OÜJ¡çì2–”E=žê0MA-ŒÔŒœHM¤¥ÑíWSxŒÿ\;±UÇkU6<,á7v¢ã±DÄl}fzkåI0X˜cþˆ1Xqù2¢‰Ã<jUÔë7”j´Ð}íÂÐ1”-™u¬LGýÈ±,a‡Âë‹ÌácÉŸr™¦¾é	$×ª$r\«
QšxSå$˜.'p!¾f8:	n.>e®Óœ˜/lñ•
33	Ì2cÉ³yªWƒt¥•FÝGæïixf†è`¶Ñ³8à2ÝìéŒe8á«i7Ù1êÑ]PÏmØ ÙQžrZTž¦PúVbL]Ù_CñêV–`ü5¨bCåíqiøšpÐ³;Æb”†SÔæGt/Ë.L¯%YZò¹¹aº3@‰å6ã2‘{fþ™‘ãÒ+Å¿ZUØ†»Íý!‡ŠÆ“é•:Wˆê-ËÜÃ…ÅTD/BÚàvb­òªX4wZ	ƒ‚ÂäÊ‡¡I-t5ˆ[k¯UÑ<ô9QígË‚Ù› >7ºÝÁ1`ê"ø¹cü4ëkÇ2#¿ƒ;%LÑTÍqÞW"Œ«~^1áé^WjSxºÌÄä[ÁÀ9ØW‘YQÀ»Æ¹yøöñ¸ö©xvÛ8Fø¥¥Œ[ÏFpeÇ0Ÿú;	ëŒ2@‘bÍÃ¿;^Ø­†REmiå÷Ú8Èjìöðoˆx8â~Xïš£€sGZm÷”+¬è0ÌAm ¦bj8`à½I¨3+±Q5ýŠÁ,˜ž
`±ÆûÉ…îøê³ZÅ–]ˆ×nˆÃççmþ.Ëã™Ú)R"Qíï‹îÊ_0-¿/5´ÜpDD8(S‹oÓÅ†{RnÏdxg÷øT×]Ißz]æg!pºï­´dOÛàQ‹5ù‡«Ï—ãöÞÿõ_-¿ÓÏ´{Ž©$ú0µacÑwºÎMF)#ìÃÆüšÃCÛèGOðÝxt{tÅÄ®åQkä ¶%ÓšfNðV_Idœˆ Ž‚g^O³°7ŠNÉ’[„[°­×€"2;5Éi 2;þ<œw»¥ÀÔÀ£Ú*…)V¾ð‡»ºbWy­ô&ï•òÞ?äÉÒÛÊéÐšŸçô×eŠ!í¹ËëžÉ¢ŒÆ ÷vÚGêÉ±r†‚i*E™›švý¶Òô´ÛÝ+5o£§·º9J/G“Q,ÞyM¿pÜ9úˆsý«ÌôFGØÕøÛÀÒQ¤”;Ùjµä"‘-êõÔ|\ß‹““#åæM›v+›Ú©èÐÈ[9Wd*ÿ< æã³ËÙ¤Ì*].)ì4hËƒÍ_½efÉ+…ÛÍéCxÎii¥t.¯³è¦	žìZq­½‘©FùYékÕ§æ+só,ñsG›Òaâd<#í5mì9oÐ÷‘EèV¢P§œÄƒ5Ü§Úô!æ~:°ûk.wôÜZŸ
òÛù ?ÎS¦¡T&?Bç¶ŸÏôà1%Q}?ìuk%^P›®
@Qu8Ø“,N¦u÷›ÆÃ\}ÓØØÄÿ~K>Àÿæ¨–g$æFáuê7œÚÊê/iœœž]©4Bä¸–IÌß„È×kTøÄgÌŽzkÏå—¢bÎn¾WERv.°öÍ¹lé+Bán™˜iá…TÃtHŒ}`-–cÜ<¶»²Êï­N@‹êƒŠÌ!ãG|ºîÂ/þÞâ‡~J³ófŠn£¼™GÙE”5)ÒÈTdëÒÃsÞnô0OÅ™ãµZ³Qøå—ˆaÓØïÎ&wÑïýOñÚç
#·°*IÞÈGá¤ÿ»›w5õ¹µy_Žòßn¿KÞò¤
Î‰wÒ]¥§$¸˜ÓŽe)óIÊNQG°ZžÌ-Ÿû=Ï]ÒÚ¯lø<¨‘-Pñ]®š#‘òçNû‡›‚óÀ8™UŽ57‰Ê2ñ±þË7¸Ë  ¥©(~|#´”›Ð‹÷¿©ŽFšµ£w¨(ÅÓÑ™M—Ê9[…:çkiF9›_s&å<.A)ÌGÍ›Í¥Z'¯ÖÇðÿBB›TnH4XÛøý“.ü1Á­Ya(•;Y¶GmQúãi7èi$ên‹,d¶ œ®q&	‰­zë¯+­É]=£ôóFopÞ@ïQ”ÐíŸ¢ sÃÓ]tÏ¥>¥ìï¥4ßfo¢-y=v¿p—Ç#£M ™µïÈ%©ÒQšn)Œ›#Ó¯DùœoNù®ÒYÆ¹yÊwGÓ>ºzÿ°I+y•—³\(}‡BÔ´W©HGÝCá¨M ²>€£:í¥%´Ù¸ÿýŸªÛ0¥Û~{ÿÛ9m	sÞë?¡í÷òà~:…ÿ<Xq¿mÙp<Çj\x«hˆ,™î
m]Kd¥ÁÕi_4ºÎ±¸:o­®%“ë—YÅ/ÍEg¬ôv*†®'åŸéhb,ÎoË*-Ç×HëU†•	Ø\ó•&¢—½"~®Q}Þ²¡ZˆkÄªÖ*¼Øê½ySxÄë-ƒŸ[æmœÚZñ—¥æÎm¹ÄÍHöûÅ™pÍŠJ@ö½[ñ“'óÆ\¦Ö_PLLNMiü
I1‰2Ž1ø÷[Ëö¢ä|:d£ÑÆúuð‡àwÔoXÊgYTÇZÂ¢ôFô†‰–Öëš0y„px3Ä=p1Úõÿ {~ü˜ºÅÊUÓ¦]àÄÓly†ðü1—™¡4€YœØõhâHOÕÚÿ+lü}½ñ§<ÄG¬\fÇôA±%8Q¾]~'ÇëN"§ù?ÿ3 `N|êÞO úç{þ#èªøº†Gêç—èä>žü¶ˆƒdÝür~™a4ªðÌxAÔDgh¹õooH†="8?	Z-Ð†`¶sðêÓs}° ½ìžîcîn¢Ïc@ÿy#i…×ö%ŸÙ—üç…—LÜ­óyìô~~sŠB®hŽÏÍ=OÓÜ{~ïØ¼Xæy¡½Že/NC?/4w³MÝæÎóê7t’Wñý¼q^»[~Ï›Êcß4QìÉápÞÎóò+¾È¾â?_ÐUá½ÓE»SÒØªÞ«˜rdUø<OESfäå¦ü¼êàöU°ñyUs*›Ãs¯¹KEô¥¯íQæŸFGì(¤š0]è+jb¥9Î°g¸´hàõMîÅ›a[’û®a“|qÙ7³{>W¢P«®,²æ€HýËPŸSr”óÁigf.ÛÚ¹ÀD• ° ¼ôUx:sß¦A½˜ R”1¹ÊD8‚lj¬f$fqòÑ—[Xó8ÄÐ‘›Ð„Z(:þìûr}rÕ°¶ˆi@•`K{[Dd…"/%YRhªRÞ{ùîìÏC^„ÈòYë|yÉewð·]FY
.¦š£b»±SÇ]£•Ä.z	D'jK’“*ˆNí½Ý¶¹¯ÚS4ŒB‚ óÕæ½µÇ«wkðjkÍ{­¬„‡)-t.ŒÕ;cåÃ*CY0k+­7›­»PÞË_[r&YK‡øËaû¿áZ<äµ
ÖÊ{šTÑ7ŽŸší…ú DÈž–…Xà¹Ä¿˜&£=øe—øŸáf z4¢:®·íüæj	»ÏðžÚ#¾±ñ‘®ïÁ“/4é¨F5ÎµñCƒp_ØJ, åm°AþÚ¼åu@*bêÚhf0çñ¦	€ÅdÜ—æZà<k©÷
ò ½:;É-)ŽFQf¾š\^½á†{³^º¥!m§ãqšñz¼âOù©AIzIíŽ£„ÇµšóÜ!?UÍëÎŠ….s¬šûÏ?b¾’TóioXWã(LrVÎ{À1b2…õ(¦˜Bðre¢ã<ÅkE‘xŒ°4™ZÍ¢þ¬ç½ì8»N"gôNþÒb]ÐŠ42¼¹!Ê8uæ ú
Ç~Ec†~Ÿéãïj…—´ZgÖËÝl.q²Z¬dµä,GÛ¯3'ÚV­Üÿ6¼µ¡4WÜí,…E^…}1Ë7ÚåÓãA´\Œ–gX&@®*ŸrÂ{	Í¦Ôå¬Õðç$MNjñ,Í.Ã¬/{¶óô8pãpù4ÆZô£Ã»ÜáÝ¡œÙŸÄÙ
oçgN·å…+¬ƒÛØG¹$ôšL³På#¬GyLá¨ÜÏ{ÈÖ†Ï8…1h¼¸Í+önñš1÷J8í½a"«¾S úÏY”c¡z/U)zât.‰Æ:™õÖÐœ–D—žœ=ïº¦C)~Ú=9¾I(§7Ô¹æ+%-¾w;¹voN+…º.y¡:¤uÉK÷/iö’×
q¸â]òÒÃa²K^½õpØF bzQË'*.M±¨ysL†»Îsù}J˜Ü¢ŽKºó;ž“qüÉS©º)‚\Ø@{•ýÊÅg£‹tž·ÌýA|fæ­©D:cÓ¦"•º[YÕÂ_mÅÿ©ŽJs.‚uœØóœàóîó\áÅç>&9ÜÏ©¢³xO[•ø~Ç+ÉP¶ëÂ_‘Ó?ªª•7ü6ÆÀpåz¬óiFmÈCåÞ6f•Ü¹@eª\a%'%‡µo9aí[^Xû–µRâßE2Š7÷«^ªöoªšpÈ
V„^ÌwTîÁã;l©«P|EöÉW-tm+:Í½ ¤ìˆõ*$åÕƒPæÒ¿j‹ªˆ‘˜£m—¤¨ËÉÜ>Z2iø·p,?gë7?·H­¬ýrˆŠ!œøãNûDß†KUR9ÂHJTz×¡à¥›Á|ì¸6)Èð³îÀ»~ÝÁVSúi¨b©½¼Ôâ	|Ú»XU÷“^Ä¢½¥uå‹¯i¹ŒQ³€(ÚÎ~ã%f¼5³~ø åÃôú¿Q¶4?ÿè'x•‘^djŸÝ¦^WçkÒÊÜ$­[}òÊü¶û¾¬æ*Îì†@ýb¨Þc-Áàct´RMÂ¥%ÚLÙè­¹Ãgq²åÏiË-)¿ëŠ§ÛÝú€oo°å<µß|u±rêN»µìÈu-¡ýYD&­Ê³Œ§nÙÑb5jÒÂ2Ôn;Œ;–bÂÏMÖ²A››¢hîÄ;-xùt6Ø*TpþjÊ]Õ7  `²·wn¾%KZnçTª.É%Cû¾OAL8MGÝ*}f|»gç/Ê¿Ñœ¾›VŸ×;|gèGƒ+•Br@Ù)ëÆ8Ûk?ßo_¹¾ƒWWïÞñ@ô›¹c¸Ïm®wÓŽàwÑžÜxs¬Åƒ©|É.ùÊ{¬	}MêuGXãšV•¸¥»ó..’à¹×â08r«×¿õ5Jÿ°Ÿ~Úk}é>ßÿÅ÷eÉý_×¡áúÆÆÃo×ÿI=üÒÃÏÿðû¿pÿ÷v·;ÝÎëƒ.y{0gÿ7Ö<Ü¸_ØÿÍ‡ßm|½ÿí×ø¨ŠÏóƒ—êyç sÜÞSG/Ÿz(A‘R<–|^I¸ÞýºÚü“úó,‰Ô&lv€4¹ÊâóáT­n¯ÑCõ,‹"ÕMÓK¬ŠýïÃ¤l­:ðŽ^Sý u£ù ™fç­'ê\DÙiÄ9ÞL9Ž§h²œbœÁäŠDº>&¸Æg
 mÏ Š°¬Î!£ðæˆoS€ò3d`uí9ºƒ>c&ŽFéeÔoó¦KŸ£,
Ç —a«ÚhÕ(¦t¤ŽfgÐ›¾ëá† ¾FQF<Š¨ò5ÿ\4ÈõbàT¨>¾z'}
¢AðmÞÔÈ[¹ÜW†÷¼–ß`Ò	–äç—©øx?Êãs¼ oÖÁ„–ð2¼â,Mæ‰ Ü<Ô8è’ÄQRO¯Ðˆ‰wóMëÁtéŒãd%}Þ§óY˜…ð=*ö”zÄx‰þ¤ù‡X,æ<ÇÆ4µ¹8Šnt£+°œ]Cº€ ±r–$úkÊÝ‰ ÞŒ+µæd–<ÅÔ™YùG8–p2Å¨_`}s˜VæÝÀåÃ¬ˆÄwÂD\ú³+aH·âLg½Dð7„B«%óÏa
iJ˜ð£
ð‚åI¾Åáà
˜ñÔñ'œ_†—óQ@3–Dæ5ÇË^§Á$‹1uWøêÙúX£¼¥§p&Z@A:¸®
9'‘`i|jU¶/Fôc”‡¤ºŒóáZÝtTŠ4ÝKûÝGR]:´ôbpb¤ñÔyÛ8hlº‡×q·al=IÐnÐ8ízs@µ€{‹1AnŸÂu	g°v)ŸÏ_b@í‘½œv#‰x'YtA!Þˆâ æ
÷'Á0ùEg˜¿•Ÿèt’-ŸïdÖ­šD`§SÜxlˆ›ô¢lRèVUÈã³xOc¾Uî’»Juì> Ò÷ã¢äVŸá¤]DÀ#Bs¤•y†¾Ç“À]4‚|ÖÚK7äˆ«s,^@+B§["™ì“²P_F½X.”‰`2ÍyFx‹ Œ+/!V_N* 8ÞÜ@‡®®[êñj¬8m@3¨|èB˜-ˆ|+W9ñ* d‚¿b&´Nr=*¢@ˆÚ£½*ôâ@ÂéeŠ×Nò­`ucMáí©Ù”xó^\os³W7×`ÍD0~!a’ÃœÇïFÑ9âº9ñxa»uw\‹¨£ ŠÙu.]­gu—Í/Lòîêéý¥iÂ{@'3 XN ‰{ w"‹˜=ñÌ—\*Ð¨=êÒäŽÏ ý˜üS§é4‡=¶Ý¡4Î"Yï±ÜjÐYH‘½¥ŠÕ$"ÔyyX1ÑgÆ9_ž-wä„SY›>yä’(å£+â<Dw$1ü`ú£uëÒõ`ðK¯‚
#µày©.xÇ‡RFÏG6K‚ò4
‡_ˆû„[pÈÂ^ìz>¤&ã0™@|€CBéò”¨òtXlä™(>á? #0áp¢ŠQ€„1R€@ï/`’ì„Ã'*(3Ó2•_*Ó¥B@†s“XÒp†G"íõfy"©3Ãx1é’H@zîÏ€ãšÃ[HLâAOBäÿ’ñŠï¾EÖ>KpU'S4¸ù¤õ2bvg7Dç©È#J™O‡@"ÅšÇÒX$øšÂñÒCmRrÍÌ Q˜áÕHùìÍ(X1œVYd	¹ô“Fƒ¿÷)å„.ˆÞ¡¸Å£`r×-‘Ä”„^–• Ô`†»k#°c¯c]väUš[1¹)vªè„Ç	Ž¯®"Ð5ÙÆÅœÉ¯ˆë2#MeD2AÁ	þŒtK G”«¤­¥$ëÂaà4õ¦š”ù	gOØ0°²§‘£8Ó˜p‚ŽÎr÷	iÒ\(|?%öŒBÍ‹4æPcÚÜG$Í¸±‹z´B,Õ›‰Ó-Yq´”míaÆÃˆ–d®TÍ«¦H
,	à~Yr„{¦©Q ûƒS(D…îe¦õ0R€îƒŸq,FS$¾C–WâÞ]é5A¹Ã¡ã’p%ôÃ\C‰»1_:éïwUû`Ë!íìžìt±ñzSã„{¤÷k'©±xJû«OÑ}sŽæJáÈh•5¸9Àð»Æ(~‹7/\
]g‘:òu«€4›º@Áhã"ÍÐß”0kÆºGíe|Ó'™èIÖ°Sv)Î=z¥:!t&MX3ì÷aËs¾¡,·­jòB”×hKjV¨©ÁÈ®\ã]9Läz#Ö˜%›dJˆæÌ1Ô PõÃ	;üB	²øN€)KjæCNóA†‰$ÝJV8¨Ë
Sýf'$À¢— öX*JŸQÔ96 ÁÅ9ç£ÀJÈÀ&V“1(ÄZ¯"iþªi÷H:v[Ñb´U­—,hƒÏj²Q,†Ó•˜>e³ð=9J~6‹Œ§;<§ÐŽâ:÷	MHK`þH\!œÖõ}ê»z—D‰€°ŒŒ¾7@]G!jw€¯#v¡î'ÜÊ%„#úÔ£và0 ™~‡¼MßÅÇ6<ó&’Êqø+
âñçÒÐžÉ<€ófÀ	<:²J“púÚx—¨€‚'ˆa®7á=˜Ðign
£{*3Rh³Ÿ^°úGæ2ÌNÀ]DEtÇsŠg^¤3¢QÂŽA ò‹ZC»€•h ¬¥À*ì“ÌÀr…œúÆÙœÄ‘ñ¡,„†ñ Câ`êºb•š‚üšøÎÍP„i“¡„ãÇ[âgÛÏEÄÐÐ"]‹ˆF{Âü·jäõƒEŽ¼ˆNDÒc«»²y!÷˜Äš£ ¼Ù‘Ø5Êhà +7Jê¦g6W˜¾-º%Ô¿Ñ3‚)l«c²J‹…z¡¤«‚°‚î$ä…XDd’x@lÑ¦M`s"–¼ªƒàZÂ¬Ù
”T6`GÊcŒ‡–€ïŽ××û0Á{,I00w®Ñ$1)$N;=!²lyMÀ‰ÕYÙå‡A;H"‰À¨F)±H3ø5„M%¹mT=5Ï¯9úhMTe—±X€F!L¤Æœn—Î“}‹¥{XYÃ˜"S:<û%"
ŽàíÙBÙCî‹Õ@CðvQT³¾ÚÕ‹f_w’Ï#ä˜~õ4F9Œ…]„ oþQ2¤ôºsàyx˜4 •-í_¡õ¢®—’ÒÓ€Û›Žrç""^$:ö½Ù(4Ö¶1.Ã¤¿YxŽÆ„‡ õmtÅÂX8NñZJ«·ã´‰²
yÑ ìuI½„:ËB$j5æŽB•­!gÔ°á­á­Ô
Q	Ô˜t¤«­†kl}¥·ûzØ ²?@çzoÃs&òûá/°Û@®ÒÄ˜Å²„TÉŠÐ5œætÆÏÖ•1FCËZLXED·%–²Ô/}@54±„¯ÊˆCÆƒ‰Â´ž”—Šb†Â¼ÄšqÐbÔ
£¨	Úà‘K¡ÓwS^ÂáÀ¦(«‘bFž^
Vß‚–Ä'}L¤=æ¥ñ8žQÁóz
Ñ%$&Ì¬${½†™'È„ÛÇ
Ðïó:Ë%Ø}<Š2­ˆZiöÜN‘=¶|Ú€Lí{SÛlC·½j¬Lh<rû0	©d‘F£ `sJ]Íª®-‚<§+‘é5Bs;#›lªMMvªŒð´ž@+'¤8ä¯HG¢òY¹¶þEz‰ZkÙ¡	qÖgNƒ½›ÅãJ‹ZT2§iÊB¸ü 'À""¹'´QYãn&Úœ#tÂªNàb’É¾0d<•}Ù?–<ÚfÁÒZµaýŽ aô4®®jhÚCŽÞçã*»É?ŠÅ^–]jŽ{’ðRY6öÒ]%á˜ïŠðæW¤Û³3³4¦ºšÖôa¡u­`b¶«š¢7å˜.æ§t8Æ³D+±¤î2*Ð¶p"^HÇæwŽ-”º,fyõ©ZW6ñ»8dÄ~mÊÍr2¨e‘-êæÞž-ÚX¹o¯»€»[<ÿ¨éÛg€ £eÜÎl³‰Å€2…„ÕÈ6è…bl>'/^¿B€"¤Ô?k!mÈmJ†è#mà'{0J0‹‹”•-Ë1^¡u¨8¶ºJ9šj“¤îß©?‚Ô€F2“Ï’Q<Ž†oÃÖ´¥¬õ‰r
JÈï¼+Ð8!f¸:$)¬òýìÊ_â‚’eÃêê„x¤´9Ñ%byd‹§³©Èâxq~À°“ô”ãóˆgh7Ñ ”ó˜}Z(iáù¸GÌŸs»¤gW¾NHLþ“ÇdÇ…M€•ZoXŽT[ô%²pmôY×Ì”ãý¦¸l²Úçí^OfI´1 ÒORF„öBç©ñ	ŽÑ½SB‡Ñ”9/øÐÑ&Î—eA£Ír6Ê!QtY!v%"ÍÊ¨}\¶«'–,‹áÈÁTísžŒve€è•ÅE•YÑ#³Ò­,fùL8¯p J!‘.³s„lÄœåÆÆâ²°iL•]SdÒ÷VŽmÐY4GƒºœozÄ6X»@lˆ8”:dš›Fƒ÷˜ŒVðÙFÆþ=ög›iD};qÀí’@ŸÕŠýÆfAð&áê¶Y71v?{/Îz³±®…åEŠ Ž ÄŽo¼8G‰ÀÀÌÑÊ©T—ÄEØ%â½xGhƒ!v²±NFÞe‡–™-»8ÀûM¤#Úïñ’ý¬”ó}†ËÓnÕØ¦!£¡îÉq<H½ÍCV
(r†|dÝ¾aû(1i3lFo˜¤£ô™	è–!¹1í9F!8öj07ÞÀ„ÏåtH{T†@ÛØÐ,èõîÑ¡C8¦hÜ˜}Pk9$ys]íÀ2ŒÏàõ?ýé[<SA„U*2ÄjÑ¨*&}²$zË ¾=‡ÜF<ð#ªàÓJö_†¸8YñYÂ¦‘FÈ)vã­™Òý)ßdB†÷*ê€¼ðLPAlÍz1!Œä
öHHl<åiP<¢Ì
Å1Þ¡gBA4SaYÄÈ´â@RoªwÕ,ÒY&‡ÇQ‚Ô•”H é(|»".É&u>îìSÍËàÔÞ•Å”™™Õ,mZP½š´{šÎ¹}¥ã³¶Ù ær ÙÝB—ž˜ðç»¹'Ò0s	´™C@Ðb‹‡%ž«Ét’O@ág§,ù‡­Ý5Hò!bv„öz‰3[hìzPÂ%ìZ¹Cv“IŒ}¡‰ï‰Ð‚¢Å“ã³é‹þö¨Š‹âB‚¾³NF¥þ‚Èú…g ¹ö"¦WÆæöˆ†qN‡Ô7'|¢Ú­RmÍ.ZÃÍFrtvC±FŠjAÉßÈŒì²º›‚‚D Âáø„|6¡¬dŽÚPhƒlLá¡‹lûZ¶Éø•ëh/`ké/	ª"mcFçŽERô^Û‹6Š¹X«IDAoíƒ*Œ7W$nÚÐÜed[ì¡×Hxe«2û,Ø•cd¬DJå£oQˆÅ®# !°]`ˆÖÖoàÙ'õEÞvzßÅU©|2\NÍçÛÊZ˜ï´¨,Z!ÙŽd6lôt@…H/4n B¨Í985™hoÍÆi–X¿ÌhÂŽ%ÎñüáûzRì3D["´CY‘Õp8ižG¹Ž$­¬ €"L¦:(I@Ý=Vo¨ãFŸ—È3!]]SµË>D1“(JÒFë²eçaÖaÜ	ÊÚÄtÅ&x2)R@•§¸ aA9ŠÞ÷u0w-µ¶êN†Wâ³·FÎT.òÆ±¨—Q¤FáóDÏu°—6s)Õ_Óu9©c¼¢~¾«VŠèÕØ)NPæ:^áÚˆ}Éc^ÅždBÆ2-a	|‹TEÛólA³06R|Hçð¶Ã³ÁÐÈ
¾ÅøÃ+¯WN¼pý/+D;§è=¾ŠT_”Úv‘àäÅy‚ÑwìŒ¬úÚCªÍ:,nŒÑ³‚üÄXçë¨0¢²‹®é‹t4ãâ»!Pš4$Äß<w¤sÔÂósDhôÛÆz¤v‰hòÓÜñR[–/#´	•E3b²•ð§´ÿ®„'g\’PW‚Ò~}QzY‘A×SB*[Õö‘—þ§gdmš½Ã#‰tÈ•¬ïÓÊ
áÎ·.O= aEØé3Øœ9¼Ô7”TŒdbX˜eÆÅ8—:½1LÀBÍ«´ˆ:+Š4ŒOId+‡¥n›þ
Æt@ínC²9ô†W9ÉÀæE@V­}ÚiQ£ku’÷Æ“0‰µ]‰©Dµ©/~ÇÒJ¨ú³Œíg:dF9’=@8K6Z«Ây–µÿ¦s™¨e¨¿',ÖQ}–ö€ƒè€çã¯®¢0cÓ­Ó„9§cÒÂä„¹UÆ!Ö¼2ŽÉ†%6j˜©€8îôaˆ’©¹¸°n‘4Ü•O&äò&az‘Ý–9¼»9dD"GÍ5>Ö«ñ'B~s|¨k)IîÂÅÇ)GˆÕŽ^ž&pÂpÝ'êR®OCäký2b1a†$Û°VQa?ŠÜ¡Ž°`$aG’Š
b%8Ág‡ºúÚ¥»uÑálX%BòB¬V•te¸p„¡¬\9ÎµQ‰Åi¯æ$™±:Š.uô` a#,QGE(Ú®ì†°WŸy¨9<Fä™p‹3- ~{få¢9ÿL´1:Î¼G²üì™!;=aéJ«Å˜}Þ5-y­•ÚÙõ….{.BdfB—é!wNÀõ„f[˜Q9I/eà&xWÐ€ejšzï<Ñ04HŸ”æ%Ü­ÏE%>xùÇÇ;Æ5äÚN„ö«lbz@ô—ÝZs®¸Z!v¹»ÈåX¾þË
9ªH1k]¨o­Ã7ünj
g–yHP9Ôº˜]†sW·‰¥k]5ƒ$#™ä0Í9¯cîëu98ZmÜd!h£	c²Z¨ã¨%¶aX†õ[çˆÉìmÎ=m2—SÍ=53²N¢(kLÓþËá_&äO¯0ÁÁ‘Ç	ÛØQP	¯]…'Ü÷"ÁPÏ/ŸELmÄ0d›Ä[­c$ì©óèÚ™è‹*Áq@#ÇøèõtR¸fX<08ac/©>bx8<ç;PAspÏŒ#»ï{SJ¤Ð	CBc<êaÈCk4‡CSì`>³’AM´¢c"‚)æŠÒ¬a[H‘FÍ,‚³åÌ`¤ËWucà¥á8nÓˆ†)ü>Ä;¸Äy•[¨=ÇÆåMÌyÔ—Ô â°ê!Û¢
Cïc$†¢’`®î”sG“ôKØŸ7ÙzÐOggÓÁŒËyçÖë [“Ž.xáEJa‹$y„ç:ÛÆ ÒÙ–=Q¬–b…jO]Õ¼…òâªƒéÕ„dÅ”£èðúCF„5ÞGaž;)õ‚YBûg&·¡Ð¹âIÐ	)½ÂÜš˜£GÉ[½C#>q6Bç	{`à”fÂQv40Œ02bdå²F®7ËA'$°r2õþ¥i^*.€.ðpg	&Y Ÿ@®H’&ÇÈ¨Éf³Hõ
é¹P$ü.Çí°‚¼K”ŠþÖáAîs"Ç0­´Ÿ×7zQuÉ“ˆuõ6ºâåeÂ[ØšàöT'2"p¼PT‘¶U¶nèx<o€H‚°ô>ç„æó%ºÈZ…‚|†¡ŠQ‘Íˆ³q'3$RS]_kPÆ#ND+ÐTRS]”T&l*âyqh¹6Ï"Ró}bÎ†¹ŒC	ÝxN´¤D*]S¬&ú¢ñawìÖs£r’MËj »º66È‘ö9st3ãÄdvê®œ“(#×:j“~HðvÃZ$²ÚáqF´“øªI4ÅÓ+#—¬AS¨Êj¥yÓanouÄÀS
8Ž‚JÆóöíÛzQÉ”x¹zoÀº¾šwÆ0&$×¢m,=dÓÁ2?‰06Üë$e°#bÅMJc§
{WîÙ*à¤$]³äí­8î™p3×˜Þ	@æÇ‡ûk&lÉ¿£GÍ›z9B/
 ô)sÁi•eG
G×Þ#Bh¾2—c#Ä÷CgÖ³™3Ù%ƒWuA¥ ´<›ãe@‘Q(´N â~?"³Èå0JJN($TÑh`)´;³´,â`(âVDî­ë˜©îÆr§#JÄ£ÉÍ¤Våp¦=Œn3¶Qua/KóÜ$!ÎS…¹û¬¥a2È¹~ÏÊÃÃ™Iô²±‰°,ç@—ù€•£‚âQ…˜áùÃA1pNtWê]kŽ@¤u® )ÛÜŒpb– [„ïh ”àÑ´hµ¾kb½jí—9‰´Aµæ<µLË"7ôq\â¥KæMv†8+ñ8œQÁI€o˜Dœô“EšíY—[3¨÷ŠJ|M:l‚}bÚÝAb$PŽá$7›nb3'Ó¸Áê®!Ë‹Å0¹àìpb[_)ç	£ÚˆÓ…•cØò­£ÔÝZã·•tÏlªO ‰òÖŸh‚Žê›ÝU« +•œ£HÂéA)<ƒç˜éiWÏ`n@«ªBcp¡ÔàT”€n‹a}u7ÚŸN%E	É|Ð©ÏË[bu–Èâi«™ÛQz)Ã€÷P‰“š¬\ê	"½›kÖÙ@&–`Îð‘NQ¬‹ïXì"¤1ù>)?îŽÜ‡ºÔÙ{+ã>lo·5Åm¤Lú¦òè|ì¢ß‹Êè 8ŒcÁ«ÀË4»HY"8[fdÇ„eDÕø´hØk	…¦D?YçÇŽ$‘6©Ã/Ð¿…>/J“‰µalR:œYjŠA¹ÚxHÄtãÛâ¡Œ©Ç&Ý”Ô–ìÂ°/›Âã˜ŸÙåfÂ^Ø5ÊËe*2PïZ°ñ‡™¶-–¼­D<®Ú'ËKÏî9”<BV¶ã©}o¿‰yL1º—Çƒa'ÏãÄ(·geø6ãvN
]ÁÌÅ­[³B—”¶—;ÖCc†á„¦ü’J6G6[Î¤³JÜxmÃÀÁà­hô»÷©Ö…»FG×¶EkF8âÅDg"[!ª.e§ÇqŒ¢~a,¸†-xuÛœ•K‘i}rÛïÀÅ4tx/¬ÎÎÄ)`¢·L,³zñ¯ü¤Î¹7]µª³lÛ(‘7kúr8¬µEÖª0¶MÃq¤ö‚0:Ðk\¹í„srÈP%\“lRJìb.Æ/•`²˜Ê‚ØŠÑ&Ä³Ñ<òÒµš˜æ
JâÎ]N"Ú´ÈDÞZ»f®~ `Ÿb—DéÑÜ=æP{ÖzB!UaIƒVóbÞBVµÀªŠ‰X‚-|–7 ¢¬3”MJÕèÌøP9 I²à@ ÔþlŒ2§¶x1Ñ®èçðÿ*Æb‘ÒŸ¹ã”wóiÚy¾gß¨5êmÃžÏàà]HÀÎ¼ñ»6
.‹¹¥A/Ðh¾—…BéÀá™ 67™©N!#°´bT(!®_C‚„¼Nª£ z{„QAÉÙá	ÊFÆo—²œó“OT]T².Ža›rë<i™kd<Â™~-Ì%àQÀ6 DQ×¯!Ó;0ï÷MRPâ„ínÜå£™Œ[ª°s’ÐMc@f˜ƒ0m0©HEµPtâÅ¥NÞ+ù¦·ÀTžÂ‰U\XU£x9?Ëj*ˆ¼*Z:5À9ñnô‘
7‹©P[XÐ°Âo“¡G¶6ØôñÂ	
#áî!¢’‡¤~WŠˆS‘„³ÀÔŒd¿«cª.
€ŠlDd_`x-0B(;”Å2L5PVF•r¤—U•ôƒü±‹è'öØ\`ÄÚËÔml• ø 4o:Þx€â³ä¶v9¨fÐ8re²+cCNþv]õIªLe'(Ã è>è¶)­º—„t£EœEtæTš’~ƒfG¹3—`ù\ê¼ã1Ë	ƒ8ÃÈ–xÙz~†¹	­Ðs1FçÓ²|ºfõ¸ 8\›tÐ›‰ƒÑB5ë{ß]ß@">`8£8ó Ø¸géþZ:c¾!Ç˜õì©Ä3‡¿R‘¥)ÒËÌRèðÓMgS>ÍMÍWLc‚E9Ów_B/¦îV;PwÒÞÔ‚üDzij*„àÍ^V•.ëE/£4ƒkö§&Yÿ&r ?Ö„ò‚3Ú
é:vÒuŽpí2(P²Ïá*z @0)ËÏ‹H²Ùí¤t3äPnS-¥rHÖ|™Åj^+&™Kà3,o""o°C›B³JN7Šä-õJ¹ÈH©ùDúáÇU„cÎi˜‘db³æÈwœ³¯+Zr¶^Å&ø•äÐgjìpê!/r)Á´.$WÃ²kP:÷\nHÂ}QRnkÎ'MD˜ÞI/£±|1 š|¡—¨8•¡<sr­|¯ŠÇ]5Ê·¬_e¢.‰¸u#-°ÅYv…½PŸùŒ]$yëŸ©N:"±È¦=q^fÌw'º¾¢,F†tkŒµUC+*OÖÿSc‰ßõŸ÷Ã©š\ðÊ-ÉÅ"˜WÖù>–êä¨[PuŠPcÁ£ceçŒ9n½/¢oóŽk 5ˆ1ŽYGm%ª<;	sg'Ñ”‹\î\‘;[ì’Ž4Áà\Ó ãvðˆZz®óØ×ÂÎö«»T‘±OY”l†!''h@¤û¬ `]=²ÄYqËÏ4ˆÏ£ŽK²‹ysuîºÎŠ3Añw
êŸ
KÊŸaõÑ`€!W%±Yôm¤<*T®=o’fh|Ÿ…”|dù”÷>OöJCˆR¸ýÛ‹Õu³ô*‰§,uBè8{ËŽ¥8Žyµ•®Ücµ	<áfÆøxÁÂäXjp$ï?E¤Òwrú`JéM%è>;×J|àêÒØì¾õ‚Ô™+Yá¨™ºl¤rìáHê)ºI¬^nQ8ìÇ>IVÉÆFSé²–ºä\ÂVÇ4«éÀ›‚ÈˆgÊXt)' B/0i§0W-æÈVà¤46f<œ·YnkÚD¢ Ã„ÓèŽÚ”ß39$^K[Ç]vñR!}óÀx¢¾SÃñ§:€ë6hiÄõMÃž9°;ÈHYÔ×OëšS`ñ<r:;N7s	Š»&%<(‡LŠÈAæBÎ‘·XqQêZeD ÔžižêÜ!‘ã‰
€%}ö«Rz+úæ¸†Wš-æR—LG5[ðÍVhóªÔE¾cè41^46ÙåÔÄ¼z¦r5¸g‡Ó;í¨!,$»†)?€U³Q«jªÓàš9žÊí~	çà 
—´ ¸,ÜK9èíN§œ¸-ûÂU)ˆ$Ü»L|b°!Kgb¤7*«ÙYŸjþ$™H$WÚ<@ÓH¬Sì~§l“ü2HE}©³*•ŠÜ‘vKŽÓUSv.ÑK²°T)ÖïpQr"']Ö0»?·pkO®qYÛísÍr÷w‚Xº02¥æ:ÇªÏ™mi^5Üdv‚[åT_±Œ
Œš²G,ƒ'¥¡r–ÚÜàTW`ÐE"ü0br¦V:•	Æ¸IÝ_š’¤tl{è˜§“BÊƒaÒe€-)œ$¶&†`jªhuB_u‚Øœ¹ÂÐæˆÕ‘¥s¨ŠÎÀsV<"¬Ê:
¤ÈE	$c[- „)áîXaLå²Õû¦‡ºK‘‚P¤r©­KO#Wm2‘MÀŠ‡)"‹.\h,3âI1ÅyWwEÆ M ÔRRÅ	YJæm–y2–¿´Í…Æ‰ƒU¹•ÿ&s£°º¡1¦s›án)4-NÑ@ (“s'v”dFqtÙ 9uutæ³²Xl†i&‘W&™ëÈª>&Í´Í©à*È¤»aéLëZÐB4ázIu¦ôuòVÑ!Üèà(åµª€ŽÐLi!íkÆ¦F`8W]íÏÕ”JÚtR%tñ?Î&lFe1ù`q.›½âwÁ‚ÂÉSmJˆÀÚ..tUÃú#YL,%Í®jríg) ýt\ìfçDqdxÝT|É‹êËÖ¹-êeë-°d`Bx’‘^l’Ž:_iúJW‘9ðR‰%‡„W«#c²èiœ€N@¥øñ5¡)A¤6Ý‘ìdú 9!68	¯Æç”Z‡‚ôàU¥Ò4Ú¾*E¯80_ÈJ¡FŸÛ_6Ëfu]ÒÜjkxeJ¢ít¥Ó¡¯uJKrÑ§Hð©:i™*ø™xI3A´¼³Êñs1•öíó—úÇÇkÌ<Ð	ã GñLúU]›#jî`ÑC§içš&’w¶â ‹#Ç‘ Ï5A-YLb©¿&—¡ÑžëÖê¾ù½Ú3Ø-¼3MÇc]ZÖ1û™L*&—ÍŒOÔi'T‡d€ÄÈSMË :3WW\S€¶C—ÝÈIcvw=z¢RØjc³‰Å­ºæ#ØïC„˜ß¥›¹úéXËo…zl¢èK2µªõC*g7£Ê0ìÎpäG;Ø5%QløÐ{&,_wQår»Òõí`!‘Ýb¿Æ64ÿÝ¦?ùÚMh|Ÿ§RÞ@§–åñx6š†úžŽÔ+UæòLºDŠÎCKMÝ¾&ì¥d—wÍ?2@¼ÃŒŠŸMEš&âÒ’ÏúÄuvß]…².hôXBEëq$™L#ñ8gÞ3vX~PÅ”,¹®ŽmfÙèšd.ºðVÉ¨àähdxˆ9:SÇ¨ùÉcn5£ûMŒè¶R&ÞKÑF2]t=Å'²X"%y+	Kd”üšy7OH|jåµ‡¯$Œe´ÀÖå°µ^Ýâ…$7¦:™\ñn¾W‚uL
]‰È:®VÇZ—ÅýÌ®ÇÛ}ŠêE‡í9ÅüÖeT,"pF+ë"ñãœ]Åøò ©Ž#Øa÷«È½{©`Áešw!G¶J²L É[èatÆô´çÝXHçÝ98pø—
Â{pp~¡­Ëõa…¤IœÅ&›W¢Õ‹”%â}Ì(Ñ:|	ua.5b™—Ûñ3iô„µáÊ¨$< 6Í`ê¸/ºE2ÃÂ‚&ò+0Áåª¥ABÌ/ø]…µ

kU³.&AX«§¹×‘jàÛSJÃàHj²Ý96ž9WîˆÂ­ªô3B¾¢8	ÖPêáM`ñ¦gdv^'”výÕ¢Þ|²ác½aª½ÙŸÌø‚ªñ9x­Y»;ÂÒÆ¼»âáT3ˆ&ð•UÁEäßg¶ õ„îëx~}7cŠöå;Uí2¹!Ž^³;^‚®ßÐ:¿ËFöhCµ¸e&«z.67Z2ÍltnàÆý;ñCIê½á
q	³–% :­ˆp!É€©¸Q'hZ€ËˆÒ‹‡”Lì6Mh8£Òk	g÷¢sÜQ»]up¨^·Û'?ªg‡Çøƒ::>|~ÜÞ¯«“CúÞù“ÎÁ‰:êïïžœtvÔÓƒöÑÑÞîvûé^Gíµ_ãÍIÿ±Ý9:Q¯_tÔ!‚½Ûí¨îI_Ø=P¯wOvžÀíÃ£wŸ¿8	^îítŽé†ªôN/ª£öñÉn§‹ãxµ»ÓqÇ¤jí.»¦^ïž¼8|yb> ?ª¿ììÔUg— uþãè¸ÓíÂ  öî>Œ¸?îlï½Ü±ÔÕS€ppx¢övafÐìä°`oÒVCÇÁ üýÎñöøÚ~º»·ë…×j=Û=9€.híÚ<òí—{íãàèåñÑa·ÓT¼„ üx·û3…ý÷—mV`ì·¶;Ø—3ç ¶	§«~<|‰,æ½·ã-
.TGítžu¶Ov_uêØºé¾ÜïÈzwO hÐÞÛSmoûøGÕí¿ÚÝ¦u8îµwq•¶Êá£Ñ·M.7=µÌã 1¨ó
ñãåÁ®Äqçß_Â\K”%¿ýü¸CíàDðz†»gC1bÔéøÁ"Æ€b‡jÿpg÷n‹ ÎöáÁ«ÎÝÀ]Xg‹²í§‡¸0Oa »4®îÛN{¿ý¼Óu0ûä’íºêu¶wñøð`—ê sÅ­…Dµa"'ïcð"àFèŸ¹ƒ]µ}—‘RívƒöI[Ñˆáß§l}Ü9€…¢3ÖÞÞ~yç[à0šîK8»¼8_:â»Ç;>d„·ÏÚ»{/‹ˆ‡=Â"HB@g'¸Ew­àæ«ÝgÐÕöÙ6ååÕØŠ§hÖÞyµKÇQúAîÊšÀì‚¬#cßwM¾[¯Ä0Ø-%©¸Ì«ï=“ƒG"Ûð{Säƒ#mí~,øŒR,vÀÉ+\YXâ›…
O)]ŠC„	£K6€Î°„ëÿ, 
¤ðRtv,ÇÔ¥œ	Š‰-ïèŽ„<@›ÖYžŽ0ž
'³ø2z|œ±WØLÌ’z¹A6±À_›îÌÐRø™¢K‹ÛËºV| /iŸçÜ@h?/ø^§6-‡sèÐò‘å€°*È’ÜëCºÀ¥½•X‡3È•Óâ!‘yœSžcœ;ÿË,/ä–ÖÅ3’O¹†îÉ¢nÂ@Å/Oÿêl‡èºM4ò}þE¼úfUã_Òº±¾$bÄêTŠ1ÐŠ¯:uÊHþ:&p—ìÐy8À©áˆÍÛcÝ$*Î¶  "'ÌžïkÉ½1’¿ÄšéT5ô‹$!×ƒ’ì­«¿‘úS32M•e1‹¨IJJÛtõœÁÌÔv¥«lQ6äú—“Þ×5ÞœùßÍ)H@Ÿeq4@JhŠ‰¼ùDªi)ku{Mý€Õéž@"Õé{O¸ß¹¯U‡mxÛ½eî÷69žj}P\œ7TíQ\(%‡¹§_HÂÏ|¾®Õ˜’iÁÆQpúÑªŸnºVÖlšÕ`çiî®¢{A'é6Î’=l'W¥E}T‹kÈA´ÈöÈäÕb‚¥Ÿ–XqÚUQò‚Å'x)+xu#ÖÂ"=\»0XMÖU£Ðáâµ‰lö#ëæ–ºrN-2»–¬²cäC¤~N§“­Vëòò²yžÌšivÞÒá­'0 6†îaÒ[Ú‹ˆ0í$û7_=N5ïÑÎ—¥	VÂ»BÂ	F®ÀÜ\F9qõP‰²¹Æ–º¦rú²•×#›rFéWšecaØ)Õmäb§nÁ^,\#)«?H¿On|KxÈ¥™iMÛO»‡{/O:{?ºšÌ#ÚSÙN5½ýÝø~y·iÁÏ³eDË£öÃ†Iïx>Í&)ÚX¹ÝõîºÅGËÒðj‚æFr*s¡Á¼-ø§o«w3ý‚°sìJH1ŽmK3u×Á˜¶ +Yh½ö‘p÷ç/wmõc¹Æ4#[ƒªÀxq–¾«™¸I2Åšb¨%õÁ¹N¯0¢AìÕö}£_”­QLê·@8øº5òza$® ¦ÑÅÊx5ëÆ7eÝ±ÂŠ¹óã™ñ©û‡ovv®•d	ˆVm7Þ¼‡4XzHÙr¸€Ò“Gº¹ÅÂ€H¸ûÃ•Ã&ö^jýCîäJ8t9Ä ±,E?f$×z]I²—ý¥¼N<£´Lž)²ˆG‚†lÎã¶=Š«h*fH¹3G€k{Ÿ£K‹p)áxu·Ž[ÁÙÃ0°lžu£„¢°_á­Á’:”qƒÑÃ”Ž…!4•[1Æ J§“áUërxÕ€enŒÎ'£æp:ÁîüÓ?â§ŸöZÇöÎ~§9î¡>Ö××¿}ð@á¿ß}ûþ]ßäïðy°ùðÛïÔÆýÍ‡6<\øP­oÜ‡þI­¡ñxŸ²JžFÛA³Á`Áï<eþýùÜQ‡/wðâ·(8ÁËžû(‚!ÑVnuòj§¿w’‹ÿóÿüD-åRN2…Ò—$T™Û@ýè$Õ$J.bØOƒ„ôöˆïè;µÓ’Ï6B¾Ñ©¨Q{dÆ`¢Zæø"°€:dX×~Âéa'‡»;ÞhH	Ë8ˆ	ƒÐ=
N<i×)ëWº^,À1)Ú8cPôá†¹@ÍÕ“Ì“9m§OCàyÁlüÑbšf(ÞQt·¾#ðgèz§š”ª„nMá[˜½eÜÑËè­3Ë-Ýýº:no×©Ñó–•¡êEHóél0°þ¶81¥@½”2
Œ¤ÝœI º§‘æž„šKøÍ/3	Æ¼w/õaPÍ|xïž,K]ßæâó™¢’'Y±š%½!›!b¬Ó$nÇu	R`ÜÐ£+4KÆa 'Ž/æÔ«/ž—R/¨ÀŠ‹ÔBÎßçêuE,Â]Ð!7‡ÏÚMQ€u^5¼ ?Ù%
*±4ä]Ù‹“Ù;õjÿÿüßÿ/Œ
Ç¸“öÞ²…¹ˆƒQŽÃ|rá)G16å}£§1ˆ>†vÕêN³hÚRÿ®àƒù{©{[ÇAØ¥;w@A™Î&…í²q €>C
6m°ÑP—%³K§p7q9Nå'ÜÖ&Ö ÂäÈÊ_Yd0Ðµ—:ƒ³>Å¢~x¿` ûÛßpøAJë÷o në¿Zê'ø÷´×Ï£ŸUk¶¾Ñâ+E[åÎTcl®o|×ØØhlÜ?Ýx°µùýÖÃïúŽO¶ða6LT¼º*~ZµÞÜÂó í<;T[€ˆ¡µœU6fbÇaÝc¬»ºðå—9_']ÈOáÅÏðß3õÃ!Û½ÎéÓv·óägµž‚7bóÆîÌø`Û¼úScl~{q¸ï<
Ï_îÀ÷í¿¼<’Ç;Z2ŠÆ°ÒBGš³Z%¹kŒRóy´¶ÜÅ|pr¯4Þ†Þ7Tü–A+¬©Íy®v4¥iª}dqDtÂìœ*^4Y¥[ÐÕ²%dBuà¼ñ&@ßæÇesIõÎ&‚sÑÀœ‰¬ö£AˆÞ½ýëZsY}î] U]k º»˜k²^vÒCx-ð3ÖÐV}B€¢z¤ì`@¸\OrÜƒ±™FçM©î¨p¾l!Ú¼ ïV©©39âÉ(iôÇÐ•¿è¸^-úa­¶¬ÇŠs¹¤Ç³°÷v6É«úäŸ–ws§>õXØ)Ñ-ºg³¢[óãÒS^E–ÌV˜}5ÒµÆq¿?Šp×—öý%VúÓ)è^zN|rKµ¦ãI‰ÇÒsd’AàÎ”=§t+È]<R`õ÷éñ{ññ—~6á½ÆÙ½{B˜¸æ½ÄŒ°4ç,24³kÃ22¼Ý¯~ûrî{jU‹c›*ãá‹›Öð	›ÖàD;à Ò7ØºÂXE'¼^)ß ÔTUÒD”œoÁ@Ö[ }´ø±ˆ<-`°üX)a\ )À@b\zÔ'X¸Ùß7Ö7ßžn¬o=|°µþðãä‘æzs]K$·ÒûGÈ/s_ÞÁìBº1žNÀE8šEùÂ7^æ:,Êz™.à›T)WÚ\ÉeÕæó¸¸‹Ahé~>ÄÞáó9 6ZxL½Û9Ù>Ý><^Ò}‹œ¸-Àæ¥ÀædÙ»†—ß]úžÇ&œ>Ù_
ÁòSÔÄ#o°†b{o3¾	î¼Ü>™»þºbÿ@!ßZ´•ª5_nl67›ÍûÍõ› ~¶ÿÚ~€ÿÜ~Õ.Œ—çYëÐ	[¿ôßn4¿o®Ÿn|»¹Rwûx÷èäôÙ¿”1o>]RødX«Ç.|m›œíÖ`¡SÌ9ÌÅxü1g\À÷f§»ú­eG±ê­25ø„Ž—Ÿ¦ê÷npŽª_¼X:ß›œ¾§4F€8^X¤nò"`ç4<£,Eú«™cäýÍ^D«ö'oë¯¢yºÓyÖ~¹wrêB*<]°óŽ
yRF
äÑ©F›[ôzøn<’úIôm¥îÆç	ó^éV€~I.Så-¬µÎÿ1®„ ð¾EÿáwO{ ÄÑ¼œ‡Åï§|-÷vGÿYX `Ÿµ8•­ ËŽx(öÏQ?¸ßiDökL³ï>i¢Øx
ø‡«éJÏ³ÃUüæ=ÂäŠ'üÏ)²î~sr5L¨<ÿ!Žør”ŸÂÓ|Ü”Úµ…ß5ÍòIá@ $« <ôŠ¿ÀëÓZ–ÛLâS¬%ÑÄ1ñ8b!ö/SaêŸÈ®~qŠo†ú^šE.ùBRÁu‡‡ªÐ›èw,­")[ûT$”¬†úiÐa÷ã ±{ªðÛ'›<ys=ü¦ä¢4…A‡jQ›á¾³
Ñ/Kî¨íaÔ{k—„b#±3×uŽøŸTmå½nv])¢VS??¢´µ@)jÑ`#”\®[MÝÖm¥T³ªü$H&êSUë"3:z:hL•oâ þ3é³Æƒwåž±s" ÿâ£Çµ¦r¦ÐZy¯‰>Û;ÜnïÑ/§mìÄ£¦5ì@VºæûàÓ¡.f¿fî|ý‰`†Ù)>kÃtéƒf~[WÊxpÕ[ªÝk
ÍTÛ8Ë0œ UêÅlý8ÑÉ€‚Üù4šHÙÏØ
¾·ƒ†cýRþh©¦þ“×{Mõgl+›Â‰hnQnFFŒÿ>ã0µ{Æ¼*„iW¹ç(>÷˜Êž€…'E‚aMãEG†N‹>6Ÿtt>öð¬R‘d³€ªÁáY×–œ’e¯3êÜ¹ƒ74:&#\ëvÖÆÓˆ|ŠAðôÊØ5îi—»ÐnÓÜ±žk bË•ÆŒGu–ó¥qS© *6.×Š†ç…;/b¹¹=7U*ôEìbáŽ´…›"ã*l`uØ—sÇ©êk›PÃö@¼	n–T›Åa¼•ÍøŽ9SÄ……sdï°!óšœÐÍ5š‡ŽÕŽÂ6BàMßäg,Bt-nîš1RÝ¹:÷¬lœ­^o¸HÐêÚ‚[W,ïÒExqba%ùÊ2â½c°G=#æD|Ïl)öÂ%\VXÚžf| ªðù v"&-Ø@ÃFù£>Ÿ`CK¾]ˆ:Ñ¸ðEI aÒ5ˆ¸*v-ÙÇí
s‚¨§ÞŒí+Ô	¶Ö_SßÏœÊ&MHÔ®ÂÌåii¤r˜ô€Ð¼íí©ThÊøÒœü<ú ïí´èq]\2üw·»§L½¯,²a'¤þÈ€x žHY±ªR °ÃTWO„9›²™£^³²è²áÔqgõgr÷„5†ê˜¤´úú¯Ð7¡RÊ\,‹‚þûMµ—ÚÒq¥i@ûc„D®¦ÃñU‘`í¬Ä¢EKxjq%¸ ««>âí¡C<ngŽþô<Œ+è•¥=¤Ÿnk,Œ¸cúŒmsíÏ¬ƒù<¼DÐQqF£‰Z®ÙÊÜØd10öŽi4ðœÚOñgY´¢…B/Úœe’E¬\­ÒÜŠ°+w­iíÌÜêÓ ¡Æ~<–¡"H5X×-StàŠa~`¦°ãØ©¾!Ó/Ë«–ªY_ŽV–ÆÒS__zI‚¦¦ÁMµ5œ=æ¬ßÓö™ê>UVÂ‘ž¢w”ˆäŠ;kÕz"æÔ9x¥^if\ ÔmÂ!óõ(œ.ˆú¨fksV³»J¦§4ý¸FÜºvÈuµÒë§gfÎüZt¹UÎºÂƒL…LøãÄæ®«|R&i…î×ÏéÚužcQ-žrÅÐ
Cçv¢i†WrÍ[™úâA.ŠnšœjI‚Ä*Oˆ­{¦%WÞE–åË¤"¢S€þŽÉ3$w;õc–‰u§•"±È9V85â^1ô„ ea˜‹¿¸z«ÍÊ’&O7òWÖûZ`ÎÕ_–Î,õ¯ŒY;ÍÝçhMÀo4Ü–yZz§+˜N¨S¢üYWú@ùíº;=âxçÏÚ±jÆ``;ÄËºñÖÚ
ã=EÌ¢sFGúÊ›v¼BüQ|ÀU¬Ó2Ñr:á ó†ëîÒ¼ñR§ÚÉ"~» à;wŠ?¸ú«;Å6~Wó?ÕûA]ÁñXÚ•¾)ªj~ŸÔ© nÕ;{t*|ªR©ïíì>#äÇ@´YŒÁ´‰/|úð‡ÈM†ç6wYTˆ - çwê„<U:‚q#˜ü¾LX¿°þ6Ã}PòÙØ€6›÷y•.âÊyWy<(¼ógø‰ª¡2tÏ" éÆg4ÑØå(1eå‘Íá(žêï±ÚBøÀ’}e›A%.,bµ+Æ×Ô“~J#Ø9ÜoïT¬ñÂÓÆ—ÇÞÊæ>h1X½ÁGË„dªšzbm1TPC/£€ÁøxÈ(0tàW @Ë§&:»ºŸžQƒÆ±[5èhSñ~ªnžxéƒ¶Í•,v^ÉÆ¹óÑòÎ’;¢ø^z³žIiye#éŸE˜¾'·„'X[käQeV*YAºAµ^À#¸9ÿãdvga
£9mu_1T"óÀéÞn÷Ä°³rå»NÃ· Ì“_>i?e@G¯wNŸíîUÉ4GúRp£ªêêi +ïµœqÝòw|rÙoNß‘±Àm¤sÿ‡Ç'¥¾¹¯'2}9“ËÍ âð¬Å€¬Mm9¸ãÎÑ²q-qË¢!o	Pcë[Lv±jå¤­ëƒ.î”4‘sÕfÕOŠ§)àþú'…YÁ©ØšüÑH8Ž“ª£·nñÍÙ’@•ø²i#œ¥ådúˆ=
ýú}~¥ÀvqLý|Ž©è7^t{%Ì0Í§h¼ª{8Š¼Í>›U¯;uñŒƒ`´¹Éå'ÞK¾•Ÿ³ä¨ÎŠXÔÈHˆUJ<Üs
m³Ñ­¤@FaŽeú¥V•Aq™'!+#Açex¹=;™úASŠ'þÀ±n)þn($Ùþ¨j]e—T÷ÓQ‹Kär†UKDáo´ñ}„B¥ ]­Ú§t/)"´ÒŒ!@£²‹˜sP@ño7ƒ)¹ŽX}Àš»hA¿]0è·ÖgG× „çQKÒ =DñPÃ1ñÜ~6gEüÁ’;ä\N«Á+ÎKÌs×ðA„x§s!âoé$JDžpˆî\
úÁdôVÜ‘!9Y¿:ÏAêna+¡o­Ò¡ÐÏf	ö"7œ|)u÷¿ÿ—%àKÈõM‰tÉkW&Ò@ZN'ZXøa¯sðüäÅ™>ývÙ‡¿ž¤Lc,’œ36Øl¬Óu#a OU"îk£V®k€j(ü;›L$7ÈÚ¿ÈPa`p£(9ŸíÝ	Ò¡ÜÔ›€7/™ª£qÿÿö·¿y“ýÈ¥)ê{ÛÍË3=e‹â)y-=øßÿë<ê?ŸGºº·µáFkmuñ¹i:`?býÎ'1ªá#Oê.‚,Ü¦Y+}°¤ghþ´Hˆe1¿»¯XC”Jv|C¯6 žØ{/îá÷v_Ü#Óî/iœœÂ>U8;®
˜ø"U¶§:@c¾+E3Rr%U@š¿ôa–b?ì|˜ëÖBÇ'Rð´´ŸG{I0§îpµŽÔ8©òŸáøž2A{ÆiÇ;¦[	TÆR´¡u“ñ[Ök{º1I¬‡M6‘{‘¤´;ÛLl[Xß¬!„—4AÆMÑË<¡Ò¼¸ÌEô1X# ˆœb.Rˆ›ÿú´×ÔÝWZD—`n³×ýlÒ¢2	Ÿ‹Ž|©b0YÐ)ƒe@Ó;»ÇOèŸMM"¨Fz ÀA#o>@¼G‹9#…ÁV„&¸¼ä`966[-ó°5£ÜUÕ¦jsÚ-%;‰‘3KíY`D:kj7Ï1ÃJ‚:‰‡RÄÞÙìå„†îÄ!‚ \Ã\ˆ(Ç§ô/×Ö·›™ªº•\ã¢~zÿÎÎî¢[oùÂÀrLŒûÿÛûÖõ¶q$Ñó÷èûòX%3Nz,‰wJêQï8¶“ö´{-'éKúóÇh+–EH9±§sžfcÿí‹* $AŠ²|‘'MôNVÂ­P¨êòÝàDÝVQ²yÌ
ÁŽ:k1FÎÙsÐÔ`µ¢Ö³n­öùm;ÑËçÙ	@HO&pl'†"-^ôV¦.zBŸ‹,÷õ[Pé›¸ÄEZRN<é¤ˆ™¿¼+<*ëM¥™†Ž	]¦®•wÐ–zÓ‹¹›µhž§ÌYÐ—vû’&TÚo
¶ê¾Ú¸Úÿ¢ª–øÿÑ5Ë@ÿ?š¡WþV‘j©€{@99Çƒ\cÏ=«]ï¢<Õ#8Ûžiÿ2†ü-ÄSæ<V;çýŠs—NHÝùÒ+ñeÛÿbÆ›Ñ‰sm,Øÿ–®èEÿ_¶iWû©­PÇ„åi{®£S÷Y@U½íúŠÞñlÝ÷MUõ}üg³5k?f»´CÕŽÕö}ÍtÛ¦jêÔ×­¶æ†¡uìÀRlÅt¹vfkfè^@-ÃqtÓtÃ±Û†jµ¶j´]Û±W×:¾¡R¹vf—Ö	Úi·©¢kžéj¾´ƒŽ¦9Ô¶4_±T«cvtÜ•ÕöÔ¡ŠÖQ=»§éj [×w)Â÷l7P<]mû¦5KŒTËW}ÍñŒÀÖ:Ð´]ßp<‡FÛòÛ¾ªØT>1@'QGñ é;¾ß¶‚Žã8´Óñ4Ûô¶ÚÖ¼N[¥šªêÅÆ%Ë¸N[i[†­¹íªA jÇ·;–Úîè~@5Ïó%pÚTVt¦ïÚªc›ž…Ù2Ãw]Çu´¶åhšæk®æØ–"U+ZÜµ=UU5§[Õ1UXhÇVÚÔï(ºÛétª«Fö± Ù“¹ªêBoÌ¶ïu‚ŽMMjš€0°¶xŠ£–¥šyXå&q¦¦Y¦Ó|=ÐÚ¦bT1ÚºãimE|´øËbÏÂšY[E<O	\Oó|ÝÐM
Ýl;Ša[¶«´mê¨ŠÀÆ˜%[âÑÀl«šéø0Å&ð4´£ X€k[¾¡)Ž¥jZàXî¼ñ¾˜´ãÃH¬@¬êttÖ¦ 3W¶Šdûgz¦	[6ŠIM@íÀu=Ý±¨î9šÒv-Õ³ÍÀ5´ù“sKÜ›vS,œPÄGæØ4``‰tº
,8õmÛ	6p‘¾§Á+6kéèN ©~[3ÕruÏôu 	a€¥m lžbÒÂÚK¦›Z[SLN´À35ÛqW£&ük(fÛö°¼€‡y»SÐØ15èšN©®ØJÐVá¯ŽÒ±4[q|Óq
{,oYÕX[Cµê:¶ëBïUXxª¹ªîÚØ‚¢Ô£Æ•pj@H]Õ:¥‚£°UR[S]ö‡c¶SDžd.j–
dÞp¡yjëNÇðT©¬ð)à‘ãRÇƒ¹s‹“ËLjõHXÕf‹väÈÖ=X$Õð\W±a 
ì¶@7UWƒ½¢¶m-í”ƒ4“0ŒÐ ‚¦Ž	„ˆp¢*ªŽæµu`M,†ëÛšˆáij9T…‘¸#ÙôÔì8n›Ú¦ÖñTÃö]ÃêØN»cªÕÂ“×uµ £ø^9Lí(õŸ“?¥–Ò½¨hšKât\ÎmÇ¦ð[°(œqžeÓ@e3 : ­w‹v,Ï·€+è¨¦cé®ã¸:œsœp5çÌ«~Ä/òŽP!ò(¼cç=À<6©ôÌðt À6XªêÁiH-GÕ<@Å,«©GÜ¬d8¸Ä;à(V™­#lHj8ZÇ±Úª¸Úi *@µÏtŒÀ)‡©ajÓwô0CÔ¤–k¸p€ ‘qtLKB§8ß¾æFÃgóJ½v ãµQpÎ©¶m8ÈÄ ¿¡j–mxžŽÄ¹°ªIGGÀ©±ël#m_ÄÄñ+ÕuªµÛšiû°kËµ€¢¦X×Þhéož‚l®ºo¹šÝ¶ÛJÇ1|ŽTÕ÷€Š 9R}¥|fõâÌ²~ªºn;ÒÝ7,ÛQ)lË×,ª¸pÀA;pjw,»¦è$?ùÇ5'°LhˆæíÐ<j1vUmA' ÖÚp,Øåè¤j¥³ÉÖÀ)àêÃs€=SØÚ·€iìßŽå–o+U9â
eøŒ_í »hÂéé™6…zl×ž„p€™0Í@WTÇ¸ö±P>Òë˜
£#¶Ñ†¦ çÝv:p˜Á!¤ó£Í#V¥$€sz–f¸ž»ÜtJEñ|Là}€oQ«m«Š£0º2äîÎæöëþvM÷aH®ï88º 0`mƒŽïhÀáê& ¿¯ºI½Ìa`D;€y…ÍeÂ$é8 ¶[Fu-8{Úš®(€ÔLn­þ¤‚û’òB÷ÝÊý¦9ÿþåe”ÿAÒ-Ýù_5móÿó¾;†éO.ÿ—É@ËncÁý¡+jrÿc€|	ëoØzuÿ»’ôøšŠd‹ïO“Ôü>Dï ø½Åƒh±Ç©¿’¾x€zú|«ÿêôzŒ^¤£xâD%Zg ‹¨‘—pRÅîdz|¼Núñ% SøÚ2;Œj¢Mžº3Æ²ð}ƒÅ‡ßû1ÐZ€Ý“§!ž¡
Èkò{ñÄbüxWµ·ýA\^>n¡p”4î0šŠÞTÛð…Fž¿°nîO'Ï“—e–RÂÊYÖMÄá„p¶'0%ÃlÎˆ/ð]4³ ,7:F8¹ÄUmX€ ìßL´°ø –>Ãñ>½ÜßmèMåoK]ÄWk@}lEPŒªóÈÉ8 ˜‡Ì
¿0‹±9A[ø{C´Ô6ïv7?·ôœbà˜$&/êÜ3Ÿú™)ý„Lç€[¹%Ný™™_¾qM8”±³˜6d=@L(×_ð…KWñ¨~žéŒ<Òà—Þ°&.—sMÞæaòæ œ0‹/ø|Q·}_R’Zfñs<îÌ9æzŽ»»G›oú‡{¯v~ÝàFóRûI0¾¼UpnNXÁY'£Â‡	{›ö›9«‹õœ_ÑÍ ƒ9cá)ÁDÍ« JJåí10”·àžr¾¾à37J¡åzJ]Ë©³–öoÖ8C°lg#A5‹a
G„ÒªHf37 ˜ŸDÉG´Zò·y+ÐX—Á›µ¡’à¡ÅÓ©aEg]ÉÊŽNr¶z…6ó¾Ð1%Â›õ+ÃCNÏ+©\	=W>f€·BF#„æ°3ºˆYxv—&Q¬ò´%â±B›K¥¢/Ýà?TÒßÝRáÉá^Ú¸šÿWUMOõ?Sãï¿zÿi%ii[ô+” æÉ ™ýÏ;1{!9&~Ö˜‚)³ø”,;Š}žJtw¤|VLFpq£DÕ²è!'‰¶*ÜŠÀ§Jf¸EÿØ™Ûv[rÄ™YmÞ¤Ü^£ØùÄçòíÆAï-zžZâdru²ßW{kï§ÿxÒ}ÿ±E~ãî
Öòóïd-)éù'=øš±MŸ³/N/_ÛyIÜžä1ËŠlfìñù:-ÜbS¯X€»:Ì,¥²'¥e¥ÃùÀÐ’7+ºY—=rŠŸ„‹oQ Nòž¤–œdxÈNXÍ4›MâÎëùÝr3ÈXbsïõ‹ëN_‰—×²$+lí¤Ë›
Ÿ…µ
(%Øþ™YÎ Ìßg  NÆ¸¢bô˜^¢?É:ZÀçüæL¼T6—éF¦Ÿ·ßT…Ê	ù§‹ËÞûÙ`Î“ÑÚRé '¬?g¬Q˜Ldº³Í`Ué2“éÏ5nB„«?½árI"§~¥ê5?Ñšðš7Oí­y>‘wó÷ÿ&Ñ‰MÏHÃ#EuE¢ýÐòéyk4ÿ8F¼Æ9©wÉÞOõ?ð„ªG­.y±±³»½õ¤ÕJóž@.†û~¹½ÕªO˜Ñ&i°ÀÊyÿ”üi˜9H]n­NÞ?#ñd0Š•?>9“cXq%íÝXtàÅ§ó`¶£xp06üÿ$@“»±±µÅ;ñùÑ­1…~ÀÉª®«¢ü¨ÌÄ¦à2 %(žÜž$þäâãKÒ8ìü^øoÎçóú´©î/×½Fâýõ`×É÷°J’MþšXL¤áÙ
è¸TÈ[Š·š=IJJt<û:(T ´¼¤P‘|IåOæ–—
¯ŠD.+Í|)±
u¹qkÔåRHÅgKAn®õÙR+—š-!}Ýü´æfÌ ©v£‘˜—¶ñ/ÈdÄQ¶Æn4â	Óá~Â¸ü­×¤îz™ë™WÌpuRßßŒ‹Mí¸³NL"ìE‰Ñv£ÁN¾7;IÀ5‘‘˜…è+ã™¿i0è¼¸Èh_=œ¤GÒÚ¤Çl:¥Ç! MÁJ1ý6æŸØ1”fr£Nü’C&Vb–d›½µa„!žšßAç¼pNzÎ4Ó½µ]tuµ»»q¸ÝÛ$XØ’?Óš*/å¦ß3ÌJÏ¹tŒÃ	ïÂ0ž¤YÏ*ëO4Åqf¿c†Ìh=')F| |a×2ÏÐÓ1ÿ0g™ÅœØZ“ZXS¹z7¶¸ñyVÞ¬:33—ªNÝ€„Ê”èf02»t	Äio-gþ…¶,k|zöe;¡gÎä"éÖâÍ‘YVÖ†Èº%ß“?/ó1ï„?„½µóAŽ

åÞú¿‡Þ{qwµºØ]I*Wó^nô?4Û4Òû_ËDýS7”êþw©ºÿ-Ó‘¾Âk`ÙIBu¼ômð×y|­ëÅ/q}FÈcî²×ùÙXâàï&–`Ï°–ä"‹-¥*£ÿ™eÖý1íÿ5½ ÿ«Ùvõþ»’ô˜‘{)¸×˜"*¶›¹NÅs?hâ‹°‚ÞL0S—2ûi®!r7ØM’kŠÜé^'ùfaˆéTÜcea×ÉÞþ³ÕßÞN=ØÔßtZ˜ýîªz»ÓUáº¤n»Ü?—àQnX¹Ü6ñÿ†Äÿ+†Žúß–bUû©Òÿ–xÿ¢yñÃäýçh€—³ê•xÅ¿ß¨³ßS~¿üó×ž0|ö}·qû?KÑ+û¿U¤Ì&øþÚ¸ùúëŠ¦Të¿ŠTðÒs/mÜbýmÝªÖ)ïç~Ú¸Åú›vEÿW’fÜÝC7_C«ÎÿÕ¤9^¨–ÚÆ‚ûUQíÂú›†YÝÿ®$=Îé¢´”x¢OCÑŽ|¤‘ù6þG˜‰G~ÿ‹jÿ·™eÖ‚‚zqÕj©VËƒgcCÛÇç,ªÕö7ì=Á»OX¨«fª@,2Ø»Qbs å˜÷	õN3+[¿ÀaÖS›fÞïº¤›\'=R¯§½'$Yñ&«.—"¤YV¾ÐaDY®q»}p°w€/µ‰‰5ëSiM˜,>_‰OâÃž¯A¦wõê:Â‰Âé„Çý’'½¶°òŸëî»J9þ_òÙ·Ü6n~þ›š¡Uçÿ*ÒŒO°{hãºëo¨†ÿ1þÏ¨ü?­$]ÏÓæÝÚXÀÿÁžOý£·:¢hŠ¦Wþ¿W’ÿã k{´¼K÷G·y|t‹çÀ%÷9÷ XºÝíQðÑ•¯‚æ?>š}|T|äÑ×ÉåôŒÐ	ôa8¤#â‹È\‘ãòQñ•Ã¹á³Þ£yïzK^ùeïÑ²žö–ÚGLˆi8BIÎ¹0”,žúƒ	7ORžÍñ&\Ošæ›iÃ·—WD$Ð\„±‚Å,÷õÔ­'Uf”ÚH·TÕ-­0(+$¹Y¹Ä0+_s%X3Ao,ÈÍ—ÉÇŠMÊ`n¡\.îmZŽ[.¦%·v^m¼.¶Ês³R(`mÍ”â¹ŸÙòåíq_áÿEøý#
Šø™¬È>²ªÏS'¬'ÅÑI,ÊÞhA“õ®ø5g?S—×!)Y°•ûœä}g¼Ïìwø„Ëù‘ôÍrò‘™èm†£Sï’Kñ9NÊ!ÁÉK',à£Âö(†/ò’ˆ¬}:úƒãõ7é$ÆëDfQˆÛLNG¨ëðáü¬‘¨OˆïÂIóa£ù¥Fac<	ÏÆRÆþ$cs4Â9L¶åR›­F¿¶[ô;´±€ÿ³u=õÿ©é¦…üŸmWö+IË—cùæ ÿCæú~F/‡#B·ÑcB‚)üãè\ÆoË‰ÈîÖÎà&LÌ;!>ä	.²Ü+<yTÔs¦,ß4 £&yNð?ß™äÔ8Ö„3àgÎhŠfg@pù ¤ä#ø 	ŠT\éú¸ä7ÐPo“ÙŽ9ÏiäÀ¦u§À’ÑöðˆPÜð d9Êß)6æÂãrÌwk»]B9öj€“Pãló5xÂ P~ÛÍO>ÒAhTV:1Äp Í;#Ÿ~"3ú,¤ÇØÑ95vC'€>‡…:œPŒ+]¨µ´iöG]âzÉ,¯ÃïÜÍ[¯#üÍ•6ÕB÷ðO›C •]@%ïMŽ÷AÜG…oã²Ì8rü¨áÇŒ'lø£îóB‰prìŒ„oGg˜´5•È.ùw¿ÿã†©jŸ÷ß~ü[ÿ|:ð½7ÿzÙ(8Toö‡ï:_ú¿ì«íñiëäôãù¯/Ž/üŸÜÛ>Ùy{z°ëü×pûÜy;T&›///?þÔÚŒLÃzÛ_>oýºíÐé`÷í£š7êJ¨åþƒIÜ^Rf&Þ(Ì,+6ò<@¬m Û%ÈõRPdÁGX! .gažÆ'“pz|Ò€¿q—èpÂg¢Á%Í9œÓÑk=ØjM¶oØÔ
qäçöÔ­Ðèžö9ö³ÚèkâËé1+ÿ)ï$Ã1g¼Á|ù$bš,ÐWJ#~úùÃNKÝ{ùjüêo?½ûùGúqúÓ'êÛÿüå—_âKû×‘ýá"ØÚ>9<Ûùqøó»n¼ý¯QôñÃßþ©ŽèñönûãËýÓOöÁEçùëÖ¯ãÖ«VÿGëì_?½nÿK;P8˜fhåÿ¼’JäËÍÙàiƒDÞä éŠ”Ÿ€—h8À^–—à«Ú fÌ¿²ÀÇ	ì‰òèb‹Â¹«­«ËL(2/ó ] §š†ãçt·û°!ÂK——A·ÔèbäÍù<@ÇCxI€  4”ûpö	pô/æŸ?eøõŠùBž¿Áµ®(ÀùÖògÈ#^Ì¨ÄßÎ6"Ëà,by)~·ÁVÍ™×Q&:™Æ‹½´Pù	8Š‡Ko ±<sŠ§YŠê·!y_ãíÉ×Ÿ®ÀîNm,¸ÿ1U+µÿS½ÿ¶VÝÿ¬"UïrŸó—A¥;áË\iÊu®‚°ê€½ÿÁ¡r‹×?q”¸8å|î›³cŠ<}sö:æåd:òSÎƒð†ñàA8<Æˆ £äšÈ™éã$æ[2kéåqÀ¸j ù¼³Ð±)†üÒ'wCUÝ Ý©(bñ÷‹;Ù2”d…Cà˜‰‹û3ŽÄaêBô4œLèiLŽ)Ã=˜’^ ž0	¡ÛßìU°&:e±eØ­_“¼0ù‰cÊ‰ëxw1”ƒBÑ,Ä;$Á¨´-¨†0&’GÓBDGo±Z¼N"t³–Ca•LÇˆÎ¹àóy²{šË]‘Ä5Jæp³Wo…ãX„Š©ÏÁw½^½àóäêÅˆñªÖÔšjð[®+½â•‡ï—ãn¥¥‹Ž’ç (í^¦ äˆùÙ”ú™<6–{üfÖ(…n ·Lôá)ÁH{èÂ!ÿ¡‡þ
eûýÝz|(dlï÷ÐýCÆÍ†ÁwOÂÍnÞ%äSLô¶¿÷âðÝÆÁvqÙ¢0ˆ1¢Më<Ã‰ÖL­#ŒMU“¿?·0MI¹¯ÞåŠgKJ¾ÝÊ•ŠÏýV2ìÔmÈNFêRü=ºWîÛ1-‹‚¥„è,2ù‹pO<°§ŠÒ›/×WOä«´âOÛ¿ô÷¶oˆrN£û³~æChŽ¥Þ¿ÞÙü	÷A¯žüÊ†‹PëðO:¦Ã(ÎÇç÷Þ“§éƒ¼äz’üñÓ:x’hM<Ã³÷1€es0ÔS®Pë¹\çjù\çêuYÎƒq7œ®D³‡”®lüm,ÿ3“ÿàƒ½ÿ[•þçJR%ÿÉ}ÎËsvÂCVRYð¿ÿÃ_a6¦ü>™ ·,Ë‚ÏØ+yÌÿ)!oú¥z¢™¡Cý8{åg¾fÊgïKg››2Ë27“	Iêqþ'`qÃ…ÙjóÃ–C]g‰ÑAÝ¦]†LÂœ…17ÓZ`z
 ¸\Ò!VgS'ä€J½e¿†,b$cö .ˆ¨Aàë3†ŽuŽ%ÜÅr>Éb’rî	Cßì¼œñ®Î!ÉñxËa	½Ý{ï¢º›êí¦À¾=ÕÝ%ªä&ø/•äfå²Õ–Ëe¹\}——Ýð}Áswˆ}ö*RgÚ½sÝž¶PI–?-R³—¨Ø&ŽñgÕzg\â—ªô
¥VìºÈAtåîæóó‘G°Üƒþ¢!¦”üú,*ßq˜3ÊºçtâÂ1™ü™†H•ŽáÈ@p‰†uqÅ¿Ñ§©kòÿwÒ ^Àÿkªafü¿‰ü¿ªY•ýÿJRÅÿË}¾ÿÿÐÕùD¶…Š2þEU`r*³ù7Vž#UªÁ_	;.ÞúZîÎ–,ù¸{X^•riöü×ø¦;B=­#au§À…öß†’ÿ:ê¨ªZÝÿ­$Uç¿Üçâù_¾öñ/] ¢Ó Þk2t|¡’=¹a3åÇ¿€GÕxçXéÊøð‰*dáø>ƒŽb“œ™h’>C¼™hœËšøç§PÈ¥c®âHãê>î.}¬îãî÷>nOl	$|š°âþîæ®{·µØ,—ëÃ¾¿²Ç‹îp4ü(ƒ“’Î	'‹@Èd#5‚÷†SŸ>Ÿ@—ØMÒóì‡©°ïl1mf‘¦‚ä²¨ìŽ«”åŽCbÌ_Ñ]Ñÿ§©G"\Àà£ØF±zÏú¿ºÙ«¶¦àû¯^Ù¯&Iüßò™Ûp·`þ–Úáë§jGR¬Þ#Ç÷ÙNÐšl–bPÉ÷Oº}…Ú.ðR,ÖÒ)LÝ»9'5‘ZêjÀhÉœSÂ.jÐ€ÚÄù€3v*f‘2	å»ÄÆ—Ç]›;1*F¨Z˜‹‹u‹îç£–;}ÓqSžãšÏ×x”Š¨¤È”°Ü\­´Œ–õèŠGÅk¿)Ê¶÷gaanZìê—Çk1]5Q*;ss‹†¬cæW‘OW0	Ïøo­¾è)N†'5ó¾ÆßåúÜW,&Þä’<iÂ’â[ …F¥xgxÜ‡BEáÒGòèSþ€Þ ³VÂu=ë‰“ «ž÷j¹0áÙ3ß¬;žÚM&† '“d" ¡q!<yI‡—Ýã•‡Ïžåÿ´"ÿ§­”ÿSuÎÿÿ·ŠTñ¢ÃÿWñ¬ñŠÿ«ø¿Îÿiÿ§.“ÿSoÁÿiß"ÿ§þiù¿9ï¿wQ [Àÿ1~)çÿ_Ã @ÿ·Š4³þª^ÊúèwùPÌLÿçÖ_7*þ%©âÿE‡óüÿüMððùÿÄ;ÚëÏœ5 ë¶³™ÏyWn¯CŸ~rÂ×ú¹’%œ,¡—–Ñ¿Y‚Î.X^Ž¤Ãq½~#~Y´‘Hj^~Pœ3·æP…ù€ê%vj	ßÌ.]Dÿh­´v%h­´4˜}©Ç¸Pè0Þ›N¨´{Ô²:ÚÕu´rÑ§TŽHå¡+‰ˆ·)õ‡$Sê•LùË”UúzÒµâ?Üïû­˜Yü/Mgþ«’ÿW’*ýo¹ÏƒA|]Êßù(`“Ì	ù]:Ì‰Šq[‡eðf@]ÃC©÷†@¥î*ò;ô±Ò /h'A¨ˆ#9ãá¤/Ae¼ÞÑþF¿ÿnï`ësLúQ·Ô$,ß?ž`ÛÀìÑï‰ò<LQïÉSà3	s6àî:#@AÒð=Rßhüê4.•F§™A8ôIã#Qøã„Âº5FD}–Ã¾þ=}|rLI›üõ¯°.Qôzä»ß Øïßå³ x1ƒ,ò{nxé.ä²0P “äÛ×jÜCWÜ“Cz?€—¯ê­8Í²0Ìö°}nÏÂ_‡]”„ŒŽa‹ImþÛG¢øŽû¥.ÃÂ_{ÌÝ#y3bÛ\²Çé37Ý@©$|È¶Øîi;ÁÒ)€­ÿ Áçº)F¾éo|&sªmä¡cµ¨¾ÜiÉV¹¸KªXÁ
 Ê#c®ð³¦ÌŽ7‚Ûû‡âõÝuœtÞƒi:-É"\Á}Uo®7›å»«Y²7XoŒâ9ÇwËM\ÚTnkn™*+þo2ÍêÿêEýß»<ý³t#ý_ÿ½Òÿ]QªÞÿE‡+ýß‡ô®_éÿVoöª7ûê­¶z«}ú¿âfˆ}tÖ_,ƒÇXÄÿ¦•ò–®EµuE¯ø¿U¤e›E–og xïÅxùÃ£{øì‚˜‡èKr{EfO`<Ð…þ+ÀøÕ2xvSÕšŠQ`ðæpwq(:KXgÉVxæ¾ŽîAkjÖ¸É	#$Á>eÎjd®ï<	üSóÙœ1–Ž¥ÔjŠ²Íc?]ÛÚ{µ±óšE<Z['uFJx½ú³À/l®€çhMµÅ«E­¿Duò"õâY@Gl 	ÄÁ(~Z„*.ØáDC ¶¢¨õgIå(&õ¯ªÜïïJõµ¬>»7œì®+~¤.,íÀ«§ÇH_IÝzþ ø£Úx‚ZãÈÎ¶®à¢~ûKôûZa2¾/ßO¦y¦8.@Vœ_¶ï§s˜Ïf·X¯$ybi1Y…7Ùü”‚ÇùËJ§OYsJãŒAi@UAÞíöbÀs}à9OùxwCÁé¤S-ÍÃzî=§d²9áÕ²ù¸ªbŠŒ¹y¹ª"ÎÔkiseó³¨V6k½™yZWõ¥Oëå§YûŸùW·mã&ö?ª®rûŸÊÿçJRuÿ':üíÜÿUö?„«¬îê]â·íKàVö?Ú·ÿIÜTö?÷cÿSù”¨î”_šY­ÒÒÓ¬ü§qÚ.sÀ÷ÿÕ6³ø*È‚ÿU¯îÿW’*ùOt8/ÿÍÙ_ð7ÀØ
Î01­q’Ã9*(ƒx_‘2H%ä])äM*!ïO(ä•,¢üÓ´ä3ÁÐ‹™a‚^:w’ôˆ©¬—Ó„Î‰{™ô>ÑÏLä+oA[ÐBQî›#øeëtÑïêZ9áOU‘cùÿÍyþÏ_X t "Î|tK¹¯ `'nŒK­(±E¶l:†Ô6w0sûýÕ‰n×²ÿG«ˆ;ð˜ùEŠÿª©Œÿ·+þ%©2ù_dòÈÿþ¹u<d‘^’#¼fÖÿÏéhŠóˆÙfåSë§‚YÑ¬» h ‡Çt„1årMÁß<N+œ‰ž÷N1v/ãæ¬y¾V6ë÷™¡¿ã2kLø›[ñJÌøçŒ!!ßÈLr
.ßÎTd©ÄÜõ2{M®¶6ºþê'lãg´ŸžÆÙ8†®3lxòÌ ™Ïmˆ˜ =¤Dk „îè‰‡Ópé‰s>']Çóè8®<Ü¡Kpƒllm˜evøcÎs
R85w
"lN„ˆ»P~g% ¬Á<r¤8èßŸºñf¬ÁöŠO‡½ Ú£_øŽá“×ÉÙ”²Í‚›ý9 wªÁDÈÆæîZ;ÎÁý	”–ø²M¹Ôa#¢#*j¢Ç“pØ€•ò‡t’¢:rC>»ÁñÝúS8li,*ôÞ×Õ¦ÖlJSUuÓ´šjÓh¶ó}ýÖ*¬; é÷Äñ€É¬oa9¦ÅNÀ£tâqêqêÄ¤‰Vïåûú÷Èè†Ÿ…÷|¤ïþz6®°uZ°ù`ëð›EÛzáo¾™È³ú2ñ'CìL…?_Ò™_
¥ÐcÐ°ÌåÿKÃ»ßIXèÿËÐ2þßÆø/ªf[ÿ¿ŠTñÿ…Ïsÿ!K IàäkHç'ã‘gxÑ{dü2ß?—í¿6×¦¿âùWÏó¿rCòc	y}~ÕG˜Ï9’+W1]´³x?ÐWPwzÎ/Oy£1ÇfäÖöØR²w¸È;É[:‰BÛlà¶nÒæÍû2O¼ ŽèÒŒÎáÀo8¢×ÐîÅ(v>•·“ówÆBRW_û¬¼ñÄÃPƒw-×®Èân[
P|¥.w’ñb ‚6`; ­ñSðQý¥ñÎ½ûh!!¤¥.Ž„w§pRèXšŸë[–Ë»wÀ¡¥½{™|O;ˆŒk
Ðyâx1p¶ÐV7Soà»£¿|''-Î·B×ŽOœ®±>šžÎx]}=©©­Ï~9|Ð¯é”çŽ	càˆC:âDrôHX×§tiöÂÈrÁãªJ¡1dÂééîÒÑq|ÒxŽ®ôÞ§•ß“·I‰Òú)v§²‡TT¸ Ê€ÄhxÄ(zF»õ>>‰û¤ÿãFCÍuöïi8¾Ø]%*û … ¦ öÍtwõY<Äž5äGÆðP.{{(Ö1íÚ¶m¿xe›ôÓx 6ê`XÓÙµ
u
-7&ô_S8Ï@¶šNà¸Èf†wéæûh>JÅ <‚0uk„:dõ½
£n…Q÷,|ýÁ¤ƒcAäóÄ}€'5ðEúÎò±nÞíÎÈ\ÒOðA 	;B¾öé'Á.5 ƒ£ÌÀ±'ƒ	ÓÉW~LAùF|1¦],x|1ï; w„\Ó¼ïÑÔ…£ÎØ´ fócbà¥™¼ëÑß‘ÃüpOØ0ÈÖsLæ$?:š.Déð8¸wÌ~ƒÎpØèëÖå<óeóyoƒþ÷¿“Û ýwÒj<ŒË…*=ø”Ýÿ ?>	c”Bý3Y^Z‹ü?(’þ§­¡ÿK³+û¿•¤êþG¾ÿ¼È=»É%9ñ»§FYý¡ngª‚38fu…pË>2«ú#É;C‹_D-ö À½#!ZüÉ 	¿oTMÊhøçxFñÀ»˜×•ÝUðÊÿNš§}8—{oöy–Ž/€Ey€“IÎ²Z‘p^Nééð‚ÿ>Dx‡
WÞ‘{¶øè|Š€gê™Ê«GµÏÈÝrÒ<à€N¢Üxè[¯úÛç°oAZ§°Ù€.IHŠßn>ŸÌÙtÓ?‹šHâ<z5˜À³pÔòÝðÊîÜ1Ho¿<W.	_d9¾ô9U¥ûIsù¿%¶±€ÿSm#õÿ¥aAE5m³zÿ[IZÚé˜œ‘XqwY‰‡Ïîî½<Bvœ™#×ñN§c~ç>ÐOˆà%¸~ùì::_|ž/>½MùôV”Sv~Ïßÿsé?®ù’hÌbúŸÉÿ–ôß²”Šþ¯$UòEù+ÊÍ>~S”Ÿ'YÿoÙ¬?Kï³ø†nZ@ÿ»¢ÿ«I_›¥þ¬­> ìÝHö•{>Áž¥×Er½	;êCè’sÈó,u¾9qžG›—7ãµo€¿LHüÆ’Óáp
OÂ€ÈN¦#|N´B—8 hàùþCÃvFüÑ^uwosc—™¨JNtB1yñfw—4ÎûÿNÀ…¦wB~`Ñ GØyí‡¿ªµ¥Nï`f#oÂ®ÕMP6=Êº¶®¯ëæºuÍ‰Úy½y°ýjûõáÆ—™/Î¬dŽ4ÍÑwógF°&83‹¦âKLUZIÊø?æøq‰ÈwÔ¿”6ñ–b¤üŸe¡üo«¶Vñ«H÷æóé€À¾"OÖà|d—Ì ý•åzž—$NL
ìäl¥ÓTì&)òŒjS)2oFÀ?É}ÿ•ðÔŽÊÌLb8º€~œyñ0qÑ‚ÃàQ,²aäÌ+˜Å,7Gàÿ’Ð†¬;ŽhÔ'¢ÞÉ|8Ý´™ØºÂ¶‚<e=}Ö$þØƒLnOB`(`±óPü
›àÒ Kæˆâfíq®4³‡s#?óXÝÝÜ÷hê‡ÄÏ.;iM£Ik8p[b˜âÿ·
ß;>¯YÒ@éò°¬0U+‡£÷©ãÅ€Sñõ[ñEõEÍôÞÅ2TræŒ¦ÎðJà«´t8¾9ä°d%àJºqk¿!ýø½¶E9âCC=ÁéÈŽ`;kïœQõF4þNN›Ü¦¶¶ÄtRÌ$µßÉþ½vx1¦½h DÖPUm¥k/qÇ²_ï lÈtÇ÷f´jÛŸ¨Çðoö[‹¡Ø;êîb<ôµÇ‡ã’²ÈÏ"âÈÅg4œÆ}êõtE©A3#ß™ø{Óx<{€p°óÂQB÷“¯Û“I8)~„1ò;›)ê?¿èM‡ñ€éd'SóMD•Èóü2òÈ\½«Ó)-òÿ£ÙfÆÿ±÷«zÿ_Qª|~J÷ˆ9Ü —Šx‡(lSÄ+gÏŠ¼cãØá§mxA€jEéÓpjþt’ÞF‡âX
°‰çü<ý³œÀ­)³\ò¥dÊˆz@dÂ³Áåm}trhÏa}$áØªÂlBÃ3š…&Ã«&´ÿˆ›Ð°0pD&ð ß-:	§CŸŒÂØi2¢¨®êL. n¼Ál¢"Úyûè8C¾.i+Ç3pâ+:!ô¸	³LšèRøh<	›¼ÍÃšG6Î¤>Gâ,üƒ”Î¹3²¥–Ñ8ŠÃÃ.ÅÎ1a~ývw6ßô÷^íüºq¸³÷¤^j?Œ¢#bè›Vpï`csw›=Ë%r‡í!û™‰#ëÉVŒp–ZSEi9ã±Pùä0ßlÉ ó0aÜW”:”ÛÚ8Ü˜†€2	Gèì¬§÷Œëùã(…–zDd}”º–º²Û¿¤3­Üe¦ðæOoö“qKPÅ…ñb˜¼ ¼*ÌÅìÌ.˜ŸÄÖÙÀ÷‡ô£3¡2è¯Þ%àoš±¶ïŸo7äŽæà} d&'°cYÑäý7[J4'œ ¦ñ9e$k^›¡ZÌ®µv8#z¸y<äíÄaq=°P‰`²2Á	%È¦@PàÌp1ÂqåiKÀñðZ*%ý{éÿ¡º£¾{Êóÿ‚ 7'Ñx‰m,àÿUçü¿fº¥[Lÿ×ªøÿ•¤ß¶_¿Üy½ý{í€Fc8(­~ËgõÔ¦Âÿ«ýörûõöÁÎæïµþöæ›ƒÃ_ŽÞì­Þî½ÝÙ8zõ'†ý7ûèo¥8Ã¥éVéþR™ü¿DÑŸ¥ûß6ÕTÿÓ°-…íC©öÿ*R%ÿçåÿ‡,úoæ”>ÎM°˜ÎpàDìí@>Q+8žÊ‹@L®y³•ÞG¥—BHƒ_ø
5¼À§ŸÕ—[Bq;œÆäðísÆ1:ÿÝ,ó™î>ÈÛ’¢y›.ÛÍÆÚg^›ød¾Ý8è½u†SºÄÎ
å–ý¾Ú[{?ýÇû“îû-ò[!rÈïd-)éù'=øšÉMŸ³/N¯à¥Ÿ;ÛÏ
¸¢ Ê)RöPd3U—Ï×iià›*€xÅYÄ .GIeOJËJ†ó¡…hV2t³.zä?µ˜Ñ¤ Þð=Óz ²Y3Íf“¸óz~·Ü2–ØÜ{ýâºÂWâåõ†,]lí¤Ë›Þ|Q«€R2€íŸ™‡¿9 xÁY °6™äJ'$ÓK 	^¶Ïø\à<‚‰ƒÊæ2Ý¨Hyo¶5¯Ü¨œ’º¸ì­±ŸFáá@­-•ŠØñÎH´È(ºã°Û¤äR§†¹¼ÐË&ðhw§ø¹FˆÖøMV2èÕ›DÚ¡â*Aèž‰ÛÁ'ƒzÍG´Æ+á®_óübä ¾ó×ÒB'I!i;g_‡ìk]¦uékz0[û•+…[h¶äæJáŽš-¹P*-68)T¡×ƒáÜBé>‘J{W—æ›0+¤$7elE²ÏŽ;wÚ‹E¥Es…¤©KIP:kÇãÞÚ1Ø6L3ÃžË¯Jð^,ù_PWñ„ÇILÕî&¡Ý]8{›d»Í’?Ø™œjöÖðƒOšßÁ6ñÂa8é9Ó8L”ƒqÓï`OÒ¬ˆg•A‹†¢8Ð‰'ßAgbô.ÙO—–É°%%éÄÄà>¯`5S¹„O‰¬:½YuŠoÝRõ	ß€%'ƒÝw“ÐN1q>{kçƒò Áˆ7*øs:æh1M‘bZÌ€ÎœöÖÎ˜‚QÿÀ…C×œÌÅVê¨SD•*b•bòðàRsCAÌ„™ÊœÄÊ=‰¦g_¶3èälzvæL.’nùìS)ÌÇ™?šDØ‹²˜KYP%î½,œÒ“KZã>ÆglÆŸby09ÿ¿Wgmy*_íUtáþgâ ,§œ·Ä6ÝÿBîÌý¯jT÷?«Hƒ:£M|kÞ+¼`r|jÈsu/ñPð¥{_¥»¦rý/&-íxÁþ×¤øÏ†­Ø¨ÿ¯ëÕþ_Iªî‹ú_î×À¼ûÕmðuQ º^úmðµn¿Äí!ILAXÀõÃë²ÄÁßM¦Çža-þ'G²P!»Wó™óÄîeŸ1‹øCÓü¿QÅ]QzÌH>?RØYÂµ&‰Jº¹Ã€•øAv·6ö	†ÂÆL]Êì§¹†Èe.1Ó\SäJÁ²ÓoéJcÌ;=ÆÒëdoÿÙêoo“Ä.®öø¦»€ÔðÆÈ½S:éªz»ÓUáº¤n»Ü¯V”¿UšÙÿÍ£­íovVÆÿffÿkÚÌÿ·¥ªÕþ_Eªø‰ÿ/àþåÿçX€”³ë·° )J	J‹?+ÿí1æß†æ}¥™ó?{¹4 ÎÝÎâ¿+€ü¿méÿ¿’TùÿàGÿÚ_yøßÁÈ-|€ÜÐH˜wdRô "ŸàµU8þHg¶ÄÕÇz
=ÝÖîßéGÙZß¯ßrìªÝƒëk´tï×‚~K saWüæ;XæD¾Ê¹ïsÛÛÛß~½Õ?JÍ!{u¶ÁÐ²õÁ?U› ë©–Öªç=‚äoI“»bî¤á#+ú¯é º%{™['«€êø×ª4¡ç“êËs.òÀ¼‹Hþß©8!_ÞÄŒ¥ð‹îT»hÿg«ŠYñ«HÉ“¿Kž,þðôÕ]¥Ý.^
åöÃr¯„žì‡¼É  |rŒ£\ ?ð"9öQ.’|àÅr,eP[òÇ–òæŒÁ ñEîÒ¿È=>LÅbÝ¾¿ ¢»5É÷z°@ñ1bú:üNŽk¾×%ifM
ñ¸89vF‰¿ŠÜ8¶8DoÔc'r´^ÛƒüólõBKÞp3Å qÐI
yŸ†pöÏ…Ì?ßò—&~UªR•ªT¥*U©JUªR•ªT¥*U©JUªR•ªT¥*U©Jß`úÿP)³ ˜ 