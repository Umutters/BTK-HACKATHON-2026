/// API keys ve ortam değişkenleri --dart-define ile sağlanır.
/// Çalıştırma komutu:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
///     --dart-define=GEMINI_API_KEY=AIzaSy...
///
/// VS Code için .vscode/launch.json içindeki "args" dizisine ekleyin.
class AppEnv {
  AppEnv._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Geliştirme sürecinde keylerin tanımlanıp tanımlanmadığını kontrol eder.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      geminiApiKey.isNotEmpty;
}
