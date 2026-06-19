# Plan: Petfolio Vendor/Admin Dashboard — Separate Web Project

## Context

The Petfolio Flutter app currently contains both buyer-facing marketplace screens and vendor/seller management screens (shop setup, product CRUD, order fulfillment, earnings). The goal is to:

1. **Remove** all vendor screens from the Flutter app — sellers will use a dedicated web dashboard instead
2. **Build** `petfolio-dashboard` — a single Next.js web app with role-based routing (`/vendor/*` and `/admin/*`), hosted on Vercel, connected to the same Supabase project
3. **Fix database gaps** — missing tables, missing columns, and missing/wrong RLS policies discovered during the audit

The buyer experience in the Flutter app is **unchanged**. Vendor login in Flutter will redirect to the web dashboard URL.

---

## Current State Audit

### Flutter: What Stays vs What Goes

**Remove from Flutter (11 screens, 8 routes, 6 controllers, 2 repositories):**

| Asset | Path |
|---|---|
| Screens | `lib/features/marketplace/presentation/screens/vendor/` (entire folder) |
| Routes | `/seller`, `/seller/setup`, `/seller/edit-shop`, `/seller/kyc`, `/seller/products`, `/seller/products/add`, `/seller/products/:id/edit`, `/seller/orders`, `/seller/orders/:id`, `/seller/earnings` |
| Controllers | `my_shop_controller.dart`, `vendor_products_controller.dart`, `vendor_orders_controller.dart`, `edit_shop_controller.dart`, `manual_kyc_controller.dart`, `deletion_request_controller.dart` |
| Repositories | `vendor_product_repository.dart`, `kyc_repository.dart` |

**Keep in Flutter (buyer flows, untouched):**
- All screens under `presentation/screens/customer/`
- `marketplace_screen.dart`, `product_detail_screen.dart`, `cart_screen.dart`, `wishlist_screen.dart`, `shipment_tracking_screen.dart`, `prescription_upload_screen.dart`, `order_confirmation_screen.dart`
- All buyer controllers, `order_repository.dart`, `shop_repository.dart` (read-only methods only), `address_repository.dart`, `promo_repository.dart`, `wishlist_repository.dart`, `prescription_repository.dart`, `shipment_repository.dart`, `product_review_repository.dart`

**Add to Flutter (small change):**
- In the seller dashboard route handler: replace the screen with a `WebView` or `url_launcher` call pointing to the vendor dashboard URL, so existing deep links don't break during transition

### Database: Current `is_admin()` Setup

The `is_admin()` function reads `app_metadata.is_admin` from the JWT (set via Supabase Admin API). No `user_roles` table exists. No `is_vendor()` function exists. Vendors are currently identified solely by owning a row in `shops`.

---

## Database Changes Required

### 1. Missing Tables (create via migration)

```sql
-- Vendor payout requests
CREATE TABLE public.payout_requests (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id         uuid NOT NULL REFERENCES public.shops ON DELETE CASCADE,
  amount_cents    bigint NOT NULL CHECK (amount_cents > 0),
  method          text NOT NULL CHECK (method IN ('bkash','nagad','bank','stripe')),
  account_details jsonb NOT NULL DEFAULT '{}',
  status          text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','paid','rejected')),
  notes           text,
  requested_at    timestamptz NOT NULL DEFAULT now(),
  resolved_at     timestamptz,
  resolved_by     uuid REFERENCES auth.users
);

-- Order disputes
CREATE TABLE public.disputes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    uuid NOT NULL REFERENCES public.marketplace_orders ON DELETE CASCADE,
  raised_by   uuid NOT NULL REFERENCES auth.users,
  reason      text NOT NULL CHECK (char_length(reason) <= 1000),
  status      text NOT NULL DEFAULT 'open' CHECK (status IN ('open','under_review','resolved','closed')),
  resolution  text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Platform-wide admin key-value config
CREATE TABLE public.platform_settings (
  key         text PRIMARY KEY,
  value       jsonb NOT NULL DEFAULT '{}',
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  uuid REFERENCES auth.users
);

-- Seed defaults
INSERT INTO public.platform_settings (key, value) VALUES
  ('default_platform_fee_percent', '10'),
  ('allowed_product_categories', '["food","gear","toys","treats","health","grooming","beds","apparel"]'),
  ('maintenance_mode', 'false');

-- Admin → vendor broadcast announcements
CREATE TABLE public.vendor_announcements (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text NOT NULL,
  body        text NOT NULL,
  is_pinned   boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  uuid REFERENCES auth.users
);
```

