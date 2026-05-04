# 🔊 Admirals — Sound Bible

> **Versión:** 1.0 (firmado — completo, 15 secciones, 2 partes publicadas).
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2 (§13.4 — División 3D vs Código aplicada también a audio)
> **Documento hermano principal:** `art/01_art_direction.md` v1.0 (§9-§11 sound signatures por nodo).
> **Documento gemelo:** `art/02_shader_contracts.md` v1.0 (este doc es el paralelo sonoro).
> **Documentos referenciados:** todos los nodos §13 (`01_node_farm.md`, `03_node_mill.md`, `04_node_bakery.md`, `05_node_retail.md`) + `02_sonar_tablet.md` §13 (sonidos UI Tablet) + `technical/02_events_catalog.md` v1.0 (eventos que disparan sonidos).
> **Estado:** firmado.

> **Lectura previa obligatoria:** Bible §3 (Pilar 3 — detalle obsesivo), Art Direction §9-§11, cada node doc §13 (sonidos requeridos).

---

## 0. Resumen ejecutivo

Este documento es **el catálogo canónico de todo el audio del ecosistema Admirals**. Es el **paralelo sonoro** del `02_shader_contracts.md`.

Define:

- **Qué sounds existen** (catálogo unificado `*_sound_*` IDs).
- **Quién dispara cada sonido** (qué evento del bus / qué resource).
- **Master mix** por nodo — la firma sonora completa.
- **Categorías sonoras** (ambient, fx, voice, ui, notif, music).
- **Performance budgets** (instances simultáneos, prioridades).
- **Localization** strategy para voice lines.
- **Validation y testing** protocol.
- **Naming + ownership** matrix.

> **El audio es el 50% de la inmersión.** Un horno sin sound de fuego es un prop muerto. Un supermercado sin beep de POS es arcade. Esta Sound Bible asegura que **cada interacción jugable tiene su firma sonora canónica** y que ningún sonido se diseña ad-hoc.

---

## 1. Filosofía sonora

### 1.1 Los 5 principios del sonido Admirals

> **Recapitulación de Art Direction §9-§11 con foco operacional.**

#### Principio 1 — Sonido físico siempre (Bible Pilar 1)
> Si un objeto se ve, **se oye**. Si una acción se ejecuta, **suena**.

- Carrito moviéndose → `retail_cart_rolling` posicional.
- Saco de harina golpeando suelo → `mill_sack_drop_thud`.
- Pan saliendo del horno → `bakery_oven_bread_out`.

#### Principio 2 — Sonido propaga la cadena (Bible Pilar 2)
> El sonido del trigo cosechado SUENA distinto al sonido de la harina molida que SUENA distinto al sonido del pan horneado. **Cada paso es audible.**

#### Principio 3 — Detalle obsesivo (Bible Pilar 3)
> Un horno vacío suena distinto a uno con pan dentro. Un lineal lleno suena distinto a uno medio vacío al pasar carrito.

#### Principio 4 — Audio diegético sobre música
> **80% de la experiencia es audio diegético** (lo que pasa en el mundo). Música solo en momentos específicos: launch, marketing trailers, special events. **NO ambient music in MLOs.** Los MLOs viven de su atmósfera diegética.

#### Principio 5 — Brand sonora consistente
> El **chime de notificación de la Tablet** es la firma sonora del ecosistema — debe ser **inmediatamente reconocible** y compartido entre TODOS los nodos. Como el "Netflix tudum" o el "Mac startup chime".

### 1.2 Anti-patrones sonoros

> **Cosas que rompen la inmersión Admirals.**

- ❌ **Ambient music in-world.** Mata la atmósfera diegética.
- ❌ **Sonidos UI genéricos.** Cada notif Admirals debe ser custom brand.
- ❌ **Voice lines sin localization.** Todo voice line tiene IDs es-ES + en-US oleada 1, otros idiomas oleada 2+.
- ❌ **Sounds sin attenuation.** Posicional 3D obligatorio para todo lo que ocurre en MLO.
- ❌ **Loop sounds sin fade.** Compresores de neveras NO arrancan/paran abruptamente.
- ❌ **Master mix saturado.** En hora pico Retail, max 8 sounds simultáneos audibles — priority queue corta el resto.
- ❌ **Sonidos sin owner claro.** Cada sound ID tiene UN resource que lo dispara.

### 1.3 La meta sonora del producto

> **Test Wooow auditivo:** un jugador con auriculares puestos, ojos cerrados, escuchando 30 segundos del MLO de la Panadería en hora pico, debe poder describir QUÉ está pasando — escuchar el horno, los clientes, la caja, el mostrador.

**Ese es el target.**

---

## 2. División Audio team vs Code

> **Paralelo exacto al 3D vs Code de `02_shader_contracts.md` §2.** El audio team entrega assets sonoros + datos. Code los dispara según eventos del bus.

### 2.1 Responsabilidades Audio team

1. **Sound files** (.wav 48kHz 16-bit / .ogg vorbis q5).
2. **Sound bank metadata** (.dat según FiveM convention).
3. **Variantes sonoras** (3-5 variantes por SFX recurrente — evita repetition fatigue).
4. **Voice lines** (es-ES + en-US oleada 1) con scripts canónicos.
5. **Documentación de sound IDs** (este doc — sección por nodo).
6. **Master mix** por nodo (atmosphere prebaked + priorities).

### 2.2 Responsabilidades Code

