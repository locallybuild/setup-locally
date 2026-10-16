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

See [`teardown/action.yml`](teardown/action.yml) for the full input reference.

## License

This action is licensed under [Apache-2.0](LICENSE). The Locally CLI it installs is governed by separate terms — see [`NOTICE`](NOTICE).
