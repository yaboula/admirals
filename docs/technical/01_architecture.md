# 🏗️ Admirals — Arquitectura Técnica

> **Versión:** 1.0 (firmado)
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2
> **Documentos de diseño que esta arquitectura debe soportar:** `01_node_farm.md` v1.1, `02_admirals_tablet.md` v1.0, `03_node_mill.md` v1.0.
> **Estado:** primera redacción completa de las 4 partes (21 secciones, ~2500 líneas). Documento técnico-estratégico — NO es la documentación de API ni de código fuente.

> **Lectura previa obligatoria:** Bible §13 (Arquitectura completa, contenido en oleadas), Tablet §23 (briefing técnico inicial).

---

## 0. Resumen ejecutivo

Este documento define **cómo se construye técnicamente Admirals** para que:

1. **Soporte arquitectónicamente todos los nodos** ya diseñados (Granja, Tablet, Molino) y los futuros (Panadería, Retail, Restaurantes, Cervecería, Mecánico, etc.) **desde el primer commit**.
2. **Garantice las oleadas sin reescribir.** Añadir centeno, drones agrícolas, robos, etc., sea siempre **añadir config + asset**, no rediseñar.
3. **Sea performático en FiveM real** (objetivo: ningún jugador del servidor pierde fps por culpa de Admirals).
4. **Sea seguro** (todo cliente es hostil — server-authoritative absoluto).
5. **Sea instalable y mantenible** por servidores con admins de nivel medio (no requiere ingeniería de Rockstar).
6. **Sea evolucionable** vía SDK público en oleada 3+ para que terceros construyan sobre la plataforma.

> **Filosofía técnica fundacional:** Admirals **NO es una colección de scripts**. Es **una plataforma con resources especializados**, comunicados por un bus de eventos único, con un schema de base de datos compartido y un cliente NUI común (la Tablet).

---

## 1. Filosofía técnica

### 1.1 Principios

> Estos principios son **innegociables**. Cualquier decisión técnica futura se mide contra ellos.

| # | Principio | Significado práctico |
|---|---|---|
| **P1** | **Server-authoritative absoluto** | El cliente nunca decide nada relevante. Solo renderiza y envía intenciones. |
| **P2** | **Bus de eventos único `admirals:*`** | Toda comunicación inter-resource pasa por el bus. Resources jamás se llaman directamente. |
| **P3** | **Schema compartido** | Una sola DB, tablas con prefijo `admirals_`, sin solapar con tablas del framework base (qbox/esx). |
| **P4** | **Item Físico universal** | Todo "ítem productivo" del ecosistema (saco trigo, saco harina, hogaza pan) tiene el **mismo schema** (peso, volumen, calidad, frescura, origen, lote). |
| **P5** | **Resources independientes pero coordinados** | Cada producto Admirals es 1 resource. Si desinstalas Granja, las apps de Granja desaparecen de la Tablet pero el resto sigue. |
| **P6** | **NUI única (la Tablet)** | No hay UIs custom por nodo. Todo es app dentro de la Tablet. |
| **P7** | **Bridges de compatibilidad explícitos** | QBox, QBCore, ESX, ox_inventory, etc. — cada bridge es código aislado, fácilmente auditable. |
| **P8** | **Configuración fuera del código** | Todo lo configurable (precios, modos, mapas, idiomas) vive en archivos `config.lua` + DB. Nunca hardcoded. |
| **P9** | **Datos en MySQL, estado en RAM** | La fuente de verdad es la DB. La RAM del servidor cachea estado caliente con sync periódico. |
| **P10** | **Performance medible** | Cada feature tiene un budget de frame y de coste de DB. Si supera, no entra hasta optimizar. |

### 1.2 Anti-patrones técnicos prohibidos

- ❌ **Llamadas directas entre resources** (ej. `exports['admirals_granja']:Function()` desde otro resource Admirals). Solo a través del bus.
- ❌ **Polling cada N ms** en client para chequear estado del mundo. Todo es event-driven.
- ❌ **Confianza en datos del cliente** sin validación server.
- ❌ **Tablas de DB sin prefijo `admirals_`** que puedan chocar con el framework base.
- ❌ **UI fuera de la Tablet** (Pilar 5 en código).
- ❌ **Hardcoding de precios, idiomas, ubicaciones**.
- ❌ **Sincronización por broadcast global** cuando sirve broadcast por zona/jugador.
- ❌ **Resources con dependencias circulares** (Granja depende de Tablet, Tablet de Granja).
- ❌ **Migrations que rompen DB existentes** sin script de upgrade documentado.

---

## 2. Stack tecnológico

### 2.1 Stack canónico

| Capa | Tecnología | Versión objetivo | Por qué |
|---|---|---|---|
| **Server runtime** | FiveM (CFX server artifact) | latest stable | Plataforma destino |
| **Server scripting** | Lua 5.4 (cfx-server) | nativo | Lenguaje servidor FiveM |
| **Client scripting** | Lua 5.4 (cfx-client) | nativo | Lenguaje cliente FiveM |
| **Framework base** | QBox primary | 1.x | Stack moderno comunidad |
| **Compatibilidad** | QBCore secondary, ESX bridge limitado | latest | Cobertura comercial |
| **DB** | MySQL 8 / MariaDB 10.6+ | — | Estándar comunidad, oxmysql |
| **DB driver** | oxmysql | latest | Async, prepared statements |
| **Inventario** | ox_inventory | latest | Imprescindible — Item Físico vive aquí |
| **Targeting** | ox_target | latest | Interacciones con props/zonas |
| **Library Lua** | ox_lib | latest | Utils, notificaciones fallback, callbacks |
| **Voice** | pma-voice | latest | Llamadas inter-Tablet |
| **NUI Frontend** | React 18 + TypeScript 5 | latest LTS | UI moderna |
| **Build NUI** | Vite | 5.x | Hot-reload dev, bundle producción |
| **Estilos** | TailwindCSS 3 + componentes propios estilo shadcn/ui | — | Velocidad + consistencia |
| **Animaciones UI** | Framer Motion | 11.x | Transiciones AAA |
| **Iconos** | Lucide React + iconset propio Admirals | latest | Profesional |
| **Estado NUI** | Zustand | 4.x | Reactivo simple |
| **Validación** | Zod | latest | Schemas TypeScript runtime |
| **Tipos compartidos** | TypeScript declarations + Lua type hints | — | Coherencia client/server |

### 2.2 Lo que NO usamos (decisiones explícitas)

- ❌ **ESX como primary** — tecnología legacy, fragmenta el desarrollo.
- ❌ **mysql-async** — obsoleto, oxmysql lo reemplaza.
- ❌ **MenuV / qb-menu** — Pilar 5 prohíbe menús flotantes.
- ❌ **Discord como dependencia hard** — opcional para webhooks de logging, nunca necesario para gameplay.
- ❌ **Cron jobs externos** — todo timing vive dentro de los resources, sin OS-level scheduling.
- ❌ **NodeJS sidecar servers** — añade pieza fuera del control del admin medio. Reservamos solo para SDK público O3+ si imprescindible.
- ❌ **Custom render shaders** que no funcionen en GPUs medias — el wooow de partículas se hace con scaleforms / particles GTA V o webgl-en-NUI, no shaders custom propios.

### 2.3 Versionado SemVer

Cada resource Admirals sigue **SemVer estricto**:

```
admirals_<resource>_<MAJOR>.<MINOR>.<PATCH>
```

- **MAJOR:** breaking change en bus de eventos, schema DB, o API público.
- **MINOR:** feature backward-compatible (oleada nueva = MINOR bump).
- **PATCH:** fix sin cambio de comportamiento.

Compatibilidad cross-resource declarada en `fxmanifest.lua` de cada uno.

---

## 3. Arquitectura de capas

### 3.1 Diagrama lógico

```
                    ┌─────────────────────────────────┐
                    │     CLIENTE FiveM (jugador)     │
                    │                                 │
                    │  ┌────────────────────────────┐ │
                    │  │   NUI: Tablet (React+TS)   │ │
                    │  │   ↕ NUI bridge messages    │ │
                    │  └────────────────────────────┘ │
                    │  ┌────────────────────────────┐ │
                    │  │  Client Lua                │ │
                    │  │  - Render target Tablet    │ │
                    │  │  - Anim de personaje       │ │
                    │  │  - Interacciones físicas   │ │
                    │  │  - Listeners admirals:*    │ │
                    │  └────────────────────────────┘ │
                    └────────────┬────────────────────┘
                                 │ events admirals:*
                                 │ (TriggerServerEvent / Callbacks)
                    ┌────────────▼────────────────────┐
                    │     SERVIDOR FiveM              │
                    │                                 │
                    │  ┌────────────────────────────┐ │
                    │  │  Bus de eventos `admirals:*│ │
                    │  │  - publisher / subscriber  │ │
                    │  │  - throttling              │ │
                    │  │  - validation              │ │
                    │  └────────┬───────────────────┘ │
                    │           │                     │
                    │  ┌────────▼──────┬───────────┐ │
                    │  │ Server Lua    │ Resources │ │
                    │  │ - admirals_core (always)  │ │
                    │  │ - admirals_tablet         │ │
                    │  │ - admirals_granja         │ │
                    │  │ - admirals_molino         │ │
                    │  │ - admirals_panaderia ... │ │
                    │  └────────┬──────────────────┘ │
                    │           │                    │
                    │  ┌────────▼──────────────────┐ │
                    │  │  Bridges (compatibilidad) │ │
                    │  │  - bridge_qbox            │ │
                    │  │  - bridge_qbcore          │ │
                    │  │  - bridge_esx (limitado)  │ │
                    │  └────────┬──────────────────┘ │
                    │           │                    │
                    │  ┌────────▼──────────────────┐ │
                    │  │  oxmysql / ox_inventory   │ │
                    │  └────────┬──────────────────┘ │
                    └───────────┼────────────────────┘
                                │
                    ┌───────────▼────────────────────┐
                    │   MySQL / MariaDB              │
                    │   admirals_* tables            │
                    └─────────────────────────────────┘
```

### 3.2 Descripción de capas

#### Capa 1 — DB

- Una sola base de datos compartida con el framework.
- Todas las tablas Admirals con prefijo `admirals_`.
- oxmysql como único driver. **Todas las queries son prepared statements** (no string interpolation).
- Migrations versionadas en `admirals_core/migrations/` ejecutadas al arranque.

#### Capa 2 — Bridges

- **Aislamiento total** del framework base (QBox / QBCore / ESX) detrás de un módulo único: `admirals_core/bridge/`.
- Funciones canónicas Admirals (ej. `Bridge.GetPlayer(src)`, `Bridge.AddMoney(src, amount, account)`) implementadas N veces — una por framework — con misma firma.
- **El resto del código nunca toca el framework directamente.** Si mañana sale QBox 2.0 con cambios, solo se actualiza el bridge.

#### Capa 3 — `admirals_core` (resource fundacional)

- **Resource raíz que SIEMPRE está cargado.** Sin él, nada funciona.
- Contiene:
  - El **bus de eventos `admirals:*`** (implementación pub/sub).
  - El **bridge** al framework.
  - El **sistema de cuentas Admirals** (cuenta cloud por personaje).
  - El **sistema de empresa** (genérico, reusable por cualquier vertical).
  - El **sistema de Item Físico** (schema universal de ítems productivos).
  - El **sistema de calidad** (cálculos S/A/B/C/D + propagación batch_id).
  - El **sistema de notificaciones** (cross-app, 12 tipos).
  - El **sistema de logging y observability**.
  - **Migrations DB**.
  - **Utilidades comunes** (formato de moneda, tiempo, distancias, etc.).

#### Capa 4 — `admirals_tablet`

- Resource de la Tablet (hardware + OS + apps base).
- Depende de `admirals_core`.
- Contiene:
  - Modelo 3D + spawning del prop Tablet.
  - Sistema de docking + render target del monitor.
  - **NUI completa** (React build) servida desde aquí.
  - Las **8 apps base** (Empresa, Manager Panel, Mercado, Logística, Mensajes, Banca, Notas&Contratos, Tienda Admirals + Settings).
  - **API de registro de apps** que otros resources consumen para añadir sus propias apps.

#### Capa 5 — Resources de nodo (Granja, Molino, Panadería, etc.)

- Cada nodo es un **resource independiente**.
- Depende de `admirals_core` siempre, y declara dependencia opcional con `admirals_tablet` para registrar apps.
- Contiene:
  - **Lógica server** (lo que pasa en el mundo cuando se ejecuta una etapa del proceso).
  - **Lógica client** (interacciones físicas, render targets, animaciones contextuales).
  - **Apps Tablet específicas** (ej. Manager Panel del Granjero — registrada al boot).
  - **Migrations DB** propias (tablas específicas del nodo, prefijo `admirals_<nodo>_`).
  - **Configuración** (cultivos, máquinas, parcelas, contratos, etc.).
  - **Assets locales** (`.ytyp`, `.ydr`, etc.) si aplica.

#### Capa 6 — Cliente: Client Lua

- Maneja:
  - Renderizado del prop Tablet en mano del personaje.
  - Render target sobre la pantalla del modelo 3D.
  - Animaciones del personaje (sacar, guardar, manipular).
  - Listeners de eventos del bus para acciones contextuales.
  - Comunicación con NUI (mensajes a/desde el frontend).

#### Capa 7 — NUI: React + TS (la Tablet)

- **Single-page application** corriendo dentro del cliente FiveM.
- Composición:
  - **OS shell** (boot, lock, home, app switcher, notifications panel, settings).
  - **Apps base** (8 apps + Settings).
  - **Apps registradas dinámicamente** por resources de nodo.
- Comunicación con Lua client vía `fetch` POST a NUI callbacks.
- Comunicación inversa vía `SendNUIMessage` desde Lua.

### 3.3 Dependencias entre resources (mapa)

```
admirals_core (raíz, sin deps Admirals — solo framework + ox)
   ↑
   ├── admirals_tablet (depende de core)
   │      ↑
   │      ├── (apps registradas dinámicamente por otros resources)
   │
   ├── admirals_granja (depende de core, opcional tablet)
   │
   ├── admirals_molino (depende de core, opcional tablet)
   │
   ├── admirals_panaderia (depende de core, opcional tablet)
   │
   ├── admirals_retail (depende de core, opcional tablet)
   │
   └── admirals_<vertical futura> (depende de core, opcional tablet)
