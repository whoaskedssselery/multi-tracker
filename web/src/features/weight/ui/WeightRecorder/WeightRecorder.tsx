'use client';

import { useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Delete, Check } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import styles from './WeightRecorder.module.scss';

const NUMPAD = [
  ['7', '8', '9', 'del'],
  ['4', '5', '6', '+0.5'],
  ['1', '2', '3', '-0.5'],
  ['.', '0',  '',  'ok'],
];

export function WeightRecorder() {
  const addEntry = useAppStore(s => s.addWeightEntry);
  const last     = useAppStore(s => s.weightEntries[0]);
  const [open,  setOpen]  = useState(false);
  const [draft, setDraft] = useState('0');

  const press = useCallback((k: string) => {
    setDraft(prev => {
      switch (k) {
        case 'del':  return prev.length > 1 ? prev.slice(0, -1) : '0';
        case '+0.5': return ((parseFloat(prev) || 0) + 0.5).toFixed(1);
        case '-0.5': return Math.max(0, (parseFloat(prev) || 0) - 0.5).toFixed(1);
        case '.':    return prev.includes('.') ? prev : prev + '.';
        default:     return prev === '0' ? k : prev + k;
      }
    });
  }, []);

  const commit = () => {
    const v = parseFloat(draft.replace(',', '.'));
    if (v > 0 && v < 500) { addEntry(v); setOpen(false); setDraft('0'); }
  };

  const open_ = () => { setDraft(last ? last.value.toFixed(1) : '0'); setOpen(true); };

  return (
    <AnimatePresence mode="wait">
      {!open ? (
        <motion.button key="trigger" className={styles.trigger}
          onClick={open_} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
          whileHover={{ scale: 1.01 }} whileTap={{ scale: 0.99 }}>
          <div>
            <p className={styles.triggerLabel}>ЗАПИСАТЬ ВЕС</p>
            <p className={styles.triggerVal}>
              <span className="mono">{last ? last.value.toFixed(1) : '—'}</span>
              {last && <span className={styles.triggerUnit}> кг</span>}
            </p>
          </div>
          <span className={styles.arrow}>→</span>
        </motion.button>
      ) : (
        <motion.div key="pad" className={styles.pad}
          initial={{ opacity: 0, scale: 0.97 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.97 }}
          transition={{ type: 'spring', stiffness: 500, damping: 40 }}>
          <div className={styles.display}>
            <span className={`${styles.displayVal} mono`}>{draft}</span>
            <span className={styles.displayUnit}>кг</span>
          </div>
          <div className={styles.numpad}>
            {NUMPAD.map((row, ri) => (
              <div key={ri} className={styles.numRow}>
                {row.map((k, ki) => {
                  if (!k) return <div key={ki} className={styles.key} />;
                  const isOk = k === 'ok', isDel = k === 'del';
                  return (
                    <motion.button key={ki}
                      className={`${styles.key} ${isOk ? styles.keyOk : isDel || k.includes('0.5') ? styles.keyAlt : styles.keyNum}`}
                      onClick={() => isOk ? commit() : press(k)} whileTap={{ scale: 0.93 }}>
                      {isDel ? <Delete size={18} /> : isOk ? <Check size={20} /> : k}
                    </motion.button>
                  );
                })}
              </div>
            ))}
          </div>
          <button className={styles.cancel} onClick={() => setOpen(false)}>Отмена</button>
        </motion.div>
      )}
    </AnimatePresence>
  );
}


