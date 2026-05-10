export type SemanticColorTone = 'success' | 'warning' | 'danger' | 'info' | 'neutral' | 'brand'

interface SemanticColorVars {
  color: string
  background: string
  border: string
}

const SEMANTIC_COLOR_VARS: Record<SemanticColorTone, SemanticColorVars> = {
  success: {
    color: 'var(--color-semantic-success-deep)',
    background: 'var(--color-semantic-success-glow)',
    border: 'var(--color-semantic-success-deep)',
  },
  warning: {
    color: 'var(--color-semantic-warning-deep)',
    background: 'var(--color-semantic-warning-glow)',
    border: 'var(--color-semantic-warning-deep)',
  },
  danger: {
    color: 'var(--color-semantic-danger-deep)',
    background: 'var(--color-semantic-danger-glow)',
    border: 'var(--color-semantic-danger-deep)',
  },
  info: {
    color: 'var(--color-semantic-info-deep)',
    background: 'var(--color-semantic-info-glow)',
    border: 'var(--color-semantic-info-deep)',
  },
  neutral: {
    color: 'var(--color-text-tertiary)',
    background: 'rgba(255, 255, 255, 0.08)',
    border: 'var(--color-border-medium)',
  },
  brand: {
    color: 'var(--color-brand-signal-orange)',
    background: 'var(--color-brand-signal-orange-subtle)',
    border: 'var(--color-border-brand-strong)',
  },
}

export function semanticColorVars(tone: SemanticColorTone): SemanticColorVars {
  return SEMANTIC_COLOR_VARS[tone]
}
