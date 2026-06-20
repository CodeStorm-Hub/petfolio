---

# Petfolio — Complete Screen Inventory by Module

**Total screens: 63** across 15 modules.

---

## 1. AUTH

### 1.1 `login_screen.dart`
**Objective:** Entry point for existing users — authenticate with email/password.

**Features & Functionalities:**
- Email + password form with visibility toggle
- Inline error banner for auth failures
- "Forgot password" bottom sheet (`_ForgotPasswordSheet`) — sends Supabase reset email
- Animated entrance via `FadeTransition` + `AnimationController`

**Widgets:**
`AuthBrand`, `AuthCard`, `AuthField` ×2, `VisibilityToggle`, `AuthErrorBanner`, `PrimaryPillButton`, `AuthToggleLink`, `_ForgotPasswordSheet`, `FadeTransition`

**User Flow:**
User opens app → GoRouter redirects unauthenticated user to `/login` → enters credentials → taps Sign In → on success GoRouter redirect to `/home`; on failure `AuthErrorBanner` shows message. Taps "Forgot password" → `_ForgotPasswordSheet` modal → enters email → Supabase sends reset link. Taps "Create one" → `/register`.

**Supabase Backend:**
- `auth.signIn(email, password)` via `authRepositoryProvider`
- `auth.resetPasswordForEmail(email)` via `passwordResetProvider`

---

### 1.2 `registration_screen.dart`
**Objective:** New user account creation.

**Features & Functionalities:**
- Email + password + confirm-password fields with visibility toggles
- Password-match validation
- Inline error banner

**Widgets:**
`AuthBrand`, `AuthCard`, `AuthField` ×3, `VisibilityToggle`s, `AuthErrorBanner`, `PrimaryPillButton`, `AuthToggleLink`

**User Flow:**
`/register` → fills form → taps Create Account → GoRouter auth-state listener redirects to `/home` (or `/care?onboardingComplete=1` if first pet creation pending).

**Supabase Backend:**
- `auth.signUp(email, password)` via `authRepositoryProvider`

---

## 2. PET PROFILE

### 2.1 `onboarding_screen.dart`
**Objective:** 5-step pet-creation wizard for new users or adding another pet.

**Features & Functionalities:**
- Step 0: Hero welcome splash
- Step 1: Species picker (dog/cat/rabbit/bird/fish/other grid)
- Step 2: Pet name input + AI breed identifier (`BreedIdentifierWidget` — NVIDIA Vision API)
- Step 3: Age slider (`BoneSliderWidget`)
- Step 4: Personality traits multi-select (Wrap chips)
- Step 5: Done / loading state
- Animated `_FloatingPaws` background (floating paw icons, `AnimationController.repeat(reverse: true)`)
- Step-progress bar in `_OnboardingHeader`

**Widgets:**
`_OnboardingHeader`, `_FloatingPaws`, `AnimatedSwitcher`, `BreedIdentifierWidget`, `PfCard`, `PrimaryPillButton`, `TailWagLoader`, `BoneSliderWidget`, `FadeTransition`, `SlideTransition`

**User Flow:**
After sign-up (or tapping "Add Pet") → `/onboarding` → walks steps → on complete → `/care?onboardingComplete=1`; skip → `/home`.

**Supabase Backend:**
- `pets` table insert via `petListProvider.notifier.addPet(...)`
- `pet_geo_points` upsert if location granted
- Sets active pet in session via `activePetControllerProvider.notifier.setActivePet(pet)`

---

### 2.2 `pet_profile_screen.dart`
**Objective:** Gamified pet dashboard — XP, streaks, quests, achievements, moments.

**Features & Functionalities:**
- Hero gradient wave banner with pet avatar
- Quick stats trio: streak / XP / care logs
- Daily quests preview card
- Recent moments (placeholder section)
- Recent achievements horizontal row
- Floating toolbar: Edit / Care / Post action pills
- Skeleton loader during data fetch
- Species-tinted theming

**Widgets:**
`WaveHeader`, `PetAvatar`, `_HeroGamifiedBanner`, `_QuickStatsTrio`, `_DailyQuestsCard`, `_DailyQuestRow`, `_MomentPlaceholder`, `_RecentAchievementsRow`, `PfAchievementTile`, `_FloatingToolbar`, `SkeletonLoader`, `PetfolioEmptyState`

**User Flow:**
Tap pet avatar anywhere in app → `/pets/:id` → full gamified dashboard → tap Edit → `/pets/:id/edit`; tap Care → `/care`; tap Post → `/social/create-post`.

