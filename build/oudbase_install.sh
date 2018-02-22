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
‹ ÆZ í½klcIÖ&ÎÎîv³ãïëİ|Ù×·ã¯†R¤^ñ©×ŒfØ;l‘İ£½,Jİ3ÛİË½$¯È;MŞË½÷RjM·Ö‰ãøñÇyØÛ@'ùşçõ'	ò Y8p€ ±	l  È'çÔãŞªû )‰’ºgxgZ$ë:uªêÔ©S§Nªfvê’Ÿ\.·º¼Lèç
ûÌ–Ø'H~±°´˜[Y^Î/‘\>¿¼R˜"Ë—M>}ÇÕl Å±ôp vx8à=¯‡÷ù†<uè«ß¬AõÜ¾“qÚ—PÆàş/,ç Ïiÿòyè`…å)’»ZBÏ7¼ÿ§ßÍ"Ô5§œ&éñ=€mf£¹FfÆvß6´¦áÒÃr¿ï¦î8¤¬é«×ÕM—¼Gªı^Ï²]2w¿\‡<UMoé¶n8®­9N
,÷óËò°£¹nİî·Z¤zl¸_évG3›c'z[ëêö¬eÀÁËRßm[6YuõCÍ$;zÛîdÎÒyâĞ´ŒEÓ>vydVrWš†ëåÙÔw½­™-½yÿ„5Ysı²e |Á@öô#Ã1,3"^0°İ¾İ³aº<CªÛè¹ÄµHK‡¶Nªf6tÂjH4‡ØºÛ7IÃjêØ–«;‚šı6ô£ÃpÀ·®f˜Òwô&9´l¢›G†m™´S¡sÚVß%ûÊi(^Qº¡[¡4DÖvİ³–Í¶ ²_ÇÖÉ²sPÄ‹ëcïVhò	p•eŸ¬ÁÏ\>“û SÈåW! QÙ0×Ğ:äH·±&_Èäó³*`JÍ/A
a3êğ-“X‡È)PÑÌ%Î4Y‡B­®ñ•æaÁÔ_ĞÁ¶sP®ííìì×ÊÛÅ™—Ò¯µt
ØÆmáĞËXv+uJ	¨˜M¬ãÅéHRte#ıKi¾î\ BÉG•½êÆÎvz3YŞ)íîV¶ËÅÔşŞA%EF|¦wµzG'«Eø¢õz:À}§Z)¦”6«çÀ¼Q‡!Hº8šªë{»ûµíÒV¥83‡n‚œ!3¹ùäşÖn­¼±WYßßÙû¢˜Êºİ^Š&>ØØ„Òg^* §Y5{ff&•¬î—öökŸTJåÊ^1E¡xÒ «¡Ûf^J¥Ÿ’¹GŒÃ!7ßé<³dæn*¹UÚØ,•Ë{•jµ<ı±ek0 3v²²··³WÌ%e¸xO2túf™ê"ÌÀĞwôrºÈ£µô¹yò2([Ë†Óëh'`Ì¥#;y\H™š&•­-§ERÛvÈ+x!ØÉOÒí#›¤òîmà‰íõÊ=’.“@h–·áû—ìû.ŒöcËn> æ¿GEBHºÅì´p2çâäĞ…É~Åd?ŠÊ1Rb²ÛQÙm½ñœN?¶Şë*—bHõöÁ¾GÈ¾k¤aË†­7p’ [š	µ±cĞE6İ}H!=DeILîP·à)0	±)9*ß¦Õ¢â	&ø—›;Q:œ28ã<Äü)I·\’#Ï>ÄùİLŠj®wtÍ,™Í?Ñ7\7ó²pJ_ë˜k\@âEçÏš~h$O“cŸë"‡Öc,&£\£K–nï²†:mõ¹ùäKZÏíİƒ}˜$ówÖîF1!}@×Õë4[ûƒÙ"u>š¬m ¯¡É)ªSP»¢1 3‚‚L4b “ùõ¤ÂwÀäæõI
~Ô<!û[•ğÑÖ.L,MPKHêgw¾Hßé¦ï4kw>Y»³µv§ššÿğC)ëŞ^|VsHf:»@îs”»ó–ª”›JÉ wÙ{ ñˆLº£5ü¢rğiŠ	W‚ƒA€
ua,-£Ñ¶Ş§	Ø QŠ¼ru¤5i<z9•q5CJ|uÚÆ¡ëı:nã¸§Tc±ï½”Ö¦¥qÖšùd‡Ö.²†ƒÑ) RMÃµmZ¦–Mcì¶{÷¢êôšµ~4‘£7ŞeÈgODÊ*E$(º) é÷@‚ôÁøÂp/A96ñE(O¼õ¸HÎ£8öÀsóŞœ‹ÒfÚö,‹«¼À+PM²ZE!aIÜ"Z×ê›T×ìV—ÈN†Tapõé´†â½aÙ¨wè½Œ\DaÔ"b2‡Sûü¨ø—‡â—µª6 ‹¦oZ.íT§3º„Ü/İ?%PüØ+­oV<í¦v¿T44ôĞRi6Z£»±’¨iFµG¥>ùü0ÌëV¿Ó¤\«ßh³ÖKiö3 éXZ“<yùÉ°G6#ˆ”Ñ-­oÕ‚Ù¾Âç‡P1½)ç_š¿bÛĞBHN“jjö¡µaÙiïÚ}ÓDı…Û„V·«™*ºÂ9Ğ5IEÄº8ë–á8T³
kÙ2GÂ[Ævã„*¨FàÓÔ™HüêÓÑy­>@èòÊ|ˆxCBa¶åÛÚÔ†8¬UQŠ êèòHnw4qÄŒÏl {~eŞ¡uQˆ&|í²E–DÿÌV*Ÿ¢‘ìX3M8 ¿·µNÇR†éÏ‡Šó¹i›¬ê1ú^…¡ä4$üUšöô®ujµ
5ó^V_9±»
ÊÂ½lS?ÊšıNÇ™†¥¨¬~SŒk³¯£y&?ËÖp¿ß’±£umœi–ón»$ªVêÂè|RCLÛ/ÉÍv;ÆcYaFn!½¸°1Şô$:&H¡caDá‚Ï>I
•J€1•JU§'"XP‡8"V5•ån!ï­wB’íP°G>	ãÉ%¯^Á›wIºx-¨”šÏAiXÖ&6
sÉÀÌ™¹C”‚ş”˜¦ö@Ï=”¤
½½(ù:“›’\ÇDC#|Â@²1ª†%D<˜J²ùÓWR®dšÙÏaŒşõ2òŞ{ØMÇ$%Ù.”ê¬·I¯GÔvÉËJkæU8©šÉqÿXX–¡ÛÒŒÙŞ%îwm­GRJÅ–r)\ã'“\jA«K6]P¬A´‚Úrs N}ĞöLjæ÷6yR¼]˜Nˆã­¥»VØVÍß³-~8ÑòYºƒ-ÜÓl`íal=Äs“ö‘±V^ûr­²f£ê-‹˜‚)²‚|É,†9i28šèéÒ;clÈŒŒlº³MóP™CËÇì{1_
ÙdkÏ“½ÊîæÆzi7BTUæU®ŒÆòsQÙ™¹+O`tæIµ~(3B2.Ğ¡Í;µdYHfasyCëd¹“)2£¢æR‚Ü#ŞH†Qı^>‰@Ìş?ós(«M•¢ãä
‚mu¹èálúÒƒZ™)m·LBM€0´RBÂDOÈDŒ?³)û{ŒB0@üøÔ’?Ş$q¬Cs!Lû’Ëb°¯kéT¤ú4Á½"›œf^î>.óŠœ²fz—O‘aøA³ĞÒb¸sø,P®ú¦P…@Ê´Ò ƒ'9d:Í¶“Ó‡¶¡?@Ši¥A u{.ı¾k[=İvİAJ!‰µ‘_‘ò6Ï’å:‘ÈŠ kƒfZ¦¾§2UÃ“Ñ<cÄŸÏ—ò
8ço({Lˆi ›µ&üƒIGc;õ¸‰;íiƒÌ:Ù_ÎdÓÙY™!×—LO÷µÆs€%ef,ïö;®ÑÃ½Mt½ğPdw¨n
«Wá¢‚?“}¹ı¡“}jfIöÃÓÜ Ğ¡ñ"ş%‡Z“F>¡RµË¦!e¸±•i¾íSÕí#Xo!ëUå>™kºÔ4Èl„oŠêM¥ìy!B¤¾m[);lS¥X.¨pñn1Ğğ—Šm¾TÔĞ0Æ–ˆI\d¸ÄÛ,—véŸª7•ª-ÃKº™—_É”VÛÁ]‹9íø9™½_y¸±ır¯ZL=5ÓOaíö€~M}¸ñp{g¯²ÓC1ÿ![j—qw(O~C²¿,5›6ôA%ëL“~4‹¥Ì>½—%/¡Rs3‹,¹ÂªéóOîCrŠ/é¢„¦©=Næ)­Ê¸ózudAï,çCÚüğ.
wS¶’PèÕ‰Xšòãl·F1µ7x§qÒ;cëªàiA0hèÀarFŒ´:v"zG¿j}}¦Bl‘y‡ÎTÔ’7³»*|©¼µ±-O>±ó˜ÖìæYxöŠì«Ø9L©R\·FÔÏÑ«Kuâã½ËdhiŸ… âWÒĞÀñ°–ú3î)É*K§‚×WÉ»¿^ßFU‡€àõåB$³ŸÁƒ7Õ—
ëbıÔMsoE:dúº}Q'ÏÕ?Âÿ›¹ğ]‹ÿ÷âR®€şßğmu¹Ë1ÿïüÄÿû*‰ÿ÷5ù{îëâÿÍ€5PEÄöœ¬9_w×ï÷3ğÿ%¹~çƒÓµ­fLX!{fTDäôô†qxâûáC#ŒÛKb¼îã_ogğ±z‚ŸÙüJ}¸¿A.ÜWè¯á-¬pî«põIwÉGRCÒè.Ûñ×İY;Ló&H6d6yGÊ‰Éª—{K3:„Û=¢³O|¤¯ÔGšL|¤'>Òdâ#=ñ‘øHsyõĞ¼²½6ø&ÒCğO|•Ïè«<&?Şëğ*øO~Íü'´²ı¨8Ô[2ŞÑ’•H ´‰å¸vÌN”€ğì’lõ›'—æ
Ù]3Ö*Ôò*|!«1î‹] ”,@3sBÏ°¯ĞtëdŸ.dŸ’lkşÒü(Çâ'ùµw¥ãb/Ğ·¢š©dKñlö¦«Õ#í"Œ#Œ4Tö×¹cØ<ˆ×cÓ¤aë¸šÕT
´ÓèÅ=ó"QÃfW{d¿t¿.(6Gms£Š.Ì¯ëˆÌşrzÖ?röªÑwò<Lkóá¹ˆ7ÃãÒŞ6zç¨šO…6ŞÓˆºÇày ºG]¦t-Ì†”–Kû¥Óì]<6ãçê›Ü+×¯ˆ¿–_qr(®ĞjÄ¶WŞáNŒ‚DmÚ—3èa˜¹û4ûtşÎ?E*2wg²OóÙÙy¿jò"Êkñ°+º²·ÁÚY’¥)Î×}GÄÖ<u6L†é÷\`ÑºMff	ü7ÏÅ>?¾cêÇTœf ƒ"‘ûŞ}4ù”â}jrÄj½ÙŒéê‚‘ÅI-oÌ…°¥ØQ«G,tXTwã0;îCbvï´¥”9ÆOğÉŒÈôÌ— 3>"Ç;ò&-çz çê‡äÑÅpK±¤Wô74(¡_,»•±psÄÉ8ÔË2(=ãI[æzÉ2¥R¹óê2”GXõª—–‡©ß[ Õ·º¬³e|•äU¤v'^«Z_€Ğ÷BC¯éÍ)şœûIº'\‡>§®_å=Õ.¡_cŒĞUg¾¼ìü÷.Â2­@+â…'Ö×F%yg‡YZ@óş1p Ú{–å2iÚ\C‰ºP@&{öÉ“µzG3Ÿ¯={6;’H™?RÔbOeœóª9Èlt@¿oCÏ¶‹è§¤0˜.3›}šZxšÊ†Pdg[>D~Í«V66Œ@ig
<=r7Xs¯Í¼qZóH;e
½Œ:¾{º«'IŸç8º²_ë€]³ÖúÎÖV	u}¾ ÚØ>Í2ŒéNs:İ¶—V‚üÀ_#ù%äHE&zÀÉmpH
GœØ˜Ö¬•µn1ŸıÙş,¬— Ó¨í¹ÒH½F‡J…˜Wep¤áòô‡¡p¶dİÊ|.ÃÖÏ] „7¢Õã‡\½Ê¨ŒÃÍ3lSHç‡²}ÏÆT¨Læ…©6Å«. yAÒµªìì­U<õ,öìq
Ç_‚„e o$Ş’ssôËÏòóª|ˆ4ŸÇwûèíâô¸²;„eö	(0¦á´õfĞüîw¼bm¿ÀŒÕ´ÍP?EõuuXQê6¬Ö›™”g,‘|ÓgâØEeO~èiºIÊ!³>gs1=½”ËÉËÿPçRÒ¹«PÀ®èSÚI¿Eş®²	a<şo¸×«ğÿD&î÷®'şïâò¢çÿ™_\EÿÏÂÒ$şï•<ÿÏkòÿôÜ×Åÿ“Uè›ëÿ¹’ÿ‡ø~É­*0[Ú—¸KHÛÚÁVäº®ØEhXæ!µ%ÃïÌG^dGš>q(Ãöf8”æ2ù76ºğ•º•î±‹5:ØÜ¹B¬R¢Ïî3Ñ´ÒÓ“ŸU*»Å¥³àáÈ¶ûİ:¨Şc]Nës]ï%AÖôĞu°˜J§Å÷èd¡ü,äAGkM<hßdZ—|„¬úõ÷¥õ*ê=Ò#8PÑ[ec{}¯²UÙŞ/mN|rÏÁµ¯•Oî$nñÄ'—–1ñÉøäN|rÓ¯“OîH.¹§Ü‰Sîùœr¹nvÊ8Ó@7q¦8Ó¾QÎ´ãGú:ÒºkÆZw­rn´.,¨™*Òõ*œlÇ>tâ5œxN¼Fß`¯Q¾=7¢×(»ïAdrÑp.¦~slÚ—|ªÂb_àì¬uĞ*.ı”f<HÄ‘VËE†Õ´cö;YÆ9ÖõçÄ¤¦øävåqíq¥òÙöds9HÍ'w6ËşXø€§é™—¸p:?O³ß/­v°[«V€óX¡5(2%¹ƒK	šİ‰€õ°ˆA™}"2«]TÕ;‰VT%Bsx‚_ğépd¸5³bßnñUY¦bV«4ñ&õãT7_[Oät!dìoFgÃ;ùüå«.ª¯2ç$ê”âÚ…y³JRË§=¿]xAQ¾¬µã‰7îb*„Ñ)®aF¨Ã(=;óR¥EÊz5¢»¨ì*J¢ú/×1Àóºe-¿G ˜7P#Ó§º…¤w¿jÒFYÙ—áÌ¸­¯Ø2o}gû¹Wë!U—ˆpçufGåğNZµ§ŠrC+
UËjxÚûAY¥Ÿı&Ú5ÄOZ5—9ÖKäİd‚i=£×ÎQ­Ì=yk<G÷6÷4¾9¨ÏàT<’C1/åÜÅÃ‰C6ÿxÖ‹¬òşÂu»Ôw-¼*©¡A:¥ónšuˆÕi¢¿ôA]ƒNóâ1Â-0ùó¨"¿
	ÈµQÊj¢“„İÈí.IÛÑ#3€qøÎL|5¶-¹
‡Vtı9½•	+HDÏÇnìˆ»”ÆäêÍÉ›¸zŸá¹nWÛ×òAçßLÍ3³^Jƒı¿s¹¥Ü
ú/-./-æ
y’Ë/®,æ&şßWò|ûßzkjjKk*ù\ˆ&L›º	ÿ
ğï·ğ~'¾3ÊÒşşûFsü_ğïûoñôÛSS?=<£õz=ÓÑ€q-?½[å8ŞÆ?SSáºZÃÆPÇ%^‡]†°‡Î³öÛö§Xôa®wô³©¿˜šúƒôĞáŸşóßÃÏü•0Úëù(77]RƒÇ?õÕÅàø_*,MÆÿU<“ó×sşÃóÄ“Ï~0ã=‰‹çtq­”r#xìäÈeœÉ…O4auÙ“ãDĞM!ÄÌã~İâ23…lZçºyB‘¶t·†XJ7²ı)è+×>ss‡xŸ	i¶î5çsˆGlU^gM}ë˜o}Ó¼BĞWÃrÉ‰î]!c®"·3|²C7xÄñúyåôEJ1:ß/U?©UwöÖ+OrÏ`Ñ\İ2[‡·èıF|Œ	¬°nF¤ôÖ˜k6…L…P§ ÷‡¤wÜ$é]ø
ÒªîX¾‹»ìnQ«hü	àÉ/çê0â™&ğJÈ_÷µqhàş6“Hß
ö;ób¢ fu’åÊƒÒÁ&^şSfqèî%oBjqK)0|1/±uµ
¥l…r8iËZ­nÕÊ;°ÄUÊmZ(ÔTÀÚæÎziS†¢ÑbaîJN`°î3(İmÄB¡ÅL”ÙŠ…Ú¯lín–ö+U‹w	Òe~İ½òÁú¾\‹=BæJXÙn2:$qÃîq¾)dò™ÅL.ø`ëñ `f5Ş«PÓñÆÃbŠÉÇİæAa˜J"qE™#ï Gè‰Óø×¢NOe¦”Ê!\Òâw1¬U2¤_kiÉMêt$ğˆªI99®¢–K+V”}µ†4LJ\‹ÒY{'ü·–S–6„•ƒrÂ(Úe	&¦Ì·¿¨Á}jY“†8ÓgĞ«Æ#X˜¸x^â–€'Vf(¸º%µ£wz(‹ı¡ãÀªU“['Ü¢ïAã¾Éİ‘:•Ğw§ÁğŠ4@ IØ|yÆqú	³ç÷¡6m@b©
Çx°¨V‡âÊÎ bEhî<,rUôª eèÕ´Aè#Ä´Úbl·Ñı5ª?|©æRüêc©à¸T¨
ÈI¹ºªdô)-T‘¹RÁŸ–•D‘Ş÷3ö¥v¤±¦EÉáï'S‘¤re}gï‹s¡£nKœˆÀ;(LI äDãÁšûñX4Èq{»î	¹¸»·¿ÿÆ âµg;ôEz>JoP×yÓ;ˆª¿Ğ}JF–‹J/#UáÊ¸oÅ¿Ò«×Ü+™¹Nñ}„€\LşK÷YVhŠòÿs €Ñgënß6I>x·7 pÕË—¥ŞËÈ{ÛE|ÏFÁ#QÕğZ¯òÌÕí.A4±s"¦8\¾êd·´ÿ	ºë¶ãJ¼eáõ¨ÇLM¶ØWÜSÍYë”¤;zÀ—W’Õ¥G•r‘ãÇ©äæ]‹éC…÷9.Bö™@VOpk9ô`uR=¶@!tf‰t‚ğyDŸ‘M¤I$UAáL>¢v#”ïS‡ğô<³†äµc41Q3ëi‚Â'E¸3r“@—Gc—'OÙÉTQLNIHõ8%*&z^±Drä÷¼Í$$ãÔôË½™ø¬Î}[è¨ñ;õ‡.>¡—óJd2Ÿv´ÀÔDk0ÃŒX„P¥TNò¾»Zİ#Q‰öëûøÒ‹œÃã
oªa<¡.×Fé1Z¢Ü ê¾±ïÚÛq,˜\ğø­uè¢Ûësî	+¯¥¡ÆÒ˜cC$ªò¼}ÛÌ5[¦Åã¡ä4-ğ×‘çáã=˜
$£™C²q3¢/½D ÷88ÄŸİş‚şí¼Tê¨ë/‰edØÛÜ@3”Şí¹'>¤BÎÇa=ƒ•à¢ÒhqUEñãVÜÌ½WªÔh!|zöH3OTBTÑ†F1VçûT”Ìã˜.â{_ærèrQ|‰3¸•k8lÀÙÄkgh;¦s0æ—x'Ä)BªI.\‘#/ÃY</z¥(‰µ©=¯‰7ÇÂ1Üqş#Àwgæ¹8~;;¯—ÏÆÍc”¿.íĞ„¬;j«ö$´3ê A‰ÇÓMË£¤-mùÍÍİ
ÿµQ×:ŒÀ³ •¯`ëtYVû}J«‰×!8°l€I……şB“<¤xë¼–ÈGU?‚˜Õ bŞs#äbG]=¤Q³²Œ1OÛçÎT¾®˜¼pè_,àöò2¸ÓKÃÉ5yìÙó9ÆŒ²3fÂ° [öğ$n92â˜T.oìÕøË”õ\	ù0 Ñµ3
4q2÷]_yò
3+@R–-øšXäÒşsúib·	Í&FgávA4–«•Ê(Tr
›Ğ9WIšLÏ@oÀİÎø”µ
:•v`gŠøõ85ÀTÊŞÑy™TZïyÙ-[ktô5ğF#aÌì¡¢R·ÓÉĞİO!›/Æóò<ïdôaT­…|×#3|‚äÎÍø­<ÊÉúŠ(ùwXein"è[¥cÊ«2©ÁáY‘§#É ÊÆPo–K»dÅ3‘HÁÀêAœ‚VUXZ«V7Cà%zä"œÚ"Bö¤s<›È°WÙ=Ã¸¾’š4„ƒÜ8şu˜œ¬NˆL
zÓ¬e³’OÂ-—®N7Dã'ûû»D}âªƒ ÕHP¿:Âa~,ckì±”©³ßO›òŒÉ§Vîˆ!«–—1q²Ã®gçqÌÓ&f£“`3Kïà(OÛ\¡¤Ãi¡ŸQOJ]{ÄÅgZX¬¶)ÙF9ìÁøc6ŞT!î ¡Æ¢Wméé¼tÅÇÒ¼‚îüˆ
*"äàó#[œ—gJeçë¼(WâQm3M`‰ĞÌhá~9#"Å*¡LP|Å¨nÕfgI˜öD!®peÒñœm˜î!™½“^vÈt¾€Wè×%üëàJ1\#n‰äó^à¼^jfîKË0kõ’ dSş‰Lâ}§ŒŒ^\)v¦ÍŸ¤¥•¯?./SšI=ú’EZ‹/ÅÀ›YŠ…KºKjBá@…—jÂ{ÆS‡N“P:fæbOšÏÊ'ÍgáÚÇøœåìyLn<şR®ã©|&=œ‰Nâ”öÙ~oöCv¬ŒıÆ#brhÌ_TAC«˜NÚéh½ækWïh)4¶zwœëëïĞ†º™Õ<
Æ‰2Úå…PH‰ñF<ÌszÛ7•VşÊHTæÆşYÇt•®æŠ3yu>JÛ–şòÂ.zv¢‹B¹êŠNA#Á•W±ÇmO#ÏQWÍ<ÂíFªáY3¹MyîĞÙíèhÊÖ_àjÈp;'ÔT*eŠ=ôöõòéi¹l©lîÊ”a"}-TÂƒëäè5²DÀe„U†/3uŒ8p™æÿfYáá{c]h¼Ï0,‘=¶íDâQV¸Y‘6Él–®Ş©I*baY-Ó¤Ó}v!ûË™loVPà)éM'İ8l¥q£G7éµy\SÇ}e-!J•ÉÁò>¡‘ÆY_½(%V/¹È½Ên¨’²éeœ­zF‰$q×èéÄêÛl¬e"%Ò´I8Béÿ¼	:-9á*4*õî2Aù&3©´¬€%İ<ÒêM‚ç “_|ÿƒhÆŞ¢aWWb`iO¾_öı¼ç—¼“I©(Y4²ÆXX¹‚F»‰+ +[í"“|Ğ@c”r-”!óäå´âUÌnı¯qcPh†c¯éxDW–ëŸÂüÙ˜o'f£H¯°jkæáã¸äÓy~66îŠ‡ŠVƒ¤²ŒÙÆÓ§$fá]óøtMâÀ5·ÖfÔfIÉuUÕšÍ`Mp§=‘ŸoLß»Gs8jeôK4 ·õN„	YÙy¥ â¤‰ämÌ‡…œx¡[*),V>ÚÊö£‹áôÑ‚’xPİßÙÂsèÌÊº¬¤¦§aı{êgRÁÏ¤¦2y¾ƒÒS”œ/N=)#À1= ®˜4%p%}y|ßr•,/= /üqƒÕépùäœ.¥GçV‚9Dzz²Í†ó)U)ªk·`I’ˆQrHéá,ªµÚÏ¢¦(*¯6¨wBë¢¨|UC‘”¬En‹ åz‡@YzT·Q¸1=
dv$8¤+à²w£•:(àç’#> û=^:½JÙ¡£*9€ğöñœ6?Vß%}‹0{W5Qoó/h7WóROÔ¼ò™tú^*ºígoõüæ{‹¦†H%âéÌp©-«­d“=†dæQÜ1êWÀû9à	ur;İÊx±şCŒ,Â;]ÉÃzİéfâ4¾Û`û­ÔGFåë(•LªÈSû@£™@×£°w	yöŒ4¶ÒæFÉĞNá©##PÁ}¹ÌİùâÜl
ş{•šÏÜ¥ŞŒÄ_‹bàOzº+ÇÜ4â˜y5Ç°Ìšù™ìÓBv6ËKş–]hğõW]|ozüN:Ÿã»Y©+óÌKZ©à>>)ı©²={SÌ:”í«K]6ˆ·ğöÕ§ğ†h¶cKïĞX¯—±QÅAo<À ÿùÔ‡ì>¢…êzR.±ò6ÈôLŠµ ,üğ ôä™e¾.¡=0…·	&|ûšIÉi÷£PÈ™b­ŠéFÉ‚N¢-Ä¡ÉƒgßtÛûéÑ“øZ!'@îh2‰¤u«ÛµÌ]fÅµÊÓtu`ZÇnOw`~,¦RRº$0ŸDÕkzÆÇÎëU÷gÏş¦EºšÛh/®®™(Y5*d6ºDoP¤è=ìŠ3Šü&	GËÂ›³P˜t0™³uz±”Yy~#HÑK$ê¥c	Ótş†Ò,»É(;Öá“…–^`3‚¸*ËbßfKY¼ÃD÷™aMJ«Zº‹æÎd¸'ø@Y,dQa‡—ür¥:ÑşÈ¦ÂåO3£ Hzz{Û¶ ‘ç _¼æsÛ~ó	:8YO '9:­bĞLÀ4Ğ  -è.óg»
^§,ğ<KÃÂàkÓ2Ó…x`ÙÇšİä}6˜óØqH‚ãçô^ñÄ]ò¶ùháıcJıCİTYšTl¸áí Ë[È#`B‹®kkÄé`X,z<Aë„Ëy)!YË«)Ÿ _\ÊåVã»ÛG¾ŒIl›ŒxNxEœf3Ò¯ûºƒ!å•“úPÄ~PœU»Œú0õcEÓ»3fç€Å,¯U÷÷FqÇRhYó
ºĞ™¤—r!§’W>ä®6$C´[ÚL‹Lb×kH¶€/ßÑ’iy€«Û¬cwip2¦âyèóD „…ÈwVkqº¬ÅmKœÇÅePÁ!g»ø‚c»*öA”ÄÎ×z°<X`RV9Ş/Š%_~Áíù^®GÄ,‰LDÑjfN(©Õu Ú›$5Ä‡,n£.~S0n».˜®r’4JA2÷i6’ß§•×a“—'ø#ìÆğCTP¡p‡ƒi<²~a=ª=ñÙ‡ãæ¬ĞV“ òèK ¡æšº&¹¦®)®©k¾¿Å(^-Ág¿è¦*Ùé!=¶nëGÌÅ´¾3ÔŒZ0x,zÔ
Ÿëº?ƒ(Z
FwûhÛ:[Ğ81Êqoâİ?¡òWjC9`zq	xUÎ¬üx‡jÇ0
_Ÿ¡tí#aŒÂùZ˜tl|‰ë>Ï{•Ò¾w54úF¥ù±oOb7ÖøòYDñs$“ŞAx-
ˆ»Ü‹Û‡*'k„LYVóåÅĞ˜çÊˆ‘7CÅ±õ‘Û4ƒ$àa]¹‰ÇÕÀ—¢·
'S)¤³,ı"Ø÷A;÷±§¬‹b÷JFŸ®<WËŒr“œ»e®·ß‡NÄšˆTô…‹w–<Ë
,Plh|%/öëZ¬Cjİ0×Ô:­É‘Üø{ íl+·±<>bÃ'H®½u"•QÑ˜_ÜÙ×Öix8Aµ4\9f`0¤¬„i`,Y#ÓŒvj¸†÷¢ÿ¡Qø3"·xè‡ø¢a½â[“şŸzÆöxc£kiÒ0œÇ#:'56?9€øìH²Ô­N2¾ËC®âÇÒ0ZÇÆ‚‹õ)øHV÷F&#FéLLd¦€ØîisŒ[2”‡ÃøëhñTSr”º\cÔzÇÍŒûÂJËì.×3£E‘PùõÀX[.51¤ë)µ@ç$uÅ¤‰ŒŸC™ººø•]Â±wRd¾WŠÛf,Z@òº¯®™<cxšV#{Ùe»ÿïKòîZ\&¹|~yyeŠ,_6aø|ÃïÂş‡ucy«’é6/©¼äki)®ÿWWåûÿhÿ/æ–“û¿®â™¦Ö't%Iz÷jQ“İøÇ©š_·T1şŞŸúkTİƒù¦©ÙMã+q`ÉèöèÍ-Ô«Îó¡ Êıù‹]ÜÂ¹xWH5ÄŠ…›&x—ÓĞzº“!¥ŞûÔj+ÁøuJX†J ÖAoÀïú#¬²³¡øS:Ü©ıbx[×èıáö)!ğş˜¾?±ú°ÈÄxÄé¢­q ›ô:VeŠf×ğ›”¼ËÒ©(­ÔF¥o¼×êAÑÑ_PôuƒªA‰‹Å4˜ßu˜Æm]iÆ²hF¥©OK©ºµ@`¹´@ö¡Ã(î®eÿ¸m4¨7’‡IMİÖ:TF³4¬C¨"¦±ŞÕ¥Jd’É»‚iîbv €ÅgG°›îŞõî8»{—7Ë#Ì,±}~d’İ<E¹€Ôûfƒz¥ñ%4V[İí¸v¿m@›@ÄÒ•Ÿ†ñ¥¼Ö§WSE”‚7]££ÙÈÆÇèI ÀEØ^lË¥Ù ÀÇ¶áºº‰ğÊ<æÌLøÈzeÓ0û/È£­¿÷‡ÿP…4–é­ZH”«ĞĞ4ßæôêºÛ5”õM54“|ª;ÎI¶êÚ ”¶iùN›.qhDf»oÒî1OX|vFÄĞKÓÓ¸KÕïºË‹PA÷K{LG«µÃîuã§×ı¦#wùFDMl‡nÍÇ8@ %¢ŞÒ‚|ìÌñšÆz‹–ÃúıÕ¯~E/ dFÿİÚo²ä	*¯¦£?#Ù~.ŸuÚ0V›Ùpa$İNâEeé|>_¬å—Ö
ï¯-¿O#Õìíã­z¸ÀµIDÖ¹G\ä2ùyFf6~M3u‚½œ˜°Ó¥è˜ƒ28ZK_ˆ"äIº}ôşÖÉGÒˆ{ÏÈ@|r^eOàbëzïè^ú}BW„RÄõ{Ï4„Š´ïJzhÉœ‹7ıuñ‚‰–>?İQ<:İ¤¼‚¨nÁĞíZM}¶@›ÊØäC(?Z†láG…f·út<±«
5ì‘l;LêÀxc eû{ Cêb‰T„™T‘9q’Ø»¥b>3¬ˆ&+ƒ
GA/Œ.ÂoÌyŞ^~¥1¨,ˆİº~‘6ôÒÆÜdˆŠ³]a¸úcœİñòvtıæwúRØÖ%Öş†¦ß÷Õ[%ÄÉ<¶¡£6:¶W–¾˜O+1b\)‘İXçD•É^/Ô ŠyH.6¦PÿtLD±ŞË¡£<J:©-Ÿì£™.Û5šÍ½>´ìËhéóKĞM«EçÉ5’u»½Ğ×±Z8I&“òÔ¬¿Ğ¨jF/¥é wíğ@Ü vQ¦ÇßAÆÇ7²üÌ@¾tıî].˜èàb#í„ksR#˜ß6LG†ÜÍèÜwqæ¾Kæ„:Æ"Isz¬ˆÖyL¡tÓ¶<uæÇL/v¤ëTY½=Sá‘ú(J¥MèfkÉeAûÈ²d®^0J„‚ÁôÇHãg‘ Æ¡¤&Å…ı~:WHçWjùÜÚòÒZnùlúH>“Ëä„F2–ÒÏ ¿Äf.«¤±ğsĞ’‹ G;Ö1şòì½4$¤ÄÒ1E%Å`F!fHù9Š¨C®E½æ:ç.>KÏ¡-z(²8B†åõ¦ñpŞ¡ùB'‰y™~LÓaüùT¥šÎ‘#ôŸ'±•ÜLÂAüºØöç·˜‚J=‹*«\d:
båŒóXGæ¦ˆ›^Ó—ı²ù<Ÿy?“«åW
1ù—ı†9/^†DÉç5^&,é¾¾ÙøÍNÁBºnŠøÅè}Vgã­¸j¤ÑkØPŒÊ–ç(xøhŠÎ7Â8ŠÎ8š ZßQFß}J#Û¾d™ºkpé<#*Êû–q´£Á,ágô¶¿Ynñó,(‚ÂS u8Â
:jĞà—™¹!•€³èÍYúÇßÄ!)RØ–¦œÂ¸@JaÆ¼$»–lè6C§“Mâ.BRÙJHâV*ı¼£YJş–7ÒE2½N‹}4P²cÔ³I•Ù¤w;µü£vÉ¿)EşÏ˜LSNÉ ÚXş£!à$DVË¶ Ítœ9óE¤°vÓl¦wƒ	*¦FMDŠ;N\§qe†x/¬íôo€P¬Ââ¡|,FkZÚpÓ3 Ìpiü³œ¸§3%úïeÖ›£ÈªÈÈnt¦ê<¼fëÊM}±JR˜Á‡ƒ*P_ß1…hEÙüyQP¥d.@êù°IÊîÙò t Ø÷µÑšÔ&OcÒ)üíİe%®e0g™}ûª}Íqc»evÔ;fãî—x
áfYïJQ~%´&n4d›ID’Š©‘ª0ìvyEš¦T/%®Óù±~½ºójŒ3¼bcİîÅ@óŞÄÛÕëÄÁ½à+íEÏ7­¶cãcªl—Ñã5r]Ì¬¸d™ÁÜ«÷ˆvèêŞ*YPİí äøûRêÈ’ŒøÊ×»ò)ÂªÏK1T5bèø½®ctr×3¯rÁ3«Ü•&I2âmÌüpÀˆW2éRæ‘Ï½}Ñ¿E9Mó{ì<?d”ËÎXgzãˆJ&#lë’İh®N÷“Éû']ã®ØÒBcî†[ösfVÆC²ŠY®¸aÌÛQí;}º!J¯ÿ@z˜K¶¢e`ÑCPÒøÅ³:|²q¤›÷¬D³ŒRnáÖ……»c<ÜI] Wû›ªŠ±6ƒ!q˜=^ãb¤YÈ˜uHÃîcP4wÁe\XG¶;,(dÆ¼Ùñn‹VNÑ¶¹2âÈ8¢&GÉäçY„4œHÙ„Ì£u`ˆ›,rI=lœn…\hÂ‚»À]øì•ck„XÃkF°Ó÷T¡Ùç{ÏÌR¬¸KÈSa¨{2Éä+Š‚W¤¬3Ñ‚°˜ €NwäU0}ñ-c¤û/t–oá‹‘Ì>¨}ìtUÓßÉÁ=n³Ñ¡ãğà´°¤`FXW©±Ÿ…ÂûÖ_ƒŞLáÊ­_vjîß«RÊ“ ÍÛJŸú¹Xgâ>À4L+&/ğ-öcQ¯Äw;¡ËN#TQ)#Z•MÁÆ7B™ƒ¶¨s	€»ğbê ]××ßÎjöÑçC1†
Ÿ”´ qŒ¡4Õß=ø}ïmÍléÍÙ´x•¬Ãp5 ~Æ3Bâ¬†QtTÁùÑı–Ô]Í”¬´Ì¡^áãª£Z=…ã‚wsûE"S˜2"Ótn“ˆVkV9ÒqgšÎ¢T°Öut96ù™QLn®Í·°š˜N|ÜPë?RéŞÕ_¸¢Ñ‚
Ñh1ÍÄ1²µBu¹ÃGõZÆ·33¨ó@´€?–'EPj°µn˜N¾ ó›Ê’½›•¯\¦¯úó'5†³uK—&c:­ì¦[*ƒ3dËb7&CWv)8T©G­  uvÀR–»#=èè/œ[eugbUœèä$Çg
j­Ïÿ¹‹'e?¡i-0zº‹œôÈ Ğ³1@(ZŞD^ 3¦U÷j ıÀŸÁ-·ÈZGì ãˆãY¼MlVtÔCcf5ùçEŠ–7Ï3äÀSOÑEƒÍ™Té’"ã‘Ú*Šk™üÂ`"’‡ª›§B“ j•¢Ä.(¦%YßÅ)KÕI¹Šet­¾é2}†êİIÊhôÑĞ`:±(4R%æz¯œzê^Ğõ„ tá7Ğ¸¢«½–¥+yÊqµe•ŸÉ9ºãÃÚ™/ıù®Œ×vbv(à…JnÖKå©rLÉÕÉ$j­#÷@Yî »K%"½ñµ–l…bbğ	ğÄ°{¿F³v…·{Jã¥é-Æ
’öåd|z¹XP©x…­¸@›‰6§äG®ÜKqôÒBÅ&3Šü-#€ß¬P|!ªFŠ0jQñOtĞ¢`x-
`¨ß\TıÎU(gİ¨<›tT¨R%rq¼YŞx@™Ñú:Óšª:p~ò¤‘QÈ“Áå)*T ´}ÒV¨äò¹ŒÁÄïÉÖş~›7û æ“ÏC†Bf‘‘¹EYï¨]ã¥¥@Oá=ªÂ…Ê“{Š­®Q§5ä%Â§,LYÌŒ¢,ı•©6à>0¤_™Í ’MµÜW•,nl ğøZá68Úp‰ªùù(ˆ^	5Xüá:aÄ!à « Àfã6c¶„?‚²
Bè¨±Ô6Ùˆ¢
Š›T”WQäJ7P	 nŠ÷•9³Â;ÃI.©â›Öh%ÓEË#âiúuİ1„ÕÇ2utÔ6Qpâê£nétm½.`ŒGÏ?›Î.5L€[„ß·,N…Ä¼‡€ŞB¬" qà­Ã€³««=‡Å<5cæıÒ}†Hh—]å ³<@•¨|†Xíq~¢˜¤
4æåG„ôçå+%±[§üJpË%ÍCø…È·©G¸ 
]Ğ7iàÒ€(¤­o2Ş‹Q-Çaå=è`Oq>®x0{)ÊJ9€÷êGJÓ‰Q×}Ç*Èì¬h§×½/(ü€óˆÏè­]GŠVîS~7íÈ²;Ô}¾EHsu¶€íIrZ£­ö³wL/Hwh±¦k‹]fk£ãO™¨(c˜lãÒä§©ä<›‰”6@ø£«ï©ğÅ‰%ÉKĞhr5-ª‰haøıšˆÖ§Ü÷³Ì°`ÑôRfºP H#M©>"RàÌÇÃ„½'?Whõ]	1ÆÑCLïØ	µÌ†ÑÏıÜßÓp§YkéiLæôüáA¥®&<ßiŠ¾Ó"ˆ¾h~å;ÂBoûNTşÍKˆñÈ°b1â;¼xšÏİ’€,­¼¸ÒtKJÜ QÀÕË+ù:”5¼Á4~Šw/–ÑÅîĞ$ƒjÀL(ŒÄÂÄŠ’ê:Lş.ŒaFß±aU3;ß7dT%Óº€âİÊl±¨Y½åòMî†¢XxW–ó<WcX)ÜcVş1NËÛrõZ¢\ †ËÚõdÃqĞiŸû	QV¡N õ~‡®ĞBİFş£ğ0•J?i0r$‚‰JqĞZ@ÑQùä!|öë³¸ÓôUÄ³sm×í9kÙ,šiQ hçn–ÊCPK³ qöİ4Íådç×’É»äIE¸z²d‹„ÀÒÛvÇğ|³t³;ız×`¡¾iêòg!Ó<m¸M£óI tšÂm–Ô$}“V*õ`ŠÒğ:
™\†|aõA¤œ«N·ı5èĞŞ‰èb…h.ùÉê3E˜±ìV–çd77Ö+ÛÕJŞİüüçÿÑn|Ñ¢ŸQãä—+…BÆÿXÉOâ\Åå@9î2ÇÿÈ--®äyÿ¯æsÿciuiyÿã*éw©óàsê6Ú=ÒØf6škdfìh½0%¥‡ä>ú ¢’[Ækc¬¯Ş#U>'Íİ/Wç!OUÓ[« oêv@Â>X ïƒ¸!;šëÖí~«µ@ª0q}¥ÛzdìD£A"Ãµ[¼/õ]Pgøûª«¢]šNGd”Ñytu„´›¢>vyà´¹+MÃõrÏlj»Îü
îŸ°(£Ëy& _0=ıÈÀy*"^00åZ)ºkÇ=näu2VØrAëâ%JNBÔ3·[ºëïæG;ÀpNƒBâz0ÒFoA=É'ú±Ÿ¬ÁÏü™Üj¦Ë¯€Ş	Â€NNi¡gÆN@Zœ‚
¸ƒŸÛ}ÇÔs5´ÏÒø+¾¿¸·œîˆŠ 0tKX%€bãÁGĞ…¯®ûŞ©¸É	*^°„êj“ÿåaşüÀ~ú!nÒQqŠÎóÏÇó7Ù+s_ØñCpª€0ÓvÑéØ×‰¥’ÑÀğ!I®ÖbëôÍÍ»'vã¥ıí€P¨]Ëq‡#¹˜ğ6¡€á©Üß•®Bù^¿b¡_PöƒƒGÒ(Î7€„mƒJyÈÔ½{©öbvªZ,›ç«›zøS"M1ÇDÒ6äK–÷d$¬|óe8N~hMêi‹åÕF”â	È¨¥³™çBMo3A|áı6	î®ÑÍ+
>v,;Å*ûº2U¿><ÄHÃ@†NËøP+l64¢ÅSÓqÙbW¼1Ë—fàb°…ÃF¡ïp'd‹£SÃCfìÒô£ÈA~oµR}°§©£›pX¼„2†èÿ¹Â
_ÿàÛ*®ÿ–òK‹ıÿJoÿà»SoMMmi²S%Ÿi€iS7á_şışáïk4”¥ıı=şsü+ğïv $á§ÿ4‡† Ô3Ğ:Ñ_ &MïVPû›ú/ğ³òÇÿ×Ÿ^¨“'ò	Æ½”2†ŒÿÕåÂj`ü/®NÆÿÕ<—µş¿4Àjˆ³¼Ù õHİ~¬Xœú£;Ôÿ(Î-Ÿ]Ôî?bûnCZ"„-	|ˆá5ƒz>frA¸;ŠÜÇ^]¶á50#ˆ«^ñv:é·ïósöÂpèœ˜®ö‚õÀ£Ò^ñ^;á"®~5_œ}Úÿøi{íéq–<	ÄµFfd£ÙÜ"ã¿Ñ¢#üû õ¢t¢ÖOî(W–ŒR’Q¼>MhükMøµd>l;VèÄ#CŸ0Òªû$(Ò‚¯x° :|©Hô,¢^2mDïò·è«[dX¼ĞuÔa=ñp´*K–„òÆ×½iá”[	œĞ­t‚ÊçÔç%w¤_+:MÖé²÷C{úWèÙ+ùÙqül%Zƒ†ç•òÛÒ´Ü‰è¢C+0h™(~qòUq–~MSs†9{	"ßröÛA³“w‡İ´Wï³£xx3¿_eŸ1‚1˜ÍA	z P©$½>o”ƒ˜mïäR`Öj ihûo;ômJ–)é-C ]
§0^'Cáè
Cá=t³IÌhGU*@µÑ‰òÆŒİÍ¤bEi2Ú#şk­ÛìAP#T’šÎG^«µzÅYïH/Ñj³TévIñŞ	‘Mµ‰ÇC67ñúÃuÒ‘só+&İÊgñE“dîÂ`iXË.j}×ò ¢ÑÔ½÷6CĞqm/ÉaIQØœ™1s—:%¡ƒ“I
9ÆçOˆxãjÀûÂ)
²-ç3C–9ŠùÙõ³e§.aRv[ïä¤åcqÎ†Ã÷!(«8{d„.(rµº×TÔ‹±EßcŠ~0½¿Š³Š+X:-üÀ•Fø©œ—İ&Ói×†™¡ÔŠ¤A24ËÛ$Õ0‹şyŒ-ŠÖNñ÷Âa˜*ÓÃ¥L‰Óï^/1ğhèjö‰ «éÀ8õ\I¯©mĞ©ˆğ<M§©‚s°!"4ó¡àt®®ê`-UffN|\Ù7ÇÊ,Ûe§·q–1¢ıw1¿¸XXZY"¹üòòâêÄşs%Ïknÿ5¹ı÷şv}úBõœ<‘OtğÅñ–1düVWCã¾MÆÿU<ûïõÚ•§_K3°ìu?À4ËGå&æàó“ğ¦›ƒG2/^ŸùŒivŠù½{C\lQôa.é0zØ	ùïGY¾¼9f˜ş¿TXd÷?æVò8wæò…Õ¥‰ş%»ÿQ
nÈ¼ Iİ¶àÇ¹_øaoF(&.J‰U/u‰§–è’[¤.óÔ=i™.Ş­à#Şêß=éá)6„^ÀûáŞ6OØñöêVrú¬c‰$ıK_Öò‹ï°–_Y\Y[‚gíıà'à}sÖîãx¢C«·Œaúÿò²tş'—Gÿ¯åÕÉø¿’grşãZÎ¯2xS5ÿ˜ ÑŠúäÈ@Æ«©_³êıú(Ş¬b•ãAzİr>îÁëS.»ŒÜhçAí_ZÍåóôüïòêäüïU<ş=—WÆˆıë¿%ø‹ş¿ 1Núÿ*À­?—RÆÙÇÿâj¾0éÿ«x¤{Jj™rµF¯csÃì?ùU>şË«Ë«+ôü!?Yÿ]É3Êşïƒ)¶ÿû3ˆƒ{ºŞ#íÿ¾¹&ÏëùHãÿ’Fÿ°ñ_XÊå–‚ãçÿÉø¿’'q¿ßÌÃ¸†¯7¦Øçí,ôÿzŞâŸ?š¢¾ Ü)½ÓÊWV·7n‚'Ïä™<“gòLÉ3–'Á>nÜº^2&Ïä™<¯áƒòğÏùç²Ïÿÿ|[Ês›şù1ÿüCö™àpoñÏ·ùçşy›şù1ÿüCöÉ…V‚/>¼ä_¡$¸"AøçÇgªòä™<ß¨×îß™jLÙSú”^¿çïßw­r¹ÙwSSûoüƒ¿UqÂï›ß÷Ú2~:ZÙ{kÊœÊL5Õò¿{#ø^*ÿî?úÓS¡üRù‘ï#ÊÿĞæN5êÇN¯Ş±Ğ'ò¿ª÷:†ãærÿCâ­o½ıíï|÷Æ·nü±Ïªmë¸J—İ×ì'ø/D¬óïû–Õñ¾kõG†~\»ı{ëâB9šÙhê òô±a6­ãûVßl:O¤7oŞ¼q³vûÇ/_.}°´@Wr§äe>—û`¬,/Ş¼ñÃ;ùâÆ¯º'_½|uú›¿Äê!ÄâÔïú÷/ûõS[véÇÒçhÕü­ÿFÔü5¿™¼uëİúló³­íÚíÛ}GßÓ;4bz‘8µÛ¿‹áÑ7–¹këGPåÇ¼	Ï„7ßkh¼ìÀÕKNÕøŠA7l«ÓÙµ=¾ø÷óñ]èÕç¿p,Û]§È>7 ?ƒú>–±CCÓ;<ÌöÍ›ÿÆïüğfæÒ…ÕJ~û»·¿÷ı[¿wëÑƒ¥ŞÑ¦ÛşBs:½ÏıĞÔ&^Ä¥Û7¿÷Önîãé¾ß~ÿG?şÉïÿôw‚ĞËçıºñë¾áÜ¾qƒ•ñî;Ó7oÿÑ§xtiËjÒpòôÍ;ï¾3{ãÆL_§çâ›¿ışíïıîüİwní;P‹ÛÚ›4%“½ukÿ9ğÂmç&KY\ºõÎAG«ëÛÍ›7hÒûÜzç1w?¹ıO,Ş»õÎç<\¼ó½ÄÂMFÓ;ëïTnÜş/nüËFwnBñ?ùÑ‘ª7¾À7¥fSoŞôWM<Ç¾Ğ¦˜ş˜aoã¬üÎTnêşÔ§S¿œêMLı™©~ê¯LıÍ©?šúw¦şã©ÿzê¿Ÿú;SêLıÃ©ÿcêÿœú‰ÄwßKü8‘JÌ$î$ŞKd¹D!±˜ø8±‘ø4ñYâqâW	=ÑJ´FÂN'N_%^&şTâŸMüs‰?›øs‰!ñW5ñ×=ño&ş(ñ·ÿ^âßOü'‰ÿ4ñŸ%şóÄßNüÏ‰ÿ%ñwÿ[âOüß‰ôÖ·ŞâË·÷ïªÌÿÖï(<ÎG÷[1†Ç?ÙøäÓÏŞ{myüïüvğ?ş{ÿÄ~HîÜÍ,¾_¼ï1@ »”Ùrc/Êv‚­Ø`#àÖÄœÈ¡¿¸Üvû»¿ııÿäGï¦~úÓÛÈo7èÏ÷fzëv†ÄMúóg³ğö-x‡ˆoå~Z¸	Œû[¬œå[«7€Åo›½]»õÑM·ßfo~«txıöw(¢õò­[·§p¬ŞÊ´Yö¿œúï¦ş.°ëÿ;õÿ%¾H&¾Ÿøa‚$æ™Äû‰{‰Ÿ'î'Ö•Ävb7±—¨&öÏµ„–¨'‰NÂLX‰eØW‰ÓÄŸLü3‰?ø3À¶È´ÿbâ/%şrâ_Nü«‰-ñ7ÿ:eŞX÷?Hü‡‰ÿ˜÷¿Mü6Àª›*«&ş'ŸU¥)îßşêÿ¤ü¦óFÖş‚4­Um³c™­)¦µ¿=Õ™jNS‡êtğöïËï"&Yé]h‚õŞEL®·à5Õ¢°ËT€ğ4ÿöxÈZb!C”Å@FĞ9y&Ïä™<“gò|Co±‚öÿJüşÿä™<“çkü$Ş.WË÷§¼ÁĞƒ¶vÿ~%2LŞx‹9Íñ4Ï¥ëµÙ˜¬ÿ'ëÿoøúò|sßÿ÷òn‚ıüÏòj.GÏÿ,//OÎ\Åã÷?LFf¦y,pöó?xä¤ÿ¯â‘üÿåØÆZÆó?ù\~•Å[Z^Y.`ÿ//--Müÿ¯â™V/ŞÃSÏùå}âlŒÙuèİn’'‚è7Œaìyö!‚›É›?1yh ª‡DoĞ€èr8.DŠ-ïö{ÊnÙZ×I&wKûŸgğïÚ†3Êf¼Pß<F{7 ½ŞÖÏı›óuÇÒè%ÙŞ=…Œî”E<EŠ$•ò¨'DÔ€X(¥Œ€•¡ÉDAÀ½ãè@o´-’ªìííìal4qm"¥)2'4k/qs†¸†œõ«x„@è)ÄãX}»Á®ù“=94ó7+öÍäQÎÿÂ ´\2n%àìó?Ì“óßWòÈúš®Qÿ[ÊçWs«ÿm©°4Ñÿ¯ä	õ?û¨Ñ k™ŞÉ8Ê¢ÿ-..Ñøyú/‡÷¿­æ&ç¿¯æWÌœ``®óĞÖ×î7Ü¾­ó@şMRÕí#ƒr½¶˜\Áp\o,.%w0Ly«™|!“[
„ß
†Ùª²·®%îÖ¡Ä’²…o±¶"emB£›^¸Şry“ä39ò3òpw“@ùãl[akæ´8ºNZ†Kl^=Òf¶hÜ&¼e…&|íòx_&¿9ØÉö{h¬FNÙß)ïdüÚ‰R£K–#)Ş‘¡‰“MÚÌ5z}Š+Ãa3-İ›-ïl•6¶kÛ¥­ÊìIBítk,_j^ èin{\ ‚l?—Ï²lNö“"wˆDÅ|’Ş^Ao¾!£aºsA¬ìŞ¼£‘®ÂZ;5/2;NGä”¹Zİ”òüü}\ÛÅU‡å=¨Vö0ã±^íÒh¤<ÂaÄ{ySœÊRµúxg¯˜dÏF‚fÓÑJa×È“;Î³Ù@c| ßÍÇğÁı°¤$ î·nZƒçBóæô3øí‰ÛÏ‡7‘ÄAc‹´»ÖãÍªÿ,…Š–2Çê»iñğª^SKí°$¡Gô“ß&,›ßƒr!§È©´Ë ŒØRÛÒàòÛgX.¿ÕŠ¡vª¼ ©­´İSìkıD¯ÿ@~±Œ!úÌ‚¡õß$şÏ=“K®úÒ‡76Öë¦^ĞV6»Ğ°®‡,(·»4–ÇX½êò™|îJo\ İ-—Õz½,»‚ÛY1Ğ&gwâuC ™‘{@vÇ|IçKÜü·alĞ]Ã‘Ò²Ó_¬‹Ëô:€—s¹çÉÓ‰á÷ú„öÇ;õÓg˜ıg)4ÿ/­¬Lâ¿_É3™ÿ'óÿ¨·<€øÒª³û&ó½DÂ¸ñëúóÎ	9ìw:„é_ƒ_vßôbäó±Æ[8HâÈ]ø/ÍÇÔ­~ğc¡Ğ8m’vÉƒƒÍM’î"ŸĞÍº–i´É½{$ëv{28^ÅU¸÷^>y	Í×Ôh=ÃlØ:ò¥v}˜[(,,.,-,/¬œ«97¶×÷*[•íıÒëÒªÜõâêZ²P -ywÔöãj3¶ßYìºçáëzTÿÏãS£¶ëŒÃ6jÆRÆ0ıo¹°Äõ¿å¥ü*İÿ£şıïòŸ±X¼¾ëŒ;€×¨aé¨Ç¤%í”ÿ#œ¤­e¢t¶U]#šK›¬‘	¹Õ´EÏ¥›€#©d&Owæd-L¼9 F2¼àf`Sl’ZZ-Í9»·Ct7µXM•´7‘O¹•“^âÿkDHŸÑ$!#ŒIl wUlş=oÈº-.{'st'c>CJÍ/atº@Z¶38úö)Xšº»V×qK0-¹™ä´½Áî¢îìÚĞ5å½ÓoZ¤ÑóL:íõ,¯&ÿÌ
¨°Ö¥øYÎˆ¢;Ce»@S9kßÔµ†Üå^J“gVLı1e¬¤«™}­39uâµÕ;;f+¢'(â1J½À¾40=å0Ÿ¹p±Ê—ğğ»«ˆ­wtv%µ¬8T°R“:|êi[Ç¸iÌ8Fº“OP <K–uÆÅ@7© W6&k¦ëMİ=¶ìçè§–î&K‡®nIò	—ËÏ’û'=½è0Àõ$î±™š•|ˆ°hñë¹’!;2oƒj[t+şŞ;Ş^6RÈ7Æ“•zƒòÜÙóf)Û=Öë›¸ˆ«™Õ;®:Ågõdt@—ÙÔìæNßíõİ"p%ÚW¡¸yF[×ÜÅn¿ãi,†7çuÏégyTıOÜI2tŒ÷@Ñÿ–WòüşÇÕÜbnô¿•Õ¥Å‰şwÏäşÇk¹ÿQeo¬E0æöG2¹ıñ<¤=õ´BÉê_±V8/¶û0 É‰Õeë/ªÑÕ}¿6´åtŒhÉP0ô‡©ÛªÆĞW*›Óö²Ôuÿ\äugĞˆØñó&ô$(<?B$ÊRôrŠÎ;rBôVz]=†”aeî·u•!˜¶ƒ™Z¯ñwäØ€?h]Ú‘fthRÉlŠIrµ¡W¦onÖÖªû;[¿(íoìlÃZAíZ=ò.µ®e”6¡€;{¥õÍ
;tÄW#ÌËáK¤Ó_¤,ˆáâ`+4†SœbòW8>N<Ï3¡D‡¬\Ú/…!"å„µkj®¶àòÔ-~ÇÃæ]6Oi”H9ãéÄdk!¯ğúg»¢ŞVn·“Ê½‚”á†PmÄl×h6;ú±fë2ê[ús¡Æ¼ß§¥G%™Pß—ÀÌ°€è²¢7wøBë€"oÒÈtÓØ29CùN_e} >Ô¹@-d`3R¶¨Œ`^¼°b=r½N…ÖK•-NÏfÆ.M?Šä÷¾±†Ş˜GÕÿ¹@ÍØÎ8/m¢ÿãqaÿ-r9êÿ·8¹ÿëJ'•í‡Û•gÉ=İé¤×Ùö.4SÌgrì¿ä“‡•íÊŞÆú³dµ²~°·±ÿEí`do¥Z{´Qªm}Á„[õ`İÅ‹‡ZÇÿMr“gÜOÔúŒKúÿ«Ë…U¶ş/Vrtÿgyuiâÿ{%Ïe­ÿ'®@dGXŞlÀºâLgĞEµ ÷,"Uá²C1ÿÃCNeÏ„íDZø*¾¡ù¶s‚öõ&]ÅÈAO¶q{ÿQ9&óèZÜ‘®ÖŒ€{¨…Wa.¹f‘G^«Ÿ§NÕÓÕ^°xTÚ+>Ò:}}ì„‹¨Õ|qöiÿã§íµ§ÇYò„…¬ÏÓgdV@6ší"¼õU§ş­¨æ«ÑCf@½(ÅÂğ“;<ysg½´y:JIF=XT ¥Ñ° ÄYl;VèÄ#ƒµãCZuŸä EZğU–  	À{±BôòzHQ/™6âÆv<Yu3B¬ïl?µAXO<­Ê’%¡¼±çu¯gZ8åV'`)AåsT_ã0À0ëtYËÂİ|EÃİxcNàg+Ñ4<¯”ß–Ş -ñ ;Lê e¢øÅÉWÅYú5ME4Ìæì%ˆ@~Bf0V.•ÌZ£MÍNÂú“ÄT-~cÖ67ªû§IBšV’™$0ûŒ1BØ€J%›–©ó`9(fM)f= ¶ ’†¶ÿ¶Cß¦d‰’Şf€‚0Ò¥@áp
CAª…£+© åí¨J¨6:±@Ş˜‘ ƒ¡Ù€ôáA¬(MF{Ä­Õc›=jD‚*@RÓyâÈkµV¯8ÛÒ]z.Õ«PËj³TfS­¡M¼ƒ7èú×Ö;=‘Mµ¹"isV²ÅuÒ‘só+z2İÊgñE“dîÂ`iXË.j}×ò ¢ÑÔ½÷6CĞqm/ÉaIQØœ™1sˆq5£CÒ&)ä<Ÿ[<!â5Œ«ï³<‡˜m97˜²Z­ù~vılÙuÛ¶l)»­÷Î† 2tvVÙÇâœ‡CˆĞ¡S 82¬âì‘¡0
W«{M?û=Æ})úÁ æyq¶Kı“Òø;®m9.	@¥ş‚D*çgèBy’\f†R*’ÉĞ,o“TÃ,úŞOÜí)Åß‹#ÍT™Ù}\®=ØØ¬È”8ıîõ/†®fŸ²šŒSøÃLÆ×Ô6MÇv
‰›;Ù©‚s°QfÇÄE‚ŠPpI¶wÜ¬–ŒûÂ•+33'¾Î®Îì›ceØl—^uoŒe³ÿBªoÿ]\BûÏÊêÄÿãJÃ<‚õ!ŒµôyÈwŠòH¢æVk)^`×Mıä¹èíÿE×2c3‹ÿ°ºšcñ_K+8şWs“ñÏÄş{½ö_y¬}=ÍÀ¬‚C­ÁAS0š&æà‹“ğ¦›ƒG2/^ŸùŒi‚WºP~CË{C\lQôa.ö“z
ÉŞCó?¬Ç=ÇÓÿ—
‹üş‡•<€bü‡Õå‰ş%Ï4°L€SÉÍ¼ I¬)¢—Î]ø¢À_l–K»4&.J‰U/u‰§úö0u™§îIËtñnŞù«÷¤§½…Ğdgÿ”«•
a¡ª[Éé³%’DÃNÓj<×íµüâû¬åWWÖ–àY{ÿø	xßœµû8ĞøÏÔÊ•¥ƒÍıÚ•éÿËË<şóra¦F<ÿ±¼º<ÿWñLÎ\ËùÀ({c5ÿ˜ ÑŠúäÈ@Æ«©_³êıú(Ş¬b•ãAzİr>î	Íÿ5±A?¾ CæÿÅååU/şÇòêÿ«+‹ÿÏ+y&ñ?äøQüŸœ„ ñŸË
â5zDĞİ…U0\Nø(6¸Ü ÑŒh¬±¡¤Ä	û9CÄâ£LøÚD‘m7—DÒV‹;»•írµæk,¦è¨Á£ŒÙ/›Ïó™÷3¹Z~i)›RƒäıC¡Ti4]wY¨t5Ë_÷ Rõ1$§ÕfÜÓñ¾3dµuÆÚItd754ˆÿ¿iÒvè5dí&Œ¥ŒaöŸÜâb şïjn¹0Ñÿ®â™lÒÉšj”ñğÆjÊÜH#E]óTsª¼™${¢ıƒVœoJDßdš°Ù(Bó¹-äÃøaÙ­d³±F¼Ä¤UÇ˜Rü N±[š)¢C(o`&af‘ÎÎBî@°×áì’uËtAÕ×mó®nÁD‹™½>æëM“gòLÉ3y.ñùÿ‹lÀ 0 