1. **Disparar sounds** según estado del juego (eventos `admirals:*`).
2. **Posicional 3D** (entity-attached cuando aplique).
3. **Volume control** runtime (atenuación por distancia, ducking).
4. **Loop management** (start/stop con fades).
5. **Priority queue** cuando hay saturación.
6. **NO crear sounds** sin estar documentados aquí.

### 2.3 Tabla resumen

| Capacidad | Audio team | Code |
|---|---|---|
| Recording / sourcing | ✅ | ❌ |
| Mixing inicial | ✅ | ❌ |
| Variantes (rotación) | ✅ (definición) | ✅ (rotación runtime) |
| Posicional 3D | ❌ (data) | ✅ (placement) |
| Volume base | ✅ (default) | ✅ (override runtime) |
| Loop fade in/out | ❌ (data) | ✅ |
| Voice lines | ✅ (recording) | ✅ (trigger) |
| Localization swap | ❌ (data) | ✅ (per-locale switch) |
| Priority management | ❌ (data) | ✅ (queue) |

---

## 3. Catálogo unificado de sound IDs

### 3.1 Naming convention

```
<dominio>_<categoría>_<asset-base>_<variante?>
```

**Categorías canónicas:**

| Categoría | Prefijo en ID | Ejemplo |
|---|---|---|
| **Ambient** | `_amb_` | `bakery_amb_morning_quiet` |
| **FX** (puntual SFX) | `_fx_` | `retail_fx_pos_beep` |
| **Voice** (líneas voz) | `_voice_` | `retail_ped_voice_complain_queue_es_01` |
| **UI** (Tablet / interfaces) | `_ui_` | `tablet_ui_button_tap` |
| **Notif** (alertas push) | `_notif_` | `tablet_notif_admirals_default` |
| **Music** (raras, eventos especiales) | `_music_` | `admirals_music_launch_trailer` |

**Reglas:**
- snake_case obligatorio.
- Dominio explícito.
- Categoría obligatoria en ID.
- Variantes con sufijo `_v01`, `_v02`, `_v03`...
- Idiomas en sufijo voice (`_es_01`, `_en_01`).

### 3.2 Tipos técnicos

| Tipo | Uso | Formato | Tamaño típico |
|---|---|---|---|
| **One-shot SFX** | Beeps, clicks, golpes únicos | .wav 48kHz 16bit mono | 5-50 KB |
| **Loop SFX** | Compresores, motors, ambient permanente | .ogg q5 mono | 100-500 KB |
| **Ambient layer** | Atmósfera de zona | .ogg q5 stereo | 1-3 MB |
| **Voice line** | Diálogo PED | .ogg q5 mono | 50-200 KB |
| **UI sound** | Interacción Tablet | .wav 48kHz 16bit mono | 5-30 KB |
| **Notif** | Push notifications | .wav 48kHz 16bit stereo | 30-100 KB |
| **Music** | Trailers, launch, special events | .ogg q7 stereo | 3-10 MB |

### 3.3 Política de loudness

> **Target loudness:** -23 LUFS integrated por sound bank (broadcast standard).

- One-shot SFX peak: -3 dBFS max.
- Loops ambient: -28 LUFS integrated (sit beneath dialog).
- Voice lines: -16 LUFS integrated (intelligibility priority).
- UI sounds: -18 LUFS (consistent button clicks).
- Notif: -14 LUFS peak (cuts through ambient).

### 3.4 Total de sounds custom oleada 1

| Dominio | Sound IDs | Detalle |
|---|---|---|
| `farm` | ~25 | §5 |
| `mill` | ~20 | §6 |
| `bakery` | ~32 | §7 |
| `retail` | ~30 | §8 |
| `tablet` | ~25 | §9 |
| `admirals` (shared) | ~10 | §10 |
| **Total custom** | **~140 sound IDs** | |

> **Comparación:** una resource AAA típica en FiveM tiene 200-400 sound IDs custom. Admirals oleada 1 con 140 está **dentro de budget conservador**.

### 3.5 Política de variantes

- SFX recurrentes (>10 triggers/min en gameplay normal) → **mínimo 3 variantes** rotando random.
- SFX raros (<2 triggers/min) → 1 variante OK.
- Voice lines → mínimo 5 variantes por línea para evitar fatigue.
- Notif Admirals → 1 variante única (signature).

---

## 4. Categorías sonoras detalladas

### 4.1 Ambient (atmósfera por zona)

> **Ambient layers** son loops permanentes que definen el "feel" de cada zona del MLO.

**Patrón consistente:** cada nodo tiene 2-3 layers ambient (busy / quiet / specific zone).

| Patrón | Ejemplo | Loop length |
|---|---|---|
| `<nodo>_amb_busy` | `retail_amb_busy` (hora pico) | 3-5 min loop |
| `<nodo>_amb_quiet` | `bakery_amb_morning_quiet` | 3-5 min loop |
| `<nodo>_amb_<zona>` | `bakery_amb_oven_room` | 2-3 min loop |

**Code responsibility:** crossfade entre busy/quiet según hora del día + ocupación del MLO.

### 4.2 FX (puntual SFX)

> **One-shot SFX** disparados por acciones específicas. Mayor volumen del catálogo.

Patrones recurrentes:
- Maquinaria (motor start/loop/stop trio).
- Interacción objeto (pickup/place/drop).
- Estados producto (sizzle, splash, pour, knead).
- Vehicles (truck arrive, beep reverse, doors).

