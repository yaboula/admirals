import { type HTMLAttributes, type ReactNode } from 'react'
import { cn } from '@/lib/utils'

export interface ConicEdgeProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
  enabled?: boolean
}

export function ConicEdge({ children, enabled = true, className, ...rest }: ConicEdgeProps) {
  return (
    <div className={cn(enabled && 'tactile-conic-edge', className)} {...rest}>
      {children}
    </div>
  )
}
