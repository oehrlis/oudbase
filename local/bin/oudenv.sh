#!/bin/bash
# ---------------------------------------------------------------------------
# $Id: $
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: oudenv.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: $LastChangedBy: $
# Date.......: $LastChangedDate: $
# Revision...: $LastChangedRevision: $
# Purpose....: Bash Source File to set the environment for OUD Instances
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# ---------------------------------------------------------------------------
# Rev History:
# 06.06.2016   soe  Initial version
# 19.07.2016   soe  Major changes to include oudenv.conf and oud.<INSTANCE>.conf
# 10.11.2017   soe  Add support for OUD_DATA to distinct persistant files for docker
# 13.11.2017   soe  Add get_ports and create oudtab entry
# ---------------------------------------------------------------------------

# - Environment Variables ---------------------------------------------------
# - Set default values for environment variables if not yet defined. 
# ---------------------------------------------------------------------------
export HOST=$(hostname)
SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"                  # Basename of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P)" # Absolute path of script
SCRIPT_FQN="${SCRIPT_DIR}/${SCRIPT_NAME}"                    # Full qualified script name

# default values for file and folder names
DEFAULT_OUD_ADMIN_BASE_NAME="admin"
DEFAULT_OUD_BACKUP_BASE_NAME="backup"
DEFAULT_OUD_INSTANCE_BASE_NAME="instances"
DEFAULT_OUDSM_DOMAIN_BASE_NAME="domains"
DEFAULT_OUD_LOCAL_BASE_NAME="local"
DEFAULT_OUD_LOCAL_BASE_BIN_NAME="bin"
DEFAULT_OUD_LOCAL_BASE_ETC_NAME="etc"
DEFAULT_OUD_LOCAL_BASE_LOG_NAME="log"
DEFAULT_OUD_LOCAL_BASE_TEMPLATES_NAME="templates"
DEFAULT_PRODUCT_BASE_NAME="product"
DEFAULT_ORACLE_HOME_NAME="fmw12.2.1.3.0"
DEFAULT_ORACLE_FMW_HOME_NAME="fmw12.2.1.3.0"
OUD_CORE_CONFIG="oudenv_core.conf"

DEFAULT_ORACLE_BASE=${SCRIPT_DIR%/${DEFAULT_OUD_LOCAL_BASE_NAME}/${DEFAULT_OUD_LOCAL_BASE_BIN_NAME}}

# default ORACLE_BASE or OUD_BASE
export ORACLE_BASE=${ORACLE_BASE:-${OUD_BASE}}
export ORACLE_BASE=${ORACLE_BASE:-${DEFAULT_ORACLE_BASE}}
export OUD_BASE=${OUD_BASE:-${ORACLE_BASE}}
export OUD_LOCAL="${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}"

# set the ETC_CORE to the oud local directory
export ETC_CORE=${OUD_LOCAL}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}

# source the core oudenv customizaition
if [ -f "${ETC_CORE}/${OUD_CORE_CONFIG}" ]; then
    . "${ETC_CORE}/${OUD_CORE_CONFIG}"
fi

# define location of base location for OUD data
export OUD_DATA=${OUD_DATA:-"${ORACLE_BASE}"}

# define misc base directories
export OUD_ADMIN_BASE=${OUD_ADMIN_BASE:-"${OUD_DATA}/${DEFAULT_OUD_ADMIN_BASE_NAME}"}
export OUD_BACKUP_BASE=${OUD_BACKUP_BASE:-"${OUD_DATA}/${DEFAULT_OUD_BACKUP_BASE_NAME}"}
export OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-"${OUD_DATA}/${DEFAULT_OUD_INSTANCE_BASE_NAME}"}
export OUDSM_DOMAIN_BASE=${OUDSM_DOMAIN_BASE:-"${OUD_DATA}/${DEFAULT_OUDSM_DOMAIN_BASE_NAME}"}

