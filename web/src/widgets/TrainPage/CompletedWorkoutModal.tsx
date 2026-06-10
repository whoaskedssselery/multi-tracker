'use client';

import { useMemo } from 'react';
import { Pencil, Check } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import { Modal, Button } from '@/shared/ui';
import { WD_FULL, fmtDate, dayOfWeek, setsOnDay, fmtW } from '@/shared/lib/train';
import { dayKeyOf } from '@/shared/lib/utils/format';
import type { WorkoutTemplate, ExerciseTemplate } from '@/shared/types';
import styles from './CompletedWorkoutModal.module.scss';

export function CompletedWorkoutModal({ template, date, exercises, onClose, onEdit }: {
  template: WorkoutTemplate;
  date: Date;
  exercises: ExerciseTemplate[];
  onClose: () => void;
  onEdit: () => void;
}) {
  const setEntries = useAppStore(s => s.setEntries);
  const key = dayKeyOf(date);
  const dateLabel = `${WD_FULL[dayOfWeek(date) - 1]} · ${fmtDate(date)}`;

  const rows = useMemo(() => exercises.map(ex => ({
    ex, sets: setsOnDay(setEntries, ex.id, key),
  })), [exercises, setEntries, key]);

  const totalSets = rows.reduce((n, r) => n + r.sets.length, 0);
  const totalVolume = rows.reduce(
    (v, r) => v + r.sets.reduce((s, x) => s + x.weightKg * x.reps, 0), 0,
  );

  return (
    <Modal
      open
      onClose={onClose}
      maxWidth={620}
      footer={
        <div className={styles.footer}>
          <Button variant="ghost" onClick={onClose}>Закрыть</Button>
          <Button variant="secondary" icon={<Pencil size={15} />} onClick={onEdit}>
            Редактировать
          </Button>
        </div>
      }
    >
      <div className={styles.head}>
        <span className={styles.doneTag}><Check size={13} /> Выполнено</span>
        <h2 className={styles.title}>{template.name}</h2>
        <span className={styles.date}>{dateLabel}</span>
      </div>

      <div className={styles.stats}>
        <div className={styles.stat}>
          <span className={`${styles.statNum} mono`}>{rows.length}</span>
          <span className={styles.statLabel}>упражнений</span>
        </div>
        <div className={styles.stat}>
          <span className={`${styles.statNum} mono`}>{totalSets}</span>
          <span className={styles.statLabel}>подходов</span>
        </div>
        <div className={styles.stat}>
          <span className={`${styles.statNum} mono`}>{fmtW(totalVolume)}</span>
          <span className={styles.statLabel}>кг объём</span>
        </div>
      </div>

      <div className={styles.list}>
        {rows.map(({ ex, sets }) => (
          <div key={ex.id} className={styles.exercise}>
            <div className={styles.exHead}>
              <span className={styles.exName}>{ex.name}</span>
              <span className={styles.exCount}>{sets.length} × подх.</span>
            </div>
            <div className={styles.sets}>
              {sets.length === 0 ? (
                <span className={styles.noSets}>—</span>
              ) : sets.map((s, i) => (
                <span key={i} className={`${styles.setChip} mono`}>
                  {fmtW(s.weightKg)}<span className={styles.setX}>×</span>{s.reps}
                </span>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Modal>
  );
}
