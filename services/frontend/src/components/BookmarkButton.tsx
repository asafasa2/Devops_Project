import React, { useState, useEffect } from 'react'

interface BookmarkButtonProps {
  moduleId: number
}

const BookmarkButton: React.FC<BookmarkButtonProps> = ({ moduleId }) => {
  const [isBookmarked, setIsBookmarked] = useState(false)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    // Load bookmark status from localStorage (in a real app, this would be from an API)
    const bookmarks = JSON.parse(localStorage.getItem('bookmarks') || '[]')
    setIsBookmarked(bookmarks.includes(moduleId))
  }, [moduleId])

  const handleToggleBookmark = async () => {
    setLoading(true)
    
    try {
      // Simulate API call delay
      await new Promise(resolve => setTimeout(resolve, 300))
      
      const bookmarks = JSON.parse(localStorage.getItem('bookmarks') || '[]')
      let updatedBookmarks: number[]
      
      if (isBookmarked) {
        updatedBookmarks = bookmarks.filter((id: number) => id !== moduleId)
      } else {
        updatedBookmarks = [...bookmarks, moduleId]
      }
      
      localStorage.setItem('bookmarks', JSON.stringify(updatedBookmarks))
      setIsBookmarked(!isBookmarked)
      
    } catch (error) {
      console.error('Failed to toggle bookmark:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <button
      onClick={handleToggleBookmark}
      disabled={loading}
      className={`bookmark-button ${isBookmarked ? 'bookmarked' : ''}`}
      title={isBookmarked ? 'Remove bookmark' : 'Add bookmark'}
    >
      {loading ? (
        <span className="bookmark-loading">⏳</span>
      ) : (
        <span className="bookmark-icon">
          {isBookmarked ? '🔖' : '📑'}
        </span>
      )}
      <span className="bookmark-text">
        {isBookmarked ? 'Bookmarked' : 'Bookmark'}
      </span>
    </button>
  )
}

export default BookmarkButton