# define default home directories
export ORACLE_HOME=${ORACLE_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_HOME_NAME}"}
export ORACLE_FMW_HOME=${ORACLE_FMW_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/${DEFAULT_ORACLE_FMW_HOME_NAME}"}
export JAVA_HOME=${JAVA_HOME:-"${ORACLE_BASE}/${DEFAULT_PRODUCT_BASE_NAME}/java"}

# set directory type
DEFAULT_DIRECTORY_TYPE="OUD"
export DIRECTORY_TYPE=${DIRECTORY_TYPE:-"${DEFAULT_DIRECTORY_TYPE}"}
# - EOF Environment Variables -----------------------------------------------

# - Initialization ----------------------------------------------------------
tty >/dev/null 2>&1
pTTY=$?
export SILENT=${2}

# count number of execution / source
export SOURCED=$((SOURCED+1))

# Check OUD_BASE and load if necessary
if [ "${OUD_BASE}" = "" ]; then
    if [ -f "${HOME}/.OUD_BASE" ]; then
        . "${HOME}/.OUD_BASE"
    else
        echo "ERROR: Could not load ${HOME}/.OUD_BASE"
    fi
fi  

# Check if OUD_BASE exits
if [ "${OUD_BASE}" = "" ] || [ ! -d "${OUD_BASE}" ]; then
    echo "ERROR: OUD_BASE not set or \$OUD_BASE not available"
    return 1
fi

# Check if JAVA_HOME is defined
if [ "${JAVA_HOME}" == "" ]; then
    echo "WARN : JAVA_HOME is not set or could not be determined automatically"
fi

# store PATH on first execution otherwise reset it
if [ ${SOURCED} -le 1 ]; then
    export OUDSAVED_PATH=${PATH}
else
    if [ ${OUDSAVED_PATH} ]; then
        export PATH=${OUDSAVED_PATH}
    fi
fi

# set the log and etc base directory depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE=${OUD_LOCAL}/${DEFAULT_OUD_LOCAL_BASE_LOG_NAME}
    export ETC_BASE=${OUD_LOCAL}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}
else
    export LOG_BASE=${OUD_DATA}/${DEFAULT_OUD_LOCAL_BASE_LOG_NAME}
    export ETC_BASE=${OUD_DATA}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}
fi

# recreate missing directories
for i in ${OUD_ADMIN_BASE} ${OUD_BACKUP_BASE} ${OUD_INSTANCE_BASE} ${ETC_BASE} ${LOG_BASE}; do
    mkdir -p ${i}
done

# Create default config file in ETC_BASE in case they are missing...
for i in oud._DEFAULT_.conf oudenv_custom.conf oudenv.conf oudtab; do
    if [ ! -f "${ETC_BASE}/${i}" ]; then
        cp ${OUD_LOCAL}/${DEFAULT_OUD_LOCAL_BASE_TEMPLATES_NAME}/${DEFAULT_OUD_LOCAL_BASE_ETC_NAME}/${i} ${ETC_BASE}
    fi
done

# create also some soft links from ETC_CORE to ETC_BASE
for i in oudenv.conf oudtab; do
    if [ ! -f "${ETC_BASE}/${i}" ]; then
        ln -sf ${ETC_BASE}/${i} ${ETC_CORE}/${i}
    fi
done

# set the OUDTAB to ETC_BASE or fallback to ETC_CORE
if [ -f "${ETC_BASE}/oudtab" ]; then
    export OUDTAB=${ETC_BASE}/oudtab
else
    export OUDTAB=${ETC_CORE}/oudtab
fi

