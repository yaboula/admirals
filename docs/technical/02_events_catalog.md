# 📡 SONAR — Catálogo de Eventos `sonar:*` (post-Phase-8) / `sonar:*` (pre-Phase-8 legacy)

> **Versión:** 1.2 (post Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical post S1.10.x). **SSoT vigente** — filosofía + schemas + audit/throttle policies + tipos (state/command/push/callback) + naming conventions + tier system + RFC governance sin cambios foundational (pivot-agnostic). Event prefix `sonar:*` scheduled rename `sonar:*` Phase 8 per ADR-013.
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.4 (post-pivot)
> **Documento técnico padre:** `01_architecture.md` v1.0 (§5 define la arquitectura del bus).
> **ADRs relacionados:** ADR-011 (pivot) + ADR-012 (refinement) + **ADR-013 (namespace migration Phase 8+9 scheduled)**.
> **Estado:** firmado.

> **Lectura previa obligatoria:** `agents/00_BOOTSTRAP.md` v1.5, `01_architecture.md` §5 (Bus de eventos) y §10 (Tablet técnica), **`planning/02_decision_log.md` ADR-013** (event prefix migration execution), **`planning/01_roadmap.md` v1.5** (Phase 8+9 scheduled + Sprint 2 DIFERIDO).

---


## 0. Resumen ejecutivo

Este documento es **la referencia oficial de todos los eventos del bus `sonar:*` (pre-Phase-8) / `sonar:*` (post-Phase-8 per ADR-013)** que viven en el ecosistema SONAR.

Cada evento es un **contrato firmado** entre quien lo emite y quien lo escucha. Romper un contrato es un **breaking change** (bump MAJOR del resource emisor — ver `01_architecture.md` §18).

Este doc cubre:

- **Filosofía y convenciones** que todos los eventos siguen.
- **Schemas formales de payload** con tipos, validaciones y rangos.
- **Dirección de emisión** (server↔server, server↔client, client→server).
- **Suscriptores típicos** y side effects.
- **Reglas de audit, throttling y rate limiting.**
- **Ejemplos de payload** reales para developers y tests.

> **Cualquier evento del bus que un desarrollador use en código DEBE estar registrado aquí.** Si no está, no existe.

---

## 1. Filosofía y convenciones

### 1.1 Principios

| # | Principio | Significado práctico |
|---|---|---|
| **E1** | **Naming inmutable** | El nombre de un evento jamás se renombra. Si cambia su semántica, se crea un evento nuevo y se deprecia el viejo. |
| **E2** | **Payload tipado** | Todo evento tiene schema. Validación en `Bus.Publish` rechaza payloads malformados. |
| **E3** | **Eventos en pasado** | El nombre describe lo que **ya pasó** (`harvest_completed`, no `complete_harvest`). Los `command` events son la excepción. |
| **E4** | **Idempotencia donde aplique** | Un mismo evento puede emitirse 2 veces (red, retry) — los suscriptores deben ser idempotentes cuando hay riesgo. |
| **E5** | **Sin lógica de negocio en el evento** | El evento describe un hecho. La lógica vive en el suscriptor. |
| **E6** | **Audit por defecto en eventos críticos** | Mutaciones de dinero, contratos, empresas, calidad → siempre logueados en `sonar_event_log`. |
| **E7** | **Throttling explícito** | Eventos high-frequency (`growth_tick`, `state_change`) declaran su throttle aquí. |
| **E8** | **Versionado del schema por evento** | Cada schema tiene `schema_version`. Si cambia, el catálogo lo refleja con changelog del evento. |

### 1.2 Convención de naming (recordatorio)

```
sonar:<dominio>:<acción>
```

- 3 partes, snake_case.
- `dominio` = subsistema (`core`, `tablet`, `bank`) o nodo (`granja`, `molino`).
- `acción` = qué pasó / qué se solicita.
- **Verbo en pasado** para state events (`account_logged_in`, `harvest_completed`).
- **Verbo en imperativo** para command events (`transfer_requested`, `harvest_start`).

### 1.3 Tipología de eventos

> **Reproducimos la tabla del `01_architecture.md` §5.3 con detalle adicional.**

| Tipo | Descripción | Patrón típico | Audit default |
|---|---|---|---|
| **State** | "Esto pasó." Hecho consumado. Pasado. | server → server (+ broadcast a clientes interesados) | Siempre |
| **Command** | "Quiero hacer X." Intent del cliente. Server valida. | client → server | No (loguea solo failures) |
| **Push** | Notificación dirigida a un cliente concreto. | server → client (target) | No (es output) |
| **Callback** | Request → response síncrono. | client ↔ server (con `lib.callback`) | No (loguea solo errores) |

### 1.4 Estructura canónica de un payload

Todo payload SONAR incluye **siempre** estos campos meta cuando aplica:

```ts
{
  // Campos de tracing (gestionados por Bus.Publish — no manuales)
  _event_name: string,           // 'sonar:granja:harvest_completed'
  _event_id: string,             // UUID v4 único de esta emisión
  _emitted_at: number,           // unix timestamp ms
  _schema_version: number,       // versión del schema del evento

  // Campos del evento (definidos por evento)
  // ...
}
```

Los campos `_event_*` son **automáticos** — los añade `Bus.Publish` en `sonar_core`. Los handlers nunca los emiten manualmente.

### 1.5 Plantilla de especificación de evento

> **Toda entrada en este catálogo sigue este formato.** Si un developer añade un evento nuevo, crea entry con esta plantilla.

```
### sonar:<dominio>:<acción>

**Tipo:** state | command | push | callback
**Dirección:** server→server | client→server | server→client(target) | server→clients(broadcast)
**Emisor canónico:** <resource>(s)
**Suscriptores típicos:** <resource>(s)
**Audit:** always | configurable | never
**Throttle:** none | <interval_ms> per <key>
**Schema version:** N

**Payload:**
```ts
{
  field: type,        // descripción + restricciones
  ...
}
```

**Side effects:**
- Bullet del efecto.

**Ejemplo:**
```json
{ ... }
```

**Notas:** opcional.
**Eventos relacionados:** opcional.
```

### 1.6 Tipos canónicos (TypeScript-equivalent en spec)

Para mantener concisión usamos estos tipos en los schemas:

| Tipo SONAR | Definición | Validación |
|---|---|---|
| `AccountId` | UUID v4 | regex UUID v4 |
| `CompanyId` | UUID v4 | regex UUID v4 |
| `TabletSerial` | UUID v4 | regex UUID v4 |
| `BankAccountId` | UUID v4 | regex UUID v4 |
| `IBAN` | string | regex `^AD-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$` |
| `BatchId` | string | regex `^(FARM|MILL|BAKE|RETAIL)-\d{4}-\d{4}-[A-Z]$` |
| `Vertical` | enum | `'farm' \| 'mill' \| 'bakery' \| 'retail' \| 'logistics' \| ...` |
| `Role` | enum | `'owner' \| 'manager' \| 'employee' \| 'temporary'` |
| `Grade` | enum | `'S' \| 'A' \| 'B' \| 'C' \| 'D'` |
| `Score` | int | 0-100 |
| `Money` | decimal | >=0, max 10^9 |
| `Coords` | `{x:f, y:f, z:f, heading?:f}` | finite numbers |
| `UnixSec` | int | >=0 |
| `UnixMs` | int | >=0 |

---

## 2. Catálogo — Dominio `core`

> **Eventos del corazón del ecosistema.** Identidad, empresas genéricas, estado global, reputación.

### 2.1 sonar:core:account_logged_in

**Tipo:** state
**Dirección:** server→server (+ broadcast targeted a la propia src del jugador)
**Emisor canónico:** `sonar_core` (vía bridge framework)
**Suscriptores típicos:** `sonar_tablet` (login UI), todos los nodos (cargar empresas del jugador)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  src: number,           // server id (player slot)
  account_id: AccountId,
  char_id: string,       // citizenid QBox / identifier ESX
  alias: string,
  source: 'qbox' | 'qbcore' | 'esx' | 'manual',
}
```

**Side effects:**
- Tablet client carga sesión del jugador.
- Nodos pre-cargan companies a las que pertenece.
- Notificaciones pendientes se entregan.

**Ejemplo:**
```json
{
  "src": 23,
  "account_id": "1f2c8b3a-9e4d-4f00-a77b-12c3aabbccdd",
  "char_id": "QBX-456789",
  "alias": "Marcos Vega",
  "source": "qbox"
}
```

---

### 2.2 sonar:core:account_logged_out

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** todos los resources (limpiar caches por jugador, persistir estado pendiente)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  char_id: string,
  reason: 'disconnect' | 'kick' | 'ban' | 'character_switch',
}
```

**Side effects:**
- Repos hacen flush forzado de cache de ese jugador.
- Tablet renderizada se libera (rendertarget).
- Logs de sesión cerrada.

---

### 2.3 sonar:core:company_created

