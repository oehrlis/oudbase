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
    echo "alias oud='. \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'"  >>"${PROFILE}"
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
    DoMsg "alias oud='. \${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh'"
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
‹ Ä…ŽZ í½[l#I¶ &öÌÜ©byï­_ÏëNï¡T£ÇˆO‰R·ºYÓ,‘U­n½V”ªº§ªF“$Sdv‘™œÌ¤Tê*Í^ØØëõ®÷Ç¯]k¯kûÃ0öÚë×mø	Ø€=XcöîúÏÆ.à`øcísâ‘‘’’(©ª›Ñ]"™yâÄëÄ‰'NœS7ÌìÔ§\.·Z,ú¹Â>s…eöÉÉ/–—r+Åb~™äòùâJaŠ¯ºb˜úŽ«ÙPÇÒÂØÑÑ€÷¼Þç[’ê0þV¿yÍsûNÆi_AƒÇ¿PÌÁ˜Óñ(äó0þ@
Å)’»‚º„Ò×|ü§’E¨kN;9MÒãK€mf£¹FfÆŽvß6Žµ¦áò£Eò ï¦î8¤¢ë«×ÕM—ü”Ôú½že»dîA¥6yjšÞÒmÝp\[sÞ_$ïå‹ò¨£¹nÝî·Z‹¤vb¸_êvG3›c¯ô¶ÖÕ3,­eÂÁËrßm[6Ysõ#Í$;zÛîdÎÒyâÐg‹>ûÈåiX]È]m®—{fSsÜõ¶f¶ôæƒSÖýÍõË–ðÙÓÇ°ÌˆxÁÀvûvÏrt†éÐ©5l£ç×"->Ú:1LhšÙÐ	k!Ñbënß$«©cOX®îˆÚì·a†¾u5Ãìœ’¾£7É‘eÝ<6lË¤ƒ
ƒÓ¶ú.Ù\ICÑðŠÖû†JCdm×í9kÙl ûuì,ë1Y¸>öa…î!UYöéüÌå3¹÷3…\~……Óp­CŽu»`ò…L>0«¦Üü¸ö!£ßØ2‰u„”Í\ÁäL“u(Ôê_j.Tì2Ø“úK:Ùv*‡{;;û‡•íÒÌ+é×Z:dã¶pêe,»•:£¨šMlãåë‘¤è*0Gú—<Ö:}Ý¹Dƒ’«{µíŒf²²SÞÝ­nWJ©ý½ƒjŠŒ˜¦vµzG'«EŽø¢õz:0Àý`§V-¥–7kÀ´Q‡)Hº8›jë{»û‡Ûå­jif)Ü>CfróÉý­ÝÃÊÆ^u}gïóR*ëv{)úðáÆ&”>óJ8ËªÙ333©dm¿¼·øqµ\©î•Rô²'††mæ•Tú™{Ì(žóî;›§s–Ì,¤’[åÍr¥²W­ÕJ@ÓY¶2Óh'«{{;{¥\R¦ˆË$C÷°o6¨.CÝxgß¯9p´–>7O^ykÅpzí”Œ¹t$'
)QÓGkËi‘ÔÆöÃ²Æ
^òÓtûØ&iƒ|ˆ³{chb{½zŸ¤+äC#š•møþû¾³ýÄ²›øï“çQ…’nG;-œÌ¹¸8taq‡_1Ù£²GÌ”˜ìvTöF[o¼ Ë­÷:Fƒò¥R»ý$È÷Éw4ÌRÅ°õ.dK3¡5vºÈ®{ OH?¢¼$&whX0ÁX„Ø’•oÓjQöü«ÍGÈÎœqDžÂÃüI·\’#Ï?ÀõÝLŠf®wtÍ,›Í?Õ7\7óªpF_ëXk\€ãEçÏúüÈHž%Ç¾ÖEN­-FXŒG¹F—
,ÝÞUMuÚësóÉW´Û»û°Hæï­-œE!M ëj/t’­}
“Ál‘ºMÖ·à×ÐåÕˆ]Ñ€A@&1ÉüvRæ»H`qóÆ$?Hjžý­ê!ÐÑÖ.,,MKHêg÷>Oßë¦ï5ï}¼vokí^-5ÿÁRÖ½½ø¬æÌtuÜ(wçS,U)7•’Ø{ ‘D&ÝÑþHÑ)ø,EJ„‹ÁÉ @…¸0––Ñh[ï×	È 'QŠ¼vu¤5i>z9•y5SJ|uÚÆ‘ëý:iã¼§µÆbõ¥umZJçm™_­ÀÃ¡­‹lá`t
¨ÔÒpk›–©‡yÓ‡íþý¨6½a½]ÉÑ;ï*ø³Ç"å…"dÝ€ô{À{c|i¸W [ø"„'Þ{œ%ç‘{à¹yoÍEî
+mHz–ÙU^Ž
àUh&Y)†¢Î'°%n­kõM*‰kv«[d'Cj0¹útYCöÞ°l”;Œ^F.¢0j1™Ã¥}~TüÅ¡øe©„Š@b é›–KÕÁåŒn!÷ËÎ?öÊë›UOº9|P®::zh©4-ÇÑ]ŠXy¨kF¥G¥=ùü0ÌëV¿Ó¤\«ßh³¶Kéös éXZ“<›yõñG6#*)£[ÚÞš«}•mÎ azSÎ¿<4Õ¶¡‡°:M*E¨Ù‡¶†e§£k÷Må®jXÝ®fªè
@×t$=ëÒ0¬[†ãPÉ*,eË=
m(ûWTA5˜¦ÎXâÇÐžŽÎ[mð	B·7°QæSÄ›
±GìO˜h{Râ´4E)jG·Gr¿£Š#f~fÙ³ð+ð-¨‹LÜ0ák—m²¤ú¿ÿþ|`§ò	*ÉN4ÓÔˆò{[ët,ešþ|(Û90_˜Ö‰Éš#ï¥X(JÎBÌ_­ÓžÞµŽA¬ÖQ fsÞËê'vWAY¸ŸmêÇY³ßéx ÓÐ£•ÕoŠYâcmöuTÂâgÙZ<è·dì¨ÝAgšå\ÈàD#ÃJC/jÈiÿ%¹Únçáx4+LIÃ5¤—×C6F›G‡ÉÃ),Ì(ÜðÙ§I!R	0&R©â£„#ràEd¢ Â¢¦²Ý-ä½ýî‘AHÒ«;ìUŸ®„ñÕ%¯_Ã›Ÿt3ðZ® Rj>¥aY›Ø)8Í%{2CfæŽúKbšê=%ô|ôö>¢äûL®NHrðU0IÇ¨*–9Ò`*ÉÖO_HU¨’If?‡9úk”ËÈOŠÃtBR’îBi~@{›ôFDí—¼\ ´gnP“Š™¬ãõ…dº-Í¸”î]¢~×Öz$¥4l9—Â=~2É¹ôº¤ÓÅ:*Ò^P{. ÔI£ÒžIÕüÞ!OŠ÷“	q¾µt×êÙªù{¶…ÓZ¾Jw°‡{šÄà¢>Œí‡xnÒ>6Ö*k_¬U×l”B½m°á‰,`]2aNZŽçrºôÎ˜'[§2!#™îìB×<RÖÐ
Â1ý^ÄBVÙÅÀÚód¯º»¹±^ÞÇÃ…P­ªó*UFcù¹hlÌ,ÈÝ£yÜBmòŒtA`jóE)Y–’…ÙÀZÞÐ:YnEÀ¸DŠÌ¨¨9— ÷‰7“aVÿ4ŸD ¦ÿŸù9”Õ¦ÂÑqqÁ¶ºœõp2}åÁGíÌ”¾+’P m”à0Ñò ã¯ìfÊ>Å#`?~mño‘8Ñ¡»Ž&H}Id±Ø×µt*R}–Œ ^‘M~f^í>©ð†œ±nú	_"ÃðƒV¡å¥ðàðU0 \õM!
—H¥AOrÈtš'§lCz:…'¦•Ôí¹ôû®mõtÛ5tk
Xù©lCõÙc¹M$²¡ èÚ ™–¨ï«D¤ðd4cÃXåÏOçËyœS‰Æ”="ÄgÀ›µ&üƒEGc'õx‰'íiƒÌ:Ù_ÎdÓÙY™!×,O´Æ€%¦,ïö;®ÑÃ³M4½ðPdw¨l
»Wé¢€?“}µý“}ffIöƒ³ÜÀÐ¡ó"þ%‡Z“F¦P)ŠÚeË2ÝØÊ4?ö©éö1ì·ôjò˜Ìµ@\†Ú4Èl„ŠêM¥ìyÁB¤±i[);¬ŽS¹X.(pñn6Ðð·Šm¾UÔP1Æ¶ˆIÜd¸ÅÛ¬”wéŸš·”ª=ÃKº™WßÉ”Ÿ|z¸ƒ§sÚÉ2û úhcûÕ^­”zf¦ŸÁÞí!ýšú`ãÑöÎ^u–‡Rþ¶Õ*ñt(O~C²¿,7›6ŒA9ëL=ûpK™}v?K^A£æf–Øã*k<Ÿçxr3<°xE7%ô™:âdžÖU™wž@¯Î,b>$Í¢ð0åi/	^]ˆ¥%?Nwk”R{ƒO'£3¶Ñ¡b þ‘f“†NÆ—aÆH»c'bDpö«Ú§ÑW*Ä™wèJE5y3»; Â—+[Ûòâ»ŽiÍ®aŽ°…W¯È±Š]Ã”&Åk¤Bý£º\P>>ºŒ‡–÷ùT ~-Mœk©8áž‘¬b±t&h}•üä7@ëÛ¨¢êà´^,Dûù¼0øP½XPHÛ§š{;Òqì Ó7m‹:I×Ÿ„ý73á»ûï¥å\í¿áÛj±Ë1ûïüÄþû:ÒÄþû†ì¿½	÷U±ÿæFÀˆ"âxN„œ¯ºé÷{øÿŠL¿óKÁŒ†éÚV³&ì=5*"rzzÃ8:õíð¡Æm%1^óñ¯¶1øX-ÁÏm~­6Ü_#îk´×Ž°GR¸„	wÈT¸vŸ¤»äCi„áÑè&Û—±×ÝX;\çMàlHlò‰”“;Ô</÷–ft×{DgŸØH_«4™ØHOl¤ÉÄFzb#=±‘æ,òú¡Xe{}»ðM,¤‡àŸØ*ŸÓVyLv¼7aU:±ŸüŠÙOhuûqi¨µd¼¡%+@iÊKPí˜(áù-%Ùî7O®Ì²»f¬U©9äuØBÖbÌ» (i€fæ„œ'`_£êÖÉ>[Ì>#ÙÖü•ÙQŽÅNò+oJÇÙ^`l#X5gRI—âéì=#LW«GêEJi¨î¯sÆ°yu ÞˆM“†­ãnVS-(PO£d{ôÎ‹T¶º
ß#ûå¥pA€´;77jh"ÀìºŽÉì/§gý+g¯}jž‡Åam>¼ñnxRÞÛFëUÂÊÓN¡÷,¢í1x‚ìQ×€(]³aM+åýòYv¯Íø¹ú&·Êõâï¥„ÅWÜ…Š+´…±ï•wx£ Q»6Å9ÄŒAZfžeŸÍÁßùgX‹ÌÂLöY>;;ï7MÞDy=6EWÎ6X?K¼4ÅéºïèƒÈšç Æ†Épý}˜Ctƒn“ÙÅYÿÍs¶Ï¯ï˜ú	eç† Hä¾u}|Fñ>39bµÝlÅtuAÈâ¦–7çBØRìª‡Õ#,ª§q˜Ï!1»wÛRÊc'øtFdzîsÐ‘ã]y“¶‰s=sõ#òšèbº¥Ø£×ô7t(¡_,»•±ðpÄÉ8ÔÊ2(=ãq[fzÉ2¥R¹óê6”gXDíU+-S¿·H«o7tYfËø$*ñ«HéN¼V¥<¿ !ï…¦^Ó[Sü5÷<$éž0úŒš~U6öT½„R­ø£‡®:³åe÷ï¼w©–iZa/üá¡ãÚ(Ä íÌá4Kh>>N@{Ï²\ÆM›kÈQHä sÏ>}ºVïhæ‹µçÏgçC‰#ógŠZì™Œs^U™ÈàlÙv	-à”'dŒ&ËÌfŸ¥Ÿ¥²!ÙÙ–‘…_óª–M#Ú™ O¯Ü–Üg^‰Á8;ôªvÆzuüð:ôTOâ>Íqt¿Õ½ '­õ­­2Êú|C´±}–eÓ&Lætºm9.m½ù¿F²KÉ>ªšh'÷=ÂaU8¢À´à•éÍÃŠvÊ5æ³?»×Ÿ…ý`µa!W:)Ðƒ¡×hP©³ªÎ4L!{A
cK6¬Ìæ2¬ýœñ0ÐJø *Ð<.qÈÍ«ŽJ8\=Ã…t~)Û·lL…ÊdV˜jW¼î’—$íP­ÊÎÞZÕÏbï§pü-H˜òNâ=97G¿ü,?¯ò‡Hõyü°Þ/N¿;»#ØfŸ‚ cN[oÕïþÀ+ÚöK¬XMëÄ\ñS4ÿÄ€YW‡¥nãÍj½™IyÊÉ6}&Ž\Tqðæ‡ž¦‡¤ü2sÖ0Ÿ§—s9yû\Zun*ÐëÆ”vAÒï‘€½«¬BÏ†ÿknõ*ì?‘ˆû½›ñÿ»T\òì?óK«hÿYXžøÿ½–4±ÿ¼!ûOoÂ}Uì?Yƒ¾¾öŸ+øˆýçû™Üª³¥}§„´¯ìE.ëŠS„†eQ]2üÎ|èyv¤Ï'¥qØÞƒÒ\&ÿÖz¾V³ÒýÏw±E››#7ˆ5JŒÙÆšöO{zòÓju·´|<Ùv¿[‡	Í{¢ë/èd}¡ë½$ðšš–Ré´ø>B=™k?yØÑZÚ·Ù‚Ö%"©~õmi½†zIša'*Z«ll¯ïU·ªÛûåÍ‰Mî¨ö²Éø-žØäÒ2&6¹›Ü‰MnúM²ÉÉ$wb”;1Ê½˜Q.—íÂF¹cÚè&Æ´cÚ·Ê˜vÜþHß@CZwÍXë®U¯ÂŒÖ…- USE£^‡‘í8Ý‡N¬FÃ€«Ñ‰Õè[l5ÊçF´eñD&çbéG6Ç–}YÁ§
,&Ð®ÎZµâÒOiÅS€„iµ\$XÍA=f¿c‘"ŽÈ‰®¿ &UÅ'·«OŸT«ŸnïH:—ƒÔ|rg³â¿€=€x–žy…' góó4ûƒòú§»‡µ*P+ô
…LDÉEîáV‚fDs" =,bPf¿
™Õ!ª„ÚŒƒDªVBsø¿à³áÈðhVÅ¾Ýâ'«³\CŠYmÒÄz˜\ÖŽS5Þ|c-‘#Ð…,’q¼5˜MtïtäÓ—/º¨¶Êœ’¨QfˆjGèfÍ*q-¿ÞøëIhzøýÂŠ²eåø¨Oœ¼qSÁŒÎp3BFÙ™Wj]¤L¡W#š‹Ê¦¢$jìøv<¯[æ‘Ñò‡q„ójrúõ†a!éÝ/G£ôQV¶Ãe83nëK¶Í[ßÙ~HîÇµzHÓD0q îœ£mÁ¬ãhÆ´¡M{¦7´¡Ð´¬Ö`Ž§½ßè”UúÙo¢^Cüä®UcpÉžc½‡œã¡™LðYÏhÆõsT/s‹cÞ[‹ãÑ­ã-DNêsdPÌK¹°AñpcâÎ?žô"›<‚½p@Ü.÷]C%54ÈA—t>L³±:M´×Ñ#(kÐe>ÂR<†¹ÿaöãMä¡ ²ô1JYB¬Sd’°¹Ý%i;zf0?™‰oÆ¶%7áÈêƒ¬?§·2a)¢Òó±;"–Ò˜L½yõ&¦ÞçH7mjûF&4þÍzjÖ+)c°ýw.·œ[Aûïå¥b>òþ®&öß×“¾õ½oO½35µ¥5ÈN|&X>›ºÿ
ðï·ð~'~g4”åýý=öæø¿àßw ßàÏïNMýäðŒÖëuôLGs\4 Æ½üônãø&þ™šú“×Õ6®€:nñ:,ÂÏrØo1Ø`Ñ†¹ÞÑ7Ì¦þrjêÓßÿBÿÅüŸþ~æ¯…ÐÞÌ¤Dnº¢2Ïÿ•\~y98ÿ—ó“ù-irÿãfîx–øoóÝ¦œ¢7qñž€.ÂJù77‚ád'·@®âH.|¤	»Ëžì'‚
!n ð»¸ip—©A(dÓj¼ÐíÈ"ˆ´¥»‡ˆÕ¡ÕájBv>cåÚ§cî`nïÁcÍ6Ð¼æbñˆ­¦ÓpÖÔ¶þ˜ÙÖ)íØ+m5,—œê^ìs¹žáãzÀ#®×Ï+·/RŠÒùA¹öñamç`o½ú4÷6ÁÝ-Ó•qx‹Æ7âsL`…}3"m µÆ\Ó°)d*„:¸? ½“&IïÂWàVuÇêô]<ewÛˆZEûðOQO~!¸9W÷€iš<Ä¿îkãÈÀómÆ°RüP(8ZìÎ‹‰L‚ª=ÔIVªË›ü§ÂüÐÓKÞ…Tã–R`øf^bûjJ9
åpÒ‘µZÛ:¬ìÀW)·i!SS7wÖË›2õ¦ó Pò
Û Aá‰1ƒÒÝF,jÌD™­X¨ýêÖîfy¿Zã°KÞ(ósìîíTÖ÷åVôè2WÂÊN“Ñ ‰ƒuOò…L!“Ï,er!À‡[O 3­ñ^•ªŽ7•RŒ?Òcd†©d!V®$Sä= È#qÿZÂÙ™L”R9„sZü.¦µZé×ZZ2“:	<¢iRNŽ«ä£¥EÄÁÒ†•d[­!“á`‘› ©áHà‚‚¿1j9%aé°A(P9(¯E; ,AÄ´“ùñUø£M-oÒwúj,`0‚…‰Àóµ,±2CÁÕ#ilÕ¸ÓC^ì?2ìZ5¹‡qÁ-ùÔï›<©3	}×p¯è@š„Íçg§ÿ€aöì>Ô®ðA,U¡–ÅêP¼AÞ@¬0Í@lááÈÃ,WE¯2Z†^}6}›VCÌí6š¿F‡ÏÕüYŠ¿Bc,b—J­|Rn®ÊýÅ“Ëªð\©àOÊË¢Hïû9ûB;ÖX×"çðÏ“©E‰È\¹º¾¿³÷ù!3¡£fK¼wP˜ò€V'¶DèÇ"AŽÛBØuOÉý@DìÞþþçèˆ·žÐ—èý4(½AMçMï"ªþRoôi5²œUz©WÁs+þ•ž\½áVÉÌtŠŸ#ìãbò_¹Í²R§(ûÿg1 XýlÝíÛ&Éãw{
w½|káÕÔ{·ÕˆŸÙ(x¤Z5¼Þ«#?su»‹EÍ?AìœŠ%·¯:Ù-ïŒæzG†í¸mYõÄ€¥ÉÖ»áŠ8Õœ´ÎHº£ly%^]~\­"r cü8“lÀ¼°˜>Tøì‘ãâ(T`Ÿdñö‘²AVÕSè´B£af™HŸFäõÉDZDRQÆä#J7Bø>“qKÏsKH^?FW&je=g]† ð«"Ì¹J Ë½±Ë‹§ldª&g$$zœ‘‘zV±D2ä÷¬Í$$ãÌ÷ôË­™øªÎm[èj#0âwjC|JƒóFd2¿î¨9½Á3bB…Rù‘÷ÝÕê^o¿¾/äŒ+¬©†Ñ„º]eÄh‰r‡ªçÆ¾ioÇ±`qÁë·Ö‘‹f¯/¸%¬¼X”ŽKt`uŽH¨Â{0ú¶Ï
˜i¶\GdG’Ñ´ÀÜGDž˜[Œõxpb*¬Î’Í›mé¥
r‹ó€Aüùá/ißÎK¥†ºþ–XF†£Í„°BéÝž{êA*d|–3X	.
U;nÅÌÜ{¥rý€„²À§w4óTÅ!Xíèhc5¾OEñ<Žé2¶÷õa&÷A —µÁ—(ƒ+P¹„ÃvœL¼~†¾c2#~‰vB”"¸šdÂI0ò6<Å³¢WŠ’H›ZÑó–xy,C}÷?twnš‹£·óÓÚEélÜ4FéëÊ.MÈ²£æ¸êHB?£äXqô7MÑ©<ŠÛÒžß,c%£©[¡¿6
àZ‡Uð<håÐ ìb.ójLéd51‚ÛXT˜ë/TÉÃïb×ù¨æGTf@ó¨Ø†÷Â9ÛQwÏiÔª,cÌÓþ¹‚;•oª&Ï Ú	¸}‡¼
žôRwrMî{F¶¼FÊ9ã‚„ìŒ¹b×ª{ÎèvyTˆãÃ0îàµÊ¹Ø[#³ò­‘Yx£ÚW³tž›$±ùñv‰:õä;&QÙ¨GÕl¿7û3e¿ÑèžÒj+$Á g*x”e›þAÝ\GioìŠž³^HBNÈ´YüùÏU3Wñ\œ”²£‰ži‚ö¯´‡¼3äTÚM˜)ÜÏ#g‡•½£Ë Ò˜´]SPX¶Öèè‡TGˆA0-®‡Ž2ÎN'C0¤l‘½éÅDŸ·¢{³2CÍô1V}nÆïüùPn6æ$„c‡5žb RÁ¾¢y@¹5ÆxVt|³RÞ%»ÈI‰Tú@­©°ô°VÛ—éíˆHpª6eØ“®Dðl"Ã^u7>Ž1¾
2
Cî÷ÂÌXæÃœaóã}Y`¹
vÌ:y0»‡¤'M~‚]]óé éK])"¥R$~ú•Rª {ó1¾õ´Ú¦tÿ9‚ãSUü¾W´ š‡×md.é¼/by^AwqDNŽ‹#[ò‘Q.Šr%åùNf¾v@…€¥3’ö‹èÙ†é‘Ù{é¢Cî¥óü»B¿.ã_å÷°ŒÀõCœm–[¾°ó°~J² „½|Æ?±·½ï”"Ð¶&z§4cHÛŸÎSWÈüÂ ¬ÎÐâ»!y´ž~28Ã»œaö€<|ÁÚ·¯w:bº}	ÕóÕmZ?(³œ]HÚã—ì/%ë]NÒ»œw)/â`ÌÌjòÚ£†,…–8Ðñ•Ó³Øù‡$
øâ‘Þ‰žŠt¥ÿ’"“zíÐ”ôÅ^Yº‹v4G%C¹éŽŠ.î.$QÅ^›S,<ƒ;5óQJT’frÝ;Ý< ²ÛÑQ%›_•·sJUR¦ØËk1î¯¾rB¦*Y Ù!%˜È3SµâAá8^0æ¸RaÏß8q™¬õvLYa©wŽjp—k“†%rDÃ›Æ¨#&EÐC¥cÚ$³Yº‰¡ûz9€¹W´L“²ÿìbö—3ÙÞ¬¨'5tã¨•F…­nÒðW\HB}¢"Æ‰’CeòB°¼éëq–ÆG¥ÄÚ	­P#å}Ù8{õœIVƒŒÌ‘N­¾ÍæZ´cZð$œ¡ô‹o7ŽÆNØÐœÞn§VB±2rˆTDAš^†$	Î<‡˜üÒ{ïGÃ0‚ðÄ\„]YZ‰¥#ùJ|Ø÷ÞWð^œó^Ž'¥¢xyPÃ2@½"å
ê.BŠ‹ ¬¬¼ˆÔ\HðAíEŒêBÊT_Dê.Æß‹×±ºõ{x›óïÃC+{Mç#Ißüæ¯Æ\§Ò¹Fœ¾‡EÃØ6ß8'¡­Ã<u#™WOôåDY«ARÙ@ÆlãÙ³À£5J?k®I¸æÑÖÚŒÚ-)¹m£J£Z³Ú¹VÔÉ¹šoL5¾?®Îaï”Ð¯Pe×Ö;J;å…‚‹qÙYÓ˜/	>°&¹¶TR(7|´ÕíÇ—»‹å£!ñ ¶¿³…öÈh”Æ†¬¤>OÃþ÷ÌÏ¤‚ŸI}ÈäÙ I©$]œZDE€ãó ¸¢R’À•çcÈãÛˆªÕòžà…]]°ây \¾#ƒKÏ£sÃó`ñ<=ÙfÃù”¦”Ô½[°$‰Å(9¤ç²ˆF³D6*¸¿‰ÊQEdmAYâZÈP`7ÊžGe ¶…ŸGï‡ç
¸ÌD¬¢rÇ AúBüÀ¯pÒ~—NãÁ(gT´F‹dïÄiók®]ÒW°m©:…Y{Ç&AU©š—2j¢æ•ïˆÒ÷RÑm?{«çwß#Ø0qB*oK…KmYm%›||9$3÷ªŒ^xÖˆËÔ(Kr@%írã‡™Çeº#‡};šçÐó˜i|·ÁNª¨ÍõîÇ÷C*©F'¾4E3ÌFayþœ$¯òæFÙs˜Lá©aÔ‚Û9s™…ùÒÜl
þ{šÏ,Pë"âï)Ñ½m‹cnqÌ¼žcXæÍüLöY!;åÿÛ'TÜú»'~ª#~/ÏñsŒT„¶xæmTðSÊC¦DrÀã¦ÑHÊ‰Å•Šÿâ¬%|bñ	¼!šmÃÜÒ;Ô÷âUœ[²K‰Ñ2$Ÿú€Åù@ˆ ðä
o@3ƒX½ À¦ïØ¿NÂKži(à[á
ú¯…{‡BQ·¯ÙP#éq!éïðV¸œ)v—¯¨`”,xN+úBK:¼‹¢ÛÞOïÊŒD×JuÕ­BLcªÒºÕíZæ.0³ÒŒÚäi*å›Ö	…ÛÓXK©”ô\b˜O£Ú5=ãcçmŒjûóç#oÓ"]Ím´IW×Lä¬š2›Ýj7(R<°sÅ!EÂÑ²0’2“úU!s¶NcƒJ™%–çw‚äM@ª½d¸4M×o(Í²›¬f':üo2W¯‹lEZ²Ì¥a¶”M8,t_’Ö¥´ù¡-¸ènÙ)´…õ²YH3Â.øåJm¢ã‘M…ËŸfÊ=à:ô6	Ž¶mA'ÏÁ¸xÝç¶ýîõà•Èz=ÉÑ¨Ý‚n¢na Cw™]&;ðe‘çAß¶è¦_›–™–@(ÄCË>Ñì&³Á”'ê‡Up\Or;Šý•@Þ6Ÿ-||Li|hTöL*6Üq~Å‘¨} &ÔÌº¶Fœº©¡æÂZ'\Î+	ÉZ^]Hù!èâJ‚ÍŒ/Ö†EŒxohEÜId+Ò¯ûºƒ.žË`ý%â¿×#îŽŒ]ÑÅŒ°MýD‘´ãb8ì0Â‡µý½Q,Z”:Û–y]èŽÀ+¹3É&²ø’!Ú²gH¦¥@&qz5$[À‰ŸÌÉT`-4$ëØ­‚¢ÚÅå÷[œƒ’8,âheG½Â!¯…ó
EU,¿à
c/× Ta¹/UÓ«"·,¤“ÔŒz6m®šâÃ‘;	Š?uŠ;
>WÇNbÏÒmêÁÃ”T¿O+WóÂº#EÜíºq¢ñpÈ‚'ú›òjíñ²È17e…Î2|‘FÖ„4ôÌZnM²–[S¬åÖ|Í~ÎoôAÎÙrtW•‡%;¨µõc	ÚßZ
ZF·ÖÜi1Š+ ÛSœðË
¢%¯ÅqnÂAÔ™ L
(÷‰ç¨\¥¯Ô ‚
R$ÞÕñ.°ò¦œ{Uön_a¾9SéÆgÂ™óéØè7$0Ÿ÷ªå}/†(ß¤ùý@Ïâ”…6ðù³¸î¦HÆ5R"p¼Ä…‹õ.øÇ¡
:T!S–5àbyÑ‡Ú…2¢‹¶PFq¿qä>_VÏèB¨}GîbFqcÕ<¥hø‰áÕTÊéæ{~ì4d½‡=¸d]»ý&úÞÎ…zf”«=äÂ=s³ã>ÌÃ¶lD¤ªKÜU¢Ç˜äyBBžg†:âðœ®ÅZ<ÖsMmÓšìò‡¿žrW·¶uÅ_e+µjÓÜtïDò2({,¡Îa¸5)Æòv’!h¥áÊÎ¥‚¾%LÊp´2r]‚nf.S› ®a•
‚{n¢PÛ†žžY%·täû‚¡þ_â{“{ˆŽö³‹rÆcÝ°éÒ0œtá;Úñ¯jl~æYl@}âV#«¥žÁ	¿eñCnq?¶£l,¸X¿ÊÓêþÈÕˆ:W&2S€m÷4Ç9Á³JC‚`ü}´GxªŽ3JÜ
î1{'ÍŒûÒfJO*,èß¹Ñ…ÜH¨üö`l-çšèûïL%¦µÔyA¤£JÔµP„@e*Ä„cƒ`Qd¾¹„ìa,R@ò¦cLR|jZìU—1,þÆËàñ?
«¹e’Ëç‹Åå)R¼êŠaúšÇÿÀñ‡í`e«šé6¯¨ò²¼7þK««~ü'>þK¹bnÿå:Ò4U*Ñ Ü^\ªI¢Í¸ópUóøïü™¿J¥8XFššÝ4¾]Œnzî§V\Þ™=õPë/KÌq?ß»¢¯lê ‹
~=ÿö»„K0‹ÓÐzº“!åÆýhµ•ûÍ<œ–¡VPë õÙ©þ›‡…ìl(ö{Î"7"DGèÞÐ5ºPÇpû´"ðþ„¾?µú°wDHÄéâ¡7mq ›4Ÿ²ò²À<’†,—šÒvAkÔÚbÄc+BOì;úKŠ¾n£S(±cQ§h¦Ëö‘«³­+ÝXÝ¨ô3µ¡(×¶	ì‚)Ð£>ÅÝµl!¹Ÿ´µ~1ð¢©ÛZ‡ŠÅ¨m†í•¯46ººÔˆL2¹ ˆf³C˜?YfêŽÃ´°àÅ¸YXàÝ²ÈÜH2kŸ_µc‘G(zßlP+(¾€ÎjË®[×î7°h¯°¡ÓÐ¿è¢×û44ID)iÆèÍF2>AãxÔ§‘áƒT„£àù6{XÎ
|b®«›˜C&1cT¦™G@6*›†ÙIoý?ú VXÇ
ª‚•r5ÃÔ™ÞwOszuÝ††íÊÆ>54“|¢;Îi¶æÚ k¶iùN›î\¨GN»oÒá1O™^V9N4HÑÓxøÔï†ËóPŒN½öË{L´Fe´Ãâúð[Ï~×‘~¾p(.DÃ°fÈœ ÐQoiA>vfè	Ýs½EËaãýÕ¯~EP1]þG€ní7YòeÒFÓÑŸ“l?—Ï:m˜«Íl¸0’n'1PM:ŸOç—óËk…÷ÖŠïQç{ûU	÷­Ö‰È:÷˜3’\&?Ïª‡‡éäîÁ¡UcvºämPæGké‹Qyšn?‡¿uò¡d8ÿ9ˆ@ÃË¡¨úï#¶®÷Žzx÷ž? t£'yÜ½ÿ|`ACj‘öM—C‰¶™Ì¹é©‹Æ[úü0tÇñèt“Ò.0¢ºS·k5õaØ}*c“//xöO²…Ke:šÝêÓùÄBU(jX’T6ŒëÀ|cƒ eûªý!m±ÄÈBˆLjÈœ¸êy)ŸÏ+¢ÉŠ@§’QEÐ@RÑEø9ÏûËo4:¶[×/Ó‡¾CÂ˜HV(X0•º+>ÁÕƒ÷¢©1måsagXG”YGøç”~w<P½Š‹]ìœFítì/ï{>5¬Äˆy9¤D±È‰*“½^¨A­\lL¡þmŒˆb½—CgywÒZ¾ØG]¶k4›G}hÙWÑÓç ›V‹®“k$ëv{¡5®cµp‘L&7ä¥Y©QÑŒŒ£ÏAîÚáŽXAì¢D¿ƒ„odþ™|éúÂgLtr±™vÊ¥9©“Ìï&#Cîftî\¹ÈœÇ˜'Q^Ÿc«¬uŸÐzÓ¾<uf7Ëâ™[<:wŠ3|1R¾A)C¢¤	Ýl­AErY>²ì1/XM„€ÁäÇH	ãW‘ dÆ¡GMŠû½t®Î¯æskÅåµ\ñ|òH>“Ëä„D2–ÒÏ!¿Äf®¨r˜[ƒ9hIHE0¢ëyj\êÅM"é˜¢î’R°£+¤œÎ‡"êr$C‘Gc€y£î‡†‹ÏÒ;+¨bŠ,®"ÃòzËx8ïÐ|¡¨¼Lßûà0þzªÖš®‘#ŒŸÇ±•ÜŒBA<NQlÿó(v£ RoÕÆ¢Ê*ìFA¬Üâ¨[À±cÓ0MÙ/š/ò™÷2¹ÃüJa &?Øc˜òâyè@”|]£nÉ`Á’â5ÌÆ#{x
)ÜñQÑx&ç™ã­™g¤ÙkØTŒÊæ(xølŠÎ7Â<ŠÎ8ÚÞQfßZGv*É2ÏåÓàÒyFî„ö-ãhÇƒIÂÏèj³ÜâçyPÏy¦ÀÓá«xÉ¥A;€³qC"'Œñä±Þù9NIñ„TÊOHOxÀjî®+ÙÐm¼„
N'›ÄS„¤r”ÄRú'£Szü-Ÿ‹Ç4œ
ûè dÇ¨g“0+³I/:©ü½=É¿iüŸ`0™¦ü$ƒbã!Ðu&!²Z¶åb í¦Š )9â	û`‘3½ÓLÐ pmÔ‡Xã“ŽƒÎsœ.õOi4ôÀ{Á`m§x€l6à`1[#ÐÒŽC˜ž`†Kýf¤Ä=	é0~—SoŽ>#k"#‹èIÅyê±ËÖ•HM±BR˜À‡“*Pš {YÙüEQP¡d.PÕ‹a“„Ýó!äÎÌ@°ïk¢5©Nžú2SèÛ‹e"B2˜ó¬¾ýÑ¾ê¸±E5Æ`\|Á€Ð9"z!åxHPMD´b‡Iæ´ •R"5aXta…›¦TãÅÐÅ±^~½¶sÏ[Œ2¼‘bs­éÅDóÞÄÛÕ^èÄÁ³ +t	E¯-­¶£ãcªnWÐ5r_Ì´xd™SAÜŽ«÷ˆväêÞ.IP=í ÕñÏ¥Ô9%ñ•	®ò	Âª‡%ß›<49*1tü^×ÑYðÔ«œ1Å¬*²‚â²Ó$IFŒÆÉmþGÉ9¦ œ#Ož9}Ë¢™faë9Ï™%Ã²3Ò™žFÿ“’Êûºl7Ú†«Ó3ÅdòÁ©§×XGZ¨ìÂÓðË~ÁÔÊx·BVP1ÍWŒy'ª}§OD©£~¬ÓqÉZ´lzŠQ<è '›GºépƒITËÀ,ån]h¸;Æ‹È“ÔEúÒ?TU”µtÁÂôðO#ÕâPY‡4ì>^b_d—ôñ\Æ…md§Ã¢†L™—!;^´Pl»btØá2ðˆcã˜ª%•Ÿ§Òp!qd"Ö)n2Oõ°r6ºw”ê"C[ÜEn™çà¨œèP±Fˆ4¼nÄ	;íQyHš}~öÌ4ÅŠ¹„¼††'“L¾¦(H ½&±„Å aKG^Ÿ  Ï¾eŒôü…Ãò#|ñ«Ù±Oo}ÊÎ¸ÍF¦ŽÃšÂ–‚)a]¥Å~ZCìk;	ˆÂ›•Ú ¾í
´Ü¨Ö”O&Q!To+cê;‚bƒ‰ç<bS÷žøx‘É°ïèÛŠZ…0'¾Ù	Ýþð
±Š*"eD¯²¥!8ÂøFsÐuÎð^,T£ËýÁúÇYÍ>Ú|(ÊPas€œ Nðª¼¦Ú› E÷ÛÖÌ–ÞÌM)N}¨ ?ã)!qUCoÀÇ:0ªàú…6æ~Oê„®æ9ØUzgæPcïqµQmžBqÁØ¬Á1dž¯ÆÔ &ŒÈuºÄ°I•V[V=Öñdš®¢”±Öu491ùUPæ¼l®Í°™˜.|ÞPí?ÖžSxWéŠNj(D§ÅtïÄÈÞ
µ-då5j_ÏÌ .^
 ì±<.‚\ƒíuÃõä{àˆj¾f‹BEÒ7b·¢pà•ËäU=ð¸æâp²¢fi"h&>§¬•E:¤<8C¶,1†²KÁ¡I=ª®³ó¶²ÜéaGiàÚ*‹;ó«bôD'Ù¯gQSïpþÏ]¼ ;8…–µXÀèå.rÑ#@ÏÄ ¡hùy‘Ì4šVÝkôÜ"[q‚Œ3Žgñ±YÑQgR™ÕäŸ—)Z><ÏO<eÑçqÍ¤B—Ü¯z¡£¢¸žÉ/®äÀê¡è&Ø©$¨X¥±‹ŠjI–wqÉReR.¢C]«oºLž¡r7z.2}44˜L,
‰¹œã§ž¸4=¡²ð†è\1Ô^ÏÒ<¥¸ŽÚ³ÊÏÀâ=ðaéÌçþüTÆë;±ºÇ'Z‡PŒRZÝ¬÷4”§Æ-0%S'“¨­Ž<e¹ä.•ˆõoµ¤+ƒ_¿@tóökTàPx§§Ô?—Þb¤ I_NÆ¯/gj-^c/.Òn¢Ý)™ƒÄUW¥¸úÒBÅ!3Šô-#€ß¬P|!ªFŠ0jQñ)z<hQ0=†0Ôn.ª}*”“nTžM:+T®¹9Þ¬l<¤Ä†h}iQ›/^=é@d”êÉàò„
ÊÚ>é+T2yŠ<Æ`ì÷Àdûÿ¼Í[}PòÉç!C!³ÄªyDÙî¨Sãåå@žOà=cªÂ„Êã{Šm®Q§5ä%Â¦,\³˜EÙú+KmÀ|`È¸2A$-Zj¹­
Y\Ù@kPÙÙ*olGôñÀÙ†[¬PË/VƒøôZˆÁâçIÈ„w{ƒ¦‚{˜<Š7ÚŒÚþÈ*õLGu¹ öÉFT  ¸EEyU])r‘ âú¡x[É`á‘Ë8+¼3¼pàä’(¾iV2Ý´<ö7(ž¤_×Ch},SGCm'î>êÖ±N÷ÑûVƒñÈùç“Ù¥Ž	Ô†ºá‘QåxÕ
›÷ÐÀ¡*êwÜ:
»ºÚØÌS50fÞ/?`ˆÄßˆ~ÙUî/ËTÙÊWƒÕç…™Ÿ©Ðýa^~„y^¾R‹Vä7‚kÞhÕ<DAóQˆ|Úpt÷óQè‚š¸áHNê£zº¾AÈø(Fõ‡•Ï ƒ#ÅAø¼âÎÓq¦(;å ÞëŸ)M'F\#ôk Ó³¢ž¢m9.*ŠzÀuÄ't†ÖŽn#E+)÷¹ÏU;2ïŸ¯Qg7Ò\ `R…œÖh«ãì]ÓBåÖ;´YÓ5Ç€Í.ÓµÑù§,T”0LvpiòÛTr	žNŠDr¨ø£«ï©žðÅ‰%É[Ðkr5-ª‹haøŽ*ýšˆö§<÷³Ì0cÑ4î+Ý(P¤‘*ŽT)ó[æãŒ!ÂÞ†“ß+´ú®„ý¶Æ!Æw£¡–ÉPªô‹•~áŸixÒ¬µô4>æôüéA¹î&üà·ˆ¾Ó#ˆ¾hâ‚]añzË•±1V,F|‡lùÚ-1¸ÁÜÊócL¤„Çúˆ®Ÿ_Éá7Bµá¦ñØ^<%£‹Ã¡I
Õ€šþH(‰…Š/$ÕuXüSÃŒR¾cÇªjv~nÈ.¨JªuÅ‡•ébQ²‚úz:v–ËW¹Š`á…Èêy.Æ°R¸Å>*­ükœ–wäêõ­ˆx
·tèÉ†ã Ñ>·¢¤B@êýNÜ) †ºôGkÀ½OÂSúI_c%«­%Ð‘OÁg¿>‹'-P A[E¼k1×vÝž³–ÍbE3-
ýÜÍR~bi$Î¾›¦¹œìüZ2¹@žV…©'{ìc‘XzÛîžíq–Îcv§_ïÌµ4}zŽüYÈ4O;nÓhàÁ|&(]¦ðØ‡=j’¾Io«À@•{°Déx‘ˆ…L.C>·úÀRN‰U§ÇþhïT1ÏB4—|ˆÕƒÚœœd4Š0cÙ­,/ÎÉnn¬W·kÕ4 ½²ùÅïÿ£Ýø¼	D§Qýä‹…•B¡@ý¬ä'þ?®#EPŽ»ŒÁþ?rËK+y>þ«¹¥\Æyu¹8ñÿqiú'Ôxð5Gm)¶™æ™;ZÏMIùÑ"y€6¨(äV0L‰Õ£ëÕOI¯Is*µyÈSÓôú*ÀÏpØÂû‹ä=`7äQGsÝºÝoµI®/u]Œ½Ò¨È°´2Ë€÷å¾â_sõ#ÔKÓåˆÌ0:¦Žð,Ã–¨\Þ¸lAîjÓp½Ü3›šã®3»‚§l*hrž‰ ÀdO?6p
ˆL	cDOí¸Å¼OÆ[.H]¼DÉHˆZáÑcKwýÓüh®€¡Îi°‚G0„¸Œ´SÇ;DÐNò±vì§kð3ÿ~&·š)äò+ ws  “Óº×3c¯@ZÜ‚
˜ƒ_Û˜'Ôr%ÔÏRÿ+¾½ˆwMOD…z$¬V€bãÎGÐ„¯®ûÖ©xÈ	"ôAqµÉ¯ÿrï}¾¿>ýé¨Å8EçÙgŠëùŠ™l†•¹/ôø‚ ¸	UÀ>˜I»htìËÄRÉ¨`ø°J®ÖbûôÍÍC_tãåýí€P¨]Ëq‡#™˜ð>¡€á©ÜÞ•îBùY¿¢¡_TÎƒƒWÒ(Î5€„uƒJò©g÷"RõÅìVµØ6îW;6õò§T5EY¿°"_j°|&#aå‡/ÃqòKkÒ¨HG,ç@¨v¢äO@F-ÝÍ¼jÌKñ…ÏÛ$|xºF¯(høÚ±l«œëÊTíúð#õîº=,ãC©°8Ðˆo9NSÄ‹…cš/Í<ÅÍ`§!ÌBßàNðG§Š‡ÌØ¹é‡‘“üþÄ¥šp¤©¡›0X¼‚2†Èÿ¹Â
ßÿàÛ*îÿ–óËKùÿZÒ·¾÷í©w¦¦¶´Ù©‘Ï7ÀgS·á_þýþáïk4”åýý=þsüKðïn $á?ÿHt¨g: u¢½ ^LšÞ­! ö×õ_àgõOþ¯?¾T;')2.ã^ICæÿj±°˜ÿK«“ù=éªöÿW¦xKu qZ€·[ ^©{È¯‹[ôÄ‚ÚÅ™å³Àà~ÇwÒ!¬Ià»@t'¨xÔ³1“Âc<Qä6îðêª•o€A„Å sÒ5nßæçü…áÔ95]í%Çå½Òc¼½4öŠwùµ|iöYÿ£gíµg'Yò4à®þ9™f;Æ£E;î÷ê%éF­ÿ¸£D"¥$£Mhüh%<Ú˜ÛŽ„• :ñÈÐ&Ì‡´ê~•5Ò‚¯¸³ 2«@<ôðXlD½Ç´½˜nÑYdX :j‡°‘x4Z“%MBecÏ^OµpÆµN(Øœ„ úµy‰AÀ)ÃÑB§É:ÝÖâyhOÿ-{%;;ŽŸíD¡ãy£ü¾ô&-7"ºìÔ
LZÆŠ_ž~Yš¥_Ó”EÃšaÎ^äÁËÂv;¨vòBóÑC{5L5ÄÃ€s<ž9Ë>c},0ƒâô  RI®›”˜mÃIr.0ëµ4µý·ú6%s„”ô¯G„!°^
N§0Æ“¡pv…¡0¼ÜlÒ3ÚQ
ÔÚèÄysF‚n†fÒ‡¶¢tÿµVíö ¨	ª I]ç±#¯×Z½Ò¬×Ñ{hµÙS)h¤xo„„x]µ‰×C671ªá:éÀÌƒµù5u“îeJ³ø¢I20YVÇ²KZßµ<€h4uï½Ít\Û{ä°GQØœž1³@’ÐÀÉ$…œãS‹ÇD¼Žq5 }aÙŠ¹ÁÄe†b~vý|Ù©I˜”ÝÖ{çC iùXœóáðmÈŠcÃ*Í¡¸C®V÷ºŠb1²è{DÑ>@ë¯Ò¬b
–N;0B¹þ‚‡”ÏËf“é´kÃÊPî@CÒÀš•m’j˜%ÿ>ÆEk§ø{a0L…iÏàR®‰ÓïÞleà%Ô¡«Ù§¢ZMæ©gJzC}ƒö¨X‹ËÓtš
8ÂC3 "T‚ÆÕ‡€…XK™™_ç7göíÑ2Ëú_ÙèmœeŒ¨ÿ]Ê/-–W0þK±¸´:Ñÿ\KzÃõ¿&×ÿþýß®O_ª“™¢/Ž·Œ!ó¿°ºšÿðm2ÿ¯#Mô¿7«ÿU\ž~%ÕÀ²Õý mpP,_•›¨ƒ/^…·]<’zñæÔg„L³[HoôêÅØ;âr›z¬æ’.ƒ¡…àÿ¾—å«[c†ÉÿË…%ÿ1·’Çµ3—/¬.OäÿkI,þ£äÜYA’<‹¶à_Çµ_øêaof(>\’Ö¼§Ëüi™n¹ÅÓ"º'mÓÅ»1âíþÝÓÞbCèEŒß0ˆ<a×Ûk[ÉéóÎ%’ôƒ¾¬å—Þ{-¿²´²¶ií½÷á'à}{öîãHÑ®ÕÇ[Æ0ù¿X”îÿäòhÿU\ÌÿkI“û7rÿ#Êàm•ücn€Dê“ +0^Iýzäôä˜Eï7Gðf«î<Ò›æóq	Ã§\u¹Ñîÿ‚Ø¿¼šËçéýßâêäþïu$?NÁÕ•1âøãþoþ¢ý/HŒ“ñ¿Žˆús%eœþ/­æ“ñ¿Ž$Å)9ÌTj‡4Ó˜Ë¦ÿÉ¯òù_(®WWèýÿB~²ÿ»–4ÊùïÃ)vþû3ˆ‚gº^’Î_Š\“ôf&iþ_Ñì6ÿË¹ÜrpþqýŸÌÿkI‰ýfæ5|½5Å>ïþCÑ ·ø¿Pz‡þ`ŠÚv kp§ôN+_kXÝÞ¸+<I“4I“4I“4IcI	öqëÎÍVc’&i’ÞÀ„üðÏøç±Ïÿÿü¦”ç.ÿ$üó#þùGì3ÁáÞáŸßäŸ·øç]þIøçGüóØ'gZ	¾ùHð’|‡’à
ŠáŸ«É“4I_«„{÷ß™jLÙSú”Þ¿ÿÎß¾ïZ•J³ï6¦¦þæ_û{£ê„ß7¾ïµeüt¶²÷Ö”9•™jªåûVð½TþÂ?ø³S¡üRù‘ï#ÊÿÔÍjÔOœ^½c¡MäUïuÇÍåþ‡Ä;ßøæ·~çÛ·nÝºsëOÜz^k['5z½ìf?Å_±Î¿ï[VÇû®ÕúÉáÝß_åhf£©È³'†Ù´NX}³é<•^Ü¾}ûÖíÃ»?|õjùýåE²´’;[$¯ò¹Üû‹d¥¸|vvûÖ÷ïåK¿êž~ùêõÙoþk‡`‹S¿ß¿ì·OíÙåJoœãuÖòwþÑòÿQ´üvòÎ?qçÓÍO·¶wïÞí;úžÞ¡ãÐŠÄ9¼û{è}£a™»¶~M~ÒÀHx&¼ùNCë`°W/w:5ãKÝ°­Ng×r4öøü3<ÏÇw¡WŸýÂ±lw"ûÌ üê»XÆuMïp7Û·oÿ¿ûý?œ™KV?,?üíïÝýÎwïüþï=A–zG?81šnûsÍiè4žû/ «MÄ¥Û·¿óÎnïãí¾ß~÷?üÑüøÝwƒÐËgýºñë¾ážÞ¾u‹•ñ“w§oßýã[ÏðêÒ–Õ¤îäé›wòîì­[Oñù:½ßüíwï~ç÷æÞ½³ï@+îj·nÓ'™ì;û/€î:·Ù“¥å;ït´ºÞ¹Û¼}‹>zïý;ï>áæ'w?åK÷ï¼ûwï|'±x›ÕéÝõw«·îþ·~‰e£9ÏNO7¡øýà‡X«[·>Ç7åfSoÞö.WM4Ç¾Ð®˜þˆ+aïâªüîTnêÁÔ'S¿œêMNý¹©vê¯Lýõ©?žúw¦þã©ÿzê¿Ÿú[SwêïMýý©ÿcêÿœú‰Ä·ßIü0‘JÌ$î%~šÈ&r‰Bb)ñQb#ñIâÓÄ“Ä¯z¢•h'Œ„8Iœ&¾L¼Jü™Ä?™ø§>ñÿ\â¯$þåÄ_Mü+‰3ñÇ‰¿‘ø÷ÿ~â?Iü§‰ÿ,ñŸ'þfâNü/‰¿øßÿ{âÿNüƒw¾ñ×X¾#¨W%þw~W¡q>»ßùgbhüã?ùô§o,ÿ­ßÅþ‡ÿùÞ÷É½…ÌÒ{¥†[¡H™)õ1ò¢d'ÈŠM6îüaÜÄ9€úË[Hmw¿ýÛ?øá~ð“Ô|éíýùÓÙß¹›€)q›þüÙ,¼}Þ!â;¹náßý+§xgõøÝo±·kw>¼“àî7ÙÛŸß)ßZ¿û;ÑzåÎ»S8Wo%Ú$û_NýwSÈõÿúÿßJ$ßM|?As‰Lâ½ÄýÄÏë‰jb;±›ØKÔû‰ç‰Ã„–¨'‰NÂLX‰%Ø×‰³ÄŸNü‰?›øs@¶H´ÿ|â/%þrâ_Lü«‰-ñ×ÿ:%ÞH÷?Hü‡‰ÿˆ÷¿Mü6@ª›*©&þ'ŸT¥%îßþÝì{ÿ¨ü¦óF]Öþ¢´¬×l³c™­)&µsª3Õœ2¦ŽÔåà› ¿‹Xd¥w¡Ö{±¸ÞwÖT‹.À.ÂËü7oÅCFÔ%2T³ÈˆzNÒ$MÒ$MÒ$}MÒ7ØAý5þü’&i’¾Â)ñÍJ­ò`Ê;%Ôµø÷+‘ajðAÀ;Ì`hŽ?óLºÞ˜Ã€Éþ²ÿÿšïÿ'éë›|ûß«‹9úýŸâj.Gïÿ‹ÅÉýëHþøÃbdfšWAç¿ÿƒ¡ 'ãI²ÿ—°µŒ!÷ò¹ü*óÿ¶\\)pü‹ËËËûÿëHÓjà=¼õüˆïq²Ñg×‘-Ü8"OÑÑoÁØòü7“·3þÃä‘¨æ½A¢Ëî¸)ö¼Ûï(»ek]'™Ü-ï\šÁ¿k3èÎ(›ñ\}óÔÛ“ˆ pÔõz[o¼ð#ç!êŽ¥Ñ Ù^œBVï”äE<EJ$•òjOˆh 1WJ+C’‰‚€7zÇÑ)€Þh[$UÝÛÛÙCßh"l"­SdNè,Ö_"r†CÎÆÀ÷U<‚#ôâq¬¾Ý`aþ¤NOÍüõò}3IÊý_˜„–‹nBÆ-œý‡U`rÿûZ’,ÿ¡Zàå¿å|ni5·Šþß–ËùÿZRhüÙÇ!u°–éŽ£Œ!òßÒÒ2õÿ—§ÿrÿm57¹ÿ}=i\>s‚Ž¹6Ì#[s\»ßpû¶Îù7IM·æÈõÆ|rÝq(~¼¾¸”ÜA?\°ä­fò…Ln9à~+èf«Æ\Üº–ˆ­C+K*z¼øÚŠt”µ	nzîz+•M’ÏäÈÏÈ£ÝMå³o…®™×ÅÑuÒ2\bóæ‘6ó°Eý6a”b˜ðµËý}™<r°“í÷PY”²¿SÙÉø­SM.ÝDXŽ$xGº&N6i7Ò4• W†ÃfZº;7[ÙÙ*oln—·ª³‹$µÓ=dùRóAOsÛCàæ dû¹|–es²÷œ¹G¤ZÌ'iô
ù†Œ†éÎ±²¸;£‘®Â^;5/2;NGä”¹VÛ”òüü}ÜÛÅ5‡å=¨U÷0ã‰^éÒh¤¼ŠÃŒ÷ò¦x-ËµÚ“½
l`’=+4Ëè›ÎV
»FžÞsžÏ:ãƒ ø®èæ8€î»%%p¿wƒÐÐ<Gšw§ŸáÀïŸHôØ>´ˆD=Ð~t­'›51ÿÙÊØ“9ÖÞM‹»WõºZê‡Å$	%1N~Ÿ°l~Ê…”"¤Ò/ƒ2bOmK“ËïŸa¹ü^+…ú©ú¸ôÒþM/±otŠÞÿÿcCä?XCû¿‰ÿŸkJ“ ×ôá­õõº)„ç´•­.Ô­ësÊ-û.ú€å>V¯;âB>“Ï]kÄÝrY­×Ë²„\ÏŠŽ6Ñù8‹AŠá‡ 2%÷€,Æ|E×K<ü·anÐ]Ã™Ò²^Ð_l KEú@JÅ\îEòl¢øýš¦Ðùïx—~š†é–CëÿòÊÊÄÿûµ¤Éú?YÿGòâ«Îâ;MÖ{©
ãÆw¢ë/:§ä¨ßé&/ #|~Ù}Óó‘Ïb·pàÄï“ø/ÝÇÄ-~ðƒc!Ð8m’vÉÃƒÍM’î"ÐÍº–i´Éýû$ëv{28†â*Üÿi>yÝ×Ôè=ÃlØ:Ò¥vs˜[,,.-./W.ÔÛë{Õ­êö~ùMéUnzq}=Y(Ðž\µÿ¸ØŒýwž»éuø¦’jÿyÒq©î:ã°ƒš±”1Lþ+–¹üW\Î¯Òó?jÿ7‘ÿ®>mÂbø®sž Þ t†¥£“–¤3PBôp’´–‰’ÙUqh.	Hl²D&PäV3Ð=—"Œ$’	˜<=™“¥0ñæ dIñ‚‡MqHèiµ4çêØm¸¢›x¨ÅZh¨$½‰|JTNÄþ×ˆà~4^D“p„¬bŒcCmñDPÅæÇyC’ÐmìÌÑ“Œù)7¿€ÙIèA iÙ¬àhÛ§`izXèéZ]?Â#EÜÀ²äf’Ó
ô‹-DÍYØÐ5å½ÓoZ¤ÑÓ,:Žíõ,o&ÿÌ
¨²Þ¥øYÎˆ¢C%»@W9[ßÔµ†ÔåŽ^J“gVLí1e¬¤«™}­395âµÕ;?f+b$(â1r½À¹4=¥0˜Ÿ¹÷q±Ê·xì*bë…¤"°×€‡
VnRƒOÝ!mëí‚ÇXïäSd Ï“Q1Ô¿„‚”ˆÉ'šé:%SwO,ûEÆ©¥»Éò‘«ÛÁ‡$ù”óåçÉýÓž^r˜àzÏØJLÌJ>Â	X²xx®äÈ“Ì›Å¥ X†ÓÍŠ¿€÷Žw–5äãÉêK½Aiîüy³”ìžèõM<
DËU†Ìê] Wâ³z2:¨—ÙÔìæNßíõÝP%êW¡Ÿ8yN{÷Ü¥n¿ãi,†wçM¯éçIªü'bRcÈ!òßòÒJžÇ\Í-åŠ ÿ­¬./Mä¿ëH“ø7ÿQ™eo­F0&ú#™D¼HÒžxÚ ¦du/Y/\Û˜'äÔêƒ°u
‚—Íèê¾]êr:F¤d(ÆÃÔmEc+µ›Óö.²Ôuÿ^äugˆØõó&Œ$<¿B$ÊRärŠÎ»rBôVF]½†”aeî·u• ˜´ƒ™Z?äïÈ‰4º´cÍèÐ¥’;ØVÉÕZ„†LßÜ<\?¨íïlmü¢¼¿±³{µk9ôÊ»ÔS¸—Qú„îì•×7«ìÒß03B,‡o}°žþ&eQL{) ©0œâ“¿Ãñqâ}žA¥
yÈ*åýr"òwNØº¦æj‹ž"oQ=âw<l^°yZG©j"g|ýDe²Š¶7xýÓƒ]Ñn	+×ÛÇÉ åQAKÊpC¨vb¶k4›ýD³uõÃ­'ý…Pc^Šï“òã²\Qß@Ì°è²¢7wèBë€ oRÏdÓØ29AùF_u} >”9C-d`3R±(`V¼°c=†|½N™¶Kå-ŽNïfÆÎM?Œœä÷¿¶ŠÞ˜¤Êÿœ¡flgœA›†ÈÿxÝ_è…\ŽÚÿ-Mâ]KzZÝ~´±]}žÜÓpzïrO3¥|&ÇþK>}TÝ®îm¬?OÖªë{ûŸìï­Öo”·>gÌ­v°‹æâ¥#­ãŒ?’Ü$;EíÿÇ¸õ§iÈü_-VÙþ¿PXÉÑóŸâêòÄþ÷ZÒUíÿ'¦@ÕŽÐ¼Ý
€uÅ˜® 
/ÔkžYD^«Âm‡¢þ‡D7NO…íDjø.¾¡ú¶sŠúõ&ÝÅÈÁH¶ñxÿq%*óøFÌ‘®W€g(…×`.™f‘Ç^¯_¤MµSÓÕ^²x\Þ+=Ö:}}ì^=jùÒì³þGÏÚkÏN²ä)sY!6žgÏÉ¬€l4Û%xëoªÎü7ZIÍwH/™I õ’äÃÜá7wÖË›g£”dÔƒEP  sø&K‚mGÂJ xd°·s|H«îW9P#-ø*K/O	 à½Ø!zù =<Qï1íÄíøjÕ}Ì±¾³ýpÔa#ñh´&Kš„ÊÆž7¼žjáŒk	œl€¤dÕÏP|CÀ Ã`.¬Óm-swó%uwãÍ9ŸíD¡ãy£ü¾ô&m™;Ý¹ìdR'-cÅ/O¿,ÍÒ¯iÊ¢aÍ0g¯€òŠ°‚±r)gÖmªvÚŸ$>5PóçwæáæFmÿ,IHÓJ2•fŸ1Fp{P©dÓ2uî,9Àl£I"¹À¬Ô@ÒÔößvèÛ”ÌRÒÛÔ õR p:…¡à©…³+OÊ3ÚQ
ÔÚèÄysF‚n†fÒ‡¶¢tÿµVíö ¨	ª I]ç±#¯×Z½ÒlKwé½T¯A-«Íž2ê!*ÐÄ;xƒ¦m½Ó «6×%mnÂN¶´N:0ó`m~Mo¦{@™Ò,¾h’ÌL–†Õ±ì’Öw- MÝ{o3×ö9ìQ6§ÃÁgÌ,@e\Íè´I
9Æ§‰xãj@û,Ïf+æCVk 6ßÏ®Ÿ/»nÛ–-e·õÞù@†ŽÁî*ûXœóáp¨t
Ç†Uš=6âA†áju¯«àg¿ÇÈ¢ïE?ø *ó¢4Û¥öIiü×¶—º ÜÁCÊçgèBi¹6¬å4$œ¡YÙ&©†Yò­Ÿ¸ÙSŠ¿Wš©0=³û¤røpc³*×Äéwo¶2ðêÐÕìSQ­¦óþ0•ñõMÓ±¬…DM„ÝƒìTÀ9Ø¨°kââŠPPI¶wÒ<,÷¥+7ffN|ÜœÙ·GËÐÿØn½ÐëÞË¦ÿ…§¾þwiõ?+«ûkI†yûC˜k‡0æ!Û)J ‰’ÛaK±»éÚOÒeS´ýÝËŒM<ÌÿÃêjŽù]Z*,¯àü_]ZÊMæÿu¤‰þ÷fõ¿ò\ûjªY‡jƒƒª`TLÔÁ—¯ÂÛ®I½xsê3B¦	†t¡ô†š2öŽ¸Ü¦ë‡¹ØOj)$;x­ÿ°;÷3Lþ_.,ñø+y Eÿ«Å‰ü-iš2XÆÀ)çfV$OÖÖK×.|Qà/6+å]ê
.IkÞÓeþÔw´‡O‹üéž´MïVà¿ûwO{:Ñ[½Hv6ðO¥V­æz ¶•œ>ï\"ITì4­ÆÝ^Ë/½÷þZ~eiemÒÚ{ïÃOÀûöìÝÇ‘Bó?sX©>,lî^›ü_,rÿÏÅÂ
,xÿ£¸ZœÌÿëH“û7rÿ#0ËÞZÉ?æH´ >¹2°ã•Ô¯GNOŽYô~soÖ°êÎÃñ ½i>—Bëÿ¡8 Ÿ!ëÿR±¸êùÿ(.£ü¿º²4±ÿ¼–4ñÿ!ûÿˆ¢ÿäÄˆŸ®Êˆ×éN?=|ôVÁp5î?¢Èàj=€D^ ³Æâd„’.ád$ìt‹{Œ<á+ãDÖÝ\­#IZ-íìV·+µCï^c)Eg^eÌ~Ñ|‘Ï¼—Éæ——³)ÕùGÞ¿JeFÓÑ…r—¹úH7Q²üuß€JÊ®>†ä´zÁŒ{:Æá;GV[g¤-D{y[]ƒHþÿ›Æí‡žqˆ¤Ác)c˜þ'·´ðÿ»š+&òßu¤É!m°ÚAU2ÞZEM…+i$¯kžhN…7“ 'pO¥P‹óuñè›lB6%è>·…t¸?,»•l6Öˆ÷0iÕÑ§T£?€Rì–f
ïÊXIÆ†Y¢k§³…»ìu8{ ¤FgÝ2]õuÛÃ¼«[°PÇbf¯Ï…ù¦YÓ$MÒ$MÒ$MÒ$MÒ$MÒ$9ýÿÀ¨{ë 0 