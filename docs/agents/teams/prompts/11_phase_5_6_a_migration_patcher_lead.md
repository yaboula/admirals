---
prompt_id: 11_phase_5_6_a_migration_patcher_lead
title: Phase 5.6.A — Build Automated Migration Patcher (Path A automated, qb-* → SONAR exports)
phase: BANK-BE.PHASE_5.6.A — Patcher implementation + test fixtures
preceded_by: BANK-BE.PHASE_5.5 (manual probe in-isolation 22 exports)
supersedes_partial: 10_phase_5_cross_script_sync_lead.md (Path E descartado, paragraph 8.5 de prompt 10)
emitted_by: PM Cascade
emitted_at: 2026-05-13 05:10 UTC+02
authority: Founder yaboula architectural decision 2026-05-13 05:00 UTC+02 — "Path A AUTOMATIZADO mediante herramientas de migración. Cero lógica de sincronización reactiva en qb-core. Sustitución limpia y directa del código viejo." + Founder principle "cuando reducimos mas trabajo es mucho mejor" (delegar work a herramienta, no a runtime sync). Doctrine SONAR authoritative master + Q4 LOCKED preserved.
status: ACTIVE — awaiting Product Engineer + Backend Lead spawn
spec: progress/MIGRATION_PATTERNS.md (LOCKED v1.0)
---

# Mission — BANK-BE.PHASE_5.6.A — Automated Migration Patcher

## 1. Context summary

Founder ratificó Path A automatizado. Patcher determinístico Python sustituye estáticamente `Player.Functions.AddMoney/RemoveMoney('bank', ...)` en los 56 qb-* resources del server por `exports.sonar_bank_app:AddMoney/RemoveMoney(...)` canónicos. **Cero lógica reactiva runtime. Cero contract amendment. Cero re-introduction Phase 3 complexity.**

Path E (passive listener) fue **descartado** post self-correction PM Cascade 2026-05-13 04:50 UTC+02 (loop risk via MirrorSync echo = same Phase 3 error reframed). Path B (re-Pre-Hook) descartado Q4. Path C (hybrid) descartado audit gap. Path D (defer + disclaimer) descartado por founder concern "seguramente falla".

## 2. Inputs lectura obligatoria

