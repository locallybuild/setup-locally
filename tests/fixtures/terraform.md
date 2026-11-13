<!-- locally-snapshot-diff:default -->

### Locally snapshot diff

**3 resources changed** since <code>before</code> in <code>snapdiff-rg</code>: 1 removed, 1 modified, 1 added.

| | Resource | Kind |
|---|---|---|
| 🔴 Removed | <b>alpha</b><br><sub>in snapdiffsa</sub> | Blob container |
| 🟡 Modified | <b>snapdiffsa</b> | Storage account |
| 🟢 Added | <b>beta</b><br><sub>in snapdiffsa</sub> | Blob container |

<details open><summary>🟡 <b>snapdiffsa</b> · Storage account · 1 property changed</summary>

| Property | Before | After |
|---|---|---|
| <code>tags.environment</code> | <code>"one"</code> | <code>"two"</code> |

</details>

<details><summary>Data · 2 records changed</summary>

Blobs, queues, directory users and the like, which Locally holds alongside the resources.

| | Item | Kind |
|---|---|---|
| 🔴 Removed | <code>snapdiffsa/alpha</code> | Storage container |
| 🟢 Added | <code>snapdiffsa/beta</code> | Storage container |

</details>

<sub>Compared <code>before</code> (4 Nov, 20:11 UTC) with Locally (4 Nov, 20:11 UTC). Not compared, since they change on their own: eventgrid events, eventgrid sequences, activity log (set <code>all: true</code> to include them). <a href="https://github.com/locallybuild/example/actions/runs/1/attempts/1">Workflow run</a> · <a href="https://github.com/locallybuild/example/actions/runs/1/artifacts/2">Diff as JSON</a></sub>
