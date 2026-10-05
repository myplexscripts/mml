# Mega Man Legends: Kattelox Days

A non-commercial **Mega Man Legends** fan-game prototype that combines the broad story structure and lore of **Mega Man Legends 1** with a more relaxed, top-down life-sim rhythm inspired by games like Stardew Valley.

The core idea is simple: **the Flutter is your home from the beginning**. It crash-lands on Kattelox Island, and MegaMan and Roll have to live there while repairing it. Daily life in town, relationships, scavenging, Digger work, Refractors, ruins, Reaverbots, the Bonnes, and Flutter repairs all feed into the same progression loop.

## Current prototype

The first playable vertical slice includes:

- MegaMan movement and four-direction Buster combat
- Kattelox surface area with a damaged Flutter, City Hall, Junk Shop, Museum, Cafe, Police Station, shoreline and ruin entrance
- Roll, Data, Barrell, Mayor Amelia and Tron Bonne
- time of day and day counter
- simple daily NPC schedules
- friendship counters
- Zenny rewards
- a hand-built Kattelox ruin layout
- Reaverbot encounters
- Servo Motor and Ancient Circuit salvage
- a large Refractor objective
- Bonne/Servbot ambush event
- staged Flutter repairs at 34%, 67% and 100%
- sleeping aboard the Flutter to advance the day
- save-on-sleep to `user://kattelox_days_save.json`
- a complete prototype arc from the crash to making the Flutter flightworthy again

This is intentionally a **prototype**, not an attempt to duplicate MML1 scene-for-scene. The story beats, characters, terminology and world logic are based on the source game, while the daily-life structure and top-down presentation are an original reinterpretation.

## Engine

- **Godot 4.7.x**
- GDScript
- 640x360 internal canvas
- nearest-neighbour texture defaults
- GL compatibility renderer for broad Windows hardware support

No Docker is needed.

## Run it

1. Install Godot 4.7.x for Windows.
2. Clone or download this repository.
3. Open `project.godot` in Godot.
4. Press **F5** or click Run Project.

The project opens directly into the prototype.

## Controls

| Action | Key |
| --- | --- |
| Move | WASD or Arrow Keys |
| Talk / interact | E, F or Space |
| Fire Mega Buster | J |
| Dash | Shift |
| Sleep aboard Flutter | R |
| Advance dialogue | E, F, Space or Enter |
| Quit | Escape |

## Prototype progression

1. Talk to Roll beside the crashed Flutter.
2. Enter the northern Kattelox ruins.
3. Recover the Servo Motor.
4. Return it to Roll to repair the first Flutter system.
5. Recover the Ancient Circuit.
6. Return it to Roll to restore navigation systems.
7. Deal with Tron and the Servbot ambush in Central Kattelox.
8. Return to the ruins and recover the large Refractor.
9. Bring it to Roll to restore the Flutter's main engine.

## Design rules

The project should continue following these rules:

- **The Flutter is always MegaMan's home.** Do not replace it with a generic farmhouse.
- Surface life should feel warm, human and lived-in. Ruins should feel ancient, mechanical and uncanny.
- Refractors are important infrastructure and treasure, not generic crystals.
- Roll is the mechanical heart of progression. Salvaged parts should become repairs, upgrades and special weapons through her.
- Reaverbots should have varied silhouettes and body plans rather than all being humanoid robots.
- The Bonnes should remain colourful, funny and mechanically inventive without losing their threat.
- Kattelox should feel like a real community with schedules, shops and reasons to spend time above ground.
- The game can borrow the daily-life pacing of Stardew Valley, but it should always read as **Mega Man Legends first**.

## Art direction

The current build uses procedural placeholder pixel art so the game is immediately playable without external assets.

The intended direction is:

- top-down pixel art
- cleaner and more detailed than the current placeholders
- readable 16px/32px tile language similar to classic life sims
- MML's actual colours, silhouettes and machinery
- bright surface world, darker geometric ruins
- chunky machinery, visible rivets, panels, pipes and exaggerated shapes
- no generic fantasy RPG art

A public-domain Mega Man Legends fangame sprite source has also been identified for later asset replacement. See `docs/ASSETS.md`.

## Fan project note

This is an unofficial fan project. Mega Man, Mega Man Legends, MegaMan Volnutt, Roll Caskett, Data, Barrell Caskett, Tron Bonne, the Servbots, Kattelox, the Flutter and related names and concepts belong to Capcom.

The repository should not imply endorsement by Capcom. Any third-party or ripped game assets should be tracked separately with their source and reuse status before being committed.
