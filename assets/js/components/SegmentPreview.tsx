import React from 'react'
import { PreviewResult } from '../lib/types/filter-tree'

interface SegmentPreviewProps {
  result: PreviewResult
}

export const SegmentPreview: React.FC<SegmentPreviewProps> = ({ result }) => {
  const { totals, sample_percent, warnings } = result

  return (
    <div className="segment-preview bg-gray-50 border rounded-lg p-4">
      <h3 className="text-lg font-medium mb-3">Preview Results</h3>

      {/* Sample Warning */}
      {sample_percent < 100 && (
        <div className="mb-3 p-2 bg-yellow-50 border border-yellow-200 rounded text-sm text-yellow-700">
          Results based on {sample_percent}% sample
        </div>
      )}

      {/* Warnings */}
      {warnings && warnings.length > 0 && (
        <div className="mb-3">
          {warnings.map((warning, index) => (
            <div key={index} className="p-2 bg-blue-50 border border-blue-200 rounded text-sm text-blue-700 mb-1">
              {warning}
            </div>
          ))}
        </div>
      )}

      {/* Totals */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white p-4 rounded-lg border shadow-sm">
          <div className="text-3xl font-bold text-blue-600">
            {totals.visitors.toLocaleString()}
          </div>
          <div className="text-sm text-gray-500">Visitors</div>
        </div>

        {totals.pageviews !== undefined && (
          <div className="bg-white p-4 rounded-lg border shadow-sm">
            <div className="text-3xl font-bold text-green-600">
              {totals.pageviews.toLocaleString()}
            </div>
            <div className="text-sm text-gray-500">Pageviews</div>
          </div>
        )}
      </div>

      {/* Time Series Data */}
      {result.results && result.results.length > 0 && (
        <div className="mt-4">
          <h4 className="text-sm font-medium mb-2">Trend</h4>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b">
                  <th className="text-left py-2 px-3">Date</th>
                  <th className="text-right py-2 px-3">Visitors</th>
                  {result.results[0]?.pageviews !== undefined && (
                    <th className="text-right py-2 px-3">Pageviews</th>
                  )}
                </tr>
              </thead>
              <tbody>
                {result.results.map((row, index) => (
                  <tr key={index} className="border-b border-gray-100">
                    <td className="py-2 px-3">{row.date}</td>
                    <td className="text-right py-2 px-3">{row.visitors.toLocaleString()}</td>
                    {row.pageviews !== undefined && (
                      <td className="text-right py-2 px-3">{row.pageviews?.toLocaleString()}</td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Zero Results Message */}
      {totals.visitors === 0 && (
        <div className="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg text-center">
          <p className="text-yellow-800 font-medium">No visitors match your filters</p>
          <p className="text-yellow-600 text-sm mt-1">
            Try removing some filters or broadening your criteria
          </p>
        </div>
      )}
    </div>
  )
}

export default SegmentPreview