```

**Sin dependencias circulares.** **Sin dependencias horizontales** entre nodos (Granja no depende de Molino — se comunican solo por bus).

---

## 4. Schema de base de datos

> **Convención:** todas las tablas con prefijo `admirals_`. Tipos: ids = `VARCHAR(36)` (UUID v4) o `BIGINT AUTO_INCREMENT` según frecuencia. JSON donde la flexibilidad excede la rigidez.

### 4.1 Tablas core (en `admirals_core`)

#### `admirals_accounts`

> **Cuenta Admirals.** Una por personaje. Vinculada al char_id del framework base.

```sql
CREATE TABLE IF NOT EXISTS admirals_accounts (
  account_id      VARCHAR(36) PRIMARY KEY,            -- UUID v4
  char_id         VARCHAR(64) NOT NULL UNIQUE,        -- citizenid QBox / identifier ESX
  alias           VARCHAR(64) NOT NULL,                -- nombre/alias visible
  profile_data    JSON NOT NULL,                       -- foto avatar, bio, configuración, etc.
  reputation      INT NOT NULL DEFAULT 0,              -- 0-100
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_char_id (char_id)
);
```

#### `admirals_tablets`

> **Hardware Tablet.** Una entrada por dispositivo físico que existe en el servidor.

```sql
CREATE TABLE IF NOT EXISTS admirals_tablets (
  tablet_serial    VARCHAR(36) PRIMARY KEY,           -- UUID, único de hardware
  owner_account_id VARCHAR(36) NULL,                  -- cuenta vinculada actualmente, NULL si sin asignar
  tier             ENUM('basic','pro','enterprise') NOT NULL DEFAULT 'basic',
  finish           VARCHAR(32) NULL,                  -- color/acabado (ej. 'titanium-black')
  customizations   JSON NOT NULL,                     -- wallpaper, theme, ringtones, app order, widgets
  pin_hash         VARCHAR(128) NULL,                 -- hash si PIN configurado
  privacy_screen   BOOLEAN NOT NULL DEFAULT FALSE,    -- toggle pantalla privada
  is_lost          BOOLEAN NOT NULL DEFAULT FALSE,    -- robada/perdida
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_account_id) REFERENCES admirals_accounts(account_id) ON DELETE SET NULL,
  INDEX idx_owner (owner_account_id)
);
```

#### `admirals_companies`

> **Empresa.** Genérica — vale para Granja, Molino, Panadería, futuros.

```sql
CREATE TABLE IF NOT EXISTS admirals_companies (
  company_id        VARCHAR(36) PRIMARY KEY,
  vertical          VARCHAR(32) NOT NULL,             -- 'farm' | 'mill' | 'bakery' | 'retail' | etc.
  name              VARCHAR(128) NOT NULL,
  logo_url          VARCHAR(255) NULL,                -- ref a asset (servidor lo sirve)
  owner_account_id  VARCHAR(36) NOT NULL,
  hq_location       JSON NOT NULL,                    -- {x,y,z,heading,zone}
  bank_account_id   VARCHAR(36) NOT NULL,             -- ref a admirals_bank_accounts
  cash_balance      DECIMAL(12,2) NOT NULL DEFAULT 0, -- caja física empresa
  reputation        INT NOT NULL DEFAULT 50,          -- 0-100
  status            ENUM('active','suspended','bankrupt','sold') NOT NULL DEFAULT 'active',
  founded_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  config            JSON NOT NULL,                    -- config específica del vertical (ej. parcelas, máquinas)
  FOREIGN KEY (owner_account_id) REFERENCES admirals_accounts(account_id),
  INDEX idx_vertical (vertical),
  INDEX idx_owner (owner_account_id)
);
```

#### `admirals_company_members`

```sql
CREATE TABLE IF NOT EXISTS admirals_company_members (
  company_id    VARCHAR(36) NOT NULL,
  account_id    VARCHAR(36) NOT NULL,
  role          ENUM('owner','manager','employee','temporary') NOT NULL,
  position      VARCHAR(64) NULL,                     -- 'maquinista', 'tendero', 'tractorista', etc.
  salary        DECIMAL(10,2) NOT NULL DEFAULT 0,     -- salario por turno
  hired_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fired_at      TIMESTAMP NULL,
  productivity  INT NOT NULL DEFAULT 50,              -- 0-100, calculado de tareas completadas
  permissions   JSON NOT NULL,                        -- override permisos (default según role)
  PRIMARY KEY (company_id, account_id),
  FOREIGN KEY (company_id) REFERENCES admirals_companies(company_id) ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES admirals_accounts(account_id),
  INDEX idx_account (account_id)
);
```

#### `admirals_bank_accounts`

```sql
CREATE TABLE IF NOT EXISTS admirals_bank_accounts (
  bank_account_id  VARCHAR(36) PRIMARY KEY,
  iban             VARCHAR(32) NOT NULL UNIQUE,      -- formato 'AD-XXXX-XXXX-XXXX'
  type             ENUM('personal','company','cooperative') NOT NULL,
  owner_id         VARCHAR(36) NOT NULL,             -- account_id si personal, company_id si company
  balance          DECIMAL(14,2) NOT NULL DEFAULT 0,
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_owner (owner_id)
);
```

#### `admirals_bank_movements`

```sql
CREATE TABLE IF NOT EXISTS admirals_bank_movements (
  movement_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  bank_account_id  VARCHAR(36) NOT NULL,
  amount           DECIMAL(14,2) NOT NULL,           -- positivo ingreso, negativo gasto
  balance_after    DECIMAL(14,2) NOT NULL,
  category         VARCHAR(32) NOT NULL,             -- 'salary', 'b2b_payment', 'transfer', 'tax', etc.
  related_doc_id   VARCHAR(36) NULL,                 -- ref a contrato/albarán/factura
  description      VARCHAR(255) NULL,
  counterparty_id  VARCHAR(36) NULL,                 -- otra cuenta involucrada
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (bank_account_id) REFERENCES admirals_bank_accounts(bank_account_id),
  INDEX idx_account_date (bank_account_id, created_at)
);
```

#### `admirals_documents`

> **Notas, contratos, albaranes, recibos, certificados.**

```sql
CREATE TABLE IF NOT EXISTS admirals_documents (
  doc_id          VARCHAR(36) PRIMARY KEY,
  type            ENUM('note','contract','delivery_note','receipt','license','company_deed','bill_of_sale') NOT NULL,
  owner_account_id VARCHAR(36) NULL,                 -- propietario (si personal)
  company_id      VARCHAR(36) NULL,                  -- propietaria si empresarial
  title           VARCHAR(255) NOT NULL,
  content         JSON NOT NULL,                     -- estructura libre por type
  signatures      JSON NOT NULL,                     -- array de {account_id, signed_at, signature_data}
  status          ENUM('draft','pending_signature','active','fulfilled','breached','archived') NOT NULL DEFAULT 'draft',
  parent_doc_id   VARCHAR(36) NULL,                  -- para addendums
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_owner (owner_account_id),
  INDEX idx_company (company_id),
  INDEX idx_type_status (type, status)
);
```

#### `admirals_messages`

```sql
CREATE TABLE IF NOT EXISTS admirals_messages (
  message_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
  chat_id        VARCHAR(36) NOT NULL,               -- conversación
  sender_id      VARCHAR(36) NOT NULL,               -- account_id o company_id (canal empresarial)
  body           TEXT NOT NULL,
  attachments    JSON NULL,                          -- array de doc_ids o URLs de fotos
  read_by        JSON NOT NULL,                      -- array de {account_id, read_at}
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_chat_date (chat_id, created_at)
);
```

#### `admirals_chats`

```sql
CREATE TABLE IF NOT EXISTS admirals_chats (
  chat_id     VARCHAR(36) PRIMARY KEY,
  type        ENUM('direct','group','company_channel') NOT NULL,
  participants JSON NOT NULL,                         -- array de account_ids
  company_id  VARCHAR(36) NULL,                       -- si type='company_channel'
  metadata    JSON NULL,                              -- nombre grupo, foto, etc.
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### `admirals_notifications`

```sql
CREATE TABLE IF NOT EXISTS admirals_notifications (
  notif_id        BIGINT AUTO_INCREMENT PRIMARY KEY,
  account_id      VARCHAR(36) NOT NULL,              -- destinatario
  type            VARCHAR(32) NOT NULL,              -- 'critical_op', 'critical_fin', 'info', etc. (12 tipos)
  source_resource VARCHAR(64) NOT NULL,              -- 'admirals_granja', 'admirals_tablet', etc.
  title           VARCHAR(128) NOT NULL,
  subtitle        VARCHAR(255) NULL,
  body            VARCHAR(500) NULL,
  actions         JSON NULL,                          -- array de {label, action_id, params}
  related_doc_id  VARCHAR(36) NULL,
  read            BOOLEAN NOT NULL DEFAULT FALSE,
  archived        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at         TIMESTAMP NULL,
  INDEX idx_account_unread (account_id, read, created_at)
);
```

#### `admirals_market_offers`

> **Marketplace** — trabajos temporales, productos, servicios, empresas en venta.

```sql
CREATE TABLE IF NOT EXISTS admirals_market_offers (
  offer_id          VARCHAR(36) PRIMARY KEY,
  type              ENUM('temp_job','product','service','company_sale') NOT NULL,
  publisher_id      VARCHAR(36) NOT NULL,             -- account_id o company_id
  publisher_kind    ENUM('account','company') NOT NULL,
  title             VARCHAR(128) NOT NULL,
  description       TEXT NULL,
  data              JSON NOT NULL,                    -- estructura libre por type
  price             DECIMAL(12,2) NULL,
  location          JSON NULL,                        -- {x,y,z,zone}
  status            ENUM('open','reserved','accepted','completed','cancelled','expired') NOT NULL DEFAULT 'open',
  accepted_by       VARCHAR(36) NULL,                 -- account_id que aceptó (temp_job)
  expires_at        TIMESTAMP NULL,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_type_status (type, status),
  INDEX idx_publisher (publisher_id)
);
```

#### `admirals_logistics_jobs`

```sql
CREATE TABLE IF NOT EXISTS admirals_logistics_jobs (
  job_id          VARCHAR(36) PRIMARY KEY,
  origin_id       VARCHAR(36) NOT NULL,               -- company_id origen
  destination_id  VARCHAR(36) NOT NULL,               -- company_id destino
  carrier_id      VARCHAR(36) NULL,                   -- account_id o company_id transportista
  vehicle_plate   VARCHAR(16) NULL,
  cargo           JSON NOT NULL,                      -- array de {item_id, quantity, batch_id}
  status          ENUM('pending','en_route','delivered','disputed','cancelled') NOT NULL DEFAULT 'pending',
  delivery_note_id VARCHAR(36) NULL,                  -- ref a documento albarán
  scheduled_at    TIMESTAMP NULL,
  started_at      TIMESTAMP NULL,
  delivered_at    TIMESTAMP NULL,
  INDEX idx_status (status),
  INDEX idx_carrier (carrier_id)
);
```

#### `admirals_event_log`

> **Append-only log** de eventos para auditoría y observability.

```sql
CREATE TABLE IF NOT EXISTS admirals_event_log (
  log_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  event_name  VARCHAR(128) NOT NULL,                  -- 'admirals:granja:harvest_completed'
  source      VARCHAR(64) NOT NULL,                   -- resource emisor
  actor_id    VARCHAR(36) NULL,                       -- account_id que disparó
  payload     JSON NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_event_name (event_name),
  INDEX idx_actor_date (actor_id, created_at)
) PARTITION BY RANGE (UNIX_TIMESTAMP(created_at)) (
  -- particiones por mes para purga eficiente
  PARTITION p_initial VALUES LESS THAN MAXVALUE
);
```

### 4.2 Tablas por nodo (en cada `admirals_<nodo>`)

> Cada nodo añade sus tablas con sub-prefijo. Ejemplos:

#### Granja: `admirals_farm_*`

```sql
admirals_farm_plots         -- parcelas (id, company_id, type, location, area, current_crop, stage, ...)
admirals_farm_crops         -- catálogo cultivos (id, name, variety, common/premium, stages, season_window, ...)
admirals_farm_stages        -- estados de crecimiento (plot_id, stage, started_at, vars: humedad, plagas, ...)
admirals_farm_silos         -- silos (id, company_id, type, capacity, current_kg, current_quality, batch_ids)
admirals_farm_machinery     -- vehículos/aperos (id, company_id, model, condition, location, last_maintenance)
admirals_farm_licenses      -- licencias por jugador (account_id, license_type, granted_at, valid_until)
```

#### Molino: `admirals_mill_*`

```sql
admirals_mill_silos         -- silos entrada e intermedios (id, company_id, kind, content_type, current_kg, ...)
admirals_mill_machines      -- estado máquinas (id, company_id, type, operating, calibration, last_clean, wear)
admirals_mill_pallets       -- paletas almacén (id, company_id, sack_count, sack_data: type, quality, batch, weight)
admirals_mill_quality_logs  -- registros calibración + producción
```

#### Tablet: `admirals_tablet_*`

```sql
admirals_tablet_app_registry  -- apps registradas (resource_id, app_id, manifest_json)
admirals_tablet_app_data      -- datos persistentes por app (account_id, app_id, data_json)
```

### 4.3 Item Físico — schema universal

> **Esta es la pieza más importante de la arquitectura.** Todo ítem productivo del ecosistema (saco trigo, saco harina, hogaza pan, malla tomates, baguette) tiene este schema. Vive en **ox_inventory metadata**, persistido entre stops.

```jsonc
// Estructura del campo `metadata` de un item Admirals en ox_inventory
{
  "admirals": {
    "item_kind": "wheat_grain | flour | bread | tomato | ...",
    "variant": "common | premium | special",
    "weight_kg": 25.0,
    "volume_l": 18.5,
    "quality": {
      "grade": "S | A | B | C | D",
      "score": 87,                   // 0-100 numérico subyacente
      "components": {                // desglose por variable
        "input_quality": 82,
        "process_factor": 90,
        "freshness": 95,
        // ...
      }
    },
    "freshness": {
      "produced_at": 1730000000,     // unix timestamp
      "expires_at": 1732592000,      // null si no perecedero
      "days_since_production": 3
    },
    "origin": {
      "vertical": "farm | mill | bakery",
      "company_id": "abc-123",
      "company_name": "Granja del Valle",
      "facility_id": "plot_3 | mill_room_1 | oven_2",
      "location": { "x": 1234, "y": 5678 }
    },
    "batch_id": "FARM-2026-0431-A",
    "lineage": [                     // upstream lineage para trazabilidad
      { "vertical": "farm", "batch_id": "FARM-2026-0431-A", "company_id": "..." }
    ],
    "labels": {                      // info renderizable en sticker/embossed
      "company_logo_ref": "valle.png",
      "product_name": "Trigo blando premium",
      "sealed_at_iso": "2026-04-30T08:15:00Z"
    },
    "schema_version": 1
  }
}
```

**Garantías:**
- Cualquier resource Admirals puede leer este schema y hacer decisiones (panadería puede rechazar harina con `quality.grade < B`).
- Ítem se mueve por inventarios sin perder metadata.
- Se mueve por contenedores (saco → camión → silo molino) y mantiene su lineage acumulando entradas en `lineage`.
- `schema_version` permite migraciones futuras sin romper.

### 4.4 Indexación y partitioning

- **Índices ya declarados** en cada tabla (foco: queries más frecuentes — por jugador, por empresa, por estado).
- **`admirals_event_log`** particionado por mes — purga simple.
- **`admirals_bank_movements`** particionado por trimestre si crece (>10M filas).
- **`admirals_messages`** archivable mensual a tabla `_archive`.

### 4.5 Migrations

> **Cada resource tiene su carpeta `migrations/`** con archivos numerados:

```
admirals_core/migrations/
  001_initial_schema.sql
  002_add_reputation_index.sql
  003_partition_event_log.sql
  ...
admirals_granja/migrations/
  001_initial_farm_schema.sql
  002_oleada2_compostaje.sql
  ...
```

Al arrancar el resource, `admirals_core` ejecuta las migrations pendientes y registra en `admirals_schema_versions(resource, version, applied_at)`. **Nunca rebajar** versión sin script `down`.

---

## 5. Bus de eventos `admirals:*` — la espina dorsal

### 5.1 Filosofía

> **Toda comunicación entre resources Admirals pasa por eventos.** Ningún resource llama a otro directamente.

Razones:
- **Desacoplamiento:** un nodo nuevo (Cervecería) puede suscribirse al bus y reaccionar sin modificar Granja.
- **Auditoría:** todo evento se loguea en `admirals_event_log` (configurable por verbosidad).
- **Testabilidad:** mockear el bus permite tests sin levantar todo el ecosistema.
- **SDK público O3:** el bus es la API que apps de terceros consumen.

### 5.2 Convención de naming

```
admirals:<dominio>:<acción>
```

- `dominio` = subsistema o nodo (ej. `core`, `tablet`, `granja`, `molino`).
- `acción` = qué pasó, en pasado (ej. `harvest_completed`, `notification_pushed`).
- **Siempre snake_case en la acción.**
- **Siempre 3 partes** (no más, no menos).

Ejemplos válidos:
- `admirals:core:account_logged_in`
- `admirals:tablet:notification_pushed`
- `admirals:granja:harvest_completed`
- `admirals:molino:milling_started`
- `admirals:bank:transfer_completed`

### 5.3 Tipos de eventos

| Tipo | Dirección | Uso |
|---|---|---|
| **State events** (notificaciones de estado) | server → server, server → clients | "esto pasó". Múltiples suscriptores. |
| **Command events** (intenciones del cliente) | client → server | "quiero hacer X". Validados por server. |
| **Push events** (servidor empuja al cliente) | server → client | Notificaciones, refrescos UI. |
| **Callback events** (request/response) | client ↔ server | Consultas síncronas (lib `lib.callback` o ox_lib). |

### 5.4 Catálogo canónico de eventos (oleada 1)

#### Dominio `core`

| Evento | Payload | Emisor | Suscriptores típicos |
|---|---|---|---|
| `admirals:core:account_logged_in` | `{ account_id, char_id, source }` | core | tablet (login UI), nodos (cargar empresas del jugador) |
| `admirals:core:account_logged_out` | `{ account_id }` | core | todos |
| `admirals:core:company_created` | `{ company_id, vertical, owner_account_id }` | core | tablet (refresh lista), nodo correspondiente |
| `admirals:core:company_member_added` | `{ company_id, account_id, role }` | core | tablet, nodo |
| `admirals:core:reputation_changed` | `{ account_id?, company_id?, delta, new_value, reason }` | core/nodos | tablet (notif) |
| `admirals:core:state_change` | `{ entity_type, entity_id, fields_changed }` | core | tablet (refresh), observability |

#### Dominio `tablet`

| Evento | Payload | Emisor | Suscriptores |
|---|---|---|---|
| `admirals:tablet:opened` | `{ account_id, tablet_serial }` | client | server (analytics) |
| `admirals:tablet:closed` | `{ account_id, tablet_serial }` | client | — |
| `admirals:tablet:dock_in` | `{ account_id, dock_id }` | client | server (UI expand monitor) |
| `admirals:tablet:dock_out` | `{ account_id }` | client | server |
| `admirals:tablet:notification_pushed` | `{ account_id, notif_id, type, ... }` | core/nodos | tablet client (mostrar) |
| `admirals:tablet:app_action_performed` | `{ account_id, app_id, action, params }` | tablet | resource correspondiente |

#### Dominio `bank`

| Evento | Payload | Emisor |
|---|---|---|
| `admirals:bank:transfer_requested` | `{ from, to, amount, concept, requester_account_id }` | tablet/cliente |
| `admirals:bank:transfer_completed` | `{ from, to, amount, movement_id }` | core/bank |
| `admirals:bank:transfer_failed` | `{ from, to, amount, reason }` | core/bank |
| `admirals:bank:salary_paid` | `{ company_id, account_id, amount }` | core (cron interno) |

#### Dominio `granja` (ejemplo de evento por nodo)

| Evento | Payload |
|---|---|
| `admirals:granja:plot_seeded` | `{ company_id, plot_id, crop_id, seeded_by_account_id, started_at }` |
| `admirals:granja:plot_irrigated` | `{ company_id, plot_id, by_account_id, water_kg }` |
| `admirals:granja:plot_fertilized` | `{ company_id, plot_id, fertilizer_type, by_account_id }` |
| `admirals:granja:pest_detected` | `{ company_id, plot_id, pest_type, severity }` |
| `admirals:granja:harvest_started` | `{ company_id, plot_id, harvester_id, by_account_id }` |
| `admirals:granja:harvest_completed` | `{ company_id, plot_id, batch_id, kg, quality }` |
| `admirals:granja:silo_filled` | `{ silo_id, kg_added, batch_id }` |
| `admirals:granja:weather_event` | `{ event_type, severity, area, eta_minutes }` |

#### Dominio `molino` (ejemplo)

| Evento | Payload |
|---|---|
| `admirals:molino:grain_received` | `{ company_id, from_company_id, batch_id, kg, type }` |
| `admirals:molino:silo_filled` | `{ silo_id, kg_added, batch_id }` |
| `admirals:molino:cleaning_completed` | `{ machine_id, batch_id }` |
| `admirals:molino:milling_started` | `{ company_id, batch_id, calibration_mm, speed_pct }` |
| `admirals:molino:milling_completed` | `{ company_id, batch_id_input, batch_id_output, kg_flour, kg_semolina, kg_bran, quality }` |
| `admirals:molino:sack_packed` | `{ company_id, sack_id, type, weight_kg, quality, batch_id }` |
| `admirals:molino:machine_failed` | `{ company_id, machine_id, failure_type }` |

> **El catálogo completo se mantiene en `docs/technical/02_events_catalog.md`** (archivo futuro). Cada nodo nuevo añade su sección con review obligatoria.

### 5.5 Implementación del bus

```lua
-- admirals_core/server/bus.lua (esqueleto)

local Bus = {}
local subscribers = {}      -- { eventName = { handler1, handler2, ... } }

function Bus.Subscribe(eventName, handler, opts)
  opts = opts or {}
  subscribers[eventName] = subscribers[eventName] or {}
  table.insert(subscribers[eventName], { fn = handler, opts = opts })
end

function Bus.Publish(eventName, payload, opts)
  opts = opts or {}

  -- 1. Validation contra schema (si registrado)
  if not Bus.Validate(eventName, payload) then
    Bus.LogError(eventName, payload, 'schema_validation_failed')
    return false
  end

  -- 2. Audit log (configurable verbosity)
  Bus.AuditLog(eventName, payload, opts.actor)

  -- 3. Distribuir a suscriptores
  local subs = subscribers[eventName] or {}
  for _, sub in ipairs(subs) do
    if sub.opts.async then
      Citizen.CreateThread(function() sub.fn(payload) end)
    else
      local ok, err = pcall(sub.fn, payload)
      if not ok then Bus.LogError(eventName, payload, err) end
    end
  end

  -- 4. Push a clientes interesados (si tagged como client-broadcast)
  if opts.broadcast_to_clients then
    TriggerClientEvent(eventName, opts.target_src or -1, payload)
  end

  return true
end

exports('Subscribe', Bus.Subscribe)
exports('Publish', Bus.Publish)
```

> **Cada evento documentado tiene un schema Zod-equivalente Lua** validado en `Bus.Publish`. Esto previene que un nodo emita un payload deformado y rompa a otros suscriptores.

### 5.6 Throttling y backpressure

- Eventos de alta frecuencia (`admirals:granja:plot_growth_tick`) se **agregan** server-side antes de publicar (cada N segundos en vez de cada tick).
- `state_change` se **debounce** por entidad: cambios en la misma entidad en <500ms se agrupan.
- Suscriptores lentos no bloquean el bus: si un handler tarda >50ms, se mueve a thread async automáticamente.

### 5.7 Eventos cross-resource — diagrama de flujo Granja → Molino

```
[Granjero termina cosecha en su parcela]
        │
        ▼
admirals_granja: emite admirals:granja:harvest_completed
        │
        ├─→ Bus valida + loguea
        ├─→ admirals_tablet: notif al granjero ("Cosecha lista")
        ├─→ admirals_core: actualiza reputación si calidad alta
        └─→ admirals_granja (mismo): refresca silo, abre venta en mercado

[Granjero firma envío al molino]
        ▼
admirals_logistics: crea job, emite admirals:logistics:job_started
        │
        ├─→ admirals_tablet: tracking visible al molinero
        └─→ admirals_granja: marca lote como "en tránsito"

[Camión llega al molino, báscula confirma]
        ▼
admirals_molino: emite admirals:molino:grain_received
        │
        ├─→ admirals_bank: dispara transfer_requested (granjero ← molino)
        ├─→ admirals_tablet: notif "Pago recibido" al granjero
        └─→ admirals_molino (mismo): silo se llena, batch_id registrado
```

**Cero acoplamiento directo Granja↔Molino.** Solo eventos.

---

## 6. Estructura interna de un resource Admirals

> **Todos los resources Admirals siguen la misma estructura.** Esto facilita onboarding, code review, mantenimiento.

### 6.1 Layout estándar

```
admirals_<resource>/
├── fxmanifest.lua                  -- declaración FiveM
├── README.md                       -- doc resumen del resource
├── CHANGELOG.md                    -- histórico SemVer
├── config/
│   ├── config.lua                  -- config principal (admin edita aquí)
│   ├── config_locale.lua           -- locale default
│   └── config_brand.lua            -- branding por servidor
├── locales/
│   ├── en.lua
│   ├── es.lua
│   └── ...
├── migrations/
│   ├── 001_initial.sql
│   └── ...
├── server/
│   ├── main.lua                    -- bootstrap + bus subscriptions
│   ├── bridge_proxy.lua            -- usa admirals_core/bridge
│   ├── handlers/
│   │   ├── handler_<feature1>.lua
│   │   └── handler_<feature2>.lua
│   ├── services/
│   │   ├── service_<domain>.lua
│   │   └── ...
│   └── repositories/
│       ├── repo_<table1>.lua       -- queries DB para esa tabla
│       └── ...
├── client/
│   ├── main.lua                    -- bootstrap client
│   ├── interactions/
│   │   ├── interaction_<zone>.lua  -- ox_target, ped interactions
│   │   └── ...
│   ├── render_targets/
│   │   └── render_<screen>.lua
│   └── animations/
│       └── anim_<scene>.lua
├── nui/                            -- (solo en admirals_tablet y resources que registren apps)
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── tailwind.config.ts
│   └── src/
│       ├── apps/
│       │   └── <app>/...
│       ├── components/
│       ├── lib/
│       │   ├── bridge.ts           -- wrapper de NUI bridge
│       │   ├── store/              -- Zustand stores
│       │   └── i18n/
│       └── main.tsx
├── shared/
│   ├── constants.lua               -- constantes shared client+server
│   └── schemas.lua                 -- schemas de validación de eventos
└── stream/                         -- assets a stremear (si aplica)
    ├── *.ytyp
    ├── *.ydr
    └── ...
```

### 6.2 fxmanifest.lua canónico

```lua
fx_version 'cerulean'
games { 'gta5' }

name 'admirals_granja'
author 'Admirals'
description 'Plataforma agrícola raíz del ecosistema Admirals'
version '1.0.0'

dependencies {
  '/server:7290',                   -- versión mínima del artifact
  'oxmysql',
  'ox_inventory',
  'ox_lib',
  'ox_target',
  'admirals_core',
}

shared_scripts {
  '@ox_lib/init.lua',
  'shared/*.lua',
  'config/config.lua',
  'config/config_locale.lua',
  'locales/*.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/main.lua',
  'server/bridge_proxy.lua',
  'server/repositories/*.lua',
  'server/services/*.lua',
  'server/handlers/*.lua',
}

client_scripts {
  'client/main.lua',
  'client/interactions/*.lua',
  'client/render_targets/*.lua',
  'client/animations/*.lua',
}

ui_page 'nui/dist/index.html'        -- solo si tiene UI propia (no si solo registra apps en Tablet)
files {
  'nui/dist/index.html',
  'nui/dist/assets/*',
  'nui/dist/locales/*.json',
}

-- Metadata Admirals
admirals_resource 'true'
admirals_vertical 'farm'
admirals_apps_provided { 'farmer_manager_panel' }
admirals_min_core_version '1.0.0'
```

### 6.3 Bootstrap de un resource (server/main.lua)

```lua
-- admirals_granja/server/main.lua
local Bus = exports.admirals_core:GetBus()
local Bridge = exports.admirals_core:GetBridge()
local Logger = exports.admirals_core:GetLogger('admirals_granja')

-- 1. Migrations
exports.admirals_core:RunMigrations('admirals_granja', GetCurrentResourceName())

-- 2. Registrar app(s) en Tablet (si Tablet está cargado)
if GetResourceState('admirals_tablet') == 'started' then
  exports.admirals_tablet:RegisterApp({
    app_id = 'farmer_manager_panel',
    name = 'Manager Panel',  -- se sobreescribe por locale del jugador
    icon = 'images/manager_panel.svg',
    vertical = 'farm',
    permissions_required = { 'view_company' },
    component_path = 'farmer/ManagerPanelApp',  -- ref al bundle JS
  })
end

-- 3. Subscribirse a eventos del bus relevantes
Bus.Subscribe('admirals:logistics:cargo_delivered', function(payload)
  -- gestionar entrega de grano si destino es una de nuestras granjas (raro), etc.
end)

Bus.Subscribe('admirals:tablet:app_action_performed', function(payload)
  if payload.app_id == 'farmer_manager_panel' then
    require('handlers.handler_manager_panel').Handle(payload)
  end
end)

-- 4. Cron interno (timers internos, no OS cron)
exports.admirals_core:RegisterCron('admirals:granja:growth_tick', { interval_minutes = 5 }, function()
  require('services.service_growth').Tick()
end)

Logger:Info('admirals_granja booted, version 1.0.0')
```

### 6.4 Comunicación NUI ↔ Lua client (la Tablet)

#### Cliente Lua → NUI (server-driven)

```lua
-- admirals_tablet/client/main.lua
local function PushNotificationToTablet(notif)
  SendNUIMessage({
    action = 'notification:push',
    payload = notif,
  })
end

-- Subscripción al bus para refrescar UI
RegisterNetEvent('admirals:tablet:notification_pushed', function(payload)
  PushNotificationToTablet(payload)
end)
```

#### NUI → Lua client (intent del usuario)

```ts
// nui/src/lib/bridge.ts
export async function nuiPost<T = unknown>(action: string, payload: unknown): Promise<T> {
  const resourceName = (window as any).GetParentResourceName?.() ?? 'admirals_tablet';
  const res = await fetch(`https://${resourceName}/${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload ?? {}),
  });
  if (!res.ok) throw new Error(`nui ${action} failed`);
  return res.json();
}