**Tipo:** state
**Dirección:** server→server (+ push al owner)
**Emisor canónico:** `sonar_core` (al confirmar creación)
**Suscriptores típicos:** `sonar_tablet` (refrescar app Empresa), nodo correspondiente al `vertical` (provisión de assets/parcelas/etc.)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  vertical: Vertical,
  name: string,
  owner_account_id: AccountId,
  hq_location: Coords,
  bank_account_id: BankAccountId,
  iban: IBAN,
  founded_at: UnixSec,
}
```

**Side effects:**
- Granja: si `vertical === 'farm'`, inicializa parcelas y silos según config del map.
- Tablet: añade la empresa a la app Empresa del owner. Crea chat empresarial (`sonar:messages:chat_created`).
- Banca: cuenta empresarial activada con saldo inicial 0.
- Documents: certificado de constitución generado (`sonar:documents:created` type='company_deed').

**Ejemplo:**
```json
{
  "company_id": "9c3e1a4b-...",
  "vertical": "farm",
  "name": "Granja del Valle",
  "owner_account_id": "1f2c8b3a-...",
  "hq_location": { "x": 2120.5, "y": 4798.2, "z": 41.0, "heading": 90 },
  "bank_account_id": "...",
  "iban": "AD-A1B2-C3D4-E5F6",
  "founded_at": 1730000000
}
```

---

### 2.4 sonar:core:company_member_added

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet` (refrescar Empresa app), nodo del vertical (asignar permisos físicos en MLO)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  account_id: AccountId,
  role: Role,
  position: string | null,    // 'maquinista', 'tendero', etc.
  salary: Money,
  added_by_account_id: AccountId,
  hired_at: UnixSec,
}
```

**Side effects:**
- Tablet del nuevo miembro: empresa aparece en app Empresa.
- Nodo: si rol concede acceso a zonas físicas, se actualizan permissions in-world.
- Mensaje empresarial automático: *"<alias> se ha unido a <company>".*

---

### 2.5 sonar:core:company_member_removed

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet`, nodo del vertical
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  account_id: AccountId,
  reason: 'fired' | 'resigned' | 'temporary_completed' | 'banned',
  removed_by_account_id: AccountId | null,    // null si automático
  removed_at: UnixSec,
}
```

**Side effects:**
- Acceso físico al MLO de la empresa revocado para ese account.
- Tareas asignadas pendientes se reasignan o cancelan.
- Última nómina se calcula y paga (si reason !== 'banned').

---

### 2.6 sonar:core:company_member_role_changed

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet`, nodo del vertical
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  account_id: AccountId,
  old_role: Role,
  new_role: Role,
  old_position: string | null,
  new_position: string | null,
  changed_by_account_id: AccountId,
  changed_at: UnixSec,
}
```

**Side effects:**
- Permisos in-world actualizados.
- Tablet refresca app Empresa del miembro.
- Notificación push al miembro.

---

### 2.7 sonar:core:company_status_changed

**Tipo:** state
**Dirección:** server→server (+ broadcast a Mercado si público)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet`, nodos relacionados, `sonar_market`
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  old_status: 'active' | 'suspended' | 'bankrupt' | 'sold',
  new_status: 'active' | 'suspended' | 'bankrupt' | 'sold',
  reason: string,
  changed_at: UnixSec,
}
```

**Side effects:**
- Si `bankrupt`: contratos B2B activos se anotan como impagados, miembros notificados, NPC de administración entra a actuar.
- Si `sold`: nuevo owner toma posesión, miembros existentes notificados.
- Mercado actualiza listado público.

---

### 2.8 sonar:core:reputation_changed

**Tipo:** state
**Dirección:** server→server (+ push al sujeto)
**Emisor canónico:** cualquier resource (vía API `Reputation.Apply`)
**Suscriptores típicos:** `sonar_tablet` (notif si cambio significativo), `sonar_market` (re-rankear)
**Audit:** always (con razón)
**Throttle:** debounce 5s por sujeto + razón (anti-spam)
**Schema version:** 1

**Payload:**
```ts
{
  subject_kind: 'account' | 'company',
  subject_id: AccountId | CompanyId,
  delta: number,                  // -10..+10 típicamente, max ±20
  new_value: number,              // 0-100
  reason_code: string,            // 'contract_fulfilled', 'contract_breached', 'good_review', etc.
  reason_text: string | null,
  source_resource: string,
  occurred_at: UnixSec,
}
```

**Side effects:**
- Si `new_value` cruza umbral (50, 75, 90, 95): notif "Subiste a Premium Vendor".
- Mercado: re-rankea ofertas del sujeto.
- Contratos: algunos exigen reputación mínima; si cae bajo umbral, se renegocian.

**Notas:** la lógica de cálculo del `delta` vive en el resource emisor según contexto. Este evento solo informa el resultado.

---

### 2.9 sonar:core:state_change

**Tipo:** state (genérico — usar solo cuando no haya evento más específico)
**Dirección:** server→server (+ broadcast targeted)
**Emisor canónico:** cualquier resource
**Suscriptores típicos:** `sonar_tablet` (refrescar UI activa)
**Audit:** never (alto volumen)
**Throttle:** debounce 500ms por entidad
**Schema version:** 1

**Payload:**
```ts
{
  entity_kind: 'plot' | 'silo' | 'sack' | 'vehicle' | 'machine' | 'pallet' | 'company' | string,
  entity_id: string,
  fields_changed: string[],       // nombre de campos que cambiaron
  preview: Record<string, unknown> | null,  // snapshot mínimo opcional
  source_resource: string,
}
```

**Side effects:**
- Tablet refresca paneles que dependen de esa entidad.

**Notas:** **úsalo con moderación.** Preferir eventos específicos del dominio. Sirve como fallback para refrescos UI sin proliferar eventos.

---

## 3. Catálogo — Dominio `tablet`

> **Eventos del dispositivo Tablet.** Hardware, OS, apps, docking.

### 3.1 sonar:tablet:opened

**Tipo:** state
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet` (cliente)
**Suscriptores típicos:** `sonar_core` (analytics, métricas)
**Audit:** never
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  tablet_serial: TabletSerial,
  opened_at: UnixSec,
  context: 'foot' | 'vehicle' | 'office',
}
```

---

### 3.2 sonar:tablet:closed

**Tipo:** state
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** `sonar_core` (analytics)
**Audit:** never
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  tablet_serial: TabletSerial,
  closed_at: UnixSec,
  duration_ms: number,
}
```

---

### 3.3 sonar:tablet:dock_in

**Tipo:** state
**Dirección:** client→server (+ push back al cliente con ack)
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** `sonar_tablet` (server-side: expandir UI a monitor), nodo del lugar (despacho de empresa)
**Audit:** configurable
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  tablet_serial: TabletSerial,
  dock_id: string,                // identificador del dock físico
  dock_kind: 'basic' | 'pro' | 'enterprise',
  company_id: CompanyId | null,   // si el dock está en sede de una empresa
  docked_at: UnixSec,
}
```

**Side effects:**
- Monitor se enciende.
- UI Tablet redimensiona al layout expanded.
- Audio de docking se reproduce.

---

### 3.4 sonar:tablet:dock_out

**Tipo:** state
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** `sonar_tablet` (server-side)
**Audit:** never
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  tablet_serial: TabletSerial,
  dock_id: string,
  undocked_at: UnixSec,
  duration_ms: number,
}
```

---

### 3.5 sonar:tablet:notification_pushed

**Tipo:** push
**Dirección:** server→client (target)
**Emisor canónico:** cualquier resource (vía API `Notif.Push`)
**Suscriptores típicos:** `sonar_tablet` (cliente — render UI)
**Audit:** always (loguea quién pushó qué a quién)
**Throttle:** rate limit per (account_id, source_resource): max 30/min
**Schema version:** 1

**Payload:**
```ts
{
  notif_id: number,                  // BIGINT auto-increment
  account_id: AccountId,             // destinatario
  type: 'critical_op' | 'critical_fin' | 'important' | 'info' | 'fin_pos' | 'contract' | 'message' | 'weather' | 'system' | 'market' | 'logistics' | 'reputation',
  source_resource: string,
  title: string,                     // max 64 chars
  subtitle: string | null,           // max 128 chars
  body: string | null,               // max 500 chars
  actions: Array<{
    label: string,
    action_id: string,                // dispatched cuando user pulsa el botón
    params: Record<string, unknown>,
  }> | null,
  related_doc_id: string | null,
  delivery_mode: 'push_popup' | 'banner_inferior' | 'panel_only' | 'blocking',
  pushed_at: UnixSec,
}
```

**Side effects:**
- Banner pop-up aparece en la Tablet (si abierta).
- Vibración del modelo Tablet (si guardada).
- Sonido específico por `type`.
- Entry en `sonar_notifications` tabla.

**Ejemplo:**
```json
{
  "notif_id": 5821,
  "account_id": "1f2c8b3a-...",
  "type": "critical_op",
  "source_resource": "sonar_granja",
  "title": "Plaga detectada",
  "subtitle": "Parcela hortícola 3",
  "body": "Pulgón. Daño estimado 30% si no se trata en 24h.",
  "actions": [
    { "label": "Tratar ahora", "action_id": "sonar:granja:open_treatment_ui", "params": { "plot_id": "..." } },
    { "label": "Ver detalle", "action_id": "sonar:tablet:open_app", "params": { "app_id": "farmer_manager_panel", "view": "operations.plot_3" } }
  ],
  "delivery_mode": "push_popup",
  "pushed_at": 1730000000
}
```

---

### 3.6 sonar:tablet:notification_read

**Tipo:** state
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** `sonar_core`
**Audit:** never
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  notif_id: number,
  read_at: UnixSec,
}
```

**Side effects:**
- `sonar_notifications.read = true, read_at = ?` para esa fila.
- Badge count en home decrementa.

---

### 3.7 sonar:tablet:app_action_performed

**Tipo:** command (genérico para apps registradas)
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet` (cuando una app dispara intent)
**Suscriptores típicos:** resource dueño de la app
**Audit:** configurable por app
**Throttle:** rate limit per (account_id, app_id, action): max 60/min
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  app_id: string,                  // 'farmer_manager_panel', etc.
  action: string,                  // 'start_irrigation', 'pay_salaries_now', etc.
  params: Record<string, unknown>,
  performed_at: UnixSec,
}
```

**Side effects:**
- Resource dueño de la app procesa según `action`.

**Notas:** este es el catch-all que las apps registradas dinámicamente usan. Resources individuales pueden tener eventos específicos para acciones críticas.

---

### 3.8 sonar:tablet:app_registered

**Tipo:** state
**Dirección:** server→client (broadcast a tablets activas)
**Emisor canónico:** `sonar_tablet` (server) cuando un resource llama `RegisterApp`
**Suscriptores típicos:** `sonar_tablet` (NUI) — añade icono al home
**Audit:** never
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  app_id: string,
  name_key: string,                // i18n key
  icon_url: string,
  vertical: Vertical | string,
  permissions_required: string[],
  component_url: string,           // URL al bundle JS
  schema_version: number,
  publisher: string,               // 'SONAR' | 'Studio externo'
}
```

---

### 3.9 sonar:tablet:settings_updated

**Tipo:** state
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** `sonar_tablet` (server: persist), `sonar_core` (preferencias en cuenta)
**Audit:** never
**Throttle:** debounce 1s per account
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  tablet_serial: TabletSerial,
  changes: {
    wallpaper?: string,
    theme?: 'auto' | 'light' | 'dark',
    accent_color?: string,
    privacy_screen?: boolean,
    pin_set?: boolean,
    locale?: string,
    ringtone_default?: string,
    ringtones_per_contact?: Record<string, string>,
    notifications_per_app?: Record<string, { enabled: boolean, priority: 'low'|'normal'|'high' }>,
    home_layout?: { columns: number, app_order: string[], widgets: string[] },
  },
  updated_at: UnixSec,
}
```

---

### 3.10 sonar:tablet:lost_or_stolen

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_tablet` (oleada 2 — al activar mecánica de robo)
**Suscriptores típicos:** `sonar_core`, propio Tablet (cliente para deslogar)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  tablet_serial: TabletSerial,
  previous_owner_account_id: AccountId,
  reason: 'lost' | 'stolen',
  reported_at: UnixSec,
}
```

**Side effects:**
- Tablet se marca `is_lost = true` en DB.
- Si jugador la usa: pide login (acceso solo si tiene su cuenta).
- Owner anterior: notif "Tu Tablet fue reportada como perdida/robada".

---

## 4. Catálogo — Dominio `bank`

> **Eventos bancarios.** Cuentas, transferencias, movimientos, salarios.

### 4.1 sonar:bank:account_created

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet` (refrescar Banca app)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  bank_account_id: BankAccountId,
  iban: IBAN,
  type: 'personal' | 'company' | 'cooperative',
  owner_id: AccountId | CompanyId,
  initial_balance: Money,
  created_at: UnixSec,
}
```

---

### 4.2 sonar:bank:transfer_requested

**Tipo:** command
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet` (NUI)
**Suscriptores típicos:** `sonar_core` (handler bancario)
**Audit:** loguea solo failures
**Throttle:** rate limit per account: 5/min
**Schema version:** 1

**Payload:**
```ts
{
  requester_account_id: AccountId,
  from_iban: IBAN,
  to_iban: IBAN,
  amount: Money,                   // > 0, max 10^7
  concept: string,                 // max 100 chars
  request_nonce: string,           // UUID v4 — anti-replay
}
```

**Side effects:**
- Server valida (8 pasos — ver `01_architecture.md` §16.3).
- Si OK: emite `transfer_completed`.
- Si KO: emite `transfer_failed`.

---

### 4.3 sonar:bank:transfer_completed

