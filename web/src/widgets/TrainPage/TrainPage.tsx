'use client';

import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight, Check, Coffee, ListChecks } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import {
  weekMonday, addDays, dayOfWeek, fmtDate, fmtWeekRange, computeDays,
  activeExercises, exercisesLoggedOnDate, WD_LABELS,
  type DayItem,
} from '@/shared/lib/train';
import { dayKeyOf } from '@/shared/lib/utils/format';
import type { ExerciseTemplate } from '@/shared/types';
import { ProgramModal } from './ProgramModal';
import { WorkoutLogModal } from './WorkoutLogModal';
import { CompletedWorkoutModal } from './CompletedWorkoutModal';
import styles from './TrainPage.module.scss';

export function TrainPage() {
  const templates    = useAppStore(s => s.workoutTemplates);
  const exerciseTpls = useAppStore(s => s.exerciseTemplates);
  const slots        = useAppStore(s => s.scheduleSlots);
  const setEntries   = useAppStore(s => s.setEntries);

  const [weekOffset, setWeekOffset] = useState(0);
  const [selectedDow, setSelectedDow] = useState(dayOfWeek(new Date()));
  const [programOpen, setProgramOpen] = useState(false);
  const [logTarget, setLogTarget] = useState<{ day: DayItem; exercises: ExerciseTemplate[] } | null>(null);
  const [doneTarget, setDoneTarget] = useState<{ day: DayItem; exercises: ExerciseTemplate[] } | null>(null);

  const weekStart = useMemo(
    () => addDays(weekMonday(new Date()), weekOffset * 7),
    [weekOffset],
  );

  const days = useMemo(
    () => computeDays(weekStart, slots, templates, exerciseTpls, setEntries),
    [weekStart, slots, templates, exerciseTpls, setEntries],
  );

  const selected = days[selectedDow - 1];

  // Tapping a DONE workout opens the read-only completed summary; an unfinished
  // day (missed past / today / future) opens the editor to fill it in.
  const openCard = (day: DayItem) => {
    if (!day.template) return;
    const key = dayKeyOf(day.date);
    if (day.isDone) {
      const exercises = exercisesLoggedOnDate(exerciseTpls, setEntries, day.template.id, key);
      if (exercises.length === 0) return;
      setDoneTarget({ day, exercises });
    } else {
      const exercises = activeExercises(exerciseTpls, day.template.id);
      if (exercises.length === 0) return;
      setLogTarget({ day, exercises });
    }
  };

  // "Редактировать" from the summary → editor with the logged exercises.
  const editDone = () => {
    if (!doneTarget?.day.template) return;
    setLogTarget(doneTarget);
    setDoneTarget(null);
  };

  const goToday = () => {
    setWeekOffset(0);
    setSelectedDow(dayOfWeek(new Date()));
  };

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <div className={styles.headTop}>
          <div>
            <h1 className={styles.title}>Тренировки</h1>
            <p className={styles.subtitle}>{fmtWeekRange(weekStart)}</p>
          </div>
          <div className={styles.nav}>
            <button className={styles.navBtn} onClick={() => setWeekOffset(o => o - 1)} aria-label="Прошлая неделя">
              <ChevronLeft size={18} />
            </button>
            <button className={styles.todayBtn} onClick={goToday}>Сегодня</button>
            <button className={styles.navBtn} onClick={() => setWeekOffset(o => o + 1)} aria-label="Следующая неделя">
              <ChevronRight size={18} />
            </button>
            <button className={styles.programBtn} onClick={() => setProgramOpen(true)}>
              <ListChecks size={15} /> Программа
            </button>
          </div>
        </div>

        {/* Day strip */}
        <div className={styles.strip}>
          {days.map(d => {
            const active = d.dow === selectedDow;
            return (
              <button
                key={d.dow}
                className={[
                  styles.stripDay,
                  active && styles.stripActive,
                  d.isToday && styles.stripToday,
                ].filter(Boolean).join(' ')}
                onClick={() => setSelectedDow(d.dow)}
              >
                <span className={styles.stripLabel}>{WD_LABELS[d.dow - 1]}</span>
                <span className={styles.stripDate}>{d.date.getDate()}</span>
                <span className={`${styles.stripMark} ${d.template ? styles.stripMarkOn : ''} ${d.isDone ? styles.stripMarkDone : ''}`} />
              </button>
            );
          })}
        </div>
      </header>

      <div className={styles.body}>
        {/* Selected-day card */}
        <div className={styles.colMain}>
          <AnimatePresence mode="wait">
            <motion.div
              key={`${weekOffset}-${selectedDow}`}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.16 }}
            >
              <DayCard day={selected} exerciseTpls={exerciseTpls} onOpen={() => openCard(selected)} />
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Whole week */}
        <div className={styles.colSide}>
          <div className={styles.weekHead}>
            <span className={styles.caps}>Вся неделя</span>
            <button className={styles.weekProgram} onClick={() => setProgramOpen(true)}>Программа →</button>
          </div>
          <div className={styles.weekList}>
            {days.map(d => (
              <WeekRow
                key={d.dow}
                day={d}
                count={d.template ? activeExercises(exerciseTpls, d.template.id).length : 0}
                onOpen={() => openCard(d)}
              />
            ))}
          </div>
        </div>
      </div>

      {programOpen && <ProgramModal onClose={() => setProgramOpen(false)} />}
      {doneTarget && (
        <CompletedWorkoutModal
          template={doneTarget.day.template!}
          date={doneTarget.day.date}
          exercises={doneTarget.exercises}
          onClose={() => setDoneTarget(null)}
          onEdit={editDone}
        />
      )}
      {logTarget && (
        <WorkoutLogModal
          template={logTarget.day.template!}
          date={logTarget.day.date}
          exercises={logTarget.exercises}
          onClose={() => setLogTarget(null)}
        />
      )}
    </div>
  );
}

