# 🎨 Admirals — Shader Contracts (3D ↔ Code)

> **Versión:** 1.0 (firmado — completo, 14 secciones, 2 partes publicadas).
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2 (§13.4 — División 3D vs Código)
> **Documento hermano principal:** `art/01_art_direction.md` v1.0 (§15 Materiales en mundo).
> **Documentos referenciados:** todos los nodos §11.4 (`01_node_farm.md`, `03_node_mill.md`, `04_node_bakery.md`, `05_node_retail.md`) + `02_sonar_tablet.md` §12 (NUI design system) + `technical/01_architecture.md` §13 (NUI técnico).
> **Estado:** firmado.

> **Lectura previa obligatoria:** Bible §13.4 (3D vs Código), Art Direction §15-§17 (materiales + escenografía), cada node doc §11 (assets 3D) + §11.4 (uniforms expuestos).

---

## 0. Resumen ejecutivo

Este documento es **el contrato canónico entre el equipo 3D y el equipo de código** para todos los materiales y shaders del ecosistema Admirals.

Define:

- **Qué materiales existen** (catálogo unificado `mat_*`).
- **Qué uniforms expone cada material** al código (`fill_count`, `oven_glow`, `belt_speed`, etc.).
- **Quién es owner** de cada uniform (qué resource lo escribe).
- **Qué rangos válidos** tiene cada uniform y qué pasa fuera de ellos.
- **Cómo se valida** que 3D y Código respetan el contrato (testing protocol).
- **Performance budgets** por material (instrucciones GPU, pase render).

> **El contrato es de cumplimiento bilateral:** 3D entrega meshes + texture sets + shaders con los uniforms documentados expuestos. Código escribe esos uniforms en runtime y NUNCA invade el dominio del 3D (no añade materiales nuevos sin actualizar este doc).

---

## 1. Filosofía y scope

### 1.1 ¿Qué es un shader contract?

Un **shader contract** es la especificación pública de un material: qué entradas acepta del código (uniforms), qué salidas visuales genera, qué rangos son válidos, qué pasa en edge cases.

> **Analogía:** un shader es como una API REST. El 3D escribe el "servidor" (el shader). El código escribe el "cliente" (las llamadas que setean uniforms). **Ambos consultan este doc para mantener compatibilidad.**

### 1.2 Lo que SÍ cubre este documento

- ✅ Catálogo de **todos** los materiales custom de Admirals (`mat_admirals_*`, `mat_farm_*`, `mat_mill_*`, etc.).
- ✅ **Uniforms** expuestos por cada material (nombre, tipo, rango, default, owner resource).
- ✅ **División de responsabilidades** 3D ↔ Code para cada material.
- ✅ **Performance budget** (GPU cost orientativo).
- ✅ **Validación** y testing protocol.
- ✅ **Naming conventions** y versioning de materiales.

### 1.3 Lo que NO cubre este documento

- ❌ Implementación interna del shader (el `.fxc`/`.shader` source es propiedad del 3D — no la replicamos aquí).
- ❌ Materiales nativos GTA V sin custom (esos se reusan tal cual).
- ❌ Texture sets (las texturas en sí — eso es Art Direction §15).
- ❌ Lighting global / post-FX scene-wide (Art Direction §14).
- ❌ Particle systems FX (eso es Art Direction §13 — aunque algunos comparten uniforms con materiales).

### 1.4 Anti-patrones que este contrato previene

- ❌ **3D entrega material sin uniforms expuestos** → código no puede animar nada → wow muerto.
- ❌ **Código escribe uniforms inventados** → shader los ignora silenciosamente → bug invisible.
- ❌ **Cambios de uniforms sin coordinar** → fixed values no se actualizan → memoria/glitches.
- ❌ **Materiales con nombres genéricos** (`mat_metal_1`) → colisiones cross-team → confusion.
- ❌ **Sin versioning** → swap de mesh con shader incompatible → crash.
- ❌ **Sin performance budget** → shader heroico tira FPS de servidores low-end.

---

## 2. División 3D vs Código — recordatorio canónico

> **Recapitulación de Bible §13.4 aplicada a shaders.** El contrato shader es la **interfaz** entre estos dos equipos.

### 2.1 Responsabilidades 3D (entrega del shader)

El equipo 3D entrega:

1. **Mesh** (modelo geométrico).
2. **Texture set** (color + normal + roughness + emissive maps).
3. **Shader** (`.fxc` para FiveM, basado en `default.fxc` o custom-extended).
4. **Variantes estáticas** del material (presets canónicos para previews).
5. **Documentación de uniforms** (en este doc — sección por nodo).

> **Wow CORE:** el shader **ya entrega visualmente** la idea wow incluso sin código (con uniforms en valores default). Si el horno apagado se ve hermoso, encendido se ve épico — **el degradé visual lo entrega 3D, no código**.

### 2.2 Responsabilidades Code (escribir uniforms)

El equipo de código:

1. **Escribe valores de uniforms** según estado del juego (eventos `admirals:*`).
2. **NO modifica meshes** ni shaders ni texturas.
3. **NO inventa uniforms** que no estén en este contrato.
4. **Suscribe a eventos** del bus que mutan estado relevante.
5. **Optimiza writes** (no escribir todos los frames si el valor no cambió).

