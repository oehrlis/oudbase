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
‹ ñX„Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹„–—øæÇf ]ˆ€4Üå×”´s¢–×šD€n\wƒGâ†áGûÕoÿ?ø§Ü/pøİ/şÎÌªê®ê $AJ3‹š‘„î®ÊÊªÊÊÊÊÊÊ<³ìÒ“NårykcƒÑ¿›üßruÿ+«Ôªë•r¥¶¾YeåJec£ö„m<4b˜Æo¸€Šç˜óA¶óó	ßE;‚"éÆß÷N¡yşØ+zı¨còøW×7`Ìaü+ÕZ­¼¾ã¿^«l=aåÀ%–şÄÇé%$3Ãëg–Xa~	 åvzu–›;Øc×º4z–Çš/×Øó±gÙ¦ç±–yiœÑĞ´}öKÖFë³•ç­NÊtóÂtMËó]ÃóLVız}UÙ¨²—Ã÷ÏÜñÅÅë\Yş¦;0ìŞÜ‘Ş7†f‘§:Ó&|lı¾ãŠß<7lv`öİÅVÓË3Şz÷_t@±ë¡t»gùAéÜ®áùÛ}Ã¾0{Ï¯y÷·?¬[Í€x–#óÒò,Çe‘x¶Ã±;r<“Cz4Ã:]×ùÌwØ…	ÿôMfÙĞ4»k2ŞBfxÌ5ı±ÍºNÏÄp|Ó“Ø÷a=~Ë\³±göØ¹ã2Ó¾´\Ç¦A…Áé;cŸ¿n jøDxŸÃ°Bm¬ïû#¯^*]@ÎñöN‰÷˜‡,HÜœû°B÷°ï€ª÷ºåJ±üu±Z®l2Æ€£0¶c[¾eØ¥éb7BJµX©`-™§Ùû¸ö!£	¿0³c3ç)Z|€ÉY`ÛP©3´~4|@ì>Ğ3æšl¯Z§GÇ§­ıFî£òT/dlüœzEÇ½ÈŞm»‡m¼?×‚92øìµ1›Ş=”yİ>êìì7`43­ƒæáa{¿ÕÈ½jgÙŒi	h×8˜là\°s~£‘	Œ`??è´ÙÍİÎàmœÁdCœMí£ÃãÓıæ^»‘[A
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
,Õ§iğRp<4“‰¾Y½´~Nêeaq,z+bq<»µqº¥ñóÄI}£â™ŠE-w6(nLÓù§“^b“g°ˆÛÍ±ï`¨œ®%hIÃ´ì1gĞC{=†²-ó	–â)Ì-²øO³Oh¢…h¨ÒÇ,uI±N“IâfäîÜä™8ıd&½ûÚ„sg²şŠyQŒH	HçSvdŒŸ9™zô¦Ş·HŸÛÔö‹Lhü[<Ô¬RÇdûïry½¼‰ößë•òÆz­²ÉÊ•Úf­º°ÿ~”ôó—OşüÉ“=£Ë:ì÷’5á»'ªğç_à<ÿÙ¿™dóøøˆÿ¢ÿşü»H–%Şÿõ“'rxÑfq`x> ã^~é°#`üküëÉ“¿Ç|C£ëâ
hâoÀİô¡ñ¬Èû<ïßEò¢óÙÀÜ±{æ‡'OşCáßÿ#æş¯ÿù¿ü[ü·ò(„öe&-¢ĞÕ1yşoÔ6¶ÊÑù¿^İZÌÿÇH‹ûŸçşG`‰ÿS¾ûÁ•Stï	˜2àQxs#Ntqä!n”ã·@z°»©~"èPañø ßÇMƒgá°ø\B9{N÷½é&ŞA ¦ŠP=BG¨	ùùŒ•ï^Ï»ƒç|3¡=>qÅ®1PÛ5Q­‡f.—†k¡á‡;ÿÕµü"´Ø6]?2Èîjˆ4¯œã™¡a”õaSîšx^û* geŠÈº¤­21nü°†{NËfEdÍ§#×Á1*ò:ûâ0k0‘møD~*¾ñí!…#“VIjÍì‚‡(ùÆ©»›»»§Û¯:Ç{;ÿHñ”Š…r:IQJO‘5•Ú'”Q!’OâXëááËèp0T/®a¼í@Ô_—Ë%Kåå0¥]H˜Ğî‰ „`4¢À®ôQÔXNËÖ„btìŠEšv\ª¢œ9¦â'‘)Y
”&eƒh·Ulÿ§ÃäÕQAÛ xN¨wbihõzóÊpMô‹½7ü@cY‚÷Ûæë¦Š¨ï fÖ‡KY¥1O8”ÆÀ7]Æç’_J«S”ˆ¬	9¹¶Aœº'Ã3ın)ªŸ
ÖrˆGp&Ü30ŒÇYÈ5Ú*oñøŞ¦8÷ëÛÄIşìAîÌµ•ÕûuÀ4î†wuL_v5° ºBÎ„FvĞİ×f»óÎù¥ŒPw@'óÒ/J^¾WæK#0«À'r ZÈİdœ´Ğˆƒg‹Frïl7w*4Nvšõ,oW–	Kx&bÌ0¬HLZKnLÚèÜ$‚!·/‰ÀÂ/t¢ƒS^CÓó&ç|ÊG:ùFØáø„…y¡Ö™h®LÖÃÂÈ‡)8¡åa–k<,¹Ğ–´G9AY’şâßs¥Òò§>€‚¬’W¤sÅ'ùæ®xyÃÂÕÀó‹?ài!G¸\Doå¤ôö'¥w¿Ê¬İšJv#¸v¾ï·÷N‘ãË‚liì¹%ä´¡Å·k	?|Rc@ìÇ†V¿ë…Ü
¶c`ÙïÑ +¹±¹
©mGv.ú€– 9,¼9•¼j˜ù‰a‡da/€›[Ì^¯gó@*~í2\ãÉ´E4¢Õ~Ñ|µK„ÚÛÇGßŸr“>2£’yôo¹ú¢Ñd8«Ç;zÏƒÉ"Z|Î–ŸŸØËy²Á¡/ºõM2¦­N»-LœÎ¥Éíğ-¨°!SÌw>©MPæŒÏI‰¾ÅçáBT×ÒÆ7ŠÑ¿!"y^0—…gŞá¾ÍE"s¿GŸO¢Ë¹EFƒî#Bí]º*aÍfwLh”„eHPğàÕÑv»…ç”â'T~áVè|pÅ¹QÄ2¥üƒÛ¨k8%İ÷8I¹ğÁñsaIp~£qÄC‘ˆWH$¦ÁÇÄøñ#qF§ÁQ°êª»Ğš?±
f„'Æƒkie‡ê
“6¿CóÌsËõ|…¶Ôze¸îšİòeÄlAZ7¬00#¶Ûá"Şi¾n·N8Ğ1şs£Øü:Ã\ñ³fK€Ğ3‡D y9ÊÎ(µoµQ—B’„Ûy/²
ù‚D¨’Óx¸oÀ™¯#è[´0CÑ[¶’4Òœ*«!Ù)K"—–ûÜ(™ä¦$sĞ³Éà¸¤4ÏƒÀô>å6ÍØ£Áèì\±6–]™™Åb;B%)f×Ñöh9±® 'GvF#tAaª±$¿½ù=ÃE­dáìj4`8Y„f¦º9ù×áÊÆ¬vã›×àã¢é¯@köÙ)zŠ«™®“ ›Y†4¥N1W«õlÂşEBºÑúÙ4[õÈ °û¯+”!6°b©àR« “ Ÿ¡ï8óæÄ¯ĞNŒR¤LªØ>%Œº	ÌÏµªÒ&ósÑ’`"Ï…S¨/áâD„înMsiôv{Z»+Í›Æˆ¾ì¶ºh¯$ô3î)¢+ş–L”Ê“¸-õün‘L¦nşú(É€,@Ş¬êSŸßH3U^)MVãx Á¢Â}fY(€yá´ '*IÍO@fBó" øÎáÎ ÛÑ·!hÒª¬B¬Ü¨{¯9^FüR]÷ğÑ0HÀ{ìcôˆ”ü°õ„ÓÕd)æŒ2¤7gÄ®ÛÓ¾yTŒãÃ0¿Âûˆ+©×-–ÕëËğE7Læé6W0RËãµ}ê©—3’Š…º©åñhùnaÉŸÑZr™ÔTáj+%Áç{Mx%Ôûâòlİ¼st*{Îy¯91›`%ã¯­Û‡Ê÷RSÍŒºt‰R‡¯Ù‚g€–„¢9;¬„ü-ƒHcâ ‚®?« ø©Ú)j|R ñ¤
Á‰CÅâÈğû:P¾ÈŞt£bbÈ[Ñr‚©Çì·S}‡¨¯äÂÎÏÇJó1g1â€’ 0¥âPÿ5¡Şg¢¯:}·Õ<d‡ÈI™R:OÌÚÑóŠ¬§În,{“®$f'=|¬À‘r—@“Ú‡Ñìóã‡pÅ¢2äñ(Î‹U6,ø5ˆÌb—Ë´ƒ×9b…­½-7æıŒ™øí3¤TúÀi‰áÈtB²ArL$­!¬{LJ
Rn'ßô“i^ë	O÷]U(¸¶XÓ–n¹¨`Z’›u§o+ÇştP­æçbº¶@ÆÏÈ}´n‚%<Åz>òîÀªq`ÈZî°–.€Ú‰É]ÁnN{»ƒRpªRØğØÓB¥ŠoÒÏuüÛÃÍN|
O &ó‰÷Sd§¿‰ @rOŞMæ¬õ &>ÁFå„G½›>ò¥ä®UmLÁA._ wí°ÓÈ…÷Ş¸<èÆ"U¹'ÙwÉLjÓ¿\Úõ,EÖH½‰¥Ï­ô,W\IVÏøBW­¶Ğ:ñ„ÉZd‡•5Ò`nÀÍé”B©÷¡R<><*±sN,ĞwLâ±ŒxTlL>}ùn`Æ‰ËÅŠŸÆ”Å{Ã;/éS,¾…‹îÿ\–ãPG4¾JÚJaÒs²Á°Ùr‰Ä{’ÄÉŞœ{ìsl›„•ÒZé¹ÒhYb¬{=¯Ğ=¿( *Ó´)¢’XüPÓ–¸LÇê•`}ßÑ%ŞyÖ&„­ÆÎW	[X#ÕË<{õ–IUÌÌ‘®±ËçZòIò$œ¡ô#´hÃóH/nG¦é Xªcç¨
‘*ÒHHëaHÉ/rBJí«¯“óp‚dÌ»YÛLÉK#ùQş„¼_}­Á½;ç½OÊ&ñò¨îa‚âA)İÕÇ¶ô‘¼ê¶>qO¯äîëS6õJ‰èÆ>qW?ÿ^|ŒÕm<Â‚§b¿[áøgšxXûù—°p5Ú¶˜62á\:.¦îœÄöÖºŠ)Oóä™°¢Ÿu«‰X«Å²¥HÁR÷ä$òªNôSè´®P`= ­zNï–¬Ú¶Y¥Q¼²UûNÒ™²^nN?{–†süB?ú.ôÍA‚>K;[ ,ò¢•êÿgÎæÎ’ODì,î-›‘[Ùl{ÿõı¬ÄC° $’uû)ˆàè"„Y(H_°KÆMXH'„°ş>R(~c€’ïïŸ,›²ãûHvıJ˜]{?‡2ñ¼Lğ>’?~Mƒç—ï#Ùã7ˆxvå}r	å
ŠVB¾/,C±åx9­)}ï­Ia1Z	åı„"²QÑ"‰Šîo’Ê% ˆ¬-Ê!±¾OÈ*b¶Æ²ò÷I€m&ÁÆ÷IÙ÷&f‡÷Zv•Èğ7Í‚ôøAˆ?à‰BŒhj­Ñè18ğúâæä5(ò´7ˆÆA‡¹Á‰‚<â• õ²Ä¨™^V½½Bß•ªûañ‹QØ}/aÀÅ	¥F´xŒ×záôµbêÁŞ”ÂÂQ/:v‰ØéÊ§ü²]@M2VÅä—ˆî7~‘;ñ¥9ìÛÑp…–ğÛ?Ä!kr'öCVªhñe¦@|iŠ
ÌFyW{÷E$¯æîN3ğÁKù•{huã­Wó•å,ü÷)›/®’İ÷”èÛºSa¬,!ŒÜ§%`ò¹ÒIµ´œ å£øÛ'˜6ÊîI¨°aÄŸ*e¡´Î&è¤s©Q)êjşF€
h®ÑœHÊè“™ñÃ‰ÿ.L<ƒNUmA~]²a(­£
ß¤Ã¯êìğ:zp%uUÇ†)¯«™pû İ©JİèjZ­ÆÉ¾¢ŠZ-¾M7xÓ•¡ÕĞ‰ ;B‘BsBiÛûæs#§7y‰]Û¹¢|G¦KDß+<ãmR»–r!tÑÆ¤¶¿{1æ³64ünMÃFæbøĞ »gÑn³K@ÑÔË—–ù"Ì„ãÂÁø 8Ÿè­‚­¸&E\T
+³>ì„¬¢ß_+K´„áes·Ç1»2á›;Ğ\ãLQ†½(qxã\–ç,±ğ#Ëñ.¥æÇv¡²»Uó”Ø..ÌTÀbÊî™,¬WiG)¯‰ë·Œ÷×£í:ĞÉ+0.A÷ùı°û$‰RÀÓ2œ…
è& èàğ4Ÿíqy0(k¢zûü²íØ%åxá¸W†Ûc6™ò$8pˆ‚ç[İ÷=uDë˜ï@Ù¾˜-b|le|(Ö §Tï¸H?¨™åœúDH¨œô]ƒytşA¶¤Æ ^ÏGH½¢¯%b›.éâABxÌ/‚rB Ìx© hEŞüá+Ò?Mçjf£æE=dšÊÅ‚¹ëz¸…®m^iÂfšgüá™õ´s|4Ëa½†CpS3 ÿ¨Vr£œñ+ÅÇ”U½€8£˜R¨)$p¦[ã‡S
m„…b†SŠn¦½›±C’µ³¼İ™`„1E.Ä_¦ SÅˆ©¦6U?åiPj‚™¢´ïVğĞál¥˜’Íéç´ÉG÷Ù|’@Ú©Hú	LÚÙHô½>ˆ
ŸV./N¯R¢*zI»À×K¬)áĞ—C=0UE÷úwKÌy“XLÁH´É4 ¦¶ævCuÅn¨®ÙÕCuşÎxôõ,urW5§è×ÙˆŸ^ºæ¥Ëµ!¼¾-ã·¸¹sX`0r M¶í‘ªï°iî˜A04¹èLyµkd,p­ZveEi
¯v¨¤ˆ¡–¤x"Zvëe;¸»3‡ÙùN±Ï>CæÈ½?ñ>½ê—uQºÃûÑò–sxwZŞ>³ìzªÅŒø¨ôd]½•.¾óØX+wü§z§£x…ÂVÆ%GIÊi˜–¯ŞÎï
wz%$}VÓó¡ —bp­I tl"°¦!ÍÜ³Çú}ãHzşø\à%uizSø‹Köo„„kpÕjêõë)]Ï§\ôJ¾p)PM-Ï]3LÀ']qœˆ–®a”Ò‡Ü:Ì9‡Ù65»Ø-ú³™ÑˆpÙI,á#Ãó®PD4ºû“Q@xáM¨°’H§£«^Ñÿà'İ*<|ÓâQqf(»@˜XXfÆöHèåF¯ˆ¶At/1ñ%Ñm'5‡G^ˆ™l¤† `áyz¿qª…Bæsûı•IØJ>hÓü¿£¿äJ­Z®T×·Ê•
ƒÕõÚ¶ñ X‰ô'îÿ¹kº¨óÄ¨NŞCQÁíÇ¿¶¾ÿÇI=§û°“ÿÉÌãÏı¿oâøW66ãÿ(	Çÿ¨;ÁvqØ{ : ?6××ÓÆ¾\Œ­\«-üÿ?FZ¢M-eüêÓN–ÄP îÖÛöåÿşOÿƒ6% 2õ·gı(­Ò­áh€gdrœ.’ÇºPãŞZÅ5t«L~^h3
M•ùıN†>ø½®12½"kĞïûE_s¢ Ü©c:‚Æ ME®÷çØ<¬ä`G3¶ñÖ„ÅV?ÎĞô­!àïYş˜»v^cWôı„Û&:ò`Şç¨ÅÈİ£pLš”ÉıpOêA°D²¢vAktl1â¥ˆĞÙâÀü@àÏ\ô5òíc[ ¢› ‰º¦Ö-ÙZ?Óio³³·Æ`C¿F™^aÀöĞqåFôªouéœŞ
İœã.Õ^°[¦í‚ÁG×TQÌdV%Ñ¬bqÀ€û—ãv©8L««#óÕUÑ-kÜÏºæA[x'*`gc»Köbc[$GçáÆİóİqû€º@ŞŞ>³lØä˜0`²÷É5}B-iÀZÃE2¾Âcrx5¦ÈÀQ*²{Š‹Mtç™¯\Ë÷M _vn9ÆU„˜‘Ê®e?°×{ÿû?ş7À
ql‘W}DÊ7,èh*wdx£3Ó…†Z˜•½µ›ıÖô¼ëRÇwM¿Û§ú…«ycà9'•†Ç¾æşú8:jœPØ.¡R|<ŠWèŞğØqóˆïQæñ¸škyú¸ñ,ÃZdop‚@O$}¥ŠBèÜ*ºæú:‹êáãˆşÓ?ı áºÄß ¸úKì-î¿º=Ï|‡á+%¯sµWŠWÆ
ı*(T*…Jí´²^¯~UßøŠ®¢cTTÃ8çQÿøXtåµ`$åb%ÏÑLƒ6cØù‰…)öúZ"oıËwğ÷ûV±r}öM„Ç „”ĞTÏÚ0ø†Š¼ğısFzÅ»ò³w+š‚E!´3Œ%o~…(Ñáè…™Ÿî2œió@¦{æÀÔ:=s´HŸªĞTKãÀR£Èöp‰#¦c¸cšO<TÉ„ª¦%EÉ¹á…FÃó¶)mqäÈEÂXLiÈŠ¼.x-Í§UÑãU o´¤*(rBragæE…FßX<õ=ú0ô«•É®aõœs#È@†ˆmraoZG¤Í,Æ-ş"¡"t›b½ãõ SÉ?iÚŠH©X®‚É£¡l˜Zwk`Sê&Oì‰MæŸ&×9ñã®sAHQğí(ãD×¦°zd2;êše~0Hf¡H:<Êêêp´òQ>G)¿¨Œ¥å
g««bÆò.D‚×BÌQ:²…}Ã…G(İK.½ŠKÚ*[‘r
÷'ğ¹tÀsòø†ğ¦¾8gÜôzu„ßÀÕU’$ø€QdsXf/‘•F¢³ »ÀrÑQüº^­İy¾}Ew\œyáWT :wà\áS 9'Ï7
u%ƒHº±Â±P6Ée_EcÛÜ®¬ÊF–Mé¨$†&
(h&XR2jp˜	ÍU#Û(Ëx5É´ÄcÉ¾ø‡ıXSÓ‰6…ZøwrYl@qŸœ›{ò6Fr#Ã½SSå™FMÀíš©èƒùÙ‘÷Íœ]!r}›ª&Kr‰)¤ÔFKÒ.´óıeÇã>	41‚CF„©<åˆà¸Ê7üDI}Ãl”7"Ö8êÈh*ï*À2š,ƒQ~è¯ø |-<å3ZP¬³R¥”ñMX~8øğ§ÈKyßÊ+öÔœTøˆ.´gçÂu|Œë×K{E`ÏŒ,˜–ON"õÉãz£Èœ.°Ôv£_DXjòx€º«kF²\¼S
A’ğ]4qMï´¼éa‘´`v+Hi1ÙbJa…O¯D.”på ‹ÉØÀpj¤ä OE1š{c–‰µ´÷[x?qmä¢*AŒŠ(0ğ|sÄŒsßÖ%œFúˆ’˜¢Ñ` Î·à°—ÿ-æÈÇİÃˆør(¡˜øûÌÄcl5ØTˆpW)Ô¾ªJ÷I‘a3Æ¤†33¦˜Sh
<ŠÁÊ[Øtp}V†_JƒWl1ˆ…ôBİ‡s«|V·3Ğ.vÏPœ“ÎÒºHQäAìë¦Ûí[¾Iš´LæùuàQdU*rP’Eğ•ã¾ç›)´hR¥O.–
©7Ğ#½1©ÉÍ"âÃXUD¦˜ŠÈÑJ¿K7-(û½‰áç=aõ‚òšoÊ})÷uë}¢şp6„ªDm'VÄ[‚\Ø‡Ï¨7KÜËëºc¼d²Æ/Ñ îW……mä:Q‰!—Ô‹ì ˆ™¡ı£ Œd83îwIû	EdL¥NOİ ñ¨çÎâ;¯äŞÑĞE£¼5¹=[ÆÊ•	ˆuc¤t#NØ¥€z(Ä«GŒHr™È!A(7'O1“ùÄ£ÄFÒ'Ö29kÁ¼ø2&XK°OÑ7˜±˜ 7âZR>
Åµ/MØ…¹ÜT±ê/P³Ëã­zÂïH#|‡åk-‹P%p¸µ³Èñ5E0+‹Ô á§$Òò0´ƒ©˜L!Ü»jcŞUæƒ‰Ú9É¾^c\MüÆë×tÂ/‰…‡-$9	„8¢Z¼C±/†FàùHá	qø;5©CG
=v…—Tıü5ô"A\d»@–¯‚JÚôU“±(úüÓ¼À—`§;7ICZoYûÒD-$­ÄNÎL<¸²…ı1¿U¾Ò[gl&ÏL‚ Æ£ĞÒ
Nù}óƒ/;-jD';-¥›D'&öV¬m1½¤Q+†»QëîP#röÌœ+\ã)äã4?qVØRö|Ø­¸$õr)-ä‚JtĞ©dEG2Î¾'†Âƒ3ç)²=‡ù€¡RvhÒˆv¢g×x<ÅVÄÑÓ‹ùbôª‹| j\Ä’U‡+QöD×öÃÇC4¶œbÌ<5c2“OdõlBÖÛeâ¡jU/ºÆrİs´@yÀÇ¨*±Õ	JQ
A%âK½,¯:IÓÃÁØ%C}¼OÕª>¸È^B<„ªU;¢ S&¥õLem2’ÑCE²S¹~’0¡‰nkÁµË¨”‡İº$&S¨cHQóh'iïÓZİ1ûò`qA¥‰‚ XİC‘,r¢Ç„€” wüHçÊ¡z–ñ‰âzÏj‘-UòÀÇe’û‹Sğ ï°«‡ôD8b4İRğ6V¦#NÛ•c-›é­–,X¨¥áyª%ô”=cr«õ…!D€*•.… R¤ <óJñƒZ©1¹R-–ôÔLç°* ·©UA:sLjß*¤TfW“ÇWØ¤-Önkçâ-4Dˆnº;zŠFnôÔì*KÇm9M°~@yà•*§b#×é»~é|xU©«ÅJ±V,ã@pvöÊæG¡j3àæ(IT*P Z¬q’<b%·;¡[ú¡÷¾RüªX>­¬¯GÊüCÜ“’§lÑT÷Ô\ëŒj©:áØ1Y
‡Ö6ÚÒÑÚOWú=‰&-]â8‘0ò-+aĞ:Økîì'ôñÄÙ†[–XËï†Azú$ÅJù8C’2VÂ5Ÿèi²„'€â­>'¾?J’éèaSô>ÙIÂ*Jæb„CWyŒ£«¸h–™„–!ı8=Zyâ²È+L¯8¹"Úî:³ÕL›€×¡ÀHÎg¦gIİc›häb#ãDişÌ¹4IÖN–³9ó‘›o''8±ØÏ[EY¥±y= `W	Çòßx›c£ßéå€äU „~9Ô®2©TÛÑi´—×—èîOì¢‘¨?ÁW¨_«‰»e!ô7„Z (êI/	P¨™™.âg/	\TŸ3hÄ_Ğ@c4	˜Å¤yé=6R"‹˜WÂKÎmçûø3¥ç¥ˆkŒ¾ñrmîûû°QGÅËšF¸„„ÎÁºÉm$°ê˜
ç‚BU¢òîØğ…zYnÍë›\ŒıI
.£Û‡Ú$ËUTf Ş±Íixl¹îŠæŸ¶PaØ¤µ7Däh­†@ÇÃ¹ şÊ3õï¤·x)UbMê–.Æš|ÃHê"ª¿‘­‡P`¿7ÀÓ#Ç3£‹Q$ôs ‰[pÔœ(¿sÂL!Æ¿ÍSØd;c_ŒŞyÒ ã·Ù@«d¨ ı~ÒïÃSÏ+³€¯…qs8=ˆ»àn"0Í!ğã”Ağcë	_Üü/1¶bèš!^ZN*Dü†q¥<4<`p“¹Uà­Š6¤_Â„
Ÿ_©~FcØˆ3„“ÑÀq´5Äá0eDí}.•®Re™èÔ²“”ÙØ±ºÚZœ>qã~EU-s‰aåºM”¬ ß@gÍK…*lK,_ Rİ-Ä^‹0C%Ph»zÑ<lãö‚†íxŞ–)a@¤BGıgãœ.¸S@oé0.Dà-ıK.Î	Î*å%™‹f	täÛ—ğïølO. B†Æ2ïM÷İJß÷G^½TBD‹”	úyX"~bi	$Î±_ R^)_ÏdVÙÛö2”½àÀ¼ŠÀ1ûîÀò¤U‰gÍcqo|6´¸1z{‹ò%(”§Ûµºx¼‹!†i™ÂcşªÇÆ64Â@5G°D™2ó“¦Õb¹È¾wÆÀR®™sF‡ÇèèZ±(ÂŸ}‹èvWWWEƒ ÷¢$ªóJ»;ÛíıN» @Ÿlş¹o`}Ş„F:]ÇŒ÷?«[µ­re«J÷?77÷?#áøÓá—<Ä|€:&ßÿ„ß›òşïzy£Vƒñ_¯Ô¶÷?%ıÅßüå“?òdÏè²ƒû½”ğİ“¿‚?UøóGøƒÏÿs6Íãã#ñKüwøó×‘,¾ÿ[X>ŠxÔ,b€vÔy¢Gİ¥Ãf4ş—ùøoûïÿÏßİ«‹”˜"ö¬RÇ”ù¿µQ®Dæm«º˜ÿ’–~G|¥÷d˜9Û>cÆğr;½:Ë= ààªzóå{>ö@æ‡Ízj;#’»É:B¶^yŞêä¡LÇ0/ğ¾*†äó@R¬~½Æ¾ªlTÙËáûgîøâbu@ ÿÑtñúù ªÕ"OuÕp>5Ç>ìÉÄ§oãáÉÔlvÔy´ú…wE.gÿÆ€²7”n÷,?(Û6ºÍ_óh¡]x1!~àYÌK…íXùgÓ<îëÆ¥/„)´´¥]¡¤™êğ(a’*ˆ`æø°¨“vJX#ãuRØ®Ãs2µ"ÜJ¡VDØ½À'jä9Ğ *¦ É¼Çz‹}gáÕ¬ë:<V¾.–·ŠÕreš<ï ™à@z0˜;
ä¨
¡*¦ç÷‰«„SçÚö|^7¯1ôàÜ—¾Á:•ÆòÉø7'ıúÉU‰½¸æzÇ–eÎn¯ßĞ½†_ŒDg—J†³†b[¾h^g©É:KtÏ©dèF3DC•*yû‰y•ƒt`x®ætÎB”#ÑO%:”@&P³É× ¾Fl
^S'Æ‹jÎ%Õ¼èêzÖá#ñr¶&+'Ô­£`xƒ#ëqíÅœ* Ú¿'½}
 qwg½$Âİ NgdşˆÖ	ÊY¡€¯ÇÓú2˜´÷—£M&}ÒrVüáúÇÆ2ı,‹†5Ã^~ Øå7Ââgjœ¡)u7©t˜ˆOEä^<gÑ…‰p¶ŠË&Úí.†1Ó)°„PöXîFİ.°dêËLÊÔ¿èkVåYå+šLÅs ^Z.œNñ\ğVË…³+ŞB® ›ÕOjTkkš)˜3JîîäÜ|B†ù­h]F#~6ÎR»=šÕJÌªeRº.`GA¯]ŒË_áà¥Óço§Åò|‘J^ù
