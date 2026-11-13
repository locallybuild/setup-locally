#!/usr/bin/env bash
# Renders each tests/fixtures/<name>.json and compares it with
# tests/fixtures/<name>.md (and <name>.short.md, for the comment-sized form).
# Pass --update to rewrite the expected output instead.
set -euo pipefail
cd "$(dirname "$0")/.."

update=false
if [ "${1:-}" = "--update" ]; then
  update=true
fi

failed=0
for json in tests/fixtures/*.json; do
  base="${json%.json}"
  for detailed in true false; do
    expected="$base.md"
    if [ "$detailed" = "false" ]; then
      expected="$base.short.md"
    fi
    actual="$(jq -r -f scripts/render-diff.jq \
      --arg title "Locally snapshot diff" \
      --arg marker "<!-- locally-snapshot-diff:default -->" \
      --argjson detailed "$detailed" \
      --argjson open_limit 25 \
      --arg run_url "https://github.com/locallybuild/example/actions/runs/1/attempts/1" \
      --arg artifact_url "https://github.com/locallybuild/example/actions/runs/1/artifacts/2" \
      "$json")"
    if [ "$update" = "true" ]; then
      printf '%s\n' "$actual" > "$expected"
      echo "updated $expected"
    elif ! diff -u "$expected" <(printf '%s\n' "$actual"); then
      echo "::error::$json rendered differently to $expected"
      failed=1
    else
      echo "ok $expected"
    fi
  done
done
# However large a diff is, its short form has to fit in a pull request comment
# (65,536 characters) - which the full form of this one doesn't.
large="$(jq -n '{
  from: {name: "before", createdAt: "2026-11-04T10:00:00Z"},
  to: {live: true, createdAt: "2026-11-04T11:00:00Z"},
  resources: [range(5000) | {
    action: (["removed", "changed", "added"][. % 3]),
    id: "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-\(. % 7)/providers/Microsoft.Storage/storageAccounts/account\(.)",
    type: "Microsoft.Storage/storageAccounts",
    changes: [{action: "changed", path: "tags.environment", before: "one", after: "two"}]
  }],
  data: [],
  summary: {resourcesAdded: 1666, resourcesChanged: 1667, resourcesRemoved: 1667, dataAdded: 0, dataChanged: 0, dataRemoved: 0}
}')"
for detailed in true false; do
  size="$(printf '%s' "$large" | jq -r -f scripts/render-diff.jq \
    --arg title "Locally snapshot diff" --arg marker "" \
    --argjson detailed "$detailed" --argjson open_limit 25 \
    --arg run_url "https://github.com/locallybuild/example/actions/runs/1/attempts/1" \
    --arg artifact_url "https://github.com/locallybuild/example/actions/runs/1/artifacts/2" | wc -m | tr -d ' ')"
  if [ "$detailed" = "true" ] && [ "$size" -lt 65000 ]; then
    echo "::error::expected the full form of the large diff to be too long for a comment, but it's $size characters"
    failed=1
  elif [ "$detailed" = "false" ] && [ "$size" -ge 65000 ]; then
    echo "::error::the short form of the large diff is $size characters, which is too long for a comment"
    failed=1
  else
    echo "ok large diff (detailed=$detailed): $size characters"
  fi
done

exit "$failed"