### 4.3 Voice (líneas PED + player feedback)

> **Voice lines** localizadas por idioma. Dispatched según contexto.

**Tipos:**
- **PED ambient chatter** — frases random PEDs en MLOs.
- **PED reaction** — respuesta a evento (cola larga, lineal vacío, promo activa).
- **NPC supplier confirmations** — bridges NPC entregando mercancía.
- **Player feedback** — confirm acciones (futuro oleada 2 con voice acting player).

**Localization tier oleada 1:** **es-ES + en-US** obligatorios. Resto idiomas (fr-FR, de-DE, pt-PT, it-IT) oleada 2.

### 4.4 UI (Tablet + interfaces in-game)

> **UI sounds** de la Admirals Tablet — botones, swipes, app open/close, scroll.

Patrón: **discrete + brand-consistent**. NO clicks genéricos. Cada UI sound suena "Admirals" (subtle brass undertone donde aplique).

### 4.5 Notif (push notifications)

> **Notif sound es el sello sonoro del ecosistema.** Cuando suena en el servidor, cualquier player con experiencia Admirals lo reconoce.

**Tier de prioridad notif:**
- **Critical** (rara): full sound + force vibration.
- **High** (frequent): full sound.
- **Medium** (default): sutil.
- **Low** (passive): NO sound, solo badge update.

### 4.6 Music (eventos especiales)

> **Música solo en:**
- Launch screen del producto.
- Trailer Tebex.
- Eventos servidor especiales (oleada 2+).
- Credits panel.
- **NUNCA in-world ambient.**

---

## 5. Sounds del nodo Farm (Granja)

> **Fuente:** `01_node_farm.md` §13 + Art Direction §9.

### 5.1 Ambient layers Farm

| Sound ID | Descripción | Loop |
|---|---|---|
| `farm_amb_morning_birds` | Mañana con pájaros + brisa suave (ideal apertura granja) | 4 min |
| `farm_amb_midday_quiet` | Día campo silencioso con grillos lejanos | 4 min |
| `farm_amb_evening_calm` | Atardecer con grillos cercanos + viento | 4 min |
| `farm_amb_storm_rain` | Tormenta lluvia fuerte (override weather) | 3 min |
| `farm_amb_warehouse_quiet` | Almacén interior con eco subtle | 3 min |

### 5.2 FX maquinaria Farm

| Sound ID | Descripción |
|---|---|
| `farm_fx_tractor_engine_start` | Tractor arrancando |
| `farm_fx_tractor_engine_loop` | Tractor motor idle/driving (loop) |
| `farm_fx_tractor_engine_stop` | Tractor apagando |
| `farm_fx_combine_harvester_start` | Cosechadora arranque |
| `farm_fx_combine_harvester_loop` | Cosechadora cosechando (loop heavy) ⭐ |
| `farm_fx_combine_harvester_stop` | Cosechadora apagando |
| `farm_fx_irrigation_pump_start` | Bomba riego arrancando |
| `farm_fx_irrigation_pump_loop` | Bomba riego activa (loop) |
| `farm_fx_water_spray` | Chorro agua riego (variantes v01-v03) |

### 5.3 FX agricultura Farm

| Sound ID | Descripción |
|---|---|
| `farm_fx_seed_pour_v01-v03` | Verter semillas (3 variantes) |
| `farm_fx_soil_till_v01-v03` | Arar tierra (3 variantes) |
| `farm_fx_wheat_cut_v01-v03` | Cortar trigo cosechadora (3 variantes) |
| `farm_fx_grain_pour_silo` | Verter grano en silo |
| `farm_fx_silo_fill_drone` | Silo llenándose drone (low-freq sutil) |
| `farm_fx_pallet_drop` | Palet dejándose en suelo |

### 5.4 Voice Farm (PEDs/player feedback)

| Sound ID | Descripción |
|---|---|
| `farm_voice_npc_supplier_arrived_es_01-03` | "Llegó camión semillas" (3 var es-ES) |
| `farm_voice_npc_supplier_arrived_en_01-03` | id en-US |

> **Total Farm: ~25 sound IDs custom oleada 1.**

---

## 6. Sounds del nodo Mill (Molino)

> **Fuente:** `03_node_mill.md` §13 + Art Direction §9.

### 6.1 Ambient layers Mill

| Sound ID | Descripción | Loop |
|---|---|---|
| `mill_amb_grinding_active` | Molino moliendo activo (low-freq drone + dust) ⭐ | 3 min |
| `mill_amb_quiet_warehouse` | Almacén silencioso con polvo suspendido | 3 min |
| `mill_amb_factory_idle` | Maquinaria apagada con tick metálico ocasional | 3 min |

### 6.2 FX maquinaria Mill

| Sound ID | Descripción |
|---|---|
| `mill_fx_stone_grinding_start` | Piedras arrancando rotación |
| `mill_fx_stone_grinding_loop` | Piedras moliendo grano (loop signature) ⭐⭐ |
| `mill_fx_stone_grinding_stop` | Piedras frenando |
| `mill_fx_belt_motor_loop` | Cinta transportadora motor (loop) |
| `mill_fx_chute_grain_flow` | Grano cayendo por tolva |
| `mill_fx_separator_active` | Separador harina/salvado vibrando |
| `mill_fx_packaging_machine_cycle` | Empaquetadora ciclo completo |
| `mill_fx_sack_seal_v01-v03` | Sellado saco harina (3 var) |

