import { remapToApiFilters } from '../util/filters'
import {
  formatSegmentIdAsLabelKey,
  getSearchToSetSegmentFilter,
  getSegmentNamePlaceholder,
  isSegmentIdLabelKey,
  parseApiSegmentData,
  isListableSegment,
  resolveFilters,
  SegmentType,
  SavedSegment,
  SegmentData,
  canExpandSegment,
  handleSegmentResponse,
  SavedSegments
} from './segments'
import { Filter } from '../dashboard-state'
import { PlausibleSite } from '../site-context'
import { Role, UserContextValue } from '../user-context'
import {
  FilterExpression,
  ConditionGroup,
  createEmptyExpression,
  createCondition,
  expressionToFilters
} from '../components/filter-builder/types'

describe(`${getSegmentNamePlaceholder.name}`, () => {
  it('gives readable result', () => {
    const placeholder = getSegmentNamePlaceholder({
      labels: { US: 'United States' },
      filters: [
        ['is', 'country', ['US']],
        ['contains', 'page', ['/blog', `${new Array(250).fill('c').join('')}`]]
      ]
    })

    expect(placeholder).toEqual(
      'Country is United States and Page contains /blog or ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc'
    )
    expect(placeholder).toHaveLength(255)
  })
})

describe('segment labels in URL search params', () => {
  test(`${formatSegmentIdAsLabelKey.name} and ${isSegmentIdLabelKey.name} work`, () => {
    const formatted = formatSegmentIdAsLabelKey(5)
    expect(formatted).toEqual('segment-5')
    expect(isSegmentIdLabelKey(formatted)).toEqual(true)
  })
})

describe(`${parseApiSegmentData.name}`, () => {
  it('correctly formats values stored as API filters in their dashboard format', () => {
    const apiFormatFilters = [
      ['is', 'visit:country', ['PL']],
      ['is', 'event:props:logged_in', ['true']],
      ['has_not_done', ['is', 'event:goal', ['Signup']]]
    ]
    const dashboardFormat = parseApiSegmentData({
      filters: apiFormatFilters,
      labels: { PL: 'Poland' }
    })
    expect(dashboardFormat).toEqual({
      filters: [
        ['is', 'country', ['PL']],
        ['is', 'props:logged_in', ['true']],
        ['has_not_done', 'goal', ['Signup']]
      ],
      labels: { PL: 'Poland' }
    })
    expect(remapToApiFilters(dashboardFormat.filters)).toEqual(apiFormatFilters)
  })
})

describe(`${getSearchToSetSegmentFilter.name}`, () => {
  test('generated search function omits other filters segment correctly', () => {
    const searchFunction = getSearchToSetSegmentFilter(
      {
        name: 'APAC',
        id: 500
      },
      { omitAllOtherFilters: true }
    )
    const existingSearch = {
      date: '2025-02-10',
      filters: [
        ['is', 'country', ['US']],
        ['is', 'page', ['/blog']]
      ],
      labels: { US: 'United States' }
    }
    expect(searchFunction(existingSearch)).toEqual({
      date: '2025-02-10',
      filters: [['is', 'segment', [500]]],
      labels: { 'segment-500': 'APAC' }
    })
  })

  test('generated search function replaces existing segment filter correctly', () => {
    const searchFunction = getSearchToSetSegmentFilter({
      name: 'APAC',
      id: 500
    })
    const existingSearch = {
      date: '2025-02-10',
      filters: [
        ['is', 'segment', [100]],
        ['is', 'country', ['US']],
        ['is', 'page', ['/blog']]
      ],
      labels: { US: 'United States', 'segment-100': 'Scandinavia' }
    }
    expect(searchFunction(existingSearch)).toEqual({
      date: '2025-02-10',
      filters: [
        ['is', 'segment', [500]],
        ['is', 'country', ['US']],
        ['is', 'page', ['/blog']]
      ],
      labels: { US: 'United States', 'segment-500': 'APAC' }
    })
  })

  test('generated search function sets new segment filter correctly', () => {
    const searchFunction = getSearchToSetSegmentFilter({
      name: 'APAC',
      id: 500
    })
    const existingSearch = {
      date: '2025-02-10',
      filters: [
        ['is', 'country', ['US']],
        ['is', 'page', ['/blog']]
      ],
      labels: { US: 'United States' }
    }
    expect(searchFunction(existingSearch)).toEqual({
      date: '2025-02-10',
      filters: [
        ['is', 'segment', [500]],
        ['is', 'country', ['US']],
        ['is', 'page', ['/blog']]
      ],
      labels: { US: 'United States', 'segment-500': 'APAC' }
    })
  })
})

