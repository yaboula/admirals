import { cn } from '@/lib/utils'
import afroManWithVrUrl from '@/assets/avatars/afro-man-with-vr.png'
import boyWithVrUrl from '@/assets/avatars/boy-with-vr.png'
import minerUrl from '@/assets/avatars/miner.png'
import shortHairManWithBucketHatUrl from '@/assets/avatars/short-hair-man-with-bucket-hat.png'
import shortHairManWithSweaterUrl from '@/assets/avatars/short-hair-man-with-sweater.png'
import thiefWithBlackHoodieUrl from '@/assets/avatars/thief-with-black-hoodie.png'

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
  'linear-gradient(135deg, rgb(248, 123, 92), rgb(156, 67, 63))',
  'linear-gradient(135deg, rgb(45, 192, 142), rgb(0, 72, 93))',
  'linear-gradient(135deg, rgb(211, 170, 100), rgb(131, 78, 54))',
  'linear-gradient(135deg, rgb(139, 135, 216), rgb(11, 81, 127))',
  'linear-gradient(135deg, rgb(244, 176, 175), rgb(155, 66, 81))',
]

const AVATAR_IMAGES = [
  boyWithVrUrl,
  afroManWithVrUrl,
  thiefWithBlackHoodieUrl,
  shortHairManWithSweaterUrl,
  shortHairManWithBucketHatUrl,
  minerUrl,
]

export function BankAvatar({ name, size = 'md', seed, className }: BankAvatarProps) {
  const label = name?.trim() || 'Contacto'
  const index = Math.abs(seed ?? hashString(label)) % AVATAR_GRADIENTS.length
  const imageUrl = AVATAR_IMAGES[Math.abs(seed ?? hashString(label)) % AVATAR_IMAGES.length]

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
        border: '1px solid rgba(255,255,255,0.18)',
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.24), 0 8px 18px -10px rgba(0,0,0,0.8)',
      }}
      aria-label={label}
      title={label}
    >
      <img
        src={imageUrl}
        alt=""
        className="h-full w-full object-cover scale-110"
        loading="lazy"
      />
    </span>
  )
}

function hashString(value: string): number {
  let hash = 0
  for (let i = 0; i < value.length; i++) {
    hash = (hash << 5) - hash + value.charCodeAt(i)
    hash |= 0
  }
  return hash
}
