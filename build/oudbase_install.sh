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
            ${OUD_INSTANCE_BASE}; do
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
        if [ -f ${OUD_BASE}/local/etc/$i ]; then
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
‹ J$hZ í}]sI’˜îìóÅáéì‡sÄÅÅ¹ä,	.ñIRaÚ…HÃ]~AI;+jyM IôèÆu7Hq(nøÁ~´_ıæğ/ğƒÊı‚¿ß‹€3³ªº«ú Iš®Ièîª¬¬¬¬¬¬¬¬¬SË.?yàT©T676ıû”ÿ[©­óEbÕµZm³¶^İØ¨²Jµºñ´ú„m<4b˜Æo¸€Šç˜óA¶³³	ßE;‚$éúß÷N yşØ+yı¨crÿ×Ö7Ö°ÿ«µµµÊúôÿúZuó	«< .±ô3ïÿ…_”‘N¯Ÿ[`Åù%€¶¸İ«³Å¹ƒ=r­£gy¬ùj•½{–mzk™æÀMÛg¿dñhä¸>[~Ñê LÇ0ÏM×´<ß5<Ïdµg«ìËêF½¾êÏÏWYçÒò¿7İa÷æô14K<Õ™6ààcsì÷W|ìøæ™a³}³ï,¶ì˜^yô®äĞ»ßø‚ ¥®3„Òíå¥wÏßêö¹Ù{qÅÉß2ü°n5~àYÍË³;–E~àÙÆîÈñLéğët]kä3ßaç&üÓ7™eCÓì®Éx™á1×ôÇ6ë:=)áø¦'±9êC?zü–=¸bcÏì±3Çe¦}a¹M
ÓwÆ>;zÓ*BÕğ‰ğ>ƒn…ÚXß÷G^½\>‡œãS¤N™SÌC,nÎ½[<ìà*Ç½ªÃc¥Zª<+Õ*Õ§Œ1(ŒmÛ–ovaºHFÈS­•ªUÌ³)ó4{ßB3šğ3;6sÎS ¡¥œE¶•:Cë{ÃÄî=g~¤Á¶ÿºur¸¿tÒÚk,^+OõbØÆ?Ç¡WrÜóü!Ğ¶{ØÆûã‘#p-#ãÏŞƒ±éİ£A¹7íÃÎöş^z3×Úo´÷ZüÑáëvÍ˜€wÓÉÎ9;³à‡1™ X ö‹ıN»‘ÙÜéÜğÆ)A6ÄÑÔÙ:Ü>8:Ùkî¶‹ËÈá6È¶X)ävNZÛ‡í­£ıÃoù²?åéåËí¨}ñZËpSÖ‹—ó¹ÎQóğèä›v³Õ>läé	Å“]İ¶x­Ô~Ã–ßp‡÷‚|7³lq%ŸÛmnï4[­Ãv§Ó şã0 Kİ~®}x¸Ø¨äT¸Orp/Çv™ê>ÌÀÁÍwô	¼ØkÏ87—ì:*[[–7W<ÃœkGv
¸˜š^µœ]ïœå·÷^î³:¯x5ÚÉïŠı—-ö5îí=à‰½­ösVl±¯Aèµöà÷wü÷ŒöKÇí½æÎŞ'UÂX±ŸÄìT9[öqrÂäO)Å/’Š'Œ””ânRñnßì~ éÇ5G«Kr)€Òî0Iö½@ö­³®İhY®ÙÅI‚í6´ÆM—Hºğ†Ä+’%)¥cİ‚	ŞÀ$Ä§ä¤r;Î9‰'˜à¯wö_¡t¸áù¬3ö^VoXñÜgöş+œßíœlæÖÀ4ì¦İû‡±åó|‹×µúl`®•ù"/¹|…Ñû3+w“›û\—8´v9cqå[CRX†£‡êDõåBîšÚ¹½wğú&Éêõ•›$&¤º®ñÁd ÙºW0ìsvjÂ?=NÛ.Èk 9ºµ+0#(ÈÌ`¶:YØNbp¾«&· OòğÀòÆ¶wÛ'ÀG»0±ô@-aù_}ñmñ‹añ‹ŞÉßÔ¿Ø­ÑÉ¾úJ)zx˜^ÔR˜f(}‡z÷‡µjõæój†ş]ËPJH²éİpäiBC¾É³j@t0È¬R]˜”—êèöÌâl€ƒ(Ï>ù¦ÉŠ†2ƒ’Ú¸š&ÈCJşôúÖ™<]öqÜÖXí/ _ÂµçhUÜ¶e!Z‘—S[—ØÂÉà´¬JKã­í9¶—Msì¶çÏ“Úô£~2’³ï!äs "Õ	•"İ”G Az`ühù M›ø”'A=!’«(ƒì•B0ç¢t…™6¦=«âªªd‰
ÙÛĞL¶Z.±·°$>gÆĞÛ¤‰îù—È^‰u`piZCñŞu\Ô;ô^I­¢6k0[Æ©½0+ü©ğU­„Ô`1ĞômÇ§Nõp:£%äQóÅƒªàá°¹µÓ´›“ÍN„p@è©µR1ªÇ3}¬½4.k€Ú£Öjuä-g<èßwû|Å‡íÒÈ~0Çè±ãÅëoö=Ê%‰¤
nmj{;Ìöm¾8?ƒ†™=µüúÔòm×
!:=Ò"ôâS[Ã‹SïºcÛFıEØ„ºÎphØ:¸ÚÀõ<EEO„º6ê®åy¤YÅµl•£gá­G#İ¢¨¸À¶M.¿öLÑjKZŞÀBY‘`HhÌ¶1#=a *4ÄaiŠV`GË#•îhâHŸåHñ2<•!¿GQˆ[6üòE–‚ÿ³g…ÈJå·h$»4lÛ`èï}c0p´aúë©bçµıÁv.mŞô}¯ˆ™¥¡ä&&üuœÍ¡sjµ‰
5óAÑP9q‡ÈÚórÏ¼(ÛãÁ@<Pğ9aÛ97†Käıí} ó@ 9I¹ÀçâÂÊ½ÊIÕEfãª‹®¶pŠŸa¶¨¤‹Q¾””+®ÒiËÊZ5XWYŒåÜ¡â }šqÒÑeŸ>Á—_°b/òYEP«µZÚ°®$
'Å+±Åå3”6áÔS$»[`ì-DGë ãì!H±ËöœĞåĞ ?å Slyº—`üås|
•A+¹ôkÿ„úûå/±›.Y^±hÍXIsAèt©ª*kÓ.)v¤ÎqÂqîŸËrp»†u/·Âı¾kŒX^kØz%ké\NH ºb;IÀ	
ˆ€
:å"f7“uÇ UÙdN6Sò‚.\÷ÂñvnúÎØV/?r~8¡‰Ùp€.0ƒv'¾î¥YÿÂª·êßÕÛuµ½`ùÁYx£*²À—Ü2WQ„îE!¢+ß¬Û½RÙtÿ HóJ›«Z˜ÛÑRr|'s¨¦±”¼n¶v¶·šGhÄaÕ.è\™å×²±5¶¸¢N´
¤…Ş>”1!Adh‹EmTws%MØÀœÙ5e±[Ï¥D-ê …”`ÏY0’aTÿ²šÃLÜÎ¾øk¨«OJ3q„‰Øu†Bô6½ò'­€4Úm°	05JJ˜ä‰o‚ˆ	gĞ	#åˆ §L¼ÄOˆÍ$ùL—&ëóD¹/°,’€ÿ¬ó‰ÖŞ›\÷ÊbêK °x}ğ¶%rÃÉô1EÆóOš…Ö×â#fÁˆ3¶¥bR6¢ıE<'r‹|Û¶xæZ&ğÓ¼±" áÈ§ß®32]ß2=Ä^q…iíúüµÚ&–ØPÈè» 6©ŸëL5‡c³8ê·çòõª–]ğˆ!¶mÄw ™ü)Çàûá¸é‡ûÙE‹-yå?.–‹å%•¡ÔwLN/ŒîÈË¶[Ü$=|k„;ˆèà€(ï»°+¬|ó£jôbùzï+¯|l—Yù«›Ø ÎôÿQäª+ S¬–?ğIHl|ÛbAl®tL÷V5ÈxµO–Ïa]ØtÙR,‹Øz4{Zİ)@”¾ƒe‰VwÜè¥Ë°JTİÜ•B .ÈúbAf ù‰/Är¸”±p!µÓjĞ_`"Õ)ÃÅJ¸ÅkK¬šow²{ËÆå¶ô¢ıj{ïú°ÓÈÛÅcX!½¤Ÿù¯¶_íí¶·`rhT¿âšÆîÁTÙŸXùÍ^Ï…>(£\]¬á«ã¯—°–¥ãçevZ^\ã¯Û¼ğ¾ àT¾b7¸-pMKz§÷8+®Ú¨Ôy}dAïlTcºüô.ŠwS•¨$Õy}V&ü4©ÕÈNŞÏËzgn½CJ ş¥Œ"¨.—aÄ(f/¡Gpôë6Ùç)„–Xvê<Eö²Åƒ}Pà›­İí=uêIÅŒŞĞ²g˜ÆâsWb_¥ÎaZ“Òº5Ñl}‡^]¯éŸè].C›Gb(D R†‡zş+Á¸7¬¬ùİH^ßd¿øğú‚8$¯oÔ™ıv^›¼u½QÓXÛ§oMëÑy¬‹ŸÛãSOÒÿ—»p}ÿßµõ
ùÿÂ¯ÍZ¥Bş¿•jæÿû)óÿıLş¿Á€û©øÿ
'P&I¹=£NÑŞOİõ÷Ëüÿ@®¿ÕµhAËö]§7ÕÖnyy#³k]…~Ø@„yï’Ï×}ø§í<WOà[»?ªïÏÈ…÷ıu¼…‘îáÂsí<gÅ!ûZéax5»Ëî}üugwÖã¼’™Mİ)ñRJÇš”Ş5¬+òäâ™ì£úÈ²ÌG6ó‘e™læ#›ùÈ
ùø°¼rš§N|™‡ìø™¯ê-}UçäÇù9¼
3¿¾Ÿ˜_dmï½iLõâKw äõ¨-sí»×ÎÙ¹ ŞŞƒ¯~«ìÁ\ô†u«Ş&7½ÇğÑë¤¸Õ!£bZ\–zÌû	M·^ùxµ|ÌÊç…óï›‹ÿŞOŞÅKˆ½Hß&ˆj!¤Š-%°ÙÎ¾qšh‰Œa”Y }´%$‡àÀ‚[`]×ÄÕ¬¡ïí£Æd(öèÌƒ‚Ÿ]eì‰£æ‹F¼¢„ŒD“ín^s£¶ôÇ…¥ğÈÑ§îØÌ«09Ôñ¹HámópıFtM‘'¢ñÚç%è§0¥ï`1Ä´Õ<jŞ”WğØDXjloÑ°!áZJú"¥È X±%ÔŒ´×¾áNŒD'm^HˆE‹ú¾•VËÇËğwá±(­,–«å¥BØ4uP<î"­ímp:+²4/øzì™“ØZ” 7¸\ÿPÀEÆ-Ğ]¶´ºÄà¿‚û.?	b›—$Î-;ÒA‰ÀC¿3z}CpmXo7Ÿ1}S2²<©Œ¹´<?‚àŒ˜ƒ®túnÇ}H,œ¶S
§x°½[”…Ş‡t1äG”eâòô\óŒ}b¦nyşê=AıpÜó’ƒ›#^É#ÿ¿, ÌR m¹S /Tì*õôe(‹°ìuÿ¡ Òx´Ê<gìvMUg+…,ªÈ«DíN~Öµ¼°©ïÅ†^/˜SÂ9÷¼dÅ‘tjù=9%µ¶u»„†Vz‹1BÓ)÷2åç¯‚où”-·&^ÄËÏwQ‰AŞYÆaV”¹EÿX8 İCÇñ¹4íÕQ¢®ÖÉAç^z÷®~:0ìõ÷ï—
1‰$€…#E¯öF…YĞÍAvw :øz¶ß@ß,í›bë2Kåãüêq¾Q^:s”á© [Ùø0¥+ğ|gŠæ~²x-;ãæ$@í†+ô*èôîõhWO‘!Ï	pÛ­°Õ» `­­ıİİ&êúbA´½wSæ‹ƒæb±ïx>5‚N$àÓLs39x'¡‰¾Y*í1¢" E†…@6…š'-ãJXÌ—~õÅx	ÖK iVúÂD®)BÁØgtõÓûûEG¦˜'[8¥ ïVî·~.hßˆŠ4OhjóÚ³20ÏğM!SÊ}îò±:¹ NŠOC ò‘=²ªìÖÛz–zö4Œ.Aâ2PIPry™~üªZĞåC¢ù<½Ûg§‹7îâÊî–ÙW ÀØ–×7{Qó{Øñšµı3VÏ¹´WAı”Í¿´`ÔÂŠÒtñd­Ù+åc‰â5½˜Æ.:‹xx&Á,Ò&iol’§õ9o˜ï‹ë•Šºüu.¡.\…"vİHŸ	r!E"˜ª	a>ş˜?æc'éÿ‰L<}ÿÏµµÀÿ³º¶‰şŸµõÌÿó1Ræÿù™ü?ƒ÷Sñÿäúùú>-ÁÿSü?Ÿ•*›Z]ã;Ü%$Z{HE¡ëÊ]„®cŸ‘-K_‘ıè}æPšíÇáPZ)U´ÑeÕ­ôèÛlÑë™Ä%ûìMGW#3÷»vû ±~8ØŞxx
š÷Ö4?Ğ`ı`š£Èšº6òÅ¢ü=üÈX„½ç™íÙƒÖg_#«şô}iƒ†Ia*z«lïm¶wÛ{GÍÌ'÷\ûƒòÉÍâÖf>¹TGæ“›ùäf>¹Å’OîL.¹™Snæ”{7§\¡ÛÅr3gÚ	à2gÚÌ™öGåL;ï8™?@GZ¿nÕ‡õöC¸Ñú° 3U¢3êc8ÙÎ3¬eæ5Ï˜yf^£?b¯Q±=7£×(÷/ùh8—S?Š9>í«>]a±/pv6hW•OË$ãëõ"ÃÚ1Ç‡m`\šæf“)>·×~{ò¶İşİŞ¾bsy/äöwZáX„oŠ‹×¸pS(PñÍ­ß½>8é´óx¥'P)bZ)ö.%¨ ºëa“
‡($Ö»¨k3v5TGÂğÄ‹°â›éÀpkfÅ±{.vVdC‚¬7)óf÷õãÔ7°È	àbÉØßŒÎ>
ù+T]t_eÁIä”ãÚˆÂ½Y©âOocÃ#¤‹¨(É—UÀ#;Üy.¦Rİàf†6ÌÒ³‹×:.J¡Ø§İEUWQ–Ôwb¹¡‡·ûÌ:»qŒº‘’!ŞĞ-¬xğ}÷l•U?\³äŸÏ—y[û{/Ùó´VOiš’/7À½[´-ZtÃ;M¨iÇšrC…¦•.‰<c¸PåqÜC»†|A?S`©1Mƒ—Bâ¡›LôİÈê¥Ñ9‰ÊÂãXP+âq<»·qº§ñ‹ÄA}§â™ŠE-wv(îL³ù§³^b“gğ¨ÛÍ±ïàU9]JĞ”.ºiÉcÎ ‡ş:Ğ{ušæ<ÅS„[dòŸæ?ĞDq ¡j³Ô%Õ:M'‰»‘»CVt“Gfâô™ôfì9jÎœ1èúËæy)® % ]HİØ‘wüÌÉÕ[ —¹zß"}nWÛdBçßÒI`f}:&ûW*ë•§èÿ½†îˆ›kë¬R]{º–ù?Nú‹¿ùË'şäÉ®Ñeûö{)šğİ“¿‚?5øóÏğÿìßÍ²yttÈQ‰ÿşC$Ë¿ïÿúÉ“¿=¼dŒF³40<€q-¿pĞ0ş-şõäÉßc¾¡Ñuq4q‰7àaúÑyVäı÷ï"yÑ‡ùt`nÛ=óã“'ÿ©øÿ€¹ÿûıoÿÿ­>
£ı0“v£ĞÕ1yüoT+ÕZtü¯W7³ñÿ);ÿñyÎø?æ³Ü8E'qñœ€)/<
OnD¯ÍN<Ä)JüHV—#5Nm
!l`àû¸hğ,ìŸ›A(gÏé~0İÄ"ôÜôOªGè3!ßŸ‚¾òİ«yxÎ'CÚ—ìÊ·]×zèæra¸:îx¸òX]Ë/AçA‹mÓ…ş#‡ì®†AóúÁ>Ş©:v@Yå®‰ûE°®~V†ˆ¬KúŠ¡ãÎÿh`¸æ´lVBÑ|2rì£¯ó¨/6³q³@‚ÉOÄ7¾<¤ëÈ¤W’Zó É@ğ%ß8'swsgçdëuçhwûtŸR	²P®Ç#-J¡yS©4¡Œb‘Ü8xÛ:X¿¾Œ6Cóâ*æÀÓÄıåq¥R°ìP^Sú…I	íPA( FÃ!
éFoPEÕ`·lUFÇ®¸²HBÓ¶KUÔ‚=ÇTü$2eK‘‘²ÁdlíV Šåÿt˜<£Ú+è§à4€:ËC«×˜—†kª _î¾•àïË¼ß6ß4UD5xß3³>ŒXÊ*yÂ®4¾éÚĞ?üxTZ‚¡ÄÍš“[Ä®{2<Óï–£¦ñ‰`¡€a-‡dò =Çx…Ü¢­Ê¯mJsŸ°¾NäÏäÌ\[™½ßBãnxYÇô%©AÑ¡¨¨ŠJ&t²r_™Áİõ\vÎ/å„ø›}Ú™—qQ
ò½2^[>Q ¸ĞCî&§ø˜à m„N„aUÏ³³¿ÕÜi¨08³iÓ0©]Z&LÜ¹ˆK ¦"7Ñê¸q’Ğ3GÃ@‘KÍ› ‚(¡ï.ø„… J®ô*E£GÓVqäAĞA°³*îé\X@º£ÊGñï‹åòÒ§>€‚¬ZP¤¯'ùæ®xyÃâåÀóKßá¦!G¸]Doù¸üîÇå÷¿*\¯İšJvĞ`“q#`ü®—e@¿©ddËcÏ-“ìLA<Ø™@Ÿ2JŠrLª…OñÏƒ†KFÌR¯ç7òúâpâ$rkû°½u´øí	ùÇcHO’[Ó´ç½¡ÀêŒ-}qvl/È…¾è>()Õ·:í¶pô9“S¤!ãšV`Y¢˜/»ªMPXèy\¦oq6%\È§¨¥—K‹×zûnÈFZÍç"~çííûWìyä~êÑÑÑ·ùHœû%4èTÔŞ¥vpüÖühvÇ„FYøG÷_nµ[¸['~Ò~İÜ›w®Ø=‰x¦”pOm§¤SÇ)Ç8~.H\øW^nîã"ç yôºY®ç+½èàÅ —¨‡®‰Ğ-_ŞĞ,:ñ†fÄW8œ:Í7íÖ	Án³àBÈ0W|oSÀ ôÌ!¹¥˜C]µÄ­ıÃ6j|rBs°âk!÷EV1QÒä}Cz¡õTäIxQ”A{A&T¹'%M«aï*‚‡:X™zå¡Ô—utPûU2I%8s@Ùdp|ÊŸçA`:M¹-R4ĞÁÏÎïVIÊÜ,Â.Iqó¶GË‰u99²3:=+
×àˆçòí½–ïéˆ,j%Ê@‹Ö€á`–˜YÌáÈ¿
ÇP>æ%¼§'GHWÍáVóNYG„bÌUšæ[X<é0¤":Ä\½¤ó	š³„t'éÓi¾Ñ‘N`÷u–V8C,˜Äb‰+t‚M:í¸ğæÌ¯ğNŒSZí—Í×;Gª¯M"Ã¨kŸH‘ÀİY«Jamrw-	ò\80…ûõ#|wkKã·ÛóÚ]ùlŞ<Füõ`Şíê¤ix¾Ş“@gÔŞ£+ÿL”Ë“¤-Q~§‰H&s·Æ}Ôd@ oVáÎO@™ª¬û”«që=vjÂ¤Âc4YĞAğ&8P¢šÔüd&4/Šëèw(Ä®ğK I³²
±z£®ræxøí‡*'8÷`âûëè–Åıê‰ !ª‹,rŒtHoÎˆR?¶e`”Q1‰İxôÏ¿-§º÷/©îıKğEw„åé6.ÿ©åñ€>ôÔÃ IÅH‡#Aµ4-}Å=úø3zçÁ›3K™m¥&‘â|U¯„9YüCñˆ“½i·O$åœŠ’óAU2şú×º?¢|/-£|Âèa‘¨£"Q(ØìË=k ¼$LŒ(Ùa&äßhD†q:n«‚à»8'h[IÄsõ%'6±J#Ãïë@ù${?Öª‰¡lÅzş¥óN-ô¢¾¼¿+ÍûœÅ`ˆ1‚À”ŠCKÓ„z;\ˆ2¼êxöVó€ $eJ¬:1kGÏ+²t:;±ìMrcOÌNÀcßuQL8lD³Ï£"ô‡*Ç£¸,VÅ°× 2‹U.Ó6úæˆ¶ö¶Ò˜Ó31É¨L

†İÒ	yy1©‡”F0íŸÈÛII@ÊYÔä3e2Ík&áé¾ó‰gkÚDÂÓ-§Lr™îômeƒ™¶DÕ|á(L·È›¯­›ÀĞ¯\„°^ˆ¼;°Z
•»\ÓŠdtÆ¾(V+üıÿª®ãßŞ±Oè
èª„—R˜&|Ãû› w<x Ûü&zß$U“¼[´Væ˜øğz¢cÂì\¬·(l7r¸5Ru'æl9/ı [‡ôŒÆbxÄ‰«bn¬#B]LU9’ÃT‘º¢6ıëYÁévuSi¹g¹â8©:éO8g¤›'[Xn`Å‡³ñÄ)å ‰‡ƒ‰¦éş4àÎQ
¸D-1¾O¦S#€P_àÂ1Ñ¤ Q†Ò!Àƒ®ãÎ8&ø|ùãxúrûU#{ã“èªÆe‹JbÆ	Iâ;u¢¢-r›-•Ii%ı’¼vyÜ3Ç¶i".¯–ÿ¸X-I‚©¢ç»gçE4Ğ™6İK#æ´%NA±:E%Xß7trµ‰	O«±óÀU‚bk¤ª‡Ï“ª·”Uê²w²êÊ»|&Šª)¬pèÒĞa·ß¼¸‡G¥}Oia‹m*Ü«è õb~Rş&)¿È	yªk_>KÎÃ9%Ğ00ïÓµ§)y©‹¯åOÈûå3îİEòı„UbF—ÚÖÙJ©è"6¶‚äUW±‰KX%t›²†UJD×±‰‹ØùSñ1¦½ñÏ_ˆEFlêãŸi âŞäçŸÛÂiZ—bÆ·„mX­Äò1e"ÖtÖeÌVX ÀoÕxÜ™HæZ,_,w#¯êÄ?õ€Oë
ÖCŞRÛ¢óYz Zô Z9}'iËT/wGŸ?OÃ1~šùå}s`ÑLå”ESQÃ§ÌÙ[TÊˆÛÀ åsry‚mï½¹Ÿ“m´Cr>İ#,ğ.k Çèï‹vÙ¸	é#6,¤¿Š;\óBòıı³“£NBv|É®»ñ‡Ùµ÷s(wpçe‚÷‘üq/w_¾dÀàÙ•÷É%~­„|_\‚bKñrZSú¢-Z“"R´Êû	Ed£¢E]Ø$•K@EYT"b9|ŸU\yËÊß' 1™ß'eY›˜ŞkÙUi oi,Ğ“ï$B,¸•›'º¡A³b“êŒ>|­Ûë‹ƒgC6Ö ÈÍËà2Ú›ärÇR‚ÖË’ fzYÕùŸ¾+U÷Ãâç£|¯@Éçê‚R#:ğÅk=wúZ1uŸjJaçãbDÜÎ å~ÖƒÎï%ù]bò3÷ë?„Èc ÒRìè‡Avôü¶Í÷$È9ƒâm‰õ•*¦i™)PÏ@[¢B “QŞÆŞ¿gÍª¹³İB˜R~ÅÿH¼åÒJ¡±¼”‡ÿ>å¥r#aábCc‘'p*Œå„±øi™C) ˜Âbù¸V^J€r-~Áò†²:’†ãĞjœf*¾¦F¥…ø-¶:u¹•p"(½O>Ü§Ş»0LpK5Õ¦øi'Ê†7mVùê~Õ@ãÇÓ¼Á‹4R.`¤¼®ñ;³·œáĞ±€[‹ZAté5Îv.)ß¡é lÀâ6|¯Œˆw<˜¥^ÉÂb]¬cypñ>âye;lhøİş*š†CÇğYä¢Ek¥.E¿:äLçÀxzÆ¹ƒ— ·ğ(;[vMºM)¬ğtH„¼b@_+{F$ ñ$ªÛã˜]šğ¿Í£ë­ò!/câ—yø/<*Ëó_ü-r’Róck(InÕ— ¶&	3•°ØÒ–‡-
ëUÚDıQÎÇë_àÖcÀƒ9co»yú% ŸßÉ'ñH”ƒ›à,4O ™€i€ 0,±>÷°âvß SVE'8öùEÛ±‹JÊñÒq/·'úl2çI<°ãÏ·ºèjÅIiß²0ã*t*ÚJÿP rşN©6N¸ÔÌò B}"$4­ù®Á¼F Ç?c¯çZR¯ê’R,:%_<H|ÿù…7WãÑKÃöŒàÀ+òĞ—·ÿ46=Œª©ùø™AÓòp#\ñŸ»¥‚»SÚæ¥¦J¥…ÍŞaO:G‡³lÛj8çÈ4p1oßkµ’e·W)(ìöS
ÔôÂô>¥ĞZ¤Ü—˜Rl=RŒÛÜ§ÚPìæ	¡òÌYÂ®qÄ]TBQ§“È¶®f.S?£YPj‚7–tcU·DJí"Ù¸KŞ&ÍÇ€ÄK³†§[ŞÓlâŠSÎ;M&f9ÑÈ¸ D‰¯Hƒa›p”a.]«í£àQè Æ`°&RxŞı³¶† ı#ˆÙ¹+E]q¥¨k®õpm|SÏcS!f’)Óœbëd#¾qäš=B9<“áG3yÜCœ~ñÏ`¥'Üh#U+Ó"‚ZcrÅNçi'VXëTg…ü$Š2z‘‡$	Îßáƒ8q—i'8(0‡4ŸağÙ¹xbï³pÜÃ1™~œU
<A)ÏA†§+åyÂSË®§zˆ
-ëŠyTæG4±VŠJ—D7h	¿—Bw(§*Ÿ-_=)&NıIH:+—Òóá™\—RpğA tl"°¦!ÍœÄEí#q$=|&ğ’æ‰	ÔŒ’#n ëÜZ•z@s
Iãù”£ ÉG²ª©åù1é	ø¤ÛâÑÒ6òvz—[gB¢¦â0[Ç¦f—b İìû|f4"òc6dE$ÁÈğ¼K´=…¨¤Ú0^xV"¬$RÁÉè²Wò?úIçŞ¶ø=3”1J,,3c{ä™tŒUp£_ø…îtr)ñ”ñm'vÛåNUNÀBºzjëÙbîsG¢ÌÒçHÂËïAë˜ÿã¥V1úkm}³R­2øQ[_{Â6+‘~æñ_»¦‹fM¼ÕÅ{(.¸}ÿ¯­gıÿ8©çtvğ?™¹ÿjµjµı_İX¯dıÿ	ûÿ°İlí¶KÃŞÕôxº¾Öÿk•ÍZ5Òÿkğ+‹ÿıiŒt)cW›,´ë…ê»·Ü¶/şå¿ü/Z‚‚Ú3Üõ½t›¶†£î‘Ï@°H±ºB…—Gk<0¬*Åİ Uã(ô¥å§îÆàöºÆÈôJ¬9À¸Ïç}íP»§Œuèôu¸
Âcó°’ımÍ[Ä[.+º­8CÓ·†€¿gùcÚu•]ÒwŒl›XyCÜ£ w®cÑtz‡WDR.Kãğ±]Ğ[¼ñÎ@Dhûp`~$ğ§.Õ‡ÅZ±-Xœ™ ÷»¦FÆ–$£FgÚĞmvvWÙask•2½C‡ì¡ãÊeÿeßêö+sŒkj´Z._œ¼wM¥¥\nE2Í
ğF¢Áw¬ÄnZY	¯¬²¬ò8ËZ]yš¸€í.93B‰‡fÏwÇ]¤‘@¦=µlXRšĞa’úš:¡Œ4n­á"_âN8¼ÓÍ Q.²{JÈ”—MçŒ™/]Ë÷M`\fîúÄ­¨˜‘÷Êe?²7»ÿòŸÿ`…8¶(ª6"åšÊŞèÔt¡afåıFo-Ãf¿5=ïªÜñ]Óïö©~jÚxŞ“Hİc_ñøiõ@X‚/àFÁxé®0´á±£æ!_—£ñÑãqİµĞÒôq%Y»µÄŞâ J$}¥ŠBèÜ­Èc}Ä¢zx¢ÿøÿHpÛío \ıOeöW»İg¾ÇˆĞÕ²×‡±Ú+Ç+cÅ~•«Õbuí¤º^¯}Yßø’aT}4z9gÑøØXtù$•RµÀÑLƒ6ãµÓÓİË«Iˆ¼+ö/ŞÃß§ìkÅMóù{6ƒVPB3í>GhÃàšMÃ÷/Y‰”°­ÏßO¬h
ÅĞQ.–ø}ÓË@}ˆ¡ÏÍÂ4péàL›27İS†îĞé™Ó EhªBS]egŒÛÅ)„ái<ñ«
&T5-)ö^.u/­nNi‹#{.ÒÆB`JC–åy¦ ^c¡4­Š¯cU%UA‘Ó“«‰Yô
±Šø]´÷ aç(å&T,¸=ÛsÎ|ŒP.éânƒP
{Ó‘6²wY‹„Š×buÂëŞ§²Ò°H©XÎ‚É½¡lŸZw‚h`Sê¦Ï‰MæŸ&×9ñãsNHÑå»QÁ‰¡&aöÈå¶Õ9ËühÎB7iğ«VVöEà3ĞGˆğ9ÊøE,%(W<]Y#–ßá@,x%Ô…È-¤W¡t/¹ô
Ni+lYê)<r—ÀçÂ€Ì)àÂ›h	pN¹w¿èÑaUƒ üª‚$Å4ˆ›Ã4{¢4r;Š,íÅgõÚÚgàÛWtÇÉ™~M°C¸çŸ‚}
ŠG¢pW2ˆ¤#¬»Ê"¹ìëèİ·+«_e!Ë¦*I ‰Ê“Š")Oõrˆ	ÍUo¶P–÷U$ó¿Kòå?ìÅššÎ´)ÜÂ¿SJ ìäü[<²b°0’ãnq‚ÜÎÔk^èºLÀ˜¸·È²oæìZQ¨âÛT5©[’KLa¥6:‹vÑ³¯,;~ï‹@cÍçÄ5u'ìWù†ïß©oø™òFÜµ%¶:ršÉ;‡°œfËá-ôW|»U¾–Ìò$Öi9RÎù&L?|øS»ÈGyßÎ+õÔœTøˆ‡ãµgçÜu|¼×«—ö0Š@ÊŒ,–OÇí#õÉãz£Èè.0Õv£_Äµ´tVmV×Œd¹x't·AÂwÑpÄ5y¼Óô¦_‹¢]fµŒœÓ-¦Väôr„áR@‰P0™Œ¼N‰Œi $z37+ÒóÏ3‰–ö^Ï›'Î\µA#ˆƒ·¢	<ß1ãÌ7ƒy	‡‘¾Æ„¢¤¦h¼Xˆó%8¬å‹yòñÀ&â~)ÔPLü}jâ‰'¶,*Äu7)Ü¾¢j÷ÆŸc3FãJ3†äŸSP~t|—¶ğ áö¬?U¯ùRpIG@…àÚ.­
yİ«C;™<CqÎ:ÜCÑ‘ÖM·Û·|“,i¹Ü‹« äÅŠ4ä &‹6àKÇıÀSèA¦jŸ\-Zo`G{c2RØ;Ä‡+°ªŠLwª¡FGü.m³|àì&^?í	#Ô×|S®ëL¹®Xí‡«@?4%j+±sãÊ>|F»YâbĞXòX×ã9’U~Nm¿*,l#·‰J¹¦^bûÁÚ¥_t¹)Aú]ĞzBÑçÓ@­ÓS×À<êÅS§ñ•W2u4tÑ	rU.ÏV…«‹‡½ribİkdÄ»p]ñè‘ ’R&²IêÍ	İSÊå>ñ["#ék™\´`^||SØ§èÌXJĞ›?q«…áZè„&¬Â\îÚíhÙå÷-z"0h#|…åk-‹P%p¸´³(10E0*KÔ H#Òò0Ô¾©L!\»j}¶å‰Ö9€)D
¾^éMøo<?L{!üX¸ÙBš“@ˆ#øûÅ	Š´AÌµ‡'ÜÃ¥xJ:ÊP Ø%C1ôı´ĞóûEø=i½Ûq²|†ÄÛo¤§V@ç¨÷D?e®$c«9æÙ—Œ@°°â¹î e0"ÛH`·s•.§PõĞüÄGuKY¾`¡têå
G8 •‹î¦v1í¦É+ğ=÷Q‰í:üş `§!e‡&hQuz…;-lYì¢¼˜éºIu¾*Tm¯†¤‹ü":Òèuøx€~Ú“SL.¥fL–W‰R‹MÈz»L<#T­šøVÙb·çœ-Pğ1jLIlu‚}n·WvJ#¯:ÉhÁÁØeC}¼OÕªi³Ä^úZ–•[UB”ôbv‘4ÊTW'#9=œ{¥h“SÍ‹š²ªF¿Ót×•
¡cACºúŠ&$Rœğô§Õã&¿ñ)¨4Q§U¨]óuÔbNHefÛWvu@Yòà'è”Õ#«ƒäO¯ÜH:$ßĞh‡¤BÒáPÑp tËÁÛX™Ø8Vvhl¦·ZŠPh4b¡–†çUª–ĞSŒßzÆäVëCˆ U*Ã»@¥È/* xæ•âµR=cr¥Úµ¨S)ÎaUÀnS«‚<´}–Ô¾;U*X!©Ì~Ÿa“V;­í—ÄL¸5¶pO=r'ÌİÑSŒK³ §fWE:®0i€õC Ê¯TÙà•voÜõËgÃËj­T+UKk¥
vg¯m¾kZéišDµ
j¥5BRt¢äv—J–¿ë}¨–¾,UNªëë‘2¿Å»$ƒİ‘ÌÑ¬ĞÔ\ë”j©:a-YŠ„ÖÖBÚÔ1@OéWq‹q/LšºÄÎİíÆW_„Ak·¹½—@ã‰£µïXËï†Azú$ÕJù8C’:VÂù èÆ¨„g€ã­>g¾?ÊRèè72è4ÙNÂ*J–b„CWyŒ£«ÄÉ•™¶"·CO& Ô8-òÊÓ+I®¨¶;Îl5Ó"àM¨ğ¿	/…÷,¹vlı5lœ¨ÍŸ:&éÚÉz6Ç`>zóítà„€bŠ/*.^PoÃÑÄ¼~½˜`G¹é/”=¾ñ–®üú/~†—’gˆèr R¨¶¢ÓN.i=.Ï=Ñ¡¡Ø	%QBÜ2Q¿V6B˜"µ P4ªY ĞÈ0\$æY¸¨ib:ĞHd´$ ñc0Ñ‹I”yí=ÖS"W"`máûø¥ç¥hkŒ¾ñöq».ûå}æ«;à4ò9ë&·‘Àª]*â¼	K‰*ºc½Z¹_ªorƒ(Ò“lMF·¿Ä|0Ñ–xÇÖ>¦áY°vä†%~Ú<E|a“ıÙwÒj5&–(l ñ×©'“<ÀK©kRWt1ÉäF‰¨2üFÖåBåŞ ÷A;.WŒ.n©ÎÏ&®ÀPsF ü´z3…ÿ6Lá]ìŒ}0†’IŒßf­²¡‚ô‡	H÷Üy3ÎÍ"¾nºáğ á‚‹‰ÀÉ„ÀS(‚àÇÖa¹#[â­ma”X„xa9©ñŞ[ãÉëˆù6IX±mÏƒ¬;œ”Ÿv.OÇçH3ÔÑê×G$ˆgEĞxKÿRP&”	|¼HŸ{™‹H3Ä»Wğïøt	íÈP!Ã½ÿ¦û~¹ïû#¯^.cèÆÒ9e*ua™¨&eĞ:Æ~‘JyåB=—[aïÚÉïïœóB(
 Çì»Ë“!eµ€Å½ñéĞâ!èí-Ê—¡P·cuq·
o°$Y…fmşªÇÆ6ùgA?4G §L™y•IO§Z©Rbß:cà«+æœÒ^˜SÌèJj+¢3|ö5¢Ø]^^–XrÜó²¨Î+ïloµ÷:í" }úÙ-Ïà&ıƒ,QÒŒç¿j›k›•ê&?ÿõôivşë1ö?íÈ•¨còù/øı”Ÿÿ«®mT×*O¡ÿ×á¿ìü×£¤¿ø›¿|òçOì]¶ßa¿—S
¾{òWğ§şğùÏ²ytt(~b‰ÿ	ş:’åÏÂ÷ò¶„GÀÌ^˜‹†"š¹pĞÁŒÆÿ1ÿ€ÿ¶ÿşÿşİ½Ú™¥Äñg{:¦ŒÿÍÚÆfdü¯mfãÿqÒÂ/p_¤ü³f[MÎ˜ Şâv¯Î ppTµùj•½{–KœÆÍuF¤¨ş’u„2ºü¢Õ)@™aãy5¼LÊÕªöl•}Yİ¨±WÃ÷Oİñùù*ë€Æú½éâñÓ@íQ%êª3|jı¾ãŠOß<Ã	RBÙ2¬C
èõïJ\1ı/€Ê*”n÷,?(½¸bt‹ûO¼¸âĞB¿ĞRBüÀ³šj§±,òÏ¦…ŒÖË^
WHéÿFËu2<§ù7ğ0äa’·`áƒDs|Ó“¨Óš^x#âq2ĞœaMl.¨áÚ×’ÂY >Q#Ï€p9Àæ}O7Áj±o,<šqU‡Çê³Re³T«TŸBó@Æ0y_¹<Á<w(,ˆT\Oïs1+Û7>òxÓ<l¼Á»±æ¸ŒÄÔ©6–Ç¿9î×/Ëì]$Ò{¶$sv{ı†#.ürÚP\GÃ×-İ,€¬ÓÄ …J†n4Cô=%o?1¯’amıaNç4DYÃft5ˆ•|¥á…!Ák¢]]–R+Ìj^c;k{9¡_ÍÖ"eS®µ}ô^°Kw#¶à¼XhH@û÷d«L ö¿b Ğ%™±Ğ„12¿ÇYe{DÀ×¯¾Ñh¹{ÜÖ }ÈqAúñêûÆı,’€‰o/=€ ã—Â'Ø[Õk.r©·4ç˜Ï‹/ZäîFá*®Í`x.E~ç…p@.u{‘Û?—‚¯úšWÇr^ùŠ ñX¥–GJ<¼ÕráÀ‰ç‚·+ÈføÆ8=„eR3ÃAÉİœ›µ0?dDlÜi8-“B@|¤85–‚¨©ÁK§Ïß*!Yå7ø"om‘¯ ı;£rg§yÔnl±Œ˜	?QPŠ S©±„z¬´ÌİuÛ0Æ¾dHs|w9€ï¯<ş*	š7ÙaŒ/®ñÉ6«U‚<!ƒ> Œo%i|†b•É=\æù°¸y»âdzWŠ»æèv cxÅ»ŒĞV/A\XNcéÂŠ…ˆôÓ€Tcb‰ñH©öCcI3®‹Ò²ÎHNà¼$	¬nD‹¾2»9 ”‹0°{­=–ïÚĞÁe—Àºyñ]îÀ’’la©˜xãáçE>CÃ½’hõ<‘ÁæÜg¢îğ!	{yÅ"m¿Şn‰½`ñB(ùw«O 
íX+Y\–?“›³”©œwRí¿jlÛyÖ1»ıw­¶ştUªk›™ıçQÒÜşkûï¿şóÖÂ½Ú™¥ÄÚjôOÿµÍÍØø‡_ÙøŒ”Ù?¯ıWu?M3°8ã6Í5«>’™9øî(üØÍÁ3(?ŸoñÍÜÑn ;!îgf@ü°”âˆ~^Rş‡ñKn™¦ÿ¯Õ6£ñß77Ö³ùÿ1ÿ«óöEQ\e‘ë…pîÂ5ñÎšÀÅ—kÊËNğv]¼m’i@¾İosÿv«aÁX{×«k_>«WŸ®=­¯CªùìËg™`Ö”æh¾uLÿ•Xüÿõ§ÙøŒ„A«ºÊ­ï¨n¬¯gşŸ‘0^ÙC×q—şßØÌúÿ1R±ëáê˜µÿkµ`€uºÿ¡’ÿGI‘(RÇíÇÿÚfµ–õÿc$=\ãÃÔ1{ÿoÔ6×¨ÿ76²ñÿ()óê¸ıø_¯fóÿã¤”ˆs­£2yıW­T…ÿÿúÆÓö?¨ÿ™ıçQÒÓãçØ+qokÓÍî±³±İ¥ÓÁ%­âãvƒÛNÿª¾‘P_{Ü¥²K.•ª9nQÂ¨ğãm?w¡—ËñK¢ñïú"Å¸(Î‚âY{•+¥s÷'ÜÕ:1˜lôÜ„°‘«Šo;öv‘c'»RN‰;¹pf7û¹¥äøáó­ãöó?ÌÙùßGI©ñãçXÇ”ù:>Öÿ›µìüß£¤Ìéã±>~´^;R@¤E3ŞÜwqÖşíqQ-U+êq‘x	ŠWõ¼¼erFq±ÉôŒâ¾ÌxMú'^%êÂØ ‡¡E×!9è‰w`cƒ<ë{øY©|ÈİdŠßÏ4%]Ç2ï:¦Ìÿkë±ùıéÓÌÿûQR6ÿgóÿ¬^  ¾sN¹g6ß+(ÌŞ¥i~\±³ñ` øò[±7"Ÿ)±ó­$ñ3¶ÿU|"~²ú»’}öòõÎ^_
~¹{§F©ÛgÏŸ·wÊìèŠ[{şËjîÈ×30Ğ£ew]
Zg|>"VVk«k«ë««OïDÎí½­Ãön{ï¨ùC¡ª0½>%k5¢äÊ¬ôî¼Á>÷<ü¹Ò”ëúæRÇ4ıoÄşï:ÿ·Iû™ş÷ğin]{5mÛ>ËwÇtq8rÜcÎX(*>£v†µ£ST´3PPâ×UB>E[+%él«ºº†1;#›ª‘I•ÍĞbâØó(*™ÌS-Uğ‹¢…É/¯A§Q/­Î.ã÷`ş×PZ¯Í»‡]ÀL›b·SK#U´7YN;•^­&¥Fˆ‚!ªè1#¦ß>¡AO£w(˜€<”Î–A¯ììJ¬Éo°ÄKÛVÙ¹ëÀ{{”0Üıïu:5ÏğŞÏ1]èlù¥Ü‚–[Üû«\.S×¾{ãÃº£8ğ›.ĞYV4Sü[TĞæÔ%ø¼dBÉ¡³]„T¿&Zß3ñŞÜ$ş¬µôDñiÕğ[º¨âÆÑ‰ÀiwĞÎèö„ Às”rØ±>_C Ó‡Áø¬<ÃuÄ¦XF@²ÄJÂ5)`2“¨”`Å¡gköhÃïGt.ñ$Ü#ûsÄ;÷ÀûœE¾ñv§Ã<²‘{kØ¾×°Mïñ,A?›~®‰ÇF_²Ü;!—ßç®FfƒßH˜Ãıû†¸ÈúÀ†#®œÍ½…â0È‚Q½øºŒÃİ
¾ƒï¼½¤ŒQÕşhv‰çn_¶Ll÷Ö<İqÎ­.î\s`Îè°N	3RÁ^vÏp{ûc4öÀ•h_:	ò¨‹kîÆp<ğ­"V#Èù¹çôÛ¤Ô[ çXÇıİıÿ¿èN¸ÿ·–ÿx”ô®½÷j{¯ı>wH·=ƒ "óˆTŞ „ÿ—{÷ª½×>ÜŞzŸë´·^n}{òú Õ<jwNŞl7Ov¿åa§:¯0tKãÌxóõ"ËÒC¤Ô»ŞçXÇ´ñoÃñ¿Fñn®eãÿ1’e_˜6Îß'Ğç±¹“øAdÈáäpr®iŸû,İ7EÆÿ¸w\x37ĞTûÏÆf`ÿÙXÇøß›O×2ÿŸGI™ıGµÿ$ñfzPxËVÜè³À£h`şIbƒ‡µ %3ŞCf¨év ™ ßÑ”
{2á'cRcw<¬!Hñ hì´÷Z“àáF>ù†àr^7şT#×ºv{)ƒûpSO±‡A}şil’ª©gJIg-xhâ9Œ[uMÎÚH²eèÇjŠœÿå!UNµKøb.uLõÿ^[‹ømV6²ø’2­(ÚQ-m<üh·Z€#u×-PÍIy³HÿJúôsõèÊõ€„½nÈçŸ#®Âƒãçzİ:^æœSÜSèà8Å=7lë{r‰×¿ÀLÂ!víÍŞjì.äàŸãÅ#5u[·Fšn ùÀt`¢N…Ì?ß
òçMYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–"éÿy¡ ¸ 