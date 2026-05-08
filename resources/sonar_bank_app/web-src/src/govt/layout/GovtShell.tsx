import { useEffect } from 'react'
import { Outlet } from 'react-router-dom'
import { GovtSidebar } from './GovtSidebar'
import { GovtTopbar } from './GovtTopbar'

/**
 * GovtShell — isolated layout shell for the SONAR Treasury Bureau panel.
 *
 * Mounts the Civic Navy theme via [data-theme="govt"] on documentElement
 * so the body background and global selection styles inherit the
 * government palette. Cleans up on unmount so the consumer Bank reverts
 * to the Signal Orange / Pure Black palette.
 */
export function GovtShell() {
  useEffect(() => {
    const root = document.documentElement
    const previous = root.dataset.theme
    root.dataset.theme = 'govt'
    return () => {
      if (previous === undefined) {
        delete root.dataset.theme
      } else {
        root.dataset.theme = previous
      }
    }
  }, [])

  return (
    <div className="relative flex h-full w-full" data-theme="govt">
      <GovtSidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <GovtTopbar />
        <main className="min-h-0 flex-1 overflow-hidden px-4 pb-4">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
