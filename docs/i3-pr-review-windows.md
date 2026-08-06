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
- **The value lands in WM_NAME verbatim** — chromium appends no `" - Chromium"` suffix.
  Verified against a live ws9 window, whose `name` was exactly the string passed. This is
  what makes an end-anchored (`…$`) i3 title regex safe; see §7.
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
   *(Superseded by step 5 — the prefix is what made the two rows unpairable by eye.)*
4. **Per-window status dots.** Land the `title_format` work (§6). It only becomes useful once
   the rows are distinguishable, and stacking is what makes the dot visible.
5. **Queue token moved to the end of the browser title** (§7). Both rows for a PR now open
   with the same `<repo>#<n>`.
6. **`no_focus` on the review windows** (§8), so a newly polled PR can't take the keyboard
   while another one is being read.

### Phase 2 (still not implemented — but the objections below no longer hold)

**Pair each PR's two rows by adjacency, not by nesting.** After both windows map, mark the
terminal and move the browser to that mark:

    i3-msg '[instance="^prr-main-46517$"] mark --replace prr-main-46517'
    i3-msg '[class="^Chromium$" title="^main#46517 "] move container to mark prr-main-46517'

**Verified on a scratch workspace** (i3 4.25.1, four windows spawned interleaved
`Aterm, Bterm, Aweb, Bweb` into one stacked container):

- **Sibling adjacency, no nesting.** With a *leaf* target, `move container to mark` inserts
  the container immediately **after** the mark in the target's parent. Result was
  `stacked [ Aterm, Aweb, Bterm, Bweb ]` — one stacked container, four leaves, no new level.
  §3's two objections (unreadable `T[…]` container decorations, groups nesting inside each
  other) came from the `split v` variant, which is **not needed**. Both rows keep rendering
  their own full titles, dots included.
- **No focus steal.** The focused workspace and focused window were unchanged across two
  mark+move pairs, exactly as §3 predicted for criteria-based commands.
- **Clean no-ops on failure.** A missing mark gives `{"success":false}` and moves nothing
  (verified against a live ws9 window, which stayed put); criteria matching no window gives
  `{"success":false,"error":"Given criteria don't match a window"}`. So an opportunistic
  pairing attempt on ws10 — where the authored PR's terminal may be long gone by the time
  its review browser opens — costs nothing when the mark isn't there.

Still needed to land it: a `pair_windows <repo> <number>` helper polling `i3-msg -t get_tree`
until both windows exist (bounded, ~30s), launched with `setsid -f` so it is tied to neither
`send_notification()`'s 30s dunstify block nor the poller's lifetime. Plus `i3-msg` in
`start-pr-review.sh`'s `verify` list.

Two things to get right:

- **Never interpolate the PR title into an i3 criterion.** Criteria are PCRE and real titles
  contain metacharacters — `refactor(PRO-2119)` is a live capture group. Only `<repo>#<n>` is
  safe to interpolate, and it needs anchoring (`^main#46517 `) so `main#4651` can't match
  `main#46517`.
- **Since step 5, `^main#46517 ` matches the terminal too**, so the browser criterion must be
  qualified with `class="^Chromium$"`.

Remaining cost: the move reorders the ws9 stack. Focus is preserved, but rows shift if you
happen to be reading ws9 at that second.

**Cheaper alternative considered:** serialise the spawns — split `send_notification()` into
`open_browser` + `notify`, wait for the browser to map, then `launch_review()`. Natural map
order then pairs them with no i3 machinery at all. Rejected as insufficient: it only fixes
ordering *within* one poller, and three pollers run concurrently, so cross-repo interleaving
(a `dataform#239` row landing between the two `main#46729` rows) survives. Marks fix that;
ordering does not.

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

## 7. Queue token at the end of the browser title (landed)

The two rows for one PR shared nothing at the start of their titles, so a stacked ws9 could
not be read as pairs:

    class pr-review-requested   ✳ main#46729 refactor(PRO-2119): initial setup as…
    class Chromium              pr-review-requested main#46729 refactor(PRO-2119): initial…

