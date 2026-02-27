import React, { useState, useCallback, useRef } from 'react'
import { useFilterBuilder } from './FilterBuilderContext'

interface DraggableItemProps {
  id: string
  children: React.ReactNode
  groupId?: string
}

export function DraggableItem({ id, children, groupId }: DraggableItemProps) {
  const { moveItem } = useFilterBuilder()
  const [isDragging, setIsDragging] = useState(false)
  const dragRef = useRef<HTMLDivElement>(null)

  const handleDragStart = useCallback((e: React.DragEvent) => {
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', id)
    setIsDragging(true)
  }, [id])

  const handleDragEnd = useCallback(() => {
    setIsDragging(false)
  }, [])

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.dataTransfer.dropEffect = 'move'
  }, [])

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    const draggedId = e.dataTransfer.getData('text/plain')

    if (draggedId && draggedId !== id) {
      // Get the index of the drop target
      const children = dragRef.current?.parentElement?.children
      if (children) {
        const dropIndex = Array.from(children).indexOf(dragRef.current!)
        moveItem(draggedId, dropIndex, groupId)
      }
    }
  }, [id, groupId, moveItem])

  return (
    <div
      ref={dragRef}
      draggable
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
      className={`draggable-item ${isDragging ? 'draggable-item--dragging' : ''}`}
      data-item-id={id}
    >
      {children}
    </div>
  )
}

interface SortableListProps {
  children: React.ReactNode
  groupId?: string
}

export function SortableList({ children, groupId }: SortableListProps) {
  const { state, moveItem } = useFilterBuilder()
  const [dragOverIndex, setDragOverIndex] = useState<number | null>(null)

  const handleDragOver = useCallback((e: React.DragEvent, index: number) => {
    e.preventDefault()
    setDragOverIndex(index)
  }, [])

  const handleDragLeave = useCallback(() => {
    setDragOverIndex(null)
  }, [])

  const handleDrop = useCallback((e: React.DragEvent, index: number) => {
    e.preventDefault()
    const draggedId = e.dataTransfer.getData('text/plain')
    if (draggedId) {
      moveItem(draggedId, index, groupId)
    }
    setDragOverIndex(null)
  }, [groupId, moveItem])

  return (
    <div className="sortable-list" data-group-id={groupId}>
      {React.Children.map(children, (child, index) => (
        <div
          key={index}
          className={`sortable-list__item ${dragOverIndex === index ? 'sortable-list__item--drag-over' : ''}`}
          onDragOver={(e) => handleDragOver(e, index)}
          onDragLeave={handleDragLeave}
          onDrop={(e) => handleDrop(e, index)}
        >
          {child}
        </div>
      ))}
    </div>
  )
}
