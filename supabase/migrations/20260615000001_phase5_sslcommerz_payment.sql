-- Phase 5: SSLCommerz payment support (bKash, Nagad)

-- 1. Extend the payment_method_enum type (payment_method is an enum, not a text+CHECK column)
ALTER TYPE payment_method_enum ADD VALUE IF NOT EXISTS 'bkash';
ALTER TYPE payment_method_enum ADD VALUE IF NOT EXISTS 'nagad';
ALTER TYPE payment_method_enum ADD VALUE IF NOT EXISTS 'sslcommerz';

-- 2. Add SSLCommerz transaction tracking column
ALTER TABLE marketplace_orders
  ADD COLUMN IF NOT EXISTS sslcommerz_transaction_id text;
