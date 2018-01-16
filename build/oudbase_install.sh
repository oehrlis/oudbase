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
    DoMsg "INFO :   [-i <ORACLE_INSTANCE_BASE>] [-m <ORACLE_HOME_BASE>] [-B <OUD_BACKUP_BASE>]"
    DoMsg "INFO : "
    DoMsg "INFO :   -h                          Usage (this message)"
    DoMsg "INFO :   -v                          enable verbose mode"
    DoMsg "INFO :   -a                          append to  profile eg. .bash_profile or .profile"
    DoMsg "INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This "
    DoMsg "INFO                                 directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default \$ORACLE_BASE). This directory has to be "
    DoMsg "INFO                                 specified to distinct persistant data from software eg. in a docker containers"
    DoMsg "INFO :   -i <ORACLE_INSTANCE_BASE>   Base directory for OUD instances (default \$OUD_DATA/instances)"
    DoMsg "INFO :   -m <ORACLE_HOME_BASE>       Base directory for OUD binaries (default \$ORACLE_BASE/middleware)"
    DoMsg "INFO :   -B <OUD_BACKUP_BASE>        Base directory for OUD backups (default \$OUD_DATA/backup)"
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
while getopts hvab:o:d:i:m:B:E: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_ORACLE_INSTANCE_BASE="${OPTARG}";;
      m) INSTALL_ORACLE_HOME_BASE="${OPTARG}";;
      B) INSTALL_OUD_BACKUP_BASE="${OPTARG}";;
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

# define the real directories names

# set the real directories based on the cli or defaul values
export ORACLE_BASE=${INSTALL_ORACLE_BASE}
export INSTALL_OUD_BASE=${INSTALL_OUD_BASE:-"${ORACLE_BASE}"}
export OUD_BASE=${INSTALL_OUD_BASE:-"${ORACLE_BASE}"}
export INSTALL_OUD_DATA=${INSTALL_OUD_DATA:-"${OUD_BASE}"}
export OUD_DATA=${INSTALL_OUD_DATA:-"${OUD_BASE}"}
export ORACLE_INSTANCE_BASE=${INSTALL_ORACLE_INSTANCE_BASE:-"${OUD_DATA}/instances"}
export ORACLE_HOME_BASE=${INSTALL_ORACLE_HOME_BASE:-"${ORACLE_BASE}/middleware"}
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${OUD_DATA}/backup"}

# Print some information on the defined variables
DoMsg "Using the following variable for installation"
DoMsg "ORACLE_BASE          = $ORACLE_BASE"
DoMsg "OUD_BASE             = $OUD_BASE"
DoMsg "OUD_DATA             = $OUD_DATA"
DoMsg "ORACLE_INSTANCE_BASE = $ORACLE_INSTANCE_BASE"
DoMsg "ORACLE_HOME_BASE     = $ORACLE_HOME_BASE"
DoMsg "OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
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
            ${ORACLE_INSTANCE_BASE}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

