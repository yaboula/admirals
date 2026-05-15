import { AnimatePresence, motion, useReducedMotion } from 'motion/react'
import { CheckCircle2, AlertTriangle, AlertOctagon, Info, Trash2, Check, X } from 'lucide-react'
import { useNotifications, type NotificationType } from '@/stores/notifications'
import { Button } from '@/components/ui'
import { cn } from '@/lib/utils'
import { useI18n } from '@/lib/i18n'

const TYPE_META: Record<
  NotificationType,
  { icon: typeof CheckCircle2; bg: string; border: string; iconColor: string }
> = {
  info: {
    icon: Info,
    bg: '#0a151f',
    border: 'rgb(0, 173, 228)',
    iconColor: 'rgb(0, 173, 228)',
  },
  success: {
    icon: CheckCircle2,
    bg: '#0a1f12',
    border: 'rgb(0, 173, 91)',
    iconColor: 'rgb(0, 173, 91)',
  },
  warning: {
    icon: AlertTriangle,
    bg: '#1a1508',
    border: 'rgb(230, 173, 0)',
    iconColor: 'rgb(230, 173, 0)',
  },
  danger: {
    icon: AlertOctagon,
    bg: '#1a0a0a',
    border: 'rgb(234, 60, 63)',
    iconColor: 'rgb(234, 60, 63)',
  },
}

export interface NotificationDrawerProps {
  open: boolean
  onClose: () => void
}

