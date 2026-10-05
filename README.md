# Mega Man Legends: Kattelox Days

A playable, non-commercial Mega Man Legends fan game with a Stardew-inspired daily rhythm. The Flutter crash-lands on Kattelox, becomes your home, and needs three salvaged systems to fly again. Build a life on the surface, earn Zenny, upgrade your Buster with Roll, explore the northern ruins and face the Bonnes.

**Version 0.3.0: explorable town interiors, three crops, neighbour gifts, breakable salvage, a craftable Grenade Arm and advancing Deep Dig runs. The complete Flutter repair chapter remains playable, and v0.2 saves are compatible.**

![Kattelox town](docs/screenshots/town.png)

## Play on Windows

Download `KatteloxDays-Windows` from the latest successful [build workflow](https://github.com/myplexscripts/mml/actions/workflows/godot-check.yml), extract the ZIP and open `KatteloxDays.exe`. The exported game includes its assets and does not require Godot, Python or Docker.

To run the source, open `project.godot` with **Godot 4.7.2** and press F5. The title screen offers a new adventure or Continue. New Adventure asks before replacing an existing save.

## What is playable

- A detailed pixel-art Kattelox town with the Flutter, crew cabin, City Hall, Junk Shop, museum, cafe, police station, homes, garden, request board, shoreline and ruin lift. Enter the Junk Shop, museum, cafe and City Hall, explore their furnished interiors and use the counters.
- Recognisable MegaMan animation, Roll, Data, Barrell, Amelia, Tron and the Junk Shop Man. Town characters follow daily schedules; daily conversations improve friendship and unlock Roll's seed gifts. Give tomatoes to Roll, fish to Barrell and sunflowers to Amelia, once per person per day.
- Real CharacterBody2D collision and sliding, wall-aware enemy navigation, swept projectile collision, knockback, dash invulnerability, attack telegraphs, lock-on, health, armour, healing and defeat recovery.
- Three distinct ruin layouts, Horokko, Zakobon, Sharukurusu, guardians, a Bonne mech showdown, Servbots, guarded caches and a complete Flutter repair campaign.
- Buster power, rapid-fire and armour upgrades; find the eastern weapon plans and craft Roll's Grenade Arm with scrap, shards and Zenny. Its lobbed shots bounce off walls, use energy and deal splash damage with wall occlusion; Zenny and scrap drops with gravity, bounce and collection; score, combos, Digger ranks and best-dig tracking.
- Twelve farm plots with turnips (3 watered nights), regrowing tomatoes (4 nights, then 2 per harvest) and sunflowers (5 nights); seed selection, hoeing, watering, harvesting, fishing timing challenges, shipping, daily requests, a relic museum and cafe or galley meals.
- Breakable salvage crates drop scrap, Refractor shards and Zenny. Crates stay claimed until the next morning. Deep Dig progresses from depth 4 to 20, rotates connected side-chamber layouts and increases guardian strength and cache rewards.
- Day/night lighting, rainy days, restored energy after sleep, a daily summary and persistent progress.
- Legends-inspired blue and gold menus, segmented health, equipment, a location map, objective journal and the animated scrolling pause background. Options include music, sound effects and reduced motion.
- Three original looping music tracks, original garden/UI Foley and attributed Legends sound effects.

![New crops](docs/screenshots/garden.png)

![Junk Shop interior](docs/screenshots/interior-shop.png)

![Flutter home](docs/screenshots/flutter.png)

## Controls

| Action | Keyboard / mouse | Gamepad |
| --- | --- | --- |
| Move | WASD / arrows | Left stick |
| Interact / advance dialogue | E, F, Space / Enter in menus | A |
| Fire Buster | Hold J / left click to aim | X |
| Lock onto a visible enemy | Hold K / right click | Left shoulder |
| Grenade Arm (after crafting) | L, aim with K | B |
| Choose garden seeds | C / select seeds twice on hotbar | Hotbar / menu |
| Dash | Shift | Right shoulder |
| Use an energy bottle | Q | Y |
| Tools | 1 Buster, 2 hoe, 3 watering can, 4 seeds; T cycles | Click tool buttons |
| Pause / return | Esc / MENU | Start |
| Map / equipment | M / Tab | Pause tabs |
| Sleep near or inside the Flutter | R / interact with bunk | Interact with bunk |
| Fullscreen | F11 | Window controls |

E also handles the garden's next step: till an empty plot, plant a seed, water it, or harvest a mature crop. Press C to choose the crop before planting. Tomatoes stay planted after harvesting and need two watered nights to regrow. In combat areas the Buster equips automatically. Hold lock-on and fire while moving; dash through telegraphed attacks. Gardens and town services are usable from the first day.

## The repair chapter

1. Speak to Roll beside the Flutter to receive the repair plan.
2. Enter the northern lift and clear the stabilizer chambers. Recover the Servo Motor and bring it to Roll.
3. Explore the navigation vault, defeat its guardian and return the Ancient Circuit.
4. Meet Tron in the plaza and defeat the Bonne machine.
5. Enter the Refractor core, defeat the final guardian and recover the Large Refractor.
6. Deliver it to Roll for the ending. Keep playing in town or try a Deep Dig run.

Taking a break to garden, fish, help neighbours and buy upgrades makes the next dig easier. Defeat costs a small amount of Zenny and returns you safely home; repair parts stay with you.

## Saves

Version 2 saves use Godot's `user://kattelox_days_v2.json`. Windows stores this in the game's folder under `%APPDATA%/Godot/app_userdata/`. Data, sleep, the pause menu, area travel, story milestones and the 45-second autosave all save progress. Continue restores equipment, inventory, crops, friendship, daily requests and repair progress, and starts you safely beside the Flutter.

Version 0.3 loads v0.2 saves directly, retaining repair progress, equipment, mature turnips and inventory. New features receive safe defaults. This version uses a separate save from the older prototype. Its old save is preserved. Browser saves belong to the browser and origin where the Web build runs.

## Build and validation

Godot 4.7.2, GDScript, a 640 x 360 logical canvas, nearest-neighbour pixel art and the GL compatibility renderer. Windows is the main target; a single-threaded WebGL 2 build is provided for browser testing.

```sh
python tools/check_game.py --godot godot --export
```

The checked-in workflow imports and parses the project, runs a main-scene smoke check, executes campaign and expansion regression tests, plays the Bonne fight using ordinary movement/fire inputs, and exports Windows and Web artifacts. Runtime errors fail validation even if Godot returns exit code zero. See [validation](docs/VALIDATION.md) and [asset provenance](docs/ASSETS.md).

Art and music are already bundled. `tools/build_art.py` (Pillow) and `tools/build_audio.py` (NumPy and ffmpeg) rebuild the original/derived assets; they are development tools only.

![Legends-inspired pause screen](docs/screenshots/pause.png)

## Credits

Mega Man Legends and its characters, setting and related designs belong to Capcom. This is an unofficial fan project and implies no endorsement. Original Seeteufel the Mighty fan sprites are credited to its authors, and CC0 terrain is by Kenney. Detailed credits and source links are in [ASSETS.md](docs/ASSETS.md).
