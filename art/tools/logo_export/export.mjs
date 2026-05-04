// -----------------------------------------------------------------------------
// SONAR Logo — SVG → PNG raster export pipeline (Puppeteer renderer)
// -----------------------------------------------------------------------------
// Generates PNG exports + favicon.ico from logo_v3 SVG sources.
//
// Renderer: Puppeteer (headless Chromium) — full web-font support via
// Google Fonts @import. librsvg/sharp deprecated por ignorar @font-face
// inline → renderizaba wordmark/lockups con system fallback (no Syncopate).
//
// Usage (from this dir):
//   npm install      # downloads Chromium (~300MB) on first run
//   npm run build
// -----------------------------------------------------------------------------

import puppeteer from 'puppeteer'
import pngToIco from 'png-to-ico'
import { readFile, writeFile, mkdir, unlink } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { resolve, dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const LOGO_DIR  = resolve(__dirname, '..', '..', 'branding', 'logo_v3')
const OUT_DIR   = resolve(LOGO_DIR, 'exports')

// ───────────────────────── Export matrix ─────────────────────────
const EXPORTS = [
  // Monograma orange (default)
  { source: 'monogram_s.svg',        prefix: 'monogram',          sizes: [16, 32, 64, 128, 256, 512, 1024] },
  // Monograma white (sobre orange/black)
  { source: 'monogram_s_white.svg',  prefix: 'monogram_white',    sizes: [64, 128, 256, 512] },
  // Monograma black (sobre white)
  { source: 'monogram_s_black.svg',  prefix: 'monogram_black',    sizes: [64, 128, 256, 512] },
  // Monograma solid (stroke 12px, ≤32px legibility)
  { source: 'monogram_s_solid.svg',  prefix: 'monogram_solid',    sizes: [16, 32, 64, 128, 256] },
  // Monograma light (stroke 3px, hero/large)
  { source: 'monogram_s_light.svg',  prefix: 'monogram_light',    sizes: [64, 128, 256, 512] },
  // Wordmark "SONAR" Syncopate Bold + stencil masks
  { source: 'wordmark_sonar.svg',    prefix: 'wordmark',          sizes: [256, 512, 1024, 2048] },
  // Lockup horizontal (header, signatures)
  { source: 'lockup_horizontal.svg', prefix: 'lockup_horizontal', sizes: [512, 1024, 2048] },
  // Lockup vertical (square contexts)
  { source: 'lockup_vertical.svg',   prefix: 'lockup_vertical',   sizes: [256, 512, 1024] },
]

// Favicon.ico multi-res composite
const FAVICON_SIZES  = [16, 32, 48]
const FAVICON_SOURCE = 'monogram_s_solid.svg'

// ───────────────────────── Puppeteer renderer ─────────────────────────

let browser

async function getBrowser() {
  if (!browser) {
    browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    })
  }
  return browser
}

/**
 * Parse viewBox from SVG content → aspect ratio (height/width).
 * Falls back to 1:1 if not found.
 */
function getAspectRatio(svgContent) {
  const m = svgContent.match(/viewBox=["']([\d.\-\s]+)["']/)
  if (!m) return 1
  const parts = m[1].trim().split(/[\s,]+/).map(Number)
  if (parts.length !== 4 || !parts[2] || !parts[3]) return 1
  return parts[3] / parts[2]
}

/**
 * Render an SVG file to PNG at the given width.
 * Height auto-computed from SVG viewBox aspect ratio (or square if `square` flag).
 */
async function renderPng(svgPath, outPath, width, square = false) {
  const svgContent = await readFile(svgPath, 'utf8')
  const aspect = square ? 1 : getAspectRatio(svgContent)
  const height = Math.round(width * aspect)

  const html = `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:100%;height:100%;background:transparent}
  body{display:flex;align-items:center;justify-content:center;overflow:hidden}
  svg{display:block;width:${width}px;height:${height}px}
</style>
</head>
<body>${svgContent}</body>
</html>`

  const br = await getBrowser()
  const page = await br.newPage()
  await page.setViewport({ width, height, deviceScaleFactor: 1 })
  await page.setContent(html, { waitUntil: 'networkidle0' })
  // Ensure web fonts loaded before screenshot
  await page.evaluate(() => document.fonts.ready)

  const buffer = await page.screenshot({
    type: 'png',
    omitBackground: true,
    clip: { x: 0, y: 0, width, height },
  })

  await writeFile(outPath, buffer)
  await page.close()
}

// ───────────────────────── Main ─────────────────────────

async function main() {
  console.log('SONAR logo export pipeline (Puppeteer)')
  console.log('========================================')
  console.log('Source dir:', LOGO_DIR)
  console.log('Output dir:', OUT_DIR)
  console.log('')

  if (!existsSync(OUT_DIR)) {
    await mkdir(OUT_DIR, { recursive: true })
    console.log(`[mkdir] ${OUT_DIR}`)
  }

  console.log('[boot] launching headless Chromium...')
  await getBrowser()
  console.log('[boot] ready')
  console.log('')

  let totalFiles = 0

  for (const exp of EXPORTS) {
    const svgPath = join(LOGO_DIR, exp.source)
    if (!existsSync(svgPath)) {
      console.log(`[skip] ${exp.source} not found`)
      continue
    }
    // Square for monograms (200×200 viewBox), aspect for wordmark/lockup
    const isSquare = exp.source.startsWith('monogram')
    for (const size of exp.sizes) {
      const outName = `${exp.prefix}_${size}.png`
      const outPath = join(OUT_DIR, outName)
      await renderPng(svgPath, outPath, size, isSquare)
      console.log(`[png]  ${outName}`)
      totalFiles++
    }
  }

  // Favicon.ico composite
  console.log('')
  console.log('Building favicon.ico...')
  const faviconSvgPath = join(LOGO_DIR, FAVICON_SOURCE)
  const tempPngs = []
  for (const size of FAVICON_SIZES) {
    const tmpPath = join(OUT_DIR, `_favicon_tmp_${size}.png`)
    await renderPng(faviconSvgPath, tmpPath, size, true)
    tempPngs.push(tmpPath)
  }
  const icoBuffer = await pngToIco(tempPngs)
  await writeFile(join(OUT_DIR, 'favicon.ico'), icoBuffer)
  console.log('[ico]  favicon.ico')
  totalFiles++

  for (const tmp of tempPngs) await unlink(tmp)

  await browser.close()

  console.log('')
  console.log(`Done. ${totalFiles} files exported to: ${OUT_DIR}`)
}

main().catch(async (err) => {
  console.error('Export failed:', err)
  if (browser) await browser.close()
  process.exit(1)
})
