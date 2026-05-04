# 🥖 Admirals — Nodo 3: La Panadería Admirals

> **Versión:** 1.0 (firmado — completo, 15 secciones, 3 partes publicadas).
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2
> **Documentos hermanos:** `01_node_farm.md` v1.1 · `02_sonar_tablet.md` v1.0 · `03_node_mill.md` v1.0 · `art/01_art_direction.md` v1.0.
> **Estado:** firmado.

> **Lectura previa obligatoria:** Bible §3 (5 Pilares), §13.4 (3D vs Código), Molino §0-§4 (qué llega), Tablet §7 (Manager Panel modular), Art Direction §15-§17.

---

## 0. Resumen ejecutivo

La **Panadería Admirals** es el **tercer nodo de la Cadena del Pan** y el **primer nodo del ecosistema con cliente final directo (B2C walk-in)**. Es donde **la cadena se hace pan** — el momento en que el trigo del granjero, la harina del molinero y la levadura del proveedor se convierten en **producto comestible que se vende caliente al amanecer**.

Recibe **harinas con calidad propagada** del Molino + ingredientes secundarios (sal, levadura, azúcar, mantequilla, huevos), las transforma mediante un proceso de **8 etapas físicas con un mecanismo nuevo único — fermentación basada en tiempo real no acelerable** —, y produce **5 categorías de pan + bollería** que se venden por dos canales en paralelo:

- **B2B (mayorista):** palets a Retail, restaurantes, supermercados, hostelería.
- **B2C (escaparate):** venta directa al jugador walk-in que entra a comprar 1 baguette caliente.

Es a la vez:

- **Una panadería artesanal urbana** con MLO propio: obrador + escaparate + zona servicio.
- **Un proceso productivo físico-temporal** con 8 etapas, donde **el reloj decide la calidad** tanto como la habilidad.
- **Un puesto profesional** (el Panadero) con su rol RP de oficio nocturno — empieza a las 3-4am, termina a mediodía.
- **Un nodo del ecosistema** — recibe del Molinero, vende a Retail Y a customers walk-in, pasa por Logística para mayoristas, factura por Banca, firma contratos en la Tablet.

> **La Panadería es donde la Cadena del Pan se vuelve emocional.** En Granja, el jugador siembra. En Molino, ve transformación. En Panadería, **ve el resultado oler bien y ser comprado por otro humano**. Es el nodo que cierra la promesa narrativa del Bible §1: "del campo a la mesa".

---

## 1. Filosofía y posicionamiento

### 1.1 Artesanal premium con calor humano — la decisión estética

La Panadería Admirals es **artesanal premium con calor humano**. NO industrial, NO factoría. La inspiración no es Bimbo — es **una panadería de barrio bien con obrador histórico** estilo Madrid centro / París intramuros / Lisboa Chiado.

- **Artesanal** — masa amasada, formada a mano, horneada en horno de leña/eléctrico semi-rotativo. Sin esto, no hay alma.
- **Premium** — la marca Admirals premia el oficio elevado a profesión digna. El panadero NO es un personaje cómico — es **un oficial del oficio**, con uniforme blanco impoluto, sello en cada hogaza, firma en libreta.
- **Calor humano** — la panadería es el único nodo donde el jugador siente **temperatura del horno + aroma humeante + clientes walk-in que sonríen al recibir su baguette**.

**Inspiración visual:**
- Panaderías premium europeas: Poilâne (París), Panem (Madrid), Tartine (SF tono).
- Tonos: **harina blanca + cobre cálido del horno + madera clara del mostrador + brass Admirals en detalles**.
- Iluminación: **calor cálido del horno + luz del amanecer entrando por escaparate + lámparas brass colgantes**. Wow atmosférico de código: vapor visible saliendo de hornos al abrir + heat shimmer.

### 1.2 ¿Por qué un nodo dedicado?

> **¿No podría el Molino "incluir" la panadería como un cuarto adicional?**

No. Por 5 razones:

1. **Pilar 1 — Físico.** Amasado, fermentación, horneado son disciplinas distintas. Un horno NO es un molino.
2. **Pilar 2 — Cadena.** Sin Panadero independiente, no hay relación B2B Molino → Panadería.
3. **Pilar 3 — Detalle.** La Panadería es **el nodo más sensorial del ecosistema oleada 1** (aroma, calor, sonido del horno, escaparate).
4. **Comercial.** Permite vender la Panadería como producto independiente con NPC bridges en upstream.
5. **B2C consumer-facing.** Es **el primer nodo con interface al consumidor jugador walk-in** — desbloquea pattern (escaparate + caja + cliente entra) que reusaremos en Retail y futuras verticales.

### 1.3 El oficio nocturno — la firma temporal del nodo

> **Diseño deliberado:** la Panadería es el ÚNICO nodo del ecosistema oleada 1 con horario canónico atípico.

- **Hora de inicio canónica:** 3:00 - 4:00 AM in-game.
- **Hora pico de venta:** 6:00 - 11:00 AM.
- **Hora de cierre:** 14:00 - 15:00.
- **Tarde:** prep masa madre, refresco, limpieza — opcional, gameplay tranquilo.

> **Esto NO es un castigo — es identidad.** Un jugador que elige Panadero está eligiendo un oficio de madrugada. RP rico, comunidad cerrada, romanticismo. Servidores con time-cycle acelerado se ajustan automáticamente.

> **Trade-off explícito:** un panadero que abre tarde tiene **menos pan listo** para la hora pico → menos ingresos. El gameplay premia el oficio a la hora correcta sin forzar.

### 1.4 Anti-patrones específicos de la Panadería

- ❌ Menú "convertir 50kg harina en 100 panes" en 5 segundos. **El pan tarda lo que tarda. Fermentación NO se acelera.**
- ❌ Hornos estáticos sin glow ni vapor. **Brillo del fuego visible + vapor al abrir + sonido crepitante.**
- ❌ Pan idéntico genérico. **5 categorías mínimas**, cada una con modelo 3D y comportamiento distinto.
- ❌ Calidad arbitraria. El pan hereda **calidad harina (40%) + skill panadero (30%) + tiempo fermentación correcto (30%)**.
- ❌ Pan que dura 7 días en stock. Vida útil real: pan blanco 24h prime, baguette 12h prime, hogaza sourdough 72h prime. **Sin frescura, no hay urgencia.**
- ❌ Cliente walk-in que no aparece. **Sistema PED customers** activos genera demanda B2C real.
- ❌ Aroma invisible. Al estar dentro, **HUD o sound layer** comunica "huele a pan recién hecho".
- ❌ Pan sin sello de origen. Cada hogaza/baguette empaquetada lleva sello empresa + batch + fecha + lineage trace.
- ❌ Producción ilimitada simultánea. El obrador tiene **capacidad física** — gameplay táctico real.

### 1.5 La promesa wooow específica de la Panadería

> Un jugador recién instalado entrando a una Panadería Admirals debe pensar en los primeros **30 segundos**: *"esto huele a pan de verdad"*.

**Los 3 wow primarios:**

1. **El escaparate al amanecer.** Vidrio gigante, panes en cestas de mimbre apiladas, luz del horno cálida bañando todo, brass Admirals en detalles.
2. **El horno abierto.** Cuando el panadero abre el horno: **glow + vapor + crujido del pan caliente + sonido del oficio**. Cinemática micro celebrada.
3. **El cliente walk-in feliz.** PED entra, va al mostrador, recibe pan caliente, sonríe (anim), sale. Comunica "esto es un negocio real, no un script vacío".

---

## 2. Topología del nodo — el MLO de la Panadería

### 2.1 Visión general del edificio

> **MLO único, identificable, ubicado en zona urbana viva.** Ubicación canónica recomendada: **Vinewood Boulevard / Mirror Park / Vespucci Beach** (calles transitadas con flujo PED). Configurable por servidor.

**Tamaño:** mediano (más pequeño que Molino — urbano). **20m × 15m de planta + zona exterior pequeña (carga camiones lateral)**.

**Concepto:** **doble fachada** — frente público con escaparate + lateral/trasera de servicio para mayoristas. El público entra por delante, los camiones por detrás.

### 2.2 Zonas funcionales

| # | Zona | Función | Visible desde fuera |
|---|---|---|---|
| Z1 | **Escaparate / Shop front** | Venta B2C walk-in con vitrina expositora | Sí — fachada principal |
| Z2 | **Mostrador de venta** | Caja, báscula, terminal Tablet, atendedor | Parcial desde escaparate |
| Z3 | **Pasillo de servicio** | Conecta shop con obrador | No |
| Z4 | **Obrador (sala principal)** | Mesa amasado + zona formado + amasadora | No |
| Z5 | **Zona de hornos** | 2 hornos rotativos + 1 tradicional (variant premium) | No |
| Z6 | **Cámara de fermentación** | Estantes con bandejas + control humedad/temperatura | No |
| Z7 | **Almacén harinas** | Sacos paletizados frescos + control humedad | No |
| Z8 | **Cámara fría bollería** | Para masas con frío + producto bollería en espera | No |
| Z9 | **Zona empaquetado** | Mesa + selladora + estanterías de palets salida | No |
| Z10 | **Despacho del panadero** | Oficina con dock Tablet + pizarra de pedidos | No |
| Z11 | **Vestuario empleados** | Cambio uniforme blanco + taquillas | No |
| Z12 | **Carga lateral / trasera** | Camiones recogen palets B2B | Sí — lateral |
| Z13 | **Acceso peatonal** | Entrada cliente walk-in con terraza opcional | Sí — frente |

### 2.3 Plano conceptual

```
                  CALLE PEATONAL (Z13)
        ┌───────────────────────────────────┐
        │     [ESCAPARATE Z1 — vitrina]     │   ← visible público, PEDs walk-in
        │  ┌─────────────────────────────┐  │
cliente→│  │ [Z2 mostrador]   [terminal] │  │
        │  │  Z3 pasillo                 │  │
        │  │  ┌──────────┐ ┌──────────┐  │  │
        │  │  │ Z4 obrad.│ │ Z6 ferm. │  │  │
        │  │  └──────────┘ └──────────┘  │  │
        │  │  ┌──────────┐ ┌──────────┐  │  │
        │  │  │ Z5 horno │ │ Z9 emp.  │  │  │
        │  │  └──────────┘ └──────────┘  │  │
        │  │  ┌──────────┐ ┌──────────┐  │  │
        │  │  │ Z7 alm.  │ │ Z8 frío  │  │  │
        │  │  └──────────┘ └──────────┘  │  │
        │  │  [Z10 desp.]   [Z11 vest.] │  │
        │  └─────────────────────────────┘  │
        │           [Z12 carga lateral]    │
        └───────────────────────────────────┘
              CALLE SERVICIO (camiones B2B)
```

