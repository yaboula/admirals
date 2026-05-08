import { Link } from 'react-router-dom'
import { Badge, Button, Card, CardContent, CardDescription, CardEyebrow, CardHeader, CardTitle } from '@/components/ui'
import { useI18n } from '@/lib/i18n'
import { FE_VERSION } from '@/lib/env'

export function Splash() {
  const { t } = useI18n()
  return (
    <div className="min-h-screen bg-surface-abyss text-text-primary flex items-center justify-center p-6">
      <div className="tactile-vista-hero-light w-full max-w-2xl">
        <Card variant="glass" padding="xl" hero>
          <CardHeader divided>
            <CardEyebrow>SONAR Bank — Phase A</CardEyebrow>
            <CardTitle>BANK-FE.1 — Foundation layer R1</CardTitle>
            <CardDescription>
              Foundation layer active. 5 Tactile UI primitives ready. Canonical Zustand
              stores instantiated. Stack 2026 absolute locked (ADR-017 D5).
            </CardDescription>
            <div className="flex flex-wrap gap-2 mt-2">
              <Badge tone="brand" variant="soft" pulse>BANK-FE.1 ACTIVE</Badge>
              <Badge tone="success" variant="soft">Backend LOCKED v1.0.1 R1</Badge>
              <Badge tone="info" variant="soft">FE v{FE_VERSION}</Badge>
            </div>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-text-secondary">
              Dev Showcase Page exposes the 5 canonical primitives (P-01..P-05) +
              Spinner stub for founder / Frontend Lead visual review.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link to="/dev/showcase">
                <Button variant="primary">{t('splash.openDevShowcase')}</Button>
              </Link>
              <Button variant="ghost" disabled>Bank Home (BANK-FE.2)</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
