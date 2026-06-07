'use client';

import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, ArrowLeft } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import { TaskItem } from '@/entities/task';
import { NoteCard, NoteEditor } from '@/entities/note';
import { TaskForm } from '@/features/task';
import { SearchBar } from '@/shared/ui';
import { Button } from '@/shared/ui';
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
  const tasks         = useAppStore(s => s.tasks);
  const notes         = useAppStore(s => s.notes);
  const toggleDone    = useAppStore(s => s.toggleTaskDone);
  const addNote       = useAppStore(s => s.addNote);
  const updateNote    = useAppStore(s => s.updateNote);
  const deleteNote    = useAppStore(s => s.deleteNote);

  const [tab,          setTab]          = useState<Tab>('tasks');
  const [search,       setSearch]       = useState('');
  const [taskFormOpen, setTaskFormOpen] = useState(false);
  const [editingTask,  setEditingTask]  = useState<TaskItemType | null>(null);
  const [selectedNote, setSelectedNote] = useState<number | null>(null);

  const activeCount = tasks.filter(t => !t.isDone).length;
  const q = search.toLowerCase();

  const filteredTasks = useMemo(() =>
    tasks.filter(t => !q || t.body.toLowerCase().includes(q)), [tasks, q]);
  const doneTasks     = filteredTasks.filter(t => t.isDone);

  const filteredNotes = useMemo(() => {
    const all = notes;
    return q ? all.filter(n =>
      n.title.toLowerCase().includes(q) || n.body.toLowerCase().includes(q),
    ) : all;
  }, [notes, q]);

  const pinned  = filteredNotes.filter(n => n.isPinned);
  const regular = filteredNotes.filter(n => !n.isPinned);

  const selectedNoteObj = notes.find(n => n.id === selectedNote) ?? null;

  const openTaskForm = (task?: TaskItemType) => {
    setEditingTask(task ?? null);
    setTaskFormOpen(true);
  };

  const switchTab = (t: Tab) => { setTab(t); setSearch(''); setSelectedNote(null); };

  return (
    <div className={styles.page}>
      {/* Header */}
      <header className={styles.header}>
        <h1 className={styles.title}>{tab === 'tasks' ? 'Задачи' : 'Заметки'}</h1>

        <div className={styles.controls}>
          {/* Tab switcher */}
          <div className={styles.tabs}>
            <button className={`${styles.tab} ${tab === 'tasks' ? styles.tabActive : ''}`}
              onClick={() => switchTab('tasks')}>
              Tasks · {activeCount}
            </button>
            <button className={`${styles.tab} ${tab === 'notes' ? styles.tabActive : ''}`}
              onClick={() => switchTab('notes')}>
              Notes · {notes.length}
            </button>
          </div>

          {/* Action button */}
          {tab === 'tasks' ? (
            <Button variant="primary" size="sm" icon={<Plus size={14} />}
              onClick={() => openTaskForm()}>
              Новая задача
            </Button>
          ) : (
            <Button variant="primary" size="sm" icon={<Plus size={14} />}
              onClick={() => { const id = addNote(); setSelectedNote(id); }}>
              Заметка
            </Button>
          )}
        </div>
      </header>

      {/* Content */}
      <AnimatePresence mode="wait">
        <motion.div key={tab} className={styles.body}
          initial={{ opacity: 0, x: tab === 'tasks' ? -10 : 10 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.15 }}>
          {tab === 'tasks' ? (
            <TasksPanel
              groups={GROUPS}
              filteredTasks={filteredTasks}
              doneTasks={doneTasks}
              search={search}
              onSearchChange={setSearch}
              onToggle={toggleDone}
              onEdit={openTaskForm}
            />
          ) : (
            <NotesPanel
              pinned={pinned}
              regular={regular}
              selectedId={selectedNote}
              selectedNote={selectedNoteObj}
              search={search}
              onSearchChange={setSearch}
              onSelect={setSelectedNote}
              onNew={() => { const id = addNote(); setSelectedNote(id); }}
              onPin={id => updateNote(id, { isPinned: !notes.find(n => n.id === id)?.isPinned })}
              onDelete={id => { deleteNote(id); if (selectedNote === id) setSelectedNote(null); }}
              onBack={() => setSelectedNote(null)}
            />
          )}
        </motion.div>
      </AnimatePresence>

      <TaskForm open={taskFormOpen} editing={editingTask} onClose={() => setTaskFormOpen(false)} />
    </div>
  );
}

// ── Tasks panel ───────────────────────────────────────────────────────────────

