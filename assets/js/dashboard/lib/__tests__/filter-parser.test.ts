import {
  filterTreeToBackend,
  backendToFilterTree,
  FilterTree,
  ConditionGroup,
  FilterCondition,
  createEmptyFilterTree,
  createEmptyCondition,
  validateFilterTree
} from '../filter-parser'

describe('filterTreeToBackend', () => {
  it('serializes a single condition to backend format', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'visit:country',
            operator: 'is',
            value: ['US']
          }
        ],
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = filterTreeToBackend(tree)

    expect(result.filters).toEqual(['is', 'visit:country', ['US']])
    expect(result.labels).toEqual({})
  })

  it('serializes multiple conditions with AND connector', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'visit:country',
            operator: 'is',
            value: ['US']
          },
          {
            id: 'cond-2',
            dimension: 'visit:device',
            operator: 'is',
            value: ['Mobile']
          }
        ],
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = filterTreeToBackend(tree)

    expect(result.filters).toEqual([
      'and',
      [
        ['is', 'visit:country', ['US']],
        ['is', 'visit:device', ['Mobile']]
      ]
    ])
  })

  it('serializes multiple conditions with OR connector', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'or',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'visit:country',
            operator: 'is',
            value: ['US']
          },
          {
            id: 'cond-2',
            dimension: 'visit:country',
            operator: 'is',
            value: ['UK']
          }
        ],
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = filterTreeToBackend(tree)

    expect(result.filters).toEqual([
      'or',
      [
        ['is', 'visit:country', ['US']],
        ['is', 'visit:country', ['UK']]
      ]
    ])
  })

  it('serializes nested condition groups', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'or',
        conditions: [],
        children: [
          {
            id: 'group-1',
            connector: 'and',
            conditions: [
              {
                id: 'cond-1',
                dimension: 'visit:country',
                operator: 'is',
                value: ['US']
              },
              {
                id: 'cond-2',
                dimension: 'visit:device',
                operator: 'is',
                value: ['Mobile']
              }
            ],
            children: [],
            isRoot: false
          },
          {
            id: 'group-2',
            connector: 'and',
            conditions: [
              {
                id: 'cond-3',
                dimension: 'visit:country',
                operator: 'is',
                value: ['UK']
              }
            ],
            children: [],
            isRoot: false
          }
        ],
        isRoot: true
      },
      labels: {}
    }

    const result = filterTreeToBackend(tree)

    expect(result.filters).toEqual([
      'or',
      [
        ['and', [['is', 'visit:country', ['US']], ['is', 'visit:device', ['Mobile']]]],
        ['is', 'visit:country', ['UK']]
      ]
    ])
  })

  it('includes labels in serialization', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'visit:country',
            operator: 'is',
            value: ['US']
          }
        ],
        children: [],
        isRoot: true
      },
      labels: { 'cond-1': 'United States' }
    }

    const result = filterTreeToBackend(tree)

    expect(result.labels).toEqual({ 'cond-1': 'United States' })
  })

  it('serializes condition with modifier', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'event:name',
            operator: 'contains',
            value: ['signup'],
            modifier: { case_sensitive: false }
          }
        ],
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = filterTreeToBackend(tree)

    expect(result.filters).toEqual([
      'contains',
      'event:name',
      ['signup'],
      { case_sensitive: false }
    ])
  })

  it('handles single condition at root level (unwraps)', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'visit:country',
            operator: 'is',
            value: ['US']
          }
        ],
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = filterTreeToBackend(tree)

    // Single condition at root should be returned directly, not wrapped
    expect(result.filters).toEqual(['is', 'visit:country', ['US']])
  })
})

