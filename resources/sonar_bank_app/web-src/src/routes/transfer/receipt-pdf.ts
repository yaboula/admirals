import type { TransferReceipt } from '@/data/mutations'
import { maskMoneyDisplay, maskOperationCode, revealOperationCode } from '@/lib/privacy'

export interface TransferReceiptPdfInput {
  receipt: TransferReceipt
  recipientLabel: string
  amountLabel: string
  availableBalanceLabel: string
  fromIbanMasked: string
  toIbanMasked: string
  timestampLabel: string
  streamerMode: boolean
  labels: TransferReceiptPdfLabels
}

export interface TransferReceiptPdfLabels {
  receiptTitle: string
  sentAmount: string
  receiptNumber: string
  securityCode: string
  from: string
  to: string
  memo: string
  hiddenMemo: string
  noMemo: string
  date: string
  availableBalance: string
  bankReference: string
  receiptWatermark: string
  footerLine1: string
  footerLine2: string
  committedStatus: string
  pendingStatus: string
  revertedStatus: string
  failedStatus: string
}

interface CanvasTextOptions {
  size?: number
  weight?: 400 | 600 | 700 | 800
  color?: string
  align?: CanvasTextAlign
  maxWidth?: number
}

interface ReceiptJpeg {
  bytes: Uint8Array
  width: number
  height: number
}

const PAGE_WIDTH = 595.28
const PAGE_HEIGHT = 841.89
const CANVAS_SCALE = 2
const MARGIN_X = 54
const FONT_FAMILY = '"Inter Variable", Inter, "Segoe UI", Arial, sans-serif'
const COLORS = {
  background: '#0d0e12',
  shell: '#13151b',
  panel: '#1d1f26',
  ink: '#f3f3f7',
  muted: '#8f95a3',
  faint: 'rgba(255, 255, 255, 0.10)',
  border: 'rgba(255, 255, 255, 0.16)',
  brand: '#ef7338',
  success: '#7be0a7',
  watermark: 'rgba(255, 255, 255, 0.035)',
}

export async function downloadTransferReceiptPdf(input: TransferReceiptPdfInput): Promise<void> {
  const image = await createReceiptJpeg(input)
  const pdf = buildPdfDocument(image)
  const blob = new Blob([pdf], { type: 'application/pdf' })
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = buildReceiptFileName(input.receipt)
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  window.setTimeout(() => URL.revokeObjectURL(url), 1000)
}

async function createReceiptJpeg(input: TransferReceiptPdfInput): Promise<ReceiptJpeg> {
  await registerReceiptFont()

  const canvas = document.createElement('canvas')
  canvas.width = Math.round(PAGE_WIDTH * CANVAS_SCALE)
  canvas.height = Math.round(PAGE_HEIGHT * CANVAS_SCALE)

  const ctx = canvas.getContext('2d')
  if (!ctx) throw new Error('PDF_CANVAS_UNAVAILABLE')

  ctx.scale(CANVAS_SCALE, CANVAS_SCALE)
  drawReceiptCanvas(ctx, input)

  const blob = await canvasToBlob(canvas)
  return {
    bytes: new Uint8Array(await blob.arrayBuffer()),
    width: canvas.width,
    height: canvas.height,
  }
}

async function registerReceiptFont(): Promise<void> {
  if (!('fonts' in document)) return
  await Promise.all([
    document.fonts.load(`400 12px ${FONT_FAMILY}`),
    document.fonts.load(`700 38px ${FONT_FAMILY}`),
  ])
}

function drawReceiptCanvas(ctx: CanvasRenderingContext2D, input: TransferReceiptPdfInput): void {
  drawBackground(ctx)
  drawHeader(ctx, input)
  drawAmount(ctx, input)
  drawReceiptPanel(ctx, input)
  drawWatermark(ctx, input)
  drawFooter(ctx, input)
}

function drawBackground(ctx: CanvasRenderingContext2D): void {
  fillRect(ctx, 0, 0, PAGE_WIDTH, PAGE_HEIGHT, COLORS.background)
  fillRect(ctx, 32, 32, PAGE_WIDTH - 64, PAGE_HEIGHT - 64, COLORS.shell)
  line(ctx, 32, 98, PAGE_WIDTH - 32, 98, COLORS.border)
  line(ctx, 32, PAGE_HEIGHT - 116, PAGE_WIDTH - 32, PAGE_HEIGHT - 116, COLORS.border)
}

