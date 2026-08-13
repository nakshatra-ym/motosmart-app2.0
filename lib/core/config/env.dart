/// Build-time configuration, injected via `--dart-define`.
///
/// `useMockData=true` (the default) routes every repository to its in-memory
/// mock implementation so the app is fully demoable with no backend running.
/// Once PLAN_backend.md's API is deployed, flip it to false and fill in the
/// real values below — no screen or widget code changes needed, only the
/// provider overrides in `core/network` / `core/auth`.
class Env {
  const Env._();

  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String cognitoUserPoolId =
      String.fromEnvironment('COGNITO_USER_POOL_ID', defaultValue: '');

  static const String cognitoAppClientId =
      String.fromEnvironment('COGNITO_APP_CLIENT_ID', defaultValue: '');

  static const String cognitoRegion =
      String.fromEnvironment('COGNITO_REGION', defaultValue: 'ap-south-1');

  /// Optional — powers `lib/obd_feature`'s plain-language fault explanations.
  /// Falls back to a deterministic rule-based description when empty/unset,
  /// so the customer bike-health demo never breaks without a key.
  static const String anthropicApiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

  /// Powers the customer chatbot's live replies via Groq's OpenAI-compatible
  /// API. Falls back to the offline keyword-based reply when empty/unset or
  /// on any request failure, so the chat never breaks without a key.
  ///
  /// The default below is a prototype key baked into the client build —
  /// rotate it and move the call behind a real backend before any public
  /// distribution, since anything shipped in the app bundle is extractable.
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.3-70b-versatile',
  );
}
