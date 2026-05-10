import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { RouterProvider } from 'react-router-dom'
import { router } from './router'
import { isInsideFiveMNui, isMockMode } from './lib/env'
import { installMockHandlers } from './data/mock/register'
import { RootErrorBoundary } from './components/errors/RootErrorBoundary'
import './styles/index.css'

if (isMockMode() || !isInsideFiveMNui()) {
  installMockHandlers()
}

const rootEl = document.getElementById('root')
if (!rootEl) {
  throw new Error('SONAR Bank: #root element missing in index.html')
}

// Last-resort global handlers: any uncaught error or rejected promise that
// bypasses React's render lifecycle is logged here. Without this, FiveM's CEF
// silently swallows them and the user sees a black screen.
window.addEventListener('error', (event) => {
  console.error('[SONAR Bank] window.onerror', {
    message: event.message,
    filename: event.filename,
    lineno: event.lineno,
    colno: event.colno,
    error: event.error,
  })
})
window.addEventListener('unhandledrejection', (event) => {
  console.error('[SONAR Bank] unhandledrejection', {
    reason: event.reason,
  })
})

createRoot(rootEl).render(
  <StrictMode>
    <RootErrorBoundary>
      <RouterProvider router={router} />
    </RootErrorBoundary>
  </StrictMode>,
)
