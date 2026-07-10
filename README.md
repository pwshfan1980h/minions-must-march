# Minions Must March

A Godot 4 Lemmings-inspired puzzle game about little lanky skeleton minions doing unsafe civil engineering in crumbling crypts.

## Current Status

Playable 12-level campaign:

- Four assignable skills: Block, Build, Dig, and Featherfall
- Multi-tier crypt and Ash Catacombs puzzles with crumbling terrain and Styx hazards
- Campaign map, rescue scoring/progress, pause-and-inspect mode, and 1×–3× march speed
- Procedural skeleton animation, terrain art, atmosphere, particles, and sound feedback
- Headless feature, skill-activation, audio, and full-campaign configuration checks
- Web export preset for browser testing

## Controls

- Click the spawn portal to begin; choose a skill and click a skeleton to assign it
- `1`–`4`: select Block, Build, Dig, or Featherfall
- `A`/`D`, arrows, or mouse wheel: pan the chamber
- `F`: cycle march speed; `Space`: pause and inspect; `R`: restart
- `F4`: open the chamber map

## Open in Godot

Open this repository folder in Godot 4.x and run the main scene.

Run the automated checks with:

```bash
python3 scripts/tools/headless_feature_checks.py
godot --headless --path . -s tests/campaign_smoke_check.gd
godot --headless --path . -s tests/builder_activation_check.gd
godot --headless --path . -s tests/digger_activation_check.gd
```

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