> **Wow ENHANCEMENT:** el código añade **dinamismo, glow procedural, pulsing, sound-sync, FX sync**. El horno encendido respira con el código.

### 2.3 Tabla resumen de la división

| Capacidad | 3D (modelo) | Code (uniforms) |
|---|---|---|
| Geometría | ✅ | ❌ |
| Texturas base (color/normal/roughness) | ✅ | ❌ |
| Emissive map base | ✅ | ❌ |
| Glow intensity dinámico | ❌ | ✅ (`emissive_intensity`) |
| Color tint dinámico | ❌ | ✅ (`tint_*`) |
| Animación interna shader (UV scroll, vertex deform) | ✅ (parametrizado) | ✅ (control de uniforms) |
| Visibility de sub-meshes | ✅ (variantes) | ✅ (`visibility_mask` uniform) |
| Sounds | ❌ | ✅ |
| FX particles | ✅ (asset prefab) | ✅ (trigger + uniforms color/rate) |
| Post-FX layer | ❌ (lighting) | ✅ (uniforms a la cámara) |

---

## 3. Catálogo unificado de materiales

### 3.1 Naming convention

```
mat_<dominio>_<asset-base>_<variante?>
```

Ejemplos válidos:
- `mat_farm_field_wheat` — campo de trigo en Farm.
- `mat_mill_stone_grinding` — piedra molturadora del Molino.
- `mat_bakery_oven_door` — puerta del horno Bakery.
- `mat_bakery_dough_proofing` — masa fermentando.
- `mat_retail_shelf_white` — lineal supermercado.
- `mat_tablet_screen` — pantalla Admirals Tablet.
- `mat_admirals_brass_polished` — brass signature compartido.

**Reglas:**
- snake_case obligatorio.
- Dominio explícito (`farm` / `mill` / `bakery` / `retail` / `tablet` / `admirals` para shared).
- Sin números si hay solo 1 variante.
- Variante con sufijo descriptivo (`_v1`, `_proofing`, `_polished`).

### 3.2 Versioning

Cada material tiene **schema_version** en su definición. Cambios breaking → bump version → ambos equipos sincronizan.

```
mat_bakery_oven_door @schema 1.0
  └─ uniforms: [oven_glow, door_open]
mat_bakery_oven_door @schema 1.1
  └─ uniforms: [oven_glow, door_open, smoke_density]   ← uniform añadido
```

> **Política:** uniforms **adding-only** son non-breaking. Renames o removes son **breaking** → bump major.

### 3.3 Total de materiales custom oleada 1

| Dominio | Materiales custom | Detalle en sección |
|---|---|---|
| `farm` | ~12 | §5 |
| `mill` | ~8 | §6 |
| `bakery` | ~14 | §7 |
| `retail` | ~10 | §8 |
| `tablet` | ~6 | §9 |
| `admirals` (shared) | ~5 | §10 |
| **Total custom** | **~55 materiales** | |

> **Comparación:** una resource AAA típica en FiveM tiene 80-150 materiales custom. Admirals oleada 1 con 55 está **dentro de budget conservador**.

---

## 4. Catálogo unificado de uniforms

### 4.1 Tipos de uniforms soportados

| Tipo | Descripción | Ejemplo |
|---|---|---|
| `bool` | true/false | `door_open` |
| `int` | entero | `fill_count` (0-30) |
| `float` | decimal | `emissive_intensity` (0-1) |
| `vec2` | 2 floats | `uv_scroll_speed` |
| `vec3` | 3 floats (RGB / pos) | `tint_color` |
| `vec4` | 4 floats (RGBA) | `glow_color_alpha` |
| `string` | texto (text-rendering only) | `signage_text`, `lcd_total_text` |
| `texture_id` | ID de textura swappable | `signage_logo` |

### 4.2 Categorías semánticas de uniforms

> **Patterns recurrentes** que aparecen en múltiples materiales — diseño consistente.

#### 4.2.1 Stock / fill state

| Uniform | Tipo | Range | Significado |
|---|---|---|---|
| `fill_count` | int | 0-N | Productos visibles en balda/contenedor |
| `fill_ratio` | float | 0-1 | Porcentaje normalizado de llenado |
| `is_empty` | bool | – | Helper de `fill_count == 0` |

#### 4.2.2 Emissive / glow

| Uniform | Tipo | Range | Significado |
|---|---|---|---|
| `emissive_intensity` | float | 0-1 | Multiplier de emissive map |
| `emissive_color` | vec3 | RGB 0-1 | Tint del glow |
| `pulse_rate` | float | Hz 0-10 | Pulso opcional (0 = estático) |

#### 4.2.3 Animation / motion

| Uniform | Tipo | Range | Significado |
|---|---|---|---|
| `uv_scroll_speed` | vec2 | -10 to 10 | Velocidad scroll UVs |
| `rotation_speed` | float | rad/s | Velocidad rotación |
| `belt_speed` | float | 0-1 | Velocidad cinta normalizada |

#### 4.2.4 Wear / weather state

| Uniform | Tipo | Range | Significado |
|---|---|---|---|
| `wear_level` | float | 0-1 | Desgaste (0 nuevo, 1 muy usado) |
| `humidity_level` | float | 0-1 | Humedad / condensación |
| `dirt_level` | float | 0-1 | Suciedad / polvo |
| `wet_level` | float | 0-1 | Mojado por lluvia |

#### 4.2.5 Text rendering (signage / displays)

