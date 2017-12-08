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
‹ ×˜*Z í}]wÛH²˜óq“sù”ä!9çœ¤—æ¬D­~H²f8¦wi‘öhW_W”í;×öêB$$bD\ ”¬±µ'9'Ék^ó›òîoÈHUu7Ğ€²Hy>Ğ3¶	 »ººººººººúÌvÊ–œ*•ÊöÖ£Ÿğ+µMş¯H¬ºQ«Tk›Û•j•ÁŸ­Í'ØÖ²Ã4öÓT|×šš²ŸOù.Úşû3IgĞÿî¸w
ÍÆ¾á÷—PÇôş¯mn=©aÿC÷oT7¶6¡ÿáÇö#VY.‰ô+ïÿÇ¿)#œ™~?÷˜•— Za·Wg……ƒ=ñì+³gû¬ùr=û¶cù>kYWÖÀ-'`¿eñhäz[}Şê¡LÇ´.,Ï²ıÀ3}ßbµoÖÙ×Õ­{90ƒàÌ_\¬³ÎµühyÓé-ésh<Õ™6ààcsô]O|ìÖ¹é°C«ïl¶êZ~‘ùôÎpéİA £ë¡t»gaéÂé;}Ó¹°zÏo8ù[fÕ­fÀ<Ë±ueû¶ë$²È<ÛÑØ¹¾Å!=a®g¸ìÂ‚ú³hšÓµo!3}æYÁØa]·g!%ÜÀò%6'}èGŸÃ€_CÓv7lì[=vîzÌr®lÏu¨S¡súî8`'¯[%¨>ŞçĞ­PëÁÈ¯—Ës|†Ô)sŠù(â€Å­…w+‡}\åz7ux¬TÊ7ÌdOc QÛuìÀ6ìÊòŒ§Z3ªUÌ³-ó4{?€B3Zğ3»sÏ‘S ¡Æg‰í@¥îĞşÑ ±û@ÏYh°¾jœ¶…ÊS½”¶	.pè®w‘¿%ÚNÛx<r®cd<Øks0¶ü{4(÷º}ÜÙ=<h@oæZ‡Í££öA«‘?9~ÕÎ³9Ócà]ól`±{ÁÎmøaF€ıü°Ónä_4÷:Ÿxã† âhêìïœ4÷ÛÂ*r¸r†*ÅÜÉşÑik÷¸½srxü}#_†£<½|±»µ>jnËzq£PÈç:'Íã“ÓïÚÍVû¸‘§'O&t5t[á£Rû-[}Í9ŞòİiÌ²ÂZ>·ßÜİk¶ZÇíN§<ı×3a@İ~®}||xÜ¨äT¸Orp/ÆN™ê>ÌÀÁ-vô¼Ø+ß¼°V‹ìc\¶¶l40ox†×ìr!15½j¹ûşËï¼8du^ñz¼“ß–úW+Ùì)îİà‰ƒö3Vj±§ FôZğûşûFûµëõ^ ó?cïÓ*a¬ÔOcvªœ­89ar‡§	Å¯ÒŠ§Œ”	Å½´âİ¾Õ½¤éÇ³F»Kri ¥İQ’ì{…ì[g]§Ñ²=«‹“Û7h7\*éÃ6¯H–L(èLğ&!>%§•Ûs/H<Áÿqïğ%J‡[Ï>goáeõ–•.Vaï¿ÅùİÉÉfî,Ói:½¿ÛÏWøX»¥ÏÖ æZ™/&ñÒËW½?·s·¹…Ïu©CkŸ3—Q=$…e8ZÖP'ª¯s©»G¯N`’¬~U_»McBJ ëš—ÍÖ»Áà\°3şéqÚvA^É	Ô-¨]é€AAf&slĞÉ¢vƒƒğ]g0¹…}’‡–/2v²»ß>>Ú?‚‰¥j	Ëÿî«ïK_K_õN¿ú®şÕ~ı«N¾øí·JÑããÉE…ivÒŸQïáŸ°V­Ş|^Í°Æ¿kŒ”$Y¾ÙF@&4äàÛ<k0¡ÄƒÌ*Õ…iy©nßÅüNÀ8ˆòìS`Y¬d*ã1,©«é`Âl0¤äO¿oŸáÓuÇ=aÕşğ%\{®VÅ][¡{9³u©-œNËª´4ÙÚëXIÙ´Àn{ö,­M?1ê§#9?ñ–!ŸC©N¨±¸è¦l<1Òã;X‚r4kâKQõ„H®¢8³WŠáœ‹ÒfÚ„ö¬Š«ª’$*doC3Ùh1Ú`o`I|ÁÌ¡;vH7½‹1.‘}ƒu`piZCñŞu=Ô;ô¡VQ›·
	˜­âÔ^œşÖLøªVBj°húP§ú8Ñò¤ùü–AUğpÜÜÙk‡ÚÍéóf'F8 ôÌZ©Õã[Ö^šW¦=@íQkOµ:ò;ôBà»}¾âÃvid¿˜köØ»ÂÇï=Ê†DR·1³½fû6_œŸCÃ¬Z~sfù¶ç…izñ™­áÅ©w½±ã ş"lB]w84\í3Àõ|EEO…º1ê¾íû¤Y%µl•£çá­G#İ¢¨9¸Àq,.¿ƒö,Ñj[ZŞÀBY‘pHhÌ¶5'=a +4ÄakŠV`GË#•îhâ˜0>Ë±âex*C~Ÿ*¢·ø9ä‹,ÿo¾)ÆV*D#Ùµé8&óAï›ƒ«ÓßÏ;¯œKÇ½vxÓ'è{%Ì,%·	á¯ãtlİ+P«-T¨ù˜‹FÊ‰7Ô@Ö•{ÖUÙêä‚ğÌ	óØá‹ÅX0¸1DX"ïoïhœBÉ	LÊ8VŞMNª.2W]tµ…Sü³Å%]‚òFZ®¤J§-+kÕp]yn3–q‡ŠCôiÆ™Œ.ûô	¾ü†•z±Ï*‚Z­Õ
Ô†uí!Qp8)†ìœÁ
«ç(m¢©§Dv·ĞØ[Œ:ÖÆ98Ab='–í9¡Ë¡A~ÊA§Øòt7`üås|Š”A+¹ô{Aı‡ıö·ØM×,¯Ø´æÇ¬¤¹°GtºTÕ
•µi—;Rç8á8÷/„e9¸}Ó¾—[áşÀ3G,¯5l³’Çµt.'¤P]±‚$àD@r1³›ÅºcĞª2§‡›)yA®{áx»°wl«—y.?œĞÄl8@
L˜!@»_wˆÒ¬e×[õêíº‡Ú^¸üàŠ,¼QYàKn™«(B÷ªÓ‡•ov‘íß¨ŒŒlzx¤y©ÍU-ÌÇíhrü s¨¦±	y½";nííî4OĞˆŸÀª]Ô¹2Êïeck¬°¦N´
¥…Ş>”	#Alh‹EmTws†&l`Îìšƒ²Ø­çR"Ï
:h!%Ø3dÕ¿­æ0·³~uõI©`N‚0{îPˆÁ¦Ãüi+ v[,AÌC’&}â›"b¢tÊH9!è&Ş)â'Âfšü	'‰kÈu…yâÜ—YIÀÖKùTkïm.…{e1õ% (|<zÓ¹ådú˜"“ù§ÍB›ÉÎ³`L‰;R1)Óşâ9K%¾m[:÷løéŞ8n	ĞpĞï#ÏY^`[>b
¯8¢†´ }şZmKm(d<Ğ ›ÀÔÏt¦š‹Ã±Yõ»sùfUË.xÄÛ¶!â;ÌfşÀ”còıpÜôÃıì’ÍVüòŸåRyEåC(õƒ“Ós³{	yÙn‹›¤‡ãA`pBåCÏv…5B`}P.”?|ë—ß9eVşövlç@ú©€ÿ,rÕ€©)QKŒŸø$¤6¾mñXl®t,ï
V5ÈxµOV/`]ØtÙJ"‹Øz´zZİE)@”¾ƒe‰VwÒè¥Ë°J\İÜ•B -ÈúbAf¢ù‰/Är¸”±q!µ×jÑ_p"Õ)ÃÅJ
¸ÂG[¬šoştzˆ{«æõ%[yŞ~¹{ğñ¸ÓÈ¿sJï`…ô‚~æ¿İ}ypxÜŞÉ¡Qı–/h[¸Seeå?7{=ú ŒrµPÃWï®`-+ï•ÙGhÔjaƒ¿nófÀû¢€Sù–İâ¶ÀGZ’Ğ;½ÇY‘pÕF]¨Îë#zg«šĞågwQ²›ªD%©ÎëÓ°2áO²Úüñôı¼¬wÖ;¤à_Ê(‚*`ĞĞÀárFŒbFğSzG¿nã™Bh©egÎSd/+‚ßlíï¨SÏÄYÌìmgi,9w¥öÕÄ9LkÒ¤nM5[F¯nÖô‰Oô.—¡Í1b€?)CÇC=ÿ­`Ü[VÖü‚n%¯o³ßüxı A’×·j©Ì~7¯MßºŞªi¬‹íÓ·¦Ãõè"Ö¥/íñ©'éÿË]¸¾ˆÿïÆf…üá×öV­R!ÿßJ5óÿ}ˆ”ùÿ~!ÿßpÀıRü…¨	“¤ÜQ§hÿ—îúûµÿ/Éõ·º/h;çöÆ úÀÚ-4ï! duíó›Èˆ°è]òÅºÿ²ê	|g7àõáı¹ğ> ¿nŠ·0²Â=\x®¢g¬4dO•†Wó»ìŞÇ_w~gİ$Î{ ÙÙÔBéDóÂÒû¦=`bE^<ó‘}PY–ùÈf>²,ó‘Í|d3Y!"ŞvŠWnHó‰_æ!;~æ«zG_Õùq~	¯ÂÌ¯ïæ×YÛ¯3½ø&; òú Ô–¹öİƒkìÜ ïîÁÇW¿U¶4½aİ®·ÉMï!|ô:Üê†Q± V¥'ó~BÓ­_~·^~ÇÊÅ¥ù÷-Äïïâ%Ä^¬oSDµRÅ–ÚìCçÀÀ<Kµ‹Ä
ÆŒ0Ê,Ğ>ÙŒCq`a=f]ÏÂÕ¬©ïí£Æb(öèÌƒ‚Ÿ]eì‰“æóF²¢”ŒDÓ½İn^s£+¶òçÇ+Ñ‘£Oİq ˜War¨“s‘ Ã›æñúèš"OD!â½Kiû8/@÷83)‹!¦­æIó¶¼†Ç&¢RcGx‹F‰ÖRÒiÒ‚•XBÍI{íîÄh@tÒæ…„(Ø$Ğ÷ÍX{W~·
ß!ÆZ¡ü®Z^)FMSQ!Å“.ÒÚŞ§³"Kó‚¯Ç¾5­E	rƒË%ñ\lÑİc+ë+ş+
±ïñ“ uMâÜvb”
<ò;£×·÷# ëíæ3f`IF–'uÂ1—€–çGÜsÑ•NßÃâ¸‰ÅÃÓvJá	lo²ĞûH‚"@~xäIY&®@ÏµÎÙ'fÉá–ç¯>Ñ3”Ñ×»0\ÜñŸüÿX@YF(m¹S /Tê*õõe(‹°ìuÿ¡Òx´Î|wìu-Ug3"UäUªv'?ëZ^TÔ÷C¯Î)Ñœ{	/Yi$Zşœ’Z»Çº]BCkr‹1BÓ÷2åç¯Âoù”ÇZnM¼ˆ—§~à¡ƒ¼³ŠÃ¬$s‹ş±q zÇ®piÚ«£D]¯!“ƒÎ½òömıl`:—õ÷ïWŠ	‰$€E#E¯öV…YÔÍANw :øsz¶ß@ß,í›bë2+åwùõwùrDyå"ÊQ†§¢neãÃ”v®Àcğšûiá£ìŒÛÓµ[®Ğ« 'w¯O»zŠtˆxN€ÛmE­Ùkíîï7Q×¢İƒÛ2‡Xô`0—J}×¨t"Ÿæò˜›ËÁ;MôÍRiù(6,²¨yÚ2o„Å|åw_W`½æ¥/Lä‘bL|FW?¸¿_|¤aJx²EÃPºònåŞ€Iëg!„@”äFT¬yBãP›×—q„y†o
YâPnäs—OÔÉıuR|¬ä“Uåğ¸ŞÕ³‰gOóÈ8Ñ$)‘%WWéÇïªE]>¤šÏ'wûütñÇ]\ÙÃ2ûÇöûV/n~:^³¶ßcÆê¹×Î:¨Ÿ²ù×6Œº3XQZ¬µzF>4–(^Ó…Iì¢³ˆg¬m’öÆyúPŸó†ø¾´Y©¨ËÿDçêÂU(f×õ)‘ Q$æ‰©š³àÿ‰ùc>t’şŸÈÄãÑñÿÜÚØÚı?«ÛèÿYÛÜÊü?"eşŸ_Èÿ3p¿ÿOŞ _¯ÿçşŸáÿùQÙÖòì›?à.!ÑÚG*
]Wî"t]çœlÉğl<#ûÑûÌ¡t´Ÿ‡CiÅ¨şl£Ë>¨[éÉ÷GØ¢W{{s7ˆ7JöÙs.šNnFVîOíöQcó.p°ƒñğ4ïe]Ò`½´¬QdÍ]ùRIşO~ä?*Â^Ì‹ÌƒöçìA°§Èª¿|_Ú°¡aRFÃŠŞ*»;ÇíıöÁIs/óÉı®ıIùäfqk3Ÿ\ª#óÉÍ|r3ŸÜÒOÉ'w.—ÜÌ)7sÊı<§\¡Û%r3gÚ)à2gÚÌ™ögåL»è8™?AGÚ n×‡õö2ÜhX™*Õõ!œlÖ2óMfÌ¼F3¯ÑŸ±×¨Ø›Ók”Çû—…4œË©ÅŸöUŸ®°8À8;›´Š+ÊŒ§e’ñõz‘aMí˜ãË¶°G®-ë’9dŠÏ´ßœ¾i·ÿtp¨Ø\^å‹¹Ã½VôÖ QÆÛRá#î Ü‹TüysçO¯N;mà<^é)T
…˜VŠ}…K	*ˆîDÀzXÅ´Â
)…õ.j%ÚŒDÕ‘0}ñ"ªøv60Üš…Yqì]ˆUYÅ ëMÊ¼‡Ù}ı8uçÍŸ¬'r
¸„G2ö·	£³‡"şŠTİWYp9e&¸v¢poVEjExãÓ›Äğˆè"*JóeğÈ'wŞ„‹©F·¸†™£óôlá£‹R(ñiNwQÕU”¥õX®cèá×9·/¢nœcA n¬d„7t+ıØ=Ÿ‡FeÕ—Ã4‚‹ù2oçğà{6©Õ3š&ƒäËpÿm‹]DãğNjÚ;M¹¡†BÓÊf—‡DŸ1\¨ò8î¡]C>Š Ÿ`©1MÃ—Bâ¡›LüİÈîM¢s•…Ç± VÌãx~oãÉÆÏSõœŠçr(µ|¶Cñlgâ„Í2ë¥6yá˜ºİ.^•Ó5¡Mé¢›V|æzè¯½ÇP× i>ÅS|‚p‹Mş³üÇSš(®Â4Tícº¤Z§é$I7roÈJ^úÈŒAœ½33¹®Ú„swºşªua$¤¤‹7vä?rõèe®ŞwH_ÚÕö'™Ğù×8Í¬K©cºÿw¥²Yy‚şßÕÚVµV­ÖX¥ºñ¤–Åÿ}˜ô7ÿñß>ú—í›]vØaÿ E¾{ô·ğ§ş/üçñoæÙ<99æ¿¨Äÿƒ?ÿ!–å_‰÷ÿîÑ£¿=Ü0G£eL?@`\Ë?>êÿÿzôè¿`¾¡Ùõp´p‰7àaúÑyVäı÷?Çò¢óÙÀÚuzÖ‡Gşké?ı#æş_ÿãş{ü·ú ŒöÓLÚBKªcúøß¬lV7ãã³²ÿ‡HÙù/sş#ôÄÿ9ŸıàÆ):‰‹ç,yáQtr#~hv
d§@*ÉS =X]Ô8´)„°y€à¢Á·±[n¡œ=·{iy©'Dè…œ"TŸĞfB¾?}x7‹&ğ‚O† ´ç '®Ù;n»!®õÑÍåÊôltÜñqå?°»v`@çA‹Ëƒş#‡ì®†Aóûá>Ş™9v@Ù å…ûE°®~V†ˆ¬KúŠ¡ãÎÿ¡h`¸æ´f h>y.ö‘Áë<é‹Í¬Á@ÜlÃ`òSñ/é:2é•¤Ö<@2<D)0/ÈÜİÜÛ;İyÕ99ÜßıGºOÉ€,”ëÈõI‹R(EŞT*M(£ØB$7Ä¶ÖÃ¯/£ÍÁÈ¼¸9ğ´qy\©”A#,»”—Ã”~!aR`B»§T
ÑpˆC@ºÑTQs=Ü-[†Ñ±'®,’Ğ´íRµpÏq"~™²­ÈHÙ`26ˆv+PÅò6LQíôJRp@ˆå¡İë¬kÓ³TĞ/ößHğŸË¼?6_7UD5x? 3³>ŒXÊ*y¢®4å9Ğ?WüxÔ¤:C‰›5!'·6ˆ]÷txVĞ-ÇMãSÁB!ÃZ.É.äAz†ñ8
¹E[•->_ÛŸ°¦ògK93×Vfï×¡Ğø<¼K¬c’Ô ‚èPT\Eˆ$:Ù¹o¬ğîz.;—rÂ@üİ!íÌË¸(Eù^/Ğ­Ÿ( \ä!w›S|LpĞ6"'È
Â°ªçÙ;Üiî5TœÙ4ÏéÇ0©]ÛLÜ¹˜K(¦b7Ñê¸q’È3GÃ@‘KÍ›‚¥|4Ö#²à–[…1.ÑÿGºª´»e%tF`ç‘`	&Õñ¨(İEŞ¡ªGñ…ryåSÀB	V-&‘B+BF¾yh„B©¨„¿ë¥»ã€RÔP-~bˆGÔb\çá§z=_Œœg2Fí<7ìYìãÑÉÉ÷GP‹o^7èèÔŞ%¯r'<£i}°ºcB£,6ÑÃ‚‡¯wÚ-ÜÒ?iSç'î°Ë½Š„‰=æ:6¡üÒİy5œÒ\ãßMğçøy0<òì 5á£æÉwè3vn{~ ô¢‹·G^Û CxB·y¯èD+æP‰¬Nóu»uŠÀcğŸ[Å)¼50Ê•Ü °=sDny•7Nè¨Jì·Q-Z*	jeC^n2Š¬Bš’„¿%åA‡Êò$¼iS0Å¡ÛêÜİdoÔ»Š¨ Väs>`R©ÒÑAIÉ$5¥$Î!eÓÁñya:4é4å–HÑPQ>;W\ %)só¸‘Æ¸d‚/h¼=ZN¬+ÌÉ‘Ó3VAPøÆÜ[ïîÚzOoUQ+¹İ…ª–‹XîÃrØ‚›hå®„IÑÈk€g1DIWÍ+Ss°xŠ	Å„?-Í aë0¤—:ÄB]ió)ê•„tOÚ³Y´±N`÷õ¨U8ChÕB£&F‘lÒhÇ…7g~…wœÒj¿h¾Ú;Q2RFUcEBŸX­*…µÉ'V´$ÈáÀ	Ü—âÍã»;óÜ$~»;¯}.Ÿ-šÇˆ¿–æ­Nš¦è=	t6#—X“øï1‰syš´%Êï5ÉtîÖø¯šè„à]ÀÆo©GuEVG}JƒÕÁàæ>;³`Rá|lè x“	)QMk~
2SšÅuôÏ(Ä®ğK i³²
±JôYÂ	©Ÿj<•ğp0z‰«Î?Æ÷m(8TOD’Pı(‘s`Ì CúFûºåäzZèÓ½¢út¯Àİû‘İÉÇ;µ,ú|ëCHõü!=Œ„ÍÊx´ò-wİâÏè†oÎí¢zb©ƒNë÷äB¢µ{|*Éá^¦,õÔ¿ÿ}4'ËwÒ®Å%y@¨Su´E“/ùö :7/e?ÿŞ'/Ì™tHRçv÷S4²N Âs6%¶Œ‘ô#€|¶»©óf$àpO•cUOxv¦øÑ]-D.&JŠNÓÊ‹-*Í”
#ÛÕ„ú:|Šü¼J=ë^«yÄP|14†NdëèùD¶ÓNgOËÚ$ÇâÔ¬šYË|¬x‹"2óqû(¿Àş[xôUÜGII§
9!A!kH¦íµ,«ˆ`xLŠI®
G/CÚv¢ÎFæ‰“YAˆiÿÄŞNKy]?œx<G•+÷‘Í<İGB+PNÛÓD3OwĞ˜Ë…«Ûw”}9ÚI’y¢a2yÕ,ƒÛ>Ú·LšY•Øñ›EÜçªé€p¤>°ØÈ³àœåq°¯JÕŠ?Á¿ª›ø·ÿÎÉÇØñRšÅŞãÕ6€+údKœÃßD×Û8èô¥KÁVÖ	øƒeÊ‘øÄ—(bIAáCü‘Ënê¶j8Ê`šÍÆBUÑ<¼¹A^•ÕI9¹²¦É\mÂÓyAEKCuCg–Èâhœ:=¦†ÖWÏ¦#° Áùk*U¸ùF’…«té¾1àÎ
(MOJîGiö	Ng\Ç¤›$RUƒtµ`Á‡4¶å*İœËg ‡gU<îµû²1™½¸&*şQnf<^àRÌ‰q½6®Ó†"TŠv4R”¶R&ı‹T&räÁ•\Ç¡©ª¼^şs¡<Z‘5‡B¶ç—ºç%4ğX]~!$-Ú‚;QŸ¨ ëúÎZ-ª&1Ehµu–Xèˆ‰Æ©*å¢(yÁ¡pÏ}Ç;öøhÑäÆc)9phÑÈë ·gü¤›j£}1iQ%Ê™ÊLY/å7!åoãyE.ø^İøú›äwÎáü‹ùl<IÉGİ÷Qş„|_Â»»,¼ŸÀHôL|•7a‰§”ˆ¯¥´…T,Ÿº˜J¬¤”¼ñÕTÊRJÉ_N%ÖR‹¥ÖRçÏĞ:~â¬¸SeÃ€Å»ÇU>æàWm	ó	:ı†Ë9­œ˜`¤¼®ñ«µvÜáĞuL& ­ `\9î5å;¶|©`ëè=}yÌ½’Ç…º‰<¸™÷>f{w\64ƒn-Óññ°fÀº 4lŠ^Ñ% h™%_hrã¡ê.ÆD»î =ŞÙªgQÔv¥p$¥"äİ,z­­Pz¡Ãª×ã˜][ğ¿Ãá¯s!&Cç•ù)aôZ•åQXÀ<ı#+p’RógH%¹UÇOhF™ÊX",(?İÕ«´‰ú£œOÖÿ˜Ë_sÀc>ao{.yú%$_ĞÈ'ñH”Ãa'&ßFd¦áwˆÚ= ·±sÍ+ì”uQ£ŒîÊè¸NIÉB9^¸ŞµéõDŸMç<‰v¢àv÷’n`@pèeû–§Ğ	&ê¨(^§T›$\Œjfi¿Œ O…„“'èYÌàÚú1Éz>*@êÕ[]oçñu$_,%àâ¢ ©aë¤Z:§ ğŠtÛáòö/ K`ğm—Çú º“FÅ@r&Ø
„•Å¾NØÃ‹É®šeÕÇºÖÜ-'E×:ÑN;'Çó˜,4BÏµÜî‹N£.–ªJNRbBGQ£Bí†=}ú4Š5ØD2'e“Mº¦˜#b;oŠ*—cæƒğSüƒ°§‡¥¦ØÒå ‚pˆ˜¸•ANÓùØÂ3}Ÿ/Æá!©ÒŞ!ISß…S¿ Áa ¸M'&mR§,êT§”ˆÿS¼BÒµÚ2]ÃC®O¥ğ¢û=Zß' ¤îäÄk^]ØçêŠ}®®ÙçêÑŠà¶Ç°!b¼¦SÅ7Õ7ålÄ×Vueƒô ”£=/hY#EœœÇğNpWRìHÆªVLŠìúÅ5(rtÔœX[Dg…ü4Š3nÈG$	]ñA8š|ü}.0‚3¾8/Pì}[“é‘87£3ªt)U¥kæ™íÔ'ßÄG…–uÅ]æŞ®X+?ú©O¤ˆÕÂüæÑQÅAøÙT§ãÈ13t ”tV6&çC÷f#ô!(İ›¬YHÅ³‡NÍ¨ãÉ?¤ŒÏ^ÒÍt
5Å‰Áô.ÈºæÀ‰‘hDè½:ƒ¤É|ŠWMºw›@ubyéq>¹Sìs!ó&b=é'f—¤0Ğîºy67±>2©…bcu$î=æ½É”ŠEÈ5µ’X§£ë|Òœ¬Ş´xäÂ9Ê'ü©RËÌØá7ç2nõØh2$/­T2b¬N"°aâ¬xºÁ/ònRı»±VûU›.K­cVüŒ—÷¿Vk›Û•j•ÁÚæÆ#¶µT¬Dú•ÇÿèZÚ«0ª§¿,.¸{ÿolfıÿ0©çv—;øÍİÿÿgs£†÷?W·¶6³şˆ„ıÜ†¥Ûö–TĞãÉææ¤şß¨l×ª±şß¨l<Éâ?=DzL*åã*ÑJ–¶3PYávÚÎÕ?ÿ÷ÿCKĞÎz¦×³”;Şöp4ÀMŸ
È!:†éwü´¾p˜Á°t¤†V1£hÛ”»2ŒÁäwÍ‘å¬9À¸?}Í_]„ÓÁ:tÍŠoÂğ7Ø<¬äpWí¯#8Xšğã¿àƒ>4%óĞëìš¾cœÇÂ3ÌâÖ
µx ¹{SSayI'–Í}ë±]Ğ[Œxn""´/4°>ø3İğ¡ÆKÇ¨è
Äs”^ÏÒÈØ’dÔèL;uÍÎş:ƒåü:ez9†#ØC\óeèußîö;
sƒk<´TÁZ™–"&ï]Ki„‘Ë­I¦YÃâ€F¤ÜğãØMkka ›µ5A–ugG‹ ""°³±Ó¥d±¬5(ĞM´l÷oÜE	¤+ï™íÀÊ‚“Ô§ĞD)µ`¤){hLºÖú·8áÕ˜n†ˆs‘ÓSNC½hb8Ì|íÙA`9X ãòP¾€[õ0#ï•=Û`¯÷ÿù¿ıoÀ
qlQT%D*0m 4•;6ıÑ™åAÃlÌÊûŞÚ¦ÃşhùşM¹xVĞíSı"Ô9ğ]Œ“OİãÜğ£Ñ5N<,8£áz<ŠuWÈôÙIó˜¯BÑæó¸^Zh!ú¸‹,„İj°78@€i_©¢:5ÍòÁX±¨Ş_€è?ıÓ?Q :nKü€«ÿµÌŞâR¯Ûó­÷¨Zöû0V{åde¬ÔÏa ªRµZªnœV7ëµ¯ë[_“g³v/uJÑğnêŠQ—RO‚6çµCS‹…SÁ[…ßÃßgì©r^ûÙ{6ƒvXB35>ChÃğšñ¢÷Ïùı¿JØgï§V4‹”‹ŒÃ”r£qq¸äİÆaJ»©|´MUhj¬ªp—İ`û8Å‘Ğ‘—	<Tİ”ªf%ÅşÈ¥éGQ¢m¬mqeÏÅÂXLiÈªtEC1YUôxx5­
Šœ•^EDÌ¢ WÔh<†Èï"¹£#Œ"Ù¡bÁí«¾{`„*HÍ±í")ìÏ"Ä¤‘Å¸/R,T˜v®$Fx=À×LöO¶‚*–³`zo(»fÖ"ØŒº)ÄOj“ù§éuNı]óM—¯Ä'F‘€Ù#—ÛUç,ëƒI:ERä¡ğÖÖä™fĞGˆğ9ÎøE,”+­­‰ËcøŞ5G!2d‹hÃ•G(İK/½†SÚ[•z
?”+ğ¹r sŠø†ğ&Zœ3î¶Äı»"bJx’…‡ªKS|@ƒ0Ø¦Ù+¥±è|(.°\¼¿©×6>{¾{EŸ99óÂ¯¨ v(wà^ãSh•§CT
w¥ƒHÆ<„ÔH„2L/›ˆmx·²z(CYv¡Òš( D œV4IéxªÁ§4Wl¢,ã¦ó¿KàÅß$š:™i'pÿNçw@(1°Òóïğ 	áÂHs¸ÑiŠ_3W¯	x‘O*5ÃİÜ!;Ê¾¹³k=DQˆîRÕ´nI/1ƒ•ÚèØÅv¾>°dÜO&†-Ë‰0å§ìWù†ïV©oøîòFÄZ[9ÍäCXN³‚å0Ê#ı•Ü\”¯å†§|Fï·}VÎA§”sÓıÔ¹*ï»ÀyFOÍIõGx–A{v/<7À¸Î½I¯£8 ¤ÌÈ†‘at:"VŸ1?Š}ÎÀáSm7şE\KBG+Ğ6`w­X–ë—KøÃ”ï¢áˆkúx§éM‹©3^ENKè3
+rz5Æp@‰Ó!0™ŒM§KF:bˆŞ#ÉÈXsüó\¢%º[=Ex‘jƒF£büÀ1ó<°Ây	‡‘¾Æ„¢¤¦h¼X†ˆó%8¬åéæn|òÌ˜ˆ/ŒŠ…¿Ï,ŒšÃÖÂE…w:Û×Tíã¾qörlÎ@{ÂqfÎh{Š·§\bi:Â£ƒÛ³rô7¾jä6ó¾ë¼îÃ»ózöuÙÄ:‹;à¤>ˆ´nzİ¾XdIËåß„§•Ö¤!5Y´_»Ş%_L¡G“ª}rµTh½¡qìÉHgî®Àª*2ÅÔF	ŒÖè†ï£+ÎĞ¼´ğú!_ø¼ ¾Xr]gÉuİÀ¾Lµ®Gw¹q[¯ºƒÏ…²oÑı’é‹A@cÅg]oŒÖù´ıª°°Ü&*1äšºÁÃğ„ZĞg
ÀMn3c~W´PôùPÇ4QëôÕõ0xø,¹òJ§†.:å­ËåÙºpìğ±W®-@¬›`Œ8`‡ÜC!ş}DRÊÄ6	"½9¥{Œ\î¿% –>±–ÅEæÅ1Å1ƒ}Š¿ÁŒFŠŞü‰[Èø(×B¿ 4aæqWÅ^d¿@Ë.·ï‹3} ğV µ8*B•pÀÑÒÎ–Wí†£Ò ‰°±–GQôtLÅ`’áÚUëS²8Óâ’w&Z7ä ¦pøzñûùoô§½~À'Úl!ÍI ÄıÏ’EZÍğˆ¥ÚÃSâ0+^jÒ†2oúÃ¦¾‚z:”ÇÉîlÏÈò2D²¤_RHç¸¯™DÊ\=HÇ<QsÂ-paÅs}>‰;W56Ànç*]O¡ê¥ ù‰ê–²|ÁBéÖËh@+Îgv1í¦Éè€øÆéFƒÈ`û.ì4¤ìĞ¤-ªÎnp§…­Š]”ë]7 ÎWE‚ªíÕti¼£ÇGZ“æİğñı†§§„\š˜1]^¥J-6%ëİ2ñŒPµjâ[g…nÏ=[ <àcÜ˜’Úêû®W6H#¯:ÍhÁÁ8eS}¼OÕªiÓ`¯Bı-ËJÔ}•Fˆ^Â.2‰2ÕõéHNEç^)ÚäT@ó¢¦…¬«A	4…]“u¥BèXPÇ¢ZÓ„DŠë³»cÜÁäÁœÃJSu1QEÚE8_Ç-æ„€TfvƒqeW‡”%râ¸NYí1¶:HïøäôÊm€¤CòİvH*Äar"àB·¾M”éˆce‡Æaz«¥…F#jix^§j	=Åø­gLoµ>1DP¥2p2TŠü¢€g^)~P+Õ3¦Wª]‹1“¢±áUì6³*ÈCÛgiíû¬J+¤•ÙÓƒkó6mµ°×Ú}AÌ„ûQc÷Ôcá^?=Å¸4zjvU¤ã
“X? <ğJ•Xi÷Æİ |>¼®ÖŒšQ56Œ
vg¯¾kYéBišDµ
jÆG!yıÊ¤v—Ç¾Gw
”è]V¯Êius3VæxaKx£’9”#ššškŸQCmUB§ì %1› ¡µµ6uÅĞ3úUÜb“ÆÓ¦.±3FaÛùê‹0hî7wRh<u´¡öhùça09}’j¥|œ#I+å¼J|cTBO²@ÈñvŸ³@_ŸÂeO)tôX:MvÓp€ŠÒ¥áĞU“è*a‹d¦Øí@Ó	 5¤N‹¼òÁìÊñÚù(Ó;_Í´x)ü¯£KÁ|[.ƒ]ÇB'jógî•EºvºÍ1XŒŞ|7X=®cC¡cDÔG5Ğ­&æõÈá:€=%ˆ${ó–®<²7?SÊÉ3)t9ÒNü¨T[Ñiçt´—§|èìjâ<¨ÏÃ§s“V^5B˜"µ8J?Pdd˜ãÏÀ+nš˜-3€†ÆiÀD/¦QNäU´÷DO‰,|\5Å‘¼\láûğ¥çOĞÖ}ãíãv'\öËû¬Ö5vÀi$âsÖKo#U»TDa–Ut'z/²0r¿ÔÀâQ¤'ÙšÌn?ŸŸ|0Ñ–x'Ö>–éÛ°v°%.*%¾pÈşlŠëf´BK6€ø+ßÒ¿“IàM¨kRWt	É˜f‰¨2üFÖåBåŞ ÷A\')WÌ.n©ÎÏ¦®ÀPkN üôts0şm>˜Â»¯x cŒI€ñÛ| U6T¾œ‚ôe´_`âÎ›ya•ğµpÓ†	\L„N&~<"~Œ`}¹˜;²¥dîAˆW¶;"~Ã »¾¼i(”oÓ„Ûõı1È*±ÃIùiçòl|4Cm­~}D‚xV1€·ô/EÛ¡‹ii¼HŸ{™‹H3ÄÛ—t!ï
Ú‘¡B†{ÿ—–÷~U^ØÛ·#C¹µ—¨&eĞ:ÆA‰Jùåb=—[coÛÈïï‚ó#(“¯ı-ó¬E,îÏ†6eCoïP¾…ŠD¸=»‹»Ux9É*4kóW=6vÈ?ú¡99eÉÌëLz:ÕŒŠÁ¾Ğºg´fÂ3º‘ÚŠ(ÂÌ€=Eô »ëëkÃ$€†ë]”Eu~yow§}Ği— è3ĞÏîxş7é—r°DIw?ÿWİÚªfç¿"ÅüY–RÇôó_•íêÖêÿÚFu{só	ÿ‚³ó_‘ÿ†î…¼$ÇŒù´É9À+ìöøİñ‹Uk¾\gÏñölTqZÑÑDõ[Ö“ÑêóV§e:¦uçU0Î¯¢µöÍ:ûººUc/fœyã‹‹uÖëGËÃãgK@×£üâ{£®nfÂ§æ8è»øÔ	¬s´HÒ$ÄVA)¢×¼3øÄô‡@ '+(İîÙAXº°gúÁß?}~Ã; …~aFJüÀ³[W6ÎN‰,òÏ¦ÅÕK^W(éÿBê:&ío<-IÅ-T|hn`ùuÒé…7'™túĞ¸¨V„ºê’b³>Q#ÏP`‹¾‚‡àµØw6ºfßÔá±úQÙ6`n{ÍÃäUDòãÂQïJ^ĞíË8tnœÀüÀ{àuó¸ñÃ/qw¤Sm¬¼ÿá]¿şîºÌŞÆ¢€¼g+2g·××¯¾¾œ5×±èõ@‰4 û,5`–’¡Ïi®äí§æU2&C[_”Ó=Óo•ÀŒ®†l‘¯¡4¼–;JúuÎyzB­0;¨y1â¼íå„~9_‹£|k÷8y­´¼IÚO„*S ´ÿl ûwÀcqá9®`FÖ¸£XGx~]ú)P\´)"e.sÂú³€«ÁÔ1Ç%é‡›+ô³DD¾³²	&oL\Ğ¸Fv›x·LÉ Ç¼xÁËß‘á•Õ—Ã1¹ÒíÅ.TX	¿èk^Îyå+î's 7k¹p°$sÁ[-d.x¹Âlvˆo‚Ù#Xö`b¦pD(¹»Ósóáå™ ‘ŒØSw–NË¤Ğ#” !) ÷=y¶·×<i7vØ ø&²Ot¦<Ìd4VğCkÀš]wàzs¸a†t0gáw^øÊç¯Ò ù‘Æhal7h‚Ev%Ìu_8hÃF¦ÙX‘¶#(¶U™Ş;enO‹Š[w+N–3¥¸gî@±eEPü»ÁˆLmÄ•í6V®ìÔÛ’eqc…LVJµ—Í6V*IÃ¿êŸà%IPÕ\*ÈÜæ P.Á ìµX¾ë4¢ıé}ëåÅw¹B:fhV1ñÇÃ/‹|†¦w#Ñêù0šBÛú¢è‹S|©D;8¯v[b+G¼ĞJ~ÀÍ¦S€BNJc
«ògqzsVîjœÊÒÒSt~iyuÌ°ÿT0æO,şÛöVfÿyÄãÿ(nş  âª¼ÊbánÑvjâCxÛ
¾ÜP^vÂ·›âmt‰
¾İoã—¥äßIQe,ÇwëxN¯¸©ã}9u¼Ä&4ó¦ôc‹­cÖøOÚÿ7·¶²ø_’ğĞê²ëøœıŸÍ,şßƒ$<¯¼ì:>kÿo;ëÿ‡HÑ‰İåÕ1oÿ×j[À ›ÿ±’ÿI±(K©ãîãc»ZËúÿ!’®a9uÌßÿ[µíêÿ,şï¥D8%Ôq÷ñ¿YÍæÿ‡I"v,´Êôõ_µ²¹AñŸ+›O6Ÿ`ÿƒú_ÍÖ‘3=.Qî1{)n)	Ït;=&¯…nKù+g¯^îñ·FôRDByåó=Õ.í©ªŞE£ÂG´íÂ3‡~.Ç/-Â¿ë:ãbğ¸2tû½ÀíhõŠ£Ü½ãÉ(W“L'»^ë×IæK³h––˜Òã‡-¶»Ïÿ[µê“lşˆ41~Üë˜1ÿCÇ'ú»–Íÿ’2§ß‡vúıÙ:ûîI1)šÑa,ŞaÌwW¸Ç>´nÕ¨VÔ75Œ)ŠW5‚)oQ6QÄ;ÅŒI}Ä«D<ô0´)²{IO¼[ôàÛ?ÂÏJå2w›)y¿Ò”uÑuÌ˜ÿ76óÿæ“'ÛÙüÿ)›ÿ³ùŞÃ>  ~pÏø1Ÿl¾WPX4¼kËºÜ°óñ` øğ[±xnœN>+ç£[9HâoØüWò‰XxéêG"$;+ìÅ«½=¼¾>ür÷ÎL£ÛgÏ…·wÈìx2«öì·ÕÜÈ×31Ğƒít=:´n~9"VÖkëë›ë[ëO>‹œ»;ÇíıöÁIó§BUaz}8JÖjDÉµyéŞp7‚}éyøK¥áúRÇ,ıoÄşïfu»úß6íÿeúßòÓÂ,ºöjÚ®s:Wxe#?³ĞcÎX(*¾ v†µ£SR´3PP’×U@>E[3Òt¶u]]Ã˜1MÕÈ$ˆÊ¶´øvÇ<ŠJ&óT
~Q´0ùåè4Šá¥ÕÙg<> æ§÷ôÚüÀqØòú<ji¬¡Šö&Ëi´£ĞêRjD(˜¢Š ÕkJeôIZtœ¥Ãï|§ZØ*è•ı¢ÁšüÚ¾Î.<fpÜÛÓ DáîF×ùÌ:Ç{?Æt¡“¹ÇZnqï\¶®}÷Ç=—uGI>à‘.ÑYV4Sü[UĞæÔ%ø¼dJé¡³]ŒT>¿& Zß³ğŞœ+$ş¼µôDñYÕğ[º¨âÆ‘©ÀiwĞîèîİ” À”rØ±>_C Ó‡Áø¬|ƒëˆm±Œ€d‹•„gQÀ$:'Q1`Å¡gköh‹ïGp¯1 ]1,ïÜ[ ïsJ¹Æ›½òÈFîé~Ã±¼ÇÃ€~º°‚\/‰¿d¹·B.¿ÏÜŒ¬¿‘ ‡û÷q‘ÕK€W\9“{Åa…£8~ñU‡-ºü ß}½´Œ
QÕş`u‰çî^¶Ll÷Æ:Ûs/ì.^•Ã¹£Ï€uFğÜ‘
®#.¹>£qĞ ®Dû*ĞIˆ÷D]\s7†ãA`—°AÎ/=§ß%M¼juÌĞÿĞİ/ôÿ«î„ûÙıï“Ş¶^î´ßçé¶'TdŞ‘Ê ğÿro_¶ÚÇ»;ïsöÎ«ãİ“ïO_µš'íÎéëİæéş÷üÌyçÕılœ›±^dYZFšx×Ûë˜5şám4ş7ĞÿëÉöF6ş"ÙÎ•åàü}
}˜;‰D†N§šğ¥±ÏÒ}Óìï_ÇLûÏÖvhÿÙ¢øÛO62ÿŸI™ıGµÿ¤Şhš™€–oŠ¢l'>ë!<òL~ óO,×”ÎxË0ÍQÓ=ì@sAÿLSĞDØ”	¿k»c¹† Å qxÔ>huNÃ„ùô‚ÊyİøS]ëÒíù–Œ>ÈM=¥†+úËØ$USÏŒ’î(^ğØÂ“w(êYœµ%tËĞÏÕ44ã–ğ…Ô1Óÿ{c#æÿµ]ÙªeúßC¤Ì_+vÜ_K?[ç­–¸"XÙuUsRŞ’ ¸Ñ‚>ıZ=ºr= a¯Û òÈ‡ëğàz¹^·ÎÂ—9÷÷ºx Nñ.LÇş‘\âõ/0“pˆ]§As§¿»9øçdñXMİÁ¼â3„|d¹0QO„Ì?ß	ò—MYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥)éÿTè6  