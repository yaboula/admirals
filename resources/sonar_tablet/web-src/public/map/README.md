# SONAR Tablet — Map texture assets

## Estado S2.5

- `world.svg` — **PLACEHOLDER** SVG inline (grid + coord reference + origin marker).
  Referenciado por `src/apps/Map/MapCanvas.tsx` como `<img src="/map/world.svg">`.
- `world.jpg` — **pendiente founder** (export real GTA5 minimap atlas).

## Swap a textura real

1. Exportar minimap atlas desde RageEditor u OpenIV:
   - Resolución recomendada **4096×4096** (o 8192×8192 si aspect 16:12 San Andreas real).
   - Format **JPEG quality 82** — target filesize ≤800KB (D6 R2 bundle adjacent).
   - Bounds canonical GTA5 V usados en proyección:
     `Config.MapWorldBounds = { min_x=-4000, max_x=4500, min_y=-4000, max_y=8000 }`.
2. Colocar archivo aquí: `resources/sonar_tablet/web-src/public/map/world.jpg`.
3. Actualizar `src/apps/Map/MapCanvas.tsx` → `src="/map/world.jpg"`.
4. Verificar coords: player en world `(0, 0)` debe alinear visual al origen del atlas
   (cross-hair del placeholder SVG ayuda como guía durante validación).
5. `npm run build` y confirmar bundle output:
   - `web/map/world.jpg` presente.
   - JS main ≤500KB gzip (textura NO entra al JS bundle, va en `/map/` raíz
     servido por FiveM vía `fxmanifest.files` patrón `web/map/*`).

## Notas técnicas

- `preserveAspectRatio="none"` en `<svg>` de `MapCanvas` permite que la textura
  rellene el viewport sin letterbox. Los ejes GTA5 son: `+X` Este, `+Y` Norte
  (NO cartesiano SVG). La proyección `worldToViewport()` en `lib/projection.ts`
  aplica flip `y = (max_y - world_y) / (max_y - min_y)`.
- Filesize límite hard: **≤1MB** por archivo (prompt S2.5 rule). Si founder
  proporciona atlas >1MB → flag issue + defer optimization (convert to WebP
  quality 80 reduce ~40% vs JPEG q82 equivalent SSIM).
