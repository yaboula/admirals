import { useState } from 'react'
import { motion } from 'motion/react'
import { Coins, Loader2, ScanSearch } from 'lucide-react'
import { useI18n } from '@/lib/i18n'
import { useAceGate } from '@/components/security'
import { ACE_PERMS } from '@/lib/ace'
import { useTaxBracketsQuery, useTaxCycleQuery, usePolicyLogQuery } from '../data/queries/govtTax'
import { BracketEditor } from './tax/BracketEditor'
import { CollectionPanel } from './tax/CollectionPanel'
import { PolicyLog } from './tax/PolicyLog'
import type { GovtTaxTierId } from '../data/contracts'

/* ============================================================================
   Tax Engine "Policy Studio" — Authority Black design language.

   Design decisions:
   - Near-pure black backgrounds (0.05-0.08 lightness, 0.008-0.012 chroma 252)
   - Blue accent: ONLY atmospheric radial behind hero + single selected-state
     border. NO blue fills on interactive elements.
   - ONE signature glow: the ring arc in CollectionPanel (green, represents
     economic health, not decorative noise).
   - Breathing room: 24-32px section gaps, large typography for key metrics.
   - Neon: zero except the bracket slider thumb when a tier is edited
     (communicates active mutation, then disappears on save).
   ============================================================================ */

export function TaxEngine() {
  const { t } = useI18n()
  const granted = useAceGate({ require: ACE_PERMS.P11.perm })

  const bracketsQuery = useTaxBracketsQuery()
  const cycleQuery = useTaxCycleQuery()
  const logQuery = usePolicyLogQuery()

  const [draftRates, setDraftRates] = useState<Map<GovtTaxTierId, number>>(new Map())

  const isLoading = bracketsQuery.isLoading || cycleQuery.isLoading || logQuery.isLoading
  const brackets = bracketsQuery.data ?? []
  const cycle = cycleQuery.data
  const changes = logQuery.data ?? []

  if (!granted) return <PermissionDenied />

  return (
    <div
      className="relative flex h-full flex-col overflow-y-auto"
      style={{ background: 'rgb(0, 0, 1)' }}
    >
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 top-0 h-[280px]"
        style={{
          background: 'radial-gradient(ellipse 80% 100% at 50% -10%, rgba(34,145,248,0.12), transparent)',
        }}
      />

      <div className="relative z-10 flex flex-col gap-6 p-4 pb-8 lg:p-6">
        <PageHeader isLoading={isLoading} />

        {isLoading ? (
          <SkeletonGrid />
        ) : (
          <>
            <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
              <Section title={t('govt.tax.section.editor')} hint={t('govt.tax.section.editorHint')}>
                <BracketEditor
                  brackets={brackets}
                  onDraftChange={setDraftRates}
                />
              </Section>

              <Section title={t('govt.tax.section.collection')} hint={cycle?.cycleId ?? ''}>
                {cycle ? (
                  <CollectionPanel
                    stats={cycle}
                    brackets={brackets}
                    draftRates={draftRates.size > 0 ? draftRates : undefined}
                  />
                ) : null}
              </Section>
            </div>

            <PolicyLog changes={changes} />
          </>
        )}
      </div>
    </div>
  )
}

/* ---- page header --------------------------------------------------------- */

function PageHeader({ isLoading }: { isLoading: boolean }) {
  const { t } = useI18n()
  return (
    <motion.header
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
      className="flex flex-wrap items-end justify-between gap-4 border-b pb-5"
      style={{ borderColor: 'rgb(4, 6, 8)' }}
    >
      <div className="flex items-center gap-4">
        <div
          className="flex h-11 w-11 items-center justify-center rounded-2xl border"
          style={{
            background: 'radial-gradient(circle at 40% 30%, rgb(3, 18, 37), rgb(1, 2, 4))',
            borderColor: 'rgb(16, 27, 40)',
          }}
          aria-hidden
        >
          <Coins size={18} strokeWidth={1.7} style={{ color: 'rgb(90, 178, 255)' }} />
        </div>
        <div>
          <h1
            className="text-xl font-extralight tracking-[-0.03em]"
            style={{ color: 'rgb(240, 242, 244)' }}
          >
            {t('govt.tax.title')}
          </h1>
          <p className="mt-0.5 text-xs" style={{ color: 'rgb(82, 86, 90)' }}>
            {t('govt.tax.subtitle')}
          </p>
        </div>
      </div>

      <div className="flex items-center gap-2">
        {isLoading ? (
          <Loader2 size={14} className="animate-spin" style={{ color: 'rgb(90, 94, 99)' }} />
        ) : null}
        <span
          className="rounded-full border px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.14em]"
          style={{
            borderColor: 'rgba(34,145,248,0.28)',
            background: 'rgba(34,145,248,0.08)',
            color: 'rgb(94, 168, 249)',
          }}
        >
          {`P11 · ${t('govt.tax.ace.label')}`}
        </span>
      </div>
    </motion.header>
  )
}

/* ---- section wrapper ----------------------------------------------------- */

function Section({ title, hint, children }: { title: string; hint?: string; children: React.ReactNode }) {
  return (
    <motion.section
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.24 }}
    >
      <div className="mb-3 flex items-baseline justify-between gap-2">
        <h2
          className="text-[11px] font-semibold uppercase tracking-[0.18em]"
          style={{ color: 'rgb(101, 105, 111)' }}
        >
          {title}
        </h2>
        {hint ? (
          <span className="text-[10px] font-mono" style={{ color: 'rgb(58, 61, 65)' }}>{hint}</span>
        ) : null}
      </div>
      {children}
    </motion.section>
  )
}

/* ---- loading skeleton ---------------------------------------------------- */

function SkeletonGrid() {
  return (
    <div className="grid gap-5 lg:grid-cols-2">
      {[0, 1].map((i) => (
        <div key={i} className="space-y-3">
          <div className="h-3 w-32 animate-pulse rounded-full" style={{ background: 'rgb(4, 6, 8)' }} />
          {[0, 1, 2, 3].map((j) => (
            <div key={j} className="h-16 animate-pulse rounded-2xl" style={{ background: 'rgb(1, 2, 3)', animationDelay: `${j * 60}ms` }} />
          ))}
        </div>
      ))}
    </div>
  )
}

/* ---- permission denied --------------------------------------------------- */

function PermissionDenied() {
  const { t } = useI18n()
  return (
    <div
      className="flex h-full items-center justify-center p-6"
      style={{ background: 'rgb(0, 0, 1)' }}
    >
      <div
        className="flex max-w-sm flex-col items-center gap-4 rounded-2xl border p-8 text-center"
        style={{ background: 'rgb(1, 1, 2)', borderColor: 'rgb(9, 11, 14)' }}
      >
        <span
          aria-hidden
          className="flex h-12 w-12 items-center justify-center rounded-full border"
          style={{
            background: 'rgb(1, 3, 7)',
            borderColor: 'rgb(15, 23, 31)',
            color: 'rgb(34, 145, 248)',
          }}
        >
          <ScanSearch size={20} strokeWidth={1.6} />
        </span>
        <div>
          <p className="text-sm font-semibold" style={{ color: 'rgb(227, 229, 231)' }}>{t('nav.permissionRequired')}</p>
          <p className="mt-2 text-xs leading-relaxed" style={{ color: 'rgb(90, 94, 98)' }}>
            {t('govt.tax.permissionHint')}
          </p>
        </div>
      </div>
    </div>
  )
}
