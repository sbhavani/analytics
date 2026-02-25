import React, { useEffect, useState, useRef } from 'react'
import FlipMove from 'react-flip-move'
import Chart from 'chart.js/auto'
import FunnelTooltip from './funnel-tooltip'
import ChartDataLabels from 'chartjs-plugin-datalabels'
import { numberShortFormatter } from '../util/number-formatter'
import Bar from '../stats/bar'
import { isComparisonEnabled } from '../dashboard-time-periods'

import RocketIcon from '../stats/modals/rocket-icon'

import * as api from '../api'
import LazyLoader from '../components/lazy-loader'
import { useDashboardStateContext } from '../dashboard-state-context'
import { useSiteContext } from '../site-context'
import { UIMode, useTheme } from '../theme-context'

const getPalette = (theme) => {
  if (theme.mode === UIMode.dark) {
    return {
      dataLabelBackground: 'rgb(9, 9, 11)',
      dataLabelTextColor: 'rgb(244, 244, 245)',
      visitorsBackground: 'rgb(99, 102, 241)',
      dropoffBackground: 'rgb(63, 63, 70)',
      dropoffStripes: 'rgb(9, 9, 11)',
      stepNameLegendColor: 'rgb(228, 228, 231)',
      visitorsLegendClass: 'bg-indigo-500',
      dropoffLegendClass: 'bg-gray-600',
      smallBarClass: 'bg-indigo-500',
      comparisonA: 'rgb(99, 102, 241)',
      comparisonB: 'rgb(168, 85, 247)',
      positiveChange: 'rgb(34, 197, 94)',
      negativeChange: 'rgb(239, 68, 68)'
    }
  } else {
    return {
      dataLabelBackground: 'rgb(39, 39, 42)',
      dataLabelTextColor: 'rgb(244, 244, 245)',
      visitorsBackground: 'rgb(99, 102, 241)',
      dropoffBackground: 'rgb(224, 231, 255)',
      dropoffStripes: 'rgb(255, 255, 255)',
      stepNameLegendColor: 'rgb(24, 24, 27)',
      visitorsLegendClass: 'bg-indigo-500',
      dropoffLegendClass: 'bg-indigo-100',
      smallBarClass: 'bg-indigo-300',
      comparisonA: 'rgb(99, 102, 241)',
      comparisonB: 'rgb(168, 85, 247)',
      positiveChange: 'rgb(22, 163, 74)',
      negativeChange: 'rgb(220, 38, 38)'
    }
  }
}

const formatChange = (value) => {
  if (value === null || value === undefined) return '-'
  const prefix = value > 0 ? '+' : ''
  return `${prefix}${value}%`
}