### 2.4 Capacidad física

| Zona | Capacidad |
|---|---|
| Z1 escaparate vitrina | 4-6 cestas mimbre + 2 estantes superiores + 1 vitrina baja bollería |
| Z2 mostrador | 1 caja + báscula brass + 1 atendedor (player o NPC empleado) |
| Z4 obrador | 1 mesa amasado 2.5m × 1.2m + 1 amasadora + 2 mesas formado |
| Z5 hornos | 2 rotativos eléctricos (16 bandejas c/u) + 1 tradicional opcional |
| Z6 fermentación | 24 bandejas en estantes + control T° (FX subtle steam) |
| Z7 almacén harinas | 12 palets (~600 sacos 25kg) |
| Z8 cámara fría | 6 estantes refrigerados + 80 bandejas bollería |
| Z9 empaquetado | 1 mesa 2m + selladora + 4 palets simultáneos |
| Z12 carga lateral | 1 muelle camión + transpaleta |

### 2.5 Variantes de la panadería (3 tiers)

| Variante | Footprint | Hornos | Capacidad B2B | Target |
|---|---|---|---|---|
| **Pequeña / barrio** | 12×10m | 1 rotativo | 200 panes/día | RP indie, panadería barrio |
| **Estándar (canónica)** | 20×15m | 2 rotativos | 800 panes/día | Servidores medios — default |
| **Premium / heritage** | 30×20m | 2 rotativos + 1 tradicional leña | 1500 panes/día | Servidores grandes, hostelería pesada, RP histórico |

> **Implementación oleada 1:** la **Estándar** + toggle config "small_mode". Premium llega oleada 2.

---

## 3. Materias primas y productos

### 3.1 Inputs (qué llega del Molino + proveedores)

| Item | Unidad | Origen | Calidad heredada |
|---|---|---|---|
| `flour_white_w001` | Saco 25kg | Molino — trigo blando | Sí |
| `flour_whole_w002` | Saco 25kg | Molino — trigo integral | Sí |
| `flour_strong_w003` | Saco 25kg | Molino — trigo fuerza | Sí |
| `flour_rye_r001` | Saco 25kg | Molino — centeno | Sí |
| `flour_spelt_s001` | Saco 25kg | Molino — espelta (premium) | Sí |
| `salt_fine_001` | Saco 5kg | NPC supplier oleada 1 | Baseline B |
| `yeast_fresh_001` | Bloque 500g | NPC supplier (refrigerado) | Baseline B |
| `yeast_dry_001` | Sobre 100g | NPC supplier | Baseline B |
| `sugar_white_001` | Saco 5kg | NPC supplier (futura vertical caña) | Baseline B |
| `butter_block_001` | Bloque 1kg refrig. | NPC supplier (futura Lácteos) | Baseline B |
| `egg_dozen_001` | Caja 12u refrig. | NPC supplier (futura Avícola) | Baseline B |
| `water_potable` | Implícito grifo | Infraestructura | N/A |

> **Oleada 1:** sal, levadura, azúcar, mantequilla, huevos vienen de **NPC Bridge proveedor** (Tablet — comprar caja sin gameplay físico de origen). Oleadas futuras desbloquean estos como verticales jugables.

### 3.2 Recetas base — catálogo oleada 1

> **5 categorías de pan + bollería.** Cada receta: inputs + tiempos + output + calidad + precio.

#### 3.2.1 Pan blanco común — `bread_white_basic`

- **Inputs (batch 16 panes 500g):** 4kg flour_white + 80g salt + 60g yeast_fresh + 2.4L water.
- **Tiempos:** amasado 10min · ferm 1ª 90min · formado 15min · ferm 2ª 60min · horneado 22min · enfriado 30min.
- **Output:** 16 × `bread_white_basic` (500g).
- **Vida útil:** 24h prime, 48h descontado, 72h merma.
- **Precio ref:** 1.20€ B2C / 0.65€ B2B.

#### 3.2.2 Pan integral — `bread_whole_country`

- **Inputs (batch 12 hogazas 750g):** 4kg flour_whole + 1kg flour_white + 100g salt + 80g yeast_fresh + 3.2L water + opcional 200g semillas.
- **Tiempos:** amasado 12min · ferm 1ª 120min · formado 20min · ferm 2ª 80min · horneado 35min · enfriado 45min.
- **Output:** 12 × `bread_whole_country`.
- **Vida útil:** 36h prime, 72h descontado, 96h merma.
- **Precio ref:** 2.50€ B2C / 1.40€ B2B.

#### 3.2.3 Baguette — `bread_baguette_classic` ⭐

- **Inputs (batch 24 baguettes 250g):** 5kg flour_white + 100g salt + 80g yeast_fresh + 3.2L water.
- **Tiempos:** amasado 8min · ferm 1ª 60min · **formado 25min** (skill premium — formar baguette es arte) · ferm 2ª 45min · horneado 18min · enfriado 20min.
- **Output:** 24 × `bread_baguette_classic` (250g, 60cm largo).
- **Vida útil:** **12h prime, 24h descontado, 36h merma.** ¡Producto más perecedero!
- **Precio ref:** 1.50€ B2C / 0.85€ B2B.
- **Nota:** **producto wow del nodo** — emoji visual.

#### 3.2.4 Hogaza rústica sourdough — `bread_sourdough_rustic`

- **Inputs (batch 8 hogazas 1kg):** 5kg flour_strong + 1kg flour_rye + 120g salt + **masa madre 800g** (cultivo del panadero, ver §4.10) + 4L water.
- **Tiempos:** amasado 15min · ferm 1ª **240min (4h!)** · formado 25min · ferm 2ª 90min · horneado 50min · enfriado 60min.
- **Output:** 8 × `bread_sourdough_rustic` (1kg, premium product).
- **Vida útil:** **72h prime, 96h descontado, 120h merma** (masa madre conserva).
- **Precio ref:** 6.00€ B2C / 3.50€ B2B (alto margen).
- **Nota:** producto emblemático artesanal. **Solo desbloqueado si cultivo de masa madre activo.**

#### 3.2.5 Croissant — `pastry_croissant_butter`

- **Inputs (batch 24 croissants 80g):** 2kg flour_strong + 30g salt + 50g yeast_fresh + 1.2L water + 200g sugar + 1kg butter (laminado!) + 4 huevos.
- **Tiempos:** amasado 8min · refrig 1ª 60min · **laminado 3 vueltas con 30min refrig entre cada** = 90min total · formado 20min · ferm 2ª 90min · horneado 18min · enfriado 15min.
- **Output:** 24 × `pastry_croissant_butter` (80g).
- **Vida útil:** 12h prime, 24h descontado, 36h merma.
- **Precio ref:** 2.20€ B2C / 1.20€ B2B.
- **Nota:** **proceso más complejo** del catálogo oleada 1 — skill alto + cámara fría operativa.

### 3.3 Calidad y propagación

> Cada hogaza/baguette/croissant lleva `quality_score` heredado.

**Fórmula canónica:**

```
pan.quality = (0.40 × flour.quality) 
            + (0.30 × baker_skill_factor)
            + (0.30 × timing_score)
            - penalties
```

**Componentes:**

- **`flour.quality`** — calidad harina input (heredada del Molino, que la heredó del Granjero).
- **`baker_skill_factor`** — habilidad del jugador panadero (XP del personaje, max 1.0).
- **`timing_score`** — 1.0 si todos los tiempos de fermentación se respetaron en ventana óptima.
- **`penalties`** — eventos negativos:
  - Horneado con horno mal precalentado: -0.10.
  - Cámara fermentación T° fuera de rango: -0.05 a -0.15.
  - Pan dejado quemar: -0.30 o pérdida total.
  - Producto fuera de prime aplica devaluación de precio (no de quality_score).

**Mapeo a grade visible:**

- ≥ 0.90 → **A+** (etiqueta "Pan del Capitán" — máximo precio).
- 0.80-0.89 → **A**.
- 0.65-0.79 → **B**.
- 0.50-0.64 → **C**.
- < 0.50 → **D** (vendible solo a comedores baratos / hostelería low-cost).

### 3.4 Lineage trace — qué cuenta cada hogaza

> Cada producto final empaquetado lleva código batch + lineage completo visible en la Tablet del cliente.

Ejemplo `lineage_trace` para una baguette:

```
lineage:
  product:    bread_baguette_classic
  batch_id:   BAK-2026-04-30-A-0042
  quality:    A (0.84)
  produced:   2026-04-30 06:14
  expires:    2026-05-01 06:14 (prime), 2026-05-02 06:14 (final)
  baker:      Carlos Méndez (skill_lvl 38)
  business:   Panadería La Almirantazgo
  inputs:
    - flour_white_w001 batch MIL-2026-04-29-B-0017 (Molino San Juan, qual A)
      └─ wheat batch FRM-2026-04-15-C-0008 (Granja del Río, parcela P03, qual A+)
    - salt_fine_001 NPC batch SAL-NPC-001
    - yeast_fresh_001 NPC batch YST-NPC-014
```

> **Visible al cliente B2C** al escanear el sello en la Tablet. **Visible al cliente B2B** completo en cada palet recibido. **Es el wow de la trazabilidad real.**

---

## 4. Proceso físico — el ciclo del Panadero

### 4.1 Las 8 etapas del ciclo

> Cada etapa es físicamente jugable. No menús de "click para producir". Cada una requiere acción + tiempo + decisión.

```
[1. Recepción harinas] → [2. Pesado/dosificación] → [3. Amasado]
                                                          ↓
                                                  [4. Fermentación 1ª]
                                                          ↓
[8. Empaquetado/exposición] ← [7. Enfriado] ← [6. Horneado] ← [5. División + formado + Ferm 2ª]
```

### 4.2 Etapa 1 — Recepción de harinas

**Trigger:** camión Molino llega al muelle Z12 con palets.

**Acción:**
1. Confirmar pedido en Tablet (validar cantidades + calidad esperada vs lineage).
2. Descargar palets con transpaleta (animación física, mover a Z7).
3. Firmar albarán Tablet — sello digital.
4. Pago automático al Molino vía Banca (definido en contrato B2B previo).

