# Changelog
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-configure-file { "MD024":{"allow_different_nesting": true }} -->
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2021-03-03

### Added

### Changed

### Fixed

### Removed

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

[unreleased]: https://github.com/olivierlacan/keep-a-changelog/compare/v0.2.1...HEAD
[1.9.5]: https://github.com/oehrlis/oudbase/releases/tag/v1.9.4