**Tipo:** state
**Dirección:** server→server (+ push targeted ambos extremos)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet` (notif moneda + actualizar balance), `sonar_documents` (generar recibo automático)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  movement_id_from: number,
  movement_id_to: number,
  from_iban: IBAN,
  to_iban: IBAN,
  amount: Money,
  concept: string,
  category: 'salary' | 'b2b_payment' | 'transfer' | 'tax' | 'refund' | 'b2c_sale' | 'other',
  related_doc_id: string | null,
  requester_account_id: AccountId,
  occurred_at: UnixSec,
}
```

**Side effects:**
- 2 entries en `sonar_bank_movements` (debe + haber).
- Recibo PDF auto-creado en `sonar_documents`.
- Notif "Pago recibido" al destinatario, "Pago realizado" al emisor.
- Reputación: si `category === 'b2b_payment'` y on-time, bump leve a ambas partes.

---

### 4.4 sonar:bank:transfer_failed

**Tipo:** state
**Dirección:** server→client(target)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet` (mensaje error)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  requester_account_id: AccountId,
  from_iban: IBAN,
  to_iban: IBAN,
  amount: Money,
  reason: 'insufficient_funds' | 'unknown_destination' | 'unauthorized' | 'rate_limited' | 'invalid_amount' | 'replay_detected' | 'system_error',
  details: string | null,
  occurred_at: UnixSec,
}
```

---

### 4.5 sonar:bank:salary_paid

**Tipo:** state
**Dirección:** server→server (+ push al miembro)
**Emisor canónico:** `sonar_core` (cron salary_tick)
**Suscriptores típicos:** `sonar_tablet` (notif moneda)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  member_account_id: AccountId,
  movement_id: number,
  amount: Money,
  shift_label: string,             // 'turno_2026-04-30_morning'
  paid_at: UnixSec,
}
```

---

### 4.6 sonar:bank:salary_failed

**Tipo:** state
**Dirección:** server→server (+ push al owner de la company)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet` (notif crítica financiera al owner)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  member_account_id: AccountId,
  amount_owed: Money,
  reason: 'insufficient_funds',
  occurred_at: UnixSec,
}
```

**Side effects:**
- Notif crítica al owner: "Caja insuficiente para pagar nóminas".
- Trigger de evaluación de quiebra si reincidente.

---

### 4.7 sonar:bank:cashbox_opened

**Tipo:** state
**Dirección:** client→server (+ ack al cliente)
**Emisor canónico:** `sonar_tablet` (cliente, al interactuar con prop caja)
**Suscriptores típicos:** `sonar_core`, nodo del vertical (UI mínima de caja)
**Audit:** always
**Throttle:** rate limit per (account, company): 10/min
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  company_id: CompanyId,
  cashbox_location: Coords,
  opened_at: UnixSec,
}
```

**Side effects:**
- Validación física (proximidad ped ↔ prop caja).
- Validación permiso `open_cash_box`.
- UI cliente abre con balance + 20 movimientos recientes.

---

### 4.8 sonar:bank:cashbox_movement

**Tipo:** state
**Dirección:** server→server (+ push al actor)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet`, nodo del vertical
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  amount: Money,                   // positivo depósito, negativo retiro
  new_cash_balance: Money,
  by_account_id: AccountId,
  reason: 'deposit' | 'withdrawal' | 'b2c_sale' | 'expense',
  related_doc_id: string | null,
  occurred_at: UnixSec,
}
```

---

## 5. Catálogo — Dominio `notifications` (gestión interna)

> **Eventos del subsistema de notificaciones.** Complementan `sonar:tablet:notification_pushed` con eventos de gestión.

### 5.1 sonar:notifications:bulk_archived

**Tipo:** state
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** `sonar_core`
**Audit:** never
**Throttle:** rate limit per account: 5/min
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  notif_ids: number[],             // hasta 200 por llamada
  archived_at: UnixSec,
}
```

---

### 5.2 sonar:notifications:action_invoked

**Tipo:** command
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** resource declarado por la action
**Audit:** loguea
**Throttle:** rate limit per (account, action_id): 30/min
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  notif_id: number,
  action_id: string,               // ej. 'sonar:granja:open_treatment_ui'
  params: Record<string, unknown>, // los que venían en la notif
  invoked_at: UnixSec,
}
```

**Side effects:**
- Resource correspondiente ejecuta la acción.
- Notif se marca leída.

---

### 5.3 sonar:notifications:preferences_updated

**Tipo:** state
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet` (Settings app)
**Suscriptores típicos:** `sonar_core`
**Audit:** never
**Throttle:** debounce 2s per account
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  preferences: Record<string, {
    enabled: boolean,
    priority: 'low' | 'normal' | 'high',
    delivery_mode_override: 'push_popup' | 'banner_inferior' | 'panel_only' | null,
  }>,                              // key: type de notif
  updated_at: UnixSec,
}
```

---

## 6. Catálogo — Dominio `documents`

> **Eventos del repositorio documental.** Notas, contratos, albaranes, recibos, certificados.

### 6.1 sonar:documents:created

**Tipo:** state
**Dirección:** server→server (+ push targeted)
**Emisor canónico:** `sonar_core` (al crear cualquier documento)
**Suscriptores típicos:** `sonar_tablet` (refrescar Notas&Contratos), partes implicadas
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  doc_id: string,
  type: 'note' | 'contract' | 'delivery_note' | 'receipt' | 'license' | 'company_deed' | 'bill_of_sale',
  owner_account_id: AccountId | null,
  company_id: CompanyId | null,
  title: string,
  status: 'draft' | 'pending_signature' | 'active' | 'fulfilled' | 'breached' | 'archived',
  parties: AccountId[] | CompanyId[],   // partes implicadas (si contrato)
  parent_doc_id: string | null,
  created_by_account_id: AccountId,
  created_at: UnixSec,
}
```

**Side effects:**
- Notif al owner / partes.
- Si `type === 'license'` y obtenida tras curso: certificado válido para sistema correspondiente.

---

### 6.2 sonar:documents:signature_requested

**Tipo:** command
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** `sonar_core`
**Audit:** loguea
**Throttle:** rate limit per account: 30/min
**Schema version:** 1

**Payload:**
```ts
{
  doc_id: string,
  signer_account_id: AccountId,
  signature_data: {
    method: 'typed' | 'drawn' | 'biometric',
    visual_ref: string,            // imagen base64 si drawn, name si typed
  },
  signed_at: UnixSec,
}
```

---

### 6.3 sonar:documents:signed

**Tipo:** state
**Dirección:** server→server (+ push a las partes)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet`, resources interesados (ej. `sonar_logistics` cuando es albarán)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  doc_id: string,
  signer_account_id: AccountId,
  signed_at: UnixSec,
  all_parties_signed: boolean,
  status_after: 'pending_signature' | 'active',
}
```

**Side effects:**
- Si `all_parties_signed === true`: status pasa a `active`. Documento se vuelve **inmutable**.
- Notif a las otras partes.
- Si docking activo + impresora: imprime físicamente en mundo (anim impresora).

---

### 6.4 sonar:documents:status_changed

**Tipo:** state
**Dirección:** server→server (+ push a las partes)
**Emisor canónico:** cualquier resource (vía API)
**Suscriptores típicos:** `sonar_tablet`, partes implicadas
**Audit:** always (especial para `breached`)
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  doc_id: string,
  old_status: 'draft' | 'pending_signature' | 'active' | 'fulfilled' | 'breached' | 'archived',
  new_status: 'draft' | 'pending_signature' | 'active' | 'fulfilled' | 'breached' | 'archived',
  reason_code: string | null,
  reason_text: string | null,
  changed_by: AccountId | 'system',
  changed_at: UnixSec,
}
```

**Side effects:**
- Si `breached`: notif crítica a las partes, reputación negativa al incumplidor, posible escalada legal RP (oleada 3 — notaría).
- Si `fulfilled`: reputación positiva a las partes, contrato archivable.

---

### 6.5 sonar:documents:shared

**Tipo:** state
**Dirección:** server→server (+ push al receptor)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** never
**Throttle:** rate limit per account: 30/min
**Schema version:** 1

**Payload:**
```ts
{
  doc_id: string,
  from_account_id: AccountId,
  to_account_id: AccountId,
  shared_via: 'message' | 'inter_tablet' | 'email_sim',
  shared_at: UnixSec,
}
```

---

### 6.6 sonar:documents:printed

**Tipo:** state
**Dirección:** server→server (+ push al cliente para anim impresora)
**Emisor canónico:** `sonar_tablet` o cualquier resource al imprimir físicamente
**Suscriptores típicos:** cliente Lua del jugador con dock activo
**Audit:** never
**Throttle:** rate limit per account: 20/min
**Schema version:** 1

**Payload:**
```ts
{
  doc_id: string,
  printed_by_account_id: AccountId,
  printer_location: Coords,
  pages: number,
  printed_at: UnixSec,
}
```

**Side effects:**
- Anim impresora física (motor + papel saliendo).
- Sonido de impresora.
- Prop "documento impreso" generado opcional (item físico — oleada 2).

---

## 7. Catálogo — Dominio `messages`

> **Eventos de mensajería.** Chats 1-1, grupales, canales empresariales.

### 7.1 sonar:messages:chat_created

**Tipo:** state
**Dirección:** server→server (+ push a participantes)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** never
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  chat_id: string,
  type: 'direct' | 'group' | 'company_channel',
  participants: AccountId[],
  company_id: CompanyId | null,    // si type='company_channel'
  metadata: {
    name?: string,
    icon_url?: string,
  } | null,
  created_by_account_id: AccountId,
  created_at: UnixSec,
}
```

---

### 7.2 sonar:messages:sent

**Tipo:** state
**Dirección:** server→server (+ push targeted a participantes online)
**Emisor canónico:** `sonar_core` (vía intent client)
**Suscriptores típicos:** `sonar_tablet` (cliente — render mensaje)
**Audit:** never (alto volumen)
**Throttle:** rate limit per account: 60/min
**Schema version:** 1

**Payload:**
```ts
{
  message_id: number,              // BIGINT
  chat_id: string,
  sender_id: AccountId | CompanyId,
  sender_kind: 'account' | 'company',
  body: string,                    // max 2000 chars
  attachments: Array<{
    kind: 'document' | 'photo' | 'location' | 'voice',
    ref: string,                   // doc_id, image_url, coords json, voice_clip_url
    metadata: Record<string, unknown>,
  }> | null,
  sent_at: UnixSec,
}
```

**Side effects:**
- Notif tipo `message` a participantes que no estén con el chat abierto.
- Sonido pop si chat abierto.

---

### 7.3 sonar:messages:read

**Tipo:** state
**Dirección:** client→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** `sonar_core`, `sonar_tablet` (broadcast a otros participantes — read receipts)
**Audit:** never
**Throttle:** debounce 1s per (account, chat)
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  chat_id: string,
  last_read_message_id: number,
  read_at: UnixSec,
}
```

---

### 7.4 sonar:messages:typing

