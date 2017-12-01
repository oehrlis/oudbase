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

# move the oud config to the OUD_DATE/etc folder
if [ ! "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    DoMsg "Move ${OUD_BASE}/local/etc to ${OUD_DATA}/etc"
    mv ${ORACLE_BASE}/local/etc/* ${OUD_DATA}/etc
fi

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
‹ Õ!Z í}]w9²˜óq“sù”ä!9çœKkV¢Vü”dÍpLÏÒ"íÑ®¾®(Û;×öj[dKìÙÍínJÖØÚ“‡œ“Çä5¯ùMù÷7ä¤ª tıAR){f3¶Ùİ@¡P(
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
 Â5ßWú7yO!Rq­º0=ÕÓS]3=ÕCü¦Çèb€$·ÏD·w|'VlÄ3®yiÁp%”C#	4„mâ8;NxuC°?&öÆ"U+çÙÓHÀ„lr•…\î47„°Ğ»0?©ç£[Ã!I§:|.w˜Áîÿ8>ì•#!÷ñ·dyPÛR¿÷ÎQL}N[sé¾y8	¢;¤tj]%¥sà©e×S­\â£BËºâã,sK¬•Ÿ,T¿Q@daçré$†â"	|lùªÛkè¸ğIH:—Òó¡ƒ­†K)ğb(İ›¬iHE³nµ¨oâÁ2¤çÏ^ÒÑq5Å´äÈºÆÀIkDà?9…¤ñ|Š_G²•@5µ¼ôyNïëLÈºT¬g#}jvIúí*•g3£á³!“X(2VGâZ]ŞËá‰?©¬!QS+‰Tp2ºê•ü~’›Ïá›Œ7Cù˜GOba™Û#<·ñdÀ`msä'”èÓDŒÕ‰ÅÍ‹EN¶¬…ş5ª‡Ñ<E_fü±ı°Ğ:¦ÅÁx	xÿgµ¶±U©Vü¨m¬?b›ÅJ¤_yü‡®é¢å£:z‹â‚Û÷ÿúFÖÿ“zNw±ƒÿÑÌı_­¬oÖ¬cü—êææfÖÿ‘°ÿÚ°&o—†½Õôx²±‘ÿ§²U«Fú½²¾•Åÿyˆô˜t"
ÊÄÕ¡¥&öQ›áVÚöå?ÿ÷ÿCkPŸz†Û³~’{¿Öp4@ó¿Gä	Ô0~Z[øobX:uAËŒQ¸ÈİÔÆàñºÆÈôJ¬9À¸/ç}Í¥Y„SÁ:tšL¯ƒğ'Ø<¬ä`Gì­!8Xºğãàsh=ğÇ<´Ã»¢ï'Ä6Ñ­yCÜd  wÂ1j:&Ã!"©Á’¹û5¶Z£c‹¯D„vHæê¢§6Ô8pè¤]wf‚Vêš[’ŒiÏªÙÙ[c°Ş^£L/ÇĞa{ˆëU¾Nä‰-2&È0'¸C,fi­`ğŞ5•F”r¹UÉ4«X0Àˆ¤ƒkîİ´º2Y]dYãqV´"òq;Û]ÚSëÎ:	×Õï»H"t=µlXá˜Ğa’úš&¡Œ4d­A×_áf¼ÓÍ Q.²{Ê™Mç‚™¯\Ë÷M`\Êçssfä½²kÙãìõŞ?ÿ·ÿX!-ŠªƒHù†„¦rG†7:5]hØ¡…Yy¿Ñ[Ë°ÙLÏ».w|×ô»}ª_„š1ƒqÒ©{ìk~z–££Æ	‡ác´G‘î
ƒÁ;nñe"Z«<×I-CW#‘e°[Kì DÒWª(„NM3€|0ÖG@,ª‡÷ ú—¿ü…q[ßï\ıoeö×bİg¾Çˆ0Õ²×‡±Ú+Ç+cÅ~«Õbuı¤ºQ¯}]ßüš¼iµ{‰ŠwWJUq)q´¯™XXÜ(›€Ş*ûş>eO•#½ÏŞ³‰ğ”°‚š-ğBßĞÎ¾ÎïUÂ6<{?±¢)X$\d¤„mÓÀÅï¶RÒMÕS EhªBScûÍ%¶‡S	y™\‰‡*›PÕ´¤¹Ô1¼ğ`}¸/4¥-ì¹HC)Y‘NYÁiıBiZ=^TLª‚"'%W³ è6Oªñ»(îAÃğ”[J$3T,¸ÔsÎ|ŒP$i"¶Y(…½i„HYŒ{åDBEig"„×<Meÿ¤a+(R±œ“{C	Ø4µîÑÀ¦ÔM!^›Ì?M®sâÇğšgº|#*81Ğ Ì¹Ü:g™ÒY(’…¶º*½‚>BÜ€ÏQÀ/ª`)A¹âéêª±<†±àµPs"C¶6\y„Ò½äÒ«8¥­²©§ğs›ŸKg 2§€oo¢%À9å<<Ğ»#‚j§'x¨²$Å4ˆ›Ã4{‰¢4Å–‹öâ7õÚúgàÛWtÇÉ™~E°C¸ç
Ÿ³9ÜQ¸+D<æ¤F,”]rÙXl»Û•ÕCÙÉ²)„Jh¢€nRÑ@$%ã©‡›Ğ\5²]€²ŒW—ÌK<–ü‹Ü55iS¸…§3# ”0IÉù·ù¹ú`a$Ç9
Üğt…8™©×¼Ğ;“Qn‘eßÌÙµ¢@5·©jR·$—˜ÂJmô‡ëâV8_Xv<î£@#[åD˜êö«|Ã·“Ô7|ûFy#bíŠ­œfòÎ¡,§YÁråşŠïşÉ×rGR>£ØÀ:-ç SÊ9ß„é‡ƒj<•÷]à¼ROÍIõ‡èÕ¯=;ç®ãc\ß^ÚkÀ(
 )3²`dX>ˆÔ'GŒë"_ 3p¸ÀTÛ~×RĞ!´X]3’åjàáåŞ0á»h8âš<ŞizÓÃ"jÁlWÓbºÅ”ÂŠœ^‰0\
(qN&“±áTÉÈAÇ$J¢7ƒ`#2ÿ<“h	ïÖN^¤Ú ÄÁ¨ÈÏ7GÌ8óÍ`^Âa¤¯ñ!(©)ï–â|	kyº¹Y ?=%âË¢†bâïS«°Õ`Q!Â]¦pûªª}Ü7[Í‹Mx¶ÌmN!Ù”K[¸\p{VşÆW|‰M½ï8¯;Dî<~]2±ÎãÇâ0©"­›n·où&YÒr¹ç×Á¹UiÈAMmÀW{ÁSèr¤jŸ\-Zo`G{c2Ò9oÄ‡+°ªŠL1•Q£¯1:¤{è+34.L¼~ÆN)¨¯ù¦\×™r]7°.í‡ká]^ÜÖ«®Ä Æ3¡ì›t¿`òbĞXöX×£«ü?
€¶_¶‘ÛD%†\S/±ƒ ‚ô—0“_Ë¤ß%­'}>Ğ1ñô+O] ó¨gOã+¯dêhè¢ÓÜš\­	Ï{åÊÄº1ÖÈˆöqÀ=âİ#A$¥Ld“ Ô›º§”Ë}âQâ#ék™\´`^|<'Ø§èÌXJĞ›?q«…áZè„&¬Â\îJØíhÙåñÖ=qº´¾Âòµ‡E¨8\ÚYòªÕ`T–¨Aâ¨{¤åa 5S1˜$B¸vÕú”,Î´¸ä‰Ö9€é,¾^cü~9şıÄi/„u	7[HsqD±8A‘C#8l¨öğ„8¼Š™´¡£Å›ŞĞÕŞĞ÷OĞBÏ£Kò8É½Ûu²|†„¬KÒq( sÔL¢Ÿ‚2W’1Õs4KF XXñ\wG vç¦ÆØí\¥‹ã)T½4?ñQİR–/ØA(İƒz¹Âh%ĞõÔ.¦İ4@ßÓØàQ¿h•ØÃ£Ç;);4iD‹ªÓkÜia+båÅÀü@áæÕùª@Pµ½’.íı×A€ÛèHkÒ¼<¢cïä“K©“åU¢Ôb²Ş.ÏU«&¾5¶Ôí9§A”|ŒS[`ß£Ø¦"d¿41òª“ŒŒ]6ÔÇûT­š6KìU _ eY‰º®¢ ³‹¤Q¦º6É‰èáÜ+E›œ
h^Ô´5õx¾¦° ï°®TêRàcšHqÂnVwŒ;˜<ŞoPi¢N#&ªP»æë¨ÅœÊÌ!®ìê€²äòM7Ğ)«=FVÉŸ^¹tH¾¡ĞI…8¤'Â¡£á@è–ƒ·±2±q¬ìĞØLoµ¡ĞhÄB-ÏkT-¡§¿õŒÉ­Ö'†ªTÆÖ…J‘_T ğÌ+Åj¥zÆäJµk¦R42œÃª€İ¦Vyhû,©}wªT°BR™]=ş2Ÿa“V»­ÄL¸5¶pO=ôîè)Æ¥YĞS³«"W˜4Àú! åWªlğÀJ»7îúå³áUµVª•ª¥õR;‚‹³W6ß5­t4GM¢Z…µÒ:G!~ıFZ»ËcÏ¥°óå{ÕÒ×¥ÊIuc#RæxaGp£’9#ššškRC-UB'ì Å1K‘ĞÚZH›º"è)ı*n1Iâ…IS—Ø£ÈŞ|õE´öš;û	48ÚPûµün¤§OR­”3$©c%(‰nŒJèq8Şêsè+ğX ¬á)…_P§ÉNPQ²#ºÊc]%€Ì½r}2 †Äi‘W>˜^9^;fÚuf«™¯C…ÿux)”gÉe°c›è¯a£àDmşÔ¹4I×NÖ³9óÑ›o§«‡£ul(ˆŠˆ4¨ÆBÕÄ¼\Z°«Äyeo\ÀÒ•æ‡=9 y¤%.‡Ú‘u€j+:í Öãò*˜õãÉğdnÒjâq|ÂFS¡ ‡Ê'
ÓÁáÁô)xEMÓ¢ec
ĞÀø1	˜èÅ$Ê‰¼Šöë)‘…«¦83—‹,<#`~ ô¼mÑ7Ş>nwÂe¿¼ÏhMcœFB>ç`İä6XµKEäOa)QEw¬÷B#÷KõMnEz’­Éèöã!ÜÉmˆwlíckGqWì¢Jâ›ìÏ†¸‘D«!0ñ°Daˆ¿òLı;™ä^J•X“º¢‹I&ß0’HD•á7².÷
¿šıÛ“+F·THçç@Wà¨9#P~¼9„™ÂŒ›¦ğ.Æ+>CÀ-#0~›´Ê†
Ò¾÷Üy3ÎÍ"¾nºáğ á‚‹‰ÀÉ„ÀS(‚àÇÖÑr¹#[bÌîğj„xi9©ñzõäe4|›$¬ØçAV‰NÊO;—§ãs¤j‹hõë#Ä³"º ¼¥)î]LJãEúÜË\D*˜!Ş¾¤Y—Ñ2Üû¿0İ÷+òÂÖ¾9•”[[iP€jR­cì©”W.Ôs¹Uö¶ıüşÎ90/„’~ík™g-`qo|:´xTz{‹òe(T ÂíZ]Ü­ÂûHV¡Y›¿ê±±MşYĞÍÈ)Sf^cÒÓ©Vª”ØâRç”öÂ˜bF×R[E˜á³§ˆ`wuuU2`ÉqÏË¢:¯¼»³İŞï´‹ ôèg·<ÿ›ô9X¢¤ÛŸÿ«nnV³ó_‘"ş,©còù¯ÊVuó	õm½ºµ±Aç¿àßìü×C$qÿûÅ¼¯_Øğ?Ó+àS/wxÿ<¯×KäEğÒÿ…Ôu2<¥ío<-IÅía®‹Ÿ÷--IÂÇ/{_?_‚»rçtû.kÛ7>ğxİ<j¼Æ ¿sG\éTËïÆ¿×¯¿»*³·‘0ïÙ²ÌÙíõõ+doÂ/§Åu,|=ĞbÍÈ:MŒd¥dèF3Dƒ{+yû‰y•ƒt`hës:§ú­Â˜ÑÕ˜*ò5”†×rGI¿Î—b0§Ô
³ƒšC
ÎÚ^Nè—³µH1Ê·vâ×
Ë›„½X1@ûOd«H ìß1 Å…×¸‚™?á~ŒbàùuÙ'@qÑ¦”¹pÌ	ëÏnRÇ—¤®j,ÓÏ"IXùöò$˜¼D.fpAãFy-õ>““áyñ%k&G†×LP|[^ÇärW¹l™Øf9ø: ¯yu8ç•¯¸ÏÜ¬åÂÁÏoµ\8vâ¹à-ä
²Y¾1faYƒÔLÁˆPrw'çæÃ-Ì2A#±§î4	œ–I¡G AR î»“lw·yÜnl³ğ9LdŸèLy©ÔXÆ=VZÖì:Çmcß	2$ƒ9¾»ÀÀwƒW•Íˆì0F—VÉvƒv XdW‚<a÷ƒ6h”oei;‚b›•É½Sæö´°¸y»âd9SŠ»æèv [VÅ»ŒĞÔ&A\ZNcùÒJ¼PWæ7–Éd¥T{ÑXÖlcÅ¢4ŒñÛñ	^’UíÈÅ¢ï‚Ìm å"Ê^kŸå»v#ÜŸŞ#°n^|—(¤cho<ü¼ÈÀGÀah¸×­£)°­&Ú ±H0Å‹´ƒój§%¶rÄ äÜl:(´á¤4fiEş,LnÎòmSYZx
Ï/-®)öŸÊzm+ÿmk3³ÿ<Hâñ7P qU^e‘x´h»À5ñ!¸w_®+/;ÁÛñ6¼NßnŠ·ÑkCro¥¨2–ã»ˆu¼¦—½Ôñæ˜:^ç’	šYSò1ÇùÖ1müÇíÿ››O²ñÿ	­.º»ìÿ ı?ÛÿY|ÂóÊ‹®ãNû[Yÿ?D
Oì.®Yû¿VÛØ ø•lü?HŠD	XH·ÿë[ÕZÖÿ‘ôp‹©cöşß¬m­SÿonfãÿAR,Çê¸ıøß¨fóÿÃ¤”ˆs­£2yıW­l¬‹øÏO6`ÿƒú_ÍÖ‘3=.Qî1{)®	ÎtÛ=&/H¯3ùg·Ü¾ñ÷¥ğ¥ˆ„òÊã{ª]ÚSU½3(Š2F…0hÛ¹k½\ß*„×—èŒK‰Ç•¡ëènG«wåîOF¹;db8™È½W¿H2Ÿ›E³´À”?l¾uÜ~şß¬UŸdóÿC¤Ôøqs¬cÊüëÿ­Z6ÿ?HÊœ~Úé÷gëì»+DZ4£ƒH¼Ãˆï®p}hÜj©ZyPÜÄ0¦(^Õ¦¼urFØtzFï3~$õ¯qalĞÃĞ¢pÈÎ=ñllÒƒgı?+•‹ÜM¦äıJSR8Öy×1eş_ßˆÍÿOd÷?=HÊæÿlşŸõ°ˆS~Ì'›ïæïÊ4/×ìl<ˆ >üV¬§“ÏÊù¨ùV’ø¶
ÿU|"^²úÉÎŠ>{ñjw¯/¿‡Ü½S£Ôí³gÏ‚Û;dv<™U{öÛjnäëèÁ²».Z7>+kµµõµµÍµ'w"çÎşöQ{¯½ÜüR¨*L¯GÉZ(¹:+ı‚û nG°Ï=®4%\ÿ\ê˜¦ÿmÂƒØÿİ¨nÕ@ÿÛ¢ı¿Lÿ[|šÛ€E×^MCÛ±Ï@ç
®lägz¬ÃEÅgÔÎ°vÔcŠŠv
Jüº
È§hk¥$mMW×0fGDcS52	¢²UZŒ@ü »cE%“yª¥
~Q´0ùåè4Šá¥ÕÙc<> æ§÷ôÚ¼kÀqØõòú<ji¤¡Šö&Ëi´ÃĞêRj„(¢Š ÕkJeôIZxœ¥Ãï|§ZØ
è•½B‰5ù´}»Ìà¸·§A	Ãİ0®ó©y†÷~ŒéB'Ë/åk¹Å½?JpÙºöİ÷ÖÅù€GºDgYÑLño9RA›S—àó’	$w†ÎvRyüš h}ÏÄ{s.‘ø³ÖÒÅ§UÃoéR ŠG&§MÜ@;£ÛCvz‚ ÏQ
ÈaÇú|LOã³ò®#¶Ä2’%V®I“èœD¥+=[³G[¼x?‚s…èŠYxçŞ¢ xŸS¢È5Şìv¸ G6roÛ÷¶éã=%è§sÓÏ5ñâ˜èK–{+äòûÜñõÈlğ	r¸ßY½ÄØpÄ•3¹7PY0Š£_•qØ¢[Áğİ“ÑKËˆá‰Uíf—xîöeËÄvoÌÓ]çÜêâU9˜3º¬S‚çŒTpqÉõÁØıp%ÚWNB„¼'êâš»1|«ˆÕr~î9ı6)õ¨9Ö1EÿCw¿Àÿ¯ºîÿ­gç?$½mï¿ÜÙo¿ÏÑmO ¨È¼#"•5@áÿåŞ¾lï·v¶ßç:ííWG;Ç?œ¼:l5Û“×;Í“½ø™óÎ«C<ûÙ83Ş|½È²´ˆ”z×Ûë˜6şám8ş×ÑÿóÉÖz6ş"Yö¥iãü}}›;‰D†N'çšğ¹±ÏÒ}Óôï_ÇTûÏæV`ÿÙ¤ø[OÖ3ÿŸI™ıGµÿ$Şhš™€o
£lÇ>k<òL~ óO,Ö”Ìx‹0ÍPÓ=ì@3A¿£)(öeÂ/Æ¤ÆîX¬!Hñ h¶÷[“à¡F>ù† r^7şT#×ºt{)£rSO±‡áŠş:¶ IÕÔ3¥¤3Š<2ñäÅ-Šº&gm	$Ù2ôs5M¹%|.uLõÿ^_ømU6k™ş÷)ó×Š¢õ×ÒÆÃÏÖy«%®VvİÕœ”7›$ğ¯µ O¿V®\HØë6€|ş9òá<8îy®×­³àeÎ9Å=…î €SÜsÃ¶~"—xıÌ$b×nĞÜé­%ÁîBş9^<RSw°-¯ø šLÔ©ùç[AşÜ¢)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,¥¤ÿõ¾÷ë  