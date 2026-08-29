# MediBuddy

MediBuddy is a Flutter app that helps people track their medications: schedules, dosages, and remaining stock, with an AI-powered assistant that flags possible drug interactions and a simple in-app shop for reordering supplies.

## Features

- **Authentication** – Email/password and Google Sign-In, sign up, login, and password reset, backed by Firebase Auth.
- **Medication tracking** – Add, filter (all / low stock / frequency), and sort medications, with a per-medication stock progress bar and low-stock warnings. Data is stored per-user in Cloud Firestore.
- **AI insights** – Sends the user's medication list to a Groq-hosted LLM to surface plain-English drug info and potential interactions between meds.
- **Shop & cart** – Browse a small catalogue of medication-related products, manage a cart, and check out.
- **NETS QR checkout** – Generates a NETS QR code via the NETS sandbox API and listens for real-time payment confirmation over SSE.
- **Profile & theming** – Edit account details and choose an app accent colour, persisted with `shared_preferences`.

## Tech stack

- [Flutter](https://flutter.dev) / Dart
- [Riverpod](https://riverpod.dev) for state management
- [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore)
- [Groq API](https://groq.com/) for AI-generated medication insights
- [NETS QR sandbox API](https://www.nets.com.sg/) for payments

## Project structure

```
lib/
  constants/    # theme/colours
  models/       # data models (Medication, CartItem, AiInsight, ...)
  providers/    # Riverpod providers (auth, medications, AI, NETS, theme)
  screens/      # app screens/pages
  services/     # Firebase, Groq AI, NETS, theme services
  widgets/      # reusable widgets
```

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK ^3.11.5)
- A Firebase project with Auth and Firestore enabled (this repo already includes `lib/firebase_options.dart` and `android/app/google-services.json` for the project's own Firebase app)
- API keys for Groq and the NETS sandbox (see below)

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure API keys

The Groq and NETS API keys are **not** committed to the repo. Copy the example file and fill in your own keys:

```bash
cp env.example.json env.json
```

```json
{
  "GROQ_API_KEY": "your-groq-api-key",
  "NETS_API_KEY": "your-nets-sandbox-api-key",
  "NETS_PROJECT_ID": "your-nets-sandbox-project-id"
}
```

`env.json` is git-ignored. When running from the command line, pass it explicitly:

```bash
flutter run --dart-define-from-file=env.json
```

The VS Code launch configurations in `.vscode/launch.json` already pass `--dart-define-from-file=env.json`, so you can just use "Run and Debug" once `env.json` exists.

### 3. Run the app

```bash
flutter run
```

## Testing

```bash
flutter test
```

## Notes

- The AI insights feature calls a third-party LLM (Groq) and the payment flow uses the NETS **sandbox** environment — no real payments are processed.
- AI-generated medication information is for general reference only and is not medical advice.