# Load list of OUD Instances from oudtab
if [ -f "${OUDTAB}" ]; then 
    # create a OUD Instance Liste based on oudtab
    export OUD_INST_LIST=$(grep -v '^#' ${OUDTAB}|cut -f1 -d:)
    
    # set a default OUD_INST_LIST if oudtab is empty
    if [ "${OUD_INST_LIST}" = "" ]; then
        # try to load instance list based on OUD instance base directory
        echo "WARN : Could not find any OUD instance in ${OUDTAB}"
        echo "WARN : Fallback to \${OUD_DATA}/*/OUD"
        unset OUD_INST_LIST
        for i in "${OUD_INSTANCE_BASE}/*/OUD"; do
            # create a OUD Instance Liste based on OUD base
            OUD_INST_LIST="${OUD_INST_LIST} $(echo $i|sed 's/^.*\/\(.*\)\/OUD.*$/\1/')"
        done
    fi
    
    # if not defined set default instance to first of OUD_INST_LIST 
    if [ "${OUD_DEFAULT_INSTANCE}" = "" ]; then
        export OUD_DEFAULT_INSTANCE=$(echo $OUD_INST_LIST|cut -f1 -d' ')
    fi
else
    # try to load instance list based on OUD instance base directory
    echo "WARN : Could not load OUD list from ${OUDTAB}"
    echo "WARN : Fallback to \${OUD_DATA}/*/OUD"
    unset OUD_INST_LIST
    for i in "${OUD_INSTANCE_BASE}/*/OUD"; do
        # create a OUD Instance Liste based on OUD base
        OUD_INST_LIST="${OUD_INST_LIST} $(echo $i|sed 's/^.*\/\(.*\)\/OUD.*$/\1/')"
    done
fi

# remove newline in OUD_INST_LIST
OUD_INST_LIST=$(echo ${OUD_INST_LIST}|tr '\n' ' ')

# set the last OUD instance to ...
if [ "${OUD_INSTANCE}" = "" ]; then
    # the default instance
    export OUD_INSTANCE_LAST=${OUD_DEFAULT_INSTANCE}
else
    # the real last instance
    export OUD_INSTANCE_LAST=${OUD_INSTANCE}
fi

# use default OUD Instance if none has been specified as parameter
if [ "${1}" = "" ]; then
    export OUD_INSTANCE=${OUD_DEFAULT_INSTANCE}
elif [ "${1}" = "SILENT" ]; then
    export OUD_INSTANCE=${OUD_DEFAULT_INSTANCE}  
    export SILENT="SILENT"
else
    export OUD_INSTANCE=${1}
fi
# - EOF Initialization ------------------------------------------------------

# - Functions ---------------------------------------------------------------
# ---------------------------------------------------------------------------
function oud_status {
# Purpose....: just display the current OUD settings
# ---------------------------------------------------------------------------
    STATUS=$(get_status)
    DIR_STATUS="ok"
    if [ ${DIRECTORY_TYPE} == "OUD" ] && [ ! -f "${OUD_INSTANCE_HOME}/OUD/config/config.ldif" ]; then
        DIR_STATUS="??"
        STATUS="not yet created..."
    elif [ ${DIRECTORY_TYPE} == "ODSEE" ] && [ ! -f "${OUD_INSTANCE_HOME}/config/dse.ldif" ]; then
        DIR_STATUS="??"
        STATUS="not yet created..."
    elif [ ${DIRECTORY_TYPE} == "OUDSM" ] && [ ! -f "${OUD_INSTANCE_HOME}/config/config.xml" ]; then
        DIR_STATUS="??"
        STATUS="not yet created..."
    fi
    
    get_ports "-silent"      # read ports from OUD config file
    get_oracle_home "-silent"      # read oracle home from OUD install.path file
    echo "--------------------------------------------------------------"
    echo " Instance Name      : ${OUD_INSTANCE}"
    echo " Instance Home ($DIR_STATUS) : ${OUD_INSTANCE_HOME} "
    echo " Oracle Home        : ${ORACLE_HOME}"
    echo " Instance Status    : ${STATUS}"
    if [ ${DIRECTORY_TYPE} == "OUD" ]; then
        echo " LDAP Port          : $PORT"
        echo " LDAPS Port         : $PORT_SSL"
        echo " Admin Port         : $PORT_ADMIN"
        echo " Replication Port   : $PORT_REP"
    elif [ ${DIRECTORY_TYPE} == "ODSEE" ]; then
        echo " LDAP Port          : $PORT"
        echo " LDAPS Port         : $PORT_SSL"
    elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then 
        echo " Console            : http://$(hostname):$PORT/oudsm"
        echo " HTTP               : $PORT"
        echo " HTTPS              : $PORT_SSL"
    fi
    echo "--------------------------------------------------------------"
}