// uso desde una app
const result = await nuiPost<{ ok: boolean }>('app:bank:transfer', {
  from: 'AD-XXXX',
  to: 'AD-YYYY',
  amount: 1500,
  concept: 'Pago materiales',
});
```

```lua
-- admirals_tablet/client/main.lua
RegisterNUICallback('app:bank:transfer', function(data, cb)
  -- 1. Validación local mínima (formato)
  if not data.from or not data.to or not data.amount then
    return cb({ ok = false, error = 'invalid_payload' })
  end

  -- 2. Forward al server (server es authoritative)
  TriggerServerEvent('admirals:bank:transfer_requested', data)

  -- 3. Esperar callback server
  exports.admirals_core:OnceCallback('admirals:bank:transfer_completed', function(result)
    cb(result)
  end, { timeout_ms = 5000 })
end)
```

> **Regla:** NUI nunca calcula nada con dinero. Solo dispara intents. El servidor decide.

### 6.5 Registro dinámico de apps en la Tablet

```ts
// nui/src/lib/app_registry.ts (Tablet NUI)
type AppManifest = {
  app_id: string;
  name: string;
  icon: string;
  vertical: string;
  permissions_required: string[];
  component_path: string;  // ref dinámico, lazy-loaded
};

const registry = new Map<string, AppManifest>();

