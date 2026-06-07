'use client';

import { useMemo, useState } from 'react';
import { Plus, X, Check } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import { Modal, Button } from '@/shared/ui';
import { midnight } from '@/shared/lib/utils/format';
import {
  WD_FULL, fmtDate, lastSetsString, parseDefaultSets, dayOfWeek,
} from '@/shared/lib/train';
import type { WorkoutTemplate, ExerciseTemplate } from '@/shared/types';
import styles from './WorkoutLogModal.module.scss';

interface SetRow { weight: string; reps: string }

export function WorkoutLogModal({ template, date, exercises, onClose }: {
  template: WorkoutTemplate;
  date: Date;
  exercises: ExerciseTemplate[];
  onClose: () => void;
}) {
  const setEntries = useAppStore(s => s.setEntries);
  const logSets    = useAppStore(s => s.logSets);

  // Build initial rows once: previous logged sets drive the rows, else the
  // program's configured sets (reps pre-filled), else 3 empty rows.
  const initial = useMemo(() => {
    const map: Record<number, SetRow[]> = {};
    for (const ex of exercises) {
      const parts = lastSetsString(setEntries, ex.id).split(' · ').filter(Boolean);
      const defaults = parseDefaultSets(ex.defaultSetsJson);
      const count = parts.length || defaults.length || 3;
      map[ex.id] = Array.from({ length: count }, (_, i) => {
        if (i < parts.length) {
          const m = /([\d.]+)×(\d+)/.exec(parts[i]);
          return { weight: m?.[1] ?? '', reps: m?.[2] ?? '' };
        }
        const reps = i < defaults.length ? defaults[i].reps : null;
        return { weight: '', reps: reps == null ? '' : String(reps) };
      });
    }
    return map;
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const [rows, setRows] = useState<Record<number, SetRow[]>>(initial);
  const [saved, setSaved] = useState(false);

  const dateLabel = `${WD_FULL[dayOfWeek(date) - 1]} · ${fmtDate(date)}`;

  const update = (exId: number, i: number, field: keyof SetRow, value: string) => {
    setRows(prev => {
      const next = { ...prev, [exId]: prev[exId].map((r, j) => j === i ? { ...r, [field]: value } : r) };
      return next;
    });
  };

  const addRow = (exId: number) =>
    setRows(prev => ({ ...prev, [exId]: [...prev[exId], { weight: '', reps: '' }] }));

  const removeRow = (exId: number, i: number) =>
    setRows(prev => ({ ...prev, [exId]: prev[exId].filter((_, j) => j !== i) }));

  const save = () => {
    const dateStr = midnight(date);
    for (const ex of exercises) {
      const sets = (rows[ex.id] ?? [])
        .map(r => ({
          weightKg: parseFloat(r.weight.replace(',', '.')),
          reps: parseInt(r.reps, 10),
        }))
        .filter(s => !Number.isNaN(s.weightKg) && !Number.isNaN(s.reps) && s.reps > 0);
      if (sets.length > 0) logSets(ex.id, dateStr, sets);
    }
    setSaved(true);
    setTimeout(onClose, 350);
  };

  return (
    <Modal
      open
      onClose={onClose}
      maxWidth={760}
      footer={
        <div className={styles.footer}>
          <Button variant="ghost" onClick={onClose}>Отмена</Button>
          <Button variant="primary" onClick={save} icon={saved ? <Check size={16} /> : undefined}>
            {saved ? 'Сохранено' : 'Сохранить'}
          </Button>
        </div>
      }
    >
      <div className={styles.head}>
        <h2 className={styles.title}>{template.name}</h2>
        <span className={styles.date}>{dateLabel}</span>
      </div>

      <div className={styles.list}>
        {exercises.map(ex => {
          const last = lastSetsString(setEntries, ex.id);
          return (
            <div key={ex.id} className={styles.exercise}>
              <div className={styles.exHead}>
                <span className={styles.exName}>{ex.name}</span>
                {last && <span className={styles.exLast}>{last}</span>}
              </div>
              <div className={styles.rows}>
                <div className={`${styles.row} ${styles.rowHeader}`}>
                  <span className={styles.cellIdx}>#</span>
                  <span className={styles.cellLabel}>Вес, кг</span>
                  <span className={styles.cellLabel}>Повт.</span>
                  <span className={styles.cellDel} />
                </div>
                {(rows[ex.id] ?? []).map((r, i) => (
                  <div key={i} className={styles.row}>
                    <span className={styles.cellIdx}>{i + 1}</span>
                    <input
                      className={styles.cell}
                      inputMode="decimal"
                      placeholder="0"
                      value={r.weight}
                      onChange={e => update(ex.id, i, 'weight', e.target.value)}
                    />
                    <input
                      className={styles.cell}
                      inputMode="numeric"
                      placeholder="0"
                      value={r.reps}
                      onChange={e => update(ex.id, i, 'reps', e.target.value)}
                    />
                    <button
                      className={styles.del}
                      onClick={() => removeRow(ex.id, i)}
                      aria-label="Удалить подход"
                    >
                      <X size={14} />
                    </button>
                  </div>
                ))}
                <button className={styles.addSet} onClick={() => addRow(ex.id)}>
                  <Plus size={14} /> Подход
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </Modal>
  );
}
