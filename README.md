# Admirals — The Big Project

> *Building the gold standard of FiveM ecosystems.*

Premium FiveM server with deep economy, production chains (Farm → Mill → Bakery → Retail), Tablet UI, and multi-framework compatibility via Bridges Layer.

[![Status](https://img.shields.io/badge/status-Sprint%200%20(MVP%20in%20progress)-blue)]()
[![Oleada 0](https://img.shields.io/badge/Oleada%200-CLOSED%20100%25-brightgreen)]()
[![Docs](https://img.shields.io/badge/docs-29%20signed%20%7C%20%7E27k%20lines-success)]()

---

## Status

**🏆 Oleada 0 (documentation) CLOSED** — 29 docs signed, ~27.260 lines, 9 ADRs.
**🚀 Oleada 1 (MVP playable) — Sprint 0 in progress** — Setup + Bridges Layer + admirals_core.

| Oleada | Status | Estimated | Output |
|---|---|---|---|
| 0 — Documentation | ✅ Closed 100% | ~1 month | 29 docs SSoT, ready-to-code |
| 1 — MVP (Granja + Tablet + Banco) | 🟡 In progress | 5 months | Playable server, monetizable |
| 2 — Multi-node (Mill + Bakery + Retail) + social | 🔴 Pending | 6-8 months | Full production chain end-to-end |
| 3+ — Federation + advanced | 🔴 Pending | Ongoing | Cross-server, marketplaces |

See [`docs/planning/01_roadmap.md`](docs/planning/01_roadmap.md) for detailed roadmap.

---

## Quick start (dev)

Prerequisites:
- FiveM server (latest recommended build)
- MySQL 8+ (MariaDB 10.5+ also OK)
- Node.js 20+ (for Tablet NUI builds, Oleada 1 S1+)
- Git

```bash
# 1. Clone
git clone https://github.com/yaboula/admirals.git
cd admirals

# 2. Configure server
cp server.cfg.example server.cfg
# Edit server.cfg: set sv_licenseKey, DB credentials, endpoints

# 3. Install dependencies (FiveM resources)
# Ensure these are in your resources/ directory (download separately):
#   - oxmysql, ox_lib, ox_inventory, ox_target
#   - QBox (primary framework)
#   - lb-phone (phone bridge T1)

# 4. Start server
./run.sh     # Linux
./run.cmd    # Windows

# 5. Verify boot
# Console should show:
#   [Admirals Bridges] v0.X.0 | Bank→qbox | Inventory→ox_inventory | ...
#   [Admirals Core] Migrations applied (002 total)
#   [Admirals Core] Ready — resmon <0.5ms idle
```

See [`scripts/smoke_test.md`](scripts/smoke_test.md) for full manual smoke check (available after Sprint 0 S0.4).

---

## Repository structure

```
admirals/
├── README.md                   ← you are here
├── server.cfg.example          ← FiveM server config template (S0.1)
├── .gitignore                  ← (S0.1)
│
├── docs/                       ← 29 signed docs, ~27k lines
│   ├── 00_PRODUCT_BIBLE.md     ← product constitution (read FIRST)
│   ├── agents/                 ← AI agent onboarding + operations
│   │   ├── 00_BOOTSTRAP.md     ← ⭐ entry point for any AI session
│   │   ├── 02_working_conventions.md
│   │   └── 03_founder_playbook.md ← founder operations manual
│   ├── design/                 ← product design + node specs
│   ├── economy/                ← economic models + balance
│   ├── gameplay/               ← loops, progression, social
│   ├── art/                    ← 3D/sound/UI references
│   ├── technical/              ← architecture, DB, APIs, FSMs, bridges
│   ├── planning/               ← roadmap + ADRs
│   └── qa/                     ← testing protocol
│
├── resources/                  ← FiveM resources (Lua server+client)
│   ├── admirals_bridges/       ← compat layer multi-framework (S0.2-S0.3)
│   │   ├── fxmanifest.lua
│   │   ├── bridges/            ← 6 bridge interfaces
│   │   ├── adapters/           ← implementations per script (native + T1 + T2)
│   │   └── server/             ← registry + dispatcher + logger
│   └── admirals_core/          ← core event bus + DB + rate limiter (S0.4)
│       ├── fxmanifest.lua
│       ├── server/
│       └── migrations/         ← SQL versioned migrations
│
├── progress/                   ← operational logs
│   ├── SESSION_LOG.md          ← append-only log every AI session
│   ├── SPRINT_PLAN_S{N}.md     ← per-sprint plan with sessions
│   └── SPRINT_RETRO_S{N}.md    ← per-sprint retro
│
├── scripts/                    ← dev utilities
│   ├── smoke_test.md           ← manual smoke checklist
│   └── test_adapter.lua        ← bridge adapter test harness
│
└── .windsurf/                  ← Cascade/Windsurf workspace config
    ├── rules/admirals.md       ← always-on workspace rule
    └── workflows/              ← start-session, close-session, sprint-retro
```

---

## Working with AI agents

This project is built **solo-founder + AI pair programming**. Operations manual: [`docs/agents/03_founder_playbook.md`](docs/agents/03_founder_playbook.md).

**If you're an AI agent joining this project:**
1. Read [`docs/agents/00_BOOTSTRAP.md`](docs/agents/00_BOOTSTRAP.md) first (15 min).
2. Read [`docs/agents/03_founder_playbook.md`](docs/agents/03_founder_playbook.md) §4-§6 (5 min).
3. Read last 3 entries of [`progress/SESSION_LOG.md`](progress/SESSION_LOG.md).
4. Wait for founder green-light before any code change.

Model allocation strategy: **Opus 4.7 primary** (backend + frontend). Sonnet 4.6 / Gemini 3.1 Pro / GPT-5.3 Codex as specialized auxiliaries. See playbook §2.3.

---

## Working language

- **Code, identifiers, comments, commits, technical docs** → English (non-negotiable).
- **Design discussions, planning docs, ADRs** → Spanish (working language).
- **In-game UI** → Multi-language, Spanish default (English roadmap for Oleada 3+).

---

## Architecture highlights

- **Bridges Layer** — all money/items/phone/identity/target/notify calls route through `Bridges.*` — never couple to specific framework. Supports QBox (T1), QBCore/ESX (T2 compat), custom scripts (T3 SDK). See [`docs/technical/07_bridges_compatibility.md`](docs/technical/07_bridges_compatibility.md).
- **Quality system** — every item carries lineage (origin farm, mill lot, batch) + quality score affecting downstream. See [`docs/technical/05_state_machines.md`](docs/technical/05_state_machines.md).
- **Tax retention 8%** as primary economy sink (no pay-to-win, no RNG gambling). See [`docs/economy/01_economic_model.md`](docs/economy/01_economic_model.md).
- **No generic XP** — progression by real metrics (sales volume, quality scores, specific achievements). Per ADR-004.
- **MVP = Granja** (cross-vertical root) — not Bakery. Per ADR-008.

---

## Commercial

Premium FiveM asset — pricing + license model TBD post-Oleada 1 beta.
For early-access inquiries: (contact TBD).

---

## License

All rights reserved. This is a proprietary project. See LICENSE (TBD).

---

*"Documentation without meta-organization is noise. The BOOTSTRAP is the signal."*