**Duración:** ~3-5 min reales por palet.

**Edge cases:**
- Calidad recibida ≠ esperada → opción rechazar / aceptar con descuento.
- Saco roto → rechazar el saco específico (no todo el palet).

### 4.3 Etapa 2 — Pesado y dosificación

**Trigger:** panadero arranca batch (selecciona receta en Tablet o pizarra Z10).

**Acción:**
1. Tablet muestra recipe card con cantidades exactas.
2. Va a almacén Z7, pesa harina en báscula brass del mostrador.
3. Va a cámara fría Z8 para sacar levadura, mantequilla.
4. Saca sal, azúcar de armarios.
5. Lleva ingredientes al obrador Z4.

**Duración:** ~2-3 min por batch.

**Detalle wooow:** la báscula brass tiene aguja real (animación) — el panadero ajusta hasta marcar el peso. Sound `bakery_scale_tick` cuando aguja pasa marcas.

### 4.4 Etapa 3 — Amasado

**Trigger:** ingredientes en mesa del obrador Z4.

**Tres opciones:**

1. **A mano** — animación física 8-15min, **+0.05 al baker_skill_factor** (premium artesanal). Solo viable batches pequeños.
2. **Amasadora industrial** — máquina Z4. Más rápido (5-10min), pero **-0.05 al skill_factor**.
3. **Amasadora + acabado a mano** (híbrido recomendado) — máquina 5min + 3min mesa = bonus equilibrado.

**Duración:** 8-15 min (recipe-dependent).

**Wooow:**
- **Mano:** masa que se pega/despega de la mesa con `bakery_dough_slap`.
- **Máquina:** gancho metálico girando, masa visible girando (FX shader animado).

### 4.5 Etapa 4 — Fermentación 1ª — la mecánica nueva ⭐

> **La mecánica ÚNICA de la Panadería: tiempo real no acelerable.**

**Trigger:** masa amasada en cuenco/bandeja → entra a Cámara Z6.

**Mecánica:**
- Tiempo de fermentación de la receta (ej. 90min para pan blanco).
- **NO se acelera con ningún power-up.** Ni dinero. Ni skill. Es tiempo real in-game.
- El panadero hace **otras tareas simultáneas** (atender mostrador, otro batch, empaquetar). Promueve gameplay multi-tarea.

**Ventana óptima:**

```
[time elapsed]
0%       80%      100%      120%      150%+
|--------|--------|---------|---------|----->
sub-     premium  óptimo    pasado    quemado
fermentado          (★)     levemente  masa muerta
```

- **0-80%** = sub-fermentado: pan denso, sin volumen. `timing_score = 0.5`.
- **80-100%** = ★ premium óptimo. `timing_score = 1.0`.
- **100-120%** = pasado leve, algo agrio. `timing_score = 0.85`.
- **120-150%** = pasado, aroma fuerte ácido. `timing_score = 0.55`.
- **>150%** = masa muerta (full waste). `timing_score = 0`.

**Visualización:**
- Tablet app `Panadero` muestra timer activo por batch + barra brass + ventana óptima.
- Notificación push cuando entra ventana óptima.
- Notificación crítica si entras zona pasada.
- En zona Z6, las bandejas **visualmente crecen** (shader uniform `dough_growth` 0-1, art §15.2).

**Trade-off real:** un panadero impaciente que saca al 60% pierde calidad. Uno que se distrae 30min de más, tira el batch. **El reloj decide.**

### 4.6 Etapa 5 — División, formado, fermentación 2ª

**División:**
1. Pesar masa en porciones (báscula + cortador).
2. Anim cortar masa con espátula.

**Formado a mano según tipo:**
- **Pan blanco / hogaza:** bola simple — anim 5s/unidad.
- **Baguette:** estirado largo — anim 12s/unidad (skill-intensive).
- **Croissant:** triángulo enrollado tras laminado — anim 8s.
- **Skill bonus:** baker_skill alto reduce tiempo formado x0.7.

**Fermentación 2ª:**
- Mismo concepto que la 1ª pero más corta (45-90min según receta).
- Mismas ventanas óptimas con visual.
- En bandejas del horno directamente.

### 4.7 Etapa 6 — Horneado

**Pre-condición crítica:** **horno DEBE estar precalentado a temperatura objetivo.**

**Mecánica precalentado:**
- Horno apagado → frío (T = 25°C).
- Encender → calienta gradualmente (3-5 min para llegar a 220°C).
- **Si olvidas precalentar** → pan no sube, calidad −0.30.
- Tablet muestra T° horno en tiempo real.

**Mecánica horneado:**
- Insertar bandeja → puerta brass abre, panadero empuja, anim cierra.
- **Glow + vapor wow** al abrir (FX §13.2 art).
- Timer de horneado (recipe-dependent, 18-50min).
- Tablet notifica cuando faltan 2min.
- **Si no sacas a tiempo:** pan se quema (modelo 3D oscurece, `quality = 0`).

**Capacidad:** 16 bandejas/horno × 2 hornos = 32 bandejas paralelo. **Pico de producción real es la capacidad de horneado** — planificación es estratégica.

### 4.8 Etapa 7 — Enfriado

**Trigger:** bandeja sale del horno con pan caliente.

**Acción:**
1. Sacar bandeja con guantes — **vapor visible** (FX `bakery_fx_steam_bread`).
2. Colocar en estanterías de enfriado (Z9 o Z4).
3. Tiempo: 15-60 min según producto.

**Mecánica:**
- Pan **NO se puede empaquetar caliente** (humedece, calidad baja).
- Si intentas empaquetar antes → warning Tablet + penalty −0.05.
- Pan en enfriado **YA está disponible para venta walk-in** del escaparate Z1 (clientes adoran pan caliente — premium UX).

> **Wooow:** durante el enfriado, el aroma se "extiende" a la zona escaparate. Sistema sonoro: `bakery_warm_amb` activa + cliente walk-in **attraction rate aumenta** (§8.3 spawn rate boost).

### 4.9 Etapa 8 — Empaquetado y exposición

**Dos rutas paralelas:**

**Ruta A — Exposición vitrina (B2C):**
1. Coger cesta de mimbre + colocar panes en escaparate Z1.
2. Pan visible al cliente walk-in.
3. Cuando cliente compra (§8), ítem sale del stock vitrina.

**Ruta B — Empaquetado para B2B:**
1. Llevar pan a Z9 mesa empaquetado.
2. Colocar en cajas de cartón con logo empresa estampado.
3. Selladora aplica adhesivo con batch + lineage + sello cera digital.
4. Apilar cajas en palet.
5. Palet listo para Logística → Retail.

**Tiempo:** 5-8 min por palet completo.

### 4.10 Bonus — Cultivo de masa madre (gameplay temporal)

> **Mecánica opcional premium para desbloquear `bread_sourdough_rustic`.**

- Panadero cultiva masa madre en bote de cristal en Z4.
- **Refresco diario obligatorio:** echar harina + agua, esperar 12-24h.
- Si te olvidas 48h sin refrescar → masa muere, empezar de cero (5-7 días para cultivo activo).
- Masa madre activa **da bonus quality +0.10** a productos sourdough.
- **Wooow narrativo:** bote etiquetado con fecha de "nacimiento" del cultivo. RP rico.

---

## 5. Maquinaria — catálogo detallado

> **Aplicando regla Bible §13.4:** 3D entrega modelos sólidos con la idea wooow CORE (rigs animables); código añade rotación, partículas, glow, sound espacial.

### 5.1 Amasadora industrial — `bakery_machine_mixer`

**Descripción:** máquina con bowl acero inoxidable 60L y gancho-espiral. 1.2m alto × 0.8m ancho. Detalles brass Admirals en mando control + emblema empresa.

**3D entrega:** mesh con bowl extraíble + gancho rotativo + base motor + panel control con dial brass. Texture: acero brushed + brass detail + wear sutil. Rigs: rotación gancho, apertura bowl.

**Código añade:**
- Rotación del gancho (uniform `mixer_rpm` 0-3).
- Particle FX masa pegándose al gancho (custom abstract).
- Sound `bakery_mixer_loop` posicional 3D.
- Glow LED panel control si encendida.
- Vibración sutil del bowl (camera shake mínimo si player muy cerca).

### 5.2 Mesa de amasado a mano — `bakery_table_kneading`

**Descripción:** mesa industrial mármol blanco 2.5m × 1.2m × 0.9m alto. Patas roble. Báscula brass empotrada en esquina.

**3D entrega:** mesh sólida con surface mármol + estructura roble + báscula empotrada. Texture: mármol vetas naturales + grain madera + brass báscula. Sin partes móviles.

**Código añade:**
- Layer "harina espolvoreada" (decal sobre superficie cuando panadero usando) — FX overlay.
- Cuando amasado a mano, anim character + masa visual (prop separado).
- Sound `bakery_dough_slap` posicional.

### 5.3 Cámara de fermentación — `bakery_machine_proofbox`

**Descripción:** armario cerrado 2m × 1m × 2.2m alto con puerta cristal brass-framed. Interior 8 estantes para bandejas. Panel control externo brass con humedad + temperatura.

**3D entrega:** mesh con puerta cristal brass-framed + interior estantes + panel externo + iluminación interior amber sutil. Animación apertura puerta. Detalle: condensación cristal (texture variant).

**Código añade:**
- FX `bakery_fx_steam_proofbox` — vapor visible al abrir.
- Glow interior brass cuando activa.
- Shader uniform `humidity_level` modula condensación texture.
- Sound `bakery_proofbox_hum` ambient suave.
- Las bandejas dentro tienen uniform `dough_growth` 0-1 que infla la masa visualmente.

### 5.4 Horno rotativo eléctrico — `bakery_oven_rotary` ⭐

**Descripción:** horno eléctrico industrial de panadería, 2.5m × 1.8m × 2.4m alto, capacidad 16 bandejas en carro rotativo. Puerta vertical grande con vidrio resistente. Panel control brass digital. Acabado acero negro mate + brass details premium.

**3D entrega:** mesh con puerta apertura vertical + carro rotativo interior + panel control brass externo. Texture: acero negro brushed + brass + glass + interior brick. Rig animable: puerta sube, carro rota. Variantes: "puerta cerrada", "puerta abierta full", "puerta media-abierta".

