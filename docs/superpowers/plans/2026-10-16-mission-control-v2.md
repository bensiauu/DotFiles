# Mission Control v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Herdr mission-control tab the place Ben stays: cards show real activity including subagents, expand to a full detail view, answer every blocked-prompt shape, and start/stop sessions.

**Architecture:** v1 is one 408-line `card.py` plus `grid.py`. v2 splits the pure, testable logic out of `card.py` into three stdlib modules (`transcript.py` for JSONL parsing, `blocked.py` for dialog classification, `projects.py` for the start-form project list) and keeps rendering, the key loop, and Herdr actions in `card.py`. `grid.py` gains two small behaviours (skip ticks while zoomed, write an overflow count). Tests are `unittest` over trimmed real-transcript fixtures; rendering is checked by eye in Herdr.

**Tech Stack:** Python 3.14 stdlib only (no pytest; `python3 -m unittest`), Herdr CLI (`herdr api snapshot`, `pane`, `agent`, `tab`), ANSI 256-colour terminal output.

**Spec:** `docs/superpowers/specs/2026-10-16-mission-control-v2-design.md`

## Global Constraints

- Python 3 stdlib only; no pip dependencies. Tests run with `python3 -m unittest discover -s herdr/.config/herdr/mission-control/tests -v`.
- All code lives in `herdr/.config/herdr/mission-control/` (stowed to `~/.config/herdr/mission-control/`). Tests in a `tests/` subfolder there, fixtures in `tests/fixtures/`.
- Never read a whole transcript: parse the tail (v1 `TAIL_BYTES = 1_500_000`) and never more than one tail per file per tick.
- No writes under `~/.claude`. Scratch state only under `/tmp/herdr-mc/`.
- Keep the v1 catppuccin-latte-ish palette dict `C` and `STATE` table in `card.py`.
- `herdr agent prompt` is rejected with `agent_blocked` while status is `blocked`: every blocked answer uses `herdr pane send-text` and/or `herdr agent send-keys`.
- All `herdr` invocations use `subprocess.run([...])` argv lists, never a shell string, so prompt text with quotes/newlines passes intact.
- Commit after every task with the Co-Authored-By line from the session.
- In zsh, a word beginning with `=` is equals-expansion; test commands and docs avoid `echo ====`-style separators.

## Review Focus

1. A session that has not yet received a human prompt (fresh `claude` just started) has a transcript with no user text record. The card must render title/cwd with empty ASKED/SAYING, not crash. Pinned in Task 1 (`test_empty_turn_has_no_asked`).
2. A `<task-notification>` whose `<tool-use-id>` matches no Agent `tool_use` in the parsed tail (the launch scrolled out of the 1.5 MB tail) must be ignored, and the subagent is still found via its `.meta.json`. Pinned in Task 2 (`test_notification_without_launch_is_ignored`).
3. `herdr agent read` returning empty text or an error for a blocked agent must classify as `unknown` so the card shows all three hints. Pinned in Task 3 (`test_empty_text_is_unknown`).
4. A `.meta.json` that is malformed or missing must not remove the subagent from the list; fall back to the transcript's `agentId` and an empty description. Pinned in Task 2 (`test_malformed_meta_falls_back`).
5. The start form's project list must survive `~/.claude/projects` entries whose newest transcript has no `cwd` in its first record, and paths that no longer exist. Pinned in Task 8 (`test_candidates_skip_missing_cwd_and_dead_paths`).

---

## File Structure

