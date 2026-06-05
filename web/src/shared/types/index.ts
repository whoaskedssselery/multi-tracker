// ─── Data types — mirror of Flutter/Drift schema (camelCase, matching toJson) ─

export interface Profile {
  id: number;
  name: string;
  birthDate: string | null;
  heightCm: number | null;
  targetWeightKg: number | null;
  units: 'kg' | 'lbs';
  updatedAt: string;
}

export interface AppPreferences {
  id: number;
  themeMode: 'light' | 'dark' | 'system';
  aiModel: string;
  notificationsEnabled: boolean;
  updatedAt: string;
}

export interface WeightEntry {
  id: number;
  date: string;       // ISO midnight UTC
  value: number;
  note: string | null;
  createdAt: string;
}

export interface Goal {
  id: number;
  label: string;
  startValue: number;
  currentValue: number;
  targetValue: number;
  unit: string;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}

export interface TaskItem {
  id: number;
  body: string;
  dueAt: string | null;
  notifyAt: string | null;
  recurrence: 'none' | 'daily' | 'weekly' | 'weekdays' | 'monthly';
  parentRecurringId: number | null;
  priority: 'none' | 'low' | 'mid' | 'high';
  group: 'today' | 'tomorrow' | 'week' | 'later' | 'none';
  isDone: boolean;
  completedAt: string | null;
  notificationId: number | null;
  createdAt: string;
  updatedAt: string;
}

export interface NoteItem {
  id: number;
  title: string;
  body: string;
  isPinned: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface WorkoutTemplate {
  id: number;
  name: string;
  color: number;     // ARGB int
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}

export interface ExerciseTemplate {
  id: number;
  workoutTemplateId: number;
  name: string;
  sortOrder: number;   // -1 = archived
  defaultSetsJson: string; // JSON array
  createdAt: string;
  updatedAt: string;
}

export interface ScheduleSlot {
  id: number;
  workoutTemplateId: number;
  dayOfWeek: number; // 1=Mon..7=Sun
}

export interface SetEntry {
  id: number;
  exerciseTemplateId: number;
  date: string;
  setIndex: number;
  weightKg: number;
  reps: number;
  note: string | null;
  createdAt: string;
}

export interface WorkoutNote {
  id: number;
  workoutTemplateId: number;
  date: string;
  body: string;
  createdAt: string;
  updatedAt: string;
}

export interface AiAnalysis {
  id: number;
  exerciseTemplateId: number;
  date: string;
  verdict: 'progress' | 'plateau' | 'regress' | 'loading';
  explanation: string | null;
  createdAt: string;
}

export interface ChatMessage {
  id: number;
  role: 'user' | 'assistant';
  content: string;
  contextFilter: 'all' | 'train' | 'weight' | 'tasks';
  citedRefsJson: string;
  createdAt: string;
}

// ─── Snapshot — matches Flutter exportSnapshot() exactly ─────────────────────

export interface AppSnapshot {
  snapshotVersion: number;
  schemaVersion: number;
  exportedAt: string;
  tables: {
    profile: Profile[];
    app_preferences: AppPreferences[];
    goals: Goal[];
    weight_entries: WeightEntry[];
    workout_templates: WorkoutTemplate[];
    exercise_templates: ExerciseTemplate[];
    schedule_slots: ScheduleSlot[];
    set_entries: SetEntry[];
    workout_notes: WorkoutNote[];
    ai_analyses: AiAnalysis[];
    task_items: TaskItem[];
    note_items: NoteItem[];
    chat_messages: ChatMessage[];
  };
  secrets?: {
    groqApiKey?: string;
  };
}

// ─── UI helpers ───────────────────────────────────────────────────────────────

export type TaskGroup = TaskItem['group'];
export type TaskPriority = TaskItem['priority'];
export type ThemeMode = 'light' | 'dark' | 'system';

export interface SyncStatus {
  configured: boolean;
  signedIn: boolean;
  email: string | null;
  busy: boolean;
  lastSynced: Date | null;
  error: string | null;
  status: string | null;
}