export function NotificationDrawer({ open, onClose }: NotificationDrawerProps) {
  const { t } = useI18n()
  const notifications = useNotifications((s) => s.notifications)
  const markAsRead = useNotifications((s) => s.markAsRead)
  const clearNotification = useNotifications((s) => s.clearNotification)
  const clearAll = useNotifications((s) => s.clearAll)
  const markAllAsRead = useNotifications((s) => s.markAllAsRead)
  const unreadCount = useNotifications((s) => s.unreadCount())
  const reduced = useReducedMotion()

  const handleMarkAsRead = (id: string): void => {
    markAsRead(id)
  }

  const handleClearNotification = (id: string): void => {
    clearNotification(id)
  }

  const handleMarkAllAsRead = (): void => {
    markAllAsRead()
  }

  const handleClearAll = (): void => {
    clearAll()
  }

  return (
    <AnimatePresence>
      {open ? (
        <>
          <motion.div
            initial={reduced ? false : { opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={reduced ? { opacity: 0 } : { opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm"
            onClick={onClose}
          />
          <motion.div
            initial={reduced ? false : { opacity: 0, x: 320 }}
            animate={{ opacity: 1, x: 0 }}
            exit={reduced ? { opacity: 0 } : { opacity: 0, x: 320 }}
            transition={{ type: 'spring', stiffness: 400, damping: 30 }}
            className="fixed right-0 top-0 h-full w-[400px] z-50 flex flex-col"
            style={{
              background: 'rgba(7, 2, 1, 0.96)',
              borderLeft: '1px solid rgba(255, 255, 255, 0.08)',
              boxShadow: '-24px 0 80px -40px rgba(0, 0, 0, 0.9)',
            }}
          >
            <div className="flex items-center justify-between px-6 py-5 border-b border-white/[0.06]">
              <div>
                <h2 className="text-lg font-semibold text-text-primary">{t('notifications.title')}</h2>
                {unreadCount > 0 && (
                  <p className="text-xs text-text-secondary mt-0.5">
                    {unreadCount} {unreadCount === 1 ? t('notifications.unread') : t('notifications.unread_plural')}
                  </p>
                )}
              </div>
              <button
                type="button"
                onClick={onClose}
                className="shrink-0 text-text-tertiary hover:text-text-primary transition-colors"
                aria-label={t('common.close')}
              >
                <X size={20} strokeWidth={1.9} />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-4 space-y-2">
              {notifications.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-full text-center">
                  <div
                    className="w-16 h-16 rounded-2xl flex items-center justify-center mb-4"
                    style={{
                      background: 'rgba(255, 255, 255, 0.03)',
                      border: '1px solid rgba(255, 255, 255, 0.06)',
                    }}
                  >
                    <CheckCircle2 size={32} strokeWidth={1.5} className="text-text-tertiary" />
                  </div>
                  <p className="text-sm text-text-secondary">{t('notifications.empty')}</p>
                </div>
              ) : (
                notifications.map((notification) => {
                  const meta = TYPE_META[notification.type]
                  const Icon = meta.icon
                  return (
                    <motion.div
                      key={notification.id}
                      initial={reduced ? false : { opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      className={cn(
                        'rounded-xl p-4 border transition-all',
                        notification.read ? 'bg-white/[0.02] border-white/[0.04]' : 'bg-white/[0.04] border-white/[0.08]'
                      )}
                      style={
                        !notification.read
                          ? {
                              borderColor: meta.border,
                              background: `${meta.bg}40`,
                            }
                          : undefined
                      }
                    >
                      <div className="flex items-start gap-3">
                        <div
                          className="shrink-0 mt-0.5 inline-flex h-9 w-9 items-center justify-center rounded-lg"
                          style={{ background: 'rgba(0,0,0,0.32)' }}
                        >
                          <Icon size={18} strokeWidth={2} style={{ color: meta.iconColor }} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2">
                            <h3 className="text-sm font-semibold text-text-primary tactile-wght-breathing">
                              {notification.title}
                            </h3>
                            {!notification.read && (
                              <span
                                className="shrink-0 w-2 h-2 rounded-full"
                                style={{ background: meta.iconColor }}
                              />
                            )}
                          </div>
                          {notification.message && (
                            <p className="text-xs text-text-secondary mt-1 leading-relaxed">{notification.message}</p>
                          )}
                          <p className="text-[10px] text-text-tertiary mt-2">
                            {new Date(notification.timestamp).toLocaleString()}
                          </p>
                          {notification.action && (
                            <div className="mt-3">
                              <Button
                                size="sm"
                                variant="ghost"
                                silent
                                onClick={() => {
                                  notification.action?.onClick()
                                  handleMarkAsRead(notification.id)
                                }}
                              >
                                {notification.action.label}
                              </Button>
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center gap-2 mt-3 pt-3 border-t border-white/[0.04]">
                        {!notification.read && (
                          <Button
                            size="sm"
                            variant="ghost"
                            silent
                            onClick={() => handleMarkAsRead(notification.id)}
                            className="text-xs"
                          >
                            <Check size={14} strokeWidth={2} className="mr-1" />
                            {t('notifications.markRead')}
                          </Button>
                        )}
                        <Button
                          size="sm"
                          variant="ghost"
                          silent
                          onClick={() => handleClearNotification(notification.id)}
                          className="text-xs text-text-tertiary hover:text-text-primary"
                        >
                          <Trash2 size={14} strokeWidth={2} className="mr-1" />
                          {t('notifications.delete')}
                        </Button>
                      </div>
                    </motion.div>
                  )
                })
              )}
            </div>

            {notifications.length > 0 && (
              <div className="flex items-center justify-between px-6 py-4 border-t border-white/[0.06]">
                {unreadCount > 0 && (
                  <Button
                    size="sm"
                    variant="ghost"
                    silent
                    onClick={handleMarkAllAsRead}
                    className="text-xs"
                  >
                    <Check size={14} strokeWidth={2} className="mr-1" />
                    {t('notifications.markAllRead')}
                  </Button>
                )}
                <Button
                  size="sm"
                  variant="ghost"
                  silent
                  onClick={handleClearAll}
                  className="text-xs text-text-tertiary hover:text-text-primary ml-auto"
                >
                  <Trash2 size={14} strokeWidth={2} className="mr-1" />
                  {t('notifications.clearAll')}
                </Button>
              </div>
            )}
          </motion.div>
        </>
      ) : null}
    </AnimatePresence>
  )
}
