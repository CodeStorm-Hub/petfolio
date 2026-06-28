## 2026-06-28T12:14:42Z
Your identity:
- Archetype: worker
- Role: Auth Migration Specialist
- Working directory: j:\GitHub\petfolio\.agents\worker_milestone_2
- Original parent: Project Orchestrator (9023a2a1-598d-4024-a77b-b352452ad4aa)

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Mission:
Implement Milestone 2: Auth Migration as detailed in:
- j:\GitHub\petfolio\PROJECT.md
- j:\GitHub\petfolio\.agents\explorer_exploration_1\handoff.md
- Proposed files: j:\GitHub\petfolio\.agents\explorer_exploration_1\proposed_auth_controller.dart and proposed_auth_controller_test.dart

Specifically, perform these steps:
1. Create a centralized SupabaseClient provider in j:\GitHub\petfolio\lib\core\providers\supabase_provider.dart using `@Riverpod(keepAlive: true)` that returns `Supabase.instance.client`.
2. Migrate all manual providers in j:\GitHub\petfolio\lib\features\auth\presentation\controllers\auth_controller.dart to Riverpod 2/3 code-generated providers using `@riverpod` / `@Riverpod(keepAlive: true)`. Ensure that `PasswordReset` generated notifier class does not specify type parameters (e.g., `class PasswordReset extends _$PasswordReset` with no state type inside the generic).
3. Consolidate the duplicate `_friendlyAuthError` function in login_screen.dart and registration_screen.dart by extracting it as an extension or static helper (e.g. extension on AuthException) and updating the UI calls to use it.
4. Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
5. Run `dart analyze` to verify clean static analysis.
6. Run auth tests: `flutter test test/features/auth/auth_repository_test.dart` and implement the proposed test file `test/features/auth/auth_controller_test.dart` using the proposed code from explorer, and run it.

Write your changes and verification report to: j:\GitHub\petfolio\.agents\worker_milestone_2\handoff.md
Send a completion message when done.
