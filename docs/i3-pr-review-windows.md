# Research: nicer window naming + tabbed/stacked layout for the pr-review workspaces

Background for `scripts/pr-review.sh` and the `assign`/`for_window` rules in `i3`.

Verified against the live setup: i3 4.25.1, alacritty 0.17.0, Chromium 150, `font pango:monospace 12`.
All probes ran on a hidden scratch workspace `zzlab`, then cleaned up.

**Decisions taken from this** — the terminal moves to WM_CLASS routing and the workspaces go
stacked; the browser keeps `--new-window` on the default profile for now, so §2's Chromium
findings (`--class` handoff, `--app=`, dedicated `--user-data-dir` instances) are recorded
for later rather than acted on.

## 1. What i3 can match on

From the i3 userguide: criteria are `class`, `instance`, `window_role`, `window_type`,
`machine`, `id`, `title`, `urgent`, `workspace`, `con_mark`, `con_id`, `floating`,
`tiling`, `floating_from`, `tiling_from`, `all`.

> "The criteria class, instance, role, title, workspace, machine and mark are actually
> regular expressions (PCRE)."

So **yes — prefix/suffix matching already works today.** `assign [title="^pr-review-requested"] $ws9`
would let you append PR info after a stable prefix without touching anything else.

But `title` is the worst property to route on:

> "The difference between assign and for_window … is that the former will only be executed
> when the application maps the window" … "Some applications first create their window, and
> then worry about setting the correct title." Therefore matching on class/instance is
> recommended over title.

That is exactly the constraint already documented in `launch_review()`:
`--title` is what i3 assigns on, and claude's `--name` retitles right afterwards.

## 2. What each program lets you set (all verified)

### alacritty — full control, no caveats

`--class <class>[,<instance>]` (`alacritty --help`). Probe result:

    --class prrlabgeneral,prrlabinstance  ->  i3 class 'prrlabgeneral', instance 'prrlabinstance'

WM_CLASS never changes after map, so routing is rock-solid **and the title is freed
entirely** for claude's `--name`.

#### `--title` freezes the title — claude's `--name` is currently dead weight

Verified: `alacritty --title pr-review-reviewed -e sh -c 'printf "\033]0;OSC-SET-THIS\007"; sleep'`
→ i3 still reports title `pr-review-reviewed`. Passing `--title` on the CLI suppresses
later OSC-0 title changes (`dynamic_title` is at its default `true`; the dotfiles
`alacritty.toml` doesn't set it, and non-review terminals do show claude's titles).

This explains the live tree: every ws9/ws10 review terminal reads `pr-review-requested`,
never `Review(<n>): <title>`. So the `--name "$REVIEW_CLAUDE_NAME"` passed in
`launch_review()` has no visible effect today. Dropping `--title` in favour of `--class`
makes it start working.

### chromium — three options, different trade-offs

| flag | i3 class | i3 instance | title | works on the running browser? |
|---|---|---|---|---|
| `--window-name=X` (today) | `Chromium` | `chromium` | **frozen to X forever** | yes |
| `--class=X` | `X` | `chromium (<profile path>)` | live page title | **NO — silently dropped** |
| `--app=<url>` | `Chromium` | derived from the URL | live page title, no " - Chromium" | yes |

- `--class=X` verified dropped: launching against the already-running default-profile
  browser left WM_CLASS at `Chromium`/`chromium`. Chromium forwards `--new-window` to the
  existing process, which computes WM_CLASS from *its own* command line. It only works with
  a separate `--user-data-dir` (verified: class `prrlabchrome`).
- `--window-name` is honoured even when forwarded, and permanently overrides WM_NAME —
  the live ws9 windows still read `pr-review-requested` while sitting on PR pages. Full
  control of the title, but no live page title.
- `--app=` verified: `--app=file:///tmp/claude-1000/i3lab/lab.html` → instance
  `tmp_claude-1000_i3lab_lab.html`, title `PR 46517 lab page`. For a PR URL expect
  something like `github.com__ignite-analytics_main_pull_46517` — **confirm at
  implementation time**. Note the instance can't distinguish the requested vs authored
  queues (both are github PR URLs), and `--app` windows have no tab bar/omnibox.
- Footnote, untested: the binary also exposes `--window-workspace=N` (sets
  `_NET_WM_DESKTOP`). Index-based, so brittle against named workspaces.

#### Can tabs be aimed at one specific existing window? Only via a separate instance.

There is no CLI switch that names a target window. Chromium's ProcessSingleton forwards the
URL to the running browser process, which hands it to `BrowserList::GetLastActive()` — hence
review tabs scattering into whichever window was last touched. CDP (`Target.createTarget`)
has `newWindow`/`background` but no window id either, so remote debugging doesn't help.

What does work, verified: **a dedicated `--user-data-dir` is its own singleton**, so URLs
launched with it can only land in *its* windows.

    # 1st: creates the review window (and --class IS honoured here)
    chromium --user-data-dir=$P --class=prreviewlab --new-window <url1>
    # 2nd: no --new-window, while the DEFAULT-profile browser is the last-active one on screen
    chromium --user-data-dir=$P <url2>

