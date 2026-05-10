import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'

export interface SpinnerProps {
  size?: 'xs' | 'sm' | 'md' | 'lg'
  variant?: 'brand' | 'neutral' | 'inverse'
  className?: string
  'aria-label'?: string
}

const SIZE_PX: Record<NonNullable<SpinnerProps['size']>, number> = {
  xs: 12,
  sm: 16,
  md: 20,
  lg: 28,
}

const STROKE: Record<NonNullable<SpinnerProps['size']>, number> = {
  xs: 2,
  sm: 2,
  md: 2.5,
  lg: 3,
}

const VARIANT_COLOR: Record<NonNullable<SpinnerProps['variant']>, string> = {
  brand: 'rgb(246, 75, 0)',
  neutral: 'rgba(247,248,252,0.72)',
  inverse: 'rgb(0, 0, 0)',
}

export function Spinner({
  size = 'md',
  variant = 'brand',
  className,
  'aria-label': ariaLabel,
}: SpinnerProps) {
  const { t } = useI18n()
  const px = SIZE_PX[size]
  const stroke = STROKE[size]
  const color = VARIANT_COLOR[variant]
  const trackColor = 'rgba(247,248,252,0.12)'

  return (
    <span
      role="status"
      aria-label={ariaLabel ?? t('common.loading')}
      className={cn('inline-flex items-center justify-center', className)}
      style={{ width: px, height: px }}
    >
      <svg
        width={px}
        height={px}
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{
          animation: 'tactile-spin 800ms linear infinite',
          willChange: 'transform',
        }}
      >
        <circle cx="12" cy="12" r="9" stroke={trackColor} strokeWidth={stroke} fill="none" />
        <path
          d="M21 12a9 9 0 0 0-9-9"
          stroke={color}
          strokeWidth={stroke}
          strokeLinecap="round"
          fill="none"
        />
      </svg>
      <style>{`
        @keyframes tactile-spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        @media (prefers-reduced-motion: reduce) {
          [role='status'] svg { animation: none !important; }
        }
      `}</style>
    </span>
  )
}
