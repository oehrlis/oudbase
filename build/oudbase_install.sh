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
VERSION=0.1
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="TRUE"                                         # enable verbose mode
SCRIPT_NAME=$(basename $0)                             # Basename of the script
SCRIPT_FQN=$(readlink -f $0)                           # Full qualified script name
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
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
while getopts hvab:o:d:i:m:B:E:f:j arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
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

# define default values for a couple of directories and set the real 
# directories based on the cli or default values
DEFAULT_ORACLE_BASE="/u01/app/oracle"
export ORACLE_BASE=${INSTALL_ORACLE_BASE:-"${DEFAULT_ORACLE_BASE}"}

DEFAULT_OUD_BASE="${ORACLE_BASE}"
INSTALL_OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

DEFAULT_OUD_DATA=$(if [ -d "/u01" ]; then echo "/u01"; else echo "${DEFAULT_ORACLE_BASE}"; fi)
INSTALL_OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}
export OUD_DATA=${INSTALL_OUD_DATA}

DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/instances"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/backup"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

DEFAULT_ORACLE_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

DEFAULT_ORACLE_FMW_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} /usr/java -type f -name java 2>/dev/null |head -1)| sed "s:/bin/java::")
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

# Print some information on the defined variables
DoMsg "INFO : Using the following variable for installation"
DoMsg "INFO : ORACLE_BASE          = $ORACLE_BASE"
DoMsg "INFO : OUD_BASE             = $OUD_BASE"
DoMsg "INFO : OUD_DATA             = $OUD_DATA"
DoMsg "INFO : OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "INFO : OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "INFO : ORACLE_HOME          = $ORACLE_HOME"
DoMsg "INFO : ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "INFO : JAVA_HOME            = $JAVA_HOME"
DoMsg "INFO : SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "INFO : Installing OUD Environment"
DoMsg "INFO : Create required directories in ORACLE_BASE=${ORACLE_BASE}"

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE=${ORACLE_BASE}/local/log
    export ETC_BASE=${ORACLE_BASE}/local/etc
else
    export LOG_BASE=${OUD_DATA}/log
    export ETC_BASE=${OUD_DATA}/etc
fi

for i in    ${LOG_BASE} \
            ${ETC_BASE} \
            ${ORACLE_BASE}/local \
            ${OUD_BACKUP_BASE} \
            ${OUD_INSTANCE_BASE}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "INFO : Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

