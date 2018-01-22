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
#
# - Customization -----------------------------------------------------------
# - Below you may set some variables explicit. In general this customization 
# - should not be necessary. It's recommended to set the variable before using
# - oudenv.sh eg. in .bash_profile. 
# - The installation script oudbase_install will add available variable bellow 
# - the tag INSTALL_CUSTOMIZATION.
# 
# - Possible variables for customization
# - ORACLE_BASE       define the Oracle base directory, defaults to /u00/app/oracle
# - OUD_BASE          define the oud base directory, defaults to ORACLE_BASE
# - OUD_DATA          define oud directory for data, instance, configurations
# - OUD_INSTANCE_BASE define the instance base directory, defaults OUD_DATA/instances
# - OUD_BACKUP_BASE   define the backup base directory, defaults OUD_DATA/backup
# - ORACLE_HOME       define the backup base directory, defaults to ORACLE_BASE/middleware
# - ORACLE_FMW_HOME   define the backup base directory, defaults to ORACLE_HOME
# - JAVA_HOME         define the java home
# - LOG_BASE          alternative log directory, defaults to OUD_BASE/local/log
# - ETC_BASE          alternative etc/config directory, defaults to OUD_BASE/local/etc
#
# - Do not change anything below the customization section.
# ---------------------------------------------------------------------------
# <INSTALL_CUSTOMIZATION>

# - End of Customization ----------------------------------------------------

# - Environment Variables ---------------------------------------------------
# - Set default values for environment variables if not yet defined. 
# ---------------------------------------------------------------------------
export HOST=$(hostname)
export ORACLE_BASE=${ORACLE_BASE:-"${OUD_BASE}"}
export OUD_DATA=${OUD_DATA:-"/u01"}
export OUD_LOCAL="${OUD_BASE}/local"            # sowiesoe
export OUD_INSTANCE_BASE=${OUD_INSTANCE_BASE:-"${OUD_DATA}/instances"}
export OUD_BACKUP_BASE=${OUD_BACKUP_BASE:-"${OUD_DATA}/backup"}

export ORACLE_HOME=${ORACLE_HOME:-"$(find ${ORACLE_BASE} ! -readable -prune -o -name oud-setup -print |sed 's/\/oud\/oud-setup$//'|head -n 1)"}
export ORACLE_FMW_HOME=${ORACLE_FMW_HOME:-"$(find ${ORACLE_BASE} ! -readable -prune -o -name oudsm-wlst.jar -print|sed -r 's/(\/[^\/]+){3}\/oudsm-wlst.jar//g'|head -n 1)"}
export JAVA_HOME=${JAVA_HOME:-$(readlink -f $(find ${ORACLE_BASE} /usr/java ! -readable -prune -o -type f -name java -print |head -1)| sed "s:/bin/java::")}

# set directory type
export DIRECTORY_TYPE=OUD
if [ "$(find ${ORACLE_BASE} ! -readable -prune -o -name dsadm -printf '%f\n')" = "dsadm" ]; then
    export DIRECTORY_TYPE=ODSEE
    # fallback for ODSEE home...
    export ORACLE_HOME=${ORACLE_HOME:-"$(find ${ORACLE_BASE} ! -readable -prune -o -name dsadm -print |sed 's/\/bin\/dsadm$//'|head -n 1)"}
    echo "Directory type is ${DIRECTORY_TYPE}"
fi
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

# store PATH on first execution otherwise reset it
if [ ${SOURCED} -le 1 ]; then
    export OUDSAVED_PATH=${PATH}
else
    if [ ${OUDSAVED_PATH} ]; then
        export PATH=${OUDSAVED_PATH}
    fi
fi

# set the ETC_CORE to the oud local directory
export ETC_CORE=${OUD_LOCAL}/etc

# set the log and etc base directory depending on OUD_DATA
if [ "${ORACLE_BASE}" = "${OUD_DATA}" ]; then
    export LOG_BASE=${OUD_LOCAL}/log
    export ETC_BASE=${OUD_LOCAL}/etc
else
    export LOG_BASE=${OUD_DATA}/log
    export ETC_BASE=${OUD_DATA}/etc
fi

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
    if [ ${DIRECTORY_TYPE} == "OUD" ]; then
        STATUS="$(if [ $(ps -ef | egrep -v 'ps -ef|grep ' | \
                  grep org.opends.server.core.DirectoryServer|\
                  grep -c ${OUD_INSTANCE} ) -gt 0 ]; \
                  then echo 'up'; else echo 'down'; fi)"
        if [ -f ${OUD_INSTANCE_HOME}/OUD/config/config.ldif ]; then
            DIR_STATUS="ok"
        else
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
        echo " LDAP Port          : $PORT"
        echo " LDAPS Port         : $PORT_SSL"
        echo " Admin Port         : $PORT_ADMIN"
        echo " Replication Port   : $PORT_REP"
        echo "--------------------------------------------------------------"
    fi
}