1. **`progress/MIGRATION_PATTERNS.md`** — spec técnica completa LOCKED v1.0 (este prompt complementa, no duplica).
2. **`docs/technical/bank_phase_a/c_be_02_api_contracts_v1_3.md`** — 22 exports surface canonical.
3. **`resources/sonar_bank_app/server/api/public_api.lua:337-351`** + **`admin_api.lua:220-229`** — exports actuales emitidos.
4. **`docs/agents/teams/decisions/founder_phase_5_pivot_q1_q8_2026_05_12.md`** — Q4 LOCKED context.
5. **MEMORY[dc00d46d]** — QBCore docs URL canonical para verificar Player.Functions semantics.
6. Real source code samples: `D:\FiveM_Server\Sonar\resources\[qb]\` (especialmente qb-vehicleshop, qb-shops, qb-pawnshop, qb-houses, qb-vehiclesales, qb-drugs).

## 3. Authority + boundary

### ✅ Permitido

- Crear directorio `tools/migration_patcher/` en repo workspace `d:\theBigProject\tools\migration_patcher\` con:
  - Python package: `patcher/` (modules: `__main__.py`, `cli.py`, `patterns.py`, `binding_resolver.py`, `transformer.py`, `fxmanifest_injector.py`, `report.py`)
  - Tests: `tests/` con fixture corpus `.in` + `.expected` files
  - `requirements.txt`, `README.md`, `pyproject.toml` opcional
  - GitHub Actions workflow opcional `.github/workflows/migration_patcher_tests.yml` (Phase B)
- Ejecutar `--dry-run` contra `D:\FiveM_Server\Sonar\resources\[qb]\` (sandbox snapshot only — NO `--apply` en server real esta sub-fase)
- Generar `migration_output/` artifacts en sandbox `D:\theBigProject\sandbox_migration_output\` (gitignored)
- Iterar pattern detection regex + binding resolver hasta golden tests verde
- Emitir progress notes en `progress/PHASE_5_6_A_PATCHER_PROGRESS.md`

### ❌ Prohibido sin escalation founder

- `--apply` contra `D:\FiveM_Server\Sonar\resources\[qb]\` directo (sub-fase 5.6.C scope post Backend Lead curation 5.6.B)
- Tocar contracts SSoT LOCKED v1.0.2 R2
- Tocar exports surface `resources/sonar_bank_app/` (los 22 exports están LOCKED)
- Tocar qb-core mainline (`D:\FiveM_Server\Sonar\resources\[qb]\qb-core\`) — patcher NO modifica qb-core, solo downstream qb-* que LLAMAN qb-core
- Phase B scope (cash/crypto/qb-banking/qb-inventory/ox_inventory) — disabled por defecto en patcher v1, opt-in flag Phase B
- Inyectar runtime listeners / hooks / shims — Path E descartado, no resuscitar

## 4. Pre-flight checklist

- [ ] Pull branch `feature/bank-security-phase-a` HEAD post-`dd94f75`
- [ ] Verificar `progress/MIGRATION_PATTERNS.md` exists (spec base)
- [ ] Sandbox snapshot: `Copy-Item -LiteralPath 'D:\FiveM_Server\Sonar\resources\[qb]' -Destination 'D:\theBigProject\sandbox_qb_snapshot' -Recurse` (gitignored, ~500MB read-only test corpus)
- [ ] Python 3.11+ installed + venv `tools/migration_patcher/.venv` (gitignored)
- [ ] Verificar branch `feature/bank-security-phase-a` checkout

## 5. Deliverables sub-fase 5.6.A

### 5.1 Python patcher module structure

```
tools/migration_patcher/
├── README.md                    # Usage + architecture overview
├── requirements.txt             # python deps (regex, click, pydantic, pytest)
├── pyproject.toml               # opt
├── .gitignore                   # .venv, sandbox_*, migration_output
├── patcher/
│   ├── __init__.py
│   ├── __main__.py              # entry point: python -m patcher
│   ├── cli.py                   # click CLI: --dry-run/--apply/--filter-resource/--money-types/--rollback
│   ├── patterns.py              # S1-S4 + U1-U9 regex compiled + metadata
│   ├── binding_resolver.py      # GetPlayer/GetOfflinePlayer scope analyzer
│   ├── transformer.py           # main pattern apply + replacement template
│   ├── fxmanifest_injector.py   # dependency 'sonar_bank_app' injection
│   ├── report.py                # auto_patched.md / manual_review.md / summary.json emitters
│   └── safety.py                # marker detection, idempotent re-run, double-shift guard
├── tests/
│   ├── __init__.py
│   ├── conftest.py              # pytest fixtures
│   ├── fixtures/
│   │   ├── qb_shops_main.in.lua
│   │   ├── qb_shops_main.expected.lua
│   │   ├── qb_vehicleshop_server.in.lua
│   │   ├── qb_vehicleshop_server.expected.lua
│   │   ├── qb_pawnshop_main.in.lua
│   │   ├── qb_pawnshop_main.expected.lua
│   │   ├── qb_houses_main.in.lua
│   │   ├── qb_houses_main.expected.lua
│   │   ├── qb_vehiclesales_main.in.lua
│   │   ├── qb_vehiclesales_main.expected.lua
│   │   ├── qb_drugs_cornerselling.in.lua    # cash only → U1
│   │   ├── qb_drugs_cornerselling.expected.lua
│   │   ├── fxmanifest_no_deps.in.lua
│   │   ├── fxmanifest_no_deps.expected.lua
│   │   ├── fxmanifest_existing_deps.in.lua
│   │   ├── fxmanifest_existing_deps.expected.lua
│   │   └── fxmanifest_already_present.in.lua    # idempotent
│   ├── test_patterns.py         # S1-S4 + U1-U9 detection regex unit tests
│   ├── test_binding_resolver.py # scope analyzer
│   ├── test_transformer.py      # full input → output golden tests per fixture
│   ├── test_fxmanifest.py       # injection variations
│   ├── test_safety.py           # marker, idempotent, double-shift
│   ├── test_cli.py              # CLI flags + summary.json schema
│   └── test_report.py           # output formats
└── docs/
    ├── ARCHITECTURE.md
    ├── PATTERNS.md              # cross-link a progress/MIGRATION_PATTERNS.md
    └── USAGE.md
```

### 5.2 Test corpus extracted from real server

Backend Lead extrae snippets reales de los 6 resources CRITICAL/HIGH del scan:
- qb-vehicleshop/server.lua (20 hits)
- qb-drugs/{cornerselling,deliveries}.lua (7 hits cash → U1)
- qb-shops/main.lua (5 hits mixed)
- qb-vehiclesales/main.lua (3 hits bank)
- qb-pawnshop/main.lua (2 hits mixed)
- qb-houses/main.lua (2 hits bank)

Para cada uno: 1 fixture `.in.lua` (verbatim copy) + 1 `.expected.lua` (golden) construido manualmente Backend Lead siguiendo §6 SAFE patterns spec.

### 5.3 CLI specification (click-based)

```
python -m patcher [OPTIONS] <SOURCE_DIR>