### 6.3 FX manipulación Mill

| Sound ID | Descripción |
|---|---|
| `mill_fx_sack_drop_thud_v01-v03` | Saco harina golpeando suelo (3 var) |
| `mill_fx_sack_pickup` | Coger saco harina |
| `mill_fx_pallet_truck_brass` | Transpaleta brass moviéndose |
| `mill_fx_grain_pour_to_mill` | Verter grano a molino |
| `mill_fx_dust_burst_subtle` | Estallido polvo harina sutil |

### 6.4 Voice Mill

| Sound ID | Descripción |
|---|---|
| `mill_voice_npc_quality_check_es_01-03` | Inspector calidad NPC (3 var) |

> **Total Mill: ~20 sound IDs custom oleada 1.**

---

## 7. Sounds del nodo Bakery (Panadería)

> **Fuente:** `04_node_bakery.md` §13 + Art Direction §9.

### 7.1 Ambient layers Bakery (firma sonora del nodo) ⭐

| Sound ID | Descripción | Loop |
|---|---|---|
| `bakery_amb_morning_quiet` | 4-6am pre-apertura — sutil hum oven + clock tick | 5 min |
| `bakery_amb_baking_active` | 6-9am horneado activo — fuego + vapor + crujido | 4 min |
| `bakery_amb_open_to_public` | 9am+ apertura — clientes lejanos + caja registradora | 4 min |
| `bakery_amb_oven_room_close` | Específico zona horno (proximidad) | 2 min |

### 7.2 FX horno (HERO SOUND DEL NODO) ⭐⭐⭐

| Sound ID | Descripción |
|---|---|
| `bakery_fx_oven_door_open` | Puerta horno abre (chunky brass clunk) ⭐ |
| `bakery_fx_oven_door_close` | Puerta cierra |
| `bakery_fx_oven_fire_loop` | Fuego horno activo (loop signature) ⭐⭐ |
| `bakery_fx_oven_fire_ignite` | Encendido fuego horno |
| `bakery_fx_oven_fire_extinguish` | Apagado fuego |
| `bakery_fx_oven_temperature_alarm` | Alarma sobre-temperatura |
| `bakery_fx_bread_in_oven_v01-v03` | Meter pan horno (pala) |
| `bakery_fx_bread_out_oven_v01-v03` | Sacar pan horno (pala) |
| `bakery_fx_bread_crackle_fresh` | Pan caliente crujiendo (proximidad cerca) |

### 7.3 FX masa y fermentación

| Sound ID | Descripción |
|---|---|
| `bakery_fx_mixer_start` | Mezcladora industrial arranque |
| `bakery_fx_mixer_loop` | Mezcladora amasando (loop) |
| `bakery_fx_mixer_stop` | Mezcladora frenando |
| `bakery_fx_dough_knead_v01-v03` | Amasar masa manual (3 var) |
| `bakery_fx_dough_slap_table` | Masa golpeando mesa de trabajo |
| `bakery_fx_flour_sprinkle` | Espolvorear harina sutil |
| `bakery_fx_proofing_tick` | Tick sutil cada N min de fermentación (passive) |

### 7.4 FX caja registradora brass + venta

| Sound ID | Descripción |
|---|---|
| `bakery_fx_cash_register_brass_open` | Cajón brass abre con campanita ⭐ |
| `bakery_fx_cash_register_brass_close` | Cajón cierra |
| `bakery_fx_cash_register_keys_v01-v03` | Teclas cajera registradora |
| `bakery_fx_scale_brass_place` | Colocar producto en balanza |
| `bakery_fx_paper_bag_fold` | Bolsa papel doblándose |
| `bakery_fx_receipt_print` | Impresora ticket (papel térmico) |

### 7.5 Voice Bakery (PED clientes)

| Sound ID | Descripción |
|---|---|
| `bakery_ped_voice_order_es_01-05` | Cliente pidiendo (5 var es-ES) |
| `bakery_ped_voice_order_en_01-05` | id en-US |
| `bakery_ped_voice_thanks_es_01-03` | "Gracias" cliente (3 var) |
| `bakery_ped_voice_compliment_smell_es_01-03` | "Qué bien huele" |
| `bakery_ped_voice_complain_no_bread_es_01` | "¿Sin pan otra vez?" |

> **Total Bakery: ~32 sound IDs custom oleada 1.**

---

## 8. Sounds del nodo Retail (Supermercado)

> **Fuente:** `05_node_retail.md` §13.

### 8.1 Ambient layers Retail

| Sound ID | Descripción | Loop |
|---|---|---|
| `retail_amb_busy` | Hora pico — PEDs hablando + carritos + beeps lejanos ⭐ | 5 min |
| `retail_amb_quiet` | Hora valle | 4 min |
| `retail_amb_aircon` | Aire acondicionado base toda la tienda | 5 min loop |
| `retail_amb_backroom` | Almacén con ventilación + freezer hum | 3 min |
| `retail_amb_office_quiet` | Despacho silencioso | 3 min |

### 8.2 FX POS / caja registradora (HERO SOUND DEL NODO) ⭐⭐⭐

