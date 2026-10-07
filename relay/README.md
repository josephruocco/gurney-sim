# Gurney room relay

Status: implemented and tested locally. No public relay is deployed yet.

The game creator remains peer 1 and runs authoritative physics. Both Macs connect
outward over WebSocket to this service. Room codes are eight random hexadecimal
characters. Codes are invitations: anyone with a code can join its waiting lobby.
Maximum four players per room. Starting a run locks the room. Host departure ends
it; there is no host migration or reconnect recovery yet.

## Local verification

Use the same Godot version as the game (currently 4.7.2):

```sh
Godot --headless --path relay --script res://server.gd
```

Set the game's relay address to `ws://127.0.0.1:9080`, enter a player name, and
click Create room. Share the generated code with the other game instance, which
uses the same relay address and clicks Join room. Both click Ready up.

On this development Mac, `godot/tests/run_room_test.sh` starts the relay and two
actual game clients, checks ready/world sync, and exercises invalid room codes,
sender identity, locked-room rejection and host departure. It owns its processes
and cleans them up on exit. Port 9080 must be free.

## Public deployment (remaining step)

Needs a Linux server, a domain pointing to it, and inbound TCP 443 for secure
WebSockets (plus TCP 80 for automatic certificate issuance). Players need no
router port forwarding. Costs/account provisioning are not included.

1. Install the matching official Linux Godot binary at `/usr/local/bin/godot`.
2. Copy this relay directory to `/opt/gurney-relay`.
3. Create an unprivileged `gurney` service user with read access to that directory.
4. Install `gurney-relay.service` into `/etc/systemd/system`, then enable/start it.
5. Install Caddy; replace `relay.example.com` in `Caddyfile` with your domain and
   include that site in its configuration. Keep TCP 9080 private; proxy only via TLS.
6. Verify service logs, then enter `wss://YOUR-DOMAIN` in BOTH game instances.
   The same URL can be prefilled with the GURNEY_RELAY_URL environment variable.
7. Test a full game from two separate networks before distributing a new package.

This is a single-process relay: do not load-balance across independent instances;
room membership is in memory and restarts end active rooms. It caps connections,
rooms, message size and per-connection message rate. It is a private playtest
service, not an authenticated public matchmaking system. WebSocket uses TCP,
so packet loss can delay movement updates. Internet latency still needs testing.

Transport uses Godot's MultiplayerPeerExtension script packet hooks:
https://docs.godotengine.org/en/stable/classes/class_multiplayerpeerextension.html
