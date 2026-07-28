/// Runtime configuration, supplied via `--dart-define` (or
/// `--dart-define-from-file`) at build/run time. Never hardcode real
/// Supabase credentials into source.
///
/// Example:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=xxx
class Env {
  static const supabaseUrl = String.fromEnvironment('https://uslcbhozuyyfnencttol.supabase.co');
  static const supabaseAnonKey = String.fromEnvironment('sb_publishable_8ZfvWocrUKREOAwU8CjRdA_qK_jHuT3');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