describe('backendToFilterTree', () => {
  it('deserializes a single condition from backend format', () => {
    const data = {
      filters: ['is', 'visit:country', ['US']],
      labels: {}
    }

    const result = backendToFilterTree(data)

    expect(result.rootGroup.conditions).toHaveLength(1)
    expect(result.rootGroup.conditions[0].dimension).toBe('visit:country')
    expect(result.rootGroup.conditions[0].operator).toBe('is')
    expect(result.rootGroup.conditions[0].value).toEqual(['US'])
    expect(result.labels).toEqual({})
  })

  it('deserializes multiple conditions with AND connector', () => {
    const data = {
      filters: [
        'and',
        [
          ['is', 'visit:country', ['US']],
          ['is', 'visit:device', ['Mobile']]
        ]
      ],
      labels: {}
    }

    const result = backendToFilterTree(data)

    expect(result.rootGroup.connector).toBe('and')
    expect(result.rootGroup.conditions).toHaveLength(2)
    expect(result.rootGroup.conditions[0].dimension).toBe('visit:country')
    expect(result.rootGroup.conditions[1].dimension).toBe('visit:device')
  })

  it('deserializes multiple conditions with OR connector', () => {
    const data = {
      filters: [
        'or',
        [
          ['is', 'visit:country', ['US']],
          ['is', 'visit:country', ['UK']]
        ]
      ],
      labels: {}
    }

    const result = backendToFilterTree(data)

    expect(result.rootGroup.connector).toBe('or')
    expect(result.rootGroup.conditions).toHaveLength(2)
  })

  it('deserializes nested condition groups', () => {
    const data = {
      filters: [
        'or',
        [
          ['and', [['is', 'visit:country', ['US']], ['is', 'visit:device', ['Mobile']]]],
          ['is', 'visit:country', ['UK']]
        ]
      ],
      labels: {}
    }

    const result = backendToFilterTree(data)

    expect(result.rootGroup.connector).toBe('or')
    // The second item is a single condition (not wrapped in a group), so it becomes a condition, not a child
    expect(result.rootGroup.children).toHaveLength(1)
    expect(result.rootGroup.conditions).toHaveLength(1)
    expect(result.rootGroup.children[0].connector).toBe('and')
    expect(result.rootGroup.children[0].conditions).toHaveLength(2)
    expect(result.rootGroup.conditions[0].dimension).toBe('visit:country')
    expect(result.rootGroup.conditions[0].value).toEqual(['UK'])
  })

  it('includes labels in deserialization', () => {
    const data = {
      filters: ['is', 'visit:country', ['US']],
      labels: { 'cond-1': 'United States' }
    }

    const result = backendToFilterTree(data)

    expect(result.labels).toEqual({ 'cond-1': 'United States' })
  })

  it('handles empty filters', () => {
    const data = {
      filters: [],
      labels: {}
    }

    const result = backendToFilterTree(data)

    expect(result.rootGroup.conditions).toHaveLength(0)
    expect(result.rootGroup.children).toHaveLength(0)
  })

  it('handles condition with modifier', () => {
    const data = {
      filters: ['contains', 'event:name', ['signup'], { case_sensitive: false }],
      labels: {}
    }

    const result = backendToFilterTree(data)

    expect(result.rootGroup.conditions[0].operator).toBe('contains')
    expect(result.rootGroup.conditions[0].modifier).toEqual({ case_sensitive: false })
  })

  it('handles list of conditions without connector (implicit AND)', () => {
    const data = {
      filters: [
        ['is', 'visit:country', ['US']],
        ['is', 'visit:device', ['Mobile']]
      ],
      labels: {}
    }

    const result = backendToFilterTree(data)

    expect(result.rootGroup.connector).toBe('and')
    expect(result.rootGroup.conditions).toHaveLength(2)
  })
})

