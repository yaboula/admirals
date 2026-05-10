import { lazy, Suspense } from 'react'
import { createBrowserRouter, createHashRouter, Navigate, useLocation } from 'react-router-dom'
import { App } from './App'
import { AppShell } from './components/layout/AppShell'
import { isInsideFiveMNui } from './lib/env'
import { useAuthGate } from './stores/authGate'

const Auth = lazy(() => import('./routes/Auth').then(m => ({ default: m.Auth })))
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
const GovtShell = lazy(() => import('./govt/layout/GovtShell').then(m => ({ default: m.GovtShell })))
const Bureau = lazy(() => import('./govt/routes/Bureau').then(m => ({ default: m.Bureau })))
const Census = lazy(() => import('./govt/routes/Census').then(m => ({ default: m.Census })))
const Sanctions = lazy(() => import('./govt/routes/Sanctions').then(m => ({ default: m.Sanctions })))
const TaxEngine = lazy(() => import('./govt/routes/TaxEngine').then(m => ({ default: m.TaxEngine })))
const GovtBusiness = lazy(() => import('./govt/routes/GovtBusiness').then(m => ({ default: m.GovtBusiness })))
const GovtTreasury = lazy(() => import('./govt/routes/GovtTreasury').then(m => ({ default: m.GovtTreasury })))
const GovtSubsidies = lazy(() => import('./govt/routes/GovtSubsidies').then(m => ({ default: m.GovtSubsidies })))
const GovtReports = lazy(() => import('./govt/routes/GovtReports').then(m => ({ default: m.GovtReports })))

function RouteLoader() {
  return (
    <div className="flex h-full items-center justify-center" aria-busy="true" aria-label="Loading">
      <div className="h-5 w-5 animate-spin rounded-full border-2 border-white/10 border-t-[rgb(246, 75, 0)]" />
    </div>
  )
}

function S({ children }: { children: React.ReactNode }) {
  return <Suspense fallback={<RouteLoader />}>{children}</Suspense>
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const location = useLocation()
  const unlocked = useAuthGate((s) => s.unlocked)
  if (!unlocked) {
    return <Navigate to="/auth" replace state={{ from: `${location.pathname}${location.search}` }} />
  }
  return children
}

const routes = [
  {
    path: '/',
    element: <App />,
    children: [
      { path: 'auth', element: <S><Auth /></S> },
      { path: 'atm', element: <ProtectedRoute><S><Atm /></S></ProtectedRoute> },
      {
        path: 'tesoreria',
        element: <ProtectedRoute><S><GovtShell /></S></ProtectedRoute>,
        children: [
          { index: true, element: <S><Bureau /></S> },
          { path: 'censo', element: <S><Census /></S> },
          { path: 'sanciones', element: <S><Sanctions /></S> },
          { path: 'fiscal', element: <S><TaxEngine /></S> },
          { path: 'empresas', element: <S><GovtBusiness /></S> },
          { path: 'movimientos', element: <S><GovtTreasury /></S> },
          { path: 'subsidios', element: <S><GovtSubsidies /></S> },
          { path: 'informes', element: <S><GovtReports /></S> },
        ],
      },
      {
        path: '/',
        element: <ProtectedRoute><AppShell /></ProtectedRoute>,
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
