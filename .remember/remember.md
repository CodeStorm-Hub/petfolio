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