### 2. Missing Columns (alter existing tables)

```sql
-- products: CRITICAL — no product description currently exists
ALTER TABLE public.products
  ADD COLUMN description    text,
  ADD COLUMN weight_grams   integer,
  ADD COLUMN tags           text[]   NOT NULL DEFAULT '{}',
  ADD COLUMN sku            text;

-- marketplace_orders: cancellation + refund tracking
ALTER TABLE public.marketplace_orders
  ADD COLUMN buyer_notes      text,
  ADD COLUMN cancelled_reason text,
  ADD COLUMN cancelled_at     timestamptz,
  ADD COLUMN refund_status    text NOT NULL DEFAULT 'none'
    CHECK (refund_status IN ('none','requested','approved','processed'));

-- shipments: audit + delivery notes
ALTER TABLE public.shipments
  ADD COLUMN updated_at      timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN delivery_notes  text;

-- prescriptions: reviewer tracking
ALTER TABLE public.prescriptions
  ADD COLUMN reviewer_id   uuid REFERENCES auth.users,
  ADD COLUMN review_note   text;

-- promos: vendor-specific promos + usage limits
ALTER TABLE public.promos
  ADD COLUMN shop_id       uuid REFERENCES public.shops ON DELETE CASCADE,
  ADD COLUMN usage_count   integer NOT NULL DEFAULT 0,
  ADD COLUMN max_usage     integer;

-- shops: admin features
ALTER TABLE public.shops
  ADD COLUMN featured              boolean NOT NULL DEFAULT false,
  ADD COLUMN tags                  text[]  NOT NULL DEFAULT '{}',
  ADD COLUMN announcement_banner   text;

-- vendor_ledgers: link to payout
ALTER TABLE public.vendor_ledgers
  ADD COLUMN payout_request_id  uuid REFERENCES public.payout_requests,
  ADD COLUMN paid_at            timestamptz;
```

### 3. Role System: Add `is_vendor()` Function

```sql
-- Add vendor role helper (mirrors existing is_admin() pattern)
CREATE OR REPLACE FUNCTION public.is_vendor()
RETURNS boolean
LANGUAGE sql STABLE
AS $$
  SELECT coalesce(
    (auth.jwt() -> 'app_metadata' ->> 'is_vendor')::boolean,
    false
  );
$$;
```

When admin approves a vendor's KYC in the web dashboard, a Supabase Edge Function (`approve-vendor`) calls the Supabase Admin API to set `app_metadata.is_vendor = true` on that user. This is the same pattern as the existing `is_admin` boolean.

### 4. RLS Gaps to Fix

**`shipments`** — vendors need to add/update tracking info:
```sql
CREATE POLICY "shipments: vendor insert"
  ON public.shipments FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM marketplace_orders o JOIN shops s ON s.id = o.shop_id
    WHERE o.id = shipments.order_id AND s.owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "shipments: vendor update"
  ON public.shipments FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM marketplace_orders o JOIN shops s ON s.id = o.shop_id
    WHERE o.id = shipments.order_id AND s.owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "shipments: admin all"
  ON public.shipments FOR ALL TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());
```

**`prescriptions`** — vendor approval/rejection + admin access:
```sql
CREATE POLICY "prescriptions: vendor update"
  ON public.prescriptions FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM marketplace_orders o JOIN shops s ON s.id = o.shop_id
    WHERE o.id = prescriptions.order_id AND s.owner_id = (SELECT auth.uid())
  ));

CREATE POLICY "prescriptions: admin all"
  ON public.prescriptions FOR ALL TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());
```

**`promos`** — vendor + admin CRUD (currently only public SELECT exists):
```sql
CREATE POLICY "promos: vendor manage own"
  ON public.promos FOR ALL TO authenticated
  USING (shop_id = (SELECT shops.id FROM shops WHERE shops.owner_id = (SELECT auth.uid())))
  WITH CHECK (shop_id = (SELECT shops.id FROM shops WHERE shops.owner_id = (SELECT auth.uid())));

CREATE POLICY "promos: admin manage all"
  ON public.promos FOR ALL TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());
```

**`product_variants`** — add missing DELETE policy for vendor:
```sql
CREATE POLICY "variants: vendor delete"
  ON public.product_variants FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM products p JOIN shops s ON s.id = p.shop_id
    WHERE p.id = product_variants.product_id AND s.owner_id = (SELECT auth.uid())
  ));
```

