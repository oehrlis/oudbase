#!/bin/bash
# ---------------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ---------------------------------------------------------------------------
# Name.......: oud_eusm.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2019.10.17
# Revision...: --
# Purpose....: Shell script for EUS admin tool (command line)
# Notes......: This script is mainly used for environment without TVD-Basenv
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

# - Default Values ------------------------------------------------------
VERSION=v1.7.0
JRE_HOME=$JAVA_HOME/jre/
EUSMLIBDIR=/u00/app/oracle/local/eusm/lib
ORACLEPKI=$ORACLE_HOME/oracle_common/modules/oracle.pki/oraclepki.jar
OSDT_CERT=$ORACLE_HOME/oracle_common/modules/oracle.osdt/osdt_cert.jar
OSDT_CORE=$ORACLE_HOME/oracle_common/modules/oracle.osdt/osdt_core.jar
OJDBC8=$ORACLE_HOME/oracle_common/modules/oracle.jdbc/ojdbc8.jar
RDBMSVER=19
# - End of Default Values -----------------------------------------------

$JRE_HOME/bin/java -classpath $ORACLEPKI:$OSDT_CERT:$OSDT_CORE:$JRE_HOME/lib/rt.jar:$OJDBC8:$EUSMLIBDIR/eusm.jar:$EUSMLIBDIR/ldapjclnt$RDBMSVER.jar oracle.security.eus.util.ESMdriver "$@"

# - EOF -----------------------------------------------------------------