ºjı¸îî6Ûm6€™kó'r“d*6–ñCWa²tã6Œ±ï’Áœß]`à»Á+¿J‚æDvà¹U:XÁC›UËAZ&tŒo íËƒ(¶QL%~Ø7oWœµ”â®9º å )„âİFx&A\ZNcùÒŠ¹Qõ³ «ÆDã‘RíûÆ²vpU(ÈS+F|Ÿà%qtõ·Pğ]Xš@¹ < ×ÚgÙ®İ­Çö¬›ß¥y‰ÍÁñ°Š‰7~^dà#à04Ük‰VÏƒ|¦¾ÁÓsÄ"áœ¼P QæÕNKZˆ:@Ih
r
PÈDiLnEşÌOnÎòOıø@Õÿªwó¬cFıo­R«U×7×Yİ?.ô?“¾pı¯-ô¿ÿ÷_¶—îÕÎEJL¡ş÷¡fÿÔù_İÚŠÍøµ˜ÿ‘úßÏ«ÿUgİÏS¬ZMĞGUÁª¹ïB|w~êêà™Ô‹ŸO}†QŒÈéÌÇæŞ÷ÛÔ#~XJ1hE³5ÉÿCÿE·ÆL“ÿ×+[òü·º¾µ…ñ¶¶*‹õÿ1÷ÿ­¸ù òEV\a‘pW¸vá‡ªø@¾&a†âËšò²¼]o›´—o7ÄÛ#eó.¿mÂ·P'à_Ğs¯¡ÿnø«Õi·¿¢ÓÙË,İv.±·¡¯Wj_}]¯lÖ6ëëê_} ó§¾›¿}Jvs6ß:¦Íÿr,şÇúÆÆæbş?FB§u]GùÖñ_*ëëûÏÇHè¯ğ¡ë¸Ëøol-Æÿ1Rè±ïáê˜qüAş«m•k›ÿ¥¼˜ÿ’"^B¤ÛÏÿÚV¥ºÿÇHº»Ö‡©cöñß¨nÕhü76óÿQRÌïÔqûù¿^Y¬ÿ“R<öÎµòäı_¥Ìõ?5ØömnTqüAü__ìÿ#-1İ/yf‰½‘„÷„v7¥Ëå?r‚q»Aüİ¿*†/…'äW7ˆì’A¤ª§(jb<Â ®1ô2¶ÿ®çÈ]K10õ/HÛ«9ÏÜÛŸt=x¢3éh`æĞ‘àÙ·ğ};ÏÑ“!§ø\øOOÿõ§’ãÌ·Û¯ÿ°
,îÿ>JRå?´ÚşŒòßÿo•Qş«®o,Æÿ1Rlüù?§tÀR]Ï£)ò_­¶^Ãñ¯ĞŸ2Şÿß*Wç’æuX5ÊÙ±Ï]#ØÊÍ{{¬Ã£ÀxŸÓ'jˆ¡øùZáh¥£8¦X©ËëÃ›¨÷µK^±øİB–µÈ»eÄ(&Ñ¬E¸Gæ:­Ö.«ËìWìåá.:W™gßî9=r$pñL“]Xèâ†7õ¹5Ly ;ø9ŞØmá÷Ë+GhŠ”r|Ğ:(†­›¦Üés<EğN4MÊp'¢§dN©¥Š"oñÂôW–…oÒıæ^{ye)äÑ)/—ÍK £À‰z* Ü  Š¡%œ—–zYö”)Xä3dÓN7_˜„hÙşJ*¿wƒ–ëtöÚÙ¼,ìyY~RáNgW)_ËS,´æğ²¯:í#,xetiu³â0ãƒ²Ye³ÓyspÔ‚Lfä"BËœ¾¹GJLuöö©÷n9ÒßD²¾êcÙq Âì¡Y‹d{7š#òÑÜ¢;Ã¯ÂşIıæ|]¦äÆƒÜáíº7»9ÿùb	üÍ
ooã èj¥Ö2,–ä8…}Â‹…ı1©RŠJZ¿L*ˆ=µ¯L®°¦•
{­ë§öà:ĞKÇŸ{‰ı¢Sjü¸9Ö1EşƒU0¶ÿÛZÈ“Fßmôı“µòŞ•"-0ÏA$ŞaÄX[ØC?¶Åu¥X)?ªÅubSd¯jSŞ:9£l:=£ˆwŠ?Òz	d2ranĞÃĞ¢pÈÎ{zâØØ Ïú~–Ëï37ÅïŸhJ
Ç:ï:¦éÖcëÿúææâşç£¤Åú¿Xÿg½åâçŒßïZ¬÷

ó†wešï×ì|Œ±yçœBºc›9+âæ[9pâ¯Ù*üWîaİ’ÅXHvVğÙ‹W»»¬@Á"~¹{gF±ÛgÏ±’?©Ùñ*^õÙ/+™è¾!,»ë’nãóuby­ºV[[_ÛXÛ¼Swîìoµ÷ÚûÇÍ/¥W…éÅãõdµJ=¹:kÿ	±ûï6ö¹×áÏ•tûÏ«wJºë¢ÇjæRÇ4ùo„ıç:÷ÿ½EöùïáÓÜ&,^ß»å	àg”Î°v”c
ŠtJŒş1Ÿ"­“d¶5]\Ã‰M•È$ˆòVúbäÓ! æQD2™§B'sª&¿¼™FQ¼àa`O²Wô´^›w8»ş€™6Å½ –FªHo²œv+?­.¹Fˆ‚!ªè1#¦RÔ …÷<;äºKº€b+t’‘/²f¢pĞA »pXÁÑ¶OƒFn£Óµ3óqs Ë’_Ì,i¹é6+¬[aœÔºöİ÷ÖÅé€mÄËr¢™âßR¤‚6ï]‚ÏK&T<:ÙEºÊ‚²ôL£ëuù³×ÒÅ§UÓA{L*Fğƒ‰ÀÉˆsĞÎèö„‘ ÀsäG‘si z¢0˜Ÿå¯q±%¶,±“pMŠÿB÷¤ËEØqèÙš=2øÄ09ÎÚ1à‰?G¼3o‘¼Ë(ñ…x HŒ@^ÙÎ¼1lßkØ¦å¸ï‹0N¦ŸibÔúèK–y+øò»ÌñõÈlxLp3ƒgl.fe^âl8ŸB™7P&Y0‹Q±§-šÿ ß½à,1ã™ö³K4wû²%"»7æÙ.¢å*æŒî ëŒà9#àe÷·w0öGc¿T‰úUè'ÁBŞQïâ»1|«€ÕˆîüÜkúm’.ÿ‰Á-ºŞhuL‘ÿğºOpÿ§Z.Óù_mqÿûQÒÛöşËıö»Ì‘éŒ Dêx©ÿ/óöe{¿}´³ı.Óio¿:Ú9şşôÕa«yÜîœ¾Şiî}ÏıÁv^¢¹HãÜxó½E²H‘ôù,ùŞº˜cÓæ?¼çü¿mnÕóÿ1’e_š6®ß§0æ±µ“èAdÈàâpz¡IŸûEºoŠÌÿqï4İ:7ĞTıÏÆV ÿÙXÇûÿ[›µ…ıÏ£¤…şGÕÿ$ÑÿBô* 0^t\é³À#ìGPÿ$‘ÁÃj€’	ï!”@3Ôt=ĞLĞï¨
J…=Gğ³Ñ©¾ûV¤X 4Ûû­Îéo›¯›t•¡‘¥Yóƒqi”~è½¯¿*–O+ëë¥¬®ü©”‚#D’Aº=Ï”Î=¹ª§ĞC§ÿ<¶ IUÕ3¥¤3Š<2ñö-Šº&'m	$Y3ôSUEüÿp÷ˆ§HÚE|1—:¦Ú×jû¯­òÆÂÿ÷£¤…½Ví¨½–6~²Æ[-À	˜‘zêˆæ$¼Ù8­9}ıSµèÊô {İtŸt¸{‘éuë,x™qÎğL¡;€ ÷Â°­É$^ÿ+	‡Øµ´vzkI°»ƒÔÔl;¶¢¾éMêTÈüó­ nÖ´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´H‹´HwLÿàa…1 ¸ 