# Store install customization
for i in    OUD_BACKUP_BASE \
            ORACLE_HOME_BASE \
            ORACLE_INSTANCE_BASE \
            OUD_DATA \
            OUD_BASE \
            ORACLE_BASE; do
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
    elif [ -f "${HOME}/.bash_profile" ]; then
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
    echo 'alias oud=". $(find $OUD_BASE -name oudenv.sh)"'    >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. $(find $OUD_BASE -name oudenv.sh)'                >>"${PROFILE}"
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
‹ bø]Z í}ÛvI’˜víõÅÓ®Öçìñ±s@ôàW’b7º¡ˆ€Ôœám	Jš^IÃ-E š@¶ª@Š-q|í×}óñøcüû~ğ8"2³*³. HT_Pİ’PY™‘‘‘‘‘‘‘‘‘ç–]z²à§\.ïlo3ú÷)ÿ·\İâÿŠ‡U6«ÕêVe{»ÂÊ•ÊöÓÊ¶½hÄğ{¾á*cNÌÙ..&|íşı‰<çĞÿÎ¸{ÍóÇ^Ñë/ Éı_İÚ~ZÅş¯T·77Ë[ÛĞÿ[›•'¬¼ \bÏ/¼ÿW~UB87¼~f…æ÷ ´Ü^·Ærs{êZWF×òXãå{>ö,Ûô<Ö4¯Ì3š¶Ï~ÍÚãÑÈq}¶ö¼ÙÎC™¶aöL×´<ß5<ÏdÕ¯6Ø—•í*{90|ÿÜ÷z¬}mù?˜îÀ°»sGúĞšEşÔ˜6ààccì÷W|lûæ…a³#³ï,¶æ˜^y”Vt(í·¾ @±ã¡t«kùAéÜ¾áù»}Ãî™İç7œüMÃëV3àåÄ¼²<Ë±cYäíxìÏäÏ°vÇµF>óÖ3áŸ¾É,šfwLÆ[È¹¦?¶YÇéšH	Ç7=‰ÍiúÑã0à×Ğ°ìÁ{f—]8.3í+ËulêTèœ¾3öÙéëfª†O„÷t+Ô†Àú¾?òj¥RrÏ‘:%N1E°¸9÷nò°o«÷¦¯åJ±üU±Z®<eŒDalÏ¶|Ë°+ÓE2BJµX©`™§Ñı¤Ò˜Ñ„_˜Ù±™sœ-.`pØ.Tê­{ôŒùÛÑ«æÙÉÑÑéYó°û¨¼Õ
Y`¿‡C¯è¸½ì-!Ğ²»ØÆ‡ã‘!pM#ãÏ^ƒ±é= A™×­“öŞÑaz3Ó<j·›õìéÉ«V–Íø¬ ïç“œ»°à‡1™ X öó£v«}ÑØoßğÆ9A6ÄÑÔŞ=Ù;>=;l´ê¹5äpäË•ó™Óƒã³æŞIk÷ôèä»z¶äGYJ|±·µç>jnKzñb.—Í´O'§gß¶ÍÖI=Ko(èjè¶ÜG¥ö[¶öšs8¤òİæiÌ²Üz6sĞØÛo4›'­v»<ı[Ç5`@;ıLëääè¤^Î¨ñğäà^Œí2ÕC˜ƒ›ïè»x±WÑ3×òìcT¶6-o40nx†9×ìp!15%5¯Ç²{‡/XW¼íä·…ş•Ë
ûG÷Ş!ğÄánë+4Ù7 Ft›‡ğû{şûFûµãv_ ó?cï“*a¬ĞObvªœ­ù89ar‡·”âWIÅFJJq7©x§ov.iúqÍÑÀê\J ´;|$û^!ûÖXÇ®7-×ìà$ÁZã¦€K$İsHa#‘D²$¥t¬[ğ˜„ø”œTnßé‘x‚	şãşÑK”·<ŸuÁŞBbå–z>+³÷_ãüngd3w¦a7ìî?Œ-ŸçË}¬ŞÒgs s­Ì‘xÉåËŒÒ/¬Ìmfîs]âĞ:àŒÅe”oIa5Ô‰êkùÌGjçŞáñ«S˜$+_ÔÖo“˜ĞuK“fëŞÀ`°{ìÜ„ºœ¶×@rujW2`FP™Ált²°Äà |7LnAŸdá…eóŒî´Î€abé‚ZÂ²ÿÅw…/†…/ºg_|[ûâ öE;›ÿúk¥èÉIzQ{Jaš] ô=ê=ú=ÖªÕ›ÍªÖùw-C1á‘…LÏè„# Krğm–Õ™P¢ƒAf•êÂ¤¼TG§ï`ş'`DYöÉ7MV0”ñ”ÔÆÕd0A6Rò§×·.üàíºã°Æjø®]G«â®-ÑŠ$Nm]b'ƒÓ²*-·¶ëØf\6Í±Û=KjÓŒúÉHÎN¼EÈç@Dª*E,*º)@‚ôÁøÁò M›ø”'A=!’+(ƒìå|0ç¢t…™6¦=«âª¢d‰
Ù[ĞL¶Z.²7°$î1cèŒmÒÄ·7Æ%²Wdm\cšÖP¼wõ½WT«¨ÎZ…ÌÖpjÏÏ
{*|U+!µX4}Ûñ©S=œÎh	yÚx~Ë *x9iìî·íæìy£!zj­TŒêñLŸ k‰Æ•aP{ÔÚS©Lƒ¼ëŒ]‚à;ãNŸ¯ø°]Ùï fà]ö.÷ñÛ#`RQ"©‚ÛœÚŞ¶³}‹/Î/ afW-¿5µ|ËuBˆN—´½øÔÖğâÔ»îØ¶Q6¡3¶®zp]OQÑ¡nNƒz`yiVq-[åèYx+ÂÑH7¨j.°m“‹Äo¡=S´Ú„–7°PC$³mÏHOh'
qXGš¢UØÑòH¥;š8RÆg)R¼o%ÈïQECâ–?‡|‘¥àÿÕWùÈJåwh$»6lÛ`èï}c0p´aú›©bç•}i;×6ozŠ¾WÀÌÒPrş:N'æĞ¹µÚD…šù h¨œ¸CdõY©k^•ìñ` N(øÏŒ0½˜ƒC„%òáö>€Æy œÀ¤\`sqaåŞd¤ê"³qÕEW[8Å/0[TÒÅ(_LÊWé´eeµ¬+/,Æ2îPq€>Í8éè²OŸàË¯X¡ù¬"¨ÕZ)CmX×>‡“bÈÎYní¥M8õÈî{óÑQÇÚÀ8‡§R¬çÄ²=#t94èÁO9è[nÀAàEÙŸ§BePãJ®ıÆÂ?£şÃ~ıkì¦k–UlZó#VÒLĞ#:]*j…ÊÚ´CŠ©sœpœûçÂ²Üa=ÈÆ­p¿ï#–Õ¶UÎâZ:“Ò¨®ØNAp‚" ‚N¹ˆÙÍd1hU6™ÓƒÍ”¬ ×½p¼õLßÛêåG®ƒÃ'41Â#ÃfğÑîÄ×¢4ë_YµfíûZ«æ¢¶,?¸")ª"|É-seEè^å#ú°òÍÊ³ƒ•‘‘M4/µ¹ª‰ù¸-%Ç÷2‡jKÉëæÙIëxo·qŠFüV­¼Î•ÉP~#[e¹uu¢ µP -ôö¡ÌˆÉ¸	"C[t,j£ê¼›)jÂæÌ1(‰İz.%²,§ƒR‚=cÁH†QıëJ3q;{î7PWŸ”
fâ$±ë…èlú1ÈŸ´Òh·Íb$À<Ô()a’'¾	"&œA'Œ”S‚2ñN?!6“äO0I\›@®+Ìå¾LÀ²Hş³VÈ&Z{o3	Ü+‹©‰  ÷ñøMS4ä–“éWbŠŒçŸ4mmÆ;GÌ‚%flKÅ¤lDû‹2xFä,ø¶máÂµLà§H± áÈ§ßÇ®32]ß2=Ä’8Â†4}¬¶‰%62ú.h€`êg:SÍÄáØ,úİ¹|«¢e<bˆmÛ€1$³Ñ…?0å|?7ıp?»`±U¯ôÇ\©PZUùJ}ïÀäôÜè\B^¶×ä&éáxà[#ÜAD‡ DéÈ5€]aà›|T£s¥‡_{¥wv‰•¾¾MâH?ğE®š0ñ‰Õá§c>	iƒo[¬ˆÍ•¶é^Áª¯­öÉZÖ€M‡­Æ²ˆ­G³«Õ—Dé;X–huÇ^º+GÕ-ÑÁ):á‚¬/dšŸøB,ƒKRûÍÆ1ıÕ&R2\¬$€Ë}´Äz¡ñæ÷gG¸7°f\_²Õç­—{‡OÚõì;»ğVH/ègöë½—‡G'­]˜ê•¯ù‚¦¾{0ö'Vúc£Ûu¡J(WsULz÷Í*Ö²úîY‰}„F­å6yr‹7ÒóNùkv‹ÛiIBiz³<áªº@×GôÎv%¦ËOï¢x7UˆJR×§aeÂO³ZõìÉäı¼eïÌ­wH	À¿”QUÀ ¡Ãå2ŒÅŒà%ô~İÆ3û<…ĞËN§È^–;>¾Ñ<Ø;T§ÔYÌè-{†i,>w%öUê¦5)­[ÍÖ÷èÕ­ª>ñ‰Şå2´q*†Bğ'ehàx¨e¿Œ{ËJš_Ğ­äõö«?¯¢!h€C@òúv5‘ÙïÆàÕÉ[×ÛUu±}úÖt°Çú±ğ¹=>õGúÿr®Ïâÿ»¹U&ÿ_øµ³]-—Éÿ·\Yúÿ>Æ³ôÿıLş¿Á€û¹øÿ
'P&I¹=£NÑŞÏİõ÷Ë"ü¿ ×ßÊf´ eû®Óƒêk·À¼‡€¼‘Ù±.nB?l Â¼wÉçë>üóv«'ğİ€Õ‡÷äÂûˆşº	ŞÂÈ
pá¹Š¶Ÿ±Â}£ô0$Íî²ûİÙuã8ïƒdCfSwJ¼”Ò±æ¥kÀÄŠ<¹øÒGöQ}dÙÒGvé#Ë–>²KÙ¥¬‘ï;Á+7 yêÄ·ôé«zG_Õ9ùq~¯Â¥_ßÏÌ¯²¶_×§zñ¥; òú Ô¶tí{ ×ÎÙ¹ Şİƒ¯~+la.zÃšUk‘›ŞcøèµSÜê†Q± åÖ¤'ó~BÓ­Wz·QzÇJ½üÂüûæâ¿÷³wñb/Ò·	¢Z©bK	lös oœ'ÚE"#Fehî
	Æ¡8° ÇVXÇ5q5kè{ûh§1Š=:ó `ÃgW{â´ñ¼¯(!#‘ãl¯›×ÜãèŠ­şqe5<rô©3öó
Lµ||.dxÓ89D¿]Bä‰(D¼w	mOóts˜Òw°bÚlœ6nKëxl",5¶…·hØp-%}‘Òd¬ØjFÚkßp'F¢“6+$DÎ"Á€¾oÅõw¥wkğwşbQ\Ï•ŞUJ«ù°iê"* xÜEZÛÛàtVdiVğõØ3'±µ(Anp™8ş¡€‹Œ!Z »luc•Áy!ö]~Ä6¯Iœ[v¤ƒ‡~g”|KpßÙ°Şn>cú¦ddyR's1hY~Á1]éôİ8,ûX<8m§Nñ`{›“…Ş‡4ò‚#OÊ2qmz®yÁ>1S·,OúDï@PF?·WtpsÄ+zäÿW„”Y¤-w
ä…
¥Ş¼¾eÑ–€½î?@6˜çŒİ©êlÅEy•¨İÉÏº–V õ½ØĞësJ8ç^B"+Œ¤SËÈ)©¹w¢Û%4´Ò[ŒšÎ¹—)?|ËÆ ¬h¹5ñ"Ï<ßE%yg‡YAæıcá tOÇçÒ´[C‰ºQE&{õíÛÚùÀ°/kïß¯æcI GŠ^í­
3¯›ƒìÎ tğç.ôl¿¾YZ
›b•ë2«¥wÙwÙRDiµæ(Á[^·²ñaJ;Wà1øÎÍı,÷QvÆíY€Ú-WèUĞéİëÑ®"Bàöša«#vAÁZ»GÔõÅ‚hïğ¶Ä!]Ì…Bßñ|jHÀ·™<æfrğNB}³TÚc>DE Šl
5ÏšÆ°˜¯şıãUX/¤Yé¹F¤cŸÑÕOcîïiøÄ<ÙÂa(İ y·roÀ¸õ3@ J|#*Ò<¡q¨ÍkÍÊ8Â<Ã7…Lq(7ô¹ËÆêäş:)>ÈVğÈªrtRkêYêÙÓ,2N¸‰Ë@A$AÉµ5úñ÷•¼.Íçéİ>;]¼qWv°Ì¾Æ¶¼¾ÙšßÃ×¬í˜±ºÎµ½ê§lşµ£îV”¦‹'kÍn1K¯é\»è,âá™³@›¤İ±I>Ôç¼a>¦¶Êeuùë\B]¸
Eìº‘>%dBŠD<1UÂ|ü?2ÌÇ~¤ÿ'2ñxôYü?·7·7ÿÏÊæúV·¶—şŸñ,ı??“ÿg0à~.şŸ¼A¿\ÿÏ§EøŠÿçWÅò–çÀøw	‰ÖRQèºr¡ãØdK†÷â7Ad?J_:”¦Aûi8”–‹•ŸltÙGu+=ıî[ôjæñFÉ>{ÎEÓéÍÈÌü¾Õ:®oİ v8Ã€€æ½1ÍK¬—¦9Ê€¬¡ë`=[(Èß3àÉü‡EØ‹Ñ[zĞş”=h}ö²êÏß—6hhğ(#Œá@Eo•½Ãİ“ÖAëğ´±¿ôÉ½×ş¨|r—qk—>¹TÇÒ'wé“»ôÉ-ü˜|rgrÉ]:å.rïç”+t»¸SîÒ™v¸¥3íÒ™ö'åL;ï8™?BGZ¿fÕ†µÖ"Üh}X™*Ñõ1œlçÖré5Ï¸ô]zş„½FÅöÜŒ^£<Ş¿,ä£á\Nı(æø´¯øt…Å¾ÀÙÙ U\yUf<-“Œo¬×‹kxhÇ¶=rmš—Ì&S|æ°õæìM«õûÃ#Åæò*›Ïí7Ã°3Şrqà6Ÿ§âÏ»¿u|ÖnçñJÏ R(Ä´Rì\JPAt'ÖÃ*&QH(¬wQ3Öfì$j¨„á‰„°âÛéÀpkfÅ±Û;«²Š!AÖ›´ôfõãÔ7´È	àbÉØßŒÎ.>
ù+T]t_eÁIä”ãÚˆÂ½Y©âoobÃ#¤‹¨(É—UÀ#;Üy.¦Rİâf†6ÌÒ³¹:.J¡Ø§İEUWQ–Ôwb¹¡‡wûÂê…İ8Æ‚@HÉoèV8ş¡s1Jª.‡Yô{?ğeŞîÑáö,­ÕSš&ƒäËpïm‹GãğNjÚ;M¹¡†BÓJF‡‡DŞ1\¨ò:î¢]C¾Š Ÿ)°Ô˜¦A¢xè&MYİ4:'QYxjE<g÷6N÷4~8¨ïàT<“C±¨åŞÅÓ‰c6ÿtÖKlòşÂu»1ö¼*§c@	šÒE7­zÌtÑ_z¡®AÓ|‚§xŠp‹LşÓüÇš(®Â4Tíc–º¤Z§é$q7rwÈ
nòÈŒ@œ¾3“ŞŒCGmÂ…3]Íìã
RÒùÔyÇÏœ\½zKWï;<ŸÛÕöGù óoñ,0³.¤ÉşßåòVù)úWw6w¶*eôÿŞ|ºµŒÿû8Ï_üí_>ùó'OŒ;j³?HÑ„iOş
şTáÏÿ?ğşgÿn6ÓÓş‹Jü?øóï#YşHÿë'Oşôğ¢1ÌâÀğ|t ÆµüÊq[Àø·ø×“'ÿ	ó‹3 ‰K¼Ó‚Î³"ï_ğ¼ÿ1’}˜Ïæİ5?<yòŸÿá1÷ÿøoÿıoğßÊ£0ÚóÑnZP“ÇÿÖN¥ºÿ[›Ëóò,Ï|ó'şOùì7NÑI\<'`ÊÂ“ÑëD—§@q
¤?Ò…ÕåHA›B˜Çø>.<»ÅçfÊÙu:—¦›xBöLÿ¡z„0òı)è+ß½™7ç|2¡=9qÍnœ1pÛq­‡n.W†k¡ã‡+ÿÕ±ü"t´Ø6]è?rÈîhˆ4¯ìã›¡c”õaQîš¸_ë*àgeˆÈº¤¯
1îüˆ†kNËfEÍg#×Á>*ò:Oûb3k07Ûğ$˜üL|ãËCºLz%©5Qò™»ûûg»¯Ú§G{ÿH÷)!å:v<Ò¢J‘7•JÊ(¶Éƒ?b[ëá×—Ñæ`h^ÜÀxÚ¸¿4.—K –ÊËaJ¿àQ`B»'T
€ÑpˆC@ºÑTQc#Ø-Û†Ñ±+®,’Ğ´íRµ`Ï1?‰LÉRd¤l0D»¨bù?&Ï¨ö
úÅ)8 NÄÒĞêvæµáš*èo$ø{Æ²ïw×QŞ÷ÀÌ¬#–²Jg°+oº6ôÏ?•V§`(q³&ääÖ±ëÏô;¥¨i|"X( dXÓ!Á…<HÏÀ1G!·h«²Åãk›âÜ'¬où³…œ™k)³÷ë@hÜïk›¾$5ˆ :UBÉ„Nv@î3¸»ËÎù=a şöˆvæe\”¼LWÆK=p«À7
 zÈİf´õĞ‰²‚0¬èyövûug6Ísz&µkË„‰;qa	ÄTä&Z7îBzæh(r©®™c@ğá¯”ÇzH|Ãrk P 3Æ%úÿH—@•v·¬€Îì"ô,À¤
òEqËcyåEº‘¼Cşâr¥Òê§>TX%CP
³I™òcA4’€bğ»V˜·ÒØsK$Hu,)IEPT\Ébˆ^´k\.b¾Z-›'Ÿúé€Dšf³İj‘xõ~1}ŞõŒî0ÏIÈ½+Q†8Ù2üÈe8¿“[‹@±¹wÒÚ==:ùîŒÜø€¥Ã‹²İ?3r
nyr•¡dİI&¥b¤ÿN~DM[\"å>êEnÉwFZÊç"rçííû7ìYäNêÑééwíHû"Ôé$ÔŞ¡CvpäÖü`vÆ„FIøD^ì¶š¸C'~ÒİÜÿšw®Ø1‰x¦”_¸w¶†SÒI‡w)G8~.+†š¼ĞÜÇ…Íqãô[t¼°\ÏWzÑÁË@¯-P	]¡[¾¼•Yt"Œ«ñg vãu«y†ÀcğŸ[Å¯,¸2ÌßÏ°=sHn)3P?CÍp÷è¤…Z\tĞ¼«øWÈ=c‘UL4aß’.¨ÀCİy’#Ê1h,èÅ„ê!÷¤©4ì]EúP+Óm¢ˆ‘:²j¼J&©øÆq(›Oó“¡ñ<L§)÷›EŠz7ğÙ…âÑ*I™™Å+8Â%)®½Ñöh9±® 'GvFGgAáñV¾»§òE­äEhÎ0,Âz3‹9ù7áÊÆ<Cã¢‘×àãôäéª9Ùj>À)káˆPŒ¹GÓ¤&†t:$B'ƒ˜«gt6A[–â}>Í:Ò	ì¡Ò
gˆE’X qíH°I@g ŞœùŞ‰qJ³õ¢ñjÿTõ¯Idu½)¸8kU)¬M.Î¢%Á@¦p_‚s~„ïîÌsiüvw^»/ŸÍ›Çˆ¿æÑ®Nš†çë=	tÆ•FTb¥ñß
‰ry’´%Êï7ÉdîÖø¯šè„à]ÀªqÛù©'S•ÕaŸÒ`µ1V½ÇÎM˜Tx\&:R‚SO%*IÍO@fBó" ¸~o€Bìè
¿š4+«+·ê*gŞ~¬áq‚³Şèü%n®ÿİ†£X_]Du‹EÎ1ãƒéÍ±@êÇ¢¬L‚2*&ñ¡O_á™·µT—şUÕ¥¾èÎ¯ü¹‹›jytı×‡z  ©ép$¨VÇ£Õ¯¹G<H¹°”ÙVj‚)ÎWu$LÈâŠAœìA»wr&)ç\*JNÌïTÉø›ßè>ˆ2]ZCù„ÑÅ°!QçD¢P°Á—-xÖ xI˜Q²ÃLÈ¿Ñ4ˆ<&ŒátÄVÁwnÎĞ”ˆç KQNl\G†ß×òIöa¬UCÙŠ»óüK-æ#œZè[D}-?+ÍûœÅ`ˆM0‚À”ŠCËØ„zÛ\ˆ2¼êxöıfã˜£$eJ :1k[Ï+²µÛû±ìr]OÌNÁ¿cNuQL8iG³Ï£îCÈãQ\«bXÈkP™Å*—i›{sÄ
[{WiÌéŒ™˜dT&Ãni‡<ƒ¼˜ÔCJ#˜öO$uÒ£ åüiò92ùÌk&áÏCç
Î*Ö´‰„?wœNğY‘Ët§o+›Ê´ªæGaº@ŞÎûhİ~åòƒ­|äıUãÀP¨Üà¦päZ¶AŒÎØ…JÙƒ¿Ÿâ_•-üÛ{ggºº*!Q
Ó„oxgà‡d‚ßDïÛ¤j’r9+ae^ Â¢StL˜õÄz‹Båx#‡[#U‚`Î–óÒ@°µIÏ¨çÂcM\scêbªÊ‘šŠÔµéßÌ
N·ë¨›`k]ËGHÕIÂÙ"İ<aØÂr+>œ'öL1› I¼L4…H—§wˆRÀ%j‰ñ}=âõƒú‰6 ‘ˆ2”®	>2¸;ã˜àóåOc4à‰Ë½—õtî/L¢«—å8”Ä/’ÄwêD…F¦‚ÍVK¤´’~Iº<Ö™cÛ4—6JÌ•F«ƒ`ªèz…ÎE¯€:Ó¦»hÄ|ö£Ä)(V§¨ëû–?Î³61ái5¶\%(Ö±Fªzø<©zGY¥.{ç «nœ±ËGa¢¨Z‘Â
‡.ı„pûÍ‹{ÑTÚ÷”¶Ø¶¡Â½ŠP+d·àÉŞ&å9!OeóË¯’ópN	4ÌûtóiJ^êâò'äıò+îıEòÃ„UbF—ÚÖÙJ©è"6¶‚äUW±‰KX%t›²†UJD×±‰‹ØùSñ1¦=42öÍAÂ²V31RéÓ¯†š˜³g¤_d»õ^Ğ²©V‡`[‡¯æ‚…Y•)Ï@gÁÓè¼ÏêÀŞzzÁ.·a!}éé‘BqçT^H¦?<;98$dÇôHvİå9Ì®¥Ï¡LÜ˜—	Ò#ùãÁ<¿Ld;«óìJzr	ÅÛY+!Ó«Pl5^NkJ]Wv£5)R+¡¤O("-’Ø¨¨B˜T.E€,ò`9LOÈ*®ŒeåéI@¸&ÁÆô¤ì í³Cº–]•ò¦…ÆÀıâ^ò Ä‚[ùCÑì5ë©èûØ½¾8¤3dcŠÜô	¿ÓN`X”;=´^–5ÓËªÒô]©ºïBò½åˆ+óJèø¯µçôµbª}Jálf…/.¼˜wà|Æãé°S¨´¬`=arõ‡õ ä!#ikÜÂ&ä
}Üãö\ÚØ¦øDBW4°ZÅ¬'3qØ6X¸Q)Ğ¼(ó:{ÿ©MÁ§±¿×b>R~Ú~<Ä¼·V\Ï×‹ë´õÎòaIŒ!Dî“©eW°(•ûôÁp{ZZÚĞû™0šä“ûH(Ş&}(ˆo´WË¸y‹ÛK&v«ÚğB~‹Sv\`~Ü`J]áC~Şƒ²á],{'¾V_Õ¬íñ<c`p–KöSè(ÓW’«üÖà]g8tìcà¿zN+‹TÎlçšò˜ˆµ:¨úaz&dò·<œŸ^ÉJ.„.V
±<èØö>â‡b;lhøşš†ƒÁğY¤Eù:½è˜'„áQ¸=Ã§#Çğ0/[sMºJ).:"dsZ˜¬XĞWHìâY<·Ë1»6á›ÇÛàƒXF/ñ Hx O–ç#¸ğËq’Róck'Inug5¶43•°˜¢Ï·(’#lõG)¯…¯Ug‹½í:@ä5è—€|~?$ŸÄC Q
ŒÎÂ¡Å³p±d¦‚ÀX°`ÔúÜß„[Á‚NÙe0 ÚØç§´lÇ.(Y(ÇÇ½6Ü®è³Éœ'ñÀC<ßê\Òår#’»¾eaUèT°•ş¡PÌ<M©6N¸ÔÌÒm;„>|×`Ş ÏF“”1ˆ×óQR“7AÈè@<t¨ä‹…D8Ÿ_€g5"·4óÍè¼"]Ø¹¼ıç±éa\AÍãÉü ú“‡Û‚ŠO¬ØöKÙ={qÖuÌÇ#OAº+ñÜ¹Ì6¯5)-pğ‘\wÖ>=™eKÃ!8M€Û{Ñ®×Äƒªì“Z(´ŠæèÄß|óMF±‰ç£š{Òy/
¥y¡I(ª\ì¥zzG Ô'é§  &.œ“Ót6²¼û’ÍGá!©ÒŒlé½4S›"”c“‰YJ´Ë¯hîñ[Àÿ	ÒséZÍ<‹§*ƒ®O¤ğ¼û=Ük‰Ht3Š4 Ò¼šØ¡­);´5m‡¶.okYŒˆ(Æk2e0ŞAÔQÌwÂQÎFÜíšWHB9<ê!½Z„PÃy¯BÂ;/RµC--h!è&× èĞæÏ‚°‰:+d'qP”yĞ95$Ip¬_„Óõ}äwà<‡4ŸağÙ¹xbï³pÜâ˜L?%„s3Ì’Ç«ÂC[ò˜Ò¹e×R75ÅG…–5Åz(ó“_X+j£†^¡ËxÄv¦KQ ”ÃZÀÏ–¯À)‡‰$$•‹éùğ¨Ÿ†K1ğ§(= ›¬iHE³üPÆ &IÏ_¼äZ5E0”äÃûÈº7å¤ûšBÒx>ÅÃ<ù¤‡@5µ<?}9ŸdKU*ZºDíLïrëBHÔTfëØÔì²cC´KBŸÍŒFD~Ì†Lb¡ˆ$w‹xâ¡0–T[Æ]°ÃJ"œ®»EÿƒŸtœáøM“‡|Ÿ¡|ìäBba™Û#ºâè[ıî Ü¥¥‰‡7ˆoÛ±ğ<¬pÌ1$5ê1-ÌêÁŠy,™ÏÔnùÌüŸ…Ö1-ş+ÆK¬lVË•êÖN¹Rağ£ºµù„m/+ñüÂã?vLzx«ƒ·(.¸{ÿon-ûÿq®ÓYìà2sÿóø¯[UèÿÊöÓÊ²ÿãÁş?i5š­â°» :€O·¶Òú³¼S­Dú³ŒãÿwñÏ
­üéR¶ ®.-÷iÏunnµe_ıëı_´n­²k¸]ëéBiGÜ¢=ğ`ûŒâö„Z*Ö&œ½1¬"Á§¥Ş(ô«ã'pÆàõ:ÆÈôŠ¬1À¸¯½¾vÀU„SÅ:tZÓo‚ğ§Ø<¬ähOó€ğ6„†®ÎĞÄæ=hŠ?æ¡7Ø5}Ç8¡¶‰‡¬™7Äı'jñ rwé:Mçq8E$Õà²$~Û­Ñ±Å¯D„6Ïæîâ¹]¨qàPÜÛ-şÂeİ5526%5:Óvf£}°ÁN»”éå:Œ`W®Õ¯ûV§(Xa˜S\£9ÏrùŠÊà½k*(f2ë’iÖ±8`€7’n¸³ vÓúzÈt}]eƒÇYÕ"hŠÈ³Äì|lwh»]¬ı‹è4´mx¾;î ˆòdİ¹eÃ:Ğ„“Ô§Ğ´	µ`¤akhÙø÷!iL7F¹Èî*á^40œ+f¾v-ß7m,€qY¹;7}bFŞ+û–=şÀ^üëùÀ
qlRT]DÊ7, 4•;1¼Ñ¹éBÃ-ÌÊûR-Ãf¿3=ï¦Ôö]Óïô©~jÖxŞ“FİcßğXJõ°:­´1‚\¤»Â`°†ÇN'|1CÇuÖBËÒÇõHdYìÖ"{ƒ(‘ô•*
¡s7 Œõ‹êáıˆşÓ?ı ç×ß¸ÚŸJì-.Q;]Ï|a+%¯cµ[ŠWÆ
ı*.T*…ÊæYe«Vı²¶ı%<9Å¨Úh©r.¢ñq±èÚk!HÊÅJ£™mÆkg'¦»W7’y[è_½‡¿ÏÙ7Šëá³÷l"<%¬ „f}†Ğ†Á7´u†éÏ™v”°ÏŞO¬h
…Ğù+öğûf×(€òÃ®õÌü4pWéàL›26İs†îĞéšÓ EhªBSİ?W„";À)„¼L¾ÈC•O¨jÚ£i¹Ô1¼0ÌZ¸×7¥-ì¹HC)Y“g‚Ømùâ´*º¼
Œ[“TENN®"$f^Ğ+l4Æ-áwQ>€†aÌ“”Hæ¨Xp#´ç\ø¡XÒ6DlóP
{Ó‘6²wØŠ„ŠÖ=uÂë§²Ò°H©XÎ‚É½¡lZw‚h`Sê¦¯‰MæŸ&×9ñ£¸¿~Ñå›QÁ‰aç`öÈdöÔ9Ëü`ÎB‘ôy(ôõõ#	ôâ|r~QKÊÎ××Åˆå1Ü‰o„š£²…´áÊ#”î&—^Ç)m­I=…Gñø\99yL!¼‰– çœûvñ‹Şb18ÎC•')> AÙ¦Ù+¥‘èì(.°\´¿ªU7ï=ß½¢{NÎ¼ğ+*€
Ä8×øl.Pl…»’A$#`õX(ûä²¯¢±íïVVe/Ë¦*I ‰JúIE‘”Œ§~BsÕÈöÊ2^}2/ñ»ä^üÃa¬©éL›Â-ü;i1 ÍMÎ¿Ë£¬#9ÎQà†§¯)àåL½&à…»ÔŒy‡ì(ûfÎ®õ…-½KU“º%¹ÄVj¡«dİøúÀ²ã÷>41ŞtF\SuÆÁ~•)|ÓMMá»ZJŠ¸kGlud4“w`Í
–Á(ÿôW|T&Ë]aù.‚ë¼”N)e|¦>ü©]ä¡¤w€óŠ]5'Õ¾âAYíİé¹÷útÓ’£( ¤ÌÈ‚‘aùtô6RŸ1®7Š|ÎÀáSm'úE\KIçvÑ6`uÌH–ë‡—zÃ„ï¢áˆkòx§éM¿A»Ìf9-¦[L)¬ÈéµÃ¥€Ça2x
9èÔqQôfzR§æŸg-­Ã&=Mœ¹jƒFoEx¾9bÆ…oó#}	DIMÑx°çKpXËÿó
äãAÄı2¨¡˜øûÜÄS<l=XTˆë.R¸}]Õ>˜;ÃfŒÌ-¼‹fÏ=§ İè­ .+1láöÂíY~J’êÙbK> BpM —Vù¬îŠ¡¶¡8g•q¸Ô‘Ö·Ó·|“,i™Ìó›àøûº4ä &‹6àkÇ½ä‹)tûRµO®–
­7°#½1™)âÃXUE¦;•P£z‡kY>pö¥‰×ÏzÂ1õ5ß”ë:S®ëÖe¢ıp#¼Ë›ÛzÕ•Xmqe>£İ,q1h¬z¬ãñÅ?%‚¶_¶‘ÛD%†\S/²£ ¹vé]ÀD¾Ec~W´Pôù@Ç4PëôÔõ0zñÌy|å•L]ô\ÜË³áŸâa¯\›€X'ÆqÀ®ÜCW¼y$ˆ¤”‰l„zsB÷3™Oü–¸Èó‰5M.Z0/&@Æ‡ö)š‚‹	zó'nu ã£0\ı‚Ğ„U˜Ëı9»¡ı-»ü¾5O‰ m„¯°|­Åaª„—v%¦Fe‘$"wEZ†İÖ1ƒI"„kW­OÃ¤¼3Ñº!0…KÀäÆï—ç¿ñí…ğSPáfiN!hà¤'(Òbhñ;ÔpâÊ'mè(Cñ¦w<…aèû'h¡çwğ{’ºE¶ïdù ˆ7aH÷ª€ÎQ—9‰~
Ê\=HÆ<VsÌ/`aÅsİÊ`D¶‘6Ànç*]O¡ê% ù‰ê¦²|ÁBéÔËp@+]MíbÚM“áÄ1ÆMƒ¨ÈKØiHÙ¡I#ZTßàN[»(/æºnN¯òUÛ«!é¢tˆ4:¾£sõä'&—R3&Ë«D©Å&d½[&ªVM|,×é:çA”|S[`ß£›.Ä•}ÒÄÈ«N2Zp0vÉP_RµjÚ,²W~–eåÖ5•Å ½˜]$2•ÉHNDç^)ÚäT@ó¢¦…l¨‘°4…ı·u¥BèXPÇ®Á¡	‰'<ûhuÆ¸ƒÉo	*MÔiÄDjÁ|µ˜R™Ùó#Ä•]P–Üî‰ã:eµ×Èê ¹ããÓ+·’É7tÚ!©‡ô‡p(Çh8º¥ 5V¦-6•›é­–"X¨¥á}ƒª%ôã·1¹ÕúÄ"@•Ê%P)ò‹
 Şy¥øA­TÏ˜\©v-âTŠF†sX°ÛÔª mŸ%µï^•
VH*³¯ßÆÃgØ¤ÕÂ~sï1îG-ÜSÜqôãÒ,è©ÙU‘+L`ı€òÂ+U6x`¥İwüÒÅğºR-V‹•âf±ŒÁÅÙ+›ïš…Vº@š£&Q©@jq“£q'¹İÁ=r¥ï»—•â—ÅòYek+Ræwx©\p£3’9#ššškSC-UB'ì Å1K‘ĞÚZH›º"è)ı*n1Mâ…IS—Ø£{øê‹0h4öh<q´¡ökùı0H>IµR¾ÎğH+áPOtcTB³@ÀñVŸ³@_ŸÀ%O)tôèì:Mö’p€Š’¥áĞQ^ãè*13e¦İÈí°“	 5$N‹¼òÁôÊA’+ªí¾3[Í´x*ü¯ÃK¡=K.ƒÛD'jóçÎ•Iºv²Í1˜Ş|78!H–À†bŠ ìêÍš˜×¯Òì+·~…²Ç7.aéÊ¯âo9 yğ'.ÇÚÁ%u€j+:í¸‘Öãò°ô‰+õ'Äâõk5ñp˜a#„)‚P E#u%
ÓÁEâx%‹š&¦DûJ?&½˜D9‘WÑŞc=%²ğq%BPá@Ñ°?Pº^Š¶Æèo·;á²_Şg¼¡±N#!Ÿs°nr	¬Ú¥"v™°”¨¢;Ö{¡…‘û¥ú&7ˆ"=ÉÖdtúñ½ÈmˆwlíckGq7?m"¾°Éşlˆû)µK6€ø+ÏÔ¿“Ià¥T‰5©+º˜dò#‰DT~#ër¡Àro€û —+F·THçç@Wà¨9#P~Ä<„™ÂŒ›¦ğ.vÆ¾©¤Æo³VÙPAúrÒ—á~;oFÏ,`²pÓ‡	\LN&~œB?F°ÈÙop
#Ÿ"Ä+ËI…ˆßğO^MÈ·IÂŠíyŞd•Øá¤ü´sy>î!ÍP[D«_‘ ‘ •ş¥D(øx‘>÷2‘
fˆ·/áßñù*Ú‘¡B†{ÿ—¦û~­ïû#¯V*a8Âb2;Î°DƒT“hc¿@¥¼R¾–É¬³·­ä÷×ãÀ¼ŠÀ1ûîÀò¤CH‰gÍcqo|>´xÀJ½CùÊáö­îVámv$«Ğ¬Í“ºll“ôCcrÊ”™7˜ôtªËEö3¾ºaÎ9í…0ÅŒn¤¶"Š0Ãgß z€İõõuÑ €EÇí•Du^io·uØn è3ĞÏîxş7ér°Dyîpş«\Ùç¿.Ï=ÆñgYH“Ï•wªO«aÿomãù¯­­åù¯ÇxV~…vÑÒ%9fÌ¦MÎø ¼Ü^·Ær Uk¼Ü`ÏÇe£ŠÓÄ¨‘Îˆ&ª_³¶˜ŒÖ7Ûì´m˜=<¯‚Kx Z«_m°/+ÛUör`øş¹;îõ6Xf¬LŸ- m\ùSS73áScì÷W|jûæZ$ibk ‡äÑëÒŠ|bú­/€“”nu-?(Û7<—ïŸ>¿áĞD¿°bBüÀ³œ˜WÎN±,òÏ¦LÕK^W(éÿBê:Òö7£d¥â(>H4Ç7=‰:éôÂ	“ÀÌ	:}`\T+BİuI±YŸ¨‘À¨Î°yßÙIğ€Zì[]³ojğZùªXŞ)VË•§Ğ<1LŞ]*O0ÎŠåQİ×³‡»Ç¡scûÆŞ¯'õ×xOÆÜ—áSÚ•úê»ñoßõkï®Kìm$zÉ{¶*svºıºØ)ür^W\ÇÂä7j@ÖybT1%C'š!zŸ’·Ÿ˜WÉ0H†¶¾0§s¢¬a3ºyF&Céz?H&Ñ5&)µÂì æÅh“³¶—úål-RŒòÍ½“ ÷+ı­0Á{±xn
€ÖÈV‘@Ø¿c VDøp\ÁŒÌp?F±
ğúm)3á˜{@ rm,ècKÒ7?ÔWég$,ˆ|{uL^)3¸¨±Û3©W6f˜ŒÍ‹ç¬™üŞŠG¡y1“«nä2°Õàë€¾fÕáœU¾âp<r³–K<¤j¹pìÄsA*ä
²Y¾1faYƒÔLÁˆPrw&çæÃ-Ì2A#±§î<	œ–I¡G ARôFõÕ ÚaèôyªJQ~ƒ/ò2™íßÇØrûûÓV}—`¬Àdø‰Î¥™ŠõUüĞeÅu`ï3pÜº1ö C2˜óà»Ë|7HòxR4o ²Ã8Ï­“ımI°P/yB~@ß0ê«ÒşÅ¶Ë“{¸ÄmraqónÅÉú¦wÍÑİ (ö°Šw7¡¹N‚¸²œúê•íæç©ÆÄã‘Ríe}U³¯
Ò¸ÆÈoß ‘¤°j‹.|ävc (``w›‡,Û±ëá÷u³â»Ü„!=5°b«˜xãáçE>CÃ½‘hu=‘}ş3ÑüˆE‚9¿P ] W{M±$t€’pÃê Ğ¦•Ò˜Üšü™ŸÜœÕep¹¹>hÿ!ÑH@ÊyÖ1ÅşS®>Úÿ¶··ªKûÏ£<ñ·ùäÏŸ<90:ì¨Íş Wâ˜öä¯àOşü	şàûÿdãôôDüÄÿşüu$ËŸ…é×–Ã@fq`x>®åñÊ•ã6füáÿ¾ÿGü÷ö_şfíAí\>‰Ohÿ]ÔèŸ>şãöÿíÍÊörü?Æ_]\Óú³ºÿ¹³½´ÿ?ÊÃã¿)Ç¼2+xœUX$&<Ú®ñCU|®fÅÄM%±¤n‰Ôğ¦ULİ©ÑÛT3+w2T0–á^$5¼N·†÷äÖğòİŞ‚»Tg}’¹Ï·å¿2ş·¶·Ÿ.Çÿc<´`ÑuÌ¸ÿ¯ôe÷—ûÿ‹0^Å¢ë¸Oÿoï,ûÿ10bÃâê˜µÿ«Õm`€-Šÿ[^ÿGy"QbRÇİÇÿæN¥ºìÿÇxôp=‹©cöşß®îlRÿoo/Çÿ£<±pL¨ãîã«²œÿçI‰Ø4×:Ê“×•òÖ&ö¥¼¹õtë)ö?¨ÿ•åúï1¦Ç¥Ë¬°—â²­ ¦‡İeòîôğÒ¯?q†q;ÁUUE$¬W÷©éOêGQô1*èx„A;{®1ô2~³ş]ËÑÇ"+FWôQº#©÷ fOL¹`kb8±È”¿œHbŸ›E—ÏŸäø‘ó­ãîóÿvµ²<ÿñ(OjüĞ9Ö1eş‡õÿNu9ÿ?Ê³<ôñØ‡>~²‡=ö¥€H‹fw‰w9»!G<öŒJ±R~Ô‰a¬Q¼ª¬1x÷äŒ"°õôŒ"Ş5füHê#^%åÂØ —¡EáğKzãXß¦Ïú~–Ë—™Û¥’÷}’ÂqÏ»)óÿæVlşßzútg9ÿ?Æ³œÿ—óÿ¬‡=A@|ïœócËù^AaŞğ®MórpÃ.ÆƒàÆoE`ÜŠ|¡œoå ‰¿bëğ_È'b¡&«±+9XÁg/^íïãõUğá·»{n;}öìYp{“Ì's«Ï~]É,€|]ıXvÇ¥ %Æç#by£º±¹±µ±½ñô^äÜ;Ü=i´O?ª
ÓëãQ²Z%J®ÏJ¿à>˜»ìsÏÃŸë™r]Ë\ê˜¦ÿmÃ‹Øÿİâşß;´ÿ·ÔÿÿÌmÀ¢k¯¦¡íÙ sWöòóf]ÖæŒ…¢â3jgX;ê1E;%~]äS´µb’Î¶¡«k³)¢±©™QŞ)-F ~€İ1¢’É<•b¿(Z˜üò
tÅğÒl0óÓ…«zmŞà8ìøy}*µ4ÒPE{“å´ áÕRj„(¢Š. ÕkªeôaZx±Íïü'Ùè•íƒ|‘5øFxiÇë¹Ìà¸·§A	Ã0®ÿ¹y÷>éB?Ë/fV´ÜâŞ7%¸xMûî»ëŒâ|À#£³¬h¦ø·© Å©KğyÉ„
’;Cg»©<~M´¾kâ½iWHüYkéŠâÓªá·4*PÅSÓ&î Ñİ!;	=A€ç(ä°c}¾† ¦'ƒñYş
×;b%V®IóèœD¹+=[£K[¼x?sqèŠqxgŞ¢ xŸQ¢ˆÖßì·¹ G62oÛ÷ê¶éã=NEè§égxqX4‘eŞ
¹ü>sz32ëüFšîß×ÅE†/q ÖqåXæ‡AŒâèÅ‡%¶èVğ=|÷dôêbx&DUëƒÙ!»{Ù±İó|ßéY¼*sF÷€uNğœ‘
ğ²»†Û=û£±_®Dû*ĞIˆ÷D]\s×‡ão°AÎÏ=§ßåI½puLÑÿĞİ/ğÿ«‚î„û›Ëóò¼m¾Ü;l½ÏœĞm ¨È¼#"UÖAáÿeŞ¾l¶NövßgÚ­İW'{§ß½:n6N[í³×{³ƒïxÌ‘ö«c<·_¿0Ş|½È–Ï"Ô»>çXÇ´ñ©áøßDÿÿí§;›Ëñÿe_™6ÎßgĞç±¹“øAdÈàäpÖÓ´€Ïıòyè3ıFß‡×1Õş³½Ø¶·¢ıçéæÒÿçQ¥ıGµÿ$Şh½4-ŞŞ²7úlğÈ3ùÌ?Il°XP2ã-Â4CM°Íı¦ TØs”	?k»c±† Å ~tÜ:l¶Ï‚äêÙäâJYİøS‰\ëÕéz¦Œ>ËM=….†šûç±Hª¦)%Q´à‰‰'/îPÔ59kK É–¡Ÿªi(rşW\Œ¬]Ä„¹Ô1Õÿ{s3âÿµSŞ^Æ{”gé¯E;ê¯¥‡Ÿ¬óVS\¯ìºª9)o6IàßhAŸ~©]™.°Û©ùüòá¼8n/ÓíÔX˜qÎqO¡3€à·gØÖä¯™„CìØuš;½$ØÈÁ?Ç‹GjêvåÏäcÓ‰:2ÿ|'ÈŸ[4-Ÿå³|–ÏòY>Ëgù,Ÿå³|–ÏòY>Ëgù,Ÿ9<ÿİ[Z4  