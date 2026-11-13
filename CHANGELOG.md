# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added
- `snapshot-save`, which takes a snapshot of everything in Locally with `locally snapshot save`, optionally encrypted with a passphrase, and can upload it as a workflow artifact and/or share it with your Locally Team.
- `snapshot-load`, which replaces everything in Locally with a snapshot, using `locally snapshot load`. The snapshot can be one on the runner (by name, by path, or the one in a folder a workflow artifact was downloaded to) or one shared with your Locally Team.
- `snapshot-diff`, which compares two snapshots - or a snapshot with what's in Locally now - with `locally snapshot diff`, where each side can be a snapshot on the runner, a workflow artifact (from this run, another run or the latest on a branch) or one shared with your Locally Team. The differences are written to the job summary, and optionally as a pull request comment that's updated in place.

## 1.0.3 (2026-11-04)

### Fixed
- `teardown` now uploads `ci.log` when the calling job has failed. Previously it checked `failure()`, which within a composite action only reports on the action's own steps, so the log was never uploaded.
- `teardown` names the artifact after the job (and matrix leg), so that more than one failing job in a run can each upload their log. Previously each used `locally-ci-log`, so only the first would succeed.

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
