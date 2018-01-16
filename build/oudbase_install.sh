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
‹ £C]Z í}]w9²˜óq“sù”ä!9çœKqV¢Vü”dÍp†Ş¥EÚ£]}]Q¶ï\Û«Û"[bÈnnwS²ÆÖ<äœ<&¯yÍoÊ/¸¿!? U è’’(Ù3Ó˜±Íî
…B¡P(
§–]yòÀ©Z­nmn2ú÷)ÿ·ZßàÿŠÄjëõúV}£¶¹YcÕZmóií	Û|hÄ0M<ßpÏ1§æƒlggS¾‹vÿşLÒ)ô¿3éŸ@óü‰WöPÇôş¯ol>­cÿ×ê›ëëÕMèÿõÚÖV} \béWŞÿK¿© œŞ ·ÄJ‹K ­°Óo°ÂÂÁ»Ö¥Ñ·<Öz¹ÆO<Ë6=µÍKsèŒG¦í³ß²îd<v\Ÿ­<ow‹P¦k˜ç¦kZïg²ú7kìëÚf½¾êNÎÏ×X÷Êò2İ¡a÷ô¾12Ë<5˜6ààckâW|ìúæ™a³sà-¶â˜^‘yô®ìĞ»?ø‚ å3‚Ò¾å¥»†çoûÜì?¿æäo~X·š?ğ,Gæ¥åYË"?ğl‡wìx&‡ôx†u{®5ö™ï°sş˜Ì²¡ivÏd¼…Ìğ˜kú›õœ¾‰”p|Ó“Ø =~Ë^³‰göÙ™ã2Ó¾´\Ç¦N…Î8Ÿ¿n— jøDxŸA·Bmlàûc¯Q©œCÎÉ)R§Â)æ¡ˆ7Ş­@ö=p•ã^7à±Z+W¿)×«µ§Œ1(ŒíØ–oCviºHFÈS«—k5Ì³%ó´ú?‚B3šğ3;6sÎS ¡åœ%¶•:#ë'ÃÄî=g~ Ávğª}rtpp|ÒŞo>*ORØÆ?Ç¡WvÜóü!Ğ±ûØÆûã‘#pm#“¡Ï^Ã‰éİ£A¹×£îÎÁ~z3×>hvöÛÍüñÑ«NÍ™–€wÓ¡É†Î9;³à‡1› X öóƒn§™ÑÚíŞğÆ)A6ÂÑÔİ>Ú9<>Ùoíuš…äpä+T‹¹ã½Ã“öÎQgûøàè‡f¾âÆyzùbgj/|Ô2ÜTôâåB!Ÿë·O¾ï´Ú£fP<ĞÕĞm…Jí7lå5çpx/ÈwS¤1Ë
«ùÜ^kg·Õnuºİ&ğô×€Yîr££ƒ£f5§rÄı{’ƒ{1±{ÈT÷an±£ïLàÅ^yÆ¹¹Rd£²µmyã¡qÍ3,¸vd§€‰©éUÛÙóÎY~gÿÅkğŠ×¢ü¶4¸tYÉbßáèŞÙØßî<c¥6ûÔˆ~{~ÿÈÂh¿rÜş`şgì}R%Œ•IÌN•³'‡Lîğ”Rü2©xÂHI)î&ïÌŞM?®9Z=’K) ”v‡I²ï%²oƒõìfÛrÍNlÏ°¡5n
¸DÒ=‡7l,^‘,I)ëLğ&!>%'•ÛuÎI<Áÿq÷à%J‡Ï:coáeí†•Î}Veï¿ÅùİÎÉfnMÃnÙı¿ŸX>ÏWøX¿¡ÏææZ™/"ñ’ËW½?³r7¹…Ïu‰Ck3—Q¾5"…e4~¨¡NT_)æ>R;wö_Ã$Yûª±z“Ä„”@×5.Lš­{ƒÁ>g§&üÓç´í¼’¨P»’! 3‚‚Ìf[ “…í$á»Æ`rú$,_dìxg¯s|´wKÔ–ÿİW?”¾•¾êŸ|õ}ã«½ÆWİ|ñÛo•¢GGéEí…ivÒw¨÷àOX«Vo>¯fXåßµå„$™ÑG@&4äà›<k2¡DƒÌ*Õ…iy©ŞÀÁü!NÀ8ˆòì“oš¬d(ã1(©«é`‚l0¤äOo`ùÁÓÕ Ç=aÕşğ%\ûVÅm[¢y9³u‰-œNËª´4ŞÚ¾c›qÙ´Àn{ö,©M_õ“‘œŸx!Ÿ©N¨±¨è¦l21ÒãË åhÖÄ— <	ê	‘\Cqd¯ƒ9¥+Ì´1íYW5%;HTÈŞf²mĞbt™½%ñ93FÎÄ&MÜpÏ'¸DöÊ¬ƒkBÓŠ÷ã¢ŞÁ ÷Êjõy«€Ù
NíÅyáoÎ„¯j%¤6 ‹¦o;>uª‡Ó-![ÏoTG­íİN İœ<ou#„BÏ¬•ŠQ=é`í¥qiXCÔµöÔj³ o;“aŸ øÎ¤7à+>l—Fö[€:FŸ½+|üş Ø£R–HªàÖg¶·ëÀlßá‹ó3h˜ÙWËoÌ,ßq] ¢Ó'-B/>³5¼8õ®;±mÔ_„M¨çŒF†­ƒ«ß\ßSTôD¨ë³ îYGšU\ËV9zŞŠp4ÒM ªšƒlÛä"ñ{hÏĞ­¶Ä ¡å,”Å	†„Æl›sÒÚ‘BCÖ‘¦hU v´<Ré&”ñY‰¯ÀSò{TÑ…¸eÃÏ_d)øóM1²Rù#É®Û6˜úûÀm˜ş~¦Øye_ØÎ•Í›¢ï•0³4”ÜÄ„¿Ó‘9r.A­6Q¡æc>(*'îHYVé›—{2ª“
>Â3'Ìc/cÁàÆa‰¼¿½ q$'0)X@@à\\X¹×9©ºÈl\uÑÕNñ3Ì•t1Ê—“rÅU:mYY¯ëÊ3‹±\€;T O3N:ºìÓ'øòVêG>«jµÖªPÖµ‹DÁá¤²seVX9CiN=%²»ÆŞbtÔ±.0Îş1‚ë9±lÏ	]zğS:Å–§pxÆ_>Çç©PÔ¸’k@¿‡±ğÔØo‹İtÅòŠ@k~ÄJšzD§KM­PY›öH±#usÿBX–ƒÛ3¬{Ù¸î÷]cÌòZÃ6ªy\KçrB: ÕÛ)HNP@dTĞ)1»™¬7­Ê&sz°™’táº·sÓwÆÀ¶zù±ëàğÃ	MÌ†C¤ğØp|´;ñu‡(Í—V£İø±Ñi¸¨íË®ÈÂU‘¾ä–¹ª"t/‹}XùfÙŞµÊÈÈ¦‡@š—Ú\ÕÆ|Ü–’ãG™C5¥äu‹ì¨s¸»³İ:F#~«NQçÊd(¿—­³Âª:QĞZ(zûPfÄd\„‘¡-:µQuŞÍ•5asfÏVÄn=—yVĞA)Á±`$Ã¨şm-‡™¸½ğ{¨k@J3q„‰ØuFBô6ıäOZi´Ûd1`j””0ÉßÎ SFÊ1AO™x§ˆŸ›iò'˜$®L ×%æ‰r_.`Y$ÿÙ(å­½7¹î•ÅÔ—  ğñğM[4ä†“é7bŠŒçŸ6m¬Ç;GÌ‚%fbKÅ¤lDû‹2xNä,•ø¶méÌµLà§kxc;%@£±O¿]glº¾ezˆ)¼â4
ÒŞôùkµM,±¡ÑwAlS?Ó™j.ÇfqÔoÏå5-»àClÛ,ˆï@2}øSÁ÷ÃqÓ÷³K[ö*.TJ•e•¡ÔLNÏŞäe;mn’M†¾5ÆDtp@T\ØÖ¾ùÁG5ºPù¸ÿ­WygWXåÛ›Ø ÎôSÿYäj( S¬–?òIHl|ÛbIl®tM÷V5Èx]µOVÎa]ØôØr,‹Øz4ûZİE)@”¾ƒe‰VwÜè¥Ë°jTİÜ“B .ÈbAf ù‰/Är¸”±p!µÛnÒ_İ`"Õ)ÃÅJ¸ÂGK¬Zoştr€{+ÆÕ[~Şy¹³ÿñ¨ÛÌ¿³Kï`…ô‚~æ¿İy¹pÔÙ†É¡Yû–/hš›¸Sce•?·ú}ú ‚rµPÇWï¾[ÆZ–ß=«°Ğ¨•Â:İáÍ€÷E§ú-»Ám´$¡wz³"áªº@×GôÎf-¦ËÏî¢x7ÕˆJR×§aeÂO³ZÍüÑôı¼¬wÖ;¤à_Ê(‚*`ĞĞÀárFŒbFğzG¿nã™Bh‰egÎSd/+€ßjïíì«SOê,fôG–=Ç4Ÿ»û*uÓš”Ö­‰fë;ôêF]ŸøDïrÚ:C!ø“24p<4òß
Æ½aÍ/èFòúûÍ_×÷Ñ4Ä! y}³Èì·cğúô­ëÍºÆºØ>}k:X.bıXúÜŸz’ş¿Ü…ë³øÿ®oTÉÿ~mmÖ«Uòÿ­Ö2ÿßÇH™ÿïgòÿÜ/ÅÿW80IÊíuŠö~é®¿_—áÿrı­­GZ¶ï:ı	¨>°vÌ{È›=ëì:ôÃ",z—|±îÃ¿lgà…zßÚøQ}xE.¼è¯›à-Œ¬pŞ˜«h÷+ØwJÃ«ù]vïã¯;¿³nç]lÈlêN‰—R:Ö¼ ôa™X‘'Ï|dÕG–e>²™,Ë|d3ÙÌGVˆÈÇw„â•Ğ<uâË<dgÀÏ|Uoé«º ?ÎÏáU˜ùõıÂüú kgÿus¦_º ¯€@m™kß=¸vÁÎ} ğö||õ[cæ¢7jX¹é=†^7Å­nPaEêy2ï'4İz•wk•w¬r^|0ÿ¾…øïıâ]¼„Ø‹ôm‚¨Bj¨ØR›}àè§‰v‘HÁˆF™:ÇÛB‚qh,è±%ÖsM\ÍúŞ>ÚiL†bÎ<(ØğÙUÆ8n=oÆ+JÈHä8Ùİéâæ5÷8ºdË^Z}êM|À¼“C£Ÿ‹Ş´öÑoD×„y"
ï]BÛSà¼ İãÔ ¦ô,†˜¶[Ç­›Ê*›KMlá-6$\KI_¤´+¶„š“öÚ7Ü‰Ñ€è¤Í	Q°H0 ï[yõ]åİ
ü]|‡X”W•wµÊr1lšºˆ
(w‘Öö68Yš|=ñÌil-J\.(à"cˆè.[^[fğ_Qˆ}—Ÿ±Í+ç–é Dà¡ß½¾!¸ïlXo7Ÿ1}S2²<©Œ¹´<?‚àŒ™ƒ®túnÇ}H,œ¶S
§x°½-ÈBïC	ZyÁ‘'e™¸2=×<cŸ˜)‡[¿úDÏ@PF?÷¼ìàæˆWöÈÿ¯(³H[îÈ•zJ½E}Ê¢#,{İ(€4¯1Ï™¸=SÕÙÊ!‹*ò*Q»“Ÿu-/¬@ê{±¡×æ”pÎ½€—¬4–N-ÿ@NIí#İ.¡¡•ŞbŒĞtÊ½Lùù«à[>eIË­‰ñòÄó]TbwVp˜•dnÑ?@÷Èq|.Mû”¨kudrĞ¹—ß¾mœû¢ñşır1&‘°p¤èÕŞ¨0‹º9ÈîAîBÏšè›¥½as@¬s]f¹ò.¿ö._‰¨,Ÿ‡9*ğTÔ­l|ÒÎx¾3Cs?)|”qs vÃztz÷z´«§H‡ç¸vØêˆ]P°ÖöÁŞ^u}± ÚÙ¿©pˆ¥as©4p<ŸA'ği.¹¹¼“ĞDß,•ö˜Q€"ÃB ›BÍ“¶q-,æË¿ûj²ë%€4/}a"×ˆ¡`ì3ºúiŒÀıı¢#SÌ“-†Òw+÷Œ[?Z Ä7¢"Í‡Ú¼Î¼Œ#Ì3|SÈ‡rCŸ»|¬Nî¨“âÓ€|`%¬*GN ¥=Í#ã„K¸D”\Y¡¿«uùh>OïöùéâMz¸²;ƒeö5(0¶åÌ~Ôüv¼fm¿ÇŒÕw®ì5P?eó¯,u§°¢4]<YköËùÀX¢xMÒØEgÏ$˜%Ú$íOLòô¡>çóñ}i£ZU—ÿ±Î%Ô…«PÄ®éS"A.¤HÄS5!,fÁÿ…ùc>v’şŸÈÄ“ñgñÿÜ\ß\ü?kë[èÿYßØÌü?#eşŸŸÉÿ3p¿ÿOŞ _¯ÿçÓ2ü?Ãÿó›ruKË³güˆ»„Dk©(t]¹‹Ğsì3²%Ãsù» ²½ÏJÓ ı<J«åÚÏ6ºì£º•ÿpˆ-zµ»;wƒx£dŸ=ç¢éøzlæşÔé67nG ÛŸŒNa@@óŞ˜æÖÓç@ÖŒÑu°™/•äï9ğäGşÃ"ìÅĞ8Ï<hÎ´>ûYõ—ïK44HÊc8PÑ[egû¨³×Ù?níf>¹wàÚ/Ê'7‹[›ùäR™Onæ“›ùä–¾$ŸÜ¹\r3§ÜÌ)÷nN¹B·‹;åfÎ´SÀeÎ´™3íÏÊ™vÑq2¿@GZ¿a5FÎC¸Ñú° 3U¢3êc8Ù.2¬eæ5Ï˜yf^£?c¯Q±=7§×(÷/ùh8—S?Š9>í«>]a±/pv6†hW•OË$ãëõ"ÃÚ1'C‡mb\™æ³ÉŸÛï¼9yÓéüiÿ@±¹¼Ês»íğ¬ÂŒ7¥ÂGÜ¸)©øóÖöŸ^t;Ày¼Ò¨
1­û
—Tİ‰€õ°Ši…C
ë]Ôµ;‰ª#axâEXñÍl`¸5³âÄ=;«²Š!AÖ›”y³ûúqêÎ›_¬'r¸˜G2ö·£³Bş
UİWYp9eÆ¸v¢poVEj…xãÓ›Øğé"*JòeğÈ'wŞ„‹©F7¸†™£óôlá£‹R(öiNwQÕU”%õX®cèámÇ>³ÎÃnœcA ^¤dˆ7t+şÔ;›‡FÕ—Ã,ûç?ñeŞöÁşö,­Õ3š&ƒäËpïm‹]DãğNjÚ;M¹¡†BÓ*F‡D1\¨ò8é£]C>Š Ÿ)°Ô˜¦ÁK!ñĞM&únlõÓèœDeáq,¨ñ8ßÛ8İÓøyâ ¾…Sñ\Å¢–;;Ïv&ÙüÓY/±ÉsøGÔíÖÄwğªœ%hJİ´ì1gØGè=†ºMó	â)Â-2ùÏòOh¢¸
ĞPµyê’j¦“ÄİÈİ+¹É#3qöÎLz3öµ	gÎtıó¼W.¦nìÈ;~äê-ĞË\½o‘>·«í™Ğù·|˜Y¤éşßÕêFõ)ú×·êµÍÍ«ÖÖŸ®gşß“şæ?şÛ'ÿòÉ“=£Çºì¤hÂwOşşÔáÏÿ…?ğü/şÍ| [ÇÇGü•øğç?D²ü+ñşß=yòw ‡—ñxh–‡†ç£0®å—»Æ¿Æ¿<ù/˜odô\œM\ây˜ş#tyÿ†çıÏ‘¼èÃ|:4wì¾ùáÉ“ÿZúOÿˆ¹ÿ×ÿøŸÿÿ­=
£}™I»Qèê˜>ş7`Ô×£ã£¾ÿÇHÙùÏsş#ğÄÿ9ŸıàÆ):‰‹çLyáQxr#zhv
ä!NTã§@ú°º«q"hSaóø ßÇEƒga·øÜB9ûNïÂtOˆ ĞsÓ?A¨¡#Ì„|
úÊw¯MàŸAhÏAN\±kgÜvM\ë¡›Ë¥áZè¸ãáÊhõ,¿-¶Mú²{"Íûx§fèØe}X”»&îÁº
øY"².é+†BŒ;ÿ¢ášÓ²YEóÉØu°Ê¼ÎãØÌÅÍ6| 	&?ßøò®#“^IjÍC$ÁC”|ãœÌİ­İİ“íWİãƒ½¤û”Ê…r:iQ
¥È›J¥	e[ˆäÆÁ“ØÖÁzøõe´9š×0v î¯LªÕ
h„‡òr˜Ò/$H
Lh÷T€
B0Q`H7zƒ*j¬»ekÂ0:qÅ•Eš¶]ª¢ì9¦â'‘©XŠŒ”&cƒh·U,ÿgÃäÕ^Aß 8gÔ‰XYışĞ¼2\Sıbï'ĞX–àı±õº¥"ªÁû˜™`ÄRVéÌv¥1ôM×†ş¹äÇ£Òê%nÖ„œÜÚ vİ“á™~¯5O„k;$#¸é8Æã(ämU¶x|mS^ø„õ]â ö gæ:Êìı:wÃ»Äº¦/I"ˆEEU„P2¡“ûÚî®ç²sq)'ÄßĞÎ¼Œ‹R”ï•ñÒÜ*ğ‰À…r79ÅÇm3tâ€¬ kzİƒíÖnS…Á™Móœ^‚IíÊ2aâÎE\X1¹‰VÇ»„9Š\jjæØ|ø+åÃ±’Ÿ°Ü
(èŒqş?Ò%P¥İ+¡3;ıK0©‚|QÜòXQyn$ïP¤¿xB¥²üi Õ$V+Æ”Â,DR¾ùR¤$ ün”æÁ­2ñÜ
	RKz¥"(*®?1D/Ú5.1_£‘/’Oı™t@"M³İítH<ƒzÿ0}Ş÷Œş¨ÈIÈ½«P†8ÙrüÈe8¿“[‹@±½sÔÙ>>8úá„Üø€¥Ã‹²İ?7r
nEr•¡×º“LJÅH?şüˆÚ¶¸D*|Ô‹ÜïŒ´”/Dä.ÚÚ÷¯Ù³ÈÔããã0Ú‘ ÷EhÒI<¨½G‡ìàÈ­ùÁìMŠğ‰
¼:Úî´q‡Nü¤=º/Üÿšw®Ø1‰x¦”pïl§¤“ïR:pü\V.5y¡¹›ÃÖñ÷èxf¹¯ô¢ƒ—^Y º&B·|y+³èDWC3âÎ@İÖëNûÇà?7Š_Yp	d˜+¾Ÿ)`	zæÜRf ~†šáöÁQµ<¹è yWñ¯{Æ"«˜iÂ¾!]P‡º)ò$¼(Ç ± ª‡Ü{’¦Ò°wéC¬L·‰"FêÈ::¨ñ*™¤âÇ9 l28>ÍO‡Æó 0¦Üo)èİÀggŠG«$en¯à—¤¸öFÛ£åÄº‚œÙ9…;pÄ[ùöÊ÷t>µ’e 9kÀp°ëÌ,æhì_‡c(ó‹F^ƒÓ“#¤«æd«ù §¬…#B1æM“.,˜tÒéb¡ÑùmYBºcôé,èH'°û:H+œ!IbÄµ#Á&v\xsæWx'Æ)íÎ‹Ö«İcÕ¿&‘aÔõN¤Hàâ¬U¥°6¹8‹–y!˜Â}	Îù¾»5Ï¥ñÛíyí®|¶h#şz0vuÒ4<_ïI 3®4¢+ÿ–L”Ë“¤-Q~·…H&s·ÆÔd@ oVÛÎO=™ª¬û”«±ê=vjÂ¤Âã2YĞAğ&8õP¢–Ôüd¦4/Šëèw(Ä®ğK I³²
±v£®rxàíKœõFç/qsıÇè6Åúê‹À ª[,rŒtHoÁˆR?¶eM`”Q1‰İxü
Ï¼­¤ºô/«.ıËğEw~åé6nş©åÑõ_zê€¤b¤Ã‘ ZŒ—¿å^|ü=òàÍ™¥Ì¶RŒHq¾ªƒWÂ„,ş¡ÄÉ´;G'’rÎ…¢äÄüN•Œ¿ÿ½îƒ(ßKk(Ÿ0ú6$êœH
6øò%Ï/	³"Jv˜	ù7š‘Ç„1œØª øÎÍ	ÚR ñd)
Á‰«òØğ:P>ÉŞu£jb([qwiÄ|„S}¨¯Bâc¥yŸ³±	F˜Rqh›Ro—Q†WÏ¾Ûn²C”¤L©T'fíêyEÖ“nw7–½E®ë‰Ù)øw¬À‘â¯.ŠÉGÃhöEôñC„ûPòd—ÅªòTf±ÊeÚæŞ±ÂÖŞVs:c&&•IAÁ°[º!Ï /&õÒ¦ıy;-)H9š|L¦EÍ$<İw>Q à¬bÍšHxºåt‚iI.Ó­l*Ó6¨š/…évy;Cá£uø•Ë6Š1wVC¡rw€ë:À±kÙş1:c_•jUş~ŠÕ6ğoïOè
èª„—R˜&|Ã;› w<l Ûü&zß$U“¼+X	+sL|x=‚‹NÑ1av.Ö[*Ç;Ü©ºs¶œ—¾ ÁÖ%=£Y5qUÌuD¨‹©*Grh*RWÔ¦7/8İ®£n‚­ô-W!U'ı)g‹tó„aË¬øp6Ú3å|$ñp84Ñ"]†Ü!J—¨%Æ÷õtŠcÔê\8&Ú€D"ÊPº"$xğ‘ÁuÜ9ÇŸ/£O\î¼l¦so|a]Õ¸¬À¡$öh|‘´@ ¾S'*42•l¶\!¥•ôKòÔå±ÎÛ¦‰¸²Vùs¡2^–SEß+õÎÎKh 3mº‹FÌh?Jœ‚buŠJ°¾ïéøã"kVc÷«Å:ÖHU_$Uo)«ÔeïdÕµ3qù(LUKRXáĞ¥¡“n¿yq¯":ƒJûÒÂÛ6T¸WÑ¥ü¤üMR~‘òÔÖ¿ş&9ç”@ÃÀ¼O×Ÿ¦ä¥.ş(BŞ¯¿ÑàŞ]$ßOX%ö`t©=e­”Š.bc+ØH^u›¸„UòG—±)kX¥Dt›¸ˆ]<cÚsÍ!Ù\R'=ÈÀ] )†'ß9ªñá¿ê0İ¡‹°“³Ø±áFÊë:¿HoÛûĞpa¾Ó
ÂøÇÅ¥í\Q¾#ÓƒŞîßÓÖ”G¸Ñ+Y*„ĞÅà‰åÁ½Ş÷‘­Ûa#ÃïÖØÈ4lfû¬2Ç¢X5=Š†{:ù@Î¡<0¥ãÜÁˆ¢höâù¶âštGƒR8”Ã
òŠ†¾V•K$üĞ=İísÌ®Løßæ!7Ö¸”2+<& ú¨Ëò(S@ø‰8I©ù1q"É­c³E˜©"€ÅxŸŸeëUÚDıQÉÇë_ââÛòoØÛ®D^~	ÈçBòI<•`&öx<å	˜†ßlõ`|†+†A§¬‰2cdâsÇeÛ±KJÊñÂq¯·/úl:çI<°ãÏ·ztß
‚Cïc(;0]…N0÷‡ıCÑ	ù;¥Ú8á"tP3KO¦úTH8÷‚Ç¼!¢Ac¯ç£¤!ƒ#Ëó<š–ä‹	ú¹¸˜‡jJ©ùÎé"¼"½º¸¼ı¨"jGÛ4?€:æ¡¥Lq–°ƒŠ0OYW±m"Å­¬%ÅÔC­È6¯4çê´Xz"–ËI÷øh»†Cà`€ÛyÑm6Ä¢[ÉI:O $)X ±ï¾û.Œ,ƒØÄÖ«ÑUO’4Å“Ğ6f%U.G(©›bï#(5eßCn+ˆ‰;Xä4,‘“ùb’*MïL×qÓ´OE(…Ó‰YI\ª.i>_1(!ÿ'8-¤kµ4j¸>‘Â‹î÷Ğü¸ói@¤ya´l(FË†f´l„ˆ›Fƒ‰ñšL<İ;õp”³1_¢¹æ¥ÒƒP½_¡!d®QEpÃt‚Mk±a©Z	+’Çô“kPä«ù†± ’Î
ùieô×IxºâƒğCº‹ü\r0‚3>;/Pì}{8&ÓgqnF_eéqú1KÏİSËn¤ÚùÄG…–å‰,Ì¡±V~Ğ[=Lñé……Ï¥ƒqŠÿ2ğ³å«>é¡ßnà_+!é¬\NÏ‡Şï.åÀÅH tl"°f!Íø¼£Œç|9’?9xI/ä)Ôçƒ“Ï³!ëC$F¬só’Æó)NWÉÎÕÔòò@Bz§XgBæ¥b=éS³KÒ‡h7[=›ÈŸ™ÄB‘±:·œó^`KÅ"`Ğo(¬$RÁÉøª_ö?øI>x‡oÚ<Néåcîv‰…efl<Ÿçvnô€÷hZ$/¾DCâ¬n,)…ÛÍHÕGÀB_8ÕpK·RîsGbù<Iìø<h³âa¼¼ÿ¹VßØªÖ0şO½¾±ş„m>(V"ıÊãÿôL-XÕ×{(.¸}ÿ¯odıÿ8©ïôvğ?™»ÿ)ş×ÓuèÿÚæÓjÖÿ‘°ÿ:­ö^§<ê?P@§iı¿^İª×"ı¿^İ¨gñß#-Ñ2—.åâªÑÚ–68P}á¶:öå?ÿ÷ÿC‹PĞú†Û·~’[èÖh<Äm
È½":·*|<Z‡pöÁ°:t‹Ö5ãp_•{`2ŒÁæõŒ±é•Ykˆq¿ÎÚNëĞ4†h:¾Â_aó°’ƒ-8¾·†à`­hÀŒÿ„7ŒzĞÂCû¬±+úq¢lÙ0o„›-Ôâ!äîS8^M§åq˜D$­ X>?Œí‚ÖèØâ"B;ECó?uñÜÔ8tèÜ]zf‚ŞëšÛ’Œiï®Õİ[c°À_£L/'Ğa{„d¾0½X½¢`…a®pÕ‡¶+X=ÓâÄà½k*(çr«’iV±8`€©‡×ü<
vÓêjÈjuUeÇÙÒ"(‰ÈcÄìtb÷hoY,tËè*\È{¾;é!ˆÒ³úÔ²aIeB‡IêSh²„Z0Òœ5²†]k…›ğjB7ÃD¹Èî+Çç^´0œf¾r-ß7m,€q¹(ŸÏí|˜‘÷Ê®eO>°×{ÿüßş7`…8¶)ª"åšÊŞøÔt¡a‡fåıFo-Ãf4=ïºÒõ]Óï¨~jÌzŞ“Aİc_ó³ôõX‚.¡){2tWÌğØqëˆ¯KÑ<æñ¸~Zh1ú¸‰,†İZfop€ %’¾RE!tjšäƒ±>bQ=¼¿ Ñú§¢ ”Üºø ×øk…½ÅÕ^¯ï™ï1"X­â`¬ö+ñÊXiÃ@u¥Z­T[?©m4ê_76¿&gqí^ú„¢ÁİôÕrM\JŸmÎkÇ¦7Š' ‚·Š¿‡¿OÙwÊÿgïÙTxJXA	Íøø¡‚ohØß?ç÷+a{½ŸZÑ,.2RÂæÅYàâw›)á’óYĞ"4U¡©±ê‚}÷2ÛÃ)„¼L´ÌCUN©jVR,’\ê^f#ÜØšÑGö\¤!Œ…À”†¬Hß¶ vG±<«Š>¯Ï-'UA‘ó’«‰Yô
çVù]D÷ axæ5%’%*Üâê9g>F¨“Û2”ÂŞ,B¤,Æ½“"¡µc>Âëşf²Ò°H©XÎ‚É½¡ì›Yw‚h`3ê¦_‰MæŸ¦×9õ£¸¿~ÑåKQÁ‰aG`öÈåvÔ9Ëü`ÎB‘Ty(ÌÕÕqôâ|r~QKÊ•NWWÅˆå1<‰¯…š£²…´áÊ#”î'—^Å)m•­H=…Ÿâø\:C9E|Cx-Î)wdâ}8"ÄNpˆ‡ªLR|@ƒ(³L³—(J#Ñ9Q\`¹h/~Ó¨¯ßy¾}EwœœyáWT ;ˆ;t®ğ)°ÓÓÙ4…»’AÄcBjÆB™&—Å6½]Y=”©,›B¨$&
(H§DR2jpĞ)ÍU#›(Ëx¥É¼Äïyñ÷û±¦¦3m
·ğït¦	Ä€4-9ÿ6²,Œä8G¾¡€Gsõš€z©R#0>Ò-²£ì›;»ÖC¶ê6UMë–ä3X©ƒ~=Ü{çëËÇıhb¼Áœ¸¦à„#‚ı*ßğı+õß RŞˆXëb«#§™¼sh ËiV°Fy¥¿âÛòµÜ•Ïè7´N+9è”JÎ7aúáàÃŸZ gå}8¯ÜWsRıá#”Ğs×ñ1®{?í5`€”[02,Ÿ^Dê“#ÆõÆ‘/Ğ8\`ªíE¿ˆk‰èÜÚ¬Ér5ôğro”ğ]4qMï4½éaqµ`æ+Èi1İbFaEN¯D.”8v“ÉÄÀpÚdä S'eÑ›Aè!œK´töÛxö qnäªAŒŠ/0ğ|sÌŒ3ßæ%Fúˆ’š¢ñ` Î—à°–ÿ#æÈÇ¹‰øâ¨¡˜øûÔÄ0Kl5XTˆpÇ)Ü¾ªj÷Ì˜csFf®4s†g\P€Få[Ã>Ü•£¿ñU3_f3ï»Ïë^‘;ïgç¬³´$î€”ú Òºåö–o’%-—{~Z•†ÔdÑ|å¸|1…>NªöÉÕR¡õvÄ‰7!3 …@@|¸«ªÈS%0ú\£c¾‡Î9#ãÂÄëÇ<áƒúšoÊu)×uCë"Ñ~¸ŞåÈm½êJj<Ê¾I÷Ë&/eõÜ	XãG"Ğö«ÂÂ6r›¨ÄkêevÄ³Ô‚¾S ~r¤™€ô»¤õ„¢Ï:¦Z§§®€yÔÀã§ñ•W2u4tÑMoM.ÏÖ„«‡‡½reb½kdÄ»p]ñá‘ ’R&²IêÍ	İSÎå>ñ[B"ék›\´`^||3Ø§èÌXNĞ›?q«…áZè„&¬Â\î¼ØíhÙå÷mxâ h#|…åk-‹P%p¸´³äUÛÁ¨,SƒDä†HËÃ°‹:¦b0I„píªõ)YœiqÉ;­r Óq9|½Æøı¢ü7úËÓ^?òn¶æ$âˆiq‚"-FFp~Síá)qØ¿5iCGŠ7}â‘Cß?A=5Ëãä÷Ël×Èò2@#!KO¥€ÎQï3‰~
Ê\=HÆ<VsÌ³-`aÅsİØË`·s•.§PõĞüÄGu[Y¾`¡têå
G8 •‹fv1í¦Ép’øÆHƒ¨ÌöKØiDÙ¡IcZT^ãN[»(/†æºnD¯ŠUÛ«!éÒÙ„»´Í»Áã!zOO1¹”š1Y^%J-6%ëí2ñŒPµjâ[c…^ß9Z <àcÔ˜’ØêûE:W¶H#¯:ÉhÁÁØC}¼OÕªi³Ì^úZ–•[7TB”ôbv‘4ÊÔÖ¦#9=œ{¥h“SÍ‹š²¦FBĞtVÖ•
¡cA#
ƒN)NxĞÏêMp“Gÿ*MÔiÄDjÁ|µ˜R™Ùñ#Ä•]P–|Ì‰ã†:eµÇÈê ¹ããÓ+·’É7tÚ!©‡ôD8”c4İJğ6V¦+6•›é­–"X¨¥áyª%ôã·1¹ÕúÄ"@•ÊHÛP)ò‹
 y¥øA­TÏ˜\©v-ÎLŠF†sX°ÛÌª mŸ%µïN•
VH*³«Gcç3lÒja·½ó‚˜	÷£&î©Gâß=Å¸4zjvU¤ã
“Ø  <ğJ•Xi÷'=¿r6ºªÕËõr­¼^®bGpqöÊæ»f¡•.æ¨IÔjP ^^ç(Ä¯_JkwpHåÇşE­üu¹zRÛØˆ”ù#^*Üè‡däˆf…¦æZ§ÔPK•Ğ	;hqÌR$´¶Ò¦®ˆzF¿Š[¬’xaÚÔ%vÆ(Î?_}íƒ½ÖÎ~§6Ô¾c-¿éé“T+åãIêX	'X¢£zœ·œ
ü¨hxJ¡£GçÔi²“„T”,Å‡òGW‰™$3mGn›N ¨!qZä•gW’\Qmwùj¦EÀëPá^
èYrìØ&úkØ(8Q›?u.MÒµ“õlÁbôæÛéÀê!qŠ5#‚pª‘‘51¯‡š×ì*·>„²Ç7.`éÊCÁóS¦<C“@—Cí:@µvrGëqyî‡ÍÄNèˆúñ„|27i5ñpHa#„)‚P ‰ÃõS…F†Ùàğ€ş¼¢¦‰Ù@Ñ²1h`ü˜LôbåD^E{õ”ÈÂÇUKÒËE°?Pú^Š¶Æèo·;á²_Şg·¦±N#!Ÿs°nr	¬Ú¥"(®°”¨¢;Ö{¡…‘û¥ú&7ˆ"=ÉÖdôñÈmˆwlíckGqcì¢bâ›ìÏ†¸ŸH«!0ñ°Daˆ¿òLı;™ä^J•X“º¢‹I&ß0’HD•á7².÷
,÷†¸âØq¹bôpK…t~4q.€šsåç©C˜),Àø·ù`
ïb¼â9ŒQCÒ ã·ù@«l¨ }1é‹p¿ÀÀ7ãÜ,áká¦.¸˜œLü$…"~‚`=Hš;²%Fğ/Bˆ—–“
¿acO^MÈ·iÂŠíxŞd•Øá¤ü´sy:9Gš¡¶ˆV¿"A<+ÂÀ[ú—âïĞÅÔ4^¤Ï½ÌE¤‚âíKº{íÈP!Ã½ÿÓ}¿"/ì˜ÃqY¹µ›¨&Ğ:&~‰Jy•b#—[eo;ÈïïœóB(é×~WxÖ"÷&§#‹G·¡··(_BE"Ü®ÕÃİ*¼Í„dšµù«>›ØäŸıĞƒœ2eæ5&=êåj™ı . vNi/Ì€)f|-µQ„>ûÑì®®®Ê,;îyETçUvw¶;ûİN	€>ıì–ç?p“şA–(éöçÿj››µìü×c¤ˆ?ËƒÔ1ıüWu«¾¾…ı_[¯nn>…ÕÚúÖf5;ÿõié7t¡ë9fÌ§MÎ™ ^a§ß`… Uk½\cÏ'e£ŠÓÆ‰Î˜&ªß²®˜ŒV·»E(Ó5Ìs<¯‚…=­õoÖØ×µÍ:{94|ÿÔœŸ¯±.ÌX?™.?{ ´q=Zæ©¡nfÂ§ÖÄ8®øÔõÍ3´HÒ$ÄV@)¢×¼+ó‰é¾  NVPºÓ·ü ta×ğüm¾úüšw@ıÂÊ	ğÏrd^Z8;Å²È<›Tw.y!\¡¤ÿ©ëdxJÛßxZ’Š[ ø Ñßô$ê¤Óo$<N3'èôqQ­uÔ%Åf!|¢F :À}gÁj±ï-tÍ¾nÀcí›ru«sÛShÈ&ï®’'BpWú‚n_Ç¡smûÆŞ¯[GÍ×'yáˆËH$İZsùİäïwWö6ä=[–9{ı~ôMøå´©¸…¯‡Z¤y Y§‰!´”½h†h<u%ï 1¯’a˜m}aNçT¿U> 3ºÄE¾†ÒğZî(é×¹Së”ZavPóbhÅyÛË	ır¾)FùöÎQüZyy“¼^¦ èüÙ*R ûwÀÛ&?\ÁŒÍŸp?F±
ğÛ¯ºÇ{'@qÑ¦”¹pÌ	ëÏî’SÇ—¤®j.ÓÏIXùöòH0y¥dÌà‚Æ Ö[ê•=9&Ã óâk.G†·¢Pœ_^Çär¯¹b9ø:¤¯yu8ç•¯¸ÏÜ¬åÂÁÏoµ\8vâ¹à-ä
²Y¾1faYÃÔLÁˆPr÷¦çæÃ-Ì2A#±§î4	œ–I¡G ARœ›ËAh¿à¥3ào•¸ò4v£¦íî¶;Ím6„3ß':„d*7—ñCŸ•W—{ÎĞq›ÆÄw‚É`Nƒï.0ôİà•Ç_%Aó†";êÂ*{Ğp«òj'ìï`”Tğ£¹,MPl³:½;+Ü 7oWœLmJq×ß€bü
¡x·ƒÚæ$ˆKËi._Z‰÷qË<“æ2Ù¸”j/šËš1­T’–4~™:>ÁK¹ªá¹Tò]Ò­! \‚QÜoï³|Ïn†Ú{ÖÍ‹ïrÇ…”ÒÀd­bâMFŸø8Œ÷Z¢Õ÷`øÆøÏD´è#	¶ûR‰¶|^í´ÅŞx¡”ü€»S' …v¨”ÆVäÏâôæ,ÿJƒ²=b
Ï/=\3ì?ÕõúV4şÛÖæFfÿyŒÄãÿ(nş  âª¼Æ"pÑvêâCp5¾\W^vƒ·âmxÓ
¾İo£·©ä–n¥¨2–ã»ˆ¼N§÷ä4ğòŞ‚“ÉySò1ÇÅÖ1küÇíÿ››O³ñÿ	­>twÙÿÙØÈö#áyå‡®ãNû[Yÿ?F
Oì>\óö½¾	°Añ«Ùø”‰ğ uÜ~ü¯oÕêYÿ?FÒÃ5<Ló÷ÿf}kús3ÿ’bá8 ÛÿZ6ÿ?NJ‰Ø±Ğ:ªÓ×µêÆ:ùÿT×7n<Åşõ¿–­ÿ#-1=.Qn‰½÷–gºí>“Å†÷§ü•3ŒÛnûøÛrøRDByåñ=Õí©ªŞE£ÂMÆ´íÜ5F^.Ç¯1Â¿:ãRæqeè>"zÛÑê¥G¹{Ç“Qî*™N&ráÖ¯'’ÌçfÑ,=`J¶Ø:n?ÿoÖkO³ùÿ1Rjü¸Ö1cş‡õÿV=›ÿ%eN¿íôû³uöİ•"-šÑA$ŞaÄwW¸Ç>¶n­\«>ªnbS¯jSŞ:=£l:;£ˆwŠ?’úˆW‰¸06èadQ8dç‚x67éÁ³~‚ŸÕêEî&Sò~¥))ë¢ë˜1ÿ¯oÄæÿ§O·²ùÿ1R6ÿgóÿ¼‡}@@üèœòc>Ù|¯ °hxW¦y1¼fg“áPğá·bñÜ8|VÎG-¶rÄß°Uø¯ä±ğ’ÕXHvVòÙ‹W»»x}	|øäîŸåŞ€={ÜŞ!³ãÉ¬ú³ßÖr@¾¾,»çÒ¡uãó±ºV_[_ÛXÛ\{z'rîìouö:ûÇ­/…ªÂôúx”¬×‰’«óÒ/¸àvûÜóğçJ3Âõ/¤Yúß&<ˆıßÚVô¿-ÚÿËô¿‡O°èÚ«ih;öè\Á•üBŸu9c¡¨øŒÚÖzLIÑÎ@A‰_Wùm­œ¤³­éêÆìˆhlªF&AT·Ê@‹1ˆ`wÌ£¨d2O­\Å/Š&¿¼F1¼´»{ŒÇÄütá^›w8zşP^ŸG-4TÑŞd9í€vZ]JCTÑg zM©Œ>©AO§tù¯â
[½²»W,³¿Áƒ¶¯±s×÷ö4(a¸»1Æu>5ÏğŞ	]èdùåÜ’–[Üû£—mhß½Ißa½qœx¤Kt–ÍÿV"t8u	>/™PArgèl!•Ç¯	€Ö÷M¼7ç‰?o-}Q|V5ü–.ª¸qd*pÚÄ´3¾=d'¡'ğ¥€vlÀ×ÀôÄa0>«ßà:bK,# Yb%áš0‰ÎITË°âĞ³µú´Å‹÷#8W®˜õˆwî-
€÷9%Š\óÍn—yd#÷Æ°}¯i›>ŞãQ†~:7ı\/‰¾d¹·B.¿Ï_Í&¿‘ ‡û÷Mq‘ÕK€MG\9“{Åa£8zñU‡-ºüß=½´‚QÕù`öˆçn_¶Bl÷Æ<İuÎ­^•Ã9ã;À:%xÎX×—\LüñÄoW¢}è$DÈ{¢.®¹›£ÉĞ·JX ççÓo“RoZ`3ô?t÷üÿê ;áşßzvşãQÒÛÎşËıÎûÜİö‚ŠÌ;"RY4ş_îíËÎ~çhgû}®ÛÙ~u´süÃÉ«Ãvë¸Ó=y½Ó:ÙûŸ9ï¾:Ä£œÍ3cè-Ö‹,K‘Rïz[`³Æ?¼Çÿ:úÿo>İZÏÆÿc$Ë¾4mœ¿O Ïcs'ñƒÈÃÉáä\Ó>7öYºoš}£ãıë˜iÿÙÜ
ì?›OÑşót=óÿy””ÙTûOâ¦™	èáM@a”í¸Ñg-€GÉ`şIbƒ‡µ %3ŞCæ¨év ¹ ßÑ”
{2ácRcw<¬!Hñ hvöÛİ“à¡f>ù† J^7şÔ"×ºôú)£rSO©Ñ‡ş2± IÕÔ3£¤3<2ñäÅ-Šº&gm	$Ù2ôs5Í¸%|!uÌôÿ^_ømU7ë™ş÷)ó×Š¢õ×ÒÆÃÏÖy«-®VvİÕœ”7›$ğ¯µ O¿V®\HØï5|ş9òá<8îy®ßk°àeÎ9Å=…Ş€SÜsÃ¶~"—xıÌ$bÏnÒÜé­%ÁîAş9^<RSo¸-¯ø šLÔ©ùç[AşÜ¢)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)Ks¤ÿkğ-+  