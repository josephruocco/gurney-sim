#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
godot_bin="/Applications/Godot.app/Contents/MacOS/Godot"
host_log="/tmp/gurney-godot-host.log"
client_log="/tmp/gurney-godot-client.log"

"$godot_bin" --headless --path "$project_dir" --quit-after 300 -- --host --autostart >"$host_log" 2>&1 &
host_pid=$!
trap 'kill "$host_pid" 2>/dev/null || true' EXIT
sleep 1
"$godot_bin" --headless --path "$project_dir" --quit-after 180 -- --join --autostart >"$client_log" 2>&1
wait "$host_pid"
trap - EXIT

rg -q 'NETWORK Player [0-9]+ joined' "$host_log"
rg -q 'NETWORK Connected as player [0-9]+' "$client_log"
rg -q 'ROSTER local=1 spawned=1' "$host_log"
rg -q 'ROSTER local=[0-9]+ spawned=1' "$client_log"
rg -q 'ROSTER local=[0-9]+ spawned=[0-9]+ slot=[0-9]+ total=2' "$client_log"
rg -q 'ROSTER local=[0-9]+ spawned=[0-9]+ slot=1 total=2' "$client_log"
rg -q 'WORLD_SYNC local=[0-9]+ players=2' "$client_log"
rg -q 'LOBBY local=[0-9]+ players=2 ready=2' "$client_log"

echo "Two-instance ENet host/client roster and world-state sync test passed."
