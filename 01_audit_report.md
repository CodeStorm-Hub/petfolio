# PetFolio UX/UI Audit Report

## 1. Executive Summary
Overall, the PetFolio application boasts a highly polished, modern, and aesthetically pleasing design. The use of vibrant gradients, soft pastel colors, and gamification elements (badges, streaks, XP) creates a very engaging and delightful "First-Time User" experience. 

However, there is a systemic layout issue across almost all scrollable views: the custom floating bottom navigation (`AppShell`) overlays and obscures content at the bottom of the screens. Additionally, there are a few severe accessibility violations regarding text/icon contrast, particularly on the Match screen. Addressing these layout and contrast issues will elevate the app from feeling "good" to feeling truly premium and production-ready.

---

## 2. Screen-by-Screen Breakdown

### Home / Pets Dashboard
- **Visual Observations:** 
  - The hero section uses a vibrant red/orange gradient (`WaveHeader`) with welcoming typography.
  - Gamification stat cards (Streak, XP, Care Logs) use pleasant pastel colors (yellow, purple, teal) providing a soft, approachable aesthetic.
  - The floating bottom navigation (`AppShell`) has a clean, pill-shaped design that feels modern.
- **Visual Bugs:** 
  - **Overlapping Content:** The floating `AppShell` casts a shadow and currently obscures the "Recent achievements" section at the bottom of the scroll view. 
- **Friction Points:**
  - **Pet Switcher Sheet:** The bottom sheet for switching pets is polished (nice drag handle, clear active state). However, there is a minor inconsistency: the main header uses an emoji avatar (🐱) but the pet switcher and Care header fall back to a generic initial avatar ("B" for Biscuit). Unifying avatar displays would improve cohesiveness.

### Care
- **Visual Observations:**
  - The XP/Streak banner is highly engaging. The glowing orange streak badge and the level progress bar ("Lv 7 Caretaker") look fantastic and encourage gamification.
  - The "Trophy room" uses distinct, colorful icons that fit the pastel aesthetic perfectly.
  - The "Generate AI Routine" banner acts as an excellent, visually distinct call-to-action (CTA).
- **Visual Bugs:**
  - Similar to the Home screen, the floating `AppShell` partially obscures the empty state text ("Add care tasks for Biscuit...") at the bottom of the screen. 
- **Friction Points:**
  - The moon icon in the top right is slightly ambiguous—it could indicate "Dark Mode" or "Log Sleep". Tooltips or labels for icon-only buttons might be helpful.

### Social
- **Visual Observations:**
  - Familiar, intuitive layout resembling popular social media feeds (Stories row at the top, feed cards below).
  - Unread stories use a clean orange ring indicator.
- **Visual Bugs:**
  - **Severe Clipping:** The `AppShell` navigation bar completely overlaps the bottom feed item. As you scroll, feed cards slide *underneath* the navigation bar and are cut off, making it impossible to read or interact with the bottom-most content cleanly without holding the scroll.

### Match
- **Visual Observations:**
  - Clean empty state with a centered paw icon.
  - Bottom action buttons (X, Star, Paw, Bone, Refresh) use a Tinder-like circular layout which is instantly recognizable.
- **Visual Bugs:**
  - The bottom action buttons are positioned too close to the `AppShell` navigation, making the bottom of the screen feel extremely cramped.
- **Friction Points & Accessibility:**
  - **Contrast Violations:** The empty state subtitle text ("Turn on Match Discovery...") is a very light grey/brown on a beige background, making it extremely difficult to read.
  - The white icons inside the pastel circular action buttons (e.g., white bone on light yellow circle) completely fail WCAG contrast ratios.

### Market
- **Visual Observations:**
  - Beautiful promotional banner with a smooth gradient ("20% off treats this week").
  - Clean horizontal scroll for categories (Food, Treats, Toys, etc.).
  - Product grid is well-structured with clear pricing and "Add" buttons.
- **Visual Bugs:**
  - **Severe Clipping:** Just like the Social feed, the product grid lacks bottom padding. The bottom row of products is entirely eclipsed by the `AppShell`.
- **Friction Points:**
  - **Context Mismatch:** The header reads "SHIP TO MOCHI'S HOUSE", but the globally active pet from the dashboard was "Biscuit". If the market defaults to a specific pet or user address without clearly tying it to the active pet context, users might purchase items for the wrong profile by mistake.

---

## 3. Accessibility & Heuristics
- **Contrast Issues:** The Match screen suffers from severe low-contrast text (empty state subtitle) and low-contrast icons (white icons on pastel buttons). These must be darkened.
- **Touch Targets:** The circular buttons in the Match screen and the "Add (+)" buttons in the Market grid are sufficiently sized for touch. 
- **Visibility of System Status:** The app does a good job of showing active states (e.g., the colored icons in the `AppShell`), but the clipping issues hide the true end of lists, violating the heuristic of user control and freedom.

---

## 4. Actionable Recommendations (Prioritized)

1. **[CRITICAL] Global Bottom Padding:** Add a global bottom padding/inset (e.g., `padding: EdgeInsets.only(bottom: 100)`) to all main `ListView` and `SingleChildScrollView` widgets across Home, Care, Social, and Market. Content must clear the floating `AppShell`.
2. **[HIGH] Fix Match Screen Contrast:** Darken the subtitle text on the Match empty state. Change the icon colors in the Match action buttons from white to a darker shade (or darken the button background colors) to pass WCAG AA contrast standards.
3. **[MEDIUM] Market Context Check:** Ensure the Market header ("Ship to [Pet]'s House") correctly reflects the globally active pet, or clearly indicate that shipping is tied to the user account rather than a specific pet to avoid confusion.
4. **[LOW] Unify Avatars:** Standardize how pet avatars are displayed when no image is uploaded. Decide between Emoji avatars (🐱) or Initial avatars (B) and use them consistently across the Home header, Pet Switcher, and Care screens.