| Uniform | Tipo | Range | Significado |
|---|---|---|---|
| `text_string` | string | UTF-8 | Texto a renderizar |
| `text_color` | vec3 | RGB 0-1 | Color texto |
| `text_size_mult` | float | 0.5-2.0 | Multiplicador tamaño |

#### 4.2.6 Visibility masks

| Uniform | Tipo | Range | Significado |
|---|---|---|---|
| `visibility_mask` | int | bitfield | Máscara de sub-meshes visibles |
| `variant_index` | int | 0-N | Índice de variante activa |

### 4.3 Política de defaults

> **Cada uniform tiene default obligatorio** que produce el estado canónico/idle del asset.

- Horno apagado: `oven_glow=0`, `door_open=false`, `pulse_rate=0`.
- Lineal lleno: `fill_count=30`.
- Pantalla sin texto: `text_string=""`.

> **Si el código no escribe el uniform, el default se aplica**. El asset siempre se ve correcto en su estado base.

---

## 5. Shaders del nodo Farm (Granja)

> **Fuente:** `01_node_farm.md` §11 (assets 3D) + Art Direction §15.

### 5.1 `mat_farm_field_wheat` — campo de trigo

**Asset:** parcelas de cultivo (estados sembrado/crecimiento/maduro/cosechado).

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner | Significado |
|---|---|---|---|---|---|
| `growth_stage` | float | 0-1 | 0 | `admirals_farm_visuals` | 0=sembrado, 0.3=brote, 0.7=crecido, 1=maduro |
| `harvest_progress` | float | 0-1 | 0 | id. | 0=sin cosechar, 1=todo cosechado (alpha mask) |
| `wind_strength` | float | 0-1 | 0.3 | `admirals_weather` | Mecimiento del trigo |
| `dryness_level` | float | 0-1 | 0 | `admirals_farm_visuals` | Sequía/falta riego (color shift amarillento) |
| `soil_moisture` | float | 0-1 | 0.5 | id. | Humedad suelo (oscurece tierra) |

**3D entrega:** mesh con vertex animation soportada + texture growth atlas (4 stages) + emissive map vacío (no glow).

**Performance budget:** 1 instance por parcela, target 8 parcelas simultáneas visibles. **Tier 2 (medio)**.

### 5.2 `mat_farm_soil_dirt` — tierra de parcela

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `tilled_state` | int | 0-3 | 0 | `admirals_farm_visuals` |
| `wet_level` | float | 0-1 | 0 | `admirals_weather` |
| `tracks_visible` | bool | – | false | `admirals_farm_visuals` |

**3D entrega:** mesh terreno + variantes texture (sin arar / arado / regado / con huellas tractor).

### 5.3 `mat_farm_tractor_metal` — chasis tractor

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `dirt_level` | float | 0-1 | 0.2 | `admirals_farm_visuals` |
| `wear_level` | float | 0-1 | 0 | id. |
| `headlight_intensity` | float | 0-1 | 0 | id. |

### 5.4 `mat_farm_silo_metal` — silo de almacenamiento

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `fill_ratio` | float | 0-1 | 0.5 | `admirals_farm_storage` |
| `wear_level` | float | 0-1 | 0.1 | id. |

> **Visual:** indicador externo al silo (ventana cristal o marca brass) refleja `fill_ratio`. **Wow funcional.**

### 5.5 `mat_farm_seed_bag` — saco de semillas

| Uniform | Tipo | Range | Default |
|---|---|---|---|
| `is_open` | bool | – | false |
| `tag_text` | string | – | "TRIGO" |

### 5.6 Otros materiales Farm (compactados)

| Material | Uniforms clave | Owner |
|---|---|---|
| `mat_farm_water_pump_brass` | `pump_active`, `flow_rate` | `admirals_farm_irrigation` |
| `mat_farm_fence_wood` | `wear_level` | – |
| `mat_farm_barn_wood` | `door_open`, `wet_level` | `admirals_farm_visuals` |
| `mat_farm_seed_storage_glass` | `fill_count` (0-N sacos visibles) | `admirals_farm_storage` |
| `mat_farm_warehouse_floor` | `dirt_level`, `wet_level` | `admirals_farm_visuals` |
| `mat_farm_irrigation_pipe` | `flow_active` | `admirals_farm_irrigation` |
| `mat_farm_tablet_dock_brass` | `is_docked`, `glow_subtle` | `sonar_tablet` |

> **Total Farm: ~12 materiales custom oleada 1.**

---

## 6. Shaders del nodo Mill (Molino)

> **Fuente:** `03_node_mill.md` §11 + Art Direction §15.

### 6.1 `mat_mill_stone_grinding` — piedra molturadora

**Asset:** muelas de piedra del molino (hero prop wow).

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `rotation_speed` | float | rad/s 0-15 | 0 | `admirals_mill_machinery` |
| `flour_dust_emission` | float | 0-1 | 0 | id. |
| `wear_level` | float | 0-1 | 0.05 | id. |
| `is_grinding` | bool | – | false | id. |

**3D entrega:** mesh muela + groove pattern + emissive bajo (subtle warmth) + UV scroll para texture motion + dust emission anchor points.

**Visual wow:** cuando `is_grinding=true`, polvo de harina sale visible (FX), `rotation_speed` controla velocidad rotación visible.

