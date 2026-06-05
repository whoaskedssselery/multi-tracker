import { Sparkles } from 'lucide-react';
import styles from './AiPage.module.scss';

export function AiPage() {
  return (
    <div className={styles.page}>
      <header className={styles.header}><h1 className={styles.title}>ИИ</h1></header>
      <div className={styles.content}>
        <Sparkles size={48} className={styles.icon} />
        <p className={styles.label}>AI Chat в разработке</p>
        <p className={styles.sub}>Скоро: чат с Groq LLM, контекст тренировок / веса / задач, стриминг ответов</p>
      </div>
    </div>
  );
}
