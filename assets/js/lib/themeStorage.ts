import { setItem, getItem } from '../dashboard/util/storage'

export type ThemeMode = 'light' | 'dark'

const THEME_STORAGE_KEY = 'theme_preference'

export function loadThemePreference(): ThemeMode | null {
  const saved = getItem(THEME_STORAGE_KEY)
  if (saved === 'light' || saved === 'dark') {
    return saved
  }
  return null
}

export function saveThemePreference(mode: ThemeMode): void {
  setItem(THEME_STORAGE_KEY, mode)
}

export function getSystemThemePreference(): ThemeMode {
  if (typeof window !== 'undefined' && window.matchMedia) {
    return window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'light'
  }
  return 'light'
}
