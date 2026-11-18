#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: herdr-close.sh <name-or-pane...>" >&2; exit 2; }
[ $# -ge 1 ] || usage
command -v herdr >/dev/null || { echo "herdr not on PATH" >&2; exit 3; }
command -v jq >/dev/null || { echo "jq not on PATH" >&2; exit 3; }

rc=0
for arg in "$@"; do
  pane=$arg
  if [[ $arg != *:* ]]; then
    pane=$(herdr agent list | jq -r --arg n "$arg" '.result.agents[] | select(.name==$n) | .pane_id' | head -1)
    [ -n "$pane" ] || { echo "no pane for name: $arg" >&2; rc=4; continue; }
  fi
  herdr pane close "$pane" >/dev/null
  echo "closed $arg ($pane)" >&2
done
exit $rc
