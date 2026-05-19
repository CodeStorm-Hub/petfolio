### Step 1: Database Schema & Storage Restructuring

**Prompt for Claude:**

> "We need to update the Supabase schema for the PetFolio marketplace to support both Stripe and manual (Cash on Delivery) flows, as well as a centralized admin system. Create a new SQL migration file in `supabase/migrations/` with the following changes:
> 1. Alter the `shops` table: Keep the Stripe fields, but add `payout_method` (enum: 'stripe', 'manual'), `kyc_status` (enum: 'pending', 'submitted', 'approved', 'rejected'), `trade_license_url` (text), `national_id_url` (text), `rejection_reason` (text), and `bank_account_details` (jsonb).
> 2. Alter the `marketplace_orders` table: Add `payment_method` (enum: 'stripe', 'cod') and `payment_status` (enum: 'pending', 'paid', 'collected').
> 3. Create a new `vendor_ledgers` table with columns: `id`, `shop_id`, `order_id`, `order_total_cents`, `platform_fee_cents`, `vendor_earnings_cents`, and `status` (enum: 'pending_clearance', 'available', 'paid'). Include foreign keys and timestamps.
> 4. Create a new storage bucket named `kyc-documents`.
> 5. Update RLS policies: Allow users with an `is_admin = true` claim (or an admin role system of your choice) to SELECT, UPDATE, and DELETE on these tables, and restrict `kyc-documents` reads to admins and the file owners."
> 
> 

### Step 2: Edge Functions & Backend Logic

**Prompt for Claude:**

> "Update the Supabase Edge Function located at `supabase/functions/create-payment-intent/index.ts`.
> Modify the function to expect a `payment_method` string in the request payload.
> * If `payment_method === 'stripe'`, execute the existing Stripe destination charge logic and return the client secret.
> * If `payment_method === 'cod'`, bypass Stripe entirely. Perform necessary cart/inventory validation and return a success token or JSON response that allows the Flutter client to proceed with writing the order directly to Supabase.
> Ensure CORS headers and error handling remain intact."
> 
> 

### Step 3: Flutter Data Layer (Models & Repositories)

**Prompt for Claude:**

> "Update the Flutter data layer in `lib/features/marketplace/data/`.
> 1. Update `models/shop.dart` and `models/marketplace_order.dart` to include the new fields from the latest database migration (`payoutMethod`, `kycStatus`, `paymentMethod`, `paymentStatus`, etc.). Run the build runner to regenerate the Freezed/JSON serialization files.
> 2. Create a new model `vendor_ledger.dart` mapping to the new table.
> 3. Update `repositories/order_repository.dart` to handle direct database inserts for COD orders, passing `payment_method: 'cod'` and `payment_status: 'pending'` when skipping Stripe."
> 
> 

### Step 4: Vendor Onboarding & UI (Seller Dashboard)

**Prompt for Claude:**

> "We are updating the vendor UI to support branching onboarding using the `Provider` package for state management.
> 1. In `lib/features/marketplace/presentation/screens/vendor/shop_setup_screen.dart`, add a UI selection for location (International vs. Bangladesh).
> 2. If International, route to the existing Stripe `url_launcher` flow.
> 3. If Bangladesh, navigate to a new Flutter form screen `ManualKycScreen`. Use `Provider` to manage the state of this multi-step form (collecting business info, picking NID/Trade License images, and capturing bank details). Upload the files to the `kyc-documents` bucket and update the `shops` row to `kyc_status: 'submitted'`.
> 4. Update `SellerDashboardScreen` to display conditional warning banners: If 'manual' and 'submitted', show 'Documents under review'. If 'rejected', show the rejection reason."
> 
> 

### Step 5: Buyer Checkout Flow

**Prompt for Claude:**

> "Update the buyer checkout experience in `lib/features/marketplace/presentation/screens/cart_screen.dart` and `checkout_controller.dart`.
> 1. Introduce a payment method selector UI before the checkout button: 'Credit Card (Stripe)' vs 'Cash on Delivery'. Use `Provider` to manage the selected payment state.
> 2. If Stripe is selected, maintain the current flow triggering the Payment Sheet.
> 3. If COD is selected, bypass the Payment Sheet. Show a summary confirmation bottom sheet, invoke `OrderRepository` to insert the order directly as COD, clear the shop's cart items, and route to the success screen."
> 
> 

### Step 6: PetFolio Official Admin Panel

**Prompt for Claude:**

> "Create a completely new feature module for the PetFolio Official Admin Panel at `lib/features/admin/`. This should be a route-protected area optimized for desktop/tablet.
> Strictly use the `Provider` package to manage the state across this entire module.
> 1. Create `AdminAuthProvider` to validate admin access.
> 2. Create `KycReviewProvider` to fetch and manage shops where `kyc_status == 'submitted'`.
> 3. Create `LedgerProvider` to aggregate the `vendor_ledgers` table.
> 4. Build a UI with a side navigation rail containing:
> * **Overview:** Dashboard metrics.
> * **KYC Approvals:** List view of pending shops, ability to view uploaded NID/Licenses, and 'Approve' or 'Reject' buttons.
> * **COD Reconciliation:** List of delivered COD orders with a 'Mark Cash Received' button (updates order status and moves ledger funds to 'available').
> * **Payouts:** List of vendors with an 'available' balance, showing their bank info, and a 'Mark as Paid' button to clear the ledger."
> 
> 
> 
>