**Código añade:**
- **Glow naranja-rojo del fuego visible** (emissive uniform `oven_glow`) cuando precalentado/horneando.
- **Vapor + heat shimmer** al abrir (FX `bakery_fx_oven_open` — combina steam + heat distortion shader).
- Rotación carro interior (uniform `rotary_speed`).
- Sound layers: `bakery_oven_idle_loop`, `bakery_oven_door_open`, `bakery_oven_breathing`.
- Temperature uniform comunicado a Tablet (panel digital muestra T° en vivo).
- Estado on/off → panel LED brass cambia color.

> **Wow primario del nodo:** abrir el horno con bandeja de pan dorado humeante.

### 5.5 Horno tradicional de leña — `bakery_oven_woodfired` (variante premium)

**Descripción:** horno mediterráneo bóveda ladrillo, hueco para leña, puerta hierro forjado con asa brass. 2.5m diámetro. **Estética heritage premium.** Solo en variante Premium.

**3D entrega:** mesh con bóveda ladrillo refractario + hueco frontal + puerta hierro + base piedra. Texture: ladrillo envejecido marcas calor + hierro oxidado + brass pulido en asa. Anim apertura puerta con bisagra brass crujiente.

**Código añade:**
- **Fuego real visible dentro** (particle FX `bakery_fx_wood_fire`).
- Glow naranja muy fuerte cuando puerta abierta.
- Smoke particles saliendo por chimenea exterior (FX `bakery_fx_chimney_smoke` — visible desde la calle).
- Crepitar de leña (`bakery_woodfire_crackle`).
- Heat distortion delante.
- **Wow marketing:** cliente walk-in ve humo saliendo de la chimenea desde la calle. **Genial para screenshot.**

### 5.6 Cámara fría — `bakery_cold_room`

**Descripción:** armario refrigerador industrial 2m × 1m × 2.4m, puerta acero con manija brass, 6 estantes. Control externo T°.

**3D entrega:** mesh con puerta + interior estantes + panel control. Texture: acero blanco-frío + brass handle + interior con LED azul. Anim puerta.

**Código añade:**
- **Vapor frío saliendo al abrir puerta** (FX `bakery_fx_cold_air`).
- Sound `bakery_cold_room_hum` (compresor).
- Indicador LED panel temperatura.

### 5.7 Báscula brass de mostrador — `bakery_scale_brass`

**Descripción:** báscula vintage brass de balanza con plato y aguja. Capacidad 0-10kg. **Hero prop wow del mostrador.**

**3D entrega:** mesh con plato pivotante + aguja + dial circular grande (números visibles) + base brass. Texture: brass pulido envejecido + dial blanco con números negros. Rig: aguja gira según peso.

**Código añade:**
- Uniform `scale_weight` 0-10 que rota la aguja proporcional.
- Sound `bakery_scale_tick` cuando aguja pasa marcas.
- Detection cuando panadero coloca item → peso detected → aguja ajusta.

### 5.8 Selladora de empaquetado — `bakery_sealer_machine`

**Descripción:** máquina pequeña mostrador, 0.4m × 0.3m × 0.4m alto, sella bolsas plástico con calor + aplica etiqueta adhesiva. Brass detail en palanca.

**3D entrega:** mesh con base + palanca + zona sellado + carrete etiquetas. Texture: industrial blanco + brass palanca. Anim palanca up/down.

**Código añade:**
- Sound `bakery_sealer_press` al accionar.
- Particle FX micro de vapor al sellar (heat seal).
- Etiqueta aplicada genera prop "etiqueta con batch + sello brass" pegada al producto.

### 5.9 Resumen budget maquinaria oleada 1

| Asset | 3D custom | Aparece en |
|---|---|---|
| `bakery_machine_mixer` | 1 | Z4 obrador |
| `bakery_table_kneading` | 1 | Z4 obrador |
| `bakery_machine_proofbox` | 1 | Z6 fermentación |
| `bakery_oven_rotary` | 1 (con states) | Z5 hornos |
| `bakery_oven_woodfired` | 1 (variante premium — backlog) | Z5 — solo premium |
| `bakery_cold_room` | 1 | Z8 |
| `bakery_scale_brass` | 1 (hero prop) | Z2 mostrador |
| `bakery_sealer_machine` | 1 | Z9 empaquetado |
| **Total maquinaria custom** | **7 (oleada 1) + 1 (premium futuro)** | |

> Cabe en budget Bible §13.4 (≤25 assets per node). Quedan slots para escenografía + items físicos en §11.

---

## 6. Sistema de empresa — adaptación a la Panadería

> **Reusa la arquitectura validada de Granja §11 y Molino §6.** Mismo modelo: 4 roles + dual-pool de caja + contratos B2B vía Tablet + permisos. Los específicos de la Panadería son los puestos y la naturaleza dual del negocio (B2B + B2C simultáneos).

### 6.1 Empresa "Panadería Admirals" — definición

```yaml
business_type: "bakery_admirals"
business_class: "production_with_storefront"   # nuevo class — combina producción + venta directa
required_assets:
  - mlo_bakery (variante elegida: small/standard/premium)
  - oven_rotary (mín 1)
  - mixer (mín 1)
  - proofbox (mín 1)
  - cold_room (mín 1)
  - scale_brass (mín 1)
  - sealer (mín 1)
ownership_modes: ["player_solo", "player_group", "npc_bridge"]
default_currency: "EUR"
dual_channel: true   # ⭐ flag específico — habilita B2C walk-in además de B2B
```

### 6.2 Roles de la empresa Panadería

| Rol interno | Permisos | Sueldo base |
|---|---|---|
| **Maestro Panadero** (owner / CEO) | Todo. Contratos B2B. Recetas custom. Contratación. Banca. | Sin sueldo (cobra dividendos). |
| **Oficial Panadero** (senior) | Operar maquinaria. Crear batches. Acceder almacén. Atender mostrador. NO firma contratos. | 180-280€/turno. |
| **Aprendiz Panadero** (junior) | Asistir maestro. Empaquetado. Limpieza. Atender mostrador. NO opera horno solo. | 100-160€/turno. |
| **Dependiente** (mostrador) | Solo Z1+Z2 — atiende cliente walk-in, cobra, repone vitrina. NO entra a obrador. | 90-140€/turno. |
| **Repartidor** (opcional) | Maneja camión salida. Entrega pedidos B2B. NO opera obrador. | 130-180€/turno. |

> **Específico de la Panadería:** rol **Dependiente** es nuevo respecto a Granja/Molino. Es el primer puesto del ecosistema **dedicado exclusivamente a atender cliente final** — desbloquea pattern para Retail oleada 2.

### 6.3 Dual-pool de caja (mismo modelo Granja §11.3)

- **Caja Operativa** — gastos día a día (ingredientes, sueldos, mantenimiento maquinaria, electricidad horno).
- **Caja de Inversión** — capital reserva (compra horno premium, expansión MLO, contratos pesados).

**Específico Panadería:** la caja se alimenta de **2 fuentes paralelas:**
1. **Ingresos B2B** — pagos por contratos firmados a Retail/restaurantes (entran como transferencias bancarias programadas).
2. **Ingresos B2C** — efectivo de la caja registradora del mostrador Z2 (acumula a lo largo del día, ingresa al banco al final del turno).

> Tablet muestra ambos flujos separados — el Maestro ve "hoy hemos vendido 240€ B2C en mostrador + 1.450€ B2B firmados".

### 6.4 Contratos B2B disponibles para la Panadería

| Tipo | Quién firma | Ejemplo |
|---|---|---|
| **Contrato semanal Retail** | Tienda/supermercado | "150 baguettes + 80 panes integrales/día, lun-vie." |
| **Contrato hostelería** | Restaurante / bar | "60 baguettes/día, recogida 7am exacta." |
| **Contrato hotel premium** | Hotel jugable (futuro) | "200 panes mixtos para desayuno buffet, 6:30am." |
| **Contrato evento puntual** | Catering, fiestas | "500 panecillos para evento boda sábado." |
| **Contrato exclusividad** | Restaurante premium | "Sourdough exclusiva, solo para nosotros, 30 hogazas/semana." |

### 6.5 Pipeline de contratación (adaptado de Granja/Molino)

```
[Cliente B2B descubre Panadería en directorio Tablet "Mercado"]
       ↓
[Solicita oferta — cantidad + frecuencia + calidad mínima]
       ↓
[Maestro Panadero recibe notif Tablet "Nueva solicitud"]
       ↓
[Negocia precio/frecuencia/penalty cláusulas en chat Tablet]
       ↓
[Firma con sello brass — ceremonia §14.8 art direction]
       ↓
[Contrato activo — pedidos automáticos en agenda diaria del Panadero]
       ↓
[Producción → Logística → Entrega → Pago automático Banca]
```

### 6.6 Sueldos y dinámica turnos

> **Específico Panadería — turnos cortos pero madrugadores.**

| Turno | Horario canónico | Quién |
|---|---|---|
| **Turno producción** | 03:00 - 11:00 (8h) | Maestro + 1-2 oficiales |
| **Turno mostrador** | 06:00 - 14:00 (8h) | Dependiente + opcional aprendiz refuerzo |
| **Turno tarde (limpieza/prep)** | 15:00 - 19:00 (4h) | 1 aprendiz (opcional) |

> Los turnos NO son obligatorios técnicamente — un Maestro solo puede llevar la panadería entera con menos producción. Servidores RP grandes premian roles distribuidos.

---

## 7. Manager Panel del Panadero — apps Tablet específicas

> **La app Manager Panel** es la misma del ecosistema (Tablet §7), pero con instancia "Panadero" registrada al instalar el resource. **6 áreas, mismo lenguaje visual** que Granjero/Molinero + un área NUEVA específica para B2C.

### 7.1 Áreas del Manager Panel del Panadero

| # | Área | Función |
|---|---|---|
| 7.1.1 | **Dashboard** | KPIs día: panes producidos, vendidos B2C, vendidos B2B, calidad promedio, batches activos. |
| 7.1.2 | **Recetas y producción** | Catálogo recetas + arrancar batch + ver batches activos con timers. |
| 7.1.3 | **Mostrador / B2C** ⭐ | **Nueva área específica** — vista de caja registradora + historial ventas walk-in + stock vitrina. |
| 7.1.4 | **Almacén e inventario** | Stock harinas + ingredientes + producto terminado + masa madre activa. |
| 7.1.5 | **Contratos B2B** | Ver contratos activos + agenda pedidos del día + aceptar nuevos. |
| 7.1.6 | **Empleados y turnos** | Roster + turnos + sueldos + permisos. |

