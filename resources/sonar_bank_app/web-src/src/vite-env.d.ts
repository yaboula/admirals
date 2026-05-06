/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_MOCK_MODE?: string
  readonly VITE_BANK_FE_VERSION?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

declare global {
  interface Window {
    GetParentResourceName?: () => string
    invokeNative?: (name: string, ...args: unknown[]) => void
    __mockBankEvent?: (eventName: string, payload: unknown) => void
  }

  function GetParentResourceName(): string
}

export {}
