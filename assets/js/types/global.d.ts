// Global type declarations for the dashboard
export {}

declare global {
  interface Window {
    plausible?: {
      siteId?: string
      [key: string]: unknown
    }
  }
}