### 7.2 Dashboard del Panadero — anatomía

```
┌─────────────────────────────────────────────────┐
│  PANADERÍA LA ALMIRANTAZGO              06:42   │
│  Hoy — Martes 30 abril                          │
├─────────────────────────────────────────────────┤
│  PRODUCCIÓN HOY                                 │
│  · 48 baguettes ✅  · 24 hogazas ✅             │
│  · 12 sourdough en ferm 1ª (62%) ⏱             │
│  · 24 croissants en horno (12min restantes) 🔥  │
├─────────────────────────────────────────────────┤
│  VENTAS HOY                                     │
│  · B2C mostrador:  247€  (37 transacciones)     │
│  · B2B mayorista: 1.450€  (3 contratos hoy)     │
│  · Total bruto:   1.697€                        │
├─────────────────────────────────────────────────┤
│  ALERTAS                                        │
│  ⚠ Stock harina blanca bajo: 12 sacos (re-pedir)│
│  ⚠ Masa madre necesita refresco hoy            │
│  ✅ Pedido Bistro Marqués entregado 06:30      │
└─────────────────────────────────────────────────┘
```

### 7.3 App "Recetas y producción"

- Catálogo recetas oleada 1 (5 categorías + bollería).
- Botón **"Arrancar batch"** — selecciona receta + cantidad + autoriza inicio.
- Vista batches activos: timer + etapa actual + ventana óptima destacada brass.
- **Notificaciones críticas push** cuando batch entra ventana óptima fermentación / horneado próximo a terminar.
- Historial batches: lineage + calidad final + ventas trace.

### 7.4 App "Mostrador / B2C" ⭐ (nueva)

> **Área específica de Panadería que NO existe en Granja/Molino.** Aquí gestiona el dependiente o el panadero las ventas directas.

**Pantalla principal:**

```
┌─────────────────────────────────────────────────┐
│  CAJA — MOSTRADOR                  06:42        │
├─────────────────────────────────────────────────┤
│  STOCK VITRINA AHORA                            │
│  · Baguette clásica       12 ud  1.50€          │
│  · Pan blanco común        8 ud  1.20€          │
│  · Hogaza integral         6 ud  2.50€          │
│  · Sourdough rústica       4 ud  6.00€          │
│  · Croissant butter       18 ud  2.20€          │
├─────────────────────────────────────────────────┤
│  ÚLTIMAS VENTAS                                 │
│  06:39 PED Mike Bellic   1×baguette       1.50€ │
│  06:37 PED Tracey        2×croissant      4.40€ │
│  06:35 PED Lamar         1×sourdough      6.00€ │
├─────────────────────────────────────────────────┤
│  TOTAL HOY: 247€  (37 transacciones)            │
│                                                 │
│  [REPONER VITRINA] [CERRAR CAJA] [Z-REPORT]     │
└─────────────────────────────────────────────────┘
```

**Acciones:**
- **Reponer vitrina** — abre selector con stock pan disponible en zona enfriado, panadero arrastra a vitrina.
- **Cerrar caja** — imprime Z-report del día + transfiere efectivo a banco.
- **Z-report** — resumen del turno: ventas por producto, IVA, total.

### 7.5 App "Almacén e inventario"

- Stock harinas con lineage trace por saco.
- Stock ingredientes secundarios (sal, levadura, mantequilla, huevos).
- Producto terminado: en enfriado / vitrina / palets B2B.
- **Cultivo masa madre:** estado (activa / inactiva), última hora de refresco, alerta si necesita atención.
- Pedidos automáticos a Molino: configurar reglas "si stock harina blanca < 10 sacos, pedir 20 sacos automático al Molino San Juan".

### 7.6 App "Contratos B2B"

- Contratos activos con stats: cumplimiento, calidad media entregada, próxima entrega.
- Solicitudes nuevas pendientes — accept/reject/negotiate.
- Plantillas de contrato (semanal Retail, hostelería diaria, exclusividad premium).
- Calendario de entregas de hoy + próximos 7 días.
- Histórico facturación.

### 7.7 App "Empleados y turnos"

- Roster panadería: nombres, roles, sueldos, próximo turno.
- Asignar turnos drag-and-drop semanal.
- Permisos por rol (Bible §11.4 modelo).
- Despidos / contrataciones.

### 7.8 Lenguaje visual — coherencia con design system Tablet

> **Todo el Manager Panel del Panadero usa los mismos componentes que Granjero/Molinero** — `<DocumentCard>`, `<DataTable>`, `<KpiBlock>`, `<ContractEntry>`, etc. (art direction §12.4).

**Variaciones específicas Panadería:**
- Tonos paleta: **acentos cobre cálido** en lugar de earth-tone Granja o industrial-grey Molino.
- Iconografía custom: panes, baguettes, hogazas, croissants — versions Lucide-stylized con brass strokes.
- **Notificación signature** del nodo Panadería: chime suave + un "olor visual" (ondas cálidas brass al pop notif) — evoca el aroma sin ser literal.

---

## 8. Mercado, contratos y venta directa — el dual-channel ⭐

> **Esta sección es ÚNICA del nodo Panadería.** Es el primer nodo del ecosistema con **dos canales simultáneos** — y la solución arquitectónica que aplicaremos en Retail oleada 2.

### 8.1 Los dos canales — visión

```
                         PANADERÍA
                            │
            ┌───────────────┴──────────────┐
            ▼                              ▼
   CANAL B2B (mayorista)          CANAL B2C (walk-in)
            │                              │
   Contratos firmados en           Cliente PED entra al
   Tablet con sello brass.         escaparate, va al
   Producción planificada.         mostrador, compra.
   Logística entrega palets.       Efectivo o tarjeta.
   Pago bancario programado.       Sale con bolsa.
            │                              │
   Retail / Restaurantes /         Consumidor final
   Hostelería / Hotel              (player o NPC).
```

### 8.2 Canal B2B (mayorista) — funcionamiento

> **Mismo modelo que Granja/Molino** — contratos formales con calidad mínima, frecuencia, penalty cláusulas. Pago automático vía Banca.

**Tipos de contrato B2B Panadería:**
- **Contrato semanal Retail** — tienda firma "150 baguettes/día lun-vie" durante 12 semanas.
- **Contrato hostelería diario** — restaurante firma "60 panes recogida 7am cada día".
- **Contrato hotel premium** — hotel firma "200 panes mixtos para desayuno buffet, 6:30am".
- **Contrato evento puntual** — catering boda "500 panecillos sábado 14:00".
- **Contrato exclusividad sourdough** — restaurante premium firma "30 hogazas/semana, exclusiva".

**Penalty cláusulas:**
- Entrega tardía: penalty -10% pago de ese pedido.
- Calidad bajo mínimo: penalty -25% + opción rechazo total.
- Falta de stock: penalty contractual + posible cancelación de contrato.

**Logística B2B:**
- Repartidor (rol §6.2) carga palets en camión panadería.
- Conduce a punto entrega (Retail / restaurante).
- Cliente firma recepción Tablet.
- Banca transfiere automáticamente.

### 8.3 Canal B2C (walk-in) — funcionamiento ⭐

> **Mecanismo NUEVO en el ecosistema Admirals.** Sistema de generación de PED customers dinámicos que entran a la panadería a comprar directamente.

#### 8.3.1 Generación de clientes PED

**Sistema:** spawn de PEDs walk-in con **rate dinámica** según hora del día y atractivo de la panadería.

**Factores que afectan spawn rate:**

| Factor | Impacto |
|---|---|
| **Hora del día** | 6-11am pico (rate × 4) · 11-14h medio (rate × 2) · resto bajo (× 0.5). |
| **Stock vitrina** | Vitrina llena (rate × 1.3) · vitrina vacía (rate × 0.3). |
| **Calidad pan en vitrina** | Avg quality A+ (× 1.4) · D (× 0.6). |
| **Pan caliente** (recién horneado) | × 1.5 boost durante 30min post-horneado. |
| **Reputation panadería** | Score 0-100 acumula con buenas ventas + tiempo. Affecta rate. |
| **Tráfico peatonal zona MLO** | Vinewood Blvd alto · Paleto Bay bajo. |

**Configuración:**
- Servidor admin define `bakery_walkin_baseline_rate` en config (ej. "1 PED cada 3 minutos baseline").
- Sistema multiplica por factores anteriores.
- Cap superior: max 1 PED en mostrador simultáneamente (queue si más).

#### 8.3.2 Comportamiento del PED customer

```
[Spawn fuera del MLO en calle Z13]
       ↓
[Walk hacia escaparate]
       ↓
[Anim: mira vitrina, pondera 5-10s]
       ↓
[Decisión: comprar o irse]
       ├─ irse (~30% si calidad baja o vitrina poco atractiva) → walk away
       └─ entrar
       ↓
[Walk al mostrador Z2]
       ↓
[Anim espera turno]
       ↓
[Selecciona producto (texto sobre cabeza: "Una baguette, por favor")]
       ↓
[Player o NPC dependiente atiende]
       ├─ player atiende: cobra desde Tablet caja
       └─ NPC dependiente: auto-atiende en X segundos
       ↓
[Anim: dependiente coge pan, lo embolsa, cobra]
       ↓
[Anim: cliente paga (efectivo o tarjeta)]
       ↓
[Anim: cliente recibe bolsa, sonríe, sale]
       ↓
[Despawn fuera del MLO]
```

**Dialog system PED:**
- Líneas pre-grabadas: "Una baguette, por favor", "Dame 2 hogazas", "El sourdough, se ve increíble", "Buenos días, lo de siempre".
- Variación según hora: "Buenos días" antes 10am, "Buenas tardes" después.
- Comments contextuales: si ven pan recién hecho (humeante) → "Huele increíble aquí" (boost reputation).

#### 8.3.3 Player customers (otros jugadores compran)

> **Players reales también pueden entrar como customers.** Mismo flow pero sin AI:
- Player walk-in entra al MLO normalmente.
- Va al mostrador, target prompt "Comprar pan".
- UI radial: selecciona producto + cantidad.
- Pago desde wallet del player → caja de la panadería.
- Recibe ítem físico en inventario.

