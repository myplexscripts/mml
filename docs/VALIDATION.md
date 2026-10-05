# Flutterbound 0.5.0 validation

Godot **4.7.2**, GL compatibility renderer, 1280 × 720 UI, fixed overhead 3D camera and 60 Hz physics. Windows x86_64 and single-threaded WebGL 2 exports.

## Automated checks

`python tools/check_game.py --godot godot --export` imports the source, rejects runtime errors, executes the following checks and exports both targets:

- **31 campaign/physics checks:** upright Flutter landing, climbable staircase ramp, title/new adventure, quest start, cabin healing, input movement, merged-wall collision, dash movement/energy, guarded cache, loot/score, all three repairs, guardian/Tron appearance, Bonne unlock, ending, priced upgrade, Grenade Arm crafting, advancing Deep Digs, bottle use, defeat recovery, atomic save/reload credits navigation, safe new-adventure cancellation, thin meter dimensions, locked-floor rejection and saved camera zoom.
- **Normal-input Bonne playtest:** active AI, ordinary movement, lock-on, Buster fire and dash, starting armour/power and three bottles. The recorded run defeats the Feldynaught with 100 health, three bottles remaining and 1315 score. No enemy health reduction, frozen enemies or player-stat boosts are used for this fight.
- **Isolated combat checks:** keyboard hold/release charges for 40 damage even while normal fire is held; right-stick aim takes priority over stale mouse aim; hits expose health feedback; swept shots stop at arena walls; rigid-body grenade splash deals 48 damage; pause freezes and resume advances projectiles. Enemies are frozen only for these isolated collision/damage assertions.
- **Self-contained exports:** Windows embedded pack and Web PCK mounted from an empty project. All four areas start, visible actor meshes have textures, music is available and tests/authoring tools are excluded.

## Rendered and browser checks

`tests/legends_visual.gd` captures the title, crew dialogue, Flutter landing, cabin, workbench, five pause tabs, ruins, map and Bonne arena with actual native rendering. Reviewed with Mesa OpenGL; no script errors or leaked resources remain. Screenshots in the README come from the running game.

`tools/browser_check.cjs` uses a fresh Playwright browser profile. Chromium 154 / WebGL 2 renders the actual textured models. The playtest exercises dialogue, mouse fire/charge, movement/dash, pause/options/map, IndexedDB persistence, reload and Continue, and rejects browser/Godot errors. Reduced-motion and zoom settings survive the reload.

`tools/package_game.py` adds instructions and asset credits, checks ZIP integrity and compares the packaged executable/PCK bytes with the verified exports.

## Limits

Native Windows execution has not been tested in this Linux environment. The Windows executable and embedded assets are validated structurally and loaded as a resource pack. The browser test covers startup/controls/save behaviour; the full story progression is exercised by the Godot campaign test. Visual animation uses procedural rig posing rather than a full authored animation set. This is one complete fan-game repair chapter with repeatable digs, not the original games' full campaign.
