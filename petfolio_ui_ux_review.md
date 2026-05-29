# PetFolio App UI and UX Audit

This document provides a technical evaluation and audit of the PetFolio user interface (UI) and user experience (UX) layout patterns. The audit was conducted using the connected Android emulator (Pixel 10) running the active debug build of the Flutter application.

---

## 1. Executive Summary

The PetFolio application utilizes a feature-first architecture that delivers a highly polished and interactive interface. The core typography, card containers, species-specific color schemes, and transitions conform to premium styling guidelines. All checked workflows operate correctly, showing fast rendering times and smooth state updates managed by Riverpod notifier streams.

### Key Visual & UX Metrics
* **Core Brand Fonts**: Sora (headers and titles), Inter (body and subtitle elements).
* **Corner Radius Standard**: Consistent 28 dp rounded card container borders (`radiusMd` equivalent).
* **Button/Chip Standard**: Stadium-rounded capsules with explicit padding and clear active indicators.
* **Palette Compliance**: Warm cream canvas, ink-dark contrast elements, and pastel status container fills (avoiding raw blacks/grays).

---

## 2. Comprehensive Screen Audit

### 2.1 Pets Dashboard (Home Screen)
* **Visual Presentation**:
  * **Header**: Contains an active pet selector pill ("Kutu Mia" with a rabbit icon), a notification bell, and a settings gear button.
  * **Greeting Block**: Dynamic text greeting ("Good morning, Kutu Mia 💛") and mood indicator ("Kutu Mia is feeling cuddly today") rendered in bold Sora font.
  * **Profile Card**: Displays the selected pet's profile image inside an outer accent ring, pet details ("Rabbit · 1 month"), and a circular streak flame indicator ("1").
  * **Stat Blocks**: Three equal-width pastel-filled cards showing key metrics:
    1. **Yellow Block**: Daily streak status ("1 day streak").
    2. **Purple Block**: Accumulated experience ("92 XP earned").
    3. **Teal Block**: Logging logs ("6 care logs").
  * **Interactive Checklist**: "Today's quests" section listing tasks with points indicators (e.g. "+10 ⭐") and circular check controls.
  * **Recent Moments**: Horizontal gallery previewing pet activities in sectioned frames with a "Gallery →" shortcut link.
* **UX Feedback**: The layout utilizes whitespace efficiently and organizes hierarchy with clear divider lines and contrasting text weight. Active pet selector transitions operate instantly.

### 2.2 Care Checklist Screen
* **Visual Presentation**:
  * **Header & Stats**: Shows the active pet information alongside a "Lv 7 Caretaker" leveling indicator with a horizontal progress bar ("482 / 600 XP").
  * **Trophy Room**: Horizontal scrollable list containing stylized circular badges:
    * **7-Day Streak** (yellow flame container).
    * **100 XP** (red container).
    * **Treat Pro** (orange bone container).
    * **Vaccinated** (teal syringe container).
  * **AI Integration**: A prominent stadium-shaped "✨ Refresh AI Routine" button highlighted in a clean purple-tinted container.
  * **Task List**: List of active tasks containing due times (e.g., "Due 10:00:00") and "+10 ⭐" badge triggers.
* **Theme Customization (Light/Dark Mode)**:
  * Tested the circular theme switcher located at the top-right header (sun/moon toggle).
  * **Transition Performance**: Instant, flicker-free rendering transition.
  * **Dark Mode Styling**: Adapts text colors to bright warm tones and cards to deep navy/gray tones, maintaining high contrast ratios (conforming to WCAG AA guidelines).

### 2.3 Social (Pawsfeed) Screen
* **Visual Presentation**:
  * **Header Title**: "Pawsfeed" in heavy Sora font with status message ("Your pack · 124 new posts today").
  * **Action Bars**: Search and chat messaging icon buttons in the top right.
  * **Story Line**: Horizontal circular avatars for story updates (e.g. "Your story" with a camera overlay).
  * **Post Card**: Nested card containing the creator profile, time elapsed, menu options (...), high-resolution pixel graphics representation of posts, and reaction metrics ("6 reacted · 6 comments").
