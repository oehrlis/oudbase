#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 01_create_eus_instance.sh
# Author.....: Patrick Joss (jpa) patrick.joss@trivadis.com
# Editor.....: Patrick Joss
# Date.......: 2020.12.16
# Revision...: --
# Purpose....: Script to create an empty weblogic domain 
#              with template Basic WebLogic Server Domain  
# Notes......: 
# Reference..: https://github.com/oehrlis/oudbase
# License....: Licensed under the Universal Permissive License v 1.0 as 
#              shown at https://oss.oracle.com/licenses/upl.
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------

sed -e '
s@###DOMAIN_NAME###@${DOMAIN_NAME}@g
s@###DOMAIN_HOME###@${DOMAIN_HOME}@g
s@###WLS_HOME###@${WLS_HOME}@g
s@###JDK_HOME###@${JDK_HOME}@g
s@###WLS_ADMIN###@${WLS_ADMIN}@g
s@###WLS_PASSWORD###@${WLS_PASSWORD}@g
s@###NM_PORT###@${NM_PORT}@g
s@###MACHINE_NAME###@${MACHINE_NAME}@g
s@###LISTEN_PORT###@${LISTEN_PORT}@g
' create_domain.py.template > /tmp/create_domain.py

${WLS_HOME}/oracle_common/common/bin/wlst.sh /tmp/create_domain.py

rm -f /tmp/create_domain.py





