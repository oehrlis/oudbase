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
VERSION=1.0.0
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="TRUE"                                         # enable verbose mode
SCRIPT_NAME=$(basename $0)                             # Basename of the script
SCRIPT_FQN=$(readlink -f $0)                           # Full qualified script name
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
CONFIG_FILES="oudtab oudenv.conf oud._DEFAULT_.conf"
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
    DoMsg "INFO :                               directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default /u01 if available otherwise \$ORACLE_BASE). "
    DoMsg "INFO :                               This directory has to be specified to distinct persistant data from software "
    DoMsg "INFO :                               eg. in a docker containers"
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
    INPUT=${1}
    PREFIX=${INPUT%:*}                 # Take everything before :
    case ${PREFIX} in                  # Define a nice time stamp for ERR, END
        "END  ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "ERR  ")        TIME_STAMP=$(date "+%n%Y-%m-%d_%H:%M:%S  ");;
        "START")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        "OK   ")        TIME_STAMP="";;
        "INFO ")        TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S  ");;
        *)              TIME_STAMP="";;
    esac
    if [ "${VERBOSE}" = "TRUE" ]; then
        if [ "${DOAPPEND}" = "TRUE" ]; then
            echo "${TIME_STAMP}${1}" |tee -a ${LOGFILE}
        else
            echo "${TIME_STAMP}${1}"
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
SKIP=$(awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0)

# count the lines of our file name
LINES=$(wc -l <$SCRIPT_FQN)

# - Main --------------------------------------------------------------------
DoMsg "${START_HEADER}"
if [ $# -lt 1 ]; then
    Usage 1
fi

# Exit if there are less lines than the skip line marker (__TARFILE_FOLLOWS__)
if [ ${LINES} -lt $SKIP ]; then
    CleanAndQuit 40
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvab:o:d:i:m:B:E:f:j: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
      B) INSTALL_OUD_BACKUP_BASE="${OPTARG}";;
      j) INSTALL_JAVA_HOME="${OPTARG}";;
      m) INSTALL_ORACLE_HOME="${OPTARG}";;
      f) INSTALL_ORACLE_FMW_HOME="${OPTARG}";;
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
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

DEFAULT_OUD_DATA=$(if [ -d "/u01" ]; then echo "/u01"; else echo "${ORACLE_BASE}"; fi)
export OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}

DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/instances"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/backup"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

DEFAULT_ORACLE_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

DEFAULT_ORACLE_FMW_HOME="${ORACLE_BASE}/product/fmw12.2.1.3.0"
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

SYSTEM_JAVA=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA} ! -readable -prune -o -type f -name java -print |head -1) 2>/dev/null| sed "s:/bin/java::")
DEFAULT_JAVA_HOME=${DEFAULT_JAVA_HOME:-"${ORACLE_BASE}/product/java"}
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

if [ "${INSTALL_ORACLE_HOME}" == "" ]; then
    export ORACLE_PRODUCT=$(dirname $DEFAULT_ORACLE_HOME)
else
    export ORACLE_PRODUCT
fi

# Print some information on the defined variables
DoMsg "INFO : Using the following variable for installation"
DoMsg "INFO : ORACLE_BASE          = $ORACLE_BASE"
DoMsg "INFO : OUD_BASE             = $OUD_BASE"
DoMsg "INFO : OUD_DATA             = $OUD_DATA"
DoMsg "INFO : OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "INFO : OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "INFO : ORACLE_HOME          = $ORACLE_HOME"
DoMsg "INFO : ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "INFO : JAVA_HOME            = $JAVA_HOME"
DoMsg "INFO : SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "INFO : Installing OUD Environment"
DoMsg "INFO : Create required directories in ORACLE_BASE=${ORACLE_BASE}"

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
            ${ORACLE_BASE}/admin \
            ${OUD_BACKUP_BASE} \
            ${OUD_INSTANCE_BASE} \
            ${ORACLE_PRODUCT}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

# backup config files if the exits. Just check if ${OUD_BASE}/local/etc
# does exist
if [ -d ${OUD_BASE}/local/etc ]; then
    DoMsg "INFO : Backup existing config files"
    SAVE_CONFIG="TRUE"
    for i in ${CONFIG_FILES}; do
        if [ -f ${OUD_BASE}/local/etc/$i ]; then
            DoMsg "INFO : Backup $i to $i.save"
            cp ${OUD_BASE}/local/etc/$i ${OUD_BASE}/local/etc/$i.save
        fi
    done
fi

DoMsg "INFO : Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

# restore customized config files
if [ "${SAVE_CONFIG}" = "TRUE" ]; then
    DoMsg "INFO : Restore cusomized config files"
    for i in ${CONFIG_FILES}; do
        if [ -f ${OUD_BASE}/local/etc/$i.save ]; then
            if ! cmp ${OUD_BASE}/local/etc/$i.save ${OUD_BASE}/local/etc/$i >/dev/null 2>&1 ; then
                DoMsg "INFO : Restore $i.save to $i"
                cp ${OUD_BASE}/local/etc/$i ${OUD_BASE}/local/etc/$i.new
                cp ${OUD_BASE}/local/etc/$i.save ${OUD_BASE}/local/etc/$i
                rm ${OUD_BASE}/local/etc/$i.save
            else
                rm ${OUD_BASE}/local/etc/$i.save
            fi
        fi
    done
fi

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
        ${ORACLE_BASE}/local/bin/oudenv.sh && DoMsg "INFO : Store customization for $i (${!variable})"
    fi
done

# append to the profile....
if [ "${APPEND_PROFILE}" = "TRUE" ]; then
    if [ -f "${HOME}/.bash_profile" ]; then
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
    echo 'alias oud=". ${OUD_BASE}/local/bin/oudenv.sh"'      >>"${PROFILE}"
    echo ''                                                   >>"${PROFILE}"
    echo '# source oud environment'                           >>"${PROFILE}"
    echo '. ${OUD_BASE}/local/bin/oudenv.sh'                  >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg '# Check OUD_BASE and load if necessary'
    DoMsg 'if [ "${OUD_BASE}" = "" ]; then'
    DoMsg '  if [ -f "${HOME}/.OUD_BASE" ]; then'
    DoMsg '    . "${HOME}/.OUD_BASE"'
    DoMsg '  else'
    DoMsg '    echo "ERROR: Could not load ${HOME}/.OUD_BASE"'
    DoMsg '  fi'
    DoMsg 'fi'
    DoMsg ''
    DoMsg '# define an oudenv alias'
    DoMsg 'alias oud=". ${OUD_BASE}/local/bin/oudenv.sh"'
    DoMsg ''
    DoMsg '# source oud environment'
    DoMsg '. ${OUD_BASE}/local/bin/oudenv.sh'
fi

touch $HOME/.OUD_BASE 2>/dev/null
if [ -w $HOME/.OUD_BASE ]; then
    DoMsg "INFO : update your .OUD_BASE file $HOME/.OUD_BASE"
    # Any script here will happen after the tar file extract.
    echo "# OUD Base Directory" >$HOME/.OUD_BASE
    echo "# from here the directories local," >>$HOME/.OUD_BASE
    echo "# instance and others are derived" >>$HOME/.OUD_BASE
    echo "OUD_BASE=${OUD_BASE}" >>$HOME/.OUD_BASE
