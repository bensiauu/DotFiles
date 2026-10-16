# Mission control v2: stay in the tab

Design for the next iteration of the Herdr mission-control tab
(`herdr/.config/herdr/mission-control/`). Builds on the v1 commit `eace610`
(one live card per coding agent).

## Intent

Ben runs several Claude Code sessions at once in Herdr. Today the
mission-control tab shows one card per agent, but he still has to jump into
the agent's own pane for most things: to read a full reply, to see what a
session's subagents are doing, to answer anything that is not yes/no, to
start a new task, or to close a finished one. The goal of v2 is that he stays
in mission control and only enters an agent's pane for genuine scrutiny (a
disagreement with the agent, a stuck tool, debugging the agent itself).

Observed failure that motivated this (screenshot, 2026-10-16): a card read
`WORKING 22m25s · 0 tools · 0 edits` because the real work was happening in
two background subagents the card could not see. The single `NOW`/`SAID`
pair was not enough to tell what the agent was actually doing.

## Goals

1. A card tells you what the agent is *actually* doing, including work done
   by its subagents.
2. A card can expand into a full-tab, read-only, live detail view without
   leaving mission control.
3. Any blocked prompt Claude Code shows (yes/no, numbered options, free
   text) can be answered from the card.
4. Start a new task from the tab: type the prompt, pick the project folder,
   launch.
5. Stop a finished session from the tab.

## Non-goals

- Replacing the agent pane. Anything interactive beyond "answer the
  prompt / send a reply" still happens there.
- Supporting agents other than Claude Code in the detail parsing. Cards for
  other Herdr agent kinds keep the v1 behaviour (status, title, cwd).
- Editing or resuming transcripts, or any write to `~/.claude`.
- Multi-machine / remote Herdr sessions.

## Anti-goals (would make it a failure even if it works)

- The card lies by omission: shows "working, 0 tools" while subagents churn.
- Expanding a card disturbs the grid (other cards move, close, or lose
  their agent).
- A start or stop action lands on the wrong agent/pane.
- The card process itself becomes heavy enough to slow Herdr or Claude
  (transcripts are up to ~8 MB per subagent; parse tails, never whole files).

## Constraints

- Python 3 stdlib only, same as v1 (no pip deps). OSS-only tooling.
- Data sources: `herdr api snapshot`, `herdr agent read --source detection`,
  and the Claude transcript JSONL files. No hooks into Claude Code are
  required, though the existing `~/.claude/hooks/ntfy-notify.sh` stays in
  use for blocked pushes.
- Herdr CLI surface verified available on this install:
  `pane zoom --on/--toggle`, `pane close <id>`, `pane split --direction
  --cwd --env`, `tab create --workspace --cwd --label --env --no-focus`,
  `agent start <name> --kind claude --pane <id> -- [args]`,
  `agent prompt <target> <text>`, `agent send-keys`, `agent focus`,
  `pane process-info`.
- Keep the catppuccin-latte 256-colour palette from v1; the terminal theme
  is light.
- Everything lives under `herdr/.config/herdr/mission-control/` in the
  DotFiles repo, stowed to `~/.config/herdr/mission-control/`.

## Transcript facts the builder can rely on (verified 2026-10-16)

- Main session transcript: `~/.claude/projects/<project-slug>/<session>.jsonl`.
  `session` is `agent_session.value` from the Herdr snapshot.
- Subagent transcripts: `~/.claude/projects/<project-slug>/<session>/subagents/agent-<agentId>.jsonl`.
  Same record format as the main transcript (`type` in user/assistant with
  `message.content` lists of text/tool_use/tool_result/thinking), with
  `isSidechain: true` and `agentId` on every record.
- Each subagent has a sidecar `agent-<agentId>.meta.json` next to its
  transcript with `agentType`, `description`, `toolUseId`, `spawnDepth`,
  `requestShape` (`background` for async) and, for grandchildren,
  `parentAgentId`. Grandchildren (`spawnDepth` 2+) sit flat in the same
  `subagents/` directory as their parents.
- The parent transcript links a subagent via the `Agent` tool call: the
  `tool_use` input has `description`, `subagent_type`, `model`; the matching
  `tool_result` record carries `toolUseResult.agentId`,
  `toolUseResult.description`, and `toolUseResult.status`
  (`async_launched` for background agents). A `<task-notification>` user
  record arrives when a background agent finishes, with `<status>` and
  `<tool-use-id>`.
- Edits: `tool_use` with name in Edit/Write/MultiEdit/NotebookEdit; input
  has `file_path` (or `notebook_path`).
