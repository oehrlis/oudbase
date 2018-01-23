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
‹ BgZ í}]sI’˜îìóÅáéì‡sÄÅÅ¹Ä,	.ñÉ¯f ]ˆ€4Üå×”´s¢–×šDn\wƒ‡â†áGûÕoÿ?ø§Ü/pøİ/şÎÌªê®ê $AJ3‹‘„®®ÊÊÊÊÊÊÊÊÊ:µìÒ³G~Êåòæú:£7ø¿åêÿW<¬²Z­nV×*ëëV®TÖ7*ÏØúc#†ÏÈóPñsl>Èvv6æ»hGğïOä9…şwFİh?òŠ^ïêßÿÕµõ*ö¥º¾ºZ^[‡ş_[­l>cåGÀ%öü‰÷ÿÂ/JÈ§†×Ë,°Âì€–ÛîÖXnæ`\ëÒèZk¼^a/Ge›Çšæ¥Ùw†ÓöÙ/Y{4:®Ï–^6Ûy(Ó6ÌsÓ5-ÏwÏ3Yõù
ûº²^e¯û†ïŸº£óóÖ¾²üM·oØİ™#½gÌ"jLpğ±1ò{+>¶}óÌ°Ù¾Ùsû[rL/Ï<J+:”ö_ ØqPºÕµü tnÇğü­aŸ›İ—×œüMÃëV3àåĞ¼´<Ë±cYäí`äÏä^Ï°vÇµ†>óvnÂ?=“Y64Íî˜Œ·sMd³Ó5‘oz›£ô£ÇaÀ¯aÙık6òÌ.;s\fÚ—–ëØÔ©Ğ9=gä³£·ÍTŸï3èV¨õ|èÕJ¥sÈ9:Eê”8Å<qÀâæÌ»ÈÃ¾®rÜë¼–+Åòóbµ\Ù`ŒDalÛ¶|Ëè³KÓE2BJµX©`M™§Ñı¤Ò˜Ñ„_˜Ù±™s†œ->Âà,°-¨ÔX?> öèó#¶ı7Í“Ãıı£“æ^=w£¼Õ
Y`ÿ‡^ÑqÏ³·„@ËîbG†À5aŒŒú>{kôG¦÷€eŞ¶ÛÛû{uèÍLs¿qpĞÚkÖ³G‡oZY6å³ ¼kœöMÖwÎÙ™?ŒáĞÁ°_î·[õì«ÆNûğ€7Na²¦öÖáöÁÑÉ^c·UÏ-!‡Û gX®œÏíœ4·[[Gû‡ß×³%0ÌRâ«í¨=w£e¸-éÅ‹¹\6Ó>j|×j4[‡õ,½¡x2 «¡Ûr7Jí·lé-çpHä»ÍÓ˜e¹ålf·±½Óh6[ívxú7kÀ€,vz™Öááşa½œQ9âá=ÉÁ½Ùdª‡07ÛÑw&ğbo<ãÜ\Ê³›¨lmZŞ°o\ó3®Ù)àBbjJj:»Ş9Ënï½Úg5^ñJ´“ßz—.+Xì[İÛ{À{[­¬Ğdß‚ÑmîÁïøïíWÛ}Ìÿ‚}Hª„±B/‰Ù©r¶äãä0€ÉŞRŠ_&O))Åİ¤âÙ¹ éÇ5‡}«Cr)€Òîğ‘ì{‰ì[c»Ş´\³ƒ“Û5lh›.‘t/!…EÉ’”Ò±nÁR`âSrR¹çœÄLğ7;û¯Q:Üò|Ö{‰•[V8÷Y™}øçw;#›¹Õ7»awÿadù<_î¦zKŸÍ>Ìµ2_Dâ%—/3J?³2·™™Ïu‰Ck—3—Q¾5 …e0|¬¡NT_Êgn¨Û{o`’¬|U[¾MbBz@×5.Lš­{ƒÁ>g§&üÓå´í€¼’¨[P»’! 3‚‚Ìf[ “…í$á»Â`rú$/,›gìh{·u|´{ KÔ–ıÕWß¾¾ê|õ]í«İÚWílş›o”¢‡‡éEí	…ivÒ÷¨wÿwX«Vo6«fXæßµÅ„G2=£€,MhÈÁ·YVgBˆ™UªãòRƒùCœ€peÙ'ß4YÁPÆcPRWãÁÙ`HÉŸ^Ï:óƒ·«{Â«ıàK¸v­Š»¶,D+’8±u‰-NËª´4ŞÚ®c›qÙ4Ãn{ñ"©M_õ“‘œx!Ÿ©N¨±¨è¦l41ÒãGËåhÒÄ— <	ê	‘\Aqd/çƒ9¥+Ì´1íYW%;HTÈŞ‚f²-Ğbt‘½ƒ%ñ93ÎÈ&MÜpÏG¸DöŠ¬ƒkDÓŠ÷ã¢ŞÁ ÷ŠjÕi«€ÙNíùiá¯O„¯j%¤6 ‹¦o;>uª‡Ó-!/oT/‡­V İœ¼l´#„BO¬•ŠQ=é`-Ñ¸4¬>jZ{*•I·œQ¿K|gÔéñ¶K#ûÀô£Ës7ßí{”ŠIÜêÄö¶˜í[|q~3»jùµ‰å[®Btº¤EèÅ'¶†§ŞuG¶ú‹°	uœÁÀ°upÕ{€ëzŠŠuuÔ]ËóH³ŠkÙ*GOÃ[Fº	D5PSpm›\$~íé›¢Õ– ´¼…²"ÁĞ˜m}JzÂ@;ThˆÃ:Ò­
À–G*İÑÄ‘2>K‘â%x+A~* ·lø9à‹,ÿçÏó‘•ÊoÑHveØ¶Á<Ğß{F¿ïhÃô×ÅÎûÂv®lŞô}¯€™¥¡ä6&üuœÍs	jµ‰
5óAÑP9qÈê‹R×¼,Ù£~_<PğaÛ57†KäÃí} ó@ 9I¹ÀçâÂÊ½ÎHÕEfãª‹®¶pŠŸa¶¨¤‹Q¾˜”+®ÒiËÊj%XWYŒeÜ¡â }šqÒÑeŸ>Á—_°B7òYEP«µR†Ú°®$
'Å)²ÜÒJ›pê)İ-0öæ££µqö¤XÏ‰e{FèrhĞƒŸrĞ)¶<İ€ƒÀ‹0ş²>O…Ê Æ•\ú5Œ…Fı‡ıò—ØMW,«Ø´æG¬¤™ GtºTÔ
•µi‡;Rç8á8÷Ï„e9¸]Ãz[á~ß5†,«5l­œÅµt&#¤P]±‚$àDú@r³›É:#Ğªl2§›)YA®{áx;7}gl«—º?œĞÄlØG
˜ÁG»_wˆÒ¬wiÕšµj­š‹Ú^°üàŠ,¤¨Š,ğ%·Ì•¡{™èÃÊ7+Ïv¯UFF6İ? Ò¼Öæª&æãv´”?Èªi,%¯›g‡­ƒí­ÆñcXµò:W&Cùµll•å–Õ‰‚ÖB´ĞÛ‡2#&ã"$ˆmÑ±¨ªón¦¨	˜3;F¿$vë¹”È²œZH	ö‚#Fõ/+ÌÄíì¹_C]=R*˜‰“ LÄ®3¢G°éM?i¤ÑnÅH€y¨QRÂ$O|cDL8ƒ)G=eâ#~BlÆÉŸ`’¸2\—˜'Ê}™€e‘üg­M´öŞf¸WS@îæà]S4ä–“ébŠŒç7­­Æ;GÌ‚%fdKÅ¤lDû‹2xFä,ø¶máÌµLà§kH± ÁĞ§ß®34]ß2=Ä’8Â†4÷ }¬¶‰%62ú.h€`ê:SMÅáØ,úİ¹|­¢e<bˆmÛ€1$³Ñ…?0å|?7ıp?»`±E¯ô‡\©PZTùJıàÀäôÒè\@^¶İä&éÁ¨ï[CÜAD‡ Diß5€]aà›}T£s¥›½o¼Ò±]b¥onS`ƒ8Òü‘«¦ L|bµDøé€OBÚ`ãÛbs¥mº—°ªAÆk«}²të
À¦ÃcYÄÖ£ÙÕêÎK¢ô,K´ºãF/]†•£ê–èàpAÖ2ÍO|!–Á¥Œ…©fã€şj©N.VÀån,±^h¼ûİÉ>î,WlñeëõöŞÍa»=¶Ç°BzE?³ßl¿ŞÛ?lmÁäP¯|Ã4õuÜƒ©°?²Òİ®}PB¹š«bÒñ·‹XËâñ‹»F-åVyr‹7ÒóNùv‹Û7´$¡4½ÇYpÕF] Îë#zg½Óå'wQ¼›*D%©ÎëÓ°2á§YH­zöpü~Ş¼wfÖ;¤à_Ê(‚*`ĞĞÀárFŒbFğzG¿nã™~Bh‰e'ÎSd/Ëìƒßhînï©SOê,ft–=Å4Ÿ»û*uÓš”Ö­‰fë{ôêZUŸøDïrÚ8C!ø“24p<Ô²ßÆ½e%Í/èVòú&ûÅ×÷ĞÔÇ! y}½šÈìwcğêø­ëõªÆºØ>}k:XÎbıXøÜŸú#ı¹×gñÿ]]+“ÿ/üÚ\¯–Ëäÿ[®ÌıŸâ™ûÿ~&ÿß`Àı\ü…¨“¤ÜQ§hïçîúûuş$×ßÊj´ eû®Óêk·À¼‡€¼¡Ù±Î®C?l Â¬wÉgë>üóv©'ğİ€ŸÔ‡÷OÈ…÷	ıu¼…‘àÂsm¿`…ûVéaHšŞe÷!şºÓ;ëÆqŞÉ†Ì¦î”x)¥cÍJïVŸ‰yrñ¹ì“úÈ²¹ìÜG–Í}dç>²sY!"ŸŞvŒWn@óÔ‰oî!;şÜWõ¾ª3òãü^…s¿¾Ÿ™_dmí½­OôâKw äõ¨mîÚ÷ ®±s ¼»_ıVØ£¹èjV­EnzOá£×Nq«@FÅ”[’zÌû	M·^éx¥tÌJçùGóï›‰ÿŞÏŞÅKˆ½Hß&ˆj!¤úŠ-%°ÙÎ¾qšh‰Œa”Y u´%$‡àÀ‚[`×ÄÕ¬¡ïí£Æd(öèÌƒ‚Ÿ]eì‰£ÆËz¼¢„ŒD“í6n^s£K¶ø‡…ÅğÈÑ§ÎÈÌ+09Ôòñ¹Há]ãpıFtM‘'¢ñÚçè§0¥ï`1Ä´Ù8jÜ––ñØDXjdoÑ°!áZJú"¥È X±%Ô”´×¾áNŒD'mVHˆœE‚}ßŠËÇ¥ã%ø;ŒX—s¥ãJi16M]D»Hk{œÎŠ,Í
¾yæ8¶%È.Ç?p‘1Dt—-®,2ø//Ä¾ËO‚Øæ‰sËtP"ğĞïŒ’o	î±- ëíæ3¦oJF–'u‚1ƒ–åGœ!sĞ•NßÃâ¸‰ÅƒÓvJá¶÷9YèC(As! /8ò¤,—† çšgì3åpËò¤OôeôÃqÏ‹nxEüÿŠ°€2‹´åN¼P¡£Ô›×—¡,:Â°×ı‡H£á
óœ‘Û1U­²¨"¯µ;ùY×òÂ
¤¾zİ`N	çÜHd…¡tjù=9%5·u»„†Vz‹1BÓ)÷2åç¯‚oÙ”-·&^Dâ‰ç»¨Ä ï,á0+ÈÜ¢,€î¡ãø\švk(QWªÈä s/¾_;íöEíÃ‡Å|L"	`áHÑ«½UaæusİéƒşÒ…íÕÑ7KKaS@¬r]f±tœ]9Î–b J‹ça¼åu+F ´sƒïLĞÜOr7²3nOÔn¹B¯‚Nï^võéòœ ·İ[±
ÖÚÚßİm ®/DÛ{·%±ĞïÂ`.zçS#èD¾Må17•ƒwšè›¥Òó!*PdXdS¨yÒ4®…Å|ñW_a½¦¥/Lä‘"Œ}FW?¸¿_t¤áód‡¡täİÊ½ãÖÏ\ (ñ¨Hó„Æ¡6¯5-ãóß2Å¡ÜĞç.«“ûê¤ø4  YÁ#«Êşa­¨g©gO³È8á$.‘%—–èÇ¯*y]>$šÏÓ»}zºx£®ìÎ`™}
Œmy=³5¿‡¯YÛ0cu+{ÔOÙü+Fİ)¬(MOÖšİb60–(^Ó¹4vÑYÄÃ3	f6I»#“<}¨ÏyÃ|L/¬•Ëêò?Ö¹„ºpŠØu#}J$È„‰xbª&„Ù,ø¿0Ì§~¤ÿ'2ñhøYü?×W×WÿÏÊê&úV×ÖçşŸOñÌı??“ÿg0à~.şŸ¼AºşŸEø‚ÿçóbySË³kü€»„Dk©(t]¹‹Ğqì3²%Ã{ñÛ ²¥ÏJÓ ı4JËÅÊO6ºì“º•}€-z³³3uƒx£dŸ½ä¢éèzhf~×jÔ×îG ÛNa@@óŞ™æÖÓf@ÖÑu°-äï)ğäGşÃ"ìUß8Ÿ{Ğş”=h}ö-²êÏß—6hhğ(#Œá@Eo•í½­ÃÖnkï¨±3÷É½×~Q>¹ó¸µsŸ\ªcî“;÷Éûä¾$ŸÜ©\rçN¹s§Üû9å
İ.î”;w¦nîL;w¦ıI9ÓÎ:NæèHë×¬Ú Öz7Z– d¦JtF}
'ÛY†µœ{Æ3Î½Fç^£?a¯Q±=7¥×(÷/ùh8—S?Š9>í«>]a±/pv6úhW^•OË$ãëõ"ÃÚ1G}‡­c\™æ³ÉŸÙk½;y×jıno_±¹¼Éæ3û;Íğ¬ÂŒ·…Üî ÜæóTüecëwoNÚ-à<^é	T
…˜VŠ}…K	*ˆîDÀzXÅ¸Â!
	…õ.jÆÚŒDÕ‘0<‘V|;nÍÂ¬8rÏÅÎª€¬bHõ&Í½‡ÙCı8uçÍ/Ö9\Ì#ûÛ€ÑÙÅÀƒÀG!…ª‹î«,8‰œ2c\;Q¸7«"µB¼ñí]lx„t%ù²
xdÇ“;oÂÅT
£[\ÃLÑ†iz6w£ã¢Š}šÒ]TueI}'–ëzxË±Ï¬ó°§ÀX¨)âİÂ
?vÎ¦¡QIõÃå0‹şù|™·µ¿÷Š½Hkõ„¦É ùrÜ»CÛ¢EgÑ8¼Ó„šv¬)7ÔPhZÉèğÈÁ;†U^G]´kÈWô3–Ó4Hİd¢iC«›Fç$*cA­ˆÇñôŞÆéÆ/õœŠ§r(µÜÛ¡x²3qÌæŸÎz‰MÂ_8¢n7F¾ƒWåt(ASºè¦E9ı.úë@ï1Ô5hšOğOn‘É’ÿxBÅU8€†ª}LS—Të4$îFîXÁM™ˆ“wfÒ›±ç¨M8sF ë/™çÅ¸‚”€t>ucGŞñ3#WoŞÜÕûÏçvµı"tş-fÖG©c¼ÿw¹¼VŞ@ÿïÕÊÚêädåÊêÆêæÜÿûI¿ø›¿|öçÏí¶ßf¿—¢	Óıü©ÂŸ?ğşgÿf:££Cş‹Jü?øóï"Yş•HÿëgÏşôğ¢1öÍbßğ|t ÆµüÂA[Àø×ø×³gùFÇÅĞÄ%^Ÿ‡é?DçY‘÷/xŞ¿‹äEæÓ¾¹mwÍÏı‡Â¿ÿGÌı_ÿóù·øoåIíË|´…©ñãmsÇÿVÇÿÚju>şŸâ™Ÿÿø<ç?OüŸòÙnœ¢“¸xNÀ”…'7¢×‰ÎO<Æ)rüHV—C5Nm
!l`àû¸hğ,ìŸ›A(g×é\˜nâ	znú'Õ#t„™ïOA_ùîõ¬	<ã“!í%È‰+víŒ€Û®‰k=ts¹4\w<\ù÷­å¡ó Å¶éBÿ‘CvGC„ y½`ïÔ; ¬‹r×Äı"XW?+CDÖ%}ÅPˆqçÿ@40\sZ6+¢h>ºöQ‘×yÔ›Yı¾¸Ù† Áä'â_ÒudÒ+I­¹d xˆ’oœ“¹»±³s²õ¦}´¿»ıtŸR²P®Ç#-J¡yS©4¡Œb‘Ü8ø#¶u°~}m†æÅÌ§ˆûK£r¹aÉ¡¼¦ô	&´{,@¡ ‡(0¤½A5V‚İ²a¹âÊ"	MÛ.UQöSñ“È”,EFÊ“±A´[*–ÿ“aòŒj¯ oPœ‚“ êD,¬n·o^®©‚~µûN‚¿h,Kğ~ÛxÛPÕàı ÌÌz0b)«tæ	»Òèû¦kCÿ\òãQiu
†7kBNnm»îÉğL¿SŠšÆÇ‚…B†5’\Èƒôãqr‹¶*[<¾¶)Î|Âú6q¿x”3s-eö~ûá]`mÓ—¤D‡¢¢*B(™ĞÉÈ}mw×sÙ9»'#ÄßíÓÎ¼Œ‹’—éÊx©nøFàB¹ÛŒâc‚ƒ¶:q@V†=ÏÎşVc§®ÂàÌ¦yN/À¤ve™0qg".,˜ŠÜD«ãÆ]HBÏE.Õ5sl>ü¡|„.8¼Cºà^€*¹nÑ«.M[…¡;APpBÁÌª¸§7t-`é6rŒ*ıÅ¿çJ¥ÅO= Y%¯4H^!N2å¾xyƒÂUßó‹?à¦!G¸\Doé¸ôşÇ¥¿Êß¬ŞšJvĞ`“q#`ü®rKˆGß²/Ğo*ÙÒÈsK$;SĞF'v&Ğ§Œ’¢“JşCü³ aã’³ÔjÙü­¼¾8œ8É_D ÜÜ>lmí~BşqÀÒ“äÎ4ízFw °:c‹_Û‹yòD¡/ºJJõÍv«%}Î¤ãiÈø¦X–¨ fË®jVz—è[œM	ò)jjÆåRîFoß-ùÑH«ùLÄï¬ı¢}ÿš½ˆÜO=<:ú#	’s¿„:ÊƒÚ;t`ÀßšÍÎˆĞ(	ÿˆ àş›Ã­VwëÄOÚ¯ûÂ}±yçŠİ“ˆW`JùG÷ÔÖpJ:õpœrìãç‚Äuååæ>.rGß¡;à™åz¾Ò‹^zezèšİòåÍ¢oY¡oF|…ÃÙ¨İxÛj pàüçVñ1.„sÅ÷6,BÏ’[Š9ÔÕPKÜÚ?l¡Æ' 4+¾rÿXd%MŞ·¤*ğPOE„äˆ¢Úz4¡ªÈ=)iZ{W<ÔÁÊÔ›(¥¾¬£ƒÚ¯’I*ÁqœÊ&ƒãSşxh<ÓiÊ}h‘¢|v¦x·JRf¦ñpIŠ›o´=ZN¬+ÈÉ‘ÒéYAP¸G<—ïîµü@GdQ+yTZ´‹°äÀÌb†şu8†²1/Ñ¸hä5ø8=9Bºj·š?pÊº8"c®Ò4ßÂâI‡!‰ĞÉ fê%MĞœ%¤‡8IŸNòt{¨³´ÂbÁ$K\¡lĞhÇ…7g~…wbœÒl½j¼Ù9R}mF]ûDŠîÎZU
k“»³hI0gÂ)Ü—à¨á»;ó\¿İ×îËg³æ1â¯GónW'MÃóõ:£ö•Xiü·@`¢\$m‰ò;D2™»5şë¡&º !x°jw~ÊTeuØ§4XmŒ[ï±S&£É‚‚”àT@‰JRóÓ¼(®£ß ;ºÂ/&ÍÊ*ÄÊ­ºÊ™áá·/5TNpîÁÄ-ö7Ñ-9ŠûÕABTYä3>èŞŒ¤~l!ÊêÀ$(£bºñè[Juï_Tİûá‹îËŸ»¸ü§–Çc úĞS$#Õâh¸ø÷èãïè)g–2ÛJM0"Åùª’„9YüCñˆ“½i·O$åœEÉ‰ù *ıkİQ¦KË(Ÿ0ºB$ê¨H
6û²Ïê/	#Jv˜	ù7š‘Ç„aœÛª ø.Î	ÚVR ñd}	Á‰M¬âĞğ{:P>É>Œu£jb([q§©Åü…S}‡¨/åBâçc¥yŸ³±!F˜RqhiSo›Q†WÏ¾Ól°”¤L©ƒU'fmëyEÖ“v{'–½Anì‰Ù)x¬À¡â».ŠÉ‡­ƒhöYôñc„şPòh—ÅªòTf±ÊeÚFß±ÂÖŞUs:c&&•IAÁ°[Ú!Ï /&õÒ¦ıI÷(H9‹š|¦L>³šIøóĞùD‚³Š5i"áÏ§|ä2İéÙÊ3m‰ªùÂQ˜n'75än¬ÛÀĞ¯\„°–¼?°j
•û\ÕŠdtÆ¾*TÊü½UÖğoïØÎ&ttUB¢¦	ßğş&ÀÈ6¿‰Ş·IÕ$/ärVÂÊ>¼@„E§è˜0;ë-
›ãnTİ	‚9[ÎK_€`k“QÏ…Gœ¸*æÆ:"ÔÅT•#9L©+jÓ¿œn×Q7•–º–+“ª“ş˜sFºyÂ°…åV|8í™b6’x9è›h
‘îO}î¥€KÔãûd:Å1õ.m@
"e(]<úÈà:î”c‚Ï—?Ñ€§/·_×Ó¹7¾0‰®j\–ãP{4¾HHZ ß©m‘Ûl±DJ+é—äµËã9¶Mqi¥ô‡\i¸(1¦Š®WèœĞ@gÚt/˜/Ğ~”8Åê•`}ßÑQÈYÖ&&<­Æö#W	Šu¬‘ª>KªŞQV©ËŞÈªkgäòQ˜(ª¤°Â¡K?B‡!Ü~óâFt•ö=¥…-¶m¨p¯¢Ô
Ù5x²·IùENÈSYıúyrÎ)†y7V7RòRßÈŸ÷ëçÜû‹ä‡	«ÄŒ.µÇ¬³•RÑEllÉ«®b—°Jşè26e«”ˆ®c±³§âSL{hdì™ı„e­fb¤,Ò¿_;1c/;I¿Èvë½ e3R­Á¶öŞ>Ì91³*9U€Î‚'ÓyŸÕ½õô‚]2nÃBú,ÒÓ#…âª¼LxvrpHÈé‘ìºûs˜]KŸA™¸c0/¤GòÇ½ƒy~™Éw\çÙ•ôäŠç³VB¦¡Øb¼œÖ”º®ìFkR¤VBISD6*Z$±QQ…0©\Š( YäÁr˜U\ËÊÓ“
€pM‚éIÙAÚ'f‡t-»*ä­¾úÅ½äAˆ·ò‡"ÛkÖ?R9Ğ÷)°z=q`gÀF¹é§=À°(wz$h½,	j¦—U¦é»Ru/,~>É÷”#®Ì+5¢ãS¼Ös§§Síû
‹øO â®(Ÿpy:÷”ä¯†È}×Ö‘Ç¤%,tpÿšìøm›ÛriS›â	=ÑÀJ“Ì,Ù`ÍF…@é¢¼ËŒ}øÀ"ºWcg»„~¤üŠß0n¾{KÅå|}i1ÿ}Êæ‹Ë´ıÎòÊÚnw—<(Sa,- ŒÜ§%%`ò¹Òqµ´˜ åFüµ†¢UJƒ[hmK3±İP£RŒiü­“aÜº2–”Ş'ß×ÇS‹\&¸•j€ü”eÃ\¶+|U¿ª`ÀSiZ.î0R’«ü®á-g0pìàÖzN+ˆ®Ğ ÆÙÎå;4=€uX„éÊˆxÏƒ ê•,äBèbMËƒ.p"+¶Ã†ßé­°iØ8tŸu@.ZÎ¯C@ÑŸ‡Òù»[qî`Ğuä–>fK®I×X)…‰Uoa²bk_ 'øÜ.ÇìÊ„ÿm•l…yK¼ÄÃ&á1>YøÂ,ÇIJÍ­²$¹Õ=ØØ":ÌTÀbKî%¬WiõG)¯¯j>‚‹½í:@ä%è—€|~/$ŸÄC Q
F¬p}ñ,\Ö™€i€ 0,±>÷Láö² SVDÃ6òùÙ.Û±JÊñÊq¯·+úl<çI<°ãÏ·:t%İ¤´ï@Y˜q:l¥(€3OSª.B5³tğ¡…„&	ß5˜×ÇÕä0eôãõÜ(@j]RŠ€£’/%.úìÂB«q¼¥ApJÏYàéìÎåí?L£j¾QæGĞ´<Ü@T¼gÅaÊ>“Øµ³®bŞ y
í]‰G†änh¶y¥©Riá†÷E¸»“öÑá4Û]Áù\ÌKòF­$åztaïœP ª&Ë	…V#…¤=wB±µH1n«œPh]±7&xÔÉ³:	»m7;	EN"ÛaÁ§èáÉ”ãÅ"İÿ„ÄÄízR»ÈF6<’·—²1 ñÒ¬ˆéË4[¢"Ã”s"ã‰YJÜxXĞ<øã+Ò`Ø&¸€Ï¤k5û3!jk"…gİïáfR@¢U¤‘æÕÄtMÙ‚®i[Ğµpm|[ËbøG!f’)ƒÁ¢p¾
'6äw×¼´@èÊáY&h?ÒÆãÅáô‹w#+=á~©Z	—¡Ô“+~tªIóôgAŒH²ã8(Ê<è}’$8·„/Â«ü>ÓNà`=ƒ4›ağÙ¹x†bï³pÜã1™~
U
<y&Ï…§Òä9¬SË®¥îÚŠ
-kŠyTæGÛ°VÂG3C7‰ıZ—B(§Ñ€Ÿ-_=aÂ
NKIH:+ÓóáYF—bà0.Pz 6X“ŠfN0¢ö\8’?:xIóÄjŠÈ/É‘
un­J=Ø6¤ñ|Š}òQjjy~¼t>é¶¸D´t£<¼šŞåÖ™¨©8L×±©ÙeÇ†h7¢¾˜ˆü˜™ÄBI04<ï
mÄCaà©¶Œú˜‡•D*8^u‹şG?é¼ÆÁ»&o?EùØÑŒÄÂ23¶GåÅ3Ş·úEI¸M'>O§ß¶cñïyå˜çKjˆgšĞÕ“#³XÏ2Ÿ;‚ßÃáåó¨uLŠÿŠñ+«Õr¥º¶Y®Tü¨®­>cëŠ•xşÄã?vLÍsx«ƒ÷X\p÷ş_]›÷ÿÓ<]§ó¸ƒÿÙÔı¿ZÙ€ÿÊUèÿÊúÚæ¼ÿŸâÁş?l5š»­â ûHu =6ÖÖÒúµ¼Y­Dúµ¼Z™Çÿ}ŠgÃt)[W—VÀ´{ƒj¨·Ú²/ÿ÷ú´”E«k¸]ëGé6i†}Üã¡½ï`#Œbõ„ŠÖ&¼1¬"»§ÕÏ0ô¥ã§nÆàõ:ÆĞôŠ¬ÑÇ¸¯ç=íP«§Šuè}Ü³¿ÂŸbó°’ımÍëÁ[®º_8o˜÷ )şˆ‡v\aWôã„Ú&¬fŞ w’¨Å}Èİ¥ë4İ”Çá‘TƒË’ø\l´FÇo¼2Úë›	ü©‹gu¡Æ¾C±lÛ3ôW×ÔÈØ”dÔèL“öî
;ll­P¦×#è0‚=p\¹|½êY¢`…aNqmˆ.XcÓ"Ãà½k*(f2Ë’i–±8`€7’ô¯¹ƒ vÓòrÈtyYe…ÇYÕ"hŠÈ³Äìtdwhã\,‡‹è4\î{¾;ê ˆò4İ©eÃÒÈ„“Ô§Ğ´	µ`¤ak`õÙø
wt!iD7F¹Èî*!^50œ+f¾r-ß7m,€qY¹·bFŞ+;–=úÈŞîşïÿøß +Ä±IQu)ß°€ĞTîĞğ†§¦;°0+ï7Jµ›ıÖô¼ëRÛwM¿Ó£úE¨Y£ï9xOu}Íã'qtÔ{Â`)¹€ïÑ0Ò]a0XÃcGC¾¾D#šÇã:k¡eéãr$²,vk‘½Ã”HúJ…Ğ¹{ÆúˆEõğşDÿéŸş‰säo \í%öWm®g~Àˆ°•’×ƒ±Ú-Å+c…^*•Beõ¤²V«~][ÿšaTm4Ş8gÑø¸Xté­$åb%ÏÑLƒ6åµ³cÓİ«+Iˆ¼/ô.?Àß§ì[ÅİğÅ6ƒVPB3Q¾@hƒàšÿÂô—Œ¬JØÆÆV4‹Bèğ{ø}³K@y€¡ÖÎÍü$p—éàL›26İS†îÀéš“ EhªBS]>§‚"ÛÅ)„¼L¾ÈC•©jÒ£Ø-¹Ô1¼0´Z¸ı5¡-ì¹HC)Y’ç‚xmùâ¤*º¼
ŒU“TENN®"$f^Ğ+l4Æ*áwQ>€†aœ“”Hæ¨Xp»¬çœù¡XÒ6DlóP
{“‘6²w½Š„ŠÖ;uÂë'²Ò°H©XÎ‚É½¡lXw‚h`ê¦¯‰MæŸÆ×9ö£¸¿~Ñå›QÁ‰¡æ`öÈd¶Õ9ËühÎB‘ôy(ôåå}øôâ|r~QKÊN——Åˆå1Ü‰¯…š£²…´áÊ#”î&—^Æ)m™-I=…Gîø\:}9yL!¼‰– ç”{iñ‹ŞV18 ÎC•')> AÙ¦ÙK¥‘èì(.°\´Ÿ×ª«÷ï^Ñ='g^øÀâö+|ìí@á®dIGX=Ê>¹ì›hlû»•ÕCÙË²)„Jh¢€~\Ñ@$%ã©‡Ó\5²}€²ŒWŸÌKü.¹Wÿ°kj:Ó¦pÿNçØA(r“óoñÈjÁÂHs¸á‰k
r9U¯	x¡.5cbŞ!;Ê¾©³k=D¡JïRÕ¸nI.1•ZèôØÁz¾>°ìø½MŒ5×TpD°_e
ß‡RSøF’"îÚ[ÍäAXF³‚e0Ê?ıß6”Ér£T¾£³_ß:-e SJß„é‡ƒjy(éà¼bWÍIõ‡¯x8V{wÎ]ÇÇ{}ºiÉ€Q RfhÁÈ°|:n©O×F¾@gàp©¶ı"®¥¤³ºh°:f$ËUß;¡Øæ	ßEÃ×äñNÓ›~-‚v™ÍrZL·˜PX‘ÓK†K%Ãd22ğ:2rĞIã¢èÍ Ü¤HÍ?O%ZZ{M<oš87rÕ ŞŠ$0ğ|sÈŒ3ßæ%Fúˆ’š¢ñ` Î—à°–ÿ-æÈÇˆûePC1ñ÷©‰'wØr°¨×]¤pû²ª}<4w†M[8ÜL’{FA¹q_\VbØÂ„Û³2üt$Õ³Å H@…àÚ .­òYİ;A;a;EqÎ:âp©"­n§gù&YÒ2™—×Á‘÷eiÈAMmÀW{ÁSè	¥jŸ\-Zo`Gy#2RØ+Ä‡+°ªŠLw*¡F‡òÑ²|àì¯Ÿõ„¯êk¾)×u¦\×õ­‹DûáJx—7·õª+±"×âÊ>|F»YâbĞXôXÇáyˆ~Şm¿*,l#·‰J¹¦^dûAsíÒº€‰ÜmF ı.i=¡èói Öé©ë`õâ™ÓøÊ+™:ºèÌ·"—g+ÂeÃÃ^¹2±NŒ52â€]¸‡®xóHI)Ù$õæ„î)f2Ÿø-q‘çkš\´`^L€Œ	>ìS43ôæOÜê@ÆGa¸ú¡	«0—»8vCûZvù}kÚ_aùZ‹Ã"T	.í,
D
LŒÊ"5HDëŠ´<µ­c*“D×®ZŸ†‡Fyg¢uC`
‘€É+Œß/Ïã9XÚáç™ÂÍÒœBÑÀo-NP¤ÅÀbv¨=<æÅ»MÚĞQ†âMïxÂĞ÷OĞBÏïà÷$u‹lÇÈò2@o¿G£^dı”¹zŒy¬æ˜‡Z2ÁÂŠçº?”Áˆl#l€İÎUº8BÕK@óÕMeù‚„Ò=¨—+á€V.ºšØÅ´›&Cˆc:÷™Q‘í:<~8°Ó€²C“†´¨:½Æ¶$vQ^õÍtİœ:_å	ª¶WCÒEâit8|=@ãñOL.¥fL–W‰R‹Éz·L<#T­šøVX®ÓuNƒ(/ø5¦$¶:Á¾G·[ˆ+û¤‰‘Wd´à`ì’¡¾>¤jÕ´Ydoı-ËÊ­k*!Šz1»He*+ã‘‹Î½R´É©€æEMYQ£_i
º4ëJ…Ğ± ]}C)NxŠÑêŒp“ßøTš¨Óˆ‰*Ô.‚ù:j1'¤2³íGˆ+»: ,y¢ÇõuÊj¯‘ÕArÇÇ§Wn$’oè´CR!éáPÑp tKAj¬L[l+;46Ó[-E(4±PKÃû
UKè)Æo=cr«õ‰!D€*•aJ Rä ¼óJñƒZ©1¹RíZÄ‰ç°*`·‰UAÚ>Kjß½*¬TfG¿‡Ï°I«…æö+b&ÜY¸§¹âşè)Æ¥iĞS³«"W˜4Àz! å…WªlğÀJ»;êø¥³ÁU¥Z¬+ÅÕb;‚‹³76ß5­t4GM¢RÕâ*G!)ÊNr»ƒKåJ?t/*Å¯‹å“ÊÚZ¤Ìoñ.¹àFg$s G4+45×:¥†Zª„NØA‹c–"¡µµ6uEĞúUÜbšÄã¦.±3Fw;ñÕaĞÜßmlï%ĞxìhCí;Öòûaş|’j¥|â‘:VÂ9—èÆ¨„g€ã­g?JRèèÙušl'á %K1Â¡£¼ÆÑUâdÊL[‘ÛaÇ jHœyåıÉ•ƒ$WTÛgºšiğ6Tøß†—B{–\;¶‰ş6
NÔæOK“tíd=›c0½ùn:pB`,Å×ÕÛ041¯_/¤ØQnú
eo\ÀÒ•_ÿÃÏ¢r@ò,L]´³<ê ÕVtÚ	­Çåù:ü;i#êOˆ¿%ê×jâ!0ÃFS¡ ŠFçJ&ƒ‹ÄîJ5ML‰ğ•40~Œ&z1‰r"¯¢½ÇzJdáãJÂ¢-<#`Ÿ~ t½mÑ7Ş>nwÂe¿¼ÏxEcœFB>ç`İä6XµKE¼2a)QEw¬÷B#÷KõMnEz’­Éèôâ—x‘&Ú2ïØÚÇ4<Öân~Ú<E|a“ıÙwRj5&–(l ñ7©'“<ÀK©kRWt1ÉäF‰¨2üFÖå.Bå^÷A;.WŒn©ÎÏ&®ÀPsJ üÔu3…ÿ6Lá]ìŒ|0†DIŒß¦­²¡‚ôÅ¤/ÂıwŞŒs³€ÉÂM7$\p18™øQ
EüÁz"< wdK¼µ)ŒvŠ/-'"~Ã{+<yi ßÆ	+¶íy#Ub‡“òÓÎåéèi†Ú"Zızˆñ¬~ ©ô/B™ÀÇ‹ô¹—¹ˆT0C¼ÿNÑ2Üû¿0İK=ßzµR	CÏ)S±ãJ4(@5)Ö1òTÊ+åk™Ì2{ßúH~ç˜BQ 8fÏí[t)ñ¬y,îNİC©w(_‚By"ÜÕÁİ*¼ÁdšµyR—lòÏ‚~hAN™2ó
“NÕb¹È¾wFÀW×Ì9¥½0¦˜áµÔVDføì[D°»ºº*°è¸ç%QWÚÙŞjíµ[ úô³;ÿÀMúG9X¢<Sÿªn®n–+›üü×ÆÆüü×S<Øÿ´c 7V¡ñç¿à÷†8ÿ·º^Y-o@ÿ¯Áóó_OòüÅßüå³?öl×è°ı6û½œR0íÙ_ÁŸ*üù#üÁ÷ÿ9ÈÆÑÑ¡ø‰%ş;üùëH–?Óÿäm€™E¼0Eüqá ÿeş#şÛúûÿówjçüI|"şlRÇ„ñ¿Y]ßŒŒÿÕÍùøšgá¸/Rº Ç¬éV“S> /·İ­±Ü# ª6^¯°—#Ï²q‰ÓÄø¯ÎÕ_²¶PF—^6Ûy(Ó6Ìs<¯†—Éx ZUŸ¯°¯+ëUöºoøş©;:?_amĞX4]<~úh£=ªÈŸšêÌ Ÿ#¿ç¸âSÛ7ÏpG‚”P¶ë<zıAZ‘+¦¿ñPY…Ò­®å¥s; F·¸ÿÄËkŞMô-&dÀ<Ë¡yi¡vË"?ğlZècİ¹ì•p…”şo´\'Ãsš§>rá,|hozuZÓoD<Nš3¬éƒÍµ"\{àZR8À'jäğ .çØ¬ïé%x@-ö…G3®kğZy^,o«åÊ4d“÷ËÌ3GÂÛ` CÅõô!\àĞ¹¶}ã#ï·Ãú[¼gæˆËˆBíJ}ñxô›ã^íøªÄŞGú|`‹2g§Û«ë±ÎÂ/§uÅu4Lîk¡Ô¦d&ÚS2t¢¢wh)y{‰y•ıt`hës:§!ÊF0£«Á˜d2”®‡_ÉD#ºº(¥V˜Ô¼uÚörB¿®EÊ¦\sû0è½`—îVlÁy±‡
€ÖïÉV™@ìÅ  K29b¡	chşˆ²Êöˆ€¯_á¢Ñ2r¸u@
úã‚ôãõõEúY ß^|Æ/…N°·ª×5dRoiÍ0âÏYäîFá*®Í`x&E0ç…p@.vº‘Ûÿƒ¯}úšUÇrVùŠ ñX¥–GJ<¤j¹pàÄsA*ä
²Y¾1NaYıÔLÁpPrwÆçæc-ÌA#[wšNË¤Ğ#)Î‡õÅ úgèôxªZT~ƒ/òö™íßÁX‹;;£V}‹õa¤ÀLø‰‚R™ŠõEüĞeÅe`îÓwÜº1ò C2˜Óà»Ëô}7HòxR4¯/²ÃÏ-“ñÉ6«–ƒ<!ƒ> ŒoõEi|†bëåñ=\âù°¸y·âdzWŠ»æğn cxÅ»ŒĞV/A\ZN}ñÒŠ…:ôÓ€T#b‰ÑP©ö¢¾¨×iYg$'ğI«Q…‚ï‚Ìnôåìnse;v=tpÙ%°nV|—;°¤¤[X*&Şhğy‘€ÃÀp¯%Z]Fd°9÷™hƒ;|ˆEÂ^^¡@[Ào¶›b/X$è %?ànõ	@¡k¥1¹%ù3?¾9‹?ñ`‹_à£ÚÕ­³¬czûïjumc•+ëë«›sûÏ“<_¸ı×ößÿû/[jçüI|Bûïcş‰ã¿º¹ÿğk>şŸâ™Û?¯ıWu?O3°8ã6É5«>’ssğıQø©›ƒ§2P~>Ş~â›¹£;İ¤:sB<ÌÌ€øa)Åı¼¤üã—<Ş3Iÿ_­nFã¿o®¯Íçÿ§xxü_å˜?°/Šâ
‹\“ƒs~¨ŠtÖü F(&®*‰í uM¤6È4 S×Eê¡bNàßî4,Ëp/âZeõëçµÊÆêFmÚ×Ï¿~>·Lû$‡9šm“Æ9ÿm}}c>şŸâÁ U]GùÎ÷?TÖ×ÖæşŸOñ`¼²Ç®ã>ı¿>¿ÿáI0b×ãÕ1mÿW«ëÀ ktÿCy>şŸä‰D	|”:î>şW7+Õyÿ?Å£‡k|œ:¦ïÿõêæ*õÿúú|ü?ÉÇùuÜ}ü¯UæóÿÓ<);gZGyüú¯R®ÿÿµõõ*ö?¨ÿsûÏ“<LKœY`¯Åı£AL7»ËÎFv‡N{—ş‘3ŒÛ	níü«b˜("¡¾ñ¸Ke‡\*Us<İ¢„QáGCÚ~î/“á—ãßµÅ¸(Î‚"¬½ÊÕÈ™Ç“îL6zkBØÈ•»wˆ{·È±ã])'Ä_xn7ûS{’ã‡Ï¶»Ïÿ0ÌÏÿ>É“?~†uL˜ÿ¡ãcı¿YŸÿ{’gîôñÔN?Y/) Ò¢ïGî;ˆ8kˆ§ö¸¨+å'õ¸H¼ÆÅ«zƒ	^Ş2>£¸ØdrFqß	f¼!ı¯ualĞËÀ¢ëœzãX_§Ïú~–Ë™Û¹â÷'ú$]Ç2ë:&Ìÿ«k±ùmccîÿı$Ï|şŸÏÿÓzy‚€øÁ9åşóù^AaÖğ®Ló¢ÍÎFı¾àËoÅîcÜ8Š|¦8ÄÎ¶rÄÏÙ2üWò‰XøÉêGìJ6VğÙ«7;;x})|øäîÅN½xÜŞ)³£+nõÅ/+™G _×À@–İq)hñùˆX^©®¬®¬­¬¯lÜ‹œÛ{[‡­İÖŞQãK¡ª0½>%«U¢äò´ôî¼Á>÷<ü¹	×õÍ¤Iúß:¼ˆıß5ÿo“öÿæúßã?3°èÚ«ihÛöè\¾;¢‹{Ä‘ã.ksÆBQñµ3¬õ˜‚¢‚¿®ò)ÚZ1Ig[ÑÕ5ŒÙÑØTL‚(oC?Àî˜GQÉdJ±Œ_-L~y:bxi¶w¿ ó¿ñ€ÒzmŞ5à8èø}fÚ»Zi¨¢½ÉrÚ©œğj5)5BQE—	€1ıö	Zx½MÁä¡t¶ze{7_d~ƒ%^Ú¶ÂÎ]fpÜÛÓ „áî‡x¯Ó©y†÷~èBgË/f´ÜâŞ_år™šöİuÖÆù€ßtÎ²¢™âßR¤‚§.Áç%*Hîí"¤òø5Ğú®‰÷æ^"ñ§­¥+ŠOª†ßÒ­@7N›¸S€v†w‡ì$ô¡Ãõø˜8Ægù9®#6Å2K¬$\“&Ó9‰rVz¶F—6|ñ~Dç
OÂ0B°?C¼3ïQ |È(QäëïvÚ\È#™w†í{uÛôñÏ"ôÓ¹égxql4‘eŞ¹ü!st=4ëüFÂîß×ÅEÖ¯q Öqålæ‡AŒâèÅ×%¶èVğ|÷äí%%ÄğDˆªÖG³C<w÷²%b»wæésnupçšs†÷€uJğœ¡
ğ²»†ÛİùÃ‘_®Dû*ĞIˆD]\s×£¾o°AÎÏ=§ßåI½z†uLĞÿĞİ/ğÿ«‚î„û«óóOò¼oí½ŞŞk}ÈÒmÏ ¨È¼#"•×AáÿeŞ¿níµ··>dÚ­­7‡ÛGßŸ¼9h6Zí“·Û“İïyØ©ö›İR?3úŞl½ÈæÏc<©w½Ï°IãRÃñ¿Jñ66Wçãÿ)Ë¾4mœ¿O Ïcs'ñƒÈÁÉáä\Ó>7öóç¡Odüº'Á…733M´ÿ¬oöŸõ5Œÿ½¹±:÷ÿy’gnÿQí?Iü?7=	(¼e+nôY	àQ´À'0ÿ$±ÁãZ€’ï1Œ@SÔô ;ĞTĞïi
J…=C™ğ³±©±;×¤x Ô÷Z{ÍöIpp=›|Cp)«*‘k];]Ï”Á}¸©§ĞÅ >ÿ<² IÕÔ3¡¤3Œ<4ñÆŠº&gm	$Ù2ôS5EÎÿò*'ÈÚEL˜Iı¿WW#ş_›åõyü¿'yæşZQ´£şZÚxøÉ:o5'Fê®[ š“òf3şµôéOÕ£+Óv;u Ÿ|¸/{évj,HÌ8§¸§ĞéÃpŠ{nØÖä¯™„CìØuš;½•$ØÈÁ?Ç‹Gjêô·o4İ òéÀD
™¾äÏ-šæÏü™?ógşÌŸùóHÏÿD]µ¸  