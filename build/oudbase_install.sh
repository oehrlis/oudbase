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
‹ ã¯¡Z ì½ml$I–ÆšÛÝë©¹í=Éw«›Óml5çHö²>²>IÎpvªIv7wøu,v÷ÌNÏr³2³ªrº*³&3‹lv7ùClAúcC'û‡aØ0äƒ[8Ù2¬²Û0ôGkl@€q6`À_ú#øl¿™‘™õÁf‘Ý=S9Ã®ªÈˆ/^¼xñâ½MÓÊÏ]ñS(j•
¡ŸUöY(–Ù'ˆR*–K…j¥¢”IAQ*Õâ©\uÃð¸žê@S\Û™²µZ#Þó~ŸoÈÓ„ñ·ú1tÏ¸9·suŒÿb¥ cNÇ ¨(0þ@
•9R¸‚¶ÄžoøøßúQI ©ºô-’ÞÐæ·õ52?u°GŽy¢ê¦Kê÷–ÉkZ†ë’MãÄèÚýžayä÷IcÐïÛŽGïl6– LC5Ú†c˜®ç¨®kâê2YQ*Er¯«z^Ó´ÛË¤qjzÏ§«ZúÔ½§öŒ{Öˆ4áàe}àul‡¿lxFKµÈ¾Ñqº&Y´w‰¸4-gÓ´=Ž€œf÷ ô–nzAéùÕõ6:ªÕ6ô;gý›ªÖ-fÀ,Ë¡qbº¦mÅ²ø/X¶ƒÓ·]ƒAº4Cšcö=âÙ¤mÀGÇ ¦]³4ƒ°Õ%Žá,¢Ùº˜°=Ãõ[sÔqtøÖSM«{F®¡“–íÃ:1Û¢ƒ
ƒÓ±9z¸™…ªámw†jC`Ïë»kù|ršˆ<Ã˜‹,HÜ˜ú°zÈ} *Û9[ƒŸ%WXÍJ•…mËôLµKNÑy”bNQ0OÍÏS×¿.„8b4àf¶-b·R £¹+˜œY²•Ú=ó™êAÃ.=m<¥“mÿÁæñáþþÑñæÞúüsá×Z6dãµqêål§9§Ø²tìãåÛ‘¦à6aŽºy¨v†{‰¥n6¶÷÷Öa4Ó›ûõƒƒ­½ÍõÌÑáƒ­™ð¹´«6»éÚmÒ2á‹ÚïÀX öýÆÖzæn}§ñð€6š0IgScãpûàèx¯¾»µ>¿ˆnŸ!ó…¥ôÑîÁñæöáÖÆÑþágë™¼×ëghâÝí¨}þ¹”á</ÏÍÏgÒ£úáÑñý­úæÖáz†þBö¤ÂPÃ°Í?j?'‹…C:Gßù³dþv&½[ßÞ©onn5ë@ÓÛŽ
2§uÒ[‡‡û‡ë…´H—IîîÀÒ¨.CÜtg_‹·‹<pÕ¶±¸DžGyë¦éö»êË0åÚ‘œ*¤DM“6í]·M2Û{w÷É«x9:ÈŸg;'ÉšäCœÝÛ{@{[‘ì&ùÄ}s¾É¾Àl?µý.ÿGä‹¤JÉv’ˆVN=\z°¸Ã¯!ÅO’Š'Ì”!Å¤âZÇÐžÐåÇ1ú]S£|i ¡ßáã“ï	’ïÑ¬õMÓ14\$È®jAoœ!àQwRHŸ'Q^2¤tlXðX„Ø’œTnÇnSöüóý{ÈÎY>³E>‡DåœdÛ)/>ÀõÝJûÝÜèªU·ô?˜Ë7ÿ¼xN_]Xký|Ž—\¾@hzËLŸ§§¾Ö%N­]FXŒGyf
,½þUMuŠõÅ¥ôsÚÏí½ƒG°H*ï¯Ý>O"Bú€¬«>1H¶ÎL«Mš|è·ðk@9ubW2 F‰J,d²°Ÿ”Àù.XÜ‚1ÉÀ’Y"äh{wëèh÷ Ä’ùñûŸeßïeß×ß¿¿öþîÚûÌÒE‡µÆ¦«”~‰z÷?ÁZ¥z31Ãmö^ÊKxüB†«jáÈÐ)ø<CÖ	¢“ÁÏê‹£òÒ:´ŽùÃ6à$Êža¬*ÌÇ ¤4¯Fƒ	²Á”ò¿º³å¿N;8ïi«±ÚA{i[u[ªâ¢=›IÛ»ÄŽ'ezï­n[Fœ7MqØ>ú(©O¯ö“99ò®‚?,R\P("QÖM3AØ p/`ŒOMï
„£q_‚ðÄ±ÇY²‚ì8È^X
Ö\ä®°ÒÆ¤g‘])Bvà¨}ºI6@Š¡ säl‰ÛDíÙ‹JâªÓàÙÍ‘L®]Ö½k¶ƒrÑË‰U'­ÂLqi_š~e,|Q*¡bHú–íÑAuq9£[È£úsUÁÃúÆÎV Ýß©7"ˆD­•£õ¸†GK‰ê‰jvQz”ú£(ã oØƒ®N!xö@ë°öKBûÀtmU'çŸßßòÈçüFŠàJcûÛ°aµßb›ótÌÐÅòå±å·0„ÍÑ©!ÛVœŽ®3°,”_¸NH³{=Õ’Á_œî
"z"ÔÒ8¨»¦ëRÉ*.e‹=	mE(ñÆ*š€
,Ë`,ñ>ô§kð^›|‚Ðíl”ù	¦„Dl•	ñ	íPÀ!NëHW¤* ut{$âUCæg>R<¿òß¥õ‰›|í±M–ÐþÕÕ¥ÈNå§¨$;U-K%.ÈïµÛµ¥iú“±lçõÄ²O-Öõ!ò^3ûŠ’óó—Ûthôì«¨ÙœŠ†Â‰Ó“@?ÊëÆIÞt»A–[€Q
Êèþ,	¡êÕƒ°øÙŽªAÂA[„ŽÚÔqfYÉÛ9’¤jÄ¼Â&à‹2dŠ¿4WÛíßŽf…)i¸†ôòzH€Æh3àè0y#………>ç,í‹T~6&RÉâ£„f‹ràEä’rÅEMi»[T‚ýnË$$´*šOWÂáÍ%/^À›‘¬y-6PªU)@mX×"§¹ `OçÈüb¹`¸$f©>0PB/E¹i Aï!H¾Ïäê„4—1QÑ_}f èeÅGÌ¤Ùú
©U2Éì'0G¿B¹Œüþïã0’Œ »ºÑÞ¦ƒ‘ñ¢ˆ
{f
œTÌdˆcÔ?’eàvUóRºwú=Gí“ŒÔ±r!ƒ{ütšs-Àº ÓÅ
édÌEÔÑ íYTÍòd8^˜Lˆó­mxvÈV.ßwlœ~¸ÐòUº‹î«ƒ‡ú0¶â¥IçÄ\Û\ûrmkÍA)4Ø1RDè’iÂbp²‘Ó…wæÙ=	Étÿ PsOZC71ÓïÉñ¥ŸCTÙÉë,‘Ã­ƒíú.ÄZµµ$Se2”Ÿø-’ùÛâF÷h·û‡<#Æã"(ˆLm>°(%‹ò@:'1XË5µ›çVŒKdÈ¼šs	ò	f2ÌêßWÒ˜‰éÿçuu¨°C\œA@pìg=œLŸù“vfî*$†ÌC;ås˜äy‹	Wö3åˆB"Œ`?akFñŸ`‘85 ]'˜'J}é€dìëZ6“¨…>O'P¯_LL óÏmòŽœ34ýˆ/‘ñü£V¡r)>8|ŒWË…€ËF¤Ò(§yÎl–'g[Ži =AŠegõúý~àØ}ÃñLÃÅ–BÃQØ‘Í=h>KûD;
=$Ó:õG2QE)<LãØ1Öø‹ÓyY‘²s*Qùr@„˜¼YÕá•Ôãq$ž´gM²àæ>ŸÏæDJ„R_Ú°<ÝQµ'—lo2eyoÐõÌ>žm¢éE "¿OeSØ½xÆSüùüó½Üüc+Oòœ?ðÏy®5`â«%BQl’¦;P¹Å}†sû-$½†8&‹m—¡5Yˆeá‡¢†.Õ½ä³aì@Ú–êŽ«ãd.Vˆ
\|€5ŸháV±Ã·Š**ÆØ1›,·x;›õúO#XJeÌ0Æ’ nþ¹Éw2õGŸïã©Å¢zú„,ÜÙº·½÷ü°±žyleÃÞí.ýšù`ûÞÞþáÖ,ëÊl«µ^ÁÓ!…ü’ä^×uÆ œu¾ˆI?\ÀZ”'Ï¡S‹ó%–¼ÅºéKNárŽÏé¦„¦É#N–h[¥yôòÌ‚Ñ©(1i~üÅ‡I¡Xòzy!–üaº[s=s8ú¤q6:S*à?Â,‚*`ÒÐ‰Ãø2Ìawì&ŒÎ~Yû4ùJ…ÐËŽ]©¨&oþ`Døúæîöž¸ø]ÇT½gZ,dñÕ+q¬†®aR—†k¢Bý%Fµ\”>>ºŒ‡ÖøTˆ ~!Lœk™8áž“¼d±tîÓzüè—@ë{¨¢êâði½RL$ö‹xqô¡z¥(‘.öO>4v¤ÓØAf_µ-êì¹þÇ·ÿf&|¯Äþ»T.Ñþ¾Õ*ÅBÙ+3ûïëxföß¯Èþ;˜p_ûon¬‚(âÏ‰‚ûu7ý^ÉÁÿWdú­”¢MËsl} &ì5*rû†f¶ÎB;|@Â´­$¦k>þõ6Ÿª%ø…ÍÀ¯Õ†ûdÂ}öÚ	ÖâH
—0áŽ™
7>"ÙùPaHšÜdû2öÚ“kÇÛ¼œ‰M<‘r‡”Žu/(½«š]ÂõÉÅg6Ò×j#Mf6Ò3i2³‘žÙHÏl¤9‹¼~CèVÙÎ‡.|3é1ðg¶Ê´Už’ï«°*ÙO~Íì'!ëÖÞÃõ±Ö’Ã-Y} j›™P^‚j§lD	 /n)Év¿
¹2SÈÞš¹¶EÍ!¯Ã²1Ä|±Ðü¢/çùy_ êÖÍ?^Î?&ùöÒ•ÙQNÅNòkoJÇÙ^dlX5gR]A—èì#LOm&êE"#JaØ:ÚàŒAÚ@‚»E4ÇÀÝ¬*[P žÆ Èö¨Ï‹Ð¶ºú±GŽêwÖã%d¤è8ÞÙn ‰ ³ë:!?¿µºœ½Ð´\Åam)¾q4<ªî¡uŽ,	aã)R(ò'ô}œ» {4U JÏÆbØÒÍúQý<ÝfÂR‹[å†	÷R¾Å×0‡
+¶…š÷Ò;<‰‘€È¨Íp1oRÆ€†¹Ûóáß¥ÇØŠÜíùüc%¿°vMÜD›¢KgÏ/Ípº¸Æ(²æ%¨±a:ÞþÁEæÝ ;dayÀKœís÷Ë8¥ìÜ´"”<´î£Éçîc‹–ûÍVLÏð	Ù÷Ô
æ\Z†¹zØ}b£Á¢|‡Åñ‹Þ–Bá!v‚ŸÏû…¾9è|È\Þ„mâbä\£E^ÃŸn–ô‚þ„úÅvÚ9GÜœK­,s°2r·e¦—¬PVê]’·¡$:ÃZ/[iýeâÚG3D™-’¨À¯¥;ÿµ,å…øò^lêéÁš®¹O ‘dû¾éÐ§ÔôksûPÖKHÍÞcŒÐÕd¶¼Ìÿ.x—‰A¹%å–ØO<v=…¤EœfY?7' shÛã¦úrÔå"9ÈÜŸ¾ÖìªÖ“µ/¾XXŠq$,œ)rµç"Ì%Ydi]Áï80²u´€“RÈ‹L–YÈ?Î,?Îäc òí0G~-ÉZ66@hg<u¹-¹Ï?÷ãü8hÚ9èEÐÃ‡×¥§zwiŽƒÛÞ{ÑrÒÚØßÝ­£¬Ï7DÛ{çy1ÛÕa2g³Ûõh'¨çþšÈ.q"Cú¤f¢œˆ{Ì‡Má€"Ó‚7v67Õ3®1_øñûƒØ/¤Iñ¹„¤c¯Ñ R"fUiøÄìÃiè[²ae6—qíç| nPâQ‘îq‰CìÞÖ¤„ÃÕ3ìPÈàNÙ¡ec&V'³Â”Qñ¢@ž’¬Kµ*û‡k[x6Ô÷8ƒ„nAâ<#‰crq‘~ù±²$ó‡DõùðaŸ/î@Ã]¶Ùg ÀX¦Û1ô¨ú=xIÛ~‰K·O­e?ýîŸš0ëš°£4ô¬6ô\&P–¶éóÃÈE&=?Œ,=$ånÈlÌYÇ<LÏ–qû\Útn*ÑëFÆ”¢ b$bï*ª¦³áÿ†[½úöŸHÄƒþ«‰ÿ[ª”ûO¥TCûÏbyÿ÷Zž™ýç+²ÿ&Ü×Åþ“uè›kÿYÍÁÿcì?Ws…š”gWýO	)®]Ä"—uýSÍ¶ZT—¿s‘iúÌ t´7Ã ´SÞØèÂ×jVzôÙöèÁÎÎÄbòÇìcMGg}#ýÉÖÖÁzù"p8°½A¯	º÷È0žÐÉúÄ0úià5}4\Ïd³þ÷	ÚÉB+„EÈÝ®ÚžYÐ¾É´ùIõëoKt4x„Fp¢¢µÊöÞÆáÖîÖÞQ}gf“ûTûZÙäÎâÏlri3›Ü™MîÌ&7û:ÙäNd’;3Êå¾œQ.—íâF¹3cÚàfÆ´3cÚ7Ê˜vÚñH_CCZoÍ\ë­m]…­[ ª¦J4F½#Ûi†YÆ3Î¬FgV£o°Õ(?ž›Ðj”Ý÷àòPqî/ýÈæØ²/*ødÅºÀÕYí¢V\ø)¬xR&?Ž´\/¬ê¢sÐµIGäÔ0ž‹ªâÓ{[Žmm}²·/è\d–Òû;›áØ„Ï³óÏñà|i‰¿SßøäÁÁqc(Uz•B!"•"ïãV‚Ds" =¬bTá°		…å!ÚŒõ‰vTn„êò„°âóñÀðhVÅÓæ'«²ØB
YîÒÌz˜\ÖŽS6Þ|m-‘ÀÅ,’q¼U˜:†w:
é+]d[eNIÔ(3Fµ …Y³
\+l7þz›!^xEI¶¬Õãù'oÜÄÔgFç¸‡™ “Œìüs¹-B¡Ø«	ÍEESQ’4v|»Žž7l«e¶Ãaœ ÅAZ¤dØn’=x¦µ&ÁQ^´Ãe0s^ûÛæmìïÝ%ëõ˜®ù—øàîú-:Îá6´k%á†vº–W5x:øAY…ŸõþOZu,1rlÈ9šÉDÓú¦>ÏIXæÇ[‹ãÉ­‡[ßIœÔ0*žÈ ˜×òÒÅã‰c:ÿá¤—Øå	ì…#âv}àÙxU’¦B	º¤óaZp‰ÝÕÑ^F ¬A—ùKñ!Ì-²ø³Oè"¿
	š!J“Ôå‹u’L7#wz$ë$ÏÌÄñ'3Ã»±g‹]hÙõv.. %4zièÁŽ—Ò”L½yóf¦Þx^µ©íkù ñoî8P³^I£í¿…r¡Šöß•BQ©+ERPJÕRqfÿ}-Ï·ë×çÞš›ÛU5²ß Ÿú¬	ÓæÞ†¿"üý
þàwê;“¬²o´Ä?…¿ßŒdù5ž~snîw@Ï©ý~×ÈuU×C`ÜËß:hpßÂææ~óõTÍÁÐÀ-^—]†pˆÆ³<ï·YÞßäEæf×Ø¶tãéÜÜ³¿ý3Ìý×ÿò_û>~*×Bh¯ç#ÝÜtEuŒžÿÕRµVˆÎÿriÿûZž™ÿÇ«ñÿ,ñßdß¦œ¢ž¸è'`ø×J…žÑëdg^ WáRˆ{è°»ì‹q"è¡Ââñ ¾‡›×Äañ˜„æÔmí‰á$zˆ Ð¶á#T—6‡«	ÙùŒ•çœMÁÜ >$‚‡ªc¢yÍËÄ#´†A¯³¦¶õ'Ì¶>Ji'A%h«a{äÌ®ÀÎ‘)w‘ëîïÓß½~Iò¾ÈHJç;õÆýãÆþƒÃ­Ï_À¦3º»eº2žß¦÷ñ9æC…}3ÕÐZcQ7š3Øþ©N²ð¸UÓµ»OÙ½‚–ÁÞýà)¬7çò0á¹Eîâ•_Ô®Ù2ñ|›ñl?ŠŽóy±IPµfuÓ›[wëvðòŸM‡€ž^rR[FÊÃ7óB&¶¯–sIG¡<Ÿpd-dmìoîÃWªW·‘©Éwö7ê;b.Mahž; ’70Ú!ž³\†§Í…3¿ÎöÐ\G[»;õ£­Ï‹w	R²°ÄÁáþæƒ#±}êBæ	PÙi2$ñ,­Þ©RÌsJ®”+Ä2ÞÝ}4"3ÓnQÕñö½õãÇô˜™a&ˆ[)ò} È#q>üµ?çç"Q
õÎiñ»?­åf¿Ö²‚™ÔùDÙº&”ä°ÖC°´ŠayiÇÖE[­1ˆÉø×Á"7ARÃ‘Àã­å”„…Ã_Ê³ò†Q°#êò‰˜"™Q…?ÚÔ²ñ&šïÓgÒ«Æ"#X™ñ¼@-K¬ÜØìò‘4öŽjÜé!/|v­ªˆa\p×Cƒ÷MŽÌ¹ ¾gºƒë#Ð†&@ù‡&0ÈÝ‡ŒÚÄZ%Š	8àº¤X7Ê;#€%¦¹[x<ð8Ë•ÁËŒ–—ÓFO`Óò`øs»ƒæ¯Iãrµp–â¯ØÇØ¥ÔªŸ»+sÆ°B?å²•J<W¨ø§õ‡u¿Êàû+ûR=Qj‘s„çÉÔ¢Ä/\ykãhÿð³cfBGÍ–x#"ï 2)6'öÄ×OE‚œ¶…°ç‘"7b÷Ž>Ã@¼÷ì„~ú§Aí5·GTã©¡h3òœU©·‰çVü+=¹zÍ­’™é?GˆØÇ)å6ËR›’ìÿq `ísoàXD‰ÞßL(Üõò­EÐÒàeâ½í¬EüÌF‚#´J°×D~æN« jx‚Ø=ó—8Ü¾ä ~tÍõZ¦ãzmÙx=ê©	K“c tÓóï©æ¤uN²]#bË+ðêúÃ­ÍctŒç‚Xp-f˜+~öÈaqræDñö‘²A–Õ3ÀZ¡Ñ0³L¤DH#âúŒd","™¤úÆäJ7¾ð}.Âð-=/,!xLnLÒÊzÁ¶Œ6Å7gä*Æ..ž¢‘©$˜œ“˜èqNDL¬b‰`ÈX›	6Hæyé—[3ñUÛ¶Ð-$´Æ‡ˆß©-8ñ½˜w"—Ë…mGÌ±¦˜ñ7!T(“‚ïžÚš(Eûm|éEÎñ‹q}kªq4!o×&1Z£ˆPùÜ84ííº6,.è~k·<4{}Â-aÅ=€EBÔTPÐ…5Öm‘hF"ïÑÛ·CVÀL³Å6"{l	FÓ>œè>"Ñð<ÂÜ†XG'¦”“µ™çdófB[z¡Üâ<bqcøKÚ·óZ©¡n¸%áhs!¬PF¯ï…D‰ÇåVƒ‡B£ÍEÉŽ[23^É\?"aÄ,ð©ï‘jÉ0|VEbªÆ÷™$žÇ!]Æö¾9Îä>2ä²6øep*—pØ.€“I€gÀ“9ñ´£Ÿ«	&\‰#nÃ#E+z©*´©=ïI0‘§BC¨/Áÿ#Bw¦¹aôvqZ{Y:›6Qúº2§	QvT]OIÀ3Ê QŽ5ŒþnQ0Q*Oâ¶ó;uld2uKô×A\í²^¬x5 s¬3D^Ž)¬^‡àÂ¶úUò8Ö˜P’ºŸÐ˜Ý“@,¶ã}iˆœïÈÛghÒ²,BT(‚®À©òuÁÄ@C oà’çÑ£^ONçÁgDÓk$˜4ˆÈî”†cÃrô ] ñÌ‘5Ž±åÍíÃcþ2c?‘bþD4@”¢£ù®¹?
¥§p¦0½$åÙÎ€°ØÐ±•E¬ý'?	×??Í?.d\SÇð,\Ñ1ª›­­IZÉ[¨Ãà\góPgzæq>íu§×@Q¬O¡3Y¶q–À×XKÙ;º"‘
¾ ¸í¨Z×8¦Þd ,Ó (Ûívsôø3 È–çËÑ¼¸Ð‡ÍFX«ÖbÆë‰îcsçC,/ÅJ²±"Rù}ÖYZš†jé!õ5×àùY•çÎÉ¨ÌÆ@ïlÖÈ²g"4#«Gepšµ!çåYXö:õ¹HÌN•±‡‚£/æ8Ü:¸À¼¾–žN4…£nþ,Nv× Dl
šÓ¬åó‚QÂ­÷®n/ÖÆûGGD~†u³6³†Ýñ-æ§2·¦üGZ:ýø²)®˜|iå–¢ly'Ã=s`Ä9OQÌf'A4È²à,ÏDq.µŽdãi±ŸIOFÞ|õÅç–¯.°;–à³|8ÈÎÙáº
ÿª-zÑA–žU„;>ÊK¸—T”!¿<°Ò’¸RJG_/²:äÅNÓ|(	’­<¬gbF$©%¤Šoå³Úóü¼)0“¨gO€èW øçôÓòZdáýlÅ%ïg•"þ[¥_Ëø¯‹[Åx¸*’¯{‡½Ìüâ—¶i7ÏH2!qœóO$’à;%d4ãÊ0§¶p‘¶¾á¼¼Jn&Œèseim¾Cö7 ÁÜÌû±X8§»¦æ(áVÍ7Ÿ	Ä¡óô%„ŽùÅ¡®æ¢«ù¼‘ÇŸ‹8Ÿ)îèÏÅ>ž‹NéñBt§m_ô>`~eì7úˆAJË\º¬€2¬XnÖíª}ýµëw2šZ¿O»î«ïØ‰º•W™
æ‰4ÛÅPLˆ	f<FÌsû6;8váÎÈïÌÌý‹ÎéÝÍ­Ï+òz”uFlýÅ]òêD7…b×?œœFpÂ6WCým%S£ÀRW.<ÁõF¾š¡&Ñ¬ úÈÊjÕâz|fI0šrä k úÛxŠ(ÓëžQõªP(îÞ	ä)üŒõè‚½¹ÎžÄ]~ibvc2iNÖ—ä½zò>]hÀUÄ>•XS·LÈ<ØîãÍ`¾™ñE†1ž3Ï $Žh\_ÕUù´ãÁ“¬EòTƒ@ÕÔ³‰Å†µ-‹ŠùåüÏçóý¿ÁFAw³Z«ÅÓ&Ã¢w÷ñÝ†Hû¿æX¼¬ï>1ÍÚøJª±qÅUnÄ:)ª¦‰Õ«åg1NÎÏÎìÃ¦fn~vËçh8¿é—Ðeí®Ü¸ìAÔü3¥(wI\ØÁ¦´°ÿòóœG)­¬&çaäl»0oµT’—ÒÁsÿ+ä]Y•à¾<ß¾GË$­Q5ñq¤TTíSÒEòŠzÇDõª?ªb¢_JDu¬1ëÕ`ñ:ÖÆAÙ¹:+¶>²×tz¢5Î«_ ÃµœˆDÖ²DÃ£8#ª¨â[óT‹Òé «ÄÕÓþC³I2ùHÁ¼öøq$‰é¨×:](p- ­µy-±oãåiFŒª®G{‚ÆC …å¦Ôâ>Öæ8×¦„~…*ðŽÑMP‚KgÇ4‹ï,#Æ©›²?¥Ï'"†t/-“öun!Ø­½‡—sCÁ‚ˆù q´¿‹®hË†l(HNÏÂþ<,$BXHN
Ì…g]°«¼|vjšÓ#Ù%¥¬]JŸB™Ð<^nVÉï›G»á§G²‹Îbv!=¹„ïs-á§g ØB¼œÔ•uyç­I`1R	!=^DÖ·‡EäôUEÊØ®*©\B×%F9ë:×¦'dåw’Ç²²ô¤Àn“`czRvàÙ‰Ù!]Ê.rÿz·z×yü¥øHØ
}–EÐ‰oñ®’£ú!3tçg<GV.Œ°ÀMàÏ›ç®È>ì¶-_Rv:˜„¶ Ù?@/PÿP@ Ð'1 LÌ[Rbiz=˜t~J·è œ²ºõ G$¶FñÇ¿M+²±EJ Ñ‘A¸¹ƒ"<áŽ„åy’ÔôÖ2ÐÐ
±rC*bâ˜3T¸!$¹!é±+1/Gy‘…×§Œ¬CbÓƒÜ[øn›Ñ5Ð¤¡\ùPÅJu¶Ÿ)XA~¤…@J¥yoòÅ$"kÖw¶ëAt|šŸZ‘B+¸!©»˜»½´¾¸ÿ^d–r·©))	÷àu•ºÖ…±xaÌ¿XdP– ÌÒ|þq1¿ å9ÿFT¶‡ûE~®Ãÿ~V)ð“ÄL‚†þ9íTôŸL þ\2ÀsA¦…IÒÑá•nxüÓÎøÑáOáQÈÝèÒ@»WqHÈ<Ð·ïâí
JævÔ¾Ð}R®°óp´
ª…°Í=	cg€¸¦0|+^>«¾bóHu EBrQ89Å b¡¡zI%ÁÅÇ…ïñ!(•ÐñÐp‚Ÿ¤@×Rs"Í¬A‘BSjÒ†ÝëÙÖ0³õy¹Ë·è¾Æ²Oi¾CÃ…•}=“Ò†ùyR¿nÍ‡Ðy“úþÅ[Ë&=ÕÓ:Ë¤g¨rVÕƒYºI•Š¦Ûžï Êo¿`´m¼¶™Iƒh‘EÇ A…–"A#´^ð	¹E—2¨ÍvtÖ²Sþ·X\ïe¶"ø·qåYàaÓjKjXèž‘y†RÚý˜ÒÁGw.7Â4$Ì”çÀbº æ9Ö+ô‰ŽG>¯ÿSg×¡®ƒ8ÚŽH^„q	ÐçuBôùíàÈ=ÍÁ™¨Ï4Ñ B€[˜ÀÐ=f„ÏNS‚AYæe09ÆäÁ×–me…,4Ç]Û9UÙhÊóÛ‡Mp=S{B/uïÓEÜ³¡l‡Ï>>–0>ÔD˜¥	ÕÆÁƒ˜Y<¾Ÿ ê¢=G%nc’Qßµ¯ç¹ dM‘R¾@øtq%7‹Mïb%ñ&,ÿ¸hB'A ß­H_ãùKn ÆS³]îÄé;
N]µÇ<n,ãT’¿‡]Ø³ÿ€Œ?nNb
'µÁ7Š[’ÀÅÂž‹•œtJÌTpLd“À1…J‘Bþiß˜b;F~’5¦Pe„™á˜¢S7'ŒP¦dõÒD$~ˆ_î¢zî(Œ4v ò2æE£*Ž:¯xˆ7çKw%ÁP!
rdÿÌn_öêV˜EŽˆå‘t!¾à'A©n¾7œÐÌ ‰4œØü¢/fæe“‰dKžÌRN°aGŒÃ3‡4FÓeJVA!BÉè1Í'Òû-ÉÝ=®¬‚¿ôzHŠèðiM C”ï1†cÐê€=$Žá´)+vHHt;Št vôÃÌ‚×³à5É,x-T=â÷(Å{=øê—Œªú˜3*ÒgŽqbÂZLûBÏ¨ƒ_€RáÃïPáþ‘ª…› †]½Ò¶Áö#4HäkO‚Ë?dúÊŒ"¨(E¢ÿk‚wåÂÂOàÑ<…YøúL¥W>¦Èœ_	‘N.qßóùp«~ÜË6aYîsÈAìº ?û!TâÉ¸Fà¬	¯ý
†]ÁÍ*¤l‚ByÖ—+‹qI_ª †=ôcLŒÓx ˜\„.|íúÄ(f7U_†^é4¾™Rýù•²ôË@?é<„]².=tRMöl})ÌLâ K^3¯vÜÇE­ÄžMT³†›wŒÂ–¾È,Ímlp« ðîÚPCÜ¦i­É}ZÃèñ÷~ô¹‹íÜ¦Þàé56î½óÊ±Û2‰¹WŒFO›¹‘³cÐØ|á†zizbÀÆh<_ÒÈ@¾b>Ú±-ÑÐm—iMÖ¸FE³¡Q©‰·'°FºÞ Õ
ã«Ñ˜jÃ±Éo]HŽ]rÊÎx‡†6ƒÒx>!†Jr0#ÞÔ¡åY´Îí~‚Ø,ù¨Ó:|ÈÍñ‡¶a²šÝØ°ŠÓê£‰›1DèÝ˜ÄB¶ÝW]÷d(ùî£Â“UÉIâVtqÜ?ÕsÞS/™)=Údé^\,r *ì¿Ÿ{Ë¹&ÆÓ=§è‚ ®±x@‰Á‹(Q7b·î²›cLxèÅ’Xh0"ÆšŠžÖý?º­å§kØ3îþ7¼/‰ÞÿT*Öjå)(J¥Zœ#•«n>ßðûŸpüaë²¹»•ëéWT^òU.ÿR­æßÿŒ©P©ÎîÿºŽçV`~–îÕ¢ZzöŒ«¿niË:ù³îß¤°<]utó™ïícöúôæjØãÓå!e·ð}Þ•@$R!¥º€0·i‚wp¹šÚ7Ü©wñÞ§vGŠ=àÛÊArÕ.¤×a÷°’ýmÉÐÏ]æVƒèÃÛzfÚïšÞ€6ÞŸÒ÷gö ö9¸=<§=îBn^Ç*­ìâ~“RpY:5¤ý‚ÞÈ­ÅïUl=ÄïO)ø¦ƒ1Õ Æ®MƒbZ&,1-VÇÐ¸é£QÂ35«¨7v—	HìË4Ó½…Ý³_Ê<í˜5ˆ1ÑÓ2µKE8ÔŒ‚(Le•®!t"—Nßö‰æ6‡°xâÌÞ‡éöíàŽ³Û·9Z–Ya¦poEvó¥ÒX5ŒâR+ «#†îv=g !(
üP:°ùP1¾ôr€}j?™PÞ4föÌ®ê Ÿ¢=
$a4D@@„Šp‚Ø–wë9²M3Ÿ:¦çÀ+ó˜õ)Ó"cF6*;¦5xJîþÙþ´
Û¸IoÕÂFyª	ˆ¦åU·ß4èØ‰YÙ¸ÑTSµÈO×=Ë7<ä¢­ßíP)›FdvëŒÅggÍÈ FéÖ-<(ô#ÃD¨Ç Ž¡°ƒ?é½nÜy=D¹ÍuáÇ¾_;kŽ<Â	˜HzK+
¡3ÛO@Ìõ> ‹ÖÃÆú‹_ü‚^@ÈôÎ¸µ_æÉç(?iºk|Aòƒ‚’w;0Wõ|¼2’í¤ñ¢²¬¢d•Ò±R^+®¬UVh šÃ#¼U÷Xv‹$]|ÈI!§,±fƒÆ¯iæ¡NÁ¡¡cv†sTá®Ú6–“òy¶sòüÛ$
ÆØ}AFÂ#PÂJHjéZ/xGoøÒïº)"®ôÅÈŠÆ´"+ÛˆKí3Yôð¦¿^0Ñ6–Æ;Î°(í#jÚ0u{¶nŒƒÁ©MôàL¢rd—8ÊtT§= ó‰]U8¢ªq ^`\æ¨;TCé‹í\¤#„„À„Ž,ún¸Á-K¹qUè¬
*œT½H0¹Š™K_a§1¨,°Ý¦q†i‡Üdˆ‚SŸ`¸úS\Ýñòv´>æw†\Ø‡ˆ:CDx¦¢ãŽ|«„ïÖÆÎd¤#¾òôÅRf\	órLÌõÃMª“½_©I$…XíJC÷‹„jƒ—cgywÓ[¾Ø']¾gêz×ÀQ[÷U`úå9èŽÝ¦ëäÉ{½~lëÚm\$Óémqi6žªT4£†Òt»öy n»(Ñãï(áã‘æ \¶yû6gLtr±™vÆ¥9É-Ä“‘¡´ž\ú6®Ü·É¢/Ž±HÒ¼='vXë¦ÐvS\œ&3¥¥;ÒýŠ¬Á±ÎðåDù¥I’&«½)äAúÈ³d.^°–ø“%Œ\E"0Ç’t
{%[(f•ê±RX«”×
•‹É#J®+øÉTj¿€ü2´ð¦|A‹í0²ÄZRŒh×>Å_Ê‘F„Hz$¤$gK²ÅÁhþ
)>‘ä!Ê@(xp=²l’“l¼zæ€‡êÐ±À†5d\Ù`—[.æ†ËëCšŽƒ®§r«é9Áø[*Íxð$Äï©Š~‹é$ d×â¡ òÒE¦“ –„§8ÉšvzM_þKý‰’[ÉŽ•jq$¤ð²ß8åç¡#AòuF—ƒK¸¯od1îç(,„ë¦HÚ‹Þgu‘9ÎÁ†þ=ÍîäRã¦bR©87x‰ŠÇÏ¦ärÌ£ä‚“1€±ýdöÝ¡md'hl!¢f®ä!Y@¸`ßr®z2š$Â‚Á	,+íÿ¼ˆè™$ƒIpý^4Š îÉíÅDN> 7çé?á™NI?…ª‰)Œ
„¦ÌKóˆgiÍpÐ)	œn>§ié(!§yôŸèÍBbô·x–ë'Óë´Ø×‚Ò]³™OÃ¬Ì§ƒÛ©Å¯KüM[þÔ€Áät1%‡bã1Ð¾& ²ÛŽ83äìÌž,!…}°›fsý³! CñÖÈ‰ØâÓ®{Lã­Ó°²¦fDÞûÖqû‘7@ ÈVaó EßÀ û³5,Eæé›Íôh,±‘”xh0!Æïe6ôÉgdÃ/Ènt¦â<bæÒM}C…¤8ª'U¤6¾¿cÑ"²²¥—A…’ÅHS_š ì^ ð‚ý@íU§:yßM¢ïà.+ÿêX–ç"«ï A´×P7µ[f'½cvØý²c•Ü,\)Ê¯„VýÙáDšÅ1€¤õLŽ]w»¼ÄM3²¡ˆéå¡Ž^~ƒ¾óðcŒ2‚‘bs-¿ý‰¼	·§>1ˆ‹g3@W‹šØ›íŽ7DÇ‡´µ·‰F—‰ûb¦ýÀã ÛêžùÄízFŸ¨-Ïv‘H‚òimNx.%Ï<Éù_™àz;G~Šyå‹ç…ð¥,Ubø½i`Ür;P¯rÆ4dU¹-*(.;MÒdÂÛ˜¹}ú„W2OéRæ‰'Ï"½}1¼E9K=Êr^3KÆg¤së†ðTFˆëº£uLÏ gŠéô³@¯qÛ?ÒBež†ŸÚÎ¦VF? QAÅ4W\1œ¨Ü=¥·`{˜ŽKÔ¢å`ÓCPŒRùÅ³.Ú²ydX.7îCµÌR®á6|w×|’x’ºL¯>U%em£²0} ¼ÆÄDµ84cÁ%š3@¿öeæ·§à",ì#;ö[È”y9²Ü-9ržš]v¸<âÄ<¡*GAåh„T\H\Q…Ä£vaŠ[,xF3®œMÆŽÔ\dhË¾w™[‘¹8*§4L‹‘F€Fœ°·ê!w©@sÄÏž™¦X2——ÂØðäÒé‰</È¦ÁXô2&Ø}‘ÑÌ²o"=¡Ç°üß÷„Í€ØÇ|ôð$Ï¸-­SÇå‘]aKÁ”°žÔã°­„µ¿&½:ˆ"˜•9Ú!¾íŠô<¼Vn)ŸL~ƒP½-iù‰&žóø˜Æ8Åäe~$Ã¾c .jÂâR„f'tûÃÄ*‰”	XeKCt„ñ/Ì.šœà)¼¿tP.Šgé´ù”¡¾ÍrZÈqŠÞóªlo‚ü¾w/*GvlÞ%»ïäŸ”¸ªa@åUtýB{è£ÐSƒ Ã&pfŽ5LžVåîI½›;:†,Ö”:À„±M—6¡ÑrÏ¶N<™¦«(e¬MCN-î¶È"-vøñv“e¦K#Ÿ7Tû­tšß3žz>Ò¢
iCÐÄ‘˜ˆ­XßbÙI£–õÌ,×Ë7€fP#öXA®Áöºñvò=pB3_°EaSÐ7"ZQ8êeòj¸\sy<YQ³4ÿÒdL§¬•ÝtKypŽìÚìÆdÊÍ]êS-(pý»°•åæHw»ÆS×VQÜY¢P%£'º8‰ÁM£ŒšŒ ³æè'¶¬Í˜¼Ü%.zdDÖ‹eb¡jñy™ÌkºÝz üÀŸÑ#·Ä^'œ ãŒãE‚ClVuÒ™cåUñçeªÏsäA ž¢‰[3©Ð%""4/vT43ÊòèFŽlŠn>;õ%	*VIBì²¤Zå]\²d™”‹èPGÏX“g¨ÜÁŒLm€¦€&“‰ýJEb.ç„Âi îEMOh|YxÛ‹ ×ê ³t'O)®+cVúYœ“>.…ÜŸŸÊ¸óW÷ámC(Fjmn>H•ipLÁÔÉ"r¯Ï@Yé¹5b{‡÷ZÐúCØ€°BŒüöªp(‚ÓS²Ëh3R¤/7¶—³¹/‹ËM‚9È°æŠ£4¬½´Rÿ*EúÀoV)¾+•3&WŠyäª†?ÉãA«‚é1¶*ÈCíæ’ú÷R•rÒM*³Cg…ÌU7Ç;›Ûw)ñ£!ÚÀDcZK^¾yÂÈ$Í³‹K*T(Cè„ „¬RÁä)ñ ‚±ßÛ_„çmÁêƒ’¢@b®ÄšxDœØï¤Sãr9Ræ§ðž1Uß„*à{’í®Ù¤5Å%Á¦,Þ²!+Š´õ—–ÚˆùÀ˜qe:ƒDZµÔr[1²¸²¶€‡xŠãxälÃ-V¬ç/×‚áÏ_öNðø2a‚jÔTÐ‡'€âÍ#Ž ?òR;}¦#‡q²Ô¨hØ¢"½Jj®pù“Ÿ‰ë‡†ÛJF+O\ÆYåÝñ•'Dñ{²šé¦åa¸A	$ý¦áš¾ÖÇ¶4Ô¶qâî£iŸto¼/`-˜Žœ1™]@L¤54¼…òœ{ÅØ| €^B, ÆíVÄØÕSŸÀfžª±ðQýä{£&àå@òµ'¨´ÝXåçN­,&RÌ×•×ŸŸ×/ÕÄ®l
;Á5o´i h´ü$@¡Nm<¸H,ý$pQMÜx ‘ˆûI@]ß(`|“0ÇóŠgÐÑ‘âYø¼âñÔq¦H;åÜëŸ)º;D\#ôë Ó³¢žÂ¿í}Y¢\GBBg`ä>R°â˜òèø\µ#òîØð…uæ‘æì  ñIrªÖ‘Ç9pÓBå¶;¶Y3T×„Í.ÓµÑù'-T”0,vpiqo*±†@'E¹4ükÈï©žà©k· 1Öä©jŠheøŽ*ýt„ûÓ.žûÙVœ±¨½“™n(ÐD•jL”ÅØ
a!ÂÞM“ûÚO Œ¡\‡¦WìNZ$C¡ÑOF4úIx>¦âI³Ú6²˜ÌôÂéA¹î&Ûi
~0#~€`]~¯sa¡w@DªðÚ"„xbÚC!â;¼wš¯ÝƒÍ­‚ÐÆôHÊbŸPÁõó«è]Rk8ÂT~IGp©”ÙÃáP…jDMßò•Ä¾Š’š,á)Œi%)ß±²šŸ2UAµîçâÃÊt±(YA{;+ªÜMI°nÍðÕó\Œaµp‹}TZ…nœvpä`Ž6Dº}·tèÉ¶ë¢Ñ>·¢¤B@šƒ6NÜ) †ºƒôG[À#%B*ý¤ñ°±ŒUúŽÖ~.:K ‘ŸßƒÏAsOZ B‚¶Šèk±Øñ¼¾»–ÏcCsmš	ðÜËS~bi$Î—¥¥ÜüÒZ:}›|¾å›z²äŠ À6:N×ló,ëwÍžÉ¢MÓÔ”ÏC¡%Š¸SÃƒù4LPºLá±KÒÉÀ¢Þ*0Põ>,Q†Ÿy™øÅ\!G>³ÀRÎˆÝ¤Çþ*hÿÌb^„¨ù›­;==Í©`ÎvÚy^›ßÙÞØÚkleèG ›¿¼ÿ?mæ¸3ýô¢
ÈÏèø…BY)úñŠ•Š‚ñŠ¥Ê,þÃu<é@è:4C8AÏ£U2ÁYJOÆÔ“ŸèñSâ‡Ö_ôLK¾iƒ$ 8.¬À.Ó¡9¯z$^ÍCç?ÇxÎí¨WQÇ˜ù_)Õ*Ñø/µš2›ÿ×ñ¬”VÔ¢ZXY5ª­•ŠQ.U
ÍJ³¬VZ¥ŠQ,5µrUoÕÊä'¹|‚ÿ@±¬×”R©P)êåšjTµÕj¹TÐWW”rS«­6aR©€Ð)”}´V±Ú,Uª¥–^\U5]iUBU«ÀèëJUÕWÔ’^-VÄÒ¡_BµVlj%])–
­hm×[EmU-ëšShÕ U¡´o[-•ÖÊJ­i@{••ba¥´jÔT­Tl®®VVŒ¢®ÔÊ5K&˜ë¥f©VR5]Ñš…²¡µ²º
½/õ’Ö Êª¶Z9PÀÊjce¥\®”›*äƒÞªJÍX©•ŠU¥Õ,Àºº²ZU«ÑÊÏˆÕ•ÂJµÝoÕšJ«¥”•U½†Y-é-£¨iz¡Ðèô¢X©TõjKiÕª+Æj«UU›m¥U4ôªÑ*TkµÕr©¥±XÔã¢l4•ÊJ­BÛZ¨­®®ê¥Šª+ÍfiÆR¨"‹bœ?¶ºZjê¥âª²¢V›º¶¢hÎªVTJêJ¡¶ZÑ#°’]".2¢1Wyl¥–¦ZM­¨é% )CQš+j¡\«Öš…•š¡*½¥ÕJqP¢'†QÕ‹µV¹X]m•KÐuvÚj±P-j…fiÅ((Z­VIèœH+cU7
e´•ªè*ÀXWšµƒ (ÕÕÊªR(ëE=ŠàûqŠKFÎKÒ^ØE©0 J•BY­–VÕ–V)¯´
+šQÐ5M[mÀU
JË(i­ÚJ)Íq˜b¡\4ŠEÅP­¹ZV´bA¯KåB©¤W
µ¢¢ÕUXÌdp‚ëN(¯R* GÓ*ÅšÚl5.áßrf®V[þ_«É d¿£JÁh®jY­ VK+%à+%E)¬jðI1*j¡Ü¥™cÏ"½©Wª+-]+”W›åÕ2ðÈZÐÚ*JJI¯iÀK+ÍR´+Ô© s¦E4}³uk½PSV*ÅêJ¡CY^© †è¢NÛ˜²ìƒÄû±ŽÑü”±àŸ†±¢Ã:=’\ix}µZ…ÕkFY+‹mFgŠµ@Ê±÷ZZºZÕªEµ¤U
@žÍ•RÀ(µ`_†¦5«zI­iC:_<¢Hý/ë+:°©Z`ÁZ¹R))Õb­¬i­–Z­®”WJzIQkå@¥ ÆÐ„&CL½Ü¬)eµ`ÀúÛ,ÖfFMij•f2ÜÒ1Ó|£ùÉ±Ýj¡ò€—
£d£Ú,RAÀR4Z«•j¦kAméÀe«ËFLQ‹%U-´´Öj«ªõB¥R)«j& ,ÏÍ*ÎíR¹’X)*¹cëQ¡Vb-VÕb­Ô¬©új©Z lX€Í-­\,–A\¨&'0\ëKÕ&H«…Š¼»T­ª­rYkÍ¦¾Ó©¨©Æê*Ð["Ì¨#ŸÒTtà*jÕ¨­T‘AO›ÀÙW[ ýVµ¨«Í¢®'÷¼˜Øó"¶rEÓªz³LK‡¡o*«+0eK-®f	C+·Vkj!pá˜ÅDáS‚-§ÅÁ¯€p¤¡ŒU^Ai®º+Ze¥Z¨À4Q´d¨Iø¤<·Ú‚ºY‚IÚjÖ´uUŽY&«`Êã5q0¸Íj¡ Ìà””J¹¬*°RÀB<¾YUa-¯”A:lÑi »šÂ¬Tk+•&P‡Ñ¬`™
¬Q ¯Õf¹ÂD«¦×ª«~I_ßñÝòI®…W]Ç„ñ_Ë
,)Åb‘ÅUfñ_¯ãI’§]Ç˜ý¹TUøøƒLR¨Àø—kå™þïZž[?¢›ã'Ôq:š4¦N»Eæ·õ52?u°A˜Úú½er}ñso®µûô¼â÷IƒŸI,ÞÙl,A™†j´1V¥ë9ªë¤¸ºLV€Ý{°:yMgÐn/“Æ©é=3=;õF£AJŽ=k1·x_xÛáïžÑB»Dªm%‹¶á.¡«+¤å˜öcã µ²PzK7½ ôüŽêzLozçŒÀ&nr	ðËrhœ˜¸(Æ²ø/X6éfkjµÍ=®D;	ì°«¾_£à$F=ÃÐô¼mx¡7G²7À¡Á‰±-B "Eêt‡úIî›Çàl~*«¹B-W,(UB0B¶YÛýÐÃSo@Ö‚	ð²ÐîÀ„8¥ž›xâ„öy4þnèob<EqÑdñ~ `ê 7€BãÁgÑ…³i„ÞÉhä¾àÒ;žñ¸RçáßøMáÝF´iÄ 
.ÐÆùá¥MpŽÕyäÛqúÁ]è"þáì´ÎÃ3Q¡f<``ð°IžÚfv;;ÇGû»Û?«mïïå Íu`»®)Âp#Žš1Œû;S+îë!Yh.Kþ ÑDfÌD€‰6&£ 

€É¾’íYT=_"Ä×shrð/¡i’9Nbûâ†œB‡E›\*7¾“-FE0±½ @‰B<I´›ë¥@ÓU^ÜÞZ€‡ÖÕÔx™f‡¢%»þH²_'±¢7QÄ¢Ç‰ðP*Ô"­#Áb”«[ð¦Ín™g–Oªu†Æ mœ†0C‡KŸ·¸5<ÉM›~˜8É?šíùäGš::úJç+¨cÜù±ÞÿQ®âùv 3ùÿZžoÿÖ¯Ï½57·«jd¿A>õ¹¦Í½Eøû%üáïÿ`2õ££CþKüðw3’%¦ÿH9¼ÂÈuAêDLsë Õ?1~†Ÿ[¿÷?þî¥ú9{ŸÈ‘Ó•Ô1zþ+ŠR­Eæ©V.Îæÿu<Wµÿ¿2Àª¦x³ rH¥»<¬œõ‰Z¬Rÿ³aa žôøæÛÛÂ!®Ià»@¼NB51Xàc(V„f¨hQÎcÀ««V"¼j4«C)¼p!Œ_èóuñÊpêœYžú”ÀÃúáúCŒ^3õ†ûWû5”õ…ÇƒwÖŸæÉç‘«õ¾ ~NMïD.²ß¨É—†šëBDµ0¹+Ýš:IMf3ñw!ƒÍÞ¬ÊoFóvó
ºÃ¡O`˜Ón†MŽ´H¾âÁ‚y	Ä{ýd ÉþF4H¦HîŸO¾=VÌ»±¿wwR„°‘¸7Y—MÂæöa0¼jáœk	Üè-“"€­O©ÏÓ Ü‘6 CùÑm-ÚÃ÷gèÙ-øYrøl'zˆç
qLZîDvÙ©™´Œ?={¶¾@¿f)‹†5ÃZ¸È/Zûm¡ÚÉ×þ¤©ÓjþBdRGÌó4!ºf*	,>oFcl2ƒdÔ¹2iÝ¶Œ4.ÈÆú˜¯/h:göÏ‰ÛQÝAd55‚%Åðùmt6ÊžÌÙÿ$ó—šŒ›_#wëÛ;[›óù|6©÷ë{÷¶6ó™K˜#YoCo‘Ç‹x¹¼IýD2bmòx‰dûŽiy…OU§£_Z×ç¸ûô¤oèV¸¬þ’mÅfÔ77Y#Î_¸HzÙ´V¼'Ê²ÂËÀ¯–B© ÏZ$Ü}=«¥Êk?#Ù# ÔxTHÒZ¶Ò,Ê™E7'ƒ!À(eIˆü>˜ÈÏÃŒðt!Ssh.Vk˜µãçxzøÖL|=!S”•	ù;Có™º£"ÃsÓ-´@FºìR3b.äèñ\*åBÏ©b®xá­Ý”Ñ*aLw¡¿i6ë;Ò:ñ$RF)úf³ž¬µÞíÂWè—¾¹G2šµ´Ø¥.zN†¿÷=®©4x¬†p\lE‚{j6KWÁÛþ5N<Aè/‹è7Ô[èÌü¢ÿuitwü	c,¹JÛ6MÛðŽÙÁ1êƒƒw}öŠ.I~"d÷Àü¤nn}¡ëâÝ0¹ÛP¿fwmg]xva}acäììÔ¶Ö7fõ½+2È”œ«¼‰'XÖ‚ntÖ„®çI.KJjÛåÙy·©W&zxZ¤XðóØ.ë(»…0¤ì Ï^‚þ{*0ßG€T
£§WžùÍ†Å‹§²Bq ’‹h3„â^FèR+€x²¾ ù³¾¢9H+ô^mcà%´¡§:g~³QÂá;´¸ì cCDC²È7Wš¶dŸ˜öúÂ‰»¡ÞS›À^µÚköðG<ÿý§YÇ„ç?%¥T*–«eRP*•Òìüçzž×üüÇâç?ÿäW·.ÕÏÙ“ø$»ùL·Ž1ó¿X«Åæ?|›Íÿëxfç?¯öüGr®ûZ‰QWFœE‚ÄPi³ã —oÂ›~4ÑñÂ«SŸr‹EñAz£¡w¦ŽˆËi1°}XJ†zYŸÿ‡ž¹W·ÆŒ“ÿËÅõÿ(ª
®¥X›Ù]Ïs‹2XárfMvÛn:×.|Qä/è+0C1±$$6‚Ô2O­SmªŸZá©‡‚ÖWÅ+¦=UuôFØe²¿ÿl6¶¶oÚØMßºè\"éðÒï5¥´²º¦TKÕµ2<k+«ðà~³tÉŽõÓ­cœü_©þjÿY©Íæÿµ<3ÿ¯Wâÿdñ¦JþC<À’õ™ØÈLWR¿9==eÑûõ¼YÇ¶öïNè«æóÃ¼>ûªë(Læÿb¹VPêÿ_©Íüÿ¯ã	#t\]Ž?‹ÿYCýo© fãO$JÛ•Ôqñù_ª)ÅÙø_Ç#D!;Îm6Ž ýŒFÄÅŸqú¥ÎÿšR¦ñ?
³óŸëy&9ÿ½;ÇÎŸb?ÇÇÑ3ÝàÎŸú¥fÏëùóÿŠfÿ¸ù_,
åèü/WgúŸëzRwºó¾Þ˜cŸ7ßIÎzƒÿÅž·øçæ¨m°oÎhžºýf×¾Â“…Ù3{fÏì™=³gö\âI±ß}µÍ˜=³gö¼†òÂ??æŸÈ>Süý[üó[B™›ü“ðÏùç²ÏÏ÷ÿüÿ¼Á?oòOÂ??æŸÈ>9ÓJñÍGŠ×œâ;”WP¤ÿüøB]ž=³çõàÞý;sÚœ3gÌ©‘ýûÙìwM×+þ4õÖ¯}ëÛßùõ7n|÷Æ»7¾htìÓõÁ¼£:Ÿã¯Õë4ù÷#ÛîßÕæCÓ8=¾ùç7lo¿3ZØÔÈòø‘iéöé{`éîçÂ‹·ß~ûÆÛÇ7ðüy©´ºLÊ•Êù2y^«à{©z~þöß~_YßþEïìÙóç¿ü#ÖŸ7Ì}/ÒÉ¿íd·­4ðZ1öú;ÿCì½{²ÁðÖ?ð‘ðßùHx;ýÝwÞ}ç“OvßÙ?¾ù›'Ð¿}zS¦Ëoý;¾ù=¼1r[³­ÇÀ÷4»;èYîñÍïkjïõŒz·Û0Ÿ.æÖ»Û=°]Á|ö)qã»Ø«O†®xØñÍ›×84º4z#Zt¸ŸšP%¼™zûã·8¿˜-Ö>¬ßýÕ÷n~ÿ7ÿÜŸçŸz-¯½tœšº×ùLu5ÃÂ€¡¹G³k¡wá÷ßúÁÛoÿêáw¾÷Þï¾÷{þ«h‘7oÝøtÐ4¿˜Þ­ƒüè½w£#Ï®­ÓË5oþoÓ7ïÿè½÷>Ç74N„~ãÆ¯~óæ÷¿÷Îí÷–ß¾©Þ8r¡Õ,%ÿŽòöM÷í£'@4å½ò;Õ7õ·tÕ¦ÑeI«ï|pãæ'o?âF,ñ£w>¾ñýÔòÛŸò[4]Zó÷Þû9ÖŒÆ-û}Ã‚VýPý÷þÂïüà´ê3|WÇ 7n¼¸Ýúx‘}¡øxûÖÇ¾^òÆÜ_œ+ÎmÎíÌýèåùÜ_ûs<÷'sÿÑÜ<÷÷çþë¹?ûÇsÿÓÜ?™û§sÿçÜÿ5÷§ÞJ¥S7S¿“z/õS¿—ZHRë©Ÿ¤>NÕS?M=L=J}šRSÍ”ž2R_¦Ü”—:I¦^¤þùÔ¿úS%õ×R#õG©-õ¯§þ­Ô¿—ú÷Sÿaêo§þÓÔ–ú‡©ÿ&õRšúïSÿsêIý¯©ÿ-õ¤þ¿·¾õÖ·Y#ßògÂ<ÞúJçÓý­e¥ß»oûO^_Jÿoƒ‘÷?ó[¿MÞ_¢P@dà%ÚÉ‘Ò#0Jx>aÑÑÇ‰ðÞïþÅw~ø ÞO‡Íœ›¿ŽÄwãWïaý0óÃù@f7ÙÏw~øÝ·a.°w?\¾qãæ[l.ÿÃwnþÌ :ÝÞ+•ßùáÍo±ß ?WVßyçæ·`6°·ëÁÛï Ýs¨ïl½SõæÜ%	÷¿šû‡sDûÿ€xöÔwS.õƒÔ€X³©k=µ™ÚJÝMí§R‡©FêAêç©cJ¶ORÝT/e§ž¦žÑž§~™úË@´ÿRê_NýÕÔ¿
¤û7)éþÛ©'õ·RÿnêS’ú;©¿›úO€„ÿ^ê?Oý ã_EvG&ØÔ?ŽlÏÞÜÔž67÷þÖÿþw·Üø{}äû~GdýTZ”ÞŸ4«k[í9&ä²wöœ5—›Óåeã×oDßm»ýÿþ•¹¹ø{}äû„¶ý´Ë›ÓäšË_…o„:ÿöoü³¿õ—Ä7ú7r=ÿùÖ\wNŸ3çZrMßzO|—Ð?á]¬oÁ»„~}ÞÙsmÚwa>ŽáoÝž3¡-CsÆZ6$gB;gÏì™=³göÌž¯Ûókìƒ þkøùÿì™=³çkü¤¾µÙØ¼3ÆÔµøû…_`nôAÀ[Ì`h‘§&]¯ÍaÀlÿ?ÛÿÓç›»ÿŸ›=ßØG¾ýjê˜Ðÿ£\*Tj…B	ý?*•ÊÌÿã:žØ5öWPÇÅýð*ØÙø_Ç#Øÿ‹0NµŽ1þ?JA©±øoåJµRÄñ¯”Ëå™ýÿu<·ä‹7Ñëù¿¼SåÝ³«5°4v¤Ù"Ÿc¢_2‚q4òÅ˜ÝJ¿Ó-A=pÙ…½AÇ…@óÞ O î¶£öÜtú ~t}ÿ]›ÇpFù\êŸ'ÐhOþM!^½Ð1´'áÍ™ºk«:¦÷”²vg„[2dd2Aë	ñ{™X(¥œŸWÌEH.)¼1º®A3°Øø[‡‡û‡Í¿6•¶)±$ ‹áË¿9ÇâÑáØ„Á­'¸!ƒp\{àhìšOéé±…¿Y±ofäÿ“Ðö0LÈ´…€‹¯ÿ°
Tgëÿu<¢ü‡êW(ÿÑûÿª…*ÊÅJy6þ×ñÄÆ¿ ³oÇþM=°.\®Ž1ò:ûËã_„×3ÿïky¦3çÝ ê×»ÓÆóîËÄýz÷%]A»¥Ð_‰³ëÝË…ÿzwlü¯w' öî„ÀÞ† k°ð»Ï=b8ÐÊn×°@u„ð‘ÏÞÄ{7Íë
Ð.óÂß…•\¡„Ñ¼V†Dóšz(@¾ñ£hŠ[ ÄÇ¢n:ìž¡ÂR¾P8ÆhXÇTÜøUó{Ø‚Ê/Ñ¶¥a'$t` ‘«ðNÌöZÆ/‹PKÖãÖ‚ûY‚ø©a¾ûû£½ú®œ/¼{)„·x$G–¦ð õ\ÊsÜhìÄó`j$»…&š]EäÜÜ>Ü­ïEke©a.Ü‡mÆr±Ôs:Œòe¸QÃ¿¬kà¾ùñ»°wÌf5àü«?*hƒïovãñ3~vÇ¶=Ü¢ã:aë¢o¥ûs2âXø9/¿âïººÚ? wø0¤‹é®ð‚bÚIïÝÚ°-‹F‚s1<ûùðæD`€´€ŽA·,Ï9óÓÚ†e8@¿£Ûj˜mËÐ7-à5$jž‰Ý›t4°0á—'½¬Ý¿·[­.¬<èØàÏeÙÙ¾c÷úBÂc÷±:ÃE<úStjñåÞ}É­{\þ+û+Žÿñ ’ÃÐP—1ÆÈµr©•ÿjµ™þïZž™üw½òßÙõf‹€?¸ªá=ëšZÇ Ø1¼‚Á!­ü£›Æ0)ä’Íí»äÔthüW­CtHã"e²ÜQ-ÓAË°rïFo¸c˜ð§«N‹<Q-‹B£5¨€ÝS­È§Äì!•˜ÀŽÉ©áèÐ+I‹¥\A¹~™tš q«on¢ª™.Ú˜rÇpµLºæ $AR·º0-bà„…mBH*ÎWÃÉ>ˆEŒ:ŸcdÛ„QEYƒ¥f¼ÃÎ,´#XV]>°â¡ÁôáÐçÔ0=÷¤2¦E–k¨@…Ùm´î!0T¤gmlí;6v@ŸØ°(º-5U|ë05kÝG÷2|?Ä	·¹çâwNùÝ´ÝüD§.0½5Õoßi M!IIïúI‰žÝ¤ènVkµ©H˜Õ­,NÅHÛi«–ùŒ†mV»~]A~\#ÏûõŠR<?:xxúãÆÉÀÔµ_=pk«nëH1t­žÞÓ?Ûo++ý'ùÎ“Ó“ŸÝmŸéõOïïou¶>9ÜQÿ »u¢>ìœ{Ïž~’?0­J¹ú°aõïÝÉÿlK5æÎÃwÓšµ&Ð¤+ýâQ»@	°zKd6‚Yš­<ÖDòÍ¢L»FPàÂ0PG:¡™€÷²]Û~âu{Ðîdá·é­‘Èa´*“ß´ÍÃÚ£pA\%ÅÈµ\:´tir]‚”®pêc‹gs?yîGKYÞ³A›æ¿ÖñÌ6 Š‚èÿ,ÿ«á¤ÞP¶ñÉ§_nç•ý{»ýÝòèÓûÆéà“§F³]ûégŸ}æ=«ýÌª}yÖÚÜêõ¶ïw?}ôÓúÃ?°ÜÓ/üSÅ2Ú[;+§÷ž<­ž­ÞÙËÿ¬_Ïïæ÷«½¯?Ù[ùªxX`lcÒ³+ÿÉ8ä|CæüXv!0…À(+ÂæS8‘
bcr6ªY¡ô‘N˜É9šªöÄ€>6éEï£ó8J6Ã õa<³ªÖÒœò]€ñÕ À$çÑUOÍºg–6äµ‰w‹£Ê U"°!HÎöeï)lÇaß6üýp”áÛøBY>ËÌFd`ògr†º$ŸETŸÏ
Ä¶1D˜ QÙ=9ÓtÐQS‡5†çq;O·O“	1yQŒôÑÆ:‹³§F¸€Ô/¿Â½z•ÊõÄõ?‰:åKÕ1FÿSQ*Âù/|/åZu¦ÿ¹Ž‡ßÿƒV[W  Î”A‘vËÊ Ä©öf«‚°¼Iayzæñ£@® BSÀgfËdRóƒ^ÛÀmBŽÜs0ê¿7ˆÉÍ@œ&ªe¨@ß²» /£xÏµDê 7¢Î_„Ûn¡Dp k*4k€‹*×&}ãN)oÑm;½¸ôÅC”´(r]»R2iâ|ó\®Û†è‰í8Æ´J%@+&êê:tgGG³A’ž:pŸ°.¨°Ë‘G&Ý6Ñ­–ŽÛÃeÔò¹”80ÎK÷UH!!Õ@:ÈPÝ4ÆB€ˆßS,å-à&z„Ö|lÀ6òi¿k>3ñÀÛ'ñÜôÅ¿ü”þááÖz&o÷½¼í€dhdbYðpo=2OØ"èÍÃ#C¥˜+æ”\)WË
Çƒ¨øÐõäwìÔm=
lùÈùï ‰ÍóO+Ýc<×=ÚéŸ8F/e‡Ôs%ÒŒãþ©žóžzŒàôp¯{”_¬ã]‘¼ÆÎ:ÞI>Ü:XÇ«"CÖnMaùÒë½-™oˆ/CTïúVÒý»Gê‡[Ñásí–wª:Fþ$¤|¬Ô1ì¡ëPÔÿ}žÿR=QòÝÝ}$ekõNr=Ü”ry'zÞïzpÕè¶Õ²Å@ N¯g`£^º«Z*¬è™ æâ»fžÈŽ†×ùi{`!þ2wküdë³ÆÑþáÖIïË'nÄAüãár}¡õ{ÛŸà|XÏøßÂî"Ôüôé¾ízaåh"¡¬SK	%#¥YjQN-±ÔRFÜžu_ž&¿[©7ò‰ïÿŠÇÁŒS2³ÿ+W«Jìü¿Z™íÿ®ã™mù®wË7dv½Ù›>¾kýý¿ÇŽqê¾w”½ÅíßÕƒ]À't9qQ+h&Zp¨]ÕÐ½ð Ÿ^"›ŒFÔ­’Déi emšîòkj?=¸íâc@ÿX$Níº¼+P4Ç7<]º‡„½$7C+jw »›gFsS´ðƒtmÇóúîZ>ß6½Î ‰cšgãì¢ôŽvn×±û¬}ƒld‘š¨d¿¼·K””2áˆßhó‚XCÍèË½›ÞØß»»}o(<¤¤LM¸*y<nÁëÓäexÞ à×ÓˆwŠÆ¹>}È¹üÔ0_8òb¾0•ò²¼u]çÒ4Tý Xž†d¨o¢©.UÎ¢©,;šÄà¶Ÿ`l‹ç”ÉF¾øf¼/7oÅæó$]Ú‚ŒŒ™Ð¤ýqÝXóÅ:5	¾dWc¦»Àúš°Òù?=Æ¯Þí†&È° 8ßæ::ò¯÷™Ô„òÿ¥,€GËÿJ±R‹Úÿ*Å™ýïõ<3ùÿ5ÿß|`¶‘-nc…‚Ôú—<åþÛÙ8}¬_…ôÍm—|«f/âõ˜ÄñnZÕaBÃdqÌæÀ3Žà‰Òï5²H4˜ŽéÁòo™šÚE“Ž¬mê¸JRo!)Ç¾ÞÜjl…MûÂÅ0*·/3¨ûLy•x~)b;ð…šfQÏöŽêŸÔaWsJ®J¹
_•JN)Â\fÛÞ»·³•}Xßy°…¿?Íînßq‘,l°Öw![O=ÃB„/æ‘9ô²D–FtçÑ~‹º%v^xŸÐõäÏFiüM³–Gû¯áuvµX¾Î¾6Œ¾Ê¦ôˆ‡™z}4»oN·™¢et÷½æä:}=ìûo‰E_£Ž8=Hbv÷Ì˜´¿JåzúKoëÑ<Ö¥ÄÞJ9&žÑ+Å_à´¶lïõšÍ0O§_äUC8¦wßõD<ÏC
Ù§ç¸Ùz¿ßÅ#(“aÀ†	ðšq4¡…Ã915š#±ÿÉYã}÷l˜í¨'S…Þ£©¡©ÃK(B‹šiµ—€#¸R¶¦9Ý×G ˜€À¡ÚÝñHòÆ±³Æë@xËfŒËóÓ”ËÍ—«Evè¡ÚŒÅ@1H€Qö`äÑÃö³p.)ƒããíõa–û‚9ûˆõ!žM@ÀËü
º+¬¶æ]ÉTþ5ëö†î>pºÉ‹}%vïp;…ã»±ÙÈîØmÓê«íW4’“‹À‚ÛJÀÒÏ˜xTŒ8I’„–Q´@³Ù­x.áíÏqóØ
i†Vd4 ¿i>Ø8zpXß!»Gd1IÊ&ó‰‹ùÙ­–(»†¢ò[ø&"ã :_z†áRàq<
/'À¡À6&D$EØÙáK;ä-x¿«žíQ]åèuóŠ±ä¯:#n[Tì3HCËx/ÃSÛ±}»5 
·`î´Yì3kA£>•ê; Áa»,Š,9ŽBñm€?[*Báj—œš^'N‚†ß6—aS,>tÇWŠ!è‘ØíU 	ÿ@;Á+Žš…¶•7|ÐÙi‡ˆ"JJû-¶ÖaGÜp*†„äwŽQÜ®ÁûßäÚ¿`Nm›²+‘:æ‰üçÔ¢%\Ã¨w]û2x™º&ÿµ0ŠŠëÿKÇL!vŒîVÇ<ÞÉ¥€ÆÆƒ—ý¿R¬Íôÿ×ñÌôÿ×­ÿOž]oºú_0 ÂPÅ¬_¤«êÜ$4ÚÅº’ÕÿŠk@ß“Ž455âAO¼ïGQû÷L¿¢î–ì0!GêÈø]4Öhì”A¨âÔ4°mæix3Þ†™‰ÎõšèìsâFÁÐÛ•«5×™ÔÔe|¼:–¯RÜ¨3AÕÝ" %À	›Úã@ˆ ˆŽ§uºqÇ&QS¿å¡-õdßÞ¤'K4@B­Îlù6#Iæ.d—ì2@à}¾F“‘Iå¿Ë€Œ‘ÿâñŸ‹JYQfòßu<±ñWJÇŽlÊU]?Fë«Ò%v ãü¿KÅjtüKÕYüçky˜?áÇÏ£[(•W×'Cîà²Í±§‚püÔ'ò9MIédBFÌt…‘`{1u°Þ\¼ÄÞbê–v£á[‹±;‹	6î+†l+XhifYÄv‡ØÓ'Ls†þß_ª‰/µgëFd—qq‰~êc&Êóé	" N¹Ó•å'åÓÜýaÙài—vpÅúùM;®@þÃ$ä‹
Èš³OhÍ.dSbÆì4UUJÌS
[5Â(~b›x1ãáÖA¦ÙF[ÎO´KHó\F|ÐpŸFr¦ÆPóYžÍ¾• ør ¯ãqš“+>8f??üø–ã
4ëP&Áf\‰h6V¬}t1tq$èbh¡3B‹q 0TµÛNa6)IeŠ£ËiG;D>Áý ¶B™yæUÍZD“GXÑò¢-}<¶O&ãwæ³Q´€3šáW ŠÌEHA¨Æ'‡»$K¢	?M=?û&È;¦ÅÙ‹8ØÒ‹HÁbÊ¨X,81j/€X¼K²PQ?B¾	žv‹§ºå}VÞg¢øïWÿ«\)G÷ÿ…òlÿw=Ïìüç•ÇÿºþÈ· 9aPãúx	•ÿ²Þ	à®Ô¿{v~ÄÚ0;?ºÞó#tÒï`€Óçéýúzq_›ö”=˜aÜñ.«!þÊqåž¹k_òy-L¼F>1ùŸ/’0ÊÝ\ÿluŒ³ÿ*•K(ÿ+ô¯P$¥V(ÎÎÿ®å™ÖbÐ·­HÜ0û4×6©O'ÜÚ}•Ç'Q™<BñÓ=-‘JG¥pÃj9¥˜+”#²÷s-¸‚±±K6ížjZc9h‡w é–mcss‡(¹ù1¹w°C þiâv—@ÓÐy[\Ã  ñ‡wt˜4J5|=›Ê=¡=>üÏ0Ü<”r´¿¹Ÿ{7¥–2+b»¨|b¦¾’\zâÇïLëÍÇtq£Ï:”Êñ¼¹¶á-.lîïÖ·÷hàÒ…e’yÞí³r™%@—œÑ p‰E ùAAÉ³bnþ}7CÞ'B+–ÒT÷vL;àC4-o1
•®µÇ¸ì"ÐZ¡ d–üÂ®ÛõË*¢„P¾–§âå°î°²[‡XðÔhví¶©e‚†£	¸_6Ã[Yo4ínfÒétßÁ-0ú¦³•‹dŸ¿ï~±AÆ‘ì>šcÙq ÂìuzáÀA€Ã0{ˆÝhn¬X‰hnŽÎ°Àƒ?‰àan_Ò–1¹T9x´Óðç?K¡,¥,²þîØ\Ç ZÀÃršÄœBœ°b!>F•BJ	RÂË¨‚ˆ©=ar…øW*ÄÚzO[Oë –Ž^õûZ?qûŸb¢Añºí
3ùï:ž©Øÿ'™™ýÏµÙÿŒ„™ýÏÌþ';³ÿy£ìŠ‰yŠßdûŸâëhÿCÙ,oßÌþçJíŠ¯“ý?Ø3ûŸ™ýÏûÄ÷…cÆ6EqòJï¨jñûJ3ûŸkyfû³ëÚŸ™W_‹Í™‰®Õx-²E]µýÅÖ¿¶Ïß±±NÏ6e‘¼›2çÒ›²ÙfìÍÝŒ%
à‹AÎ%.xsÌÐY€KíÈ|ˆÁžL²‘¶e¡‰È…6f¼áÖ,¹†â˜¢û³!´pœ.²E]JÚ¤‰~ë’hþœÉæç¯x£¦DÄ¼û’û³,€tÚè'ZtgÝZ…èx=vWC;3´Ý³-Öì¹êg"ÿ4ô»Dãü?j•XüHžíÿ®ã™ù¼rÿœ]o¶s–`÷©×~H×ü…® wk€ØÆ(]1Ï‹À¦8b¨÷‘nç–ª‚ßìböxËvmÝð/Ïá­ 	7…PoÑÉƒ]¯bÄIÁÉÃJðòÒ…Žd	UªÂRŸx—1*Ë ³_BIÓ“ý”d­xèZ¶Ýµ›j7«‰È@y Ÿ dLï9ow¬o¥	e…Ù¦ÑQOLÛYS5Íè{¯âB”•Wâ«2M€(sÕ77‰=Ðù¥Ô·€Ö\ÈÇÄ«éÑ
ÃÕáô¯	ŸÊR¿©€ú€0ƒ¦ç Õ®áQ‡!¤Gô~‚×xÉÍ2éJÅ8	ïÀxièæ°Eê;.ÌçMpßÍÔ{ÔˆTT„·<8v7LDïN@(Ûê„“¬ª™k™EX‡Û†Ç¬?Î(¹bn¥\È)J©RaÑÀW
•ÇêU°ÈI€”r…ˆªÁ–!³‰ÑÁ¨å÷^¨ÀñŽ˜;BÌ1¼^a­|œù ·-öé"ðfÂGÎ¬[Ð
ôêXËçó0Y}`ËðÛÜsñ;›q d)s…$„-šÑÐ+ ¡ ñS!¢ Úx*º?”	ïÿ»Ô`Œü_SâñßŠÕYüßkyfòÿkpÿß›¿oø¹81Õ™œ?“ó_¹œ¿«š]rÆE.h0M­‘Åt&~ŒDt€Üž×ÏâåU†³Öµ5µ‹¤Àj¨[}Fg(™íS”ÓãÑ:¿F‡<4³e>3é…™©óbŠméÛ ž•7é•™Ö‰Ú5õlpùOÖ=³<õir=RŸ7™¯1áløB[Á*ïsµv–5Mª—'1¯äCÉˆ¤‚€0²@¶Àô ¼»XâÞö¨Kq0*Dø9€cXõ"Ò¥¶…©¬y‡ZÐº{þû (¥@µŽê¨šb,ÔµF/Q»kÙã÷o‹ý	²3×¸5µÛï¨kåekÐšÑÖJË~ÉârüOaÞ3þÿö®~¹mÜˆÿÏ™¾êdê6•¨oé¢)3§ÈJªV±=–íôšd4	KŒ)QGRvœ6oÓ7é‹u I¢,Û¡¥sCä&‹,‹åâ‡%Mö×Íì^!:ç›…À/ó;qœ(9>©CÃï ‚‰Ê6·PÈ	vO{@çZ|àÃÂÉy@‘Z>ÃöR> $‘ŠîÑ ¦[dW<ÑöÞ#L2ük§X‰5æï¥³ô‹¦˜í²—–}Öï"»§²][•ClYQq<ÐÈäP¦ÁŠ^kBÛ­˜¿åÛë¤_–˜¨ÞIÝÙn&Ê$j.ºô×%¬?°‘Zº Ö£žáMºÿ<Z/RüšVïÁ^[•KÔ$êñ……?XzÔš%WîÞfÃâžnöËÆÑúsÓúJ¿„2ÂVÐ¢9†öšôKÐNØn£Ïe$	ÍÎ×( .²KÛ ù0ÚþÍšlm-›5ÙÞr«*Þ9àGà¥]Lå[F„#ô¬1·\cÅ_w ]AØ[‘ƒ×X¼nÐCñ—¥Þ­¯ËÙ½g‡`èŠ%ŒˆDcnÛ~U_«èúï?Ðñ{il~0|‹<Ýž"ÿíL\ÇÇ¢‰vÖ±Áÿ†?óÿ”+Õz«\©r¥ÑÊñ?¶“2ÝX=Zð^†‰õd~‚ ±#‡8î¨éE1¦I_ŽµMB“dÝß‰`ÞJE­”Ñ¹Ð\ã\È¼	¥e¹\Ò‹à5[æQ½²£ÔxÇÌr¡ÂÏ„`¼$ßÇ˜1Â1¼4s<öcfyè.p.Ù/>€ZƒýðÀÑåò¥ò-_ÇÐ$ÿuõÒÏÒ&ü¯úÊú_oæß¶“òõ?_ÿï¸þwAA|vÆäM¾Þ'š5¿kJ/mô¨Ù6áöq.X`½»œ£s"ørèe^9hâ—äüÁC1ÜÜ éæÇX`ÃƒÆ›’¢OÞœ¤8C9ÿ¨Í±®Sòê)ù³…Lî,}R}õ‡ŠòÝgêôž57\æGÑw×‰åBµP+ÔBóAÝÙ?ìžôÞõO;¿•^åVé{²Ze=ùâ®ý'Ìfì¿ûtØ®×á]¥Èþ£¾Qº¶½Ã.T=Ô™I›ì¿&ÿ©·ZhþÕÿµÒ¬åöß6Rf#î‰ »CëkG;¦(Yg` ¬È?ÒIÖššf³âæÑ}’°Ød‹,Œj©ÐŸÀ"d’4†Ì*[aAÎØ4’ãÁ`Í –œyÐÓñÚ¼hãÌðíà&{ÓÄ‹JÖ[P.Or:…¡…ÿth¨	º¨Â$‚!o×ØÐZD„s‹Bb†,z"ˆŒ!dH–RIÇü³“})‰ëÀ
Bçb†\ºê˜^ ¤,;aL,_UžÅ¨Y˜¬[þ”
,þv,ß[š1«r ‹Žç–lk\¯)þ_JT Ò2þ¼dJéƒ»DWyŒßÞ¤ºáƒtùw¯ÅÅ7UÃ/1–¸’™>_êö­ÌÙ½Åw`í,îÏÙI	Æ8C-p’À%¡g†e¼Ä}DKl# ‰CªÄ¥6å8¤‚±Å	2ÄÖŸã\"SçJƒƒ0fØnå*€OÊåRí×–)‚¾°Æ”÷úÜ÷´9õ¯÷Rå¡ÑJçÂ§nò!Q>½üI9½YPÍ³`‚S?ÂcØ»ògû×{(“+œ½ZÒÃé:Z¸$y!†1¶L "+½/Ô`²vÿ²üšì÷t<@X„ÏàÌœÅx7ËìN­£pH­V.+ÐÌ¹©»æÑÒ_,}„Óv&6œ¹ç@÷¹=×uÜd&ô©P7ŸØHàþ\›-mßb_óE×ïzýÛ0Àt~52@‡~ï¡O)m:ÿYk2üŸz¥Ñ*×Ê°ÿš­znÿm%=û=›—9Tëö €’³ìÉzÑ(b£b÷%=Ìpd9bµoè>/ºüìš¥ºl[ÜpU¼æKí£zSüˆ/U0¶æGdq9yj€RrfÖ×Ãñ0n¯aB\“g	ÆÖaqÃÎŒF÷ /£‚|*A°hÃXÅÀ¸ySgi3»Œl2§xäIs‰ôý},"ÄFé›hð`ehíuÅìrÆŽÏtÓÐ‰
£NÔ±îMq½F9Qy§Sq–À‰<rmÁ_e«_é–Í*”jÆ :Î›äëÂ ;ƒQ÷lxzô®ÿÏÎiÿèö
œêØñ<Kæá±½L¬OáÑI§;è€$Øðk$°±õÁvF›”B0]<ì¥„ÅÂyžÈã<á½oe(5(dvÐ9í¬0CFÑÎ	ßÎÔ}½:ò
ñOü^È-=am”š"W­m_Ð˜RÌ[(^¸û÷³ãà½%®Âo»™''”G…!I­ôà&†ñN,Í,Ó´éµîR™õ›wïöbe¿¿uÎ;rCcü>ƒ0ÃbÆ«½MÈ†œº;zE	ØkëðÀÓî-üÐ
ýnl¡ ß˜‘‡éM
;ÖP( ×ÇLá{Åu‹ÌqÕÉ\›þ%u’¿úa½kRÜþ
Uu½E†ul°ÿË•ZC|ÿoT«`;cü_­™ÛÿÛHz‡oû‡½OÊ	õ é)ÿ¼{Îm­¢–ùåÃÛÞaï¤ßý¤{Ý³“þé/£³cÐ½½áè¼ß½û…+·áÙ1ž~Ó.tÛËæëAž3¥íÿ3Üú³´éüw£ÚâûÿjµYnUÙü¯çñ¿[IµÿÏCRšâxÚ€n,˜­`
#V·-Ýcß,R¯ÕÃm‡’8TÍ6Ng¡ÛKõ$ˆ] üÝ¸öú×M¶‹‘+‚‘œâçýÓóv"l~µ“p¤íº4á!lÀ¥Ð,röúCÞiÈüò8ïœhì|Sæ¡%ÇÃŠ¶ÿqùóÇiûãu‰|H "û¥aN5È6Uß¢]K tr°Íˆ`,p#=¶ÅãÁQ·3øv—š¬q²ªKËHDˆ¡|“%ÑNSi%{=3ØÛy¥3Žšœh‘žÌâW}`	@~°CË{xlDÃÇ¬û‡ë›5Ž8#^¸|×á#ñön¯,yú'áð†®…oÂKà•"%3èýƒ7¬aÀ	WÀ\è²m-u‰· _­Ëˆæ\ÀŸïDGÐñâ¥¢¾'m•æC¦ib2Å'-WÅ_n¾jûìŸE¦¢aÍ˜ï?‚
7TêsQ/ÓÌº1en§Àû£àS=QgŽýáé7…ÓQ¸K‹?·´=•H³5ñ%ÜˆÏ­=ÅtæTá…PìfIœkýhIS;ÊµYîž¬ö¤\Z°JíŠQátZ¥‚§1*œ]«Tð¨B2kšöR‰V[öZ¢pÎHÔÆíÔ|BFô Vb]ÆF$ÊÖÇk»=Ij¥’Æˆ¤®ÕQØk“…¶?¡>»—4|¡‰3åO¹Ou„´ r0ôoJíEðºjÐ•4ÀNVëf¬Íÿf7‡Dª¶&Q_Àd1Ûq5}é;!A:›q˜ïr¶ï†<þ(›grÐÏ_@c|„*)ÎIµÒDÒ*‘°c|dŸ—¹ÀbòíÂPâ fQqz¿â?KÅ]º¸	1;ââÝ‡`Á€Î€Å•åhûWVLxPaøú8ì*ø¹\p±X†B±L>€Æ\jû3ŸTÄ8pä	Q_Â|âò$	Ÿ›Í¯Z…œð€ä–xËÙnƒÇæ—³™îÞÍ2=˜§¨ÓNúÆô\[‘†¿¬s$¿4hõç””×&ÞÒ¢ú_|ùeb0O·½ÎþÓñ2'ü?®Ž[/XŒŒëØäÿ…§‘ÿ·†ñ¿f+ÿØJ²æW°?„¹6‚1_‰¡bò ´ÜF&>ìºõyúÞ”ÿÅö2™¹7á?´Z,þ¿V©Õªõ&‹ÿ¯Õrüÿ­¤Üÿ»[ÿ¯<×þ?ÝÀü7zƒ“®`täîàïoÂSwßÉ½¸;÷!ÏˆOaŸ€ò†ž’yG|ß¦Û‡¥øO)„vþ_Yÿawœõ³Éþ¯Wkìûo­Ü¬”ÿ»Ro5rû+éS°\3ÍÍ£ I…´cª—­]˜QƒƒÎ1ÁÛëðaMz8ŸÖÅS§>mˆ§Òýva^“´¥sa{Nº@Žúø×Á°×#z`øNyvß¹Dtì˜ŽqIÝv¥öÓËv¥Yk¶ëÚ?½„ŸÀ÷éìÝ³H+ó_ôÞtÎ§£­Ùÿ~ÿWŒ±&,xþ£Ñjäó)?ÿ±“ó‰Yöd-ÿ5'@ÒõüÈ­ÈÖRßŽ®dlzÿvïŒïKÝµž_—VÖÿèV’Ì @6¬ÿµf­áTñüg«Y«æëÿ6RŽÿ!ã¤É¿’C€Dé± @ÂNOý(„üØWØ‡ÇÿHƒÇE I¼Dger‡š¾äNÜ²–w†:áÿDöÝ<ˆd¥jGÇ½Ãƒá(<Ï¨í±Ù‚GKŸÍËŠú“ZUêõÒ^ü£e¶‡az4pêr¨¢‰å¯K'C}l(é,’O`{¨›÷(êR.Ò“ìA~KÐ þ¿i]°þXX#mdRÇ&ÿO™Ûþo«ÜÈí¿­¤ü#m²ÙIWMl><YGMp‰š„ºšæÌx›ÐþMÌéŸôâü(ˆ¾Š	]htŸ?A9,ÀÇ(¦Ñ&áCEºt$Åèó "–+
çhÌ5¶|z…4ÞPðìÕâ‰š»ëÌ}0õ©r>¦,Ôk9óì{qÞµjÊSžò”§<å)OyÊÓ#¤ÿSÔ„È ø 