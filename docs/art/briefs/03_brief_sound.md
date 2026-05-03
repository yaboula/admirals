# Brief — Sound design SONAR (5 SFX firma)

- **ID:** BRIEF-SOUND-001 v1 (post-ADR-012)
- **Versión:** v1.0 (2026-05-03)
- **Status:** 🟡 Draft firmable — pending founder green-light + sound designer assignment
- **Owner:** Founder yaboula · Sound designer TBD
- **Reviewer:** Founder (final sign-off)
- **Source SSoT:** ADR-011 + **ADR-012** + `01_art_direction.md` v2.0-scaffold-r6 NOTICE §Sound naming + `00_PRODUCT_BIBLE.md` v1.4 §1 sound signature
- **Deadline sugerido:** ~2 semanas post-kickoff (3 rondas review).
- **Dependency:** independiente (puede ejecutar paralelo a logo + icons).

---

## 1. Contexto + filosofía sonora SONAR (post-ADR-012)

**SONAR es premium-tech infrastructure.** Estilo sonoro convergente: **Apple Pro apps notification sounds + Linear UI feedback + Vercel deploy chimes + Stripe payment confirmations**. Premium, terse, calm, professional, atemporal.

**Filosofía Pilar S7 art_direction:** *"El silencio es diseño. Sound intencional. SONAR habla poco; cuando habla, importa."* Cada SFX tiene función específica, no decorativo.

**Lo que SONAR sound NO ES (post-ADR-012):**
- ❌ NO sonar ping radio submarino literal (waveform militar).
- ❌ NO hydrophone acoustic underwater literal.
- ❌ NO submarino diving alarm / klaxon / nuclear sub atmosphere.
- ❌ NO ocean/wave/whale/dolphin nature sounds (touristy/cliché).
- ❌ NO RGB gamer notification sounds (jangle, sting electrónico saturated).
- ❌ NO Material Design generic chimes (genéricos).
- ❌ NO casino/slot-machine win sounds.

**Lo que SONAR sound ES:**
- ✅ Premium-tech UI feedback (Apple/Linear/Vercel/Stripe class).
- ✅ Terse — ≤500ms cada SFX (excepto signal_emerge notif que puede llegar 800ms).
- ✅ Tonal, no noisy — armónicos cuidados, NO crackle/static/distortion.
- ✅ Bass presence sutil para signature gravitas (sin booming sub-bass gaming).
- ✅ High-end clarity (premium feel).
- ✅ Atemporal — debe sobrevivir 5+ años sin refresh.

---

## 2. Los 5 SFX firma (canonical post-ADR-012)

| # | Nombre canonical | Función UI | Trigger en producto |
|---|---|---|---|
| 1 | **`signal_emerge`** | Notification primary | Push notification, new message, eco transactional received, manifiesto firmado entrante |
| 2 | **`depth_press`** | Confirmación / firma | CTA primary press, manifiesto signed, transferencia confirmed, contract sealed |
| 3 | **`layer_dive`** | Escritura UI / submit | Form submit, save action, drill-down navigation, layer transition |
| 4 | **`console_tap`** | Premium click feedback | Button click standard, tab switch, item select (más sutil que `depth_press`) |
| 5 | **`panel_open`** | Modal / drawer open | Modal aparece, drawer slide-in, notification panel reveal |

> **Importante:** estos nombres reemplazan los v1 deprecated (`sonar_ping`/`sonar_pressure`/`sonar_depth`/`sonar_console`/`sonar_hatch`) que tenían connotación submarino-acústica literal.

### 2.1 SFX especificación per-sound

#### `signal_emerge` (notif primaria)
- **Duración:** 400-800ms (puede llegar 800ms para presencia notif).
- **Tonalidad:** mid-tone clarity con leve pitch-rise (sugiere "algo emergiendo a la superficie").
- **Carácter:** confident, calmo, NOT urgent. Como Slack notification pero más premium.
- **Anti-patterns:** ❌ NO ping radio waveform, NO ding-dong genérico, NO bell.
- **Refs convergentes:** Apple Mail "new mail" (premium tonal), Vercel deploy success chime, Stripe payment received.

#### `depth_press` (firma/confirm)
- **Duración:** 200-400ms.
- **Tonalidad:** low-mid press con weight, leve "settle" decay (sugiere "peso descendiendo confirmado").
- **Carácter:** authoritative, decisive, premium gravitas.
- **Anti-patterns:** ❌ NO booming sub-bass gaming, NO weapon foley.
- **Refs convergentes:** Apple Touch ID success, Stripe Connect "payment authorized" confirmation, Linear "task completed".

#### `layer_dive` (escritura UI)
- **Duración:** 150-300ms.
- **Tonalidad:** quick mid-tone descent suave (sugiere "moviéndose a la siguiente capa").
- **Carácter:** smooth, transitional, frictionless.
- **Anti-patterns:** ❌ NO swoosh wind/water literal, NO sci-fi laser whoosh.
- **Refs convergentes:** Notion page transition, Linear navigation between projects, Arc browser space switch.

