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
‹ Ú[,Z í}ÛvI’˜|Yû,l?Øçìñ±s öàW’b7ZĞD@jÎğ¶%m¯¤á"QM 
SU Å–8Ç>Çö«_ıMş‚ı€#"/•YU¸P©¾TvKBUeFFFFFFFFF:nùÑ=§J¥²µ¹Éèß'üßJmƒÿ+«®×*ÕÚÆV¥ZeğgsãÉ#¶yßˆa¡å*gOÍÙÎÎ¦|íPÿşLÒ)ô¿7î@óÂqP
ú÷PÇôş¯ml>©aÿWk›ëë•MèÿõêÖ#V¹\éWŞÿSF8µ‚~î1+..´¥^--ì±ï\Z='`Í—kìù8p\;XË¾´Şhh»!û-ëŒG#ÏÙÊóV§ e:–}nû¶„¾6«}³Æ¾®nÖØË†§şøü|u®œğGÛXnoáHï[C»ÄS>6ÇaßóÅÇNhŸY.;°ûşÀa+X@ïJ½ûC(PêzC(İî9¡*½´kávßrÏíŞókNş–FuëğÏrd_:ã¹‰,òÏv8öG^`sHÏgX§ë;£…;·áŸ¾ÍšævmÆ[È¬€ùv8vY×ëÙH	/´‰Íqú1à0à×ĞrÜÁ5vy>³İKÇ÷\êTèœ¾7ÙñëVª†O„÷t+Ô†Àúa8
êåò9äŸ"uÊœbŠ8`q{áİ
äaßWyşu+ÕRå›ÌdOc QÛqĞ±ìÒö‘Œ§Z+U«˜gKæiö~ )„4f´áfö\æ!§@CK÷08‹l*õ†ÎVˆİzÎş@ƒíàUëäèààø¤µßXú¨=Õ‹y`›ğ‡^ÉóÏó7„@ÛíaïGÀµ`ŒŒ!{mÆvp‡å^·:;ûèÍ\ë yxØŞo5òÇG¯Úy6gz¼kl6ğÎÙ™?¬ÑÈÁ°ŸtÚü‹ænç3àoœÂdCMí£Ãã“ıæ^»±´‚î‚œaK•Bîxïğ¤µsÔŞ>>8ú¾‘/‡ÃQ^¾ØÙ…Ú—>nÊfñÒÒR>×9nŸ|×n¶ÚG<=¡x² «¡Û–>jµß°•×œÃá½ ßMÆ,[ZÍçöš;»ÍVë¨İé4€§ÿàùÈR·Ÿk5*9#îŞ“Ü‹±ÛE¦º3pp‹}g/ö*°Îí•û—­-'¬kaÁµ#;).$¦¦W-o/8gùı¬Î+^‹wòÛbÿÒgE‡=ÅÑ½³<±¿İ~ÆŠ-öÔˆ^k~ÿÀÂh¿òüŞ`şgì}Z%ŒûiÌN•³•'‡!Lîğ4¡øeZñ”‘2¡¸ŸV¼Û·»4ıøöhàtI.M  µ;J’}/‘}ë¬ë6Zowq’`{–­ñ'€K%İsxÃFâÉ’	¥İ‚	ŞÀ$Ä§ä´r»Ş9‰'˜à?î¼DépÃó9gì-¼¬Ş°âyÈ*ìı·8¿»9ÙÌím¹M·÷÷c'äù–>Önè³=€¹Væ‹I¼ôòFïÏœÜMnás]êĞÚãŒÅeTèIaîk¨ÕW
¹ÔÎıÃWÇ0IV¿ª¯Ş¤1!%Ğu­›fë_Ã`pÏÙ©ÿô8m» ¯äêÔ®tÀŒ  3‹¹èdQ;‰ÁAø®1˜ÜTŸäáåŒïìµO€öabéZÂò¿ûêûâWÃâW½“¯¾«µWÿª“/|û­VôèhrQwFaš] ôgÔ{ğ'¬Õ¨7Ÿ×3¬òïF†RJ’…ìÀêF# OrğM5˜PâƒAf•êÂ´¼TG·ïaş'`Dyö)´mV´´ñ¨Jãj:•†”üô³P=]õqÜÖXío _ÂµçUÜ¶eZ±—3[—ÚÂéàŒ¬ZK“­íy®”Mì¶gÏÒÚô£~:’óï>ä³‘ú„€J‹‹nÊÀÆ#ƒ ½@0~pÂ{PfM|)Ê“ ÉUÇ*{¥ æ\”®0Ó&´g]\Uµì Q!{šÉ¶A‹!Ğ%ö–ÄçÌzc—4qË?ã9(±®1Mk(Ş»zƒŞ+éUÔæ­Bf+8µæ…¿9¾®•Ú ,š¾ë…Ô©Ng´„<n>¿aP<5·wÛJ»9yŞìÄ„Y+£z;$ÀÆKëÒr¨=í©VgAŞöÆƒA½q·ÏW|Ø.ƒì· 3ğ¬{·ôñ»`rI"©ƒ[ŸÙŞ³}›/ÎÏ avO/¿1³|Û÷BˆN´³øÌÖğâÔ»şØuQ6¡®7Z®	®öàz¦¢§B]ŸuÏ	Ò¬’Z¶ÎÑóğVŒ£‘nQÔ\àº6‰ßA{¶hµ#-o`¡,†ˆ³mÎIOhGqXÇšbTØÑòH§;š8&ŒÏr¬xÊ? Š†(Ä~ù"KÃÿ›o
±•ÊÑHve¹®ÅĞßûÖ`àÃô÷3ÅÎ+÷Âõ®\Şô	ú^3KCÉMBø›8ÙCïÔjj>æUÑH9ñ‡ÈÚ³rÏ¾,»ãÁ@Ÿ<Pğ9a;x±7†Käİí} ó€’œÀ¤\`sqaå_ç¤ê"³qÕÅT[8ÅÏ0[\Ò%(_JË•TéŒee­ªÖ•gc9…;T¬Ğ§g2ºìÓ'øòVìÅ>ëµV+PÖµ‹DÁá¤²s%¶´r†Ò&šzŠdwSÆŞB|Ô±0Îş1‚ë9±lÏ	]zğS:Í–gpx	Æ_>Çç©H4¸’k@¿‡±ğÔØo‹İtÅòšÀh~ÌJšS=bÒ¥ªW¨­M»¤Ø‘:Ç	Ç¹!,ËÁíYÎlÜ÷‡¾5by£a•<®¥s9!€êší$'( 2 *˜”‹™İlÖƒVå’9]m¦ä]¸î…ãíÜ½°­Y~ä{8üpB³á )<²|`†íN|İ!J³ş¥SoÕ¨·ë>j{jùÁYx£+²À—Ü2WÑ„îe!¦kßœÛ»ÖÙôàHóÒ˜«Z˜ÛÑ&äøAæĞMcòúvÔ>ÜİÙn£?U»`re:”ßËÆÖØÒª>QĞZHI³}(32.F‚ØĞ‹Ú¨>ïæJ†°9³kÊb·K‰<[2A)Á15’aTÿ¶šÃLÜÎ¾ô{¨«OJ³q„‰Ø÷†Bô6ı¨ò§­€Úm²	05JJ˜ô‰oŠˆ‰fĞ)#å˜ O˜x§ˆŸ›iòGMW6ëóÄ¹/§XIÀÖ‹ùTkïM.…{e1ı% Xúxø¦%rÃÉô1E&óO›…6Ö“#fÁ˜3v¥bR6¦ıÅ<'r‹|Û¶xæ;6ğÓ5¼q½" á(¤ß‡¾7²ıĞ±Ä^qEiíúüµŞ&–ÚPÈú 6©Ÿ™L5‡c³8ê·çòª‘]ğˆ%¶mâ;ÌVşÀ”cñıpÜôÃıì¢Ã–ƒòŸ—ÊÅò²Î‡Pê&§çV÷ò²7IÇƒĞá":8(åßv…5BhQ^*Üÿ6(¿sË¬üíÍØ ÎôSÿYäªk SS¢–?òIÈl|Ûâ±Ø\éØş%¬jñ:zŸ¬œÃº°é²åD±õh÷ŒºR€h}Ë£î¤ÑË”a•¸º%:¸+…@7ZõÅ‚ÌBó_ˆåp)ãàBj·Õ<¤¿:j"5)ÃÅJ
¸¥X/4ßüéä ÷V¬«¶ü¼ırgÿãQ§‘çßÁ
éıÌ»órÿà¨½“C£ú-_Ğ46q¦ÊşÊÊnöz>ôAåêR_½{ºŒµ,¿{Vf¡Q+Këüu›7ŞœÊ·ì·>Ò’„Ş™=Î
„«1ê”:o,èÍjB—ŸİEÉnª•¤:oNÃÚ„?ÉBê4òGÓ÷ó²ŞYXï€i£ª€AC‡Ëe1š!Héı¦gşy
¡¥–9O‘½léğ øfkog_Ÿz&ÎbVoè¸sLcÉ¹+µ¯&ÎaF“&ukªÙú3zu£fN|¢w¹m‹¡üI8êùoãŞ°²át#y}‹ıæ¯Àëûhà¼¾YKeöÛ1xmúÖõfÍ`]lŸ¹5­Ö£‹X?¿´Ç§™¤ÿ/wáú"ş¿ëòÿ…_[›µJ…ü+ÕÌÿ÷!Ræÿû…üÕ€û¥øÿ
'P&I¹=£OÑÁ/İõ÷ëüO®¿ÕõxAÇ}¯7ÕÖnÊ¼‡€‚‘İuÎ®#?l Â¢wÉë>üËv^¨'ğ­İ€Ô‡÷WäÂû€şº)ŞÂÈ
wpáM¸Šv±â=Õz^Íï²{İùu“8ï‚dCfÓwJ‚	¥ÍS¥÷,gÀÄŠ<½xæ#û >²,ó‘Í|dYæ#›ùÈf>²BD>¼#ì¯\Eó‰_æ!;~æ«zK_Õùq~	¯ÂÌ¯ïæ×YÛû¯3½ø&; òú Ô–¹öİkìÜ oïÁÇW¿Uvo.zÃºSo“›ŞCøèu&¸Õ!£fZZ‘zÌû	M·AùİZù+ŸîÍ¿o!ş{¿x/!öb}›"ª…h¶e³WÎ¡ušj‰Œa´Y }¼-$‡¦p`ªÇ³®oãjÖ2÷öÑNc3{tæAÃ†Ï®2öÄqóy#YQJF"ÇÉîN7¯¹ÇÑ%[şóãåèÈÑ§î8Ì«09ÔÉ¹HáMóhıFLM‘'¢ñŞ¥´}œ {œZÀ”¡‡ÅÓVó¸yS^ÅcQ©±+¼E£†Dk)é‹4é@ÁJ,¡æ¤½ñwb &ióBB,9$Ğ÷­´ú®ünş.¼C,J«KåwÕòr!jš¾ˆROºH{œÎš,Í¾ö4¶%È.—Ä?p±1DtŸ-¯-3ø¯ Ä¾ÏO‚¸ö‰sÇuP*ğÈïŒ^ßÜw® l¶›Ï˜¡-YÔQc.-Ï x#æ¡+¹‡Åq‹«ÓvZá	lo—d¡÷‘]Š êÈ“¶L\kŸ±OÌ–Ã-Ï_}¢g (£^òps$(äÿW‚”]RÒ–;òBÅ®VoÁ\†²øKÁŞôRÆ£5xc¿kë:[)bQM^¥jwò³©åEH}/1ôzjN‰æÜxÉŠ#éÔòä”ÔÚ92íZ“[ŒšN¹—)?¥¾åP¹ñ"^¡JòÎ
³¢Ì-úÇÁèy^È¥i¯u­†L:÷òÛ·õÓå^Ôß¿_.$$’ ³ÚfÁ4¹İèàÏ}èÙ~}³Œ7lˆ5®Ë,—ßå×ŞåË	ååó(G
¦•#PÚ¹Áwfhî'KegÜœ(Ôn¸B¯ƒÜ½íêiÒ!â9n§µ:f¬µ}°·×D]_,ˆvöoÊbqĞƒÁ\,ö½ ¤FĞ‰|šËcn.ï44Ñ7K§=æCT Ø°ÈN æIËºóåß}5^†õ@š—¾0‘DŠQ0ñ]ıFàş~ñ‘†)áÉCéÈ»•{&­ŸK
-P’Q±æ	Co^{^Ææ¾)d‹C¹‘Ï]>Q'÷4Iñi@>°b@V•ƒ£z[©gÏæ‘q¢%HR
"	J®¬ĞßU¦|H5ŸOîöùéŒ»¸²;ƒeö5(0®ôí^Üüu¼am¿ÃŒÕó®Ü5P?eó¯u§°¢´}<Yk÷Jye,Ñ¼¦—&±‹É"I°‹´IÚÛäéC}ÎâûâF¥¢/ÿK¨W¡˜]7Ö§D‚\D‘˜'¦nBXÌ‚ÿ'æùĞIú"G_Äÿss}s]ùV×·Ğÿ³¶±™ù>DÊü?¿ÿ§p¿ÿOŞ _¯ÿç“ü?Ãÿó›ReËÈ³gı€»„Dë ©(t]¹‹ĞõÜ3²%Ãsé©ŠìGï3‡ÒIĞ~¥•Rõg]öAİJ¿?Ä½Úİ»A¼Q²ÏsÑt|=²sj··#€í‡§0  yolû‚ë…mr kFè:ØÈ‹ò÷xò#ÿQöb`g´?gÚ=EVıåûÒª†ª¤0†½Uvö·Ú{íıãænæ“û\û“òÉÍâÖf>¹TGæ“›ùäf>¹ÅŸ’Oî\.¹™Snæ”ûyN¹B·K:åfÎ´SÀeÎ´™3íÏÊ™vÑq2‚´aİ©ëíûp£a	@fªTgÔ‡p²]dXËÌk4™1óÍ¼FÆ^£b{nN¯Qï_
Ñp.§~s|Ú×|¦Ââ_àìlĞ*®=j3‘IÆ76ëE†µ´cÛÄ¹²íæ’)>·ß~sò¦İşÓşfsy•/äv[ÑXDoŠKqà¦P âÏ›ÛzuxÒiçñJO R(ÄŒRì+\JPAt'ÖÃ*¦PH)lvQ+Ñfì$j¨‰„ˆQÅ7³áÖ,ÌŠcÿ\ì¬
È:†ÙlRæ=ÌîêÇi:oşd=‘SÀ%<’±¿-=<|ñW¤º˜¾Ê‚“È)3Áµs…{³jR+ÂŸŞ$†GDQQš/«€Gv<¹ó&\L¥0ºÁ5Ìm˜§g—>š¸h…ŸætÕ]EYZß‰å:†ŞöÜ3ç<êÆ90êÆJFxC·°âáİ³yhTÖıp9ÌRxş#_æmì¿`Ï&µzFÓd|¹Ü¢mñ¢‹hŞiBM{g(7ÔPhZÙêòÈêÃ…jãÚ5ä£ú9–ÓT½İdâïFNoÓ¨,<µbÇó{Oö4~:¨oáT<—C±¨å³Šg;'lş“Y/µÉsøÇÔíæ8ôğªœ®%hJİ´0oĞCè=†ºMó)â„[lòŸå?ÒDq ¡kóÔ%Õ:C'Iº‘ûCVôÓGfâì™ÉÍØ÷ô&œycĞõWìóRRAJAº0qcGŞñ³ Wo^æê}‹ô¥]m’	K'ÊÌz/uL÷ÿ®T6*OĞÿ»ZÛ\¯nnVY¥ºşd=‹ÿû0éoşã¿}ô/=Ú³ºì ÃşAŠ&|÷èoáOşü_øÏÿâßÌ²y||ÄQ‰ÿşC,Ë¿ïÿİ£GzxÉvi`!: ãZşñaGÀø×ø×£Gÿó­®3 K¼Ó„Î³"ïßğ¼ÿ9–}˜OöÛ³?<zô_‹ÿé1÷ÿúÿóßã¿Õa´Ÿf2nº§:¦ÿÊ<ÄÆÿF­’ÿ‡HÙù/sşCyâÿœÏ~pãÄÅs¶¼ğ(:¹¿N4;r§@*ÉS =X]ô8´)„°yB€â¢!p°[Bn¡œ=¯{aû©'Dè¹ Ô€ĞfB¾?}ú×‹&ğ‚O† ´ç '®Øµ7n»&®ĞÍåÒòtÜ	på?pºNX‚Îƒ»¶ıGÙ]‚ôÕ>Ş©9v@Ùå¾ûE°®~Ö†ˆ¬KúŠ¡ãÎÿJ40\s:.+¡h>ùöQ‰×yÜ›Yƒ¸Ù† Áä'â_ÒudÒ+I¯y€d xˆRh“¹»¹»{²ıªs|°·ótŸR	²P®C/ -J£ySé4¡Œb‘Ü8xÛ:X¿¾Œ6#óâæÀÓÄıåq¥R°ìQ^Sú…¨¤Á„vO¨!¤€ÑpˆC@¦ÑTQkMí–­	ÃèØWIhÆv©šÚsœˆŸD¦ìh2R6˜Œ¢İT±üŸ“gÔ{}ƒ’œĞ$byèôzûÊòmô‹½7ügÆ²ïÍ×MQŞÀÌ¬#–²Jg¨+­Ahû.ôÏ%?5©NÁPâfMÈÉ­b×=vËqÓøT°P@È°–G2‚yÊ1G!·hë²%àk›ÒÂ'¬§©ƒüÙ½œ™kk³÷k%4>ï"ëØ¡$5ˆ :W"É„Nv@îk[İ]ÏeçâRNˆ¿; y¥ ßkã¥¡Ü*ğ‰ÀEr79ÍÇm#râ€¬ «fİƒíænC‡Á™Íğœ~“Ú•cÃÄ‹¹°(1»‰ÖÄ»D9š\jæØ|økå£±‘Ÿ°Ü
(èŒqş?Ò%P§İ+¢3;‹ü‹0©Gé.òU=ú‹X*——?õ,”`ÕB)´"dä›‡FHI=@Eı®çÁ¡<ü2	F›,_TU-|bˆPôc\ğÁ—z=_ˆœh2VíD†×ìYì2ãÑññ÷&GPob7èÔŞ%ïrWÕ´?Øİ1¡Q›éªàÁ«£ív·vÄOÚÜù‰;îrï"aj¹M(ïn½Ni.òï&øÈsü|>yvˆñaóø;ô;sü ÔzÑÃ[$¯Ğ%|¡;¡¼ÎWt"Ès,DW§ùºİ:AàÀ1øÏæ¤nŒr%7Â,ÂÌ‘[^é;ªÛGmT¤¶J[Û˜—›"«ª$éoH‰Ğà¡Rƒ<	¯cZLuèş‚zw»#õ®&2¨ƒ59O#˜T®LtPUÒ2I)‰³¢l:8>?L‡Æó 0“¦Üá)ª6à³3ÍR’27;iŒK&ø„ÆÛcäÄºTNìœ²‚Â4ææz{×;z­ŠZÉıN©\0,bÙËb{8
¯£1”O¸&E#¯!ÅP$]ïLÃytÂ"*&~µ4S‚¦mÂŞjDètu©Í§¨YÒ]<jOg9ÒÆ:İÕ³Vã¡]ÍšE²‰¢3ĞoÎüï$8¥Õ~Ñ|µ{¬;f¤2Œ®(ÇŠ(ßX£*µÉ7V´Dä…pàîKñêñİ­yn¿İ×>—ÏÍcÄ_÷æ
­OšVš=	t.•J¹¸ÄšÄ	LœËÓ¤-Q~·‰H¦s·Á}Ôd@ o6~[=ú­k²:êS¬.9Ø©“
èã@Áu\FQ¢šÖüd¦4/ŠëèŸPˆSá—@Ófeb•ès'¥~ªqUÔ!aôWŒïßP¨ˆ(¡ûS"çÀ˜	A‡ŒötËñ+<ü´2Ñ·{Y÷í^†/¦$»•¯wjYôı6‡î/Bz	›åñhù[îÂÅŸÑŞœ9ıäR/ÖñÉ…DkçèD’Ã»HYêé~ÿûhN–ï¤}‹Kò‚Ğ§êh«&_œtn^Ê~4(0şMİ+/ÌštXRçö÷4¶N Âs96%¶J#+ìG ùlw7ÒçÍHÀáŞ*ÇªğğL-ğ¢»²¸():Í(/¶.¨4Ó*ŒlXêëğQ(òó*Í¬»­æ!;DñÅ4ĞN8‘­cæÙN:]#k“ŒS³Rˆf#ó‘æQ,ŠÈÌGíÃüûoáQtq7%%.ä„4…T¬!™±ç²@¬"‚áq)&¹J^†´íDÌ'³†3ş‰½–ò¦~8ñ˜.Wî"›yº‹„Ö  œv¦‰fn! 1=–W¯ïjûs´£$óDÃdòªY¹_úèÜ0ieÕbÈopŸ¨fÂ‘şùÀÖ#`#ßqÃ3–ÇqÀ¾*V+üıÿªnàßÁ;7?‚àÄ_Hi{WÜ ®è›-qV¿‰®7qĞéK—%G['à><îSÄ'¾„D9K

#Œ<npÓ·WÕL(g€ûĞ¤h6n,U5ÍÃOP‘„áUYŸ”“+kšÌõ&<T´4Ô7vV`‰,ÈéÓcÊ¡hsõl¹Â° œ¿¦Rµ7ßÈQ2°q•.İ8ÜÉCeèIÉ})Ã>ÁéŒë˜t“Dªj®ÜG"ƒm¹J7'ÃòèáY}í¼lLf/®‰Š´$/q)æÄ¸^×i••¢E—-—Iÿ"•‰\y%Ïuiª*¯•ÿ¼T-Ëš•íÅîÙy<¶K—`I‹ö‡„àNÔ'*Àº¾£3W‹ªILFm{¬tÄDãt•rQ”¼…àĞ¸ç®‚ãÚû|´rã±”8´èGä}€Û3AÒ]·Ñ¾˜´ÀèHçLm¦¬óò7ñ¼"|¯®ıMò;ç5ÿb¾'ëORòQ÷}”?!ß×ß(x·—…w‰‰¯ò&,ñ´ñµ”±ŠåÓS‰•”–7¾šJYJi¹ãË©ÄZj±Ôº×yÅ·´Ÿ8«@îEÙ0pñÎQ•9øU»‡ùÕ2BN+Ç–i¯küŠ­mo8ôÜCË‡	È(×E®wEùì FjØ:zODÀCûÂ¬äñR]ŒŠDÜÌ{³½»Za·¿Æ†¶åxh3d]E±èP´Ì’O4¹ñuŒsc¢]w€ïlÅ·)z»V8’Òòšn½6ÖG(½ĞqÕïqÌ®løßå‡ñ×¸“!ôÊü´0z¯Êò(,`ş‘-q’RógI%¹Kº,ŸÔŒ2•°DxP~Ê1ªWkõG9Ÿ¬ÿ1—¿Ö€Ç~ÂŞö= ò
ô‹"_ØÈ'ñH”Õ°Aà €2Óğ»DŒÛØ¹æ¥:eM”Áèã»4º[Ô²Peù=ÑgÓ9Oâ‡(¡Ó½ ›ú%BÙ¾íkt‚‰:êŠ[ÆßiÕ&	£ƒYÚ/#èS!áä	zx€¶~¬A²zõÆÔÛyœÉ÷pqÑĞôğuR-Ó xEºípyûĞ%0‡±Ëc İ)@#æ 9lÂÊâ\%ìáŠhWM‹¶…jk_n—“¢lˆ('ã£yLÊqMÛyÑiÔÅRUËIJŒÒx45Ji7ìéÓ§QÌ	Ä&’9)›lÒ0ÅÛy“Pt¹3¨OñÂ®JM±¥ËAa…˜¸ANÓùØÂ3}Ÿ/Äá!©ÒŞ!ISß…S¿ Á5a ¹M'&mR§,êt§”ˆÿS¼BÒµÆ2]UŠëS)¼è~Ö÷	 ©;9±ÄšWö¹ºfŸ«ö¹z´"¸©ç1|ˆ¯é”ÁÃAñMµĞ‹F9ñµ•o_: =åhÏBÖHo ç1¼[CíJŠÉXÕZÀI>@?°¹E†óS1FLVÈOã 8óà†|DåÊˆÂÑäsä·ò¹XÀZÌ0øâ\¼@±÷E8îş˜ÌôŒÄ¹Q¥Kiä¨*]3O·>Ñø&>j´¬kŞè²0÷vÅZùPıœ"E®æ7ŸÌhªÀÏN¨;G™ÊRB2Y¹49º7¸””‰@éØÄ`ÍB*]95£Œ' 9’A8>xI7Ó)Ô'ÓOº ëZ$F¢Ê{uI“ù4¯štï6êÄòÒã|r§8gBæMÄz>ÒOÌ.Ia`Üyóln4b#|>dRÅÆêHÜÌ{9:š)Å5½’X'£«^)ü¦9Y¾iñ†s”OøS¥–™±=ÂoÏeÜ˜‘°ÑdH^Z©eÄXD€ÃÄ™ñtƒ_äİ¤ûw-b­ö«
$6[îµYñ0^ŞÿZ­mlUªÿ£VÛXÄ6ï+‘~åñ?º¶v*ŒêÜÜ¾ÿ×7²ş˜Ôóº÷;øÍİÿÕõÊææÖzú¿º¹¹™õÿC$ìÿ£6,ùÛ¥aïê z<ÙØ˜Ôÿë•­Z5Öÿë•õ­,şÓC¤Ç¤jQP~W‰V°´Jª·Óv/ÿù¿ÿZŠ€VÖ³üó£Üév†£nvT@îÑñÛH¯ã§õ…£†Õ £4´zEÛ¥ÜUa¦ kì ÄšŒûsŞ7üÔE8¬ÃDĞ øZ…¿Áæa%;Fpì`ÁÁŠĞ‚?ÿo )á˜‡öXcWôãÄ¸6•`Á·T¨ÅÈİ£pœ†êÊã°ˆH:*X6÷©ÇvAkLl1â¹…ˆĞ~ĞÀş@àO}t¿‡Ÿ¢+ÏlPv}Û cK’Ñ 3íĞ5;{k–ñk”éå:Œ`qÌ—ŸW}§ÛGœ(Ì®íĞBkdZ‚X¼wm­¥\nU2Í*0"íàš+ÀnZ]UlVWYÖxœ#‚Šˆ<D\ÀNÇn—vÅr¶Dn¢åzúã.Ò€H ]xON6t˜¤>…&J©#M9Cg`ÑµÖW¸µ	¯Æt3Dœ‹Üv
êEÃù`æ+ß	CÛÅ—‡ò…Üš‡y¯ì:îø{½÷ÏÿíVˆc‹¢*!R¡å ¡©Ü‘ŒNmvè`VŞoôÖ±\öG;®ËĞ·ÃnŸê¡†¬Aàaœ|ê÷š‰æèèqâa¡ùÖãQ¬»¢`@VÀ›G|õ‰F°€Çõ2BÑÇÕXd!ìÖ{ƒ(‘ö•*Š SÓ, Œõ‹êáıˆşÓ?ı ã6Ä? ¸ú_Ëì-.ñº½À~ªå cµWNVÆŠıª*V«ÅêúIu£^ûº¾ù5y4÷R§UwSWJUq)õ$hs^;4µ°¸Q8¼Uø=ü}Êjç´Ÿ½gSá1(á¨†‰ñBªoh¾‹Ş?ç÷ÿja;½ŸZÑ,R.2V)åFãÂ,pÉ»UJ»©|´Muhz¬*µ»^b{8Å‘Ğ‘—	–x¨º)UÍJšİ‘K+ˆ¢%DÛW3ÚâÉ‹5„±˜Öé‚¦B0J³ªèñ*ğøiZ9+½Šˆ˜A¯¨ÑxüßErFG'D²CÅ‚ÛUï,ÄU2š%bÛER8˜EˆI#‹q¤X¨0ã<IŒğf€¯™ìŸ6l&T,gÁôŞĞvÍ¬;E4°uSˆŸÔ&óOÓëœú1ºæ›._‰NŒ³G.·£ÏYö‹tŠ¤ÈCá­®Ê³Ì 7àsœ#ğ‹.XJP®xºº*F,áG,x-ÔÈ-¢W¡t/½ô*Ni«lEê)ü0®ÀçÒ€Ì)àÂ›h	pN¹»ôï‰H)êU—¦ø€Qb˜f/Q”Æ¢ó¡¸Àrñ^ü¦^[ÿìøö}æäÌ¿¢Ø¡@Üw…OÊO‡§4îJ‘Œy©‘e˜^6ÛğveÍP†²ìB¥	4Q@‹@8­¨IéxêÁ§4Wl¨P–ñ
Óy‰ß%ğâï÷MÌ´¸…§s; ´ØWéù·y°µ0’ãntJ…âÖÌÕk^ä‹JÀ07·È²oîìFQô¡ÛT5­[ÒKÌ`¥6zÿuq‡¯7÷S ‰ÑÊr"Lù	GûU¾á»Tú¾+¤½±–ÅVGÎ0yçĞ –3¬`9ŒòH%7åk¹Ñ)ŸÑëmàœ–sĞ)å\hÃôÃÁG?@®Úû.p^©§ç¤ú£G<Ã`<{ç¾b\çŞ¤×€Q RfäÀÈpB:«O?Å¾@gàp©¶ÿ"®%¡#hpºv,ËÕ ÀË%‚aÊwÑpÄ5}¼Óôf†Å4‚¯ §%t‹…59½c¸	 Ä©˜LÆ†Ó%#
)‰ŞTddŒ9şy.Ñİ­"¼HµA#ˆ‡Q±Ah˜uÚj^Âad®ñ!(©)ï–
q¾‡µ<İÜ-Oñ…QC±ñ÷©ÑrØªZTˆp§¸}U×>î_/Çæ°'fæŒ²· 8{Ú%––+<9¸=+Gã«F¾ÄfŞw7}bw^Ï¾.›XçñcqœÔ‘ÖM¿ÛwB›,i¹ÜókuJiUrP“Eğ•ç_ğÅz2éÚ'WK…Ö«ìˆã`Lf@:køpVW‘)¦6J`ô¬F÷û ]p†Ö…×Â×õµĞ–ë:[®ëÎEªıp-ºËÛzõ•Ôx&”}›î—L_Ëëúc<°Æ> íW‡…mä6Q‰!×ÔKì@…%4‚>S nr—ƒô»¤õ„¦Ï+ÓB­3Ğ×À<zàáÓäÊ+:ºèŒ·&—gkÂ¡#À^¹²±n‚5qÀ>VÜC!şDRÊÄ6	"½9¥{J¹Ü'~K@,}b-›‹Ì‹/ cŠCûƒK)zó'nu ã£0\ı‚Ğ„U˜Ï]{‘ı-»<Ş~ Îò6ÂWX¡Ñâ¨UÂGK;G^µ«Fe‰$ÂÄZEÏ31ƒI"„kW£OÉâL‹KŞ™hİ˜N¾áë5Æïä¿Ñ+öBøÁh³…4'GTù%	Š´Zêh¥ŞÃSâ0kŞiÒ†2oúÃƒ–¹‚z2”ÇÉî•Ø®'å3¤B².I$Eç¸™DÊ\=HÇ<QsÂ-µ°â¹>Ä«`·s•.‰§PõRĞüÄGuK[¾`¡tWõr…#ĞZ ó™]L»i2* ¾§±ÁC¹Ñ *±=‡vRvhÒˆU§×¸ÓÂVÄ.Ê‹ı®Ğç«A5öjHº´÷_«¨Åñ‘Ö¤yW=¢¿ğô”K3¦Ë«T©Å¦d½]&ªÖM|kl©ÛóNU´|ŒSR[bß£€µâÊibäU§-8·léw©Z7m–Ø+¥_ eY‹º¯¢¤ĞKØE&Q¦º6É©èáÜ+E›œ
h^4´5=¡° K²©TêR4kšHqÂã|NwŒ;˜<ˆ³ª4U§U¤]¨ù:n1'¤2³Æˆ+»ZQ–<É‰ã&eÇØê ½ã“Ó+·’É7tíTˆÃäD8”€cİ²z›(ÓÇÚËÌVK
F,ôÒğ¼FÕzšñÛÌ˜Şjsbˆ JeÀd¨ùE Ï¼Rü WjfL¯Ô¸c&EcÃ9ª
ØmfU‡¶ÏÒÚ÷Y•
VH+³kÕæ3lÚja·µó‚˜	÷£Æî©ÇÂ¼~>zšqiôôìºHÇ&°~@{à•j<°Òî»aùlxU­•j¥ji½TÁàâì•ËwÍ"+’æ¨IT«P VZç($¯_™Ônuï@ù‡ŞEµôu©rRİØˆ•ù#ŞK nôB2+9bX¡©¹Î)5ÔÑ%tÊZ³	ÚXSWÌ =£_Å-6i¼0mê;c®¯¾ƒÖÁ^sg?…ÆSGjß‰–“Ó'©VÊÇ9’Ô±RÎ©Ä7F%ô$(wúœúü(xJ¡cÆx4i²“†T”.Å‡®ö˜DWW$3mÇnšN ¨!uZä•fW×ÎG™v½ùj¦EÀëHá]
8rì¹6úk¸(8Q›?õ.mÒµÓõlÁbôæÛéÀúQp
#¢=ên1oF7ìjÁû#ÙZ°tå½ùYRH”I¡Ë¡qÒG ÆŠÎ8Ÿcô¸<İCgVçpDıx>›ŒšxÔ¢¨ÂA¨)@âıT@‘‘a68<†?¯¸ib6P´lÌ ªŒÓ€‰^L£œÈ«iï‰Yø¸jŠ£x¹ØÂ3öáJ/˜ ­1úÆÛÇíN¸ì—÷Y­ì€ÓHÄç¬ŸŞF«w©ˆ¾*,%ºèNô^daä~©¡Í¢HO²5Yİ~2.?ù`¢-ñN¬}l+p`í(.`K\TJ|á’ıÙ×Ì5(K6€ø«À6¿“IàM¨kÒWt	ÉZV‰¨2üFÖåBåŞ ÷A<7)W¬.n©ÎÏ¦®ÀP{N üÔts0şm>˜Â»¯x clI€ñÛ| u6Ô¾˜‚ôE´_`áÎ›unñµpÓ†	\L('?@?F°ˆXÌÙR±G÷Å ÄKÇ›¿a°İ@Ş0¤äÛ4aÅv‚`²JìpR~Ú¹<Ÿ#ÍP[D«_‘ Áà-ıKQvèbZ/Òç^æ"RÁñö%]È»Œvd¨áŞÿ…í¿_‘ööíÁ¨¤İÚKƒT“2hã°H¥‚r¡Ë­²·íä÷wÎ”É×ş–yÖÆ§C‡Ç°¡··(_†B"Ü®ÓÅİ*¼”‚dšµù«»äŸıĞœ²eæ5&=j¥J‰}/. õNi/Ì‚)ft-µQ„Y!{ŠèvWWW%‹ –<ÿ¼,ªÊ»;ÛíıN»@Ÿ~vËó¸I/K´tûóx|vşë!RÌŸå^ê˜~ş«²U[ßRç¿@†Ju}k³’ÿzˆôø7tä9fÌ§MÎ™ ŞÒNß¿hÀê¨Zóå{·g£ŠÓÂ@ˆŞˆ&ªß²˜ŒV·:(Ó±ìs<¯‚ñ}­µoÖØ×ÕÍ{9°ÂğÔŸŸ¯±ÌX?Ú>?»´q=Ê/¾/ÕõÍLøÔ‡}ÏŸ:¡}†Iš„Ø
è!ôúw%>1ı!ÀÉ
J·{N¨J/íZA¸Í÷OŸ_óh¡_X)%~àYìKg§Dùg3b€šÎ%/„+”ô!uO“ö7‘¤â¦$šÚDtzá„ÇI`æ^õŠP÷@]RlÂ'jäğ ªó lÑWï< ûÎA×ìë:<V¿)U¶J0·=æŒaò
"y‚qá(¨»’tû2k7´>ğxİ<j¼ÆpÆG\ÆéTËïÆx×¯¿»*³·±èïÙ²ÌÙíõÍ+„o¢/§Íu,z=0B!ÍÈ9M”¥eèÆ3ÄC™kyû©yµƒÉÀĞÖåôNÍ[¥˜ÑõP-ò5”†×rGÉ¼Î™"NO¨f=/Pœ·½œĞ/çk‘f”oí%¯•–7I‰e€ö?­b aÿN x,.<ÇÌÈş÷c4ë¨ Ï¯K?Š‹6E¤ÌEcNXp%˜>æ¸$ıpıcc™~IÂ‚Èw—ïA‚É›4n¨ˆnï”É1ì˜_ræòwdxÕEóåÅpL.w{±‹–Õ×}ÍëÃ9¯}Å=àdäf#–d.xkäÂ±“Ìo!—Êæ(|ÌÁr3©¡åîNÏÍ‡[”d‚A2bOÜi8#“F%A)ÎGeÀO½ôúü­P~ƒÆîbl´İİæq»±Í00`æûD‡ĞU¦Rc?ôXix¹ë<¿aCOeHsª¾ûÀ ôÕ«€¿JƒDvÔK«dìAÃ¬Ê+*OÔßj”+*„–ÕX–Æ&(¶Y™Şen€‹ŠÛ·+N¦6­¸on@3~EP‚ÛÁˆlsÄ¥ã5–/Ôk•eqc™l\ZµeÃ˜V,JK¿Ÿà%‰\İğ\,†>éæ P.Â(îµöY¾ë6¢í=ëçÅw¹ãBJ©2Yë˜ãá—E>CË¿–hõ~Êÿ…hƒ}Ä"Åv_,Ò–Ï«–Øû/L€’pwê Ğ•Ö˜¥ù³0½9Ë·µfeé¶):¿tuÌ°ÿTÖk[ñøo[›™ıç!ÿ£¹ùƒˆ«ò*‹…¹EÛ~¨‰ê–|¹®½ì¨·âmty
¾İoã—¤äßJQe,ÇwëxûM¯¶©ã=9u¼¼&“ó¦ôc‹­cÖøOÚÿ767Ÿdãÿ!Z½ï:>gÿgc#Ûÿyˆ„ç•ï»ÏÚÿÛÊúÿ!Rtb÷şê˜·ÿkµM`€ŠÿXÉÆÿƒ¤X”€{©ãöã}«ZËúÿ!’®á~ê˜¿ÿ7k[ëÔÿ››Ùø”ÇquÜ~üoT³ùÿaÒ„ˆ­£2}ıW­l¬“ÿOe}ãÉÆìPÿ«Ùúï!ÒcfÆ%Ê=f/Åí$êL·Ûcò:Øè–”¿r†ñ»êR¿-E/E$”WßSíÒªîAQ”1*Üx„AÛÎ}kärü²"ü»¾Dg\J<®İ:D/p;Z¿Ú(wçx2Ú•$SÃÉÄ®ÕúõD’ùÒ,š¥{LéñÃ[ÇíçÿÍZõI6ÿ?Dš?nuÌ˜ÿ¡ãı¿UËæÿI™ÓïC;ışl}w¥€˜Íè ï0æ»+ÜcÚ·ZªVÔ75Œ)ŠW=‚)oQ6QÄ;ÅŒI}Ä«D|ô0t(²wAO¼›ô8?ÂÏJå"w“)y¿Ò”uÑuÌ˜ÿ×7óÿÆ“'ÙıO’²ù?›ÿç=ìâï”óÉæ{…EÃ»²í‹Á5;"€¿k€çÆéä³v>j±•ƒ$ş†­ÂU Ÿˆ…—®~$B²³bÈ^¼ÚİÅëKàÃ wïÔ*uûìÙ3u{‡Ì'³jÏ~[ÍİùzzpÜ®O‡Ö­/GÄÊZmm}mcmsíÉg‘sgû¨½×Ş?nşT¨*L¯GÉZ(¹:/ıÔ} ·#Ø—‡¿Tš®!uÌÒÿ6áAìÿnT·ğşÏ-ÚÿËô¿ûO°èÚkhh;îè\êÊF~¡Ç:œ±PT|AíkG=¦¨ig  $¯«€|š¶VJÓÙÖLucvÄ46]#“ *[% ÅÄ°;æÑT2™§ZªàM“_^N£^Z=Æãb~ºpÏ¬-¸‡İp ¯Ï£–Æªio²œq@;
­.¥F„‚%ªè1P¿¦TFŸ4 E§S:üÎWqH…­€^ÙÙ+”X“ß`AÛ×Ø¹ïÁ{{”(Üİã:ŸÚgxïÇ˜.trÂRî±‘[Üû£—­ßƒqÏcİQ’x¤Kt–Íÿ–c´9u	>/™RAzg˜l#UÀ¯	€Ö÷l¼7ç‰?o-=Q|V5ü–.ª¸qd*pÚÄ´7º=d/¥'ğ¥€v¬Ï×ÀôÄa0>+ßà:bK,# 9b%áÛ0‰ÎITJ°â0³5{´Å‹÷#xW®˜ˆwî-
€÷9-Š\ãÍn‡yd#÷ÆrÃ áÚ!ŞãQ‚~:·Ã\/‰¿d¹·B.¿Ï_ì¿‘ ‡û÷q‘ÕK€O\9“{Åa©Q¿øªŒÃİ
~€ïŒ^ZFO„¨j°»Äs·/[&¶{cŸîzçN¯ÊáÀ¼ÑgÀ:%xŞH×—\ŒÃÑ8l W¢}è$DÈ{¢.®¹Ãñ tŠX ç—Óo“&ŞµÀ:fèèî§üÿj ;áşßzvşãAÒÛöşËıöûÜİö‚ŠÌ;"RY4ş_îíËö~ûhgû}®ÓŞ~u´süıÉ«ÃVó¸İ9y½Ó<ÙûŸ9ï¼:Ä£œ3k,Ö‹,K÷‘&Şõ¶À:fxÿuôÿß|²µÿ‡H{i»8Ÿ@Ÿ'æNâ‘!‡“ÃÉ¹¡|iì³t×4ûFÇ»×1Óş³¹¥ì?›OĞşód=óÿy”ÙtûOê¦™	èşM@Q”í¤ÑgMÁ#Ïä0ÿ¤±ÁıZ€Òï>Œ@sÔt;Ğ\Ğ?Ó4öeÂ/Æ¤Çî¸_CæĞ88lï·:'ê¡F>ı† rŞ4şTc×ºt{-£rSO±‡Ñ‡ş2v IİÔ3£¤7Š<²ñäÅ-Šú6gm	$İ2ôs5Í¸%|!uÌôÿ^_ùmU6k™ş÷)ó×Š£÷×2ÆÃÏÖy«%®Övİ”jNÊ›Ë@„×FĞ§_«GW®$ìu@¾ğùp<ÿ<×ëÖ™z™óNqO¡;€àÿÜrÉ%Şü3	‡Øu4wki°»ƒNÕÔlË+>äCÛƒ‰z"dşùV¿´hÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,MIÿ—ç¹×  