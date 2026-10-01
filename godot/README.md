# Gurney Simulator Co-op

Godot 4 rewrite of the shared-gurney co-op prototype. The web/iOS game is a design reference only.

## Run

Open `project.godot` in Godot 4.7, or run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --editor --path godot
```

Choose **Solo** for one instance. For local multiplayer, choose **Host** in one instance and **Join localhost** in another. Players use WASD, E to grab or release the gurney, and Space to brake. Inputs are sent to the host, which owns the shared gurney simulation.

## First milestone scope

- One shared rigid-body gurney
- Host-authoritative combined push, brake, and steering inputs
- Sliding rigid-body patient whose position affects balance
- Player weight and lean affecting gurney balance
- Parking-garage roof-to-street switchback with parked and moving traffic
- Broken-guardrail balance shortcut, concrete columns, cones, and finish bay
- ENet host/client flow for local multi-instance testing
- Placeholder procedural geometry only