# ---------------------------------------------------------------------------
function oud_up {
# Purpose....: display the status of the OUD instances
# ---------------------------------------------------------------------------
    echo "TYPE  INSTANCE     STATUS PORTS          INSTANCE HOME"
    echo "----- ------------ ------ -------------- ----------------------------------"
    for i in ${OUD_INST_LIST}; do
        # oudtab ohne instance home
        PORT_ADMIN=$(grep -v '^#' ${OUDTAB}|grep -i ${i} |head -1|cut -d: -f4)
        PORT=$(grep -v '^#' ${OUDTAB}|grep -i ${i} |head -1|cut -d: -f2)
        PORT_SSL=$(grep -v '^#' ${OUDTAB}|grep -i ${i} |head -1|cut -d: -f3)
        DIRECTORY_TYPE=$(grep -v '^#' ${OUDTAB}|grep -i ${i} |head -1|cut -d: -f6)
        DIRECTORY_TYPE=${DIRECTORY_TYPE:-"${DEFAULT_DIRECTORY_TYPE}"}
        STATUS=$(get_status ${i})
        if [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
            INSTANCE_HOME="${OUDSM_DOMAIN_BASE}/$i"
        else
            INSTANCE_HOME="${OUD_INSTANCE_BASE}/$i"
        fi
        printf '%-5s %-12s %-6s %-14s %-s\n' ${DIRECTORY_TYPE} ${i} ${STATUS} \
            "$(join_by / ${PORT} ${PORT_SSL} ${PORT_ADMIN})" "${INSTANCE_HOME}"
    done
    echo ""
}

# ---------------------------------------------------------------------------
function get_status { 
# Purpose....: get the current instance / process status
# ---------------------------------------------------------------------------
    InstanceName=${1:-${OUD_INSTANCE}}

    if [ ${DIRECTORY_TYPE} == "OUD" ]; then
        echo "$(if [ $(ps -ef | egrep -v 'ps -ef|grep ' | \
                grep org.opends.server.core.DirectoryServer|\
                grep -c ${InstanceName} ) -gt 0 ]; \
                then echo 'up'; else echo 'down'; fi)"
    elif [ ${DIRECTORY_TYPE} == "ODSEE" ]; then
        echo "$(if [ $(ps -ef | egrep -v 'ps -ef|grep ' | \
                grep ns-slapd|\
                grep -c ${InstanceName} ) -gt 0 ]; \
                then echo 'up'; else echo 'down'; fi)"
    elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
        echo "$(if [ $(ps -ef | egrep -v 'ps -ef|grep ' | \
                grep wlserver|\
                grep -c ${InstanceName} ) -gt 0 ]; \
                then echo 'up'; else echo 'down'; fi)"
    else
        echo "n/a"
    fi
}

function get_oracle_home {
# Purpose....: get the corresponding ORACLE_HOME from OUD Instance
# ---------------------------------------------------------------------------
    if [ ${DIRECTORY_TYPE} == "OUD" ]; then
        Silent=$1
        if [ -r "${OUD_INSTANCE_HOME}/OUD/install.path" ]; then
            read ORACLE_HOME < "${OUD_INSTANCE_HOME}/OUD/install.path"
            if [ -d ${ORACLE_HOME} ]; then
                ORACLE_HOME=$(dirname ${ORACLE_HOME})
            else
                echo "WARN : Can not determin ORACLE_HOME from OUD Instance. Please explicitly set ORACLE_HOME"
            fi
        else
            echo "WARN : Can not determin ORACLE_HOME from OUD Instance. Please explicitly set ORACLE_HOME"
        fi
        export ORACLE_HOME
        if [ "${Silent}" == "" ]; then
            echo " Oracle Home    : ${ORACLE_HOME}"
        fi
    fi
}

# ---------------------------------------------------------------------------
function get_ports {
# Purpose....: get the corresponding PORTS from OUD Instance
# ---------------------------------------------------------------------------
    if [ ${DIRECTORY_TYPE} == "OUD" ]; then
        Silent=$1
        CONFIG="${OUD_INSTANCE_HOME}/OUD/config/config.ldif"
        if [ -r $CONFIG ]; then
            # read ports from config file
            PORT_ADMIN=$(sed -n '/LDAP Administration Connector/,/^$/p' $CONFIG|grep -i ds-cfg-listen-port|cut -d' ' -f2)
            PORT=$(sed -n '/LDAP Connection Handler/,/^$/p' $CONFIG|grep -i ds-cfg-listen-port|cut -d' ' -f2)
            PORT_SSL=$(sed -n '/LDAPS Connection Handler/,/^$/p' $CONFIG|grep -i ds-cfg-listen-port|cut -d' ' -f2)
            PORT_REP=$(sed -n '/LDAP Replication Connector/,/^$/p' $CONFIG|grep -i ds-cfg-listen-port|cut -d' ' -f2)
        else
            echo "WARN : Can not determin config.ldif from OUD Instance. Please explicitly set your PORTS."
        fi
        # export the port variables and set default values with not specified
        export PORT_ADMIN=${PORT_ADMIN:-"4444"}
        export PORT=${PORT:-"1389"}
        export PORT_SSL=${PORT_SSL:-"1636"}
        export PORT_REP=${PORT_REP:-"8989"}
        
        if [ "${Silent}" == "" ]; then
            echo "--------------------------------------------------------------"
            echo " Instance Name   : ${OUD_INSTANCE}"
            echo " LDAP Port       : $PORT"
            echo " LDAPS Port      : $PORT_SSL"
            echo " Admin Port      : $PORT_ADMIN"
            echo " Replication Port: $PORT_REP"
            echo "--------------------------------------------------------------"
        fi
    fi
}

# ---------------------------------------------------------------------------
function update_oudtab {
# Purpose....: update OUD tab
# ---------------------------------------------------------------------------
    if [ ${DIRECTORY_TYPE} == "OUD" ]; then
        get_ports -silent
        if [ -f "${OUDTAB}" ]; then
            if [ $(grep -v '^#' ${OUDTAB}| grep -iwc ${OUD_INSTANCE}) -eq 1 ]; then 
                sed -i "/${OUD_INSTANCE}/c\\${OUD_INSTANCE}:$PORT:$PORT_SSL:$PORT_ADMIN:$PORT_REP:$DIRECTORY_TYPE" "${OUDTAB}"
            else
                echo "add ${OUD_INSTANCE} to ${OUDTAB}"
                echo "${OUD_INSTANCE}:$PORT:$PORT_SSL:$PORT_ADMIN:$PORT_REP:$DIRECTORY_TYPE" >>"${OUDTAB}"
            fi
        fi
    fi
}
# ---------------------------------------------------------------------------
function oud_help {
# Purpose....: just display help for OUD environment
# ---------------------------------------------------------------------------
echo "--- OUD Instances -----------------------------------------------------"
echo ""
echo "--- ENV Variables -----------------------------------------------------"
echo "  CUSTOM_ORA_LOG      = ${CUSTOM_ORA_LOG-n/a}"
echo "  DIRECTORY_TYPE      = ${DIRECTORY_TYPE-n/a}"
echo "  ETC_BASE            = ${ETC_BASE-n/a}"
echo "  ETC_BASE            = ${ETC_BASE-n/a}"
echo "  ETC_CORE            = ${ETC_CORE-n/a}"
echo "  INSTANCE_BASE       = ${INSTANCE_BASE-n/a}"
echo "  INSTANCE_BASE       = ${INSTANCE_BASE-n/a}"
echo "  JAVA_HOME           = ${JAVA_HOME-n/a}"
echo "  LOG_BASE            = ${LOG_BASE-n/a}"
echo "  ORACLE_BASE         = ${ORACLE_BASE-n/a}"
echo "  ORACLE_FMW_HOME     = ${ORACLE_FMW_HOME-'n/a'}"
echo "  ORACLE_HOME         = ${ORACLE_HOME-n/a}"
echo "  OUD_INSTANCE        = ${OUD_INSTANCE-n/a}"
echo "  OUDSM_DOMAIN_BASE   = ${OUDSM_DOMAIN_BASE-n/a}"
echo "  OUD_INSTANCE_BASE   = ${OUD_INSTANCE_BASE-n/a}"
echo "  OUD_INSTANCE_HOME   = ${OUD_INSTANCE_HOME-n/a}"
echo "  PORT                = ${PORT-n/a}"
echo "  PORT_ADMIN          = ${PORT_ADMIN-n/a}"
echo "  PORT_REP            = ${PORT_REP-n/a}"
echo "  PORT_SSL            = ${PORT_SSL-n/a}"
echo ""
echo "--- Default Aliases ---------------------------------------------------"
echo "  oudup       List OUD instances and there status short form u"
echo "  oud_status  Display OUD status of current instance"
echo "  oud_help    Display OUD environment help short form h"
echo "  gp          Get ports of current oud instance"
echo "  goh         Get oracle home of current oud instance"
echo ""
if [ -s "${ETC_BASE}/oudenv_custom.conf" ]; then
    echo "--- Custom Aliases ---------------------------------------------------"
    while read -r line; do
#    If the line starts with alias then echo the line
    if [[ $line == alias*  ]] ; then
        ALIAS=$(echo $line|sed -r 's/^.*\s(.*)=('"'"'|").*/\1/' )
        COMMENT=$(echo $line|sed -r 's/^.*(#(.*)$|(('"'"')|"))$/\2/')
        COMMENT=${COMMENT:-"n/a"}
        printf "  %-10s %-s\n" \
                ${ALIAS} \
                "${COMMENT}"
    fi
    done < "${ETC_BASE}/oudenv_custom.conf"
    echo ""
fi
}

# ---------------------------------------------------------------------------
function join_by { 
# Purpose....: Join array elements
# ---------------------------------------------------------------------------
    local IFS="$1"; shift; echo "$*"; 
}

# ---------------------------------------------------------------------------
function relpath {
# Purpose....: get the relative path of DIR1 from DIR2
# ---------------------------------------------------------------------------
    BaseDirectory=$1
    TargetDirectory=$2

    if [ "${BaseDirectory}" == "" ]; then
        echo "WARN : BaseDirectory in relpath is empty."
        caller
        return 1
    fi
    
    if [ "${TargetDirectory}" == "" ]; then
        echo "WARN : TargetDirectory in relpath is empty."
        caller
        return 1
    fi
    
    CommonPart=$BaseDirectory # for now
    Result="" # for now

    while [[ "${TargetDirectory#$CommonPart}" == "${TargetDirectory}" ]]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        CommonPart="$(dirname $CommonPart)"
        # and record that we went back, with correct / handling
        if [[ -z $Result ]]; then
            Result=".."
        else
            Result="../$Result"
        fi
    done

    if [[ $CommonPart == "/" ]]; then
        # special case for root (no common path)
        Result="$Result/"
    fi

    # since we now have identified the common part,
    # compute the non-common part
    ForwardPart="${TargetDirectory#$CommonPart}"

    # and now stick all parts together
    if [[ -n $Result ]] && [[ -n $ForwardPart ]]; then
        Result="$Result$ForwardPart"
    elif [[ -n $ForwardPart ]]; then
        # extra slash removal
        Result="${ForwardPart:1}"
    fi
    echo "$Result"
}
# - EOF Functions -----------------------------------------------------------

# - Main --------------------------------------------------------------------

# Load OUD config from oudtab
if [ -f "${OUDTAB}" ]; then # check if the requested OUD Instance exists in oudtab
    if [ $(grep -v '^#' ${OUDTAB}| grep -iwc ${OUD_INSTANCE}) -eq 1 ]; then 
        # set new environment based on oudtab
        OUD_CONF_STR=$(grep -v '^#' ${OUDTAB}|grep -i ${OUD_INSTANCE}|head -1)
        OUD_INSTANCE=$(echo ${OUD_CONF_STR}|cut -d: -f1)
        PORT=$(echo ${OUD_CONF_STR}|cut -d: -f2)
        PORT_SSL=$(echo ${OUD_CONF_STR}|cut -d: -f3)
        PORT_ADMIN=$(echo ${OUD_CONF_STR}|cut -d: -f4)
        PORT_REP=$(echo ${OUD_CONF_STR}|cut -d: -f5)
        DIRECTORY_TYPE=$(echo ${OUD_CONF_STR}|cut -d: -f6)
        DIRECTORY_TYPE=${DIRECTORY_TYPE:-"${DEFAULT_DIRECTORY_TYPE}"}
        
        # set the instance home based on directory type
        if [ ${DIRECTORY_TYPE} == "OUD" ]; then
            OUD_INSTANCE_HOME="${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"
        elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
            OUD_INSTANCE_HOME="${OUDSM_DOMAIN_BASE}/${OUD_INSTANCE}"
        else
            OUD_INSTANCE_HOME="${OUD_INSTANCE_BASE}/${OUD_INSTANCE}"
        fi
        export OUD_INSTANCE_HOME
        export OUD_INSTANCE_ADMIN=${OUD_ADMIN_BASE}/${OUD_INSTANCE}

        # get_oracle_home 
        get_oracle_home -silent    # get oracle home from OUD instance
        export INSTANCE_NAME=$(relpath "${ORACLE_HOME}" "${OUD_INSTANCE_HOME}")
        export PORT
        export PORT_SSL
        export PORT_ADMIN
        export PORT_REP
        export DIRECTORY_TYPE
    elif [ -d "${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/OUD" ]; then
        # fallback to OUD_INSTANCE_BASE Instance directory
        export OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}
        export OUD_INSTANCE_ADMIN=${OUD_ADMIN_BASE}/${OUD_INSTANCE}
        echo "WARN : Set Instance based on ${OUD_INSTANCE_HOME}"
        get_oracle_home -silent    # get oracle home from OUD instance
        get_ports -silent    # get ports from OUD config
        echo "${OUD_INSTANCE}:${PORT}:${PORT_SSL}:${PORT_ADMIN}:${PORT_REP}:${DIRECTORY_TYPE}">>${OUDTAB}
        echo "WARN : Add ${OUD_INSTANCE} to ${OUDTAB} please review ports"
    else # print error and keep current setting
        echo "ERROR: OUD Instance ${OUD_INSTANCE} does not exits in ${OUDTAB} or ${OUD_INSTANCE_BASE}"
        export OUD_INSTANCE=${OUD_INSTANCE_LAST}
    fi
