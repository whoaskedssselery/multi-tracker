'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Trash2 } from 'lucide-react';
import { useAppStore } from '@client/shared/store';
import { Modal, Button, Textarea } from '@client/shared/ui';
import type { TaskItem, TaskGroup, TaskPriority } from '@client/shared/types';
import styles from './TaskForm.module.scss';

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

const schema = z.object({ body: z.string().min(1, 'Введите задачу') });

interface Props {
  open: boolean;
  editing?: TaskItem | null;
  defaultGroup?: TaskGroup;
  onClose: () => void;
}

export function TaskForm({ open, editing, defaultGroup = 'none', onClose }: Props) {
  const addTask    = useAppStore(s => s.addTask);
  const updateTask = useAppStore(s => s.updateTask);
  const deleteTask = useAppStore(s => s.deleteTask);

  const [group,    setGroup]    = useState<TaskGroup>(editing?.group ?? defaultGroup);
  const [priority, setPriority] = useState<TaskPriority>(editing?.priority ?? 'none');

  const { register, handleSubmit, formState: { errors }, reset } = useForm<{ body: string }>({
    resolver: zodResolver(schema),
    defaultValues: { body: editing?.body ?? '' },
  });

  const close = () => { onClose(); reset(); };

  const onSubmit = ({ body }: { body: string }) => {
    if (editing) {
      updateTask(editing.id, { body: body.trim(), group, priority });
    } else {
      addTask({ body: body.trim(), group, priority, notifyAt: null });
    }
    close();
  };

  return (
    <Modal open={open} onClose={close} title={editing ? 'Изменить задачу' : 'Новая задача'}
      footer={
        <>
          {editing && (
            <Button variant="danger" size="sm" icon={<Trash2 size={14} />}
              onClick={() => { deleteTask(editing.id); close(); }}>Удалить</Button>
          )}
          <span style={{ flex: 1 }} />
          <Button variant="secondary" onClick={close}>Отмена</Button>
          <Button variant="primary" onClick={handleSubmit(onSubmit)}>
            {editing ? 'Сохранить' : 'Создать'}
          </Button>
        </>
      }>
      <div className={styles.form}>
        <Textarea label="Задача" placeholder="Что надо сделать?"
          error={errors.body?.message} autoFocus {...register('body')} />

        <div>
          <p className={styles.groupLabel}>КОГДА</p>
          <div className={styles.chips}>
            {GROUPS.map(g => (
              <button key={g.key} type="button"
                className={`${styles.chip} ${group === g.key ? styles.chipActive : ''}`}
                onClick={() => setGroup(g.key)}>{g.label}</button>
            ))}
          </div>
        </div>

        <div>
          <p className={styles.groupLabel}>ПРИОРИТЕТ</p>
          <div className={styles.chips}>
            {PRIORITIES.map(p => (
              <button key={p.key} type="button"
                className={[styles.chip, priority === p.key && styles.chipActive,
                  p.key === 'high' && styles.chipHigh, p.key === 'mid' && styles.chipMid,
                ].filter(Boolean).join(' ')}
                onClick={() => setPriority(p.key)}>{p.label}</button>
            ))}
          </div>
        </div>
      </div>
    </Modal>
  );
}

