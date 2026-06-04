'use client';

import { motion } from 'framer-motion';
import { useAppStore } from '@/store/app-store';
import { WeightChart } from '@/components/home/WeightChart';
import { WeightRecorder } from '@/components/home/WeightRecorder';
import { GoalsCard } from '@/components/home/GoalsCard';
import { StatsCard } from '@/components/home/StatsCard';
import { formatDateShort, dayWord } from '@/lib/utils/format';
import s from './page.module.scss';

const WEEKDAYS = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const MONTHS = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

function headerDate() {
  const d = new Date();
  return `${WEEKDAYS[d.getDay() === 0 ? 7 : d.getDay()]} · ${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

export default function HomePage() {
  const profile = useAppStore(s => s.profile);
  const weightEntries = useAppStore(s => s.weightEntries);
  const tasks = useAppStore(s => s.tasks);

  const name = profile.name.trim();
  const greeting = !name || name === 'User' ? 'Привет' : `Привет, ${name}`;

  // Streak: consecutive days with weight entries
  const weightStreak = calcStreak(
    weightEntries.map(e => e.date.slice(0, 10)),
  );
  const taskStreak = calcStreak(
    tasks
      .filter(t => t.isDone && t.completedAt)
      .map(t => t.completedAt!.slice(0, 10)),
  );
  const openCount = tasks.filter(t => !t.isDone).length;

  return (
    <div className={s.page}>
      {/* Header */}
      <div className={s.header}>
        <div>
          <motion.h1
            className={s.greeting}
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
          >
            {greeting}
          </motion.h1>
          <p className={s.date}>{headerDate()}</p>
        </div>
      </div>

      {/* Content */}
      <div className={s.content}>
        <div className={s.grid}>
          {/* Left column */}
          <div className={s.col}>
            <WeightRecorder />
            <WeightChart entries={weightEntries} targetWeight={profile.targetWeightKg ?? undefined} />
            <HistoryCard entries={weightEntries.slice(0, 8)} />
          </div>

          {/* Right column */}
          <div className={s.col}>
            <GoalsCard />
            <StatsCard weightStreak={weightStreak} taskStreak={taskStreak} openTasks={openCount} />
          </div>
        </div>
      </div>
    </div>
  );
}

function calcStreak(dates: string[]): number {
  const unique = Array.from(new Set(dates)).sort((a, b) => b.localeCompare(a));
  if (!unique.length) return 0;
  const today = new Date().toISOString().slice(0, 10);
  let count = 0;
  let expected = today;
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

import type { WeightEntry } from '@/types';

function HistoryCard({ entries }: { entries: WeightEntry[] }) {
  const deleteEntry = useAppStore(s => s.deleteWeightEntry);
  if (!entries.length) return null;

  return (
    <div className={s.historyCard}>
      <h3 className={s.historyTitle}>ИСТОРИЯ</h3>
      <div className={s.historyList}>
        {entries.map((e, i) => {
          const prev = entries[i + 1];
          const delta = prev ? e.value - prev.value : null;
          return (
            <motion.div
              key={e.id}
              className={s.historyRow}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: i * 0.03 }}
            >
              <span className={`${s.historyDate} mono`}>{formatDateShort(e.date)}</span>
              <span className={`${s.historyVal} mono`}>{e.value.toFixed(1)}</span>
              {delta !== null && (
                <span className={`${s.historyDelta} mono ${delta > 0 ? s.deltaUp : delta < 0 ? s.deltaDown : ''}`}>
                  {delta > 0 ? '+' : ''}{delta.toFixed(1)}
                </span>
              )}
              <button
                className={s.historyDelete}
                onClick={() => deleteEntry(e.id)}
                aria-label="Удалить"
              >×</button>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
