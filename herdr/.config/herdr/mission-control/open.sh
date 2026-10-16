#!/usr/bin/env bash
# Open (or focus) the mission-control tab: one live card per agent, laid out automatically.
# Usage: open.sh [--focus|--no-focus]      alias: mc
set -eu
MC="$HOME/.config/herdr/mission-control"
ws=${HERDR_WORKSPACE_ID:-$(herdr api snapshot | jq -r '.result.snapshot.focused_workspace_id')}
snap=$(herdr api snapshot)
tab=$(printf '%s' "$snap" | jq -r --arg ws "$ws" '.result.snapshot.tabs[]? | select(.workspace_id==$ws and ((.label // .title // "")=="mission-control")) | (.tab_id // .id)' | head -1)
if [ -z "$tab" ]; then
  out=$(herdr tab create --workspace "$ws" --label mission-control --cwd "$HOME" --env "MC_TAB_ID=pending" ${1:---no-focus})
  tab=$(printf '%s' "$out" | jq -r '.result.tab.tab_id // .result.tab.id')
  root=$(printf '%s' "$out" | jq -r '.result.root_pane.pane_id')
  sleep 0.8
else
  [ "${1:-}" = "--focus" ] && herdr tab focus "$tab" >/dev/null
fi
# one supervisor per tab, started from the card pane's shell so it outlives this script.
# (A plain background job from an agent's Bash tool dies with that shell.)
mkdir -p /tmp/herdr-mc
if ! pgrep -f "python3 .*grid.py $tab" >/dev/null; then
  first=$(herdr api snapshot | jq -r --arg t "$tab" '.result.snapshot.layouts[] | select(.tab_id==$t) | .panes[0].pane_id')
  herdr pane run "$first" "nohup setsid python3 $MC/grid.py $tab >/tmp/herdr-mc/grid.log 2>&1 </dev/null & disown; clear; export MC_TAB_ID=$tab; exec $MC/card.py" >/dev/null
fi
sleep 2
echo "mission-control: tab $tab (supervisor pid $(pgrep -f "python3 .*grid.py $tab" | head -1))"
