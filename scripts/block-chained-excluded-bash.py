#!/usr/bin/env python3
"""
PreToolUse hook: deny Bash calls that combine a sandbox-excluded command with
shell chaining/loops/substitution.

Why: commands listed in `sandbox.excludedCommands` run OUTSIDE the sandbox.
If they're chained with `&&`, `||`, `;`, `$(...)`, backticks, `<(...)`,
`>(...)`, or for/while loops, the rest of the chain inherits that escape
hatch. We want the excluded list to mean "simple invocation only".

Exceptions (allowed):
  - File redirection with bare `>` / `>>` / `<` (not in CHAINING_TOKENS).
  - Piping (`|`) into stdout-only filters listed in SAFE_PIPE_TARGETS, e.g.
    `gh pr view 123 | head -20`. The whole pipeline still runs outside the
    sandbox, but these filters only consume stdin and emit stdout.

Wire into ~/.claude/settings.json (merge into existing top-level keys):

    {
      "hooks": {
        "PreToolUse": [
          {
            "matcher": "Bash",
            "hooks": [
              {
                "type": "command",
                "command": "/home/amund/.dotfiles/scripts/block-chained-excluded-bash.py"
              }
            ]
          }
        ]
      }
    }

Make sure it's executable: chmod +x <path>.

Behavior:
  - Reads PreToolUse hook input JSON from stdin.
  - If tool_name != "Bash", allows.
  - Loads sandbox.excludedCommands from ~/.claude/settings.json on each
    invocation (so edits to the settings list take effect immediately, no
    restart needed). If the file is missing/malformed/empty, the script
    becomes a no-op.
  - Quote-strips the command, looks for any chaining token, and if found AND
    any excluded prefix appears as a command-position token, denies with a
    clear reason. All other cases allow (exit 0, no output).
"""

import json
import os
import re
import sys

SETTINGS_PATH = os.path.expanduser("~/.claude/settings.json")


def _normalize_pattern(pat: str) -> str:
    """Strip a trailing wildcard so a pattern like "gcloud *" becomes the
    literal prefix "gcloud" we can match against the start of the command."""
    pat = pat.rstrip()
    if pat.endswith(" *"):
        return pat[:-2]
    if pat.endswith("*"):
        return pat[:-1].rstrip()
    return pat


def load_excluded_prefixes(path: str = SETTINGS_PATH) -> list[str]:
    """Read sandbox.excludedCommands from a settings.json file.
    Returns [] on any error so the hook fails open (allows the call)."""
    try:
        with open(path) as f:
            data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return []
    raw = data.get("sandbox", {}).get("excludedCommands", [])
    if not isinstance(raw, list):
        return []
    prefixes = []
    for p in raw:
        if not isinstance(p, str):
            continue
        norm = _normalize_pattern(p)
        if norm:
            prefixes.append(norm)
    return prefixes

# Tokens that escape "this is a single simple command".
# Note: r"\|\|" comes before r"\|" so it wins at the same position.
CHAINING_TOKENS = [
    (r"&&", "&&"),
    (r"\|\|", "||"),
    (r";", ";"),
    (r"\|", "|"),
    (r"\$\(", "$("),
    (r"`", "`"),
    (r"<\(", "<("),
    (r">\(", ">("),
    (r"\n", "newline"),
]
CHAINING_RE = re.compile("|".join(t[0] for t in CHAINING_TOKENS))

# Same set minus single-pipe — used to detect chaining that we never allow.
NON_PIPE_CHAINING_RE = re.compile(r"&&|\|\||;|\$\(|`|<\(|>\(|\n")

# Commands that only consume stdin and produce stdout. Safe to allow after a
# pipe even when the upstream command runs outside the sandbox.
SAFE_PIPE_TARGETS = {
    "head", "tail", "grep", "egrep", "fgrep", "rg",
    "wc", "sort", "uniq", "cut", "tr", "awk", "sed",
    "jq", "yq", "cat", "less", "more", "column", "rev", "nl",
    "base64",
}