describe(`${isListableSegment.name}`, () => {
  const site: Pick<PlausibleSite, 'siteSegmentsAvailable'> = {
    siteSegmentsAvailable: true
  }
  const user: UserContextValue = {
    loggedIn: true,
    id: 1,
    role: Role.editor,
    team: { identifier: null, hasConsolidatedView: false }
  }

  it('should return true for site segment when siteSegmentsAvailable is true', () => {
    const segment = { id: 1, type: SegmentType.site, owner_id: 1 }
    expect(isListableSegment({ segment, site, user })).toBe(true)
  })

  it('should return false for personal segment when user is not logged in', () => {
    const segment = { id: 1, type: SegmentType.personal, owner_id: 1 }
    expect(
      isListableSegment({
        segment,
        site,
        user: {
          loggedIn: false,
          role: Role.public,
          id: null,
          team: { identifier: null, hasConsolidatedView: false }
        }
      })
    ).toBe(false)
  })

  it('should return true for personal segment when user is the owner', () => {
    const segment = { id: 1, type: SegmentType.personal, owner_id: 1 }
    expect(isListableSegment({ segment, site, user })).toBe(true)
  })

  it('should return false for personal segment when user is not the owner', () => {
    const segment = { id: 1, type: SegmentType.personal, owner_id: 2 }
    expect(isListableSegment({ segment, site, user })).toBe(false)
  })
})

describe(`${resolveFilters.name}`, () => {
  const segmentData: SegmentData = {
    filters: [['is', 'browser', ['Chrome']]],
    labels: {}
  }
  const segments: Array<
    Pick<SavedSegment, 'id'> & { segment_data: SegmentData }
  > = [{ id: 1, segment_data: segmentData }]

  it('should resolve segment filters to their actual filters', () => {
    const resolvedFilters = resolveFilters(
      [
        ['is', 'segment', [1]],
        ['is', 'browser', ['Firefox']]
      ],
      segments
    )
    expect(resolvedFilters).toEqual([
      ...segmentData.filters,
      ['is', 'browser', ['Firefox']]
    ])
  })

  it('should return the original filter if it is not a segment filter', () => {
    const filters: Filter[] = [['is', 'browser', ['Firefox']]]
    const resolvedFilters = resolveFilters(filters, segments)
    expect(resolvedFilters).toEqual(filters)
  })

  it('should return the original filter if the segment is not found', () => {
    const filters: Filter[] = [['is', 'segment', [2]]]
    const resolvedFilters = resolveFilters(filters, segments)
    expect(resolvedFilters).toEqual(filters)
  })

  const cases: Array<{ filters: Filter[] }> = [
    {
      filters: [
        ['is', 'segment', [1]],
        ['is', 'segment', [2]]
      ]
    },
    { filters: [['is', 'segment', [1, 2]]] }
  ]
  it.each(cases)(
    'should throw an error if more than one segment filter is applied, as in %p',
    ({ filters }) => {
      expect(() => resolveFilters(filters, segments)).toThrow(
        'Dashboard can be filtered by only one segment'
      )
    }
  )
})