describe('filterTreeToBackend and backendToFilterTree roundtrip', () => {
  it('maintains data integrity for single condition', () => {
    const originalTree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'visit:country',
            operator: 'is',
            value: ['US']
          }
        ],
        children: [],
        isRoot: true
      },
      labels: { 'cond-1': 'United States' }
    }

    const backend = filterTreeToBackend(originalTree)
    const restored = backendToFilterTree(backend)

    expect(restored.rootGroup.conditions).toHaveLength(1)
    expect(restored.rootGroup.conditions[0].dimension).toBe('visit:country')
    expect(restored.rootGroup.conditions[0].operator).toBe('is')
    expect(restored.rootGroup.conditions[0].value).toEqual(['US'])
  })

  it('maintains data integrity for nested groups', () => {
    // Use two children to properly preserve the outer connector
    const originalTree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'or',
        conditions: [],
        children: [
          {
            id: 'group-1',
            connector: 'and',
            conditions: [
              {
                id: 'cond-1',
                dimension: 'visit:country',
                operator: 'is',
                value: ['US']
              },
              {
                id: 'cond-2',
                dimension: 'visit:device',
                operator: 'is',
                value: ['Mobile']
              }
            ],
            children: [],
            isRoot: false
          },
          {
            id: 'group-2',
            connector: 'and',
            conditions: [
              {
                id: 'cond-3',
                dimension: 'visit:country',
                operator: 'is',
                value: ['UK']
              }
            ],
            children: [],
            isRoot: false
          }
        ],
        isRoot: true
      },
      labels: {}
    }

    const backend = filterTreeToBackend(originalTree)
    const restored = backendToFilterTree(backend)

    expect(restored.rootGroup.connector).toBe('or')
    expect(restored.rootGroup.children).toHaveLength(1)
    expect(restored.rootGroup.conditions).toHaveLength(1)
    expect(restored.rootGroup.children[0].connector).toBe('and')
    expect(restored.rootGroup.children[0].conditions).toHaveLength(2)
    expect(restored.rootGroup.conditions[0].value).toEqual(['UK'])
  })
})

describe('validateFilterTree', () => {
  it('validates a valid filter tree', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'visit:country',
            operator: 'is',
            value: ['US']
          }
        ],
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = validateFilterTree(tree)

    expect(result.valid).toBe(true)
    expect(result.errors).toHaveLength(0)
  })

  it('rejects more than 20 conditions', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: Array.from({ length: 21 }, (_, i) => ({
          id: `cond-${i}`,
          dimension: 'visit:country',
          operator: 'is' as const,
          value: ['US']
        })),
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = validateFilterTree(tree)

    expect(result.valid).toBe(false)
    expect(result.errors).toContain('Maximum 20 conditions allowed')
  })

  it('rejects more than 3 levels of nesting', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [],
        children: [
          {
            id: 'level-1',
            connector: 'and',
            conditions: [],
            children: [
              {
                id: 'level-2',
                connector: 'and',
                conditions: [],
                children: [
                  {
                    id: 'level-3',
                    connector: 'and',
                    conditions: [
                      {
                        id: 'cond-1',
                        dimension: 'visit:country',
                        operator: 'is',
                        value: ['US']
                      }
                    ],
                    children: [],
                    isRoot: false
                  }
                ],
                isRoot: false
              }
            ],
            isRoot: false
          }
        ],
        isRoot: true
      },
      labels: {}
    }

    const result = validateFilterTree(tree)

    expect(result.valid).toBe(false)
    expect(result.errors).toContain('Maximum 3 levels of nesting allowed')
  })

  it('rejects condition missing dimension', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: '',
            operator: 'is',
            value: ['US']
          }
        ],
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = validateFilterTree(tree)

    expect(result.valid).toBe(false)
    expect(result.errors).toContain('Condition missing dimension')
  })

  it('rejects condition missing value', () => {
    const tree: FilterTree = {
      rootGroup: {
        id: 'root',
        connector: 'and',
        conditions: [
          {
            id: 'cond-1',
            dimension: 'visit:country',
            operator: 'is',
            value: []
          }
        ],
        children: [],
        isRoot: true
      },
      labels: {}
    }

    const result = validateFilterTree(tree)

    expect(result.valid).toBe(false)
    expect(result.errors).toContain('Condition missing value')
  })
})
