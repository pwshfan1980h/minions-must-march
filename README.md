# Minions Must March

A Godot 4 Lemmings-inspired puzzle game about little lanky skeleton minions doing unsafe civil engineering in crumbling crypts.

## Current Status

Early playable prototype baseline:

- Godot 4 project with main scene: `scenes/GameRoot.tscn`
- Lanky skeleton minions spawn, walk, fall, turn around on walls/blockers, and exit
- Fall-death handling with bone-splash feedback
- First job-selection UI foundation with Blocker support
- Web export preset included for early browser testing

## Open in Godot

Open this repository folder in Godot 4.x and run the main scene.

## Web Export

A non-threaded Godot Web export preset is included. Export locally with:

```bash
godot --headless --path . --export-release Web builds/web/index.html
```

Then serve the generated `builds/web/` folder from localhost for a quick smoke test:

```bash
cd builds/web
python3 -m http.server 8088
```

Open `http://localhost:8088/` in a browser. For LAN/device testing, use HTTPS because Godot Web requires a secure context outside localhost.
