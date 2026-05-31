# Petfolio — Remembered High-Signal Context

This file contains high-signal architectural, structural, and feature-related context for subsequent development phases.

## 1. Social & Feed Architecture
- **Routes & Separation**: 
  - `CreatePostScreen` is mapped to `/social/create-post`.
  - `CreateStoryScreen` is mapped to `/social/create-story`.
- **Viewfinder & Grid Selection (Stories)**:
  - Custom camera viewfinder (`_CameraViewfinderCard`) utilizes a DSLR/mobile viewfinder custom painter overlay with interactive mock triggers (rec dots, raw/hdr badges).
  - Story selection is media-first, displaying a 3-column mock grid with high-resolution animal photography and a system gallery file-picker trigger.
  - Media captures/selections are rendered on a fullscreen 9:16 story preview overlay with gradient-protected overlay texts.
- **Instagram Aspect Ratio Standard**:
  - The feed card (`_PostPhoto` in [social_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/social_screen.dart)) and creation preview (`_ImagePreview` in [create_post_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/create_post_screen.dart)) use a uniform `4:5` portrait aspect ratio (`aspectRatio: 4 / 5`).
  - This matches the `4:5` aspect ratio used on the post detail screen (`post_detail_screen.dart`) to minimize vertical cropping.


## 2. Interactive Story Features
- **Story Long-Press Menu**:
  - Long-pressing a story avatar in the home feed triggers a dynamic Cupertino/Material styled popup selector menu containing **Add to Story** and **View Story**.
  - **Add to Story** immediately pushes the user to `/social/create-story`.
  - **View Story** launches the full screen story viewer.
- **Story Viewer Profile Click**:
  - Tapping the avatar or pet name in `story_viewer_screen.dart` pauses the slide progression timer and navigates to the pet's profile page (`/social/profile/:petId`).
  - Safely resumes the slide progress bar when the user returns via back navigation.


## 3. General Architecture & Guidelines
- **State Management**: Standardized entirely on Riverpod. Avoid introducing legacy packages like `provider`.
- **Persistent Dark Mode**:
  - The application uses a Riverpod code-generated `ThemeNotifier` (generating `themeProvider`) in [theme_notifier.dart](file:///home/kratzer/workspace/petfolio/lib/core/theme/theme_notifier.dart).
  - Selected theme states are written to and loaded from `SharedPreferences` under the key `'theme_mode'`.
  - Toggled using `ref.read(themeProvider.notifier).toggleTheme()` via the AppHeader action button inside [pet_profile_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/pet_profile/presentation/screens/pet_profile_screen.dart).
- **Paw Icon Likes**:
  - Replaced all default Material heart/favorite icons with paw icons (`Icons.pets_rounded` for liked/filled state and `Icons.pets_outlined` for unliked/border state) across social cards, details, and double-tap gestures to align with the pet-centric design.
- **Supabase Optimization**:
  - Push complex joins/aggregations to Database Views or RPCs to avoid client-side N+1 queries.
  - Wrap database auth checks in subselects: `(select auth.uid())` for RLS performance.
- **Errors & UI Alerts**:
  - App-wide notifier-triggered failures must utilize `AppSnackBar.showError` and `appSnackBarMessengerKey` instead of assigning transient errors to long-lived state providers.


## 4. Responsiveness & Bottom Navigation Layout
- **Unified Breakpoints**:
  - Built a shared `ResponsiveLayout` helper (`lib/core/widgets/responsive_layout.dart`) with breakpoints `mobileMax = 600` and `tabletMax = 1024`.
  - Core screens are responsive, constraining main view content to centered columns (typically `560px` to `800px`) on wider screens (Tablets/Web/Desktop) to prevent stretching.
- **Mobile Bottom Spacing**:
  - Because `_FloatingNav` overlays screen content inside the shell route layout, bottom-docked interactive buttons on full-screen non-scrollable layouts (e.g., the Matching screen's `_ActionDock`) must use dynamic bottom padding on mobile viewports (`SizedBox(height: isWide ? 16 : (92 + MediaQuery.paddingOf(context).bottom))`) to sit cleanly above the floating navigation bar.
- **Root Navigator for Modal Sheets**:
  - Modal bottom sheets shown from screens wrapped by the shell navigator (such as the switcher, cart drawer, story options, and care forms) must set `useRootNavigator: true`. This forces them to render on the root navigator, rendering above the floating navigation bar.


## 5. Code Audit & Stability Fixes (May 31, 2026)
- **Feature Teardown**: Completely removed legacy "Treat" (🦴) and "Undo" (↺) buttons from the Matching swipe deck to keep features tightly focused.
- **Database & Storage**: Added an optimized bucket read policy to `medical-documents` storage bucket wrapping the `public.is_admin()` check in a cached subselect.
- **State Management & Lifecycles**: Resolved build-phase state mutation exceptions inside `CareNotifier` using a microtask-deferred state sync watcher.
- **GoRouter Cold Starts**: Resolved race conditions on deep-linked screens (like pet editing) by wrapping GoRouter builders in dynamic consumer contexts to handle loading states cleanly.
- **Query Boundaries**: Configured strict `.limit(100)` boundaries on matching queries, medical vault streams, and care logs to prevent full table scans/excessive data fetching.
- **Robust Error Handling**: Added error boundaries and retry UI triggers to switcher, stories, quest cards, achievements, and weight lists to replace swallowed error screens.
- **Modal Sheets Positioning**: Added `useRootNavigator: true` to the remaining modal bottom sheets (including image picking in create post, post options, share access, and weight logging) to ensure they render above the persistent bottom navigation bar.