**Performance:** **Tier 1 (alto cost)** — hero prop.

### 6.2 `mat_mill_flour_sack` — saco de harina

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `fill_level` | float | 0-1 | 1 | `admirals_mill_storage` |
| `quality_tier` | int | 0-3 | 1 | id. |
| `tag_text` | string | – | "HARINA T55" | id. |
| `lineage_qr_uri` | string | – | "" | id. |

> **`quality_tier`** afecta tinte sutil del saco (T0=premium tinte cálido, T3=basic tinte neutro). El packaging **comunica calidad visualmente**.

### 6.3 Otros materiales Mill

| Material | Uniforms clave | Owner |
|---|---|---|
| `mat_mill_belt_canvas` | `belt_speed`, `belt_dirt` | `admirals_mill_machinery` |
| `mat_mill_grain_chute_metal` | `flow_active`, `flow_rate` | id. |
| `mat_mill_separator_glass` | `flour_visible_amount` | id. |
| `mat_mill_packaging_machine` | `is_packing`, `cycle_progress` | id. |
| `mat_mill_warehouse_dust` | `dust_density` | `admirals_mill_atmosphere` |
| `mat_mill_signage_brass` | `signage_text`, `signage_lit` | `admirals_mill_visuals` |

> **Total Mill: ~8 materiales custom oleada 1.**

---

## 7. Shaders del nodo Bakery (Panadería)

> **Fuente:** `04_node_bakery.md` §11.4 + Art Direction §15.

### 7.1 `mat_bakery_oven_door` — puerta del horno (HERO PROP) ⭐

**Asset:** horno profesional de panadería — el hero prop más importante del nodo.

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `oven_glow_intensity` | float | 0-1 | 0 | `admirals_bakery_oven` |
| `oven_glow_color` | vec3 | RGB 0-1 | (1.0, 0.55, 0.15) | id. |
| `door_open` | bool | – | false | id. |
| `temperature_visible` | float | C° 0-300 | 20 | id. |
| `pulse_rate` | float | Hz 0-2 | 0.5 (cuando glow>0) | id. |
| `interior_visible_breads` | int | 0-12 | 0 | id. |

**3D entrega:** mesh horno con interior modelado (rejillas + back wall) + cristal puerta + emissive map del back wall + animación puerta apertura. Warmth amber tint en glass.

**Visual wow:**
- `oven_glow_intensity=0` → horno apagado, neutro.
- `oven_glow_intensity=0.4` → calentando, glow naranja sutil pulsing.
- `oven_glow_intensity=1.0` → horneando, glow naranja intenso pulsing rítmico.
- `door_open=true` → cristal desaparece, glow sale al ambient → **bloom + heat distortion FX visible**.
- `interior_visible_breads` controla cuántos panes visibles en rejillas (props anidados).

**Performance:** **Tier 1 (heavy)** — hero prop, optimización de bloom + heat distortion necesaria.

### 7.2 `mat_bakery_dough_proofing` — masa fermentando

**Asset:** masa en cubas de fermentación.

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `fermentation_progress` | float | 0-1 | 0 | `admirals_bakery_proofing` |
| `volume_scale` | float | 0.7-1.5 | 1.0 | id. |
| `surface_dryness` | float | 0-1 | 0 | id. |
| `is_overproofed` | bool | – | false | id. |

**3D entrega:** mesh masa con blend shapes para crecimiento + texture surface skin.

**Visual wow:**
- Masa **crece visiblemente** durante 3-4 horas reales (mecánica única Bakery — fermentación tiempo real).
- `surface_dryness` añade textura agrietada si reposo muy largo.
- `is_overproofed=true` aplica visual wilted (decadente).

**Performance:** **Tier 2** — N instances, vertex blend shapes.

### 7.3 `mat_bakery_bread_baked` — pan horneado

**Asset:** modelo de pan terminado (5 variantes — blanco, integral, baguette, sourdough, croissant).

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `bake_quality` | float | 0-1 | 0.8 | `admirals_bakery_oven` |
| `crust_darkness` | float | 0-1 | 0.5 | id. |
| `freshness_hours` | float | 0-72 | 0 | `admirals_bakery_inventory` |
| `lineage_qr_uri` | string | – | "" | id. |

**3D entrega:** mesh pan con detalle crust + texture variants para crust darkness gradient.

**Visual:**
- `bake_quality` afecta crust+color (high → dorado óptimo, low → pálido o quemado).
- `freshness_hours` añade visual "dried out" gradual hasta hours=72.

### 7.4 `mat_bakery_glass_display` — vitrina de venta

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `interior_lit` | float | 0-1 | 0 | `admirals_bakery_visuals` |
| `humidity_level` | float | 0-1 | 0.1 | id. |
| `fill_count` | int | 0-30 | 15 | `admirals_bakery_inventory` |

**Visual wow:** vitrina iluminada con bocadillos visibles. Si `fill_count` baja, los slots vacíos se ven (no abstracto).

### 7.5 Otros materiales Bakery