**`shop_deletion_requests`** — no policies exist at all:
```sql
ALTER TABLE public.shop_deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shop_deletion_requests: owner insert"
  ON public.shop_deletion_requests FOR INSERT TO authenticated
  WITH CHECK (owner_id = (SELECT auth.uid()));

CREATE POLICY "shop_deletion_requests: owner select"
  ON public.shop_deletion_requests FOR SELECT TO authenticated
  USING (owner_id = (SELECT auth.uid()) OR is_admin());

CREATE POLICY "shop_deletion_requests: admin update"
  ON public.shop_deletion_requests FOR UPDATE TO authenticated
  USING (is_admin()) WITH CHECK (is_admin());
```

**New tables RLS** (payout_requests, disputes, platform_settings, vendor_announcements):
- `payout_requests`: vendor INSERT/SELECT own shop, admin ALL
- `disputes`: buyer INSERT, buyer/vendor SELECT own, admin ALL
- `platform_settings`: admin ALL, authenticated SELECT
- `vendor_announcements`: admin ALL, is_vendor SELECT

### 5. Realtime: Broadcast from DB Triggers

For live order updates in the vendor dashboard, use `realtime.broadcast_changes()` instead of raw postgres_changes (avoids the N-reads-per-subscriber bottleneck):

```sql
-- Trigger fires when marketplace_orders status changes
CREATE OR REPLACE FUNCTION notify_order_change()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM realtime.broadcast_changes(
    'shop:' || NEW.shop_id::text,
    TG_OP,
    'marketplace_orders',
    'public',
    NEW,
    OLD
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_order_change
  AFTER INSERT OR UPDATE ON public.marketplace_orders
  FOR EACH ROW EXECUTE FUNCTION notify_order_change();
```

Vendor dashboard subscribes to channel `shop:<shop_id>` — only that vendor's orders fan out.

### 6. Missing Indexes for RLS Performance

```sql
CREATE INDEX IF NOT EXISTS ix_products_shop_id ON public.products (shop_id);
CREATE INDEX IF NOT EXISTS ix_orders_shop_id ON public.marketplace_orders (shop_id);
CREATE INDEX IF NOT EXISTS ix_orders_buyer_id ON public.marketplace_orders (buyer_id);
CREATE INDEX IF NOT EXISTS ix_vendor_ledgers_shop_id ON public.vendor_ledgers (shop_id);
CREATE INDEX IF NOT EXISTS ix_shipments_order_id ON public.shipments (order_id);
CREATE INDEX IF NOT EXISTS ix_prescriptions_order_id ON public.prescriptions (order_id);
CREATE INDEX IF NOT EXISTS ix_promos_shop_id ON public.promos (shop_id);
CREATE INDEX IF NOT EXISTS ix_payout_requests_shop_id ON public.payout_requests (shop_id);
CREATE INDEX IF NOT EXISTS ix_disputes_order_id ON public.disputes (order_id);
```

---

## Web Dashboard: Tech Stack

**Project**: `petfolio-dashboard` (new GitHub repo)  
**Hosting**: Vercel (free tier → Pro as needed)

| Layer | Choice | Rationale |
|---|---|---|
| Framework | **Next.js 15 App Router** | First-class Supabase SSR support, largest ecosystem, most Supabase examples |
| Language | TypeScript | Type safety with Supabase generated types |
| UI Library | **Shadcn/UI** | Tailwind-based, copy-paste components, full code ownership, best Next.js App Router integration |
| Data tables | **TanStack Table v8** | Headless, works natively with Shadcn, best for sortable/filterable order + product tables |
| Charts | **Recharts** (via Shadcn chart blocks) | Shadcn's native chart choice, CSS variable theming, lighter than Tremor |
| Auth | `@supabase/ssr` + Next.js middleware | Cookie-based sessions, RLS enforcement on server components |
| DB client | `@supabase/supabase-js` v2 | Same Supabase project, `force-dynamic` on all authenticated routes |
| Realtime | Supabase Realtime (client components) | Live order notifications via `shop:<id>` broadcast channel |
| State | Zustand (UI state) + TanStack Query (server state) | URL-based filters via `nuqs` |
| Forms | React Hook Form + Zod | Vendor product/shop forms |
| Images | Supabase Storage + `next/image` | Product images, shop logos/banners via existing Supabase Storage |
| Icons | Lucide React | Already aligned with Shadcn |