function TasksPanel({ groups, filteredTasks, doneTasks, search, onSearchChange, onToggle, onEdit }: {
  groups: { key: TaskGroup; label: string }[];
  filteredTasks: TaskItemType[];
  doneTasks: TaskItemType[];
  search: string;
  onSearchChange: (v: string) => void;
  onToggle: (id: number) => void;
  onEdit: (t: TaskItemType) => void;
}) {
  const active = filteredTasks.filter(t => !t.isDone);

  return (
    <div className={styles.tasksPanel}>
      <div className={styles.toolbar}>
        <SearchBar value={search} onChange={onSearchChange} placeholder="Поиск задач..." />
      </div>
      <div className={styles.taskList}>
        {active.length === 0 && doneTasks.length === 0 && (
          <div className={styles.empty}>
            <p>Задач нет</p>
            <p className={styles.emptySub}>Нажми «Новая задача» чтобы начать</p>
          </div>
        )}
        {groups.map(({ key, label }) => {
          const items = active.filter(t => t.group === key);
          if (!items.length) return null;
          return (
            <div key={key} className={styles.group}>
              <p className={styles.groupLabel}>{label.toUpperCase()}</p>
              <div className={styles.groupCard}>
                <AnimatePresence>
                  {items.map((task, i) => (
                    <TaskItem key={task.id} task={task} isLast={i === items.length - 1}
                      onToggle={() => onToggle(task.id)} onEdit={() => onEdit(task)} />
                  ))}
                </AnimatePresence>
              </div>
            </div>
          );
        })}
        {doneTasks.length > 0 && (
          <div className={styles.group}>
            <p className={styles.groupLabel}>ВЫПОЛНЕНО</p>
            <div className={styles.groupCard}>
              {doneTasks.map((task, i) => (
                <TaskItem key={task.id} task={task} isLast={i === doneTasks.length - 1}
                  onToggle={() => onToggle(task.id)} onEdit={() => onEdit(task)} />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Notes panel ───────────────────────────────────────────────────────────────

function NotesPanel({ pinned, regular, selectedId, selectedNote, search, onSearchChange,
  onSelect, onNew, onPin, onDelete, onBack }: {
  pinned: NoteItem[]; regular: NoteItem[];
  selectedId: number | null; selectedNote: NoteItem | null;
  search: string; onSearchChange: (v: string) => void;
  onSelect: (id: number) => void; onNew: () => void;
  onPin: (id: number) => void; onDelete: (id: number) => void;
  onBack: () => void;
}) {
  return (
    <div className={styles.notesPanel}>
      {/* Sidebar */}
      <div className={`${styles.notesSidebar} ${selectedNote ? styles.notesSidebarHidden : ''}`}>
        <div className={styles.notesToolbar}>
          <SearchBar value={search} onChange={onSearchChange} placeholder="Поиск..." />
        </div>
        <div className={styles.notesList}>
          {pinned.length === 0 && regular.length === 0 && (
            <div className={styles.empty}>{search ? 'Ничего не найдено' : 'Нет заметок'}</div>
          )}
          {pinned.length > 0 && (
            <>
              <p className={styles.notesSection}>ЗАКРЕПЛЁННЫЕ</p>
              {pinned.map(n => (
                <NoteCard key={n.id} note={n} selected={n.id === selectedId}
                  onSelect={() => onSelect(n.id)} onPin={() => onPin(n.id)} onDelete={() => onDelete(n.id)} />
              ))}
            </>
          )}
          {regular.length > 0 && (
            <>
              {pinned.length > 0 && <p className={styles.notesSection}>ОСТАЛЬНЫЕ</p>}
              {regular.map(n => (
                <NoteCard key={n.id} note={n} selected={n.id === selectedId}
                  onSelect={() => onSelect(n.id)} onPin={() => onPin(n.id)} onDelete={() => onDelete(n.id)} />
              ))}
            </>
          )}
        </div>
      </div>

      {/* Editor */}
      <div className={`${styles.notesEditor} ${!selectedNote ? styles.notesEditorEmpty : ''}`}>
        <AnimatePresence mode="wait">
          {selectedNote ? (
            <motion.div key={selectedNote.id} className={styles.notesEditorInner}
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              transition={{ duration: 0.12 }}>
              {/* Mobile back button */}
              <div className={styles.mobileBack}>
                <button className={styles.backBtn} onClick={onBack}>
                  <ArrowLeft size={18} /><span>Заметки</span>
                </button>
              </div>
              <NoteEditor note={selectedNote} onDelete={() => onDelete(selectedNote.id)}
                onPinToggle={() => onPin(selectedNote.id)} />
            </motion.div>
          ) : (
            <motion.div key="empty" className={styles.notesEmptyState}
              initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
              <p className={styles.notesEmptyTitle}>Выбери заметку слева</p>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}