| Material | Uniforms clave | Owner |
|---|---|---|
| `mat_bakery_mixer_metal` | `mixer_active`, `bowl_fill`, `rotation_speed` | `admirals_bakery_mixer` |
| `mat_bakery_proofing_chamber` | `humidity_visible`, `interior_lit` | `admirals_bakery_proofing` |
| `mat_bakery_flour_dust_amb` | `dust_density` | `admirals_bakery_atmosphere` |
| `mat_bakery_counter_marble` | `dirt_level`, `flour_residue` | `admirals_bakery_visuals` |
| `mat_bakery_chalkboard_menu` | `menu_text`, `menu_prices` | id. |
| `mat_bakery_cash_register_brass` | `drawer_open`, `display_total` | `admirals_bakery_pos` |
| `mat_bakery_scale_brass` | `weight`, `needle_angle` | id. |
| `mat_bakery_bread_basket_wicker` | `fill_count` | `admirals_bakery_inventory` |
| `mat_bakery_oven_back_emissive` | `intensity_amber` | `admirals_bakery_oven` |
| `mat_bakery_signage_brass` | `signage_text`, `signage_lit` | `admirals_bakery_visuals` |

> **Total Bakery: ~14 materiales custom oleada 1.**

---

## 8. Shaders del nodo Retail (Supermercado)

> **Fuente:** `05_node_retail.md` §11.4.

### 8.1 `mat_retail_shelf_white` — lineal estándar (HERO MECÁNICO) ⭐

**Asset:** lineal blanco de supermercado (50% del visual del nodo).

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `fill_count` | int | 0-30 | 30 | `admirals_retail_inventory` |
| `price_text_1` | string | – | "" | `admirals_retail_pricing` |
| `price_text_2` | string | – | "" | id. |
| `price_text_3` | string | – | "" | id. |
| `price_text_4` | string | – | "" | id. |
| `promo_active` | bool | – | false | id. |
| `promo_color` | vec3 | RGB | (1.0, 0.9, 0.0) | id. |

**3D entrega:** mesh lineal con 4 baldas + props productos individuales en sub-meshes (visibles según `fill_count`) + planos etiquetas precio (text rendering).

**Visual wow:** stock dinámico real visible — un lineal con 30 productos vs 3 productos se VE diferente. Etiquetas precio se actualizan en runtime. Si `promo_active=true`, overlay amarillo en frente del lineal.

**Performance:** **Tier 2** — alto número de instances (50-300 lineales por MLO Retail).

### 8.2 `mat_retail_pos_white` — caja registradora POS (HERO PROP) ⭐

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `belt_speed` | float | 0-1 | 0 | `admirals_retail_pos` |
| `scanner_active` | bool | – | false | id. |
| `scanner_beam_color` | vec3 | RGB | (1.0, 0.1, 0.1) | id. |
| `lcd_total_text` | string | – | "0.00 €" | id. |
| `lcd_color` | vec3 | RGB | (0.2, 1.0, 0.4) | id. |
| `drawer_open` | bool | – | false | id. |
| `printer_active` | bool | – | false | id. |

**Visual wow:** beam láser rojo del escáner visible al pasar producto, LCD total actualiza, cinta moviéndose, cajón abre con efectivo.

**Performance:** **Tier 1** — hero prop.

### 8.3 `mat_retail_fridge_glass` — nevera vertical cristal

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `fridge_lit` | float | 0-1 | 0.8 | `admirals_retail_visuals` |
| `humidity_level` | float | 0-1 | 0.4 | id. |
| `door_open` | bool | – | false | id. |
| `fill_count` | int | 0-N | 20 | `admirals_retail_inventory` |

**Visual wow:** condensación en cristal (`humidity_level`), LED interior glow (`fridge_lit`).

### 8.4 `mat_retail_signage_brass` — cartel sección suspendido

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `signage_text` | string | – | "PANADERÍA" | `admirals_retail_visuals` |
| `signage_lit` | float | 0-1 | 0.6 | id. |
| `signage_color` | vec3 | RGB | (1.0, 0.85, 0.6) | id. |

### 8.5 Otros materiales Retail

| Material | Uniforms clave | Owner |
|---|---|---|
| `mat_retail_promo_sign_brass` | `promo_text`, `discount_pct` | `admirals_retail_pricing` |
| `mat_retail_shopping_cart_metal` | `fill_count`, `dirt_level` | `admirals_retail_visuals` |
| `mat_retail_shopping_basket_plastic` | `fill_count` | id. |
| `mat_retail_scale_brass` | `weight`, `lcd_text` | `admirals_retail_pos` |
| `mat_retail_floor_polished` | `dirt_level`, `wet_level` | `admirals_retail_visuals` |
| `mat_retail_safe_metal` | `dial_angle`, `door_open` | `admirals_retail_finance` |

> **Total Retail: ~10 materiales custom oleada 1.**

---

## 9. Shaders de la Admirals Tablet (NUI / device)

> **Fuente:** `02_sonar_tablet.md` §12 (design system NUI) + `technical/01_architecture.md` §13 (NUI técnico) + Art Direction §12.

### 9.1 Filosofía específica Tablet

> **La Tablet es un híbrido único:** mesh 3D físico (el dispositivo) + render target dinámico (la pantalla NUI). Los shaders actúan en **2 capas**:
>
> - **Capa device** — material del cuerpo de la Tablet (brass + glass).
> - **Capa screen** — material que recibe el render NUI como texture target.

### 9.2 `mat_tablet_screen` — pantalla NUI (HERO PROP) ⭐

