'use client';

import { useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Delete, Check } from 'lucide-react';
import { useAppStore } from '@/store/app-store';
import s from './WeightRecorder.module.scss';

const NUMPAD = [
  ['7', '8', '9', 'del'],
  ['4', '5', '6', '+0.5'],
  ['1', '2', '3', '-0.5'],
  ['.', '0',  '',  'ok'],
];

export function WeightRecorder() {
  const addEntry = useAppStore(st => st.addWeightEntry);
  const entries  = useAppStore(st => st.weightEntries);
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState('0');

  const last = entries[0];

  const key = useCallback((k: string) => {
    setDraft(prev => {
      switch (k) {
        case 'del':  return prev.length > 1 ? prev.slice(0, -1) : '0';
        case '+0.5': return String(((parseFloat(prev) || 0) + 0.5).toFixed(1));
        case '-0.5': return String(Math.max(0, (parseFloat(prev) || 0) - 0.5).toFixed(1));
        case '.':    return prev.includes('.') ? prev : prev + '.';
        default:     return prev === '0' ? k : prev + k;
      }
    });
  }, []);

  const commit = () => {
    const v = parseFloat(draft.replace(',', '.'));
    if (v > 0 && v < 500) {
      addEntry(v);
      setOpen(false);
      setDraft('0');
    }
  };

  const open_ = () => {
    setDraft(last ? last.value.toFixed(1) : '0');
    setOpen(true);
  };

  return (
    <AnimatePresence mode="wait">
      {!open ? (
        <motion.button
          key="trigger"
          className={s.trigger}
          onClick={open_}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          whileHover={{ scale: 1.01 }}
          whileTap={{ scale: 0.99 }}
        >
          <div>
            <p className={s.triggerLabel}>ЗАПИСАТЬ ВЕС</p>
            <p className={s.triggerValue}>
              <span className="mono">{last ? last.value.toFixed(1) : '—'}</span>
              {last && <span className={s.triggerUnit}> кг</span>}
            </p>
          </div>
          <span className={s.triggerArrow}>→</span>
        </motion.button>
      ) : (
        <motion.div
          key="recorder"
          className={s.recorder}
          initial={{ opacity: 0, scale: 0.97 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.97 }}
          transition={{ type: 'spring', stiffness: 500, damping: 40 }}
        >
          {/* Display */}
          <div className={s.display}>
            <span className={`${s.displayVal} mono`}>{draft}</span>
            <span className={s.displayUnit}>кг</span>
          </div>

          {/* Numpad */}
          <div className={s.numpad}>
            {NUMPAD.map((row, ri) => (
              <div key={ri} className={s.row}>
                {row.map((k, ki) => {
                  if (k === '') return <div key={ki} className={s.key} />;
                  const isOk  = k === 'ok';
                  const isDel = k === 'del';
                  return (
                    <motion.button
                      key={ki}
                      className={`${s.key} ${isOk ? s.keyOk : isDel ? s.keyAlt : s.keyNum} ${k === '+0.5' || k === '-0.5' ? s.keyAlt : ''}`}
                      onClick={() => isOk ? commit() : key(k)}
                      whileTap={{ scale: 0.93 }}
                    >
                      {isDel ? <Delete size={18} /> : isOk ? <Check size={20} /> : k}
                    </motion.button>
                  );
                })}
              </div>
            ))}
          </div>

          <button className={s.cancel} onClick={() => setOpen(false)}>Отмена</button>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
