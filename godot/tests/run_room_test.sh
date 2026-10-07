#!/bin/zsh
set -euo pipefail
base="${0:A:h:h:h}"
bin=/Applications/Godot.app/Contents/MacOS/Godot
logs=$(mktemp -d /tmp/gurney-room-test.XXXXXX)
pids=()
trap 'for pid in $pids; do kill "$pid" 2>/dev/null || true; done' EXIT
"$bin" --headless --path "$base/relay" --script res://server.gd >"$logs/relay" 2>&1 &
pids+=($!)
sleep 1
GURNEY_RELAY_URL=ws://127.0.0.1:9080 "$bin" --headless --path "$base/godot" -- --room-create --autostart >"$logs/host" 2>&1 &
pids+=($!)
code=""
for attempt in {1..30}; do
 code=$(sed -n 's/^ROOM_CODE //p' "$logs/host" | head -1)
 [[ -n "$code" ]] && break
 sleep 0.2
done
if [[ -z "$code" ]]; then cat "$logs/relay" "$logs/host"; exit 1; fi
GURNEY_RELAY_URL=ws://127.0.0.1:9080 GURNEY_ROOM_CODE="$code" "$bin" --headless --path "$base/godot" --quit-after 360 -- --room-join --autostart >"$logs/client" 2>&1 &
pids+=($!)
wait $pids[-1]
cat "$logs/host" "$logs/client"
rg -q 'WORLD_SYNC local=2 players=2' "$logs/client"
rg -q 'players=2 ready=2' "$logs/host"
if rg 'SCRIPT ERROR|RPC.*failed|checksum failed' "$logs/host" "$logs/client"; then exit 1; fi
"$bin" --headless --path "$base/relay" --script res://protocol_test.gd
print 'Room relay host/client gameplay sync and protocol tests passed' 
