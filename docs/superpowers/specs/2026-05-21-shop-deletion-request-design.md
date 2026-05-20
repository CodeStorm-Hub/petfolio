# Shop Deletion Request — Design Spec
_Date: 2026-05-21_

## Overview

Vendors can request that their shop be deleted from the PetFolio platform. The request enters a pending queue that a PetFolio admin must approve or reject. On approval the shop is soft-deleted (marked inactive) and all its products are unlisted; the underlying rows are retained for financial audit.

---

## 1. Database

### 1.1 New table — `shop_deletion_requests`

| Column | Type | Constraints |
|---|---|---|
| `id` | `uuid` | PK, `gen_random_uuid()` |
| `shop_id` | `uuid` | FK → `shops(id)`, NOT NULL |
| `owner_id` | `uuid` | FK → `auth.users(id)`, NOT NULL |
| `reason` | `text` | nullable (optional vendor input) |
| `status` | `text` | NOT NULL, DEFAULT `'pending'`, CHECK IN `('pending','approved','rejected')` |
| `rejection_note` | `text` | nullable (admin fills on reject) |
| `requested_at` | `timestamptz` | NOT NULL, DEFAULT `now()` |
| `resolved_at` | `timestamptz` | nullable |
| `resolved_by` | `uuid` | nullable (admin uid) |

Index: `(status)` for the admin queue query.

**RLS:**
- Owner can `INSERT` (one pending request per shop enforced by RPC) and `SELECT` their own rows
- Admin can `SELECT` all rows; no direct `UPDATE` — all mutations go through RPCs

### 1.2 RPC — `request_shop_deletion(p_shop_id uuid, p_reason text)`

Vendor-callable (authenticated, not admin-only). Guards in order:
1. `auth.uid() = shops.owner_id` — caller owns the shop
2. Zero active orders — `marketplace_orders.status NOT IN ('delivered','cancelled','refunded')` for this shop; raises exception with count if any exist
3. No existing pending request — raises exception if `status = 'pending'` row already exists for this shop

On success: inserts into `shop_deletion_requests`, writes `audit_logs` row (`shop_deletion_requested`).

### 1.3 RPC — `resolve_shop_deletion(p_request_id uuid, p_action text, p_rejection_note text)`

Admin-only (`is_admin()` guard). `p_action` IN `('approved','rejected')`.

**On `approved`:**
- Sets `shops.is_active = false`, `shops.updated_at = now()`
- Bulk-sets all shop products to `is_active = false` (or unlisted equivalent)
- Updates `shop_deletion_requests` row: `status = 'approved'`, `resolved_at`, `resolved_by`
- Inserts `audit_logs` row (`shop_deletion_approved`)
- Inserts `notifications` row to `owner_id` (type `shop_deletion_approved`)

**On `rejected`:**
- Validates `p_rejection_note` is non-empty
- Updates request row: `status = 'rejected'`, `rejection_note`, `resolved_at`, `resolved_by`
- Inserts `audit_logs` row (`shop_deletion_rejected`)
- Inserts `notifications` row to `owner_id` (type `shop_deletion_rejected`, metadata includes `rejection_note`)

---

## 2. Dart Models & Repositories

### 2.1 Model — `ShopDeletionRequest` (plain class, no Freezed)

Fields: `id`, `shopId`, `ownerId`, `shopName` (joined), `reason`, `status`, `rejectionNote`, `requestedAt`, `resolvedAt`.

`factory ShopDeletionRequest.fromJson(Map<String, dynamic> json)` unpacks nested `shop:shop_id(shop_name)` PostgREST join.

### 2.2 `ShopRepository` additions

- `requestShopDeletion(String shopId, {String? reason})` — calls `request_shop_deletion` RPC
- `fetchMyDeletionRequest(String shopId)` — selects `shop_deletion_requests` where `shop_id = shopId` AND `status = 'pending'` OR `status = 'rejected'` (most recent), returns `ShopDeletionRequest?`

### 2.3 `AdminRepository` additions

- `fetchPendingDeletionRequests()` — selects `shop_deletion_requests` with `shop:shop_id(shop_name, owner_id)` join, filtered `status = 'pending'`, ordered by `requested_at asc`
- `resolveDeletionRequest(String requestId, {required bool approve, String? rejectionNote})` — calls `resolve_shop_deletion` RPC

**No changes to `Shop` model or `myShopProvider`.**

---

## 3. State Management

### 3.1 `myDeletionRequestProvider` (vendor-side)

`AsyncNotifier<ShopDeletionRequest?>` in `lib/features/marketplace/presentation/controllers/deletion_request_controller.dart`.

- Loads via `ShopRepository.fetchMyDeletionRequest(shopId)` — `shopId` is read from `myShopProvider` (already watched by `_DashboardBody`); notifier is a `family` provider keyed on `shopId`
- `submitRequest(String shopId, {String? reason})` — calls RPC, refreshes state; on active-orders exception surfaces readable message via `AppSnackBar.showError`
- Watched by `_DashboardBody` to drive the three danger-zone states

### 3.2 `shopDeletionRequestsProvider` (admin-side)

`AsyncNotifier<List<ShopDeletionRequest>>` in `lib/features/admin/presentation/controllers/shop_deletion_controller.dart`.

- Loads via `AdminRepository.fetchPendingDeletionRequests()`
- `resolve(String requestId, {required bool approve, String? rejectionNote})` — calls RPC, optimistically removes card from list
- `refresh()` — pull-to-refresh with `AsyncLoading` guard

---

## 4. Vendor UI — Seller Dashboard

File: `lib/features/marketplace/presentation/screens/vendor/seller_dashboard_screen.dart`

