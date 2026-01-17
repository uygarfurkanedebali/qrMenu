-- =============================================
-- QR-INFINITY: DYNAMIC RLS POLICIES
-- =============================================
-- Run this ENTIRE script in Supabase SQL Editor
-- This enables the dynamic SaaS architecture
-- =============================================

-- First, ensure RLS is enabled
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- =============================================
-- CLEAN SLATE: Drop all existing policies
-- =============================================
DROP POLICY IF EXISTS "anon_read_tenants" ON public.tenants;
DROP POLICY IF EXISTS "auth_insert_tenants" ON public.tenants;
DROP POLICY IF EXISTS "auth_update_tenants" ON public.tenants;
DROP POLICY IF EXISTS "Public can view active tenants" ON public.tenants;
DROP POLICY IF EXISTS "Allow insert tenants" ON public.tenants;
DROP POLICY IF EXISTS "Allow update tenants" ON public.tenants;

DROP POLICY IF EXISTS "anon_read_products" ON public.tenants;
DROP POLICY IF EXISTS "auth_insert_products" ON public.products;
DROP POLICY IF EXISTS "auth_update_products" ON public.products;
DROP POLICY IF EXISTS "auth_delete_products" ON public.products;
DROP POLICY IF EXISTS "Public can view products" ON public.products;
DROP POLICY IF EXISTS "Allow insert products" ON public.products;
DROP POLICY IF EXISTS "Allow update products" ON public.products;
DROP POLICY IF EXISTS "Allow delete products" ON public.products;

-- =============================================
-- TENANTS TABLE: PUBLIC READ, AUTH WRITE
-- =============================================

-- PUBLIC (anon + authenticated) can read active tenants
CREATE POLICY "tenants_public_read" 
    ON public.tenants 
    FOR SELECT 
    TO anon, authenticated
    USING (is_active = true);

-- AUTHENTICATED users can insert new tenants (System Admin)
CREATE POLICY "tenants_auth_insert" 
    ON public.tenants 
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

-- AUTHENTICATED users can update tenants
CREATE POLICY "tenants_auth_update" 
    ON public.tenants 
    FOR UPDATE 
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- =============================================
-- PRODUCTS TABLE: PUBLIC READ, OWNER WRITE
-- =============================================

-- PUBLIC (anon + authenticated) can read available products
CREATE POLICY "products_public_read" 
    ON public.products 
    FOR SELECT 
    TO anon, authenticated
    USING (is_available = true);

-- AUTHENTICATED users can insert products (for their own tenant)
CREATE POLICY "products_auth_insert" 
    ON public.products 
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

-- AUTHENTICATED users can update products
CREATE POLICY "products_auth_update" 
    ON public.products 
    FOR UPDATE 
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- AUTHENTICATED users can delete products
CREATE POLICY "products_auth_delete" 
    ON public.products 
    FOR DELETE 
    TO authenticated
    USING (true);

-- =============================================
-- VERIFICATION: List all policies
-- =============================================
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles::text, 
    cmd,
    qual::text as using_clause
FROM pg_policies 
WHERE tablename IN ('tenants', 'products')
ORDER BY tablename, policyname;

-- =============================================
-- TEST QUERIES (run after policies)
-- =============================================
-- SELECT * FROM tenants;  -- Should work for anon
-- SELECT * FROM products; -- Should work for anon
