'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Trash2 } from 'lucide-react';
import { useAppStore } from '@shared/store';
import { Modal, Button, Input } from '@shared/ui';
import type { Goal } from '@shared/types';
import styles from './GoalForm.module.scss';

const UNITS = ['kg', 'lbs', 'rep', 'km', '%'];

const schema = z.object({
  label:        z.string().min(1, 'Введите название'),
  startValue:   z.coerce.number(),
  currentValue: z.coerce.number(),
  targetValue:  z.coerce.number(),
});
type F = z.infer<typeof schema>;

interface Props {
  open: boolean;
  editing?: Goal | null;
  onClose: () => void;
}

export function GoalForm({ open, editing, onClose }: Props) {
  const addGoal    = useAppStore(s => s.addGoal);
  const updateGoal = useAppStore(s => s.updateGoal);
  const deleteGoal = useAppStore(s => s.deleteGoal);
  const [unit, setUnit] = useState(editing?.unit ?? 'kg');

  const { register, handleSubmit, formState: { errors }, reset } = useForm<F>({
    resolver: zodResolver(schema),
    defaultValues: {
      label:        editing?.label ?? '',
      startValue:   editing?.startValue ?? 0,
      currentValue: editing?.currentValue ?? 0,
      targetValue:  editing?.targetValue ?? 0,
    },
  });

  const close = () => { onClose(); reset(); };

  const onSubmit = (data: F) => {
    if (editing) {
      updateGoal(editing.id, { ...data, unit });
    } else {
      addGoal({ ...data, unit });
    }
    close();
  };

  return (
    <Modal open={open} onClose={close} title={editing ? 'Редактировать цель' : 'Добавить цель'}
      footer={
        <>
          {editing && (
            <Button variant="danger" size="sm" icon={<Trash2 size={14} />}
              onClick={() => { deleteGoal(editing.id); close(); }}>Удалить</Button>
          )}
          <span style={{ flex: 1 }} />
          <Button variant="secondary" onClick={close}>Отмена</Button>
          <Button variant="primary" onClick={handleSubmit(onSubmit)}>
            {editing ? 'Сохранить' : 'Создать'}
          </Button>
        </>
      }>
      <div className={styles.form}>
        <Input label="Название" placeholder="Сбросить до 78 кг"
          error={errors.label?.message} {...register('label')} />
        <div className={styles.row3}>
          <Input label="Старт" type="number" step="0.1" error={errors.startValue?.message} {...register('startValue')} />
          <Input label="Текущее" type="number" step="0.1" error={errors.currentValue?.message} {...register('currentValue')} />
          <Input label="Цель" type="number" step="0.1" error={errors.targetValue?.message} {...register('targetValue')} />
        </div>
        <div>
          <p className={styles.unitLabel}>Единица</p>
          <div className={styles.units}>
            {UNITS.map(u => (
              <button key={u} type="button"
                className={`${styles.unit} ${unit === u ? styles.unitActive : ''}`}
                onClick={() => setUnit(u)}>{u}</button>
            ))}
          </div>
        </div>
      </div>
    </Modal>
  );
}
