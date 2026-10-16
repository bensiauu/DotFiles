# Herdr mission control

One pane per agent. Each pane runs `card.py`, a live status card for one Herdr agent:

    ◐ WORKING 1m15s                                 w2:p16 · claude
    ───────────────────────────────────────────────────────────────
    merge-dashboards-into-apps
    ~/work/acm  ⎇ apps-only

    ASKED   <the last prompt you typed to it>
    NOW     Bash 2s
            <what the current tool call is doing>
    SAID    <the last thing the agent said to you>
    ───────────────────────────────────────────────────────────────
    turn 3m01s · 5 tools · 0 edits · 1 subagents · 0 errors · 93k ctx

Keys inside a card (the card pane must have focus):

    Enter     reply to this agent: type on the REPLY line, Enter sends, Esc cancels
    g         go to the agent's own pane (works across workspaces)
    y / n     answer a blocked agent's yes/no approval (sends the key + Enter)
    Esc       send Escape to a blocked agent

A blocked agent gets a red NEEDS YOU banner and the dialog text it is stuck on, plus a
Herdr toast and an ntfy push (topic in `pass home/ntfy/claude-topic`).

`grid.py` is a small supervisor that keeps the tab at exactly one card per live agent:
it splits the largest card when a new agent appears (right if wide, down if tall), cards
adopt the newest unassigned agent, and an empty card is closed after 25 s.

    mc            # alias -> open.sh --focus : open or focus the tab, start the supervisor
    MC_INTERVAL=1 # card poll interval (default 1.5 s); q in a card closes it

Data comes from `herdr api snapshot` (status, title, cwd, session id) and the Claude
transcript `~/.claude/projects/*/<session>.jsonl` (prompt, current tool, last reply, counts).
The raw tool ledger still lands in `~/.claude/state/activity.jsonl` for grepping.
