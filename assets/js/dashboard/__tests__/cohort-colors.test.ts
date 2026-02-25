import { getRetentionLevel, RETENTION_THRESHOLDS } from '../stats/cohort/cohort-theme'

describe('Cohort Colors', () => {
  describe('getRetentionLevel', () => {
    it('returns "high" for retention >= 25%', () => {
      expect(getRetentionLevel(1.0)).toBe('high')
      expect(getRetentionLevel(0.5)).toBe('high')
      expect(getRetentionLevel(0.25)).toBe('high')
    })

    it('returns "medium" for retention between 10% and 25%', () => {
      expect(getRetentionLevel(0.24)).toBe('medium')
      expect(getRetentionLevel(0.15)).toBe('medium')
      expect(getRetentionLevel(0.1)).toBe('medium')
    })

    it('returns "low" for retention < 10%', () => {
      expect(getRetentionLevel(0.09)).toBe('low')
      expect(getRetentionLevel(0.05)).toBe('low')
      expect(getRetentionLevel(0.0)).toBe('low')
    })
  })

  describe('RETENTION_THRESHOLDS', () => {
    it('has correct HIGH threshold', () => {
      expect(RETENTION_THRESHOLDS.HIGH).toBe(0.25)
    })

    it('has correct LOW threshold', () => {
      expect(RETENTION_THRESHOLDS.LOW).toBe(0.1)
    })

    it('HIGH is greater than LOW', () => {
      expect(RETENTION_THRESHOLDS.HIGH).toBeGreaterThan(RETENTION_THRESHOLDS.LOW)
    })
  })
})
