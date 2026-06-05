'use client';

import { useEffect, useRef, useCallback } from 'react';
import { useAppStore } from '@frontend/shared/store';
import { SyncService } from '@frontend/shared/lib/sync/sync-service';
import { createClient } from '@frontend/shared/lib/supabase/client';
import { formatSyncTime } from '@frontend/shared/lib/utils/format';
import toast from 'react-hot-toast';

const DEBOUNCE_MS = 3_000;
const GROQ_KEY_LS = 'groq_api_key';

export function useSync() {
  const store = useAppStore();
  const svcRef = useRef<SyncService | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const inFlightRef = useRef(false);

  // Initialise service once
  if (!svcRef.current) {
    svcRef.current = new SyncService(createClient());
  }
  const svc = svcRef.current;

  const exportSnap = useCallback(() => store.exportSnapshot(), [store]);
  const hasData = useCallback(() => store.hasUserData(), [store]);

  // в”Ђв”Ђ Push (debounced, only if changed) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  const schedulePush = useCallback(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(async () => {
      if (inFlightRef.current) { schedulePush(); return; }
      const user = await svc.getUser();
      if (!user) return;

      inFlightRef.current = true;
      store.setSyncStatus({ busy: true, status: 'РЎРѕС…СЂР°РЅРµРЅРёРµвЂ¦' });
      try {
        const ts = await svc.pushIfChanged(user.id, exportSnap());
        store.clearDirty();
        if (ts) store.setSyncStatus({ lastSynced: ts });
      } catch { /* silent */ } finally {
        store.setSyncStatus({ busy: false, status: null });
        inFlightRef.current = false;
      }
    }, DEBOUNCE_MS);
  }, [svc, store, exportSnap]);

  // в”Ђв”Ђ Reconcile (pull if remote newer, push if dirty) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  const reconcile = useCallback(async () => {
    if (inFlightRef.current) return;
    const user = await svc.getUser();
    if (!user) return;

    inFlightRef.current = true;
    store.setSyncStatus({ busy: true, status: 'РЎРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏвЂ¦' });
    try {
      if (store.isDirty) {
        await svc.pushSafe(user.id, exportSnap(), hasData());
        store.clearDirty();
      } else {
        const { outcome, snapshot } = await svc.reconcile(exportSnap(), hasData());
        if (outcome === 'pulled' && snapshot) {
          store.hydrate(snapshot);
          // Restore Groq key from localStorage if not in snapshot
          if (!snapshot.secrets?.groqApiKey) {
            const storedKey = localStorage.getItem(GROQ_KEY_LS);
            if (storedKey) store.setGroqApiKey(storedKey);
          }
          toast.success('Р”Р°РЅРЅС‹Рµ СЃРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°РЅС‹');
        }
      }
      const ts = svc.getLastSyncTs();
      if (ts) store.setSyncStatus({ lastSynced: ts });
    } catch (err) {
      const msg = friendlyError(err);
      store.setSyncStatus({ error: msg });
    } finally {
      store.setSyncStatus({ busy: false, status: null });
      inFlightRef.current = false;
    }
  }, [svc, store, exportSnap, hasData]);

  // в”Ђв”Ђ Manual sync в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  const syncNow = useCallback(async () => {
    if (inFlightRef.current) return;
    const user = await svc.getUser();
    if (!user) return;

    inFlightRef.current = true;
    store.setSyncStatus({ busy: true, error: null, status: 'РЎРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏвЂ¦' });
    try {
      if (store.isDirty) {
        await svc.pushSafe(user.id, exportSnap(), hasData());
        store.clearDirty();
      } else {
        const { outcome, snapshot } = await svc.reconcile(exportSnap(), hasData());
        if (outcome === 'pulled' && snapshot) {
          store.hydrate(snapshot);
          if (!snapshot.secrets?.groqApiKey) {
            const storedKey = localStorage.getItem(GROQ_KEY_LS);
            if (storedKey) store.setGroqApiKey(storedKey);
          }
        } else {
          await svc.pushSafe(user.id, exportSnap(), hasData());
          store.clearDirty();
        }
      }
      const ts = svc.getLastSyncTs();
      if (ts) {
        store.setSyncStatus({ lastSynced: ts });
        toast.success(`РЎРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°РЅРѕ ${formatSyncTime(ts)}`);
      }
    } catch (err) {
      const msg = friendlyError(err);
      store.setSyncStatus({ error: msg });
      toast.error(msg);
    } finally {
      store.setSyncStatus({ busy: false, status: null });
      inFlightRef.current = false;
    }
  }, [svc, store, exportSnap, hasData]);

  // в”Ђв”Ђ Boot: init user + initial reconcile в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  useEffect(() => {
    let mounted = true;

    const init = async () => {
      const supabase = createClient();

      // Restore Groq key
      const storedKey = localStorage.getItem(GROQ_KEY_LS);
      if (storedKey) store.setGroqApiKey(storedKey);

      const { data: { user } } = await supabase.auth.getUser();
      if (!mounted || !user) return;

      store.setUser(user.id, user.email ?? null);
      store.setSyncStatus({ signedIn: true, email: user.email ?? null });

      // Initial reconcile
      await reconcile();
    };

    init();

    // Listen to auth changes
    const supabase = createClient();
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (!mounted) return;
      if (event === 'SIGNED_OUT') {
        store.setUser(null, null);
        store.reset();
        svc.clearLocalSync();
      } else if (session?.user) {
        store.setUser(session.user.id, session.user.email ?? null);
        store.setSyncStatus({ signedIn: true, email: session.user.email ?? null });
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // в”Ђв”Ђ Re-sync on tab focus в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  useEffect(() => {
    const onFocus = () => {
      if (store.sync.signedIn) reconcile();
    };
    window.addEventListener('focus', onFocus);
    return () => window.removeEventListener('focus', onFocus);
  }, [reconcile, store.sync.signedIn]);

  // в”Ђв”Ђ Auto-push on dirty в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  useEffect(() => {
    if (store.isDirty && store.sync.signedIn) schedulePush();
  }, [store.isDirty, store.sync.signedIn, schedulePush]);

  return { syncNow };
}

function friendlyError(err: unknown): string {
  const s = String(err);
  if (s.includes('NetworkError') || s.includes('fetch') || s.includes('timeout'))
    return 'РќРµС‚ СЃРѕРµРґРёРЅРµРЅРёСЏ вЂ” СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓСЋ РїРѕР·Р¶Рµ';
  return s.slice(0, 120);
}



