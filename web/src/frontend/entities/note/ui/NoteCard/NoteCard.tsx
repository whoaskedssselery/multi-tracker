'use client';

import { motion } from 'framer-motion';
import { Pin, PinOff, Trash2 } from 'lucide-react';
import type { NoteItem } from '@frontend/shared/types';
import styles from './NoteCard.module.scss';

interface Props {
  note: NoteItem;
  selected: boolean;
  onSelect: () => void;
  onPin: () => void;
  onDelete: () => void;
}

export function NoteCard({ note, selected, onSelect, onPin, onDelete }: Props) {
  const preview = note.body.replace(/\n/g, ' ').trim() || 'Нет текста';

  return (
    <motion.div
      className={`${styles.card} ${selected ? styles.active : ''}`}
      onClick={onSelect}
      whileHover={{ x: selected ? 0 : 2 }}
      layout
    >
      <div className={styles.main}>
        <p className={styles.title}>{note.title || 'Без названия'}</p>
        <p className={styles.preview}>{preview}</p>
      </div>
      <div className={styles.actions}>
        <button className={styles.action}
          onClick={e => { e.stopPropagation(); onPin(); }}
          title={note.isPinned ? 'Открепить' : 'Закрепить'}>
          {note.isPinned ? <PinOff size={13} /> : <Pin size={13} />}
        </button>
        <button className={`${styles.action} ${styles.danger}`}
          onClick={e => { e.stopPropagation(); onDelete(); }}
          title="Удалить">
          <Trash2 size={13} />
        </button>
      </div>
    </motion.div>
  );
}


