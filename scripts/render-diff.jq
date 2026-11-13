# Renders the output of `locally snapshot diff --json` as GitHub-flavoured
# Markdown, for a job summary or a pull request comment.
#
#   jq -r -f render-diff.jq \
#     --arg title "Locally snapshot diff" \
#     --arg marker "<!-- ... -->" \
#     --argjson detailed true \
#     --argjson open_limit 25 \
#     --arg run_url "https://github.com/.../actions/runs/1/attempts/1" \
#     --arg artifact_url "https://github.com/.../artifacts/2" \
#     diff.json
#
# run_url (where the job summary is) and artifact_url (the diff as JSON) are
# linked from the footer when set - and when the diff is too long to show in
# full, which is how a pull request comment points at the rest of it.
#
# The layout, most important first: one sentence saying how much changed; a
# table of the resources that changed, removals first; then, collapsed, what
# changed on each modified resource and in the data Locally holds. With
# `detailed` false (when that's too long for a comment, or the job summary),
# only the sentence and the first rows of the table, and links to the rest -
# so that it stays short however large the diff is.
#
# Everything that comes out of a snapshot is HTML-escaped (including `|`, so it
# can't break a table) and values are wrapped in <code>, so nothing in a
# snapshot can inject Markdown or HTML, or @mention anybody.

def esc: tostring | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;") | gsub("\\|"; "&#124;") | gsub("`"; "&#96;") | gsub("\r?\n"; " ");
def code: "<code>" + esc + "</code>";

# How many rows a table shows before the rest are folded away.
def row_limit: 20;

# Removals first: they're the most likely to be unexpected, and the most
# damaging. Then modifications, then additions.
def rank: if . == "removed" then 0 elif . == "changed" then 1 else 2 end;
def badge: if . == "removed" then "🔴 Removed" elif . == "changed" then "🟡 Modified" else "🟢 Added" end;
def dot: if . == "removed" then "🔴" elif . == "changed" then "🟡" else "🟢" end;

def plural($n; $one; $many): "\($n) " + (if $n == 1 then $one else $many end);

# `storageAccounts` -> "storage account": camelCase and snake_case split into
# words, and the last one made singular.
def words: gsub("(?<a>[a-z0-9])(?<b>[A-Z])"; "\(.a) \(.b)") | gsub("[_-]+"; " ") | ascii_downcase;
def singular:
  if test("ies$") then sub("ies$"; "y")
  elif test("(ss|us|is)$") then .
  elif test("s$") then sub("s$"; "")
  else . end;
def capitalised: (.[0:1] | ascii_upcase) + .[1:];

