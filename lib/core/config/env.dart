/// Build-time configuration, injected via `--dart-define`.
///
/// `useMockData` routes every repository to its in-memory mock implementation
/// so the app is demoable with no backend running. It now defaults to **false**
/// — the app talks to the real FastAPI backend described in PLAN_backend.md,
/// and mocks are opt-in via `--dart-define=USE_MOCK_DATA=true`.
class Env {
  const Env._();

  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);

  /// Uses the backend's local auth shortcut (`AUTH_DEV_MODE=true` server-side)
  /// instead of Cognito: the app sends `X-Dev-User: <identifier>:` and the API
  /// resolves it against `employees.cognito_sub` / `customers.cognito_sub`,
  /// which `scripts/seed.py` seeds with each account's email.
  ///
  /// This exists because dealer staff are admin-provisioned in Cognito, so a
  /// freshly seeded database has no pool users to sign in as. Set this to false
  /// once the pool is populated and real OTP sign-in takes over.
  static const bool authDevMode =
      bool.fromEnvironment('AUTH_DEV_MODE', defaultValue: true);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // The pool ID, app client ID, and region are public identifiers, not secrets:
  // the app client is deliberately created without a secret (a mobile app cannot
  // keep one), so these ship inside every build anyway. Defaulting them here
  // means sign-in works without remembering three --dart-define flags; override
  // any of them for a different pool.
  static const String cognitoUserPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
    defaultValue: 'ap-northeast-2_5OjZyNjRh',
  );

  static const String cognitoAppClientId = String.fromEnvironment(
    'COGNITO_APP_CLIENT_ID',
    defaultValue: '33t4of8grvorv51stcaoq366f1',
  );

  /// Must match the pool's region — it forms the Cognito endpoint host.
  static const String cognitoRegion = String.fromEnvironment(
    'COGNITO_REGION',
    defaultValue: 'ap-northeast-2',
  );

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