# Store install customization
for i in    OUD_BACKUP_BASE \
            OUD_INSTANCE_BASE \
            OUD_DATA \
            OUD_BASE \
            ORACLE_BASE \
            ORACLE_HOME \
            ORACLE_FMW_HOME \
            JAVA_HOME; do
    variable="INSTALL_${i}"
    if [ ! "${!variable}" == "" ]; then
        sed -i "/<INSTALL_CUSTOMIZATION>/a $i=${!variable}" \
        ${ORACLE_BASE}/local/bin/oudenv.sh && DoMsg "INFO : Store customization for $i (${!variable})"
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
    echo '# Check OUD_BASE and load if necessary'             >>"${PROFILE}"
    echo 'if [ "${OUD_BASE}" = "" ]; then'                    >>"${PROFILE}"
    echo '  if [ -f "${HOME}/.OUD_BASE" ]; then'              >>"${PROFILE}"
    echo '    . "${HOME}/.OUD_BASE"'                          >>"${PROFILE}"
    echo '  else'                                             >>"${PROFILE}"
    echo '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"' >>"${PROFILE}"
    echo '  fi'                                               >>"${PROFILE}"
    echo 'fi'                                                 >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# define an oudenv alias'                           >>"${PROFILE}"
    echo 'alias oud=". ${OUD_BASE}/local/bin/oudenv.sh"'      >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. ${OUD_BASE}/local/bin/oudenv.sh'                  >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg '# Check OUD_BASE and load if necessary'
    DoMsg 'if [ "${OUD_BASE}" = "" ]; then'
    DoMsg '  if [ -f "${HOME}/.OUD_BASE" ]; then'
    DoMsg '    . "${HOME}/.OUD_BASE"'
    DoMsg '  else'
    DoMsg '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"'
    DoMsg '  fi'
    DoMsg 'fi'
    DoMsg ''
    DoMsg '# define an oudenv alias'
    DoMsg 'alias oud=". ${OUD_BASE}/local/bin/oudenv.sh"'
    DoMsg ''
    DoMsg '# source oud environment'
    DoMsg '. ${OUD_BASE}/local/bin/oudenv.sh'
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
‹ ÛúfZ í}]sI’˜îìóÅáéì‡sÄÅÅ¹Ä,	.ñMŠ#Ì@»i¸Ë¯#(içD-¯	4‰İ¸î)Å?8Âö«ßş~ğO¹_àğ»_üœ™UÕ]Õ H‚”f=#	]]•••••••••ujÙ¥'ü”ËåÍFÿ>åÿ–«ëü_ñ°J­Zİ¬®W66*¬\©l<­<a>cÏ7\@ÅsÌ‰ù ÛÙÙ„ï¢Á¿?‘çúß÷N yşØ+zı¨crÿW×7V±ÿ+ÕZ­¼¾ı¿^«l>aåÀ%öü‰÷ÿÒ/JÈ§†×Ï,±Âü€–ÛîÕYnî`\ëÂèYk¾Zc/Æe›ÇZæ…9pFCÓöÙ/Yg<9®ÏV^´:y(Ó1ÌsÓ5-ÏwÏ3YõÙûº²Qe¯†ïŸºãóó5Ö¹´üMw`Ø½¹#½gÍ"êLpğ±9öû+>v|óÌ°Ù¾Ùw[qL/Ï<J+:”ö_ Øu†Pºİ³ü tnÇğü­¾aŸ›½Wœü-ÃëV3àåĞ¼°<Ë±cYäí`ìÏä^ Ï°N×µF>óvnÂ?}“Y64ÍîšŒ·sMl³®Ó3‘oz›£>ô£ÇaÀ¯¡aÙƒ+6öÌ;s\fÚ–ëØÔ©Ğ9}gì³£7­TŸï3èV¨õ}äÕK¥sÈ9>Eê”8Å<qÀâæÜ»ÈÃ¾®rÜ«:¼–+Åò³bµ\yÊ‰ÂØ¶mù–1`¦‹d„<•j±RÁ<›2O³÷H!¤!0£	¿0³c3ç9Z|€ÁY`[P©3´~4|@ì>Ğ3æGlû¯['‡ûûG'­½FîZy«²À6ş9½¢ãgo¶İÃ6ŞkÁ|öÆŒMïÊ¼iv¶÷÷Ğ›™Ö~óà ½×jd_·³lÆg	x×8˜làœ³3~£‘	‚`¿Øï´Ù—ÍÎàoœÂdCM­Ãíƒ£“½æn»‘[A·AÎ°\9Ÿ9Ú=8im¶·ö¿odKşp”¥Ä—Û;P{îZËpSÒ‹s¹l¦sÔ<<:ù®İlµYzCñd@WC·å®•ÚoØÊÎá.Èw“§1Ër«ÙÌns{§Ùj¶;ğôo×€Yìö3íÃÃıÃF9£rÄı{’ƒ{9¶»ÈT÷an¾£ïLàÅ^{Æ¹¹’g×QÙÚ²¼ÑÀ¸âæ\;²SÀ…ÄÔ”Ôrv½s–İŞ{¹Ïê¼âµh'¿+ô/\V°Ø·8º·÷€'ö¶ÚÏY¡Å¾5¢×Úƒß?ğß0Ú/·÷˜ÿ9{ŸT	c…~³SålÅÇÉa“;¼¥¿H*0RRŠ»IÅ»}³û¦×¬.É¥ J»ÃG²ï²ouíFËrÍ.Nl×°¡5n
¸DÒ½€6I$KRJÇºHIˆOÉIåvœsO0Á_ïì¿BépÃóYgì$VnXáÜgeöşœßíŒlæÖÀ4ì¦İû‡±åó|¹ëê}60×Ê|‰—\¾Ì(ıÌÊÜdæ>×%­]ÎX\FùÖ–áè¡†:Q}%Ÿ¹¦vnï¼>‚I²òU}õ&‰	é]×ø`2Ğlİ+ö9;5áŸ§mä5œ@İ€Ú•˜df0Û,l'18ß5“[Ğ'YxaÙ<cGÛ»íà£İ˜Xz –°ì¯¾ú¾ğÕ°ğUïä«ïê_íÖ¿êdóß|£=<L/jO)L³”¾C½û¿ÃZµz³Y5Ã*ÿ®e(&<²éİpdiBC¾É²j@t0È¬R]˜”—êèöÌâl€ƒ(Ë>ù¦É
†2ƒ’Ú¸š&ÈCJşôúÖ™¼]öqÜÖXí/ _ÂµçhUÜ¶e!Z‘Ä©­KládpZV¥¥ñÖöÛŒË¦9vÛóçImúÂ¨ŸŒäìÄ{ùˆHuB@¥ˆEE7e`ãˆA^ ?Zş(GÓ&¾åIPOˆä
Šã {9Ì¹(]a¦iÏª¸ª(ÙA¢Bö64“mC ‹ì-,‰Ï™1tÆ6iâ†{>Æ%²Wd\cšÖP¼wõ½WT«¨ÎZ…ÌVpjÏÏ
c*|U+!µX4}Ûñ©S=œÎh	yÔ|qÃ *x9lní´íæäE³!zj­TŒêñLŸ k‰Æ…aP{ÔÚS©Lƒ¼åŒ=‚à;ãnŸ¯ø°]Ùofà=vœ»şnØ£T”HªàjSÛÛq`¶oóÅù4Ìì©å×§–o».PÑé‘¡ŸÚ^œz×Û6ê/Â&Ôu†CÃÖÁUï ®ç)*z"ÔÚ4¨»–ç‘f×²U…·"tˆj fàÛ6¹HüÚ30E«-1@hye1D‚!¡1ÛÆŒô„v¨Ğ‡u¤)Z€-Tº£‰#e|–"ÅKğV‚üU4D!nÙğsÈY
şÏå#+•ß¢‘ìÒ°mƒy ¿÷ÁÀÑ†é¯§Š×öÛ¹´yÓSô½f–†’›˜ğ×q:4‡Î¨Õ&*Ô|ÌECåÄj «ÏK=ó¢duò@ÁGxf„ylÿå|,Ü",‘÷·÷4Îä&åœ‹+÷*#U™«.ºÚÂ)~†Ù¢’.FùbR®¸J§-+«•`]yf1–	p‡ŠôiÆIG—}ú_~Á
½ÈgA­ÖJjÃºv(8œCv¦Èr+g(mÂ©§@v·ÀØ›:ÖÆÙ;Bb='–í¡Ë¡A~ÊA§Øòt/ÂøËfø<*ƒWrè×0şõöË_b7]²¬b#Ğš±’f‚ÑéRQ+TÖ¦]RìHã„ãÜ?–åàvë^6n…û}×±¬Ö°õr×Ò™Œ@uÅv
’€ tÊEÌn&ëA«²Éœl¦d]¸î…ãíÜô°­^~ä:8üpB³á )<2\`íN|İ!J³ş…UoÕ¨·ë.j{Áòƒ+²¢*²À—Ü2WV„îE>¢+ß¬<Û½RÙtÿ HóJ›«Z˜ÛÑRrü s¨¦±”¼n¶v¶·šGhÄaÕÎë\™å×²±U–[U'
ZÒBoÊŒ˜Œ‹ 2´EÇ¢6ªÎ»™¢&l`Îìƒ’Ø­çR"Ër:h!%ØsŒdÕ¿¬d0·³ç~uõI©`&N‚0»ÎPˆÁ¦×Aş¤F»#æ¡FI	“<ñM1á:a¤ô”‰w‚ø	±™$‚IâÒr]`(÷e–EğŸõB6ÑÚ{“Ià^YLM ¹ëƒ·-ÑN¦_ˆ)2Ò,´^‹w˜#JÌØ–Š9HÙˆöeğŒÈY(ğmÛÂ™k™ÀOWb;@Ã‘O¿\gdº¾ezˆ)$q…iíú<YmKl(dô]Ğ ›ÀÔÏu¦š‰Ã±YõÛsùzEË.xÄÛ¶bHf£`Ê1ø~8núá~vÁbË^é¹R¡´¬ò!”úÁÉé…Ñı yÙv‹›¤‡ãop¥}× v…5‚o~ôQÎ•®÷¾ñJÇv‰•¾¹IâH?ğD®º0ñ‰Õá§>	iƒo[,‰Í•é^Àª¯£öÉÊ9¬+ ›.[e[fO«;/ˆÒw°,Ñê½tVª[¢ƒ»RtÃY_,È4?ñ…X—2.¤vZÍú«L¤:e¸XI —»¶Äz¡ùöw'û¸7°b\~`Ë/Ú¯¶÷®;ì±]8†ÒKú™ıfûÕŞşa{&‡Få¾ ilàL…ı‘•şĞìõ\èƒÊÕ\“¿]ÆZ–Ÿ—Ø54j%WãÉmŞHÏ8åoØn\Ó’„ÒôgyÂUu:¯,èJL—ŸŞEñnª•¤:¯OÃÊ„Ÿf!µÙÃÉûy‹Ş™[ï€)£ª€AC‡Ëe1ŠÁKèıºgöy
¡%–:O‘½,w°
|³µ»½§N=©³˜ÑZöÓX|îJì«Ô9LkRZ·&š­ïĞ«ëU}â½ËehóH…àOÊĞÀñPÏ~#÷†•4¿ Éë›ì^ßCCĞ ‡€äõj"³ßÁ«“·®7ªëbûô­é`=:õcás{|êôÿå.\ŸÅÿ·¶^&ÿ_øµ¹Q-—Éÿ·\Yøÿ>Æ³ğÿıLş¿Á€û¹øÿ
'P&I¹=£NÑŞÏİõ÷ë"üÿ@®¿•Z´ eû®Óƒêk·À¼‡€¼‘ÙµÎ®B?l Â¼wÉçë>üóv«'ğ­İ€Õ‡÷OÈ…÷ıu¼…‘îáÂsí<g…!ûVéaHšİe÷>şº³;ëÆqŞÉ†Ì¦î”x)¥cÍJïÖ€‰yrñ…ì£úÈ²…ìÂG–-|d>²Y!"ßv‚Wn@óÔ‰oá!;şÂWõ–¾ªsòãü^…¿¾Ÿ™_dmï½iLõâKw äõ¨máÚw®³s ¼½_ıVØƒ¹èëV½Mnzá£×Iq«BFÅ”[‘zÌû	M·^éx­tÌJçùóï›‹ÿŞÏŞÅKˆ½Hß&ˆj!¤Š-%°ÙÎ¾qšh‰Œa”Y }´%$‡àÀ‚[b]×ÄÕ¬¡ïí£Æd(öèÌƒ‚Ÿ]eì‰£æ‹F¼¢„ŒD“ín^s£¶ü‡¥åğÈÑ§îØÌ+09Ôóñ¹HámópıFtM‘'¢ñÚç%è§0¥ï`1Ä´Õ<jŞ”VñØDXjloÑ°!áZJú"¥È X±%ÔŒ´×¾áNŒD'mVHˆœE‚}ßŠ«Ç¥ãø;ŒXWs¥ãJi96M]D»Hk{œÎŠ,Í
¾{æ$¶%È.Ç?p‘1Dt—-¯-3ø//Ä¾ËO‚Øæ%‰sËtP"ğĞïŒ’oî±- ëíæ3¦oJF–'u‚1ƒ–åGœsĞ•NßÃâ¸‰ÅƒÓvJá¶w9Yè}(As! /8ò¤,WF çšgì3åpËò¤OôeôÃqÏ‹nxEüÿŠ°€2‹´åN¼P¡«Ô›×—¡,:Â°×ı‡HãÑóœ±Û5U­²¨"¯µ;ùY×òÂ
¤¾z½`N	çÜÈ
#éÔò{rJjmêv	­ôc„¦SîeÊÏ_ß²1(KZnM¼ˆÄÏwQ‰AŞYÁaV¹EÿX8 İCÇñ¹4íÕQ¢®U‘ÉAç^~÷®~:0ìõ÷ï—ó1‰$€…#E¯öF…™×ÍAvw :øz¶ß@ß,-…Í ±Êu™åÒqví8[Š(-Ÿ‡9Jğ–×­l|ÒÎx¾3Es?É]ËÎ¸9	P»á
½
:½{=ÚÕS¤CÈsÜv+luÄ.(Xkkw·‰º¾Xmïİ”8ÄÂ ƒ¹Pè;O 	ø6“ÇÜLŞIh¢o–J{Ì‡¨@‘a!M¡æIË¸óå_}5^†õ@š•¾0‘kDŠP0ö]ı4Fàş~Ñ‘†OÌ“-†Òw+÷Œ[?sZ Ä7¢"Í‡Ú¼ö¬Œ#Ì3|SÈ‡rCŸ»l¬Nî¨“âÓ€|d¬*û‡õv ¥=Í"ã„K¸D”\Y¡¿ªäuùh>OïöÙéâ»¸²;ƒeö(0¶åõÍ^Ôüv¼fm¿ÇŒÕs.í5P?eó/-u§°¢4]<YköŠÙÀX¢xMçÒØEgÏ$˜Ú$íMòô¡>çó1½°^.«ËÿXçêÂU(b×ô)‘ R$â‰©šæ³àÿÂü1û‘şŸÈÄãÑgñÿÜ¨mÔÿÏJmı?«ëÿÏÇxşŸŸÉÿ3p?ÿOŞ ?]ÿÏ§EøŠÿç³bySË³kü€»„Dk©(t]¹‹Ğuì3²%Ã{ñÛ ²¥/JÓ ı4JËÅÊO6ºì£º•}€-z½³3sƒx£dŸ½à¢éèjdf~×n4ÖoG ÛOa@@óŞšæ¬Ls”Y3B×ÁF¶P¿gÀ“ù‹°—ã|áAûSö õÙ·Èª?_Ú ¡Á£Œ0†½U¶÷¶Û»í½£æÎÂ'÷\ûEùä.âÖ.|r©…OîÂ'wá“[ø’|rgrÉ]8å.œrïæ”+t»¸SîÂ™v¸…3íÂ™ö'åL;ï8™_ #­_·êÃzû!Üh}X™*Ñõ1œlçÖrá5Ï¸ğ]xş„½FÅöÜŒ^£<Ş¿,ä£á\Nı(æø´¯øt…Å¾ÀÙÙ U\yUf<-“Œo¬×‹kxhÇ¶=riš˜M¦øÌ^ûíÉÛvûw{ûŠÍåu6ŸÙßi…`f¼)ä®qà&Ÿ§â/š[¿{}pÒiçñJO R(Ä´Rì+\JPAt'ÖÃ*&QH(¬wQ+Öfì$j¨„á‰„°â›éÀpkfÅ±{.vVdC‚¬7iá=ÌîëÇ©;o~±È	àbÉØßŒÎ>
ù+T]t_eÁIä”ãÚˆÂ½Y©âoocÃ#¤‹¨(É—UÀ#;Üy.¦Rİàf†6ÌÒ³¹k¥PìÓŒî¢ª«(Kê;±\ÇĞÃ[}f‡İ8Æ‚@İHÉoèV8ø±{6Jª.‡YôÏäË¼­ı½—ìyZ«§4MÉ—àŞ-Ú-:Æá&Ô´cM¹¡†BÓJF—‡DŞ1\¨ò:î¡]C¾Š Ÿ)°Ô˜¦A¢xè&MY½4:'QYxjE<g÷6N÷4~‘8¨oáT<“C±¨åÎÅÓ‰c6ÿtÖKlòşÂu»9ö¼*§k@	šÒE7-{ÌôĞ_z¡®AÓ|‚§xŠp‹LşÓüÇš(®Â4Tíc–º¤Z§é$q7rwÈ
nòÈŒ@œ¾3“ŞŒ=GmÂ™3]Å</Æ¤¤ó©;òŸ9¹zô®Ş·x>·«íù óoñ$0³>H“ı¿ËåõòSôÿ®UÖkO!'+WjOk›ÿïGyşâoşòÉŸ?y²ktÙ~‡ı^Š&L{òWğ§
şşÀûŸı›Ù@6ù/*ñÿàÏ¿‹dùW"ı¯Ÿ<ù[ĞÃ‹Æh40‹ÃóÑ×òKã_ã_Oü=æ]g@—x¦ÿgEŞ¿àyÿ.’}˜Oæ¶İ3?>yò
ÿş1÷ıÏÿåßâ¿•Ga´/óÑnz :&ÿõÍÿ[ÿëµêbü?Æ³8ÿñyÎø?å³Ü8E'qñœ€)/<
OnD¯]œyˆS åø)¬.GjœÚBØÀ<>À÷qÑàYØ->7ƒPÎÓı`º‰'Dè¹éŸ TĞfB¾?}å»Wó&ğœO† ´ '.Ù•3n»"®õĞÍåÂp-tÜñpå?°º–_„ÎƒÛ¦ıGÙ]‚æõƒ}¼S3tì€²>,Ê]÷‹`]ü¬Y—ôC!ÆÿÑÀpÍiÙ¬ˆ¢ùdä:ØGE^çQ_lfâf>€“Ÿˆo|yH×‘I¯$µæ’à!J¾qNæîæÎÎÉÖëÎÑşîö?Ò}JEÈB¹´(…RäM¥Ò„2Š-DrãàØÖÁzøõe´9š×0v î/Ëåh„%‡òr˜Ò/$x˜Ğî‰ „`4¢ÀnôUÔXvËÖ„atìŠ+‹$4m»TE-ØsLÅO"S²)LÆÑnªXşO‡É3ª½‚¾Aq
N¨±4´z½yi¸¦
úåî[	şN ±,ÁûmóMSETƒ÷03ëÃˆ¥¬Ò™'ìJcà›®ısÁG¥Õ)JÜ¬	9¹µAìº'Ã3ın)jŸ
ÖrHFp!Ò3pŒÇQÈ-ÚªlñøÚ¦8÷	ëÛÄAşüAÎÌµ•ÙûM 4î†wuL_’DŠŠª¡dB'; ÷•Ü]ÏeçüŒ0·O;ó2.J^¦+ã¥¸Uà€=än2Š	ÚFèÄYAVô<;û[Í†
ƒ3›æ9½“Ú¥eÂÄ‰¸°b*r­w!	=s4¹ÔĞÌ±	 øğ‡òºàğé‚oXPxªäºA¯BP4z4mFîAÁ	0«âŞÈµ€¤ÛÈ1ª|ôÿ+•–?õd•¼Ò ]x…8É”»âå—Ï/ş€›J„áVp½•ãÒ»?—Şÿ*]»!4•ì Á&ãFÀ2ø]/äVe@¿©ddKcÏ-‘ìLA<Ø™@Ÿ2JŠrL*ùOñÏ‚†KFÌR¯gó7òúâpâ$rkû°½u´øı	ùÇcHO’[Ó´ç½¡ÀêŒ-uvl/çÉ…¾è>()Õ·:í¶pô9“S¤!ãšV`Y¢˜/»ªMPXèy\¢oq6%\È§¨¥—K¹k½}7äG#­æs¿óö‹öı+ö<r?õèèè{Œ|$HÎıt*jïÒ;8~k~4»cB£$ü#‚‚û¯·Ú-Ü­?i¿î÷Åæ+vO"^)åÜS[Ã)éÔÃqÊ±Ÿ×ş•—›û¸È9h}‡î€g–ëùJ/:x1è¥ê¡k"tË—74‹N¼a…ñg£NóM»u‚ÀcğŸÅÇ,¸2ÌßÛ°=sHn)æPWC-qkÿ°Ÿ\€Ğ¬øZÈıc‘UL”4yß^¨ÀC=y’#Š2h/èÑ„ª"÷¤¤i5ì]EğP+So¢<”ú²j¿J&©Çq(›Où“¡ñ<L§)÷¡EŠ:8ğÙ™âİ*I™™ÅC8Â%)n¾Ñöh9±® 'GvF§gAáñ\¾½×ò=‘E­äQhÑ0,Â’3‹9ùWáÊÆ¼Dã¢‘×àãôäéª9ÜjşÀ)ëâˆPŒ¹JÓ|‹'†t@$B'ƒ˜«—t6As–îã$}:Í7:Ò	ì¾ÎÒ
gˆ“X,q…N°I@g ŞœùŞ‰qJ«ı²ùzçHõµIduí)¸;kU)¬MîÎ¢%Á@¦p_‚£~„ïnÍsiüv{^»+ŸÍ›Çˆ¿Ì»]4Ï×{èŒÚ{Tb¥ñß‰ry’´%Êï4ÉdîÖø¯šè„àmÀª1Üù	(S•ÕaŸÒ`µ1n½ÇNM˜TxŒ&:R‚P%*IÍO@fBó" ¸~g€Bìè
¿š4+«+7ê*g‡ß¾ÔP9Á¹ot·Ø_G·ä(îWO	Q]d‘s`Ìø CzsF,ú±…(k “ ŒŠI|èÆ£×xşm%Õ½Yuï_†/º#,nãòŸZèCO=TŒt8TËãÑò7Ü£¿£w¤œYÊl+5Áˆç«:HædñÅ#Nö¦İ><‘”s>(JNÌUÉøë_ëşˆ2]ZFù„ÑÃ"QGE¢P°Ù—-xÖ xI˜Q²ÃLÈ¿Ñ4ˆ<&ãtÜVÁwqNĞ¶’ˆç ëKNlbG†ß×òIö~¬UCÙŠ;õüK=æ/œZè;D}%?+ÍûœÅ`ˆ1‚À”ŠCKÓ„z;\ˆ2¼êxöVó€ $eJ¬:1kGÏ+²t:;±ìMrcOÌNÀcßuQL8lD³Ï£"ô‡*Ç£¸,VÅ°× 2‹U.Ó6úæˆ¶ö¶Ò˜Ó31É¨L

†İÒ	yy1©‡”F0íŸHê¤G@ÊYÔä3eò™×LÂŸûÎ'
œU¬i	n9à³$—éNßV6˜iKTÍÂt;¼©!wmİ†~å"„õ|äİUãÀP¨Ü`M(6ÑûªP){ğ÷Sü«²{Çv6¡+ «¥0Mø†÷7îxğ@¶!øMô¾Iª&y!—³Væøğáõ",:EÇ„Ù¹XoQØoäpk¤êNÌÙr^ú[‡ôŒF.<âÄU17Ö¡.¦ªÉaªH]Q›şí¬àt»º©´Ò³\qœTô'œ3ÒÍ†-,7°âÃÙxbÏ³	ÄËÁÀDSˆtpç(\¢–ß'Ó)@¨/pá˜hR‰(CéŠ@àÁG×qg|¾üiŒ<}¹ıª‘Î½ñ…ItUã²‡’Ø£ñEBÒøN¨h‹ÜfË%RZI¿$¯]÷Ì±mšˆKk¥?äJ£e‰A0Uô¼B÷ì¼€:Ó¦{iÄ|ö£Ä)(V§¨ëûBÎ³61ái5v¸JP¬cTõğyRõ–²J]öÎAV]9c—ÂDQµ$…]ú:áö›÷0¢ó¨´ï)-l±mC…{ ^È®Ã“½IÊ/rBJíëgÉy8§æ}Z{š’—ºøZş„¼_?ÓàŞ]$ßOX%ö`t©=a­”Š.bc+ØH^u›¸„UòG—±)kX¥Dt›¸ˆ?cÚC#cß$,k5#e‘şıjØ‰9{ÙIúE¶[ï-›‘ju¶½÷æ~Î‰!X˜UÉ©òt<™Îû¬ì­§ì’qÒgñ°)wTå…dúı³“ƒCBvLd×İŸÃìZúÊÄƒy™ =’?îÌóËôHö¸ã:Ï®¤'—P<Ÿµ2½°Å–ãå´¦4te7Z“" µJú„"²QÑ"‰Š*„IåPDÈ"–Ãô„¬âªÀXVT „klLOÊÒ>1;¤kÙUi o]h,Ğ/î$B,¸u?Ù^³ş‘Ê¾OĞë‹;C6Ö ÈMŸ <íé†E¹Ó#AëeIP3½¬ê4Mß•ªûañóQH¾W qe^©Ÿâµ;}­˜jßŸRXÄ‡Äxw@ù„ûÈÓ¹§$5ì@î»~¿şCˆ<v$-a`¡ƒû×d\ÂoÛÜ–K›Ú§Hè‰Vª˜ôd¦`Ék6*Jå]eìı{Ñ½š;ÛÍ ô#åWü†qóİ[)®æ+ËYøïS6_\¥íw–WÖv»»äA™
ce	aä>­p(y “Ï•«¥å(×â¨•0l­RÜBk[š‰íš•bLào´˜ÔhãÖ•‰\ ô>ù¾>œZäÂ0Á­¨T[ dà§D(Şà²}Xá«øU} + ‚LÓrqd¸€‘’\åwo9Ã¡c ·6rZAt…5Îv.)ß¡é lÀ¢ LWFÄ;P¯d)BkŠXt{ñX±64ünMÃÆ¡cø¬rÑ¢p~]Šşt8”ÎÏğØİ
Œsƒ®#·ğ0[qMºÆJ)¬ğtH„¬bx“[û	h<Áçö8f—&üoó¨dk|ÈËXâ%6	ñÉò|À~d9NRj~l•%É­îÁÆÑa¦’ [ğp/a½J›¨?JÙxıK|Ukx\ìm×"¯@¿äóû!ù$‰R0b…ë‹gá²ÈL±`Áˆõ¹g
·—²&Ê`¶±ÏÏvÙ]P²P—{i¸=Ñg“9Oâ‡(x¾Õı@WÒHJû”…W¡SÁVú‡8ó4¥Ú8á"tP3KïúDHh’ğ]ƒy<QMSÆ ^Ïµ¤^Ñ%¥8*ùâAâ¢Ï/,´Ç[gôœ^‘Îî\ŞşóØô0¡æe~MËÃDÅ{Vl¦ì3‰];ë2æ’§ĞŞ•xdHî†f›—š*•nx_„»;éÎ²İ¥áœ¿ÑÀÅ¼$¯ÕJR®GöÎ)ªza²œR¨)$í¹SŠ­GŠq[å”BŠ½1Á£NÕIØm‹¸ÙI(êtÙ>E?O– Ô/éş§  &n×“ÚE6²á‘¼½” ‰—fEL·X¦Ù¦œ™LÌRâÆÃ’æÁ_‘Ã6Á|.]«ÙŸñiPc0X)<ï~7“b ı¨"ˆ4¯.¶ ëÊt]Û‚®‡kã›zÃ?
1“Lîõ„óP8±7¸»æ…BPÏ2ACø‘6/§_¼1Xé	÷ÃHÕJÀ¸´ Ö˜\ñ£SMš§?bDê¬ÄAQæAïÛ$Á¹%|^åw™vë9Œ ùƒÏÎÅs{Ÿ…ãÉôcP¨RàÉ3y~,<•&ÏaZv=u×V|ThYWÌ£²0?Ú†µò>jœºyHì×ºò@9ülùê	ÃğVpZJBÒY¹˜Ï2j¸‡qÒ=°‰Àš†T4{p‚µwŒàÂ‘ôüñ™ÀKš'&PSD~IT€¬kpkUêÁ¶)$çS\è“²TSËóã¥ğI·Å%¢¥mäáÕô.·Î„DMÅa¶MÍ.;6Ä@»õùÌhDäÇlÈ$ŠH‚‘áy—h{ 
÷Hµ%`¼ĞÇ<¬$RÁÉè²Wô?úIç5Ş¶x|ûÊÇf$–™±=ò,/ñ¾Ñ/JÂmh:ñ‘x:…ø¶‹Ïc(Ç<_RC<°Ğ„®™Çz¶ùÜüî÷/Ÿ­cZüWŒ—X©UË•êúf¹Rağ£º^{Â6+ñü‰Çìš.šçğVï¡¸àöı_[_ôÿã<=§û°ƒÿÉÌı_«llnÔj5èÿÊÆÓÊ¢ÿãÁş?l7[»íâ°÷@u =®¯§õ­¼Y­Dú¿VÆñ¿ˆÿûğÏ-†éR¶ ®.­€i÷ÕPnµm_üïÿô?h)ŠVÏp{ÖÒmÒ¸ÇC{ßÁFÅê	7­M8xcXE:wO«ŸQèKÇOİ0ŒÁëu‘éYs€q_ÏûÚ¡VNëĞ4¸g„?Åæa%ûÛš×ƒ·&\/t¿p†&Ş0ïASü1í¸Æ.é;Æ	µM<XÍ¼!î$Q‹»G×1hº)Ã)"©—%ñ¸Ø.h-Şxe "´60?øSÏêB‡b-Ø(¶g&è¯®©‘±%É¨Ñ™6&›İ5vØÜZ£L¯ÆĞa{è¸rùzÙ·º}DÁ
ÃœâÚ-\°Æ¦E†Á{×TQÌdV%Ó¬bqÀ o$\qAì¦ÕÕ éêª Ë³ªEĞ‘g‰ØéØîÒÆ¹X)Ği¸Ü÷|wÜE	äiºSË†¥‘	&©O¡ijÁHÃÖĞ.²ñ%îèBÒ˜nŒr‘İSB&¼lb8WÌ|éZ¾oÚX ã²rnÄŒ¼Wv,{ü‘½Ùıßÿñ¿Vˆc‹¢ê"R¾a¡©Ü¡áNMv`aVŞo”j6û­éyW¥ïš~·Oõ‹P³ÆÀsğ4êûŠÇOâè¨÷„ÁRr	ŞãQ¤»Â`°†Çš‡|}‰F4ÇuÖBËÒÇÕHdYìÖ"{‹(‘ô•*
¡s÷ Œõ‹êáıˆşÓ?ı ç6Èß ¸úKì®Úº=Ï|a+%¯cµWŠWÆ
ı*.T*…Jí¤²^¯~]ßøšaTm4Ş8gÑø¸Xtå$åb%ÏÑLƒ6ãµ³Óİ«kIˆ¼+ô/ŞÃß§ì[Åİğù{6ƒVPB3Q>GhÃàšÿÂôŒ¬JØÆçï'V4‹Bèğ{ø}³+@yˆ¡ÖÎÍü4péàL›26İS†îĞé™Ó EhªBS]>§‚"ÛÅ)„¼L¾ÈC•O¨jÚ£Ø-¹Ô1¼0´Z¸ı5¥-ì¹HC)Y‘ç‚xmùâ´*z¼
ŒU“TENN®"$f^Ğ+l4Æ*áwQŞƒ†aœ“”Hæ¨Xp»¬çœù¡XÒ6DlóP
{Ó‘6²w½Š„ŠÖ;uÂë§²Ò°H©XÎ‚É½¡lZw‚h`Sê¦¯‰MæŸ&×9ñ£¸¿~Ñå›QÁ‰¡æ`öÈd¶Õ9ËühÎB‘ôy(ôÕÕ}øôâ|r~QKÊNWWÅˆå1Ü‰¯„š£²…´áÊ#”î%—^Å)m•­H=…Gîø\89yL!¼‰– ç”{iñ‹ŞV18 ÎC•')> AÙ¦Ù¥‘èì(.°\´ŸÕ«µ;ÏÀ·¯è“3/üš
`‡qÎ%¾övŠG pW2ˆ¤£¬eŸ\öu4¶ıíÊê¡ìeÙB%	4Q@‰@?©h ’’ñTƒÃOh®Ù>@YÆ«Oæ%~—ÜËØ‹55iS¸…§sì ”@¹Éù·xdµ`a$Ç9
ÜğÄ5¹œ©×¼Ğ—11o‘eßÌÙµ¢P¥·©jR·$—˜ÂJmtzìâ=_XvüŞ&ÆšÎˆkªN8"Ø¯2…ïC©)|£GIwíˆ­ŒfòÎ ,£YÁ2åŸşŠoÊd¹Q*ßÑÙo`–2Ğ)¥ŒoÂôÃÁ‡?µ‹<”ô.p^±§æ¤úÃW<«½;ç®ãã½>½´dÀ(
 )3²`dX>·Ô'GŒë"_ 3p¸ÀTÛ~×RÒY]´X]3’åràPló„ï¢áˆkòx§éM¿A»Ìf9-¦[L)¬Èé•Ã¥€Ga2x
9è¤qQôfnR¤æŸg-í½7Mœ¹jƒFoEx¾9bÆ™oó#}	DIMÑx°çKpXËÿó
äãÄı2¨¡˜øûÔÄ“;l5XTˆë.R¸}UÕ>îŒ;ÃfŒÆ-nfÉ=§ Ü¸/.+1lá	ÂíY~:’Ùb¤? Bpm —Vù¬î °¡8g¥%q¸Ô‘ÖM·Û·|“,i™Ì‹«àÈûª4ä &‹6àKÇıÀSè	¥jŸ\-Zo`G{c2RØ+Ä‡+°ªŠLw*¡F‡ò.Ñ²|àì&^?ë	_Ô×|S®ëL¹®Xí‡ká]ŞÜÖ«®ÄŠx\‹+ûğíf‰‹A@cÙc]wŒç!Öøy´ıª°°Ü&*1äšz‘í1ÌµKè&r·ƒô» õ„¢Ï:¦Z§§®€yÔ‹gNã+¯dêhè¢3ßš\­	—{åÒÄº1ÖÈˆv)àºâÍ#A$¥Ld“ Ô›º§˜É|â·ÄEO¬erÑ‚y12&øX°OÑÌXLĞ›?q«…áZè„&¬Â\îâØíhÙå÷­y"0h#|…åk-‹P%p¸´³()0E0*‹Ô ­+Òò0Ô¶©L!\»j}å‰Ö9€)D&¯1~¿<ÿç`i/„Ÿg
7[HsqD¿µ8A‘C#ˆÙ¡öğ„{xï6iCGŠ7½ãy
Cß?A=¿_€ß“Ô+²G ËgÈ A¼ıBztz‘IôSPæêA2æ±šcjÉ+ëîP#²°v;Wéâx
U/ÍO|T·”åvJ÷ ^®p„Z¹èjjÓnš!é46xÜgDE¶ëğøáÀNCÊMÑ¢êô
wZØŠØEy90?Òusê|•'¨Ú^I5ˆCt¤ÑQàğõ ı'?1¹”š1Y^%J-6!ëí2ñŒPµjâ[c¹nÏ9Z ¼àkÔ˜’Øêûİn!®ì“&F^u’Ñ‚ƒ±K†úzŸªUÓf‘½ô´,+·®©„(èÅì"i”©¬MFr"z8÷JÑ&§š5-dM~¥),èÒ¬+BÇ‚:†tõMH¤8á)F«;ÆL~ãKPi¢N#&ªP»æë¨ÅœÊÌ¶!®ìê€²ä‰N7Ğ)«½FVÉŸ^¹tH¾¡ĞI…8¤?„C8FÃĞ-©±2±q¬ìĞØLoµ¡ĞhÄB-ïkT-¡§¿õŒÉ­Ö'†ªT†)J‘_T ğÎ+Åj¥zÆäJµk§R42œÃª€İ¦Vyhû,©}wªT°BR™ı>Ã&­vZÛ/‰™p?jlázäNˆ»£§—fAOÍ®Št\aÒ ë‡ ”^©²Á+íŞ¸ë—Î†—•j±Z¬kÅ2vg¯m¾kZéišD¥ªÅG!)ÊNr»ƒKåJ?ô>TŠ_Ë'•õõH™ßâ]rÁÎHæ@hVhj®uJµT	°ƒÇ,EBkk!mêŠ §ô«¸Å4‰&M]bgŒîvâ«/Â µ¿ÛÜŞK ñÄÑ†Úw¬åwÃ ıù$ÕJù:Ã#u¬„s.ÑQ	=ÎÇ[}Î}~”4<¥ĞÑ#²ë4ÙNÂ*J–b„CWy£«ÄÉ”™¶"·ÃN& Ô8-òÊÓ+I®¨¶;Îl5Ó"àM¨ğ¿	/…ö,¹vlı5lœ¨ÍŸ:&éÚÉz6Ç`>zóítà„ÀXŠ/(¯«·ahb^¿^H°£ÜôÊßø KW~ı?‹ÊÉ³0	t9ĞÎò¨T[Ñi'p´—çwèğKì¤¨?!ş–¨_«‰‡À!L„Z (+	Phd˜.»+	\Ô41h$ÂWĞÀø1	˜èÅ$Ê‰¼Šöë)‘…+x
Š¶ğŒ€}üÒóR´5Fßxû¸İ	—ıò>ã5p	ùœƒu“ÛH`Õ.ñÊ„¥Dİ±Ş-ŒÜ/Õ7¹AéI¶&£Û_âE>˜hË@¼ckÓğ,X;Š¸qøióñ…MögCÜI©Õ˜xX¢°Ä_{¦şLò /¥J¬I]ÑÅ$“oI$¢ÊğY—{–{Üqì¸\1º¸¥B:?š¸@ÍòS×!Ì`üÛl0…w±3öÀ%0~›´Ê†
Ò& ı!Ü/0pçÍ87˜,ÜtÃáAÂ“	§PÁ¬'ÂrG¶Ä[›Âh§ñÂrR!â7¼·Â“×‘òm’°bÛ7Y%v8)?í\Ï‘f¨-¢Õ¯HÏŠàJÿRp!”	|¼HŸ{™‹H3Ä»WğïøtíÈP!Ã½ÿ¦û~¥ïû#¯^*aÂâ9e*va‰¨&%Ğ:Æ~Jy¥|=“YeïÚÉïïœóB(
 Çì»Ë“!%5Å½ñéĞâ¡{(õåKP(O„Û±º¸[…7Ø‘¬B³6Oê±±MşYĞÍÈ)Sf^cÒÓ©Z,Ù÷ÎøêŠ9§´fÀ3º’ÚŠ(ÂŸ}‹èv———Eƒ ÷¼$ªóJ;Û[í½N» @Ÿƒ~vËó¸Iÿ K”gÆó_ÕÍÚf¹²Yåç¿.Î=ÆƒıO;rcåê˜|ş~?çÿj•Zù)ôÿ:ü·8ÿõ(Ï_üÍ_>ùó'Ov.Ûï°ßË)Óüü©ÂŸ?Â|ÿŸ³lŠŸXâ¿ÃŸ¿dù³0ıoAŞñ˜YÄ3ÑP„Á—:˜Ñø_æ?â¿í¿ÿ?w¯v.Ä'âÏö uLÿ›ÕÍÈø¯m.Æÿã<K¿À}‘ÒrÌšm59ãğrÛ½:Ë= àà¨jóÕ{1ö,—8-ŒÿêŒHQı%ëetåE«“‡2Ã<Çójx™ŒªUõÙûº²Qe¯†ïŸºãóó5ÖõGÓÅã§€6Ú£Šü©«Îğ©9öû+>u|ów$H	e+°É£×¤¹bú_ •U(İîY~P:·bt‹ûO¼¸âĞB¿ĞbBüÀ³šj§±,òÏ¦…>ÖË^
WHéÿFËu2<§ù7ğpÚá#nÁÂ‰æø¦'Q§5½ğFÄãd 9Ãš>Ø\P+Âµ®%…³ |¢Fàr€Íû^‚ÔbßYx4ãª¯•gÅòf±Z®<…æŒaò¾by‚yî(Pxt¨¸Şç‚:W¶o|ä=ğ¦yØxƒwãÌqQ¨Si,sÜ¯_–Ø»H@Ÿ÷lYæìöú=ÖYøå´¡¸†É-”Ú,€¬ÓÄ@{J†n4Cô-%o?1¯’amıaNç4DYÃft5“L†Òğâ‹ ™hDW¥Ô
³ƒšÃ±ÎÚ^NèW³µHÙ”km½ìÒİˆ-8/âPĞş=Ù*S ˆı¯ tI&G,4aŒÌqCVÙğõ+\4ZCî·hCAr\~¼ú±±L?$`AâÛË Àø¥Ğ	öVõº†Lê-­&C¼óâ9‹ÜÃÁ(\Åµ³¯Á¤æ¼Èån/rûßrğu@_³êXÎ*_Ñ$«ÔráH‰ç‚T-œx.H…\A6+À7Æé!,kš)JîîäÜ|¬…ùA h$#b+àN“Ài™zâ# Åù¨±Dÿ>OUB‹ÊoğEŞ>"“ ı;kqg§yÔnl±Œ˜	?QPŠ S±±Œz¬¸
ÌİuÛ0Æ¾dHs|w9€ïIOJ‚æDvã¹U2ş¢!ÙfÕr'd`Ğ„ñ£±,ÏPl£<¹‡KÜ 7oWœLïJq×İ€b¡x·ƒÚê%ˆËi,_X±P‡¾qjL,1)Õ~h,kÆõBAZÖÉ	|ƒD’ÀêFT¡à» ³›@¹ »×ÚcÙ®İ\v	¬›ßå,)©Á–Š‰7~^dà#à04Ü+‰VÏƒlÎ}&Úàb‘°—W(Ğğëí–Ø	:@É¸[}PhÇZiLnEşÌOnÎòO<Øâø¨ö_5Fë<ë˜İş[«®?]gåÊÆFmsaÿy”ç·ÿÚÂşûÿeké^í\<‰Ohÿ}¨Ñ?uüW77cã~-Æÿc<ûïçµÿª£îçigÜ¦Yƒ£¦`ÕGra¾;
?usğLÊÏg€ÃÛO|ó#wt§›TçNˆû™?,¥¸¢Ÿ—”ÿaü’‡›c¦éÿµêf4şûæÆúbşŒ‡ÇÿUùû¢(®°È598wá‡ªø@gÍ`„bbMIì©ë"µI¦™º!Rsÿv«aÁX†{×+µ¯ŸÕ+OkOëëğÔ¿~öõ³…`Ö'9ÌÑ|ë˜6şË±øÿëOãÿ1ZõĞu”o}ÿCec}}áÿùÆ+{è:îÒÿ›‹şŒ'ŒØõpuÌÚÿÕê0À:İÿP^ŒÿGy"Q¤ÛÿÚf¥ºèÿÇxôpSÇìı¿Qİ¬Qÿol,Æÿ£<±pœPÇíÇÿze1ÿ?Î“±s®u”'¯ÿ*åŠğÿ_ßxºQÅşõaÿy”g‰éq‰3Kì•¸4ˆéf÷ØÙØîÒiÏà²Ñ?r†q»Á­UE$Ô×w©ì’K¥j§[”0*üx„AÛÏ]cèe2ü²cü»£ÅÀYP$µW¹9sïx²Á£ƒÉF¯sMˆ ¹r÷±co9v²+å”¸±“/ìfjOrüğùÖqûùfÅùßGyRãÇÏ±)ó?t|¬ÿ7«‹óò,œ>Ûéã'ëå±#DZ4ãıÈ}gáñØ•b¥ü¨‰×˜ xUo0ÁË[&g›LÏ(î;ÁŒ×¤âU¢.ŒzZt’óŞx66èÅ³~„Ÿåò‡ÌÍBñû}’®c™wSæÿÚzlş_útáÿı(Ïbş_Ìÿ³zy‚€øÁ9åş‹ù^AaŞğ.MóÃàŠÀ—ßŠ=À¸qùLqˆoå ‰Ÿ±Uø¯ä±ğ“ÕØ•l¬à³—¯wvğúRøğÈİ;5Šİ>{ş<¸½SfGWÜêó_V2@¾-»ëRĞ:ãó±¼V]«­­¯m¬=½9·÷¶Û»í½£æ—BUaz}<JV«DÉÕYéÜx;‚}îyøs=S®ë›KÓô¿xû¿ë<şß&íÿ-ô¿‡æ6`ÑµWÓĞ¶í3Ğ¹|wL÷ˆ#Ç=ÖáŒ…¢â3jgX;ê1E;%~]%äS´µb’Î¶¦«k³3¢±©™QŞ,-F ~€İ1¢’É<•b¿(Z˜üòtÅğÒêì2~? æí¥õÚ¼+ÀqØõÌ´)v;µ4ÒPE{“å´S9áÕjRj„(¢Š 9búí´ğ4z‡‚	ÈCélôÊÎn¾ÈšüK¼´m»Ìà¸·§A	Ãİğ^§SóïıÓ…Î–_Ì,i¹Å½¿Êå2uí»7î9¬;Šó¿éeE3Å¿¥HmN]‚ÏK&TÜ:ÛEHåñk¡õ=ïÍ½@âÏZKOŸV¿¥[*nœ6qg íŒnÙIè	<G) ‡ëó50=qŒÏò3\GlŠe<–XI¸&L¦så"¬8ôlÍmøâıˆÎ%„c„`xgŞ¡ xŸQ¢È7Şît¸ G62oÛ÷¶éã=Eè§sÓÏ4ñâØh"Ë¼rù}æèjd6ø„Ü¿oˆ‹¬_á l8âÊÙÌ[(ƒ,ÅÑ‹¯K8lÑ­àøîÉÛKJˆá‰Uíf—xîöeKÄvoÍÓçÜêâÎ5æŒî ë”à9#àe÷··?öGc¿\‰öU “!ï‰º¸ænÇß*`5‚œŸ{N¿Í“zôë˜¢ÿ¡»_àÿWİ	÷ÿj‹óò¼kï½ÚŞk¿ÏÒmÏ ¨È¼#"•7@áÿeŞ½jïµ··Şg:í­×‡ÛGßŸ¼>h5Ú“7ÛÍ“İïyØ©ÎëİÒ83Ş|½ÈÏC<©w½Ï±iãRÃñ_£øO7k‹ñÿe_˜6Îß'Ğç±¹“øAdÈàäpr®iŸûÅsß'2şÇ½“àÂ›¹™€¦Ú66ûÏÆ:ÆÿŞ|Z[øÿ<Ê³°ÿ¨öŸ$ş_˜€ÁŞ²7ú¬ğ(Zà#˜’Øàa-@ÉŒ÷F jº‡h&èw4¥Â£LøÙXƒÔØkR< ûí½Vç$¸@¸‘M¾!¸”Õ?•Èµ®İgÊà>ÜÔSèaPŸ[€¤jê™RÒEšxãE]“³¶’lú©š†"çyH•dí"&Ì¥©şßµZÄÿk³¼±ˆÿ÷(ÏÂ_+ŠvÔ_K?Yç­àÂHİuTsRŞl’À¿Ò‚>ı©ztez@Â^·äóÏ‘×àÅqÏ3½n‰ç÷ºxNqÏÛú‘\âõ/0“pˆ]»As§·–»9øçxñHMİÁ–cã­‘¦@>0˜¨S!óÏ·‚ü¹EÓâY<‹gñ,Å³xèùÿşØ6<  