**Tipo:** push (efímero — no persistente)
**Dirección:** client→server→clients
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** participantes del chat
**Audit:** never
**Throttle:** debounce 2s per (account, chat)
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  chat_id: string,
  is_typing: boolean,
}
```

**Notas:** efímero, no entra en `sonar_event_log`.

---

### 7.5 sonar:messages:deleted

**Tipo:** state
**Dirección:** server→server (+ push a participantes)
**Emisor canónico:** `sonar_core`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** rate limit per account: 20/min
**Schema version:** 1

**Payload:**
```ts
{
  message_id: number,
  chat_id: string,
  deleted_by_account_id: AccountId,
  deleted_at: UnixSec,
}
```

**Side effects:**
- Mensaje queda como "mensaje eliminado" placeholder (soft-delete).
- No se borra de DB para auditoría.

---

### 7.6 sonar:messages:voice_recorded (oleada 2)

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** participantes del chat
**Audit:** never
**Throttle:** rate limit per account: 30/min
**Schema version:** 1

**Payload:**
```ts
{
  voice_clip_id: string,
  chat_id: string,
  sender_account_id: AccountId,
  duration_ms: number,             // max 60000 (1 min) en O2
  storage_ref: string,             // ref a archivo de audio
  recorded_at: UnixSec,
}
```

---

### 7.7 sonar:messages:call_initiated (oleada 2)

**Tipo:** push
**Dirección:** server→client (target)
**Emisor canónico:** `sonar_tablet`
**Suscriptores típicos:** Tablet del receptor
**Audit:** loguea
**Throttle:** rate limit per (caller, callee): 5/min
**Schema version:** 1

**Payload:**
```ts
{
  call_id: string,
  caller_account_id: AccountId,
  callee_account_id: AccountId,
  via: 'pma_voice',
  initiated_at: UnixSec,
}
```

**Side effects:**
- Ringtone en Tablet del callee.
- Vibración + UI llamada entrante.

---

### 7.8 sonar:messages:call_state_changed (oleada 2)

**Tipo:** state
**Dirección:** server→server (+ push a ambos extremos)
**Emisor canónico:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  call_id: string,
  state: 'ringing' | 'answered' | 'declined' | 'missed' | 'ended',
  duration_ms: number | null,      // si ended
  ended_by: AccountId | null,
  occurred_at: UnixSec,
}
```

---

## 8. Catálogo — Dominio `market`

> **Eventos del marketplace.** Trabajos temporales, productos a la venta, servicios, empresas en venta.

### 8.1 sonar:market:offer_published

**Tipo:** state
**Dirección:** server→server (+ broadcast a tablets con preferencias matching)
**Emisor canónico:** `sonar_market`
**Suscriptores típicos:** `sonar_tablet` (push notif a interesados, refrescar app Mercado)
**Audit:** loguea
**Throttle:** rate limit per publisher: 30/h
**Schema version:** 1

**Payload:**
```ts
{
  offer_id: string,
  type: 'temp_job' | 'product' | 'service' | 'company_sale',
  publisher_id: AccountId | CompanyId,
  publisher_kind: 'account' | 'company',
  title: string,
  description: string | null,
  data: Record<string, unknown>,    // estructura libre por type
  price: Money | null,
  location: Coords | null,
  expires_at: UnixSec | null,
  published_at: UnixSec,
}
```

**Side effects:**
- Notif tipo `market` a usuarios con prefs matching (geolocalización + categoría).
- Mercado refresca listings.

**Ejemplo (temp_job):**
```json
{
  "offer_id": "...",
  "type": "temp_job",
  "publisher_id": "9c3e1a4b-...",
  "publisher_kind": "company",
  "title": "Cosechar parcela hortícola 2",
  "description": "Cosecha de tomate premium. Estimado 30 min.",
  "data": {
    "estimated_minutes": 30,
    "vertical": "farm",
    "task_kind": "harvest",
    "plot_id": "plot_3"
  },
  "price": 500,
  "location": { "x": 2120.5, "y": 4798.2, "z": 41.0 },
  "expires_at": 1730003600,
  "published_at": 1730000000
}
```

---

### 8.2 sonar:market:offer_accepted

**Tipo:** state
**Dirección:** server→server (+ push a publisher)
**Emisor canónico:** `sonar_market`
**Suscriptores típicos:** `sonar_tablet`, resource del vertical correspondiente (provisión de acceso físico)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  offer_id: string,
  accepted_by_account_id: AccountId,
  accepted_at: UnixSec,
  expected_completion_at: UnixSec | null,
}
```

**Side effects:**
- Si `temp_job`: provisiona acceso temporal a la zona física en MLO.
- Notif al publisher: "<alias> aceptó tu oferta".
- Notif al aceptante: dirección + descripción.

---

### 8.3 sonar:market:offer_completed

**Tipo:** state
**Dirección:** server→server (+ push a ambas partes)
**Emisor canónico:** resource del vertical correspondiente (al verificar cumplimiento)
**Suscriptores típicos:** `sonar_market`, `sonar_core` (reputación), `sonar_bank` (pago)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  offer_id: string,
  accepted_by_account_id: AccountId,
  publisher_id: AccountId | CompanyId,
  outcome: 'success' | 'partial' | 'failed',
  outcome_details: string | null,
  completed_at: UnixSec,
}
```

**Side effects:**
- Si `success`: pago automático (`bank:transfer_requested` interno) + reputación +1 a ambas partes.
- Si `partial`: pago proporcional + reputación neutra.
- Si `failed`: sin pago + reputación -2 al aceptante.
- Acceso temporal revocado.

---

### 8.4 sonar:market:offer_cancelled

**Tipo:** state
**Dirección:** server→server (+ push a interesados)
**Emisor canónico:** `sonar_market`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  offer_id: string,
  cancelled_by: AccountId | 'system',
  reason: string,
  cancelled_at: UnixSec,
}
```

---

### 8.5 sonar:market:offer_expired

**Tipo:** state
**Dirección:** server→server (+ push al publisher)
**Emisor canónico:** `sonar_market` (cron de expiración)
**Suscriptores típicos:** `sonar_tablet`
**Audit:** never
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  offer_id: string,
  expired_at: UnixSec,
}
```

---

### 8.6 sonar:market:product_purchased

**Tipo:** state
**Dirección:** server→server (+ push a comprador y vendedor)
**Emisor canónico:** `sonar_market`
**Suscriptores típicos:** `sonar_tablet`, `sonar_logistics` (si entrega), `sonar_bank` (pago)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  offer_id: string,
  buyer_id: AccountId | CompanyId,
  buyer_kind: 'account' | 'company',
  seller_id: AccountId | CompanyId,
  seller_kind: 'account' | 'company',
  quantity: number,
  unit_price: Money,
  total_amount: Money,
  delivery_mode: 'pickup' | 'delivery_via_logistics',
  logistics_job_id: string | null,
  purchased_at: UnixSec,
}
```

**Side effects:**
- Pago automático (con holding si delivery — se libera al confirmar entrega).
- Si delivery_mode = 'delivery_via_logistics': crea `logistics_job`.
- Reserva el producto físico (lote/saco) en almacén origen.

---

### 8.7 sonar:market:reputation_review_posted

**Tipo:** state
**Dirección:** server→server (+ push al sujeto)
**Emisor canónico:** `sonar_market`
**Suscriptores típicos:** `sonar_core` (aplicar delta), `sonar_tablet`
**Audit:** always
**Throttle:** rate limit per (reviewer, subject): 1/24h
**Schema version:** 1

**Payload:**
```ts
{
  review_id: string,
  reviewer_id: AccountId | CompanyId,
  subject_id: AccountId | CompanyId,
  rating: 1 | 2 | 3 | 4 | 5,
  comment: string | null,           // max 500 chars
  related_offer_id: string | null,
  posted_at: UnixSec,
}
```

**Side effects:**
- Reputación: delta calculado según rating (rating 5 = +2, rating 1 = -3, etc.).
- Reseña visible en perfil público del sujeto en Mercado.

---

## 9. Catálogo — Dominio `logistics`

> **Eventos de transporte y entregas.** Crear envío, en ruta, entregar, firmar.

### 9.1 sonar:logistics:job_created

**Tipo:** state
**Dirección:** server→server (+ push a partes interesadas)
**Emisor canónico:** `sonar_logistics`
**Suscriptores típicos:** `sonar_tablet` (refrescar app Logística), nodos origen y destino
**Audit:** always
**Throttle:** rate limit per company: 60/h
**Schema version:** 1

**Payload:**
```ts
{
  job_id: string,
  origin_id: CompanyId,
  destination_id: CompanyId,
  carrier_id: AccountId | CompanyId | null,    // null si pendiente asignar
  carrier_kind: 'account' | 'company' | null,
  vehicle_plate: string | null,
  cargo: Array<{
    item_kind: string,
    quantity: number,
    batch_id: BatchId,
    quality_grade: Grade,
    weight_kg: number,
  }>,
  estimated_distance_km: number,
  estimated_price: Money,
  scheduled_at: UnixSec | null,
  delivery_note_id: string | null,
  created_by_account_id: AccountId,
  created_at: UnixSec,
}
```

**Side effects:**
- Albarán de envío auto-generado (`sonar:documents:created` type='delivery_note').
- Si docking + impresora del origen: imprime físicamente.
- Notif al destino: "Envío recibido para aceptación".

---

### 9.2 sonar:logistics:job_started

**Tipo:** state
**Dirección:** server→server (+ push)
**Emisor canónico:** `sonar_logistics`
**Suscriptores típicos:** `sonar_tablet` (tracking activo en mapa)
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  job_id: string,
  carrier_id: AccountId | CompanyId,
  vehicle_plate: string,
  started_at: UnixSec,
  origin_coords: Coords,
  expected_delivery_at: UnixSec,
}
```

**Side effects:**
- Tracking GPS comienza.
- Cargo se marca "en tránsito" — bloqueado en almacén origen.

---

### 9.3 sonar:logistics:job_position_updated

**Tipo:** push
**Dirección:** server→clients(targeted: partes interesadas en tracking)
**Emisor canónico:** `sonar_logistics` (cliente del transportista emite, server forwardea)
**Suscriptores típicos:** Tablets de origen, destino, carrier
**Audit:** never (alto volumen)
**Throttle:** debounce 5s per job
**Schema version:** 1

**Payload:**
```ts
{
  job_id: string,
  current_position: Coords,
  speed_kmh: number,
  eta_seconds: number,
  cargo_health: 'ok' | 'warning' | 'damaged',     // refrigerado: temp; impacto vehículo: damaged
  reported_at: UnixMs,
}
```

---

### 9.4 sonar:logistics:job_delivered

**Tipo:** state
**Dirección:** server→server (+ push a partes)
**Emisor canónico:** `sonar_logistics`
**Suscriptores típicos:** nodo destino (recibir cargo en silo/almacén), `sonar_bank` (liberar pago en holding), `sonar_core` (reputación)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  job_id: string,
  carrier_id: AccountId | CompanyId,
  delivered_at: UnixSec,
  receiver_signature_doc_id: string,    // doc firma cliente
  cargo_received: Array<{
    item_kind: string,
    quantity: number,
    quality_grade: Grade,
    quality_score: Score,
    batch_id: BatchId,
  }>,
  discrepancies: Array<{
    kind: 'quantity' | 'quality' | 'damage',
    notes: string,
  }> | null,
}
```

**Side effects:**
- Albarán firmado (`sonar:documents:signed`).
- Cargo entra al almacén destino.
- Pago al carrier liberado.
- Reputación: +1 al carrier si sin discrepancias; -2 si discrepancias.

---

### 9.5 sonar:logistics:job_disputed

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_logistics` (cuando alguna parte reporta issue)
**Suscriptores típicos:** `sonar_tablet` (notif crítica), administración NPC (oleada 2)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  job_id: string,
  raised_by_account_id: AccountId,
  reason: 'cargo_damaged' | 'quantity_mismatch' | 'late' | 'wrong_destination' | 'other',
  evidence: {
    photos: string[] | null,
    notes: string | null,
  },
  raised_at: UnixSec,
}
```

**Side effects:**
- Pago en holding hasta resolver.
- Notif a las 3 partes: origen + destino + carrier.
- Reputación congelada hasta resolución.

---

### 9.6 sonar:logistics:job_cancelled

**Tipo:** state
**Dirección:** server→server (+ push)
**Emisor canónico:** `sonar_logistics`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  job_id: string,
  cancelled_by_account_id: AccountId,
  reason: string,
  cancelled_at: UnixSec,
  refund_issued: boolean,
}
```

