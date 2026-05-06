import { Link } from 'react-router-dom'
import { Badge, Button, Card, CardContent, CardDescription, CardEyebrow, CardHeader, CardTitle } from '@/components/ui'
import { FE_VERSION } from '@/lib/env'

export function Splash() {
  return (
    <div className="min-h-screen bg-surface-abyss text-text-primary flex items-center justify-center p-6">
      <div className="tactile-vista-hero-light w-full max-w-2xl">
        <Card variant="glass" padding="xl" hero>
          <CardHeader divided>
            <CardEyebrow>SONAR Bank — Phase A</CardEyebrow>
            <CardTitle>BANK-FE.1 — Capa fundacional R1</CardTitle>
            <CardDescription>
              Foundation layer activa. 5 primitives Tactile UI listos. Stores Zustand
              canonical instanciados. Stack 2026 absolute lockeado (ADR-017 D5).
            </CardDescription>
            <div className="flex flex-wrap gap-2 mt-2">
              <Badge tone="brand" variant="soft" pulse>BANK-FE.1 ACTIVE</Badge>
              <Badge tone="success" variant="soft">Backend LOCKED v1.0.1 R1</Badge>
              <Badge tone="info" variant="soft">FE v{FE_VERSION}</Badge>
            </div>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-text-secondary">
              Dev Showcase Page expone los 5 primitives canonical (P-01..P-05) +
              Spinner stub para revisión visual founder/Frontend Lead.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link to="/dev/showcase">
                <Button variant="primary">Abrir Dev Showcase</Button>
              </Link>
              <Button variant="ghost" disabled>Bank Home (BANK-FE.2)</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
