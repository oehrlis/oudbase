# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Latest releases are always available via [releases].

## [Unreleased] -

### Added

### Changed

### Fixed

## [3.4.8] - 2023.05.04

### Fixed

- update installation script to update *oudenv.conf* with *oudenv.conf.new* if
  just the comment is different. If the file itself differs a info message during
  installation inform about additional manual steps. e.g. use diff to check the file.

## [3.4.7] - 2023.05.04

### Fixed

- Repair broken build / package issue with *base64* encoding
- change encoding to OpenSSL based e.g. `openssl base64`

## [3.4.6] - 2023.05.03

### Changed

- Update default Patch IDs to Oracle April Critical Patch Advisory
  
## [3.4.5] - 2023.04.03

### Fixed

- Fix issue with undefined variable in *oudenv.sh* and wrong order
- change mode of *test_scripts.sh* to 755

## [3.4.4] - 2023.04.03

### Fixed

- Fix issue with undefined variable in *oudenv.sh*
- Handle error when *oud_backup.sh* is executed on a system without OUD instance,
  e.g. when no instances are defined / found.
- Handle error when *oud_export.sh* is executed on a system without OUD instance,
  e.g. when no instances are defined / found.

## [3.4.3] - 2023.03.31

### Fixed

- Issue with *nounset* either disable it or catch return values
- Fix issue with chsum file for tvdldap.tgz

## [3.4.2] - 2023.03.31

### Changed

- update build to generate a tvdldap.tgz file

### Fixed

- Issue with *errexit* either disable it or catch return values

## [3.4.1] - 2023.03.30

### Fixed

- Issue with *errexit* either disable it or catch return values

## [3.4.0] - 2023.03.30

### Added

- add a first draft version of tool test scripts *test_script.sh* and *test_unit.sh*
  These files are currently beta and not yet stable.

### Changed

- Update a few doc's and comments

### Fixed

- fix issues when run tools in a clean environment. Add default values
- fix adhoc source of environment
- fix issue related with nounset, errexit and pipefail

## [3.3.3] - 2023.03.29

### Fixed

- Fix a few issues in *52_remove_unavailable.sh*

## [3.3.2] - 2023.03.29

### Fixed

- Fix issue with wrong / missing *ORACLE_SID* on OUD environments

## [3.3.1] - 2023.03.29

### Added

- add initialize all replication script *30_initialize_all.sh*

### Fixed

- fix issue where check of existing net service names does not work. Add bind
  parameter to function *net_service_exists* and fix scripts *tns_modify.sh*,
  *tns_add.sh* and *tns_load.sh*. If available they now check existing
  net service names with the corresponding bind values.
- Remove *ORACLE_SID* in *tns_dump.sh*

## [3.3.0] - 2023.03.29

### Added

- add check to *tns_delete.sh* to check if dump file does exists. If yes the PID
  will be added to the file name.
- add scripts to remove host from replication completely.
- Add *advanced* flag to replication check script
- Add a script to verify replication status

### Changed

- Change alias *dsrs* add the *advanced* option
- Clean up checks for variables as well output for the replication scripts
- minor code update for comments and redundancy

### Fixed

- *tns_functions.sh* was not able to load *BasEnv*. Disable nounset, errexit and
  pipefail before source *BasEnv*
- add default value for *TNS_ADMIN*

## [3.2.0] - 2023.03.28

### Added

- Add configuration variable *TVDLDAP_DEFAULT_DUMP_OUTPUT_DIR* to define default output directory

## [3.1.0] - 2023.03.28

### Added

- Add configuration variable to define dump prefix *TVDLDAP_DUMP_FILE_PREFIX*
- Add parameter to force one dump file instead of one per suffix *-O* and *TVDLDAP_ONE_DUMP_FILE*

## [3.0.4] - 2023.03.28

### Fixed

- fix variable and file check in templates

## [3.0.3] - 2023.03.28

### Fixed

- fix wrong check of password file in oudbase

## [3.0.2] - 2023.03.28

### Fixed