// ── Selected-day card ───────────────────────────────────────────────────────────
function DayCard({ day, exerciseTpls, onOpen }: {
  day: DayItem; exerciseTpls: ExerciseTemplate[]; onOpen: () => void;
}) {
  if (!day.template) {
    return (
      <div className={styles.restCard}>
        <Coffee size={20} className={styles.restIcon} />
        <span className={styles.restText}>День отдыха</span>
      </div>
    );
  }

  const ex = activeExercises(exerciseTpls, day.template.id);
  const preview = ex.slice(0, 4).map(e => e.name).join(' · ');

  return (
    <div className={styles.dayCard} style={{ borderColor: 'var(--color-accent)' }}>
      <span className={styles.caps}>{WD_LABELS[day.dow - 1]} · {fmtDate(day.date)}</span>
      <h2 className={styles.dayName}>{day.template.name}</h2>
      {preview && <p className={styles.dayPreview}>{preview}</p>}
      <div className={styles.dayFoot}>
        <span className={styles.dayCount}>{ex.length} упр.</span>
        {day.isDone ? (
          <button className={styles.doneBadge} onClick={onOpen}>
            <Check size={15} /> Выполнено
            <ChevronRight size={15} />
          </button>
        ) : (
          <button className={styles.openBtn} onClick={onOpen}>Открыть</button>
        )}
      </div>
    </div>
  );
}

// ── Week-list row ───────────────────────────────────────────────────────────────
function WeekRow({ day, count, onOpen }: { day: DayItem; count: number; onOpen: () => void }) {
  const has = !!day.template;
  return (
    <button
      className={`${styles.row} ${has ? styles.rowActive : ''}`}
      onClick={has ? onOpen : undefined}
      disabled={!has}
      style={has ? { borderColor: 'rgba(var(--color-accent-rgb), 0.33)' } : undefined}
    >
      <span className={styles.rowDate}>{WD_LABELS[day.dow - 1]} · {fmtDate(day.date)}</span>
      {has ? (
        <>
          <span className={styles.rowBody}>
            <span className={styles.rowName}>{day.template!.name}</span>
            <span className={styles.rowCount}>{count} упр.</span>
          </span>
          {day.isDone && <Check size={16} className={styles.rowCheck} />}
          <ChevronRight size={16} className={styles.rowChevron} />
        </>
      ) : (
        <span className={styles.rowRest}>Отдых</span>
      )}
    </button>
  );
}