export default function Funnel({ funnelName, tabs }) {
  const site = useSiteContext()
  const { dashboardState } = useDashboardStateContext()
  const [loading, setLoading] = useState(true)
  const [visible, setVisible] = useState(false)
  const [error, setError] = useState(undefined)
  const [funnel, setFunnel] = useState(null)
  const [comparison, setComparison] = useState(null)
  const [isSmallScreen, setSmallScreen] = useState(false)
  const theme = useTheme()
  const chartRef = useRef(null)
  const canvasRef = useRef(null)

  useEffect(() => {
    if (visible) {
      setLoading(true)
      fetchFunnel()
        .then((res) => {
          setFunnel(res)
          setError(undefined)
        })
        .catch((error) => {
          setError(error)
        })
        .finally(() => {
          setLoading(false)
        })

      // Fetch comparison data if comparison mode is enabled
      if (isComparisonEnabled(dashboardState.comparison)) {
        fetchComparison()
          .then((res) => {
            setComparison(res)
          })
          .catch(() => {
            setComparison(null)
          })
      } else {
        setComparison(null)
      }

      return () => {
        if (chartRef.current) {
          chartRef.current.destroy()
        }
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dashboardState, funnelName, visible, isSmallScreen])

  useEffect(() => {
    if (canvasRef.current && funnel && visible && !isSmallScreen) {
      initialiseChart(getPalette(theme))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [funnel, visible, theme])

  useEffect(() => {
    const mediaQuery = window.matchMedia('(max-width: 768px)')
    setSmallScreen(mediaQuery.matches)
    const handleScreenChange = (e) => {
      setSmallScreen(e.matches)
    }
    mediaQuery.addEventListener('change', handleScreenChange)
    return () => {
      mediaQuery.removeEventListener('change', handleScreenChange)
    }
  }, [])

  const repositionFunnelTooltip = (e) => {
    const tooltipEl = document.getElementById('chartjs-tooltip-funnel')
    if (tooltipEl && window.innerWidth >= 768) {
      if (e.clientX > 0.66 * window.innerWidth) {
        tooltipEl.style.right =
          window.innerWidth - e.clientX + window.pageXOffset + 'px'
        tooltipEl.style.left = null
      } else {
        tooltipEl.style.right = null
        tooltipEl.style.left = e.clientX + window.pageXOffset + 'px'
      }
      tooltipEl.style.top = e.clientY + window.pageYOffset + 'px'
      tooltipEl.style.opacity = 1
    }
  }

  useEffect(() => {
    window.addEventListener('mousemove', repositionFunnelTooltip)
    return () => {
      window.removeEventListener('mousemove', repositionFunnelTooltip)
    }
  }, [])

  const formatDataLabel = (visitors, ctx) => {
    if (ctx.dataset.label === 'Visitors') {
      const conversionRate = funnel.steps[ctx.dataIndex].conversion_rate
      return `${conversionRate}% \n(${numberShortFormatter(visitors)} Visitors)`
    } else {
      return null
    }
  }

  const calcOffset = (ctx) => {
    const conversionRate = parseFloat(
      funnel.steps[ctx.dataIndex].conversion_rate
    )
    if (conversionRate > 90) {
      return -64
    } else if (conversionRate > 20) {
      return -28
    } else {
      return 8
    }
  }

  const getFunnel = () => {
    return site.funnels.find((funnel) => funnel.name === funnelName)
  }

  const fetchFunnel = async () => {
    const funnelMeta = getFunnel()
    if (typeof funnelMeta === 'undefined') {
      throw new Error('Could not fetch the funnel. Perhaps it was deleted?')
    } else {
      return api.get(
        `/api/stats/${encodeURIComponent(site.domain)}/funnels/${funnelMeta.id}`,
        dashboardState
      )
    }
  }

  const fetchComparison = async () => {
    const funnelMeta = getFunnel()
    if (typeof funnelMeta === 'undefined') {
      return null
    } else {
      return api.get(
        `/api/stats/${encodeURIComponent(site.domain)}/funnels/${funnelMeta.id}/comparison`,
        dashboardState
      )
    }
  }

  const initialiseChart = (palette) => {
    if (chartRef.current) {
      chartRef.current.destroy()
    }

    const createDiagonalPattern = (color1, color2) => {
      // create a 10x10 px canvas for the pattern's base shape
      let shape = document.createElement('canvas')
      shape.width = 10
      shape.height = 10
      let c = shape.getContext('2d')

      c.fillStyle = color1
      c.strokeStyle = color2
      c.fillRect(0, 0, shape.width, shape.height)

      c.beginPath()
      c.moveTo(2, 0)
      c.lineTo(10, 8)
      c.stroke()

      c.beginPath()
      c.moveTo(0, 8)
      c.lineTo(2, 10)
      c.stroke()

      return c.createPattern(shape, 'repeat')
    }

    const labels = funnel.steps.map((step) => step.label)
    const stepData = funnel.steps.map((step) => step.visitors)

    const dropOffData = funnel.steps.map((step) => step.dropoff)
    const ctx = canvasRef.current.getContext('2d')

    const calcBarThickness = (ctx) => {
      if (ctx.dataset.data.length <= 3) {
        return 160
      } else {
        return Math.floor(650 / ctx.dataset.data.length)
      }
    }

    // passing those verbatim to make sure canvas rendering picks them up
    var fontFamily =
      'ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"'

    var gradient = ctx.createLinearGradient(900, 0, 900, 900)
    gradient.addColorStop(1, palette.dropoffBackground)
    gradient.addColorStop(0, palette.visitorsBackground)

    const data = {
      labels: labels,
      datasets: [
        {
          label: 'Visitors',
          data: stepData,
          backgroundColor: gradient,
          hoverBackgroundColor: gradient,
          borderRadius: 4,
          stack: 'Stack 0'
        },
        {
          label: 'Dropoff',
          data: dropOffData,
          backgroundColor: createDiagonalPattern(
            palette.dropoffBackground,
            palette.dropoffStripes
          ),
          hoverBackgroundColor: palette.dropoffBackground,
          borderRadius: 4,
          stack: 'Stack 0'
        }
      ]
    }

    const config = {
      plugins: [ChartDataLabels],
      type: 'bar',
      data: data,
      options: {
        responsive: true,
        barThickness: calcBarThickness,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            enabled: false,
            mode: 'index',
            intersect: true,
            position: 'average',
            external: FunnelTooltip(palette, funnel)
          },
          datalabels: {
            formatter: formatDataLabel,
            anchor: 'end',
            align: 'end',
            offset: calcOffset,
            backgroundColor: palette.dataLabelBackground,
            color: palette.dataLabelTextColor,
            borderRadius: 4,
            clip: true,
            font: {
              size: 12,
              weight: 'normal',
              lineHeight: 1.6,
              family: fontFamily
            },
            textAlign: 'center',
            padding: { top: 8, bottom: 8, right: 8, left: 8 }
          }
        },
        scales: {
          y: { display: false },
          x: {
            position: 'bottom',
            display: true,
            border: { display: false },
            grid: { drawBorder: false, display: false },
            ticks: {
              padding: 8,
              font: { weight: 'bold', family: fontFamily, size: 14 },
              color: palette.stepNameLegendColor
            }
          }
        }
      }
    }

    chartRef.current = new Chart(ctx, config)
  }

  const header = () => {
    return (
      <div className="flex justify-between w-full">
        <h4 className="mt-2 text-base font-semibold dark:text-gray-100">
          {funnelName}
        </h4>
        {tabs}
      </div>
    )
  }

  const renderError = () => {
    if (error.name === 'AbortError') return
    if (error.payload && error.payload.level === 'normal') {
      return (
        <>
          {header()}
          <div className="font-medium text-center text-gray-500 mt-44 dark:text-gray-400">
            {error.message}
          </div>
        </>
      )
    } else {
      return (
        <>
          {header()}
          <div className="text-center text-gray-900 dark:text-gray-100 mt-16">
            <RocketIcon />
            <div className="text-lg font-bold">Oops! Something went wrong</div>
            <div className="text-lg">
              {error.message ? error.message : 'Failed to render funnel'}
            </div>
            <div className="text-xs mt-8">
              Please try refreshing your browser or selecting the funnel again.
            </div>
          </div>
        </>
      )
    }
  }

  const renderEmptyState = () => {
    return (
      <>
        {header()}
        <div className="font-medium text-center text-gray-500 mt-44 dark:text-gray-400">
          No data for selected period
        </div>
      </>
    )
  }

  const renderWarning = (message) => {
    return (
      <div className="mt-2 p-2 bg-yellow-50 border border-yellow-200 rounded text-yellow-700 text-sm dark:bg-yellow-900 dark:border-yellow-700 dark:text-yellow-200">
        {message}
      </div>
    )
  }

  const renderComparisonChart = (comparisonData, theme) => {
    const palette = getPalette(theme)
    const { comparison } = comparisonData

    return (
      <div className="mt-6 overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b dark:border-gray-700">
              <th className="py-2 text-left font-medium text-gray-500 dark:text-gray-400">Step</th>
              <th className="py-2 text-right font-medium text-indigo-500">Current Period</th>
              <th className="py-2 text-right font-medium text-purple-500">Comparison Period</th>
              <th className="py-2 text-right font-medium text-gray-500 dark:text-gray-400">Change</th>
            </tr>
          </thead>
          <tbody>
            {comparison.map((step, index) => {
              const isPositiveVisitors = step.visitors_change >= 0
              const isPositiveConversion = step.conversion_change >= 0

              return (
                <tr key={index} className="border-b dark:border-gray-700">
                  <td className="py-3 font-medium dark:text-gray-200">{step.label}</td>
                  <td className="py-3 text-right">
                    <div className="font-medium dark:text-gray-200">{numberShortFormatter(step.visitors_a)}</div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">{step.conversion_rate_a}%</div>
                  </td>
                  <td className="py-3 text-right">
                    <div className="font-medium dark:text-gray-200">{numberShortFormatter(step.visitors_b)}</div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">{step.conversion_rate_b}%</div>
                  </td>
                  <td className="py-3 text-right">
                    <div className={`font-medium ${isPositiveVisitors ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                      {formatChange(step.visitors_change)}
                    </div>
                    <div className={`text-xs ${isPositiveConversion ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                      {formatChange(step.conversion_change)}
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>

        {/* Comparison Legend */}
        <div className="mt-4 flex items-center justify-center gap-6 text-xs">
          <div className="flex items-center gap-2">
            <span className="inline-block w-3 h-3 rounded bg-indigo-500"></span>
            <span className="text-gray-500 dark:text-gray-400">Current Period</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="inline-block w-3 h-3 rounded bg-purple-500"></span>
            <span className="text-gray-500 dark:text-gray-400">Comparison Period</span>
          </div>
        </div>
      </div>
    )
  }

  const renderInner = (theme) => {
    if (loading) {
      return (
        <div className="mx-auto loading pt-44">
          <div></div>
        </div>
      )
    } else if (error) {
      return renderError()
    } else if (funnel) {
      // Check for empty state - no entering visitors
      const hasData = funnel.entering_visitors > 0

      if (!hasData) {
        return renderEmptyState()
      }

      const conversionRate =
        funnel.steps[funnel.steps.length - 1].conversion_rate

      // Warning for single-step funnel
      const showStepWarning = funnel.steps.length < 2
      // Warning for date range > 1 year - check from dashboardState
      const dateRange = dashboardState?.query?.date_range
      const showDateWarning = dateRange &&
        (new Date(dateRange[1]) - new Date(dateRange[0])) > (365 * 24 * 60 * 60 * 1000)

      return (
        <div className="mb-8">
          {header()}
          <p className="mt-0.5 text-gray-500 text-sm">
            {funnel.steps.length}-step funnel • {conversionRate}% conversion
            rate
          </p>
          {showStepWarning && renderWarning('Funnels need at least 2 steps to show conversion rates')}
          {showDateWarning && renderWarning('Date range exceeds 1 year - data granularity may be affected')}
          {isSmallScreen && (
            <div className="mt-4">{renderBars(funnel, theme)}</div>
          )}
          {comparison && comparison.comparison && (
            renderComparisonChart(comparison, theme)
          )}
        </div>
      )
    }
  }

  const renderBar = (step, theme) => {
    const palette = getPalette(theme)
    return (
      <>
        <div className="flex items-center justify-between my-1 text-sm">
          <Bar
            count={step.visitors}
            all={funnel.steps}
            bg={palette.smallBarClass}
            maxWidthDeduction={'5rem'}
            plot={'visitors'}
          >
            <span className="flex px-2 py-1.5 group dark:text-gray-100 relative z-9 break-all">
              {step.label}
            </span>
          </Bar>

          <span
            className="font-medium dark:text-gray-200 w-20 text-right"
            tooltip={step.visitors.toLocaleString()}
          >
            {numberShortFormatter(step.visitors)}
          </span>
        </div>
      </>
    )
  }

  const renderBars = (funnel, theme) => {
    return (
      <>
        <div className="flex items-center justify-between mt-3 mb-2 text-xs font-bold tracking-wide text-gray-500 dark:text-gray-400">
          <span>&nbsp;</span>
          <span className="text-right">
            <span className="inline-block w-20">Visitors</span>
          </span>
        </div>
        <FlipMove>
          {funnel.steps.map((step) => renderBar(step, theme))}
        </FlipMove>
      </>
    )
  }

  return (
    <div style={{ minHeight: '400px' }}>
      <LazyLoader onVisible={() => setVisible(true)}>
        {renderInner(theme)}
      </LazyLoader>
      {!isSmallScreen && (
        <canvas className="" id="funnel" ref={canvasRef}></canvas>
      )}
    </div>
  )
}