describe(`${canExpandSegment.name}`, () => {
  it.each([[Role.admin], [Role.editor], [Role.owner]])(
    'allows expanding site segment if the user is logged in and in the role %p',
    (role) => {
      const user: UserContextValue = {
        loggedIn: true,
        role,
        id: 1,
        team: { identifier: null, hasConsolidatedView: false }
      }
      expect(
        canExpandSegment({
          segment: { id: 1, owner_id: 1, type: SegmentType.site },
          user
        })
      ).toBe(true)
    }
  )

  it('allows expanding site segments defined by other users', () => {
    expect(
      canExpandSegment({
        segment: { id: 1, owner_id: 222, type: SegmentType.site },
        user: {
          loggedIn: true,
          role: Role.owner,
          id: 111,
          team: { identifier: null, hasConsolidatedView: false }
        }
      })
    ).toBe(true)
  })

  it.each([
    [Role.viewer],
    [Role.billing],
    [Role.editor],
    [Role.admin],
    [Role.owner]
  ])(
    'allows expanding personal segment if it belongs to the user and the user is in role %p',
    (role) => {
      const user: UserContextValue = {
        loggedIn: true,
        role,
        id: 1,
        team: { identifier: null, hasConsolidatedView: false }
      }
      expect(
        canExpandSegment({
          segment: { id: 1, owner_id: 1, type: SegmentType.personal },
          user
        })
      ).toBe(true)
    }
  )

  it('forbids even site owners from expanding the personal segment of other users', () => {
    expect(
      canExpandSegment({
        segment: { id: 2, owner_id: 222, type: SegmentType.personal },
        user: {
          loggedIn: true,
          role: Role.owner,
          id: 111,
          team: { identifier: null, hasConsolidatedView: false }
        }
      })
    ).toBe(false)
  })

  it.each([[SegmentType.personal, SegmentType.site]])(
    'forbids public role from expanding %s segments',
    (segmentType) => {
      expect(
        canExpandSegment({
          segment: { id: 1, owner_id: 1, type: segmentType },
          user: {
            loggedIn: false,
            role: Role.public,
            id: null,
            team: { identifier: null, hasConsolidatedView: false }
          }
        })
      ).toBe(false)
    }
  )
})

