# Shardbound — Godot 4.5 (Windows) version

HD-2D port of the web demo: pixel-art sprites as billboards inside lit 3D rooms
(torch lights with shadows, glow, fog, depth of field). Same rules, data, music and unlocks as the web demo.

## Open / run
1. Install **Godot 4.5.x** (standard build) from godotengine.org.
2. Open `godot/project.godot` in Godot and press **F5**.

## Build a Windows .exe
Editor: **Project → Export → Windows Desktop → Export Project** (install export templates when prompted).
Command line:
```
godot --headless --path godot --export-release "Windows Desktop" build/Shardbound.exe
```

## Layout
| Path | What |
|---|---|
| `scripts/data.gd` | All game data: heroes, skills, relics, enemies, floors, upgrades, feats |
| `scripts/game.gd` | Game flow: title, camp, runs, floor generation, rooms, shop, unlocks |
| `scripts/battle.gd` | Turn-based battle engine |
| `scripts/world.gd` | 3D scenes (rooms, battle arena, camp) and effects |
| `scripts/ui.gd` | FF-style windows, menus, HUD, minimap |
| `scripts/meta.gd` | Permanent progress (saved to `user://meta.json`) |
| `scripts/audio.gd` | Music, jingles, sound effects |
| `scripts/autotest.gd` | Automated play-tester: `godot --path godot -- --autotest [--cheat] [--shots]` |
| `assets/` | Sprites, textures, music/SFX (rendered from the web demo), fonts (OFL) |
| `art_src/` | Pixel-art source (Python): heroes.py (poses), monsters.py, props.py |
