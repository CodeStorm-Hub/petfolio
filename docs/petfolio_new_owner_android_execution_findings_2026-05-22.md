# PetFolio Android New Owner Execution Findings

Date: 2026-05-22  
Device: `emulator-5554`  
Account: `codestromhub@gmail.com`  
Pet created: `Milo`, dog, Labrador Retriever  
Evidence folder: `qa_artifacts/android_new_owner_2026-05-22/`

## Execution Summary

The app was tested as a newly verified pet owner using the connected Android emulator. I logged in, completed first-pet onboarding, created real owner data, and exercised the main app modules end to end.

Live Supabase verification for this account shows the flow created:

| Area | Rows verified |
| --- | ---: |
| Care tasks | 1 |
| Care logs | 1 |
| Weight/health logs | 1 |
| Medical records | 1 |
| Social posts | 1 |
| Comments | 1 |
| Post likes | 1 |
| Match swipes | 1 |
| Marketplace orders | 1 |
| Shops | 1 |

## Actions Performed

### Auth and Onboarding

- Logged in with `codestromhub@gmail.com` after email verification.
- Added first pet:
  - Name: `Milo`
  - Species: Dog
  - Breed: Labrador Retriever
  - Current weight: `12.5 kg`
  - Target weight: `14 kg`
  - Activity selection: Active
- Skipped photo upload and entered PetFolio.

Feedback:

- Login succeeded, but raw Android automation taps were unreliable on custom CTA buttons when the keyboard was active. Pressing the keyboard done action worked.
- Onboarding is clear and fast, but the pet photo step should offer an obvious "Add later" reassurance and maybe a default avatar preview.
- The selected activity appeared as "Active" in onboarding but Nutrition later displayed "Moderate". This looks like an internal value leaking into the UI.

Recommendations:

- Add stable `ValueKey` and semantic labels to all primary form CTAs.
- Ensure activity values use consistent user-facing labels across onboarding, profile, and nutrition.
- Add optional helper text explaining that pet profile data can be edited later.

### Care

- Opened Care dashboard for Milo.
- Added a daily Walk task named `Morning walk`.
- Opened task options and edit sheet.
- Completed the task via swipe.
- Confirmed streak moved to `1 / 1`, `1 day streak`.
- Saw the "First Care Log" badge snackbar.

Feedback:

- The empty state and add-task sheet are practical.
- Swipe-to-complete worked, but it is not discoverable enough for a new owner.
- Task edit/delete actions are tucked behind a menu and are easy to miss.

Recommendations:

- Add a visible checkbox or "Mark done" affordance on task rows in addition to swipe.
- Add a first-use hint for swipe actions.
- Show recent completion history under each task, especially for recurring tasks.

### Nutrition

- Opened Nutrition from Care.
- Reviewed calorie recommendation for Milo.
- Logged a new weight: `12.7 kg`.
- Added a note: `After morning walk good energy`.
- Confirmed recommendation changed from `745 kcal/day` to `753 kcal/day`.

Feedback:

- Weight logging is straightforward and the recommendation updates immediately.
- ADB punctuation input can encode characters literally, so automated test data should avoid punctuation unless using a richer input driver.
- The Nutrition screen displayed the activity as "Moderate" even though onboarding showed "Active".

Recommendations:

- Add a small "why this recommendation?" explanation with weight, activity, and target-weight factors.
- Use the same activity label model across onboarding and nutrition.
- Add trend visualization after at least two logs.

### Medical Vault

- Opened Medical Vault.
- Added a vaccine record:
  - Name: `Rabies vaccine`
  - Dosage: `1 dose`
  - Frequency: `Annual`
  - Notes: `Initial record from new owner setup`
  - Reminders enabled
- Verified the record appears under Vaccines.

Feedback:

- The record type sheet and form are clear.
- A reminder can be enabled while no due date is set, which makes the reminder non-actionable.
- The profile overview later displayed `Rabies vaccine No date Mark done`, which is understandable but not especially helpful.

Recommendations:

- If reminders are enabled, require or strongly prompt for a next due date.
- Add record templates for common vaccines.
- Surface "next due" prominently on the profile and care dashboard.

### Social

- Created a post from Milo:
  - `Milos first day on PetFolio Logged a morning walk and added his rabies record`
- Liked the post.
- Opened post detail.
- Added a comment:
  - `First comment from new owner flow`

Feedback:

- Posting, liking, and commenting worked.
- The post detail showed `Milo Milos first day...`, which feels redundant because the pet name is repeated before content.
- Comments worked after hiding the keyboard; the send action was not obvious in the focused keyboard state.

Recommendations:

- Avoid duplicating pet name in the post detail body.
- Keep the send button visible and semantically labeled when the keyboard is open.
- Add post privacy visibility indicators for new owners.