# ---------------------------------------------------------------------------
function oudup {
# Purpose....: display the status of the OUD instances
# ---------------------------------------------------------------------------
    if [ ${DIRECTORY_TYPE} == "OUD" ]; then
        echo "TYPE INSTANCE   STATUS PORTS          HOME"
        echo "---- ---------- ------ -------------- ----------------------------------"
        for i in ${OUD_INST_LIST}; do
            STATUS="$(if [ $(ps -ef | egrep -v 'ps -ef|grep ' | \
                        grep org.opends.server.core.DirectoryServer|\
                        grep -c $i ) -gt 0 ]; \
                        then echo 'up'; else echo 'down'; fi)"
            # oudtab ohne instance home
            PORT_ADMIN=$(grep -v '^#' ${OUDTAB}|grep -i ${i} |head -1|cut -d: -f4)
            PORT=$(grep -v '^#' ${OUDTAB}|grep -i ${i} |head -1|cut -d: -f2)
            PORT_SSL=$(grep -v '^#' ${OUDTAB}|grep -i ${i} |head -1|cut -d: -f3)
            printf "OUD  %-10s %-6s %-14s %-s\n" \
                $i \
                ${STATUS} \
                "${PORT}/${PORT_SSL}/${PORT_ADMIN}" \
                "${OUD_INSTANCE_BASE}/$i"
        done
        echo ""
    fi
}

# ---------------------------------------------------------------------------
function get_oracle_home {
# Purpose....: get the corresponding ORACLE_HOME from OUD Instance
# ---------------------------------------------------------------------------
    if [ ${DIRECTORY_TYPE} == "OUD" ]; then
        Silent=$1
        if [ -r "${OUD_INSTANCE_HOME}/OUD/install.path" ]; then
            read ORACLE_HOME < "${OUD_INSTANCE_HOME}/OUD/install.path"
            ORACLE_HOME=$(dirname ${ORACLE_HOME})
        else
            echo "WARN : Can not determin ORACLE_HOME from OUD Instance."
            echo "       Please explicitly set ORACLE_HOME"
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
            echo "WARN : Can not determin config.ldif from OUD Instance."
            echo "       Please explicitly set your PORTS"
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
        printf " %-10s %-s\n" \
                ${ALIAS} \
                "${COMMENT}"
    fi
    done < "${ETC_BASE}/oudenv_custom.conf"
    echo ""
fi
}

# ---------------------------------------------------------------------------
function relpath {
# Purpose....: get the relative path of DIR1 from DIR2
# ---------------------------------------------------------------------------
    BaseDirectory=$1
    TargetDirectory=$2

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
        export OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}
        
        # get_oracle_home 
        get_oracle_home -silent    # get oracle home from OUD instance
        export INSTANCE_NAME=$(relpath "${ORACLE_HOME}" "${OUD_INSTANCE_HOME}")
        export PORT
        export PORT_SSL
        export PORT_ADMIN
        export PORT_REP
    elif [ -d "${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/OUD" ]; then
        # fallback to OUD_INSTANCE_BASE Instance directory
        export OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}
        echo "WARN : Set Instance based on ${OUD_INSTANCE_HOME}"
        get_oracle_home -silent    # get oracle home from OUD instance
        get_ports -silent    # get ports from OUD config
        echo "${OUD_INSTANCE}:${PORT}:${PORT_SSL}:${PORT_ADMIN}:${PORT_REP}:">>${OUDTAB}
        echo "WARN : Add ${OUD_INSTANCE} to ${OUDTAB} please review ports"
    else # print error and keep current setting
        echo "ERROR: OUD Instance ${OUD_INSTANCE} does not exits in ${OUDTAB} or ${OUD_INSTANCE_BASE}"
        export OUD_INSTANCE=${OUD_INSTANCE_LAST}
        return 1
    fi
else # check if the requested OUD Instance exists in oudbase
    if [ -d "${OUD_INSTANCE_BASE}/${OUD_INSTANCE}/OUD" ]; then
        export OUD_INSTANCE_HOME=${OUD_INSTANCE_BASE}/${OUD_INSTANCE}
        get_oracle_home -silent    # get oracle home from OUD instance
        get_ports -silent    # get ports from OUD config
        export INSTANCE_NAME=$(relpath "${ORACLE_HOME}" "${OUD_INSTANCE_HOME}")
    else # print error and keep current setting
        echo "ERROR: OUD Instance ${OUD_INSTANCE} does not exits in ${OUD_INSTANCE_BASE}"
        export OUD_INSTANCE=${OUD_INSTANCE_LAST}
        return 1
    fi
fi

# set the new PATH
export PATH=${OUD_LOCAL}/bin:${OUD_INSTANCE_HOME}/OUD/bin:${ORACLE_HOME}:${JAVA_HOME}/bin:${PATH}

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
if [ -f ${ETC_BASE}/${OUD_INSTANCE}_pwd.txt ]; then
    export PWD_FILE=${ETC_BASE}/${OUD_INSTANCE}_pwd.txt
else
    export PWD_FILE=${ETC_BASE}/pwd.txt
fi


if [ ${pTTY} -eq 0 ] && [ "${SILENT}" = "" ]; then
    echo "Source environment for ${DIRECTORY_TYPE} Instance ${OUD_INSTANCE}"
    oud_status
fi
# - EOF ---------------------------------------------------------------------
