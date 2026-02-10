-- ═══════════════════════════════════════════════════════
-- QR MENU — RLS FIX (Tenants + Products)
-- Root Cause: Products policy queries tenants table,
--   but tenants had no SELECT policy → sub-query blocked
-- ═══════════════════════════════════════════════════════

-- 1. GÜVENLİK DUVARLARINI TEKRAR AÇ (Zorunlu)
ALTER TABLE "public"."tenants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;

-- 2. TEMİZLİK (Eski, bozuk kuralları sil)
DROP POLICY IF EXISTS "Owners can view their own tenant" ON "public"."tenants";
DROP POLICY IF EXISTS "Shop Owners can manage their own products" ON "public"."products";
DROP POLICY IF EXISTS "Public Read Access" ON "public"."products";
DROP POLICY IF EXISTS "Public Display" ON "public"."products";
DROP POLICY IF EXISTS "Enable all access for authenticated users" ON "public"."products";
DROP POLICY IF EXISTS "products_access_policy" ON "public"."products";

-- 3. KİLİT NOKTA: Tenants tablosunu OKUMA izni ver
-- Bu olmazsa, ürün eklerken yapılan kontrol başarısız olur!
CREATE POLICY "Owners can view their own tenant"
ON "public"."tenants"
FOR SELECT
TO authenticated
USING (
  owner_email = auth.jwt() ->> 'email'
);

-- 4. ÜRÜN YÖNETİM İZNİ (Insert, Update, Delete)
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

-- 5. MÜŞTERİLER İÇİN OKUMA İZNİ (Menüde görünsün)
CREATE POLICY "Public Read Access"
ON "public"."products"
FOR SELECT
TO anon, authenticated
USING (true);

-- 6. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT ALL ON TABLE "public"."products" TO authenticated;
GRANT SELECT ON TABLE "public"."products" TO anon;
GRANT SELECT ON TABLE "public"."tenants" TO authenticated;
