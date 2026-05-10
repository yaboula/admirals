import { Component, type ErrorInfo, type ReactNode } from 'react'

interface RootErrorBoundaryProps {
  children: ReactNode
}

interface RootErrorBoundaryState {
  hasError: boolean
  error: Error | null
  componentStack: string | null
}

/**
 * GLOBAL last-resort error boundary mounted ABOVE the RouterProvider in main.tsx.
 *
 * Why this exists:
 *   - The internal AppErrorBoundary in App.tsx only protects <Outlet />.
 *   - Errors thrown in App itself, NuiControlBridge, NetEventBridge,
 *     BankDeviceFrame, RouterProvider, lazy chunk loaders, or any hook
 *     mounted outside the route tree (useBankNetEvent, useI18n, useBankStatus,
 *     useInvalidateBootstrap, etc.) bubble PAST AppErrorBoundary because that
 *     boundary is a SIBLING, not an ancestor of those components.
 *   - When such an error reaches the React root unhandled, React unmounts the
 *     entire tree. The user sees a TOTAL BLACK SCREEN inside the FiveM NUI
 *     because nothing is rendered anymore — index.html body is transparent.
 *
 * This boundary catches ALL such errors and renders a self-contained fallback
 * with INLINE styles only (no Tailwind / no CSS variables / no font assets)
 * so it works even if the entire stylesheet fails to load.
 */
export class RootErrorBoundary extends Component<RootErrorBoundaryProps, RootErrorBoundaryState> {
  state: RootErrorBoundaryState = {
    hasError: false,
    error: null,
    componentStack: null,
  }

  static getDerivedStateFromError(error: Error): Partial<RootErrorBoundaryState> {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('[SONAR Bank] ROOT crash captured by RootErrorBoundary', {
      message: error?.message,
      stack: error?.stack,
      componentStack: errorInfo?.componentStack,
    })
    this.setState({ componentStack: errorInfo?.componentStack ?? null })
  }

  handleReload = (): void => {
    try {
      window.location.reload()
    } catch {
      /* no-op */
    }
  }

  render(): ReactNode {
    if (!this.state.hasError) return this.props.children

    const errorMessage = this.state.error?.message ?? 'Unknown error'
    const errorName = this.state.error?.name ?? 'Error'
    const stackPreview = (this.state.error?.stack ?? '').split('\n').slice(0, 4).join('\n')

    return (
      <div
        role="alert"
        aria-live="assertive"
        style={{
          position: 'fixed',
          inset: 0,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '24px',
          background: 'rgba(0, 0, 0, 0.78)',
          fontFamily: 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif',
          color: '#f5f5f5',
          zIndex: 2147483647,
        }}
      >
        <div
          style={{
            width: '100%',
            maxWidth: '560px',
            padding: '28px 30px',
            borderRadius: '20px',
            background: '#120c08',
            border: '1.5px solid rgba(255, 100, 19, 0.55)',
            boxShadow: '0 24px 80px -32px rgba(0, 0, 0, 0.95), 0 0 60px -20px rgba(255, 100, 19, 0.25)',
            textAlign: 'left',
          }}
        >
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: '44px',
              height: '44px',
              borderRadius: '14px',
              background: 'rgba(255, 100, 19, 0.14)',
              border: '1px solid rgba(255, 100, 19, 0.4)',
              marginBottom: '14px',
              fontSize: '24px',
              lineHeight: 1,
            }}
            aria-hidden="true"
          >
            ⚠
          </div>
          <h1
            style={{
              margin: 0,
              fontSize: '17px',
              fontWeight: 600,
              letterSpacing: '0.01em',
              color: '#ffffff',
            }}
          >
            SONAR Bank — Critical render fault
          </h1>
          <p
            style={{
              margin: '8px 0 0',
              fontSize: '13px',
              lineHeight: 1.55,
              color: 'rgba(245, 245, 245, 0.72)',
            }}
          >
            The interface caught a fatal error before mounting. The frame was
            preserved instead of leaving you on a black screen. Reload the
            resource or close and reopen the app to retry.
          </p>
          <pre
            style={{
              margin: '14px 0 0',
              padding: '12px 14px',
              borderRadius: '12px',
              background: 'rgba(0, 0, 0, 0.55)',
              border: '1px solid rgba(255, 255, 255, 0.06)',
              fontSize: '11px',
              lineHeight: 1.5,
              color: '#ffb38a',
              fontFamily: 'ui-monospace, "JetBrains Mono", "Cascadia Code", monospace',
              whiteSpace: 'pre-wrap',
              wordBreak: 'break-word',
              overflowX: 'auto',
              maxHeight: '180px',
            }}
          >
            {`${errorName}: ${errorMessage}\n${stackPreview}`}
          </pre>
          <div style={{ marginTop: '16px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
            <button
              type="button"
              onClick={this.handleReload}
              style={{
                appearance: 'none',
                border: '1px solid rgba(255, 100, 19, 0.6)',
                background: 'linear-gradient(180deg, rgba(255, 100, 19, 0.95), rgba(220, 78, 8, 0.95))',
                color: '#ffffff',
                padding: '9px 16px',
                borderRadius: '12px',
                fontSize: '12.5px',
                fontWeight: 600,
                cursor: 'pointer',
                letterSpacing: '0.02em',
              }}
            >
              Reload UI
            </button>
            <span
              style={{
                fontSize: '11px',
                color: 'rgba(245, 245, 245, 0.45)',
                alignSelf: 'center',
              }}
            >
              See devtools console for full stack trace.
            </span>
          </div>
        </div>
      </div>
    )
  }
}
