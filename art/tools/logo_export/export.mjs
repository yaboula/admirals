// -----------------------------------------------------------------------------
// SONAR Logo — SVG → PNG raster export pipeline
// -----------------------------------------------------------------------------
// Generates PNG exports + favicon.ico from logo_v2 SVG sources.
// Per brief 01_brief_logo.md v2 §2.1 deliverables.
//
// Usage (from this dir):
//   npm install
//   npm run build
// -----------------------------------------------------------------------------

import sharp from 'sharp'
import pngToIco from 'png-to-ico'
import { readFile, writeFile, mkdir } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { resolve, dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const LOGO_DIR = resolve(__dirname, '..', '..', 'branding', 'logo_v2')
const OUT_DIR  = resolve(LOGO_DIR, 'exports')

// Export matrix: [source svg, output prefix, sizes]
const EXPORTS = [
  {
    source: 'monogram_s.svg',
    prefix: 'monogram',
    sizes: [16, 32, 64, 128, 256, 512, 1024]
  },
  {
    source: 'monogram_s_solid.svg',
    prefix: 'monogram_solid',
    sizes: [16, 32, 64, 128, 256]
  },
  {
    source: 'monogram_s_light.svg',
    prefix: 'monogram_light',
    sizes: [64, 128, 256, 512]
  },
  {
    source: 'wordmark_sonar.svg',
    prefix: 'wordmark',
    sizes: [256, 512, 1024, 2048]   // wider, higher-res for marketing
  },
  {
    source: 'lockup_horizontal.svg',
    prefix: 'lockup_horizontal',
    sizes: [512, 1024, 2048]
  },
  {
    source: 'lockup_vertical.svg',
    prefix: 'lockup_vertical',
    sizes: [256, 512, 1024]
  }
]

// Favicon.ico multi-res composite
const FAVICON_SIZES = [16, 32, 48]
const FAVICON_SOURCE = 'monogram_s_solid.svg'    // solid = more legible ≤32px

async function renderPng(svgPath, outPath, size) {
  const svgBuffer = await readFile(svgPath)
  await sharp(svgBuffer, { density: 384 })   // high density for crisp raster
    .resize(size, size, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(outPath)
}

async function renderPngWidth(svgPath, outPath, width) {
  const svgBuffer = await readFile(svgPath)
  await sharp(svgBuffer, { density: 384 })
    .resize({ width, fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(outPath)
}

async function main() {
  console.log('SONAR logo export pipeline')
  console.log('============================')
  console.log('Source dir:', LOGO_DIR)
  console.log('Output dir:', OUT_DIR)
  console.log('')

  if (!existsSync(OUT_DIR)) {
    await mkdir(OUT_DIR, { recursive: true })
    console.log(`[mkdir] ${OUT_DIR}`)
  }

  let totalFiles = 0

  for (const exp of EXPORTS) {
    const svgPath = join(LOGO_DIR, exp.source)
    if (!existsSync(svgPath)) {
      console.log(`[skip] ${exp.source} not found`)
      continue
    }
    for (const size of exp.sizes) {
      const outName = `${exp.prefix}_${size}.png`
      const outPath = join(OUT_DIR, outName)
      // For non-square (wordmark, lockup), use width-based
      const isSquare = exp.source.startsWith('monogram')
      if (isSquare) {
        await renderPng(svgPath, outPath, size)
      } else {
        await renderPngWidth(svgPath, outPath, size)
      }
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
    await renderPng(faviconSvgPath, tmpPath, size)
    tempPngs.push(tmpPath)
  }
  const icoBuffer = await pngToIco(tempPngs)
  await writeFile(join(OUT_DIR, 'favicon.ico'), icoBuffer)
  console.log('[ico]  favicon.ico')
  totalFiles++

  // Clean favicon temp files
  const { unlink } = await import('node:fs/promises')
  for (const tmp of tempPngs) {
    await unlink(tmp)
  }

  console.log('')
  console.log(`Done. ${totalFiles} files exported to: ${OUT_DIR}`)
}

main().catch((err) => {
  console.error('Export failed:', err)
  process.exit(1)
})
