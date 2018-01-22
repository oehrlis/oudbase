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
    echo 'alias oud=". ${OUD_BASE}/local/oudenv.sh)"'         >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. ${OUD_BASE}/local/oudenv.sh)'                     >>"${PROFILE}"
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
‹ JµeZ í}Ër#I’XíJ«µÅi¥ÃÊlmm¢‡‡xòÕ…nÔŠ@Us†¯%XUÓ[¬æ&$‘M ›™ ‹Íâ˜2ÓQºê&Óè OÙ/é®‹>@î™ù @dõÙ]UÈÈSË.={ä§\.o®¯3úwƒÿ[®®ñÅÃ*«Õêfu­²¾^aåJe}£òŒ­?6bøŒ<ßpÏ1Çæƒlggc¾‹vÿşDSègÔ=æù#¯èõ¡ñı_][ß¨bÿWªë««åµuèÿµÕÊæ3V~\bÏ/¼ÿ~UB85¼^ff÷ ´Üv·Ær3{äZ—F×òXãõ
{9ò,Ûô<Ö4/Í¾3˜¶Ï~ÍÚ£áĞq}¶ô²ÙÎC™¶a›®iy¾kxÉªÏWØ—•õ*{İ7|ÿÔŸ¯°ö•åÿ`º}ÃîÎé=c`ùScÚ€ƒ‘ßs\ñ±í›g†ÍöÍÛ·Ø’czyæQZÑ¡´ßù‚ Å3€Ò­®å¥s;†çoõûÜì¾¼æäo~X·š?ğ,‡æ¥åYË"?ğl#wèx&‡ôx†µ;®5ô™ï°sşé™Ì²¡ivÇd¼…Ìğ˜kú#›uœ®‰”p|Ó“Øõ =~Ëî_³‘gvÙ™ã2Ó¾´\Ç¦N…Îé9#Ÿ½m jøDxŸA·Bm¬çûC¯V*CÎÑ)R§Ä)æ¡ˆ7gŞ­@öp•ã^×àµ\)–Ÿ«åÊc$
cÛ¶å[FŸ]š.’òTªÅJólÊ<î÷ …†ÀŒ&üÂÌÍœ3ähhñgmA¥ÎÀúÁğ±‡@Ï˜i°í¿iîï4÷ê¹å­VÈÛøç8ôŠ{½%ZvÛøp<2®	cdÔ÷Ù[£?2½4(ó¶uØŞŞß«CofšûƒƒÖ^³=:|ÓÊ²)Ÿà]ã´o²¾sÎÎ,øa‡&€ır¿İªg_5vÚ÷€¼q
Cp4µ··Nö»­zn	9Ü9Ãrå|æh÷à¤¹}ØÚ:Ú?ü¶-ùƒa–_mï@í¹-ÃmI/^Ìå²™öQãğèä›V£Ù:¬géÅ“]İ–»Qj¿eKo9‡Cº ßmÆ,Ë-g3»íF³yØj·ëÀÓ¿s\d±ÓË´÷ëåŒÊïIîÕÈî S=„8¸Ù¾3{ãçæRİDekÓò†}ãšg˜qíÈNSSRÓÙõÎYv{ïÕ>«ñŠW¢ü¾Ğ»tYÁb_ãèŞŞØÛj½`…&ûÔˆns~ÏÀh¿rÜî+`şìCR%ŒzIÌN•³%'‡Lîğ–Rü2©xÂHI)î&ïôÌÎM?®9ì[’K) ”v‡dßKdßëØõ¦åšœ$Ø®aCkÜp‰¤{	)l(’H–¤”u>“Ÿ’“Êí8ç$`‚¿ÙÙÒá–ç³ÎØ{H¬Ü²Â¹ÏÊìÃW8¿ÛÙÌ­¾iØ»û#Ëçùr7Õ[úlöa®•ù"/¹|™Qú™•¹ÍÌ|®KZ»œ±¸Œò­),ƒácu¢úR>sCíÜŞ;xs“då‹ÚòmÒº®qa2Ğlİkö9;5áŸ.§mä5œ@İ‚Ú•˜df0Û,l'18ß“[Ğ'YxaÙ<cGÛ»­à£İ˜Xº –°ìo¾ø¶ğÅ ğE÷ä‹oj_ìÖ¾hgó_}¥=<L/jO(L³”¾G½ûÀZµz³Y5Ã2ÿ®e(&<²épdiBC¾Í²:j@t0È¬R]——êèôÌâl€ƒ(Ë>ù¦É
†2ƒ’Ú¸&ÈCJşôzÖ™¼]õpÜÖXí¯ _ÂµëhUÜµe!Z‘Ä‰­KláxpZV¥¥ñÖvÛŒË¦vÛ‹Imú‘Q?Éé‰÷ò9‘ê„€J‹ŠnÊÀFCƒ ½@0~´üGP&M|	Ê“ ÉÇAör>˜sQºÂLÓUqUQ²ƒD…ì-h&Û-†@Ù;XŸ3càŒlÒÄ÷|„Kd¯ÈÚ0¸F4­¡xï8.êz¯¨VQ¶
	˜-áÔŸşúDøªVBj°hú¶ãS§z8Ñò¨ñò–AUğrØØÚiÚÍÉËF;B8 ôÄZ©Õã™>ÖKÃê£ö¨µ§R™yËõ»ÁwF_ña»4²ßLß1ºì8wóÍ>°G©(‘TÁ­NloÛÙ¾ÅçgĞ0³«–_›X¾åº@!D§KZ„^|bkxqê]wdÛ¨¿›PÇ[W½¸®§¨è‰PW'Aİµ<4«¸–­rô4¼áh¤›@T5Ø¶ÉEâ7Ğ¾)Zm‰BËX(‹!	ÙÖ§¤'´C…†8¬#MÑª ìhy¤ÒM)ã³)^‚·ä÷¨¢
qË†Ÿ¾ÈRğş<Y©üdW†mÌı½gôû6L;Qì¼±/lçÊæMOÑ÷
˜YJncÂ_ÇéĞ8— V›¨Pó1•w ¬¾(uÍË’=ê÷ÕÉá™æ±ıW³±`pcˆ°D>ÜŞĞ8’˜”,  p..¬ÜëŒT]d6®ºèj§øf‹Jºå‹I¹â*¶¬¬V‚uå™ÅX&À*Ğ§']öé|ù+t#ŸUµZ+e¨ëÚA¢àpRÙ™"Ë-¡´	§Ùİco>:êXgïAŠõœX¶g„.‡=ø)bËÓ8¼ã/›áóT¨j\É5 ßÂXøgÔØ¯İtÅ²Š@k~ÄJš	zD§KE­PY›vH±#usÿLX–ƒÛ5¬Ù¸î÷]cÈ²ZÃÖÊY\Kg2B: ÕÛ)HNP@¤TĞ)1»™¬3­Ê&sz°™’táº·sÓw†À¶zù¡ëàğÃ	MÌ†}¤ğĞp|´;ñu‡(Íz—V­Yû¾Öª¹¨íË®ÈBŠªÈ_rË\Yº—ùˆ>¬|³òl÷ZeddÓı Íkm®jb>nGKÉñ½Ì¡šÆRòºyvØ:ØÙŞj¡?†U+¯se2”ßÊÆVYnY(h-H½}(3b2.B‚ÈĞ‹Ú¨:ïfŠš°9³côKb·K‰,Ëé …”`/X0’aTÿº’ÁLÜÎû-ÔÕ#¥‚™8	ÂDì:!z›Şù“V@íÖYŒ˜‡%%LòÄ7FÄ„3è˜‘rDĞS&Ş1â'Äfœü	&‰+Èu‰y¢Ü—	XIÀÖ
ÙDkïm&{e15 änŞ5ECn9™~%¦Èxşq³ĞÚj¼sÄ,QbF¶TÌAÊF´¿(ƒgDÎBoÛÎ\Ë~º†Û)€ }ú}à:CÓõ-ÓCL!‰Ó(lHsĞçÉj›XbC!£ï‚Ø ¦~¡3ÕTÍâ¨ßË×*ZvÁ#†Ø¶XÓ@2]øSÁ÷ÃqÓ÷³[ôJßåJ…Ò¢Ê‡Pê{&§—Fçò²í&7IF}ßâ":8 Jû®ì
kßüè£+İì}å•í+}u›Ä9~,àïD®š0ñ‰Õá§>	iƒo[,ˆÍ•¶é^Âª¯­öÉÒ9¬+ ›[Œe[fW«;/ˆÒw°,Ñê½tVª[¢ƒ;RtÂYO,È4?ñ…X—2.¤všú«L¤:e¸XI —»±Äz¡ñî'û¸7°d\]°Å—­×Û{7‡ízöØ.Ã
éıÌ~µızoÿ°µ“C½ò_ĞÔ×q¦ÂşÄJß5º]ú „r5WÅ¤ã¯±–Åã%vZÊ­òäo¤çœòWì·nhIBiz³<áªº@×GôÎz%¦ËOî¢x7UˆJR×§aeÂO³Zõìáøı¼yïÌ¬wH	À¿”QUÀ ¡Ãå2ŒÅŒà%ô~İÆ3ı<…ĞËNœ§È^–;Ø¾ÑÜİŞS§ÔYÌè,{Ši,>w%öUê¦5)­[ÍÖ÷èÕµª>ñ‰Şå2´q$†Bğ'ehàx¨e¿Œ{ËJš_Ğ­äõMö«?¯ï¡!¨C@òúz5‘ÙïÆàÕñ[×ëUu±}úÖt°Åú±ğ¹=>õGúÿr®Ïâÿ»ºV&ÿ_øµ¹^-—Éÿ·\™ûÿ>Å3÷ÿıLş¿Á€û¹øÿ
'P&I¹=£NÑŞÏİõ÷Ë"üÿH®¿•ÕhAËö]§;ÕÖnyyC³c]‡~Ø@„Yï’ÏÖ}øçí<SOà;»?©ï/È…÷	ıu¼…‘àÂsm¿`…ûZéaHšŞe÷!şºÓ;ëÆqŞÉ†Ì¦î”x)¥cÍJïVŸ‰yrñ¹ì“úÈ²¹ìÜG–Í}dç>²sY!"ŸŞvŒWn@óÔ‰oî!;şÜWõ¾ª3òãü^…s¿¾Ÿ™_dmí½­OôâKw äõ¨mîÚ÷ ®±s ¼»_ıVØ£¹èjV­EnzOá£×Nq«@FÅ”[’zÌû	M·^éx¥tÌJçùGóï›‰ÿŞÏŞÅKˆ½Hß&ˆj!¤úŠ-%°ÙÎ¾qšh‰Œa”Y u´%$‡àÀ‚[`×ÄÕ¬¡ïí£Æd(öèÌƒ‚Ÿ]eì‰£ÆËz¼¢„ŒD“í6n^s£K¶øİÂbxäèSgäæ˜jùø\$Èğ®q¸‡~#º&„ÈQˆxÇ	mOó
tS˜Òw°bÚl5nKËxl",5²…·hØp-%}‘Òd¬ØjJÚkßp'F¢“6+$DÎ"Á€¾oÅåãÒñü?F,ŠË¹Òq¥´˜›¦.¢ŠÇ]¤µ½NgE–f_<s[‹ä—‰ã
¸È¢ºËWü—bßå'AlóŠÄ¹eG:(xèwFÉ·÷Ø€õvóÓ7%#Ë“:Á˜‹AËò#Î9èJ§ïÆaqÜ‡ÄâÁi;¥pŠÛûœ,ô!” ¹yR–‰KCĞsÍ3ö‰™r¸eyÒ'z‚2úá¸çE7G¼¢GşEX@™Å@Úr§@^¨ĞQêÍëËPa	ØëşC¤Ñp…yÎÈí˜ªÎVYT‘W‰Úü¬kyaRß‹½n0§„sî$²ÂP:µü‘œ’šÛ‡º]BC+½Å¡é”{™òóWÁ·lÊ‚–[/"ñÄó]Tbw–p˜dnÑ?@÷Ğq|.M»5”¨+UdrĞ¹ß¿¯öû¢öáÃb>&‘°p¤èÕŞª0óº9ÈîôAéBÏöêè›¥¥°) V¹.³X:Î®gK1¥Åó0G	Şòº•#PÚ¹Áw&hî'¹Ù·'j·\¡WA§w¯G»zŠtyN€Ûn†­Økmíïî6P×¢í½Û‡Xèwa0
=Çó©t"ß¦ò˜›ÊÁ;	MôÍRiù(2,²)Ô<i×Âb¾ø›/F‹°^HÓÒ&rH
Æ>£«ŸÆÜß/:Òğ‰y²…ÃPºònåŞ€qëg.€@”øFT¤yBãP›×š–q„y†o
™âPnès—ÕÉıuR| ¬à‘Ueÿ°Ö
Ô³Ô³§Ydœp	—‚H‚’KKôã7•¼.Íçéİ>=]¼QWvg°Ì¾Æ¶¼ÙšßÃ×¬í˜±ºÎ•½ê§lş•£îV”¦‹'kÍn1K¯é\»è,âá™³@›¤İ‘I>Ôç¼a>¦ÖÊeuùë\B]¸
Eìº‘>%dBŠD<1UÂlü?2Ì§~¤ÿ'2ñhøYü?×W×WÿÏÊê&úV×ÖçşŸOñÌı??“ÿg0à~.şŸ¼A¿\ÿÏ"ü?Áÿóy±¼©åÙ5¾Ç]B¢µ‡Tº®ÜEè8öÙ’á½øuÙÒç¥iĞ~¥åbå']öIİJ¾=À½ÙÙ™ºA¼Q²Ï^rÑtt=43hµêkw#€í§0  yïLó‚ë…i3 k†è:XÏ
ò÷xò#ÿaöªoœÏ=hÊ´>ûYõçïK44x”Æp ¢·ÊöŞÖak·µwÔØ™ûäŞƒkT>¹ó¸µsŸ\ªcî“;÷Éûä~L>¹S¹äÎrçN¹÷sÊº]Ü)wîL;ÜÜ™vîLû“r¦uœÌ¡#­_³jƒZë1Üh}X™*Ñõ)œlgÖrî5Ï8÷{ş„½FÅöÜ”^£<Ş¿,ä£á\Nı(æø´¯øt…Å¾ÀÙÙè£U\yUf<-“Œo¬×‹kxhÇõ¶=rešÌ&S|f¯õîä]«õ‡½}Åæò&›Ïìï4Ã°3Şr7¸p›ÏSñ—­?¼98i·€óx¥'P)bZ)ö.%¨ ºëaã
‡($Ö»¨k3v5TGÂğDBXñíd`¸5³âÈ=;«²Š!AÖ›4÷fõãÔ7´È	àbÉØßŒÎ.>
ù+T]t_eÁIä”ãÚ)ˆÂ½Y©âoïbÃ#¤‹¨(É—UÀ#;Üy.¦RİâfŠ6LÓ³¹¥PìÓ”î¢ª«(Kê;±\ÇĞÃ[}f‡İ8Æ‚@HÉoèV8ø¡s6Jª.‡YôÏàË¼­ı½WìEZ«'4MÉ—àŞÚ-:‹Æá&Ô´cM¹¡†BÓJF‡‡DŞ1\¨ò:ê¢]C¾Š Ÿ)°Ô˜¦A¢xè&MZİ4:'QYxjE<§÷6N÷4~™8¨ïàT<•C±¨åŞÅ“‰c6ÿtÖKlòşÂu»1ò¼*§c@	šÒE7-zÌéwÑ_z¡®AÓ|‚§xŠp‹Lş“üÇš(®Â4Tícšº¤Z§é$q7rwÀ
nòÈŒ@œ¼3“ŞŒ=GmÂ™3]É</Æ¤¤ó©;òŸ¹zôæ®Şwx>·«íòAçßâI`f}”:Æû—Ëkåôÿ^­¬®V67×Y¹²º±Vû?Éóó—ÏşüÙ³]£ÃöÛìR4aÚ³¿‚?Uøó/ğŞÿìßL²qttÈQ‰ÿş]$Ë¿éıìÙß‚^4†Ã¾YìÀ¸–_8hÿÿzöìï1ßÀè¸8š¸Äëó0ı‡è<+òşÏûw‘¼èÃ|Ú7·í®ùñÙ³ÿPø÷ÿˆ¹ÿëş/ÿÿ­<	£ı8íF¡Gªcüø_Û\Û¬DÇÿÚ|ü?Í3?ÿñyÎø?å³Ü8E'qñœ€)/<
OnD¯ŸyŒS åø).¬.‡jœÚBØÀ<>À÷qÑàYØ->7ƒPÎ®Ó¹0İÄ"ôÜôOªGè3!ßŸ‚¾òİëYxÆ'CÚKWìÚ·]×zèæri¸:îx¸òï[Ë/BçA‹mÓ…ş#‡ì†AózÁ>Ş©:v@Yå®‰ûE°®~V†ˆ¬KúŠ¡ãÎÿh`¸æ´lVDÑ|2tì£"¯ó¨'6³ú}q³@‚ÉOÄ7¾<¤ëÈ¤W’ZsÉ@ğ%ß8'swcgçdëMûhwûé>¥"d¡\GZ”B)ò¦RiBÅ"¹qğGlë`=üú2ÚÍ‹+˜O;÷—Får	4Â’Cy9Lé<
Lh÷X€
B0Q`H7zƒ*j¬»e+Â0:rÅ•Eš¶]ª¢ì9¦â'‘)YŠŒ”&cƒh·U,ÿ'ÃäÕ^Aß 8'Ô‰XXİnß¼2\Sıj÷/ĞX–àı¾ñ¶¡"ªÁû˜™õ`ÄRVéÌv¥Ñ÷M×†ş¹äÇ£Òê%nÖ„œÜÚ vİ“á™~§5„k:$#¸é8Æã(ämU¶x|mSœù„õuâ ñ(gæZÊìı6÷Ã»ÀÚ¦/I"ˆEEU„P2¡“ûÚî®ç²svOFˆ¿Ù§y%/Ó•ñRÜ*ğÀ…r·ÅÇm=tâ€¬ +zı­ÆN]…Á™Móœ^€IíÊ2aâÎD\X1¹‰VÇ»„9Š\ªkæØ|øCù]px‡tÁ7,(¼ Urİ¢W!(]š¶
Cw‚ à„‚˜UqOoèZÀÒmäU>ú‹Ï•J‹Ÿz 
²J^i.¼BœdÊ}ñò…«¾ç¿ÇM%Bp+¸ˆŞÒqéıwÇ¥¿Éß¬ŞšJvĞ`“q#`ü®rKˆGß²/Ğo*ÙÒÈsK$;èÎÁÎ¢”¤ø42Qq%ÿ‰!ºYP¨q…ˆùjµlşVŞVÎ“ä"0ln¶¶ö¿=!w8àé8¢l›ß™š]Ïèóyr>¡$İí$…f»Õ¾=gÒWŠ”bü@3	¬DT ³åPw…;¦Ç%úçLÂ…Üˆš‘q…”»ÑÛwK®3ÒP>‰;kWhß¿f/"WR¾Å`G‚äÜ¡Nñ ö°ƒ·æG³3"4JÂ%"(¸ÿæp«ÕÄ:ñ“¶è~äî×¼sÅ†IÄ0¥ü£;gk8%t8N9éÀñsAÈºÀ¿ò>s×5£oĞğÌr=_éEï½²@#tM„nùòRfÑ‰·¬Ğ7#îÁáÔn¼m5O8pşs«¸•w@†¹âÛ™– ¡gÉ-Eªg¨ní¶PÉ“kšv÷
¹e,²Š¹‘æë[Rx¨š"OBrD7…˜P;äÎ“4“†½«ê`e¶M”‡REÖÑA…WÉ$õŞ8Îe“ÁñY~<4é4ån³HÑ@í>;SZ%)3Ó8G¸$Å³7Ú-'ÖääÈNéç¬ (¼#ÎÊwwT~ ï±¨•œ(ÅY†ƒEo`f1Cÿ:CÙ˜ch\4ò|œ!]5[Í8e)Š1ïhšoa½¤Ã>‡Dèd3uŒÎ&(ËÒCü¢O'¹CG:=Ô?Zá±Fë#®Ô	6	è´ãÂ›3¿Â;1Ni¶^5Şì©î5‰£.w"Eg­*…µÉÃY´$È3áÀîKğÍğİy.ßîÎk÷å³Yóñ×£9´«“¦áùzOQ{J¬4ş[ 0Q.O’¶Dù"™ÌİÿõP“]€¼X5l;?ôdª²:ìS¬6†ª÷Ø©	“
ËdAAJpè) D%©ù	ÈŒi^×ÑïPˆ]á—@“febåV]åÌğ¼Û5:NpÔ}¿ÄÅõ7Ñ]8
õÕqAT¯Xä3>èŞŒ¤~l!ÊêÀ$(£bºñèy[Jõè_T=úá‹îûÊŸ»xù§–GÏ}è©şÿIÅH‡#Aµ8.~Åøø;:äAÊ™¥Ì¶RŒHq¾ªƒ$aAÿPâdÚíÃI9çBQrbn§JÆßşVwA”éÒÊ'Œ.F‰ú&…‚ı½lÁ³úÀKÂªˆ’fBş¦Aä1a§¶*¾qs‚¶•@<Y_Bpbßª84ü”O²cİ¨šÊVÜœç_j1áÔBß êK¹øùXiŞç,Cì¦TZšÆÔÛæÂ@”áUÇ³ï4ì %)SªÀøÔ‰YÛz^‘õ¤İŞ‰eoçzbvŠı+p¨¸«‹b²Àaë š}}üÑ>T<Æe±*†…¼•Y¬r™¶·7C¬°µw•ÆœÎ˜‰IFeRP0ì–vÈ3È‹I=¤4‚iÿDRÇ=Š RŸ&#“Ï¬fş<t>Q à¬bMšHøsÇéŸ¹Lwz¶²§L» j¾p¦Û	äå¹ë60ö+w¬åc ï¬†Båş Wu€dU?#Fgì‹B¥ìÁßøWeÿöílBW@W%$Jašğ¯lÜñ¬lCğ›è}›TMòB.g%¬ÌñáÃë	DXtŠ	³s±Ş¢H9ŞĞáÖHÕƒ ˜³å¼ô#lmÒ3ê¹ğTWÅÜXG„º˜ªr$G¦"uEmú×Ó‚Óí:ê¦ÒR×rÅ	RuÒs´H7O¶°ÜÀŠgã±=SÌ&@/}M!Òã©Ïı¡p‰Zb|ŸL§8ı ¾À…c¢HA$¢¥+BG\ÇrLğùò§1ğÀåöëz:÷Æ&ÑUËrJbÆ	Iâ;u¢¢]q›-–Hi%ı’uy¨3Ç¶i".­”¾Ë•†‹ƒ`ªèz…ÎÙyt¦MWÑˆùíG‰SP¬NQ	Ö÷~œembÂÓjl?r• XÇ©êá³¤êe•ºì¬ºvF.…‰¢jA
+ºô#ôÂí7/îTDGPißSZØbÛ†
÷*:@­]ƒ'{›”_ä„<•Õ/Ÿ'çáœh˜wcu#%/uñü	y¿|®Á½¿H~˜°JìÁèR{Ì:[)]ÄÆV°‘¼ê*6q	«ä.cSÖ°J‰è:6q;{*>Å´‡FÆÙOXÖj&FÊ"]úÕH3v¬“ô‹l·ŞZ6#ÕêlkïíÃüC°0«’å	è,x÷YØ[O/Ø%ã6,¤Ïâa!==R(î›ÊÉô‡g'‡„ì˜É®{<‡Ùµô”‰ûó2Az$Ü!˜ç—é‘ìq_u]IO.¡8;k%dzaŠ-ÆËiM©ëÊn´&E@j%”ô1Ed£¢EU“Ê% ˆE,‡é	YÅí€±¬<=© ×$Ø˜”¤}bvH×²«Ò@^´Ğè[ _ÜK„Xpë (˜½fı#•}Ÿ¡×gtl¤A‘›>AÜwÚÓ	‹r§G‚ÖË’ fzYÕOš¾+U÷ÂâçÃ|¯A9âÊ¼R#:>Åk=wzZ1Õ¾?¡°	‰!"î:€ò	w‹§£NIşjØÜ]ıaı‡y¸HZÂÀB÷¯Éş¸€ß¶¹-—6µ)4‘Ğ¬T1éÉLÁ’ÖlT¨ş'öe^fìÃQ¾;Û Ü#P|…q÷İ[*.çëK‹YøïS6_\¦ıw–Ww»»äB™
ciaä>-q(y “Ï•«¥ÅO÷ÜK€u#~v	£GQ.¥İ-°¹¥Ún¨eI&µ xàp‡ÿ AŒ[XÆr‚Âäÿúxª‘C·£Rí¡lxqËöa…¯làWõ,xø10OËşt¡é+ÉU~Åğ–38öpl=§DwhPålçŠòšÁ:,ÂteT¼ç±ÿôJr!t±®ˆåA7¸¯ÛaÃïôVØÀ4l>†Ï: -Šâ×! èÓ@gBéØÙ­À8w0Ö:rKOş²%×¤Û«”Â
C‡DÈ*Æ·0Y±·/Æƒ{n—cveÂÿ6F¶Â‡½!^âÑ’ğô,Ï}á–ã$¥æÇVZ’Üê>ll!f*	`±eòÖ«´‰ú£”×¿ÀW¶FŸÇ¾ÅŞv òôK@>¿’Oâ!(&jáşâY¸´2Ó A`,X0b}îÂmfA§¬ˆ2}mäó#]¶c”,”ã•ã^nWôÙxÎ“x`Ç!
ou.è&º!Ijß²0ë*t*ØJÿPÜf¦T'\„jféäB	Í¾k0¯©ÉiÊèÇë¹Q€Ôäµ2”3*ùâQÂ¡Ï.´¾[§ô^‘ï\ŞşóÈô0¡æe~mËÃMDÅƒVl¦ì5‰;ë*æ’§ˆŞ•x@HîŠf›Wš:•ex_D¹;iN³å¥áœÃÑÀÅ<%oÔJRnE6Ï	ªza¶œPh5RHÚt'[‹ãöÊ	…Ö›c‚W<¯“°ãqµ“PÔé$²%|Š~Ş,A©1,ÒPA8@L\ª'µ‹ldÓ#y‹)# /Í’˜nµL³'*2L9+2˜¥ÄÍ‡Í‹?¾*†m‚øLºV³AãÉÑ Æ`°&RxÖın(Å $úREi^MlC×”mèš¶]×Ç·µ,F}b&™2Ó!êç;¡pbCntwÍK„¡g‚†ğcm<LN¿x%b°Ú.ˆ‘ª•8qiA­1¹âG'›4o„†ÔY!;ƒ¢Ìƒ¸!I‚³Kø"<Ëï3íNÖ3A³Ÿ‹g(ö>Ç=“éG¡P¥ÀÓgòYx2MÅ:µìZêÎ­ø¨Ğ²¦˜Hea~¼kå‘{Ôğ2táØ³u)Òr"øÙòÕS†áI¬àÄ”„¤³r1=gÔp)Nã¥`5	©höà#jï¸…#éù£3—4OŒ¡¦ø’  Y×à«ÔÃmHÏ§¸Ñ'g¨¦–çGLÇà“nKDK7ÚÈ¬é]n	‰šŠÃt›š]vlˆvê‹©ÑˆÈéI,‘CÃó®Ğö@<Æë‘jKÀx¡ŸyXI¤‚“áU·èô“Îl¼kò°öS”ÏH,,3c{äy^<ç}«ß„[Ñtê#ñ„
ñm;ö‡Ny¿¤Fv&`¡]==2‹õl!ó¹÷Íè.?ZÇ¤ø¯/±²Z-Wªk›åJ…ÁêÚê3¶ş¨X‰çÿ±cºh§Ã[¼Çâ‚»÷ÿêÚ¼ÿŸæé:ÇüÏ¦îŒÿZ]¯T¡ÿ+ëk›óşŠûÿ°Õhî¶Šƒî#ÕôØX[KëÿÕòfµéÿÕòjeÿ÷)ZÓ¥lA\]Z
Ó6ê£"ÜjË¾üßÿéĞš4®®áv­¤¥5öq³‡6Âƒ1
Üjp<Z›ğöÆ°ŠtŸ–AÃĞ±Áaƒ×ëCÓ+²Fã¾÷´®"œ*Ö¡#hôqÿ:ŠÍÃJö·5oEøaè‹áL¼aŞƒ¦ø#Úq…]ÑwŒj›xÊšyÜR¢÷!w—®cĞ”T‡SDR.Kâ§q±]Ğ[¼ñÊ@Dh?¬o~$ğ§.Ü…û^°-ĞpÏLPd]S#cS’Q£3íP6Ú»+ì°±µB™^ ÃöÀqå:öªguzˆ‚†9ÅE"šº`±M«ƒ÷®©4¢˜É,K¦YÆâ€ŞHÒ¿æŞ‚ØMËËA ÓåeA–gU‹ )"Ï°Ó‘İ¡t±..R Ópİïùî¨ƒ4 È£u§–k$:LRŸBÓ&Ô‚‘†­Õ7\dã+ÜÚ…¤İå"»«ÄOxÕÀp®˜ùÊµ|ß´± Æeåş<Ü,ˆy¯ìXöè#{»û¿ÿã¬Ç&EÕE¤|ÃBS¹CÃš.4ìÀÂ¬¼ß(Õ2lö{Óó®Kmß5ıNê¡f¾çà=iÔ=ö5¦ÄÑQï	ƒ5åZ¾GÃHw…Á`5ùB­ië¬…–¥Ë‘È²Ø­EöP"é+UBç¾2@>ëC ÕÃûı§ú'
@Î‘¿pµ?•Ø{\¾uºù#ÂVJ^Æj·¯ŒzT\¨T
•Õ“ÊZ­úemıK:-xx„QµÑŠãœEããbÑ¥·B”‹•<G3Ú”×Î-Lw¯®$!ò¾Ğ»ü Ÿ²¯ßÃØXxJXA	ÍVù¡‚ohÓ_22{(a_|[Ñ,
¡÷Wìá÷Í.Q åÆ];7ó“À]¦ƒ3mÈØtOº§kN‚¡©
Mõÿ¼Šl§8:ò2ù"U>¦ªIbÀäRÇğÂ8ká>Ø„¶8²ç"a,¦4dIn‚·å‹“ªèò*0pMR99¹Š˜yA¯°Ñ¸„ßEù †AOR"™£bÁ´sæc„bHÛ±ÍC)ìM"DÚÈbÜ+*Z÷ôÔ	¯xÈşIÃVP ¥b9&÷†°ybİ	¢M¨›B¼&6™_çØâşvøE—oF'ÆƒÙ#“ÙVç,ó£A:EÒç¡Ğ——÷E$ĞGˆğ=ÊøE,E(W8]^#–Çp'¼jBdÈÒ†+Pº›\z§´e¶$õÆGàséôAæä1…ğ&ZœSî®Å/zsDŒÅà48U¤ø€Qd3˜f/Q”F¢³£¸ÀrÑ^|^«®Ş{¾{E÷œœyá7T ;ˆÛw®ğ-0¼Sp…»’A$#`õX(ûä²o¢±íïVVe/Ë¦*I ‰JúqE‘”Œ§~LsÕÈöÊ2^}2/ñ»ä^ıÃ^¬©éL›Â-ü;j1 DÍMÎ¿ÅÃ¬#9ÎQà†Ç¯)âåT½&à…¾¸Ôy‡ì(û¦Î®õÅ-½KUãº%¹ÄVj¡÷c·êùúÀ²ã÷>41øtF\SuÂÁ~•)|CJMá;>JŠ¸kGlud4“w`Í
–Á(ÿôW|ÿP&ËSù^}ë´”N)e|¦>ü©]ä¡¤w€óŠ]5'Õ¾âIYíİ9wïõé¦%FQ H™¡#Ãòéìm¤>9b\oùÃ¦ÚNô‹¸–’î¢mÀê˜‘,W}ï„b›'|G\“Ç;MoúµÚe6KÈi1İbBaEN/E.”8w“ÉÈÀëTÈÈAÇ‹¢7ƒØ“2:5ÿ<•hií5ñğiâÜÈU4‚8x+’ÀÀóÍ!3Î|3˜—pék|@H JjŠÆ{€e€8_‚ÃZş÷˜W r î—AÅÄß§&ãaËÁ¢B\w‘ÂíËªöñĞÈÜ6ehnáy3e|îEèÆ|qY‰a—nÏÊğ£BTÏƒø‚k¸´Êgu7í¸íÅ9ë,,ˆ;À¥>ˆ´n¸å›dIËd^^çß—¥!5Y´_9î_L¡K”ª}rµTh½qäÈH1°®Àª*2İ©„=Ë;t^Ëò³/L¼~ÖN3¨¯ù¦\×™r]×·.í‡+á]ŞÜÖ«®ÄŠxv‹+ûğíf‰‹A@cÑcw„#VøÁ´ıª°°Ü&*1äšz‘íÍµKè&ò»ô»¤õ„¢Ï:¦Z§§®€yÔ‹gNã+¯dêhè¢WßŠ\­ß{åÊÄ:1ÖÈˆv!àºâÍ#A$¥Ld“ Ô›º§˜É|â·ÄEO¬irÑ‚y12&8[°OÑÌXLĞ›?q«…áZè„&¬Â\îëØíhÙå÷­y"Jh#|…åk-‹P%p¸´³(*)0E0*‹Ô º+Òò0î¶©L!\»j} å‰Ö9€)^&¯0~¿<ÿ‡bi/„l
7[HsqD¶8A‘#à¡öğ˜{x77iCGŠ7½ãÁ
Cß?A=¿l€ß“Ô-²G ËgÈ A¼
Cºtº“IôSPæêA2æ±šc®jÉ+ëşP#²°v;Wéâx
U/ÍO|T7•åvJ÷ ^®p„Z¹èjbÓnšŒ'é46xhDE¶ëğ`âÀNÊMÒ¢êôwZØ’ØEyÕ7?Òusê|•'¨Ú^I5¢Ct¤Ñ¹àğõ Ç?1¹”š1Y^%J-6&ëİ2ñŒPµjâ[a¹N×9Z ¼àkÔ˜’Øêû]u!®ì“&F^u’Ñ‚ƒ±K†úúªUÓf‘½	ô´,+·®©„(èÅì"i”©¬ŒGr,z8÷JÑ&§š5-dE…¥),èÛ¬+BÇ‚:tMH¤8áqF«3ÂL~ıKPi¢N#&ªP»æë¨ÅœÊÌ¶!®ìê€²ä’N××)«½FVÉŸ^¹tH¾¡ĞI…8¤?„C8FÃĞ-©±2m±q¬ìĞØLoµ¡ĞhÄB-ï+T-¡§¿õŒÉ­Ö'†ªTÆ,J‘_T ğÎ+Åj¥zÆäJµk'R42œÃª€İ&Vyhû,©}÷ªT°BR™ı:>Ã&­všÛ¯ˆ™p?jdázä‚ˆû£§—¦AOÍ®Št\aÒ ë… ”^©²Á+íî¨ã—ÎW•j±Z¬W‹eì.ÎŞØ|×,´ÒÒ5‰J
T‹«…¤;Éí.•+}ß½¨¿,–O*kk‘2¿Çæ‚‘ÌÑ¬ĞÔ\ë”j©:a-YŠ„ÖÖBÚÔ1@OèWq‹i/Œ›ºÄÎ]ôÄW_„As·±½—@ã±£µïXËï‡AúóIª•òuŠGêX	^¢£zœ·zœz
ü(ixJ¡£‡g×i²„T”,Å‡òGW	š)3mEn‡O ¨!qZä•÷'W’\Qmwœéj¦EÀÛPá^
íYrìØ&úkØ(8Q›?u.MÒµ“õlÁlôæ»éÀ	Q²6lPDaW¯ÆĞÄ¼~×`G¹ö+”=¾qKW~?”ÊÉC1	t9Ğõ¨T[ÑiGq´—yèLìÈ¨?!—¨_«‰ÇÃ!L„Z (ª+	Phd˜.È+	\Ô41h$ÜWĞÀø1˜èÅ$Ê‰¼Šöë)‘…+…
Š¶ğŒ€}úÒõR´5Fßxû¸İ	—ıò>ãp	ùœƒu“ÛH`Õ.ÁË„¥Dİ±Ş-ŒÜ/Õ7¹AéI¶&£Ó‹ßèE>˜hË@¼ckÓğ,X;Š¸qøióñ…MögC\P©Õ˜xX¢°Äßx¦şLò /¥J¬I]ÑÅ$“oI$¢ÊğY—»–{}Üqì¸\1:¸¥B:?š¸@Í)òã×!Ì`üÛt0…w±3òÀ%0~›´Ê†
Òc¾÷Üy3ÎÍ&7İpxpÁÅDàdBàG)Ağ#ë‰XÜ‘-ñ
§0ô)B¼´œTˆø/±ğäİ¤|'¬Ø¶ç@V‰NÊO;—§£s¤j‹hõë!Ä³"
¤Ò¿ee/Òç^æ"RÁñş5ü;:]D;2TÈpïÿÂt?,õ|èÕJ%ŒGX<§LÅ3(Ñ  Õ¤ZÇÈ/P)¯”¯e2Ëì}ë#ùıs`^Eà˜=·oyÒ!¤Ä³æ±¸7:X<†¥Ş¡|	
å‰p;Vw«ğ:;’UhÖæI]6²É?ú¡19eÊÌ+Lz:U‹å"ûÖ_]3ç”öÂ˜b†×R[E˜á³¯=ÀîêêªhÀ¢ã—Du^ig{«µ×n èĞÏîxş7éå`‰òLyş«º¹ºY®lòó_óó_Oñ`ÿÓÜXy„:ÆŸÿ‚ßáù¿Õ5<ÿ¹VYİœŸÿz’ç/şæ/Ÿıù³g»F‡í·Ùå”‚iÏş
şTáÏŸà¾ÿÏé@6ÅO,ñßáÏ_G²üY˜ş· o‹xÌ,âí™h(Â(mÌhü/óñßÖßÿŸ¿{P;çOâñg{”:&ŒÿÍêF%2şW7W«óñÿÏÂ¯p_¤tAYÓ­&§| ^n»[c¹G Um¼^a/Geã§‰`!)ª¿fm¡Œ.½l¶óP¦m˜çx^o–ñ@µª>_a_VÖ«ìußğıSwt~¾ÂÚ ±ş`ºxüôĞF{T‘?5Õ™>5F~ÏqÅ§¶oá)¡l	Ö!yôúƒ´"WLç ²
¥[]ËJçv@Œnqÿ‰—×¼šèZLÈ€x–CóÒBí4–E~àÙ´ÈºsÙ+á
)ıßh¹N†ç4ÿ[;|äÂ-Xø Ñßô$ê´¦Şˆxœ4gXÓ›jE¸öÀµ¤p€OÔÈ3à\Î°Y_ÚKğ€Zìf\×àµò¼XŞ,VË•hÈ&//–'˜gÅ¹Áˆ‡ŠëéCn»À¡smûÆGŞo‡õ·xQÎÌ—¡…Ú•úâñèwÇ½ÚñU‰½DöùÀeÎN·W×ƒ…_NëŠëh˜Ü×bªMÈ:MŒ¸§dèD3D/ÔRòöó*úéÀĞÖætNC”5Œ`FW£2Éd(]oÁ’‰FtQJ­0;¨y1.ë´íå„~=]‹”M¹æöaĞ{Á.İ­Ø‚ób± ­?’­2€ØÿŠ@—drÄBÆĞü7d•í_¿ÏE£e0äp6ô!ÇéÇëê‹ô³@$¾½øŒß`oUïnÈ¤^Ùša2Ö;/³¦rwfx+&3çÅpH.vº‘Ë ƒ¯}úšUGsVùŠ. ñÈÌZ.+ñ\ªåÂ¡Ï©+ÈføÆx=„eõS3BÉİŸ›¶0?ˆdÄœ
¸Ó$pZ&… 	Hq>¬/@ƒD§ÇS•(£ò|‘—‘È$hÿ†]ÜÙiµê[¬cæÂO–"ÈT¬/â‡.+.{wœ¾ãÖ‘ï’Áœß] ï»A’Ç“’ y}‘Fyn™Ì¿hJ¶Yµä	Y öa|Ã¨/Jó3[/ïá7É‡ÅÍ»'ã»RÜ5‡w ˜ÃC(Şİ`„Öz	âÒrê‹—V,ê¡oœ¤KŒ†JµõEÍ¼^(HÛ:#·1|ƒD’ÁêVT¡à» µ}@¹ »ÛÜcÙ]]\v	¬›ßå,©©Á&–Š‰7|^dà#à00Ük‰V×ƒlÏ}&Úàb‘°›W(Ğ&ğ›í¦Ø	:@É¸_}PhÏZiLnIşÌoÎâÏ%îâåQí¿j°ÖYÖqûïÚÆ+WÖ×çöß'z~äö_[Øÿï¿l-<¨ó'ñ	í¿5ú'ÿêæflü¯Îí¿OóÌí¿Ÿ×ş«ºŸ§Xœq›dš‚UÉ¹9øş(üÔÍÁS(?Ÿ¯AñÍÜÑ®U9!fd@ü°”âˆ~^Rş‡ñKo™¤ÿ¯V7£ñß7××æóÿS<<ş¯rÌØEq…EîËÁ¹?TÅ:k~ #W•Ävº&Rd©ë"õP1&ğowŒe¸q­²úåóZecu£¶OíËç_>Ÿ[	¦}’ÃÍ¶Iã¿‹ÿ¿¶¾¾1ÿOñ`ĞªÇ®£|çû*ëkksÿÏ§x0^Ùc×qŸş_Ÿßÿğ$O±ëñê˜¶ÿ«Õu`€5ºÿ¡<ÿOòD¢>Jwÿ«›•ê¼ÿŸâÑÃ5>NÓ÷ÿzus•ú}}>şŸä‰…ã|„:î>ş×*óùÿi”ˆ3­£<~ıW)¯­bÿWÊ«kkØÿ şÏïz’géq‰3ìµ¸ˆ4ˆéfwÙÙÈîĞiÏàÖÑ?q†q;ÁõUE$Ô7w©ìK¥j§[”0*ühˆAÛÏ]càe2üÖcü»–£EW–®/¦²ö*w$gOV¹|tl8ÙÈıÜ¿œH²Ÿ›EçÏ#>ÉñÃg[Çİçÿõje~ş÷IÔøñ3¬cÂüëÿÍê|ş’gîôñÔN?Y/) Ò¢ïGî;ˆ8kˆ§ö¸¨+å'õ¸H¼ÆÅ«zƒ	^Ş2>£¸ØdrFqß	f¼!õ¯ualĞËÀ¢ëœzãX_§Ïú~–Ë™Û¹’÷}’®c™uæÿÕµØü¿¶±1÷ÿ~’g>ÿÏçÿi½<A@|ïœrÿÎù|¯ 0kxW¦yÑ¿fg£~_ğå·b÷1nE>Sbg[9Hâçlş« ùD,üdõ#v%+øìÕ›¼¾>ürwOb§Ç^¼nï”ÙÑ·úâ×•Ì#¯k` GËî¸´Îø|D,¯TWVWÖVÖW6îEÎí½­ÃÖnkï¨ñc¡ª0½>%«U¢äò´ôî¼Á>÷<ü¹	×õÍ¤Iúß:¼ˆıß5ÿo“öÿæúßã?3°èÚ«ihÛöè\¾;¢‹{Äã.ksÆBQñµ3¬õ˜‚¢‚¿®ò)ÚZ1Ig[ÑÕ5ŒÙÑØTL‚(oC?Àî˜GQÉdJ±Œ_-L~y:bxi¶w¿ ó¿ñ€ÒzmŞ5à8èø}fÚ»Zi¨¢½ÉrÚ©œğj5)5BQE—	€1ıö	Zx½M¡ä‘t¶ze{7_d~ƒ%^Ú¶ÂÎ]fpÜÛÓ „áî‡x¯Ó©y†÷~èBgË/f´ÜâŞ_år™šöİuÖÆù€ßtÎ²¢™âßR¤‚§.Áç%*Hîí"¤òø5Ğú®‰÷æ^"ñ§­¥+ŠOª†ßÒ­@7N›¸S€v†w‡ì$ô¡Ãõø˜8Ægù9®#6Å2K¬$\“&Ó9‰rVz¶F—¶xñ~Dç
OÂ0B°?C¼3ïQ |È(QäëïvÚ\È#™w†í{uÛôñÏ"ôÓ¹égxql4‘eŞ¹ü!st=4ëüFÂîß×ÅEÖ¯q Öqålæ‡AŒâèÅ×%¶èVğ=|÷äí%%ÄğDˆªÖG³C<w÷²%b»wæésnuğª\ÌŞÖ)Ás†*8ÀËînwäG~¸í«@'!B>uqÍ]Œú¾UÀj9?÷œ~—'õèÖ1AÿCw¿Àÿ¯
ºîÿ­ÎÏ<Éó¾µ÷z{¯õ!sH·=ƒ "óˆT^„ÿ—yÿºµ×:ÜŞúi·¶Şn}{òæ Ù8jµOŞn7Nv¿åA§Úo0pKıÌè{³õ"›?ñ¤Şõ>Ã:&HÇÿ*ÅØØ\ÿ§x,ûÒ´qş>>ÍÄ"C'‡“sMøÜØÏŸ‡>‘ñ?êŞÌÌ4Ñş³¾ØÖ×6Ğş³±:÷ÿy’gnÿQí?Iü?7=	(¼e+nôY	à‘gò˜’Øàq-@ÉŒ÷F )jz€h*è÷4¥Â¡LøÙXƒÔØkR< êû­½fû$¸@¸M¾!¸”Õ?•Èµ®®gÊà>ÜÔSèbPŸY€¤jê™PÒFšxòâE]“³¶’lú©š†"çyH•dí"&Ì¤‰şß««ÿ¯Íòú<şß“<s­(ÚQ-m<üd·š€#u×-PÍIy³HÿZúôKõèÊt„İNÈçŸ#®À‹ãgº3Î)î)túğœâ¶õ¹Äë_`&á;væNo%	vrğÏñâ‘š:ı-ÇÆ[#M7€|`:0Q§BæŸïùs‹¦ù3æÏü™?ógş<Òóÿæ™Q  