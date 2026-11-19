<!-- locally-snapshot-diff:default -->

### Locally snapshot diff

**4 resources changed** since <code>after</code> in <code>snapdiff-rg</code>: 2 removed, 2 added.

> [!WARNING]
> These snapshots seem to come from different Locally instances, as their tenants differ. Each instance has its own tenant and subscription IDs, so everything shows as removed and added again, even when both hold the same resources.

| | Resource | Kind |
|---|---|---|
| 🔴 Removed | <b>beta</b><br><sub>in snapdiffsa</sub> | Blob container |
| 🔴 Removed | <b>snapdiffsa</b> | Storage account |
| 🟢 Added | <b>beta</b><br><sub>in snapdiffsa</sub> | Blob container |
| 🟢 Added | <b>snapdiffsa</b> | Storage account |

<details><summary>Data · 8 records changed</summary>

Blobs, queues, directory users and the like, which Locally holds alongside the resources.

| | Item | Kind |
|---|---|---|
| 🔴 Removed | <code>9c75dffe-0a15-475a-9da8-8cb9dbfec422/5942f68a-8a5e-437f-88dc-bb243edbfae7</code> | Subscription |
| 🔴 Removed | <code>9c75dffe-0a15-475a-9da8-8cb9dbfec422/9c148861-01a2-4b8c-bbde-d232e3444a7a</code> | Subscription |
| 🔴 Removed | <code>9c75dffe-0a15-475a-9da8-8cb9dbfec422/c8b200a5-168e-4a34-b439-4076c2c08f57</code> | Subscription |
| 🔴 Removed | <code>/tenants/9c75dffe-0a15-475a-9da8-8cb9dbfec422</code> | Tenant |
| 🟢 Added | <code>4ae86617-728e-4ac2-9bdb-9349df25b57a/05c64d57-a430-40bd-a6b7-537154250fee</code> | Subscription |
| 🟢 Added | <code>4ae86617-728e-4ac2-9bdb-9349df25b57a/d9e3063e-7e83-4684-845a-910398a9b753</code> | Subscription |
| 🟢 Added | <code>4ae86617-728e-4ac2-9bdb-9349df25b57a/f1bf936c-1045-4ccd-85f5-d416f49de97e</code> | Subscription |
| 🟢 Added | <code>/tenants/4ae86617-728e-4ac2-9bdb-9349df25b57a</code> | Tenant |

</details>

<sub>Compared <code>after</code> (18 Nov, 07:18 UTC) with Locally (18 Nov, 07:19 UTC). Not compared, since they change on their own: signing keys, auth tokens, eventgrid events, eventgrid sequences, activity log (set <code>all: true</code> to include them). <a href="https://github.com/locallybuild/example/actions/runs/1/attempts/1">Workflow run</a> · <a href="https://github.com/locallybuild/example/actions/runs/1/artifacts/2">Diff as JSON</a></sub>
