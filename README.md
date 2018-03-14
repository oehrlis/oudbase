# OUD Base
Trivadis does have the TVD-BasEnv™ to standardizes and simplifies the handling of environments for Oracle database and application server landscapes. Although the current version of TVD-BasEnv™ already support OUD and OID environments, there are sometimes situations, where you need a small and slimed down environment scripts for dedicated OUD servers. TVD-BasEnv™ is rather complex and brings a lot of nice features for Oracle Database environments with ASM, RAC, DataGuard and more stuff which is in general not required on a simple OUD server.

*OUD Base* is basically just the **oudenv.sh** script, some configuration files and a bunch of aliases. The directory structure for the OUD binaries, scripts and configuration files is similar to what is use in TVD-BasEnv™ and based on OFA. It is written in bash and tested on Oracle Linux VM’s, OUD Docker container and Raspberry Pi’s with Raspbian Jessy/Stretch. It should also run on any other bash environment.

## Setup
*OUD Base* is available as TAR file or as Bash installation file *oudbase_install.sh*. Wherein *oudbase_install.sh* is a TAR file with a wrappped Bash script.

```bash
oracle@oud:~/ [oud_cdse] /u01/shared/oudbase_install.sh -h
2017-11-13_14:28:58  START: Start of oudbase_install.sh (Version 0.1) with -h
2017-11-13_14:28:58  INFO : processing commandline parameter
2017-11-13_14:28:58  INFO : Usage, oudbase_install.sh [-hv] [-b <ORACLE_BASE>] 
2017-11-13_14:28:58  INFO :   [-i <ORACLE_INSTANCE_BASE>] [-m <ORACLE_HOME_BASE>] [-B <OUD_BACKUP_BASE>]
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
oracle@oudeng:/u00/app/oracle/ [oud_docker] /u01/scripts/oudbase_install.sh -v -b /u00/app/oracle -o /u00/app/oracle -d /u01
2018-02-16_10:54:05  START: Start of oudbase_install.sh (Version 1.0.0) with -v -b /u00/app/oracle -o /u00/app/oracle -d /u01
2018-02-16_10:54:05  INFO : processing commandline parameter
2018-02-16_10:54:05  INFO : Define default values
2018-02-16_10:54:05  INFO : Using the following variable for installation
2018-02-16_10:54:05  INFO : ORACLE_BASE          = /u00/app/oracle
2018-02-16_10:54:05  INFO : OUD_BASE             = /u00/app/oracle
2018-02-16_10:54:05  INFO : LOG_BASE             = /u01/log
2018-02-16_10:54:05  INFO : ETC_CORE             = /u00/app/oracle/local/etc
2018-02-16_10:54:05  INFO : ETC_BASE             = /u01/etc
2018-02-16_10:54:05  INFO : OUD_DATA             = /u01
2018-02-16_10:54:05  INFO : OUD_INSTANCE_BASE    = /u01/instances
2018-02-16_10:54:05  INFO : OUD_ADMIN_BASE       = /u01/admin
2018-02-16_10:54:05  INFO : OUD_BACKUP_BASE      = /u01/backup
2018-02-16_10:54:05  INFO : ORACLE_PRODUCT       = /u00/app/oracle/product
2018-02-16_10:54:05  INFO : ORACLE_HOME          = /u00/app/oracle/product/fmw12.2.1.3.0
2018-02-16_10:54:05  INFO : ORACLE_FMW_HOME      = /u00/app/oracle/product/fmw12.2.1.3.0
2018-02-16_10:54:05  INFO : JAVA_HOME            = /usr/java/jdk1.8.0_162
2018-02-16_10:54:05  INFO : SCRIPT_FQN           = /u01/scripts/oudbase_install.sh
2018-02-16_10:54:05  INFO : Installing OUD Environment
2018-02-16_10:54:05  INFO : Create required directories in ORACLE_BASE=/u00/app/oracle
2018-02-16_10:54:05  INFO : Create Directory /u01/log
2018-02-16_10:54:05  INFO : Create Directory /u01/etc
2018-02-16_10:54:05  INFO : Create Directory /u00/app/oracle/local
2018-02-16_10:54:05  INFO : Create Directory /u01/admin
2018-02-16_10:54:05  INFO : Create Directory /u01/backup
2018-02-16_10:54:05  INFO : Create Directory /u01/instances
2018-02-16_10:54:05  INFO : Create Directory /u00/app/oracle/product
2018-02-16_10:54:05  INFO : Backup existing config files
2018-02-16_10:54:05  INFO : Backup oudtab to oudtab.save
2018-02-16_10:54:05  INFO : Backup oudenv.conf to oudenv.conf.save
2018-02-16_10:54:05  INFO : Backup oud._DEFAULT_.conf to oud._DEFAULT_.conf.save
2018-02-16_10:54:05  INFO : Extracting file into /u00/app/oracle/local
bin/
bin/oud_status.sh
bin/oud_export.sh
bin/oud_backup.sh
bin/oudenv.sh
config/
certificates/
doc/
doc/README.md
etc/
etc/oudenv_core.conf
etc/oudenv.conf
etc/oudenv_custom.conf
etc/oudtab
etc/oud._DEFAULT_.conf
lib/
log/
templates/
templates/ldif/
templates/etc/
templates/cron.d/
templates/.bash_profile
templates/logrotate.d/
templates/create/
templates/create/create_OUDSM.py
templates/logrotate.d/oud
templates/cron.d/oud
templates/etc/wls_oudsm.service
templates/etc/install.rsp
templates/etc/oraInst.loc
templates/etc/oud_instance.service
templates/ldif/oud_pi_init.ldif
2018-02-16_10:54:05  INFO : Restore cusomized config files
2018-02-16_10:54:05  INFO : Store customization in core config file /u00/app/oracle/local/etc/oudenv_core.conf
2018-02-16_10:54:05  INFO : save customization for OUD_DATA (/u01)
2018-02-16_10:54:05  INFO : save customization for OUD_BASE (/u00/app/oracle)
2018-02-16_10:54:05  INFO : save customization for ORACLE_BASE (/u00/app/oracle)
2018-02-16_10:54:05  INFO : Please manual adjust your .bash_profile to load / source your OUD Environment
2018-02-16_10:54:05  INFO : using the following code
# Check OUD_BASE and load if necessary
if [ "${OUD_BASE}" = "" ]; then
  if [ -f "${HOME}/.OUD_BASE" ]; then
    . "${HOME}/.OUD_BASE"
  else
    echo "ERROR: Could not load ${HOME}/.OUD_BASE"
  fi
fi

# define an oudenv alias
alias oud=". ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh"

# source oud environment
. ${OUD_BASE}/${DEFAULT_OUD_LOCAL_BASE_NAME}/bin/oudenv.sh
2018-02-16_10:54:05  INFO : Could not update your .OUD_BASE file /home/oracle/.OUD_BASE
2018-02-16_10:54:05  INFO : make sure to add the right OUD_BASE directory
2018-02-16_10:54:05  END  : of oudbase_install.sh
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
alias oud=". $(find $OUD_BASE -name oudenv.sh)"

# source oud environment
. $(find $OUD_BASE -name oudenv.sh)
```

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
| ------------------------- | -------------------------------------- |
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

## Issues
Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/oehrlis/oudbase/issues)
* [submit new issue](https://github.com/oehrlis/oudbase/issues/new)

## License
OUDBase is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.

