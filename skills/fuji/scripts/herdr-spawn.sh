#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: herdr-spawn.sh <name> <kind> <brief-file> [timeout-ms] [--cwd DIR] [-- agent-args...]" >&2; exit 2; }
[ $# -ge 3 ] || usage
name=$1 kind=$2 brief=$3
shift 3
timeout=1800000
if [ $# -gt 0 ] && [[ $1 =~ ^[0-9]+$ ]]; then timeout=$1; shift; fi
cwd=$PWD
agent_args=()
while [ $# -gt 0 ]; do
  case $1 in
    --cwd) [ $# -ge 2 ] || usage; cwd=$2; shift 2 ;;
    --) shift; agent_args=("$@"); break ;;
    *) usage ;;
  esac
done

[ "${HERDR_ENV:-}" = 1 ] || { echo "not inside herdr" >&2; exit 3; }
command -v herdr >/dev/null || { echo "herdr not on PATH" >&2; exit 3; }
command -v jq >/dev/null || { echo "jq not on PATH" >&2; exit 3; }
[ -f "$brief" ] || { echo "brief not found: $brief" >&2; exit 2; }
[ -d "$cwd" ] || { echo "cwd not found: $cwd" >&2; exit 2; }
[[ $name =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || { echo "bad name: $name" >&2; exit 2; }

ws=${HERDR_WORKSPACE_ID:-$(herdr pane current | jq -r '.result.pane.workspace_id')}
label="fuji-${HERDR_PANE_ID//:/-}"
lock="/tmp/fuji/.herdr-lock-${HERDR_PANE_ID}"
mkdir -p /tmp/fuji
got=0
release() { if [ "$got" = 1 ]; then rmdir "$lock" 2>/dev/null || true; fi; }
trap release EXIT

for _ in $(seq 1 600); do mkdir "$lock" 2>/dev/null && { got=1; break; }; sleep 0.1; done
[ "$got" = 1 ] || { echo "lock timeout: $lock" >&2; exit 5; }

tab=$(herdr tab list --workspace "$ws" | jq -r --arg l "$label" '.result.tabs[] | select(.label==$l) | .tab_id' | head -1)
if [ -z "$tab" ]; then
  created=$(herdr tab create --workspace "$ws" --cwd "$cwd" --label "$label" --no-focus)
  tab=$(jq -r '.result.tab.tab_id' <<<"$created")
  pane=$(jq -r '.result.root_pane.pane_id' <<<"$created")
else
  root=$(herdr pane list --workspace "$ws" | jq -r --arg t "$tab" '.result.panes[] | select(.tab_id==$t) | .pane_id' | head -1)
  read -r pane width height <<<"$(herdr pane layout --pane "$root" | jq -r '.result.layout.panes | max_by(.rect.width * .rect.height) | "\(.pane_id) \(.rect.width) \(.rect.height)"')"
  dir=right
  [ "$width" -lt $((height * 2)) ] && dir=down
  pane=$(herdr pane split --pane "$pane" --direction "$dir" --cwd "$cwd" --no-focus | jq -r '.result.pane.pane_id')
fi
release

report="$(dirname "$brief")/report.md"
rm -f "$report"

herdr agent start "$name" --kind "$kind" --pane "$pane" --timeout 120000 ${agent_args[@]+-- "${agent_args[@]}"} >/dev/null

herdr agent prompt "$name" "$(cat "$brief")" --wait --timeout "$timeout" >/dev/null || true

if [ ! -s "$report" ]; then
  echo "no report at $report; agent tail:" >&2
  herdr agent read "$name" --source recent-unwrapped --lines 30 >&2 || true
  jq -n --arg name "$name" --arg tab "$tab" --arg pane "$pane" --arg kind "$kind" '{name:$name, tab:$tab, pane:$pane, kind:$kind, report:null}'
  exit 4
fi
jq -n --arg name "$name" --arg tab "$tab" --arg pane "$pane" --arg kind "$kind" --arg report "$report" '{name:$name, tab:$tab, pane:$pane, kind:$kind, report:$report}'