chromium's `--class` is dropped on the shared profile (§2), so the title is the browser's
only routing signal and the queue token has to stay in it. Moving it to the **end** and
anchoring the regexes with `$` gives both rows the same `<repo>#<n>` opening:

    assign     [title="pr-review-requested$"] $ws9
    assign     [title="pr-review-reviewed$"]  $ws10
    for_window [title="pr-review-(requested|reviewed)$"] layout stacking

Safe because `--window-name` reaches WM_NAME verbatim (§2) — nothing can be appended after
the token, so the end anchor cannot drift. The `class="^pr-review-"` rules are untouched.

Two accepted trade-offs:

- **The token truncates on long titles.** The browser row already overflows 3440px. Routing
  is unaffected (i3 matches WM_NAME, not the rendering) and the workspace already says which
  queue it is, so this only costs a redundant visual cue.
- **`^<repo>#<n>` now matches both windows.** Only matters for Phase 2 criteria, which must
  add `class="^Chromium$"`.

## 8. Focus: new review windows no longer steal it (landed)

`no_focus [criteria]` exists in this i3 (4.25.1 — `cfg_no_focus` in the binary, with runtime
messages `no_focus was set for con = %p, not setting focus` and `This is the first window on
this workspace, ignoring no_focus`):

    no_focus [class="^pr-review-"]
    no_focus [title="pr-review-(requested|reviewed)$"]

**It composes with the stacking from §3.** An unfocused child of a stacked container is drawn
entirely behind the focused one, so a new arrival adds a title row and nothing else — the
"spawn in the back" behaviour, with no scratchpad tricks.

Scope of the problem, measured:

- **Hidden workspaces were never affected.** On a scratch workspace with no output showing
  it, the workspace's focus head stayed on the first window in *both* a control run and a
  `no_focus` run. i3 simply does not move focus for windows mapping out of view.
- **There is one output** (`DP-4`, 3440x1440), so ws9/ws10 are only ever visible while
  standing on them. That is the only case `no_focus` changes — and the only case that was
  ever annoying.
- **Not measured: the visible case.** Testing it means parking the user on the test
  workspace for ~20s of deliberate focus-stealing, which is worse than the bug. The code path
  is the same `no_focus` check at manage time, and real use answers it on the next PR.

Caveats:

- **The first window on a workspace is always focused**, `no_focus` or not — i3 says so
  explicitly. Desirable: switching to an empty ws9 still lands somewhere.
- **`no_focus` covers map time, not activation.** If chromium later asks to be raised via
  `_NET_ACTIVE_WINDOW`, the *global* `focus_on_window_activation` decides. It is unset here,
  so the default `smart` applies, which **does** focus a window on a visible workspace. If
  `no_focus` alone leaks, the escalation is `focus_on_window_activation urgent` — but that is
  global and would also stop e.g. a Slack link from raising the browser. Only if needed.

Unrelated, noticed while measuring: `i3` pins `workspace $ws9 output HDMI1` and `$ws10 output
HDMI1`, an output that does not exist on this machine. Dead lines; i3 falls back to `DP-4`.

## Sandbox notes

- The live config is `/home/amund/.dotfiles/i3` itself, not `/etc/i3/config` (which exists
  and differs). Confirmed with `i3-msg -t get_version | jq -r .loaded_config_file_name` —
  worth doing before editing, since neither `~/.config/i3/config` nor `~/.i3/config` exists.
- Testing config directives (`no_focus`, `assign`, `for_window`) means editing that file and
  running `i3-msg reload`; they are not accepted by the command parser at runtime. Validate
  with `i3 -C -c <file>` first, and expect each reload to be a visible flicker on screen.
- `i3-msg` is blocked in the sandbox: `Could not create socket: Operation not permitted`
  (the IPC socket lives under `/run/user/1000/i3/`). All probes needed
  `dangerouslyDisableSandbox: true`. Same finding as the dots report.
- Trying to run the probes in an isolated `Xvfb :99` instead failed: the X server needs to
  write `/tmp/.X11-unix/X99`, which is outside the writable allowlist, and this Xvfb build
  has no `-unixdir` option. `-listen tcp -nolisten unix` also failed to come up.
