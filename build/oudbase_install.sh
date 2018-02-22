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
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"                  # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"                    # Full qualified script name

START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
OUD_CORE_CONFIG="oudenv_core.conf"
CONFIG_FILES="oudtab oudenv.conf oud._DEFAULT_.conf ${OUD_CORE_CONFIG}"

# a few core default values.
DEFAULT_ORACLE_BASE="/u00/app/oracle"
SYSTEM_JAVA_PATH=$(if [ -d "/usr/java" ]; then echo "/usr/java"; fi)
DEFAULT_OUD_DATA="/u01"
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_PRODUCT_BASE_NAME="product"
DEFAULT_ORACLE_HOME_NAME="oud12.2.1.3.0"
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.3.0"
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
    DoMsg "INFO :   -A <OUD_ADMIN_BASE>         Base directory for OUD admin (default \$OUD_DATA/admin)"
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
while getopts hvab:o:d:i:m:A:B:E:f:j: arg; do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      a) APPEND_PROFILE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      o) INSTALL_OUD_BASE="${OPTARG}";;
      d) INSTALL_OUD_DATA="${OPTARG}";;
      i) INSTALL_OUD_INSTANCE_BASE="${OPTARG}";;
      A) INSTALL_OUD_ADMIN_BASE="${OPTARG}";;
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

DoMsg "INFO : Define default values"
# define default values for a couple of directories and set the real 
# directories based on the cli or default values

# define ORACLE_BASE basically this should not be used since -b is a mandatory parameter
export ORACLE_BASE=${INSTALL_ORACLE_BASE:-"${DEFAULT_ORACLE_BASE}"}

# define OUD_BASE
DEFAULT_OUD_BASE="${ORACLE_BASE}"
export OUD_BASE=${INSTALL_OUD_BASE:-"${DEFAULT_OUD_BASE}"}

# define OUD_DATA
DEFAULT_OUD_DATA=$(if [ -d "${DEFAULT_OUD_DATA}" ]; then echo ${DEFAULT_OUD_DATA}; else echo "${ORACLE_BASE}"; fi)
export OUD_DATA=${INSTALL_OUD_DATA:-"${DEFAULT_OUD_DATA}"}

# define OUD_INSTANCE_BASE
DEFAULT_OUD_INSTANCE_BASE="${OUD_DATA}/${DEFAULT_OUD_INSTANCE_BASE_NAME}"
export OUD_INSTANCE_BASE=${INSTALL_OUD_INSTANCE_BASE:-"${DEFAULT_OUD_INSTANCE_BASE}"}

# define OUD_BACKUP_BASE
DEFAULT_OUD_BACKUP_BASE="${OUD_DATA}/${DEFAULT_OUD_BACKUP_BASE_NAME}"
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE:-"${DEFAULT_OUD_BACKUP_BASE}"}

# define ORACLE_HOME
DEFAULT_ORACLE_HOME=$(find ${ORACLE_BASE} ! -readable -prune -o -name oud-setup -print |sed 's/\/oud\/oud-setup$//'|head -n 1)
DEFAULT_ORACLE_HOME=${DEFAULT_ORACLE_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_HOME_NAME}"}
export ORACLE_HOME=${INSTALL_ORACLE_HOME:-"${DEFAULT_ORACLE_HOME}"}

# define ORACLE_FMW_HOME
DEFAULT_ORACLE_FMW_HOME=$(find ${ORACLE_BASE} ! -readable -prune -o -name oudsm-wlst.jar -print|sed -r 's/(\/[^\/]+){3}\/oudsm-wlst.jar//g'|head -n 1)
DEFAULT_ORACLE_FMW_HOME=${DEFAULT_ORACLE_FMW_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_FMW_HOME_NAME}"}
export ORACLE_FMW_HOME=${INSTALL_ORACLE_FMW_HOME:-"${DEFAULT_ORACLE_FMW_HOME}"}

# define JAVA_HOME
DEFAULT_JAVA_HOME=$(readlink -f $(find ${ORACLE_BASE} ${SYSTEM_JAVA_PATH} ! -readable -prune -o -type f -name java -print |head -1) 2>/dev/null| sed "s:/bin/java::")
export JAVA_HOME=${INSTALL_JAVA_HOME:-"${DEFAULT_JAVA_HOME}"}

# define OUD_BACKUP_BASE
DEFAULT_OUD_ADMIN_BASE="${OUD_DATA}/${DEFAULT_OUD_ADMIN_BASE_NAME}"
export OUD_ADMIN_BASE=${INSTALL_OUD_ADMIN_BASE:-"${DEFAULT_OUD_ADMIN_BASE}"}

# define ORACLE_PRODUCT
if [ "${INSTALL_ORACLE_HOME}" == "" ]; then
    ORACLE_PRODUCT=$(dirname ${ORACLE_HOME})
else
    ORACLE_PRODUCT
fi

# set the core etc directory
export ETC_CORE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/etc" 

# adjust LOG_BASE and ETC_BASE depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE="${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/log"
    export ETC_BASE="${ETC_CORE}"
else
    export LOG_BASE="${OUD_DATA}/log"
    export ETC_BASE="${OUD_DATA}/etc"
fi

# Print some information on the defined variables
DoMsg "INFO : Using the following variable for installation"
DoMsg "INFO : ORACLE_BASE          = $ORACLE_BASE"
DoMsg "INFO : OUD_BASE             = $OUD_BASE"
DoMsg "INFO : LOG_BASE             = $LOG_BASE"
DoMsg "INFO : ETC_CORE             = $ETC_CORE"
DoMsg "INFO : ETC_BASE             = $ETC_BASE"
DoMsg "INFO : OUD_DATA             = $OUD_DATA"
DoMsg "INFO : OUD_INSTANCE_BASE    = $OUD_INSTANCE_BASE"
DoMsg "INFO : OUD_ADMIN_BASE       = $OUD_ADMIN_BASE"
DoMsg "INFO : OUD_BACKUP_BASE      = $OUD_BACKUP_BASE"
DoMsg "INFO : ORACLE_PRODUCT       = $ORACLE_PRODUCT"
DoMsg "INFO : ORACLE_HOME          = $ORACLE_HOME"
DoMsg "INFO : ORACLE_FMW_HOME      = $ORACLE_FMW_HOME"
DoMsg "INFO : JAVA_HOME            = $JAVA_HOME"
DoMsg "INFO : SCRIPT_FQN           = $SCRIPT_FQN"

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "INFO : Installing OUD Environment"
DoMsg "INFO : Create required directories in ORACLE_BASE=${ORACLE_BASE}"

for i in    ${LOG_BASE} \
            ${ETC_BASE} \
            ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME} \
            ${OUD_ADMIN_BASE} \
            ${OUD_BACKUP_BASE} \
            ${OUD_INSTANCE_BASE} \
            ${ORACLE_PRODUCT}; do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "INFO : Create Directory ${i}" || CleanAndQuit 41 ${i}
done

# backup config files if the exits. Just check if ${OUD_BASE}/local/etc
# does exist
if [ -d ${ETC_BASE} ]; then
    DoMsg "INFO : Backup existing config files"
    SAVE_CONFIG="TRUE"
    for i in ${CONFIG_FILES}; do
        if [ -f ${ETC_BASE}/$i ]; then
            DoMsg "INFO : Backup $i to $i.save"
            cp ${ETC_BASE}/$i ${ETC_BASE}/$i.save
        fi
    done
fi

DoMsg "INFO : Extracting file into ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}

# restore customized config files
if [ "${SAVE_CONFIG}" = "TRUE" ]; then
    DoMsg "INFO : Restore cusomized config files"
    for i in ${CONFIG_FILES}; do
        if [ -f ${ETC_BASE}/$i.save ]; then
            if ! cmp ${ETC_BASE}/$i.save ${ETC_BASE}/$i >/dev/null 2>&1 ; then
                DoMsg "INFO : Restore $i.save to $i"
                cp ${ETC_BASE}/$i ${ETC_BASE}/$i.new
                cp ${ETC_BASE}/$i.save ${ETC_BASE}/$i
                rm ${ETC_BASE}/$i.save
            else
                rm ${ETC_BASE}/$i.save
            fi
        fi
    done
fi

# Store install customization
DoMsg "INFO : Store customization in core config file ${ETC_CORE}/${OUD_CORE_CONFIG}"
for i in    OUD_ADMIN_BASE \
            OUD_BACKUP_BASE \
            OUD_INSTANCE_BASE \
            OUD_DATA \
            OUD_BASE \
            ORACLE_BASE \
            ORACLE_HOME \
            ORACLE_FMW_HOME \
            JAVA_HOME; do
    variable="INSTALL_${i}"
    if [ ! "${!variable}" == "" ]; then
        if [ $(grep -c "^$i" ${ETC_CORE}/${OUD_CORE_CONFIG}) -gt 0 ]; then
            DoMsg "INFO : update customization for $i (${!variable})"
            sed -i "s|^$i.*|$i=${!variable}|" ${ETC_CORE}/${OUD_CORE_CONFIG}
        else
            DoMsg "INFO : save customization for $i (${!variable})"
            echo "$i=${!variable}" >> ${ETC_CORE}/${OUD_CORE_CONFIG}
        fi
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
    echo "# Check OUD_BASE and load if necessary"                       >>"${PROFILE}"
    echo "if [ \"\${OUD_BASE}\" = \"\" ]; then"                         >>"${PROFILE}"
    echo "  if [ -f \"\${HOME}/.OUD_BASE\" ]; then"                     >>"${PROFILE}"
    echo "    . \"\${HOME}/.OUD_BASE\""                                 >>"${PROFILE}"
    echo "  else"                                                       >>"${PROFILE}"
    echo "    echo \"ERROR: Could not load \${HOME}/.OUD_BASE\""        >>"${PROFILE}"
    echo "  fi"                                                         >>"${PROFILE}"
    echo "fi"                                                           >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# define an oudenv alias"                                     >>"${PROFILE}"
    echo "alias oud=\". \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh\""  >>"${PROFILE}"
    echo ""                                                             >>"${PROFILE}"
    echo "# source oud environment"                                     >>"${PROFILE}"
    echo ". \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"  >>"${PROFILE}"