---

### 9.7 sonar:logistics:carrier_assigned

**Tipo:** state
**Dirección:** server→server (+ push al carrier asignado)
**Emisor canónico:** `sonar_logistics`
**Suscriptores típicos:** `sonar_tablet` (notif al carrier)
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  job_id: string,
  carrier_id: AccountId | CompanyId,
  carrier_kind: 'account' | 'company',
  vehicle_plate: string,
  assigned_at: UnixSec,
}
```

---

## 10. Catálogo — Dominio `granja`

> **Eventos del nodo Granja SONAR.** Ciclo agrícola completo. Ver `01_node_farm.md` para semántica de gameplay.

### 10.1 sonar:granja:plot_prepared

**Tipo:** state
**Dirección:** server→server (+ broadcast a Tablets de la company)
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet` (Manager Panel — refresh Operations)
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  prepared_by_account_id: AccountId,
  preparation_kind: 'plowed' | 'tilled' | 'amended',
  fuel_used_l: number,
  prepared_at: UnixSec,
}
```

---

### 10.2 sonar:granja:plot_seeded

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`, `sonar_granja` interno (cron de crecimiento)
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  crop_id: string,                  // 'wheat_soft' | 'tomato' | etc.
  variant: 'common' | 'premium',
  seeded_by_account_id: AccountId,
  seed_quantity_kg: number,
  seed_quality_grade: Grade,
  seed_quality_score: Score,
  seeder_machine_id: string | null, // null si manual
  expected_stages: number,
  expected_harvest_at: UnixSec,
  seeded_at: UnixSec,
}
```

**Side effects:**
- Plot pasa a stage 1 (germinación).
- Cron de crecimiento programa progresión.
- Notif al manager: "Sembrado completado".

---

### 10.3 sonar:granja:plot_irrigated

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  by_account_id: AccountId,
  water_kg: number,
  source: 'manual' | 'sprinkler' | 'pivot' | 'cistern_truck',
  cost: Money,
  irrigation_score_delta: number,    // afecta calidad final
  irrigated_at: UnixSec,
}
```

---

### 10.4 sonar:granja:plot_fertilized

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  by_account_id: AccountId,
  fertilizer_kind: 'organic' | 'chemical_npk' | 'compost' | 'premium',
  quantity_kg: number,
  cost: Money,
  fertilization_score_delta: number,
  fertilized_at: UnixSec,
}
```

---

### 10.5 sonar:granja:pest_detected

**Tipo:** state
**Dirección:** server→server (+ push notif crítica al manager)
**Emisor canónico:** `sonar_granja` (cron pest random + drone monitoring O3)
**Suscriptores típicos:** `sonar_tablet`
**Audit:** always
**Throttle:** none (raro)
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  pest_kind: 'aphid' | 'mildew' | 'rust' | 'beetle' | 'other',
  severity: 'low' | 'medium' | 'high',
  detection_source: 'manual_inspection' | 'auto_check' | 'drone_monitor',
  estimated_damage_pct: number,    // si no se trata
  treatment_window_hours: number,
  detected_at: UnixSec,
}
```

**Side effects:**
- Notif crítica al manager con acciones rápidas (`Tratar ahora` / `Ver detalle`).
- Plot.pest_control_score se desliza si no se trata.

---

### 10.6 sonar:granja:pest_treated

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  pest_kind: string,
  treatment_kind: 'manual_pesticide' | 'sprayer' | 'drone_fumigator',
  product_used: string,
  by_account_id: AccountId,
  cost: Money,
  effectiveness_pct: number,        // 0-100
  pest_control_score_delta: number,
  treated_at: UnixSec,
}
```

---

### 10.7 sonar:granja:plot_growth_tick

**Tipo:** state (interno — no broadcast a clientes)
**Dirección:** server→server
**Emisor canónico:** `sonar_granja` (cron interno, agregado)
**Suscriptores típicos:** `sonar_granja` (sí mismo — actualizar stages)
**Audit:** never (alto volumen)
**Throttle:** debounce 5min per plot
**Schema version:** 1

**Payload:**
```ts
{
  ticks: Array<{
    plot_id: string,
    new_stage: number,
    growth_pct: number,            // 0-100 dentro del stage actual
    visual_state: string,          // 'sprouting' | 'leafing' | 'flowering' | etc.
  }>,
  ticked_at: UnixSec,
}
```

**Notas:** evento agregado para reducir volumen del bus. **No** se broadcastea a clientes — el visual change se sincroniza vía `state_change` cuando hay clientes en zona.

---

### 10.8 sonar:granja:harvest_started

**Tipo:** state
**Dirección:** server→server (+ broadcast a la company)
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  harvester_machine_id: string,     // 'combine_1', 'manual', 'forklift_lifter'
  by_account_id: AccountId,
  expected_kg: number,
  expected_quality_grade: Grade,
  started_at: UnixSec,
}
```

---

### 10.9 sonar:granja:harvest_completed

**Tipo:** state
**Dirección:** server→server (+ broadcast a la company)
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`, `sonar_core` (reputación si calidad alta)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  batch_id: BatchId,
  crop_id: string,
  variant: 'common' | 'premium',
  kg_harvested: number,
  quality: {
    grade: Grade,
    score: Score,
    components: Record<string, Score>,
  },
  by_account_id: AccountId,
  destination_silo_id: string | null,    // si auto-cargado
  completed_at: UnixSec,
}
```

**Side effects:**
- Si quality.score >= 90 (S): reputación +1 al granjero y empresa.
- Si destination_silo_id presente: emite `silo_filled` a continuación.
- Notif al manager: "Cosecha completada — Calidad <grade>".
- Plot vuelve a stage 0 (vacío).

---

### 10.10 sonar:granja:silo_filled

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  silo_id: string,
  kg_added: number,
  new_total_kg: number,
  capacity_pct: number,             // 0-100
  batch_ids_aggregated: BatchId[],
  added_at: UnixSec,
}
```

**Side effects:**
- Shader del silo refresca nivel.
- Si capacity_pct >= 90: notif "Silo casi lleno".
- Si capacity_pct >= 100: notif crítica + bloqueo de nuevo input.

---

### 10.11 sonar:granja:silo_emptied

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`, `sonar_logistics` (si destino es transporte)
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  silo_id: string,
  kg_removed: number,
  new_total_kg: number,
  destination: 'truck' | 'mill_direct' | 'discard',
  destination_ref: string | null,   // logistics_job_id o company_id receiver
  batch_ids_consumed: BatchId[],
  emptied_at: UnixSec,
}
```

---

### 10.12 sonar:granja:weather_event

**Tipo:** state
**Dirección:** server→server (+ broadcast a granjas en area)
**Emisor canónico:** `sonar_granja` (gestor de clima del nodo)
**Suscriptores típicos:** `sonar_tablet` (notif weather), plots afectados (recálculo weather_score)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  event_kind: 'rain' | 'storm' | 'hail' | 'drought' | 'frost' | 'heatwave',
  severity: 'mild' | 'moderate' | 'severe',
  area: 'global' | 'paleto' | 'grapeseed' | 'sandy_shores',
  affected_plot_ids: string[],
  starts_at: UnixSec,
  ends_at: UnixSec,
  damage_pct_estimated: number,     // si severity > moderate
  weather_score_delta: number,      // afecta calidad final
}
```

**Side effects:**
- Notif weather a managers de granjas afectadas.
- Si hail con severity severe + plot sin malla protectora: emite `harvest_loss`.
- Plot.weather_score actualizado.

---

### 10.13 sonar:granja:harvest_loss

**Tipo:** state
**Dirección:** server→server (+ push crítico al manager)
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  plot_id: string,
  loss_kind: 'hail' | 'pest_uncontrolled' | 'drought' | 'frost' | 'flood',
  kg_lost: number,
  estimated_revenue_lost: Money,
  occurred_at: UnixSec,
}
```

---

### 10.14 sonar:granja:machine_failed

**Tipo:** state
**Dirección:** server→server (+ push crítico al manager)
**Emisor canónico:** `sonar_granja`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  machine_id: string,
  machine_kind: 'tractor' | 'harvester' | 'sprayer' | 'irrigator' | 'sower' | 'forklift',
  failure_kind: 'mechanical' | 'fuel_empty' | 'damage' | 'maintenance_due',
  estimated_repair_cost: Money,
  estimated_repair_minutes: number,
  failed_at: UnixSec,
}
```

---

### 10.15 sonar:granja:machine_repaired

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_granja`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  machine_id: string,
  repaired_by: AccountId | 'mechanic_npc' | 'sonar_mechanic_company',
  cost: Money,
  parts_used: string[],
  duration_minutes: number,
  repaired_at: UnixSec,
}
```

---

### 10.16 sonar:granja:season_changed

**Tipo:** state
**Dirección:** server→server (+ broadcast a todas las granjas)
**Emisor canónico:** `sonar_granja` (gestor de calendario)
**Audit:** always
**Throttle:** none (1 evento por cambio)
**Schema version:** 1

**Payload:**
```ts
{
  old_season: 'spring' | 'summer' | 'autumn' | 'winter',
  new_season: 'spring' | 'summer' | 'autumn' | 'winter',
  duration_mode: 'sprint' | 'default' | 'realista' | 'hardcore',
  changed_at: UnixSec,
}
```

**Side effects:**
- Cultivos pueden quedar fuera de ventana óptima (penalización calidad).
- Notif a managers: "Estación cambió a <season>".
- Visual ambiente del MLO cambia.

---

### 10.17 sonar:granja:license_obtained

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_granja` (al completar mini-curso)
**Suscriptores típicos:** `sonar_core` (registrar certificado en `sonar_documents`), `sonar_tablet`
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  account_id: AccountId,
  license_kind: 'driving_basic' | 'driving_agricultural' | 'driving_harvester' | 'driving_transport' | 'pesticide_handling' | 'fumigation_drone',
  cost: Money,
  obtained_at: UnixSec,
  expires_at: UnixSec | null,
}
```

---

### 10.18 sonar:granja:compost_ready (oleada 2)

**Tipo:** state
**Dirección:** server→server
**Audit:** loguea
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  composter_id: string,
  kg_compost: number,
  quality_grade: Grade,
  ready_at: UnixSec,
}
```

---

### 10.19 sonar:granja:drone_dispatched (oleada 3)

**Tipo:** state
**Dirección:** server→server
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  drone_id: string,
  mission_kind: 'fumigation' | 'monitoring' | 'precision_seeding',
  target_plot_ids: string[],
  pilot_account_id: AccountId,
  dispatched_at: UnixSec,
  expected_completion_at: UnixSec,
}
```

---

### 10.20 sonar:granja:drone_returned (oleada 3)

