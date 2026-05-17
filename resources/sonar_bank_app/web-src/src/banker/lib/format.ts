/**
 * SONAR Bank App — banker/lib/format.ts
 * --------------------------------------------------------------------------
 * Small formatters used across banker modules. Money values arrive as MINOR
 * units (cents) — `formatMinor` divides by 100 and applies locale.
 */

const moneyFormatter = new Intl.NumberFormat(undefined, {
  style: 'currency',
  currency: 'EUR',
  maximumFractionDigits: 2,
})

const compactFormatter = new Intl.NumberFormat(undefined, {
  notation: 'compact',
  maximumFractionDigits: 1,
})

export function formatMinor(minor: number | null | undefined): string {
  if (minor === null || minor === undefined || Number.isNaN(minor)) return '—'
  return moneyFormatter.format(minor / 100)
}

export function formatMinorCompact(minor: number | null | undefined): string {
  if (minor === null || minor === undefined || Number.isNaN(minor)) return '—'
  return '€' + compactFormatter.format(minor / 100)
}

export function formatBps(bps: number | null | undefined): string {
  if (bps === null || bps === undefined || Number.isNaN(bps)) return '—'
  return (bps / 100).toFixed(2) + '%'
}

export function formatDayMs(ms: number | null | undefined): string {
  if (!ms) return '—'
  return new Date(ms).toLocaleDateString()
}

export function formatRelative(ms: number | null | undefined): string {
  if (!ms) return '—'
  const diff = Date.now() - ms
  const min = Math.floor(diff / 60_000)
  if (min < 1) return 'just now'
  if (min < 60) return `${min}m ago`
  const h = Math.floor(min / 60)
  if (h < 24) return `${h}h ago`
  const d = Math.floor(h / 24)
  if (d < 30) return `${d}d ago`
  const mo = Math.floor(d / 30)
  return `${mo}mo ago`
}

export function compactNumber(n: number | null | undefined): string {
  if (n === null || n === undefined || Number.isNaN(n)) return '—'
  return compactFormatter.format(n)
}
