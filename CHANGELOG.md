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

### Changed

### Fixed

### Removed

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