Options:
  --dry-run              Generate diffs + reports without modifying files (default)
  --apply                Apply patches with .bak backup
  --filter-resource TEXT Glob pattern to filter resources (e.g. "qb-*shop")
  --money-types TEXT     Comma-separated: bank,cash,crypto (default: bank)
  --output-dir PATH      Output directory (default: ./migration_output)
  --rollback             Restore .bak files
  --no-color             Disable ANSI color
  --verbose              Debug logging
  --help                 Show help
```

### 5.4 Reports per spec §11

- `migration_output/auto_patched.md` — markdown inventory entries per §11.3
- `migration_output/manual_review.md` — markdown catalog per §11.4 ordered by severity (CRITICAL → HIGH → MEDIUM → INFO)
- `migration_output/summary.json` — schema validated per §11.2
- `migration_output/<resource>/<file>.diff` — unified diff format (compatible with `git apply`)
- `migration_output/<resource>/<file>.bak` — only if `--apply`

### 5.5 Test coverage targets

- ≥85% line coverage `patcher/` modules
- 100% pattern coverage S1-S4 + U1-U9 (each pattern has ≥1 fixture)
- 100% CLI flag coverage
- Idempotent re-run test (apply 2x = no diff)
- Rollback test (apply → rollback → identical to original)
- summary.json schema validation pydantic

## 6. Implementation guidance Backend Lead + Product Engineer

### 6.1 Sequencing recomendado

1. **Hour 0-1:** repo skeleton + `requirements.txt` + `pyproject.toml` + `.gitignore` + venv setup + initial pytest scaffolding
2. **Hour 1-2:** `patterns.py` con regex S1+S2+S3 + U1-U9 detection (without replacement) + unit tests pattern detection only
3. **Hour 2-3:** `binding_resolver.py` con scope walker GetPlayer/GetOfflinePlayer/GetPlayerByCitizenId + tests con fixture variations
4. **Hour 3-4:** `transformer.py` con replacement templates + S1+S2+S3 full transform + golden tests qb_shops + qb_vehicleshop fixtures
5. **Hour 4-5:** `fxmanifest_injector.py` + tests 3 variations (no deps / existing block / already present idempotent)
6. **Hour 5-5.5:** `safety.py` marker detection + double-shift guard + tests
7. **Hour 5.5-6:** `report.py` + `cli.py` + `summary.json` schema + integration tests
8. **Hour 6+:** dry-run contra `D:\theBigProject\sandbox_qb_snapshot\` + iterate edge cases hasta golden tests verde + Backend Lead spot-check 10 random patches

ETA total: 4-6h (2 personas paralelas) o 6-8h (1 persona).

### 6.2 Critical safety priorities (en orden)

1. **NEVER double-shift** — anti-pattern §4.3 + U9 detection MUST be airtight
2. **NEVER modify ungroundable bindings** — if scope analyzer can't resolve `<player_var>` → MANUAL flag, never guess
3. **NEVER touch qb-core mainline** — patcher hard-codes exclusion `qb-core` from scope (only patches RESOURCES THAT CALL qb-core, not qb-core itself)
4. **NEVER apply without backup** — `--apply` MUST `.bak` before write, `--rollback` MUST be tested working
5. **Idempotent re-run** — marker `-- SONAR_PATCHED v1` skip already-patched files
6. **Phase A scope strict** — `--money-types=bank` default, cash/crypto raise WARNING if user opts in without explicit Phase B confirmation flag

## 7. Adversarial test scenarios

Founder paralelo (cuando patcher v1 dry-run produce output) ejecuta:

- **A1:** Comparar `summary.json` totals con preliminary scan PM Cascade (39 hits → expected ~25-30 auto-patched bank-only + ~10-14 manual U1 cash + 0-5 U2-U9)
- **A2:** Spot-check 10 random `auto_patched.md` entries → verbatim correct + binding resolution accurate
- **A3:** Re-run `--dry-run` 2x → idempotent (zero diff entre runs)
- **A4:** `--apply` sandbox copy → `lua -p` syntax check passes 100% files patched
- **A5:** `--rollback` sandbox → `git diff` = empty (perfect restore)
- **A6:** Edge case: file con `-- SONAR_PATCHED v1` marker → patcher skips correctly
- **A7:** Edge case: file con identifier `amount_minor` → U9 detected, NOT auto-patched
- **A8:** Edge case: nested loop `for _, p in pairs(...) do p.Functions.AddMoney('bank', ...)` → U3 manual
- **A9:** Edge case: `Player.Functions.SetMoney('bank', ...)` → U2 manual + recommendation template emitted
- **A10:** Edge case: fxmanifest.lua already has `'sonar_bank_app'` dependency → idempotent no-op

## 8. Sub-fase 5.6.B-C-D referenciadas (NO scope esta sesión)

- **5.6.B Backend Lead curation:** revisa `manual_review.md` post dry-run + escribe operator playbook con paso-a-paso para cada U-pattern → output `progress/PHASE_5_6_OPERATOR_PLAYBOOK.md`
- **5.6.C Live validation:** founder + Backend Lead `--apply` contra sandbox copy `D:\FiveM_Server\Sonar_sandbox\` + ejecuta Phase 5.5 manual probe matrix re-validating bahora con qb-* patched → audit row `invoker_resource = qb-vehicleshop` real (NO heurística), `event_type = bank_credit/bank_debit` (NO bank_external_*)
- **5.6.D Founder GO MANUAL Phase A complete:** tag `bank-phase-a` + MIGRATION.md final paragraph "Operator migration via SONAR migration_patcher v1.0" + GitHub release notes + final sign-off

Estas sub-fases están explícitamente fuera del scope de esta sesión 5.6.A. Patcher build first, validation later.

## 9. Activation checklist copy-paste

```
Spawn Backend Lead + Product Engineer BANK-BE.PHASE_5.6.A:

