'use client';

import { useRef, useCallback, useEffect } from 'react';
import { Pin, PinOff, Trash2 } from 'lucide-react';
import { useAppStore } from '@shared/store';
import { formatDate } from '@shared/lib/utils/format';
import type { NoteItem } from '@shared/types';
import styles from './NoteEditor.module.scss';

interface Props {
  note: NoteItem;
  onDelete: () => void;
  onPinToggle: () => void;
}

export function NoteEditor({ note, onDelete, onPinToggle }: Props) {
  const updateNote = useAppStore(s => s.updateNote);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const flush = useCallback((title: string, body: string) => {
    updateNote(note.id, { title: title.trim() || 'Без названия', body });
  }, [note.id, updateNote]);

  const schedule = useCallback((title: string, body: string) => {
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => flush(title, body), 500);
  }, [flush]);

  useEffect(() => () => { if (timerRef.current) clearTimeout(timerRef.current); }, []);

  const words = note.body.trim() ? note.body.trim().split(/\s+/).length : 0;

  return (
    <div className={styles.editor}>
      <div className={styles.toolbar}>
        <span className={`${styles.meta} mono`}>{formatDate(note.updatedAt)} · {words} сл</span>
        <div className={styles.actions}>
          <button className={`${styles.action} ${note.isPinned ? styles.pinned : ''}`}
            onClick={onPinToggle} title={note.isPinned ? 'Открепить' : 'Закрепить'}>
            {note.isPinned ? <Pin size={16} /> : <PinOff size={16} />}
          </button>
          <button className={`${styles.action} ${styles.del}`}
            onClick={() => { if (confirm('Удалить заметку?')) onDelete(); }}>
            <Trash2 size={16} />
          </button>
        </div>
      </div>

      <div className={styles.titleWrap}>
        <textarea key={`t-${note.id}`} className={styles.titleInput}
          defaultValue={note.title === 'Без названия' ? '' : note.title}
          placeholder="Без названия" rows={1}
          onChange={e => {
            e.target.style.height = 'auto';
            e.target.style.height = `${e.target.scrollHeight}px`;
            schedule(e.target.value, note.body);
          }}
          onBlur={e => flush(e.target.value, note.body)} />
      </div>

      <div className={styles.bodyWrap}>
        <textarea key={`b-${note.id}`} className={styles.bodyInput}
          defaultValue={note.body} placeholder="Начни писать..."
          onChange={e => schedule(note.title, e.target.value)}
          onBlur={e => flush(note.title, e.target.value)} />
      </div>
    </div>
  );
}
