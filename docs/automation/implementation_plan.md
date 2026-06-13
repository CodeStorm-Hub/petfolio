# Implementation Plan - PetFolio Comprehensive QA Automation & UI/UX Audit

This plan outlines the steps to build, run, test, and audit the PetFolio Android application using emulator `emulator-5554`, Marionette protocol, and Supabase database.

## User Review Required

> [!IMPORTANT]
> - Ensure the Android emulator `emulator-5554` is booted and responsive before starting the execution.
> - The `.env` file must be present at the workspace root and contain valid Supabase credentials.
> - Direct write queries may be executed on Supabase to verify sync status, or direct SQL inspection via Supabase tool.

## Proposed Steps

### Step 1: Device Detection & Compilation
1. Verify `emulator-5554` is online.
2. Launch the Flutter app using `flutter run --dart-define-from-file=.env -d emulator-5554` in the background and capture output to locate the Dart VM WebSocket URL.
3. Establish Marionette session by connecting to the Dart VM URL.

### Step 2: Module Walks & Interactive Flows
We will walk through the modules sequentially:
1. **Authentication & Onboarding**:
   - Test validation errors with empty/bad format.
   - Login with real credentials (`syed.reza181@gmail.com` / `123qweasd`).
   - Open pet switcher, select different pet, test `/onboarding` UI.
   - Verify `user_fcm_devices` token synchronization.
2. **Care & Health Dashboard**:
   - Go to `/care`, check daily streak ring, toggle nutrition and medical tasks.
   - Navigate to `/care/health`, add medical record, simulate upload.
   - Navigate to `/care/nutrition`, log weight `12.5 kg`.
   - Navigate to `/appointments`, book clinic slot for Friday afternoon.
   - Verify database changes in `care_logs`, `care_streaks`, `medical_vault`, `pet_weight_logs`, and `appointments`.
3. **Social Hub & Communities**:
   - Go to `/social`, test scroll, double-tap post to like, react with emojis.
   - Open `/social/stories`, inspect StoryViewer progress bar.
   - Go to `/social/create-post`, type caption ("Montu enjoying his morning run at Central Park! 🐾🌞"), add post image, publish.
   - Go to `/social/communities`, join "Retriever Parents", publish a post.
   - Verify database changes in `posts`, `post_likes`, `story_reactions`, and `community_members`.
4. **Pet Discovery & Matching**:
   - Go to `/matching`, grant location permissions.
   - Swipe candidates, verify mutual swipe celebration overlay.
   - Open Match Inbox `/matching/inbox`, enter thread with "Coco", send message, verify realtime receipt.
   - Verify database changes in `swipes`, `matches`, `chat_threads`, and `chat_messages`.
5. **Multi-Vendor Marketplace**:
   - Go to `/marketplace`, open product card, add 5-star review, add to cart.
   - Navigate to `/marketplace/cart`, verify vendor-grouped layout.
   - Setup seller shop "Monty's Treats" under `/seller`, onboard Stripe, add product "Baked Salmon Cookies" ($8.99, 50 stock).
   - Change order status in Order Queue to "Shipped" with FedEx tracking.
   - Verify database changes in `shops`, `products`, `marketplace_orders`, and `product_reviews`.
6. **Admin Portal**:
   - Go to `/admin`, review KYC onboarding request for "Monty's Treats" and approve it.
   - Verify `shops.is_verified` is true in Supabase.

### Step 3: Audit & Gap Analysis
1. Analyze accessibility / semantics.
2. Analyze theme usage (hardcoded values vs `AppTheme`).
3. Audit hardcoded mock text vs Supabase-driven data.
4. Review security / RLS policies for table modifications.

### Step 4: Deliverables
- Create `QA_AUTOMATION_REPORT.md` at workspace root detailing executions, bugs, and gaps.
- Save screenshots/dumps to `qa_artifacts` folder.

## Verification Plan

### Manual Verification
- We will monitor ADB logs, check the UI via screenshots, and query Supabase tables to confirm database sync.
