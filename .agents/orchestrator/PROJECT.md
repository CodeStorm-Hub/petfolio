# Project: PetFolio Codebase and Supabase Backend Audit

## Architecture
- Multi-feature Flutter codebase with Feature-First Architecture (`lib/features/`).
- State Management: Riverpod (Generated Notifiers).
- Backend: Supabase (Auth, DB, RLS, Edge Functions, Triggers, Storage).

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Audit Auth & Profile | Features: auth, profile, settings | None | DONE (Generated auth_audit.md, profile_audit.md, settings_audit.md) |
| 2 | Audit Pet Profile & Activity | Features: pet_profile, activity | None | DONE (Generated pet_profile_audit.md, activity_audit.md) |
| 3 | Audit Care | Features: care | None | DONE (Generated care_audit.md) |
| 4 | Audit Matching & Messaging | Features: matching, messaging | None | DONE (Generated matching_audit.md, messaging_audit.md) |
| 5 | Audit Marketplace & Offers | Features: marketplace, offers | None | DONE (Generated marketplace_audit.md, offers_audit.md) |
| 6 | Audit Social & Communities | Features: social, communities | None | DONE (Generated social_audit.md, communities_audit.md) |
| 7 | Audit Appointments & Admin | Features: appointments, admin, home | None | DONE (Generated appointments_audit.md, admin_audit.md, home_audit.md) |

## Interface Contracts
- Read-only audit: Explores codebase features and Supabase backend components.
- Generates markdown files under `audit_reports/<feature_name>_audit.md`.
