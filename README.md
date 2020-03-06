# OUD Base
Trivadis does have the TVD-BasEnv™ to standardizes and simplifies the handling of environments for Oracle database and application server landscapes. Although the current version of TVD-BasEnv™ already support OUD and OID environments, there are sometimes situations, where you need a small and slimed down environment scripts for dedicated OUD servers. TVD-BasEnv™ is rather complex and brings a lot of nice features for Oracle Database environments with ASM, RAC, DataGuard and more stuff which is in general not required on a simple OUD server.

*OUD Base* is basically just the **oudenv.sh** script, some configuration files and a bunch of aliases. The directory structure for the OUD binaries, scripts and configuration files is similar to what is use in TVD-BasEnv™ and based on OFA. It is written in bash and tested on Oracle Linux VM’s, OUD Docker container and Raspberry Pi’s with Raspbian Jessy/Stretch. It should also run on any other bash environment.

## Setup

Latest installation script or TAR file is available on the [releases](https://github.com/oehrlis/oudbase/releases) page.

### Automatic Setup using shell script
*OUD Base* is available as TAR file or as Bash installation file *oudbase_install.sh*. Wherein *oudbase_install.sh* is a TAR file with a wrappped Bash script.

```bash
oracle@oud:~/ [oud_cdse] /u01/shared/oudbase_install.sh -h
2017-11-13_14:28:58  START: Start of oudbase_install.sh (Version 0.1) with -h
2017-11-13_14:28:58  INFO : processing commandline parameter
2017-11-13_14:28:58  INFO : Usage, oudbase_install.sh [-hv] [-b <ORACLE_BASE>] 
2017-11-13_14:28:58  INFO :   [-i <O⁄RACLE_INSTANCE_BASE>] [-m <ORACLE_HOME_BASE>] [-B <OUD_BACKUP_BASE>]
2017-11-13_14:28:58  INFO : 
2017-11-13_14:28:58  INFO :   -h                          Usage (this message)
2017-11-13_14:28:58  INFO :   -v                          enable verbose mode
2017-11-13_14:28:58  INFO :   -b <ORACLE_BASE>            ORACLE_BASE Directory. Mandatory argument. This 
2017-11-13_14:28:58  INFO                                 directory is use as OUD_BASE directory
2017-11-13_14:28:58  INFO :   -o <OUD_BASE>               OUD_BASE Directory. (default $OUD_BASE).
2017-11-13_14:28:58  INFO :   -d <OUD_DATA>               OUD_DATA Directory. (default $ORACLE_BASE). This directory has to be 
2017-11-13_14:28:58  INFO                                 specified to distinct persistant data from software eg. in a docker containers
2017-11-13_14:28:58  INFO :   -A <OUD_ADMIN_BASE>         Base directory for OUD admin (default $OUD_DATA/admin)"
2017-11-13_14:28:58  INFO :   -B <OUD_BACKUP_BASE>        Base directory for OUD backups (default $OUD_DATA/backup)"
2017-11-13_14:28:58  INFO :   -i <OUD_INSTANCE_BASE>      Base directory for OUD instances (default $OUD_DATA/instances)
2017-11-13_14:28:58  INFO :   -m <ORACLE_HOME_BASE>       Base directory for OUD binaries (default $ORACLE_BASE/middleware)
2017-11-13_14:28:58  INFO :   -B <OUD_BACKUP_BASE>        Base directory for OUD backups (default $OUD_DATA/backup)
2017-11-13_14:28:58  INFO : 
2017-11-13_14:28:58  INFO : Logfile : /tmp/oudbase_install.log
```

Installation example to install **OUD base** in a OUD docker container in verbose mode. **-b** is used to specify the **ORACLE_BASE** directory where **-d** is used to specify */u01* (configured as docker volume) as **OUD_DATA** base folder to store instance data, configuration files etc. 

```bash
oracle@eusoud:/u01/config/ [oud_eus] ./oudbase_install.sh -v -b /u00/app/oracle -o /u00/app/oracle -d /u01
2020-03-02_21:55:12  START: Start of oudbase_install.sh (Version v1.7.5) with -v -b /u00/app/oracle -o /u00/app/oracle -d /u01
2020-03-02_21:55:12  INFO : processing commandline parameter
2020-03-02_21:55:12  INFO : Define default values
2020-03-02_21:55:13  INFO : Using the following variable for installation
2020-03-02_21:55:13  INFO : ORACLE_BASE          = /u00/app/oracle
2020-03-02_21:55:13  INFO : OUD_BASE             = /u00/app/oracle
2020-03-02_21:55:13  INFO : LOG_BASE             = /u01/log
2020-03-02_21:55:13  INFO : ETC_CORE             = /u00/app/oracle/etc
2020-03-02_21:55:13  INFO : ETC_BASE             = /u01/etc
2020-03-02_21:55:13  INFO : OUD_DATA             = /u01
2020-03-02_21:55:13  INFO : ORACLE_DATA          = /u01
2020-03-02_21:55:13  INFO : OUD_INSTANCE_BASE    = /u01/instances
2020-03-02_21:55:13  INFO : OUD_ADMIN_BASE       = /u01/admin
2020-03-02_21:55:13  INFO : OUD_BACKUP_BASE      = /u01/backup
2020-03-02_21:55:13  INFO : ORACLE_PRODUCT       = /u00/app/oracle/product
2020-03-02_21:55:13  INFO : ORACLE_HOME          = /u00/app/oracle/product/fmw12.2.1.4.0
2020-03-02_21:55:13  INFO : ORACLE_FMW_HOME      = /u00/app/oracle/product/fmw12.2.1.3.0
2020-03-02_21:55:13  INFO : JAVA_HOME            = /usr/java/jdk1.8.0_241
2020-03-02_21:55:13  INFO : SCRIPT_FQN           = /u01/config/oudbase_install.sh
2020-03-02_21:55:13  INFO : Installing OUD Environment
2020-03-02_21:55:13  INFO : Create required directories in ORACLE_BASE=/u00/app/oracle
2020-03-02_21:55:13  INFO : Create Directory /u01/log
2020-03-02_21:55:13  INFO : Create Directory /u01/etc
2020-03-02_21:55:13  INFO : Create Directory /u00/app/oracle/local
2020-03-02_21:55:13  INFO : Create Directory /u01/admin
2020-03-02_21:55:13  INFO : Create Directory /u01/backup
2020-03-02_21:55:13  INFO : Create Directory /u01/instances
2020-03-02_21:55:13  INFO : Create Directory /u00/app/oracle/product
2020-03-02_21:55:13  INFO : Create Directory /u00/app/oracle
2020-03-02_21:55:13  INFO : Backup existing config files
2020-03-02_21:55:13  INFO : Backup oudtab to oudtab.save
2020-03-02_21:55:13  INFO : Backup oud._DEFAULT_.conf to oud._DEFAULT_.conf.save
2020-03-02_21:55:13  INFO : Start processing the payload
2020-03-02_21:55:13  INFO : Payload is available as of line 487.
2020-03-02_21:55:13  INFO : Extracting payload into /u00/app/oracle/local
2020-03-02_21:55:13  INFO : Payload is set to base64. Using base64 decode before untar.
bin/
bin/oud_status.sh
bin/oud_start_stop.sh
bin/oud_start_stop_all
bin/oud_export.sh
bin/oud_backup.sh
bin/oudenv.sh
bin/oud_eusm.sh
doc/
doc/LICENSE
doc/README.md
doc/.version
doc/.oudbase.sha
etc/
etc/oudenv_core.conf
etc/oudenv.conf
etc/oudenv_custom.conf
etc/oudtab
etc/oud._DEFAULT_.conf
log/
lib/
templates/
templates/etc/
templates/cron.d/
templates/.bash_profile
templates/logrotate.d/
templates/create/
...
2020-03-02_21:55:14  INFO : Restore cusomized config files
2020-03-02_21:55:14  INFO : Store customization in core config file /u00/app/oracle/etc/oudenv_core.conf
2020-03-02_21:55:14  INFO : save customization for OUD_DATA (/u01)
2020-03-02_21:55:14  INFO : save customization for OUD_BASE (/u00/app/oracle)
2020-03-02_21:55:14  INFO : save customization for ORACLE_BASE (/u00/app/oracle)
2020-03-02_21:55:14  INFO : Please manual adjust your .bash_profile to load / source your OUD Environment
2020-03-02_21:55:14  INFO : using the following code
# Check OUD_BASE and load if necessary
if [ "${OUD_BASE}" = "" ]; then
  if [ -f "${HOME}/.OUD_BASE" ]; then
    . "${HOME}/.OUD_BASE"
  else
    echo "ERROR: Could not load ${HOME}/.OUD_BASE"
  fi
fi

# define an oudenv alias
alias oudenv='. ${OUD_BASE}/bin/oudenv.sh'

# source oud environment
if [ -z "" ]; then
    . ${OUD_BASE}/bin/oudenv.sh SILENT
else
    . ${OUD_BASE}/bin/oudenv.sh
fi
2020-03-02_21:55:14  INFO : update your .OUD_BASE file /home/oracle/.OUD_BASE
2020-03-02_21:55:14  END  : of oudbase_install.sh
```

The only manual step after installing *OUD Base* is to adjust the *.bash_profile / .profile script*. Just source the corresponding script as described in *$OUD_BASE/local/templates/.bash_profile*. 

```bash
# Check OUD_BASE and load if necessary
if [ "${OUD_BASE}" = "" ]
  then
    if [ -f "${HOME}/.OUD_BASE" ]
      then
        . "${HOME}/.OUD_BASE"
      else
        echo "ERROR: Could not load ${HOME}/.OUD_BASE"
    fi
fi

# define an oudenv alias
alias oudenv=". $(find $OUD_BASE -name oudenv.sh)"

# source oud environment
. $(find $OUD_BASE -name oudenv.sh)
```

### Manual setup TAR file

Extract the TAR to your favorite folder.

```
tar -zxcd oudbase_install.tgz -C $ORACLE_BASE/local
```

Update the oudenv_core.conf and add some mandatory parameter eg. ORACLE_BASE, OUD_BASE, OUD_DATA, OUD_INSTANCE_BASE, OUD_BACKUP_BASE, ORACLE_HOME, ORACLE_FMW_HOME, JAVA_HOME, LOG_BASE or ETC_BASE. Where ORACLE_BASE is the minimal required parameter.

```
echo "ORACLE_BASE=$ORACLE_BASE" >> $ORACLE_BASE/local/etc/oudenv_core.conf
```

Add a .OUD_BASE file to the user home

```
echo echo "OUD_BASE=$OUD_BASE" >> $HOME/.OUD_BASE
```

Update .profile or .bash_profile to source the OUD environment

```
PROFILE=$HOME/.bash_profile
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
echo "alias oudenv='. \${OUD_BASE}/bin/oudenv.sh'"                  >>"${PROFILE}"
echo ""                                                             >>"${PROFILE}"
echo "# source oud environment"                                     >>"${PROFILE}"
echo ". \${OUD_BASE}/bin/oudenv.sh"                                 >>"${PROFILE}"
```

Open a new terminal to test OUDBase.

## Configuration and Architecture

By default **oudbase** does work from its base folder **OUD_BASE** which is usually the same as **ORACLE_BASE**. In certain cases it make sense to separate persistent data like configuration files, log files and OUD instances. If OUD does run in a docker container it's crucial, that you OUD instance is on a separate volume. Otherwise the instance will not survive. **OUD_DATA** variable allows to specify an alternative base directory for  persistent data like OUD instance home, backups, exports as well configuration and log files. 

### Config Files
The OUD Base does have the following configuration files.

| File                | Description    |
| ------------------- |----------------|
| .OUD_BASE           | This is a simple file in the user home directory. It includes the pointer to the OUD Base directory. This file is used to initiate $OUD_BASE. |
| oudtab              | oudtab is a simple file which includes all OUD instance and there ports eg. default LDAP port, admin port, SSL port and replication port.      |
| oudenv_core.conf         | This is the configuration file is customized by the setup script with values specified during installation. It is loaded when an environment is set or changed. Location of oudenv_core.conf is $ETC_CORE respectively $OUD_BASE/local/etc |
| oudenv.conf         | This is the main configuration file for environment variables and aliases. It is loaded when an environment is set or changed. Location of oudenv.conf is $ETC_BASE. |
| oudenv_custom.conf  | This is the custom configuration file for environment variables and aliases. It is loaded after oudenv.conf when an environment is set or changed. Location of oudenv_custom.conf is $ETC_BASE. Every alias will be shown in oud_help (h) with the alias name and the comment as help text |
| oud._DEFAULT_.conf  | This configuration file for custom environment variables. Location of oud._DEFAULT_.conf is $ETC_BASE. |
| oud._INSTANCE_.conf | This configuration file for custom environment variables for a dedicated OUD instance eg. oud_pi Location of oud._oud_pi_.conf is $ETC_BASE.|

### Directories and its variables

The following directory, environment variables and aliases are defined and used in OUD Base. Most of them are inspired by OFA (Oracle Flexible Architecture) and TVD-BasEnv™.

| ENV Variable              | Alias        | Path                               | Description                            |
| ------------------------- |------------- | ---------------------------------- | -------------------------------------- |
| $ORACLE_BASE, $cdob       | cdob         | /u00/app/oracle                    | Base directory for the oracle binaries |
| $OUD_BASE                 | n/a          | /u00/app/oracle                    | Base directory for the OUD binaries. Usually this defaults to $ORACLE_BASE.|
| $OUD_DATA                 | cdob         | /u01, /u00/app/oracle              | Base directory for the OUD data. It is used to have OUD instances, config files, log files etc on a separate folder or mount point. In particular if OUD is used in a docker container. This allows to have the persistant data on a volume. It defaults to $OUD_BASE |
| $OUD_LOCAL, $cdl          | cdl          | $OUD_BASE/local                    | OUD Base directory with the scripts, config etc |
|                           | cdl.bin      | $OUD_LOCAL/bin                     | Scripts directory in OUD_BASE |
| $ETC_CORE                 | n/a          | $OUD_LOCAL/etc                     | OUD core configuration directory $ETC_CORE is equal to $ETC_BASE for regular installations. |
| $ETC_BASE, $etc           | etc, cdl.etc | $OUD_DATA/etc                      | OUD Base configuration directory |
| $LOG_BASE, $log           | log, cdl.log | $OUD_DATA/log                      | OUD Base log directory |
|                           | n/a          | $OUD_DATA/doc                      | OUD Base documentation directory |
|                           | n/a          | $OUD_DATA/config                   | Local directory for configuration files, LDIF etc to build an OUD instance |
|                           | n/a          | $OUD_DATA/certificates             | Local directory for certificates |
| $ORACLE_HOME, $cdh        | cdh          | $ORACLE_BASE/product/fmw12.2.1.3.0 | Oracle Unified Directory binaries eg. 11.1.2.3 |
| $JAVA_HOME                | n/a          | /usr/java/jdk1.8.0_144             | Java used for OUD |
| $OUD_INSTANCE_BASE, $cdib | cdib         | $OUD_DATA/instances                | Base directory for the instance homes |
| $OUD_BACKUP_BASE          | n/a          | $OUD_DATA/backup                   | Base directory for the OUD backups and exports|
| $DOMAIN_HOME              | n/a          | $OUD_DATA/domains                  | Base directory for the OUD backups and exports|
|                           | oud_pi       |                                    | Alias to set environment for OUD instance oud_pi |
| $OUD_INSTANCE_HOME, $cdih | cdih         | $OUD_DATA/instances/oud_pi         | OUD Instance Home directory for Instance oud_pi |
| $cdic                     | cdic         | $OUD_INSTANCE_HOME/OUD/config      | Config directory for OUD instance oud_pi |
| $cdil                     | cdil         | $OUD_INSTANCE_HOME/OUD/logs        | Log directory for OUD instance oud_pi |

### Variables

Variable besides the ones mentioned above.

| Variable                  | Description                            |
| ------------------------- | -------------------------------------- |
| $OUD_INSTANCE             | Name of the current OUD instance |
| $OUD_INST_LIST            | List of OUD instances taken from $OUDTAB |
| $PWD_FILE                 | Password file for the OUD instance eg. ${ETC_BASE}/$OUD_INSTANCE_pwd.txt or ${ETC_BASE}/pwd.txt |
| $PORT                     | OUD instance port taken from oudtab file |
| $PORT_ADMIN               | OUD instance admin port taken from oudtab file |
| $PORT_REP                 | OUD instance replication port taken from oudtab file |
| $PORT_SSL                 | OUD instance SSL port taken from oudtab file |
| $OUDTAB                   | oudtab config file eg. ${ETC_BASE}/oudtab |

### Aliases

| Alias                     | Description                            |
| ------------------------- | -------------------------------------- |
| backup_changed            | Create a TAR file of the changed/added files in $ORACLE_BASE/local. The TAR file will be stored in $OUD_BACKUP_BASE |
| dsc                       | dsconfig including hostname, $PORT_ADMIN and $PWD_FILE |
| dsrs                      | dsreplication status |
| oud_pi                    | OUD Base does generate an alias for each OUD instance based on its name. This allows to easily change the environment from one to an other OUD instance. |
| oud <INSTANCE>            | Use oud INSTANCE name to change the environment to a particular OUD instance |
| taa                       | taa will do a tail -f on the OUD instance access log |
| tae                       | tae will do a tail -f on the OUD instance error log |
| tas                       | tas will do a tail -f on the OUD instance server.out log |
| tarep                     | tarep will do a tail -f on the OUD instance replication log |
| task                      | task does run a manage-tasks with hostname, port etc parameter |
| u                         | u runs oudup to display the current OUD Instances |
| vio                       | vio opens the oudtab file eg. ${ETC_BASE}/oudtab |
| version                   | Display version of OUD base and list changed files in $OUD_LOCAL|

### Functions

| Function                  | Alias   | Description                  |
| ------------------------- | --------|----------------------------- |
| gen_password <LENGTH>     | gen_pwd | Generate a password string. The password is 10 characters long and contains number as well as upper and lower case characters. The length of the password can be changed by specify a parameter eg. ```gen_password 8``` for an 8 character password |
| get_oracle_home           | goh     | Get the corresponding ORACLE_HOME from OUD Instance. |
| get_ports                 | gp      | Get the corresponding PORTS from OUD Instance. |
| get_status                | n/a     | Get the process status of the current OUD instance or OUDSM domain. Internally used to get the *UP* or *DOWN*.|
| join_by                   | n/a     | Internally used to join array elements. |
| oud_help                  | h       | Display a short help for important variable and aliases. If custom aliases has been specified in oudenv_custom.conf the will be shown as well. The alias name will be displayed by side a help text. The help text is taken from the line comment of the alias command if available otherwise oud_help will just display n/a |
| oud_status                | os      | Display the current OUD or OUDSM status with instance name, instance home, ports etc.|
| oud_up                    | u, ou   | Display up/down status of all OUD instances and OUDSM domains. |
| relpath <DIR1> <DIR2>     | n/a     | Internally used to get the relative path of DIR1 from DIR2 |
| update_oudtab             | n/a     | Update OUD tab (${ETC_BASE}/oudtab) for the current OUD instance. Adjust Ports or add the instance to the OUD tab. |

### Usage and Use Cases

Display status of the current OUD instance.

```
oud@oudeng:~/ [oudtd] os
--------------------------------------------------------------
 Instance Name      : oud_docker
 Instance Home (ok) : /u01/instances/oud_docker
 Oracle Home        : /u00/app/oracle/product/oud12.2.1.3.0
 Instance Status    : up
 LDAP Port          : 1389
 LDAPS Port         : 1636
 Admin Port         : 4444
 Replication Port   : 8989
--------------------------------------------------------------
```

Show runing OUD and OUDSM instances

```
oud@uxltoud03:~/ [oudtd] u
TYPE  INSTANCE     STATUS PORTS          INSTANCE HOME
----- ------------ ------ -------------- ----------------------------------
OUD   oud_docker   up     1389/1636/4444 /u01/instances/oud_docker
OUD   oud_test     up     2389/2636/5444 /u01/instances/oudtest
OUDSM oudsm_domain up     7001/7002      /u01/domains/oudsm_domain
```

## Issues
Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/oehrlis/oudbase/issues)
* [submit new issue](https://github.com/oehrlis/oudbase/issues/new)

## License
oehrlis/docker is licensed under the GNU General Public License v3.0. You may obtain a copy of the License at <https://www.gnu.org/licenses/gpl.html>.
