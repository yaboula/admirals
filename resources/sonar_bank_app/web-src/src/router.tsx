import { lazy, Suspense } from 'react'
import { createBrowserRouter, createHashRouter } from 'react-router-dom'
import { App } from './App'
import { AppShell } from './components/layout/AppShell'
import { isInsideFiveMNui } from './lib/env'

const Home = lazy(() => import('./routes/Home').then(m => ({ default: m.Home })))
const Accounts = lazy(() => import('./routes/Accounts').then(m => ({ default: m.Accounts })))
const Transactions = lazy(() => import('./routes/Transactions').then(m => ({ default: m.Transactions })))
const Cards = lazy(() => import('./routes/Cards').then(m => ({ default: m.Cards })))
const Transfer = lazy(() => import('./routes/Transfer').then(m => ({ default: m.Transfer })))
const RecurringPayments = lazy(() => import('./routes/Recurring').then(m => ({ default: m.RecurringPayments })))
const Settings = lazy(() => import('./routes/Settings').then(m => ({ default: m.Settings })))
const Audit = lazy(() => import('./routes/Audit').then(m => ({ default: m.Audit })))
const Business = lazy(() => import('./routes/Business').then(m => ({ default: m.Business })))
const Investments = lazy(() => import('./routes/Investments').then(m => ({ default: m.Investments })))
const Loans = lazy(() => import('./routes/Loans').then(m => ({ default: m.Loans })))
const Atm = lazy(() => import('./routes/Atm').then(m => ({ default: m.Atm })))
const DevShowcase = lazy(() => import('./routes/dev/Showcase').then(m => ({ default: m.DevShowcase })))
const NotFound = lazy(() => import('./routes/NotFound').then(m => ({ default: m.NotFound })))

function RouteLoader() {
  return (
    <div className="flex h-full items-center justify-center" aria-busy="true" aria-label="Loading">
      <div className="h-5 w-5 animate-spin rounded-full border-2 border-white/10 border-t-[oklch(0.65_0.22_40)]" />
    </div>
  )
}

function S({ children }: { children: React.ReactNode }) {
  return <Suspense fallback={<RouteLoader />}>{children}</Suspense>
}

const routes = [
  {
    path: '/',
    element: <App />,
    children: [
      { path: 'atm', element: <S><Atm /></S> },
      {
        path: '/',
        element: <AppShell />,
        children: [
          { index: true, element: <S><Home /></S> },
          { path: 'cuentas', element: <S><Accounts /></S> },
          { path: 'transacciones', element: <S><Transactions /></S> },
          { path: 'tarjetas', element: <S><Cards /></S> },
          { path: 'transferir', element: <S><Transfer /></S> },
          { path: 'recurrentes', element: <S><RecurringPayments /></S> },
          { path: 'ajustes', element: <S><Settings /></S> },
          { path: 'auditoria', element: <S><Audit /></S> },
          { path: 'empresas', element: <S><Business /></S> },
          { path: 'inversiones', element: <S><Investments /></S> },
          { path: 'creditos', element: <S><Loans /></S> },
          { path: 'dev/showcase', element: <S><DevShowcase /></S> },
        ],
      },
    ],
  },
  { path: '*', element: <S><NotFound /></S> },
]

export const router = isInsideFiveMNui()
  ? createHashRouter(routes)
  : createBrowserRouter(routes)
