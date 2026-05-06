export const isMockMode = (): boolean => {
  return import.meta.env.VITE_MOCK_MODE === 'true'
}

export const isDev = (): boolean => {
  return import.meta.env.DEV === true
}

export const getResourceName = (): string => {
  if (typeof window !== 'undefined' && typeof window.GetParentResourceName === 'function') {
    return window.GetParentResourceName()
  }
  return 'sonar_bank_app'
}

export const getNuiBaseUrl = (): string => {
  return `https://${getResourceName()}`
}

export const isInsideFiveMNui = (): boolean => {
  return typeof window !== 'undefined' && typeof window.GetParentResourceName === 'function'
}

export const FE_VERSION = (import.meta.env.VITE_BANK_FE_VERSION as string | undefined) ?? '0.1.0-dev'
