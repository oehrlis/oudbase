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
‹ ´K„Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹ä,	.Ñøà×f ]ˆ€4Üå×”´³¢–×šD€n\wƒGâ†áGûÕoÿ?ø§Ü/¸ğû½ø83«ª»ª? )ÍjFº»*+«*+++++óÌvJO8•Ëå­FÿnòËÕuş¯H¬²V]¯”+kë›UV®T66Ö°‡FÓÈLPñ]kl>Èv~>æ»hGøï$Áø»£î)4/ù†ß{€:Æu}ÆÆ¿RİX[+¯oÀø¯¯U¶°òà’H?óñ_øE	IàÌô{¹Vœ]h‹;İ[œ9ØcÏ¾4»¶Ï/VÙ³‘o;–ï³¦uiõİáÀröKÖ‡®°ågÍvÊ´MëÂò,Û<Ó÷-Vıj•}YÙ¨²}3Î¼ÑÅÅ*k_ÙÁ–×7îÌ‘Ş7–ÁSi>6FAÏõÄÇv`›;°z^ßfË®å˜Oï—Şı&`tÜ”nuí ,½¸kúÁvÏt.¬î³kŞıM3ˆêV3àåÈº´}ÛuYäípä]ßâÍ°vÇ³‡\vaÁ?=‹Ù4ÍéXŒ·™>ó¬`ä°Ûµ°'ÜÀò%6Ç=GŸÃ€_Óvú×lä[]vîzÌr.mÏuhPapzî(`Ç¯šE¨>Şç0¬PëÁĞ¯•Jst†½Sâ=æ#‹·f>¬Ğ=ì[ *×»®Ác¹b”¿2ªåÊ&c8
c;ØfŸ]Zv#ä©TJólÉ<î÷À…°-ø…™]‡¹çH)ĞPã&g‘mC¥îÀşÁ ±û@ÏYïi²¼lŸ6÷ë‹”§Z1d\àÔ3\ï"C´œ.¶ñşxä\æÈ¨°Wfdù÷hPîUë¨½s°_‡ÑÌ5‡‡­ıf=|ô²•gS¦ ]ó¬o±¾{ÁÎmøa‡0€ıì İªçŸ7vÛw€´qSp6µ·vO÷{­úâ2R¸|†-–¹ã½ÃÓæÎQkûøàè»z¾†yzù|gj_ü e¸)éÅÅÅ|®}Ü8:>ı¶Õh¶êyzBödÂPÃ°-~Pj¿aË¯8…Ã{Ñ}7š³lq%ŸÛkìì6šÍ£V»]šşë™0!N/×:::8ª—s*EÜ$9¸ç#§ƒDubààf;ûÎ^ì¥o^XËö!Î[›¶?ì›×<ÃŒkGr
©ˆš^5İ=ÿ‚åwöŸ°¯x5>ÈoŠ½KmöÎî} ‰ıíÖSVl²o@Œè6÷á÷÷ü÷!Ìö+×ë>âÊŞ¦UÂX±—FìT9[pqÀâOÅ/ÓŠ§Ì”Œâ^ZñNÏê¼£åÇ³†}»C|)€Òî(Iò½Dò­±SoÚÕÁE‚í™´ÆË —ÚuÏàŠWÄK2J'†¼Eˆ/ÉiåvİbO°ÀØ=xÜá†ç³ÏÙxY¹aÅ‹€•ÙÛ¯q}wr²™Û}ËtN÷FvÀó-~¨ŞĞg«k­ÌãxéåËŒŞŸÛ¹›ÜÌ×ºÔ©µÇ	‹ó¨ÀÀ2>ÔT§^_.ä>P;wö_Ã"Yù¢¶r“F„”@Ö5ßY$[ï&ƒsÁÎ,ø§Ëû¶üºœ@İ€Ø•ˆdf2Ç™,j'80ßU‹[8&yx`ùcÇ;{­S £½CXXº –°ü¯¾ø®øÅ øE÷ô‹ok_ìÕ¾hç_­=:Ê.êL(L«”¾C½¿ÃZµzóy5Ã
ÿ®e0R’,dùf'šyZĞ‚oò¬Î„Ÿ2«Æå¥::=óG8à$Ê³e±¢©ÌÇ°¤6¯Æƒ	³Á”’?ı}„OW=œ÷„5VûÀ—píºZ·mY„VìåÄÖ¥¶p<8-«ÒÒdk»®c%yÓ‡íéÓ´6}f½Ÿäô÷ü9d‘ê‚€B‹³nÊÀFC`ƒÀ½€1¾·ƒ&-|)Â“è=Á’+ÈÃìåB¸æ"w…•6!=«ìª¢d
Ù[ĞL¶R6ØkØ_0sà’ÄMïb„[dß`m˜\#ZÖ½w\å£g¨UT§­BfË¸´¦…¿1¾*•Ø $’¾ã4¨>.g´…<n<»aP<5¶w[¡tsú¬ÑutôÄZ©Õã[Ö^š—¦İGéQkO¥2	ò¶;êw	Bà:=¾ãÃviİ~0}×ì²“Åß y”‰¤
nmb{Û.¬ö-¾9?‡†Y]µüúÄò-ÏƒBtº$EèÅ'¶†§ÑõFƒò‹Ğ	uÜÁÀttpÕ;€ëúŠˆ
umÔ=Û÷I²JJÙ*EOC[1ŠÆ~ˆj ¦ Ç±8KüÚÓ·D«m1Ah{e1EÂ)¡ÛÆ”ı	íHéCœÖ±¦hU v´=RûUó³+^‚§ä÷©¢2qÛŸ¾ÉRğÿê«Bl§ò[T’]™c2ä÷Ùï»Ú4ıõD¶óÒyç¸Woz†¼WÄÌRQr“`ş:NGÖÀ½±ÚBšÏù°h$œxdõi©k]–œQ¿¯.ÈøÏœP<Ÿƒ+C„&òşú>€Æi äœ@¤œaAåâÆÊ»ÎIÑEfã¢‹.¶ğ?ÇlqN—èy#-WR¤Ó¶•ÕJ¸¯<·Ë…¸CÅ!ú´âd£Ë>~„/¿`Ånì³Š Vk¥µa]»Ø)8EvÎ`‹ËçÈm¢¥§Hz·PÙ[ˆÏ:ÖÂÙ?Fb?'¶í9!Ë¡B~ÊI§èòt7`şås|Š„A*¹ôk˜ÿ„òûå/q˜®X^ÑhÍiIsáˆèıRQ+Tö¦ìHœãÇ©&$ËÁí™ö½tÜ
õ9dy­aëå<î¥s9Á ×İ)pŞ¡€HzAï¹˜ÚÍbHU©ÓÃÃ”¼è.{á|»°wd«—z.N?\ĞÄjØÇšC€z'¾ï¥YïÒ®5kß×Z5¥½pûÁYx£
²@—\3WV˜îe!&+ßìÛ»V	Éôàºæ…¶V51×£eäø^æPUcy½;jîîl7Q‰ŸÀªUĞ©2Ê¯ec«lqE](h/r½}È3<.Ö±©-¥QuİÍ³5³cöKâ´s‰<[ÔA.Á²p&Ã¬şe%‡™¸}ñ×PW„
fá"±çëdú!ÌŸ¶Òúnƒ%º óP£$‡I_øÆ°˜h3S	zÆÂ;†ıDØŒã?á"qeAw]b8õåB’Å.à?kÅ|ª¶÷&—B½²˜ú ,~8|İ¹áİô±D&ó[…Ö×’ƒ#VÁ˜3r¤`\6&ıÅ	<'r‹üØ¶xîÙĞÓ5¼qÜ"0 Á0 ß‡;´¼À¶|Ä^ñ>ŠÒÜôùkµM,µ¡1ğ@l Q?Õ‰j*
ÇfqÔoOåë-» SÛ†$ˆï€3›]øKÉÏÃñĞÏ³‹6[òK\,KK*B©ï]Xœ™w—í4¹Jz0êöOÑÀ!Q:ğL WØ#Öû ÅèÅÒ‡ı¯ıÒ‰Sb¥¯o2`;‡®ø"WM˜šµÄèé/BÚdãÇâp¥my—°«AÂk«c²|û
À¦Ã–YÄÑ£ÕÕê.H¢ŒlK´º“J/‡•ãâ–àdhCÖ2ÕO|#–Ã­Œ©İfãşj‡©Ş3œ­¤€[ü`‹ıBãõïNğl`Ù¼zÇ–µ^ìì8j×ó'NñvHÏégşëûG­mXê•¯ù†¦¾g0ö'Vúc£Ûõ`JÈW«øêä›%¬eéäi‰}€F-/®ñ×-Şx_pÊ_³<ø@[z§8+®Ú¬Åy}fÁèlT²üä!JS…zIŠóú2¬,øYR»?7™	ø—2‹ 
˜44q8_†£¨ü”ÁÙ¯ëx¦_§ZjÙ‰ëéË@€o4÷vöÕ¥'s3»Û™bK®]©c•¹†iMÊÖTµõFu½ª/|bt9m‹©üQ™8jù¯áŞ°’ft#i}‹ıâO@ëû¨êã´¾QM%öÛxuüÑõFU#]lŸ~4îGg±,~j‹O=Iû_nÂõIì×ÖËdÿ¿¶6ªå2Ùÿ–+sûßÇHsûßOdÿN¸ŸŠı¯05a‘”Ç3êíÿÔM¿4àÿ2ı­¬ÅÚNà¹İˆ>°wÕ{ÈZûü:²Ã†N˜õ)ùlÍ‡ÚÆÀ3µ¾µğ£ÚğşŒLxÑ^7ÅZIá&¼	SÑöSV°o”†WÓ›ìŞÇ^wzcİ$Î»ÀÙØÔ“?£t¢yaé=Óî3±#O/>·‘}TY6·‘ÛÈ²¹ìÜFvn#+XäãÂ±Êû<sá›[ÈN€?·U½¥­êŒì8?…UáÜ®ï'f×Y[û¯ê­ø² y} j››öİƒjglÜ ooÁÇw¿ö`&zƒš]k‘™ŞcØèµ3ÌêQÑ -.K9Oæıˆª[¿t²Z:a¥‹ÂƒÙ÷ÍÄ~ï'oâ%Ø^llSXµ`R}E—êìCãÀÀ<KÕ‹Ä
Æ”0Ê*Ğ:ŞŒCq`áˆ-°gánÖÔÏöQOc1d{tçAÁ†¯®Ò÷ÄqãY=YQJFêÓİ6^s‹£K¶ôÇ…¥èÊÑÇÎ( Ì+°8Ô
ÉµHtÃëÆÑ>Úè’"OBw’Òö8ÏAö83(‹!¦ÍÆqã¦´‚×&¢R#GX‹F‰öRÒ)ëBÁJl¡¦ì{íÄh@ô®Í±hc@Û7cå¤t²Nce±tR)-¢¦©›¨°Ç“&ÒÚÙïg…—æ]|kY‹d—Kâ1¸Ø¢ºÇ–V—üWlßã7AëŠØ¹íÄ(xdwF¯oî‰# ëíæ+f`IB–7uÂ9—€–çWÜ!sÑ”N?Ãâx‰ÅÃÛvJá¶7‹²ĞÛˆƒ.F€üğÊ“²M\‚œk³Ì’Ó-Ï_}¤gèPF?\ïÂpñpÄ7|²ÿ3`e!·åF¼P±£Ô[Ğ·¡,>ÃR°×í‡BH£á*óİ‘×±T™ÍˆHTáW©Òü¬KyQRŞKL½n¸¦Dkî;xÉŠCiÔò{2Jjîéz	­ì£‡¦3neÊï_…ßò	(Zn½ˆ—§~à¡ƒ´³ŒÓ¬(s‹ñ±qzG®pnÚ­!G]­"‘ƒÌ½ôæMí¬o:ïjoß.I ‹fŠ^í
³ «ƒœNdğgŒl¯¶YÚ6Ä*—e–J'ùÕ“|)¢´tå(ÁSA×²ñiB;àÑùÎÉıtñƒŒ›Óµ.Ğ« ³‡×§S=…;D4'Àí4£VÇô‚‚´¶öö(ë‹ÑÎşM‰C,ö»0™‹ÅëÔº‘€OSYÌMeà†&Úf©}ù(6-²½yÚ4¯…Æ|éW_Œ–`¿¦í_XÈµNŠõ`â3šúi„Àíıâ3SÂ’-š†Ò+·Lj?C´AIDÅš'$µy­i	G¨gø¡%.åF6wùDÜ>PïŠ ò}ÒªÕZ¡x–y÷4„mA’<Pt’èÉåeúñ«JAç©êóìaŸ¾_üQwvç°Í¾Æ±ıÕ«ß£×´í÷X±ºî•³
â§lş•³îv”–‡7k­®‘•%ŠÕôb¹è$âã«H‡¤İ‘E–>4æ¼a¾/®—Ëêö?1¸„º0ŠéuccJ]‹z$f‰©ªf³áÿÌì1;IûO$âÑğ“Øn¬m¬…öŸ•µ-´ÿ¬®oÌí?#Íí??‘ıg8á~*öŸ¼A?_ûÏMşŸ`ÿù•QŞÒòì™ßã)!õµ½(d]yŠĞqsÒ%Ã³ñMèÙŞÏJ³ ı8JËFåGë]öQÍJ¿;Ä½ÜİºA¼QrÌqÖt|=´r¿kµëë·#€íg0! y¯-ëMÖw–5Ì¯¢é`=_,ÊßSàÉ¯üGEØó¾y1· ı1[Ğì$ÕŸ¾-mØĞ0)3ŒáDEk•ıí£Ö^kÿ¸±;·É½Õ~V6¹s¿µs›\ªcn“;·ÉÛä?'›Ü©LrçF¹s£Ü»å
Ù.i”;7¦nnL;7¦ıQÓÎÚOæghHÔìÚ Öz3Ú ¶ ¤¦J5F}#ÛYºµœ[&3Î­FçV£?b«Qq<7¥Õ(÷÷/¨8—K?²9¾ì«
>]`q€.pu6û¨W•OË$ıëõ"Áš>ê1G}—màˆ\YÖ;æ*>·ßz}úºÕúİş¢sy™/äv›ÑØDoŠ‹ğà¦P âÏÛ¿{yxÚnåñJO¡R(Ä´RìÜJPA4'ÒÃ*ÆPH)¬Q3Ñf$j¨„é‹QÅ7“áÑ,¬Š#ïBœ¬
È*†YoÒÜz˜İ×S7Şül-‘SÀ%,’q¼M˜]t<tÑW$ºè¶Ê‚’È(3AµSt
·fU¸V„7>½NL¨_DEi¶¬éñäÉ›01•Ìè÷0S´aš‘]ü ã¢J|šÒ\T5eic'¶ëèzxÛuÎí‹h§ÀXtP'V2Â†…èœOÓG%Õ—Ã4‚‹ø6oû`ÿ9{šÕê	M“Nòå¸‹¶Å‹Î¢qÓ„šv¢	7ÔPhZÉìp—Èá3ºUG]ÔkÈGáô3–êÓ4|)8šÉÄßínV?§õ²°8½³8ŞÚ8ÛÒøYê¤¾…QñTÅ¢–;O6&Nèü³I/µÉSØÇÄíÆ(p1TNÇ„´¤‹aZò™Ûï¢½ŒCYƒ–ùKñæ[ü'Ù§4Q„Â4Técšº¤X§É$I3roÀŠ^úÌŒAœ|2“İŒ}WmÂ¹;YÙº0’R
Ò…ÌƒãgF¦Ş½¹©÷-Ò§6µı,ÿ§¡šõAêoÿ].¯—7Ñş{½R^ßXß¨°rems­:·ÿ~”ôó—OşüÉ“=³ÃÚì÷’5á»'ªğçŸá<ÿÙ¿›dãøøˆÿ¢ÿşü‡X–#Şÿõ“'r¸a‡}Ëè›~€À¸—_8lÿÿzòäï1ßÀìx¸Z¸Åës7ıGh<+òşÏûw±¼hÃ|Ö·vœ®õşÉ“ÿTüÀÜÿı¿ş·ÿV…Ğ>Ï¤Ez :ÆÏÿµÍõøü_ŸÏÿÇIóûŸæşGh‰ÿc¾ûÁ•Stï	X2àQts#Nt~ä!n”“·@º°»ª~"èPañ ?ÀMƒoã°\B9»nçå¥ŞA VpŠP}BG¨	ùùŒUà]Ïºƒg|3¡=>qÅ®İPÛ5Q­f.—¦g£á;ÿ¾İ±ZìXŒdw4DšßÏñÎ¬È°Ê°)÷,</‚}Ğ³2Ed]ÒV™7şYÃ=§í0YóéĞsqŒ^çqOfõû"²Ÿ@‚ÈOÅ7¾=¤pdÒ*I­¹İ@ğ¥À¼ uwcw÷tûeûø`oçOÉ€,”ëĞõIŠRzŠ¬©Ô>¡Œâ‘Ì8xÇ:X_F‡ƒ‘zqsàm¢şÒ¨\.DXr)/‡)íBÂ¤À„v¨ £é†€t¥7ˆ¢æjxZ¶*£#O„,’Ğ´ãRµğÌ1?‰LÉVx¤l0)D»¨bû?&Ï¨
Ú%{p@½K»Ûí[W¦g© Ÿï½–àïË¼ß6^5TD5xß1³ÌXÊ*y¢¡4ûå90>—üzTV‚ DdMÈÉµâÔ=tJqÕøX°P@ğ°¦K<‚3yà¡a<ÎB®ÑVy‹Ï÷6ÆÌ¬oR'ùÓ¹3×RVïW!Ó¸ŞEÖ¶ÙÕÀ‚èRT\Dˆ8ÙAw_[aìzÎ;g—rBAüíÌK¿(ù^™/õĞ¬ŸÈ\d!w“SlLpÒÖ##5*Ë½{°İØ­«Ğ8Ùi6Ô°¼]Ù,á¹˜1KÈ°b1iu,¹1Id£s“
†Ü¾¤‹¾Ä@ÒˆNaxuMÏ›Rœó(ëpäQ‡ãæ…Zg¢¹"H0]Z‹Co¦èF–‡EX®ñ°pèÙ@[ÒåeIú‹_,•–>ö d•‚Ò +F8É7wÅË¯ú~`|§U„áVô½å“Ò›?”Şşªğaí†ĞT²ƒhÃµı]û¸µwŠˆXäK#ß+!§,®¸]KôákCb96´2ü]+..c;ú¶óºÒ»øAÁ!³íh‚ÂÎEĞ ‡…7§RP3?2ì<ìps‹Ùkµ|H%Ç¯]Fk<™¶ˆF4[Ï/wÉ‘Pkûøàè»SnÒGfT2şmñƒş‚h4NèêñƒŞõa²ˆŸ³¥/ÎOœ¥ÙàĞİú&Óƒf»Õ&NçÒdŒöøTØ© f;ŸÔ&(s	Æç¤Dß’óˆp!ªkjã…ÅxÇß‘</˜ÉÂ3k‹ğ ¸fOc‘¹‡ÇÇß¡Ï'ÑåÜ"£N÷¡ö]•pÂ‹ÇÖ{«3"4JÂ2$,xğòh»ÕÄsJñ“N*?s+t>¸âÜ(f™QşÁmÔ5œÒî{œd\øàøy°$x@¿ñ8â‘HÄ+$’Óğcjüx‘8£Óà(XuÔ]hÍŸX3£ãşµ´²Cu…ÅÇß¢yæ¹íùB[.j½²A\÷,„n2b¶ ­Vì[1Ûího7^µš§èÿ¹QlşÂ Q®äY³€%@è™#"¼eg”Ú·Z(Ë!IBŠí‹<ÏY…|A"ÔÉé
<Ü7àL×±ô-Z˜¡èÎ-[I‰hN•Õì‰%•KËı‹îF”LrS’Ä9ìÙtp\RçA`zŸr›fìÑpOtv®XË®ÌMc±£’³ëx{´œXW˜“#;¥º‚ 0ÕY’ßŞŠü†á¢V²pw50œ,B³SİƒëhåV»I†ÍkpÑtÏ× 5ûì=EŒU'L×I
€Í¬C„RG§ƒ˜©Õz>eÿ"!İÇhıl’­zlØ}×ÊX±Tp©UIØÏĞwœysâWh'A)R&UlŸR	Fİ‹ÆŠ„æçZU
i“ù¹hI8‘gBÔ—rq"Fw·¦¹,z»=­İ•ÎfMcD_vÛ@]4M?ĞGú÷q•E&NåiÜ–z~·H¦S·F=”d@ oVõ©Ïo¤Y*¯Æ”&«ƒq|¿`Qá>³lÀüèFZØ•´æ§ 3¦y1P|çpg€‚íèÛ	4mUV!VnÔ½×/#~®®‹Â{øh˜$Œ|ö!~DJ~ØºÂi‹j²Œ”s& ÒŸ1b!×Oli_<*Áña_â}ÄåÌëKêu‹%ø¢&ót›+™åñZ†>õÔËiÅ"İÔÒh¸ô5·°äÏh-¹Djªhµ•’`Œ‹ó½&¼ê}ñù‡N·nŞ9:•=ç¾S„œ„M°’ñ×¿ÖíCå{©©æF]ºÄG©‡ÂÃ×|Ñ·û@KBÑ‹œVBş–A¤1qPA×ŸUüTí5>€xÒ	EàÄ¡¢14ƒ”/²÷#İ¸˜ñV´œà_j	ûíÌBß"êË‹Qç¥ù˜³q@I˜Rq¤ÿSo›3Q†WÌ¾Ûl²Cä¤L©‡§fmëyEÖÓv{7‘½A×
R³“>QàH¹K ŠÉG­ÃxöYŒñC¸bQòh˜äÅ*üDf±ËeÚÁë±ÂÖŞ–ó~ÆLüöR*“œ‚á¸´#¢AbL"¥¬“ò˜–¤ÜN¿å'Ó¬Öî»¢(Pp]±'-%<İrAÁ´ 7ênÏQüéZÍÍÃlMŒ±øÁ¾	7”Ğë…È»«&![¹;ÀµB|ñÓNKî
vs<ØÛÂ¨Â•â†Ï¾(VÊø÷&ı\Ç¿}Üè$§/áò÷bÂ_Ğ™x7Evjø› ¤öôä¢¢ÀÄ§÷#ğĞ¸Œà¦bÃG~”ü¡ËÕ¡ª}I(4È…ñ3à¬mtê‹Ñ7.z‰ˆ„AUæI÷[Fò’Úôo¦—u5K‘32oaiGsË]Û×‘ÕÂS½ĞÕ*¦#4Nüğ`ü€ì°o¡¢FËõ¹)R(ó.T†7À‡ÇCÅ!qÆ©“ú­!‚I=’Ñ‹ŒÙâ¢@àÁ§/ß	L9q¹Pñã˜²xgxçE={Š%·oñ½ŸÇ9”ÔMn¥Ò¶Q˜´Åœì/¶T"Ñ¤p²5çŞú\Ç!a¥´Zúãbi¸$1×½®_ìœ_Qi9MI,~¨eK]¦uŠJ°¾oéï,kBVcû«„íG¢‘êne–½zK¤*¦æH×îÈãs-}w¿ yÎPúY³áY¤Ÿ4£ËÒt,Õ‰3T…Hé$¤uHŠ0¤ä9!OeíË¯Òóp‚eÌ»¹¶™‘—Fòƒü	y¿üJƒ{wÎ{?”Oãåq½Ã¥ƒR*¾£OlçcyÕ-}ê~^ÉßÓglè•ñM}ê~ö½ø«Ûhˆ—OÅ~+±ÂñÏ4ñ öÓ/aÑj,4m	MdÊ™tR4ÌÜ9‰í­}•PœÈ+aE?çV±V›åK±‚¥ÎÉIìUè§ÒiM¡ÀZH[µE½[òjÛ¦•FñºB\¸içÉz¹aüôiÎÉËüDèx²Ğ³ú)º,í\²ÈKVªïŸ›:K>³±¸´|Nne#°­ıW÷³À‚H–í§ ‚£{>du  ı}Ñ)™7Q!¢BúûX¡äm^H¾¿v²jJÉïcÙõ;(QvíıÊ$ogğ2áûXşä_¾eOŞâÙ•÷é%”ë'Z	ù¾¸Å–’å´¦Ôõ½[¼&…Åh%”÷cŠÈFÅ‹¤6*¾¿I+—‚"²¶8‡Ärø>%«ˆ×šÈÊß§ ¶™ß§eŞ›šŞkÙUn Cß4ú6ÒwâüH€'
/¢©üI´FƒÇğ`Àï‰[“6Ò È“Ş0ä†§	òxW‚ÖË£fzYõæ
}WªîEÅ/†Q÷½€M '”ÑÚ1Yë…ÛÓŠ©‡z
'½èÔ%f£(Ÿò‹Jtù4ÍP_ ºßø!DîÀ—vä°oG£:rXÀo;ü ‡,YÈYœØ™X©¢Å—™Bñ¤)*2å]aìí[“¼»;Ğÿ.åWîX Å¿l¬êËKyøïc¾`¬Í‹ö”è×Œ¹3a,/ ŒÅËJÀK'ÕÒR
”âlŸ`Ú(»'¡Â†—úkÿÄÉ§è¤?P£2ÔÕü Ğ\£9–
”Ñ'ã‡ÿ=˜&xşœ©Ú‚üªeÃ0Z;G¾I‡_ÕØàUôğ4JêªM0R^WsÑöºS+”¹ÑÕ´Z<“}!­CµZ{[^ø¥+C«¡Cw:„b…f„Ò¶;¸Î!Ìçú¢Şät÷ŠòY>,u@2z¯ğŒ7iíZXŒ ‹6¦µıíÛ˜!Ÿã²tz«l`™23€9]›v›Šf^´Ê!&.ÆÁùÔGOlÙ³(Ú¢RX™õQ'äı~ôZ9€\ %/š{]Ù•ÿ;Üyæ*gŠ2äE‰{÷ÃÛæ²<g‰ÅØ"ïRj~b*»[5MIìâ¢L%,¡à^É¢z•6Ñx”òÉú¸~Ëìs_í8Ú¼ãv_Ğ‹ºOâ!(…<-'ÀÙ¨àn¢naO¸ÁW‡ƒ²*Ê ·ĞQÀ¯ ;®ST²Pç®wez]1fã)Oâ‡(øİyG‘S‡´.”í‰Ù"ÆÇQÆ‡âğwJµÉ‹õƒšYŞÆ‰ …„ÊÉÀ3™ßGÇdGjö“õ|P€Ô*úZ"¶é’.$|Çì¢¨á&ä	À”
€Vä­¾"ıÓÈòÑi®f2j½YÔG¦©\*˜¹®‡[ç:Ö•&lfyÅ?^YOÛÇGÓÖk8„15p	ãñj%7Ê¿RPpL(PÕˆ3Š	…Öb…äÎ„bë±büpbB¡¨PÂbBÑÍì¢w3vH³t–7;SŒbæÏã ÈÓ…äË`ê¢35ĞÔ¦ê¡<K1Q”¶İ
¾!Z"”­Sò‹ú9múÑ}¾‡‡$u*’}“u6¯¢Â§•‹‹ãÇ«”ªŠ^Ğ.o%õ!kJ¹ıóùPOLEÑ5Dˆ~ÈİRsÖ$–PğG RíqcH¨­¹İPM±ªivCµHİ‚¿ã3ı<FŞU	úu6ä§—uiÃ²Amˆ®îBËønî‚j„]{¬jÅ3l–+f-.:Ó%^í
Aë„–GYqšÂk*)b˜%)ˆ–İzÙïíÌ`v~†Sì“ÏrïOB¼E¯úE]”îğn´¼áİ›–7…Ïl§–i1#>*=YSo¤‹ïüò5ÖÊş©é(V¡°•ñÈI’r_¦†¨7ó£{Âá}^	IŸFv>ô áb„WšJ÷À&kRñìá{ÜH¡Ï7¤ŒÎ^R—6¦7…¯¸tßFH¸&W­f^½Ğ¥É|Ê%¯ôË–ÕÌòÜ-Ã|²Ç©héFéô!{ÈísÁœ3q˜n`3³Ë0Ğb¨?÷˜™ÔB1N04}ÿ
Õ@DC‘«?)…„İ‚Š*‰Up:¼êÁû íFááë&ˆ3EùÄåÁÔÂ23¶Gz›@ß(7zhE´¢;‰©÷'‰nÛ‰ˆ9<êBÂd#3(‹Î{Ô»³P-sŸÚç¯š„½äƒÖ1Éÿ;úK®¬UË•êúV¹‚şŸ«Õõµ'lãA±égîÿ¹cy¨÷Ä¨NşCQÁíÇm}>ş“ºnça'ÿ“©ÇŸü¿on®ÃøW66+óñŒ„ãÔ‚İ`Ët¨èÍõõ¬ñ‡/Wcã¿V^¯Ìıÿ?FZ -eıêÓn–ÅP¨îÖ[Îå¿ü—ÿE›º¦×µ–éö`ØÇÃ32»OÉc]$†qo­âªºU&?/´—FæÊü'Cü~ÇZ¾Á}ôû~ÑÓœ(wêX‡ ÙGs‘ëĞı96+9ØÑnüUaõc¢å;°{ øûv0â®WÙ}G?á…<˜?À#:jqrw)“&ir?ÜÂ“z,‘ì„¨]Ğ[Œxi""t¾Ø·Şø3}C@}—|û86ˆ©çH£¥ucSv£ÖÏtâÛhï­2ØÔ¯R¦#0‚=p=¹½êÙ:«·#7ç¸ÓCÕì˜iË`òÑµ”F¹ÜŠ$š,pÿrÜ6‡ie%td¾²"ºe•ûY×<hÏóDìlätÈfClnrtmŞıÀu°¨äíí3Û&{Ÿ\Ó§Ô‚‘ìİ7=$ã+<*‡W#Š§"§«¸èyŞ@wî˜ùÊ³ƒÀr° úeçÖc\Mˆù¨ìÚÎè={µ÷/ÿù Vˆc“¼ê#RiCGS¹#ÓY4ìĞÆ¬|Üè­m:ì·–ï_—ÚgÕ/\Í›}ßÅ8©4<Î5÷×ÇÑQã„ÂÆpã£al¸"gğ¦ÏG|·ˆ
1ŸÇuĞ\ËÓÇ•˜gyVƒ½Æ	=‘ö•*Š sË,è>˜ëCè,ª‡ úÿø€„ëàj*±7¸ët}ë-z„¯”üÌÕn)Y+ör¨ X©+k§•õZõËÚÆ—tıè£j *Æ=ûÇÇ¢Ë¯#)•G3Ú”açÇ¦Øë«iˆ¼)ö.ßÂßgìÅÒõé[6ƒvXBS7>Ehƒğ*ó¢÷Ïé.ïÊOß­hÅÈÖ0‘x¼ùe
 0@‡£Va¸Ëlp–ÃXŞ™Swàv­IĞb}ªBS­CkƒíáGLÇô.F4Ÿx¨’1UMJŠ’sÓŒFgnÚâÊ‘‹5„±˜Òeye,ôZZ0&UÑåU o´´*(rBzQgDEFßX<õ=ú0ò«•É®eõİó #È@¦ˆmqaRGdÍ,Æ­şb¡"t»b½ãõ É?mÚŠÈ¨X®‚é£¡l˜Xw
k`ê&Oì©MæŸÆ×9öã®{AHQğí8ãD×¦°zär;êše½7If¡H:<ÊÊÊp´òQ>Ç)¿¨ŒÅ€rÅ³•1cy"Ák!æ(Ù¢¾áÂ#”î¦—^Á%m…-K9…{Šø\º}à9|CxS_œ3nşÆ½ºÂoèn„‡*I|@‚0Ø–ÙKd¥±è,È.°\|¿ªU×î¼ß¾¢;.Î¼ğK*€
Ûw¯ğ)Ô“÷…ºÒA¤İZaõD(›ô²/ã±mnWVe#ËftTC”4ãŠ†,)O58Ì˜æª‘mB”e¼štZâ±dŸÿÃ~¢©ÙD›A-ü;¹-6 ¸‹OÏ¿Í=y†#9Ï‘áF*È©òT£&àE¶ÍÔôÁ|‹ìÈû¦Î®¹Æ¾MUã†%½ÄRj¡5iOÛùşÀv’qŸšÁ!'ÂTrDp\å~ª¤¾áÇ6ÊkOuä4•w`9M–Ã(?ôWòP¾–Çò­(ûöY)ƒRÊ,?|ôSä¥¼ï å]5'Õ=¢›íÙ½ğÜ ãúu³^Fq Ø3Cf†ã‚X}rÆxş0ö§,µø–š¼ nÀîX±,W}ÿ”B¤|G\Óç;-ozX$-˜İ2RZB¶˜PXáÓË1‚Ë %Ü9Àb221œ)9È›ƒ!F3to,Ã2ğÏS±–Ö~¯ô§®\´A%ˆ‹Q~`™yXáº„ÓHßãBQS4Ú,CÄùöò¿Å¼ù¤‹_%ŸYxiŒ­„›
î*ƒÚWTéã¾!)rlÊ˜ÂxfÊÀ3
MÇñ"X™é»®ÏÊñ‹iğª7ÂX8a/„Ñ}8·*äu[ír÷Å9é,, ›EÄ¾nxX¤IËå]‡^EV¤"%YÔ_¹Ş;¾™B«&Uúäb©zC=âÈ‘Ü,">\€UEdŠ©ˆ-õ;t;Ğ€²ßY~Ş–/(¯–Ü×Yr_×·ß¥êW)`C¤JÔvbŞäÂ>|F½YêfĞXòYÇáE“U~‘u¿*,l#×‰J¹¤n°ƒ0f†ô0’ñÌ¸ß%í'y>”1M”:}u Ä£;Kî¼Ò{GCóVåölU`ø8*W ÖIFØ8aBê¡¯>1"Éeb‡‘Üœ2<F.÷‘G‰¥¬iqÖ‚yñdL±˜`ão0£‘"7äZR>
Åµ/MØ…yÜ\±é/P³Ëã­úÂ÷H#|‡h-ŠP%p´µ³Éñ5E8+jğUkyÚAÇTL&‰î]µ1î+óÁDí†œÀä…_¯2
®&~ãl:áÅ¢Ã’œBÑĞ
-Ù¡Ø3ô~¤ğ˜8|Š­šÔ¡#…»Â‹*¦~~‚zÏ†‡ 6Ø®+å+dˆ Æ€’öC†‚¾j6GŸšUø¬âtç&iHë-k]Z¨…¤µƒØÉ™…W°Aæ7Ë—{bëŒÍä™iAÔÂxZZÁ)`½d§Åéd§et“èÄÔŞJ´-a¤—6jF´å¹î e0cgoáÜÁ¹Âåà$B>NAó#g…MeÏ‡İŠKbX/—Ò".¨DHVt)ã|à{b(<8qƒí¹<Èå€²C“†´=»Æã)¶,÷­÷£W]äU;à"–¬:]‰³'ºº=¢Áõø”`æ™Ó™|*«gc²Ş.ÏU«zÑU¶Øéºga”|Œk R[¢¥T"Î±ÔËòªÓ4=ŒS2ÕÇûT­êƒö2Êxä±0T­ÚFˆ^B™”Õ3•ÕñHEÉNåúIÂ„&º­†W/ãRZuë’˜L¡EÍ£Uœ¤M¼SkwFxìËƒÅ…•¦
‚buD²PÈ‰3RÜ	b+‡:ìY2Æ'Šëë=«=Æ¶TéŸ”I"î/NÁÃ¾Ã®B²á` Åh8º¥ğm¢L[œ¶+ÇZÓ[-Y(4±PKÃó*UKè)'zÆôVëC„ U*İ
A¥H/* xæ•âµR=cz¥Z,é‰=›ÎQU@n«‚<tæ˜Ö¾;U*H!­Ì®&¯°i[¬İæÎs"&<ÄÙhˆÜtwôÜ4è©ÙU–Ûrš`½€òÀ+UNÅ†Ûu‚ÒùàªR5ªFÅX3Ê8œ½tøQc¤Ú¹9J•
¨k…4¯XéíCè–¾ï¾«_åÓÊúz¬Ìo1Ä-1)yÊòMuOÍµÏ¨¡¶Ê¡S“˜ephm©-]1­ı„q¡ßÓhaÜÒ%) #ß²Íƒ½ÆÎ~Jm¸eI´ünd§R¬”S$)c¥\õ‰Ÿ&KèI)Şîqè)ğSH ¤á)™6Eï“4 ¢t.F8t”Ç$ºŠ›f™Ih²Óã•§.‹¼òşäÊ“+¢í®;]Í´	x	ü¡ä|fù¶Ô¸…F.2N”æÏÜK‹dít9›c0¹ùv2pŠ#;ù½ÑQÔU›×c ê v•pœï	Ìw°9æ1úø½^H^Jé—Cí:“:Aµv	Iqy…‰îÿ$.‰úSüå‰úµš¸kæ¨BC¨…€âŞôÒ Eš™Éàb¾öÒÀÅõ9“Æ<ò¥5Fã€‰QLë9‘W‘Ş#%²ˆy%<ÅáLÑv1¸?Sº~†¸Æèo ×Öá¾¿uT¼¬jô€ëHDè¬—ŞF«©p0(T%*ïN_¤—åÖ¼ÅÕÈØŸ¤à2;½d¨M²\EeâØüX¦oÃæ‘ë®hşi†CZ{SDÖju<,•Û â/}KÿNz+€—Q%Ö¤né¬)0Í´.¢Êğ)Ñºö{}<=r$c1;xEB?šº@­)ò{çÌ`üÛt0…M¶;
Àè¡'0~›´J†
ÒïÆ ı.:e1ñ¼Ò¼°ŠøZ7GÓƒ¸î&BÓ?Êè?B°¾ğçÉÍÿRc+Fî‰â¥ífBÄo[Ê—AÃC7[…«è`Cú&L©àñù•êk4è0S8GÛSQPÆÔŞçRé*U–)Nm'M™««­Åé7îWTÕ2—V®ÛDÉ
ğuÖ¼T¤Â¶5Á"ô*ÕİBŒáµƒ0TE&ğQ°û°çÍË6n/hèÙï`™&D*tÔ6ºÀé‚;ÔøöşáFŞÒ¿äæ‘à¬R^R‘¹h–@G¾yÿÎ–ğä*dh,óÎòŞ.÷‚`è×J%DÔ¸ LĞÏƒñCKK q‚"•òK…Z.·ÂŞ´Ş“¡ìæGP ®Õóú¶/-¨J<k‹û£³ÍˆÑÛ[”/A¡uÜ®İÁã]1LË£ğW]6rÈ ª1„%Ê’™W™4¬eƒ}ç€¥\3÷ŒMĞáµbQ„™ûÑì®®®“ ®wQÕù¥İíÖ~»U OA6ÿÔ7°>mB#‡®cÊûŸÕ­µ­re«ÊïnÎï>FÂñ§Ã/yˆù uŒ¿ÿ	¿7Ãû¿åµ5ÿõÊÚÖüşç£¤¿ø›¿|òçOì™vĞf¿—Ò¾{òWğ§
şğùO²q||$~b‰ÿ	ş:–åÏ¢÷Ë‡W@-´£Î½ê.¶1£ù¬?à¿­¿ÿ¿w¯vÎSjŠÙ³>HæÿÖF¹›ÿk[Õùü”´ğ<â+½#ÃÌéöS&€·¸Ó­±Å ^Uo¼XeÏF>Èü°Yo¢cmwHr÷/Y[ÈÖËÏší”i›ÖŞWÅ°|>HŠÕ¯VÙ—•*{Ñ7ƒàÌ]\¬²6à?X^? ´QµjğTS‡àScÀL|jÖ9®‘LÍ–aG]@«_xgp9û7è ”½¡t«kaéÅ]`£ÛÜØèÙ5€&Ú…)ğÏrd]Ú(l'²È<›æu_7.}.L¡¥ı+íºè%ËT‡Grˆ’TA„[xì47€=¨@´SÂ¯“ÂF “©áV
µ"Âî>Q#ÏP1ÀhLf=ÆĞ[ì[¯f]×à±ò•QŞ2ªåÊ&4xŞ=A3Á¾ô`0sÈY:DULÏï[	§Îµ˜ïù¼jÕ_aøÁ™#.ıƒµ+õ¥“ÑoNzµ“«{sÏõ–-Éœn¯®{.Œ¾˜©/•guÅ¶<zİ×<'NS“}–ê¢SÉĞ‰gˆ‡+UòöRó*úÙÀğ\+ÊéE(Ç02ãŸJt(!3€L :g“¯|=ŠÚ¾¦NL:ÕLªyÑİõ´ÂGâÅtMVN¨›;Gáğ†GÖ7â<ÚO8<U ´~Ozû â08éÒzA„¼AÎĞú­”³B_?¦õe8iï2G›Lú¤å¬øıõõ%úY$k†³ô ,°Ão„%ÏÔXC9R<ê®Ré0Šè¼ø¢M&¢Ù*.›h·»ÆM§àBÙ`©wu,¸ÀR˜©'3)S;úÚ§¯y•#ä•¯h2•Ìxi¹p:%sÁ[-Î®d.x¹Âlv/­Q1¬í~f¦pÎ(¹;ãsó	å¶¢uHôÙ<ËìöxV;5«–Iéº…½v1¬/…¾…Ã—n¿UËoğE*yå+èª]ôåº»Û8nÕ·Yf¬ÍÉMN˜É¨/á‡.3V`²tÜ¾ëÕÍQà†ÒÁœ…ß= xá+Ÿ¿Jƒæ÷Evà‹+t°‚‡4«–Ã<µ„L$ì˜ÀÚ—;Pl£<Jü°+*nİ®8k)Å=kx; ÊASÅ¿ŒèL‚¸´İúÒ¥p¥˜gaWˆ$FC¥Úwõ%íàªX”§VŒø>ÁKâèê!o±x°4ú€rx@·¹Ïò§YíX//¾Kó›Ããa4ø´ÈÀGÀa`z×­®32<øşD}ƒ§çˆEÊ9y±H¢ÌË¦0´/t€’Ğä 9ˆÒ˜Åeù³0¾9K?öãUÿ«ÜÍ²)õ¿k•µµê:ùÿÛØ˜ë)}æú_GèÿõŸ·îÕÎyJM‘ş÷¡fÿÄù_İÚJÌø5Ÿÿ‘æúßO«ÿUgİOS¬ZÑÇUÁª¹ï\|w~ìêà©Ô‹ŸN}†‘ŒÈéÌÇfŞ÷ÛÔ#~XJ1hE³5Éÿ#ÿE·ÆL’ÿ×+[òü·º¾µ…ñ¶¶æş¿%qÿßŠ› _dÅy…k~¨Šäkâf(¾\S^¶Ã·ëâmƒ6âòí†x{¤lŞå·Møé‚ë!ZâbîUôß5Û­ãWtÚ{¹…ÛÎ%–ã6ôµÊÚ—_Õ*›k›µuHµ/¿‚G€ùcßÍß>¥»9›m“æ9ÿc}ccs>ÿ#¡Óº‡®£|ëø/•õõ¹ıçc$ôWøĞuÜeü7¶æãÿ)òØ÷puL9ş ÿ­m•×6)şKy>ÿ%Å¼„>H·Ÿÿk[•ê|ü#éîZ¦éÇ£ºµFã¿±1Ÿÿ’îx ÛÏÿõÊ|ıœ”á±w¦u”Çïÿ*e®ÿYƒmßæFÇÄÿõùşï1ÒÓı’çØM8tOètÙyxãYº\ş'¯Æàı+#z)<!¿ô¹Ad‡"Uu<EQÃ¨£!m¸ğÌŸËñĞåøwm‘Üµ¡©ŸxAÚ^%ĞyîŞş¤ÃÂcIÇƒ3§x€Ğ¾…ïèÛyo9ÁoôøÂ??ı×Ï=¥Ç˜m·_ÿa˜ßÿ}”¤Êhµı	å?¾ÿß*£üW]ß˜ÿc¤ÄøóNé€Å^Ï¢	òßÚÚú…ş”ñşÿV¹:?ÿ{”4«Ãê¸QÎsî™QÀVnŞÛemÆÿ”ö8qCœÅÏÖ
G+·ÀÁ€0F¥j”×c†7qîk—¼bñ»5„,k’wË˜QLªY‹p"ÌušÍ]V1ÊìWìÅá.:W™eßî¹]r$pñ-‹]Øèâ†7õ¸5Lx ;ø9ŞØá÷Ë/†hŠ”r|Ğ<0¢ÖÍSîôˆ¹¾"x§š&å¸ÑS²§T‡R†Èk\XÁò’ğMºßØk-­²<…<:ååò	`:QÏ€›@1´„óÒÒ~}Á,
9²i§›/LB´`9•ß»AËuº{í|Aöı¾,?®p»½«”¯Få)–FVsxÙ—íÖ¼²Î@º´;ùq˜ñaÙ¼À²Ñn¿>8jÂ&7ô¡%NßÜ#%¦{ó…ÿv)Ö_Ç²‡¾êÙq ¢ì‘Y‹ez7#òñÜ¢;£/£şIıå}]fäÆƒÜÑíº×»m9ÿùb	üÍ2ooã ìj¥Vs,‘ä8E}Â‹Eı1®RŠJZ¿Œ+ˆ=µ¯L®¨&•Šz­è§Ö{à:ĞKÇŸz‰ı¬Sfü¸Ö1AşƒU0±ÿÛšË“æFßmôı£µòŞ•"+0ÏA,ŞaÌX[ØC?¶ÅuÅ¨”Õâ:5Œ)²W5‚)oŸQ6œQÄ;ÅŒh½2z07èa`S8d÷=ñ¬oĞƒoÿ ?Ëåw¹›¹â÷gšÒÂ±ÎºIúŸõÄú¿¾¹9¿ÿù(i¾şÏ×ÿioyƒøŞ=ã÷»æë½‚Â¬á]YÖ»ş5;¡GlCÇ=§P ŞÈ!GÎÊ…¸ÙVœø+¶ÿU ûDX·tñ#’öüåî.+R°ˆß@îî™itzìéSV
C5;^Å«>ıe%÷ İ×51dít<òÁm~ºN,¯VW×V×W7V7ïÔ;ûÛG­½ÖşqãséUazñx=Y­RO®LÛBlÆş»M‡}êuøS%İşóªïŸ’îÚğùAÍLê˜$ÿmÀƒ°ÿ\çş¿·Èşo.ÿ=|šÙ„Åë{·<ü„ÒÖrLQ‘Î@@IĞ?æS¤5#Mf[ÕÅ5A“ØT‰L‚(oĞÃ€1"’É<:™S¥0ùå%È4Šâ»ò0½ô¡§õÚükÀqĞ	úÌr(îµ4ÖPEz“å´[ùQhuÉ5"LQE—	€1=¢-ºçÙ&×]Ò[¦“Œ‚Á]ŠÂAìÂsaGÛ>J¹N×Î¬s<RÄÍ,K‘[ĞrÓmVX·¢8©5í»?êº¬3LÒÚˆ—åD3Å¿¥X-Ş»Ÿ—L© }0t²‹u•eéZf' ê
¦¯¥+ŠOª¦ö˜*TŒà32ûc“ç İáí!»)#A€gÈbçÒ@ôDa0?Ë_á>bKl# Ùb'áYÿ…îI—ØqèÙ]2øÄ09îÚ0àI0C¼so¼Í)ñ…êx HŒ@^ÙÎ½6À¯;Vpåzï§+È50j}ü%Ë½|ùmîøzhÕ}&¸•Ã3¶:³r/pÖ]›O¡Ük(“,œÅõ¸X†ÓÍŠ¿‡ï~x–Šƒñ\ë½Õ!š»}Ù‘İkëlÑr•s‡w€uFğÜ¡
ğrº¦×=ÃQPªDı*ô“`!o©wqÏ]Œú]ÄjDw~ê5ı6I—ÿÄà?œaä?¼îŞÿ©–Ëtş·6¿ÿı(éMkÿÅÎ~ëmîÈò‡.FP"õ¼T	„ÿ—{ó¢µß:ÚÙ~›k·¶_íwúò°Ù8nµO_í4N÷¾ãş`Û/Ñ\¤~nöıÙŞ"™§‡Húü–‰üo]Ì°IóŞFóü¿mn­Íçÿc$Û¹´\¿OaÌk'ÑƒÈÃÅáôB“>5öótß›ÿ£îiºuf* ‰úŸ­Pÿ³±÷ÿ·6×æö?’æúUÿ“FÿsĞ#¨€¢xÑI¥Ïj,°Aı“F«J'¼‡PMQÓ=ô@SA¿£*(öyÂOF¤úî{XEbP?8lí7Û§¿m¼jĞU†zfÍ÷æ¥Yú¾û®b|i”O+ëë¥¼®ü©”Â#D’A:]ß’Î=¹ª§ØE§ÿ4²IUÕ3¡¤;Œ<²ğö-Šz'm	$]3ôcUÅüÿp÷ˆ§HÚ¾˜Ií¿×Öbö_[å¹ÿïGIs{­8Úq{-m>üh·š€0#õÔ-ÍIxsp‚àZsúúsµèÊu¡»:t_pt¸
®w‘ëvj,|™sÏğL¡Ó‡ ïÂtìÈ$^ÿ+	‡Øqê´vú«i°;ƒNÕÔéo»N ¢¾å…-êLÈüó­ jÖ4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4Oó4OwLÿÂ]Å ¸ 