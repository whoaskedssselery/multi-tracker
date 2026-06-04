'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, X, Trash2 } from 'lucide-react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useAppStore } from '@/store/app-store';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import type { Goal } from '@/types';
import s from './GoalsCard.module.scss';

const UNITS = ['kg', 'lbs', 'rep', 'km', '%'];

const schema = z.object({
  label:        z.string().min(1, 'Введите название'),
  startValue:   z.coerce.number({ invalid_type_error: 'Число' }),
  currentValue: z.coerce.number({ invalid_type_error: 'Число' }),
  targetValue:  z.coerce.number({ invalid_type_error: 'Число' }),
  unit:         z.string(),
});
type F = z.infer<typeof schema>;

export function GoalsCard() {
  const goals = useAppStore(s => s.goals);
  const addGoal = useAppStore(s => s.addGoal);
  const updateGoal = useAppStore(s => s.updateGoal);
  const deleteGoal = useAppStore(s => s.deleteGoal);

  const [editing, setEditing] = useState<Goal | null>(null);
  const [adding, setAdding] = useState(false);
  const [unit, setUnit] = useState('kg');

  const { register, handleSubmit, formState: { errors }, reset, setValue } = useForm<F>({
    resolver: zodResolver(schema),
    defaultValues: { unit: 'kg' },
  });

  const openAdd = () => {
    reset({ label: '', startValue: 0, currentValue: 0, targetValue: 0, unit: 'kg' });
    setUnit('kg');
    setEditing(null);
    setAdding(true);
  };

  const openEdit = (g: Goal) => {
    reset({ label: g.label, startValue: g.startValue, currentValue: g.currentValue, targetValue: g.targetValue, unit: g.unit });
    setUnit(g.unit);
    setEditing(g);
    setAdding(true);
  };

  const close = () => { setAdding(false); setEditing(null); };

  const onSubmit = (data: F) => {
    const d = { ...data, unit };
    if (editing) {
      updateGoal(editing.id, d);
    } else {
      addGoal(d);
    }
    close();
  };

  return (
    <div className={s.card}>
      <div className={s.header}>
        <span className={s.caps}>ЦЕЛИ</span>
        <button className={s.addBtn} onClick={openAdd}>
          <Plus size={18} />
        </button>
      </div>

      {goals.length === 0 ? (
        <p className={s.empty}>Добавьте первую цель</p>
      ) : (
        <div className={s.list}>
          {goals.map((g, i) => (
            <motion.div
              key={g.id}
              className={s.goal}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              onClick={() => openEdit(g)}
            >
              <div className={s.goalTop}>
                <span className={s.goalLabel}>{g.label}</span>
                <span className={`${s.goalVals} mono`}>
                  {g.currentValue.toFixed(1)} / {g.targetValue.toFixed(1)} {g.unit}
                </span>
              </div>
              <div className={s.progressBg}>
                <motion.div
                  className={s.progressFill}
                  initial={{ width: 0 }}
                  animate={{ width: `${Math.min(100, progress(g) * 100)}%` }}
                  transition={{ duration: 0.6, ease: 'easeOut' }}
                  style={{ background: progress(g) >= 1 ? 'var(--color-success)' : 'var(--color-accent)' }}
                />
              </div>
              <span className={`${s.goalPct} mono`}>{Math.round(progress(g) * 100)}%</span>
            </motion.div>
          ))}
        </div>
      )}

      {/* Dialog */}
      <Modal
        open={adding}
        onClose={close}
        title={editing ? 'Редактировать цель' : 'Добавить цель'}
        footer={
          <>
            {editing && (
              <Button variant="danger" size="sm" icon={<Trash2 size={14} />}
                onClick={() => { deleteGoal(editing.id); close(); }}>
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
          <Input label="Название" error={errors.label?.message} placeholder="Сбросить до 78 кг" {...register('label')} />
          <div className={s.row3}>
            <Input label="Старт"    type="number" step="0.1" error={errors.startValue?.message}   {...register('startValue')}   />
            <Input label="Текущее"  type="number" step="0.1" error={errors.currentValue?.message} {...register('currentValue')} />
            <Input label="Цель"     type="number" step="0.1" error={errors.targetValue?.message}  {...register('targetValue')}  />
          </div>
          <div>
            <p className={s.unitLabel}>Единица</p>
            <div className={s.units}>
              {UNITS.map(u => (
                <button
                  key={u}
                  type="button"
                  className={`${s.unitBtn} ${unit === u ? s.unitActive : ''}`}
                  onClick={() => { setUnit(u); setValue('unit', u); }}
                >
                  {u}
                </button>
              ))}
            </div>
          </div>
        </div>
      </Modal>
    </div>
  );
}

function progress(g: Goal): number {
  const range = Math.abs(g.targetValue - g.startValue);
  if (range === 0) return 1;
  return Math.min(1, Math.abs(g.currentValue - g.startValue) / range);
}
