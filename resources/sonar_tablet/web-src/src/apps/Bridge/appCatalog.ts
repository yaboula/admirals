/**
 * SONAR Tablet — Bridge home app catalog (S2.3).
 *
 * 9 apps base per `docs/design/02_sonar_tablet.md` §5.1 + 3 placeholders
 * reservados futuras waves. DEPRECATED emoji refs: usamos Lucide React bridge
 * per NOTICE art/01_art_direction.md v3.0-locked + ADR-016 D3.
 *
 * Status legend:
 *   - 'shipped'           ready (S2.3 home only + nav stubs).
 *   - 'stub-S2.4'         stub con copy "Coming S2.4" (Bank app real S2.4).
 *   - 'stub-S2.5'         stub con copy "Coming S2.5" (Map app real S2.5).
 *   - 'placeholder-future' disabled tile, 3 slots reservados S3+.
 */
import type { ComponentType } from 'react'
import {
  Building2,
  LayoutDashboard,
  Landmark,
  MessageSquare,
  Plus,
  ScrollText,
  Settings,
  ShoppingBag,
  Tag,
  Truck,
} from 'lucide-react'
import type { LucideProps } from 'lucide-react'
import type { AppView } from '@/context/TabletRouter'

export type AppRoute = Extract<AppView, 'bank' | 'map'> | 'home' | null

export type AppStatus =
  | 'shipped'
  | 'stub-S2.4'
  | 'stub-S2.5'
  | 'placeholder-future'

export interface AppTileDef {
  id: string
  label: string
  lucideIcon: ComponentType<LucideProps>
  route: AppRoute
  status: AppStatus
}

export const APP_CATALOG: readonly AppTileDef[] = [
  {
    id: 'empresa',
    label: 'Empresa',
    lucideIcon: Building2,
    route: null,
    status: 'placeholder-future',
  },
  {
    id: 'manager',
    label: 'Manager Panel',
    lucideIcon: LayoutDashboard,
    route: null,
    status: 'placeholder-future',
  },
  {
    id: 'mercado',
    label: 'Mercado',
    lucideIcon: Tag,
    route: null,
    status: 'placeholder-future',
  },
  {
    id: 'logistica',
    label: 'Logística',
    lucideIcon: Truck,
    route: 'map',
    status: 'stub-S2.5',
  },
  {
    id: 'mensajes',
    label: 'Mensajes',
    lucideIcon: MessageSquare,
    route: null,
    status: 'placeholder-future',
  },
  {
    id: 'banca',
    label: 'Banca',
    lucideIcon: Landmark,
    route: 'bank',
    status: 'shipped',
  },
  {
    id: 'notas',
    label: 'Notas & Contratos',
    lucideIcon: ScrollText,
    route: null,
    status: 'placeholder-future',
  },
  {
    id: 'tienda',
    label: 'Tienda SONAR',
    lucideIcon: ShoppingBag,
    route: null,
    status: 'placeholder-future',
  },
  {
    id: 'settings',
    label: 'Settings',
    lucideIcon: Settings,
    route: null,
    status: 'placeholder-future',
  },
  // 3 placeholders future (S3+) — disabled tiles para completar grid 4×3.
  {
    id: 'placeholder-1',
    label: '—',
    lucideIcon: Plus,
    route: null,
    status: 'placeholder-future',
  },
  {
    id: 'placeholder-2',
    label: '—',
    lucideIcon: Plus,
    route: null,
    status: 'placeholder-future',
  },
  {
    id: 'placeholder-3',
    label: '—',
    lucideIcon: Plus,
    route: null,
    status: 'placeholder-future',
  },
]
