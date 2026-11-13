```
ooooo                                      oooo  oooo              
`888'                                      `888  `888              
 888          .ooooo.   .ooooo.   .oooo.    888   888  oooo    ooo 
 888         d88' `88b d88' `\"Y8 `P  )88b   888   888   `88.  .8'
 888         888   888 888        .oP\"888   888   888    `88..8'
 888       o 888   888 888   .o8 d8(  888   888   888     `888'
o888ooooood8 `Y8bod8P' `Y8bod8P' `Y888\"\"8o o888o o888o     .8'
                                                       .o..P'
                                                       `Y8P'
```

# setup-locally

This repository contains several GitHub Actions for [Locally Build](https://locally.build):

* `locallybuild/setup-locally@v1` - installs and configures Locally.
* `locallybuild/setup-locally/install-plugins@v1` - allows for installing Locally Plugins.
* `locallybuild/setup-locally/teardown@v1` - provides a means of stopping Locally once it's been launched in CI mode.
* `locallybuild/setup-locally/snapshot-save@v1` - takes a [Locally Snapshot](https://locally.build/docs/features/locally-snapshots) of everything in Locally, and optionally uploads it as a workflow artifact and/or shares it with your Locally Team.
* `locallybuild/setup-locally/snapshot-load@v1` - replaces everything in Locally with a snapshot.
* `locallybuild/setup-locally/snapshot-diff@v1` - shows what changed between two snapshots, or between a snapshot and what's in Locally now.

## OIDC Configuration for a Team/User (obtaining `team-uuid` or `user-uuid`)

Locally launches via OIDC, which is configured either [against your User](https://account.locally.build/account/oidc) or against a Team ([Locally Account](https://account.locally.build) -> Teams -> [Name] -> Team CI (OIDC).

If you've not already configured OIDC within Locally, on either the Team CI (OIDC) or User CI (OIDC) page linked above, you can:

1. Click `Add Trust` in the top-right of the page.
2. Select `GitHub Actions`.
3. Under `Organisation or Username`, enter the GitHub username for either your GitHub Organisation or your GitHub User (for example `mycompany` or `myusername`).
4. Under `Repository`, either specify the name of the repository you'd like to use Locally with (e.g. `myrepo`) or leave this blank to allow Locally to be used with all repositories in the GitHub Organisation/Username you specified above.
5. Under `Branch`, we'd recommend leaving this blank, but you can lock this down to specific branches by entering a branch name.

At the end of this flow, you'll see both the Team/User UUID and an example GitHub Action that uses the GitHub Actions within this repository.

## Example: Using `locallybuild/setup-locally@v1`

To use Locally against your Team, you can use the following GitHub Actions configuration:

```yaml
- uses: locallybuild/setup-locally@v1
  with:
    team-uuid: 'abc123'
    # plugins: recommended  # default; or `none`, `all`, `custom`
```

To use Locally in CI against your User, you can use the following GitHub Actions configuration:

```yaml
- uses: locallybuild/setup-locally@v1
  with:
    user-uuid: 'bcd234' # see above
    # plugins: recommended  # default; or `none`, `all`, `custom`
```

By default, both of these will install the Recommended set of Plugins, but you can specify a custom list to install for example:

```yaml
- uses: locallybuild/setup-locally@v1
  with:
    team-uuid: ${{ vars.LOCALLY_TEAM_UUID }}
    plugins: custom
    plugins-list: |
      Microsoft.ServiceBus
      Microsoft.Storage
```

`plugins-list` accepts one plugin per line (as above) or a comma-separated list
(`Microsoft.ServiceBus,Microsoft.Storage`) — the newline form is easier to read
and gives cleaner diffs as the list grows.

The full list of arguments:

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `team-uuid` | one of¹ | `''` | Locally team UUID (from account.locally.build) |
| `user-uuid` | one of¹ | `''` | Locally user UUID (from account.locally.build) |
| `version` | no | `latest` | CLI version (`latest` or e.g. `v2026.09`) |
| `plugins` | no | `recommended` | One of `none`, `recommended`, `all`, `custom` |
| `plugins-list` | when `plugins=custom` | `''` | Comma- or newline-separated plugin list |
| `start` | no | `true` | Generate TLS, install plugins, start `locally ci` |
| `configure-dns` | no | `true` | Route `*.locally` to Locally's DNS once started, and check it resolves |
| `accept-sql-server-licence` | no | `false` | Accept the Microsoft SQL Server licence by setting `LOCALLY_ACCEPT_SQL_SERVER_LICENCE` - must be explicitly set to `true` |
| `cache` | no | `true` | Cache the plugin directory between runs |
| `cache-key-prefix` | no | `''` | Optional cache key prefix |
| `expected-checksum` | no | `''` | SHA-256 to verify CLI tarball against |

¹ Exactly one of `team-uuid` or `user-uuid` must be set, depending on whether the OIDC subject is configured at team or user scope. Setting both fails; setting neither fails.



See [`action.yml`](action.yml) for the full input reference.

## Example: Using `locallybuild/setup-locally/install-plugins@v1`

Use this subaction to install Locally plugins later in a workflow — for example after running `setup-locally` with `plugins: none`. It requires `locally` to already be on `PATH` (i.e. `setup-locally` must have run earlier in the job).

```yaml
- uses: locallybuild/setup-locally/install-plugins@v1
  with:
    team-uuid: ${{ vars.LOCALLY_TEAM_UUID }}
    plugins: custom
    plugins-list: |
      Microsoft.ServiceBus
      Microsoft.Storage
```

As above, `plugins-list` takes one plugin per line or a comma-separated list.

The full list of arguments:

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `plugins` | no | `none` | One of `none`, `recommended`, `all`, `custom` |
| `plugins-list` | when `plugins=custom` | `''` | Comma- or newline-separated plugin list |
| `team-uuid` | one of¹ | `''` | Locally team UUID (falls back to the `LOCALLY_TEAM_UUID` env var set by `setup-locally`) |
| `user-uuid` | one of¹ | `''` | Locally user UUID (falls back to the `LOCALLY_USER_UUID` env var set by `setup-locally`) |
| `accept-sql-server-licence` | no | `false` | Accept the Microsoft SQL Server licence by setting `LOCALLY_ACCEPT_SQL_SERVER_LICENCE` - must be explicitly set to `true` (otherwise the env var set by `setup-locally` is inherited) |

¹ Exactly one of `team-uuid` or `user-uuid` must be resolvable (via input or inherited env) for any value of `plugins` other than `none`. Setting both fails.

See [`install-plugins/action.yml`](install-plugins/action.yml) for the full input reference.

## Example: Using `locallybuild/setup-locally/teardown@v1`

Use this subaction as the final step of any job that called `setup-locally` — it stops `locally ci`, removes the `*.locally` DNS configuration added by `configure-dns`, and, on job failure, uploads `ci.log` as a workflow artifact for debugging.

On self-hosted runners this matters: without it, the runner is left routing `*.locally` to Locally's DNS port after Locally has stopped.

```yaml
- uses: locallybuild/setup-locally/teardown@v1
  if: always()
  # with:
  #   upload-logs-on-failure: 'true'  # default
```

The full list of arguments:

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `upload-logs-on-failure` | no | `'true'` | Whether to upload `ci.log` as a workflow artifact when the job has failed |
| `job-status` | no | `${{ job.status }}` | The status of the calling job, which decides whether `ci.log` is uploaded. There's no need to set this |

The artifact is named `locally-ci-log-<job id>`, with the matrix index appended (`-0`, `-1`, ...) for each leg of a matrix job.

See [`teardown/action.yml`](teardown/action.yml) for the full input reference.

## Snapshots

[Locally Snapshots](https://locally.build/docs/features/locally-snapshots) allow you to capture the resources (and data) within Locally as a single file, which can be restored later or shared with your Team.

The three subactions below are used to save, load and diff Snapshots - each of these needs to run after `setup-locally` in the same job (since they reuse its credentials).

Snapshots are available on the Standard plan and above, whilst sharing a Snapshot with your Team requires the Team plan or above.

> [!WARNING]
> Snapshots contain the credentials of your resources (Key Vault values, keys, passwords). Anyone who can download a workflow artifact can read an unencrypted snapshot, so set `passphrase` (from a secret) before uploading or sharing one.

## Example: Using `locallybuild/setup-locally/snapshot-save@v1`

Use this subaction to take a snapshot of everything in Locally, and optionally upload it as a workflow artifact and/or share it with your Locally Team:

```yaml
- uses: locallybuild/setup-locally/snapshot-save@v1
  with:
    name: deployed
    upload: artifact
    passphrase: ${{ secrets.LOCALLY_SNAPSHOT_PASSPHRASE }}
```

The full list of arguments:

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `name` | yes | | The name to save the snapshot under: letters, digits, `.`, `_` and `-`, starting with a letter or digit (at most 100 characters) |
| `description` | no | `''` | What the snapshot holds and why it was taken (one line, at most 500 characters) |
| `passphrase` | no | `''` | Encrypt the snapshot with this passphrase, passed in from a secret |
| `timeout` | no | `''` | Give up if running operations haven't finished within this time (e.g. `5m`) - defaults to waiting |
| `upload` | no | `none` | Any of `none` (keep it on the runner only), `artifact` (a workflow artifact) and `team` (share it with your Locally Team), comma- or newline-separated |
| `artifact-name` | no | `locally-snapshot-<name>` | The workflow artifact's name, when `upload` includes `artifact` |
| `artifact-retention-days` | no | repository setting | How many days to keep the artifact for |
| `artifact-overwrite` | no | `false` | Replace an artifact of the same name from earlier in this run |
| `team` | no | `''` | The Locally Team to share with, when `upload` includes `team` and you're in more than one |

Artifact names have to be unique within a run, so when more than one job uploads a snapshot, give each a different `name` (or `artifact-name`).

Outputs: `name`, `path` (of the snapshot file on the runner), `artifact-name`, `artifact-id` and `artifact-url`.

See [`snapshot-save/action.yml`](snapshot-save/action.yml) for the full input reference.

## Example: Using `locallybuild/setup-locally/snapshot-load@v1`

Use this subaction to replace everything in Locally with a snapshot - to start a job from an environment that's already been deployed, say, or to put Locally back as it was between two sets of tests.

Everything in Locally is replaced, and only if the whole snapshot can be loaded: otherwise it's left as it was. Plugins that the snapshot needs and that aren't installed may be installed first, and stay installed even if the load is refused.

```yaml
- uses: locallybuild/setup-locally/snapshot-save@v1
  with:
    name: before

- run: npm test

- uses: locallybuild/setup-locally/snapshot-load@v1
  with:
    snapshot: before
```

To load a snapshot that another workflow (or an earlier run) uploaded as an artifact, download it with `actions/download-artifact` and give `snapshot` the folder it was downloaded to. The subaction loads the one `.locallysnap` file in that folder:

```yaml
- uses: actions/download-artifact@v8
  with:
    name: locally-snapshot-deployed
    path: ${{ runner.temp }}/locally-snapshot
    # for an artifact from another run:
    # run-id: ...
    # github-token: ${{ github.token }}

- uses: locallybuild/setup-locally/snapshot-load@v1
  with:
    snapshot: ${{ runner.temp }}/locally-snapshot
    passphrase: ${{ secrets.LOCALLY_SNAPSHOT_PASSPHRASE }}
```

To load a snapshot that's been shared with your Locally Team:

```yaml
- uses: locallybuild/setup-locally/snapshot-load@v1
  with:
    snapshot: shared-baseline
    source: team
    passphrase: ${{ secrets.LOCALLY_SNAPSHOT_PASSPHRASE }}
```

A team's snapshot is downloaded under a name of its own, loaded, then removed from the runner, so it can't replace a snapshot that's already there.

The full list of arguments:

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `snapshot` | yes | | With `source: local`, a snapshot's name, the path of a `.locallysnap` file, or the path of a folder holding exactly one. With `source: team`, the name of a snapshot shared with your Locally Team |
| `source` | no | `local` | Where the snapshot comes from: `local` (on the runner) or `team` |
| `team` | no | `''` | The Locally Team, when `source` is `team` and you're in more than one |
| `passphrase` | when the snapshot is encrypted | `''` | The snapshot's passphrase, passed in from a secret |
| `timeout` | no | `''` | Give up if running operations haven't finished within this time (e.g. `5m`) - defaults to waiting |

See [`snapshot-load/action.yml`](snapshot-load/action.yml) for the full input reference.

## Example: Using `locallybuild/setup-locally/snapshot-diff@v1`

Use this subaction to show what changed between two snapshots, or between a snapshot and what's in Locally now, in the job summary and (optionally) as a pull request comment. It needs Locally to be running even when comparing two snapshots, since Locally does the comparison.

To see what your tests changed, take a snapshot before they run, then compare it with what's in Locally afterwards:

```yaml
permissions:
  contents: read
  id-token: write      # Locally signs in using GitHub's OIDC token
  pull-requests: write # to comment on the pull request

steps:
  - uses: actions/checkout@v7

  - uses: locallybuild/setup-locally@v1
    with:
      team-uuid: ${{ vars.LOCALLY_TEAM_UUID }}

  - uses: locallybuild/setup-locally/snapshot-save@v1
    with:
      name: before

  - run: terraform apply -auto-approve

  - uses: locallybuild/setup-locally/snapshot-diff@v1
    with:
      from: before
      comment: true

  - uses: locallybuild/setup-locally/teardown@v1
    if: always()
```

To compare a pull request with `main`, upload a snapshot as an artifact on every push to `main`:

```yaml
- uses: locallybuild/setup-locally/snapshot-save@v1
  with:
    name: deployed
    upload: artifact
    artifact-name: locally-snapshot-deployed
    passphrase: ${{ secrets.LOCALLY_SNAPSHOT_PASSPHRASE }}
```

Then, in pull requests, compare the latest one from `main` with what the pull request deploys:

```yaml
permissions:
  contents: read
  actions: read        # to find and download artifacts from other runs
  id-token: write
  pull-requests: write

steps:
  # ... set up Locally and deploy ...

  - uses: locallybuild/setup-locally/snapshot-diff@v1
    with:
      from: locally-snapshot-deployed
      from-source: artifact
      from-branch: main
      passphrase: ${{ secrets.LOCALLY_SNAPSHOT_PASSPHRASE }}
      comment: true
```

Or to compare with a snapshot your team shared:

```yaml
- uses: locallybuild/setup-locally/snapshot-diff@v1
  with:
    from: golden
    from-source: team
    team: Platform Team # only needed when you're in more than one team
```

Each side of the comparison is a snapshot from one of three sources:

| Source | `from` / `to` is | Notes |
|--------|------------------|-------|
| `local` (default) | a snapshot's name, or the path to a `.locallysnap` file | e.g. one taken earlier in the job with `snapshot-save` |
| `artifact` | the name of a workflow artifact holding one snapshot | from this run by default; set `*-run-id` for another run, or `*-branch` for the most recent one on a branch (ignoring those uploaded by pull requests from forks). Needs `actions: read`. |
| `team` | the name of a snapshot shared with your Locally Team | downloaded for the comparison, then removed from the runner |

Leave `to` empty to compare against what's in Locally now.

The full list of arguments:

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| `from` | yes | | The earlier side of the comparison |
| `from-source` | no | `local` | `local`, `artifact` or `team` |
| `from-run-id` | no | this run | With `artifact`, the run that uploaded it |
| `from-branch` | no | `''` | With `artifact`, use the most recent one uploaded on this branch |
| `to` | no | what's in Locally now | The later side of the comparison |
| `to-source` | no | `local` | `local`, `artifact` or `team` |
| `to-run-id` | no | this run | With `artifact`, the run that uploaded it |
| `to-branch` | no | `''` | With `artifact`, use the most recent one uploaded on this branch |
| `repository` | no | this repository | Where to download artifacts from |
| `team` | no | `''` | The Locally Team, for a `team` source, when you're in more than one |
| `passphrase` | no | `''` | The passphrase for encrypted snapshots (both sides need the same one) |
| `all` | no | `false` | Also compare timestamps, etags, the activity log, delivered events and issued tokens |
| `timeout` | no | `''` | When comparing against Locally now, give up if running operations haven't finished within this time |
| `title` | no | `Locally snapshot diff` | The heading of the summary and comment |
| `job-summary` | no | `true` | Write the differences to the job summary |
| `comment` | no | `false` | Comment on the pull request (needs `pull-requests: write`) |
| `comment-key` | no | `default` | Which comment to update, so that several diffs can each have their own |
| `pull-request-number` | no | the triggering pull request | The pull request to comment on |
| `artifact` | no | `true` | Upload the diff, as JSON, as a workflow artifact when there are differences |
| `artifact-name` | no | `locally-snapshot-diff-<comment-key>-<suffix>` | That artifact's name |
| `artifact-retention-days` | no | repository setting | How many days to keep that artifact for |
| `fail-on-changes` | no | `false` | Fail the step when there are differences (after writing the summary and comment) |
| `github-token` | no | `github.token` | Used for artifacts and comments |

The comment is updated in place on later runs. It's only created when there are differences, but an existing one is always updated - so it says so once a later push puts things back. A diff too long for a comment (or the job summary) is cut down to its headline and the first rows of its table there, with links to the rest: the workflow run's summary, and the diff as JSON (uploaded as an artifact, unless `artifact: false`). The comment links to both either way.

Outputs: `has-changes` (`true` / `false`), `resources-added`, `resources-changed`, `resources-removed`, `data-added`, `data-changed`, `data-removed`, `json-path` (the diff as `locally snapshot diff --json` printed it), `markdown-path`, `artifact-url` and `comment-url`.

The summary leads with how much changed, then lists the resources that did - removals first, since they're the most likely to be unexpected, then modifications, then additions:

> **3 resources changed** since `before` in `snapdiff-rg`: 1 removed, 1 modified, 1 added.
>
> | | Resource | Kind |
> |---|---|---|
> | 🔴 Removed | **alpha**<br><sub>in snapdiffsa</sub> | Blob container |
> | 🟡 Modified | **snapdiffsa** | Storage account |
> | 🟢 Added | **beta**<br><sub>in snapdiffsa</sub> | Blob container |

followed by what changed on each modified resource (as a before/after table of its properties) and in the data Locally holds (blobs, queues, directory users and the like), each collapsed.

Credentials are never shown - a changed key or secret is reported as changed, without its value - and nothing that comes from a snapshot is interpreted as Markdown or HTML in the summary or comment.

See [`snapshot-diff/action.yml`](snapshot-diff/action.yml) for the full input reference.

## Developing

* `tests/render.sh` checks the Markdown rendering of a snapshot diff against `tests/fixtures/` (`--update` rewrites the expected output).
* `tests/terraform` is a small configuration that CI applies twice with different variables (see the comment at the top of `main.tf`), so that the snapshot actions have a known set of changes to find and to undo.
* `tests/run-action.py <action.yml> name=value ...` runs an action's scripts against a Locally on your machine, skipping the steps that use other actions. It needs PyYAML, and the `locally` you want to use first on your `PATH`.

## License

This action is licensed under [Apache-2.0](LICENSE). The Locally CLI it installs is governed by separate terms — see [`NOTICE`](NOTICE).
