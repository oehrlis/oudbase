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
    DoMsg "INFO                                 directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default /u01 if available otherwise \$ORACLE_BASE). "
    DoMsg "INFO                                 This directory has to be specified to distinct persistant data from software "
    DoMsg "INFO                                 eg. in a docker containers"
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
    INPUT=${1%:*}                     # Take everything behinde
    case ${INPUT} in                  # Define a nice time stamp for ERR, END
        "END ")  TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S");;
        "ERR ")  TIME_STAMP=$(date "+%n%Y-%m-%d_%H:%M:%S");;
        "START") TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S");;
        "OK")    TIME_STAMP="";;
        "*")     TIME_STAMP="....................";;
    esac
    if [ "${VERBOSE}" = "TRUE" ]; then
        if [ "${DOAPPEND}" = "TRUE" ]; then
            echo "${TIME_STAMP}  ${1}" |tee -a ${LOGFILE}
        else
            echo "${TIME_STAMP}  ${1}"
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
SKIP=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`

# count the lines of our file name
LINES=$(wc -l <$SCRIPT_FQN)

# - Main --------------------------------------------------------------------
DoMsg "${START_HEADER}"
if [ $# -lt 1 ]; then
    Usage 1
fi

# Exit if there are less lines than the skip line marker (__TARFILE_FOLLOWS__)
if [ $LINES -lt $SKIP ]; then
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
      f) INSTALL_JAVA_HOME="${OPTARG}";;
      m) INSTALL_ORACLE_HOME="${OPTARG}";;
      j) INSTALL_ORACLE_FMW_HOME="${OPTARG}";;
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
DoMsg "Using the following variable for installation"
DoMsg "ORACLE_BASE          = $ORACLE_BASE"
DoMsg "OUD_BASE             = $OUD_BASE"
DoMsg "OUD_DATA             = $OUD_DATA"
DoMsg "OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "ORACLE_HOME          = $ORACLE_HOME"
DoMsg "ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "JAVA_HOME            = $JAVA_HOME"
DoMsg "SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "Installing OUD Environment"
DoMsg "Create required directories in ORACLE_BASE=${ORACLE_BASE}"

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
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "Extracting file into ${ORACLE_BASE}/local"
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
        ${ORACLE_BASE}/local/bin/oudenv.sh && DoMsg "Store customization for $i (${!variable})"
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
fi

# Any script here will happen after the tar file extract.
echo "# OUD Base Directory" >$HOME/.OUD_BASE
echo "# from here the directories local," >>$HOME/.OUD_BASE
echo "# instance and others are derived" >>$HOME/.OUD_BASE
echo "OUD_BASE=${OUD_BASE}" >>$HOME/.OUD_BASE
DoMsg "Please manual adjust your .bash_profile to load / source your OUD Environment"
CleanAndQuit 0

# NOTE: Don't place any newline characters after the last line below.
# - EOF Script --------------------------------------------------------------
__TARFILE_FOLLOWS__
‹ öÕeZ í}]sI’˜îìóÅáéì‡sÄÅÅ¹Ä,	.ñÉ¯f ]ˆ€4Üå×”´s¢–×šDn\wƒ‡â†áGûÕoÿ?ø§Ü/pøİ/şÎÌªê®ê $AJ3‹‘„®®ÊÊÊÊÊÊÊÊÊ:µìÒ³G~Êåòæú:£7ø¿åêÿW<¬²Z­nV×*ëëV®TÖ7*ÏØúc#†ÏÈóPñsl>Èvv6æ»hGğïOä9…şwFİh?òŠ^ïêßÿÕµõ*ö¥º¾ºZ^[‡ş_[­l>cåGÀ%öü‰÷ÿÂ/JÈ§†×Ë,°Âì€–ÛîÖXnæ`\ëÒèZk¼^a/Ge›Çšæ¥Ùw†ÓöÙ/Y{4:®Ï–^6Ûy(Ó6ÌsÓ5-ÏwÏ3Yõù
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
?vÎ¦¡QIõÃå0‹şù|™·µ¿÷Š½Hkõ„¦É ùrÜ»CÛ¢EgÑ8¼Ó„šv¬)7ÔPhZÉèğÈÁ;†U^G]´kÈWô3–Ó4Hİd¢iC«›Fç$*cA­ˆÇñôŞÆéÆ/õœŠ§r(µÜÛ¡x²3qÌæŸÎz‰MÂ_8¢n7F¾ƒWåt(ASºè¦E9ı.úë@ï1Ô5hšOğOn‘É’ÿxBÅU8€†ª}LS—Të4$îFîXÁM™ˆ“wfÒ›±ç¨M8sF ë/™çÅ¸‚”€t>ucGŞñ3#WoŞÜÕûÏçvµı"tş-fÖG©c¼ÿw¹¼VŞ@ÿïÕÊêzu³¼ÎÊ•ÕÕµ¹ÿ÷“<ñ7ùìÏŸ=Û5:l¿Í~/E¦=û+øS…?ÿàıÏşÍt GG‡ü•øğçßE²ü+‘ş×Ïı-èáEc8ì›Å¾áùè Œkù…ƒ¶€ñ¯ñ¯gÏşóŒ‹3 ‰K¼>ÓˆÎ³"ï_ğ¼É‹>Ì§}sÛîšŸ=û…ÿ˜û¿şçÿòoñßÊ“0Ú—ùh7
=RãÇÿÚæz¹ÿkÕùøŠg~şãóœÿ<ñÊg?¸qŠNââ9S^xÜˆ^':?ò§@ÊñS ]X]Õ8´)„°y|€ïã¢Á³°[|n¡œ]§saº‰'Dè¹éŸ TĞfB¾?}å»×³&ğŒO† ´— '®Øµ3n»&®õĞÍåÒp-tÜñpåß·:–_„ÎƒÛ¦ıGÙ‚æõ‚}¼S3tì€²>,Ê]÷‹`]ü¬Y—ôC!ÆÿÑÀpÍiÙ¬ˆ¢ùdè:ØGE^çQOlfõûâf>€“Ÿˆo|yH×‘I¯$µæ>’à!J¾qNæîÆÎÎÉÖ›öÑşîö?Ò}JEÈB¹´(…RäM¥Ò„2Š-DrãàØÖÁzøõe´9šW0v î/Êåh„%‡òr˜Ò/$x˜Ğî± „`4¢ÀnôUÔX	vËV„atäŠ+‹$4m»TE-ØsLÅO"S²)LÆÑnªXşO†É3ª½‚¾Aq
N¨±4°ºİ¾ye¸¦
úÕî;	ş^ ±,ÁûmãmCETƒ÷03ëÁˆ¥¬Ò™'ìJ£ï›®ısÉG¥Õ)JÜ¬	9¹µAìº'Ã3ıN)j
ÖtHFp!Ò3pŒÇQÈ-ÚªlñøÚ¦8ó	ëÛÄAşâQÎÌµ”Ùûm 4î‡wµM_’DŠŠª¡dB'; ÷µÜ]ÏeçìŒ0·O;ó2.J^¦+ã¥¸Uà€=än3Š	ÚzèÄYAVô<;û[º
ƒ3›æ9½ “Ú•eÂÄ‰¸°b*r­w!	=s4¹T×Ì±	 øğ‡òºàğé‚oXPxªäºE¯BP4º4m†îAÁ	0«âŞĞµ€¤ÛÈ1ª|ôÿ+•?õ d•¼Ò ]x…8É”ûâå
W}Ï/ş€›J„áVp½¥ãÒû?—>ü*³zKh*ÙAƒMÆ5Œ€eğ»VÈ-!}Ë¾@¿©ddK#Ï-‘ìLA<Ø™@Ÿ2JŠrL*ùOñÏ‚†KFÌR«eó·òúâpâ$rsû°µu´øı	ùÇcHO’;Ó´ëİÀêŒ-~uvl/æÉ…¾è>()Õ7Û­–pô9“S¤!ãšV`Y¢˜-»ªMPXèy\¢oq6%\È§¨©—K¹½}·äG#­æ3¿³ö‹öıkö"r?õğèè{Œ|$HÎıêt*jïĞ;8~k~4;#B£$ü#‚‚ûo·ZMÜ­?i¿î÷Åæ+vO"^)åİS[Ã)éÔÃqÊ±Ÿ×ş•—›û¸È9h}‡î€g–ëùJ/:x1è•ê¡k"tË—74‹N¼e…¾ñg£vãm«y‚ÀcğŸ[ÅÇ,¸2ÌßÛ°=sHn)æPWC-qkÿ°…Ÿ\€Ğ¬øZÈıc‘UL”4yß’^¨ÀC=y’#Š2h/èÑ„ª"÷¤¤i5ì]EğP+So¢<”ú²j¿J&©Çq(›Oùã¡ñ<L§)÷¡EŠ:8ğÙ™âİ*I™™ÆC8Â%)n¾Ñöh9±® 'GvJ§gAáñ\¾»×ò‘E­äQhÑ0,Â’3‹9ú×áÊÆ¼Dã¢‘×àãôäéª9ÜjşÀ)ëâˆPŒ¹JÓ|‹'†t@$B'ƒ˜©—t6As–â$}:É7:Ò	ì¡ÎÒ
gˆ“X,q…N°I@g ŞœùŞ‰qJ³õªñfçHõµIduí)¸;kU)¬MîÎ¢%Á@	¦p_‚£~„ïîÌsiüvw^»/ŸÍšÇˆ¿Í»]4Ï×{èŒÚ{Tb¥ñß‰ry’´%Êï4ÉdîÖø¯‡šè„à]Àª1Üù	(S•ÕaŸÒ`µ1n½ÇNM˜TxŒ&:R‚P%*IÍO@fLó" ¸~o€Bìè
¿š4+«+·ê*g†‡ß¾ÔP9Á¹ot·ØßD·ä(îWW	Q]d‘s`Ìø Cz3F,ú±…(«“ ŒŠI|èÆ£7xşm)Õ½Quï_„/º#,îâòŸZèCO=TŒt8T‹£áâ7Ü£¿£w¤œYÊl+5Áˆç«:HædñÅ#Nö¦İ><‘”s.%'æƒªdüõ¯uD™.-£|Âèb‘¨£"Q(ØìË<«¼$LŒ(Ùa&äßhD†q:n«‚à»8'h[IÄsõ%'6±ŠCÃïé@ù$û0Öª‰¡lÅzş¥óN-ô¢¾”‰Ÿ•æ}Îb0Ä†A`JÅ¡¥iL½m.D^u<ûN³qÀP’2¥
V˜µ­çYOÚíXö¹±'f§@à±‡Šïº(&¶¢ÙgÑÇúCÈ£a\«bXÈkP™Å*—i}3Ä
[{WiÌéŒ™˜dT&Ãni‡<ƒ¼˜ÔCJ#˜öO$uÜ£ å,jò™2ùÌj&áÏCç
Î*Ö¤‰„?wœNğYËt§g+Ì´%ªæGaº@ŞÔ»±nC¿rÂZ>òşÀªq`(TîpU(6ÑûªP){ğ÷şUYÃ¿½c;›ĞĞU	‰R˜&|Ãû› w<x Ûü&zß&U“¼ËY	+s|øğz¢cÂì\¬·(l7t¸5Ru'æl9/}‚­MzF=qâª˜ëˆPSUä0U¤®¨MÿvZpº]GİTZêZ®8NªNúcÎéæ	Ã–Xñál<¶gŠÙHâå o¢)Dº?õ¹s”.QKŒï“éÇ Ô¸pL´)ˆD”¡tEH ğè#ƒë¸S	>_ş4F¾Ü~]OçŞøÂ$ºªqYCIìÑø"!i@|§NT´En³Å)­¤_’×.{æØ6MÄ¥•Òr¥á¢Ä ˜*º^¡sv^@iÓ½4b¾@ûQâ«ST‚õ}GG!gY›˜ğ´Û\%(Ö±Fªzø,©zGY¥.{g «®‘ËGa¢¨ZÂ
‡.ı†pûÍ‹{ÑyTÚ÷”¶Ø¶¡Â½ŠP+d×àÉŞ&å9!OeõëçÉy8§æİXİHÉK]|#BŞ¯Ÿkpï/’&¬{0ºÔ³ÎVJE±±l$¯ºŠM\Â*ù£ËØ”5¬R"ºM\ÄÎŠO1í¡‘±gö–µš‰‘²Hÿ~5ìÄŒ½ì$ı"Û­÷‚–ÍHµ:ÛÚ{û0çÄ,ÌªäTy:Lç}VöÖÓvÉ¸é³xXHOŠ;ªòB2ıáÙÉÁ!!;¦G²ëîÏav-}eâÁ¼LÉ÷æùez${ÜqgWÒ“K(ÏZ	™^X„b‹ñrZSêº²­IZ	%}LÙ¨h‘ÄFEÂ¤r	(¢ d‘ËazBVqU`,+OO* Â5	6¦'eiŸ˜Òµìª4·.4úè÷’!Ü:ÈŠl¯YÿHå@ß§ÀFèõÄiPä¦OötÃ¢Üé‘ õ²$¨™^Vuš¦ïJÕ½°øù0$ßkP¸2¯ÔˆOñZÏVLµïO(,âCb<ˆ» |Â}äéÜS’¿v ÷]Xÿ!D;’–0°ĞÁık²?.à·mnË¥MmŠS$ôD+ULz2S°dƒ5¥‹ò.3öá‹è^íFú‘ò+~Ã¸ùî-—óõ¥Å,ü÷)›/.Óö;Ë+k»İ]ò L…±´€0rŸ–8”<€ÉçJÇÕÒb”ñÔJ6ŠV)n±-ÍÂvCmJ±¥	è·ZHj´…qãÊX&P:Ÿ\_O+ra”àNTª) 2ğC"”/pÙ>¬ğEüª>‚ A–i¹¶?2\ÀHI®ò«†·œÁÀ±€Yë9­ zBƒg;W”ïĞô@şÕaM¦+â=¨W²¡‹%E,zÀ}ˆ8¬Ø~§·Â¦aãÈ1|Ö±hQ4¿Ew:JÇgxènÆ¹ƒ1×‘[úx˜-¹&İb¥VX:$BV±»…ÉŠ©}ä3às»³+ş·yP²>âe(ñš„§ødy>Ş?²')5?¶È’äV·`ckè0SI ‹­x´—°^¥MÔ¥l¼ş¾¨5ú<.ö¶ë ‘— _òù½|D)±ÂóÅ³pUd¦‚ÀX°`ÄúÜ1…›Ë‚NYe0
ÛÈçG»lÇ.(Y(Ç+Ç½2Ü®è³ñœ'ñÀC<ßê\ĞtCÒ¾eaÂUèT°•ş¡øÍ<M©6N¸ÔÌÒ¿;„>Z$|×`^T“¿”Ñ×s£ ©UtI)âJ¾x”°è³‹
­†ñ–öÀ)gW¤¯;—·ÿ<2=F¨¹F™AÑòpÿPqûƒ)ÛLbÓÎºŠ9ƒä)²w%’{¡Ùæ•¦I¥EŞÑîNÚG‡Óìvi8Ço4p1'Éµ’”ÛÑ…¹sBª^@X,'Z’æÜ	ÅÖ"Å¸©rB¡uÅÜ˜àP'ê$l¶E¼ì$u:‰ì†Ÿ¢„#KPjŒ‹ôşS—ëIí"ÙïHŞ]ÊÆ€ÄK3"¦,ÓL‰ŠS‰Œ'f)qßaAsà/Hƒa›à>“®ÕÌÏx‚4¨1¬‰u¿‡{I1 ‰nT‘DšW;Ğ5eº¦í@×Â¥ñm-‹Ñ…˜I¦Ævˆ:ÂùN(œØÛÛ]óÒ¡G(‡G™ !üD‡Ó/^,ô„÷a¤j%^\Z€FPkL®øÑ¡&ÍÑŸ!"uVÈã (ó ómH’àØ¾§òûL;õFĞl†ÁgçâŠ½ÏÂqÇdú)(T)ğà™<>J“Ç°N-»–ºi+>*´¬)ÖQY˜ŸlÃZy5Ì]<$¶k]Šx F~¶|õ€ax+8,%!é¬\LÏ‡G5\Š¿¸@éØD`MB*š=8ÀˆÚ;páHzşèLà%Íc¨)¿$*@Ö5¸±*õ\Û’Æó)ôÉ'Yª©åùéÒ1ø¤›âÑÒ6òìjz—[gB¢¦â0]Ç¦f—b ]ˆúbj4"òc:dE$ÁĞğ¼+´=…q{¤Ú0^èbV©àdxÕ-úı¤ãïš<¼ıåc'3ËÌØy”xßê÷$á.4øH<œB|Û…¿ç!”c/©	XhAWÌb=[È|î ~|„—Ï£Ö1)ş+ÆK¬¬VË•êÚf¹Rağ£º¶úŒ­?*VâùÿØ1]´Ïá­ŞcqÁİûumŞÿOótÎãşgS÷?ÿº±ı_YßX›÷ÿS<Øÿ‡­Fs·Ut© ÇÆÚZZÿ¯–7«•Hÿ¯–×æñŸäY Õ0]ÊÄÕ¥%0mß *Â­¶ìËÿıŸş­e@Óên×úQºMZƒa7yhï;Ø	£X=¡æÆ£µ	o«Hçîiù3}éø©†1x½14½"kô1îëyO;Ô*Â©b:‚F÷ì¯ƒğ§Ø<¬d[ózğV„ë…îÎÀÄæ=hŠ?â¡WØ}Ç8¡¶‰«™7À­$jqrwé:M9åq8E$Õà²$~ Û­Ñ±Å¯D„öÁúæGêâY]¨±ïP¬ÛÍöÌÖ5526%5:ÓÎd£½»Â[+”éõ:Œ`W®_¯zV§‡(Xa˜S\¢‰Ù´Ê0xïšJ#Š™Ì²dše,à$ıkî ˆİ´¼2]^dYáqVµš"ò,q;ÙÚ9ëá":×ûï:H"<MwjÙ°62¡Ã$õ)4mB-iØX}ÃE6¾Â-]HÑÍ€Q.²»JÈ„WçŠ™¯\Ë÷M`\VîÂÃÍ˜‘÷Êe>²·»ÿû?ş7À
qlRT]DÊ7, 4•;4¼á©éBÃ,ÌÊûR-Ãf¿5=ïºÔö]Óïô¨~jÖè{Ş“Fİc_óøIõ0XK. Å{4ŒtWÖğØQã/0ÑŠæñ¸ÎZhYú¸‰,‹İZdïp€ %’¾RE!tîäƒ±>bQ=¼¿ Ñú§¢ äÜù Wûc‰½Çe[§ë™0"l¥äõ`¬vKñÊX¡—Á@Å…J¥PY=©¬Õª_×Ö¿¦‚‡GU­7ÎY4>.]z+I¹XÉs4Ó MyíìØÂt÷êJ"ï½Ëğ÷)ûVq7|ñ…Ç „”Ğl”/Ú ø†ö¿0ı%#s‡¶ñÅ‡±MÀ¢:|Å~ßìP`¨µs3?	Üe:8ÓæŒM÷Ô¡;pºæ$hšªĞT—ÏÀ« ÈvqŠ#¡#/“/òPåcªšô(†K.u/­îMh‹#{.ÒÆB`JC–äy† ^[¾8©Š.¯cÕ$UA‘““«‰™ô
±Jø]” aç$%’9*Ü0ë9g>F(–´Û<”ÂŞ$B¤,Æ}¯"¡¢uçNğz€ç‰ìŸ4lR*–³`ro(›'Ö Ø„º)Äkb“ù§ñuı(îo‡_tùfTpb¨9˜=2™muÎ2?¤³P$}
}yy_>}„¸ß£_TÁR„r…Óåe1bywbÁk¡æ(D†l!m¸ò¥»É¥—qJ[fKROá‘{>—NdNSo¢%À9ånZü¢7G„U€óPåIŠhE6ƒiöEi$:;Š,íÅçµêê½gà»WtÏÉ™~C°C¸}ç
ßƒ;Å#P¸+DÒÑV…²O.û&ÛşneõPö²l
¡’š( D W4IÉxªÁáÇ4Wl ,ãÕ'ó¿KîÕ?ìÅššÎ´)ÜÂ¿Ó9vJ Üäü[<²Z°0’ãnxâš‚\NÕk^èƒKÀ˜˜wÈ²oêìZQ¨Ò»T5®[’KL`¥z=vp‹¯,;~ïƒ@cMgÄ5U'ìW™Â7¢Ô¾Ó£¤ˆ»vÄVGF3ygĞ –Ñ¬`ŒòOÅ÷e²Ü)•ïèí×·NKè”RÆ7aúáàÃŸÚEJz8¯ØUsRıá+ÕŞs×ññ^ŸnZ2`€”Z02,ŸÛFê“#Æõ†‘/Ğ8\`ªíD¿ˆk)é¬.Ú¬ÉrÕ÷N(¶yÂwÑpÄ5y¼Óô¦_‹ ]f³„œÓ-&VäôR„áR@‰£Æ0™Œ¼N…ŒtÒ¸(z37)RóÏS‰–Ö^Ï›&Î\µA#ˆƒ·"	<ß2ãÌ7ƒy	‡‘¾Æ„¢¤¦h¼Xˆó%8¬å‹yòñÀâ~ÔPLü}jâÉ¶,*Äu)Ü¾¬jÆaSFã7S†äQPnÜÁ—•¶páö¬?Iõl1ÒP!¸6€K«|VwOĞNØNQœ³ÎÂ‚¸\êƒHë†ÛéY¾I–´Læåupä}YrP“Eğ•ã^ğÅºB©Ú'WK…ÖØGŞˆÌ€ö
ñá
¬ª"ÓJ(Ñ£¼CG´,8ûÂÄëg=á,ƒúšoÊu)×u}ë"Ñ~¸ŞåÍm½êJ¬ˆÇµ¸²ŸÑn–¸4=ÖqGx b…ø@Û¯
ÛÈm¢C®©Ù~Ã\»ô‡.`"›H¿KZO(ú| c¨uzêú ˜G½xæ4¾òJ¦†.zó­ÈåÙŠğÙğ°W®L@¬c€Œ8`î¡+Ş<DRÊD6	B½9¡{Š™Ì'~K\äùÄš&-˜ c‚“ûMÁŒÅ½ù·:ñQ®…~AhÂ*Ìå>İĞ~–]~ßš'C€6ÂWX¾Öâ°UÂ‡K;‹‘S£²HÑº"-Cmë˜ŠÁ$Âµ«Ö§á¡QŞ™hİ˜B$`ò
ã÷Ëóßx–öBø¦p³…4'G4p\‹i10‚˜j¹‡Gqo“6t”¡xÓ;¨0ôı´Ğóûø=Iİ"Ûq²|†ÄÛ/¤ËQ@ç¨™D?e®$c«9æ¢–Œ@°°â¹î e0"ÛH`·s•.§PõĞüÄGuSY¾`¡têå
G8 •‹®&v1í¦Éâ˜NcƒÇ}¦ATd»ì4 ìĞ¤!-ªN¯q§…-‰]”W}ó#]7§ÎWy‚ªíÕtQƒ8DG_Ğáxü“K©“åU¢Ôbc²Ş-ÏU«&¾–ëtÓ Ê¾F)‰­N°ïÑíâÊ>ibäU'-8»d¨¯©Z5mÙ›@¿@Ë²rëšJˆb€^Ì.’F™ÊÊx$Ç¢‡s¯mr* yQÓBVÔèWšÂ‚>ÍºR!t,¨c@WßĞ„DŠc´:#ÜÁä7¾•&ê4b¢
µ‹`¾ZÌ	©ÌlûâÊ®(K®èÄq}²ÚkduÜññé•Û I‡äºíTˆCúC8c4İR+ÓÇÊÍôVK
F,ÔÒğ¾BÕzŠñ[Ï˜Üj}b Je˜¨ùE ï¼Rü VªgL®T»q"E#Ã9¬
ØmbU‡¶Ï’Úw¯J+$•ÙÑoàá3lÒja§¹ıŠ˜	÷£Fî©Gî„¸?zŠqiôÔìªHÇ&°^@yá•*<°Òî:~élpU©«ÅJqµXÆàâìÍwÍB+] ÍQ“¨T @µ¸ÊQHŠ²“ÜîàR¹Òİ‹Jñëbù¤²¶)ó[¼K.¸ÑÉÈÍ
MÍµN©¡–*¡vĞâ˜¥Hhm-¤M]ô„~·˜&ñÂ¸©KìŒÑİN|õE4÷wÛ{	4;ÚPûµü~¤?Ÿ¤Z)_§x¤•pĞ%º1*¡ÇY àx«ÇY §ÀO`’†§:zDv&ÛI8@EÉRŒpè(¯qt•8™2ÓVävØñ€§E^yrå ÉÕvÇ™®fZ¼ş·á¥Ğ%—Ám¢¿†‚µùSçÒ$];YÏæÌFo¾›œK`CñEàuõ6MÌë×é v”›¾BÙã°tå×ÿğÃ¨<“@—í0:@µvGëqy€‡N¿ÄÚˆúâo‰úµšxÌ°ÂA¨€¢Ñ¹’ …F†Éà"±»’ÀEM“F"|%Œã€‰^L¢œÈ«hï±Yø¸§p hÏØ§(]/E[cô·ÛpÙ/ï3^ÑØ§‘Ï9X7¹VíR¯LXJTÑë½ĞÂÈıR}“D‘dk2:½ø%^äƒ‰¶Ä;¶ö1Ï‚µ£¸€‡Ÿ6O_Ød6Ä”Z‰‡%
@ügêßÉ$ğRªÄšÔ]L2ù†‘D"ª¿‘u¹‹P`¹×Ç}ÇË£ƒ[*¤ós ‰+pÔœ(?vÂLaÆ¿MSx;#_Œ1QÒ ã·é@«l¨ }1é‹p¿ÀÀ7ãÜ,`²pÓ‡	\LN&~”B?B°ÈÙom
£"ÄKËI…ˆßğŞ
O^GÈ·qÂŠm{Şd•Øá¤ü´sy::Gš¡¶ˆV¿"A<+¢@*ıKÑ…P&ğñ"}îe."Ìï_Ã¿£ÓE´#C…÷ş/L÷ÃRÏ÷‡^­TÂ„ÅsÊTì8ƒ
PMJ uŒü•òJùZ&³ÌŞ·>’ßß9æ…P Ùsû–'BJ<k‹{£ÓÅc÷PêÊ— P·cup·
o°#Y…fmÔe#›ü³ CS¦Ì¼Â¤§SµX.²ïğÕ5sNi/Ì€)fx-µQ„>ûÑì®®®Š,:îyITç•v¶·Z{íV€¾ ıìç?p“şQ–(Ï”ç¿ª›«›åÊf•ŸÿÚ˜ŸÿzŠûŸväÆÊ#Ô1şüüŞÎÿUVËxşkş›Ÿÿz’ç/şæ/Ÿıù³g»F‡í·Ùïå”‚iÏş
şTáÏá¾ÿÏé@6ÅO,ñßáÏ_G²üY˜ş· o‹xÌ,â…™h(ÂèmÌhü/óñßÖßÿŸ¿{P;çOâñg{”:&ŒÿÍêúfdü¯nÎÇÿÓ<¿À}‘Ò9fM·šœòx¹ínåppTµñz…½y–Kœ&€u†¤¨ş’µ…2ºô²ÙÎC™¶aãy5¼LÆÕªú|…}]Y¯²×}Ã÷OİÑùù
kƒÆú£éâñÓG@íQEşÔTgøÔù=ÇŸÚ¾y†;¤„²%X‡äÑëÒŠ\1ı/€Ê*”nu-?(Û1ºÅı'^^óh¢_h1!~àYÍKµÓXùgÓbëÎe¯„+¤ô£å:Óüx8íğ‘·`áƒDs|Ó“¨Óš^x#âq2ĞœaMl.¨áÚ×’ÂY >Q#Ï€p9Àf}O/Áj±ï,<šq]ƒ×Êóby³X-W6 y c˜¼¯X`9
ß#*®§¹à‡Îµíy¼mÖßâİ83G\†jWê‹Ç£ß÷jÇW%ö>Ñç[”9;İ^]v~9­+®£ar_‹¥6 ë41Ò’¡Í½CKÉÛKÌ«dè§C[˜Ó9QÖ0‚]Æ$“¡t=¼ø"H&ÑÕE)µÂì æÅx¬Ó¶—úõt-R6åšÛ‡Aï»t·bÎ‹Å8T ´~O¶Ê bÿ+ ]’ÉMCóGÜU¶G|ı
–Á{À­ÚPĞ‡¤¯¬/ÒÏ	Xøöâ#0~)t‚½U½®!“zKk†Éï¼xÎ"wçp0
WqílÃk0)„9/„r±ÓÜş·|íÓ×¬:–³ÊWt ‰çÀ*µ\8Râ¹ UË…'R!WÍ
ğqzËê§f
†ƒ’»3>7ka~ÉˆØ
¸Ó$pZ&…øHq>¬/á?ƒD§ÇS•Ø¢ò|‘·È$hÿ[ÜÙiµê[¬#fÂO”"ÈT¬/â‡.+.swœ¾ãÖ‘ï’Áœß] ï»A’Ç“’ y}‘Æxn™Œ¿hH¶Yµä	Y ôa|Ã¨/Jã3[/ïá7È‡ÅÍ»'Ó»RÜ5‡w ÃC(Şİ`„¶z	âÒrê‹—V,Ö¡oœ¤KŒ†JµõEÍ¸^(HË:#9oHXİˆ*|dv£(``w›{,Û±ë¡ƒË.u³â»Ü%%5ØÂR1ñFƒÏ‹|†{-Ñêz0"ƒÍ¹ÏDÜáC,öò
Ú~³İ{Á"A(ùw«O 
íX+É-ÉŸùñÍYü©G[üòÕş«ieÓÛW«kk¬\Y__İœÛäùÂí¿¶°ÿşßÙZxP;çOâÚkôOÿÕÍÍØø‡_óñÿÏÜşûyí¿ê¨ûyšÅ·IÖà¨)Xõ‘œ›ƒïÂOİ<•òóàğúßüÈİé&Õ™âafÄK)n€èç%å¿äñæ˜Iúÿju3ÿ}s}m>ÿ?ÅÃãÿ*Çü}QWXäœ»ğCU| ³æ0B1qUIl©k"µA¦™º.Rsÿv§aÁX†{×*«_?¯U6V7jkğÔ¾~şõó¹`Ú'9ÌÑlë˜4şË±øÿkëëóøßOò`ĞªÇ®£|çû*ëkóøÿOò`¼²Ç®ã>ı¿¾9ïÿ§xÂˆ]WÇ´ı_­®¬Ñıåùø’'%ğQê¸ûø_İ¬Tçıÿ®ñqê˜¾ÿ×«›«Ôÿëëóñÿ$O,ç#Ôq÷ñ¿V™ÏÿOó¤Dìœiåñë¿Jymû¿R^]ÛXÛÀşõîÿÿ$ÏÓãgØkqiÓÍî²³‘İ¡ÓÁm£äãv‚k;ÿª&ŠH¨o<îRÙ!—JÕO·(aTøÑƒ¶Ÿ»ÆÀËdømÇøw-G1.Š³ H k¯r7ræÁñd•KGÇ†“ÜËı§Iös³èüyÄ'9~ølë¸ûü¿^­ÌÏÿ>É“?~†uL˜ÿ¡ãcı¿YÏÿOòÌ>Úéã'ëå±#DZ4ãıÈ}gáñÔ•b¥ü¤‰×˜ xUo0ÁË[Æg›LÎ(î;ÁŒ7¤>âU¢.ŒzXt’sAo¼ëëôâY?ÂÏrù"s;WòşDŸ¤ëXf]Ç„ùu-6ÿ¯mlÌı¿Ÿä™ÏÿóùZ/O?8§Ü¿s>ß+(ÌŞ•i^ô¯ÙÙ¨ß|ù­Ø}ŒG‘Ï‡ØÙV’ø9[†ÿ*@>?Yıˆ]ÉÆ
>{õfg¯/…¿ÜİS£Øé±/‚Û;evtÅ­¾øe%óäëèÑ²;.­3>Ë+Õ•Õ•µ•õ•{‘s{oë°µÛÚ;j|)T¦×§£dµJ”\–~Á}€w#Øç‡?×3áº¾™Ô1Iÿ[‡±ÿ»ÆãÿmÒşß\ÿ{ügf]{5mÛ>ËwGtq8rÜemÎX(*>£v†µ£SP´3PPâ×UB>E[+&él+ºº†1;#›ª‘IåÍ"ĞbâØó(*™ÌS)–ñ‹¢…É/o@§Q/Íö.ã÷`ş7PZ¯Í»¿ÏL›b·SK#U´7YN;•^­&¥Fˆ‚!ªè2#¦ß>¡AO£·)˜€<”Î–@¯lïæ‹¬Áo°ÄKÛVØ¹ëÀ{{”0Üıïu:5ÏğŞÏ]èlùÅÌ‚–[Üû«\.SÓ¾{£®Ã:Ã8ğ›.ĞYV4Sü[ŠTĞâÔ%ø¼dBÉ¡³]„T¿&Zß5ñŞÜK$ş´µtEñIÕğ[º¨âÆÑ±Àiw
ĞÎğî„ À3”rØ±_C Ó‡Áø,?ÇuÄ¦XFÀc‰•„kRÀd:'Q.ÂŠCÏÖèÒ/Şè\áI¸Fögˆwæ=
€%Š|ıİN›yd#óÎ°}¯n›>ŞãY„~:7ıL/&²Ì{!—?d®‡fßH˜Áıûº¸Èú5Àº#®œÍ¼ƒâ0È‚Q½øº„Ãİ
~€ï¼½¤„QÕúhvˆçî^¶Dl÷Î<İqÎ­^•Ë9Ã{À:%xÎPxÙ]ÃíîüáÈ¯W¢}è$DÈ¢.®¹ëƒQß·
X ççÓïò¤Ş=Ã:&èèîøÿUAwÂı¿Õùù'yŞ·ö^oïµ>dé¶gTdŞ‘Êë ğÿ2ï_·öZ‡Û[2íÖÖ›Ãí£ïOŞ4G­öÉÛíÆÉî÷<ìTûÍ†n©Ÿ}o¶^dóç1Ô»ŞgXÇ¤ñ©áø_¥ø›«óñÿe_š6Îß'Ğç±¹“øAdÈàäpr®iŸûùóĞ'2şGİ“àÂ›™™€&ÚÖ7ûÏúÆÿŞÜXûÿ<É3·ÿ¨öŸ$şŸ›€ÀŞ²7ú¬ğÈ3ù	Ì?Ilğ¸ dÆ{#Ğ5=À4ô{š‚RaÏP&ül¬AjìÇ5) õıƒÖ^³}\ \Ï&ß\ÊêÆŸJäZ×N×3epnê)t1¨Ï?,@R5õL(é£M<yq‡¢®ÉY[I¶ıTMC‘ó¿<¤Ê	²vfRÇDÿïÕÕˆÿ×fy}ÿïI¹¿Ví¨¿–6~²Î[MÀ	„‘ºë¨æ¤¼Ù$­}úSõèÊt„İNÈçŸ#®À‹ãgº3Î)î)túğœâ¶õ#¹Äë_`&á;væNo%	vrğÏñâ‘š:ı-ÇÆ[#M7€|`:0Q§BæŸïùs‹¦ù3æÏü™?ógş<Òóÿ;PZF  