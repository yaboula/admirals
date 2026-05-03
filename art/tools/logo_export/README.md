# Logo Export Tool

Renders SVG sources in `art/branding/logo_v2/` to PNG raster exports + `favicon.ico`.

## Usage

```bash
cd art/tools/logo_export
npm install
npm run build
```

Outputs to `art/branding/logo_v2/exports/`.

## Deliverables (per `docs/art/briefs/01_brief_logo.md` v2 §2.1)

### Monograma
- `monogram_16.png`, `monogram_32.png` (favicons)
- `monogram_64.png`, `monogram_128.png`, `monogram_256.png`, `monogram_512.png`, `monogram_1024.png`

### Monograma solid (stamp variant ≤32px)
- `monogram_solid_16.png` → `monogram_solid_256.png`

### Monograma light (inverse canvas, hybrid theme)
- `monogram_light_64.png` → `monogram_light_512.png`

### Wordmark
- `wordmark_256.png`, `wordmark_512.png`, `wordmark_1024.png`, `wordmark_2048.png`

### Lockups
- `lockup_horizontal_512.png`, `_1024.png`, `_2048.png`
- `lockup_vertical_256.png`, `_512.png`, `_1024.png`

### Favicon
- `favicon.ico` multi-res composite (16+32+48)

## Stack

- `sharp` ≥0.33 — SVG to PNG rasterization (libvips backend)
- `png-to-ico` ≥2.1 — multi-resolution ICO composite

## Notes

- Node ≥18 required (ESM + `node:` imports).
- `node_modules/` gitignored per project root `.gitignore` line 15.
- Regenerate exports when SVG sources in `art/branding/logo_v2/` change.
