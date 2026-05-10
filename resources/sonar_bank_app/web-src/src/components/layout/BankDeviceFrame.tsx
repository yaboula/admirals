import { useEffect, type ReactNode } from 'react'
import { isInsideFiveMNui } from '@/lib/env'

interface BankDeviceFrameProps {
  children: ReactNode
}

export function BankDeviceFrame({ children }: BankDeviceFrameProps) {
  useEffect(() => {
    if (!isInsideFiveMNui()) return
    const prev = document.body.style.background
    document.body.style.background = 'transparent'
    return () => {
      document.body.style.background = prev
    }
  }, [])

  if (!isInsideFiveMNui()) return children

  return (
    <div className="bank-device-viewport">
      <div className="bank-device-frame">{children}</div>
    </div>
  )
}
