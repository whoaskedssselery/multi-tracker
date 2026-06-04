'use client';

import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Search, X, Bell, Trash2, ChevronRight } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useAppStore } from '@/store/app-store';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Input, Textarea } from '@/components/ui/Input';
import type { TaskItem, TaskGroup, TaskPriority } from '@/types';
import s from './TasksPane.module.scss';

const GROUPS: { key: TaskGroup; label: string }[] = [
  { key: 'today',    label: 'Сегодня' },
  { key: 'tomorrow', label: 'Завтра' },
  { key: 'week',     label: 'На неделе' },
  { key: 'later',    label: 'Позже' },
  { key: 'none',     label: 'Без даты' },
];

const PRIORITIES: { key: TaskPriority; label: string }[] = [
  { key: 'none', label: 'нет' },
  { key: 'low',  label: 'низкий' },
  { key: 'mid',  label: 'средний' },
  { key: 'high', label: 'высокий' },
];

const schema = z.object({
  body: z.string().min(1, 'Введите задачу'),
});

export function TasksPane() {
  const tasks = useAppStore(s => s.tasks);
  const addTask = useAppStore(s => s.addTask);
  const toggleDone = useAppStore(s => s.toggleTaskDone);
  const updateTask = useAppStore(s => s.updateTask);
  const deleteTask = useAppStore(s => s.deleteTask);

  const [search, setSearch] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<TaskItem | null>(null);
  const [group, setGroup] = useState<TaskGroup>('none');
  const [priority, setPriority] = useState<TaskPriority>('none');

  const { register, handleSubmit, formState: { errors }, reset } = useForm<{ body: string }>({
    resolver: zodResolver(schema),
  });

  const openAdd = () => {
    reset({ body: '' });
    setGroup('none');
    setPriority('none');
    setEditing(null);
    setModalOpen(true);
  };

  const openEdit = (t: TaskItem) => {
    reset({ body: t.body });
    setGroup(t.group);
    setPriority(t.priority);
    setEditing(t);
    setModalOpen(true);
  };

  const close = () => { setModalOpen(false); setEditing(null); };

  const onSubmit = ({ body }: { body: string }) => {
    if (editing) {
      updateTask(editing.id, { body: body.trim(), group, priority });
    } else {
      addTask({ body: body.trim(), group, priority, notifyAt: null });
    }
    close();
  };

  const activeTasks = useMemo(
    () => tasks.filter(t => !t.isDone && (search ? t.body.toLowerCase().includes(search.toLowerCase()) : true)),
    [tasks, search],
  );
  const doneTasks = useMemo(
    () => tasks.filter(t => t.isDone && (search ? t.body.toLowerCase().includes(search.toLowerCase()) : true)),
    [tasks, search],
  );

  const grouped = GROUPS.map(g => ({
    ...g,
    items: activeTasks.filter(t => t.group === g.key),
  })).filter(g => g.items.length > 0);

  return (
    <div className={s.pane}>
      {/* Toolbar */}
      <div className={s.toolbar}>
        <div className={s.searchWrap}>
          <Search size={15} className={s.searchIcon} />
          <input
            className={s.search}
            placeholder="Поиск задач..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          {search && (
            <button className={s.clearSearch} onClick={() => setSearch('')}>
              <X size={13} />
            </button>
          )}
        </div>
        <Button variant="primary" size="sm" icon={<Plus size={14} />} onClick={openAdd}>
          Новая задача
        </Button>
      </div>

      {/* List */}
      <div className={s.list}>
        {activeTasks.length === 0 && doneTasks.length === 0 && (
          <div className={s.empty}>
            <p>Задач нет</p>
            <p className={s.emptySub}>Нажми «Новая задача» чтобы начать</p>
          </div>
        )}

        {grouped.map(({ key, label, items }) => (
          <div key={key} className={s.group}>
            <p className={s.groupLabel}>{label.toUpperCase()}</p>
            <div className={s.groupCard}>
              <AnimatePresence>
                {items.map((task, i) => (
                  <TaskRow
                    key={task.id}
                    task={task}
                    isLast={i === items.length - 1}
                    onToggle={() => toggleDone(task.id)}
                    onEdit={() => openEdit(task)}
                  />
                ))}
              </AnimatePresence>
            </div>
          </div>
        ))}

        {doneTasks.length > 0 && (
          <div className={s.group}>
            <p className={s.groupLabel}>ВЫПОЛНЕНО</p>
            <div className={s.groupCard}>
              {doneTasks.map((task, i) => (
                <TaskRow
                  key={task.id}
                  task={task}
                  isLast={i === doneTasks.length - 1}
                  onToggle={() => toggleDone(task.id)}
                  onEdit={() => openEdit(task)}
                />
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Task modal */}
      <Modal
        open={modalOpen}
        onClose={close}
        title={editing ? 'Изменить задачу' : 'Новая задача'}
        footer={
          <>
            {editing && (
              <Button variant="danger" size="sm" icon={<Trash2 size={14} />}
                onClick={() => { deleteTask(editing.id); close(); }}>
                Удалить
              </Button>
            )}
            <div style={{ flex: 1 }} />
            <Button variant="secondary" onClick={close}>Отмена</Button>
            <Button variant="primary" onClick={handleSubmit(onSubmit)}>
              {editing ? 'Сохранить' : 'Создать'}
            </Button>
          </>
        }
      >
        <div className={s.form}>
          <Textarea
            label="Задача"
            placeholder="Что надо сделать?"
            error={errors.body?.message}
            autoFocus
            {...register('body')}
          />

          <div>
            <p className={s.formLabel}>КОГДА</p>
            <div className={s.chips}>
              {GROUPS.map(g => (
                <button
                  key={g.key}
                  type="button"
                  className={`${s.chip} ${group === g.key ? s.chipActive : ''}`}
                  onClick={() => setGroup(g.key)}
                >
                  {g.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <p className={s.formLabel}>ПРИОРИТЕТ</p>
            <div className={s.chips}>
              {PRIORITIES.map(p => (
                <button
                  key={p.key}
                  type="button"
                  className={`${s.chip} ${priority === p.key ? s.chipActive : ''} ${
                    p.key === 'high' ? s.chipHigh : p.key === 'mid' ? s.chipMid : ''
                  }`}
                  onClick={() => setPriority(p.key)}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      </Modal>
    </div>
  );
}

function TaskRow({ task, isLast, onToggle, onEdit }: {
  task: TaskItem;
  isLast: boolean;
  onToggle: () => void;
  onEdit: () => void;
}) {
  const prioColor = task.priority === 'high' ? 'var(--color-danger)'
    : task.priority === 'mid' ? 'var(--color-warning)'
    : task.priority === 'low' ? 'var(--color-text3)'
    : 'transparent';

  return (
    <motion.div
      className={`${s.taskRow} ${isLast ? s.taskRowLast : ''}`}
      initial={{ opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, height: 0 }}
      layout
    >
      <button
        className={`${s.check} ${task.isDone ? s.checked : ''}`}
        onClick={onToggle}
        aria-label="Отметить"
      >
        {task.isDone && <span className={s.checkMark}>✓</span>}
      </button>

      {task.priority !== 'none' && (
        <span className={s.prio} style={{ background: prioColor }} />
      )}

      <span
        className={`${s.taskBody} ${task.isDone ? s.taskDone : ''}`}
        onClick={onEdit}
      >
        {task.body}
      </span>

      <ChevronRight size={14} className={s.taskArrow} onClick={onEdit} />
    </motion.div>
  );
}
