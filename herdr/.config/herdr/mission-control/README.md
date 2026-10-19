# Herdr mission control

One pane per agent. Each pane runs `card.py`, a live status card for one Herdr agent. The aim
is that you stay in this tab and only enter an agent's own pane for real scrutiny.

    ◐ WORKING 1m15s               ⏎ reply · e expand · g go · x close · n new   w2:p16 · claude
    ───────────────────────────────────────────────────────────────────────────────────────────
    merge-dashboards-into-apps
    ~/work/acm  ⎇ apps-only

    ASKED   <the last prompt you typed to it>
    NOW     Bash 2s   <what the current tool call is doing>
    SAYING  <the latest thing the agent wrote, even mid-turn; SAID once the turn ends>
    AGENTS  ◐ Build studio backend   Edit services/app.py        12s ago
            ◐ Build studio frontend  Bash npm test  (2 ✗)        3s ago
    TRAIL   ✎ card.py 3m · ▶ pytest 2m ✗ · ✎ grid.py 1m · ▶ pytest 40s · ⌕ README 12s
    ───────────────────────────────────────────────────────────────────────────────────────────
    turn 3m01s · 5 tools · 0 edits · 2 agents · 0 errors · 93k ctx

Sections drop in this order when the pane is short: TRAIL, AGENTS rows beyond 2, SAYING
lines beyond 1, ASKED's second line. A blocked card gives the dialog the whole body.

## Keys (the card pane must have focus)

| Key | Grid card | Expanded view |
|---|---|---|
| ⏎ | reply to this agent (type, Enter sends, Esc cancels); on a free-text prompt, answer it | same |
| e | expand: zoom this card to the whole tab, read-only, still live | collapse |
| Esc | cancel reply/form; when blocked, send Escape to the agent | collapse (when not typing) |
| g | go to the agent's own pane (works across workspaces) | same |
| x | close this agent's session (asks y/n; warns if still working) | same |
| n | new task: type the prompt, Tab picks the project, Enter launches | same |
| y / n | answer an arrow-selected Yes/No dialog (the folder-trust prompt) | same |
| 1-9 | pick a numbered option (permission prompts, AskUserQuestion) | same |
| j / k, J / K, 0 / $ | – | scroll line, half page, top/bottom |
| q | quit this card (the supervisor restarts it) | collapse |

When the agent is blocked on a Yes/No dialog, `n` means No; otherwise it opens the new-task form.

## Blocked prompts

A blocked agent gets a red NEEDS YOU banner, the dialog text, a Herdr toast and an ntfy push
(topic in `pass home/ntfy/claude-topic`). The card classifies the dialog (`blocked.py`):

| Shape | Looks like | Answer with |
|---|---|---|
| yes_no | arrow-selected `❯ No, exit` / `Yes, I trust this folder` | y / n (moves the cursor, then Enter) |
| options | `❯ 1. Red` / `2. Green` … | a digit. Options that open a text box ("Type something.", "Other", "Chat about this") then open the card's REPLY line |
| free_text | an input box under a question | ⏎, type, ⏎ |
| unknown | nothing recognisable | every hint is shown |

`herdr agent prompt` is refused while an agent is blocked, so blocked answers go through
`herdr pane send-text` + `herdr agent send-keys`.

## Expanded view (e)

Zooms the card pane (`herdr pane zoom`), so the other cards keep running. Sections, all
untruncated and scrollable: ASKED, BLOCKED (full dialog), REPLY (last complete reply), SAYING,
NOW, FILES (edited this turn, with counts), TRAIL (every tool call this turn with time,
duration, ✓/✗), AGENTS (each live subagent with its own SAYING/NOW/TRAIL, grandchildren
indented, finished agents listed). Reply, go, close, and blocked keys work here too.

## Start (n) and stop (x)

`n` opens a form in the card body: a multi-line prompt box (Alt+Enter for a newline) and a
PROJECT row. Candidates are the cwds of running agents plus the 10 most recently used
Claude projects (worktree paths collapse to the repo root). The project is auto-picked from
words in your prompt (`acm`, `dotfiles`; `herdr`/`zsh`/`nvim`/`p10k`/`colorscheme` → DotFiles),
else the last project you launched; Tab cycles and pins your choice. Enter creates an unfocused
tab in your work workspace at that folder, starts `claude` in it, sends the prompt, and a card
adopts the new agent within a few seconds. Mission control never creates worktrees: the
project's own CLAUDE.md rules apply, as they would from a manual start.

`x` asks `close w2:p16 "title"? y/n` (or `agent is still working — close anyway?`) and closes the
agent's pane. The empty card is reclaimed by the supervisor.

## Supervisor and files

`grid.py` keeps the tab at exactly one card per live agent: it splits the largest card when a
new agent appears (right if wide, down if tall), cards adopt the newest unassigned agent, and
an empty card is closed after 25 s. It does nothing while a card is zoomed, and above 8 cards
it writes `/tmp/herdr-mc/overflow` so cards show `+N more`.

    mc            # alias -> open.sh --focus : open or focus the tab, start the supervisor
    MC_INTERVAL=1 # card poll interval (default 1.5 s)

Modules: `card.py` (render, keys, Herdr actions), `transcript.py` (Claude JSONL parsing: turn
summary, trail, files, subagents), `blocked.py` (dialog classifier), `projects.py` (start-form
project list), `grid.py` (supervisor), `open.sh`.

Data comes from `herdr api snapshot` (status, title, cwd, session id), the Claude transcript
`~/.claude/projects/<slug>/<session>.jsonl` (prompt, current tool, latest text, counts), and
the subagent transcripts `~/.claude/projects/<slug>/<session>/subagents/agent-*.jsonl` with
their `.meta.json` sidecars (description, type, model, depth, parent). Only file tails are
read each tick; task-notifications are scanned incrementally.

## Tests

    python3 -m unittest discover -s ~/.config/herdr/mission-control/tests -v

Fixtures in `tests/fixtures/` are trimmed real transcripts and dialog captures.