| Sound ID | Descripción |
|---|---|
| `retail_fx_pos_beep_v01-v05` | Beep escáner producto (5 variantes — alta rotación) ⭐⭐ |
| `retail_fx_pos_belt_motor_loop` | Cinta POS moviendo (loop) |
| `retail_fx_pos_drawer_open` | Cajón POS abre |
| `retail_fx_pos_drawer_close` | Cajón cierra |
| `retail_fx_pos_print_receipt` | Impresora ticket POS |
| `retail_fx_pos_card_terminal_beep` | Terminal tarjeta confirm |
| `retail_fx_pos_cash_count_v01-v03` | Contar billetes (3 var) |
| `retail_fx_scanner_beam_active` | Beam láser scanner (sutil whine) |

### 8.3 FX flujo cliente

| Sound ID | Descripción |
|---|---|
| `retail_fx_door_chime_brass` | Campanita brass entrada cliente ⭐ |
| `retail_fx_cart_rolling_loop` | Carrito rodando (loop posicional) |
| `retail_fx_cart_pickup` | Coger carrito stack |
| `retail_fx_basket_pickup` | Coger cesta stack |
| `retail_fx_shelf_pickup_v01-v03` | Coger producto lineal (3 var) |
| `retail_fx_paper_bag_rustle_v01-v03` | Bolsa papel (3 var) |
| `retail_fx_plastic_bag_rustle_v01-v03` | Bolsa plástico (3 var) |
| `retail_fx_scale_self_print` | Balanza self-service imprime etiqueta |

### 8.4 FX neveras / climatización

| Sound ID | Descripción |
|---|---|
| `retail_fx_fridge_hum_loop` | Compresor neveras ambient (loop) ⭐ |
| `retail_fx_fridge_door_open` | Puerta nevera abre |
| `retail_fx_fridge_door_close` | Puerta cierra |

### 8.5 Voice Retail (PED clientes)

| Sound ID | Descripción |
|---|---|
| `retail_ped_voice_browse_es_01-05` | "¿Qué llevo hoy?" (5 var es-ES) |
| `retail_ped_voice_browse_en_01-05` | id en-US |
| `retail_ped_voice_complain_queue_es_01-03` | "Esta cola es eterna" |
| `retail_ped_voice_compliment_low_price_es_01` | "¡Precios increíbles!" |
| `retail_ped_voice_complain_empty_shelf_es_01` | "Otra vez sin pan..." |
| `retail_ped_voice_thank_cashier_es_01-03` | "Gracias, buen día" |

### 8.6 Notif Retail-specific

| Sound ID | Descripción |
|---|---|
| `retail_notif_low_stock` | Lineal estado crítico |
| `retail_notif_long_queue` | Cola excesiva |
| `retail_notif_supplier_arrived` | Camión proveedor en dock |
| `retail_notif_promo_active` | Promoción activada con éxito |
| `retail_notif_z_report_ready` | Z-report cierre caja listo |

> **Total Retail: ~30 sound IDs custom oleada 1.**

---

## 9. Sounds de la Admirals Tablet (UI / device)

> **Fuente:** `02_sonar_tablet.md` §13 + Art Direction §11.

### 9.1 Filosofía sonora Tablet

> **La Tablet es la interfaz universal del ecosistema** — sus UI sounds son **la firma sonora más oída del producto**. Cada UI sound debe sonar "Admirals" — sutil brass undertone donde aplique, distinto de UIs genéricas FiveM.

### 9.2 UI base Tablet

| Sound ID | Descripción |
|---|---|
| `tablet_ui_button_tap` | Tap botón estándar (subtle click + brass tail) ⭐ |
| `tablet_ui_button_tap_premium` | Botón primary action (brass click más pronunciado) |
| `tablet_ui_swipe_horizontal` | Swipe entre apps (whoosh sutil) |
| `tablet_ui_swipe_vertical` | Scroll vertical (texture roll) |
| `tablet_ui_app_open` | App abriendo (whoosh + chime corto) |
| `tablet_ui_app_close` | App cerrando (whoosh inverso) |
| `tablet_ui_keyboard_tap_v01-v03` | Tecla virtual (3 var typing) |
| `tablet_ui_toggle_on` | Switch ON (brass click positive) |
| `tablet_ui_toggle_off` | Switch OFF (brass click neutral) |
| `tablet_ui_error` | Error / acción inválida (subtle deny) |
| `tablet_ui_success` | Confirm acción exitosa (chime corto positive) |
| `tablet_ui_unlock` | Tablet unlock (brass clack + glow up) |
| `tablet_ui_lock` | Tablet lock (brass clack + dim) |

### 9.3 Notifications system (HERO SOUND DEL ECOSISTEMA) ⭐⭐⭐

> **Estos son los sonidos más oídos del producto.** Cualquier player con experiencia Admirals los reconoce instantáneamente.

| Sound ID | Descripción | Tier |
|---|---|---|
| `tablet_notif_admirals_default` | **Notif default Admirals — signature chime** ⭐⭐⭐ | Medium |
| `tablet_notif_admirals_critical` | Notif crítica (alarm subtle + brass) | Critical |
| `tablet_notif_admirals_message_in` | Mensaje entrante chat | Medium |
| `tablet_notif_admirals_payment_in` | Pago recibido Banca (chime monetary subtle) | High |
| `tablet_notif_admirals_payment_out` | Pago saliente | Medium |
| `tablet_notif_admirals_contract_signed` | Contrato firmado (brass stamp + chime) | High |
| `tablet_notif_admirals_alert_business` | Alerta empresa (low priority) | Low/Medium |
| `tablet_notif_admirals_call_ringtone_default` | Tono llamada entrante | High |

