import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { RouterProvider } from 'react-router-dom'
import { router } from './router'
import { isInsideFiveMNui, isMockMode } from './lib/env'
import { installMockHandlers } from './data/mock/register'
import './styles/index.css'

if (isMockMode() || !isInsideFiveMNui()) {
  installMockHandlers()
}

const rootEl = document.getElementById('root')
if (!rootEl) {
  throw new Error('SONAR Bank: #root element missing in index.html')
}

createRoot(rootEl).render(
  <StrictMode>
    <RouterProvider router={router} />
  </StrictMode>,
)
