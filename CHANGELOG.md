# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] -

### Added

### Changed

### Fixed

### Removed

## [2.10.1] - 2023-02-22

### Changed

- update layout for debug information in scripts

### Fixed

- Fix issue #112 *Debug mode does not dump env variables*

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
[1.9.5]: https://github.com/oehrlis/oudbase/releases/tag/v1.9.5
[1.9.6]: https://github.com/oehrlis/oudbase/releases/tag/v1.9.6
[2.0.0]: https://github.com/oehrlis/oudbase/releases/tag/v2.0.0
[2.1.0]: https://github.com/oehrlis/oudbase/releases/tag/v2.1.0
[2.1.1]: https://github.com/oehrlis/oudbase/releases/tag/v2.1.1
[2.1.2]: https://github.com/oehrlis/oudbase/releases/tag/v2.1.2
[2.2.1]: https://github.com/oehrlis/oudbase/releases/tag/v2.2.1
[2.3.1]: https://github.com/oehrlis/oudbase/releases/tag/v2.3.1
[2.4.0]: https://github.com/oehrlis/oudbase/releases/tag/v2.4.0
[2.5.0]: https://github.com/oehrlis/oudbase/releases/tag/v2.5.0
[2.6.0]: https://github.com/oehrlis/oudbase/releases/tag/v2.6.0
[2.7.0]: https://github.com/oehrlis/oudbase/releases/tag/v2.7.0
[2.7.1]: https://github.com/oehrlis/oudbase/releases/tag/v2.7.1