else # check if the requested OUD Instance exists in oudbase
    if [ -d "${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/OUD" ]; then
        export OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}
        export OUD_INSTANCE_ADMIN=${OUD_ADMIN_BASE}/${OUD_INSTANCE}
        get_oracle_home -silent    # get oracle home from OUD instance
        get_ports -silent    # get ports from OUD config
        export INSTANCE_NAME=$(relpath "${ORACLE_HOME}" "${OUD_INSTANCE_HOME}")
    else # print error and keep current setting
        echo "ERROR: OUD Instance ${OUD_INSTANCE} does not exits in ${OUD_INSTANCE_BASE}"
        export OUD_INSTANCE=${OUD_INSTANCE_LAST}
    fi
fi

RECREATE="TRUE"
# re-create instance admin directory
if [ ! -d "${OUD_INSTANCE_ADMIN}" ] && [ "${RECREATE}" = "TRUE" ]; then
    mkdir -p "${OUD_INSTANCE_ADMIN}" >/dev/null 2>&1
    mkdir -p "${OUD_INSTANCE_ADMIN}/create" >/dev/null 2>&1
    mkdir -p "${OUD_INSTANCE_ADMIN}/log" >/dev/null 2>&1
    mkdir -p "${OUD_INSTANCE_ADMIN}/etc" >/dev/null 2>&1
