import React from 'react'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { SegmentList, Segment } from '../../js/components/SegmentList'

// Mock fetch globally
global.fetch = jest.fn()

const mockFetch = global.fetch as jest.MockedFunction<typeof fetch>

describe('SegmentList', () => {
  const mockSegments: Segment[] = [
    {
      id: '1',
      name: 'US Visitors',
      visitor_count: 1500,
      created_at: '2025-01-01T10:00:00Z',
      updated_at: '2025-01-15T10:00:00Z'
    },
    {
      id: '2',
      name: 'Mobile Users',
      visitor_count: 3200,
      created_at: '2025-01-05T10:00:00Z',
      updated_at: '2025-01-20T10:00:00Z'
    },
    {
      id: '3',
      name: 'Returning Visitors',
      created_at: '2025-01-10T10:00:00Z',
      updated_at: '2025-01-25T10:00:00Z'
    }
  ]

  beforeEach(() => {
    mockFetch.mockClear()
  })

  const renderComponent = (props = {}) => {
    const defaultProps = {
      siteId: 'site-123',
      onSelectSegment: jest.fn(),
      onDeleteSegment: jest.fn().mockResolvedValue(undefined),
      onCreateNew: jest.fn()
    }
    return render(<SegmentList {...defaultProps} {...props} />)
  }

  describe('Loading state', () => {
    it('shows loading skeleton while fetching segments', () => {
      mockFetch.mockImplementation(() => new Promise(() => {})) // Never resolves

      renderComponent()

      // Loading skeleton should be present (animating div)
      expect(document.querySelector('.animate-pulse')).toBeInTheDocument()
    })
  })

  describe('Error handling', () => {
    it('displays error message when fetch fails', async () => {
      mockFetch.mockRejectedValue(new Error('Network error'))

      renderComponent()

      await waitFor(() => {
        expect(screen.getByText(/network error/i)).toBeInTheDocument()
      })
    })

    it('displays error when response is not ok', async () => {
      mockFetch.mockResolvedValue({
        ok: false,
        status: 500
      } as Response)

      renderComponent()

      await waitFor(() => {
        expect(screen.getByText(/failed to fetch segments/i)).toBeInTheDocument()
      })
    })
  })

  describe('Segment rendering', () => {
    beforeEach(() => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ segments: mockSegments })
      } as Response)
    })

    it('renders list of segments', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByText('US Visitors')).toBeInTheDocument()
        expect(screen.getByText('Mobile Users')).toBeInTheDocument()
        expect(screen.getByText('Returning Visitors')).toBeInTheDocument()
      })
    })

    it('displays visitor count when available', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByText(/1,500 visitors/)).toBeInTheDocument()
        expect(screen.getByText(/3,200 visitors/)).toBeInTheDocument()
      })
    })

    it('does not show visitor count when undefined', async () => {
      renderComponent()

      await waitFor(() => {
        // Returning Visitors should not have visitor count
        const returningVisitors = screen.getByText('Returning Visitors')
        const parent = returningVisitors.parentElement
        expect(parent?.textContent).not.toContain('visitors')
      })
    })

    it('displays empty state when no segments', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ segments: [] })
      } as Response)

      renderComponent()

      await waitFor(() => {
        expect(screen.getByText(/no saved segments yet/i)).toBeInTheDocument()
      })
    })
  })

  describe('Search functionality', () => {
    beforeEach(() => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ segments: mockSegments })
      } as Response)
    })

    it('filters segments by search query', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByText('US Visitors')).toBeInTheDocument()
        expect(screen.getByText('Mobile Users')).toBeInTheDocument()
      })

      const searchInput = screen.getByPlaceholderText(/search segments/i)
      fireEvent.change(searchInput, { target: { value: 'mobile' } })

      expect(screen.queryByText('US Visitors')).not.toBeInTheDocument()
      expect(screen.getByText('Mobile Users')).toBeInTheDocument()
    })

    it('shows no results message when search has no matches', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByText('US Visitors')).toBeInTheDocument()
      })

      const searchInput = screen.getByPlaceholderText(/search segments/i)
      fireEvent.change(searchInput, { target: { value: 'nonexistent' } })

      expect(screen.getByText(/no segments match your search/i)).toBeInTheDocument()
    })
  })

  describe('Interactions', () => {
    beforeEach(() => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ segments: mockSegments })
      } as Response)
    })

    it('calls onSelectSegment when segment is clicked', async () => {
      const onSelectSegment = jest.fn()
      renderComponent({ onSelectSegment })

      await waitFor(() => {
        expect(screen.getByText('US Visitors')).toBeInTheDocument()
      })

      const segmentButton = screen.getByText('US Visitors')
      fireEvent.click(segmentButton)

      expect(onSelectSegment).toHaveBeenCalledWith(mockSegments[0])
    })

    it('calls onCreateNew when New Segment button is clicked', async () => {
      const onCreateNew = jest.fn()
      renderComponent({ onCreateNew })

      await waitFor(() => {
        expect(screen.getByText(/new segment/i)).toBeInTheDocument()
      })

      const newButton = screen.getByText(/new segment/i)
      fireEvent.click(newButton)

      expect(onCreateNew).toHaveBeenCalled()
    })

    it('shows delete confirmation when delete button is clicked', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByText('US Visitors')).toBeInTheDocument()
      })

      // Find and click the delete button for the first segment
      const deleteButtons = screen.getAllByTitle('Delete segment')
      fireEvent.click(deleteButtons[0])

      expect(screen.getByText(/delete segment/i)).toBeInTheDocument()
      expect(screen.getByText(/are you sure you want to delete/i)).toBeInTheDocument()
    })

    it('calls onDeleteSegment when delete is confirmed', async () => {
      const onDeleteSegment = jest.fn().mockResolvedValue(undefined)
      renderComponent({ onDeleteSegment })

      await waitFor(() => {
        expect(screen.getByText('US Visitors')).toBeInTheDocument()
      })

      // Open delete confirmation
      const listDeleteButtons = screen.getAllByTitle('Delete segment')
      fireEvent.click(listDeleteButtons[0])

      // Click delete button in modal (the one with red background)
      // Get all buttons with "Delete" and select the one in the modal (last one)
      const allDeleteButtons = screen.getAllByText('Delete')
      const confirmDelete = allDeleteButtons[allDeleteButtons.length - 1]
      fireEvent.click(confirmDelete)

      await waitFor(() => {
        expect(onDeleteSegment).toHaveBeenCalledWith('1')
      })

      // Segment should be removed from the list
      expect(screen.queryByText('US Visitors')).not.toBeInTheDocument()
    })

    it('closes delete confirmation when cancel is clicked', async () => {
      const onDeleteSegment = jest.fn()
      renderComponent({ onDeleteSegment })

      await waitFor(() => {
        expect(screen.getByText('US Visitors')).toBeInTheDocument()
      })

      // Open delete confirmation
      const deleteButtons = screen.getAllByTitle('Delete segment')
      fireEvent.click(deleteButtons[0])

      // Click cancel button
      const cancelButton = screen.getByText(/cancel/i)
      fireEvent.click(cancelButton)

      // Modal should be closed
      expect(screen.queryByText(/delete segment\?/i)).not.toBeInTheDocument()

      // onDeleteSegment should not have been called
      expect(onDeleteSegment).not.toHaveBeenCalled()

      // Segment should still be in the list
      expect(screen.getByText('US Visitors')).toBeInTheDocument()
    })
  })

  describe('API calls', () => {
    it('fetches segments on mount', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ segments: [] })
      } as Response)

      renderComponent({ siteId: 'test-site' })

      await waitFor(() => {
        expect(mockFetch).toHaveBeenCalledWith('/api/sites/test-site/segments')
      })
    })

    it('uses custom apiBaseUrl when provided', async () => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ segments: [] })
      } as Response)

      renderComponent({ siteId: 'test-site', apiBaseUrl: '/custom-api' })

      await waitFor(() => {
        expect(mockFetch).toHaveBeenCalledWith('/custom-api/sites/test-site/segments')
      })
    })
  })

  describe('Accessibility', () => {
    beforeEach(() => {
      mockFetch.mockResolvedValue({
        ok: true,
        json: async () => ({ segments: mockSegments })
      } as Response)
    })

    it('has proper aria-label on search input', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByLabelText(/search segments/i)).toBeInTheDocument()
      })
    })

    it('has proper role on segment list', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByRole('listbox', { name: /segments/i })).toBeInTheDocument()
      })
    })

    it('delete button has proper aria-label', async () => {
      renderComponent()

      await waitFor(() => {
        expect(screen.getByLabelText(/delete us visitors/i)).toBeInTheDocument()
      })
    })
  })
})
