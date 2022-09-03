#!/bin/bash
# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Data Platform - Transactional Data Platform
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: oud_eusm.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2022.09.03
# Version....: v2.7.1
# Purpose....: Shell script for EUS admin tool (command line)
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# ------------------------------------------------------------------------------

# - Default Values ------------------------------------------------------
VERSION=v2.7.1
JRE_HOME=$JAVA_HOME/jre/
EUSMLIBDIR=$ORACLE_BASE/local/oudbase/lib
ORACLEPKI=$ORACLE_HOME/oracle_common/modules/oracle.pki/oraclepki.jar
OSDT_CERT=$ORACLE_HOME/oracle_common/modules/oracle.osdt/osdt_cert.jar
OSDT_CORE=$ORACLE_HOME/oracle_common/modules/oracle.osdt/osdt_core.jar
OJDBC8=$ORACLE_HOME/oracle_common/modules/oracle.jdbc/ojdbc8.jar
RDBMSVER=19
# - End of Default Values ------------------------------------------------------

if [ -f "$ORACLE_BASE/local/oudbase/lib/eusm.jar" ] &&  [ -f "$ORACLE_BASE/local/oudbase/lib/ldapjclnt19.jar" ]; then
    $JRE_HOME/bin/java -classpath $ORACLEPKI:$OSDT_CERT:$OSDT_CORE:$JRE_HOME/lib/rt.jar:$OJDBC8:$EUSMLIBDIR/eusm.jar:$EUSMLIBDIR/ldapjclnt$RDBMSVER.jar oracle.security.eus.util.ESMdriver "$@"
else
    echo "ERROR : Can not find $ORACLE_BASE/local/oudbase/lib/eusm.jar or $ORACLE_BASE/local/oudbase/lib/ldapjclnt19.jar"
    echo "        Make sure to copy this two java classes from an Oracle 19c installation"
    echo "        cp $ORACLE_HOME/rdbms/jlib/eusm.jar ."
    echo "        cp $ORACLE_HOME/jlib/ldapjclnt19.jar ."
fi


# - EOF ------------------------------------------------------------------------