**Asset:** la superficie de la pantalla de la Admirals Tablet.

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `nui_render_target` | texture_id | – | NUI default | `sonar_tablet` |
| `screen_brightness` | float | 0-1 | 0.85 | id. |
| `screen_color_temp` | float | -1 to 1 | 0 | id. |
| `is_locked` | bool | – | true | id. |
| `notification_pulse` | float | 0-1 | 0 | id. |
| `glare_strength` | float | 0-1 | 0.3 | `admirals_environment` |

**3D entrega:** mesh pantalla con normal map sutil (reflejo realista) + glass material reactive a entorno.

**Visual wow:** pantalla muestra el NUI render real con brightness ajustable. `notification_pulse>0` añade pulse sutil edge cuando llega notif. Glare reaccionando a luz ambient.

**Performance:** **Tier 1** — render target costoso, optimización LOD según distancia jugador.

### 9.3 `mat_tablet_body_brass` — chasis brass de la Tablet

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `brass_polish` | float | 0-1 | 0.85 | – |
| `wear_level` | float | 0-1 | 0.05 | – |
| `engraving_visible` | bool | – | true | – |

**3D entrega:** mesh con engraving del logo Admirals + brass texture set premium.

### 9.4 `mat_tablet_dock_charging` — base de carga brass

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `is_charging` | bool | – | false | `sonar_tablet` |
| `charge_glow_color` | vec3 | RGB | (1.0, 0.85, 0.4) | id. |
| `pulse_rate` | float | Hz 0-2 | 0.5 | id. |

**Visual wow:** dock pulsing sutil cuando Tablet está charging — signature visual del puesto de trabajo.

### 9.5 `mat_tablet_nui_glass_overlay` — material overlay NUI (en código)

> **Material especial usado por NUI para alpha layers internos del DOM render** (no es físico — es software-side). Documentado para referencia.

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `blur_strength` | float | 0-15 | 0 | `sonar_tablet` (NUI side) |
| `tint_color` | vec4 | RGBA | (1,1,1,1) | id. |

### 9.6 Otros materiales Tablet

| Material | Uniforms clave | Owner |
|---|---|---|
| `mat_tablet_speaker_mesh` | `audio_active` | `sonar_tablet` |
| `mat_tablet_camera_lens` | `camera_active` | id. |

> **Total Tablet: ~6 materiales custom oleada 1.**

---

## 10. Shaders comunes / shared (`mat_admirals_*`)

> **Materiales compartidos entre múltiples nodos.** Especialmente brass signature + paper artifacts.

### 10.1 `mat_admirals_brass_polished` — brass signature ⭐

**Asset:** TODA superficie brass del ecosistema (Tablet, signages, hardware Admirals).

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `polish_level` | float | 0-1 | 0.85 | – |
| `tarnish_level` | float | 0-1 | 0.1 | – |
| `engraving_visible` | bool | – | false | – |
| `tint_warmth` | float | -0.2 to 0.2 | 0 | – |

**3D entrega:** PBR brass con metallic=1, roughness map cuidado + normal map para engravings.

> **Reglas de uso:** todos los nodos usan ESTE shader para brass — coherencia visual del ecosistema. No hay 5 brass distintos.

### 10.2 `mat_admirals_paper_document` — papel oficial

**Asset:** contratos, albaranes, recibos, tickets.

**Uniforms:**

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `document_text` | string | UTF-8 | "" | varies |
| `document_qr_uri` | string | – | "" | id. |
| `paper_aging` | float | 0-1 | 0 | – |
| `is_stamped` | bool | – | false | id. |
| `stamp_color` | vec3 | RGB | (0.7, 0.1, 0.1) | id. |

**Visual wow:** texto dinámico + QR code dinámico + sello rojo Admirals si firmado.

### 10.3 `mat_admirals_logo_emissive` — logo Admirals iluminado

| Uniform | Tipo | Range | Default | Owner |
|---|---|---|---|---|
| `emissive_intensity` | float | 0-1 | 0.6 | `admirals_branding` |
| `tint` | vec3 | RGB | (1.0, 0.85, 0.6) | id. |

### 10.4 Otros shared

| Material | Uniforms clave | Uso |
|---|---|---|
| `mat_admirals_npc_tag_brass` | `tag_text`, `tag_color` | Tags NPCs Admirals |
| `mat_admirals_smoke_amb` | `density`, `color_tint` | Atmósfera ambient (chimeneas, vapor) |

> **Total shared: ~5 materiales.**

---

## 11. Performance budgets

### 11.1 Tiers de cost

| Tier | Coste GPU | Uso recomendado |
|---|---|---|
| **Tier 1 — Heavy** | Heroico (>500 instructions, post-FX) | Hero props únicos: oven_door, pos_station, tablet_screen, mill_stone_grinding |
| **Tier 2 — Medio** | Normal (200-500 instructions) | Mobiliario común visible, props animados |
| **Tier 3 — Light** | Bajo (<200 instructions) | Background, decoración, props no-interactivos |
| **Tier 4 — Micro** | Mínimo | Tags, etiquetas, papers |

### 11.2 Budget total por escena MLO

> **Target conservador para servidores low-end (16GB RAM, GTX 1060):** mantener 60fps estable.

| MLO | Tier 1 | Tier 2 | Tier 3 | Total instances visibles |
|---|---|---|---|---|
| Granja | 2 (silo, tractor) | 12 (parcelas, props) | 30 (decoración) | ~45 |
| Molino | 2 (stones, packaging) | 8 | 20 | ~30 |
| Bakery | 3 (oven, mixer, vitrina) | 15 | 25 | ~45 |
| Retail standard | 2 (POS, lineales) | 80+ (lineales múltiples) | 40 | ~120 |