### 9.4 Sound de docking / charging

| Sound ID | Descripción |
|---|---|
| `tablet_fx_dock_in` | Tablet conectándose al dock brass (clack magnético) |
| `tablet_fx_dock_out` | Tablet desconectando del dock |
| `tablet_fx_charging_chime` | Chime sutil al empezar carga |

> **Total Tablet: ~25 sound IDs custom oleada 1.**

---

## 10. Sounds shared (`admirals_*`)

### 10.1 Brand sonora compartida

> **Sounds que aparecen en MÚLTIPLES nodos.** Especialmente notifs sistema-wide y eventos brand-related.

| Sound ID | Descripción | Uso |
|---|---|---|
| `admirals_brand_chime_signature` | **El chime de la marca** — usado en intro Tablet, splash launch, eventos brand ⭐⭐⭐ | Cross-node |
| `admirals_brand_logo_reveal` | Sound del logo apareciendo en pantalla launch | Marketing |
| `admirals_paper_stamp_official` | Sello brass oficial (firmar contrato, validar albarán) | Cross-node |
| `admirals_money_count_v01-v03` | Contar dinero efectivo (3 var) | Cross-node |
| `admirals_truck_arrive_horn` | Camión llegando (bocinazo distintivo Admirals) | Cross-node |
| `admirals_truck_engine_idle_loop` | Camión idle motor | Cross-node |
| `admirals_truck_engine_loop` | Camión driving | Cross-node |
| `admirals_logistics_unload_v01-v03` | Descargar palet de camión (3 var) | Cross-node |

> **Total shared: ~10 sound IDs.**

---

## 11. Master mix por nodo

> **El master mix** es la receta sonora completa de cada zona. Define qué layers ambient suenan + qué prioridades + qué crossfades.

### 11.1 Master mix Granja

| Hora canónica | Layers activos | Volumen relativo |
|---|---|---|
| 6-9am (mañana labor) | `farm_amb_morning_birds` + maquinaria FX según actividad | -20 LUFS |
| 9-13h (día activo) | `farm_amb_midday_quiet` + tractor loop si activo | -22 LUFS |
| 13-18h (tarde) | `farm_amb_midday_quiet` | -23 LUFS |
| 18-22h (atardecer) | `farm_amb_evening_calm` | -24 LUFS |
| 22h-6am (noche) | `farm_amb_evening_calm` con velvet attenuation | -28 LUFS |
| **Tormenta** (override) | `farm_amb_storm_rain` | -18 LUFS |

### 11.2 Master mix Molino

| Estado | Layers activos | Volumen relativo |
|---|---|---|
| **Molino activo** (grinding) | `mill_amb_grinding_active` + `mill_fx_stone_grinding_loop` | -18 LUFS |
| **Molino idle** | `mill_amb_factory_idle` | -25 LUFS |
| **Almacén perimetral** | `mill_amb_quiet_warehouse` | -26 LUFS |

### 11.3 Master mix Bakery (signature complejo) ⭐

| Hora canónica | Layers activos |
|---|---|
| **3-6am pre-work** | `bakery_amb_morning_quiet` + clock tick subtle |
| **6-9am horneado** | `bakery_amb_baking_active` + `bakery_fx_oven_fire_loop` + mixer si activo |
| **9-12h apertura B2C** | `bakery_amb_open_to_public` + cliente voices ocasionales + `bakery_fx_cash_register_brass_*` per sale |
| **12-15h hora valle** | `bakery_amb_open_to_public` quieter |
| **15-19h tarde** | `bakery_amb_open_to_public` |
| **19h+ cierre** | `bakery_amb_morning_quiet` |
| **En proximidad zona horno** | crossfade hacia `bakery_amb_oven_room_close` (radial 5m) |

### 11.4 Master mix Retail (most complex) ⭐⭐

| Hora canónica | Layers activos |
|---|---|
| **8-10am apertura suave** | `retail_amb_aircon` + `retail_amb_quiet` + door chimes ocasionales |
| **10-14h actividad media** | `retail_amb_aircon` + `retail_amb_busy` (50%) + POS beeps ocasionales + cart rolling |
| **14-19h actividad alta** | `retail_amb_aircon` + `retail_amb_busy` (80%) + POS beeps frecuentes + cart rolling múltiples |
| **19-22h hora pico** ⭐ | `retail_amb_aircon` + `retail_amb_busy` (100%) + `retail_fx_pos_beep_*` cada ~3s + multi cart rolling + voices |
| **Backroom** | `retail_amb_backroom` (separate zone) |
| **Despacho** | `retail_amb_office_quiet` |

### 11.5 Master mix Tablet UI

> **Continuous mix:** UI sounds dispatched sin layer ambient (el ambient lo provee el MLO donde el player está). Solo sonidos discrete + notifs según event triggers.

**Ducking obligatorio:** cuando UI sound o notif Tablet dispatch → ambient layer del MLO baja -6dB durante 1.5s con fade.

---

## 12. Ownership y dispatcher matrix

> **Cada sound ID tiene UN owner resource** que tiene autoridad para dispararlo. Otros resources solo emiten eventos al bus que el owner consume y traduce a sound.

### 12.1 Master ownership matrix

