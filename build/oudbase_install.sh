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
‹ ‘È%Z í}]w9²˜óq“sù”ä!9çœKkV¢Vü”dÍpLÏÒ"íÑ®¾®(Û;×öj[dKìÙÍínJÖØÚ“‡œ“Çä5¯ùMù÷7ä¤ª tıAR){f3¶Ùİ@¡P(
…BáÔ²Ëœ*•ÊÖæ&£Ÿğ+µş¯H¬º^«Tk[•j•ÁŸÍ'Øæ¢Ã4ö|ÃT<Çœ˜²Mø.Úüû3I§ĞÿÎ¸wÍóÇ^Éë/ Éı_ÛØ|²Eı_[¯nbÆJuc}½úˆU€K,ıÊûÿñoÊÈ§†×Ï=fÅù%€¶´Ó«³¥¹ƒ=v­K£gy¬ùr={–mzk™—æÀMÛg¿eñhä¸>[yŞê LÇ0ÏM×´<ß5<ÏdµoÖØ×ÕÍ{90|ÿÔŸŸ¯±Î•åÿdºÃîÍé}ch–xª3mÀÁÇæØï;®øØñÍ3ÃffßXlÅ1½óè]É¡w¿÷J]g¥Û=ËJ/í¿İ7ìs³÷üš“¿eøaİjüÀ³™—–g9v,‹üÀ³İ‘ã™ÒsàÖéºÖÈg¾ÃÎMø§o2Ë†¦Ù]“ñ2Ãc®émÖuz&RÂñMObsÜ‡~ô8ø54,{pÍÆÙcgËLûÒr›::§ïŒ}vüºU„ªáá}İ
µ!°¾ï¼z¹|9Ç§H2§˜‡"XÜœ{·yØ÷ÀU{]‡ÇJµTù¦3ÙÆHÆvlË·Œ»4]$#ä©ÖJÕ*æÙ’yš½A
!Mø…™›9gÈ)ĞĞÒg‘mC¥ÎĞúÉğ±û@Ï™h°¼jŸ´öK•§z1lãŸãĞ+9îyş†hÛ=lãıñÈ¸Œ‘ñÀg¯ÁØôîÑ ÜëöQgç`¿½™k4Ûû­FşøèU;ÏfLwÓÉÎ9;³à‡1™ X öóƒN»‘ÑÜíÜğÆ)A6ÄÑÔÙ>Ú9<>ÙoîµK+Èá6È¶T)ä÷OZ;Gííãƒ£ù²?åéå‹]¨}é£–á¦¬/--åsãæÑñÉ÷íf«}ÔÈÓŠ'ººmé£Rû[yÍ9ŞòİhÌ²¥Õ|n¯¹³ÛlµÚNxú÷kÀ€,uû¹öÑÑÁQ£’S9âş=ÉÁ½Û]dªû07ßÑw&ğb¯<ãÜ\)°QÙÚ²¼ÑÀ¸ææ\;²SÀ…ÄÔôªåìyç,¿³ÿâ€ÕyÅkÑN~[ì_º¬h±§8ºwö'ö·ÛÏX±Å‚ÑkíÃïùïCíWÛ{ÌÿŒ½Oª„±b?‰Ù©r¶âãä0„ÉRŠ_&O))Åİ¤âİ¾Ù½ éÇ5G«Kr)€Òî0Iö½Dö­³®İhY®ÙÅI‚í6´ÆM—Hºçğ†Ä+’%)¥cİ‚	ŞÀ$Ä§ä¤r»Î9‰'˜à?î¼DépÃóYgì-¼¬Ş°â¹Ï*ìı·8¿Û9ÙÌíiØM»÷cËçù–>Önè³9€¹Væ‹H¼äòFïÏ¬ÜMnîs]âĞÚãŒÅe”oIa5Ô‰ê+…ÜGjçÎşá«c˜$«_ÕWo’˜èºÆ…É@³u¯a0ØçìÔ„zœ¶]×@rujW2`FP™Ált²°Äà |×LnAŸäáåŒïìµO€öabéZÂò¿ûê‡âWÃâW½“¯¾¯µWÿª“/|û­Rôè(½¨=¥0Í.PúõükÕêÍçÕ«ü»–¡”d!Ó3ºáÈÓ„†|“g&Ô€è`Y¥º0)/ÕÑí;˜?Ä	Ø Q}òM“e<%µq5L†”üéõ­3?xºêã¸'¬±Úß ¾„kÏÑª¸mËB´"/§¶.±…“ÁiY•–Æ[Ûsl3.›æØmÏ%µé£~2’³oò9‘ê„€J‹ŠnÊÀÆ#ƒ ½@0~°ü(GÓ&¾åIPOˆä*Šã {¥Ì¹(]a¦iÏª¸ª*ÙA¢Bö64“mƒC Kì,‰Ï™1tÆ6iâ†{>Æ%²Wb\cšÖP¼wõ½WR«¨ÍZ…ÌVpj/Ì
s*|U+!µX4}Ûñ©S=œÎh	yÜ|~Ã *x8jnï¶íæäy³!zj­TŒêñLŸ k/KÃ ö¨µ§ZyÛzÁwÆİ>_ña»4²ßÌÀ1zìİÒÇï€=Ê%‰¤
n}j{;Ìöm¾8?ƒ†™=µüÆÔòm×
!:=Ò"ôâS[Ã‹SïºcÛFıEØ„ºÎphØ:¸ÚÀõ<EEO„º>êåy¤YÅµl•£gá­G#İ¢¨¸À¶M.¿‡öLÑjKZŞÀBY‘`HhÌ¶9#=a )4ÄaiŠV`GË#•îhâHŸåHñ2<•!¿GQˆ[6üòE–‚ÿ7ß"+•? ‘ìÊ°mƒy ¿÷ÁÀÑ†éwSÅÎ+ûÂv®lŞô}¯ˆ™¥¡ä&&üuœÌ¡s	jµ‰
5óAÑP9q‡ÈÚ³rÏ¼,ÛãÁ@<Pğ9a;x17†Käıí} ó@ 9I¹ÀçâÂÊ½ÎIÕEfãª‹®¶pŠŸa¶¨¤‹Q¾””+®ÒiËÊZ5XWYŒåÜ¡â }šqÒÑeŸ>Á—ß°b/òYEP«µZÚ°®]$
'Å+±¥•3”6áÔS$»[`ì-DGë ãì#H±ËöœĞåĞ ?å Slyº—`üås|
•A+¹ôŒ…¿¢şÃ~û[ì¦+–WlZó#VÒ\Ğ#:]ªj…ÊÚ´KŠ©sœpœûçÂ²ÜaİËÆ­p¿ï#–×¶QÉãZ:—Ò¨®ØNAp‚" ‚N¹ˆÙÍdİ1hU6™ÓƒÍ”¼ ×½p¼›¾3¶ÕË\‡Nhb6 …G†Ìà£İ‰¯;DiÖ¿´ê­úõvİEm/X~pEŞ¨Š,ğ%·ÌU¡{YˆèÃÊ7«Àö®UFF6=8Ò¼Ôæªæãv´”?Êªi,%¯[`GíÃİíæ1ñcXµ:W&CùN6¶Æ–VÕ‰‚ÖB´ĞÛ‡2#&ã"$ˆmÑ±¨ªón®¤	˜3»Æ ,vë¹”È³%´ìF2ŒêßVs˜‰ÛÙ—¾ƒºú¤T0'A˜ˆ]g(D`ÓAş¤F»M#æ¡FI	“<ñM1á:a¤ô”‰w‚ø	±™$‚IâÊr]b(÷å–EğŸõb>ÑÚ{“Kà^YL}	 –>¾i‰†Üp2ıFL‘ñü“f¡õxçpÊğ©0¢ÉŒm©ƒ¨¨€Q.Ï‰œÅ"ß»-¹–	Luol§Rh8òé÷¡ëŒL×·LÑ…WœPakZûĞşZmKl-dô]P›ÀÙÏtÎš‰Í±YõÛ³úFUË.Å{·â;ÏFşÀ¼cğMqÜùÃMí¢Å–½òŸ—ÊÅò²ÊŒPêGf¨çF÷ò²·KÇßá6"z9 Ê®<ßüà£.½Tş¸ÿ­W~g—YùÛ›Ø ÓôÿYäª+ S¬–?ò™Hq|ïâ±Øaé˜î%,mñ:jŸ¬œÃâ°é²åX±ÿhö´ºRŠ(}k­î¸åKd•¨Î%:¸+%A7\•õÅªÌ@_åp=cájj·Õ<¤¿:ÁlªS†Ë–pK-±hh¾ùãÉn¬WlùyûåÎşÇ£N#ÿÎ.¾ƒeÒú™ÿvçåşÁQ{fˆFõ[¾ªilâFL•ı•ÿÜìõ\èƒ2
×¥¾z÷tkY~÷¬Ì>B£V–Öùë6o¼/8•oÙî|¤u	½Ó{œWmÔ:½>² w6«1…~zÅ»©JT’:½>+³~š™Ôjä&oêe½3·Ş!M ÿRFTƒ†—Ë0b[‚—Ğ#8úuCÏìóBK,;u"£ÙÒáhñÍÖŞÎ¾:õ¤ÎbFohÙ3Lcñ¹+±¯Rç0­Iiİšh»¾C¯nÔô‰Oô.—¡Íc1"€?)CÇC=ÿ­`ÜVÖœƒn$¯o±ßüx}­A’×7k‰Ì~;¯MŞ¿Ş¬i¬‹íÓ÷§ƒEé<‘ÅÏíö$éÿË]¸>‹ÿïúF¥&ü·6k•
ùÿV2ÿßI™ÿïgòÿÜ/ÅÿW80?Êíuvö~é®¿_—àÿ¹şV×£-ÛwŞ´X¶æ=äÌ®uvúaæ½K>_÷á_¶3ğ\=oíü >¼¿"Şô×MğFV¸‡oÌU´óŒ‡ì©ÒÃğjv—İûøëÎî¬Çy$2›ºSâ¥”5/(½gX&ãÉÅ3Ùõ‘e™læ#Ë2ÙÌG6ó‘"òáa'xå4Oø2Ù)ğ3_Õ[úªÎÉósxf~}¿0¿>ÈÚŞİ˜êÅ—î Èë P[æÚw®³s ¼½_ıVÙÂ\ô†u«Ş&7½‡ğÑë¤¸Õ!£bZZ‘zÌû	M·^ùİZù+Ÿæß7ÿ½_°‹ˆBìEú6AT!5Pl)Í>pôÓD»H¤`Ä£Ìíãm!Á8´ ôØcÖuM\Íú¶>ÚiL†bÎ<(ØğÙUÆ8n>oÄ+JÈHä8Ùİéà¾5w6ºdË~¼9úÔû€y&‡z!>	2¼ií£Ëˆ®	!òD"Ş»„¶§ÀyºÇ©Lé;X1m5›7åU<6–ÛÂ[4lH¸–’nHi2Vl	5#íµo¸£ÑI›bÉ"Á€no¥Õwåw+ğwábQZ]*¿«–—aÓÔET@ñ¸‹´¶·Áé¬ÈÒ¼àë±gNbkQ‚<àrqüCC´@wÙòÚ2ƒÿ
Bì»ü$ˆm^‘8·ìH%]ÎèõÁ}gÀz»ùŒé›’‘åI`ÌÅ åùgÄô¢Ówã°8îCbñà´R8Åyíí’,ô>” K! /8ò¤,WF çšgì3åpËóWŸèÊè‡ã—ÜñJ¹ş•`e–iËıy¡bW©· /CYt„%`¯»Æ£5æ9c·kª:[)dQE^%jwò³®å…H}/6ôzÁœÎ¹ğ’GÒŸåOäÔÚ9ÒíZé-ÆM§ÜÁ”Ÿ¿
¾åcPk¹5ñ"^x¾‹JòÎ
³¢Ì-úÇÂè9Ï¥i¯u­†L:÷òÛ·õÓa_Ôß¿_.Ä$’ ½ÚfA7ÙİèàÏ]èÙ~İ²´7lˆ5®Ë,—ßå×ŞåË1ååó0G
º•#PÚ¹Áw¦hî'KegÜœ¨İp…^Ş½íê)Ò!ä9n§¶:b¬µ}°·×D]_,ˆvöoÊbqĞƒÁ\,öÏ§FĞ‰|šÉYn&ßî$4Ñ-K¥=æCT È°È¦Pó¤e\‹ùòï¾/Ãz	 ÍJ_˜È5"E(ûŒ^~#pW¿èHÃsb‡¡ô äİÊãÖÏ¥ -PâQ‘æ	Cm^{VÆæ¾)dŠC¹¡»]>V'wÔIñi@>°¢GV•ƒ£z;PÏRÏæ‘qÂ%H\
"	J®¬ĞßUº|H4Ÿ§wûìtñÆ]\ÙÁ2ûÛòúf/j~;^³¶ßcÆê9Wö¨Ÿ²ùWŒºSXQš.¬5{¥|`,Q¦—ÒØEg#˜EÚ$íMòô¡>çóñ}q£RQ—ÿ±Î%Ô…«PÄ®éS"A.¤HÄ	S5!ÌgÁÿå¸b~–$ı?‘‰Ç£Ïâÿ¹¹¾¹øV×·Ğÿ³¶±™ù>DÊü??“ÿg0à~)şŸ¼A¿^ÿÏ'%øŠÿç7¥Ê––gÏøw	‰ÖRQèºr¡ëØgdK†çÒÓ ²½ÏJÓ ı<J+¥êÏ6ºìƒº•ÿpˆ-zµ»;sƒx£dŸ=ç¢éøzdæşØn66nG ÛOa@@óŞ˜æÖÓå@ÖŒĞu°‘/åïğäGşÃ"ìÅÀ8Ï<hÎ´>{Š¬úË÷¥$e„1¨è­²³¿}ÔŞkï7w3ŸÜ;píå“›Å­Í|r©Ì'7óÉÍ|r‹_’OîL.¹™Snæ”{7§\¡ÛÅr3gÚ	à2gÚÌ™ögåL;ï8™_ #­_·êÃz{n´>,ÈL•èŒúN¶ók™yÆ3f^£™×èÏØkTlÏÍè5ÊãıËB>ÎåÔbOûªOWXlàœZÅ•GeÆÓ2ÉøÆz½È°†‡vÌñÀa›Ø#W¦yÁl2ÅçöÛoNŞ´ÛÜ?Pl.¯ò…ÜÁn+ü k€0ãMqé#î Ü
Tüysû¯O:mà<^é	T
…˜VŠ}…K	*ˆîDÀzXÅ¤Â!
	…õ.jÅÚŒDÕ‘0<ñ"¬øf:0Üš…Yqì‹UYÅ ëMÊ¼‡Ù}ı8uçÍ/Ö9\Ì#ûÛ€ÑÙÃ˜ƒÀG!…ª‹î«,8‰œ2c\;Q¸7«"µB¼ñéMlx„t%ù²