> **Retail es el más demandante** — optimización crítica via instancing de lineales (todos comparten material → 1 draw call).

### 11.3 Optimization rules

- ✅ **Instancing obligatorio** para mismo material (`mat_retail_shelf_white` x 50 lineales → 1 draw call).
- ✅ **LOD aggressive** para props lejanos (>20m → bajar a Tier 3 ó 4).
- ✅ **Texture atlasing** cuando posible (productos pequeños comparten atlas).
- ✅ **Cull aggressively** props ocultos (backroom invisible desde frente público).
- ✅ **Defer post-FX** a hero props únicos (no aplicar bloom global a todo).
- ❌ **NO** usar Tier 1 en >5 instances simultáneos.
- ❌ **NO** abusar render targets (Tablet ya consume 1 — máximo 3 totales en escena).

### 11.4 Profiling protocol

> **Antes de firmar release de un nodo:**

1. Profile con FiveM dev tools en MLO con población típica de prod.
2. Verificar fps ≥60 con player + 4 NPCs visibles.
3. Verificar fps ≥45 en hora pico (8+ PEDs en Retail).
4. Verificar memoria GPU ≤ 4GB allocated por el resource.
5. Documentar baseline en `technical/01_architecture.md` §15 (performance section).

---

## 12. Naming, ownership y versioning matrix

### 12.1 Master ownership matrix

> **Cada uniform tiene UN ÚNICO owner resource** que tiene autoridad para escribirlo. Otros resources solo leen estado vía bus de eventos.

| Resource | Materiales que escribe | Eventos bus que consume |
|---|---|---|
| `admirals_farm_visuals` | `mat_farm_field_*`, `mat_farm_soil_*`, `mat_farm_tractor_*`, `mat_farm_barn_*`, `mat_farm_warehouse_*` | `farm:crop_state`, `farm:weather_change` |
| `admirals_farm_storage` | `mat_farm_silo_*`, `mat_farm_seed_storage_*` | `farm:storage_change` |
| `admirals_farm_irrigation` | `mat_farm_water_pump_*`, `mat_farm_irrigation_pipe` | `farm:irrigation_*` |
| `admirals_mill_machinery` | `mat_mill_stone_*`, `mat_mill_belt_*`, `mat_mill_chute_*`, `mat_mill_separator_*`, `mat_mill_packaging_*` | `mill:machinery_*` |
| `admirals_mill_storage` | `mat_mill_flour_sack` | `mill:packaging_complete` |
| `admirals_mill_atmosphere` | `mat_mill_warehouse_dust` | `mill:tick_atmosphere` |
| `admirals_bakery_oven` | `mat_bakery_oven_*` | `bakery:oven_*`, `bakery:bake_complete` |
| `admirals_bakery_proofing` | `mat_bakery_dough_*`, `mat_bakery_proofing_chamber` | `bakery:proofing_*` (real-time tick) |
| `admirals_bakery_mixer` | `mat_bakery_mixer_*` | `bakery:mixer_*` |
| `admirals_bakery_inventory` | `mat_bakery_glass_display`, `mat_bakery_bread_basket_*`, `mat_bakery_bread_baked` | `bakery:inventory_change`, `bakery:bake_complete` |
| `admirals_bakery_pos` | `mat_bakery_cash_register_*`, `mat_bakery_scale_*` | `bakery:sale_*` |
| `admirals_bakery_atmosphere` | `mat_bakery_flour_dust_amb` | `bakery:tick_atmosphere` |
| `admirals_bakery_visuals` | `mat_bakery_counter_*`, `mat_bakery_chalkboard_*`, `mat_bakery_signage_*` | varios |
| `admirals_retail_inventory` | `mat_retail_shelf_*`, `mat_retail_fridge_*` (fill_count), `mat_retail_shopping_cart_*` | `retail:inventory_change`, `retail:cart_change` |
| `admirals_retail_pricing` | `mat_retail_shelf_*` (price_text), `mat_retail_promo_sign_*` | `retail:pricing_change`, `retail:promo_*` |
| `admirals_retail_pos` | `mat_retail_pos_*`, `mat_retail_scale_*` | `retail:sale_*`, `retail:scan_*` |
| `admirals_retail_finance` | `mat_retail_safe_*` | `retail:cashbox_*` |
| `admirals_retail_visuals` | `mat_retail_signage_*`, `mat_retail_floor_*` | varios |
| `sonar_tablet` | `mat_tablet_*` | `tablet:*` |
| `admirals_branding` | `mat_admirals_logo_emissive` | `core:server_state` |
| `admirals_environment` | uniforms ambientales cross-cutting (`glare_strength`, `wet_level` global) | `weather:*`, `time:*` |
| `admirals_weather` | `wind_strength`, `wet_level` en materiales outdoor | `weather:*` |

### 12.2 Reglas de versioning

- **Schema additions** (uniform nuevo añadido) → minor bump (1.0 → 1.1) — non-breaking.
- **Schema changes** (rename/remove uniform) → major bump (1.0 → 2.0) — **breaking**, coordinar release con code team.
- **Texture set rev** (assets repintados) → patch bump (1.0 → 1.0.1) — non-breaking si tamaño/formato igual.

