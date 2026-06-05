'use client';

import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import type {
  Profile, AppPreferences, WeightEntry, Goal, TaskItem, NoteItem,
  WorkoutTemplate, ExerciseTemplate, ScheduleSlot, SetEntry,
  WorkoutNote, ChatMessage, AppSnapshot, SyncStatus,
} from '@frontend/shared/types';
import { todayMidnight } from '@frontend/shared/lib/utils/format';

// в”Ђв”Ђв”Ђ Default values в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

const defaultProfile = (): Profile => ({
  id: 1, name: 'User', birthDate: null, heightCm: null,
  targetWeightKg: null, units: 'kg', updatedAt: new Date().toISOString(),
});

const defaultPrefs = (): AppPreferences => ({
  id: 1, themeMode: 'system', aiModel: 'llama-3.3-70b-versatile',
  notificationsEnabled: true, updatedAt: new Date().toISOString(),
});

// в”Ђв”Ђв”Ђ State в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

interface AppState {
  // в”Ђв”Ђ Auth в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  userId: string | null;
  userEmail: string | null;

  // в”Ђв”Ђ Data в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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

  // в”Ђв”Ђ Groq key (localStorage, not in snapshot) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  groqApiKey: string | null;

  // в”Ђв”Ђ Sync в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  sync: SyncStatus;
  isDirty: boolean;

  // в”Ђв”Ђ Loading в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  hydrated: boolean;

  // в”Ђв”Ђ Sequence counters (for new IDs when offline) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  _nextId: { [table: string]: number };
}

// в”Ђв”Ђв”Ђ Actions в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

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

  // Chat
  addChatMessage: (role: 'user' | 'assistant', content: string, filter: string) => void;
  clearChatHistory: (filter?: string) => void;
}

// в”Ђв”Ђв”Ђ Helpers в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

function nextId(state: AppState, table: string): number {
  const current = state._nextId[table] ?? 1;
  state._nextId[table] = current + 1;
  return current;
}

function now(): string { return new Date().toISOString(); }

// в”Ђв”Ђв”Ђ Store в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

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
    // в”Ђв”Ђ Initial state в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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

    // в”Ђв”Ђ Auth в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    setUser: (id, email) => set((s) => {
      s.userId = id;
      s.userEmail = email;
      s.sync.signedIn = id !== null;
      s.sync.email = email;
    }),

    // в”Ђв”Ђ Hydration в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    hydrate: (snap) => set((s) => {
      const t = snap.tables;
      s.profile = t.profile[0] ?? defaultProfile();
      s.preferences = t.app_preferences[0] ?? defaultPrefs();
      s.weightEntries = [...(t.weight_entries ?? [])].sort(
        (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
      );
      s.goals = [...(t.goals ?? [])].sort((a, b) => a.sortOrder - b.sortOrder);
      s.tasks = [...(t.task_items ?? [])].sort(
        (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime(),
      );
      s.notes = [...(t.note_items ?? [])].sort((a, b) => {
        if (a.isPinned !== b.isPinned) return a.isPinned ? -1 : 1;
        return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
      });
      s.workoutTemplates = t.workout_templates ?? [];
      s.exerciseTemplates = t.exercise_templates ?? [];
      s.scheduleSlots = t.schedule_slots ?? [];
      s.setEntries = t.set_entries ?? [];
      s.workoutNotes = t.workout_notes ?? [];
      s.chatMessages = [...(t.chat_messages ?? [])].sort(
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

    // в”Ђв”Ђ Snapshot export в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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

    // в”Ђв”Ђ Dirty tracking в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    markDirty: () => set((s) => { s.isDirty = true; }),
    clearDirty: () => set((s) => { s.isDirty = false; }),

    // в”Ђв”Ђ Sync в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    setSyncStatus: (patch) => set((s) => {
      Object.assign(s.sync, patch);
    }),

    // в”Ђв”Ђ Groq key в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    setGroqApiKey: (key) => set((s) => {
      s.groqApiKey = key;
      try {
        if (key) localStorage.setItem('groq_api_key', key);
        else localStorage.removeItem('groq_api_key');
      } catch { /* ignore */ }
    }),

    // в”Ђв”Ђ Profile в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    updateProfile: (patch) => set((s) => {
      Object.assign(s.profile, patch, { updatedAt: now() });
      s.isDirty = true;
    }),

    // в”Ђв”Ђ Preferences в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    updatePreferences: (patch) => set((s) => {
      Object.assign(s.preferences, patch, { updatedAt: now() });
      s.isDirty = true;
    }),

    // в”Ђв”Ђ Weight в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    addWeightEntry: (value, date, note) => set((s) => {
      const id = nextId(s, 'weight');
      const entry: WeightEntry = {
        id, value,
        date: date ?? todayMidnight(),
        note: note ?? null,
        createdAt: now(),
      };
      s.weightEntries.unshift(entry);
      s.weightEntries.sort((a, b) =>
        new Date(b.date).getTime() - new Date(a.date).getTime());
      s.isDirty = true;
    }),

    deleteWeightEntry: (id) => set((s) => {
      s.weightEntries = s.weightEntries.filter(e => e.id !== id);
      s.isDirty = true;
    }),

    // в”Ђв”Ђ Goals в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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

    // в”Ђв”Ђ Tasks в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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

    // в”Ђв”Ђ Notes в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    addNote: (title = 'Р‘РµР· РЅР°Р·РІР°РЅРёСЏ', body = '') => {
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

    // в”Ђв”Ђ Chat в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
    addChatMessage: (role, content, filter) => set((s) => {
      const id = nextId(s, 'chat');
      s.chatMessages.push({
        id, role, content,
        contextFilter: filter as 'all' | 'train' | 'weight' | 'tasks',
        citedRefsJson: '[]',
        createdAt: now(),
      });
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

// в”Ђв”Ђв”Ђ Selectors в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

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



