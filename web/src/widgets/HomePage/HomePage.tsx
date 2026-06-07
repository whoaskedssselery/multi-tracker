'use client';

import { motion } from 'framer-motion';
import { useAppStore } from '@/shared/store';
import { WeightChart, WeightHistoryList } from '@/entities/weight';
import { GoalItem } from '@/entities/goal';
import { WeightRecorder } from '@/features/weight';
import { GoalForm } from '@/features/goal';
import { formatSyncTime, dayWord, taskWord } from '@/shared/lib/utils/format';
import { Flame, CheckSquare2, Plus } from 'lucide-react';
import { useState } from 'react';
import styles from './HomePage.module.scss';

const WEEKDAYS = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const MONTHS = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

function headerDate() {
  const d = new Date();
  const wd = d.getDay() === 0 ? 7 : d.getDay();
  return `${WEEKDAYS[wd]} · ${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
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

export function HomePage() {
  const profile       = useAppStore(s => s.profile);
  const weightEntries = useAppStore(s => s.weightEntries);
  const tasks         = useAppStore(s => s.tasks);
  const goals         = useAppStore(s => s.goals);

  const [goalFormOpen, setGoalFormOpen] = useState(false);
  const [editingGoal,  setEditingGoal]  = useState<typeof goals[0] | null>(null);

  const name = profile.name.trim();
  const greeting = !name || name === 'User' ? 'Привет' : `Привет, ${name}`;

  const weightStreak = calcStreak(weightEntries.map(e => e.date.slice(0, 10)));
  const taskStreak   = calcStreak(
    tasks.filter(t => t.isDone && t.completedAt).map(t => t.completedAt!.slice(0, 10)),
  );
  const openTasks = tasks.filter(t => !t.isDone).length;
  const streaks = [
    { n: weightStreak, label: 'с весом' },
    { n: taskStreak,   label: 'задач' },
  ].filter(s => s.n > 0);

  return (
    <div className={styles.page}>
      {/* Header */}
      <header className={styles.header}>
        <motion.h1 className={styles.greeting}
          initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}>
          {greeting}
        </motion.h1>
        <p className={styles.date}>{headerDate()}</p>
      </header>

      {/* Scrollable content */}
      <div className={styles.scroll}>
        <div className={styles.grid}>
          {/* Left */}
          <div className={styles.col}>
            <WeightRecorder />
            <WeightChart entries={weightEntries} targetWeight={profile.targetWeightKg ?? undefined} />
            <WeightHistoryList />
          </div>

          {/* Right */}
          <div className={styles.col}>
            {/* Goals */}
            <div className={styles.card}>
              <div className={styles.cardHeader}>
                <span className={styles.caps}>ЦЕЛИ</span>
                <button className={styles.addBtn} onClick={() => { setEditingGoal(null); setGoalFormOpen(true); }}>
                  <Plus size={18} />
                </button>
              </div>
              {goals.length === 0 ? (
                <p className={styles.empty}>Добавьте первую цель</p>
              ) : (
                <div className={styles.goalList}>
                  {goals.map((g, i) => (
                    <motion.div key={g.id} initial={{ opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.05 }}>
                      <GoalItem goal={g} onEdit={() => { setEditingGoal(g); setGoalFormOpen(true); }} />
                    </motion.div>
                  ))}
                </div>
              )}
            </div>

            {/* Stats */}
            <div className={styles.card}>
              {streaks.length > 0 && (
                <div className={styles.statsSection}>
                  <span className={styles.caps}>СТРИКИ</span>
                  <div className={styles.streakList}>
                    {streaks.map(({ n, label }) => (
                      <div key={label} className={styles.streak}>
                        <Flame size={14} className={styles.streakIcon} />
                        <span className="mono">{n}</span>
                        <span className={styles.streakDay}>{dayWord(n)}</span>
                        <span className={styles.streakLabel}>{label}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              <div className={styles.statsSection}>
                <span className={styles.caps}>ЗАДАЧИ</span>
                <p className={styles.taskStat}>
                  {openTasks === 0
                    ? <span className={styles.allDone}>Всё сделано ✓</span>
                    : <><span className="mono">{openTasks}</span> {taskWord(openTasks)}</>
                  }
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <GoalForm open={goalFormOpen} editing={editingGoal}
        onClose={() => { setGoalFormOpen(false); setEditingGoal(null); }} />
    </div>
  );
}