export function registerApp(manifest: AppManifest) {
  registry.set(manifest.app_id, manifest);
  emit('app:registry_changed');
}

// Las apps se cargan con React.lazy() según el component_path.
```

Cuando un resource Admirals se inicia, llama a `RegisterApp` server-side, que a su vez empuja un mensaje NUI a las Tablets activas:

```js
// Tablet NUI recibe
window.addEventListener('message', (e) => {
  if (e.data.action === 'app:registered') {
    registerApp(e.data.payload);
  }
});
```

**Resultado:** la home de la Tablet muestra el icono de la nueva app sin reload del cliente.

---

## 7. Item Físico — patrones avanzados

### 7.1 Creación de un Item Físico

```lua
-- admirals_core/server/services/item_factory.lua
local ItemFactory = {}

function ItemFactory.Create(spec)
  -- spec: { item_kind, variant, weight_kg, quality, origin, batch_id, lineage_in? }
  local meta = {
    admirals = {
      item_kind = spec.item_kind,
      variant = spec.variant or 'common',
      weight_kg = spec.weight_kg,
      volume_l = ItemFactory.ComputeVolume(spec.item_kind, spec.weight_kg),
      quality = spec.quality,
      freshness = {
        produced_at = os.time(),
        expires_at = ItemFactory.ComputeExpiry(spec.item_kind, os.time()),
        days_since_production = 0,
      },
      origin = spec.origin,
      batch_id = spec.batch_id,
      lineage = ItemFactory.AppendLineage(spec.lineage_in, spec.origin),
      labels = ItemFactory.BuildLabels(spec),
      schema_version = 1,
    },
  }
  return meta
end

return ItemFactory
```

### 7.2 Movimiento de Item Físico (granjero → molino)

Cuando el grano sale del silo de la granja y entra al silo del molino, **mantenemos lineage**:

```lua
-- Cuando se vacía un saco/lote del granjero al silo del molino
local incoming = {
  item_kind = 'wheat_grain',
  weight_kg = 800,
  quality = sack.metadata.admirals.quality,
  batch_id = sack.metadata.admirals.batch_id,
  origin = sack.metadata.admirals.origin,
  lineage = sack.metadata.admirals.lineage,
}

-- El silo del molino acumula múltiples lotes — guardamos lineage_aggregate
mill_silo:AddBatch(incoming)
```

Cuando el molino produce harina, el output **hereda lineage del input**:

```lua
local flour_meta = ItemFactory.Create({
  item_kind = 'flour',
  variant = 'force',  -- harina de fuerza
  weight_kg = 25,
  quality = ComputeMillQuality(input_quality, process_factor),
  batch_id = 'MILL-2026-0431-A',
  origin = { vertical = 'mill', company_id = mill.company_id, ... },
  lineage_in = mill_silo:GetLineageForBatch(input_batch),
})
```

> **Resultado:** el saco de harina tiene en `lineage[]` un registro de la cosecha de granja origen + la molienda. Trazabilidad completa.

### 7.3 Cálculo de freshness

```lua
function Freshness.Update(meta)
  local now = os.time()
  local produced = meta.admirals.freshness.produced_at
  meta.admirals.freshness.days_since_production = math.floor((now - produced) / 86400)

  if meta.admirals.freshness.expires_at and now > meta.admirals.freshness.expires_at then
    -- Item caducado — penaliza calidad
    meta.admirals.quality.score = math.max(0, meta.admirals.quality.score - 30)
    meta.admirals.quality.grade = ScoreToGrade(meta.admirals.quality.score)
  end

  return meta
end
```

Llamado:
- Cuando se inspecciona el ítem (Manager Panel, Notas, etc.).
- En cron periódico para ítems en almacenes (cada hora real).

### 7.4 Validación al consumir un Item

Cualquier nodo downstream valida que el ítem cumple condiciones del contrato:

```lua
function Contract.ValidateDelivery(contract, items)
  for _, item in ipairs(items) do
    local meta = item.metadata.admirals

    if contract.min_quality and GradeRank(meta.quality.grade) < GradeRank(contract.min_quality) then
      return false, 'quality_below_minimum'
    end

    if contract.required_kind and meta.item_kind ~= contract.required_kind then
      return false, 'wrong_item_kind'
    end

    if contract.max_age_days and meta.freshness.days_since_production > contract.max_age_days then
      return false, 'too_old'
    end
  end
  return true
end
```

---

## 8. Sistema de empresa — patrones de implementación

### 8.1 Roles + matriz de permisos

```lua
-- admirals_core/shared/constants.lua
CONST.ROLES = { 'owner', 'manager', 'employee', 'temporary' }

