import { forwardRef, useId, useState, type ButtonHTMLAttributes, type SelectHTMLAttributes, type ReactNode } from 'react'
import { motion, AnimatePresence } from 'motion/react'
import { ChevronDown, Check } from 'lucide-react'
import { cn } from '@/lib/utils'

export type SelectSize = 'sm' | 'md' | 'lg'

export interface SelectOption {
  value: string
  label: string
  disabled?: boolean
}

export interface SelectProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'size' | 'value' | 'onChange'> {
  label?: ReactNode
  hint?: ReactNode
  error?: ReactNode
  fullWidth?: boolean
  selectSize?: SelectSize
  value: string
  onChange: (value: string) => void
  options: SelectOption[]
  placeholder?: string
}

const SIZE_CLASSES: Record<SelectSize, string> = {
  sm: 'h-8 px-3 text-sm',
  md: 'h-10 px-3.5 text-base',
  lg: 'h-12 px-4 text-md',
}

export const Select = forwardRef<HTMLButtonElement, SelectProps>(function Select(
  {
    label,
    hint,
    error,
    fullWidth = true,
    selectSize = 'md',
    value,
    onChange,
    options,
    placeholder = 'Select an option...',
    className,
    id,
    disabled,
    ...rest
  },
  ref,
) {
  const fallbackId = useId()
  const selectId = id ?? fallbackId
  const hintId = `${selectId}-hint`
  const errorId = `${selectId}-error`
  const hasError = Boolean(error)
  const describedBy = hasError ? errorId : hint ? hintId : undefined
  const [isOpen, setIsOpen] = useState(false)

  const selectedOption = options.find((opt) => opt.value === value)

  return (
    <div className={cn('flex flex-col gap-1.5', fullWidth ? 'w-full' : 'w-auto')}>
      {label && (
        <label
          htmlFor={selectId}
          className="text-sm font-medium text-text-secondary tracking-tight"
        >
          {label}
        </label>
      )}
      <div className="relative">
        <button
          ref={ref}
          type="button"
          id={selectId}
          disabled={disabled}
          onClick={() => !disabled && setIsOpen(!isOpen)}
          aria-haspopup="listbox"
          aria-expanded={isOpen}
          aria-invalid={hasError || undefined}
          aria-describedby={describedBy}
          className={cn(
            'tactile-input tactile-focus-ring flex items-center justify-between gap-2',
            SIZE_CLASSES[selectSize],
            disabled && 'opacity-50 pointer-events-none cursor-not-allowed',
            'w-full rounded-lg border border-white/10 bg-white/[0.02] px-3 py-2 text-sm text-text-primary focus:border-white/20 focus:outline-none transition-colors',
            className,
          )}
          {...rest}
        >
          <span className={cn('flex-1 text-left', !selectedOption && 'text-text-tertiary')}>
            {selectedOption?.label || placeholder}
          </span>
          <ChevronDown size={16} className={cn('text-text-tertiary transition-transform', isOpen && 'rotate-180')} />
        </button>

        <AnimatePresence>
          {isOpen && (
            <>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="fixed inset-0 z-40"
                onClick={() => setIsOpen(false)}
              />
              <motion.div
                initial={{ opacity: 0, y: -4 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -4 }}
                transition={{ duration: 0.15 }}
                className="absolute z-50 w-full mt-1 rounded-lg border shadow-xl"
                style={{
                  borderColor: 'var(--color-border-subtle)',
                  backgroundColor: 'var(--color-surface-card)',
                }}
              >
                <div
                  className="max-h-60 overflow-auto py-1"
                  role="listbox"
                  aria-activedescendant={value}
                >
                  {options.map((option) => (
                    <button
                      key={option.value}
                      type="button"
                      onClick={() => {
                        onChange(option.value)
                        setIsOpen(false)
                      }}
                      disabled={option.disabled}
                      role="option"
                      aria-selected={value === option.value}
                      className={cn(
                        'flex items-center justify-between gap-2 w-full px-3 py-2 text-sm transition-colors',
                        'hover:bg-white/[0.05] focus:bg-white/[0.05] focus:outline-none',
                        value === option.value ? 'text-text-primary bg-white/[0.08]' : 'text-text-secondary',
                        option.disabled && 'opacity-50 cursor-not-allowed',
                      )}
                    >
                      <span className="flex-1 text-left">{option.label}</span>
                      {value === option.value && (
                        <Check size={14} className="text-semantic-info-deep" />
                      )}
                    </button>
                  ))}
                </div>
              </motion.div>
            </>
          )}
        </AnimatePresence>
      </div>
      {hasError ? (
        <span id={errorId} className="text-sm text-semantic-danger-deep" role="alert">
          {error}
        </span>
      ) : hint ? (
        <span id={hintId} className="text-sm text-text-tertiary">
          {hint}
        </span>
      ) : null}
    </div>
  )
})

// Keep the native select for backward compatibility
export const NativeSelect = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(function NativeSelect(
  {
    className,
    ...rest
  },
  ref,
) {
  return (
    <select
      ref={ref}
      className={cn(
        'tactile-input tactile-focus-ring',
        'w-full rounded-lg border border-white/10 bg-white/[0.02] px-3 py-2 text-sm text-text-primary focus:border-white/20 focus:outline-none',
        className,
      )}
      {...rest}
    />
  )
})