**Supabase Backend:**
- `care_streaks` table (realtime via `careStreakRealtimeProvider(pet.id)`)
- `care_tasks` table (today's tasks via `careDashboardProvider`)
- `pet_awards` + `badge_unlocks` tables (via `petAwardsSummaryProvider(pet.id)`)
- `pets` table (via `activePetControllerProvider`)

---

### 2.3 `edit_profile_screen.dart`
**Objective:** Edit all pet profile fields across 5 section cards.

**Features & Functionalities:**
- Photo & Name card: avatar picker + `CachedNetworkImage` + name field
- About card: bio text
- Details card: species (read-only chip) + AI breed identifier + gender segmented button
- Activity card: activity-level chips (Wrap)
- Visibility & Matching card: public/discoverable `SwitchListTile`, GPS sync button
- Save with error banner

**Widgets:**
`_SectionCard` ×5, `_AvatarEditor`, `_LabeledField`, `_SpeciesChip`, `BreedIdentifierWidget`, `_GenderSelector` (`SegmentedButton`), `_ActivityChip`, `SwitchListTile` ×2, `_LocationRow`, `OutlinedButton`, `CheckboxListTile`, `PrimaryPillButton`, `_ErrorBanner`

**User Flow:**
`/pets/:id/edit` → edits fields → Save → upserts pet record → pops back.

**Supabase Backend:**
- `pets` table upsert via `editProfileControllerProvider.notifier.submit(...)`
- `pets.is_discoverable` update via `discoveryVisibilityControllerProvider`
- `pet_geo_points` upsert (GPS) via `petMatchLocationProvider.notifier.syncMatchLocation`

---

### 2.4 `manage_pets_screen.dart`
**Objective:** Reorder, archive, and manage all pets in the user's account.

**Features & Functionalities:**
- Drag-to-reorder list (`SliverReorderableList`)
- `PopupMenuButton` per pet: Archive / Unarchive
- "Add pet" callout card → `/onboarding?mode=add`
- `_ShareAccessSheet` (co-carer invite — future feature, currently disabled)
- Error and empty states

**Widgets:**
`_ManageHeader`, `_PetList`, `_PetRow`, `ReorderableDragStartListener`, `PetAvatar`, `PopupMenuButton`, `_AddPetCallout`, `_ShareAccessSheet`, `_EmptyState`, `_ErrorState`

**User Flow:**
Settings / Me → Manage Pets → drag to reorder → popup to archive → tap Add pet → onboarding flow.

**Supabase Backend:**
- `pets.display_order` bulk update via `petListProvider.notifier.reorder(...)`
- `pets.archived_at` via `petListProvider.notifier.archive(id)` / `unarchive(id)`

---

## 3. HOME

### 3.1 `hub_home_screen.dart`
**Objective:** Pathao-inspired bento-grid hub linking all major features.

**Features & Functionalities:**
- `WaveHeader` with floating pet card (streak pill + level pill)
- Bento grid: Care (2×tall tile) / PawsFeed + Match (stacked) / Market + Vet (row) / All Features CTA
- Quick Actions horizontal scrollable row (Camera, Walk, Meds, Vet, Find Match, Shop)
- Pet Spotlight `PageView` carousel
- Exclusive Deals section (filter chips + promo banner)
- Scroll-driven header fade via `homeScrollProgressProvider` (shell integration)
- `AllFeaturesSheet` bottom sheet listing every feature route

**Widgets:**
`WaveHeader`, `_PetHeroCard`, `_BentoGrid`, `_CareTile`, `_BentoTile`, `_AllTile`, `_QuickActionsRow`, `_QuickActionCard`, `_SpotlightCarousel`, `_DealsSection`, `AllFeaturesSheet`, `TailWagLoader`, `GoogleFonts.sora`

**User Flow:**
App launch (authenticated) → `/home` → bento tiles → routes to respective features. Pet card taps → `/pets/:id`. Quick actions → direct routes.

**Supabase Backend:**
- `care_streaks` realtime (via `careStreakRealtimeProvider`)
- `care_tasks` (today's, via `careDashboardProvider`)
- `pet_awards` (via `petAwardsSummaryProvider`)

---

## 4. SOCIAL

### 4.1 `social_screen.dart`
**Objective:** Main PawsFeed — stories + infinite-scroll post feed.

**Features & Functionalities:**
- Stories row: grouped by pet, animated gradient ring for unviewed, dashed-circle "Add" CTA, sorted unviewed-first
- Post cards: 4:5 image well (`CachedNetworkImage` or `_VideoPostPlayer` auto-play muted), rich caption with hashtag highlighting (lilac), reaction stack, action bar
- Long-press React → emoji picker (🐾❤️🦴⭐) with swipe-to-select
- Double-tap → `ReactionBurst` particle animation
- Infinite scroll pagination (load more sliver)
- Species-tinted `WaveHeader`
- FAB → `/social/create-post`

**Widgets:**
`WaveHeader`, `_StoriesRow`, `_StoryItem`, `PostCard`, `_SocialPostListSliver`, `_LoadMoreSliver`, `SkeletonLoader.feedCard`, `PostCommentsBottomSheet`, `PostOptionsSheet`, `ReactionBurst`, `PetfolioEmptyState`, `DashedCirclePainter`, `VideoPlayer`, `_RichCaption`, `_ReactPickerBtn`

**User Flow:**
Bottom nav → PawsFeed → scroll feed → tap story ring → `/social/story/:petId`; tap post image → `PostDetailScreen`; tap hashtag → `/social/hashtag/:tag`; tap avatar → `/social/profile/:petId`; FAB → create post.

**Supabase Backend:**
- `feed_posts` table (paginated, joined to `pets`, `post_likes`, `post_comments`) via `socialControllerProvider(petId)`
- `stories` table via `storiesProvider`
- `post_likes` upsert via `toggleLike`

---

### 4.2 `social_profile_screen.dart`
**Objective:** Instagram-style pet profile — posts, achievements, follow system.

**Features & Functionalities:**
- Circular gradient-ring avatar, post/follower/following stat columns, bio
- Own-profile: Edit Profile + Share Profile buttons
- Other profile: Follow/Following toggle + Message (→ `openDirectChat`) + Share icon
- Care & Achievements section: streak / XP / logs stat cards + badge horizontal strip
- 3-column image grid (`SliverGrid`)

**Widgets:**
`_ProfileHeader`, `_ProfileAvatar`, `_ProfileStatColumn` ×3, `_AwardsSection`, `_CareStatCard` ×3, `_BadgeHighlight`, `SliverGrid`, `_ActionButton`, `SkeletonLoader`

**User Flow:**
Tap pet avatar or post → `/social/profile/:petId` → tap Follow → toggle; tap Message → `SocialDmScreen`; tap post thumbnail → `PostDetailScreen`.

**Supabase Backend:**
- `pets` table via `petByIdProvider(petId)`
- `feed_posts` (profile grid) via `socialProfilePostsProvider(petId)`
- `pet_follows` (follow status) via `followStatusProvider(petId)`
- `care_streaks`, `pet_awards`, `badge_unlocks` via respective providers

---

### 4.3 `create_post_screen.dart`
**Objective:** Compose and publish a feed post with image + caption.

**Features & Functionalities:**
- Pet identity row (which pet is posting)
- 4:5 image well — gallery/camera picker via `pickImage`
- Caption textarea (500 char limit, hashtag hint, char counter)
- Public visibility info row
- Full-screen upload overlay during submit
- Error banner

**Widgets:**
`_PetIdentityRow`, `_ImageWell`, `_EmptyImagePlaceholder`, `_SourceChip` (gallery/camera), `_CaptionCard`, `_VisibilityInfo`, `_UploadOverlay`, `_ImageSourceSheet`, `_ErrorBanner`

**User Flow:**
FAB on PawsFeed → `/social/create-post` → pick image → write caption → Post → upload → redirect back to feed (feed invalidated).

**Supabase Backend:**
- Supabase Storage (image upload) via `createPostControllerProvider.notifier.submit(petId)`
- `feed_posts` table insert
- Feed provider invalidated on success

---

### 4.4 `post_detail_screen.dart`
**Objective:** Full-screen expanded view of a single post with comment thread.

**Features & Functionalities:**
- Carousel image well (multiple images via `PageView`)
- Full un-truncated caption
- Scrollable comment thread with reply support (`_replyingToComment`)
- Fixed comment input bar at bottom (`autofocusComment` param)
- Like / save / share actions

**Widgets:**
`CachedNetworkImage`, `PageView` (image carousel), `_CommentBubble`, `_InputBar`, `_CommentFocusNode`, `AppSnackBar`

**User Flow:**
Tap post anywhere → `PostDetailScreen` (post passed via router extra) → scroll comments → reply to comment → submit → comment appended.

**Supabase Backend:**
- `feed_posts` table read via `socialRepositoryProvider`
- `post_comments` table read/insert via `commentControllerProvider`
- `post_saves` table toggle via `savedPostsControllerProvider`

---

### 4.5 `hashtag_screen.dart`
**Objective:** Browse all posts tagged with a specific hashtag.

**Features & Functionalities:**
- 3-column image grid (same as profile grid)
- Infinite scroll (loads more at bottom threshold)
- Empty state with tag name

**Widgets:**
`GridView.builder`, `TailWagLoader`, `PetfolioEmptyState`, `_PostThumb`

**User Flow:**
Tap `#hashtag` text in any caption → `/social/hashtag/:tag` → browse grid → tap thumbnail → `PostDetailScreen`.

**Supabase Backend:**
- `feed_posts` filtered by hashtag (caption LIKE %#tag%) via `hashtagFeedProvider(tag)`

---

### 4.6 `saved_posts_screen.dart`
**Objective:** Personal bookmark collection — all saved/bookmarked posts.

**Features & Functionalities:**
- 3-column image grid
- Infinite scroll (loads more at bottom)
- Empty state with bookmark icon

**Widgets:**
`GridView.builder`, `TailWagLoader`, `PetfolioEmptyState`, `_SavedThumb`

**User Flow:**
Profile → Saved → grid → tap → `PostDetailScreen`.

**Supabase Backend:**
- `post_saves` table joined to `feed_posts` via `savedPostsProvider`

---

### 4.7 `story_viewer_screen.dart`
**Objective:** Full-screen story viewer with progress timer, reactions, and pet-group paging.

**Features & Functionalities:**
- Stories grouped by pet (`PetStoryStack`)
- 5-second auto-advance per story with 50ms tick progress bar
- Pause on long-press
- `PageController` to swipe between pet story groups
- Reaction overlay: floating emoji burst animation (`_FloatingEmojiData`)
- Reaction picker (swipe up to reveal emoji row)

**Widgets:**
`CachedNetworkImage`, `PageController`, `_ProgressBars`, `_FloatingEmojiData`, `_ReactionPicker`, `TailWagLoader`

**User Flow:**
Tap story ring on PawsFeed → `/social/story/:petId` → watch story → auto-advance → swipe right/left for other pets → swipe up for reaction → reaction emoji floats → story group ends → back to feed.

**Supabase Backend:**
- `stories` table via `storiesProvider` (filtered by active pet's follows)
- `story_views` insert on view (marks story as seen) via `storyControllerProvider`

---

### 4.8 `create_story_screen.dart`
**Objective:** Publish a 24-hour story image for the active pet.

**Features & Functionalities:**
- Gallery / camera picker (`image_picker`)
- Mock pet image quick-picks (Unsplash grid for demo)
- Preview before post
- Upload to Supabase Storage

**Widgets:**
`CachedNetworkImage`, `ImagePicker`, `_MockImageGrid`, `PrimaryPillButton`, `AppSnackBar`

**User Flow:**
PawsFeed "Add story" CTA → `/social/create-story` → pick or use mock image → preview → Post → uploads to storage → `stories` row inserted → back to feed.

**Supabase Backend:**
- Supabase Storage (story image)
- `stories` table insert via `createPostControllerProvider`

---

### 4.9 `notifications_screen.dart`
**Objective:** Two-tab activity hub — social updates + marketplace promotions.

**Features & Functionalities:**
- Tab 1 "Updates": likes/comments/follows — animated `_NotificationTile` list (avatar emoji, summary, timeAgo, unread dot)
- Tab 2 "Promotions": promo-code cards (code + discount + description + expiry + copy button)
- Auto-marks all read on init

**Widgets:**
`TabBar`, `TabBarView`, `_UpdatesTab`, `_PromotionsTab`, `_NotificationTile`, `_PromoNotifCard`, `TailWagLoader`, `PetfolioEmptyState`, `flutter_animate` (.fadeIn, .slideX, .slideY)

**User Flow:**
Bell icon in shell → `/notifications` → reads updates → swipes to Promotions tab → copies promo code.

**Supabase Backend:**
- `app_notifications` table (filtered by type) via `notificationsProvider`
- `promos` table via `promoListProvider`
- `app_notifications.read_at` bulk update via `notificationsProvider.notifier.markAllRead()`

---

### 4.10 `social_dm_screen.dart`
**Objective:** Direct-message chat between two users (social path, not match-based).

**Features & Functionalities:**
- Reverse-sorted `ListView.builder` (newest at bottom)
- Colour-coded message bubbles (theirs = surfaceContainerHighest, mine = AppColors.poppy)
- Text input + send button
- Shares `chat_threads` / `chat_messages` tables with matching chat

**Widgets:**
`AppBar`, `TailWagLoader`, `_Conversation`, `ListView.builder`, `_MessageBubble`, `_InputBar` (TextField + `IconButton`)

**User Flow:**
Social profile "Message" button → `SocialDmScreen(otherUserId)` → `socialDmThreadProvider` creates or gets thread → messages stream via `socialDmConversationProvider(threadId)` → type → send.

**Supabase Backend:**
- `chat_threads` create/get via `socialDmThreadProvider(otherUserId)`
- `chat_messages` realtime stream + insert via `socialDmConversationProvider(threadId)`

---

## 5. MATCHING

### 5.1 `matching_screen.dart`
**Objective:** Tinder-style pet discovery — swipe right to match, left to pass, up to wave.

**Features & Functionalities:**
- `SegmentedButton`: Playdate / Breeding mode toggle
- `_DiscoveryStack`: up to 3 depth cards with parallax scale/offset
- `_SwipeCard`: drag + exit animation, haptic feedback at threshold. Right = MATCH (red), left = PASS (grey), up = WAVE (lilac)
- `_CardSurface`: gradient photo, distance pill, info panel (name/age/breed/bio/traits)
- `_ActionDock`: Pass (✕) + SuperPaw (⭐) + Match (🐾)
- Location gating: prompts permission if needed → blocked → `_LocationAccessEmpty`
- Mutual match celebration overlay (`MatchCelebrationOverlay`) on realtime event
- Empty deck state (`_EmptyDeck`)

**Widgets:**
`WaveHeader`, `_DiscoveryStack`, `_SwipeCard`, `_CardSurface`, `_ActionDock`, `MatchCelebrationOverlay`, `_LocationAccessEmpty`, `_EmptyDeck`, `TweenAnimationBuilder`, `CachedNetworkImage`

**User Flow:**
Nav → Match → grant location → swipe cards → mutual match triggers celebration overlay → tap card opens `SocialProfileScreen`; mode toggle switches Playdate/Breeding discovery pool.

**Supabase Backend:**
- `matching_discovery_rows` view or RPC via `discoveryCandidatesControllerProvider`
- `pet_swipes` insert on each swipe via `discoveryControllerProvider(petId)`
- `pet_mutual_matches` realtime stream via `mutualMatchInsertStreamProvider(petId)`
- `pet_geo_points` for proximity via `petMatchLocationProvider`

---

### 5.2 `matches_inbox_screen.dart`
**Objective:** List of all mutual matches for the active pet — entry to chat.

**Features & Functionalities:**
- Pet switcher support (falls through to `TailWagLoader` if no active pet)
- List of `MatchInboxItem` cards (avatar, name, last message preview, unread count)
- `PetSwitcherSheet` accessible from header
- Tapping a match → opens `ChatScreen`

**Widgets:**
`_MatchesInboxView`, `_MatchInboxCard`, `PetSwitcherSheet`, `TailWagLoader`, `PetfolioEmptyState`

**User Flow:**
Matching tab → Inbox tab → list of mutual matches → tap → `/match/chat/:threadId`.

**Supabase Backend:**
- `pet_mutual_matches` joined to `chat_threads` + `chat_messages` (last message) via `matchesInboxControllerProvider(pet.id)`

---

### 5.3 `chat_screen.dart`
**Objective:** Real-time match-based chat with date separators, timestamp groups, typing indicator.

**Features & Functionalities:**
- Reverse `ListView` (newest at bottom)
- `_DateSeparatorItem` at day boundaries
- Timestamp shown only on last message in sender burst (same sender, within 60s)
- Load older messages on scroll to top (`loadOlderMessages()`)
- Typing indicator (`_DotDotDot` animated dots)
- Playdate scheduler sheet from AppBar action (`PlaydateSchedulerSheet.show`)
- Pet switcher sheet
- Read receipts (✓✓) on own messages

**Widgets:**
`AppHeader`, `PetSwitcherSheet`, `ListView.builder` (reverse), `_MessageBubble`, `_DateSeparator`, `_TypingIndicator` (`_DotDotDot`), `_Composer` (multiline TextField + `IconButton.filled`), `PlaydateSchedulerSheet`

**User Flow:**
Inbox → tap match → `/match/chat/:threadId` → real-time messages appear → type → send → ✓✓ on delivery/read; tap scheduler → book playdate.

**Supabase Backend:**
- `chat_messages` table paginated + realtime via `chatConversationControllerProvider(_args)`
- `chat_threads.last_read_at` update on open
- Typing events via Supabase Realtime `chatTypingStateProvider`

---

### 5.4 `match_liked_screen.dart`
**Objective:** View all pets that have swiped right on the active pet (incoming likes/waves).

**Features & Functionalities:**
- Grid of pet cards that liked/waved at active pet
- Pet-switcher fallback for no active pet
- Tap → can match back or pass

**Widgets:**
`_LikedView`, `_LikedPetCard`, `PetSwitcherSheet`, `TailWagLoader`, `PetfolioEmptyState`

**User Flow:**
Match nav → Likes tab → grid of inbound likes → tap → decide to match or pass.

**Supabase Backend:**
- `pet_swipes` where `target_pet_id = activePet.id AND direction = right/wave` via `matchLikedControllerProvider`

---

### 5.5 `breeding_setup_screen.dart`
**Objective:** Configure breeding profile/credentials for a pet (for breeding-mode discovery).

**Features & Functionalities:**
- Registry name + registry ID text fields
- Sire / Dam name fields
- Titles / achievements field
- Active toggle (opt in/out of breeding discovery)
- Certificate document upload (via `media_picker`)

**Widgets:**
`_BreedingSetupView`, `TextEditingController` ×5, `SwitchListTile`, `PrimaryPillButton`, `_DocPickerRow`, `TailWagLoader`, `PetfolioEmptyState`

**User Flow:**
Match settings → Breeding Setup → fill credentials → upload cert → Save → data stored → pet becomes visible in breeding discovery.

**Supabase Backend:**
- `pet_health_certs` table (cert model `PetHealthCert`) via `breedingSetupControllerProvider`
- Supabase Storage for certificate image/PDF

---

### 5.6 `verification_center_screen.dart`
**Objective:** Request and view status of trust verification badges (vet records, microchip, pedigree, etc.).

**Features & Functionalities:**
- For each `VerificationType` (iterates all enum values): shows tile with status (pending / approved / not requested)
- "Request" button per type → `verificationControllerProvider.notifier.request(type)`
- Success snackbar on request

**Widgets:**
`_VerificationTile`, `TailWagLoader`, `PetfolioEmptyState`, `AppSnackBar`

**User Flow:**
Match settings / Profile → Verification Center → view statuses → tap Request → admin reviews → badge appears on profile.

**Supabase Backend:**
- `pet_verifications` table (model `Verification`) via `verificationControllerProvider`

---

## 6. CARE

### 6.1 `care_screen.dart`
**Objective:** Daily care tracker — task log, gamification, AI routine generation.

**Features & Functionalities:**
- Filter chips: All / Medical / Nutrition / Grooming / Walk
- `CareDailyTasksDashboard` (task list with check-off)
- `CareDatePicker` (navigate by day)
- AI routine banner → `RoutineRecommendationSheet` (NVIDIA API via `aiRoutineProvider`)
- Cache-aware AI: shows cached results if valid, generates fresh only when needed; force-refresh icon
- `WebPushEnableBanner` (web-only push permission)
- Post-onboarding welcome snackbar + auto-prewarm AI
- Species-tinted `WaveHeader`

**Widgets:**
`WaveHeader`, `_FilterChips`, `CareDailyTasksDashboard`, `CareDatePicker`, `CareTaskFormSheet`, `RoutineRecommendationSheet`, `GamifiedCareUI`, `WebPushEnableBanner`, `CareBanners`, `TailWagLoader`, `PetfolioEmptyState`

**User Flow:**
Home Care tile → `/care` → see today's tasks → check off → streaks update; tap AI banner → routine sheet shows suggestions → apply → tasks inserted; FAB → `CareTaskFormSheet` to add custom task.

**Supabase Backend:**
- `care_tasks` table (CRUD) via `careDashboardProvider`
- `care_streaks` table via `careStreakRealtimeProvider`
- NVIDIA LLM API call via `aiRoutineProvider` (no direct DB for AI)

---

### 6.2 `medical_vault_screen.dart`
**Objective:** Organized medical records store — vaccines, medications, vet visits.

**Features & Functionalities:**
- 3 section groups: Vaccines / Medications & Parasite Prevention / Vet Visits
- `VitalsChartWidget` (weight/vitals chart from `fl_chart`)
- Add record via `AppBottomSheet`
- Share pet's medical summary via `share_plus`
- Open PDF/image via `url_launcher`
- Records filterable by `MedicalRecordType`

**Widgets:**
`_MedicalVaultBody`, `_VaultSection` ×3, `_RecordCard`, `VitalsChartWidget`, `AppBottomSheet`, `TailWagLoader`, `PetfolioEmptyState`, `DashedRectPainter`, `SkeletonLoader`

**User Flow:**
Care → Medical Vault → see grouped records → tap record → view detail / delete; Add → sheet → pick type/date/notes → Save; Share → native share sheet with summary text.

**Supabase Backend:**
- `medical_records` table (CRUD) via `healthVaultControllerProvider`
- `weight_logs` table (for vitals chart) via `healthRepositoryProvider`
- Supabase Storage for record attachments

---

### 6.3 `medications_screen.dart`
**Objective:** Daily medication adherence tracker — mark doses given.

**Features & Functionalities:**
- List of active medications with dose info
- "Given" button per medication → records dose
- Empty state points to Medical Vault for adding meds

**Widgets:**
`_MedicationCard`, `TailWagLoader`, `PetfolioEmptyState`

**User Flow:**
Care → Medications → see today's meds → tap "Given" → dose logged.

**Supabase Backend:**
- `medical_records` (medications type) + `medication_doses` table via `medicationsControllerProvider(pet.id)`

---

### 6.4 `nutrition_screen.dart`
**Objective:** Calorie/weight tracking + weight history chart.

**Features & Functionalities:**
- Calorie recommendation card (based on pet species, weight, activity level via `PetLevel.fromXp`)
- Weight history `fl_chart` line chart
- "Log Weight" FAB → `_LogWeightSheet` bottom sheet
- Haptic feedback on log

**Widgets:**
`_NutritionBody`, `_CalorieCard`, `_WeightChartCard` (`fl_chart`), `_LogWeightSheet`, `TailWagLoader`, `PetfolioEmptyState`

**User Flow:**
Care → Nutrition → see calorie recommendation + weight chart → Log Weight → enter grams → Save → chart updates.

**Supabase Backend:**
- `weight_logs` table (CRUD) via `nutritionProvider(pet.id)`
- `pets.weight_kg` + `pets.activity_level` for calorie calc

---

### 6.5 `symptom_checker_screen.dart`
**Objective:** 3-step guided symptom checker with triage output.

**Features & Functionalities:**
- Step 0: Symptom picker (10 symptoms + "Other"), including emergency flags
- Step 1: Duration selector (3 options)
- Step 2: Severity selector (mild/moderate/severe)
- Triage result: colour-coded (urgent / monitor / routine) with guidance text
- Emergency symptoms auto-escalate to "Seek a vet now"
- Save to health log

**Widgets:**
`_SymptomPicker`, `_DurationPicker`, `_SeverityPicker`, `_TriageResult`, `PrimaryPillButton`

**User Flow:**
Care → Symptom Checker → pick symptom → pick duration → pick severity → see triage result (coloured card) → optionally Save → `health_logs` row inserted.

**Supabase Backend:**
- `health_logs` table insert (model `HealthLog`) via `healthRepositoryProvider`

---

### 6.6 `walk_tracking_screen.dart`
**Objective:** Real-time GPS walk tracker with map, distance, and elapsed time.

**Features & Functionalities:**
- `flutter_map` map with `LatLng` polyline route
- Geolocator stream (5m distance filter, high accuracy)
- Per-second timer for elapsed time display
- Distance accumulation using `latlong2` `Distance` calculator
- Start / Pause / End controls
- Permission gate (requests if not granted)
- Error state for permanent denial

**Widgets:**
`FlutterMap`, `Polyline`, `_WalkControls`, `_StatRow` (distance + time), `_WalkState` (internal notifier)

**User Flow:**
Care Quick Action "Walk" → `/care/walk` → map loads → Start → GPS stream begins → route drawn on map → End → walk summary → optionally save care log.

**Supabase Backend:**
- `care_tasks` (walk type) insert on save via `careDashboardProvider`
- No direct DB during tracking (local state only)

---

## 7. APPOINTMENTS

### 7.1 `vet_hub_screen.dart`
**Objective:** 4-tab hub entry for all vet-related features.

**Tabs:**
1. **Clinics Grid** (`_ClinicsGridTab`) — vet clinic browser
2. **Appointments History** (`_AppointmentsHistoryTab`) — past + upcoming
3. **Favorites** (placeholder)
4. **Vet Profile** (placeholder)

**Features & Functionalities:**
- `IndexedStack` for persistent tab state
- Floating tab bar pill at bottom using `physics: SpringDescription`
- Branded AppBar ("PETFOLIO · VET")

**Widgets:**
`AppBar`, `IndexedStack`, `_ClinicsGridTab`, `_AppointmentsHistoryTab`, `_PlaceholderTab`, `_FloatingTabBar`, `AppointmentCardWidget`

**User Flow:**
Home Vet tile or bottom nav → `/appointments` → Vet Hub → browse clinics or view history.

**Supabase Backend:**
- `vet_clinics` via `clinicListProvider`
- `appointments` via `appointmentControllerProvider`

---

### 7.2 `vet_clinics_screen.dart`
**Objective:** Browse and search vet clinics (standalone screen, also embedded in VetHub).

**Features & Functionalities:**
- List of clinic cards with photo, name, address, rating
- Skeleton loading list
- Empty + error states with retry

**Widgets:**
`_ClinicCard` (with `CachedNetworkImage`), `_SkeletonList`, `PetfolioEmptyState`

**User Flow:**
Tap clinic → `/appointments/clinics/:id` → `ClinicDetailsScreen`.

**Supabase Backend:**
- `vet_clinics` table via `clinicListProvider`

---

### 7.3 `clinic_details_screen.dart`
**Objective:** Clinic profile + service picker + slot picker → booking flow.

**Features & Functionalities:**
- Clinic header: `CachedNetworkImage` banner, name, address, rating
- Services list (vet consult / grooming / vaccination / etc.) from `clinicServicesProvider`
- Booking state: selected service + slot displayed as "Your Booking" summary
- Available slots picker via `availableSlotsProvider`
- "Book Appointment" CTA → `BookingConfirmationSheet` modal

**Widgets:**
`_ClinicBanner`, `_ServiceList`, `_ServiceTile`, `_SlotPicker`, `_BookingSummary`, `BookingConfirmationSheet`, `PrimaryPillButton`

**User Flow:**
Clinic card → ClinicDetailsScreen → pick service → pick slot → Confirm → `BookingConfirmationSheet` → submit → appointment created.

**Supabase Backend:**
- `vet_services` table via `clinicServicesProvider(clinic.id)`
- `appointment_slots` table via `availableSlotsProvider`
- `vetBookingControllerProvider.notifier.initForClinic(clinic)` manages selection state

---

### 7.4 `appointments_screen.dart`
**Objective:** Upcoming and past appointments with calendar-add integration.

**Features & Functionalities:**
- 2-tab `DefaultTabController`: Upcoming / Past
- `AppointmentCardWidget`: clinic name, date/time, service, status badge, `add_2_calendar` button
- FAB "New" → `_showAddSheet` (add appointment modal)

**Widgets:**
`DefaultTabController`, `TabBar`, `TabBarView`, `_AppointmentsTabList`, `AppointmentCardWidget`, `FloatingActionButton.extended`

**User Flow:**
VetHub Appointments tab or standalone → see upcoming/past split → tap card → detail; FAB → add appointment manually (without clinic flow).

**Supabase Backend:**
- `appointments` table (filtered by pet + past/future) via `appointmentControllerProvider`
- `add_2_calendar` exports appointment to device calendar (no Supabase call)

---

## 8. MARKETPLACE — CUSTOMER

### 8.1 `shop_intro_screen.dart`
**Objective:** One-time onboarding splash shown on first Marketplace visit.

**Features & Functionalities:**
- 3 feature highlights (Authentic / Convenient Pay / Track Order)
- `SharedPreferences` flag `pf_shop_intro_seen` — shown only once
- `ShopIntroScreen.shouldShow()` + `ShopIntroScreen.markSeen()` static helpers

**Widgets:**
`GoogleFonts.sora`, `_FeatureRow` ×3, `PrimaryPillButton`, `PetfolioThemeExtension`

**User Flow:**
First marketplace visit → `/marketplace/intro` shown → "Start Shopping" → `/marketplace`; never shown again.

**Supabase Backend:** None — local SharedPreferences only.

---

### 8.2 `marketplace_screen.dart`
**Objective:** Main shop browsing page — category chips, product grid, shop list.

**Features & Functionalities:**
- `_MarketHeader` with cart icon (badge count)
- `_CategoryChips` filter bar (Food/Treats/Toys/Beds/Apparel/Grooming/Gear/Health)
- `_ShopBody` product grid filtered by selected category
- "Add to cart" → `_addToCart` with `FlyToCartAnim` (product image flies to cart icon)
- Cart drawer (`CartDrawer`) via `showModalBottomSheet`
- Web: `WebCheckoutResumeListener` handles Stripe cancel query param
- Responsive: constrained to 800px on wide screens

**Widgets:**
`_MarketHeader`, `_CategoryChips`, `_ShopBody`, `_ProductCard`, `FlyToCartAnim`, `CartDrawer`, `WebCheckoutResumeListener`, `SmoothPageIndicator`, `ProductGlyph`, `AddressSheet`

**User Flow:**
Home Market tile → `/marketplace` → (first time: intro shown) → browse → filter by category → tap product → `ProductDetailScreen`; tap cart → `CartDrawer`; tap shop name → `ShopStorefrontScreen`.

**Supabase Backend:**
- `products` table (filtered by category) via `productListControllerProvider`
- `shops` table via `shopListControllerProvider`
- `cart_items` local state via `cartProvider` (Riverpod, not persisted to DB)

---

### 8.3 `marketplace_categories_screen.dart`
**Objective:** Visual category browser — all 8 categories as large tappable cards.

**Features & Functionalities:**
- 8 categories with emoji + colour + product count
- Tapping selects category and pushes marketplace with filter pre-set
- `flutter_animate` entrance animation

**Widgets:**
`_CategoryCard` ×8, `flutter_animate` (.fadeIn/.slideY)

**User Flow:**
Marketplace header "Categories" → `/marketplace/categories` → tap card → back to `/marketplace` with category pre-selected.

**Supabase Backend:**
- `products` count per category via `productListProvider`

---

### 8.4 `product_detail_screen.dart`
**Objective:** Full product page — images, description, variants, add-to-cart.

**Features & Functionalities:**
- `PageView` image carousel with `SmoothPageIndicator`
- Product name, brand, price (variant-adjusted)
- Variant picker (size/flavour options) via `productVariantControllerProvider`
- Subscribe & Save toggle (`SubscriptionToggle`) with frequency selector
- `_AddToCartSheet` bottom sheet (qty + variant confirm)
- Wishlist heart button via `wishlistControllerProvider`
- Reviews section (`ProductReviewsSection`)
- Haptic feedback on add to cart + pop animation

**Widgets:**
`PageView`, `SmoothPageIndicator`, `_ImageGallery`, `_VariantChips`, `SubscriptionToggle`, `_AddToCartSheet`, `ProductReviewsSection`, `ProductGlyph`

**User Flow:**
Product card → `/marketplace/product/:id` (product passed as router extra) → view images → select variant → Subscribe toggle → Add to Cart → cart badge increments.

**Supabase Backend:**
- `products` table via `productListProvider`
- `product_variants` table via `productVariantControllerProvider`
- `wishlists` table toggle via `wishlistControllerProvider`
- `product_reviews` table via `productReviewsSection`

---

### 8.5 `cart_screen.dart` (+ `CartDrawer`)
**Objective:** Review cart items grouped by shop, apply promo, select address, and checkout.

**Features & Functionalities:**
- Items grouped by `shop_id` (`_CartHeader`)
- `CartLineItem` per item (qty stepper, remove)
- Promo code entry via `promoRepositoryProvider`
- Address selection via `AddressSheet` + `addressControllerProvider`
- "Petfolio Official Shop" constant UUID recognized for special handling
- Checkout via `checkoutProvider.notifier.checkout()` → Stripe or COD
- Success → push `/marketplace/order/:orderId`; failure → error snackbar + reset

**Widgets:**
`_CartHeader`, `CartLineItem`, `_AddressCard`, `_PromoCard`, `_OrderSummaryCard`, `PrimaryPillButton`, `PetfolioEmptyState`, `WebCheckoutResumeListener`

**User Flow:**
Cart icon / FAB → `CartDrawer` or `/marketplace/cart` → review items → apply promo → pick address → Checkout → Stripe payment (web) or COD → redirect to order confirmation.

**Supabase Backend:**
- `marketplace_orders` insert via `checkoutProvider`
- `order_items` insert
- `promos` table read via `promoRepositoryProvider`
- `user_addresses` table via `addressControllerProvider`
- Stripe checkout session created server-side

---

### 8.6 `order_confirmation_screen.dart`
**Objective:** Post-checkout success/confirmation page.

**Features & Functionalities:**
- Animated checkmark (`CurvedAnimation` with `elasticOut` + fadeIn)
- Web: polls `orderRepositoryProvider.pollOrderConfirmation()` for Stripe webhook confirmation
- "Continue Shopping" → `/marketplace`; "Track Order" → order detail

**Widgets:**
`AnimationController`, `_ScaleAnim`, `_FadeAnim`, `PrimaryPillButton`

**User Flow:**
Cart checkout → Stripe success redirect to `/marketplace/order/:orderId?stripe=success` → polling confirms → animated checkmark → "Track Order" → BuyerOrderDetailScreen.

**Supabase Backend:**
- `marketplace_orders.status` poll via `orderRepositoryProvider.pollOrderConfirmation(orderId)`

---

### 8.7 `wishlist_screen.dart`
**Objective:** Display all wishlisted products as a 2-column product grid.

**Features & Functionalities:**
- `SliverGrid` 2-column layout using `ProductCard`
- Tap product → `ProductDetailScreen`
- Empty state

**Widgets:**
`SliverGrid`, `ProductCard`, `_EmptyWishlist`, `TailWagLoader`

**User Flow:**
Me → Wishlist → 2-column grid → tap → `ProductDetailScreen`.

**Supabase Backend:**
- `wishlists` joined to `products` via `wishlistItemsProvider`

---

### 8.8 `customer/buyer_order_list_screen.dart`
**Objective:** Buyer's full order history list.

**Features & Functionalities:**
- List of `_OrderCard` items with status badge + date + total
- Pull-to-refresh via `buyerOrdersProvider.notifier.refresh()`
- Tap → `BuyerOrderDetailScreen`

**Widgets:**
`_OrderCard`, `_IconBtn`, `CircularProgressIndicator`

**User Flow:**
Activity → My Orders → list → tap → order detail.

**Supabase Backend:**
- `marketplace_orders` filtered by `buyer_id` via `buyerOrdersProvider`

---

### 8.9 `customer/buyer_order_detail_screen.dart`
**Objective:** Full order breakdown — items, status timeline, tracking link.

**Features & Functionalities:**
- Order items list with product names + qty + prices
- Status badge (pending / confirmed / shipped / delivered / cancelled)
- "Track Shipment" → `ShipmentTrackingScreen` if shipped
- "Cancel" button if cancellable
- Handles both cache-hit and direct-fetch cases

**Widgets:**
`_OrderItemRow`, `_StatusBadge`, `_TrackButton`, `PrimaryPillButton`, `AppSnackBar`

**User Flow:**
Order list → tap → order detail → Track Shipment → tracking screen; Cancel → confirmation → order cancelled.

**Supabase Backend:**
- `marketplace_orders` by ID via `orderByIdProvider(orderId)` or cache
- `order_repository.cancelOrder(orderId)` for cancellation
- `shipments` table linked to order

---

### 8.10 `customer/shop_storefront_screen.dart`
**Objective:** Individual shop page — banner, bio, product grid.

**Features & Functionalities:**
- Shop banner + logo + name + description from `shopByIdProvider`
- Product grid filtered to this shop via `shopProductsControllerProvider`
- "Visit Website" via `url_launcher`
- Skeleton loading states
- "Add to Cart" inline

**Widgets:**
`_ShopBanner`, `_ShopHeader`, `ProductCard` grid, `SkeletonLoader`, `PrimaryPillButton`

**User Flow:**
Tap shop name on any product → `/marketplace/shop/:shopId` → browse shop's products → Add to Cart.

**Supabase Backend:**
- `shops` table via `shopByIdProvider(shopId)`
- `products` filtered by `shop_id` via `shopProductsControllerProvider`

---

### 8.11 `prescription_upload_screen.dart`
**Objective:** Upload a vet prescription required for restricted medicine orders.

**Features & Functionalities:**
- Image picker (camera / gallery) via `ImagePicker`
- Vet name text field
- File preview after pick
- Upload to Supabase Storage + `prescriptions` table row

**Widgets:**
`_PickerSheet`, `_FilePreview`, `_VetField`, `PrimaryPillButton`, `AppSnackBar`

**User Flow:**
Checkout detects prescription-required item → `/marketplace/order/:orderId/prescription` → pick photo → enter vet name → Upload → order unblocked.

**Supabase Backend:**
- Supabase Storage (prescription image)
- `prescriptions` table insert (model `Prescription`) via `prescriptionControllerProvider`

---

### 8.12 `shipment_tracking_screen.dart`
**Objective:** Live shipment status timeline for a specific order.

**Features & Functionalities:**
- Status milestones rendered as a vertical timeline (`_MilestoneRow`)
- "Open Tracker" → `url_launcher` (courier tracking link)
- Pull via `shipmentProvider(orderId)`

**Widgets:**
`_MilestoneRow`, `_TrackButton`, `PrimaryPillButton`

**User Flow:**
Order detail → Track Shipment → `/marketplace/order/:orderId/tracking` → timeline → Open Tracker link.

**Supabase Backend:**
- `shipments` table (model `Shipment`, with milestones JSON) via `shipmentProvider(orderId)`

---

## 9. MARKETPLACE — VENDOR

### 9.1 `vendor/seller_dashboard_screen.dart`
**Objective:** Vendor home — shop status gating, then live KPI dashboard.

**Features & Functionalities:**
- `_NoShopView` if no shop yet → "Create Shop" → `/seller/setup`
- `_ShopDeactivatedView` if shop not active (awaiting KYC/Stripe)
- `_DashboardBody` if active: revenue, order counts, product count KPI cards; recent orders list
- `WidgetsBindingObserver` — refreshes on app resume (catches Stripe onboarding return)

**Widgets:**
`_NoShopView`, `_ShopDeactivatedView`, `_DashboardBody`, `_KpiCard`, `_RecentOrderRow`, `CircularProgressIndicator`

**User Flow:**
Seller entry → `/seller` → no shop → Create Shop; inactive → wait for activation; active → see dashboard → tap orders → `/seller/orders`.

**Supabase Backend:**
- `shops` table via `myShopProvider`
- `marketplace_orders` (vendor's orders) via `vendorOrdersProvider`
- `products` count via `vendorProductsProvider`

---

### 9.2 `vendor/shop_setup_screen.dart`
**Objective:** Create or edit shop profile (name, slug, description, payout method).

**Features & Functionalities:**
- Form: shop name, URL slug, description, payout method (`PayoutMethod` enum: Stripe / bank)
- Dual mode: create vs edit (detects existing shop)
- Validation via `GlobalKey<FormState>`

**Widgets:**
`_NameField`, `_SlugField`, `_DescField`, `_PayoutSelector`, `PrimaryPillButton`

**User Flow:**
Dashboard → "Create Shop" → `/seller/setup` → fill form → Submit → shop created → redirects to Stripe onboarding or KYC.

**Supabase Backend:**
- `shops` table insert/update via `myShopProvider.notifier.createShop(...)` / `updateShop(...)`

---

### 9.3 `vendor/add_edit_product_screen.dart`
**Objective:** Add a new product or edit an existing one.

**Features & Functionalities:**
- Form: name, brand, variant (size/flavour), price (in dollars → converts to cents), inventory count, category dropdown, subscribable toggle
- Dual mode: add vs edit (detects `widget.product`)
- Validates all fields

**Widgets:**
`_NameField`, `_BrandField`, `_VariantField`, `_PriceField`, `_InventoryField`, `_CategoryDropdown`, `SwitchListTile`, `PrimaryPillButton`

**User Flow:**
Product list → "+" → `/seller/products/add` or tap existing → `/seller/products/edit/:id` → fill form → Save → product appears in shop.

**Supabase Backend:**
- `products` table insert/update via `vendorProductsProvider.notifier.saveProduct(...)`

---

### 9.4 `vendor/vendor_product_list_screen.dart`
**Objective:** View and manage all of the vendor's products.

**Features & Functionalities:**
- List of `_ProductRow` cards with `ProductGlyph` icon, name, price, inventory badge
- "+" FAB → `/seller/products/add`
- Tap product → `/seller/products/edit/:id`
- Delete via swipe/popup

**Widgets:**
`_ProductRow`, `ProductGlyph`, `_IconBtn`, `PrimaryPillButton`, `PetfolioEmptyState`

**User Flow:**
Dashboard → My Products → `/seller/products` → list → add/edit/delete.

**Supabase Backend:**
- `products` filtered by `shop_id` via `vendorProductsProvider`

---

### 9.5 `vendor/vendor_order_queue_screen.dart`
**Objective:** Active order queue for vendors — process and fulfil orders.

**Features & Functionalities:**
- Active orders only (filtered by `status.isActive`)
- Sorted newest-first
- `_OrderCard` per order: buyer name, items, status, total
- Refresh button
- Empty state

**Widgets:**
`_OrderCard`, `_IconBtn`, `_EmptyOrders`, `CircularProgressIndicator`

**User Flow:**
Dashboard → Order Queue → `/seller/orders` → see active orders → tap → `VendorOrderDetailScreen`.

**Supabase Backend:**
- `marketplace_orders` filtered by `shop_id` + active status via `vendorOrdersProvider`

---

### 9.6 `vendor/vendor_order_detail_screen.dart`
**Objective:** Detailed order view for vendors — update status, add tracking.

**Features & Functionalities:**
- Order items list
- Status update CTA (`AppBottomSheet` for status flow)
- Tracking number entry

**Widgets:**
`_OrderItemRow`, `_StatusCTA`, `AppBottomSheet`, `PrimaryPillButton`

**User Flow:**
Order queue → tap order → `/seller/orders/:id` → update status (confirm / ship / mark delivered) → `AppBottomSheet` for confirmation.

**Supabase Backend:**
- `marketplace_orders.status` update via `vendorOrdersProvider.notifier.updateStatus(...)`
- `shipments` insert on ship action

---

### 9.7 `vendor/vendor_earnings_screen.dart`
**Objective:** Vendor payout ledger — all credit/debit transactions.

**Features & Functionalities:**
- Chronological ledger list (`_LedgerRow`: amount, type, date, balance)
- Total earnings summary card

**Widgets:**
`_LedgerRow`, `_EarningsSummary`, `SliverList`

**User Flow:**
Dashboard → Earnings → `/seller/earnings` → see transaction history.

**Supabase Backend:**
- `vendor_ledgers` table (model `VendorLedger`) queried directly via `_vendorLedgerProvider` (`FutureProvider.autoDispose`)

---

### 9.8 `vendor/manual_kyc_screen.dart`
**Objective:** Multi-step KYC document submission for vendors who don't use Stripe Connect.

**Features & Functionalities:**
- 3-step flow: Step 1 = Business info (name + address), Step 2 = Document upload (NID/passport/trade license), Step 3 = Review & submit
- `_StepIndicator` progress bar
- Doc picker (camera/gallery)
- Inline error via `ref.listen(docError)`

**Widgets:**
`_Header`, `_StepIndicator`, `_Step1`, `_Step2`, `_Step3`, `PrimaryPillButton`

**User Flow:**
Shop setup (bank payout) → `/seller/kyc` → fill business info → upload doc → review → Submit → admin reviews.

**Supabase Backend:**
- Supabase Storage (KYC documents)
- `kyc_submissions` table via `manualKycControllerProvider`

---

### 9.9 `vendor/stripe_onboarding_screen.dart`
**Objective:** Bridge screen to launch Stripe Connect onboarding in browser.

**Features & Functionalities:**
- Receives `accountLinkUrl` from router extra
- "Open Stripe" button → `url_launcher` external browser
- `WidgetsBindingObserver` — on app resume calls `myShopProvider.notifier.refreshAfterOnboarding()` to detect completion

**Widgets:**
`_OpenStripeButton`, `PrimaryPillButton`, `WidgetsBindingObserver`

**User Flow:**
Shop setup (Stripe payout) → `/seller/stripe-onboarding` → Open Stripe → Stripe flows in browser → returns to app → app detects completion → shop activated.

**Supabase Backend:**
- `myShopProvider` refresh on resume checks `shops.stripe_onboarding_complete`

---

### 9.10 `vendor/edit_shop_screen.dart`
**Objective:** Edit all shop profile details including branding, contact, policies, social links.

**Features & Functionalities:**
- 3-tab `TabController`: Branding / Contact / Policies
- Branding tab: shop name, description, logo picker, banner picker
- Contact tab: email, phone, street, city, state, zip
- Policies tab: return policy text, shipping policy text + social links (website/Instagram/Facebook/TikTok/YouTube)
- Logo/banner picked as `Uint8List` and previewed locally

**Widgets:**
`TabController`, `_BrandingTab`, `_ContactTab`, `_PoliciesTab`, `_LogoPicker`, `_BannerPicker`, `PrimaryPillButton`

**User Flow:**
Dashboard → Edit Shop → 3-tab form → Save → shop record updated.

**Supabase Backend:**
- `shops` table update via `editShopControllerProvider`
- Supabase Storage for logo/banner images

---

## 10. COMMUNITIES

### 10.1 `communities_screen.dart`
**Objective:** Browse and join pet communities (interest groups).

**Features & Functionalities:**
- Scrollable list of `_CommunityCard` (banner image, name, member count, join status)
- FAB "Create community" → `CreateCommunitySheet` (only shown if communities exist)
- Empty state FAB CTA
- Skeleton loader

**Widgets:**
`_CommunityCard` (`CachedNetworkImage`), `CreateCommunitySheet`, `SkeletonLoader`, `PetfolioEmptyState`, `PrimaryPillButton`

**User Flow:**
Nav → Communities → list → tap → `CommunityDetailScreen`; FAB → create sheet → submit → new community appears.

**Supabase Backend:**
- `communities` table via `communitiesControllerProvider`
- `community_members` for join status

---

### 10.2 `community_detail_screen.dart`
**Objective:** Community feed — read posts, write posts.

**Features & Functionalities:**
- Community header (banner, name, member count)
- Post list (`communityPostsProvider`) with author avatar, timeAgo, text content
- Inline composer (text only) — collapsed by default, expands on tap
- Submit creates post; error snackbar on failure
- `setActiveCommunity(ref, community.id)` on init

**Widgets:**
`_PostList`, `_PostCard`, `_ComposerBar`, `SkeletonLoader`, `PetfolioEmptyState`, `AppSnackBar`

**User Flow:**
Community list → tap → `/communities/:id` → read posts → tap composer → type → Submit → post appears at top.

**Supabase Backend:**
- `community_posts` table (CRUD) via `communityPostsProvider`
- `communities.id` sets active scope

---

## 11. ACTIVITY

### 11.1 `activity_screen.dart`
**Objective:** Unified timeline of all orders + appointments, filterable.

**Features & Functionalities:**
- Filter chips: All / Orders / Appointments
- Items merged into `_ActivityItem` (order or appointment) sorted by date descending
- Date-grouped sections (`_groupByDate`)
- `_OrderRow`: status badge, shop name, total
- `_AppointmentRow`: clinic name, date, service
- Tab-mode (embedded in shell) vs push-mode (with header + back button)

**Widgets:**
`_FilterChip` ×3, `_DateSection`, `_OrderRow`, `_AppointmentRow`, `GoogleFonts.sora`, `TailWagLoader`

**User Flow:**
Settings/Me → My Orders → `/activity`; or bottom nav "Activity" tab → filter → tap order → `BuyerOrderDetailScreen`; tap appointment → vet hub.

**Supabase Backend:**
- `marketplace_orders` via `buyerOrdersProvider`
- `appointments` via `appointmentControllerProvider`

---

## 12. OFFERS

### 12.1 `offers_screen.dart`
**Objective:** Browse available marketplace promo codes with category filter.

**Features & Functionalities:**
- Filter chips: All / Food / Grooming / Health / Toys
- Animated `_PromoCard` list (code + discount % + description + expiry + copy button)
- Copy promo code via `Clipboard.setData` + haptic
- `flutter_animate` card entrance animations

**Widgets:**
`_FilterChip` ×5, `_PromoCard`, `flutter_animate` (.fadeIn/.slideY), `PetfolioEmptyState`

**User Flow:**
Settings → Offers → `/offers` → filter → copy promo code → paste at checkout.

**Supabase Backend:**
- `promos` table via `promoListProvider`, filtered by `promoFilterProvider` → `filteredPromosProvider`

---

## 13. ADMIN

### 13.1 `admin_screen.dart`
**Objective:** Admin access gate — checks `isAdminProvider` before rendering.

**Features & Functionalities:**
- If not admin: lock icon + "Admin access required" + "Go Home" button
- If admin: renders `AdminLayout`

**Widgets:**
`Icon(Icons.lock_outline_rounded)`, `FilledButton`, `AdminLayout`

**Supabase Backend:**
- `isAdminProvider` reads from user metadata or `admin_users` table claim

---

### 13.2 `admin_layout.dart`
**Objective:** Full admin panel with 6 navigation tabs.

**Tabs:**
1. **Dashboard** (`AdminDashboardTab`) — KPIs and charts
2. **KYC** (`KycApprovalsTab`) — review and approve vendor KYC submissions
3. **Ledger** (`FinancialLedgerTab`) — platform-wide financial overview
4. **Orders** (`OrdersTab`) — all marketplace orders
5. **Moderation** (`ModerationTab`) — content flagging/review
6. **Shops** (`ShopsTab`) — all vendor shops management

**Features & Functionalities:**
- `NavigationRail` (tablet/wide) or bottom nav (mobile)
- Shop deletion via `shopDeletionControllerProvider`

**Widgets:**
`NavigationRail` / `BottomNavigationBar`, `AdminDashboardTab`, `KycApprovalsTab`, `FinancialLedgerTab`, `OrdersTab`, `ModerationTab`, `ShopsTab`

**Supabase Backend:**
- All admin tables: `kyc_submissions`, `vendor_ledgers`, `marketplace_orders`, `shops`, `flagged_content`, `app_notifications`

---

## 14. PROFILE

### 14.1 `profile/me_screen.dart`
**Objective:** User's personal profile hub — identity, pet management, account actions.

**Features & Functionalities:**
- `_ProfileCard`: email avatar, display name, email
- MY PETS section: Switch Active Pet (→ `PetSwitcherSheet`), Add New Pet (→ `/onboarding?mode=add`)
- ACCOUNT section: Saved Addresses (→ `/settings/addresses`), My Orders (→ `/activity`)
- STORE section: My Shop (→ `/seller`), Wishlist (→ `/marketplace/wishlist`)
- SOCIAL section: Saved Posts (→ `/social/saved`)
- Theme toggle (dark/light via `themeNotifierProvider`)
- Sign Out via `authControllerProvider.notifier.signOut()`

**Widgets:**
`_ProfileCard`, `_MeGroup`, `_MeTile`, `PetAvatar`, `PetSwitcherSheet`, `PetfolioThemeExtension`

**User Flow:**
Bottom nav "Me" → profile hub → navigate to any sub-section; Theme toggle → instant dark/light switch; Sign Out → back to `/login`.

**Supabase Backend:**
- `Supabase.instance.client.auth.currentUser` for user info
- `authControllerProvider.notifier.signOut()` → Supabase `auth.signOut()`

---

## 15. SETTINGS

### 15.1 `settings_screen.dart`
**Objective:** Account settings and quick-links hub.

**Features & Functionalities:**
- `_ProfileCard`: current user email + avatar initials
- ACCOUNT group: Saved Addresses, My Orders
- OFFERS group: Promos (→ `/offers`), Refer & Get Discounts (coming-soon snackbar)
- STORE group: (implied links to seller and wishlist)
- App version / sign-out
- `GoogleFonts.sora` title

**Widgets:**
`_ProfileCard`, `_SettingsGroup`, `_SettingsTile`, `_NewBadge`, `GoogleFonts.sora`

**User Flow:**
Me → Settings → `/settings` → tap tiles → navigate to sub-pages; Sign Out → `/login`.

**Supabase Backend:**
- `Supabase.instance.client.auth.currentUser` for display
- `auth.signOut()` on sign-out

---

## Summary Table

| Module | Screen Count |
|---|---|
| Auth | 2 |
| Pet Profile | 4 |
| Home | 1 |
| Social | 10 |
| Matching | 6 |
| Care | 6 |
| Appointments | 4 |
| Marketplace (Customer) | 12 |
| Marketplace (Vendor) | 10 |
| Communities | 2 |
| Activity | 1 |
| Offers | 1 |
| Admin | 2 |
| Profile | 1 |
| Settings | 1 |
| **Total** | **63** |

---

## Core Supabase Tables Referenced Across All Screens

| Table | Used By |
|---|---|
| `auth.users` | Login, Register, Me, Settings |
| `pets` | Onboarding, Pet Profile, Edit Profile, Manage Pets, Care, Social |
| `pet_geo_points` | Edit Profile, Matching |
| `pet_swipes` | Matching |
| `pet_mutual_matches` | Matching, Matches Inbox |
| `pet_follows` | Social Profile |
| `feed_posts` | Social Feed, Create Post, Post Detail, Hashtag, Saved Posts, Profile Grid |
| `post_likes` | Social Feed |
| `post_comments` | Social Feed, Post Detail |
| `post_saves` | Post Detail, Saved Posts |
| `stories` | Social Feed, Story Viewer, Create Story |
| `story_views` | Story Viewer |
| `chat_threads` | Chat, Social DM, Matches Inbox |
| `chat_messages` | Chat, Social DM |
| `care_tasks` | Care, Home, Pet Profile |
| `care_streaks` | Care, Home, Pet Profile, Social Profile |
| `medical_records` | Medical Vault, Medications |
| `weight_logs` | Nutrition |
| `health_logs` | Symptom Checker |
| `pet_awards` / `badge_unlocks` | Pet Profile, Social Profile, Home |
| `app_notifications` | Notifications |
| `vet_clinics` | Vet Hub, Vet Clinics, Clinic Details |
| `vet_services` | Clinic Details |
| `appointments` | Appointments, Activity |
| `products` | Marketplace, Product Detail, Categories, Shop Storefront, Vendor Products |
| `product_variants` | Product Detail |
| `product_reviews` | Product Detail |
| `shops` | Marketplace, Shop Storefront, Seller Dashboard, Shop Setup |
| `wishlists` | Product Detail, Wishlist |
| `marketplace_orders` | Cart, Order Confirmation, Buyer Orders, Vendor Queue, Activity |
| `order_items` | Buyer Order Detail, Vendor Order Detail |
| `shipments` | Shipment Tracking, Vendor Order Detail |
| `prescriptions` | Prescription Upload |
| `promos` | Notifications (Promotions tab), Offers |
| `vendor_ledgers` | Vendor Earnings, Admin Ledger |
| `kyc_submissions` | Manual KYC, Admin KYC |
| `communities` | Communities |
| `community_posts` | Community Detail |
| `pet_verifications` | Verification Center |
| `pet_health_certs` | Breeding Setup |
| `user_addresses` | Cart |



---

Here's the full breakdown of every consolidation opportunity:

---

## Category 1 — Merge (−9 screens)

**`me_screen` + `settings_screen` → `AccountScreen`**
Both are navigation hubs with a profile card, account tiles, offers link, sign-out, and identical `_ProfileCard` widget. The only unique content is `settings_screen` has an "Account" group and `me_screen` has a "Pets" group — these become two groups inside one screen.

**`create_post_screen` + `create_story_screen` → `CreateContentScreen`**
Both: pick an image, preview it, add text/caption, tap publish. The only difference is the destination (`feed_posts` vs `stories`). A `mode: post | story` param and a `SegmentedButton` toggle handles both. The UI is structurally identical.

**`hashtag_screen` + `saved_posts_screen` → `PostGridScreen(source)`**
Both are literally the same widget — 3-column `GridView.builder` with `TailWagLoader`, `PetfolioEmptyState`, and infinite scroll. The only difference is the data source. A `source: hashtag | saved` param with the appropriate provider routes the data. Zero UI difference.

**`social_dm_screen` + `chat_screen` → `ChatScreen(threadId, mode)`**
They share `chat_threads` and `chat_messages` tables, a reverse `ListView`, `_MessageBubble`, and a text `_InputBar`. `chat_screen` has date separators and typing indicator that `social_dm_screen` is missing — merge both into one screen where those features are always present. Entry point (`socialDmThreadProvider` vs direct `threadId`) becomes a constructor param.

**`matches_inbox_screen` + `match_liked_screen` → `MatchHubScreen`**
Both are pet-list screens under the Matching nav. Inbox is a list of mutual matches; Liked is a grid of inbound swipes. They're already accessed from the same tab bar. Make them explicit `TabBar` tabs inside one `MatchHubScreen` (same pattern as `VetHubScreen`).

**`breeding_setup_screen` + `verification_center_screen` → `MatchProfileSettings`**
Both configure trust/identity for the Matching feature. Breeding setup = breeding credentials. Verification center = badge requests. Both are settings-style forms with no list/detail sub-navigation. Two tabs in a single "Match Profile Settings" screen.

**`shop_setup_screen` + `edit_shop_screen` → `ShopProfileScreen`**
`shop_setup` creates the shop (name, slug, description, payout). `edit_shop` edits branding/contact/policies. The setup form is a strict subset of the edit form. One screen with `isNew` flag — shows only the basic fields on creation, unlocks the full 3-tab form post-creation. Eliminates the need to navigate away after creating a shop.

**`admin_screen` → fold into `AdminLayout`**
`admin_screen` is a 40-line file that checks `isAdminProvider` and renders `AdminLayout` or a lock widget. Move the `isAdminProvider` check into `AdminLayout.build()` directly. No separate route needed.

---

## Category 2 — Convert to Sheet/Dialog (−4 screens)

**`shop_intro_screen` → `BottomSheet`**
It's a one-time splash with 3 bullet points and a "Start Shopping" button. `SharedPreferences` flag already works the same way; just call `showModalBottomSheet` instead of `context.push('/marketplace/intro')`.

**`marketplace_categories_screen` → modal sheet from Marketplace header**
Eight category cards in a `Column`. This fits perfectly in a `showModalBottomSheet`. The current full-screen route adds a navigation entry just to show 8 tiles.

**`order_confirmation_screen` → success `BottomSheet`**
An animated checkmark + 2 buttons. The `AnimationController` works the same inside a sheet. Removes a dedicated route from the order flow.

**`stripe_onboarding_screen` → `AlertDialog`**
It's a single explanatory card + one "Open Stripe" button + `WidgetsBindingObserver`. The observer can live in the seller dashboard instead. The screen itself is a full route for one button.

---

## Category 3 — Remove (−4 screens)

**`buyer_order_list_screen`**
`activity_screen` already shows all `marketplace_orders` + `appointments` in a unified date-sorted timeline with filter chips. `buyer_order_list_screen` is a strict subset — just orders. Any entry point (`Settings → My Orders`) can route to `activity_screen` with the `_Filter.orders` pre-selected via a constructor param.

**`vet_clinics_screen` (standalone)**
`vet_hub_screen` already embeds `_ClinicsGridTab` as its first tab. The standalone `VetClinicsScreen` is only reachable from legacy routes. Remove it — `VetHubScreen` covers it.

**`appointments_screen` (standalone)**
Same situation — `VetHubScreen` tab 2 is `_AppointmentsHistoryTab`. The standalone `AppointmentsScreen` is redundant.

**Notifications "Promotions" tab**
`offers_screen` already shows all promos with category filtering, copy-to-clipboard, and animations. The Promotions tab in `notifications_screen` duplicates this. Remove the tab from `notifications_screen` and add a deep link from the bell to `offers_screen` for promo notifications.

---

## Feature Duplication (no screen removal, but worth noting)

| Duplicated Feature | Appears In |
|---|---|
| Add to Cart | `marketplace_screen`, `product_detail_screen`, `wishlist_screen`, `shop_storefront_screen` |
| Promo code display | `notifications_screen` (tab), `offers_screen`, `hub_home_screen` (deals section) |
| Pet avatar + species chip | `social_profile`, `pet_profile`, `care_screen`, `matching_screen`, `chat_screen` — all re-derive species theming independently |
| Empty state pattern | Each screen defines its own `_EmptyState` widget; a single `PetfolioEmptyState` with consistent params exists but isn't always used |
| `PetSwitcherSheet` trigger | `matches_inbox_screen`, `match_liked_screen`, `chat_screen`, `me_screen` — four separate trigger points |

---

**Net result: 63 → ~46 screens.** The biggest wins by effort-to-impact ratio are the `social_dm + chat` merge (they already share DB tables but maintain two separate implementations) and removing `buyer_order_list_screen` entirely (Activity already does it better).

[Duplicated](Duplicated.png)