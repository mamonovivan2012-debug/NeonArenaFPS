# Neon Arena FPS v4 — Maps & Visual Upgrade

Godot 4.5.1 project. This version focuses on six distinct arena layouts and a visual pass.

## Six different maps
1. Factory — gantries, support columns, heavy machinery, conveyor-like cover lanes.
2. Laboratory — clean test cells, containment pods, luminous research structures.
3. Cyber City — dense building blocks, neon signage, street lanes and elevated silhouettes.
4. Underground — metro tunnel geometry, platform dividers and service structures.
5. Spaceport — launch platforms, docking pylons and large terminal structures.
6. Wasteland — broken cover fields, skeletal industrial remains and dusty lighting.

## Visual/gameplay systems
- Filmic tonemapping, glow, fog, colored ambient lighting and shadowed directional light
- Metallic/roughness materials and emissive trim
- First-person weapon mesh and muzzle flash
- Raycast firing, hit particles, enemy waves, sprint, jump, reload and HUD
- Number keys 1–6 switch maps

## Build
Push all files to GitHub, including `.github/workflows/build.yml` and `export_presets.cfg`.
Open Actions → Build Windows EXE. Download the `NeonArenaFPS-Windows` artifact.

## Honest scope note
This is a procedural playable map/visual upgrade, not a finished 20 GB commercial game. It does not include purchased/artist-authored hero assets, motion-captured character animation, full sound design or cinematic content. Those require additional real asset production; the package is intentionally not padded with junk data.