Window count stayed at 8 across the second launch, and the dedicated window's title went
`PR 46517 lab page` → `SECOND lab page`. The tab landed in the review instance, ignoring
the default instance's last-active window entirely.

Notes:
- The instance string encodes the profile path — `chromium (/tmp/claude-1000/i3lab/chromeprofile)`
  — so two review profiles are distinguishable by `instance` even without `--class`.
- `--class` is fixed by the *first* launch's command line, so one profile = one WM_CLASS =
  one workspace. Splitting requested/reviewed across ws9 and ws10 needs two profiles.
- Cost: separate cookie jar per profile, so one GitHub login each, plus one extra browser
  process per profile.
- `--profile-directory=<name>` inside the *default* `--user-data-dir` would also scope
  "last active" to that profile while sharing the process, but it shares neither cookies nor
  the command line — so it costs a login without unlocking `--class`. Untested; little upside.
- Within the review instance, "last active window" still applies, so keep it to one window
  per queue if you want deterministic placement.

## 3. Layout: what actually works, without stealing focus

Criteria-based commands act on matched containers **without focusing them**, so none of
this yanks you to ws9. `focus` and `append_layout` would; avoid both.

### Making the workspace stacked/tabbed — converges cleanly

`[criteria] layout stacking` run once per new window settles on exactly **one**
workspace-level stacked container. Verified with 4 windows arriving one at a time:

     workspace 'zzlab'        layout splith
       con                    layout stacked
         con  prrlab1
         con  prrlab2
         con  prrlab3
         con  prrlab4

Why: i3's `con_set_layout` retargets a leaf to its parent, and for a `CT_WORKSPACE` parent
with children it wraps them in a new split container. After the first call the wrapper
exists, later arrivals attach *inside* it, and the call is a no-op. No accumulation.

So `for_window [class="^pr-review-"] layout stacking` is sufficient — no global
`workspace_layout`, no startup hack, no empty-workspace trick.

### Pairing browser + claude in one group — works, but costs readability

Fully focus-free recipe, verified step by step:

    i3-msg '[instance="^prr-46517-claude$"] mark --replace prr46517'
    i3-msg '[instance="^prr-46517-claude$"] split v'
    i3-msg '[instance="^prr-46517-web$"]    move container to mark prr46517'
    i3-msg '[instance="^prr-46517-web$"]    layout tabbed'

Resulting tree (verified):

     workspace
       con                    layout tabbed
         con  prr-46517-claude   marks ['prr46517']
         con  prr-46517-web

Two problems:

