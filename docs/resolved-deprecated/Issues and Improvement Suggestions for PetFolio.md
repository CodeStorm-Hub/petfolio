# Issues and Improvement Suggestions for PetFolio (multi‑vendor‑marketplace branch)

This report consolidates issues discovered across all modules of **PetFolio** (lib/ folder) and suggests improvements based on research into comparable pet social networks, e‑commerce marketplaces, loyalty programs and wellness‑tracking apps. Observations are grouped by module (core, auth, pet profile, care, marketplace, matching, social, and general) and by backend/data layer. Each improvement recommendation is backed by evidence from external sources.

## 1 Issues by Module

### Core

* **Theme & design system** – The design tokens and AppTheme definitions are clear and used consistently, but there are no automatic dark‑mode adaptation rules and no run‑time theming support (e.g., changing accent colour) which many modern apps provide. Global typography sizes are hard‑coded and not responsive for accessibility.

* **Routing** – go\_router defines many nested routes. Some error states redirect to home without explanation. Deep links have limited handling for unknown routes. There is no route guard for offline/maintenance mode.

* **Global error handling** – The AppException classes exist, but many repositories and controllers simply print errors to debugPrint or ignore them. UI surfaces sometimes fail silently without user feedback (e.g., failed location sync in matching).

### Authentication

* **Limited auth options** – Only email/password sign‑in is supported. There is no social login (Google, Facebook, Apple) or anonymous/guest mode. There is no password‑reset UI.

* **User onboarding** – The registration flow does not collect preferences or consent for newsletters/notifications. There is no multi‑factor authentication (MFA) or phone verification.

### Pet Profile

* **Model duplication** – There are two Pet models (one in pet\_profile and one in care module). They have overlapping and diverging fields. This duplication increases maintenance risk and can cause mismatches when converting across modules.

* **Limited editing** – Users can edit pets but cannot change species or breed after onboarding. There is no way to add microchip or vaccination info directly on the profile. Photo upload uses camera/gallery only; there is no cropping or editing.

* **No social visibility controls** – Pets have an isDiscoverable flag but there is no in‑app UI to toggle it. Privacy settings (public/private profile, hide age/breed) are lacking.

### Care and Health Management

* **Task engine limitations** – While tasks can be created and scheduled, there is no support for custom reminders (notification scheduling), time‑based triggers, or variable repetition beyond fixed frequencies. Recurring tasks cannot be skipped with partial credit. There is no built‑in suggestions for new tasks based on pet species or age.

* **Wellness tracking** – Health logs and medical records are separate, but there is no consolidated wellness dashboard. Weight charts exist, but there is no AI pattern recognition or symptom tracking to detect trends. Records cannot be exported to share with vets.

* **Gamification** – Streaks and badges exist, but there is no overall score or progression system. Gamification rewards are not tied to tangible benefits such as discounts.

* **Offline support** – Only the daily checklist uses local caching via SharedPreferences. Other care tasks and logs require network access.

### Marketplace

* **Cart persistence** – The cart is stored in memory only (not persisted to local storage). If the app is closed, items are lost.

* **Search and discovery** – The marketplace screen has a search bar and category chips, but the search functionality is not implemented and categories are static. There is no sorting (price, popularity) or filtering beyond categories. The **Discover Shops** section is static; there is no ranking based on ratings or distance.

* **Product subscriptions** – Products can be marked as subscribable, but subscription management is simplistic. Frequency options are limited (weeks only). There is no auto‑ship discount system or pause/resume functionality.

* **Checkout and payments** – The new cash‑on‑delivery (COD) flow is an improvement, but there is still reliance on Stripe for card payments and no support for mobile wallets or regional methods (e.g., bKash in Bangladesh). There is no cart‑level tax and shipping calculation; shipping is assumed to be free. There is no coupon/promo code support or gift cards.

* **Vendor and admin features** – Multi‑vendor functionality exists, including onboarding and KYC, but there is no vendor analytics dashboard or inventory management UI. Vendors cannot create or edit products from the app. The admin panel is implemented but lacks moderation tools (e.g., flagging inappropriate content).

* **Trust & safety** – There is no rating/review system for products or shops. The marketplace lacks dispute resolution flows or buyer protection messaging.

