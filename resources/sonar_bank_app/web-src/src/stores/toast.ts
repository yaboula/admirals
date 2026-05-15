import { create } from 'zustand'
import { generateUuidV4 } from '@/lib/utils'

export type ToastTone = 'success' | 'warning' | 'danger' | 'info'

export interface ToastAction {
  label: string
  onClick: () => void
}

export interface Toast {
  id: string
  tone: ToastTone
  title: string
  description?: string
  duration?: number
  action?: ToastAction
}

export interface ToastQueueState {
  toasts: Toast[]
  push: (toast: Omit<Toast, 'id'>) => string
  dismiss: (id: string) => void
  clear: () => void
}

export const useToastQueue = create<ToastQueueState>((set) => ({
  toasts: [],
  push: (toast) => {
    const id = generateUuidV4()
    set((s) => ({ toasts: [...s.toasts, { ...toast, id, duration: toast.duration ?? 1500 }] }))
    return id
  },
  dismiss: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
  clear: () => set({ toasts: [] }),
}))

export const toast = {
  success: (title: string, description?: string, action?: ToastAction): string =>
    useToastQueue.getState().push({ tone: 'success', title, description, action }),
  warning: (title: string, description?: string, action?: ToastAction): string =>
    useToastQueue.getState().push({ tone: 'warning', title, description, action }),
  danger: (title: string, description?: string, action?: ToastAction): string =>
    useToastQueue.getState().push({ tone: 'danger', title, description, action }),
  info: (title: string, description?: string, action?: ToastAction): string =>
    useToastQueue.getState().push({ tone: 'info', title, description, action }),
}