CONST.PERMISSIONS = {
  -- Empresa
  view_company           = { 'owner', 'manager', 'employee', 'temporary' },
  edit_company_basic     = { 'owner', 'manager' },
  edit_company_critical  = { 'owner' },                  -- vender, cerrar, cambiar IBAN
  -- Empleados
  view_members           = { 'owner', 'manager', 'employee' },
  hire_member            = { 'owner', 'manager' },
  fire_member            = { 'owner', 'manager' },
  promote_member         = { 'owner' },
  set_salary             = { 'owner' },
  -- Banca
  view_bank              = { 'owner', 'manager' },
  transfer_money         = { 'owner', 'manager' },
  open_cash_box          = { 'owner', 'manager', 'employee' }, -- caja física
  -- Inventario
  view_inventory         = { 'owner', 'manager', 'employee' },
  remove_inventory       = { 'owner', 'manager' },
  -- Contratos
  view_contracts         = { 'owner', 'manager' },
  sign_contracts         = { 'owner', 'manager' },
  -- Operaciones específicas
  start_machine          = { 'owner', 'manager', 'employee' },
  configure_machine      = { 'owner', 'manager' },
}
```

### 8.2 Función `Check`

```lua
function Company.HasPermission(account_id, company_id, permission)
  local member = CompanyRepo.GetMember(company_id, account_id)
  if not member then return false end

  -- Custom permissions del miembro tienen prioridad sobre default por role
  if member.permissions and member.permissions[permission] ~= nil then
    return member.permissions[permission]
  end

  local allowed_roles = CONST.PERMISSIONS[permission]
  if not allowed_roles then return false end

  for _, r in ipairs(allowed_roles) do
    if r == member.role then return true end
  end
  return false
end
```

Usado en cada handler antes de ejecutar:

```lua
RegisterNetEvent('admirals:granja:harvest_start', function(plot_id)
  local src = source
  local account = Bridge.GetAccountId(src)
  local plot = PlotRepo.Get(plot_id)
  if not Company.HasPermission(account, plot.company_id, 'start_machine') then
    return Logger:Warn('Unauthorized harvest_start by '..account)
  end
  -- ... continuar
end)
```

### 8.3 Sistema de salarios (cron interno)

```lua
-- cada 1h in-game, calcular y pagar nóminas pendientes
exports.admirals_core:RegisterCron('admirals:bank:salary_tick', { interval_minutes = 60 }, function()
  local pending = CompanyRepo.GetPendingSalaries()
  for _, pay in ipairs(pending) do
    local company = CompanyRepo.Get(pay.company_id)
    if company.cash_balance + company.bank_balance >= pay.amount then
      Bank.Transfer({
        from = company.bank_account_id,
        to = pay.member_bank_account_id,
        amount = pay.amount,
        category = 'salary',
        concept = 'Salario turno '..pay.shift_label,
      })
    else
      -- emitir notif crítica al owner
      Bus.Publish('admirals:tablet:notification_pushed', {
        account_id = company.owner_account_id,
        type = 'critical_fin',
        title = 'Caja insuficiente',
        body = 'No hay fondos para pagar nóminas. '..pay.amount..'$ pendientes.',
      })
    end
  end
end)
```

### 8.4 Caja física (dual-pool)

- **`cash_balance`** vive en `admirals_companies` directo (no en `admirals_bank_accounts`).
- Las operaciones físicas con la caja (abrir, depositar, retirar) son client → server eventos.
- **Validación física obligatoria:** el jugador tiene que estar **en mismo lugar que el prop caja física** para abrir.

```lua
RegisterNetEvent('admirals:granja:cashbox_open', function(company_id)
  local src = source
  local ped_pos = GetEntityCoords(GetPlayerPed(src))
  local cashbox_pos = CompanyRepo.GetCashboxLocation(company_id)
  if #(ped_pos - cashbox_pos) > 2.0 then
    return -- demasiado lejos, ignorar
  end
  if not Company.HasPermission(account, company_id, 'open_cash_box') then return end

  -- enviar payload al cliente para abrir UI mínima de la caja
  TriggerClientEvent('admirals:granja:cashbox_opened', src, {
    balance = company.cash_balance,
    movements = MovementsRepo.GetRecentForCashbox(company_id, 20),
  })
end)
```

---

## 9. Sistema de calidad — propagación formal

### 9.1 Modelo

> **La calidad es un score 0-100 acompañado de un grade (S/A/B/C/D).** El score se computa desde múltiples variables ponderadas; el grade es discretización para UX.

```
score → grade:
  90-100 → S
  75-89  → A
  60-74  → B
  40-59  → C
  0-39   → D
```

### 9.2 Cálculo en el productor (granja)

```lua
function Quality.ComputeFarm(plot, harvest_event)
  local crop_def = CropCatalog.Get(plot.crop_id)

  local weights = crop_def.quality_weights -- ej. {soil=0.15, irrigation=0.20, fertilization=0.15, pest_control=0.20, harvest_timing=0.15, weather=0.10, seed_quality=0.05}
  local components = {
    soil           = plot.soil_score,
    irrigation     = plot.irrigation_score,
    fertilization  = plot.fertilization_score,
    pest_control   = plot.pest_control_score,
    harvest_timing = harvest_event.timing_score,
    weather        = plot.weather_score,
    seed_quality   = plot.seed_quality,
  }
  local total = 0
  for k, w in pairs(weights) do
    total = total + (components[k] or 50) * w
  end
  return {
    score = math.floor(total),
    grade = Quality.ScoreToGrade(total),
    components = components,
  }
end
```

### 9.3 Propagación en el procesador (molino)

```lua
function Quality.ComputeMill(input_quality, mill_state, batch_kg)
  -- Factor proceso del molino: 0-100
  local fp = 0
  fp = fp + 25 * mill_state.cleaning_score        -- limpieza adecuada
  fp = fp + 25 * mill_state.calibration_score     -- calibración correcta
  fp = fp + 20 * mill_state.humidity_score        -- humedad ambiente OK
  fp = fp + 15 * mill_state.machine_wear_score    -- desgaste rodillos
  fp = fp + 15 * mill_state.cross_contamination_score -- limpieza entre tipos

  local result_score = input_quality.score * 0.7 + fp * 0.3

  return {
    score = math.floor(result_score),
    grade = Quality.ScoreToGrade(result_score),
    components = {
      input_quality = input_quality.score,
      process_factor = math.floor(fp),
    },
  }
end
```

### 9.4 Lineage para auditoría

En cada propagación se acumula entrada en `lineage[]`. La UI de Manager Panel y de Notas&Contratos puede renderizar la cadena visualmente:

```
🌾 Granja del Valle (Calidad A · 87/100)
   parcela 3 · cosecha 30/04/2026
      ↓
🏭 Molino de Pedro (Calidad A · 84/100)
   pasada 0.18mm · velocidad 80%
      ↓
🍞 Panadería del Sur (Calidad A · 81/100)
   masa madre · cocción 220°C 35min
```

---

## 10. Tablet — arquitectura técnica completa

### 10.1 El render target — pantalla viva

> **La pieza técnica más crítica del producto.** Lo que ven otros jugadores cuando miran tu Tablet es la **misma UI que tú ves**.

#### Mecánica

1. La Tablet 3D tiene un **plano** definido como zona de render target (definido en el `.ytyp` por el equipo 3D).
2. Cuando el jugador saca la Tablet, el client Lua:
   - Adjunta el prop al ped en mano dominante (anim).
   - Crea un **runtime texture** (`CreateRuntimeTxd` + `CreateRuntimeTextureFromImage` no — usamos NamedRendertarget).
   - Asocia el rendertarget al modelo.
3. La NUI **renderiza en una capa específica** que se proyecta al rendertarget en cada frame.
4. Otros jugadores cerca, al mirar la Tablet, ven la textura del rendertarget actualizándose en vivo.

#### Performance

- **Solo 1 rendertarget activo por jugador.** Si la Tablet se guarda, se libera el target.
- **NUI render budget:** 30fps target. La UI de la Tablet limita animaciones a `transform`/`opacity` para mantenerse en GPU compositing.
- **Rendertarget update rate:** 30fps (no 60). Suficiente para sentir vivo.
- **Si hay muchos jugadores con Tablet a la vez** (ej. 20 en sala de juntas), solo **rendertargets en mismo viewport** se mantienen activos. Los demás congelan última frame hasta volver a viewport.

#### Pantalla privada

```lua
function RenderTarget.UpdateForObserver(observer_src, owner_src)
  local owner_settings = TabletRepo.GetSettingsBySrc(owner_src)
  if owner_settings.privacy_screen and observer_src ~= owner_src then
    -- otros ven solo wallpaper + logo
    SendNUIMessageTo(owner_src, { action = 'render:privacy_mask', payload = { wallpaper = owner_settings.wallpaper } })
    return
  end
  -- otros ven UI completa (default)
end
```

### 10.2 Boot sequence técnica

```ts
// nui/src/os/boot.tsx
export async function bootSequence(): Promise<void> {
  await nuiPlay('boot_sound');                 // sonido naval ~1.2s
  await fadeIn('logo', 400);                    // logo aparece
  await playWaveAnimation();                    // 3 anillos concéntricos 500ms
  await typewriter('AdmiralsOS', 300);
  await fadeOut('boot_screen', 400);
  emit('os:boot_complete');
}
```

Bus eventos respectivos en Lua side disparan el sonido y validan estado.

### 10.3 Catálogo de NUI callbacks (cliente Lua)

```lua
-- admirals_tablet/client/main.lua
local NUI_CALLBACKS = {
  ['os:boot_complete']            = require('handlers.handle_boot_complete'),
  ['os:close_tablet']             = require('handlers.handle_close_tablet'),
  ['app:bank:transfer']           = require('handlers.handle_bank_transfer'),
  ['app:market:accept_offer']     = require('handlers.handle_market_accept'),
  ['app:logistics:create_job']    = require('handlers.handle_logistics_create'),
  ['app:notes:sign_document']     = require('handlers.handle_doc_sign'),
  ['app:settings:update']         = require('handlers.handle_settings_update'),
  ['app:tablet_action']           = require('handlers.handle_app_action'),  -- catch-all para apps registradas
  -- ...
}

for action, handler in pairs(NUI_CALLBACKS) do
  RegisterNUICallback(action, handler)
end
```

### 10.4 Performance budget de la Tablet

| Métrica | Budget | Cómo se mide |
|---|---|---|
| Tiempo de boot | <2s 99-percentil | timing eventos `os:boot_start` → `os:boot_complete` |
| Apertura de app | <300ms desde tap a render usable | timing `app:open_request` → `app:rendered` |
| Refresh Manager Panel con datos en vivo | <500ms | timing recepción `state_change` → DOM update |
| FPS impacto en cliente con Tablet abierta | <5fps drop (en GPU media) | benchmark internos |
| RAM NUI | <80MB residente | profiler Chrome devtools |
| Bundle JS final | <2MB gzipped | rollup-plugin-visualizer |
| Llamada NUI ↔ Lua callback | <50ms p95 | timing internal |
| Render target update | 30fps estables | gpu profiler |

### 10.5 Internacionalización

```ts
// nui/src/lib/i18n/index.ts
import { create } from 'zustand';

const useLocale = create<{ locale: string; t: (k: string) => string }>((set) => ({
  locale: 'es',
  t: (key: string) => translations[locale.locale]?.[key] ?? key,
}));
```

- Locales se cargan dinámicamente desde JSON servidos por Tablet resource.
- Cada resource Admirals puede aportar **sus propios locales** para sus apps (registrados al boot).

### 10.6 Arquitectura de las apps registrables

```ts
// Contract para apps externas (registradas por nodos)
export interface AppManifestExt {
  app_id: string;
  name_key: string;            // clave i18n
  icon_url: string;
  vertical: string;
  permissions_required: string[];
  component_url: string;       // URL al bundle JS de la app (servida por su resource)
  schema_version: number;
}

// React.lazy carga el bundle on-demand
const AppComponent = React.lazy(() => import(/* @vite-ignore */ manifest.component_url));
```

> **Sandboxing:** las apps cargadas dinámicamente no acceden directamente a la DB ni al estado global. Solo emiten **intents** vía bridge → server. Esto prepara el SDK público de O3.

---

## 11. Bridges de compatibilidad

### 11.1 Filosofía: aislamiento total

> **El framework base (QBox / QBCore / ESX) jamás se toca fuera del módulo `bridge`.** Si mañana el framework cambia su API, solo se actualiza el bridge. Cero impacto en el resto del ecosistema.

### 11.2 API canónica del bridge

```lua
-- admirals_core/server/bridge.lua
local Bridge = {}

-- Identidad de jugador
function Bridge.GetPlayerSrcByCharId(char_id)         end
function Bridge.GetCharIdBySrc(src)                   end
function Bridge.GetAccountId(src)                     end  -- account Admirals (no del framework)

-- Datos básicos
function Bridge.GetPlayerName(src)                    end
function Bridge.GetPlayerJob(src)                     end  -- mapeo opcional a job/gang del framework
function Bridge.IsAdmin(src)                          end

