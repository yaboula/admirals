import { useState } from 'react'
import { ArrowRight, Search, Send, ShieldAlert, Wallet } from 'lucide-react'
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardDescription,
  CardEyebrow,
  CardFooter,
  CardHeader,
  CardTitle,
  IconButton,
  Input,
  Spinner,
} from '@/components/ui'
import { MotionPreset } from '@/components/motion/MotionPreset'
import { sfx } from '@/lib/sfx'
import { useI18n } from '@/lib/i18n'
import { FE_VERSION } from '@/lib/env'

export function DevShowcase() {
  const { t } = useI18n()
  const [loading, setLoading] = useState(false)
  const [muted, setMuted] = useState(sfx.getMuted())
  const [amount, setAmount] = useState('')
  const [error, setError] = useState<string | undefined>(undefined)

  const toggleMute = (): void => {
    const next = !muted
    sfx.setMuted(next)
    setMuted(next)
  }

  const validate = (v: string): void => {
    setAmount(v)
    if (v && Number(v) > 5000) setError('Exceeds the $5,000 transfer limit')
    else setError(undefined)
  }

  return (
    <div className="min-h-screen bg-surface-abyss text-text-primary">
      <div className="tactile-vista-hero-light">
        <div className="mx-auto max-w-6xl px-6 py-10 flex flex-col gap-8">

          <header className="flex flex-col gap-2">
            <span className="text-xs uppercase tracking-widest font-medium text-text-tertiary">
              SONAR Bank — BANK-FE.1 dev showcase
            </span>
            <h1 className="text-3xl font-semibold tracking-tight">Tactile UI Primitives</h1>
            <p className="text-sm text-text-secondary max-w-2xl">
              Capa fundacional R1: 5 primitives canonical (Button, IconButton, Input, Card, Badge) +
              Spinner stub. Multi-layer box-shadow ladder + radial diffuse glow + premium
              glassmorphism. Frontend v{FE_VERSION}.
            </p>
            <div className="flex items-center gap-2 mt-1">
              <Badge tone="brand" variant="soft" pulse>BANK-FE.1</Badge>
              <Badge tone="native_full" variant="soft">native_full</Badge>
              <Badge tone="lite_mode_active" variant="soft">lite_mode_active</Badge>
              <Badge tone="compromised" variant="soft">compromised</Badge>
              <Badge tone="framework_missing" variant="soft">framework_missing</Badge>
            </div>
          </header>

          {/* ============================================================ */}
          {/* Buttons */}
          {/* ============================================================ */}
          <MotionPreset preset="fade-up">
            <Card padding="lg">
              <CardHeader divided>
                <CardEyebrow>P-01</CardEyebrow>
                <CardTitle>Button</CardTitle>
                <CardDescription>4 variants × 3 sizes + loading + iconos. SFX integrado (depth_press / console_tap).</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-3 items-center">
                  <Button variant="primary">{t('dev.confirm')}</Button>
                  <Button variant="secondary">{t('dev.cancel')}</Button>
                  <Button variant="ghost">{t('dev.viewDetail')}</Button>
                  <Button variant="danger" leftIcon={<ShieldAlert size={16} />}>{t('dev.blockCard')}</Button>
                </div>
                <div className="flex flex-wrap gap-3 items-center">
                  <Button size="sm">Small</Button>
                  <Button size="md">Medium</Button>
                  <Button size="lg" rightIcon={<ArrowRight size={18} />}>Large + icon</Button>
                </div>
                <div className="flex flex-wrap gap-3 items-center">
                  <Button
                    loading={loading}
                    onClick={() => {
                      setLoading(true)
                      window.setTimeout(() => setLoading(false), 1200)
                    }}
                  >
                    {loading ? t('dev.processing') : t('dev.triggerLoading')}
                  </Button>
                  <Button disabled>Disabled</Button>
                  <Button fullWidth variant="primary" leftIcon={<Send size={16} />}>
                    {t('dev.transferFullWidth')}
                  </Button>
                </div>
              </CardContent>
            </Card>
          </MotionPreset>

          {/* ============================================================ */}
          {/* IconButton */}
          {/* ============================================================ */}
          <MotionPreset preset="fade-up">
            <Card padding="lg">
              <CardHeader divided>
                <CardEyebrow>P-02</CardEyebrow>
                <CardTitle>IconButton</CardTitle>
                <CardDescription>4 variants × 4 sizes + square/circle. aria-label obligatorio.</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-3 items-center">
                  <IconButton aria-label={t('dev.search')} icon={<Search size={16} />} variant="primary" size="sm" />
                  <IconButton aria-label={t('dev.search')} icon={<Search size={18} />} variant="secondary" size="md" />
                  <IconButton aria-label={t('dev.search')} icon={<Search size={20} />} variant="ghost" size="lg" />
                  <IconButton aria-label={t('dev.search')} icon={<Search size={20} />} variant="danger" size="lg" shape="circle" />
                  <IconButton aria-label="Mute SFX" icon={<Wallet size={18} />} variant="secondary" onClick={toggleMute} />
                  <Badge tone={muted ? 'warning' : 'success'} variant="soft">
                    SFX {muted ? 'muted' : 'on'}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          </MotionPreset>

          {/* ============================================================ */}
          {/* Input */}
          {/* ============================================================ */}
          <MotionPreset preset="fade-up">
            <Card padding="lg">
              <CardHeader divided>
                <CardEyebrow>P-03</CardEyebrow>
                <CardTitle>Input</CardTitle>
                <CardDescription>Bevel inset pressed-into-surface. Estados: default / focus / disabled / error.</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-3xl">
                  <Input label={t('dev.recipientIban')} placeholder="ES91 2100 0418 4502 0005 1332" />
                  <Input
                    label="Amount ($)"
                    placeholder="0.00"
                    leftAdornment={<span className="text-text-tertiary">$</span>}
                    value={amount}
                    onChange={(e) => validate(e.target.value)}
                    error={error}
                    hint={error ? undefined : '$5,000 transfer limit'}
                    inputMode="decimal"
                  />
                  <Input label={t('dev.concept')} placeholder="Alquiler mes en curso" hint={t('dev.maxChars')} maxLength={64} />
                  <Input label="Disabled" placeholder="No editable" disabled />
                </div>
              </CardContent>
            </Card>
          </MotionPreset>

          {/* ============================================================ */}
          {/* Card variants */}
          {/* ============================================================ */}
          <MotionPreset preset="fade-up">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <Card variant="baseline" padding="lg">
                <CardEyebrow>BASELINE</CardEyebrow>
                <CardTitle>Tactile card</CardTitle>
                <CardDescription>
                  Multi-layer shadow + inset bevel highlight (top) + bottom shadow
                  (bottom). Gradient orange diffuse 24% radius bottom-right.
                </CardDescription>
              </Card>
              <Card variant="elevated" padding="lg" hero>
                <CardEyebrow>ELEVATED + HERO GLOW</CardEyebrow>
                <CardTitle>Hero card</CardTitle>
                <CardDescription>
                  Card elevated con radial top-glow signal-orange interno (gradient
                  primary-glow) + bevel reforzado.
                </CardDescription>
              </Card>
              <Card variant="glass" padding="lg" interactive>
                <CardEyebrow>GLASS</CardEyebrow>
                <CardTitle>Premium glassmorphism</CardTitle>
                <CardDescription>
                  bg-black/40 + backdrop-blur 24px saturate 180% + edge highlight
                  mask-composite (1px gradient). Click → console_tap SFX.
                </CardDescription>
                <CardFooter divided>
                  <Button variant="ghost" size="sm">{t('dev.close')}</Button>
                  <Button variant="primary" size="sm" rightIcon={<ArrowRight size={14} />}>{t('dev.continue')}</Button>
                </CardFooter>
              </Card>
            </div>
          </MotionPreset>

          {/* ============================================================ */}
          {/* Badge full matrix */}
          {/* ============================================================ */}
          <MotionPreset preset="fade-up">
            <Card padding="lg">
              <CardHeader divided>
                <CardEyebrow>P-05</CardEyebrow>
                <CardTitle>Badge</CardTitle>
                <CardDescription>10 tones (incl. 4 status badge bridges Q11) × 3 variants × 3 sizes.</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {(['neutral','brand','success','warning','danger','info'] as const).map((t) => (
                    <Badge key={`solid-${t}`} tone={t} variant="solid">{t}</Badge>
                  ))}
                </div>
                <div className="flex flex-wrap gap-2">
                  {(['neutral','brand','success','warning','danger','info'] as const).map((t) => (
                    <Badge key={`soft-${t}`} tone={t} variant="soft">{t}</Badge>
                  ))}
                </div>
                <div className="flex flex-wrap gap-2">
                  {(['neutral','brand','success','warning','danger','info'] as const).map((t) => (
                    <Badge key={`outline-${t}`} tone={t} variant="outline">{t}</Badge>
                  ))}
                </div>
              </CardContent>
            </Card>
          </MotionPreset>

          {/* ============================================================ */}
          {/* Spinner */}
          {/* ============================================================ */}
          <MotionPreset preset="fade-up">
            <Card padding="lg">
              <CardHeader divided>
                <CardEyebrow>P-10 (stub)</CardEyebrow>
                <CardTitle>Spinner</CardTitle>
                <CardDescription>4 sizes × 3 variants. Token-driven, prefers-reduced-motion safe.</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-6 items-center">
                  <Spinner size="xs" />
                  <Spinner size="sm" />
                  <Spinner size="md" />
                  <Spinner size="lg" />
                  <Spinner size="lg" variant="neutral" />
                </div>
              </CardContent>
            </Card>
          </MotionPreset>

          <footer className="text-xs text-text-tertiary mt-2">
            Tactile UI doctrine ADR-017 D2/D3/D4 — flat designs prohibidos. Stack 2026 absolute.
          </footer>

        </div>
      </div>
    </div>
  )
}
