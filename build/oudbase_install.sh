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
‹ ˆZ í½klcIÖ&ÎÎîv³ãïëİ|Ù×·ã¯†R¤^ñ)JšÑ{‡-²{4£—E©{f»{µ—äy§É{¹÷^J­éÖúCb q?ş8cHà$?‚À_â¼ş$A@$$¶ó/äùáäœzÜ[u$%QR÷k¦EòŞªS§ªN:uêÔ9uÃÌN]rÊår+KK„~.³Ï\¡È>y"ùÅBq1·¼´”/’\>¿´\˜"K—¦¾ãj6 âXúÀ|íğpÀ{ŞïóIu«ß<€æ¹}'ã´/¡Áã_(Â`ãøçK‹‹¹âŒq1¿2Er—€K(}ÃÇúİ,’@]sÚÉi’_h3ëÍU23v°{¶q¤5‡”.û}Ç0uÇ!ıHïX½®nºä=Rë÷z–í’¹û•Ú<”©izK·uÃqmÍqtRø`¼Ÿ_*‡Íuëv¿ÕZ µcÃıJ·;šÙ;Ò[ZWÏ°´J”	/Ë}·mÙüeÍÕ5“lëm»c9Kwæ‰CŸe,úìc—w@¦au¡tµi¸^é™Íq×ÚšÙÒ›÷OX÷W4×¯[Î€/X–]ıÈpËe/X¶¾İ³Aº4CjÛè¹ÄµHK‡¶Nšf6tÂZH4‡ØºÛ7IÃjêØ–«;›½6Œ£Ã`À·®f˜Òwô&9´l¢›G†m™tPapÚVß%{*i¨^Q¼aX¡6Övİ³šÍ¶ g¿½“e=æ ‹×Ç>¬Ğ=ä *Ë>Y…Ÿ¹|&÷A¦Ë/B€£²n®¡uÈ‘nc7B|!“Ïc‘§Üü¸ö!£ß0³eë)š¹„É™&kP©Õ5¾Ò\@ì"Ğ“ú:Ù¶÷+»ÛÛ{•­ÒÌKé×j:dã¶pêe,»•:¥TÍ&¶ñâx$)¸
Ì‘~Ç%´N_w.Ğ ä£ênm}{«£™¬l—wvª[•Rjow¿š"#¦i ]­ŞÑIÇj‘C¾h½Œ`ßß®UK©åÚ9àmÔa
’.Î¦ÚÚîúÎŞÁVy³Zš™C
7Ï™Ü|rosç ²¾[]ÛÛŞı¢”Êºİ^Š>|°¾µÏ¼T2œfÕâ™™™T²¶WŞİ;ø¤Z®TwK)úÙ“CÃ6óRªı”Ì=bÏy÷ÎÓ9Kfî¦’›åõr¥²[­ÕJ@Ó[¶2Óh'«»»Û»¥\R¦ˆ‹$÷ o6¨.BÜxgß!Ç‹ì;ZKŸ›'/ƒ¼µb8½vÂ2Œ¹v$'
)QÓGkÓi‘ÔúÖƒm²Ê*^ò“tûÈ&iƒ|„³{}hbk­z¤+ä##š•-øş%û¾³ıØ²›€øï‘gQ•’nG;­œÌ¹¸8taq‡_1Å¢ŠGÌ”˜âvTñF[o<§Ë­÷:Fƒò¥ R»ı$È÷Éw•4ÌRÅ°õ.dS3¡5v¸È®»OH?¢¼$¦thX0ÁX„Ø’UnÃjQöüËí‡ÈNY>ã<‡ùS’n¹$G}ˆë»™Í\ëèšY6›¢o¸,ßÌËÂ)}­w`­ù/º|Ğç‡Fò49öµ.rjm2Âb<Ê5ºT`éö.kªÓ^Ÿ›O¾¤í\ßÚÙßƒE2gõîiÒ²®ö\' ÙÚ'0Ì©ëğÑd}Û ~]NA‚Øˆd¢Ó ™Ìo'%p`¾7oLRğƒ¤æ	Ù[ß¬ mîÀÂÒ±„¤~vç‹ônúNóàÎ'«w6WïÔRó~(İİ/j)LW(}z·?ÃZ•zS)9Ã]ö^É‰H¢îh¤è‚†|š"%ÂÅ€àdY…¸0(/­£Ñ¶0¿N¢yåê:IkÒ|ôJ*ój0/L)ñÕi‡®÷ë¸óbÕ¾øR\›–RÅY[æ£x8´u‘-NÉ*µ4ÜÚ¦eêaŞ4Æa»w/ªM¯YïG#9zç]öX¤¼  PD‚¬›f ı°Aà^À_î%GÃ¾á‰÷gÉydÇ^öÜ¼·æ"w…•6$=Ëì*/e
Ù«ĞL²R!aKÜ"Z×ê›T×ìV·ÈN†Ô`rõé²†ì½aÙ(w½Œ\EaÔ*`2‡Kûü¨ğ—†Â—¥*6 ‰¤oZ.T—3º…Ü+ß?%PüØ-¯mT=éæà~¹è8èè¡µÒb´Gw)`å¡v¤”•öäóÃ ¯YıN“Bp­~£Ív|Ø.¥ÛÏ ¦ciMòtæå'Û@ÙŒ@R·8´½5Vû*ÛœBÃô¦\¾8´|Õ¶¡‡&•"ÔâC[ÃŠÓÑµû¦‰ò×	5¬nW3Up…s€k:’ˆ	uqÔMÃq¨d–²eŠ…¶ıÆU@@¦©3–ø	´§£óV|‚Ğíl”ùñ¦„BlK#ö'L´]©qZš¢TØÑí‘Üï¨âˆ™ŸÙ@ñ,üÊB~‡VÔE&n˜ğµË6Yş|0Ø©|ŠJ²cÍ45â€üŞÖ:K™¦?ÊvöÍç¦ul²¦ÇÈ{iÌ,%§!æ¯â´«w­#«u¨Ùœ÷ŠúÂ‰İU@îe›úQÖìw:òâŒâ™äê±íãÑ`0e×D^\ßĞxœˆ”1,è@ \ÜXÙ'I!ºˆlLtQÅÖã‡˜-ÈéB=Ÿ‰Êé”me!ïí+B’îP±‡>]qâÑ%¯^Á›wIºx-#¨ÔšÏAmX×v
N'I‘Ì™¹Cä6şÒ“¦z7OÙ;œu¤„³µ‡ ù~oÛ“\–C…|“NÒå©
ù—J²uÊªdĞÏa.üåòŞ{8LÇ$%é”æ´¤IoDÔ~ÉËJ{Óì¨8Ç:QÿXH–ÛÔŒé¸%êwm­GRJÃŠ¹î¥“IÎ ×%İ)pÖ¡€HzAí¹€ÚM'>HU&U§{‡))Ş/LöÂùÖÒ]«d«–ïÙN?\ĞøjØÁîi6ƒ‹z'¶ïà¥IûÈX­¬~¹Z]µQÚó¶L…'² tÉ4s9‰éÍäaé1O6OdBF2İŞ®y¨¬UÌÇôh19¾9dÕXL^{ìVw6Ö×Ê{¨ÄaUW©2ÊÏEcdæ®¼PĞ½Ç-Ôö!Ïñ¸@¦6X”Fåu7™Q˜¬™­“å§õŒK¤ÈŒ
šs	rx3fõ{ù$fbzö™ŸC]m*TAXˆm«ËY'Ó—^ş¨ÒwK$Ô˜‡6Jp˜è…o ‹ñWĞ3eBYx°›AüÇ[$uè®#Ì¤¾¤G²Øìëj:©í=MFP¯(&? 3/wWxCNY7½Ë—ÈpşA«Pq1<8|1}SæÀeÒ_À“<g:ÍmÓ‡¶¡=ÀÓJêö\ú}Ç¶zºíºƒ˜Â#ÖG~C*[€>{,·‰D62º6H€e ê{*QDáØ,†úÙ©¼˜W²sÑø±­G‚ø8³Ö„°ähì<ığ<;mY'ûË™l:;+Ó!”úÒ‚Åé¾ÖxyÉz…©¤»ıkôğ<Ùm[r…=‚«¿pQŒÉ¾ÜúĞÉ>5³$ûáil`çĞõÿ’çZ• F¦P-zÚa‹2ÙØ±Å4?\©éöìjğjò˜Ìµ`_Ø4Èl(?zÔ›Jİó‚HcÛ¥î°ÒKåa¹ ¸Å¸!˜@Ãßµù†LCõÛˆ%q+càFj£RŞ¡jŞBªöc+àf^|¿P~üÙÁ6ÌiÇÏÉìıêÃõ­—»µRê©™~
;¤ôkêÃõ‡[Û»Õ5XJùÙ†¦´„g0yò’ıe¹Ù´a²ÈWg
øèéG³XËìÓ{Yò57³ÈWY3àù<‡“ûœâ±ÀKº%¡ÏÔ'óWeÖyâ¼:³`t–ò!Y~ø…‡)O{Iˆóê2,-øqR£”Ú|7±ğ4‹ 
˜4tâ0¾3FR#8#‚³_ÕñŒ¾N!´È²C×)ª/›ÙÙ¾\Ù\ß’—ØULkvs„e,¼vEUì¦4)nX#ÕÖçÕbA]øøè2ZŞãS! ø•45p>¬¦>ä„{J²Š]Ğ© õòîo€Ö·PÔÁ) h}©Iìg#ğÂà£ë¥‚BºØ>õhÚÛcÿ˜¾n‹O5	û_fÂu-ö¿‹Åµÿ…o+K…\Úÿæòûß«Hûßk²ÿõ&Ü×Åş—j°HŠãy‰v¾î¦¿ïgàÿK2ıÍ/¦k[Í>ˆ>°wóÔ{ÈééãğÄ·Ã†N÷)ùxÍ‡¿ŞÆÀcµ>³ğ•Úğ~ƒLx¯Ğ^7ÂZIá&¼!SÑÚ=’î’¤†G£›ì^Ä^wtcİ0ÎÀÙØä“'¦t¨y^éMÍè¾#.>±‘½RY2±‘ØÈ’‰ìÄFvb#ËYäÕÂ°Êõú<vá›XÈ?±U=£­ê˜ì8¯Ãªpb×÷5³ëƒ¬Õ­G¥¡V|ñ€¬> µMLû.@µc6î€g·àc»ß<¹4½îª±Z¥fzWa£W‹1«ëBFI43'ä<‘÷ªnìÓ…ìS’mÍ_š}ßXì÷¾ö&^œíÆ6‚Us&Õ‘t)ÎŞ3tµz¤^$P0 „‘VêŞç`š‡ñFlš4lw³šz¶z Û£w$lØê*|Oì•ï—ÂEd¤İq°±^ÃÃkfqtDf9=ë_9zÕè»€y‡ÕùğZÄ»áqywíFTI‘§B;ïiDÛcà< Ù£®QºCL+å½òiö.^›ğKõMn-ê7ÄßK	[¤¸Vh5bß+ïğ$F¢vmŠsˆƒ2´}ËÜ}š}:çŸ"™»3Ù§ùìì¼ß4yåõxØDZ9Û`ı,ñÒ§ë¾£"k^‚šÁ%Ãøû.0‡èİ&³³ş›çlßf7ALı˜²sÃP$pßîŒ>>¥pŸš°Ún¶bºº dqSÇ›s!h)vÁêMéÔÓ8,çXÜ»m'±`{2#
=ó9èŒÈñ®<IÛÄ¹È¹ú!yEt1İRìÑ+ú:”Ğ/–İÊXx8âdjÿ—”ñ¸-3
d…Ò©ŞyuJ‚3,{Õ~ÈƒÔï-ÇêÛ]–Ù2>‰Jü*Rº¯U)Ï¯@È{¡©×ôÖÍ}Iº'ŒZ>§FI•õ]U/¡ ßbôĞTgV¦ìş•÷.‚2­äVØxà¸6
1H;s8ÍÒ"7' ½kY.ã¦ÍUä¨$r¹gŸ<Y­w4óùê³g³ó!Äù3E­öT†9¯ªƒÌFdğû6Œl»„¶YÊ2Ä“ef³OSOSÙˆìlËÏ‘…_óª–M#Ú™ Îw†Hî3/Å`œx¨2^?¼=Õ“¸ƒOsÜzÅou@/ÈIkm{s³Œ²>ß­ofÄt§	“9n[KAo$à¯‘,æF2ğBm³ä¾Ç|ˆ
˜Ù˜Ş<¨h'\c>û³;ıYØ/¤Qûr¥“=z¦~
!0{¿àLÃ²dó§¡0dÃÊ¬ÃÚÏİ „¢Íã‡Ü¼ê¨„ÃÕ3ìPHç—r}›»T¨Nf¨vÅ«. yAÒÕªlï®V=ñ,öîi
	Çß‚„y ï$Ş“ssôËÏòó*ˆTŸÇûèıâô¸³;„mö	0¦á´õfPıî¼¢m¿ÀŠÕ´Í?Eó˜uuØQê6Ş¬Õ›™”§,‘¬¦gâÈE%ï$èizHÚìëÔÒ‡9k˜‹ÏÓÅ\NŞş‡—¢ÎM…zİÀ˜Ò.Hú=°Ä”UãÙğ¿fö˜W„ı'q¿w-öŸK‹K‹ıg~qí?Å¥‰ıçU¤‰ıç5ÙzîëbÿÉôÍµÿ\ÎÀÿCì??ÈäV”<›Ú—xJHûÚÁ^ä²®8EhXæ!Õ%ÃïÌGg?ú|bPíÍ0(Íeòo¬wÙ+5+İûb[´¿±1rƒX£Ä˜İg¬iï¤§'?«VwJÅ³ÀáÀ¶úİ:LhŞc]N'ës]ï%×ôĞt°”J§Å÷ğdWşı"äAGkM,hßdZ—|„¤úõ·¥õê%i†œ¨h­²¾µ¶[İ¬ní•7&6¹ç Ú×Ê&wâ·vb“Kë˜ØäNlr'6¹é×É&w$“Ü‰QîÄ(÷|F¹\¶åNŒi€›ÓNŒiß(cÚqûÉ|iİUcµ»Z½3Z¶ TMiŒzF¶ãtk9±gœXN¬Fß`«Q~<7¢Õ(ó÷/
¹¨8K?²9¶ìË
>U`1.puÖ:¨—~J+’Iø7VëE‚ÕÔcö;YÂ9ÖõçÄ¤ªøäVõñÁãjõ³­mIç²ŸšOnoTü°ğ3¦g^â	Àéü<-~¿¼öÙşÎA­
”Ç*=€J¡QJ‘;¸• ÑœH«TØG!¢°:D•P›qhCU$4‡?ğ+>faUìÛ-~²Ê!ËRÈj“&ÖÃä¢vœªñækk‰.d‘Œã­Áìl¢ãA #Ÿ¾|ÑEµUæ”D2CT;B§0kV‰kùxã¯Ç¡éá÷¯(Ê–•Ã£z<qòÆML3:Å=Ìmedg^ª¸H…B¯F4•MEIÔØñí:º^³ÌC£åãójJúxÃ°ôÎWÃQú(+Ûá2˜·õÛæ­mo= ÷âZ=¤iÂI¾8 wÎĞ¶`Ñq4cšĞ¦=U„ÚPhZVk0—ÈŞot*ıì7Q¯!~r§Ÿ1°dŸ¦ŞCÎñĞL&ø¬g4ãú9ª—¹Å1ï­€ÅñèÖÆñ–Æ÷#'õŒŠG2(æµœÛ x¸1qHçOz‘MÁ^8 n—û®…¡r” K:¦Y‡X&ÚëÀè”5è2a)ÃÜ‹ÿ0ûñˆ&òP8€†,}ŒR—ë™$lFnwIÚ™ˆÃOfâ›±eÉM8´ú ëÏé­LX@Š@z>ö`GÄø“©7Gobê}†tİ¦¶¯eBãßÌ§f½”:ÛçrÅÜ2Úsøäò‹Ë…ÜÄşûJÒ·ğİ©·¦¦6µÙ®‘ÏkÂgS7á_şışÁïÄwFYŞÛÛeßh‰ÿş}?å[üùí©©Ÿ€Ñz½éh‹À¸—ŸŞ©qoãŸ©©?ùºZÃÆPÇ-^‡¹éßEãY÷Û,ïOyÑ†¹ŞÑ×Í¦şbjêÒ?üæşÿôŸÿ~æ¯„Ğ^Ï¤Dº¤:ÏÿexZÎÿb~2ÿ¯$Mî\ÏıÏÿM¾ûÁ”Sô&.ŞĞEÀ#ÿæF0œèäÈeÜÉ…o4awÙ“ıDĞC!„Äã|7Ãâ25ÍÙ´Ïu;ò†méîBu(:\MÈÎ§`¬\ûdÌÌâ}"x¤Ùš×œÏ ¡ÕtÎ˜ÚÖ1Ûú ¥y• ­†å’İœ!cn"×3|²MxÄõúù¤rı"¥Ş¿ˆ½_0MÏ×˜é¸Ãç– ûe„Eh¦1×4lš55“KÌIï¸IÒ;„ÃæTw¬NßÅCu·UhşõçäÃÆ½¸ºå“Q{€	İ×:Æ¡§ØlÖ#üè'8&ìf‹‰¬€*70«“¬T”÷70øL…y g”¼Ÿ¨^-¥äá[v)Û=«¹”OO:˜–²Ö6*Û°‘UêmZÈºÔŒÛkå9õ™›ç>€äÛ åÂsa–Kw±¹P/&êlÅæÚ«nîl”÷ª5cÙÑ{c~‰İíÊşÚÜŠ½(æJPÙ™1šñ,‡İã|!SÈä3‹™\(ãƒÍÇ23İğn•*ˆ×–RŒĞÃdy©d "W’	ñâ€‘8-áôT&J©Âù)~“WECúµš–Œ¡NGÊÑ4©$‡UòÁÒ*âòÒ†•d‹¬!“ÁH‘w ©áHà²¿a ˜ÛéHA¨IyV; .AÄ´“ù!Uë£å,oÒ7÷ê*`‚•‰ğâµì­2C³«ÏØ:ªW^‡× $Ø›jrã²ZòÍ.¨w7y8R§ø®á4\Ñ04	šÏÏ8LÿƒìYw¨]àƒX«B1,)êÓ¡pƒ¼3 XašÈ¶Ã‡Y®
^e´¼úlø6­†˜Ûm4rŸ«ù³…ÆXª8Ä.¬|Rn®Êı
Å“‹Vªğ\©âOËÊ¢Jïû+ûR;ÒX×"çğO©İˆ(\¹º¶·½ûÅ3”£ÆI‰À;¨Ly@Ñ‰†ƒ-Zâ±È‰ã¶vİr/¹··÷zúá­gçğ%zjoPyÓ»nª¿Ğ}ŠF–³J¯àöşîZµ‚§Sü+=ŸzÍm™?-XÁÅ”¿tËd§(+ÿ§1fş?[wû¶IòÁèÑŞ„Â½-ß@x˜z/#£†3ŒøÉŒGÂªáõ^ù™«Û]¬‚hş9açD,q¸IÕÉNyï4Ê;4lÇ•hËÂğœÇ,M¶ĞWÄIæ¤uJÒ=`±+ñêò£jå ãÇ©déå…eôs…O9,BÍì,à>R6ÈÁê¢z}v@hÌìéáÓˆ¼>#™H‹H*ªÂd|DéFß§2aÏyf	ÉëÇhd¢VÖ3â2„Š0Zäÿ.÷¹./²)©"˜œ’èqJ"D|èÙ¾É\ß³)“,ŒSßŸ/·Yâ«:·`¡[HÀF@ÄïÔâ†ø„£åÈd2>î¨g9½ÁÔ/bB…Rù‘÷İÕêŠŠO_ß’—f6SÃhBİ®2b´F¹CÕÓaß€·ãX°¸à%[ëĞEãÖçÜŞUŞ(JG¥:°Æ:‡$˜‘¨Â{0ú³Ï
˜¶Œ#²ÇCÉ4ZÀ	î#"ÍËÌ-ÆF<81•œg“Í›-æ%¹]yÀìıì&ï´bçµRs\K,ÃÑæj@X¡ônÏ=ñ‰ 21Ë¬…F‹‹*Šµ¶bLî½R¹~@ÂÙÙÓFšy¢Â¬Švt4ˆ±šØ§¢x‡tûú0ÃúÀ ‹ZÚK”ÁÕ¤\Âa» N&^?Cß1™ƒ¿D;!J\M2ÔŠ$y(âÙÊ+UI¤MmåyK¼‰<
Œ¡¾ˆ[º;3ÍÅÑÛÙií¼t6n£ôuiW#dÙQs\u$¡ŸQr¬8ú›¦`‚TÅmiÏo”ÉhêVè¯¸Öa¬ €]ŸÓe^í)¬&=p`Û ‹
sğ…*yxâ]Ÿóz"Õüd4/ ŠmxÏ³u÷,€F­Ê2Ä<íŸK¸9ùºúYòœ !€ÛwÈËày.u×äfdûj¤˜3.HÈÎ˜ó¸~PİsJ·ÃÈ£B†qo/OÎÅŞ™•ï†ÌÂÕŠš¥³Ü‰-wHÔ©'ß$‰*Fe8Ê¨fû½Ù™9(û¦ğäĞV[!	¸8S‘À£,ÛäğêÌ:Ú{}÷@ôœõ\rBÌRÆŸÿ\5fÏÅy([0šè&håJ{È;)N¥Ø„™ÂÉ<rvX	Ù;º"IÛ5„ek~@u´Ñ€X¦ÅõÀQÆÙédè¹¥”-²#İ ˜èóV4ó`oVCÆæ±…>AÔçfüÎŸ•fcNB0¶Yã)"Uì+šÔ[cÌ€—aU‡³oTÊ;d9)‘ª@Oç‘Ykj^õ VÛe/Ó;‘Ù©Ú T`WºøÀ‹‰»Õ`öqŒñeøQr¿fÆ2æ›æËËe°cÖqÈƒÙİ7$=iòìêšOH_²èJ)H‘tøYègTJ©‚lìıBÆøÖÓj›Ò-_ä^Ÿªâ÷½"lÕ<¼j#sIç¥¨ÅyÜùT@89ÎlÑ<F9/Èåxg;™PøÚKg$íWÑ³Ó=$³wÒK¹“Îğï2ıZÄ¿Êïaë‡8Û
,·  |iæAı„d!öò)ÿÄŞö¾SŠ8OÅì”fi[âÓyê™‚ßCj5ÀZ|÷"¤3Ö³Âgc·s3Ì‡ïX{îöõNGL·¯ =_İ¦õƒ2Ëé¹¤=~•şB²ŞÅ$½sÉygò"ÆÌ¬&¯=
aÈÒPhÙğˆİ[9=‹H¢€/	àuè©HWšñ¯"2©×MI_ì•¥»hwrT2”›şÑ¨àânÌIUìå8ÅbÀ³®S‹DU i&×­±Ó½Áš!;UR°ùQÉp;'Tå!Š½¢ã¤ñòñq™^¨dÖ†”`"ÏLUÄƒÂq¼`Ì¸TaÏß8q™¬õfLYa©w†jp—k“%rDÃ›Æ¨#&EĞC¥cÚ$³Yº‰¡ûz€9Q´L“²ÿìBö—3ÙŞ¬ÀÀ“šNºqØJ£ÂV7i+.$¡>QãDÍ¡:y%Xß'ô^õ8kã‚£Rcí’«„V¨‘ò¾lœ½zF$«AFæH'Vßfs-Z1-xÎPúÅ·Gã'lNNï°S+¡X9HD*	¢ M!I‚³”Ÿç„<ùÅ÷?ˆÎÃÂs1ïòârL^:’/ÅWÈûş
ÜósŞ‹ñ¤T/jX¨W¤RAİEHqÈ++/"5Rş ö"Fu!•ª/"uãïÅ«Xİú=¼³yÀ÷á¡½¦ó¤¯	óWc®Sé\#NßÃ¢aì›oŒãĞÖa:‹Ì«'úr¢¬Õ ©l `¶ñôiàÑ*¥ŸUNW%
\õhkuFí–”Ü¶Q¥Q­Ùm‚\+êä\-7&Œïİ‹Ã9ìcú%ªìÚz'Bi§œ Ğ,Âb\vÉ4æ«C‚O¬IÎ-•ÊluëÑÅn\ù`AHÜ¯ímo¢=2¥±!+©ÏÓ°ÿ=õ©„àRŸ
y6@R*IÆEÏN-¢"²ãó@vE¥$eW¡Œo#ª¢å=ävuÁfˆçìò9»ô<º„0<–ÏÓ³Pl6\NiJIİ»k’XŒRBz> ˆhT°Hd£‚û›¨r("krÈ×BFdåatCYÙó¨À6£`ãó¨ìÀ{#³Ãs%»ÌDD¢rÇ Aú\üÀÇ8i¿Çk§Q_”³*Z£E²wâ´ùeÖ.é+P„¶ÔB¬½c“ ªT-K5QËÊ7Aé{©ê¶_¼Õó»ï!l˜8!Õˆ·¥Âµ¶¬¶RL>¾R˜ûNF_;kÄ€ej”%9 ‹…v±ñCˆÌ¯2İ‘Ã¾ÍsèyÌ4¾[g'UÔf‡úğãû!+•T£"“'¾4EÌFóŞ%äÙ3¼ÊëeÏ-2ÍO‹ n[äÌeîÎ—æfSğß«Ô|æ.µ."şİíÑÛ±0æ¦ÆÌ«9eÀÌÏdŸ²³P^òo°}BÅ­¿{â§0âwÒù?ÇHEh‹g^ÒFO00¥<ğ§J¼<`ÍT œX\ªø/ÎZÂ'ŸÂ¢Ù6Ì-½C=,^Æ¹%»”¸ş -Cò©Y…z\bãmàhf«×ƒ°é;òoQƒğ’g
øV¸„şÀKàŞá†PÔíi6`$=.$ı½Ğ’R(v—¯¨`”"xN+úBK:¼‹¢ÛŞOïÊŒD×
:tGC(PhL(­Yİ®eî 3+Í¨M¦R¾iÓ|»ºëc	ôŸKóIT»¦g|è¼Qmö,pämZ¤«¹öéêš‰œUs¡AfÓ [íŠv®¸3ÄÃH0ZÆ«AfÒAï)dÎÖiP©°ÄòüN\HØK†KÓtı†Ú,»É0;Öá“9t]`+‚Ã’e'³¥lÂa¡ûŠÌ°.¥ÍmÁEwËH¡-¬Ÿ)Ë…4#ì2_¯Ô&:ÙT¸şi¦Ü®Co“àhÛtòŒ‹×}nÛï>G"ë1ô$g vº	ˆ:¸…İev™ìtÀ”^=Ø¢w|mZfZÊBs<°ìcÍnò1Ly8DÁq<Éít(8ôJeÛ|¶ğñ1¥ñ¡±/Ø3©ÚpÇúAÎ,D}è!¡fÖµ5âtĞ5Ö:áz^J@VóêBÊA—Rf|5ä(âøcÄ{#@+âN"[‘~İ×tä¬Xë/@wø½qwdìŠ.f„mêÇŠ¤©a{Ÿy
>¨ííbÑ¢à l[æp¡;/åJN%C˜|ÈâgHhË!……ÄéÕbs$~23¤ĞÒ k¡!EÇneĞ..¿GØâD”ÄAG+ÛêÄy-˜W(ªbùW{¥ 
Ë}	MEUYH'©õl:Ú\!5„‡#wêw|®Ä¥ÛÔƒ‡)©~ŸV®æ…u1GŠ¸ÛuíDãÁOô*åaíñ²È17e…Î2| ‘FÖ„4ôÌZnU²–[U¬åV}Í~Îoô4ÎÙrtW•‡%;¨µõ#	ÚßZ
ZF·ÖÜ51Š+†ÛSœğË
ª%ßÄqÎÀAÔ™ L
(÷‰ç\¥¯Ô ‚
R$ŞÕñ.°ò¦œyUön_a¾>SéÚgÂ™óµéØè7$0Ÿw«å=/R(ß¤ùı@Ïâ”0ğù³¸î¦HÆ5R"<¼Ä…õ.øÇ
:T¡P–5à|eÑ‡Ú¹
¢‹¶PAq¿qä>_VÏèB¨}GîbFqcÕ<¥h‰áh*õts†=¿t˜Şƒ\².
İ¿~}oç\=3ÊÕrî¹Şqæa[6"PÕ%î*ÑcLò,!!Ï3CqxNWc-ë†¹ª¶iUvùÃßO9ƒÑ­m^2ÂãC¶R«9Íu÷î¡A$/ƒ²Çê†[“bÄn·!¹‚V®ì\*è{P‚4Ğé œ"#ãt3sl°†!Ìî¹‰BmúsfH:nÿğĞ÷Cı¿Ä÷&÷íMå >ÆºaÒ¥á|Ò…ïhÇÕØòÌ³Ø |âV#ÑRÏà„ß²ø!7¹ˆ‹Ãh›]¬ÁGò´º721BÇ`d"ØvOsœc<+ 4$ÆßG{„çßˆ–)ô›÷…É„WX(¿Xi-ZÈ­€ÊGEdÆÖq.‰¾şNÕ ÑhJKD:V D\Åıc±£BL76´æ›GÈNÆ²ê'¯;rÁ$#5tÏ˜0ª£“½¤:†ÅÿÁxùÅB._(®äòyÿ£¸8E–.	%}Ãã4­Æe»—FŒÿRÌåpüóKÅÂdü¯"áøïVaı«fºÍKªƒü‹qã¿¸²âÇÿ‚ñ/àü‡§“ø?W‘¦©º‘e÷âêP#5A@ÙŒ‡[©šGïOı5*ßƒÀÑÔì¦ñ•¸et{4¦µïó¬9¨ïb_€a!¸V½¨S×itKĞóïÅ°ëÙcğ8­§;Rî`Ü—V[¹ùÎÃ©`*‚ZíO¼ğ'Ø<¬d{]±ìt¸y)º EÇ—®ÑüÃíSDàı1}bõ‰©£o,âtÑ‚¶¸¹›4£"£±<’Š,™¤ÒvAkTl1âµ†ˆP[ş‚‚¯Ûèn	jìXÔ]i€€w¨ƒgëJ7VD7*ıL­kÊµÍûãšéaŒÂîZ¶ØÓ·µ‹2ğzª©ÛZ‡n˜ğ6TòÖØèêR#2Éä]A4w±8`À<³K8Lwïz1îŞåİ²ÀŒ2Õ{Ÿ_Âd‘g(zßlPû8¾G„ÎjËN}×î7°h(°Õ×Ğóì‚×û44MD-iÈèÍF2>F³$x„~Ò T„£ày½{PÎušùØ6\W7± †ÌbfÊìÌ3²QÙ0Ìşòhóïıá¿X!U‘r5ÃÔÙ‰À®æôêºÛ10+7úÔĞLò©î8'ÙškÃ®¤MëwÚtOK}µÚ}“yÂ<73tä8á°¿šÆcÉ~/0\ïjt÷¶WŞe›.<¦pX\'~Şï:r—Ÿ<ˆ«ò0¬ò'ôDÔ[Z‘™ C÷Á\ïAgÑzØx¢¿úÕ¯h 2vÊó1€[ıM–<ÁİK£éèÏH¶ŸËg6ÌÕf6\I·“¨(Ï§ó‹ùâjáıÕ¥÷©Û‘İ=Œª…ëD{ÄI.“ŸghÆAãaZ¹£dphoÅ˜.ùÍTxßÑZúB"OÒí£gğ·N>’®TÜ{FÂ#PÂğJ(‡@÷Z×{G}ÿ{Ïïª|1ß{6°¢!X¤}£öP¢m&s.Fúê¢ëù–>?ÜQ<8İ¤´Œ¨nÁÔíZM}´@ŸÊĞäk-e\†lâG™f·út>±Peª–$eã:0ßØ @İş¡Ï¶Xbä!Ä&5dNÜMöü×Ïg†UÑdU »Ñ¨*h ±è*üÎœçıå7İMÛ­ëéCßUeL$3,˜²YãêÁ›ÑÇ6ó¹°3¬#Ê¬#ül¿;î«şæÅ]?v‚§v:ö‹÷>ŸVcÄ¼R#‹eåDÕÉ^¯Ô Š>P®6¦RÿNDµŞË¡³<Š;i-_ì£‰.Û5šÍ£>´îËèéósĞ«E×ÉU’u»½Ğ×±Z¸H&“ëòÒ¬¿Ğ¨hFÒç wms½ vQ¢ÇßAÂÇ72ÿÌ@¹tıî]Î˜èäb3í„KsR'C6¿o˜Œ¥›Ñ¥ïâÊ}—Ì	qŒù˜åøY`­óø„âMûàÔ™E5‹goñ¸Ş!9Îğ…Hù¥‰’&t³µ
ˆä² }dÙc.^0L„€ÁäÇH	ãW‘ dÆ¡GM
ûıt®Î/äs«KÅÕÜÒÙä‘|&—É	‰d,µŸA~‰-\QC'1‡KìÓšŠ`D;Ö1şòüÔ¿ŸDÒ!Eİ@%¥`!VH9DÔµY"f"ËFİWŸ¥·™ğ0b(°8D†•õ–ñpÙ¡åBw“y¾_ÊaüõTÅš®‘#ŒŸÇ±•ÒŒBA<‚Ulÿóø†£€Rï[Ç‚Ê*!G¬Üšà¨ûá°cÓ ^Ù/›Ïó™÷3¹ƒüra $?úg˜òâyè@|]£ë`Á’"y,Æc¾x
)ñ]”ÑH7g™ã¬Ík¤Ù]jØTŒ*æç¨xølŠ.7Â<Š.8ÚŞQfß}Š#;¯f™çlpí¼ ÷SÂû–q´£Á$áôìXiñó, ‚ Ràép€U¼şÔ ÀÃ¹!‘€“Æx§üaœ’â	;Ó–Ÿ0*ğ€åÜ‘[R97Lâ)BR9JHâY:ıŒŞ*=ş–-'Äch‡}tP²cÔ³I˜•Ù¤·VşŠ~Àäß#ÿgL¦)?É Øx ôGÊI€¬–m¹H½©@JxÂ>XÊLï$4(Œú1>î8èVÉéRÏ¥FC¼Övz7@ ÈVaóĞ¾³5,í8ÌÓ3 ›áRj)qWgB:ŒFlÕ›£ÏÈš(Èb½Rqúr³u%†W¬&°AÕá¤
Ô¦HŸCV6^T(™ z>h’°{6€ÜÍö}­C´&ÕÉS/w
}{QnDPI–ç,«o?B´o :nlñ'G>y2`v†˜“^°A,V±ÎØáD’¹³€G¥T†HMwZá¦)Õ,Kñu~¨ƒ—_¯íÜ'£o¤Ø\Ã{b¢yïÂíjÏuâàÙĞ:£ZŒVÛÑq†!U·*hâ¹/fÚ<²ÌÎ‰ nÇÕ{D;tuo‰$¨vPtüs)udIF|e‚ëİùóª!©%¯¬<h=*1tü^×ÑO¹ë©W9cŠYUîÊ
Š‹N“$1N+¿2b°Ö1…kyòÌÑ¸l~|Õ4u,à‘óüY2¬8#éiôL*©Œ°¯Ëv£m¸:=SL&ïŸxz»âH•]x~lÙÏ™ZoİÈ
*¦¹âŠ1ïDµïôé(á€ø0—¬EËÀ¦‡ ¥ñ”Zø²y¤›7¥EµÌR®áÖ…†»c<<I] AQıCUEY›Aç<L¯ñ1R-hÌ:¤a÷Ñ½Ásß€§à2,l#;2e^†l{qd±í^şc£Ã—GGTå(©ü<†‰#«x´Lq“ùP©‡•³Ñ½£ ‹mAhp¸§ƒ£r¬bixİˆvÚ£ò€
4{üì™iŠs	y)O&™|EA@zE*:c-˜@Æ«Kò*ø3úì[†HÏ_è1,?Â±PÍ>ˆ}jäóvÆm6:0uîî¶L	ë*-ö‹ĞJ`_ûkĞ¨Z@Ş¬ÌĞñmW å~ÜHS>™B¨ŞVÆÔwÆÏyÄ¦_ññ?’aßÑëµ
aîI|³ºıá1D‘2¢WÙÒa|#„9è‹:ç x
/–ªÑå‚ıã¬fm>e¨°9@N9Ñ‰‚¦Ú› EİÖÌ–ŞÌ‹7É:7òÏxJH\ÕĞOô‘Œ*¸~áí¿'uBWó\/+=3sè5€qµQmBqÁ¨½Á1d>ÑÆÔ &ŒÈ8]`Ø$¤Õ–Ut<™¦«(e¬uCM~I˜¹µ›kóãl&ËL—F>o¨ö±ç4¿«¿pE§5¢Óbº‰wbdo…Úºÿ5j_ÏÌršAØcy\¹Ûë†ñä{à4_±E¡"é±[Q8ğêeòª¿x\sa8YQ³4NŸSÖÊb`Rœ!›‹¥
CÙ¥Ù¡I=ª®³ı ¶²ÜéAGaàÚ*‹;óªbôD'ÙãkQS¿şÏ¼=8…–µØŒÑË]ä¢Gd=[&–ª–‘ÈL£iÕ½H?ğgğÈ-²Õ'È8ãxï›Uu&ÅÀ˜YMşy‘ªåÃóÙ÷ÄS4Ñ`k&ºäÈxè…Šâz&¿0Éè¡è&Ø©$¨X¥±ŠjI–wqÉReR.¢C]«oºL¡r7ú´2}44˜L,*‰¹œã§¸4=¡Yxİt®j¯géNR\GíYåg`qø°tæs~*ãõXİãÅ!£à@ÑÍzOCejÜS2u2‰ÚêÈ3PV:@îRˆo|«%]¡X|ü
Ñà¯Qm€CáRÏmz‹‘‚$}9_ÎT,^a/.Ğn¢İ)™ƒÄ¡+R¾´RqÈ•"}Ë à7«_È•ª£+Å<jUñ)z<hU0=†Vy¨İ\TûÎU)'İ¨2tV¨\%rs¼QY@‰ÑúÓâyŸ=é@dôäìò„
ÊÚ> é«T2yŠ<Æ`ìwßdûÿ¼Í[}PòÉç¡@!³ÈPˆ<"lwÔ©q±(ó)¼gLU˜Py|O1" Í5ê´¡†¼¢DØ”…1‹YQ”­¿²ÔÌ†Œ+ÓDÒÂ ¥–ÛŠ¡Å•ƒÊöfy}+¢Î6Üb…Z~>âÓ+!‹Ÿ#$!FÜúš

èağ(Şh3hKğ#H «à)˜êŒCí“õ( ¢¸EEy…®ÓJdâú¡x[É`å‘Ë8«¼3¼ràä’(¾aV3İ´<ò7(¤_×Ch},SGCm'î>êÖ‘N÷Ñû†Áxäü³ÉìRÇ°¡ÎdxÌ\9’¹Âæ= 4¤¬
€z¤·Æ®®ö6óTŒ…÷Ê÷ q<¢_v”›íòUv Ê}veÄÅmvzû;tÓœ×\€×¯ÔÄâXùàš7Šš(z 
¯S.˜ 
\P7h |APO×7Å¨ãyå3èàHñ,|^q·ú8S”r îÕÏ”¦#®ú5éYQOÑ¶E
=à:â:kG·‘‚•Ç”Gcàª™w‡†Ï×¨³i®Î °?©BNk´Õqö®i¡òñmÖtÍ1`³Ëtmtş)%“\šü6•\ƒ§“"‘Üßwtõ=Õ³¼˜*±&ybM®¦Eu­ßQ¥_¡Àş´ƒç~–f,ZƒF¦
4ReÀê#eí|˜1$@Ø»Ñ`ò{…Vß• £Gß8Àøn4Ğ2JH?€ôsÿ|LÃ“f­¥§ñ1¿ çOÊ]p7á‡EFğı˜Ağ}ëğà'ì
‹ê]^¨üXNñÈ°b!â;mÌ×n‰ÁæV‡kz$%bDTpõüJÌÂ†w˜Æ£²x‘¶Œ.‡&)TjúC¡$*V¼T×aiğOa3Jù«ªÙù¹!» *©ÖE.>¬L‹’àëéØY)_ån(‚…<E¨ç¹Ãjáû¨´ò¯qZŞ‘«×s%$n/èĞ“uÇA£}n'DI…Ôû-œ.¸S@uébÀı’ÂSúIİ¢#ŒUŠ‹Ö"%Ğ‘OÂg¿>‹'-P!A[E¼k1×vİ³šÍ"¢™ÍıÜÍR~bi$Î¾›¦¥œìüj2y—<©
SOöØ‡"°ô¶İ1<Ûã,Ë:Å~½k0§ãôéÊg¡Ğ<í¸£óI˜ t™Âcö¨Iú&½­UîÁ¥‹ÌD\è(drò…Õ–rB¬:=ö×`@{'bˆy¢¹ä#D°;>>Îh`Æ²[Y^“İX_«nÕªi zdóóßÿGºñyˆN£úÿÈ/–…õÿ±œŸøÿ¸Še@9î:ûÿÈ—ó|üWr‹¹%ÿâJqiâÿã*Òô»Ôxğ95Gm)´™õæ*™;XÏMIùá¹6¨(äV0€Õ£ëÕ{¤Æ×¤¹û•Ú<”©iz}`ìo8láƒò>°ò°£¹nİî·Z¤×Wº®GÆ4*$2,­†Ì2à}¹ï‚8Ãß×\ıõÒt9"s ŒÎ£©#<Ë°%êc—÷.[PºÚ4\¯ôÌ†æ¸kÌ®àş	
šœg"2à–eW?2p
e/X6%À=µã7ò>l¹ uñ%#!j„G-İõOó£`¸†:§Aaq?i§wˆ äíØOVágşƒLn%SÈå—Aîæ@@&§¸×3cG -nAÌÁÏí>Lˆcj¹‡êg©ÿßŞ@DB§'¢Â=V Ğ¸ó4á«ë¾u*r‚ˆ‡¡P\mòë¿Ü¯£ïÉQ?ÄC:j1NÁyö™âz¾b&›auî	=¾ nB°fÒ.û2±T3ê<DÉÕZlŸ¾±qÀ"Ï®ÿ¢¼·¾½•,4×å8†Ã‘LLxŸĞŒá©ÜŞ•îBùY¿¢¡_PÎƒƒWÒ(Ì5€uƒ JyÀÔ³{©úbv«Zl›÷«šzùSBMQÇDâVäK–Ïd$¨üğe8L~iMéˆå ÕN”ü	È ¥»™çe)¼ğy›O×èáÍ¾v,Å*çº:U»>¼ÄHı€†nËğP*l4‚Å[ÓpÅbÁæ˜æK3Op3ØÂi³Ğ7¸¼ÅÑ©â!3vnúQä$¿7q[ª&ijè&/¡!ò®°Ì÷ø¶‚û¿bıNäÿ+HßşÁw§ŞššÚÔd»F>Ü ŸMİ„ø÷ø‡¿ÿ­Ñ@–÷övùW,ñ¯À¿Û,	ÿùO@rÈ @=Ó©íğbÒôN3jSÿ~VÿøÿúÓµs’"Sà2î¥Ô1dş¯,Vóqe2ÿ¯&]ÖşÿÒ4 o¨ Nğf+ Ô+uøµbqëXPû£8³|2ŞOâøn]Ú"„5	|ˆî5¯ƒz6frEx'ŠÜÆ^]¶á5P#ˆ ³PºÆíÛüœ½2œ:'¦«½`#ğ¨¼[z„·—Æ¸¬PË—fŸö?~Ú^}zœ%O‘Y‘³ÑlÂùo´è~†zIºQë?î(1jF©É¨GÆË“24‚ü86<Ÿ·™WÊĞ‰†6a~N«î£ÀH¾âÎbx	ä¨â1€‡Çb#ê=¦èEû‹Õ#çÅĞ²£v‰‡£5YÒ$TÖw½áõT§\Kà„ÂJ ªŸS›— Ü2Gvš¬Ñm-‡öô¯Ğ²W²³ãğÙNô :7ÊïKoÒr#¢‹N­À¤e¬øÅÉW¥Yú5MY4¬æì%°@Ö.l·ƒj'/h#=´WRC<EÈ#İ³â3FĞÇÓ9(N W*I¹óƒrà ³` QÎf½Lm‘IšÚşÛ}›’9BJz‹×#Â9/%N§p.Œ(çÂÙÎ…g“^6£Õ¨ ÖF'6“7g¤ÜÁ¹Ù„ôó[QºŒˆÿZ«Çv{0«™UÉ$uÇ¼^kõJ³^ÄOï¡ÕfO¥p¢â¼âtÕ^ÙØÀx—k¤3ÖæWÔMº—)SšÅM’¹“¥au,»¤õ]ËË¦î½·€k{ö(
šÓáÙgÌÜ¥FIhàd’BÎËãS‹ÇD¼q5 }aÅ–rƒ‰!ËÅüâúÙŠS“0©¸­÷Î@2Òò¡8gƒáÛ	G†Uš=2B©\­îu5ÄbdÑ÷ˆ¢|€Ö_¥YÅ,v`„r#ü)Ÿ—Í&Ói×†•¡Ü†¤34+[$Õ0Kş}ŒM
ÖNñ÷Â`˜
ÓÁ¥Œ‰Óï^/2ğpèjö‰@«éÀ<õLI¯©oĞ±ˆ°<M§©€³¿.<4ó*@A%h\} P¨µÔ˜™9ñu~psfß-³¬ÿ•ŞÆYÇˆúßÅüâb¡¸\$¹üÒÒ$şË¥×\ÿkrıï?üíÚô…Ú9I‘)Úùâxë2ÿ++¡ùß&óÿ*ÒDÿ{½ú_Ååé×R,[İĞUÁòU¹‰:øü(¼éêà‘Ô‹×§>#dšİâ@z£W/ÆŞÛÔ#~XJº†v‚ÿû^–/o&ÿ‹,şcn9kg._X)Näÿ+I,ş£äÜYA’<‹¶à_Çµ_øêaof(>\”Ö¼§Eş´L·Üâéº+mÓÅ»e1âíşİ“ŞbÃÜ¿şTjÕ*a×Ûk›Éé³Î%’ôƒ¾¬æßÿ`5¿¼¸¼Z„´úşğà¾9{÷q¤h×êã­c˜ü¿´$İÿ¡ñ‹K+“ù%irÿãZîC¼©’ÌhA}rd ã•Ô¯FNOYô~}oÖ°êöƒñ ½n>—0|Êe×‘íş/ˆıÅ•\>Oïÿ.­Lîÿ^Eòã\^#?îÿŠğíAbœŒÿU¤@ÔŸK©ãìóq%_˜ŒÿU$)NÉA¦R; á˜Æ\Ç0ıO~…ÏÿÂÒÊÒÊ2½ÿ_ÈOöW’F9ÿ}0ÅÎ_`‘ããà™®—¤óß¢Ô$½Išÿ—4û‡ÍÿB1—+çÿ®ÿ“ù%)q¿ßÌÃ¼†¯7¦Øçí,:ëş/”ŞâŸ?š¢¶ÀÜ)½ÓÊ×V·7n„'i’&i’&i’&i,)Á>nÜº^4&i’&é5LÈÿü˜ş!ûLğ÷oñÏ·¥2·ù'áŸóÏ?dŸ	ï-şù6ÿ¼Á?oóOÂ??æŸÈ>9ÓJğÍG‚×œà;”WP$ÿüøLM¤IúF%Ü»gª1eOéSZxÿş¿|ßµ*•fßmLMıí¿ñşVÕ	¿o|ßkËğéleï­)s*3ÕTëÿîà{©ş»ÿèOO…ÊKõG¾¨ÿ[€›;Õ¨;½zÇB›ÈÿªŞë›Ëı‰·¾õö·¿óİ7nÜºñÇn<«µ­ã½^v_³Ÿà/ˆXçß÷,«ã}×êıøàöï­‰€r´°ÑÔ!ËÓÇ†Ù´ï[}³é<‘^Ü¼yóÆÍƒÛ?~ù²øAq,.çNÈË|.÷ÁY^*Ş¼ñÃ;ùÒú¯º'_½|uú›¿ÄÚ!ØâÔïÆ÷/ûíS{¶øcés´ÆZşÖ#Zş?Š–ßLŞºõÇn}¶ñÙæÖöÁíÛ}GßÕ;ÔcZ‘8·İ£¯7,sÇÖ É	Ï„7ßkhvàêåN§f|År7l«ÓÙ±=¾øÏóñ]èÕç¿p,Û]£À>7 >Ëõ}¬c›º¦w¸›í›7ÿßùáÌÌ¥+•üöwoïû·~ïÖ£K½£ïM·ı…æ4tÏıĞÕ&âÒí›ß{ëG7÷ğvßo¿ÿ£ÿä÷úÎ;ÁÜÊçıºñë¾áÜ¾qƒÕñî;Ó7oÿÑ§xuiÓjRwòôÍ;ï¾3{ãÆ|¾FïÅ7ûıÛßûİù»ïÜÚs ·µ7é“LöÖ­½ç@·›ìÉbñÖ;û­®wn7oŞ ŞÿàÖ;¹ùÉíÏøÃÒ½[ï|ÎİÅ;ßK,Üd8½³öNõÆíÿâÆ/±n4çÙîé&Tÿ“ı±Z¿qã|Sn6õæMïrÕôÇsìíŠé¹ö6®ÊïLå¦îO}:õË©ŞÔÉÔŸ™úç§şÊÔßœú£©gê?ú¯§şû©¿3õ÷§şÁÔ?œú?¦şÏ©ÿ'‘H|7ñ½Ä©ÄLâNâ½D6‘K‹‰ë‰OŸ%'~•Ğ­D;a$ìÄqâ$ñUâeâO%şÙÄ?—ø³‰?—ø%ñW-ñ×ÿfâ+ñï%şıÄ’øOÿYâ?OüíÄÿœø_7ñ¿%ş÷ÄÿøGo}ë-®±|KPÿJüoıBã|v¿õchü“õO>ıì½×–ÆÿÎïà ÿã¿÷Oüà‡äÎİÌâû¥û†[¡H™)õ1ò¢d'ÈŠM6nıAÜÄÙ‡ú‹Hm·¿ûÛßÿñO~ônê§?½ôvƒş|oö§·n'`JÜ¤?6oß‚wøVî§…›@ø·¿ÅêYºµrHüö·ÙÛÕ[İ„Ipûmööç·Ê7€Öo‡Z«Üºu{
çêÍ¡D;dÿË©ÿnêï¹ş¿Sÿ_âÛ‰dâû‰&Hb.‘I¼Ÿ¸—øyâ~b-QMl%v»‰Zb/ñ,qĞõD#ÑI˜	+Ñ£û*qšø“‰&ñ§È‰ö_Lü¥Ä_NüË‰5ñ¯%şFâ_§Äûïéş‰ÿ0ññş·‰ßHuC%ÕÄÿä“ª´ÄıÛ¿óOıàŸ”ß4cŞ¨ËÚ_–µ£šmv,³5Å¤ö·§:SÍ)cêP]Şş}ù]Ä"+½-°Ş»ˆÅõ¼³¦Ztv™^æß¾Ÿ3—Øœ!ÌbrFà9I“4I“4I“ôIßbõÿÕøóÿIš¤Iú§ÄÛ•Zåş”w J¨k'ğïW¢ÀÔàƒ€·˜ÁĞæ™t½6‡“ıÿdÿÿßÿOÒ77ùö¿—	rôû?K+¹½ÿ³´´4¹ÿqÉXŒÌLó2Hàì÷0ädü¯"Iöÿr ¶±Ö1äşO>—_aşßŠKËKÿ¥b±8±ÿ¿Š4­ŞÃ[Ïyğ>'}vzÑÂCò]ı†Œİ Ï>ÄìfòfÆ˜<4Ô¾Ã¢7¨CtÙÅwû=u·l­ë$“;å½OJ3øwuİe3«oş€z{‘ u½ŞÖÏıÈyºci4H¶§á’¼ˆ§H‰¤Rö„ˆ–A&æJ)#òÊ¹ÉDå€7zÇÑi½Ñ¶Hªº»»½‹¾ÑDØDŠSdIè,Ö_"r†CÎÆÀ÷U<‚#ôÂq¬¾İ`aş¤NO-üÍò}3IÊı_˜„–‹nBÆ-œ}ı‡U`rÿûJ’,ÿ¡Zàå¿b>·¸’[AÿoÅBq"ÿ_I
?û8 Ö2½“qÔ1Dş[\,Rÿyú/‡ñßVr“ûßW“Æå3'è˜kİ<´5Çµû·oëÜ‘“ÔtûÈ`\¯Í'WĞW€âÇë‹K)ôÃKŞJ&_ÈäŠ÷[A7[5æâÖµDlŠ,©Xèñ6àk+ÒQÖtºé¹ë­T6H>“#?#w6Ô?Î¾ºf‹£ë¤e¸ÄæÍ#mæa‹úmÂ(+Ä0ák—ûû2yä`'Ûï¡²)eo»²ñ[7&L.İDX$xGº&N6i7Ğ4• T†çÍ´twn¶²½Y^ß:Ø*oVgH
j§{ÀÊ¥æ€æ¶‡ ÀÍÈösù,+ædï8)r‡HXÌ'iô
ù†ˆ†éÎ¡²¸;£®À^;5/
;NG”T¸VÛÊüò}ÜÛÅ5‡•İ¯Uw±à±^éÒh¤<ÄaÆ{eSËr­öx{·˜dÏF„f}ÓÙJó®’'wœg³Îø0}Gts(;€ŸİwKJÙıŞæ†Şà%‚¹ywúöış‰ıçç‘HârcAn?ºÖãš˜ÿì	e	ìÉkï†Åİ«z]-õÃB’„’'¿OX1¿?•BJ‘	Ré—A±§¶¤Éå÷Ï°R~¯•BıT}\ziïº—Ø×:Eïÿ€±!ò¬‚¡ıßÄÿÏ¥IĞ‡«úğÆúzİÂsÚÊVêÖõ9å–}—}Àr«Wq!ŸÉç®4âÈn¹¬ÖëeYB®gEG›è|œÅ ÅpC22%÷YŒ3šñ%]/ñğß†¹AtfJËzN±,-Ñh RZÊå'O'Šßoh
ÿwé§i˜ş§Zÿ‹ËËÿïW’&ëÿdı5Ê0ˆ/­:‹ï4Yï%ÆïX×ŸwNÈa¿Ó!L^@Gøü²û¦ç#ŸÄoåÀ‰? wá¿<t7H´øÁ…@ã´IÚ%ö76Hº‹tş1änÖµL£Mîİ#Y·Û“³c(®Â½÷òÉKè¾¦f@ïfÃÖ‘.µëëÄÜBaaq¡¸°´°|®î\ßZÛ­nV·öÊ¯K¯rÓ‹«ëÉBöäİQû‹ÍØgé°ë^‡¯+©öŸÇç€ê®3;¨KÃä¿¥B‘ËKÅü
=ÿ£öùïòÓØ&,†ï:ã	à5JgX;Ê1iI:%Dÿ˜O’Ö2Q2Û‚*®Í%‰M–ÈˆÜJú¢çÒC@Ì#‰d"OÌÉR˜x³2¤xÁÃÀ¦8$ûô´Z›s8vn‡è&j±–*Io¢œ•“ñÿ5"¸†‚Æ«h!Æ86`‹'‚*4?Î’„n‹`ïddÌgH¹ù%ÌNBHË¶`GÛ>JÓƒBO×êú!)âæ –%7“œVr¯³ØBÔ¼‘…]UŞ;ı¦E½0À¢ãØÙQÏòfòÏl ‚*ë]
Ÿ•Œ¨ z0T²t•Cóaë›ºÖpºÜÑkiòâÃª©¡=¦•t5³¯u§Fœ#€¶zg‡lEŒ<F.°8—¢§ó3÷î#Vø6]El½£³Tö°ãP³•›ÔàSwHÛ:ÆC{ ` Æ1â|‚àY²¢3*üKx HÙ˜|¬™®S2u÷Ø²Ÿg`œZº›,ºº|H’O8_~–Ü;éé%Ç€	®'ñŒ­ÄÄ¬äCœ€%‹‡çJ>†â0É¼Y\
Še8mÑ¬øKxïxgÙˆ!?OV_èJsg/›¥d÷X¯oàQ Z®2`Vï°êÕ“Á^fS³›Û}·×wK@•¨_…~â,äí]Üs—ºık¤±Ş×½¦Ÿ%©òŸˆI<tŒq ‡ÈÅÅå<ÿ¸’[Ì-ü·¼R\œÈW‘&ñ¯%ş£2ËŞX`LôG2‰şxÒxÚ ¦du¯X/œÚ}˜ÇäÄêƒ°u‚—Íèê¾]êr:F¤d¨ÆÃÔmEc+
Íi{Yêº¯Êº³HDìúyF‡_!u)r9ç]9!z+£®^CÊ°:÷ÚºJLÚÁÂ[?àïÈ±4º´#ÍèĞ
¥š;Ø¢äj-BC¦ol¬í×ö¶7×QŞ[ßŞ‚½Ëµc9ôÊ»ÔS¸—Qú„fÜŞ-¯mTÙ¥#¾af„Xßú ş&eAL{) ©0˜â“¿Ãñaâ}A %„<`•ò^9ù;'l]SsµO‘· ñ;4/Ø<ÅQBM”ŒÇO “U´…¼ÁkŸíïˆvKP¹Şv8L–Q´¤÷à0€j'f»F³ÙÑ5[—A?Ø|,ÀŸ4–¥ğ>-?*Ëˆ*ğ¾b†D—U½±ı0@Zy“z¦  ›ÆÖÉ	Ê7 ğª{kà¡,Èúh`¡ Û˜‘ŠEy³â…ë	0àëuÊŒ°]*oqtz¯03vnúQä$¿÷UôÆ$Uşç5c;ãÚ4DşÇëşBÿ[(ärÔşoqÿëJÒ“êÖÃõ­ê³ä®îô€Óëìx—{š)å39ö_òÉÃêVuw}íY²V]Ûß]ßûâ`xoµvğh½|°ùcnµı4/jgü‘ä&iÜ)jÿ?Æ­?MCæÿÊRa…íÿ…å=ÿYZ)Nì¯$]Öşb
v„àÍV ¬)†Àtå ÙPx1 ^ğÌ"òZn;õ?$ºqÚ¯x*l'R“ÀwğÕ·Ô¯7é.F®F²Çû{*iT!˜G×btµj<@)¼pÉ4‹<òzı<mª˜®ö‚À£òné‘ÖéëcG\xõ¨åK³Oû?m¯>=Î’'Ìe…Øx>#³"g£Ù.Á[Suê¿ÑJj¹zÉLÊP/I¾0üÇşxc{­¼q:JMF=XU ¤Ñf`.@àßdIyÛ‘y¥x`°·süœVİG9€‘|•¥—§Dà½Ø!zå <<Qï1íÄõ­x´ê>dÌ±¶½õ`Ôa#ñp´&Kš„Êú®7¼já”k	œl€¤d ÕÏQ|À2†À\X£ÛZæîæ+êîÆ›s>Û‰@ÇóFù}éMÚ2wºsÑÉ¤NZÆŠ_œ|Uš¥_Ó”EÃšaÎ^ä7acõRÎ¬5ÚTí$´?I|j æÏïÌƒõÚŞi’¦•d*	,>cŒàör¥’MËÔ¹³ä ³&‰ä³^¦¶È$Mmÿm‡¾MÉ!%½Í áˆ—’§S8<Uráì
ç‚§ËËf´£ÀÚèÄfòæŒ”»187›~~`+J—Ññ_kõØnf5"³*™¤®óØ‘×k­^i¶¥»ô^ª× –ÕfO™Nõ hâ¼AÓ¿¶Şé‰GĞUkÀ’66`'[Z#˜y°6¿¢7Ó½L™Ò,¾h’Ì]˜,«cÙ%­ïZ^†h0uï½Í t\Û{ä°GQĞœÏ<cæ. ãjF‡¤MRÈyy|jñ˜ˆ×1®´ÏÊb±¥Ü`bÈjÔæûÅõ³×mÛ²¥â¶Ş; (Ğ1Ø]eŠs65"BƒNâÈ°J³G†B<È0\­îuüì÷Yô=¢è 2ÏK³]jŸ”Æ8pmËq©K Êğ<¤|~†.!”æá‘kÃÊPî@CÒÀš•-’j˜%ßú‰›=¥ø{q¥™
Ó3;+Ö7ª2&N¿{½ÈÀKÀ¡«Ù'­¦óş0•ñ5õMÓ±ÄB¢&ÂîÆAq*àì¯WØ5qñ@(¨$Û;n ”ŒûÂ•33'¾ÎnÎì›£eèl·^èuoŒuÓÿÂS_ÿ»XDıÏòÊÄşãJ’aÁşæÚŒyÈvŠÒÏDÉí ¥X]7ö“tÑmÿE÷2cSóÿ°²’cş_Åeœÿ+‹‹¹Éü¿Š4Ñÿ^¯şWk_O50kàPmpPŒê‰:øâ(¼éêà‘Ô‹×§>#dš`HJo¨Y cïˆ‹mê?,Å~RK!ÙÁ{hı‡İñ¸×˜aò±°Èã?,ç!+úXYšÈÿW’¦)ƒeœrnfIòdUa½tíÂşb£RŞ¡®ğğá¢ô°æ=-ò§¾£=|ºÄŸîJÛtñnŞù»÷¤§½…¹Èö:ş©ÔªUÂ\Ô6“ÓgK$‰Š¦Õx®Û«ùÅ÷?XÍ//.¯!­¾ÿü¸oÎŞ})4ÿ3•êƒòşÆŞÁ•ÉÿKKÜÿóRa–F¼ÿ±´²4™ÿW‘&÷?®åşG`–½±’ÌhA}rd ã•Ô¯FNOYô~}oÖ°êöƒñ ½n>—Bëÿ8 Ÿ!ëÿâÒÒŠçÿc©ˆòÿÊòâÄşóJÒÄÿ‡ìÿ#Šş“ ~º, ^§G8ıXğàÑSXÂå¸ÿˆ"ƒËõ MxÎ‹jº€‘ ŸÓH,ì1ò„¯7Yws¹@$iµ´½SİªÔ¼{¥5x•1ûeóy>ó~&w/³)ÕùGŞ¿JeFÓÑ…r—¹úH7Q²üuß $eWCJZ½`Á]ãğ¡¨­3Ò@¢=ƒ¼©®A$ÿÿMãöCÏ8@ÒÎàƒ±Ô1Lÿ“[\øÿ]É-&òßU¤É!mí ªF™o¬¢¦Â•4’×5O4§Â›I€¸'ŠÒ?¨Åù¦xôM6¡›tŸÛB:\€–İJ6«Ä{˜´êèSªÑ@)vK3…wå¬$bÃ,ÑµÓYˆ‚İ€ìu¸x ¦FgÍ2]õuÛƒ¼£[°PÇBf¯ÏùºYÓ$MÒ$MÒ$MÒ$MÒ$MÒ$9ıÿ‹¹8· 0 