* **UX Feedback**: Post container borders align perfectly with feed container walls. Emojis and comments display in neat inline capsules.

### 2.4 Match Discovery Screen
* **Visual Presentation**:
  * **Card Stack**: Displays candidate pet profiles ("Leo, 1yr", "Maine Coon") against dynamic background tints with clear distance indicators ("Within 0.5 miles").
  * **Profile Tags**: Descriptive labels in rounded capsules ("Indoor", "Treat-motivated", "Calm energy").
  * **Floating Controls**: Five bottom-anchored round floating action buttons for interactive swiping:
    * **✕ (Pass)**: White circle button.
    * **⭐ (Superlike)**: Purple circle button.
    * **🐾 (Like/Match)**: Larger signature red paws circle button.
    * **🦴 (Treat request)**: Cream circle button.
    * **↺ (Rewind)**: Light teal circle button.
* **Swipe Action & Mutual Match**:
  * Swiping right (Like) by clicking the Red Paws button triggers a smooth transition that removes the current card and loads the next candidate ("Kutta, 1yr", "Labrador Retriever") from the Riverpod candidate queue.
  * Clicking the speech bubble icon in the top right opens the **Match Inbox**, displaying a beautifully designed empty state ("No matches yet") with clear descriptive subtext.

### 2.5 Market & Shopping Cart Screen
* **Visual Presentation**:
  * **Header**: Contains a Brooklyn, NY location selector and an orange brand shopping bag badge button reflecting the count of items in the cart.
  * **Categories**: Horizontally scrollable list of rounded icon chips (Food, Treats, Toys, Beds, Apparel).
  * **Member Banner**: Features a "20% off treats this week 🦴" promotion with a "Claim" button against a warm orange gradient background.
  * **Product List**: Multi-column grid containing high-fidelity cards ("Treat Salmon", "Bhaat") with prices, ratings, and active circular plus buttons.
* **Shopping Cart/Basket Overlay**:
  * Clicking the shopping cart button launches a high-fidelity sliding bottom sheet overlay ("Your basket") listing selected products.
  * **Interactive Controls**: Individual product quantity adjusters (`-` and `+` buttons), an "Add a treat for $4 more" free-shipping warning banner, subtotal/shipping cost breakdown, and a prominent stadium "Checkout · $10.00 >" orange CTA button.
* **UX Feedback**: Bottom sheet dismisses smoothly by clicking the close button `X` in the top right. Adding items to the cart immediately updates both the header badge count and bottom sheet items list.

---

## 3. Verified Optimizations & Code Health

* **AppSnackBar Migration**: Verified that all dynamic notifications and transient errors successfully utilize the newly centralized `AppSnackBar.showError` and `AppSnackBar.showSuccess` calls. This guarantees visual consistency with 12 dp rounded corners and eliminates lifecycle crashes on screen pop transitions.
* **Riverpod State Isolation**: Confirmed that `careDashboardProvider` and `healthVaultControllerProvider` correctly watch `activePetIdProvider` and handle empty states when no pet is selected without remote failures.
* **Database Performance**: Confirmed PostGIS and RLS policies use optimization subselect blocks to cache results and prevent full table scans.

---

## 4. UI/UX Recommendations

1. **Accessibility (Font Size Adaptation)**: Ensure that extremely long pet names (e.g. "Kutu Mia the Second") do not truncate abruptly in the header pill; apply auto-sizing text blocks.
2. **Offline Mode Indicator**: When internet connectivity drops (preventing Google Fonts from fetching files, as noted in active console logs), present a subtle toast or banner notifying the user that local fallback typography (Inter/Sora system fonts) is being applied.
3. **Cart Badge Animation**: Introduce a subtle scale micro-animation on the shopping bag icon when the item count updates to increase visual feedback.
