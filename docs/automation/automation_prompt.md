# Claude Code Refined Prompt: Comprehensive Android Automation Testing & UI/UX Audit for PetFolio

Copy and paste the prompt below into **Claude Code** (running in the PetFolio repository root) to initiate the automated testing process.

---

```markdown
Role: Senior Mobile QA Automation Engineer & Flutter UI/UX Expert
System: Android Emulator (emulator-5554)
MCP Tools Available: `mobile-mcp`, `marionette-mcp`, `supabase`, `chrome-devtools-mcp`
Project Target: PetFolio (Flutter, Supabase Backend, GoRouter Navigation, Riverpod State)

You are tasked with executing a comprehensive Android App automation testing session, visual UI/UX audit, and backend synchronization review for the PetFolio application. The Flutter app has Marionette bindings integrated in debug builds (`marionette_flutter`), which allows you to inspect widgets, perform precise taps, double-taps, enters, and scrolls without Appium's Flutter limitation.

CRITICAL REQUIREMENT: Do NOT use mock placeholder text (e.g., "test", "asdf", "123"). You must use real-life data and scenarios that mimic actual users, pets, and marketplace shops. Follow the walkthrough and execute all available operations on each module.

---

### Phase 1: Setup & Connection
1. **Device Identification**:
   - Check if the Android emulator `emulator-5554` is active using `mobile-mcp` (`mobile_list_available_devices`) or standard `adb devices` via shell.
2. **App Compilation & Launch**:
   - Launch the Flutter app in debug mode on the emulator with environment variables loaded:
     ```bash
     flutter run --dart-define-from-file=.env -d emulator-5554
     ```
   - Monitor the console logs. Locate the Dart VM Service URI (WebSocket URL), which typically matches `ws://127.0.0.1:PORT/.../ws`.
3. **Establish Marionette Session**:
   - Invoke `marionette-mcp`'s `connect` tool using the WebSocket URL. Verify connection by fetching interactive elements.

---

### Phase 2: Core Module Walkthrough & Real-Life Test Scenarios

For each module listed below, perform the actions, dump the UI structure, capture screenshots, and verify database changes in Supabase (using the `supabase` MCP tool or direct SQL inspection).

#### 1. Authentication & Onboarding Module
* **Scenario**: A user logs in and manages their active pet profile.
* **Actions**:
  - Locate the login screen fields (`login_email`, `login_password`, `login_cta`).
  - Attempt login with invalid format (`invalidemail`) and empty form. Validate that the UI displays format and validation errors.
  - Submit the form using real credentials (email: `syed.reza181@gmail.com` / password: provided via environment).
  - **Onboarding / Switch Pet**:
    - Tap the active pet avatar switcher pill in the top header.
    - Open the bottom sheet of the pet list, and tap on another pet (e.g., "Tommy" or "Ziggy") to switch context. Verify that providers (care tasks, appointments) invalidate and reload the UI.
    - Try navigating to `/onboarding` to add a new pet with real-life parameters (e.g., Name: "Montu", Species: "Dog", Breed: "Golden Retriever", Age: "3 years", Activity Level: "Active"). Test the "Skip" button (`app_tutorial_skip`).
- **Database Verification**:
  - Confirm that the user's FCM device token is successfully synced in the `user_fcm_devices` table.

#### 2. Care & Health Dashboard Module
* **Scenario**: Tracking daily habits, streaks, and uploading health vaults for a pet.
* **Actions**:
  - Navigate to the **Care** tab (`/care`).
  - Verify layout rendering of the daily streak progress ring (Snapchat/Fitness style).
  - Interact with daily task checkboxes (e.g., `care_task_check_<id>`). Toggle a nutrition task like "Morning Kibble" or a medical task like "Rabies Booster".
  - **Optimistic UI Check**: Verify that the task status toggles immediately in the UI and writes to `care_logs` with a popping confetti overlay on completion.
  - **Medical Vault**:
    - Navigate to `/care/health`. Scroll vertically to view records.
    - Add a mock medical record: Title: "Rabies Vaccination Certificate", Carrier/Provider: "Happy Paws Vet Clinic", Record Type: "Vaccine". Simulate file uploading (or specify dummy URL).
  - **Nutrition Tracker**:
    - Navigate to `/care/nutrition`. Track weight and verify the weight logs chart. Log a real value (e.g., "12.5 kg").
  - **Appointments**:
    - Navigate to `/appointments`. Select a clinic (e.g., "Greenwood Animal Hospital").
    - Open the calendar, select a Friday afternoon time slot, and book an appointment.
- **Database Verification**:
  - Check the `care_logs`, `care_streaks`, `medical_vault`, `pet_weight_logs`, and `appointments` tables to verify rows are correctly updated or created.

#### 3. Social Hub & Communities Module
* **Scenario**: Interacting with social content and sharing stories.
* **Actions**:
  - Navigate to the **Social** tab (`/social`).
  - Perform vertical scrolling to stress-test the infinite-scroll feed. Check for frame drops or UI stuttering.
  - Find a post, double-tap to like, and verify the like heart animation.
  - Open the emoji picker on a story/post, apply a real-life reaction (e.g., ❤️ or 🔥), and verify the UI state updates.
  - **Story Viewer**:
    - Tap a story ring in the horizontal carousel. Open `StoryViewerScreen` (`/social/stories`), verify that the progress bar runs, and swipe right/down.
  - **Post Creation**:
    - Tap the create-post action button (`/social/create-post`).
    - Type a real caption: "Montu enjoying his morning run at Central Park! 🐾🌞". Add a mockup image and publish.
  - **Communities**:
    - Navigate to `/social/communities`. Open a community (e.g., "Retriever Parents").
    - Tap join and publish a post inside the community forum.
