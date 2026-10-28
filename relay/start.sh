#!/bin/bash
set -euo pipefail
export PORT="${PORT:-10000}"
envsubst '${PORT}' < /app/nginx.conf.template > /tmp/nginx.conf
nginx -t -c /tmp/nginx.conf
pids=()
cleanup() {
    trap - EXIT TERM INT
    if ((${#pids[@]})); then
        kill "${pids[@]}" 2>/dev/null || true
        wait "${pids[@]}" 2>/dev/null || true
    fi
}
trap cleanup EXIT
trap 'exit 0' TERM INT
PORT=9080 BIND_ADDRESS=127.0.0.1 godot --headless --path /app --script res://server.gd &
pids+=($!)
nginx -c /tmp/nginx.conf -g 'daemon off;' &
pids+=($!)
# Stop the whole container if either service exits, so Render can restart it.
wait -n "${pids[@]}"
exit 1
