# Pkl strings use \u{codepoint}, rather than JSON's \uXXXX escapes.
def hex:
  if . < 16 then "0123456789abcdef"[.:.+1]
  else ((. / 16 | floor | hex) + (. % 16 | hex)) end;

def pkl_string:
  if . == null then "null"
  else "\"" + (explode | map(
    if . == 34 then "\\\""
    elif . == 92 then "\\\\"
    elif . < 32 or . == 127 then "\\u{" + hex + "}"
    else [.] | implode end
  ) | join("")) + "\"" end;

def render_manifest:
  . as $workspace |
  ["amends \".workspace/Workspace.pkl\"", "", "task {",
   "  name = \(.task.name | pkl_string)",
   "  description = \(.task.description | pkl_string)",
   "  branch = \(.task.branch | pkl_string)", "}", "", "repositories {",
   (.repositories[] |
     "  new {",
     "    host = \(.host | pkl_string)",
     "    slug = \(.slug | pkl_string)",
     "    baseBranch = \(.baseBranch | pkl_string)",
     (if .branch != $workspace.task.branch then "    branch = \(.branch | pkl_string)" else empty end),
     "    initialHead = \(.initialHead | pkl_string)",
     "  }"),
   "}", "", "appendix {", "  notes {",
   (.appendix.notes[] | "    new {", "      body = \(.body | pkl_string)", "    }"),
   "  }", "  links {}", "}", ""] | join("\n");

# Pkl 0.27-0.31 --root-dir rejects some non-ASCII import URIs. Its module
# allowlist checks both requested and resolved paths, including symlinks.
# Accept raw and percent-encoded URI characters within each workspace root.
def module_pattern:
  "file:/+" + (ltrimstr("/") + "/" | explode | map(
    . as $point | ([.] | implode) as $char |
    if $char == "/" then "/"
    elif ($char | @uri) == $char then "\\x{" + ($point | hex) + "}"
    else "(?:\\x{" + ($point | hex) + "}|(?i:" + ($char | @uri) + "))" end
  ) | join(""));