- Remove unused files from release accidentally created during build

## [3.0.1] - 2023.03.28

### Fixed

- fix minor bug in *source_env*

## [3.0.0] - 2023.03.28

### Added

- add *set -o noglob* to tns tools
- Implement issue #83 *trap / signal handline*
- Implement issue #85 *Improve bash script stability*

### Changed

- Fix file header doc for crontab templates

### Fixed

- Fix bug issue #133 in *gen_password*.
- Implement bug fix for issue #106 *Do not create GROUP_OU and USER_OU*
- Implement bug fix for issue #130 *tns_dump.sh can not be executed in crontab without shell*

## [2.12.7] - 2023.03.06

### Changed

- limit dump of TNS entries to bulk mode in *tns_delete*

### Fixed

- fix issue with undefined variable in *echo_secretes*

## [2.12.6] - 2023.03.06

### Added

- add *echo_secrets* to mask secret variables in debug mode

### Changed

- update header of *oud_instance.service* change order of documentation
- update debug messages to use *echo_secrets*
- update debug messages to use STDERR rather than STDOUT

### Fixed

- Fix issue #125
- Fix issue #126

## [2.12.5] - 2023.03.02

### Fixed

- Fix layout of status output for *tns_dump.sh*, *tns_load.sh* add *tns_test.sh*
- Fix wrong setting of variable for processed BaseDN.
- Fix line breaks in status output for BaseDN
- Fix count of Dumped TNS entries

## [2.12.4] - 2023.03.02

### Added

- *tns_dump.sh* add process status information
- *tns_load.sh* add process status information
- *tns_test.sh* add process status information

## [2.12.3] - 2023.03.02

### Added

