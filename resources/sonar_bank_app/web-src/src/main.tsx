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

// =============================================================================
// CRITICAL: FiveM NUI transparency.
// =============================================================================
// When the resource starts, CEF mounts the page on top of the game viewport.
// If <html>, <body>, or #root paint ANY opaque background, the game world is
// hidden behind a solid layer — the user sees a "black screen" the moment the
// resource loads, even before React renders anything visible.
//
// The CSS body:has(.bank-device-viewport) rule does NOT solve this because
// .bank-device-viewport only exists in the DOM when visible=true (after the
// /bank command). Before that, body keeps its --color-surface-abyss
// background and covers the game world.
//
// The inline <style> in index.html sets `background: 0 0 !important` (which
// LightningCSS produced from `transparent`). Some older CEF builds parse the
// shorthand inconsistently. Setting the longhand `backgroundColor` directly
// via JS is unambiguous and applied before the first React render.
// =============================================================================
if (isInsideFiveMNui()) {
  document.documentElement.style.backgroundColor = 'transparent'
  document.body.style.backgroundColor = 'transparent'
}

const rootEl = document.getElementById('root')
if (!rootEl) {
  throw new Error('SONAR Bank: #root element missing in index.html')
}
rootEl.style.backgroundColor = 'transparent'

createRoot(rootEl).render(
  <StrictMode>
    <RouterProvider router={router} />
  </StrictMode>,
)
