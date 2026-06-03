/// Supabase connection settings.
///
/// Fill these in from your Supabase project:
///   Project Settings → API → Project URL  and  anon / public key.
///
/// The anon key is SAFE to embed in the app — it only grants access that
/// Row Level Security (RLS) policies allow, and our policy scopes every row
/// to its own authenticated user.
///
/// Leave both empty to disable sync entirely (the app runs fully local).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oninslcjnvsttuzctmms.supabase.co',
  );

  // "Publishable" key (new Supabase format) — the public/anon client key.
  // Safe to embed: access is governed by Row Level Security, not the key.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_uKrEjRASD6pspDjgYU1Xiw_d6tNF0M4',
  );

  /// Whether sync is configured at all.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
