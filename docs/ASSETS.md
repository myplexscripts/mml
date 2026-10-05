# Asset sourcing

The prototype currently draws its own placeholder pixel art in GDScript so the repository can run without external downloads.

## Approved reference sources

### Mega Man Legends Station / Sky Pirate Arcade

Use for visual reference first. The site maintains MML1/MML2 screenshots, sprite rips, texture dumps, tiles and fan-game resource packs.

Useful resource page:

- `https://arcade.legends-station.com/?id=resource-graphics`

Useful categories include:

- Megaman Digger Casket character sprites
- MML character / Reaverbot sprite packs
- Gold City / Harbor / Ruin tilesets
- MML1 32x32 game-rip tiles
- MML1 and MML2 texture dumps
- official-art styled character sprites

These resources should **not** automatically be treated as freely redistributable just because they are downloadable. Track the source and reuse status before committing files.

## Public-domain source found

### Seeteufel the Mighty

Repository: `https://github.com/Emeltee/iSMG`

The authors state in the repository README that their **original code and art resources are released into the public domain**, including the sprite pack associated with the fangame. That makes its original art a good candidate for temporary prototype assets or edits.

Important distinction: public-domain status applies to original material released by the authors. It does not magically relicense any underlying Capcom-owned character designs, names, music, or ripped game assets.

## Current art policy

Until an asset's reuse status is clear:

1. Use MML screenshots and artwork as **reference**, not as bundled files.
2. Use procedural/original placeholders in the playable build.
3. Prefer public-domain fan resources for temporary art where practical.
4. Keep Capcom-ripped textures and sprites out of the repository unless deliberately added later with clear source notes.
5. Preserve the MML visual language: strong silhouettes, chunky machinery, bright surface colours, geometric ruins, clear Reaverbot eyes, and recognizable character colour blocking.

## Intended sprite scale

For the Stardew-like presentation:

- world tiles: 16x16 or 32x32 source pixels
- main characters: roughly 16x32 to 32x48 source pixels
- large machinery: multiples of 32px
- display scale: integer nearest-neighbour upscale

The goal is not to make MML look like a generic fantasy farming game. The pixel-art treatment should preserve Kattelox architecture, Refractors, the Flutter, Reaverbots, Bonne machinery and the series' colour hierarchy.
