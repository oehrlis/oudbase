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
    export LOG_BASE=${OUD_LOCAL}/log
    export ETC_BASE=${OUD_LOCAL}/etc
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

# move the oud config to the OUD_DATE/etc folder
if [ ! "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    DoMsg "Move ${OUD_BASE}/local/etc to ${OUD_DATA}/etc"
    mv ${OUD_BASE}/local/etc/* ${OUD_DATA}/etc
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
‹ n( Z í}]s¹²Ø&U©ÔåSò’Tå%8´öHÔ‡’¬]®ésh‘öê}]Q¶ïŞµîˆ‰³"gxg†’µ¶Nå!UyL^ó–Ê/Èoº¿$İ`˜’²HywÏ`×6gh4F£ÑhœÛNå«%§jµº³½Íèß§üßj}‹ÿ+«mÖ«µúÖNµVcğg{ëéWl{Ùˆašøé*¾kMÍÙ..¦|íÿı•¤sèwÒ?ƒæßğK¨czÿ×·¶ŸîPÿ×7kÛ˜±ZÛÚÜ¬}ÅªKÀ%‘şÆûÿÉï*Èç¦?(<aåÅ%€¶²×o°•…ƒ=õìk³oû¬õjƒ½˜ø¶cù>k[×ÖĞ,'`¿gİÉxìz[{Ñî– L×´.-Ï²ıÀ3}ßbõo7Ø7µí:{54ƒàÜ›\^n°îülyCÓé/éCsd<5˜6ààck\O|ìÖ…é°#kàm¶æZ~‰ùôÎpéİA £ç t§oaé•}Óv¦siõ_Ürò·Í ª[Í€x–ëÚöm×Id‘x¶ã‰7v}‹Cz<Ãº=Ï,pÙ¥ÿ,f;Ğ4§g1ŞBfúÌ³‚‰ÃznßBJ¸åKlNĞ>‡¿F¦íoÙÄ·úìÂõ˜å\ÛëP§BçÜIÀNß´ËP5|"¼/ [¡66‚±ß¨T.!çä©SáóQÄ‹[ïV û¸ÊõnğX­Õo˜É2Æ@¢0¶çØmÙµå!!O­nÔj˜gGæiõ)„4f´àfvæ^ §@C%Î2Û…Jİ‘ı³ b^°>Ğ`;zİ>;9::=k6W>*OrØ&¸Ä¡g¸Şeñè8}lãÃñ(¸6Œ‘É0`oÌáÄòĞ Â›ÎIwïè°	½Yhµ;‡ífñôäu§ÈæLO€wÍó¡Å†î%»°á‡9[ X ö‹£n§Y|ÙÚï~<às‚l„£©»{²w|zvØ:è4WÖÃ3l¥Z*œŸµ÷N:»§G'?4‹•`4.ÒË—{ûPûÊG-Ã]E/n¬¬İÓÖÉéÙ÷V»sÒ,ÒŠ'ººmå£Rû[{Ã9Şòİ•hÌ²•õbá µ·ßj·O:İnxú®gÂ€4zƒBçääè¤Y-¨ñğäà^Nœ2ÕC˜ƒ[ìè»x±×¾yi­•ØÇ¸lmÛşxhŞò®Ù)äBbjzÕvüKVÜ;|yÄ¼âx'ÿX\{¬l³g8º÷'w;ÏY¹ÍÑoÂïŸøïcí7®×	Ìÿœ½O«„±ò Ù©r¶àä0‚É2Š_§O)Å½´â½Õ»¢éÇ³ÆC»Gr)€Òî(Iö½Föm°ÓlÛÕÃI‚˜´ÆË —Jºğ†Å+’%¥İ‚	ŞÀ$Ä§ä´rûî%‰'˜à?î½BépÇóÙìGxY»cåË€UÙûïp~w
²™»CËtZNÿ&vÀó­|¬ßÑgks­Ì“xéå«ŒŞ_Ø…»ÂÂçºÔ¡uÀ‹Ë¨À‘Â2/k¨Õ×J…ÔÎ½Ãã×§0IÖ¾n¬ß¥1!%ĞuÍ+‹fëİÂ`p.Ù¹ÿô9m{ ¯äêÔ®tÀŒ  3“96èdQ;‰ÁAøn0˜ÜÂ>)Â+–;İ;èœÃÄÒµ„ÿşëÊ_Ê_÷Ï¾ş¾ñõAãën±ôİwJÑ““ì¢ÎŒÂ4»@éÏ¨÷èÏX«Vo±¨fXçßµFJ’…,ßìE# Hrğ]‘5™PâƒAf•êÂ´¼TGoàbş'`DEö)°,V6•ñ–ÔÆÕt0a6Rò§?°/‚ğéf€ã°Æjø®}W«â¾-‹ĞŠ½œÙºÔN§eUZšlmßu¬¤lZ`·=Ö¦_õÓ‘œŸxËÏ¡ˆT'TŠX\tS6ƒé‚ñƒ,A9š5ñ¥(O‚zB$×P‡Ù«¥pÎEé
3mB{VÅUMÉ²w ™l´m°·°$¾dæÈ8¤‰›Şå—È¾Áº0¸&4­¡xï¹êzÏP«¨Ï[…ÌÖpj/Í{&|U+!µX4}Ç¨S}œÎh	yÚzqÇ *x8iíîwBíæìE«#zf­TŒêñ­€ k/ÍkÓ¢ö¨µ§V›y×û!p'½_ña»4²ßÌĞ5ûìİÊÇï€=*†DR·9³½]fû_œ_@Ã¬¾Z~kfùç…>izñ™­áÅ©w½‰ã ş"lB=w42\ı3Àõ}EEO…º9êíû¤Y%µl•£çá­G#İ¢¨9¸Àq,.¿‡ö-Ñj[ZŞÀBY‘pHhÌ¶='=a (4ÄakŠV`GË#•îhâÈŸ•Xñ
<U ¿OPˆÛüñE–‚ÿ·ß–b+•?¡‘ìÆt“ù ¿ÌáĞÕ†éfŠ×Î•ãŞ8¼éú^3KCÉ]Bøë8X#÷Ôjj>æÃ¢‘râ4õç•¾u]q&Ã¡:y à#<Â<vôr1n–È‡Ûû çPr“rÎÅ…•w[ª‹ÌÆU]má¿ÀlqI— ¼‘–+©ÒiËÊz-\W^ØŒBÜ¡â}šq²ÑeŸ>Á—ß±r?öYEP«µV…Ú°®}$
'Å]0ØÊÚJ›hê)“İ-4ö–â£uqO¤XÏ‰e{AèrhĞƒŸrĞ)¶<İ€ƒÀÅŸ§"ePãJ®ıÆÂ¿ şÃ~ÿ{ì¦VTlZócVÒBØ#:]jj…ÊÚ´GŠ©sœpœûÂ²Üi?ÈÆ­pà™cVÔ¶U-âZºPÒ¨®ØNAp‚"C ‚N¹˜ÙÍb½	hU™ÓÃÍ”¢ ×½p¼]Z;¶ÕË=‡Nhb6"…Ç¦Ì İ‰¯;Di6¸¶íÆONÃCm/\~pEŞ¨Š,ğ%·ÌU¡{]ŠéÃÊ7»ÄnUFF6=:Ò¼Òæª6æãv´Œ?Éªi,#¯Wb'ãı½İÖ)ñXuJ:W¦Cùƒll­¬«­…Bi¡·eFBÆÅHÚ¢cQUçİ‚¡	˜3{æ°"vë¹”(²´ì9G2Œêß×
˜‰ÛÙWş uH©`N‚0{îHˆÁ¦Ãüi+ vÛ,AÌC’&}â›"b¢tÊH9%èïña3Mş„“ÄäºÆ<qî+„,‹$à?åbªµ÷®Â½²˜ú ¬|<~Û¹ãdú˜"“ù§ÍB[›ÉÎá”áSaL“™8R;QSã\^9Ëe¾w[¾ğl˜êŞ8n¤ĞhĞïcÏ[^`[>¢¯8¡¢Ö´¡üµÚ0–ÚZÈx ¶€³Ÿëœ5›c³8ê÷gõ­š–]0Š)önC>Äw Í>üyÇä›â¸ó‡›Úe›­ú•¿¬TÊ•U•¡ÔO.ÌP/ÌŞäe{mn—M†=ÆmDôrAT<x
õ!@]z¥òñğ;¿òÎ©°Êww°A¦é§ş‹ÈÕP ¦¦D-1~:æ3‘6âøŞÅ±ÃÒµ¼kXÚ ãuÕ>Y»„Å`Óc«‰,bÿÑêku—¤QúÖ&ZİIË—.ÈªqKtpOJ‚^´*ˆU™‰6(¾+àzÆÆÕÔ~»uLuÃÙT§—-)àV>ÚbÑĞzûç³#Ü X3o®Øê‹Î«½Ã'İfñS~Ë¤—ô³øİŞ«Ã£“Î.ÌÍÚw|UÓÜÆ˜û+«ü¥Õï{Ğ®+u|õîÙ*Ö²úîy…}„F­­lò×Şx_pªß±;ÜøHëz§÷8+®Ú¨uz}dAïl×
ıì.JvS¨$uz}.Vfı,3©İ,LßÔË{ga½Cš ş¥Œ"¨.—aÄ(¶?¥Gpôë†ùç)„–Zvæ<EF³•ã#Ğâ[íƒ½CuêÉœÅÌşÈvæ˜Æ’sWj_eÎaZ“²º5Õvı½ºU×'>Ñ»\†¶NÅPˆş¤âw‚qïXEsº“¼¾Ã~÷WàõC´qH^ß®§2ûı¼>}ÿz»®±.¶OßŸ¥‹XD–¿´Ûg˜¤ÿ/wáú"ş¿›[ÕºğÿİÙ®W«äÿ[Íı%åş¿_Èÿ7p¿ÿ_ájÂü(·gÔÙÙÿ­»ş~cÀÿKrı­mÆÚNà¹ı	h=°lÍ{È[=ûâ6òÃ",z—|±îÃ¿mgà…zßÛøQ}xÿ†\xÑ_7Å[Yá.¼	WÑîsV±gJÃ«ù]vâ¯;¿³nç}lÈlêN‰ŸQ:Ñ¼°ôi™XŒ§Ï}dÕG–å>²¹,Ë}dsÙÜGVˆÈÇw„â•Ò<sâË=dgÀÏ}Uïé«º ?Î/áU˜ûõıÆüú kçğMs¦_¶ ¯€@m¹kß¸vÁÎ} ğş||õ[cKsÑ5ìF‡ÜôÃG¯›áV7‚ŒŠheMêy2ï'4İú•w•w¬rYZšßBü÷~Ã.^\ 
±ëÛQ-„ÔP±¥„6ûĞ900ÏSí"±‚1#Œ2tNw…ãĞBXØcOXÏ³p5kêÛúh§±Š=:ó `ÃgW{â´õ¢™¬(%#‘ãl¯‹ûÖÜÙèš­şåÉjtäèSo æ5˜¥ä\$Èğ¶urˆ.#º&„ÈQˆxïRÚç%èç&0eàb1Ä´İ:mİUÖñØDTjâoÑ¨!ÑZJº!eÈ X‰%Ôœ´×¾áNŒD'mQHˆ›º½ëï*ïÖàïÒ;ÄÂX_©¼«UVKQÓÔETHñ¤‹´¶·Áé¬ÈÒ¢àë‰oMckQ‚<à
Iü#C´@÷ØêÆ*ƒÿJBì{ü$ˆcİ8·X¥\ÎèõÁ}çÀz»ùŒX’‘åIpÌ% ùwÌ\ô¢Ówã°8îCbñğ´R8ÃyíÇYè}$AW"@~xäIY&®AÏµ.Ø'fÉáVä¯>Ñ3”Ñ×»4\ÜñŸ\ÿX@YF(m¹? /Tî)õ–ôe(‹°ìu×¡Òd¼Á|wâõ,Ug3"UäUªv'?ëZ^TÔ÷C¯Î)Ñœ{/Yy,ıYş‘ü‘Ú{'º]BC+»Å¡éœ;˜òóWá·bÊ-·&^ÄË3?ğP‰AŞYÃaV–¹EÿØ8 ½×¸4í7P¢nÔ‘ÉAç^ıñÇÆùĞt®ïß¯–I ‹FŠ^í
³¤›ƒœŞtğôì ‰nYÚ6Ä:×eV+ïŠïŠ•ˆÊêe”£O%İÊÆ‡(í\Çà;34÷³•²3îÎBÔî¸B¯‚Îî^Ÿvõéñœ ·×Z³
ÖÚ=:8h¡®/D{‡w±<ìÃ`.—®P#èD>Íå,7—owšè–¥Òó!*PlXd3¨yÖ6o…Å|õï¿¬Âz	 ÍK_˜È5"Å(˜øŒ^~#pW¿øHÃ”pb‹†¡ô äİÊ“ÖÏ•-P’Q±æ	Cm^g^Ææ¾)d‰C¹‘»]1Q'wÔIñi@>°²OV•£“F'TÏ2Ï‘q¢%HR
"	J®­Ñ¿¯•tùj>ÏîöùéâOz¸²»€eö-(0í¬~Üüu¼fmÀŒÕwoœP?eóoluç°¢´<<Ykõbh,Q¦W²ØEg#XeÚ$íO,òô¡>çğ}y«ZU—ÿ‰Î%Ô…«PÌ®ëS"A!¢HÌ	S5!,fÁÿËqÅü"Iú"OÆ_Äÿs{s{3ôÿ¬mî ÿg}k;÷ÿ|Œ”û~!ÿÏpÀıVü?yƒşvı?ŸğÿÿÏoê–çÀü	w	‰Ö>RQèºr¡ç:dK†gãYÙŞç¥YĞ~¥U£ö«.û¨n¥§?c‹^ïïÏİ Ş(Ùg/¸h:½[…?w:ÇÍ­ûÀÀ'£sĞ¼·–uEƒõÊ²Æ5ctlËeù{<ù‘ÿ¨{94/sÚ_³mÀ!«şö}iÃ††Ia*z«ìît:‡§­ıÜ'÷3¸öå“›Ç­Í}r©Ü'7÷ÉÍ}rË¿$ŸÜ¹\rs§ÜÜ)÷óœr…n—tÊÍi§€ËisgÚ_•3í¢ãdşiƒ†İ5:Ëp£`	@fªTgÔÇp²]dXËÜk4™1÷Í½FÅ^£b{nN¯Qï_
Ğp.§~s|ÚW|ºÂâ _àìlÑ*®<*3–IÆ7ÖëE†5}´cN†.ÛÆ¹±¬+æ)¾pØy{ö¶Óùóá‘bsy],öÛÑXDïÊ+qà®T¢â/Z»~}|Öí çñJÏ R(Ä´Rìk\JPAt'ÖÃ*¦PH)¬wQ;Ñfì$j¨„é‹QÅw³áÖ,ÌŠïRì¬
È*†YoRî=ÌêÇ©;oşb=‘SÀ%<’±¿M}Œ9|ñW¤ºè¾Ê‚“È)3Áµs…{³*R+ÂŸŞ&†GDQQš/«€Gv<¹ó&\L¥0ºÃ5Ìm˜§gW>ê¸(…ŸætU]EYZß‰å:FŞuû2êÆ90êÅJFxC·°òñÏ½‹yhTQıp9L#¸ü™/óv_²çY­Ñ4$_n€û÷h[¼è"‡wšPÓŞiÊ5šV1{<røŒ‘B•ÇIíòQÄûÌ€¥†3_
‰‡n2ñwc»ŸEç4*cA­˜ÇñüŞÆÙÆ/Rõ=œŠçr(µ|¶Cñlgâ„Í?›õR›<‡¿pLİnM¯Êé™P‚¦tÑM«>s‡}ô×Şc¨kĞ4Ÿâ)!Üb“ÿ,ÿñ”&Š«p Uû˜§.©Öi:IÒÜ±²—>2cgïÌd7ãĞU›páN@×_³.¤‚”‚t)scGŞñ³ Wo^îê}ô¥]m‘	³ĞÌº”:¦ûÃï§Uôÿ®áÛZõ)«Ö6ŸÖæşß’şİú÷_ıÛ¯¾:0{ì¨ËşQŠ&|÷ÕßÁŸ:üù+üÁçÿ7ÈÖéé‰ø‰%şüù±,ÿ&zÿ_@7ÌñxhCÓĞ×òO»˜ñ¿–ÿó?á¿ÿëüÏÿø væ)5i7
-©éã¾mÆÇÿV½šÿÇHùù/sş#ôÄÿ5ŸıàÆ):‰‹ç,y×Qtr#~h~
d§@ªÉS }X]Õ8´)„°y€à¢Á·±[n¡œ}·wey©'Dè¥œ!TŸĞfB¾?}x·‹&ğ‚O† ´ 'nØ­;n»%®õÑÍåÚôltÜñqå?´{v`@çA‹Ëƒş#‡ì†Aóá>Ş¹9v@Ù å…ûE°®~V†ˆ¬KúŠ¡ãÎÿ¡h`¸æ´f h>{.ö‘Áë<ˆÍ¬áP\jÃ`ò3ñ/é&2é•¤Ö<D2<D)0/ÉÜİÚß?Û}İ==:Øû'ºJÉ€,”ëØõ}[…Á9F£	e[ˆäÆÁ“ØÖÁzøÍe´9™70v î¯LªÕ
h„—òr˜Ò/$L
Lh÷T€
B!0q`H7zƒ*jn„»eÂ0:ñÄmEš¶]ª¢î9fâ'‘©ØŠŒ”&cƒh·U,ÿgÃäÕ^Aß $gÔ‰XÙışĞº1=Kıòà­ÿY ±,ÁûSëMKETƒ÷03Àˆ¥¬Ò™'êJsXısÍGeÕ)JÜ¬	9¹µAìº§Ã³‚^%nŸ

ÖvIFp!Ò3tŒÇQÈ-ÚªlñùícÆÂ'¬g©ƒüùRÎÌu”ÙûM(4>ï2ëZ$5ˆ :W"É„Nv@î[+¼»ËÎÅ¥‚0D;ó2.JI¾WÆK3t«À'
 yÈİ´ÍÈ‰²‚0¬éyöv[ûMg6Ísú	Lj7¶w!æÂŠ©ØM´:nÜ…$òÌÑ0PäRS3Ç¦€àÃ_)õˆ,ø„åÖ@¡@gŒ+ôÿ‘.*íîXØEäX†Iu2^/I‘w¨ëÑ_üËJ¥²úi p¡«•˜H©a#ß<£û#Š=@%üİ(Çq¸Ø½‰ÁÒ'†uAçÅE¾j4Š¥È3v!pÑ±ApËÇn(Ÿş€±o%øÎt“ÎeAí=rwÂ˜Ö«7!4*b‡<,xôúd·ÓÆıñ“vl~áŞ¸ÜeHØÏc~aå—î««á”æ÷ş.Ãñãç§{ÀŞòzë ÕÜãÖé÷èva{~ ô¢‹·BŞØ  xB·y=¯èDdC+æ-É£nëM§}†ÀcğŸ;ÅË(¼0Ê•Üİ°=sDnyO7ÎÖ¨'ìtpÎ—*(Iae·]î Š¬BT’ø¾#Í@‡š
ò$¼©J0¡O*Ü—kÔ»Š(¢V„o1`RcÒÑAıGÉ$Õ $Î!eÓÁq¡?ÏƒÀtšr/J¤h¨…Ÿ](ş’”…y|Dc\’áèo–ë
srdçt{UÎ¡1ßÕûû­>ĞUÔJ>u¡¥ÃÁ"Öò°ÖµFãà6CÅ„Ÿ`R4òàYŒ?AÒUs¹Ô<B3VF1¡˜p–¥Ôg†tA#B§ƒX¨Ÿl1Ew’â&{>Ë;6Ö	ì¡î²
g•Y¨ËÄ(’MB:í¸ğæÌ¯ğN‚SÚ—­×û§ª·E*Ã¨Úo¬HèğªU¥°69¼Š–„y!˜Á})®Ú1¾»7ÏeñÛıyísùlÑ<Füµ4ÿfuÒ4ı@ïI ³a…¸ÄÊâ¿'&ÎåiÒ–(¿ßB$Ó¹[ã¿j2 ‚÷¿}ÑYõ)V#—ûìÜ‚I…Gé±¡ƒàMx&¤D-­ù)ÈLi^×Ñ? ;ºÂ/¦ÍÊ*ÄÑg	ÇŸ~©ÁRÂ“¿è
$®0ÿß”¡ÈO}&Bu’DÎ1€é/1ì#è–Ó×x¢i-Óa{UuØ^…/ºk#»—wjYtèÖ‡êÖ/Bz	›ÕÉxõ;î—ÅŸÑÇ
Ş\Ø%õ8R?ÖæÉ…D{ïäL’Ã½JYê©şğ‡hN–ï¤ÑŠKò>FwP§êhÿ¥Xöí!tnQÊ~40ş-¼'^Ø*éd49=¬ËÕi.’G¸¿É1i$¼,S|{.k+=J‰’‚ÆZy±}@¥™RadGÊ¨¯ËÈÏ«Ô³î·[Çì¥S@cHßD¶®Od;ëv÷µ¬-ròMÍJa’µÌ'ŠW¯("3Ÿt‹ì¿…GBP¥ÓdœLªLÂôG±äcÚ¾Ç±Š†G–˜äªp°1¤m7êld8™„˜öOìí´TÔÕ¹Ì£2ªxˆ(åé!U€bÕ&Iyº‡<ÅôD®3İ£ì‘Ñ®Ì“ìE®4¿òÑ¾cÂ¦ZSâ¸o•4pŸ¨®Â‘şùÀ6#`cÏv‚VÄqÀ¾.×ª>üıÿªmáßş;§?`Ç_Hi{×Ì ®è-q]ïâ ÓW+¶¢Öã><–)Gpšã›¿gÈI‰r)V ÊÃ»Ü>¦nq†s œ– ]¸jà%èÆ-¶ğª"vâ±’K_š²U¤ŸÍ*Ë†,¬¦#Öò°À9h*eŒ¸ÅDrúĞÂ…±t‡rg	”¦š$÷w–Ì \×™“5¸¬¦è’ZÖ\ágkğÓŞ«fv·rMü£ÜG yk…CH±³Å¾¸²—¢¸z/;lµBš)'äÇC
¹C“Be£ò—•ÊxUÖŠ³¾_î]\–Ñòa9tåƒi¸0OˆÈD}¢¬ë{:a´¨š„0Öjë.±:ĞÆS•·EQòÃ[á‡ï[wâñÑ¢î'r|ãĞ¢Ñ^;î[øÉÍy:ÊEFÒ4¡Ê	•3•9©Q.nA*ŞÅóŠ\ğ½¶ùÍ·ÉïœÂ™ó=İ|š’ºï£ü	ù¾ù6„§1ù@FcGºİrak)¥gâë©ŒÅ”R"¾jÑ–,±|ê²%±fQòÆ×-)‹%w|á’Xµ,–ZËåÎ+5Äù5{VÜˆ²a˜Ş½“sğ«¾„ù]]C…]N+§¦)¯ëüB©]w4rcÓƒ	H+W {CùN,FjØ:zODx?éA¯äÉJ]ŒŠDÜåz3J;.™Ao°ÁF–éøxD1`=6ÅlèP4Y’09Iñ m
ŒK#ë¡Ásˆ~ŞlÍ³(V¹R8’Ò
`!Õ·=~X?z­­DPz¡›¦×ç˜İXğ¿Ãop!&ÆUøÙXôÕ”åQXÀ<ı3[á$¥æ'NNJrª,ŸKŒ2U°D0L~¦/ªWiõG¥˜¬ÿ	—¿æG:ÂŞö\ òôKH¾`‘Oâ!¨„ÃNî Ú( €LÀ4üæL»ãÆg®y…²!÷:İÑxp>ÇuÊJÊñÒõnL¯/úl:çI<°ã?°{Wtï ‚C/<(;°<…N0QGıCQºø;¥Ú$ábtP3Kı;‚>N g1ˆnó´'b“õ|T€4dP©]ó¨2’/–ünq±¿Ô`mR-ssxEú³pyû/ K`È	mûÃú º“æeƒ\˜L2VåÂaß$Å%ŠßVK‹-…jcİhN†Y1¥DLƒ³îéÉ<Æi&ˆ†áŞËn³!–ˆJNRbBGQ£Bí†={ö,Š°€Ø¤íµjK‘4W@:W­mII(ª\-Ôã5…Å%r~-ÆL¶éëŞb)Û˜öi‘úH“ú(¥ŒbÅj:hÛ5e5¦º©$ DŒ›âç°>ÑÖè)Ö²k*…C ÑŠšï+„ı›¾§«8†VC˜Šé©¡™‘
~×(bt
1@Ò[„gOâÛ;+6æ‹Ïº¶a¸Ê‘‘B†6qœ'¼º!Ü{c±ª•óìY$`B¶¸ÊB.wš
CXè]XœÖóñNÇ­áˆ$¡S>—‡Ï˜áîÿ81ì—#÷ñ·dxPÛR÷.PL}N[sé¾y8	¢;¤tjŒ\%¥sà¹í42­\â£BË†âã,sK¬•Ÿ,T¿Q@daçòè$†â"	|lªÛkäºğIH:ÙùĞÁVÃÅ½JÀ&kRñì¡[-ê›x°Œ#é“—ttœBMq -ı ²®9´AR$úOÎ i2Ÿâ×‘î_%PÍ,/}³;Å¾².ëùHŸ™]’>Â@»JåùÜhÄFø|È¤ŠÕ±¸V—÷rtâO*!kHÔÔJbœoúFğ!Hsó9~Ûæñæ(ŸğèI-,3c{„ç6¸Ó,£mü„R}šˆ±º‰¸y‰£Èé–µÈ¿Fõ0ZÄ¢è—Fl?,µYñ_0^ŞÿY«oíTk5?ê[›_±í¥b%Òßxü‡å¡å£:úËâ‚û÷ÿæVŞÿ“úno¹ƒÿ«¹ûŸÇÙÆø/µí­§yÿ?FÂş?éÀš¼cŒúKªèñtk+3şOu§^‹õÿ&¼Íãÿ<FzB:eãêĞR“û¨MŠp+çú_ÿûÿ¥5¨O}ÓëÛ?Ë½_{4¢ùß§r„NjF
?­-ü71¬º eÆ8Ú@änjcğø=slùk1îËå@siáT°Asˆ&ÓÛ0ü	6+9ÚÓ‚#û–n&üÁøxÃZ‚	í°Ánè;Æ	q,t«gş7¨ÅCÈİ§pŒšÉãpˆH*a°dî~í‚ÖèØbÄk¡’¡õÀŸ{è©5]:iCWà]X •z–FÆ¶$£FgÚ³ju6¬·7(Ó«	tÁáz•¯ùAb›Œ	2Ì	.ÂĞ„‹YZ+˜¼w-¥F¡°.™f‹‘txË=Ğ±›Ö×Ã@&ëë‚,<ÎŠACD!.`ç§G{ªbİiP “h]íŞ¤‡4 H÷ÑsÛ&©O¡iRjÁHCöÈšt­ñnöÁ«	İç"§¯˜yÙÂp.˜ùÆ³ƒÀr° Æe¡|7·aFŞ+û¶3ùÀŞüëûß€âØ¦¨:ˆT`Ú@h*wbúãsËƒ†Û˜•÷½µM‡ıÉòıÛJ7ğ¬ 7 úE¨sè»'ºÇ¹å§g9:jœpX>AKğdë®(Œé³ÓÖ	_&¢µÊçq´Ğ2ôq=Y»Õ`oq€ %Ò¾REtjš	äƒ±>bQ=¼¿ Ñşç¦ dÜÖ÷G ×øk…ıˆk±^ß·ŞcD˜ZÅÀXíW’•±ò €ŠÊµZ¹¶yVÛjÔ¿ilCŞ´Ú½Ä)EÃ»‰«FM\JœmÎkg¦7Ê¦ ‚·Ê¾‡¿ÏÙ3åHïó÷l*<%ì°„f|ĞFá7´³Eï_ğû_•°ÏßO­h)Ù†)åFÛÒ,pÉ»mÃ”vSõh1šªĞÔXEá~³ÁpŠ#¡#/“3x¨²)UÍJŠKÓÖGûB3ÚâÊ‹5„±˜Ò5é”Ö/³ªèó*ğ¤bZ9)½Šˆ˜%A¯¨ÑxRßEñ F§Ü2"™¡bÁ ¾{`„"HË±Í")ìÏ"DÖÈbÜ+'*J;Ë#¼ài&û§[AŒŠå,˜ŞJÀ¦™u§ˆ6£n
ñ’ÚdşizS?F×<ÓåqÁ‰`ö(öÔ9Ëú`’ÎB‘ôx(´õuyìôâ|s~Q‹åÊçëëbÄònÄ‚·BÍQˆÙ"ÚpåJ÷ÓK¯ã”¶ÎÖ¤ÂÏm
|®İ!Èœ¾!¼‰– çœ;ğğ@ï®ªà¡ÊÒĞ ¶€iöEi,:Š,ïÅoõÍÏï_ÑgNÎ¼ğk*€
Äº7øšÍéàÂ]é ’1ï 5¡ìÒË&bÛİ¯¬ÊN–Í Tš@”tÓŠ†")O58Ü”æª‘íB”e¼ºt^â±ä_şÃa¢©ÙL›Á-ü;1 „IJÏ¿ËÏÕ‡#9ÎQàF§+(ÄÉ\½&àEŞ™ÔŒˆrì(ûæÎ®õª¹OUÓº%½ÄVê ?\·ÂùúÀv’qšÙª ÂTŸqD°_å¾¤¾áÛ7ÊkWlu4“w`Í
VÀ(ôWr÷O¾–;’òıÀ†öy¥ R)L?|ôSä©¼ïç}5'Õ=¢W¿öì^zn€q}ûY¯£8 ¤ÌØ†‘atN VŸ1?}ÎÀáSm/şE\KA‡Ğ6`÷¬X–›¡—ø£”ï¢áˆkúx§éM‹¨³]CNKè3
+rz-Æp Ä9	˜L&&†S%#“0Do†ÁFd82şy.Ñİ­"¼HµA#ˆ‹Q‘~`™yXá¼„ÃH_ãBQRS4Ş,CÄùÖòts³@>yzJÄ—EÅÂßçVaëá¢B„»ÌàöuUûxh(¶›3›ğl™3 Û‚B²)—šp¹àö¬ı¯šEƒÍ¼ï¸¨;Äî<}]2±Î“'â0©"­[^o`YÒ
…·á¹uiÈAMmÀ7®wÅSèr¤jŸ\-ZohGœø2Ò9oÄ‡+°ªŠL1•Q£¯1:¤ûè+32¯,¼~ÆN)¨¯–\×Yr]7´¯Rí‡Ñ]^ÜÖ«®Ä Æ¡ì[t¿`úbĞXõYÏ› «ü?
€¶_¶‘ÛD%†\S7ØQÁNúK˜É¯eÒïšÖŠ>ê˜xOú¯®€yÔÀ³çÉ•W:u4tÑinC.Ï6„ç…½rcb½k„dÄû$ä
ñî“ ’R&¶IéÍ)İc
Ÿx”øXúÄÚ-˜_@ÆÏ	ö)ş3)zó'nu ã£0\ı‚Ğ„U˜Ç]	û‘ı-»<Şº/N·6ÂWXÖâ¨UÂGK;[^µJƒ$ºÇZZÓ1ƒI"„kW­OÉâL‹KŞ™hİ˜Î‚áëÆï—ã¿ÑOœöBøQ—h³…4'G4tKi12ÃÃ†jO‰Ã«¸‘I:ÊP¼é]íM}ÿ-ô<º$“Ü7Ø¾+å3dˆ d]‘C!ãÎ`ı”¹zy¢æ„£Y:áÂŠçú|wnjl€İÎUº$BÕKAóÕmeù‚„Ò=¬—+Ñ€V]ÏìbÚM“äğ=õ‹‘Á\=ØiDÙ¡IcZTßâN[»(/‡Ö
7¯ÎW%‚ªíÕté¾	ÜÆGZ‹æİğñ{§§„\ÊÌ˜.¯R¥›’õ~™xF¨Z5ñm°•^ß=[ <àcÜ˜’ÚêûÅ6!û¥‰‘Wf´à`œŠ©>>¤jÕ´i°×¡~–e%êºJ#D/aÉ¢Lmc:’SÑÃ¹WŠ69Ğ¼¨i!êñ|MaAßa]©:Ô1¢ÀÇ4!‘â„ÜìŞw0y¼ß°ÒTFLT‘vÎ×q‹9! •™½ F\ÙÕ!eÉå›8n¨SV{Œ­Ò;>9½r é|C7¤’
qÈN„ƒ£á@èVÂ·‰2]±q¬ìĞ8Loµ¡ĞhÄB-ÏT-¡§¿õŒé­Ö'†ªTÆÖ…J‘_T ğÌ+Åj¥zÆôJµkfR46œ£ª€İfVyhû,­}ŸU©`…´2ûzüe>Ã¦­öÛ{/‰™p?jbãz,"èç£§—æAOÍ®Št\aÒ D ”^©²Á+íş¤T.F7µºQ7jÆ¦QÅàâìµÃwÍ"+](ÍQ“¨Õ @İØä($¯ßÈjweâ{v¾òSÿªf|cTÏj[[±2Â;ÂÌ¡Ñ¬ĞÔ\ûœj«:e-‰Y†„ÖÖBÚÔ3@ÏèWq‹I/L›ºÄÎEöæ«/Â }tĞÚ;L¡ñÔÑ†Úw¢åŸ‡Avú$ÕJù8G’:VÊ’øÆ¨„dãíg?…*Rèèñušì¥á ¥K1Â¡§<&ÑUøÈLñ+×§ jHyåÃÙ•ãµãQ¦}w¾šiğ&RøßD—Bù¶\»…ş
NÔæÏİk‹tít=›c°½ù~:°z8ZÇ†‚¨ˆHƒj,TMÌëÁ¥u ûJœ÷Höæ,]yğg~Ø“’GZRèr¬ÉQ¨¶¢ÓÒh=.áĞ¡ÒÄQ?Oç&­&Ç'j„0Ej! q¨|* ÈÈ0LŸWÜ41(Z6f Ó€‰^L£œÈ«hï‰Yø¸j‰3s…ØÂ3öñJßÏĞÖ}ãíãv'\öËûŒ64vÀi$âsÖKo#U»TDş–Ut'z/²0r¿ÔÀâQ¤'ÙšÌŞ Â|0Ñ–x'Ö>–éÛ°vp%.ª$¾pÈşlŠI´BK6€økßÒ¿“IàeT‰5©+º„d
L3DT~#ër¡ğ«Ù/°ı	¹böpK…t~4u.€ZsåÇ›#˜,Àø·ù`
ïb¼â3ŒÑ2² ã·ù@«l¨ }5é«h¿ÀÄ7óÒ*ãká¦.¸˜Lü$ƒ"~‚`}-—;²¥Æì®Aˆ×¶›	¿a W_^FÊ·iÂŠíùşd•Øá¤ü´sy>¹Dš¡¶ˆV¿"A<+¢À[ú—âÎĞÅ¤4^¤Ï½ÌE¤‚âÇWt!ë*Ú‘¡B†{ÿW–÷~M^Ø:°†cC¹µ•¨&Ğ:&A™Jù•R£PXg?v>ßß%æGP²¯}­ğ¬%,îOÎG6êBoïQ¾…JD¸}»‡»UxÉ*4kóW}6qÈ?ú¡59eÉÌLz:ÕªÁ~ºç´fÂ3¾•ÚŠ(ÂÌ€=Cô »››Ã$€†ë]VDu~eo·sØí”èsĞÏîyş7é—r°DI÷?ÿWÛŞ®åç¿#ÅüY–RÇôó_Õ<ó…ı_ß¬ílmÑù/ø7?ÿõIÜÿ~µèëß—vü¯ô
øÌKàÅŞ¿Îkàuçy¼ô!uOYû› OKRq{œëâ}KKÚ…ğÉËŞ“Â/…ğ®Üİ¾‹CçÖ	Ì¼Ş´Nšo0ÀïÂ—Aºµæê»Éßïn*ìÇX˜÷lUæìõú²wÑ—ó¦â:½j1‹ædŸ§F²R2ôââÁ½•¼ƒÔ¼J†a60´õE9İsıVáÌèjLùJÃk¹£¤_çK1˜3j…ÙAÍ‹!çm/'ô«ùZ¤åÛ{'Ék…åMÂ~"†˜ ód«È  ìß	 OÄ…×¸‚[?ã~ŒbàùuÙg@qÑ¦ˆ”…hÌ	ëÏnRÇ—¤nn®ÒÏ2IXùÎê$˜¼D.apAãFy-ó>““áyñ{.G†×LP|[^ÇäjO¹l™Øf5ü:¤¯Eu8•¯¸œÌÜ¬åÂÁ’Ìoµ\8v’¹à-ä
³Ù!¾	f`ÙÃÌLáˆPr÷¦çæÃ-Ê2A#±§î<œ–I¡G(ABR îû“l¿uÚiî²!ğ9LdŸèLy˜Éh®â‡>3Ö5{îĞõšæ$pÃé`ÎÃï0¼ğ•Ï_¥Aó‡";ŒÑ•u²İ ÙÕ0OÔ}á ˜fsUÚ ØvuzïT¸=-*nİ¯8YÎ”â5¾ Å–Añï#2µI×¶Û\½¶S/Ô•y&ÍU2Y)Õ^5W5ÛX¹,cü6d|‚—$AU;r¹x s[C@¹ƒ²ß>dÅÓŒö§¬Wßå
é˜¡ZÅÄŸŒ¾,2ğp™Ş­D«ïÃh
më_ˆ6h G,RLñå2íà¼Şk‹­ñB(ù7›Î 
m8)YY“?KÓ›³z_ãT–¢óKË«c†ı§ºYß‰ÇÛÙÎí?’xüÅÍ@\•×X,-Ú.ğC]|ïÁ—›ÊËnøvK¼®Á·ÛâmüÚÂ“{)ªŒø.bïƒiàe/¼9¦×¹ä‚fŞ”~Ìq±uÌÿIûÿÖööÓ|ü?FÂC«Ë®ãsöĞşŸïÿ,?áyåe×ñYû;yÿ?FŠNì.¯yû¿^ßØ¢øÕ|ü?JŠE	XJ÷ÿ›;µzŞÿ‘ôpË©cşşß®ïlRÿooçãÿQR"Çê¸ÿøßªåóÿã¤Œˆ­£:}ıW«n×BÿŸÍ-œÿ··6wòõßc¤'LKTxÂ^‰kDÂ3İNŸÉR£ëLşÊÆë…·oü½‘P^û|OµG{ªªwEQÆ¨p“1m»ôÌ‘_(ğ[…ğïÆ
q1x\ºˆ^àv´zQ!'ó8ñd¾4£æi))=~Øbë¸ÿü¿]¯å÷?<JÊŒ·À:fÌÿĞñ‰şß©×òùÿ1RîôûØN¿¿Zgß}) ²¢ÅâÆ|w…{ìc;àÖŒZõQpSÃ˜¢xU#˜bğÖéE`ÓÙE¼SÌø‘G¼JÄƒ±A#›Â!»WôÄ;°¹M¾ı3ü¬V¯
w¹z÷7šÒÂ±.ºóÿæVbşßzú4_ÿ?JÊçÿ|şŸ÷°ˆŸÜs~Ì'ŸïïÆ²®†·ìb2Š >üV¬!§“ÏÊù¨ÅV’ø[¶ÿÕ€|"^ºú‘ÉÎÊ{ùz¯/„ÜısÓèØóçáí2;Ìª?ÿ}­°òõMô`;=­›_ˆÕúÆæÆÖÆöÆÓÏ"çŞáîIç sxÚú¥PU˜^’õ:Qr}^ú…÷Ü`_zşRiF¸ş…Ô1KÿÛ†±ÿ»UÛ©ƒş·Cû¹ş·ü´°‹®½š†¶ç\€Î^ÙÈÏ,ôY—3ŠŠ/¨aí¨Ç”í”äuOÑÖŒ4mCW×0fGLcS52	¢ºc -Æ ~€İ1¢’É<5£Š_-L~y:bxiwˆùéÂ=½6ÿpõ‚¡¼>Zk¨¢½ÉrÚí(´º”
¦¨¢Ï@õšR}Rƒgéò;_Å©¶ze÷ d°¿Áƒ¶o°KÏ…÷ö4(Q¸»1Æu>·.ğŞ	]èdFá‰–[Üû£—mhßıIße½q’x¤Kt–ÍÿVbt8u	>/™RAzgèl#•Ï¯	€Ö÷-¼7ç‰?o-}Q|V5ü–.ª¸qd*pÚÄ´;¾?d7¥'ğ¥€vlÀ×ÀôÄa0>«ßâ:bG,# Ùb%áY0‰ÎITXqèÙZ}ÚÜÅûÜˆ@WÌÄ»ğ#
€÷%Š\óí~—yd£ğÖt¿éXŞãa@?]ZA¡…ÇÄ_²ÂB.¿/œŞ­&¿‘ €û÷Mq‘Õ+€MW\9SxÅa…£8~ñU‡-ºüß}½´‚	QÕù`õˆçî_¶Bl÷Ö:ßw/í^•Ã¹ãÏ€uNğÜ±
®+.¹>šãIĞ®Dû*ĞIˆ÷D]\s7G“a`—±AÎ/=§ß'eŞµÀ:fèèîúÿÕAwÂı¿ÍüüÇ£¤;‡¯ö;ï'tÛ*2ïˆHeMĞ@ø…_u;'{»ïİÎîë“½ÓÎ^·[§îÙ›½ÖÙÁüÌy÷õ1ıl^˜C±^dyZFÊ¼ëmuÌÿğ6ÿ›äÿ÷tg3ÿ‘lçÚrpş>ƒ>OÌÄ"C'‡³KMøÒØçé¡iö¯c¦ıg{'´ÿlSü¿§›¹ÿÏ£¤Üş£ÚRo4ÍM@Ë7EQ¶“FŸù$?‚ù'–kJg¼eæ¨év ¹ ¦)(öeÂoÆ¤ÆîX®!Hñ hwÛİ³ğ¡f1ı† JQ7şÔb×ºôú¾%£rSO¹áŠşeb’ª©gFIw/xbá™‹{õ,ÎÚHºeè×jšqKøBê˜éÿ½¹óÿÚ©n×sıï1Rî¯G;î¯¥‡_­óV[\¬ìº…ª9)oIÜjAŸşV=º
} a¿×ò—È‡ğàz—…~¯ÁÂ—÷÷zCx Nñ.MÇş™\âõ/0“pˆ=§Is§¿‘»9øçdñXM½á®¼â3„|l¹0QgBæŸïùK‹¦<å)OyÊSò”§<å)OyÊSò”§<å)OyÊSò”§<å)OyÊSò”§<å)OyÊSò”‘ş?§óÕ  