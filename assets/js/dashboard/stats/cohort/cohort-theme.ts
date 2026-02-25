// Retention color thresholds for cohort analysis

export const RETENTION_THRESHOLDS = {
  HIGH: 0.25, // 25% or higher retention - good
  LOW: 0.1,   // 10% or lower retention - needs attention
} as const

export type RetentionLevel = 'high' | 'medium' | 'low'

export function getRetentionLevel(rate: number): RetentionLevel {
  if (rate >= RETENTION_THRESHOLDS.HIGH) {
    return 'high'
  } else if (rate >= RETENTION_THRESHOLDS.LOW) {
    return 'medium'
  } else {
    return 'low'
  }
}

export const RETENTION_COLORS = {
  light: {
    high: {
      bg: 'bg-emerald-100',
      text: 'text-emerald-800',
      border: 'border-emerald-200',
    },
    medium: {
      bg: 'bg-yellow-100',
      text: 'text-yellow-800',
      border: 'border-yellow-200',
    },
    low: {
      bg: 'bg-red-100',
      text: 'text-red-800',
      border: 'border-red-200',
    },
  },
  dark: {
    high: {
      bg: 'bg-emerald-900',
      text: 'text-emerald-100',
      border: 'border-emerald-700',
    },
    medium: {
      bg: 'bg-yellow-900',
      text: 'text-yellow-100',
      border: 'border-yellow-700',
    },
    low: {
      bg: 'bg-red-900',
      text: 'text-red-100',
      border: 'border-red-700',
    },
  },
} as const
