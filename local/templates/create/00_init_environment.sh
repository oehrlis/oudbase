#!/bin/bash
# -----------------------------------------------------------------------
# Trivadis AG, Business Development & Support (BDS)
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# -----------------------------------------------------------------------
# Name.......: 00_init_environment.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2018.03.20
# Revision...: --
# Purpose....: Datei zum setzten der Instanz spezifischen Umgebung. 
#              Grundsaetzlich basieren die folgenden Script auf der OUD 
#              Base Umgebung. Ggf ist diese Datei anzupassen.
# Notes......:
# Reference..: https://github.com/oehrlis/oudbase
# License....: GPL-3.0+
# -----------------------------------------------------------------------
# Modified...:
# see git revision history with git log for more information on changes
# -----------------------------------------------------------------------
# - Default Environment Variables ---------------------------------------
# Diese sollte bereits durch OUD Base korrekt gesetzt sein daher an der 
# Stelle auskommentiert. Wichtig ist dabei, dass die entsprechende 
# Umgebung gesetzt ist. Wird OUD Base nicht verwendet, sind die folgenden
# Variablen explizit zu setzten.
# -----------------------------------------------------------------------
#export ORACLE_BASE="/opt/oracle"
#export ORACLE_HOME="${ORACLE_BASE}/product/oud12.2.1.3.0"
#export OUD_INSTANCE=ouddd
#export OUD_INSTANCE_ADMIN=${ORACLE_BASE}/admin/${OUD_INSTANCE}
#export OUD_INSTANCE_HOME="${ORACLE_BASE}/instances/${OUD_INSTANCE_NAME}"
#export PWD_FILE=${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_pwd.txt
#export PORT_ADMIN=4444
#export PORT=1389
#export PORT_SSL=1636
#export PORT_REP=8989
# - End of Default Environment Variables --------------------------------

# - Customization -------------------------------------------------------
export SOFTWARE=${ORACLE_BASE}/software/v12.2.1.3.0/
export SOFTWARE_JAVA=${SOFTWARE}/java/
export SOFTWARE_FMW=${SOFTWARE}/fmw/
export SOFTWARE_TVD=${SOFTWARE}/tvd/

# - Instance Information
export DIRMAN="cn=Directory Manager"
export REPMAN=admin
export BASEDN="BASEDN"

# - Certificates and password
export KEYSTOREFILE=${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}_jks
export KEYSTOREPIN=${OUD_INSTANCE_ADMIN}/etc/${OUD_INSTANCE}.pin
export NICKNAME="NICKNAME"
export PIN="PIN"

# - Hosts
export HOST=$(hostname 2>/dev/null ||echo $HOSTNAME)    # Hostname
export HOST1="HOST1"
export HOST2="HOST2"
export HOST3="HOST3"

# - End of Customization ------------------------------------------------
