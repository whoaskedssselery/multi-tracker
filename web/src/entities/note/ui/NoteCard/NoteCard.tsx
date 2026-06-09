'use client';

import { Pin, PinOff, Trash2 } from 'lucide-react';
import type { NoteItem } from '@/shared/types';
import styles from './NoteCard.module.scss';

interface Props {
  note: NoteItem;
  selected: boolean;
  onSelect: () => void;
  onPin: () => void;
  onDelete: () => void;
}

export function NoteCard({ note, selected, onSelect, onPin, onDelete }: Props) {
  const preview = note.body.replace(/\n+/g, ' ').trim();

  return (
    <div
      className={`${styles.card} ${selected ? styles.active : ''}`}
      onClick={onSelect}
    >
      <div className={styles.head}>
        <p className={styles.title}>{note.title || 'Без названия'}</p>
        <div className={styles.actions}>
          <button className={styles.action}
            onClick={e => { e.stopPropagation(); onPin(); }}
            title={note.isPinned ? 'Открепить' : 'Закрепить'}>
            {note.isPinned ? <PinOff size={14} /> : <Pin size={14} />}
          </button>
          <button className={`${styles.action} ${styles.danger}`}
            onClick={e => { e.stopPropagation(); onDelete(); }}
            title="Удалить">
            <Trash2 size={14} />
          </button>
        </div>
      </div>
      <p className={styles.preview}>{preview || 'Нет текста'}</p>
    </div>
  );
}
