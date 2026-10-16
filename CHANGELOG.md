# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added
- `setup-locally` now configures the runner's resolver so `*.locally` addresses resolve once `locally ci` has started, and validates this by checking that `control-plane.locally` resolves to `127.0.0.1`. Disable with `configure-dns: 'false'`.

## 1.0.0 (2026-09-16)

### Added
- Initial release: setup, install-plugins, and teardown composite actions.