- Context size: `message.usage` on assistant records
  (input + cache_read + cache_creation).

## The card (grid view)

Layout from top to bottom. Sections shrink or drop in the order given under
"Height budget" when the pane is short.

```
◐ WORKING 22m25s                          ⏎ reply · e expand · g go · x close   w2:p16 · claude
──────────────────────────────────────────────────────────────────────────────────────────────
merge-dashboards-into-apps
~/work/acm  ⎇ apps-only

ASKED    mission control wiring test, please ignore and continue
SAYING   Let me clean up that leftover unused variable…                 ← latest text, even mid-turn
NOW      Bash 42s  Wait for the dev Deploy run and read the image tag
TRAIL    ✎ card.py 3m · ▶ Bash pytest 2m ✗ · ✎ grid.py 1m · ▶ Bash pytest 40s ✓ · ⌕ Read README 12s
AGENTS   ◐ Build apps-only studio backend     Edit services/app.py        12s ago
         ◐ Build apps-only studio frontend    Bash npm test  (2 ✗)        3s ago
──────────────────────────────────────────────────────────────────────────────────────────────
turn 21m33s · 55 tools · 2 edits · 2 agents · 3 errors · 286k ctx
```

Changes from v1:

- **SAYING** replaces the v1 rule of "last complete reply only". It shows
  the most recent assistant `text` block in the current turn, whatever its
  position. When the turn has ended, SAYING is the final reply (so it is a
  superset of v1 SAID). Label reads `SAID` when the agent is idle/done and
  `SAYING` while working.
- **TRAIL** is a one- or two-line compact timeline of the last N tool calls
  in the current turn, newest on the right, each as `glyph short-label age`
  with `✗` for an error result. Glyphs: `✎` edit/write, `⌕` read/grep/glob,
  `▶` bash, `⇄` agent, `·` anything else. N is whatever fits in the width.
- **AGENTS** lists live subagents of this session: one row each with status
  glyph, the `description` from the Agent call, the subagent's own current
  tool (or last text if no tool is pending), error count if non-zero, and
  age of its last transcript write. A subagent is *live* when its Agent
  tool_use has no matching completion yet. In practice every Agent call in
  Ben's transcripts is async (`requestShape: background`), so the rule that
  matters is: live until a `<task-notification>` whose `<tool-use-id>`
  matches the Agent `tool_use` id. Treat a non-background agent as live
  until its `tool_result` arrives, but do not invest fixtures in that path.
  Fallback for both: an agent whose transcript has not been written for
  10 minutes is shown as `stale` rather than live.
  Finished subagents drop off the card but remain in the detail view.
  Grandchildren are included: a row for a depth-2 agent is indented one
  step under its parent row and attributed via `parentAgentId`. The
  footer `N agents` counts every live agent at any depth. This matters
  because work hidden one level deeper is the same bug this redesign
  fixes.
- **NOW** is unchanged but is suppressed when SAYING is more recent than
  the pending tool call started (the text is the better summary).
- **Header keys** now read `⏎ reply · e expand · g go · x close`, plus the
  blocked hint when blocked (see below).
- **Footer** gains `N agents` when the session has live subagents. The
  `tools` count includes subagent tool calls? **No**: footer counts stay
  main-session only, so the number matches what you see in TRAIL. The
  AGENTS rows carry their own counts.

Height budget (tallest first): header, title+cwd, ASKED (2 lines), NOW,
SAYING (up to 3 lines), AGENTS (one row per live agent, max 4, then
`+N more`), TRAIL, footer. When the pane is too short, drop in this order:
TRAIL, AGENTS rows beyond 2, SAYING lines beyond 1, ASKED second line.

## Blocked state on the card

v1 handles only yes/no/Esc. Claude Code dialogs come in three shapes; the
card must classify the dialog text (from `herdr agent read --source
detection`) and show the right hint:

| Shape | Detection | Card hint | Keys |
|---|---|---|---|
| yes/no permission | contains `Yes`/`No` options or `(y/n)` | `y / n / esc` | y, n, esc (then Enter for y/n, as v1) |
| numbered options | lines starting `1.` `2.` … or `❯ 1.` | `1-9 pick · esc` | digit → send-keys digit then enter |
| free text question | none of the above, or an input box glyph `›` | `⏎ answer · esc` | Enter opens the REPLY line; send via `herdr pane send-text <pane> <text>` then `agent send-keys <pane> enter` |

Classification is best-effort; when unsure, show all three hints.

