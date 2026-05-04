-- =============================================================================
-- SONAR Core — server/metrics.lua
--
-- Instrumentación counters + histograms in-memory para sonar_core.
-- Exporta a /sonar_metrics admin command. Sirve como base para
-- futura export Prometheus (Oleada 2+).
--
-- API pública:
--   SONAR.Metrics.Counter(key, delta?)              — incrementa counter.
--   SONAR.Metrics.Observe(key, value_ms)            — histogram sample.
--   SONAR.Metrics.Gauge(key, value)                 — set gauge absoluto.
--   SONAR.Metrics.Get(key)                          — inspecciona entry.
--   SONAR.Metrics.Snapshot()                        — full dump table.
--   SONAR.Metrics.Reset()                           — zero all.
--
-- Histogram:
--   Sliding window de últimas N samples (Config.MetricsHistogramWindow=500).
--   Calcula p50/p95/p99 + min/max/avg al leer Snapshot.
--   Memory: 500 samples * 8 bytes * 100 keys ≈ 400 KB.
--
-- Admin command:
--   /sonar_metrics         — imprime snapshot completo.
--   /sonar_metrics_reset   — zero todos counters + histograms.
--
-- Referencias SSoT:
--   docs/technical/01_architecture.md §8 (observability — metrics catalog).
--   docs/technical/06_fivem_standards.md §2 (performance budgets).
-- =============================================================================

SONAR = SONAR or {}
SONAR.Metrics = SONAR.Metrics or {}

local Config = SONAR.Config
local Log = SONAR.Log
local Metrics = SONAR.Metrics

-- -----------------------------------------------------------------------------
-- Storage — tablas separadas por tipo para O(1) dispatch + type safety.
-- -----------------------------------------------------------------------------
local _counters = {}    -- [key] = number
local _gauges = {}      -- [key] = number
local _histograms = {}  -- [key] = { samples[], head, size, max }

local _window = Config.MetricsHistogramWindow or 500

-- -----------------------------------------------------------------------------
-- Public — Counter — incrementa monotonic counter.
-- -----------------------------------------------------------------------------
function Metrics.Counter(key, delta)
  if type(key) ~= 'string' then return end
  delta = tonumber(delta) or 1
  _counters[key] = (_counters[key] or 0) + delta
end

-- -----------------------------------------------------------------------------
-- Public — Gauge — set valor absoluto (último gana).
-- -----------------------------------------------------------------------------
function Metrics.Gauge(key, value)
  if type(key) ~= 'string' then return end
  value = tonumber(value)
  if value == nil then return end
  _gauges[key] = value
end

-- -----------------------------------------------------------------------------
-- Public — Observe — histogram sample (sliding window).
-- -----------------------------------------------------------------------------
function Metrics.Observe(key, value)
  if type(key) ~= 'string' then return end
  value = tonumber(value)
  if value == nil then return end

  local h = _histograms[key]
  if not h then
    h = { samples = {}, head = 1, size = 0, max = _window }
    _histograms[key] = h
  end

  h.samples[h.head] = value
  h.head = (h.head % h.max) + 1
  if h.size < h.max then h.size = h.size + 1 end
end

