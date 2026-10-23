# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 1.0.2 (2026-10-23)

### Added
- `setup-locally` has a new `accept-sql-server-licence` input which, when explicitly set to `'true'`, sets `LOCALLY_ACCEPT_SQL_SERVER_LICENCE` so that `locally ci` can run SQL Server. It defaults to `'false'`, which leaves the variable unset.
- `install-plugins` accepts the same `accept-sql-server-licence` input, for when it's used standalone; otherwise it inherits `LOCALLY_ACCEPT_SQL_SERVER_LICENCE` from `setup-locally`.

## 1.0.1 (2026-10-23)

### Added
- `setup-locally` now configures the runner's resolver so `*.locally` addresses resolve once `locally ci` has started, and validates this by checking that `control-plane.locally` resolves to `127.0.0.1`. Disable with `configure-dns: 'false'`. This uses `locally configure dns`, which needs Locally 2026.10 or later on Windows.
- `teardown` removes that DNS configuration again.

### Fixed
- Verifying the CLI download no longer fails on Windows runners, where `shasum` isn't available.
- Generating TLS material no longer fails on Windows runners, where Git Bash rewrote the certificate subject into a path.

## 1.0.0 (2026-09-16)

### Added
- Initial release: setup, install-plugins, and teardown composite actions.
