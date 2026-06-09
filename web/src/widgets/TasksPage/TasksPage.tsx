'use client';

import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import { TaskItem } from '@/entities/task';
import { NoteCard, NoteEditor } from '@/entities/note';
import { TaskForm } from '@/features/task';
import { SearchBar, Button, Modal } from '@/shared/ui';
import type { TaskItem as TaskItemType, NoteItem, TaskGroup } from '@/shared/types';
import styles from './TasksPage.module.scss';

type Tab = 'tasks' | 'notes';
const GROUPS: { key: TaskGroup; label: string }[] = [
  { key: 'today',    label: 'Сегодня' },
  { key: 'tomorrow', label: 'Завтра' },
  { key: 'week',     label: 'На неделе' },
  { key: 'later',    label: 'Позже' },
  { key: 'none',     label: 'Без даты' },
];

export function TasksPage() {
  const tasks      = useAppStore(s => s.tasks);
  const notes      = useAppStore(s => s.notes);
  const toggleDone = useAppStore(s => s.toggleTaskDone);
  const addNote    = useAppStore(s => s.addNote);
  const updateNote = useAppStore(s => s.updateNote);
  const deleteNote = useAppStore(s => s.deleteNote);

  const [tab,          setTab]          = useState<Tab>('tasks');
  const [search,       setSearch]       = useState('');
  const [taskFormOpen, setTaskFormOpen] = useState(false);
  const [editingTask,  setEditingTask]  = useState<TaskItemType | null>(null);
  const [noteId,       setNoteId]       = useState<number | null>(null);

  const activeCount = tasks.filter(t => !t.isDone).length;
  const q = search.toLowerCase();

  const filteredTasks = useMemo(() =>
    tasks.filter(t => !q || t.body.toLowerCase().includes(q)), [tasks, q]);
  const doneTasks = filteredTasks.filter(t => t.isDone);

  const filteredNotes = useMemo(() =>
    q ? notes.filter(n => n.title.toLowerCase().includes(q) || n.body.toLowerCase().includes(q)) : notes,
    [notes, q]);
  const pinned  = filteredNotes.filter(n => n.isPinned);
  const regular = filteredNotes.filter(n => !n.isPinned);

  const noteObj = notes.find(n => n.id === noteId) ?? null;

  const openTaskForm = (task?: TaskItemType) => { setEditingTask(task ?? null); setTaskFormOpen(true); };
  const switchTab = (t: Tab) => { setTab(t); setSearch(''); };
  const newNote = () => setNoteId(addNote());
  const togglePin = (id: number) =>
    updateNote(id, { isPinned: !notes.find(n => n.id === id)?.isPinned });
  const removeNote = (id: number) => { deleteNote(id); if (noteId === id) setNoteId(null); };

  return (
    <div className={styles.page}>
      <header className={styles.header}>
        <h1 className={styles.title}>{tab === 'tasks' ? 'Задачи' : 'Заметки'}</h1>
        <div className={styles.controls}>
          <div className={styles.tabs}>
            <button className={`${styles.tab} ${tab === 'tasks' ? styles.tabActive : ''}`}
              onClick={() => switchTab('tasks')}>
              Задачи<span className={styles.tabBadge}>{activeCount}</span>
            </button>
            <button className={`${styles.tab} ${tab === 'notes' ? styles.tabActive : ''}`}
              onClick={() => switchTab('notes')}>
              Заметки<span className={styles.tabBadge}>{notes.length}</span>
            </button>
          </div>
          <Button variant="primary" size="md" icon={<Plus size={18} />}
            onClick={() => tab === 'tasks' ? openTaskForm() : newNote()}>
            {tab === 'tasks' ? 'Новая задача' : 'Новая заметка'}
          </Button>
        </div>
      </header>

      <div className={styles.toolbar}>
        <SearchBar value={search} onChange={setSearch}
          placeholder={tab === 'tasks' ? 'Поиск задач…' : 'Поиск заметок…'} />
      </div>

      <div className={styles.scroll}>
        <AnimatePresence mode="wait">
          <motion.div key={tab} className={styles.list}
            initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}
            transition={{ duration: 0.16 }}>
            {tab === 'tasks'
              ? <TasksList groups={GROUPS} active={filteredTasks.filter(t => !t.isDone)}
                  done={doneTasks} onToggle={toggleDone} onEdit={openTaskForm} />
              : <NotesList pinned={pinned} regular={regular} search={search}
                  onOpen={setNoteId} onPin={togglePin} onDelete={removeNote} />}
          </motion.div>
        </AnimatePresence>
      </div>

      <TaskForm open={taskFormOpen} editing={editingTask} onClose={() => setTaskFormOpen(false)} />

      <Modal open={noteObj !== null} onClose={() => setNoteId(null)} maxWidth={680}>
        {noteObj && (
          <NoteEditor note={noteObj}
            onDelete={() => removeNote(noteObj.id)}
            onPinToggle={() => togglePin(noteObj.id)} />
        )}
      </Modal>
    </div>
  );
}

