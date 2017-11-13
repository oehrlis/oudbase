#!/bin/bash
# -----------------------------------------------------------------------------
# $Id: $
# -----------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------------
# Name.......: oudbase_install.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: This script is used as base install script for the OUD Environment
# Notes......: --
# Reference..: --
# -----------------------------------------------------------------------------
# Rev History:
# 11.10.2016   soe  Initial version
# -----------------------------------------------------------------------------

# - Customization -------------------------------------------------------------
export LOG_BASE=${LOG_BASE-"/tmp"}
# - End of Customization ------------------------------------------------------

# - Default Values ------------------------------------------------------------
VERSION=0.1
DOAPPEND="TRUE"                                        # enable log file append
VERBOSE="TRUE"                                         # enable verbose mode
SCRIPT_NAME=$(basename $0)                             # Basename of the script
SCRIPT_FQN="$(pwd)/$0"                                 # Full qualified script name
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
ERROR=0
# - End of Default Values -----------------------------------------------------

# - Functions -----------------------------------------------------------------
# -----------------------------------------------------------------------------
function Usage()
# Purpose....: Display Usage
# -----------------------------------------------------------------------------
{
  VERBOSE="TRUE"
  DoMsg "INFO : Usage, ${SCRIPT_NAME} [-hv] [-b <ORACLE_BASE>] "
  DoMsg "INFO :   [-i <ORACLE_INSTANCE_BASE>] [-m <ORACLE_HOME_BASE>] [-B <OUD_BACKUP_BASE>]"
  DoMsg "INFO : "
  DoMsg "INFO :   -h                          Usage (this message)"
  DoMsg "INFO :   -v                          enable verbose mode"
  DoMsg "INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument."
  DoMsg "INFO :   -i <ORACLE_INSTANCE_BASE>   Base directory for OUD instances (default \$ORACLE_BASE/instances)"
  DoMsg "INFO :   -m <ORACLE_HOME_BASE>       Base directory for OUD binaries (default \$ORACLE_BASE/middleware)"
  DoMsg "INFO :   -B <OUD_BACKUP_BASE>        Base directory for OUD backups (default \$ORACLE_BASE/backup)"
  DoMsg "INFO : "
  DoMsg "INFO : Logfile : ${LOGFILE}"

  if [ ${1} -gt 0 ]
    then
      CleanAndQuit ${1} ${2}
    else
      VERBOSE="FALSE"
      CleanAndQuit 0
  fi
}

# -----------------------------------------------------------------------------
function DoMsg()
# Purpose....: Display Message with time stamp
# -----------------------------------------------------------------------------
{
  INPUT=${1%:*}                         # Take everything behinde
    case ${INPUT} in                    # Define a nice time stamp for ERR, END
      "END ")  TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S");;
      "ERR ")  TIME_STAMP=$(date "+%n%Y-%m-%d_%H:%M:%S");;
      "START") TIME_STAMP=$(date "+%Y-%m-%d_%H:%M:%S");;
      "OK")    TIME_STAMP="";;
      "*")     TIME_STAMP="....................";;
    esac
    if [ "${VERBOSE}" = "TRUE" ]
      then
        if [ "${DOAPPEND}" = "TRUE" ]
          then
            echo "${TIME_STAMP}  ${1}" |tee -a ${LOGFILE}
          else
            echo "${TIME_STAMP}  ${1}"
        fi
        shift
        while [ "${1}" != "" ]
          do
            if [ "${DOAPPEND}" = "TRUE" ]
              then
                echo "               ${1}" |tee -a ${LOGFILE}
              else
                echo "               ${1}"
            fi
            shift
        done
      else
        if [ "${DOAPPEND}" = "TRUE" ]
          then
            echo "${TIME_STAMP}  ${1}" >> ${LOGFILE}
        fi
        shift
        while [ "${1}" != "" ]
          do
            if [ "${DOAPPEND}" = "TRUE" ]
              then
                echo "               ${1}" >> ${LOGFILE}
            fi
            shift
        done
    fi
}

