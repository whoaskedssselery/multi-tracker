'use client';

import { useRef, useCallback, useEffect } from 'react';
import { Pin, PinOff, Trash2 } from 'lucide-react';
import { useAppStore } from '@/store/app-store';
import { formatDate } from '@/lib/utils/format';
import type { NoteItem } from '@/types';
import s from './NoteEditor.module.scss';

interface Props {
  note: NoteItem;
  onDelete: () => void;
  onPinToggle: () => void;
}

export function NoteEditor({ note, onDelete, onPinToggle }: Props) {
  const updateNote = useAppStore(st => st.updateNote);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const flush = useCallback((title: string, body: string) => {
    updateNote(note.id, {
      title: title.trim() || 'Без названия',
      body,
    });
  }, [note.id, updateNote]);

  const schedule = useCallback((title: string, body: string) => {
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => flush(title, body), 500);
  }, [flush]);

  // Save on unmount
  useEffect(() => {
    return () => { if (timerRef.current) clearTimeout(timerRef.current); };
  }, []);

  const wordCount = note.body.trim()
    ? note.body.trim().split(/\s+/).length
    : 0;

  return (
    <div className={s.editor}>
      {/* Toolbar */}
      <div className={s.toolbar}>
        <span className={s.meta}>
          {formatDate(note.updatedAt)} · {wordCount} сл
        </span>
        <div className={s.actions}>
          <button
            className={`${s.action} ${note.isPinned ? s.actionActive : ''}`}
            onClick={onPinToggle}
            title={note.isPinned ? 'Открепить' : 'Закрепить'}
          >
            {note.isPinned ? <Pin size={16} /> : <PinOff size={16} />}
          </button>
          <button
            className={`${s.action} ${s.actionDel}`}
            onClick={() => {
              if (confirm('Удалить заметку?')) onDelete();
            }}
            title="Удалить"
          >
            <Trash2 size={16} />
          </button>
        </div>
      </div>

      {/* Title */}
      <div className={s.titleWrap}>
        <textarea
          key={`title-${note.id}`}
          className={s.titleInput}
          defaultValue={note.title === 'Без названия' ? '' : note.title}
          placeholder="Без названия"
          rows={1}
          onChange={e => {
            e.target.style.height = 'auto';
            e.target.style.height = e.target.scrollHeight + 'px';
            schedule(e.target.value, note.body);
          }}
          onBlur={e => flush(e.target.value, note.body)}
        />
      </div>

      {/* Body */}
      <div className={s.bodyWrap}>
        <textarea
          key={`body-${note.id}`}
          className={s.bodyInput}
          defaultValue={note.body}
          placeholder="Начни писать..."
          onChange={e => schedule(note.title, e.target.value)}
          onBlur={e => flush(note.title, e.target.value)}
        />
      </div>
    </div>
  );
}
