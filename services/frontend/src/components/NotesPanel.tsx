import React, { useState, useEffect } from 'react'

interface Note {
  id: string
  content: string
  timestamp: string
  sectionId?: string
}

interface NotesPanelProps {
  moduleId: number
}

const NotesPanel: React.FC<NotesPanelProps> = ({ moduleId }) => {
  const [notes, setNotes] = useState<Note[]>([])
  const [newNote, setNewNote] = useState('')
  const [editingNote, setEditingNote] = useState<string | null>(null)
  const [editContent, setEditContent] = useState('')

  useEffect(() => {
    // Load notes from localStorage (in a real app, this would be from an API)
    const savedNotes = localStorage.getItem(`notes-${moduleId}`)
    if (savedNotes) {
      try {
        setNotes(JSON.parse(savedNotes))
      } catch (error) {
        console.error('Failed to parse saved notes:', error)
      }
    }
  }, [moduleId])

  const saveNotes = (updatedNotes: Note[]) => {
    setNotes(updatedNotes)
    localStorage.setItem(`notes-${moduleId}`, JSON.stringify(updatedNotes))
  }

  const handleAddNote = () => {
    if (!newNote.trim()) return

    const note: Note = {
      id: Date.now().toString(),
      content: newNote.trim(),
      timestamp: new Date().toISOString()
    }

    const updatedNotes = [note, ...notes]
    saveNotes(updatedNotes)
    setNewNote('')
  }

  const handleEditNote = (noteId: string) => {
    const note = notes.find(n => n.id === noteId)
    if (note) {
      setEditingNote(noteId)
      setEditContent(note.content)
    }
  }

  const handleSaveEdit = () => {
    if (!editContent.trim() || !editingNote) return

    const updatedNotes = notes.map(note =>
      note.id === editingNote
        ? { ...note, content: editContent.trim() }
        : note
    )

    saveNotes(updatedNotes)
    setEditingNote(null)
    setEditContent('')
  }

  const handleCancelEdit = () => {
    setEditingNote(null)
    setEditContent('')
  }

  const handleDeleteNote = (noteId: string) => {
    if (window.confirm('Are you sure you want to delete this note?')) {
      const updatedNotes = notes.filter(note => note.id !== noteId)
      saveNotes(updatedNotes)
    }
  }

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp)
    return date.toLocaleString()
  }

  return (
    <div className="notes-panel">
      <div className="notes-header">
        <h3>📝 My Notes</h3>
        <span className="notes-count">{notes.length} notes</span>
      </div>

      <div className="add-note-section">
        <textarea
          value={newNote}
          onChange={(e) => setNewNote(e.target.value)}
          placeholder="Add a note about this module..."
          className="note-input"
          rows={3}
        />
        <button
          onClick={handleAddNote}
          disabled={!newNote.trim()}
          className="add-note-button"
        >
          Add Note
        </button>
      </div>

      <div className="notes-list">
        {notes.length === 0 ? (
          <div className="no-notes">
            <p>No notes yet. Add your first note above!</p>
          </div>
        ) : (
          notes.map((note) => (
            <div key={note.id} className="note-item">
              {editingNote === note.id ? (
                <div className="edit-note">
                  <textarea
                    value={editContent}
                    onChange={(e) => setEditContent(e.target.value)}
                    className="edit-note-input"
                    rows={3}
                  />
                  <div className="edit-actions">
                    <button onClick={handleSaveEdit} className="save-button">
                      Save
                    </button>
                    <button onClick={handleCancelEdit} className="cancel-button">
                      Cancel
                    </button>
                  </div>
                </div>
              ) : (
                <>
                  <div className="note-content">
                    {note.content}
                  </div>
                  <div className="note-meta">
                    <span className="note-timestamp">
                      {formatTimestamp(note.timestamp)}
                    </span>
                    <div className="note-actions">
                      <button
                        onClick={() => handleEditNote(note.id)}
                        className="edit-note-button"
                        title="Edit note"
                      >
                        ✏️
                      </button>
                      <button
                        onClick={() => handleDeleteNote(note.id)}
                        className="delete-note-button"
                        title="Delete note"
                      >
                        🗑️
                      </button>
                    </div>
                  </div>
                </>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}

export default NotesPanel