### Matching (Pet Dating/Playdates)

* **Error handling** – The matching data source does not surface errors; if an RPC call fails, it returns an empty list, causing silent failures. Location sync failures are swallowed. There is no retry/backoff for network calls.

* **Incomplete premium features** – The \_ActionDock includes a placeholder for **Boost** (premium), but it is not implemented. There is no subscription or in‑app purchase integration.

* **Discovery algorithm** – Matching uses a simple filter by species, distance and age. There is no personality or behavioural matching. Pets can match only if both have location set; there is no fallback based on city. Users cannot view a map of nearby pets.

* **Communication** – Chat threads work but there are limited features: no media sharing (photos/videos), no typing indicators, no read receipts, no block/report functionality.

### Social (Community Feed)

* **Feed scalability** – The social feed uses Supabase queries for posts and comments, but there is no pagination or lazy loading of media. Realtime updates and notifications are limited. It is unclear how content moderation is handled.

* **Content creation** – Post creation seems basic (text and one image). There is no support for videos, multiple images, polls, or reactions beyond likes. Pet profiles cannot repost or share posts.

* **Engagement** – There is no trending or discovery feed. Users cannot follow others or pets; there is no follower/following system. Comments do not support threading or mentions.

* **Safety & privacy** – There is no explicit block/report mechanism for users. Privacy settings for posts (public/friends) are missing.

### General Application Issues

* **Internationalization (i18n)** – The app uses hard‑coded English strings and lacks localization. Currency is fixed (USD) and does not adjust to local currencies like BDT for Bangladesh.

* **Accessibility** – Components do not expose semantic labels for screen readers. Colour contrast may be insufficient. The font sizes do not adjust for system preferences.

* **Offline/low‑connectivity** – Most features rely on realtime Supabase calls. Without network connectivity, the app becomes unusable. There is no offline caching for posts, messages, or orders.

* **Testing** – Unit and widget tests are sparse. The existing test/widget\_test.dart fails. There is limited automated testing for the multi‑vendor and matching features.

* **Security** – The Supabase edge functions check ownership and shop activity, but many API keys and secrets are stored in environment variables without encryption at rest. There is no rate limiting or abuse detection.

## 2 Improvement Suggestions (Insights from Industry)

### A. Social Networking Improvements

