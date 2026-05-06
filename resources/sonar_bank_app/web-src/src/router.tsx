import { createBrowserRouter, createHashRouter } from 'react-router-dom'
import { App } from './App'
import { Splash } from './routes/Splash'
import { DevShowcase } from './routes/dev/Showcase'
import { NotFound } from './routes/NotFound'
import { isInsideFiveMNui } from './lib/env'

const routes = [
  {
    path: '/',
    element: <App />,
    children: [
      { index: true, element: <Splash /> },
      { path: 'dev/showcase', element: <DevShowcase /> },
    ],
  },
  { path: '*', element: <NotFound /> },
]

export const router = isInsideFiveMNui()
  ? createHashRouter(routes)
  : createBrowserRouter(routes)
