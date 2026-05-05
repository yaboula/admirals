/**
 * SONAR Tablet — AppTile (S2.3).
 *
 * Tile del Bridge home grid. Surface `bg-sonar-white/5` (alpha-layer tonal,
 * permitido per SPRINT_PLAN_S2 §6). Hover → `text-sonar-orange` +
 * `ring-sonar-orange/40` (brand focus signal). Disabled → `opacity-40` +
 * `cursor-not-allowed` sin hover response.
 *
 * Dark-only strict (ADR-016 D2): cero light surfaces / grey palette / light-mode variants.
 * 3-color canonical (ADR-016 D1): solo sonar-black / sonar-orange / sonar-white
 * + alpha-layers sobre esos 3.
 */
import { memo } from 'react'
import { motion } from 'framer-motion'
import type { Variants } from 'framer-motion'
import type { AppTileDef } from '@/apps/Bridge/appCatalog'
import { useSfx } from '@/hooks/useSfx'

export interface AppTileProps {
  def: AppTileDef
  onActivate: (def: AppTileDef) => void
  /** Framer Motion variants passed from listStagger parent (BridgeHome). */
  variants?: Variants
}

function statusBadgeLabel(status: AppTileDef['status']): string {
  switch (status) {
    case 'shipped':
      return '✓'
    case 'stub-S2.4':
      return 'S2.4'
    case 'stub-S2.6':
      return 'S2.6'
    case 'placeholder-future':
      return '—'
  }
}

function AppTileInner({ def, onActivate, variants }: AppTileProps) {
  const { play } = useSfx()
  const disabled = def.route === null
  const Icon = def.lucideIcon
  const badge = statusBadgeLabel(def.status)

  return (
    <motion.button
      type="button"
      variants={variants}
      disabled={disabled}
      onClick={() => {
        if (disabled) return
        // console_tap SFX before dispatch — immediate feedback (DC-S2.6.6).
        play('console_tap')
        onActivate(def)
      }}
      aria-label={def.label}
      data-tile-id={def.id}
      data-tile-status={def.status}
      className={[
        'group relative flex aspect-square w-full flex-col items-center justify-center gap-3 rounded-xl',
        'border border-sonar-white/10 bg-sonar-white/5',
        'outline-none transition-colors duration-150',
        disabled
          ? 'cursor-not-allowed opacity-40'
          : 'cursor-pointer hover:bg-sonar-white/10 hover:text-sonar-orange focus-visible:ring-2 focus-visible:ring-sonar-orange/40',
      ].join(' ')}
    >
      <Icon
        className={[
          'h-8 w-8 transition-colors duration-150',
          disabled
            ? 'text-sonar-white/60'
            : 'text-sonar-white/80 group-hover:text-sonar-orange',
        ].join(' ')}
        strokeWidth={1.5}
        aria-hidden
      />
      <span className="text-sm font-medium tracking-tight text-sonar-white">
        {def.label}
      </span>
      <span
        className="absolute right-2 top-2 font-mono text-[10px] uppercase tracking-wider text-sonar-white/40"
        aria-hidden
      >
        {badge}
      </span>
    </motion.button>
  )
}

export const AppTile = memo(AppTileInner)