-- -----------------------------------------------------------------------------
-- Internal — compute percentile from sorted array.
-- @param sorted_arr number[] ascending.
-- @param p number 0..1.
-- -----------------------------------------------------------------------------
local function _percentile(sorted_arr, p)
  if #sorted_arr == 0 then return 0 end
  -- Nearest-rank method (simple, O(1) después de sort).
  local rank = math.ceil(p * #sorted_arr)
  if rank < 1 then rank = 1 end
  if rank > #sorted_arr then rank = #sorted_arr end
  return sorted_arr[rank]
end

-- -----------------------------------------------------------------------------
-- Internal — snapshot de un histogram con stats calculados.
-- -----------------------------------------------------------------------------
local function _hist_stats(h)
  if h.size == 0 then
    return { count = 0, min = 0, max = 0, avg = 0, p50 = 0, p95 = 0, p99 = 0 }
  end

  -- Clone + sort para percentiles (O(n log n), n ≤ 500).
  local sorted = {}
  for i = 1, h.size do sorted[i] = h.samples[i] end
  table.sort(sorted)

  local sum = 0
  for i = 1, h.size do sum = sum + sorted[i] end

  return {
    count = h.size,
    min = sorted[1],
    max = sorted[h.size],
    avg = sum / h.size,
    p50 = _percentile(sorted, 0.50),
    p95 = _percentile(sorted, 0.95),
    p99 = _percentile(sorted, 0.99),
  }
end

-- -----------------------------------------------------------------------------
-- Public — Get — inspecciona una key específica (útil para tests).
-- -----------------------------------------------------------------------------
function Metrics.Get(key)
  if _counters[key] ~= nil then
    return { type = 'counter', key = key, value = _counters[key] }
  end
  if _gauges[key] ~= nil then
    return { type = 'gauge', key = key, value = _gauges[key] }
  end
  if _histograms[key] then
    return { type = 'histogram', key = key, stats = _hist_stats(_histograms[key]) }
  end
  return nil
end

-- -----------------------------------------------------------------------------
-- Public — Snapshot — full state dump para export.
-- -----------------------------------------------------------------------------
function Metrics.Snapshot()
  local counters = {}
  for k, v in pairs(_counters) do counters[k] = v end

  local gauges = {}
  for k, v in pairs(_gauges) do gauges[k] = v end

  local histograms = {}
  for k, h in pairs(_histograms) do histograms[k] = _hist_stats(h) end

  return {
    counters = counters,
    gauges = gauges,
    histograms = histograms,
    ts = os.time(),
  }
end

-- -----------------------------------------------------------------------------
-- Public — Reset — zero todo (tests + admin reset).
-- -----------------------------------------------------------------------------
function Metrics.Reset()
  _counters = {}
  _gauges = {}
  _histograms = {}
end

-- =============================================================================
-- Admin commands.
-- =============================================================================

local function _is_admin(source)
  if source == 0 then return true end
  return IsPlayerAceAllowed(source, Config.AdminAcePrefix .. 'metrics')
end

-- /sonar_metrics — dump completo.
RegisterCommand('sonar_metrics', function(source)
  if not _is_admin(source) then return end

  local snap = Metrics.Snapshot()
  print('^5=== SONAR Core — Metrics Snapshot ===^7')
  print(string.format('Timestamp: %s', os.date('%Y-%m-%d %H:%M:%S', snap.ts)))

  -- Counters (ordenados alfabéticamente para output estable).
  local counter_keys = {}
  for k in pairs(snap.counters) do counter_keys[#counter_keys + 1] = k end
  table.sort(counter_keys)
  if #counter_keys > 0 then
    print('^3-- Counters --^7')
    for _, k in ipairs(counter_keys) do
      print(string.format('  %s = %d', k, snap.counters[k]))
    end
  end

  -- Gauges.
  local gauge_keys = {}
  for k in pairs(snap.gauges) do gauge_keys[#gauge_keys + 1] = k end
  table.sort(gauge_keys)
  if #gauge_keys > 0 then
    print('^3-- Gauges --^7')
    for _, k in ipairs(gauge_keys) do
      print(string.format('  %s = %.4f', k, snap.gauges[k]))
    end
  end

  -- Histograms.
  local hist_keys = {}
  for k in pairs(snap.histograms) do hist_keys[#hist_keys + 1] = k end
  table.sort(hist_keys)
  if #hist_keys > 0 then
    print('^3-- Histograms (ms) --^7')
    for _, k in ipairs(hist_keys) do
      local s = snap.histograms[k]
      print(string.format('  %-40s count=%-5d min=%-7.2f avg=%-7.2f p50=%-7.2f p95=%-7.2f p99=%-7.2f max=%-7.2f',
        k, s.count, s.min, s.avg, s.p50, s.p95, s.p99, s.max))
    end
  end

  print('^5=========================================^7')
end, true)

-- /sonar_metrics_reset.
RegisterCommand('sonar_metrics_reset', function(source)
  if not _is_admin(source) then return end
  Metrics.Reset()
  print('^2[SONAR] Metrics reset.^7')
end, true)

-- -----------------------------------------------------------------------------
-- Boot announce.
-- -----------------------------------------------------------------------------
Log.Info('Metrics ready (histogram_window=%d)', _window)
