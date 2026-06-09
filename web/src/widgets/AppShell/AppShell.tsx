import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { AnimatePresence, motion } from 'framer-motion';
import { Sidebar } from '@/widgets/Sidebar';
import { MobileNav } from '@/widgets/MobileNav';
import { useSync } from '@/features/sync';
import { HomePage } from '@/widgets/HomePage';
import { TrainPage } from '@/widgets/TrainPage';
import { TasksPage } from '@/widgets/TasksPage';
import { AiPage } from '@/widgets/AiPage';
import { SettingsPage } from '@/widgets/SettingsPage';
import styles from './AppShell.module.scss';

export function AppShell() {
  useSync();
  const location = useLocation();

  return (
    <div className={styles.shell}>
      <Sidebar />
      <main className={styles.main}>
        <AnimatePresence mode="wait">
          <motion.div
            key={location.pathname}
            className={styles.page}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -6 }}
            transition={{ duration: 0.2, ease: [0.22, 1, 0.36, 1] }}
          >
            <Routes location={location}>
              <Route path="/"         element={<HomePage />} />
              <Route path="/train"    element={<TrainPage />} />
              <Route path="/tasks"    element={<TasksPage />} />
              <Route path="/ai"       element={<AiPage />} />
              <Route path="/settings" element={<SettingsPage />} />
              <Route path="*"         element={<Navigate to="/" replace />} />
            </Routes>
          </motion.div>
        </AnimatePresence>
      </main>
      <MobileNav />
    </div>
  );
}
