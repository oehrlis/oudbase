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
‹ Èü	Z í}ëzÛ8²àü]=Fv-‹ºØ»ÕQfKI{Æ·c9Éö&Z¤,¶%RCRvÜ‰çÛûûwí<ÉV  ©‹mÉIw‹Óãˆ P(
…B¡P¸pÜÒŸü”ËåİFÿ>ãÿ–«Ûü_ñ°ÊVµ\©nï–+ÿßÙ~ö'¶³hÄğ¡é*gOÌÙºİ	ßE;¢#Ïô¿7²Î/ÌÎÕhh½Ô1¹ÿ«;[;[ÔÿÕ­İÊÖ.ôÿvu{çO¬¼ \RÏ¼ÿWş\B¸0ƒ^n…ç÷ ´Õ}«ÆVçöÌw®MË	Xãõ&{9
×Ö´¯í¾7ØnÈşÂÚ£áĞóC¶ş²Ù.@™¶i_Ú¾í¡oÍª?l²ï+;Uöºo†á…?º¼Üdí'üÕöû¦kÍé#s`ü©1mÀÁÇÆ(ìy¾øØí®é²c»ç÷¶îÙA”fx”ö·PÀèx(İ²œ0*½z`á^Ït/mëå-'ÓãºÕøg9µ¯ÀñÜTùg;ùC/°9¤—À3¬İñaÈBñ1³ßgşÈu÷’¿i²}FÛ±$‚ÚDä¬]ğâğk`:nÿ–Ûb]Ïg¶{íøKı	ıÒóF!;{Û,B­ğ‰PîBdÖÃaP+•.!çè	SâÄ
PºwÛsïQ û	ÊóokğZ~fÀ0‰=cŒ0aĞr'tÌ>»¶}¤ ä©ü`”wµ<‡æ/ĞÖÑ:@*:n§?²ldh&4Äí2àG|7ïµÏG{­” «F¥‚ w%À†õH4„ŒmÃ/¬İs™×• ‰ã*[É‚ú5êØ¬è°¡é¿†¶€‚¡İqº·ƒ÷$ª†s'g‘íâŞÀùÕZ#p-¤ZwP9¸&ŒÀQ?doÍşºêØ½m¶÷êe£’k7NNZGÍzşìôM+Ïf|V`x˜}è
ï’uøa‡6ˆ-€ıò¸İªç_5Ú€Ürœ<ËÎµ÷N÷OÎÎ‡­úê:"¸‚­–9àÃÓ³óŸZfë´§7”\&ˆ\ ùêg¥è[ËG ¤‹¶ßhL³Õ|î°±Ğh6O[ívXôooÂ€5:½\ëôôø´^Îı|‚-zsp0sƒx£dŸ½ä¢éìvhçşÑjÔ·ïG ;.`@@óŞÙöÖ+Ûæ@Ö}˜êùbQşÏØ!‹‹°W}óReÜÇ3gÜW#·ƒ¼ÿåàæ=äµÙ¤éÃ¾yËŞæå¼…uW€_/°Ï9ì‚h°ĞØ£¤¦w\²üşÑ«cVãÙ7“ìü¾Ø»F!ù¦·s)’Û/X1dÏ‘Uá×€=WØ>~ÌÏX±—âª“­‡8;€/àmLÙëTÙŒA<¦lûêÈv8gKIŒ)54z”Æp 2˜ÕööN[‡­£³ÆÁ8)2EXšNæ2GF6Ş%	>PL>¿~µĞºãùœ.{‰•;V¼Y™}ü‘…=ÛÍI\÷ú¶é6\ë?GNÈó­~®ŞÑg»Š‚Ì—¥ÙåËŒÒ»Nî.÷4ä3 ¡:k0\Ô!ª¯r|Èì¼9«Ñ¾«mÜMmgæ•Í@#÷o‘A¼°á‹Ó¶	œ@İ¯eC ñŠ=3™ë€Ê·“”C˜6L›QŸäá…åŒí¶Î©O`Ê²@bùÿøîçâwƒâwÖùw?Õ¾;¬}×Î~üQ)zz:¾¨;¥0M}PúõÿkÕêÍçÕü»–ÁÈxd!;0;ñÈÓl‹|—gu&Œä`Y¥"2)/ÕÑéy˜?Æ	Ø Q}	mPMe<F%µq5L”†”üôœn½İôpÜÖXíŸ_ÂÕò´*îÛ²­DâÔÖe¶p28-«ÒÒtk-ÏµÓ²iİöâEV›¾1êg#9;ñ@>Ó´À`¼°ADôûäÌ{•	eu
Z/|f3Í{ê È”ÆQör!šrQ¸ÂD›ÒìUiUQ²ƒ@…ì-  Û„@ì,ç/™9ğF.Íñ¦9Âå}`°6Œ­Íj(İ;ïÛÈãÚ†ZEuÖ*$`¶3{aVøhòdø¨3½l´[ÌõBÒßÚª–h^ƒæ‚Z˜¹2ò7ê[!ôF_Ô!öî¦ï™û°úù§cè¨’!‘TÁmMmoÛƒiWèv]h˜m©åø¡PÊş¶‡ÓuM€ªÒ3û}O#Ä_§vá÷Êõn\Öò}ÏOOm8ª('ŒgZ,¿šÏ
‡/–„ÍæñF€¶×³;W1Ë ‡:Æ©kwP‹óosRNÊl\Nê2’ò»˜-Ù›©AndåJÏš[­DJl×a,áîtcô‘ğÁxtÙ—/ğåÏ¬h%>«jµVÊP[.Y[GoAiuÏRS‘l‘Í
¸H=\Ÿ(¶Áœ!ê P[æ‡£3lĞÅ2!'æz¦\I5jèk<¬Ñè{—ùñäÃª/J–}]rGı>'Çê_YÑş
\ö—¿`Oİ°¼²&Ñ(°÷ä¢NÑISQ+TtáÍ14³ íä ˜×rp°ğz”í-'†9V±æÃiuõ¡¡qøÒ˜‘·l6—vèûta3ô=E¸¼èxƒdì#•"Ûe>ÇuQšõ®ÃšSÔZ5œ!"…O~¢N~½‚À¦¬¯ëBbU¾…° 30ã	4øµ&¸;¼ÕÜc2 £b[]—Š›ÌûíãAéÃfé+]ªë‰VAg¢ì
ş*Ve«ªp%UIï²2IŒÆ¾b5ˆ,ı¬ë{º¡y‘¹rOL˜q×:ÛC•C‹p`QƒVXÇ·q½ejH%Áf8¾-†öï>Ğö”8k¼¬§+ÊÈHä8?ØoÃúwıÒ·‡hYûçÊ#ùpî¾tF!`^)X+¤…® Ã»Æé!1U#òD"Ş‡Œ¶ó
&YÜ{Aƒä.z›³Æ]i£¿ãR#­!±¶zŒƒKq(ÚØ;hE}/P X)%FÚkßpÿF¢“6/X~Õ!N_Jÿ46>”>¬ÃßÂÄÂØX-}¨”Ö
qÓT5?¢xÒ”gëœÎŠàÈ¾ö$¶%É¥ñGlbÑÒgk›kşW2Î·ŞµúÀÉ.ÇMtP&pŞÉQòÁıà
Àz»ùÔ@½Áµ8èimÌ¥ å/‹Ï8¢Pˆ†s9õ£˜ãÓ¾jàÓøgg³VqåU™ñ´LyA½^dX3@;æ¨ï±ì‘Û¾b.™âsG­wçïZ­+6—7ùBîø €5@œñ®¸úw î
*ş²±÷7'çíp¯ô*…BL+Å¾Ã¥üJ¡ ¬‡UL*£QXï¢fªÍØIÔP	3	qÅwÓáÖ,ÌŠ#ÿRì¬
È*†YoçƒÏ2àP?±—‹ppÙHÈ‰"Q¡c÷~Uú«˜«1 @n«–Üõ!(öv—}a¶»yô…Şa`1úáù—†‡Û`Ø> mÀJÏ6š®ö<ÿ¶M‰¼P±£Ô[ĞWÌñäÂú"×Ká`8Ei<_ı,ÁŞq2!µ3(¡ÉÇ«Ñp“ŞÈ‡DEá5bˆÊ˜©ËÏºŠW ”åpB¬[’rÄ7&ŒNËéÀKá¯Xu¹‚ì¬8dRı'NjîŸ‚äÚˆĞf¢"µb¼ñí]jxÄtí6PÕíİ•<²ãÉ7´ÿ+Âè×03´a–]ı¬ã¢J}b/Ğ&®ğ.5şRIvâÅ7Faİ‘Õwb¹Œ*†Ûu.ãnœcA N¢dŒ7t+üÚéÎB£’2Î9L#¼ü•/óö^±ãZ=¥i‘ï£kˆÜ îÑ¶dÑy4€Ô´šrC…¦•Ì®U”wk€b3zYh×¯6?‚q°@~õqÒ–ºLİd’iCÇGç,*÷P!Š¦Šnx^˜VqiS£ÒBKUûáeæ &óßÕ¢:EP5	ƒ9´%›óe  >±b@–¥ãÓš¨E®ŸU…áge¹•°èsÍ_Œµõuúøø]ñ¬—Ùä`DLÑõû a×	z¶¥·4¡n7F¡7€ï˜P‚¦tÑMkóúúë@ï1Ô5hš´ò|a•-Ü“ÿXıø&rUĞPµYê’j¦“äSUûVô³Gfâô™ñÍ8òÔ&t½èúëö¥‘V2.ŒİØ?6ƒ¨£XŞ»	kF‰ŞÓï“vgûÀZÛ2ò‘)OYĞ¯«ú­Æbv‘öŞ­‘š#‰¼U!¦·ËeÕ8•v„ºğ
Lì$Fgğ˜"ú¾ºfàš‡Aªøµ]m¿ÉGúsi÷Uü¿·¶ËÕÈÿ»
ìU®lo•+Kÿï§x–şß_Éÿ;p¿ÿo¡/ıaı¿¿7à¿)şßKwí,h¿wíŠQ~»ö\}µ¿mGí¥÷òoØ{ùwî³¼ô5Äcß”¯1[ú/}ÙÒ×xék¼ô5"ò›ñ5f39/]—®Æq5nqBÚÕx{kZùC‡»^ éĞ‚Ï·¨mK—åÁ-]–—.Ë¿)—å¹;-›nËƒšSkÕšµ_á¸ü®ÉM¬sóhğ_d!¹_	Æä‹£³"/nlú×È«IrÖèÎÉÖŠù[|Ê€÷\¨ÅÏßå2 ‹©‰ `õóÉ»&w[€rÄYÒ2’@ÚŞbIGÓ;!—ÜKOî¥'÷ïÑ“[0òŒÜpŞoÖë6-öboÛxÎÕ}j[ÿóättzJ4fh1hä8„ôÕ]Ñò)(+ZnM¼ˆÄó ôQ‰AŞYÇaV”¹Eÿ88 ıSÏ¹4µj(Q7«Èä s¯½_»è›îUíãÇµBJ"	`ñHÑ«½Sa´’"„ÖKz¶WÏ3:€§° V¹.³Vúßü/¥@”Ö.ã%xK8~=Îoü<B-áB>¹{¹Ç´"bàö›q«vAÁZY>Ób±oÁ`.{^R#ú^Çìã$R•«¡Ñ<Ü?‚¤Ğ‡…u£ß‡ŸI†eª9˜1MîœÓó!*PbXdÇPó¼iŞ
‹ùÚ|7Zƒõ@š•¾0‘kDJP0õyF‡n|T§îÄ¼,¼qE·&¼q‰İgöÈUš—á•Ûš•qîåª‹ÏLîº­H={˜».>Ó]v)×ıBg§Ëş¼ ›g[Ûçá*š¿t
½×óµ=ğ¾î#ı?«ÂQğUü?·wí
ÿÏÊfDÿÏ­¥ÿç“<KÿÏ¯äÿ¸ß‹ÿ'®ğdV´6ç-Ä³¥¾\Xo[öïİ	´b”X”è|1Ÿ§§bZ;=>M¦Ê[­˜¶	/qè°ÆÏßı¾]>Ù7¡÷ìNGµöÎOæKĞ<%Ê=%-ƒ¾±T.««ù§õı#9fxt>¡?)²Ó#œGı”'æVl²ç|{~ÿÂ«‹ûlvgRö8Rv—R?«x‡Ìš8ı(mÇ PÚ?’}¯‘}k,s»(\&é^¦=²K§ºuÑ¸ômıê¾­Ë8ºKßVªcéÛºôm]ú¶'{š>½ÛkDóe İ‡{·îL…Ÿ0óWï€Å@ÓG
òÚ‹v¤Ñƒñ†,w†¥Oí#|j§–'‡VB‡ÇeÓ‹OmMKìAïÊÁÂ&$\/4pÕ€³5NÔ9ùïÌÂ[	FºIgÔ\àº6‰?ÑîŸhµ#-oÈ'¹A¦V3#=a *4”^%ãöàáõ¡ÒMãÜÅÑí§„±’¨¢
qÇÅ]*¾ÈúÊÚÜ_3KCI:“zÚ¨Pó1• Tİq•Écé'ş;óëş=Õs<9ê–NâßN\ë•Ğ7‡,¯ûá–ó¸–Î=À{<íÜ(ãÓ©Î}ù…9—;äXŞªùOá[>Æ£{¾şá~¶Nö÷ghÄOa5Ï@ÙIçk)— Abh‹½Ñ¼Cš¼­Jb·K‰<Kxw)Á^°h$ó š{QìRÄƒJoÜP+ŸØ™'c¤Ñn'íy¨QRÂdO|DL<ƒN)g}ÌÄ;AüÄØL’?¿ÛÃD>&4™‘+µó¤£wšËs"g±È÷n‹]ß±©n!ÅõŠ …Ã~ŸøŞĞöCÇÈa;6âÖ4îò÷ñŒü
_èœ5›c³8ê÷gõíŠ–]0Š)ön#>Ä4Ï¦ÿ‡yÇä›â¸ó‡›ÚE‡áWKÅÒšÊŒPêf¨—Ü—Œí7¹]z0ê‡Î·ÑË!Q:öMàYX(„ö'òM[-}>ú1(}pK¬ôãİØ ÓôÿSäª) 3ŸT-	~:á3‘6âøŞÅŠØaáÎÜÄxmµOÄ‘§ÃÖRYÄş£miu¤Qú;Æu§-_º +'u.ÑÁ)	:ñª¬'Ve&Ú øj,¼8h6NèO{Œ=—-àV?;bÑĞx÷ócÜ X7o®ØÚËÖëı£Ï§ízşƒ[ü Ë¤Wô3ÿãşë£ãÓÖÌõÊ|USßÁ˜
û7+ıS5)¡p]­bÒ‡çkXËÚ‡%öµ¾ºÅ“[¼^pÊ?²;ÜøLëJÓ{œq·Ê”ïjÆÈ‚ŞÙ©¤úé]”î¦
Q)ÃŠ2ë3“:õüéäM½eïÌ­wHÀ?Ê(‚*`ĞĞÀárFŒbK2zG¿nè™}Bh™e§ÎSÓ]Ú3f1Šê<Ã4–»2ûjì¦5i\·fÚ®Ğ«ÛU}â½ËehãL…à/ÊĞÀñPËÿ(÷•4ç ;Éë»ìÏÿ^?BkP‡€äõj&³ßÁ«“÷¯wªëbû®Ç¿ÏX´ÚŠbAuLöÿİz¶õl;Šÿúlg—•+[ÛÛÛKÿß§x–ş¿_Çÿ7òêü-ûşòc’4ÏaàQ[®ub§İävÂï>
ì3ş›â üƒQŞÕòš¿àn*Q=@RŠo’QğæZUÂ»ñ<òï¢tXN{[,C@t%GØÀ<!Àñ|Pà`·„üÊiy° õ3CÎ"ĞK;<G¨¡#®òSíĞW¡;oÏÙS¡½9qÃn½pÛ-qm€û¤×¦ï –à9*Ğ­œĞ€Îƒ»¶ıGÎˆ‚ô¢=Û;Şı€²áz¾£VôÀÏÊ‘uIGb—.ï åØ@Ñ|š*ö‘Áë<“nöı¾Pjù L~.¾ñ“`d‰ÛÚjÍ}$ÁC”Bó’­6Î÷Ş´Ï÷ÿ-¥ÈB¹N¼ pTœc4šPF±H;ü×za=ÜrA!âÏ›˜}&‰ûK£r¹d‡%òr˜r«$z˜Ğî‰ „"`4’À~é‘e†æfd†ßãŒ|±Z‘Ğ´]Oµè4ÄXü$2%G‘‘²ÁtÙ„h·U\ÿ0&Ï¨ö
n ¥)8 NÄÒÀ±`YrË8ô«Ãwüƒ@cY‚÷÷ÆÛ†Š¨ï`fÖƒKYå¦WÜ•f?´}úçš;ß«S0”°¬CN®á‹XÙğì°SJ^4,2¬é‘ŒàB¤gäĞ‰£ßh¤Ê–€[Œ¹OXÏ3ù‹…án)³÷ÛHh<ï"kÛ¡$5w­R*B,™p'È}kG¾+\vÎï‘§^~:¦xò\|!:—zäodã·‘ïÔã38hëqèÈ
Â°¢ç98ŞkÔÓ»CšÇß
Lj7w.ø&S‰(7x&ç£a È¥ºvO>ü•òñXÉ‚oXn
Ü±¼Â¹K®Òóx%ëÆ[æE˜TGÃ‚Œ2óu=úÃ¿¬–Jk_z Š°J!…‰”Z162åqİ¡Hì*ÑïZ1‰ÃMÏéôH¾0¬#:/.â0©VËb÷‘¹Ày»„á-{‘Ø¡ıŒA	¾‘Y§óhƒ'OG~ë'Ê'û“İ%«%*xüæt¯ÕÄÃÿâ'ÿÿÆ]V¸Ã®8*ŸğS~á-NY“ÆxNrüğÈ§ì-··CTsOg?¡Õ¶ëøA¨ô¢‡VáßFèN(·çD'Â ëÛ	Ç‰Xµo[ÍsƒÿÜ)·ÌFÖÀ8WÚ©KÀ ôÌªI0"©2ş‰ªŠÄËga)Õ!.I„ß‘Ò¡d’º‡	Uˆ¨9Ùà¸¤çA`ŠkÒô o³‡p»ø¶™B·=2l›@n´²ˆXÁÂ
ÏÃÛ˜sò©˜ZiÀk€µ/à%™¢…'Ó¢§Y$DA*°Í; 4ê0`y81¼œl®Ñåòºƒ„ô˜àrÓbÊ%ºƒ=6ÈœÂ#Beê"±Œd˜ˆâ@;.¼ø Q¸(Å3ÍÖ«Æ›ƒ3Í7(‹uTí/Q$
~¥U¥09…‰-‰dÄ\xqŞ'Àá½¹oçİŸëÊqóæ6â´…Ånc¸xì›î0ˆt6#—”bã8q…À$ù=Kåˆd6ŸkœØÃ9İìsï6é‡Áù÷)[İ´XMÃlÄ/Àr ƒ %ò|Œ(QÉj~2š— ÅµÕHW}%ĞÔÔŸ€X!ú,Àaö›?;QIŸ'Ÿ,KôU¯‹&0;÷2XÀÉ1è–³7@y}làË55ğå|Ñ/yf÷
„™Yc&ÜÇ•ğ˜É"¤À‘°Y×~äÁÈø;ƒ”®SPÃùZ	è´JÍ8'±z.Éá]e,zÔık<;Ë4i¾á’ÜÂó¹ê¤ïDä‹Ó‡ÎÍKÙËeÆ¿EÂjG>óñäô¸.W§¹XáNÇ¤–:Ÿ“Yà'Ü}X_éQH•4ÖÊC:•fJ…±EeL}Ü“NæçUêYÉ…í¥S@£/L*[[Ï'²·ÛZÖ]w™•¼k´Ìêy$QDf>mäçØ‹;Ë
Òi4L&U&I/¦.ßQCù.@4q‚ı|Òb‘¿¸liÛ;™'If!¦ı“HôäuunlÈaU<F”òç1U€bÕ™$IùsyŠÏŠ\{z=WÙ-¢ı™'&ã¾2ä.:11a]¬(m·¸‡ªê€p¤?ØVlè;nØeyì»b¥Àßgø§²ƒn>ArèD‚”f‰tô©\ñ4¢Ä9úMt½K‚Î^i¬:ŠZ?øğX¤Áioƒ#O¤%Š»Fg±ƒ¡çZtó®²ÙÍÑÙ’™/ú)ºqÛ%$•Ä´14Ã^zLS¶ŠôóYA³¦Ê¥«éŠU=¬pšH#i;‘œŞ·q‰,úÜm@¥©&é3×ufd.ëŸ‚)Ú¤–ÕW¹wëŞñÑ«ı×õñİÊU4ñ™YòÖ*‡a{K*|Ie/%Dé¸ƒËÖJ¤érB®a<÷ıöüÒ&Ô®Éš#qfÅN÷²ˆ6Û%Oa!Ópa‘©úÒç»çT“ÆZmíVÚXªqªò6/JŞcx+ÜóØá}ë|>Z´Ñ½"Ç7-úï:ã®RŞ¦¦7´u"MªœP9S™“jÅü6<ù»d^‘¾W¶¾ÿ!ısA4Óa¾g[Ï2òQ÷}–?!ß÷?Dğ4s&È™‡cZ>N`¤z&¹³˜RJ$W-Ú’%‘O]¶¤Ö,JŞäº%cÑ¢äN.\R«–ùRk¡Áx|»óëøY2p§Ê†Q÷O+|ÌÁ¯êætúŒv9­œ™>`¤$WÅÉo0ğÜÓ‡	H+¸KQMn(ß©ÀH­[ÇéôAh¢¨de5†.FE*î~L¥]Ì°ÓÛdÛt £²‡"u(š,CëCDØQ`\z 	}ôxfë¾m:ZáXJ+D€…”åø<&@œ¬­DPz¡Ã¢oqÌnløÏåÁî7¹“Jüd
z-Êò(,`ş•­r’RóSñ©$¹U'c~Å™JX*œ?ù×«´‰ú£”O×¿Âå¯ÙçÇÛ)Â£D^‡~‰ÈöbòI<¥hØÉ]E	˜†v, 7>sÍ+ê”MQ’†£»²¹[T²PWcú–è³Éœ'ñÀC‚Ğé\1ôüDpèe{¶¯Ğ	&ê¸èĞ5OSªM.A5³Ô¿cè!áä	zúè@N{"f?]ÏgHM†y“Ú5Á&ùb!±Ræ-B"ÕÒìíu±fwÕõSs@¬.Ú–¾ıaİ‰Ñ)›æÚAÚÔª\Ø3œ›”¡˜¤­èû‚×Aì»öæn7îN6„‰ŠŞyûìtã€†ƒ4ÄÃpÿU»^KD5ÜÎ­‘Æ£¨Q‘vÃ?Î7O%6Y»®ÚR$Ë).Å(‚¢ÊåÄB=YSQk–ók>a²Í^÷æIxØÆ¬4¤Ef:‘&óPJÅŠ[ĞôXNY]e«7í1n†ïÃ\úD[ ÏhTcÄ®™ Ä+j¾¯õoöB¢âZ5azª)¦§šfzªÅ*ø]-ÿâE4@²[„§0’Û;¡§ËòÅŒo_;0\	åØH!C›¸Ã'+†¡Ü{c‰ª•K\ÆÅ›!~_ªó“z>Ùé¸5“$r/ÃáüğíşÏóçÃ¾I9sO%ÓpÌƒÚ–ú£¸wbê«pÚâ˜+ĞCJŒ*t”.§±Ó ôØ»pÜÚX+—ø¨Ğ²¦xûÊÂÜó0RT›9Î‡7–~
³¼d ™úåS™…efA~ P=¥ÖUf{æSt”¾/ë](ÁéƒÌŸOÁ>ÛqI :¶¼t¦›dD¼eNWˆ±X'JLC>™=ETCç>3É3!“Y(vz]ıŒ.Úwz¸&4‘›J¦KuD;u•æÔ“|äÆîªƒË<tòoçğı7ğ£ûBë˜|şŸŸ—Çóÿ•êön¹Rağ£º½õ'¶³P¬Äó?ÿßÁ ']4ZÚÁ¢¸àşı¿µ½ìÿ§y,¯³ØÁÿ§Ùû¿ºµûl«R†ş¯ììT–ıÿöÿiV¢-c`-¨ Ç³íí±ñ_Ê»ÕJ¢ÿ·Ê[[Ëø/Oñ¬*†$¹(®
-°Èœën£å^ÿ÷ÿù¤ÚƒÖf™¾åü*w<Á°Fï€
È:©ë}ü´®ğZÄcõtê€VC%<ø‡1X‚9´ƒ5ú÷ã²§9òŠpX‡ ÙGCámş›‡•ïkQ˜ƒM%ÆÀ›qpÍøÑşMvCß1N„k£39hZ§÷!·E7ïjª-Ã "iØM«–p:ÆvAktlÚ¾‰ˆĞ¾@ßşDà/ğ>r -ë{tÒ„®îéÚ û¶FÆ¦$£FgÚ©i´7¬27)ÓëtÁ¦˜ëA8êv?HêĞZ†¹  õö¿FÏMe&ï][i„‘ËmH¦ÙÀâ€´/=æ±0¡›66¢@‚,›<Î†AAD!.`#¼[/´àËCƒ]Äñ‚ĞuDé4	fX[ÚĞa’úš$£Œ4ãœ¾é#ßà$áÁ @‚‹\K9&òªá<0óï„¡íbŒËAùBndÂŒ¼Wwô‰½=üïÿı+Ä±IQU©Ğt\››CNÍ`xaûĞ°³ò~£TÇtÙßí ¸-µCß;=ª_„1û‡P÷¸·üô$GGaè¥•´†‰îŠƒ˜;kœò5;Úh×G-B7‘E°[öP"ë+UC§¦™@>ëC ÕÃûı¯ÿú/
@Å-\pµ—Ø{\v¬ÀşˆA*¥ cÕ*¥+cÅ^Õ+•beë¼²]«~_Ûù|Hµ+3ŠF×–Š¸¯p´ClO,,®ÕË@¯Öû/Øsåté‹l"<%œ¨„f{ĞÑ7´.Åé/ùUqÊ±ı'V4‹ì{üø“q›_a¸Ì{ı„9/ãÌ)Ğ4U¡©±j¢]V7Ã…BGŞcğPUªšöÄ‚LH3ˆVÇ»!SÚâÉK4„±˜ÒuéŠÖ.Óª°xx>/«
Šœ“]ELÌ‚ WÜh<Ÿb÷Â~ã³]c"Y¡bÁmÜ×o(Ğ(¤dŠØV±¦bÜÈbÜ%*HóàO^ğ3•ı³†­ À˜Šå,˜İJÀ©ugˆ6¥n
ñ‘Ùdşir?Æ×Sâ¶)ágŞaöÈåöÕ9Ëşd’ÎB‘Ôx(¬yØôâ|Or~Q‹åŠbÄò^Ä‚·BÍQˆÙbÚpåJ[Ù¥7pJÛ`ëROá§>×^dNSo¢%À¹àn+}Ëö¹"ÎïÏ‘ªª*KñÂ`s˜f¯Q”&¢s¡¸ÀrÉ^ü¡Vİzğ|ÿŠ89óÂo¨ v(·ïİà[(«(Ü•"óz*”YvÙTl³û•ÕC™É²c•%ĞD%Ù¤¢‘HÊÆS6¡¹jd³e¯,›—øE6¯şó(ÕÔñL;†[øw:)b@	““Ÿ&Frœ£ÀÏP´™zMÀ‹}©œãÙQöÍœ]ë!
uŸª&uKv‰)¬ÔB/°n óõã¦ãş	41²QN„)>çˆ`¿Ê¾[©¦ğ]#%EÄZ[9ÍäCXN³‚å0ÊıIoÒÉd¹q(ßÑû©ï\”rĞ)¥ŞÑçàãŸZ G%½œgXjNª?~E_víİ»ô½ãºZã’£$ ¤ÌĞ‘á„äŸ¨O?&¾@gàp©¶“ü e?Ó©:§c'²ÜôƒsÈ2¾‹†#®Ùã¦7=,Ìt9-¥[L)¬ÈéõÃ%NÀd22ûòÂ:`ˆŞŒ‚mÈpTüóL¢%¾4Cx‘jƒF£â
‚Ğ2³ÚÑ¼„ÃH_ãBòfTS4Ş,#ÄùÖòt¹@>}fHÄEÅÆß6aÑ¢B„;ÃíªöñØP\96c,.áÏ1c@®9…äÂ|¬Òt…g·gåè/&Õó3\—×}î{ƒg•<ƒ£èƒHë†ßé9¡M–´\îåmtZeCrP“Eğç_ñÅ:Ú¨Ú'WK…ÖÙGÁˆÌ€tºñá
¬ª"SL]”Àèa‹nØ0†ÀÙWPÂvá;‚úÌ)b]gËu]ß¹Ê´nR ÏØ”¨­Ä Æ®Pöá3ÚÍ2ƒ€ÆZÀ:şÄ7¹<Ú~UXØFn•rMİ`ÇQ3-è+à%÷“H¿kZO(ú|¤câU–7º> æQ^¤W^ÙÔÑĞEW±M¹<Û=öÊˆuR¬‘ìJÄ=â; A$¥Lb“ Ö›3ºÇÈå¾ğ(á‰çkÚ\´`^L€ŒìK23zónu ã£0\ı‚Ğ„U˜Ïè¬Ø~–]o;gº@á+¬Pkq\„*á€ã¥CÁW€)¢QiPƒÄïDËãc:¦b0I„píªõ)YœiqÉ;­r Ó	(LŞdt‰øŞÑ´ÂxÄ›-¤9	„8¢‘Wš H‹±S{xBVÅÛKÚĞQ†ÅnĞÁÜÔ÷OĞBÏ£ò8¹–Á<,Ÿ!#!ëªô`ŠèœôÙ’èA™«Ù˜§jNùƒe#-¬x®‡#@ÌÄ6RÄØí\¥Kã)T½4¿ğQİT–/ØA(İ£z¹Âh%ĞñÔ.¦İ4@ÓilğXW4ˆvèñèiÀNÊMÒ¢êâwZØºØEyÕ·?Q¸qu¾*Tm¯†¤Këèmà49Ò4ïF¯'èÎ:ùIÉ¥±³åU¦Ôb²Ş/ÏU«&¾M¶Ú±¼‹¨Ê¾&)™­Î°ïQxu²]šyÕYFÆ-™êëcªVM›{éhYV¢n«„0"ôRv‘q”©lNFr"z8÷JÑ&§š5-dS=”®),°LJ(BÇ¢²1ğ-MH¤8á±.§3ÂLï5ª4S§U¬]DóuÒbNHef?LWvuDYrt&ëë”Õ^«ƒìOO¯ÜH:$ßĞh‡¤BÆ?„ƒ£á@è–¢ÔT™¶Ø8Vvh\¦·ZŠPh4b¡–†÷Mª–ĞSŒßzÆìVëCŒ U*Ã¼B¥È/* xç•âµR=cv¥ZXü©Mç¸*`·©UAÚ>Ëjßƒ*¬Uæ€¸L¥™«…ƒæş+b&Ü9¸§ˆˆùpôãÒ,è©ÙU‘+L`½€òÂ+U6x`¥m:a©;¸©TªQ1¶Œ2vgo\¾k[é"išD¥ªÆG!}ıÂ¸v—FOaÇK¿XWã{£|^ÙŞN”ù;^Øİèƒdäˆf…¦æ:ÔPG•Ğ;hiÌÆHhm-¤M]	ô”~·XdñÂ¤©KìŒ¡Ò"V_„Aóø°±”Aã‰£µïTË†Áøç‹T+åëÔ±2Î}$7F%ô4Dïô8ôø,PÒğ”BGª§Ód?¨([Šå5®¶FfÚKÜ2™ PCæ´È+ïO¯$¹¢Úx³ÕL‹€·±Âÿ6¾(pä2Øsmô×pQp¢6á]Û¤kgëÙƒùèÍ÷ÓÕ#Á:6:DÄ×S#€jb^®¬8Pâ£Ç²'4¯`éJv±U~Ä‘’'¦2è"¯ÿŒ—~É˜$‡µsZZËS^t”2uKÔç¡³¹I«‰G¯‰!L„ZH¥(62L‡Ç±§à•4MLŠ–)@#ãÇ$`¢³('ò*Ú{ª§D>®âh[.±ğL€}úbc´5Fßxû¸İ	—ıò>›Mp‰ùœƒõ³ÛH`3nŞ–Ut§z/¶0r¿ÔĞæQ¤'ÙšÌN/Âœ|0Ñ–x§Ö>¶8°v0¥.*$¾pÉşlŠ)´"Ë6€ø›ÀÖ¿“Ià©kRWt)Éšf‰¨2üFÖe¡Àr¯û ›–+f‡îa§uÍ\ öŒ@ù¡Şæ`üÛl0…w1^ñÆã ã·Ù@«l¨ }5é«x¿ÀÄ7óÒ.b²pÓ‡	\LDN&~4†"~„`#–;²eFª¯ä@ˆ×7"~Ãğ¦¼/’o“„Û‚È*±ÃIùiçòbt‰4Cm­~=D‚xVœ©‡Tú—¢­ĞÅ”4^¤Ï½ÌE¤‚âıkºsíÈP!Ã½ÿ+Ûÿ¸./ììÙı¡¡ÜÚIƒT“h£°H¥‚R¡–Ëm°÷­Oä÷wÉ1”ñ×~–xÖF‡Ç2¡Ô{”/A¡îÀéànFí'Y…fmd±‘KşYĞ!È)[fŞdÒÓ©j”ö³¸€Ò» ½0¦˜á­ÔVDf†ì9¢ØİÜÜ&4<ÿ²$ªJû{­£v«@_€~vÏó¸I¿ƒ%ÊsÿóËó_Oõd»¹Ì·Éç¿²ú{gçÙòü×S<	¦…Ô1¥ÿw+;ÏÄù¿Êîöö3<ÿ·»¼ÿıiqÿûÕ¼¯_Øğ¿Ñ+àÇ^/îğşm^¯;É‹à¥ÿ-×Èğ8nàiTÜŸæºøyßM“u!|ú²÷ô…ğóE!º+wN·ïâĞ¹uCóï·Óú[k<wÄeÜ¡v¥¾öaô·½Ú‡›{Ÿˆó‘­Éœ«§_!{¹¨+®ƒqr_‹Ô4 ç"3~—’¡“Ìi®äíeæU2ôÇC[oœÓ»Ğo€ÀŒ®†l’ÉP’å¢~/ES+Ìj^¤8k{9¡_ÏÖ"eS¦¹š¾VXŞ$¤"§) Zÿ“lUc ˆı€qá5®`‡ö¯¸§XÇx~]ö9P\´)&e.sÂú7‡;³Ô1Ç%é§Û_ëkô³HD¾»¶ 	&¯ÎKÜĞ¸Å›{‹KÉ Ç¼øª3“¿+ÃË5(ª//†cr­£\¶Ll³}íÓ×¼:œóÊWôHç@nÖrá`Iç‚T-t.H…\Q6'Â7Åì1,§?6S4"”ÜÉ¹ùp‹óƒLĞHFì©€»È§eRèIˆ€ûÁH€ƒƒÆY«¾ÇúÀç0‘}¡˜Q&£¾†,fl kv¼¾ç×ÍQèE²Á\Dß} úQRÀ“² }‘ÆèêÙîĞè²j9Êw_4h£F…¦Y_“¶C(¶SÜ;%nO‹Û÷+N–S¥¸oï@±eÆP‚ûÁˆM­ÄµãÕ×®Ì{~eQ}L–JµWõ5Í6Z,JÃ(#Ÿ|ƒD’ ê>B±ú s}@¹ƒÒj±|Ç­Çş	‡ÖÏ‹ïrtÌhBÅ$¾.2ğp˜ş­DË
`4E{+_‰6¸AƒXdlÅ‹´ƒ÷f¿)¶òD‚Pòn6ÚpT³º.&7gí¾ÆÉå³ğ'>¿¶¸:¦Ùÿ¶ª»Éø»;KûÏ“<<ş“rÌ@\•WX"
/Ú.ğCU|ˆn[ÁÄ-%±¥n‹ÔøLİ©ÉËRr+÷RTËñ]äŞ‚SÃ+njx_N/±Y
šY<´ºè:²ÿƒößåşÏâ<¯¼è:´ÿ·»ìÿ§xâ»‹«cÖş¯Vw€¶)şcy9şŸäsb{®uLÑÿ*åJ´ÿ·µı¿³½µ»ÔÿâYaz\
ĞĞ^‹‹¢3}®ÅäµpqÔùs†ñ;QĞ÷ÿaÄ‰â$ü›€ÛT;dSUwg(Š&F1hÏ¥o‚\ß¥€k«äãlğ¸t)% 9Z½y!·Œ'ğ4ñ¾6£.Ÿ…<©p,¨ãşúßve©ÿ=Í£‡ëYL³÷ÿNuw‹âÿïì,õ¿'yQ¢RÇıÇÿÖn¥ºìÿ§x²ã‡Í·û÷ÿNµòlÙÿOñŒ7Ç:¦¬ÿ ãSı¿[­,×Oñ,>ŸÚéó7ëìy Ä¸hFÇ‰x‡	ßMáùÔ˜£R~RÌÌ0¦(^Õ¦¼urFØtzFï3~&Ã^%âÃØ —Cá½+zãXß¡—Àù~–ËW¹»åòşúL‰;—:¦Îÿ[[‰ù·¼S]ÎÿOñ,çë$ÚÉùZšü[¼›"DdìDÖÖnSÂ@Œƒax«9}üQgğœ$´:u _x‰|¸	/™³:5%æ¼‹_€–>¼ §ø—¦+"Më_BoÈ!vÜúkßÃP¬Y°;ƒNOÔÔéïÉoäÛöí±ùç{AşÚ¢iù<Á36
üë˜2ÿ£¹7²ÿVËeZÿo-Ïÿ>Éó¾uôzÿ¨õ1wJÑŞaÊ%§_© ^1Êü¹÷¯[G­Óı½¹vkïÍéşÙÏçoNš³Vûüí~ãüğg~æ ıæ}ë]³Ì×‹`ù,â{×Ãë˜6ş!5ÿ[äÿñlwyÿë“<{š8hZçĞçÉËk8?ˆ9œÎ/QC©{b¢øÚØ/ŸÇ>Óoty|SÆÿÖÎôÿßÙŞ¡øxôrü?Å3·¥ºök+ş}·køh‘ÉÏ,Y¬Í¹
OöÅÕ>ÖŠNQYí‹å~êF#Èª¬ù¬•ÿ¦¾èÇ°M‰u¿º®— Ê»c2¼ó({™0ü¢¬åå—7°VlïÍö!ã!b1?İ¹ª×ÜƒNØ—7¨ÒİLêÕLPNYîËrZŒ†øv)8bLQ…Å@õ¦j€XƒÖTâmË({~mŞÔ±Éh¶ÙŒà‘Oš!v:Ä°şv¯}Ñ}~NhäV´ÜâÚ7%¶xMûŒ,u†™lÀcãq	ÑJño)QG‹—ªà%3êHõE6ã%ˆğ»b\‹Y6^väŸµ"KŸ¡&~[£XÜ<5~À¯xœº7¼?p/»Wöe‚¬ÇíOÀÿÄp0TË? jW˜ àq„Ê·)|š*•J"[Ã"WO¼-Ç»Áğ(táx8G¼sïQ|Ì)1Eëšïé†AİµC¼ĞÉ€º´Ã\oK&²Ü{! ?æÎn‡v_M“CGŞº¸Ñğµ¦æ”¿úñIë¨Ù>ˆ×óÙÂKù\ë“İ!F«ë÷–äu¤2úD‰8«háqÕ@’õ†3”ô†É‚§6úÜŞ£¨osÖ–@ i×2}ëxGa˜wŞrB¼|$z£E·>õC§ˆ²LøkO÷©gÊu}s©cªş/Rÿ«ìVQÿ#ÿÏ¥ş·øg©ÿ©ú_úºÊ¥ò·xå¯MÑ(dT¶2¸}XÈRIùy0Å‹Õş2Ønªß´j¡÷Mı@¥/ğ¥ÀïFã{wĞæ‚àiÔ¾wPY4ŠS¶C¶x¬÷y{I	1<¢JSïW–+…ïì‹ïÒéàU¹ªRxOXRßSÁeky¿Q%oÂ“uó¼ë˜¦ÿm§ü·Ÿ=[êOò,ı—ş¿³{ñ‹wÁ7ˆ—ş¾

ó†wcÛWı[Öª*.óºt°?rI³UâãÎ·rÄ?°ø_È'îÂÌv?ÆYSqhz¬²WoX‘nØùä¶.L£Óc/^°R8ªÙ12oõÅ_*¹Ï2ñ¢Çíøti…ùõˆXŞ¬nnmnoîl>{9÷öN[‡­£³Æ·BUqôşé(Y­%7f¥Ÿp›Gúİ‡`_{^>Ëgù,Ÿ§~ş?ä´1Z h 