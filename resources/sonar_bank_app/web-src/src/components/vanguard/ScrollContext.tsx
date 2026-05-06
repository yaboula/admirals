import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from 'react'

interface ScrollContextValue {
  scrollY: number
  progress: number
  containerRef: React.RefObject<HTMLDivElement | null>
}

const ScrollContext = createContext<ScrollContextValue | null>(null)

export interface ScrollProviderProps {
  children: ReactNode
  /** Pixels of scroll required to reach progress=1 (default 200) */
  saturationPx?: number
  className?: string
}

export function ScrollProvider({ children, saturationPx = 200, className }: ScrollProviderProps) {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const [scrollY, setScrollY] = useState(0)
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    const el = containerRef.current
    if (!el) return
    let raf: number | null = null
    const onScroll = (): void => {
      if (raf !== null) return
      raf = requestAnimationFrame(() => {
        const y = el.scrollTop
        setScrollY(y)
        setProgress(Math.min(1, Math.max(0, y / saturationPx)))
        raf = null
      })
    }
    el.addEventListener('scroll', onScroll, { passive: true })
    return () => {
      el.removeEventListener('scroll', onScroll)
      if (raf !== null) cancelAnimationFrame(raf)
    }
  }, [saturationPx])

  return (
    <ScrollContext.Provider value={{ scrollY, progress, containerRef }}>
      <div ref={containerRef} className={className}>
        {children}
      </div>
    </ScrollContext.Provider>
  )
}

export function useScrollContext(): ScrollContextValue {
  const ctx = useContext(ScrollContext)
  if (!ctx) {
    throw new Error('useScrollContext must be used inside <ScrollProvider>')
  }
  return ctx
}

export function useScrollProgress(): number {
  return useScrollContext().progress
}
