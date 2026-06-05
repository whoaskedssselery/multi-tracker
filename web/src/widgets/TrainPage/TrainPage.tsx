import { Dumbbell } from 'lucide-react';
import styles from './TrainPage.module.scss';

export function TrainPage() {
  return (
    <div className={styles.page}>
      <header className={styles.header}><h1 className={styles.title}>Тренировки</h1></header>
      <div className={styles.content}>
        <Dumbbell size={48} className={styles.icon} />
        <p className={styles.label}>Раздел в разработке</p>
        <p className={styles.sub}>Скоро: PPL-программы, журнал подходов, AI-анализ прогресса</p>
      </div>
    </div>
  );
}
