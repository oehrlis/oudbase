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
2017-11-13_14:28:58  INFO :   -i <ORACLE_INSTANCE_BASE>   Base directory for OUD instances (default $OUD_DATA/instances)
2017-11-13_14:28:58  INFO :   -m <ORACLE_HOME_BASE>       Base directory for OUD binaries (default $ORACLE_BASE/middleware)
2017-11-13_14:28:58  INFO :   -B <OUD_BACKUP_BASE>        Base directory for OUD backups (default $OUD_DATA/backup)
2017-11-13_14:28:58  INFO : 
2017-11-13_14:28:58  INFO : Logfile : /tmp/oudbase_install.log
```

Installation example to install **OUD base** in a OUD docker container in verbose mode. **-b** is used to specify the **ORACLE_BASE** directory where **-d** is used to specify */u01* (configured as docker volume) as **OUD_DATA** base folder to store instance data, configuration files etc. 

```bash
oracle@oud:~/ [oud_cdse] /u01/shared/oudbase_install.sh -v -b /u00/app/oracle -d /u01
2017-11-13_14:29:23  START: Start of oudbase_install.sh (Version 0.1) with -v -b /u00/app/oracle -d /u01
2017-11-13_14:29:23  INFO : processing commandline parameter
2017-11-13_14:29:23  Using the following variable for installation
2017-11-13_14:29:23  ORACLE_BASE          = /u00/app/oracle
2017-11-13_14:29:23  OUD_BASE             = /u00/app/oracle
2017-11-13_14:29:23  OUD_DATA             = /u01
2017-11-13_14:29:23  ORACLE_INSTANCE_BASE = /u01/instances
2017-11-13_14:29:23  ORACLE_HOME_BASE     = /u00/app/oracle/middleware
2017-11-13_14:29:23  OUD_BACKUP_BASE      = /u01/backup
2017-11-13_14:29:23  SCRIPT_FQN           = /u01/shared/oudbase_install.sh
2017-11-13_14:29:23  Installing OUD Environment
2017-11-13_14:29:23  Create required directories in ORACLE_BASE=/u00/app/oracle
2017-11-13_14:29:23  Create Directory /u01/etc
2017-11-13_14:29:23  Create Directory /u01/log
2017-11-13_14:29:23  Create Directory /u00/app/oracle/local
2017-11-13_14:29:23  Create Directory /u01/backup
2017-11-13_14:29:23  Create Directory /u01/instances
2017-11-13_14:29:23  Extracting file into /u00/app/oracle/local
bin/
bin/oud_backup.sh
bin/oud_export.sh
bin/oud_status.sh
bin/oudenv.sh
config/
certificates/
doc/
doc/README.md
etc/
etc/oud._DEFAULT_.conf
etc/oudenv.conf
etc/oudtab
lib/
log/
templates/
templates/.bash_profile
templates/cron.d/
templates/etc/
templates/ldif/
templates/logrotate.d/
templates/logrotate.d/oud
templates/ldif/oud_pi_init.ldif
templates/etc/install.rsp
templates/etc/oraInst.loc
templates/etc/oud_instance.service
templates/etc/wls_oudsm.service
templates/cron.d/oud
2017-11-13_14:29:23  Store customization for OUD_DATA (/u01)
2017-11-13_14:29:23  Store customization for ORACLE_BASE (/u00/app/oracle)
2017-11-13_14:29:23  Please manual adjust your .profile to load / source your OUD Environment
2017-11-13_14:29:23  END  : of oudbase_install.sh
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
| oudenv.conf         | This is the main configuration file for environment variables and aliases. It is loaded when an environment is set or changed. Location of oudenv.conf is $ETC_BASE. |
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

###Aliases

| Alias                     | Description                            |
| ------------------------- | -------------------------------------- |
| dsc                       | dsconfig including hostname, $PORT_ADMIN and $PWD_FILE |
| dsrs                      | dsreplication status |
| oud_pi                    | OUD Base does generate an alias for each OUD instance based on its name. This allows to easily change the environment from one to an other OUD instance. |
| oud INSTANCE              | Use oud INSTANCE name to change the environment to a particular OUD instance |
| taa                       | taa will do a tail -f on the OUD instance access log |
| tae                       | tae will do a tail -f on the OUD instance error log |
| tas                       | tas will do a tail -f on the OUD instance server.out log |
| tarep                     | tarep will do a tail -f on the OUD instance replication log |
| task                      | task does run a manage-tasks with hostname, port etc parameter |
| u                         | u runs oudup to display the current OUD Instances |
| vio                       | vio opens the oudtab file eg. ${ETC_BASE}/oudtab |

## Issues
Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/oehrlis/oudbase/issues)
* [submit new issue](https://github.com/oehrlis/oudbase/issues/new)

## License
OUDBase is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.

