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
‹ ù„Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹ä,	.ñIRaÚ…HÃ]~AI;+jyM IôèÆu7Hq(nøÁ~´_ıæğ/ğƒÊı‚¿ß‹€3³ªº«ú Iš®Ièîª¬¬¬¬¬¬¬¬¬SË.?yàT©T676ıû”ÿ[©­óEbÕµÚzµR][Zc•juccí	ÛxhÄ0=ßpÏ1'æƒlgg¾‹vÿşHÒ)ô¿3î@óü±WòúPÇäş¯­o@ŸCÿWkkk•õèÿõµêæVy \bégŞÿ¿(#œ^?·ÀŠóK mq»Wg‹s{äZFÏòXóÕ*{1ö,Ûô<Ö2/Ì3š¶Ï~É:ãÑÈq}¶ü¢Õ)@™a›®iy¾kxÉjÏVÙ—Õ{50|ÿÔŸŸ¯²Î¥åoºÃîÍé=ch–xª3mÀÁÇæØï;®øØñÍ3ÃfûfßXlÙ1½óè]É¡w¿ñJ]g¥Û=ËJ/î¿Õ7ìs³÷âŠ“¿eøaİjüÀ³š–g9v,‹üÀ³Œİ‘ã™ÒàÖéºÖÈg¾ÃÎMø§o2Ë†¦Ù]“ñ2Ãc®émÖuz&RÂñMObsÔ‡~ô8ø54,{pÅÆÙcgËLûÂr›::§ïŒ}vô¦U„ªáá}İ
µ!°¾ï¼z¹|9Ç§H2§˜‡"XÜœ{·yØ7ÀU{U‡ÇJµTyVªUªOc QÛ¶-ß2ìÂt‘Œ§Z+U«˜gSæiö¾)„4f4áfvlæœ!§@CK08‹l*u†Ö÷†ˆİzÎüHƒmÿuëäpÿè¤µ×X¼VêÅ<°C¯ä¸çùB m÷°÷Ç#GàZ0FÆŸ½1cÓ»GƒroÚ‡íı½ôf®µß<8hïµù£Ã×í<›1- ï§“œsvfÁc42A° ìûv#ÿ²¹Ó¹<àS‚lˆ£©³u¸}pt²×Üm7—‘Ãm3l±RÈíœ´¶Û[Gû‡ß6òe8ÊÓË—Û;Pûâµ–á¦¬/-.æs£æáÑÉ7íf«}ØÈÓŠ'ººmñZ©ı†-¿áïùn
4fÙâJ>·ÛÜŞi¶Z‡íN§<ıÇ5`@–ºı\ûğpÿ°QÉ©qÿäà^í.2Õ}˜ƒ›ïè;x±×qn.ØuT¶¶,o40®x†9×ìp!15½j9»Ş9Ëoï½Ügu^ñj´“ßû.+ZìkİÛ{À{[íç¬Øb_ƒÑkíÁïïøïí—Û{	Ìÿœ½Oª„±b?‰Ù©r¶ìãä0„ÉRŠ_$O))Åİ¤âİ¾Ùı@ÓkV—äR
 ¥İa’ì{ì[g]»Ñ²\³‹“Û5lh›.‘t/à‰W$KRJÇº¼IˆOÉIåvœsO0Á_ïì¿BépÃóYgì¼¬Ş°â¹Ï*ìıW8¿Û9ÙÌ­iØM»÷cËçù¯k7ôÙÀ\+óE$^rù
£÷gVî&7÷¹.qhírÆâ2Ê·†¤°G5Ô‰êË…Ü5µs{ïàõL’Õ/ê+7ILH	t]ãƒÉ@³u¯`0ØçìÔ„zœ¶]×@rujW2`FP™Ált²°Äà |WLnAŸäáåŒmï¶O€v`béZÂò¿úâÛâÃâ½“/¾©±[ÿ¢“/|õ•Rôğ0½¨=¥0Í.PúõîÿkÕêÍçÕ+ü»–¡”d!Ó3ºáÈÓ„†|“g&Ô€è`Y¥º0)/ÕÑí;˜?Ä	Ø Q}òM“e<%µq5L†”üéõ­3?xºìã¸'¬±Ú_ ¾„kÏÑª¸mËB´"/§¶.±…“ÁiY•–Æ[Ûsl3.›æØmÏŸ'µéFıd$g'ŞCÈç@Dª*E,*º)@‚ôÁøÑò@9š6ñ%(O‚zB$WQÙ+…`ÎEé
3mL{VÅUUÉ²·¡™l´]boaI|ÎŒ¡3¶I7Üó1.‘½ëÀàÓ´†â½ë¸¨w0è½’ZEmÖ*$`¶ŒS{aVøSá«Z	©Àb éÛOêátFKÈ£æ‹UÁÃask§h7'/šá€ĞSk¥bTgúX{i\Ö µG­=Õê4È[ÎxĞ#¾3îöùŠÛ¥‘ı`ÑcÇ‹×ßì{”KIÜÚÔöv˜íÛ|q~3{jùõ©åÛ®Btz¤EèÅ§¶†§ŞuÇ¶ú‹°	uáĞ°upµ;€ëyŠŠumÔ]ËóH³ŠkÙ*GÏÂ[Fº	D5P3pm›\$~í˜¢Õ– ´¼…²"ÁĞ˜mcFzÂ@;ThˆÃ:Ò­
À–G*İÑÄ‘2>Ë‘âex*C~*¢·lø9ä‹,ÿgÏ
‘•ÊoÑHviØ¶Á<ĞßûÆ`àhÃô×SÅÎkûƒí\Ú¼é)ú^3KCÉMLøë8šCçÔjj>æƒ¢¡râ5µçåyQ¶Çƒ:y à#<sÂ<¶ÿr>n–ÈûÛû ç@r“rÎÅ…•{•“ª‹ÌÆU]má?ÃlQI£|))W\¥Ó–•µj°®<³Ë¸CÅú4ã¤£Ë>}‚/¿`Å^ä³Š Vkµµa];HNŠ!;Wb‹Ëg(mÂ©§Hv·ÀØ[ˆ:ÖÆÙ;Bb='–í9¡Ë¡A~ÊA§Øòt/ÁøËçø<*ƒWrè×0ş	õöË_b7]²¼b#Ğš±’æ‚ÑéRU+TÖ¦]RìHã„ãÜ?–åàvë^6n…û}×±¼Ö°õJ×Ò¹œ@uÅv
’€ tÊEÌn&ëA«²Éœl¦ä]¸î…ãíÜô°­^~ä:8üpB³á )<2\`íN|İ!J³ş…UoÕ¿«·ë.j{Áòƒ+²ğFUd/¹e®¢İ‹BDV¾Y¶{¥22²éşæ•6Wµ0·£¥äøNæPMc)yİ;lìlo5ĞˆÃª]Ğ¹2Ê¯ecklqE(h-H½}(3b2.B‚ÈĞ‹Ú¨:ïæJš°9³kÊb·K‰<[ÔA)Á³`$Ã¨şe5‡™¸}ñ×PWŸ”
fâ$±ë…èlzäOZi´Û`1`j””0ÉßÎ FÊAO™x'ˆŸ›Iò'˜$.M ×æ‰r_.`Y$ÿY/æ­½7¹î•ÅÔ— `ñúàmK4ä†“ébŠŒçŸ4­¯Å;GÌ‚%flKÅ¤lDû‹2xNä,ù¶mñÌµLà§+xc;E@Ã‘O¿\gdº¾ezˆ)¼â4
ÒÚôùkµM,±¡ÑwAlS?×™j&ÇfqÔoÏåëU-»àClÛ,ˆï@2=øSÁ÷ÃqÓ÷³‹[òÊ\,ËK*B©ï˜œ^İ—m·¸Iz8øÖwÑÁ! QŞw`WX#øæGÕèÅòõŞW^ùØ.³òW7)°Aœé'ş£ÈUW &¦X-~:à“6Øø¶Å‚Ø\é˜î¬jñ:jŸ,ŸÃº°é²¥X±õhö´ºR€(}Ë­î¸ÑK—a•¨º%:¸+…@7\õÅ‚Ì@ó_ˆåp)cáBj§Õ< ¿:ÁDªS†‹•p‹×–X/4ßşîd÷–ËléEûÕöŞõa§‘?¶‹Ç°BzI?ó_m¿ÚÛ?loÁäĞ¨~Å4Üƒ©²?±ò›½}PF¹ºXÃWÇ_/a-KÇÏËìµ¼¸Æ_·y3à}AÀ©|Ånp[àš–$ôNïqV \µQ¨óúÈ‚ŞÙ¨Ætùé]ï¦*QIªóú4¬LøiR«‘?œ¼Ÿ—õÎÜz‡” üKEP8\.ÃˆQÌ^Bàè×m<³ÏS-±ìÔyŠìe‹û À7[»Û{êÔ“:‹½¡eÏ0Åç®Ä¾JÃ´&¥uk¢Ùú½º^Ó'>Ñ»\†6ÄPˆ ş¤õüW‚qoXYóº‘¼¾É~ñ'àõ=4pH^ß¨%2ûí¼6yëz£¦±.¶OßšÖ£óX??·Ç§¤ÿ/wáú,ş¿këòÿ…_›µJ…ü+ÕÌÿ÷1Ræÿû™üƒ÷SñÿN L’r{F¢½Ÿºëï—%øÿ\«kÑ‚–í»Noª¬İóòFf×:»
ı°óŞ%Ÿ¯ûğOÛx®À·v~TŞŸ‘ï#úë&x#+ÜÃ…7æ*ÚyÎŠCöµÒÃğjv—İûøëÎî¬Çy$2›ºSâ¥”5/(½kX&VäÉÅ3ÙGõ‘e™læ#Ë2ÙÌG6ó‘"òña'xå4Oø2Ù)ğ3_Õ[úªÎÉósxf~}?1¿>ÈÚŞ{Ó˜êÅ—î Èë P[æÚw®³s ¼½_ıVÙƒ¹èëV½Mnzá£×Iq«BFÅ´¸,õ<™÷šn½òñjù˜•Ïæß7ÿ½Ÿ¼‹—{‘¾MÕBH[J`³œ}ã4Ñ.)1Â(³@ûhKH0-À=¶Àº®‰«YCßÛG;ÉPìÑ™>»ÊØGÍxE	‰';ÛÜ¼æGléKá‘£Oİ±˜War¨âs‘ ÃÛæáúèš"OD!â'´=ÎKĞ=N`JßÁbˆi«yÔ¼)¯à±‰°ÔØŞ¢aCÂµ”ôEJ;A°bK¨i¯}ÃˆNÚ¼‹	ô}+­——áïÂ1bQZY,WËK…°iê"* xÜEZÛÛàtVdi^ğõØ3'±µ(Anp¹8ş¡€‹Œ!Z »liu‰Á!ö]~Ä6/Iœ[v¤ƒ‡~gôú†àÛ°Şn>cú¦ddyR's1hy~Á1]éôİ8,ûX<8m§Nñ`{·(½%èbÈ<)ËÄåè¹æûÄL9ÜòüÕ'z‚2úá¸ç%7G¼’Gş%X@™¥@Úr§@^¨ØUê-èËPa	ØëşC¤ñh•yÎØíšªÎV
YT‘W‰Úü¬kyaRß‹½^0§„sîxÉŠ#éÔò{rJjmêv	­ôc„¦SîeÊÏ_ßò1(ZnM¼ˆ—'ï¢ƒ¼³ŒÃ¬(s‹ş±p º‡ãsiÚ«£D]­!“ƒÎ½ôî]ıt`Øêïß/bI GŠ^í
³ ›ƒìî tğ.ôl¿¾YÚ6Ä×e–ÊÇùÕã|9¢¼tæ(ÃSA·²ñaJ;Wà1øÎÍıdñZvÆÍI€ÚWèUĞéİëÑ®"Bà¶[a«#vAÁZ[û»»MÔõÅ‚h{ï¦Ì!=ÌÅbßñ|jHÀ§™<æfrğNB}³TÚc>DE Šl
5OZÆ•°˜/ıê‹ñ¬— Ò¬ô…‰\#R„‚±Ïèê§1÷÷‹4L1O¶pJ7@Ş­Ü0nı\ Ğ%¾iĞ8Ôæµgeaá›B¦8”úÜåcurÿ@Ÿ† ä#+zdUÙ?¬·õ,õìi'\‚Äe  ’ äò2ıøUµ Ë‡Dóyz·ÏNoÜÅ•İ,³¯@±-¯oö¢æ÷°ã5kû=f¬si¯‚ú)›iÁ¨;…¥éâÉZ³WÊÆÅkz1]tñğL‚Y¤MÒŞØ$OêsŞ0ß×+uùë\B]¸
Eìº‘>%äBŠD<1UÂ|ü?0ÌÇNÒÿ™x<ú,şŸkkÿgumı?kë™ÿçc¤Ìÿó3ùî§âÿÉôóõÿ|Z‚ÿ§ø>+U6µ<»Æw¸KH´öŠB×•»]Ç>#[2<—¾"ûÑûÌ¡4ÚÃ¡´Rªşh£Ë>ª[éÑ·Ø¢×;;37ˆ7JöÙ.š®FfîwíöAcı6p°½ñğ4ï­i~ ÁúÁ4G95#tlä‹Eù{<ù‘ÿ°{90Î3Ú³­Ï¾FVıéûÒ’2ÂTôVÙŞÛ:lï¶÷š;™Oî¸öå“›Å­Í|r©Ì'7óÉÍ|r‹?$ŸÜ™\r3§ÜÌ)÷nN¹B·‹;åfÎ´ÀeÎ´™3íÊ™vŞq2€´~İªëí‡p£õa	@fªDgÔÇp²gXËÌk41óÍ¼FÄ^£b{nF¯Qï_òÑp.§~s|ÚW|ºÂb_àìlĞ*®<*3–IÆ7ÖëE†5<´cÛÀ¹4ÍÌ&S|n¯ıöäm»ı»½}Åæò:_Èíï´Â°3Ş¯qà¦P â/š[¿{}pÒiçñJO R(Ä´Rì\JPAt'ÖÃ*&QH(¬wQ+Öfì$j¨„á‰aÅ7ÓáÖ,ÌŠc÷\ì¬
È*†YoRæ=ÌîëÇ©;oş`=‘ÀÅ<’±¿=<|òW¨ºè¾Ê‚“È)3Æµ3…{³*R+ÄŸŞÆ†GHQQ’/«€Gv<¹ó&\L¥0ºÁ5Ìm˜¥g¯u\”B±O3º‹ª®¢,©ïÄrCo9ö™uvãu#%C¼¡[XñàûîÙ,4*«~¸fÉ?ÿ/ó¶ö÷^²çi­Ò4$_n€{·h[´è<‡wšPÓ5å†
M+]9xÆp¡Êã¸‡vù(‚~¦ÀRcš/…ÄC7™è»‘ÕK£s•…Ç± VÄãxvoãtOã‰ƒúNÅ39‹ZîìP<İ™8fóOg½Ä&Ïà/Q·›cßÁ«rº” )]tÓ’ÇœAıu ÷ê4Í'xŠ§·Èä?Í<¡‰â*@CÕ>f©KªušNw#w‡¬è&ÌÄé;3éÍØsÔ&œ9cĞõ—ÍóR\AJ@ºº±#ïø™“«·@/sõ¾EúÜ®¶?È„Î¿¥“ÀÌú uLöÿ®TÖ+OÑÿ{½Z©®?­®³Juíim3óÿ~”ôó—OşüÉ“]£Ëö;ì÷R4á»'jğçŸá<ÿÙ¿›dóèèÿ¢ÿşü‡H–#Şÿõ“'zxÉfi`x>: ãZ~á #`ü[üëÉ“¿Ç|C£ëâhâoÀÃô¢ó¬Èû<ïßEò¢óéÀÜ¶{æÇ'OşSñ?şsÿ÷ÿúßş=ş[}Fûa&íF¡ªcòøß€Ñ^ÿõZ%ÿ‘²óŸçüGà‰ÿc>ûÁStÏ	˜òÂ£ğäFô:ÑìÈCœ©ÄOô`u9RãDĞ¦Âæñ¾‹ÏÂnñ¹„röœîÓM<!‚@ÏMÿ¡z„0òı)è+ß½š7ç|2¡½ 9qÉ®œ1pÛq­‡n.†k¡ã‡+ÿÕµüt´Ø6]è?rÈîjˆ4¯ìãš¡c”õaQîš¸_ë*àgeˆÈº¤¯
1îüˆ†kNËf%Í'#×Á>*ñ:úb3k07Ûğ$˜üD|ãËCºLz%©5Qòs2w7wvN¶^wöw·ÿ@÷)• å:p<Ò¢J‘7•JÊ(¶Éƒ'±­ƒõğëËhs04/®b<í@Ü_W*eĞËåå0¥_H˜Ğî‰ „`4¢ÀnôUÔXvËV…atìŠ+‹$4m»TE-ØsLÅO"S¶)LÆÑnªXşO‡É3ª½‚¾Aq
N¨±<´z½yi¸¦
úåî[	şN ±,ÁûmóMSETƒ÷03ëÃˆ¥¬Ò™'ìJcà›®ısÁG¥Õ)JÜ¬	9¹µAìº'Ã3ın9jŸ
ÖrHFp!Ò3pŒÇQÈ-ÚªlñøÚ¦4÷	ëëÄAşüAÎÌµ•ÙûM 4î†w‘uL_’DŠŠª¡dB'; ÷•Ü]ÏeçüRNˆ¿Ù§y¥ ß+ã¥¸Uà€=änrŠ	ÚFèÄÁ³†E#¹wö·š;g;Í‡z¦·KË„)<qf	VäNZKîLúèh(ª¡f@pA å#ÂRŸ° ğÔZş… rôh+Ü1ˆ„¢º
a~Åİ½‘k3H’cTşè/ş}±\^úÔ0PUJƒt1â$ßÜ/oX¼x~é;Ü^"ä·¢‹è-—ßıñ¸üşW…ëµBSÉºl2®ˆ,ƒßõââ2â1°ìèA•Œlyì¹e’¢)h£»;èSFIQIµğ‰!şyĞµqñˆYêõ|áF^dN¡ä9"Pnm¶·ö¿=!O9`éSrkšö<£7X±¥/Îí¥ù¤Ğİ%¥úV§İ.?gÒ…Šteü@,PT óeWµ	
«=Ëô-Î¦„yµ4ãÂiñZoßyÔHûù\ñ¼=¤}ÿŠ=ÜT=::úc 	’s…ÏƒÚ»ttÀâšÍî˜Ğ(O‰ àşëÃ­v÷íÄOÚ¹û{eóÎû(ÿÀ”òî³­á”tşá8å ÇÏ‰ëÿÊkÎ}\î4¾AÇÀ3Ëõ|¥¼"ôÒEÑ5ºåË»šE'Ş°âÀŒx‡³Q§ù¦İ:AàÀ1øÏâm\æŠïr
X„9$·s¨µ¡¾¸µØFİO.EhV¼.äN²È*&Jš¼oHCTà¡ÆŠ<	¯#*3è1èÛ„J#÷©¤i5ì]UKÀV¦ŞDy(5gÔƒ•LRãP6Ÿò'Cãy˜NSîM‹´qà³3ÅÏU’27‹¯p„KR~£íÑrb]ANìŒîÏ
‚ÂI8âÃ|{ÿå{º$‹ZÉ·2Ğ§5`8X„Mfs8ò¯Â1”ù‹ÆE#¯ÁÇéÉÒUs½Õ<ƒSVÈ¡sš¦ù–Q:éŠH„N1Wé|‚æ,!İÇ]útš—t¤Ø}İ¦ÎK'±lâ
`“€Î@;.¼9ó+¼ã”VûeóõÎ‘êu“È0ê*(R$p|ÖªRX›ŸEK‚<Lá¾—ıßİšçÒøíö¼vW>›7=˜Ÿ»:i¯÷$Ğµ÷¨ÄJã¿åò$iK”ßi"’ÉÜ­ñ_5ĞÁÛ€U£¹ó³P¦*«Ã>¥Ájc{š0©ğhMt¼	ÎB”¨&5?™	Í‹€â:ú
±£+ühÒ¬¬B¬Ş¨«œ9ƒû¡Í	N€£K˜¸Ïş:º9GÀz"\ˆê,‹œcÆÒ›3bÔ-DY˜eTLâC7½Æ“pË©şKª£ÿ|Ñ]byºójy< =õX@R1ÒáHP-GK_qß>şŒ~zğæÌRf[©	F¤8_ÕÁ+aXÿPdâd¿ÚíÃI9çƒ¢äÄ¼Q•Œ¿şµî™(ßK)Ÿ0zL$ê²H
¶ıòEÏ /	#Jv˜	ù7š‘Ç„‰œŞª ø~Î	ÚVR ñd}	Á‰í¬ÒÈğû:P>ÉŞu£jb([qÏ©Ç<‡S}ƒ¨//†Ä/ÄJó>g1bkŒ 0¥âĞÒ4¡Ş¢¯:}§Õ<`(I™R†­NÌÚÑóŠ¬'ÎN,{“Ú³SHğXCÅ‹]“ÛÑìóèã‡¢
äñ(.‹U1,ä5¨Ìb•Ë´-¿9b…­½­4ætÆLL2*“‚‚a·tBA^Lê!¥Lû'òvRRr*5ùt™LóšIxºï|¢@ÁYÅš6‘ğtËéÓ‚\¦;}[Ùj¦ÍQ5_8
ÓíòÎ†Åkë&0ô+W"¬b ï¬†Båî ×t€bc ±/ŠÕŠ?Å¿ªëø·wlçºº*á¥¦	ßğ&'À È6¿‰Ş7IÕ$/ä­„•9&>¼A„E§è˜0;ë-
 ãnT‚9[ÎK? ÁÖ!=£±vâª˜ëˆPSUä€U¤®¨MÿzVpigr”i>õø¶µÜ³\qU-<ÃmºUÃ°…ÁŠ8‰OìĞR>šx8˜hE‘>Tîa¥€L="“$nXŞC»Ø& ÎNè„WÅ‰.‘ˆ¦—®å	|Øs~ÆÏ•ÇPÇC¦Û¯éC3¾êŠ.Ù\¶È¡$öh|”´ú!¾SgaÚÿ·ÙR™4rRÉ9™‡wsl›´Œòjù‹åÑ’Ä ˜{^±{v^Dë£iÓõ;b2DãXâü«ST‚õ}C'>çY›˜Íµ;\%¬bTó¤ê-e•º¦Ÿƒ¬ºrÆ.…‰¢jA
+ºô#ô‹Â½E/îHEÇniSWšc{¢
÷*
N½˜_‡”¿IÊ/rBêÚ—Ï’ópN	Ô'ÌûtíiJ^êâkùò~ùLƒ{w‘|?a•ØƒQ;Â#‚R*ºB-Ï#yÕ%zâú\É]£§,Ğ•ÑEzâ
}şT|Œio<Âcf'b›úøg¨¸ñúùç¶pš–³˜e1a9®k¦.±Ä‚ÕºŒBß®"É\‹åË‘‚åîñqäUø§ği]áÀzÈ[j[fUgÑÑ=jÂõ¤ı`½Ü1|ş<Çø±obäÜ	è›ƒÛ“¶@Yäq5JÌœb¥ˆøDÜ	Z>'×¾!ØöŞ›ûù‡`A;$èĞ½1ï²pŒş¾h—›°>bÃBúûH¡¸_9/$ßß?;y!%dÇ÷‘ìúi…0»ö~eâ~ü¼Lğ>’?îÌÏóË÷‘ìñs&<»ò>¹„rPA+!ß— ØR¼œÖ”†¾h‹Ö¤ˆ­„ò~BÙ¨h‘ÄFE6IåPDQ•ˆXß'd7{Æ²ò÷I@L&ÁÆ÷IÙAÖ&f‡÷ZvUÈKRšôä;ÉƒnÂç‰.¢ĞLô¤:£ƒb`È÷úâ|İ5(rg6¸³6^ë¿Ü• õ²$¨™^V=ã@ß•ªûañóQH¾W äsuA©½ãµ;}­˜º	7¥°çŠá?">u€ò	?ÒBÇ“œJ±ùQ“ûõBä¡^i)vt2¡M‚ü¶Í7\Èó„ÂŠ‰õ•*vw™)PÏ@[¢B “QŞÆŞ¿gÍª¹³İ"µR~Å¹=d¼åÒJ¡±¼”‡ÿ>å¥ò‘aáb#€‘›s*Œå„±øi™C) ˜Âbù¸V^J€r-~Áò†²:’VñĞ$f¿¦F¥X¼ø-„<Z¬¹	t"(½Oê§Ş»0Lp¿8Õ¦ø¡.Ê†.mVùê~Õ@ãÇCËÁş‘4R.`¤¼®ñ«Á·œáĞ±€[‹ZA<¯ jœí\R¾CÓØ€Åmø^ïxÌN½’…ÅºXÇòàâ}Ä­ÌvØĞğ»ıU64‡á³.ÈE‹ÖJ]ŠNGt–›»ñPû
ŒsïH@nà‰}¶ìštëœRXáéyÅÜ¾V6ÄH@ã[·Ç1»4á›\åC^†ş/ó(gxêV–ç¾ø=[ä$¥æÇÖP’Üª£DlMf*`±¥-ÎÖ«´‰ú£œ×¿À­3Æ€Ç¬ÆŞv ò2ôK@>¿’Oâ!(#6'ÀYh 2Ó A`,X0b}î>Æí¾A§¬Š25qìó£˜¶c•,”ã¥ã^nOôÙdÎ“x`Ç!
ou?Ğ’#’Ò¾eaÆUèT´•ş¡xëüRmœp:¨™å)ŒúDHhZó]ƒy€@^Æ ^Ïµ¤^Õ%¥XtJ¾xkæÅ]»/Û3º·¯È)\ŞşÓØô0x¨æÀh~MËÃ]~ÅÅ}î–
î+j›—š*•|_D§<éÎ²'­á’ÓÀÅ\™¯ÕJn”­l¥ °ÛO)PÓÓû”Bk‘Br_bJ±õH1nsŸRhC±›'¸½Êu	[â_X	EN"{Öš¹Lı ŒfA©	®fÒGWA8@L\†)µ‹|dã.y8# /ÍnyO³‰+2L9Ì5™˜åD#ã‚vÌ&¾"†mÂ9¹t­¶‚'¾ƒƒÁšHáy÷{ÌÚHtvŒ4 fSä~"uÅO¤®ù‰ÔÃµñM=ÑZ…˜I¦LsŠ­“øÆ‘k^X ôåğÀ!4„Ÿ;åáqúÅ«Lƒ•ğT­ÄwL¨
jÉ?:z¨ÇaAHWò“8(Ê<è"’$8\ˆâèÇ]¦àÄFĞ|†Ágçâ9Š½ÏÂqÇdúYET)ğx¨<ä•‡%O-»ê} >*´¬+æQY˜Ÿ?ÅZyÄ-5,]&ü\ŠP¢~¶|õpxT28Ò(!é¬\JÏ‡5\JÁ©Ò=°‰Àš†T4{pÌµw¸Ä‘ôüñ™ÀKš'&PSjJ,‚¬kpkUêéÓ)$çSÎ¹$Ÿ7¨¦–çgÀ'à“n‹KDK7ÚÈæé]n	‰šŠÃl›š]vlˆvñó™ÑˆÈÙI,‘#Ãó.Ñö@<ÆÙ’jKÀxáA°’H'£Ë^Éÿè'ª:xÛâ×QÌP>v~*±°ÌŒí‘î1Ã~¯ºSĞ±¬Ä#dÄ·Øu<äyl—;5";Mèêñ®y¬g‹¹Ïpó–„ûÛƒÖ1-ş3ÆK­®Õ*ÕÚúf¥Zeğ£¶¾ö„m<(V"ıÌã¿vMí}x«‹÷P\pûş_[ÏúÿqRÏé>ìà2sÿSüçÍMìÿêÆÆzÖÿ‘°ÿÛÍÖn»4ì=P@§ëëiı_©Eú­²¶Åÿ~Œ´@«kº”1ˆ«MKjÚB½V„[nÛÿò_ş­@sënÏú^ú[ÃÑ 7h3=ØY£]¡&È£5Š“V•¢mĞrj:™ò³vcp{]cdz%Ö`Üçó¾v”]„SÆ:t:\á±yXÉş¶æFá­
_ı9œ¡é[CÀß³ü1íºÊ.é;Æ	¶M§À¼!nMQ‹»G×±hÊ.Ã+")—¥ñc÷Ø.h-Şxg "´¯60?øSOèC‡"¬ØhÊg&(Ä®©‘±%É¨Ñ™v:›İUvØÜZ¥L¯ÆĞa{è¸r=|Ù·º}DÁ
ÃãbMf°h§U‹Á{×TQÊåV$Ó¬`qÀ o$\qCì¦•• ñÊŠ Ë*³¬EĞ‘§‰ØéØîÒN¼X_—(Ğqh?ğ|wÜE	äÚSË†µ–	&©O¡©jÁHãÖĞ.²ñ%nÃ«1İå"»§JyÙÄpÎ˜ùÒµ|ß´± Æeæ>AÜ¼ˆy¯ìXöø#{³û/ÿù Vˆc‹¢j#R¾a¡©Ü¡áNMv`aVŞoôÖ2lö[Óó®Êß5ınŸê¡¦çà=‰Ô=öšÆÑQï	„µéZĞÇ£Hw…Á 5ù‚­rë®…–¦+‘ÈÒØ­%öP"é+UBçş6@>ë# ÕÃûıÇüGº€€5àê*³w¸ìö<ó=F„®–½>ŒÕ^9^+ös¨¼X­«k'ÕõzíËúÆ—t,øğ£ê£5È9‹ÆÇÆ¢Ëo„ ©”ªf´¯X˜î^^MBä]±ñş>e_+ş‹Ïß³‰ğ”°‚šÍó9BßĞ¾ÁÈ|¢k}ş~bES°(†d±Äï›^¦ êC°xn¦»HgÚ<¹é:0t‡NÏœ-BSšêCx)”Ø.Nq$t÷|Lã‰_U0¡ªiI1„r©cxa@Åp?mJ[Ùs‘†0S²,úQ¥iUôx¡*©
Šœ\EHÌ‚ WØhŒPÄï¢½ÃèF)7 bÁ½sæc„rHßw„RØ›Fˆ´‘Å¸/W$T¼î-ª^ğ>•ı“†­ @JÅrLî%`ûÔºD›R7vNl2ÿ4¹Î‰wœsš@êŒ.ß
N0	³G.·­ÎYæGƒtºIƒ_…°²²/Â>BÜ€ÏQÀ/ª`)A¹âéÊŠ±übÁ+¡æ(D†l!m¸ò¥{É¥WpJ[aËROáñº>Î dNßŞDK€sÊİ¾øE¦„}àW$)> A”Ø¦Ù¥‘ÛP\`¹h/>«×Öî<ß¾¢;NÎ¼ğk*€
Ä8—øğ)
‰Â]É ’Î"°Fì*‹ä²¯£w[Ü®¬~•…,›B¨$&
(7PL*ˆ¤d<ÕË!&4W½Ù"@YŞW‘ÌKü.É—ÿ°kj:Ó¦pÿNÑ+@(á±“óoñxŠÁÂHs¸a(
m;S¯	x¡O/5#áŞ";Ê¾™³k=DŠoSÕ¤nI.1…•ÚèEÙÅ-¾>°ìø½/MŒ0Ÿ×ÔpD°_å¾±¥¾á;GÊq×–ØêÈi&ïÀrš,‡·|Ğ_ñ}HùZî¼ÊgôX§åtJ9ç›0ıpğáOí"å}8¯ÔSsRıá#×s×ññ^¯^ÚkÀ(
 )3²`dX>CÔ'GŒë"_ 3p¸ÀTÛ~×ÒÒ!v´X]3’åràĞ	ßEÃ×äñNÓ›~-Šv™Õ2rZL·˜RX‘ÓË†K%ÎàÃd26ğ:%2rĞü’èÍ È¬CÏ?Ï$ZÚ{-<ˆ87rÕ ŞŠ&0ğ|sÄŒ3ßæ%Fúˆ’š¢ñ` Î—à°–ÿ-æÈÇ#~ˆû¥PC1ñ÷©‰GØJ°¨×İ¤pûŠª}Ü7Íƒ_xğÌˆN¡øÑ#@\VdØÂµ„Û³rü¸¼jäKÁÕ‚ËB¸´*äuwíÈîÅ9ë,,`ÔEDZ7İnßòM²¤år/®‚X+Òƒš,Ú€/÷_L¡k•ª}rµTh½qìÉHÁî®Àª*2İ©†=Ô»tæËò³?˜xı´'œoP_óM¹®3åºn`}H´®RØüĞ”¨­ÄJxş‹+ûğíf‰‹A@cÉc]wŒ,Vù´ıª°°Ü&*1äšz‰í7h—~Ñlä¿3éwAë	EŸtLµNO] ó¨OÆW^ÉÔÑĞEïÀU¹<[> öÊ¥	ˆuc¬ìBÀ=tÅ£G‚HJ™È&A¨7'tO)—ûÄo‰Œ¤O¬erÑ‚yñdLpÚ`Ÿ¢o0c)AoşÄ­d|†k¡_š°
s¹Ïd/´_ e—ß·è‰ˆ) ğ–¯µ8,B•pÀáÒÎ¢ğÃÀÁ¨,QƒD„‰HËÃ û:¦b0I„píªõix
•w&Z7ä ¦Ø!øz¤?†úà¿ñ`-í…ğRáfiN!hà'(ÒbhÁlÔp—â.'mè(Cb—x@ÃĞ÷OĞBÏoá÷¤õJlÇÈò2@ï¼‘.L%}Õs-Š>ÿ4¯ğ)XÅéÎMÒÖ[Ö¾0Ñ
Is‰“S7.má»ÌÏ/÷ÅÒ›É3Ó„ ¸…ñ[(i§ü¾ùÑ—D‹úòI¢¥I1‘Z±¶Åü“z­®Fy®»#@ŒÈŞ[0vp¬p=8§ĞĞüÄEaKYó!YqJêåZZ(•Û§²mAÊÛğ=	"Ÿ$O‰í:üªèÊ!e‡&h%zz…ÛSlYl=½˜éNu’/Tmƒ‹D²J#*è@vøx€^ß“SL˜§fLò‰¢MÈz»L<#T­ÚEWÙb·çœ-Pğ1jJlu‚Q”.÷œJ»,¯:ÉÒÃÁØeC}¼OÕª=¸Ä^Jšã•«*UB”ôbÆ¤4ÊTW'#9=TX¤8•ó')šê¶9ŒjyèX®kbB1…:†tKÍâ¤mâYR«;Æm_~9VPi¢"(f÷P%”œè6! 5Àm?B\ÙÕeé< qÜ@§¬öYR%w|\'	¥¿Øh‡¤BÒáPÑp tËÁÛX™ØmW¶µl¦·ZŠPh4b¡–†çUª–ĞSvôŒÉ­Ö'†ªT‹J‘_T ğÌ+Åj¥zÆäJµ»d§R42œÃª€İ¦VyhÏ1©}wªT°BR™ı²2>Ã&-±vZÛ/‰™pol¡#Bäúœ»£§XäfAOÍ®Št\–Ó ë‡ ”^©²+6rŞ¸ë—Ï†—ÕZ©Vª–ÖJì.Î^Û|«14mÒ5‰j
ÔJk…¤XGÉíîß,×ûP-}YªœT××#e~‹×n’’»lÑL÷Ô\ë”j©:aÛ1YŠ„ÖÚÔ±ÚOéWqõs/LšºÄv"]ƒÇ—¬„Ak·¹½—@ã‰£—,±–ßƒôôIª•òq†$u¬„ÓFÑİd	=ÎÇ[}Î}~”5<¥ĞÑ/¯Ği²„T”,Å‡®òGW‰º+3mE®ÔL ¨!qZä•¦W’\QmwœÙj¦EÀ›Pá4çSÓ³¤íÀ±Mtr±Qp¢6ê\˜¤k'ëÙƒùèÍ·ÓÂ“	l(Z©¸£B½8HóúMl:€åRÄPöøÆXó›Òø‰`HHJ Ëv¢J ÚŠN;¥õ¸<EEGbçDı	QĞDıZM< nØa¿!Ô@ÑiI€BËÌtp‘jIà¢öœé@#qÖ’€£IÀD/&QNäU´÷XO‰,b\‰ø_8R´•gîã”—¢®1úÆÈ­u¸î—·À¯jü€óHÈè¬›ÜF«ö©'L%ªìu_h—åŞ¼¾ÉÍÈHO2pİ~üÂCò\Ecâ[ü˜†gÁâ‘Û®hüi1†MV{CÜß«ÕØxX¢´Ä_{¦şìV /¥J¬I]ÒÅD“oI$¢ÊğÑzÖ{Ü=rì¸`1º¸EJ?š¸@ÍòÃï!Ì`üÛl0…O¶3öÀ™&0~›´Ê†
Ò& ı!Üe1p¿Ò87‹øZ87‡Ãƒ¤®&×?N¡‚#XODiäî‰7Ü…Agâ…å¤BÄoxÇ'¯nÜdiDj¢q.¡‚Ç—WjÉ6‚`†„¶†Ø†b Œ˜½Ï¤ÑUš,®›´ì$c6V7[‹İ'îÜ¯˜ªe.Ñ­Ü¶‰šàØ¬y©Ğ„miŠEåQš»…Ãkah
]àÃ+ÇÊ"Zìd\^P×³mÏÃ4%\ˆUh«ÿt|ÃW
hñí#ÿ"ü¼¥)¼"ÁE¥<¤"sÑ(B¾{ÿO—pç*dè,óÁtß/÷}äÕËeD´tN™€ÎÃ2ÉCPKË qı"•òÊ…z.·ÂŞµ?’£ì9æ…P Ùw–'=¨Ê<k‹{ãÓ¡ÅƒgÑÛ[”/C¡nÇêâö.^ôJÓn£ğW=6¶É¡:ª9‚)Ê”™W™t¬•*%ö­3‘rÅœSÚ<6 CGW²‹EføìkD°»¼¼,°ä¸çeQWŞÙŞjïuÚE útóÏ}ëó&tÒyè:f<ÿYÛ\Û¬T7ktşóéÓìüçc$ìÚü’›˜PÇäóŸğû)õÿZum£ºVy
ı¿ÿeç?%ıÅßüå“?òd×è²ıû½Ôğİ“¿‚?5øó'øƒÏÿ{6Í££CñKüOøó×‘,¾ÿ[˜>JxÔ,á5ÙhóÄh²Ìhüóøoûïÿïßİ«YJLÖ©cÊøß¬mlFÆÿÚf6ş'-ü·øÊÈ1s¶uÆŒ	à-n÷êlñ GÕ›¯VÙ‹±:?,Ö[PÚ‘ŞıKÖºõò‹V§ e:†yçUñ–54ÅÚ³Uöeu£Æ^ß?uÇçç«¬
ø÷¦‹ÇÏ m4­–xª«Cğ©9öaM&>u|ó7×H§fË°¢. ×/¼+q=û7¾  êŞPºİ³ü ôâˆÑ-îlôâŠw@ıÂK	ğÏrh^X¨lÇ²È<›K]w.})\¡¥ÿ+­ºh%ÍU‡Çç“4AKx$šãÃT NÖ)áŒÇIa!0¸
÷ÉÔŠp)…Vá÷Ÿ¨‘gÀh˜`Ô'óîc ûÆÂ£YWux¬>+U6KµJõ)4d=A7ÁŒ`0w(^FNU\Ïïsc+Û7>òxÓ<l¼ÁKãæ¸QÖ©6–Ç¿9î×/Ëì]$BØ{¶$sv{ı†<1ürÚP\ÇÃ×-6ã,€¬ÓÄÈJ†n4CôrI%o?1¯’a·­ÂœÎiˆ²†Ìèjt7ùJ7Â›t‚×D#ºÓ/¥V˜Ô¼ßyÖörB¿š­EÊşrkû0è½`ÃùFì&{±˜©
€öïÉê@låÆ à‘2Y¡Efd~¾ÊNŸ€¯ß	¥Ñ2r÷¸ÆD
úã‚ôãÕ÷%úY$ß^z Öåç¹â;êı/¹Ô»ÙsLŞÁ‹/ZtÜ!Œâ¨ˆv6‹áå×t%‚0ÕÁ€\êFoE^
¾èk^Ëyå+ú2Ås`•Z.)ñ\ğVË…'ŞB® ›àãô–5HÍ%wwrn>ÖÂü 4’±p§Ià´L
=ñâ|ÔX
Â	/>«Ä*–ßà‹4©ÊWĞşŞº³Ó<j7¶Ø F
Ì„Ÿ((M©ÔXÂ=VZæî:Çmcß	2$ƒ9¾»ÀÀwƒW•Íˆì0ÆWh·DlV«yB}@ß0KrŠmT&÷p™o-…ÅÍÛ§M$¥¸kn@ÙÖ	¡x·ƒî:I–ÓXº°b±S}ã4 Õ˜Xb<RªıĞXÒ¶‰ŠE¹GÄHNà¼$	¬n©‹¾2»9 ”‹0°{­=–ïÚĞWk—Àºyñ]:’lÆª˜xãáçE>CÃ½’hõ<‘Á6óg¢îU#	»ÒÅ"y3¼Şn	·ñB(ù/N 
9_(Y\–?“›³ô37Ö?@Rí¿êÆİ<ë˜İş»V[ºÎ*ÕµÍÌşó(énÿµ…ı÷_ÿyká^íÌRb
í¿5ú§ÿÚæflüÃ¯lü?FÊì¿Ÿ×ş«ºŸ¦Xõš`š‚UwßÌ|w~ìæà™”ŸÏ ‡×)‘'ò¹Í÷33 ~XJqhE·5)ÿÃøE7ÇLÓÿ×j›Ñû67²øß’xüo%Ì°/Šâ*‹Ü»…s~¨‰kâ F(¾\S^v‚·ëâm“Lòí†x{¨˜ø·[ÆrÜ¾^]ûòY½útíi}RıËg_>Ëì³¦ä0gó­cÚø¯ÄîÿXßØxšÿÇH´î¡ë¨Üúş—êÆzvÿÇ£$ŒWøĞuÜ¥ÿ76³şŒFì{¸:fíÿZm`î©dãÿQR$JèƒÔqûñ¿¶Y­eıÿI×ú0uÌŞÿµÍ5êÿìş¯GJ±p¼PÇíÇÿz5›ÿ'¥Dìk•Éë¿j¥*üÿ×7nÔ°ÿAıÏì?’˜—<·À^‰ƒğ„v'eÈå?q†q»Á5ÀU
_ŠHÈ¯=îRÙ%—JÕO·¨á­ã^ÚpîC/—ã·§ãßõE
×R
œÅ²ö*w­çîO:¸Äxb0éèıĞ	 #wxß"vôí"GOv¥œ7zráÌnösKÉ÷Ì·ÛÏÿ0dç%¥Ş1Ç:¦ÌÿĞñ±şß¬eçÿ%eNíôñ£õòØ‘"-0÷~ä¾“ˆ³†ğ‡xl‹j©ZyT‹ÄkŒP¼ª7áåM“3Š‹¦g÷aÆkÒ?ñ*aÆ=-ºÍù@O¼ôàYßÃÏJåCî&Sü~¦)é:¦y×1eş_[ÍÿëOŸfşß’²ù?›ÿgõòñsÊı;³ù^AaŞğ.MóÃàŠ1"¡íœÑU@îØ¦@nŠCì|+IüŒ­ÀU Ÿ¸Ö!Yıˆ]ÉÈŠ>{ùzg¯/†¿Ü½S£Ôí³çÏƒÛ{evtÅ­=ÿe5÷ äë²Ô²».Åà3>+«µÕµÕõÕÕ§w"çöŞÖa{·½wÔü¡PU˜^’µQreVú÷Ş`Ÿ{ş\iÊus©cšş·bÿwÇÿÛ¤ı¿Lÿ{ø4·‹®½š†¶mŸÎå»cºƒJ9î±g,ŸQ;ÃÚQ)*Ú((ñëj!Ÿ¢­•’t¶U]]Ã¤MÕÈ$ˆÊf	h1ñìy•Læ©–*øEÑÂä—× Ó(†—Vg—ñ«.0ÿk(­×æ]Ã®?`¦Mqo©¥‘†*Ú›,§Ê	¯V”R#DÁUô˜ ÈÓ/RÑ …§Ñ;L@JgË Wvv%Öä7Øâ¥«ìÜu`Ç½=JxsÃ¯(;5ÏğŞß1]ènù¥Ü‚–[Üû­Ü“T×¾{ãÃº£8ğK[ĞYV4Sü[TĞæÔ%ø¼dBÉ¡³]„T^”¹gâ½ÙHüYké‰âÓªéà~¬
UÜ8<8mâÎ Úİ²“ĞxR@;Öçk`zâ0Ÿ•g¸ØËH–XI¸&Å¦s•¬8ôlÍmøb˜lçOÂ1à±?G¼sïP ¼Ï)ñÅow:\È#¹·†í{ÛôñßôÓ¹éçšxkeô%Ë½rù}îèjd6ø¤9Ü¿oˆ‹ì_á l8âÊéÜ[(ƒ,ÅÑ‹ïË8lÑ­à;øîÉ‹xÊˆá‰Uíf—xîöeËÄvoÍÓçÜêâÎ5æŒî ë”à9#àe÷··?öGc¿\‰öU “!ï‰º¸ænÇß*b5‚œŸ{N¿MJ½~uLÑÿĞİ/ğÿ«î„ûkÙùGIïÚ{¯¶÷Úïs‡tÛ;*2ïˆÀëĞ@ø¹w¯Ú{íÃí­÷¹N{ëõáöÑ·'¯ZÍ£vçäÍvód÷[vªóú C·4ÎŒ7_/²,=DÒÇ?ˆL”oèu5Ç:¦xÿ5Šÿğts-ÿ‘,ûÂ´qş>>ÍÄ"C'‡“sMøÜØgé¾)2şÇ½“àê¦¹™€¦Ú66ûÏÆ:ÆÿŞ|º–ùÿ<JÊì?ªı'‰ÿ3Ğ#˜€ÂûââFŸÕ E|óO<¬(™ñÂ4CM÷°Íı¦ TØs”	?k»ãaAŠ@cÿ ½×êœwa7òÉ—]—óºñ§¹¡¸ÛóLÜ‡›zŠ=êóOcTM=SJ:£hÁCÏaÜ¢¨krÖ–@’-C?VÓPäü/©r‚¬]Âs©cªÿ÷ÚZÄÿk³²‘Åÿ{””ùkEÑúkiãáGë¼Õœ@©»njNÊ›Í@øWZĞ§Ÿ«GW®$ìu@>ÿùp÷<×ëÖYğ2çœâBw À)î¹a[ß“K¼şf±k7hîôV“`w!ÿ/©©;Ørl¼ÓtÈ¦u*dşùV?·hÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)K)éÿü‹¶÷ ¸ 