#### `console_tap` (premium click)
- **Duración:** 50-150ms.
- **Tonalidad:** brief high-mid click con leve "pop" tonal.
- **Carácter:** crisp, precise, satisfying — más sutil que `depth_press`.
- **Anti-patterns:** ❌ NO mechanical keyboard generic, NO mouse click foley.
- **Refs convergentes:** Apple Magic Trackpad haptic-equivalent sound, Vercel UI button feedback, Stripe Dashboard tab tap.

#### `panel_open` (modal)
- **Duración:** 200-400ms.
- **Tonalidad:** soft rise + breath-like reveal (sugiere "panel emerging").
- **Carácter:** welcoming, smooth, premium.
- **Anti-patterns:** ❌ NO door creak, NO submarino hatch foley, NO spring-loaded mechanism.
- **Refs convergentes:** Apple notification center reveal, Linear command palette open, Vercel dialog open.

---

## 3. Deliverables exactos

### 3.1 Archivos finales (por SFX)

| # | Archivo | Formato | Notas |
|---|---|---|---|
| 1 | `signal_emerge.wav` | WAV 48kHz/24-bit stereo | Master uncompressed |
| 2 | `signal_emerge.ogg` | OGG Vorbis Q6 (~96-128kbps) | FiveM in-game playback |
| 3 | `signal_emerge.mp3` | MP3 320kbps | Web hero, marketing |
| ...repeat para los 5 SFX | | | |

**Total archivos audio:** 5 SFX × 3 formatos = **15 audio files**.

### 3.2 Package entregables adicionales

| # | Archivo | Formato | Uso |
|---|---|---|---|
| 1 | `sonar_sounds_session.{ableton,logic,reaper,reason}` | DAW session source | Editable source para iteración futura |
| 2 | `sonar_sounds_guidelines.pdf` | PDF 6-10 páginas | Specs + waveform diagrams + LUFS levels + use cases per SFX |
| 3 | `sonar_sounds_showcase.mp4` | Video demo 30s | Cada SFX triggered en context UI mockup |
| 4 | `sonar_sounds_bibliography.md` | Markdown | Refs convergentes + samples licensing chain + tools used |

**Repo destino:** `art/sound/sonar_sounds_v1/` (Phase 8 code refactor para resources/sonar_tablet/sounds/).

### 3.3 Specs técnicos audio

- **Sample rate:** 48kHz master (entrega WAV) + 44.1kHz auto-conversion para web.
- **Bit depth:** 24-bit master.
- **Channel:** stereo (mono donde proceda — `console_tap` puede ser mono).
- **Loudness normalization:** -15 LUFS integrated (per ADR-012 spec) ±0.5dB tolerance.
- **True peak:** ≤ -1.0 dBTP (avoid clipping cross-platform).
- **Dynamic range:** moderado — NO over-compressed, NO over-dynamic.
- **Headroom:** mínimo 1.5dB headroom each SFX.
- **Frequency balance:** verifica per-SFX que no hay mud (200-400Hz buildup) ni harshness (2-4kHz spike).

---

## 4. Bibliography + samples licensing

### 4.1 Source material strategy

Sound designer puede:

**Opción A — Synthesis pure (preferido):**
- Composición desde cero usando synths (analog modeled o digital pure).
- Source: Serum, Vital, Pigments, Diva, Massive X, Operator, etc.
- **Ventaja:** zero licensing risk, full IP.

**Opción B — Sample layering (acceptable con licensing chain documented):**
- Usar samples de packs comerciales con licencia commercial use.
- **Packs aceptable refs:** Splice subscriptions, Output sample packs, Sample Magic, Loopmasters (todos con royalty-free clearance commercial).
- **Anti:** sound design libraries con restrictions personal-only o per-project licensing trickery.

**Opción C — Field recording (NOT recommended):**
- Grabar sonidos físicos reales (clicks, taps).
- Riesgo IP cleanliness + post-processing complexity.

### 4.2 Licensing chain documentation (obligatorio)

Designer entrega **`sonar_sounds_bibliography.md`** con:
- Cada SFX → método (synth pure / sample layered / field recorded).
- Si sample layered: pack name + license type + license URL + clearance commercial confirm.
- Tools used (DAW + plugins).
- **Cesión total IP a yaboula/SONAR** post-delivery — designer NO retiene exclusive rights.

---

## 5. Do ✅ / Don't ❌

### 5.1 ✅ Hacer

- Crear los 5 SFX en una **session sonora coherente** (mismos tools + signature tonal + character family).
- Validar -15 LUFS integrated cross-SFX (consistency loudness).
- Test cada SFX en **3 contextos:** (a) headphones premium (Sennheiser HD600 class), (b) laptop speakers MacBook, (c) phone speaker iPhone — debe leer paridad y character preserved.
- Test integration mockup: video 30s con UI mockup Tablet SONAR triggering los 5 SFX en context (entregado como `sonar_sounds_showcase.mp4`).
- Documentar bibliography + licensing chain explícito.
- Entregar source DAW session editable para futuro tweaking.

### 5.2 ❌ No hacer