-- Dinero (cuentas del framework, NO bancarias Admirals)
function Bridge.GetMoney(src, account)                end  -- account: 'cash' | 'bank'
function Bridge.AddMoney(src, account, amount)        end
function Bridge.RemoveMoney(src, account, amount)     end

-- Inventario (vía ox_inventory directamente cuando posible)
function Bridge.AddItem(src, item, count, metadata)   end
function Bridge.RemoveItem(src, item, count)          end
function Bridge.GetItemCount(src, item)               end
function Bridge.GetInventoryItems(src)                end

-- Vehículos
function Bridge.SpawnVehicleForPlayer(src, model, location, plate) end
function Bridge.IsVehicleOwned(plate, char_id)        end

-- Eventos del framework relevantes (puenteados al bus Admirals)
-- ej. 'QBCore:Server:OnPlayerLoaded' → 'admirals:core:account_logged_in'

return Bridge
```

### 11.3 Implementaciones por framework

```
admirals_core/server/bridge_impl/
├── qbox.lua
├── qbcore.lua
├── esx.lua
└── _autodetect.lua
```

`_autodetect.lua` mira en arranque qué resource de framework está corriendo y carga el impl correspondiente. Failsafe: si no detecta, **no arranca** y emite error claro.

### 11.4 Ejemplo: implementación QBox

```lua
-- admirals_core/server/bridge_impl/qbox.lua
local QBX = exports.qbx_core
local Bridge = {}

function Bridge.GetCharIdBySrc(src)
  local Player = QBX:GetPlayer(src)
  return Player and Player.PlayerData.citizenid
end

function Bridge.GetMoney(src, account)
  local Player = QBX:GetPlayer(src)
  return Player and Player.PlayerData.money[account] or 0
end

function Bridge.AddMoney(src, account, amount)
  local Player = QBX:GetPlayer(src)
  if not Player then return false end
  Player.Functions.AddMoney(account, amount)
  return true
end

-- Puente de eventos
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
  local src = source
  local char_id = Bridge.GetCharIdBySrc(src)
  -- Re-emitir como evento Admirals
  exports.admirals_core:GetBus().Publish('admirals:core:account_logged_in', {
    src = src,
    char_id = char_id,
    source = 'qbox',
  })
end)

return Bridge
```

### 11.5 ESX bridge limitado

ESX queda **soportado pero limitado** en oleada 1:
- Identidad y dinero: OK.
- Inventarios: requiere ox_inventory (no nativo ESX).
- Jobs/society: bridge mínimo, no se usa para empresas Admirals (Admirals tiene su propio sistema empresa).

Servidores ESX puros + items vanilla → no soportados oficialmente. Recomendamos ox_inventory.

### 11.6 Bridges con phone scripts

> **Tablet ≠ Phone.** Pero pueden coexistir. Bridge configurable para interoperabilidad de mensajes y contactos.

```lua
-- config/config.lua
Config.PhoneBridge = {
  enabled = false,                           -- por defecto separados
  phone_resource = 'lb-phone',               -- 'lb-phone' | 'qb-phone' | 'gksphone' | 'qs-smartphone'
  features = {
    sync_contacts = true,
    sync_messages = false,                   -- mensajes Admirals son profesionales — separados por default
    incoming_call_redirect = false,
  },
}
```

Cuando habilitado, el bridge:
- Se suscribe a eventos del phone resource (`lb-phone:contactAdded`, etc.).
- Replica como eventos Admirals.
- Provee API inversa (Admirals push → phone) si el phone soporta.

### 11.7 Bridges con sistemas bancarios externos

Algunos servidores tienen sistema bancario propio (Renewed-Banking, qb-banking).

```lua
Config.BankBridge = {
  mode = 'admirals_native',                  -- 'admirals_native' | 'shared_with_framework' | 'external_resource'
  external_resource = nil,
  sync_balance_with_framework = false,
}
```

- **`admirals_native`** (default): Banca Admirals usa su propia tabla `admirals_bank_accounts`. Las cuentas del framework (cash/bank de QBox) son **separadas**. Default seguro.
- **`shared_with_framework`**: la cuenta personal Admirals es alias de la cuenta `bank` del framework. Operaciones se reflejan en ambos.
- **`external_resource`**: delegación total a otro resource bancario. Bridge específico.

> **Comercialmente:** vendemos default `admirals_native`. Compatibilidad shared/external es upgrade Pro.

---

## 12. Persistence — patrones detallados

### 12.1 Reglas de oro

| Regla | Por qué |
|---|---|
| **Toda mutación pasa por una repo** | Single point of audit/log/cache |
| **Las repos exponen métodos por intención**, no queries | Cambio de schema no propaga al uso |
| **Prepared statements 100%** | Sin SQL injection nunca |
| **Transacciones en operaciones multi-tabla** | Atomicidad garantizada |
| **Estado caliente en RAM, fuente de verdad en DB** | Performance + recuperación |
| **Sync periódico RAM → DB** (debounce 1-5s) | Equilibrio entre fps y safety |

### 12.2 Patrón Repository

```lua
-- admirals_granja/server/repositories/repo_plot.lua
local PlotRepo = {}
local cache = {}                              -- in-memory cache por plot_id
local dirty = {}                              -- ids con cambios pendientes a flush

function PlotRepo.Get(plot_id)
  if cache[plot_id] then return cache[plot_id] end
  local row = MySQL.single.await(
    'SELECT * FROM admirals_farm_plots WHERE plot_id = ?',
    { plot_id }
  )
  if row then
    row.config = json.decode(row.config or '{}')
    cache[plot_id] = row
  end
  return row
end

function PlotRepo.UpdateStage(plot_id, new_stage, by_account_id)
  local plot = PlotRepo.Get(plot_id)
  if not plot then return false end
  plot.current_stage = new_stage
  plot.updated_at = os.time()
  dirty[plot_id] = true

  exports.admirals_core:GetBus().Publish('admirals:granja:plot_stage_changed', {
    plot_id = plot_id,
    new_stage = new_stage,
    by_account_id = by_account_id,
  })

  return true
end

-- Flush periódico
exports.admirals_core:RegisterCron('admirals:granja:plot_flush', { interval_seconds = 5 }, function()
  for plot_id, _ in pairs(dirty) do
    local p = cache[plot_id]
    if p then
      MySQL.update.await(
        'UPDATE admirals_farm_plots SET current_stage = ?, updated_at = ? WHERE plot_id = ?',
        { p.current_stage, p.updated_at, plot_id }
      )
    end
    dirty[plot_id] = nil
  end
end)

-- Flush forzado al apagar resource (resource:OnStop)
AddEventHandler('onResourceStop', function(name)
  if name == GetCurrentResourceName() then
    PlotRepo.FlushAll()
  end
end)

return PlotRepo
```

### 12.3 Transacciones multi-tabla

```lua
-- Ejemplo: crear empresa = insertar en admirals_companies + admirals_bank_accounts + admirals_company_members atomic
function CompanyService.Create(spec)
  return MySQL.transaction.await({
    {
      query = 'INSERT INTO admirals_bank_accounts (bank_account_id, iban, type, owner_id) VALUES (?,?,?,?)',
      values = { spec.bank_account_id, spec.iban, 'company', spec.company_id },
    },
    {
      query = 'INSERT INTO admirals_companies (company_id, vertical, name, owner_account_id, hq_location, bank_account_id, config) VALUES (?,?,?,?,?,?,?)',
      values = { spec.company_id, spec.vertical, spec.name, spec.owner, json.encode(spec.location), spec.bank_account_id, json.encode(spec.config) },
    },
    {
      query = 'INSERT INTO admirals_company_members (company_id, account_id, role, position, salary, permissions) VALUES (?,?,?,?,?,?)',
      values = { spec.company_id, spec.owner, 'owner', 'Founder', 0, json.encode({}) },
    },
  })
end
```

Si cualquiera falla, todo se revierte.

### 12.4 Migrations sistema completo

```lua
-- admirals_core/server/migrations.lua
local Migrations = {}

function Migrations.Run(resource_name, base_path)
  local current = MySQL.single.await(
    'SELECT version FROM admirals_schema_versions WHERE resource = ?',
    { resource_name }
  )
  local version = current and current.version or 0

  local files = ListMigrationFiles(base_path)  -- '001_x.sql', '002_x.sql', ...
  table.sort(files)

  for _, file in ipairs(files) do
    local n = ExtractVersionNumber(file)
    if n > version then
      local sql = ReadFile(base_path .. '/' .. file)
      MySQL.query.await(sql)
      MySQL.update.await(
        'INSERT INTO admirals_schema_versions (resource, version, applied_at) VALUES (?,?,NOW()) ON DUPLICATE KEY UPDATE version = ?',
        { resource_name, n, n }
      )
      print(('[admirals] migration %s applied for %s'):format(file, resource_name))
    end
  end
end

return Migrations
```

### 12.5 Backup y recovery

> **Recomendación a admins:** backup MySQL diario nativo + retención 30 días.

Admirals provee:
- **Comando admin** `/admirals export <resource>` → genera dump JSON de todas las tablas del resource (útil para migración entre servidores).
- **Comando admin** `/admirals integrity check` → verifica integridad referencial (foreign keys huérfanas, balances que no cuadran, etc.).

### 12.6 Particionado a escala

Cuando el servidor crezca (>500 jugadores activos / >100k filas en log):

| Tabla | Estrategia |
|---|---|
| `admirals_event_log` | Partitioning by month (ya en schema) + purge automático >90 días |
| `admirals_messages` | Archive table mensual (`admirals_messages_archive_YYYYMM`) |
| `admirals_bank_movements` | Partitioning by quarter |
| `admirals_notifications` | Auto-purge leídas + archived >30d |

Procesos de archivado son cron internos del `admirals_core`.

---

## 13. Performance global del ecosistema

### 13.1 Budgets server-side

| Métrica | Budget | Cómo se mide |
|---|---|---|
| **Server tick impact** (todos resources Admirals) | <5ms p95 | `txAdmin` resource monitor |
| **CPU per tick por resource** | <1ms p95 | profiling interno |
| **DB queries por minuto pico** | <500/min en server 100 jugadores | log slow queries (>50ms) |
| **Slow queries** (>100ms) | Cero en operación normal | alerting MySQL |
| **Eventos del bus por segundo** | <50/s sostenido (>200/s alerting) | counter interno |
| **RAM consumida por resource Admirals** | <128MB residente cada uno | server monitoring |

### 13.2 Patrones obligatorios para performance

#### A — Throttling de eventos high-frequency

```lua
local lastFire = 0
local THROTTLE = 1000  -- ms

function Plot.OnGrowthTick(plot_id, growth_data)
  local now = GetGameTimer()
  if now - lastFire < THROTTLE then return end
  lastFire = now

  Bus.Publish('admirals:granja:plot_growth_tick', { plot_id = plot_id, ... })
end
```

#### B — Batch updates en DB

```lua
-- Mal: N queries para N plots
for _, plot in ipairs(plots) do
  MySQL.update.await('UPDATE admirals_farm_plots SET ... WHERE plot_id = ?', { plot.plot_id })
end

