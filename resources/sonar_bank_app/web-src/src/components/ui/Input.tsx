import { forwardRef, useId, type InputHTMLAttributes, type ReactNode } from 'react'
import { cn } from '@/lib/utils'

export type InputSize = 'sm' | 'md' | 'lg'

export interface InputProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, 'size' | 'prefix'> {
  label?: ReactNode
  hint?: ReactNode
  error?: ReactNode
  leftAdornment?: ReactNode
  rightAdornment?: ReactNode
  fullWidth?: boolean
  inputSize?: InputSize
}

const SIZE_CLASSES: Record<InputSize, string> = {
  sm: 'h-8 px-3 text-sm',
  md: 'h-10 px-3.5 text-base',
  lg: 'h-12 px-4 text-md',
}

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  {
    label,
    hint,
    error,
    leftAdornment,
    rightAdornment,
    fullWidth = true,
    inputSize = 'md',
    className,
    id,
    disabled,
    ...rest
  },
  ref,
) {
  const fallbackId = useId()
  const inputId = id ?? fallbackId
  const hintId = `${inputId}-hint`
  const errorId = `${inputId}-error`
  const hasError = Boolean(error)
  const describedBy = hasError ? errorId : hint ? hintId : undefined

  return (
    <div className={cn('flex flex-col gap-1.5', fullWidth ? 'w-full' : 'w-auto')}>
      {label && (
        <label
          htmlFor={inputId}
          className="text-sm font-medium text-text-secondary tracking-tight"
        >
          {label}
        </label>
      )}
      <div
        className={cn(
          'tactile-input tactile-focus-ring',
          'flex items-center w-full',
          SIZE_CLASSES[inputSize],
          disabled && 'opacity-50 pointer-events-none',
        )}
      >
        {leftAdornment && (
          <span className="mr-2 shrink-0 inline-flex items-center justify-center text-text-tertiary">
            {leftAdornment}
          </span>
        )}
        <input
          ref={ref}
          id={inputId}
          disabled={disabled}
          aria-invalid={hasError || undefined}
          aria-describedby={describedBy}
          className={cn(
            'flex-1 bg-transparent border-none outline-none w-full',
            'text-text-primary placeholder:text-text-tertiary',
            'disabled:cursor-not-allowed',
            className,
          )}
          {...rest}
        />
        {rightAdornment && (
          <span className="ml-2 shrink-0 inline-flex items-center justify-center text-text-tertiary">
            {rightAdornment}
          </span>
        )}
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