**Critical Next.js + Supabase rules** (to avoid the ISR auth token leak documented in GitHub issue #30241):
- `@supabase/ssr` v0.10.0+ (auto-sets `Cache-Control: no-store`)
- All authenticated routes: `export const dynamic = 'force-dynamic'`
- Never call `supabase.auth.getSession()` in server code — use `getUser()` only
- Middleware at `middleware.ts` refreshes JWT cookies on every request

---

## Architecture: Two Portals, One Next.js App

```
petfolio-dashboard/
├── app/
│   ├── (auth)/
│   │   ├── login/          # Supabase magic link / email+password
│   │   └── callback/       # OAuth callback handler
│   ├── vendor/             # Protected: requires is_vendor = true in app_metadata
│   │   ├── layout.tsx      # Vendor sidebar nav
│   │   ├── page.tsx        # Dashboard overview
│   │   ├── products/       # Product CRUD
│   │   ├── orders/         # Order queue + fulfillment
│   │   ├── shop/           # Shop settings + KYC
│   │   ├── earnings/       # Ledger + payout requests
│   │   └── promos/         # Vendor promo codes
│   ├── admin/              # Protected: requires is_admin = true in app_metadata
│   │   ├── layout.tsx      # Admin sidebar nav
│   │   ├── page.tsx        # Platform overview
│   │   ├── vendors/        # Vendor approval + KYC review
│   │   ├── orders/         # All platform orders
│   │   ├── products/       # Platform product moderation
│   │   ├── prescriptions/  # Rx approval queue
│   │   ├── payouts/        # Payout approvals
│   │   ├── disputes/       # Dispute resolution
│   │   ├── promos/         # Platform-wide promos
│   │   ├── settings/       # platform_settings CRUD
│   │   └── announcements/  # Vendor announcements
│   └── api/
│       ├── approve-vendor/ # Edge: sets app_metadata.is_vendor via Admin API
│       ├── approve-payout/ # Edge: marks ledger entries paid
│       └── webhooks/       # Stripe Connect webhooks
├── components/
│   ├── ui/                 # Shadcn primitives
│   ├── data-table/         # TanStack Table wrappers
│   ├── charts/             # Recharts wrappers
│   └── realtime/           # Order notification bell
├── lib/
│   ├── supabase/
│   │   ├── client.ts       # createBrowserClient
│   │   └── server.ts       # createServerClient
│   └── types/
│       └── database.ts     # Generated from `supabase gen types`
└── middleware.ts            # Auth redirect + JWT refresh
```

---

## Vendor Portal Features (Full Spec)

### 1. Onboarding & Shop Setup
- Register with email (Supabase magic link or password)
- Shop creation wizard: name → slug → description → logo/banner upload → business info → policies
- KYC submission: trade license + national ID upload to Supabase Storage, sets `kyc_status = 'submitted'`
- KYC pending state: read-only view while waiting for admin approval
- Stripe Connect or manual payout method selection (after KYC approved)

### 2. Dashboard Overview (`/vendor`)
- KPI row: Today's orders, Revenue this month, Pending shipments, Active products
- Revenue chart (Recharts area chart, 30-day rolling)
- Recent orders table (last 10, TanStack Table)
- Real-time order notification bell (Supabase Realtime `shop:<id>` channel)
- Low stock alert cards (products where `inventory_count < 5`)
- Pinned vendor announcements from admin

### 3. Product Management (`/vendor/products`)
- Table: Name, SKU, Category, Price, Stock, Status, Rating, Actions
- TanStack Table with: column sort, category filter, active/inactive toggle filter, search
- Add/Edit Product drawer/modal:
  - Images (multi-upload to Supabase Storage, drag-reorder)
  - Name, Brand, SKU, Category, Description (new column), Tags (new column)
  - Price + Subscription price, `is_rx` toggle
  - Inventory count, Weight (new column)
  - Glyph + gradient picker (aesthetic)
  - Active toggle
- Variant management sub-table: SKU, Attributes (JSON key-values), Price override, Stock
- Bulk actions: activate/deactivate selected, delete selected
- Soft delete: sets `active = false`, not hard delete

### 4. Order Management (`/vendor/orders`)
- Table: Order #, Date, Buyer (masked), Items (count), Amount, Payment Method, Status, Actions
- TanStack Table with: status filter tabs (Pending → Processing → Shipped → Delivered), date range picker, search by order ID
- Order detail page:
  - Line items with product thumbnails
  - Buyer shipping address (read-only)
  - Payment method badge
  - Prescription attachment viewer (if `is_rx` order) — approve/reject with note
  - Status update flow: Pending → Processing → Shipped (requires courier + tracking number input) → Delivered
  - Add shipment details form (courier name, tracking ID, tracking URL, `shipped_at`)
  - Download packing slip (PDF via `window.print()` or simple HTML template)
- Real-time: new order toast notification, order status badge updates live

### 5. Shop Settings (`/vendor/shop`)
- Profile tab: name, slug (read-only after first set), description, logo, banner
- Policies tab: return policy, shipping policy (text areas)
- Contact tab: business email, phone, address fields
- Social links tab: JSON editor for social_links
- Announcement banner: optional text shown on shop storefront in Flutter app
- Danger zone: Request shop deletion (creates `shop_deletion_requests` row)
- KYC status badge: pending / submitted / approved / rejected with rejection reason

### 6. Earnings & Payouts (`/vendor/earnings`)
- Ledger table: Order date, Order ID, Gross Amount, Platform Fee, Net Earnings, Status, Paid Date
- TanStack Table with: status filter (pending_clearance / available / paid), date range
- Summary cards: Available balance, Pending clearance, Total paid out
- Revenue chart: monthly bar chart (Recharts)
- Request Payout button: opens modal with amount (capped at available balance), payout method, account details
- Payout history table: amount, method, status, requested date, resolved date

### 7. Promo Management (`/vendor/promos`)
- Table: Code, Type (percent/flat), Value, Min Order, Category, Usage (count/max), Active, Expires, Actions
- Create promo form: code, discount type, value, min order, category scope, usage limit, expiry date
- Promos are scoped to `shop_id` — only apply to this vendor's products
- Toggle active/inactive inline

---

## Platform Admin Features (Full Spec)

### 1. Overview (`/admin`)
- KPI row: Active vendors, Orders today, GMV this month, Platform fees earned, Open disputes
- Platform revenue chart vs vendor earnings (stacked bar, Recharts)
- Top vendors by GMV table
- Recent activity feed (audit_logs table)
- Open disputes count badge

### 2. Vendor Management (`/admin/vendors`)
- Table: Shop name, Owner email, KYC status, Active, Verified, Platform fee %, Orders, Created
- KYC review queue: filter to `kyc_status = 'submitted'`
  - View uploaded documents (trade license, national ID from Supabase Storage)
  - Approve: sets `kyc_status = 'approved'`, `is_verified = true`, calls `/api/approve-vendor` Edge Function to set `app_metadata.is_vendor = true`
  - Reject: sets `kyc_status = 'rejected'`, saves rejection_reason
- Per-vendor page: shop details, all orders, ledger, override platform fee %
- Suspend/unsuspend: toggle `is_active`
- Feature shop: toggle `featured` (new column)

### 3. Orders (`/admin/orders`)
- All platform orders, all vendors
- Table: Order #, Shop, Buyer (masked), Amount, Payment Method, Payment Status, Order Status, Date
- Filters: shop select, status, payment method, date range, search
- Order detail: full view + ability to update status, trigger refund, add admin notes
- Export to CSV

### 4. Prescription Queue (`/admin/prescriptions`)
- All pending prescriptions across all orders
- Table: Order #, Shop, Product, Uploaded, Status, Actions
- View prescription image, approve/reject with note

### 5. Payouts (`/admin/payouts`)
- Payout requests table: Shop, Amount, Method, Account Details, Requested At, Status
- Approve: marks request approved, updates `vendor_ledgers.payout_request_id` and `paid_at`
- Reject: sets status to rejected with note

### 6. Disputes (`/admin/disputes`)
- All disputes table: Order #, Raised By, Reason, Status, Age
- Dispute detail: order info, communication history
- Resolve: set resolution text, close dispute

### 7. Platform Promos (`/admin/promos`)
- Same promo CRUD as vendor, but `shop_id = null` → platform-wide (applies to all vendors)

### 8. Platform Settings (`/admin/settings`)
- Key-value editor for `platform_settings` table
- Default platform fee %, allowed categories, maintenance mode toggle

### 9. Announcements (`/admin/announcements`)
- Create announcements (title, body, pin toggle) → shown in vendor dashboard

---

## UI/UX Design Direction

**Design system**: Shadcn/UI tokens extended with Petfolio brand (matching existing `AppColors` from Flutter):
- Primary accent: Petfolio orange/warm palette
- Surface: neutral grays (Shadcn defaults)
- Charts: consistent color sequence matching Flutter app palette

**Layout pattern**: Fixed sidebar (collapsed on mobile) + scrollable content area
- Sidebar: shop logo/name, nav items with icons (Lucide), bottom user menu
- Top bar: breadcrumb, notification bell, avatar

**Table UX standards** (TanStack Table throughout):
- URL-encoded filter state via `nuqs` (shareable filtered URLs)
- Optimistic updates on status changes
- Skeleton loading states (Shadcn Skeleton)
- Empty states with actionable CTAs
- Bulk selection toolbar

**Form UX** (React Hook Form + Zod):
- Inline validation
- Image upload: drag-and-drop zone → Supabase Storage → returns URL
- Unsaved changes warning before navigation

**Realtime UX**:
- Toast notification for new orders (top-right, Shadcn Sonner)
- Order status badge updates in-place (no page reload)
- Bell icon with unread count badge

---

## Flutter App Changes (Post-Dashboard)

1. **Remove** all vendor screens and routes (11 screens, 8 routes listed above)
2. **Remove** vendor controllers and repositories (6 + 2 listed above)
3. **Add** in `marketplace_routes.dart`: replace `/seller` route with a redirect screen that calls `url_launcher` to open the web dashboard URL
4. **Update** `main.dart` / `router.dart` to remove seller route imports
5. **Run** `flutter analyze` + `flutter test` to verify clean removal
6. Run `dart run build_runner build --delete-conflicting-outputs` if any generated files reference removed code

No buyer screens, controllers, models, or repositories change.

---

## Implementation Phases

### Phase 0: Database Migration (do first, before code)
Run all SQL above as Supabase migrations in order:
1. New tables (`payout_requests`, `disputes`, `platform_settings`, `vendor_announcements`)
2. Missing columns on existing tables
3. New `is_vendor()` function
4. RLS policy fixes (new policies for `shipments`, `prescriptions`, `promos`, `shop_deletion_requests`, `product_variants`)
5. Realtime broadcast trigger on `marketplace_orders`
6. Missing indexes
7. Seed `platform_settings`

### Phase 1: Flutter Cleanup
Remove vendor code, add `/seller` → web redirect, run analyze + tests.

### Phase 2: Next.js Project Bootstrap
```bash
npx create-next-app@latest petfolio-dashboard --typescript --tailwind --app
npx shadcn@latest init
npx shadcn@latest add button card table badge dialog drawer form input label select textarea toast sonner
npm install @supabase/supabase-js @supabase/ssr
npm install @tanstack/react-table @tanstack/react-query zustand nuqs
npm install react-hook-form @hookform/resolvers zod recharts lucide-react
npx supabase gen types typescript --project-id jqyjvhwlcqcsuwcqgcwf > lib/types/database.ts
```

Set environment variables in Vercel:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (for Edge Functions / API routes that use Admin API)
- `NEXT_PUBLIC_DASHBOARD_URL` (reference from Flutter app)

### Phase 3: Auth + Middleware
- `middleware.ts`: JWT refresh + role-based redirect (`/vendor` requires `is_vendor`, `/admin` requires `is_admin`)
- Login page with Supabase magic link
- All authenticated layouts use `force-dynamic`

### Phase 4: Vendor Portal (build in feature order)
Shop setup → Products → Orders → Earnings → Promos

### Phase 5: Admin Portal
Vendor management (KYC queue) → Orders → Prescriptions → Payouts → Disputes → Settings

### Phase 6: Realtime & Polish
- Connect Supabase Realtime subscription to vendor order channel
- Notification bell component
- Toast for new orders
- Loading skeletons throughout

---

## Verification Plan

1. **Database**: Run the SQL migrations against the Supabase project, verify via `list_tables` and `execute_sql` spot checks
2. **RLS**: Test each policy with `set role authenticated; set request.jwt.claims = ...` psql session to confirm vendor A cannot see vendor B's data
3. **Flutter cleanup**: `flutter analyze` should show 0 errors, `flutter test` should pass; manually smoke-test buyer checkout flow
4. **Web auth**: Verify vendor gets redirected from `/admin` and admin gets redirected from `/vendor`
5. **Product CRUD**: Create product in web dashboard → verify it appears in Flutter marketplace screen
6. **Order flow**: Place order in Flutter → verify it appears in vendor's web dashboard order queue → update status in web → verify Flutter buyer sees updated status
7. **Realtime**: Open vendor dashboard, place order in Flutter app (or insert via SQL), confirm toast fires within 2 seconds
8. **KYC approval**: Admin approves vendor → verify `app_metadata.is_vendor = true` set → vendor can access `/vendor/*` routes