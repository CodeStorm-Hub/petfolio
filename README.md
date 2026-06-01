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

## Pending: Kotlin Gradle Plugin (KGP) Migration

Flutter 3.44 introduced built-in Kotlin support in AGP, deprecating the explicit `id("kotlin-android")` + `kotlinOptions {}` pattern. The app and several plugins need to migrate before AGP 9.0 enforces the change.

**Current workaround** — `android/gradle.properties` holds two compat flags added by the Flutter migrator:

```properties
android.builtInKotlin=false
android.newDsl=false
```

These suppress build failures today but will be removed in a future Flutter release.

**Blocked on these plugins releasing KGP-migrated versions:**

| Plugin | Status |
|---|---|
| `image_picker_android` | Awaiting upstream release |
| `shared_preferences_android` | Awaiting upstream release |
| `url_launcher_android` | Awaiting upstream release |
| `share_plus` | Awaiting upstream release |
| `stripe_android` | Awaiting upstream release |

**Migration steps (do all at once, after all plugins above are updated):**

1. `flutter pub upgrade` — pull in the migrated plugin versions
2. In `android/app/build.gradle.kts`:
   - Remove `id("kotlin-android")` from the `plugins {}` block
   - Replace `kotlinOptions { jvmTarget = ... }` inside `android {}` with:
     ```kotlin
     kotlin {
         compilerOptions {
             jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
         }
     }
     ```
3. In `android/gradle.properties`, delete (or flip to `true`) both compat flags:
   ```properties
   android.builtInKotlin=true
   android.newDsl=true
   ```
4. Run `flutter build apk --debug` to confirm a clean build.
