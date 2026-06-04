'use client';

import { motion } from 'framer-motion';
import { Flame, CheckSquare2, Dumbbell } from 'lucide-react';
import { dayWord, taskWord } from '@/lib/utils/format';
import s from './StatsCard.module.scss';

interface Props {
  weightStreak: number;
  taskStreak: number;
  openTasks: number;
}

export function StatsCard({ weightStreak, taskStreak, openTasks }: Props) {
  const streaks = [
    { n: weightStreak, label: 'с весом',       icon: Flame },
    { n: taskStreak,   label: 'задач',          icon: CheckSquare2 },
  ].filter(s => s.n > 0);

  return (
    <div className={s.card}>
      {/* Streaks */}
      {streaks.length > 0 && (
        <div className={s.section}>
          <p className={s.caps}>СТРИКИ</p>
          <div className={s.streaks}>
            {streaks.map(({ n, label, icon: Icon }, i) => (
              <motion.div
                key={label}
                className={s.streak}
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: i * 0.1 }}
              >
                <Icon size={14} className={s.streakIcon} />
                <span className="mono">{n}</span>
                <span className={s.streakDay}>{dayWord(n)}</span>
                <span className={s.streakLabel}>{label}</span>
              </motion.div>
            ))}
          </div>
        </div>
      )}

      {/* Tasks summary */}
      <div className={s.section}>
        <p className={s.caps}>ЗАДАЧИ</p>
        <p className={s.tasksVal}>
          {openTasks === 0
            ? <span className={s.allDone}>Всё сделано ✓</span>
            : <><span className="mono">{openTasks}</span> {taskWord(openTasks)}</>
          }
        </p>
      </div>
    </div>
  );
}