### Danger Zone section

Placed at the bottom of `_DashboardBody`'s `CustomScrollView`, below Quick Actions, above the trailing `SizedBox(height: 120)`. Separated from Quick Actions by a full-width `Divider` and a "DANGER ZONE" label in `AppColors.danger` at 11sp / w700 / 0.88 letterSpacing.

**State A — No pending/rejected request:**
A `ListTile`-style row:
- Leading: `Icons.delete_forever_rounded` in `AppColors.danger`
- Title: "Request shop deletion" in `AppColors.danger`
- Subtitle: "Requires admin review" in `ink500`
- Trailing: `Icons.chevron_right_rounded` in `ink300`
- Tap opens `_DeleteShopRequestSheet`

**`_DeleteShopRequestSheet` bottom sheet:**
- Title: "Request Shop Deletion"
- Consequence bullet list (3 items):
  - Shop hidden from all buyers immediately on approval
  - All products unlisted
  - Cannot be undone without contacting support
- Amber info box: "PetFolio reviews requests within 2–3 business days. You'll be notified of the outcome."
- Optional `TextFormField`: label "Reason (optional)", hint "Why are you closing your shop?", multiline, maxLength 300
- Footer button row: "Cancel" (TextButton) · "Submit Request" (FilledButton in `AppColors.danger`)
- On submit: calls `myDeletionRequestProvider.notifier.submitRequest(...)`; on active-orders error shows `AppSnackBar.showError`; on success dismisses sheet

**State B — Pending request:**
Amber `Container` banner:
- Icon: `Icons.hourglass_top_rounded` in `AppColors.warning`
- Title: "Deletion request pending"
- Subtitle: "Admin review in progress · Submitted [requestedAt date]"
- Not tappable

**State C — Rejected request:**
Red `Container` banner:
- Icon: `Icons.cancel_outlined` in `AppColors.danger`
- Title: "Deletion request rejected"
- Body: admin's `rejectionNote`
- "Submit new request →" TextButton in `AppColors.danger` — reopens `_DeleteShopRequestSheet`

---

## 5. Admin UI — New "Shops" Tab

### 5.1 `admin_layout.dart` changes

- Add `_AdminTab.shops` to enum (6th tab)
- Destination: `Icons.store_outlined` / `Icons.store_rounded`, label `'Shops'`
- Tab icon shows red dot badge when `shopDeletionRequestsProvider` has items
- `_body` switch: `_AdminTab.shops => const ShopsTab()`

### 5.2 `ShopsTab` widget

File: `lib/features/admin/presentation/widgets/shops_tab.dart`

Uses `AdminPanelScaffold` with pull-to-refresh via `shopDeletionRequestsProvider.notifier.refresh()`.

`AsyncValue.when`:
- Loading: `CircularProgressIndicator`
- Error: `AdminErrorState`
- Empty: `AdminEmptyState(icon: Icons.store_outlined, message: 'No pending deletion requests')`
- Data: `ListView.separated` of `_DeletionRequestCard`

### 5.3 `_DeletionRequestCard` (ConsumerStatefulWidget)

Card layout (top → bottom):
1. **Header row:** `Icons.delete_forever_rounded` (danger, 16px) · shop name (`textTheme.labelMedium`, `ink500`) · `Spacer` · `AdminStatusChip('Pending', AppColors.warning)`
2. **Requested date:** `labelSmall` in `ink500`
3. **Reason block** (if `reason != null && reason.isNotEmpty`): `surface2` container, italic reason text, max 200 chars
4. **Consequence summary:** "Approving deactivates this shop and unlists all its products" in `ink500` at 12sp
5. **Action row** (or `CircularProgressIndicator` when `_loading`):
   - "Reject" `OutlinedButton` → `AlertDialog` with:
     - Title: "Reject deletion request"
     - Required `TextFormField` for rejection note (validates non-empty before enabling Confirm)
     - Buttons: "Cancel" (focused by default) · "Confirm Reject" (`FilledButton` in `AppColors.danger`)
   - "Approve deletion" `FilledButton` (AppColors.danger) → `AlertDialog` with:
     - Title: "Approve shop deletion?"
     - Body: "[Shop name] will be deactivated and all products unlisted. This cannot be undone."
     - Buttons: "Cancel" (focused by default) · "Approve deletion" (`FilledButton` in `AppColors.danger`)

Both dialogs call `shopDeletionRequestsProvider.notifier.resolve(...)` on confirm. Errors via `AppSnackBar.showError`.

---

## 6. Files Changed / Created

| Action | File |
|---|---|
| **New migration** | `supabase/migrations/20260521000000_shop_deletion_requests.sql` |
| **New model** | `lib/features/admin/data/models/shop_deletion_request.dart` |
| **Modified** | `lib/features/marketplace/data/repositories/shop_repository.dart` |
| **Modified** | `lib/features/admin/data/repositories/admin_repository.dart` |
| **New controller** | `lib/features/marketplace/presentation/controllers/deletion_request_controller.dart` |
| **New controller** | `lib/features/admin/presentation/controllers/shop_deletion_controller.dart` |
| **Modified** | `lib/features/marketplace/presentation/screens/vendor/seller_dashboard_screen.dart` |
| **New widget** | `lib/features/admin/presentation/widgets/shops_tab.dart` |
| **Modified** | `lib/features/admin/presentation/screens/admin_layout.dart` |

---

## 7. Out of Scope

- Email/push notifications (in-app `notifications` table row only)
- Vendor ability to cancel a pending request (contact support instead)
- Hard delete / data export
- Admin bulk-action on multiple requests
