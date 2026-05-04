/**
 * SONAR Tablet — TabletRouter (S2.3).
 *
 * Router state machine home ↔ app vía React Context + useReducer.
 * Stack FROZEN per ADR-016 D5 / SPRINT_PLAN_S2 §4: NO Zustand / Redux / Jotai.
 *
 * Surface API:
 *   - <TabletRouterProvider>: mount en App.tsx dentro de <TabletFrame>.
 *   - useTabletRouter(): thin hook (ver hooks/useTabletRouter.ts) que throw si
 *     se consume fuera del provider.
 *
 * State:
 *   - view: 'home' | 'bank' | 'map'
 *
 * Actions:
 *   - OPEN_APP(view)    — navigate home → app stub
 *   - BACK_TO_HOME      — navigate app → home (triggered por "← Volver" btn o ESC)
 *
 * Scope S2.3: solo 3 rutas (home + bank stub + map stub). Apps reales llegan
 * S2.4 (Bank) + S2.5 (Map). Añadir nuevas routes = extender AppView + reducer
 * + appCatalog entry con `route` definido.
 */
import { createContext, useMemo, useReducer } from 'react'
import type { Dispatch, ReactNode } from 'react'

export type AppView = 'home' | 'bank' | 'map'

export type TabletRouterState = {
  view: AppView
}

export type TabletRouterAction =
  | { type: 'OPEN_APP'; view: Exclude<AppView, 'home'> }
  | { type: 'BACK_TO_HOME' }

export interface TabletRouterContextValue {
  state: TabletRouterState
  dispatch: Dispatch<TabletRouterAction>
}

const INITIAL_STATE: TabletRouterState = { view: 'home' }

function reducer(
  state: TabletRouterState,
  action: TabletRouterAction,
): TabletRouterState {
  switch (action.type) {
    case 'OPEN_APP':
      if (state.view === action.view) return state
      return { view: action.view }
    case 'BACK_TO_HOME':
      if (state.view === 'home') return state
      return { view: 'home' }
    default:
      return state
  }
}

export const TabletRouterContext = createContext<TabletRouterContextValue | null>(
  null,
)

export interface TabletRouterProviderProps {
  children: ReactNode
}

export function TabletRouterProvider({ children }: TabletRouterProviderProps) {
  const [state, dispatch] = useReducer(reducer, INITIAL_STATE)
  const value = useMemo<TabletRouterContextValue>(
    () => ({ state, dispatch }),
    [state],
  )
  return (
    <TabletRouterContext.Provider value={value}>
      {children}
    </TabletRouterContext.Provider>
  )
}