* **Community feed and playdates** – Apps like **Pawmates** provide a news feed where owners post photos/videos of their pets and like/comment on other posts. They offer a *matching algorithm* based on **age, breed, size and distance** to find compatible playmates and arrange meetups; unlimited chat is available to coordinate playdates[\[1\]](https://apps.apple.com/ca/app/pawmates-the-pet-social-media/id1397983772). **PetFolio** could adopt a similar discovery algorithm and show a feed of nearby pets/events. Allowing users to filter potential matches by size, temperament or activity level would enhance relevance.

* **Local services map** – Pawmates integrates a map of local **veterinarians, groomers, pet stores and dog walkers**, complete with ratings and contact details[\[1\]](https://apps.apple.com/ca/app/pawmates-the-pet-social-media/id1397983772). Adding a services map inside PetFolio would complement the marketplace and provide one‑stop access to community‑rated services.

* **Customizable pet profiles and story reels** – Encouraging users to complete detailed pet profiles and share stories (e.g., via reels or short videos) would increase engagement. A profile completion meter and prompts to add interesting details or health milestones could help build richer data for matching algorithms.

* **Following and groups** – Introduce a follower/following system so users can subscribe to pets they like. Implement groups or packs around topics (breed groups, training clubs). Provide privacy options for each post (public/friends/pack). Add comment threads and mentions.

### B. Marketplace & Loyalty Enhancements

* **Auto‑ship and subscription discounts** – Leading pet retailers like **Chewy** and **BarkBox** offer *autoship* or subscription services with **5‑10 % discounts, free shipping and membership perks**[\[2\]](https://www.rivo.io/blog/best-loyalty-programs-pet-brands#:~:text=5). Chewy sends personalised touches like handwritten cards and ensures easy cancellation. PetFolio can enhance its subscription model by:

* Allowing users to schedule recurring deliveries for each product at flexible intervals (weekly, monthly, quarterly).

* Offering subscription discounts or loyalty points (e.g., 10 % off or bonus care points when subscribing).

* Providing early reminders before the next shipment with easy pause/resume/cancel options.

* **Curated experience boxes** – Companies like **BarkBox (BARK)** differentiate via monthly themed boxes tailored to a pet’s size and play style[\[3\]](https://www.rivo.io/blog/best-loyalty-programs-pet-brands#:~:text=6%29%20BARK%20). PetFolio could introduce curated subscription boxes for different species, life stages or themes (e.g., ‘Puppy Starter Kit’, ‘Senior Wellness Box’). These boxes could include toys, treats, and care items at a bundle discount.

* **Loyalty program** – Build a **points-based loyalty system** where purchases, posts, care task completions and referrals earn points. Points can be redeemed for discounts, free shipping or exclusive items. Blue Buffalo’s Good Rewards uses receipt scanning across retailers to accumulate points; other brands offer referral credits and tiered status levels. PetFolio could implement digital receipts for external purchases or integrate with vendor POS systems.

* **Reviews and ratings** – Implement a rating system for products and shops to build trust. Verified purchases should be labelled, and negative reviews should trigger vendor support workflows. Add a Q\&A section for product inquiries.

* **Payment methods** – Beyond Stripe and COD, integrate local payment gateways (e.g., **bKash** or **Nagad** for Bangladesh) and support digital wallets (Apple Pay, Google Pay). Offer split payments if the cart contains items from multiple vendors.

* **Dynamic shipping and tax** – Calculate shipping costs based on vendor location and buyer address (or pickup options). Show estimated delivery times and allow real‑time tracking. Include tax calculations for different jurisdictions.

### C. Wellness & Care Features

* **Comprehensive wellness tracking** – As noted by PerkyPet AI, a strong pet wellness platform **combines structured symptom logging, behavior and routine monitoring, centralized health history and AI guidance**[\[4\]](https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps#:~:text=PerkyPet%20AI%20is%20the%20industry%27s,for%20both%20cats%20and%20dogs). PetFolio’s care module could:

* Allow users to log **symptoms, behaviours and routines** beyond scheduled tasks.

* Use AI or rule‑based analysis to detect anomalies in weight, activity or symptom trends and alert owners of potential health issues.

* Provide personalized guidance and suggestions for tasks based on the pet’s species, age, and health history (e.g., recommended walks for high‑energy dogs, feeding reminders for diabetic pets).

* **Appointment and medication management** – PetDesk focuses on appointment scheduling, vaccination and medication reminders[\[5\]](https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps#:~:text=2,Appointments%20and%20Preventive%20Care%20Tracking). PetFolio should add a **calendar and reminders** integrated with vet clinics for upcoming appointments and preventive treatments. Reminders should trigger push notifications.

* **Medical record consolidation** – Apps like Medika store and organise medical records, vaccinations and medications[\[6\]](https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps#:~:text=4,Medical%20Record%20Storage). PetFolio’s medical vault should allow scanning or uploading vet documents, storing lab results and prescriptions, and exporting records for vet visits. Add a shared access feature for veterinarians or family members.

* **Health gamification & rewards** – Link care streaks and health milestones to tangible rewards in the marketplace (e.g., a badge unlocking a coupon). Offer challenges (e.g., ‘Walk 5 km this week’) with community leaderboards.

### D. Matching & Community

* **Advanced matching algorithms** – Extend discovery to consider **temperament, energy level, weight and play style** (data captured via the pet profile). Use AI to suggest matches based on compatibility and mutual preferences. Provide a safety check (e.g., vaccinated status) to reassure owners before meetups.

* **Playdate calendar & events** – Add an event scheduling feature where pet owners can host playdates or join group walks in local parks. Integrate with calendar and notifications.

* **Map and proximity filter** – Show a map of nearby pets and events, using location clusters. Include distance filters and radius settings. Provide the ability to browse without sharing exact location by using approximate city areas.

* **Premium features** – The placeholder **Boost** could become a premium subscription offering: priority placement in discovery, unlimited swipes, enhanced profile customization, or virtual gifts. Integrate with in‑app purchases.

* **Safety tools** – Add reporting/blocking functionality, verified badges for KYC‑verified users, and optional identity checks. Provide guidance on safe meetups.

### E. Social Feed & Engagement

* **Rich media and stories** – Allow posts with multiple images, short videos, and stories that expire after 24 hours (similar to Instagram). Support stickers, GIFs and tags.

* **Follow system and notifications** – Implement followers/following and push notifications for likes, comments, new matches or posts from followed pets. Add trending or recommended posts based on interactions and location.

* **Content moderation** – Use automated tools and manual review to detect inappropriate content (spam, abuse). Provide reporting, blocking and mute features for users.

* **Live streams and events** – Explore live streaming for pet training sessions, Q\&A with vets, or adoption events. Create virtual events with chat and donations to shelters.

### F. General Improvements

* **Internationalization** – Localize the app (UI strings, units, currency) to support global audiences. Provide currency conversion in the marketplace (e.g., BDT for Bangladesh). Detect locale automatically and allow manual override.

* **Accessibility & UX** – Ensure proper semantic labels for screen readers, implement dynamic font scaling, and offer dark‑mode customisation. Use animations judiciously to maintain performance.

* **Offline-first architecture** – Cache essential data (posts, products, tasks) for offline use and sync when the network is available. Provide an offline indicator with limited functionality rather than failing silently.

* **Testing & quality** – Expand unit, integration and widget tests across all modules. Add smoke tests for new features (e.g., multi-vendor cart, KYC flows). Incorporate CI/CD with test coverage reporting.

* **Security & privacy** – Encrypt local storage of sensitive data (session tokens). Enforce strong password and OTP policies. Implement rate limiting and monitoring for suspicious activity. Provide privacy settings for data sharing.

## Summary

PetFolio already boasts a comprehensive feature set: pet onboarding, care management with streaks, social feed, multi-vendor marketplace with Stripe Connect, matching and chat, and admin/vendor modules. However, there are many opportunities to enhance user experience, reliability and competitiveness. Improvements could be drawn from market leaders: more robust wellness tracking with AI guidance[\[4\]](https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps#:~:text=PerkyPet%20AI%20is%20the%20industry%27s,for%20both%20cats%20and%20dogs), loyalty programs and subscription discounts similar to Chewy and BarkBox[\[2\]](https://www.rivo.io/blog/best-loyalty-programs-pet-brands#:~:text=5)[\[3\]](https://www.rivo.io/blog/best-loyalty-programs-pet-brands#:~:text=6%29%20BARK%20), and community engagement tools akin to Pawmates’ news feed, matching algorithm and local services map[\[1\]](https://apps.apple.com/ca/app/pawmates-the-pet-social-media/id1397983772).

Adopting these enhancements will help PetFolio stand out as a holistic platform for pet owners, combining social interaction, health management and e‑commerce into a seamless experience.

---

[\[1\]](https://apps.apple.com/ca/app/pawmates-the-pet-social-media/id1397983772) ‎Pawmates: The Pet Social Media App \- App Store

[https://apps.apple.com/ca/app/pawmates-the-pet-social-media/id1397983772](https://apps.apple.com/ca/app/pawmates-the-pet-social-media/id1397983772)

[\[2\]](https://www.rivo.io/blog/best-loyalty-programs-pet-brands#:~:text=5) [\[3\]](https://www.rivo.io/blog/best-loyalty-programs-pet-brands#:~:text=6%29%20BARK%20) Rivo | Best Loyalty Programs For Pet Brands

[https://www.rivo.io/blog/best-loyalty-programs-pet-brands](https://www.rivo.io/blog/best-loyalty-programs-pet-brands)

[\[4\]](https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps#:~:text=PerkyPet%20AI%20is%20the%20industry%27s,for%20both%20cats%20and%20dogs) [\[5\]](https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps#:~:text=2,Appointments%20and%20Preventive%20Care%20Tracking) [\[6\]](https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps#:~:text=4,Medical%20Record%20Storage) Top 5 Pet Wellness Tracking Apps | 2026 Guide

[https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps](https://perkypetai.com/tips/the-top-5-pet-wellness-tracking-apps)