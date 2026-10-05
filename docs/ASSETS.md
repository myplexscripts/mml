# Bundled assets and provenance

The game uses real imported PNG sprites, tiles and Ogg audio. Its runtime no longer draws the old placeholder characters and buildings. Pixel artwork uses a 16/32px terrain language and layered, larger character and machinery sprites.

## Sources used

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

The yellow Flutter and red roof, MegaMan's blue silhouette, Roll's workshop role, Data's save role, Refractors, Reaverbot eyes, Bonne machinery, segmented health and scrolling blue pause menus are deliberate Legends cues. The garden, shipping, requests, friendship, schedules and day cycle provide the life-sim rhythm.

## Rebuild

```sh
python tools/build_art.py
python tools/build_audio.py
```

The art generator reads the three preserved source PNGs and uses Pillow. The audio generator uses NumPy and ffmpeg. Seeded generation makes the outputs reproducible. Runtime builds require neither tool nor any network access.

Mega Man, Mega Man Legends, MegaMan Volnutt, Roll Caskett, Data, Barrell Caskett, Tron Bonne, Servbots, Kattelox and the Flutter belong to Capcom. This repository is a non-commercial, unofficial fan project.