| Resource | Sound IDs que dispara | Eventos bus que consume |
|---|---|---|
| `admirals_farm_audio` | `farm_amb_*`, `farm_fx_*`, `farm_voice_*` | `farm:*`, `weather:*` |
| `admirals_mill_audio` | `mill_amb_*`, `mill_fx_*`, `mill_voice_*` | `mill:*` |
| `admirals_bakery_audio` | `bakery_amb_*`, `bakery_fx_*`, `bakery_ped_voice_*` | `bakery:*` |
| `admirals_retail_audio` | `retail_amb_*`, `retail_fx_*`, `retail_ped_voice_*`, `retail_notif_*` | `retail:*` |
| `sonar_tablet_audio` | `tablet_ui_*`, `tablet_notif_*`, `tablet_fx_*` | `tablet:*`, cross-domain notifs |
| `admirals_brand_audio` | `admirals_brand_*`, `admirals_paper_*`, `admirals_money_*` | `core:*`, brand events |
| `admirals_logistics_audio` | `admirals_truck_*`, `admirals_logistics_*` | `logistics:*` |

### 12.2 Reglas de dispatch

- **NUNCA hard-code play sound** desde lógica negocio. Siempre vía evento al bus → audio resource consume → dispatch sound.
- **Volume runtime override** permitido al code (atenuación distancia, ducking).
- **Sound files** SOLO añaden/modifican via Audio team — code NO toca .wav/.ogg.

### 12.3 Versioning policy

- **Sound additions** (nuevo sound ID) → minor bump del catálogo (1.0 → 1.1) — non-breaking.
- **Sound removes** → major bump — **breaking**, coordinar release.
- **Sound replacement** (mismo ID, audio mejorado) → patch bump (1.0.1) — non-breaking.

---

## 13. Performance budgets

### 13.1 Tiers de prioridad (cuando hay saturación)

| Prioridad | Categoría | Behavior si saturación |
|---|---|---|
| **P0 — Critical** | `*_notif_*_critical`, voice del player | Siempre suena, override otros |
| **P1 — High** | `tablet_notif_admirals_*`, `*_fx_pos_*`, voice acted responses | Suenan, evict P3+ |
| **P2 — Medium** | FX maquinaria, FX manipulación, ambient layers | Default tier |
| **P3 — Low** | PED voices ambient, FX subtle (proofing tick) | Evicted bajo presión |
| **P4 — Background** | Ambient distant, LFE subtle | Primero en evict |

### 13.2 Caps simultáneos

| Tipo | Cap simultáneos |
|---|---|
| Ambient layers | 3 (puede ducking entre ellos) |
| FX one-shots | 12 (priority queue cuts low) |
| Voice lines | 4 (PEDs cercanos solo) |
| UI sounds | 2 (no overlap) |
| Notif | 3 (queue if more) |
| Loops (motors, fridges) | 8 (proximity-based) |

**Total max simultáneos:** ~30 voices. **Target normal:** ~10-15 voices.

### 13.3 Atenuación 3D

> **Posicional 3D obligatorio** para todo sound diegético. Reglas:

| Tipo | Inner radius (full vol) | Outer radius (silence) |
|---|---|---|
| Voice PED | 3m | 12m |
| FX manipulación | 2m | 8m |
| FX maquinaria heavy | 5m | 25m |
| Ambient layer | full MLO | – |
| UI Tablet | non-positional (player headphones) | – |
| Notif Tablet | non-positional | – |

### 13.4 Optimization rules

- ✅ **Sound atlas / banks** — agrupar sounds del mismo dominio en banks .dat para load eficiente.
- ✅ **Streaming para ambient** loops largos (>1MB).
- ✅ **One-shots load to RAM** completamente.
- ✅ **Voice lines on-demand** load (not preloaded all locales).
- ✅ **LRU cache** para PED voices con cap size.
- ❌ **NO** loops sin fade in/out (audio glitch garantizado).
- ❌ **NO** overlapping idénticos (doblar volumen → clip).
- ❌ **NO** sounds pitch=1 sin variación (PED voices con random pitch ±5% para variedad).

---

## 14. Validation y testing protocol

### 14.1 Validation automática (CI)

> **Pre-merge checks:**

1. **Linter sound IDs:** parsea sound banks y compara con este doc. Falla si discrepancia.
2. **Loudness check:** verifica LUFS por categoría está en rango.
3. **File format:** .wav 48kHz 16bit / .ogg q5 según tipo.
4. **Naming convention:** sound IDs siguen patrón.
5. **Owner integrity:** cada sound dispatcher mapping single source.
6. **Localization completeness:** voice lines tienen es-ES Y en-US oleada 1.

### 14.2 Validation manual (pre-firmar release)

> **Antes de cada major release:**

1. **Listening session** completa por nodo en cada hora canónica del master mix.
2. **Hora pico stress test** — dispatching simultáneo todos los sounds del nodo + verificar priority queue funciona.
3. **Headphone mix verification** — el "test wooow" auditivo (§1.3).
4. **Localization validation** — voice lines suenan natural en cada idioma soportado.
5. **Volume balance** entre nodos consistente.

### 14.3 Test escenas requeridas

| Escena | Propósito |
|---|---|
| `qa_audio_farm_full_day` | Día completo Granja con ciclo ambient cambiando |
| `qa_audio_mill_grinding_session` | Molino activo + maquinaria + dust loop |
| `qa_audio_bakery_morning_to_open` | Bakery 3am → 9am (transición ambient compleja) |
| `qa_audio_retail_peak_hour` | Retail 19-22h con 8 PEDs simultáneos + 2 cajas activas |
| `qa_audio_tablet_all_notifs` | Disparar todos los notif IDs en secuencia |
| `qa_audio_priority_stress` | Saturar voice slots para verificar priority queue |

