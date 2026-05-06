import { createBrowserRouter, createHashRouter } from 'react-router-dom'
import { App } from './App'
import { AppShell } from './components/layout/AppShell'
import { Home } from './routes/Home'
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