> **Coherencia:** un player puede comprar 1 baguette para él, ir a su casa, comerla con animación de comer. **Cierra el ciclo del pilar Bible §3.1 — del campo a la mesa.**

#### 8.3.4 Caja registradora — UX del cobro

**Cuando un cliente (PED o player) llega al mostrador:**

- Tablet del player atendedor recibe **notificación push**: "Cliente pide: 1× baguette + 2× croissant. Total: 5.90€".
- Player elige método cobro:
  - **Efectivo** — anim recibir billetes, dar cambio. Caja registradora suma.
  - **Tarjeta** — anim cliente acerca tarjeta (NFC), beep, terminal Tablet.
- Player **pulsa "Confirmar cobro"** — transacción cerrada.
- Stock vitrina decrementa.
- Cliente PED recibe bolsa (anim) y sale.

**Caja registradora física Z2:**
- Modelo 3D vintage brass (hero prop de mostrador, art direction §16.5).
- Anim: cajón abre con sound `bakery_register_drawer`.
- Cuando hay efectivo dentro, modelo visible.

#### 8.3.5 Stock vitrina — sistema físico

> **El pan que el cliente walk-in compra es STOCK FÍSICO real en la vitrina.** No abstracto.

- Cestas de mimbre del escaparate Z1 tienen capacidad limitada (8-12 unidades cada una).
- Cuando una cesta se vacía, **no entra cliente PED a comprar ese producto** (lógica spawn rate).
- Player debe **reponer vitrina** desde stock enfriado (acción §7.4 + anim caminar con cesta).
- **Visual real:** una vitrina con 12 baguettes se ve diferente a una con 2.

### 8.4 Pricing dinámico (oleada 1: lite)

> **Oleada 1:** sistema simple, oleadas 2+ pricing dinámico complejo.

- **B2C precios** definidos por el Maestro Panadero en config (ej. baguette 1.50€).
- **Descuento automático** si producto cerca de end-of-prime:
  - Producto en última 25% de vida útil prime → -15% precio.
  - Producto pasado prime → -40% (visible "oferta del día").
  - Producto cerca de merma → -60% o donación banco alimentos.
- **B2B precios** negociados en contrato — fijos durante vigencia.

### 8.5 Reputation system de la panadería

> **Sistema simple oleada 1 — sirve como base para Retail oleada 2 más complejo.**

- Score 0-100 público.
- Sube con: buenas reviews PEDs, contratos cumplidos sin penalty, calidad consistente.
- Baja con: contratos incumplidos, calidad baja repetida, retrasos.
- **Visible en directorio Tablet "Mercado"** — clientes B2B ven reputación antes de firmar.
- **Afecta spawn rate B2C** (§8.3.1).

---

## 9. Edge cases de la Panadería

### 9.1 Pan quemado en horno

**Trigger:** panadero olvida sacar bandeja a tiempo.

**Comportamiento:**
- Modelo 3D pan oscurece progresivamente (uniform `burn_level` 0-1).
- Sound `bakery_oven_burn_alert` cuando `burn_level > 0.7`.
- Si llega a 1.0 → producto destruido, `quality = 0`.
- Tablet notifica: "⚠ Batch BAK-XXXX quemado — pérdida de 16 panes".
- Pan quemado va a basura (waste tracking en analytics empresa).

### 9.2 Cliente B2C insatisfecho

**Trigger:** PED compra pan y resulta de calidad D (muy baja).

**Comportamiento:**
- 30% chance PED hace comment negativo audible: "Esto está duro" o "No volveré".
- Reputation score panadería: -2.
- Si recurrente: clientes empiezan a rate-down spawn.

### 9.3 Contrato B2B incumplido

**Trigger:** Panadero no entrega pedido de contrato a tiempo.

**Comportamiento:**
- Penalty automática según cláusula (-10% a -25% del pago).
- Notif al cliente B2B: "Tu pedido de hoy no llegó".
- Cliente puede: aceptar penalty / rescindir contrato / pedir extensión.
- Si rescinde: contrato cancelado + reputation -10.

### 9.4 Falta de ingredientes inesperada

**Trigger:** panadero arranca batch pero no tiene suficiente harina/levadura/etc.

**Comportamiento:**
- Tablet: "⚠ No puedes arrancar batch — falta 2.5kg harina blanca".
- Sugiere: re-pedir al Molino (1 click) o cancelar.
- Si batch ya arrancado y quedan etapas con ingredientes faltantes → batch pausado, panadero debe resolver.

### 9.5 Masa madre muerta

**Trigger:** panadero olvida refresco 48h+.

**Comportamiento:**
- Tablet notifica diariamente con escalación: "⚠ Refresca masa madre" → "🚨 24h sin refresco" → "💀 Masa madre muerta".
- Si muere: cultivo se reinicia (5-7 días para activo de nuevo).
- Productos sourdough no producibles durante ese período.

### 9.6 Horno averiado

**Trigger:** azar tras X horas de uso continuo / falta de mantenimiento.

**Comportamiento:**
- Sound `bakery_oven_malfunction` + spark FX visual.
- Horno deja de funcionar — no precalienta.
- Panadero debe **comprar reparación** vía Tablet (NPC mecánico) — coste 200-500€ + 30min downtime.
- Ingrediente preventivo: limpieza diaria del horno (5min anim) reduce probabilidad.

### 9.7 Robo / asalto al mostrador (RP eventual)

**Trigger:** evento RP de servidor (raro, opt-in).

**Comportamiento:**
- Player malicioso entra con arma, exige caja.
- Sistema integra con economía RP del servidor.
- Caja registradora puede estar **vacía si Z-report acaba de hacerse** — incentiva cerrar caja regularmente.

### 9.8 Pan en vitrina expirado

**Trigger:** producto en vitrina supera vida útil prime + descontado.

**Comportamiento:**
- Modelo 3D visible degradación (color pálido, textura menos atractiva).
- Spawn rate B2C reduce drásticamente.
- Tablet notifica: "Pan en vitrina caducado — retirar".
- Producto retirado va a:
  - Banco de alimentos NPC (donación, +reputation comunidad).
  - Basura (waste tracking).
  - Conversión a pan rallado / panko (oleada 2 — feature backlog).

### 9.9 Sobrecarga producción (3 contratos simultáneos)

**Trigger:** Maestro firma demasiados contratos para capacidad.

**Comportamiento:**
- Tablet: "⚠ Capacidad horneado insuficiente para entregas mañana 6am".
- Panadero debe priorizar: contratar más empleados, comprar 2º horno, rechazar contrato nuevo.
- **Diseño deliberado:** la **escasez de capacidad de horneado** es el bottleneck principal — gameplay táctico real.

---

## 10. Hooks a otras verticales

> **La Panadería es nodo central que conecta con muchas verticales presentes y futuras.**

### 10.1 Hooks oleada 1 (activos al launch)

- **Granja Admirals** — vía Molino, recibe trigo trazable.
- **Molino Admirals** — proveedor directo de harinas, contratos B2B continuos.
- **Banca Admirals** — facturación contratos, transferencias, cuenta empresa, préstamos para 2º horno.
- **Logística Admirals** — repartidor entrega palets B2B (camión + ruta).

### 10.2 Hooks oleada 2 (próximos)

- **Retail Admirals** — el cliente B2B principal de la Panadería. Tienda recibe palets diarios. **Pattern B2C walk-in se reusa en Retail.**
- **Lácteos / Granja vacas** — proveedor de mantequilla + huevos (oleada 2 desbloquea como real, no NPC bridge).
- **Supermercado mayorista** — vende ingredientes secundarios (sal, levadura, azúcar) si el panadero no quiere ir a NPC suppliers individuales.

### 10.3 Hooks oleadas futuras

- **Pastelería / Repostería** (vertical separada o expansión) — comparte filosofía pero focus en dulces, tartas, postres premium.
- **Cadena Hostelería** — restaurantes propios que firman contratos masivos.
- **Cadena Catering / Eventos** — boda, celebraciones, contratos puntuales pero grandes.
- **Agricultura ecológica** — variedad "harina ecológica certificada" con label premium en pan + precio +30%.
- **Distribución de pan congelado** (mercado mass-market) — panes pre-horneado parcial, vendidos a supermercados, descongelan + finalización.

### 10.4 Hooks RP no comerciales

- **Eventos servidor:** torneo "mejor pan del año" — paneles de jueces, premios in-game.
- **Festivales gastronómicos:** la panadería como participante.
- **Donación banco alimentos:** producto cerca de merma se dona vía NPC bridge — +reputation, evento RP narrativo.

---

## 11. Assets 3D — briefing equipo 3D

> **Aplicando regla Bible §13.4**: el 3D entrega el modelo funcional con la idea wooow CORE. El código añade el shimmer.

### 11.1 Lista canónica de assets 3D oleada 1

#### MLO (1 asset estructural — 3 variantes)

| Asset | Descripción | Prioridad |
|---|---|---|
| `mlo_bakery_standard` | Variante canónica 20×15m: 13 zonas (§2.2), doble fachada urbana | **P0** |
| `mlo_bakery_small` | Variante pequeña 12×10m: zonas reducidas, 1 horno solo | P1 (toggle config) |
| `mlo_bakery_premium` | Variante 30×20m con horno tradicional leña + zona heritage | **P2 (oleada 2)** |

#### Maquinaria (7 assets — §5)

| Asset | Tipo | Hero |
|---|---|---|
| `bakery_machine_mixer` | Amasadora industrial | – |
| `bakery_table_kneading` | Mesa amasado mármol | – |
| `bakery_machine_proofbox` | Cámara fermentación | – |
| `bakery_oven_rotary` | Horno rotativo eléctrico | ⭐ |
| `bakery_oven_woodfired` | Horno tradicional leña (premium) | ⭐ (oleada 2) |
| `bakery_cold_room` | Cámara fría | – |
| `bakery_scale_brass` | Báscula brass mostrador | ⭐ |
| `bakery_sealer_machine` | Selladora empaquetado | – |

#### Hero props escenografía (4 — §16.5 art direction extension)

| Asset | Zona | Wow |
|---|---|---|
| `bakery_register_brass` | Z2 mostrador | Caja registradora vintage brass — pieza de mostrador. |
| `bakery_window_display` | Z1 escaparate | Estructura interior de la vitrina con cestas mimbre + estantes superiores + iluminación. |
| `bakery_mother_dough_jar` | Z4 obrador | Bote cristal con masa madre activa — etiqueta brass con fecha de "nacimiento". |
| `bakery_chalkboard_menu` | Z2 mostrador | Pizarra con menú del día escrito en tiza, marco roble + brass. |

