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
‹ V&gZ í}]sI’˜îìóÅáéì‡sÄÅÅ¹Ä,	.ñÉ¯f ]ˆ€4Üå×”´s¢–×šDn\wƒ‡â†áGûÕoÿ?ø§Ü/pøİ/şÎÌªê®ê $AJ3‹‘„®®ÊÊÊÊÊÊÊÊÊ:µìÒ³G~Êåòæú:£7ø¿åêÿW<¬²Z­nV×*ëëV®TÖ7*ÏØúc#†ÏÈóPñsl>Èvv6æ»hGğïOä9…şwFİh?òŠ^ïêßÿÕµõ*ö¥º¾ºZ^[‡ş_[­l>cåGÀ%öü‰÷ÿÂ/JÈ§†×Ë,°Âì€–ÛîÖXnæ`\ëÒèZk¼^a/Ge›Çšæ¥Ùw†ÓöÙ/Y{4:®Ï–^6Ûy(Ó6ÌsÓ5-ÏwÏ3Yõù
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
mÄCaà©¶Œú˜‡•D*8^u‹şG?é¼ÆÁ»&o?EùØÑŒÄÂ23¶GåÅ3Ş·úEI¸M'>O§ß¶cñïyå˜çKjˆgšĞÕ“#³XÏ2Ÿ;‚ßÃáåó¨uLŠÿŠñ+«Õr¥º¶Y®Tü¨®­>cëŠ•xşÄã?vLÍsx«ƒ÷X\p÷ş_]›÷ÿÓ<]§ó¸ƒÿÙÔı¿ZÙ€?ÕèÿÊúú¼ÿŸäÁş?l5š»­â ûHu =6ÖÖÒúµ¼Y­Dúµ¼º>ÿûÏ-†éR¶ ®.­€i÷ÕPnµe_şïÿô?h)ŠV×p»ÖÒmÒû¸ÇC{ßÁFÅê	7­M8xcXE:wO«ŸaèKÇOİ0ŒÁëuŒ¡éY£q_Ï{Ú¡VNëĞ4ú¸g„?Åæa%ûÛš×ƒ·"\/t¿p&Ş0ïASüí¸Â®è;Æ	µM<XÍ¼î$Q‹û»K×1hº)Ã)"©—%ñ¸Ø.h-Şxe "´Ö7?øSÏêB}‡b-Ø(¶g&è¯®©‘±)É¨Ñ™6&íİvØØZ¡L¯GĞa{à¸rùzÕ³:=DÁ
ÃœâÚ-\°Æ¦E†Á{×TQÌd–%Ó,cqÀ o$é_sAì¦åå éò² Ë
³ªEĞ‘g‰ØéÈîĞÆ¹X)Ği¸Ü÷|wÔA	äiºSË†¥‘	&©O¡ijÁHÃÖÀê.²ñîèBÒˆnŒr‘İUB&¼j`8WÌ|åZ¾oÚX ã²rnÄŒ¼Wv,{ô‘½İıßÿñ¿Vˆc“¢ê"R¾a¡©Ü¡áOMv`aVŞo”j6û­éy×¥¶ïš~§Gõ‹P³Fßsğ4êûšÇOâè¨÷„ÁRrŞ£a¤»Â`°†Ç‡|}‰F4ÇuÖBËÒÇåHdYìÖ"{‡(‘ô•*
¡s÷ Œõ!‹êáıˆşÓ?ı ç6Èß ¸ÚKì=®Ú:]Ïü€a+%¯cµ[ŠWÆ
½*.T*…ÊêIe­Vıº¶ş5<<Â¨Úh¼qÎ¢ñq±èÒ[!HÊÅJ£™mÊkgÇ¦»WW’y_è]~€¿OÙ·Š»á‹l,<%¬ „f¢|ĞÁ74ÿ…é/Y;”°/>Œ­h…Ğá+öğûf—(€ò C­›ùIà.ÓÁ™6dlº§İÓ5'A‹ĞT…¦º|NE¶‹S	y™|‘‡*SÕ¤G±[r©cxahµpûkB[Ùs‘†0S²$Ï3ñÚòÅIUty«&©
Šœœ\EHÌ¼ WØhŒUÂï¢| Ã8')‘ÌQ±àvYÏ9ó1B±¤mˆØæ¡ö&"md1îz	­;wê„×<Odÿ¤a+(R±œ“{C	Ø<±îÑÀ&ÔM!^›Ì?¯sìGq;ü¢Ë7£‚CÍÁì‘Él«s–ùÑ …"éóPèËËû"ğè#Äøåü¢
–"”+œ./‹Ëc¸^5G!2diÃ•G(İM.½ŒSÚ2[’z
Ü#ğ¹tú sò˜Bx-Î)÷Òâ½9"¬bp œ‡*OR|@ƒ(²L³—(J#ÑÙQ\`¹h/>¯UWï=ß½¢{NÎ¼ğ*€
Äí;WøØÛ)Â]É ’°z,”}rÙ7ÑØöw+«‡²—eS•$ĞD%ı¸¢HJÆS?¦¹jdû e¯>™—ø]r¯şa/ÖÔt¦MáşÎ±ƒPå&çßâ‘Õ‚…‘ç(pÃ×ärª^ğB\jÆÄ¼Cv”}Sg×zˆB•Ş¥ªqİ’\b+µĞé±ƒ;ô|}`Ùñ{šk:#®©:áˆ`¿Ê¾¥¦ğ%EÜµ#¶:2šÉ;ƒ°ŒfË`”ú+¾m(“åF©|Gg¿¾uZÊ@§”2¾	ÓşÔ.òPÒ;ÀyÅ®š“ê_ñp¬öîœ»÷útÓ’£( ¤ÌĞ‚‘aùtÜ6RŸ1®7Œ|ÎÀáSm'úE\KIguÑ6`uÌH–«¾wB±Í¾‹†#®Éã¦7ıZí2›%ä´˜n1¡°"§—"—J5†Éddàu*dä “ÆEÑ›A¸IšJ´´öšxŞ4qnäªA¼I`àùæg¾ÌK8Œô5> $%5Eã=À2@œ/Áa-ÿ[Ì+6÷Ë †bâïSOî°å`Q!®»HáöeUûxh0î›2·p¸™2$÷Œ‚rã¾¸¬Ä°…'·geøé Hªg‹Aş€
Áµ\Zå³ºw‚vÂvŠâœuÄàRDZ7ÜNÏòM²¤e2/¯ƒ#ïËÒƒš,Ú€¯÷‚/¦ĞJÕ>¹Z*´ŞÀ8òFd¤°WˆW`U™îTB	Œå:¢eùÀÙ&^?ë	_Ô×|S®ëL¹®ë[‰öÃ•ğ.onëUWbE<®Å•}øŒv³ÄÅ  ±è±;Âó+ü¼Ú~UXØFn•rM½ÈöƒæÚ¥?t¹ÛŒ@ú]ÒzBÑçÓ@­ÓS×À<êÅ3§ñ•W2u4tÑ™oE.ÏV„Ë†‡½rebkdÄ»p]ñæ‘ ’R&²IêÍ	İSÌd>ñ[â"Ï'Ö4¹hÁ¼˜ |,Ø§h
f,&èÍŸ¸ÕŒÂp-ôBVa.wqì†ö´ìòûÖ<´¾Âòµ‡E¨8\ÚYˆ˜"•EjˆÖiyj[ÇT&‰®]µ>òÎDë†À"“W¿_ÿÆs°´ÂÏ3…›-¤9	„8¢ßZœ H‹ÄìP{xÌ=<Šw›´¡£Å›Şñ<…¡ïŸ …ß/ÀïIêÙ#å3d€ Ş~!=:G½È$ú)(sõ óXÍ1µd‚…Ïu(ƒÙF
Ø »«tq<…ª—€æ'>ª›Êò;¥{P/W8Â­\t5±‹i7M†Çt<î3¢"Ûuxüp`§e‡&iQuz;-lIì¢¼ê›éº9u¾ÊTm¯†¤‹Ä!:Òè(pøz€şÆãŸ˜\JÍ˜,¯¥“õn™xF¨Z5ñ­°\§ëœ-P^ğ5jLIlu‚}n·WöI#¯:ÉhÁÁØ%C}}HÕªi³ÈŞúZ–•[×TBôbv‘4ÊTVÆ#9=œ{¥h“SÍ‹š²¢F¿ÒtiÖ•
¡cAºú†&$Rœğ£Õá&¿ñ%¨4Q§U¨]óuÔbNHefÛWvu@YòD'ëë”Õ^#«ƒäO¯ÜH:$ßĞh‡¤BÒÂ¡£á@è–‚ÔX™¶Ø8Vvhl¦·ZŠPh4b¡–†÷ª–ĞSŒßzÆäVëCˆ U*Ã”@¥È/* xç•âµR=cr¥Úµˆ)ÎaUÀn«‚<´}–Ô¾{U*X!©Ì~Ÿa“V;ÍíWÄL¸5²pO=r'ÄıÑSŒKÓ §fWE:®0i€õB Ê¯TÙà•vwÔñKgƒ«JµX-VŠ«Å2vgol¾kZéišD¥ªÅUBR”äv—Ê•~è^TŠ_Ë'•µµH™ßâ]rÁÎHæ@hVhj®uJµT	°ƒÇ,EBkk!mêŠ 'ô«¸Å4‰ÆM]bgŒîvâ«/Â ¹¿ÛØŞK ñØÑ†Úw¬å÷Ã ıù$ÕJù:Å#u¬„s.ÑQ	=ÎÇ[=Î=~”4<¥ĞÑ#²ë4ÙNÂ*J–b„CGy£«ÄÉ”™¶"·Ã' Ô8-òÊû“+I®¨¶;Ît5Ó"àm¨ğ¿/…ö,¹vlı5lœ¨ÍŸ:—&éÚÉz6Ç`6zóİtà„ÀXŠ/(¯«·ahb^¿^H°£ÜôÊß¸€¥+¿ş‡ŸEå€äY˜ºhgyÔª­è´8ZËó;tø%vÒFÔŸKÔ¯ÕÄC`†¦B- Î•(42L‰İ•.jš˜4á+	h`üLôbåD^E{õ”ÈÂÇ•<…E[xFÀ>ı@éz)Ú£o¼}Üî„Ë~yŸñŠÆ8„|ÎÁºÉm$°j—ŠxeÂR¢ŠîXï…Fî—ê›Ü Šô$[“ÑéÅ/ñ"L´e Ş±µix¬ÅÜ8ü´yŠøÂ&û³!î¤ÔjL<,QØ âo<SÿN&y€—R%Ö¤®èb’É7Œ$Qeø¬Ë]„Ë½>îƒ8v\®ÜR!ŸM\ æ”@ù©ëf
0şm:˜Â»Øù
`‰’¿MZeCé‹1H_„ûî¼çf“…›n8<H¸àb"p2!ğ£Š ø‚õDx@îÈ–xkSí!^ZN*Dü†÷Vxò:Ò@¾VlÛóF «Ä'å§ËÓÑ9ÒµE´úõ	âYü Ré_
.„2és/s©`†xÿş.¢*d¸÷aº–z¾?ôj¥† ,S¦bÇ”hP€jR­cä¨”WÊ×2™eö¾õ‘üşÎ90/„¢ pÌÛ·<éRâYóXÜ,º‡RïP¾…òD¸«ƒ»UxƒÉ*4kó¤.ÙäŸıĞ‚œ2eæ&=ªÅr‘}ïŒ€¯®™sJ{aL1Ãk©­ˆ"ÌğÙ·ˆ`wuuU4`ÑqÏK¢:¯´³½ÕÚk·
 ôègw<ÿ›ôr°Dy¦<ÿUİ\İ,W6«tşkcc~şë)ìÚ1+PÇøó_ğ{Cœÿ[]¯¬–ñü×ü7?ÿõ$Ï_üÍ_>ûógÏvÛo³ßË)Óıü©ÂŸ?Â|ÿŸÓlŠŸXâ¿ÃŸ¿dù³0ıoAŞñ˜YÄ3ÑP„ÁÚ˜Ñø_æ?â¿­¿ÿ?÷ vÎŸÄ'âÏö(uLÿ›ÕõÍÈø_İœÿ§y~û"¥rÌšn59åğrÛİË=àà¨jãõ
{9ò,—8MŒÿêIQı%ketée³‡2mÃ<Çójx™ŒªUõù
ûº²^e¯û†ïŸº£óóÖõGÓÅã§€6Ú£Šü©©Îğ©1ò{+>µ}ów$H	eK°É£×¤¹bú_ •U(İêZ~P:·bt‹ûO¼¼æĞD¿ĞbBüÀ³š—j§±,òÏ¦…>ÖË^	WHéÿFËu2<§ù7ğpÚá#nÁÂ‰æø¦'Q§5½ğFÄãd 9Ãš>Ø\P+Âµ®%…³ |¢Fàr€Íú^‚ÔbßYx4ãº¯•çÅòf±Z®l@ó@Æ0y_±<Á<s(¼:T\OrÁkÛ7>òxÛ8¬¿Å»qf¸Œ(Ô®ÔG¿9îÕ¯Jì}$ Ï¶(svº½ºë,ürZW\GÃä¾Jm@Öib =%C'š!z‡–’·—˜WÉĞO†¶ş0§s¢¬a3ºŒI&CézxñEL4¢«‹Rj…ÙAÍ‹áX§m/'ôëéZ¤lÊ5·ƒŞvénÅœq¨ hıl•) ÄşW º$“#š0†æ¸!«løú.-ƒ!÷€[´¡ 9.H?^ÿX_¤Ÿ° ñíÅG`üRè{«z]C&õ–Ö“!ŞyñœEîÎá`®âÚÙ†×`Rs^äb§¹ıo1øÚ§¯Yu,g•¯è ÏUj¹p¤ÄsAª–N<¤B® ›àãô–ÕOÍ%wg|n>ÖÂü 4’±p§Ià´L
=ñâ|X_¢‰N§*¡Eå7ø"o‘IĞşŒµ¸³Ó8jÕ·XF
Ì„Ÿ((E©X_Ä]V\æî8}Ç­#ß	2$ƒ9¾»@ßwƒ$'%Aóú";ŒñÜ2Ñl³j9È²@0èÂø†Q_”Æg(¶^ßÃ%n‹›w+N¦w¥¸kï@1†‡P¼»ÁmõÄ¥åÔ/­X¨Cß8H5"–•j/ê‹šq½P–uFrß ‘$°ºU(ø.ÈìFP.ÀÀî6÷X¶c×C—]ëfÅw¹KJj°…¥bâŸø8÷Z¢Õõ`D›sŸ‰6¸Ã‡X$ìå
´üf»)ö‚E‚PòîVŸ Ú±V“[’?óã›³ø¶ø>ªıWÑ:Ë:¦·ÿ®V×6ÖXÃ¿mÎí?Oò|áö_[Øÿï¿l-<¨ó'ñ	í¿5ú'ÿêæflüÃ¯ùøŠgnÿı¼ö_uÔı<ÍÀâŒÛ$kpÔ¬úHÎÍÁ÷Gá§nÊ@ùùpxû‰o~äît“êÌ	ñ03â‡¥7@ôó’ò?Œ_òxsÌ$ıµºÿ¾¹¾6ŸÿŸâáñ•cşÀ¾(Š+,rMÎ]ø¡*>ĞYó¡˜¸ª$¶ƒÔ5‘Ú Ó€L]©‡Š9»Ó°`,Ã½ˆk•Õ¯Ÿ×*«µ5xj_?ÿúùÜN0í“æh¶uLÿåXüÿµõõùøŠƒV=vå;ßÿPY_[›û>ÅƒñÊ»ûôÿúæ¼ÿŸâ	#v=^Óöµº°F÷?”çãÿIH”ÀG©ãîãu³R÷ÿS<z¸ÆÇ©cúş_¯n®Rÿ¯¯ÏÇÿ“<±pœPÇİÇÿZe>ÿ?Í“±s¦u”Ç¯ÿ*åŠğÿ_[ßX¯bÿƒú?·ÿ<É³Àô¸Ä™öZÜ?Ät³»ìldwè´gpÙè9Ã¸àÖÎ¿*†‰"ê»TvÈ¥R5ÇÓ-J~4Ä íç®1ğ2~Ù1ş]ËQŒ‹bà,(ÈÚ«\œyp<ÙàÎÑ±Ád£×¹&D€\¹{‡Ø±w‹;Ş•rBÜØñ…çv³?µ'9~ølë¸ûü³Àüüï“<©ñãgXÇ„ù:>Öÿ›Õùù¿'yæNOíôñ“õòØ‘"-šñ~ä¾ƒˆ³†ğ‡xj‹J±R~R‹ÄkLP¼ª7˜àå-ã3Š‹M&g÷`ÆÒ?ñ*QÆ½,ºÉ¹ 7Şõuzñ¬ág¹|‘¹+~¢OÒu,³®cÂü¿º›ÿ×66æşßOòÌçÿùü?­—'ˆœSîß9ŸïfïÊ4/ú×ìlÔï‹ ¾üVì>Æ£ÈgŠCìl+Iüœ-Ã Ÿˆ…Ÿ¬~Ä®dcŸ½z³³ƒ×—Â‡ß@îî©QìôØ‹Áí2;ºâV_ü²’yòuôhÙ—‚ÖŸˆå•êÊêÊÚÊúÊÆ½È¹½·uØÚmí5¾ª
ÓëÓQ²Z%J.OK¿à>À»ìsÏÃŸë™p]ßLê˜¤ÿ­Ã‹Øÿ]ãñÿ6iÿo®ÿ=ş3³‹®½š†¶mŸÎå»#º¸G9î²6g,ŸQ;ÃÚQ)(Ú((ñë*!Ÿ¢­“t¶]]Ã˜MÕÈ$ˆòfh1ñìy•Læ©ËøEÑÂä—7 Ó(†—f{—ñû0ÿ(­×æ]ƒßg¦M±Û©¥‘†*Ú›,§Ê	¯V“R#DÁUt™ ÈÓoŸĞ …§ÑÛL@JgK W¶wóEÖà7Xâ¥m+ìÜu`Ç½=Jî~ˆ÷:šgxïçˆ.t¶übfAË-îıU.—©iß½Q×aaœøMè,+š)ş-E*hqê|^2¡‚äÎĞÙ.B*_­ïšxoî%ÚZº¢ø¤jø-İ
TqãèXà´‰;hgxwÈNBOàJ9ìX¯!€é‰Ã`|–Ÿã:bS,#à±ÄJÂ5)`2“(aÅ¡gktiÃïGt®ğ$Ü#û3Ä;óÀ‡ŒE¾şn§Í<²‘ygØ¾W·Mïñ,B?›~¦ÇFYæ½Ë2G×C³Îo$Ìàş}]\dı`İWÎfŞAqdÁ(^|]Âa‹n?ÀwOŞ^RBO„¨j}4;Äsw/["¶{gî8çVw®90gxX§Ïªà /»k¸İı‘?ùuàJ´¯„ù@ÔÅ5w}0êûV«äüÜsú]Ô[ gXÇıİıÿ¿*èN¸ÿ·:?ÿñ$ÏûÖŞëí½Ö‡Ì!İö‚ŠÌ;"Ry4ş_æıëÖ^ëp{ëC¦İÚzs¸}ôıÉ›ƒfã¨Õ>y»İ8Ùı‡j¿9ÀĞ-õ3£ïÍÖ‹lş<Æ“z×ûë˜4ş!5ÿ«ÿacsu>şŸâ±ìKÓÆùûú<6w?ˆœNÎ5-àsc?úDÆÿ¨{\x33ĞDûÏúf`ÿY_Ãøß›«sÿŸ'yæöÕş“ÄÿsĞ˜€Â[¶âFŸ• E|óO<®(™ñÃ4EM°Mı¦ TØ3”	?k»ãqAŠ@}ÿ µ×lŸ×³É7—²ºñ§¹ÖµÓõLÜ‡›z
]êóÏ#TM=J:ÃhÁCÏaÜ¡¨krÖ–@’-C?UÓPäü/©r‚¬]Ä„™Ô1Ñÿ{u5âÿµY^ŸÇÿ{’gî¯E;ê¯¥‡Ÿ¬óVpa¤îºª9)o6Ià_kAŸşT=º2] a·SòùçÈ‡+ğâ¸ç™n§Æ‚ÄŒsŠ{
>¼ §¸ç†mıH.ñú˜I8Ä]§¹Ó[I‚İüs¼x¤¦NË±ñÖHÓ ˜LÔ©ùç;AşÜ¢işÌŸù3æÏü™?ôü{,º  