-- Bien: 1 query con IN()
local ids = {}
for _, p in ipairs(plots) do table.insert(ids, p.plot_id) end
MySQL.update.await(
  'UPDATE admirals_farm_plots SET stage = ? WHERE plot_id IN ('..GeneratePlaceholders(#ids)..')',
  { new_stage, table.unpack(ids) }
)
```

#### C — Lazy loading

- Cuentas, empresas, plots se cargan **on-demand** al primer acceso.
- Datasets grandes (libro contable mes, mensajes históricos) **paginados** en NUI.

#### D — Broadcast targeted, no global

```lua
-- Mal: TriggerClientEvent(eventName, -1, payload)  -- broadcast a TODOS
-- Bien: TriggerClientEvent(eventName, target_src, payload) -- solo al jugador interesado
-- Para una empresa: iterar sobre sus miembros y enviar a cada src activo.
```

### 13.3 Streaming de assets

- Los assets 3D (MLO, props, vehículos) se **streamean por zona**:
  - Granja Grapeseed → solo se carga si jugador está cerca.
  - Molino Paleto → solo se carga si jugador está cerca.
  - Tablet prop → siempre cargada (se usa en todo el mapa).
- Reduce VRAM y tiempo de carga inicial.

### 13.4 Throughput de servidores grandes (200+ jugadores)

> **Admirals diseñado para escalar a servidores grandes.** Aquí los patrones no negociables:

- **Sharding lógico por vertical:** la lógica de Granja procesa solo plots de granjas activas con jugadores cerca.
- **Idle entities pause:** un molino sin jugadores cerca durante >5 min entra en estado idle (sin tick, sin sync).
- **Cache por zona:** datos de empresas se cargan al entrar a zona, se descargan al salir + 5 min grace.
- **DB read replicas** (modo enterprise opcional): admins con mucho tráfico pueden configurar read replica MySQL para queries pesadas (Manager Panel).

### 13.5 Monitoring y alerting

Resource `admirals_core` expone métricas via:
- Comando admin `/admirals stats` → snapshot.
- Endpoint HTTP local `/admirals/metrics` → formato Prometheus (oleada 2).
- Webhooks Discord opcionales para alerts críticas (caja insuficiente generalizada, slow queries, errores).

---

## 14. Testing strategy

### 14.1 Niveles

| Nivel | Qué se testea | Herramienta | Coverage objetivo |
|---|---|---|---|
| **Unit** | Funciones puras (cálculo calidad, validadores, formatters) | Lua busted / Vitest (NUI) | 80%+ funciones críticas |
| **Integration server** | Repos + DB en sandbox MySQL | Lua busted + MySQL test db | 60%+ servicios |
| **Integration NUI ↔ Lua** | Bridge NUI: intent → callback | Test harness con stub | 100% callbacks expuestos |
| **End-to-End in-game** | Escenarios completos en server de pruebas | Playwright + cliente headless FiveM | Smoke tests por feature |
| **Performance** | Budgets de §13 | benchmark scripts | Sin regresión por commit |

### 14.2 Test harness para resource Lua

```lua
-- spec/quality_spec.lua
describe('Quality.ComputeFarm', function()
  it('produces grade S for perfect inputs', function()
    local result = Quality.ComputeFarm({
      soil_score = 100,
      irrigation_score = 100,
      fertilization_score = 100,
      pest_control_score = 100,
      seed_quality = 100,
      weather_score = 100,
    }, { timing_score = 100 })
    assert.equals('S', result.grade)
    assert.is_true(result.score >= 90)
  end)

  it('produces grade D for terrible inputs', function()
    local result = Quality.ComputeFarm({
      soil_score = 10,
      irrigation_score = 0,
      fertilization_score = 5,
      pest_control_score = 0,
      seed_quality = 30,
      weather_score = 20,
    }, { timing_score = 10 })
    assert.equals('D', result.grade)
  end)
end)
```

### 14.3 Tests de integración con DB de prueba

CI levanta MySQL contenedor → ejecuta migrations Admirals → corre tests de integration sobre repo + service.

```lua
describe('CompanyService.Create', function()
  before_each(function()
    TestDB.Reset()
    TestDB.RunAdmiralsMigrations()
  end)

  it('creates company with bank account atomically', function()
    local result = CompanyService.Create({
      vertical = 'farm',
      name = 'Test Farm',
      owner = 'test-account-1',
      ...
    })
    assert.is_true(result.ok)

    local company = CompanyRepo.Get(result.company_id)
    local bank = BankRepo.Get(company.bank_account_id)
    assert.is_not_nil(company)
    assert.is_not_nil(bank)
    assert.equals('farm', company.vertical)
  end)

  it('rolls back on bank account failure', function()
    -- forzar fallo en bank insertion
    ...
    assert.equals(0, CompanyRepo.CountAll())
  end)
end)
```

### 14.4 Tests de NUI (React + Vitest)

```ts
// nui/src/apps/bank/__tests__/transfer.test.ts
import { render, screen, fireEvent } from '@testing-library/react';
import { TransferForm } from '../TransferForm';
import { mockNuiBridge } from '../../../test/mocks';

test('disables submit when amount is zero', () => {
  render(<TransferForm fromAccount="AD-1" availableAccounts={[{ iban: 'AD-2' }]} />);
  fireEvent.change(screen.getByLabelText('Importe'), { target: { value: '0' } });
  expect(screen.getByRole('button', { name: 'Transferir' })).toBeDisabled();
});

test('emits intent via bridge on submit', async () => {
  const post = mockNuiBridge();
  render(<TransferForm ... />);
  fireEvent.change(screen.getByLabelText('Importe'), { target: { value: '500' } });
  fireEvent.click(screen.getByRole('button', { name: 'Transferir' }));
  expect(post).toHaveBeenCalledWith('app:bank:transfer', expect.objectContaining({ amount: 500 }));
});
```

### 14.5 Smoke tests E2E

Servidor de pruebas con `txAdmin` corriendo + scripts auto-piloto que simulan:
- Login de cuenta Admirals.
- Apertura de Tablet.
- Creación de empresa (Granja).
- Siembra → cosecha (etapas aceleradas).
- Venta a NPC bridge molino.
- Pago automático.

Pasa o falla el commit en CI.

### 14.6 Test Wooow

> **Bible §1: el Test Wooow es objetivo, no subjetivo.** Para cerrar una feature:

| Pregunta | Pasa si |
|---|---|
| ¿Es físico? | El jugador hace una acción en el mundo, no un click en menú flotante |
| ¿Sale del marco esperado por la competencia? | Sí — es algo que ningún script FiveM tiene |
| ¿Funciona el primer try? | Sí — sin tutorial intuir cómo se usa |
| ¿Otros jugadores lo notan? | Sí — la acción es visible |
| ¿Sentirías orgullo de mostrarlo en YouTube? | Sí — pasa el corazón de la marca |
| ¿Está documentado en su doc de diseño? | Sí — tiene su sección con assets 3D, código, animaciones, sonidos definidos |

Cualquier "no" → no se publica.

---

## 15. Deployment y packaging

### 15.1 Pipeline desde dev hasta server cliente

```
[Developer commit]
    ↓
[CI: lint + unit + integration tests + build NUI]
    ↓
[Tag SemVer release: admirals_<resource>_X.Y.Z]
    ↓
[Build artifact: zip con resource listo, NUI bundled]
    ↓
[Distribución: Tebex (one-time), licensing portal (annual/sub)]
    ↓
[Server admin descarga zip + extrae a resources/]
    ↓
[Server admin añade `ensure admirals_core` etc. a server.cfg]
    ↓
[Server admin edita config/config.lua]
    ↓
[Inicia el servidor → migrations corren automáticas → ready]
```

### 15.2 Empaquetado de un release

```
admirals_<resource>_1.0.0.zip
├── admirals_<resource>/             ← carpeta lista para resources/
│   ├── fxmanifest.lua
│   ├── server/, client/, nui/dist/, ...
│   ├── config/config.example.lua    ← admin renombra a config.lua
│   ├── migrations/
│   └── ...
├── INSTALL.md                       ← pasos paso a paso
├── CHANGELOG.md                     ← qué cambió desde versión anterior
├── LICENSE.txt                      ← términos comerciales
└── README.md
```

> **Las NUI llegan ya buildeadas** (`nui/dist/`). El admin no necesita Node ni npm.

### 15.3 Verificación de licencia

Cada resource Admirals verifica la licencia del servidor al arrancar:

```lua
exports.admirals_core:VerifyLicense({
  resource = 'admirals_granja',
  license_key = Config.LicenseKey,        -- entregada por el portal de Admirals
})
```

- **Online check** opcional (1 vez por hora) contra el endpoint Admirals.
- **Offline grace period:** si no hay internet, sigue funcionando 7 días.
- **Modo dev/staging:** licencia "DEV" gratis para testing.
- **Anti-piratería ligera:** verificación de hash del bundle. No invasiva — el cliente ético funciona perfectamente; el pirata pierde features online (Mercado público, futuros SDK apps).

### 15.4 Compatibilidad de versiones

```lua
-- En cada fxmanifest.lua
admirals_min_core_version '1.0.0'
admirals_max_core_version '1.x.x'
```

Si un servidor tiene `admirals_core 2.0.0` (breaking) y `admirals_granja` solo declara compatibilidad con `1.x.x` → el granja no arranca y emite error claro.

### 15.5 Migration de datos entre versiones

Cuando una oleada minor introduce nuevas tablas/columnas, las migrations corren automáticas. Cuando una **major** introduce cambios incompatibles:
- Documentación explícita de cambios.
- Script de migración que el admin ejecuta (`exports.admirals_core:MigrateMajor('1.x.x', '2.0.0')`).
- Backup forzado antes de aplicar.
- Rollback documentado por si falla.

### 15.6 Configuración estructurada

```lua
-- admirals_granja/config/config.example.lua
Config = {
  ServerSettings = {
    Locale = 'es',
    Currency = '$',
    TimeZone = 'Europe/Madrid',
  },

  Branding = {
    ServerName = 'Tu Servidor',
    ServerLogo = 'images/your_logo.png',
    BootSplash = 'images/your_splash.png',  -- aparece antes del logo Admirals
  },

  Granja = {
    Mode = 'default',  -- 'sprint' | 'default' | 'realista' | 'hardcore'
    EnableHorticulture = true,
    EnableGreenhouses = true,
    SeasonDurationHours = 6,
    Locations = {
      { id = 'farm_grapeseed', enabled = true,  config_path = 'maps/grapeseed.lua' },
      { id = 'farm_paleto',    enabled = false, config_path = 'maps/paleto.lua' },
    },
  },

  Crops = require('config/config_crops'),  -- catálogo separado para limpieza
  Machinery = require('config/config_machinery'),
  Contracts = require('config/config_contracts'),
}
```

---

## 16. Seguridad y anti-cheat

### 16.1 Principio cero: el cliente miente

> **Toda decisión que afecte estado debe validarse server-side.** Sin excepciones.

### 16.2 Patrones obligatorios

| Patrón | Implementación |
|---|---|
| **Validación de origen físico** | Antes de procesar acción, server verifica que el ped del jugador está cerca del prop relevante |
| **Validación de permisos** | `Company.HasPermission` antes de cada acción empresarial |
| **Rate limiting por jugador** | Acciones con coste (transferencias, contratos) limitadas a N por minuto |
| **Validación de payload** | Schema Zod-equivalente Lua en cada handler de evento |
| **Audit log** | Toda mutación crítica → entry en `admirals_event_log` |
| **Detección de inconsistencias** | Cron de integridad detecta balances negativos sin causa, lineage roto, etc. |
| **No exponer ids internos en NUI** sin necesidad | minimiza superficie ataque |

### 16.3 Ejemplo: validación de transferencia bancaria

```lua
RegisterNetEvent('admirals:bank:transfer_requested', function(data)
  local src = source

  -- 1. Identidad
  local account_id = Bridge.GetAccountId(src)
  if not account_id then return end

  -- 2. Schema
  if not Validators.BankTransfer(data) then
    return Logger:Warn('Invalid transfer payload from '..account_id)
  end

  -- 3. Rate limit
  if not RateLimit.Check(account_id, 'bank_transfer', 5, 60) then
    return SendNotif(src, 'Demasiadas transferencias seguidas. Espera un momento.')
  end

  -- 4. Permisos sobre cuenta origen
  if not Bank.CanOperateAccount(account_id, data.from) then
    return Logger:Warn('Unauthorized transfer attempt by '..account_id)
  end

  -- 5. Saldo suficiente
  local from = BankRepo.Get(data.from)
  if from.balance < data.amount then
    return SendCallback(src, 'admirals:bank:transfer_failed', { reason = 'insufficient_funds' })
  end

  -- 6. Cuenta destino existe
  if not BankRepo.GetByIban(data.to) then
    return SendCallback(src, 'admirals:bank:transfer_failed', { reason = 'unknown_destination' })
  end

  -- 7. Importe positivo finito
  if data.amount <= 0 or data.amount > 10000000 then
    return Logger:Warn('Suspicious transfer amount: '..data.amount)
  end

  -- 8. Ejecutar transacción atómica
  local ok, err = Bank.TransferAtomic(data.from, data.to, data.amount, data.concept, account_id)

  -- 9. Notificar resultado
  if ok then
    Bus.Publish('admirals:bank:transfer_completed', { ... })
    SendCallback(src, 'admirals:bank:transfer_completed', { ok = true })
  else
    SendCallback(src, 'admirals:bank:transfer_failed', { reason = err })
  end
end)
```

### 16.4 Protección contra exploits comunes

| Exploit típico FiveM | Mitigación Admirals |
|---|---|
| **Item duplication** | ox_inventory + validación server de movimientos + audit log |
| **Money exploit** | Toda mutación de balance pasa por Bank.* con transacción + audit |
| **Position teleport** | Validación de distancia ped ↔ prop antes de cualquier acción física |
| **Stat spoofing** | Stats Admirals (calidad, productividad, reputación) calculadas server-side |
| **NUI injection** | NUI callbacks validan payloads + sanitización de strings |
| **Replay attacks** | Cada acción tiene `nonce + timestamp` validado |

### 16.5 Privacidad de datos

- Datos personales del jugador (mensajes privados, notas, balances) **nunca** se envían a clientes que no sean el dueño.
- Logging respeta GDPR-equivalent — los logs no contienen datos sensibles innecesarios.
- Comando admin para que un jugador **exporte sus datos** (descarga JSON) o **solicite borrado** (anonimización en DB manteniendo integridad referencial).

---

## 17. Logging y observability

### 17.1 Niveles de log

```lua
local Logger = exports.admirals_core:GetLogger('admirals_granja')

Logger:Trace('Plot growth tick: '..plot_id)         -- desactivado por default
Logger:Debug('Stage transition: '..from..' -> '..to) -- activo solo en dev
Logger:Info('Plot harvested: '..plot_id..' batch '..batch_id)
Logger:Warn('Unauthorized action by '..account_id)
Logger:Error('Failed to publish event: '..err)
Logger:Fatal('Migration failed, aborting boot')
```

### 17.2 Destinos de log

| Destino | Default | Configurable |
|---|---|---|
| **Consola del servidor** | Sí | Niveles |
| **Archivo `logs/admirals_<resource>.log`** | Sí | Niveles + rotación |
| **`admirals_event_log` tabla** | Solo eventos del bus | Verbosidad por evento |
| **Discord webhook** | No | URL admin + niveles |
| **Endpoint HTTP custom** | No | URL admin (oleada 2) |

### 17.3 Eventos relevantes para auditoría (siempre logueados)

- Creación / venta de empresa.
- Transferencias bancarias > umbral configurable.
- Cambios de role (promote/demote/fire).
- Firma de contratos.
- Quiebras y administración.
- Errores de integridad.

### 17.4 Métricas observable (oleada 2 — Prometheus exporter)

```
admirals_active_companies{vertical="farm"} 12
admirals_active_companies{vertical="mill"} 4
admirals_pending_orders_total 47
admirals_event_bus_publishes_total{event="harvest_completed"} 312
admirals_event_bus_subscribers_lag_ms{event="state_change",p99} 42
admirals_db_query_duration_ms{query="GetPlot",p95} 8
admirals_player_tablets_open 23
```

### 17.5 Comandos de diagnóstico para admins

```
/admirals stats                        -- snapshot general
/admirals integrity check              -- verificar integridad referencial
/admirals integrity fix --dry-run      -- propuesta de reparación sin aplicar
/admirals event_log tail --filter ...  -- live tail de eventos
/admirals slow_queries                 -- top 10 queries lentas última hora
/admirals reload_config <resource>     -- recargar config sin restart
```

---

## 18. Versionado y compatibilidad

### 18.1 SemVer aplicado

> Cada resource Admirals sigue SemVer estricto. Las oleadas afectan a MINOR.

| Cambio | Bump |
|---|---|
| Fix sin cambio comportamiento | PATCH (ej. 1.2.3 → 1.2.4) |
| Nueva feature backward-compatible | MINOR (ej. 1.2.3 → 1.3.0) |
| Oleada 2 / 3 (nuevos cultivos, drones, etc.) | MINOR |
| Cambio en bus eventos / schema DB / config breaking | MAJOR (ej. 1.5.0 → 2.0.0) |

### 18.2 Compatibilidad cross-resource

Cada resource declara:

```lua
admirals_min_core_version '1.0.0'
admirals_max_core_version '1.x.x'
admirals_min_tablet_version '1.0.0'
```

`admirals_core` al arrancar verifica todos los resources Admirals cargados. Si algún resource es incompatible:
- Mensaje claro al admin: *"admirals_granja v1.5.0 requiere admirals_core 2.x.x. Actualiza o downgrade."*
- El resource incompatible no carga.

### 18.3 Deprecation policy

- Los eventos del bus y APIs públicas se mantienen **al menos 2 versiones MINOR** después de su deprecación.
- Deprecation se anuncia en CHANGELOG + warning en logs cuando se usan.

### 18.4 Roadmap de versiones

```
admirals_core:
  1.0.0  → Lanzamiento (cuentas, empresa, banca, item físico, bus, notif)
  1.1.0  → Oleada 2 (mensajes voz, robos, llamadas inter-tablet)
  1.2.0  → Oleada 3 (SDK público, OCR, modo facial)
  2.0.0  → Reescritura major (si necesaria — esperamos 5+ años)

admirals_tablet:
  1.0.0  → Lanzamiento (8 apps, dock, render target)
  1.1.0  → Oleada 2
  1.2.0  → Oleada 3 (SDK + apps comunidad)

admirals_granja:
  1.0.0  → Lanzamiento (12 cultivos, MLO, ciclo completo)
  1.1.0  → Oleada 2 (centeno, avena, girasol, caña, compostaje, granizo, robos)
  1.2.0  → Oleada 3 (drones agrícolas, cooperativa, exportación)
```

---

## 19. SDK público para apps de terceros (oleada 3)

### 19.1 Visión

> **Admirals como plataforma:** developers externos crean apps que se instalan en la Tablet, distribuidas vía Tienda Admirals.

Esto convierte a Admirals en algo que ningún competidor tiene: **una plataforma con ecosistema**. A largo plazo (años 3-5), revenue share con devs.

### 19.2 Anatomía de una app de terceros

```
my_external_app/
├── manifest.json                    -- declaración de la app
├── icon.svg
├── locales/
│   └── es.json
├── nui/dist/                        -- bundle JS + CSS
└── server/                          -- (opcional) lógica server propia
    └── handlers.lua
```

### 19.3 Manifest de app

```json
{
  "app_id": "com.example.delivery_tracker",
  "name_key": "delivery.app_name",
  "icon_url": "icon.svg",
  "vertical": "logistics",
  "publisher": "Example Studios",
  "version": "1.0.0",
  "min_admirals_tablet_version": "1.2.0",
  "permissions_required": [
    "read:deliveries",
    "push:notifications",
    "intent:bank_transfer"
  ],
  "component_url": "nui/dist/main.js",
  "schema_version": 1
}
```

### 19.4 API expuesta a apps externas

```ts
// SDK público (TypeScript declarations entregadas a developers)
declare global {
  interface AdmiralsSDK {
    // Lectura (con permisos)
    deliveries: {
      list(filter: DeliveryFilter): Promise<Delivery[]>;
      subscribe(filter: DeliveryFilter, cb: (d: Delivery) => void): Unsubscribe;
    };
    // Intents (server valida)
    intents: {
      bankTransfer(params: TransferParams): Promise<TransferResult>;
      pushNotification(params: NotifParams): Promise<void>;
    };
    // UI helpers
    ui: {
      toast(message: string, kind?: 'info' | 'success' | 'warn' | 'error'): void;
      confirm(title: string, message: string): Promise<boolean>;
    };
    // i18n
    t(key: string): string;
  }
  const admirals: AdmiralsSDK;
}
```

### 19.5 Sandboxing y seguridad

- **Permisos declarativos:** la app declara qué permisos necesita en manifest. El usuario los aprueba al instalar.
- **Sin acceso DB directo:** todo pasa por SDK que valida server-side.
- **Sin acceso a otras apps' data** sin permiso explícito.
- **Code signing:** apps publicadas en Tienda Admirals están firmadas. Apps sideloaded por server admin requieren modo `dev` activado.

### 19.6 Distribución y monetización

- **Tienda Admirals oficial** con sección "Apps de la comunidad".
- **Curado:** Admirals revisa cada app antes de publicar.
- **Modelos de cobro:** gratuitas, one-time, suscripción.
- **Revenue share:** Admirals retiene un % por procesamiento + curaduría.

---

## 20. Roadmap técnico

### 20.1 Hitos técnicos

| Hito | Descripción | Estado |
|---|---|---|
| **T0** | Diseño firmado de Granja, Tablet, Molino | ✅ Completado (mayo 2026) |
| **T1** | Architectura técnica firmada | 🟡 En revisión (este doc) |
| **T2** | `admirals_core` v1.0.0 funcional (bus, bridges, DB, item físico, empresa, banca) | Pendiente |
| **T3** | `admirals_tablet` v1.0.0 — boot + home + 4 apps base (Empresa, Banca, Mensajes, Settings) | Pendiente |
| **T4** | `admirals_tablet` completo — 8 apps + dock + inter-tablet | Pendiente |
| **T5** | `admirals_granja` v1.0.0 — vertical slice jugable (1 cultivo end-to-end) | Pendiente |
| **T6** | `admirals_granja` v1.0.0 completo (12 cultivos + ciclo) | Pendiente |
| **T7** | `admirals_molino` v1.0.0 completo | Pendiente |
| **T8** | `admirals_panaderia` v1.0.0 — pendiente diseño | Pendiente |
| **T9** | `admirals_retail` v1.0.0 — pendiente diseño | Pendiente |
| **M4 — Beta cerrada** | Test en servidor propio + 10 testers comunidad | Pendiente |
| **M5 — Lanzamiento Tebex** | Cadena del Pan v1.0.0 pública | Pendiente |
| **Oleada 2** | Update gratis 2-3 meses post-lanzamiento | Año 1 |
| **Oleada 3** | Drones, SDK público | Año 1-2 |

### 20.2 Decisiones técnicas pendientes (registro vivo)

| # | Decisión | Estado | Notas |
|---|---|---|---|
| D-01 | Render target Tablet — método exacto (NamedRendertarget vs scaleform) | Abierta | Prototipar ambos en T2 |
| D-02 | NUI: Vite dev server in-game o solo build estático | Decidida | Solo build estático (consistencia y perf) |
| D-03 | Idioma config — toml/yaml vs lua | Decidida | Lua (consistencia con stack) |
| D-04 | Backup automatizado built-in vs delegar al admin | Abierta | Probable: provisión, pero responsabilidad del admin |
| D-05 | Validación de licencia online — frecuencia | Abierta | 1h por defecto, configurable |
| D-06 | SDK lenguaje recomendado terceros | Decidida | TypeScript canónico, JS soportado |
| D-07 | Anti-cheat externo (FiveM ACE) — usar o no | Abierta | Probable: opcional, no requerido |

### 20.3 Métricas de éxito técnico

A medir en M5 (lanzamiento):

- ✅ <5ms tick impact en server con 100 jugadores activos.
- ✅ <2s boot Tablet en 99% jugadores.
- ✅ Cero data loss en simulación de 24h con 50 jugadores activos.
- ✅ Cero exploit conocido sin parche.
- ✅ <0.1% crash rate (servidores compatibles).

---

## 21. Estado del documento

- **Versión:** 1.0 (firmado).
- **Próxima revisión:** evolución según nuevas verticales.
- **Documentos derivados pendientes:**
  - `02_events_catalog.md` — catálogo completo de eventos `admirals:*` con schemas validation.
  - `03_db_schema.md` — DDL completo + ERD visual.
  - `04_sdk_reference.md` (oleada 3) — referencia del SDK público.
  - `05_deployment_guide.md` — guía paso a paso para admins de servidor.
  - `06_security_handbook.md` — patrones detallados de seguridad + checklist auditoría.
- **Documentos relacionados de diseño:**
  - `01_node_farm.md` v1.1 — Granja (consume esta arquitectura).
  - `02_admirals_tablet.md` v1.0 — Tablet (consume esta arquitectura).
  - `03_node_mill.md` v1.0 — Molino (consume esta arquitectura).

---

## Resumen ejecutivo del documento (cierre)

Este documento es **el contrato técnico** que debe respetar todo el código de Admirals.

**Pilares técnicos cumplidos:**

- ✅ **Bible §13.3 (Arquitectura completa, contenido en oleadas):** la arquitectura aquí descrita soporta de día 1 todas las features de oleadas O1, O2, O3 sin reescritura. Añadir centeno, drones o un nodo nuevo (Cervecería) será siempre **añadir config + asset**, nunca rediseñar.
- ✅ **Bible §13.4 (3D vs Código):** la responsabilidad del código (shaders, partículas, post, lighting, swap dinámico, lógica) está claramente separada de la responsabilidad del 3D. El código no tiene límite — esta arquitectura le da el poder.
- ✅ **Pilar 1 (Físico):** la arquitectura **fuerza** validaciones de origen físico. Sin proximidad al prop, no hay acción.
- ✅ **Pilar 2 (Cadena):** Item Físico universal + lineage automático = trazabilidad completa upstream→downstream sin acoplamiento entre nodos.
- ✅ **Pilar 3 (Detalle):** budgets de performance permiten obsesión sin penalizar fps.
- ✅ **Pilar 4 (Assets propios):** streaming por zona reduce coste de assets propios.
- ✅ **Pilar 5 (Tablet):** NUI única + render target vivo + sandboxing = la Tablet es plataforma, no menú.

**Decisiones críticas locked:**

- Stack canónico: FiveM + Lua + QBox primario + ox_* + React+TS+Vite+Tailwind+Framer+Lucide.
- DB: MySQL/MariaDB + oxmysql + prepared statements 100% + migrations versionadas.
- Bus de eventos `admirals:*` como única vía de comunicación inter-resource.
- Item Físico universal con lineage acumulativo.
- Server-authoritative absoluto.
- SemVer estricto + compatibilidad declarada cross-resource.
- SDK público planeado para oleada 3 — Admirals como plataforma.

**Esta arquitectura es para un producto de 5-10 años en el mercado.**

---

*"Architect once. Build forever."*