# A resource type's kind, in words: the last type in it, made singular - with
# what's left of a `...Services` parent, so that
# Microsoft.Storage/storageAccounts/blobServices/containers is a "Blob container".
def kind:
  (split("/") | .[1:]) as $types
  | ($types | last // "resource" | words | singular) as $leaf
  | if ($types | length) > 1 and ($types[-2] | test("Services$")) then
      ($types[-2] | sub("Services$"; "") | words) + " " + $leaf
    else $leaf end
  | capitalised;

# A record type's kind: `storage_containers` -> "Storage container".
def record_kind: words | singular | capitalised;

# Where an ARM ID's resource's own name starts: after the last /providers/.
def provider_index: ascii_downcase | [match("/providers/"; "g").offset] | last;

# The resource's own name, and the names of the resources it's nested in (or,
# for an extension resource such as a role assignment, attached to) - leaving
# out the `default` singletons (blobServices/default) that only add noise.
def names:
  . as $id
  | ($id | provider_index) as $i
  | if $i == null then [($id | split("/") | last)]
    else
      ($id[0:$i] | if provider_index != null then (split("/") | [last]) else [] end) as $attached
      | ($id[$i + 11:] | split("/") | .[2:] | [to_entries[] | select(.key % 2 == 0) | .value]) as $own
      | $attached + $own
    end;
def own_name: names | last;
def parent_name: names | .[0:-1] | map(select(ascii_downcase != "default")) | join("/");

def resource_group:
  (capture("/resourceGroups/(?<rg>[^/]+)"; "i") | .rg) // "";

# `2026-11-04T20:11:14.123Z` -> "4 Nov, 20:11 UTC". By hand, since jq's
# strptime/strftime fail on Windows.
def when:
  if . then
    (capture("^(?<y>[0-9]{4})-(?<m>[0-9]{2})-(?<d>[0-9]{2})T(?<hm>[0-9]{2}:[0-9]{2})") // null) as $t
    | if $t == null then .
      else "\($t.d | tonumber) "
        + (["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][($t.m | tonumber) - 1])
        + ", \($t.hm) UTC"
      end
  else "" end;

def side_name: if .live then "Locally now" else (.name // "(unnamed)") end;

# Values are JSON, as the CLI emits them, cut short so that a large blob or
# template doesn't swamp a table.
def value:
  if . == null then "—"
  else tojson | if length > 80 then .[0:77] + "..." else . end | code
  end;

def property_label:
  (.path // "" | code)
  + (if (.record // "") != "" and .record != "generic_resources" then "<br><sub>" + (.record | words | esc) + "</sub>" else "" end);

def property_row:
  "| " + property_label + " | "
  + (if .sensitive then "🔒 <i>hidden</i> | 🔒 <i>hidden</i>"
     else (.before | value) + " | " + (.after | value) end)
  + " |";

# Rows past the limit are folded away, so a large diff stays scannable.
def table($header; $rows):
  if ($rows | length) <= row_limit then
    $header + "\n" + ($rows | join("\n"))
  elif $detailed | not then
    $header + "\n" + ($rows[0:row_limit] | join("\n"))
    + "\n\n<i>and \(($rows | length) - row_limit) more.</i>"
  else
    $header + "\n" + ($rows[0:row_limit] | join("\n"))
    + "\n\n<details><summary>and \(($rows | length) - row_limit) more</summary>\n\n"
    + $header + "\n" + ($rows[row_limit:] | join("\n")) + "\n\n</details>"
  end;

def sorted_resources:
  (.resources // [])
  | map(. + {name: (.id | own_name), parent: (.id | parent_name), group: (.id | resource_group)})
  | sort_by((.group | ascii_downcase), (.action | rank), (.name | ascii_downcase));

def groups: [sorted_resources[].group] | unique_by(ascii_downcase);

def resource_table:
  (groups | length > 1) as $by_group
  | table(
      (if $by_group then "| | Resource | Kind | Resource group |\n|---|---|---|---|"
       else "| | Resource | Kind |\n|---|---|---|" end);
      [ sorted_resources[]
        | "| " + (.action | badge)
          + " | <b>" + (.name | esc) + "</b>"
          + (if .parent != "" then "<br><sub>in " + (.parent | esc) + "</sub>" else "" end)
          + " | " + (.type // "" | kind | esc)
          + (if $by_group then " | " + (if .group == "" then "—" else (.group | esc) end) else "" end)
          + " |" ]);

def modified_details($open):
  [ sorted_resources[] | select(.action == "changed" and ((.changes // []) | length) > 0)
    | "<details" + (if $open then " open" else "" end) + "><summary>🟡 <b>" + (.name | esc) + "</b> · "
      + (.type // "" | kind | esc) + " · " + plural(.changes | length; "property"; "properties") + " changed</summary>\n\n"
      + "| Property | Before | After |\n|---|---|---|\n"
      + ([.changes[] | property_row] | join("\n"))
      + "\n\n</details>" ]
  | join("\n\n");

def data_count: [(.data // [])[].changes | length] | add // 0;

def data_details:
  [ (.data // [])[] | .type as $t | .changes[] | . + {kind: ($t | record_kind)} ]
  | sort_by((.action | rank), (.kind | ascii_downcase), (.key | ascii_downcase)) as $rows
  | ([$rows[] | (.changes // []) | length] | add // 0 | . > 0) as $with_changes
  | "<details><summary>Data · " + plural($rows | length; "record"; "records") + " changed</summary>\n\n"
    + "Blobs, queues, directory users and the like, which Locally holds alongside the resources.\n\n"
    + table(
        (if $with_changes then "| | Item | Kind | Changes |\n|---|---|---|---|" else "| | Item | Kind |\n|---|---|---|" end);
        [ $rows[]
          | "| " + (.action | badge) + " | " + (.key | code) + " | " + (.kind | esc)
            + (if $with_changes then
                 " | " + ([(.changes // [])[]
                   | (.path // "" | code) + ": "
                     + (if .sensitive then "🔒 <i>hidden</i>" else (.before | value) + " → " + (.after | value) end)]
                   | join("<br>"))
               else "" end)
            + " |" ])
    + "\n\n</details>";

def resource_count: (.resources // []) | length;
def is_empty: resource_count == 0 and data_count == 0;

def counts($items):
  [ ($items | map(select(.action == "removed")) | length) as $r | if $r > 0 then "\($r) removed" else empty end,
    ($items | map(select(.action == "changed")) | length) as $c | if $c > 0 then "\($c) modified" else empty end,
    ($items | map(select(.action == "added")) | length) as $a | if $a > 0 then "\($a) added" else empty end ]
  | join(", ");

def since:
  if .to.live then "since <code>" + (.from | side_name | esc) + "</code>"
  else "between <code>" + (.from | side_name | esc) + "</code> and <code>" + (.to | side_name | esc) + "</code>"
  end;

def headline:
  (groups) as $groups
  | if is_empty then "✅ **No changes** " + since + "."
    elif resource_count == 0 then
      "**No resources changed** " + since + ", but " + plural(data_count; "data record"; "data records") + " did."
    else
      "**" + plural(resource_count; "resource"; "resources") + " changed** " + since
      + (if ($groups | length) == 1 and $groups[0] != "" then " in <code>" + ($groups[0] | esc) + "</code>" else "" end)
      + ": " + counts(.resources) + "."
    end;

def link($url; $text): "<a href=\"" + ($url | esc | gsub("\""; "&quot;")) + "\">" + $text + "</a>";

# Where the rest of the diff is: the job summary (from a comment) and the JSON.
def links:
  [ (if $run_url != "" then link($run_url; "Workflow run") else empty end),
    (if $artifact_url != "" then link($artifact_url; "Diff as JSON") else empty end) ]
  | join(" · ");

def too_long:
  "> [!NOTE]\n> This diff is too long to show in full here. "
  + if $run_url != "" and $artifact_url != "" then
      "See all of it in the " + link($run_url; "workflow run's summary") + ", or " + link($artifact_url; "download it as JSON") + "."
    elif $run_url != "" then "See all of it in the " + link($run_url; "workflow run's summary") + "."
    elif $artifact_url != "" then link($artifact_url; "Download it as JSON") + " to see all of it."
    else "See the <code>json-path</code> output of the step for all of it."
    end;

def footer:
  "<sub>Compared <code>" + (.from | side_name | esc) + "</code>"
  + (if .from.createdAt then " (" + (.from.createdAt | when) + ")" else "" end)
  + " with " + (if .to.live then "Locally" else "<code>" + (.to | side_name | esc) + "</code>" end)
  + (if .to.createdAt then " (" + (.to.createdAt | when) + ")" else "" end)
  + (if ((.skipped // []) | length) > 0 then
       ". Not compared, since they change on their own: " + ([.skipped[] | split("/") | last | words | esc] | join(", "))
       + " (set <code>all: true</code> to include them)"
     else "" end)
  + "."
  + (if links != "" then " " + links else "" end)
  + "</sub>";

[
  (if $marker != "" then $marker else empty end),
  "### " + ($title | esc),
  headline,
  (if ((.notes // []) | length) > 0 then
     "> [!WARNING]\n" + ([.notes[] | "> " + esc] | join("\n>\n"))
   else empty end),
  (if resource_count > 0 then resource_table else empty end),
  (if is_empty then empty
   elif $detailed then
     ( ([.resources[]? | select(.action == "changed")] | length) as $modified
       | modified_details($modified <= 3) | select(. != "") ),
     (if data_count > 0 then data_details else empty end)
   else too_long
   end),
  footer
] | join("\n\n")
