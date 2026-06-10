'use client';

import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import type {
  Profile, AppPreferences, WeightEntry, Goal, TaskItem, NoteItem,
  WorkoutTemplate, ExerciseTemplate, ScheduleSlot, SetEntry,
  WorkoutNote, ChatMessage, AppSnapshot, SyncStatus,
} from '@/shared/types';
import { todayMidnight, dayKey } from '@/shared/lib/utils/format';

// ─── Default values ───────────────────────────────────────────────────────────

const defaultProfile = (): Profile => ({
  id: 1, name: 'User', birthDate: null, heightCm: null,
  targetWeightKg: null, units: 'kg', updatedAt: new Date().toISOString(),
});

const defaultPrefs = (): AppPreferences => ({
  id: 1, themeMode: 'system', aiModel: 'llama-3.3-70b-versatile',
  notificationsEnabled: true, updatedAt: new Date().toISOString(),
});

// ─── State ────────────────────────────────────────────────────────────────────

interface AppState {
  // ── Auth ──────────────────────────────────────────────────────────────────
  userId: string | null;
  userEmail: string | null;

  // ── Data ──────────────────────────────────────────────────────────────────
  profile: Profile;
  preferences: AppPreferences;
  weightEntries: WeightEntry[];
  goals: Goal[];
  tasks: TaskItem[];
  notes: NoteItem[];
  workoutTemplates: WorkoutTemplate[];
  exerciseTemplates: ExerciseTemplate[];
  scheduleSlots: ScheduleSlot[];
  setEntries: SetEntry[];
  workoutNotes: WorkoutNote[];
  chatMessages: ChatMessage[];

  // ── Groq key (localStorage, not in snapshot) ──────────────────────────────
  groqApiKey: string | null;

  // ── Sync ──────────────────────────────────────────────────────────────────
  sync: SyncStatus;
  isDirty: boolean;

  // ── Loading ───────────────────────────────────────────────────────────────
  hydrated: boolean;

  // ── Sequence counters (for new IDs when offline) ──────────────────────────
  _nextId: { [table: string]: number };
}

// ─── Actions ──────────────────────────────────────────────────────────────────

interface AppActions {
  // Auth
  setUser: (id: string | null, email: string | null) => void;

  // Hydration (called after pulling snapshot from Supabase)
  hydrate: (snap: AppSnapshot) => void;
  reset: () => void;

  // Snapshot export
  exportSnapshot: () => AppSnapshot;
  hasUserData: () => boolean;

  // Dirty tracking
  markDirty: () => void;
  clearDirty: () => void;

  // Sync status
  setSyncStatus: (patch: Partial<SyncStatus>) => void;

  // Groq key
  setGroqApiKey: (key: string | null) => void;

  // Profile
  updateProfile: (patch: Partial<Profile>) => void;

  // Preferences
  updatePreferences: (patch: Partial<AppPreferences>) => void;

  // Weight
  addWeightEntry: (value: number, date?: string, note?: string) => void;
  deleteWeightEntry: (id: number) => void;

  // Goals
  addGoal: (goal: Omit<Goal, 'id' | 'sortOrder' | 'createdAt' | 'updatedAt'>) => void;
  updateGoal: (id: number, patch: Partial<Goal>) => void;
  deleteGoal: (id: number) => void;

  // Tasks
  addTask: (task: Pick<TaskItem, 'body' | 'group' | 'priority' | 'notifyAt'>) => void;
  updateTask: (id: number, patch: Partial<TaskItem>) => void;
  toggleTaskDone: (id: number) => void;
  deleteTask: (id: number) => void;

  // Notes
  addNote: (title?: string, body?: string) => number;
  updateNote: (id: number, patch: Partial<NoteItem>) => void;
  deleteNote: (id: number) => void;

  // Train
  addWorkoutTemplate: (name: string, color?: number) => number;
  updateWorkoutTemplate: (id: number, patch: { name?: string; color?: number }) => void;
  deleteWorkoutTemplate: (id: number) => void;
  setTemplateExercises: (
    templateId: number,
    exs: { id?: number; name: string; sets: number; reps: number }[],
  ) => void;
  setScheduleSlot: (dayOfWeek: number, templateId: number | null) => void;
  logSets: (
    exerciseId: number,
    date: string,
    sets: { weightKg: number; reps: number }[],
  ) => void;