#### Items físicos (productos + ingredientes — ~12 assets)

| Asset | Detalle |
|---|---|
| `bread_white_basic_v1` | Pan blanco 500g — modelo dorado con corte cruzado típico. |
| `bread_whole_country_v1` | Hogaza integral 750g — más oscura, con harina espolvoreada arriba. |
| `bread_baguette_classic_v1` | Baguette 60cm × 8cm — modelo dorado con cortes longitudinales. |
| `bread_sourdough_rustic_v1` | Hogaza sourdough 1kg — corteza oscura rugosa, marca cruz cuaja. |
| `pastry_croissant_butter_v1` | Croissant 80g — capas visibles, dorado mantequilla. |
| `flour_sack_25kg_branded` | Saco harina 25kg con logo Molino + brass label batch. |
| `salt_bag_5kg` | Saco sal con logo proveedor. |
| `yeast_block_500g` | Bloque levadura fresca refrigerado. |
| `butter_block_1kg` | Bloque mantequilla papel encerado + sello brass. |
| `paper_bread_bag` | Bolsa de papel kraft con logo Panadería para B2C. |
| `cardboard_bread_box` | Caja cartón mayorista con logo + sello brass. |
| `wicker_basket_display` | Cesta mimbre vitrina (props decorativos). |

#### Vehículos (1 asset — opcional)

| Asset | Detalle |
|---|---|
| `bakery_delivery_van` | Furgoneta de reparto blanca con logo Panadería brass — para B2B logística. (Oleada 1: variante reuso van GTA con livery custom — barato.) |

#### Total budget oleada 1

| Categoría | Cantidad |
|---|---|
| MLO + variantes | 1 (P0) + 1 (P1 small mode toggle) |
| Maquinaria | 7 (P0) + 1 (premium oleada 2) |
| Hero props escenografía | 4 |
| Items físicos | ~12 |
| Vehículos | 1 livery |
| **Total custom oleada 1** | **~25 piezas custom** ✅ dentro del cap Bible §13.4 |

### 11.2 Detalles wooow específicos por asset (qué se diferencia del nativo)

> **Si el 3D team duda "puedo coger el asset nativo X de GTA?"**, esta tabla decide.

| Asset | ¿Hay nativo aceptable? | Decisión |
|---|---|---|
| Mesas/sillas obrador interior | Sí (multiple props) | **Reusa nativo.** |
| Estanterías metálicas almacén | Sí | **Reusa nativo.** |
| Amasadora industrial | No (no hay equivalente naval-premium) | **Custom.** |
| Horno rotativo eléctrico | No (los hornos GTA son cocinas residenciales) | **Custom.** |
| Báscula brass | No (no hay ninguna brass + dial) | **Custom hero prop.** |
| Caja registradora vintage | Hay genéricas, no premium brass | **Custom hero prop.** |
| Cestas mimbre | Sí | **Reusa nativo + textura custom logo.** |
| Sacos harina | Hay sacos genéricos, no con label batch + lineage scan | **Custom (variante con label brass).** |
| Pan modelos | No (los breads de GTA son cartoony) | **Custom 5 modelos.** |
| Bolsa papel kraft | No | **Custom (con logo).** |

### 11.3 Texture sets requeridos

> **§15.4 art direction texture authoring guidelines aplican a cada asset.**

| Material | Uso | Notas |
|---|---|---|
| `mat_bakery_oven_steel_black` | Horno rotativo cuerpo | Acero negro mate brushed + brass detail. Roughness variado. |
| `mat_bakery_oven_brick` | Horno tradicional bóveda | Ladrillo refractario envejecido con marcas calor. |
| `mat_bakery_marble_white` | Mesa amasado | Mármol blanco con vetas naturales sutiles. |
| `mat_bakery_brass_polished` | Detalles maquinaria + báscula | Brass pulido envejecido sutil. |
| `mat_bakery_wicker_basket` | Cestas vitrina | Mimbre natural envejecido. |
| `mat_bakery_paper_kraft` | Bolsa papel | Papel kraft natural con grano. |
| `mat_bakery_bread_crust` | Pan modelos | **Material clave del nodo** — corteza dorada-oscura con variaciones, normal map riguroso de cortes. |
| `mat_bakery_bread_crumb` | Interior pan (visible si cortado) | Miga blanca con burbujas — solo en variants premium oleada 2. |
| `mat_bakery_butter_wax` | Bloques mantequilla | Papel encerado amarillento. |

### 11.4 Shader uniforms expuestos al código

> Catálogo a registrar en `docs/art/02_shader_contracts.md`:

| Material | Uniforms | Range | Owner código |
|---|---|---|---|
| `mat_bakery_oven_steel_black` | `oven_glow` | float 0-1 (emissive intensity interior) | `admirals_bakery_visuals` |
|  | `door_open_state` | float 0-1 (afecta heat shimmer overlay) | id. |
| `mat_bakery_bread_crust` | `freshness` | float 0-1 (1=recién hecho cálido, 0=duro pasado) | id. |
|  | `burn_level` | float 0-1 (oscurece progresivamente) | id. |
|  | `dough_growth` | float 0-1 (size factor durante fermentación) | id. |
| `mat_bakery_paper_doc` (etiqueta saco) | `wax_seal_present` | bool | id. |
| `mat_bakery_proofbox_glass` | `humidity_level` | float 0-1 (condensación visible) | id. |
| `mat_bakery_wicker_basket` | `fill_count` | int 0-12 (controla shader visibility de panes apilados — opcional, alternativa props discretos) | id. |

---

## 12. Animaciones requeridas

### 12.1 Animaciones del personaje (panadero)

| Anim ID | Descripción | Duración | Loop |
|---|---|---|---|
| `bakery_anim_knead_manual` | Amasar masa a mano sobre mesa | 8s | Yes |
| `bakery_anim_knead_machine` | Supervisar amasadora industrial | 5s | Yes |
| `bakery_anim_weigh_ingredient` | Pesar en báscula brass | 4s | Once |
| `bakery_anim_dough_divide` | Dividir masa con espátula en porciones | 6s | Yes |
| `bakery_anim_bread_shape_round` | Formar bola pan blanco | 5s | Once per piece |
| `bakery_anim_bread_shape_baguette` | Estirar baguette | 12s | Once per piece |
| `bakery_anim_pastry_lamination` | Laminar masa croissant | 10s | Yes |
| `bakery_anim_pastry_shape_croissant` | Enrollar triángulo croissant | 8s | Once per piece |
| `bakery_anim_oven_load` | Cargar bandeja en horno (puerta abre, empuja, cierra) | 6s | Once |
| `bakery_anim_oven_unload` | Sacar bandeja del horno con guantes | 6s | Once |
| `bakery_anim_basket_carry` | Llevar cesta de pan caminando | Loop | Yes |
| `bakery_anim_display_refill` | Reponer vitrina (colocar panes en cesta) | 4s | Yes |
| `bakery_anim_register_use` | Manejar caja registradora vintage | 3s | Once |
| `bakery_anim_card_pay` | Presentar terminal Tablet a cliente con tarjeta | 3s | Once |
| `bakery_anim_seal_package` | Operar selladora con palanca | 2s | Once |
| `bakery_anim_pallet_move` | Mover palet con transpaleta | Loop | Yes |
| `bakery_anim_mother_dough_feed` | Refrescar bote masa madre (echar harina + agua) | 6s | Once |

### 12.2 Animaciones del cliente PED

| Anim ID | Descripción | Duración |
|---|---|---|
| `bakery_anim_ped_window_browse` | Mirar vitrina ponderando | 5-10s |
| `bakery_anim_ped_walk_to_counter` | Caminar al mostrador | Loop walking |
| `bakery_anim_ped_wait_queue` | Esperar turno | Loop idle |
| `bakery_anim_ped_order_speak` | Hablar pidiendo (con texto sobre cabeza) | 3s |
| `bakery_anim_ped_pay_cash` | Pagar efectivo | 3s |
| `bakery_anim_ped_pay_card` | Pagar tarjeta | 3s |
| `bakery_anim_ped_receive_smile` | Recibir bolsa + sonrisa | 2s |
| `bakery_anim_ped_walk_away` | Caminar saliendo | Loop |

### 12.3 Animaciones de objetos/maquinaria (rigs)

| Rig | Descripción |
|---|---|
| `bakery_rig_mixer_hook_rotate` | Gancho amasadora rotativo |
| `bakery_rig_oven_door_vertical` | Puerta horno rotativo subiendo |
| `bakery_rig_oven_carriage_rotate` | Carro interior rotativo del horno |
| `bakery_rig_proofbox_door` | Puerta cámara fermentación con bisagra |
| `bakery_rig_register_drawer` | Cajón caja registradora abriendo |
| `bakery_rig_scale_needle` | Aguja báscula brass moviendo |
| `bakery_rig_dough_growth` | Masa creciendo en bandeja (shape blend) |
| `bakery_rig_chalkboard_menu_text` | Pizarra menú (text dynamic vía code) |

---

## 13. Sonidos requeridos

> **Sound bible será completo en `docs/art/03_sound_bible.md`. Aquí el subset Panadería.**

### 13.1 Sonidos del proceso productivo (firma sonora del nodo)