function drawHeader(ctx: CanvasRenderingContext2D, input: TransferReceiptPdfInput): void {
  text(ctx, 'SONAR', MARGIN_X, 70, { size: 24, weight: 800, color: COLORS.ink })
  text(ctx, 'BANK', MARGIN_X + 84, 70, { size: 24, weight: 800, color: COLORS.brand })
  text(ctx, input.labels.receiptTitle, MARGIN_X, 92, { size: 10, color: COLORS.muted })
  text(ctx, formatReceiptStatus(input.receipt.status, input.labels), PAGE_WIDTH - MARGIN_X, 70, {
    size: 10,
    weight: 800,
    color: COLORS.success,
    align: 'right',
  })
  text(ctx, input.timestampLabel, PAGE_WIDTH - MARGIN_X, 92, {
    size: 9,
    color: COLORS.muted,
    align: 'right',
  })
}

function drawAmount(ctx: CanvasRenderingContext2D, input: TransferReceiptPdfInput): void {
  text(ctx, input.labels.sentAmount, MARGIN_X, 154, { size: 11, color: COLORS.muted })
  text(ctx, input.amountLabel, MARGIN_X, 195, { size: 38, weight: 800, color: COLORS.ink, maxWidth: 360 })
  text(ctx, `${input.labels.to}: ${input.recipientLabel}`, MARGIN_X, 220, { size: 12, color: COLORS.muted, maxWidth: 420 })
}

function drawReceiptPanel(ctx: CanvasRenderingContext2D, input: TransferReceiptPdfInput): void {
  const x = MARGIN_X
  const y = 280
  const w = PAGE_WIDTH - MARGIN_X * 2
  const h = 300
  fillRect(ctx, x, y, w, h, COLORS.panel)
  line(ctx, x, y, x + w, y, COLORS.brand, 1.4)

  const rows: Array<[string, string]> = [
    [input.labels.receiptNumber, input.streamerMode ? maskOperationCode(input.receipt.transaction_id) : revealOperationCode(input.receipt.transaction_id)],
    [input.labels.securityCode, input.streamerMode ? maskOperationCode(input.receipt.correlation_id) : revealOperationCode(input.receipt.correlation_id)],
    [input.labels.from, input.fromIbanMasked],
    [input.labels.to, input.toIbanMasked],
    [input.labels.memo, input.streamerMode ? input.labels.hiddenMemo : input.receipt.reason?.trim() || input.labels.noMemo],
    [input.labels.date, input.timestampLabel],
    [input.labels.availableBalance, input.streamerMode ? maskMoneyDisplay() : input.availableBalanceLabel],
    [input.labels.bankReference, input.streamerMode ? maskOperationCode(input.receipt.idempotency_key) : revealOperationCode(input.receipt.idempotency_key)],
  ]

  let rowY = y + 58
  for (const [label, value] of rows) {
    text(ctx, label, x + 24, rowY, { size: 8, color: COLORS.muted })
    text(ctx, value, x + 150, rowY, { size: 9, weight: 700, color: COLORS.ink, maxWidth: w - 174 })
    line(ctx, x + 24, rowY + 18, x + w - 24, rowY + 18, COLORS.faint)
    rowY += 32
  }
}

function drawWatermark(ctx: CanvasRenderingContext2D, input: TransferReceiptPdfInput): void {
  text(ctx, 'SONAR BANK', 188, 450, { size: 34, weight: 800, color: COLORS.watermark })
  text(ctx, input.labels.receiptWatermark, 230, 484, { size: 18, weight: 800, color: COLORS.watermark })
}

function drawFooter(ctx: CanvasRenderingContext2D, input: TransferReceiptPdfInput): void {
  text(ctx, input.labels.footerLine1, MARGIN_X, 764, {
    size: 8,
    color: COLORS.muted,
    maxWidth: PAGE_WIDTH - MARGIN_X * 2,
  })
  text(ctx, input.labels.footerLine2, MARGIN_X, 780, {
    size: 8,
    color: COLORS.muted,
    maxWidth: PAGE_WIDTH - MARGIN_X * 2,
  })
}

function fillRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number, color: string): void {
  ctx.fillStyle = color
  ctx.fillRect(x, y, width, height)
}

function line(ctx: CanvasRenderingContext2D, x1: number, y1: number, x2: number, y2: number, color: string, width = 0.7): void {
  ctx.strokeStyle = color
  ctx.lineWidth = width
  ctx.beginPath()
  ctx.moveTo(x1, y1)
  ctx.lineTo(x2, y2)
  ctx.stroke()
}

function text(ctx: CanvasRenderingContext2D, value: string, x: number, y: number, options: CanvasTextOptions = {}): void {
  const size = options.size ?? 10
  const weight = options.weight ?? 400
  ctx.fillStyle = options.color ?? COLORS.ink
  ctx.font = `${weight} ${size}px ${FONT_FAMILY}`
  ctx.textAlign = options.align ?? 'left'
  ctx.textBaseline = 'alphabetic'
  if (options.maxWidth) {
    ctx.fillText(value, x, y, options.maxWidth)
    return
  }
  ctx.fillText(value, x, y)
}

function canvasToBlob(canvas: HTMLCanvasElement): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (blob) {
        resolve(blob)
        return
      }
      reject(new Error('PDF_CANVAS_BLOB_FAILED'))
    }, 'image/jpeg', 0.94)
  })
}

function buildPdfDocument(image: ReceiptJpeg): Uint8Array {
  const content = `q\n${fixed(PAGE_WIDTH)} 0 0 ${fixed(PAGE_HEIGHT)} 0 0 cm\n/Im1 Do\nQ`
  const chunks: Uint8Array[] = []
  const offsets: number[] = []
  let length = 0

  const append = (value: string | Uint8Array): void => {
    const chunk = typeof value === 'string' ? encode(value) : value
    chunks.push(chunk)
    length += chunk.length
  }

  const addObject = (id: number, value: string): void => {
    offsets[id] = length
    append(`${id} 0 obj\n${value}\nendobj\n`)
  }

  const addStreamObject = (id: number, dictionary: string, stream: Uint8Array): void => {
    offsets[id] = length
    append(`${id} 0 obj\n${dictionary}\nstream\n`)
    append(stream)
    append('\nendstream\nendobj\n')
  }

  append('%PDF-1.4\n%SONAR\n')
  addObject(1, '<< /Type /Catalog /Pages 2 0 R >>')
  addObject(2, '<< /Type /Pages /Kids [3 0 R] /Count 1 >>')
  addObject(3, `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${fixed(PAGE_WIDTH)} ${fixed(PAGE_HEIGHT)}] /Resources << /XObject << /Im1 4 0 R >> >> /Contents 5 0 R >>`)
  addStreamObject(4, `<< /Type /XObject /Subtype /Image /Width ${image.width} /Height ${image.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${image.bytes.length} >>`, image.bytes)
  addStreamObject(5, `<< /Length ${byteLength(content)} >>`, encode(content))

  const xrefOffset = length
  append('xref\n0 6\n')
  append('0000000000 65535 f \n')
  for (let id = 1; id <= 5; id += 1) {
    append(`${String(offsets[id]).padStart(10, '0')} 00000 n \n`)
  }
  append(`trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`)

  return concat(chunks, length)
}

function buildReceiptFileName(receipt: TransferReceipt): string {
  return `sonar-bank-receipt-${maskOperationCode(receipt.transaction_id).replace(/[^a-z0-9]/gi, '-')}.pdf`
}

function formatReceiptStatus(status: string, labels: TransferReceiptPdfLabels): string {
  switch (status.toLowerCase()) {
    case 'committed':
      return labels.committedStatus
    case 'pending':
      return labels.pendingStatus
    case 'reverted':
      return labels.revertedStatus
    case 'failed':
      return labels.failedStatus
    default:
      return status.toUpperCase()
  }
}

function fixed(value: number): string {
  return Number.isInteger(value) ? String(value) : value.toFixed(2)
}

function byteLength(value: string): number {
  return encode(value).length
}

function encode(value: string): Uint8Array {
  return new TextEncoder().encode(value)
}

function concat(chunks: Uint8Array[], length: number): Uint8Array {
  const out = new Uint8Array(length)
  let offset = 0
  for (const chunk of chunks) {
    out.set(chunk, offset)
    offset += chunk.length
  }
  return out
}
