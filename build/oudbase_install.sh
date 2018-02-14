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

if [ ! "${INSTALL_ORACLE_HOME}" == "" ]; then
    export ORACLE_PRODUCT=$(dirname $DEFAULT_ORACLE_FMW_HOME)
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
‹ ®ıƒZ í}]sI’˜îìóÅáéì‡sÄÅÅ¹ä,	.ñÉ¯f ]ˆ€4Üå×”´³¢–×šD€n\wƒGâ†áGûÕoÿ?ø§Ü/¸ğû½ø83«ª»ª? ©ùèš‘„î®ÊÊÊÊÊÊÊÊÊ:³ìò“N•JekcƒÑ¿›üßJmÿ+«®Õj[µõêÆF•UªÕÍê¶ñĞˆa{¾á*cNÌÙÎÏ'|íşı‘¤3ègÜ;…æùc¯äõ Éı_[ßØ¬aÿWkkk•õèÿõµêÖVy \bégŞÿ¿(#œ^?·ÀŠóK mq§Wg‹s{ìZ—FÏòXóå*{>ö,Ûô<Ö2/Í3š¶Ï~É:ãÑÈq}¶ü¼Õ)@™a^˜®iy¾kxÉjOWÙ—Õ{90|ÿÌ_\¬²Î•åoºÃîÍé}ch–xª3mÀÁÇæØï;®øØñÍsÃffßXlÙ1½óè]É¡w¿ñJ]g¥Û=ËJ/î¿İ7ì³÷üš“¿eøaİjüÀ³™—–g9v,‹üÀ³İ‘ã™ÒsàÖéºÖÈg¾Ã.Lø§o2Ë†¦Ù]“ñ2Ãc®émÖuz&RÂñMObsÜ‡~ô8ø54,{pÍÆÙcçËLûÒr›::§ïŒ}vüºU„ªáá}İ
µ!°¾ï¼z¹|9ÇgH2§˜‡"XÜœ{·yØ7ÀU{]‡ÇJµTyZªUª›Œ1(ŒíØ–oviºHFÈS­•ªUÌ³%ó4{ßB3šğ3;6sÎ‘S ¡¥œE¶•:Cë{ÃÄî=g~ Ávğªuztpp|ÚÚo,~TêÅ<°C¯ä¸ùB m÷°÷Ç#GàZ0FÆŸ½6cÓ»Gƒr¯ÛGƒıôf®uĞ<<lï·ùã£Wí<›1- ïg“œvnÁc42A° ìçv#ÿ¢¹Û¹<à3‚lˆ£©³}´sx|ºßÜk7—‘Ãm3l±RÈï¶vÚÛÇGß6òe8ÊÓË;»PûâG-ÃMY/^Z\Ìç:ÇÍ£ãÓoÚÍVû¨‘§'Ot5tÛâG¥ö¶üšs8¼ä»)Ğ˜e‹+ùÜ^sg·Ùjµ;ğôo×€Yêösí££ƒ£F%§rÄı{’ƒ{1¶»ÈT÷an¾£ï\àÅ^yÆ…¹\`£²µey£qÍ3Ì¹vd§€‰©éUËÙó.X~gÿÅ«óŠW£ü¶Ø¿tYÑb_ãèŞÙØßn?cÅûÔˆ^k~ÇÂh¿rÜŞ`şgì]R%ŒûIÌN•³e'‡!Lîğ”Rü2©xÂHI)î&ïöÍî{š~\s4°º$—R (í“dßKdß:ëÚ–åš]œ$ØaCkÜp‰¤{oØH¼"Y’R:Ö-˜àLB|JN*·ë\x‚	şãîÁK”7<ŸuÎŞÂËê+^ø¬ÂŞ}…ó»“ÍÜ˜†İ´{ÿ0¶|oñcí†>›˜ke¾ˆÄK._aôşÜÊİäæ>×%­=ÎX\FùÖ–áè¡†:Q}¹ûHíÜÙ?|u“dõ‹úÊMR]×xo2Ğlİkö;3áŸ§mä5œ@İ€Ú•˜df0Û,l'18ßU“[Ğ'yx`ùcÇ;{íSà£½C˜Xz –°ü¯¾ø¶øÅ°øEïô‹oê_ìÕ¿èä_}¥=:J/jO)L³”¾C½¿ÃZµzóy5Ã
ÿ®e(%$YÈôŒn8ò4¡!ßäYƒ	5 :dV©.LÊKutûæq6ÀA”gŸ|ÓdECAIm\Mdƒ!%z}ëÜ®ú8î	k¬ö€/áÚs´*nÛ²­ÈË©­KládpZV¥¥ñÖöÛŒË¦9vÛ³gImúQ?ÉÙ‰÷ò9‘ê„€J‹ŠnÊÀÆ#ƒ ½@0~°üP¦M|	Ê“ ÉUÇAöJ!˜sQºÂLÓUqUU²ƒD…ìmh&Û-†@—ØX_0cèŒmÒÄ÷bŒKd¯Ä:0¸Æ4­¡xï:.êz¯¤VQ›µ
	˜-ãÔ^˜şÆTøªVBj°hú¶ãS§z8Ñò¸ùü†AUğpÔÜŞmÚÍéóf'B8 ôÔZ©Õã™>Ö^—†5@íQkOµ:ò¶3ô‚ïŒ»}¾âÃvid¿˜côØÉâÇo€=Ê%‰¤
nmj{;Ìöm¾8?‡†™=µüúÔòm×
!:=Ò"ôâS[Ã‹SïºcÛFıEØ„ºÎphØ:¸ÚÀõ<EEO„º6êåy¤YÅµl•£gá­G#İ¢¨¸À¶M.¿öLÑjKZŞÀBY‘`HhÌ¶1#=a )4ÄaiŠV`GË#•îhâHŸåHñ2<•!¿GQˆ[6üòE–‚ÿÓ§…ÈJå·h$»2lÛ`èï}c0p´aúë©bç•ıŞv®lŞô}¯ˆ™¥¡ä&&üuœÌ¡s	jµ‰
5óAÑP9q‡ÈÚ³rÏ¼,ÛãÁ@<Pğ9a;x17†Käıí} ó@ 9I¹ÀçâÂÊ½ÎIÕEfãª‹®¶pŠŸc¶¨¤‹Q¾””+®ÒiËÊZ5XW[ŒåÜ¡â }šqÒÑeŸ>Á—_°b/òYEP«µZÚ°®]$
'Å+±Åås”6áÔS$»[`ì-DGë ãì#H±ËöœĞåĞ ?å Slyº—`üås|
•A+¹ôkÿ„úûå/±›®X^±hÍXIsAèt©ª*kÓ.)v¤ÎqÂqîŸËrp{†u/·Âı¾kŒX^kØz%ké\NH ºb;IÀ	
ˆ€
:å"f7“uÇ UÙdN6Sò‚.\÷ÂñvaúÎØV/?r~8¡‰Ùp€.0ƒv'¾î¥YÿÒª·êßÕÛuµ½`ùÁYx£*²À—Ü2WQ„îe!¢+ß¬Û»VÙôàHóR›«Z˜ÛÑRr|'s¨¦±”¼nµww¶›ÇhÄaÕ.è\™å×²±5¶¸¢N´
¤…Ş>”1!Adh‹EmTws%MØÀœÙ5e±[Ï¥D-ê …”`ÏX0’aTÿ²šÃLÜÎ¾øk¨«OJ3q„‰Øu†Bô6ıäOZi´Û`1`j””0ÉßÎ FÊ1AO™x'ˆŸ›Iò'˜$®L ×%æ‰r_.`Y$ÿY/æ­½7¹î•ÅÔ— `ñãá›–hÈ'Ó/ÄÏ?iZ_‹w˜#JÌØ–Š9HÙˆöeğœÈY,òmÛâ¹k™ÀO×ğÆvŠ €†#Ÿ~ºÎÈt}ËôSxÅi6¤µèó×j›XbC!£ï‚Ø¦~¦3ÕLÍâ¨ßË×«ZvÁ#†Ø¶Xßd6zğ¦ƒï‡ã¦îg-¶ä•ÿ¸X.–—T>„Rß909=7ºï!/Ûiq“ôp<ğ­î ¢ƒC ¢|àÀ®°FğÍ>ªÑ‹åû_yå»ÌÊ_İ¤Àq¤Ÿø"W]˜˜bµDøéOBÚ`ãÛbs¥cº—°ªAÆë¨}²|ë
À¦Ë–bYÄÖ£ÙÓê.H¢ô,K´ºãF/]†U¢ê–èà®İpAÖ2ÍO|!–Ã¥Œ…©İVóşê©N.VÀ-~´Äz¡ùæw§¸7°l\½gKÏÛ/wö?uù»x+¤ô3ÿÕÎËıƒ£ö6LêW|AÓØÀ=˜*û+ÿ±Ùë¹Ğe”«‹5|uòõÖ²tò¬Ì>B£–×øë6o¼/8•¯Øn|¤%	½Ó{œWmÔê¼>² w6ª1]~zÅ»©JT’ê¼>+~š…Ôjä&ïçe½3·Ş!% ÿRFTƒ†—Ë0b3‚—Ğ#8úuÏìóBK,;u"{Ùâá(ğÍÖŞÎ¾:õ¤ÎbFohÙ3Lcñ¹+±¯Rç0­Iiİšh¶¾C¯®×ô‰Oô.—¡Íc1"€?)CÇC=ÿ•`ÜVÖü‚n$¯o±_ü	x}A’×7j‰Ì~;¯MŞºŞ¨i¬‹íÓ·¦ƒõè<ÖÅÏíñ©'éÿË]¸>‹ÿïÚz…üá×ÖF­R!ÿßJ5óÿ}Œ”ùÿ~&ÿß`ÀıTü…¨“¤ÜQ§hï§îúûe	ş ×ßêZ´ eû®Óƒêk·À¼‡€¼‘ÙµÎ¯C?l Â¼wÉçë>üÓv«'ğ­İ€Õ‡÷gäÂûˆşº	ŞÂÈ
÷pá¹Šv±â}­ô0¼šİe÷>şº³;ëÆqŞÉ†Ì¦î”x)¥cÍJïÖ€‰yrñÌGöQ}dYæ#›ùÈ²ÌG6ó‘Í|d…ˆ||GØ	^¹ÍS'¾ÌCv
üÌWõ–¾ªsòãü^…™_ßOÌ¯²¶÷_7¦zñ¥; òú Ô–¹öİƒkçìÜ oïÁÇW¿Uö`.zÃºUo“›ŞcøèuRÜê†Q± -.K=Oæı„¦[¯|²Z>aå‹Âƒù÷ÍÅï'ïâ%Ä^¤oDµRÅ–Øìç@ß8K´‹D
FŒ0Ê,Ğ>ŞŒCp`A-°®kâjÖĞ÷öÑNc2{tæAÁ†Ï®2öÄqóy#^QBF"ÇéîN7¯¹ÇÑ%[úãÂRxäèSwìæU˜ê…ø\$Èğ¦y´~#º&„ÈQˆx'	mOót3˜Òw°bÚj7oÊ+xl",5¶…·hØp-%}‘Òd¬ØjFÚkßp'F¢“6/$Ä¢E‚}ßJ+'å“eø»p‚X”VË'ÕòR!lšºˆ
(w‘Öö68Yš|=öÌIl-J\.(à"cˆè.[Z]bğ_Aˆ}—Ÿ±Í+ç–é Dà¡ß½¾!¸'¶ ¬·›Ï˜¾)YÔ	Æ\ZApFÌAW:}7‹ã>$NÛ)…S<ØŞ.ÊBïB	ºò‚#OÊ2qyz®yÎ>1S·<õ‰ Œ~8îEÉÁÍ¯ä‘ÿ_	Pf)¶Ü)*v•zú2”EGXöºÿP i<Ze3v»¦ª³•BUäU¢v'?ëZ^XÔ÷bC¯Ì)áœû^²âH:µüœ’Z;Gº]BC+½Å¡éŒ{™òóWÁ·|Ê‚–[/âå©ç»¨Ä ï,ã0+ÊÜ¢,€î‘ãø\šöê(QWkÈä s/½}[?öûú»wK…˜DÀÂ‘¢W{£Â,èæ »; ü¹=Ûo o–ö†Í ±Æu™¥òI~õ$_(/]„9ÊğTĞ­l|ÒÎx¾3Es?]ü(;ãæ4@í†+ô*èôîõhWO‘!Ï	p;­°Õ» `­íƒ½½&êúbA´³Sæ‹ƒæb±ïx>5‚N$àÓLs39x'¡‰¾Y*í1¢" E†…@6…š§-ãZXÌ—~õÅx	ÖK iVúÂD®)BÁØgtõÓûûEG¦˜'[8¥ ïVî·~.hßˆŠ4OhjóÚ³20ÏğM!SÊ}îò±:¹ NŠOC ò=²ªÕÛz–zö4Œ.Aâ2PIPry™~üªZĞåC¢ù<½Ûg§‹7îâÊî–Ù× ÀØ–×7{Qó{Øñšµı3VÏ¹²WAı”Í¿²`ÔÁŠÒtñd­Ù+åc‰â5½˜Æ.:‹xx&Á,Ò&iol’§õ9o˜ï‹ë•Šºüu.¡.\…"vİHŸ	r!E"˜ª	a>ş˜?æc'éÿ‰L<}ÿÏµµÀÿ³º¶…şŸµõÌÿó1Ræÿù™ü?ƒ÷Sñÿäúùún–àÿ)şŸOK•--Ïñî­=¤¢Ğuå.B×±ÏÉ–Ï¥¯ƒÈ~ô>s(Mƒöãp(­”ª?Úè²êVzüí!¶èÕîîÌâ’}öœ‹¦ãë‘™û]»}ØX¿l<<ƒÍ{cšïi°¾7ÍQdÍ]ùbQşO~ä?,Â^Œ‹ÌƒöÇìAë³¯‘Uú¾´ACƒ¤Œ0†½Uvö·Ú{íıãænæ“{®ıAùäfqk3Ÿ\ª#óÉÍ|r3ŸÜâÉ'w&—ÜÌ)7sÊ½›S®ĞíâN¹™3íp™3mæLû£r¦wœÌ #­_·êÃzû!Üh}X™*Ñõ1œlçÖ2ógÌ¼F3¯Ñ±×¨Ø›Ñk”Çû—…|4œË©ÅŸöUŸ®°ØÀ8;´Š+ÊŒ§e’ñõz‘aí˜ãÃ6°G®Ló=³ÉŸÛo¿9}Ónÿnÿ@±¹¼Êr»­ğ¬ÂŒ7ÅÅ¸pS(PñçÍíß½:<í´óx¥§P)bZ)ö.%¨ ºëa“
‡($Ö»¨k3v5TGÂğÄ‹°â›éÀpkfÅ±{!vVdC‚¬7)óf÷õãÔ7°È	àbÉØßŒÎ>
ù+T]t_eÁIä”ãÚˆÂ½Y©âOobÃ#¤‹¨(É—UÀ#;Üy.¦Rİàf†6ÌÒ³‹u\”B±O3º‹ª®¢,©ïÄrCo;ö¹uvãu#%C¼¡[Xñğûîù,4*«~¸fÉ¿ø/ó¶ö_°gi­Ò4$_n€{·h[´è<‡wšPÓN4å†
M+]9xÆp¡Êã¸‡vù(‚~¦ÀRcš/…ÄC7™è»‘ÕK£s•…Ç± VÄãxvoãtOãç‰ƒúNÅ39‹ZîìP<İ™8fóOg½Ä&Ïà/Q·›cßÁ«rº” )]tÓ’ÇœAıu ÷ê4Í'xŠ§·Èä?Í<¡‰â*@CÕ>f©KªušNw#w‡¬è&ÌÄé;3éÍØwÔ&œ;cĞõ—Í‹R\AJ@ºº±#ïø™“«·@/sõ¾EúÜ®¶?È„Î¿¥ÓÀÌú uLöÿ®TÖ+›èÿ½^ÙÚªU·6Y¥º¶¹¾ù?Jú‹¿ùË'şäÉÑeö{)šğİ“¿‚?5øóÏğÿìßÍ²y||ÄQ‰ÿşC$Ë¿ïÿúÉ“¿=¼dŒF³40<€q-¿pØ0ş-şõäÉßc¾¡Ñuq4q‰7àaúĞyVäı÷ï"yÑ‡ùl`îØ=óÃ“'ÿ©øÿ€¹ÿûıoÿÿ­>
£ı0“v£ĞÕ1yüoTñ!2ş××²øß’²óŸçüGà‰ÿc>ûÁStÏ	˜òÂ£ğäFô:ÑìÈCœ©ÄOô`u9RãDĞ¦Âæñ¾‹ÏÂnñ¹„röœî{ÓM<!‚@/Lÿ¡z„0òı)è+ß½7ç|2¡=9qÅ®1pÛ5q­‡n.—†k¡ã‡+ÿÕµüt´Ø6]è?rÈîjˆ4¯ìã™¡c”õaQîš¸_ë*àgeˆÈº¤¯
1îüˆ†kNËf%Í§#×Á>*ñ:ûb3k07Ûğ$˜üT|ãËCºLz%©5Qò2w7wwO·_uövş@÷)• å:t<Ò¢J‘7•JÊ(¶Éƒ'±­ƒõğëËhs04/®b<í@Ü_W*eĞËåå0¥_H˜Ğî‰ „`4¢ÀnôUÔXvËV…atìŠ+‹$4m»TE-ØsLÅO"S¶)LÆÑnªXşO‡É3ª½‚¾Aq
N¨±<´z½ye¸¦
úÅŞ	şN ±,ÁûmóuSETƒ÷03ëÃˆ¥¬Ò™'ìJcà›®ısÉG¥Õ)JÜ¬	9¹µAìº'Ã3ın9jŸ
ÖrHFp!Ò3pŒÇQÈ-ÚªlñøÚ¦4÷	ëëÄAşìAÎÌµ•Ùûu 4î†w‘uL_’DŠŠª¡dB'; ÷µÜ]ÏeçüRNˆ¿9 y¥ ß+ã¥¸Uà€=änrŠ	ÚFèÄÁ³†E#¹w¶›»g;Í‡z¦·+Ë„)<qf	VäNZKîLúèh(ª¡f@pA å#ÂRŸ° ğÔZş… rôh+Ü1ˆ„¢º
a~Åİ½‘k3H’Tşè/ş}±\^úÔ0PUJƒt1â$ßÜ/oX¼x~é;Ü^"ä·¢‹è-Ÿ”ßşñ¤üîW…k7„¦’tÙd\	X¿ëÅÅeÄc`ÙïÑƒ*ÙòØsË$ESĞFwv.Ğ§Œ’¢“jáCüó kãâ³ÔëùÂ¼È8œBÉsD ÜÚ9jo}{JrÀÒ§äÖ4íyFo(°:gK_œŸØKòI¡/º7JJõ­N»-\~Î¥éÊø&X ¨ æË®jVz”é[œM	ò.jiÆ…ÓâG½}7äQ#íçsÄóööıkö,rSõèøø[Œ$HÎ=t>jïÒÑ;8ˆk~0»cB£,<%‚‚¯¶Û-Ü·?içîî•Í;Wì£DüSÊ?¸Ï¶†SÒù‡“”?$®ü+¯9÷q¹sØ<şÏ-×ó•^tğŠĞ+E×Dè–/ïjxÃŠ3â5ÎFæëvëÇà?7Š·Yp5d˜+¾Ë)`	zæÜRÌ¡Ö†úâöÁQu?¹¡9Xñº;É"«˜(iò¾!Q‡+ò$¼¨Ì Ç o*Ü§’¦Õ°wU-;X™zå¡ÔœutPV2Iu8s@Ùdp|ÊŸçA`:M¹7-R4ĞÆÏÎ?WIÊÜ,¾Â.Iqø¶GË‰u99²3º?+
'áˆóíı—ïé’,j%ßÊ@ŸÖ€á`6˜YÌáÈ¿ÇP>æ/¼§'GHWÍõVóNY!G„bÌišæ[XFé0¤+":Ä\ı¥ó	š³„twé³i^Ò‘N`÷u›V8C,Ä²‰+t‚M:í¸ğæÌ¯ğNŒSZíÍW»Çª×M"Ã¨« H‘ÀñY«Jamr|-	ò\80…û\ö#|wkKã·ÛóÚ]ùlŞ<Füõ`~îê¤ix¾Ş“@gÔŞ£+ÿL”Ë“¤-Q~·‰H&s·Æ}Ôd@ oVæÎÏB™ª¬û”«ì=vfÂ¤Â£5YĞAğ&8P¢šÔüd&4/Šëèw(Ä®ğK I³²
±z£®ræxî‡4'8.aâ>ûÑÍ9Š ÖáBTgYä3>èŞœ¤~l!ÊÀ$(£bºñø„[Nuô_Rı—à‹îËÓmœÿSËã }è©Ç’Š‘G‚ji<ZúŠûöñgôÓƒ7ç–2ÛJM0"Åùª^	Ã²ø‡"'ûÕîJÊ9ï%'æªdüõ¯uÏDù^ÚHù„ÑÃ`"Q—E¢P°í—/zÖ xI˜Q²ÃLÈ¿Ñ4ˆ<&LätğVÁ÷sNÑ¶’ˆç ëKNlg•F†ß×òIö~¬UCÙŠ{öüK=æ9œZèD}y1$~!Vš÷9‹Á[c)‡–¦	õv¸0exÕñì»­æ!;DIÊ”*0lubÖWd=ítvcÙ›äĞ˜B‚Ç
)^ì¢˜,pÔ>ŒfŸG?DU GqY¬Ša!¯Ae«\¦mùÍ+lím¥1§3fb’Q™»¥òòbR)`Ú?‘·“’"€”S©É§Ëdš×LÂÓ}ç
Î*Ö´‰„§[N'˜ä2İéÛÊV3mªùÂQ˜n'w6,~´nC¿r%Âz!òîÀjq`(TîpM(6Ñû¢X­xğ÷&şU]Ç¿½;ŸĞĞU	/¥0Mø†79îxA¶!øMô¾Iª&y!·h%¬Ì1ñáõ",:EÇ„Ù…XoQ oäpk¤êXÌÙr^ú¶éÅğ°WÅÜXG„º˜ªr$¬"uEmú×³‚Óí:ê¦ÒrÏrÅÁRuÒŸpâH7O¶°ÜÀŠgã‰=SÊ'@‡M!ÒjÀİ¤p‰Zb|ŸL§8Æ¡¾À…c¢HA$¢¥+B\ÇqLğùòÇ1ğæÎËF:÷Æ&ÑUË9”Ä/’ÄwêDE[ä6[*“ÒJú%ùïòhmÓD\^-ÿq±<Z’SEÏ+vÏ/Šh 3mº¡FÌh?Jœ‚buŠJ°¾oèPä<kVcç«Å:ÖHUŸ'Uo)«ÔeïdÕµ3vù(LURXáĞ¥¡ën¿yq_#:™JûÒÂÛ6T¸WÑêÅü:¤üMR~‘òT×¾|šœ‡sJ a`ŞÍµÍ”¼ÔÅåOÈûåSîİEòı„UbF—ÚÖÙJ©è"6¶‚äUW±‰KX%t›²†UJD×±‰‹ØùSñ1¦½ñObŠEFlêãŸi âŞäçŸÛÂiZ—bÆ·„mX­Äò1e"ÖtÖUÌVX pÕx™HæZ,_,wON"¯êÄ?õ€Oë
ÖCŞRÛ¢óYz(ZôZ9}'iËT/wGŸ=KÃ1~2šùå}s`ÑLå”EXQ©ÌÙoTÊˆÛÀ åsry‚mï¿¾Ÿ»m´Cr>İc-ğ.k Çèï‹vÙ¸	é#6,¤¿Š»^óBòıı³“£NBv|É®;ô‡Ùµ÷s(wuçe‚÷‘üqw_¾dÅàÙ•÷É%_~­„|_\‚bKñrZSú¢-Z“"R´Êû	Ed£¢E]Ø$•K@EYT"b9|ŸU\~ËÊß' 1™ß'eY›˜ŞkÙUi ïi,Ğ“ï$B,¸•›'º«A³b“êŒ>|­Ûë‹#hC6Ö ÈÍËàZÚ›ärÇR‚ÖË’ fzYõ }Wªî‡Å/F!ù^‚’ÏÕ¥Ftà‹×záôµbê>Õ”Â"â)FÈˆ¸Ê§üÔäKò»Ää§1î×‘GC¥¥8,ØÑƒìèøm‡ïIsEŞë+ULÓ2S ¶D…@'£¼+Œ½{Ç"šUsw§3¥üŠÿ;:‘xË¥•Bcy)ÿ}ÊJ+äFÂÂÅ$É"OàTËcñÓ2‡R 0…ÅòI­¼” å£øË#6ÊêHC«qš©ø#5*Å(,ÀßhQÖÑ¨Ë­„¹@é}òá~8õŞ…a‚[ª©6-ÈÀÏ=Q6¼“hç¨ÊWçğ«ö ?ë¶X¤‘êØp#åuß½í‡}ÜÚXÔ
¢K?¨q¶sEùL`·á{eD¼åa-õJCèbmËƒkˆwÏ+ÛaCÃïöWÙĞ4l:†Ïº -Z+u	(úåĞqg:Æ£Ñ+0.¼F ¹e€‡ÚÙ²kÒÅlJa…§C"ärøZÙ3Z gRİÇìÊ„ÿmgo•y¿ÌáÁTYøâ÷l‘“”š[CIr«¾±5I˜©,€Å–¶<€QX¯Ò&êr>^ÿ·ÎÖ{Ûu€ÈËĞ/ùü~H>‰‡@¢ŒØœ g¡yÈL±`Áˆõ¹‡·û²*Ê``Á±ÏO+Ú]T²P{e¸=Ñg“9Oâ‡(x¾Õ}O—,HJû”…W¡SÑVú‡B’ówJµqÂEè f–Bè!¡iÍwæ0F 9şƒx= õª.)Å¢SòÅƒDúŸ_ s52½4lÏè¼"mpyûOcÓÃøššŸù4-7Â/ğ¹[*¸;¥m^iªTZ íÀñ´s|4Ë¶­†CpLóöı¨Vr£ìö*…İ~Jš^@˜Ş§Z‹’ûSŠ­GŠq›û”BŠİ<Á3T9KØ5¸‹J(êtÙÖÕÌeêa4JMğÆ’n¬
Âbâ¾H©]ä#wÉÛ¤ùxiÖğtË{šM\‘aÊy§ÉÄ,'´“(ñi0l2Ì¥kµ}<ÔÖD
Ï»ßcÖÖ@¢?`¤1›"w¥¨+®uÍ•¢®oêyh*ÄL2ešSllÄ7\óÒ¡G(‡gò !üh&€ˆÓ/Şö¬ô„m¤j%bZÌQPkL®øÑé<íÄ
¢ê¬ŸÄAQæA/ò$Áù;|§#î2íæ0‚æ3>;ÏQì}{8&Óó¡J'(å9Èğt¥<OxfÙõTïñQ¡e]1ÊÂüˆ&ÖÊƒR©‘“è.-áwàRåT%ğ³å«'eÃÓ„Á©?	IgåRz><“«áR
>”îMÖ4¤¢Ùƒ“¸¨½cL"¤çÏ^Ò<1š"–Qrìd]ƒ[«RhN!i<Ÿr$ùH–@5µ<?&=Ÿt[\"ZºÑFÂNïrë\HÔTfëØÔì²cC´;~ŸÍŒFD~Ì†Lb¡ˆ$w…¶â¡0•T[ÆÏJ„•D*8]õJş?éÜÑá›¿±a†ò±#F‰…efl<“±
nô«¿Ğ‚N.%²"¾íÄntàQÁc»Ü©AË	XhBWO@Íc=[Ì}î˜”Yz¼$|û´iñŸ1^ju­V©ÖÖ·*Õ*ƒµõµ'lãA±égÿµkºhÌÄ[]¼‡â‚Û÷ÿÚzÖÿ“zN÷aÿ“™ûã?onn`üçêÆÖzÖÿ‘°ÿÚÍÖ^»4ì=P@Íõõ´şÇ¯Eú­²‘Åÿ”´@¦º”1ˆ«MöÚëB¥]„[nÛ—ÿò_ş-ü@-ínÏú^:K[ÃÑ wÄÈS Ø6¤]¡šË£5ŠcV•¢mĞZqzĞò³vcp{]cdz%Ö`Üç‹¾v”]„SÆ:tz8\á±yXÉÁæ#â­
GUœ¡é[CÀß³ü1íºÊ®è;Æ	¶M§À¼!î»Q‹»G×±hš<Ã+")—¥ñc÷Ø.h-Şxg "´i80?ø3OèC‡"¬Ø,ÎMĞö]S#cK’Q£3mã6;{«ì¨¹½J™^¡ÃöĞqåbÿªouûˆ‚†9Æ•4Ú-—/ÉŞ»¦ÒˆR.·"™f‹x#Ñàš»Sb7­¬ŒWVYVyœe-‚®ˆ<M\ÀÎÆv—Ü„ñ DCãˆç»ã.Ò€H ÏĞY6,$Mè0I}
MPF·†ÖÀp‘¯pÿ^éfĞ(Ù=%PÊ‹&†sÆÌW®åû¦0.3wxâ¶SÌÈ{e×²ÇØë½ùÏÿ°B[U‘òMåotfºĞ°C³ò~£·–a³ßšw]îø®éwûT¿5m<ïI¤î±¯yÔ4zO ,¼p{`<ŠtWÚğØqóˆ¯ÆÑäèñ¸îZhiú¸‰,İZbop€ %’¾RE!tîLäƒ±>bQ=¼¿ ÑüÇ¤¸Åö7 ®ş§2{‹kÜnÏ3ßaDèjÙëÃXí•ã•±b?‡Ê‹Õj±ºvZ]¯×¾¬o|IÇ‚1ª>šºœóh|l,ºüZ’J©Zàh¦A›ñÚé‰…éîåÕ$DŞû—ïàï3öµâœùì›A	+(¡tŸ!´ağ¥áûçŒlCJ°Ögï&V4‹bèKü¾ée
 >Ä ‹fa¸Ëtp¦Í™›î™CwèôÌiĞ"4U¡©²F‰íáGBÇp/Æ4øUªš–+/—:†T7§´Å‘=ic!0¥!ËòS¥±PšVEWª’ª ÈéÉU„Ä,z…ÆEü.Ú{Ğ0Œn”r“*ÜŠí9ç>F(—ôq·A(…½i„HYŒ;ªEBÅë®°:áõ ïSÙ?iØ

¤T,gÁäŞP¶O­;A4°)uS`çÄ&óO“ëœøq×¹ 	¤Îèòİ¨àÄ “0{är;êœe~0Hg¡›4øU++"Üè#Äøåü¢
–”+­¬ˆËïp ¼jBdÈÒ†+Pº—\z§´¶,õ¯Kàsé@æğáM´8gÜ§_ôèˆ`ªAØ~UA’âD‰Íaš½DQ¹Å–‹öâÓzmíÎ3ğí+ºãäÌ¿¢Ø¡@Üs…OÁîE!Q¸+DÒAÖˆ]e‘\öUôn‹Û•Õ¯²eS•$ĞDåŠIE‘”Œ§z9Ä„æª7[(Ëû*’y‰ß%ùâöcMMgÚnáß)zˆ%<vrşmO1XÉq7Œ³@¡mgê5/tX¦F`$Ü[dGÙ7sv­‡(@ñmªšÔ-É%¦°R]D»èÏÀ×–¿÷E ‰æsâšºSö«|ÃwíÔ7|[Ly#îÚ[9ÍäCXN³‚åğ–ú+¾É*_ËmeùŒ®‘ë¬œƒN)ç|¦>ü©]ä£¼ïç•zjNª?|Ä#ñÚ³sá:>ŞëÕK{E eFŒË§Cö‘úäˆq½Qät˜j»Ñ/âZZ:¡¶«kF²\¼SºÑ á»h8âš<ŞizÓ¯EÑ.³ZFN‹éS
+rz9Âp) D€˜LÆ^§DFŠ/P½™•aèùç™DK{¿…§ÌçF®Ú ÄÁ[Ño˜qî›Á¼„ÃH_ãBQRS4Ş,ÄùÖò¿Å¼ùx8q¿j(&ş>3ñœ[	âº›n_Qµû†àÏ±cğ÷¤ñÏ)?º;ˆËŠ[øÍp{VŸ¥‚W|)¸š# BpY—V…¼îË¡G¡8g…é¡èƒHë¦Ûí[¾I–´\îùuèbErP“Eğ•ã¾ç‹)ôSµO®–
­7°#½1™)ØâÃXUE¦;ÕP£û}—´Y>pö{¯Ÿö„gêk¾)×u¦\×¬÷‰öÃU
›šµ•X	·qe>£İ,q1h,y¬ëñôÈ*?ƒ¶_¶‘ÛD%†\S/±ƒàæíÒ/º€œ“Æ ı.i=¡èói Öé©ë`õâ©³øÊ+™:ºèú¸*—g«ÂÁÅÃ^¹2±nŒ52â€]¸‡®xôHI)Ù$õæ„î)årŸø-‘‘ô‰µL.Z0/¾€Œ	)ìSôf,%èÍŸ¸ÕŒÂp-ôBVa.wí…ö´ìòû=´¾Âòµ‡E¨8\ÚY~˜"•%jŸiy`_ÇT&‰®]µ>ØòÎDë†À_¯‚ôÇ8&ü7¦½~ú+Ül!ÍI Ä¼üâEZ RÚÃîáR|¥e(Pì
OŸúş	Zèù­"ü´^‰í:Y>Câ7Ò?«¤ ¯ºåEÑçŸæÕ >«8İ¹IÒzËÚ—&Z!iî qrfâFÀ•-³ùaèå¾X:c3yfš·0~%Íà”ß7?ø’hQGEI´2	"&R+Ö¶˜dR¯•ÂÕ(Ïuw(ƒÙ{Æ®ÇñúqšŸ¸(l)k>$+N‰A½\K¥ r;àT¶¢-HyÛ¾'ÂCä“ä)±=‡_µ ]9¤ìĞ¤­DÏ®q{Š-‹­§óİÑ©Nò‚ªmp‘HVã„DÅ6Ñ¥}rŠ	óÔŒÉB>QÔ³	Yo—‰g„ªU»è*[ìöœ³ Ê>F-P‰­N0ŠÒE@âSi—åU'Yz8»l¨÷©Zµ—Ø«@)Cs¼rU¥JˆR€^Ì˜”F™êêd$'¢‡
‹§rş$eBSİVƒó”Q-½æuML(¦PÇn	£Yœ´M<(kuÇ¸íË/Ç
*MTÅìªd’İf ¤¸ãGˆ+»: ,v è”Õ#Kªäë$¡ô»àíTˆCz"JÀ1„n9x+Ó»íÊ¶–ÍôVK
F,ÔÒğ¼JÕzÊ1¹ÕúÄ"@•ÊH8P)ò‹
 y¥øA­TÏ˜\©v—ìTŠF†sX°ÛÔª í9&µïN•
VH*³«_VÆgØ¤%Önkç1nâ-tDˆ\Ÿswô‹Ü,è©ÙU‘Ër`ı€òÀ+UvÅF®ÓwıòùğªZ+ÕJÕÒZ©‚ÁÅÙ+›o5†¦Í@š£&Q­BZi£È)¹İÁı›åïzï«¥/K•Óêúz¤ÌoñÚMRr—-#šéškQC-UB'l;Æ1K‘ĞÚR›º"Vû)ı*®~Nâ…IS—ØN¤kğø’•0hì5wöh<q´á’%Öò»a>IµR>Î¤•p”*º›,¡ÇY àx«ÏY ¯ÀO`²†§:úå:Mv’p€Š’¥áĞUãè*!…e¦íÈ•Ú“	 5$N‹¼òÁôÊA’+ªí®3[Í´x*üæ|fz–´8¶‰N.6
NÔæÏœK“tíd=›c0½ùv:pBì5…bwT¨ib^¿‰M°«\ŠÊßx‹c~S?îÌÉãV	t9Ô‹©T[Ñi‡¼´—GÄè|Uì0—¨?!Ä›¨_«‰G!ì7„Z ( .	Ph™™..	\Ô3h$ˆ\ĞÀb4	˜èÅ$Ê‰¼Šöë)‘EŒ+ÜGŠ¶òŒÀ}ü‘ÒóRÔ5Fßx¹µ×ıòøUp	ƒu“ÛH`Õ>1ñ„©D•İ±îí²Ü›×7¹éI.£Û_xH«hÌ@¼c‹Óğ,X<rÛ?m¢"Æ°Éjoˆû{µK”6€ø+ÏÔ¿“İ
à¥T‰5©Kº˜hò#‰DT~##Z¡Àzo€»G,F7¢Héç@—à¨9#P~²?„™ÂŒ›¦ğÉvÆ¾Ãî¤Æo³VÙPAúı¤ß‡»,îWf_çæpxtÁÕDàšCàÇ)Ağcë‰”Üı/ñ†»0¢.B¼´œTˆøïøñäÕÍ€›,­‚0T´±!Ãé%TğøòJÃFÌ±1ƒxÇÖ»ÃP”³÷¹4ºJ“eÂu“–dÌFÂêfk±ûÄûSµÌ%º•Û6Q³|›5/š°-M±BXJs·Pcx-Â!@¡|xåx@9BDËêz¶ãyc˜¦„K ±
mõŸ/p¸àJ-¾}ä?Â@ÄV·ô/Å.C$¸¨”‡Td.%@È·/áßñÙî\@…eŞ›î»å¾ï¼z¹Œˆ–.(ĞyX&yji4Î±_¤R^¹PÏåVØÛör”½àÀ¼ŠÀ1ûîÀò¤U™g-`qo|6´xd0z{‹òe(T ÂíZ]ÜŞÅ‹^išÂmşªÇÆ694BG5G0E™2ó*“®µR¥Ä¾uÆ R®™sF›ÇtèèZv±(ÂŸ}èvWWW%ƒ –÷¢,ªóÊ»;ÛíıN»@Ÿnş¹O`}Ş„N:]ÇŒç?k[k[•êVÎnnfç?#aÿÓæ—ÜÄ|€:&Ÿÿ„ß›ÔÿkÕµêZÏ®ÃÙùÏGIñ7ùäÏŸ<Ù3ºì Ã~/µ|÷ä¯àOşü	şàóÿdóøøHüÄÿşüu$ËŸ…ïÿ¦5KxM6Ú<1TîÂa3ÿÇüşÛşûÿûw÷jg–SÄŸõAê˜2ş·j[‘ñ¿¶•ÿÇI¿À-¾ò{rÌœm1cx‹;½:[| ÀÁQõæËUö|ìÎ‹õFËvF¤wÿ’u„n½ü¼Õ)@™a^àyU¼BÎM±öt•}Yİ¨±—Ã÷ÏÜñÅÅ*ë€ş½éâñó@M«%êªã|j}X“‰Oß<ÇÍ5Ò©Ù2¬¨èõïJ\Ïş/€º7”n÷,?(½¸bt›;=¿æĞB¿ğRBüÀ³™—*Û±,òÏ¦Š×K_WhéÿJ«.ÚCIsÕá—„Iš ‚%<Íña*P'ë”ğFÆã¤°\‡ûdjE¸”B«ˆğ{OÔÈsà4L0ê“y÷1P‹}cáÑ¬ë:<VŸ–*[¥Z¥º	ÍƒgOĞMp #Ì
†aa×óû\„CçÚö¼^7¯ñF¼¹#.ã¯uª¥“ñoNúõ“«2{	ö-Éœİ^¿¡G†¿œ5×ñğõ@<9 ë,1,©’¡Í½9SÉÛOÌ«d¤Ãm«0§s¢¬a3ººN¾†Òğš à5Ñˆ.,L©f5/¯µ½œĞ/gk‘²¿ÜÚ9
z/Øp¾»É^, ¬ ı{²º§ [¹1 x$LVh‘™ß£o²Ó'àë^i´†Ü=îhÑ†‚>ä¸ ıpı}c‰~IÀ‚Ä·—@€uùy®øÎz¹M.õnö“bğâ‹w£8*¢Íbxù5İ÷ Lu0 —º½È¿KÁ×}Í«c9¯|E_¦x¬RË…#%Şj¹pàÄsÁ[Èd³|cœÂ²©™‚á äîNÎÍÇZ˜‚F2"¶î,	œ–I¡G >R\ŒKA¬äà¥Óço•@Ìò|‘&Uù
Ú¿‹‘iww›ÇíÆ6ÀH™ğ¥	2•Kø¡ÇJ+ÀÜ]gà¸cì;A†d0gÁw—ønğÊã¯’ y‘Æøâ
mcà–ˆÍj• OÈÁ ãFcIn£@±Êä.ó­¥°¸y»â´‰¤wÍÑí (Û:!ïv0Â]'	âÒrK—V,0¬oœ¤KŒGJµïKÚ6Q±(÷ˆÉ	|‚—$Õ-ÕbÑwAf7€rv¯µÏò]»újíX7/¾KgRRƒÍXo<ü¼ÈÀGÀah¸×­#2ØfşL´Á½jÄ"aWºX$o†W;-áÖ ^è %? ãÅ)@!ç¥1‹Ëògars–~æÆúHªıWİ¸›g³Û×jë›ë¬RİØXÛÊì?’~àö_[ØÿõŸ·îÕÎ,%¦ĞşûP£êø¯mmÅÆ?üÊÆÿc¤Ìşûyí¿ê¨ûišUÏ¡	Öà¨)Xu÷ÍÌÁwGáÇnÉ@ùùpxWy¢!¿‘ûØÜ	q?3â‡¥‡Vt[“ò?Œ_ôpsÌ4ı­¶½ÿa+‹ÿı8‰ÇÿVÂ| û¢(®²È¥b8wá‡šø@±&a„âË5åe'x».Ş6É4 ßnˆ·GŠ9»Õ°`,ÇıáëÕµ/ŸÖ«›k›õuHõ/Ÿ~ù4³Ìš’ÃœÍ·iã¿»ÿc}cc3ÿ‘0hİC×Q¹õı/ÕõìşGI¯ğ¡ë¸Kÿoleıÿ)ŒØ÷puÌÚÿµÚ0À:İÿRÉÆÿ£¤H”Ğ©ãöãm«ZËúÿ1’®õaê˜½ÿ7j[kÔÿÙø”Çû uÜ~ü¯W³ùÿqRJÄŞ¹ÖQ™¼ş«VªÂÿ}cs£†ıêfÿy”´Àô¸ä¹öRÜÖ„'´{ì<8ñ,C.ÿ‰3ŒÛî8ş«RøRDB~åq—Ê.¹TªæxºEo…ğÒ†×z¹¿ÿ®/R¸–Rà,(^µW¹H>wïxÒÁÍƒIG/¿Nˆ ¹ ü±£o9z²+å”¸Ñ“gv³Ÿ[J¾?`¾uÜ~ş‡Y ;ÿû()õşˆ9Ö1eş‡õÿV-;ÿ÷()súxl§­—Ç®i¹"÷Dœ5„?Äc{\TKÕÊ£z\$^c„âU½Á/ošœQ\l4=£¸ï3~$ı¯valĞÃĞ¢ëĞœ÷ôÄ;°±Aõ=ü¬TŞçn2Åïgš’®cšwSæÿµõØü¿¾¹™ù?JÊæÿlşŸÕËÄwÎ÷ïÌæ{…yÃ»2Í÷ƒkv>Æˆx<†¶sNW¹c›¹)±ó­$ñS¶ÿU|âZ‡dõ#v%#+úìÅ«İ]¼¾>ür÷ÎŒR·Ï=nï•ÙÑ·öì—ÕÜ¯g`ÈRËîºƒÏø|D¬¬ÖV×V×W7V7ïDÎıí£ö^{ÿ¸ùC¡ª0½>%k5¢äÊ¬ôî½Á>÷<ü¹Ò”ë:çRÇ4ıoÄşï:ÿ·Eû™ş÷ğin]{5mÇ>ËwÇt•8rÜcÎX(*>£v†µ£ST´3PPâ×ÕB>E[+%él«ºº†!H#›ª‘I•­ĞbâØó(*™ÌS-Uğ‹¢…É/¯@§Q/­ÎãW]`şWPZ¯Í»‡]ÀL›âŞRK#U´7YN;•^­(¥Fˆ‚!ªè1#¦_¤¢AO£w(˜€<”Î–A¯ììJ¬Éo°ÅKWÙ…ëÀ{{”ğæ†^Qvfã½¿cºĞİòK¹-·¸÷[¹'©®}÷Æ=‡uGq>à—¶ ³¬h¦ø·© Í©KğyÉ„
’;Cg»©¼ (sÏÄ{³/‘ø³ÖÒÅ§UÓÁıXª¸qx"pÚÄ´3º=d'¡'ğ¥€v¬Ï×ÀôÄa0>+Oq±%–,±’pMŠÿLç$*%XqèÙš=ÚğÅ0ÙÎ„cÀcxçŞ¢ x—Sâ‹7Şìv¸ G6roÛ÷¶éã=¾%è§ÓÏ5ñÖÊèK–{+äò»ÜñõÈlğIs¸ßÙ¿ÄØpÄ•Ó¹7PY0Š£ß—qØ¢[Áwğİ“ñ”ÃS!ªÚÌ.ñÜíË–‰íŞ˜g»Î…ÕÅkÌİÖÁsF*8ÀËînï`ìÆ~¸í«@'!BŞuqÍİ¾UÄj9?÷œ~›”züë˜¢ÿ¡»_àÿWİ	÷ÿÖ²ó’Ş¶÷_îì·ßåè¶wTdŞ× ğÿro_¶÷ÛG;Ûïröö«£ãoO_¶šÇíÎéëæéŞ·<ìTçÕ!†niœo¾^dYzˆ¤™(ßĞëjuLÿğ6ÿkÿask-ÿ‘,ûÒ´qş>…>ÍÄ"C'‡ÓMøÜØgé¾)2şÇ½Óàê¦¹™€¦Ú6¶ûÏÆ:ÆÿŞÚ\Ëü%eöÕş“Äÿ™	èL@á}qq£Ïj ¢>‚ù'‰Ö”Ìxaš¡¦{Øf‚~GSP*ì9Ê„ŸŒ5Hİñ°† Å qpØŞouNƒ»°ùäË®ËyİøSÜPÜíy¦îÃM=Åõù§±Hª¦)%Q´à‘‰ç0nQÔ59kK É–¡«i(rş—‡T9EÖ.á‹¹Ô1Õÿ{m-âÿµUÙÈâÿ=JÊüµ¢hGıµ´ñğ£uŞjN ŒÔ]·@5'åÍf 	ük-èÓÏÕ£+×öº Ÿ|¸
{‘ëuë,x™sÎpO¡;€à÷Â°­ïÉ%^ÿ3	‡Øµ4wz«I°»ƒÔÔl;6^‚iºäCÓ‰:2ÿ|+ÈŸ[4e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥,e)KYÊR–²”¥”ôÿ2ÅLİ ¸ 