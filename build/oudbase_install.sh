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
    DoMsg "INFO :   [-i <OUD_INSTANCE_BASE>] [-B <OUD_BACKUP_BASE>]"
    DoMsg "INFO :   [-m <ORACLE_HOME>] [-f <ORACLE_FMW_HOME>] [-j <JAVA_HOME>]"
    DoMsg "INFO : "
    DoMsg "INFO :   -h                          Usage (this message)"
    DoMsg "INFO :   -v                          enable verbose mode"
    DoMsg "INFO :   -a                          append to  profile eg. .bash_profile or .profile"
    DoMsg "INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This "
    DoMsg "INFO                                 directory is use as OUD_BASE directory"
    DoMsg "INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default \$ORACLE_BASE)."
    DoMsg "INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default /u01 if available otherwise \$ORACLE_BASE). "
    DoMsg "INFO                                 This directory has to be specified to distinct persistant data from software "
    DoMsg "INFO                                 eg. in a docker containers"
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
while getopts hvab:o:d:i:m:B:E:f:j arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
      B) INSTALL_OUD_BACKUP_BASE="${OPTARG}";;
      f) INSTALL_JAVA_HOME="${OPTARG}";;
      m) INSTALL_ORACLE_HOME="${OPTARG}";;
      j) INSTALL_ORACLE_FMW_HOME="${OPTARG}";;
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
DoMsg "Using the following variable for installation"
DoMsg "ORACLE_BASE          = $ORACLE_BASE"
DoMsg "OUD_BASE             = $OUD_BASE"
DoMsg "OUD_DATA             = $OUD_DATA"
DoMsg "OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "ORACLE_HOME          = $ORACLE_HOME"
DoMsg "ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "JAVA_HOME            = $JAVA_HOME"
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
            ${OUD_INSTANCE_BASE}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local

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
        ${ORACLE_BASE}/local/bin/oudenv.sh && DoMsg "Store customization for $i (${!variable})"
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
‹ »BfZ í}]sI’˜îìóÅáéì‡sÄÅÅ¹Ä,	.ñÍf ]ˆ€4Üå×”´s¢–×šD€n\wƒGâ†áGûÕoÿ?ø§Ü/pøİ/şÎÌªê®ê $AJ3‹‘„®®ÊÊÊÊÊÊÊÊÊ:³ìÒ“~ÊåòÖÆ£7ù¿åê:ÿW<¬R«V·ªë•
+W*›•'lã¡Ãgìù†¨x91d;?Ÿğ]´#ø÷'òœAÿ;ãŞ)4Ï{E¯ÿ uLîÿêúÆfû¿Rİ¨ÕÊëĞÿëµÊÖV~ \bÏŸxÿ/ı¢„,pfxıÌ+Ìïh¹^åæöØµ.å±æË5ö|ìY¶éy¬e^šg44mŸı’uÆ£‘ãúlåy«“‡2Ã¼0]Óò|×ğ<“UŸ®±¯+Uör`øş™;¾¸Xc+ËÿÑt†İ›;ÒûÆĞ,ò§Î´›c¿ï¸âcÇ7Ï›˜}w`±ÇôòÌ£´¢Ci¿ñŠ]g¥Û=ËJçvÏßîö…Ù{~ÍÉß2ü°n5~àYÌKË³;–E~àÙÇîÈñLé9ğët]kä3ßa&üÓ7™eCÓì®Éx™á1×ôÇ6ë:=)áø¦'±9îC?zü–=¸fcÏì±sÇe¦}i¹M
ÓwÆ>;~İ*@Õğ‰ğ>‡n…ÚXß÷G^½Tº€œã3¤N‰SÌC,nÎ½[<ì;à*Ç½®Ãk¹R,?-VË•MÆHÆvlË·Œ»4]$#ä©T‹•
æÙ’yš½@
!Mø…™›9çÈ)ĞĞâÎÛ†J¡õ£áb÷1?Ğ`;xÕ:=:88>mí7r•·z!lã_àĞ+:îEö†hÛ=lãıñÈ¸Œ‘ñÀg¯ÁØôîÑ ÌëöQgç`¿½™i4Ûû­FöøèU;Ëf|–€w³ÉÎ;·à‡1™ X öóƒN»‘}ÑÜíÜğÆA6ÄÑÔÙ>Ú9<>İoîµ¹äpäË•ó™ã½ÃÓÖÎQ{ûøàèûF¶äGYJ|±³µç>jnJzñb.—Ít›GÇ§ßµ›­öQ#Ko(èjè¶ÜG¥ö¶òšs8¤òİäiÌ²Üj6³×ÜÙm¶ZGíN§<ıÇ5`@»ıLûèèà¨QÎ¨qÿäà^Œí.2Õ}˜ƒ›ïè;x±Wqa®äÙÇ¨lmYŞh`\ós®Ù)àBbjJj9{ŞËîì¿8`u^ñZ´“ßú—.+Xì[İ;ûÀûÛíg¬Ğbß‚ÑkíÃïøïCíWÛ{ÌÿŒ½Kª„±B?‰Ù©r¶âãä0„ÉŞRŠ_&O))Åİ¤âİ¾Ù}OÓkV—äR
 ¥İá#Ù÷Ù·Îºv£e¹f'	¶gØĞ7\"éC
‰$’%)¥cİ‚¤À$Ä§ä¤r»Î‰'˜à?î¼DépÃóYçì-$VnXáÂgeöîœßíŒlæöÀ4ì¦İû‡±åó|¹Õúl`®•ù"/¹|™Qú¹•¹ÉÌ}®KZ{œ±¸Œò­!),ÃÑCu¢úJ>ó‘Ú¹³øê&ÉÊWõÕ›$&¤t]ã½É@³u¯a0ØìÌ„zœ¶]×@rujW2`FP™Ált²°Äà |×LnAŸdá…eóŒïìµOöabéZÂ²¿úêûÂWÃÂW½Ó¯¾«µWÿª“ÍóRôè(½¨=¥0Í.PúõükÕêÍfÕ«ü»–¡˜ğÈB¦gtÃ¥	9ø&ËL¨ÑÁ ³JuaR^ª£Ûw0ˆ°¢,ûä›&+ÊxJjãj2˜ )ùÓë[ç~ğvÕÇqOXcµ¿ |	×£UqÛ–…hE§¶.±…“ÁiY•–Æ[Ûsl3.›æØmÏ%µé£~2’³ï!äs "Õ	•"İ”G Az`ü`ù M›ø”'A=!’+(ƒìå|0ç¢t…™6¦=«âª¢d‰
ÙÛĞL¶Z.²7°$¾`ÆĞÛ¤‰îÅ—È^‘u`piZCñŞu\Ô;ô^Q­¢:k0[Á©=?+ü©ğU­„Ô`1ĞômÇ§Nõp:£%äqóùƒªàå¨¹½Û´›ÓçÍN„p@è©µR1ªÇ3}¬%—†5@íQkO¥2ò¶3ô‚ïŒ»}¾âÃvid¿˜côØIîãwÀ¥¢DRW›ÚŞ³}›/ÎÏ¡afO-¿>µ|ÛuBˆN´½øÔÖğâÔ»îØ¶Q6¡®3¶®zp=OQÑ¡Ö¦Aİ³<4«¸–­rô,¼áh¤›@T5Ø¶ÉEâwĞ)Zm‰BËX(‹!	Ù6f¤'´#…†8¬#MÑª ìhy¤ÒM)ã³)^‚·ä÷¨¢!
qË†ŸC¾ÈRğú4Y©üdW†mÌı½o6L=Uì¼²ßÛÎ•Í›¢ï0³4”ÜÄ„¿Ó‘9t.A­6Q¡æc>(*'îPY}Vê™—%{<¨“
>Â3#Ìc/æcÁàÆa‰¼¿½ q$'0)X@@à\\X¹×©ºÈl\uÑÕNñsÌ•t1Ê“rÅU:mYY­ëÊs‹±L€;T O3N:ºìÓ'øòVèE>«jµVÊPÖµ‹DÁá¤²3E–[9GiN=²»ÆŞ|tÔ±0Îş1‚ë9±lÏ]zğS:Å–§pxÆ_6Ãç©PÔ¸’k@¿†±ğÏ¨ÿ°_ş»éŠeÖüˆ•4ôˆN—ŠZ¡²6í’bGê'çş¹°,·gX÷²q+Üï»Æˆeµ†­—³¸–Îd„t ª+¶Sœ €È ¨ S.bv3YwZ•Mæô`3%+èÂu/o¦ïŒ€mõò#×Áá‡š˜Há‘á3øhwâëQšõ/­z«şC½]wQÛ–\‘…U‘¾ä–¹²"t/ó}XùfåÙŞµÊÈÈ¦‡@š—Ú\ÕÂ|Ü–’ã™C5¥äuóì¨}¸»³İ<F#~«v^çÊd(¿–­²Üª:QĞZ(zûPfÄd\„‘¡-:µQuŞÍ5asf×”Än=—Y–ÓA)Á±`$Ã¨şe%ƒ™¸=÷k¨«OJ3q„‰Øu†Bô6ıäOZi´Û`1`j””0ÉßÎ FÊ1AO™x'ˆŸ›Iò'˜$®L ×%æ‰r_&`Y$ÿY/d­½7™î•ÅÔD ûxø¦%rÃÉô1EÆóOš…ÖkñÎ³`D‰ÛR1)Ñş¢9¾m[8w-øéRl§ h8òé÷¡ëŒL×·L1…$N£°!­}@Ÿ'«mb‰…Œ¾`˜ú™ÎT3q86‹£~{._¯hÙbÛ6`ALÉlôàL9ßÇM?ÜÏ.XlÙ+ı!W*”–U>„R?809=7ºï!/Ûiq“ôp<ğ­î ¢ƒC ¢tàÀ®°FğÍ>ªÑ¹ÒÇıo¼Ò‰]b¥onR`ƒ8ÒOü‘«® L|bµDøéOBÚ`ãÛKbs¥cº—°ªAÆë¨}²rë
À¦Ë–cYÄÖ£ÙÓêÎK¢ô,K´ºãF/]†•£ê–èà®İpAÖ2ÍO|!–Á¥Œ…©İVóşê©N.VÀå>Zb½Ğ|ó»ÓÜX1®Ş³åçí—;û:ì‰]8Òú™ıfçåşÁQ{&‡Få¾ ilàL…ı‘•şĞìõ\èƒÊÕ\“N¾]ÆZ–O•ØGhÔJ®Æ“Û¼pÊß°ÜøHKJÓ{œå	WmÔê¼>² w6*1]~zÅ»©BT’ê¼>+~š…Ôjd&ïç-zgn½CJ ş¥Œ"¨.—aÄ(f/¡Gpôë6Ùç)„–Xvê<Eö²Üá(ğÍÖŞÎ¾:õ¤ÎbFohÙ3Lcñ¹+±¯Rç0­Iiİšh¶¾C¯®Wõ‰Oô.—¡Íc1"€?)CÇC=û`ÜVÒü‚n$¯o±_üx}A’×7ª‰Ì~;¯NŞºŞ¨j¬‹íÓ·¦ƒõè<Ö…Ïíñ©?Òÿ—»p}ÿßÚz™üá×ÖFµ\&ÿßreáÿûÏÂÿ÷3ùÿîçâÿ+œ@˜$åöŒ:E{?w×ß¯‹ğÿ¹şVjÑ‚–í»Noª¬İóòFf×:¿ı°óŞ%Ÿ¯ûğÏÛx®À·v~TŞ?!ŞGô×MğFV¸‡oÌU´óŒ†ì[¥‡!iv—İûøëÎî¬Çy$2›ºSâ¥”5/(½gX&VäÉÅ>²ê#Ë>²Y¶ğ‘]øÈ.|d…ˆ||GØ	^¹ÍS'¾…‡ìø_Õ[úªÎÉósx.üú~f~}µ½ÿº1Õ‹/İ×@ ¶…kß=¸vÎÎ} ğö||õ[aæ¢7¬[õ6¹é=†^'Å­nPnEêy2ï'4İz¥“µÒ	+]äÌ¿o.ş{?{/!ö"}› ª…(¶”Àf8úÆY¢]$R0b„Qföñ¶`Z€zl‰u]W³†¾·v“¡Ø£3
6|v•±'›ÏñŠ29Nww:¸yÍ=.Ùò––Ã#GŸºc0¯ÀäPÏÇç"A†7Í£}ôÑ5!DˆBÄ;Ih{
œ {œÀ”¾ƒÅÓVó¸ySZÅca©±-¼EÃ†„k)é‹”v ƒ`Å–P3Ò^û†;1´Y!!r	ô}+®”NVàïü	bQ\Í•N*¥å|Ø4uP<î"­ímp:+²4+øzì™“ØZ” 7¸LÿPÀEÆ-Ğ]¶¼¶Ìà¿¼û.?	b›W$Î-;ÒA‰ÀC¿3J¾!¸'¶ ¬·›Ï˜¾)YÔ	Æ\Z–ApFÌAW:}7‹ã>$NÛ)…S<ØŞæd¡w¡Í…€¼àÈ“²L\k³OÌ”Ã-Ë“>Ñ;”ÑÇ½(:¸9â=òÿ+ÂÊ,Ò–;òB…®Ro^_†²èKÀ^÷
 GkÌsÆn×Tu¶bÈ¢Š¼JÔîäg]Ë+ú^lèõ‚9%œsßC"+Œ¤SËïÉ)©µs¤Û%4´Ò[ŒšÎ¸—)?|ËÆ ,i¹5ñ"O=ßE%yg‡YAæıcá tÇçÒ´WG‰ºVE&{ùíÛúÙÀ°ß×ß½[ÎÇ$’ ½Úf^7ÙİèàÏ]èÙ~}³´6Ä*×e–K'Ùµ“l)¢´|æ(Á[^·²ñaJ;Wà1øÎÍı4÷QvÆÍi€ÚWèUĞéİëÑ®"BàvZa«#vAÁZÛ{{MÔõÅ‚hgÿ¦Ä!=Ì…Bßñ|jHÀ·™<æfrğNB}³TÚc>DE Šl
5O[Æµ°˜/ÿê«ñ2¬— Ò¬ô…‰\#R„‚±Ïèê§1÷÷‹4|blá0”n€¼[¹7`Üú™ Ğ%¾iĞ8Ôæµgeaá›B¦8”úÜecurÿ@Ÿ† ä+xdU98ª·õ,õìi'\‚Äe  ’ äÊ
ıøU%¯Ë‡Dóyz·ÏNoÜÅ•İ9,³¯A±-¯oö¢æ÷°ã5kû=f¬se¯ú)›eÁ¨;ƒ¥éâÉZ³WÌÆÅk:—Æ.:‹xx&Á,Ğ&iol’§õ9o˜é…õrY]şÇ:—P®B»n¤O‰™"OLÕ„0ŸÿæùØôÿD&>‹ÿçFm£øVj[èÿY]ßXø>Æ³ğÿüLşŸÁ€û¹øòıéúnáÿ)şŸO‹å--Ïñî­=¤¢Ğuå.B×±ÏÉ–ïÅoƒÈ~”¾p(MƒöÓp(-+?Ùè²êVzüı!¶èÕîîÌâ’}öœ‹¦ãë‘™ù]»}ØX¿l<<ƒÍ{cšïi°¾7ÍQdÍ]ÙBAşO~ä?,Â^Œ‹…íOÙƒÖgß"«şü}iƒ†2ÂTôVÙÙß>jïµ÷›»ŸÜ;píå“»ˆ[»ğÉ¥:>¹ŸÜ…OnáKòÉÉ%wá”»pÊ½›S®ĞíâN¹gÚ	àÎ´gÚŸ”3í¼ãd~´~İªëí‡p£õa	@fªDgÔÇp²gXË…×h<ãÂktá5úöÛs3zòxÿ²†s9õ£˜ãÓ¾jàÓøggc€VqåU™ñ´L2¾±^/2¬á¡s<pØöÈ•i¾g6™â3ûí7§oÚíßí(6—WÙ|æ`·~€5@˜ñ¦ûˆ; 7ù<ŞÜşİ«ÃÓN8Wz
•B!¦•b_áR‚
¢;°V1©pˆBBa½‹Z±6c'QCu$O$„ßL†[³0+İ±³* «d½Iïav_?Nİyó‹õDN óHÆş6`tö0ğ ğQÈ_¡ê¢û*N"§Ì×Î@îÍªH­o|{!]DEI¾¬ÙñäÎ›p1•Âè×03´a–Í}ÔqQ
Å>Íè.ªºŠ²¤¾Ëu=¼íØçÖEØ3`,Ô”ñ†na…Ã»ç³Ğ¨¤úár˜EÿâG¾ÌÛ>ØÁ¥µzJÓd|¹îİ¢mÑ¢óhŞiBM;Ñ”j(4­dtyHäàÃ…*¯ãÚ5ä«ú™Ki$
‰‡n2Ñ´‘ÕK£s•…Ç± VÄãxvoãtOãç‰ƒúNÅ39‹ZîìP<İ™8fóOg½Ä&Ïà/Q·›cßÁ«rº” )]tÓ²ÇœAıu ÷ê4Í'xŠ§·Èä?Í<¡‰â*@CÕ>f©KªušNw#w‡¬à&ÌÄé;3éÍØwÔ&œ;cĞõWÌ‹b\AJ@:Ÿº±#ïø™“«·@oáê}‹çs»Ú~‘:ÿO3ëƒÔ1Ùÿ»\^/o¢ÿw­²^Û„œ¬\©mÖ¶şßòüÅßüå“?òdÏè²ƒû½M˜öä¯àOşüü÷?û7³lñ_TâÿÁŸÉò¯Dú_?yò· ‡Ñh`†ç£0®å—;Æ¿Æ¿<ù{Ì74º.Î€&.ñ<Lÿ:ÏŠ¼Áóş]$/ú0ŸÌ»g~xòä?şı?bîÿúŸÿË¿Å+Âh_æ£İ(ô@uLÿë[<ş·:ş×kÕÅøŒgqşãóœÿ<ñÊg?¸qŠNââ9S^xÜˆ^'º8ò§@ÊñS =X]Ô8´)„°y|€ïã¢Á³°[|n¡œ=§ûŞtOˆ ĞÓ?E¨¡#Ì„|
úÊw¯çMà9ŸAhÏAN\±kgÜvM\ë¡›Ë¥áZè¸ãáÊ`u-¿-¶Mú²»"ÍëûxgfèØe}X”»&îÁº
øY"².é+†BŒ;ÿ¢ášÓ²YEóéÈu°Š¼Îã¾ØÌÄÍ6| 	&?ßøò®#“^IjÍ$ÁC”|ã‚ÌİÍİİÓíWãƒ½¤û”Š…r:iQ
¥È›J¥	e[ˆäÆÁ±­ƒõğëËhs04/®a<í@Ü_—Ë%ĞKåå0¥_Hğ(0¡İ*Àh8D! İèª¨±ì–­	ÃèØWIhÚv©ŠZ°ç˜ŠŸD¦d)2R6˜Œ¢İ
T±üŸ“gT{}ƒâœP'bihõzóÊpMô‹½7ü@cY‚÷Ûæë¦Š¨ï`fÖ‡KY¥3OØ•ÆÀ7]úç’J«S0”¸YrrkƒØuO†gúİRÔ4>,2¬åŒàB¤gà£[´UÙâñµMqîÖ·‰ƒüÙƒœ™k+³÷ë@hÜïë˜¾$5ˆ :UBÉ„Nv@îk3¸»ËÎù=a şî€væe\”¼LWÆK#p«À7
 zÈİd´Ğ‰²‚0¬èyv¶›»g6Ísz	&µ+Ë„‰;qa	ÄTä&Z7îBzæh(r©¡™c@ğáå#tÁáÒß° ğTÉuƒ^… hôhÚ*ŒÜ1‚‚:`VÅ=½‘kH·‘Tùè/ş=W*-ê(È*y¥Aºğ
q’)wÅË®_ü7•9Â­à"z+'¥·8)½ûUşcí†ĞT²ƒ›Œk Ëàw½[A<–ıı¦’‘-=·D²3mtò`ç}Ê()Ê1©ä?1Ä?6.1K½ÍßÈë‹Ã‰“üEÊ­£ööñÁÑ÷§äŒ!=InMÓgô†«s¶üÕù‰½œ'Oú¢û ¤Tßê´ÛÂÑç\:N‘†ŒhZe‰
`¾ìª6AaU çI‰¾ÅÙ”p!Ÿ¢–F`\.å>êí»!?i5Ÿ‹ø·_´ï_³g‘û©GÇÇßcä#Arî—Ğ SyP{—ØÁñ[óƒÙ%á<xu´İnánøIûu_¸/6ï\±{ñ
L)ÿàÚNI§NR=pü\¸.ğ¯¼ÜÜÇEÎaóø;t<·\ÏWzÑÁ‹A¯,P]¡[¾¼¡Ytâ+Ìˆ¯p8uš¯Û­SƒÿÜ(>fÁ…a®øŞ¦€%@è™CrK1‡ºj‰ÛGmÔøä„æ`Å×Bî‹¬b¢¤Éû†ôBê©È“Q”A{A&T¹'%M«aï*‚‡:X™zå¡Ô—utPûU2I%8s@Ùdp|ÊŸçA`:M¹-R4ĞÁÏÎïVIÊÌ,Â.Iqó¶GË‰u99²3:=+
×àˆçòí½–ïéˆ,j%Ê@‹Ö€á`–˜YÌáÈ¿ÇP6æ%¼§'GHWÍáVóNYG„bÌUšæ[X<é0¤":Ä\½¤³	š³„t'é³i¾Ñ‘N`÷u–V8C,˜Äb‰+t‚M:í¸ğæÌ¯ğNŒSZíÍW»Çª¯M"Ã¨kŸH‘ÀİY«Jamrw-	ò\80…ûõ#|wkKã·ÛóÚ]ùlŞ<Füõ`Şíê¤ix¾Ş“@gÔŞ£+ÿ–L”Ë“¤-Q~·‰H&s·Æ}Ôd@ oVáÎO@™ª¬û”«që=vfÂ¤Âc4YĞAœ€
(QIj~2šÅuô;bGWø%Ğ¤YY…X¹QW9s<üö¥†Ê	Î}£#˜¸ÅşctKâ~õDÕE9ÆŒ:¤7gÄ©[ˆ²0	Ê¨˜Ä‡n<~…çßVRİû—U÷şeø¢;Âòç6.ÿ©åñ€>ôÔÃ IÅH‡#Aµ<-Ã=úø;zçAÊ¹¥Ì¶RŒHq¾ªƒ$aNÿP<âdoÚ£SI9ç½¢äÄ|P•Œ¿şµî(Ó¥e”O=!uT$
›}Ù‚g€—„‰%;Ì„üMƒÈcÂ0NÇmU|çm+)€x²¾„àÄ&Vqdø}(ŸdïÇºQ51”­¸SÏ¿ÔcşÂ©…¾CÔWr!ñó±Ò¼ÏY†Ø#L©8´4M¨·Ã…(Ã«gßm5Ù!JR¦TÁª³vô¼"ëi§³ËŞ$7öÄì<VàHñ]Åd£öa4û<úø!B¨y<ŠËbUy*³Xå2m£oXako+91“ŒÊ¤ `Ø-g“zHiÓş‰¤Nz¤œEM>S&ŸyÍ$ü¹ï|¢@ÁYÅš6‘ğç–Ó	>Kr™îômeƒ™¶DÕ|á(L·È›r­›ÀĞ¯\„°¼;°j
•»¬é ÅÆ 2:c_*eşŞÄ¿*ëø·wbgºº*!Q
Ó„oxàd‚ßDï›¤j’r9+ae^ Â¢StL˜]ˆõ…ÍñF·FªîÁœ-ç¥/@°uHÏhäÂ#N\scêbªÊ‘¦ŠÔµéßÎ
N·ë¨›J+=ËÇIÕIÂ9#İ<aØÂr+>œ'öL1› I¼L4…H÷§wRÀ%j‰ñ}2â„ú‰6 ‘ˆ2”®	|dpwÆ1ÁçËŸÆhÀÓ—;/éÜ_˜DW5.Ëq(‰=_$$-ˆïÔ‰Š¶Èm¶\"¥•ôKòÚåqÏÛ¦‰¸´VúC®4Z–SEÏ+tÏ/
h 3mº—FÌh?Jœ‚buŠJ°¾ïè(ä<kVcç«Å:ÖHUŸ'Uo)«ÔeïdÕµ3vù(LUKRXáĞ¥¡Ãn¿yq#:JûÒÂÛ6T¸WÑê…ì:<Ù›¤ü"'ä©Ô¾~šœ‡sJ a`ŞÍÚfJ^êâò'äıú©÷î"ù~Â*±£Kí	ël¥Tt[ÁFòª«ØÄ%¬’?ºŒMYÃ*%¢ëØÄEìü©øÓûæ aY«™)‹ôïWÃNÌÙËNÒ/²İz'hÙŒT«C°íı×÷sNÁÂ¬JN•§ ³àÉtŞg`o=½`—Œ›°>‹‡…ôôH¡¸£*/$ÓïŸ²cz$»îşf×ÒçP&îÌËé‘üqï`_¦G²Ç×yv%=¹„âù¬•é…e(¶/§5¥¡+»Ñš©•PÒ'‘ŠIlTT!L*—€"
@y°¦'dWÆ²òô¤ \“`czRvö‰Ù!]Ë®JyëBs`~q'ybÁ­ƒü¡ÈöšõTô}
l„^_Ø²±EnúAàiO'0,Ê	Z/K‚šéeU§iú®Tİ‹_ŒBò½åˆ+óJèø¯õÂékÅTûş”Â">$Æˆ¸ë Ê§ÜGÎ=%ù«arßõûõBä±#i	Ü¿&ûã~Ûá¶\ÚÔ¦8EBO4°RÅ¤'3K6X³Q!Pº(ï*cïŞ±ˆîÕÜİi¡)¿â7Œ›ïŞJq5ßXYÎÂŸ²ùâ*m¿³¼²¶ÛÛ#ÊT+K#÷i…CÉ˜|®tR--'@ù(~Z	ÃFÑ*¥Á-´¶¥™Ø>R£RŒiü“aÜº2‘”Ş'ß×‡S‹\&¸•j€ü”eÃ\v*|U¿ª`ÀSiZ.î0R’«ü®ámg8tìCàÖFN+ˆ®Ğ ÆÙÎå;2=€X„éÊˆxËƒ ê•,åBèbMËƒ.pï"+¶Ã††ßí¯±¡iØ8tŸuA.ZÎ¯K@ÑŸ‡Òù»[qá`Ğuä–f+®I×X)…‰Uoa²bk_"'øÜÇìÊ„ÿm•lyK¼ÄÃ&á1>YøÂ,ÇIJÍ­²$¹Õ=ØØ":ÌTÀbKî%¬WiõG)¯‰¯j‚‹½í:@äè—€|~?$ŸÄC Q
F¬p}ñ,\Ö™€i€ 0,±>÷Láö² SÖDÃ6öùÙ.Û±JÊñÂq¯·'úl2çI<°ãÏ·ºïéJºIiß²0ã*t*ØJÿP g¦T'\„jféàBŸ	M¾k0o€'ªÉaÊÄëù¨ ©WtI)J¾x¸èó­Æñ–Á=gW¤³;—·ÿ<6=ŒF¨ùF™@ÓòpQñ„)ûLb×ÎºŠyƒä)´w%’»¡Ùæ•¦J¥…>áîN;ÇG³lwi8ço4p1/Éj%)×£{ç”U½€0YN)T‹’öÜ)ÅÖ#Å¸­rJ¡ÅŞ˜àQ'Ïê$ì¶EÜì$u:‰l‡Ÿ¢„'KPj‚‹tÿS·ëIí"ÙğHŞ^ÊÆ€ÄK³"¦[,Ól‰ŠSÎ‰L&f)qãaIóà¯Hƒa›à>—®ÕìÏx„4¨1¬‰w¿‡›I1 ‰~T‘DšW[Ğueº®mA×ÃµñM=‹á…˜I¦wˆzÂùN(œØˆÜ]óÒ¡G(‡g™ !üH‡Ó/Ş¬ô„ûa¤j%`\Z„FPkL®øÑ©&ÍÓŸ1"uVÈNâ (ó ÷mH’àÜ¾¯ò»L;ƒõFĞ|†Ágçâ9Š½ÏÂqÇdú1(T)ğä™<?J“ç°Î,»ºk+>*´¬+æQY˜mÃZy5Îİ<$ök]
y œF~¶|õ„ax
+8-%!é¬\LÏ‡g5\ŠÃ¸@éØD`MC*š=8ÁˆÚ;FpáHzşø\à%Í¨)"¿$G*@Ö5¸µ*õ`Û’Æó).ôÉGYª©åùñÒ	ø¤ÛâÑÒ6òğjz—[çB¢¦â0[Ç¦f—b İˆúlf4"òc6dE$ÁÈğ¼+´=…{¤Ú0^ècV©àttÕ+úü¤ó‡oZ<¾ıåcG3ËÌØy–Ïxßè%á64øH<B|Û‰Å¿ç1”c/©!	XhBWOÌc=[È|î~÷{„—ÏƒÖ1-ş+ÆK¬ÔªåJu}«\©0øQ]¯=aŠ•xşÄã?vMÍsx«ƒ÷P\pûş¯­/úÿqÓ}ØÁÿdæş¯UÖ×+Õ­ôecc}Ñÿñ`ÿµ›­½vqØ{ :€›ëëiı_+oU+‘ş¯•k›‹ø¿ñ,Ñb˜.eâêÒ
˜voPáVÛöåÿşOÿƒ–2 hõ·gı(İ&­áh€{<´÷l„Q¬PqãÑÚ„ƒ7†U¤s÷´ú…¾tüÔÃ¼^×™^‘5÷õ¢¯jáT±Ac€{ö×AøSlVr°£y=xkÂõÂ@÷ghâó4ÅóĞkìŠ¾cœPÛÄƒÕÌâNµx ¹{tƒ¦›ò8œ"’jpY?€‹í‚ÖèØâW"BÛ`ó?sñ¬.Ô8p(Ö‚mb{n‚şêš[’Œic²ÙÙ[cGÍí5ÊôrF°‡+—¯W}«ÛG¬0Ì)®ÑÂklZd¼wM¥ÅLfU2Í*ğF’Á5wÄnZ]™®®
²¬ñ8«ZMy–¸€í.mœ‹åp‘†Ë}ÏwÇ]¤‘@¦;³lX™Ğa’úš6¡Œ4l­á"_á.$éfÀ(Ù=%dÂ‹&†sÅÌW®åû¦0.+wááÖ@ÌÈ{e×²ÇØë½ÿıÿ`…8¶(ª."åšÊŞèÌt¡a‡fåıF©–a³ßšw]êø®éwûT¿5k<ïI£î±¯yü$zO,%—Ğà=Eº+kxì¸yÄ×—hDóx\g-´,}\D–Ån-²78@€I_©¢:wòÁX±¨Ş_€è?ıÓ?Q rnƒü€«ÿ±ÄŞâª­ÛóÌw¶Ròú0V{¥xe¬ĞÏ` âB¥R¨ÔN+ëõê×õ¯é€àÑ1FÕFãs‹EW^AR.VòÍ4h3^;;±0İ½º–„ÈÛBÿòü}Æ¾UÜŸ½cá1(a%4å3„6¾¡ù/LÎÈÚ¡„m|önbES°(„_±‡ß7»B”‡jíÂÌOw™Î´y cÓ=s`è9Z„¦*4Õå3p*(²=œâHèÈËä‹<Tù„ª¦=Šİ’KÃC«…Û_SÚâÈ‹4„±˜Òy!ˆ×–/N«¢Ç«ÀX5IUPäää*Bbæ½ÂFc¬~å=hÆ9I‰dŠ·ËzÎ¹Še mCÄ6¥°7i#‹q×«H¨hİ¹S'¼ày*û'[A”Šå,˜ÜJÀæ©u'ˆ6¥n
ñšØdşir?ŠûÛá]¾œjfLfG³Ìé,IŸ‡B_]=@!nÀ÷(GàU°¡\áluUŒXÃXğZ¨9
‘![H®<Bé^réUœÒVÙŠÔSxäÏ¥3 ™“ÇÂ›h	pÎ¸—¿èÍaƒà<Ty’âD‘Íaš½DQ‰ÎâËE{ñi½Z»ó|ûŠî89óÂ¯¨ v(wà\á[`o§x
w%ƒH::À±PöÉe_EcÛß®¬Ê^–M!T’@”ô“Š")O58ü„æª‘í”e¼úd^âwÉ½ø‡ıXSÓ™6…[øw:Çb@	”›œ›GVFrœ£ÀO\SË™zMÀ]p©óÙQöÍœ]ë!
Uz›ª&uKr‰)¬ÔF§Ç.îĞóõeÇï}hb¬éŒ¸¦ê”#‚ı*Sø>”šÂ7z”q×ØêÈh&ïÀ2š,ƒQşé¯ø¶¡L–¥òıÖY)RÊø&L?|øS»ÈCIïç{jNª?|ÅÃ±Ú»sá:>ŞëÓKKŒ¢ 2#F†åÓqÛH}rÄ¸Ş(ò:‡Lµİèq-%ÕEÛ€Õ5#Y®Ş)Å6Oø.¸&wšŞôk´ËlVÓbºÅ”ÂŠœ^‰0\
(qÔ&“±×©‘ƒNEoá&e@jşy&ÑÒŞoáyÓÄ¹‘«6hqğV$ç›#fœûf0/á0Ò×ø€@”Ô÷ Ë q¾‡µüo1¯@>Ø@Ü/ƒŠ‰¿ÏL<¹ÃVƒE…¸î"…ÛWUíã¾Á¸3lÆhÜÂáfÆÜs
Êøâ²Ã Ü•á§ƒ ©‘-Aú*×pi•ÏêŞ	Ú	ÛŠsÖYZw€K}iİt»}Ë7É’–É<¿¼¯JCj²h¾rÜ÷|1…PªöÉÕR¡õvÄ±7&3 …½B|¸«ªÈt§J`t(ïÒ-ËÎ~oâõ³ğ•A}Í7åºÎ”ëºõ>Ñ~¸ŞåÍm½êJ¬ˆÇµ¸²ŸÑn–¸4–=ÖuÇxbŸ÷@Û¯
ÛÈm¢C®©ÙAÃ\»ô‡.`"w›1H¿KZO(ú| c¨uzêú ˜G½xæ,¾òJ¦†.:ó­ÉåÙšpÙğ°W®L@¬c€Œ8`—î¡+Ş<DRÊD6	B½9¡{Š™Ì'~K\äùÄZ&-˜ c‚ûMÁŒÅ½ù·:ñQ®…~AhÂ*Ìå.½Ğ~–]~ßš'C€6ÂWX¾Öâ°UÂ‡K;‹‘S£²HÑº"-Cmë˜ŠÁ$Âµ«Ö§á¡QŞ™hİ˜B$`òã÷Ëóßx–öBøy¦p³…4'G4ğ[‹i14‚˜jO¸‡Gñn“6t”¡xÓ;§0ôı´Ğóûø=I½"Ûu²|†ÄÛ/¤ÇQ@ç¨™D?e®$c«9æ¡–Œ@°°â¹î e0"ÛH`·s•.§PõĞüÄGuKY¾`¡têå
G8 •‹®¦v1í¦Éâ˜NcƒÇ}¦ATd{ì4¤ìĞ¤-ªÎ®q§…­ˆ]”ó]7§ÎWy‚ªíÕtQƒ8DG_Ñßxò“K©“åU¢Ôb²Ş.ÏU«&¾5–ëöœ³ Ê¾F)‰­N°ïÑíâÊ>ibäU'-8»d¨¯÷©Z5mÙ«@¿@Ë²rëšJˆb€^Ì.’F™ÊÚd$'¢‡s¯mr* yQÓBÖÔèWšÂ‚.ÍºR!t,¨cHWßĞ„DŠb´ºcÜÁä7¾•&ê4b¢
µ‹`¾ZÌ	©ÌìøâÊ®(KèÄq²ÚkduÜññé•Û I‡äºíTˆCúC8c4İR+ÓÇÊÍôVK
F,ÔÒğ¾FÕzŠñ[Ï˜Üj}b Je˜¨ùE ï¼Rü VªgL®T»q*E#Ã9¬
ØmjU‡¶Ï’Úw§J+$•ÙÕoàá3lÒja·µó‚˜	÷£Æî©Gî„¸;zŠqiôÔìªHÇ&°~@yá•*<°Òî»~é|xU©«ÅJ±V,cGpqöÊæ»f¡•.æ¨IT*P Z¬q’¢ì$·;¸T®ôCï}¥øu±|ZY_”ù-Ş%ÜèŒdäˆf…¦æZgÔPK•Ğ	;hqÌR$´¶Ò¦®ˆzJ¿Š[L“xaÒÔ%vÆèn'¾ú"Z{ÍıOm¨}ÇZ~7ÒŸOR­”¯3<RÇJ8çİ•Ğã,p¼Õç,ĞWà'°@IÃS
="»N“$ ¢d)F8t•×8ºJœL™i;r;ìd@‰Ó"¯|0½räŠj»ëÌV3-^‡
ÿëğRhÏ’Ë`Ç6Ñ_ÃFÁ‰Úü™si’®¬gsæ£7ßNNŒ%°¡ø‚"ğºz†&æõë…t »ÊM_¡ìñ÷°tå×ÿğ³¨<“@—Cí,:@µvGëqy~‡¿ÄNÚˆúâo‰úµšxÌ°ÂA¨€¢Ñ¹’ …F†éà"±»’ÀEMÓF"|%Œ“€‰^L¢œÈ«hï±Yø¸§p hÏØÇ(=/E[cô·ÛpÙ/ï3^ÓØ§‘Ï9X7¹VíR¯LXJTÑë½ĞÂÈıR}“D‘dk2ºıø%^äƒ‰¶Ä;¶ö1Ï‚µ£¸€‡Ÿ6O_Ød6Ä”Z‰‡%
@ü•gêßÉ$ğRªÄšÔ]L2ù†‘D"ª¿‘u¹‡P`¹7À}ÇË£‹[*¤ós ‰+pÔœ(?uÂLaÆ¿ÍSx;c_Œ!QÒ ã·Ù@«l¨ ı~ÒïÃıwŞŒ³€ÉÂM7$\p18™øq
EüÁz"< wdK¼µ)ŒvŠ/-'"~Ã{+<yi ß&	+¶ãycUb‡“òÓÎåÙøi†Ú"Zıúˆñ¬~ ©ô/B™ÀÇ‹ô¹—¹ˆT0C¼}	ÿÏ–Ñ2ÜûoºïVú¾?òê¥† ,^P¦b×–hP€jR­cì¨”WÊ×3™Uö¶ıüş.80/„¢ pÌ¾;°<éRâYóXÜŸ-º‡RoQ¾…òD¸]«‹»UxƒÉ*4kó¤ÛäŸıĞœ2eæ5&=ªÅr‘}ïŒ¯®™sF{aL1£k©­ˆ"ÌğÙ·ˆ`wuuU4`Ñq/J¢:¯´»³İŞï´ ôèg·<ÿ›ôr°Dyf<ÿUİªm•+[U:ÿµ¹¹8ÿõö?íÈ•¨còù/ø½)ÎÿÕ6*µò&ôÿ:ü·8ÿõ(Ï_üÍ_>ùó'OöŒ.;è°ßË)Óüü©ÂŸ?Â|ÿŸ³l‰ŸXâ¿ÃŸ¿dù³0ıoAŞñ˜YÄ3ÑP„Á—;˜Ñø_æ?â¿í¿ÿ?w¯v.Ä'âÏö uLÿ[Õ­Èø¯m-Æÿã<K¿À}‘Ò{rÌšm59ãğr;½:Ë= àà¨jóå{>ö,—8-ŒÿêŒHQı%ëetåy«“‡2Ã¼Àójx™ŒªUõéûº²Qe/†ïŸ¹ã‹‹5ÖõGÓÅã§€6Ú£Šü©«Îğ©9öû+>u|ów$H	e+°É£×¤¹bú_ •U(İîY~P:·bt›ûO<¿æĞB¿ĞbBüÀ³™—j§±,òÏ¦…>ÖË^WHéÿFËu2<§ù7ğpÚá#nÁÂ‰æø¦'Q§5½ğFÄãd 9Ãš>Ø\P+Âµ®%…³ |¢Fàr€Íû^‚ÔbßYx4ãº¯•§ÅòV±Z®lBó@Æ0y_±<Á<w(¼:T\OïsÁkÛ7>ğxİ<j¼Æ»qæ¸Œ(Ô©4–OÆ¿9é×O®Jìm$ Ï;¶,sv{ı†ë,ürÖP\GÃäJm@ÖYb =%C7š!z‡–’·Ÿ˜WÉ0H†¶ş0§s¢¬a3ºŒI&CéFxñEL4¢«‹Rj…ÙAÍ‹áXgm/'ôËÙZ¤lÊµv‚ŞvénÄœq¨ hÿl•) ÄşW º$“#š0Fæ¸!«løú.-ƒ!w[´¡ 9.H?\ÿØX¦Ÿ° ñíå`üRè{«z]C&õ–Ö“!ŞyñœEîÎá`®âÚÙ†×`Rs^är·¹ıo9ø: ¯Yu,g•¯è ÏUj¹p¤ÄsAª–N<¤B® ›àãô–5HÍ%wwrn>ÖÂü 4’±pgIà´L
=ñâbÔX¢‰NŸ§*¡Eå7ø"o‘IĞş]Œµ¸»Û<n7¶Ù F
Ì„Ÿ((E©ØXÆ=V\æî:Çmcß	2$ƒ9¾»ÀÀwƒ$'%Aó";ŒñÜ*Ñl³j9È²@0èÂø†ÑX–Æg(¶QÜÃ%n‹›·+N¦w¥¸kn@1†‡P¼ÛÁmõÄ¥å4–/­X¨Cß8H5&–”jß7–5ãz¡ -ëŒä¾A"I`u#ªPğ]ÙÍ \€İkí³l×n„.{ÖÍŠïr–”Ô`KÅÄ?/2ğpîµD«çÁˆ6ç>mp‡±HØË+høÕNKì‹ äÜ­>(´c­4&·"æ'7gù'lñ|Tû¯£uuÌnÿ­U×7×Y¹²±QÛZØåùÂí¿¶°ÿşßÙ^ºW;OâÚjôOÿÕ­­Øø‡_‹ñÿÏÂşûyí¿ê¨ûyšÅ·iÖà¨)Xõ‘\˜ƒïÂOİ<“òóàğößüÀİé&Õ¹â~fÄK)n€èç%å¿äáæ˜iú­ºÿ¾…ñŸóÿÃ?<ş¯rÌØEq…E®ÉÁ¹?TÅ:k~#kJb'H]©M2ÈÔ‘z¤˜ø·[Æ2Ü‹¸^©}ı´^Ù¬mÖ×á©ıôë§;Á¬Or˜£ùÖ1mü—cñÿ×76ñ¿åÁ U]GùÖ÷?T6ÖñÿåÁxe]Ç]úckÑÿñ„»®Yû¿Zİ X§ûÊ‹ñÿ(O$JàƒÔqûñ_ÛªTıÿ®ñaê˜½ÿ7ª[5êÿÅı?ôÄÂq>@·ÿë•Åüÿ8OJÄÎ¹ÖQ¼ş«”×kØÿ•rm}s}ûÔÿ…ÿÿ£<KLKœYb/Åı£AL7»ÇÎÇv—N{—ş‘3ŒÛníü«b˜("¡¾ò¸Ke—\*Us<İ¢„QáÇ#Ú~áC/“á—ãßõÅ¸(Î‚"¬½ÊÕÈ™{Ç“UîN6r-÷ŸN$ÙÏÍ¢‹çŸäøáó­ãöóÿFµ²8ÿû(Ojüø9Ö1eş‡õÿVu1ÿ?Ê³púxl§Ÿ¬—Ç®iÑŒ"÷Dœ5„?Äc{\TŠ•ò£z\$^c‚âU½Á/o™œQ\l2=£¸ï3~$õ¯ualĞËĞ¢ëœ÷ôÆ;°±A/õ#ü,—ßgnJŞŸè“tË¼ë˜2ÿ×ÖcóÿúææÂÿûQÅü¿˜ÿgõòñƒsÆı;ó½‚Â¼á]™æûÁ5;"€/¿{€qã(ò™â;ßÊA?e«ğ_È'bá'«±+ÙXÁg/^íîâõ¥ğá7»wf»}öìYp{§Ì®¸Õg¿¬d€|==Zv×¥ uÆç#by­ºV[[_ÛXÛ¼9wö·Ú{íıãæ—BUaz}<JV«DÉÕYéÜx;‚}îyøs=S®ë›KÓô¿xû¿ë<şßíÿ-ô¿‡æ6`ÑµWÓĞvìsĞ¹|wL÷ˆ#Ç=ÖáŒ…¢â3jgX;ê1E;%~]%äS´µb’Î¶¦«k³3¢±©™QŞ*-F ~€İ1¢’É<•b¿(Z˜üò
tÅğÒêì1~? æå¥õÚ¼kÀqØõÌ´)v;µ4ÒPE{“å´S9áÕjRj„(¢Š 9búí´ğ4z‡‚	ÈCélôÊÎ^¾ÈšüK¼´m]¸Ìà¸·§A	Ãİğ^§3óïıÓ…Î–_Ì,i¹Å½¿Êå2uí»7î9¬;Šó¿éeE3Å¿¥HmN]‚ÏK&TÜ:ÛEHåñk¡õ=ïÍ½DâÏZKOŸV¿¥[*nœ6qg íŒnÙIè	<G) ‡ëó50=qŒÏòS\Gl‰e<–XI¸&L¦så"¬8ôlÍmñâıˆÎ„c„`xgŞ¢ x—Q¢È7Şìv¸ G62oÛ÷¶éã=Eè§ÓÏ4ñâØh"Ë¼rù]æøzd6ø„Ü¿oˆ‹¬_â l8âÊÙÌ(ƒ,ÅÑ‹¯K8lÑ­àøîÉÛKJˆá©Uíf—xîöeKÄvoÌ³]çÂêâU¹˜3º¬3‚çŒTp€—İ3ÜŞÁØıp%ÚWNB„¼#êâš»1|«€Õr~î9ı6Oê-Ğs¬cŠş‡î~ÿ_t'Üÿ«-Î<Êó¶½ÿrg¿ı.sD·=ƒ "óˆTŞ „ÿ—yû²½ß>ÚÙ~—é´·_íúê°Õ<nwN_ï4O÷¾ça§:¯1tKãÜxóõ"[<ñ¤Şõ>Ç:¦HÇâ?lnÕãÿ1Ë¾4mœ¿O¡Ïcs'ñƒÈÁÉáôBÓ>7ö‹ç¾Odü{§Á…7s3MµÿllöŸuŒÿ½µY[øÿ<Ê³°ÿ¨öŸ$ş_˜€ÁŞ²7ú¬ğÈ3ùÌ?Ilğ° dÆ{#Ğ5İÃ4ô;š‚RaÏQ&ül¬Ajì‡5) ƒÃö~«s\ ÜÈ&ß\ÊêÆŸJäZ×nÏ3epnê)ô0¨Ï?-@R5õL)éŒ¢L<yq‹¢®ÉY[I¶ıTMC‘ó¿<¤Ê)²væRÇTÿïZ-âÿµUŞXÄÿ{”gá¯E;ê¯¥‡Ÿ¬óVpa¤îºª9)o6Ià_kAŸşT=º2= a¯Û òùÈ‡kğâ¸™^·Î‚ÄŒs†{
İ¼ §¸†mıH.ñú˜I8Ä®İ ¹Ó[K‚İ…üs¼x¤¦î`Û±ñÖHÓ šLÔ©ùç[AşÜ¢iñ,Å³xÏâY<ôüÈ»t5  