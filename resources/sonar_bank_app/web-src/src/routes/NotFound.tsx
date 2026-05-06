import { Link } from 'react-router-dom'
import { Button, Card, CardContent, CardDescription, CardEyebrow, CardHeader, CardTitle } from '@/components/ui'

export function NotFound() {
  return (
    <div className="min-h-screen bg-surface-abyss text-text-primary flex items-center justify-center p-6">
      <Card variant="glass" padding="xl" className="max-w-md w-full text-center">
        <CardHeader>
          <CardEyebrow>404</CardEyebrow>
          <CardTitle>Ruta no encontrada</CardTitle>
          <CardDescription>
            La pantalla solicitada no existe o aún no ha sido implementada en BANK-FE.1.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Link to="/">
            <Button variant="primary" fullWidth>Volver al inicio</Button>
          </Link>
        </CardContent>
      </Card>
    </div>
  )
}
