import { createClient as createSupabaseClient, type SupabaseClient } from '@supabase/supabase-js';

// Single browser client (SPA) — session persisted in localStorage, auto-refresh.
let _client: SupabaseClient | null = null;

export function createClient(): SupabaseClient {
  if (_client) return _client;
  _client = createSupabaseClient(
    import.meta.env.VITE_SUPABASE_URL as string,
    import.meta.env.VITE_SUPABASE_ANON_KEY as string,
    {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    },
  );
  return _client;
}
