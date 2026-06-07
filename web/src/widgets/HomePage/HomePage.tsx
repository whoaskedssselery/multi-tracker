'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Flame, Plus, ListTodo } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import { WeightChart, WeightHistoryList } from '@/entities/weight';
import { GoalItem } from '@/entities/goal';
import { WeightRecorder } from '@/features/weight';
import { GoalForm } from '@/features/goal';
import { dayWord, taskWord } from '@/shared/lib/utils/format';
import styles from './HomePage.module.scss';

const WEEKDAYS = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const MONTHS = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];

function headerDate() {
  const d = new Date();
  const wd = d.getDay() === 0 ? 7 : d.getDay();
  return `${WEEKDAYS[wd]}, ${d.getDate()} ${MONTHS[d.getMonth()]}`;
}

function calcStreak(dates: string[]): number {
  const unique = Array.from(new Set(dates)).sort((a, b) => b.localeCompare(a));
  if (!unique.length) return 0;
  const today = new Date().toISOString().slice(0, 10);
  let count = 0, expected = today;
  for (const d of unique) {
    if (d === expected) {
      count++;
      const prev = new Date(expected);
      prev.setDate(prev.getDate() - 1);
      expected = prev.toISOString().slice(0, 10);
    } else if (d < expected) break;
  }
  return count;
}

const rise = (i: number) => ({
  initial: { opacity: 0, y: 14 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.4, delay: 0.04 * i, ease: [0.22, 1, 0.36, 1] as const },
});

export function HomePage() {
  const profile       = useAppStore(s => s.profile);
  const weightEntries = useAppStore(s => s.weightEntries);
  const tasks         = useAppStore(s => s.tasks);
  const goals         = useAppStore(s => s.goals);

  const [goalFormOpen, setGoalFormOpen] = useState(false);
  const [editingGoal,  setEditingGoal]  = useState<typeof goals[0] | null>(null);

  const name = profile.name.trim();
  const greeting = !name || name === 'User' ? 'Привет 👋' : `Привет, ${name}`;

  const weightStreak = calcStreak(weightEntries.map(e => e.date.slice(0, 10)));
  const taskStreak   = calcStreak(
    tasks.filter(t => t.isDone && t.completedAt).map(t => t.completedAt!.slice(0, 10)),
  );
  const openTasks = tasks.filter(t => !t.isDone).length;
  const streaks = [
    { n: weightStreak, label: 'вес' },
    { n: taskStreak,   label: 'задачи' },
  ].filter(s => s.n > 0);

  const openForm = (g: typeof goals[0] | null) => { setEditingGoal(g); setGoalFormOpen(true); };

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <div className={styles.headMain}>
          <motion.h1 className={styles.greeting}
            initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}>
            {greeting}
          </motion.h1>
          <p className={styles.date}>{headerDate()}</p>
        </div>
        {streaks.length > 0 && (
          <div className={styles.headStreaks}>
            {streaks.map(({ n, label }) => (
              <span key={label} className={styles.streak}>
                <Flame size={14} className={styles.streakIcon} />
                <b className="mono">{n}</b>
                <span className={styles.streakDay}>{dayWord(n)}</span>
                <span className={styles.streakLabel}>· {label}</span>
              </span>
            ))}
          </div>
        )}
      </header>

      <div className={styles.scroll}>
        <div className={styles.grid}>
          <div className={styles.col}>
            <motion.div {...rise(0)}><WeightRecorder /></motion.div>
            <motion.div {...rise(1)}>
              <WeightChart entries={weightEntries} targetWeight={profile.targetWeightKg ?? undefined} />
            </motion.div>
            <motion.div {...rise(2)}><WeightHistoryList /></motion.div>
          </div>

          <div className={styles.col}>
            <motion.section className={styles.card} {...rise(1)}>
              <div className={styles.cardHeader}>
                <span className={styles.caps}>Цели</span>
                <button className={styles.addBtn} onClick={() => openForm(null)} aria-label="Добавить цель">
                  <Plus size={18} />
                </button>
              </div>
              {goals.length === 0 ? (
                <p className={styles.empty}>Добавьте первую цель</p>
              ) : (
                <div className={styles.goalList}>
                  {goals.map((g, i) => (
                    <motion.div key={g.id} initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.05 * i }}>
                      <GoalItem goal={g} onEdit={() => openForm(g)} />
                    </motion.div>
                  ))}
                </div>
              )}
            </motion.section>

            <motion.section className={styles.card} {...rise(2)}>
              <div className={styles.cardHeader}>
                <span className={styles.caps}>Задачи</span>
                <ListTodo size={16} className={styles.cardIcon} />
              </div>
              {openTasks === 0 ? (
                <p className={styles.allDone}>Всё сделано ✓</p>
              ) : (
                <p className={styles.taskStat}>
                  <span className="mono">{openTasks}</span>
                  <span className={styles.taskWord}>{taskWord(openTasks)} открыто</span>
                </p>
              )}
            </motion.section>
          </div>
        </div>
      </div>

      <GoalForm open={goalFormOpen} editing={editingGoal}
        onClose={() => { setGoalFormOpen(false); setEditingGoal(null); }} />
    </div>
  );
}
