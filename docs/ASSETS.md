# Bundled assets and provenance

Version 0.5 uses textured 3D character and machinery models, original environment geometry, imported terrain textures and Ogg audio. The earlier 2D assets remain in the repository for project history; the exported game includes only the current scene and its resources.


## Version 0.4 model resources

[Sky Pirate Arcade model resources](https://arcade.legends-station.com/?id=resource-models) credits **Xinus22** for the contributed packs and **Kion** for the ripping tools. Original game models, textures and designs belong to **Capcom**. Availability on a fan resource site does not establish a commercial redistribution licence. These assets are credited as unofficial fan resources, not CC0 or project-owned art.

| Repository directory | Download pack | Model |
| --- | --- | --- |
| `assets/models/flutter`, `drache`, `feldynaught` | `mml1_vehiclesmecha_pack` | Flutter, Drache and Feldynaught |
| `assets/models/horokko`, `sharukurusu`, `guardian` | `mml1_reaverbots_pack` | Horokko, Sharukurusu and Hanmuru Doll |
| `assets/models/roll`, `data`, `barrell` | `mml1_casketts_pack` | Roll, Data and Barrell |
| `assets/models/tron`, `servbot` | `mml1_bonnes_pack` | Tron and Servbot |
| `assets/models/megaman` | `xinus_megaman` | Custom rigged MegaMan model by Xinus22 |

Downloads use `https://arcade.legends-station.com/dlr.php?dl=<pack>`. FBX models and their matching texture atlases are bundled directly. Import unit corrections normalize the game rips. MegaMan's source FBX was reduced to visible character meshes and converted to GLB with Godot; unused helmet/special-weapon geometry was removed. TIF body/weapon textures were converted to PNG with Pillow. Embedded GLB textures are extracted by Godot on import. Skeleton posing is authored in `scripts/legends/models.gd`; no external animation pack is claimed.

The Flutter landing, crew cabin, connected ruin chambers, Bonne arena, scenery, lights, collision geometry and menus are built in `scripts/legends/`. Version 0.5 uses selected original MML texture crops for the island, landing apron, ruins, staircase and cabin. Original music and attributed game sound effects retain their credits below.

## Earlier assets and reused textures/audio

| Files | Source | Reuse status / contribution |
| --- | --- | --- |
| `assets/source/seeteufel.png`; MegaMan animation, Bonne mech, Refractors, ruin panels and pillars derived from it | [Seeteufel the Mighty, Emeltee/iSMG](https://github.com/Emeltee/iSMG), `my-gdx-game-android/assets/img/seeteufelScreen.png` | The authors release their **original** code and art into the public domain. Their README is preserved as `SEETEUFEL_LICENSE.md`. This does not relicense Capcom character designs. Cropped and adapted by `tools/build_art.py`. |
| `assets/source/kenney_town.png`; grass details, trees and bushes | [Kenney Tiny Town](https://kenney.nl/assets/tiny-town), mirrored in [GeorgeQLe/assets-2d-city](https://github.com/GeorgeQLe/assets-2d-city) | CC0. The pack's licence text is preserved. Used and adapted for the surface terrain. |
| `assets/source/kenney_urban.png` | Kenney RPG Urban pack in the same mirror | CC0 reference source retained for the reproducible pipeline. Final town paving is original. Licence text is preserved. |
| `assets/audio/buster.ogg`, `item.ogg`, `hurt.ogg`, `hit.ogg`, `explosion.ogg`, `door.ogg` | The iSMG audio directory: `sfx-buster-fire1`, `sfx-item-get`, `sfx-hurt1`, `sfx-reaverhurt1`, `sfx-grenade-explode1`, `sfx-ruindoor-open1` | Legends game sound effects distributed with the fan resource project. Treat as Capcom game audio; the original-art public-domain declaration is **not** a licence for these recordings. Kept separately from the original music/Foley and credited here. |
| Remaining character/enemy sheets, buildings, Flutter, cabin furniture, crops, icons, paving, decorations and UI treatment | Original artwork in `tools/build_art.py` | Created for this fan game, with MML characters, machinery and colour language as references. |
| `town.ogg`, `ruins.ogg`, `boss.ogg`, `select.ogg`, `water.ogg`, `step.ogg`, `plant.ogg` | Original compositions and synthesised Foley in `tools/build_audio.py` | Created for this project; these are not ripped game music. Three distinct, seamless town/ruin/battle loops. |

The source images and licence notices are bundled in the repository but excluded from exported games, along with authoring tools, tests and documentation. The game loads the resulting PNG and Ogg files directly.

## Legends Station references

The user's supplied resources informed the design and helped identify the Seeteufel fan pack:

- [Sky Pirate Arcade creation resources](https://arcade.legends-station.com/?id=create)
- [Graphics resource directory](https://arcade.legends-station.com/?id=resource-graphics)
- [Audio resource directory](https://arcade.legends-station.com/?id=resource-audio)
- [MML1 character reference](https://www.legends-station.com/?id=mml1-characters)
- [MML1 sprite reference](https://www.legends-station.com/?id=mml1-sprites)
- [Mega Man Legends](https://www.legends-station.com/?id=mega-man-legends)
- [Mega Man Legends 2](https://www.legends-station.com/?id=mega-man-legends-2)

The yellow Flutter and red roof, MegaMan's blue silhouette, Roll's workshop role, Data's save role, Refractors, Reaverbot eyes, Bonne machinery, segmented health and scrolling blue pause menus are deliberate Legends cues. The earlier garden and town routines are superseded by the top-down action chapter in version 0.4.

## Rebuild

```sh
python tools/build_art.py
python tools/build_audio.py
```

The art generator reads the three preserved source PNGs and uses Pillow. The audio generator uses NumPy and ffmpeg. Seeded generation makes the outputs reproducible. Runtime builds require neither tool nor any network access.

Mega Man, Mega Man Legends, MegaMan Volnutt, Roll Caskett, Data, Barrell Caskett, Tron Bonne, Servbots, Kattelox and the Flutter belong to Capcom. This repository is a non-commercial, unofficial fan project.

## Version 0.3 expansion

The tomato and sunflower sprites, seedlings, shop counter, stock shelves, cafe tables, plant pots, museum display cases, salvage crates and weapon plans are original pixel art from `tools/build_art.py`. They add no new third-party licences. The Grenade Arm is a Mega Man Legends-inspired mechanic; the [Legends Station special-weapon reference](https://www.legends-station.com/?id=mml1-special-weapons) informed the design. Projectile visuals and explosion particles are drawn by the game. Existing credited Refractor shard graphics and sound effects are reused.

## Version 0.5 visual resources

| Files | Source and credit | Adaptation |
| --- | --- | --- |
| `assets/legends/stone.png`, `hex_floor.png`, `wall.png`, `wall_cap.png`, `metal.png`, `sand.png`, `pillar.png`, `circuit.png`, `water.png` | [MML1 Game Rip Tiles](https://arcade.legends-station.com/resources/tex_fab_gamerip1.png), ripped and contributed by **fAB**, original Capcom textures | Exact 32 × 32 crops; runtime tints recorded in world.gd. |
| `assets/legends/grass.png`, `grass_worn.png`, `cabin_metal.png`, `cabin_panel.png` | [MML1 complete texture dump](https://arcade.legends-station.com/resources/mml1_texture_dump.rar), contributed by **DylanTheCG**, original Capcom textures | Selected palette variants and exact crops, recorded by original hashed filename in `assets/legends/provenance.json`. |
| `assets/models/container` | [MML1 Misc model pack](https://arcade.legends-station.com/dlr.php?dl=mml1_misc_pack), contributed by **Xinus22**, ripping tools by **Kion** | Original ItemContainer FBX and matching KONTE texture, used for salvage and service containers. |
| `assets/fonts/BarlowCondensed-SemiBold.ttf` | [Barlow Condensed](https://github.com/google/fonts/tree/main/ofl/barlowcondensed), **Jeremy Tribby** | SIL Open Font License 1.1, included in assets/fonts/OFL.txt and each build ZIP as FONT-LICENSE.txt. |

Selected source PNGs are preserved in `assets/source/legends`. Run `python tools/build_legends_textures.py` to recreate all crops without downloading the full texture dump. The geometry, landings, staircase, radar, field log, card treatment and colour choices are authored in this project. These are actual runtime resources, not screenshot overlays.

The Flutter retains its source model's upright landed orientation, with the deck above the cabin and the fin pointing upward. Landing supports, a boarding staircase and railings are authored around that orientation.