else
    DoMsg "INFO : Could not update your .OUD_BASE file $HOME/.OUD_BASE"
    DoMsg "INFO : make sure to add the right OUD_BASE directory"
fi

CleanAndQuit 0

# NOTE: Don't place any newline characters after the last line below.
# - EOF Script --------------------------------------------------------------
__TARFILE_FOLLOWS__
‹ óE„Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹„–—øæÇf ]ˆ€4Üå×”´s¢–×šD€n\wƒGâ†áGûÕoÿ?ø§Ü/pøİ/şÎÌªê®ê $AJ3‹š‘„î®ÊÊªÊÊÊÊÊÊ<³ìÒ“NårykcƒÑ¿›üßruÿ+«Ôªë•r¥¶¾YeåJec£ö„m<4b˜Æo¸€Šç˜óA¶óó	ßE;‚"éÆß÷N¡yşØ+zı¨còøW×7`Ìaü+ÕZ­¼¾ã¿^«l=aåÀ%–şÄÇé%$3Ãëg–Xa~	 åvzu–›;Øc×º4z–Çš/×Øó±gÙ¦ç±–yiœÑĞ´}öKÖFë³•ç­NÊtóÂtMËó]ÃóLVız}UÙ¨²—Ã÷ÏÜñÅÅë\Yş¦;0ìŞÜ‘Ş7†f‘§:Ó&|lı¾ãŠß<7lv`öİÅVÓË3Şz÷_t@±ë¡t»gùAéÜ®áùÛ}Ã¾0{Ï¯y÷·?¬[Í€x–#óÒò,Çe‘x¶Ã±;r<“Cz4Ã:]×ùÌwØ…	ÿôMfÙĞ4»k2ŞBfxÌ5ı±ÍºNÏÄp|Ó“Ø÷a=~Ë\³±göØ¹ã2Ó¾´\Ç¦A…Áé;cŸ¿n jøDxŸÃ°Bm¬ïû#¯^*]@ÎñöN‰÷˜‡,HÜœû°B÷°ï€ª÷ºåJ±üu±Z®l2Æ€£0¶c[¾eØ¥éb7BJµX©`-™§Ùû¸ö!£	¿0³c3ç)Z|€ÉY`ÛP©3´~4|@ì>Ğ3æšl¯Z§GÇ§­ıFî£òT/dlüœzEÇ½ÈŞm»‡m¼?×‚92øìµ1›Ş=”yİ>êìì7`43­ƒæáa{¿ÕÈ½jgÙŒi	h×8˜là\°s~£‘	Œ`??è´ÙÍİÎàmœÁdCœMí£ÃãÓıæ^»‘[A
·Ï°\9Ÿ9Ş;<míµ·¾odKşp”¥—/vv¡öÜG-ÃMI/^Ìå²™Îqóèøô»v³Õ>jdé	Ù“CÃ–û¨Ô~ÃV^s
‡÷¢ûnò4gYn5›Ùkîì6[­£v§Ó šşã0!‹İ~¦}ttpÔ(gTŠ¸ÿHrp/Æv‰ê>ÄÀÁÍwö¼Ø+Ï¸0Wòìc”·¶,o40®y†9×äP!5½j9{ŞËîì¿8`u^ñZtßú—.+Xì[œİ;û@ûÛíg¬Ğbß‚ÑkíÃïøïC˜íWÛ{ÄÿŒ½Kª„±B?‰Ø©r¶âãâ0„ÅRŠ_&O˜))Åİ¤âİ¾Ù}OËkV—øR
 ¥İa’ä{‰ä[g]»Ñ²\³‹‹Û3lh›.±ëÃ6¯ˆ—¤”&x‹_’“Êí:Ä`ÿ¸{ğ¹ÃÏg³·ğ²rÃ
>+³wßàúngd3·¦a7íŞ?Œ-ŸçË}¬ŞĞgs k­ÌáxÉåËŒŞŸ[™›ÌÜ×ºÄ©µÇ	‹ó(ß’À2=ÔT§^_Ég>R;wö_Ã"YyZ_½I"BJ ëïM’­{“Á¾`g&üÓã}Û~]N n@ìJ† Ä23˜mL¶“˜ïƒÅ-“,<°l±ã½ö)ĞÑŞ!,,=KXöWO¿/<öNŸ~WºWÚÉæ¿ùF)zt”^ÔR˜V(}‡z~‡µjõf³j†Uş]ËPLH²éİpdiAC
¾É²b@t2È¬R\˜”—êèöÌâd€“(Ë>ù¦É
†2ƒ’Ú¼š&ÈSJşôúÖ¹<]õqŞÖXí/ _ÂµçhUÜ¶e!Z‘—S[—ØÂÉà´¬JKã­í9¶çMs¶gÏ’Úô…õ~2’³wŞCğç€Eª
E,Êº)€÷ÆøÁò@8š¶ğ%O¢÷K® ;²—óÁš‹ÜVÚ˜ô¬²«Š’8*doC3Ù6H1ºÈŞÀ–ø‚Cgl“$n¸cÜ"{EÖÉ5¦eÙ{×qQî`0zEµŠê¬UHÀl—öü¬ğ7¦ÂW¥€Ä@Ò·ŸÕÃåŒ¶ÇÍç7ª‚‡£æön;nNŸ7;‘ƒZ+£z<Ó'ÀÚKãÒ°(=jí©T¦AŞvÆƒAğq·Ïw|Ø.­Ûofà=v’ûøİG©(‘TÁÕ¦¶·ãÀjßæ›ósh˜ÙSË¯O-ßv]è!D§GR„^|jkxq]wlÛ(¿P×[W½¸§ˆè‰PkÓ îYG’U\ÊV)zÚŠP4ö›@T5Ø¶ÉYâwĞ)Zm‰	BÛØ(‹)L	Ø6fìO˜hGJâ´4E«°£í‘Úï¨âH™Ÿ¥Hñ<• ¿G‘‰[6üòM–‚ÿ×_ç#;•ß¢’ìÊ°mƒy ¿÷ÁÀÑ¦é¯§²Wö{Û¹²yÓSä½f–Š’›ó×q:2‡Î%ˆÕ&
Ô|ÎECáÄj «ÏJ=ó²duñ@ÆGxf„zìàÅ|4\"4‘÷×÷4Nç"å:(7VîuFŠ.2]t±…÷ø9f‹rºXÏ“rÅE:m[Y­ûÊs‹±L€;T O+N:ºìÓ'øòVèE>«jµVÊPÖµ‹‚ÓIQdgŠ,·rÜ&\z
¤w”½ùè¬c œıc)ösbÛ²*ôà§œtŠ.OWà ğ"Ì¿l†¯S¡0¨Q%—€~sáŸQşa¿ü%ÓË*:­ù-i&½_*j…ÊŞ´K‚‰s¼ã8õÏ…d9¸=Ãº—[¡~ß5F,«5l½œÅ½t&#¸ôº¢;NÀ;@/è=Q»™¬;©Ê&uzp˜’ıÂe/œo¦ïŒ€lõò#×Áé‡šXØÃ#ÃbğQïÄ÷¢4ë_ZõVı‡z»î¢´l?¸ oTAè’kæÊ
Ó½ÌGäaå›•g{×*!#™B×¼ÔÖªæãz´”?Èªj,%¯›gGíÃİíæ1*ñcXµó:U&Cùµll•åVÕ…‚öB·ĞÛ‡<#Æã"]™Úb`QU×İLQc6°fvAIœÖs.‘e9´àìf2Ìê_V2˜‰ëÙs¿†ºú$T0AXˆ]g(X ÓAş¤Öw,Ö˜‡%9LòÂ7Å„+è„™rLĞSŞ	ì'Äfÿ	‰+ºëóD©/,vÿY/dµ½7™ê•ÅÔ—  ÷ñğMK4ä†wÓ/ÄÏ?iZ¯ÅG¬‚!flKÁ¸lDú‹xFä,ø±máÜµL §kxc;`@Ã‘O¿]gdº¾ezˆ)¼â}6¤µèó×j›XbC!£ï‚Ø¢~¦ÕLÍâ¨ßÊ×+ZvA#†8¶Hßg6zğ–ƒŸ‡ã¡g,¶ì•ş+JË*B©Xœİ÷—í´¸Jz8øÖOÑÀ! Q:p WØ#øæÅè\éãş7^éÄ.±Ò77)°C×Oü‘«® LL±Z"ôtÈ!m²ñc‹%q¸Ò1İKØÕ áuÔ1Y¹€}`ÓeË±,âèÑìiuç%QÆ¶%Zİq¥—ÎÃÊQqKpW2n¸!ë‹™ê'¾ËàVÆÂÔn«yHu‚…TïÎVÀå>Zb¿Ğ|ó»Ó<X1®Ş³åçí—;û:ì‰]8Òú™ıfçåşÁQ{‡Få¾¡ilàL…ı‘•şĞìõ\ƒòÕ\_|»Œµ,Ÿ<+±Ğ¨•\¿nófÀû¼€Sş†İà±ÀGÚ’Ğ;}ÄYpÕf] Îë3Fg£“å§Q|˜*ÔKRœ×—aeÁOÓZìÑäó¼ÅèÌmtHÀ¿”YUÀ¤¡‰Ãù2ÌEà%ŒÎ~]Ç3û:…ĞËN]§H_–;< ¾ÙÚÛÙW—ÔUÌè-{†e,¾v%Uê¦5)mXÕÖwÕõª¾ğ‰Ñå<´y,¦Bğ'ejà|¨g¿„{ÃJš]Ğ¤õ-ö‹?­ï£"h€S@ÒúF5‘ØoGàÕÉG×Ut±}úÑt°Çş±ğ¹->õ$í¹	×g±ÿ­­—Éş~mmTËe²ÿ-Wö¿‘ö¿ŸÉş7˜p?û_ajÀ")gÔ%Úû¹›ş~U„ÿÈô·R‹´lßuzc}`ï¨÷72»Öùuh‡0ïSòùšÿ¼çj	|k3àGµáı2á}D{İka$…{˜ğÆLE;ÏXaÈ¾UF^Ín²{{İÙuã8ïgCbSOJ¼”Ò±æ¥÷kÀÄ<¹øÂFöQmdÙÂFva#Ë6²Ù…¬`‘o;Á*7èóÔ…oa!;şÂVõ–¶ªs²ãüV…»¾Ÿ™]dmï¿nLµâK7 äõ¨maÚwª³q ¼½ßıVØƒ™èëV½Mfza£×I1«BFE”[‘rÌû	U·^éd­tÂJù³ï›‹ıŞÏŞÄK°½ÈØ&°jÁ¤Š.%ĞÙÆ¾q–¨‰Œ(a”U }¼-8‡àÀ‚[b]×Äİ¬¡Ÿí£ÆdÈöèÎƒ‚_]¥ï‰ãæóF¼¢„ŒÔ§»;<¼æG—lùKËá•£Oİ±˜W`q¨çãk‘è†7Í£}´Ñ%!D:…:ï$¡í)p^€ìqf QúCL[ÍãæMi¯M„¥Æ¶°î¥¤-RÚ…‚ÛBÍØ÷Ú7<‰Ñ€è]›"gc@Û·âêIédşÎŸ ÅÕ\é¤RZÎ‡MS7QAÇM¤µ³ŞÏ
/Í
º{æ$²%È.Ç?dp‘9Dt—-¯-3ø//Ø¾Ëo‚Øæ±sËP"ğĞîŒ^ßÜ[ ÖÛÍWLß”„,oês.-Ë¯ 8#æ )~‡Åñ‹·í”Â)los²Ğ»ƒæB@^påIÙ&®Œ@Î5ÏÙ'fÊé–å¯>Ñ3t(£{QtğpÄ+zdÿW„”Y¸-7
ä…
]¥Ş¼¾eÑ–€½n?@Ö˜çŒİ®©ÊlÅD~•(İÉÏº”V å½ØÔëkJ¸æ¾‡—¬0’F-¿'£¤ÖÎ‘®—ĞĞJo1zh:ãV¦üşUğ-ƒ²¤åÖØ‹xyêù.
1H;+8Í
2·' {ä8>ç¦½:rÔµ*9ÈÜËoßÖÏ†ı¾şîİr>Æ‘°p¦èÕŞ¨0óº:Èî@îÂÈöh›¥½a3@¬rYf¹t’];É–b JËa<åu-ŸF ´sïL‘ÜOså`Üœ¨İp^>¼ê)Ü!¤9n§¶:¢¤µ}°·×DY_lˆvöoJbaĞƒÉ\(ôÏ§FĞ|šÉbn&ï$4Ñ6Kí{Ì‡¨@‘i!MéÍÓ–q-4æË¿z:^†ı@šµa!×:)Òƒ±Ïhê§·÷‹Î4L1K¶pJ3@>¬Ü0®ıÌhƒ?ˆŠ4OHjóÚ³PÏğC!S\Êmî²±:¹} ŞŸ† ä+x¤U98ª·ñ,õîi	'Ü‚Äy è$Ñ“++ôãW•¼ÎÕçéÃ>{¿xã.îìÎa›}Œmy}³U¿‡¯iÛï±bõœ+{ÄOÙü+fİì(MoÖš½b6P–(VÓ¹4rÑIÄÃ;	fI{c“,}hÌyÃ||_X/—Õílp	ua*ÑëFÆ”º öHÄSU!ÌgÃÿ…Ùc>v’öŸHÄãÑg±ÿÜ¨mÔûÏJmí?«ëûÏÇHûÏÏdÿL¸Ÿ‹ı'oĞŸ®ıçfşŸbÿùu±¼¥åÙ3~ÀSBêk{QÈºò¡ëØç¤K†çâ·g?z¿0(MƒöÓ0(-+?Yï²jVzüı!¶èÕîîÌâ’cöœ³¦ãë‘™ù]»}ØX¿l<<ƒ	Í{cšïi²¾7ÍQxÍMÙBAşO~å?,Â^Œ‹…íOÙ‚Ögß"©şümiƒ†I™a'*Z«ììoµ÷ÚûÇÍİ…Mî¨ö‹²É]ø­]ØäR›Ü…MîÂ&·ğ%ÙäÎd’»0Ê]åŞÍ(WÈvq£Ü…1ípcÚ…1íOÊ˜vŞ~2¿@CZ¿nÕ‡õöC˜Ñú° 5U¢1êcÙÎÓ­åÂj4qa5º°ı	[Šã¹­F¹¿YÈGÅ¹\ú‘Íñe_Uğé‹t«³1@­¸ò¨¬xZ&éßX¯	ÖğP98lGäÊ4ß3›Tñ™ıö›Ó7íöïöË«l>s°Û
?À ÌxSÈ}Ä€›|Š?onÿîÕái§”Ç+=…J¡ÓJ±§¸• ‚hN¤‡UL*¢PX¢V¬Í8HÔP	Ã/ÂŠo¦Ã£YXÇî…8YU	²Ş¤…õ0»¯§n¼ùÅZ"'€‹Y$ãx0;{èxè(¤¯PtÑm•%‘QfŒjgènÍªp­o|z›a¿ˆŠ’lY<ÒãÉ“7ab*™ÑîafhÃ,#›û¨ã¢Š}šÑ\T5eIc'¶ëèzxÛ±Ï­‹pgÀXtP7R2Ä†…ìÏÒG%Õ—Ã,ú?òmŞöÁşö,­ÕSš&äËpïm‹Gã0¦	5íDn¨¡Ğ´’Ñå.‘ƒgtª<{¨×Âég
,Õ§iğRp<4“‰¾Y½´~Nêeaq,z+bq<»µqº¥ñóÄI}£â™ŠE-w6(nLÓù§“^b“g°ˆÛÍ±ï`¨œ®%hIÃ´ì1gĞC{=†²-ó	–â)Ì-²øO³Oh¢…h¨ÒÇ,uI±N“IâfäîÜä™8ıd&½ûÚ„sg²şŠyQŒH	HçSvdŒŸ9™zô¦Ş·HŸÛÔö‹Lhü[<Ô¬RÇdûïry½¼‰ößë•òzukc•+µÍÚÂşûqÒ_üÍ_>ùó'OöŒ.;è°ßKÖ„ïüü©ÂŸ?ğügÿf6Íãã#ş‹Jü?øóï"Yş•xÿ×Oü-ÈáEc4˜Åáùh Œ{ù¥Ã€ñ¯ñ¯'Oşó®‹+ ‰[¼wÓ„Æ³"ï_ğ¼É‹6ÌgsÇî™<ù…ÿ˜û¿şçÿòoñßÊ£Ú—™´ˆBTÇäù¿QÛØ¬Fçÿz­¶˜ÿ‘÷?>ÏıÀÿ§|÷ƒ+§è&.Ş0eÀ£ğæF4œèâÈCÜ)Çoô`w9RıDĞ¡Ââñ¾›ÏÂañ¹„röœî{ÓM¼!‚@/Lÿ¡z„Pòó)+ß½wÏùfB{|âŠ];c ¶k¢ZÍ\.×BÃwş«kùE<h±mº0~dİÕ!h^?8Ç;3CÃ(ëÃ¦Ü5ñ¼öU@ÏÊ‘uI[1dbÜø?`÷œ–ÍŠÈšOG®ƒcTäu÷ÅaÖ` "Ûğ	$ˆüT|ãÛC
G&­’ÔšØQòRw7wwO·_uövş‘â)!å:t<’¢”"k*µO(£8B$3Ä±ÖÃÃ—Ñá`¨^\ÃxÛ¨¿4.—K –ÊËaJ» )0¡İ*Àh:D! ]é¢¨±œ–­	ÅèØ!‹$4í¸TE-8sLÅO"S²)LÊÑnªØşO‡É3ª£‚¶AñœPïÄÒĞêõæ•áš*è{o$ø;Æ²ï·Í×MQŞ@Ì¬3–²Jcp(oº6ŒÏ%¿•V§ (Yrrmƒ8uO†gúİRT5>,<¬åàL¸g`³k´UŞâñ½MqîÖ·‰“üÙƒÜ™k+«÷ë€iÜïë˜¾ìj`At)**"„œ	ì »¯Í v=çóK¡ şî€Næ¥_”¼|¯Ì—F`VOä .´»É(6&8i¡ÏäŞ=Ønî6Thœì4ê%XŞ®,–ğLÄ˜%`X‘˜´:–Ü˜$´Ñ¹ICn_…_" éD§0¼†¦çM(Îù
”t8ò°Ãñ	
óB­3Ñ\$˜­‡…‘;SpBËÃ,×xX8r- -ir‚²$ıÅ¿çJ¥åO} Y%¯4HçŠ!NòÍ]ñò†…«çÀÓ*Bp+¸ˆŞÊIéíNJï~•ÿX»!4•ì Gpí|ß9nï"Ç"–'ÙÒØsKÈiC‹+n×~ø¤Æ€Ø­~×¹lÇÀ²ß£AWrcsRÛ&(ì\ô-rXxs*yÕ0óÃÉÂ^ 7·˜½^ÏæT2üÚe¸Æ“i‹hD«ı¢ùj—	µ·¾?å&}dF%óèßrõD£ÉpWwô“E´øœ-?=?±—ódƒC_të›dLZv[˜8K“1ÚàZPaC¦˜ï|R› Ì%Ÿ“}‹Ï#Â…¨®¥n£CDò¼`.Ï¼-Â}ÿš=‹Dæ>ŸD—s‹ŒİG„Ú»tUÂ.›Ìî˜Ğ(	Ë àÁ«£ívÏ)ÅO:©üÂ­ĞùàŠs£ˆ=dJù·Q×pJºïq’ráƒãçÂ’àıFãˆ‡"-¯HLƒ‰ñã9FâŒNƒ£`ÕUw¡=4bÌOŒ×ÒÊÕ&;l‡æ™ç–ëù
m9¨õÊqİ5ºåËˆÙ‚´nXa`Fl·ÃE¼Ó|İn"p cüçF±ùt†¹âgÍ– ¡g‰@òr”Qjß>8j£.7„$	)¶/ò<_dò‰P7$§+ğpß€3^G6.Ğ·ha†¢;·l%i$¤9UVC²S$–D.-÷/::¸Q2ÉMIç g“ÁqIi24é}Êmš±Gƒ=ĞÙ¹bm,»23‹Åv„JRÌ®£íÑrb]ANìŒFè
‚ÂT;bI~{+ò{†‹ZÉÂ5ØÕhÀp²ÍLus8ò¯Ã9”YíÆ6¯ÁÇEÓ<_3€Öì³SôV3]') 6³:iJb®VëÙ„ı‹„t£õ³i¶ê‘A`÷5^W(Cl`ÅRÁ¥VA&A?CßqæÍ‰_¡¥H™T±}J$u/)˜ŸkU)¤Mæç¢%ÁD¦P_ÂÅ‰İİšæÒèíö´vW:›7}=ØmuÑ4<_IègÜSD9Vı-˜(•'q[êùİ&"™LİıõQ’Y€¼XÕ§>¿‘fª¼:Sš¬6Æğ@ş‚E…ûÌ²P óÂiAOT’šŸ€Ì„æE@ñÃ
¶£oC$Ğ¤UY…X¹Q÷^s¼Œø¥º.
îá£a€?öØÇè)ùaë	§-ªÉ2RÌdHoÎˆ\?¶=¦}ò¨Ç‡a<~…÷WR¯[,«×-–á‹n˜ÌÓm®`¤–ÇkúÔS/g$uSËãÑò7ÜÂ’?£µä2©©ÂÕVJ‚.Î÷šğJ¨÷Å?ä:ÙºyçèTöœó^rb6ÁJÆ_ÿZ·•ï¥¦š/=té5¥
_³Ï -	E/rvX	ù7Z‘ÆÄA]VAğSµSÔø¤ â9H'‚‡ŠÅ‘á÷u |‘½éFÅÄ·¢åÿRÙo§úQ_É…Ÿ•æcÎb0Ä%A`JÅ¡şkB½ÎD^u<ûn«yÈ‘“2¥
t˜µ£çYO;İXö&]+HÌNzøX#å.(&µ£Ùç1ÆáŠEeÈãQœ«lXğk™Å.—i¯sÄ
[{[nÌû3ñÛgH©Lr
†ãÒ	‰‰1qˆ”f°BôMÂcRRXr;8ù–ŸLóZKxºïŠ¢@ÁuÅš¶”ğtËÓ’Ü¨;}[9ò§Cj5_8Ó52vFî£un(¡)Öó1wVC¶rw€µ|tñÓNKî
v3âÁö³˜Èá©
Eœ¦dŸ6€c?-TÊü½‰UÖñoïÄÎ&J|6Ÿ°x&+±¤X¾aP0è~¼Í"‡!øM$s“„Kòn4g%¨¨ãˆE<Ê1|!6ä‹É9\¥ªÚ¨‚‡\\¿ îÜ!a©‘ïÍqyÒD(PªrS²ï3’¹Ô¦;+¸´ë]Š¬’z“K;Ş[éY®¸Ò¬!p†®š1l¡µâ“´È&*{¤Áİ€›ã)…RïS¥x|x<Tbç¤:Y ï"˜Äcñ¨Ø™.r
|úòİÄŒ—&?)‹÷w^6Ò§X|İ?º,Ç¡$h|;–´Ã¤	dÃa³åmH’'{uîñÏ±mxJk¥?äJ£e‰A°vö¼B÷ü¢€ªPÓ¦ˆLbEM]âR«ST‚õ}G—€çY›,´;\%labTw<óìÕ[r$UÁ03GºvÆ.ŸkÉ‚%É“p†ÒĞ"Ï3½¸	]¸¦ƒd©²ŒÃ*DªÈ# ^­CR„*%¿È	y*µ¯¾NÎÃ	"v0ïfm3%/äGùò~õµ÷îœ÷~<)›ÄË£º‹	Š¥TT+S	DòªjD€’?ªHQ
(%¢ŠD­Àü{ñ1V·ñ/Š=[l…ãŸi>âaïç_ÂÂÕXhëbÚÌ„sí¸h˜ºû[dë*¦|Í“gÃŠ~V®&b­Ë–"Kİ““È«:ÑO= ÓºBõ€¶ê9½[²jÛf•FñÊCTì;IgÒz¹9aüìYÎq‡ Dèx:Ñ7	ú0íl‚²È‹Zªÿ 9›KK>±Ó¸´lFneC°íı×÷³2Á‚HÖñ§ ‚£‹>d  ı}Á.7a!ÂBúûH¡ø^H¾¿v²ŒJÈï#Ùõ{,avíıÊÄoxğ2ÁûHşø5_¾dß@âÙ•÷É%”+,Z	ù¾°Å–ãå´¦4ô½[´&…Åh%”÷ŠÈFE‹$6*º¿I*—€"²¶(‡Ärø>!«ˆùËÊß' ¶™ß'eŞ›˜ŞkÙUn Ãç4Òwâ!üX'
Q¢hF“Áá‚×7/‡l¬A‘§ÅA4:N$ä±­—%FÍô²êíú®Tİ‹_ŒÂî{	› .N(5¢Åd¼Ö§¯S§~Ñ1LÄÎP>å—èk’±+ ¿„t¿ñCˆÜ	0íÈaß†/tl±„ßvø!YÃÃ9±2°Rå$@f
Ä7¦¨Èl”w•±wïXDòjîî4¾”_¹§V;ŞJq5ßXYÎÂŸ²ùâ*Ùí°pO‰¾áÈ <ÆÊÂÈ}ZáPò &Ÿ+TKË	P>Š_°}‚i£ì¤*<Tƒ§ê¾©Q)
lşF.€
h®ÑœHÊè“™òÃ‰ÿ.L<ÃNUmA~İ²a(®£
ß¤Ã¯êìğ:{p¢%uUÇ†)¯«™pû İ©JİèjZ­èÉ¾¦ŠZ-ÆM7xÛ•¡ÕĞ‰ ;B‘BsBiÛûæs#§7y‰]Û¹¢|G¦KDß+<ãmR»–r!tÑÆ¤¶¿{1´64ünMÃFæbøĞ »gÑn³K@ÑTÌ—–ı"L…ãÂÁø"8Ÿèí‚­¸&ElT
+³>ì„¬¢ß_+‡˜K´„áeu·Ç1»2á›;à\ãLQ†Í(qxc]–ç,±ğ#Ëñ.¥æÇv¡²»Uó–Ø..ÌTÀbÊîÙ,¬WiG)¯‰ë·Œ÷÷£í:ĞÉ+0.A÷ùı°û$‰RÀÓ2œ…
è& èàğ4Ÿıqy0(k¢zûü³íØ%åxá¸W†Ûc6™ò$8pˆ‚ç[İ÷}uDë˜ï@Ù¾˜-b|le|(V§Tï¸H?¨™åúDH¨œô]ƒytB¶¨Æ ^ÏGH½¢¯%b›.éâAB€Ì/‚²B Ìx)hEŞâ+Ò?Mïjf§æE=dšÊÅ„¹ëz¸…¯m^iÂfšgıáÙõ´s|4Ë¿†Cp™S3@ÿ¨Vr£Ø	(ÅÇ”U½€8£˜R¨)$p¦[ã‡S
m„…bÆSŠ*FIvÎò^g‚ù@Äøyy.™L]Î"FšÂSı ÔA©	ŠÒ²[Á7@K²•F6§Ÿ°&ºgc½ˆƒ—v‘~v’vª}¯²Âa•k‹“Ç«”¨D^Ò®nÅ5
SI¸ûóåPO L"Ñ1D€~À—sŞ$SÍ‡ ­q#ˆ)œ¹P]±ªk6@õPQ‚¿£w ÑË³`±É]Õœ¢g#~îèš—0|jCxqZÆïos·°(z`ä@ ¬Ú#U+~aÓ1ƒHgr¡—®ğjÈXà
Z'´ì$ÊŠÒ^êPIƒ,IÁB´ìÖnpkg³óœbŸ}†Ì‘{â}(zÕ¯é¢\†7£åıæğÖ´¼'|fÙõT[ñQéÉºz]|çW¯±VîòOõKG‘
…•‹K.’”ÛÒ05,_½—ŞnóJHú¬(¦çC .ÅàB“@éØD`MC*š=¸a[ ôøÆ‘ôüñ¹ÀKjÁ&ô¦ğ—ìÙ	×àJÑÔ‹×Sº4O¹â•|ÕR šZ;e˜€OºÊ7-]7(]>¤¹u.˜s*³ljv9°!Zõg3£á³!“X(Â	F†ç]¡‡h(tô'¢€ğÂ;Pa%‘
NGW½¢ÿÁOºOxø¦ÅãáÌP>vu0±°ÌŒí‘¾&Ğ3ÊX­zèFbâíI¢ÛN,^¹3¶H	AÀÂ“õfã<”…Ìçöø«'aëø uLóÿş’+µj¹R]ß*W*~T×kOØÆƒb%ÒŸ¸ÿç®é¢Î£:yE·ÿÚúbü'õœîÃNş'3?÷ÿ¾Yƒñ¯lll.Æÿ1ÿQöƒíâ°÷@u@l®¯§?|¹ÿZ¹¶¹ğÿÿi‰¶¶”5ğ«OûY:ÒB±R¸[oÛ—ÿû?ıÚš€àÔ3Üõ£´*·†£|‘ÉDp:HëBAŒ{k×\Ğ­2ùy¡İÌ(45æw<úà÷ºÆÈôŠ¬9@¿ï}Í‰‚p§uè4õ¸ÜŸcó°’ƒÍXÆ[;Zí8CÓ·†€¿gùcîÚy]Ñwôn›èÈƒyC<^£ wÂ1i²&÷Ã-<©ÁÉÆ‡Ú­Ñ±Åˆ—"Bgƒó?sÑ7Ô8pÈ·m zn‚<êšZ7¶d7jıL§µÍÎŞƒmıez9†#ØCÇ•ÛÑ«¾Õ¥sv+ts{=T~Á™6]SiD1“Y•D³ŠÅî_Û•â0­®ÌWWE·¬q?ëšmáy¨€í.Ù[ˆím‘‡ÛwÏwÇ]ìêy{ûÌ²a«cÂ€ÉŞ'×ô	µ`¤khÉø
¹áÕ˜"G©Èî).z^4Ñ;f¾r-ß7m,€~Ù¹åWbF>*»–=şÀ^ïıïÿøß +Ä±E^õ)ß° £©Ü‘áÎLvhaV>nôÖ2lö[Óó®Kß5ınŸê®æç`œTûšûëãè¨qBak¸„ªññ(2\¡3xÃcÇÍ#¾_D•˜Çã:h®åéãjÄ³<k‘½Á	=‘ô•*
¡s«*è>˜ë#è,ª‡ úOÿôO€„kàê,±·¸ëö<óz„¯”¼>ÌÕ^)^+ô3¨ P©*µÓÊz½úU}ã+º~tŒQ5PãœGıãcÑ•×‚‘”‹•<G3ÚŒaç'¦ØëkIˆ¼-ô/ßÁßgì[ÅJõÙ;6ƒVPBS8>ChÃàªóÂ÷Ïi/ïÊÏŞM¬h
…ĞN0–x¼ù
 0D‡£f~¸Ëtp¦Í˜î™SwèôÌiĞ"}ªBS-…K‹"ÛÃ%˜á^Œi>ñP%ªš–=$ç:†:Oİ¦´Å‘#ic!0¥!+òºWàµ4_œVEW¾Ñ’ª È	ÉU„™ı6}cñXÔ÷èÃĞ¯VJ$,¸ÕsÎ}ŒP i"¶IÈ…½i‘6³·Ø‹„ŠĞm‚õ×<L%ÿ¤i+z ¥b¹
&†°ajİ	¬M©›<±'6™š\çÄ»Î- uFÁ·£Œ]›Âê‘Éì¨k–ùÁ ™…"éğP(««ÂÑÈ#Dø¥ü¢2–"”+œ­®ŠËc¸	^1GédÈö¡t/¹ô*.i«lEÊ)ÜSœÀçÒ ÏÉãÂ›úàœqÓ5èÕn|w#<TI’àD‘Ía™½DV‰Î‚ìËEGñëzµvçøöİqqæ…_QPèÜs…Oşœ¼ß(Ô•"éÆ	kÄBÙ$—}ms»²z(Y6¥£’š( D ™T4`IÉxªÁa&4Wl ,ãÕ$Ó%ûâöcMM'ÚjáßÉå°Å]|rşmîÉ3ØÉy7ô.AN•g5/´K¦F æ[dGŞ7svm„È5ömªš4,É%¦R-A»xŞÎ÷–û$ĞÄ¦ò”#‚ã*ßğs%õ?¸QŞˆX{â¨#£©¼3¨ ËhZ°Fù¡¿âÇ€òµ<ø”Ïh9°ÎJ”RÆ7aùáàÃŸZ /å}(¯ØSsRıá#ºĞ×ñ1®_/í5`€=3²`fX>9ˆÔ'gŒë"_`0pºÀRÛ~a©Écê¬®Ér5ğN)IÂwÑpÄ5y¾Óò¦‡EÒ‚Ù­ ¥Åd‹)…>½!¸PÂ,&cÃ©‘’ƒ<1ÅhîeXşy&ÖÒŞoáuüÄµ‘‹6¨q0*¢ÀÀóÍ3Î}3X—pé{|@H JbŠF{€e€8ß‚Ã^ş·˜W wï"âË¡„bâï3/|±Õ`S!Â]¥Pûª*}Ü7$E†Í“B˜ÏÌ˜bN¡)ğ@^+3laÙÁõY~©^5²Å NĞAtÎ­òYİÚ@»˜=CqN:KKèâD‘±¯›n·où&iÒ2™ç×GU©ÈAIuÀWûo¦Ğ®I•>¹X*¤Ş@8öÆ¤$7‹ˆ`U™b*"F+û.İì³| ì÷&†Ÿ÷„íÊk¾)÷u¦Ü×¬÷‰úÃ5
ØªµXoùqa>£Ş,q3h,{¬ëñ’È¿ƒº_¶‘ëD%†\R/²ƒ f†ô0’ùÌ¸ß%í'y>1”:=u Ä£;‹ï¼’{GCMóÖäölM˜`x8*W& Ö‘FĞ8a—ê¡¯1"Ée"‡¡Üœ0<ÅLæIŸXËä¬óâÈ˜`3Á>Eß`Æb‚Üü‰kHù(×B¾ 4aærƒÅ^¨¿@Í.·ê	¿9 ğ–¯µ8,B•pÀáÖÎ"Ç×@Á¬,Rƒ„Ÿ‘HËÃĞ:¦b2I„pïªix×˜&j7ä&2øzQp5ñ¯OÓY¿ä¶ä$âˆvhñÅ¾ç"u„'ÄáS¬Õ¤y(ôØ^21ôóÔĞ‹x6<q‘í:Y¾Bb(iATTĞWÇ¢èóOój _‚UœîÜ$i½eíKµ´v;93ñ àÊVÈüVøJ_l±™<3-‚ZBK+8å÷Í¾ì´¨)ì´”n˜Ø[±¶ÅÌô’F­îFy®»#@ŒÈÙ[0wp®p98§ĞüÄYaKÙóa·â’ÔË¥´*ÑA§’AÊ8ø
Î@œ§Èöä†rHÙ¡I#Ú‰]ãñ[GO/æŠÑ«.òy‚ªpKV¦DÙ]»ÑäzrŠ1óÔŒÉL>‘Õ³	Yo—‰g„ªU½èËu{ÎYĞå£¨ÄV'(E)•ˆs,õ²¼ê$Mc—õñ>U«úà"{e<òXªVíˆb€^L™”Ö3•µÉHNDÉNåúIÂ„&º­×&£RÚuë’˜L¡!EÍ£Uœ¤M¼kuÇxìËƒÅ•&
‚buE²@È‰3RÜñ#+‡:èY2Ç'Šè=«=F¶TÉ—IBî/NÁƒ¾Ã®BÒáPŠÑp tKÁÛX™8mWµl¦·Z²Ph4b¡–†ç5ª–ĞSNôŒÉ­Ö†ªTº‚J‘^T ğÌ+Åj¥zÆäJµXÒS{42Ãª€Ü¦VyèÌ1©}wªTBR™]=L_a“¶X»­DLxˆ7¶Ğ!¸éîè)¹YĞS³«,·å4Áú! åWªœŠ\§7îú¥óáU¥Z¬+ÅZ±ŒÁÙÙ+›5†ªÍ€›£$Q©@j±ÆQHòh•Üî „né‡ŞûJñ«bù´²¾)ó[qKLJ²|DSİSs­3j¨¥rè„cÇ8f)ZÛ@jKWDk?e\Eè÷$Z˜´t‰ãD
ÀÈ·¬„Aë`¯¹³ŸĞÇgnYb-¿éé“+åãIÊX	—}¢§ÉzœŠ·úœú
ü(ixJ¦£‡MÑûd'	¨(™‹]å1®âbYfZ†ôãôhå‰Ë"¯|0½ràäŠh»ëÌV3m^‡ 9Ÿ™%um¢‘‹Œ¥ù3çÒ$Y;YÎæÌGn¾œà„N`C>kEt5d•Ææõ€:€]%gÈ{|ã=lyŒ>~³—’‚úåP»Ğ¤NPmG§]CÒF\^b¢@±ëF¢ş_w¢~­&îV9l„Ğßj ¨'¼$@¡ff:¸ˆŸ¼$pQ}Ît ozI@Ñ$`b“zNäU¤÷ØH‰,b^	/o8S´gîãÏ”—"®1úÆÈµu¸ïïÃF/k=à::ë&·‘Àªc*œ
U‰Ê»cÃêe¹5¯or52ö')¸Œn?j“,WQ™xÇ6?¦áY°yäº+šÚBE„a“ÖŞ‘£µKä6€ø+ÏÔ¿“Ş
à¥T‰5©[ºkò#©‹¨2üFJ´BıŞ O;ÎXŒ.D‘ĞÏ&nÁPsF üæy3…ÿ6La“íŒ}0z×IŒßf­’¡‚ôû	H¿OY<¯4.Ì¾ÆÍáô î‚»‰À4‡ÀSzÁ¬'|qró¿ÄØŠ¡ka„xi9©ñÆ–òdĞğ€ÁMæV·):Ø~*x|~¥ú	a#:ÌNBÇÏÖ‡ÃP”µ÷¹TºJ•eB SËNRfcÇêjkqúÄûUµÌ%†•ë6Q²|5/ª°-M°|yJu·cx-Â •@¡	|ì>è9BDóÛz¶ãycX¦„I ‘
õŸ/pºàN5¾}¤?Â@8·ô/¹(C$8«”—Td.š%Ğ‘o_Â¿ã³e<¹€
Ë¼7İw+}ßyõR	-^P&èça‰ø!ˆ¥%8Ç~Jy¥|=“YeoÛÈPö‚óB(
 Çì»Ë“T%5Å½ñÙĞâÀèí-Ê— P:n×êâñ.†¦e
Qø«ÛdĞÕÁeÊÌkLšV‹å"ûŞK¹fÎ0 £k9Ä¢3|ö-¢Ø]]]XtÜ‹’¨Î+íîl·÷;í }²ùç¾õyé<t3Şÿ¬nÕ¶Ê•­*İÿÜ\Üÿ|”„ãO‡_òóê˜|ÿ~o÷Ë5¼ÿ¹^©m-î>Jú‹¿ùË'şäÉÑeö{)-à»'ªğçğŸÿçl ›ÇÇGâ'–øïğç¯#Yş,|ÿ·°|ñ
¨YÄ í¨óD¸K‡Ìhü/óñßößÿŸ¿»W;)1EìY¤)ók£\‰ÌÿÚVu1ÿ%-ıøJïÉ0s¶}ÆŒ	àåvzu–{ ÀÁUõæË5ö|ìÌ›õ:ÅvF$wÿ’u„l½ò¼ÕÉC™a^à}U©ç¤Xız}UÙ¨²—Ã÷ÏÜñÅÅë€ ş£éâõó@U«Eêªá|j}Ø“‰Oß<ÇÃ5’©Ù
ì¨óhõïŠ\Îş/: eo(İîY~P:·lt›=¿æĞB»ğbBüÀ³™—
Û±,òÏ¦yÌ×K_ShiÿJ».:CI3ÕáQÂ$UÁ;Íña*P'í”°FÆë¤°\‡çdjE¸•B­ˆ°{OÔÈs TL0“y1ôûÎÂ«Y×ux¬|],o«åÊ&4xŞ=A3Áô`0wÈ]ºDULÏï	§Îµíø¼n5^cèÀ¹#.=„u*å“ñoNúõ“«{qĞõ-Ëœİ^¿¡û.¿‰./•gÅ¶<|=Ğ|'ÎR“u–è¤SÉĞfˆ†Uòöó*éÀğ\+Ìéœ…(G02¢ŸJt(!3€L ºg“¯|#Œ¸¼¦NŒ»Õ\LªyÑUõ¬ÂGâålMVN¨[;GÁğGÖ7â<Ú‹¹<U ´Ozû â08îÔzI„«AÎÈü­”³B_¦õe0iïîF›Lú¤å¬øÃõeúY k†½ü ,°Ëo„ÅÏÔ8AR<êÎRé0İŠÈ¼xÎ¢ál—M´Û]cS`¡ì°Ü:;\`9ÈÔ—™”©~Ğ×¬Ê²ÊW4™Šç@¼´\8â¹à­–gW<¼…\A6«ŸÔ¨ÖÖ 5S0g”ÜİÉ¹ù„ó[ÑºŒF$ülœ¥v{4«•˜UË¤t]À‚^»5–ïÂÁK§Ïß*®‹å7ø"•¼òtÕ.zsİİm·Ûl 3ÖæOä&'ÈTl,ã‡+®Âdé:Çmcß	2$ƒ9¾»ÀÀwƒW•ÍˆìÀ3r«t°‚‡46«–ƒ<!µL$èß Ú—;Pl£<™Jü°+,nŞ®8k)Å]st; ÊASÅ»ŒğL‚¸´œÆò¥s¦êgAW‰$Æ#¥Ú÷eíàªP§VŒø>ÁKâèê!o¡à»°4€rx@¯µÏ²]»ZíX7+¾Kó›ƒãao<ü¼ÈÀGÀah¸×­328øşL}ƒ§çˆEÂ9y¡@¢Ì«–0´/t€’Ğä 9ˆÒ˜ÜŠü™ŸÜœåŸúñªÿUîæYÇŒúßZ¥V«®o®³recc¡ÿ}¤ô…ëm¡ÿı¿ÿ²½t¯v.Rb
õ¿5û§ÎÿêÖVlşÃ¯ÅüŒ´Ğÿ~^ı¯:ë~j`Õrh‚68ª
VÍ}êà»£ğSWÏ¤^ü|ê3ŒeD–hHod>6÷¸ß¦ñÃRŠA+š­Işú/z¸5fšü¿^Ù
ü¯omaü‡­­ÊbıŒÄı+n>€|‘WX$è®]ø¡*>¯‰C˜¡ø²¦¼ìo×ÅÛ&mÄåÛñöHÙ¼Ëo›ğ-Ô	ø×#´ÄÅÜkè¿şjuÚmÆ¯ètö2K·K,Ãmèë•ÚW_×+›µÍú:¤úW_Ã#Àü©ïæoŸ’İœÍ·ió¿‹ÿ±Nñóÿá:­{è:Ê·ÿRÙX__Ø>FB…]Ç]Æck1ş‘B}WÇŒãò_m«\Û¤ø/åÅü”ñú uÜ~ş×¶*ÕÅø?FÒİµ>L³ÿFu«Fã¿±±˜ÿ’bîx ÛÏÿõÊbıœ”â±w®u”'ïÿ*e®ÿ©Á¶os£Šãâÿúbÿ÷i‰é~É3Kì¥ˆ'¸'´{ì<¸ñ,].ÿ‘ŒÛ¢ğşU1|)<!¿ò¸Ad—"Uu<EQÃ¨ãm¸p¡—Éğàåøw=GîZŠ©ŸxAÚ^%ÔyæŞş¤ƒÂIGÃ3'x€„Ğ¾…ïèÛyl9ÅoôäÂzú¯?õ”?`¾uÜ~ı‡U`qÿ÷Q’*ÿ¡Õög”ÿøş«Œò_u}c1ş‘bãÏÿ9¥–âèzuL‘ÿjµõ…ş”ñşÿV¹º8ÿ{”4¯Ãê¨QÎ}îaÀVnŞÛcÆûœö8QCœÅÏ×
G+µÀÁ€0ÅJµX^ŞDl¸¯]òŠÅïÖ²¬EŞ-#F1‰f-Â=Š0×iµvY¥Xf¿b/wÑ¹Ê<ûvÏé‘C ‹gšìÂB7¼y¬Ï­aÈ`bÈØÁÏ¡ğÆn¿_^i<B3P¤”ãƒÖA1lİœ0åN˜ã)‚w¢iR†;=%ËpJ(Uy‹¦¿²,|“î7÷ÚËk,K!Ny¹l^NÔSàæ P-á¼´ôÔË²§LÁ"Ÿ!›vºùÂ$DËöW¢Pù½´\G [°×ÎæeaÏÈò“
w:»JùjXbi¤5‡—}ÕiaÁ+ó¤K«›‡”Í
,›Î›ƒ£l`2#ZæôÍ=Rbª³·O½wË‘Îø&’=ğUËfÍX${Ø»ÑÜè‘—ˆæİxöO"xì¿0wàë2%7öäo×½ÙíÈùÏßKàoVx{ƒAW+ı°–a±$Ç)ì^,ìI¥RT‚ÔúeRAì©}er…ı3­TØkX?µ? ×^:şÜKìRãÇÍ±)ò¬‚±ıßÖBş{œ´0ú~l£ïŸ¬•÷®diy"ñ#ÆÚÂú±-®+ÅJùQ-®Ã˜"{U#˜bğÖÉE`ÓéE¼SÌø‘ÖK “‘sƒ†…CvŞÓÀÆ=xÖğ³\~Ÿ¹Y(~ÿDSR8Öy×1Mÿ³[ÿ×77÷?%-ÖÿÅú?ë-/`?8gü~×b½WP˜7¼+Ó|?¸fçcôˆÍcè8ç
ÔÛäÈY¹7ßÊÍVá¿
tŸë–,~ÄB²³‚Ï^¼Úİe
ñÈİ;3Šİ>{öŒ•üáHÍWñªÏ~YÉ<@÷õY`Ù]—|pŸ¯ËkÕµÚÚúÚÆÚæºsgû¨½×Ş?n~)½*L/¯'«UêÉÕYûOˆÍØ·é°Ï½®¤Û^¼SÒ]=~P3—:¦Éğ ì?×¹ÿï-²ÿ[ÈŸæ6añúŞ-O ?£t†µ£SP¤3Pbôùi­˜$³­éâ† ˆHlªD&A”·ŠĞ#Ÿ1"’É<:™S¥0ùåÈ4Šâ{ò0½ò §õÚ¼kÀqØõÌ´)îµ4ÒPEz“å´[ùahuÉ5BQE	€1=¢-¼çÙ!×]Ò[¡“Œ|‘5{…ƒØ…ëÀ
¶}”0r®™çx¤ˆ›X–übfIËM·Yaİ
ã¤ÖµïŞ¸ç°î(N<h#^–Íÿ–"´yï|^2¡‚äÁĞÉ.ÒU^”¥g]¨ËŸ½–(>­šÚcªP1‚ÏØLNFœ3€vF·‡ì$Œ#8ŠœKÑ…Áü,ûˆ-±€d‰„kRüº'].ÂCÏÖì‘Á'†Éq®ğĞ~ŒOü9ây‹à]F‰/ÔÀAbòÊvæaû^Ã6ı+Ç}_„qº0ıL£ÖG_²Ì[Á—ße¯GfÃ³`‚›<ckp1+ó'`Ã±øÊ¼â0É‚YÜˆŠe8mÑ¬øøîgÙˆ¡8Ï´?˜]¢¹Û—-Ù½1Ïvñ(-W90gtXgÏ©à /»g¸½ƒ±?û JÔ¯B?	òz÷Üáxà[¬Ftçç^Óo“tùOnÑõFs¬cŠü‡×}‚û?Õr™Îÿj‹ûß’Ş¶÷_îì·ßeLoä`%RïˆÀK@ø™·/Ûûí£íw™N{ûÕÑÎñ÷§¯[ÍãvçôõNótï{î¶óêÍEçÆÀ›ï-’Ezˆ¤Ï`™ÈßğÖÅë˜6ÿám8ÿkäÿms«¶˜ÿ‘,ûÒ´qı>…1­D"C‡ÓM
øÜØ/Ò}Sdş{§AèÖ¹©€¦ê6¶ıÏÆ:ŞÿßÚ¬-ì%-ô?ªş'‰ş* GP…ñ¢ãJŸµ Y`?‚ú'‰V”Lx¡š¡¦{èf‚~GUP*ì9ò„Ÿ6Hõİ÷°Š Å qpØŞouNÛ|İ¤«,ÍšŒK£ôCï}¥øU±|ZY_/euåO¥!’Òíy¦tîÉU=…:õüç±Hªª)%Q´à‘‰÷°oQÔ59iK Éš¡Ÿªj(âÿ‡»G<EÒ.â‹¹Ô1Õş»V‹Øm•7ş¿%-ìµ¢hGíµ´ùğ“5ŞjNÀŒÔS·@4'áÍfÀ	ükÍéëŸªEW¦]Øë6 ûü¤Ã5xpÜ‹L¯[gÁËŒs†g
İ< ¥¸†mıH&ñúXI8Ä®İ µÓ[K‚İ…üs¼x¤¦î`Û±}õM7€|h:°P§BæŸoùs³¦EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤EZ¤Eºcúÿ7Ÿ)F ¸ 