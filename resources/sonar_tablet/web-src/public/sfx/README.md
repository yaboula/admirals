# SFX Assets — SONAR Tablet (S2.6)

Place the 5 canonical OGG files here. Vite serves `public/` statically at root (`/sfx/<name>.ogg`).

## Required files

| File | Sound | Trigger |
|---|---|---|
| `signal_emerge.ogg` | App open / data loaded | Bank app mount, Map app mount |
| `depth_press.ogg` | Confirm / ceremonial press | Transfer success |
| `layer_dive.ogg` | Sub-view dive | Bank tab click |
| `console_tap.ogg` | Premium click tap | AppTile activate |
| `panel_open.ogg` | Panel / modal reveal | Tablet frame open |

## Specs (brief_sound production brief — S3+)

- Format: OGG Vorbis, mono, 44100 Hz, ~128 kbps
- Duration targets:
  - `console_tap`: ≤100ms
  - `depth_press`: ≤300ms
  - `layer_dive`: ≤300ms
  - `panel_open`: ≤500ms
  - `signal_emerge`: ≤800ms
- Normalized: -12 LUFS integrated, -1 dBTP true peak

## Until assets are produced

`sfx.ts` `playSfx()` is a no-op if the pool element is missing (graceful degradation).
The engine will NOT throw or log errors — silent fallback per DC-S2.6.4.
