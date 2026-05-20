For AI Coding Agent's agentic behavior, instructing it to read the specific files, apply Flutter/Riverpod and Supabase best practices (like `ref.onDispose` and RPC transactions), and follows feature-first architecture.

### Phase 1: State Persistence & Memory Management

**Prompt 1: Scoping the Active Pet ID**
Read lib/features/pet_profile/presentation/controllers/active_pet_controller.dart. The active pet ID is currently stored in SharedPreferences using a static, unscoped key '*prefKey'. Refactor this to make the key user-scoped to prevent cross-user contamination. Fetch the current user ID using Supabase.instance.client.auth.currentUser?.id. Update the saving, loading, and deletion logic to use 'active_pet_id*${userId}'. Ensure that if the user logs out, we clear the specific user's active pet key or handle the null user gracefully. Maintain the existing Riverpod Notifier structure.

**Prompt 2: Persisting the Marketplace Cart**
Read lib/features/marketplace/presentation/controllers/cart_controller.dart. The CartNotifier currently initializes with CartState.empty and loses data on app restart. Refactor this to persist the cart items locally using SharedPreferences. Implement a JSON serialization/deserialization method for CartState or CartItem. On Notifier build, attempt to load the cart from SharedPreferences. Whenever an item is added, removed, or updated, asynchronously update the SharedPreferences string. Handle parsing errors safely by reverting to an empty cart.

**Prompt 3: Fixing Riverpod Realtime Leaks**
Read lib/features/social/presentation/controllers/social_controller.dart and any related realtime providers in the social feature. The controller subscribes to a Supabase realtime channel (e.g., 'public:posts') but lacks a lifecycle hook to clean it up when the provider is destroyed. Refactor the build method of the Riverpod AsyncNotifier or StreamProvider to use ref.onDispose(() { channel.unsubscribe(); }). Ensure that every time the provider is destroyed or rebuilt, the previous channel is explicitly unsubscribed to prevent memory leaks and duplicate stream events.

### Phase 2: Error Handling & Completing UI Facades

**Prompt 4: Surfacing Care Module Network Errors**
Review the controllers and UI screens in lib/features/care/presentation/. Specifically, look at how exceptions from CareRepository (like DatabaseException or NetworkException) are handled. Refactor the controllers so that instead of swallowing errors, they correctly emit AsyncValue.error. Then, update the UI (e.g., care_screen.dart) to use the Riverpod .when() pattern correctly. Replace the generic error displays with actionable error UI components that display the specific exception message and include a 'Retry' button that calls the provider's refresh or fetch method.

**Prompt 5: Replacing Pet Profile UI Placeholders**
Read lib/features/pet_profile/presentation/screens/pet_profile_screen.dart. There are hardcoded UI elements and placeholders like _FeedPlaceholder() for the Health and Care tabs. Connect these tabs to real data. Replace these placeholders by injecting the appropriate Riverpod providers (like healthLogsProvider or careTasksProvider). Scaffold a basic list view for the Care tab showing upcoming tasks, and a list view for the Health tab showing recent medical logs. Use the existing SkeletonLoader widget from the core widgets library for the loading states.

### Phase 3: Backend Transactional Safety (PostgreSQL RPCs)

*Note: After running these prompts, ask Claude Code to run `supabase db push` or `supabase start` to apply the migrations locally before testing.*

**Prompt 6: Admin KYC Audit Trails via RPC**
We need to fix race conditions and missing audit trails in the Admin KYC process using a database transaction. Step 1: Create a new SQL migration file in supabase/migrations/ named with the current timestamp and '_admin_kyc_rpc.sql'. This file should create a Postgres function (RPC) named 'approve_vendor_kyc(p_shop_id UUID, p_admin_id UUID)'. Inside the transaction: update 'shops' kyc_status to 'approved', insert a record into an 'audit_logs' table, and insert a row into 'notifications' alerting the vendor. Step 2: Update lib/features/admin/data/repositories/admin_repository.dart to replace the sequential client update calls with await _client.rpc('approve_vendor_kyc', params: {...}).

**Prompt 7: Transactional Checkout Processing via RPC**
We need to ensure Marketplace checkout operations are atomic to prevent partial database states. Step 1: Create a new SQL migration file in supabase/migrations/ named with the current timestamp and '_checkout_transaction_rpc.sql'. Create an RPC function 'process_checkout(p_user_id UUID, p_cart_items JSONB)' that creates an 'orders' row, inserts multiple 'order_items' rows, and clears the user's server-side cart or reserves inventory in a single Postgres transaction. Step 2: Review lib/features/marketplace/data/repositories/order_repository.dart and refactor the checkout/order creation method to execute this new RPC instead of making multiple sequential Supabase API calls from the client.

### Phase 4: External Integrations

**Prompt 8: Stripe Webhook Edge Function**
We need to implement a Supabase Edge Function to handle Stripe Webhooks asynchronously. Step 1: Scaffold a new Supabase edge function using Deno and TypeScript in supabase/functions/stripe-webhook/index.ts. Step 2: Add logic to verify the Stripe signature using the STRIPE_WEBHOOK_SECRET environment variable. Step 3: Handle the 'payment_intent.succeeded' event. When this event occurs, extract the metadata (which should contain the order_id) and use the Supabase Admin client to securely update the 'orders' table payment_status to 'paid'. Ensure error boundaries are strict and proper HTTP 200/400 status codes are returned to Stripe.

**Prompt 9: Creating Social Posts with Storage Integration**
Review the Social feature. Ensure there is a complete end-to-end flow for creating a social post. Read lib/features/social/presentation/controllers/create_post_controller.dart and its corresponding screen. Ensure the UI allows uploading an image and adding text. Refactor the logic to use the Supabase Storage client to upload the image file to a 'posts' bucket, retrieve the public URL, and then insert the post data along with the URL via social_repository.dart. Add proper loading overlays during the upload process and handle any Storage exceptions gracefully.