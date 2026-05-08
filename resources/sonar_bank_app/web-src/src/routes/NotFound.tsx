import { Link } from 'react-router-dom'
import { Button, Card, CardContent, CardDescription, CardEyebrow, CardHeader, CardTitle } from '@/components/ui'
import { useI18n } from '@/lib/i18n'

export function NotFound() {
  const { t } = useI18n()
  return (
    <div className="min-h-screen bg-surface-abyss text-text-primary flex items-center justify-center p-6">
      <Card variant="glass" padding="xl" className="max-w-md w-full text-center">
        <CardHeader>
          <CardEyebrow>404</CardEyebrow>
          <CardTitle>{t('notFound.title')}</CardTitle>
          <CardDescription>
            {t('notFound.description')}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Link to="/">
            <Button variant="primary" fullWidth>{t('notFound.backHome')}</Button>
          </Link>
        </CardContent>
      </Card>
    </div>
  )
}