Branch: feature/bank-security-phase-a HEAD post-dd94f75 (pull + new commits)
Workspace: d:\theBigProject\
Sandbox source: D:\FiveM_Server\Sonar\resources\[qb]\ (read-only reference, NO --apply)
Sandbox copy: D:\theBigProject\sandbox_qb_snapshot\ (Backend Lead crea via Copy-Item, gitignored)

Read prompts (ambos obligatorio):
1. progress/MIGRATION_PATTERNS.md (spec técnica LOCKED v1.0)
2. docs/agents/teams/prompts/11_phase_5_6_a_migration_patcher_lead.md (este prompt)

Mission: build Python migration patcher v1.0 per spec §1-§16.

Sequencing (h0-h6):
- h0-1: repo skeleton tools/migration_patcher/ + venv + pytest
- h1-2: patterns.py S1+S2+S3 + U1-U9 regex + unit tests detection
- h2-3: binding_resolver.py scope walker + tests
- h3-4: transformer.py replacement templates + golden tests fixtures
- h4-5: fxmanifest_injector.py + tests 3 variations
- h5-5.5: safety.py marker + double-shift + tests
- h5.5-6: report.py + cli.py + summary.json + integration

Test corpus: extract real snippets from qb-vehicleshop, qb-shops, qb-pawnshop, qb-houses, qb-vehiclesales, qb-drugs (6 resources, top hits) → fixtures .in.lua + .expected.lua manual golden por Backend Lead.

Coverage targets: ≥85% line, 100% pattern S1-S4+U1-U9, 100% CLI flag, idempotent re-run, rollback, schema validation.

Output:
- tools/migration_patcher/ commited
- progress/PHASE_5_6_A_PATCHER_PROGRESS.md notes
- migration_output/ sandbox dry-run results para founder review (gitignored)

Boundary STRICT:
- NO --apply contra server real D:\FiveM_Server\Sonar\ (sub-fase 5.6.C)
- NO touch contracts LOCKED v1.0.2 R2
- NO touch los 22 exports en sonar_bank_app
- NO touch qb-core mainline
- Phase A scope = --money-types=bank only; cash/crypto Phase B disabled default
- NO inject runtime listeners (Path E descartado founder 2026-05-13 05:00 UTC+02)

ETA: 4-6h paralelo (Backend Lead + Product Engineer) o 6-8h sequential.

Founder paralelo: A1-A10 adversarial scenarios paragraph 7 cuando dry-run output ready.

GO.
```

## 10. Boundary recordatorio final

- Patcher es operator-side migration tool. Workspace `tools/migration_patcher/` es entregable para que cualquier operator pueda correrlo contra su instalación qb-* y migrar limpiamente. NO es runtime SONAR component.
- SONAR core (resources/sonar_*) NO se modifica esta sub-fase. Los 22 exports siguen siendo el surface estable del Closed Public API.
- Patcher publish via release tag `migration_patcher-v1.0.0` post-validation 5.6.C-D para distribución a operators terceros.

---

**PM Cascade emitió este prompt 2026-05-13 05:10 UTC+02 post founder ratification 05:00 UTC+02.**
**Spec base:** `progress/MIGRATION_PATTERNS.md` v1.0 (committed mismo push).
**Path A automatizado preserva: SONAR authoritative master + Q4 LOCKED + Phase 3 cleanup + zero recursion + zero contract amendment.**
