# PetFolio Android Automation Execution Report

Date: 2026-05-22  
Plan executed: `docs/petfolio_android_automation_test_plan_2026-05-22.md`  
Device: `emulator-5554` (`sdk gphone16k x86 64`, Android 17 / API 37)  
App id: `com.example.petfolio`  
Artifact folder: `qa_artifacts/android_automation_2026-05-22/`

## Summary

Executed the Android emulator QA pass using the current debug build and the checked-in `.env` runtime defines. The app installed, launched, initialized Supabase, and resumed an authenticated session for pet `Tommy`.

The pass covered authenticated read-only navigation, scroll checks, route opening, drawers/sheets, and safe form visibility checks. I did not execute destructive or persistent state-changing actions such as creating/deleting pets, publishing posts, sending chat messages, adding cart items, checkout, seller KYC submission, product mutation, admin approvals, moderation resolutions, or shop deletion requests because the run used an existing live authenticated account and no dedicated QA data policy/fixture reset was provided.

## Environment Checks

| Check | Result |
| --- | --- |
| `adb devices` | Passed: `emulator-5554 device` |
| `flutter devices` | Passed: emulator visible as Android 17 / API 37 |
| Supabase DNS from emulator | Passed: `jqyjvhwlcqcsuwcqgcwf.supabase.co` resolved and pinged |
| Runtime defines | Passed: `.env` has `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STRIPE_PUBLISHABLE_KEY` |
| Debug install/run | Passed: `flutter run -d emulator-5554 --dart-define-from-file=.env` built and installed |
| App process log scan | Passed: no app-specific crash, Flutter error, `SocketException`, or `PostgrestException` found |

## Evidence Captured

- 68 UI XML dumps.
- 68 UI summary text files.
- 63 screenshots.
- App-scoped logcat: `qa_artifacts/android_automation_2026-05-22/logcat_petfolio_pid_final.txt`.
- Full logcat: `qa_artifacts/android_automation_2026-05-22/logcat_full.txt`.

## Executed Coverage

### Shell Navigation

| Screen | Result | Evidence examples |
| --- | --- | --- |
| `/home` Pets | Passed | `ui_home_top.txt`, `ui_home_bottom.txt` |
| `/care` | Passed | `ui_care_top.txt`, `ui_care_bottom.txt` |
| `/social` | Passed | `ui_social_top.txt`, `ui_social_bottom.txt` |
| `/matching` | Passed with empty state | `ui_match_top.txt`, `ui_matching_empty_state.txt` |
| `/marketplace` | Passed | `ui_market_top.txt`, `ui_market_bottom.txt` |

### Home And Pet Profile

| Flow | Result |
| --- | --- |
| Home profile overview render | Passed |
| Home tabs: Overview, Health, Care, Awards | Passed |
| Scroll checks across Home tabs | Passed |
| Pet switcher sheet | Passed: showed 4 pets, active pet, switch rows, add pet, manage, sign out |
| Manage pets route | Passed |
| Tommy overflow menu | Passed: showed `Share access` and `Archive pet`; no option selected |

### Care

| Flow | Result |
| --- | --- |
| Care dashboard | Passed |
| Date strip render | Passed |
| Empty daily tasks state | Passed: `No tasks for today` |
| Nutrition banner route | Passed |
| Nutrition screen | Passed: showed weight trend, kcal recommendation, `Log Weight` action |
| Medical vault banner route | Passed |
| Medical vault screen | Passed: showed vaccines, medications, vet visits empty sections |

### Social

| Flow | Result |
| --- | --- |
| Social feed render and scroll | Passed |
| Create post route | Passed: composer loaded with photo picker, text field, public post controls |
| Messages action | Passed: navigated to full-screen matching inbox |
| Post detail route | Passed: first feed item opened detail with comments and input controls |
| Notifications route | Passed: empty activity state rendered |
| Social profile route | Passed: Tommy profile loaded with stats, edit/share profile actions |

### Matching

| Flow | Result |
| --- | --- |
| Discovery screen | Passed with empty state |
| Discovery data | Empty for active pet: app logged `[DiscoveryCandidates] ... count=0` |
| Preferences sheet | Passed |
| Inbox route | Passed: new matches and existing conversations rendered |
| Chat route | Passed: existing chat opened |
| Chat input | Passed: entered local draft `QA_draft_not_sent`; send was not tapped |

### Marketplace

| Flow | Result |
| --- | --- |
| Marketplace render and scroll | Passed |
| Shop storefront | Passed: `PetFolio Official` storefront opened and product grid rendered |
| Product detail | Passed: product page showed subscription toggle, frequency, quantity, summary, add-to-cart |
| Cart | Passed: empty cart state rendered |
| Admin entry from marketplace | Passed |

### Seller

| Flow | Result |
| --- | --- |
| Seller dashboard entry from Home | Passed |
| Seller dashboard render | Passed: shop `PetFolio`, verified status, product/order counters |
| Seller quick actions visible | Passed: Add product, Manage products, View orders, Edit shop |
| Seller danger zone visible | Passed: Request shop deletion visible; not tapped |

### Admin

| Flow | Result |
| --- | --- |
| Admin route authorization | Passed for current user |
| Dashboard tab | Passed |
| KYC tab | Passed |
| Ledger tab | Passed |
| Orders tab | Passed |
| Moderation tab | Passed |
| Shops tab | Passed |
| Drawer navigation | Passed |

## Blocked Or Deferred Coverage

These were intentionally not executed on the live existing account:

- Auth destructive flows: sign out, new registration, first-run onboarding.
- Pet mutations: active pet switch, add pet, edit pet, archive pet.
- Care mutations: add/edit/delete task, toggle task completion, log weight, create medical records.
- Social mutations: publish post, like/unlike, comment, report, follow/unfollow.
- Matching mutations: pass/greet/like/super, send chat message.
- Marketplace mutations: add to cart, quantity changes, checkout, Stripe PaymentSheet.
- Seller mutations: create/edit/delete products, edit shop, submit KYC, start Stripe onboarding, request shop deletion.
- Admin mutations: approve/reject KYC, resolve reports, update orders, approve/reject shop deletion.

To execute those safely, create or identify disposable QA buyer/seller/admin accounts and seed rows prefixed with `QA_AUTOMATION_20260522`, or run against a Supabase branch/QA project with a reset script.

## Findings

1. No app crash or app-scoped runtime exception occurred during this run.
2. The prior emulator DNS blocker is not present in this run; the emulator resolved and reached the Supabase host.
3. Matching discovery is empty for active pet `Tommy`; the UI handles this with a clear empty state.
4. Care dashboard for `Tommy` has no tasks for today; the UI handles this and exposes add-task and nutrition/medical-vault navigation.
5. Cart is empty for the current account; cart empty state renders correctly.
6. Seller dashboard shows zero products and zero pending orders for the current shop, but the seller quick actions are reachable.
7. The Social Messages header action navigates to the full-screen matching inbox as expected. This route has no bottom nav, so automation must back out before using shell tab finders.

## Next Execution Slice

Run a controlled mutating pass after fixture setup:

1. Seed QA users: buyer, seller, second matching user, admin.
2. Seed QA pets with discoverable state and locations.
3. Seed seller shop/products/orders and social posts.
4. Execute mutating scenarios with cleanup by QA prefix and captured before/after Supabase snapshots.