- **Database Verification**:
  - Verify rows in `posts`, `post_likes`, `story_reactions`, and `community_members` are created.

#### 4. Pet Discovery & Matching Module
* **Scenario**: Swiping candidates for playdates and starting a real-time chat.
* **Actions**:
  - Navigate to the **Match** tab (`/matching`).
  - Grant location permissions. Verify location-based discovery candidates load (e.g., distance tags "Within 2 miles").
  - Swipe candidates horizontally, or tap the swipe controls: pass (`✕` / key `match_action_pass`) and like (`🐾` / key `match_action_like`).
  - Perform a mutual swipe to trigger the Match Celebration overlay.
  - **Realtime Messaging**:
    - Navigate to `/matching/inbox`. Select a conversation thread (e.g., with "Coco").
    - Type a real message: "Hey! Down for a playdate at Central Park this Saturday?". Send and verify that the message is instantly updated in the chat window, and that typing indicators react.
- **Database Verification**:
  - Check the `swipes`, `matches`, `chat_threads`, and `chat_messages` tables. Confirm that message read receipts and location updates sync correctly to Supabase.

#### 5. Multi-Vendor Marketplace Module
* **Scenario**: Buying supplies from multiple shops and fulfilling orders as a vendor.
* **Actions**:
  - **Buyer Flow**:
    - Navigate to the **Market** tab (`/marketplace`). Scroll horizontally through categories and deals.
    - Tap a product card (e.g., "Interactive Feather Wand" or "Organic Kibble") to open product details. Read reviews, submit a 5-star rating with the review text: "Excellent quality, my dog loves it!".
    - Tap "Add to Cart" and verify the flight animation.
    - Navigate to the Cart Screen (`/marketplace/cart`). Verify items are grouped by vendor shop (e.g., "PetFolio Official" vs. "Monty's Treats").
    - Tap "Checkout [Shop Name]" (shop-by-shop checkout). Verify that Stripe payment sheet or Cash On Delivery (COD) initializes.
  - **Seller Vendor Flow**:
    - Navigate to the Seller Portal (`/seller`). If it crashes or the route is unregistered (e.g., missing `/seller`), report this immediately.
    - Setup a shop: Name: "Monty's Treats", Slug: "montys-treats", Description: "Freshly baked organic dog treats and cookies".
    - Connect Stripe: Tap "Connect with Stripe" -> redirects to browser for Stripe Connect onboarding -> complete KYC -> returns to app.
    - Manage Products: Open Product List -> Add a product: Name: "Baked Salmon Cookies", Price: "$8.99", Category: "Food", Inventory Count: "50", Image URL: upload or specify valid URL.
    - Fulfill Orders: Open Order Queue -> Select a pending order -> change status to "Shipped" -> input Carrier: "FedEx", Tracking Number: "9876543210", and Tracking URL: `https://fedex.com/track/9876543210`.
- **Database Verification**:
  - Verify cart grouping state. Check database tables `shops`, `products`, `marketplace_orders`, and `product_reviews` for successful writes.

#### 6. Admin Portal Module
* **Scenario**: Admin moderation and seller KYC approvals.
* **Actions**:
  - Navigate to `/admin`.
  - Open the navigation drawer and browse through Dashboard, KYC reviews, Ledgers, Moderation, Orders, and Shops.
  - Select an onboarding request for "Monty's Treats" in the KYC list, and approve it.
- **Database Verification**:
  - Verify that `shops.is_verified` is set to `true` and check corresponding `audit_logs`.

---

### Phase 3: Hardware & Device Features Verification
- **Gesture Control**: Verify vertical scrolling (feed, product lists) and horizontal swiping (discovery deck, onboarding, deals carousels).
- **GPS Location**: Check if the location matches mock database values and updates the discovery candidate distance banner.
- **FCM Push Notifications**: Monitor notifications. Check if foreground messages show in the tray and if background handler initializes properly.
- **Animations & Performance**: Analyze transitions (cart bottom sheet slide, match celebrations, task completion haptics/XP overlays). Report any visual clipping, blank layouts, or stuttering.

---

### Phase 4: UI/UX & Backend Gap Analysis
For every component and module, analyze:
1. **Accessibility (Semantics)**: Report interactive elements (buttons, cards, switcher sheets) that lack `Semantics` wrappers, making screen-reading impossible.
2. **Text Styles & Tokens**: Identify if screens utilize hardcoded `TextStyle` literals (e.g., manual font sizes, inline weights) instead of the defined `AppTheme` schema.
3. **Hardcoded Placeholder Data**: Detect where mock placeholders are still used (e.g., cart shipping messages, deal banners) instead of real Supabase models.
4. **Backend/Security Gaps**: Locate direct table modifications in UI controllers (such as direct table `UPDATE` calls bypassing SECURITY DEFINER RPCs) or missing RLS policy checking.

---

### Phase 5: Deliverables & Formatting

Create a comprehensive report named `QA_AUTOMATION_REPORT.md` at the root of the workspace.
Structure the report as follows:
- **Executive Summary**: Core highlights, total test cases passed/failed, and top critical issues.
- **Module Execution Table**: Columns: Module, Feature, Test Action, Marionette Keys Used, Result (PASS/FAIL/CRASH), Screen Capture Filename.
- **Accessibility & Semantics Audit**: Detailed list of elements lacking semantic keys and labels.
- **Visual & UI Theme Discrepancies**: Log of hardcoded fonts, colors, and design system deviations.
- **Backend & Database Synchronization Gaps**: Gaps identified between UI state and Supabase tables, including RLS/RPC security recommendations.
- **Logcat / Observatory Warnings**: Critical error stack traces, exceptions, or RenderFlex overflow logs caught during execution.

Ensure you save all screenshots and dumps into the `/qa_artifacts/` directory with clear names matching your report tables.
```