- ❌ Sonar ping submarine waveform literal.
- ❌ Hydrophone underwater acoustic literal.
- ❌ Diving klaxon / submarine alarm / nuclear sub atmosphere.
- ❌ Ocean wave / whale / dolphin / nature ambient.
- ❌ RGB gamer jangle / sting electrónico saturated.
- ❌ Casino win / slot machine / coin drop.
- ❌ Material Design generic chimes (genéricos).
- ❌ Door creak / submarine hatch / mechanical foley literal.
- ❌ Sci-fi laser / lightsaber / spaceship FX.
- ❌ Voice samples (no human vocals incluso whispers).
- ❌ Crackle / static / distortion artifacts.
- ❌ Booming sub-bass gaming-style.
- ❌ Reverb tail demasiado largo (>1s — tail-cut clean).

---

## 6. Referencias sonoras (estudiar obsesivamente)

### 6.1 Convergir (premium-tech UI sound class)

- **Apple Pro apps:** Final Cut export complete, Logic Pro punch-in, Mail new message premium.
- **Linear:** task complete, project switch, command palette feedback.
- **Vercel:** deploy success chime, build complete, dashboard transitions.
- **Stripe:** payment confirmed, dashboard tab feedback, Connect signup flow.
- **Notion:** page transition, comment received, drag-drop snap.
- **Arc Browser:** space switch, command palette, profile change.

### 6.2 Inspiración tonal abstracta (NO copiar literal)

- Modular synthesis tonal sequences (Mutable Instruments aesthetic).
- Ambient producer SFX (Brian Eno generative, Tycho transitions).
- Premium product UI sound (Apple HomePod feedback, Tesla UI sounds — NOT car-specific).

### 6.3 Anti-referencias (NO copiar)

- ❌ **Hunt: Showdown** atmospheric / military.
- ❌ **Call of Duty / Battlefield** UI sounds (military).
- ❌ **Gaming RGB peripherals** sound libraries.
- ❌ **Submarine documentaries / war movies** sonar/sub atmosphere.
- ❌ **iOS default ringtones** (genéricos).
- ❌ **Windows / Android system sounds.**

**Bibliography moodboard:** designer entrega `sonar_sounds_bibliography.md` con timestamps específicos en refs convergentes (ej. *"Apple Mail new mail @ 0:00-0:01 — convergent character for `signal_emerge`"*).

---

## 7. Proceso review (gates)

| Ronda | Deliverable | Founder review | Outcome |
|---|---|---|---|
| **R0 — Kickoff** | Bibliography moodboard + cuestionario dudas + tools confirmation | Sync 30 min | Green-light dirección |
| **R1 — Sketches** | 5 SFX rough drafts (1-2 takes per SFX) MP3 + LUFS measured | Async 48h | Ajustes per-SFX + lock direction tonal |
| **R2 — Refinamiento** | 5 SFX refined + showcase mockup video draft + bibliography draft | Async 48h | Ajustes finos + sign-off carácter |
| **R3 — Delivery** | Package completo (15 audio files + DAW session + guidelines PDF + showcase MP4 + bibliography MD) | Sync 30 min | Sign-off final |

---

## 8. Licensing + entrega

- **Cesión rights:** full transfer of all IP rights + copyrights to yaboula / SONAR. Unlimited perpetual worldwide commercial use, including derivative works + game integration + marketing.
- **Sample chain clearance:** designer asegura zero residual licensing claims (especialmente Opción B sample layering).
- **NDA:** Sound confidential hasta reveal oficial SONAR.
- **Attribution:** designer accreditable en credits SONAR website + trailer (opcional).
- **Source files:** DAW session + plugins state preserved entregable.

---

## 9. Presupuesto + timeline

- **Scope sound designer:** mid-senior UI sound designer specialized premium-tech, 30-50 horas totales 2 semanas.
- **Presupuesto orientativo:** €1,500-€3,500 EUR freelance EU. 2-3 quotes antes contratar.
- **Specialty:** preferencia sound designer con portfolio premium-tech apps (NO gaming-only background, NO film foley-only).
- **Alternativa AI:** Suno / ElevenLabs sound effects (limited quality 2026). Recomendado humano para premium UI feedback.

---

## 10. Checklist founder pre-kickoff

- [ ] Re-read ADR-012 + art_direction r6 NOTICE §Sound naming.
- [ ] Los 5 nombres locked: `signal_emerge`, `depth_press`, `layer_dive`, `console_tap`, `panel_open`.
- [ ] Filosofía S7 "silencio es diseño" enforced.
- [ ] LUFS -15 target confirmed.
- [ ] Bibliography + licensing chain transparency obligatorio.
- [ ] Presupuesto asignado.
- [ ] Sound designer contratado con portfolio premium-tech matching.
- [ ] Deadline R3 firm.

---

## 11. Changelog

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| v1.0 | 2026-05-03 | Cascade (Sonnet 4.5) | Initial brief — 5 SFX firma post-ADR-012: `signal_emerge`/`depth_press`/`layer_dive`/`console_tap`/`panel_open`. NO submarine/sonar-radio/military literal. Refs convergentes Apple/Linear/Vercel/Stripe premium-tech UI. |

---

**FIN DEL BRIEF — SOUND SONAR v1 (post-ADR-012)**