**Delivery while blocked.** `herdr agent prompt` refuses with `agent_blocked`
whenever the agent's status is `blocked`, regardless of dialog shape
(verified in `herdr agent prompt --help`). So every blocked answer, including
free text, goes through the raw channel: `pane send-text` for the text and
`agent send-keys … enter` to submit (digits and y/n use `send-keys` alone,
as v1 does). `agent prompt` remains the path for the normal reply line when
the agent is idle, done, or working. The card's `act_reply` picks the channel
from the current status. The
NEEDS YOU banner and the ntfy/toast push stay as in v1. The blocked dialog
excerpt on the card grows from 6 lines to whatever fits in the body budget.

## Expanded view (`e`)

Press `e` on a card. The card calls `herdr pane zoom --on <own pane>`, so
it fills the mission-control tab while every other card keeps running
untouched. The same `card.py` process renders a different layout; no new
process. `e` or `Esc` (when not typing) calls `pane zoom --toggle` back.
`q` in expanded view also returns to the grid rather than quitting.

Expanded layout, scrollable with `j`/`k` (line) and `J`/`K` (half page),
`g`/`G` top/bottom… **conflict:** `g` already means "go to pane". Decision:
in expanded view `g` keeps meaning go-to-pane; use `Home`/`End` or `0`/`$`
for top/bottom.

```
◐ WORKING 22m25s   merge-dashboards-into-apps   ~/work/acm ⎇ apps-only        w2:p16 · claude
e/esc back · ⏎ reply · g go · x close · j/k scroll
────────────────────────────────────────────────────────────────────────────────────────────
ASKED      <full prompt text, wrapped>

REPLY      <full last complete reply, wrapped, markdown left as-is>

SAYING     <latest mid-turn text if different from REPLY>

BLOCKED    <full dialog text as read from the pane, when blocked>

FILES      services/app.py            3 edits
           frontend/src/Studio.tsx    1 edit
           tests/test_app.py          1 write

TRAIL      15:51:02  Bash     pytest -q tests/                    4.2s  ✗ 2 failed
           15:51:09  Edit     services/app.py                     0.1s
           15:51:12  Bash     pytest -q tests/                    3.9s  ✓
           … (whole turn, oldest first)

AGENTS     ◐ Build apps-only studio backend   python-service-engineer · sonnet · 12m · 140 tools · 3 edits
             SAYING  Let me clean up that leftover unused variable…
             NOW     Edit services/app.py 2s
             TRAIL   ⌕ Read 30s · ▶ Bash pytest 20s ✓ · ✎ Edit 2s
           ✓ Lint pass (finished 4m ago, 12 tools)
────────────────────────────────────────────────────────────────────────────────────────────
turn 21m33s · 55 tools · 2 edits · 2 agents · 3 errors · 286k ctx
```

All sections are omitted when empty. FILES is derived from edit tool_use
inputs in the current turn (main session only; subagent edits are listed
under their AGENTS entry as a count). Reply (`⏎`), go (`g`), close (`x`),
and blocked keys all work identically in expanded view, so answering a
blocked agent after reading its full dialog is one key.

Refresh cadence in expanded view is the same `MC_INTERVAL`; scroll position
is preserved across refreshes and clamped to the new content length.

## Stop (`x`)

`x` on a card (grid or expanded) closes that agent's session.

- If the agent is `idle` or `done`: the card shows a one-line confirm
  `close w2:p16 "merge-dashboards-into-apps"? y/n` in the footer. `y`
  runs `herdr pane close <agent pane>`. The card then has no agent and
  v1's adopt/close logic in `grid.py` takes over.
- If the agent is `working` or `blocked`: the confirm line reads
  `agent is still working — close anyway? y/n`. Same action on `y`.
- `n`/Esc cancels. The confirm line times out after 5 s.
- `pane close` kills the whole pane, including the shell. This is
  deliberate: a finished session's pane has no further use. (Builder's
  alternative, sending `/exit`, would leave a shell pane behind in the work
  workspace.)

## Start (`n`)

`n` on any card (or in an empty card) opens the start form in that card's
body. It is modal for that card only; other cards keep refreshing.

```
NEW TASK
▸ change my colorscheme to kanagawa in herdr and p10k
  (Enter launches · Shift+Enter or Alt+Enter newline · Esc cancels)

PROJECT  [~/DotFiles]  ~/work/acm  ~/work/platform  ~          Tab cycles
```

Behaviour:

- The prompt box is multi-line (Alt+Enter inserts a newline; plain Enter
  launches). Ctrl+U clears. Paste works because the card is in cbreak mode
  and reads bytes.