- add new function *tidy_dotora* to format the net service connect sting. The function
  is based on [Ludovico Caldara](https://www.ludovicocaldara.net/dba/tidy_dotora/)
  and [Jeremy Scheider](https://ardentperf.com/2008/11/28/parsing-listenerora-with-awk-and-sed/)
  work.
- add new function *join_dotora* to join service connect sting into one line
- add new value *TVDLDAP_DUMP_FORMAT* in config template
- add new parameter *-s FORMAT* to *tns_dump.sh*. This parameter allows to configure
  the output format of the net service connect string. It is either *SINGLE* for
  all in one line or *INDENTED* for a multiline net service connect string. Default
  format is *SINGLE*.

### Changed

- enhance error correction in *tns_functions.sh* for *ldapsearch*

### Fixed

- Fix issue in *tns_load.sh* not able to load *tnsnames.ora* from *tns_dump.sh*.
  Net service name files are now joined and cleaned up using *join_dotora*

## [2.12.2] - 2023.02.28

### Fixed

- issue in *tns_dump.sh* query results for *cn* and *NetDescString* have been
  mixed up.

## [2.12.1] - 2023.02.28

### Fixed

- issue in *tns_search.sh* and *tns_test.sh* query results for *cn* and *NetDescString*
  have been mixed up.

## [2.12.0] - 2023.02.28

### Added

- add *dry run* mode for *tns_dump.sh*
- add bulk delete function to *tns_delete.sh*. This allows to delete tns entries
  based on wildcard search.
- add auto dump for bulk deletes in *tns_delete.sh*. Every bulk delete will explicitly
  create a dump in $LOG_BASE.

### Changed

- update exit errors in *tns_functions.sh*
- update status and error output in *tns_delete.sh*

### Fixed

- fix variable check in *tns_search.sh*

## [2.11.0] - 2023-02-23

### Added

- add function *bulk_enabled* to verify if bulk mode is enabled
- add function *get_list_of_config* to create a list of possible
  configuration files based on current environment variables.

### Changed

- update layout for debug information in scripts
- passwords are now automatically generated using *pwgen* if available otherwise
  it will fallback to */dev/urandom*. Default length for autogenerated passwords
  is now set to 15 characters.
- Remove Trivadis company info and e-mails

### Fixed

- Fix issue #112 *Debug mode does not dump env variables*
- Fix issue #113 *Config files are loaded multiple times*
- Fix issue #114 *Correct order for config files*
- Fix bug #122 and remove all legacy default passwords.

## [2.10.0] - 2023-02-21

### Changed

- update latest patch information in [setup_oud.sh](local/oudbase/bin/setup_oud.sh)
- update latest patch information in [setup_oud_patch.sh](local/oudbase/bin/setup_oud_patch.sh)
- update documentation for [oud_instance.service](local/oudbase/templates/etc/oud_instance.service)

## [2.9.2] - 2023-02-20

### Fixed

- Fix bug #110
- Fix bug #111

## [2.9.1] - 2022-11-07

### Fixed

- define a default value for *TNS_ADMIN*. For *tns_function.sh* it is *TVDLDAP_ETC_DIR*
  where for *tns_dump.sh* and *tns_load.sh* it is the current folder.

## [2.9.0] - 2022-11-07

### Changed

- update latest patch information in [setup_oud.sh](local/oudbase/bin/setup_oud.sh)
- update latest patch information in [setup_oud_patch.sh](local/oudbase/bin/setup_oud_patch.sh)
- move variable *OPENDS_JAVA_ARGS* to *oudenv_custom.conf* template

### Fixed

- add *MybindDN* as parameter to *export-ldif* in *oud_export.sh*.

## [2.8.0] - 2022-10-24

### Added

- add check for installed components and features in *setup_oud_patch.sh*

### Changed

### Fixed

## [2.7.1] - 2022-09-03

### Added

- add *oud.crontab* back to *etc* due to dependency in deployments

### Changed

- add alias *dsrs* to *oudbase* help

## [2.7.0] - 2022-08-30

### Added

- Add parameter "-S" for local and *-R* for remote software repository. See issue #96

### Changed

- Clean up default package names and variables
- *oudenv.sh* parameter is now checked for valid characters e.g. alphanumeric
  plus - and _
- Build now updates version as well date values in file headers.

### Fixed

- fix bug in *get_software*
- fix bug not removing temp directories when exit with error
- fix bug *oud_export.sh* EXCLUDED_BACKENDS list minor error #103

### Removed

## [2.6.0] - 2022-08-29

### Added

- add comment for *CUSTOM* section in config of templates.
- add support for subfolders in [oud_functions.sh](local/oudbase/bin/oud_functions.sh)
  to fix issue #104
- add support for subfolders in [setup_oud.sh](local/oudbase/bin/setup_oud.sh)
  to fix issue #104
- add support for subfolders in [setup_oud_patch.sh](local/oudbase/bin/setup_oud_patch.sh)
  to fix issue #104

### Fixed

- Fix issue *Update OUD default Packages* #95
- Fix issue *setup_oud.sh and setup_oud_patch.sh wrong package checks* #105

## [2.5.0] - 2022-08-24

### Added

- add [p34287807_122140_Generic.zip](https://updates.oracle.com/Orion/Services/download/p34287807_122140_Generic.zip?aru=24823841&patch_file=p34287807_122140_Generic.zip) to the list of one off patch to fix the
  log4j vulnerability in *Oracle Unified Directory* common objects see also
  Oracle Support Document [2806740.2](https://support.oracle.com/epmos/faces/DocumentDisplay?id=2806740.2)
  *Critical Patch Update (CPU) Patch Advisor for Oracle Fusion Middleware - Updated for July 2022*
  and Oracle Support Document [1074055.1](https://support.oracle.com/epmos/faces/DocumentDisplay?id=1074055.1)
  *Security Vulnerability FAQ for Oracle Database and Fusion Middleware Products*

## [2.4.0] - 2022-08-19

### Added

### Changed

- enable OUD Access logger in all templates
- disable OUD Access control logger in all templates
- remove *set -o nounset* in *tns_functions.sh*
- remove *set -o errexit* in *tns_functions.sh*
- remove *set -o pipefail* in *tns_functions.sh*

### Fixed

- fix function name *load_config* in *tns_functions.sh*
- fix wrong *objectClass* in *net_service_exists*

### Removed

- update build script and remove *oudbase_install.tgz* from the package checksum file

## [2.3.1] - 2022-08-18

### Changed

- Change configuration file for TNS tools to *oudenv.conf* and *oudenv_custom.conf*
  rather than tool base name e.g. *oudbase* or *tvdldap*
- Move unused configuration scripts to [misc](local/oudbase/templates/create/misc/README.md)
  e.g. [18_migrate_keystore.sh](local/oudbase/templates/create/misc/18_migrate_keystore.sh) and
  [19_export_trustcert_keystore.sh](local/oudbase/templates/create/misc/19_export_trustcert_keystore.sh)

### Add

- add variable *HOST1* and *HOST2* to generic [00_init_environment](local/oudbase/templates/create/generic/00_init_environment)

## [2.2.1] - 2022-08-18

### Added

- update replication script to include additional suffix defined in *ALL_SUFFIX*

## [2.1.2] - 2022-08-17

### Fixed

- Fix if syntax in [setup_oud_patch.sh](local/oudbase/bin/setup_oud_patch.sh)
  and [setup_oud.sh](local/oudbase/bin/setup_oud.sh)

## [2.1.1] - 2022-08-17

### Fixed

- Fix the check for OUD_BASE creation. Does only exit if OUD_BASE can not be created.

## [2.1.0] - 2022-08-17

### Added

- add Status info to [tns_load.sh](./local/oudbase/bin/tns_load.sh)
- add new exit code 15 for missing software package
- add parameter to specify software Repository
- add check to verify software repository and software packages

### Changed

- Update File header to latest Date, Version etc Information
- Change license in all files to Apache
- change behavior how log and tempfiles are removed in [setup_oud_patch.sh](local/oudbase/bin/setup_oud_patch.sh)
  and [setup_oud.sh](local/oudbase/bin/setup_oud.sh)

## [2.0.0] - 2022-08-16

### Added

- add initial version of scripts for Oracle Net Service Names administration
  based on OpenLDAP client tools.
  - [tns_add.sh](local/oudbase/bin/tns_add.sh) script to add TNS Names entries
  - [tns_delete.sh](local/oudbase/bin/tns_delete.sh) script to delete TNS Names entries
  - [tns_dump.sh](local/oudbase/bin/tns_dump.sh) script to dump TNS Names entries into a *tnsname.ora* file.
  - [tns_functions.sh](local/oudbase/bin/tns_functions.sh) common functions.
  - [tns_load.sh](local/oudbase/bin/tns_load.sh) script to do bulk loads of TNS Names entries.
  - [tns_modify.sh](local/oudbase/bin/tns_modify.sh) script to modify TNS Names entries.
  - [tns_search.sh](local/oudbase/bin/tns_search.sh) script to search TNS Names entries.
  - [tns_test.sh](local/oudbase/bin/tns_test.sh) Test LDAP entries using tnsping.

## [1.9.6] - 2022-08-15

### Changed

- update latest patch information in [setup_oud.sh](local/oudbase/bin/setup_oud.sh)
- update latest patch information in [setup_oud_patch.sh](local/oudbase/bin/setup_oud_patch.sh)

## [1.9.5] - 2021-05-28

### Added

- add [CHANGELOG](CHANGELOG.md)
- add [CODE_OF_CONDUCT](CODE_OF_CONDUCT.md)
- add [CONTRIBUTING](CONTRIBUTING.md)

### Changed

- add latest OUD / WLS patch to [setup_oud_patch.sh](local/oudbase/bin/setup_oud_patch.sh)
  and [setup_oud.sh](local/oudbase/bin/setup_oud.sh)
- change template [generic](local/oudbase/templates/create/generic) to *generic* integration.

### Fixed

- fix [oud_backup.sh](local/oudbase/bin/oud_backup.sh) and uncomment remove of
  old backups

[unreleased]: https://github.com/oehrlis/oudbase
[releases]: https://github.com/oehrlis/oudbase/releases
