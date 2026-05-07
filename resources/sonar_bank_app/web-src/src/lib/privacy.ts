export function normalizeSensitiveToken(value: string): string {
  return value.replace(/\s+/g, '').toUpperCase()
}

export function maskIbanDisplay(iban: string): string {
  const compact = normalizeSensitiveToken(iban)
  if (compact.length < 8) return '••••'
  return `${compact.slice(0, 4)} **** **** ${compact.slice(-4)}`
}

export function maskIbanCompact(iban: string): string {
  const compact = normalizeSensitiveToken(iban)
  if (compact.length < 8) return '••••'
  return `${compact.slice(0, 4)}…${compact.slice(-4)}`
}

export function maskIbanPanel(iban: string): string {
  const compact = normalizeSensitiveToken(iban)
  if (compact.length < 8) return '••••'
  return `${compact.slice(0, 4)} ···· ···· ${compact.slice(-4)}`
}

export function maskPanDisplay(pan: string | undefined, lastFour?: string): string {
  const compact = pan ? normalizeSensitiveToken(pan).replace(/\D/g, '') : ''
  const suffix = compact.length >= 4 ? compact.slice(-4) : lastFour ?? '••••'
  return `•••• •••• •••• ${suffix}`
}

export function maskCidDisplay(cid: string | null | undefined): string {
  if (!cid) return 'CID-••••'
  const compact = normalizeSensitiveToken(cid)
  if (compact.length <= 4) return 'CID-••••'
  return `CID-••••-${compact.slice(-4)}`
}

export function maskOperationCode(value: string | null | undefined): string {
  if (!value) return '••••••••'
  const compact = normalizeSensitiveToken(value)
  if (compact.length <= 8) return '••••••••'
  return `${compact.slice(0, 4)}…${compact.slice(-4)}`
}

export function safeAriaLabel(label: string): string {
  return label.replace(/[A-Z]{2}\d{2}[A-Z0-9]{8,}/gi, 'IBAN oculto')
}
