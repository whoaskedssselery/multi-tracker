// ─── Train domain helpers ────────────────────────────────────────────────────
// Pure functions mirroring the Flutter week-grid logic (week_grid_screen.dart +
// the workout DAO). Kept framework-free so the widget stays thin.

import { dayKey, dayKeyOf } from '@frontend/shared/lib/utils/format';
import type {
  WorkoutTemplate, ExerciseTemplate, ScheduleSlot, SetEntry,
} from '@frontend/shared/types';

export const WD_LABELS = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
export const WD_FULL = [
  'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье',
];
const MO_SHORT = ['янв', 'фев', 'мар', 'апр', 'май', 'июн',
  'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

export interface DayItem {
  dow: number;            // 1=Mon..7=Sun
  date: Date;             // local midnight
  template: WorkoutTemplate | null;
  isDone: boolean;
  isToday: boolean;
  isPast: boolean;
}

/** Monday (local midnight) of the week containing [d]. */
export function weekMonday(d: Date): Date {
  const wd = (d.getDay() + 6) % 7; // 0=Mon..6=Sun
  return new Date(d.getFullYear(), d.getMonth(), d.getDate() - wd);
}

export function addDays(d: Date, n: number): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
}

/** ISO day of week: 1=Mon..7=Sun. */
export function dayOfWeek(d: Date): number {
  return ((d.getDay() + 6) % 7) + 1;
}

export function fmtDate(d: Date): string {
  const p = (v: number) => v.toString().padStart(2, '0');
  return `${p(d.getDate())}.${p(d.getMonth() + 1)}`;
}

export function fmtWeekRange(mon: Date): string {
  const sun = addDays(mon, 6);
  if (mon.getMonth() === sun.getMonth()) {
    return `${mon.getDate()} – ${sun.getDate()} ${MO_SHORT[mon.getMonth()]} ${mon.getFullYear()}`;
  }
  return `${mon.getDate()} ${MO_SHORT[mon.getMonth()]} – `
    + `${sun.getDate()} ${MO_SHORT[sun.getMonth()]} ${mon.getFullYear()}`;
}

/** Weight number → compact string ("80", "80.5"). */
export function fmtW(v: number): string {
  return v === Math.round(v) ? v.toFixed(0) : v.toFixed(1);
}

/** Active (non-archived) exercises of a template, ordered. */
export function activeExercises(
  all: ExerciseTemplate[], templateId: number,
): ExerciseTemplate[] {
  return all
    .filter(e => e.workoutTemplateId === templateId && e.sortOrder >= 0)
    .sort((a, b) => a.sortOrder - b.sortOrder);
}

/** Day → templateId that was actually performed (from the set log). */
function loggedTemplatesByDay(
  exercises: ExerciseTemplate[], sets: SetEntry[],
): Map<string, number> {
  const exToTmpl = new Map(exercises.map(e => [e.id, e.workoutTemplateId]));
  const map = new Map<string, number>();
  for (const s of sets) {
    const tmpl = exToTmpl.get(s.exerciseTemplateId);
    if (tmpl == null) continue;
    const k = dayKey(s.date);
    if (!map.has(k)) map.set(k, tmpl);
  }
  return map;
}

/**
 * The 7 day-items for [weekStart].
 *   • Past days  → what was actually LOGGED (history); plan never applies back.
 *   • Today/future → the scheduled plan.
 */
export function computeDays(
  weekStart: Date,
  slots: ScheduleSlot[],
  templates: WorkoutTemplate[],
  exercises: ExerciseTemplate[],
  sets: SetEntry[],
): DayItem[] {
  const now = new Date();
  const todayMid = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const todayKey = dayKeyOf(todayMid);

  const byId = (id: number | null | undefined) =>
    (id == null ? null : templates.find(t => t.id === id) ?? null);

  const scheduleMap = new Map<number, WorkoutTemplate | null>();
  for (const slot of slots) {
    const t = templates.find(x => x.id === slot.workoutTemplateId);
    if (t) scheduleMap.set(slot.dayOfWeek, t);
  }

  const loggedTmpls = loggedTemplatesByDay(exercises, sets);
  const loggedDays = new Set(loggedTmpls.keys());

  return Array.from({ length: 7 }, (_, i) => {
    const date = addDays(weekStart, i);
    const key = dayKeyOf(date);
    const dow = i + 1;
    const isPast = date.getTime() < todayMid.getTime();
    const tmpl = isPast ? byId(loggedTmpls.get(key)) : (scheduleMap.get(dow) ?? null);
    return {
      dow, date, template: tmpl,
      isDone: loggedDays.has(key),
      isToday: key === todayKey,
      isPast,
    };
  });
}

/** Sets logged on a given day for one exercise, ascending by setIndex. */
export function setsOnDay(
  sets: SetEntry[], exerciseId: number, key: string,
): SetEntry[] {
  return sets
    .filter(s => s.exerciseTemplateId === exerciseId && dayKey(s.date) === key)
    .sort((a, b) => a.setIndex - b.setIndex);
}

/**
 * Exercises (INCLUDING archived) of [templateId] that have logged sets on the
 * day [key] — so a past day renders exactly as it was performed.
 */
export function exercisesLoggedOnDate(
  exercises: ExerciseTemplate[], sets: SetEntry[], templateId: number, key: string,
): ExerciseTemplate[] {
  const ids = new Set(
    sets.filter(s => dayKey(s.date) === key).map(s => s.exerciseTemplateId),
  );
  return exercises
    .filter(e => e.workoutTemplateId === templateId && ids.has(e.id))
    .sort((a, b) => a.sortOrder - b.sortOrder);
}

/** Summary of the most recently logged sets for an exercise, e.g. "80×8 · 80×8". */
export function lastSetsString(sets: SetEntry[], exerciseId: number): string {
  const own = sets.filter(s => s.exerciseTemplateId === exerciseId);
  if (own.length === 0) return '';
  let latest = own[0];
  for (const s of own) if (s.date > latest.date) latest = s;
  const k = dayKey(latest.date);
  return own
    .filter(s => dayKey(s.date) === k)
    .sort((a, b) => a.setIndex - b.setIndex)
    .map(s => `${fmtW(s.weightKg)}×${s.reps}`)
    .join(' · ');
}

/** Parse a template's defaultSetsJson → list of {weight, reps}. */
export function parseDefaultSets(json: string): { weight: number; reps: number }[] {
  try {
    const decoded = JSON.parse(json);
    if (Array.isArray(decoded)) {
      return decoded
        .filter(m => m && typeof m === 'object')
        .map(m => ({
          weight: Number(m.weight) || 0,
          reps: Number(m.reps) || 0,
        }));
    }
  } catch { /* ignore */ }
  return [];
}

/** {sets, reps} a template editor should show for an existing exercise. */
export function setsRepsOf(ex: ExerciseTemplate): { sets: number; reps: number } {
  const list = parseDefaultSets(ex.defaultSetsJson);
  if (list.length === 0) return { sets: 3, reps: 10 };
  return { sets: list.length, reps: list[0].reps || 10 };
}

// Program colour palette (ARGB ints, matching Flutter).
export const PROGRAM_COLORS = [
  0xFF6B8F71, 0xFF6E8FB8, 0xFFC08552, 0xFF7FA08A,
  0xFFB5896E, 0xFF9A7AA0, 0xFFC77B7B, 0xFF5B9AA0,
];

/** ARGB int (0xAARRGGBB) → CSS #RRGGBB. */
export function argbToCss(argb: number): string {
  const rgb = (argb & 0x00ffffff).toString(16).padStart(6, '0');
  return `#${rgb}`;
}