### 12.3 Audit trail

Cada material tiene comentario header en su `.fxc`:

```glsl
// mat_bakery_oven_door
// Schema version: 1.0
// Owner resource: admirals_bakery_oven
// Last updated: 2026-05-01
// Doc: docs/art/02_shader_contracts.md §7.1
```

---

## 13. Validation y testing protocol

### 13.1 Validation automática (CI)

> **Pre-merge checks ejecutados en CI:**

1. **Linter de uniforms:** parsea cada `.fxc` y compara uniforms declarados con este doc. Falla si discrepancia.
2. **Owner integrity check:** cada uniform tiene exactamente 1 owner declarado.
3. **Range validation:** valores defaults dentro de rangos declarados.
4. **Naming convention:** materiales que no siguen `mat_<dominio>_*` patrón → fail.
5. **Schema version:** archivo material vs doc → consistente.

### 13.2 Validation manual (pre-firmar release)

> **Antes de cada major release:**

1. Cada nodo tiene **escena de QA** con todos sus materiales presentes.
2. **Ciclar uniforms** del 0% al 100% de cada material visiblemente — verificar wow real.
3. **Profile de fps** según §11.4.
4. **Visual regression test** — screenshots comparados frame a frame con baseline.
5. **Audit ownership** — cada uniform escrito por su owner resource correcto (logging en dev mode).

### 13.3 Test escenas requeridas

| Escena | Propósito |
|---|---|
| `qa_farm_full_day_cycle` | Crop growth + weather + day/night |
| `qa_mill_grinding_session` | Mill stones + flour dust + sack fill |
| `qa_bakery_bake_cycle` | Oven glow cycle + dough proofing + vitrina fill |
| `qa_retail_busy_hour` | Lineales fill changes + POS scanner active + 6 PEDs |
| `qa_tablet_all_apps` | NUI render target + brightness + glare + notif pulse |

### 13.4 Tooling de debug

> **Comando dev** para inspeccionar uniforms en runtime:

```
/admirals_shader_inspect <prop_id>
```

Output:
```
mat_bakery_oven_door @ entity 0xABC
  schema: 1.0
  owner: admirals_bakery_oven
  uniforms:
    oven_glow_intensity: 0.85   [last updated 1.2s ago]
    door_open: false
    interior_visible_breads: 6
  performance: tier 1, 0.4ms gpu time
```

---

## 14. Roadmap del documento + estado

### 14.1 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ ~55 materiales custom catalogados.
- ✅ Naming convention establecida.
- ✅ Ownership matrix completa.
- ✅ Performance tiers definidos.
- ✅ Validation protocol establecido.

#### Oleada 2 (T+6 meses)
- 🔜 +20 materiales para Hipermercado + Lácteos vertical + Hortícola vertical.
- 🔜 Compute shaders para weather global cross-nodo.
- 🔜 Dynamic global illumination opcional para servidores high-end.

#### Oleada 3+ (T+12 meses)
- 🔜 Materiales SDK para third-party developers.
- 🔜 Shader marketplace Admirals (developers contribuyen materiales certificados).

### 14.2 Estado del documento

- **Versión:** 1.0 (firmado — completo, 14 secciones, 2 partes publicadas).
- **Próxima revisión:** evolución cuando se añadan materiales de oleada 2 (Hipermercado + Lácteos + Hortícola).
- **Documentos hijos pendientes:** ninguno — este doc es terminal-leaf del subsistema shader.
- **Documentos relacionados:**
  - `art/01_art_direction.md` v1.0 — paleta + tipografía + estética global.
  - `art/03_sound_bible.md` (próximo) — paralelo sonoro de este doc.
  - `art/04_storybook_guide.md` (próximo) — design system NUI Tablet.

### 14.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 (parte 1) | 2026-05-01 | Founder + Cascade | §0-§8 (filosofía, división 3D vs Code, catálogos, Farm/Mill/Bakery/Retail shaders). |
| 1.0 (parte 2) | 2026-05-01 | Founder + Cascade | §9-§14 (Tablet, shared, performance, ownership matrix, validation, roadmap). **Documento completo, firmable.** |

---

## Resumen ejecutivo del documento (cierre)

El **Shader Contracts** consolida la promesa Bible §13.4 en interfaz formal:

- **~55 materiales custom oleada 1** distribuidos en 6 dominios (farm/mill/bakery/retail/tablet/admirals shared).
- **Patterns recurrentes** de uniforms (fill_count, emissive_intensity, wear_level, signage_text) → consistencia cross-node.
- **Ownership matrix explícito** — cada uniform tiene UN owner resource. No hay race conditions.
- **Performance budget conservador** — target 60fps en GTX 1060.
- **Validation protocol** — CI checks + escenas QA + tooling debug runtime.
- **Versioning policy** — additions non-breaking, removes/renames breaking con coordinación.

> **El día que el equipo 3D entregue el horno Bakery con `oven_glow_intensity` documentado y el equipo de código escriba `oven_glow_intensity=0.85` durante el bake — y ambos vean exactamente lo que esperan visualmente en pantalla — habrá funcionado el contrato.**

---

*"3D entrega el wow. Code lo respira."*

**FIN DEL DOCUMENTO `art/02_shader_contracts.md` v1.0**
