/**
 * BANK-FE.4.1 — Card Designs Registry.
 *
 * Canonical collection of visual styles the user can apply to any card.
 * Each design is a complete visual recipe (surface gradient + accents +
 * text colours + motif) that `<CardVisual>` can render without branching.
 *
 * DOCTRINE — ORANGE DISCIPLINE:
 *   Only ONE design (`sonar_signature`) uses brand orange. Every other
 *   design explores a different chromatic territory (noir / aurora / sunset)
 *   so the gallery feels varied without diluting the brand anchor. The user
 *   who picks orange is picking IDENTITY; the user who picks another is
 *   picking personal style — both valid, neither competes.
 */

export type CardDesignTier = 'default' | 'premium' | 'signature'

export type CardDesignMotif = 'none' | 'pinstripe' | 'sonar_waves' | 'geometric' | 'fluid'

export interface CardDesign {
  id: string
  name: string
  tagline: string
  tier: CardDesignTier
  /** CSS background string — usually a linear-gradient or layered radial. */
  surface: string
  /** Optional CSS overlay gradient layered above the surface. */
  overlay?: string
  /** Accent colour used by chip shadow + brand mark + glow. */
  accent: string
  /** Primary text colour used for amount + card number. */
  textPrimary: string
  /** Tertiary text colour used for labels (eyebrow, holder, expiry). */
  textTertiary: string
  /** Decorative motif rendered behind the content. */
  motif: CardDesignMotif
}

export const CARD_DESIGNS: CardDesign[] = [
  {
    id: 'noir',
    name: 'Noir',
    tagline: 'Pure minimalism',
    tier: 'default',
    surface:
      'linear-gradient(135deg, oklch(0.14 0.010 270) 0%, oklch(0.08 0.008 270) 50%, oklch(0.04 0.006 270) 100%)',
    accent: 'oklch(0.70 0.012 270)',
    textPrimary: 'oklch(0.96 0.004 270)',
    textTertiary: 'oklch(0.56 0.012 270)',
    motif: 'pinstripe',
  },
  {
    id: 'sonar_signature',
    name: 'Sonar Signature',
    tagline: 'The flagship card · #FF5100',
    tier: 'signature',
    surface:
      'linear-gradient(135deg, oklch(0.16 0.012 270) 0%, oklch(0.10 0.010 270) 50%, oklch(0.06 0.008 270) 100%)',
    overlay:
      'radial-gradient(circle at 75% 45%, oklch(0.65 0.22 40 / 0.28) 0%, transparent 55%)',
    accent: 'oklch(0.72 0.22 40)',
    textPrimary: 'oklch(0.98 0.004 270)',
    textTertiary: 'oklch(0.60 0.014 270)',
    motif: 'sonar_waves',
  },
  {
    id: 'aurora',
    name: 'Aurora',
    tagline: 'Boreal · teal → violet',
    tier: 'premium',
    surface:
      'linear-gradient(135deg, oklch(0.22 0.10 195) 0%, oklch(0.18 0.14 260) 55%, oklch(0.14 0.10 290) 100%)',
    overlay:
      'radial-gradient(circle at 25% 30%, oklch(0.70 0.18 195 / 0.22) 0%, transparent 50%)',
    accent: 'oklch(0.78 0.14 195)',
    textPrimary: 'oklch(0.98 0.006 210)',
    textTertiary: 'oklch(0.78 0.04 210 / 0.75)',
    motif: 'geometric',
  },
  {
    id: 'sunset',
    name: 'Sunset',
    tagline: 'Deep amber · dusk rose',
    tier: 'premium',
    surface:
      'linear-gradient(135deg, oklch(0.22 0.12 55) 0%, oklch(0.16 0.14 25) 50%, oklch(0.10 0.12 355) 100%)',
    overlay:
      'radial-gradient(circle at 80% 20%, oklch(0.70 0.16 55 / 0.22) 0%, transparent 55%)',
    accent: 'oklch(0.72 0.14 30)',
    textPrimary: 'oklch(0.98 0.006 50)',
    textTertiary: 'oklch(0.80 0.05 40 / 0.75)',
    motif: 'fluid',
  },
  {
    id: 'titanium',
    name: 'Titanium',
    tagline: 'Light metal · executive precision',
    tier: 'premium',
    surface:
      'linear-gradient(135deg, oklch(0.88 0.010 250) 0%, oklch(0.74 0.014 250) 48%, oklch(0.50 0.018 250) 100%)',
    overlay:
      'radial-gradient(circle at 78% 20%, oklch(1 0 0 / 0.42) 0%, transparent 42%), linear-gradient(115deg, transparent 0%, oklch(1 0 0 / 0.22) 48%, transparent 62%)',
    accent: 'oklch(0.48 0.018 250)',
    textPrimary: 'oklch(0.12 0.010 250)',
    textTertiary: 'oklch(0.28 0.014 250 / 0.70)',
    motif: 'geometric',
  },
  {
    id: 'deep_space',
    name: 'Deep Space',
    tagline: 'Gravitational blue · violet core',
    tier: 'signature',
    surface:
      'linear-gradient(135deg, oklch(0.055 0.010 270) 0%, oklch(0.11 0.09 265) 48%, oklch(0.055 0.025 300) 100%)',
    overlay:
      'radial-gradient(circle at 68% 38%, oklch(0.58 0.24 285 / 0.28) 0%, transparent 46%), radial-gradient(circle at 24% 76%, oklch(0.58 0.18 220 / 0.22) 0%, transparent 42%)',
    accent: 'oklch(0.68 0.18 265)',
    textPrimary: 'oklch(0.98 0.006 260)',
    textTertiary: 'oklch(0.76 0.05 260 / 0.74)',
    motif: 'fluid',
  },
  {
    id: 'emerald_vault',
    name: 'Emerald Vault',
    tagline: 'Private green · night vault',
    tier: 'premium',
    surface:
      'linear-gradient(135deg, oklch(0.12 0.035 165) 0%, oklch(0.16 0.070 155) 52%, oklch(0.055 0.018 170) 100%)',
    overlay:
      'radial-gradient(circle at 72% 24%, oklch(0.72 0.16 155 / 0.20) 0%, transparent 48%)',
    accent: 'oklch(0.76 0.15 155)',
    textPrimary: 'oklch(0.98 0.006 165)',
    textTertiary: 'oklch(0.76 0.045 165 / 0.72)',
    motif: 'pinstripe',
  },
]

export const CARD_DESIGNS_BY_ID: Record<string, CardDesign> = Object.fromEntries(
  CARD_DESIGNS.map((d) => [d.id, d]),
)

export const DEFAULT_CARD_DESIGN: CardDesign = CARD_DESIGNS_BY_ID.sonar_signature

/**
 * Resolve a design by id with a safe fallback.
 */
export function resolveCardDesign(designId: string | undefined): CardDesign {
  if (!designId) return DEFAULT_CARD_DESIGN
  return CARD_DESIGNS_BY_ID[designId] ?? DEFAULT_CARD_DESIGN
}
