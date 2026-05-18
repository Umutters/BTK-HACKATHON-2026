/// API keys ve ortam değişkenleri --dart-define ile sağlanır.
/// Çalıştırma komutu:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
///     --dart-define=GEMINI_API_KEY=AIzaSy... \
///     --dart-define=GEMINI_API_KEYS=key1,key2,key3
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

  /// İsteğe bağlı çoklu Gemini anahtar havuzu (virgülle ayrılmış).
  /// Örn: --dart-define=GEMINI_API_KEYS=key1,key2,key3
  static const geminiApiKeysRaw = String.fromEnvironment(
    'GEMINI_API_KEYS',
    defaultValue: '',
  );

  static List<String> get geminiApiKeys {
    final keys = geminiApiKeysRaw
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList(growable: false);
    if (keys.isNotEmpty) return keys;
    if (geminiApiKey.isNotEmpty) return [geminiApiKey];
    return const [];
  }

  /// Geliştirme sürecinde keylerin tanımlanıp tanımlanmadığını kontrol eder.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      geminiApiKeys.isNotEmpty;
}