def strip_quoted_regions(s: str) -> str:
    """Best-effort: drop content inside '...', "...", and `...` so we don't
    false-positive on chaining tokens that appear inside string literals.
    Not a real shell parser — heredocs and exotic escaping aren't handled."""
    out = []
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c in ("'", '"', "`"):
            j = i + 1
            while j < n and s[j] != c:
                # In double quotes / backticks, backslash escapes the next char
                if c != "'" and s[j] == "\\" and j + 1 < n:
                    j += 2
                    continue
                j += 1
            i = j + 1  # skip past closing quote (or end of string)
        else:
            out.append(c)
            i += 1
    return "".join(out)


def find_chaining(cleaned: str) -> str | None:
    m = CHAINING_RE.search(cleaned)
    return m.group(0) if m else None


# Word-ish boundaries: prefix must sit at start or after a separator, and end at
# a separator or end-of-string. Lets us treat `gcloud` as a command, not a
# substring of `gcloudish`.
_LEFT = r"(?:^|[\s;|&`(\n><])"
_RIGHT = r"(?:[\s;|&`)\n><]|$)"


def find_excluded_prefix(cleaned: str, prefixes: list[str]) -> str | None:
    # Try longest first so e.g. "git -C ... fetch" wins over "git fetch".
    for prefix in sorted(prefixes, key=len, reverse=True):
        pat = _LEFT + re.escape(prefix) + _RIGHT
        if re.search(pat, cleaned):
            return prefix
    return None


def split_pipes(cleaned: str) -> list[str]:
    """Split on `|` but not `||`. Quoted regions must already be stripped."""
    parts: list[str] = []
    buf: list[str] = []
    i, n = 0, len(cleaned)
    while i < n:
        if cleaned[i] == "|":
            if i + 1 < n and cleaned[i + 1] == "|":
                buf.append("||")
                i += 2
                continue
            parts.append("".join(buf))
            buf = []
            i += 1
            continue
        buf.append(cleaned[i])
        i += 1
    parts.append("".join(buf))
    return parts


def all_post_pipes_safe(cleaned: str) -> bool:
    """True iff every segment after the first `|` starts with a SAFE_PIPE_TARGETS
    command. If there are no pipes, vacuously True."""
    parts = split_pipes(cleaned)
    if len(parts) <= 1:
        return True
    for seg in parts[1:]:
        m = re.match(r"\s*([A-Za-z0-9_./-]+)", seg)
        if not m:
            return False
        cmd_name = os.path.basename(m.group(1))
        if cmd_name not in SAFE_PIPE_TARGETS:
            return False
    return True


def decide(command: str, prefixes: list[str]) -> tuple[str, str | None]:
    """Return ("allow", None) or ("deny", reason). Pure function — no I/O."""
    if not command:
        return "allow", None
    cleaned = strip_quoted_regions(command)
    if not find_chaining(cleaned):
        return "allow", None
    matched = find_excluded_prefix(cleaned, prefixes)
    if not matched:
        return "allow", None
    # Allow when the only chaining is `|` into stdout-only filters.
    if not NON_PIPE_CHAINING_RE.search(cleaned) and all_post_pipes_safe(cleaned):
        return "allow", None
    reason = (
        f"'{matched}' commands must run without chaining or loops. "
        f"Run the commands in the same order, but as separate Bash tool calls. "
        f"Allowed exception: piping into stdout-only filters "
        f"(head, tail, grep, wc, jq, sort, uniq, cut, tr, awk, sed, ...)."
    )
    return "deny", reason


def deny(reason: str) -> None:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )


