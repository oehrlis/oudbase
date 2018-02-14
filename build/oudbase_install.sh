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

DEFAULT_OUD_DATA=$(if [ -d "/u01" ]; then echo "/u01"; else echo "${ORACLE_BASE}"; fi)
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
‹ ˆôƒZ í}]sI’˜îìóÅáéì‡sÄÅÅ¹ä,	.ñIRaÚ…HÃ]~AI;+jyM IôèÆu7Hq(nøÁ~´_ıæğ/ğƒÊı‚¿ß‹€3³ªº«ú Iš®Ièîª¬¬¬¬¬¬¬¬¬SË.?yàT©T676ıû”ÿ[©­óEbÕµZm³¶^İØ¨²Jµºñ´ú„m<4b˜Æo¸€Šç˜óA¶³³	ßE;‚$éúß÷N yşØ+yı¨crÿ×Ö7Ö°ÿ«µµµÊúôÿúZuó	«< .±ô3ïÿ…_”‘N¯Ÿ[`Åù%€¶¸İ«³Å¹ƒ=r­£gy¬ùj•½{–mzk™æÀMÛg¿dñhä¸>[~Ñê LÇ0ÏM×´<ß5<Ïdµg«ìËêF½¾êÏÏWYçÒò¿7İa÷æô14K<Õ™6ààcsì÷W|ìøæ™a³}³ï,¶ì˜^yô®äĞ»ßø‚ ¥®3„Òíå¥wÏßêö¹Ù{qÅÉß2ü°n5~àYÍË³;–E~àÙÆîÈñLéğët]kä3ßaç&üÓ7™eCÓì®Éx™á1×ôÇ6ë:=)áø¦'±9êC?zü–=¸bcÏì±3Çe¦}a¹M
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
ù+T]t_eÁIä”ãÚˆÂ½Y©âOocÃ#¤‹¨(É—UÀ#;Üy.¦Rİàf†6ÌÒ³‹×:.J¡Ø§İEUWQ–Ôwb¹¡‡·ûÌ:»qŒº‘’!ŞĞ-¬xğ}÷l•U?\³äŸÏ—y[û{/Ùó´VOiš’/7À½[´-ZtÃ;M¨iÇšrC…¦•.‰<c¸PåqÜC»†|A?S`©1Mƒ—Bâ¡›LôİÈê¥Ñ9‰ÊÂãXP+âq<»·qº§ñ‹ÄA}§â™ŠE-wv(îL³ù§³^b“gğ¨ÛÍ±ïàU9]JĞ”.ºiÉcÎ ‡ş:Ğ{ušæ<ÅS„[dòŸæ?ĞDq ¡j³Ô%Õ:M'‰»‘»CVt“Gfâô™ôfì9jÎœ1èúËæy)® % ]HİØ‘wüÌÉÕ[ —¹zß"}nWÛdBçßÒI`f}:&ûW*ë•§èÿ½^ÙÜ¬U7Ÿ²Juíéúzæÿı(é/şæ/Ÿüù“'»F—íwØï¥hÂwOş
şÔàÏ?Ãxş³7ÈæÑÑ!ÿE%şüù‘,ÿF¼ÿë'Oşôğ’1ÌÒÀğ|t ÆµüÂAGÀø·ø×“'ù†F×ÅĞÄ%Ş€‡é?DçY‘÷/xŞ¿‹äEæÓ¹m÷ÌOü§âüæşïÿõ¿ı{ü·ú(ŒöÃLÚBTÇäñ¿QÅ‡Èø__Ëâ?JÊÎ|ó'şùì7NÑI\<'`ÊÂ“ÑëD³S q
¤?ÒƒÕåHA›B˜Çø>.<»ÅçfÊÙsºL7ñ„=7ı„ê:ÂLÈ÷§ ¯|÷jŞóÉ„öäÄ%»rÆÀmWÄµº¹\®…;®üV×òKĞyĞbÛt¡ÿÈ!»«!BĞ¼~°wj†PÖ‡E¹kâ~¬«€Ÿ•!"ë’¾b(Ä¸ó ®9-›•P4ŸŒ\û¨Äë<ê‹Í¬Á@ÜlÃ`òñ/é:2é•¤Ö<@2<DÉ7ÎÉÜİÜÙ9Ùzİ9Úßİşİ§T‚,”ëÀñH‹R(EŞT*M(£ØB$7Ä¶ÖÃ¯/£ÍÁĞ¼¸Š9ğ´qy\©”A#,;”—Ã”~!AR`B»'T
€ÑpˆC@ºÑTQc5Ø-[†Ñ±+®,’Ğ´íRµ`Ï1?‰LÙRd¤l0D»¨bù?&Ï¨ö
úÅ)8 NÄòĞêõæ¥áš*è—»o%ø;Æ²ï·Í7MQŞwÀÌ¬#–²Jg°+oº6ôÏ?•V§`(q³&ääÖ±ëÏô»å¨i|"X( dXË!Á…<HÏÀ1G!·h«²Åãk›ÒÜ'¬¯ùó93×Vfï7Ğ¸ŞEÖ1}IjAt(*ª"„’	ì€ÜWfpw=—óK9a şfŸvæe\”‚|¯Œ—FàVO .ô»É)>&8h¡ÏäŞÙßjî4Thœí4ê˜Ş.-¦ğ\Ä™%X‘;iu,¹3Iè££a H¨†f˜M Á”PzH!|Â‚ÂPk=ú‚ÊÑ£	¬8rÇ ŠNè*X„ùw÷F®Ì HQù£¿ø÷ÅryéSÀ@AV-(ÒÅXˆ“|sW¼¼añràù¥ïp{‰#ÜŠ.¢·|\~÷Çãòû_®×nM%;è²É¸"°~×‹‹ËˆÇÀ²? U2²å±ç–IŠ¦ îìL O%E9&ÕÂ'†øçA×ÆÅ#f©×ó…y‘q8…’çˆ@¹µ}ØŞ:Ú?üö„<å€1¤OÉ­iÚóŒŞP`uÆ–¾8;¶—
ä“B_to””ê[v[¸üœI*Ò•ñM0°@QÌ—]Õ&(¬
ô<.Ó·8›.ä]ÔÒŒ§Åk½}7äQ#íçsÄóööı+ö<rSõèèè[Œ$HÎ=t>jïÒÑ;8ˆk~4»cB£,<%‚‚û¯·Ú-Ü·?içîî•Í;Wì£DüSÊ?¸Ï¶†SÒù‡ã”?$®ü+¯9÷q¹sĞ<úÏ,×ó•^tğŠĞKE×Dè–/ïjxÃŠ3â5ÎFæ›vëÇà?7Š·Yp5d˜+¾Ë)`	zæÜRÌ¡Ö†úâÖşau?¹¡9Xñº;É"«˜(iò¾!Q‡+ò$¼¨Ì Ç o*Ü§’¦Õ°wU-;X™zå¡ÔœutPV2Iu8s@Ùdp|ÊŸçA`:M¹7-R4ĞÆÏÎ?WIÊÜ,¾Â.Iqø¶GË‰u99²3º?+
'áˆóíı—ïé’,j%ßÊ@ŸÖ€á`6˜YÌáÈ¿
ÇP>æ/¼§'GHWÍõVóNY!G„bÌišæ[XFé0¤+":Ä\ı¥ó	š³„twéÓi^Ò‘N`÷u›V8C,Ä²‰+t‚M:í¸ğæÌ¯ğNŒSZí—Í×;Gª×M"Ã¨« H‘ÀñY«Jamr|-	ò\80…û\ö#|wkKã·ÛóÚ]ùlŞ<Füõ`~îê¤ix¾Ş“@gÔŞ£+ÿL”Ë“¤-Q~§‰H&s·Æ}Ôd@ oVæÎÏB™ª¬û”«ì=vjÂ¤Â£5YĞAğ&8P¢šÔüd&4/Šëèw(Ä®ğK I³²
±z£®ræxî‡4'8.aâ>ûëèæE ë‰p!ª³,rŒtHoÎˆR?¶e`”Q1‰İxôOÂ-§:ú/©şKğEw‰åé6Îÿ©åñ@€>ôÔcIÅH‡#Aµ4-}Å}ûø3úéÁ›3K™m¥&‘â|U¯„aYüC‘‰“ıj·O$åœŠ’óFU2şú×ºg¢|/m¤|Âèa0‘¨Ë"Q(ØöË=k ¼$LŒ(Ùa&äßhD&r:x«‚àû9'h[IÄsõ%'¶³J#Ãïë@ù${?Öª‰¡lÅ={ş¥óN-ô¢¾¼¿+ÍûœÅ`ˆ­1‚À”ŠCKÓ„z;\ˆ2¼êxöVó€ $eJ¶:1kGÏ+²t:;±ìMrhOÌN!Ác/vQL8lD³Ï£"ˆ*Ç£¸,VÅ°× 2‹U.Ó¶üæˆ¶ö¶Ò˜Ó31É¨L

†İÒ	yy1©‡”F0íŸÈÛII@Ê©ÔäÓe2Ík&áé¾ó‰gkÚDÂÓ-§Lr™îôme«™6GÕ|á(L·È;¯­›ÀĞ¯\‰°^ˆ¼;°Z
•»\ÓŠdtÆ¾(V+üıÿª®ãßŞ±Oè
èª„—R˜&|Ã›œ w<‚ Ûü&zß$U“¼[´Væ˜øğz¢cÂì\¬·(€7r¸5Ru,æl9/ı [‡ôŒÆbxØ‰«bn¬#B]LU9’V‘º¢6ıëYÁévuSi¹g¹â`©:éO8q¤›'[Xn`Å‡³ñÄ)å ‰‡ƒ‰¦é5ànR
¸D-1¾O¦ScP_àÂ1Ñ¤ Q†Ò!Àƒ®ãÎ8&ø|ùãxsûU#{ã“èªÆe‹JbÆ	Iâ;u¢¢-r›-•Ii%ı’üwy4Ç¶i".¯–ÿ¸X-I‚©¢ç»gçE4Ğ™6İP#æ´%NA±:E%Xß7t(rµ‰	O«±óÀU‚bk¤ª‡Ï“ª·”Uê²w²êÊ»|&Šª)¬pèÒĞu·ß¼¸¯L¥}Oia‹m*Ü«è õb~Rş&)¿È	yªk_>KÎÃ9%Ğ00ïÓµ§)y©‹¯åOÈûå3îİEòı„UbF—ÚÖÙJ©è"6¶‚äUW±‰KX%t›²†UJD×±‰‹ØùSñ1¦½ñObˆEFlêãŸi âŞäçŸÛÂiZ—bÆ·„mX­Äò1e"ÖtÖeÌVX pÕx™HæZ,_,w#¯êÄ?õ€Oë
ÖCŞRÛ¢óYz(ZôZ9}'iËT/wGŸ?OÃ1~2šùå}s`ÑLå”EXQ©ÌÙoTÊˆÛÀ åsry‚mï½¹Ÿ»m´Cr>İc-ğ.k Çèï‹vÙ¸	é#6,¤¿Š»^óBòıı³“£NBv|É®;ô‡Ùµ÷s(wuçe‚÷‘üqw_¾dÅàÙ•÷É%_~­„|_\‚bKñrZSú¢-Z“"R´Êû	Ed£¢E]Ø$•K@EYT"b9|ŸU\~ËÊß' 1™ß'eY›˜ŞkÙUi ïi,Ğ“ï$B,¸•›'º«A³b“êŒ>|­Ûë‹#hC6Ö ÈÍËàZÚ›ärÇR‚ÖË’ fzYõ }Wªî‡ÅÏG!ù^’ÏÕ¥Ftà‹×zîôµbê>Õ”Â"â)FÈˆ¸Ê'üÔäKò»Ää§1î×‘GC¥¥8,ØÑƒìèøm›ïIsEŞë+ULÓ2S ¶D…@'£¼+Œ½Ï"šUsg»3¥üŠÿ;:‘xË¥•Bcy)ÿ}ÊJ+äFÂÂÅ$É"OàTËcñÓ2‡R 0…Åòq­¼” åZü‚åeu$Ç¡Õ8ÍT|MJ1
ğ7Z”u4êr+áD.PzŸ|¸N½wa˜à–jªM2ğsO”ï$Ú>¬òÕ9üª=€Æçzƒ-i¤:2\ÀHy]ã·go9Ã¡c ·6µ‚èÒjœí\R¾CÓØ€Åmø^ïxXK½’…ÅºXÇòàâ}ÄóÊvØĞğ»ıU64‡á³.ÈE‹ÖJ]Š~9tÜ™N„ñhô
Œs¯@nà¡v¶ìšt1›RXáéyÅ€¾VöŒH@ã™T·Ç1»4á›ÇÙ[åC^FÇ/ó@`x0U–ç¾ø=[ä$¥æÇÖP’Üª/AlMf*`±¥-`Ö«´‰ú£œ×¿À­3Æ€‡uÆŞv ò2ôK@>¿’Oâ!(#6'ÀYh 2Ó A`,X0b}îaÅí¾A§¬Š2XpìóÓŠ¶c•,”ã¥ã^nOôÙdÎ“x`Ç!
ou?Ğ%‹#’Ò¾eaÆUèT´•ş¡äüRmœp:¨™åA…úDHhZó]ƒyŒ@Æ ^Ïµ¤^Õ%¥XtJ¾xHÿót®F¦—†í=ÀWä¡.oÿilz_Sóñ3?‚¦åáF¸â>wKw§´ÍKM•J ½/8tgÙ¶ÕpÎ‘iàbŞ¾×j%7Ên¯RPØí§¨é„é}J¡µH!¹/1¥Øz¤·¹O)´¡ØÍ<Cå™³„]ãˆ»¨„¢N'‘m]Í\¦~F³ Ôo,éÆª  &î‹”ÚE>²q—¼Mš ‰—fO·¼§ÙÄ¦œwšLÌr¢‘qA;‰_‘Ã6á(Ã\ºVÛGÁCÑAÁ`M¤ğ¼û=fm$úF³)rWŠºâJQ×\)êáÚø¦Ç€¦BÌ$S¦9ÅÖÉF|ãÈ5/,z„rx&Âfòˆ8ıâmŸÁJO¸ÑFªVB ¦ÅµÆäŠÎÓN¬° ê©Î
ùIeô"Iœ¿Ãq:â.ÓNpP`#h>Ãà³sñÅŞgá¸‡c2ı8ªx‚RƒOWÊó„§–]Oõ>ZÖó¨,Ìhb­<(•9‰îÒ~.ñPNU?[¾zR6<Mœú“tV.¥çÃ3¹.¥ààƒ@éØD`MC*š=8‰‹Ú;Æ$âHzşøLà%Í¨)b%ÇŞ@Ö5¸µ*õ€æ’Æó)GA’d	TSËócÒğI·Å%¢¥mä!ìô.·Î„DMÅa¶MÍ.;6Ä@»ã÷ùÌhDäÇlÈ$ŠH‚‘áy—h{ 
CQIµ%`¼ğ¬DXI¤‚“Ñe¯äô“Î¼mñf(;b”XXfÆöÈ3é«àF¿úİ)èäRâ)+âÛNìF<¶Ë´œ€…&tõÔ<Ö³ÅÜçI™¥ÇKÂ·ïAë˜ÿã¥V×j•jm}³R­2øQ[_{Â6+‘~æñ_»¦‹ÆL¼ÕÅ{(.¸}ÿ¯­gıÿ8©çtvğ?™¹ÿ)şs­Zş¯nlÔ²şŒ„ıØn¶vÛ¥aïê z<]_OëìøZ¤ÿ×àmÿû1Ò™èRÆ ®6Ùh¯•vn¹m_üËù_´ğµ´g¸=ë{é,mGÜ#O`Û"t…j.Ö(u`XUŠ¶AkÅQèAËÏÚ1ŒÁíu‘é•Xs€qŸÏûÚQvNëĞ4èáp„?Ææa%ûÛšˆ·*UtVq†¦oÏòÇ<´ë*»¤ï'Ø61œó†¸ïF-@î]Ç¢iò<¯ˆ¤\–Æİc» 5:¶xãˆĞ¦áÀüHàO]<¡5Š°b[°83AÛwMŒ-IFÎ´Ûìì®²ÃæÖ*ez5†#ØCÇ•‹ıË¾Õí#
VæWÒh´\¾$3xïšJ#J¹ÜŠdš,àDƒ+îN‰İ´²2^YdYåq–µº"ò4q;Û]r3Æƒ:#ï»H"<C{jÙ°4¡Ã$õ)4uB-iÜZÃE6¾Äıox5¦›A£\d÷”@)/›Î3_º–ï›6À¸ÌÜá‰ÛN1#ï•Ëdovÿå?ÿÀ
qlQTmDÊ7, 4•;4¼Ñ©éBÃ,ÌÊûŞZ†Í~kzŞU¹ã»¦ßíSı"Ô´1ğ¼'‘ºÇ¾âQÓ8:ê=°ğ^Àíñ(Ò]a0hÃcGÍC¾G“£Çãºk¡¥éãJ$²4vk‰½Å”HúJ…Ğ¹3ÆúˆEõğşDÿñÿ‘. àÛß ¸úŸÊì®q»=Ï|¡«e¯cµWWÆŠı*/V«ÅêÚIu½^û²¾ñ%><Â¨úhêrÎ¢ñ±±èò!H*¥j£™mÆk§'¦»—W“yWì_¼‡¿OÙ×Šsæó÷l"<%¬ „fĞ}Ğ†Á74–†ï_0²)ÁZŸ¿ŸXÑ,Š¡{\,ñû¦—)€ú,›…ià.ÒÁ™6dnº§İ¡Ó3§A‹ĞT…¦:È.%¶‹S	Ã=ÓxâWL¨jZR¬¼\ê^P1Ü,œÒGö\¤!Œ…À”†,ËSLA”ÆBiZ=^F¨Jª‚"§'W³ è6#ñ»hïAÃ0ºQÊM¨Xp+¶çœù¡\Ò7Äİ¡ö¦"md1î¨	¯»Âê„×¼Oeÿ¤a+(R±œ“{C	Ø>µîÑÀ¦ÔM›Ì?M®sâÇçœ&:£Ëw£‚LÂì‘Ëm«s–ùÑ …nÒàW!¬¬ì‹pg 7às”#ğ‹*XJP®xº²"F,¿ÃXğJ¨9
‘![H®<Bé^réœÒVØ²ÔSx¼.Ï…3 ™SÀ7„7ÑàœrŸ6~Ñ£#‚©aøUIŠh%6‡iöEiävX.Ú‹Ïêµµ;ÏÀ·¯è“3/üš
`‡qÎ%>»…Dá®dI-X#v•ErÙ×Ñ»-nWV¿ÊB–M!T’@”(&DR2êåš«Şl ,ï«Hæ%~—äËØ‹55iS¸…§è ”ğØÉù·x<Å`a$Ç9
Ü0Î…¶©×¼Ğa™‘po‘eßÌÙµ¢ Å·©jR·$—˜ÂJmtí¢?_XvüŞ&F˜Ï‰kêN8"Ø¯òßµSßğm1å¸kKluä4“w`9Í
–Ã[>è¯ø&«|-·•å3ºF¬Ór:¥œóM˜~8øğ§v‘ò¾œWê©9©şğÄkÏÎ¹ëøx¯W/í5`€”Y02,ŸÙGê“#ÆõF‘/Ğ8\`ªíF¿ˆkié„>Ú¬®Ér9ğNèFƒ„ï¢áˆkòx§éM¿E»Ìj9-¦[L)¬ÈéåÃ¥€`2x9(¾@IôfdV†¡çŸg-í½2Oœ¹jƒFoEx¾9bÆ™oó#}	DIMÑx°çKpXËÿó
äãáLÄıR¨¡˜øûÔÄsNl%XTˆënR¸}EÕ>î‚?ÇfŒÁ/Ü“fÄ?§Püèî .+2lá7ÃíY9~–
^5ò¥àj€
Áe!\Zòº/‡vy†âœu0¤‡¢"­›n·où&YÒr¹WA ‹iÈAMmÀ—û/¦ĞoLÕ>¹Z*´ŞÀ8öÆd¤`wˆW`U™îTC	Œî÷]:ĞfùÀÙL¼~ÚE¨¯ù¦\×™r]7°>$ÚW)l~hJÔVb%<ÜÆ•}øŒv³ÄÅ  ±ä±®;ÆÓ#«ütÚ~UXØFn•rM½Äöƒ›´K¿è6rNƒô» õ„¢Ï:¦Z§§®€yÔ‹§Nã+¯dêhè¢ëãª\­
{åÒÄº1ÖÈˆv!àºâÑ#A$¥Ld“ Ô›º§”Ë}â·DFÒ'Ö2¹hÁ¼ø2&x¤°OÑ7˜±” 7âV2>
ÃµĞ/MX…¹Ü!´Ú/Ğ²Ëï[ôD8ĞFø
Ë×Z¡J8àpigQøa`Š`T–¨A"|F¤åa€}S1˜$B¸vÕú4<bË;­r S`|½
Òã˜ğßxj˜öBøé¯p³…4'G4ğò‹i14‚H=jO¸‡Kñ”6t”¡@±K<}bèû'h¡ç·Šğ{Òz%¶ãdù ˆwŞHÿ¬’‚¾ê–EŸšWø¬âtç&iHë-k_˜h…¤¹ƒÄÉ©‰—¶pÌæ‡¡—ûbéŒÍä™iBÜÂø-”4ƒS~ßüèK¢E%ÑRÈ$ˆ˜H­XÛbNI½V
W£<×İ Fdï-;8V¸ÇSèÇ	h~â¢°¥¬ù¬8%õr--”‚Êí€SÙŠ¶ åmø
‘O’§Äv~Õtå²C“F´=½Âí)¶,¶^ÌtG§:Éª¶ÁE"YOtÚ<|<@—öÉ)&ÌS3&ùDQÏ&d½]&ªVí¢«l±ÛsNƒ(øµ@%¶:Á(J‰{N¥]–Wdéá`ì²¡>Ş§jÕ\b¯¥ÍñÊU•*!Jz1cReª«“‘œˆ*,RœÊù“”	Mu[ÎSFµ<ôš×51¡˜BCº%ŒfqÒ6ñ ¬Õã¶/¿+¨4Q³{¨’JNt›à¶!®ìê€²tØ8n SV{Œ,©’;>®“„Ò_ì‚´CR!é‰p(Çh8ºåàm¬LGì¶+ÛZ6Ó[-E(4±PKÃó*UKè);zÆäVëCˆ U*#á@¥È/* xæ•âµR=cr¥Ú]²S)ÎaUÀnS«‚<´ç˜Ô¾;U*X!©Ì~YŸa“–X;­í—ÄL¸‰7¶Ğ!r}ÎİÑS,r³ §fWE:.Ëi€õC Ê¯TÙ¹NoÜõËgÃËj­T+UKk¥
vg¯m¾Õš6išDµ
j¥5BR §äv÷o–¿ë}¨–¾,UNªëë‘2¿Åk7IHÉ]¶@h¦{j®uJµT	°íÇ,EBkHmêŠXí§ô«¸ú9‰&M]b;‘®ÁãKVÂ µ¿ÛÜŞK ñÄÑ†K–XËï†Azú$ÕJù8C’:VÂQªèn²„g€ã­>g¾?ÊRèè—Wè4ÙNÂ*J–b„CWyŒ£«„–™¶"WjO& Ô8-òÊÓ+I®¨¶;Îl5Ó"àM¨ğšó©éYÒvàØ&:¹Ø(8Q›?u.LÒµ“õlÁ|ôæÛéÀ	±×6ŠUÜQ¡^¤‰yı&6Àr)b({|ã,ùMiü¸3$[%Ğå@;.¦PmE§òÒz\£óU±Ã\¢ş„o¢~­&-8l„°ßj h ¸$@¡ef:¸Hx¸$pQ{Ît ‘ rI@‹Ñ$`¢“('ò*Ú{¬§D1®Dp3)ÚÊ3÷ñGJÏKQ×}ãäÖ:\÷Ë[àW5~Ày$dtÖMn#UûTÄÄ¦UvÇº/´Ëro^ßäfd¤'¸Œn?~á!y®¢1ñ-~LÃ³`ñÈmW4ş´‰ŠÃ&«½!îïÕjl<,QÚ â¯=SÿNv+€—R%Ö¤.éb¢É7Œ$QeøŒh=„ë½î9v\°]Üˆ"¥ŸM\‚ æŒ@ùÉşf
0şm6˜Â'Ûû
`»“¿ÍZeCéşî²¸_iœ›E|-œ›ÃáAÒWk§PÁ¬'BPr÷¿ÄîÂˆºñÂrR!â7¼ãÇ“W7n²´
ÂPÑÆ†§—PÁãË+5<fA0CÄÆâ[CìC1PFÌŞgÒè*M–	×MZv’1	«›­ÅîwîWLÕ2—èVnÛDÍ
ğlÖ¼ThÂ¶4Å"a)ÍİBáµ‡04….ğá•ãå-04./¨ëÙ¶çaš.Ä*´Õ:>Çá‚+´øö‘ÿ[ŞÒ¿»‘à¢RR‘¹h” !ß½‚Ç§K¸s2t–ù`ºï—û¾?òêå2"Z:§L@ça™ä!¨¥eĞ8Ç~‘JyåB=—[aïÚÉQöœóB(
 Çì»Ë“Teµ€Å½ñéĞâ‘Áèí-Ê—¡P·cuq{/z¥i
·Qø«ÛäĞÕÁeÊÌ«LºÖJ•ûÖƒH¹bÎ)mĞ¡£+ÙÅ¢3|ö5¢Ø]^^–XrÜó²¨Î+ïloµ÷:í" }ºùç>õy:é<t3ÿ¬m®mVª›5:ÿùôivşó1ö?m~ÉMÌ¨còùOøı”ú­º¶Q]«<…ş_‡ÿ²óŸ’şâoşòÉŸ?y²ktÙ~‡ı^jøîÉ_ÁŸüùüÁçÿ=ÈæÑÑ¡ø‰%ş'üùëH–?ßÿ-L%<j–ğšl´yb¨Ü…ƒf4şùü·ı÷ÿ÷ïîÕÎ,%¦ˆ?ëƒÔ1eüoÖ66#ãm3ÿ“~[|åä˜9Û:cÆğ·{u¶ø €ƒ£êÍW«ìÅØë-Œ–íŒHïş%ëİzùE«S€2Ã<Çóªx…œšbíÙ*û²ºQc¯†ïŸºãóóUÖü{ÓÅãç€6šVK<ÕUÇ!øÔû°&Ÿ:¾y†›k¤S³eXQĞëŞ•¸ı_ uo(İîY~PzqÄèw6zqÅ; …~á¥„øg94/,T¶cYäM¯;—¾®ĞÒÿ•V]´‡’æªÃ/“4AKx$šãÃT NÖ)áŒÇIa!0¸
÷ÉÔŠp)…Vá÷Ÿ¨‘gÀh˜`Ô'óîc ûÆÂ£YWux¬>+U6KµJõ)4d=A7ÁŒ`0w(†…U\Ïïs+Û7>òxÓ<l¼Áñæ¸Œ¿Ö©6–Ç¿9î×/Ëì]$üÙ{¶$sv{ı†2ürÚP\ÇÃ×-ğä,€¬ÓÄ°¤J†n4CôæL%o?1¯’a·­ÂœÎiˆ²†Ìèjè:ùJ7Âk‚‚×D#º°0¥V˜Ô¼¼zÖörB¿š­EÊşrkû0è½`ÃùFì&{±€°
€öïÉê@låÆ à‘2Y¡Efd~¾ÊNŸ€¯_x¥Ñ2r÷¸£E
úã‚ôãÕ÷%úY$ß^z Öåç¹â;êå6¹Ô»ÙsL^ˆÁ‹/ZtÜ!Œâ¨ˆv6‹áå×tßƒ0ÕÁ€\êö"wş._ô5¯å¼ò}™â9°J-”x.x«åÂÏo!WÍ
ğqzË¤f
†ƒ’»;97ka~ÉˆØ
¸Ó$pZ&…øHq>j,±’ƒ—NŸ¿U1ËoğEšTå+hÿF¦İÙiµ[l #fÂO”&ÈTj,á‡+­ swã6Œ±ï’Áœß]`à»Á+¿J‚æDvã‹+´["6«U‚<!ƒ> Œo%¹Å6*“{¸Ì·–ÂâæíŠÓ&’RÜ5G· lë„P¼ÛÁw$ˆËi,]X±À°¾qjL,1)Õ~h,iÛDÅ¢Ü#b$'ğ	^’V·T‹Eß™İ ÊEØ½ÖËwíFè«µK`İ¼ø.	HI6cUL¼ñğó"‡¡á^I´zŒÈ`›ù3Ñ÷ª‹„]éb‘¼^o·„[ƒx¡”ü€' …œ/”Æ,.ËŸ…ÉÍYú™ë ©ö_uãnuÌnÿ]«­?]g•êÆÆÚffÿy”ô·ÿÚÂşû¯ÿ¼µp¯vf)1…öß‡ıSÇms36ş×²øŸ“2ûïçµÿª£î§iV=‡&Xƒ£¦`Õİ73ß…»9x&åç3Àá]Qä‰†üFîcs'ÄıÌˆ–RZÑmMÊÿ0~ÑÃÍ1ÓôÿµÚfôş‡ÍõlşŒÄã+a>€}QWYäR1œ»ğCM| X0Bñåšò²¼]o›do7ÄÛCÅœÀ¿İjX0–ãşğõêÚ—ÏêÕ§kOëëê_>ûòYf'˜5%‡9›oÓÆ%vÿÇúÆÆÓlü?FÂ u]GåÖ÷¿T7Ö×3ÿÏÇH¯ğ¡ë¸Kÿolfıÿ)ŒØ÷puÌÚÿµÚ0À:İÿRÉÆÿ£¤H”Ğ©ãöãm³šİÿô(I×ú0uÌŞÿµÍ5êÿlü?JŠ…ã}€:n?ş×«Ùüÿ8)%bï\ë¨L^ÿU+Uáÿ¿¾ñt£†ıêfÿy”´Àô¸ä¹öJÜÖ„'´{ì,8ñ,C.ÿ‰3ŒÛî8ş«RøRDB~íq—Ê.¹TªæxºEo…ğÒ†s×z¹¿ÿ®/R¸–Rà,(^µW¹H>wïxÒÁÍƒIG/¿Nˆ ¹ ü±£o9z²+å”¸Ñ“gv³Ÿ[J¾?`¾uÜ~ş‡Y ;ÿû()õşˆ9Ö1eş‡õÿf-;ÿ÷()súxl§­—Çi¹÷#÷Dœ5„?Äc{\TKÕÊ£z\$^c„âU½Á/ošœQ\l4=£¸ï3^“ş‰W	»06èahÑuhÎzâØØ Ïú~V*r7™â÷3MI×1Í»)óÿÚzlş_ú4óÿ~””ÍÿÙü?«—'ˆïœSîß™Í÷

ó†wišWìlŒñxmçŒ®rÇ6rSbç[9Hâglş«ùÄµÉêGìJFVôÙË×;;x}1|øäî¥nŸ=ÜŞ+³£+níù/«¹ _ÏÀ¥–İu)ŸñùˆXY­­®­®¯n¬>½9·÷¶Û»í½£æ…ªÂôúx”¬Õˆ’+³Ò/¸ôvûÜóğçJS®ëœKÓô¿xû¿ë<şß&íÿeúßÃ§¹XtíÕ4´mût.ßÓTâÈqu8c¡¨øŒÚÖzLQÑÎ@A‰_Wùm­”¤³­êê† hlªF&AT6K@‹ˆ`wÌ£¨d2OµTÁ/Š&¿¼F1¼´:»Œ_uù_{@i½6ï
pvı3mŠ{K-4TÑŞd9íTNxµ¢”!
†¨¢Ç@˜~‘Š-<Ş¡`òP:[½²³[(±&¿Á/m\eç®38îíiPÂ›FxEÙ©y†÷şéBwË/å´ÜâŞoå¤ºöİ÷ÖÅù€_Ú‚Î²¢™âßr¤‚6§.Áç%*Hîí"¤ò‚ Ì=ïÍ¾@âÏZKOŸVM÷cU¨âÆá‰ÀiwĞÎèö„ Às”rØ±>_C Ó‡Áø¬<ÃuÄ¦XF@²ÄJÂ5)ş3“¨”`Å¡gköhÃÃd;—xnŒı9â{‡à}N‰/Şx»Óá‚@ÙÈ½5lßkØ¦÷ø– ŸÎM?×Ä[+£/YîËïsGW#³Áo$Íáş}C\dÿ
`ÃWNçŞBqdÁ(^|_Æa‹nßÁwO^ÄSFO„¨j4»Äs·/[&¶{kî8çVw®90gtX§Ï©à /»g¸½ı±?ûàJ´¯„yOÔÅ5wc8øV«äüÜsúmRê-ğs¬cŠş‡î~ÿ_t'Üÿ[ËÎ<Jz×Ş{µ½×~Ÿ;¤ÛŞAP‘yG^o€ÂÿË½{ÕŞkno½ÏuÚ[¯·¾=y}Ğjµ;'o¶›'»ßò°S×º¥qf¼ùz‘eé!’>şAd¢|C¯«9Ö1müÃÛpü¯Qü‡§›kÙøŒdÙ¦ó÷	ôylî$~r89œœkZÀçÆ>K÷M‘ñ?îW7ÍÍ4Õş³±Ø6Ö1ş÷æÓµÌÿçQRfÿQí?IüŸ™€ÁŞ7ú¬ğ(Zà#˜’Øàa-@ÉŒ÷F jº‡h&èw4¥Â£LøÉXƒÔØkR< ûí½Vç$¸»‘O¾ìºœ×?ÕÈÅİgÊà>ÜÔSìaPŸ[€¤jê™RÒEšxãE]“³¶’lú±š†"çyH•dí¾˜KSı¿×Ö"ş_›•,şß£¤Ì_+ŠvÔ_K?Zç­àÂHİuTsRŞl’À¿Ò‚>ı\=ºr= a¯Û òùçÈ‡«ğà¸ç¹^·Î‚—9ç÷ºx NqÏÛú\âõ/0“pˆ]»As§·š»9øçxñHMİÁ–cã%˜¦@>0˜¨S!óÏ·‚ü¹ES–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYJIÿª*x ¸ 