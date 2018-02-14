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
‹  „Z í}]sI’˜îìóÅáéì‡sÄÅÅ¹ä,	.ñIRaÚ…HÃ]~AI;+jyM IôèÆu7Hq(nøÁ~´_ıæğ/ğƒÊı‚¿ß‹€3³ªº«ú Iš®Ièîª¬¬ª¬¬¬¬¬ÌSË.?yàT©T676ıû”ÿ[©­óEbÕµÚzµR][Zc•juccí	ÛxhÄ0=ßpÏ1'æƒlgg¾‹vÿşHÒ)Œ¿3î@óü±WòúPÇäñ¯­oÀ˜ÃøWkkk•õÿõµêæVy \bég>ş¿(#	œ^?·ÀŠóK mq»Wg‹s{äZFÏòXóÕ*{1ö,Ûô<Ö2/Ì3š¶Ï~É:ãÑÈq}¶ü¢Õ)@™a›®iy¾kxÉjÏVÙ—Õ{50|ÿÔŸŸ¯²Î¥åoºÃîÍé=ch–xª3mÂÁÇæØï;®øØñÍ3ÃfûfßXlÙ1½óè]É¡w¿ñE”ºÎJ·{–”^Ü1<«oØçfïÅïş–á‡u«ğÏrh^XåØ±,òÏv0vGgrH/€fX§ëZ#Ÿù;7áŸ¾É,šfwMÆ[È¹¦?¶Y×é™Øoz›£>Œ£ÇaÀ¯¡aÙƒ+6öÌ;s\fÚ–ëØ4¨08}gì³£7­"TŸï3V¨õ}äÕËåsÈ9>ÅŞ)óóÅ‰›sVèöP•ã^Õá±R-U•j•êSÆpÆ¶mË·Œ»0]ìFÈS­•ªUÌ³)ó4{ßÂ>b4áfvlæœ!¥@CK09‹l*u†Ö÷†ˆİzÎüH“mÿuëäpÿè¤µ×X¼VêÅ<S¯ä¸çùB m÷°÷Ç#GàZ0GÆŸ½1cÓ»GƒroÚ‡íı½Œf®µß<8hïµù£Ã×í<›1- í§“œsvfÁc42± ìûv#ÿ²¹Ó¹< S˜‚lˆ³©³u¸}pt²×Üm7—‘Âmà3l±RÈíœ´¶Û[Gû‡ß6òe8ÊÓË—Û;Pûâµ–á¦¬/-.æs£æáÑÉ7íf«}ØÈÓ²'††mñZ©ı†-¿áïE÷İhÎ²Å•|n·¹½ÓlµÛNhú7kÀ„,uû¹öááşa£’S)âş#ÉÁ½Û]$ªû7ßÙw&ğb¯=ãÜ\.°ë(omYŞh`\ñs®É) B"jzÕrv½s–ßŞ{¹Ïê¼âÕè ¿+ö/\V´Ø×8»·÷€&ö¶ÚÏY±Å¾1¢×Úƒßßñß0Û/·÷ˆÿ9{ŸT	cÅ~±SålÙÇÅa‹;<¥¿H*0SRŠ»IÅ»}³û–×¬.ñ¥ J»Ã$É÷É·Îºv£e¹f	¶kØĞ7\b×½€7l$^/I)Lğ!¾$'•ÛqÎ‰=Á½³ÿ
¹ÃÏg±wğ²zÃŠç>«°÷_áúnçd3·¦a7íŞ?Œ-Ÿç[¼®İĞgs k­ÌáxÉå+ŒŞŸY¹›ÜÜ×ºÄ©µË	‹ó(ß’À2=ÔT§^_.ä®©Û{¯`‘¬~Q_¹I"BJ ëL’­{“Á>g§&üÓã}Û~]N n@ìJ† Ä23˜mL¶“˜ï*ƒÅ-“<<°|±£íİö	ĞÑî,,=KXşW_|[übXü¢wòÅ7õ/vë_tò…¯¾RŠ¦µ§¦ÕJß¡Şıßa­Z½ù¼ša…×2”’,dzF7œyZĞ‚oò¬Á„2«&å¥:º}ó‡8à$Ê³O¾i²¢¡ÌÇ ¤6¯&ƒ	²Á”’?½¾uæO—}œ÷„5VûÀ—pí9Z·mYˆVäåÔÖ%¶p28-«ÒÒxk{mÆyÓ‡íùó¤6ıÀz?ÉÙ;ï!øsÀ"Õ…"eİ”GÀ{cühù M[ø„'Ñ{‚%W‘Ù+…`ÍEî
+mLzVÙUUÉ²·¡™l¤]boaK|ÎŒ¡3¶I7Üó1n‘½ëÀäÓ²†ì½ë¸(w0½’ZEmÖ*$`¶ŒK{aVøSá«R	‰@b éÛOƒêárF[È£æ‹UÁÃask§H7'/šHÇAGO­•ŠQ=é`í¥qaX”µöT«Ó o9ãA øÎ¸Ûç;>l—Öí· 3pŒ;^¼şfÈ£\’HªàÖ¦¶·ãÀjßæ›ó3h˜ÙSË¯O-ßv]è!D§GR„^|jkxq]wlÛ(¿P×[W»¸§ˆè‰P×¦Aİµ<$«¸”­Rô,´¡hì7¨j*°m“³Äo =S´Ú„¶7°QS$˜±mÌØŸ0Ñ•>ÄiiŠV`GÛ#µßQÅ‘2?Ë‘âex*C~*"·lø9ä›,ÿgÏ
‘ÊoQIviØ¶Á<ßûÆ`àhÓô×SÙÎkûƒí\Ú¼é)ò^3KEÉMŒùë8šCçÄjj>çƒ¢¡pâ5µçåyQ¶Çƒºx ã#<sB=¶ÿr>®šÈûëû §€s‘r†”‹+÷*'E™‹.ºØÂ{ü³E9]¬çKI¹â"¶­¬Uƒ}å™ÅX.À*Ğ§']öé|ù+ö"ŸUµZ«¨ëÚÁNÁé¤(²s%¶¸|†Ü&\zŠ¤w”½…è¬c œ½#)ösbÛ²*ôà§œtŠ.OWà ğÌ¿|¯S¡0¨Q%—€~sáŸPşa¿ü%Ó%Ë+:­ù-i.½_ªj…ÊŞ´K‚‰s¼ã8õÏ…d9¸]Ãº—[¡~ß5F,¯5l½’Ç½t.'¸ôº¢;NÀ;@/è=Q»™¬;©Ê&uzp˜’ıÂe/œoç¦ïŒ€lõò#×Áé‡šXØÃ#ÃbğQïÄ÷¢4ë_XõVı»z»î¢´l?¸ oTAè’kæ*
Ó½(Däaå›U`»W*!#™î@×¼ÒÖªæãz´”ßÉªj,%¯[`‡íƒí­æ*ñcXµ:U&Cùµll-®¨í…n¡·yFŒÇEº 2µÅÀ¢4ª®»¹’Æl`Íìƒ²8­ç\"ÏuĞ‚K°ç,˜É0«YÍa&®g_ü5ÔÕ'¡‚™¸ÂBì:CÁz™^ù“v@Zßm°X`j”ä0Éß® fÊAOYx'°Ÿ›Iü'X$.Mè®Ì¥¾\@²Øüg½˜OÔöŞä¨WS_€Åëƒ·-ÑŞM¿Kd<ÿ¤Uh}->8bŒ1c[
æÀe#Ò_”Às"g±Èm‹g®e=]ÁÛ)|ú}à:#Óõ-ÓCLáï£°!­=@Ÿ¿VÛÄ
}$À&õs¨f¢plGıöT¾^Õ²1Ä±m@‚ø8³Ñƒ?°äü<ığ<»h±%¯üÇÅr±¼¤Ò!”úÎÅé…Ñı yÙv‹«¤‡ãoğå}× r…=‚o~ôQŒ^,_ï}å•í2+u“Ø9tıDÀ¹ê
ÀÄ«%BO|Ò&?¶X‡+Ó½€]^G“åsØW 6]¶Ë"ÍVwA2eì`[¢ÕWzé<¬·Ä w%è†²¾Ø¨~â±ne,ÜHí´šôW'XHõál%Üâµ%öÍ·¿;ÙÇ³eãò[zÑ~µ½w}Øiäíâ1ì^ÒÏüWÛ¯ööÛ[°84ª_ñMcÏ`ªìO¬üÇf¯çÂ”‘¯.ÖğÕñ×KXËÒñó2»†F-/®ñ×mŞx_p*_±<¸¦-	½ÓGœWmÖâ¼>³`t6ª1Y~úÅ‡©J½$Åy}Vü4©ÕÈN>ÏËFgn£CB ş¥Ì"¨&MÎ—aÆ(j/aDpöë:Ù×)„–Xvê:Eú²Åƒ}à›­İí=uéI]ÅŒŞĞ²gXÆâkWâX¥®aZ“Ò†5Qm}‡Q]¯éŸ]ÎC›Gb*D R¦Î‡zş+A¸7¬¬ÙİHZßd¿øĞú*‚8$­oÔ‰ıv^›|t½QÓHÛ§MûÑyì‹ŸÛâSOÒş—›p}ûßµõ
ÙÿÂ¯ÍZ¥Bö¿•jfÿû)³ÿıLö¿Á„û©Øÿ
#PIy<£.ÑŞOİô÷Ëüÿ@¦¿ÕµhAËö]§7Ñönzy#³k]…vØĞ	ó>%Ÿ¯ùğOÛx®–À·6~TŞŸ‘	ï#Úë&X#)ÜÃ„7f*ÚyÎŠCöµ2Âğjv“İûØëÎn¬Çy8›zRâ¥”5/(½kX&väÉÅ3ÙGµ‘e™lf#Ë2ÙÌF6³‘,òña'Xå}ºğe²Sàg¶ª·´U“çç°*Ììú~bv}µ½÷¦1ÕŠ/İ ×@ ¶Ì´ïT;gã> x{>¾û­²3ÑÖ­z›ÌôÃF¯“bV7„ŒŠhqYÊy2ï'TİzåãÕò1+ŸÌ¾o.ö{?y/Áö"c›Àª“(º”@gúÆi¢^$R0¢„QVöÑ–à`Z€Flu]w³†~¶z“!Û£;
6|u•¾'š/ñŠ2Rwœìlwğğš[]°¥?.,…W>uÇ>`^…Å¡^ˆ¯E¢Ş6÷ĞnD—„yêê¼ã„¶§Ày	²Ç©Dé;X1m5š7å¼6–ÛÂZ4lH¸—’¶Hi2Vl5cßkßğ$F¢wm^pˆE‹Ú¾•VËÇËğwá±(­,–«å¥BØ4uôxÜDZ;Ûàı¬ğÒ¼ ë±gN"kQ‚ÌàrqüC™C´AwÙÒêƒÿ
‚í»ü&ˆm^;·ìÈ %íÎèõÁ=¶`½İ|ÅôMIÈò¦N0çbĞòü
‚3bšÒé§qXÏ!±xpÛN)œbÁönQzrĞÅ\yR¶‰Ë#sÍ3ö‰™rºåù«OôÊè‡ã—<ñJÙÿ•`e–nËy¡bW©· oCYt†%`¯ÛÆ£Uæ9c·kª2[)$Q…_%Jwò³.å…Hy/6õzÁš®¹à%+¤QËïÉ(©µ}¨ë%4´Ò[ŒšN¹•)¿|ËÇ ,h¹5ö"^x¾‹BÒÎ2N³¢Ì-ÆÇÂ	è:Ï¹i¯uµ†D2÷Ò»wõÓa¨¿¿Tˆq$,œ)zµ7*Ì‚®²»Á_¸0²ıÚfioØk\–Y*çWóåˆòÒy˜£O]ËÆ§í\€Gç;S$÷“Åk97'j7\ WA§¯G§z
wiN€Ûn…­èimíïî6QÖ¢í½›2‡Xô`2‹}Çó©t#Ÿf²˜›ÉÀ;	M´ÍRûó!*PdZdSzó¤e\	ùÒ¯¾/Á~	 ÍÚ¿°kéÁØg4õÓÛûEg¦˜%[8¥ Vn×~.hƒ?ˆŠ4OHjóÚ³PÏğC!S\Êmîò±:¹} ŞŸ† ä#+z¤UÙ?¬·ñ,õîi	'Ü‚Äy è$Ñ“ËËôãWÕ‚ÎÕçéÃ>{¿xã.îìÎ`›}Œmy}³U¿‡¯iÛï±bõœK{ÄOÙüKfİ)ì(MoÖš½R>P–(VÓ‹iä¢“ˆ‡wÌ"’öÆ&YúĞ˜ó†ùø¾¸^©¨ÛÿØàêÂT(¢×Œ)uA.ì‘ˆ%¦ªB˜Ï†ÿfùØIÚ"GŸÅşscmc-°ÿ¬®m¢ıgm}#³ÿ|Œ”Ù~&ûÏ`ÂıTì?yƒ~¾öŸOKğÿûÏg¥Ê¦–g×øO	©¯=ìE!ëÊS„®cŸ‘.K_ıè}fPšíÇaPZ)U´ŞeÕ¬ôèÛlÑë™Ä%ÇìgMGW#3÷»vû ±~8ØŞxx
š÷Ö4?Ğdı`š£ğšš6òÅ¢ü=üÊX„½ç™íÙ‚Ög_#©şômiƒ†I™a'*Z«lïm¶wÛ{GÍÌ&÷Tûƒ²ÉÍüÖf6¹TGf“›Ùäf6¹Å’MîL&¹™Qnf”{7£\!ÛÅr3cÚ	à2cÚÌ˜öGeL;o?™?@CZ¿nÕ‡õöC˜Ñú° 5U¢1êcÙÎÓ­ef5Ï˜YfV£?b«Qq<7£Õ(÷÷/ù¨8—K?²9¾ì«
>]`±.pu6¨W•OË$ıëõ"Áê1Ç‡màˆ\šæf“*>·×~{ò¶İşİŞ¾¢sy/äöwZáØ„oŠ‹×xpS(PñÍ­ß½>8é´òx¥'P)bZ)ön%¨ šéa“
‡($Ö‡¨k35TGÂğÄ‹°â›éÀğhVÅ±{.NVdC‚¬7)³f÷µãÔ7°–È	àbÉ8ŞÌÎ::
é+]t[eAId”£Ú:…[³*\+ÄŸŞÆ¦GØ/¢¢$[VôxòäM˜˜Jftƒ{˜Ú0ËÈ.^ë¸(…bŸf4UMEYÒØ‰í:ºŞrì3ë<Æ0Ô”ñ†aaÅƒï»g³ôQYµÃå0Kşù÷|›·µ¿÷’=Okõ”¦I'ùò Ü»EÛ¢EçÑ8ŒiBM;Ö„j(4­lt¹Käàİ…*ãê5ä£pú™Kõi¼Íd¢ïFV/­Ÿ“zYX‹ŞŠXÏnmœniü"qRßÂ¨x&ƒbQËŠ§Çtşé¤—Øäì…#âvsì;*§k@	ZÒÅ0-yÌôĞ^F¡¬AË|‚¥x
s‹,şÓìÇš(Bá ªô1K]R¬Ód’¸¹;dE7yfF N?™IoÆ£6áÌƒ¬¿l—âRÒ…ÔƒãgN¦Ş½ÌÔûés›Úş ÿ–N5ëƒÔ1Ùş»RY¯<Eûïõj¥ºù´ú”UªkO×Ö3ûïGIñ7ùäÏŸ<Ù5ºl¿Ã~/Y¾{òWğ§şşÀóŸı»Ù@6ù/*ñÿàÏˆdù7âı_?yò· ‡—ŒÑh`–†ç£0îå:Æ¿Å¿<ù{Ì74º.®€&nñÜMÿ!ÏŠ¼Áóş]$/Ú0ŸÌm»g~|òä?ÿã0÷ÿ¯ÿíßã¿ÕG!´fÒ"
=P“çÿF­¶›ÿëk•lş?FÊî|û%şùîWNÑM\¼'`Ê€GáÍh8ÑìÈCÜ©Äoô`w9RıDĞ¡Ââñ¾›ÏÂañ¹„röœîÓM¼!‚@ÏMÿ¡z„Pòó)+ß½šwÏùfB{|â’]9c ¶+¢ZÍ\.×BÃwş«kù%<h±mº0~dİÕ!h^?8Ç;5CÃ(ëÃ¦Ü5ñ¼öU@ÏÊ‘uI[1dbÜø?`÷œ–ÍJÈšOF®ƒcTâuõÅaÖ` "Ûğ	$ˆüD|ãÛC
G&­’ÔšØQòsRw7wvN¶^wöw·ÿ@ñ”J…r8IQJO‘5•Ú'”Q!’OâXëááËèp0T/®b¼í@Ô_W*eËåå0¥]H˜Ğî‰ „`4¢À®ôQÔXNËV…btìŠEšv\ª¢œ9¦â'‘)[
”&eƒh·Ulÿ§ÃäÕQAÛ xN¨wbyhõzóÒpMôËİ·ü@cY‚÷Ûæ›¦Š¨ï; fÖ‡KY¥1O8”ÆÀ7]Æç‚_J«S”ˆ¬	9¹¶Aœº'Ã3ın9ªŸ
ÖrˆGp&Ü30ŒÇYÈ5Ú*oñøŞ¦4÷ëëÄIşüAîÌµ•ÕûMÀ4î†w‘uL_v5° ºBÎ„FvĞİWf»óÎù¥œP³O'óÒ/JA¾WæK#0«À'r ZÈİäœ´Ğˆƒg‹Frïìo5w*4Nvšõ,o—–	Kx.bÌ0¬HLZKnLÚèh(ª¡)f@pF å#=„=ì!|Â‚ÂPk=Ú‚ÈÑ£¬8rÇÀŠNh*X„õO÷F®Ä HQø£¿ø÷ÅryéSÀ@AV-(ÒÙXˆ“|sW¼¼añràù¥ïğx‰#ÜŠ.¢·|\~÷Çãòû_®×nM%;È²\;ßvÚ»'È"ê¤J?_{nYch"ÅQÂ_˜PgÀb¡•ÁïzqqÛ1°ìh•ÜØÅk‡Ô¶£Í;}@<[oNµ ZR~bØ!yŞq7ŠÙëõ|H%ÇïI†‹2Ù¢ˆF´¶Û[Gû‡ßíš´R¹õ(õ<£7(±¥/Îí¥Y¹Ğİ¾%¥úV§İFDgÒ(‹¤oü@KlyT ó jâ‡=.Ó·8á.D&-­ƒq+¶x­·ï†lt¤F~.¬}Ş6×¾ÅGb_¾E¯J¢Ë¹ÍCƒnüAí]ºŒ`W{ÍfwLh”…íEPpÿõáV»…'â'şÀí¼ùàŠ“™ˆÅaJù·×pJºQqœr¥‚ãçw~£‘ºC¡ˆW¬ù¦ÁÇÄí#q
¦ÁQ°êªû¼±
f„g²ƒ+iÇ†
“4¾AÈ3Ëõ|…¶…zi@ìšİòeLjAZ7¬80#ÖÑáªÛi¾i·N8Ğ1şs£XÕ!0Ã\ñÓ\K€Ğ3‡D ™/J§(oí¶QÆ•[.’5ëyb.²
€„”’„x(™ãL×‘­ô-Úp¡pÌmGI|iN•†ì#‘KË‚ÊûJ&)öÇqz6m&Cãy˜Ş§Üj{4Øu )ö¼²+s³ØDG¨$Å°9Ú-'ÖääÈÎhæ­ (Œ¡#¶Ú··Ó¾§éµ¨•lHƒ}ƒ'‹Ğ]ÁT7‡#ÿ*œCù˜]lœaó|\4Áó5cÍ:EaÕ1ãp’`»¨Ã&—ÔÑÉ æjOØ!HH÷1?fv_óp…2ÄQ,\Ìdô3ôgŞœøÚ‰QJ«ı²ùzçHµ.J$u·)xkU)¤MŞ¢%ÁD¦P_ÂÕ„İİšæÒèíö´vW:›7}=˜=¿ºh¯$ô3î)¢+şL”Ê“¸-õüN‘L¦nşú(É€,@Ş¬êµßù2U^)MV=õ{ Á¢Â½RY(€yá¯ 'ªIÍO@fBó" øÎáÎ ÛÑ·!hÒª¬B¬Ş¨{¯9^÷û¡:
nº£é€?öØuô’<õ„[Õ()æŒ2¤7gÄ®ÛÓ¾yTŒãÃ0½ÆË©–ÔKğE7ıåé6—RËãÅ}ê©×’Š…Ê¤¥ñhé+nÃÈŸÑq‰ôJáj+%Áç{Mx%èâòÀœl?¼}x"{Îù 91«[%ã¯­[`Ê÷RÌŒ:M‰šfRÇ›ù¢g€–„*9;¬„ü-ƒHcâ(€.« ø¹Õ	j|R ñ¤
Á‰c»ÒÈğû:P¾ÈŞt£bbÈ[Ñ6©Ç,¤S}ƒ¨//†_ˆ•æcÎb0Ä A`JÅ¡şkB½ÎD^u<ûN«yÀ“2¥
tÏ˜µ£çYO:Xö&î'f'×ç±‡Šµ¾(&¶¢Ùç1ÆáìDeÈãQœ«lXğk™Å.—iG›sÄ
[{[nÌû31I¨L2
†ÃÒ	ii1i„”F0íŸÈÛIIa@ÊíÛä[t2Ík%áé¾ë‰WkÚBÂÓ-—Lr›îômåHÕ|á,L×ÈØ‹×ÖMp¡„~X/Ä@ŞX-™Êİ®é Åq:c_«ş~ŠU×ñoïØÎ'UÂKÉL¾aÄ*À¯ZÈ6¿©¿o’ªIŞÈ-Z	;sL|z=‹.Ñ1fv.ö[ä(È9\©Pk¶\—~ Œ­CrFc1¼ÔÅE176¡,¦ŠÉ¹H\Q›şõ¬àÒî)Ë|ê5#ídl¹g¹â¾­Zx†¨ºVÃ°…Â‡ëî'h‰LÔ“Hk°·S
¥^öIqw÷ğx¨8Äu²@Ç,D0‰'":âQ‰-]Z<øôå‚øŒ—/ê?)‹—b·_5Ò§X|÷İz¹l‘CIÑøN&iƒI[MÉ^ÁfKe’¬I&cjîÎ±m’Ê«å?.–GKƒ`=ëyÅîÙyµˆ¦Má‚Ä¢†J®Äu2V§¨ëû†n¨Î³6±*k5v¸JşcT7óìÕ[r$uo>3GºrÆ.ŸkÉ›ëÉ“p†ÒĞ\½¸}İ¦3X©í‹a*DªÈ#õb~Rş&)¿È	yªk_>KÎÃ	"v0ïÓµ§)yi$¯åOÈûå3îİ9ïıxR>‰—G·ıöüJ©è†:¶›äUwÔ‰Ûi%tK²ŸVJD÷Ô‰êù÷âc¬nãŞ~;Ø
Ç?Ó|ÄsÒÏ¿„…«±PtÅ	GÂqÑ0uG$ö—ÖeLoY ·{Uı˜YMÄZ-–/G
–»ÇÇ‘Wu¢Ÿz@§u…ë!m©m™UúDûû¨ÆÕw’oõrwÄğùó4ã·Ñ‰Pqß7	ª"MmOYä-!ÕyÍœmu%ˆ˜0Ü	Z>'·ª!ØöŞ›û™8‡`A$Óì±Ñ¿²PŒş¾h—›°>cÃBúûH¡¸¹;/$ßß?;%dÇ÷‘ìú%Š0»ö~eâ×x™à}$üÏ/ßG²Ç¯¿ğìÊûäÊı	­„|_\‚bKñrZSúŞ,Z“ÂR´Êû	Ed£¢Eİ¿$•K@YY”#b9|ŸUeåï“
 ›L‚ï“²¯MÌïµì*7±[šå;ñƒ®qç‰âchuÑ0Ğ»{}qíoÈÆy„’ sÒ@Y/OO%h½,1j¦—U¯^Ğw¥ê~Xü|vß+ò¹¸ ÔˆÆ„ñZÏ¾VL=3›RXx™E¯$8@ù„ß´¡Û“Iv 8€üÌıÆ!r´´ã†}9Ú„N¿móó2!ogb¿c`¥Šš\f
Ä3–¨Èd”w…±÷ïYD²jîl7²”_¹s€-Şri¥ĞX^ÊÃŸò…Ò
™´°pÏˆÉÈV:ÆòÂXü´Ì¡ La±|\+/%@¹¿`{ÓFÙI%v¨ÁNS[_S£RÔüæÙÌ\c9‘
”Ñ'Ş‡ï]˜&x¼›ªº‚ü®eÃ8PÛ‡U¾	‡_µøñ.upÜ#uQG†)¯k¹p{ İ©JİÈjZ­wÉ¾Æ—ŠÚ ©M7xl¾•¡ÕĞ‰ ;B‘BsBiËû æscQoò	º¶sIùM–ˆ ¾WxÆ»¤v-,†ĞE“Úşş}ÄNÎvØĞğ»ıU64™‹áCƒìE»É.E+*_½‹	
Œsƒ[à| «¶ìš.P)¬Ìú°òŠş>|­œğ-Ğ†7¥İÇìÒ„ÿmîıq•3E³¡ÌİÓáuiY³Äâ÷l‘w)5?¶Ë”İ­Z~Ävma¦² Ûüs·Za½J›h<Êùxı\e¸³qm×N^†q	ºÏï‡İ'ñH”–à,Tà@7Ñ@‡ ·°€§ùÜ+ÀƒAYeĞİåØçwhmÇ.*Y(ÇKÇ½4Ü³É”'ñÀC<ßê~ ĞŸ#ZÇ|ÊöÅlãc+ãCòù;¥ÚxÇEúAÍ,/»„Ğ'BBå£ïÌ ç
2Ó4ñz® õª¾–ˆm¹¤‹‰?1?÷ûj¼©áŸÑ^hE^ªá+Ò?M½¾j™æGE=dšŠÍşÜu9ÜøÕ6/5a3Í­û¾p+zÒ9:œå]Ã!¸˜¨‹Ùf_«•Ü(góJAq€1¥@M/ Î ¦Z‹’4SŠ­GŠñÃ‡)…6”„;^yo1áŒ?bÜ+¡¨ËIä^S(ª„Z1(5ÁvN+ˆ‰(¦rÏGN0“µó±ÀÎK;/H?›H;5Px˜rgnrg–Õ°Ú½¡ø=˜¶	Oæ2´šd…WõƒƒÉšØÃó÷˜>:h½i@LëÊ_êŠáK]3|©‡Úƒ›zİì
6“Ü3Í)Ú`6âgk®yaÓ#”Ã{Ğ~½—ûåÄåcĞ{aaô©ZqÌ™æ	Ä“~tÃS»_Ä_¼:)ä'QP”xĞæ_=<Ã(7rq-»õ¢\ê˜Ãü™Ï$øì4<G¦÷Yèí¡HL¿x‰âŞu•7VÃ{°òæç©e×SM0ÄG¥'ëêcñ_¦ÅZ¹›4Õ—EwÆ.¹•Qî¿5[¾zÓ:¼÷ÜÏ”tB.¥çÃ;İ.¥àŠŠ@éØD`MC*š=¸3’;zÉâHzşøLà%•7zSx×Jöƒ„kp]^êUÚ)]Ï§\ÚI¾<'PM-Ï¯ÙOÀ']S™ˆ–®Ò’—øÓ‡Ü:ü4‡Ù65»Ø-êôó™ÑˆpÙI,á#Ãó.Qï@4:G“"K@xá­–°’H'£Ë^Éÿè'İ;xÛâ1Df(»–XXfÆöHïèëâFF‡Æ&tÇ,ñ>Ñm'c„û©Ù ¤ºÑ'`áƒzWm{Ùbîs{Iıé&aNø uLóÿşr«kµJµ¶¾Y©Vü¨­¯=aŠ•H?sÿ¿]ÓEµ!FõñŠ
n?şkëÙø?Nê9İ‡üOfÿõj¥*0şÕôÿŸÿÃ'ÿÃv³µÛ.{TôÇÓõõ´ñ‡¯Ô"ã¿V©fñ%-Ğ6‚r~ÕioN§J("wÛmûâ_şËÿ¢m=ÃíYßKÃmk8àÙY-täO-*¹·Nq“İê’Ú™Bk^~‘¡v¯kŒL¯Äšôû}Ş×®øwÚX‡ 1@k‹«Àı56+ÙßÖìU¼Ua4c áŒ34}kø{–?æ®}WÙ%}G?Ñ¶‰n&˜7Ä.jñ r÷(&7s?ÌÂ“v,»#ÀvAktl1â¡ˆĞñÜÀüHàO]ô\ 5ò<c[ tŸ™ [»¦Ö-ÙZ?Ói³³»Ê›[«”éÕŒ`Wn­/ûV—º­ĞÍ5î[Q÷ûÚ |tM¥¥\nEÍ
¸÷3nÚ‰Ã´²8²^Yİ²Êılk”…çq¢v:¶»dò ¶ê%rtª"<ßw±¨äİâSË†m›	&{Ÿ\“'Ô‚æ­¡50\$ãK<i†WcŠ¥"»§8yÙDwŞ˜ùÒµ|ß´± úåæÆW\O‰ù¨ìXöø#{³û/ÿù Vˆc‹¼ª#R¾aAGS¹CÃš.4ìÀÂ¬|Üè­eØì·¦ç]•;¾kúİ>Õ/\ÏÁ8™4<ö÷&ÇÑQãDÂ6wñãQd¸Bgà†Çš‡|ï‹ê=ûõ×\‹ÓÇ•ˆgqÖ{‹z"é+UBç†MĞ}0×GĞYT/@ôÿñ) ×şÀÕÿTfïpGÙíyæ{ô^-{}˜«½r¼2VìçĞQ}±Z-V×NªëõÚ—õ/éºôáFU@Å’sõE—ßFR)UÍ4h3†ŸX˜bo¯&!ò®Ø¿xŸ²¯CÑçïÙDxJXA	Myú¡ƒo¨šß¿`¤‰Qœõ>?±¢)XCS½XâñÆ—Éşİa›…ià.ÒÁ™6wdoº§Lİ¡Ó3§A‹ô©
M5ÖŒJl—8b:†{>¦ùÄCUL¨jZRtªœë^èş2<–›ÒG\¤!Œ…À”†,ËUOÍBiZ=^zîJª‚<ç'WvfAôWØhôÜÄcß£C¯O)‘,P°à:cÏ9óÑC½¤`ˆØ!ö¦uDÚÌbÜh.*@7ËÕ;^wğ?•ü“¦­è”Šå*˜<ŠÃş©u'°6¥nrìØdşir?î8ç´€Ô_2Nt¼	«G.·­®YæGƒdŠ¤ÂCa¬¬ì7p 5às”"ğ‹ÊXJP®xº²"f,áA$x%Ä¥“![Ø7\x„Ò½äÒ+¸¤­°e)§p?fŸg <§€ooêK€sÊ­Çx OG8™ÜağPI‚H%6‡eöYi$:²,ÅgõÚÚWàÛWtÇÅ™~Mp@¡sÎ%>gäE¡®dI—>X#Ê$¹ìëhl“Û•ÕC™È²)•ÄĞD%É¤¢KJÆS2¡¹jd“ e¯$™–x,Ñ—ÿ°kj:Ñ¦PÿN^=€(ÎÌ“óoq?“ÁÆHÎsd¸¡rù;Ó¨	x¡i05=ß";ò¾™³k#D›oSÕ¤aI.1…”ÚhŒÙEÛ¾?°ìxÜ&È‰0…'Wù†Ÿ‘©oø!”òFÄZG9MåCXNÓ‚å0Êı?Ò”¯å!®|F#ÄuZÎÁ ”s¾	ËşÔ9)ï»@y¥š“êñ¾öìœ»qİzi¯£( ì™‘3Ãòé^¤>9c\oùƒÓ–Únô‹KLNP7`uÍH–ËwB-¾‹†#®Éó–7=,Ìl)-&[L)¬ğéåÁ¥€Ş`1N‹”äì $F3p¾+ƒğÏ3±–ö^o¼'®\´A%ˆƒQño˜qæ›Áº„ÓHßãBQS4Ú,Äùöò¿Å¼ù¸_%ŸšxçŠ­›
î(…ÚWTéã¾rlÆˆ	ÂhÆ°	s
œ€Æ"X•a+®ÏÊñ{]ğª‘/¡U‚^‚ÅpnUÈë–ÚİèŠsÒYX@/"Š<ˆ}İt»}Ë7I“–Ë½¸
œn¬HEJ²¨¾tÜ|3…6ZªôÉÅR!õzÄ±7&5 9D|¸ «ŠÈS90ºwéråe01ü¸'ìxP^óM¹¯3å¾n`}HÔ®R8P•¨íÄJxÑûğõf‰›A@cÉc]wŒ÷4Vù=Ôıª°°\'*1ä’z‰í´ o€LÆÀı.h?¡ÈóŒi Ôé©û 5ğØi|ç•Ü;ºhf¸*·g«ÂœÄÃQ¹4±nŒ4‚nÄ	»P…øôˆI.9$åæ„á)årŸx”ĞHúÄZ&g-˜_@Æûö)ú3–äæO\ë@ÊG¡¸ò¡	»0—_öBıjvy¼MO¸¦i„ï°|­Åaª„·v¹e¢fe‰$\yDZĞ1“I"„{WmLÃë¾|0Q»!'09iÁ×«ÀıÑ§
ÿ7˜é,„ß³
[HrqD›ºx‡b_À9:Ââ°)–wR‡<zìïyúù	jèE´‚¶Äv,_!1B‘´†*)è«FpQôù§y5€/Á*Nwn’†´Ş²ö…‰ZHZ;ˆœšxpi#h~1{¹/¶ÎØL™A-ŒG!¥œòûæG_vZÔ,PvZJ7‰NLì­XÛb&‡I£V
w£<×İ Fäì-˜;8W¸ÇSÈÇ	h~â¬°¥ìù°[qIêåRZÈ•èSÉŠ e
|O…‡ ÎSb»AC9¤ìĞ¤íDO¯ğxŠ-‹£§—ó#ÅhUùAÕ¸ˆ%«>K¢ì‰n¾‡h>>9Å˜yjÆd&ŸÈêÙ„¬·ËÄ3BÕª^t•-v{ÎiĞå£¨ÄV'(E)@’ˆs+õ²¼ê$Mc—õñ>U«úà{e<.VªTíˆR€^L™”Ö3ÕÕÉHNDÉNåúIÂ„&º­7£RÚ¨ë’˜L¡!Åt£Uœ¤M¼’juÇxìËC™•&
‚buE²@È‰3RÜö#+‡:èYºZ@7Ğ{V{Œl©’>.“„Ü_œ‚}‡]…8¤'Â¡£á@è–ƒ·±2qÚ®kÙLoµd¡ĞhÄB-Ï«T-¡§œè“[­/!T©ôÊ•"½¨ à™WŠÔJõŒÉ•j±„§öhd:‡U¹M­
òĞ™cRûîT© …¤2;z7¾Â&m±vZÛ/‰˜ğol¡!B$¬ĞİÑS4r³ §fWY:nËi‚õC Ê¯T9¹NoÜõËgÃËj­T+UKk¥
gg¯m~Ôª6n’Dµ
j¥5B’S©ävYËßõ>TK_–*'ÕõõH™ßbÄTbRò”-à#šêškRC-•C';Æ1KáĞÚR[º"Zû)ã*B'ÑÂ¤¥K'Rx@¾e%Zû»Íí½„>8ÛpËkùİ0HOŸ¤X)gHRÆJ¸¸=M–Ğã$P¼Õç$ĞWà'@YÃS2=¨‡Ş'ÛI8@EÉ\Œpè*qt/Æ2ÓV$¤úä€—E^ù`zåÀÉÑvÇ™­fÚ¼	ş@r>5=KêÛD#'Jó§Î…I²v²œÍ1˜Ü|;8ÁœÀ†ÜÂŠØj@%Íëêt ;J°È÷øÆØórüb1$/7%ôËv9K ÚN»R¥¸¼E·™bW§Dı	îæDıZMÜsqØ¡¿!Ô@QgtI€BÍÌtpWuIà¢úœé@#í’€£IÀÄ(&õœÈ«Hï±‘YÄ¼Öp¦h;ÏÜÇŸ)=/E\cô7këpßß‡:*^V5zÀu$$tÖMn#UÇTøçª•wÇ†/ÔËrk^ßäjdìORpİ~<$Y®¢2ñm~LÃ³`óÈuW4ÿ´…ŠÃ&­½!âk5:–Èm ñ×©'½ÀK©kR·t1ÖäFRQeø”h=„û½9vœ±]<ˆ"¡ŸMÜ‚ æŒ@ù-úf
	0şm6˜Â&Ûû
`tp“¿ÍZ%Céş²x^iœ›E|-Œ›ÃéAÜwi§ô‚#XO¸Ãäæ‰‘ÿBï¾ñÂrR!â7Œ}äÉÖƒ›Ì­‡Ot°!]û%TğøüJuÕÃFt˜!üt¾—­!‡¡((#jï3©t•*Ë„0œ–¤ÌÆÕÕÖâô‰÷+ªj™K+×m¢dø:k^*Ta[š`¸Ó”ên!ÆğZ„A*Bø0{Ğs„ˆæ¤·4ôlÛóÆ°L	“ ":ê?ŸãtÁj|ûH„ğcoé_ò†HpV)/©È\4K #ß½‚Ç§Kxr24–ù`ºï—û¾?òêå2"Z:§LĞÏÃ2ñCKË qı"•òÊ…z.·ÂŞµ?’¡ì9æ…P Ùw–'-¨Ê<k‹{ãÓ¡Å}pÑÛ[”/C¡uÜÕÅã]€KË£ğW=6¶É ª9‚%Ê”™W™4¬•*%ö­3–rÅœS:<6`@GWrˆEføìkD°»¼¼,°ä¸çeQWŞÙŞjïuÚE údóÏ}ëó&4Òyè:f¼ÿYÛ\Û¬T7ktÿóéÓìşçc$:ü’‡˜PÇäûŸğû)ÿZum£ºVy
ã¿ÿe÷?%ıÅßüå“?òd×è²ıû½”ğİ“¿‚?5øó'øƒÏÿ{6Í££CñKüOøó×‘,¾ÿ[X>JxÔ,aøpÔy¢SÚ…ƒf4şùü·ı÷ÿ÷ïîÕÎ,%¦ˆ=ëƒÔ1eşoÖ66#óm3›ÿ“~G|åd˜9Û>cÆğ·{u¶ø €ƒ«êÍW«ìÅØ™6ë-ôKíŒHîş%ëÙzùE«S€2Ã<ÇûªµÎI±öl•}Yİ¨±WÃ÷Oİñùù*ë€ ş½éâõó@U«%êªá|j}Ø“‰Oß<ÃÃ5’©Ù2ì¨hõïJ\Îş/: eo(İîY~PzqØè76zqÅ …vá¥„øg94/,¶cYäMsZ¯—¾¦ĞÒş•v]t†’fªÃ!„Iª ‚-<všãÃT NÚ)aŒ×Ia#0¸
ÏÉÔŠp+…Za÷Ÿ¨‘g@¨˜`4&ócè-ö…W³®êğX}Vªl–j•êShğ¼{‚f‚éÁ`î(ë-tÀª˜ß'4N+Û7>òxÓ<l¼Áè|sG\z;ëTKÇãß÷ëÇ—eö.âlì=[’9»½~C÷Ã~9m(¦ãáëææq@Öi¢P%C7š!¬SÉÛOÌ«d¤Ãc«0§s¢¬a+ºê(N¾†Ò0dQğšúˆ‚'¦Ô
«ƒšİDÏÚ^ŞÑ¯fk‘r¾ÜÚ>F/8p¾§É^Ìùª ı{Òº§ G¹1 x%TV¨‘™ß£mrÒ'àëÁ·´¾¦Ü=âÅhSAŸrœ‘~¼ú¾±D?‹Ä`ãÛKÀÀºü>Wüä@´“KYŸc2ô/¾hÑu‡p2Š«"Úİ,†AÁ)²‚PÕÁ„\êF£E/_ô5¯Îå¼òm™â9°J-Î”x.x«åÂ‰Ïo!WÍ
ğQzË¤f
¦ƒ’»;97Ÿka~`Z—Qg+àN“Ài™”şØGĞç£ÆRà—8xéôù[Åé±ü_¤JU¾‚öï ØæQ»±Å0S`%üDNi‚L¥Æ~è±Ò
w×8nÃûN!Ìiğİå ¾¼òø«$hŞ@d‡9¾¸BÇx$b³Z%È’@0éƒñ£±$Q ØFeò—ùÑRXÜ¼]q:DRŠ»æèv ”cŠw;á©“qa9¥+æ†Õ7Nƒ®IŒGJµKÚ1Q±(Ïˆñ	|‚—ÄÕ#ÕbÑwg7€r&v¯µÇò]»ÚjíX7/¾KcRƒÃXo<ü¼ÈÀGÀah¸W­328fşL}ƒgÕˆEÂ©t±HÖ¯·[Â¬A¼ĞJz@Ã‹€BÆJc—åÏÂäæ,ıÌ•õTı¯zp7Ï:f×ÿ®ÕÖŸ®³Juccm3Óÿ<Júëm¡ÿı×ŞZ¸W;³”˜BıïCÍş©ó¿¶¹›ÿğ+›ÿ‘2ıïçÕÿª³î§©V-‡&hƒ£ª`ÕÜ7Sß…»:x&åçSÀa\&²DCz#ó±¹wÄıÔˆ–RZÑlMòÿĞÑÃ­1ÓäÿµÚf4şÃæFæÿûQ÷ÿ­¸ù òEV\e‘ ^¸vá‡šø@¾&`†âË5åe'x».Ş6I5 ßnˆ·‡Š:»Õ´`,ÇíáëÕµ/ŸÕ«O×Ö×!Õ¿|öå³LO0kJvs6ß:¦ÍÿJ,şÇúÆÆÓlş?FB§u]GåÖñ_ªëYüGIè¯ğ¡ë¸Ëøolfãÿ)ôØ÷puÌ:şµÚÀ:Å©dóÿQRÄKèƒÔqûù¿¶Y­eãÿIw×ú0uÌ>şµÍ5ÿlş?JŠ¹ã}€:n?ÿ×«Ùúÿ8)Åcï\ë¨LŞÿU+Uaÿ¿¾ñt£†ãâ¦ÿy”´Àt¿ä¹öJÄFÜÚ=vÜx–.—ÿÄ	Æí…ÿª¾_{Ü¤²K&•ª:¢¨aTˆñƒ6œ»ÆĞËåx vü»¾HîZJ± xAÚ^%l{îŞş¤ƒxÈIGCM'x€„¿…ïèÛylJ9ÅoôäÂ™Şìç–’ãÌ·Û¯ÿ°
d÷%¥Æ˜cSÖøØøoÖ²û’2£Ç6úøÑZyìH‘æ˜{?ï$b¬!ì!Ûâ¢ZªVÕâ"1Œ²W5‚ošœQ6šQÄ;ÂŒ×$b(aæ=-
‡æ| '>€zğ¬ïág¥ò!w“	~?Ó”iŞuLYÿ×ÖcëÿúÓ§™ı÷£¤lıÏÖÿY­<A|çœrûÎl½WP˜7¼KÓü0¸bgcôˆÇ}h;g
ÈÛäÈM1ˆoåÀ‰Ÿ±ø¯
İ'Â:$‹±Œ¬è³—¯wv0|1|øäî¥nŸ=Dï•ÙÑ·öü—ÕÜt_Ï@—¥–İuÉŸñù:±²Z[][]_İX}z§îÜŞÛ:lï¶÷š?”^ª×ÇëÉZzreÖşâŞ®Ã>÷:ü¹Ò”ps©cšü·âüwûÿÛ¤ó¿Lş{ø4·	‹¦½š„¶mŸÌå»cŠA%®÷X‡²ŠÏ(aí(Çé”x¸ZÈ§Hk¥$™mU×ĞiDbS%2	¢²Y‚¾ûrÇ<ŠH&óTKü¢HaòËkiÅK«³Ëx¨ÌÿÚƒÖkó® Ça×0Ó&¿·ÔÒHCéM–Ónå„¡%×Q0D=& rÄô@*´ğ6z‡œ	ÈKéläÊÎn¡Äš<‚-m\eç®+8íiPÂÈ#QvjaÜß1t·üRnAË-â~+q’êÚwoÜsXw§´eE3Å¿åHmŞ»Ÿ—L¨ y0t²‹t•8eî™7û;ÖZz¢ø´j:x«B‡'§CÜ@;£ÛCvF‚ Ï‘ÈiÇú|DOó³ò÷›bÉ;	×$ÿÏtO¢R‚‡­Ù£_t“í\âM¸1:<öçˆwî2€÷9Å¿xãíN‡3ye#÷Ö°}¯a›>Æñ-Á8›~®‰Q+£/YîàËïsGW#³Á#’æğü¾!Ù¿Â	ØpDÈéÜ[(“,˜ÅÑÀ÷eœ¶hVğ|÷d 2bx"XUû£Ù%š»}Ù2‘İ[ótÇ9·ºxrÍ9£;À:%xÎHxÙ=ÃííıÑØo U¢~úI°÷Ô»¸çnÇß*b5¢;?÷š~›”~uL‘ÿĞÜ/°ÿ«ì„çkÙıGIïÚ{¯¶÷Úïs‡í©w„ãõH ü¿Ü»Wí½öáöÖû\§½õúpûèÛ“×­æQ»sòf»y²û-w;Õy}€®[gÆÀ›¯Y–"éóX&ò7´ºšcÓæ?¼çÿùxº¹–ÍÿÇH–}aÚ¸~ŸÀ˜ÇÖN¢‘!‡‹ÃÉ¹&|nì³tß™ÿãŞIºin* ©úŸÍ@ÿ³±ş¿7Ÿ®eö?’2ıªÿI¢ÿLô* 0^\\é³À#o şI"ƒ‡Õ %ŞC(f¨éz ™ ßQ”
{<á'£R}w<¬"H± hì´÷Z“ v#Ÿìºœ×•?ÕH„ânÏ3¥s®ê)öĞ©Ï?-@RUõL)éŒ¢M¼‡q‹¢®ÉI[IÖıXUC‘û¿Ü¥Ê	’v	_Ì¥©ößkkû¯ÍÊFæÿïQRf¯E;j¯¥Í‡­ñVpf¤º¢9	o6Nà_iNŸ~®]¹ta¯Û€îóÏ‘WáÁqÏs½n/sÎ))tğ ”â¶õ=™Äë_`%á»vƒÖNo5	vrğÏñâ‘šºƒ-ÇÆ ˜¦@>0X¨S!óÏ·‚ü¹YS–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,eiBúÿ|}Y ¸ 