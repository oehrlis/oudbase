#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: oud_status.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.18
# Revision...: --
# Purpose....: Bash Script to get the instance status as retun code
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------
# - Customization -------------------------------------------------------
export OUD_ROOT_DN=${OUD_ROOT_DN:-"postgasse.org"}
export OPENDS_JAVA_ARGS=-Dcom.sun.jndi.ldap.object.disableEndpointIdentification=true
export OUD_CON_HANDLER=${OUD_CON_HANDLER:-"LDAP LDAPS"}
# - End of Customization ------------------------------------------------

# - Default Values ------------------------------------------------------
VERSION=v1.9.5
DOAPPEND="TRUE"                                 # enable log file append
VERBOSE="FALSE"                                 # enable verbose mode
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)"
TMP_FILE=$(mktemp)                              # create a temp file
START_HEADER="START: Start of ${SCRIPT_NAME} (Version ${VERSION}) with $*"
MAILADDRESS=oud@oradba.ch
ERROR=0
HOST=$(hostname 2>/dev/null ||cat /etc/hostname ||echo $HOSTNAME)    # Hostname
# - End of Default Values -----------------------------------------------

# - Functions -----------------------------------------------------------
# source common functions from oud_functions.sh
. ${SCRIPT_DIR}/oud_functions.sh
# -----------------------------------------------------------------------
function Usage() {
# Purpose....: Display Usage
# -----------------------------------------------------------------------
    VERBOSE="TRUE"
    DoMsg "Usage, ${SCRIPT_NAME} [-hvr] [-i <OUD_INSTANCE>][-D <bindDN>]"
    DoMsg "              [-j <bindPasswordFile>] [-c <CONNECTION HANDLER>]"
    DoMsg "    -h                       Usage this message"
    DoMsg "    -v                       enable verbose mode"
    DoMsg "    -l                       enable instance log file in \$OUD_ADMIN_BASE/\$OUD_INSTANCE/"
    DoMsg "    -r                       check for replication"
    DoMsg "    -D <bindDN>              Default value: cn=Directory Manager"
    DoMsg "    -j <bindPasswordFile>    Bind password file"
    DoMsg "    -c <CONNECTION HANDLER>  List of connection handler to check (default LDAP,LDAPS)"
    DoMsg "                             Can be controlled with the environment variable \$OUD_CON_HANDLER"
    DoMsg "    -i <OUD_INSTANCE>        OUD Instance"
    DoMsg "    Logfile : ${LOGFILE}"
    if [ ${1} -gt 0 ]; then
        CleanAndQuit ${1} ${2}
    else
        VERBOSE="FALSE"
        CleanAndQuit 0 
    fi
}
# - EOF Functions -------------------------------------------------------

# - Initialization ------------------------------------------------------
# Check OUD_BASE and load if necessary
if [ "${OUD_BASE}" = "" ]; then
    if [ -f "${HOME}/.OUD_BASE" ]; then
        . "${HOME}/.OUD_BASE"
    else
        CleanAndQuit 21 
    fi
fi  

# Check if OUD_BASE exits
if [ "${OUD_BASE}" = "" ] || [ ! -d "${OUD_BASE}" ]; then
    CleanAndQuit 10
fi

# Load OUD environment
. ${OUD_BASE}/bin/oudenv.sh ${OUD_INSTANCE} SILENT >/dev/null 2>&1

# Define Logfile
LOGFILE="${LOG_BASE}/$(basename ${SCRIPT_NAME} .sh).log"
touch ${LOGFILE} 2>/dev/null
if [ $? -eq 0 ] && [ -w "${LOGFILE}" ]; then
    DOAPPEND="TRUE"
else
    CleanAndQuit 11 ${LOGFILE} # Define a clean exit
fi

# default output for scripts
OUTPUT="${LOGFILE}"
# - EOF Initialization --------------------------------------------------

# - Main ----------------------------------------------------------------
#trap "CleanAndQuit 40" ERR

if [ $# -lt 1 ]; then
    DoMsg "INFO : Use current OUD instance"
fi

# usage and getopts
while getopts hvli:D:j:c:E:r arg; do
    case $arg in
        h) Usage 0;;
        v) VERBOSE="TRUE";;
        l) INSTANCE_LOG="TRUE";;
        i) MyOUD_INSTANCE="${OPTARG}";;
        D) MybindDN="${OPTARG}";;
        j) MybindPasswordFile="${OPTARG}";;
        c) MY_OUD_CON_HANDLER=$(echo "${OPTARG}"|sed s/\,/\ /g);;
        r) REPLICATION="TRUE";;
        E) CleanAndQuit "${OPTARG}";;
        ?) Usage 2 $*;;
    esac
done

# set the connection handler
OUD_CON_HANDLER=${MY_OUD_CON_HANDLER:-$OUD_CON_HANDLER}
# fallback to current instance if ${MyOUD_INSTANCE} is undefined
if [ "${MyOUD_INSTANCE}" == "" ]; then
    DoMsg "INFO : Use current OUD instance"
    MyOUD_INSTANCE=${OUD_INSTANCE}
fi

# set OUD Instance
. ${OUD_BASE}/bin/oudenv.sh $MyOUD_INSTANCE SILENT > /dev/null 2>&1
OUD_ERROR=$?
# handle errors from oudenv
if [ ${OUD_ERROR} -gt 0 ]; then
    CleanAndQuit 5 ${MyOUD_INSTANCE}    
fi

