#!/usr/bin/env python3
"""Generate Bash() permission entries for known-safe git/gh commands.

Output matches the style used in ~/.claude/settings.json:
  - 6-space indent (three levels of 2-space)
  - Blank line between logical groups
  - Trailing comma on every line except the last

Read-only ("safe") means: cannot be abused to write to the network or to
the local filesystem.

Extending:
  - Add a new gh subcommand+action to GH_SAFE_ACTIONS
  - Add a new git command to GIT_SAFE: key is the subcommand, value is a
    list of allowed argument tails ("" for the bare form)
  - Adjust GH_SCOPE_PREFIXES / GIT_SCOPE_PREFIXES to enable / disable
    pre-subcommand scope-flag variants

Pre-subcommand scope flags (`gh -R <repo>`, `git -C <path>`) are emitted
once per entry in SAFE_GH_REPOS / SAFE_GIT_PATHS. No wildcards are used
for the repo / path token — only explicit, audited values.

Modes:
  - default: emit `Bash(...)` allow entries
  - --excluded: emit `sandbox.excludedCommands` entries (bare command
    prefixes, no wildcards). `gh` collapses to a single `gh` line; `git`
    expands to one line per unique prefix in GIT_SAFE (with each scope
    variant).
"""

from __future__ import annotations

import argparse

INDENT = " " * 6

# Explicit lists of repositories (gh) and working-tree paths (git) that
# may be passed via -R / -C / --repo / --git-dir / --work-tree. Add
# entries here when you start working in a new repo.
SAFE_GH_REPOS: list[str] = [
    "Amund211/rainbow",
    "Amund211/flashlight",
    "Amund211/prism",
]

SAFE_GIT_PATHS: list[str] = [
    "/home/amund/git/overlay/rainbow",
    "/home/amund/git/overlay/flashlight",
    "/home/amund/git/overlay/prism",
]


# ---------------------------------------------------------------------------
# Data: the known-safe commands. Extend here.
# ---------------------------------------------------------------------------

# gh: each entry is "<subcommand> <action>" (or just "<subcommand>" for
# top-level commands like `gh search`). All gh entries get a trailing `:*`
# wildcard, so any flags after the action are permitted — including a
# trailing `-R foo/bar`.
GH_SAFE_ACTIONS: list[str] = [
    "search",
    "issue view",
    "issue list",
    "pr view",
    "pr list",
    "pr diff",
    "pr checks",
    "repo view",
    "run view",
    "run list",
    "release view",
    "release list",
    "label list",
    "workflow view",
    "workflow list",
]

# Pre-subcommand scope flag forms for gh. Each {repo} is filled with
# REPO_PLACEHOLDER. Comment a line out to skip that variant.
GH_SCOPE_PREFIXES: list[str] = [
    "-R {repo}",
    "-R={repo}",
    "--repo {repo}",
    "--repo={repo}",
]

# git: key is the subcommand+fixed-tokens, value is a list of allowed
# argument tails. "" means the bare command with no args. git entries
# are exact matches (no trailing `:*`) — so each variant must be listed.
GIT_SAFE: dict[str, list[str]] = {
    "fetch": [
        "",
        "--prune",
        "--tags",
        "--all",
        "--all --prune",
        "origin",
        "upstream",
    ],
    "pull": [
        "",
        "--ff-only",
    ],
    "ls-remote": [""],
    "remote show": [""],
    "remote -v": [""],
    "remote get-url": ["origin", "upstream"],
}

# Pre-subcommand scope flag forms for git. {path} is filled with
# PATH_PLACEHOLDER.
GIT_SCOPE_PREFIXES: list[str] = [
    "-C {path}",
    # Uncomment to also allow --git-dir / --work-tree forms:
    # "--git-dir {path}",
    # "--git-dir={path}",
    # "--work-tree {path}",
    # "--work-tree={path}",
]


# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------


def gh_entries() -> list[str]:
    """Build gh entries: bare form + one scope-prefix entry per safe repo."""
    out: list[str] = []
    for action in GH_SAFE_ACTIONS:
        out.append(f"gh {action}:*")
        for prefix in GH_SCOPE_PREFIXES:
            for repo in SAFE_GH_REPOS:
                scope = prefix.format(repo=repo)
                out.append(f"gh {scope} {action}:*")
    return out


def git_entries() -> list[str]:
    """Build git entries: bare form + one scope-prefix entry per safe path."""
    out: list[str] = []
    for cmd, tails in GIT_SAFE.items():
        for tail in tails:
            full = f"{cmd} {tail}".rstrip()
            out.append(f"git {full}")
            for prefix in GIT_SCOPE_PREFIXES:
                for path in SAFE_GIT_PATHS:
                    scope = prefix.format(path=path)
                    out.append(f"git {scope} {full}")
    return out


def gh_excluded_entries() -> list[str]:
    """Build gh entries for sandbox.excludedCommands: a single `gh` line."""
    return ["gh *"]


def git_excluded_entries() -> list[str]:
    """Build git entries for sandbox.excludedCommands: one line per unique
    prefix in GIT_SAFE, plus a scoped variant for each safe path."""
    out: list[str] = []
    seen: set[str] = set()
    for cmd in GIT_SAFE:
        bare = f"git {cmd}"
        if bare not in seen:
            seen.add(bare)
            out.append(bare)
        for prefix in GIT_SCOPE_PREFIXES:
            for path in SAFE_GIT_PATHS:
                scope = prefix.format(path=path)
                scoped = f"git {scope} {cmd}"
                if scoped not in seen:
                    seen.add(scoped)
                    out.append(scoped)
    return [f"{entry} *" for entry in out]


def render(groups: list[list[str]], wrap: bool = True) -> str:
    """Render groups of entries as JSON-array lines.

    Indented six spaces, blank line between groups, trailing comma on
    every entry except the very last one. When ``wrap`` is true each
    entry is wrapped as ``"Bash(<entry>)"``; otherwise the entry is
    quoted verbatim (for sandbox.excludedCommands).
    """
    flat: list[str] = []
    for i, group in enumerate(groups):
        if i > 0:
            flat.append("")  # blank line separator
        if wrap:
            flat.extend(f'"Bash({entry})"' for entry in group)
        else:
            flat.extend(f'"{entry}"' for entry in group)

    last_entry_idx = max(i for i, line in enumerate(flat) if line)
    lines: list[str] = []
    for i, line in enumerate(flat):
        if line == "":
            lines.append("")
        elif i == last_entry_idx:
            lines.append(f"{INDENT}{line}")
        else:
            lines.append(f"{INDENT}{line},")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Bash() permission entries for known-safe git/gh commands."
    )
    parser.add_argument(
        "--excluded",
        action="store_true",
        help="Emit sandbox.excludedCommands entries instead of Bash() allows.",
    )
    args = parser.parse_args()
    if args.excluded:
        print(render([gh_excluded_entries(), git_excluded_entries()], wrap=False))
    else:
        print(render([gh_entries(), git_entries()]))


if __name__ == "__main__":
    main()
