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

rect=$(herdr pane layout --pane "$HERDR_PANE_ID" | jq -r --arg p "$HERDR_PANE_ID" '.result.layout.panes[] | select(.pane_id==$p) | "\(.rect.width) \(.rect.height)"')
read -r width height <<<"$rect"
dir=right
[ "$width" -lt $((height * 2)) ] && dir=down

report="$(dirname "$brief")/report.md"
rm -f "$report"

pane=$(herdr pane split --current --direction "$dir" --cwd "$cwd" --no-focus | jq -r '.result.pane.pane_id')
herdr agent start "$name" --kind "$kind" --pane "$pane" --timeout 120000 ${agent_args[@]+-- "${agent_args[@]}"} >/dev/null

herdr agent prompt "$name" "$(cat "$brief")" --wait --timeout "$timeout" >/dev/null || true

if [ ! -s "$report" ]; then
  echo "no report at $report; agent tail:" >&2
  herdr agent read "$name" --source recent-unwrapped --lines 30 >&2 || true
  jq -n --arg name "$name" --arg pane "$pane" --arg kind "$kind" '{name:$name, pane:$pane, kind:$kind, report:null}'
  exit 4
fi
jq -n --arg name "$name" --arg pane "$pane" --arg kind "$kind" --arg report "$report" '{name:$name, pane:$pane, kind:$kind, report:$report}'
