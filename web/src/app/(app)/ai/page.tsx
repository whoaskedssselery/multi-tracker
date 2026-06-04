'use client';

import { Sparkles } from 'lucide-react';
import s from '../placeholder.module.scss';

export default function AiPage() {
  return (
    <div className={s.page}>
      <div className={s.header}>
        <h1 className={s.title}>ИИ</h1>
      </div>
      <div className={s.content}>
        <Sparkles size={48} className={s.icon} />
        <p className={s.label}>AI Chat в разработке</p>
        <p className={s.sub}>Скоро: чат с Groq LLM, контекст тренировок/веса/задач</p>
      </div>
    </div>
  );
}
