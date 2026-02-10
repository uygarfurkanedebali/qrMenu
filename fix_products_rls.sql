-- 1. Enable RLS on products (ensure it's on)
ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing restrictive policies (cleanup)
DROP POLICY IF EXISTS "Shop Owners can manage their own products" ON "public"."products";
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON "public"."products";
DROP POLICY IF EXISTS "products_access_policy" ON "public"."products";
DROP POLICY IF EXISTS "Enable read access for all users" ON "public"."products";
DROP POLICY IF EXISTS "Public Display" ON "public"."products";

-- 3. Create the CORRECT Policy for Shop Owners
-- Logic: Allow ALL operations (Insert/Update/Delete/Select) 
-- IF the product's tenant_id matches a tenant owned by the current user's email.
CREATE POLICY "Shop Owners can manage their own products"
ON "public"."products"
FOR ALL
TO authenticated
USING (
  tenant_id IN (
    SELECT id FROM public.tenants
    WHERE owner_email = auth.jwt() ->> 'email'
  )
)
WITH CHECK (
  tenant_id IN (
    SELECT id FROM public.tenants
    WHERE owner_email = auth.jwt() ->> 'email'
  )
);

-- 4. Create Public Read Policy (For Customers)
-- Allow anyone (anon + authenticated) to SELECT products
-- Filtering by tenant_id happens in the query mostly, but RLS should be permissive for reads
CREATE POLICY "Public Display"
ON "public"."products"
FOR SELECT
TO anon, authenticated
USING (true);

-- 5. Grant schema usage (just in case)
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON TABLE "public"."products" TO authenticated;
GRANT SELECT ON TABLE "public"."products" TO anon;
