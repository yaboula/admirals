import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import tailwindcss from '@tailwindcss/vite'
import path from 'node:path'

export default defineConfig(({ mode }) => ({
  plugins: [
    react(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    outDir: '../web',
    emptyOutDir: true,
    target: 'chrome111',
    cssTarget: 'chrome111',
    sourcemap: mode !== 'production',
    rollupOptions: {
      output: {
        assetFileNames: 'assets/[name]-[hash][extname]',
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
        manualChunks: (id) => {
          if (id.includes('node_modules/recharts') || id.includes('node_modules/victory-vendor')) {
            return 'vendor-charts'
          }
          if (id.includes('node_modules/framer-motion')) {
            return 'vendor-motion'
          }
          if (id.includes('node_modules/@tanstack')) {
            return 'vendor-query'
          }
          if (id.includes('node_modules/zod') || id.includes('node_modules/react-hook-form')) {
            return 'vendor-forms'
          }
          if (id.includes('node_modules/react-dom') || id.includes('node_modules/react-router')) {
            return 'vendor-react'
          }
          if (id.includes('node_modules/react/') || id.includes('node_modules/react-i18next') || id.includes('node_modules/i18next')) {
            return 'vendor-react'
          }
        },
      },
    },
  },
  server: {
    port: 5173,
    strictPort: false,
    host: '127.0.0.1',
  },
  base: './',
  define: {
    'import.meta.env.VITE_BANK_FE_VERSION': JSON.stringify('0.1.0-bank-fe.1'),
  },
}))