xdÇ“;oÂÅT
£\ÃÌĞ†Yzvé£‹R(öiFwQÕU”%õX®cÔámÇ>³ÎÃnœcA n¤dˆ7t+şÔ=›…FeÕ—Ã,ùç?ñeŞöÁşö,­ÕSš&ƒäËpïm‹GãğNjÚ;M¹¡†BÓÊF—GC1R¨ò8î¡]C>ŠxŸ)°Ôp¦ÁK!ñĞM&úndõÒèœDeáq,¨ñ8İÛ8İÓøyâ ¾…SñLÅ¢–;;Ow&ÙüÓY/±É3øGÔíæØwğªœ®%hJİ´ì1gĞCè=†ºMó	â)Â-2ùOóOh¢¸
ĞPµYê’j¦“ÄİÈİ!+ºÉ#3qúÎLz3öµ	gÎtıó¼W.¤nìÈ;~æäê-ĞË\½o‘>·«í™Ğù·t˜YRÇdÿïJe£òı¿«ø¶
¿+Õõ'µJæÿı éïşã¿}ô/=Ú3ºì Ãş$E¾{ô÷ğ§ş/üçñofÙ<>>â¿¨Äÿƒ?ÿ!’å_‰÷ÿîÑ£ =¼dŒF³40<€q-ÿø°#`üküëÑ£ÿ‚ù†F×ÅĞÄ%Ş€Gè?BçY‘÷ïxŞÿÉ‹>Ì§sÇî™=ú¯ÅÿôO˜ûıÿùïñßêƒ0Ú—™´…TÇäñ¿ßÖ£ã#ÿ“²óŸçüGà‰ÿs>ûÁStÏ	˜ò®£ğäFô:ÑìÈ"NTâ§@z°º©q"hSaóø ßÇEƒga·øÜB9{N÷ÂtOˆ ĞsÓ?A¨¡#Ì„|
úÊw¯çMà9ŸAhÏAN\±kgÜvM\ë¡›Ë¥áZè¸ãáÊ`u-¿-¶Mú²»"Íëûx§fèØe}X”»&îÁº
øY"².é+†BŒ;ÿ¢ášÓ²Y	EóÉÈu°J¼Îã¾ØÌÄ¥6| 	&?ßøòn"“^IjÍ$ÁC”|ãœÌİÍİİ“íWãƒ½¢«”J…r:iQ
¥È›J¥	e[ˆäÆÁ“ØÖÁzøÍe´9š×0v î/+•2h„e‡òr˜Ò/$H
Lh÷D€
B0Q`H7zƒ*j¬»ekÂ0:vÅmEš¶]ª¢ì9¦â'‘)[ŠŒ”&cƒh·U,ÿ§ÃäÕ^Aß 8§Ô‰XZ½ŞÀ¼2\Sıbï'ĞX–àı¡ùº©"ªÁû˜™õaÄRVéÌv¥1ğM×†ş¹äÇ£Òê%nÖ„œÜÚ vİ“á™~·5O„k9$#¸é8Æã(ämU¶x|mSšû„õ4q?[È™¹¶2{¿„Æİğ.²éKRƒ¢CQQ!”Lèdä¾6ƒ»ë¹ìœ_Ê	ñ÷´3/ã¢ä{e¼4·
|¢ p¡‡ÜMNñ1ÁAÛ8 +Ãªg÷`»¹ÛPapfÓ<§Ã¤ve™0qç".,˜ŠÜD«ãÆ]HBÏE.54sl>ü•òáXÉ‚OXn
tÆ¸@ÿé¨Òî†Ñ…şE˜TÇ£Õ‚ôy‡ºıÅ¿,•ËËŸú Š°j!†‰”Z!6òÍı0º=BØT‚ßõb‡«¾Õí“,|bXGt^\Äá«z=_=cç2 çíëû×ìYä†âÑññûFP‚ïL7è\ÔŞ%—q;8€i~0»cB£,vÈƒ‚¯¶Û-Ü¯?iÇæ÷Æå.CÂ~ñK)¿p_]§$¿÷w)ï?8İö–×[û¨æ6¿G‡°3Ëõ|¥¼òÊÁ5ºåËëyE'Â ˜oÑPuš¯Û­ƒÿÜ(^FÁm€a®øî–€%@è™CrË{ºq¶F=aûà¨s¾TAI
+»írQd¢’Ä÷i
<ÔT'áuDU‚ù}ZPYà¾t$XÃŞUDu°"|óI““ê?J&©Åq(›ıÉĞx¦Ó”{Q"E-øìLño”¤ÌÍâ#á’GÏh{´œXW“#;£Û«‚ pø®ŞŞoõ®¨¢Vò©ô(±–‡µ®9ù×áÊÇüã¢‘×àÏbü	’®šË¥æš²2ŠÅ˜³,ÍÀ >ë0¤:Ä\ıdó	º“„t7ÙÓiŞ±‘N`÷u—U8C¨ÌB]&F‘lĞhÇ…7g~…wbœÒj¿h¾Ú=V½-FÕ~#E‡W­*…µÉáU´$ÈsáÀîKpÕğİ­y.ßnÏkwå³yóñ×Âü›ÕIÓğ|½'Î¥R)•Xiü÷˜ÀD¹<IÚåw›ˆd2wkü×GMtBğ6`£·Ï£3º"«Ã>¥Ájcärš0©ğ(=t¼	ÎÀ”¨&5?™	Í‹€â:ú
±£+ühÒ¬¬B¬}püéK–œüEW q…ùÇè¦E~ê‰0ª“$rŒtHoÎˆaA·¿ÂM+©ÛËªÃö2|Ñ]Ù­¸Ë¢C·>„T·îhÒÃHØ,GËßr¿,şŒ>VğæÌ*¨Ç‘zè´6/$Z;G'’ÎEÂROÍğİwáœ,ßI£—ä=Œî NÕáşK¾èYèÜ¼”ıh$`ü[pO¼°UÒ	Èprº_—«Ó\(p“cRyY&ø÷\V–Bzb%µòbû€J3¥ÂĞ”R_‡‘ŸW©gİm5Ù!J¦€Æ¾±l=ŸÈvÒéìjY›ää›˜•Â$k™¯^QDf>jæçØs„ J§ñ(.˜T™$„èbÉÇ´}9b,1ÉUÁ`cHÛNØÙÈ<Q2+1íŸÈÛI)¯«s©GeT1pQÊÓ}ªÅª5I’òtyŠé±\g:}[Ù#£]™'&é‹\h~é£uÃ„MµªÄqß(hàî¨¦Â‘~w`ë!°‘kÙşËã8`_«ş~‚U7ğoï°¢/¤4‹¼Çkf Wô–8¿‰®7QĞÉ+%KQëñ‹”#8ÍñÍßä‰¸D9+ 
åánS·8ƒ9PÎ .\5pctã[xU;ñ¥‘á÷ãK_š²U¤ŸÎ
*Í†,¬†-Öò°À9h"eJQ‹‰äô‰cé1àÎ
(M5‰ïï,˜A¸®3#kpYÿLÑ!µ¬±ÄÏÖà!§—ônå*šøG¹@òÖ‡`g‹*|Qe/&Dqõ^´Ùr™4RNÈ!‡rl›&…òZùÏKåÑ²¬9g=¯Ø=;/¢åÃ´éÊ!Ópa‘±úDX×÷tÂh^5	a¬ÕÖY`u Å§*oó¢ä-†·Â=÷Ş×ÎØå£EİåøÆ¡E?Â½vÜ·ğâ›ót”‹6Œ¤iB•*g*sR½˜ß€”¿‰æ¹à{uıëoâß93æ{²ş$!ußGùò}ıM O3bòŒÆd»åÜÖRJÏD×S)‹)¥DtÕ¢-Y"ùÔeKlÍ¢ä®[-JîèÂ%¶j™/µÊ-˜W\s€ókú¬¸+eÃ0½;GU>æàWmó	ºº
»œV0R^×ø…RÛÎpèØ‡†V0®@lçŠò™ŒÔ°uø>ˆğ~<Òƒ^Éã¥º±<¸Ëõ>b”¶64ünMÃöğˆ¢Ïº 4,ŠÙĞ% h²$`r’âÚçFÖCƒç ı¼ÙŠkR¬r¥p(¥"ÀBªg¹ü°~øZ[‰ ôB7M·Ç1»2á›=_ãBLŒ+ó³±è«)Ë£°€yú'¶ÄIJÍœ”ä.©²8z.1ÌTÀbÁ0ù™¾°^¥MÔå|¼şÇ\şé{Ûu€È+Ğ/ùü~H>‰‡@¢;¹ƒh¡€2Óğ›3­ŒŸ¹ætÊšÜët†£±ÏølÇ.*Y(ÇÇ½2Üè³Éœ'ñÀC<ßê^Ğ½½ğ lßt:ÁDöEéâï”jã„‹ĞAÍ,õïúDH8y‚Å¼ºÍÓˆ1ˆ×óQR—AB¥vÍ£ÊH¾XHğ»ùÅşRƒµIµtÆÍqàéÏÂåí_A—ÀÚö‡ùt'Í)Ê¹0™¤¬Ê…=ÃºŠŠ¿­š[
ÕÛ¼ÒœÓbJˆ˜'ã£YŒÒLÃF],•œ¤Ä¢FÚ{úôia±IÚkÕ–"I®€t®ZÛ’’PT¹Y¨Gk
 ŠKäüš˜l“×½ùB¶1éÒ"ñ=‘&ñPJÅŠ3Ôd*Ğ¶kÂjLuS‰A	7ÁÏa.}¢­ĞS6¨1`×D
 Â5ßWú7yO!Rq­º0=ÕÓS]3=ÕCü¦Çèb€$·ÏD·w|'VlÄ3®yiÁp%”C#	4„mâ8;NxuC°?&öÆ"U+çÙÓHÀ„lr•…\î47„°Ğ»0?©ç£[Ã!I§:|.w˜Áîÿ8>ì•#!÷ñ·dyPÛR¿÷ÎQL}N[sé¾y8	¢;¤tj]%¥sà©e×S­\â£BËºâã,sK¬•Ÿ,T¿Q@daçré$†â"	|lùªÛkè¸ğIH:—Òó¡ƒ­†K)ğb(İ›¬iHE³nµ¨oâÁ2¤çÏ^ÒÑq5Å´äÈºÆÀIkDà?9…¤ñ|Š_G²•@5µ¼ôyNïëLÈºT¬g#}jvIúí*•g3£á³!“X(2VGâZ]ŞËá‰?©¬!QS+‰Tp2ºê•ü~’›Ïá›Œ7Cù˜GOba™Û#<·ñdÀ`msä'”èÓDŒÕ‰ÅÍ‹EN¶¬…ş5ª‡Ñ<E_fü±ı°Ğ:¦ÅÁx	xÿgµ¶±U©Vü¨m¬?b›ÅJ¤_yü‡®é¢å£:z‹â‚Û÷ÿúFÖÿ“zNw±ƒÿÑÌı_Ån¯Õ°ÿ«›xÿoÖÿ‹OØÿGmX“·KÃŞ‚ê z<ÙØHÿSÙ‚>×û½RÛÊâÿ<DzL:eâêĞR“û¨MŠp+mûòŸÿûÿ¡5¨O=ÃíY?É½_k8 ùß£r„Nj†
?­-ü71¬º eÆ(Ü@änjcğx]cdz%Ö`Ü—ó¾æÒ,Â©`:‚Æ M¦×AølVr°£GöÖ,İøƒñ?ğ†9´øcÚa]ÑwŒb›èVÏ¼!n2P‹»Gá5“Çá‘T‚`ÉÜıÛ­Ñ±Åˆ×"B;$ó?uÑSj8tÒ†®À;3A+uMŒ-IFÎ´gÕìì­1Xo¯Q¦—cè0‚=Äõ*_'òƒÄd˜\„¡		³´V0xïšJ#J¹ÜªdšU,`DÒÁ5÷@ÇnZ]™¬®
²¬ñ8+Zy†¸€í.í©Šug‰„ëjÏwÇ]¤‘@ºZ6¬pLè0I}
M“PF²†ÖÀ k¯p³^éf€(Ù=åÀÌ‹&†sÁÌW®åû¦0.åó¹¹3ò^ÙµìñözïŸÿÛÿ¬ÇEÕA¤|ÃBS¹#Ãš.4ìĞÂ¬¼ßè­eØì¦ç]—;¾kúİ>Õ/BÍÏÁ8éÔ=ö5?=ËÑQã„ÃŠğ1Z‚Ç£Hw…Á`7ø2­Uë¤…–¡«‘È2Ø­%öP"é+UB§¦@>ë# ÕÃûıË_şBÈ¸­ï÷ ®ş·2{‹k±nÏ3ßcD˜jÙëÃXí•ã•±b?‡ŠŠÕj±º~Rİ¨×¾®o~MŞ´Ú½Ä	Eƒ»‰+¥ª¸”8ÚŒ×ÎL,,n”M@o•}Ÿ²§Ê‘ŞgïÙDxJXA	Íø¡ƒohgß?ç÷¿*a½ŸXÑ,.²RÂ¶…iàâwÛ)é¦ê)Ğ"4U¡©±Š‚ıæÛÃ)„¼L®ÄC•M¨jZR„\ê^x°>ÜšÒGö\¤!Œ…À”†¬H§¬à´~¡4­Š¯O*&UA‘“’«‰Yô
'Õø]÷ axÊ-%’*Ü ê9g>F(’´Û,”ÂŞ4B¤,Æ½r"¡¢´³Âë¦²Ò°H©XÎ‚É½¡lšZw‚h`Sê¦/‰MæŸ&×9ñcxÍ3]¾œh f\nG³Ìé,I‡B[]•Ç^A!nÀç(GàU°” \ñtuUŒXÃXğZ¨9
‘![H®<Bé^réUœÒVÙŠÔSø¹MÏ¥3 ™SÀ7„7ÑàœrèİA5‚Ó<TY’âD‰Íaš½DQ‰Î†âËE{ñ›zmıÎ3ğí+ºãäÌ¿¢Ø¡@Üs…OÙœî(Ü•"óR#Ê.¹l,¶İíÊê¡ìdÙB%	4Q@‰@7©h ’’ñTƒÃMh®Ù.@YÆ«Kæ%KşÅ?îÇššÎ´)ÜÂ¿Ó™J˜¤äüÛü\}°0’ãnxº‚BœÌÔk^èIÀˆ(·È²oæìZQ šÛT5©[’KLa¥6úÃuq+œ¯,;÷Q ‰‘­r"Lõ	GûU¾áÛIê¾}£¼±vÅVGN3yçĞ –Ó¬`9ŒòGÅwÿäk¹#)ŸÑl`–sĞ)åœoÂôÃÁ‡?µ@Êû.p^©§æ¤úÃGôê×s×ñ1®o/í5`€”Y02,ŸÎ	Dê“#ÆõF‘/Ğ8\`ªíF¿ˆk)èÚ¬®Ér5ğğro˜ğ]4qMï4½éaµ`¶+Èi1İbJaEN¯D.”8'“ÉØÀpªdä c%Ñ›A°ŒI´„wk'/RmĞâ`Tdç›#fœùf0/á0Ò×ø€@”Ô÷ Ë q¾‡µ<İÜ,ŸñeQC1ñ÷©‰UØj°¨á.S¸}UÕ>îŠ-ÇfŒÅ&<[fÈ6§lÊ%††-\.¸=+Gã«F¾Ä¦Şwœ×"wO¿.™Xçñcq˜Ô‘ÖM·Û·|“,i¹ÜóëàÜÎª4ä &‹6à+Ç½à‹)t9RµO®–
­7°#½1™éœ7âÃXUE¦˜Ê(Ñ×Ò=ô•&^?ã	§Ô×|S®ëL¹®X‰öÃµğ./nëUWbPã™PöMº_0y1h,{¬ëÑU~@Û¯
ÛÈm¢C®©—ØAÁNúK˜É¯eÒï’ÖŠ>è˜xOú•§®€yÔÀ³§ñ•W2u4tÑinM.ÏÖ„ç…‡½rebİkdÄû8à
ñî‘ ’R&²IêÍ	İSÊå>ñ(ñ‘ô‰µL.Z0/¾€Œ	ìSôf,%èÍŸ¸ÕŒÂp-ôBVa.w%ì…ö´ìòxë8İÚ_aùZ‹Ã"T	.í,yÕj0*KÔ qÔ=Òò0Ğš©L!\»j}JgZ\òÎDë†Àt_¯1~¿ÿ~â´Âº„›-¤9	„8¢ƒXœ H‹¡6T{xB^ÅLÚĞQ†âMoèjoèû'h¡çÑ%yœä^‰í:Y>CBÖ%é8Ğ9ê&ÑOA™«É˜Çj9š%#,¬x®»#»sScìv®ÒÅñª^šŸø¨n)Ëì ”îA½\á´èzjÓnš ‡ïilğ¨_4ˆJlÏáÑã€†”š4¢EÕé5î´°±‹òb`~ póê|U ¨Ú^I—öşë Àmt¤5iŞÑ±wrŠÉ¥ÔŒÉò*Qj±	Yo—‰g„ªUß[êöœÓ Ê>F)‰­N°ïQlS²_šyÕIFÆ.êã}ªVM›%ö*Ğ/Ğ²¬D]W	Q
Ğ‹ÙEÒ(S]›ŒäDôpî•¢MN4/jZÈšz<_SXĞwXW*„u)ğ1MH¤8á7«;ÆLï7¨4Q§U¨]óuÔbNHefÇWvu@Yrù&è”Õ#«ƒäO¯ÜH:$ßĞh‡¤BÒáPÑp tËÁÛX™Ø8Vvhl¦·ZŠPh4b¡–†ç5ª–ĞSŒßzÆäVëCˆ U*cëB¥È/* xæ•âµR=cr¥ÚµS)ÎaUÀnS«‚<´}–Ô¾;U*X!©Ì®™Ï°I«…İÖÎb&Ü[¸§‰zwôãÒ,è©ÙU‘+L`ı€òÀ+U6x`¥İwıòÙğªZ+ÕJÕÒz©‚ÁÅÙ+›ïš…Vº@š£&Q­BZi£¿~#­İå±çRØùò½‹jéëRå¤º±)ó¼°#¸Ñ	ÉÈÍ
MÍµN©¡–*¡vĞâ˜¥Hhm-¤M]ô”~·˜$ñÂ¤©KìŒQdo¾ú"Z{ÍıOm¨}ÇZ~7ÒÓ'©VÊÇ’Ô±”D7F%ô8oõ9ôø	,PÖğ”BG/¨Ód'	¨(YŠ]å1®ÀGfŠ^¹>™ PCâ´È+L¯¯3í:³ÕL‹€×¡Âÿ:¼Ê³ä2Ø±Mô×°Qp¢6ê\š¤k'ëÙƒùèÍ·ÓÕÃÑ:6DEDTc¡jb^.­ØUâ¼‡²Ç7.`éÊƒ?óÃ<Ò’@—CíH:@µvFëqy‡•ÆÌˆúñdx27i5ñ8>a#„)‚P ‰Cå…F†éàğ`ú¼¢¦‰é@Ñ²1h`ü˜LôbåD^E{õ”ÈÂÇUSœ™ËE°?Pz^Š¶Æèo·;á²_Şg´¦±N#!Ÿs°nr	¬Ú¥"ò§°”¨¢;Ö{¡…‘û¥ú&7ˆ"=ÉÖdtûñîäƒ‰¶Ä;¶ö1Ï‚µ£¸€+vQ%ñ…MögCÜH¢Õ˜xX¢°Ä_y¦şLò /¥J¬I]ÑÅ$“oI$¢ÊğY—{…_Í~†íÉ£‹[*¤ós ‰+pÔœ(?ŞÂLaÆ¿ÍSxãŸ!`Œ–‘¿ÍZeCé‹	H_„ûî¼çf_7İpxpÁÅDàdBàÇ)Ağcë‰h¹Ü‘-1fwxµB¼´œTˆø½zò2š@¾MVlÇóÆ «Ä'å§ËÓñ9ÒµE´úõ	âY] ŞÒ¿w†.&¥ñ"}îe."Ìo_Ò…¬ËhG†
îı_˜îûyakßŒJÊ­­4(@5)ƒÖ1ö‹TÊ+ê¹Ü*{Ûş@~ç˜BI¿öµÌ³°¸7>Z<ª½½Eù2*áv­.îVáı$«Ğ¬Í_õØØ&ÿ,è‡æä”)3¯1ééT+UJìq©sJ{aL1£k©­ˆ"ÌğÙSD°»ºº*°ä¸çeQWŞİÙnïwÚE úô³[ÿÀMú…,QÒíÏÿU77«Ùù¯‡H–…Ô1ùüWe«ºù„ú¿¶^İÚØ ûßáßìü×C$qÿûÅ¼¯_Øğ?Ó+àS/wxÿ<¯×KäEğÒÿ…Ôu2<¥ío<-IÅía®‹Ÿ÷--IÂÇ/{_?_‚»rçtû.kÛ7>ğxİ<j¼Æ ¿sG\éTËïÆ¿×¯¿»*³·‘0ïÙ²ÌÙíõõ+doÂ/§Åu,|=ĞbÍÈ:MŒd¥dèF3Dƒ{+yû‰y•ƒt`hës:§ú­Â˜ÑÕ˜*ò5”†×rGI¿Î—b0§Ô
³ƒšC
ÎÚ^Nè—³µH1Ê·vâ×
Ë›„½X1@ûOd«H ìß1 Å…×¸‚™?á~ŒbàùuÙ'@qÑ¦”¹pÌ	ëÏnRÇ—¤®j,ÓÏ"IXùöò$˜¼D.fpAãFy-õ>““áyñ%k&G†×LP|[^ÇärW¹l™Øf9ø: ¯yu8ç•¯¸ÏÜ¬åÂÁÏoµ\8vâ¹à-ä
²Y¾1faYƒÔLÁˆPrw'çæÃ-Ì2A#±§î4	œ–I¡G AR î»“lw·yÜnl³ğ9LdŸèLy©ÔXÆ=VZÖì:Çmcß	2$ƒ9¾»ÀÀwƒW•Íˆì0F—VÉvƒv XdW‚<a÷ƒ6h”oei;‚b›•É½Sæö´°¸y»âd9SŠ»æèv [VÅ»ŒĞÔ&A\ZNcùÒJ¼PWæ7–Éd¥T{ÑXÖlcÅ¢4ŒñÛñ	^’UíÈÅ¢ï‚Ìm å"Ê^kŸå»v#ÜŸŞ#°n^|—(¤cho<ü¼ÈÀGÀah¸×­£)°­&Ú ±H0Å‹´ƒój§%¶rÄ äÜl:(´á¤4fiEş,LnÎòmSYZx
Ï/-®)öŸÊzm+ÿmk3³ÿ<Hâñ7P qU^e‘x´h»À5ñ!¸w_®+/;ÁÛñ6¼NßnŠ·ÑkCro¥¨2–ã»ˆu¼¦—½Ôñæ˜:^ç’	šYSò1ÇùÖ1müÇíÿ››O²ñÿ	­.º»ìÿ ı?ÛÿY|ÂóÊ‹®ãNû[Yÿ?D
Oì.®Yû¿VÛØ ø•lü?HŠD	XH·ÿë[ÕZÖÿ‘ôp‹©cöşß¬m­SÿonfãÿAR,Çê¸ıøß¨fóÿÃ¤”ˆs­£2yıW­l¬SüçÊúÆ“'Øÿ şW³õßC¤ÇLK”{Ì^ŠkD‚3İvÉRÃëLşÆÆí·oü})|)"¡¼òøj—öTUïŠ¢ŒQáÆ#ÚvîC/—ã·
áßõ%:ãRâqeèz zÛÑêD¹{Ç“Qî™N&rïÕ¯'’ÌçfÑ,-0%Ç›o·Ÿÿ7kÕ'Ùüÿ)5~Üë˜2ÿCÇÇú«–Íÿ’2§ß‡vúıÙ:ûîJ‘Íè ï0â»+ÜcÚ·ZªVÔ71Œ)ŠW5‚)oœQ6QÄ;ÅŒI}Ä«D\ô0´(²sAO¼›ôàY?ÁÏJå"w“)y¿Ò”uŞuL™ÿ×7bóÿÆ“'ÙıO’²ù?›ÿg=ìâGç”óÉæ{…yÃ»2Í‹Á5;"€¿k€çÆéä³r>j¾•ƒ$ş†­ÂU Ÿˆ…—¬~ÄB²³¢Ï^¼ÚİÅëKàÃï!wïÔ(uûìÙ³àö™OfÕı¶š[ ùzz°ì®K‡ÖÏGÄÊZmm}mcmsíÉÈ¹³¿}ÔŞkï7¿ª
ÓëÃQ²V#J®ÎJ¿à>€ÛìsÏÃŸ+M	×?—:¦é›ğ ö7ª[5Ğÿ¶hÿ/ÓÿŸæ6`ÑµWÓĞvì3Ğ¹‚+ù™…ëpÆBQñµ3¬õ˜¢¢‚¿®ò)ÚZ)Ig[ÓÕ5ŒÙÑØTL‚¨l•€#?Àî˜GQÉdj©‚_-L~y:bxiuöˆùéÂ=½6ïpvı¼>Zi¨¢½ÉrÚí0´º”!
†¨¢Ç@õšR}Rƒgéğ;_Å©¶zeg¯PbM~ƒm_cç®38îíiPÂpw#Œë|já½cºĞÉòK¹ÇZnqï\¶®}÷Æ=‡uGq>à‘.ÑYV4Sü[TĞæÔ%ø¼dBÉ¡³]„T¿& Zß3ñŞœK$ş¬µôDñiÕğ[º¨âÆ‘‰ÀiwĞÎèö„ Às”rØ±>_C Ó‡Áø¬|ƒëˆ-±Œ€d‰•„kRÀ$:'Q)ÁŠCÏÖìÑ/Şà\a@ºbÖŸ#Ş¹·( Şç”(r7».ä‘ÜÃö½†múxG	úéÜôsM¼8&ú’åŞ
¹ü>w|=2üF‚îß7ÄEV/q 6qåLî‡AŒâèÅWe¶èVğ#|÷dôÒ2bx"DUûƒÙ%»}Ù2±İót×9·ºxUæŒî ë”à9#\G\r}0öGc¿\‰öU “!ï‰º¸ænÇß*b5‚œŸ{N¿MJ½juLÑÿĞİ/ğÿ«î„ûëÙùIoÛû/wöÛïsGtÛ*2ïˆHeĞ@ø¹·/Ûûí£í÷¹N{ûÕÑÎñ'¯[ÍãvçäõNódï~æ¼óêÏ~6ÎŒ7_/²,-"¥Şõ6Ç:¦xÿuôÿß|²µÿ‡H–}iÚ8Ÿ@ŸÇæNâ‘!‡“ÃÉ¹¦|nì³tß4ıFÇû×1Õş³¹Ø6)şßÖ“õÌÿçARfÿQí?‰7šf& Å›€Â(Ûq£ÏZ <“Àü“Ä‹µ %3Ş"Œ@3Ôt;ĞLĞïh
J…=G™ğ‹±©±;kR< ‡íıVç$¸@¨‘O¾!¨œ×?ÕÈµ.İgÊèƒÜÔSìa¸¢¿-@R5õL)éŒ¢L<yq‹¢®ÉY[I¶ı\MCSn	ŸKSı¿××#ş_[•ÍZ¦ÿ=DÊüµ¢hGıµ´ñğ³uŞj‰+‚•]·@5'åÍf 	ük-èÓ¯Õ£+×öº Ÿ|¸{ëuë,x™sNqO¡;€à÷Ü°­ŸÈ%^ÿ3	‡Øµ4wzkI°»ƒÔÔlË+>È‡¦u*dşùV?·hÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)K)éÿCüÀà  