1. **Container titles are not window titles.** i3 renders a split container's decoration
   from `con_get_tree_representation()`, whose recursion ends at a leaf returning
   `con->window->class_instance`. So the group's row reads `T[prr-46517-claude
   github.com__..._46517]` — WM_CLASS instance, not the PR title, and `%title` /
   `title_format` / the status dots do not apply to it. The pairing costs exactly the
   readability being chased.
2. **Groups nest.** Verified: with a second PR, its group landed *inside* the first group's
   tabbed container rather than beside it. Fixable (re-move it to workspace level first),
   but it's extra machinery.

### Not recommended: append_layout

`append_layout` + `swallows` (class/instance/title/window_role/machine, all PCRE) does
create real tabbed placeholder groups, and "swallowing windows into unsatisfied placeholder
windows takes precedence over assignment rules". But it appends to the *focused* workspace
(so it steals focus) and one placeholder swallows one window — a fixed pool, no good for an
open-ended stream of PRs.

## 4. The plan

**Flat stacking on ws9/ws10, terminal routed on WM_CLASS, browser routed on a title prefix,
all the identifying information in the title.** Stacking over tabbed because every window
then gets a full-width title row, so a long PR title fits; tabbed divides one bar N ways,
which is the same squish rotated.

Four steps, one commit each.

1. **Terminal routes on WM_CLASS.** `alacritty --class pr-review-requested,prr-<repo>-<n>`,
   with `--title` dropped so claude's `--name` can reach the title bar at all (see §2).
   i3 gains `assign [class="^pr-review-requested$"] $ws9` and the `-reviewed` equivalent for
   `$ws10`; the pre-existing title rules stay for the browser and get anchored.
2. **Stacking.** `for_window [class="^pr-review-"] layout stacking` for the terminals plus
   `for_window [title="^pr-review-"] layout stacking` for the browser windows. Either one is
   enough to convert the workspace once it fires, but ws10 can receive a browser with no
   terminal (the merge notification), so both are needed.
3. **Informative titles.** Browser `--window-name="pr-review-requested <repo>#<n> <title>"`
   and claude `--name "<repo>#<n> <title>"`. The repo matters because three repos are polled.
   Keeping `pr-review-requested` as the browser's *prefix* means step 2's rules and the
   `assign` rules need no further change — and unanchored i3 regexes match anywhere, so the
   existing rules already tolerate the longer title. It costs ~20 characters of a full-width
   row, which is affordable.
4. **Per-window status dots.** Land the `title_format` work (§6). It only becomes useful once
   the rows are distinguishable, and stacking is what makes the dot visible.

### Phase 2 (agreed, deliberately not implemented yet)

**Pair each PR's two rows by adjacency, not by nesting.** After both windows map, mark the
terminal and move the browser to that mark:

    i3-msg '[instance="^prr-main-46517$"] mark --replace prr-main-46517'
    i3-msg '[title="^pr-review-requested main#46517"] move container to mark prr-main-46517'

Both commands are criteria-based, so neither steals focus. The pair then sits one keypress
apart in the stack with both titles still fully rendered — which is the readable half of the
tabbed-group idea without either of its two problems above.

Deferred because it needs a wait-for-map loop in `launch_review()` (the browser is spawned
from `send_notification()`, so the two halves have to rendezvous), and the interleaving may
well not be annoying enough in practice to justify that. Revisit after living with steps 1-4.

## 5. Alternatives to the whole approach

- **A. One browser window, N tabs, in a dedicated instance.** Persistent
  `--user-data-dir=~/.local/share/chromium-review` + `--class=pr-review-requested`, and drop
  `--new-window` after the first launch. Verified above: tabs then land in *that* window
  regardless of what was last active. Browser squish disappears entirely, Chrome's own tab
  bar is a better tab UI than i3's, `--class` gives stable routing, and page titles stay
  live. ws9 becomes 1 browser + N stacked claude terminals. Costs one GitHub login and one
  extra browser process; two workspaces would need two profiles.
- **B. Keep `--new-window` on the default profile.** Status quo placement (title-based, no
  extra login), fixed by stacking so the windows stop squishing. Zero browser gymnastics.
- **C. `--app=<pr-url>` per PR.** Chrome-less reading pane, live page title, per-PR
  instance. Can't split the two queues by instance, and no omnibox for navigating away.
- **D. Skip the browser for the first pass.** Have the review session surface the diff and
  comments in-terminal (`gh pr diff`, `gh pr view --comments`) and open the browser only
  when you actually need to comment. Halves the window count on ws9.
- **E. One workspace per PR instead of one per queue.** Move each pair to a named
  workspace (`move container to workspace "46517 upgrade MUI"`) and add a rofi workspace
  picker. Nothing is ever squished — you switch PRs rather than tile them. Costs a growing
  workspace list and a keybind.
- **F. `title_format` for icons.** `for_window [class="^pr-review-"] title_format "…"` can
  prefix a glyph per window kind — but see the conflict in §6.

## 6. Interaction with the title-dots work

Landed as step 4, in `scripts/claude-i3-notify.sh` and `scripts/claude-status-block.sh`.

- **Complementary, no rework needed.** It renders the dot as
  `title_format "<span foreground='#FFA500'>●</span> %title"`, which composes with whatever
  WM_NAME is. It deliberately does not touch WM_NAME, so the routing change is orthogonal.
  Markup renders because `i3` line 19 is `font pango:monospace 12`, and pango attribute
  values must be **single**-quoted — a nested `"` ends i3's command string and the remainder
  parses as a second, bogus command.
- **Steps 1-3 removed its stated limitation.** Its follow-up — "dots say which window, not
  which PR" — existed only because the terminal was titled `pr-review-requested` to satisfy
  the title-based `assign`. With `--class` routing and claude's `--name`, the row reads
  `● main#46517 web: upgrade MUI from 7 to 9`. No extra retitle needed.
- **`title_format` has exactly one owner: the hook.** It resets to plain `"%title"` on
  `clear`, so anything else that set a static prefix through `title_format` would be wiped.
  Identity belongs in WM_NAME.
- **Stacking amplifies it.** Dots sit in full-width stack rows instead of a bar split eight
  ways, which is where they were invisible.
- The dot marker lives in `titles/<sid>`, not the state file, because the blocklet deletes a
  `done` state when its workspace is focused. Confirmed live during the step-4 test: at
  `done` the state file was gone within the same second (ws4 was focused) while the marker
  and the green dot survived — which is the whole reason for the separate file.
- Dots only cover claude windows; browser windows never get one. Phase 2's adjacency would
  put the flagged claude row next to its browser row.

## Sandbox notes

- `i3-msg` is blocked in the sandbox: `Could not create socket: Operation not permitted`
  (the IPC socket lives under `/run/user/1000/i3/`). All probes needed
  `dangerouslyDisableSandbox: true`. Same finding as the dots report.
- Trying to run the probes in an isolated `Xvfb :99` instead failed: the X server needs to
  write `/tmp/.X11-unix/X99`, which is outside the writable allowlist, and this Xvfb build
  has no `-unixdir` option. `-listen tcp -nolisten unix` also failed to come up.
