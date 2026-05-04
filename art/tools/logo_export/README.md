# Logo Export Tool

Renders SVG sources in `art/branding/logo_v3/` to PNG raster exports + `favicon.ico`.

## Usage

```bash
cd art/tools/logo_export
npm install        # downloads Chromium ~300MB on first run
npm run build
```

Outputs to `art/branding/logo_v3/exports/`.

## Deliverables (35 files)

### Monograma orange (default)
- `monogram_{16,32,64,128,256,512,1024}.png`

### Monograma white (sobre orange/black)
- `monogram_white_{64,128,256,512}.png`

### Monograma black (sobre white)
- `monogram_black_{64,128,256,512}.png`

### Monograma solid (stencil ≤32px legibility)
- `monogram_solid_{16,32,64,128,256}.png`

### Monograma light (stroke 3px, hero/large)
- `monogram_light_{64,128,256,512}.png`

### Wordmark + Lockups (Syncopate Bold + stencil masks)
- `wordmark_{256,512,1024,2048}.png`
- `lockup_horizontal_{512,1024,2048}.png`
- `lockup_vertical_{256,512,1024}.png`

### Favicon
- `favicon.ico` multi-res composite (16+32+48 desde `monogram_s_solid.svg`)

## Stack

- `puppeteer` ≥23.6 — headless Chromium para rasterización SVG → PNG con full web-font support
- `png-to-ico` ≥2.1 — multi-resolution ICO composite

## ¿Por qué Puppeteer y no sharp?

`sharp` (libvips/librsvg backend) **ignora** `@font-face` declarations dentro de `<style>` SVG, incluso con `src: url(data:font/woff2;base64,...)` inline. Resultado: wordmark + lockups renderizaban con system fallback (DejaVu/Liberation) en vez de Syncopate.

Puppeteer usa Chromium real → soporta `@import url('https://fonts.googleapis.com/...')` nativamente + `document.fonts.ready` hook garantiza fonts cargados antes del screenshot. Fidelidad 100% con `preview.html`.

Tradeoff: ~300MB Chromium binary, ~2-3s slower per render. Aceptable para pipeline batch que corre raras veces (al cambiar SVG sources).

## Notes

- Node ≥18 required (ESM + built-in `fetch` + `node:` imports).
- `node_modules/` gitignored per project root `.gitignore`.
- Chromium auto-descargado por puppeteer en primer `npm install` (cache en `%LOCALAPPDATA%\puppeteer`).
- Regenerar exports cuando cambien SVG sources en `art/branding/logo_v3/`.
