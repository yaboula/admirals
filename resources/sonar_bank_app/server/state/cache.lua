-- =============================================================================
-- SONAR Bank App — state/cache.lua
-- =============================================================================
-- Generic in-memory LRU cache primitive (used as fallback / shared utility).
--
-- Each domain service has its own dedicated cache (bootstrap_service +
-- recipients_service). This module provides a reusable LRU class for any
-- future need (memberships, compliance flags, status bridges, etc).
-- =============================================================================

BankApp.state.cache = {}
local M = BankApp.state.cache

-- -----------------------------------------------------------------------------
-- §1. LRU class
-- -----------------------------------------------------------------------------

local LRU = {}
LRU.__index = LRU

--- New: create LRU instance.
---@param capacity integer max entries
---@param ttl_ms integer optional TTL in ms (0 = no TTL)
---@return table
function M.New(capacity, ttl_ms)
  local instance = setmetatable({
    capacity = capacity or 256,
    ttl_ms   = ttl_ms or 0,
    nodes    = {},   -- key → node
    head     = nil,  -- MRU
    tail     = nil,  -- LRU
    size     = 0,
    stats    = { hits = 0, misses = 0, evicts = 0, expires = 0 },
  }, LRU)
  return instance
end

local function now_ms()
  return os.time() * 1000 + math.floor((os.clock() % 1) * 1000)
end

function LRU:_remove(node)
  if node.prev then node.prev.next = node.next else self.head = node.next end
  if node.next then node.next.prev = node.prev else self.tail = node.prev end
  node.prev, node.next = nil, nil
end

function LRU:_push_head(node)
  node.prev = nil
  node.next = self.head
  if self.head then self.head.prev = node end
  self.head = node
  if not self.tail then self.tail = node end
end

function LRU:_evict_lru()
  if not self.tail then return end
  local evict = self.tail
  self.nodes[evict.key] = nil
  self:_remove(evict)
  self.size = self.size - 1
  self.stats.evicts = self.stats.evicts + 1
end

--- Get
---@param key any
---@return any value, nil if missing/expired
function LRU:Get(key)
  local node = self.nodes[key]
  if not node then
    self.stats.misses = self.stats.misses + 1
    return nil
  end
  if self.ttl_ms > 0 and node.expires_ms and node.expires_ms < now_ms() then
    -- expired
    self.nodes[key] = nil
    self:_remove(node)
    self.size = self.size - 1
    self.stats.expires = self.stats.expires + 1
    return nil
  end
  -- Bump to head
  self:_remove(node)
  self:_push_head(node)
  self.stats.hits = self.stats.hits + 1
  return node.value
end

--- Set
function LRU:Set(key, value)
  local existing = self.nodes[key]
  if existing then
    existing.value = value
    if self.ttl_ms > 0 then existing.expires_ms = now_ms() + self.ttl_ms end
    self:_remove(existing)
    self:_push_head(existing)
    return
  end

  local node = { key = key, value = value }
  if self.ttl_ms > 0 then node.expires_ms = now_ms() + self.ttl_ms end
  self.nodes[key] = node
  self:_push_head(node)
  self.size = self.size + 1

  if self.size > self.capacity then
    self:_evict_lru()
  end
end

--- Invalidate
function LRU:Invalidate(key)
  local node = self.nodes[key]
  if not node then return end
  self.nodes[key] = nil
  self:_remove(node)
  self.size = self.size - 1
end

function LRU:Clear()
  self.nodes = {}
  self.head, self.tail = nil, nil
  self.size = 0
end

function LRU:GetStats()
  return {
    capacity = self.capacity,
    size     = self.size,
    ttl_ms   = self.ttl_ms,
    hits     = self.stats.hits,
    misses   = self.stats.misses,
    evicts   = self.stats.evicts,
    expires  = self.stats.expires,
  }
end

return M
