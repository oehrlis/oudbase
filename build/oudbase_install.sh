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
‹ €ç8Z í}]w9²˜óq“sù”ä!9çœKqV¢VüÔ×gè]Z¤=ÚÕ×eûÎµ½º-²%öˆìæv7%klíÉCÎÉcòš×ü¦ü‚ûòRU ºş )™’=3Ûìn P(
…B¡pfÙ•'œªÕêöæ&£·ø¿ÕúÿW$V[¯Wkõíj­ÆàÏæÆÖ¶ùĞˆašx¾á*cNÍÙÎÏ§|íşı™¤3ègÒ?…æù¯ì éı_ßØÜªcÿ×ê›ëëÕMèÿõÚöV} \béWŞÿK¿© œŞ ·ÄJ‹K ­°Ûo°ÂÂÁ¸Ö•Ñ·<Öz±ÆM<Ë6=µÍ+sèŒG¦í³ß²îd<v\Ÿ­<kw‹P¦k˜¦kZïg²ú7kìëÚf½¾æN..ÖX÷Úò2İ¡a÷ô12Ë<5˜6ààckâW|ìúæ¹a³Csà-¶â˜^‘yô®ìĞ»?ø‚ å3‚Ò¾å¥{†çïûÂì?»áäo~X·š?ğ,Çæ•åYË"?ğlGwìx&‡ôx†u{®5ö™ï°ş˜Ì²¡ivÏd¼…Ìğ˜kú›õœ¾‰”p|Ó“Øœ =~ËŞ°‰göÙ¹ã2Ó¾²\Ç¦N…Î8Ÿ¼j— jøDxŸC·Bmlàûc¯Q©\@ÎÉR§Â)æ¡ˆ7Ş­@ö=p•ãŞ4à±Z+W¿)ÃL¶Å‰ÂØ®mù–1dW¦‹d„<µz¹VÃ<Û2O«ÿ#H!¤!0£	¿0³c3ç9Z~€ÁYb;P©3²~2|@ìS çÌ÷4Ø_¶OONÛÍÂå©QÊÛø8ôÊ{‘¿%:vÛøéxä\ÆÈdè³WÆpbzŸĞ Ü«Îqw÷ğ 	½™k¶:ífşäøe'ÏæLKÀ»ÆÙĞdCç‚[ğÃM, ûÙa·ÓÌ?oíuïxã† áhêîïœ´ö;ÍÂ
r¸r†ªÅÜÉşÑi{÷¸³srxüC3_ñGã<½|¾»µ>hn+zñr¡ÏuOZÇ'§ßwZíÎq3OO(èjè¶Â¥ö[¶òŠs8¼ä»-Ò˜e…Õ|n¿µ»×j·;İnxúkÀ€,÷¹Îññáq³šS9âÓ{’ƒ{>±{ÈTŸÂÜbGß¹À‹½ôŒs¥È>DekÛòÆCã†gXpíÈNSÓ«¶³ï]°üîÁóCÖà¯E;ùMipå²’Å¾ÃÑ½{ <q°ÓyÊJmö¨ıöüş‘ÿ>‚Ñ~í¸ıçÀüOÙ»¤J+’˜*g+>N#˜Üá)¥øURñ„‘’RÜM*Ş˜½Kš~\s<´z$—R (í“dß+dßëÙÍ¶åš=œ$Ø¾aCkÜp‰¤{oØX¼"Y’R:Ö-˜àLB|JN*·ç\x‚	şÃŞá”·<ŸuÎŞÀËÚ-+]ø¬ÊŞ}‹ó»“ÍÜš†İ²û?±|¯ğ¡~KŸÍ!Ìµ2_Dâ%—¯2znånsŸë‡Ö>g,.£|kD
ËhüPC¨¾RÌ} vî½<I²öUcõ6‰	)®k\š4[÷ƒ}ÁÎLø§ÏiÛy$'P· v%C f™Ì¶@'ÛIÂwÁäôIX¾ÈØÉî~çøhÿ&–>¨%,ÿ»¯~(}5*}Õ?ıêûÆWû¯ºùâ·ß*EÓ‹Ú3
Óì¥ïQïáŸ°V­Ş|^Í°Ê¿kÊ	I2=£€<MhÈÁ·yÖdBˆ™UªÓòR½ƒùCœ€påÙGß4YÉPÆcPRWÓÁÙ`HÉŸŞÀ:÷ƒ§ë{Â«ıàK¸ö­Š»¶,D+òrfë[8œ–Uii¼µ}Ç6ã²iİöôiR›¾0ê'#9?ñB>"RP)bQÑMØdb¤Æ÷–ÿ ÊÑ¬‰/AyÔ"¹†â8È^-s.JW˜icÚ³*®jJv¨½Íd; Åè2{KâfŒœ‰Mš¸á^Lp‰ì•Y×„¦5ï=ÇE½ƒAï•Õ*êóV!³œÚ‹óÂßœ	_ÕJHm Mßv|êT§3ZB´İ2¨
[;{@»9}ÖêF„Y+£z<Ó'ÀÚKãÊ°†¨=jí©ÕfAŞq&Ã>AğIoÀW|Ø.ìw 3tŒ>{[øğı!°G¥,‘TÁ­Ïlo×Ù¾ÃççĞ0³¯–ß˜Y¾ãº@!D§OZ„^|fkxqê]wbÛ¨¿›PÏ[W¿¸¾§¨è‰P×gAİ·<4«¸–­rô<¼áh¤›@T5Ø¶ÉEâ÷Ğ¡)Zm‰BËX(‹!	Ù6ç¤'´c…†8¬#MÑª ìhy¤ÒM)ã³)^§
ä÷¨¢
qË†Ÿ#¾ÈRğÿæ›bd¥òG4’]¶m0ô÷1:Ú0ııL±óÒ¾´k›7=Eß+afi(¹	§csä\Zm¢BÍÇ|P4TNÜ‘²ş´Ò7¯*öd8T'|„gN˜ÇŸ/Æ‚Á!Âùéö>€Æy œÀ¤\`sqaåŞä¤ê"³qÕEW[8ÅÏ1[TÒÅ(_NÊWé´ee½¬+Ï-ÆrîPq€>Í8éè²áËoX©ù¬"¨ÕZ«BmX×‡“bÈÎ•Yaå¥M8õ”Èî{‹ÑQÇºÀ8'R¬çÄ²='t94èÁO9è[nÀAàeùŸ§BePãJ®ıÆÂ_Pÿa¿ı-vÓ5Ë+6­ù+i.è.5µBemÚ#ÅÔ9N8ÎıaYnß°>ÉÆ­p¿ïc–×¶QÍãZ:—Ò¨®ØNAp‚"C ‚N¹ˆÙÍd½	hU6™ÓƒÍ”¼ ×½p¼]˜¾3¶ÕË]‡Nhb6"…Ç†Ìà£İ‰¯;Di6¸²íÆNÃEm/X~pEŞ¨Š,ğ%·ÌU¡{UŒèÃÊ7«ÈöoTFF6=<Ò¼Ğæª6æãv´”?Êªi,%¯[dÇ£½İÖ	ñcXuŠ:W&Cù½llVÕ‰‚ÖB´ĞÛ‡2#&ã"$ˆmÑ±¨ªón®¬	˜3{Æ°"vë¹”È³‚ZH	ö”#Fõok9ÌÄíì…ßC]R*˜‰“ LÄ®3¢G°é‡ Ò
H£İ&‹‘ óP£¤„Iø¦ˆ˜p2RNzÊÄ;Eü„ØL“?Á$qm¹®0O”ûrË"	øÏF)Ÿhí½Í%p¯,¦¾ …G¯Û¢!·œL¿Sd<ÿ´Yhc=Ş9bŒ(1[*æ e#Ú_”Ás"g©Ä·mKç®e?İÀÛ) }ú}ä:cÓõ-ÓCLá§QØö Ï_«mb‰…Œ¾`˜ú©ÎTsq86‹£~w.ß¨iÙbÛ6`A|’ÙèÃ˜r¾›~¸Ÿ]²Ø²Wùs¡Rª,«|¥~t`rzfô.!/Ûms“ôh2ô­1î ¢ƒC ¢rèÀ®°FğÍ÷>ªÑ…Ê‡ƒo½Ê[»Â*ßŞ¦Àq¤Ÿ
øÏ"WC˜˜bµDøéˆOBÚ`ãÛKbs¥kºW°ªAÆëª}²rë
À¦Ç–cYÄÖ£Ù×ê.J¢ô,K´ºãF/]†U£ê–èà½pA62ÍO|!–Ã¥Œ…©½vëˆşê©N.VÀ>Xb½Ğzı§ÓCÜX1®/Ùò³Î‹İƒÇİfş­]z+¤çô3ÿíî‹ƒÃãÎLÍÚ·|AÓÜÄ=˜û+«ü¹Õï»Ğ”«…:¾zûİ2Ö²üöi…}€F­Öùëo¼/
8ÕoÙ-n| %	½Ó{œ	WmÔê¼>² w6k1]~vÅ»©FT’ê¼>+~š…Ôjæ§ïçe½³°Ş!% ÿRFTƒ†—Ë0b3‚—Ğ#8úuÏüóBK,;s"{YáèøV{÷@zRg1£?²ì9¦±øÜ•ØW©s˜Ö¤´nM4[ß£W7êúÄ'z—ËĞÖ‰
À•¡ã¡‘ÿV0î-«h~A·’×·Ùoş
¼~€† !Éë›õDf¿ƒ×§o]oÖ5ÖÅöé[ÓÁztëÇÒçöøÔ“ôÿå.\ŸÅÿw}£Jş¿ğk{³^­’ÿoµ–ùÿ>FÊü?“ÿo0à~)ş¿Â	Ô€IRnÏ¨S´÷Kwııºÿ?ëom=ZĞ²}×éO@õµ[`ŞC@ŞØìYç7¡6aÑ»ä‹uşe;/ÔøÎnÀêÃû+rá}Dİoad…Opá¹ŠvŸ²Òˆ}§ô0¼šße÷SüuçwÖã¼’™Mİ)ñRJÇš”Ş7¬!+òäâ™ì£úÈ²ÌG6ó‘e™læ#›ùÈ
ùø°S¼rš§N|™‡ìø™¯ê}UäÇù9¼
3¿¾_˜_dí¼jÎôâKw äõ¨-síû®]°s ¼»_ıÖØƒ¹èV£Cnzá£×Mq«AFÅTX‘zÌûM·^åíZå-«\Ì¿o!ş{¿x/!ö"}› ª…*¶”Àf8úÆY¢]$R0b„QfÎÉ`Z€zl‰õ\W³†¾·v“¡Ø£3
6|v•±'NZÏšñŠ29N÷v»¸yÍ=®ØòŸ—–Ã#G{0¯ÁäĞ(Æç"A†×­ãôÑ5!DˆBÄ{›Ğö8ÏA÷83€)}‹!¦íÖIë¶²ŠÇ&ÂR[x‹†	×RÒ)í@ÁŠ-¡æ¤½öwb4 :ióBB,èûV^}[y»ß"åÕBåm­²\›¦.¢ŠÇ]¤µ½NgE–æ_O<s[‹ä—‹ã
¸È¢ºË–×–üWbßå'AlóšÄ¹eG:(xèwF¯o	î[[ ÖÛÍgLß”Œ,Oêc.-Ï 8cæ +¾‡Åq‹§í”Â)lo
²Ğ»P‚B@^päIY&®ŒAÏ5ÏÙGfÊá–ç¯>Ò3”ÑÇ½(;¸9â•=òÿ+ÃÊ,Ò–;òB¥RoQ_†²èKÀ^÷
 MÆkÌs&nÏTu¶rÈ¢Š¼JÔîäg]Ë+ú^lèõƒ9%œs/á%+¥SË?SR{÷X·Khh¥·#4q/S~ş*ø–AYÒrkâE¼<õ|•äf%™[ô…Ğ=vŸKÓ~%êZ™tîå7ogCÃ¾l¼{·\ŒI$,)zµ·*Ì¢n²{CĞÁŸ¹Ğ³ƒ&úfioØë\—Y®¼Í¯½ÍWb *Ëa
<u+F ´sƒïÌĞÜOdgÜ¨İr…^Ş½íê)Ò!ä9n·¶:b¬µs¸¿ßB]_,ˆvn+biØ‡Á\*Ï§FĞ‰|šËcn.ï$4Ñ7K¥=æCT È°È¦Pó´mÜ‹ùòï¾š,Ãz	 ÍK_˜È5"E(ûŒ®~#p¿èHÃód‡¡täİÊ½ãÖÏB (ñ¨Hó„Æ¡6¯3/ãóß2Å¡ÜĞç.«“ûê¤ø8 ïYÉ#«Êáq£¨g©gOóÈ8á$.‘%WVèÇïjE]>$šÏÓ»}~ºx“®ìÎa™}
Œmy³5¿‡¯YÛ?aÆê;×ö¨Ÿ²ù×Œº3XQš.¬5ûå|`,Q¼¦iì¢³ˆ‡gÌm’ö'&yúPŸó†ùø¾´Q­ªËÿXçêÂU(b×ô)‘ R$â‰©š³àÿÂü1;IÿOdâÉø³øn®o®şŸµõmôÿ¬olfşŸ‘2ÿÏÏäÿ¸_Šÿ'oĞ¯×ÿs«ÿÏğÿü¦\İÖòì?â.!ÑÚC*
]Wî"ôûœlÉğ\ş.ˆìGï3‡Ò4h?‡Òj¹ö³.û¨n¥'?a‹^îíÍİ Ş(ÙgÏ¸h:¹›¹?u:GÍ»ÀÀ&£3Ğ¼×¦yIƒõÒ4Ç95ctlæK%ù{<ù‘ÿ°{>4.2ÚŸ³­Ï¾CVıåûÒ’2ÂTôVÙ=Ø9îìwNZ{™Oî=¸ö‹òÉÍâÖf>¹TGæ“›ùäf>¹¥/É'w.—ÜÌ)7sÊ½ŸS®ĞíâN¹™3íp™3mæLû³r¦]tœÌ/Ğ‘ÖoXQ£ón´>,ÈL•èŒúN¶‹k™yÆ3f^£™×èÏØkTlÏÍé5ÊãıËB>ÎåÔbOûªOWXlàœ!ZÅ•GeÆÓ2ÉøÆz½È°†‡vÌÉĞa›Ø#×¦yÉl2Åç:¯O_w::8Tl./óÅÜá^;ü k€0ãm©ğw n‹E*ş¬µó§—G§İp¯ô*…BL+Å¾Â¥Dw"`=¬bZá…„ÂzµcmÆN¢†êHxV|;nÍÂ¬8q/ÄÎª€¬bHõ&eŞÃìSı8uçÍ/Ö9\Ì#ûÛ€ÑÙÇÀƒÀG!…ª‹î«,8‰œ2c\;Q¸7«"µB¼ñéulx„t%ù²
xdÇ“;oÂÅT
£[\ÃÌÑ†yz¶ğAÇE)û4§»¨ê*Ê’úN,×1ôğcŸ[a7Î± P/R2Äº…•~êÏC£Šê‡Ëa–ı‹Ÿø2oçğà9{šÖêM“Aòå¸w‡¶E‹.¢qx§	5í­¦ÜPC¡i£ÇC"Ï.TyœôÑ®!EĞÏXjLÓà¥xè&}7¶úitN¢²ğ8ÔŠxÏïmœîiü,qPßÁ©x.‡bQË½Šg;Çlşé¬—Øä9ü…#êvkâ;xUNÏ€4¥‹nZö˜3ì£¿ôC]ƒ¦ùOñá™ügù'4Q\…h¨ÚÇ<uIµNÓIânäîˆ•Üä‘8{g&½Ú„sgºşŠyQ+H	HS7vä?rõèe®ŞwHŸÛÕö‹Lèü[>Ì¬RÇtÿïju£º…şßµ­ÚÖúæFUkë[ë[™ÿ÷£¤¿ùÿöÉ¿|òdßè±Ã.û)šğİ“¿…?uøóá<ÿ‹3ÈÖÉÉ1ÿE%şüù‘,ÿJ¼ÿwOüèáec<šå¡áùè Œkù¥£®€ñ¯ñ¯'Oşæ=g@—xC¦ÿgEŞ¿áyÿs$/ú0ŸÍ]»o¾òä¿–şÓ?bîÿõ?şç¿ÇkÂh_fÒnz :¦ÿúúöFtüo¬¯gãÿ1Rvşãóœÿ<ñÎg?¸qŠNââ9S^xÜˆ^'šyˆS Õø)>¬.ÇjœÚBØÀ<>À÷qÑàYØ->7ƒPÎ¾Ó»4İÄ"ôÂôOªGè3!ßŸ‚¾òİ›ExÁ'CÚ3×ìÆ™ ·İ×zèære¸:îx¸òZ=Ë/CçA‹mÓ…ş#‡ì†AóÁ>Ş™:v@Yå®‰ûE°®~V†ˆ¬KúŠ¡ãÎÿh`¸æ´lVFÑ|:vì£2¯ód 6³†Cq³@‚ÉOÅ7¾<¤ëÈ¤W’ZóÉ@ğ%ß¸ swkoïtçe÷äp÷é>¥2d¡\GGZ”B)ò¦RiBÅ"¹qğ$¶u°~}m†æÅ5Ì§ˆû+“jµaÅ¡¼¦ô	’Ú= ‚P Œ†CÒŞ ŠkÁnÙš0ŒN\qe‘„¦m—ª¨{©øId*–"#eƒÉØ Ú­@ËÿÙ0yFµWĞ7(NÁY u"VFV¿?4¯×TA?ß-Áß4–%xl½j©ˆjğ~ff±”U:ó„]i}Óµ¡®øñ¨´:C‰›5!'·6ˆ]÷dx¦ß«DMãSÁB!ÃÚÉ.äAzñ8
¹E[•-_Û”>a}—8ÈŸ>È™¹2{¿
„Æığ.±®éKRƒ¢CQQ!”Lèdä¾1ƒ»ë¹ì\\Ê	ñ÷‡´3/ã¢å{e¼4·
|¢ p¡‡ÜmNñ1ÁAÛ8 +Ãšgïp§µ×TapfÓ<§—`R»¶L˜¸s–@LEn¢Õqã.$¡g†"—šš96şJùp¬‡dÁ',·
:c\¢ÿt	TiwËJèŒÀÎCÿÀLª _·<VT¤É[Té/^ P©,@u ‰ÕŠ1¥0‘”o¾D)	(¿¥yp«L<·B‚TÇ’^©ŠŠk¢1Íƒ¢+G,Òhä‹ä^.}‘Hélw;’Ô é?L÷÷=£?*†”„ŞVèeœj9~â2œŞÉ«E ÕŞ=îìœÿpJ^|À¾òFÒp³n|Št	4ıÖıbR*C:ñïä:ÔÖ0ÄUQáƒ^ä–Üe¤q|!RvÑîÏ¾ÃF®¡Ÿœü€¸ûA“ßAí=:`§lÍ÷foBhT„DPğğåñN§›râ'mË}á.×¼sÅ&IÄù/¥üƒ;dk8%nx›rºãç‚|raxÉ;Ì}\ËµN¾G¯¿sËõ|¥¼ÿóÚ-Ğ5ºåË‹˜E'Â`š—àpÒé¶^uÚ§8ÿ¹U\É‚{Ã\ñ-LK€Ğ3‡ä–rU2Tw;¨ØÉuMµŠK…Ü&YÅ|Hsô-©
<TG‘'áuD%—P#ä“4{†½«ˆê`e†M1R-ÖÑA%WÉ$uİ8Îe“Áñ™}:4é4å®²HÑ@Õ>;WœX%)só8G¸$Å›7Ú-'ÖääÈÎéÛ¬ (<€#ÊwwNşDcQ+9NÊ²‹0ØÀÌbÆşM8†ò1gĞ¸hä5ø8=9Bºj~µšÛoÊò7"cÑ4ÓÂI‡!ı‰ĞÉ êOP%¤Oñ…>›åéö©>Ñ
gˆu‘XqH°I@g ŞœùŞ‰qJ»ó¼õrïDu©Idu‰)x5kU)¬M^Í¢%Á@^¦p_‚?~„ïîÌsiüvw^»/Ÿ-šÇˆ¿Ì‰]4Ï×{èŒ+Š¨ÄJã¿%åò$iK”ßk!’ÉÜ­ñß 5ĞÁ»€UCµóƒN¦*«Ã>¥Ájcxz™0©ğPLt¼	:”¨%5?™)Í‹€â:ú½
±£+ühÒ¬¬B¬İª«œqûR#âÇ»ÑßK\Vÿ!ºóFá½ú"ˆê	‹œcÆÒ[0bÔ-Di¥‹2*&ñ¡O^â1·•T/şeÕ‹¾èş®<İÅ³?µ<zûëCOõùO*F:	ªåÉxù[î¸ÇŸÑ	Şœ[Êl+5Áˆç«:x%¬Æâ
;œì4»{|*)ç\*JNÌÕTÉøûßën‡ò½4€ò	£‘B¢şˆD¡`O/_ò¬!ğ’°$¢d‡™£iyLØ¿éT­
‚oÖœ¢½'ÏA¡œØ«* å“ì§±nTMe+nÈó/˜[pj¡ïõ•BHüb¬4ïsƒ!ö½S*-`Sêíra ÊğªãÙ÷Ú­#v„’”)U`LêÄ¬]=¯ÈzÚíîÅ²·È[=1;Åû8V\ÔE1Yà¸sÍ¾ˆ>~ˆª@Œã²XÃB^ƒÊ,V¹LÛÏ[ VØÚ»JcNgÌÄ$£2)(vK7ääÅ¤RÁ´"o§%E )GN“É´¨™„§OO(8«X³&î8`Z’Ëtg`+ûÈ´ó©æGaº@^ÈPø`İ6}å¾ƒbäıÕãÀP¨ÜàºpìZ¶NŒÎØW¥ZÕƒ¿·ğ¯Úşí½µó	]]•ğR
Ó„oxMàçd‚ßDïÛ¤j’r+ae‰¯GaÑ):&Ì.Äz‹¢ãxc‡[#U¯`Î–óÒ Øº¤g4áI&®Š¹±u1UåHFEêŠÚôïæ§ÛuÔÍ®•¾åŠS£ê¤?å8‘n0la¹ÎÆS{¦œO€$†&šB¤—Óû@)àµÄøşNqôA}ÇD‚HDJW„>2¸;ç˜àóåÏc4à!ËİÍtî/L¢«—8”Ä/’ÄwêD…F¦’Í–+¤´’~IÎ¹<¼™cÛ4WÖ*.TÆËƒ`ªè{¥ŞùE	t¦M×ÏˆùíG‰SP¬NQ	Ö÷=x\dmbÂÓjì>p• XÇ©êá‹¤êe•ºì]€¬ºq&.…‰¢jI
+ºô#ôÂí7/îHDÇNißSZØbÛ†
÷*:@£”ß€”¿MÊ/rBÚú×ß$çáœh˜wk}+%/uñùò~ı÷ş"ùÓ„UbF—ÚSÖÙJ©è"6¶‚äUW±‰KX%t›²†UJD×±‰‹ØÅSñ1¦=×’Í%uÒƒÜë‘²aDòİã¾ğ«ş Ózõk09‹.`¤¼®ó»óvœÑÈ±æ;­ Œ\\ÚÎ5å;6=èMàşğ=}‘LyP½’¥B]XÜë}Ùš±62üŞ`LÃöğ4¶Ïz s,
OÓ# h¸§ÃäÊcQ*0."Šfÿ!ia+®I×2(…C9¬!¯h˜ákeQ¹DÂ=Òİ>ÇìÚ„ÿmecË@³ÂÃ  [º,2ÔŸX“”š'’Üª±16[„™*XŒ÷ùñå°^¥MÔ•|¼ş%.¾!ê†½í:@äè—€|ş $ŸÄC Q	ÖabÇ³P~™€iø%ÁVÆ·`¸btÊš(ƒaE&>÷U¶»¤d¡Ï÷Úpû¢Ï¦sÄ;Qğ|«wIW¬ 8t8†²ÓUèsØ?¿Sª.B5³ôd
¡O…„s/¨qÌâ	!Ú4†ñz>(@2²<#ÏhI¾x8Ÿ‹s¨Æ¥”šïœ."À+Ò«‹ËÛ¿€*‚Ñu´M@ó=¨cZÊ7a	K1¨ó”uÛö(R¨ÊZR=ÔŠlóZó§NŸw(Â·œvOç±ëh8>¥¸İçİfC,º•œ¤óJ’¢Êûî»ïÂ`2ˆMl½]õ$y=S	mcVBQårÄ€’ºù!ö>‚RSö=ä†±‚p€˜¸vENÓùÈ9Ù ‘/Fá!©ÒôÎt7MûT„âY8˜•Ä¥ê’æóƒò‚ÓĞBºV[±àÙ‚ Æ€ë)¼è~Í1 ‰;o‘Dš×FË†b´lhFËF¸€¸mä1.¯É”ÁSÑ½Sß	G9ó%šk^Y =åĞûBæZHç1¼4'Ø´Ö‘ª•H"i¡{@?0¹E~°šo‚é¬ŸÆAQæA$§+>?¤ûÈïÀ%g#h1Ãà³sñÅŞgá¸‡c2İqçfôU–Ç¡³ôÜ=³ìFªO|ThÙPÈÂÜkåg»ÕÈ’^Xø\:§ø/?[¾ê“úíşµ’ÎÊåô|èı®áR\ŒJŸ€MÖ,¤¢ÙŸwTƒñh/GÒó'ç/é…<…šâHpò6d]chÄˆ5"pnAÒx>Åé*ÙùQ šZ^HHïë\È¼T¬ç#}jvIúí2«§s£áó!“X(2VÇâbsŞËá™k©X¬ú…•D*8_÷Ëş{?Éïèu›‡&£|Ìİ.±°ÌŒí‘ç3ğÜÎ­ãM‹äÅ—èqHœÕ….åáïb»©ÑùXè§z.bé–ƒ$¶´Yñ¿0^Şÿ\«olWk5?êëOØæƒb%Ò¯<şOÏtÑœ…Q}½‡â‚»÷ÿúFÖÿ“úNïaÿ“¹ûŸâmÁoàÍÍzÖÿ‘°ÿ;­ö~§<ê?P@­´ş_¯n×k‘ş_¯®odñß#-Ñš—.åâªÑB—v;P—á¶:öÕ?ÿ÷ÿC+ĞÖú†Û·~’ûéÖh<Ä=
È#:Äj<Z‡ğüÁ°:t ‹9ãp“•»c2ŒÁæõŒ±é•Ykˆq¿.ÚiNëĞ4†hG¾	Â_aó°’Ã]-8¾·†à`áhÀŒÿ„7ŒzĞÂCû¬±kúq¢lOÜ0o„;/Ôâ!äîS8^MÁåq˜D$­ X>?™í‚ÖèØâ"BÛFCó=?sñÔ8tè]zn‚ìšÛ’Œi#¯Õİ_c°Ú_£L/&Ğa{„«e¾J½X½¢`…a®p	ˆ†,XJÓJÅà½k*(çr«’iV±8`€©‡7üp
vÓêjÈjuUeÇÙÒ"(‰ÈcÄìlb÷h£Y¬zËè*\Õ{¾;é!ˆÒÍúÌ²a}eB‡IêSh²„Z0Òœ5²†]k; ğjB7ÃD¹Èî+gé·0œf¾v-ß7m,€q¹(ŸÏ~˜‘÷ÊeOŞ³Wûÿüßş7`…8¶)ª"åšÊŞøÌt¡aGfåıFo-Ãf4=ï¦Òõ]Óï¨~jÌzŞ“AİcßğƒõõX.¡]{2tWÌğØIë˜/RÑVæñ¸~Zh1ú¸‰,†İZf¯q€ %’¾RE!tjšäƒ±>bQ=¼¿ Ñú§¢ ”ÜÔø ×øk…½Á¥_¯ï™ï0"X­â`¬ö+ñÊXiÃ@u¥Z­T[?­m4ê_76¿&Ïqí^ú„¢ÁİôÕrM\JŸmÎkÇ¦7Š' ‚·Š¿ƒ¿ÏØwÊiÿ§ïØTxJXA	Íù¡‚ohåß?ã÷+a{¾›ZÑ,.2RÂæÅYàâw›)á’óYĞ"4U¡©±ê‚Mø2ÛÇ)„¼L´ÌCUN©jVRÌ“\ê^s#ÜåšÑGö\¤!Œ…À”†¬HG· G±<«Š>¯1'UA‘ó’«‰Yô
‡Xù]DŸ@Ãğ lJ$KT,¸ùÕsÎ}ŒP')"¶e(…½Y„HYŒ»*EBjg~"„×üÍdÿ¤a+(R±œ“{C	Ø7³îÑÀfÔM!¾›Ì?M¯sêGq'ü¢Ë—¢‚cÀì‘Ëíªs–ùŞ …"©òP˜««‡âD<è#Äøåü¢
–2”+­®ŠËcxŞ5G!2diÃ•G(İO.½ŠSÚ*[‘z
?Ò-ğ¹r† sŠø†ğ&Zœ3îÕÄ/úpD¼àdU™¤ø€Qf˜f¯P”F¢s¢¸ÀrÑ^ü¦Q_¿÷|÷Šî99óÂ/© v(wè\ãS`´§ƒj
w%ƒˆÇ<…ÔŒ…2M.‹mz·²z(SY6…PIMP"N+ˆ¤d<Õà Sš«F6P–ñJ“y‰ß%òüïbMMgÚnáßé€ˆ%‚Zrşr#XÉq7<ŠCÑæê5/tY¥F`°¤;dGÙ7wv­‡(†Õ]ªšÖ-É%f°R{¸Ï×–û+ĞÄ ƒ9qMÁ)GûU¾á›Yê¾[¤¼±ÖÅVGN3yçĞ –Ó¬`9ŒòJÅ÷åk¹*ŸÑ9nhUrĞ)•œoÂôÃÁ‡?µ@ÎÊûp^¹¯æ¤úÃG<5¡=;®ãc\÷~ÚkÀ(
 )3¶`dX>ÃˆÔ'GŒë#_ 3p¸ÀTÛ‹~×Ñ!´X=3’åzèáå2Ş(á»h8âš<ŞizÓÃâjÁÌWÓbºÅŒÂŠœ^‰0\
(q&“‰á´ÉÈAGPÊ¢7ƒ8D2R!ÿ<—hé´ñ BâÜÈU4‚8_`àùæ˜ç¾ÌK8Œô5> $%5Eã=À2@œ/Áa-ÿGÌ+ŸxñÅQC1ñ÷™‰1—Øj°¨áS¸}UÕ>>5JcÍ¦QøÕÌ«qAÑ•Kl[8|p{VşÆWÍ|™Í¼ï>¯»8Dî¼ŸYœ³ÎÒ’¸RêƒHë–ÛX¾I–´\îÙMpjUrP“Eğµã^òÅ:<©Ú'WK…ÖØ'Ş„Ì€ñá
¬ª"SL}”Àè€^úzêŒŒK¯ó„Kêk¾)×u¦\×­ËDûáZx—#·õª+1¨ñ\(û&İ/›¼4–=Ös'x~`Ÿ@Û¯
ÛÈm¢C®©—ÙaÜRúNøÉ«fÒïŠÖŠ>è˜jº> æQŸÅW^ÉÔÑĞEŸ½5¹<[~öÊµ	ˆõb¬ìRÀ=tÅ‡G‚HJ™È&A¨7'tO9—ûÈo	‰¤¬mrÑ‚yñdLpÔ`£o0c9AoşÈ­d|†k¡_š°
s¹'c?´_ e—ß·á‰ƒ ğ–¯µ8,B•pÀáÒÎ’Wm£²La"-c0ê˜ŠÁ$Âµ«Ö§dq¦Å%ïL´nÈLgçğõã÷‹òßè<O{!üüO¸ÙBš“@ˆ#¸§Å	Š´ÁaNµ‡§ÄaWœØ¤e(Şô‰ç}ÿ-ô<ğ,“ß/³=G ËgÈ A‹,İ–:G]Ñ$ú)(sõ óXÍ17·d‚…Ïubw.kl€İÎUº8BÕK@ó#Õmeù‚„Ò=¨—+á€V.:˜ÙÅ´›&cKâ{<  ¢2Ûwx`I`§e‡&iQuvƒ;-lEì¢<šïéºu¾*Tm¯†¤KçàUû::ÒZ4ïGèV<=ÅäRjÆdy•(µØ”¬wËÄ3BÕª‰oz}ç,hò€QcJb«ì{öX\Ù"MŒ¼ê$£cWõñSªVM›eö2Ğ/Ğ²¬Üº¡¢ ³‹¤Q¦¶6É©èáÜ+E›œ
h^Ô´55,‚¦° ç²®TêQLtšHqÂSVo‚;˜<xPi¢N#&ªP»æë¨ÅœÊÌ®!®ìê€²äpN7Ô)«=FVÉŸ^¹tH¾¡ĞI…8¤'Â¡£á@èV‚·±2]±q¬ìĞØLoµ¡ĞhÄB-ÏkT-¡§¿õŒÉ­Ö'†ªT†İ†J‘_T ğÌ+Åj¥zÆäJµkqfR42œÃª€İfVyhû,©}÷ªT°BR™==4;Ÿa“V{íİçÄL¸5±pO=,øşè)Æ¥yĞS³«"W˜4À! åWªlğÀJ»?éù•óÑu­^®—kåõr;‚‹³—6ß5­t4GM¢Vƒõò:G!~ıRZ»ƒ{D*?ö/kå¯ËÕÓÚÆF¤ÌñR‘àF?$s G4+45×:£†Zª„NØA‹c–"¡µµ6uEĞ3úUÜb•ÄÓ¦.±3FAÿùê‹0hî·vh<u´¡ökùı0HO¥Z)çHRÇJ8Îİ•Ğã,p¼5à,0Pà'°@EÃS
=T§N“İ$ ¢d)F8ô”Ç8ºJ %™i'r;Øt@‰Ó"¯|8»räŠj»çÌW3-^…
ÿ«ğR@Ï’Ë`Ç6Ñ_ÃFÁ‰Úü™se’®¬gs£7ßMVOŒëØPà‘S“¬‰y=î¼`O¹"”=¾q	KW9å€äšºi‚Ôª­è´c<ZËC@t‚&v\GÔÇå“¹I«‰ÇF
!L„Z Hœ´Ÿ
(42Ì‡§õgà5MÌŠ–@ãÇ4`¢“('ò*Ú{¬§D>®ZâÄ^.²ğŒ€}üÒ÷R´5Fßxû¸İ	—ıò>»5p	ùœƒu“ÛH`Õ.r…¥Dİ±Ş-ŒÜ/Õ7¹AéI¶&£7ˆßî@>˜hË@¼ckÓğ,X;Šc_Ød6ÄeEZ‰‡%
@ü¥gêßÉ$ğRªÄšÔ]L2ù†‘D"ª¿‘u¹P`¹7Ä}ÇË£‡[*¤ós ‰+pÔœ(?\ÂLaÆ¿ÍSxãÏ!`!’¿ÍZeCéË)H_†ûî¼f	_7İpxpÁÅDàdBà')Ağë‰¨ÒÜ‘-1œxëB¼²œTˆø{òª@¾MVl×ó& «Ä'å§Ë³ÉÒµE´ú	âYã ŞÒ¿Œ‡.¦¦ñ"}îe."Ìo^Ğ…ÜËhG†
îı_šî»ya÷ÀËÊ­İ4(@5©€Ö1ñKTÊ«¹Ü*{ÓyO~˜BI¿ö»Â³±¸79Y<Ô½½Cù
*áö¬îVáÕ&$«Ğ¬Í_õÙÄ&ÿ,è‡Öä”)3¯1ééT/WËìqµsF{aL1ã©­ˆ"ÌğÙwˆ`w}}]6`Ùq/*¢:¯²·»Ó9èvJ ô)ègw<ÿ›ôr°DIw?ÿWÛÜ¬eç¿#EüY¤éç¿ªÛõõm:ÿµ^İÜÜ‚ÕÚúöf5;ÿõié7t‹ë%9fÌ§MÎ™ ^a·ß`… Uk½XcÏ&e£ŠÓÆx‰Î˜&ªß²®˜ŒVµ»E(Ó5Ì<¯‚Q†=­õoÖØ×µÍ:{14|ÿÌ\\¬±.ÌX?™.?{ ´q=Zæ©¡nfÂ§ÖÄ8®øÔõÍs´HÒ$ÄV@)¢×¼+ó‰é¾  NVPºÓ·ü taÏğü¾úì†w@ıÂÊ	ğÏrl^Y8;Å²È<›*Tw.y.\¡¤ÿ©ëdxJÛßxZ’Š[ ø Ñßô$ê¤Óo$<N3'èôqQ­uÔ%Åf!|¢F :À}Áj±ï-tÍ¾iÀcí›ru»sÛ4d“YÉŒG!¸+}A·¯ãĞ¹±}ã=ïW­ãæ+š¼pÄeX’n­¹üvò‡·ƒÆÛë
{‰
ò-Ëœ½ş@¿Cú6ürÖT\ÇÂ×C-bÒ<€¬³ÄxZJ†^4C4¸º’w˜WÉ0L†¶¾0§s¦ß* ]è"_Cix-w”ôëÜ)¦uJ­0;¨y1Îâ¼íå„~1_‹£|{÷8~­¼¼IŞ‹E2S tşl) „ı;`‰í®`ÆæO¸£XGø—İ“ÃıS ¸hSHÊ\8æ„õgË©cKÒ÷7?5—ég‰$,ˆ|{ù$˜¼_2fpAãFø-õş“1‘yñ‚5—¿#Ã+R(è//†cr¹×Ü±|Ò×¼:œóÊWÜç@nÖrá`‰ç‚·Z.;ñ\ğrÙ¬ ß³‡°¬aj¦`D(¹{Ósóáæ™ ‘ŒØSw–NË¤Ğ# ).ÆÍå Î_ğÒğ·JAù»‡!ÔööZ'æÂÀ€™ï#B2•›Ëø¡ÏÊ«ÀË=gè¸Mcâ;A†d0gÁw—únğÊã¯’ yC‘ua•Œ=h8‚Uy5Èöw0Ê*ø†Ñ\–Æ&(¶YŞn€‹›w+N¦6¥¸kï@1~…P¼»ÁmsÄ•å4—¯¬ÄË¹eIs™l\Jµ—ÍeÍ˜V*IK¿YŸà%‰\Õğ\*ù.éÖP.Á(î·X¾g7Ãí}ëæÅw¹ãBJi`²V1ñ&£Ï‹|F†{#Ñê{0ücüg¢Zô‹Û}©D[>/wÛbïG¼ĞJ~Àİ©S€B;TJc
+ògqzs–ïjÍÊÒ]Sx~éáê˜aÿ©®×·£ñß¶7³ø?’xüÅÍ@\•×X$.Ú.ğC]|îiÁ—ëÊËnğvC¼¯]Á·›âmôj•ÜÒUÆr|±wë40tToâià•8™Ü˜7%s\l³ÆÜş¿±¹¹•ÿÇHxhõ¡ë¸ÏşÏÆF¶ÿó	Ï+?t÷ÚÿÛÎúÿ1Rxb÷áê˜·ÿëõM`€ŠÿXÍÆÿ£¤H”€©ãîã}»–Å}”¤‡kx˜:æïÿÍúö:õÿæf6ş%ÅÂq<@wÿµlşœ”±c¡uT§¯ÿjÕuòÿ©®olmlaÿƒú_ËÖ‘–˜—(·Ä^ˆKL‚3İvŸÉ[cÃËTşÊÆíWüm9|)"¡¼ôøjöTUïŠ¢ŒQá&cÚvá#/—ãwáßq)ó¸2t9½Àíhõ¤Ü'Ç“Q..™N&rûÖ¯'’ÌçfÑ,=`J¶Ø:î>ÿoÖk[Ùüÿ)5~Üë˜1ÿCÇÇú»Íÿ’2§ßÇvúıÙ:ûîI‘Íè0ï0â»+ÜcÛ·V®UÕ71Œ)ŠW5‚)oQ6QÄ;ÅŒH}Ä«D\ô0²(²sIO¼››ôàY?ÁÏjõ2w›)y¿Ò”uÑuÌ˜ÿ×7bóÿÆÖÖv6ÿ?FÊæÿlşŸ÷°ˆ3~Ì'›ïïÚ4/‡7ì|2Š >üV¬!§“ÏÊù¨ÅV’ø¶
ÿÕ€|"^²úÉÎJ>{şro¯/€Üı3£Ü°§OƒÛ;dv<™UúÛZîÈ×70Ğƒe÷\:´n|>"V×êkëkk›k[÷"çîÁÎqg¿spÒúR¨*L¯GÉz(¹:/ı‚û îF°Ï=®4#\ÿBê˜¥ÿmÂƒØÿİ¨m×AÿÛ¦ı¿Lÿ{ø´°‹®½š†¶kŸƒÎ\ÙÈ ôY—3ŠŠÏ¨aí¨Ç”í”øuOÑÖÊI:Ûš®®aÌˆÆ¦jdDu»´ƒøvÇ<ŠJ&óÔÊUü¢haòËKĞiÃK»»Ïx|@ÌOîéµy7€ã¨çåõyÔÒHCíM–Óh‡¡Õ¥ÔQ0D}& ª×”Êè“´ğtJ—ßù*©°Ğ+»ûÅ2kñ,0hû»p˜ÁqoOƒ†»c\ç3óïı˜Ğ…N–_Î-i¹Å½?JpÙ†öİ›ôÖÇù€GºDgYÑLño%RA‡S—àó’	$w†ÎvRyüš h}ßÄ{s®øóÖÒÅgUÃoéR ŠG¦§MÜ9@;ã»Cvz‚ /P
ÈaÇ|LOã³ú®#¶Å2’%V®I“èœDµ+=[«O[¼x?‚sèŠYxçŞ  x—S¢È5_ïu¹ G6r¯Û÷š¶éã=eè§ÓÏµğâ˜èK–{#äò»ÜÉÍØlò	r¸ßY½ÀØtÄ•3¹×PY0Š£_UpØ¢[Áğİ“ÑK+ˆá©U÷fxîîe+Äv¯Í³=çÂêáU9˜3¾¬3‚çŒUp]qÉõáÄOü&p%ÚWNB„¼#êâš»9š}«„Õr~î9ı.)õ¨Ö1CÿCw¿Àÿ¯N÷¿on¯gç?%½é¼Ø=è¼ËÓmO ¨È¼#"•5AáÿåŞ¼ètwwŞåº—Ç»'?œ¾<j·N:İÓW»­Óıø™óîË#<ÊÙ<7†Şb½È²ô)õ®·Ö1küÃÛpü¯£ÿÿæÖöz6ş#Yö•iãü}
}›;‰D†N§šğ¹±ÏÒ§¦Ù7:~z3í?›Ûıgscí?[ë™ÿÏ£¤Ìş£Úo4ÍL@o
£lÇ>k<òL~óO<¬(™ñÂ4GMŸ`šú=MA©°(~1Ö 5vÇÃ‚€æáQç İ=.jæ“oªäuãO-r­K¯ï™2ú 7õ”ú}è/TM=3J:ãhÁcO^Ü¡¨krÖ–@’-C?WÓĞŒ[ÂRÇLÿïõõˆÿ×vu³é‘2­(ÚQ-m<ül·ÚâŠ`e×-PÍIy³HÿFúôkõèÊõ„ı^Èç_ ®Áƒã^äú½^æœ3ÜSèá8Å½0lë'r‰×¿ÀLÂ!öì&ÍŞZìäàŸãÅ#5õ†;òŠÏ ò‘éÀD
™¾äÏ-š²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²4GúÿµŞUÑ  