describe('segment save/load round-trip', () => {
  const createTestExpression = (): FilterExpression => ({
    version: 1,
    rootGroup: {
      id: 'root-group-1',
      operator: 'AND',
      conditions: [
        {
          id: 'condition-1',
          field: 'country',
          operator: 'equals',
          value: 'US'
        },
        {
          id: 'condition-2',
          field: 'page',
          operator: 'contains',
          value: '/blog'
        }
      ]
    }
  })

  const createTestExpressionWithOR = (): FilterExpression => ({
    version: 1,
    rootGroup: {
      id: 'root-group-1',
      operator: 'OR',
      conditions: [
        {
          id: 'condition-1',
          field: 'browser',
          operator: 'equals',
          value: 'Chrome'
        },
        {
          id: 'condition-2',
          field: 'browser',
          operator: 'equals',
          value: 'Firefox'
        }
      ]
    }
  })

  it('converts FilterExpression to API filter format for saving', () => {
    const expression = createTestExpression()
    const filters = expressionToFilters(expression)

    expect(filters).toEqual([
      ['is', 'country', ['US']],
      ['contains', 'page', ['/blog']]
    ])
  })

  it('converts FilterExpression with OR operator correctly', () => {
    const expression = createTestExpressionWithOR()
    const filters = expressionToFilters(expression)

    expect(filters).toEqual([
      ['is', 'browser', ['Chrome']],
      ['is', 'browser', ['Firefox']]
    ])
  })

  it('round-trips FilterExpression through API format and back', () => {
    const originalExpression = createTestExpression()

    // Step 1: Convert to filters for API (save)
    const filtersForApi = expressionToFilters(originalExpression)

    // Step 2: Convert to API filter format
    const apiFilters = remapToApiFilters(filtersForApi)

    // Step 3: Simulate API response with labels
    const apiSegmentData = {
      filters: apiFilters,
      labels: { US: 'United States' }
    }

    // Step 4: Parse API response back to dashboard format (load)
    const parsedSegmentData = parseApiSegmentData(apiSegmentData)

    // Step 5: Verify the filters are preserved in legacy format
    expect(parsedSegmentData.filters).toEqual([
      ['is', 'country', ['US']],
      ['contains', 'page', ['/blog']]
    ])
    expect(parsedSegmentData.labels).toEqual({ US: 'United States' })
  })

  it('handles full segment save/load cycle with handleSegmentResponse', () => {
    const apiSegmentFromServer = {
      id: 1,
      name: 'US Blog Visitors',
      type: SegmentType.site,
      owner_id: 1,
      owner_name: 'Test User',
      inserted_at: '2025-01-15 10:00:00',
      updated_at: '2025-01-15 10:00:00',
      segment_data: {
        filters: [
          ['is', 'visit:country', ['US']],
          ['contains', 'event:page', ['/blog']]
        ],
        labels: { US: 'United States', '/blog': 'Blog' }
      }
    }

    const savedSegment = handleSegmentResponse(apiSegmentFromServer as never)

    // Verify the segment was parsed correctly
    expect(savedSegment.id).toBe(1)
    expect(savedSegment.name).toBe('US Blog Visitors')
    expect(savedSegment.type).toBe(SegmentType.site)
    expect(savedSegment.segment_data.filters).toEqual([
      ['is', 'country', ['US']],
      ['contains', 'page', ['/blog']]
    ])
    expect(savedSegment.segment_data.labels).toEqual({
      US: 'United States',
      '/blog': 'Blog'
    })
  })

  it('handles segment with complex nested conditions round-trip', () => {
    const nestedGroup: ConditionGroup = {
      id: 'nested-group-1',
      operator: 'OR',
      conditions: [
        createCondition('browser', 'equals', 'Chrome'),
        createCondition('browser', 'equals', 'Firefox')
      ]
    }

    const complexExpression: FilterExpression = {
      version: 1,
      rootGroup: {
        id: 'root-1',
        operator: 'AND',
        conditions: [
          createCondition('country', 'equals', 'US'),
          nestedGroup
        ] as FilterExpression['rootGroup']['conditions']
      }
    }

    const filters = expressionToFilters(complexExpression)

    // When flattening nested groups, we get all conditions
    expect(filters).toEqual([
      ['is', 'country', ['US']],
      ['is', 'browser', ['Chrome']],
      ['is', 'browser', ['Firefox']]
    ])

    // Round-trip through API format
    const apiFilters = remapToApiFilters(filters)
    const parsed = parseApiSegmentData({ filters: apiFilters, labels: {} })

    expect(parsed.filters).toEqual(filters)
  })

  it('preserves filter operator types in round-trip', () => {
    const expressionWithVariousOperators: FilterExpression = {
      version: 1,
      rootGroup: {
        id: 'root-1',
        operator: 'AND',
        conditions: [
          { id: '1', field: 'page', operator: 'equals', value: '/test' },
          { id: '2', field: 'page', operator: 'not_equals', value: '/exclude' },
          { id: '3', field: 'page', operator: 'contains', value: 'blog' },
          { id: '4', field: 'page', operator: 'not_contains', value: 'admin' },
          { id: '5', field: 'visitors', operator: 'greater_than', value: 100 },
          { id: '6', field: 'visitors', operator: 'less_than', value: 500 }
        ]
      }
    }

    const filters = expressionToFilters(expressionWithVariousOperators)
    const apiFilters = remapToApiFilters(filters)
    const parsed = parseApiSegmentData({ filters: apiFilters, labels: {} })

    // Verify all operator types are preserved
    expect(parsed.filters[0]).toEqual(['is', 'page', ['/test']])
    expect(parsed.filters[1]).toEqual(['is_not', 'page', ['/exclude']])
    expect(parsed.filters[2]).toEqual(['contains', 'page', ['blog']])
    expect(parsed.filters[3]).toEqual(['contains_not', 'page', ['admin']])
  })
})
