# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Petfolio** is a Flutter mobile app combining a social network, pet discovery/matching platform, health tracker, and e-commerce marketplace. It uses **Supabase** for backend authentication and data, **Riverpod** for state management, **Go Router** for navigation, and **Stripe** for payments.

## Petfolio Project Context
- **Stack**: Flutter, Riverpod (Generator — `@riverpod` annotations, `build_runner` required), GoRouter, Supabase.
- **Architecture**: Feature-first (e.g., `lib/features/<feature_name>/`).
- **Styling**: Material 3, Adaptive Design. No hardcoded colors; use `AppTheme` and `AppColors`.
- **State**: All state via Riverpod `@riverpod`/`@notifier` providers. Do NOT use `ChangeNotifier`, `ValueNotifier`, or `StreamBuilder` directly.

## Key Files
- Entry point: `lib/main.dart`
- Router: `lib/core/router.dart`
- Theme / colors: `lib/core/theme/` — `app_theme.dart`, `app_colors.dart`
- Features: `lib/features/<feature>/` — each has `data/`, `domain/`, `presentation/`
- Coding standards: `.claude/flutter-rules.md` (Dart style, layout, theming rules)

## Claude Code Rules
- **Progressive Disclosure**: Only read the files explicitly required for the immediate task. Do not scan the entire `lib/` folder.
- **Conciseness**: Keep explanations brief. Do not output raw markdown for unchanged code.
- **Verification**: Always run `flutter analyze` and `flutter test` after making changes.
- **No Mock Data**: Always bind UI directly to Supabase schemas or Riverpod controllers.

## Development Setup

### Prerequisites
- Flutter 3.22.0+ SDK installed
- Dart 3.4.0+
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

## Common Commands

### Run The App
```bash
flutter run
```

### Code Generation
Run after modifying any `@freezed`, `@JsonSerializable`, or `@riverpod` annotated class:
```bash
dart run build_runner build --delete-conflicting-outputs
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

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
