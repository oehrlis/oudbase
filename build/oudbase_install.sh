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
# License....: GPL-3.0+
# ---------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes/updates
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
‹ ú)©Z ì½ëzÇ•(š¿é§¨@tDh@€ HI¦,g ’˜ð6$%í0M A´tcºRŒÌùÎóçßþÎ£ìGÙOrÖ­nÝ’(;É“±ˆFõªªU«Ö½VÅIëwŸù³ººúxcCÑ¿øßÕµuþW>ªýpm£½þxc½ýX­¶ÛW§6>÷Àð3Ë§aCÉÓha;h6,ø]æaþý'ùœÁú§³þ)Lo:Ë›ùð3ô±xý×=~ø˜Ömm­ýh}ÖýáÚ£ß©ÕÏ0–ÒçøúßûCIà,Ì‡Á=µrw€¶´ÓßTKwö$‹/Â~œ«ÎË†z>Ëã$Êsµ]D£t2Ž’©ú£:žM&i6UËÏ·ëðÎqGYçÓ,ÌóH­}ÝPOÚkêå(œNÏ²ÙùyC_ÆÓ¿GÙ(Lúw>èýp5ù³©¼?vfÓašÉÇÓh&ê f£X-§Q^W9=k¦ôìß§‚€f/ÃÛÝ~<5o/í†ùtk&çQÿù£;œÚ¾Ýø79Š.â<N“Rý7;œe“4Òs uÜËâÉTMSuÁ?ÃHÅ	L-éEŠg¨Â\eÑt–¨^Úé4ÊõhN†°Ž9Ã€¿ÆaœŒ®Ô,újf*J.â,MhQaq†élªNÞl¯@×ð{ Ë
½!°át:É7[­sh9;Cì´c9²8 qì~7îE‰žÂËÃÝ•‡ÍÕ»óåÞKûñ ŽúØ|Í£HÁ¨ ŒMÓ†5»¢IÑ/£ôœf<N3D!ü9§Øþ×£¥È[³I,¿óÁ®¨-à‚é8þ;wù)Ð¢w´ï^oŸœœnï?[zï|Û\©MÏq6Óì¼vMè&}•î`Û†í2MÕ›p4‹òO˜Pð¦{t¼s°ÿ¬Ý\¶:‡‡Ýýígµ“£×Ýšºåçqx6Šxcø#œL"à1 ûùÁq÷YíEg÷ø#à]DÙìF ØXÇ[G;‡'§û½î³¥e$öXŽZZ­'{‡§Û;GÝ­“ƒ£ïŸÕZÓñ¤F_ììBïKï½×-ÿõæÒR-8>éœ¾êv¶»GÏjô9UKË¶ôÞéýZ-¿‰2¢ò¥÷‚¾ë:SúÒƒZ°×ÙÙílouŸÁ¶ü÷4ao6{Ã {ttpôl5p)âÓW’Á½˜%=$ªO!w·»o ãR¯óð<Z®«÷E6»ç“QxÅî¸w$'C…DÔôh;ÝËÏUmgÿÅÚäŽÅEþaex‘©•X}ƒ»{ghb«û­ZÙVß€FÑßÞ‡¿æ¿a·_¦Yÿÿ·ê§ªN”ZV;u®–§('Æ çáÛœ×/ª^¯Ø)s^Ïª^ï£Þ[âËY4Å=âKs 8ó¶M¾H¾›ª—<ÛŽ³¨G¼/L`6Ùp•¨{OÔD/™óviYðOÔŽHçª÷vÓsbO ëßï¼DîpÍíâú¶¯ÕÊùT­ªŸž¢¨O=Í­Q&¤ÿ3eÔnéýÚ5ý@ìêvŽWýþª¢çƒ8¸î\ÖUn­=&,æQÓxLºËxò¹¶:a}¹¼§yîì¾>!ÙþjóÁuÒÔÞðm¤@ÉÍ®`3$çê,‚úŒÛðk@9ºõ¡#èÊ*T	è@Î<‰Àù67³&5ø¢ju¥Nvöº§@G{‡ XPQµûêû•¯Æ+_õO¿zµùÕÞæWÇµúÓ§Î«GGó_Mnx™¤¼ýýü{õú­ÕÜøw¯A³â£_Šò°gw@RðuM=S¢7ƒnªÕ…Em©Þ0ÅövL@¸‰jê—)(Ž+¡³Í›Þ¾ZÆ4ƒ-¥ÿÌ‡ñ`j¾]qßÓ¨±Û?Àxi¬ýÔëâCgf‡Uxxãì*g¸œ×Ô™iy¶ý4‰Ê¼é—íÛo«æô†ýêAÞyŸƒ?é
TŠT‘uS5›  É½‹§ŸA9ºIðU(O‚=aÉmdÇ¦ùjÝÈ\ä® iKÚ³Ë®ÚNsà¨Ð¼ÓT[ Åè¦ú¬ãsŽÓYBšx˜ÏÐZÎ›ê6×ŒÄ²÷^š¡ÞædÔt»X»m°ZFÑ^¿-üá»Z	©@b é'é”5GqF&äIçùµ‚®àËQgk·k´›Óçãâ Ñ7öJ¯Q?y4%ÀÞÃð"ŒG¨=zói·o‚¼•ÎF}‚0Mg½![|8/í f”†}õãÒûW@­¦¤îáó=NAÚwÙ8ÀÄ¢¾ûþúïw³0„Ãé“á¿~ãløuZÝl–$¨¿ˆ{¨—ŽÇaâƒ[ûpýÜQÑ¨ÐB^¿	ò,y›¤—‰ê5}z5áõkÀžNlð¼?¼	ü^œç¤¼•ywÓÜ†|›Ç%¸ð@Ý‚Ð’$b®û
P6Š±±ìA² ú*•]hvGÏ·\2ØËGÎ2!ç(LÅëFG¨v—½(sX@«ðz¾µ }^éZóÆãÊñøàñPW’§²«5ž»pÁ~ýu½`cýy–OÕe˜$¡ÊÁò†£Qê1˜?ÝÈ0_‰Òˆæhª+ØX»x®KbËÓQ4N/À ˆÐ`ne^µjU6ö@®}ÛêG­d6™&÷`¡T:ëëým¡ögú‰a¥YØƒÏgç.tôK¡£v…ß|ÐÄ•®êÆmëPFõ"ŽQ”þq8¼¸Ÿ»—v’x‡£O÷ 4&y#‹`O²€……Š¦jvheP7ceÐW™Ø¬(;JÑ¬jUV’=C}­m,õA\ÖŒ:6Ã'>¸ê—_à—?¨•~ágw€^¯íUèûÚE¤ ÷p¢AS9P`ï÷ÂQKbœÐ¬™‹,F9ïŸ @±ÅˆnŒRøSsÇ7ê;Ä v)°°Ü·ÊµG“¬Qþ	vè¡>©þøG\¤KUs|.Þä^çÀ¬‡•¶Û¡cë÷HQ&õ˜ÑÆ´'ËàöÂø“bíO³p¢jÞÄÖWkè›áY€uÇü‰
|ÌÜ˜‘êÍ@KM(<aâT5Áë²¸ÛÎ£i:¢õßŸd)n>”Þ¢]ŒÃ“0b˜¢í8y[/âÍíÍŸ7»›jÏÆœcÃ ž¸†Á°.žÎUG\Ôö…ó[\W{W.!#™j^z‚yÛ±_rN‹Ÿu×Õ8§mVWGÝÃÝ­Î	EJ£êÖ}ª¬†ò'=Ù5µôÀ_d[^áÏ9F‰ÃPPØÚ²°¨Ý»JÆmx„Xx„úV™}{úí qÔbéOÐÓô'¡`#KÇŠa
‘¾7í«ìIsª„ lCSÒü¥Z/`0Vª/Ø''}Ž2°€ùØÑÌç>‚k:=ùþ^À……©ÚQýÞÒàp®ÊZyK,G]F°(8’"…ýÈÖ@dóŸ›+µJ/ýµó‚·Sô«îC ²ôþð»mAÛµÇ\~çº,”}Fø°L"~Qö–òh–h%8|AÍ.n.z_Z¯¬pD~eÅPô<IÒ`€ãÉ”þ>ÌÒI”Mã(Ç‘Ã#ÆØö>L‡»sT•‡†Óôâl«o}²†=†óö™¬qÅfÃ9ò\çÍÂMWFsÛ{E+8ÒiØÿx»;ôsaþäaÈyá%¤‚ñ´«ûyë¯K­•Ö}w«ÈÛ?§ AŸ‡½·ðŽÚÙæ8Äx6šÆc‚‹ªu@
4XnÓèÝ›¥Öûý§yëÇ¤¥ZO¯ô²ÖéÆþ*-7À•ŸRo„xÈ’Óã6vuOÌéã(» Û©ö¸¸†Ëç çÃÈzê~©™Ä¡£¾7Žºæ…µSÁGµÔgÅ«E±@=ÍmzÖ”Š)¢o’Mh~`4ƒw·;‡ôŸcÏÑëcŽùXØ¥÷±cšu¾ûËé‘–ÃË·êþóîËý÷GÇÏj?&+?‚û‚þ¬=Ýy¹ üÄÞ³öS¶Ÿm`°®­þ[µþÚé÷3X§ŠŒ¥5|ôã7÷±§û?~ÛRïa‚ËKùq—§Ïëgõ©ºÆøÑ{²´è™OªnÆëmgý°b·Â
n´+}Û·[ÆòR¶	sE—<ëfÀÅ-ga¨çYí¨þ²Š¿Ñ*:n³#¡KØ€´	YNÀÎs\ù<pß¡øa‚”ˆªêý)9h—ÀÂélïíì»²q®˜ûã8¹…œ­®s×r®Œõ¦¶hé+Åí'¬üúZY8XÞÝ9‘mTèäg[á^Ú¬=¢¿V-/IíZï“Çêÿûd]†#Ü>zŸl¬Un”Ûk•(òI~­’äáŸh´X©>Þ[¤ì fýúh÷YÓ,7[­¥åašOÑRß$‚Eû)·ª2K¶‡9†©ŠnT€+=ˆHÍf‰£Íñ~fëy–ÁFÈò‘±²æÒB9¡5‹ÿŽÎÈédFZ0zÐ±(U¶¬V~	ûkóPÆb—¤ÊHZ_/c•Œ"?ùÅxhîÂ£²rcþ·Îÿç¼Íß$ÿ~•üÿöF{ýåÿ·Éÿÿ5>_òÿ£ü³áþUòÿ%ó;¬c²®ª”IýÿOýÿ×Nä¿Ó,þNáÿUóïÿ¥ßÿŠ¹ö™þH
Ÿ~_Jó>þV­ŒÕ7Î
Ã£Û§ÛJ®ýííËcÞŽ(V‰ÊåsÞ.MÏ¼½Æ#%Îê×¿ä·ÿªùíêK~û—üvõ%¿ýK~û—üva‘¿~û‚Œzƒó¹‚ïKvûð¿ä™`žù%Hÿyµ_2HÿÅ2H¡iwÿè^¤5»)WÈê6É`õù©¦Ü Þ¾¤‘~ÕÞq") üðlQ¶~Ûê³¥ƒŽ7ãÍ.¥„þù ÇsR8ÇÐÐñ --k=O·ý=°yëÇFëGÕ:¯¶\Ò;É½]ªß¥ù}lŠß‡¥÷ÝœÚÇQØ^am+Xµ0©‘ãK1®w“Š:Ï*ý"…NG
tO¶„ƒ143/û"‹ÐšýT	ôÓD
Ù&rFÃÒU×9é<Vî¨¢!¡ãtwçcýœ v¡îÿõÞ}{\ð—Þl
#oƒpØ¬—e‘ á»ÎÑ>©}MOH!äýX1÷9p^€îqQNS|GºÝ9é\·ày$ûÖ,‘Ìd;kKé4±y'VÉ„º%î½ß0 âñQ[±cÀ4Ææƒ[?.Ãë?â(š–Z?¶[÷ëNî‹cDŒ—ÓñM©(‹g‡—êôÀY-"kyƒ²ƒòø-ƒ+ì!2Ð3u¿q_ÁÿÕ…íË¦$º$v'…ªnÓéñ5Áý1À…Œ’˜ÓH²>gö\	Z»¤•bæ£TÃ×1œˆ¯›“²ÎË†Dæ(1ø“¯È,p’õ^È°pìFP? Gew©Õ³Ž6ÕâOjKNPæé,ëE^o@':uS4%ÞÆ`ÃFš±üÒ±W¿?½4™ÆÉ,2š¤L—sÀü¼;ö?Ü&½z»ó±‰`vø< +eÒàY<•fy.®©]±w<Œjùç@Ÿ¥—àO^£¨]DêÎÙÖuÏýÇMÿúW9mñú°Œ¦-ÐdY«¥“x‹ÕÙSwYIµ- ¶bZ~–™ÚlØ*‹»ÊVÏyÕÊD§óü'åÔÁ’û¾ ƒáÅÃÁâvgœ Í‡IÍoµ”{^k¥ËCX„GÜ¯ËÈÚVtë_$Ñ™^v”¦S–`ýM”b5d,`çÜÿá‡Í³Q˜¼Ýüé§ûõ’`–;ùÝ^»0ëÞ›qÒÝó<´Ÿaj¡÷DÝâë÷[?Ö?ÖZ%­ûç¶E¾Õ}Ïæ§‘×©ZÒ/oN‘T‡#[Šp;ÛvÖ_¬ÖÖÁÞ^í+1Bwö¯[qeÔ‡ýµ²¢óå9Âo·Jø¼ÕŠªabÊ ‹{l‡C@…m!ƒƒÍÓíðJ¢÷ÿí«Ù}°QÒmñÊ“‡¤K?c¦ªG’çWØiø©L´äm¨³WyY9‰µìq^2È(¬ÎWu¦W!º·%q‰q .’"6Û°Vê“SX}Tü2 ïÔJ®%l×¨ÄsÒ×p¬ÙWæ‚$Áäò2ýñoíºÏ*Có—ýöxÉg=´¦ _\àKâ|õ‹!»ð^„ã6ü{Ž8é§—IÄµžþe»î¬ø(Ã4œ¨ß¬µÂ9œ¸4\|Éñ8O´Bi9üÎkÎ›âó•õÕU×åRZ\ºdY|é…5%#…¼R×ms7N–›³K¿|þÑ?:ÿ—•Óß¦þwûQ[çÿ®?~Lù¿kí/ù¿¿ÆçKþïo”ÿk6Ü¿Jþ¯˜·_ò¿äÿþ#çÿ®6Ûÿ´…¼Õ,`ô‰ÁŒ^ïîÞzB<)½fÏ™!œ ßí/Ýîá³õ#Àögã³(Ãé}Eosd4o£hÀŸ`¦ç³ÚÊŠþûãäj öõbžIxþgNxžªoTÿ…RŸÕr_¨°³»[ŸËLÛ|œý¦pÛbªÑÎþÖQw¯»ÒÙµPñÇy`ßªo¾ëvÿrláÚxéî@•Žú"ó¯Ïƒû%o{ÑVù‡ÊÛþR—üKÞ6õñ%oûKÞö—¼í•¤¼í[¥mIÜþ’¸ýq‰Û¢B–·¿$\/ ÷%áúKÂõ?UÂõ]×íýL¶žn¾ÝŒ7Ç›ÝÏ‘l=#€¼c•)ËoëŠÜ]Õ¿þ‰Úw”Z}R/Tã8‰Çáˆ¯0#¡Š³C7@[EçMø/útiWüíº°à¿ÿ=á£‹ýû/Í_2š¿d4ÿKf4;	®·Èhæ{dôK”«U®8‡Áñ_¥èµ‚p„! ç«#i½FºÎ»ß/l˜£Óv6JÕ†vsª„¼žÁ~÷»Sô‡î8¾ž×µzp°»m ÛÃ6¼^.X¯ÓëÏ;[y}xzÜÊãNO¡SxIyo©¯Ð„¡1í
H»Xô²BÅËþm—æŒ‹DõæòÀv|}30Œþ‚4žeç¼Èî	²?¥/™íÿ³3Û¿$µ;Iíúí²ÖaëcéÕ¨ïlA«5úiï²Ù(¿·´±o1bNŒvÖ×Ž¿}Wâ v"ÒQUZ´À#«ŽÄJ¶²æ××h^Þb·AûÒ{,ÎK¥Ÿn™yìf«ªµO
‚ßJ“A|n—ñ#õ
oÚqÃ²¨•Ã¿÷·ÁQËMéf˜ÍéùßÙß:Ø¡¾7ë¦¦ïSÑ	óê)WÍ­øê]Lïú¢©ýèé4Q˜Z+ìq!zó';_g}t9é¯Röx,·º³y˜Suú&&+ŸMâþ<<WaY’×[…äõÛ'®ÏgðÏ+7õä§ß*7]zùèÜô›óÒKá˜ù¤W9å[¤ž,’ÎlšbŠV/„7Hë‘eºŸcT<B)Ú ™É3/‡Kæ0·‚~tÓQ„Š)Ê]n68O
ÚmúÒš¯§¶•O$dcµ’UïÌÄ›ƒfó§±ŸºS¤30‡–ÑÛPwyÐõ¹17}\Õ©Š-rÓ©Þ—Sðù­ž¿|¼wïÕgêcqþÿ£õ‡tþÿj{£­VÛ××Ö¿äÿÿŸ/ùÿ¿Mþ?o¸òÜvuÐqRRä	–]_NücŸôg‹è7ac^ÃÇ¥?#4Œé”ÐÎ¤.®æ…éƒäéT]Eænñ¦ºã)Šñê€<ÜæÞkú+FzÐ^k›|>5ô¿:=>x}´Õýaõ§ëZ½¦žªÉe¬SøöîYžŽfSDÂ*‚Í„,^æâìùÄ@‚„MFö’ÛÝ×»xeÍ6 §p§ÿ×È>­ymDõu±ê·òb+ÒÎ‰9M÷N·@!ôúí§¸ý†`ämuvÝVtŒ}n›ç RXœƒÓ
CPÜ*šöæ¶BûR÷y>·ÕIwïp·sÒ=–¶xKß7Œ}ãðè`ûõÖ‰;‹I–ög½©•ÃS˜Y!MãËöZs­Ùn¯(5|±÷Ý‚Æìc9ê’£eçå³3ÿÓìó&:cjA î™ÑÚ8¿ãjÁJ\ÏÿY/ÂõµK”N?Š4ý­·‰?çÛæŠ“ïq}«æSsÞXÏ,Xêb^[šØ37éäÄÔôý¯(—Ôp%PVáw¼¤œHØqÍiwƒ4•Ø}i"&$K €ÜcÈËy½UOŸˆŠéÒ¬B;Ó××;ÔRH)iÞØÜqáìX†(Tjh¹ò$t1ŒaÝg6ÂKEÎÜå¨];àÇqÞc¸104šågÓ>`È&ì£¶À±Wb|æ¹!n„[äÀÓ,\&|3ð2ËõÁûŒ–ÁûÏ¯`Óþbè½=Ä<¾ªõ°\ÍîRüVZc§ã»ôFUà“ît}Îh;ÔO>µSç:ÿ¹ó¦£»4`g?‡!£9G!Ì¦ßó#lÏ(º¦Qø­Ž£áTÃÁ™hoËhdwê8^¹—­‘ózrrò=_‘Ùslõ´Þ{”œ˜CDÑ»¨7£a´„UšIÑÚF/¯üI~ÞðôJÎÅ¯[!áfÎûŸ=ùÒSU"ós2™y|Y4e‰j‹01c4
-5QÕÍHÍ•µóˆÄÃéÁqFÕ3Ø;C~6²1v¡Bëo]i‡æS¤;'¯ÐBÄY>uh+Å‹?/cMY„Ðã©NPÒÂµ¨”èðêÎ›îö):Æ®¤sG mUöÔ,á7¶Dàª'h "eƒìÕ+À3ÆìGNu"aiÄ•ÏH&Ž©UMPgÅÞR»ÑÊ÷µC§Ž}°†dðX=˜*Éúc¹„ŠÎ’8ûXJ»ÂÓÍZó“kUR=®U…Ê€Mšr2’MúŠ±¯mY[‰ý‹T—H0™0ÿ¦”VXâ+ºæV&Ñl6íØAmžjlÍ¡´BJ©ûÈü=ÏÌ½Ò¶6i®/.ß°­sn¢	ß\»ÍŠQ.Bý(‹Íå)<G˜¦˜G÷VRë\@Cñu'(ŒÍªØPùÊ{\¾fœëéŽÙãÀÉÂÔpŠvDe&k¹ÍIG-nL¯%YZò¾¹er®3@Ia-dØ~xví'&ÌJ¯”ùgMb®6÷‡*O¦W^BQ!›±¬gpSTSQU¼ÄP/oÕüäsý‚†QJé¥CaråÃÐ¬Š]âN³ykU<O }J2ïÙM9¼…EPŸšÔëP†8$EÃa+@ÈÄàpÇ:¿C;%JÑ\ÍIx¨$×/¼bÒr½®Ò¦´\™‰ÙÈwBs¨¯"¡¼@wLsóèíÃiícéì®iŒèë³ea»ºc˜Oý•<£PäXóèï)Ry·%ÌïvpÕÔíÑßðpÄü°n|>!¹¼Ú®)mÖkÿç`6€PÉ'QB/˜rlNL´«¦_1˜Óó@,¶x?¢ðß|Ö@«Ä²±Mú§ÃþQØ˜ƒÑ˜Ž#y¿ï‹áÉŸñpj_ªh¸‰ŠH:°i¦ "ßu×¨")™ÙòöÎÑ©üXKßzÅKæçjóÃ?XíÉîö+À£[òå-gy;½ÿéOVþég:üÆ\c–ÚÑ±hŒÛÇÝîmF)#ìÃâüšÃCŸéOøn<º»ºjRnà\ÕVr0ã]9eÈRþ)©cð™×Ó,ì¢SòðVáì6 ˆíŽFM
R€,ž?æ]Ao92¦:ð¨6K©ž•/¼Âá./Y,×KoòZ)ïýž,½­œ­[zNÇÌ5¤=wy}Ë=YÔÙôîvçP"{VÎP°¤uQ§¦Ç~[izz|¼[jÞ¡åÊæäŒ(½pä¤%Ëkú…£îáìë_e¦·ÚÂÅó˜„S:Š”r‡‚) ›­–äß¤.ÑvÍÇ¥1¾:99TþgÞt°éqeS;_z'{ëÎ«˜x¢s6)‹MWbŠhÅÃ>ì‘°çù>ƒàdŒáÒóYÜó„bÞ
Ñì ß4Á]^+âÜZ)?+}­úÔ|ãcîñ3üÜÓî‚t˜8‡@‘›6vÏÎ÷UèÛÈ[ôËYúJÛ¹\a½îûx@k> ¤àö°îJJ/ôõ± ÍùaÑ4¥ò¸tnû¹5#òÜž€“ÑÕ^·–b‡™óà« M\€“Í>Éâd:P÷¿ZÙÈÕW+í5üï#úsÿ›£©Xž‘¸"EîŽ·Ô––NãäôìJµ Çµü‹Dbþ&B¾®×P©ò…´cúÚ}ù9¹™³¢ïU‘¥‹…¬ ³7[º¨„pºÏÀÔ´Â
šj:}Æ¨C×Á'(KËüÞòL´h ~Q‘ÙlüˆwÙ}øÅ_cüÐOivÞL1´”7åe%™[ñŽéá/sÞ^éáñgŽ×ªnëQ•_"!Nc¿?›ÜÊ§0ø;ž¨€'ƒ¸þ©
Ê`%ÉWòQ8éÿÃÍ»šÝÙ¼/Gùo·Þ¥ˆzÒ
NûÄÛí®!TRbÌŽÇÒ_ù$åÀ©cXËHOæ3ìýÝÓÇdÍ=[jûòh%[`ú»†]µt"£Ðú7·çqŽ¬9ÆÕÜÓi^ª‘É§õ_¾Å½2æø6¡¦2­ øñÕr"_g,¦¦:EèþŽÞ¡OGWä^u^*†+T$t¾–fô³ù5gR> G#(åù¤y»¹TÛêÕvº3€ÏQÄÑc!ìn¹%ó`ëãŸƒmè4ãq–xÎC©\Ñ²¿ªè«ÒÏâÁˆÉJ¢î·Èƒ@n:ÃE.Ó$!•£Õhýu©5¹¯G`…~¾Òœ¯`´)JèÒ4±0âÙ3ºçRŸÒ	ö÷ŠWßeobAy=æ.º‡¥IºîŸ»Äêçåg1ÞžŸ]¥³Œ·fó6üìžæh¸¿é{ó®òò™:œC	j:¦TäŽ.‰;†¥ëðqìO§½´„6í‡O¾®nÃädÌ.lûèá£9m‰Þë?¡í“¯=¸Ï·?£Õª$AÑM<ÇG\x«èv,9é
m]¿c¥{Õi_t±Îñ¯:o}¬%ëçÁâ¯!ùˆÙ©¸³Jò‘¦í‰Ù8¿½ ´²\"YV™xTfdsUbúÄ—½"Ö©h»ìžÖbÌ±ªµ
/¶z?þXxÄ>êMC§›nÚÚ\òÑRsçv³>ÍÄöûÅ™`²À@ö½;ñ·ßÎs™kf%09È%ªUz`eœAbñ]·w<žßïFÉùtÈî¡öêuðûà÷÷ÔïTÈgYÔÀR""²ô8Fô†Éõë’#ëxTTmx¿—½Ä=pQÎu§(§ô¼üžêrþž›TMVƒ+¬N³Yä¹¾sPA°
˜e IA|ÿ¢è¢âžªuVþ¯påï«+_×à!|Äš¹vL¿(öý&ªí{bqà÷r¬o9ÍÿøG ÄœäÖƒ ôOüGÐUñtÔOJåç>!ž~û¶H‹äÏü¼™a4ªˆÉx©ÔDŸÝr‹ÝÝñqY-¶
y­h°ÛÝói§Œ-X°x^ŸìáÉ LçU{Dã?_IZáµ}ÉçKö%ÿyá%“ë|ž9i¾ŸÞœr“+šãóBs/Fà4÷žßÁ;ö´†?,ó¼Ð^g¸§¡Ÿš»gQÝæÎóê7ô°âúùÊ}xí~ù=o*Ï|GD±'Gâyo8ÏË¯øáûŠÿ|AW…÷N­NÉÈ¯z¯bj(¡UáóL‚;MånòRS~^õHÿ*Øø¼ª9¨•Íá¹×Üå"ú®¶Î(óð£øˆ…TWåR}¥`„ê¤sÄç.$.-Z Ha‘
9‘ñã’C°-9¯a“®qÙ7³{9W»PË®^Rw@¤þ¥e/éÈ”ÍöÁéžk¶ÅD€‰*`ÅùÆWáéÌ}›nîò2È€Æ#W&o€ÔUc5ó ±˜“¾èª ÎXÎ9 †>ˆÜ$ðø lÎB1Ügß¿[«†€UELœRy­sKˆl`ä¥£…ƒ5UázùŠÌO#^„ÈzùäV2ªMúÙ=üm‡I–RŽ©”§ø4BìÔ	ÐèFÆõ‹^ŠÚ’¥
*Tgw§c
ÓS{Ê‹†QHjt¾Ü|P¶|¿ÿ÷K­Þ|@ÉÑÊjzXu“‹Î…±|a,ý²ÌPê ¦¾Ôúq­u¿Ê{ùks…ÂGÖ"‘rXþ¯@É–Øx­"fµôž&UŒŠã§fÀ_{É>¨r\e!xÁðÏjÙèø}9þgøE…Yä¨Ðêç{sM…x±A»ö”ïizª•íðä3N>ÎyŽs=ûÐ œÆ¶fh|mv:Â_kŸÈULH]»êOÂFä<^sr°ôŒûÒ\OçUõ^A™¤q¡Ï0¹å˜ÃÑ(ÊÌWsâ×¡ko8…áÞn@…—îhH[éxœ&‡ÀÌž-ùS¾G¦Q’^R»£(åàY­æ<wæUóº·d¡Ë«æþÓO…ì¯$“}Ú6Ô8
“œöH˜Üe=Š‡Lm¹˜ÊqžâbÈLFXÊL-gQÖó^vXžE‚S²È½sÊé‰2èÕÙeÿK¸®sƒ%‚¾(«Å…gÑÑ¡ßgy°òwµÄ(­¶¥5º›ÍÉN¶QK€•¼›|ÒöëÌ‰Ö£U+÷ôÀuè0,®v–’—a]ú¦C‹>=DË0ô@ÀÅè¡4Ñ B€[ÄÀÐ§|¬„ãƒfQò²ÆZPøs’&+Njñ"Í.Ã¬/k¶˜òô8pápù4î½¥«Õ'$Ä§)¼;”Ý"ë“8ëCIïüÌé¶Œ¸ÜÆnBÊ- ateš…*ae8:íŽÊý¼w€l¶}A*BÓÅg¹ôëîî<r/©ÒÐ[{ÕüãH¤ÿšE9Ös÷6Eï@ÍÎåX²>úzçÎj>C–D—žþ=ïN›ƒ×\0üôøäè6ÉÞtšgÝW:âøÞíäÚÉ	mû9«7¿PäzÃK/éøõ¯2s%6{ÃKgoxõÎd„éå1[š¨¸xÂ’æí#7EX˜ ;/Dø1	s‹:.¥îÎïxÎùäžJEêMäÂ:
}à×©(v¸*G!—Î‹ª¹?HlÍ¼µà ‘>ßéÓ‘
ä--k%°¶ä'Uç¦ÕêEx¸ÁæÍçèç…Î‹Ï}Jr¤ Ssgñš¶*éýžWÀ¡ìï3Œ¿¢Àz¨ªQV^ð» ÃÕï±Ê§µa•kx×”U
ûZ •é
(39Ñ}ÓItßôÝ7­÷ÿ.²Q¼×A¤_5ª:7D]Õ„S\°>,ÈbšƒM…™‘C
Á£Vø6Šìr¢µÐµS	~ÞÕ mGlPÙ)¯z„2—?øôU[DPEŠÄÝ%E›NæöÁÚ9´Ûògoýæ[ã¹õoBµŸPÑ2„Ôíœ˜Kµ1rEêLM‰/”±\—*“(ós@~ÖÌ»?ÝŠšªX˜ï/µx÷.Öâý¨±ÔoéE]'ãÖ8-=jEûßob&Á;uÖèÒŸ›‡éõ«³ÔüüS Ÿà5nzQ¨}*t{0»ú4÷Gaæ6‡¾ÕGcæ·]÷›*µâÌn	Ô/-ˆæ=V>ÄF+U0¼± ›)6½97ùü,N6ý9mº¥#åw]qñÃl»;ðÝ¶|bí7Çî VNµj·ò…´%±?‹¨¥5ùa–ñÔ-RZ¬aí@ZX¼ÚmGƒqÇR,Wø)£)ÀºiPÅæ¦Ü(º=ñ–d>¶¦ ÕœM¹£úþTŒBŽÏ-çwJËíœºAÕ¼d¨sß÷9ˆIS éè±[£ÏàÀ÷{VIþ¢þ‹™Íé»iõþøn›¯äü`p¥ÂI(;eÝg» ÷óãù•Kà~u­ßùäÄ¾™;†ÛñÜæz5í¾q‘öí­‡1GÁZ<˜Ê—,Ê—ÞcékòP¯:ÊWÀª,×E$}<ï¦Ý"ž{ñ ³	%n%­;Ñ‚ßúv§›?ý´×úÜ},¾ÿ‹ïËâû¿ÖÖ?^S«íöÆ£µß©Ï=0üü¿ÿ×wg«»Üýl}Ð%oësÖ¿½º¾Ñ~XXÿµÇ¿Üÿök|TÅçåþkõ²»ß=êìªÃ×Ï<”H))J>o$gîaC­}­þ<K"µ‹ pL®²ø|8UË[uz¨^dQ¤ŽÓÁôV¿À»=é(Uu¯©¾‘Nƒ|ÐL³óÖ·ê^DÙfFÄ9^²9Ž§èœbprEúSÏ’Æg‡¶g õÅ	–ðæ¼MxsÄ) ùJ‹†‚öœâ‡™—±ÉÍG£ô2ê7ƒyÓ¥Ïa…cP‚°Õ	¨H„5Jì©ÃÙô¦¯C¸!èŠQÔ "*JÍ¿È
rœ
•®Woã¤O™Œ u½Í›ºy+—«ÂðúÚò»<‚ÕòùeªÞòøëõãå7xº$¼¯ø%m ’:Ô8ó‘t?RÏ¯è÷,Ì§`zãŒãd%}^§óY˜…ð=*ö”zÄ$IÁ¤ù‡X§å<Ç++ÓÔŒQt™ÝREà,é’t ‚žÁY`èßÑAšhéÍ¸ˆz°`Nå)V‡ÎæŸâXÂÉd£2¥Ça^X˜™WÑ‡yOéÊD‰ˆú³+aH×ÿá¿Og˜2Dð7„BØ’ùç0…4%JøCø—f½„oq8ˆ3žþ„óËðn<Ê*ÆjÅŒs¼·vL²ÏÕª _=[Ÿj”‡zÊ!‚¡”ƒxuHÈÙ‰¼KãSË²Üxq2’?@£ò	 ÕeœëÓ¦-E˜­'ªk/íGtUDHÇøiÓÒ‹Áeˆé¾SçUlã±é^ÇÕ†±õxt$A'I@ã´øæ¬f÷q4Ü>åÌÍ`)QÞŸ)¾:Å,*Z7b{9­F1'YtAyÖHâ‰ƒá
×'Á0ùEg˜¿•Ÿhw’ãœï—Ö­šÄ`¥S\xlˆ‹ô¢lR¾1Èã³xOc¾lU®’‹¥vèûñ Ir³†…ÏpÒ.!à¡9f^àÝïÂñdp Ÿõ†vÇê†œætŽu#´»Õ ’ÉŽñt§h„Ê½^@21 L¦9Ï(GŒ+/V_v*8^ª@›®¡[é1¶Uœ‹T>r!ÊB¹•«œ†x1Á_±&Â“ÜaŠ¤A¦ÄŒöp·Š¼8{oz™â=¡“|3Xn×^qšMIÖ°ìEäx‹‹”½¼Vœ‹`úBÆ$›?8/4Ý¢s`$us’ñ"vî
¸qG!³ê\UZÏê>û:˜åÝ×Ó!þKÓ„)ö€OfÀÿð¬?2÷@¯D±xæ™¡,¹"R Q{Ü¥ÉŸù1û§NÓikl»ÃhcœE‚ï±\ÚiÐYD‘½¥bÒœhð*ò°bâÏ Œs¾\®¯	§‚›>…¿’(å£+’<$wd1ü`ú#¼Ó^ðK¯‚#·ày©î­Ç‡R¹÷G6K‚ò4
›_ˆûD[°ÉÂÞ«z>¤&ã0™@}€MÂéò”¸Êt@6ÊLTŸð2 „i°9ÑÄ¤@Â9@ ×(IVÂ‘œ™y™Ê¯€”é¾Ÿ  Ã¾I,k8Ã-‘öz³ŒÂ~ÔèaŒLºÇ‘U#Ðž€„û3Çˆsx™IÜ£Ìã	rˆ<‚á_2]ñÕ³(Úg	bu2Eï–ÏZ/#wv1!ú°ˆ IŠØ|:)®3ÖÆ"¡×¶—j“NhÐÌ…ÞZ”ÏÎÐgÅ¼	Ë¢KÈ½œ4ü½Oç>¨ÆôÕ- “kf‰%¦¤ô²® 3\]C{K¦£¬ÒÒŠÙM±³RE;<Np|¡‚®Ù6"s:¤ â	tFšÊˆtC‚üùVãèÀvM’þ­ˆ„ÝÔ›jVB¾œ=QÃÀê~|®Õ™•	'ÿë´Ü,guŸˆ&Í…Ã÷SÏ¨tÐÖ¼HcÎïÕùÄ}$ÒŒë±ªGb­ÞLœ.°
HŠ [xkŒ5 sE`j^5ES`M ×Ë²#`Ü3ÍÝìBa*t-2áÃhºkÌ8Æ±KAˆ\äi\XÍˆóhtÛÖõ‡Ë©'áæ¦H\ù¶ÐI÷hïXuö·±òÐöÎÉÎÁþ16^mâù¼8áéýÚ‰#cj¬žÒúê]ôÐì£¹Z82VenÎº7òne¿ÅK.…¯³Jù¶U@–MCX`4ŽI3. 'ÌßšqG`î¢Ýa£Žoú$8éúb£uÊ*Åy G¯T7„Î¤	[†ý>,yÎ÷Ô@äÖ UM^ˆò-IÍ*55ÙRƒËã`¼`+‡‰Tþ7
iE2 á±Éñ±œ9aª~8¡m‡_è”‚¬¾à™!5ó!Ÿ¯A‰,ÝjV9h†©‹R`ÑŽKP{¬•§Ï(ÕÐàâœ &dàŽ«É˜ÔbmW‘6HÕt,¢F»­Uë¥ Úà³š "ŠeÀ°»Ó§,¶ž ¢GÉÏÉ¸»ÃsÊ£(â¹OdBVËG’
á´¡¯3\ì]$Â:2º€tay„¤	Ò¾Ž8ú‚¶Sœp5è0—ñ§µ°k›Øô;”múš<öyàž4“TF‰Ã_Q/ø ­Ù¡Ì	$ÿhÂÐð‘Àã#Ë4Y §omw™
xBææAQÞƒ	ívVPðè/ºB2#åé›°e.£ÑÈ¬àè"*’;îSÜó¢%˜)oˆŽÂè ‰_ÌZÔ¨Äe+°°G:Cè
ùÌ©$¹ˆ‚u© 4‚êÓÐå¤Ôô×|À×a†¢L›cA8~¼Àh6±ý\DÜ= -ÒE!€it&,_p©vI_ßOQåÈkØD¤0å±¹+‹rI¬%* ÂKI\£®ˆrc¡}azfw…éÛ’[Bý;#˜Â"±9&XZ¬Ô']‚Úp'!/Ä¢"“Æj‹vh›³d¬‚k³+<R2Ù@a
&/ŒqZ¾389^¯Ã¯˜$ÅÀ\‡F“Ä@!IXé	±e+kÂ vì¬ÁÆ.cý ‰œÆE{4ŠÈˆEÆ˜Á¯À Âh7•D¿¶ÐôÔ2¿æØ£51•]vÄj:…ð43¬vù<ù·x[º›•-Œ)
¥ƒ³Ÿ#âàÞî-Ô=ä*W4ôï1ªªaÖW;iöu‘¼™!Çô˜§1êa¬ì"})¨’!i;™‡—tI0ÙÒþz/•t&¤½é(wîb$Ñ¶ïÍF¡ñ¶#Ðþfá9:C^€Þ; ´Ñ+cá8Å#­ÝŽÓ&Î*ìEƒ°ktLæÔY"S«±t®lÕÙ£F|ˆlŒl¥VHJ`Æ¤#]*h9¬³÷•Þîk$$°0Àd}€ÏõÞ†çÌä÷ÂŸ	[À®ÒÄ¸Å±„\ÉªÐ5œæ´ÇÏêŠª£#†u-f¬¢¢Û‹‘¨,õ‹[HÝD¬á«2áÐ‚ñà@£0mE&å%¢X °,±.DÄzl‚Za5!Ür)túnªÏt†°9°)êjd˜‡§—‚å·`¥F#dñIÏëÑ3j@=‰gLp¦¼žBr	Isã 8ÃZ×Q"ó™qûTö}Þ`½»GQ¦Í1+­ÓžÛÁ.²Û–w0©}ajŸQè–Wü”ÇNb&• i4

Ž1Ç Ô¥¥Úc!Ä3àqÚ¹›®ÓÀšÛùdSíj²Se‚'|¯œáP¼"‰ÉgõXúWé%Z­‡&ŸXï9ö~·+!µhdNÓ”•pùv€%D
Oh§²¦ÝL¬9Gé¬M 2Ée_2îÊÀ¾ìoKm³ài­ZÇÀˆ~G‘0v—¸@34í¡Dïóv•ÕäÅc/h—ÂÅÍÅ‘$¼TÐÆQº«$ó5Î^ÊŠ|{vfPcJik@oB¨ë·]#Ðâ£)°)Çtgn8¥Í1ž%Úˆ%s—Ia€¾…3PÉð®8vÇ¸cp¢h¡G1èÕ¤
¯ìâwiÈ¨ýÚ•›åäPË"[aÍ½ØZ¬±rß^ww·x,þV-ò=öÏ FÏ¸ÙZ+ g:4	›‘°ÅÙ|NQ¼~…ED©ÖJúPÚ”Ñ‡ÚÁOþ`Ôa)-Z—cºBïP?p|tËq4Õ.IÝ¿S6­ä&Ÿ%£x#ß‡­yKÙêãŒÐßyU qBÂ2pmH2XåûÙ•’‚r¤…!5Ô9(ñÈisâK$òÈ9OgSÑÅ-ðâü@`'é%ÇçÏ,Ða¢ç1Ç´PÓ$ÂýqŽX>ç¥gW¾MHLñP“ÇäGÄˆ%ÀF­7,'‚¦-ÆY¹6ö¬ëfÊñêQD›¬…Žy»·³“[}@4“Ô£¥½ÐyjbgBct”ðateÃÞtÀ´É„óuY°(F³œrÆE]0Ä¡DäyÀuŒkÀ~õÄ²eq9”ªcŽ “Ñ¯½ò¢¡¸â1zävA¾•Å¬Ÿ‰„`bë2+G´ÁNÌYn|,î ‹ÈT94E.}°%hÎ¢a84dÓ#öA îñ!âP´‘inìuÞcÞ2ÚÀgÇ÷8žm¦õíÄrtHcbT¤ÖkOXÁ›D«[oâì0qö^œõfc]ÊËAAß9–F‰ÁÀÌÑË©Ô1©‹°J¤Ä{ù OÑCâ¤½JNÞu‡ÖØ=»8À‡Mä#:îñšãl”ñ†}èé€´ZÙ¢!£¡îÊvÜO½ÅCQ
$r†rtÝ¾û¨1i3,Fo˜¤£ô…	Ø–!…1-Ž§l{5˜@šˆn`Âç²;¤=C „µÛZ}·sxà0Ž):÷fÌZÎÿ][UÛ€†ñ¼ÞþúëG¸§‚/šTäˆÕ$¢IU\úäIôÐ ±=‡Üf<ð#®àóJŽ_†ˆœ¬Ä,aÑÈ¢ â?‹A†»ñp¦tÊw™†á½Š6 #ž*¨­Y/&‚–\!‰ˆM¤<Š[”E¡Æ{#Œ áL(‰f*"‹™6H«ñ]õ®™Ev!ëäð8J»’	,•oWÅ%Ý¤ÁÛcªSìÚû‚L™™ÁfiÑ‚jlÒê­7}ûFçgm±CÍ•@²º….=1‘Ï÷sO¥aáh7¦€ Ç›%ž«Ùt’OÀàç ,Å‡­Ã5Èò!Rv„þzÉ3[èìzÐéFX1ôr‡
¦.²£úJ_á E«'&fÓû=ìQéVÅ…=¶A&¥þ‚þÂ3°\{óŽ+ãs{JÃ8§Íæ›“>QíƒV©öf½áf!9»»¡\#E˜äoF­î¢ "è€p8?!ŸM(……£vÚä›BCØp‰mOëv¢¿qíªs=ý%EU´¢cÌØÜ±hŠÞKâ{ÑN1—j5‹ˆ£"è¥]¯¢X	sE¦¡Í]A¶Éº°NÊ+{ýPØ÷ aWŽ“±’(M–¾â ¿Ž$‚„”Àv)VXÐJ¢gÕEÛé}“WeNðÎp%5ïn+¸"0µª,V!ùŽd6ìôt@ƒH#!ÔælœšL´W·9BZ‡%Ì/3–°ã‰s"ø¾žÇÑ—íPWd3öEšçQ®3	B#+  “©NJ`Ðp÷cAÔnÁ´ÑgT{&¢khîA£vÅ‡f’EIÖhC–ì<Ìú#Ì;A]›“˜®ØO.EJ¨òd,¨GÑû¾æâR[«Nâdx%1{ë¡aâLÀ´áÊjœ;aJrejäÞþNü\'{i7—Rýº.ŽIãíñóC-€)âWc§7A™xyŠ¸ÿ’'¼Š=É„ŒgZÒøz)M:·–Ù‚fa|dø.Îé;ì‡g‡¡Ñ|Šé‡1¯1'Q¸~„w¢ŸSìßE¦/jí	‡‰HqòòŽ<E‡ø»vF^}!ÕnV7ÆYAyb¼ó4ÑØÅÐôE:šqÜ8Mšâo^8R«Nˆ9	jáù94Æmc=R‹"šü4w¢ÔVäËÈíBeÕŒ„,geÁ <Å)-Á¿/éÉÁY,Qê²K:®/F/2zJÈd«Z>ŠÒÃÿôŒ¬O³r¡³%‘¹Úƒ}Z]A"ÚyäÊÔ}PVDœ¾€Å™#K}GI…ÃØH@fF•€9pfDþÆ\AèôÆ°1vV0Šx^¥G¬ÐYQ¥azJ"+Xù8"uËôWp¦“b fHÒÕ( 7¼ÊI–4/²lýÓN‹
­7HßOÂ$Ö~%æÕ®¾øk+¡êÏ2öŸiè%Häì¢YòÑÚt@À
'äYÑþ›Î9d¦–¡ýž°ØPÄõYÛ9ªîÌ¿ºŠÂŒ]·N–œŽÿI+“–V§X3f%“KìÔ0SuÃ;Ã#SKqÝ¢i¸˜’H&%äò"ez‘ß–%¼»8†dD¢GÍu>6ªé'B¿==4t„”4w‘âã”³Äk[/OI8á ¸îm)7¦!úŒõ~µ˜¨
S’mZ«˜‹¨UîPgXp’¨#IÅ±œÐ³Ã]}ëÒ]:Éèp¬L’!y!^«Êº:\8ÂTV®=çÚ©ÄŽâ´×sÒÌØÅ:F0Ð±À–h£"íWvSØ«‡Ï2ÔlcGòL¸Å™VY½hÎÆ?kŒ¶3¯‘ Ÿ#3ä§'*aPi¹˜³ÏëQgÕ’1h½ÔÎª/\p±¨8rA7Õg&u™rçD\¼g–±w©•Ñ“Ä0ðŽÜ†î
°ƒ¦¦)ºÎ#CƒôYi^¢ÝÆ\RâÇ™¼½cÄ!R"²_fÏóâwˆvëÍ¹âÒLÄ<„ÙåîH"—ãùvä/äh"ÅluQ¢¾õcÞð»©Q(œYæ!AåTkTèbÎÅnëÅºfiF2Éašó¹Ž¹¯7doàhµs“•4à&ÉZ¡N –Ä†6n#%s´9÷¬É\vM4w×ÌÈ/8‰¢leš®à¿œþeRþ4†	Ž<NØ_ÀÀˆ’Jw‘p?6ˆ „B=_ ¼|1·Àe’hµÎ‘°»FÜ7bk;l¢/¦[$]€Œç£3@´0Háº=b‰Àà„¿¤z‹áæð‚ïÀÍÆ=3ì¾M)±B'	ñh‡¡­ÑP	M¹ƒùlÌF5Ñ†ŽÉt
¦xV”fËB†4Zfì-7a3m\¹ªƒ,Ç qxŒh˜ÂïC¼K‚W¹•€:rlBÞ$œG}9Ú \°²/:¡4ô>fAbÚ 	æ^MÙw4ÉÐh±¤ýy“mýtv6Ì¸†vn£°4éè‚ñ</RJ[$Í#<×§mÜ*}ºÁŠ'ÊÕrR¬Ðìi¨š‡(/¯:˜^MHWL9‹ï%ÔiDXX}æ¹sä£QpKè¸ñÌœm(t®x´AB:^an
M<£GÉK½C'>I6"ç	G`àtÌ„³ìh`˜adÔÈJ´F®ËAç8H`õêýjÓŒ*®:.ðpg	&] Ÿ@’®HÒ&ÆÈ©Én³H5†ô\(~‡óvØ@Þ!NEëô w‹9‚c˜VÚÏH½¨†œ“Œuõ6ºbô2ã‹-lÍpûÎQ'r"p¾PTql«ìÝÐùxÞ ‘aé}>šÏ×è"oxè
ò¦*FE1#ÁÆiœÌH!sQ|­C·81­@sI<šrê¢a6À®"ž§æPhó,"3ß!åœašË8”$ÑDKJ¬ÒuÅj¦/vÇa=7+g §iÙt±ksƒmŸOnmf‚˜,CÝ•³%cdàzGí¡Ò¼ÕÄ´É¬vdœQí$¿jMgñôÊè¥[Ð”ª²\éÞôG˜Û+1ñ”Ž£ R„ñ¼}ÿ¶F*¹Ï"×îØÖWóöÁŸI ÉõhOùt°¦N"‚×:I9 ìèXÞ’ƒqP•½+wohR]³æíaœ÷Lº™ëLˆî ËŽ£ƒ½ºI[rÇïØQó¦^ÎÐƒ½Ë\pÚ¤GÝ‘ÒÑuôˆšï²åÜ‰ýÐžµÛÆà!s¦"«dèª!¤”Ðc¨9¾	(

c …¶	DÝïGä¹FI)…Œ*L"…gö‘—EœEÒŠØ½3÷ÑÁX.âtDñhr3)LFg8Óf7DÛ¬º°—¥yî’{¹ÂÜuÖÚ09äÜ¸gåæá“Iô²ñ‰°.û@—ù ÌQÁ‰¨BÎðü„á ˜8'¶+õ®-G`Òú¬ ©‘ˆiF41K0,BwtPJòƒXZ„­ÇM,­ã2'‘v¨Öœ§6ÀÇÁ²ÈM½A—|é’{S;Cš•|>QÁ‡ )ß0‰øÐOi±gCnÍ zÜs((‰5é´	Ž‰ép©‘À8g„¹ÙãÆ 6óa7YÝudy¹æ,8œØ×W:ó„Ym$éÂÊ±ìùÖYên­‰ÛÊqÏlªw ©ò6žh†Žæ›ÃUXÐ•JÎQ%áãA)=“çX éiWÏ`nB;«ªRcp¡Ôà£(]ÑÂúênt<;œÊ%dsäðÁ >£- °Äò*äi¯™ÍÛ•xQz)Ã€÷Ðˆ“šl\ê	2½›ul K0gøÈ'„)6$v,~²˜ü˜”ŸwGáC]êü½•y¶7ÉÛšâ2ÒIú¦òèóØÅ¸•ÑIp˜Ç‚÷s—hV‘N	ˆâl…‘Z”UàÝ¢a×2
?M‰~²ÁmIH"kR§_`|c^tL&ÖJ„ñIétfí¨)&9äª½AÌ´ý¨8†§¨cê Ä‘9nJfKvaÄ—=Âã¸Ÿ9äfÒ^84Êè2¨wmØüÃLûKÑV"W“eÔsx5íxjGß«ãö79o@)Æöòd0¬äyœãÖÒ¬ßž¸S£BG0s±E+ÄWç`è’ŽíåŽ÷Ð¸ax ¡)¿d§Ò¯ÃâÈbcË™TCbQ‰¯}8¼ŠŒþàð>ÕºpWÂØèzÀ¶£¨Ži„#F&[Ø
Yu38=ÎcóƒÂc¡5lÁ£hØæl\Š&HøÉm¿—Ò0à=N¼´:;§€‰^2ñÌjä_ù9ÈsoºjYŸ²-,£dÞÔõlXk‹¼T`,b›†ãhíet q\¹íDrrÊP%\sØ¤”2ØÅ]Œ_*`N0—+$±³MHf£{ô;äk5qÍ&”Ôœ»ìDôè‘É¼µv-\ýÀ>å.‰Ñ£¥{Ì©ölõ„Â ªÒ’­æå¼…l,j…3T±[ä,/@D§ÎP7)U£3ã@å $Í‚Ðú³9Ê|´ÅË‰vU?GþW	K”þÌ ¼{žÖ©çGæñªQ£ÝF9ìù6Þ…$ìÌ¿ë£ á²š[ôÛ€æpY(ÔLžI`s35(eP@+ N…áú5$xCÈëd:
9ad±G”‚ž¢ltüN)!ËÙ?iqG5´B%)ë¶Gn„'­sLD8Ó¯…¹c<Ø€$êÆ5dºâG ¡Aã}Ò$%NØáæ}Ðy4sbÄÖ‚*¬œè¦1 0ÌA™6”TN¤¢Z¨ºNñ¶PçÜù¦·ÀTžÂ‰U\ØT£|9ÿ”ÕT&yU´ôÑ gÇ»ÙÄJ(Ü`,…ŠØÃ‚Ž­~›=¶Õf×Ç+')Œ”wºô‡J’ù]©"NEÎS3’ã®Ž«º¨ *ò‘àz`”P(‹g˜j`¬Œ*õHïTUÒ\ðÇ"Ñ?ØcÏ#Õ†\F as«x À`yÓöÆ4˜%·µè šAãÈÕaÈ¯Œ5ùÀð£UÕ'­f0•• ó†D÷À¶M	ëÞ!¤[!1pèÌ©4%ýÍ$Žrg.ÁÍsiðŠÇ¬'â3[âqdëùá&¼@Ï¥}ž–õÓºµã‚âpí¡ƒÞLŒªÁïC¿d|Àp&ÆpæA±sÏòüµ´Ç|GŽqëÙ]‰3›¿R‘µ)²Ë*tú†é€&Š³)ïæ¦–+¦1Á"œé»/©Sw©
h8ÇÞÔþDvij*„à5^V•)ëe/£6ƒ8ûºIÞ¿‰\ùÀtÄ¡¼âm…ã:wÒŽpí2Ÿ(Q²Ïé*z À0é”Ÿ—‘dO?v’ðÍS¹Mµ”rÊ!yóIe–(D¨C\x‡—œ4¸! 8Ã’ñ`ñ&bò†:´Û 4Xrp£zAÑR¯ô›€Œœšw¤Ÿ~\%A8ç¼p3’“Øl9rÁgïëŠ–|Z¯büJrèŒ35vøè!#¹tÀ´!	¤WˆÀ²8(í{.7$é¾¨)w´ä“&¢Lo§—@ÑX¾M'¾ÐKTœÊpž9g­ü¨Š']5ŸÊ·l_c¢!qF[`³¬
z¡>ó‡"Hÿòëï©N:"µÈ{âs™1_TèÆBˆ³Ò­1ÖIT½xh<ÙøO5~7"dbNÜÕä‚WnI.VÁ¼²~(÷±T'gÝ‚É¨ÛP†+eã(;gÊqë}›·]©AŒyÌ:k+QåÙIš;‰¦\ä2pçŠLØYb—}p¦	&çš˜·ƒ[Ôòs}Þ€c-l¿ºOûtŠ’Ý0ä+˜tŸ¬«Gž8«n™â™Fãõy4ÃqÉ)Åâ¹Š¹:w
†\çŒ	Õ™ ø;%õO…‰åÈŸõÑ`€)W%µYìmä<&T®#orÌÐÄ>GòQäÓ¹÷yŠ´WBŒÂÀíßîX¬®›¥WáH"e©“BÇ§·ìXŠã˜W[éÊ1V›ÀŽifL¯—,L¥>ÉëO©ô‚>x¤t†®Ÿk#>puilvßFA,•€­pÖLÃf6R9öp$õÇ”Ý$^/·(öcŸäTI»ÝT‡º¬¥.9—°×1Íj:ñ¦ 2âž2]:PaÆ„´S˜Î«sh+pÒ16<ì·YnkÚƒ:EA†	»Ñµ)¿gÎx-m1í¥âûêÇž¨ïTãpâ©à†MZq}Ó°'J¬
RVõõÓ†–X<Â‚ÎŠ“ÂÊ\‚ê®9”S¦Eâ w!Ÿ‘–°X) ½2¢êÈ4Ouî(ðDÀ
Š’ÞûUGz+úæ¸ŽWš-æÒ…LG5[ðÍ&Vh÷ªÔE¹cø4í1F»ìrjb^=W…
Ò³ËÇ;í¨%,$¿†)?€U³Q«j®³Â5s<“Ûaý>Î¡AT..iAyY¸–²Ñ9Ûv9oq[ö…«R,PI¸w™ø<Â`G–>ý‰™ÞÌD¨X¬Wä}ªù“d&‘\i÷H M#ñNqø=ž²ÿMÎ—ar@*æKƒM©Tôžˆ¬[
œ.›²s‰†\Ò…¥J±~‡û»ˆ’rÒe3ñûs·ödËÚÖhk¦»¿‚”ÜÀÚ…))5×9W}ÎlKóÒ¤áf'¸UYNõË¨À¨éTàˆuð¤4T>¥679ÕUt‘?˜B ©•Ne‚1oRŸ‹îßx$IéÜö0Ð9N'…#FHS–¶¤t’Øº‚©	¨¢sÔI}ÕÄæÌæ€>G¬Ž,ÛDUž³áa­P¶Q(!EPt%ÀŒoµ@¦„»ã…1•Ë–š.G
nÁ‘Êi¦>¶.=Œ\³ÉXDö( V<üK‘XtáBã™‘HŠ)Î£¸º+
í(–’*(NÊrPro³Î“±þ¥}.<0>8Xu¶2ðßdécV7Õ#Æãœ f8…[
MKP4 Êœ¹¿j²L£8ºˆl†ìº†óYÈ	Y¬6Ã4“È+“ŠÂuä'Õ“…fÞæTpd²Ý0ƒt¦m-h!–p£d:ÓñuŠVñ!RÜìà(ãµª€ŽQÐLi!íkÆ¦F`8W]íÏµ”JÖtRA%tñ?Î.l&eqù`q.{zÅï‚?r„S¤Ú”6…µSDtUÃú#YL"%Í®jrÇf)ãt\ìfçdqfxÃT|É‹æëÖ¹-êeë-°f`Bz’Ñ^l
’ŸŽ:ß
iúFWQ80ªÄ“CÊ«5ƒQ0Yò4A@'¡RbÄšÎPƒ”$R{Ü‘üdú M9!18	¯Æ”ç”Ú€‚ôàU¥Ò4Ú¿*E¯81_ØJ¡FŸÛ_6ëf]ÒÜ°jëxeN¢ýt¥Ý¡¯:–ä’O‘áSuÒ2WðOây,Í$ÑJòÎ2çÏÅTÚ·oÜK\ê×Yx`ÆAG9Å3éWum¶¨¹?‚U}L;×<‘¢³X)8¶ˆ|}®é jÙZ`–ú8¹õÜ°^÷µ'j/Ì`µðÎ4_4ŒuiYÇígNjP1¹lfb|bN;©:d c$f˜jlZw ÓÁ¸i¼ºâ’˜¼Í¨È˜ºìfN·»éÔ•ÂVíµ&·:6×Áz Äü>ÝÌÕOÇZ+ÔûcE_ê”©emR9»U†áp†£?ÚÁÖ•d±aâC?î™´|ÝEUÈíJ×·D¢¸Å~ohþ»M«~òµšÑø">O¥¼>Z–ÇãÙhê{b8S¯T™Ës	è)ú¤z*hêö5/%¿¼ëþ‘âfTü¤è*Ò<QK<×§ëøî*ÔuÁ¢Ç*ÚŽ#ÈÁ4³gá-`0cGä…TL9¥"×Õ±/Ð ®ùHæ¢KÆ§@Ã ÃMÌÙ™:GÍ?<æV3j?lbF·Õ2ñ^ŠZé¢ë)>*Ð(”Å)É[áHX"£ŸÐÒÈ»yBòS+¯ÕX8|%ÇÉXGl][ëÕ-¾P¸ÀAÎÆT§ S(ÞMÒ÷*PP¢Ž9BWb²Î«Õ¹Öeuÿ³k&ðöòzQÆi{N1cu‹“œÑ
^$œOW1½¬7ÕQ+ã~¹w/Ü#ˆ¦ywrf« Ëš\°…F7aLO{Þ…´Ï0œƒ‡©À!àØƒƒóÃm]®+$Mâ,6§y%kÑx½È¸ÁQr!¾ÐÇ%#ºC‡¯3¡.Ì¥F¬#º8“&OÀWF%å©iSÇuÑ-’4™_I.—P­šb~Á?ÑUÀUPÀUMÜºxÂz=Í½ŽTßîRgR“ïÎññÌ¹rGnP¥G˜òuÅhJ°ŽRnK7åÄ8£³3žPÛõ1ªU½ù$dÓÇzÃTG)4ò?™ñUãsèZ‹vw„¥ŠywÅ7,Â/hfOà+«‚‹È¿Ïlé#IÜ×ùüú~.Î?íËªZ4¹)Ž^‹;F	A×oh›ß#»´ ZÝ2“@¬ž‹ÏÄÍ–L3›¸yÿNþP’zo8ŠBA]ÂSË’ Vd¸fÀ\Ü˜4-IÀeÂíÅ#JfvM“Î¤ô$‡3‹{Õ=êªcµ ¾ëuöO¾W/Žðuxtðò¨³×P'ô½ûŸ'ÝýuØ=ÚÛ99én«çßÃÃÝ­ÎóÝ®Úí|‡7'ýçV÷ðD}÷ª»¯üw;Ç]u|ÒÁvöÕwG;';û/	àÖÁá÷G;/_¯v·»GtCUz§Õaçèd§{Œãx³³ÝuÇ¤jcvM}·sòêàõ‰|pð€|¯þ²³¿ÝPÝÔýÏÃ£îñ1 `ïìÁˆ»ðãÎþÖîëmKC=û'jwfÍNö&m5tÀßëm½‚¯ç;»;€/¼VëÅÎÉ>tA¸ëðÈ·^ïvŽ‚Ã×G‡ÇÝ¦b@øÑÎñ_Ì@û¯;``ìuö·ºØ—3ç –	§«¾?x"æ½»í!ÕUÛÝÝ­“7Ý¶„nŽ_ïußÇ' 4èìîªýîŒ·sô½:î½ÙÙ"<u;;Gˆ¥­ƒ£#„r°Ïdô¨ÉÉå&à±«³–™cì#uß }¼ÞßELuÿã5Ì©DùT‚ð;/º„h‡&‚ïv``¸z†0Fƒ^,a|$v ö¶w^à²álì¿é~¸X<[’í<?@Ä<‡ìÐx`ˆ%\·íÎ^çe÷Ø¡ì3K¶êø°»µƒÀï@@ »Œªýc˜+.-< ªkŒ8yƒ×° ÷5á@ßøÌì²í»L”j÷à)0Øîœtþ}ÞÅÖGÝ}@í±ÎÖÖë#ØoØß€Ñ¿†¸³Ï«ó¥-¾s´èMFtû¢³³ûú¨HxØó A:+Á-Žë _í¼€®¶^É²)o+¯^ÁR<ïB³Îö›ÚŽÒrGp³#‚G¦¾ÇM¾[¯Ä0x\:¤â
¯¾ÇôÌ‰l8òÙ¦ß›"œikoôcÅg”b±>¼Â•…%¿Y¸ð”ŽKqŠp€*atÉÐ–paûŸT^ŠÍŽå˜z£”O‚âÁ–wtGB Oë,OGx~ž
'³ú:z|œ±WøLÌ&’zgƒìÁö¸3G@KégŠ.-i_,ëZñº¤užs¡ý¼â{:„"Nç:Ñ©åß£ÈÛeU;$¹×‡lK{+±Ng+§%B"ó8§sŽ9HîTâ/³¼p¶´!‘‘|Ê5Œ0qoHu“*q±xøWg³:D×m¢k”ï“ð/âÕ7«šø’¶õ%i”#ÖÀ¤êPœV}ÕG§Œæ¯swÈ‡œŽØ¼=ÖA£âÓ”Dä¤Ùó}-¹w#f@ú—x3ª†~Qb‚D äzPÒ½uõ72jF§©¡±,n5IÉ¨cÿ‚®ž3˜™Ú®t•-ê¦B\ß :é}]ãÍ™ÿýœŽ	è³,ŽA	Mq"q7¿•ªDZËZÞª«o°:Ý·ÐHõñ½o¹ß¹¯U§mxË½iî÷9žj{PB|n¨:¢¸PKsÏ¾?óuø†6cJ®›GÁÇ–ýã¦õ²eÓ¬F€§¹»jˆá}H‡¬qÖìa9¹*-Ú£Z]C	¢U¶§æ\-VÐ XÚùi™»*j^€ÜyŠ—²Š×qÄ– BXd‡ë›ÉºjÆ#\º6™Í~fÝ|ÀRWÎ©EfqÉæ ;f>Dê›át:Ùlµ.//›çÉ¬™fç-îÑúÔÁÔ=<tã–6Á""Ì;ÉÿÍWSÍ{ôóei‚U£ð®p‚™+07WPN\;T²¬G®³¥¡¹œ¾l%D|dÓ@ö(]ãJ“¢ÓÀXvJu¹Ø©[°×È‘Õo¤ßoo½KtÈ¥™	§çÇ»¯Oº»ß»–ÌSZSYN5½ýÝø~y¿iÁ÷³ÄË£öÃŽIo{ÞÍæP´ñ$<u»ëÝwÈGÏÒðj‚îF
*s¡Á¼-ô§o«wO:ûaçø;•:"bÛ–gê®ƒ1-V²ÐvíS‘î/_ïØêÇrhF¾U…	èâ,}W3y“2dÊ5ÅTKê5‚}^aFƒø«í-úF¿(«SNÚ·À8øº5Šza$® ¦ÉÅêx5Æ7eÝ±ÂŠ¹óã…‰©û‡ovv®•dˆUm67Þ¼›4¸q“²çp§1.Îts‹…“p×‡+‡Mì½Ôú‡Ü9+áðåÄ²ã˜‘\ëu%‡í¸ì/ëÄ=JÈ`öL™E<tdó9nÛ£„Š¦â†”;s¸ögñ>ºÔ¹—’^€Wwë¼DÈ.¦eó¼{˜%…ýŠh–Ô¡7˜=LÇ±0…¦r)&ÃTét2¼j]¯V Í+£óÉ¨9œŽG°:¿ûgüôÓ^ë¨ÛÙÞë6ÇýÏÔÇêêê£õu…ÿ>~´Aÿ®®ñwø¬¯m<z¬Ú×6ÖÖÖÖ?^S«í‡«§V?Óx¼ÏE
%O£…í Ù`°àwžŒ2ÿþ“|î©ƒ×Ûxñ[œàeÏ}TÁ‰h/·:y³½¿w“‹ÿóÿüÄ-åRNr…Ò—¤T™ÛÀüèä¨I”\Ä &pœéìßÑwê ¦e:Ÿm„r£Zp£ÎÈŒÁƒj™‹À>üê”a]û	§‡ìl{£!#,ã$&LÂð8ñt¦C§l7\éz±À ÇdhãŒÁÐ‡G˜6æ5WO²Læc;}Ïfãi†Åpë;†¡w:C“’A•Ð­)|³‡ÆmFÏ¬·ï5ÔQg«A^Î°¬U/BîœOgƒ·Å‰)ê)£ÄHZÝÈ™È¡šhHª¹¤ßü<“dÌÒYÕÌ‡Zú6ïdŸÏ¤•\8É†Õ,éÙc˜&I;®K‚¸Àä†]1 E2#q|1§Æ¾D^J½ +1.2ùü>W¯+R®‚N¹9xÑiŠ¬ÏUÃðóC¢`KC^•Ý8™½SoöþÏÿýÿÂ¨pŒÛiï-GÀQ™‹8å(Ì'gÞ˜rcS^7zƒêóghW­ãiM{CêßU|ðü^êÞ–AÃqÈ VéÞ=0P¦³Ia¹lÞ¨G'`ÏMNl4ÔeÉ,ê®&¢ãT~Âemb"<Yù+«ºŽRg°×'€,ê‡×ú·¿ý‡¤„¿p›ÿÝR?À¿§½~ý¤Z³Õv‹¯m•;S+Ã`mµýx¥Ý^i?<m¯o®=ÙÜx¢06pt²‰·³c¢âÕe‰ÓªÕf[
oÌƒ¶³ÿâ@mR"¦Öò©²13;NëcÝÕ…/¿Îù:éò@~X^üÿ=SßÀ¶Ýíž>ïw¿ýI-„§àØ¼±³3Þß2¯þ°26¿½:Øsž?‡ç¯·áûÖ_^Êã…Ý0Š•a¥‡Ž>4gµLz×µæó¨~¸‹ùàä^i¼#£ohøÝ­€Sšó\mkNÓT{(âˆé„Ù9U¼h²I· «›>–‘	×ýÆ‹ }›ošKªW®0œ‹æLd¹BŒî-é_ëÍ›ºès¨ê‚BÕ]XdÖ_vÒCNx+ðph«>¡	@Ù=2v0!\®§
9ïÁøL£ó&§T÷\8¿	FhÇ;ûŒ#7u&G25þºò‘ŽøjÑõÚM=VìËz<{og“¼ªOþéæNcîÔç;%¾E÷lVtk~¼q—Wq§f+Â¾šèZã¸ßE¸ê7öý90ýñt7='9¹©ZÓñ¤$ãFé9
É ð
gJŠžSºô.)ˆúLôø½Høø‹Ë?›ðÞÊÙƒÂ˜¸æ½äŒ°6ç šYÜ°Žo÷«ß~€’ûZÖêç¦Êxøâ¦:>¡q.i´NP {ƒ½+LU´Ã•ú(JMU¥MDÉù&dµÚG‹‹zÁ#Ñ
ë•ÆJ‘dÆ¥G}‚…‹ýdeum¥ýè´½º¹±¾¹ºñaúH»¹Ú\ÕÉôþúËÜ—·ñt!ÝO;à"Í¢|á¯se£L°‡ÍQ)WÛ\ÉÕæó¬ˆƒÅ ´„t?b÷àåínÓEïvO¶N·Žnè¾EAÜPóÀæä¦w/¿{ã{ž˜pú4lÿFVžú£&y‹õ3Û{›yðm(èðè`ûõÖÉ\üëŠý· …rkÑR
¨Ö`|Ù^k®5ÛÍ‡ÍÕÛ ~±÷ü. ÿ¹ó¦S/Î³ÖÏ`¶~î¿m7Ÿ4WOÛÖB:Þ:Ú9<9}ñûeÊ›ÏC‚¹†ÌV×Ú±_Û¢`»uXhÁóf‡c<û=.`Ž{»Ý]ýÖM[±ê­27øˆŽoÞMÕïÝbU¿x;pã|o³ûžÓAâ|aÑX¸Í‹@ÓðŒN)Ò_Í3ïo÷"zµ°?y[ýÍÓíî‹ÎëÝ“SRáéÍ »ï¨'¨@å‘":Õäzs‹þƒJß‚[R?‰Þ¡¯Ô}ÂTà<ag^À˜n—ä2QÞÂZëüJ€î[ô~÷´JÍËyXü~Ê×ÒyauôŸ£ø¬À®lXpÄC±ŽúñÀýN#²_{À`š}÷IÕÆS ?Ä¦(=ÏRLWñ›÷ˆ’+žð?§ÀÈŽ÷š“«9`BåÑøqÄ—£üžæã¦Ô®-ü®l–O
¿  [ã¡WüXïÖ
°„8l3‰O±–D,¤Ä£ˆ•tX¿tL…©o½#õ‹S|3Ô×€ôÒ,rÌW’Ê¶¨;ÜT…ÞÄ¾c…hYYýcAR²\êÇAs”ÝxÈQLPì©ÂoŸ|òÍõè›¥!:U‹Ú|ˆôU¨öxYBpOm£Þ[‹ÊÄÎÜÐ9FàPµ¥÷ºÙu´ˆZMýô”Ž­JQ‹•6BÍåºÕÔmÝVJ5«ZÀ/ÑH’d¢Þ0UµîÑÑÁˆ r£c¤ƒÆTùæ à0“>[<xWÑ'ú/>zVk*g
­¥÷šIá³Ýƒ­Î.ýrºßÁN<nZÃûðÐußu±ø5sçëO„2ÌJñ^¦ãHo4óÛB¸RÆƒ«ÞRí^Sh¦ÚÇY†„éœ ©Ò.fïÇ‰>(ÄO£‰”ýŒ­éG;h86.åï–jê?Yq}ÐTÆ¶²(|Í-ŠÁÍÈ‰áßgœ¦öÀ¸W…1Í‘*\Å§n“@Ù°p§H2¬i¼hËÐnÑÛæ£¶Î‡nže*’l¨V8=K“sý†]rÓëL:÷îáŽËqÝÉzÃxQL1ž_¿ÆÒBgFÃí1w¬gà:¨Øs%Ž1Qå|iÜT*€ŠËõ¢aâyáÎ‹XnnÏM•
}»x¸#íá¦Ì¸
XÖåÜ	ªzÎÚ&&Ô°?o‚›%Õnq&oe3¾cÎTqaá9:¬GÈÎ¼&èæÍCÇkGi›N!ð¦ïò3!º7w]ˆ˜©î\{VvÎVcÇ.2´†öà6ë»t^œXÀ$oCA#nØ{†zÔRhN$öÌžb/]Â…¥åiÁ/B>¿¨íˆY¶ÅÐp¥üQ¿Ÿ`CË¾]ˆ:Ñ„ðÅH aÒ5ˆˆ‹KŽq»…Âœ$ê©7cû
uÂ€­÷×Ô÷3»²I³«0syZ©l&= to{k*š2¾ƒ4§8ÞÀ»ÛCzÜÿ}|¼«L½¯,²i'dþÈ€x žJYU)PXaª«'Êœ=²™c^‹òè²ãÔ	gõgr÷„u†êœä´úú¯ÐÏ7¡RÊ\,‹’þûMµ›ÚÒq¥i@û%ã„D©¦ÓñUQ~bí`bÆ’žZÄ`µcÕ[\²=tŠÇÝÌÑŸžGq»²´†ôÓ]M€•wLŸ°lÎ ý™uñüÀäÃc/1t4Ü†Ñh¢–‡u[¹€›SL½c<§öS¼ÀYVôPh¤ÍA“ ±[¥¹aW®ZÓú™¹ÕÇ@Rý|,ÃEk°­[§ØÀÃü……Â¶ão¤ú2À†L¿¬¯Zy`¸fãf²¢´4ÖžúúÒKR45nª=<QÃÉÙc>õ›à±}æ:/À”•t¤£èDrÕ:Aõ’žH8u÷ß¨7Zu‡hÈ|=§²>ªÅÚÜ†Õâ®Rè©M?¬7„®Ý rC-õúé™™ó¿Cn•³®ˆ S!~Å±¹ëª˜ƒIZ¡ûõSºvƒçXÔD«§\14¤ÂÐ ¹]D4ÍðJ¡¢y˜i7ráðPuÓìTk¤VyJlÃs-¹ú.Š,_'ôg°ÕHŸ!½Û©7³N¬;­T‰EÏ±Ê©Q÷Š©'4 ­Ã\|äê¥6˜%Kž(näcÖûZÎÕ_ÖÎ,÷—¨ŒÁ–îó?4†&PŒ7nË<-½s,˜NªS¢üYWÆ@ùí¹;=âxçÏÚñjÁ``;ÄËºñÖZ
=E
Ì¢s&GûÊ›v¼ÂüQü‚XlšN:È¼áº«4o¼Ô©2C§Hß. øÎân§~ÃêN±ßÕüOõzPW°=nìJßU5¿êTH·ê]Ú>W©4Žw·w^ñc"Ú,ÆdÚÄW>~xN@ä6Ãs›»"*Ä†€ó…;uRž*Á¸Ì~_'l_Øx›‘>¨ù´ÛðÂZó!¡2D\9ïª¨ñúzá?ÃïÌTu
•á{^M7>£‰Æ®D©È)+lŽDñLOÔÒnXWöTÒÂ"Q+¹b|M=Ù§4‚íƒ½ÎÎ~Žî6¾<öNF0ÿó‹Vƒõ×[|´NH®ª©§ÖS5ô2	Š‡LC~	´¼qj¦³£ûyå95h;Uc€Žæ	ï§ªá¶à‰Ç~Ñþ¡ù¹’ÅÎ+Å8w>º¹sàäŽ*¾›Þ®g2ZÞXÅhúgß“[Â¬­‰5ò¨2+•¬ Û Ú.àÜžÿa:»ƒ˜ÂhöC[ÝWŸ*±yàtwçøÄ°³qå'»NÃ·`Ì“_>é<g@‡ßmŸ¾ØÙ­Òiõ¥àÆTÕÔ³@—Þk=ãºå¯øä²ßœ¾#gÛH?æþŽNJ}sÿ^Oäúr&!ž7šÄéY‹YŸÚÍàŽº‡7«è‰»(:òn j|}‹€É*VaNÚº1èâJIÙW6Ýq§x–rî¯¿SXœŠ¯É¤ã8Guô¶áÖ-¾9[P%¾îAÖŸÒrNúˆ?
ãú}~¥ vqLý|Ž
©è7Fº½f˜æSt^5<EÙf7ƒÍªñN`]:ã$ínrå‰÷’ïåçSrTgE<jä$Ä*%í9…¶ÙéV2 £0Ç2ýR«…Ê ¸Â“ˆ•‹‘`ðŒNx¹=?™úFsŠoýcÝRüÝpHòýQÕºÊ.©î§c—Øå4«PDáo´ð}„B¥ WºZµÏ9è^2Dh¥C€F·e960ç€âßnSÎ:bõh.`üív ]2tývÁ ßÚ˜]ƒžG+øXÚíA-“ÏMàgs0‚àg–Â± çò±¼â¼$<wŒDˆq:"þ–N¢Dô	‡éÎå ¿˜½U ·eHÎ©_}ÎAêna+áo¯ÒáÐ/f	ö¢0œ|)u÷¿ÿ—eà7°ëÛ2éRÔ®Ì¤µœN´²ðÍnwÿåÉ«oeúôÛeþzi2±pHrÎlØ<fÓ^¥ëFÂî8ªDÜ×N­\× Õ1Pøw6™ÈÙT`Sèÿ"G…Á]Œ¢ä|:´w'H‡RpS/Þ¼dªŽZZÄõÿÛßþæMö	<KSÔÛÍè™ž²Gñ”¢–ÎüïÿužõŸ/#]ÝÛÍÚp³µ‰·ºôÜ4p±L~çCÕðQ&/‚,Ò¦Y}°ÏÐòi‘ËjþñžbQ*Ùñ½Úz.`¼>|€/<Ø>ønÿ¹vNãäÖ©jÃÙqUÀÄ©²=Õó])ZR(©âÐü¥7³ûáàÓÀ\·:1‘B¤m ã<:J‚g
éWH“ªø¢À”	Ù3M;Ñ1ÝJ¸ 2–¢m˜Œß²Q³Ø³¸ˆIb#l²ˆÜ‹ºA¿³=‰mëÒ@(qI3d\æy•æE4ÉÇP€ bhŠ¥H!oBâëÓ^Sw_éAY‚g›½îg“•I°ô\ä›LCÉBN cLßlïµ¿¥Ö4K\H šè '¼ù ñ!,–Œ”wZ‘šàvòš“åpØØl¹,ÃêÆ¸«Ú«MÕá$´CB%2;É‘3¨v’,0#­
µ“çxÂJ’:I†RÆÞÙìõ„†áÄ!‚ ZÃ³QŽOé_®	¬o73U1t+¹ÆEýðþÝÇ°8Þò…‰åx0nËàä›­’dóœÁŽ·HQ9Û¢M+ôVÞªoÁõCWçåócÅFÃÄ¶>(Òâ¦u|=ŸaÅ ¬¹HO?àý¼T'Äéiº„tbçD[/oAE¥‹‡ÍÕ¦¹:&=£t-¿@›©¦7å2kù¼N¶XÐo]öÅ|0i¿)jÕçêcqýŸÕÕõöš®ÿÓÞØx„õÖÖ×¾Ôÿù5>1p"æ1h«[ì¹zp;'Dõ§˜Áj»Íþ¥œß±LÅcå²s'pœO„3œßz%~›íÁx3†Ÿ£öÿÆãÕRý¯ÇW¿ìÿ_ãÓµ{Ãhð¨ÎŸÚ½v{}cuõW×V½¶º:X¸ÑSj¶ÊçÇo<z|®>yüäq{ãëvô8ê¤Õ¯£µèÑã‡ýÇëƒ~=vß¶gÍÖ£p­¿ºúdõñÃ¨½¶®®ãíÕ‡«ûƒõèItv¶þõú`Õ}ÛžKŸ¢ÇíÇõWÛëaõáÙ“‡kíÇýG«kOÖ`:_‡«ƒµó¶œx´±öðIØ{²q~ýpã¬õ6àÝÕ^ïëöÆÃ^õÉÃ^{ðõê:¾YyÀhÐ>[];ëÖzÐÓàñÙ“vø0l?z8X{m|}¶~öõã°¿ñõ ¿ûh}õëþÙãÕGOž Š×úýµ‡kg½µõv}ýhíñjïa‚D,tîœŒûÿÛûÖí¶q¤Áý»:'ï€Q2ã¤Ç’xÑ½Gýc;iO;¶?ËNú’^ ™±DjDÊŽ=}š}Œý÷½ØV 	R”%Û²w3“‘ÁBáV ª€º´šJ³^mh&T­öûjUmÙV]m¶`Ü¨fA”¾Ñ¤
´¢SZº¡7›­ºY¥fÚ­V-µ¦Ö`~¥f«Õz¿U¯5ûR±´Å]ˆCÕŒf[SõzÓh(Ð_«ÕªR]­¶´Z•Í÷"{2Óª«vçYiVÍº¡¶ªašJM³jšb(-Ë¨öMNy‹Lân3£3¦pÉ¹Uô¾e)}ÓÒ,[Ê‚4›Hš@é@èÔP»o5ôYT²%­ëMÝ¶k–b5-Å†°ª*ÌWfF­7jª:ÍèœL+5Ú²©ó¢6ëv«¥+0×5³C_kªj½KN©ÚšE²ý»ÅeÎioÙm©pAšíZÖMË¬õku ¶!è‘©÷kìjUÕÔ©]¥j&²YH æ¾YÕ´V¿Ú²L6’škº¥â6H-½Þè+ªš{Étö¥¦+° 7³oj´ÿV•Z³aõ>Åÿ6Rë#iw
³ƒ“cÁØTuË <@T‡¾Õë¦Ö·ÔzµÄ˜á”e©?*¨vKÚ¯j-SQë°ÑRPj¿¦X&ì5]mAÕñ¬2½a[uØ%l¶Ù´UX®-]­5ê*¬'µ¥Óº]¯Q3=¸Ì¤VQ{Âª6ž´³‚¦×©Ñ€1n)M“ö8,LXxŠb«°ö´z¿^Sàø¡Ù(«!Ê‰ç=4ˆàìf´¯5U *ØCjfÕª[ºM[0ùªm4¡¾¾Ú¨fcUØ×“=ñAKu«fÔªUë«u8cköUé×[}­¡×j@oËê÷³qj½ÈN¢ÿ0lV‹*°·š@ë³fÖa+´«Ðð&1Õu•Â×[`e#Pkâ^\Õô†Vµl ·~&¦o×T“V5C…©3jæ¼©Ò{ü"¯‡
‘=¯ßÇ»0l®mè-C§×lÕTl`ù`qÀ9]«+°(Fß^@iÝ-k/­êuMÇÖÂ ´àø‡ÍN‡£ _ƒÀ„ýÈh©†]Y·±ª÷¤™H=|NÑ±Å5FÐÐ«Í­ÁÓ×ª-8øCÅÎŠ¡ëÕV}iC®&œê}ÛhÀ¿Àêhf8-89k–aÖlx¨*Prö(¤MË)ìQ@«´»¹­TkvCa0@÷–mêv­©ÙÍ†ig÷\Ëì¹ÆæªÙ¬Ô¬ÚfËjÕ,»i›}hgSoY–^kT[°ð@Ùˆ•÷Ò'ãg<[öKëSÜ³‘m TÑ›–Um´Z*ž#p4›Vvs³Æ“p\[5µO•¦¦ÂnmÕšu¤jXpÞYÀ ©6•Úm–çvêZÕ´lƒ™”öÅ²UÕ†3Áê0îu8n€Qa'ÊQû{Û»ÝÝ‚ƒcn@6°·iMKkô[:°%¶|Š
ì´AmÕËÅNšVÖt–„V­6Mà}«lè¦	LUKö¨jB>ç¯ä››»¯x®PœÈL(÷ÕjóïP^BùO­6€±l€ü¤þ¿Hí¡†éO.ÿeñÀ«®cü_­i5.ÿ« Nj(ÿ#!äòÿ:Òó¿0áøœ™£¯æ&_§='/öì6y±r´‘›ò-¯FZßá¡šØÈßHW<s¼|½Ó}eº ¯b?˜¾O‰ÖÚ$Ààiä-œ9™›¤{é×t‚®ÇWÞhTH,óÔž1Ë„ï[,‰øÞ€—uÉ!»m%/=ê¿BWWæ7°ÿÄà­,”Þµ *ýbßðƒm~oúúŠÏÀ²âå üÀAXÜZ<¦Ó áv4`lIŽ‰Yí‹[YO;ìÁÖ(	3Ë`|«Ð ¶æË6€jÌ9=6…Ã0.¾œ.DO@¼oöKzYùûÊ§öÆ`r¨µ £ŠQÝ¹;}qð³Xš4„ßwûþ*é¯¼±¥ÐÓZÊåÌ]±½¦È$Œ‹:àÌÇ{lÓH¿ èp««ÐÉ<3;K6€aÎEl¼8Æ
ÙCÊßÓmábT<ò^Ä:Ì}yÝ#ºèÆ/tœ´Ë¼Î“ð6$:a¦òA"¢@Û¶ôh/ÕÌâ¹0|,ü–1àzwûû½íÓîÉá»½_·xÄËçê(—´RMŒ	œuz)|j°·baO˜°ØLØœ¥ÝÞ1œ3‡NÔ¼	¡Ô YÒ>P CDItî¹5ä±S>\ý[ÒÁ¤Ô´„zefûf¤ËvVaà±§pŒ'ÍŠdÆq„ÉA”|Ë¨%ÿwBe¾Y›	Zð0:ëÚTv¼‘°KÕ™ô€Žß¬‡RržVÊhâF´èIñ9C¼ã±=Bh²îUÀÂ…›4Œª”Ü[DÔ÷òÊwÓd.òžÒSbêÊùAê¸™ÿWÕªªÄüµÁÞÿò÷ÿõ¤‡âÿLx¢2À<)ài I—Zo„[ÁÐëSwdö‡óÜr ¾D
àö¤ã{V’†17ÔûK»k	C
ð)"VÓ\vwý–EÆV…·¯ç•_ø ¿ß:î¼GÿH+o8W= G]µ³ñqúÏgí—òw­²_?‘Ò²Ï:ð5f©¾Æ_ŒN²·I’ ÌŽä³/ÎŠlf˜ðu™š3]U
¥c¥¸[¾ØJU‚=Ë„• †ó‘¡Õié™q“S-2ÒŸ„;j \GGR¡³=d‡lh”Íqï`~³Ì3Bl¼Yv@øL¼]®Ë’±³wMo$X|2‚_I‘”Œ`÷gfÁ60ÕžA€Î"S‹J¼cz¾$K^Ÿó¡=xÑ©x,£E+Ìï»´R‹–oö_®®;ìg‰p*¹pZÂjqÆ
…ÎPö+0›f&3õýZ !ÈÁ“±ø'íÅ•K	µ!€*lÏ¥á¿2iVÙÙ°l"¯ìïÿCü3ÃŸŽHÉ"i5;¢ýP±éEÅ‡¿Ðt¬tAŠmrøSñw<ÌŠ~¥MÞlííïî¼¨T¢¼‹aªßîîTŠßæù²LJ, pŸ||IþBJ3c(ÊµÉÇW¤4ž8n üþÅ˜`ö•¨ucÑ€7_.ú³ýÝ‚3´dÿ)õ5¹[;;¼_÷‘ôJShG›”ÎÕMU”¿ú*3ƒ!¸î“roYB?hÁàš”N€R¿~G…Óô¤h¤³ÊuFåø¸î"ùf©DâÁß“‰ûy<ƒ©=]2çBñZcÐ³RÚÓã¯N&¢
Ø×3€Ò[™6^ÞŒ7¼šù bŠ2qãÒ(ÊP¸£ÏBAn
7øY(È•¡f!¤¯ž™ÖÄˆÙ>4"².•B³HÂ–3þ™l£”­ˆK¥`[ëÖp?¡_öÎ)Zn'v™òŽ\NŠâ{hÓÏøÝÈþ8nÄÄÇVd—Jì<Ý…‰Œ$ÂðXD|@gvþRg^¼¾º¹;a‹¤¹‰ŽÜhHMÊº.ú6æŸØ‘ercDüñ…WhÀfË¡¡‰ÊßAã,oèM:Æ4ð"€ÎÆ>ºhÚßß:Ùíl6†äwÆÛF@ÙPfô=¦¬èÌ‹ú8œð&ƒI”åó¬¬öøCŽ#û3ÀEc^—hJãù¼£|b7bÆÓ1ÿ0Ç™éœÀ€½&4´5åæÕXáFÓqqz»âÌ<Z*4u;)ÇXüÛáˆí©%ç„1ó#-YVùtô¸Ð†‘1¹
›5C8BÛc–Õ€¹!²>È÷äÏË|Ì;á/¯³qá$vA¡”
ÅcßÃ=VÊVó]mô?tU×âû_õ?jºžÛ¬%å÷¿{ÿ›P®ÿC^Ë&û7Ü§¯‚eWYùup~üp×ÁK]/>Þõ!Ï¹“	œ_æbåq?±Û‡¥$×Nx/óØ'[ž–I±eÖÃÕ±Ðþ_ÓSúßZõ¿sþïáÓsvÀJÁm¸†Qy´ÝØu*ò.øAX„ôf‚™º”Ùr«"w‹Ýu…¹5‘{,Ý…ßêb:›™dIYDØMr¸‡ÿìtww#6…ç·ÝéHÁ‹‚~·U½Ùj«u½Þ®Bj7[ð'àýs‰‚Ù†•«­cÁú×j5–ÿ\ÿÕºZË×ÿ:R®ÿÿ(úÿiCæ§*ùÍ± ÈÔr€Ç–ÖV,«­GR+¬XøúvD/Þ±ÝÃ7«Az—ýÃg¯úLI§;ØÖ5·ÿ\GŠí¡®ŽeçŸùRtÔÿV”Z>ÿëH)/=RÇí×¿ÞÐ«ùü¯#%½â<Lw˜ÿZ#ßÿ×’fÜ=@·Ÿÿª–ŸÿëIs¼P­´Ž÷?ª¢6Ró_«Öòûßµ¤çI£h”HBOôQ(Z×&ý(r‚Ó'¿áÑÿá3±È§ïÜ-üïrœYè;ˆêÔçêêSW—Ÿc)Ž<Æ†ºcä
G['?v^à¿í,ÔU9RÄì-.´ã 8¦F­óØª™Ç/0˜‡õÈ†œ·»(éxI‡‹Që		{@ü¡+
«.CRÎ‚€/tèSÀ5—wñm<4igmÊ,	ƒÅÇ+´œ
}Øó9ˆµ—PS/"ß›NxÜ/yÐÿ¹î¾ó”àÿ%Ÿ}«­cyùO­éU÷óóiÆÚÔqþ¯žókIËyÚ¼_ø¿ªRô?JU%Š¦hzþþ·–´ÒûìgÑ«ß³Õ^”?»Ë»ß³;<ü=@»O™«ëÙýžÿž-|ÿ{¶Äà³%_ Ÿ¥Ÿ yÌwr=:V‡Ô%¶ˆWÈÕG®Ÿ¥ÞŸÝþ5ïÙ¼ç¼˜2ùAïÙª_ôVÞ^†PH<QDDIÔº5Bp^ÚÎ„[›)¯æ85.†UkÜ¨ò{ô…‹N"(i"ØYÊ š»ùjÃ"3zŠ¤©½˜Ù‹ÂÜîÇÃîÉÁÖ»$\lã›‰ÁËðAî×L2tmƒ¹)¸DÞŽ¤F;{Çï¶ÒµòÜ
å½(žû•McÒL×þ¯äS”Ï?>µT²`/?ÃY9Â¸ZÅyZ¢ÅýõâU FÅ­KM˜Eå¹!3M Å·¡mŒ˜it9ß—>°‘?2ëËmÏu™Æ™ÅÇ9„Ã0´Ê	»n »ÈƒÄvé°ßu.µ·é$À$jÄÍáN¦.ª<|¾•B-
ñ]ø·>ñ¼¡?ÊõJã‰7KGoŒÕQÇ1\¢+{c~–_ü¡ÒÒnñïQÇþ¿QW"ÿ¿ 1ðL®ÿ»ž”óÿëåÿç¬®§-ü:õ\ƒnBÇÐkBúSøÇvè<) ä“ý½7ÀGO˜þŸuFlÈ"Ev bLû0§Ó>uËÏÒVc¯©ÿ³IŸœ®Ë°±Œ)àîCó@“ä’NlŽ(—IVØÞ€Z}ã“cÚ0ç5õ­3XÜæ$²åa­»„âÆ âhL’.îtR:Me"P3_&P’b› “Q€c%p¤ u0ClÀVù‚€ÆcÊß] “Kê@_Ye—Lb öÒžkÓ/£—<:ÀÖÎ)±ïagõÌÞÉ„b„óT©•Ž·Ýr;ápoÂïc\Ø;>þæj»Ï
žùXçí!l®m 1NGtâ{nêÛ8+3ðÆ©Û/Yý	J¶[Â%Ÿ‚ð&Ãž]aX×T’Úä?Ýî[5UûzrôþòïÝ‹©c[§ÿ>õ-¿¢:§GÃ­Ë·ö/‡µ9>¯œ_^üúfpeoýüãáîÙÞûóã}ã¿‡»Æû¡2Ù~{}}ùSåÈqkÕúû®;~ûºòë®A§ÎþûgËmK4é'þ	ÞRæü¡”Y6†½ÜAò-¡LÓ&ÈðaP”ÀNì<£ÒÐóÎƒ³‰7œ•ào'høÀw®iòËÀ¹ îÃ‹þ«µ2›ÈS6´B:píÄâº)=àÒÇçk?{í§K¹ÁõtÀà_ÃfÎ Š¡œÿŸÿ‡Ù5¦áL=Ñmã§Ÿ?ïUÔÃ·ïÆïþþÓ‡Ÿ¤—ÓŸ¾PsÐø×/¿ü\7~uŸ¯ú;»g'£½‡?ø×ÖûÿvýËÏÿ—êÒÁî~óòíÑù—ÆñUëõAå×ñVå]¥ûc}ôïãŸšÿÖŽ¾mLczö“Þ¸q$áæ¬ù…Û…´)œ&¦·"¼`ø|GÉ ö4‚Ïj	X5ûF€Ë	¬‹lô¥G¡Ü§ÞÍ0ŠŒÎ<DWè’ªdXÃ9MÁ%?,‰øçÙ0è§¾ä_¹ÖœÏzÃ+#¼Á#ìóèKÉõ§5ÿûü!Ã¯7ŒÊ%®s çs³FÈO^Í¨Ð±Ž6ƒ"Îàìd6¿éb³fÌkŒ€ñÏ¦í]fbö¡8ƒŠs´%Ü0GFú€‹Hýþ'ÜäJmÉ †÷ªcÁýOM×éýWÃûŸj~ÿ³ž$ì?Qkï·ü2(ÕîäePæR{ÚWAXÞaÁpl\â)X\ …ž‹97{:PdßËäídêÚÏ>ÃÏq:x-Ãí¾7` 7¼%2¦ýè¹™9…•ðúÈ)Ï < Ç›
Íšâa'n“òWêºbq[ÄëÕ½O	³Iô½!pÉÄÄuøâ1"…so2¡çPF0DÞ	ž1ÉŽQM—), >cêŸ³øRìb°L>8Llb¢–âá&Þ&úŒÈ£\…”\TaÄô¯5£Æ¸ˆ}8^b©`“øèA1IÓáh¸<pÖµƒŠáR*¯~RBH±3ÝN±â.ª8‚»bÊ·;ˆöÔ
p¨ZY+«e y¹¬ô<Œ¶ý¿ºfzŽO;DŸƒ ³yQ0¨’¾ë•Ú¾8g{ögR©f '\ôÏ+áˆ^;èV$ù¡ƒ>GR°Ýî~½¤²w:è’$f`½þ
PÈ½nß7ü[ŒP´º{øæäÃÖñnzú|¯`t«ÊEL•™R=ŒSEÃ¿¿V06UÜ›w`ýÑeÔÉûTpaWÂ®G.möâ0ÂÀ•:Ùþ[#(˜„R³Èäª¡miÇHÿÜ–"­¢‚?íþÒ=9<Þ½%é}>÷gPÍú1›¡<–Z°·ý®‡N1üw±áŸ¨O?z~WŽ*2j‡iÊ¨ÅD®Æsµd®Îsõ¢,žußŸ&sí„Û¦¥ƒÍß£ŽEú¿z=~ÿ¯Õùû=—ÿÖ‘r‘o½"ßœÕõ´…>!‰õÿçÿñç•­©¿Ï&ÈËâßk# îü§DØO”6œLÍ uhP;ˆò™¡ìaÄ;O2å“˜Hý)YÀšE‡ø	x}˜pÏGÆÂð¹"…Îú¢+P´,‘!“!§‡l3ÖB`z u\Ó!B³aœ|.Z®¨½¨ $ÉØ6(€“$JøúŠÑc1&›ç#¬MâhÃXîYWí½‹É±c“#ngãêÙ!aßWC;RÏŽþ15´W¨yÒG*Ìáâ™—áâ\®¥Ía·l[°ÊÜ	g—=u™÷\ÆÔƒæo>ËhS34©ÃÐ³Ü3A-2µ·…î26_ä éò€É1IZâµ~Q7£ýývLë{ß³«3zÙtbÂqþ‰ôËá4At¡B}zæìÁiIþÿ^ÀøM×cý_EGý_U«çï?kI9ÿÿðÿO_˜ŸAdWè>!ãŸÖþ%ç2ßk]à9‚S®ü$t¡»jeð
Ñ¿w›p¦ä¹ü2p‰4{þë=¾ z¨Õvh÷º \hÿ_S¥û?ÏU­æçÿ:R~þ¯ûüÏ^]Oýø—. ÑUï¶Ð ‰Ó°®ìã_`ƒk<¬Ã”¹ c—xø‚¢õSÇþŽ;þ‰©Arf¢L¶\8~†xYØ8—!Uq	§)´sÀÕi_Ñ­²½ùÝz¯èÅ
Á]†{ŸGMy¸ëºe¯º;#àp]Ønlñ¢« ÜGJ¶c„A‰Æ„ï‹PÈ»HäúÀNmúzMbW5aËã»¦¦¾·Ã4ú™õCäŠÀé‡wFY×]]ÜyîÙeÀ úüÇÑQÎÓÃ¥eùÿû\ .àÿgý¿ijUÍßÿ×’fæ_Õ{R¸ïžaÛ=¼8×ï!.Òÿ×±ÿ7UcòŸ^Ëå¿µ¤<èÓš‚>Ý°®î'ú-”ü–ü–”ûæˆ}Üõ¿ùåÒ‹íwÎ¥ÔÏG»ÜQÊ.÷À³iJ
¼½Ä5OàZù\>µO+µ––´D0#u‘ÁïÙáM›ã•–Ð<æ¶òË’ÚK*H`êŒ®ËM Ò3aô¸U7è,,­² ïÍâÂÜìfÅ†¥„¸‚€¢³“†K"ö¢ÖŸx#ò‚Vàñ_:_ðÄ/#u|,ð·~5DÇŸ÷áOi|Â‡}Hšw¨˜ñ¤¯¦ßô5Ÿ+Þ>ZËD­ÝˆZË@-uæHj1Nº‰³¦*­&5«Œvs•>ìâÁîïNAR-¾àí¼E,û%IAVu˜õ>Òˆùç\ßD¸¢ùøJTQ¼)HÕ„äÐåŽð4æI³‚ïP?p\±½È“ø*83°Ñ&‡vñÀbÁ¥‡ö§@0õIé,¨hœ"ßŒ¯ºÅ+½‘È/$V’–òÿ÷°öß­!éÿëµÜþ{)ÿ{tÿ´Ç¿¤ðIìlê–:þs\%ÞUÃ?Ýƒê÷çï‡+loþ~xÃûaèpš’m)ful)ãðzG[Ýî‡Ãã¯a,«g^l<^6
ü~y†u‹G¿'¶Çó0ù/»$›^T¦\g#ò; ’’m‘âVéW£t­”ZEÈì{C›”.‰ªÀgæ°äõUŒÛú´ô¹RÉ€’&ùÛß`~ü"étÈw¿²Oß%³ y:*ƒ,ò)Ñ½0		˜wö	ØQÉ;¶Ä1Ò™…Ž–&ŽA:?À—,jÂ®qga”¯pÛ7ÆûšÅ¿	«+tî¸XzR]}‡ÿ¶=WTÀßsíe\øëYö“S—-I1£Ëœ0Á.&ÑC¼Üfðp?J!µö Öþƒ„‹hGyÚÝ=þJæÛJbÇb~qµÃÏ$sz•ä3°†@’ÇŒ9:‹«ê3Çõ¼\Þ?¤/î–ñÇð@Šh½{8†yzr&Pß®yÓÃØ/­Ø´æ#xÌ1ä¹SnÇtÏ”+¥Ü?ÍÜÿ!	è°û®<¾ZEît½QïÔ*QÔ†RÍßÿ×’V%§¥/höÜþÄða°<}¹›q8 àúù<Ÿ¾“IQüj_ã¥Ó·0PzYÕÊJ5u÷2çŠØ+
Õ}Gv¼‘á¸ù#úJÑ\ýx¾‘Y¾k¸nl6þ=v.³ÔRe[ÐàåÆÎá»-à´‘9ÛØ$EqÔãåŠ¯Bc<-oF€Ü"¨LµÂ‹ù•¿süW"µâUÉ=Ö£ã/ÓX…´"m(ŠZ|öýaXþ¦ÂÀIåµ¸<ãŒçu'<°à%5aŠ«5=ì…e‹I™¬X(ÆlÐ'|¶Œ7ùÛ_ýO©Áø>~ó8N@Î%Ÿ£hcðxtÓÐÈòih1œqÓx|2ÑãøÅÐÑ½Âh1€R[Ã‡ýn¸1ð¶Wðœ—¼¿ûžxŒ†Z‡ÍÄåOá<ÅcÂ‹ÅãqS)¤™ ãrSA©iqÅã³¨T<j™qÚý;ŒÒÉcŸ½ßBšÕÿÔ2õÔ´uéêj®ÿ¹Æ”ë®KÿsþºÊõ?sÖu…Íõ?ŸŽþ§–	£ý™õ?µoQÿ“mÕ¢}¹þçƒêjß’þg8Ù¹þg®ÿù‡L³òŸÒã[ªÌ®>¨ÿçšÚâ?k<þ³^Ëå¿u¤\þ[—ü7g]ý!„?]«`¸B—¹j	â0lO(òNçBßTè›Ü[èË…½§+ìeL.…—ä+ÁØ‹‘a_4÷’øBŒ‘Ì—Ð…Iˆ}±"Ì­?ÑÎXôË®A[PCZþ›# ÆótðæR	!Pv[“`ýÿÃyÿ¯,€GÞ¿£üWBÐƒ3‰6Æ“––ÜÒ¢[<ß†ô6·3sÛ‹pyº)-eÿ‡ªˆ÷¨c¡ü'ÅU•“ÿê\þ[GÊíÿÝþW×Ó¶ äÆr<žjäö;æ'6|MÝ)Ž6zéœ±¼‹´žSªÄ³¶ƒ‰¨™‰ªàoîÆ›8#Ñ2ãhœ³Œ^Á3<…3k>ÙÈ‰5Lfù¹V~sºp–ÐÕN_¸Â1cU©“(KŸ¡d(°”~Fã©èZi0ôLcX²äÁÀ³|œøÃ ã†´jiBYÏüÍ±pJ&=3.oÒ6,‹ŽƒÜœq…í}€(± ÷0ò"(ås iß2u04-ZÛ¢[\\†ò3<Aÿ”%fŸQ9†VžšÁF°†4ãã2+[øŒÎô7ÉhJÙjÁÅþšb4Ü èÆÍ%[Ûû>¬8×gäWå½FªGêjª&Þ°gé$¢{äm"–†a9íâK8ï4:‹jY+7«JYUõZ­^VËÕrS©},2ûŠ—tÂèèö{bX VwÐ(Sûcç
U4î8r'8r|Üˆ¨…ðV~,~¢wùÎ ›áÇÀv¡hß«©›Bˆl~3ÿ¡;>þæ+¼*> 	a‹rzŠ~%Da[LE¹EÎŸ7-ÿé^àBÿ/z¬ÿ©T™ÿO­¡äòß:R.ÿ}ñŸž¾˜Œðz£$xá¹œ—Ëyw\MOOÎ{g8Cò#Ð÷Ôå·ù´„ùœý¼qB£Icø"ÚCÏ2†Hr¼†-wÌé9óC6µì~+€Âœä=À ];,0Ûmê¼á`[ÆÈWÄMºEeŽ{a»dˆVC½Wn`|É®'ÑçnuO"ÿ.G¬¼òÐ­D‰7-Q¯Èâöù),¶ÀR”Éo@AK°<`·±#ô~äðÆ2r"Â+Nä×B¸ôð&©†Eù‰¶Å¹¼yÇ[Ôº·á÷¨(¥DH´'†€uµý1µcØ.õþúÜŸœ/‹¶1Ÿíê¦;ÍXm}3,©mÎ~9¼ÓtJÓcÇÏ€1ˆ?u¹°Þÿ=ÖiéùÉœš#ÄàC.dÞ4A6FL8<í}ê‚³ÒkôŸô1*ü‘¼!2ËGdØžÊöd¨ðõw 7ØÛK,Êm»¨c“î[%5ÑHX¿çÞ4(Ùb-´?ësvà`ÝLÝ ­ÏÒ!¶¬$Ï8nfŒeØ¬¡¸[Ún4uàQo¬“~;b¡:.Pg»ž*“ª¹4¡ÿžÂ9‚ôtÇG<2¼I·_GóI* ÖHÎw&¨VÞÊ)êNõðÄÂç8JêÄ&ŸÜÜ<­Iïï,Ë&½î¹¶sM¿ÀA$ì-Ù&4Ø¦_çT*Ñ!EQ‚S‰¿çy|L|‰…®„À„Wó¾yûÈEÍûîOM8ZáŒ 0›Žeò¬Eÿ@m¤x÷¡ó„uƒì¼F´ÐÁpL’½£ÑDdv£ûÀÌ·è¾MÎ5_—_—ñæïþoxówôAšü&é	¦øþøä‰ €hW˜›‚•Õ±Èÿ‹ÆÿÖ@2¯¡ÿ—º®äúßkI+xðèéÞeÜÁòzÚ×=ûá^A2wTFÜU…gîuø ä÷+k1sòÑ“œÅTø]_aLÜ³$îñ~…?#•á÷­ŠI%Û1®çŽu4·.+{Ïá…ÿÃRZÞø
ØF×2æŒýò…[JÏ‡Wü÷Èññ^Ã>]9wâ£ñÅ>ªSSÞ=+|EÎèŽ#dWt.häÖýÜy×Ý½€es<…µÛ—d€X¢øíöƒÇ¼Ž–í‘_ÆÐ¢7ãynÅ6+À?›sû }\r.n>øáØ?öáø'Hsù¿Ö±€ÿÓ0æ»àÿêuEþ¯ÖÐsýÏµ¤œÿËù¿œÿ›¯§Æÿí¾í¡ŽUCPOÇüTN| _pid|à6&³¨{‘:Üå5ù(W”sv˜?ö>—§ì4÷üÇ·¢:nqþ‡÷?µ<þÓzR~þçç~þÏÎW~þççÿŸ!Éú¿°	¬ZôgiÑûO­&ùmhpþWjîÿu-iÅQáa< =Q@³^€`uÝïà_xî/qì/yê§ýmØ >{&y3çŸ=ãoÄÏ;áW;/…§äÚ‡5wÕøøƒéO‡CÂ¹âõ™ÛÉÔE”P7}õY¯E¾ƒÿ Ëþ(A*SE©ã±x¤¨0ýæ
Cbgü3R
È›Óý}RáJú'@Õ”­3òÃ¤ŒÆ2¸7ˆöÃßÔÂŸm80zŽkM˜>ñxƒ¨lj›úfu³¶Y¿Ópîlï¾Û=8ÙúVF•ó¨kIMc#ùÝ²ã'˜h¿ÛØcŸôÙ)æÿ0šÞåÐï±GÖ²Ïõ¬¤Ž…üŸªÅï?UÿI­çüßZÒÊ–SšAû†@a[‘‰)qÖ¬MfÈþFm3Éž# )m6È“Ò*+2Is^jYIsY§.0ò=J÷ˆÎ‚†>bˆØ¿‚vŒ¬`zDÃnð(Vq7ÙÜUœN€õ!ð_ƒ„{CÜCTjQod2žiÛLpSaÿD^²–¾*“-û3¬A¦ºINQ˜ì$;ÂÂB%™´\óHœ \xž€fÆhpv`è],¹øîOmXãÙi‡ßŸT†ŽYÝÿ_IU \Ý1ü¼dF™Ó“¢²ÔPù{oSÃ
€¦‚åk±EñEÕta¿d¬dd¸Scx#rŸZŒÚß³—1q.;Ü»±…ßp?ùTØ¡|!@¥Å÷•=ÁU>nàw\\z“ó2wnPØêt’Î$…ßÄþ©pr5¦ßM‚ÐŒWÞâ
f¿>@1X ÑÐ™Ñ*ì~¡£ÇÙoFr¨¹1ÐQ.öÆ°Èš!!Éà'ÎˆóÕ¥VGW”TãÚÆÄ>œãiÐ„Yù»å¹¾Í¿îN&Þ$ýú,¶”Ol¤PÒîŒ¦ÃÀaöbhû$¿[JòüÆ·gÞ×é›”ðÕšûÿ®2þ¯ÞÈã?­'=ÿ[<çÌõ*wžÜ¸Üèô%`b•=ÙA¼ 6kâ!³Ši¾“±”ì‹pÑ
b>ì˜~ž8žé$ô‡Cq<ö±Š×ülÏ¹4¶1Çl|ÞÈ¹¾³»n†í5,ºKråMÕ»"ÌfÜÑ8D*Þæ }XP†Š…42æ@É0lþ™7ÚÄõ`ñ‰KQOÝ˜\AÙ`Ã‡Edôa£ïh¬yÍ°®„TÀÐ‰÷KÿŒÐAFš”0Îzã‰‡´XæužœÑ$ÑqF‰2ê‰o0}ðZX†3dJ5£ñ$Ç‡M
Œa®}÷÷{Û§Ý“Ãw{¿nì€¤Â¡Ž<ßwd>#‰Ä˜0ÀÃã­íý]öÊB<"-Ö#/lg,"m†KÒÇQJ]eqœ§;2Â$Nè÷¥EÈv¶N¶f!¢XnÃÞI›ÑUÞfRwÀ°EN‘Y¥¦Ežíç¶/lL%q_(:¼ýÓéQØo	«¸¹]Œ“Ê³Â<ÍÏŒà"„ÉA¬ŒÛÒKcBeÔoÞ}Ñß	5c¯ß¿¶ÞoÉMàûÄLÎ`Å2Ððá?žJ47ž ÕÁeÛÖ¼:A‰‹R€døvO¶oÀ‡ü¦84–C˜XX";Û#øf	òòl(pv˜l3Â~%÷ãÉ¶òÝô™‹ü‡oôª73%ù±Ù•'þx…u,àÿUØªU`ûÕÓÿÏï×“~Û=x»w°û©pLý1ìÂ”?ï¾ç;jYáÿ)üöv÷`÷xoûS¡»»}z¼wòKïôöÅÝnïýÞVïÝ/|ãéž¡÷£Nß®L4O—²äÿŠþ,-XÿzCä½ª±õ_­çëé¡äÿ\(£Ù· Oû`;¡ýËNàÛƒiÃg¯r$ª„ÀSH9ÕcBÍéNt1ígÞ$	~á³Øð
ßŽl&aÈ¡¼ï'ïw˜§÷"¿DXMsÞñ[Rþ"ï£y½Kÿ»ÌÕä÷[Ç÷ÆpJWÞp¡ZrÔU;§ÿüxÖþxY!¿¥b‹}"!¤eŸuàk,R}¿TŠ'0 Š0RöPdïnoí]¦&ÇLW•BéXi€8ž±$Ø³LX	`8’Çž79Õ"#ý©Â|Q‡ ÀkÀ÷P>ŒÊzÈÅÐ(›âÞÁüf™1f„Ø><x³ì€ð™x»\—¥{„½ãhz£‹…¯âŽÀ¯¤HJF°û3s:œE ka›	µtBü1½†ÝÂŠ×\ˆŸË¡=xÑ©x,£E»…Ûò]–ij1%-ßì¿\]w6ØÏ;àTr7à åN¼àlõ²½ß°ÎØ¥Sx÷SÀ\ïýâÁìíïuO¾±½¿Àâ/œN±L¤ÕšÔø—ˆ/œbÁö\Zà…pØ°ìtœA¾lD@g!´´ã¯Cöµ(ïEékZ0íJ@árš…‚Ü®®Y(È¨Ì9ËêTªÕÎp.P´f$hëfh¾ cxØVCÆf$þl˜s‡=êd‚&€¤¡‹¶£hÔãÎÆ€=¶$£LïŒçòÕ^Ÿ…ßàªþÑá8Ì‚¡Úß†-idåÎ6ÂÊ3†äwvrG@åÎ~°Iù;X,–7ô&cx@63ú>á†Á$ÊòyV6(ÀaÏxñ4&@'µ%—hJSK´‰D@û¼L‹Õ”›‰Aøœ‰‹ÓÛ§ø,/ŸÐñíHñôb,þíppÏ*¨Ð¢¸p¼ÎÆ…“ Ü0ÃŒ†
þœŽ9YL#¢˜¦3 1çÓ*á8q¡Siùûñ'S¡Û¥è}<å<—Ó³)cÓrKüéèqƒ¾§£‘1¹
›eû°N%·á26¶?ñ±YÑãð‹<†GVàÅ!•TÆ—6Æ._¹3	Gâ7ugcUwÌ©ûŸ‰¢ÖŠðcZtÿ¹3÷¿ª–ßÿ¬#9.:‚•Ðƒ9ï¤ß=€òU½WïÝú<Ý7eë1Ice×À‹ôÿU)þKU¯£þ¿®çñ_Ö’òûßÇ½ÿ•×Úó˜wpámpú*…÷ü:8¿~øëà¥®ïúŒç$  'àüâÍYù@ÜO¨Çöa)þ''EØûdËÓ2i†ÿsÕu,’ÿªšž’ÿª†šóëHÏÙËpvrsU¢’vâèe¼~ÐÄ‡ý­#rû'fêRf7Ê­Š\æŠ8Ê­‰Ücé%üV'mÉbEÃ „Þ$‡{øÏNww—„v‘…ç·ÝéH¯ÝlÏ:§“¶ª7[mµ®×ÛUHífþ¼OI{ïþifý—{;»o¶N÷Ozë’ÿ´†Zå?•ÙÿÔ•ÜÿïZRnÿó(ö?©Uöd%¿9@Ù‚ZnôØÒÚŠeµõHj…_ßŽèÅ;¶²˜YwÙÿgÎÿ8*ñÊ\À,ºÿ­Kþÿ5ôÿß¨kùù¿–”ûáòÙßx$ßÃÌ|ÀÜÒŒ—td“ö #Ÿ¢…u8~‰F6ÃÕËf„½ÞéKÖ\?¬ß—lê*<€ë—%jº‡÷—¥°ßÑÌ\Ü9ÏwïÆfù€‘¯vÆû‹Ä`vvvº½ÈµSd­O+ŸísµÜ,+=µ®UŠI0É›çð.ž{†)ÙÈþ{ê@³dÏ0sËxãt‘c{©BÊ×@X|uÎeÙ»Œÿš1€c§‡üo3VRÇ¢ûµû©+hÿÕPyüÏµ¤ü‘>ÝìôUMb=<Ù‹šqI#ùã‹xsÆà¹v‚à*qéŸæsÎ«jnÁ†I²­LP0@Jß„?¼É `[me<ó3Ì–5„?€'Ã}ƒ$¾À1Å1Zn‡Àþfn øçÙâ©š¬á¶ç qÐI„ùˆzpÖÏÅÌ?ß
óco~yÊSžò”§<å)OyÊSžò”§<å)O‚ôÿô)¦D p 