fi

# re-create instance admin directory
if [ ! -f "${ETC_BASE}/oud.${OUD_INSTANCE}.conf" ] && [ "${RECREATE}" = "TRUE" ]; then
    echo "# ---------------------------------------------------------------------------" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
    echo "# Instance Name      : ${OUD_INSTANCE}"      >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
    echo "# Instance Type      : ${DIRECTORY_TYPE}"    >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
    echo "# Instance Home      : ${OUD_INSTANCE_HOME}" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
    echo "# Oracle Home        : ${ORACLE_HOME}"       >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
    echo "# ---------------------------------------------------------------------------" >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
    echo "export ORACLE_HOME=${ORACLE_HOME}"  >>${ETC_BASE}/oud.${OUD_INSTANCE}.conf
fi

# set the new PATH
if [ ${DIRECTORY_TYPE} == "OUD" ]; then
    export PATH=${OUD_LOCAL}/${DEFAULT_OUD_LOCAL_BASE_BIN_NAME}:${OUD_INSTANCE_HOME}/OUD/bin:${ORACLE_HOME}:${JAVA_HOME}/bin:${PATH}
elif [ ${DIRECTORY_TYPE} == "OUDSM" ]; then
    export PATH=${OUD_LOCAL}/${DEFAULT_OUD_LOCAL_BASE_BIN_NAME}:${OUD_INSTANCE_HOME}/bin:${ORACLE_HOME}:${JAVA_HOME}/bin:${PATH}
