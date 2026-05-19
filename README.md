# PetFolio

PetFolio is a feature-rich, social-commerce platform built specifically for pet owners — combining an Instagram-style social network, a Tinder-style pet discovery/matching service (for breeding and playdates), a comprehensive health and daily care tracker, and an e-commerce marketplace for pet products.

## Prerequisites

- Flutter 3.11.5+ / Dart 3.11.5+
- Android or iOS development tools

## Environment Variables

Three variables **must** be provided at build/run time via `--dart-define`. The app will throw a descriptive error on startup if any are missing — there are no hardcoded fallback values.

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anonymous (public) API key |
| `STRIPE_PUBLISHABLE_KEY` | Your Stripe publishable key (`pk_test_…` or `pk_live_…`) |

## Running the App

### Option A — inline flags

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_<key>
```

### Option B — `.env` file (recommended for local dev)

Create a `.env` file at the project root (already in `.gitignore`):

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
STRIPE_PUBLISHABLE_KEY=pk_test_<key>
```

Then run:

```bash
flutter run --dart-define-from-file=.env
```

> `--dart-define-from-file` requires Dart 2.19+.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Regenerate Freezed / JsonSerializable code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on save)
flutter pub run build_runner watch

# Static analysis
flutter analyze

# Run tests
flutter test

# Debug APK
flutter build apk --debug --dart-define-from-file=.env

# Release APK
flutter build apk --release --dart-define-from-file=.env
```

## Architecture

Feature-first structure under `lib/features/`. Core shared code in `lib/core/`. See [CLAUDE.md](CLAUDE.md) and [docs/](docs/) for full architecture, schema, and implementation status.
