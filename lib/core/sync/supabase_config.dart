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
    defaultValue: '', // ← paste Project URL here (or pass --dart-define)
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // ← paste anon public key here
  );

  /// Whether sync is configured at all.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
