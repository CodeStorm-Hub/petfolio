# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Petfolio** is a Flutter mobile app combining a social network, pet discovery/matching platform, health tracker, and e-commerce marketplace. It uses **Supabase** for backend authentication and data, **Riverpod** for state management, **Go Router** for navigation, and **Stripe** for payments.

## Petfolio Project Context
- **Stack**: Flutter, Riverpod (Generator), GoRouter, Supabase.
- **Architecture**: Feature-first (e.g., `lib/features/<feature_name>/`).
- **Styling**: Material 3, Adaptive Design. No hardcoded colors; use `AppTheme` and `AppColors`.

## Claude Code Rules
- **Progressive Disclosure**: Only read the files explicitly required for the immediate task. Do not scan the entire `lib/` folder.
- **Conciseness**: Keep explanations brief. Do not output raw markdown for unchanged code.
- **Verification**: Always run `dart analyze` and `flutter test` after making changes.
- **No Mock Data**: Always bind UI directly to Supabase schemas or Riverpod controllers.

## Development Setup

### Prerequisites
- Flutter 3.11.5+ SDK installed
- Dart 3.11.5+
- Android/iOS development tools (for emulator/device builds)

### Installation
```bash
flutter pub get
```

### Environment Variables
The app uses `--dart-define` for environment configuration. Default values for Supabase are hardcoded in `main.dart` for dev convenience, but **must** be overridden via `--dart-define` for production builds.

**Recommended: use a `.env` file (requires Dart 2.19+):**
```bash
flutter run --dart-define-from-file=.env
```

**.env file format:**
```
SUPABASE_URL=https://jqyjvhwlcqcsuwcqgcwf.supabase.co
SUPABASE_ANON_KEY=<anon-key>
STRIPE_PUBLISHABLE_KEY=pk_test_...
NVIDIA_API_KEY=<nvidia-api-key>   # AI care-routine suggestions (CareRecommendationService)
```

Individual overrides:
```bash
flutter run \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
```

## Codebase Map

```
lib/
  core/
    router.dart            # All GoRouter routes — add new routes here
    theme/
      app_colors.dart      # Colour palette — never hardcode colours, use this
      app_theme.dart       # ThemeData — use AppTheme.light / AppTheme.dark
    services/              # Cross-feature services (e.g. CareRecommendationService)
    widgets/               # Shared UI widgets
  features/
    auth/                  # Sign-in, sign-up, session
    care/                  # Health logs, medical records, streaks, badges
    marketplace/           # Shops, products, cart, checkout, KYC, vendor ledger
    matching/              # Discovery/swipe, mutual matches, chat
    pet_profile/           # Pet creation, onboarding, profile editing
    social/                # Feed, stories, follows, search
    admin/                 # Moderation, KYC review, ledger, COD orders
supabase/
  migrations/              # Timestamped SQL migrations (yyyyMMddHHmmss_name.sql)
  functions/
    create-payment-intent/ # Called by CheckoutController before Stripe confirm
    stripe-onboard-vendor/ # KYC vendor onboarding flow
    stripe-webhook/        # Stripe event handler — has service-role RLS bypass
```

## Common Commands

### Run The App
```bash
flutter run
```

### Code Generation
Run after modifying any `@freezed`, `@JsonSerializable`, or `@riverpod` annotated class:
```bash
dart run build_runner build -d
```

Watch mode:
```bash
dart run build_runner watch
```

### Static Analysis
```bash
flutter analyze
```

### Testing
```bash
flutter test
```

### Build
```bash
flutter build apk --debug    # debug
flutter build apk --release  # release
```

### Supabase Edge Functions
```bash
npx supabase functions deploy <function-name>   # deploy a single function
npx supabase functions deploy                   # deploy all functions
npx supabase db reset                           # apply all migrations locally
```

## Claude Automations

### Skills (user-invocable via `/`)
| Skill | Purpose |
|-------|---------|
| `/create-migration` | Scaffolds a timestamped `supabase/migrations/` SQL file with RLS template |
| `/new-feature` | Scaffolds the full `lib/features/<name>/` directory tree |
| `/flutter-ui-ux` | Flutter UI/UX implementation patterns |

### Agents
| Agent | When to invoke |
|-------|---------------|
| `security-reviewer` | Before merging any PR touching payments, KYC, auth, or admin |

### Pending MCP Setup
- **context7** — live docs for riverpod/go_router/supabase_flutter/stripe (all on fast-moving versions). Install: `claude mcp add context7 -- npx -y @upstash/context7-mcp`

### Hooks (`.claude/settings.json`)
- **PreToolUse** on Edit/Write: blocks accidental edits to `.g.dart` / `.freezed.dart` generated files
- **PostToolUse** on Edit/Write: hints `dart run build_runner build -d` when an annotated source file is saved

### Config Files
- `.claude/settings.json` — project hooks (checked into git, shared)
- `.claude/settings.local.json` — personal tool permissions (gitignored, not shared)
- When writing PowerShell hook commands: always end with `;exit 0` — caught exceptions still set exit code 1 otherwise

## Project Rules & Token Optimization Strategy

### 1. Strict No-Documentation Rule (Implementation Only)
* **Code Only:** Do not write any inline comments, dartdocs (`///`), explanations of code, or standalone documentation files. Focus 100% of your output on functional task implementations.
* **Explicit Override:** You may only write documentation if I explicitly command you with a prompt like "write a documentation file for this." Otherwise, output clean, uncommented code.

### 2. State Management & Session Resets (The `progress.md` Pattern)
* **Maintain State:** You must actively maintain a `progress.md` file at the root of the project.
* **Log & Wipe:** After completing a distinct phase of a feature, update `progress.md` with a concise bulleted summary of what was implemented, any new data contracts/models created, and the immediate next step.
* **Prompt to Clear:** After updating `progress.md`, you MUST explicitly advise the user: "Phase complete — please run (/remember) to save tokens before proceeding to the next phase."

### 3. Aggressive Context Scoping
* **Blind by Default:** Do not scan, grep, or read the entire codebase to "understand the app".
* **Targeted Reads:** Only read files in directories explicitly related to the current task. If working on Pet Care UI, only read `lib/features/care/` and shared widgets in `lib/core/widgets/`.
* **Respect Ignores:** Strictly adhere to the `.claudeignore` file. Never attempt to read UI design dumps, `.g.dart` generated files, or native Android/iOS folders unless explicitly commanded.

### 4. Output Formatting & Boilerplate Reduction
* **Targeted Diffs:** When updating an existing file, do not rewrite the entire file if you only changed one method. Output only the specific class, widget, or method that changed, along with instructions on where to place it.
* **No Unnecessary Explanations:** Do not explain standard Flutter/Dart concepts or write essays about how the code works unless asked.

### 5. Strict Sequential Execution
When given a full feature to implement, execute strictly in this order, waiting for user confirmation or session clears between steps:
1. Supabase SQL Schema & RLS (migration file)
2. Dart Models (Freezed/JsonSerializable)
3. Repositories (Supabase DB / RPC calls)
4. State Management (Controllers)
5. UI/UX Implementation
