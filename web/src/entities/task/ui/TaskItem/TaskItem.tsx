'use client';

import { motion } from 'framer-motion';
import { ChevronRight } from 'lucide-react';
import type { TaskItem as TaskItemType } from '@/shared/types';
import styles from './TaskItem.module.scss';

interface Props {
  task: TaskItemType;
  isLast?: boolean;
  onToggle: () => void;
  onEdit: () => void;
}

export function TaskItem({ task, isLast, onToggle, onEdit }: Props) {
  const prioColor = task.priority === 'high' ? 'var(--color-danger)'
    : task.priority === 'mid'  ? 'var(--color-warning)'
    : task.priority === 'low'  ? 'var(--color-text3)'
    : 'transparent';

  return (
    <motion.div className={`${styles.row} ${isLast ? styles.last : ''}`}
      onClick={onEdit}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, height: 0 }}
      layout>
      <button className={`${styles.check} ${task.isDone ? styles.checked : ''}`}
        onClick={e => { e.stopPropagation(); onToggle(); }} aria-label="Отметить">
        {task.isDone && <span className={styles.checkMark}>✓</span>}
      </button>
      {task.priority !== 'none' && (
        <span className={styles.prio} style={{ background: prioColor }} />
      )}
      <span className={`${styles.body} ${task.isDone ? styles.done : ''}`}>
        {task.body}
      </span>
      <ChevronRight size={15} className={styles.arrow} />
    </motion.div>
  );
}