**Tipo:** state
**Dirección:** server→server
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  drone_id: string,
  mission_outcome: 'success' | 'partial' | 'aborted' | 'crashed',
  data_collected: {                 // si monitoring
    photos: string[] | null,
    pest_alerts: Array<{ plot_id: string, pest_kind: string, severity: string }> | null,
  } | null,
  returned_at: UnixSec,
}
```

---

## 11. Catálogo — Dominio `molino`

> **Eventos del nodo Molino SONAR.** Ver `03_node_mill.md` para semántica.

### 11.1 sonar:molino:grain_received

**Tipo:** state
**Dirección:** server→server (+ push al supplier)
**Emisor canónico:** `sonar_molino`
**Suscriptores típicos:** `sonar_tablet`, `sonar_bank` (disparar pago si contrato), `sonar_logistics` (cerrar job)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,           // mill recibiendo
  from_company_id: CompanyId,      // farm origen
  logistics_job_id: string | null,
  weight_in: number,               // peso bruto báscula entrada
  weight_out: number,              // peso bruto báscula salida (camión vacío)
  net_weight_kg: number,           // diferencia
  inspection_passed: boolean,
  rejection_reason: string | null, // si !passed
  cargo: Array<{
    grain_kind: string,
    batch_id: BatchId,
    quality: { grade: Grade, score: Score },
    weight_kg: number,
  }>,
  by_account_id: AccountId,
  received_at: UnixSec,
}
```

**Side effects:**
- Si `inspection_passed`: cargo entra al silo, dispara `silo_filled`.
- Si rechazado: emite `delivery_rejected` (logistics o granja), notif al supplier.

---

### 11.2 sonar:molino:silo_filled

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_molino`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  silo_id: string,                 // 'silo_input_1', 'silo_intermediate_flour', etc.
  silo_kind: 'input_grain' | 'intermediate_flour' | 'intermediate_semolina' | 'intermediate_bran',
  kg_added: number,
  new_total_kg: number,
  capacity_pct: number,
  batch_ids_aggregated: BatchId[],
  added_at: UnixSec,
}
```

---

### 11.3 sonar:molino:cleaning_completed

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_molino`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  machine_id: string,              // 'cleaner_1'
  batch_id: BatchId,               // grano limpiado
  kg_input: number,
  kg_output: number,
  kg_waste: number,                // impurezas eliminadas
  cleaning_score: Score,           // contribuye al factor proceso
  by_account_id: AccountId,
  completed_at: UnixSec,
}
```

---

### 11.4 sonar:molino:milling_started

**Tipo:** state
**Dirección:** server→server (+ broadcast a la company)
**Emisor canónico:** `sonar_molino`
**Suscriptores típicos:** `sonar_tablet` (refrescar Operations)
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  batch_id_input: BatchId,
  grain_kind: string,
  kg_input: number,
  calibration_mm: number,          // 0.05-0.5
  speed_pct: number,                // 50-100
  expected_output: {
    flour_kg: number,
    semolina_kg: number,
    bran_kg: number,
  },
  started_by_account_id: AccountId,
  started_at: UnixSec,
  expected_completion_at: UnixSec,
}
```

---

### 11.5 sonar:molino:milling_completed

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_molino`
**Suscriptores típicos:** `sonar_tablet`, `sonar_core` (lineage update)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  batch_id_input: BatchId,
  batch_id_output: BatchId,         // nuevo batch_id que hereda lineage
  kg_input: number,
  kg_flour: number,
  kg_semolina: number,
  kg_bran: number,
  kg_loss: number,
  quality: {
    grade: Grade,
    score: Score,
    components: { input_quality: Score, process_factor: Score },
  },
  duration_minutes: number,
  completed_at: UnixSec,
}
```

**Side effects:**
- Outputs van a silos intermedios (dispara `silo_filled` por cada).
- Lineage acumulado en items físicos resultado.
- Notif al manager: "Molienda completada — <kg> harina calidad <grade>".

---

### 11.6 sonar:molino:sack_packed

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_molino`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** rate limit per machine: 60/min
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  sack_id: string,
  flour_kind: 'force' | 'baker' | 'whole' | 'semolina_fine' | 'semolina_coarse',
  variant: 'common' | 'premium',
  weight_kg: 25 | 50,
  quality: { grade: Grade, score: Score },
  batch_id: BatchId,
  origin_lineage: Array<{ vertical: string, batch_id: BatchId, company_id: CompanyId }>,
  by_account_id: AccountId,
  packed_at: UnixSec,
}
```

**Side effects:**
- Sack se materializa como Item Físico en ox_inventory con metadata.admirals.
- Etiqueta dinámica generada (logo empresa, fecha, batch, calidad).

---

### 11.7 sonar:molino:pallet_loaded

**Tipo:** state
**Dirección:** server→server
**Emisor canónico:** `sonar_molino`
**Suscriptores típicos:** `sonar_tablet`
**Audit:** loguea
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  pallet_id: string,
  sack_ids: string[],
  total_weight_kg: number,
  destination: 'warehouse' | 'truck',
  by_account_id: AccountId,
  loaded_at: UnixSec,
}
```

---

### 11.8 sonar:molino:machine_failed

**Tipo:** state
**Dirección:** server→server (+ push crítico al manager)
**Emisor canónico:** `sonar_molino`
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  machine_id: string,
  machine_kind: 'cleaner' | 'mill_rollers' | 'sasor_sieve' | 'sacker' | 'forklift' | 'conveyor',
  failure_kind: 'mechanical' | 'wear' | 'cross_contamination' | 'humidity_high',
  affects_quality: boolean,         // true si calidad downstream cae
  estimated_repair_cost: Money,
  estimated_repair_minutes: number,
  failed_at: UnixSec,
}
```

---

### 11.9 sonar:molino:machine_repaired

**Tipo:** state
**Dirección:** server→server
**Schema version:** 1

**Payload:** (idéntico a `granja:machine_repaired` adaptado)
```ts
{
  company_id: CompanyId,
  machine_id: string,
  repaired_by: AccountId | 'mechanic_npc' | 'sonar_mechanic_company',
  cost: Money,
  parts_used: string[],
  duration_minutes: number,
  repaired_at: UnixSec,
}
```

---

### 11.10 sonar:molino:cross_contamination_detected

**Tipo:** state
**Dirección:** server→server (+ push al manager)
**Emisor canónico:** `sonar_molino` (al detectar batch mezcla anomalía)
**Audit:** always
**Throttle:** none
**Schema version:** 1

**Payload:**
```ts
{
  company_id: CompanyId,
  machine_id: string,
  primary_grain: string,
  contaminant_grain: string,
  estimated_quality_drop: number,   // pp en score
  detected_at: UnixSec,
}
```

**Side effects:**
- Notif: "Posible contaminación cruzada — limpiar máquina".
- Si batch ya producido: degrada calidad de los sacks etiquetados con ese batch_id.

---

## 12. Placeholders para verticales futuras

> **Estos eventos NO son canónicos aún** — quedan reservados/anticipados para cuando se diseñen sus nodos. Documentados aquí para evitar colisión de naming.

### 12.1 Dominio `panaderia` (en diseño futuro)

Eventos previstos:
- `sonar:panaderia:flour_received` — recepción de saco molino
- `sonar:panaderia:dough_kneaded` — masa amasada
- `sonar:panaderia:dough_fermented` — fermentación completa
- `sonar:panaderia:bread_baked` — hornada finalizada (con calidad heredada)
- `sonar:panaderia:bread_packaged` — empaquetado / etiquetado
- `sonar:panaderia:retail_dispatched` — pedido a tienda enviado
- `sonar:panaderia:oven_failed` — avería horno
- `sonar:panaderia:starter_culture_refreshed` — masa madre refrescada (mantenimiento RP)

### 12.2 Dominio `retail` (en diseño futuro)

Eventos previstos:
- `sonar:retail:shelf_stocked` — estante repuesto
- `sonar:retail:sale_made` — venta a NPC o jugador
- `sonar:retail:daily_close` — cierre de caja del día
- `sonar:retail:product_expired` — producto caducado descartado
- `sonar:retail:price_changed` — etiqueta de precio modificada
- `sonar:retail:inventory_audit_completed` — recuento

### 12.3 Dominio `cervecería` (vertical futura O3+)

Placeholder: `sonar:cerveceria:mash_started` / `:fermented` / `:kegged` / `:bottled` / `:dispatched`.

### 12.4 Dominio `mecanico` (vertical futura)

- `sonar:mecanico:repair_requested` — taller recibe encargo
- `sonar:mecanico:repair_started`
- `sonar:mecanico:repair_completed`
- `sonar:mecanico:diagnostic_completed`

### 12.5 Dominio `restaurantes` (vertical futura)

- `sonar:restaurantes:order_placed`
- `sonar:restaurantes:order_prepared`
- `sonar:restaurantes:order_served`
- `sonar:restaurantes:reservation_made`

### 12.6 Dominio `seguridad` (oleada 2 — robos)

- `sonar:seguridad:break_in_attempt`
- `sonar:seguridad:break_in_succeeded`
- `sonar:seguridad:alarm_triggered`
- `sonar:seguridad:guard_npc_dispatched`

### 12.7 Reservas de naming

Para evitar colisiones futuras, **estos prefijos están reservados** y nadie debe emitir eventos con ellos hasta que se diseñe el nodo:

- `sonar:cooperativa:*`
- `sonar:notaria:*`
- `sonar:exportacion:*`
- `sonar:gasolinera:*`
- `sonar:distribucion:*`
- `sonar:taller:*`
- `sonar:hospital:*`
- `sonar:legal:*`

---

## 13. Validación de schemas — implementación

> **Filosofía:** todo payload se valida contra schema antes de entrar al bus. Payloads malformados se rechazan con error explícito + log.

### 13.1 Validators registry

```lua
-- sonar_core/server/validators/index.lua
local Validators = {}

-- Cada evento registra su validator al boot
function Validators.Register(event_name, validator_fn, schema_version)
  Validators[event_name] = {
    fn = validator_fn,
    version = schema_version,
  }
end

function Validators.Validate(event_name, payload)
  local v = Validators[event_name]
  if not v then return false, 'no_validator_registered' end
  if payload._schema_version and payload._schema_version ~= v.version then
    return false, 'schema_version_mismatch'
  end
  return v.fn(payload)
end

return Validators
```

### 13.2 Validators por evento (ejemplo bank:transfer_requested)

```lua
-- sonar_core/server/validators/bank_validators.lua
local V = exports.sonar_core:GetValidatorBuilder()

V.Register('sonar:bank:transfer_requested', V.Schema({
  requester_account_id = V.Uuid(),
  from_iban = V.Pattern('^AD%-[A-Z0-9]+%-[A-Z0-9]+%-[A-Z0-9]+$'),
  to_iban = V.Pattern('^AD%-[A-Z0-9]+%-[A-Z0-9]+%-[A-Z0-9]+$'),
  amount = V.Number({ min = 0.01, max = 10000000 }),
  concept = V.String({ maxLength = 100, optional = true }),
  request_nonce = V.Uuid(),
}), 1)

-- builder devuelve función que retorna (bool, errorMsg) según valide
```

### 13.3 Builder de schemas

```lua
-- sonar_core/server/validators/builder.lua (esqueleto API)
local Builder = {}

function Builder.Schema(shape)
  return function(payload)
    if type(payload) ~= 'table' then return false, 'not_a_table' end
    for key, validator in pairs(shape) do
      local val = payload[key]
      local ok, err = validator(val)
      if not ok then
        return false, ('field %s: %s'):format(key, err)
      end
    end
    return true
  end