elif [ ${DIRECTORY_TYPE} == "ODSEE" ]; then
    export PATH=${OUD_LOCAL}/${DEFAULT_OUD_LOCAL_BASE_BIN_NAME}:${OUD_INSTANCE_HOME}/OUD/bin:${ORACLE_HOME}:${JAVA_HOME}/bin:${PATH}
fi 

# source oudenv.conf file from core etc directory if it exits
if [ -f "${ETC_CORE}/oudenv.conf" ]; then
    . "${ETC_CORE}/oudenv.conf"
fi 
# source oud._DEFAULT_.conf from core etc directory if it exits
if [ -f "${ETC_CORE}/oud._DEFAULT_.conf" ]; then
    . "${ETC_CORE}/oud._DEFAULT_.conf"
fi

# start to source stuff from ETC_BASE
# source oudenv.conf file to set environment variables and aliases
if [ -f "${ETC_BASE}/oudenv.conf" ]; then
    . "${ETC_BASE}/oudenv.conf"
else
    echo "WARN : Could not source ${ETC_BASE}/oudenv.conf"
fi  

if [ -f "${ETC_BASE}/oudenv_custom.conf" ]; then
    . "${ETC_BASE}/oudenv_custom.conf"
fi  

# source oud._DEFAULT_.conf if exists
if [ -f "${ETC_BASE}/oud._DEFAULT_.conf" ]; then
    . "${ETC_BASE}/oud._DEFAULT_.conf"
fi

# source oud.<OUD_INSTANCE>.conf if exists
if [ -f "${ETC_BASE}/oud.${OUD_INSTANCE}.conf" ]; then
    . "${ETC_BASE}/oud.${OUD_INSTANCE}.conf"
fi

# set the password file variable based on ETC_BASE
if [ -f "${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt" ]; then
    export PWD_FILE=${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt
else
    export PWD_FILE=${ETC_BASE}/pwd.txt
fi

if [ ${pTTY} -eq 0 ] && [ "${SILENT}" = "" ]; then
    echo "Source environment for ${DIRECTORY_TYPE} Instance ${OUD_INSTANCE}"
    oud_status
fi
# - EOF ---------------------------------------------------------------------