```
herdr/.config/herdr/mission-control/
  card.py          render (grid + expanded), key loop, Herdr actions, start form, stop   (modify)
  grid.py          supervisor: zoom-aware ticks, overflow file                            (modify)
  transcript.py    NEW  JSONL tail parsing: turn summary, trail, files, subagents
  blocked.py       NEW  classify a blocked dialog's text into yes_no | options | free_text | unknown
  projects.py      NEW  project candidates for the start form + preselection
  open.sh          unchanged
  README.md        update keys, sections, data sources
  tests/
    test_transcript.py  test_blocked.py  test_projects.py
    fixtures/
      main.jsonl                       trimmed real main transcript with 2 Agent launches + 1 task-notification
      main/subagents/agent-aaa.jsonl   live depth-1 subagent (tool pending)
      main/subagents/agent-aaa.meta.json
      main/subagents/agent-bbb.jsonl   finished depth-1 subagent
      main/subagents/agent-bbb.meta.json
      main/subagents/agent-ccc.jsonl   depth-2 child of aaa
      main/subagents/agent-ccc.meta.json
      main/subagents/agent-ddd.jsonl   transcript with malformed meta
      main/subagents/agent-ddd.meta.json  (contents: `{not json`)
      fresh.jsonl                      session with no human prompt yet
      dialog_yes_no.txt  dialog_options.txt  dialog_free_text.txt
```

Fixtures are built by trimming real files under `~/.claude/projects/` (Task 1 Step 1 says how). Replace any prompt text that is sensitive with placeholder text; keep structure and keys verbatim.

---

### Task 1: Extract `transcript.py` and add SAYING, TRAIL, FILES

**Files:**
- Create: `herdr/.config/herdr/mission-control/transcript.py`
- Create: `herdr/.config/herdr/mission-control/tests/test_transcript.py`
- Create: `herdr/.config/herdr/mission-control/tests/fixtures/main.jsonl`, `fresh.jsonl`
- Modify: `herdr/.config/herdr/mission-control/card.py` (remove `read_transcript`, `transcript_path`, `tool_label`, `ts`, `clip`-independent helpers; import from `transcript`)

**Interfaces:**
- Produces:
  - `transcript.read_transcript(path: str, tail_bytes: int = 1_500_000) -> dict` with v1 keys (`title, asked, said, now, now_since, turn_start, tools, edits, errors, ctx, subagents, last_tool, last_tool_ts`) plus:
    - `saying: str | None` latest assistant text block in the turn (equals `said` once the turn ends)
    - `saying_ts: float | None`
    - `trail: list[ToolCall]` all tool calls in the turn, oldest first
    - `files: list[tuple[str, int]]` edited paths (HOME replaced by `~`) with edit counts, most edits first
    - `agent_launches: list[AgentLaunch]` Agent tool_use calls in the turn
    - `notified: set[str]` tool_use ids named by `<task-notification><tool-use-id>` records
  - `ToolCall = dict(id, name, label, ts, done_ts: float|None, error: bool)`
  - `AgentLaunch = dict(tool_use_id, description, subagent_type, model, agent_id: str|None)` (agent_id from `toolUseResult.agentId` when the result is in the tail)
  - `transcript.transcript_path(sid: str) -> str | None` (moved from card.py)
  - `transcript.tool_label(name: str, inp: dict) -> str` (moved)
  - `transcript.ts(s: str) -> float | None` (moved)
  - `transcript.glyph(name: str) -> str` → `✎` Edit/Write/MultiEdit/NotebookEdit, `⌕` Read/Grep/Glob, `▶` Bash, `⇄` Agent, `·` else

- [ ] **Step 1: Build fixtures.** From the newest `~/.claude/projects/-home-bensiauu-work-acm/*.jsonl` that has `"name":"Agent"` records, take the last 300 lines into `tests/fixtures/main.jsonl`, ensuring it contains: one human user text record, at least two `Agent` tool_use records with their `tool_result` (`toolUseResult.agentId`), one `<task-notification>` user record, at least one Edit and one Bash tool_use with results, one `is_error: true` result. Scrub prompt text to `"<scrubbed>"` where it is long. For `fresh.jsonl`, take the first 5 lines of a transcript before any `type:"user"` with string content (or hand-write: one `ai-title` record, one `assistant` record with usage only).

- [ ] **Step 2: Write failing tests** in `tests/test_transcript.py`:

```python
import unittest, os, json
from pathlib import Path
import sys; sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import transcript as T
FX = Path(__file__).parent / "fixtures"

class ReadTranscript(unittest.TestCase):
    def setUp(self): self.tr = T.read_transcript(str(FX / "main.jsonl"))
    def test_asked_is_human_text(self):
        self.assertTrue(self.tr["asked"]); self.assertFalse(self.tr["asked"].lstrip().startswith("<"))
    def test_saying_is_latest_text(self):
        self.assertIsNotNone(self.tr["saying"]); self.assertIsNotNone(self.tr["saying_ts"])
    def test_trail_oldest_first_and_marks_errors(self):
        tss = [c["ts"] for c in self.tr["trail"]]
        self.assertEqual(tss, sorted(tss)); self.assertTrue(any(c["error"] for c in self.tr["trail"]))
    def test_files_counts_edits(self):
        self.assertTrue(self.tr["files"]); self.assertTrue(all(n >= 1 for _, n in self.tr["files"]))
        self.assertEqual(sum(n for _, n in self.tr["files"]), self.tr["edits"])
    def test_agent_launches_carry_agent_id(self):
        self.assertGreaterEqual(len(self.tr["agent_launches"]), 2)
        self.assertTrue(any(l["agent_id"] for l in self.tr["agent_launches"]))
    def test_notified_ids_present(self):
        self.assertTrue(self.tr["notified"])
    def test_empty_turn_has_no_asked(self):
        fr = T.read_transcript(str(FX / "fresh.jsonl"))
        self.assertIsNone(fr["asked"]); self.assertEqual(fr["trail"], []); self.assertEqual(fr["files"], [])

class Glyph(unittest.TestCase):
    def test_glyphs(self):
        self.assertEqual(T.glyph("Edit"), "✎"); self.assertEqual(T.glyph("Grep"), "⌕")
        self.assertEqual(T.glyph("Bash"), "▶"); self.assertEqual(T.glyph("Agent"), "⇄"); self.assertEqual(T.glyph("Skill"), "·")
```

- [ ] **Step 3: Run tests, verify fail.** Run: `python3 -m unittest discover -s herdr/.config/herdr/mission-control/tests -v`. Expected: `ModuleNotFoundError: No module named 'transcript'`.

- [ ] **Step 4: Create `transcript.py`.** Move `ts`, `clip` (needed by `tool_label`), `transcript_path`, `tool_label`, `read_transcript` from `card.py` verbatim, then extend `read_transcript`: record `saying`/`saying_ts` on every assistant text block (not only the last of the record); build `trail` from `pending` plus completed calls (store `done_ts` from the tool_result record's timestamp and `error` from `is_error`); accumulate `files` from edit tool inputs (`file_path` or `notebook_path`); collect `agent_launches` from `Agent` tool_use and fill `agent_id` from the matching user record's top-level `toolUseResult.agentId`; collect `notified` by regex `<tool-use-id>(toolu_[A-Za-z0-9]+)</tool-use-id>` over user text records. Add `glyph`.

- [ ] **Step 5: Rewire `card.py`.** Delete the moved functions; `from transcript import read_transcript, transcript_path, tool_label, ts, clip, glyph`. Keep `card.py` behaviour identical for now.

- [ ] **Step 6: Run tests, verify pass.** Same command. Expected: all PASS.

- [ ] **Step 7: Smoke in Herdr.** Run `mc`; confirm existing cards render as before (no traceback in the card pane).

- [ ] **Step 8: Commit.**
```bash
git add herdr/.config/herdr/mission-control
git commit -m "mission-control: extract transcript.py; add saying, trail, files, agent launches"
```

---

### Task 2: Subagent discovery

**Files:**
- Modify: `herdr/.config/herdr/mission-control/transcript.py`
- Create: fixtures `tests/fixtures/main/subagents/agent-{aaa,bbb,ccc,ddd}.jsonl` + `.meta.json`
- Modify: `tests/test_transcript.py`

**Interfaces:**
- Consumes: `read_transcript` output (`agent_launches`, `notified`) from Task 1.
- Produces:
  - `transcript.subagents(main_path: str, tr: dict, now: float, stale_after: float = 600) -> list[SubAgent]`
  - `SubAgent = dict(agent_id, description, agent_type, model: str|None, depth: int, parent_id: str|None, status: 'working'|'done'|'stale', started_ts, last_write_ts, tools, edits, errors, saying, now: tuple|None, now_since, trail: list[ToolCall])`
  - Ordering: depth-1 agents by `started_ts`, each followed by its children (depth 2+) in `started_ts` order.
  - Liveness rule: `done` if the launch's `tool_use_id` is in `tr["notified"]` or (launch has a `tool_result` and `meta.requestShape != "background"`); else `stale` if `now - last_write_ts > stale_after`; else `working`.
  - Subagent dir: `<main_path without .jsonl>/subagents/`. Each `agent-*.jsonl` is parsed with `read_transcript` (same tail rule) for counts/saying/now/trail.

- [ ] **Step 1: Build fixtures.** From `~/.claude/projects/-home-bensiauu-work-acm/73e69781-d405-49b5-9bd5-84f56cce9004/subagents/`, trim the last 80 lines of two transcripts into `agent-aaa.jsonl` (ensure a pending tool_use at the end) and `agent-bbb.jsonl` (ensure final record is an assistant text with no pending tool). Copy their `.meta.json` and set `toolUseId` values to ids that exist in `main.jsonl` Agent launches; make `bbb`'s id the one named by the task-notification. Create `agent-ccc.jsonl` (copy of aaa, 20 lines) with meta `{"agentType":"Explore","description":"child","toolUseId":"toolu_child","parentAgentId":"aaa","spawnDepth":2,"requestShape":"background"}`. Create `agent-ddd.jsonl` (10 lines) and `agent-ddd.meta.json` containing `{not json`. Rename `agentId` values inside the jsonl files to `aaa`/`bbb`/`ccc`/`ddd`. Save `main.jsonl` from Task 1 as `tests/fixtures/main.jsonl` so the dir is `tests/fixtures/main/subagents/`.

- [ ] **Step 2: Write failing tests:**

```python
class Subagents(unittest.TestCase):
    def setUp(self):
        self.main = str(FX / "main.jsonl"); self.tr = T.read_transcript(self.main)
        self.now = max(os.path.getmtime(p) for p in (FX / "main" / "subagents").glob("*.jsonl")) + 1
        self.subs = {s["agent_id"]: s for s in T.subagents(self.main, self.tr, self.now)}
    def test_finds_all_four(self): self.assertEqual(set(self.subs), {"aaa", "bbb", "ccc", "ddd"})
    def test_live_has_pending_tool(self):
        self.assertEqual(self.subs["aaa"]["status"], "working"); self.assertIsNotNone(self.subs["aaa"]["now"])
    def test_notified_is_done(self): self.assertEqual(self.subs["bbb"]["status"], "done")
    def test_grandchild_attributed(self):
        self.assertEqual(self.subs["ccc"]["depth"], 2); self.assertEqual(self.subs["ccc"]["parent_id"], "aaa")
        order = [s["agent_id"] for s in T.subagents(self.main, self.tr, self.now)]
        self.assertLess(order.index("aaa"), order.index("ccc"))
    def test_malformed_meta_falls_back(self):
        self.assertEqual(self.subs["ddd"]["description"], ""); self.assertEqual(self.subs["ddd"]["depth"], 1)
    def test_stale_after_threshold(self):
        s = {x["agent_id"]: x for x in T.subagents(self.main, self.tr, self.now + 10_000)}
        self.assertEqual(s["aaa"]["status"], "stale")
    def test_notification_without_launch_is_ignored(self):
        tr = dict(self.tr); tr["notified"] = {"toolu_nonexistent"}; tr["agent_launches"] = []
        s = {x["agent_id"]: x for x in T.subagents(self.main, tr, self.now)}
        self.assertEqual(set(s), {"aaa", "bbb", "ccc", "ddd"}); self.assertEqual(s["bbb"]["status"], "working")
    def test_missing_dir_is_empty(self): self.assertEqual(T.subagents(str(FX / "fresh.jsonl"), {}, self.now), [])
```

- [ ] **Step 3: Run tests, verify fail.** Expected: `AttributeError: module 'transcript' has no attribute 'subagents'`.

- [ ] **Step 4: Implement `subagents`** in `transcript.py` per the Interfaces block. Read meta with `json.load` inside `try`; on failure use `{}`. `started_ts` = timestamp of the first record; `last_write_ts` = `os.path.getmtime`. Cache parsed results per path keyed on `(mtime, size)` in a module-level dict so unchanged files are not re-parsed each tick.

- [ ] **Step 5: Run tests, verify pass.**

- [ ] **Step 6: Commit.** `git commit -m "mission-control: discover subagents from transcript dir + meta.json, with liveness and depth"`

---

### Task 3: Blocked dialog classifier

**Files:**
- Create: `herdr/.config/herdr/mission-control/blocked.py`, `tests/test_blocked.py`, `tests/fixtures/dialog_{yes_no,options,free_text}.txt`

**Interfaces:**
- Produces: `blocked.classify(text: str) -> tuple[shape, options]` where `shape ∈ {"yes_no","options","free_text","unknown"}` and `options: list[str]` is the numbered option labels for `options` (empty otherwise). `blocked.strip_ansi(text) -> str` and `blocked.dialog_lines(text, keep=6) -> list[str]` (move v1 `blocked_text` filtering here; `keep=None` keeps all).
- Rules: `yes_no` if the stripped text matches `r"\b(Yes|No)\b"` on an option line **and** fewer than 3 numbered lines, or contains `(y/n)`. `options` if ≥2 lines match `r"^\s*(❯\s*)?(\d)[.)]\s+\S"`. `free_text` if neither and text contains an input glyph (`›`, `❯ `, `> ` at line start) or a line ending in `?`. Otherwise `unknown`. Empty/whitespace → `unknown`.

- [ ] **Step 1: Capture fixtures.** Trigger each dialog shape in a scratch `claude` pane (a permission prompt, an `AskUserQuestion` with options, a free-text question) and save `herdr agent read <pane> --source detection --lines 20` output to the three `.txt` files. If a shape cannot be triggered now, hand-write it mimicking Claude Code's layout (`❯ 1. Yes` / `2. Yes, and don't ask again` / `3. No` for yes_no; `❯ 1. Option A` … `4. Option D` for options; `? What colour …` + `› ` for free_text).

- [ ] **Step 2: Write failing tests:**

```python
class Classify(unittest.TestCase):
    def rd(self, n): return (FX / f"dialog_{n}.txt").read_text()
    def test_yes_no(self): self.assertEqual(B.classify(self.rd("yes_no"))[0], "yes_no")
    def test_options_returns_labels(self):
        shape, opts = B.classify(self.rd("options")); self.assertEqual(shape, "options"); self.assertGreaterEqual(len(opts), 2)
    def test_free_text(self): self.assertEqual(B.classify(self.rd("free_text"))[0], "free_text")
    def test_empty_text_is_unknown(self): self.assertEqual(B.classify("")[0], "unknown"); self.assertEqual(B.classify("\x1b[0m  \n")[0], "unknown")
    def test_dialog_lines_drops_box_art(self): self.assertFalse(any(set(l) <= set("─│╭╮╰╯┃━ ") for l in B.dialog_lines(self.rd("options"), keep=None)))
```

- [ ] **Step 3: Run, verify fail** (`No module named 'blocked'`). **Step 4: Implement.** **Step 5: Run, verify pass.**

- [ ] **Step 6: Commit.** `git commit -m "mission-control: classify blocked dialogs (yes_no / options / free_text)"`

---

### Task 4: Grid card render: SAYING, TRAIL, AGENTS, overflow, keys hint

**Files:**
- Modify: `herdr/.config/herdr/mission-control/card.py` (`render`, `main` data gathering)

**Interfaces:**
- Consumes: `read_transcript` extras and `subagents()` (Tasks 1–2); `blocked.classify`/`dialog_lines` (Task 3).
- Produces: `render(a, tr, subs, prev_state_t, cols, rows, ui) -> str` (new `subs` param). `ui` gains keys `shape`, `options` (set by main when blocked), `confirm` (Task 7), `form` (Task 9), `expanded`, `scroll` (Task 6). Helper `overflow_count() -> int` reads `/tmp/herdr-mc/overflow` (0 when absent/invalid). Helper `trail_line(trail, width, now) -> str` renders newest-right `glyph label age[✗]` items separated by ` · `, dropping oldest until it fits.

- [ ] **Step 1: Implement the body per spec section "The card (grid view)".** Order: header, banner, rule, title, cwd, blank, ASKED (≤2 lines), then one of: blocked dialog lines / NOW / "thinking…" (NOW is suppressed when `tr["saying_ts"] > tr["now_since"]`), SAYING (label `SAID` when status in idle/done; ≤3 lines), AGENTS (≤4 rows + `+N more`, grandchildren indented 2 spaces under parent; row = `glyph description  current-tool-or-saying  (E ✗ if errors)  age`), TRAIL (1 line). Height budget: compute `body_budget = rows - fixed_lines`; drop in spec order TRAIL → AGENTS beyond 2 → SAYING beyond 1 → ASKED 2nd line.
- Header keys string: `⏎ reply · e expand · g go · x close · n new`; when blocked replace with per-shape hint from spec table (`y / n / esc`, `1-9 pick · esc`, `⏎ answer · esc`; `unknown` shows all three joined with ` · `).
- Footer: add `f"{live} agents"` when `live = sum(s['status']=='working' for s in subs) > 0`; append `+N more` when `overflow_count() > 0`.
- `main()`: after reading `tr`, call `subs = subagents(tp, tr, time.time())` when `tp` else `[]`; when blocked, `txt = sh("herdr","agent","read",pane,"--source","detection","--lines","20")`, set `ui["shape"], ui["options"] = classify(txt)` and keep `ui["dialog"] = dialog_lines(txt, keep=None)`.

- [ ] **Step 2: Visual check in Herdr.** Run `mc` with at least one session that has live subagents (start one with `Agent` background work if none). Confirm: AGENTS rows appear with the description and current tool; TRAIL shows glyphs with ages; SAYING updates mid-turn; the 22-minute "0 tools" case from the screenshot now shows the subagents. Resize the card pane small and confirm sections drop in the spec order with no traceback.

- [ ] **Step 3: Commit.** `git commit -m "mission-control: card shows SAYING, TRAIL, AGENTS, overflow count, per-shape blocked hints"`

---

### Task 5: Answer any blocked prompt from the card

**Files:**
- Modify: `herdr/.config/herdr/mission-control/card.py` (`act_reply`, `act_keys`, key loop)

**Interfaces:**
- Produces: `act_reply(pane: str, text: str, blocked: bool) -> tuple[bool, str]`: when `blocked` is False use `herdr agent prompt pane text` (v1); when True run `herdr pane send-text pane text` then `herdr agent send-keys pane enter`. `act_pick(pane: str, digit: str) -> tuple[bool, str]`: `send-keys pane <digit>` then `send-keys pane enter`.
- Key loop rules (status blocked): `y`/`n`/`esc` as v1 when `shape in (yes_no, unknown)`; digits `1-9` → `act_pick` when `shape in (options, unknown)` and digit ≤ `len(options)` (or any digit when unknown); `enter` → opens the REPLY line when `shape in (free_text, unknown)` (remove the v1 "agent is blocked" refusal); on submit the reply line calls `act_reply(pane, text, blocked=True)`. Flash results as v1.

- [ ] **Step 1: Implement** the two actions and the rules above. Keep `act_keys` for raw use.
- [ ] **Step 2: Verify live.** In a scratch `claude` pane (`herdr tab create --cwd /tmp --label scratch`, then `herdr agent start scratch --kind claude --pane <p>`), ask it `ask me a question with 3 options using AskUserQuestion`; on the card press `2`; confirm the agent receives option 2. Then ask `ask me a free-text question`; press Enter on the card, type an answer, Enter; confirm it lands. Then trigger a permission prompt (`run ls via Bash`) and answer `y`. Record the three outcomes in the commit body.
- [ ] **Step 3: Commit.** `git commit -m "mission-control: answer yes/no, numbered, and free-text blocked prompts via send-text/send-keys"`

---

### Task 6: Expanded view

**Files:**
- Modify: `herdr/.config/herdr/mission-control/card.py` (`render_expanded`, key loop, zoom actions)

**Interfaces:**
- Consumes: `tr`, `subs`, `ui["dialog"]` from Tasks 1–4.
- Produces: `render_expanded(a, tr, subs, prev_state_t, cols, rows, ui) -> str` with sections in spec order (ASKED full, REPLY full = `tr["said"]`, SAYING if `!= said`, BLOCKED full dialog, FILES, TRAIL full with `HH:MM:SS name label dur ✓/✗ (error excerpt ≤40 chars)`, AGENTS each with `type · model · age · N tools · N edits` line plus indented SAYING/NOW/TRAIL; finished agents shown as `✓ description (finished Nm ago, N tools)`), footer identical to grid. Content is built as a list of lines, then sliced by `ui["scroll"]` (clamped to `max(0, len(lines) - body_rows)`). `act_zoom(pane: str, on: bool)` runs `herdr pane zoom --on <own pane>` / `--toggle`, where own pane is `os.environ["HERDR_PANE_ID"]`.
- Keys: `e` toggles `ui["expanded"]` and calls `act_zoom`; in expanded: `esc`/`q` (when not typing/confirming) collapse; `j`/`k` ±1, `J`/`K` ±`body_rows//2`, `0`/`$` top/bottom; `g`, `x`, `n`, `enter`, blocked keys behave as in grid. Header second line: `e/esc back · ⏎ reply · g go · x close · j/k scroll`. `read_key` must return `"J"`, `"K"`, `"0"`, `"$"` as plain chars (it already does for printable bytes).

- [ ] **Step 1: Implement.** Reuse `wrap`/`clip`. Preserve `ui["scroll"]` across refreshes; re-clamp each render.
- [ ] **Step 2: Verify live.** On a working card press `e`: the card fills the tab, other cards keep running (check `/tmp/herdr-mc/card-*` mtimes still advance). Scroll with `j`/`K`. Press `g` from expanded: focus moves to the agent; return and press `e`: grid restored, same agent on the card. Expand a blocked card and answer it from the expanded view.
- [ ] **Step 3: Commit.** `git commit -m "mission-control: expanded read-only detail view via pane zoom"`

---

### Task 7: Stop a session (`x`)

**Files:**
- Modify: `herdr/.config/herdr/mission-control/card.py`

**Interfaces:**
- Produces: `act_close(pane: str) -> tuple[bool, str]` → `herdr pane close <pane>`. `ui["confirm"] = (question: str, deadline: float, action: callable) | None`; while set, footer shows the question and only `y`/`n`/`esc` are read; expires after 5 s.
- Copy: idle/done → `close {pane} "{title}"? y/n`; working/blocked → `agent is still working — close anyway? y/n`.

- [ ] **Step 1: Implement.** On `y`: run action, flash result, clear `confirm`; the card then falls into the v1 "no agent" adopt/close path on the next tick.
- [ ] **Step 2: Verify live.** Press `x` on the scratch session from Task 5, confirm with `y`: pane disappears from the work workspace; the card shows "no agent" and grid.py closes it after 25 s (or it adopts a new agent). Press `x` then `n` on another card: nothing closes.
- [ ] **Step 3: Commit.** `git commit -m "mission-control: x closes a session after confirm"`

---

### Task 8: `projects.py`: candidates and preselection

**Files:**
- Create: `herdr/.config/herdr/mission-control/projects.py`, `tests/test_projects.py`

**Interfaces:**
- Produces:
  - `projects.candidates(snapshot_agents: list[dict], projects_root: str = "~/.claude/projects", limit: int = 6, exists=os.path.exists) -> list[str]`: distinct cwds from agents + cwd of the first record of the newest `*.jsonl` in each of the 10 most-recently-modified project dirs; worktree paths (`/.claude/worktrees/` in path) collapsed to the repo root (text before `/.claude/worktrees/`); skip when `exists(path)` is False or no cwd found; always append `~` (expanded); de-dupe preserving order; cap at `limit`.
  - `projects.preselect(prompt: str, cands: list[str], last: str | None) -> int`: index of the first candidate whose basename (case-insensitive) is a substring of the prompt or whose alias matches, where `ALIASES = {"herdr": "DotFiles", "zsh": "DotFiles", "nvim": "DotFiles", "p10k": "DotFiles", "dotfiles": "DotFiles", "colorscheme": "DotFiles"}`; else index of `last` if present; else 0.
  - `projects.slug(prompt: str) -> str`: first 4 words, lowercased, non-alphanumerics → `-`, collapsed, trimmed; fallback `task`.
  - `LAST_FILE = "/tmp/herdr-mc/last-project"`, `read_last() -> str|None`, `write_last(path)`.

- [ ] **Step 1: Write failing tests:**

```python
class Candidates(unittest.TestCase):
    def test_candidates_skip_missing_cwd_and_dead_paths(self):
        with tempfile.TemporaryDirectory() as root:
            mk(root, "-a", {"cwd": "/does/not/exist"}); mk(root, "-b", {}); mk(root, "-c", {"cwd": "/tmp"})
            c = P.candidates([], root, exists=lambda p: p in ("/tmp", os.path.expanduser("~")))
            self.assertEqual(c, ["/tmp", os.path.expanduser("~")])
    def test_worktree_collapses_to_repo_root(self):
        c = P.candidates([{"cwd": "/r/acm-frontend/.claude/worktrees/x"}], "/nonexistent", exists=lambda p: True)
        self.assertEqual(c[0], "/r/acm-frontend")
    def test_agents_first_then_dedup_and_cap(self):
        c = P.candidates([{"cwd": "/p1"}, {"cwd": "/p1"}, {"cwd": "/p2"}], "/nonexistent", limit=2, exists=lambda p: True)
        self.assertEqual(c, ["/p1", "/p2"])
class Preselect(unittest.TestCase):
    C = ["/h/work/acm", "/h/DotFiles", "/h"]
    def test_keyword(self): self.assertEqual(P.preselect("fix the ACM login", self.C, None), 0)
    def test_alias(self): self.assertEqual(P.preselect("change my colorscheme in herdr", self.C, None), 1)
    def test_last_then_first(self):
        self.assertEqual(P.preselect("hello", self.C, "/h"), 2); self.assertEqual(P.preselect("hello", self.C, None), 0)
class Slug(unittest.TestCase):
    def test_slug(self): self.assertEqual(P.slug("Change my colorscheme to Kanagawa, please"), "change-my-colorscheme-to"); self.assertEqual(P.slug("  "), "task")
```
`mk(root, name, first_record)` writes `root/name/x.jsonl` with one JSON line.

- [ ] **Step 2: Run, verify fail. Step 3: Implement. Step 4: Run, verify pass.**
- [ ] **Step 5: Commit.** `git commit -m "mission-control: project candidates + preselection for the start form"`

---

### Task 9: Start a task (`n`)

**Files:**
- Modify: `herdr/.config/herdr/mission-control/card.py` (form render, key handling, `launch`)

**Interfaces:**
- Consumes: `projects.candidates/preselect/slug/read_last/write_last` (Task 8); `shell_idle` logic from `grid.py` (copy the 6-line function into `card.py`; do not import grid.py, it runs a loop at import).
- Produces: `ui["form"] = dict(text: str, cands: list[str], sel: int, pinned: bool) | None`. `render_form(...)` draws per spec ("NEW TASK", prompt box with cursor, hint line, `PROJECT` row with the selected candidate in brackets, `Tab cycles`). `launch(prompt: str, project: str, ws: str) -> tuple[bool, str]` runs the spec sequence: `herdr tab create --workspace ws --cwd project --label slug --no-focus` → poll `shell_idle(pane)` up to 10 s → `herdr agent start slug --kind claude --pane pane` → `herdr agent prompt pane prompt` → `write_last(project)`; returns `(True, f"started {slug} in {pane}")` or `(False, "<step>: <stderr first line>")`.
- Keys while form open: printable → append; `enter` → launch; Alt+Enter (`\x1b\r`) → newline; `bs`; `kill`; `tab` → `sel = (sel+1) % len(cands)`, `pinned = True`; `esc` → close form. While not pinned, `sel = preselect(text, cands, read_last())` after each keystroke. `read_key` must return `"tab"` for `\t` and `"alt-enter"` for `\x1b\r` (extend the escape branch: after `\x1b`, if the next byte within 20 ms is `\r`, return `alt-enter`).
- Workspace choice: `a["workspace_id"]` if the card has an agent, else any agent's, else `snapshot()["focused_workspace_id"]`.
- `n` opens the form unless `status == "blocked" and ui["shape"] in ("yes_no", "unknown")`, in which case `n` means no (Task 5).

- [ ] **Step 1: Implement.** On launch failure keep the form open with its text and flash the error.
- [ ] **Step 2: Verify live.** Press `n`, type `in this repo, print the current git branch and stop`, confirm PROJECT preselects `~/DotFiles` when the text contains "dotfiles"; Tab to `~/work/acm` and back; Enter. Confirm a new unfocused tab appears in the work workspace, Claude starts and runs the prompt, and a card appears within ~3 s. Press `n` with the prompt `change my colorscheme in herdr` and confirm DotFiles is preselected via the alias. Close the test session with `x`.
- [ ] **Step 3: Commit.** `git commit -m "mission-control: n starts a new Claude session with prompt + project picker"`

---

### Task 10: `grid.py`: zoom-aware ticks and overflow file

**Files:**
- Modify: `herdr/.config/herdr/mission-control/grid.py`

**Interfaces:**
- Consumes: layout `zoomed: bool` from `herdr api snapshot` `layouts[]`.
- Produces: `/tmp/herdr-mc/overflow` containing `str(len(unassigned))` when `len(card_panes) >= 8 and unassigned`, removed otherwise (Task 4 reads it).

- [ ] **Step 1: Implement.** At the top of the loop body after finding `layout`: `if layout.get("zoomed"): time.sleep(TICK); continue` placed **after** the heal step so a crashed card still heals, but before grow/shrink. Write/remove the overflow file each tick.
- [ ] **Step 2: Verify live.** Expand a card (`e`); from another workspace start a new `claude` session; confirm no split happens while zoomed and the new agent gets a card within one tick after collapsing. Check `cat /tmp/herdr-mc/overflow` is absent with < 8 cards.
- [ ] **Step 3: Commit.** `git commit -m "mission-control: grid skips layout changes while a card is zoomed; writes overflow count"`

---

### Task 11: README and module docstrings

**Files:**
- Modify: `herdr/.config/herdr/mission-control/README.md`, docstrings at top of `card.py`, `grid.py`

- [ ] **Step 1: Update README** with the final key map table from the spec, the new card sections (SAYING/TRAIL/AGENTS), the expanded view, start/stop, the blocked-shape table, the subagent data source (`<session>/subagents/agent-*.jsonl` + `.meta.json`), and the test command.
- [ ] **Step 2: Run the full test suite once more**; expected all PASS. Run `mc` and confirm the tab opens cleanly.
- [ ] **Step 3: Commit.** `git commit -m "mission-control: document v2 keys, sections, and tests"`

---

## Self-review notes

- Spec coverage: card sections (T1, T2, T4), blocked shapes and delivery (T3, T5), expanded view (T6), stop (T7), start incl. project picker/preselection/launch sequence/worktree decision (T8, T9), grid changes incl. overflow (T10, T4), README (T11). "Out of scope" items untouched.
- Review Focus pins: #1 T1, #2 T2, #3 T3, #4 T2, #5 T8.
- Names used consistently: `read_transcript`, `subagents`, `classify`, `dialog_lines`, `candidates`, `preselect`, `slug`, `act_reply(pane, text, blocked)`, `act_pick`, `act_zoom`, `act_close`, `render`, `render_expanded`, `render_form`, `ui` keys `shape, options, dialog, confirm, form, expanded, scroll`.
