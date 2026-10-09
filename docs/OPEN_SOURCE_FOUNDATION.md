# Open-source foundation strategy

## Decision

Keep the existing `myplexscripts/mml` Godot project as the game core.

The project already has MML-specific fixed-angle 3D movement, Buster combat, targeting, enemies, bosses, dialogue, saving, scene transitions and imported Legends assets. Replacing that work with a complete 2D farming-game repository would create more migration work than it removes.

Instead, use permissively licensed Godot projects as donor/reference implementations for generic RPG systems, then integrate only the systems that improve the MML reconstruction.

## Primary donor reference

### SELODEV Free Starter Kit

Repository: `seloc0des/free-starter-godot`

License: MIT.

Engine: Godot 4.5 or newer.

Useful systems present in the open-source kit:

- dialogue
- quests
- save/load
- controller/interactions
- inventory
- equipment
- loot
- crafting
- vendor
- stats/skills
- combat
- enemy AI
- scene flow
- audio

Its strongest architectural lesson for this project is that story and quest content can be data-driven instead of being embedded throughout one gameplay script.

The MML project does not need its 2D controller or combat replacement. Those are already MML-specific and 3D here.

## First integration

The first integration is the new native MML progression layer in `scripts/legends/progression.gd`.

It provides:

- named story flags
- named integer counters
- tracked objectives with required counts
- guarded campaign advancement
- serialization for save/load
- a fixed twenty-step MML1 campaign range

The existing `scripts/legends/state.gd` now saves this progression payload as save schema version 2 while still accepting version 1 saves. The old vertical-slice fields remain temporarily so existing gameplay and saves do not break during migration.

`data/mml1_campaign.json` contains the twenty-step campaign backbone from the project's MML1 reference bible. Future scene logic should refer to this campaign data and named story state rather than adding more one-off booleans to `state.gd`.

## Migration order

1. Replace the invented Flutter repair vertical-slice progression with the original Ocean Tower opening and Cardon Forest crash sequence.
2. Move objective text and unlock conditions out of `main.gd` and into campaign/event data.
3. Convert NPC conversations and interaction triggers to named story flags and objectives.
4. Convert bosses, gates, licences, refractors and Sub-Gate progression to named flags/counters.
5. Add reusable inventory/item definitions where the existing parts arrays become too limited.
6. Add shop/vendor infrastructure for the Junk Store.
7. Add optional SDV-style life-sim systems only after the original MML1 campaign loop is structurally complete.

## Licensing rule

Architecture ideas do not require copied donor code. If source code from an MIT donor is directly copied or substantially adapted in a future integration, preserve its copyright and MIT notice in the repository and document the imported files here.
