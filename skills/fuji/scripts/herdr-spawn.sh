#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: herdr-spawn.sh <name> <kind> <brief-file> [timeout-ms]" >&2; exit 2; }
[ $# -ge 3 ] || usage
name=$1 kind=$2 brief=$3 timeout=${4:-1800000}

[ "${HERDR_ENV:-}" = 1 ] || { echo "not inside herdr" >&2; exit 3; }
command -v herdr >/dev/null || { echo "herdr not on PATH" >&2; exit 3; }
command -v jq >/dev/null || { echo "jq not on PATH" >&2; exit 3; }
[ -f "$brief" ] || { echo "brief not found: $brief" >&2; exit 2; }
[[ $name =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || { echo "bad name: $name" >&2; exit 2; }

width=$(herdr pane layout --pane "$HERDR_PANE_ID" | jq -r --arg p "$HERDR_PANE_ID" '.result.layout.panes[] | select(.pane_id==$p) | .rect.width')
height=$(herdr pane layout --pane "$HERDR_PANE_ID" | jq -r --arg p "$HERDR_PANE_ID" '.result.layout.panes[] | select(.pane_id==$p) | .rect.height')
dir=right
[ "$width" -lt $((height * 2)) ] && dir=down

pane=$(herdr pane split --current --direction "$dir" --cwd "$PWD" --no-focus | jq -r '.result.pane.pane_id')
herdr agent start "$name" --kind "$kind" --pane "$pane" >/dev/null

herdr agent prompt "$name" "$(cat "$brief")" --wait --timeout "$timeout" >/dev/null
jq -n --arg name "$name" --arg pane "$pane" --arg kind "$kind" '{name:$name, pane:$pane, kind:$kind}'