### 14.4 Tooling debug

```
/admirals_audio_inspect
```

Output:
```
Active sounds (12 voices):
  P1 retail_fx_pos_beep_v02      @ 8.2m   vol=-9dB    [POS station 2]
  P1 retail_fx_pos_beep_v04      @ 4.5m   vol=-6dB    [POS station 1]
  P2 retail_amb_busy             @ —      vol=-22LUFS [zone Z2-Z7]
  P2 retail_amb_aircon           @ —      vol=-26LUFS [global MLO]
  P2 retail_fx_fridge_hum_loop   @ 6.0m   vol=-18dB   [Z3 fridge_3]
  P2 retail_fx_cart_rolling_loop @ 12.0m  vol=-15dB   [PED cart_47]
  ...
Owner: admirals_retail_audio
Saturation: 12/30 voices (40%)
Last evicted: P3 retail_ped_voice_browse_es_03 (out of range)
```

### 14.5 Localization workflow

1. **Script canónico** redactado en es-ES (lengua base).
2. **Translation** a en-US (oleada 1) por translator profesional.
3. **Voice acting** sesión por idioma (mismo line ID, diferente locale folder).
4. **QA listening** por native speaker.
5. **Locale folder convention:**
   ```
   sounds/voice/es_ES/retail_ped_voice_browse_v01.ogg
   sounds/voice/en_US/retail_ped_voice_browse_v01.ogg
   ```
6. **Code switch** automático según `account.locale` o server default.

---

## 15. Roadmap del documento + estado

### 15.1 Roadmap

#### Oleada 1 (T-0 — incluido)
- ✅ ~140 sound IDs catalogados.
- ✅ Master mix por nodo definido.
- ✅ Naming + ownership matrix.
- ✅ Localization es-ES + en-US.
- ✅ Performance budgets + priority queue.
- ✅ Validation protocol.

#### Oleada 2 (T+6 meses)
- 🔜 +30 sound IDs nuevas verticales (Lácteos, Hortícola, Hipermercado).
- 🔜 Localization fr-FR, de-DE, pt-PT.
- 🔜 **Música ambiente opcional** para zonas premium (toggle config).
- 🔜 Voice acting profesional (oleada 1 puede usar AI-assisted, oleada 2 voice actors reales).
- 🔜 Self-checkout sound suite.

#### Oleada 3+ (T+12 meses)
- 🔜 SDK audio para third-party developers.
- 🔜 Sound marketplace Admirals.
- 🔜 Adaptive audio system (música dinámica según gameplay state).
- 🔜 Player voice integration (proximity voice in MLOs).

### 15.2 Estado del documento

- **Versión:** 1.0 (firmado — completo, 15 secciones, 2 partes publicadas).
- **Próxima revisión:** evolución cuando se añadan sounds de oleada 2 (verticales nuevas + idiomas adicionales).
- **Documentos hijos pendientes:** ninguno — terminal-leaf del subsistema audio.
- **Documentos relacionados:**
  - `art/01_art_direction.md` v1.0 — sound signatures por nodo.
  - `art/02_shader_contracts.md` v1.0 — paralelo visual de este doc.
  - `art/04_storybook_guide.md` (próximo) — UI components NUI Tablet.

### 15.3 Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 (parte 1) | 2026-05-01 | Founder + Cascade | §0-§8 (filosofía, división Audio vs Code, catálogo, Farm/Mill/Bakery/Retail sounds). |
| 1.0 (parte 2) | 2026-05-01 | Founder + Cascade | §9-§15 (Tablet, shared, master mix, ownership, performance, validation, roadmap). **Documento completo, firmable.** |

---

## Resumen ejecutivo del documento (cierre)

La **Sound Bible** consolida la promesa Pilar 3 en interfaz formal:

- **~140 sound IDs custom oleada 1** distribuidos en 6 dominios (farm/mill/bakery/retail/tablet/admirals shared).
- **Categorías canónicas** (ambient/fx/voice/ui/notif/music) con naming convention rigurosa.
- **Master mix por nodo** define la receta sonora completa por hora canónica.
- **Brand sonora compartida** — `admirals_brand_chime_signature` y `tablet_notif_admirals_default` son los hero sounds del ecosistema, reconocibles instantáneamente.
- **Localization tier 1** — es-ES + en-US obligatorios oleada 1.
- **Performance budgets** — max ~30 voices simultáneas, priority queue automática.
- **Test wooow auditivo** — un player con auriculares describe qué pasa solo escuchando 30s de un MLO.
- **Validation rigurosa** — CI checks + listening sessions + headphone mix QA.

> **El día que un player con auriculares puestos cierre los ojos en hora pico de la Panadería y oiga el horno crujiendo + la mezcladora amasando + la caja registradora abriendo + la cliente PED diciendo "qué bien huele" + el chime de la Tablet con notif del Banco — y reconozca la firma sonora Admirals sin necesitar mirar la pantalla — habrá funcionado la Sound Bible.**

---

*"El audio es el 50% de la inmersión."*

**FIN DEL DOCUMENTO `art/03_sound_bible.md` v1.0**