// ── Tasks ───────────────────────────────────────────────────────────────────
function TasksList({ groups, active, done, onToggle, onEdit }: {
  groups: { key: TaskGroup; label: string }[];
  active: TaskItemType[]; done: TaskItemType[];
  onToggle: (id: number) => void; onEdit: (t: TaskItemType) => void;
}) {
  if (active.length === 0 && done.length === 0) {
    return (
      <div className={styles.empty}>
        <p className={styles.emptyTitle}>Задач нет</p>
        <p className={styles.emptySub}>Нажми «Новая задача», чтобы начать</p>
      </div>
    );
  }
  return (
    <div className={styles.groups}>
      {groups.map(({ key, label }) => {
        const items = active.filter(t => t.group === key);
        if (!items.length) return null;
        return (
          <section key={key} className={styles.group}>
            <p className={styles.groupLabel}>{label}</p>
            <div className={styles.groupCard}>
              <AnimatePresence>
                {items.map((task, i) => (
                  <TaskItem key={task.id} task={task} isLast={i === items.length - 1}
                    onToggle={() => onToggle(task.id)} onEdit={() => onEdit(task)} />
                ))}
              </AnimatePresence>
            </div>
          </section>
        );
      })}
      {done.length > 0 && (
        <section className={styles.group}>
          <p className={styles.groupLabel}>Выполнено</p>
          <div className={styles.groupCard}>
            {done.map((task, i) => (
              <TaskItem key={task.id} task={task} isLast={i === done.length - 1}
                onToggle={() => onToggle(task.id)} onEdit={() => onEdit(task)} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

// ── Notes ───────────────────────────────────────────────────────────────────
function NotesList({ pinned, regular, search, onOpen, onPin, onDelete }: {
  pinned: NoteItem[]; regular: NoteItem[]; search: string;
  onOpen: (id: number) => void; onPin: (id: number) => void; onDelete: (id: number) => void;
}) {
  if (pinned.length === 0 && regular.length === 0) {
    return (
      <div className={styles.empty}>
        <p className={styles.emptyTitle}>{search ? 'Ничего не найдено' : 'Заметок нет'}</p>
        {!search && <p className={styles.emptySub}>Нажми «Новая заметка», чтобы начать</p>}
      </div>
    );
  }
  const section = (label: string, items: NoteItem[]) => items.length > 0 && (
    <section className={styles.group}>
      <p className={styles.groupLabel}>{label}</p>
      <div className={styles.noteList}>
        {items.map(n => (
          <NoteCard key={n.id} note={n} selected={false}
            onSelect={() => onOpen(n.id)} onPin={() => onPin(n.id)} onDelete={() => onDelete(n.id)} />
        ))}
      </div>
    </section>
  );
  return (
    <div className={styles.groups}>
      {section('Закреплённые', pinned)}
      {section(pinned.length ? 'Остальные' : 'Все', regular)}
    </div>
  );
}
