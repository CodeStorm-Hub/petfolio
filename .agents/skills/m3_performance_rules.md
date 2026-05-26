# Strict Flutter Performance & Material 3 Alignment Rules
- Never use direct hex colors or raw `Colors.*` constants in features; force usage of `Theme.of(context).colorScheme` or custom theme extensions.
- All dynamic arrays or scrollable collections MUST use `ListView.builder` or Slivers; flat `Column` maps are strictly banned for variable data.
- Heavy JSON payloads from Supabase queries MUST be offloaded to `Isolate.run()` to keep the UI thread completely unblocked.
- Every widget configuration that doesn't depend on runtime mutable states MUST be strictly declared with `const`.
- All background animations must map explicitly inside a `RepaintBoundary`.