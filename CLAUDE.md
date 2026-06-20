# CLAUDE.md

Guidance for Claude Code in this repository.

## Mission

**Petfolio** is a Flutter mobile app combining a social network, pet discovery/matching platform, health tracker, and e-commerce marketplace. Backend: **Supabase** (auth + data). State: **Riverpod**. Navigation: **GoRouter**. Payments: **Stripe**.

## Where to look (progressive disclosure)

Read only the file(s) relevant to the current task — do not load all of these at once.

| Working on... | Read |
|---|---|
| Feature folder structure, state management (Riverpod) | `.claude/rules/flutter-architecture.md` |
| Dart/Flutter style, lint, formatting, testing conventions | `.claude/rules/flutter-rules.md` |
| Supabase access, RLS, repositories, migrations | `.claude/rules/supabase-backend.md` |
| Building or styling a screen/widget, animations, Material 3 | `.claude/skills/flutter-ui-ux/SKILL.md` |
| "How does X relate to Y", architecture/dependency questions | `graphify-out/` — see **graphify** below |

## Claude Code Rules

- **Progressive disclosure**: only read files explicitly required for the immediate task. Do not scan the entire `lib/` folder to "understand the app." If working on Pet Care UI, read `lib/features/care/` and the shared widgets it depends on — nothing else.
- **Respect ignores**: adhere to `.claudeignore`. Never read generated files (`*.g.dart`, `*.freezed.dart`), build/cache dirs, or native platform folders unless explicitly asked.
- **Conciseness**: keep explanations brief; don't re-output unchanged code.
- **No mock data**: bind UI directly to Supabase schemas or Riverpod controllers.
- **Verification**: always run `flutter analyze` and `flutter test` after changes.

## Key Files

- Entry point: `lib/main.dart`
- Router: `lib/core/router.dart`
- Theme/colors: `lib/core/theme/app_theme.dart`, `app_colors.dart`
- Features: `lib/features/<feature>/` — each has `data/`, `domain/`, `presentation/`

## Setup & Environment

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

`.env` keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STRIPE_PUBLISHABLE_KEY`, `NVIDIA_API_KEY` (AI care-routine suggestions). Dev defaults are hardcoded in `main.dart`; production builds must override via `--dart-define`.

## Common Commands

```bash
flutter pub get                                              # install deps
dart run build_runner build --delete-conflicting-outputs    # after @freezed/@JsonSerializable/@riverpod changes
flutter analyze                                              # static analysis
flutter test                                                 # tests
flutter run                                                  # run app
flutter build apk --debug | --release                       # build
```

## Documentation Policy

No inline comments, dartdocs (`///`), or standalone doc files in implementation work, unless explicitly requested. See "Project Overrides" at the top of `.claude/rules/flutter-rules.md`.

## Session State (`progress.md`)

After completing a distinct feature phase, update `progress.md` at the repo root with a concise bulleted summary (what shipped, new data contracts/models, next step), then tell the user: "Phase complete — please run `/remember` to save tokens before proceeding."

## Sequential Execution

When implementing a full feature, follow this order, pausing for confirmation between steps: (1) Supabase SQL schema & RLS, (2) Dart models, (3) repositories, (4) Riverpod controllers, (5) UI. Details in `.claude/rules/supabase-backend.md`.

## graphify

Knowledge graph at `graphify-out/` — god nodes, community structure, cross-file relationships.

- For codebase questions, run `graphify query "<question>"` (or `graphify path "<A>" "<B>"`, `graphify explain "<concept>"`) before grepping — these return a scoped subgraph, usually much smaller than raw source browsing.
- Read `graphify-out/GRAPH_REPORT.md` only for broad architecture review.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- `/graphify` is wired up via `.claude/CLAUDE.md` → `.claude/skills/graphify/SKILL.md`.
