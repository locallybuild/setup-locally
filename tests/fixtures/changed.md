<!-- locally-snapshot-diff:default -->

### Locally snapshot diff

**2 resources changed** between <code>baseline</code> and <code>after&lt;script&gt;</code> in <code>example</code>: 1 modified, 1 added.

> [!WARNING]
> storage/blobs was saved at version 1 in "baseline" and version 2 in "after"

| | Resource | Kind |
|---|---|---|
| 🟡 Modified | <b>examplesa</b> | Storage account |
| 🟢 Added | <b>example</b> | Resource group |

<details open><summary>🟡 <b>examplesa</b> · Storage account · 4 properties changed</summary>

| Property | Before | After |
|---|---|---|
| <code>properties.minimumTlsVersion</code> | <code>"TLS1_0"</code> | <code>"TLS1_2"</code> |
| <code>tags.env</code> | — | <code>"prod &#96;@everyone&#96; &#124; &lt;b&gt;x&lt;/b&gt;"</code> |
| <code>tags.owner</code> | <code>"@tombuildsstuff"</code> | — |
| <code>keys</code><br><sub>account settings</sub> | 🔒 <i>hidden</i> | 🔒 <i>hidden</i> |

</details>

<details><summary>Data · 2 records changed</summary>

Blobs, queues, directory users and the like, which Locally holds alongside the resources.

| | Item | Kind | Changes |
|---|---|---|---|
| 🟡 Modified | <code>examplesa/data/config.json</code> | Blob | <code>contentLength</code>: <code>12</code> → <code>14</code> |
| 🟢 Added | <code>examplesa/data/hello.txt</code> | Blob |  |

</details>

<sub>Compared <code>baseline</code> (4 Nov, 10:07 UTC) with <code>after&lt;script&gt;</code> (4 Nov, 18:13 UTC). Not compared, since they change on their own: activity log (set <code>all: true</code> to include them). <a href="https://github.com/locallybuild/example/actions/runs/1/attempts/1">Workflow run</a> · <a href="https://github.com/locallybuild/example/actions/runs/1/artifacts/2">Diff as JSON</a></sub>