end

function Builder.String(opts)
  opts = opts or {}
  return function(v)
    if v == nil then
      if opts.optional then return true end
      return false, 'required'
    end
    if type(v) ~= 'string' then return false, 'not_string' end
    if opts.maxLength and #v > opts.maxLength then return false, 'too_long' end
    if opts.minLength and #v < opts.minLength then return false, 'too_short' end
    if opts.pattern and not v:match(opts.pattern) then return false, 'pattern_mismatch' end
    return true
  end
end

function Builder.Number(opts) ... end
function Builder.Uuid() ... end
function Builder.Enum(values) ... end
function Builder.Array(itemValidator, opts) ... end
function Builder.Pattern(regex) ... end

return Builder
```

### 13.4 Validación en NUI (tipos TypeScript + Zod)

```ts
// nui/src/lib/event_schemas.ts (auto-generado por tooling — ver §15)
import { z } from 'zod';

export const AccountId = z.string().uuid();
export const IBAN = z.string().regex(/^AD-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/);

export const BankTransferRequested = z.object({
  requester_account_id: AccountId,
  from_iban: IBAN,
  to_iban: IBAN,
  amount: z.number().positive().max(10_000_000),
  concept: z.string().max(100).nullable(),
  request_nonce: z.string().uuid(),
});

export type BankTransferRequested = z.infer<typeof BankTransferRequested>;
```

> **El cliente valida antes de enviar** para feedback inmediato. **El server siempre re-valida** porque el cliente miente.

---

## 14. Policies — Audit, Throttling, Deprecation

### 14.1 Audit policy

| Categoría de evento | Audit default | Notas |
|---|---|---|
| Mutaciones de dinero (`bank:*_completed`, `*_paid`, `cashbox_movement`) | always | Loguea siempre |
| Creación / cambio de empresa (`core:company_*`) | always | Inmutable trail |
| Firma y status de contratos (`documents:signed`, `*_status_changed`) | always | Auditoría legal RP |
| Acciones físicas críticas (`harvest_completed`, `milling_completed`, `pest_treated`) | always | Trazabilidad |
| Eventos high-frequency (`growth_tick`, `position_updated`, `state_change`) | never | Volumen prohibitivo |
| Mensajes de chat (`messages:sent`) | never | Privacidad + volumen |
| Comandos rechazados (`*_failed`) | always | Detectar abuse |
| Settings y preferencias (`settings_updated`) | never | Datos personales |
| Configurable por evento | configurable | El admin elige verbosidad por dominio |

> **Policy:** los `audit: always` se persisten en `sonar_event_log`. Los `loguea` se persisten en archivo de log de resource. Los `never` solo logging local en debug.

### 14.2 Throttling policy

> **3 niveles:** none, debounce, rate-limit.

#### Throttling levels canónicos

| Patrón | Cuándo usar | Implementación |
|---|---|---|
| **none** | Eventos críticos, baja frecuencia | Sin filtro |
| **debounce(N ms)** | Cambios rápidos donde solo importa el último | Coalescer N ms, emitir el último |
| **debounce(N ms) per <key>** | Misma idea, scoped a entidad | Buckets por key |
| **rate-limit(N per period)** | Anti-abuse | Rechaza emisiones que exceden |
| **rate-limit per <key>** | Anti-abuse scoped | Buckets por key |
| **agregación** | Multi events agrupados | Buffer + emisión periódica |

#### Tabla resumen de throttling actual

| Evento | Throttle |
|---|---|
| `core:state_change` | debounce 500ms per entity |
| `core:reputation_changed` | debounce 5s per (subject, reason_code) |
| `tablet:notification_pushed` | rate-limit 30/min per (account, source_resource) |
| `tablet:app_action_performed` | rate-limit 60/min per (account, app, action) |
| `tablet:settings_updated` | debounce 1s per account |
| `bank:transfer_requested` | rate-limit 5/min per account |
| `messages:sent` | rate-limit 60/min per account |
| `messages:typing` | debounce 2s per (account, chat) |
| `messages:read` | debounce 1s per (account, chat) |
| `market:offer_published` | rate-limit 30/h per publisher |
| `market:reputation_review_posted` | rate-limit 1/24h per (reviewer, subject) |
| `logistics:job_position_updated` | debounce 5s per job |
| `granja:plot_growth_tick` | debounce 5min per plot (interno, agregado) |

### 14.3 Deprecation policy

> **Política:** un evento se mantiene **2 versiones MINOR** después de su deprecación oficial.

#### Pasos para deprecar un evento

1. **MINOR N+0** (anuncio): evento sigue funcional + warning en logs cuando se usa + entry en CHANGELOG + nuevo evento (si reemplaza) operativo.
2. **MINOR N+1** (continúa): warning sigue, deprecation evidente.
3. **MINOR N+2** (eliminación): evento removido. Validator devuelve error `deprecated_event`. Bump MAJOR si hay clientes que dependían.

#### Ejemplo

> *Hipotético:* `sonar:granja:plot_watered` (legacy) → reemplazado por `sonar:granja:plot_irrigated` (nuevo).

| Versión | Estado de `plot_watered` |
|---|---|
| `sonar_granja 1.5.0` | DEPRECATED — emite warning |
| `sonar_granja 1.6.0` | DEPRECATED — sigue funcional |
| `sonar_granja 1.7.0` | DELETED — error si emisión |
| `sonar_granja 2.0.0` | Eliminado del catálogo |

### 14.4 Versionado de schema por evento

Si un evento existente cambia su schema:

- **PATCH del campo opcional** (añadir field opcional, ampliar enum): no requiere bump de schema_version.
- **Cambio de field requerido / breaking**: bump `schema_version`. El validator soporta versión N y N-1 simultáneamente durante 2 minor.
- **Renombrado de field**: NO se permite. Solo deprecación + nuevo field.

---

## 15. Tooling para developers

### 15.1 CLI: `admirals events`

> **Herramienta de línea de comandos** que ayuda a developers a navegar y mantener el catálogo.

```bash
# Listar todos los eventos
admirals events list

# Buscar por dominio
admirals events list --domain granja

# Mostrar detalles de un evento
admirals events show sonar:bank:transfer_completed

# Validar un payload contra schema
admirals events validate sonar:bank:transfer_completed payload.json

# Generar tipos TypeScript desde catálogo
admirals events generate-ts --output nui/src/lib/event_schemas.ts

# Generar tipos Lua desde catálogo
admirals events generate-lua --output sonar_core/shared/event_schemas.lua

# Validar coherencia del catálogo (todo evento usado en código está documentado, todo evento documentado tiene validator, etc.)
admirals events lint

# Verificar deprecations
admirals events check-deprecations
```

### 15.2 Generación automática de tipos

> **Single source of truth:** este markdown.

Tooling parsea las secciones `### sonar:domain:action` con sus payloads y genera:
- TypeScript `event_schemas.ts` (Zod schemas + types).
- Lua `event_schemas.lua` (validator builder calls + table definitions).
- Documentación HTML browseable (oleada 2).

```bash
# Pipeline CI ejecuta:
admirals events generate-ts && admirals events generate-lua
git diff --quiet || (echo "Schemas out of sync"; exit 1)
```

Si el código emite un evento con payload diferente al documentado, los tests fallan.

### 15.3 Debugging del bus

#### Comando admin in-game

```
/admirals events tail [filter]
  --domain <dominio>           — filtrar por dominio
  --account <account_id>       — eventos de un jugador
  --type <type>                — state | command | push | callback
  --since <minutes>            — última N min
```

#### Endpoint local HTTP (oleada 2)

```
GET http://localhost:30120/admirals/events/recent?domain=bank&limit=100
```

### 15.4 Inspector de eventos en NUI (Settings > Developer Mode)

> Solo visible si admin activa `Config.DeveloperMode = true`.

Pestaña en Settings que muestra:
- Lista en vivo de eventos `sonar:*` recientes (últimos 100).
- Tap en uno → ver payload completo + suscriptores.
- Filtro por dominio.

Útil para debug de admins desarrollando server config.

### 15.5 Tests por evento

Cada evento debe tener al menos:
- 1 test que valide payload válido pasa schema.
- 1 test por cada campo crítico que rechaza payload inválido.
- 1 test que comprueba side effects esperados (si state event).

```lua
-- spec/events/bank/transfer_completed_spec.lua
describe('sonar:bank:transfer_completed', function()
  it('valid payload passes schema', function()
    local ok, err = Validators.Validate('sonar:bank:transfer_completed', valid_payload())
    assert.is_true(ok)
  end)

  it('rejects negative amount', function()
    local payload = valid_payload()
    payload.amount = -100
    local ok = Validators.Validate('sonar:bank:transfer_completed', payload)
    assert.is_false(ok)
  end)

  it('triggers receipt creation', function()
    Bus.Publish('sonar:bank:transfer_completed', valid_payload())
    -- Wait for handler
    local docs = DocumentRepo.GetByCategory('receipt')
    assert.is_true(#docs > 0)
  end)
end)
```

---

## 16. Governance del catálogo

### 16.1 Quién puede añadir / modificar eventos

| Tipo de cambio | Quién | Proceso |
|---|---|---|
| **Añadir nuevo evento** | Cualquier developer del equipo SONAR | PR con entry catálogo + validator + tests + suscriptores |
| **Modificar schema (compatible)** | Maintainer del resource | PR con bump schema_version si breaking, sin si compatible |
| **Modificar schema (breaking)** | Founder + maintainer del resource | RFC + revisión + bump MAJOR |
| **Deprecar evento** | Maintainer del resource | RFC + plan de migración + reemplazo |
| **Eliminar evento** | Founder | Tras política de deprecación cumplida |
| **Reservar prefijo de dominio** | Founder | Update §12.7 |

### 16.2 RFC (Request For Comments)

Para cambios significativos:

```
docs/technical/rfcs/
├── RFC-0001_initial_event_catalog.md
├── RFC-0002_introduce_messages_voice.md
└── ...
```

Cada RFC tiene formato fijo:
- **Motivación**
- **Diseño propuesto**
- **Alternativas consideradas**
- **Impacto en otros eventos / resources**
- **Plan de migración (si aplica)**
- **Estado:** draft → discussion → accepted → implemented | rejected

### 16.3 Categorización de eventos por importancia

> **Para priorizar atención y testing.**

| Categoría | Descripción | Eventos típicos |
|---|---|---|
| **Tier 1 — Critical** | Mutación de dinero, identidad, contratos | `bank:*`, `core:company_*`, `documents:signed` |
| **Tier 2 — Important** | Estado del juego que afecta gameplay | `granja:harvest_completed`, `molino:milling_completed` |
| **Tier 3 — Standard** | Eventos de UX, feedback | `tablet:notification_pushed`, `messages:sent` |
| **Tier 4 — Internal** | Implementación, alta frecuencia | `state_change`, `growth_tick`, `position_updated` |

Tier 1 → 100% test coverage obligatorio.
Tier 2 → 80%.
Tier 3 → 60%.
Tier 4 → smoke tests.

---

## 17. Estado del documento

- **Versión:** 1.0 (firmado).
- **Próxima revisión:** evolución según nuevas verticales.
- **Próximas iteraciones esperadas:**
  - Cada vez que un dominio nuevo se diseñe (Panadería, Retail), añadir su sección con eventos completos.
  - Cuando se diseñe el SDK público (oleada 3), añadir sección `app_sdk` con eventos expuestos a apps de terceros.
  - Bump `schema_version` por evento cuando aplique.

