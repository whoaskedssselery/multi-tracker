'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { TasksPane } from '@/components/tasks/TasksPane';
import { NotesPane } from '@/components/tasks/NotesPane';
import { useAppStore } from '@/store/app-store';
import s from './page.module.scss';

type Tab = 'tasks' | 'notes';

export default function TasksPage() {
  const [tab, setTab] = useState<Tab>('tasks');
  const tasks = useAppStore(st => st.tasks);
  const notes = useAppStore(st => st.notes);

  const activeCount = tasks.filter(t => !t.isDone).length;

  return (
    <div className={s.page}>
      {/* Header */}
      <div className={s.header}>
        <h1 className={s.title}>
          {tab === 'tasks' ? 'Задачи' : 'Заметки'}
        </h1>

        {/* Tab switcher */}
        <div className={s.tabs}>
          <button
            className={`${s.tab} ${tab === 'tasks' ? s.tabActive : ''}`}
            onClick={() => setTab('tasks')}
          >
            Tasks · {activeCount}
          </button>
          <button
            className={`${s.tab} ${tab === 'notes' ? s.tabActive : ''}`}
            onClick={() => setTab('notes')}
          >
            Notes · {notes.length}
          </button>
        </div>
      </div>

      {/* Content */}
      <AnimatePresence mode="wait">
        <motion.div
          key={tab}
          className={s.content}
          initial={{ opacity: 0, x: tab === 'tasks' ? -12 : 12 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.18, ease: 'easeInOut' }}
        >
          {tab === 'tasks' ? <TasksPane /> : <NotesPane />}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