- PROJECT candidates: the distinct `cwd` values of (a) all agents currently
  in the Herdr snapshot and (b) the 10 most recently modified
  `~/.claude/projects/*` directories, taking the real path from the `cwd`
  field of the first record of that directory's newest `*.jsonl` (project
  slugs are not reversible: `acm-frontend` and `acm/frontend` share a
  slug). Skip paths that no longer exist. Paths inside `.claude/worktrees/`
  are collapsed to their repo root (a new task gets a fresh worktree from
  the repo's own CLAUDE.md rules). Always append `~`. De-dupe, keep at
  most 6.
- Preselection, in order: (1) keyword match between the prompt text and the
  last path segment of a candidate (case-insensitive substring, e.g.
  "acm", "dotfiles", "herdr" → DotFiles via an explicit alias map
  `{herdr: DotFiles, zsh: DotFiles, nvim: DotFiles, p10k: DotFiles}`);
  (2) the project of the most recently started session (persisted in
  `/tmp/herdr-mc/last-project`); (3) first candidate. Preselection
  re-evaluates as the prompt is typed until the user presses Tab, after
  which their choice sticks.
- Launch sequence, run by the card:
  1. Find the user's work workspace: the workspace of the agent on this
     card, else the workspace of any agent, else the focused workspace.
  2. `herdr tab create --workspace <ws> --cwd <project> --label <slug>
     --no-focus` where slug is the first 4 words of the prompt,
     kebab-cased. (A new tab rather than a split so the new agent gets
     a full pane and does not disturb an existing agent's layout.)
  3. Wait for the pane shell (`pane process-info` shows a bare shell,
     reuse `shell_idle` from grid.py; timeout 10 s).
  4. `herdr agent start <slug> --kind claude --pane <pane>` (default
     timeout). On success, `herdr agent prompt <pane> <prompt text>`.
  5. Write `/tmp/herdr-mc/last-project`. Flash `✓ started <slug> in
     <pane>`; grid.py's existing grow logic gives it a card within one
     tick (3 s), and a card that was empty adopts it directly.
- Failure at any step flashes the error in the footer and leaves the form
  content intact so the user can retry or Esc.
- Claude is started with no extra flags, in the chosen project root.
  Mission control never creates worktrees or branches; the project's own
  CLAUDE.md (for ACM: worktree from `dev` before the first edit) and the
  user's global one load as they would from a manual start, and the agent
  follows them. (Ben's decision.)

## Grid supervisor (`grid.py`) changes

- Ignore zoomed state: if the layout reports a zoomed pane in the tab, skip
  split/close decisions that tick (so an expanded card is never split or
  reclaimed under the user).
- Cap stays at 8 cards. When more agents exist than cards, grid.py writes
  the count of unshown agents to `/tmp/herdr-mc/overflow` (the file is
  removed when the count is 0). Every card reads that file each tick and,
  when it is present and non-zero, appends `+N more` in its footer. No card
  is singled out; it is a tab-wide fact.
- No other behaviour change.

## Key map (final)

| Key | Grid card | Expanded view |
|---|---|---|
| ⏎ | reply (or answer a free-text blocked prompt) | same |
| e | expand | collapse |
| Esc | cancel reply/form; when blocked, send Esc to agent | collapse (when not typing) |
| g | go to agent pane | same |
| x | close session (confirm) | same |
| n | new task form | same |
| y / n (blocked) | answer yes/no | same |
| 1-9 (blocked, options) | pick option | same |
| j / k / J / K | – | scroll |
| q | quit this card (v1) | collapse |

Note: `n` is both "new task" and "no" for a blocked yes/no prompt. Rule:
when the agent is blocked with a yes/no dialog, `n` means no; otherwise
`n` opens the form. The header hint shows whichever applies.

## Left to the builder

- Exact glyph choices and colours within the v1 palette.
- Transcript-parsing details beyond the facts listed above. Prefer the
  `.meta.json` sidecar over re-parsing the parent transcript for a
  subagent's description, type, model, and parent.
- Whether to cache parsed transcript tails between ticks (recommended:
  keep file offset + partial state per path, re-parse only appended bytes;
  v1 re-reads the last 1.5 MB every tick, and with subagents that becomes
  several files).
- Tests: a fixture directory of trimmed real transcripts (main + two
  subagents, one blocked dialog of each shape) and unit tests for the
  parser and the blocked-dialog classifier. Rendering is checked by eye in
  Herdr.

## Out of scope for this iteration, noted for later

- Sorting or highlighting cards by urgency (blocked first).
- A keyboard way to move focus between cards without Herdr's own pane
  navigation.
- Reading `~/.claude/state/activity.jsonl` instead of transcripts.
