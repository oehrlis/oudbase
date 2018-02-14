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
‹ Ê„Z í½Ms#I² V»Ú§µ‡Ó®+³µµUÈ5Ä'Éb7ºQ3(UÍ~=‚Õ=ıªjø’@’Ì. ‰ÉLÅfqL™é(]u“éè Ÿ²¿`M÷½èÈİã##2#YU=È™î&2#<<"<<<<üãÄ”Ÿ<ğS©T6Ö×ı÷ÿo¥¶Æÿ+V]­­U+•Õ|¨T«ëkÏ°õ‡FŸQ9 úîØrPìôtÌwÑõß/ä9ù÷Gİcè^4
Káù´1~şkkëÏj8ÿÕÚúêjemæmµºñ„U —Ôów>ÿ¿)#	œ8áyng÷ ´Åín-ÎìQà]8]/dÍW+ìÅ(ôn²-÷ÂíùÃ¾;ˆØoY{4úAÄ–_lµP§í¸gnàza8aè²Ú7+ìëêz½ê9QtŒÎÎVXûÒ‹~qƒ3èÎé=§ï–øSgÆ‚ƒÍQtîâc;rOÛwÏƒÇ–}7,°Ş•|z÷‡H@©ã÷¡v«ëEªöâF›çÎàÌí¾¸âÃ¿åDqÛzüÀ‹º^èùƒTù;C?t9¤@3¬İ	¼aÄ"Ÿ¹ğŸs—yèÚ ã2ŞCæ„,p£Ñ€uü®‹#áGn(±9:‡y9ø«ïxƒŞ…n—ús^àhRarÎıQÄ~Ø*BÓğ‰ğ>…i…ÖØyÃz¹|%G'8:e>b!²8 qwæÓ
ÃÃ¾ªòƒ«:ü¬TK•oJµJõc8
cÛ/òœ»pF(S­•ªU,³!Ë4»?Â1btá/,ì˜Š”-=Àâ,²MhÔï{¿8 vè9÷-¶ı×[Ç‡ûûGÇ[{ÅkíW½˜²‰Îpé•üà,C´]ìãıñÈ¸-X#£^Ä~pz#7¼G‡r?´ÛÛû{˜ÍÜÖ~óà µ·ÕÈ¾nåÙ”ÏĞ®sÒsYÏ?c§üá‡.0€ıb¿İjä_6wÚw€´qKõq5µ7·÷š»­Æâ2Rø ø[¬rG»Ç[Û‡­Í£ıÃŸùrÔæéåËíh}ñÚ(pS6«—ó¹öQóğèøûVs«uØÈÓ/dOL5LÛâµÖú[şS8¼ÃwS 5ËŸæs»ÍíæÖÖa«İn MÿÁX¥Îy®ux¸Ø¨ätŠ¸ÿLrp/GƒÕ}ˆƒ›íê;x±×¡sæ.Øu’·nyá°ç\ñ3nÉIQ!5½ÚòwÃ3–ßŞ{¹Ïê¼á•ä$¿)_¬è±ïpuoïMìm¶³âûÄˆîÖüı3ÿû Vû¥t_ñ?gïl0V<·;5Î–#Üú°¹Ã¯Œê¶ê–•’Q=°Uïœ»÷´ıî°çuˆ/e Ğú?’|/|ë¬3hlyÛÁM‚í:èMÎ:t/àŠWÄK2j§¦x›ß’mõvü3bO°Á_ïì¿BîpÃËy§ì¼¬Ş°âYÄ*ìİ·¸¿r²››=×4İy/·x]»¡ÏnöZY.Áñìõ+ŒŞŸz¹›ÜÌ÷:ëÒÚå„ÅyTäõI`éj©Ó¨/r×ÔÏí½ƒ×G°IV¿ª?½±!= ë:ï]’mp‹apÆN\øO—mø59º±Ëˆdæ°2YÜO"p`¾+675'yøÁòÆ¶w[Ç@G»°±tA,aùß}õSñ«~ñ«îñWß×¿Ú­ÕÎ¾ıV«zx˜]u0¡2í.Pûíîÿ	[5ÚÍçõOùw£@ÉòÈJnètâ§)ø&ÏLˆÉÅ ‹Jqa\Yj£sîcù' \Dyö1r]Vt´õ¨jëj<U–”ü3<÷N#õëò×=aÍşğ%\»¾ÑÄm{£•x9±wÖgÕzšîm×¸iŞ4Ãi{şÜÖ§ÏlôíHN?xÁŸ‹Ô7ŠX’uS6îŒñƒ=€p4iã³ObôK®";VÅ+µç"w…6%=ëìªª
Å[ĞM¶	R.±áH|Æœ¾?$îg#<"‡%Ö†Å5¢mÙ{ÇPî`0{%½‰Ú´MHÀl·öÂ´ğ×'Â×¥€Ä@ÒøMjˆÛ!š/n4?››;-%İ¿h¶=±UªFí„nD€—Î…ãõPz4úS­N‚¼éz]‚ù£Î9?ña¿Œa¿˜ïtÙÛÅëï÷<Ê%‰¤nubÛ>ìö-~8?…¹]½şÚÄú­ €Btº$E˜Õ'ö†W§ÙFƒÊ/B'Ôñû}g`‚«İ\7ÔDt+ÔÕIPw½0$É*-eë=m%(ÇM j€š‚
—³Äï¡?=WôÚ„7pPKD-	ƒØÖ§OXh‡Úâ²NtÅh°£ã‘>î¨âÈXŸåDõ2ü*Cùê#÷ğgŸ²4ü¿ù¦8©ü•d—Î`à°ä÷s§×óeúû‰lçõàıÀ¿ğ®gÈ{E,,%7)æoâtèöı«]¨ùšWUcá$è kÏË]÷¢<õzúæŒğÌ	õØşËÙh0¸2Dh"ï¯ïhœç"å(VÁUNŠ.²]L±…ø)KrºÔÈ—l¥Ò"q¬¬UÕ¹òÔc,§p‡†ú´ãd£Ë>~„/¿aÅnâ³ Ñjµ­a[;8(¸œ4Ev®Ä—O‘ÛÄ[O‘ônJÙ[H®:ÖÂÙ;Bâ<'í9!Ë¡Bş”‹NÓå™
^‚õ—Ïñ}*ªäĞïa-üåöÛßâ4]²¼¦#0ºŸĞ’æÔŒ˜ãRÕÔÎ¦ìHœãÇ©&$ËÁí:Ş½tÜõG3dy£ck•<¥s9Á`Ô5İ)p> €HFÁ¹„ÚÍeHUR§«Ë”¼.{áz;s#dkÖ>.?ÜĞÄnØÃ:C„z'~îµÙù…Wßªÿ\oÕ”öÔñƒ²ğFd.¹f®¢1İ‹BBÖ¾y¶{¥2’éşÍ+c¯ÚÂr\–QâgYBWe”
ì°u°³½Ù<B%~
«VÁ¤J;”ßËÎÖØâS}£ ³âfÿg¤x\bK[L,J£ú¾›+ÌöÌÓ+‹ÛzÎ%òlÑ-¸{ÎÔJ†UıÛjq=ûâï¡­s*˜‹› lÄß¬Géµ*o;c·ÎRC€e¨S’ÃØ7¾1,&ŞAÇ¬”#‚±ña?16ãøÚ$.]®,“¤¾œ"Yşg½˜·j{orê•Õô— `ñúàÇ-Ñ‘>L¿[dºü¸]hm5=9bL1£ÌË&¤¿$çDÉb‘_ÛOÏzº‚7¿¨?ŒèïƒÀºAä¹!b
¯øÅÙÚôùk½OÌÚQ( 6¨Ÿ›D5…c·8ê·§òµªQ\Ğˆ#®m	â;àÌNş-Çá÷áxé‡÷ÙE-…å¿,–‹å%¡ÖÏ>lN/œÎ{(Ë¶·¸Jº?êEŞoÑÀA(ï+œ"÷C„bôbùzïÛ°üvPfåoo2`;‡¡ø/¢T]h}R­$èé€oBÆbã×âr¥ípªAÂkës²|ç
À¦Ã–REÄÕ£Û5Ú.H¢ÍKŒ¶ÓJ/“‡U’â–˜àdø@v.dªŸøA,‡GR;[ÍúW[m¤æÈp¶b·xí‰óBóÇ?ïãİÀ²sù-½h½ÚŞ»>l7òoÅ·pBzIæ¿İ~µ·ØÚ„Í¡Qı–hëxSecå¿4»İ æ Œ|u±†¯Ş~·„­,½}^f×Ğ©åÅUşºÅ»ïNå[vƒ××t$¡wæŒ³áj¬:%Î›+fg½š’å'OQzšª4JRœ7·amÃÏÒzüáøû¼ùìÌlvHÀi«š€EC‡óeX1š!´Ì®~SÇ3ı>…Ğ¬u'îS¤/[<Ø¾¹µ»½§o=™»˜Óí{ƒ)¶±ôŞe«Ì=ÌèRÖ´ZÕÖw˜Õµš¹ñ‰Ùå<´y$–BğGmiàz¨ç¿„{ÃÊ†]Ğ¤õö›¿­ï¡"¨‡K@ÒúzÍJì·#ğÚø«ëõšAºØ?ójZGgq~,~j‹Oó'
ÔÓa³×«ÍÚ
x¼ıïüUÙWUY¥º¾º:·ÿ}”çK·ÿİœNì¹`gá®.	˜¡Ÿ£é¯¾Ö¾dûß„í.í:!Ãî1Ñ=ù%d<áÖÒT¡	k`aRûY™ôV«¥je‚Iï,xÓ\©nÄjâ"·	ırLqÒ÷VànmŒ;ØYÔ'!Y,	ïå?í¸ÀuP•û5Aã!.°—¨øûëÈéy§¬I±±…YšôJÃİÍı½—Û¯HôaVeäœÈ«8K‘{éx«õ²ùzçè˜^å?ocßÇ±?|ÓŞ¤a±°6¼»µ¯sñşsÂ¾·»È8¿cvÔ7ITYüMñÿğ¢¹ù§×âu¾j/û¨ú©zõr÷ÇøõÏì»?6hŠ6x·±:æÅö¸pãcşLo‚ìdáL
ıBğ^‡ø–{Vb%ÖåØYKâïŒ³§· ½gJk]B)ªë[Z •ønooaÜÓUºp." „ ®=ÕÇÌ}I5	´‹ahh/w+y»¨u¬PÊ€ŞåĞ·šGMt|o…^UªxÔT¶BÌGÕÆ¥½K´|‡£qGíÆàv…¡Ûá~ƒôy°ÖÙY4*A"Sæp=AèŸF—¨h¹}óH`Ş€9¬ëwŞ»hâ5ˆo ­dŒ¢eeKX¤O»"MKNœÎûÑ04¦KŒw™ËZpVö2¶-yjoM}Íj0ÁŠ!5<;G+K½x‰fcÊ(ÃŠíÂ‘%³aÃK4ürD[ó®×íö\šl•¬å0±iƒ©šÄ¡Ş[›	]'@Ó7‚Ÿam İ¢åé}¦²Ñœ­sÂƒÙ¾~Ö¾	|¸[/·ÿÜV›ŸèÖu«XÈî©p'?–WrğTnX!é°0	FÚo!	Ez.Ü“ı?±LLOZ÷këiâì`kë9@ÌÄıaîü`éíÜùásu~x|‡wÁüç¾÷ô}X_Zœ÷S§,’Q¦mèáÜj!o‘R}uBGĞÒíè°#ÌÚä¶Ğá İ‡
¶Xè ‘mé.>Àu"rP’:õíP–mí$®æ8ŞÎ÷ }mmhthÚŒ<Z>…‘şc&EWìyÂsxtôŞV§¹ÙÉ(‚1`ô×ªTÓ#G'T÷’
¥Ñ:™¦kößÓN^ ˆHxËı+µççP7T·Nd=õOÜ $4Bª^x®)ÛÉp/$=8¾„?Jg¿äÚÚ>¦>å¿Âæ_îïììÿØ>>.³kà|pî½Cö;Vı–S'Zè,Q´"£­Jâò¨._O¤“ßÙŞkµ¡™Ë+öØw‹±Ş¿0kÛõÛ›§suhU--UÃ”§‡†~¼cÑ9Ìé{oÈ½ï¨DZ¶]AšaR÷o¨éEğ1f˜•³‚wNê~½[÷êıú‹z«~Zÿ¹>ÉŞbŸmï'òãƒÃ}¾èÌ'Fj­cMebµp÷µ¢b±–ëšåpk°–óÌr†vÍZáE¥ú³ÿ9.®HÖ‚ıÔd=M•z2kñiLş'ük6á–‰B!FøH*›DK1›ot•å‹'ù¤õ¹­%Í[Iú$Ù[Ê^G5f¯sëæõ¶SnSÄøS(Ná>E†ë©
÷Eé
äD±läÖ˜¥‚@“ ëê`ø>äà>€F×~¼£~˜ö9„Ô‘ëßq3&WO,Ğéy(Ã›àsòjÕàxIQñ¼ì“º8¯bti…¬D@èŒ7¥ó½L.Å™Ò3i¶ èáF#vÛªfÄé—¹o!L0…šQ¡  wß’>Dé5Œ|;t!—b é¹OáÄ)ÈèNFÕŞiÎ+ËÅ7y¬YÁ„o|Ká˜ğ¢OM­ÉÑüz&oÎT\69aê‹eŞÔ7³õß×fD^”Oû—ÕZ©Vª–VK•$aSÍaã[a“7©¥}c3¹5ªv
ùÅ†‹üFø´jµvi¿4)9Êx¹’&gùÓ­„o¸	ájôş¸İdX‡®8‹Ã`œ­è³bt5	Zø¬ÒMO‘ËÀÏ¡4+VÚqà#Cş•ëdfˆ¥ëõ¼¿ëÔ;%ëğSOÕ
Ó¤$c¨Õ[äŒš·8ò™³‚ÜÖëM´~ÍÏKê*ÄÇku±qĞ †xƒ§ùÃK¾/$`ø‡³‘”w_“¨‹%O}8o_â/Y–va'<ÌÊúş©ÓoîRU¤ŞB±nÉV4–òøŞVŞàPZyã½1ÅZˆ©÷C@7›–!À÷Uä¢MV‘ï“ÕâTs$Ôûd…ø0hVˆßç‘~È­ëK§ã F±øAÍ9…3³œÉX¢qÉ)a¹™Dsl(ÁüuÂK×aàğjJ¦Ä{Ò)•
E­£M¡sQÇˆ8p§¢˜Ø[?)\kÛ•uõj–ká¶=ÿL/,‘°v£NjuëàÕ¶9ª*ƒÀ(g2ÆÎ[ã†bñZIIcš.’Ø‚­L!«ÁÇnÔQ¹ÿ&¶„òªHjÀPğ¶’Î–¦™õğªì£ÅÓ»Q§1.Š }Ê©Ç:CAğüPâªHå}”v¦Æ_à5Ò¦åä6k-:ÆùG…€pCŒ¿"i7hsCIãæDÎõâµnEyc\„ÉV¬Ê‹õ&ÌŠ ”|øw)t.\óö°3Ì†ŸõÀ$ïúhzMZ"8‡Ğèâv;ßJªh¡1PÃqk]ÍãÔÚ'¬	r‘ãõ@a¿ãZ##²X€?ürÁŠE÷C§7êº|éøi±â¦µ]$©ÀE«oÀÀ­ éS©x6›Y7’É(1
°îi¦ÄJPó7¬ÓÏf^5“’Ë8ãöÕŞo	¨/Ÿªt'â¸—·4¾{)H±g²ÇÇzm+Úısr-°vÄÃ$ñ»±n¢oìIáÇdØi™*ıd´ôk[iMh´~!ÇúE‰LæW%)‚—l#/ôØ7VñüF³Šìø÷|ù;	góuûhwûŸÉ_øyÙªl˜bÜ¬;¿‡#½¥µ6Öz^ÖÛ)¨t¹«ÅªÈÿä¥*<Šù˜jäLgçT\%İh8=FJ+m/Ÿ¶1£,)9ü‹fòn˜LÀöµĞXtt]š.šÔ’N+ìùó¼Ø„˜S&”IÀ¦
Oµ45°ŒVVœ&ÃÉSóvÀ¤Õ¹tÔ“Qm(vêİ¯1˜İÔ`·5˜Rõ:áëÂœç„ãÉF5È(–MÃú³ô¸İıQĞ¡Ğdz³;usbß,PÀJf„^Î`‡qš¼Â[VÓW3l E—e·¨Lêh›n`dQ°t>Ó22½Ê$v¥—™5²XYŠxI²â-9‚Y®ş"ñsÉµŒ•¤ºİ
ÓV9ë…&“©İ
"‡´!Dñ2U&ûœ0’/§\Uï&Nx¬9¸’¤é¹ô@D<')B¨yÄ9ŠCqù1¬¯ÊüÑ?ı£ÜqØóD{Fò1¡æH9©©zh´VĞÒr\}•!ùÎ„¤¢êºwávÇW×n‡´U“®‘Á*bJ¾í`›púxFÑå˜
F|¢<ïì<²º7Y‚J óóşQ«€Kö‘+`—d®Ğ9wp²htÔTö`môùÄFTR&P"Ó=D,JÁÜ§Q0ğ‘ùÿ¸jò“äÿ[]«Pş?økc½V©Pş¿Juÿã1/=şÇ›ÿO-¸/6şG"ÿŸ¸Ü@•Ï®‡è
í©ÿ¾.Áÿ(õ_u5YÑDtî¢jK6" î'|KY=¼ÛøœÓ~1Hîd¦™ oğQsø}ÖQ=~5A=Ø}ƒz\¤<éÛÏÉ×]›ax5}Ê¾ûäë›>RFçàlHl†§¶+¿Ù=U{/EDN{õy¼GõCgóyóyl#oî&>w,ò³qÇ¬|jÌ37¾¹—ø'sŞş•æª›Q·¹Ãòpó¼^ÓD^/(ÚÚû¡11‹Wv0Ş Öæ©½îAµ3v¾‹4{0çä~İ«·(M×cäèjg¤ÕêCAM´¸¬ÜæDÙ¨ºËoWÊoYùL?~Ì6¿×LòwıêS<	¶—˜[«Lª§éR”Î^%‹œ«^$Q1¡„Ñvå®PæĞb65c<LN„éiÜØVÃ†ï®Òñ¨ù¢‘nÈR†ãxg»Î[<ãĞ[úËÂS)‡?vF`^…Í¡^HïEb~lî±”u"OƒBƒ÷ÖÒ÷8/Aö@·Ôâ¿Õ}CbÚÔ¸Öh ²ÅÅ‰ÏR±¹=!+ÁJ¡¦{ãŞÄ@Ì¡Í±ècÀÜW¥§oËo—áß…·ˆEéébùmµ¼Tˆ»¦¢2,8^Ëğòònƒ³ÆK¥q†›CÖ¢YSäÒøÇ.±†è€°¥•%ÿ+¶ğL°ÒxÃ$&È
<v´¡×7÷í@ N:cá¹’Ó!N“Ğò<©?d>¦Ò2oã°:ŞCbu•m[«œ‘ÁêÍ¢¬ô.æ ‹1 P¥<Ö‰ËCsİSö‘¹r¹åù«ô”Ñ~pVòñr$,…”ÿ«(·¤¸-O
Æ+;Z»óÊ’+Ì‚½AË1¤ÑpEZ‰i2[)&Q_Y¥;ùÙ”òâ¤¼—Zzq”ŸxÏ¾T2©ÍŸ))ÑÖö¡©—0ĞÊî1Hä6…ãËíÑå·|
Ê‚QÚ`/âåq(Ä í,ã2+ÊÒb~<\€Á¡ïGœ›vëÈQWjHä s/½yS?é9ƒ÷õwï–
)$€Å+ÅlöF‡Y0ÕArøyÀÌ707“ñ†M±Æe™¥òÛüÊÛ|9¢¼t—(Ã¯‚©eãËhŸûğğK$÷ãÅk97Ç
µ.Ğë ³§—‡/Ò¸CLsÜöVÜë„^PÖæşîne}q ÚŞ»)sˆÅ^s±xî‡u‚lığ×T³¦JğhC½şô±ÇrˆŠ ”XÙŒÑ<Şr®„Æ|éw_–à¼¦_ØÈAJŒ`ê3¦ú2çûJ®4|¨z&«xÊ4`|Zy6°´ösQA Jú"*Ñ=!qèİkMK8B=Ã/…!9”sËâßEùÁÌ¡øØ X1”6Æ-%eæÏ#áÄG4”şµ|$——éßU&°ªÏ³§}úq	G<ÙÂ1ûJ„s»Iõ{<ñ†¶ı;V×¿¬€ø)»O6À'.††ÇHn·”WÊ-kâb¹˜$¢[¤KÒîˆÌ]ùœóq/ÌµJE?ş§&—P¦B	½nbNirñˆ$ŒfuÂlüŸY>¶Ç~¤ı'w§ş$öŸë«ë«Êş³ººöŸµµõ¹ıçc<sûÏOdÿ©Ü¯ÅşSdø»µÿ|V‚ÿO°ÿü¦TÙ0Êì:?ã-!5%z²®‘@‹ÜdFİÒwRzNïç¥YĞ¾ƒÒJ©úp	ínaSÊ>w³Ò£Ÿ°G¯wv¦OÑÇ„]Í™ˆrt5tsjµk·#€íñ ÂĞ½]÷=-Ö÷®;Ì¯¢é`#_,Ê¿§Às.õã*ìeÏ9›[Ğ~É´ûIõ×oK«:ªm…1\¨h­²½·yØÚmí5wæ6¹w ÚÏÊ&7™jn“Ë+Ïmrç6¹Öw³Ò¹MîÜ&×n“;•IîÜ(wn”{7£\!Û¥rçÆ´cÀÍiçÆ´_”1íg“kèái#JğÓz3Ú ¤¦²£>†‘íLÌbçV£s«Ñ¹Õè¯ÑjT\ÏMi5*bò‰J˜ñCmıÈæø¶¯+øLe t»³ÓC­¸öSÛñŒBy3’h	Ö	Q9êùlgäÒuß‹\~¹½ÖÇ?¶ZÚÛ×t.¯ó…ÜşÎVüÎ qÁ›ââ5Ş Ü
T]ÄKn·€òx£ÇĞ(TbF-ö%¨"šéaã*Ç(X*›S´•ê3NuÔDÂ	Å‹¸á›ÉÀğjvÅQp&nVdC‚lvin=ÌîkÇio~¶–Èp)‹dÂ¬ëv½|èjô‹.¦­² $2ÊLQíƒÂ­Y5®ã¿~L-x\DC6[VôxòæM˜˜Jft£§€Ó‡ifvñÚÄE«”ú4¥¹¨n*Êls'ë,r“gPÓ8ÆfZ-‚¥¬J™~éœN3Feİ—Ã,Eg¿ğc¦9ÀÀö^OèZgh"/ÀÃ[ô-Yu`!u-‘&¡@×Ê™†j¿»}d›êç¨‹zù“›ùfÁşÕÃuHWêò¥àxh&“|7ôºYãleaq,F+aq<½µq¶¥ñë¢¾…QñTÅ¢•;O6&Néü³IÏÚå)ì…âvsù˜¬ã@ÚÒÅ4-…Ìïu)F¬3`(kĞ6o±Ï`n‰Í’ı¸¥‹‡\”4técš¶¤XgÈ$i3ò ÏŠ}e& N¾™ÉîÆ¯wáÔ¬¿ì•Ò’éBæÅøsV¦Ş½¹©÷-OmjûY>hü[:VjÖic¼ıw¥²Vy†ößk•Zuã«TWŸ­­Íí¿åù‡ÿğoŸüë'OvÛo³?KÖ„ïü#üSƒşü¿ÿÕ?ÈæÑÑ!ÿ‹jüğÏÿ(òß‰÷ÿîÉ“ÿrxÉ{n	ƒ›£0åÚÆ¿Á=yòŸ±\ßé¸ºxÄë¹tísˆÆ³¢ì?ğ²ÿ)Qm˜Ozîö ë~xòä*şÿŒ¥ÿ÷ÿõû÷øßê£Úçù™¨ñë½Š?ëmuÿûQ¹ÿÇ§ñÿP–ø_²ïWN½©ud{İsCª›ç^ éRI{tát9ÔãDğä~ »KYJ;B§%éS±d×ï¼w«‡=s£c„:BMÈï§`®¢àjÖ<cÏ„ö§`Ş ¶+¢ZÊ»­’kãÉ¿çu¼¨“=¸Ìd›)ıZx®îñNÜØ°êFp(\¼/‚s•ÛÕ—ˆJÎ-lÅ(¿‹³
â™Ó˜¬J¼Í£s•’c" òc™+’‡˜œFY%é-c"+ç:cÖüˆ˜b†Jø!IQÚH‘5•‘¦3Š‹klg?p:=~9«W°z;õ—G•J$Â²Oe9Li¢&¦sPCH3ó‘`ÈTzƒ(ê¬¨Û²¡ÔÛPA33kj¨©;ÇLü$2eOã‘²Ãz*sª8şO†Éê³¢%¿@sË}¯Ûí¹—Nàê µdèwu	^:Kºïg fv+–Šªœáêqz‘`~.¸{TV›‚ ´Äß¤miÇ­ğ0kR5>,å˜æşc>ñÎä1Ï“4ŒÇUÈ5Ú:o	ùÙ¦4ó+#	êƒøÌiYõØŠiÜï"kóC,ˆœ¢’"BÌ™ĞÈ†ûŠ×ÚérŞ9»''ÄßïÓÍ¼Œ‹Rï3sŞS ¸ØBî&§Ù˜à¢ÕÒÂó¢zŠ{£ôÎşfs§¡CI´u%$&½»ô\ØÂs	cÅ°–„ï
KnLÛèhªa(f- 8#€ú‰Â…şÂŠÂĞè=Ú‚ÈÑ¥¬8FÀŠ~l*X„ıo÷†Ä HŞ¢ğGÿâßËå¥ç ³‡WZ‡L6ã$ßÜ¯°_¼ì…Qég¼^"ä·b€è-¿-¿ùËÛò»ß®WoM­8È²v\‹,Õßõââ2âÑóï)M¸Ùò(ÊÄE3ĞFsv*Ğ§‚rD9&ÕÂGJªœYX¤^ÏÈÂEœx%ËòÖöakóhÿğ§c²”Â6%·Ónètû«S¶ôÕéÛÁRlRè‹i’ÑüV»Õ&?§Ò„Šdeü@¦]Ö Ì–\õ.h¤
ãù¶LßÒdJ¸uÑ–1ÀxpZ¼6ûwC5R>F<ké(ºJ¦•Ï~ÂHbÈ¹…Bƒüó õ¹”#®ûÁíŒ™ÑUUÜ}¸ÙÚÂ{;ñ'İÜ}æVÙ·Ë¹ú86ÛN6ÿ‡·¿ 8n ô+®sBÊŒ~Ğ<úO½ Œ´Y¤\ —Š‹Ğ½HÜ_]‹I¼aÅ›°w£vó‡ÖÖ1ŠÁÿÜhÖfQ*}Ë)`	fáx¸%›C©åÅÍıÃ–LÙ'Úƒ5«y“,ŠŠ’6ï’5x(±"MÂë„ÈrÚ6¡ĞÈm*i[gW—p‚µ­×Ê¥äl¢ƒr°VHŠÃiœÕÈÚÁñ-<4^™cÊ­iqD•4tvªÙ¹Ê¡ÌMc+œ ’ƒßdŒ’Ø–*É‘ÒüYCP	'l˜oo¿|O“dÑ*ÙV*yÚ †‹Eèt`gqûÃè*^Cù”½hš5ò"ÜDÆmÓôÖ°Î8!'˜bÊhšö[L—kÀ¦ˆ4Ğv3µ—Î[$g	é>æÒ'“¬¤“Àîk6­Q†8:‰cè™¨q†±ãÌ›¿F;)JÙj½l¾Ş9Ò­n¬£Ÿ‚U”á³Ñ”FÚdø,z¢òL(0ƒú,&û	º»5ÍeÑÛíií®t6k#úz0;w}ÓÄ¤ØÆLÂ8£ôäXYô·À3™'¨ÜÆmiäwšˆ¤ºúÃœà.È„àmÀêÑÜ¹/”«óêxNi±0‚}ÈN\ØTx´&&Ş(_(5U[÷-ÈŒé^—ÑïP°Sà—@m»²±z£Ÿrfè÷¹ÍQàh$Bv¼œ£`].D7–EÊ5Î1ÅõSQÖ "A•âø0G¯Ñn9ÓĞI7ô_‚/¦I,ncüŸYÌ¥§»Øª‘GŒji4\ú–Ûöñßh§oN=m·•’`‚‹óS¼ŠeñŠLl·«İ><–#ç¿×„œ”5ªVğ÷¿7-å{©#åFƒ‰$Mi„Ôµ_¾z= %¡bDÎ;!ÿFÛ Ò˜P‘“ã­‚ßç£n%/AÚ—œ¸Î*èÜÊ7Ùû‘nRLŒy+ŞÙó/õ”åpf¥ïõåÅxğ©Ú|ÎY
†¸#Lk8Ö4i·Í™¨Ã›NßÙj°ä¤LkÃV[‹¶Í²¢èq»½“*Ş$ƒvkq
	ªp¨Y±‹j²Âaë Y|süA@t†<¦y±Î†¿‘Yœr™qå7C¬°··åÆ|œ±“„Ê$£`8-í˜fm3¤u‚ÿI¼÷hHóJµ{—ÉgV;	î»ŸhPpWñ&m$ü¹åv‚Ï‚<¦ûçíª™.Gõrñ*ÌÖÈœ‹×ŞRôk)Ö
)wVKC¦rw€«&@q1€„ÎØWÅj%„?ÃU×ğßáÛAŞ20U–—’™Z¾a&'À]dÔß4Ş7¶fì¹EÏr2Ç‡/¯G`aÉ-:ÅÌÎÄy‹è„CŸk#uÃµgË}é3`lm’3‹±³Å‚ÔDÄ²˜.rØV‘¸¢wı»iÁ™zıRi¹ëÂ±TßôÇx™ê	g 47pâÃİxìÌ”òHâÇAÏEUˆ4„êq3)œUJLß“™#±@h.ğàhÕiˆ$„¡lAH ğà+ƒË¸S®	¾_~«ı0·_5²©7}0Ij¶È¡Xg4}H°ˆîôŠ®Èl©LB+É—d¿Ë# ùƒmÄå•ò_ËÃ%‰Ú*ºa±szVD; 5b¿@ı‘uJµ)Áö¾'§ÈY¶&6<£Åö7	‚uª“º>ËQ½%¯Ò½3àUWş(à«ĞÊª$³Â¥KÄ¦Cxı¦mÈ3•î=¥†-um¨Q¯&Ô‹ù5xò7¶ò¢$”©®~ı½§%a`Ùg«Ï2ÊÒ_Ë?¡ì×ßpïÎ’ïÇ¬¬3˜<j9gkµ’‡ØÔ	6QV?ÅZ°Zùä16ã«ÕHc­‡ØÙâcl{£!zb‹CFjëãŸi¡âİä§ßÛâmZ(—RÊ7Ë5¬1Gâø˜q
g:ï2¥+,P¸j:‚ˆ|ˆçz,_NT,wŞ¾M¼ªıÔÖ5
¬Ç´¥÷Å¤³ìP´hÔrF¾íÊÔ¬wGŸ?ÏÂ1íM„ü€Êòs·gQÏªr*"=Vô@*3¶•| a6p'hùœ<Æ`[{?ÜÏÜ6Ò!™	ƒì±ø”5€bÌ÷ÅAÙ¹‰+™+6®d¾OTJ›^óJòıı‹“¡¥8¾O7úãâÆûÔI›ºó:ê}¢|ÚŞ——ïÅÓ®¼¸öŞ^C³å7jÈ÷Å%¨¶”®gt¥aÚ’-i,Å¨¡½SEv*YÅÚ©äÁÆVÏ‚"²²$GÄzøŞRT$¿Låïm€MÚ`ã{[qàµÖâğŞ(®s™G¤Ùó@N¾?ˆ±àZnşP®C‹M¢3Úğ)]wx.\Ğúld@‘——*­İM*¹¼±” ÍºÄ¨™YWw ïZÓçqõ³a<|¯@Èçâ‚Ö"ğ¥[=óÏjú=Õ„Ê"â)FÈH˜ÊÇÜëƒ<ùlv—8Üã~ó‡y4T:ŠÃí0H¾€ß¶ùgPä-qŞq°QM5-)ñ¤%ª2•}ÊØ»w,!Y5w¶›*˜)•×ìßÑˆ$\.=-4–—òğ¿ùBé)™‘°ø0‰A²È8ÆòÂXü¸Ì¡ La±ü¶V^²@¹Áñ–v:’ŠãXkœ¥*¾¦Ne(…ø#Ê:*u¹–p,h³O6Ü'Ş°LğJ5S§¸ßÃœDÛ‡U~:‡¿j ñ£_¯ºb‘Jª#' Œ´×5={Óï÷ıÁPkcÑ¨ˆ&ı ÆüK*wè†À p¸ßk+âki6²°CgãT<C¼KX^|Öw¢Îù
ë»Î —±ğEÎJŠv9äîLa<½ãÌÇ4H-=tjgËK‰Ù´ÊMÇƒ×ÈñkíÎh4ú¤]Ù¥ÿğ8{+|ÉËèøeSe}¾à‹¿°E>¤ÔıÔJ·nK:“Ä…ÊXêhËÅíj}¢ù(çÓí/píŒÓãaq¶yæE_tŸÄC QV+6'Ày¨€a¢µàÁŠ¸…×ûªIYu0°à(âŞŠPÔŠP‰—~pé]1gã)Oâ‡(„‘×yOI‡Ä¥#êÂ«Sq Í…$çï´fÓ—½°tTˆ¡…„ªµ(pXØÃdøçôÒí\k@êU“SŠC§¤‹‰ô?»@çzdz©ØÒhE:mp~û×‘b|MÃÆÏı ’VˆášøÌ5Üœrà^¢TV í}Àñ¸}t8Íµ­ƒò#3À¥¬}¯õFn´Û^­¢ĞÛO¨P3+Õû„J«‰Jò^bBµµD5®sŸPi]Ó›[,C¥Ï™åÖ8a.*¡èÛIâZ×P—é„ÒLÕc%ÍX5„b"_¤”.ò‰‹;û5i>5 8xYÚğlÍ{–N\ãaš¿ÓøÁ,[•Œ†'JúDª–­Å•a&SkÜ£ S´jQ-VëÏzŞSÚÖ€Õ0Ñ”N‘›RÔ5SŠºaJQÏÆ7õ<4lÆ>2Í	ºN6äG{áÓ#”cŸ<èwÍäqûÅlŸê¤'ÌhMk!³b‚XãrÁ¼ó¦¢š¤GAIâA+òxH”ÿşŞwÙv”£ÀVĞl–Á'§â²½OBqGd¦;ŠèA)ı cïJéOxâê™Öâ£6–uM=*+sMl•¥Ò#'Q.-awPÍ«èÙ‹tOÙØ›PyıIH&)—²Ë¡O®KI9>”îMÖ$¤’Å•'.Jï“ˆ#F£S—TOŒMËÈ{I×áÚªLÍ	Cš.§¹‚Ø]²ª™õ¹›ô|²uqV´L¥tÂÎrïTpÔL¦›ØÌârbcŒ¿Ï§F#Á?¦CÆZ)Á	†N^¢îh(E%ÅEx±¯DÜH¢ãáe·}ˆl~G?nñŒSÔO¹Y+ËÂØé“±
nÌÔ_hNAKV/+¢Ûv*£
ºåÎZNÀbºî5‹ól1÷©cRÎŸÇ{„mßƒ¶1)ş3ÆK­®Ö*ÕÚÚF¥ZeğGmmõ	[P¬Äówÿµã¨ÌÄ¬.áCQÁíçum>ÿótıÎÃ.ş'SÏÿZµRY[­Ö`ş«ëkµùü?ÆƒóØjní¶Jıîµãñlm-kş1ğw-1ÿ«•Zmÿû1RPRFW›ôt×…B»·Ü\ü×ÿåÿ¢ƒˆ¥]'èz¿Hci¯?ìáY
¨kCŠĞ‹¹<Z£pëÀ°ªmƒÎŠÃØ‚–ûÚ1ŒÁvœ¡–X³‡qŸÏÎWvNÛ0tzháp¥Âc÷°‘ımÃF$\†*«ø}7òú€èE#Úu…]ÒwŒ<p1œûxïF=îAé.¥c1$y‡WDRVÉÒ¸Û=özcb‹ïD„.{î ‡>´Øó)ÂÊÀƒcÀ©Ò~àÃ¸%‡ÑgºÆm¶wWØass…
½Á„ì¾ÈÃşå¹×9G¼8Ì1¤QèüHæğÙuµN”r¹§’hbuÀ 3õ®¸9%NÓÓ§*ñÓ§bXVxœe#‚®ˆ<MTÀNFƒ™åA‰ÇÊ‘0
FéC{âà éÂ„ÉÑ§ĞÔ–V0Ò¸×÷zN€d|‰÷ßğjD™A“T4èjR^61œ3¾¼(rXã2sƒ'®;Å‚|Vv¼Áèûa÷¿şÏÿ`…8nQTmD*r<hªwè„Ã7€xX”Ï½õœû£†Wåv¸QçœÚ¡¦^ècDšÁšÆÑÑóÂÁ{¯FÃÄtÅÁ 5ùiU!ën„–¦O‘¥qZKìG\ 0¶¯ÔPÁğÁZÂ`Q;|¾ Ñù—¡\cû Wÿ[™½Á3n§ºï0"tµÃZí–Ó±ây•«Õbuõ¸ºV¯}]_ÿšÜ‚0ª>ªºüÓd|l¬ºüƒ`$•RµÀÑÌ‚6eÚé±•)÷òŠ‘7Åó‹wğïöfœùüAOÕ0ºÏZ_}Ceiüş#İ¬õù»±MÀ¢›Ç¥oz™¨÷1Àâ™[˜î"œ;àÌİàÄ‡¥Û÷»î$h‰1Õ¡é²Ê£Ävq‹#¦ãg#ZO<UÁ˜¦&=š–—s'Œ*Æ—…úâË™Kt„±˜Ö‘eéÅ¤¢4J“šèò&0B•­	Šœno"Ì‚¯¸Ó¡ˆç¢½ÇÆÑ22 `ÁµØ¡a„rHß¹b.Nˆ¬•Å¸¡Z"T¼i
k¼à}"ùÛ–­Œ†å.hŸ-`ûÄ¶-¬Mh›;[»Ì?osìÇÿŒ6:£ä»IÆ‰&a÷Èå¶õ=ËıàÌB™4x*„§O÷E¸3Gˆğw’"ğ‹ÎXJP¯xòô©X±<‡‘à•s´A†bñØpájwíµŸâ–ö”-K9…Çëø\ø=à9|CxÓXœnÓÆ=ú"˜ª
ûÀSØ JlÛì²ÒDvdX/9‹ßÔk«wŞoßĞ7g^ù5UÀ	…Áíù—øKİNPºì l¬‘Jea¯û:™ÛâvuÍT²nÆ@Ùš¨ e WU±$;zrˆ1İÕ3[(”e¾
;-ñ\’/ÿi/ÕÕl¢Í ş¢W ĞÂcÛËoòxŠê`$×92Ü8Î…¶jÖ¼Ø`™:‘poQyßÔÅ¢ Å·ijÜ´ØkL ¥šˆvĞŸ¼A:ï‹@#ÌçDšºcÎ«|Ãoíô7üZL{#rm‰«œ¡òÎ¡,ghÁr˜åƒş•¾d•¯åµ²ü¦‘=ï¤œƒI)ç"¶>şÓHä£½ï å•ºzIj?ş‰.ñÆoÿ,ğ#ÌëÕÍz%àÈ=X^DNö‰öäŠ	ÂaâL.Øj;É/"--yè£nÀë¸‰"—½ğ˜2X¾‹#®öõNÛ›™ÅHfµŒ”–’-&TÖøôr‚à2@‰ °™ŒL§DJŠ/P³©‚ÌÊ0ôüóT¬¥µ·…^æÖ½‘‹6¨ñ1+šÀ ŒÜ!sN#WíK¸ŒÌ3> $%1Å =ÀR!Îàp–ÿ#–È§Ã™ˆüR(¡¸ø÷‰‹~Nì©:Tˆt7ÔşT—>î‚?Ç¦ŒÁ/Ì“¦Ä?£Pühî ’9a7ÃõY9îK¯ù’JÍ¡FA%áÜª7m9ä)ªsÒYXÀš<ˆcİ:ç^ä’&-—{q¥]<•Š”dQ|éïùa
íÆté“‹¥BêUzÄQ8"5 »C|¸ «‹È”S90šßwÈ¡Í‹€²ß»˜~:–E(¯E®<×¹ò\×óŞ[õ‡+6?V%'±:·qa>£ŞÌz4–BÖ	Fè=²Â½cP÷«ÃÂ>r¨ÄKê%¶¯2I¿('€û]ĞyB“ç•Œé Ôêç =ñÔIúäe]4}\‘Ç³aàâ¬\º€X'EjqÁ.(ê¡!1"Ée—±Ül™R.÷‘g‰L<Ù–ËY–ÅPĞb‘Â>&ß`Á’EnşÈµ¤|Šk!_šp
¸Ah7Ö_ f—ç[E8Fø	+2zW¡F8àøhçQøa 
µ*KÔ!>#Ñó8À¾‰©XL!<»s»ØòÉDí†\À_¯ ÷Ç8&üoô¦»îı_¶ä$âˆ*+¿ô€âXô©GŸá1y¸4[@©CG
#v‰Ş'y‚zU„çIë–Ø/å;¤BsŞHû¬’†¾n–—DŸšUø¬ãtç.H›=k]¸¨…¤½ƒØÉ‰‹—a˜Í¡—ÏÅÑ»ÉÓ† ¨…ñ,”´ƒSùÈıÉAK*ÊAË&1ˆÖÑJõ-ei›µR|å¥î pwojíàZárpO![ĞüÈYá–væÃaÅ-QµË¥´˜jÙ'’]AÊlø
‘Oœ§Äv}j¦²OÅ¡KC:‰\áõ[WO/{îÊÑ©oò‚j\pKÖã„$Ùy›Ç?Ğ¤}ü“bæ™íLŞÊêÙ˜¢·+ÄBÓº^t…-vºş‰êö&5PÖ^[”¢”Hä9•zYŞ´MÓÃÁÊşó>Mëúà{­„2TÇk©*õ()ôRÊ¤¬‘©®ŒGr,z(°Hv*÷O&ÑmEùS&¥<´š7%1!˜B}ÊF»8I›è(ëuFxíË“c©F­‚ Øİc‘L	9ÉkB@J€ÛQbpåT«‘%g¢¸9²ÆÏÄ‘Ê>ñi™$æşâ\âı% B·¬Ş¦ê´Åm»v­5`f¯%…N#zmø½BÍzÚYĞŞkscˆ Fe$héE ¿y£øAoÔ,hoÔÈ%;qDË9n
ÈmbSP†îmı»S£‚luvÌde|‡µ±v¶¶_1á%ŞÈCC„Dúœ»£§iä¦AO/®³t<–Ó;h?x£Ú­Ø0ğ»£NT>í_Vk¥Z©ZZ-Up"8;{=àW±jSqs”$ªU¨P+­rlœìıVù7Ë?wßWK_—*ÇÕµµD?bÚMbRò–MñCuOİõN¨£Î¡-×iÌ28´q€4¶®„Ö~Â¼ŠÔÏ6Z·u‰ëDJƒÇ¬„ÁÖşns{Ï2ÆcWYR=¿ÙÏG)VÊŸS<RÆ²¸R%o“%ô4	(Š÷Î9	œkğ-$P6ğ”LÇL^aÉ¶hÈÎÅ‡ö3®RXÚL¤Ô? Ğ‚u[ä÷&7œ\mwüéZ¦CÀ±À¯$ç7ô¤îÀ¸hä2@Æ‰Òü‰á’¬m—³9³‘›o'[b¯	l(«ÈQ¡'2Ø¼™‰Í°£%EŒyOä¼‡Ã1Ï”Æİ9 éne—Ã]L_ Æ‰Îpò2f\ºˆ‘UÊ™K´o	ñ&Ú7ZâÑ‚ãNı¡¦ %ÀÙ Åš™Éàáálà’úœÉ@Aäl@•Æh01‹¶‘e5é=5S¢ˆXW"¸®ãä™€ûø+¥fˆkŒ¾ñrmûeøƒp‰	ƒì}$°úœŠ˜xBU¢óîÔôÅzYnÍ¹\ŒãI
.§sNxH–«¨Ì@¼S‡×	=8<rİ­?c£"ÂÖŞù{”‡Y¹ ş:tÍï¤·xMbKú‘.Åš"Ç±5†ßH‰ÖE(pŞëáí‘?H3§ƒQ$ôs Ö#¸ êN	”{öÇ03H€ñoÓÁ6Ùş(Ò cØ,Àøm:Ğ:jH¿ƒôûø–ÅÁûJçÌ-âkaÜ/â.xšP¦9~”1"~„`C‚’›ÿY3ÜÅuâ…çgBÄo˜ã'”©›ƒÏ­T*ºØáô,<>¿ÒÃc¦°æˆØ˜*Ş±×Çép4eBí}*•®ReiI7élÊlXSm-nŸ¸q¿¦ª–¥Ä´rİ&JV€¯ÒYóZ±
Û3ÂRª»…Ã[a¨ŠMàã”ãjä#04/hêÙv`›&D*tÕ2:Ãå‚'Ôø#ı"¶
¼¥ÿRì2D‚³Jé¤"KÑ*|ó
ş;:YÂ›h¡±Ì{7x·|EÃ°^.#¢¥3*ãÜ/?±´ç(*R­°\¨çrOÙ›Ö2”=ãÀÂŠÀwÏƒJª2/ZÀêáè¤ïñÈ`ôöõËP©@·ãuğz½Ò6…×(üU—dĞÕÂåÊÂ+LšÖJ•ûÉK¹bş	];0¡Ã+9Å¢
s"ö¢Ø]^^–Xòƒ³²h.,ïlo¶öÚ­" }²ù§öÀú´é<tSúÖ6V7*ÕîÿùìÙÜÿó1œºü’—˜ĞÆxÿOøûÍÿjuu½ºZyó¿ÿ›û>Êóÿáß>ù×Oì:¶ßf–Ò¾{òğOşùüƒ¿ÿïé@6ÅŸXãÿ„ş]¢È¿ŠßÿGØ>Jèê–0M6ê<1TîÂA:ÿûÏøßÖşÿÓ½ú9¬OÂõAÚ˜°ş7jë‰õ¿º1_ÿó,ü¯øÊïÉ0sºsÆ”À[ÜîÖÙâ V®êÍW+ìÅ(™ë[-Û’Üı[Ö²õò‹­vê´÷ıU1…\’bí›öuu½Æ^õœ(:	Fgg+¬ø/n€îç€6ªVKü©ë†Cğ©9ŠàL&>µ#÷/×H¦fËp¢. Õ/¼+q9û‘ ”½¡v«ëEªöâ°ÑMnlôâŠOÀÚ…—,ğ/rè^x(l§ŠÈ¼˜(Ş4.})L¡¥ı+ºè%ËT‡'ˆ©‚PGx4?‚3¨@´SÂİIá Ğ»ŠïÉô†ğ(…Za÷Ÿ¨“§@¨˜`4'³c-ö½‡®YWuøYı¦TÙ(Õ*ÕgĞ=à1è{‚f‚=Á`æ(P00«™ß'.«Aä|à3ğCó°ñfÄ›9â2şZ»ÚXz;úÃÛóúÛË2{“ö-É’îyÃŒ9ih¦ãñëxr@Ş‰5,©V “,Ìœ©•=·–Õ
ô²áµU\Ò?‰Q60‚]]'_CíFœ&H½¦1¢„…­Âî —ÅàÕÓö—ô«éz¤İ/omªÙSÎ7â69L„Õ ´şLZ÷ â*7 ]He…™¡ûÚh7}¾™ğÊKµäî‘£ÅX
æ’ãŒôÃÕ/%ú³H8ş`éX‡ûs¥oôä6¹ÌÜì9&bğê‹¹;Ä‹Q¸Š¾Y“_S¾¡ªƒ¹Ôé&rş.©¯=úš××r^ûŠ¶LéØ¤Q
WJº¼5JáÂI—‚·PJó¾)Jay½ÌBj9h¥;ãKóµ—†`¶îÄÎ(¤‡bj(Î†%+Y½ôÏù[-³ü_¤JU¾‚şï`dÚæQ«±Éz°R`'üHAiT¡Rc	?tYé)wÇïùAÃE¾*`s¢¾@/
Ô«¿²A{¢8¬ñÅ§tW"V«¨21	¨E¯&rœÆ’¼Fjë•ñ3\æWKqu÷vÕéI«¸ÃÛĞ®ub(áí`Ä·NÄ…ç7–.¼T`ØÈ9QC5"’µfß7–Œk¢bQŞ1âø^Ö¯T‹Å( İìÊEXØİ­=–ï±­Ö.òâ»4& !U]Æê˜„£ş§E>}'¸’huCX‘êšùŞU#–[éb‘¬^oo	³ñÂ(é/
_hY\–Æwgéï\Yÿ ®ÿÕ/îfÙÆôúßÕÚÚ³5V©®¯¯nÌõ?ò|æúßĞÿş·ÿ²¹p¯~ÎëëjõO\ÿµÔú‡¿æëÿ1¹ş÷ÓêõU÷ëTë–Cc´ÁIU°nî;Wß…/]<•‚òÓ)à0WY¢!½‘ùØÌâ~jÄki­h¶&ù¿èáö˜Iòÿjm#™ÿac}m¾ÿ?ÆÃãka>€|‘WY"©î]ø¡&>P¬‰X¡ørU{ÙVo×ÄÛ&©äÛuñöPS'ğo·ZŒå¸=|½ºúõ7õê³Õgõ5xê_óõ7s=Á´=ÌÙlÛ˜´ş+©ükëëÏæëÿ1Z÷ĞmTnÿ¥º¾¶6·ÿ|Œã>tw™ÿõùü?ÆGì{¸6¦ÿZm`ò¿TæëÿQD”Ğiãöëu£:Ïÿô(®õaÚ˜~ş×k«4ÿëëóõÿ(O*ï´qûõ¿VïÿódDìi•ñç¿j¥*ìÿ×ÖŸ­×pşAüŸëåY`f\òÜ{%²5«ğ„ƒ.;UÏ2äòß8Á•ãøKñK	ùuÈM*;dR©«ã)‹f…1iÃYàôÃ\§†Ç×)\KIŠ¤íÕÉçîOZehL:™üÚ:‘ ü±£o9z¼)å„¸Ñã+Ïõfo=ÀlÛ¸ış»ÀÜÿ÷QÌü3lcÂşŸšÿÚÜÿïQ¹ÑÇc}|±V;’AdæŞOä;Ik{ˆÇ¶¸¨–ª•Gµ¸°¦1Böªg0ÂäMãŠÄF“Š|GXğšäOL%ÀÚ }Ò¡ùïéŸÀÆ:ı½_àÏJå}îf.øı>¶tL³ncÂş¿º–Úÿ×=›Û?Ê3ßÿçûÿ´VÀ ~öO¸}ç|¿×P˜5¼K×}ß»b§#ŒˆÇchû§”
((›f;ÛÆÃÂÿª0|"­ƒ]üH¥ddÅˆ½|½³ƒé‹áÃ t÷Ä)uÎÙóç*{¯,¦¸µç¿­æ`øº†,õ€bğ9Ÿn++µ•Õ•µ•õ•gwÎí½ÍÃÖnkï¨ù¹ŒªP½>ŞHÖj4’O§?•ôvö©÷áOõLH×9“6&ÉëğCÜÿ®ñøtÿ7—ÿş™Ù‚EÓ^CBÛœ‚Ì#ÊA%\»¬Í	YÅ'”Î°u”cŠštJ:]-”Ó¤µ’Mf[1Å5AšØt‰L‚¨l”`,†À~€Ü±Œ&’É2ÕR¿hR˜üòdMñ²ÕŞe<Õ–ÂH›­…W€c¿õ˜; ¸·ÔÓDG5éMÖ3¼râÔŠ’kÄ(8¢‰. 9bf"ZìŞ¦`Ò)-ƒ\ÙŞ-”X“g°Å¤+ì,ğaÇ»=Jœ¹aˆ)ÊNÜSÌû;¢„î^TÊ-¥EŞo-ORİøº>ëÓtÀ“¶ ±¬è¦øo9Ñ@‹.Áç5-Ø'Ã$»ÄP…*(s×Å¼Ù8øÓ¶ÒÕ'5ÓÆûXªÈ8<8]âNÚŞ²o™	<C. —;çg z¢0XŸ•oğ±!ğxâ$¸ÿ™ü$*%8q˜Åš]ºğÅ0Ùş%zÂ0àq4C¼so¼ËiñÅ?î´9#.¹A6n„y|K0Ogn”kbÖÊäK–{#øò»ÜÑÕĞmğŒ¤9¼¿oˆDö¯p6|‘r:÷#T‡E¦Vq2ñ}—-šüßC™ˆ§ŒVÕúàvˆæn_·Ld÷£{²ãŸy¼¹æÀüá`<¨ƒ¼]'èî¢á(j U¢~ÆI°w4ºxænôG½È+b3b8?õ~›'3üÛ˜ ÿ¡¹Ÿ²ÿ«ì„÷«sÿGyŞ´ö^mïµŞå)Û;0*RïˆÀë@øÿro^µöZ‡Û›ïríÖæëÃí£Ÿ_l5Zíã¶›Ç»?ñ°Sí×º¥qêôÂÙZ‘ÍŸ‡xÌõ,ùZ]Í°IëŞÆë•â?<ÛX¯ÿÇx¼Á…;Àıûæ<µw=ˆ9ÜÏ)àSc?îû$Öÿ¨{¬R7ÍL4Qÿ³¾¡ô?ëkÿ{ãÙêÜşçQ¹şG×ÿØè®zPœ/.­ôYQğ(Zà#¨ldğ° ;á=„hŠ–î¡š
úUA™°gÈ~5Ú =vÇÃ*‚4€ÆşAko«}¬ra7òöd×å¼©ü©&2wº¡+ƒûpUO±‹A}ş:ò I]Õ3¡¦?LV<tÑãU—“¶b×}©ª¡„ÿ/©rŒ¤]Â3ic¢ı÷êjÂşk£²>ÿ÷(ÏÜ^+‰vÒ^ËX_¬ñÖàÌH¿uS¢9	oœ º2‚>ı½Ztåº0„İN†/:C:\~p–ëvêL½Ìù'x§ĞéÁ ”àÌx¿I¼ùv±3hĞŞ®Ø`w ÿœ®h©ÓÛô˜Óä×‡:2ÿ|+ÈŸš5ÍŸù3æÏü™?ógşÌŸù3füüÿ5ÇƒŸ à 