### 17.1 Resumen del catálogo

| Dominio | # Eventos canónicos | Estado |
|---|---|---|
| `core` | 9 | Completo |
| `tablet` | 10 | Completo |
| `bank` | 8 | Completo |
| `notifications` | 3 | Completo |
| `documents` | 6 | Completo |
| `messages` | 8 (incl. O2) | Completo |
| `market` | 7 | Completo |
| `logistics` | 7 | Completo |
| `granja` | 20 (incl. O2/O3) | Completo |
| `molino` | 10 | Completo |
| `panaderia` | 8 (placeholder) | Placeholder |
| `retail` | 6 (placeholder) | Placeholder |
| `cervecería` | 5 (placeholder) | Placeholder |
| `mecanico` | 4 (placeholder) | Placeholder |
| `restaurantes` | 4 (placeholder) | Placeholder |
| `seguridad` | 4 (placeholder) | Placeholder |

**Total eventos canónicos oleada 1:** ~88 eventos firmemente documentados.

### 17.2 Documentos relacionados

- `01_architecture.md` v1.0 — arquitectura técnica (este catálogo es derivado de §5).
- `03_db_schema.md` (próximo) — DDL completo + ERD.
- `04_sdk_reference.md` (oleada 3) — SDK público para apps terceros.

---

## Resumen ejecutivo del documento (cierre)

Este documento es **el contrato de comunicación** del ecosistema SONAR (ex-Admirals).

**Pilares cumplidos:**

- ✅ **Pilar 2 (Cadena interconectada):** los eventos son el mecanismo que conecta Granja → Logística → Molino → Banca → Tablet sin acoplamiento directo.
- ✅ **Pilar 3 (Detalle obsesivo):** cada evento tiene su lugar, su payload, su side effects, su throttling, su audit policy.
- ✅ **Pilar 4 (Assets propios → Contratos propios):** ningún evento SONAR depende de un schema externo.
- ✅ **Pilar 5 (Tablet):** muchos eventos terminan en push targeted a la Tablet — la UI siempre refleja el mundo en vivo.
- ✅ **Bible §13.3 (Arquitectura completa):** los eventos para oleadas O2 y O3 ya están documentados (drones, robos, voice, etc.) — la arquitectura los soporta desde día 1.
- ✅ **Architecture §1.1 P2 (Bus único):** este documento es el manual del bus.

**Decisiones clave:**

- Naming inmutable + 3 partes + snake_case.
- Schemas tipados con validator obligatorio.
- 4 tipos: state / command / push / callback.
- Audit / throttling / deprecation policies explícitas por evento.
- Tooling de tipos auto-generados desde el catálogo (single source of truth).
- Governance: RFC para cambios significativos.
- Tier 1-4 para priorizar testing.

**~88 eventos canónicos** documentados para oleada 1 + placeholders para 6 verticales futuras.

**Si un developer quiere saber qué pasa cuando el granjero termina una cosecha, abre este doc y lo sabe en 30 segundos.**

---

*"Speak the language of events."*

---

## 18. Changelog

| Versión | Fecha | Autor | Cambios |
|---|---|---|---|
| 1.0 | 2026 (Oleada 0 firma) | Founder + Cascade | Primera redacción completa 4 partes, 17 secciones, ~3170 líneas, 88 eventos canónicos + placeholders 6 verticales futuras. Filosofía + schemas + 4 tipos + naming convention + tier system + RFC governance. **Firmable Oleada 0.** |
| 1.1 | 2026-05-04 | Founder + Cascade (S1.9 EXTENDED) | **Light refresh post-pivot SONAR** (ADR-011 + ADR-012 + ADR-013). Title rebrand Admirals → SONAR + dual prefix reference (`sonar:*` post-Phase-8 / `sonar:*` pre-Phase-8 legacy). NOTICE r1 top-level (~70 líneas) establece: naming canonical events (mapping 1:1 ejemplos + 88 eventos shipped S1 affected + emisor strings), schema fields invariant pre/post, C003 DEFERRED S3 per ADR-015 (D1=B UI-heavy pivot), voz neutral logging messages ADR-012 §D3, migration execution schedule Phase 8 (next session), reading guide §1-§17 legacy vs canonical. §0 resumen + §cierre rebrand + §Pilar 4 SONAR. **NO touched:** §1-§17 filosofía + schemas + 88 eventos payloads + tipos + tier system + RFC + governance (pivot-agnostic foundational bus). Event prefix `sonar:*` + emitter names `sonar_*` preservados legacy inline hasta Phase 8 execution per ADR-011 §5.5.8 excepciones. Próxima v1.2 post-Phase-8: 88 eventos rename 1:1 inline body. |
| 1.2 | 2026-05-04 | Founder + Cascade (S1.10.x) | **v1.2 — Phase 8+9 namespace migration ejecutada + NOTICE r1 obsoleto removido + prose Admirals→SONAR canonical.** S1.10 Phase 8+9 ejecutada (`admirals_*` → `sonar_*` code + DB tables + events + exports + server.cfg.example + 004 seed alias). S1.10.2 docs auto-rewrite Phase 1 (1075 identifiers code blocks). S1.10.3 docs Phase 2 surgical (NOTICE r1 block removed; prose "Admirals" → "SONAR" en §1-§N preservando refs históricos en este changelog; "Versión" + "FIN" bumped). Smoke harness inline admin commands cumulative S0+S1.1+S1.2+S1.3 = 10/10 PASS. **NO touched:** architecture + interfaces + contratos + tier + anti-patterns (pivot-agnostic). |

---

---

## §X.NEW — Bank Phase A Extension (LOCKED 2026-05-06 BANK-BE.LOCK.R1)

> **Estado:** v1.3.1 LOCKED — extensión Bank-specific Phase A R1 amendment hardening. Sin tocar §1-§17 foundational pivot-agnostic.
> **Owner:** Backend Lead (Cascade activated, sessions BANK-BE.0 / BANK-BE.1 / BANK-BE.LOCK / BANK-BE.AMEND.1 / BANK-BE.LOCK.R1).
> **Scope:** SONAR Bank financial-grade — v1.0.1 R1 promoted post Security Lead BANK-SEC.1 PASS veredicto: 24 server→client público + 9 server→admin ACE-checked + 12 resource-internal + 7 StateBag keys consumed (2 removed M004) + 40+1 callbacks ref (C-BE-02 incl. C001b NEW) = **54 events catalogados** Bank Phase A (51 baseline + 3 NEW M004: `balance:update` + `savings:update` + `balance:adminAudit`).

### Canonical reference

La especificación completa Bank Phase A reside en directorio dedicado:

→ **`@docs/technical/bank_phase_a/c_be_01_events_catalog_v1_3.md`** (v1.0.1 R1 LOCKED, 54 events catalogados)
→ **`@docs/technical/bank_phase_a/c_be_05_statebags_global_publishers.md`** (v1.0.1 R1 LOCKED — sub-tracks A/B privacy boundary post M004 architectural CP1-A → CP1-B migration)

### Por qué documento dedicado en sub-directorio

- **Aislamiento dominio (M4 mandato founder):** Bank Phase A es un dominio financial-grade con primitivas (StateBags global CP1-A/B, idempotency keys persistentes, audit ledger append-only, correlation-id mutex) que no aplican fuera del scope Bank.
- **Pivot-agnostic preservado:** §1-§17 de este SSoT padre son foundational compartidos por TODOS los recursos SONAR (filosofía bus, schemas, naming conventions, tier system, RFC governance). Bank Phase A los **extiende** sin reemplazarlos.
- **Audit trail limpio:** la promotion DRAFT v0.1 → v1.0 LOCKED se ejecutó atómicamente vía git mv (history preservada) en BANK-BE.LOCK ceremony.

### Cross-references

- **Sibling Bank contracts:** `@docs/technical/bank_phase_a/README.md` (índice 5 contratos LOCKED).
- **Pivot SSoTs hermanos extendidos:** `@docs/technical/04_api_contracts.md` v1.3 (callbacks Bank), `@docs/technical/05_state_machines.md` v1.3 (8 FSMs Bank), `@docs/technical/07_bridges_compatibility.md` v1.3 (Bridges Bank).
- **DB Schema upstream:** `@docs/technical/03_db_schema.md` v2.0 LOCKED PROVISIONAL.
- **ADR anchor:** `@docs/planning/02_decision_log_part2.md` ADR-018 (Bank Lite mode hybrid 3-layer).
- **Handoff context:** H1 DB→Backend received 2026-05-06; H2 Backend→Security emitted 2026-05-06 (`@docs/agents/teams/handoffs/h2_backend_to_security/`).

### Sign-off Bank Phase A extension

| Rol | Status | Fecha |
|---|---|---|
| **Founder yaboula** | ✅ APPROVED (BANK-BE.LOCK + BANK-BE.LOCK.R1 green-light) | 2026-05-06 |
| **Backend Lead (Cascade)** | ✅ self-attested (owner) v1.0.1 R1 | 2026-05-06 |
| **DB Lead** | ⚠️ implicit endorsement via DB Schema v2.0 LOCKED PROVISIONAL consistency (no schema migration impact R1 — confirmed M005 column reuse) | 2026-05-06 |
| **Security Lead** | ✅ ACCEPTED-FINAL (BANK-SEC.1 re-audit PASS veredicto + `08_audit_hooks.md` v0.2) | 2026-05-06 |
| **Frontend Lead** | ⏳ PENDING H3 future | — |

**Amendments post-LOCKED** requieren formal Round 1/2/3 protocol per `@docs/agents/teams/03_CROSS_TEAM_CONTRACTS.md` §amendments.

---

## Versioning v1.3 entry

| 1.3 | 2026-05-06 | Founder + Backend Lead (BANK-BE.LOCK) | **v1.3 LOCKED — Bank Phase A extension §X.NEW.** Append pointer hacia `docs/technical/bank_phase_a/c_be_01_events_catalog_v1_3.md` v1.0 LOCKED + `c_be_05_statebags_global_publishers.md` v1.0 LOCKED. Sign-off founder + Backend Lead. **NO touched** §1-§17 foundational pivot-agnostic (filosofía + schemas + 88 eventos payloads + tipos + tier + RFC + governance). Bank-specific 51 events catalogados en sub-directorio dedicado para aislamiento dominio (M4 mandato founder). |
| 1.3.1 | 2026-05-06 | Founder + Backend Lead + Security Lead (BANK-BE.LOCK.R1) | **v1.3.1 LOCKED — Bank Phase A R1 amendment hardening pointer.** Append updated pointer C-BE-01 v1.0.1 R1 LOCKED (54 events — +3 NEW M004 `balance:update` Tier 1 + `savings:update` Tier 1 + `balance:adminAudit` Tier 2; 2 StateBag keys removed CP1-A → CP1-B) + C-BE-05 v1.0.1 R1 LOCKED (M004 architectural founder APPROVED + `publish_balance_update()` helper canonical + lazy publish on `playerJoining`). Sign-off founder + Backend Lead + Security Lead PASS (BANK-SEC.1 re-audit veredicto). **NO touched** §1-§17 foundational pivot-agnostic. |

---

**FIN DEL DOCUMENTO `technical/02_events_catalog.md` v1.3.1 LOCKED (Bank Phase A R1 extension)**
