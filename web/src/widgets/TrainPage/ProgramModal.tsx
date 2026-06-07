'use client';

import { useState } from 'react';
import { Plus, ChevronRight, ChevronLeft, Trash2, Minus, X } from 'lucide-react';
import { useAppStore } from '@/shared/store';
import { Modal, Button, Input } from '@/shared/ui';
import {
  WD_LABELS, activeExercises, setsRepsOf, PROGRAM_COLORS, argbToCss,
} from '@/shared/lib/train';
import type { WorkoutTemplate } from '@/shared/types';
import styles from './ProgramModal.module.scss';

interface ExDraft { key: number; id?: number; name: string; sets: number; reps: number }

let draftSeq = 0;
const newDraft = (p: Partial<ExDraft> = {}): ExDraft =>
  ({ key: draftSeq++, name: '', sets: 3, reps: 10, ...p });

export function ProgramModal({ onClose }: { onClose: () => void }) {
  const templates    = useAppStore(s => s.workoutTemplates);
  const exerciseTpls = useAppStore(s => s.exerciseTemplates);
  const slots        = useAppStore(s => s.scheduleSlots);
  const addTemplate     = useAppStore(s => s.addWorkoutTemplate);
  const updateTemplate  = useAppStore(s => s.updateWorkoutTemplate);
  const deleteTemplate  = useAppStore(s => s.deleteWorkoutTemplate);
  const setExercises    = useAppStore(s => s.setTemplateExercises);
  const setScheduleSlot = useAppStore(s => s.setScheduleSlot);

  const [view, setView] = useState<'library' | 'week'>('library');

  // Editor state (null = not editing)
  const [editId, setEditId]   = useState<number | null | undefined>(undefined); // undefined=closed, null=new
  const [name, setName]       = useState('');
  const [color, setColor]     = useState(PROGRAM_COLORS[0]);
  const [exs, setExs]         = useState<ExDraft[]>([]);

  const editorOpen = editId !== undefined;

  const openNew = () => {
    setEditId(null); setName(''); setColor(PROGRAM_COLORS[0]); setExs([newDraft()]);
  };

  const openEdit = (t: WorkoutTemplate) => {
    const drafts = activeExercises(exerciseTpls, t.id).map(ex => {
      const { sets, reps } = setsRepsOf(ex);
      return newDraft({ id: ex.id, name: ex.name, sets, reps });
    });
    setEditId(t.id); setName(t.name); setColor(t.color);
    setExs(drafts.length ? drafts : [newDraft()]);
  };

  const closeEditor = () => setEditId(undefined);

  const saveEditor = () => {
    const trimmed = name.trim();
    if (!trimmed) return;
    const list = exs
      .filter(e => e.name.trim())
      .map(e => ({ id: e.id, name: e.name.trim(), sets: e.sets, reps: e.reps }));
    const id = editId == null ? addTemplate(trimmed, color) : editId;
    if (editId != null) updateTemplate(id, { name: trimmed, color });
    setExercises(id, list);
    closeEditor();
  };

  const removeProgram = () => {
    if (editId != null) deleteTemplate(editId);
    closeEditor();
  };

  // ── Editor ──────────────────────────────────────────────────────────────
  if (editorOpen) {
    return (
      <Modal
        open
        onClose={onClose}
        maxWidth={560}
        footer={
          <div className={styles.footer}>
            {editId != null && (
              <Button variant="danger" icon={<Trash2 size={16} />} onClick={removeProgram}>
                Удалить
              </Button>
            )}
            <div className={styles.footerRight}>
              <Button variant="ghost" onClick={closeEditor}>Назад</Button>
              <Button variant="primary" onClick={saveEditor} disabled={!name.trim()}>
                Сохранить
              </Button>
            </div>
          </div>
        }
      >
        <button className={styles.back} onClick={closeEditor}>
          <ChevronLeft size={18} /> {editId == null ? 'Новая программа' : 'Редактировать'}
        </button>

        <Input
          label="Название"
          placeholder="Например, Push"
          value={name}
          onChange={e => setName(e.target.value)}
          autoFocus
        />

        <div className={styles.field}>
          <span className={styles.fieldLabel}>Цвет</span>
          <div className={styles.colors}>
            {PROGRAM_COLORS.map(c => (
              <button
                key={c}
                className={`${styles.colorDot} ${c === color ? styles.colorActive : ''}`}
                style={{ background: argbToCss(c) }}
                onClick={() => setColor(c)}
                aria-label="Цвет программы"
              />
            ))}
          </div>
        </div>

        <div className={styles.field}>
          <span className={styles.fieldLabel}>Упражнения</span>
          <div className={styles.exList}>
            {exs.map((ex, i) => (
              <div key={ex.key} className={styles.exRow}>
                <input
                  className={styles.exInput}
                  placeholder="Упражнение"
                  value={ex.name}
                  onChange={e => setExs(prev => prev.map((x, j) =>
                    j === i ? { ...x, name: e.target.value } : x))}
                />
                <Stepper
                  label="подх."
                  value={ex.sets} min={1} max={10}
                  onChange={v => setExs(prev => prev.map((x, j) => j === i ? { ...x, sets: v } : x))}
                />
                <Stepper
                  label="повт."
                  value={ex.reps} min={1} max={50}
                  onChange={v => setExs(prev => prev.map((x, j) => j === i ? { ...x, reps: v } : x))}
                />
                <button
                  className={styles.exDel}
                  onClick={() => setExs(prev => prev.filter((_, j) => j !== i))}
                  aria-label="Удалить упражнение"
                >
                  <X size={15} />
                </button>
              </div>
            ))}
          </div>
          <button className={styles.addEx} onClick={() => setExs(prev => [...prev, newDraft()])}>
            <Plus size={15} /> Добавить упражнение
          </button>
        </div>
      </Modal>
    );
  }

  // ── Library / Week ──────────────────────────────────────────────────────
  return (
    <Modal
      open
      onClose={onClose}
      title="Программы"
      maxWidth={560}
      footer={
        <div className={styles.footer}>
          <div className={styles.footerRight}>
            <Button variant="primary" onClick={onClose}>Готово</Button>
          </div>
        </div>
      }
    >
      <div className={styles.segmented}>
        <button
          className={`${styles.seg} ${view === 'library' ? styles.segActive : ''}`}
          onClick={() => setView('library')}
        >
          Мои программы
        </button>
        <button
          className={`${styles.seg} ${view === 'week' ? styles.segActive : ''}`}
          onClick={() => setView('week')}
        >
          Неделя
        </button>
      </div>

      {view === 'library' ? (
        <div className={styles.library}>
          {templates.length === 0 && (
            <p className={styles.hint}>Пока нет программ. Создай первую ниже.</p>
          )}
          {templates.map(t => {
            const ex = activeExercises(exerciseTpls, t.id);
            const preview = ex.slice(0, 3).map(e => e.name).join(' · ');
            return (
              <button key={t.id} className={styles.programCard} onClick={() => openEdit(t)}>
                <span className={styles.progDot} style={{ background: argbToCss(t.color) }} />
                <span className={styles.progBody}>
                  <span className={styles.progTop}>
                    <span className={styles.progName}>{t.name}</span>
                    <span className={styles.progCount}>{ex.length} упр.</span>
                  </span>
                  {preview && <span className={styles.progPreview}>{preview}</span>}
                </span>
                <ChevronRight size={18} className={styles.progChevron} />
              </button>
            );
          })}
          <button className={styles.createBtn} onClick={openNew}>
            <Plus size={16} /> Создать программу
          </button>
        </div>
      ) : (
        <div className={styles.week}>
          {templates.length === 0 ? (
            <p className={styles.hint}>Сначала создай программу во вкладке «Мои программы».</p>
          ) : (
            Array.from({ length: 7 }, (_, i) => i + 1).map(dow => {
              const current = slots.find(s => s.dayOfWeek === dow)?.workoutTemplateId ?? null;
              return (
                <div key={dow} className={styles.weekRow}>
                  <span className={styles.weekDay}>{WD_LABELS[dow - 1]}</span>
                  <div className={styles.pills}>
                    {templates.map(t => (
                      <button
                        key={t.id}
                        className={`${styles.pill} ${current === t.id ? styles.pillActive : ''}`}
                        style={current === t.id ? { background: argbToCss(t.color), borderColor: argbToCss(t.color) } : undefined}
                        onClick={() => setScheduleSlot(dow, t.id)}
                      >
                        <span className={styles.pillDot} style={{ background: argbToCss(t.color) }} />
                        {t.name}
                      </button>
                    ))}
                    <button
                      className={`${styles.pill} ${current === null ? styles.pillRest : ''}`}
                      onClick={() => setScheduleSlot(dow, null)}
                    >
                      Отдых
                    </button>
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}
    </Modal>
  );
}

// ── Stepper ───────────────────────────────────────────────────────────────────
function Stepper({ value, min, max, label, onChange }: {
  value: number; min: number; max: number; label: string;
  onChange: (v: number) => void;
}) {
  return (
    <div className={styles.stepper}>
      <button onClick={() => onChange(Math.max(min, value - 1))} aria-label="Меньше">
        <Minus size={13} />
      </button>
      <span className={styles.stepperVal}>
        {value}<em>{label}</em>
      </span>
      <button onClick={() => onChange(Math.min(max, value + 1))} aria-label="Больше">
        <Plus size={13} />
      </button>
    </div>
  );
}
