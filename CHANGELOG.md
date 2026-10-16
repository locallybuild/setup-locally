# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added
- `setup-locally` now configures the runner's resolver so `*.locally` addresses resolve once `locally ci` has started, and validates this by checking that `control-plane.locally` resolves to `127.0.0.1`. Disable with `configure-dns: 'false'`. On Windows, where `locally configure dns` isn't supported yet, this adds an NRPT rule instead.
- `teardown` removes that DNS configuration (or NRPT rule) again.

### Fixed
- Verifying the CLI download no longer fails on Windows runners, where `shasum` isn't available.
- Generating TLS material no longer fails on Windows runners, where Git Bash rewrote the certificate subject into a path.

## 1.0.0 (2026-09-16)

### Added
- Initial release: setup, install-plugins, and teardown composite actions.
