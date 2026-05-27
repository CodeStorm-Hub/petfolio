-- Replace the plain JSONB bank_account_details column with a text column
-- that stores only a Stripe-issued bank account token (e.g. btok_...).
--
-- Raw bank account details (account number, routing number) must never be
-- stored in plain JSONB — use Stripe's tokenisation API instead.
-- Existing JSONB data is intentionally dropped; affected vendors must
-- re-submit their payout info through the proper Stripe-tokenised flow.

ALTER TABLE public.shops
  DROP COLUMN IF EXISTS bank_account_details,
  ADD  COLUMN IF NOT EXISTS stripe_bank_account_token text;
