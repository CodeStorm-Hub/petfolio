---
name: new-feature
description: Scaffold a new Petfolio feature directory with the standard feature-first structure (data/models, data/repositories, presentation/controllers, presentation/widgets, presentation/screens). Use when starting a new feature from scratch.
disable-model-invocation: true
---

# New Feature Scaffold

## Steps

1. Ask the user for the feature name if not provided via args (use snake_case, e.g. `notifications`).

2. Create these directories under `lib/features/<name>/`:
   - `data/models/`
   - `data/repositories/`
   - `presentation/controllers/`
   - `presentation/widgets/`
   - `presentation/screens/`

3. Add an empty `.gitkeep` file to each directory (so git tracks them).

4. Create a stub screen file at `lib/features/<name>/presentation/screens/<name>_screen.dart`:
   ```dart
   import 'package:flutter/material.dart';

   class <NameInPascalCase>Screen extends StatelessWidget {
     const <NameInPascalCase>Screen({super.key});

     @override
     Widget build(BuildContext context) {
       return const Scaffold(
         body: Center(child: Text('<NameInPascalCase>')),
       );
     }
   }
   ```

5. Print the next steps checklist:
   ```
   Feature '<name>' scaffolded. Follow the Petfolio implementation order:
   1. supabase/migrations/ — SQL schema + RLS  (/create-migration)
   2. data/models/         — Freezed model + JsonSerializable
   3. data/repositories/   — Supabase repository class
   4. presentation/controllers/ — Riverpod controller
   5. presentation/screens/     — UI screens
   ```

6. Update `progress.md` — append: `Feature scaffold: <name> created`