else
    DoMsg "INFO : Please manual adjust your .bash_profile to load / source your OUD Environment"
    DoMsg "INFO : using the following code"
    DoMsg "# Check OUD_BASE and load if necessary"
    DoMsg "if [ \"\${OUD_BASE}\" = \"\" ]; then"
    DoMsg "  if [ -f \"\${HOME}/.OUD_BASE\" ]; then"
    DoMsg "    . \"\${HOME}/.OUD_BASE\""
    DoMsg "  else'"
    DoMsg "    echo \"ERROR: Could not load \${HOME}/.OUD_BASE\""
    DoMsg "  fi"
    DoMsg "fi"
    DoMsg ""
    DoMsg "# define an oudenv alias"
    DoMsg "alias oud=\". \${OUD_BASE}/{DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh\""
    DoMsg ""
    DoMsg "# source oud environment"
    DoMsg ". ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"
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
‹ =„Z í½[l#I¶ &öÌÜ©byï­_ÏëNï¡T£ÇˆO‰R·ºYÓ,‘U­n½V”ªº§ªF“$Sdv‘™œÌ¤Tê*Í^ØØëõ®÷Ç¯]k¯kûÃ0öÚë×mø	Ø€=XcöîúÏÆ.à`øcísâ‘‘’’(©ª›Ñ]"™yâÄëÄ‰'NœS7ÌìÔ§\.·Z,ú¹Â>s…eöÉÉ/–—r+Åb~™äòùâJaŠ¯ºb˜ú«ÙPÇÒÂØÑÑ€÷¼Şç[’ê0şV¿yÍsûNÆi_AƒÇ¿PÌÁ˜Óñ(äó0ş@
Å)’»‚º„Ò×|ü§’E¨kN;9MÒãK€mf£¹FfÆvß6µ¦áò£Eò ï¦î8¤¢ë«×ÕM—ü”Ôú½e»dîA¥6yjšŞÒmİp\[sŞ_$ïå‹ò¨£¹nİî·Z‹¤vb¸_êvG3›c¯ô¶ÖÕ3,­eÂÁËrßm[6Ysõ#Í$;zÛîdÎÒyâĞg‹>ûÈåiX]È]m®—{fSsÜõ¶f¶ôæƒSÖıÍõË–ğÙÓÇ°ÌˆxÁÀvûvÏrt†éĞ©5l£ç×"->Ú:1LhšÙĞ	k!Ñbënß$«©cOX®îˆÚì·a†¾u5Ãìœ’¾£7É‘eİ<6lË¤ƒ
ƒÓ¶ú.Ù\ICÑğŠÖû†JCdm×í9kÙl ûuì,ë1Y¸>öa…î!UYöéüÌå3¹÷3…\~……Óp­Cu»`ò…L>0«¦Üü¸ö!£ßØ2‰u„”Í\ÁäL“u(Ôê_j.Tì2Ø“úK:Ùv*‡{;;û‡•íÒÌ+é×Z:dã¶pêe,»•:£¨šMlãåë‘¤è*0Gú—<Ö:}İ¹Dƒ’«{µíŒf²²SŞİ­nWJ©ı½ƒjŠŒ˜¦vµzG'«Eø¢õz:0Àı`§V-¥–7kÀ´Q‡)Hº8›jë{»û‡Ûå­jif)Ü>CfróÉı­İÃÊÆ^u}gïóR*ëv{)úğáÆ&”>óJ8ËªÙ333©dm¿¼·øqµ\©î•Rô²'††mæ•Tú™{Ì(óî;›§s–Ì,¤’[åÍr¥²W­ÕJ@ÓY¶2Óh'«{{;{¥\R¦ˆË$C÷°o6¨.Cİxgß¯9p´–>7O^ykÅpzí”Œ¹t$'
)QÓGkËi‘ÔÆöÃ²Æ
^òÓtûØ&iƒ|ˆ³{chb{½zŸ¤+äC#š•møşû¾³ıÄ²›øï“çQ…’nG;-œÌ¹¸8taq‡_1Ù£²GÌ”˜ìvTöF[o¼ Ë­÷:Fƒò¥R»ı$È÷Éw4ÌRÅ°õ.dK3¡5vºÈ®{ OH?¢¼$&whX0ÁX„Ø’•oÓjQöü«ÍGÈÎœqDÂÃüI·\’#Ï?ÀõİLŠf®wtÍ,›Í?Õ7\7óªpF_ëXk\€ãEçÏúüÈH%Ç¾ÖEN­-FXŒG¹F—
,İŞUMuÚësóÉW´Û»û°Hæï­-œE!M ëj/t’­}
“Ál‘ºMÖ·à×ĞåÕˆ]Ñ€A@&1ÉüvRæ»H`qóÆ$?Hjı­ê!ĞÑÖ.,,MKHêg÷>Oßë¦ï5ï}¼vokí^-5ÿÁRÖ½½ø¬æÌtuÜ(wçS,U)7•’Ø{ ‘D&İÑşHÑ)ø,EJ„‹ÁÉ @…¸0––Ñh[ï×	È 'QŠ¼vu¤5i>z9•y5SJ|uÚÆ‘ëı:iã¼§µÆbõ¥umZJçm™_­ÀÃ¡­‹lá`t
¨ÔÒpk›–©‡yÓ‡íşı¨6½a½]ÉÑ;ï*ø³Ç"å…"dİ€ô{À{c|i¸W [ø"„'Ş{œ%ç‘{à¹yoÍEî
+mHz–ÙU^
àUh&Y)†¢Î'°%n­kõM*‰kv«[d'Cj0¹útYCöŞ°l”;Œ^F.¢0j1™Ã¥}~TüÅ¡øe©„Š@b é›–KÕÁåŒn!÷ËÎ?öÊë›UOº9|P®::zh©4-ÇÑ]ŠXy¨kF¥G¥=ùü0ÌëV¿Ó¤\«ßh³¶Kéös éXZ“<›yõñG6#*)£[ÚŞš«}•mÎ azSÎ¿<4Õ¶¡‡°:M*E¨Ù‡¶†e§£k÷Må®jXİ®fªè
@×t$=ëÒ0¬[†ãPÉ*,eË=
m(ûWTA5˜¦ÎXâÇĞÎ[mğ	B·7°QæSÄ›
±GìO˜h{Râ´4E)jG·Gr¿£Š#f~fÙ³ğ+ğ-¨‹LÜ0ák—m²¤ú¿ÿş|`§ò	*ÉN4ÓÔˆò{[ët,ešş|(Û90_˜Ö‰Éš#ï¥X(JÎBÌ_­ÓŞµA¬ÖQ fsŞËê'vWAY¸ŸmêÇY³ßéx ÓĞ£•ÕoŠYâcmöuTÂâgÙZ<è·dì¨İAgšå\ÈàD#ÃJC/jÈiÿ%¹Únçáx4+LIÃ5¤—×C6F›G‡ÉÃ),Ì(ÜğÙ§I!R	0&R©â£„#ràEd¢ Â¢¦²İ-ä½ıî‘AHÒ«;ìUŸ®„ñÕ%¯_Ã›Ÿt3ğZ® Rj>¥aY›Ø)8Í%{2CfæúKbšê=%ô|ôö>¢äûL®NHrğU0IÇ¨*–9Ò`*ÉÖO_HU¨’If?‡9úk”ËÈOŠÃtBR’îBi~@{›ôFDí—¼\ ´gnP“Š™¬ãõ…dº-Í¸”î]¢~×Öz$¥4l9—Â=~2É¹ôº¤ÓÅ:*Ò^P{. ÔI£ÒIÕüŞ!OŠ÷“	q¾µt×êÙªù{¶…ÓZ¾Jw°‡{šÄà¢>Œí‡xnÒ>6Ö*k_¬U×l”B½m°á‰,`]2aNZçrºôÎ˜'[§2!#™îìB×<RÖĞ
Â1ı^ÄBVÙÅÀÚód¯º»¹±^ŞÇÃ…P­ªó*UFcù¹hlÌ,Èİ£yÜBmòŒtA`jóE)Y–’…ÙÀZŞĞ:YnEÀ¸DŠÌ¨¨9— ÷‰7“aVÿ4ŸD ¦ÿŸù9”Õ¦ÂÑqqÁ¶ºœõp2}åÁGíÌ”¾+’P m”à0Ñò ã¯ìfÊ>Å#`?~mño‘8Ñ¡»&H}Id±Ø×µt*R}–Œ ^‘M~f^í>©ğ†œ±nú	_"ÃğƒV¡å¥ğàğU0 \õM!
—H¥AOrÈtš'§lCz:…'¦•Ôí¹ôû®mõtÛ5tk
Xù©lCõÙc¹M$²¡ èÚ ™–¨ï«D¤ğd4cÃXåÏOçËyœS‰Æ”="ÄgÀ›µ&üƒEGc'õx‰'íiƒÌ:Ù_ÎdÓÙY™!×,O´Æ€%¦,ïö;®ÑÃ³M4½ğPdw¨l
»Wé¢€?“}µı“}ffIöƒ³ÜÀĞ¡ó"ş%‡Z“F¦P)ŠÚeË2İØÊ4?ö©éö1ì·ôjò˜Ìµ@\†Ú4Èl„ŠêM¥ìyÁB¤±i[);¬S¹X.(pñn6Ğğ·Šm¾UÔP1Æ¶ˆIÜd¸ÅÛ¬”wéŸš·”ª=ÃKº™WßÉ”Ÿ|z¸ƒ§sÚÉ2û úhcûÕ^­”zf¦ŸÁŞí!ıšú`ãÑöÎ^u–‡Rş¶Õ*ñt(O~C²¿,7›6ŒA9ëL=ûpK™}v?K^A£æf–Øã*k<Ÿçxr3<°xE7%ô™:âdÖU™w@¯Î,b>$Í¢ğ0åi/	^]ˆ¥%?Nwk”R{ƒO'£3¶Ñ¡b ş‘f“†NÆ—aÆH»c'bDpö«Ú§ÑW*Ä™wèJE5y3»; Â—+[Ûòâ»iÍ®a°…W¯È±Š]Ã”&Åk¤Bı£º\P>>ºŒ‡–÷ùT ~-Mœk©8á‘¬b±t&h}•üä7@ëÛ¨¢êà´^,Dûù¼0øP½XPHÛ§š{;Òqì Ó7m‹:I×Ÿ„ı73á»ûï¥å\í¿áÛj±Ë1ûïüÄşû:ÒÄşû†ì¿½	÷U±ÿæFÀˆ"âxN„œ¯ºé÷{øÿŠL¿óKÁŒ†éÚV³&ì=5*"rzzÃ8:õíğ¡Æm%1^óñ¯¶1øX-ÁÏm~­6Ü_#îk´×°GR¸„	wÈT¸vŸ¤»äCi„áÑè&Û—±×İX;\çMàlHlò‰”“;Ô</÷–ft×{DgŸØH_«4™ØHOl¤ÉÄFzb#=±‘æ,òú¡Xe{}»ğM,¤‡àŸØ*ŸÓVyLv¼7aU:±ŸüŠÙOhuûqi¨µd¼¡%+@iÊKPí˜(áù-%Ùî7O®Ì²»f¬U©9äuØBÖbÌ» (i€fæ„œ'`_£êÖÉ>[Ì>#ÙÖü•ÙQÅNò+oJÇÙ^`l#X5gRI—âéì=#LW«GêEJi¨î¯sÆ°yu ŞˆM“†­ãnVS-(PO£d{ôÎ‹T¶º
ß#ûå¥pA€´;77jh"ÀìºÉì/§gı+g¯}j‡Åam>¼ñnxRŞÛFëUÂÊÓN¡÷,¢í1x‚ìQ×€(]³aM+åıòYv¯Íø¹ú&·Êõâï¥„ÅWÜ…Š+´…±ï•wx£ Q»6Å9ÄŒAZfeŸÍÁßùgX‹ÌÂLöY>;;ï7MŞDy=6EWÎ6X?K¼4ÅéºïèƒÈšç Æ†Épı}˜Ctƒn“ÙÅYÿÍs¶Ï¯ï˜ú	eç† Hä¾u}|Fñ>39bµİlÅtuAÈâ¦–7çBØRìª‡Õ#,ª§q˜Ï!1»wÛRÊc'øtFdzîsĞ‘ã]y“¶‰s=sõ#òšèbº¥Ø£×ô7t(¡_,»•±ğpÄÉ8ÔÊ2(=ãq[fzÉ2¥R¹óê6”gXDíU+-S¿·H«o7tYfËø$*ñ«HéN¼V¥<¿ !ï…¦^Ó[Sü5÷<$é0úŒš~U6öT½„R­ø£‡®:³åe÷ï¼w©–iZa/üá¡ãÚ(Ä íÌá4Kh>>N@{Ï²\ÆM›kÈQHä sÏ>}ºVïhæ‹µçÏgçC‰#ógŠZì™Œs^U™ÈàlÙv	-à”'dŒ&ËÌfŸ¥Ÿ¥²!ÙÙ–‘…_óª–M#Ú™ O¯Ü–Üg^‰Á8;ôªvÆzuüğ:ôTOâ>Íqt¿Õ½ '­õ­­2Êú|C´±}–eÓ&Lætºm9.m½ù¿F²KÉ>ªšh'÷=ÂaU8¢À´à•éÍÃŠvÊ5æ³?»×Ÿ…ı`µa!W:)Ğƒ¡×hP©³ªÎ4L!{A
cK6¬Ìæ2¬ıœñ0ĞJø *Ğ<.qÈÍ«J8\=Ã…t~)Û·lL…ÊdV˜jW¼î’—$íP­ÊÎŞZÕÏbï§pü-H˜òNâ=97G¿ü,?¯ò‡Hõyü°Ş/N¿;»#ØfŸ‚ cN[oÕïşÀ+ÚöK¬XMëÄ\ñS4ÿÄ€YW‡¥nãÍj½™IyÊÉ6}&\Tqğæ‡¦‡¤ü2sÖ0Ÿ§—s9yû\Zun*ĞëÆ”vAÒï‘€½«¬BÏ†ÿknõ*ì?‘ˆû½›ñÿ»T\òì?óK«hÿYXøÿ½–4±ÿ¼!ûOoÂ}Uì?Yƒ¾¾öŸ+øˆıçû™Üª³¥}§„´¯ìE.ëŠS„†eQ]2üÎ|èyv¤Ï'¥qØŞƒÒ\&ÿÖz¾V³ÒıÏw±E››#7ˆ5JŒÙÆšöO{zòÓju·´|<Ùv¿[‡	Í{¢ë/èd}¡ë½$ğšš–Ré´ø>B=™k?yØÑZÚ·Ù‚Ö%"©~õmi½†zIša'*Z«ll¯ïU·ªÛûåÍ‰Mî¨ö²Éø-ØäÒ2&6¹›Ü‰MnúM²ÉÉ$wb”;1Ê½˜Q.—íÂF¹cÚè&Æ´cÚ·Ê˜vÜşHß@CZwÍXë®U¯ÂŒÖ…- USE£^‡‘í8İ‡N¬FÃ€«Ñ‰Õè[l5ÊçF´eñD&çbéG6Ç–}YÁ§
,&Ğ®ÎZµâÒOiÅS€„iµ\$XÍA=f¿c‘"È‰®¿ &UÅ'·«OŸT«ŸnïH:—ƒÔ|rg³â¿€=€x–y…' góó4ûƒòú§»‡µ*P+ô
…LDÉEîáV‚fDs" =,bPf¿
™Õ!ª„ÚŒƒDªVBsø¿à³áÈğhVÅ¾İâ'«³\CŠYmÒÄz˜\ÖS5Ş|c-‘#Ğ…,’q¼5˜MtïtäÓ—/º¨¶Êœ’¨QfˆjGèfÍ*q-¿ŞøëIhzøıÂŠ²eåø¨Oœ¼qSÁŒÎp3BFÙ™Wj]¤L¡W#š‹Ê¦¢$jìøv<¯[æ‘Ñò‡q„ójrúõ†a!éİ/G£ôQV¶Ãe83nëK¶Í[ßÙ~HîÇµzHÓD0q îœ£mÁ¬ãhÆ´¡M{¦7´¡Ğ´¬Ö`§½ßè”UúÙo¢^Cüä®UcpÉc½‡œã¡™LğYÏhÆõsT/s‹cŞ[‹ãÑ­ã-DNêsdPÌK¹°AñpcâÎ?ô"›<‚½p@Ü.÷]C%54ÈA—t>L³±:M´×Ñ#(kĞe>ÂR<†¹ÿaöãMä¡ ²ô1JYB¬Sd’°¹İ%i;zf0?™‰oÆ¶%7áÈêƒ¬?§·2a)¢Òó±;"–Ò˜L½yõ&¦ŞçH7mjûF&4şÍzjÖ+)c°ıw.·œ[Aûïå¥b>òş®&öß×“¾õ½oO½35µ¥5ÈN|&X>›ºÿ
ğï·ğ~'~g4”åıı=öæø¿àßw ßàÏïNMıäğŒÖëuôLGs\4 Æ½üônãø&ş™šú“×Õ6®€:nñ:,ÂÏrØo1Ø`Ñ†¹ŞÑ7Ì¦şrjêÓßÿBÿÅüŸş~æ¯…ĞŞÌ¤Dnº¢2Ïÿ•\~y98ÿ—ó“ù-irÿãfîx–øoóİ¦œ¢7qñ€.ÂJù77‚ád'·@®âH.|¤	»Ëì'‚
!n ğ»¸ip—©A(dÓj¼ĞíÈ"ˆ´¥»‡ˆÕ¡ÕájBv>cåÚ§cî`nïÁcÍ6Ğ¼æbñˆ­¦ÓpÖÔ¶ş˜ÙÖ)íØ+m5,—œê^ìs¹áãzÀ#®×Ï+·/RŠÒùA¹öñamç`o½ú4÷6Áİ-Ó•qx‹Æ7âsL`…}3"m µÆ\Ó°)d*„:¸? ½“&IïÂWàVuÇêô]<ewÛˆZEûğOQO~!¸9W÷€iš<Ä¿îkãÈÀómÆ°RüP(8ZìÎ‹‰L‚ª=ÔIVªË›ü§ÂüĞÓKŞ…Tã–R`øf^bûjJ9
åpÒ‘µZÛ:¬ìÀW)·i!SS7wÖË›2õ¦ó Pò
Û Aá‰1ƒÒİF,jÌD™­X¨ıêÖîfy¿Zã°KŞ(ósìîíTÖ÷åVôè2WÂÊN“Ñ ‰ƒuOò…L!“Ï,er!À‡[O 3­ñ^•ª7•RŒ?Òcd†©d!V®$Sä= È#qÿZÂÙ™L”R9„sZü.¦µZé×ZZ2“:	<¢iRN«ä£¥EÄÁÒ†•d[­!“á`‘› ©áHà‚‚¿1j9%aé°A(P9(¯E; ,AÄ´“ùñUø£M-oÒwúj,`0‚…‰Àóµ,±2CÁÕ#ilÕ¸ÓC^ì?2ìZ5¹‡qÁ-ùÔï›<©3	}×p¯è@š„Íçg§ÿ€aöì>Ô®ğA,U¡–ÅêP¼AŞ@¬0Í@lááÈÃ,WE¯2Z†^}6}›VCÌí6š¿F‡ÏÕüYŠ¿Bc,b—J­|Rn®ÊıÅ“Ëªğ\©àOÊË¢Hïû9ûB;ÖX×"çğÏ“©E‰È\¹º¾¿³÷ù!3¡£fK¼wP˜ò€V'¶DèÇ"AÛBØuOÉı@DìŞşşçèˆ·Ğ—èı4(½AMçMï"ªşRoôi5²œUz©WÁs+ş•\½áVÉÌtŠŸ#ìãbò_¹Í²R§(ûÿg1 XılİíÛ&Éãw{
w½|káÕÔ{·ÕˆŸÙ(x¤Z5¼Ş«#?su»‹EÍ?AìœŠ%·¯:Ù-ïŒæzG†í¸mYõÄ€¥ÉÖ»áŠ8Õœ´ÎHº£ly%^]~\­"r cü8“lÀ¼°˜>Tøì‘ãâ(T`Ÿdñö‘²AVÕSè´B£af™HŸFäõÉDZDRQÆä#J7Bø>“qKÏsKH^?FW&je=g]† ğ«"Ì¹J Ë½±Ë‹§ldª&g$$zœ‘‘zV±D2ä÷¬Í$$ãÌ÷ôË­™øªÎm[èj#0âwjC|JƒóFd2¿î¨9½Á3bB…Rù‘÷İÕê^o¿¾/äŒ+¬©†Ñ„º]eÄh‰r‡ªçÆ¾ioÇ±`qÁë·Ö‘‹f¯/¸%¬¼X”Kt`uH¨Â{0ú¶Ï
˜i¶\GdG’Ñ´ÀÜGD˜[Œõxpb*¬Î’Í›mé¥
r‹ó€Aüùá/ißÎK¥†ºş–XF†£Í„°Béİ{êA*d|–3X	.
U;nÅÌÜ{¥rı€„²À§w4óTÅ!Xíèhc5¾OEñ<é2¶÷õa&÷A —µÁ—(ƒ+P¹„ÃvœL¼~†¾c2#~‰vB”"¸šdÂI0ò6<Å³¢WŠ’H›ZÑó–xy,C}÷?twnš‹£·óÓÚEélÜ4FéëÊ.MÈ²£æ¸êHB?£äXqô7MÑ©<ŠÛÒß,c%£©[¡¿6
àZ‡Uğ<håĞ ìb.ójLéd51‚ÛXT˜ë/TÉÃïb×ù¨æGTf@ó¨Ø†÷Â9ÛQwÏiÔª,cÌÓş¹‚;•oª&Ï Ú	¸}‡¼
ôRwrMî{F¶¼FÊ9ã‚„ìŒ¹b×ª{ÎèvyTˆãÃ0îàµÊ¹Ø[#³ò­‘Yx£ÚW³t›$±ùñv‰:õä;&QÙ¨GÕl¿7û3e¿ÑèÒj+$Á g*x”e›şAİ\GioìŠ³^HBNÈ´YüùÏU3Wñ\œ”²£‰i‚ö¯´‡¼3äTÚM˜)ÜÏ#g‡•½£Ë Ò˜´]SPX¶Öèè‡TGˆA0-®‡2ÎN'C0¤l‘½éÅDŸ·¢{³2CÍô1V}nÆïüùPn6æ$„c‡5b RÁ¾¢y@¹5ÆxVt|³RŞ%»ÈI‰Tú@­©°ô°VÛ—éíˆHpª6eØ“®Dğl"Ã^u7>1¾
2
Cî÷ÂÌXæÃœaóã}Y`¹
vÌ:y0»‡¤'M~‚]]óé éK])"¥R$~ú•Rª {ó1¾õ´Ú¦tÿ9‚ãSUü¾W´ š‡×md.é¼/by^AwqDN‹#[ò‘Q.Šr%åùNf¾v@…€¥3’ö‹èÙ†é‘Ù{é¢Cî¥óü»B¿.ã_å÷°ŒÀõCœm–[¾°ó°~J² „½|Æ?±·½ï”"Ğ¶&z§4cHÛŸÎSWÈüÂ ¬ÎĞâ»!y´~28Ã»œaö€<|ÁÚ·¯w:bº}	ÕóÕmZ?(³œ]HÚã—ì/%ë]NÒ»œw)/â`ÌÌjòÚ£†,…–8Ğñ•Ó³Øù‡$
øâ‘Ş‰Št¥ÿ’"“zíĞ”ôÅ^Yº‹v4G%C¹éŠ.î.$QÅ^›S,<ƒ;5óQJT’frİ;İ< ²ÛÑQ%›_•·sJUR¦ØËk1î¯¾rB¦*Y Ù!%˜È3SµâAá8^0æ¸RaÏß8q™¬õvLYa©wjp—k“†%rDÃ›Æ¨#&EĞC¥cÚ$³Yº‰¡ûz9€¹W´L“²ÿìbö—3ÙŞ¬¨'5tã¨•F…­nÒğW\HB}¢"Æ‰’CeòB°¼éëq–ÆG¥ÄÚ	­P#å}Ù8{õœIVƒŒÌ‘N­¾ÍæZ´cZğ$œ¡ô‹o7ÆNØĞœŞn§VB±2rˆTDAš^†$	Î<‡˜üÒ{ïGÃ0‚ğÄ\„]YZ‰¥#ùJ|Ø÷ŞWğ^œó^'¥¢xyPÃ2@½"å
ê.BŠ‹ ¬¬¼ˆÔ\HğAíEŒêBÊT_Dê.Æß‹×±ºõ{x›óïÃC+{Mç#Ißüæ¯Æ\§Ò¹Fœ¾‡EÃØ6ß8'¡­Ã<u#™WOôåDY«ARÙ@ÆlãÙ³À£5J?k®I¸æÑÖÚŒÚ-)¹m£J£Z³Ú¹VÔÉ¹šoL5¾?®Îaï”Ğ¯Pe×Ö;J;å…‚‹qÙYÓ˜/	>°&¹¶TR(7|´ÕíÇ—»‹å£!ñ ¶¿³…öÈh”Æ†¬¤>OÃş÷ÌÏ¤‚ŸI}ÈäÙ I©$]œZDE€ãó ¸¢R’À•çcÈãÛˆªÕòà…]]°ây \¾#ƒKÏ£sÃó`ñ<=ÙfÃù”¦”Ô½[°$‰Å(9¤ç²ˆF³D6*¸¿‰ÊQEdmAYâZÈP`7ÊGe ¶…ŸGï‡ç
¸ÌD¬¢rÇ AúBüÀ¯pÒ~—NãÁ(gT´F‹dïÄiók®]ÒW°m©:…Y{Ç&AU©š—2j¢æ•ïˆÒ÷RÑm?{«çwß#Ø0qB*oK…KmYm%›||9$3÷ªŒ^xÖˆËÔ(Kr@%írã‡™Çeº#‡};šçĞó˜i|·ÁNª¨ÍõîÇ÷C*©F'¾4E3ÌFayşœ$¯òæFÙs˜Lá©aÔ‚Û9s™…ùÒÜl
ş{šÏ,Pë"âï)Ñ½m‹cnqÌ¼cXæÍüLöY!;åÿÛ'TÜú»'~ª#~/ÏñsŒT„¶xæmTğSÊC¦DrÀã¦ÑHÊ‰Å•Šÿâ¬%|bñ	¼!šmÃÜÒ;Ô÷âUœ[²K‰Ñ2$Ÿú€Åù@ˆ ğä
o@3ƒX½ À¦ïØ¿NÂKi(à[á
ú¯…{‡BQ·¯ÙP#éq!éïğV¸œ)v—¯¨`”,xN+úBK:¼‹¢ÛŞOïÊŒD×JuÕ­BLcªÒºÕíZæ.0³ÒŒÚäi*å›Ö	…ÛÓXK©”ô\b˜O£Ú5=ãcçmŒjûóç#oÓ"]Ím´IW×Lä¬š2›İj7(R<°sÅ!EÂÑ²0’2“úU!s¶NcƒJ™%–çw‚äM@ª½d¸4M×o(Í²›¬f':üo2W¯‹lEZ²Ì¥a¶”M8,t_’Ö¥´ù¡-¸ènÙ)´…õ²YH3Â.øåJm¢ã‘M…ËŸfÊ=à:ô6	¶mA'ÏÁ¸xİç¶ıîõà•Èz=ÉÑ¨İ‚n¢na Cw™]&;ğe‘çAß¶è¦_›–™–@(ÄCË>Ñì&³Á”'ê‡Up\Or;Šı•@Ş6Ÿ-||Li|hTöL*6Üq~Å‘¨} &ÔÌº¶Fœº©¡æÂZ'\Î+	ÉZ^]Hù!èâJ‚ÍŒ/Ö†EŒxohEÜId+Ò¯ûºƒ.Ë`ı%â¿×#îŒ]ÑÅŒ°MıD‘´ãb8ì0Â‡µı½Q,Z”:Û–y]èÀ+¹3É&²ø’!Ú²gH¦¥@&qz5$[À‰ŸÌÉT`-4$ëØ­‚¢ÚÅå÷[œƒ’8,âheG½Â!¯…ó
EU,¿à
c/× Ta¹/UÓ«"·,¤“ÔŒz6m®šâÃ‘;	Š?uŠ;
>WÇNbÏÒmêÁÃ”T¿O+WóÂº#EÜíºq¢ñpÈ‚'ú›òjíñ²È17e…Î2|‘FÖ„4ôÌZnM²–[S¬åÖ|Í~ÎoôAÎÙrtW•‡%;¨µõc	ÚßZ
ZF·ÖÜi1Š+ ÛSœğË
¢%¯ÅqnÂAÔ™ L
(÷‰ç¨\¥¯Ô ‚
R$ŞÕñ.°ò¦œ{Uön_a¾9SéÆgÂ™óéØè7$0Ÿ÷ªå}/†(ß¤ùı@Ïâ”…6ğù³¸î¦HÆ5R"p¼Ä…‹õ.øÇ¡
:T!S–5àbyÑ‡Ú…2¢‹¶PFq¿qä>_VÏèB¨}GîbFqcÕ<¥hø‰áÕTÊéæ{~ì4d½‡=¸d]»ı&úŞÎ…zf”«=äÂ=s³ã>ÌÃ¶lD¤ªKÜU¢Ç˜äyBBg†:âğœ®ÅZ<ÖsMmÓšìò‡¿rW·¶uÅ_e+µjÓÜtïDò2({,¡Îa¸5)Æòv’!h¥áÊÎ¥‚¾%LÊp´2r]‚nf.S› ®a•
‚{n¢PÛ†Y%·täû‚¡ş_â{“{ˆö³‹rÆcİ°éÒ0œtá;Úñ¯jl~æYl@}âV#«¥Á	¿eñCnq?¶£l,¸X¿ÊÓêşÈÕˆ:W&2S€m÷4Ç9Á³JC‚`ü}´Gxª3JÜ
î1{'ÍŒûÒfJO*,èß¹Ñ…ÜH¨üö`l-çšèûïL%¦µÔyA¤£JÔµP„@e*Ä„cƒ`Qd¾¹„ìa,R@ò¦cLR|jZìU—1,şÆËàñ?
 Irù|±Xœ"Å«®¦¯yüØV¶ª™nóŠÊÀ /ËËqã¿´ºêÇâã¿”+æ'ñ_®#MS¥ÊíÅU¡š$zĞŒ+0·Q5ÿÎŸù«TŠƒe¤©ÙMãKqÑÅèö¨ç~jÅåÙSµş²Ä÷ó½+úÊ¦²¨à×óo?°K¸c°8­§;Rî`ÜV[¹ßÌÃi`jµZŸzá/°yXÈÎ†b¿ç,r#Btôˆî]£õw·O+ïOèûS«{Gô€Dœ.zÓw ºIÃñ)+/\À#ixÁr©Ù!m´F­-F<Ö°"ôÄ¾£¿¤èë6:Õ;uŠf°lé°:ÛºÒÑJ?SŠrmk‘À.h‘=êÃ€QÜ]Ë’ûIÛhPë/!šº­u¨XŒÚfØ^PùJc£«KÈ$“‚h0;Ô€ù“e¦î8L^Œ›…Ş-‹Ì$S°öùU;y„R©÷Íµ‚â;è¬¶ìºÕqí~û€vğz:ı‹.z½OC“D”‚‘fŒ®ÑÑl$ã4>G}>HE8
o³‡åÙ À'¶áºº‰0d3Fešyd£²i˜ı—äñÖßù£j…u¬Ğ¨*X)W3Lé}÷4§W×mhØ® lÜèSC3É'ºãœfk®²f›–ï´éÎ…zä´û&ó”ùçeÕ‘ãDƒ=‡Oı^`¸<ÅèÔk¿¼ÇDkTF;,®¿õìwYàç‡âB4k†<Á	=õ–äcg†Ğ}0×{ĞY´6^PÑ_ıêW4 ÓåèÖ~“%OQ&m4ı9Éösù¬Ó†¹ÚÌ†#évÕ¤óùt~é0¿¼Vxo­øu.±·Q•pßj‘ˆ¬s9#Éeòó¬šqØx˜NîNZÕ0f§KŞÑe>p´–¾U‘§éöñsø['J†ó÷Ÿ“øä0¼Šªÿ>bëzï¨‡wïùB7z’ÇİûÏ4¤ißt9”h›Éœ‹‘ºè`¼¥ÏCwN7)í#ª[0u»VS†-Ğ§26ùò‚gÿ”![¸ÄQ¦£Ù­>O,TÕ€¢†%IeÃ¸Ì76P¶¯ÚÒKŒ\ !„øÈ¤†Ì‰¨—òùÌ°"š¬t*U$]„ß™ó¼¿üF£SA`»uı2}è;$Œ‰d…‚SI¡»â\İ1x/šóØV>v†uD™u„NéwÇÕ«¸¸ÑÅÎiÔNÇşbñ¾çSÃJŒ˜—CJd‹œ¨2Ù«á…DÑúÈÅÆêßÆˆ(Ö{9t–Gq§!­å‹}4Ñe»F³ÙÑqÔ‡–}=}qºiµè:¹F²n·Zã:VÉdrC^šõ—ÍhÀ8úä®îˆÄ.Jôø;HøøFæŸÈ—®/,pÆD'›i§\š“:Àü¾a22änFç^À•{Ì	qŒyåõ9¶:ÀZçñ	­7íKÀSgv³,¹Å£xG¡8Ã#å;”2$JšĞÍÖT$—é#Ësñ‚ÕDL~Œ”0q	à@fzÔ¤¸p°ßKç
éüÊa>·V\^ËÏ'ä3¹LNH$c)ıòKlæŠ ‡¹5˜ã€–„T#Ú±Nğ—§Æ¥^Ü$’ˆ)ê!)û`0
±BÊé|(¢.G2y4˜7ê~h¸ø,½³‚*æ¡Èâ*2,¯·Œ‡óÍºÊËô½Ãà¯§j­é9Âøy[ÉÍxğ(ÄãÅö?b7
*õVm,ª¬ÈnÄÊİØ± ºL;6Ó”ı¢ù"Ÿy/“;Ì¯bòƒ=†)/‡DÉ×5ê–,)^ÓÀl<²‡§°Âßgr9ÎÑú—yFšİÑ¹†MÅ¨\anp‚‡Ï¦è|#Ì£èŒ£1€¡íeö= ud§’l!ó\>.gäŞH@¸`ß2v<˜$üŒŞ©6Ë-~Eğœ—a
<°Š—\´x07$pòÁßIëŸóá”OØI¥ü„Qô„¬æîº’İÆH¨àt²I<EH*G	I<!¥‚1:¥‡Áßòù¸xLÃ©°¯JvŒz6	³2›ô¢“Ê_ÑÛ“ü›ÖÈÿÙ “iÊO2(6ıQ×a"«e[.Ònª’#°i0Ó;Á
×F}ˆ5>é8è<ÇéRÿ”FC¼Övz7@ ÈVaóĞ¾³5-í8„é f¸ÔoÖ@JÜÓ™ã‡q9õæè3²&2²ˆTœ§»l]‰Ô+$…	lPq8©¥)²ç•Í_JæU½6IØ=BîÌû¾Ö!Z“êä©/3…¾½X&"t ƒ9ÏêÛí¨[”ÁQcÆÅ #² R‡ÕDD+v8‘dNàQ)•!R†EV¸iJ5¾Qü]ëàå×k;÷¼Å(Ã)6×Ğš^L4ïİ@¼]í…N<›ºB—PôÚ‚Ñj»1:Î0¦êvY#÷ÅLûÇA–Ù9Äí¸zhG®îí"‘ÕÓZÿ\JY’_™àº!Ÿ ¬xXò½ÉC“£CÇïu½qO½ÊSÌª² +(.;M’dÄhœÜæÄœc
Ê9òä™£Ñ·ü(ši¶^óüY2,;#éiô?)©Œ°¯Ëv£m¸:=SL&œzzq¤…Ê.<?±ìL­Œw+dÓ\qÅ˜w¢Úwúô@”:êÇú0—¬EËÀ¦‡ ¥ñÀƒÚq²y¤›7˜DµÌR®áÖ…†»c¼ˆ<I]¤¡/ıCUEY›A,L¯ñ1R-Õ˜uHÃîã%öEvIOÁe\ØFv:,jÈ”y²ãEÅ¶{ğ'F‡.86©ÊQRùy!GV!ñh˜â&ó”Q+g£{G©.2´E¡Á]ä–yÊ‰k„HÃëFœ°Óõ‡T ÙçgÏLS¬˜KÈKahx2ÉäkŠ‚ÒkRÑkAX| €¶täuğ	úì[ÆHÏ_è1,?Â/±š}ûÔøÖ§ìŒÛlt`ê8Ü©)l)˜ÖUZìg¡…0Ä¾ö× ±“€(¼Y™¡âÛ®@Ëıè€jMùdBõ¶2¦¾#(6˜xÎ#&0uï‰ù‘û¾­¨UsBá›Ğí¯«¨"RFô*[‚#Œo„0}Qç OáÅÒA5ºÜ¬œÕì£Í‡¢6Èiâ¯Êkª½	Z4ğx¿mÍléÍÙ”âÔ‡šğ3W5ô|¬£
®_hcî÷Ä Nèjƒ]¥'pf5öWÕæ)ŒÍCæùjL`Âˆ\§K›TiµeÕcO¦é*Jk]Gã“_eÎËæÚüø ›É€éÒÈçÕşcmà9…wõ—®è´ †BtZL7ñNŒì­PÛBVîQ£–ñõÌêâ  ZÀËã"È5Ø^7\O¾¨æk¶(T$}#v+
^¹L^õ×k.'+j–&‚fâsÊZY¤CÊƒ3dËb3a(»šÔ£ZPà:;a+ËÍ‘vô—®­²¸3O±*FOtq’ız5õçÿÜÅ°ƒShY‹Œ^î"=2 ô|@Š–‘ÉL£iÕ½H?ğgğÈ-²Õ'È8ãxï›u&ÅĞ˜YMşy™¢åÃó9ğÄS}×L*tÉ‘ñª:*Šë™üâàJ¬Šn‚
I‚ŠUŠ»¨¨–dy—,U&å":”Ñµú¦Ëä*w£ç"£ÑGS@ƒÉÄ¢ĞH‘˜Ë9¾pê‰{AÓZ!o¸ÎCíõ,İÉSŠë¨=«ü,ÎÑ–Î|îÏOe¼¾«{|¢uÈ Å(u ÕÍzOCyjÜS2u2‰ÚêÈ3P–;@îR‰XßøVKºB±0øğD7o¿Fµ…wzJısé-F
’ôådüúr¶ Öâ5öâ"í&Ú’9H\uåQŠ«/-T2C¡Hß2øÍ
År¡*`t¡£Ÿ¢ÇƒÓchQ Cíæ¢Úw¡B9éFåÙ¤³Bå*‘›ãÍÊÆCJühˆÖ7Ğ˜6µùâÕ“DF©./A¨P¡¡í#~°B%“§Èƒ`Æ~L¶¿ğÏÛ¼Õ%Ÿ|22K¬
‘GÄ‘í:5^^äùŞ3¦*L¨<¾§ĞæuÚPC^Q"lÊÂ5‹YQ”­¿²ÔÌ†Œ+ÓDÒÂ ¥–ÛŠ¡Å•´•­òÆvDœm¸Å
µüb5ˆO¯…,~„Lq·7h*(°‡IÀ£x£ÍH -á ¬ROÁtT—jŸlDÕ
Š[T”WQÕ•"	 ®Š·•¹Œ³Â;ÃN.‰â›Öh%ÓMËcƒâIúuİ1„ÖÇ2u4Ô6‘qâî£nëto½/`5œ>™]ê˜@m¨ËUW­°yª" ~Ç­£€±««½€Í<Ucæıò†HÜğè—]åş²<A•¨|5Xq~Q˜ù™
İæåG¸çå+%±hE~#¸æVÍCt0…È×©Gp?….¨‰4à¤>
©§ë„ŒbTÏqXù:8R„Ï+î<gŠ²Sà½ş™ÒtbÄ5Bß±2=+ê)Ú–ã¢¢hQ¡\G|Bghíè6R´ò˜rŸû\µ#óîĞğùuv#ÍÕÙ ö'UÈi¶:ÎŞ5-T¾`½C›5]sØì2]ÊBE	Ãd—&¿M%—àé¤H$·Š8ºúêÙ _L‘X’¼±&WÓ¢ºˆ†ï¨Ò¯‰X`ÚÁs?Ë3­Aã¾ÒE©2àHõ‘2¿e>Î ìİh8ù½B«ïJˆÑokb|7j™¥J¿Péşù˜†'ÍZKOãc~AÏŸ”»ànÂ~‹èû1=‚èûˆÖá!.Ø/ ·¼Pù{ã±aÅbÄwÀ–¯İƒÌ­<?ÆôHJx¬(àúù•~#TŞa½áÅS2º8š¤P¨é„’X¨XñBR]‡¥Á?…1Ì(å;v¬ªfçç†ì‚ª¤ZP|X™.%+¨¯§cg¹|•»¡^ˆ¡çb+…[ì£ÒÊ¿ÆiyG®^ÏÑŠ(§p{A‡l8ís;!J*Ô¤ŞoátÁj¨ÛH´Üû$<¥ŸÔù5V‚±JqÑZ@ÑYùô|öë³xÒ´UÄ»sm×í9kÙ,V4Ó¢@ĞÏİ,å‡ –fAâì»išËÉÎ¯%“äiU˜z²Ç>	¥·íáÙgè<fwúõ®Á\KÓ§çÈŸ…Ló´ã6Ì'a‚Òe
}Ø£&é›ô¶
T¹K”.€‰¸ĞQÈä2äs«,å”Xuzì¯Á€öNÅó,DsÉ‡X=¨İÉÉIF£3–İÊòâœìæÆzu»VMÒû ›_üş?ĞÏ›@tÕÿG¾XX)
ÔÿÇJ~âÿã:R”å¸Ëìÿ#·¼´’çã¿š[Ê¡ÿåÕåâÄÿÇu¤éŸPãÁÔm´5z¤Øf6škdfìh=7%åG‹äÚ ¢[Á0%V®W?%5¾&Í=¨Ôæ!OMÓ[è« #<;Àaï/’÷€İGÍuëv¿ÕZ$5X¸¾Ômt=2öJ£B"ÃÒZÈ,Ş—û.ˆ3ü}ÍÕP/M—#2Âè<š:Â³[¢>ryà²¹«MÃõrÏlj»Îì
œ²¨ Éy& _0=ıØÀu*"^00%Œ=µã7ò>l¹ uñ%#!j„G-İõOó£`¸†:§Á
Áâ~0ÒNïA;ÉÇÚ±Ÿ®ÁÏüû™Üj¦Ë¯€Ü	Ì€LNë.\ÏŒ½iq*`~Ql`BœPË=”8P?Kı¯øö"Ş5=`è‘°ZŠ;A¾ºî[§â!'ˆxĞÅÕ&¿şË½÷ùşúô#<¤£ãgŸ)®ç+f²Væ¾Ğã‚à&Tû`&í¢Ñ±/K%£€áÃ*¹Z‹íÓ77Y|Ñ_”÷7v¶3 B¡v-Ç1ddbÂû„†/¤r{WºågıŠ†~Q9^I£8CÖ NÔ1B(UÈC¦İsdˆHÕ³[ÕbÛ¸_íxØÔËŸRÕuLdıÂŠ|©Áò™Œ„•¾ÇÉ/­I£"±œ¡Ú‰’?µt7óB¨1/Å>o“ğáé=¼¢ ákÇ²Q¬r®(SµëÃKŒÔ»cèö°Œ¥ÂFà@c Z¼å8MW,RŒi¾4ó7ƒ-œ†0}ƒ;Á[*2cç¦FNòûg”jÂ‘¦†nÂ`ñ
Ê"ÿç
+|ÿW€o«¸ÿ[Î//MäÿkIßúŞ·§Ş™šÚÒd§F>Ü ŸMİ†ø÷ø‡¿ÿ­ÑP–÷÷÷øWÌñ/Á¿»„ÿüG 9dĞ é€Ô‰öx1iz·†€Ú_×ŸÕ?ù¿şøRíœ¤È¸Œ{%e™ÿ«ÅÂj`ş/­Næÿõ¤«Úÿ_™à-ÕÄiŞn€z¥î!¿V,nıÑjg–ÏƒûIßmH[„°&ïÑ fàuPÏÆL.!ğD‘Û¸Ã««V"¼jZƒÎI×¸}›Ÿó†SçÔtµ—l—÷JñöÒØ+.Üå×ò¥Ùgıµ×dÉÓ€»úçdV@6ší@pÿí¸ß¨—¤µşã‰d”’ŒzdT4	 ğ£•ğhc>l;VèÄ#C›0ÒªûUÔH¾âÎb8 Èr¬ñĞÃc±õÓNôbºEGd‘a1€è¨ÂFâÑhM–4	•=ox=ÕÂ×8¡`s‚êgÔæ%7¤G&ët[‹ç¡=ıK´ì•ìì8~¶=„çòûÒ›´Üˆè²S+0i+~yúei–~MSk†9{,/Ûí ÚÉÍGíÕ0uÔÎñxæ,ûŒô±ÀtŠÓ€J%i¸n~P`¶'É¹À¬Ô@ÒÔößvèÛ”ÌRÒ[¼†Àz)P8ÂPÿM†ÂÙ†Âğr³IÌhG5*Pk£äÍ	º1šMHØŠÒetDü×Z=¶Ûƒ F$¨$uÇ¼^kõJ³^\Gï¡ÕfO¥ ‘â¼âtÕ&^ÙÜÄ¨†ë¤3Öæ×ÔMº”)Íâ‹&É,ÀdiXË.i}×ò ¢ÑÔ½÷6CĞqmï‘ÃEas:xÆÌ5JB'“rŒO-ñ:ÆÕ€ö…Qd+æC–ŠùÙõóe§&aRv[ïd¤åcqÎ‡Ã·!(«4{l„â¹Zİë*jˆÅÈ¢ïE?ø ­¿J³Š)X:-ìÀåFøR>/›M¦Ó®+C¹IghV¶Iªa–üû[­âï…Á0¦=ƒK¹&N¿{³•—P‡®fŸŠj5˜§)éõÚ£b-",OÓi*àlÍüŠPP	Wj`-5ffN|ÜœÙ·GË,ëe£·q–1¢şw)¿´TX^Y&¹|±¸´:Ñÿ\KzÃõ¿&×ÿşıß®O_ª“™¢/·Œ!ó¿°ºšÿğm2ÿ¯#Mô¿7«ÿU\~%ÕÀ²Õı mpP,_•›¨ƒ/^…·]<’zñæÔg„L³[HoôêÅØ;âr›z¬æ’.ƒ¡…àÿ¾—å«[c†ÉÿË…%ÿ1·’Çµ3—/¬.OäÿkI,ş£äÜYA’<‹¶à_Çµ_øêaof(>\’Ö¼§Ëüi™n¹ÅÓ"º'mÓÅ»1âíşİÓŞbCèEŒß0ˆ<a×Ûk[ÉéóÎ%’ôƒ¾¬å—Ş{-¿²´²¶ií½÷á'à}{öîãHÑ®ÕÇ[Æ0ù¿X”îÿäòhÿU\ÌÿkI“û7rÿ#Êàm•ücn€Dê“ +0^Iızäôä˜Eï7Gğf«î<Ò›æóq	Ã§\u¹Ñîÿ‚Ø¿¼šËçéıßâêäşïu$?NÁÕ•1âøãşoş¢ı/HŒ“ñ¿ˆús%eœş/­æ“ñ¿$Å)9ÌTj‡4Ó˜Ë¦ÿÉ¯òù_(®WWèıÿB~²ÿ»–4ÊùïÃ)vşû3ˆ‚gº^’Î_Š\“ôf&iş_Ñì6ÿË¹ÜrpşqıŸÌÿkI‰ıfæ5|½5Å>ïşCÑ ·ø¿Pz‡ş`ŠÚv kp§ôN+_kXİŞ¸+<I“4I“4I“4IcI	öqëÎÍVc’&i’ŞÀ„üğÏøç±Ïÿÿü¦”ç.ÿ$üó#şùGì3ÁáŞáŸßäŸ·øç]şIøçGüóØ'gZ	¾ùHğ’|‡’à
ŠáŸ«É“4I_«„{÷ß™jLÙSú”Ş¿ÿÎß¾ïZ•J³ï6¦¦şæ_û{£ê„ß7¾ïµeüt¶²÷Ö”9•™jªåûVğ½TşÂ?ø³S¡üRù‘ï#ÊÿÔÍjÔOœ^½c¡MäUïuÇÍåş‡Ä;ßøæ·~çÛ·nİºsëOÜz^k['5z½ìf?Å_±Î¿ï[VÇû®ÕúÉáİß_åhf£©È³'†Ù´NX}³é<•^Ü¾}ûÖíÃ»?|õjùıåE²´’;[$¯ò¹Üû‹d¥¸|vvûÖ÷ïåK¿ê~ùêõÙoşk‡`‹S¿ß¿ì·OíÙåJoœãuÖòwşÑòÿQ´üvòÎ?qçÓÍO·¶wïŞí;úŞ¡ãĞŠÄ9¼û{è}£a™»¶~M~ÒÀHx&¼ùNCë`°W/w:5ãKİ°­Ng×r4öøü3<ÏÇw¡WŸıÂ±lw"ûÌ üê»XÆuMïp7Û·oÿ¿ûı?œ™KV?,?üíïİıÎwïüşï=A–zG?81šnûsÍiè4û/ «MÄ¥Û·¿óÎnïãí¾ß~÷?üÑüøİwƒĞËgıºñë¾áŞ¾u‹•ñ“w§oßıã[ÏğêÒ–Õ¤îäé›wòîì­[Oñù:½ßüíwï~ç÷æŞ½³ï@+îj·nÓ'™ì;û/€î:·Ù“¥å;ït´ºŞ¹Û¼}‹>zïı;ï>áæ'w?åK÷ï¼ûwï|'±x›Õéİõw«·îş·~‰e£9ÏNO7¡øıà‡X«[·>Ç7åfSoŞö.WM4Ç¾Ğ®˜şˆ+aïâªüîTnêÁÔ'S¿œêMNı¹©vê¯Lıõ©?úw¦şã©ÿzê¿Ÿú[SwêïMıı©ÿcêÿœú‰Ä·ßIü0‘JÌ$î%~šÈ&r‰Bb)ñQb#ñIâÓÄ“Ä¯z¢•h'Œ„8Iœ&¾L¼Jü™Ä?™ø§>ñÿ\â¯$şåÄ_Mü+‰3ñÇ‰¿‘ø÷ÿ~â?Iü§‰ÿ,ñŸ'şfâNü/‰¿øßÿ{âÿNüƒw¾ñ×X¾#¨W%şw~W¡q>»ßùgbhüã?ùô§o,ÿ­ßÅş‡ÿùŞ÷É½…ÌÒ{¥†[¡H™)õ1ò¢d'ÈŠM6îüaÜÄ9€úË[Hmw¿ıÛ?øá~ğ“Ô|éíıùÓÙß¹›€)q›şüÙ,¼}Ş!â;¹náßı+§xgõøİo±·kw>¼“àî7ÙÛŸß)ßZ¿û;ÑzåÎ»S8Wo%Ú$û_NıwSÈõÿúÿßJ$ßM|?As‰Lâ½ÄıÄÏë‰jb;±›ØKÔû‰ç‰Ã„–¨'‰NÂLX‰%Ø×‰³ÄŸNü‰?›øs@¶H´ÿ|â/%şrâ_Lü«‰-ñ×ÿ:%ŞH÷?Hü‡‰ÿˆ÷¿Mü6@ª›*©&ş'ŸT¥%îßşİì{ÿ¨ü¦óF]Öş¢´¬×l³c™­)&µsª3Õœ2¦Ôåà› ¿‹Xd¥w¡Ö{±¸ŞwÖT‹.À.ÂËü7oÅCFÔ%2T³ÈˆzNÒ$MÒ$MÒ$}MÒ7ØAı5şü’&i’¾Â)ñÍJ­ò`Ê;%Ôµø÷+‘ajğAÀ;Ì`h?óLºŞ˜Ã€Éş²ÿÿšïÿ'éë›|ûß«‹9úıŸâj.Gïÿ‹ÅÉıëHşøÃbdfšWAç¿ÿƒ¡ 'ãI²ÿ—°µŒ!÷ò¹ü*óÿ¶\\)pü‹ËËËûÿëHÓjà=¼õüˆïq²Ñg×‘-Ü8"OÑÑoÁØòü7“·3şÃä‘¨æ½A¢Ëî¸)ö¼Ûï(»ek]'™Ü-ï\šÁ¿k3èÎ(›ñ\}óÔÛ“ˆ pÔõz[o¼ğ#ç!ê¥Ñ Ù^œBVï”äE<EJ$•òjOˆh 1WJ+C’‰‚€7zÇÑ)€Şh[$UİÛÛÙCßh"l"­SdNè,Ö_"r†CÎÆÀ÷U<‚#ôâq¬¾İ`aş¤NOÍüõò}3IÊı_˜„–‹nBÆ-œı‡U`rÿûZ’,ÿ¡Zàå¿å|ni5·Šşß–ËùÿZRhüÙÇ!u°–é£Œ!òßÒÒ2õÿ—§ÿrÿm57¹ÿ}=i\>s‚¹6Ì#[s\»ßpû¶Îù7IM·æÈõÆ|rİq(~¼¾¸”ÜA?\°ä­fò…Ln9à~+èf«Æ\Üº–ˆ­C+K*z¼øÚŠt”µ	nzîz+•M’ÏäÈÏÈ£İMå³o…®™×ÅÑuÒ2\bóæ‘6ó°Eı6a”b˜ğµËı}™<r°“í÷PY”²¿SÙÉø­SM.İDX$xGº&N6i7Ò4• W†ÃfZº;7[ÙÙ*oln—·ª³‹$µÓ=dùRóAOsÛCàæ dû¹|–es²÷œ¹G¤ZÌ'iô
ù†Œ†éÎ±²¸;£‘®Â^;5/2;NGä”¹VÛ”òüü}ÜÛÅ5‡å=¨U÷0ã‰^éÒh¤¼ŠÃŒ÷ò¦x-ËµÚ“½
l`’=+4Ëè›ÎV
»FŞsÏ:ãƒ ø®èæ8€î»%%p¿wƒĞĞ<Gšw§ŸáÀïŸHôØ>´ˆD=Ğ~t­'›51ÿÙÊØ“9ÖŞM‹»WõºZê‡Å$	%1N~Ÿ°l~Ê…”"¤Ò/ƒ2bOmK“ËïŸa¹ü^+…ú©ú¸ôÒşM/±otŠŞÿÿcCä?XCû¿‰ÿŸkJ“ ×ôá­õõº)„ç´•­.Ô­ësÊ-û.ú€å>V¯;âB>“Ï]kÄİrY­×Ë²„\ÏŠ6Ñù8‹AŠá‡ 2%÷€,Æ|E×K<ü·anĞ]Ã™Ò²^Ğ_l KEú@JÅ\îEòl¢øıš¦Ğùïx—~š†é–CëÿòÊÊÄÿûµ¤Éú?YÿGòâ«Îâ;MÖ{©
ãÆw¢ë/:§ä¨ßé&/ #|~Ù}Óó‘Ïb·pàÄï“ø/İÇÄ-~ğƒc!Ğ8m’vÉÃƒÍM’î"ĞÍº–i´Éıû$ëv{28†â*Üÿi>yİ×Ôè=ÃlØ:Ò¥vs˜[,,.-./W.ÔÛë{Õ­êö~ùMéUnzq}=Y(Ğ\µÿ¸ØŒıw»éuø¦’jÿyÒq©î:ã°ƒš±”1Lş+–¹üW\Î¯Òó?jÿ7‘ÿ®>mÂbø®s Ş t†¥£“–¤3PBôp’´–‰’ÙUqh.	Hl²D&PäV3Ğ=—"Œ$’	˜<=™“¥0ñæ dIñ‚‡MqHèiµ4çêØm¸¢›x¨ÅZh¨$½‰|JTNÄş×ˆà~4^D“p„¬bŒcCmñDPÅæÇyC’ĞmìÌÑ“Œù)7¿€ÙIèA iÙ¬àhÛ§`izXèéZ]?Â#EÜÀ²äf’Ó
ô‹-DÍYØĞ5å½ÓoZ¤ÑÓ,:íõ,o&ÿÌ
¨²Ş¥øYÎˆ¢C%»@W9[ßÔµ†Ôå^J“gVLí1e¬¤«™}­395âµÕ;?f+b$(â1r½À¹4=¥0˜Ÿ¹÷q±Ê·xì*bë…¤"°×€‡
VnRƒOİ!mëí‚ÇXïäSd Ï“Q1Ô¿„‚”ˆÉ'šé:%SwO,ûEÆ©¥»Éò‘«ÛÁ‡$ù”óåçÉıÓ^r˜àzÏØJLÌJ>Â	X²xx®äÈ“Ì›Å¥ X†ÓÍŠ¿€÷w–5äãÉêK½Aiîüy³”ìèõM<
DËU†Ìê] Wâ³z2:¨—ÙÔìæNßíõİP%êW¡Ÿ8yN{÷Ü¥n¿ãi,†wçM¯éçIªü'bRcÈ!òßòÒJÇ\Í-åŠ ÿ­¬./Mä¿ëH“ø7ÿQ™eo­F0&ú#™D¼HÒxÚ ¦du/Y/\Û˜'äÔêƒ°u
‚—Íèê¾]êr:F¤d(ÆÃÔmEc+µ›Óö.²Ôuÿ^äugˆØõó&Œ$<¿B$ÊRärŠÎ»rBôVF]½†”aeî·u• ˜´ƒ™Z?äïÈ‰4º´cÍèĞ¥’;ØVÉÕZ„†LßÜ<\?¨íïlmü¢¼¿±³{µk9ôÊ»ÔS¸—Qú„îì•×7«ìÒß03B,‡o}°ş&eQL{) ©0œâ“¿Ãñqâ}A¥
yÈ*åır"òwNØº¦æj‹"oQ=âw<l^°yZG©j"g|ıDe²Š¶7xıÓƒ]Ñn	+×ÛÇÉ åQAKÊpC¨vb¶k4›ıD³uõÃ­'ı…Pc^Šï“òã²\Qß@Ì°è²¢7wèBë€ oRÏdÓØ29AùF_u} >”9C-d`3R±(`V¼°c=†|½N™¶Kå-NïfÆÎM?Œœä÷¿¶ŠŞ˜¤Êÿœ¡flgœA›†Èÿxİ_è…\Úÿ-Mâ]KzZİ~´±]}ÜÓpzïrO3¥|&ÇşK>}Tİ®îm¬?OÖªë{ûŸìï­Öo”·>gÌ­v°‹æâ¥#­ãŒ?’Ü$;EíÿÇ¸õ§iÈü_-VÙş¿PXÉÑóŸâêòÄş÷ZÒUíÿ'¦@ÕĞ¼İ
€uÅ˜® 
/ÔkYD^«Âm‡¢ş‡D7NO…íDjø.¾¡ú¶sŠúõ&İÅÈÁH¶ñxÿq%*óøFÌ‘®W€g(…×`.™f‘Ç^¯_¤MµSÓÕ^²x\Ş+=Ö:}}ì^=jùÒì³şGÏÚkÏN²ä)sY!6gÏÉ¬€l4Û%xëoªÎü7ZIÍwH/™I õ’äÃÜá7wÖË›g£”dÔƒEP  sø&K‚mGÂJ xd°·s|H«îW9P#-ø*K/O	 à½Ø!zù =<Qï1íÄíøjÕ}Ì±¾³ıpÔa#ñh´&Kš„ÊÆ7¼jáŒk	œl€¤dÕÏP|CÀ Ã`.¬Óm-swó%uwãÍ9ŸíD¡ãy£ü¾ô&m™;İ¹ìdR'-cÅ/O¿,ÍÒ¯iÊ¢aÍ0g¯€òŠ°‚±r)gÖmªvÚŸ$>5PóçwæáæFmÿ,IHÓJ2•fŸ1Fp{P©dÓ2uî,9Àl£I"¹À¬Ô@ÒÔößvèÛ”ÌRÒÛÔ õR p:…¡à©…³+OÊ3ÚQ
ÔÚèÄysF‚n†fÒ‡¶¢tÿµVíö ¨	ª I]ç±#¯×Z½ÒlKwé½T¯A-«Í2ê!*ĞÄ;xƒ¦m½Ó «6×%mnÂN¶´N:0ó`m~Mo¦{@™Ò,¾h’ÌL–†Õ±ì’Öw- Mİ{o3×ö9ìQ6§ÃÁgÌ,@e\Íè´I
9Æ§‰xãj@û,Ïf+æCVk 6ßÏ®Ÿ/»nÛ–-e·õŞù@†Áî*ûXœóáp¨t
Ç†Uš=6âA†áju¯«àg¿ÇÈ¢ïE?ø *ó¢4Û¥öIiü×¶—º ÜÁCÊçgèBi¹6¬å4$œ¡YÙ&©†Yò­Ÿ¸ÙSŠ¿Wš©0=³û¤røpc³*×Äéwo¶2ğêĞÕìSQ­¦óş0•ñõMÓ±¬…DM„İƒìTÀ9Ø¨°kââŠPPI¶wÒ<,÷¥+7ffN|ÜœÙ·GËĞÿØn½ĞëŞË¦ÿ…§¾şwiõ?+«ûkI†yûC˜k‡0æ!Û)J ‰’ÛaK±»éÚOÒeS´ıİËŒM<ÌÿÃêjù]Z*,¯àü_]ZÊMæÿu¤‰ş÷fõ¿ò\ûjªY‡jƒƒª`TLÔÁ—¯ÂÛ®I½xsê3B¦	†t¡ô†š2ö¸Ü¦ë‡¹ØOj)$;x­ÿ°;÷3Lş_.,ñø+y Eÿ«Å‰ü-iš2XÆÀ)çfV$OÖÖK×.|Qà/6+å]ê
.IkŞÓeşÔw´‡O‹üé´MïVà¿ûwO{:Ñ[½Hv6ğO¥V­æz ¶•œ>ï\"ITì4­Æİ^Ë/½÷şZ~eiemÒÚ{ïÃOÀûöìİÇ‘Bó?sX©>,lî^›ü_,rÿÏÅÂ
,xÿ£¸ZœÌÿëH“û7rÿ#0ËŞZÉ?æH´ >¹2°ã•Ô¯GNOYô~soÖ°êÎÃñ ½i>—Bëÿ¡8 Ÿ!ëÿR±¸êùÿ(.£ü¿º²4±ÿ¼–4ñÿ!ûÿˆ¢ÿäÄˆŸ®Êˆ×éN?=|ôVÁp5î?¢Èàj=€D^ ³Æâd„’.ád$ìt‹{Œ<á+ãDÖİ\­#IZ-íìV·+µCï^c)Eg^eÌ~Ñ|‘Ï¼—Éæ——³)ÕùGŞ¿JeFÓÑ…r—¹úH7Q²üuß€JÊ®>†ä´zÁŒ{:Æá;GV[g¤-D{y[]ƒHşÿ›Æí‡qˆ¤Ác)c˜ş'·´ğÿ»š+&òßu¤É!m°ÚAU2ŞZEM…+i$¯khN…7“ 'pO¥P‹óuñè›lB6%è>·…t¸?,»•l6Öˆ÷0iÕÑ§T£?€Rì–f
ïÊXIÆ†Y¢k§³…»ìu8{ ¤Fgİ2]õuÛÃ¼«[°PÇbf¯Ï…ù¦YÓ$MÒ$MÒ$MÒ$MÒ$MÒ$9ıÿ¾D 0 