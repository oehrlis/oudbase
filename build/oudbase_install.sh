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
    DoMsg "INFO : Usage, ${SCRIPT_NAME} [-hv] [-b <ORACLE_BASE>] "
    DoMsg "INFO :   [-i <ORACLE_INSTANCE_BASE>] [-m <ORACLE_HOME_BASE>] [-B <OUD_BACKUP_BASE>]"
    DoMsg "INFO : "
    DoMsg "INFO :   -h                          Usage (this message)"
    DoMsg "INFO :   -v                          enable verbose mode"
    DoMsg "INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This "
    DoMsg "INFO                                 directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$OUD_BASE)."
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

# Define Logfile
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
while getopts hvb:o:d:i:m:B:E: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
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
export OUD_BASE=${INSTALL_OUD_BASE:-"${ORACLE_BASE}"}
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

for i in    ${OUD_DATA}/etc \
            ${OUD_DATA}/log \
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
‹ µ¯	Z í}ëzÛ8²àü]=Fv-‹ºØ»ÕQfKI{Æ·c9Éö&Z¤,¶%RCRvÜ‰çÛûûwí<ÉV  ©‹mÉIw‹Ó‹ P(
…B¡P¸pÜÒŸü”ËåİFŸñ¿åê6ÿ+VÙª–+Õíİr¥Âàÿ;ÛÏşÄv>£ 4}@%ğì‰ù [·;á»hGô÷7ò\@ÿ{#ëüÂì\†FĞ[@“û¿º³õl—ú¿ºUÙÙİİ‚şß®îTÿÄÊÀ%õüÁûåÏ%d3èåVXq~@[İ·jluî`Ï|çÚ´œ€5^o²—£Àqí `MûÚî{Ãí†ì/¬==?dë/›í”i›ö¥íÛNúfØ¬úÃ&û¾²Se¯ûf^ø£ËËMÖ¾qÂ_m¿oºÖÜ‘>2¶ÁŸÓ|lŒÂç‹íĞîš.;¶{~ßaëX@i†GiŒ7€Ò-Ë	£Ò«fîõL÷Ò¶^Şrò7Í0®[Í€x–SûÚ	ÏMe‘x¶“‘?ô›Cz	<ÃÚß†,ôo3û}æ\×q/Ùñ›&Ûwaä¸;@"x¡HDÎzĞ…/¿¦ãöoÙ(°-Öõ|f»×ï¹ÔŸĞ/=o²³·Í"Ô
Ÿå.ô(@F`½0µRér.0%N¬ ¥p·=÷Ê°Ÿ€¡<ÿ¶¯ågü“Ø3Æ-wBÇì³kÛG
BÊFyWËshşmí­¤¢ãvú#ËFfBCÜ.~ÄwãùşQû¬q´×zAé°jT*pWlX¿€DCHÀØ6üÂÚ=—y]	’8®²•,è¸¡ïY£ÍŠš>ğkhû(Ú§{9xO2 j8wrÙ îœ_Í¨õè9×Bªuç •ƒkÂõCöÖì «İÛÖi{ÿø¨^6*¹æqãä¤uÔ¬çÏNß´òlÆg†‡yÑ‡®ğ.Y×æphƒØØ/Û­zşUã ı xÀ-0ÀÙÀ³ì\{ïtÿäìü¨qØª¯®ã r+Øj¹><=;ÿ©Õh¶NëyzCÉe‚Èš¯~VŠŞ±õ·|@ºhû]Æ4[İÈçûfó´Õn×Eÿæù&X£ÓËµNOOëåÜÙÏ'Ø¢737ˆ7JöÙK.šÎn‡vî­ÖI}û>p°£Ñà4ïm_Ñ`½²íadÍĞ‡¨/åïğ\a²¸{Õ7/UÆ}<ÃqÆ}5r;ÈûáYnŞC^›MšN0ì›·ìM`^Î[Xw	8ğõûœÃ.ˆ=Jjz‡Á%Ëï½:f5}3ÉÎï‹½k’Ïaz;—"¹ı‚CöY~Øs…­áãÇ,ğŒ{)¾ :Ùzˆ³ã øŞÆ”½N•ÍÄcÊ¦±? ¡l‡s¶”ôÁ˜ÒQC£Ga*ƒYmÿhï´uØ::kŒ“"S„Å¡éôa.³pdd£qà]’àÅäóÁñëWû­;Ïé²÷X¹cÅË•ÙÇYØ³İœÄu¯o›nÃµşsä„<ßêçê}¶û (È|	Yš]¾Ì(½ëäîrO3@9Sp: ¡³ÃE¢úz!Ç‡ÌşÑÉ›³:í»ÚÆİÙvf^Ù4rÿ4ÁşXœ¶˜H€äêx-ˆ?Pì™É\T¸¤ÂÌ°É`ÚŒú$/,_`ìlÿ°uL}xS–*ËÿÇw?¿¿³Î¿û©öİaí»v¾ğãJÑÓÓñEİ)…iêƒÒ¨÷øX«Vo>¯fØàßµFÆ#ÙÙ‰G@f[äà»<«3¡`$ƒÌ*‘Iy©NÏÃü1NÀ8ˆòìKhƒòh*ã1*©«É`¢l0¤äÏ çtÃèí¦‡ã°Æjÿø®–§Uqß–Åh%§¶.³…“ÁiY•–¦[ky®–Msì¶/²ÚôQ?ÉÙ‰÷ò™¦“à…"
¤ß'gŞ«¤H(«SĞzá3›iŞËPwñ„D® 4²—Ñ”‹Â&Ú”f¯J«Š’*doØè Ú`ï`9ÉÌ7ri7ıË.ïƒµalhVCéŞñ|ßî@×6Ô*ª³V!³uœÙ³Â¯@“'ÃGée£İb®’şĞVµDó4ÔÂtÈ•i÷¼Qß"¡7êôø¢±×p0}Ï´Ø‡ÕÏ?CG•‰¤
nkj{ÛL»B·ëBÃlK-ÿÃ…„Röw´=Ü˜®k² T•Ùï{!ş:µß¸W®wã²–ï{~zjÃQE9a<ÓbéøÕ|V8|±$l67B ´½İ¹ŠY­8Ô)0N]»ƒZœ›“rRfãrR—‘”§ØÅlÉŞLr#+WzşĞtØj%Rb»c¹w§£„Æ£Ë¾|/fE+ñYEP«µR†Úr9ÈÚ:zJ¨{–2˜ŠdkˆlVhÄ=@êáúD±æQ ÚÚ0?a„ş(–	91wÔó4päJªQC_ãaFß»ÌçøpŒ'V}Q²ìë’;ê÷99VÿÊŠö¿Pà²¿ü{ê†å•5‰F„½'uŠNšŠZ¡¢wh¡™i'À\¸–ƒƒ…×£lo181Ì°Š­4N3¨«ÕˆÃ—¾ÀŒ¼m\`ã°¹´CoÜ§›¡ïá(ÂåEÇ c©Ù.ó9®«ˆÒ¬wÖœÚ Öªái,|òƒuòë6eEx]s¨ò-„% ™©€O Á¯5ÁíØá­¶à“q {ØêºTÜdŞ/hJ6KXéR]O´
:eWğWÙ°*[İP…+©Jr|'ÍIb4ö«Adég]ßàĞÍ‹Ì•{¢`ÂÜ ˆ;Ä¢Ù8kÜ•ì°Sâ#<XÔ¨Öñm\s™"dM°q‹¡<ÆˆO%´E%Î/ëÙ•ed&²œì·a¼~éÛC´Ä¬ıse€u÷¥3
¡†µBZø
r¼kœ9S66€ˆCDü0†c`½‚	÷aĞ8©İ(Áï¸ÔÈEåEkL¬ùƒNãà²ÊŸ6öZ©I°R
ÿŒ} }Ã½ˆNŞ¼`ÿU‡¸~-(ıÓØøPú°ÿ> ÆÆjéC¥´Vˆ›¦ªüÕ“f=[ßÌà´V„H^ğø(°'±¸(Á°H.<zã‰–“>[Û\cğ¿‚w¾=ğ®mĞnH9n¢ƒ2óN’ïîW ÖÛÍ§	ê®ÑAOkã/-xY|ö…B4¢K5 EWTcŸ®¼¸À8S›}´+¯Êì§eÊzèõ"ÃšÚ4G}í`ÜØösÉ,Ÿ;j½;×jıãèX±¿¼ÉrÇÍø¬âŒwÅÕÏ¸pW(Pñ—½¼99o·€óx¥çP)bZ)ö.+¨àT
`=¬bRá…ŒÂz5SmÆN¢†êH˜Hˆ+¾›·ia†ù—b—U@V1$Èz“8xŞ‡ú‰}]„ƒ;ÚÈFBnhL‰
»÷«²ĞÇXİ\rYµê®AÉ·»ì³¥èÍó¤/ô‹ÑÏ¿4<ÜŒÀöiV}¶Ñtpåçù·mJä…Š¥Ş‚¾z'Ş Ğ¹Y
Ã)
äùêg	ö+“	©A	M>ÆX†›,ğF>$*Ê¯CTæÂL5Y~ÖÕå¸¡8g€bİ’”#¾1atZN>X
ÅjÌdgÅ!“Kâ¤æş)èÜI®(m,*R+ÆßŞ¥†GLQÑŞñáaÕnĞşÑ]IÀ#›Ü…Ã½ Eİázf†6ÌÒ³«Ÿu\”B©OìÚÇ~ÃeÇ_*ÉÎA¼ø&)¬A²úN,İ‘AÍp»ÎeÜ3`,ÔI”Œñ†naÅ“_;İYhTRFÃ9‡i„—¿ò%ßŞñÑ+öb\«§4­3ò}t‘›áÁ=Ú–,:Æ°€šöASn¨¡Ğ´’ÙÁu‹ònPlF¯#mòÕFCH0È¯>CÚ^—‰Bâ¡ËL2mèXãèœEå*DÑÂQÑĞ«ÒŠ.mvTúAh©j?¼ÌÔdjâ;\T§èª&a<‡¶³ds¾ À'VÈÊt|ZµèÂõ³ª“¡0ü¬,½Ö}®ı‹±¶¾N?p¿Ã1õ2›Œˆ)º£~$¬ã:AÏ¶ô–&ÔíÆ(ôĞñJĞ”.ºi-`^ßBßè=†ºMóV/²²…[bòk¯ßÄS®Êªö1K]R­Ót’|ªjÀŠ~öÈL@œ¾K3¾GÚ„®7]İ¾4Ò
RÒ…±›<â'"ÃfUcTË»q7aİ(Ñ»qú}ÒîlXk`[F>2ë)‹ûÕqcU£ ÕXÌ.Ò>¼5²Qsä#‘·*Äôâv¹¬ªRÃP‚‰ƒÄhãSDßc×Œ]ó0N¿¶Ûí7óHÿo.á¾Šÿ÷ÖvåYìÿÊ•mx[ú?Å³ôÿşJşßÑ€û½øéëÿı½ÿMñÿ^ºkgAûm¸kWŒòƒÜµçê«ım;j/½—ÃŞË¿sŸå¥¯ñ$û¦|ÙÒ×xékÌ–¾ÆK_ã¥¯±‘ßŒ¯1›ÉÙxéj¼t5~ˆ«q‹ÛÒ®ÆÛ[ÓÊ:ÜğİH‡fÜx¾Em[º,Ïné²¼tYşM¹,ÏİiùÛt[ÔœZ«Ö¬ı²Çå§pMnb(˜›Gc€ÿ"sœÉı
H0&ï\yqcƒÔ¿F^M"‹°FNş³VÌwÜzäG¼çB-~ş.—Ñ YLM «ŸOŞ5¹«”#Îú³–éü“ÒöK:—Ş	¸ôä^zr/=¹ïÜ‚™gôäşƒ{ğ~³^·iñ{ÛÆó¯îSÛúŸ'Ç Ÿ ÓSÊ¸1C‹A» Ç!¤¯îŠ–OAYÑrkâE$¡
òÎ:³¢Ì-úÇÁèŸz^È%ªUC©ºYE&ı{íıûÚEßt¯j?®RI ‹GŠ^í
³ •á´^úĞ³½zÑ„8…Í ±ÊõšµÒ‡üæ‡|)¢´vç(Á[Âñëq~ãçj	òÉİË=¦éóœ ·ßŒ[°
ÖÊò™æ‹}s±Øó‚Ñ÷:fß ‘ª\%æáş$…>,²ı>üLj7,SåÁŒhrçì˜ö˜Q€ÃB ;†šçMóVXÏ×şã»Ñ¬ Ò¬ô]ı¬)AÁÔçºñQºó²ğÆİšğÆ%vŸÙ#Wi^†WnkVÆ¹—«.>3¹ë¶"íaîºøLwÙ¥\÷s.3øó‚myŸ‡S¨hşÒ)ô^Ï×öÆ{úGú'…£à«ønï¨ñw¸ÿçVeéÿùÏÒÿó+ùFî÷âÿ‰k<­Çyñ<©o‡#ÖØ–ı{w­åå:_ÌçéÀ©˜ÔNAû>F8ñV+æmÂKz¬ëów¿o—OöDè=;¤Q­½³ãÓŸù²3O‰rOIË o,•Æêjşi}GÿHÎ£OèOŠìôçQ?å‰ù‚›ì9ßß¿ğßê‚ş›İ™”=ÎŸ”İÇ¥ÔÏ*Ş!S&N?ÊáÚ1 ”vÇdßkdßËÜ.Ê—Iº—i†ìÒ©nÁG](.}[¿ºoë2îÒ·•êXú¶.}[—¾­ÅÉ¦OïöÑ|H÷áŞ­;Sá'LûÕ;`1ĞôÑw‚¼ö¢]htÂ`|W!Ë…aéSûŸÚ©åÉ¡•Ğá±ØôâS[ÓûAĞ»òD°°		w\õà¬@“uN~Ã;³ğV‚£‘nÒB5¸®ÍEâO´ã'ZíˆBËòÁInŠ©ÕÌHOh§
¥'É¸}7Cxz¨tGÇ8£Dqtõ)a|$ªh€BÜqqgŠ/²¾²§6÷WÃÌÒP’~£ã$İ„6*Ô|ÌGEcåÄh Uw\eòXú‰ÿÎüÄÇºOõOº¥“ø·×z%ôÍ!Ëë~¸å<®¥sğO;4Ê˜tªC_~aÎå9–·jşSø–ñè¯¸_`§­“ƒı½ÆñSXÍ3PvÒùdFJÆ%HÚ¢c…o4ïF‡DÄ&«’Ø­çR"ÏŞİBJ°,É<°ŸæR»ñÀ‚ÒÅ7ÔÄÊ'vàÉXi´ÛIûŸcj””0ÙßÏ FÊA3ñN?16“äÏïöp Q†O…	MfäJí<éÜæòœÈY,ò½Ûb×wl`ª[Hq½"H¡Á0¤ß'¾7´ıĞ±rÒã€Í£¸5Í£»ü}ü#_Â:gÍÄæØ,úıY}»¢eŒbŠ½Ûˆ1Ä³iÁÿaŞ1ù¦8îüá¦vÑ!ç÷ÕR±´¦2#”úÅƒê%÷cûMn—Œú¡3ÄmDôrˆ@”}x
¡ı‰üÑVKŸ~JÜ+ıx76Èt ıDÀÿ¹j
ÀÌ'UK‚ŸNøL¤8¾w±"vX¸71^[íqÃé°µT±ÿh[Zİ)E”¾ã†qİiË—.ÈÊIKtpGJ‚N¼*ë‰U™‰6(¾ËE‡-šú§=ÆmË–p«Ÿ±hh¼ûÇù1n¬›7WlíeëõşÑçÓv=ÿÁ-~€eÒ+ú™ÿqÿõÑñikfˆzåG¾ª©ïàFL…ı›•ş)‚š”P¸®V1éÃó5¬eíÃ‹ûZ_İâÉ-ŞH/8åÙî|¦u	¥é=Î¸+eÊ_5cdAïìTR
ıô.JwS…¨”áÂE™õÇ™Izştò¦Ş²wæÖ;¤	à?Ê(‚*`ĞĞÀárFŒbK2zG¿nè™}Bh™e§ÎSÓİØ3f1Šä<Ã4–»2ûjì¦5i\·fÚ®Ğ«ÛU}â½ËehãL…à/ÊĞÀñPËÿ(÷•4ç ;Éë»ìÏÿ^?BkP‡€äõj&³ßÁ«“÷¯wªëbûîÆ¿Ïø³ÚŠbAuLöÿİzVÙ‰üŸ¡ë\¹²µ]İ^úÿ>Å³ôÿı:ş¿‘WçoÙ÷—¤yÚr­;í&·~÷Q`ŸğßàŒò®–çĞüwS‰ê’Rœr“Œ‚·eĞªŞç‘¥#ÀrÚ£Øb¢èø8Âæ	~ˆg‚»%äW_PNËƒ¨Ÿr^Úá9BqX•Ÿd‡¾
ıÛyxÎÊí%È‰vë€Ûn‰kÜ'½6}µì ÏNnå„t´Øµ}è?rFìhˆ´ íÙ^Øñî”×ĞóÍ°°¢~V†ˆ¬K:2 »$p‘h`xÏ (ÇŠæsĞT±^ç™t³ï÷…RË`òsñŸş"K„ÜÖVkî#¢š—tTµqpp¾÷¦}v|¸ÿ¿h)e@Êuâ£Âà£Ñ„2Š@ÚÙà¸Êëá–
#ŸrŞÄè3IÜ_•Ë%s8,y”—Ã”[%Ñ£À„vO¨ £á†€ô‹,347#3ü¦¸gä‹ÕŠ„¦ízª¨E§!Æâ'‘)9ŠŒ”¦&D»¨âÊ‡é0yFµWp-MÁi u"–Ë’XÆ© _¾“àË¼¿7Ş6TD5x¿ 3³ŒXÊ*7½â®4û¡í»Ğ?×Üù~\’D‡ëög{ aÄäEHc BV!·šÉ.ØAbFNœ8òøÍEª<	¸ÅÁ˜û$õ<s`¿XHàí–2c¿ÅÃğ.²¶J"swê ¥ÄÒwŸÜ·vä¯ÂååüyÒå§cŠÛ!Ï¿¢0ñ©GøFvıxëøN=2ƒL£­¬  +zƒã½ÆA=½#¤yù­ÀDvãØ0YçAn"Ñ”Ø}Òqãfâ>Š,ªk×îd€àC^)ï˜,ø†åÖA‰À]Ê+Üä;ã*í`—N²n¼M^„‰t4Ü(Èh2P¿£ø—ÕRiíKàBV)¤0‘’*ÆF¦<£û#‰:@%ú]+&q¸é9‰¾Â†uäAÏÅ…&ÕjùBP
D-Ê8y ^ˆ¹d˜¤È¾1—<o—“0¼e/»šÃ³³ŸÑè#Æ7?ëtíöäÉoEùf²;#B£$bºDßœîµš$@ü¤0ß¸›wòGê~ƒcÊ/Ü	FÃ)ËÙòÃoKõaxÈ-ñUã“ÆÙOhéí:~*½è¡%ùÆ¥Â·ºÊ-=Ñ‰0HûvÂÙ"–gíÆÛVóÇàŸ;å6ÚÈ‚çJ;‚	X„Y5#Î_í~ÑÒî)mæ(iŒ&Ğ£{£É[†‹FXTÙƒax«·H„®J'^,7éĞ,I-
˜¤lŒ
I©n$öAgÓaÀŠlj$7à\¹å3¦o	é1qÜ.¦…oKt	{l<7…O„Ö&46bÉ4Õv|üó¤pRŠoš­W7gšKNû¨
X¢HgJ«JatŠÈ&ZI¹ğã^¼o<Á{sà8î»?ç=”ëæÍqÄmÇ'<¶p×7İWélF.)ÍÆqã
Iò|–$&Ê4Él^×¸±‡S£ÙçŞlÒc'*r<îSº.zH°¨…™‰ß=å@AJätQ¢’Õüd&4/Š+}(„®AJ 11³!Vˆ>ğUıæ­ÇñKÒ'×ÉÊglÕÛ™É÷ÊCÇ½phºåìÆ.^grM3¹_ô;•Ù½âNf–Å8”	Ïm%e²)s$lÖFÃµyì/şq¼ ¥ëÔHºV:-3(ìŸKrxWk5Ã_ÿÏĞ2MZQ¸$·ğh¬:qÇ› ùbàô¡sóRöãª•ño‘³‚0›‘»z<9=®ËÕi.–G¸ÉÆ1©¥Ædø	ÿë«1=
©’‚ÆZyaÃ¦ÒL©06lŒ©;±Éü¼J=+y ´a
htCIekëùD¶óvû@ËÚ ÛÅ3³’c‹–Y=
$ŠÈÌ§­“üûoqÇHA:†iÁ¤Ê$é@Ôå[jäÜˆ&N°³ŸOZ,rÕ–ƒ!mÛqg#ó$É¬ Ä´?‰ÔIO^WçÆFøUÅÀcD)#P(VI’”?÷§ø¬È5¨×s•ÚZyâa2~,#Ü¢ÿF¾Š@v» {8 ªGúÃmÅÀ†¾ã†]–ÇqÀ¾+VÊüûÿ©lã¿Á7Ÿ 9tG"AJ³D:º³®xPâı&ºŞ%Ag¯4VE­Ç|x,Rà4Çw Ï‘'ÒEF<£cĞÁĞs-ºôVÙg‹æÀèXÇ‚N«ıİ¸	’Jb;Øša/½¦)[Eúù¬ Æ%åòÕtÅÊÖ 8M¤Œ‘´ŸHNïÛ¸L–{ò}¾c¯€ÒT“ô†Ã‚„ë:3²—õOÁmRËê«Ü±tïøèÕşëúønå*šø£B–¼µÊ!dØà’
_RÙK	Q:ià²µi:¤œW Áİ®=¿´‰‡$†k²æHœYA±Ó½,¢ÄvÉIWÈ4\˜§Ddª¾ôÑê9Õ$„±V[{Õ6–jœª¼Í‹’÷Ş
÷<vxßz#Ÿmt¯ÈñC‹~Ä›¿¸9¤w‹é°í@HÓ„*'TÎTæ¤Z1¿Oş.™Wä‚ï•­ïHç\Ít˜ïÙÖ³Œ|Ô}ŸåOÈ÷ı<Í¤Éræ¹Â˜–©I®§Æ,¦”ÉU‹¶dIäS—-©5‹’7¹nÉX´(¹“—Ôªe¾ÔZhßîãü:~VÜ+…²aÀÄıÓ
sğ«º€ùı-#…]N+g¦)ÉUq(À<÷ÄôaÒ
Â îR@‘Êwj0RëÀÖq:}±‘h $*YY¡‹Q‘Êƒ»’Fi×c3ìô6ÙÀ6İ Èh†¬BÃ¡ cŠ&ËP†ÙÁm—ÆBƒgÙºo[£V8–Ò
`!e9>?'k+”^è+è[³şsylùM.Äd°?‚ƒ²<
˜§e«œ¤ÔüTh(InC•ÅÉp[q¦’ –Š$Æ]Åõ*m¢ş(åÓõ¯pùköùÉr
®è‘×¡_"ò…½˜|D)vrwÑAd¦á'tÆÏ\óŠ:eS”¤á(ä^d®ç•,”ã•çß˜¾%úl2çI<°ã… t:W.:„AÙí+t‚‰:î:ïÌÓ”jÓ„KĞAÍ,õïúDH8y‚Å‚>únÓˆÙO×óYR“Ö¤vÍ£ŸI¾XH˜’ùjPãoHµtìv;®™ãvıÀë_ K„¶¥oØŸ@w¢lÊæ¹v†5µ*öç&e(ægX+ú&¿àuû®}£y½»
a¢¢wŞ>;Å8 á Íñ0ÜÕ®×ÄQ4€sk¤ñ(jT¤İ°çÏŸóT‰MÖÎ«¶ÉòMKŠ ¨r9±POÖAq’åüšO˜l³×½ùB¶1+i‘™N¤Éü”RF±â]3=ŒR–GDWÙêM»%GŒ›á1—>ÑÖèºÕ±k&…# ñŠšï+Dı›½§¨8VM˜jŠé©¦™j±
~WË¿xìáˆäöNè)qê†|1ãÛ×WB96’@CÈĞ&®LÁ‰ãÊ†a(÷ÇÄŞX¢jåÎ”q!¹f—êÂü¤Ov:nÇ$‰¼´ğE8@<D`F»ÿsàüù°oRÄÜÇSÉ4ó ¶¥ş(î£˜ú*œ¶8æŠƒãÒ£
ıër)ß;î }‡.±µ±V.ñQ¡eMqº•…¹_¤¬~–³)Æ9ŞXFø)Ìò>1\ê3”O9d–™IøÙ;õ€XW9‡—í OIú¼@Uâ:pú 3ÆçS°Ïv^¨-/}Rã&‘§o™Ó¢c,Ö‰ÓOfOÕĞ#©ÏŒF2ZâLÈd"”„'*z:ßé‘’Ğ4Dn*™.5ÔíÔÍ•S£;ò‘»w¨.óĞÉ¿sïË‡?Âò¿Ğ:&Ÿÿççåñü¥º½[®Tü¨noı‰í,+ñüÁÏÿw0èI-§v°(.¸ÿom/ûÿiËë,vğÿiöş¯nUwŸ=Ãûÿ*;ÏªËşŠûÿ´Ëá–1°TĞãÙööØø/åİj²ÿ·Ê8ş—ñ_ÿ¬>ˆ»4¹(®
­òÈ¦‹.n£å^ÿ÷ÿù´¾ ÕÑ2}ËùUn»:ƒa-ïÛtê.V>ùÉ]á:‰Çêéø-I†Jx.ñc°shkô1îÇeOó&á4°A³ÖÊÛ(ü6+9Ş×¢0›J(2Œÿ€7ãàÂ=ñ£ı›ì†¾cœ×FvĞ¾O-îCn‹nÛÕôk‡ADÒ°-šV-áùŒí‚ÖèØµ}¡Í‰¾ı‰À_àä@[Ö÷èÈ]İÓµA#÷mŒMIFÎ´]Ôhn2XênR¦×#è0‚M1×ƒpÔí2~¨Ô¡u¼sAAëíŸÛëLŞ»¶Ò#—ÛL³Åh)^tÌcaB7mlD,66Y6yœ-‚‚ˆ<B\À.FxŸ:^hÁ×¨ºˆã1¡?ê ˆÒsVí°Àµ¡Ã$õ)4IF-iÆ8}ÓG6¾Á}6HÂÓ@€¹–rVåUÃy`æß	CÛÅ—ƒò…ÜÒ…y¯8îè{{øßÿûÿVˆc“¢ª R¡é¸6·ÉœšÁğÂö¡a'fåıF©é²¿ÛAp[j‡¾vzT¿5bö/ îqoùIHÂĞK++h„İ1vÖ8å†4<®Z„>n$"‹`·ì DÖWª(†NM3|0Ö‡@,ª‡÷ ú_ÿõ_€Š›Ùşàjÿ.±÷¸íXı#‚TJAÆªUJWÆŠ½ª)V*ÅÊÖye»Vı¾¶ó=9²jWf®-,q_á8h3†ØXX\«—^­÷ş½`Ï•“æ/>²‰ğ”p¢šîBDßĞÄ§¿äWÅ)Gø_|œXÑ,²ïñãOÆm~…ià2ïõ6ÅŒ{0§@KĞT…¦Æª‰¶zÜS
yÁCUM¨jÚ2!uÌ >$oÉLi‹'{.ÑÆb`JCÖ¥?Ttòº`L«ÂâUà!Á¬*(rNv11‚^q£ñˆİû14Œ˜‰d…Š7´^7¼¡@£<’)b[ÅR8˜Fˆq#‹q‡˜D¨ íA‚ğz€Ÿ©ìŸ5lÆT,gÁìŞPöL­;C4°)uS¸Ì&óO“ëœø1¾o°M	l³G.·¯ÎYö'“tŠ¤ÆCamlÈ§ 7à{’#ğ‹*X(W¼ØØ#–Çğ"¼jBdÈÓ†+PÚÊ.½SÚ[—z
?2)ğ¹öú s
˜Bx-Î÷é[¶Ïq~ÜÕ¥PUYŠh›Ã4{¢4Å–KöâµêÖƒgàûWôÀÉ™~C°C¸}ïß¢@itfFá®lé˜gğÔS¡Ì²Ë¦b›İ¯¬ÊL–C¨,&
(È&DR6jp°	ÍU#›E(ËxeÙ¼Ä/²yõŸG©¦gÚ1ÜÂ¿ÓqJÈ›ìü{üH{´0’ãn|°ÂêÌÔk^ìIÀ(<÷È²oæìZQè¨ûT5©[²KLa¥º¢upš¯7÷O ‰Qr"Lñ9GûU¦ğ-S5…o]))"ÖªØêÈi&ïÀrš,‡Ñr"¤Bb§P&ËİËœ:¥ï\”rĞ)¥ŞÑçàãŸZ G%½œgXjNª?~E‡zíİ»ô½ãºZã’£$ ¤ÌĞ‘á„ä¢Ÿ¨O?&¾@gàp©¶“ü e?ÓÑ>§c'²ÜôƒsÈ2¾‹†#®Ùã¦7=DÌt9-¥[L)¬ÈéõÃ%(Àd22ûòÂ:¡`ˆŞŒ¢~ÈĞRüóL¢%¾4Cx‘jƒF£â
‚Ğ2³ÚÑ¼„ÃH_ãBòfTS4Ş,#ÄùÖòt¹@>}pIÄEÅÆß6F8aÑ¢BÜO4†Û7Tíã±aµrlÆ¸ZÂ©dÆàZs
¯…n"X¥é
÷nÏÊÑ¿˜TÏÏp\^wH¸ïr9äœ•<¤¨ƒHê†ßé9¡M†´\îåmtbfCÚqP‘Eğç_ñµ:û¨Ê'×J…Ò™GÁˆ¬€tÂÑáú«ª!SH]Àèå‹®à0†ÀØWPÂvá¿‚êL)bYgËe]ß¹Ê4nRœÏØ’¨-Ä Æ®Ğõá3šÍ2×‚€ÆZÀ:şÔ7¹>š~UXØFn•rEİ`ÇQ02-æ+Åß%˜¿kZN(ê|¤bâM–7º< ŞQ£^¤^ÙÔÑĞEwµM¹:ÛÎEöÊˆuR¬‘ÇëJÄ=á; 9$…Lb V›3ºÇÈå¾ğ á‰çkÚ\²`^L€ŒN#ìK23jónt Û£°[õ‚Ğ„E˜Ïø¬Ø|†]n;çÊ@á¬Pkq\„*á€ã•C`€)¢AiPƒÄ!óDËãğg:¦b0I„péªõ)œimÉ;r Ó),LŞdt‰øÚ´Â™Ä{-¤8	„8¢‘/Yš H‹óS{xBHVÅãLšĞQ„ÅnĞÉİÔ·OĞ@Ïò¹–ë,Ÿ #!ëªô¢Šèœô“èA™kÙ˜§jNù¤e#­«x®‡#@ÌÄ.RÄØí\£Kã)4½4¿ğQİTV/ØA(İ£z¹¾h%ÚñÔ.¦Í4ÈÓilğx[4ˆvèñ(nÀNÊMÒšêâ7ZØºØDyÕ·?Q´qu¾*Tm«†¤Këèm«49Ò4íF¯'èR;ùIÉ¥±³åU¦Ôb²Ş/ÏU«¾M¶Ú±¼‹¨Ê¾&m)™­Î0ïQtu±]ZyÕY6Æ-™êëcªV-›{éhXVBo«„0"ôRf‘q”©lNFr"z8÷JÑ&§š5-dS=¯),°JJ(BÇ¢û±1†-MH¤8áÑ2§3ÂLº5ª4S§U¬]DóuÒ`NHef?LWvuDYr¶&ëë”Õ^‹ƒìOO¯ÜH:$ßÏh‡¤BÆ?„ƒ£á@è–¢ÔT™¶Ø7V6h\¦·ZŠPh4b¡–†÷Mª–ĞSlßzÆìVëCŒ U*C9C¥È/* xç•âµR=cv¥ZTü©Mç¸*`·©UAÚ=Ëjßƒ*¬Uæ€¸L¥™«…ƒæş+b&Ü9¸¥ˆÌùpôÛÒ,è©ÙU‘L`½€òÂ+Uöw`¡m:a©;¸©TªQ1¶Œ2vgo\¾ié"išD¥ªÆG!}ûÂ¸v—FOÈK¿XWã{£|^ÙŞN”ù;Ş×]èƒdäˆf„¦æ:ÔPG•ĞhiÌÆHhm-¤M]	ûó”~—XdñÂ¤©KlŒ¡Ò"V_„Aóø°±”Aã‰£µïTË†Áøç‹T+åëÔ±2Î$÷E%ô4Dïô8ôø,PÒğ”BGì§Ód?¨([Šå5®:GfÚK\2™ PCæ´È+ïO¯$¹¢Úx³ÕL‹€·±Âÿ6¾(pä2Øsmt×pQp¢6á]Û¤kgëÙƒùèÍ÷ÓÕcÉ:6¾DÄøS£jb^ò¬8Pb¶Ç²'4¯`éJv±U~Ì’’§¶2è"oÿŒ—~É¸ƒ$‡µ³bZË“ftœ3u&LÔg²³¹I«‰GĞ‰!L„ZHç(62L‡GÂ§à•4MLŠ–)@#ãÇ$`¢³('ò*Ú{ª§D>®âx].±ğL€}úbc´5Fßxû¸İ	—ıòj›Mp‰ùœƒõ³ÛH`3.Ş–Ut§z/¶0r·ÔĞæQ¤'ÙšÌN/J\0Ñ–x§Ö>¶8°vw1¥î)$¾pÉşlŠË%´"Ë6€ø›ÀÖ¿“Eà©kRWt)Éšf‰¨2üFÖe¡Àr¯Û ›–+f‡®a§uÍ\ öŒ@ùÁâæ`üÛl0…s1ŞğÆ8ã ã·Ù@«l¨ }5é«x¿ÀÄ7óÒ.b²ğÒ‡	\LD>&~4†"~„`§–û±eFË¯	Aˆ×7"~Ã«¼/’o“„Û‚È*±ÁIùiãòbt‰4Cm­~=D‚xVœë‡TúK_è^J/Òå^æ"RÁñş5İÇ¹†vd¨áÖÿ•í\—÷uöìşĞP.í¤AªI	´QX¤RA©PËå6ØûÖ'rû»äÀ‚Êø[?K<k‹£‹Ãã©Pê=Ê— Pwàtp·
o Y…fmd±‘KîYĞ!È)[fŞdÒÑ©j”ö³¸Ò» ½0¦˜á­ÔVDf†ì9¢ØİÜÜ&4<ÿ²$ªJû{­£v«@_€~vßó¸I¿ˆs%êsÿó•Êòü×S<Ùn.ó­còù¯¬şßŞÙy¶<ÿõOÂŸi!uLéÿİÊÎ3yÿûîö6İÿ—ıÿ¸ÿıjŞ×¿/ìøßèğc/wxÿ6¯×½‹äEğÒÿ‰Ökdy·Áğ´GjîOs]ü¼/ÈÉº>}Ù{úBøù¢İ›;§›xqèÜº¡ù‰÷ÀÛÆiı-ÆV;â2øQ»R_û0úÛ‡^íÃM‰½O„¨ùÈÖdÎÕÓ¯“½‹¿\Ô×Á8¹¯…‹šs‘DLÉĞIfHÆUWòö2ó*úã¡±7Îé]è7G@`FWãFÉd(ÉrKQ¿Ú—Â_©f5/Fsœµ½œĞ¯gk‘²+ÓÜ?M_1,oRáÛ ­ÿIÆª1 ÄH
ÀŠ¸ü—°CûWÜSÌã<¿:û(.Ú“29aş›ÃÅ]ê˜ã’ôÓí¯õ5úY$	"ß][€“÷÷¥,nhİŠ‚Ş½J&Çdäe^|Õ™Éß•áZ˜Ã1¹ÖQ.^&¶Y‹¾öék^Îyå+:¤s 7k¹p°¤sAª–ÇN:¤B®(›á›bö–Ó›)JîÎäÜ|¸ÅùA&h$#öTÀ]dÓ2)ôˆ$HD
Àı`$ÀÁAã¬Ußc}às˜È¾PL(“Q_Ã36€5;^ßóëæ(ô¢Ù`.¢ï>Ğı()àIYĞ‚¾ÈctuƒŒwhtYµå‰»/´Q£BÓ¬¯Iã!Û)Oî7¨ÆÅíû'Ó©RÜ·‡÷ 3c(Áı`Ä¶V	âÚñêk×N*8^)*óŒêkd³Tª½ª¯iÆÑbQZF9ıà$’U7ŠÅĞ™ÛèÊE”Vóˆå;n=vP8$°~^|—;h¤cF[*&Áhğu‘€ÃÀôo%ZV £)Ú\ùJ´ÁÄ"c/¦X¤-¼7ûM±—'t€’p·ñ Ğ£Ò˜Õuù³0¹9k÷¶N.ŸE?ñùµÅÕ1Íş·UİMÆÿÛİYÚäáñŸ”s  âª¼Â¡€ÑvªâCtå&n)‰í(u[¤Æ7¹`êHMŞØ’[¹—¢ÊXo#×ğ*Ş³SÃK{jx“ÎRĞÌúà¡ÕE×ñı´ÿ.÷ÿàyåE×ñ ı¿İeÿ?ÅŸØ]\³öµº°MñËËñÿ$Ï˜Ûs­cŠşW)ïT¢ı¿­mìÿí­İ¥ş÷Ï
ÓãR€†öZÜ¶ês-&ï¦‹Cßÿ›3Œß‰"Ïÿ#N'áßÜ¦Ú!›ªº;CQ41*ĞhˆA{.}särüBü·¶JNÎ+@73Pš£ÕërËxOOàk3êòYÈ“
Ç²€:î¯ÿmW–úßÓ<z¸ÅÔ1{ÿïTw·(şÿÎÎRÿ{’'%j!uÜüoíV–ñÿŸäÉ6ß:îßÿ;ÕÊ³eÿ?Å36~Üë˜²şƒOõÿnµ²\ÿ=Å³tú|j§Ïß¬³çãÂ'â&|7…{äS;`VŒJùI03Ã˜¢xU#˜bğÖÉE`ÓéE¼SÌø™x•ˆcƒ^…Cö®èw`}‡^çWøY._åî–Ëû?è3%Jì\ê˜:ÿom%æÿİòNu9ÿ?Å³œ¯“h'çk=jòouònŠ‘±Y[»M	#1†á­æôñGÁsĞêÔ|á%òá&¼xşeÎêÔX”˜ó.~Zvúğœâ_š®ˆ4­	½!‡Øqë¯}c±fÁî@ş9]<QS§¿'c¼EOloØ·ÇBæŸïùk‹¦åóÏØ(ğs¬cÊüæŞÈş[…¹×ÿ[Ëó¿Oò¼o½Ş?j}ÌR´w˜rÉéW„*¨WŒ2ÿ_îıëÖQëtïc®İÚ{sºöóù›“fã¬Õ>»ß8?ü™Ÿ9h¿9Aßßz×ìóõ"X>‹xÆŞõ0Ç:¦HÇÿù<Û]Şÿú$ã^ƒ&šÖ9ôyòòÎ"C'‡óKÔPê˜(¾6öËç±Ïô]_Ç”ñ¿µ³#ıÿw¶w(şÃî³­¥ıÿI¹-Ğµ_[ñï»]XÃG‹L~fÉbmÎUx²ÿ+®ö±vTtŠÊj_,÷S7AVeÍod­ü7õE?ÆmJ¬ûÕu½QŞ5€ÃáÅ@˜GYØË< €áe-/¿¼E°b{o¶‹ùéÎU½¶àptÂ¾¼A•îfR¯f‚rÊr_–Ób4Ä×kHÁ£`Š*,& ª7UËÄ´¦p[†Ùkğk‹ğªMF³Íf|Ò4q¸Ó!Æõ¿°»xíÓˆîósB#·¢å×¾)ÁÅkÚ÷`dy¬3ÌdìKˆVŠ¿¥D-N\ª‚—Ì¨#ÕÙŒ— VÀ/‹q-fÙxyÚ5’ÖŠ,Q|†šøm
`qóÔDø¿âqèŞğşÀ½ì^!Øs”	r²·?ÿÃÁP-ÿ€6¨]a‚‚ÇV(ß¦øytjªlT*‰l‹\=ñºïÃ£Ğ…ãáñÎ½GYğ1§­kf¼w¦u×ñF':êÒs¼A,™Èrï…€ş˜;»Úu~7MyëâFÃ×š
˜SvüêÇ'­£fû<Š ^Ïg‡/ås­Ov‡­®ßX’×‘Êè%â¬¢…ÇUÿ5r I^ÔÎPÒ&Úès{¢¾ÍY[¤]Ëô­ãQ8…u`RÜyCÊ	ñò‘èİú`Ô"Ê2Aà¯=İ§)×õÍ¥©ú¼Hı¯²[Eıü?—úßâŸ¥ş§êéë*—Êßâ•¿6E£QØ:Èàöa!K$åç	À,VûË`»E¨~Óªy„Ş7ô•¾lÀs”¿ïİA›‚§QûŞAqdÑ(NÙqØâ±2Ü_äõ%%Äğ\ˆ*M¼_Y®¾³/¼K§ƒWåªJá=aI}O—­åıF•¼	OÖuÌó®cšş·òÿİ~öl©ÿ=É³ôÿ]úÿÎìÄ/Şß ^úû*(ÌŞm_õoYwªª¸yÌëÒ]ÀşÈ%ÍV‰;ßÊAÿÀ6à Ÿ¸3ÛıgMÅ¡9è±bÈ^½98`EºbçoÛº0N½xÁJá`¨fÇÈ¼Õ©ä@>ËÄ›^·ãÓ­æ×#by³º¹µ¹½¹³ùìAäÜ?Ú;m¶Îß
UÅÑû§£dµJ”Ü˜•~Âméw‚}íyxù,Ÿå³|úùÿ»\Á h 