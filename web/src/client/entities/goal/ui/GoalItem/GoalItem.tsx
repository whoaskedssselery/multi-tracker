'use client';

import { motion } from 'framer-motion';
import type { Goal } from '@client/shared/types';
import styles from './GoalItem.module.scss';

interface Props { goal: Goal; onEdit: () => void; }

export function GoalItem({ goal, onEdit }: Props) {
  const range = Math.abs(goal.targetValue - goal.startValue);
  const pct   = range === 0 ? 1 : Math.min(1, Math.abs(goal.currentValue - goal.startValue) / range);

  return (
    <motion.div className={styles.item} onClick={onEdit}
      whileHover={{ x: 2 }} layout>
      <div className={styles.header}>
        <span className={styles.label}>{goal.label}</span>
        <span className={`${styles.vals} mono`}>
          {goal.currentValue.toFixed(1)} / {goal.targetValue.toFixed(1)} {goal.unit}
        </span>
      </div>
      <div className={styles.bar}>
        <motion.div className={styles.fill}
          initial={{ width: 0 }}
          animate={{ width: `${pct * 100}%` }}
          transition={{ duration: 0.6, ease: 'easeOut' }}
          style={{ background: pct >= 1 ? 'var(--color-success)' : 'var(--color-accent)' }} />
      </div>
      <span className={`${styles.pct} mono`}>{Math.round(pct * 100)}%</span>
    </motion.div>
  );
}

