// ─── AI context builder ──────────────────────────────────────────────────────
// Mirrors Flutter core/ai/context_builder.dart. Turns the user's data into a
// compact text preamble scoped to the active filter, so the model answers from
// real data only.

import { dayKey } from '@/shared/lib/utils/format';
import type { WeightEntry, TaskItem, SetEntry, ExerciseTemplate } from '@/shared/types';

export type AiFilter = 'all' | 'train' | 'weight' | 'tasks';

export interface ContextData {
  weightEntries: WeightEntry[];
  tasks: TaskItem[];
  setEntries: SetEntry[];
  exerciseTemplates: ExerciseTemplate[];
}

const WD = ['', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
const PRIO_RANK: Record<string, number> = { high: 0, mid: 1, low: 2, none: 3 };

function fmtW(v: number): string {
  return v === Math.round(v) ? v.toFixed(0) : v.toFixed(1);
}

function todayHeader(): string {
  const d = new Date();
  const iso = ((d.getDay() + 6) % 7) + 1; // 1=Mon..7=Sun
  return `Сегодня: ${dayKey(d.toISOString())} (${WD[iso]})`;
}

function weightContext(d: ContextData): string {
  const entries = [...d.weightEntries]
    .sort((a, b) => b.date.localeCompare(a.date))
    .slice(0, 30);
  if (entries.length === 0) return 'Данных о весе нет.';
  const lines = entries.map(e => `${dayKey(e.date)}: ${fmtW(e.value)} кг`);
  return `Вес (последние ${entries.length} записей, новые первыми):\n${lines.join('\n')}`;
}

function tasksContext(d: ContextData, limit = 50): string {
  const active = d.tasks
    .filter(t => !t.isDone)
    .sort((a, b) => {
      const p = (PRIO_RANK[a.priority] ?? 3) - (PRIO_RANK[b.priority] ?? 3);
      return p !== 0 ? p : a.createdAt.localeCompare(b.createdAt);
    });
  const hasMore = active.length > limit;
  const shown = hasMore ? active.slice(0, limit) : active;
  if (shown.length === 0) return 'Активных задач нет.';
  const lines = shown.map(t => {
    const prio = t.priority === 'none' ? '' : `[${t.priority}] `;
    return `- ${prio}${t.body}`;
  });
  const suffix = hasMore ? '\n(ещё задачи не показаны)' : '';
  return `Активные задачи (${shown.length}${hasMore ? '+' : ''}):\n${lines.join('\n')}${suffix}`;
}

function trainContext(d: ContextData, days = 28): string {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days);
  const cutoffKey = dayKey(cutoff.toISOString());
  const sets = d.setEntries
    .filter(s => dayKey(s.date) >= cutoffKey)
    .sort((a, b) => {
      const dc = b.date.localeCompare(a.date);
      return dc !== 0 ? dc : a.setIndex - b.setIndex;
    });
  if (sets.length === 0) {
    return `Тренировочных данных нет (нет записанных подходов за последние ${days} дней).`;
  }

  const keys = sets.map(s => dayKey(s.date));
  const earliest = keys.reduce((a, b) => (a < b ? a : b));
  const latest = keys.reduce((a, b) => (a > b ? a : b));
  const uniqueDays = new Set(keys).size;

  const nameMap = new Map(d.exerciseTemplates.map(e => [e.id, e.name]));
  // exerciseId → day → ["80×8", …]
  const byEx = new Map<number, Map<string, string[]>>();
  for (const s of sets) {
    const k = dayKey(s.date);
    const perEx = byEx.get(s.exerciseTemplateId) ?? new Map<string, string[]>();
    const perDay = perEx.get(k) ?? [];
    perDay.push(`${fmtW(s.weightKg)}×${s.reps}`);
    perEx.set(k, perDay);
    byEx.set(s.exerciseTemplateId, perEx);
  }

  const lines: string[] = [];
  for (const [exId, perEx] of byEx) {
    lines.push(nameMap.get(exId) ?? `Упражнение ${exId}`);
    for (const [day, reps] of perEx) lines.push(`  ${day}: ${reps.join(', ')}`);
  }
  return `Тренировки (данные с ${earliest} по ${latest}, всего ${uniqueDays} тренировочных дней):\n${lines.join('\n')}`;
}

export function buildContext(filter: AiFilter, d: ContextData): string {
  const ctx =
    filter === 'train' ? trainContext(d)
    : filter === 'weight' ? weightContext(d)
    : filter === 'tasks' ? tasksContext(d)
    : [weightContext(d), tasksContext(d, 20), trainContext(d, 14)].join('\n\n');
  return `${todayHeader()}\n\n${ctx}`;
}
