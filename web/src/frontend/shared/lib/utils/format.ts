import { format, formatDistanceToNow, isToday, isYesterday, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';

export function formatDate(dateStr: string): string {
  const d = parseISO(dateStr);
  if (isToday(d)) return `сегодня ${format(d, 'HH:mm')}`;
  if (isYesterday(d)) return `вчера ${format(d, 'HH:mm')}`;
  return format(d, 'dd.MM.yyyy  HH:mm');
}

export function formatDateShort(dateStr: string): string {
  return format(parseISO(dateStr), 'd MMM', { locale: ru });
}

export function formatDateLabel(dateStr: string): string {
  const d = parseISO(dateStr);
  if (isToday(d)) return 'сегодня';
  if (isYesterday(d)) return 'вчера';
  return format(d, 'dd.MM');
}

export function formatSyncTime(ts: Date): string {
  const diffSec = Math.floor((Date.now() - ts.getTime()) / 1000);
  if (diffSec < 60) return 'только что';
  if (diffSec < 3600) return `${Math.floor(diffSec / 60)} мин назад`;
  if (diffSec < 86400) return `${Math.floor(diffSec / 3600)} ч назад`;
  return format(ts, 'dd.MM HH:mm');
}

export function formatWeight(v: number): string {
  return v % 1 === 0 ? v.toFixed(0) : v.toFixed(1);
}

export function formatChartDate(dateStr: string): string {
  return format(parseISO(dateStr), 'd\nMMM', { locale: ru });
}

export function midnight(date: Date = new Date()): string {
  return new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    .toISOString();
}

export function todayMidnight(): string {
  return midnight();
}

// Calendar-day key (local). Extracts the day a date belongs to in the user's
// timezone — correct for both Flutter-origin dates (ISO without Z → local) and
// web-origin dates (UTC-Z midnight). Used to group/compare workout logs by day.
export function dayKey(dateStr: string): string {
  return format(parseISO(dateStr), 'yyyy-MM-dd');
}

export function dayKeyOf(date: Date): string {
  return format(date, 'yyyy-MM-dd');
}

export function weekdayName(iso: number): string {
  const names = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  return names[iso] ?? '';
}

export function dayWord(n: number): string {
  const mod10 = n % 10, mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'дней';
  if (mod10 === 1) return 'день';
  if (mod10 >= 2 && mod10 <= 4) return 'дня';
  return 'дней';
}

export function taskWord(n: number): string {
  const mod10 = n % 10, mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return 'задач';
  if (mod10 === 1) return 'задача';
  if (mod10 >= 2 && mod10 <= 4) return 'задачи';
  return 'задач';
}