### Matching

- Opened Match.
- Initial state explained that Match Discovery/location is needed.
- Opened Filters.
- Selected Dog filter.
- Turned on discovery preferences.
- Nearby candidates appeared.
- Liked one candidate.
- Opened Matches & messages; inbox correctly showed no mutual matches yet.

Feedback:

- The empty state explains the dependency on discovery/location.
- The filter sheet is useful, but the discovery toggle lacks a clear label in the accessibility tree.
- Supabase verification still showed `pets.is_discoverable = false` after the deck populated, so the discovery preference path should be reviewed for persistence or naming mismatch.

Recommendations:

- Add explicit visible and semantic text such as "Match Discovery On/Off".
- Confirm the discovery toggle updates the canonical pet discoverability field or clearly separate "filters" from "pet is discoverable".
- Add a confirmation snackbar after discovery is enabled.

### Marketplace

- Opened Market.
- Searched for `salmon`.
- Opened `PetFolio Treat Salmon`.
- Reviewed subscription frequency and quantity controls.
- Added two subscription items to cart.
- Selected Cash on Delivery.
- Placed order successfully.
- Order reference: `BA7B68C2`.

Feedback:

- Search, product detail, subscription discount, cart, COD selection, and order confirmation worked.
- The product detail has a sticky add-to-cart button, but it overlaps visually with lower order-summary content in the UI tree.
- The order confirmation is clear, but there is no immediate "view order details" CTA.

Recommendations:

- Add "View order" beside "Continue shopping".
- Ensure sticky add-to-cart does not obscure totals or summary content on shorter screens.
- Show shop name and delivery estimate in the cart before confirmation.

### Seller

- Opened Seller Dashboard from Milo profile.
- Created a shop:
  - Shop: `Milo Care Supplies`
  - Slug: `milocaresupplies`
  - Description: `Helpful essentials for dogs from a new PetFolio owner`
  - Payment location: Bangladesh
- Entered business details:
  - Business name: `Milo Care Supplies`
  - Address: `Bashundhara Dhaka Bangladesh`
  - Phone: `01712345678`
- Reached document upload.
- Verified continuing without a document shows validation: `Upload at least one document to continue.`
- Opened the Android photo picker for NID upload and stopped before uploading a real document.

Feedback:

- Seller onboarding flows logically from shop profile to business info to documents.
- Document upload validation works.
- The document picker can access user gallery photos; test automation should not upload private images without a controlled test fixture.

Recommendations:

- Provide a sample/test document path in non-production debug builds for QA.
- Make the KYC step clearly explain accepted formats and privacy handling.
- After shop creation, show a persistent "KYC incomplete" checklist.

### Pet Selector and Pet Management

- Opened pet selector.
- Verified Milo is active.
- Opened Manage.
- Opened Milo options.
- Verified actions: Share access, Archive pet.
- Opened Share access and confirmed co-carer invites are coming soon.

Feedback:

- The selector is easy to reach and the active pet is clear.
- "Share access" is visible even though the feature is not implemented.
- Archive is available but destructive; it needs strong confirmation before use.

Recommendations:

- Keep coming-soon actions but mark them disabled until backend support ships.
- Add confirmation and recovery language for Archive.
- Add profile completeness prompts from the selector, such as age, sex, and photo.

### Admin Authorization

- For this non-admin account, the Market Admin action was not visible.
- Router code also redirects `/admin` to `/home` unless `appMetadata.is_admin == true`.

Feedback:

- The non-admin UI correctly hides admin entry points.

Recommendations:

- Add an emulator regression test that tries direct `/admin` navigation and verifies redirect.
- Consider an explicit "Admin access required" screen for deep-link attempts if useful during QA.

## Notable Issues

1. Custom primary buttons are hard to activate reliably through raw adb when keyboard focus is active.
2. Nutrition displays `Moderate` while onboarding displayed `Active` for the chosen activity.
3. Match Discovery populated candidates but backend verification showed Milo `is_discoverable = false`.
4. Badge snackbar appeared after first care log, but the profile Awards tab still said no badges yet during this run.
5. Social post detail duplicates the pet name before the post text.
6. Medical reminders can be enabled without a due date.
7. Seller document upload depends on user gallery contents; automation needs a controlled fixture.

## Overall Recommendation

PetFolio’s core new-owner journey is functional: a verified owner can add a pet, create care/nutrition/medical data, post socially, explore matching, place a COD marketplace order, and start seller onboarding. The biggest improvements should focus on consistency, discoverability, and testability: consistent labels, explicit completion controls, accessible semantic labels, stable test keys, and controlled QA fixtures for image/document uploads.
