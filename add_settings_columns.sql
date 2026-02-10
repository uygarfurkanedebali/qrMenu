-- ═══════════════════════════════════════════════════════
-- QR MENU — Settings Columns Migration
-- Adds shop configuration fields to tenants table
-- ═══════════════════════════════════════════════════════

-- 1. Add new columns (IF NOT EXISTS prevents errors if run twice)
ALTER TABLE "public"."tenants" ADD COLUMN IF NOT EXISTS primary_color text DEFAULT '#FF5722';
ALTER TABLE "public"."tenants" ADD COLUMN IF NOT EXISTS font_family text DEFAULT 'Roboto';
ALTER TABLE "public"."tenants" ADD COLUMN IF NOT EXISTS currency_symbol text DEFAULT '₺';
ALTER TABLE "public"."tenants" ADD COLUMN IF NOT EXISTS phone_number text;
ALTER TABLE "public"."tenants" ADD COLUMN IF NOT EXISTS instagram_handle text;
ALTER TABLE "public"."tenants" ADD COLUMN IF NOT EXISTS wifi_name text;
ALTER TABLE "public"."tenants" ADD COLUMN IF NOT EXISTS wifi_password text;

-- 2. RLS: Allow owners to UPDATE their own tenant (for saving settings)
DROP POLICY IF EXISTS "Owners can update their own tenant" ON "public"."tenants";
CREATE POLICY "Owners can update their own tenant"
ON "public"."tenants"
FOR UPDATE
TO authenticated
USING (
  owner_email = auth.jwt() ->> 'email'
)
WITH CHECK (
  owner_email = auth.jwt() ->> 'email'
);

-- 3. Ensure SELECT policy exists (needed for reading settings)
DROP POLICY IF EXISTS "Owners can view their own tenant" ON "public"."tenants";
CREATE POLICY "Owners can view their own tenant"
ON "public"."tenants"
FOR SELECT
TO authenticated
USING (
  owner_email = auth.jwt() ->> 'email'
);

-- 4. Grant UPDATE permission
GRANT UPDATE ON TABLE "public"."tenants" TO authenticated;
