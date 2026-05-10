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
      'linear-gradient(135deg, rgb(8, 9, 13) 0%, rgb(1, 2, 3) 50%, rgb(0, 0, 0) 100%)',
    accent: 'rgb(155, 158, 166)',
    textPrimary: 'rgb(241, 242, 244)',
    textTertiary: 'rgb(114, 116, 124)',
    motif: 'pinstripe',
  },
  {
    id: 'sonar_signature',
    name: 'Sonar Signature',
    tagline: 'The flagship card · #FF5100',
    tier: 'signature',
    surface:
      'linear-gradient(135deg, rgb(11, 13, 19) 0%, rgb(3, 3, 6) 50%, rgb(1, 1, 1) 100%)',
    overlay:
      'radial-gradient(circle at 75% 45%, rgba(246, 75, 0, 0.28) 0%, transparent 55%)',
    accent: 'rgb(255, 100, 19)',
    textPrimary: 'rgb(247, 248, 251)',
    textTertiary: 'rgb(125, 128, 137)',
    motif: 'sonar_waves',
  },
  {
    id: 'aurora',
    name: 'Aurora',
    tagline: 'Boreal · teal → violet',
    tier: 'premium',
    surface:
      'linear-gradient(135deg, rgb(0, 38, 41) 0%, rgb(0, 0, 77) 55%, rgb(13, 0, 46) 100%)',
    overlay:
      'radial-gradient(circle at 25% 30%, rgba(0, 190, 193, 0.22) 0%, transparent 50%)',
    accent: 'rgb(0, 210, 211)',
    textPrimary: 'rgb(244, 250, 251)',
    textTertiary: 'rgba(155, 191, 198, 0.75)',
    motif: 'geometric',
  },
  {
    id: 'sunset',
    name: 'Sunset',
    tagline: 'Deep amber · dusk rose',
    tier: 'premium',
    surface:
      'linear-gradient(135deg, rgb(63, 0, 0) 0%, rgb(53, 0, 0) 50%, rgb(26, 0, 4) 100%)',
    overlay:
      'radial-gradient(circle at 80% 20%, rgba(232, 127, 37, 0.22) 0%, transparent 55%)',
    accent: 'rgb(239, 128, 111)',
    textPrimary: 'rgb(252, 247, 245)',
    textTertiary: 'rgba(219, 180, 166, 0.75)',
    motif: 'fluid',
  },
  {
    id: 'titanium',
    name: 'Titanium',
    tagline: 'Light metal · executive precision',
    tier: 'premium',
    surface:
      'linear-gradient(135deg, rgb(211, 216, 222) 0%, rgb(164, 172, 180) 48%, rgb(92, 100, 109) 100%)',
    overlay:
      'radial-gradient(circle at 78% 20%, rgba(255, 255, 255, 0.42) 0%, transparent 42%), linear-gradient(115deg, transparent 0%, rgba(255, 255, 255, 0.22) 48%, transparent 62%)',
    accent: 'rgb(86, 95, 104)',
    textPrimary: 'rgb(4, 6, 9)',
    textTertiary: 'rgba(36, 42, 48, 0.7)',
    motif: 'geometric',
  },
  {
    id: 'deep_space',
    name: 'Deep Space',
    tagline: 'Gravitational blue · violet core',
    tier: 'signature',
    surface:
      'linear-gradient(135deg, rgb(0, 1, 1) 0%, rgb(1, 0, 37) 48%, rgb(1, 0, 3) 100%)',
    overlay:
      'radial-gradient(circle at 68% 38%, rgba(116, 83, 254, 0.28) 0%, transparent 46%), radial-gradient(circle at 24% 76%, rgba(0, 142, 195, 0.22) 0%, transparent 42%)',
    accent: 'rgb(97, 145, 255)',
    textPrimary: 'rgb(246, 249, 253)',
    textTertiary: 'rgba(159, 178, 210, 0.74)',
    motif: 'fluid',
  },
  {
    id: 'emerald_vault',
    name: 'Emerald Vault',
    tagline: 'Private green · night vault',
    tier: 'premium',
    surface:
      'linear-gradient(135deg, rgb(0, 9, 3) 0%, rgb(0, 21, 1) 52%, rgb(0, 1, 0) 100%)',
    overlay:
      'radial-gradient(circle at 72% 24%, rgba(53, 193, 119, 0.2) 0%, transparent 48%)',
    accent: 'rgb(82, 205, 134)',
    textPrimary: 'rgb(245, 250, 247)',
    textTertiary: 'rgba(151, 187, 170, 0.72)',
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