| Sound ID | Descripción | Loop | Volume |
|---|---|---|---|
| `bakery_dough_slap` | Masa golpeando mesa amasado | No | Medio |
| `bakery_dough_kneading_loop` | Amasado a mano continuo | Yes | Bajo |
| `bakery_mixer_loop` | Amasadora industrial trabajando | Yes | Medio |
| `bakery_mixer_start` | Encender amasadora (motor arranca) | No | Medio |
| `bakery_mixer_stop` | Apagar amasadora (decay motor) | No | Medio |
| `bakery_proofbox_hum` | Cámara fermentación zumbido suave | Yes | Bajo |
| `bakery_proofbox_door_open` | Abrir cámara fermentación | No | Medio |
| `bakery_oven_idle_loop` | Horno encendido idle | Yes | Bajo |
| `bakery_oven_door_open` | Abrir horno (brass mecánico) | No | Medio-alto |
| `bakery_oven_door_close` | Cerrar horno | No | Medio |
| `bakery_oven_breathing` | Horneado intenso (sutil crepitar interior) | Yes | Bajo |
| `bakery_oven_burn_alert` | Alerta pan quemándose | No | Alto |
| `bakery_oven_malfunction` | Horno averiado (chispas + zumbido eléctrico raro) | No | Alto |
| `bakery_woodfire_crackle` | Fuego leña horno tradicional | Yes | Medio |
| `bakery_chimney_smoke_amb` | Aire saliendo chimenea exterior | Yes | Bajo |
| `bakery_cold_room_hum` | Compresor cámara fría | Yes | Bajo |
| `bakery_cold_air_burst` | Vapor frío al abrir cámara fría | No | Medio |
| `bakery_steam_bread_release` | Vapor del pan recién horneado | No | Bajo |
| `bakery_scale_tick` | Aguja báscula brass pasando marcas | No | Bajo |
| `bakery_sealer_press` | Selladora aplicando | No | Medio |
| `bakery_register_drawer` | Cajón caja registradora | No | Medio |
| `bakery_register_bell` | Campanita registradora vintage | No | Medio |
| `bakery_card_terminal_beep` | Beep terminal Tablet pago | No | Bajo |
| `bakery_paper_bag_rustle` | Bolsa papel kraft moviendo | No | Bajo |

### 13.2 Sonidos del cliente / venta B2C

| Sound ID | Descripción |
|---|---|
| `bakery_door_chime_bell` | Campanita brass al entrar cliente al MLO ⭐ |
| `bakery_ped_voice_order_es_*` | Voces clientes pidiendo (varios takes ES) |
| `bakery_ped_voice_order_en_*` | Voces clientes pidiendo (varios takes EN) |
| `bakery_ped_voice_smell_compliment` | "Huele increíble aquí" (boost reputation) |
| `bakery_ped_voice_complaint` | "Esto está duro" (calidad baja) |
| `bakery_ped_voice_thanks` | "Gracias, que tenga buen día" |

### 13.3 Sonidos de ambiente (atmosphere — §14.2 art direction)

| Sound ID | Descripción | Zona |
|---|---|---|
| `bakery_warm_amb_morning` | Ambiente cálido pan recién hecho + sutil aroma sonoro | Z1+Z2 escaparate (mornings) |
| `bakery_obrador_amb_busy` | Ambiente obrador con maquinaria + vapor | Z4-Z5 |
| `bakery_obrador_amb_quiet` | Ambiente obrador en pausa fermentación | Z4-Z5 |
| `bakery_storage_amb` | Almacén con sutil ventilación | Z7 |
| `bakery_cold_room_amb` | Cámara fría con compresor | Z8 |

### 13.4 Notificaciones Tablet específicas Panadería

| Sound ID | Descripción |
|---|---|
| `bakery_notif_proof_window_open` | Ventana óptima fermentación abierta — chime warm brass |
| `bakery_notif_oven_2min_warning` | 2 min antes fin horneado — chime urgente |
| `bakery_notif_burn_critical` | Pan quemándose — alerta crítica |
| `bakery_notif_b2c_sale` | Venta walk-in completada — chime caja |
| `bakery_notif_b2b_pickup_arrived` | Cliente B2B llegó a recoger pedido |

### 13.5 Master mix — la firma sonora del nodo

> **Cuando un jugador entra a la Panadería al amanecer, debería oír (en orden de prominencia):**

1. **`bakery_warm_amb_morning`** (ambiente base cálido).
2. **Sutil `bakery_oven_idle_loop`** desde la zona de hornos (background).
3. **`bakery_oven_door_open` ocasional + `bakery_steam_bread_release`** cuando el panadero saca bandejas.
4. **`bakery_door_chime_bell`** cuando entra cliente walk-in.
5. **`bakery_register_bell`** ocasional en cobros.
6. **PED voices** en cliente walk-in.

**Es el nodo MÁS sonoro y cálido del ecosistema oleada 1.**

---

## 14. Anti-patrones específicos del nodo + Roadmap

### 14.1 Anti-patrones (recordatorio crítico)

> **Cosas que rompen la promesa del nodo Panadería:**

- ❌ **Producción instantánea.** El pan tarda lo que tarda — fermentación NO se acelera.
- ❌ **Hornos sin glow visible.** El horno encendido se VE.
- ❌ **Pan sin vapor al sacar.** El vapor es **wow primario** del nodo.
- ❌ **Vitrina vacía pero clientes spawneando.** Si no hay stock, no hay clientes (lógica simple).
- ❌ **Cliente PED idéntico todos.** Variar modelos PED (10-20 variantes) para que la venta no se sienta repetitiva.
- ❌ **Pan eterno sin caducar.** Vida útil real, descuentos, donación banco alimentos al final.
- ❌ **Ignorar oficio nocturno.** El servidor admin que quita el horario canónico pierde la identidad — comunicar claramente que es deliberado.
- ❌ **B2B y B2C compitiendo por mismo stock sin lógica.** Definir prioridad: stock asignado a contratos B2B firmados primero, sobrante a vitrina B2C.
- ❌ **Caja registradora "menú abstracto".** La caja es **prop físico** con anim del cajón abriendo + sound + visible billetes dentro.
- ❌ **Aroma sin comunicación al jugador.** Si el jugador entra y no percibe que la panadería huele bien (vía sound layer + visual heat shimmer + comments PED), perdimos la promesa.

### 14.2 Roadmap del nodo

#### Oleada 1 (T-0 launch — incluido en producto comercial "Cadena del Pan")
- ✅ MLO standard + variante small mode.
- ✅ 7 maquinaria custom + 4 hero props.
- ✅ 5 recetas + bollería croissant.
- ✅ 8 etapas proceso jugables con fermentación tiempo real.
- ✅ B2B contratos + B2C walk-in funcional.
- ✅ Manager Panel 6 áreas Tablet.
- ✅ PED customer system con spawn dinámico.
- ✅ Reputation system básico.
- ✅ Lineage trace completo.

#### Oleada 2 (T+6 meses)
- 🔜 **Variante Premium con horno tradicional leña.**
- 🔜 **Pricing dinámico avanzado** (oferta-demanda-tiempo).
- 🔜 **Reputation system completo** con reviews públicos.
- 🔜 **Ingredientes avanzados:** semillas, frutos secos, especias.
- 🔜 **Recetas adicionales:** focaccia, pan de molde, brioche, ensaimada.
- 🔜 **Pan rallado / panko** como producto secundario aprovechando waste.
- 🔜 **Eventos especiales:** torneo "mejor pan del año".
- 🔜 **Integración Lácteos real** (mantequilla + huevos no NPC).

#### Oleada 3 (T+12 meses)
- 🔜 **Pastelería separada** (vertical hermana).
- 🔜 **Catering / eventos masivos** como contratos especiales.
- 🔜 **Distribución pan congelado** mass-market.
- 🔜 **Cadena Hostelería** propia con restaurantes jugables.

#### Oleada 4 (T+18-24 meses)
- 🔜 **Certificación ecológica** premium.
- 🔜 **Concursos internacionales** entre servidores Admirals.
- 🔜 **Master class panadero** — sistema de aprendizaje skill-based RP estructurado.

### 14.3 Métricas de éxito del nodo

> **Cómo sabremos si el nodo Panadería logra su promesa:**

| KPI | Target oleada 1 |
|---|---|
| Tiempo medio del jugador en MLO Panadería por sesión | ≥ 45 min |
| Player retention en rol Panadero a 30 días | ≥ 35% |
| Ventas B2C / B2B ratio en panaderías player-owned | 30% / 70% (B2C como complemento, no principal) |
| Calidad media del pan producido en servidores | ≥ B (0.65) |
| % de batches con timing_score = 1.0 (ventana óptima) | ≥ 60% |
| Rating Tebex específico al producto "Cadena del Pan" | ≥ 4.7/5 |
| Mentions del nodo Panadería en streams / showcase | Tracking baseline → +200% mes 6 |

---

## 15. Estado del documento

- **Versión:** 1.0 (firmado — completo, 15 secciones, 3 partes publicadas).
- **Próxima revisión:** evolución cuando se diseñe Retail (consume contratos B2B mayoristas).
- **Documentos hijos pendientes:**
  - `docs/economy/02_bakery_economy.md` — números detallados (precios B2B/B2C, costes, márgenes, balance económico del nodo).
  - `docs/technical/04_bakery_implementation.md` — arquitectura técnica del resource (eventos, schemas, NPC spawn system, fermentation timer architecture).
  - `docs/art/02_shader_contracts.md` — contratos materiales del nodo (§11.4 ya esbozados aquí).

### 15.1 Changelog del documento

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 (parte 1) | 2026-05-01 | Founder + Cascade | Redacción inicial: §0-§5 (filosofía, MLO, materias, proceso 8 etapas, maquinaria). |
| 1.0 (parte 2) | 2026-05-01 | Founder + Cascade | §6-§10 (empresa, Manager Panel, dual-channel B2B/B2C ⭐, edge cases, hooks). |
| 1.0 (parte 3) | 2026-05-01 | Founder + Cascade | §11-§15 (assets 3D, animaciones, sonidos, anti-patrones + roadmap, estado). **Documento completo, firmable.** |

---

## Resumen ejecutivo del documento (cierre)

La **Panadería Admirals** es el **nodo más sensorial y emocional del ecosistema oleada 1**. Cierra la Cadena del Pan con un nodo que:

- **Recibe harinas trazables** del Molino con calidad propagada hasta la parcela del granjero.
- **Transforma físicamente** mediante **8 etapas jugables**, incluyendo la mecánica única no acelerable de **fermentación en tiempo real**.
- **Vende por dos canales simultáneos** — B2B mayorista (contratos firmados) + B2C walk-in (clientes PED al escaparate). **Es el primer nodo del ecosistema con interface al consumidor final.**
- **Vive en oficio nocturno** — identidad temporal única, RP rico de madrugada.
- **Cierra la promesa narrativa Bible §1** — un saco de trigo que un jugador sembró hace tres días, hoy es la baguette que otro jugador come en su salón.

> **El día que un jugador en un servidor Admirals pueda decir "voy a comprarme una baguette en la panadería del barrio antes de ir al curro" — y esa baguette tenga lineage real hasta la parcela P03 del granjero Carlos del servidor RP italiano — habremos ganado.**

---

*"El pan recién hecho — la firma del oficio nocturno."*

**FIN DEL DOCUMENTO `04_node_bakery.md` v1.0**
