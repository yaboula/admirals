import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'node:path'

// https://vite.dev/config/
// SONAR Tablet — stack FROZEN per ADR-016 D5 (React 18.3 + Vite 5 + Tailwind v4).
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  // Relative paths obligatorios para FiveM NUI (carga via file:// style resource URL).
  base: './',
  build: {
    target: 'es2023',
    // FiveM resource pattern: assets servidos desde `resources/sonar_tablet/web/`.
    // `ui_page 'web/index.html'` + `files { 'web/**/*' }` en fxmanifest.lua.
    outDir: '../web',
    emptyOutDir: true,
    sourcemap: false,
    // D6 NUI perf budget: chunk warning a 500KB (gzipped budget hard).
    chunkSizeWarningLimit: 500,
  },
  // Bundle audit: ejecutar `npx vite-bundle-visualizer` post-build para verificar D6 budgets.
})
