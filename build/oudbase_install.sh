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
‹ Ü?„Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹ä,	.Ñø )0íB¤á.¿ ¤µ¼&Ğ$ztãº¤87üà?Ú¯~søøÁ?å~Ãï~ñpfVUwU  	RšYÔŒ$twUVVVVVVVVÖ©í”<p*—Ë›Œş}Êÿ-W×ù¿"±ÊZu½R®¬­?­²r¥²±±ö„m<4b˜F~`z€ŠïZcóA¶³³1ßE;Â"éúßuO yÁÈ7üŞÔ1¾ÿ«ëĞçĞÿ•êÆÚZy}ú}­²ù„• —Dúïÿ…_”NM¿—[`ÅÙ%€¶¸İ­±Å™ƒ=òìK³kû¬ñj•½ù¶cù>kZ—Vß,'`¿díÑpèz[~Ñl LÛ´Î-Ï²ıÀ3}ßbÕg«ìëÊF•½ê›ApêÎÏWYûÊ~´¼¾étgô9°jLpğ±1
z®'>¶ëÌtØ¾Õóú6[v-¿À|zg¸ôî7 €ÑqPºÕµƒ°ôâé[=Ó9·º/®9ù›fÕ­fÀ<Ë¡uiû¶ë$²È<ÛÁÈº¾Å!½ aíg¸ìÜ‚z³hšÓ±o!3}æYÁÈa·k!%ÜÀò%6G=èGŸÃ€_Óvú×lä[]væzÌr.mÏu¨S¡szî(`GošE¨>ŞgĞ­PëÁĞ¯•JçstŠÔ)qŠù(â€Å­™w+‡}\åz×5x,WŒò3£Z®<eŒDalÛ±Ûì³KËC2BJÕ¨T0Ï¦ÌÓèş RiÌhÁ/Ìì:Ì=CN†08‹l*uöf ˆİzÎú@ƒmÿuóäpÿè¤¹W_ü¨<ÕŠy`›à‡ázçùB åt±÷Ç#Gàš0FFı€½1û#Ë¿GƒroZ‡ííı½:ôf®¹ß88hí5ëù£Ã×­<›2- ïš§}‹õİsvfÃs8´@° ìûíV=ÿ²±Ó¾<àS‚l€£©½u¸}pt²×ØmÕ—‘Ã3l±\Èíœ4·[[Gû‡ß×ó¥`0ÌÓË—Û;PûâG-ÃMI/n,.æsí£ÆáÑÉw­F³uXÏÓŠ'ººmñ£Rû[~Ã9ŞòİhÌ²Å•|n·±½Óh6[ívxú7®gÂ€4:½\ëğpÿ°^Î©qÿäà^œ2Õ}˜ƒ›íè;x±×¾yn-ØÇ¸lmÚş°o^ó3®Ù)äBbjzÕtwıs–ßŞ{¹Ïj¼âÕx'¿+ö.=V´Ù·8º·÷€'ö¶ZÏY±É¾5¢ÛÜƒß?ğß0Ú¯\¯û˜ÿ9{ŸV	cÅ^³Sål9ÀÉa “;<e¿L+2R2Š{iÅ;=«sAÓgûv‡äR ¥İQ’ì{‰ì[c§Ş´=«ƒ“Û5h—.•t/àŠW$K2J'º¼IˆOÉiåvÜsO0ÁÜÙ…Òá†ç³ÏØ;xY¹aÅó€•Ùûop~wr²™[}ËtN÷FvÀó-~¬ŞĞg«s­Ì“xéåËŒŞŸÙ¹›ÜÌçºÔ¡µË‹Ë¨ÀÂ2>ÔP'ª/r©Û{¯`’¬|U[¹IcBJ ëšÍÖ»†Áàœ³SşérÚv@^É	Ô¨]é€AAf&slĞÉ¢vƒƒğ]e0¹…}’‡–/0v´½Û:>Ú=€‰¥j	Ëÿê«ï‹_Š_uO¾ú®öÕní«v¾ğÍ7JÑÃÃì¢Î„Â4»@é;Ô»ÿ;¬U«7ŸW3¬ğïZ#%ÉB–ov¢§	9ø&ÏêL¨ñÁ ³Jua\^ª£Ós1„°¢<ûX+šÊxKjãj<˜0)ùÓïÙgAøtÕÃqOXcµ¿ |	×®«UqÛ–EhÅ^Nl]jÇƒÓ²*-M¶¶ë:VR6Í°Û?OkÓFıt$§'ŞCÈçPDª*E,.º)A‚ôÁøÁ@9š4ñ¥(O‚zB$WP‡ÙË…pÎEé
3mB{VÅUEÉ²· ™l´m°·°$>gæÀ9¤‰›Şù—È¾ÁÚ0¸F4­¡xï¸êzÏP«¨N[…Ì–qj/Lc"|U+!µX4}Ç¨S}œÎh	yÔxqÃ *x8llí´BíæäE£#zb­TŒêñ­€ k/ÍKÓî£ö¨µ§R™yËõ»!pG_ña»4²ßLß5»ìxñãwûÀ%C"©‚[›ØŞ¶³}‹/ÎÏ aVW-¿>±|Ëó€BˆN—´½øÄÖğâÔ»ŞÈqP6¡;˜®zp]_QÑS¡®M‚ºkû>iVI-[åèix+ÆÑH7¨j
.p‹‹Äï =}K´Ú„–7°PC$³mLIOh‡
qXÇš¢UØÑòH¥;š82Æg)V¼O%ÈïSEâ¶?|‘¥àÿìY!¶Rù-É®LÇ1™ú{Ïì÷]m˜şz¢Øyí\8î•Ã›¡ï1³4”Ü$„¿Ó¡5p/A­¶P¡æc>,)'Ş@Y}^êZ—%gÔï«“
>Â3'Ìcû/gcÁàÆa‰¼¿½ q%'0)X@@à\\Xy×9©ºÈl\uÑÕNñ3Ì—t	Êi¹’*¶¬¬VÂuå™ÍX.Ä*Ñ§']öé|ù+vcŸUµZ+e¨ëÚA¢àpRÙ9ƒ-.Ÿ¡´‰¦"ÙİBco!>êXgïAŠõœX¶ç„.‡=ø)bËÓ8Ü€ñ—Ïñy*R5®äĞ¯a,ü3ê?ì—¿ÄnºbyÅF 5?f%Í…=¢Ó¥¢V¨¬M;¤Ø‘:Ç	Ç¹&,ËÁíšö½lÜ
÷9dy­aëå<®¥s9!€êŠí$'( Ò*è”‹™İ,ÖVå9=ÜLÉºpİÇÛ¹¸C`[½üĞsqøá„&fÃ>RxhzÀÚøºC”f½K»Ö¬ıPkÕ<ÔöÂåWdáªÈ_rË\Yº—…˜>¬|³l÷ZeddÓı Í+m®jb>nGËÈñƒÌ¡šÆ2òzvØ:ØÙŞj¡?U« se:”_ËÆVÙâŠ:QĞZ(”zûPf$d\Œ±¡-:µQuŞÍš°9³cöKb·K‰<[ÔA)Á³p$Ã¨şe%‡™¸}ñ×PW”
fá$±ç„èlú1ÌŸ¶Òh·Á$À<Ô()aÒ'¾1"&šAÇŒ”#‚1ñ?6ãäO8I\Y@®KÌç¾\È²Hş³VÌ§Z{or)Ü+‹©/ÀâÇƒ·MÑN¦_ˆ)2™Ü,´¾–ì1Æ”˜‘#s²1í/Îà9‘³XäÛ¶Å3Ï¶€Ÿ®áãA †ı>ğÜ¡å¶å#¦ğŠÓ(jHsĞç¯Õ6±Ô†BÆÀ°Lı\gª©8›ÅQ¿=—¯W´ì‚GL±m² ¾ÉlváL9&ßÇM?ÜÏ.ÚlÉ/ıa±T,-©|¥~parzav. /Ûnr“ô`Ôì!î ¢ƒC¢´ï™À®°F¬ªÑ‹¥{ßø¥c§ÄJßÜdÀq¤ø"WM˜šµÄøé€OBÚ`ãÛbs¥my—°ªAÆk«}²|ë
À¦Ã–YÄÖ£ÕÕê.H¢ô,K´º“F/]†•ãê–èàhAÖ2ÍO|!–Ã¥Œ©fã€şj‡©N.VRÀ-~´Åz¡ñöw'û¸7°l^]°¥­WÛ{Ûõü±S<†ÒKú™ÿfûÕŞşak&‡zå¾ ©oàL…ı‘•şĞèv=èƒÊÕÅ*¾:şv	kY:~^b¡QË‹küu‹7Şœò7ì·>Ò’„Şé=Î
„«6êBu^YĞ;•„.?¹‹’İT!*Iu^Ÿ†•	?ËBj×ó‡ã÷óæ½3³Ş!% ÿRFTƒ†—Ë0b3‚ŸÒ#8úuÏôóBK-;q"{ÙâÁ>(ğæîö:õdÎbfw`;SLcÉ¹+µ¯2ç0­IYİšj¶¾C¯®Wõ‰Oô.—¡#1b€?)CÇC-ÿ`ÜVÒü‚n$¯o²_üx}A}’×7ª©Ì~;¯ßºŞ¨j¬‹íÓ·¦Ãõè,ÖÅÏíñ©'éÿË]¸>‹ÿïÚz™üá×æFµ\&ÿßreîÿûiîÿû™üÃ÷sñÿN &L’r{F¢ıŸ»ëï×üÿ@®¿•µxAÛ	<·;ÕÖn¡yùC«cŸ]G~Ø@„Yï’ÏÖ}øçí<SOà[»?ªïŸï#úë¦x#+ÜÃ…7á*Ú~ÎŠö­ÒÃğjz—İûøëNï¬›Äy$2›ºSâg”N4/,½kÚ}&VäéÅç>²ê#Ëæ>²sY6÷‘ûÈÎ}d…ˆ||GØ1^¹!Í3'¾¹‡ìøs_Õ[úªÎÈósxÎıú~f~}µµ÷¦>Ñ‹/Û×@ ¶¹kß=¸vÆÎ} ğö||õ[aæ¢7¨Ùµ¹é=†^;Ã­n Ğâ²ÔódŞOhºõKÇ«¥cV:/<˜ßLü÷~ö.^BìÅú6ET!ÕWl)¡Í>tÌÓT»H¬`Ì£Ì­£-!Á8´öØëx®fM}oí4C±Ggløì*cO5^Ô“¥d$rœìl·qóš{]²¥?,,EG>uF`^É¡VHÎE‚o‡{è7¢kBˆ<…ˆwœÒö8/A÷85)‹!¦ÍÆQã¦´‚Ç&¢R#Gx‹F‰ÖRÒ)ë@ÁJ,¡¦¤½öwb4 :ióBB,Ú$Ğ÷ÍX9./Ãß…cÄÂXY,WJK…¨iê"*¤xÒEZÛÛàtVdi^ğõÈ·Æ±µ(Anp¹$ş‘€‹!Z {liu‰Á!ö=~Ä±®HœÛN¬ƒRG~gôú†à;°Şn>c–ddyR's	hy~Á2]éôİ8,ûX<<m§Îğ`{·(½$èbÈ<)ËÄå!è¹ÖûÄ,9ÜòüÕ'z‚2úázç†‹›#¾á“ÿŸ(Ë¥-w
ä…Š¥Ş‚¾eñ–‚½î?BW™ï¼¥êlFÄ¢Š¼JÕîäg]Ë‹*ú^bèuÃ9%šs/à%+¥SËïÉ)©¹}¨Û%4´²[ŒšN¹—)?~Ë' ,h¹5ñ"^ø‡JòÎ2³¢Ì-úÇÆèºnÀ¥i·†uµŠL:÷Ò»wµÓ¾é\ÔŞ¿_*$$’ ½ÚfA79>èà/<èÙ^}³´7l
ˆU®Ë,•ó«ÇùRDié<ÊQ‚§‚neãÃ”v®Àcğ	šûÉâGÙ7'!j7\¡WAgw¯O»zŠtˆxN€ÛnF­Ùkmíïî6P×¢í½›‡Xìwa0‹=×¨t"Ÿ¦ò˜›ÊÁ;MôÍRiù(6,²Ô<iš×Âb¾ô«¯FK°^HÓÒ&rH1
&>£«ŸÆÜß/>Ò0%<Ù¢a(İ y·roÀ¤õs1„@”äFT¬yBãP›×š–q„y†o
YâPnäs—OÔÉıuR| ¬è“Ueÿ°Ö
Õ³Ì³§ydœh	’”‚H‚’ËËôãW•‚.RÍçÙİ>=]üQWvg°Ì¾Æ±ıÕ›ß£×¬í÷˜±ºî•³
ê§lş•£îV”–‡'k­®‘%Š×ôb»è,âã™«H›¤İ‘E>Ôç¼a¾/®—Ëêò?Ñ¹„ºpŠÙuc}J$ÈE‰ybª&„Ù,ø¿0ÌÇNÒÿ™x4ü,şŸkk¡ÿgemı?«ësÿÏÇHsÿÏÏäÿ¸Ÿ‹ÿ'oĞŸ®ÿçSşŸàÿùÌ(ojyvÍp—hí#…®+w:®sF¶dx6¾#ûÑû¹Ci´Ÿ†CiÙ¨üd£Ë>ª[éÑ÷Ø¢×;;S7ˆ7JöÙ.š®‡Vîw­ÖA}ı6p°½Ñà4ï­e]Ğ`½°¬adÍ]ëùbQşO~ä?*Â^öÍó¹íOÙƒ6`ß"«şü}iÃ††Ia*z«lïm¶v[{G¹Oî¸ö‹òÉÇ­ûäRsŸÜ¹OîÜ'·ø%ùäNå’;wÊ;åŞÍ)WèvI§Ü¹3ípsgÚ¹3íOÊ™vÖq2¿@GÚ f×µÖC¸Ñ° 3Uª3êc8ÙÎ2¬åÜk4™qî5:÷ı	{Ší¹)½Fy¼Y(@Ã¹œúQÌñi_5ğé
‹|³³ÙG«¸ò¨ÌxZ&ßX¯ÖôÑ9ê»l{äÊ².˜C¦øÜ^ëíÉÛVëw{ûŠÍåu¾ÛßiF`e¼).~Ä€›BŠ¿hlıîõÁI»œÇ+=J¡ÓJ±¯p)AÑX«W8B!¥°ŞEÍD›±“¨¡:¦/^DßL†[³0+¼s±³* «d½Isïav_?Nİyó‹õDN—ğHÆş6atv1ğ ğQÄ_‘ê¢û*N"§Ì×NAîÍªH­o|z›]DEi¾¬ÙñäÎ›p1•Âè×0S´aš]ü¨ã¢J|šÒ]Tuei}'–ëzxËuÎìó¨§ÀX¨+áİÂŠ?vÎ¦¡QIõÃå0àüG¾ÌÛÚß{ÉgµzBÓd|¹îß¢mñ¢³hŞiBM;Ö”j(4­dvxHäğÃ…*£.Ú5ä£ú™Ki¾İdâï†v7‹ÎiTÇ‚Z1ãé½³=_¤ê[8OåP,j¹³Cñdgâ„Í?›õR›<…¿pLİnŒ¯Êé˜P‚¦tÑMK>sû]ô×Şc¨kĞ4Ÿâ)!Üb“ÿ$ÿñ”&Š«p Uû˜¦.©Öi:IÒÜ°¢—>2c'ïÌd7cÏU›pæ@×_¶Î¤‚”‚t!scGŞñ3#WoŞÜÕûés»Ú~‘	“ĞÌú uŒ÷ÿ.—×ËOÑÿ{½R^ƒïV®¬=]›û?Nú‹¿ùË'şäÉ®Ùaûmö{)šğİ“¿‚?Uøó/ğÿìßL²qttÈQ‰ÿş],Ë¿ïÿúÉ“¿=Ü0‡Ã¾eôM?@`\Ë/´Œ=yò÷˜o`v<œ-\âõy˜şCtyÿ‚çı»X^ôa>í[ÛN×úğäÉ(şûÄÜÿõ?ÿ—‹ÿV…Ñ¾Ì¤İ(ô@uŒÿÕMxˆÿõµê|ü?FšŸÿø<ç?BOüŸòÙnœ¢“¸xNÀ’E'7â×‰ÎO<Ä)ròHV—C5Nm
!l` à¸hğmì–€›A(g×í\X^ê	zn'Õ't„™ïOA_Şõ¬	<ã“!íÈ‰+ví€Û®‰k}ts¹4=w|\ù÷íĞyĞbÇò ÿÈ!»£!BĞü^¸wjEP6€E¹gá~¬«€Ÿ•!"ë’¾b(Ä¸ó(®9m‡(šO†‹}dğ:zb3«ß7Ûğ$˜üD|ãËCºLz%©5÷‘Q
Ìs2w7vvN¶^·öw·ÿ‘îS2 å:p}Ò¢J‘7•JÊ(¶Éƒ'±­ƒõğëËhs02/®b<í@Ü_•Ë%ĞK.åå0¥_H˜˜Ğî± „B`4âÀnôUÔ\wËV…atä‰+‹$4m»TE-ÜsÌÄO"S²)LÆÑnªXşO†É3ª½‚¾AI
N¨±4°»İ¾uez–
úåî[	şN ±,ÁûmãMCETƒ÷03ëÁˆ¥¬Ò™'êJ³XısÉGeÕ)JÜ¬	9¹µAìº§Ã³‚N)n
ÖtIFp!Ò3tŒÇQÈ-ÚªlñùÚÆ˜ù„õmê ş gæZÊìı&wÃ»ÈÚV I"ˆEÅU„H2¡“ûÚ
ï®ç²sv)'ÄßíÓÎ¼Œ‹Rï•ñRİ*ğ‰ÀEr79ÅÇm=râàY£¢±Ü;û[º
³æC½ ÓÛ•mÁ‹9³„+v'­%w&‰|tnRÁPØ—T`Ñ—HÚÑÁ)¯®ÙySŠs¹åcG¹Ÿ° p/Ôˆ‰îŠ Áti>,½H˜¢yaºÆÍÂ¡goI”cÔ%é/ş}±TZúÔ0PU
Jƒt©á$ßÜ/P¼êûñîVr„[ÑCô–Kïşp\zÿ«ÂÇµBSÉªq×ö÷í£Öî	J\`b¹C/|¯„’6ò¸â~-Ñ‡o@k™=”ØĞÊğw­¸¸ŒíèÛÎ:t¥7vñ£‚CfÛÑ…	Ğ »…7§RP3?1$HÖ¸¸ÅìµZ¾ ¬’ãÇ.£9\[D#šÛ‡­­£ıÃïOÈ•XM:½Üº—º>p·@ñŒ-}uvì,Èi†¾èî2Õ7Û­–ğI:“>^¤Ìãša¥˜í P› 0?ô¸Dß’ŒO¸›45ãÊnñ£Ş¾rù‘ş™Ì³vá‚kö<v•öğèè{Ò$HÎ](êt€jïĞÙ'<)l}°:#B£$\9Â‚û¯·ZMÜX?ikñwç+6zbŒåÜ©\Ã)í€ÆqÆ	Ÿ2Üş_üé À¼B…1?¦^øÎ1›j«ºlì¢¿ò «`f´ÅÛ¿–nqh_°ØAãè;ô§<³=?PxËÅ›U¯lĞ¯=¡Û¼âZ°Ö+ö­˜³u4ë¶oZÍ|ŒÿÜ(NzášQ®äæ°€%@è™#&Â•]T³·ö[¨2Ë©.Š³ŠÜ€Y…B@:Ï)Ö
<Tôq¤ÀëØJh‹.a¨ksWTR"S•+d;EÅH•ÒrÁ¡£ƒË%“\E$q)›«6ã¡ñ<L§)wBFŠ†‹à³3Å=X’27‹uŒK2ü¤ãíÑrb]aNì”^ã
‚Â·:æú}{·ï{zr‹ZÉ%5\†hÀp°Suk0®£1”O¸Ù&6¯!ÀIÓ2_óXÖª31Qğ5'- VŸ:éÁI„N1S7ó|Ê‚CBº—ùé$çòX'°ûz›+œ!Vœbªàj¦`“Î@;.¼9ó+¼“à”fëeãõÎ‘ê¬”Ê0êâ1V$ô×ªRX›üÅEKÂ<Ìà¾”“1¾»5ÏeñÛíyí®|6k#şz°ãê¤iúŞ“@g\SÄ%Vÿ-˜8—§I[¢üN‘Lçnÿz¨É€.@Ş¬Ÿ!³TYõ)Vÿû Á¤Âƒ\Ù¨€ùÑ²•´æ§ 3¦y1P|åpg€BìèË	4mVV!VnÔµ×O~©±†ÂƒóèI,Œ|ö1¾§IÓº"ÊŠêcŒœc& ÒŸ1b¡ÔO,i]2*!ñ¡^ãÂåÌóKêùˆ%ø¢{ót›3™åñ…>ôÔÓiÅ"cÒÒh¸ôw‰äÏèŞ¸Dv¥h¶•š`LŠóµ&¼öxñtNwGŞ><‘”s/%'áÄ«düõ¯u‡Nù^š–ù„ÑÅ,qOO¢P¸[š/úvxIXfQ²ÃLÈ¿Ñ4ˆ<&vè¼²
‚oƒ Å'ÏA6¡œØ4†fĞÓòIö~¬W#ÙŠ®üK-ápYè;D}y1"~!Qš÷9KÀ;Š)Gö¯1õ¶¹0exÕÉì;ÍÆ;@IÊ”*0ÚwjÖ¶Wd=i·wÙt 5;ÎçQL8lÄ³Ï¢"vŠ*GÃ¤,VÅ°× 2‹U.ÓvJgˆ¶ö¶Ò˜Ó31É¨L

†İÒxy1­‡”F0íŸØÛqI@ÊaŞôCy2Íj&áé¾ó‰g{ÒDÂÓ-§Lr™îöe‡ö”Õ|Ñ(Ì¶È«.?Ú7á^„r“Äz!òîÀªI`(TîpM(¶+ÑûªX)ûğ÷Sü«²ûÇN>¥+ «R^Jašò/ÀÜñä†lCø›è}“VMúBnÑNY™câÃëDX|ŠN³s±Ş¢¸CşĞåÖHÕ#œ³å¼ô¶6éõÅèŒWÅ¼DGDº˜ªr¤Çù"uEmú·Ó‚Ë:Ê¤Ló™§–´±å®í‰ã»já).‰Ğ­¦#>Üv?¾CvĞ·ĞN"ËúÜõL)”yv(#zŞÃã¡âØbÔÙã¼Ã¤îˆèˆÇ5¶lmM ğàÃ—+âS\>©ÿ4†,±İ~UÏbÉÕS|éå±E%µG“+™´U&m6%‡-•H³&%˜|³yt;×qH[(­–ş°X.IÂù¬ë;gçE´"Zİ>$&54r¥Î“‰:E%Xßwtàu–µ‰YY«±ıÀU‚öŸh¤ºX˜%Uo)‘ÔµùÔéÚy|¬¥/®¤LÂJ?"ï/Ü
ô“îbt¸˜ö`¥µ/±…©0©¢ÔŠùuHù›´ü"'ä©¬}ı,=gˆPÛÁ¼O×fä¥ü(BŞ¯Ÿipï.yï'“òi²<¾ì³æWJÅÔ‰Õt,¯º¢N]N+ùãKêŒõ´R"¾¦N]PÏŠ1»†x˜îD,x3ÿLã÷I?ÿÍÆÂĞ•0¦l	'UÃÌ‘X_ÚW	»e¢øUômf5‘hµY¾+XêÇ^Õˆj!ŸÖ¬E¼¥¶eZíİùã×ÀMÛ¾ÕËİÃçÏ³pLn'F~@Ã}Ïê§˜Š4³=e‘‡ÔX83vı•r æÂp'hùœ\ªF`[{oîç1%<½O@ÅÆp¼ËêÀ1úû¢S2o¢Búˆ
éïc…’Şó¼|ÿìä4”’ßÇ²ëg2¢ìÚû”IVàeÂ÷±üÉ#<¿|Ë<MÃ³+ïÓK(Ç1´ò}q	Š-%ËiM©ëk³xMŠHÑJ(ïÇ‘ŠImT|ı’V.Eeq‰ˆåğ}JVqi"+ŸV Ädl|Ÿ–dmjvx¯eW¥¼
¦Ñ·AQ¾“<ˆ°àwèºÍ¢Nª3ú†vw¿'NØHƒ"7RÃ›)hŸ44ÖËİS	Z/K‚šéeÕ“ô]©º?Fä{J>W”Ñ™0Yë¹ÛÓŠ©{f
‹ µä$æ(Ÿğƒ;t3Í;¨¹_ÿ!DĞ–VÜ°.GŸ²é/à·m¾?B"<M¬wL¬T1“ËL¡zÚŒò®0öş=‹iVíF–ò+gĞ¡Å_6V
õå¥<ü÷)_0VÈ¥…EkFŒsF¾Ò™0–Æâ§e¥ `
‹¥ãji)ÊGñ–G0l”Õ‘4bGì,³õGjT†Z€¿Ñå£™[,ÇrÒûäÁûpê½Ã·w3MW]£lx­Ôöa…/ÂáWõ4~<šn÷H[Ô‘éFÊëj.Z 9µB™YÍÊ Áí.Ié|©˜Ğ™ÚòÂÇĞç[éZºÓ!+4#”¶ÜÁÀu`<×õ&/¢ë¸W”ïĞòaŠ¨’Ñ{Ef¼Kk×Âb]´1­íïßÇüä—Ì Ó[eËtP¸˜4ÈéÚ´šìPô¢
¤Ó»¸rAqîâ]8ú¹-{İ>¨VF}D„¼b¿^+;|4…áÁk¯Ë1»²à‡“\åBQ^QâÑîğôµ,ÏEbñG¶ÈIJÍO¬2%¹UÏÄª-ÊTÀ‹¥+ªWiõG)Ÿ¬Û¯Ì>]½í¹@äeè—|A/"ŸÄC Q
eZN€³Ñ€d¦‚€´°A¦ÜÀÃNYe0zæ(àGr×)*Y(ÇK×»2½®è³ñœ'ñÀCüÀî\ĞM¢CšÇÊöÄhıã(ıCq÷ù;¥Ú$ábtP3ËÃ.ô±Ğøx&óûƒÜ4Í~²
ZEŸKÄ²\òÅƒ\g1»hşêõÒÂ?¥¿>ğŠ<TÃg¤Y>‘Õ<2­ ‹ú(4Ÿı™Ûr¸ó«c]iÊfV”ø}¥ô¤}t8Í&»†Cx0Q—ğÍş¨Vr£ìÍ+ÅÆ„U½€Øƒ˜Ph-VHnĞL(¶+Æ7&ÚP6Rüxå¹Å”=ş˜sï8(ÒxŸ|™L“b;ùšURı l“a©1xÒsYÁ7DKÜ¬*µ„ü¢¾š¾3OP{ kÓ!{ƒ#këA„ÊÁ»ñ=RJµå.h‡’ÿpì§œ^ùrø#¦êz‹ D?©İ5k&JXÈ# ©ş¤±$ìÀÜ§¦¸âÔ4WœZdÏ¸©å1°|é”iL°O³!ßíó¬KÄ0¡4…†ğÇ<ğ(*xÉn¸:nØ±ª•È£Y¡~AÑ²¸*JgNµO,6¬óU~#ÅYO!¨œ‡×øÈé^´ìÖÓ`xÌdƒñQŸ}@ÌPæ}(~ÕÏ•¢¶„GyåÜè˜¯<Øzj;µLñQ¡dM=@-¾ó³ÂX+*§F>£»ğ„o‰GAx”ã½04ì@=HkŸJHú¨0²óá‘u#<#Pº61X“Šg„ãÂcŠq$ı`t&ğ’¶©1Ô±ÈÒcç ãšÜT™yRxI“ù”3Iégª™åy1ødbSÑÒ-v2FAv—ÛgB8gâ0]Çff—a İÑı|j4bÒc:dRÅ$ÁĞôı+4«E¡ä¤ş2^th'ª$VÁÉğªk‚´po›üÆ•)Ê'Îº¥–™±=28†ò¸Ñ¯îC_:B—zÜø¶¸‘…GõO¸8d^:@À¢ıõ(Ş,–êÅÜmâ¿
ÿ¿‡
/KiRüoŒ—[Y«–+ÕõÍrãÿV«ëkOØÆƒb%ÒŸxüßå¡oõñŠnßÿkëóşœÔu;;øŸLİÿÿ{smú¿²ñ´<ïÿÇHØÿ‡-X­µŒA÷ê z<]_Ïêèør5Öÿkåõò<şûc¤ZxÒ¥œa\uZmÒ6*}"ÜvË¹üßÿéĞÂÔš®éuí¥§µ=öq³ˆÜÂ5
€©I<Z§8úau)l­5†‘û-?4È0»ß1‡–o°Fã~Ÿ÷´3ù"œ6Ö¡#höÑ=â:ÍÃJö·5Ux¹˜èéâ¬À ş¾ŒxhßUvEß1N´ca\æpKŠZÜ‡Ü]ºGÓyfI;¼,ÇÀvAktlñÆC¡ı´¾õÀŸzj jì»*Æ±A<³@[ô,ŒMIFÎ´ÃÙhï®2Xt¯R¦W#è0‚=p=¹X¼êÙÚ›¶£0×¸CÓ¬hI¥7yïZJ#Œ\nE2Í
x¸2î‹‰İ´²²^YdYåq¶µÊ"ò8q;9òQ‹Oƒ]G‹k?ğF¤‘@>µXˆXĞa’úš<¥Œ4oì¾é!_áÖ0¼ÑÍ°q.rºJÄ——ç™¯<;,`\nî-ÅÍx˜‘÷ÊíŒ>°7»ÿû?ş7À
qlRTuD*0m 4•;4ıá©åAÃlÌÊûŞÚ¦Ã~kùşu©xVĞéQı"Ô¸Ù÷]¼'“ºÇ¹æáß8:ê=‘°p[@;õhë®(¸é³£Æ!_Í¡ÁÊçqıµĞâôq%Y»Õ`oq€ %Ò¾REtî‰äƒ±>bQ=¼¿ Ñú§¢(¸½ï7 ®öÇ{‡k¤N×·ŞcDğJÉïÁXí–’•±b/‡ê‹•J±²vRY¯U¿®m|Mç›ğV4•¸gñøèXtù$e£RàhfA›òÚñ±…éîíÕ4DŞ{—ïáïSö­âÙùü=A	;,¡™Ÿ#´AømÑûŒlJtİçïÇV4‹bä[—Hü¾ñe
 ?Àø•çVa¸Ëlp–ÃÙ[Ş©Cwàv­IĞb4U¡©Şµ¡w‚ÁvqŠ#¡czç#OüªŠ1UMJŠ•KÓâUF[`ÚâÊ‹5„±˜Òey*‚Y0&UÑåU`¨­´*(r~z1‚^Q£1Ô¿‹ø4ŒÂ4eÜdŠ·‚úîY€êåE
¦¸Û"’Âş$Bd,Æ½ÜbWè~´:áõ ÿÙ?mØ

dT,gÁôŞPöO¬;E4°	uS$îÔ&óOãëûqÇ=§	¤Æèòå¸àÄH™0{ärÛêœe}0Ig¡›TøU++û"nè#Äøçü¢
ÊOWVÄˆåwx^5G!2d‹hÃ•G(İM/½‚SÚ
[–z
<&ğ¹tû s
ø†ğ&ZœSîîÅ/útETØ0~¿ª"MñÂ`3˜f/Q”Ænç@qåâ½ø¬V]»ó|ûŠî89óÂ¯© v(·ï^áShİ¦p*
w¥ƒH;¥Áê‰«LÒË¾ßmr»²úU&²l¡Òš( Ü@2®h(’ÒñT/Ó\õf“ey_I:/ñ»D_şÃ^¢©ÙL›Á-ü;…á 1 DOÏ¿ÅC†#9ÎQàF(FïT½&àE¾¼Ôé{‹ì(û¦Î®õEZ¾MUãº%½ÄVj¡÷dwÃùúÀv’÷ş41‚N\SxÂÁ~•oø®ú†o«(oÄ]kb«#§™¼sh ËiV°ŞòB%7éäk¹-)ŸÑk°oŸ–rĞ)¥\`ÁôÃÁG?µ‹œ”÷à<£«æ¤ú£G<6¯=»çà½nİ¬×€Q RfhÃÈ°:ˆ«OÏÆ¾@gàp©¶ÿ"®%¦Süh°;V,ËUß?¡+(R¾‹†#®éã¦7ıZí2³eä´„n1¡°"§—c—J„'€ÉddâuZdä è†èÍ0Z®ŒòÏ?O%ZZ{M<¢:7rÕ .ŞŠ'0ğkÈÌ³À
ç%Fúˆ’š¢ñ`"Î—à°–ÿ-æÈ'CˆûÅPC±ğ÷©…‡¤ØJ¸¨×epûŠª}Ü÷†ƒ›òŠáÜ2å=3ºé ·ËÅeU¦#ü.¸=+ÇbÁ«zŞïB	©ŞîÂ¥U!¯ûh‡™§(ÎYgaÃ~(ú Òºáuzv`‘%-—{qFÉX‘†ÔdÑ|åz|1…^GªöÉÕR¡õ†vÄ‘?"3 EíC|¸«ªÈt§J`ôLïĞi8; Î¾°ğúq_x¦ ¾Xr]gÉu]ß¾Hµ®RüÿÈ”¨­Ä<Ç•}øŒv³ÔÅ  ±ä³7Âƒ«üàÚ~UXØFn•rMİ`ûáÚ¥ot9·Œ@ú]ÒzBÑçCÓD­ÓW×À<êÅc§É•W:u4tÑqnU.ÏV…ƒ„½rebk„dÄ»r]ñé“ ’R&¶IéÍ)İcärŸø-¡±ô‰5-.Z0/¾€Œ)ìSüf4RôæOÜê@ÆGa¸ú¡	«0»v#ûZvù}›¾ˆ%Ú_aZ‹£"T	-ílŠ£LJƒ$boÄZİ c*“D×®ZŸFçsyg¢uC`Šª‚¯W]®%~ã‘cÚá£¢ÍÒœBÑĞK,IP¤ÅÀ£ù¨=<æ6Å—LÚĞQ†Å®ğ`†©ïŸ …^\Â¯ 5Ø+å3dˆ ^)$ı{}Õ­+>ÿ4«ğ)XÅéÎMÒÖ[Öº´Ğ
Is‰“S7®á#ÌOR/÷ÄÒ›É3Ó„ ¸…ñ[Hi§üõ!D‹;ºI¢eI1•Z‰¶%œèÒzÍˆV£<×İ flï-;8V¸œÄSèÇ)h~â¢°©¬ù¬8%†õr--’‚ÊíÙŠ¶ åµø
õO’Ç`».¿3ºr@Ù¡ICZ‰^ãö[[O/ûÖº£UäUÛà"‘¬‰‹':ª= Côø”æ™Ó…|ª¨gc²Ş.ÏU«vÑU¶Øéº§a”|Œ[ R[b¥Ä=·Ò.Ë«N³ôp0NÉTïSµj6ØëP)ãY…W•ª„0BôÆ¤,ÊTVÇ#9=TX¤8•ó')šê¶5Œkyèu­kbB1…:t	Íâ¤mâR»3Âm_~÷XXiª"(f÷H%•œø6! 5Àí F\ÙÕ!eÉY8®¯SV{Œ-©Ò;>©“DÒ_ì‚‡´CR!Ù‰p0€c4İRø6Q¦-vÛ•m-‡é­–"X¨¥áy•ª%ô”=cz«õ‰!B€*•at Rä <óJñƒZ©1½Rí.á‰ç¨*`·‰UAÚsLkß*¬VfG¿uÏ°iK¬æöKb&ÜÄÙèˆ»èîè)¹iĞS³«"—å4Àz åWªìŠ=·;ê¥³ÁU¥jTŠ±f”±#¸8{íğ­ÆÈ´JsÔ$*(P5Ö8
iQ ÒÛ^¡Zú¡{Q1¾6Ê'•õõX™ßâ§$¤ä.[(G4Ó=5×>¥†Úª„NÙvLb–!¡µ¤6uÅ¬öúU\ıÆã¦.±H÷ùñ%+aĞÜßmlï¥ĞxìhÃ%K¢åwÃ ;}’j¥|œ"I+å(N|7YBO²@Èñv³@OŸÂ%O)tô[8tšl§á ¥K1Â¡£<&ÑUÂËL[±+ÕÇ jHyåıÉ•ƒ$WTÛwºšiğ&RøCÍùÔòmi;p\œ¨ÍŸº—éÚéz6Ç`6zóítà”ÀmŠã*.ÛPo@ÒÄ¼~¥œ`G¹İ1’=y‹c~å?wËÉã:)t9Ğ©T[Ñi‡„´—GŒè|Nâ0¨?%>œ¨_«‰‡!ì7„Z(=.Pd™™.[.\Ü3h,]ĞĞb4˜èÅ4Ê‰¼Šöè)‘EŒ+GŠ¶òŒÁ}ü‘Òõ3Ô5Fßx¹µ×ı=X¨£áeUãœG"Fç`½ô6XµOE@=a*Qew¢û"»,÷æ,nFFz’Ëìô’77’ç*3ïÄâÇ2}ÜvEãO›¨ˆ1²Ú›â"b­†ĞÆÃR¥ şÚ·ôïd·xUbMê’.!šÓL#U†ßÈˆÖE(°Şëãî‘ë$‹ÙÁ(Rú9ĞÔ%¸ jM	”Ÿ`f° ãß¦ƒ)|²İQ  Æˆ4Y€ñÛt U6T¾ƒôE´Ëbâ~¥ynñµpn†I\M„®9~”A?B°¾ˆ_ÉİÿR¯ê‹Âñ"ÄKÛÍ„ˆßğ²"_ŞA
¸ñÒ*ŒĞD2_J/¯ÔØš	lÁLX3–l°;LÅ@3{ŸI£«4Y¦Ü›i;iÆl$¬n¶»OÜ¹_1UË\¢[¹m5+À7´YóR‘	ÛÖ‹0ş¥4w5†×"ÂĞ¹ÀGw§‡”#D´¨Ò¸¼ ®gÛ¾?‚iJ¸«ĞVÿéè‡®ĞâÛCş#D˜xKÿRX/D‚‹JyHEæ¢Q„|÷
ş.áÎTÈĞYæÂòŞ/÷‚`è×J%DÔ8§L@çA‰ä!¨¥%Ğ8GA‘Jù¥B-—[aïZÈQöœó#(
 ×êy}Û—T%µ€ÅıÑéÀæA³èí-Ê— P·cwp{o¬¥i
·Qø«.9äĞÕÂeÉÌ«LºV²Á¾wG R®™{J›Ç&tèğZv±(ÂÌ€}‹èvWWW†I ×;/‰êüÒÎöVk¯İ*Ğç ›îXŸ7¡“ÎC×1åùÏêæÚf¹²Yåç?ŸÎÏ>FÂş§Í/¹‰ù uŒ?ÿ	¿Ÿ*ç+›Ğÿë•Êüüç£¤¿ø›¿|òçOìš¶ßf¿—Ú¾{òWğ§
şğùN²qtt(~b‰ÿş:–åÏ¢÷Ó‡G@-ïûF›'F‘]8hcFóYÿˆÿ¶şşÿüİ½Ú9O©)æÏú uLÿ›kO+±ñ¿¶¹¾1ÿ‘~[|¥rÌœn1ex‹Ûİ[| ÀáQõÆ«UöbäƒÎ‹õ&’v‡¤wÿ’µ…n½ü¢Ù.@™¶iãyU¼fÎM±úl•}]Ù¨²W}3N½Ñùù*kƒş£åáñó@M«O5Õq>5F¬ÉÄ§v`áæéÔlVÔôú…w×³ î¥[];K/î€İâÎF/®y4Ñ/ÜHÉ€x–CëÒFe;‘E~àÙ´(óºséKá
-ı_iÕE{(Y®:üæ‚(ID¸„G¢¹¬AêdŞÈxœıëhŸL­—Rh~/ğ‰y<€†) F}2ë>j±ïl<šu]ƒÇÊ3£¼iTË•§Ğ<1xöİû2‚ÁÌQ `RŸTq=¿Ï]B8t®ÀüÀ{àMã°ş¯Ó›9â2~W»R_:ıæ¸W;¾*±w±ğYïÙ’ÌÙéöêzdÁè‹™RÉpZW|Ë£×}-²á45Ù§©!4•x†øõ›JŞ^j^%C?îkE9İÓåFfüS‰6%dĞ	Ôàiò5€¯G·…¯‰ˆÉ  Z H5/F†– ¼'^M×de‡º¹}vo¸e}#ö£ıD@R@ë÷d·Ï  6ƒ“1¤Ä/hÓZ?¢w‚²W(àë÷mi´í=®ˆÑ“>h¹(şpıc}‰~IDÃœá,=€ìğaÉ½õn\æ5õ9&o›àÅm:0VqØD;İÅğpºLAû`Ä.uâD/…_ûô5¯ö¼ò½¡’9°J-”d.x«åÂ“Ìo!W˜ÍñMpzËîgf
‡ƒ’»3>7kQ~ÉˆØ
¸Ó4pZ&…¡øIq>¬/…±zÃ—n¿UËoğEeå+hÿÆFİÙiµê[¬#æÒOÖ&ÌdÔ—ğC—+ÀÜ·ïzus¸a†t0§áwè^øÊç¯Ò ù}‘Æøâ
m„à¦ŠÃªå0OÄá 	˜f}InÄ@±òø.ñÍ©¨¸u»â´¥÷¬áí (Cÿv0¢}+	âÒvëK—v"4i`†¤KŒ†Jµõ%m£©X”»LŒä>ÁK’Àê¦l±x ³}@¹»ÛÜcùS¼½v	¬—ß¥;©¹áv®Š‰?|^dà#à00½k‰V×‡nT&Úàn7b‘²¯],’êñz»)#Ä ätİ8(ä¾¡4fqYş,ŒoÎÒŸ¸¹?‘Tû¯ºq7Ë:¦´ÿ®UÖÖªëO1şßÆÆÚæÜşó(é·ÿ:Âşûÿeká^íœ§ÔÙjôOÿÕÍÍÄø‡_óñÿinÿı¼ö_uÔı<ÍÀªçĞkpÜ¬ºûÎÍÁwGá§nÊ¼øùÌgxÓy¢!¿‘ûØÌ	q?#â‡¥‡Vt[“ò?Š_ôpsÌ$ı­º¿ÿasc}>ÿ?Fâñ¿•0À¾(Š+,v%Î]ø¡*>P¬‰¡ørMyÙß®‹·ZØË·âí¡bàßn5,ËqøZeíëgµÊÓµ§µuHµ¯Ÿ}ıl¾ÊŸ6¥‡9›m“Æ9qÿÇúÆÆÓùøŒ„Aëºò­ï©l¬¯Ïı?#a¼Â‡®ã.ı¿±9ïÿÇHQÄ¾‡«cÊş'ÿ¿òÚSºÿ¥<ÿ’bQB¤ÛÿµÍJuŞÿ‘ôp­SÇôı¿Qİ\£şßØ˜ÿGI‰p¼PÇíÇÿze>ÿ?NÊˆØ;Ó:Êã×•re“ïÿ¬o<İ¨bÿƒú?·ÿ<JZ`z\òÜ{%nûÃ:]vx–!—ÿÈÆë„wäş•½‘_ûÜ!²C‘ª9nQÃ[!FC¼´áÜ3~.Ç¯Ç¿k‹®Å]ıÄ²ö*‘çîO:¼áwl0éøåÉ) c\ß"vôí"Gw„œ7z|á¹İìO-¥ß0Û:n?ÿÃ,0?ÿû(IÕÿĞkû3ê|ı¿YFı¯Šçÿæıÿğ)ÑÿüŸ˜&Ú»ÆğzuLĞÿÖÖÖ×°ÿ+ô§Œçÿ7ËÕùùïGI³Ú¬;ål;g]ØÊİ…»¬Íoñ?§?NÜ'Æñ³õÂÑJÇ=pğB£R5Êë1Ç›¸ƒµKQ±øÙB–5)ºeÌ)&Õ­E„Gî:Íæ«eö+öê`ƒ«Ì’¶»n—	\|Ëbç6†¸áÍc=îC~üˆhìˆûå—FCtEN9ÚoîQëf„)zÄ\_Q¼S]“r<ˆè	yšSªC)Cä5Î­`yIÄ&İkì¶–VY®<:áåò	`QÏ€‹@wh‰à¥¥¯ü<ûŠ)Xrä#O'i˜„h;Ár*¹¿Ÿ '<İ„µv¾ û~_–W¸İŞQÊW£òt—FVsxÙ×íÖ!¼²NA»´;ùqñaÙ¼À²Ñn¿İ?lÂ&7ô¡%Îß<"%¦{÷•ÿ~)FŒobÙÃXõ‰ìØQöÈ-Å²GÔçÆÀˆ¼D<· gTàuDŸTğH¿(wë2#7RrG§ëŞî´åøçoH$ğ7Ë¼½á!©:¬æX"É~ŠhÂ‹EôW
9EeH.ã
"¥ö”ÁÑgR©ˆjõZ@ê •>÷ûE§ÌûãfXÇıfÁÄúos®ÿ=Nš;}?¶Ó÷OÖË{G
ˆ¬‹yöc÷Æœµ…?ôc{\WŒJùQ=®S¯1EñªŞ`Š—·Ï(.6œQÜwŠ?Ò|	l2ô`lĞÃÀ¦ëİzâXß ßş~–Ë¹›¹á÷O4¥]Ç:ë:&ÙÖóÿúÓ§óóŸ’æóÿ|şŸö”ˆÜS~¾k>ß+(ÌŞ•e]ô¯ÙÙ#bó;tÜ3º
Ô9ÈY97ÛÊA?c+ğ_È'®uKW?W²³bÀ^¾ŞÙaEº,â7»{j{şœ•‚ÁPÍGñªÏYÉ= ùº&^Y`;bp›ŸˆåÕêêÚêúêÆêÓ;‘s{oë°µÛÚ;j|)T®GÉj•(¹2-ı„ÚŒô»Á>÷<ü¹’îÿyÕ÷OÈvmø|£f&uLÒÿ6àAø®óøß›äÿ7×ÿ>ÍlÀâÑ¾[î ~FíkG=¦¨hg  $øó)Úš‘¦³­êê^AÓØTL‚(o@‹a@›€˜GQÉd
íÌ©Z˜üòtÅğ‚›]¹È^û@i½6ÿpt‚>³º÷‚Zk¨¢½ÉrÚ©üèju)5"LQE—	€1ı"EZKªM¡ÀdH)¶L;ƒ5ºtm°sÏ…}û4(ÑÍm´»vjá–".`Z
ŒÜ‚–›N³Â¼İ“ZÓ¾û£®Ë:Ã$ğKñ°œh¦ø·« Å©KğyÉ”
Ò;Cg»©üğR–®evà®`úZº¢ø¤jÚè©BÅ|Ff,prâœ´;¼=d7¥'ğ¥Àal_˜8Ægù®#6Å2’-VE÷¿Ğ9é²+=[£KŸxM{…›ö#¼ğ$˜!Ş¹w( Şç”û…ê¸!H‚@ÙÎ½5À¯;VpåzôÓ¹äxk}ü%Ë½rù}îèzhÕ}¸•Ã=¶:W³r¯p Ö]›¡Ü[(ƒ,Åõ¸Z†ÃİŠ€ï~¸—Šñ\ëƒÕ!»}Ù±İ[ët·Ñs•s‡w€uJğÜ¡
ğrº¦×İÃQP®Dû*ĞIˆ÷D]\s×£~`±AÎÏ=§ß&éúŸè\Ãó‡3¬c‚ş‡Ç}Âó?Õr™öÿÖæç¿%½kí½ÚŞk½ÏZşĞÅ”È¼#.^ªƒÂÿË½{ÕÚkno½Ïµ[[¯·¾?y}ĞlµÚ'o¶'»ßó ±í×è.R?3ûşlO‘ÌÓC$}üƒÈDù†§.fXÇ¤ño£ñ¿Fñßn®ÍÇÿc$Û¹´œ¿O Ïs'ñƒÈÃÉáä\Ó>7öótßÿ£îIxuëÌL@í?›¡ıgcÏÿo>]›ûÿ<JšÛTûOÿÏM@`Šî‹N}VCxäıæŸ46xXP:ã=„hŠšîaš
úMA™°g(~6Ö 5vßÃ‚€úşAk¯Ù>ùmãMƒ2Ôó4j~0/ÍÒİ‹ŠñµQ>©¬¯—òºñ§R
·Iét}K÷ä¦bƒzşóÈ$USÏ„’î0^ğĞÂsØ·(êYœµ%tËĞOÕ4‹ÿÃC* køb&uLôÿ^[‹ùm–7æñ¿%ÍıµâhÇıµ´ñğ“uŞjN ŒÔ]·P5'åÍa 	‚k-èëŸªGW®$ìvê@¾àùp\ï<×íÔXø2çâB§À)Ş¹éØ?’K¼şf±ãÔiîôWÓ`w ÿœ,«©Óßr T}Ë!X.LÔ™ùç[AşÜ¢iæiæiæiæiæiæiæiæiæiæiæiæiîş?±zË ¸ 