import { memo } from 'react'

export const AuroraBackground = memo(function AuroraBackground() {
  return (
    <div className="tactile-aurora-root" aria-hidden="true">
      <div className="tactile-aurora-blob --orange" />
      <div className="tactile-aurora-blob --magenta" />
      <div className="tactile-aurora-blob --cyan" />
      <div className="tactile-aurora-grain" />
    </div>
  )
})