# append oud instance status log file
if [ "${INSTANCE_LOG}" == "TRUE" ]; then
    INSTANCE_LOGFILE="$OUD_ADMIN_BASE/$OUD_INSTANCE/log/$(basename $SCRIPT_NAME .sh)_$OUD_INSTANCE.log"
    # adjust output for scripts
    OUTPUT="${INSTANCE_LOGFILE}"
    touch ${INSTANCE_LOGFILE} 2>/dev/null
    if [ $? -ne 0 ] && [ ! -w "${INSTANCE_LOGFILE}" ]; then
        CleanAndQuit 11 ${INSTANCE_LOGFILE} # Define a clean exit
    fi
    # display start header
    DoMsg "${START_HEADER}"
    DoMsg "INFO : Append verbose log ouptut to instance status log file ${INSTANCE_LOGFILE}"
else
    DoMsg "${START_HEADER}"
fi

touch ${TMP_FILE} 2>/dev/null
if [ $? -eq 0 ] && [ -w "${TMP_FILE}" ]; then
    DoMsg "INFO : Touch temp file ${TMP_FILE}"
else
    CleanAndQuit 11 ${TMP_FILE} # Define a clean exit
fi

if [ ${DIRECTORY_TYPE} == "OUD" ]; then
	DoMsg "INFO : Identify directory type ${DIRECTORY_TYPE}"
    # Check if we have a bindPasswordFile
    MybindDN=${MybindDN:-"cn=Directory Manager"}
    MybindPasswordFile=${MybindPasswordFile:-"${PWD_FILE}"}
    if [ ! -f "${MybindPasswordFile}" ]; then
        CleanAndQuit 43 ${MyOUD_INSTANCE}
    fi  

    DoMsg "INFO : Run status on OUD Instance ${MyOUD_INSTANCE}"
    status --script-friendly --no-prompt --noPropertiesFile --bindDN "${MybindDN}" --bindPasswordFile ${MybindPasswordFile} --trustAll >${TMP_FILE} 2>&1
    OUD_ERROR=$?

    # handle errors from OUD status
    if [ ${OUD_ERROR} -gt 0 ]; then
        CleanAndQuit 41 ${OUD_ERROR}
    fi

    # adjust temp file 
    # and add a - at the end
    sed -i 's/^$/-/' ${TMP_FILE}
    # join Backend ID with multiple lines
    sed -i '/OracleContext for$/{N;s/\n/ /;}' ${TMP_FILE}
    # join Base DN with multiple lines
    sed -i '/^Base DN:$/{N;s/\n/                      /;}' ${TMP_FILE}

    DoMsg "INFO : Process ${TMP_FILE} file"
    # check Server Run Status
    if [ $(grep -ic 'Server Run Status: Started' ${TMP_FILE}) -eq 0 ]; then
        cat ${TMP_FILE} >> "${OUTPUT}"
        CleanAndQuit 50 ${OUD_INSTANCE}
    fi

    # check if connection handler are enabled
    for i in ${OUD_CON_HANDLER}; do
        DoMsg "INFO : Check connection handler ${i}"
        AWK_OUT=$(awk 'BEGIN{RS="\n-\n";FS="\n";IGNORECASE=1; Error=51} $1 ~ /^Address/ && $2 ~ /\<'${i}'\>/ {if ($3 ~ /\<Enabled\>/) Error=0; } END{exit Error}' ${TMP_FILE} )
        OUD_ERROR=$?
        if [ ${OUD_ERROR} -eq 51 ]; then
            cat ${TMP_FILE} >> "${OUTPUT}"
            CleanAndQuit 51 ${i}
        fi
    done

    if [ "${REPLICATION}" = "TRUE" ]; then
        i="Replication"
        DoMsg "INFO : Check connection handler ${i}"
        AWK_OUT=$(awk 'BEGIN{RS="\n-\n";FS="\n";IGNORECASE=1; Error=51} $1 ~ /^Address/ && $2 ~ /\<'${i}'\>/ {if ($3 ~ /\<Enabled\>/) Error=0; } END{exit Error}' ${TMP_FILE} )
        OUD_ERROR=$?
        if [ ${OUD_ERROR} -eq 51 ]; then
            cat ${TMP_FILE} >> "${OUTPUT}"
            CleanAndQuit 51 ${i}
        fi
    
        # check if there are errors in replications
        DoMsg "INFO : Run dsreplication status on OUD Instance ${MyOUD_INSTANCE}"
        dsreplication status --no-prompt --noPropertiesFile --port $PORT_ADMIN --trustAll --bindDN "${MybindDN}" --adminPasswordFile ${MybindPasswordFile} >${TMP_FILE} 2>&1
        OUD_ERROR=$?
        # handle errors from OUD dsreplication
        if [ ${OUD_ERROR} -gt 0 ]; then
            cat ${TMP_FILE} >> "${OUTPUT}"
            CleanAndQuit 42 ${OUD_ERROR}
        fi

        CAT_OUT=$(cat ${TMP_FILE}|awk 'BEGIN{FS=":";Error=0} /${OUD_ROOT_DN}/ {if ($7 !~/\<Normal\>/ ) Error=52; } END{exit Error}' )
        OUD_ERROR=$?
        if [ ${OUD_ERROR} -eq 52 ]; then
            CleanAndQuit 52 ${i}
        fi
    fi
elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
    DoMsg "INFO : Identify directory type ${DIRECTORY_TYPE}"
    URL="http://${HOST}:$PORT/oudsm/"
    DoMsg "INFO : Check status of OUDSM console ${URL}"
    
    # run OUD status check
    curl -sf ${URL} --output /dev/null 2>&1 >/dev/null 

    # normalize output for docker....
    OUD_ERROR=$?
    if [ ${OUD_ERROR} -gt 0 ]; then
        CleanAndQuit 53 ${URL}
    fi
else
    CleanAndQuit 44 ${DIRECTORY_TYPE}
fi

DoMsg "INFO : OK, status on OUD Instance ${MyOUD_INSTANCE}"

CleanAndQuit 0
# - EOF -----------------------------------------------------------------