# Fixture settings used by --test so results don't depend on the live
# ~/.claude/settings.json. Patterns intentionally mix wildcard styles so the
# test exercises _normalize_pattern: trailing " *", trailing "*" (no space),
# and a bare prefix with no wildcard.
_TEST_SETTINGS = {
    "sandbox": {
        "excludedCommands": [
            "npm run translations *",
            "gcloud *",
            "bq *",
            "go mod download *",
            "gh*",  # no space before wildcard
            "git fetch *",
            "git -C /home/amund/git/ignite/main fetch *",
            "git pull *",
            "git push",  # no wildcard at all
            "  ",  # whitespace-only — should be dropped
            42,  # non-string — should be dropped
        ]
    }
}

_EXPECTED_PREFIXES = {
    "npm run translations",
    "gcloud",
    "bq",
    "go mod download",
    "gh",
    "git fetch",
    "git -C /home/amund/git/ignite/main fetch",
    "git pull",
    "git push",
}

_TEST_CASES = [
    # (command, expected decision)
    ("gcloud projects list", "allow"),
    ("gcloud projects list && rm -rf foo", "deny"),
    ("echo hi | grep h", "allow"),
    ("echo hi && gcloud projects list", "deny"),
    ("for f in *.go; do gh issue create -f $f; done", "deny"),
    ("git fetch", "allow"),
    ("git fetch origin master", "allow"),
    ('echo "gcloud foo && bar"', "allow"),  # chaining is inside quotes
    ('git commit -m "add gcloud config"', "allow"),  # not an excluded prefix
    ("gcloud logging read --filter='severity>=ERROR'", "allow"),
    ("gh pr view 123 | head -20", "allow"),  # safe pipe filter
    ("gh pr view 123 | tail -5", "allow"),
    ("gh issue list | jq .", "allow"),
    ("gcloud projects list | grep foo | wc -l", "allow"),  # chain of safe filters
    ("gh issue list > issues.txt", "allow"),  # bare > redirection
    ("gh issue list | xargs rm", "deny"),  # xargs is not stdout-only
    ("gh pr view 123 | head && rm bar", "deny"),  # mix of pipe and &&
    ("$(gcloud projects list)", "deny"),  # command substitution
    ("git -C /home/amund/git/ignite/main fetch && echo done", "deny"),
    ("git push origin master", "allow"),  # no-wildcard prefix, simple call
    ("git push origin master && echo done", "deny"),  # no-wildcard prefix, chained
    ("git commit && git push", "deny"),
    ("ls && git push", "deny"),
]


def run_tests() -> int:
    import tempfile

    failed = 0
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".json", delete=False
    ) as f:
        json.dump(_TEST_SETTINGS, f)
        settings_path = f.name

    try:
        prefixes = load_excluded_prefixes(settings_path)
        loaded = set(prefixes)
        if loaded != _EXPECTED_PREFIXES:
            failed += 1
            print("FAIL  prefix parsing")
            print(f"  missing:  {sorted(_EXPECTED_PREFIXES - loaded)}")
            print(f"  extra:    {sorted(loaded - _EXPECTED_PREFIXES)}")
        else:
            print(f"OK    parsed {len(prefixes)} prefixes from settings.json")

        for cmd, expected in _TEST_CASES:
            decision, _ = decide(cmd, prefixes)
            ok = decision == expected
            mark = "OK  " if ok else "FAIL"
            if not ok:
                failed += 1
            print(f"{mark}  expected={expected:5s}  got={decision:5s}  cmd={cmd!r}")
    finally:
        os.unlink(settings_path)

    total = len(_TEST_CASES) + 1  # +1 for the parse check
    print(f"\n{total - failed}/{total} passed")
    return 0 if failed == 0 else 1


def main(argv: list[str]) -> int:
    if "--test" in argv:
        return run_tests()

    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0  # don't break Claude on bad input

    if payload.get("tool_name") != "Bash":
        return 0

    command = payload.get("tool_input", {}).get("command", "")
    decision, reason = decide(command, load_excluded_prefixes())
    if decision == "deny":
        deny(reason or "")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
