// ─── SyncService — TypeScript port of Flutter's SyncService (LWW snapshot) ───

import type { SupabaseClient, User } from '@supabase/supabase-js';
import type { AppSnapshot } from '@frontend/shared/types';

const TABLE = 'app_state';
const LAST_SYNC_KEY = 'multi_tracker_last_sync_ts';
const NET_TIMEOUT_MS = 20_000;

export type SyncOutcome = 'notSignedIn' | 'pulled' | 'pushedInitial' | 'upToDate';

async function runQuery<T>(queryBuilder: PromiseLike<{ data: T; error: unknown }>, timeoutMs: number): Promise<T> {
  const result = await Promise.race([
    Promise.resolve(queryBuilder),
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error('Network timeout')), timeoutMs),
    ),
  ]);
  return result.data as T;
}

function snapshotHasData(data: AppSnapshot | null | undefined): boolean {
  if (!data?.tables) return false;
  const t = data.tables;
  const meaningful = [
    'weight_entries', 'task_items', 'note_items', 'goals',
    'workout_templates', 'exercise_templates', 'set_entries',
  ] as const;
  for (const k of meaningful) {
    if ((t[k] as unknown[])?.length > 0) return true;
  }
  const profile = t.profile?.[0];
  if (profile) {
    const { name, heightCm, targetWeightKg, birthDate } = profile;
    if ((name && name !== 'User') || heightCm || targetWeightKg || birthDate)
      return true;
  }
  return false;
}

function sigOf(snap: AppSnapshot): string {
  return JSON.stringify(snap.tables) + '§' + JSON.stringify(snap.secrets);
}

function getLastSyncTs(): Date | null {
  try {
    const v = localStorage.getItem(LAST_SYNC_KEY);
    return v ? new Date(v) : null;
  } catch { return null; }
}

function setLastSyncTs(ts: Date): void {
  try { localStorage.setItem(LAST_SYNC_KEY, ts.toISOString()); } catch { /* ignore */ }
}

function clearLastSyncTs(): void {
  try { localStorage.removeItem(LAST_SYNC_KEY); } catch { /* ignore */ }
}

export class SyncService {
  private lastSig: string | null = null;

  constructor(private supabase: SupabaseClient) {}

  async getUser(): Promise<User | null> {
    const { data: { user } } = await this.supabase.auth.getUser();
    return user;
  }

  async signIn(email: string, password: string): Promise<void> {
    const { error } = await this.supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (error) throw error;
  }

  async signUp(email: string, password: string): Promise<void> {
    const { error } = await this.supabase.auth.signUp({ email: email.trim(), password });
    if (error) throw error;
  }

  async signOut(): Promise<void> {
    await this.supabase.auth.signOut();
    clearLastSyncTs();
  }

  async remoteUpdatedAt(): Promise<Date | null> {
    const user = await this.getUser();
    if (!user) return null;
    const data = await runQuery<{ updated_at: string } | null>(
      this.supabase.from(TABLE).select('updated_at').eq('user_id', user.id).maybeSingle(),
      NET_TIMEOUT_MS,
    );
    return data?.updated_at ? new Date(data.updated_at) : null;
  }

  async pull(): Promise<AppSnapshot | null> {
    const user = await this.getUser();
    if (!user) return null;
    const data = await runQuery<{ data: AppSnapshot; updated_at: string } | null>(
      this.supabase.from(TABLE).select('data, updated_at').eq('user_id', user.id).maybeSingle(),
      NET_TIMEOUT_MS,
    );
    if (!data?.data) return null;
    this.applyPulledMeta(data.data, data.updated_at);
    return data.data;
  }

  private applyPulledMeta(snap: AppSnapshot, updatedAt: string): void {
    this.lastSig = sigOf(snap);
    setLastSyncTs(new Date(updatedAt));
  }

  async push(userId: string, snap: AppSnapshot): Promise<Date> {
    const now = new Date();
    await runQuery(
      this.supabase.from(TABLE).upsert({
        user_id: userId,
        data: snap,
        updated_at: now.toISOString(),
        device: 'Web',
      }),
      NET_TIMEOUT_MS,
    );
    this.lastSig = sigOf(snap);
    setLastSyncTs(now);
    return now;
  }

  async pushIfChanged(userId: string, snap: AppSnapshot): Promise<Date | null> {
    if (this.lastSig !== null && sigOf(snap) === this.lastSig) return null;
    return this.push(userId, snap);
  }

  async reconcile(
    currentSnap: AppSnapshot,
    hasLocalData: boolean,
  ): Promise<{ outcome: SyncOutcome; snapshot: AppSnapshot | null }> {
    const user = await this.getUser();
    if (!user) return { outcome: 'notSignedIn', snapshot: null };

    const row = await runQuery<{ data: AppSnapshot; updated_at: string } | null>(
      this.supabase.from(TABLE).select('data, updated_at').eq('user_id', user.id).maybeSingle(),
      NET_TIMEOUT_MS,
    );

    if (!row) {
      await this.push(user.id, currentSnap);
      return { outcome: 'pushedInitial', snapshot: null };
    }

    const remoteData = row.data as AppSnapshot | null;
    const remoteTs   = row.updated_at ? new Date(row.updated_at) : null;
    const last       = getLastSyncTs();

    // Always pull when local is empty but remote has data (mirrors iOS Keychain guard)
    if (remoteData && snapshotHasData(remoteData) && !hasLocalData) {
      this.applyPulledMeta(remoteData, row.updated_at);
      return { outcome: 'pulled', snapshot: remoteData };
    }

    const remoteIsNewer = !last || (remoteTs !== null && remoteTs > last);
    if (remoteIsNewer && remoteData) {
      if (!snapshotHasData(remoteData) && hasLocalData) {
        await this.push(user.id, currentSnap);
        return { outcome: 'pushedInitial', snapshot: null };
      }
      this.applyPulledMeta(remoteData, row.updated_at);
      return { outcome: 'pulled', snapshot: remoteData };
    }

    return { outcome: 'upToDate', snapshot: null };
  }

  async pushSafe(userId: string, snap: AppSnapshot, hasLocalData: boolean): Promise<Date | null> {
    if (hasLocalData) return this.pushIfChanged(userId, snap);

    const row = await runQuery<{ data: AppSnapshot } | null>(
      this.supabase.from(TABLE).select('data').eq('user_id', userId).maybeSingle(),
      NET_TIMEOUT_MS,
    );
    const remoteData = row?.data as AppSnapshot | null;
    if (!snapshotHasData(remoteData)) return this.pushIfChanged(userId, snap);
    return null;
  }

  getLastSyncTs(): Date | null {
    return getLastSyncTs();
  }

  clearLocalSync(): void {
    clearLastSyncTs();
    this.lastSig = null;
  }
}



