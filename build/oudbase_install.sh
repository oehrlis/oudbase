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
‹ t‡*Z í}]w9²˜óq“sù”ä!9çœKkV¢Vü”dÍpLÏÒ"íÑ®¾®(Û;×öj[dKìÙÍínJÖØÚ“‡œ“Çä5¯ùMù÷7ä¤ª tıAR){f3¶Ùİ@¡P(
…BáÔ²Ëœ*•ÊÖæ&£Ÿğ+µş¯H¬º^«Tk[•j•ÁŸÍ'Øæ¢Ã4ö|ÃT<Çœ˜²Mø.Úüû3I§ĞÿÎ¸wÍóÇ^Éë/ Éı_ÛØ|RÃş‡î_¯®on@ÿÃ­G¬² \béWŞÿSF85¼~î1+Î/´¥^-Íì±k]=ËcÍ—kìùØ³lÓóXË¼4ÎhhÚ>û-ëŒG#ÇõÙÊóV§ e:†ynº¦åù®áy&«}³Æ¾®nÖØËáû§îøü|u®,ÿ'ÓvoîHïC³ÄSi>6Ç~ßqÅÇo6;0ûîÀb+é˜GïJ½û½/Pê:C(İîY~Pzi×ğüí¾aŸ›½ç×œü-ÃëV3àåÈ¼´<Ë±cYäípìÏäÏ°N×µF>óvnÂ?}“Y64ÍîšŒ·sMl³®Ó3‘oz›ã>ô£ÇaÀ¯¡aÙƒk6öÌ;s\fÚ—–ëØÔ©Ğ9}gì³ã×­"TŸï3èV¨õ}äÕËåsÈ9>Eê”9Å<qÀâæÜ»ÈÃ¾®rÜë:<Vª¥Ê7%˜É0Æ@¢0¶c[¾eØ¥é"!OµVªV1Ï–ÌÓìıRiÌhÂ/ÌìØÌ9CN†–08‹l*u†ÖO†ˆİzÎü@ƒíàUëäèààø¤µßXú¨<Õ‹y`ÿ‡^ÉqÏó7„@ÛîaïGÀµ`ŒŒ>{mÆ¦wå^·:;ûèÍ\ë yxØŞo5òÇG¯Úy6cz¼kœL6pÎÙ™?ŒÑÈÁ°ŸtÚü‹ænçğ€7Na²!¦ÎöÑÎáñÉ~s¯İXZA·AÎ°¥J!w¼wxÒÚ9joıĞÈ—ıá(O/_ììBíKµ7e½xii)Ÿë7O¾o7[í£FP<ĞÕĞmK•ÚoØÊkÎáğ^ï¦@c–-­æs{Íİf«uÔîtÀÓ¿w\d©ÛÏµ•œÊ÷ïIîÅØî"Sİ‡8¸ù¾3{åçæJ}ŒÊÖ–åÆ5Ï0çÚ‘.$¦¦W-gÏ;gùı¬Î+^‹vòÛbÿÒeE‹=ÅÑ½³<±¿İ~ÆŠ-öÔˆ^k~ÿÈÂh¿rÜŞ`şgì}R%ŒûIÌN•³'‡!Lîğ”Rü2©xÂHI)î&ïöÍîM?®9X]’K) ”v‡I²ï%²ouíFËrÍ.NlÏ°¡5n
¸DÒ=‡7l$^‘,I)ëLğ&!>%'•ÛuÎI<Áÿq÷à%J‡Ï:coáeõ†Ï}Vaï¿ÅùİÎÉfnLÃnÚ½[>Ï·ô±vCŸÍÌµ2_Dâ%—¯0zfånrsŸë‡Ög,.£|kH
Ëp´¨¡NT_)ä>R;wö_Ã$Yıª¾z“Ä„”@×5.Lš­{ƒÁ>g§&üÓã´í‚¼’¨P»’! 3‚‚Ìf[ “…í$á»Æ`rú$,_`ìxg¯}|´wKÔ–ÿİW?¿¿ê|õ}ı«½úW|áÛo•¢GGéEí)…ivÒw¨÷àX«Vo>¯fXåßµ¥„$™ÑG@&4äà›<k0¡DƒÌ*Õ…Iy©nßÁü!NÀ8ˆòì“oš¬h(ã1(©«É`‚l0¤äO¯oùÁÓUÇ=aÕşğ%\{VÅm[¢y9µu‰-œNËª´4ŞÚc›qÙ4Çn{ö,©M_õ“‘œx‹ÏˆT'TŠXTtS6é‚ñƒå/@9š6ñ%(O‚zB$WQÙ+…`ÎEé
3mL{VÅUUÉ²·¡™l´]bo`I|ÎŒ¡3¶I7Üó1.‘½ëÀàÓ´†â½ë¸¨w0è½’ZEmÖ*$`¶‚S{aVø›Sá«Z	©Àb éÛOêátFKÈãæóUÁÃQs{·h7'Ï›á€ĞSk¥bTgúX{i\Ö µG­=Õê4ÈÛÎxĞ#¾3îöùŠÛ¥‘ı`Ñcï–>~ ìQ.I$UpëSÛÛq`¶oóÅù4Ìì©å7¦–o».PÑé‘¡ŸÚ^œz×Û6ê/Â&Ôu†CÃÖÁÕî ®ç)*z"ÔõiP÷,Ï#Í*®e«=oE8é&Õ@ÍÀ¶mr‘ø=´g`ŠV[b€ĞòÊbˆCBc¶Íé	íH¡!ëHS´* ;Z©tGGÊø,GŠ—á©ù=ªhˆBÜ²áç/²ü¿ù¦Y©üdW†mÌı½o6L¿›*v^Ù¶seó¦§è{EÌ,%71á¯ãtdKP«MT¨ù˜Š†Ê‰;Ô@Ö•{æeÙêä‚ğÌ	óØÁ‹ùX0¸1DX"ïoïhœÉ	LÊ8VîuNª.2W]tµ…Sü³E%]Œò¥¤\q•N[VÖªÁºòÌb,àèÓŒ“.ûô	¾ü†{‘Ï*‚Z­Õ
Ô†uí"Qp8)†ì\‰-­œ¡´	§"Ùİco!:êXgÿAŠõœX¶ç„.‡=ø)bËÓ8¼ã/ŸãóT¨j\É5 ï`,üõöÛßb7]±¼b#Ğš±’æ‚ÑéRU+TÖ¦]RìHã„ãÜ?–åàöë^6n…û}×±¼Ö°J×Ò¹œ@uÅv
’€ tÊEÌn&ëA«²Éœl¦ä]¸î…ãíÜô°­^~ä:8üpB³á )<2\`íN|İ!J³ş¥UoÕ¬·ë.j{Áòƒ+²ğFUd/¹e®¢İËBDV¾Y¶w­22²éÁ!æ¥6Wµ0·£¥äøQæPMc)yİ;jîîl7ÑˆÃª]Ğ¹2Êw²±5¶´ªN´
¤…Ş>”1!Adh‹EmTws%MØÀœÙ5e±[Ï¥D-é …”`ÏX0’aTÿ¶šÃLÜÎ¾ôÔÕ'¥‚™8	ÂDì:C!z›~ò'­€4Úm²	05JJ˜ä‰o‚ˆ	gĞ	#å˜ §L¼ÄOˆÍ$ùLW&ëóD¹/°,’€ÿ¬ó‰ÖŞ›\÷ÊbêK °ôñğMK4ä†“é7bŠŒçŸ4m¬Ç;GÌ‚%flKÅ¤lDû‹2xNä,ù¶mñÌµLà§kxc;E@Ã‘O¿]gdº¾ezˆ)¼â4
ÒÚôùkµM,±¡ÑwAlS?Ó™j&ÇfqÔoÏåU-»àClÛ,ˆï@2=øSÁ÷ÃqÓ÷³‹[öÊ^*ËË*B©˜œİÈËvZÜ$=|k„;ˆèà€(¸°+¬|óƒjôRùãş·^ù]fåooR`ƒ8ÒOüg‘«® LL±Z"ütÈ'!m°ñm‹Çbs¥cº—°ªAÆë¨}²rë
À¦Ë–cYÄÖ£ÙÓê.H¢ô,K´ºãF/]†U¢ê–èà®İpAÖ2ÍO|!–Ã¥Œ…©İVóşê©N.VÀ-}´Äz¡ùæ'¸7°b\]°åçí—;û:ü;»øVH/ègşÛ—ûGím˜Õoù‚¦±‰{0Uö7Vşs³×s¡Ê(W—jøêİÓe¬eùİ³2ûZYZç¯Û¼ğ¾ àT¾e7¸-ğ‘–$ôNïqV \µQ¨óúÈ‚ŞÙ¬Ætùé]ï¦*QIªóú4¬LøiR«‘?š¼Ÿ—õÎÜz‡” üKEP8\.ÃˆQÌ^Bàè×m<³ÏS-±ìÔyŠìeK‡ À7[{;ûêÔ“:‹½¡eÏ0Åç®Ä¾JÃ´&¥uk¢Ùú½ºQÓ'>Ñ»\†6ÅPˆ ş¤õü·‚qoXYóº‘¼¾Å~ó7àõ}4pH^ß¬%2ûí¼6yëz³¦±.¶OßšÖ£óX??·Ç§¤ÿ/wáú,ş¿ëòÿ…_[›µJ…ü+ÕÌÿ÷!Ræÿû™üƒ÷KñÿN L’r{F¢½_ºëï×%øA®¿ÕõhAËö]§7ÕÖnyy#³k]‡~Ø@„yï’Ï×}ø—í<WOà[»?¨ï¯È…÷ıu¼…‘îáÂsí<cÅ!{ªô0¼šİe÷>şº³;ëÆqŞÉ†Ì¦î”x)¥cÍJïÖ€‰yrñÌGöA}dYæ#›ùÈ²ÌG6ó‘Í|d…ˆ|xGØ	^¹ÍS'¾ÌCv
üÌWõ–¾ªsòãü^…™_ß/Ì¯²¶÷_7¦zñ¥; òú Ô–¹öİƒkçìÜ oïÁÇW¿U¶0½aİª·ÉMï!|ô:)nuCÈ¨X€–V¤'ó~BÓ­W~·V~ÇÊç……ù÷ÍÅïïâ%Ä^¤oDµRÅ–Øìç@ß8M´‹D
FŒ0Ê,Ğ>ŞŒCp`A=f]×ÄÕ¬¡ïí£Æd(öèÌƒ‚Ÿ]eì‰ãæóF¼¢„ŒD“İn^s£K¶üçÇËá‘£Oİ±˜War¨âs‘ Ã›æÑ>úèš"OD!â½Kh{
œ {œÀ”¾ƒÅÓVó¸yS^Åca©±-¼EÃ†„k)é‹”v ƒ`Å–P3Ò^û†;1´y!!–,èûVZ}W~·Ş!¥Õ¥ò»jy¹6M]D»Hk{œÎŠ,Í¾{æ$¶%È.Ç?p‘1Dt—-¯-3ø¯ Ä¾ËO‚Øæ‰sËtP"ğĞïŒ^ßÜw¶ ¬·›Ï˜¾)YÔ	Æ\ZApFÌAW:}7‹ã>$NÛ)…S<ØŞ.ÉBïC	ºò‚#OÊ2qez®yÆ>1S·<õ‰ Œ~8îyÉÁÍ¯ä‘ÿ_	Pf)¶Ü)*v•zú2”EGXöºÿP i<Zc3v»¦ª³•BUäU¢v'?ëZ^XÔ÷bC¯Ì)áœ{/Yq$ZşDNI­#İ.¡¡•ŞbŒĞtÊ½Lùù«à[>å±–[/âå‰ç»¨Ä ï¬à0+ÊÜ¢,€î‘ãø\šöê(Q×jÈä s/¿}[?öEııûåBL"	`áHÑ«½Qatsİ€şÜ…í7Ğ7K{Ãf€XãºÌrù]~í]¾Q^>s”á© [Ùø0¥+ğ|gŠæ~²ôQvÆÍI€ÚWèUĞéİëÑ®"BàvZa«#vAÁZÛ{{MÔõÅ‚hgÿ¦Ì!=ÌÅbßñ|jHÀ§™<æfrğNB}³TÚc>DE Šl
5OZÆµ°˜/ÿî«ñ2¬— Ò¬ô…‰\#R„‚±Ïèê§1÷÷‹4L1O¶pJ7@Ş­Ü0nı\
 Ğ%¾iĞ8Ôæµgeaá›B¦8”úÜåcurÿ@Ÿ† ä+zdU98ª·õ,õìi'\‚Äe  ’ äÊ
ıø]µ Ë‡Dóyz·ÏNoÜÅ•İ,³¯A±-¯oö¢æ÷°ã5kû=f¬se¯ú)›eÁ¨;…¥éâÉZ³WÊÆÅkz)]tñğL‚Y¤MÒŞØ$OêsŞ0ß7*uùë\B]¸
Eìº‘>%äBŠD<1UÂ|ü_˜?æC'éÿ‰L<}ÿÏÍõÍõÀÿ³º¾…şŸµÍÌÿó!Ræÿù™ü?ƒ÷Kñÿäúõú>)ÁÿSü?¿)U¶´<{Æ¸KH´öŠB×•»]Ç>#[2<—‘ıè}æPšíçáPZ)U¶ÑeÔ­ôø‡ClÑ«İİ™Ä%ûì9MÇ×#3÷Çvû°±q8Øşxx
š÷Æ4/h°^˜æ(²f„®ƒ|±(Ï€'?òa/ÆyæAûsö õÙSdÕ_¾/mĞĞ )#Œá@Eo•ıí£ö^{ÿ¸¹›ùäŞk¿(ŸÜ,nmæ“Kud>¹™Onæ“[ü’|rgrÉÍœr3§Ü»9å
İ.î”›9ÓN —9ÓfÎ´?+gÚyÇÉüiıºUÖÛ‹p£õa	@fªDgÔ‡p²gXËÌk41óÍ¼FÆ^£b{nF¯Qï_òÑp.§~s|ÚW|ºÂb_àìlĞ*®<*3–IÆ7ÖëE†5<´cÛÄ¹2Íf“)>·ß~sò¦İşãşbsy•/äv[áX„oŠKqà¦P âÏ›Û|uxÒiçñJO R(Ä´Rì+\JPAt'ÖÃ*&QH(¬wQ+Öfì$j¨„á‰aÅ7ÓáÖ,ÌŠc÷\ì¬
È*†YoRæ=ÌîëÇ©;o~±È	àbÉØßŒÎ>
ù+T]t_eÁIä”ãÚˆÂ½Y©âOobÃ#¤‹¨(É—UÀ#;Üy.¦Rİàf†6ÌÒ³Ku\”B±O3º‹ª®¢,©ïÄrCo;ö™uvãu#%C¼¡[Xñğ§îÙ,4*«~¸fÉ?ÿ‰/ó¶ö_°gi­Ò4$_n€{·h[´è<‡wšPÓŞiÊ5šV6º<$rğŒáB•ÇqíòQıL¥Æ4^
‰‡n2Ñw#«—Fç$*cA­ˆÇñìŞÆéÆÏõ-œŠgr(µÜÙ¡xº3qÌæŸÎz‰MÁ_8¢n7Ç¾ƒWåt(ASºè¦e9ƒúë@ï1Ô5hšOğOn‘ÉšÿxBÅU8€†ª}ÌR—Të4$îFîYÑM™ˆÓwfÒ›±ï¨M8sÆ ë¯˜ç¥¸‚”€t!ucGŞñ3'Wo^æê}‹ô¹]m¿È„Î¿¥“ÀÌº:&ûW*•'èÿ]Å·Uø]©®?©U2ÿïI÷ÿí£ùèÑÑeö')šğİ£¿‡?5øóá<ÿ‹3ÈæññÿE%şüù‘,ÿJ¼ÿwıèá%c4˜¥áùè ŒkùÇ‡ã_ã_ıÌ74º.Î€&.ñ<Lÿ:ÏŠ¼ÇóşçH^ôa>˜;vÏüğèÑ-ş§ÂÜÿëüÏÿV„Ñ¾Ì¤İ(´ :&ÿuø¶ÿÙø˜”ÿø<ç?OüŸóÙnœ¢“¸xNÀ”…'7¢×‰f§@q
¤?ÒƒÕåHA›B˜Çø>.<»ÅçfÊÙsº¦›xB›ş	Bõa&äûSĞW¾{=oÏùdB{râŠ];cà¶kâZİ\.×BÇWş«kù%è<h±mºĞäİÕ!h^?ØÇ;5CÇ(ëÃ¢Ü5q¿ÖUÀÏÊ‘uI_1bÜù?×œ–ÍJ(šOF®ƒ}Tâu÷ÅfÖ` n¶áH0ù‰øÆ—‡t™ôJRk ¢äçdînîîl¿êìíüİ§T‚,”ëĞñH‹R(EŞT*M(£ØB$7Ä¶ÖÃ¯/£ÍÁĞ¼¸†9ğ´qy\©”A#,;”—Ã”~!AR`B»'T
€ÑpˆC@ºÑTQc-Ø-[†Ñ±+®,’Ğ´íRµ`Ï1?‰LÙRd¤l0D»¨bù?&Ï¨ö
úÅ)8 NÄòĞêõæ•áš*è{o$ø;Æ²ïÍ×MQŞÀÌ¬#–²Jg°+oº6ôÏ%?•V§`(q³&ääÖ±ëÏô»å¨i|"X( dXË!Á…<HÏÀ1G!·h«²Åãk›ÒÜ'¬§‰ƒüÙBÎÌµ•Ùûu 4î†w‘uL_’DŠŠª¡dB'; ÷µÜ]ÏeçüRNˆ¿? y¥ ß+ã¥¸Uà€=änrŠ	ÚFèÄYAVõ<»ÛÍİ†
ƒ3›æ9ı&µ+Ë„‰;qa	ÄTä&Z7îBzæh(r©¡™c@ğá¯”ÇzH|Âr+ P 3ÆúÿH—@•v7¬ˆÎì,ô,Â¤:­¤¿È;Ôõè/şe©\^şÔ¸P„U1L¤Ô
±‘oî‡Ñí
Ä ü®£8\õ­nŸÄ`áÃ:ò óâ"_ÕëùBè;—8oÏXß¿fÏ"7ÀØ7‚|gºAç² ö.¹ŒÛÁLóƒÙe±C<xu´İná~øI;6_¸7.wöóˆ_XJù…ûêj8%ù½¿Kq|çø¹Àé.°·¼ŞÚG5÷°yü=:„Y®ç+½èàÕW(®‰Ğ-_ŞÑ+:ÙÀŒx‹†ò¨Ó|İn pàüçFñ2
®sÅw·,BÏ’[ŞÓ³5ê	ÛGmœó¥
JRXÙm—;ˆ"«•$¾oH3Pà¡¦‚<	¯#ªÌ_èÓ‚Ê÷¥#Áö®"Š¨ƒá›O"˜Ô˜ttPÿQ2I5(s@Ùdp\èO†Æó 0¦Ü‹)haÀggŠ£$enÑ—¤8zFÛ£åÄº‚œÙİ^…shÄwõö~«÷tEµ’O] GiÀp°ˆµ<¬uÍáÈ¿ÇP>æ'¼xãOtÕ\.5Ğ”•QD(ÆœeiõY‡!]ĞˆĞÉ æê'›OĞ$¤û¸ÉNót»¯»¬ÂBeê21Šd“€Î@;.¼9ó+¼ã”VûEóÕî±êm‘È0ªö)8¼jU)¬M¯¢%Á@¦p_‚«v„ïnÍsiüv{^»+ŸÍ›Çˆ¿æß¬Nš†çë=	t.•J¹¨ÄJã¿Ç&ÊåIÒ–(¿ÛD$“¹[ã¿>j2 ‚·½‚ÑYö)V#—{ìÔ„I…Gé± ƒàMp& D5©ù	ÈLh^×ÑïPˆ]á—@“feb•è³€ãO_j°”àä/º‰{Ì?F7e(òSO„‰P$‘s`Ìø CzsFûºåøhZIuØ^V¶—á‹îÚÈnåÀXºõ!¤ºuG‹FÂfy<Zş–ûeñgô±‚7gVA=Ô‹@§µy|!ÑÚ9:‘äp.–zj†ï¾çdùN­¸$ïatuª÷_òEÏ@çæ¥ìG#ãß‚Ëâ…­’N@†“Óıº\æBy„û›“zÌË2±À÷¸ç²²Ò£+)h¬•ÛTš)†v¤”ú:|Ğˆü¼J=ën«yÈQÚ04†ôeëèùD¶“NgWËÚ$'ßÄ¬&YË|¤xõŠ"2óQû0?Çş›{$U:GqÁ¤Ê$!¼@K>¦í{Ì«`xd‰I®
CÚvÂÎFæ‰’YAˆiÿDŞNJy]K=*£ŠûˆRî#P(V­I’”§[ÈSLå:ÓéÛÊíêÈ<á0I_äÊ@óK­&lªU%ûFAww@5ô»[\ËöÏXÇûªX­xğ÷ü«º{ïì|ô€}!¥Yä=^3¸¢´Ä9øMt½‰‚N^i,YŠZ?øğX¤Áioş OÄ%Ê¹XP(oäpû˜ºÅÌrX€táª£·ØÂ«²Ø‰/¿_úÒ”­"ıtVPi6d¹`5l±–‡5 ÎA)SŠZL$§L\Kwˆw–P@iªI|gÁÂuYƒËú‡`Š©e%~¶9í¼l¤w+WÑÄ?Ê}’·–8„;[Tá‹*{1!Š«÷¢Í–Ë¤érBq<¤cÛ4)”×Ê^*–eÍ8ëyÅîÙy-¦MW>™†ó˜ˆŒÕ'*Àº¾§FóªIc­¶Î«m,Ö8Uy›%o1¼î¹ïğ¾vÆ.-Úè~,Ç7-úîµã¾…ßœ§£\´a$MªœP9S™“êÅü¤üM4¯Èß«ë_ÿÎ¹ ˜é0ß“õ'	ù¨û>ÊŸïëoxš“d4v$Û-ç¶–Rz&ºJYL)%¢«mÉÉ§.[bk%otİ’°hQrG.±UË|©µˆPnÁ¼âšœ_ÓgÈÀ](†éİ9ªò1¿j˜OĞÕ5PØå´rl¸€‘òºÆ/”Úv†CÇ>4\˜€´‚0€qb;W”ïÈô`¤6€­Ã÷ôA„÷ã‘ôJ/…ĞÅ¨ˆåÁ]®÷£´í°¡áwûklh¶‡G}Ö¡aQÌ†.E“%y ““Ğ¦À8w0²<èçÍV\“b•+…C)­R=Ëå‡õÃ×ÚJ¥ºiº=Ù•	ÿÛüèùb2`\™ŸE_MY…ÌÓ?±%NRj~ìä¤$wI•ÅÑs‰a¦² †ÉÏô…õ*m¢ş(çãõ?æò×ğHGØÛ®D^~	Èç÷CòI<å`ØÉD	˜†ßœiõ€`ÜøÌ5¯ SÖä^§3}îÀg;vQÉB9^8î•áöDŸMæ<‰v¢àùV÷‚î@pè…eû¦«Ğ	&ê°(J§T'\„jf©‡Ğ'BÂÉô,æĞmöDŒA¼
º*µkUFòÅB‚ßÍ/ö—¬Mª¥3n¯H.oÿ
º†œĞ¶?Ì ;yhNQ6È…É$eU.ìÖUÌP\ ømÕ¤ØR¨ÖØæ•æd˜Sê@Ä48éÍbĞpf‚pî¼è4êb‰¨ä$%&Ğx5*ĞnØÓ§OÃˆMÒ^«¶Ir¤sÕÚ–”„¢ÊåÈB=ZS Q\" ç×|Äd›¼îÍ¢ğ°Iï‰ï‰4‰_€RÊ(Vœ¡&S¶]Vcª›JJÈ¸	~sém}€²A»&R8 ®¨ù¾BĞ¿É{
‘Š#hÕ…é©®˜êšé©ªà7õ<F§$¹Exö$º½ã;á°b#¾˜qÍK†+¡I !dhÇÙqâÀ«‚ı1±7©Z9Ï@&d“«,är§¹¡° „…Ş…ùI=ítÜI8Õáƒpy¸‹ÀvÿçÀùóaß¨	¹¿%ÓpÈƒÚ–ú½¸wbê³pÚâ˜K÷ÍÃIİ!¥Scè*)O-»jåZÖgY˜û[b­üd¡zü";—K'1IàcËWİ^C×ÀÀ…OBÒY¸”l5\Jƒ@éØD`MC*š=p«E}–q$=|&ğ’¨)¤% @Ö5HŠX#ÿÉ)$çSü:’ı«ª©å¥Ïsz§XgBÖ¥b=éS³KÒ‡hW©<›ÈŸ™ÄB‘±:×êò^OüIE `‰šZI¤‚“ÑU¯äğ“Ü|ß´x`¼ÊÇ<zËÌØá¹'nô Ëh›#?¡DŸ&b¬N,n^ì(r²e-ô¯Q=Œæ±(ú2ãÏˆí‡…Ö1-şÆKÀû?«µ­JµÊàGmcıÛ\(V"ıÊã?tM-7ÕÑ[Ü¾ÿ×7²ş˜Ôsº‹üfîÿjm³²¾ùdú¿º¹¹™õÿC$ìÿ£6¬ÉÛ¥aoAu =ll¤Æÿ©lÕª‘ş_¯¬oeñ"=&ˆ‚²quh©I†}Ô&E¸•¶}ùÏÿıÿĞšÔ§áö¬ŸäŞ¯5ĞüïQ¹GB'5CŒŸÖş›VN]Ğ2cn r75†1x¼®12½k0îËy_siáT°Ac€&Óë ü	6+9ØÑ‚#{k–nüÁøxÃZü1í°Æ®è;Æ	±Mt«gŞ7¨ÅÈİ£pŒšÉãpˆH*A°dî~í‚ÖèØbÄk¡’ùÀŸºè©5:iCWà™ •º¦FÆ–$£FgÚ³jvöÖ¬·×(ÓË1tÁâz•¯ùAb‹Œ	2Ì	.ÂĞ„‹YZ+¼wM¥¥\nU2Í*0"éàš{ c7­®LVWYÖxœ-‚†ˆ<C\ÀNÇv—öTÅº³DNÂuµç»ã.Ò€H İGO-V8&t˜¤>…¦I¨#YCk`ĞµÆW¸Ù¯Æt3@”‹ìr`æEÃ¹`æ+×ò}ÓÆ—…òùÜÜ†y¯ìZöø{½÷ÏÿíVˆc‹¢ê R¾a¡©Ü‘áNMvhaVŞoôÖ2löÓó®Ëß5ınŸê¡fŒç`œtêûšŸåè¨qÂaEø-ÁãQ¤»Â`0†Ç›G|™ˆÖ*ÇuÒBËĞÇÕHdìÖ{ƒ(‘ô•*
¡SÓ Œõ‹êáıˆşå/¡ dÜÖ÷{ Wÿ[™½ÅµX·ç™ï1"Lµìõa¬öÊñÊX±ŸÃ@EÅjµX]?©nÔk_×7¿&oZí^â„¢ÁİÄ•RU\JœmÆkg&7Ê& ‚·Ê¾‡¿OÙSåHï³÷l"<%¬ „f|†Ğ†Á7´³…ïŸóû_•°ÏŞO¬h
	Ù)áFÛÂ4pñ»mƒ”tSõhšªĞÔXEÁ~s‰íáGBG^&Wâ¡Ê&T5-)B.u/<XîMi‹#{.ÒÆB`JCV¤SVpZ¿PšVEW'“ª ÈIÉU„Ä,z…Æ“jü.Š{Ğ0<å–Én õœ3#É@Z†ˆmJao!ÒFã^9‘PQÚY†áõ OSÙ?iØ

¤T,gÁäŞP6M­;A4°)uSˆ—Ä&óO“ëœø1¼æ™.ßˆ
N4 ³G.·£ÎYæƒtŠ¤ÇC¡­®Êc¯ 7às”#ğ‹*XJP®xºº*F,áF,x-Ô…È-¤W¡t/¹ô*Ni«lEê)üÜ¦ÀçÒ€Ì)àÂ›h	pN¹ôîˆ Áé	ª,Iñ¢Äæ0Í^¢(DgCqå¢½øM½¶~çøöİqræ…_QìP îÀ¹Â§ÀlNwîJy©e—\6ÛîveõPv²l
¡’š( D ›T4IÉxªÁá&4Wl ,ãÕ%ó%ÿâ÷cMMgÚnáßéÌˆ%LRrşm~®>XÉq7<]A!Nfê5/ôÎ¤F`D”[dGÙ7sv­‡(PÍmªšÔ-É%¦°Rıáº¸Î×–û(ĞÄÈV9¦ú„#‚ı*ßğí$õß¾QŞˆX»b«#§™¼sh ËiV°Fù£¿â»òµÜ‘”Ïè6°NË9è”rÎ7aúáàÃŸZ Oå}8¯ÔSsRıá#zõkÏÎ¹ëø×·—ö0Š@ÊŒ,–Oç"õÉãz£Èè.0Õv£_ÄµtÈ mV×Œd¹xx¹€7Lø.¸&wšŞô°ˆZ0Ûä´˜n1¥°"§W"—Jœ“€Édl`8U2rĞ1‰’èÍ ØˆGÆ?Ï$ZÂ»µ„©6hq0*²ÀÀóÍ3Î|3˜—pék|@H JjŠÆ{€e€8_‚ÃZnnÈÇOO‰ø²¨¡˜øûÔÄÀ*l5XTˆp—)Ü¾ªj÷Å–c3Æb-3d›SH6åCÃ.Ü•£¿ñU#_bSï;ÎëN‘;§_—L¬óø±¸LêƒHë¦Ûí[¾I–´\îùupngUrP“Eğ•ã^ğÅº©Ú'WK…ÖØÇŞ˜Ì€tÎñá
¬ª"SLe”ÀèkŒéúÊ¯Ÿñ„S
êk¾)×u¦\×¬‹DûáZx—·õª+1¨ñL(û&İ/˜¼4–=ÖuÇè*¿Æ íW……mä6Q‰!×ÔKì ˆ`§ı¥ Ìä×2éwIë	EŸtL¼'ıÊS×À<jàÙÓøÊ+™:ºè4·&—gkÂóÂÃ^¹2±nŒ52â€}p…x÷HI)Ù$õæ„î)årŸx”øHúÄZ&-˜_@ÆÏ	ö)ú3–ôæOÜê@ÆGa¸ú¡	«0—»öBûZvy¼uOœnm„¯°|­Åaª„—v–¼j5•%j8êiyhMÇT&‰®]µ>%‹3-.yg¢uC`:†¯×¿_ÿF?qÚáG]ÂÍÒœBÑÀA,NP¤ÅĞª=<!¯âF&mè(Cñ¦7tµ7ôı´Ğóè’<Nr¯Äv,Ÿ!!ë’t
èu“è§ ÌÕƒdÌc5ÇÍ’V<×İˆİ¹©±v;Wéâx
U/ÍO|T·”åvJ÷ ^®p„Z	t=µ‹i7MÃ÷46xÔ/D%¶çğèqÀNCÊMÑ¢êôwZØŠØEy10?P¸yu¾*Tm¯†¤K{ÿuà6:Òš4ï‡èØ;9ÅäRjÆdy•(µØ„¬·ËÄ3BÕª‰o-u{ÎiĞå£Æ”ÄV'Ø÷(¶©Ù/MŒ¼ê$£c—õñ>U«¦Í{èhYV¢®«„(èÅì"i”©®MFr"z8÷JÑ&§š5-dM=¯),è;¬+BÇ‚:†ø˜&$Rœğ€›Õã&÷Tš¨Óˆ‰*Ô.‚ù:j1'¤2³ãGˆ+»: ,¹|ÇtÊj‘ÕArÇÇ§Wn$’oè´CR!é‰p(Çh8ºåàm¬LGl+;46Ó[-E(4±PKÃóUKè)Æo=cr«õ‰!D€*•±u¡Rä <óJñƒZ©1¹RíZ„©ç°*`·©UAÚ>Kjß*¬TfW¿ÌgØ¤ÕÂnkç1îG-ÜSD½;zŠqiôÔìªHÇ&°~@yà•*<°Òî»~ùlxU­•j¥ji½TÁàâì•ÍwÍB+] ÍQ“¨V¡@­´ÎQˆ_¿‘ÖîòØs)ì|ùÇŞEµôu©rRİØˆ”ù^ØÜè„däˆf…¦æZ§ÔPK•Ğ	;hqÌR$´¶Ò¦®ˆzJ¿Š[L’xaÒÔ%vÆ(²7_}­ƒ½æÎ~'6Ô¾c-¿éé“T+åãIêX	J¢£zœ·úœú
ü(kxJ¡£ÇÔi²“„T”,Å‡®òGW	à#3E¯\ŸL ¨!qZä•¦W×‡™vÙj¦EÀëPá^
åYrìØ&úkØ(8Q›?u.MÒµ“õlÁ|ôæÛéÀêáh
¢""ª±P51¯—Öì*qŞCÙã°tåÁŸùaOHiI Ë¡v$G ÚŠN;H£õ¸<†C‡JcfDıx2<™›´šxŸ°ÂA¨€Ä¡ò‰€B#Ãtpx0}
^QÓÄt hÙ˜40~L&z1‰r"¯¢½ÇzJdáãª)ÎÌå"ÏØ‡(=/E[cô·ÛpÙ/ï3ZÓØ§‘Ï9X7¹VíRùSXJTÑë½ĞÂÈıR}“D‘dk2ºıxwòÁD[â[û˜†gÁÚQ\À»¨’øÂ&û³!n$ÑjL<,QØ â¯<SÿN&y€—R%Ö¤®èb’É7Œ$Qeø¬Ë=„Â¯f?ÃöÇäŠÑÅ-Òù9ĞÄ¸ jÎ”oa¦° ãßfƒ)¼‹ñŠÏ0FËHŒßf­²¡‚ôÅ¤/ÂıwŞŒs³ˆ¯…›n8<H¸àb"p2!ğãŠ ø1‚õD´\îÈ–³;¼Z!^ZN*Dü†^=yM ß&	+¶ãycUb‡“òÓÎåéøi†Ú"Zıúˆñ¬ˆ. oé_Š;C“Òx‘>÷2‘
fˆ·/éBÖe´#C…÷ş/L÷ıŠ¼°µoF%åÖV š”AëûE*å•õ\n•½m ¿¿sÌ¡¤_ûZæYXÜŸ-Õ…ŞŞ¢|
ˆp»Vw«ğş’UhÖæ¯zll“ôCsrÊ”™×˜ôtª•*%öƒ¸€Ô9¥½0¦˜ÑµÔVDføì)¢Ø]]]•XrÜó²¨Î+ïîl·÷;í" }úÙ-Ïà&ıB–(éöçÿª››Õìü×C¤ˆ?ËBê˜|ş«²Uİ|Bı_[¯nmlĞıïğovşë!’¸ÿıbŞ×¿/ìøŸéğ©—À‹;¼×ÀëÎ%ò"xéÿBê:Òö7–¤âö0×ÅÏû––¤áã—½Ç/„Ÿ/
Á]¹sº}‡Îµíx¼n5^c€ß¹#.ƒtªåwãß¿ë×ß]•ÙÛH˜÷lYæìöúú²7á—Ó†â:¾h1‹fd&F²R2t£¢Á½•¼ıÄ¼J†A:0´õ…9SıVá ÌèjLùJÃk¹£¤_çK1˜Sj…ÙAÍ‹!gm/'ôËÙZ¤å[;Gñk…åMÂ^,†˜ ı'²U¤ öï€ÇâÂk\ÁŒÌŸp?F±
ğüºì ¸hSHÊ\8æ„õg·G©cKÒ×?5–ég‘$,ˆ|{yL^"3¸ q#ˆ¼–zŸIÉğ¿¼ø’5“¿#Ãk&(¾-/†cr¹«\¶Ll³|Ğ×¼:œóÊWÜç@nÖrá`‰ç‚·Z.;ñ\ğrÙ¬ ß³‡°¬Aj¦`D(¹»“sóáæ™ ‘ŒØSwšNË¤Ğ# ) ÷]ŒI¶»Û<n7¶Ù ø&²Ot¦<ÈTj,ã‡+­kvã6Œ±ï’Áœß]`à»Á+¿J‚æDv£K«d»A;,²+A°û‚A4Ê7ŒÆ²´A±ÍÊäŞ)s{ZXÜ¼]q²œ)Å]st; Š-+„âİFhj“ .-§±|i%^¨+óŒËd²Rª½h,k¶±bQÆømÈø/I‚ªväbÑwAæ6€re¯µÏò]»îOïX7/¾ËÒ1´Š‰7~^dà#à04Ük‰VÏƒÑØÖ?mĞ@X$˜â‹EÚÁyµÓ[9â…Pòn6 ÚpR³´"&7gù¶Æ©,-<…ç—WÇûOe½¶ÿ¶µ™Ù$ñø?Š›?(€¸*¯²H<Z´]à‡šøÜ;‚/×•—àí†x^'‚o7ÅÛèµ!¹Ç·RTËñ]Ä:ŞSÇË^êxsL¯sÉÍ¬)ù˜ã|ë˜6şãöÿÍÍ'Ùøˆ„‡V]Ç]öĞşŸíÿ,>áyåE×q§ı¿­¬ÿ"…'vWÇ¬ı_«mğø•lü?HŠD	XH·ÿë[ÕZÖÿ‘ôp‹©cöşß¬m­SÿonfãÿAR,Çê¸ıøß¨fóÿÃ¤”ˆs­£2yıW­l¬SüçÊúÆ“'Øÿ şW³õßC¤ÇLK”{Ì^ŠkD‚3İvÉRÃëLşÆÆí·oü})|)"¡¼òøj—öTUïŠ¢ŒQáÆ#ÚvîC/—ã·
áßõ%:ãRâqeèz zÛÑêD¹{Ç“Qî™N&rïÕ¯'’ÌçfÑ,-0%Ç›o·Ÿÿ7kÕ'Ùüÿ)5~Üë˜2ÿCÇÇú«–Íÿ’2§ß‡vúıÙ:ûîJ‘Íè ï0â»+ÜcÚ·ZªVÔ71Œ)ŠW5‚)oœQ6QÄ;ÅŒI}Ä«D\ô0´(²sAO¼›ôàY?ÁÏJå"w“)y¿Ò”uŞuL™ÿ×7bóÿÆ“'ÙıO’²ù?›ÿg=ìâGç”óÉæ{…yÃ»2Í‹Á5;"€¿k€çÆéä³r>j¾•ƒ$ş†­ÂU Ÿˆ…—¬~ÄB²³¢Ï^¼ÚİÅëKàÃï!wïÔ(uûìÙ³àö™OfÕı¶š[ ùzz°ì®K‡ÖÏGÄÊZmm}mcmsíÉÈ¹³¿}ÔŞkï7¿ª
ÓëÃQ²V#J®ÎJ¿à>€ÛìsÏÃŸ+M	×?—:¦é›ğ ö7ª[5Ğÿ¶hÿ/ÓÿŸæ6`ÑµWÓĞvì3Ğ¹‚+ù™…ëpÆBQñµ3¬õ˜¢¢‚¿®ò)ÚZ)Ig[ÓÕ5ŒÙÑØTL‚¨l•€#?Àî˜GQÉdj©‚_-L~y:bxiuöˆùéÂ=½6ïpvı¼>Zi¨¢½ÉrÚí0´º”!
†¨¢Ç@õšR}Rƒgéğ;_Å©¶zeg¯PbM~ƒm_cç®38îíiPÂpw#Œë|já½cºĞÉòK¹ÇZnqï\¶®}÷Æ=‡uGq>à‘.ÑYV4Sü[TĞæÔ%ø¼dBÉ¡³]„T¿& Zß3ñŞœK$ş¬µôDñiÕğ[º¨âÆ‘‰ÀiwĞÎèö„ Às”rØ±>_C Ó‡Áø¬|ƒëˆ-±Œ€d‰•„kRÀ$:'Q)ÁŠCÏÖìÑ/Şà\a@ºbÖŸ#Ş¹·( Şç”(r7».ä‘ÜÃö½†múxG	úéÜôsM¼8&ú’åŞ
¹ü>w|=2üF‚îß7ÄEV/q 6qåLî‡AŒâèÅWe¶èVğ#|÷dôÒ2bx"DUûƒÙ%»}Ù2±İót×9·ºxUæŒî ë”à9#\G\r}0öGc¿\‰öU “!ï‰º¸ænÇß*b5‚œŸ{N¿MJ½juLÑÿĞİ/ğÿ«î„ûëÙùIoÛû/wöÛïsGtÛ*2ïˆHeĞ@ø¹·/Ûûí£í÷¹N{ûÕÑÎñ'¯[ÍãvçäõNódï~æ¼óêÏ~6ÎŒ7_/²,-"¥Şõ6Ç:¦xÿuôÿß|²µÿ‡H–}iÚ8Ÿ@ŸÇæNâ‘!‡“ÃÉ¹¦|nì³tß4ıFÇû×1Õş³¹Ø6)şßÖ“õÌÿçARfÿQí?‰7šf& Å›€Â(Ûq£ÏZ <“Àü“Ä‹µ %3Ş"Œ@3Ôt;ĞLĞïh
J…=G™ğ‹±©±;kR< ‡íıVç$¸@¨‘O¾!¨œ×?ÕÈµ.İgÊèƒÜÔSìa¸¢¿-@R5õL)éŒ¢L<yq‹¢®ÉY[I¶ı\MCSn	ŸKSı¿××#ş_[•ÍZ¦ÿ=DÊüµ¢hGıµ´ñğ³uŞj‰+‚•]·@5'åÍf 	ük-èÓ¯Õ£+×öº Ÿ|¸{ëuë,x™sNqO¡;€à÷Ü°­ŸÈ%^ÿ3	‡Øµ4wzkI°»ƒÔÔlË+>È‡¦u*dşùV?·hÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)K)éÿ%qf  