  // Chat
  addChatMessage: (role: 'user' | 'assistant', content: string, filter: string) => void;
  clearChatHistory: (filter?: string) => void;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function nextId(state: AppState, table: string): number {
  const current = state._nextId[table] ?? 1;
  state._nextId[table] = current + 1;
  return current;
}

function now(): string { return new Date().toISOString(); }

// Newest-first by date, then by entry time / id so same-day entries keep the
// order they were recorded (87.3 before 87.4 → 87.4 is the latest).
function byDateDesc(
  a: { date: string; createdAt: string; id: number },
  b: { date: string; createdAt: string; id: number },
): number {
  const d = new Date(b.date).getTime() - new Date(a.date).getTime();
  if (d !== 0) return d;
  const c = new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  if (c !== 0) return c;
  return b.id - a.id;
}

// Date fields can arrive from two sources with different encodings:
//   • Flutter/Drift snapshot → epoch number (ms, or seconds on older builds)
//   • web-created rows        → ISO-8601 string
// All UI code assumes ISO strings, so normalise every date field to ISO on the
// way in (hydrate). Strings pass through untouched; nulls stay null.
const DATE_KEYS = [
  'date', 'createdAt', 'updatedAt', 'dueAt', 'notifyAt', 'completedAt', 'birthDate',
] as const;

function toIso(v: unknown): unknown {
  if (typeof v === 'number' && Number.isFinite(v)) {
    const ms = v < 1e11 ? v * 1000 : v; // tolerate epoch-seconds vs ms
    return new Date(ms).toISOString();
  }
  return v;
}

function normRows<T>(rows: T[] | undefined): T[] {
  return (rows ?? []).map((r) => {
    const o = { ...(r as Record<string, unknown>) };
    for (const k of DATE_KEYS) if (o[k] != null) o[k] = toIso(o[k]);
    return o as T;
  });
}

// ─── Store ────────────────────────────────────────────────────────────────────

const initialSync: SyncStatus = {
  configured: true,
  signedIn: false,
  email: null,
  busy: false,
  lastSynced: null,
  error: null,
  status: null,
};

export const useAppStore = create<AppState & AppActions>()(
  immer((set, get) => ({
    // ── Initial state ──────────────────────────────────────────────────────
    userId: null,
    userEmail: null,
    profile: defaultProfile(),
    preferences: defaultPrefs(),
    weightEntries: [],
    goals: [],
    tasks: [],
    notes: [],
    workoutTemplates: [],
    exerciseTemplates: [],
    scheduleSlots: [],
    setEntries: [],
    workoutNotes: [],
    chatMessages: [],
    groqApiKey: null,
    sync: initialSync,
    isDirty: false,
    hydrated: false,
    _nextId: {},

    // ── Auth ──────────────────────────────────────────────────────────────
    setUser: (id, email) => set((s) => {
      s.userId = id;
      s.userEmail = email;
      s.sync.signedIn = id !== null;
      s.sync.email = email;
    }),

    // ── Hydration ─────────────────────────────────────────────────────────
    hydrate: (snap) => set((s) => {
      const t = snap.tables;
      // Normalise all date fields (Flutter sends epoch numbers) → ISO strings.
      s.profile = normRows(t.profile)[0] ?? defaultProfile();
      s.preferences = normRows(t.app_preferences)[0] ?? defaultPrefs();
      s.weightEntries = normRows(t.weight_entries).sort(byDateDesc);
      s.goals = normRows(t.goals).sort((a, b) => a.sortOrder - b.sortOrder);
      s.tasks = normRows(t.task_items).sort(
        (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime(),
      );
      s.notes = normRows(t.note_items).sort((a, b) => {
        if (a.isPinned !== b.isPinned) return a.isPinned ? -1 : 1;
        return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
      });
      s.workoutTemplates = normRows(t.workout_templates);
      s.exerciseTemplates = normRows(t.exercise_templates);
      s.scheduleSlots = t.schedule_slots ?? [];
      s.setEntries = normRows(t.set_entries);
      s.workoutNotes = normRows(t.workout_notes);
      s.chatMessages = normRows(t.chat_messages).sort(
        (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime(),
      );

      // Restore Groq key from snapshot secrets
      if (snap.secrets?.groqApiKey) {
        s.groqApiKey = snap.secrets.groqApiKey;
        try { localStorage.setItem('groq_api_key', snap.secrets.groqApiKey); } catch { /* ignore */ }
      }

      // Compute next IDs
      const ids = {
        weight: Math.max(0, ...s.weightEntries.map(e => e.id)) + 1,
        goals:  Math.max(0, ...s.goals.map(e => e.id)) + 1,
        tasks:  Math.max(0, ...s.tasks.map(e => e.id)) + 1,
        notes:  Math.max(0, ...s.notes.map(e => e.id)) + 1,
        templates: Math.max(0, ...s.workoutTemplates.map(e => e.id)) + 1,
        exercises: Math.max(0, ...s.exerciseTemplates.map(e => e.id)) + 1,
        schedule:  Math.max(0, ...s.scheduleSlots.map(e => e.id)) + 1,
        sets:   Math.max(0, ...s.setEntries.map(e => e.id)) + 1,
        chat:   Math.max(0, ...s.chatMessages.map(e => e.id)) + 1,
      };
      s._nextId = { ...s._nextId, ...ids };
      s.hydrated = true;
    }),

    reset: () => set((s) => {
      s.profile = defaultProfile();
      s.preferences = defaultPrefs();
      s.weightEntries = [];
      s.goals = [];
      s.tasks = [];
      s.notes = [];
      s.workoutTemplates = [];
      s.exerciseTemplates = [];
      s.scheduleSlots = [];
      s.setEntries = [];
      s.workoutNotes = [];
      s.chatMessages = [];
      s.groqApiKey = null;
      s.isDirty = false;
      s.hydrated = false;
      s._nextId = {};
    }),

    // ── Snapshot export ────────────────────────────────────────────────────
    exportSnapshot: () => {
      const s = get();
      const snap: AppSnapshot = {
        snapshotVersion: 1,
        schemaVersion: 3,
        exportedAt: now(),
        tables: {
          profile: [s.profile],
          app_preferences: [s.preferences],
          goals: s.goals,
          weight_entries: s.weightEntries,
          workout_templates: s.workoutTemplates,
          exercise_templates: s.exerciseTemplates,
          schedule_slots: s.scheduleSlots,
          set_entries: s.setEntries,
          workout_notes: s.workoutNotes,
          ai_analyses: [],
          task_items: s.tasks,
          note_items: s.notes,
          chat_messages: s.chatMessages,
        },
        secrets: {
          groqApiKey: s.groqApiKey ?? undefined,
        },
      };
      return snap;
    },

    hasUserData: () => {
      const s = get();
      return (
        s.weightEntries.length > 0 ||
        s.tasks.length > 0 ||
        s.notes.length > 0 ||
        s.goals.length > 0 ||
        s.workoutTemplates.length > 0 ||
        (s.profile.name !== 'User' && s.profile.name !== '') ||
        s.profile.heightCm !== null ||
        s.profile.targetWeightKg !== null
      );
    },

    // ── Dirty tracking ─────────────────────────────────────────────────────
    markDirty: () => set((s) => { s.isDirty = true; }),
    clearDirty: () => set((s) => { s.isDirty = false; }),

    // ── Sync ──────────────────────────────────────────────────────────────
    setSyncStatus: (patch) => set((s) => {
      Object.assign(s.sync, patch);
    }),

    // ── Groq key ──────────────────────────────────────────────────────────
    setGroqApiKey: (key) => set((s) => {
      s.groqApiKey = key;
      try {
        if (key) localStorage.setItem('groq_api_key', key);
        else localStorage.removeItem('groq_api_key');
      } catch { /* ignore */ }
    }),

    // ── Profile ───────────────────────────────────────────────────────────
    updateProfile: (patch) => set((s) => {
      Object.assign(s.profile, patch, { updatedAt: now() });
      s.isDirty = true;
    }),

    // ── Preferences ───────────────────────────────────────────────────────
    updatePreferences: (patch) => set((s) => {
      Object.assign(s.preferences, patch, { updatedAt: now() });
      s.isDirty = true;
    }),

    // ── Weight ────────────────────────────────────────────────────────────
    addWeightEntry: (value, date, note) => set((s) => {
      const id = nextId(s, 'weight');
      const entry: WeightEntry = {
        id, value,
        date: date ?? todayMidnight(),
        note: note ?? null,
        createdAt: now(),
      };
      s.weightEntries.unshift(entry);
      s.weightEntries.sort(byDateDesc);
      s.isDirty = true;
    }),

    deleteWeightEntry: (id) => set((s) => {
      s.weightEntries = s.weightEntries.filter(e => e.id !== id);
      s.isDirty = true;
    }),

    // ── Goals ─────────────────────────────────────────────────────────────
    addGoal: (g) => set((s) => {
      const id = nextId(s, 'goals');
      s.goals.push({
        ...g, id,
        sortOrder: s.goals.length,
        createdAt: now(), updatedAt: now(),
      });
      s.isDirty = true;
    }),

    updateGoal: (id, patch) => set((s) => {
      const idx = s.goals.findIndex(g => g.id === id);
      if (idx >= 0) { Object.assign(s.goals[idx], patch, { updatedAt: now() }); }
      s.isDirty = true;
    }),

    deleteGoal: (id) => set((s) => {
      s.goals = s.goals.filter(g => g.id !== id);
      s.isDirty = true;
    }),

    // ── Tasks ─────────────────────────────────────────────────────────────
    addTask: (t) => set((s) => {
      const id = nextId(s, 'tasks');
      s.tasks.push({
        id, ...t,
        dueAt: null, recurrence: 'none', parentRecurringId: null,
        isDone: false, completedAt: null, notificationId: null,
        notifyAt: t.notifyAt ?? null,
        createdAt: now(), updatedAt: now(),
      });
      s.isDirty = true;
    }),

    updateTask: (id, patch) => set((s) => {
      const idx = s.tasks.findIndex(t => t.id === id);
      if (idx >= 0) { Object.assign(s.tasks[idx], patch, { updatedAt: now() }); }
      s.isDirty = true;
    }),

    toggleTaskDone: (id) => set((s) => {
      const idx = s.tasks.findIndex(t => t.id === id);
      if (idx >= 0) {
        const t = s.tasks[idx];
        t.isDone = !t.isDone;
        t.completedAt = t.isDone ? now() : null;
        t.updatedAt = now();
      }
      s.isDirty = true;
    }),

    deleteTask: (id) => set((s) => {
      s.tasks = s.tasks.filter(t => t.id !== id);
      s.isDirty = true;
    }),

    // ── Notes ─────────────────────────────────────────────────────────────
    addNote: (title = 'Без названия', body = '') => {
      let newId = 0;
      set((s) => {
        const id = nextId(s, 'notes');
        newId = id;
        s.notes.unshift({
          id, title, body, isPinned: false,
          createdAt: now(), updatedAt: now(),
        });
        s.isDirty = true;
      });
      return newId;
    },

    updateNote: (id, patch) => set((s) => {
      const idx = s.notes.findIndex(n => n.id === id);
      if (idx >= 0) {
        Object.assign(s.notes[idx], patch, { updatedAt: now() });
        // Re-sort: pinned first, then by updatedAt desc
        s.notes.sort((a, b) => {
          if (a.isPinned !== b.isPinned) return a.isPinned ? -1 : 1;
          return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
        });
      }
      s.isDirty = true;
    }),

    deleteNote: (id) => set((s) => {
      s.notes = s.notes.filter(n => n.id !== id);
      s.isDirty = true;
    }),

    // ── Train ───────────────────────────────────────────────────────────
    addWorkoutTemplate: (name, color = 0xFF6B8F71) => {
      let newId = 0;
      set((s) => {
        const id = nextId(s, 'templates');
        newId = id;
        s.workoutTemplates.push({
          id, name, color,
          sortOrder: s.workoutTemplates.length,
          createdAt: now(), updatedAt: now(),
        });
        s.isDirty = true;
      });
      return newId;
    },

    updateWorkoutTemplate: (id, patch) => set((s) => {
      const idx = s.workoutTemplates.findIndex(t => t.id === id);
      if (idx >= 0) Object.assign(s.workoutTemplates[idx], patch, { updatedAt: now() });
      s.isDirty = true;
    }),

    deleteWorkoutTemplate: (id) => set((s) => {
      const exIds = new Set(
        s.exerciseTemplates.filter(e => e.workoutTemplateId === id).map(e => e.id),
      );
      s.setEntries = s.setEntries.filter(se => !exIds.has(se.exerciseTemplateId));
      s.exerciseTemplates = s.exerciseTemplates.filter(e => e.workoutTemplateId !== id);
      s.scheduleSlots = s.scheduleSlots.filter(sl => sl.workoutTemplateId !== id);
      s.workoutTemplates = s.workoutTemplates.filter(t => t.id !== id);
      s.isDirty = true;
    }),

    // Reconciles a template's exercises: id==null → insert, id!=null → update,
    // removed-but-logged → archive (sortOrder -1, keeps history), removed-and-
    // never-logged → hard delete. Mirrors Flutter setTemplateExercises.
    setTemplateExercises: (templateId, exs) => set((s) => {
      const existing = s.exerciseTemplates.filter(e => e.workoutTemplateId === templateId);
      const keepIds = new Set(exs.filter(e => e.id != null).map(e => e.id as number));
      const toDelete = new Set<number>();
      for (const ex of existing) {
        if (keepIds.has(ex.id)) continue;
        const logged = s.setEntries.some(se => se.exerciseTemplateId === ex.id);
        if (logged) ex.sortOrder = -1; // archive
        else toDelete.add(ex.id);
      }
      if (toDelete.size) {
        s.exerciseTemplates = s.exerciseTemplates.filter(e => !toDelete.has(e.id));
      }
      exs.forEach((e, i) => {
        const n = e.sets < 1 ? 1 : e.sets;
        const setsJson = JSON.stringify(
          Array.from({ length: n }, () => ({ weight: 0.0, reps: e.reps })),
        );
        if (e.id != null) {
          const idx = s.exerciseTemplates.findIndex(x => x.id === e.id);
          if (idx >= 0) {
            Object.assign(s.exerciseTemplates[idx], {
              name: e.name, sortOrder: i, defaultSetsJson: setsJson, updatedAt: now(),
            });
          }
        } else {
          const id = nextId(s, 'exercises');
          s.exerciseTemplates.push({
            id, workoutTemplateId: templateId, name: e.name, sortOrder: i,
            defaultSetsJson: setsJson, createdAt: now(), updatedAt: now(),
          });
        }
      });
      s.isDirty = true;
    }),

    setScheduleSlot: (dayOfWeek, templateId) => set((s) => {
      s.scheduleSlots = s.scheduleSlots.filter(sl => sl.dayOfWeek !== dayOfWeek);
      if (templateId != null) {
        const id = nextId(s, 'schedule');
        s.scheduleSlots.push({ id, workoutTemplateId: templateId, dayOfWeek });
      }
      s.isDirty = true;
    }),

    // Overwrites all sets for an exercise on a given calendar day.
    logSets: (exerciseId, date, sets) => set((s) => {
      const key = dayKey(date);
      s.setEntries = s.setEntries.filter(
        se => !(se.exerciseTemplateId === exerciseId && dayKey(se.date) === key),
      );
      sets.forEach((st, i) => {
        const id = nextId(s, 'sets');
        s.setEntries.push({
          id, exerciseTemplateId: exerciseId, date,
          setIndex: i, weightKg: st.weightKg, reps: st.reps,
          note: null, createdAt: now(),
        });
      });
      s.isDirty = true;
    }),

    // ── Chat ──────────────────────────────────────────────────────────────
    addChatMessage: (role, content, filter) => set((s) => {
      const id = nextId(s, 'chat');
      s.chatMessages.push({
        id, role, content,
        contextFilter: filter as 'all' | 'train' | 'weight' | 'tasks',
        citedRefsJson: '[]',
        createdAt: now(),
      });
      s.isDirty = true;
    }),

    clearChatHistory: (filter) => set((s) => {
      if (!filter) {
        s.chatMessages = [];
      } else {
        s.chatMessages = s.chatMessages.filter(m => m.contextFilter !== filter);
      }
      s.isDirty = true;
    }),
  })),
);

// ─── Selectors ────────────────────────────────────────────────────────────────

export const selectActiveTasks = (s: AppState) =>
  s.tasks.filter(t => !t.isDone);

export const selectDoneTasks = (s: AppState) =>
  s.tasks.filter(t => t.isDone);

export const selectTasksByGroup = (group: string) => (s: AppState) =>
  s.tasks.filter(t => !t.isDone && t.group === group);

export const selectPinnedNotes = (s: AppState) =>
  s.notes.filter(n => n.isPinned);

export const selectRegularNotes = (s: AppState) =>
  s.notes.filter(n => !n.isPinned);

export const selectRecentWeightEntries = (limit = 30) => (s: AppState) =>
  s.weightEntries.slice(0, limit);



