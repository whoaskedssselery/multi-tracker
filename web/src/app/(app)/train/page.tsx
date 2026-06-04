'use client';

import { Dumbbell } from 'lucide-react';
import s from '../placeholder.module.scss';

export default function TrainPage() {
  return (
    <div className={s.page}>
      <div className={s.header}>
        <h1 className={s.title}>Тренировки</h1>
      </div>
      <div className={s.content}>
        <Dumbbell size={48} className={s.icon} />
        <p className={s.label}>Раздел в разработке</p>
        <p className={s.sub}>Скоро: PPL-программы, журнал подходов, AI-анализ прогресса</p>
      </div>
    </div>
  );
}
