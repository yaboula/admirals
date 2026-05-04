/**
 * SONAR Tablet — useTabletVisibility hook.
 *
 * Composición sobre `useNUIBridge` (primitive) + `fetchNUI` (NUI→Lua).
 * Single source of truth del estado visible/hidden del shell.
 *
 * - `visible` sincronizado con `sonar:tablet:toggle` Lua message.
 * - `requestClose()` hace round-trip NUI→Lua (`sonar:tablet:close` callback)
 *   que Lua-side re-emite `sonar:tablet:toggle { visible: false }` pero
 *   optimista-cierra ya React-side para UX responsivo (<16ms perceived).
 */
import { useCallback, useState } from 'react'
import { useNUIBridge } from '@/hooks/useNUIBridge'
import { fetchNUI, isInFiveM } from '@/lib/nui'
import type { NUITabletToggleMessage } from '@/types/nui'

export interface UseTabletVisibility {
  /** Estado visible (true = shell montado + keybind focus). */
  visible: boolean
  /** Cierra Tablet (optimistic UI + round-trip Lua via fetchNUI). */
  requestClose: () => Promise<void>
}

export function useTabletVisibility(): UseTabletVisibility {
  const [visible, setVisible] = useState<boolean>(false)

  useNUIBridge<NUITabletToggleMessage>((msg) => {
    if (msg.action === 'sonar:tablet:toggle') {
      setVisible(msg.visible)
    }
  })

  const requestClose = useCallback(async () => {
    setVisible(false)
    if (!isInFiveM) return
    try {
      await fetchNUI('sonar:tablet:close')
    } catch {
      // Silent: optimistic close ya aplicado; Lua recuperará state al próximo toggle.
    }
  }, [])

  return { visible, requestClose }
}
