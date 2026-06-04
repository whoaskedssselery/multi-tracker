'use client';

import { useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Search, X, Pin, PinOff, Trash2, ArrowLeft } from 'lucide-react';
import { useAppStore } from '@/store/app-store';
import { NoteEditor } from './NoteEditor';
import type { NoteItem } from '@/types';
import { formatDate } from '@/lib/utils/format';
import s from './NotesPane.module.scss';

export function NotesPane() {
  const notes      = useAppStore(st => st.notes);
  const addNote    = useAppStore(st => st.addNote);
  const deleteNote = useAppStore(st => st.deleteNote);
  const updateNote = useAppStore(st => st.updateNote);

  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [search, setSearch] = useState('');

  const selected = notes.find(n => n.id === selectedId) ?? null;

  const filtered = search
    ? notes.filter(n =>
        n.title.toLowerCase().includes(search.toLowerCase()) ||
        n.body.toLowerCase().includes(search.toLowerCase()),
      )
    : notes;

  const pinned  = filtered.filter(n => n.isPinned);
  const regular = filtered.filter(n => !n.isPinned);

  const newNote = () => {
    const id = addNote('Без названия', '');
    setSelectedId(id);
  };

  const handleDelete = (id: number) => {
    deleteNote(id);
    if (selectedId === id) setSelectedId(null);
  };

  // Mobile: show editor full-screen when note selected
  const isMobileEditor = selected !== null;

  return (
    <div className={s.root}>
      {/* Sidebar */}
      <div className={`${s.sidebar} ${isMobileEditor ? s.sidebarHidden : ''}`}>
        {/* Search */}
        <div className={s.searchBar}>
          <div className={s.searchWrap}>
            <Search size={14} className={s.searchIcon} />
            <input
              className={s.search}
              placeholder="Поиск по заметкам..."
              value={search}
              onChange={e => setSearch(e.target.value)}
            />
            {search && (
              <button className={s.clearSearch} onClick={() => setSearch('')}>
                <X size={12} />
              </button>
            )}
          </div>
          <button className={s.newBtn} onClick={newNote} title="Новая заметка">
            <Plus size={18} />
          </button>
        </div>

        {/* Notes list */}
        <div className={s.list}>
          {filtered.length === 0 && (
            <div className={s.empty}>
              {search ? 'Ничего не найдено' : 'Нет заметок'}
            </div>
          )}

          {pinned.length > 0 && (
            <NoteSection
              label="ЗАКРЕПЛЁННЫЕ"
              notes={pinned}
              selectedId={selectedId}
              onSelect={setSelectedId}
              onPin={id => updateNote(id, { isPinned: !notes.find(n => n.id === id)?.isPinned })}
              onDelete={handleDelete}
            />
          )}

          {regular.length > 0 && (
            <NoteSection
              label={pinned.length > 0 ? 'ОСТАЛЬНЫЕ' : undefined}
              notes={regular}
              selectedId={selectedId}
              onSelect={setSelectedId}
              onPin={id => updateNote(id, { isPinned: !notes.find(n => n.id === id)?.isPinned })}
              onDelete={handleDelete}
            />
          )}
        </div>
      </div>

      {/* Editor / Empty state */}
      <div className={`${s.editor} ${!isMobileEditor ? s.editorEmpty : ''}`}>
        <AnimatePresence mode="wait">
          {selected ? (
            <motion.div
              key={selected.id}
              className={s.editorInner}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.15 }}
            >
              {/* Mobile back button */}
              <div className={s.mobileBack}>
                <button className={s.backBtn} onClick={() => setSelectedId(null)}>
                  <ArrowLeft size={18} />
                  <span>Заметки</span>
                </button>
              </div>
              <NoteEditor
                note={selected}
                onDelete={() => handleDelete(selected.id)}
                onPinToggle={() => updateNote(selected.id, { isPinned: !selected.isPinned })}
              />
            </motion.div>
          ) : (
            <motion.div
              key="empty"
              className={s.emptyState}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
            >
              <p className={s.emptyTitle}>
                {notes.length === 0 ? 'Здесь будут твои заметки' : 'Выбери заметку слева'}
              </p>
              {notes.length === 0 && (
                <p className={s.emptySub}>Нажми «+» чтобы создать первую</p>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

function NoteSection({ label, notes, selectedId, onSelect, onPin, onDelete }: {
  label?: string;
  notes: NoteItem[];
  selectedId: number | null;
  onSelect: (id: number) => void;
  onPin: (id: number) => void;
  onDelete: (id: number) => void;
}) {
  return (
    <div className={s.section}>
      {label && <p className={s.sectionLabel}>{label}</p>}
      {notes.map(note => (
        <NoteCard
          key={note.id}
          note={note}
          selected={note.id === selectedId}
          onSelect={() => onSelect(note.id)}
          onPin={() => onPin(note.id)}
          onDelete={() => onDelete(note.id)}
        />
      ))}
    </div>
  );
}

function NoteCard({ note, selected, onSelect, onPin, onDelete }: {
  note: NoteItem;
  selected: boolean;
  onSelect: () => void;
  onPin: () => void;
  onDelete: () => void;
}) {
  const preview = note.body.replace(/\n/g, ' ').trim() || 'Нет текста';

  return (
    <motion.div
      className={`${s.noteCard} ${selected ? s.noteCardActive : ''}`}
      onClick={onSelect}
      whileHover={{ x: selected ? 0 : 2 }}
      layout
    >
      <div className={s.noteMain}>
        <p className={s.noteTitle}>{note.title || 'Без названия'}</p>
        <p className={s.notePreview}>{preview}</p>
      </div>
      <div className={s.noteActions}>
        <button
          className={s.noteAction}
          onClick={e => { e.stopPropagation(); onPin(); }}
          title={note.isPinned ? 'Открепить' : 'Закрепить'}
        >
          {note.isPinned ? <PinOff size={13} /> : <Pin size={13} />}
        </button>
        <button
          className={`${s.noteAction} ${s.noteActionDel}`}
          onClick={e => { e.stopPropagation(); onDelete(); }}
          title="Удалить"
        >
          <Trash2 size={13} />
        </button>
      </div>
    </motion.div>
  );
}