# -----------------------------------------------------------------------------
function CleanAndQuit()
# Purpose....: Clean up before exit
# -----------------------------------------------------------------------------
{
  if [ ${1} -gt 0 ]
    then
      VERBOSE="TRUE"
  fi
  case ${1} in
    0)  DoMsg "END  : of ${SCRIPT_NAME}";;
    1)  DoMsg "ERR  : Exit Code ${1}. Wrong amount of arguments. See usage for correct one.";;
    2)  DoMsg "ERR  : Exit Code ${1}. Wrong arguments (${2}). See usage for correct one.";;
    3)  DoMsg "ERR  : Exit Code ${1}. Missing mandatory argument ${2}. See usage for correct one.";;
    10) DoMsg "ERR  : Exit Code ${1}. OUD_BASE not set or $OUD_BASE not available.";;
    40) DoMsg "ERR  : Exit Code ${1}. This is not an Install package. Missing TAR section.";;
    41) DoMsg "ERR  : Exit Code ${1}. Error creating directory ${2}.";;
    42) DoMsg "ERR  : Exit Code ${1}. ORACEL_BASE directory not available";;
    11) DoMsg "ERR  : Exit Code ${1}. Could not touch file ${2}";;
    99) DoMsg "INFO : Just wanna say hallo.";;
    ?)  DoMsg "ERR  : Exit Code ${1}. Unknown Error.";;
  esac
  exit ${1}
}
# - EOF Functions -------------------------------------------------------------

# - Initialization ------------------------------------------------------------
tty >/dev/null 2>&1
pTTY=$?

# Define Logfile
LOGFILE="${LOG_BASE}/$(basename ${SCRIPT_NAME} .sh).log"
touch ${LOGFILE} 2>/dev/null
if [ $? -eq 0 ] && [ -w "${LOGFILE}" ]
  then
    DOAPPEND="TRUE"
  else
    CleanAndQuit 11 ${LOGFILE} # Define a clean exit
fi

# searches for the line number where finish the script and start the tar.gz
SKIP=`awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`

# count the lines of our file name
LINES=$(wc -l <$SCRIPT_FQN)

# - Main ----------------------------------------------------------------------
DoMsg "${START_HEADER}"
if [ $# -lt 1 ]
  then
    Usage 1
fi

# Exit if there are less lines than the skip line marker (__TARFILE_FOLLOWS__)
if [ $LINES -lt $SKIP ]
  then
    CleanAndQuit 40
fi

# usage and getopts
DoMsg "INFO : processing commandline parameter"
while getopts hvb:i:m:B:E: arg
  do
    case $arg in
      h) Usage 0;;
      v) VERBOSE="TRUE";;
      b) INSTALL_ORACLE_BASE="${OPTARG}";;
      i) INSTALL_ORACLE_INSTANCE_BASE="${OPTARG}";;
      m) INSTALL_ORACLE_HOME_BASE="${OPTARG}";;
      B) INSTALL_OUD_BACKUP_BASE="${OPTARG}";;
      E) CleanAndQuit "${OPTARG}";;
      ?) Usage 2 $*;;
    esac
done

# Check if INSTALL_ORACLE_BASE is defined
if [ "${INSTALL_ORACLE_BASE}" = "" ]
  then
    Usage 3 "-b"
fi

# Check if INSTALL_ORACLE_BASE exits
if [ ! -d "${INSTALL_ORACLE_BASE}" ]
  then
    CleanAndQuit 42 ${INSTALL_ORACLE_BASE}
fi

# define the real directories names

# set the real directories based on the cli or defaul values
export ORACLE_BASE=${INSTALL_ORACLE_BASE}
export ORACLE_INSTANCE_BASE=${INSTALL_ORACLE_INSTANCE_BASE-"${ORACLE_BASE}/instances"}
export ORACLE_HOME_BASE=${INSTALL_ORACLE_HOME_BASE-"${ORACLE_BASE}/middleware"}
export OUD_BACKUP_BASE=${INSTALL_OUD_BACKUP_BASE-"${ORACLE_BASE}/backup"}

# just do Installation if there are more lines after __TARFILE_FOLLOWS__ 
DoMsg "Installing OUD Environment"
DoMsg "Create required directories in ORACLE_BASE=${ORACLE_BASE}"

for i in ${ORACLE_BASE}/etc ${ORACLE_BASE}/local ${OUD_BACKUP_BASE} ${ORACLE_HOME_BASE} ${ORACLE_INSTANCE_BASE} 
  do
    mkdir -pv ${i} >/dev/null 2>&1 && DoMsg "Create Directory ${i}" || CleanAndQuit 41 ${i}
done

DoMsg "Extracting file into ${ORACLE_BASE}/local"
# take the tarfile and pipe it into tar
tail -n +$SKIP $SCRIPT_FQN | tar -xzv --exclude="._*"  -C ${ORACLE_BASE}/local
# Any script here will happen after the tar file extract.
echo "# OUD Base Directory" >$HOME/.OUD_BASE
echo "# from here the directories local," >>$HOME/.OUD_BASE
echo "# instance and others are derived" >>$HOME/.OUD_BASE
echo "OUD_BASE=${ORACLE_BASE}/local" >>$HOME/.OUD_BASE
DoMsg "Please manual adjust your .profile to load / source your OUD Environment"
CleanAndQuit 0

# NOTE: Don't place any newline characters after the last line below.
__TARFILE_FOLLOWS__