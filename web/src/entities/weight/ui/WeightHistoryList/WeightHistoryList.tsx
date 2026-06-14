'use client';

import { motion } from 'framer-motion';
import { X } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import { formatDateShort } from '@/shared/lib/utils/format';
import type { WeightEntry } from '@/shared/types';
import styles from './WeightHistoryList.module.scss';

export function WeightHistoryList() {
  // Select the stable array reference; slice in render. Slicing inside the
  // selector returns a fresh array every call → Zustand sees a changed
  // snapshot every render → "getSnapshot should be cached" infinite loop.
  const all = useAppStore(s => s.weightEntries);
  const deleteEntry = useAppStore(s => s.deleteWeightEntry);
  const entries = all.slice(0, 8);
  if (!entries.length) return null;

  return (
    <div className={styles.card}>
      <h3 className={styles.title}>ИСТОРИЯ</h3>
      {entries.map((e, i) => {
        const prev = entries[i + 1];
        const delta = prev ? e.value - prev.value : null;
        return (
          <motion.div key={e.id} className={styles.row}
            initial={{ opacity: 0 }} animate={{ opacity: 1 }}
            transition={{ delay: i * 0.03 }}>
            <span className={`${styles.date} mono`}>{formatDateShort(e.date)}</span>
            <span className={`${styles.val} mono`}>{e.value.toFixed(1)}</span>
            {delta !== null && (
              <span className={`${styles.delta} ${delta > 0 ? styles.up : delta < 0 ? styles.down : ''}`}>
                {delta > 0 ? '+' : ''}{delta.toFixed(1)}
              </span>
            )}
            <button className={styles.del} onClick={() => deleteEntry(e.id)} aria-label="Удалить">
              <X size={14} />
            </button>
          </motion.div>
        );
      })}
    </div>
  );
}


