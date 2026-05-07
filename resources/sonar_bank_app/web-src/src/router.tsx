import { createBrowserRouter, createHashRouter } from 'react-router-dom'
import { App } from './App'
import { AppShell } from './components/layout/AppShell'
import { Home } from './routes/Home'
import { Accounts } from './routes/Accounts'
import { Transactions } from './routes/Transactions'
import { Cards } from './routes/Cards'
import { Transfer } from './routes/Transfer'
import { RecurringPayments } from './routes/Recurring'
import { DevShowcase } from './routes/dev/Showcase'
import { NotFound } from './routes/NotFound'
import { isInsideFiveMNui } from './lib/env'

const routes = [
  {
    path: '/',
    element: <App />,
    children: [
      {
        path: '/',
        element: <AppShell />,
        children: [
          { index: true, element: <Home /> },
          { path: 'cuentas', element: <Accounts /> },
          { path: 'transacciones', element: <Transactions /> },
          { path: 'tarjetas', element: <Cards /> },
          { path: 'transferir', element: <Transfer /> },
          { path: 'recurrentes', element: <RecurringPayments /> },
          { path: 'dev/showcase', element: <DevShowcase /> },
        ],
      },
    ],
  },
  { path: '*', element: <NotFound /> },
]

export const router = isInsideFiveMNui()
  ? createHashRouter(routes)
  : createBrowserRouter(routes)
