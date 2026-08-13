# OBD Health Dashboard — Drop-in Feature (Simulation Data)

A single-bike, rider-facing health dashboard. All data comes from an
in-app simulator (`MockObdService`) — no dataset, no CSV, no training
data. This is intentional: nothing here trains a model, so there's
nothing for a dataset to train. Data only exists as **runtime input**
for the rule engine and AI explanation layer to operate on.

When real OBD hardware works, swap `MockObdService` for a real BLE/BT
parser — nothing else changes, since every layer only depends on the
shared `ObdReading` model and the `Stream<ObdReading>` interface.

## 1. Add these to your `pubspec.yaml`

```yaml
dependencies:
  provider: ^6.1.2
  http: ^1.2.2
```

Run:
```
flutter pub get
```

## 2. Copy the folder

Copy `lib/obd_feature/` into your existing project's `lib/` directory.
Nothing here references your app's existing code, so it won't collide.

## 3. Wire it into your app

See `lib/obd_feature/example_main.dart` for a full working example.
Minimum integration:

```dart
ChangeNotifierProvider(
  create: (_) => DashboardProvider(
    obdService: MockObdService(),
    aiService: AiExplanationService(apiKey: 'YOUR_ANTHROPIC_API_KEY'),
  ),
),
```

Then show `CustomerDashboardScreen()` wherever it should appear (a tab,
a route, a drawer item). This screen is scoped to one bike — the rider's
own — there is no fleet view or other-bike data anywhere on this screen.

## 4. Get your Anthropic API key

Sign up / grab a key at https://console.anthropic.com — the
`AiExplanationService` calls the standard `/v1/messages` endpoint
directly. If your hackathon provisions AWS Bedrock credentials instead,
swap the HTTP call in `ai_explanation_service.dart` for the Bedrock
`InvokeModel` call — the prompt and response-parsing logic stays
conceptually the same, only the request wrapper changes.

**If the API call fails or you have no key handy**, the service falls
back to the deterministic rule-based description automatically — the
demo won't break, it just shows slightly less-polished text.

## 5. Architecture recap (for your pitch to judges)

```
MockObdService  →  Stream<ObdReading>  (single bike, simulated)
                          ↓
                  DashboardProvider
                  ┌───────┴───────┐
            RuleEngine        AiExplanationService
        (instant, local,      (async, LLM-based,
         deterministic,        plain-language
         SAE DTC standards)     communication layer)
                  └───────┬───────┘
                   CustomerDashboardScreen
                   (labeled "Rule-based" vs
                    "AI-generated")
```

- **Rule engine** = ground truth for known/standardized faults. No
  training data needed — correctness comes from the OBD-II spec itself.
- **AI layer** = turns a diagnostic fact into something a rider actually
  understands and can act on. This is composition, not diagnosis —
  there's no model being trained, and no dataset backing it.
- **Mock service** = the ONLY thing that changes when real hardware
  works. Everything else stays exactly as built.

## 6. Honest framing for judges

*"There's no trained model and no dataset in this pipeline — by design.
The rule engine's correctness comes directly from the SAE OBD-II
standard, not from learned patterns. The AI layer is used for
communication (turning a diagnostic fact into a plain-language
explanation), not diagnosis. We're running against simulated telemetry
because our OBD hardware failed during testing; the architecture is
otherwise unchanged from what would run against a real bike."*

## 7. Demo tips

- Use the "Inject fault" buttons on the customer screen to trigger
  alerts reliably on cue — don't rely on random chance during judging.
- Test the whole flow running for 5+ minutes before presenting — make
  sure nothing crashes on a long-running stream.

## 8. Next steps if you have extra time

- Push `latestReading`/`health` to Firestore so a second device (a
  dealer view) can read the same bike's live state — makes the
  "portal" concept demoable across two screens instead of shared local
  state on one device.
