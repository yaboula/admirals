import { cn } from '@/lib/utils'

export interface BankAvatarProps {
  name: string | null | undefined
  size?: 'sm' | 'md' | 'lg'
  seed?: number
  className?: string
}

const SIZE_CLASS = {
  sm: 'h-8 w-8 text-[10px]',
  md: 'h-10 w-10 text-xs',
  lg: 'h-12 w-12 text-sm',
} satisfies Record<NonNullable<BankAvatarProps['size']>, string>

const AVATAR_GRADIENTS = [
  'linear-gradient(135deg, oklch(0.72 0.16 35), oklch(0.50 0.12 25))',
  'linear-gradient(135deg, oklch(0.72 0.14 165), oklch(0.36 0.10 215))',
  'linear-gradient(135deg, oklch(0.76 0.10 80), oklch(0.48 0.08 45))',
  'linear-gradient(135deg, oklch(0.66 0.12 285), oklch(0.42 0.10 245))',
  'linear-gradient(135deg, oklch(0.82 0.08 20), oklch(0.50 0.12 12))',
]

export function BankAvatar({ name, size = 'md', seed, className }: BankAvatarProps) {
  const label = name?.trim() || 'Contacto'
  const initials = getInitials(label)
  const index = Math.abs(seed ?? hashString(label)) % AVATAR_GRADIENTS.length

  return (
    <span
      className={cn(
        'inline-flex items-center justify-center rounded-full shrink-0 overflow-hidden',
        'font-semibold text-white tactile-wght-breathing select-none',
        SIZE_CLASS[size],
        className,
      )}
      style={{
        background: AVATAR_GRADIENTS[index],
        border: '1px solid oklch(1 0 0 / 0.18)',
        boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 0.24), 0 8px 18px -10px oklch(0 0 0 / 0.8)',
      }}
      aria-label={label}
      title={label}
    >
      {initials}
    </span>
  )
}

function getInitials(value: string): string {
  return value
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase() || '··'
}

function hashString(value: string): number {
  let hash = 0
  for (let i = 0; i < value.length; i++) {
    hash = (hash << 5) - hash + value.charCodeAt(i)
    hash |= 0
  }
  return hash
}
