import {
  loadThemePreference,
  saveThemePreference,
  getSystemThemePreference,
  ThemeMode
} from '../themeStorage'

// Mock the storage module
jest.mock('../../dashboard/util/storage', () => ({
  getItem: jest.fn(),
  setItem: jest.fn()
}))

import { getItem, setItem } from '../../dashboard/util/storage'

describe('themeStorage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('loadThemePreference', () => {
    it('returns "light" when saved preference is "light"', () => {
      ;(getItem as jest.Mock).mockReturnValue('light')
      expect(loadThemePreference()).toBe('light')
    })

    it('returns "dark" when saved preference is "dark"', () => {
      ;(getItem as jest.Mock).mockReturnValue('dark')
      expect(loadThemePreference()).toBe('dark')
    })

    it('returns null when no preference is saved', () => {
      ;(getItem as jest.Mock).mockReturnValue(null)
      expect(loadThemePreference()).toBeNull()
    })

    it('returns null for invalid preference values', () => {
      ;(getItem as jest.Mock).mockReturnValue('blue')
      expect(loadThemePreference()).toBeNull()
    })

    it('returns null for empty string preference', () => {
      ;(getItem as jest.Mock).mockReturnValue('')
      expect(loadThemePreference()).toBeNull()
    })

    it('calls getItem with correct storage key', () => {
      ;(getItem as jest.Mock).mockReturnValue('dark')
      loadThemePreference()
      expect(getItem).toHaveBeenCalledWith('theme_preference')
    })
  })

  describe('saveThemePreference', () => {
    it('saves "light" preference to storage', () => {
      saveThemePreference('light')
      expect(setItem).toHaveBeenCalledWith('theme_preference', 'light')
    })

    it('saves "dark" preference to storage', () => {
      saveThemePreference('dark')
      expect(setItem).toHaveBeenCalledWith('theme_preference', 'dark')
    })

    it('uses correct storage key when saving', () => {
      saveThemePreference('dark' as ThemeMode)
      expect(setItem).toHaveBeenCalledWith('theme_preference', 'dark')
    })
  })

  describe('getSystemThemePreference', () => {
    const originalMatchMedia = window.matchMedia

    beforeEach(() => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: jest.fn()
      })
    })

    afterEach(() => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: originalMatchMedia
      })
    })

    it('returns "dark" when system prefers dark mode', () => {
      ;(window.matchMedia as jest.Mock).mockReturnValue({
        matches: true
      })
      expect(getSystemThemePreference()).toBe('dark')
    })

    it('returns "light" when system prefers light mode', () => {
      ;(window.matchMedia as jest.Mock).mockReturnValue({
        matches: false
      })
      expect(getSystemThemePreference()).toBe('light')
    })

    it('returns "light" when window.matchMedia is not available', () => {
      Object.defineProperty(window, 'matchMedia', {
        writable: true,
        value: undefined
      })
      expect(getSystemThemePreference()).toBe('light')
    })
  })

  describe('localStorage persistence integration', () => {
    it('persists and retrieves theme preference correctly', () => {
      // Simulate saving dark mode
      saveThemePreference('dark')
      expect(setItem).toHaveBeenCalledWith('theme_preference', 'dark')

      // Simulate loading the saved preference
      ;(getItem as jest.Mock).mockReturnValue('dark')
      const loaded = loadThemePreference()
      expect(loaded).toBe('dark')
    })

    it('handles switching from dark to light mode', () => {
      // Start with dark mode
      saveThemePreference('dark')
      ;(getItem as jest.Mock).mockReturnValue('dark')
      expect(loadThemePreference()).toBe('dark')

      // Switch to light mode
      saveThemePreference('light')
      ;(getItem as jest.Mock).mockReturnValue('light')
      expect(loadThemePreference()).toBe('light')
    })
  })
})
